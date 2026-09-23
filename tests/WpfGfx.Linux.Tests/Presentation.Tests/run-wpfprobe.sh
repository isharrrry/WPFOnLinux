#!/usr/bin/env bash
# WpfFeatureProbe · **功能广度** runner（块级台账 + 像素核对 + 崩溃分诊）
#
#   tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh [超时秒数] [--tier default|both] [--only=a,b]
#
# 【与 run-wpftextdemo.sh 的关系】**不是另起一套**：配置七元组表头、按 PID 收尾、孤儿精确回收、
#   Xvfb 自起自灭、root 连拍+按几何裁剪、`frames_good`/`INCONCLUSIVE` 语义、读图格 —— 全部**照搬**同一套做法；
#   本文件**不改动**那个 runner（它已冻结为交付基线），只把"判什么"换成**块级台账**。
#
# 【它比样例 runner 多做的两件事】
#   1. **块级台账解析**：应用每块自报 `[feat] <名称> OK|FAIL|INCONCLUSIVE <证据>`，
#      本 runner 逐块汇总 `WFP_SUMMARY blocks=N ok=… fail=… inconclusive=…`；
#   2. **崩溃分诊**：块级 try/catch 抓不到**原生级崩溃** ⇒ 若一轮下来有块**没自报**，
#      自动用 `--only=<块名>` **逐块复跑**，把"崩在谁身上"钉出来（复跑结果单独标注，不混进主台账）。
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
# ★ `#39` 阶段 2/3：读**权威件**的路径必须跟随**唯一声明**（`build/SelfBuiltConfig.props`）。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../../build/selfbuilt-config.sh"
SAMPLE="WpfFeatureProbe"
SRC="$ROOT/samples/$SAMPLE/bin/$SELFBUILT_CONFIG/net10.0"

TIMEOUT=45; NO_BUILD=0; TIER=default; ONLY=""; TRIAGE="${WFP_TRIAGE:-1}"; APP_ENV=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-build) NO_BUILD=1; shift ;;
        --tier)     TIER="${2:-default}"; shift 2 ;;
        --only=*)   ONLY="${1#--only=}"; shift ;;
        # 诊断用：给**应用**额外传 env（逗号分隔，例：WPF_LINUX_TEXTLINE_DIAG=1,WPF_LINUX_DRAW_CENSUS=1）
        --app-env=*) APP_ENV="${1#--app-env=}"; shift ;;
        default|both) TIER="$1"; shift ;;
        *[!0-9]*)   echo "用法: $0 [超时秒数] [--tier default|both] [--only=a,b] [--no-build]" >&2; exit 2 ;;
        *)          TIMEOUT="$1"; shift ;;
    esac
done

# 【必须显式校验档位】`--tier X` 会**吃掉** X 这个位置参数 ⇒ 不校验就会出现"非法档位静默当默认档跑"
#   （实测踩到：`--tier bogus` 一路跑到起 Xvfb）。凡是"参数被吃掉"的解析器都要在**解析之后**再验一遍。
case "$TIER" in
    default|both) ;;
    *) echo "❌ --tier 只认 default|both（收到 '$TIER'）" >&2; exit 2 ;;
esac

OUT="${WFP_RUN_DIR:-/tmp/wfp-run-$$}"

# ── 桥契约判定（T2b 新格式）——**判定函数化 + 可离线自测** ──────────────────────
#   【为什么不是一行 case】2026-09-13 主控现场读码抓到两处"仪器看不见对象"缺陷：
#     ① 样例 runner 对**整行**判 `[`：而台账行形如
#        `[mil   34]   ★ 首个**有内容**的帧…（skia 指令 261 条，未画种类 0）`
#        ⇒ 行首就有 `[mil 34]` ⇒ `has_clause` **恒为 1** ⇒ 空态恒假红、且**旧桥 + N>0 时恒真绿**
#        （恰好吃掉它本来要抓的那个"取到旧桥"）；
#     ② 探针 runner 用 `grep -oE '…未画种类 [0-9]+'` 抽 `nd_pair` ⇒ **后缀被切掉** ⇒ `has_clause` 恒为 0
#        ⇒ N>0 时**恒报** SUSPECT_STALE_BRIDGE。
#   正确做法：**先切出"未画种类 N"之后的尾巴**再判；空态尾巴必须**恰好是 `）`**；
#   非空态必须形如 ` [MilXxx×N…]）`。
bridge_contract() {   # $1 = 含"未画种类 N"的那一行；stdout = 判定串
    local line="$1" tail n
    n="$(printf '%s' "$line" | grep -oE '未画种类 [0-9]+' | grep -oE '[0-9]+' | head -1)"
    [ -n "$n" ] || { printf 'NA(取不到未画种类)'; return; }
    tail="$(printf '%s' "$line" | sed -n 's/.*未画种类 [0-9]\+\(.*\)/\1/p')"
    if [ "$n" = "0" ]; then
        # 空态契约（T2b）：**不得有条款表 `[]`**；尾部允许有 trace 自己的后续上下文
        #   （实测真实行是 `…未画种类 0）  累计帧数 = 2` ⇒ 早先要求"尾巴恰好是 ）"会误报 WARN）。
        case "$tail" in
            *"["*)  printf 'SUSPECT(0 却带条款表 ⇒ 格式异常)' ;;
            "）")   printf 'ok(0 且尾部恰好为）)' ;;
            "）"*)  printf 'ok(0 且无条款表；尾部=）%s)' "${tail#）}" ;;
            *)      printf 'WARN(0 但尾部不以）起头: %s)' "$tail" ;;
        esac
    else
        case "$tail" in
            *"["*"]"*) printf 'ok(%s 且带条款表)' "$n" ;;
            *)         printf 'SUSPECT_STALE_BRIDGE(%s 但无条款表 ⇒ 疑取到旧桥/旧件)' "$n" ;;
        esac
    fi
}
# 离线牙（**不需要应用**）：造 4 行假台账，其中第 4 行专门覆盖"行首有 [mil …] 不能骗过判定"。
if [ "${BRIDGE_CONTRACT_SELFTEST:-0}" = "1" ]; then
    _bc_fail=0
    _t() { # $1=行 $2=期望前缀 $3=说明
        local got; got="$(bridge_contract "$1")"
        case "$got" in "$2"*) echo "  ✅ $3 ⇒ $got" ;;
            *) echo "  ❌ $3 ⇒ 得到 '$got'，期望前缀 '$2'"; _bc_fail=1 ;;
        esac
    }
    _t '（skia 指令 261 条，未画种类 0）' 'ok(0' '空态（裸行）⇒ 必须 ok(0…)'
    _t '[mil   28]   ★ 首个**有内容**的帧…（skia 指令 261 条，未画种类 0）  累计帧数 = 2' 'ok(0' '空态（**真实整行**，带 trace 后续上下文）⇒ 必须 ok(0…) 而不是 WARN'
    _t '[mil   34]   ★ 首个**有内容**的帧…（skia 指令 261 条，未画种类 0）' 'ok(0' '行首带 [mil 34] 的空态 ⇒ **不许**被判成"带条款表"'
    _t '（skia 指令 12 条，未画种类 2 [MilPushOpacityMask×2]）' 'ok(2' '非空态 + 条款表 ⇒ ok(N…)'
    _t '（skia 指令 12 条，未画种类 2）' 'SUSPECT_STALE_BRIDGE' '非空态 + 无条款表 ⇒ 必须报"疑取旧桥"'
    if [ "$_bc_fail" = "0" ]; then echo "BRIDGE_CONTRACT_SELFTEST=PASS"; exit 0; fi
    echo "BRIDGE_CONTRACT_SELFTEST=FAIL（判定函数不能区分四种形态 ⇒ 这条检查是假的）"; exit 2
fi

DISPLAY_NUM="${WFP_DISPLAY:-:97}"
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

printf 'grep-selfcheck\n' | grep -q 'grep-selfcheck' || { echo "❌ grep 不可用" >&2; exit 2; }
for t in xwininfo xwd convert dotnet; do command -v "$t" >/dev/null 2>&1 || { echo "❌ 缺工具：$t" >&2; exit 2; }; done

# 杀进程审计（与样例 runner 同规则：**只按 PID**，脚本里不许出现按模式杀）
KILL_AUDIT="$(grep -vE '^[[:space:]]*#' "$0" | grep -nE '(^|[^a-zA-Z])pkill|killall|kill[[:space:]]+-f' | grep -v KILL_AUDIT | head -3)"
[ -n "$KILL_AUDIT" ] && { echo "❌ 自查失败：出现按模式杀进程写法" >&2; printf '%s\n' "$KILL_AUDIT" >&2; exit 2; }

XPID=""
REAPED_TOTAL=0
app_procs() { pgrep -P "$$" -f "dotnet $SAMPLE.dll" 2>/dev/null || true; }
app_procs_count() { app_procs | grep -c . || true; }
orphan_app_pids() {   # 精确 argv + 只认 ppid==1（别人的活进程有父进程 ⇒ 绝不误伤）
    local p a0 a1
    for p in /proc/[0-9]*; do
        p="${p#/proc/}"
        [ -r "/proc/$p/cmdline" ] || continue
        a0="$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | sed -n 1p)"
        a1="$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | sed -n 2p)"
        case "$a0" in dotnet|*/dotnet) ;; *) continue ;; esac
        [ "$a1" = "$SAMPLE.dll" ] || continue
        [ "$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null)" = "1" ] || continue
        printf '%s\n' "$p"
    done
}
reap_orphans() {
    local label="$1" ids n=0 p
    ids="$(orphan_app_pids)"
    [ -n "$ids" ] || return 0
    for p in $ids; do kill -TERM "$p" 2>/dev/null || true; done
    sleep 0.6
    for p in $ids; do [ -d "/proc/$p" ] && kill -KILL "$p" 2>/dev/null || true; n=$((n+1)); done
    REAPED_TOTAL=$((REAPED_TOTAL + n))
    echo "   ♻️ $label：回收 $n 个孤儿（精确 argv + ppid==1 + 按 PID）"
}
cleanup() {
    [ "${BASHPID:-$$}" != "$$" ] && return 0     # 子 shell 不执行（历史上曾因此杀掉自己的 Xvfb）
    local p
    for p in $(app_procs); do kill -TERM "$p" 2>/dev/null || true; done
    sleep 0.5
    for p in $(app_procs); do kill -KILL "$p" 2>/dev/null || true; done
    reap_orphans "脚本收尾"
    [ -n "$XPID" ] && kill -0 "$XPID" 2>/dev/null && { kill "$XPID" 2>/dev/null || true; wait "$XPID" 2>/dev/null || true; }
}
trap cleanup EXIT

if xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1; then
    echo "== 复用已存在的 X server：$DISPLAY_NUM"
else
    echo "== 启动自己的 Xvfb $DISPLAY_NUM"
    Xvfb "$DISPLAY_NUM" -screen 0 1280x1024x24 >"$OUT-xvfb.log" 2>&1 & XPID=$!
    for _ in $(seq 1 40); do xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 && break; sleep 0.25; done
    sleep 0.6
    xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 || { echo "❌ Xvfb 起不来" >&2; exit 2; }
fi
export DISPLAY="$DISPLAY_NUM"

echo "== WpfFeatureProbe runner（块级台账 + 像素核对 + 崩溃分诊）"
echo "   仓库=$ROOT  DISPLAY=$DISPLAY  OUT=$OUT  tier=$TIER  only=${ONLY:-all}  timeout=${TIMEOUT}s"


# ── 负载闸门（主控 2026-09-11 新增的启动条件）──────────────────────────────────
#   本机有**别的工程**的构建负载（不是我们的），会把 90s 档变得不稳。
#   规则：开跑前看 1 分钟 loadavg；> 12 就等 2 分钟再试，最多 5 次。
#   ⚠️ 若 5 次仍高：**继续跑但把"环境负载高"写进读数** —— 读数要带成立条件，
#      "负载下的异常慢/INCONCLUSIVE"不许当成渲染结论。
load_gate() {
    local max="${LOAD_GATE_MAX:-12}" tries=0 l1
    while :; do
        l1="$(awk '{print $1}' /proc/loadavg)"
        if awk -v l="$l1" -v m="$max" 'BEGIN{exit !(l <= m)}'; then
            echo "   ✅ load gate：1min=$l1 ≤ $max（尝试 $tries 次）"
            LOAD_GATE_RESULT="ok(1min=$l1)"
            return 0
        fi
        tries=$((tries + 1))
        if [ "$tries" -ge 5 ]; then
            echo "   ⚠️ load gate：1min=$l1 仍 > $max（已重试 5 次）⇒ 继续跑，但读数标注**环境负载高**"
            LOAD_GATE_RESULT="high(1min=$l1,>5 次)"
            return 1
        fi
        echo "   ⏳ load gate：1min=$l1 > $max ⇒ 等 120s 再试（第 $tries 次）"
        sleep 120
    done
}
LOAD_GATE_RESULT="unknown"

# ── 构建（-m:1；失败即退出，不拿旧产物跑）─────────────────────────────────────
if [ "$NO_BUILD" = "0" ]; then
    echo "== 0/5 负载闸门（主控条件：1min loadavg ≤ 12；>12 等 2 分钟，最多 5 次）"
load_gate || true
echo "WFP_ENV loadavg=$(cut -d' ' -f1-3 /proc/loadavg) mem_available=$(awk '/MemAvailable/{printf "%d MB", $2/1024}' /proc/meminfo) cpu=$(nproc)核 load_gate=$LOAD_GATE_RESULT"

echo "== 1/5 增量构建 samples/$SAMPLE（-m:1）"
    if ! timeout 600 dotnet build "$ROOT/samples/$SAMPLE/$SAMPLE.csproj" -m:1 >"/tmp/wfp-build-$$.log" 2>&1; then
        echo "   ❌ 构建失败：" >&2; tail -15 "/tmp/wfp-build-$$.log" | sed 's/^/      /' >&2; exit 3
    fi
    grep -E "已成功生成|个警告|个错误" "/tmp/wfp-build-$$.log" | sed 's/^/   /'
fi

# ── 装配运行目录（与样例 runner 的 2/2a-2d **逐条同源**）─────────────────────
echo "== 2/5 装配运行目录"
[ -d "$SRC" ] || { echo "找不到 $SRC" >&2; exit 2; }
rm -rf "$OUT"; mkdir -p "$OUT"; : > "$OUT/feat-lines.txt"
cp -r "$SRC"/. "$OUT"/
for d in "$ROOT"/build/*.Linux/bin/"$SELFBUILT_CONFIG"/*.dll; do
    [ -f "$d" ] || continue
    proj="$(basename "$(dirname "$(dirname "$(dirname "$d")")")")"
    case "$proj" in CycleStub.*) continue ;; esac
    [ "$(basename "$d" .dll)" = "${proj%.Linux}" ] || continue
    cp -f "$d" "$OUT"/ 2>/dev/null
done
PROVIDER="$ROOT/build/DirectWrite.Linux/Provider/bin/$SELFBUILT_CONFIG/DirectWrite.Linux.Provider.dll"
[ -f "$PROVIDER" ] && cp -f "$PROVIDER" "$OUT"/ || echo "   警告：缺 Provider" >&2
SHIM="$ROOT/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
if [ -f "$SHIM" ]; then
    cp -f "$SHIM" "$OUT"/
    for a in uxtheme.dll wtsapi32.dll shell32.dll PresentationNative_cor3.dll; do cp -f "$SHIM" "$OUT/$a"; done
fi
MILDIR="$ROOT/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64"
[ -d "$MILDIR" ] && for so in "$MILDIR"/*.so; do [ -f "$so" ] && cp -f "$so" "$OUT"/; done


# ── `build/*.Linux/**` **源码 vs 产物** 新鲜度闸门（2026-09-13 加）──────────────────
#   【为什么】已经有过一次"`hbtextline_shim_stale` 恒 no"的假绿（源比产物新、跑的是旧栈却盖章相容）。
#   同形风险还有一整族：`build/WindowsBase.Linux/DependencyObject.Linux.cs` 这类**端口源码**在
#   插桩/修法后若**没重编**，应用跑的就是旧 DLL —— 而七元组里只有 **产物 sha**，
#   产物变了才看得见，**"源码变了但没重编"完全静默**。本闸门把这件事变成一行机读读数。
#   ⚠️ 判据是**建议性**的（advisory）：打 `WFP_SRC_STALE=…`，不直接判红——
#   因为目录里可能有不参与编译的 .cs（生成物/备份），**由人/主控裁决**。
src_freshness() {
    local pairs="PresentationCore:PresentationCore.dll WindowsBase:WindowsBase.dll PresentationFramework:PresentationFramework.dll DirectWriteForwarder:DirectWriteForwarder.dll ReachFramework:ReachFramework.dll System.Printing:System.Printing.dll UIAutomationTypes:UIAutomationTypes.dll UIAutomationProvider:UIAutomationProvider.dll System.Xaml:System.Xaml.dll"
    local pair proj dll newest src out=""
    for pair in $pairs; do
        proj="${pair%%:*}"; dll="${pair##*:}"
        [ -d "$ROOT/build/$proj.Linux" ] || continue
        [ -f "$ROOT/build/$proj.Linux/bin/$SELFBUILT_CONFIG/$dll" ] || continue
        newest="$(find "$ROOT/build/$proj.Linux" -name '*.cs' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f1)"
        [ -n "$newest" ] || continue
        newest="${newest%%.*}"
        src="$(stat -c %Y "$ROOT/build/$proj.Linux/bin/$SELFBUILT_CONFIG/$dll" 2>/dev/null)"
        [ -n "$src" ] || continue
        if [ "$newest" -gt "$src" ]; then out="$out $proj(源${newest}>产物${src})"; fi
    done
    printf '%s' "${out:-none}"
}

# ── 配置七元组（**全部读自 app-local**，即应用真正加载的那几份）──────────────
BRIDGE_SHA="$(sha256sum "$OUT/wpfgfx_cor3.so" 2>/dev/null | cut -c1-16)"
PC_SHA="$(sha256sum "$OUT/PresentationCore.dll" 2>/dev/null | cut -c1-16)"
PF_SHA="$(sha256sum "$OUT/PresentationFramework.dll" 2>/dev/null | cut -c1-16)"
PROVIDER_SHA="$(sha256sum "$OUT/DirectWrite.Linux.Provider.dll" 2>/dev/null | cut -c1-16)"
WIN32SHIM_SHA="$(sha256sum "$OUT/libwpfwin32.so" 2>/dev/null | cut -c1-16)"
WICSHIM_SHA="$(sha256sum "$OUT/libwpfwic.so" 2>/dev/null | cut -c1-16)"
HBTEXT_SHA="$(sha256sum "$ROOT/build/shims/PresentationCore.HbTextLine.cs" 2>/dev/null | cut -c1-16)"
BRIDGE_BYTES="$(stat -c%s "$OUT/wpfgfx_cor3.so" 2>/dev/null)"
# stale 标志（**2026-09-13 修**）：判定"shim 源比 PC 新 ⇒ 未必编进当前 PC"必须**对着权威 PC**比。
#   【原来的 bug（主控查出，第 17 个"恒真/恒假"形态）】旧写法比的是 `$OUT/PresentationCore.dll`
#   —— 那是**刚刚 cp 出来的副本**，mtime = 拷贝时刻 = 现在 ⇒ 源 mtime 永远比它旧 ⇒
#   `hbtextline_shim_stale` **按构造恒为 `no`**：应用其实跑着"不含 shim 最新改动"的旧文本栈，
#   门禁却盖章"相容"。实测现场（2026-09-13）：
#     build/shims/PresentationCore.HbTextLine.cs                   00:36:31  ← 源（新）
#     build/PresentationCore.Linux/bin/Debug/PresentationCore.dll  00:00:23  ← 权威 PC（旧）
#   真值是 **yes**。⇒ 现在读**权威 PC**；权威件缺失才退回副本，并把依据一起打出来
#   （`hbtextline_stale_basis=auth|applocal`），读者能自己核。mtime 也一并打（便于人工复核）。
#   谓词抽成函数 ⇒ 可自测（"能变红的牙"）：`HBT_STALE_SELFTEST=1` 会同时验证
#   "源新 ⇒ yes" 与 "PC 新 ⇒ no" 两个极性（临时文件造，不碰任何别人的文件）。
hbt_stale() {
    local sm pm
    sm="$(stat -c %Y "$1" 2>/dev/null)"; pm="$(stat -c %Y "$2" 2>/dev/null)"
    if [ -n "$sm" ] && [ -n "$pm" ] && [ "$sm" -gt "$pm" ]; then printf yes; else printf no; fi
}
if [ "${HBT_STALE_SELFTEST:-0}" = "1" ]; then
    _d="$(mktemp -d 2>/dev/null || echo "$HOME/.hbt-selftest")"; mkdir -p "$_d"; : > "$_d/src"; : > "$_d/pc"
    touch -d '2026-01-01 00:00:00' "$_d/pc" 2>/dev/null; touch -d '2026-06-01 00:00:00' "$_d/src" 2>/dev/null
    _r1="$(hbt_stale "$_d/src" "$_d/pc")"; _r2="$(hbt_stale "$_d/pc" "$_d/src")"; rm -rf "$_d"
    echo "HBT_STALE_SELFTEST src-newer=$_r1（期望 yes） pc-newer=$_r2（期望 no）"
    if [ "$_r1" = "yes" ] && [ "$_r2" = "no" ]; then echo "HBT_STALE_SELFTEST=PASS"; exit 0; fi
    echo "HBT_STALE_SELFTEST=FAIL（谓词不能两极化 ⇒ 这个门是假的）"; exit 2
fi
HBTEXT_SRC="$ROOT/build/shims/PresentationCore.HbTextLine.cs"
AUTH_PC="$ROOT/build/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll"
if [ -f "$AUTH_PC" ]; then STALE_BASIS="auth"; STALE_PC="$AUTH_PC"; else STALE_BASIS="applocal"; STALE_PC="$OUT/PresentationCore.dll"; fi
HBTEXT_MTIME="$(stat -c %Y "$HBTEXT_SRC" 2>/dev/null)"
PC_MTIME="$(stat -c %Y "$STALE_PC" 2>/dev/null)"
HBTEXT_STALE="$(hbt_stale "$HBTEXT_SRC" "$STALE_PC")"
# ★ 字段名与顺序**与 run-wpftextdemo.sh 的 WPTD_ARTIFACTS 逐字段一致**（两份读数要能并排看）；
#   新增字段一律**追加在末尾**，不改既有顺序（下游解析靠前缀）。
echo "WFP_ARTIFACTS bridge_sha=${BRIDGE_SHA:-NA} bridge_bytes=${BRIDGE_BYTES:-0} pc_sha=${PC_SHA:-NA} pf_sha=${PF_SHA:-NA} provider_sha=${PROVIDER_SHA:-NA} win32shim_sha=${WIN32SHIM_SHA:-NA} wic_shim_sha=${WICSHIM_SHA:-NA} hbtextline_shim_sha=${HBTEXT_SHA:-NA} hbtextline_shim_stale=${HBTEXT_STALE} hbtextline_stale_basis=${STALE_BASIS} hbtextline_src_mtime=${HBTEXT_MTIME:-NA} pc_compare_mtime=${PC_MTIME:-NA} windowsbase_sha=$(sha256sum "$ROOT/build/WindowsBase.Linux/bin/Debug/WindowsBase.dll" 2>/dev/null | cut -c1-16) dwf_sha=$(sha256sum "$ROOT/build/DirectWriteForwarder.Linux/bin/Debug/DirectWriteForwarder.dll" 2>/dev/null | cut -c1-16)"
# ↑ **尾部追加 `dwf_sha`（第九位，2026-09-14 主控派）**：既有字段顺序与含义一位未动；与 `run-wpftextdemo.sh`
#   的同名字段**逐字一致**（两份读数要能并排看）。理由见该脚本同一行上方的注释：DWF 变了而元组看不见它 = 静默位。
# ── 扩展可见位（主控 2026-09-14 **批准**；只追加一行，既有字段与顺序一位未动）──────────────────
#   口径（主控写死）：**扩展位变化 = 不自动作废基线，但必须在下一版表头记录。**
#   `reachframework` / `systemxaml` 行内有 `*_role=visible-not-frozen` ⇒ **可见位、不进冻结元组**
#     （每波都在动 ⇒ 进元组等于每波强制重冻、噪声大于信息；若"变了**且**门禁读数有差异"则升级进元组）。
#   `libskia_sha` + `libskia_nuget_2_88_9_match` = **可复算**口径：仓内 vendored 副本 vs NuGet 钉版
#     `skiasharp.nativeassets.linux/2.88.9/runtimes/linux-x64/native/libSkiaSharp.so`（版本由
#     `src/WpfGfx.Linux/WpfGfx.Linux.csproj` 钉住）；**NuGet 副本缺失 ⇒ `NOINFO`，不当 yes**。
#   `presentationui_sha` 取 **`build/CycleStub.PresentationUI.Linux/`**（断环 stub 工程的权威件）。
#   逐条判断与依据见 `samples/WpfTextDemo/ARTIFACT-TUPLE-COVERAGE.md`。
ext_sha() { local v; v="$(sha256sum "$1" 2>/dev/null | cut -c1-16)"; printf '%s' "${v:-NA}"; }
SKIA_REPO="$ROOT/build/DirectWrite.Linux/wic-shim/libSkiaSharp.so"
SKIA_NUGET="$HOME/.nuget/packages/skiasharp.nativeassets.linux/2.88.9/runtimes/linux-x64/native/libSkiaSharp.so"
SKIA_SHA="$(ext_sha "$SKIA_REPO")"
if [ -f "$SKIA_NUGET" ]; then
    if [ "$SKIA_SHA" = "$(ext_sha "$SKIA_NUGET")" ]; then SKIA_MATCH="yes(nuget-2.88.9-linux-x64)"
    else SKIA_MATCH="no(repo=${SKIA_SHA} nuget=$(ext_sha "$SKIA_NUGET"))"; fi
else
    SKIA_MATCH="NOINFO(缺 NuGet 钉版副本 ⇒ 无从比对，**不当 yes**)"
fi
echo "WFP_ARTIFACTS_EXT reachframework_sha=$(ext_sha "$ROOT/build/ReachFramework.Linux/bin/$SELFBUILT_CONFIG/ReachFramework.dll") reachframework_role=visible-not-frozen systemxaml_sha=$(ext_sha "$ROOT/build/System.Xaml.Linux/bin/Debug/System.Xaml.dll") systemxaml_role=visible-not-frozen presentationui_sha=$(ext_sha "$ROOT/build/CycleStub.PresentationUI.Linux/bin/Debug/PresentationUI.dll") pfclassic_sha=$(ext_sha "$ROOT/build/PresentationFramework.Classic.Linux/bin/Debug/PresentationFramework.Classic.dll") systemprinting_sha=$(ext_sha "$ROOT/build/System.Printing.Linux/bin/Debug/System.Printing.dll") uiatypes_sha=$(ext_sha "$ROOT/build/UIAutomationTypes.Linux/bin/Debug/UIAutomationTypes.dll") uiaprovider_sha=$(ext_sha "$ROOT/build/UIAutomationProvider.Linux/bin/Debug/UIAutomationProvider.dll") manipulations_sha=$(ext_sha "$ROOT/build/System.Windows.Input.Manipulations.Linux/bin/Debug/System.Windows.Input.Manipulations.dll") libskia_sha=${SKIA_SHA} libskia_nuget_2_88_9_match=${SKIA_MATCH} ｜ 口径=扩展位变化**不自动作废基线**，但必须在下一版表头记录；reachframework/systemxaml 是**可见位、不进冻结元组**（每波都在动 ⇒ 噪声大于信息；若"变了**且**门禁读数有差异"则升级进元组）"
# 源码比产物新 ⇒ 跑的是旧 DLL（**静默类**风险；advisory，不判红）
echo "WFP_SRC_STALE=$(src_freshness)（none=所有端口源码都不比产物新；列出者=该工程源码更新 ⇒ 疑未重编）"

#    ↓ 下面这段（块表 + 注册表断言 + 自测牙）**必须在起应用之前**：断言失败要能早退，
#      而不是跑完一趟应用才发现表错了（我第一版就把它放在 4/5，实测白跑一趟应用）。

# ── 3.5/5 【机器强制】块注册表断言（L19 收口；主控 2026-09-14 派）────────────────────
# 【要解决的问题】块表是**手写的名单**，样例的注册表是**源码里的真值**；两者一漂移就出事：
#   名单少一个 ⇒ 那一块**根本不进汇总**（全量趟里它真 FAIL 也看不见）；名单多一个 ⇒ 恒 `INCONCLUSIVE`
#   把汇总做成噪声。L19 就是这么来的（10 vs 11，漏 `text-dp-min`）。
# 【判据】**直接测量**：注册表从**样例源码**取出（`probe-block-registry.py`，唯一实现），
#   与 `BLOCKS` 比 **集合 + 条目数**；不一致 ⇒ 打印 `MISMATCH` 并**指出缺哪个/多哪个**，且**本趟判红**
#   （不是只打一行字：`REGISTRY_RC=1` 会并进门禁结论）。
# 【为什么不是恒真】牙在 `WFP_BLOCK_REGISTRY_SELFTEST=1` 里**证明能红**：删一个 ⇒ MISMATCH 且点名；
#   加一个假的 ⇒ MISMATCH 且点名；用真表 ⇒ ok。三条极性都要过才算这个门能用。
BLOCKS="popup anim opacitymask effects controls textbox-edit virtualize transforms text-rtl text-rtl-pure text-dp-min nativecombo clickprobe"
REGISTRY_TOOL="$HERE/probe-block-registry.py"
REGISTRY_RC=0
block_registry_check() {   # $1 = 待检的块表串（默认 $BLOCKS）；stdout = ok|MISMATCH 报告
    local impl="$1" reg tbl
    [ -f "$REGISTRY_TOOL" ] || { printf 'NOINFO(缺 probe-block-registry.py ⇒ 无从比对，**不当通过**)\n'; return 2; }
    reg="$(python3 "$REGISTRY_TOOL" 2>/dev/null)" || { printf 'NOINFO(注册表取不出 ⇒ 不当通过)\n'; return 2; }
    tbl="$(printf '%s' "$impl" | tr ' ' '\n' | grep -v '^$')"
    python3 - "$reg" "$tbl" <<'PY'
import sys
reg=[x for x in sys.argv[1].split("\n") if x.strip()]
tbl=[x for x in sys.argv[2].split("\n") if x.strip()]
miss=[x for x in reg if x not in tbl]; extra=[x for x in tbl if x not in reg]
if not miss and not extra and len(reg)==len(tbl):
    print(f"ok(count={len(reg)}，与样例注册表逐名一致)")
else:
    d=[]
    if miss:  d.append("块表缺=" + ",".join(miss))
    if extra: d.append("块表多=" + ",".join(extra))
    if not d: d.append(f"条目数不同 registry={len(reg)} table={len(tbl)}")
    print("MISMATCH(" + "；".join(d) + ")")
PY
}
if [ "${WFP_BLOCK_REGISTRY_SELFTEST:-0}" = "1" ]; then
    _real="$BLOCKS"
    _r_ok="$(block_registry_check "$_real")"
    _r_missing="$(block_registry_check "$(printf '%s' "$_real" | sed 's/ text-dp-min//')")"
    _r_extra="$(block_registry_check "$_real __bogus_block__")"
    printf 'WFP_BLOCK_REGISTRY_SELFTEST 真表=%s\n' "$_r_ok"
    printf 'WFP_BLOCK_REGISTRY_SELFTEST 删一块=%s\n' "$_r_missing"
    printf 'WFP_BLOCK_REGISTRY_SELFTEST 加假块=%s\n' "$_r_extra"
    if case "$_r_ok" in ok*) true;; *) false;; esac \
       && case "$_r_missing" in MISMATCH*text-dp-min*) true;; *) false;; esac \
       && case "$_r_extra" in MISMATCH*__bogus_block__*) true;; *) false;; esac; then
        echo "WFP_BLOCK_REGISTRY_SELFTEST=PASS（能绿：真表；能红且点名：缺块/多块）"
        exit 0
    fi
    echo "WFP_BLOCK_REGISTRY_SELFTEST=FAIL（至少一条极性不成立 ⇒ 这个门是假的）" >&2
    exit 2
fi

# ── 4/5 块级汇总（台账 + 像素核对 + 崩溃分诊）────────────────────────────────
echo "== 4/5 块级台账"
# 块表（**必须与样例实际注册的块同步**：`samples/WpfFeatureProbe/MainWindow.xaml.cs` 的 `all` 列表 = 11 块）。
#   ⚠️ 2026-09-14 修：这里原本只有 10 块，**漏了 `text-dp-min`**（D-P1 最小复现块，后加的）⇒
#     `--only=text-dp-min` 时 runner 把它当"不在表里"⇒ 10 块全记 `skipped`、`ok=0`
#     （幸而 GATE 的"被选块全绿"判据不会把 0 块判成 PASS，所以没有假绿，但**该块的判定根本没进汇总**；
#      更危险的是**全量趟**：那块真 FAIL 也不会被看见 —— 属"仪器看不见对象"族，与 L12/桥契约那次同源）。
#   ⇒ 现在**不靠人记**：下面 `block_registry_check()` 每趟开机时断言一次（不一致即判红，见 3.5/5 节）。
BLOCK_REGISTRY_RESULT="$(block_registry_check "$BLOCKS")"
case "$BLOCK_REGISTRY_RESULT" in
    ok*)       echo "WFP_BLOCK_REGISTRY=$BLOCK_REGISTRY_RESULT" ;;
    NOINFO*)   echo "WFP_BLOCK_REGISTRY=$BLOCK_REGISTRY_RESULT"; echo "   ⚠️ 注册表断言**无信息** ⇒ 不当通过（本趟判红）"; REGISTRY_RC=1 ;;
    *)         echo "WFP_BLOCK_REGISTRY=$BLOCK_REGISTRY_RESULT"; echo "   ❌ 块表与样例注册表**不一致** ⇒ 本趟判红（L19：表/判据与实际对象漂移 ⇒ 静默漏判）"; REGISTRY_RC=1 ;;
esac

# ── 3/5 起应用（exec ⇒ $! 就是应用 PID）──────────────────────────────────────
LAST_RC=""; LAST_FRAMES_GOOD=0; LAST_FRAMES_TOTAL=0; LAST_FRAMES_BLANK=0; LAST_COLORS=0; LAST_WINDOW="none"; LAST_NEWWIN=0
run_once() {           # $1=tag  $2=app_args
    local tag="$1" app_args="$2"
    local log="$OUT/probe-$tag.log" shot="$OUT/probe-$tag.png"
    local tier_env=()
    if [ "$TIER" = "both" ]; then
        tier_env=(WPF_LINUX_FONT_DIR="$ROOT/build/fonts-ui" WPF_LINUX_UI_FONT="Noto Sans")
    fi
    : > "$log"
    xdotool mousemove 1270 1010 2>/dev/null || true
    local before; before="$(xwininfo -root -tree 2>/dev/null | grep -oE '0x[0-9a-f]+' | sort -u | tr '\n' ' ')"
    # `--app-env=A=1,B=2` ⇒ 显式诊断开关（**只进诊断趟**，不改变验收档配置）
    local extra_env=()
    if [ -n "$APP_ENV" ]; then
        local kv; IFS=',' read -r -a _kvs <<< "$APP_ENV"
        for kv in "${_kvs[@]}"; do [ -n "$kv" ] && extra_env+=("$kv"); done
    fi
    # 【为什么要开 DRAW_CENSUS】`textbox-edit` 这类**文字块**的像素判据不能只看颜色：
    #   抗锯齿让"精确色"计数几乎为 0（实测 wave 8=16、wave 9=0，都 < MINPX=20，而读图
    #   证明文字**就在屏上**）⇒ 必须同时有"**字形到底有没有提交给渲染器**"的读数。
    #   census 的每帧汇总行里有 `GlyphRun×N` ⇒ 用 `census_glyph_runs` 抽取（见下面判据段）。
    #   这是**跟踪开关（只加日志）**，与已经默认开着的 MSG/MIL trace 同一性质。
    ( cd "$OUT" && exec env WPF_WIN32_MSG_TRACE="${WPF_WIN32_MSG_TRACE:-1}" WPF_LINUX_MIL_TRACE="${WPF_LINUX_MIL_TRACE:-1}" \
        WPF_LINUX_DRAW_CENSUS="${WPF_LINUX_DRAW_CENSUS:-1}" \
        "${tier_env[@]}" "${extra_env[@]}" dotnet "$SAMPLE.dll" $app_args > "$log" 2>&1 ) &
    local app_pid=$!

    local window="" deadline=$(( $(date +%s) + TIMEOUT )) w
    while [ "$(date +%s)" -lt "$deadline" ]; do
        kill -0 "$app_pid" 2>/dev/null || break
        w="$(xwininfo -root -tree 2>/dev/null | grep -F "$SAMPLE" | grep -oE '0x[0-9a-f]+' | head -1)"
        if [ -n "$w" ]; then
            local st; st="$(xwininfo -id "$w" 2>/dev/null | awk -F: '/Map State/{gsub(/^ +/,"",$2);print $2}')"
            case "$st" in *IsViewable*) window="$w" ;; esac
        fi
        [ -n "$window" ] && break
        sleep 0.25
    done
    # 等首绘信号（台账里出现有内容的帧）——与样例 runner 同口径
    local waited=0
    [ -n "$window" ] && while [ "$waited" -lt 60 ]; do
        grep -qE "skia 指令 [1-9][0-9]* 条" "$log" 2>/dev/null && break
        kill -0 "$app_pid" 2>/dev/null || break
        sleep 0.25; waited=$((waited + 1))
    done

    # 抓帧：root 连拍 + 按窗口几何裁剪，取最佳帧（同样例 runner）
    local frames_total=0 frames_blank=0 frames_good=0 colors=0 frame_files=() bi c dims ax ay gw gh info
    local geom_now=""
    if [ -n "$window" ]; then
        info="$(xwininfo -id "$window" 2>/dev/null)"
        ax="$(printf '%s\n' "$info" | awk -F: '/Absolute upper-left X/{gsub(/ /,"",$2);print $2}')"
        ay="$(printf '%s\n' "$info" | awk -F: '/Absolute upper-left Y/{gsub(/ /,"",$2);print $2}')"
        gw="$(printf '%s\n' "$info" | awk -F: '/^  Width:/{gsub(/ /,"",$2);print $2}')"
        gh="$(printf '%s\n' "$info" | awk -F: '/^  Height:/{gsub(/ /,"",$2);print $2}')"
        geom_now="${gw}x${gh}"
        for bi in $(seq 1 "${WFP_BURST:-8}"); do
            if xwd -root -display "$DISPLAY" -out "$OUT/b-$tag-$bi.xwd" 2>/dev/null \
               && convert "$OUT/b-$tag-$bi.xwd" -crop "${gw}x${gh}+${ax}+${ay}" +repage "$OUT/b-$tag-$bi.png" 2>/dev/null; then
                dims="$(identify -format '%wx%h' "$OUT/b-$tag-$bi.png" 2>/dev/null)"
                c="$(convert "$OUT/b-$tag-$bi.png" -format '%k' info: 2>/dev/null)"; c="${c:-0}"
                frames_total=$((frames_total + 1))
                [ "$c" -le 1 ] && frames_blank=$((frames_blank + 1)) || frames_good=$((frames_good + 1))
                frame_files+=("$OUT/b-$tag-$bi.png")
                if [ "$c" -gt "$colors" ]; then colors="$c"; cp -f "$OUT/b-$tag-$bi.png" "$shot"; fi
            fi
            sleep 0.12
        done
        # 滚动后再抓一轮（块多，必然超出视口；这样"视口外的块"也能进像素判据）
        xdotool mousemove "$((ax + 200))" "$((ay + 300))" 2>/dev/null || true; sleep 0.3
        for _s in 1 2 3 4 5 6; do xdotool click 5 2>/dev/null || true; sleep 0.2; done; sleep 0.6
        for bi in $(seq 1 "${WFP_BURST2:-6}"); do
            if xwd -root -display "$DISPLAY" -out "$OUT/b2-$tag-$bi.xwd" 2>/dev/null \
               && convert "$OUT/b2-$tag-$bi.xwd" -crop "${gw}x${gh}+${ax}+${ay}" +repage "$OUT/b2-$tag-$bi.png" 2>/dev/null; then
                c="$(convert "$OUT/b2-$tag-$bi.png" -format '%k' info: 2>/dev/null)"; c="${c:-0}"
                frames_total=$((frames_total + 1))
                [ "$c" -le 1 ] && frames_blank=$((frames_blank + 1)) || frames_good=$((frames_good + 1))
                frame_files+=("$OUT/b2-$tag-$bi.png")
                if [ "$c" -gt "$colors" ]; then colors="$c"; cp -f "$OUT/b2-$tag-$bi.png" "$shot"; fi
            fi
            sleep 0.12
        done
    fi

    # 输入注入（编辑态/输入路径）：Ctrl+A 再敲几个键
    if [ -n "$window" ] && [ "${WFP_INPUT:-1}" = "1" ] && command -v xdotool >/dev/null 2>&1; then
        # 【T1b 2026-09-13 的历史背景，2026-09-15 由 T3 收束】**别再用 `tail -1` 取"注入后的读数"**：
        #   `feat-lines.txt` 里同一逻辑事件有 `late:`(LateVerify) 与 `OK`(Verify) 两个变体，而 `OK`
        #   可能被 ~10s 首帧拖后到 `late:` **之后**（实测 L599<L734）⇒ `tail -1` 会取到**注入之前**
        #   那一行，再被当成注入后的结论（"时间点型假阳"）。
        #   旧修法 = 记台账行号 `INJECT_AT_LINE` 交给 `pick-feat-line.py`；**已被下面的应用日志锚点取代**
        #   （L23：台账里那条读数实测取自**注入之前** ⇒ 台账锚点**不再有任何消费者**；按本仓"**算了没消费**
        #    的变量要删**"的规矩，`INJECT_AT_LINE` **已删除**，不留"看着像在用"的空变量）。
        # 【T3 2026-09-15 · L23「读数早于事件」修法】台账里的"写后读数"实测取自**注入之前**的自报快照
        #   （#13 复取：台账给 `changes=0` ⇒ 旧文案写成"可观测模型陈旧"；而**应用原始日志**里
        #    `WFP_POSTWRITE t=11047 变更 text='AB' … changes=2` 明明在注入之后）。
        #   ⇒ 读点必须落在**被判决事件真正写入的那份日志**= 应用原始日志（runner 不转发它）。
        #   锚点 = **注入前的应用日志行数**（与上一行同一手法 ⇒ 免时钟对齐，不依赖两个进程的时钟）。
        INJECT_AT_APPLOG_FILE="$log"
        INJECT_AT_APPLOG_LINE="$(wc -l < "$log" 2>/dev/null | tr -d ' ')"; INJECT_AT_APPLOG_LINE="${INJECT_AT_APPLOG_LINE:-0}"
        xdotool key --window "$window" ctrl+a 2>/dev/null || true; sleep 0.3
        xdotool type --window "$window" "AB" 2>/dev/null || true;     sleep 0.5
        # 【2026-09-13 加的**注入后**抓帧】原来两趟 burst（b-/b2-）**都在注入之前**（见时序），
        #   ⇒ 任何"屏幕上还是原文本"的结论都**没有证据力**（实测踩到：我差点据此判"写入被撤销"）。
        #   这里补一趟 `b3-`（注入之后），**只存盘+记颜色数，不并入 frame_files**（不动既有判据）。
        local bi3 c3
        for bi3 in $(seq 1 "${WFP_BURST3:-3}"); do
            if xwd -root -display "$DISPLAY" -out "$OUT/b3-$tag-$bi3.xwd" 2>/dev/null \
               && convert "$OUT/b3-$tag-$bi3.xwd" -crop "${gw}x${gh}+${ax}+${ay}" +repage "$OUT/b3-$tag-$bi3.png" 2>/dev/null; then
                c3="$(convert "$OUT/b3-$tag-$bi3.png" -format '%k' info: 2>/dev/null)"; c3="${c3:-0}"
                echo "     注入后帧 $bi3/${WFP_BURST3:-3}：颜色数 $c3（b3-，仅存档，不进判据）"
            fi
            sleep 0.12
        done
    fi

    # 【必须在**杀应用之前**数新窗口】Popup/ContextMenu/ToolTip 的独立窗口在应用退出时消失；
    #   原来放在 wait 之后 ⇒ 永远是 0 ⇒ "独立窗口路径"的判据**恒假**（实测踩到）。
    local after newwin w
    after="$(xwininfo -root -tree 2>/dev/null | grep -oE '0x[0-9a-f]+' | sort -u | tr '\n' ' ')"
    newwin=0; for w in $after; do case " $before " in *" $w "*) ;; *) newwin=$((newwin + 1)) ;; esac; done
    LAST_NEWWIN="$newwin"

    kill -TERM "$app_pid" 2>/dev/null || true
    wait "$app_pid" 2>/dev/null; local rc=$?
    LAST_RC=$rc            # 供分诊判"是被我们 TERM 掉的(143) 还是自己死的"
    local leftover=0; kill -0 "$app_pid" 2>/dev/null && leftover=1

    grep -aE '^\[feat\] ' "$log" >> "$OUT/feat-lines.txt" 2>/dev/null || true

    # ── 诊断读数抽取（主控指定的"每块红一条能判的读数"）──────────────────────
    #   · RTL 块：shim 的 `HB_TEXTLINE …`（含 fallbackCalls/Handled/Bailed/**lastBail**）
    #             与 T1c 的 `[TEXTLINE_RELAXED] …`（宽松兜底有没有接手）
    #   · opacitymask 块：`未画种类 N`（MIL 台账）+ `[DRAW_CENSUS]` **条款表**（里面有没有 MilPushOpacityMask）
    local hb last_hb relaxed_n relaxed_last nd_pair nd_line
    hb="$(grep -a 'HB_TEXTLINE' "$log" 2>/dev/null | tail -1)"
    relaxed_n="$(grep -ac 'TEXTLINE_RELAXED' "$log" 2>/dev/null || echo 0)"
    relaxed_last="$(grep -a 'TEXTLINE_RELAXED' "$log" 2>/dev/null | tail -1)"
    nd_line="$(grep -aE 'skia 指令 [0-9]+ 条，未画种类 [0-9]+' "$log" 2>/dev/null | sed 's/^ *//' \
               | awk -F'指令 ' '{split($2,a," "); print a[1]"|"}' | sort -t'|' -k1,1nr | head -1)"
    nd_pair="$(grep -aE 'skia 指令 [0-9]+ 条，未画种类 [0-9]+' "$log" 2>/dev/null | grep -oE 'skia 指令 [0-9]+ 条，未画种类 [0-9]+' | tail -1)"
    # DRAW_CENSUS 条款表：按命令名统计出现次数（含 MilPushOpacityMask）
    local census_kinds push_rows
    # 【更正（实测踩到）】census 的**逐条几何行**只对"绘制命令"打印；**状态类命令（push/pop）
    #   只出现在"每帧汇总行"里**，而且名字被 `.Replace("MilDraw","")` 处理过 ⇒ 是 `PushOpacityMask×N`
    #   而不是 `MilPushOpacityMask`。我第一版按 `^\[DRAW_CENSUS\] MilPushOpacityMask` 找 ⇒ 恒 0（假读数）。
    census_kinds="$(grep -ao 'DRAW_CENSUS\] frame=[0-9]* 指令种类=[0-9]* 总执行=[0-9]*  [^\n]*' "$log" 2>/dev/null | tail -1 | cut -c1-200)"
    push_rows="$(grep -ao 'PushOpacityMask×[0-9]*' "$log" 2>/dev/null | tail -1 | sed 's/.*×//')"
    [ -n "${push_rows:-}" ] || push_rows=0
    echo "WFP_DIAG tag=$tag hb_textline=${hb:-NA}"
    echo "WFP_DIAG tag=$tag textline_relaxed=$relaxed_n last=${relaxed_last:-NA}"
    # 桥契约（判定函数见文件头；**注意**：`nd_pair` 是 `-oE` 抽出来的，**不含后缀** ⇒
    #   必须用**整行**（`nd_line`）喂给判定函数，否则后缀被切掉 ⇒ 恒报"疑取旧桥"。）
    nd_contract="NA(取不到该行)"
    [ -n "${nd_line:-}" ] && nd_contract="$(bridge_contract "$nd_line")"
    echo "WFP_DIAG tag=$tag notdrawn_pair=${nd_pair:-NA}"
    echo "WFP_DIAG tag=$tag bridge_contract=${nd_contract}"
    echo "WFP_DIAG tag=$tag draw_census_kinds=${census_kinds:-NA}"
    echo "WFP_DIAG tag=$tag pushopacitymask_count=$push_rows（census 每帧汇总行里的 PushOpacityMask×N；缺省 0=**该指令没进渲染器**）"
    # ── 消息计数：把"键到底到没到窗口"从**手 grep 变成结构性读数** ─────────────────
    #   【为什么】`textbox-edit` 的 `changes=0` 曾经只能靠 `[feat] … late` 一行去猜：
    #   "键没到窗口"与"到了但没编辑"是两回事。主控在 2026-09-13 手 grep `[msg]` 行得出
    #   `WM_SETFOCUS=1 / WM_KEYDOWN=0 / WM_CHAR=0` ⇒ 一眼分清。这里把它做进 runner：
    #   每次跑都打一行 `WFP_MSGS`，键诊断（`WPF_LINUX_KEY_DIAG=1`）落地后可直接对照。
    msg_count() { grep -ac "msg=$1 " "$log" 2>/dev/null || true; }
    m_focus="$(msg_count 0x0007)"; m_kd="$(msg_count 0x0100)"; m_kc="$(msg_count 0x0101)"
    m_char="$(msg_count 0x0102)"; m_wheel="$(msg_count 0x020a)"
    echo "WFP_MSGS tag=$tag WM_SETFOCUS=${m_focus:-0} WM_KEYDOWN=${m_kd:-0} WM_KEYUP=${m_kc:-0} WM_CHAR=${m_char:-0} WM_MOUSEWHEEL=${m_wheel:-0}（从 [msg] 行计数：键「没到窗口」与「到了没编辑」靠这行分开）"
    # ── 进程队列通知号直方图（0x8000..0x800f）────────────────────────────────
    #   上游 `TextEditorTyping.ScheduleInput` 的插入挂在 **DispatcherPriority.Background(=4)**；
    #   若 shim/Dispatcher 用 `WM_APP + priority` 投递进程队列通知，那么"Background 到底有没有被投递"
    #   就看 **0x8004** 出现过没有 ⇒ 这一格把 0x8000…0x800f 每个号**各自计数**打全。
    hist=""
    for _h in 8000 8001 8002 8003 8004 8005 8006 8007 8008 8009 800a 800b 800c 800d 800e 800f; do
        _n="$(grep -ahc "msg=0x$_h " "$log" 2>/dev/null || true)"
        hist="$hist 0x$_h=${_n:-0}"
    done
    echo "WFP_MSGHIST tag=$tag 托管[msg]:$hist"
    hist2=""
    for _h in 8000 8001 8002 8003 8004 8005 8006 8007 8008 8009 800a 800b 800c 800d 800e 800f; do
        _n="$(grep -ah "\[MSGFLOW\] pop" "$log" 2>/dev/null | grep -ac "0x$_h" || true)"
        hist2="$hist2 0x$_h=${_n:-0}"
    done
    echo "WFP_MSGHIST tag=$tag 原生[MSGFLOW]pop:$hist2"
    kd_rows="$(grep -ac '^\[KEY_DIAG\]' "$log" 2>/dev/null || true)"
    echo "WFP_KEYDIAG tag=$tag key_diag_lines=${kd_rows:-0}$([ "${kd_rows:-0}" = "0" ] && echo '（未开 WPF_LINUX_KEY_DIAG=1 或键没到 shim）' || echo '')"
    # 【`D-G42` 族修法 · 车道 W113A · 2026-09-22】原为
    #   `grep -a '^\[KEY_DIAG\]' "$log" | head -4 | sed 's/^/WFP_KEYDIAG_ROW /'`。
    #   本件 `set -uo pipefail`（`:15`）⇒ 当日志里 KEY_DIAG 的**匹配输出超过管道缓冲（64 KiB）**时
    #   `head -4` 先退出 ⇒ `grep` 吃 SIGPIPE ⇒ **整条 `if` 语句 rc=141**（现场实测 3/3；
    #   <64 KiB 时 3/3 不翻）。修法：**先收进变量、再分两路印** —— 判据（`grep -a '^\[KEY_DIAG\]'`）
    #   与打印格式**一字未动**，只让生产端的 SIGPIPE 不再进 rc。
    if [ "${kd_rows:-0}" != "0" ]; then
        _kd4="$(grep -a '^\[KEY_DIAG\]' "$log" 2>/dev/null | head -4 || true)"
        if [ -n "$_kd4" ]; then printf '%s\n' "$_kd4" | sed 's/^/WFP_KEYDIAG_ROW /'; fi
    fi
    if [ "${push_rows:-0}" != "0" ]; then
        grep -a '^\[DRAW_CENSUS\] MilPushOpacityMask' "$log" 2>/dev/null | head -2 | sed 's/^/WFP_PUSHROW /'
    fi
    # 供汇总阶段使用（local 出了函数就没了 —— 实测因此炸过一次 set -u）
    LAST_FRAMES_GOOD="$frames_good"; LAST_FRAMES_TOTAL="$frames_total"; LAST_FRAMES_BLANK="$frames_blank"; LAST_COLORS="$colors"
    LAST_WINDOW="${window:-none}"; LAST_NEWWIN="$newwin"
    echo "WFP_RUN tag=$tag exit=$rc window=${window:-none} new_windows=$newwin frames_good=$frames_good/$frames_total blank=$frames_blank colors=$colors leftover_after=$leftover shot=$shot log=$log geom=$geom_now"
    echo "$tag|${window:-none}|$newwin|$frames_good|$frames_total|$frames_blank|$colors|$rc|$leftover|$shot|${geom_now:-NA}" >> "$OUT/run-rows.txt"
    reap_orphans "run_once($tag)"
}

echo "== 3/5 起应用（only=${ONLY:-all}）"
if [ -n "$ONLY" ]; then run_once "only" "--only=$ONLY"; else run_once "all" ""; fi

declare -A APP_VERDICT APP_EVIDENCE
while IFS= read -r line; do
    name="$(printf '%s' "$line" | awk '{print $2}')"
    verdict="$(printf '%s' "$line" | awk '{print $3}')"
    ev="$(printf '%s' "$line" | cut -d' ' -f4-)"
    [ -n "$name" ] || continue
    if [ "$verdict" = "INCONCLUSIVE" ] && [ -n "${APP_VERDICT[$name]:-}" ] && [ "${APP_VERDICT[$name]}" != "INCONCLUSIVE" ]; then
        APP_EVIDENCE[$name]="${APP_EVIDENCE[$name]:-} | late: $ev"       # 保留首次的非 INCONCLUSIVE 判定
    else
        APP_VERDICT[$name]="$verdict"; APP_EVIDENCE[$name]="$ev"
    fi
done < "$OUT/feat-lines.txt"

# 每块"测试色"的像素期望（与样例里的颜色表**一一对应**；`!` 前缀=期望**不出现**）
EXPECT=(
  "popup:E5484D"            # 主窗口里 anchor 是测试色；**popup 本体在独立窗口**（由 new_windows 佐证）
  "anim:F5A524"
  "opacitymask:!8B5CF6:22C55E"   # 黑遮罩 ⇒ 测试色**不可见**；白遮罩 ⇒ 第二色**可见**
  "effects:0EA5E9:EC4899"
  "controls:14B8A6"
  "textbox-edit:F97316:near:input"   # **文字块**：近色 + census GlyphRun；`:input` ⇒ "键入腿"也要验（changes>0）
  "virtualize:64748B"
  "transforms:EAB308:94A3B8"
  "nativecombo:!7C3AED"       # 下拉项容器色：**默认（无人点击时）应不出现**；外部点击腿开了才出现
  "text-rtl:A855F7"
  "text-rtl-pure:FF2D95:00FF7F:00E5FF:ADFF2F:C084FC:near:norect"   # ⑩ 纯 RTL：四行各有自己的颜色（限框+混合线判据）
  "clickprobe:!22D3EE"   # ⑬ 块：静止时不该出现它的测试色（点开下拉才出现）
)
MINPX="${WFP_MIN_PIXELS:-20}"
# 所有帧的并集直方图（含滚动前后）——用 histogram:info:-（`txt:-` 实测 ~20s/帧，会拖到超时）
pix="$OUT/pixels.txt"; : > "$pix"
for f in "$OUT"/b-*.png "$OUT"/b2-*.png; do
    [ -f "$f" ] || continue
    convert "$f" -format %c histogram:info:- 2>/dev/null \
      | sed -nE 's/^ *([0-9]+):.*(#[0-9A-Fa-f]{6}).*/\1 \2/p' >> "$pix"
done
awk '{s[toupper($2)]+=$1} END{for(k in s) printf "%d %s\n", s[k], k}' "$pix" | sort -k2 > "$pix.sum"
# 【必须兜底成 0】颜色**不在直方图里**（=计数 0）时 grep 无输出 ⇒ 旧写法返回**空串** ⇒
#   算术比较报错 ⇒ 判 FAIL。而"负向判据"里**颜色消失正是期望结果** ⇒ 会把**修好了**报成红（实测踩到）。
count_color() {
    local v
    v="$(grep -E "^[0-9]+ $1$" "$pix.sum" 2>/dev/null | head -1 | awk '{print $1+0}')"
    printf '%s' "${v:-0}"
}

# ── 近色（fuzz）计数：**抗锯齿文字必须用这个，不能用精确色** ─────────────────────
#   实测证据（2026-09-12/13，同一块 `textbox-edit`）：读图确认 TextBox 内容就在屏上
#   （白底 + 橙色 `seed-`），但 `#F97316` 的**精确色**像素是 **0**（wave 8 也只有 16），
#   两者都 < MINPX=20 ⇒ "精确色 ≥20"对文字**天然不可满足**（笔画经抗锯齿后几乎没有像素
#   恰好等于前景色）⇒ 那是**假红**。
#   做法：把"离目标色 ≤ tol% 的像素"整体染成哨兵色 `#FF00FF` 再数它 ⇒
#     颜色对 ⇒ 计数很大；颜色改错（突变自测）⇒ 计数 0 ⇒ **仍然能红**。
#   `$3`（可选）= `WxH+X+Y`：**只在该矩形内计数**。这是 2026-09-13 突变自测抓出来的必须项：
#   整帧计数会把**画面里别人的橙色**（台账面板 `#FFF5A524` 文字、卡片标题）算进来 ⇒
#   把 TextBox 前景突变成 `#010203` 之后计数仍 9320 ⇒ **判据咬不住（假绿）**。
count_color_near() {
    local hex="$1" tol="${2:-12}" rect="${3:-}" f n total=0 crop=()
    [ -n "$rect" ] && crop=(-crop "$rect" +repage)
    for f in "$OUT"/b-*.png "$OUT"/b2-*.png; do
        [ -f "$f" ] || continue
        n="$(convert "$f" "${crop[@]}" -fuzz "${tol}%" -fill '#FF00FF' -opaque "$hex" -format %c histogram:info:- 2>/dev/null \
             | sed -nE 's/^ *([0-9]+):.*#FF00FF.*/\1/p' | head -1)"
        total=$((total + ${n:-0}))
    done
    printf '%s' "$total"
}


# ── 混合线计数（`:near` 块真正该用的判据）────────────────────────────────────────
#   【为什么"离纯色多少距离"不行（2026-09-13 突变自测 + 逐像素取色查出来的）】
#   抗锯齿/选区渲染让**字形像素是"测试色与底色"的混合**：实测 TextBox 里 `#F97316` 的字形
#   实际是 `rgb(245,165,110)`（≈ 62% 测试色 + 38% 浅底 `#F0F0F0`），与纯测试色的欧氏距离
#   ≈ **101**，而 fuzz 12% 只覆盖 ≈53 ⇒ **一个都抓不到** ⇒ 限框后计数恒 0（假红）。
#   正确判据是**与背景无关**的：取矩形内**出现次数最多**的颜色当底色，沿"底色→测试色"这条
#   **混合线**投影，落在线上（**t∈[0.35,1.6]**、垂距 ≤60）的像素都算 ⇒ 底色偏白偏暗都不影响，
#   而"把前景改成别的色相"（突变自测）时字形会离开这条线 ⇒ **仍然能红**。
#   【t 阈值怎么定的（实测，突变自测的两趟逐像素取色）】同一矩形内按 t 分档：
#     还原趟（真测试色）t=0.1→21、0.2→16、0.3→30、**0.4→57、0.5→35**（强混合=字形）
#     突变趟（#010203）  t=0.1→10、0.2→7，**t≥0.3 一个都没有**（弱混合=框线/边缘）
#   ⇒ 取 **t≥0.35**：还原趟 ~92 px/帧（≥MINPX=20），突变趟 0 px ⇒ 判据既特异**又咬得住**。
count_color_mix() {   # $1=#RRGGBB  $2=矩形(可空)  $3=帧集合(空格分隔 glob，默认 "b-*.png b2-*.png")
    local hex="$1" rect="${2:-}" globs="${3:-b-*.png b2-*.png}" g f rows crop=()
    local tr=$((16#${hex:1:2})) tg=$((16#${hex:3:2})) tb=$((16#${hex:5:2}))
    local total=0
    for g in $globs; do
    for f in "$OUT"/$g; do
        [ -f "$f" ] || continue
        crop=(); [ -n "$rect" ] && crop=(-crop "$rect" +repage)
        rows="$(convert "$f" "${crop[@]}" -format %c histogram:info:- 2>/dev/null \
                | sed -nE 's/^ *([0-9]+):.*srgb\(([0-9]+),([0-9]+),([0-9]+)\).*/\1 \2 \3 \4/p')"
        [ -n "$rows" ] || continue
        total=$((total + $(printf '%s\n' "$rows" | awk -v TR="$tr" -v TG="$tg" -v TB="$tb" '
            {c[$2","$3","$4]+=$1; if($1>max){max=$1; br=$2; bg=$3; bb=$4}}
            END{ if(max=="" ) {print 0; exit}
                 dx=TR-br; dy=TG-bg; dz=TB-bb; L2=dx*dx+dy*dy+dz*dz; if(L2==0){print 0; exit}
                 for(k in c){ split(k,p,","); px=p[1]-br; py=p[2]-bg; pz=p[3]-bb
                     t=(px*dx+py*dy+pz*dz)/L2; if(t<0.35||t>1.6) continue
                     ex=px-t*dx; ey=py-t*dy; ez=pz-t*dz; d2=ex*ex+ey*ey+ez*ez
                     if(d2<=3600) s+=c[k] }
                 print s+0 }')))
    done
    done
    printf '%s' "$total"
}

# 控件矩形（样例自报 `WFP_BOXID=<块名> x=… y=… w=… h=…`，窗口坐标系）⇒ `WxH+X+Y`
box_rect() {   # $1=块名；无则输出空（`WFP_BOXID_OVERRIDE` 仅用于自测：把矩形挪到空白处）
    if [ -n "${WFP_BOXID_OVERRIDE:-}" ]; then printf '%s' "$WFP_BOXID_OVERRIDE"; return 0; fi
    local row
    row="$(grep -ahE "^WFP_BOXID=$1 " "$OUT"/probe-*.log 2>/dev/null | tail -1)"
    [ -n "$row" ] || return 0
    local x y w h
    x="$(printf '%s' "$row" | sed -nE 's/.* x=([0-9-]+).*/\1/p')"
    y="$(printf '%s' "$row" | sed -nE 's/.* y=([0-9-]+).*/\1/p')"
    w="$(printf '%s' "$row" | sed -nE 's/.* w=([0-9-]+).*/\1/p')"
    h="$(printf '%s' "$row" | sed -nE 's/.* h=([0-9-]+).*/\1/p')"
    [ -n "$x" ] && [ -n "$y" ] && [ -n "$w" ] && [ -n "$h" ] && [ "$w" -gt 0 ] && [ "$h" -gt 0 ] && printf '%sx%s+%s+%s' "$w" "$h" "$x" "$y"
}

# ── 字形是否**真的提交给了渲染器**（census 每帧汇总行里的 `GlyphRun×N`）──────────
#   输出：非负整数；或 `NA` = **没有 census 行**（开关没开/没抓到 ⇒ 判据不因此变红，
#   只记"未取到"，否则会把"仪器没开"误报成"没画字形"）。
census_glyph_runs() {
    local nlines v
    nlines="$(grep -ahc 'DRAW_CENSUS\] frame=' "$OUT"/probe-*.log 2>/dev/null | awk '{s+=$1} END{print s+0}')"
    [ "${nlines:-0}" -eq 0 ] && { printf 'NA'; return; }
    v="$(grep -ahoE 'GlyphRun×[0-9]+' "$OUT"/probe-*.log 2>/dev/null | sed -nE 's/GlyphRun×([0-9]+)/\1/p' | sort -n | tail -1)"
    printf '%s' "${v:-0}"
}

ok=0; fail=0; inc=0
# `skipped`：`--only=X` 时未构建的块（**不计入 ok/fail/inconclusive**，见下面的块表注释）
skipped=0
{
  echo "块名|应用判定|像素判定|证据"
  for b in $BLOCKS; do
      v="${APP_VERDICT[$b]:-}"
      ev="${APP_EVIDENCE[$b]:-}"
      exp=""; for e in "${EXPECT[@]}"; do case "$e" in "$b:"*) exp="${e#*:}";; esac; done
      px="n/a"; pxnote=""
      # 【2026-09-14 修 · "仪器看不见对象"族】这些标志原来只在**有期望规格**的分支里初始化
      #   （`[ -n "$exp" ]` 里面），于是**没有期望规格的块**（如 `text-dp-min`：D-P1 最小复现）
      #   走到下面 `if [ "$input_leg" = "1" ]` 时 `set -u` 直接炸：`行 729: input_leg: 未绑定的变量`
      #   （实测：把 `text-dp-min` 加进 BLOCKS 后立刻复现）。⇒ **在循环头无条件给默认值**，
      #   这样将来再加块也不会因为"忘了配期望"而炸在汇总阶段。
      neg=0; near=0; input_leg=0; norect=0; spec=""
      # 【`--only=X` 的汇总语义（2026-09-13 修）】指定单块时，**其余块根本没被构建/跑过**。
      #   旧写法把它们一律记成 `INCONCLUSIVE` ⇒ 汇总行变成 `ok=1 inconclusive=8`，
      #   读的人会以为"仪器抓不到 8 块"（实测被误读，见本轮报告）。现在单块趟把其余块标成
      #   `skipped`（**不计入 ok/fail/inconclusive**），汇总行也据此加一个 `skipped=N` 字段。
      if [ -n "$ONLY" ]; then
          case ",$ONLY," in *",$b,"*) ;; *) printf '%s|%s|%s|%s\n' "$b" "skipped" "-" "本次只跑 --only=$ONLY，该块未构建"; skipped=$((skipped + 1)); continue ;; esac
      fi
      if [ -z "$v" ]; then
          v="INCONCLUSIVE"; ev="${ev:-未自报（块级 try/catch 也没抓到 ⇒ 疑似原生级崩溃；见分诊）}"
          inc=$((inc + 1))
      fi
      if [ -n "$exp" ] && [ "$LAST_FRAMES_GOOD" != "0" ]; then
          # 【解析规则（原来写错过，导致"双色/负向"两类判据都在乱判）】
          #   规格形状：`[!]COLOR1[:COLOR2][:near]`
          #     `!` 前缀 ⇒ **负向**：COLOR1 必须**不可见**（< MINPX），COLOR2（若有）必须可见
          #     无 `!`    ⇒ 正向：COLOR1 必须可见；给了 COLOR2 则它也必须可见
          #     `:near`   ⇒ 用**近色计数**（`count_color_near`）代替精确色，并**追加一条
          #                  census 判据**："有没有 `GlyphRun` 提交给渲染器"（文字块专用）
          # ⚠️ 这里在 `{ … }` 块里（不是函数）⇒ **不能用 local**（实测：local 只能在函数中使用）
          # 【支持多色（2026-09-13）】规格 `[!]C1[:C2[:C3…]][:near][:input]`
          #   `!` 前缀 ⇒ C1 为**负向**（必须不可见），其余必须可见；无 `!` ⇒ **全部必须可见**。
          #   ⑩ 纯 RTL 块有 4 个颜色（每行一个），所以判据必须能列 N 个色。
          neg=0; near=0; input_leg=0; norect=0; spec="$exp"
          case "$spec" in !*) neg=1; spec="${spec#!}" ;; esac
          # 【顺序无关地剥离标志位】`…:near:norect` 与 `…:norect:near` 都要能解析
          #   （实测踩到：先剥 near 再剥 norect ⇒ `near` 留在颜色列表里变成"第 5 个颜色"）
          while :; do
              case "$spec" in
                  *:input)  input_leg=1; spec="${spec%:input}" ;;
                  *:near)   near=1;      spec="${spec%:near}" ;;
                  *:norect) norect=1;    spec="${spec%:norect}" ;;
                  *) break ;;
              esac
          done
          # `:norect` ⇒ **故意整帧计数**（该块四色**全局唯一**；且它的 `WFP_BOXID` 报的是
          #   **布局坐标**，与实际绘制差了 +73 px（实测框 65x16+86+39 全是底色、字形在 x=13..30）
          #   ⇒ 对着那个框计数会恒 0（假红）。"布局坐标≠绘制坐标"本身值得 RTL 车道看，但不许污染判据。
          cols=(); IFS=':' read -r -a cols <<< "$spec"
          cnts=(); ev_counts=""; boxnote=""
          if [ "$near" = "1" ]; then
              # **只在该控件矩形内计数**（特异性）；取不到矩形就退回整帧并在证据里**写明**
              #   ⚠️ 修（主控 2026-09-14 抓）：原来是 ``…**全局唯一**，`:norect`）`` —— **双引号里的反引号会当命令执行**
              #      ⇒ 每趟都往 stderr 打 `行 659: :norect: 未找到命令`，且 `boxnote` 里那个标记被**替换成空**
              #      （证据串少一段）。同族缺陷："仪器打出来的东西 ≠ 它想说的东西"，还会污染
              #      任何按 stderr 找错误的检查（`grep -i 'not found'` 在这里会假阳）。这里用 `\`` 转义。
              if [ "$norect" = "1" ]; then boxr=""; boxnote="（整帧计数：该块四色**全局唯一**，\`:norect\`）"
              else
                  boxr="$(box_rect "$b")"
                  if [ -n "$boxr" ]; then boxnote="（限框 $boxr 内计数）"; else boxnote="（⚠️ 无控件矩形 ⇒ 整帧计数，特异性弱）"; fi
              fi
              for cc in "${cols[@]}"; do cnts+=("$(count_color_mix "#$cc" "$boxr")"); done
          else
              for cc in "${cols[@]}"; do cnts+=("$(count_color "#$cc")"); done
          fi
          for i in "${!cols[@]}"; do ev_counts="${ev_counts} #${cols[$i]}=${cnts[$i]}"; done
          px_ok=1
          if [ "$neg" = "1" ]; then
              # C1 必须**不可见**，其余必须可见
              [ "${cnts[0]}" -lt "$MINPX" ] || px_ok=0
              for i in "${!cols[@]}"; do [ "$i" = "0" ] && continue; [ "${cnts[$i]}" -ge "$MINPX" ] || px_ok=0; done
              if [ "$px_ok" = "1" ]; then
                  px="OK(负向 #${cols[0]}=${cnts[0]}<$MINPX 不可见；正向${ev_counts# #${cols[0]}=${cnts[0]}})"
              else
                  px="FAIL(负向 #${cols[0]}=${cnts[0]} 本应<$MINPX 不可见；正向${ev_counts# #${cols[0]}=${cnts[0]}} 应>=$MINPX)"
              fi
          else
              for i in "${!cols[@]}"; do [ "${cnts[$i]}" -ge "$MINPX" ] || px_ok=0; done
              if [ "$px_ok" = "1" ]; then px="OK(${ev_counts# })"; else px="FAIL(${ev_counts# } 期望每色 >=$MINPX)"; fi
          fi
          px="${px}${boxnote}"
          # ── 文字块追加判据：**字形有没有提交给渲染器**（census `GlyphRun×N`）──────
          #   只有 `:near` 块走这条（=色块型判据不受影响）。三态处理：
          #     NA  ⇒ census 没抓到 ⇒ **不据此判红**，只记"未取到"（否则"仪器没开"会被误报成"没画"）
          #     0   ⇒ 一个字形都没提交 ⇒ **红**（这才是真缺陷，与抗锯齿无关）
          #     ≥1  ⇒ 记进证据（字形确实画了）
          if [ "$near" = "1" ]; then
              gr="$(census_glyph_runs)"
              case "$gr" in
                  NA) px="$px ＋ census 未取到（GlyphRun 判据跳过）" ;;
                  0)  px="FAIL($px 但 census **GlyphRun=0** ⇒ 一个字形都没提交给渲染器)" ;;
                  *)  px="$px ＋ census GlyphRun×$gr≥1" ;;
              esac
          fi
      fi
      # ── 键入腿（`:input`）：**"画得对"不等于"编辑得了"** ────────────────────────
      #   2026-09-13 实测：像素侧已能判绿（近色 8958 + census GlyphRun×7），但
      #   `changes=0`（注入的键没进 TextBox）⇒ 若就此记 OK，等于**用"画得对"冒充"编辑态可用"**。
      #   判定三态：`changes>0` ⇒ 键入腿成立（写进证据）；`changes=0` ⇒ **INCONCLUSIVE**；日志里根本没有该行 ⇒ 不动。
      #   ⚠️ **口径更正（T1b 2026-09-13，T1c §35.5）**：`changes=0` 若取自**注入之前**的台账行 ⇒ **无信息**
      #   （**不是**"键没进"）；键是否到位另看 `WFP_MSGS WM_CHAR` 与 `KEY_DIAG`。
      #   **本行不得单独下"输入栈"结论**（旧文案曾写"瓶颈在托管输入栈"——那是在拿注入前的读数下结论）。
      # ── 键入腿（`:input`，2026-09-13 **口径更正**）──────────────────────────────
      #   旧口径用 `changes>0`（`TextChanged` 计数）判"键有没有到控件" ⇒ 实测**假红**：
      #   屏幕上明明出现了 `AB`（注入后原始分辨率帧），日志里 `changes=0`。
      #   ⇒ 现口径 = **注入前后 `WFP_BOXID` 矩形内"测试色混合线字形像素"是否变化**
      #      （注入后帧 `b3-*` 由 runner 在注入之后补抓；`changes` 只作**旁证**打印）。
      #   并且（T1b 2026-09-13 收紧口径）：
      #     · 像素/容器对 **且** `Text` DP **有写后读数且陈旧** ⇒ 记**缺陷**（不是 PASS）；
      #     · **没有写后读数** ⇒ 记 `INCONCLUSIVE(无信息)`，**不许**写成"陈旧"。
      #   判定工具：build/MilBridge/tools/t1c-dp1-leg-audit.py（rc 0=closed / 2=defect / 3=noinfo）。
      # ── 【T3 2026-09-15 · L23「读数早于事件」**修点**】─────────────────────────
      #   上面那条"有写后读数且陈旧 ⇒ 缺陷"的**读点错了**：#13 复取实测，`feat-lines.txt`（**台账**）
      #   里那条读数取自**注入之前**的自报快照（`[feat]` 在 t≈3.8s，而写入在 `WFP_LATE_SCHEDULED … after_ms=6000`
      #   之后 t≈11.0s）⇒ 台账给 `changes=0`、旧文案据此写"可观测模型陈旧"；而**应用原始日志**里
      #   `WFP_POSTWRITE t=11047 变更 text='AB' len=2 sel=2,0 changes=2` + `DP1_LEG state=closed rc=0 write_rows=4 reads_after_write=3`
      #   证明链是**闭合**的 ⇒ **非回归**（登记见 samples/WpfFeatureProbe/KNOWN-DEFECTS.md 的 **L23**）。
      #   **修法**：读点 = **应用原始日志**（`INJECT_AT_APPLOG_FILE`）里"行号 > 注入前锚点"的**末条**
      #   `WFP_POSTWRITE … changes=/text=`（`pick-postwrite-line.py`；**5 极性离线牙** `--selftest`）。
      #   **口径不变**（主控 2026-09-15 裁定 ①：**不升**）——`changes>0` 时该块**仍记 `INCONCLUSIVE`**，
      #   只让**证据行诚实**（如实写 `changes=N`）；拿不出"晚于注入"的读数 ⇒ `NOINFO`，**不许**写"陈旧"。
      if [ "$input_leg" = "1" ]; then
          in_box="$(box_rect "$b")"
          leg_col="${cols[0]}"
          g_before="$(count_color_mix "#$leg_col" "$in_box" 'b-*.png')"
          g_after="$(count_color_mix "#$leg_col" "$in_box" 'b3-*.png')"
          # 【T3 2026-09-15 · L23 修法】读点从**台账**改到**应用原始日志**（"一个事件两份日志"，与 L18 同源）：
          #   `WFP_POSTWRITE … changes=`/`text=` 由**写入点自己**打印，runner 不转发它 ⇒ 必须读 app log。
          #   锚点 = 注入前记下的应用日志行数（`INJECT_AT_APPLOG_LINE`，免时钟对齐）；
          #   找不到"晚于锚点"的读数 ⇒ **NOINFO**（**不许**写成"陈旧/没进"）—— 三态判定见 pick-postwrite-line.py 文件头。
          #   ⚠️ `WFP_APPLOG_ANCHOR_OVERRIDE=<N>` **仅供自测**：把锚点人为推后 ⇒ 期望得到 `NOINFO`（反极性牙）。
          _applog="${INJECT_AT_APPLOG_FILE:-}"; _anchor="${WFP_APPLOG_ANCHOR_OVERRIDE:-${INJECT_AT_APPLOG_LINE:-0}}"
          if [ -n "$_applog" ] && [ -f "$_applog" ]; then
              pick_out="$(python3 "$ROOT/tests/WpfGfx.Linux.Tests/Presentation.Tests/pick-postwrite-line.py" \
                            --file "$_applog" --after-line "$_anchor" 2>/dev/null)"
          else
              pick_out="NOINFO"
          fi
          pick_status="$(printf '%s' "$pick_out" | cut -f1)"; pick_status="${pick_status:-NOINFO}"
          ch_now="$(printf '%s' "$pick_out" | cut -f2)"; ch_now="${ch_now:-NA}"
          txt_now="$(printf '%s' "$pick_out" | cut -f3)"
          if ! ls "$OUT"/b3-*.png >/dev/null 2>&1; then
              # 【防假红】没有注入后帧 ⇒ **仪器没采到**（例如注入被 WFP_INPUT=0 关掉）
              #   ⇒ 记 INCONCLUSIVE 并在证据里说明；**不许**把 g_after=0 读成"没键入"。
              leg="INCONCLUSIVE(没有注入后帧 b3-* ⇒ 仪器未采样，不能判"键入有没有生效")"
              v="INCONCLUSIVE"; ev="$ev ｜ 键入腿(像素)=$leg ｜ changes=$ch_now（旁证）$txt_now"
          elif [ "${g_after:-0}" -ge "$MINPX" ] && [ "$g_before" != "$g_after" ]; then
              leg="PASS(矩形 $in_box 内字形像素 注入前=$g_before → 注入后=$g_after)"
              # 像素腿过了，但可观测模型陈旧 ⇒ INCONCLUSIVE（不是 PASS）
              if [ "$pick_status" != "AFTER" ]; then
                  # 应用日志里没有"晚于注入"的写后读数 ⇒ **无信息**（旧 `tail -1` 正是在这里把注入前的行当成注入后的结论）
                  v="INCONCLUSIVE"
                  ev="$ev ｜ **键入腿(像素)=PASS**：$leg ｜ 应用日志里**没有晚于注入的写后读数**（pick-postwrite-line=$pick_status，锚点行=${_anchor:-0}）⇒ **无信息**：既不能说"键没进"，也不能说"模型陈旧"（口径见 tests/WpfGfx.Linux.Tests/Presentation.Tests/pick-postwrite-line.py 文件头）"
              elif [ "$ch_now" = "0" ]; then
                  v="INCONCLUSIVE"
                  ev="$ev ｜ **键入腿(像素)=PASS**：$leg ｜ 且**有晚于注入的写后读数**、changes=0（$txt_now；来源=应用日志，行号>锚点 ${_anchor:-0}）⇒ **真**陈旧（缺陷，不是通过）：读 Text/绑定 Text 的真应用会**静默拿旧值**"
              else
                  ev="$ev ｜ 键入腿(像素)=PASS：$leg ｜ 写后读数 changes=$ch_now（$txt_now；来源=应用日志）"
              fi
          else
              leg="FAIL(矩形 $in_box 内字形像素 注入前=$g_before → 注入后=$g_after：**矩形内没有出现新字形** ⇒ 注入没生效)"
              v="FAIL"; ev="$ev ｜ 键入腿(像素)=FAIL：$leg ｜ changes=$ch_now（旁证）$txt_now"
          fi
      fi
      case "$px" in FAIL*) [ "$v" = "OK" ] && { v="FAIL"; ev="$ev ｜ 像素侧判红：$px"; } ;; esac
      [ "$v" = "OK" ] && ok=$((ok + 1)); [ "$v" = "FAIL" ] && fail=$((fail + 1))
      printf '%s|%s|%s|%s\n' "$b" "$v" "$px" "$ev"
  done
} > "$OUT/blocks.txt"
cat "$OUT/blocks.txt" | column -t -s'|' 2>/dev/null || cat "$OUT/blocks.txt"
TOTAL=$(( $(tail -n +2 "$OUT/blocks.txt" | grep -c '|') ))
echo "WFP_SUMMARY blocks=$TOTAL ok=$ok fail=$fail inconclusive=$((TOTAL - ok - fail - ${skipped:-0})) skipped=${skipped:-0} frames_good=$LAST_FRAMES_GOOD/$LAST_FRAMES_TOTAL blank=$LAST_FRAMES_BLANK colors=$LAST_COLORS new_windows=$LAST_NEWWIN window=$LAST_WINDOW"

# 崩溃分诊：没自报的块逐个复跑（结果**单独标注**，不混进主台账）
#   【2026-09-13 修：`--only=X` 趟**不该**把其余 8 块拿去分诊】指定单块时其余块**根本没被构建**
#   ⇒ 它们"未自报"是**构造使然**，不是崩溃。旧写法会白跑 8 次应用（每趟多 1-2 分钟），
#   还会把 `anim=FAIL` 这类无关块的结论混进同一份日志（本轮实测被读成"anim 在同一配置下三种结论"）。
#   现在：`--only` 趟默认**关分诊**（只分诊被指定的那块，若它未自报）；要旧行为用 `WFP_TRIAGE=1` 显式开。
MISSING=""
for b in $BLOCKS; do
    if [ -n "$ONLY" ]; then
        case ",$ONLY," in *",$b,"*) [ -z "${APP_VERDICT[$b]:-}" ] && MISSING="$MISSING $b" ;; esac
    else
        [ -z "${APP_VERDICT[$b]:-}" ] && MISSING="$MISSING $b"
    fi
done
if [ -n "$MISSING" ] && [ "$TRIAGE" = "1" ]; then
    echo "== 4b/5 崩溃分诊（未自报块：$MISSING）"
    for b in $MISSING; do
        echo "   ── 复跑 --only=$b"
        run_once "triage-$b" "--only=$b"
        local_v="$(grep -aE "^\\[feat\\] $b " "$OUT/feat-lines.txt" | tail -1 | awk '{print $3}')"
        if [ -z "$local_v" ]; then
            # 单块跑了还是没自报：**要么它把进程打死了，要么它连构造都没到**
            #   `LAST_RC=143` = 被我们 TERM（即活着但没自报）；其它 rc / 非 143 ⇒ 自己死的
            if [ "${LAST_RC:-}" = "143" ]; then
                echo "WFP_TRIAGE block=$b verdict=未自报(进程活着但该块没出账 —— 疑似卡死/挂起)"
            else
                crash_tail="$(grep -aE 'Unhandled exception|SIGSEGV|Aborted|core dumped|NativeAOT|Stack overflow' "$OUT/probe-triage-$b.log" 2>/dev/null | head -2 | tr '\n' ' ')"
                echo "⛔⛔ WFP_CRASH_BLOCK=$b  exit=${LAST_RC:-?}  ← **能把进程打死（比"没画出来"更严重）**"
                echo "⛔     evidence: ${crash_tail:-（日志里没有常见崩溃字样，见 $OUT/probe-triage-$b.log）}"
                echo "⛔     复现：  run-wpfprobe.sh 60 --only=$b"
            fi
        else
            echo "WFP_TRIAGE block=$b verdict=$local_v"
        fi
    done
fi

# ── 5/5 总结 ────────────────────────────────────────────────────────────────
echo
echo "== 5/5 总结"
echo "   逐次运行行："; grep -a '^WFP_RUN' "$OUT/run-rows.txt" >/dev/null 2>&1 || true
sed 's/^/     /' "$OUT/run-rows.txt" 2>/dev/null | head -12
echo "   ♻️ REAPED_ORPHANS total=$REAPED_TOTAL"
echo "   截图目录：$OUT"
ls -la "$OUT"/*.png 2>/dev/null | tail -3 | sed 's/^/     /'
# 三态（与样例 runner 同口径，**不把"仪器/未自报"混成 FAIL**）：
#   PASS = **被选的**块全部 OK ｜ FAIL = 有块判红 ｜ INCONCLUSIVE = 无红但也没全绿（多为应用没跑到自报）
#   ⚠️ 修（主控 2026-09-14 抓的"一个数字两个消费者"）：`--only=X` 时未构建的块算 `skipped`，
#      **不计入 inconclusive**。原来这一行没减 `${skipped}` ⇒ `WFP_SUMMARY` 说 `skipped=8`、
#      而 `WFP_GATE` 同一批块说 `inconclusive=8` ⇒ 两行自相矛盾，读者只能来问人
#      （主控就正好看到 `WFP_GATE=INCONCLUSIVE … inconclusive=8` 并让我"写明这不是失败"）。
#      现在两行同口径：被选块全绿 ⇒ PASS，并把 `skipped` 显式打出来。
INC=$((TOTAL - ok - fail - ${skipped:-0}))
# 应用自报的构建块（`WFP_MODE=blocks:… count=N`）——端到端交叉校验的输入（见下）。
APP_MODE_LINE="$(grep -ah '^WFP_MODE=' "$OUT"/probe-*.log 2>/dev/null | tail -1)"
if [ "$fail" != "0" ]; then GATE=FAIL; RC=1
elif [ "$ok" = "$((TOTAL - ${skipped:-0}))" ] && [ "$((TOTAL - ${skipped:-0}))" != "0" ]; then GATE=PASS; RC=0
else GATE=INCONCLUSIVE; RC=2; fi
# 【机器强制的注册表断言并进门禁结论】（3.5/5 节）：不一致/无信息 ⇒ **本趟判红**，
#   即使所有块的判定都绿也不许 PASS（L19：表与对象漂移会让"绿"没有意义）。
if [ "${REGISTRY_RC:-0}" != "0" ]; then
    GATE=FAIL; RC=1
    echo "   ❌ 块注册表断言未通过（$BLOCK_REGISTRY_RESULT）⇒ 门禁判红（『block_registry_check』见 3.5/5 节）"
fi
# 【端到端交叉校验】应用自报的构建块数 vs 块表条目数：全量趟必须相等；
#   `--only` 趟必须等于"被选块数"。不等 ⇒ 应用建的块与我们的表**不是同一批** ⇒ 判红。
if [ -n "${APP_MODE_LINE:-}" ]; then
    _appn="$(printf '%s' "$APP_MODE_LINE" | sed -n 's/.*count=\([0-9]\+\).*/\1/p')"
    if [ -n "$_appn" ]; then
        _want="$TOTAL"; [ -n "$ONLY" ] && _want="$(printf '%s' "$ONLY" | tr ',' '\n' | grep -c .)"
        if [ "$_appn" = "$_want" ]; then
            echo "   ✅ 端到端：应用自报构建块数=$_appn == 期望($_want)（$APP_MODE_LINE）"
        else
            GATE=FAIL; RC=1
            echo "   ❌ 端到端：应用自报构建块数=$_appn ≠ 期望($_want) ⇒ 应用建的块与 runner 的表不是同一批（$APP_MODE_LINE）"
        fi
    else
        echo "   ⚠️ 端到端：应用自报行里取不到 count= ⇒ **无信息**（不当通过）"
        GATE=FAIL; RC=1
    fi
else
    echo "   ⚠️ 端到端：日志里没有 WFP_MODE 行 ⇒ **无信息**（不当通过）"; GATE=FAIL; RC=1
fi
echo "WFP_GATE=$GATE blocks=$TOTAL ok=$ok fail=$fail inconclusive=$INC skipped=${skipped:-0} registry=$BLOCK_REGISTRY_RESULT（0=PASS/1=FAIL/2=INCONCLUSIVE；skipped=本次 --only 未构建的块，不计入判定）"
if [ "${skipped:-0}" != "0" ]; then
    echo "   ⓘ 本趟是 \`--only=$ONLY\` 的范围产物：只构建/只判了 $((TOTAL - skipped)) 块（$ok OK / $fail FAIL），"
    echo "     另外 $skipped 块**根本没构建**（应用自报 WFP_MODE 里也没有它们）⇒ 不是失败、也不是仪器无效。"
fi
exit $RC
