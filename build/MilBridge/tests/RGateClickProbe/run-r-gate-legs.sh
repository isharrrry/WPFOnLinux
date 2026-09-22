#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# run-r-gate-legs.sh —— `R-GATE`（`TASK-0702`）的**装置**：
#   把「连续点击 / 交互响应」做成**仓内可复算的证据**。
#
# 【它取代谁】仓外临时仪器 `$HOME/w47b-click.sh`（`7e86e3f105dc8778`，`#47` 车道 W47B 留）。
#   `docs/ROUTES.md:73` 把它记成欠账的形态是"**连续点击只有负向判据、正向判据由仓外临时脚本驱动**"
#   ⇒ 仓外件不能当判据（仪器一丢，判据就没了）。本件把它**搬进仓**并拆成两层：
#     · **本件 = 装置**：起私有 Xvfb、装配私有 app 目录、`xdotool` 真实节奏点击（`mousedown`→停 150 ms→`mouseup`）、
#       按 PID 收尾（**绝不 `pkill -f`**），落 `app.log` ＋ `evidence.txt`（逐步行号区间 ＋ X 服务器读数）。
#     · **判据唯一实现 = `build/MilBridge/tools/r-gate-step.sh`**（三态 ＋ 机读行 `R_GATE=`）。
#   ⚠️ **本件不做裁决**：它只落证据。为什么这样拆 —— 判据要能在**无 X、无 dotnet** 的机器上自测
#      （`r-gate-step.sh --selftest` 用合成证据跑 14 例），而装置只能在这台机器上跑。
#
# 【判据（先写死，见 `docs/WAVE50-PREREGISTRATION.md` §1，逐格继承 `#49` 预登记 §3 B3）】
#   ① 点 ListBox 项 ⇒ `EVT lst.selection=<被点项>`     ｜反：点卡片右侧空白 ⇒ 控件级 `EVT` 新增 = 0
#   ② 点 TextBox ⇒ `EVT tb.focus` ≥ 1                  ｜反：点**窗口外** ⇒ 无新控件级 `EVT`
#   ③ 点后键入 3 字符 ⇒ `EVT tb.text=` 行数 ≥ 3 且长度单调增 ｜反：**未点击就键入** ⇒ `tb.focus` 不增
#   ④ 点 ComboBox ⇒ `EVT combo.opened` = 1 ＋ 弹窗窗口 `IsViewable` ｜反：下拉开着时点下拉外 ⇒ 无 `combo.selection`
#   ⑤ 点弹窗 item[1] ⇒ `EVT combo.selection=1` ＋ `combo.closed` = 1
#   ⑥ 每次 mouse-up 之后 `cap=none`（`D-G55` 机器指纹）：点击后把指针**在卡片内**挪 2 px，读该 `EVT move` 行的 `captured=null`
#   ⑦ 承重连续腿：窗口内连点三下（ListBox → TextBox → ComboBox）⇒ 每下都出各自 `EVT`
#   ⑧ 像素：下拉打开时测试色 `22D3EE` 像素数 > 0（关着时的读数一并记）
#
# 【为什么⑦承重】`#47` W47B 实测：**逐个点击全绿、连做全红** —— 因为"每步把指针停到窗口外"会
#   顺带释放鼠标捕获（`D-G55`），于是"逐个点击"根本不是用户动作。本装置**除 `L1_outside` 本身之外，
#   每一次点击都在窗口内完成**（整趟都是连续交互），"点完把指针挪出窗口"这种自我安慰的写法**不许**出现。
#
# 【用法】
#   bash build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh [--no-build] [--keep] [--out=DIR]
#        [--display=:NN] [--appdir=DIR] [--sabotage=none|windowmove]
#   env：`R_GATE_OUT`／`R_GATE_DISPLAY`／`R_GATE_APPDIR`／`R_GATE_SABOTAGE`／`R_GATE_MIN_MB`／`R_GATE_LATE_MS`
#   `--appdir=<已装配的应用目录>`：**只读**拷进 `$OUT/app` 再跑 ⇒ 用于**产品级反极性**
#     （只换回 `libwpfwin32.so e700c383ec1ecdc8` 那一趟；**绝不改仓内权威件**）。
#   `--sabotage=windowmove`：POS 取完后把窗口挪 (+300,+250) ⇒ 点击坐标全失效（**仪器级反极性**）。
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/../../../.." && pwd)"
. "$ROOT/build/selfbuilt-config.sh"
CFG="$SELFBUILT_CONFIG"
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_gcServer=0

PROBE_SRC="$ROOT/samples/WpfFeatureProbe/bin/$CFG/net10.0"
PROBE_DLL="WpfFeatureProbe.dll"

DO_BUILD=1; KEEP=0; OUT=""; DISP=""; APPDIR_SRC=""; SABOTAGE="${R_GATE_SABOTAGE:-none}"
MIN_MB="${R_GATE_MIN_MB:-1000}"; LATE_MS="${R_GATE_LATE_MS:-3000}"; APP_TIMEOUT="${R_GATE_APP_TIMEOUT:-150}"
WAIT_WIN="${R_GATE_WAIT_WIN:-60}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-build)   DO_BUILD=0; shift ;;
    --keep)       KEEP=1; shift ;;
    --out)        OUT="${2:-}"; shift 2 ;;
    --out=*)      OUT="${1#*=}"; shift ;;
    --display)    DISP="${2:-}"; shift 2 ;;
    --display=*)  DISP="${1#*=}"; shift ;;
    --appdir)     APPDIR_SRC="${2:-}"; shift 2 ;;
    --appdir=*)   APPDIR_SRC="${1#*=}"; shift ;;
    --sabotage)   SABOTAGE="${2:-}"; shift 2 ;;
    --sabotage=*) SABOTAGE="${1#*=}"; shift ;;
    -h|--help)    sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "用法见文件头（未知参数：$1）" >&2; exit 2 ;;
  esac
done

OUT="${OUT:-${R_GATE_OUT:-/tmp/r-gate-$(date +%m%d-%H%M%S)-$$}}"
DISP="${DISP:-${R_GATE_DISPLAY:-}}"
APPDIR_SRC="${APPDIR_SRC:-${R_GATE_APPDIR:-}}"
mkdir -p "$OUT" || { echo "建不了 OUT=$OUT" >&2; exit 2; }
: > "$OUT/evidence.txt"; : > "$OUT/device.log"
APPLOG="$OUT/app.log"
APP="$OUT/app"

XPID=""; APID=""
cleanup() {
  [ -n "$APID" ] && { kill -TERM "$APID" 2>/dev/null; sleep 0.5; kill -KILL "$APID" 2>/dev/null; }
  [ -n "$XPID" ] && { kill -TERM "$XPID" 2>/dev/null; wait "$XPID" 2>/dev/null; }
  APID=""; XPID=""
}
trap cleanup EXIT INT TERM

say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "$OUT/device.log"; }
evid() { printf 'EVID %s\n' "$*" >> "$OUT/evidence.txt"; }
# 致命 ⇒ 落 NOINFO 证据并**正常退出**（裁决权在判据件；被 SIGKILL 时证据里就没有 device=OK ⇒ 判据报 device-incomplete）
fatal() { local tok="$1"; shift; evid "device=NOINFO reason=$tok $*"; say "R_GATE_DEVICE=NOINFO reason=$tok $*"; cleanup; exit 0; }

sha16() { [ -f "$1" ] && sha256sum "$1" | cut -c1-16 || printf 'MISSING'; }
# 精确取键（**不用** sed 的宽松匹配：`down_delta` 里含 `delta`，宽松匹配会串键）
field() { awk -v k="$1" '{for(i=1;i<=NF;i++){n=index($i,"="); if(n>1 && substr($i,1,n-1)==k){print substr($i,n+1); exit}}}'; }
kv()    { printf '%s' "$1" | field "$2"; }
alines() { wc -l < "$APPLOG" 2>/dev/null | tr -d ' '; }
msgcount() { local n; n="$(grep -ac "msg=$1 " "$APPLOG" 2>/dev/null || true)"; printf '%s' "${n:-0}"; }
# `EVID` 行取值（供本件与判据件共用同一条口径）
evid_last() { grep -a "^EVID $1" "$OUT/evidence.txt" 2>/dev/null | tail -1; }

# ═══ 0. 前置：工具／内存／件 ═══════════════════════════════════════════════════
say "=== R-GATE 装置 · 起点 ==="
say "OUT=$OUT appdir_src=${APPDIR_SRC:-<自装配>} sabotage=$SABOTAGE"
TOOLS=""
for t in Xvfb xdotool xwininfo xdpyinfo xwd convert; do
  p="$(command -v "$t" 2>/dev/null || true)"
  [ -n "$p" ] || TOOLS="${TOOLS}${t}=MISSING "
  evid "tool name=$t path=${p:-MISSING}"
done
[ -n "$TOOLS" ] && fatal tools-missing "缺 X 工具：$TOOLS"
MEM_MB="$(awk '/MemAvailable/{printf "%d", $2/1024}' /proc/meminfo)"
LOAD="$(cut -d' ' -f1-3 /proc/loadavg)"
say "loadavg=$LOAD mem_available=${MEM_MB}MB nproc=$(nproc)"
[ "$MEM_MB" -ge "$MIN_MB" ] || fatal low-memory "mem_available=${MEM_MB}MB < 门槛 ${MIN_MB}MB（读数不可归因）"
evid "env mem_mb=$MEM_MB min_mb=$MIN_MB load=$LOAD nproc=$(nproc) kernel=$(uname -r)"
evid "sabotage kind=$SABOTAGE"

# ── 构建（`--no-build` 可跳；失败 ⇒ NOINFO，**不拿旧产物跑**）────────────────────
if [ "$DO_BUILD" = 1 ] && [ -z "$APPDIR_SRC" ]; then
  say "── 构建 samples/WpfFeatureProbe（-m:1）"
  if ! timeout 300 dotnet build "$ROOT/samples/WpfFeatureProbe/WpfFeatureProbe.csproj" -c "$CFG" -m:1 --nologo -v q > "$OUT/build.log" 2>&1; then
    fatal build-failed "见 $OUT/build.log"
  fi
fi
[ -f "$PROBE_SRC/$PROBE_DLL" ] || fatal probe-missing "缺 $PROBE_SRC/$PROBE_DLL（先构建样本）"

# ── 私有 display（**先探能不能连**，不认"有没有 Xvfb 进程"）────────────────────
if [ -z "$DISP" ]; then
  for d in 88 89 90 91 92 86 87 84 85 82 83 80 81; do
    if ! DISPLAY=":$d" xdpyinfo > /dev/null 2>&1; then DISP=":$d"; break; fi
  done
  [ -n "$DISP" ] || fatal no-free-display "88..92/86..87/84..85/82..83/80..81 全被占用"
fi
Xvfb "$DISP" -screen 0 1280x1024x24 > "$OUT/xvfb.log" 2>&1 & XPID=$!
for _ in $(seq 1 40); do DISPLAY="$DISP" xdpyinfo > /dev/null 2>&1 && break; sleep 0.25; done
DISPLAY="$DISP" xdpyinfo > /dev/null 2>&1 || fatal xvfb-failed "display=$DISP xpid=$XPID"
export DISPLAY="$DISP"
say "X display=$DISP xpid=$XPID"
evid "display value=$DISP xpid=$XPID"

# ── 私有 app 目录 ──────────────────────────────────────────────────────────────
rm -rf "$APP"; mkdir -p "$APP"
if [ -n "$APPDIR_SRC" ]; then
  # 反极性：拷一份**历史件**目录（只读源），**不碰**仓内权威件
  [ -d "$APPDIR_SRC" ] || fatal appdir-missing "appdir=$APPDIR_SRC"
  cp -a "$APPDIR_SRC"/. "$APP"/ 2>/dev/null
  [ -f "$APP/$PROBE_DLL" ] || cp -f "$PROBE_SRC/$PROBE_DLL" "$APP/" 2>/dev/null
  [ -f "$APP/WpfFeatureProbe.runtimeconfig.json" ] || cp -f "$PROBE_SRC/WpfFeatureProbe.runtimeconfig.json" "$APP/" 2>/dev/null
  [ -f "$APP/WpfFeatureProbe.deps.json" ] || cp -f "$PROBE_SRC/WpfFeatureProbe.deps.json" "$APP/" 2>/dev/null
  say "app dir（历史件拷贝）=$APP src=$APPDIR_SRC"
else
  cp -r "$PROBE_SRC"/. "$APP"/ 2>/dev/null
  # 五件权威件同步（仓内件，带逐件回读断言；失败 ⇒ NOINFO）
  if ! bash "$ROOT/build/MilBridge/tools/sync-applocal.sh" --mkdir --no-manifest "$APP" > "$OUT/sync.log" 2>&1; then
    tail -8 "$OUT/sync.log" | sed 's/^/  /' >> "$OUT/device.log"
    fatal applocal-sync-failed "见 $OUT/sync.log（量到的会是旧产物 ⇒ 读数不可归因）"
  fi
  say "app dir=$APP（五件已按权威件同步）"
fi
[ -f "$APP/$PROBE_DLL" ] || fatal probe-missing-app "$APP/$PROBE_DLL"

evid "art probe=$(sha16 "$APP/$PROBE_DLL") win32shim=$(sha16 "$APP/libwpfwin32.so") pc=$(sha16 "$APP/PresentationCore.dll") pf=$(sha16 "$APP/PresentationFramework.dll") wb=$(sha16 "$APP/WindowsBase.dll") bridge=$(sha16 "$APP/wpfgfx_cor3.so") wic=$(sha16 "$APP/libwpfwic.so")"
say "APP_ART win32shim=$(sha16 "$APP/libwpfwin32.so") pc=$(sha16 "$APP/PresentationCore.dll") pf=$(sha16 "$APP/PresentationFramework.dll") wb=$(sha16 "$APP/WindowsBase.dll") bridge=$(sha16 "$APP/wpfgfx_cor3.so")"

# ═══ 1. 起应用 ＋ 找窗口 ══════════════════════════════════════════════════════
( cd "$APP" && exec env WPF_WIN32_MSG_TRACE=1 dotnet "$PROBE_DLL" --only=clickprobe --late-ms="$LATE_MS" > "$APPLOG" 2>&1 ) & APID=$!
say "app pid=$APID（--only=clickprobe --late-ms=$LATE_MS）"
WID=""
for _ in $(seq 1 $((WAIT_WIN * 2))); do
  sleep 0.5
  WID="$(xdotool search --onlyvisible --name 'WpfFeatureProbe' 2>/dev/null | head -1)"
  [ -n "$WID" ] && break
  kill -0 "$APID" 2>/dev/null || break
done
[ -n "$WID" ] || { tail -12 "$APPLOG" | sed 's/^/  | /' >> "$OUT/device.log"; fatal window-absent "pid=$APID alive=$(kill -0 "$APID" 2>/dev/null && echo yes || echo no)"; }
eval "$(xdotool getwindowgeometry --shell "$WID" 2>/dev/null)"
[ -n "${WIDTH:-}" ] && [ -n "${HEIGHT:-}" ] || fatal window-geometry "xdotool getwindowgeometry 取不到几何"
[ "$WIDTH" -ge 300 ] && [ "$HEIGHT" -ge 200 ] || fatal window-too-small "${WIDTH}x${HEIGHT}"
say "WINDOW id=$WID X=$X Y=$Y ${WIDTH}x${HEIGHT}"
evid "win id=$WID x=$X y=$Y w=$WIDTH h=$HEIGHT"

# 等 `LateVerify` 自报坐标（`STATE clickprobe` 是它最后一批 POS 之后的锚）
for _ in $(seq 1 60); do grep -aq '^STATE clickprobe' "$APPLOG" && break; sleep 0.5; done
grep -aq '^STATE clickprobe' "$APPLOG" || fatal no-state-line "窗口来了但块没自报 STATE（app 可能中途死）"
sleep 1.5

for t in lst tb combo lstitem1; do
  line="$(grep -a "^POS $t relx=" "$APPLOG" | tail -1)"
  [ -n "$line" ] || fatal pos-missing "缺 POS $t（装置无法瞄准）"
  evid "pos tag=$t $(printf '%s' "$line" | sed 's/^POS [^ ]* //')"
done
pe() { printf '%s' "$1" | field "$2"; }
POS_L="$(grep -a '^POS lst relx=' "$APPLOG" | tail -1)"
LSTX="$(pe "$POS_L" relx)"; LSTY="$(pe "$POS_L" rely)"
LSTW="$(pe "$POS_L" w)";   LSTH="$(pe "$POS_L" h)"
TB_L="$(grep -a '^POS tb relx=' "$APPLOG" | tail -1)"
TBX="$(pe "$TB_L" relx)"; TBY="$(pe "$TB_L" rely)"; TBW="$(pe "$TB_L" w)"; TBH="$(pe "$TB_L" h)"
CB_L="$(grep -a '^POS combo relx=' "$APPLOG" | tail -1)"
CBX="$(pe "$CB_L" relx)"; CBY="$(pe "$CB_L" rely)"; CBW="$(pe "$CB_L" w)"; CBH="$(pe "$CB_L" h)"
LI_L="$(grep -a '^POS lstitem1 relx=' "$APPLOG" | tail -1)"
LIX="$(pe "$LI_L" relx)"; LIY="$(pe "$LI_L" rely)"; LIW="$(pe "$LI_L" w)"; LIH="$(pe "$LI_L" h)"
for v in "$LSTX" "$LSTY" "$LSTW" "$TBX" "$TBY" "$CBX" "$CBY" "$LIX" "$LIY"; do
  case "$v" in ''|*[!0-9-]*) fatal pos-unparsable "POS 字段取不到数（值=$v）" ;; esac
done
[ "$LSTW" -gt 0 ] && [ "$TBW" -gt 0 ] && [ "$CBW" -gt 0 ] && [ "$LIW" -gt 0 ] || fatal pos-zero-size "控件 w/h 为 0（D-G50 首版形态）⇒ 点击无处可落"

# 屏幕坐标换算（relx 相对可视树根 ⇒ 加窗口原点）
sx() { echo $(( X + $1 )); }
sy() { echo $(( Y + $1 )); }
ctr() { echo $(( $1 + $2 / 2 )); }   # ctr <relx> <w>
in_win() { [ "$1" -ge "$X" ] && [ "$1" -lt $(( X + WIDTH )) ] && [ "$2" -ge "$Y" ] && [ "$2" -lt $(( Y + HEIGHT )) ]; }
in_rect() { # in_rect x y rx ry rw rh（带 4px 余量）
  [ "$1" -ge $(( $3 - 4 )) ] && [ "$1" -lt $(( $3 + $5 + 4 )) ] && [ "$2" -ge $(( $4 - 4 )) ] && [ "$2" -lt $(( $4 + $6 + 4 )) ]
}

# ── 空白点（卡片内、三个控件之外）：候选逐个试，都不行 ⇒ NOINFO（**不许**瞎点当"反极性"）──
BLANK_X=""; BLANK_Y=""; ROW_Y=""
for cand in "$(( LSTX + LSTW + 80 ))" "$(( LSTX - 60 ))" "$(( WIDTH - 25 ))"; do
  cx="$(sx "$cand")"
  for row in "$(( LSTY + LSTH / 2 ))" "$(( TBY + TBH / 2 ))"; do
    cy="$(sy "$row")"
    in_win "$cx" "$cy" || continue
    in_rect "$cx" "$cy" "$(sx "$LSTX")" "$(sy "$LSTY")" "$LSTW" "$LSTH" && continue
    in_rect "$cx" "$cy" "$(sx "$TBX")" "$(sy "$TBY")" "$TBW" "$TBH" && continue
    in_rect "$cx" "$cy" "$(sx "$CBX")" "$(sy "$CBY")" "$CBW" "$CBH" && continue
    BLANK_X="$cx"; BLANK_Y="$cy"; ROW_Y="$row"; break
  done
  [ -n "$BLANK_X" ] && break
done
[ -n "$BLANK_X" ] || fatal no-blank-point "窗口 ${WIDTH}x${HEIGHT} 里找不到'三控件之外'的空白点（反极性腿无处落）"
say "blank point=($BLANK_X,$BLANK_Y)（控件之外、窗口之内）"
evid "blank x=$BLANK_X y=$BLANK_Y"

# ── 仪器级反极性（**可选**）：窗口挪走 ⇒ 上面算出来的坐标全部失效 ─────────────────
#   ⚠️ 位置**必须在这里**（所有 POS/几何都取完之后、第一条腿之前）：
#     早一步 ⇒ 挪窗会被记进坐标读数；晚一步 ⇒ 它什么也破坏不了（那就成了假的反极性）。
#   ⚠️ 挪完**不重取几何**（重取就等于把破坏撤销了）：判据件会看到 `sabotage kind=windowmove`
#     而 `down_delta=0`/逐格缺失 ⇒ `FAIL`。**若它仍 `PASS` ⇒ 判 `sabotage-not-caught`（装置没判别力）**。
if [ "$SABOTAGE" = "windowmove" ]; then
  xdotool windowmove "$WID" $(( X + 300 )) $(( Y + 250 )) > /dev/null 2>&1
  sleep 1.0
  say "  SABOTAGE windowmove：窗口 ${X},${Y} → $(( X + 300 )),$(( Y + 250 ))（坐标保持**旧值**，点击因此落空）"
fi

# ═══ 2. 腿 ════════════════════════════════════════════════════════════════════
click_at() {   # 真实节奏：移入 → 停 450 ms → 按下 → 停 150 ms → 抬起
  xdotool mousemove "$1" "$2" > /dev/null 2>&1; sleep 0.45
  xdotool mousedown 1 > /dev/null 2>&1; sleep 0.15
  xdotool mouseup 1 > /dev/null 2>&1
}
nudge() {      # mouse-up **之后**在卡片内挪 2 px：让 `EVT move … captured=` 落进本次点击的切片（判据⑥）
  local nx=$(( $1 + 2 )) ny="$2"
  in_win "$nx" "$ny" || { nx=$(( $1 - 2 )); }
  in_win "$nx" "$ny" && { xdotool mousemove "$nx" "$ny" > /dev/null 2>&1; return 0; }
  xdotool mousemove "$BLANK_X" "$BLANK_Y" > /dev/null 2>&1
}
step_click() { # step_click <id> <x> <y>
  local id="$1" x="$2" y="$3" f0 f1 d0 d1 u0 u1 ins=0
  f0="$(alines)"; d0="$(msgcount 0x0201)"; u0="$(msgcount 0x0202)"
  click_at "$x" "$y"; nudge "$x" "$y"; sleep 1.2
  f1="$(alines)"; d1="$(msgcount 0x0201)"; u1="$(msgcount 0x0202)"
  in_win "$x" "$y" && ins=1
  evid "step id=$id kind=click x=$x y=$y inside=$ins appline_from=$f0 appline_to=$f1 down_delta=$(( d1 - d0 )) up_delta=$(( u1 - u0 ))"
  say "  $id click=($x,$y) inside=$ins lines=$f0→$f1 down+$(( d1 - d0 )) up+$(( u1 - u0 ))"
}
step_type() { # step_type <id> <text>
  local id="$1" txt="$2" f0 f1 d0 d1 c0 c1 cur
  f0="$(alines)"; d0="$(msgcount 0x0100)"; c0="$(msgcount 0x0102)"
  cur="$(xdotool getwindowfocus 2>/dev/null || true)"
  [ "$cur" = "$WID" ] || xdotool windowfocus --sync "$WID" > /dev/null 2>&1
  xdotool type --delay 120 "$txt" > /dev/null 2>&1
  sleep 1.0
  f1="$(alines)"; d1="$(msgcount 0x0100)"; c1="$(msgcount 0x0102)"
  evid "step id=$id kind=type chars=${#txt} appline_from=$f0 appline_to=$f1 keydown_delta=$(( d1 - d0 )) char_delta=$(( c1 - c0 ))"
  say "  $id type=$txt lines=$f0→$f1 keydown+$(( d1 - d0 )) char+$(( c1 - c0 ))"
}
wins() { xwininfo -root -tree 2>/dev/null | grep -oE '^ +0x[0-9a-f]+' | tr -d ' ' | sort -u; }
popup_probe() { # popup_probe <id> <baseline-window-list>
  local id="$1" w0="$2" w1 now map geom
  # ⚠️ 基线**必须先规整成"空格分隔、两端带空格"**再比：`wins()` 是**换行**分隔的，而
  #    `case " $w0 " in *" $now "*)` 只对**首/末行**成立 ⇒ 中间那些窗口会被误报成"新窗口"
  #    （本件第一版实测：主窗口 `0x200005` 与 4 个**未映射**的 WPF helper 窗口都被当成"下拉弹窗"）。
  local w0n; w0n=" $(printf '%s' "$w0" | tr '\n' ' ') "
  w1="$(wins)"
  for now in $w1; do
    case "$w0n" in *" $now "*) continue ;; esac
    map="$(xwininfo -id "$now" 2>/dev/null | awk -F: '/Map State/{gsub(/^ +/,"",$2); print $2}')"
    geom="$(xwininfo -id "$now" 2>/dev/null | awk -F: '/Absolute upper-left X/{gx=$2} /Absolute upper-left Y/{gy=$2} /^  Width/{gw=$2} /^  Height/{gh=$2} END{gsub(/ /,"",gx);gsub(/ /,"",gy);gsub(/ /,"",gw);gsub(/ /,"",gh); printf "%s %s %s %s", gx, gy, gw, gh}')"
    set -- $geom
    evid "popup id=$id win=$now map=${map:-UNKNOWN} x=${1:-?} y=${2:-?} w=${3:-?} h=${4:-?}"
    say "  popup $now map=${map:-?} geom=${1:-?},${2:-?} ${3:-?}x${4:-?}"
  done
}
pick_popup() { # pick_popup <id> ⇒ 印**最后一条**"IsViewable ＋ 非主窗口 ＋ 尺寸像下拉"的记录（空 = 没有）
  #   ⚠️ 必须**排除主窗口**：主窗口也是 IsViewable ⇒ 早先那版"取第一条 IsViewable 的新窗口"
  #      取到的是主窗口（938x938）⇒ 用它的原点去点弹窗项会点错地方（本件第一版实测）。
  grep -a "^EVID popup id=$1 " "$OUT/evidence.txt" 2>/dev/null | awk -v main="$WID" '
    { m=""; w=""; h=0
      for (i=1; i<=NF; i++) {
        if ($i ~ /^map=/) m = substr($i, 5)
        if ($i ~ /^win=/) w = substr($i, 5)
        if ($i ~ /^h=/)   h = substr($i, 3) + 0
      }
      if (m == "IsViewable" && w != main && h > 20 && h <= 400) last = $0
    }
    END { if (last != "") print last }'
}
pixels() {     # pixels <id>：整屏（私有 display ⇒ 只有本应用）测试色 22D3EE 的像素数
  local id="$1" n
  n="$(xwd -root -silent 2>/dev/null | convert xwd:- png:- 2>/dev/null \
       | convert - -format %c histogram:info:- 2>/dev/null \
       | grep -i '22D3EE' | awk '{s+=$1} END{print s+0}')"
  evid "pixels id=$id value=${n:-0}"
  say "  pixels $id = ${n:-0}"
}

# 初始 X 输入焦点给窗口（**不是点击**；放在 L0 之前 ⇒ 激活引起的焦点变化不落进 L0 切片）
xdotool windowfocus --sync "$WID" > /dev/null 2>&1; sleep 0.8
say "── 0) 像素基线（下拉还没开过）"
pixels closed_before

say "── L0 未点击就键入（判据③反极性）"
step_type L0_type_nofocus "xyz"

say "── L1 点窗口外（判据②反极性）"
step_click L1_outside $(( X - 60 )) $(( Y - 40 ))

say "── L2 点卡片右侧空白（判据①反极性）"
step_click L2_blank "$BLANK_X" "$BLANK_Y"

say "── L3 点 ListBox item1（判据①正向）"
step_click L3_lst1 "$(sx "$(ctr "$LIX" "$LIW")")" "$(sy "$(ctr "$LIY" "$LIH")")"

say "── L4 点 TextBox（判据②正向）"
step_click L4_tb "$(sx "$(ctr "$TBX" "$TBW")")" "$(sy "$(ctr "$TBY" "$TBH")")"

say "── L5 键入 abc（判据③正向）"
step_type L5_type_abc "abc"

say "── L6 点 ComboBox（判据④正向）"
W0="$(wins)"
step_click L6_combo "$(sx "$(ctr "$CBX" "$CBW")")" "$(sy "$(ctr "$CBY" "$CBH")")"
popup_probe L6_combo "$W0"
pixels open
grep -a '^POS comboitem1 relx=' "$APPLOG" | tail -1 > "$OUT/.ci1"
if [ -s "$OUT/.ci1" ]; then
  evid "pos tag=comboitem1 $(sed 's/^POS [^ ]* //' "$OUT/.ci1")"
else
  evid "pos tag=comboitem1 MISSING"
fi

say "── L7 下拉开着时点下拉外空白（判据④反极性）"
step_click L7_combo_blank "$BLANK_X" "$(( Y + $(ctr "$CBY" "$CBH") ))"

say "── L6b 重开下拉 ＋ L8 点弹窗 item1（判据⑤正向）"
W0="$(wins)"
step_click L6b_combo_reopen "$(sx "$(ctr "$CBX" "$CBW")")" "$(sy "$(ctr "$CBY" "$CBH")")"
popup_probe L6b_combo_reopen "$W0"

PW=""; PWD_="$(pick_popup L6b_combo_reopen)"
[ -n "$PWD_" ] && PW="$(printf '%s' "$PWD_" | field win)"
if [ -n "$PW" ] && [ -s "$OUT/.ci1" ]; then
  CIX="$(pe "$(cat "$OUT/.ci1")" relx)"; CIY="$(pe "$(cat "$OUT/.ci1")" rely)"
  CIW="$(pe "$(cat "$OUT/.ci1")" w)";   CIH="$(pe "$(cat "$OUT/.ci1")" h)"
  PX0="$(kv "$PWD_" x)"; PY0="$(kv "$PWD_" y)"
  if [ -n "$CIX" ] && [ -n "$PX0" ] && [ "$PX0" != "?" ]; then
    step_click L8_comboitem1 $(( PX0 + CIX + CIW / 2 )) $(( PY0 + CIY + CIH / 2 ))
  else
    evid "step id=L8_comboitem1 kind=skipped reason=popup-origin-unparsable"
    say "  L8 跳过：弹窗原点/项坐标取不到"
  fi
else
  evid "step id=L8_comboitem1 kind=skipped reason=no-popup-window-or-no-comboitem1"
  say "  L8 跳过：没有新 X 窗口或缺 POS comboitem1（判据⑤将由裁决件判红）"
fi

say "── SEQ 连续三下（判据⑦承重；指针全程在窗口内）"
step_click SEQ_lst0  "$(sx "$(ctr "$LSTX" "$LSTW")")" "$(sy "$(( LSTY + 12 ))")"
step_click SEQ_tb    "$(sx "$(ctr "$TBX" "$TBW")")"   "$(sy "$(ctr "$TBY" "$TBH")")"
step_click SEQ_combo "$(sx "$(ctr "$CBX" "$CBW")")"   "$(sy "$(ctr "$CBY" "$CBH")")"

# ═══ 3. 收尾证据 ══════════════════════════════════════════════════════════════
STATE_LINE="$(grep -a '^STATE clickprobe' "$APPLOG" | tail -1)"
evid "state value=${STATE_LINE:-MISSING}"
alive=no; kill -0 "$APID" 2>/dev/null && alive=yes
evid "appalive value=$alive"
evid "counts wm_lbuttondown=$(msgcount 0x0201) wm_lbuttonup=$(msgcount 0x0202) wm_keydown=$(msgcount 0x0100) wm_char=$(msgcount 0x0102)"
evid "applog lines=$(alines) path=$APPLOG"
grep -aci 'unhandled exception\|SIGSEGV\|Aborted' "$APPLOG" > "$OUT/.exc" 2>/dev/null || true
evid "exceptions count=$(cat "$OUT/.exc" 2>/dev/null || echo 0)"

# sabotage 已在腿开跑前生效（见上）；此处只落证据行，供裁决件读
evid "device=OK out=$OUT appdir=$APP display=$DISP"
say "R_GATE_DEVICE=OK out=$OUT"
say "  证据：$OUT/evidence.txt｜应用日志：$APPLOG"
cleanup
exit 0
