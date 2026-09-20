#!/usr/bin/env bash
#
# WPF-on-Linux 工程 · T0 环境验证
#
# 逐项检查环境是否就绪，输出版本清单。
# 退出码：0 = 全部通过；1 = 存在缺失项（缺失项以 FAIL 标出）。
#
# 用法：bash build/verify-env.sh
#
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

PASS=0
FAIL=0

# 打印一行结果：$1=状态 $2=项目名 $3=详情
row() {
    case "$1" in
        OK)   printf '  \033[0;32m✓\033[0m %-22s %s\n' "$2" "$3"; PASS=$((PASS+1)) ;;
        FAIL) printf '  \033[0;31m✗\033[0m %-22s %s\n' "$2" "$3"; FAIL=$((FAIL+1)) ;;
        WARN) printf '  \033[0;33m!\033[0m %-22s %s\n' "$2" "$3" ;;
    esac
}

# 检查命令是否存在并取版本：check <命令> <项目名> <取版本的命令...>
check_cmd() {
    local bin="$1" name="$2"; shift 2
    if command -v "$bin" >/dev/null 2>&1; then
        local v
        v="$("$@" 2>&1 | head -1)"
        row OK "$name" "${v:-（无版本输出）}"
    else
        row FAIL "$name" "未找到命令: $bin"
    fi
}

echo
echo "=============================================================="
echo " WPF-on-Linux · 环境验证清单"
echo " 主机: $(uname -srm)"
echo " 系统: $(. /etc/os-release && echo "${PRETTY_NAME:-unknown}")"
echo " 时间: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "=============================================================="

echo
echo "[1] .NET"
if command -v dotnet >/dev/null 2>&1; then
    SDK_V="$(dotnet --version 2>&1 | head -1)"
    row OK "SDK 版本" "$SDK_V"
    echo "      运行时:"
    dotnet --list-runtimes 2>/dev/null | sed 's/^/        /' || true
    if [[ -f "${REPO_ROOT}/global.json" ]]; then
        row OK "global.json" "已锁定 $(python3 -c "import json;print(json.load(open('${REPO_ROOT}/global.json'))['sdk']['version'])" 2>/dev/null || echo '?')"
    else
        row WARN "global.json" "缺失，未锁定 SDK 版本（建议运行 setup-env.sh）"
    fi
else
    row FAIL "SDK 版本" "未找到 dotnet"
fi

echo
echo "[2] NuGet"
NUGET_CFG="${HOME}/.nuget/NuGet/NuGet.Config"
if [[ -f "${NUGET_CFG}" ]]; then
    SRC="$(grep -o 'https://[^"]*index.json' "${NUGET_CFG}" | head -1)"
    row OK "源配置" "${SRC:-（未解析到源）}"
else
    row WARN "源配置" "未找到 ${NUGET_CFG}"
fi

echo
echo "[3] SkiaSharp（NuGet 缓存）"
CACHE="${HOME}/.nuget/packages"
for pkg in skiasharp skiasharp.nativeassets.linux; do
    if [[ -d "${CACHE}/${pkg}" ]]; then
        VERS="$(ls "${CACHE}/${pkg}" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tr '\n' ' ')"
        row OK "$pkg" "${VERS:-（空）}"
    else
        row WARN "$pkg" "缓存中未找到（首次 restore 时会自动下载）"
    fi
done
# 关键：托管包必须与 Linux 原生包配对，否则运行时抛 DllNotFoundException
if [[ -d "${CACHE}/skiasharp" && ! -d "${CACHE}/skiasharp.nativeassets.linux" ]]; then
    row FAIL "原生库配对" "有 SkiaSharp 但缺 NativeAssets.Linux，运行时会报 libSkiaSharp 找不到"
elif [[ -d "${CACHE}/skiasharp.nativeassets.linux" ]]; then
    row OK "原生库配对" "托管包与 Linux 原生包均已就位"
fi

echo
echo "[4] X11 / 截图工具链"
check_cmd Xvfb     "Xvfb"          sh -c 'Xvfb -help 2>&1 | grep -m1 "Xvfb" || echo "已安装"'
check_cmd xwd      "xwd (x11-apps)" sh -c 'xwd -version 2>&1 | head -1'
check_cmd xdpyinfo "xdpyinfo"      sh -c 'echo 已安装'
check_cmd convert  "ImageMagick"   sh -c 'convert -version 2>&1 | head -1'
check_cmd compare  "IM compare"    sh -c 'echo 已安装'

echo
echo "[5] 测试字体"
FONT_DIR="${SCRIPT_DIR}/fonts"
if [[ -d "${FONT_DIR}" ]]; then
    N=$(find "${FONT_DIR}" -name 'NotoSans-*.ttf' | wc -l)
    if [[ "$N" -ge 4 ]]; then
        row OK "build/fonts" "Noto Sans ${N} 个字重"
    else
        row FAIL "build/fonts" "仅 ${N} 个字体文件，期望 4"
    fi
    if [[ -f "${FONT_DIR}/SHA256SUMS" ]]; then
        if ( cd "${FONT_DIR}" && sha256sum -c --quiet SHA256SUMS ) 2>/dev/null; then
            row OK "字体校验" "SHA256SUMS 全部匹配"
        else
            row FAIL "字体校验" "SHA256SUMS 不匹配，golden 测试会不稳定"
        fi
    else
        row WARN "字体校验" "缺少 SHA256SUMS"
    fi
else
    row FAIL "build/fonts" "目录不存在"
fi

if [[ -d "${REPO_ROOT}/tests/fonts" ]]; then
    N2=$(find "${REPO_ROOT}/tests/fonts" -name '*.ttf' 2>/dev/null | wc -l)
    row OK "tests/fonts" "已部署 ${N2} 个字体"
else
    row WARN "tests/fonts" "未部署（运行 setup-env.sh 会自动拷贝）"
fi

echo
echo "[6] Xvfb 实际拉起测试"
if command -v Xvfb >/dev/null 2>&1; then
    Xvfb :99 -screen 0 1280x1024x24 >/dev/null 2>&1 &
    XPID=$!
    sleep 2
    if DISPLAY=:99 xdpyinfo >/dev/null 2>&1; then
        row OK "Xvfb :99" "可拉起，xdpyinfo 连通"
    else
        row FAIL "Xvfb :99" "已启动但连不上 DISPLAY=:99"
    fi
    kill "${XPID}" 2>/dev/null || true
    wait "${XPID}" 2>/dev/null || true
fi

echo
echo "=============================================================="
if [[ "${FAIL}" -eq 0 ]]; then
    printf ' 结果: \033[0;32m全部通过\033[0m（%d 项通过，0 项失败）\n' "${PASS}"
else
    printf ' 结果: \033[0;31m%d 项失败\033[0m（%d 项通过）\n' "${FAIL}" "${PASS}"
fi
echo "=============================================================="
echo
exit $(( FAIL > 0 ? 1 : 0 ))
