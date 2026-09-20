#!/usr/bin/env bash
#
# 发布 MilBridge（AOT 桥 `wpfgfx_cor3.so`）——**主控独占**，因为它同时修掉两个已经踩过的坑。
#
# 为什么需要这个脚本（两条实测事故）：
#
#   坑 1 · **相对 ArtifactsPath 会被按"各工程目录"解析**
#     `dotnet publish … -p:ArtifactsPath=build/MilBridge/.artifacts`（相对路径）⇒ 产物落到
#     `build/MilBridge/src/MilBridge.Linux/build/MilBridge/.artifacts/`（还顺带污染
#     `src/WpfGfx.Linux/build/…`），**正式发布目录一字未动**，而 `PUB_EXIT=0`、日志全是"成功"
#     ⇒ 又一个"绿了但没生效"。**修法：绝对路径。**
#
#   坑 2 · **与 `wpfgfx_cor3.so` 同目录的 `libwpfwic.so` 谁都不拷**
#     部署契约要求 `wpfgfx_cor3.so` + `libSkiaSharp.so` + `libwpfwic.so` **必须同目录**
#     （`dladdr` 自定位 ⇒ 目录不必是"应用目录"，但三者必须在一起）。而全仓没有任何 csproj/脚本
#     会把 WIC shim 拷进发布目录 —— 于是那份副本会**悄悄过期**（实测：发布目录里是 09-10 的
#     29,392 B 旧件，而权威件已 66,152 B）。历史上正是"全仓 3 份副本"导致
#     `WIC_SHIM_MAPS=2` / `WIC_SHIM_DOUBLE_TABLE=TRUE` ⇒ `E_HANDLE`。
#     **修法：每次发布后按权威件同步，并打印三方 sha 供核对。**
#
# 用法：bash build/publish-milbridge.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

MB="$ROOT/build/MilBridge"
PUB="$MB/.artifacts/publish/MilBridge.Linux/release_linux-x64"
WIC_SRC="$ROOT/build/DirectWrite.Linux/wic-shim/libwpfwic.so"

echo "== 发布 MilBridge（绝对 ArtifactsPath）"
timeout 1200 dotnet publish "$MB/src/MilBridge.Linux/MilBridge.Linux.csproj" \
    -c Release -r linux-x64 -m:1 -p:ArtifactsPath="$MB/.artifacts" 2>&1 | tail -4
rc=${PIPESTATUS[0]}
[ "$rc" -eq 0 ] || { echo "❌ publish 失败 rc=$rc" >&2; exit "$rc"; }

[ -f "$PUB/wpfgfx_cor3.so" ] || { echo "❌ 发布目录里没有 wpfgfx_cor3.so：$PUB" >&2; exit 3; }

echo
echo "== 同步同目录依赖（部署契约：三者必须同目录）"
if [ -f "$WIC_SRC" ]; then
    cp -f "$WIC_SRC" "$PUB/libwpfwic.so"
    echo "  libwpfwic.so ← $WIC_SRC"
else
    echo "  ⚠️ 找不到权威件 $WIC_SRC（WIC shim 未构建？）—— 未同步" >&2
fi
# libSkiaSharp.so 由 MilBridge 构建管线自带（体积大且不常变），只在缺失时报错。
[ -f "$PUB/libSkiaSharp.so" ] || echo "  ⚠️ 发布目录缺 libSkiaSharp.so —— Skia 会加载失败（RegisterFromFile 按契约把异常吞成 0）" >&2

echo
echo "== 指纹（供核对/记档）"
for f in wpfgfx_cor3.so libwpfwic.so libSkiaSharp.so; do
    if [ -f "$PUB/$f" ]; then
        printf '  %-18s %10s B  %s\n' "$f" "$(stat -c%s "$PUB/$f")" "$(sha256sum "$PUB/$f" | cut -c1-24)"
    else
        printf '  %-18s %s\n' "$f" "缺失"
    fi
done
echo "  Wic* 导出数: $(nm -D --defined-only "$PUB/libwpfwic.so" 2>/dev/null | grep -c ' T Wic')"

# ── 桥源码指纹（发布**输入**的身份；与门禁 runner 共用**同一个**脚本）──────────
# 【为什么必须有】2026-09-13 实测事故：`ACCEPTANCE-BASELINE.md` 的 **#6 被冻成"源陈旧"**
#   —— T2b 在 22:37 改了 `src/WpfGfx.Linux/Rendering/{SkiaRenderBackend,DrawInstructionCensus}.cs`，
#   而发布目录里的 .so 是 **22:24:35** 发的，于是那份基线**不对应任何现存源码状态**；
#   而全仓**没有任何闸门覆盖 `src/** → 桥`**（`WFP_SRC_STALE` 只看 `build/*.Linux/**`
#   且只在 probe runner 里，`hbtextline_shim_stale` 只看 `build/shims/**`）⇒ 静默陈旧。
#   本文件 = 发布动作的输入指纹；门禁开跑前重算并与它比对 ⇒ `BRIDGE_SRC_STALE=yes|no`。
# 【为什么可信（不是又一个代理指标）】主控实测 **AOT 发布逐字节可复现**：同一份源 + 同一
#   `ArtifactsPath` 连发两次 `ndiff=0`，`-t:Rebuild` 全量重编后仍是同一 sha
#   ⇒ "源指纹相同 ⇒ 产物 sha 相同"有实测支撑；而"部署件 ≠ 当前源"另有一条**直接测量**：
#   在同一 ArtifactsPath 重发一次，sha 若变化即证明部署件陈旧（成本 ~20 s，幂等）。
# 【唯一实现】指纹算法在 `build/bridge-src-fp.sh`；**禁止**在别处内联重写文件清单
#   （本项目已登记过"一个数字两个消费者、一个陈旧"的事故）。
FP_LINE="$(bash "$ROOT/build/bridge-src-fp.sh")"
printf '  %s\n' "$FP_LINE"
{
    echo "$FP_LINE"
    echo "SRC_ROOTS=src/WpfGfx.Linux build/MilBridge（排除 bin/obj/.artifacts 与 tests/alt-route-b/spike）"
    echo "BRIDGE_SO_SHA256=$(sha256sum "$PUB/wpfgfx_cor3.so" | awk '{print $1}')"
    echo "PUBLISHED_AT=$(date -Is)"
    echo "IMPLEMENTATION=build/bridge-src-fp.sh（唯一实现；门禁 runner 必须调它，不许内联重写）"
} > "$PUB/bridge-src-fp.txt"
echo "  bridge-src-fp.txt ← $PUB（门禁用它判 BRIDGE_SRC_STALE）"

# 误落目录自检（坑 1 的回归守卫）
stray=$(find "$ROOT/build/MilBridge/src" "$ROOT/src" -type d -name '.artifacts' 2>/dev/null | head -3)
if [ -n "$stray" ]; then
    echo
    echo "⚠️ 检测到误落的 .artifacts（相对 ArtifactsPath 又被用了？）：" >&2
    printf '   %s\n' $stray >&2
fi

# ── app-local 副本一致性（T2 的只读校验器，2026-09-11 新增）─────────────────
# 【为什么接进发布】"发布目录 / app-local 目标落后一代"是本项目的老伤（债务 #20）：
#   `DllImport("libwpfwic.so")` 与 `DllImport("libwpfwin32.so")` 都会**先命中 app 目录那份**，
#   于是"我改了源码 / 我发了新件"和"探针实际测到的东西"可以是两个不同的二进制。
#   这个校验器**只读、不改写**，且在它自己的首次实跑里就抓到了"发布目录落后一代"。
# 【口径】它报 PASS 才算"全仓只有一份、且与权威件同 sha"；非 PASS 时**大声报**（不改退出码：
#   发布动作本身是否成功由上面的 rc 决定，副本不一致是**独立的一条事实**，不该被吞掉）。
SYNC_CHECK="$ROOT/build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh"
if [ -f "$SYNC_CHECK" ]; then
    echo
    echo "== app-local 副本一致性（只读校验；期望 APPSYNC=PASS）"
    syncout=$(bash "$SYNC_CHECK" 2>&1)
    printf '%s\n' "$syncout" | grep -E 'MISMATCH|DIVERGENT|退役别名|APPSYNC=' | sed 's/^/  /'
    if grep -q 'APPSYNC=PASS' <<<"$syncout"; then
        echo "  ✅ 全仓副本与权威件一致"
    else
        echo "  ⚠️ APPSYNC 非 PASS —— 有副本与权威件不同 sha（逐条见上；别让探针测到旧件）" >&2
        # 【为什么不断言"本次发布引入"】这些副本是**构建期**同步的，发布动作本身不碰它们。
        # 结构性修法见 build/MilBridge/tests/Directory.Build.targets 的 SyncProviderAuthority
        # （Release 构建后强制把权威 Provider 拷入 app-local）；其余目录跑各自的 run-*.sh
        # （脚本内含 dotnet build）即自动收敛。所以这里只报事实，不阻断发布、也不静默。
        echo "      （提示：上述副本不是本次发布引入的；重建对应工程或跑其 run-*.sh 即收敛）" >&2
    fi
else
    echo "  （未找到 $SYNC_CHECK —— 跳过 app-local 校验）"
fi

echo
echo "== 完成（发布目录：$PUB）"
