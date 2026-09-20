#!/usr/bin/env bash
#
# WPF-on-Linux 工程 · T0 环境基线一键脚本
#
# 目标：在干净的 Ubuntu 22.04/24.04 容器里复现一套版本锁定的构建环境。
# 设计原则：
#   1. 所有版本号写死在下方 VERSION LOCK 区，避免版本漂移
#   2. 幂等 —— 重复执行安全，已满足的条件会跳过
#   3. 失败即停（set -euo pipefail），不留半截环境
#
# 用法：bash build/setup-env.sh
#
set -euo pipefail

# ---------------------------------------------------------------------------
# VERSION LOCK —— 修改此处需同步更新 docs/T0T1-report.md
# ---------------------------------------------------------------------------
readonly DOTNET_SDK_APT_PKG="dotnet-sdk-10.0"      # Ubuntu archive 源，实测 24.04 → SDK 10.0.111
readonly SKIASHARP_VERSION="2.88.9"                # 已验证可在 .NET 10 上离屏渲染
readonly NUGET_MIRROR="https://mirrors.huaweicloud.com/repository/nuget/v3/index.json"
readonly GH_PROXY="https://gh-proxy.com"           # 沙箱 GitHub 直连被 TLS 阻断，必须走镜像
readonly NOTO_UPSTREAM_BASE="${GH_PROXY}/https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSans/unhinted/ttf"
readonly NOTO_STYLES=(Regular Bold Italic BoldItalic)
readonly APT_PACKAGES=(
    xvfb          # 虚拟 X server，窗口级测试 (L4) 依赖
    x11-apps      # xwd 截屏工具 —— 注意在 x11-apps 而非 x11-utils
    x11-utils     # xdpyinfo / xwininfo 等 X11 诊断工具
    imagemagick   # convert / compare / import，golden image 比对
    fontconfig    # fc-cache / fc-list，字体管理
    libfontconfig1
)

# 路径定位：以本脚本位置推导工程根目录，不依赖调用者 cwd
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly FONT_SRC_DIR="${SCRIPT_DIR}/fonts"
readonly FONT_DEST_DIR="${REPO_ROOT}/tests/fonts"

log()  { printf '\033[0;34m[setup-env]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[setup-env]\033[0m %s\n' "$*"; }
die()  { printf '\033[0;31m[setup-env] 失败:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. 系统包
# ---------------------------------------------------------------------------
log "安装系统包: ${APT_PACKAGES[*]}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq || log "apt-get update 有告警（部分第三方源不可达，可忽略并继续）"
# shellcheck disable=SC2068
apt-get install -y --no-install-recommends ${APT_PACKAGES[@]} \
    || die "apt 安装失败，请检查网络或 sources.list"

log "安装 .NET SDK（${DOTNET_SDK_APT_PKG}）"
apt-get install -y --no-install-recommends "${DOTNET_SDK_APT_PKG}" \
    || die ".NET SDK 安装失败。备选方案：用 dotnet-install.sh 经 ${GH_PROXY} 安装"

# ---------------------------------------------------------------------------
# 2. NuGet 源
#    沙箱内 api.nuget.org 被 TLS 阻断（curl 返回 000 / SSL_ERROR_SYSCALL），
#    因此把华为镜像写入用户级配置，对 /workspace 下所有工程全局生效。
#    注意：<clear/> 会清掉机器上既有源，保证复现性。
# ---------------------------------------------------------------------------
log "配置 NuGet 镜像源"
mkdir -p "${HOME}/.nuget/NuGet"
cp -f "${SCRIPT_DIR}/NuGet.config" "${HOME}/.nuget/NuGet/NuGet.Config"
ok "已写入 ~/.nuget/NuGet/NuGet.Config → ${NUGET_MIRROR}"

# ---------------------------------------------------------------------------
# 3. SkiaSharp 预拉取到 NuGet 全局缓存
#    目的：下游同事离线也能 restore；同时提前暴露原生库缺失问题。
#    关键坑：只装 SkiaSharp 托管包会报 "cannot open shared object file:
#    libSkiaSharp"，必须同时装 SkiaSharp.NativeAssets.Linux。
# ---------------------------------------------------------------------------
log "预热 NuGet 缓存: SkiaSharp ${SKIASHARP_VERSION}"
PROBE_DIR="$(mktemp -d)"
trap 'rm -rf "${PROBE_DIR}"' EXIT
( cd "${PROBE_DIR}" \
  && dotnet new classlib -o probe --force >/dev/null 2>&1 \
  && cd probe \
  && dotnet add package SkiaSharp --version "${SKIASHARP_VERSION}" >/dev/null \
  && dotnet add package SkiaSharp.NativeAssets.Linux --version "${SKIASHARP_VERSION}" >/dev/null \
) || die "SkiaSharp ${SKIASHARP_VERSION} 拉取失败，请检查 NuGet 镜像连通性"
ok "SkiaSharp ${SKIASHARP_VERSION} + NativeAssets.Linux 已入缓存"

# ---------------------------------------------------------------------------
# 4. 测试字体（golden image 测试的地基）
#    handoff §6 要求"打包固定字体，禁止依赖系统字体"。
#    权威副本放在 build/fonts/ 并附 SHA256SUMS；此处部署到 tests/fonts/。
# ---------------------------------------------------------------------------
log "准备测试字体"
mkdir -p "${FONT_SRC_DIR}"
for style in "${NOTO_STYLES[@]}"; do
    f="NotoSans-${style}.ttf"
    if [[ ! -s "${FONT_SRC_DIR}/${f}" ]]; then
        log "下载 ${f}（经 gh-proxy 镜像）"
        curl -sSL --fail --max-time 120 \
            -o "${FONT_SRC_DIR}/${f}.tmp" \
            "${NOTO_UPSTREAM_BASE}/${f}" \
            || die "下载 ${f} 失败，请检查 ${GH_PROXY} 连通性"
        mv -f "${FONT_SRC_DIR}/${f}.tmp" "${FONT_SRC_DIR}/${f}"
    fi
done

# 校验：首轮生成清单，后续轮次逐条比对，防止上游静默换包导致测试漂移
if [[ -f "${FONT_SRC_DIR}/SHA256SUMS" ]]; then
    ( cd "${FONT_SRC_DIR}" && sha256sum -c --quiet SHA256SUMS ) \
        || die "字体校验失败：build/fonts 内容与 SHA256SUMS 不一致"
    ok "字体校验通过（与 SHA256SUMS 一致）"
else
    ( cd "${FONT_SRC_DIR}" && sha256sum NotoSans-*.ttf > SHA256SUMS )
    ok "已生成首版 build/fonts/SHA256SUMS"
fi

mkdir -p "${FONT_DEST_DIR}"
cp -f "${FONT_SRC_DIR}"/NotoSans-*.ttf "${FONT_DEST_DIR}/"
ok "字体已部署到 ${FONT_DEST_DIR}"

# ---------------------------------------------------------------------------
# 5. 固定 .NET SDK 版本
#    global.json 保证团队所有人用同一个 SDK 特性带，杜绝"我这儿能编"问题。
# ---------------------------------------------------------------------------
log "写入 global.json 锁定 SDK 特性带"
INSTALLED_SDK="$(dotnet --version)"
FEATURE_BAND="$(printf '%s' "${INSTALLED_SDK}" | awk -F. '{printf "%s.%s.%s00", $1, $2, $3}')"
cat > "${REPO_ROOT}/global.json" <<EOF
{
  "sdk": {
    "version": "${INSTALLED_SDK}",
    "rollForward": "latestFeature",
    "allowPrerelease": false
  }
}
EOF
ok "已锁定 SDK ${INSTALLED_SDK}（特性带 ${FEATURE_BAND}）"

ok "环境搭建完成。运行 bash build/verify-env.sh 查看版本清单。"
