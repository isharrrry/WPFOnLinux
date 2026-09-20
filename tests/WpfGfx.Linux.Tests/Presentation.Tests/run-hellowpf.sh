#!/usr/bin/env bash
# M7c Phase 2 · HelloWpf 端到端 runner（**一条命令可重跑**）
#
#   tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh [超时秒数] [--no-build]
#   例：  DISPLAY=:99 tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh 45
#
# 它做四件事，全部可重复：
#   1. 增量构建 samples/HelloWpf（`-m:1`）——顺带保证 deps.json 与引用副本是最新的；
#   2. 把**原生**产物按 app-local 布局放进运行目录：
#        · libwpfwin32.so  —— M7b 的 Win32 shim（resolver 的"程序集同目录"档）
#        · wpfgfx_cor3.so  —— T1 的 MilBridge（T1 解析器的"应用目录"档）
#   3. 启动 HelloWpf，**轮询 X 根窗口**等它把窗口映射出来；
#   4. 一出现新窗口就 `xwd -id` 截屏 → `convert` 成 PNG → 打印颜色直方图。
#
# 【为什么运行目录是复制品而不是 samples/HelloWpf/bin】
#   后者同时是构建输出目录；把原生产物与截图往里塞会污染 T3 的产物。
#   复制到 ${M7C_RUN_DIR:-/tmp/m7c-hellowpf-<PID>} 再覆盖，两边都干净（按 PID 分目录，
#   避免并发运行互相覆盖 —— 主控的截图被覆盖过一次）。
#   注意**先构建再复制**：早期版本只复制不构建，于是跑的是 bin 里的旧快照 ——
#   实测撞到过已经被补丁 G 修掉的 AvTrace 注册表 NRE，那一轮的结论是假的。
#
# 【为什么必须用独立进程 xwd】
#   对齐 HelloMil 的证据链标准：自己 XGetImage 只能证明"我写进去的 buffer 能读回来"，
#   Present 到 X server 那一半根本没被测到。xwd 走 server 的另一条连接与另一套编码路径。

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
# ★ `#39` 阶段 2/3：读**权威件**的路径必须跟随**唯一声明**（`build/SelfBuiltConfig.props`）。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../../build/selfbuilt-config.sh"

TIMEOUT=45
NO_BUILD=0
for arg in "$@"; do
    case "$arg" in
        --no-build) NO_BUILD=1 ;;
        *[!0-9]*)   echo "用法: $0 [超时秒数] [--no-build]" >&2; exit 2 ;;
        *)          TIMEOUT="$arg" ;;
    esac
done

# 【为什么默认值带 $$】**并发运行会互相覆盖**：主控的截图就被后一次运行覆盖掉过
#   （证据直接没了）。默认按 PID 分目录；要固定路径就自己传 `M7C_RUN_DIR=…`。
#   ⚠️ 也别用 `mktemp -d` 就完事：留着一个可预测的路径，报告里才能写"去哪看证据"。
RESIZE_OBSERVED=1
OUT="${M7C_RUN_DIR:-/tmp/m7c-hellowpf-$$}"
SRC="$ROOT/samples/HelloWpf/bin/$SELFBUILT_CONFIG/net10.0"
LOG="$OUT/hellowpf.log"
SHOT="$OUT/hellowpf-window.png"
BUILD_LOG="/tmp/m7c-hellowpf-build.log"   # 放在 $OUT 之外：第 2 步会 rm -rf $OUT

export PATH="$HOME/.dotnet:$PATH"
export DISPLAY="${DISPLAY:-:99}"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# 【为什么先验 X server】实测（收尾轮）：:99 被别的轨道停掉之后，应用会在
#   `CreateWindowEx` 上抛 `Win32Exception(1400)`（ERROR_INVALID_WINDOW_HANDLE）——
#   栈停在 `MessageOnlyHwndWrapper` 的构造里，看起来像 shim 坏了，其实是**没有 X**。
#   这类"环境没了"必须由 runner 自己说清楚，不能让人去猜应用为什么崩。
# grep 自检：本脚本**每一处判据**都建立在 grep 上。它坏掉时（参数写错 / 不可用）必须**立刻**
#   失败，否则"取不到行"会被当成"没有这一行"——主控实测抓到过一次假 ✅：`grep -mE1` 的 `-m`
#   实参非法 ⇒ grep 报错退出 2，而脚本照样打印了 ✅。判据是**取到的值非空**，不是 grep 的退出码。
if ! printf 'grep-selfcheck\n' | grep -q 'grep-selfcheck'; then
    echo "❌ grep 不可用或行为异常 —— 本脚本的判据全部不可信，直接失败" >&2
    exit 2
fi

if ! command -v xdpyinfo >/dev/null 2>&1 || ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    echo "❌ DISPLAY=$DISPLAY 上没有 X server（先跑 tests/WpfGfx.Linux.Tests/Windowing.Tests/start-xvfb.sh start）" >&2
    echo "   说明：没有 X 时应用会在 CreateWindowEx 抛 Win32Exception(1400)，那是环境问题不是 shim 问题。" >&2
    exit 2
fi

echo "== M7c Phase 2 · HelloWpf runner"
echo "   仓库    : $ROOT"
echo "   DISPLAY : $DISPLAY"
echo "   运行目录: $OUT"

# ── 1.5 可选：UI 字体覆盖（HLWPF_UI_FONT）─────────────────────────────────────
# 【为什么需要这个开关】闸门 2（`Typeface.CheckFastPathNominalGlyphs` 尾部）判定
#   `glyphTypeface.FontFaceLayoutInfo.TypographyAvailabilities`：只要字体带
#   ccmp/liga/kern 之类"必须应用的排版特性"覆盖到 fast-text 字形，上游就**刻意**拒绝
#   快速路径（"太冒险，不优化"）⇒ 回落 LineServices ⇒ 我们这个移植里没有 LS ⇒ 抛异常。
#   实测 DejaVu / Noto 都是 23（= Available|Ideo|FastText|ExtraLangLoca）。
#   正解是 shaping/LineServices（独立里程碑）；在那之前用**剥离了 OpenType 布局表**的
#   派生字体，让掩码**真的**变成 0 —— 这不是骗闸门：快速路径本来就不应用 kerning/连字，
#   剥掉之后"没有必须应用的特性"是**测出来的事实**。
#
# 【两种用法】
#   HLWPF_UI_FONT=/path/to/UI-NoLayout.ttf   给**文件路径**：脚本会
#       ① 校验文件存在（不存在就报错退出，不静默回落）② `fc-scan` 读出字族名
#       ③ 设 `WPF_LINUX_FONT_DIR=<该文件所在目录>`（PresentationCore 的 Linux 字体工厂
#          优先用它，见 build/shims/PresentationCore.Factory.Linux.cs:322-330）
#       ④ 设 `WPF_LINUX_UI_FONT=<字族名>`（shim 的 SystemParametersInfo 把它填进 lfFaceName
#          ⇒ `SystemFonts.MessageFontFamily`）
#   HLWPF_UI_FONT="Noto Sans"                给**字族名**：只设 ④（字体须已在系统目录里）
#   不设（默认）：**行为与以前完全一致**（DejaVu Sans）。
# 无论哪种，脚本都会回显实际用的路径/大小/sha256/字族 —— 一眼看出用的哪一份。
UI_FONT_ENV=()
UI_FONT_DESC="默认（未设 HLWPF_UI_FONT）"
if [ -n "${HLWPF_UI_FONT:-}" ]; then
    case "$HLWPF_UI_FONT" in
        */*|*.ttf|*.otf|*.ttc)
            if [ ! -f "$HLWPF_UI_FONT" ]; then
                echo "❌ HLWPF_UI_FONT 指向的文件不存在：$HLWPF_UI_FONT" >&2
                exit 4
            fi
            UI_FONT_FAMILY="$(fc-scan --format '%{family}\n' "$HLWPF_UI_FONT" 2>/dev/null | head -1 | cut -d, -f1)"
            [ -n "$UI_FONT_FAMILY" ] || { echo "❌ fc-scan 读不出字族名：$HLWPF_UI_FONT" >&2; exit 4; }
            UI_FONT_ENV=(WPF_LINUX_FONT_DIR="$(cd "$(dirname "$HLWPF_UI_FONT")" && pwd)"
                         WPF_LINUX_UI_FONT="$UI_FONT_FAMILY")
            UI_FONT_DESC="$HLWPF_UI_FONT
     字族    : $UI_FONT_FAMILY
     大小    : $(stat -c%s "$HLWPF_UI_FONT") 字节
     sha256  : $(sha256sum "$HLWPF_UI_FONT" | cut -d' ' -f1)
     字体目录: $(cd "$(dirname "$HLWPF_UI_FONT")" && pwd)（WPF_LINUX_FONT_DIR）"
            ;;
        *)
            UI_FONT_ENV=(WPF_LINUX_UI_FONT="$HLWPF_UI_FONT")
            UI_FONT_DESC="字族名：$HLWPF_UI_FONT（不设 FONT_DIR，用系统目录）"
            ;;
    esac
fi
echo "   UI 字体 : $UI_FONT_DESC"

# ── 1. 构建（增量；顺带刷新 deps.json 与引用副本）────────────────────────────
if [ "$NO_BUILD" = "0" ]; then
    echo "== 1/4 增量构建 samples/HelloWpf（-m:1）"
    # 【探针开关】WPF_LINUX_HELLO_PROBE=1 时把 HelloWpfProbe.cs 编进应用
    #   （见 HelloWpf.csproj 里那段注释：它回答"可视树挂没挂 / render pass 跑没跑"，
    #    这两个问题外部观测区分不了，而修法完全不同）。默认关闭，验收路径零影响。
    PROBE_FLAG=""
    if [ "${WPF_LINUX_HELLO_PROBE:-0}" = "1" ]; then
        PROBE_FLAG="-p:WpfLinuxHelloProbe=true"
        echo "   （已打开 HelloWpf 运行期探针）"
    fi
    # 【构建失败必须当场退出 —— 这一条是实测踩出来的】
    #   原来这里只 `| grep -E ...`，pipefail 未开 ⇒ 构建**失败**时脚本照样往下走，
    #   拿**上一次的旧 DLL** 跑应用。症状极具误导性：改了探针源码、看到"构建"字样，
    #   跑出来的却是旧行为（本轮就发生了：探针没编进去，白白多跑一轮）。
    #   现在：构建失败即报错退出，绝不拿陈旧产物充当结果。
    # shellcheck disable=SC2086
    if ! timeout 300 dotnet build "$ROOT/samples/HelloWpf/HelloWpf.csproj" -m:1 $PROBE_FLAG >"$BUILD_LOG" 2>&1; then
        echo "   ❌ 构建失败 —— 拒绝用陈旧产物继续（日志尾 15 行）：" >&2
        tail -15 "$BUILD_LOG" | sed 's/^/      /' >&2
        exit 3
    fi
    grep -E "已成功生成|生成失败|个警告|个错误" "$BUILD_LOG" | sed 's/^/   /'
else
    echo "== 1/4 跳过构建（--no-build）"
fi

# ── 2. 组装运行目录 ──────────────────────────────────────────────────────────
echo "== 2/4 组装运行目录"
[ -d "$SRC" ] || { echo "找不到 $SRC —— 先构建 samples/HelloWpf" >&2; exit 2; }
rm -rf "$OUT"; mkdir -p "$OUT"
cp -r "$SRC"/. "$OUT"/

# 2a) 自产程序集：**只取工程自己的产物**（`build/<X>.Linux/bin/Debug/<X>.dll`）。
#     ⚠️ 不能用 `build/*.Linux/bin/Debug/*.dll` 全量复制：glob 按字典序展开，
#     PresentationFramework.Linux 排在 PresentationCore.Linux **之后**，而它的输出目录里
#     带着一份**构建时快照的** PresentationCore.dll —— 会把刚复制进去的新版盖回去。
#     症状极具误导性：改了源码、构建成功、DLL 里确实有新代码，但跑起来行为不变。
for d in "$ROOT"/build/*.Linux/bin/"$SELFBUILT_CONFIG"/*.dll; do
    [ -f "$d" ] || continue
    proj="$(basename "$(dirname "$(dirname "$(dirname "$d")")")")"
    case "$proj" in CycleStub.*) continue ;; esac
    [ "$(basename "$d" .dll)" = "${proj%.Linux}" ] || continue
    cp -f "$d" "$OUT"/ 2>/dev/null
done

# 2b) DirectWrite.Linux.Provider：HelloWpf 现在**直接**引用它（见 csproj 的 M7c 注释），
#     所以它本来就在 bin 里；这里只用权威产物再刷一份，避免用到 PC 输出目录里的依赖副本。
PROVIDER="$ROOT/build/DirectWrite.Linux/Provider/bin/$SELFBUILT_CONFIG/DirectWrite.Linux.Provider.dll"
if [ -f "$PROVIDER" ]; then cp -f "$PROVIDER" "$OUT"/; else
    echo "   警告：找不到 $PROVIDER（PC 的模块初始化器需要它）" >&2
fi

# 2c) Win32 shim：app-local 部署（M7b resolver 的"程序集同目录"档）
SHIM="$ROOT/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
if [ -f "$SHIM" ]; then
    cp -f "$SHIM" "$OUT"/
    # 额外再放一份**以 Windows DLL 名命名**的副本（内容同一个 ELF）。
    # 为什么需要：`build/shims/Win32ShimResolver.cs` 的 MappedLibraries 只列了
    # user32/gdi32/kernel32/PresentationNative_cor3/uxtheme/wtsapi32（父级已加后两个）。
    # 落到这里的是**还没被映射、但 shim 已经能真正服务**的 DLL 名：
    #   · uxtheme.dll / wtsapi32.dll —— 现已进 MappedLibraries；保留别名作双保险，
    #     顺带实测"resolver 返回 IntPtr.Zero 时默认探测能不能命中 app-local 同名 ELF"。
    #   · shell32.dll —— M7c Phase 2 实测卡点：`Window.ShowHelper → CreateSourceWindow
    #     → SetupInitialState → UpdateIcon → IconHelper.GetDefaultIconHandles(IconHelper.cs:76)`
    #     要 `ExtractIconEx`，那是 `[DllImport("shell32.dll")]`。shim **已经导出**
    #     `ExtractIconEx`（裸名，见 tools/check-shim-coverage.py 的 ✓），缺的只是 DLL 名这一层。
    #   真正的修法是给 MappedLibraries 加 `"shell32.dll"`（在 build/ 下，本轮边界外，
    #   已登记到 docs/U2-M7c-report.md 的缺口清单）。
    # 注意**不要**顺手把 dwmapi/shcore/ole32 也 alias 进来：shim 里没有它们的符号，
    # 别名只会把清楚的 DllNotFoundException 变成 EntryPointNotFoundException，没有净收益。
    for alias in uxtheme.dll wtsapi32.dll WtsApi32.dll shell32.dll; do
        cp -f "$SHIM" "$OUT/$alias"
    done
    echo "   Win32 shim: libwpfwin32.so + uxtheme/wtsapi32/shell32 别名（app-local）"
else
    echo "   警告：找不到 $SHIM —— 先跑 src/WpfGfx.Linux.Native/build-shim.sh" >&2
fi

# 2d) MilBridge：app-local 部署（T1 解析器的"应用目录"档；/tmp 下只有这一档可用）
#
# ⚠️ **必须整个发布目录一起放**，不能只拷 wpfgfx_cor3.so：AOT 镜像内部的 Skia P/Invoke
#    只在**它自己所在的目录**找 `libSkiaSharp.so`（T1 实测：只拷 .so →
#    `DllNotFoundException: libSkiaSharp`）。发布目录里 `wpfgfx_cor3.so` 与
#    `libSkiaSharp.so` 本来就是同级的，所以按 *.so 整体复制即可。
MILDIR="$(dirname "$(find "$ROOT/build/MilBridge/.artifacts" -name 'wpfgfx_cor3.so' 2>/dev/null | head -1)" 2>/dev/null)"
if [ -n "$MILDIR" ] && [ -d "$MILDIR" ]; then
    echo "   MilBridge 发布目录: $MILDIR"
    for so in "$MILDIR"/*.so; do
        [ -f "$so" ] || continue
        cp -f "$so" "$OUT"/ && echo "     + $(basename "$so")（$(stat -c%s "$so") 字节）"
    done
    [ -f "$OUT/libSkiaSharp.so" ] || echo "   警告：libSkiaSharp.so 没进应用目录 —— CPU 渲染会 DllNotFoundException" >&2
else
    echo "   警告：找不到 wpfgfx_cor3.so —— MIL 桥接会 DllNotFoundException" >&2
fi

printf '   deps.json 里的 DirectWrite.Linux.Provider：'
if grep -q '"DirectWrite.Linux.Provider[^"]*"' "$OUT/HelloWpf.deps.json" 2>/dev/null; then
    grep -o '"DirectWrite.Linux.Provider[^"]*"' "$OUT/HelloWpf.deps.json" | sort -u | tr '\n' ' '
    echo
else
    echo "（没有！csproj 的直接引用没生效）"
fi

# ── 3. 启动并轮询窗口 ────────────────────────────────────────────────────────
echo "== 3/4 启动 HelloWpf（超时 ${TIMEOUT}s）"
before="$(xwininfo -root -children 2>/dev/null | grep -oE '0x[0-9a-f]+' | sort -u | tr '\n' ' ')"

cd "$OUT"
: > "$LOG"
# 【为什么默认打开 MIL 台账】Phase 2 的观测手段只有"退出码 + xwd 截屏"两样，
#   上一轮实测证明了这不够：窗口出来了（xwininfo 640x400 IsViewable）、截屏纯白、
#   应用日志**一行都没有** —— 到底是"渲染 pass 没跑 / 通道里没有带 HWND 的目标 /
#   渲染了没画上窗口"，只靠截屏分不出来。`WPF_LINUX_MIL_TRACE=1` 让
#   src/WpfGfx.Linux/Interop/MilPresentation.cs 把绑窗/呈现/失败原因打到 stderr，
#   直接进 $LOG。默认开（可从外部覆盖成 0 关闭）。
#   Win32 侧的**消息台账**（shim 的 wpf_dispatch_to_window，src/WpfGfx.Linux.Native）
#   同理由：托管渲染 pass 本轮不可改，但要判断"它在不在动"。
#   两个都默认开，都可用同名环境变量从外部覆盖成 0。
# `env` + 数组而不是行内前缀：UI 字体那条是**可选**的（见 1.5），
#   行内前缀没法"有条件地"加一个赋值（空值会被 getenv 当成"设了但为空"）。
#   `env` 会 exec，所以 `$!` 仍是应用自己的 PID。
env WPF_WIN32_MSG_TRACE="${WPF_WIN32_MSG_TRACE:-1}" \
    WPF_LINUX_MIL_TRACE="${WPF_LINUX_MIL_TRACE:-1}" \
    "${UI_FONT_ENV[@]}" \
    dotnet HelloWpf.dll > "$LOG" 2>&1 &
APP_PID=$!

# 【判据不能只看"root 下多了个窗口"】
#   实测：WPF 起来后会先建**两个 message-only / 通知窗口**（`HwndWrapper` + `Dispatcher`
#   的 1×1 窗口，坐在 0,0、未映射）。第一版 runner 把那个 1×1 当成"应用窗口"，
#   于是 xwd 报 `BadMatch (invalid parameter attributes)` —— 对未映射/InputOnly 窗口
#   X_GetImage 本来就不合法。
#   所以判据是：**新出现的** 且 `Map State: IsViewable` 且 宽高 ≥ 64 的窗口。
#   同时把"看到过的新窗口"全部记下来（含被过滤掉的），便于诊断。
WINDOW=""
SEEN=""
# 新窗口的几何**必须在轮询当时**记下来：应用崩掉后它的 X 连接关闭、窗口立即消失，
# 事后 xwininfo 只会得到空 —— 第一版就是这么丢掉几何信息的。
WINDOWS_TXT="$OUT/windows.txt"
: > "$WINDOWS_TXT"
DEADLINE=$(( $(date +%s) + TIMEOUT ))
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
    kill -0 "$APP_PID" 2>/dev/null || break
    for w in $(xwininfo -root -children 2>/dev/null | grep -oE '0x[0-9a-f]+' | sort -u); do
        case " $before " in *" $w "*) continue ;; esac
        case " $SEEN " in
            *" $w "*) ;;
            *) SEEN="$SEEN $w"
               xwininfo -id "$w" 2>/dev/null | awk -F: -v id="$w" '
                   /^  Width:/  {gsub(/ /,"",$2); gw=$2}
                   /^  Height:/ {gsub(/ /,"",$2); gh=$2}
                   /Map State:/ {gsub(/^ +/,"",$2); gs=$2}
                   END {printf "     %s  %sx%s  map=%s\n", id, gw, gh, gs}' >> "$WINDOWS_TXT"
               ;;
        esac

        info="$(xwininfo -id "$w" 2>/dev/null)"
        gw="$(echo "$info" | awk -F: '/^  Width:/{gsub(/ /,"",$2);print $2}')"
        gh="$(echo "$info" | awk -F: '/^  Height:/{gsub(/ /,"",$2);print $2}')"
        gs="$(echo "$info" | awk -F: '/Map State:/{gsub(/^ +/,"",$2);print $2}')"
        [ -n "$gw" ] || continue
        [ "$gw" -ge 64 ] 2>/dev/null || continue
        [ "$gh" -ge 64 ] 2>/dev/null || continue
        case "$gs" in *IsViewable*) ;; *) continue ;; esac
        WINDOW="$w"; break
    done
    [ -n "$WINDOW" ] && break
    sleep 0.25
done

if [ -s "$WINDOWS_TXT" ]; then
    echo "   期间新出现的 X 窗口（含被过滤掉的小窗口）："
    cat "$WINDOWS_TXT"
fi

# ── 3.5 等"第一帧真的画上去"再截屏 ─────────────────────────────────────────
# 【为什么必须等 —— 本轮实测踩到的时序坑】
#   窗口 map 得**很早**（Show 一返回就 map），而"内容画上去"要晚得多：
#   字体/主题加载 + 首次布局 + 渲染 + 呈现，实测在这台机器上要几秒。
#   原来第 4 步一发现窗口就 xwd ⇒ 截到的是 X 的**窗口底色白**（我们建窗时给的
#   background_pixel），于是"能渲染"被误判成"全白"。这不是渲染问题，是**取样太早**。
#   现在改成：等应用日志里出现第一帧呈现（`WPF_LINUX_MIL_TRACE=1` 的台账会打
#   `通道 N → HWND ... 已呈现`），最多等 $FRAME_WAIT 秒；等不到再截（并如实标注）。
FRAME_WAIT="${HLWPF_FRAME_WAIT:-15}"
if [ -n "$WINDOW" ]; then
    # 【判据是"有内容的帧"，不是"第一帧"】提交驱动的呈现会在 commit 时立刻发一帧，
    #   而那一帧可能只包含资源创建（`skia 指令 0 条`）。实测：只等"已呈现"会截到
    #   空帧（窗口 xwd 全白），而稍后那一帧才有 `skia 指令 11 条`。
    #   所以等 `已呈现 …（skia 指令 N 条…）` 里 **N>0**；超时再退回"任意一帧"并如实标注。
    waited=0
    while [ "$waited" -lt "$((FRAME_WAIT * 4))" ]; do
        grep -qE "skia 指令 [1-9][0-9]* 条" "$LOG" 2>/dev/null && break
        kill -0 "$APP_PID" 2>/dev/null || break
        sleep 0.25; waited=$((waited + 1))
    done
    if grep -qE "skia 指令 [1-9][0-9]* 条" "$LOG" 2>/dev/null; then
        # 【不能用 `grep -mE1`】`-m` 的实参必须是数字，'E1' 会被当成计数 ⇒ grep 报
        #   "无效的最大计数" 并退出 2；而它在 `$( )` 里失败**不会**让脚本失败 ⇒ 空串也照打。
        #   正确写法：先取到变量，再判空；判据是"拿到的行非空"，不是 grep 的退出码。
        first_content="$(grep -E 'skia 指令 [1-9][0-9]* 条' "$LOG" 2>/dev/null | head -1 | sed 's/^ *//')"
        if [ -n "$first_content" ]; then
            echo "   等到首个**有内容**的帧（等了约 $((waited / 4))s）：$first_content"
        else
            echo "   ⚠️ 台账里没有'有内容'的帧行（等到了呈现帧但 skia 指令一直是 0 条）"
        fi
    elif grep -q "已呈现" "$LOG" 2>/dev/null; then
        echo "   ⚠️ 只等到空帧（skia 指令 0 条）—— 下面截到的可能是未出内容的画面"
    else
        echo "   ⚠️ 等了 ${FRAME_WAIT}s 没等到任何呈现帧"
    fi
fi

# ── 4. 截屏 ─────────────────────────────────────────────────────────────────
if [ -n "$WINDOW" ]; then
    echo "== 4/4 发现新窗口 $WINDOW，用独立进程 xwd 截屏"
    xwininfo -id "$WINDOW" 2>/dev/null | sed -n '1,15p' | sed 's/^/   /'
    if xwd -id "$WINDOW" -display "$DISPLAY" -out "$OUT/hellowpf-window.xwd" 2>"$OUT/xwd.err" \
       && convert "$OUT/hellowpf-window.xwd" "$SHOT" 2>>"$OUT/xwd.err"; then
        echo "   截图：$SHOT（$(stat -c%s "$SHOT") 字节）"
        echo "   颜色直方图（前 8 色）："
        convert "$SHOT" -colors 8 -format %c histogram:info:- 2>/dev/null | head -8 | sed 's/^/     /'
        # 独立交叉验证：同一时刻**根窗口**的同区域也必须一致（排除"窗口内容 vs 屏上"的分歧）
        if xwd -root -display "$DISPLAY" -out "$OUT/root.xwd" 2>/dev/null; then
            convert "$OUT/root.xwd" -crop "$(xwininfo -id "$WINDOW" 2>/dev/null | awk '/Width:/{w=$2} /Height:/{h=$2} END{print w"x"h}')+0+0" \
                    +repage "$OUT/root-crop.png" 2>/dev/null && {
                echo "   屏上同区域（根窗口裁剪）直方图（前 4 色）："
                convert "$OUT/root-crop.png" -colors 4 -format %c histogram:info:- 2>/dev/null | head -4 | sed 's/^/     /'
            }
        fi
    else
        echo "   xwd/convert 失败：" ; sed 's/^/     /' "$OUT/xwd.err" | head -5
    fi
else
    echo "== 4/4 未观察到新窗口（应用没有把窗口映射出来）"
fi

# ── 4.45 输入路径**门禁**（HLWPF_INPUT_PROBE=1）──────────────────────────────
# 【它挡的是一条"绿得很漂亮但一动鼠标就死"的路】
#   真应用收到**任何**鼠标输入都会走到：
#     HwndMouseInputProvider → InputManager.ProcessInput → TextServicesManager.PreProcessInput
#     → TextServicesLoader.TIPsWantToRun（Registry.CurrentUser 在 Unix 上是 null）→ NRE → SIGABRT
#   M2 验收全程没有输入，所以从没撞到 —— 本段把它变成**可复现、可机读**的判据。
#
# 【判据两条，缺一即 FAIL —— 第二条是防"用抑制输入换不崩"的】
#   ⓐ 应用**存活**（它是本 runner 拉起的子进程；崩了只影响这一段，不会带走测试宿主）
#   ⓑ 四类事件**真的到达窗口**：WM_MOUSEMOVE(0x0200) / WM_LBUTTONDOWN(0x0201) /
#      WM_MOUSEWHEEL(0x020A) / WM_KEYDOWN(0x0100)；另外 WM_CHAR(0x0102) 只能由
#      **Dispatcher 的消息泵**（TranslateMessage）产生 ⇒ 它出现即"事件走到了 WPF 的消息循环"。
#   （消息名表里没有鼠标/键盘项，所以按**消息号**grep；号是 Win32 的公开常量，不会漂。）
#
# 【输出】`INPUT_PROBE=PASS|FAIL`（机读，ManagedLayer 的门禁用例解析这一行）。
#   runner 自己的退出码仍然等于**应用**的退出码（既有契约不改）。
if [ -n "$WINDOW" ] && [ "${HLWPF_INPUT_PROBE:-0}" = "1" ] && command -v xdotool >/dev/null 2>&1; then
    echo
    echo "== 4.45 输入路径门禁（真窗口 $WINDOW + 真注入）"
    msg_count() { grep -c "msg=0x$(printf '%04x' "$1")" "$LOG" 2>/dev/null || true; }

    xdotool mousemove --window "$WINDOW" 40 40 2>/dev/null || true; sleep 0.6
    xdotool click --window "$WINDOW" 1 2>/dev/null || true;            sleep 0.4
    xdotool click --window "$WINDOW" 4 2>/dev/null || true;            sleep 0.4   # 滚轮上
    xdotool click --window "$WINDOW" 5 2>/dev/null || true;            sleep 0.4   # 滚轮下
    xdotool mousemove --window "$WINDOW" 60 50 2>/dev/null || true;    sleep 0.4
    xdotool key --window "$WINDOW" a 2>/dev/null || true;              sleep 0.4
    xdotool key --window "$WINDOW" shift+a 2>/dev/null || true;        sleep 0.8

    # 自检：grep 不可用 / 参数写错时必须**立刻**暴露，不能让后面的判据全变成"0 条"而看似正常。
    if ! grep -q "hwnd=" "$LOG" 2>/dev/null; then
        echo "   ❌ 消息台账里连一行都没有（grep 不可用或 \$LOG 为空）⇒ 本段判据不可信，直接 FAIL"
        echo "INPUT_PROBE=FAIL"
        grep -q "hwnd=" "$LOG" || true
    fi
    n_move=$(msg_count 0x0200); n_down=$(msg_count 0x0201); n_wheel=$(msg_count 0x020a)
    n_key=$(msg_count 0x0100);  n_char=$(msg_count 0x0102)
    # grep -c 在无匹配时返回 0 行 + 退出码 1 ⇒ 上面用 || true，这里兜底成 0
    for v in n_move n_down n_wheel n_key n_char; do
        eval "[ -n "\\$$v" ]" || eval "$v=0"
    done
    echo "   消息台账（到达窗口的条数）：MOUSEMOVE=$n_move LBUTTONDOWN=$n_down MOUSEWHEEL=$n_wheel KEYDOWN=$n_key CHAR=$n_char"

    if kill -0 "$APP_PID" 2>/dev/null; then
        alive=1; echo "   ⓐ 应用存活：是"
    else
        alive=0; echo "   ⓐ 应用存活：**否**（被输入弄死了）"
        crash="$(grep -A 6 "Unhandled exception" "$LOG" 2>/dev/null | head -8)"
        if [ -n "$crash" ]; then
            printf '%s\n' "$crash" | sed 's/^/     /'
        else
            echo "     （日志里没有 Unhandled exception 行 —— 死因不是托管异常，看 \$LOG 全文）"
        fi
    fi

    missing=""
    [ "${n_move:-0}"  -ge 1 ] || missing="$missing MOUSEMOVE"
    [ "${n_down:-0}"  -ge 1 ] || missing="$missing LBUTTONDOWN"
    [ "${n_wheel:-0}" -ge 1 ] || missing="$missing MOUSEWHEEL"
    [ "${n_key:-0}"   -ge 1 ] || missing="$missing KEYDOWN"
    if [ -z "$missing" ]; then
        echo "   ⓑ 事件到达窗口：是（MOUSEMOVE/LBUTTONDOWN/MOUSEWHEEL/KEYDOWN 四类齐全）"
    else
        echo "   ⓑ 事件到达窗口：**否** —— 缺：$missing"
    fi
    [ "${n_char:-0}" -ge 1 ] && echo "   ⓒ WM_CHAR 出现（$n_char 条）⇒ 按键走过了 Dispatcher 的消息泵（TranslateMessage）"

    if [ "$alive" = "1" ] && [ -z "$missing" ]; then
        echo "INPUT_PROBE=PASS"
    else
        echo "INPUT_PROBE=FAIL"
    fi
fi

# ── 4.5 外部 resize → 尺寸跟不跟得上（债务 #3 的 **app 级**观测）──────────────
# 【为什么在真应用上还要量一遍】ManagedLayer 的 `M7cRealAttachmentTests` 已经在 MIL 层
#   用真窗口 + 独立进程 xwd + 逐像素计数证明了"resize 后按新尺寸重渲、不留旧尺寸图、
#   没有 X 底色空白"（判据：填充像素数 == 新 W×H）。那是**我们自己的呈现层**的账。
#   真应用里 resize 要经过另一条链：X ConfigureNotify → shim 的 WM_SIZE →
#   HwndTarget.OnResize → MediaContext.Resize → **渲染 pass** → 提交 → 呈现。
#   这一节量的是**那条链**，量出来的事实与 MIL 层分开写，不混为一谈。
# 【为什么用 xdotool 从外部改】等价于 WM 拖边框：不碰应用内存、不经应用自己的 API。
# 【判据为什么要"放大"而不是"缩小"】缩小只是把旧帧裁掉（新旧截图必然不同，容易误判成
#   "重渲了"）；放大则会把**没画过的区域**暴露出来 —— 那正是债务 #3 说的"旧尺寸图 + 空白"。
RESIZE_W="${HLWPF_RESIZE_W:-900}"
RESIZE_H="${HLWPF_RESIZE_H:-620}"
if [ -n "$WINDOW" ] && command -v xdotool >/dev/null 2>&1; then
    geom_now="$(xwininfo -id "$WINDOW" 2>/dev/null | awk '/Width:/{w=$2} /Height:/{h=$2} END{print w"x"h}')"
    echo
    echo "== 4.5 外部放大：${geom_now} → ${RESIZE_W}x${RESIZE_H}（xdotool windowsize）"
    frames_before=$(grep -c "已呈现" "$LOG" 2>/dev/null || true); frames_before=${frames_before:-0}

    # 【为什么先把指针挪开】实测（本轮）：窗口**变大到指针所在处**时 X server 会发 EnterNotify，
    #   shim 把它翻成 WM_MOUSEMOVE，于是真应用走到
    #     HwndMouseInputProvider.FilterMessage → InputManager.ProcessInput
    #     → TextServicesManager.PreProcessInput → TextServicesLoader.TIPsWantToRun
    #   ⇒ **NullReferenceException → 进程 SIGABRT**（`TextServicesLoader.cs:192`）。
    #   那是**输入路径**的问题（与 resize 无关，单独登记），但它会把本次 resize 观测直接打断：
    #   所以这里先把指针停到窗口外，让"resize→重渲"这件事**不被输入崩溃掩盖**。
    if [ "${HLWPF_KEEP_POINTER:-0}" != "1" ]; then
        xdotool mousemove 1250 1000 2>/dev/null || true
        sleep 0.3
        kill -0 "$APP_PID" 2>/dev/null || echo "   ⚠️ 挪指针这一步就把应用弄死了（输入路径问题，见上）"
    fi

    xdotool windowsize "$WINDOW" "$RESIZE_W" "$RESIZE_H" 2>"$OUT/xdotool.err" || true

    # 【判据必须看**增量**，不能只看"台账里有没有这一行"】启动帧可能**本来就是**这个尺寸
    #   （把 resize 目标设成当前尺寸时尤其明显）⇒ 只看"有这一行"会立刻打 ✅，而其实什么都没发生。
    #   所以先记下 resize 前该尺寸的行数，再要求它在 resize 之后**增加**。
    hits_before=$(grep -cE "已呈现 ${RESIZE_W}x${RESIZE_H}" "$LOG" 2>/dev/null || true)
    hits_before=${hits_before:-0}
    rw=0
    while [ "$rw" -lt 40 ]; do
        hits_now=$(grep -cE "已呈现 ${RESIZE_W}x${RESIZE_H}" "$LOG" 2>/dev/null || true)
        [ "${hits_now:-0}" -gt "${hits_before:-0}" ] && break
        kill -0 "$APP_PID" 2>/dev/null || break
        sleep 0.25; rw=$((rw + 1))
    done

    # 【先判"被观测对象还活着吗"】收尾轮实测：本段**先前那一步挪指针**就可能把应用弄死
    #   （TSF 空引用），此时"台账没有新尺寸帧"是**观测无效**，不是"没重渲"。
    #   把这两件事分开写，是本段最重要的一条纪律 —— 假绿的来源往往就是它。
    if ! kill -0 "$APP_PID" 2>/dev/null; then
        echo "   ❌ 观测无效：应用在 resize 之前就已经死了（见上面的输入路径诊断）——本段数字**不可用**"
        RESIZE_OBSERVED=0
    else
        RESIZE_OBSERVED=1
    fi
    echo "   X 侧窗口：$(xwininfo -id "$WINDOW" 2>/dev/null | awk '/Width:/{w=$2} /Height:/{h=$2} END{print w"x"h}')"
    echo "   应用收到的 WM_SIZE 次数：$(grep -c 'WM_SIZE' "$LOG" 2>/dev/null || echo 0)" \
         "（最后一次：$(grep 'WM_SIZE' "$LOG" 2>/dev/null | tail -1 | sed 's/.*lp=//')）"

    # 帧数判据：用台账里的**累计帧数**（MilPresentation.FramesPresented），
    # 【不能用 `grep -c 已呈现`】那条明细是**抽样**的（前 5 次 + 每 120 次），
    #   计数与真实帧数完全不是一回事 —— 第一版就是这么写的，量出来的"帧数"不可信。
    cum_before=$(grep -oE "累计帧数 = [0-9]+" "$LOG" 2>/dev/null | tail -1 | grep -oE "[0-9]+")
    # 【判据必须是"真的取到了那一行"，不能是 grep 的退出码】第一版写成
    #   `grep -mE1 …` —— 非法实参 ⇒ grep 自己失败（stderr: 无效的最大计数），
    #   而 ✅ 照样打印：**指示灯在说谎**。主控实测抓到过这一条，此处按"取到非空行"重写。
    hits_after=$(grep -cE "已呈现 ${RESIZE_W}x${RESIZE_H}" "$LOG" 2>/dev/null || true)
    hits_after=${hits_after:-0}
    resize_frame="$(grep -E "已呈现 ${RESIZE_W}x${RESIZE_H}" "$LOG" 2>/dev/null | tail -1 | sed 's/^ *//')"
    if [ "${hits_after:-0}" -gt "${hits_before:-0}" ] && [ -n "$resize_frame" ]; then
        echo "   ✅ 台账里出现**新尺寸**的呈现帧（新尺寸行数 ${hits_before} → ${hits_after}，等了约 $((rw / 4))s）："
        echo "     $resize_frame"
    elif [ "$RESIZE_OBSERVED" = "1" ]; then
        echo "   ⚠️ app 级：resize 之后**没有**新尺寸的呈现帧（等了 $((rw / 4))s）；" \
             "resize 前后累计帧数 = ${cum_before:-?}（这是台账里最后一次报的数）"
        echo "      ⚠️ 待查（**不要**照这句下结论）：下面截图显示画面**确实**铺满了新尺寸，"
        echo "         而台账与通道计数器都没动 —— 到底是谁把新尺寸的画面画上去的，"
        echo "         本 runner 的仪器还答不了（MIL 台账 + 通道计数器 + xwd 三样加起来仍不够）。"
        echo "         MIL/呈现层那一半是**闭合**的：ManagedLayer 的 M7cRealAttachmentTests"
        echo "         （真窗口 + 独立进程 xwd + 逐像素：200x120 → 320x200 后填充像素 24000 → 64000、X 底色 0）。"
    fi

    # 放大后的截图：没被重画的话，新暴露的区域就是**我们建窗时给的 X 底色（白）**。
    if xwd -id "$WINDOW" -display "$DISPLAY" -out "$OUT/hellowpf-resized.xwd" 2>>"$OUT/xwd.err" \
       && convert "$OUT/hellowpf-resized.xwd" "$OUT/hellowpf-resized.png" 2>>"$OUT/xwd.err"; then
        rshot="$OUT/hellowpf-resized.png"
        echo "   resize 后截图：$rshot（$(stat -c%s "$rshot") 字节，$(identify -format '%wx%h' "$rshot" 2>/dev/null)）"
        white=$(convert "$rshot" -alpha off txt:- 2>/dev/null | grep -c '#FFFFFF' || true)
        total=$((RESIZE_W * RESIZE_H))
        echo "   纯白（X 窗口底色）像素：${white:-0} / $total"
        if [ -f "$SHOT" ]; then
            before_geom="$(identify -format '%wx%h' "$SHOT" 2>/dev/null)"
            # 把 resize **之前**那张按旧尺寸裁出来，与 resize 之后逐像素比：
            # AE≈0 ⇒ 新画面就是旧帧的左上角裁剪（= 只是被裁了，没有重画）。
            convert "$SHOT" -crop "${geom_now}+0+0" +repage "$OUT/hellowpf-before-crop.png" 2>/dev/null
            ae="$(compare -metric AE "$OUT/hellowpf-before-crop.png" "$rshot" null: 2>&1 | tr -d '\n' || true)"
            echo "   before($before_geom) 的左上 ${geom_now} 裁剪 与 after 的逐像素差：AE=${ae:-?}"
            echo "     （AE=0 ⇒ after 只是旧帧被裁/被贴回左上角 —— 没有重渲；AE>0 ⇒ 画面确实变了）"
        fi
        echo "   resize 后颜色直方图（前 6 色）："
        convert "$rshot" -colors 6 -format %c histogram:info:- 2>/dev/null | head -6 | sed 's/^/     /'
    else
        echo "   resize 后 xwd/convert 失败："
        sed 's/^/     /' "$OUT/xwd.err" | head -5
    fi
fi

# 等应用自己结束（或被超时终止）
for _ in $(seq 1 40); do
    kill -0 "$APP_PID" 2>/dev/null || break
    sleep 0.25
done
if kill -0 "$APP_PID" 2>/dev/null; then kill -TERM "$APP_PID" 2>/dev/null; sleep 1; fi
wait "$APP_PID" 2>/dev/null
APP_EXIT=$?

echo
echo "== 应用退出码：$APP_EXIT"
if [ -s "$LOG" ]; then
    echo "== 输出（最多 25 行）"
    head -25 "$LOG" | sed 's/^/   /'
fi
echo "== 完整日志：$LOG"

exit "$APP_EXIT"
