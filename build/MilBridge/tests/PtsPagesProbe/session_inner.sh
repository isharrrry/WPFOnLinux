#!/usr/bin/env bash
# W156A w67guard 槽内脚本：多臂 × 多点点击，逐腿落机读行。
#   用法: session_inner.sh <tag> <arm:clicks> [<arm:clicks> ...]
#         臂 ∈ {A, B, C}：A=正常树（现权威五件）｜B=修前成对件（必红 rc=134）｜C=只撤画占位（必红 洋红 0）
#   ⚠️ 必须在 heavy-slot.sh 之内跑。
set -uo pipefail
# ⚠️【落仓参数化（纪律 34）】原值 `W=` **某外来车道工作目录的硬编码路径**（字面不复写，
#   否则纪律 34 的 `grep -E '$HOME/w1[0-9]+a'` 会把**注释本身**算成残留 —— 本器实测踩过）。
#   现在：`W67_WORK` 可覆盖；默认落在**仓外私有暂存**（`$HOME/w67-work`）——
#   **绝不**默认写进 `$R`（证据目录只放 `leg_*.env`／`device.txt` 这类小件）。
#   ⚠️ `BIN` **不能**指向 `$W/bin`（那是外来车道的布局）：它要用 `navclick.py`／`shotstat.py`，
#     而这两件**随装置一起落仓**在**装置自己的目录**里 ⇒ `BIN` = 本脚本所在目录（自足，无外来依赖）。
W="${W67_WORK:-$HOME/w67-work}"; DLLS="$W/dlls"; APPDIR="$W/app"
SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN="${W67_BIN:-$SELF_DIR}"
TAG="${1:?tag}"; shift
[ $# -gt 0 ] || { echo "need >=1 group" >&2; exit 2; }
# ── ⏪ `t159`：**工具换代**（会话端）—— 与 runner 侧 `LEGS_TOOLS` 同形；本行＝**新增行**（既有输出一字不动）──
#   口径：`sha16` 取**本趟实际被执行的这一份**会话件（`${BASH_SOURCE[0]}`），**不是**"打包时"的值；
#   `runner_sha16` 由 runner 经 `W67_RUNNER_SHA16` 下传（缺 ⇒ `none`，绝不猜）。放在**前置之前** ⇒ 拒跑趟也带此行。
_SESSION_SHA16="$(sha256sum "${BASH_SOURCE[0]}" 2>/dev/null | cut -c1-16)"
_SESSION_MTIME_EPOCH="$(stat -c %Y "${BASH_SOURCE[0]}" 2>/dev/null || echo 0)"
echo "SESSION_TOOLS session_sha16=${_SESSION_SHA16:-none} session_mtime_epoch=${_SESSION_MTIME_EPOCH:-0} runner_sha16=${W67_RUNNER_SHA16:-none}" >&2
D="${W67_DISPLAY:-:237}"
# ⏪【`t14`／W2·B-9，读时 2026-09-28T16:02:39+0800】默认显示号**占用探测**（`D-G139` 同族：长跑自起的显示位必须按 PID 收净；**不许静默复用别人的号**）
# ⏪【`t68`，读时 2026-09-28T20:54:02.855+0800】**修装置互斥 ＋ 占位保护名义化**（`D-G188`）。上一条判据的**原文逐字保留**在下面（一字未删），
#   新判据在它之上加两条：① **官方调用者自有显示位（lease）放行** —— 否则本脚本会被**自己的调用者**拒死
#   （`run-pts-pages-legs.sh` 起 `Xvfb :237` ⇒ 本闸判占用 ⇒ `PTS-PAGES` 腿路整条跑不起来）；② **`WPF_X11_DIR` 改写
#   不得静默改判** —— 该改写让「被占的号」看着空闲 ⇒ 保护名义化。
#   ── 原判据（逐字留档，不再生效）─────────────────────────────────────────────
#     XDIR="${WPF_X11_DIR:-/tmp/.X11-unix}"
#     if [ -S "$XDIR/X${D#:}" ]; then
#       echo "DISPLAY_OCCUPIED=$D sock=$XDIR/X${D#:} ⇒ 拒跑（号已被占；请用 W67_DISPLAY=<空闲号> 或先按 PID 收净）" >&2
#       exit 3
#     fi
#     echo "DISPLAY_LEASE=free display=$D sock=$XDIR/X${D#:}" >&2
#   ── 新判据 ────────────────────────────────────────────────────────────────
#   【射程句（写死）】**占用** ＝ 该号在**规范目录** `/tmp/.X11-unix` 或 `WPF_X11_DIR` 指向的目录里存在
#     `X<n>` socket，**且不是**由本脚本**祖先链上的 lease 持有者**亲手起的**活** `Xvfb` 所持有；
#     **放行** ＝ lease 五条全成立（① 常规件 ② 模式 `600` ③ `DISPLAY` 相符 ④ `OWNER_PID` 在本脚本祖先链上
#     ⑤ 活 `Xvfb` 且其 `ppid` == `OWNER_PID`）。**两边都不判「空闲」时（socket 在任一边存在）才走 lease**。
#   【防伪造】外人拿不到「你的祖先链」：`OWNER_PID` 必须是**本进程的祖先**，且那个 `Xvfb` 必须是它的**亲儿子**
#     ⇒ 另起一个 `Xvfb` 占号、或把 `WPF_X11_DIR` 指到空目录，都**不**满足。
#   【口径（`D-G188`）】可被环境变量**静默**改变判定的保护 ＝ 名义保护 ⇒ 一律 `NOINFO(reason=保护名义化)`。
# ── ⏪ `t157`（修 `D-1`：**分配结果必须与消费者同源**）──────────────────────────────────
#   病灶（`t155` 实测）：`run-pts-pages-legs.sh` 把 Xvfb 起在**它分配**的号上并写了 lease（`DISPLAY=:231`），
#     而本脚本的 `$D` 取 `W67_DISPLAY`（缺省 `:237`）；两个号不一致、而 `:237` 又**没有 socket 件**时，
#     旧形态走 `DISPLAY_LEASE=free display=:237` ⇒ 应用被喂错号 ⇒ `XOpenDisplay` 失败、`APP_RC=134`。
#   新形态（两条，逐字）：① lease 在且其 `DISPLAY` ≠ `$D` ⇒ **具名拒跑**（不猜、不静默；`exit 3`）；
#     ② `W67_DISPLAY` 未给而 lease 在 ⇒ **采用 lease 的分配结果**（单一来源；不再有 `:237` 兜底猜测）。
#   下面那段既有判据（socket 双边检查 ＋ lease 五条）**一字未动**；本块只在它**之前**把"号从哪来"收成一处。
_T157_L="${W67_DISPLAY_LEASE:-}"
if [ -n "$_T157_L" ] && [ -f "$_T157_L" ] && [ ! -L "$_T157_L" ]; then
  _T157_LD="$(sed -n 's/^DISPLAY=//p' "$_T157_L" | head -1)"
  if [ -z "${W67_DISPLAY:-}" ] && [ -n "$_T157_LD" ]; then
    # ② **采用 lease 的分配结果**（单一来源）：调用方没给号 ⇒ 用"这一次分配"的结果，不再拿 `:237` 兜底猜
    D="$_T157_LD"
    echo "DISPLAY_ADOPT display=$D from=lease（⏪ t157：消费端与分配端同源）" >&2
  elif [ -n "$_T157_LD" ] && [ "$_T157_LD" != "$D" ]; then
    # ① 调用方给了号、但与本次分配不一致 ⇒ **具名拒跑**
    echo "DISPLAY_MISMATCH=$D lease_display=$_T157_LD lease=$_T157_L" >&2
    echo "LEASE_REJECT reason=allocated-display-not-passed-through env_d=$D lease_display=$_T157_LD display=$D（⏪ t157 修 D-1：分配结果必须下传，不许两个入口各取各的）" >&2
    exit 3
  fi
fi
CANON_XDIR=/tmp/.X11-unix
XDIR_OVERRIDE="${WPF_X11_DIR:-}"
XN="${D#:}"
sock_here=no; sock_canon=no
[ -n "$XDIR_OVERRIDE" ] && [ -S "$XDIR_OVERRIDE/X$XN" ] && sock_here=yes
[ -S "$CANON_XDIR/X$XN" ] && sock_canon=yes
if [ -n "$XDIR_OVERRIDE" ] && [ "$XDIR_OVERRIDE" != "$CANON_XDIR" ]; then
  echo "WPF_X11_DIR_OVERRIDE=$XDIR_OVERRIDE（判据不改：与规范目录 $CANON_XDIR **双边**检查 ⇒ 该改写不得让被占的号看着空闲；D-G188）" >&2
fi
ancestor_has() {  # $1=pid ⇒ 该 pid 是否在本脚本**祖先链**上（含 `$$`）
  local pid=$$ p
  while [ -n "$pid" ] && [ "$pid" != 0 ] && [ "$pid" != 1 ]; do
    [ "$pid" = "$1" ] && return 0
    [ -r "/proc/$pid/stat" ] || return 1
    p="$(sed 's/^.*) //' "/proc/$pid/stat" 2>/dev/null | awk '{print $2}')"
    [ -n "$p" ] || return 1
    [ "$p" = "$pid" ] && return 1
    pid="$p"
  done
  return 1
}
lease_ok=0; lease_reason=none; L="${W67_DISPLAY_LEASE:-}"; l_xpid=''; l_owner=''
if [ "$sock_here" = yes ] || [ "$sock_canon" = yes ]; then
  if [ -z "$L" ]; then lease_reason=no-lease
  elif [ ! -f "$L" ] || [ -L "$L" ]; then lease_reason=lease-not-regular
  elif [ "$(stat -c %a "$L" 2>/dev/null)" != 600 ]; then lease_reason=lease-mode-not-600
  else
    l_disp="$(sed -n 's/^DISPLAY=//p' "$L" | head -1)"
    l_owner="$(sed -n 's/^OWNER_PID=//p' "$L" | head -1)"
    l_xpid="$(sed -n 's/^XVFB_PID=//p' "$L" | head -1)"
    if [ "$l_disp" != "$D" ]; then lease_reason=lease-display-mismatch
    elif [ -z "$l_owner" ] || [ -z "$l_xpid" ]; then lease_reason=lease-incomplete
    elif ! ancestor_has "$l_owner"; then lease_reason=lease-owner-not-ancestor
    elif ! kill -0 "$l_xpid" 2>/dev/null; then lease_reason=lease-xvfb-dead
    else
      xcl="$(tr '\0' ' ' < "/proc/$l_xpid/cmdline" 2>/dev/null || true)"
      xpp="$(sed 's/^.*) //' "/proc/$l_xpid/stat" 2>/dev/null | awk '{print $2}')"
      case "$xcl" in
        *Xvfb*"$D"*) if [ "$xpp" = "$l_owner" ]; then lease_ok=1; else lease_reason=lease-xvfb-not-child-of-owner; fi ;;
        *) lease_reason=lease-xvfb-cmdline-mismatch ;;
      esac
    fi
  fi
fi
if [ "$sock_here" = no ] && [ "$sock_canon" = no ]; then
  echo "DISPLAY_LEASE=free display=$D sock=$CANON_XDIR/X$XN" >&2
elif [ "$lease_ok" = 1 ]; then
  echo "DISPLAY_LEASE=official-caller-owned display=$D sock=$CANON_XDIR/X$XN xvfb_pid=$l_xpid owner_pid=$l_owner lease=$L（① 常规件 ② 模式 600 ③ DISPLAY 相符 ④ owner 在祖先链上 ⑤ 活 Xvfb 且是其亲儿子 ⇒ 放行）" >&2
else
  echo "DISPLAY_OCCUPIED=$D sock=$CANON_XDIR/X$XN ⇒ 拒跑（号已被占；请用 W67_DISPLAY=<空闲号> 或先按 PID 收净）" >&2
  echo "LEASE_REJECT reason=$lease_reason lease=${L:-<未给>} display=$D（外人不放行：无 lease／伪造／过期／非祖先链／Xvfb 非其亲生 ⇒ 一律拒）" >&2
  exit 3
fi
export PATH="$HOME/.dotnet:$PATH"; export DOTNET_gcServer=0
OUT="$W/logs/$TAG"; SHOTS="$OUT/shots"; mkdir -p "$OUT" "$SHOTS"

expect_of() { case "$1" in
  0) echo BrushDemo;; 9) echo NativeTextBoxDemo;; 10) echo NativeComboBoxDemo;;
  16) echo NativeTabControlDemo;; 23) echo RichTextBoxDemo;; 24) echo FlowDocumentDemo;;
  *) echo '';; esac; }

five() { for f in libwpfwin32.so wpfgfx_cor3.so PresentationCore.dll PresentationFramework.dll WindowsBase.dll; do
          printf '%s=%s\n' "$f" "$(sha256sum "$APPDIR/$f" | cut -c1-16)"; done; }

cnt() { # cnt <正则> <文件> —— 返回**单个 token** 的命中条数（杜绝 `grep -c || echo 0` 在零命中时输出两行）
  local n; n="$(grep -c -E "$1" "$2" 2>/dev/null || true)"
  n="${n//[$'\n\r']/}"; printf '%s' "${n:-0}"; }
firstline() { local f="$1" pat="$2" out rc
  out="$(grep -n -m1 -E "$pat" "$f" 2>/dev/null)"; rc=$?
  case "$rc" in 0) printf '%s' "${out%%:*}";; 1) printf '%s' '-';;
    *) printf 'READER-ERR(rc=%s)' "$rc";; esac; }
firstline_re() { local f="$1" pat="$2" out rc
  out="$(grep -m1 -E "$pat" "$f" 2>/dev/null)"; rc=$?
  [ "$rc" -le 1 ] || { printf 'READER-ERR(rc=%s)' "$rc"; return; }
  printf '%s' "${out:0:220}"; }
# 承重：托管侧具名行里的 err= 必须非零（防 FAKEOK 伪造 err=0）
unavail_err() { grep -o -m1 'PTS-UNAVAILABLE.*err=[-0-9]*' "$1" 2>/dev/null | grep -o 'err=[-0-9]*' | head -1; }

gi=0
for GROUP in "$@"; do
  gi=$((gi+1))
  ARM="${GROUP%%:*}"; KS="${GROUP#*:}"
  # ── `t52` 修装配口径（**根因就在这一行**）─────────────────────────────────────
  #   A 臂的语义是"**现权威五件**"，而 `$DLLS/A.*` 是 `~/w160a/stage-arms.sh` 在
  #   **2026-09-24 20:30** 落的那一份快照 ⇒ 原来这一行会把 `~/w67-work/app` 里
  #   `sync-applocal.sh` 刚灌好的现件**就地覆盖回旧代**（实测：跑前 `shim=6825dd7071387a46`
  #   ⇒ 跑后 `shim=fc60c34d51fd9247`）⇒ 腿跑的不是当前构建（`t12` 的阻塞）。
  #   ⇒ A 臂改取**仓内权威路径**；B/C 臂（反极性臂）仍按 `$DLLS` 取（它们本来就该是别的件）。
  #   `PTS_GUARD_ARM_FROM_DLLS=1` 可强制回旧行为 ⇒ 给硬闸造反极性腿用。
  R_REPO="${PTS_GUARD_REPO:-$(cd -- "$SELF_DIR/../../../.." && pwd)}"
  if [ "$ARM" = A ] && [ "${PTS_GUARD_ARM_FROM_DLLS:-0}" != 1 ]; then
    SHIM="$R_REPO/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
    PF="$R_REPO/build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll"
  else
    SHIM="$DLLS/$ARM.libwpfwin32.so"; PF="$DLLS/$ARM.PresentationFramework.dll"
  fi
  [ -f "$SHIM" ] || { echo "G$gi MISSING-SHIM $SHIM"; continue; }
  [ -f "$PF" ]   || { echo "G$gi MISSING-PF $PF"; continue; }
  cp -a "$SHIM" "$APPDIR/libwpfwin32.so"; cp -a "$PF" "$APPDIR/PresentationFramework.dll"
  GLOG="$OUT/app_g$gi.log"; GSHOTS="$SHOTS/g$gi"; mkdir -p "$GSHOTS"
  echo "=============== GROUP $gi arm=$ARM clicks=[$KS] $(date '+%T') ==============="
  echo "shim_sha16=$(sha256sum "$SHIM" | cut -c1-16) pf_sha16=$(sha256sum "$PF" | cut -c1-16)"
  five > "$OUT/five_pre_g$gi.txt"; echo "five_pre: $(tr '\n' ' ' < "$OUT/five_pre_g$gi.txt")"
  echo "mem_avail_kB_start=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)"
  cd "$APPDIR" || exit 2
  ( exec timeout "${W67_TMO:-200}" env DISPLAY="$D" HC_NO_SPLASH=1 HC_INPUT_DIAG=1 HC_GEO_EVERY=1 \
      HC_DUMP_MAX=100000 dotnet HandyControlDemo.dll ) > "$GLOG" 2>&1 &
  APP=$!
  echo "app_pid=$APP timeout=${W67_TMO:-200}s"
  sleep 8
  echo "boot_log_bytes=$(stat -c%s "$GLOG" 2>/dev/null || echo 0)"
  import -display "$D" -window root "$GSHOTS/boot.png" 2>/dev/null
  cp -f "$GSHOTS/boot.png" "$GSHOTS/last.png"
  python3 "$BIN/shotstat.py" "$GSHOTS/boot.png" | sed 's/^/  boot  /'
  echo "boot_alive=$(kill -0 "$APP" 2>/dev/null && echo yes || echo no)"
  for k in $(echo "$KS" | tr ',' ' '); do
    echo "--- G$gi click $k  $(date '+%T') ---"
    EXP="$(expect_of "$k")"
    timeout 200 python3 "$BIN/navclick.py" --log "$GLOG" --pid "$APP" --display "$D" \
        --out "$GSHOTS" --item "$k" --expect "$EXP" || echo "  navclick_rc=$?"
    alive=$(kill -0 "$APP" 2>/dev/null && echo yes || echo no)
    import -display "$D" -window root "$GSHOTS/k$k.png" 2>/dev/null
    python3 "$BIN/shotstat.py" "$GSHOTS/k$k.png" | sed "s/^/  /"
    AE=$(python3 - "$GSHOTS/last.png" "$GSHOTS/k$k.png" <<'PY'
import subprocess, sys
r = subprocess.run(['compare','-metric','AE',sys.argv[1],sys.argv[2],'null:'],capture_output=True,text=True)
o = ((r.stderr or '') + (r.stdout or '')).strip().split()
print(o[0] if o else 'NA')
PY
)
    cp -f "$GSHOTS/k$k.png" "$GSHOTS/last.png"
    printf 'CLICK k=%s alive=%s expect=%s AE=%s pts_unavail=%s pts_gap=%s guard=%s fatal=%s unh=%s ns_last=%s\n' \
      "$k" "$alive" "$EXP" "$AE" \
      "$(cnt "PTS-UNAVAILABLE" "$GLOG")" \
      "$(cnt "PTS_GAP" "$GLOG")" \
      "$(cnt "\[HC-UNHANDLED\]" "$GLOG")" \
      "$(cnt "Unrecoverable system error" "$GLOG")" \
      "$(cnt "Unhandled exception" "$GLOG")" \
      "$(grep -o '\[NS\] loaded [^ ]*' "$GLOG" 2>/dev/null | tail -1 | awk '{print $3}')"
    # ⏪ `t116`（`t115` 的 `F-1`）**「位点不再执行」的直接读数**：新增一行**机读** `FAILLINE`（**既有 `CLICK`／`PHASE` 行一字未动**）。
    #   **口径（逐字）**：`failfast=` ＝ 原始 app 日志（`$GLOG`）里 `FailFast` 字样的**行数**（.NET `Environment.FailFast`
    #   的失败位点标记）；`unrec=` ＝ 同日志里 `Unrecoverable system error` 的**行数**（**与既有 `fatal=` 同源同量**
    #   ⇒ 两者**逐字等价**，保留 `fatal=` 只为不破坏既有读法）。⇒ 判「`FailFast` 位点这次有没有执行」**看这一行**（`… failfast=0`）；
    #   `alive=yes`／`ink>0`／崩溃栈消失**只是辅证**，**不得**再冒充"直接读数"。
    #   位置：落在 `CLICK` 与 `PHASE` 之间 ⇒ 转换器 `legs-to-env.py` 的既有 region token 扫描**自动带走**（不新增解析器）。
    printf 'FAILLINE k=%s failfast=%s unrec=%s src=%s\n' \
      "$k" "$(cnt "FailFast" "$GLOG")" "$(cnt "Unrecoverable system error" "$GLOG")" \
      "app_g$gi.log:FailFast|Unrecoverable"
    # ⏪ `t124`（`t118` 的 `N1`）**帧身份 ＋ 帧位移的机读格**（**既有 `CLICK`／`FAILLINE`／`PHASE` 行一字未动**）。
    #   **口径（逐字）**：
    #     · `fr_file=` ＝ 本腿截图的**文件名**（`k<k>.png`）；截图没落 ⇒ `-`。
    #     · `fr_sha=`  ＝ 该文件的 `sha256sum` **前 16 位**（与 `five()`／`shim_sha16=` **同一算口径**）；读不到 ⇒ `-`。
    #     · `fr_lsha=` ＝ **同一时刻** `last.png` 的前 16 位。本装置在该点之前刚做过 `cp -f k$k.png last.png`
    #       ⇒ 二者**逐字相同**是**装配不变量**；不同即**装置异常**（如实印出、不掩盖）。
    #     · `fr_ae_boot=` ＝ `compare -metric AE boot.png k$k.png`（**该帧相对 `boot` 的像素位移**，整数）；算不出 ⇒ `-`。
    #   **为何是这一对**：`N1` 的两要件 ＝「帧身份」（`fr_sha` ∉ 已登记空态参照集）＋「帧位移」（`fr_ae_boot>0`）；
    #     单看 `ink>0`／`alive=yes` **证不出**"这一帧不是那张空态回退画面"（`t119` 的现场：两页停在同一回退画面）。
    #   **`-` 的语义** ＝ **没测到**（不是 0、不是绿）；键名**不含数字**（转换器 region 扫描的键词法是 `[A-Za-z_]+`）。
    #   位置：落在 `CLICK` 与 `PHASE` 之间 ⇒ 转换器 `legs-to-env.py` 的既有 region token 扫描**自动带走**（不新增解析器）。
    _fr_sha="$(sha256sum "$GSHOTS/k$k.png" 2>/dev/null | cut -c1-16)"
    _fr_lsha="$(sha256sum "$GSHOTS/last.png" 2>/dev/null | cut -c1-16)"
    _fr_ae="$(python3 - "$GSHOTS/boot.png" "$GSHOTS/k$k.png" <<'PY'
import subprocess, sys
r = subprocess.run(['compare','-metric','AE',sys.argv[1],sys.argv[2],'null:'],capture_output=True,text=True)
o = ((r.stderr or '') + (r.stdout or '')).strip().split()
print(o[0] if o else 'NA')
PY
)"
    [ -n "${_fr_sha:-}" ] || _fr_sha='-'
    [ -n "${_fr_lsha:-}" ] || _fr_lsha='-'
    case "${_fr_ae:-}" in ''|*[!0-9]*) _fr_ae='-';; esac
    [ -f "$GSHOTS/k$k.png" ] || _fr_sha='-'
    [ -f "$GSHOTS/last.png" ] || _fr_lsha='-'
    printf 'FRAME k=%s fr_file=%s fr_sha=%s fr_lsha=%s fr_ae_boot=%s\n' \
      "$k" "$([ -f "$GSHOTS/k$k.png" ] && printf 'k%s.png' "$k" || printf '-')" \
      "$_fr_sha" "$_fr_lsha" "$_fr_ae"
    n1="$(firstline "$GLOG" "EntryPointNotFoundException: Unable to find an entry point named 'CreateInstalledObjectsInfo'")"
    n2="$(firstline "$GLOG" "PTS_GAP entry=")"
    n3="$(firstline "$GLOG" "\[PTS-UNAVAILABLE\] site=")"
    n4="$(firstline "$GLOG" "Unrecoverable system error")"
    printf 'PHASE k=%s c1_ep=%s c2_pts_gap=%s c3_pts_unavail=%s c4_unrecoverable=%s managed_err=%s native_err=%s\n' \
      "$k" "$n1" "$n2" "$n3" "$n4" \
      "$(grep -o -m1 'PTS-UNAVAILABLE.*err=[-0-9]*' "$GLOG" 2>/dev/null | grep -o 'err=[-0-9]*' | head -1)" \
      "$(grep -o -m1 'PTS_GAP entry=[^ ]* .*err=[-0-9]*' "$GLOG" 2>/dev/null | grep -o 'err=[-0-9]*' | head -1)"
    echo "  c3_text: $(firstline_re "$GLOG" "\[PTS-UNAVAILABLE\] site=")"
    [ "$alive" = no ] && break
    sleep 0.4
  done
  alive=$(kill -0 "$APP" 2>/dev/null && echo yes || echo no)
  echo "alive_after_seq=$alive"
  if [ "$alive" = yes ]; then sleep 1; kill "$APP" 2>/dev/null; fi
  wait "$APP"; rc=$?
  echo "APP_RC=$rc"; echo "$rc" > "$OUT/rc_g$gi.txt"
  echo "rc_reading: $(case $rc in 124) echo 'TIMEOUT(仪器收的)';;
    137) echo 'OOM';;
    139) echo 'SILENT-SIGSEGV';;
    134) echo 'ABORT(D-G70 族)';;
    143) echo 'SIGTERM(仪器收的)';;
    0) echo 'NORMAL-EXIT';; *) echo 'OTHER';; esac)"
  echo "log_bytes=$(stat -c%s "$GLOG")"
  five > "$OUT/five_post_g$gi.txt"
  if cmp -s "$OUT/five_pre_g$gi.txt" "$OUT/five_post_g$gi.txt"; then echo "FIVE_STABLE_G$gi=YES"; else
    echo "FIVE_STABLE_G$gi=NO ⇒ 本组读数作废"; diff "$OUT/five_pre_g$gi.txt" "$OUT/five_post_g$gi.txt"; fi
  sleep 2
done
echo "ALL_GROUPS_DONE $(date '+%T')"
exit 0
