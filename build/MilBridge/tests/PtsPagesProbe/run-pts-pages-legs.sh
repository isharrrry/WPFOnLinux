#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run-pts-pages-legs.sh —— `PTS-PAGES` 步的**腿跑器**（重活那一半）。
#   与判据 `pts-pages-guard.sh` **分开**：判据纯读（<0.2 s，门禁里跑它），腿跑器只在需要时跑。
#   （形制照 `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh`。）
#
# 用法:
#   run-pts-pages-legs.sh <证据目录>              # 跑 A 臂（现权威五件）2 条腿：24 与 23
#   run-pts-pages-legs.sh <证据目录> --all-arms    # 三臂 5 条腿（A:24 A:23 B:24 B:23 C:24）
#
# 前置（脚本自己核，**不满足就响亮 NOINFO**）:
#   · `sync-applocal.sh --check <APPDIR>` ⇒ `drift=0`（否则等于在测**陈旧件**，`D-G56`/`W1` 族）
#   · 显示号空闲（**只读** /proc/*/cmdline；**不用** `pgrep -f`）
#   · 内存 ≥ 1500 MB（`MemAvailable`）
#
# 自证（缺任何一条 ⇒ 证据目录里的 `device.txt` 记 `NOINFO`，由判据转成 `NOINFO`）:
#   `X_UP=yes`
#
# 纪律：显示只用 `:23x`｜进程**只按 PID** 收（先 TERM 后 KILL）｜**禁** `pkill`/`killall`/`pgrep -f`
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

REPO="${PTS_GUARD_REPO:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)}"   # 波 `#77` 旧路径重指向：由仓根现推
# ⚠️【落仓参数化（纪律 34）】原值指向**仓外共享应用安装**（~/hc-linux/...）
#   ⇒ 跑腿会把权威五件**写进那个共享安装**（副作用）。现在默认 = **仓外私有暂存**，
#     由 ~/w160a/stage-app.sh 装配（照 RGateClickProbe 的形制）。
APPDIR="${PTS_GUARD_APPDIR:-${W67_WORK:-$HOME/w67-work}/app}"
DISPLAY_NUM="${PTS_GUARD_DISPLAY:-:237}"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
SESS="${PTS_INNER:-$SELF_DIR/session_inner.sh}"   # 私有腿跑器（与判据同目录）；⏪ `t153`：`PTS_INNER` 可注入**桩**（测试缝；默认值不变）
TOENV="$SELF_DIR/legs-to-env.py"
# ⚠️【落仓参数化（纪律 34）】原值 = 某**外来车道**工作目录下的 dlls（**硬编码**）。
#   现在：**不设 PTS_GUARD_ARMS ⇒ 不换件** —— A 臂的语义就是*现权威五件*，
#   而私有应用目录已由 sync-applocal.sh 灌成权威五件 ⇒ **不该再被任何 DLL 覆盖**。
#   ⚠️ 但**真**要跑 A 臂时，session_inner.sh 仍要 $DLLS/A.libwpfwin32.so 存在
#     ⇒ 由运行时装配（~/w160a/stage-arms.sh）：A 臂 = 当前权威件的**同一字节**副本。
#     原字面路径的 sha256 前 16 位见 ~/w160a/drop/PATH-LITERALS.txt（**不在此复写**，
#     否则纪律 34 的 grep -E '$HOME/w1[0-9]+a' 会把**注释本身**算成残留 —— 本器实测踩过）。
ARMDIR="${PTS_GUARD_ARMS:-}"
MIN_AVAIL_MB="${PTS_GUARD_MIN_AVAIL_MB:-1500}"

usage() { echo "用法: $0 <证据目录> [--all-arms]" >&2; exit 2; }
[ $# -ge 1 ] || usage
OUTDIR="$1"; shift
ALL_ARMS=0
[ "${1:-}" = "--all-arms" ] && ALL_ARMS=1
mkdir -p "$OUTDIR"
mkdir -p "$OUTDIR/device"

# ⏪ `t153`：**计数必须无条件印**（前置拒绝／转换失败／中途退出都要印）⇒ 用 `EXIT` trap 兜底（`_LEGSCOUNT_DONE` 防重印；
#   `$?` 在 trap 里就是退出码，打印不改 rc）。`requested` ＝ 请求样本数；`obtained` ＝ 真产出 `leg_<k>.env` 的样本数。
CONV_RC="-"; SESS_RC="-"; DISPLAY_NUM=""
REQ_N=2; [ "$ALL_ARMS" = 1 ] && REQ_N=5   # ⏪ t153：请求样本数（A:24,23 = 2；--all-arms = 5）—— **前置拒绝路径的计数行也要有它**
_LEGSCOUNT_DONE=0
_legs_count() {
  local rc=$?; [ "${_LEGSCOUNT_DONE:-0}" = 1 ] && return $rc; _LEGSCOUNT_DONE=1
  local n=0 d _n miss rs=""
  for d in "$OUTDIR"/arm_*; do [ -d "$d" ] || continue; _n=$(ls "$d"/leg_*.env 2>/dev/null | wc -l); n=$((n + _n)); done
  [ "$n" = 0 ] && n=$(ls "$OUTDIR"/leg_*.env 2>/dev/null | wc -l)
  miss=$(grep -c 'MISSING-SHIM' "$OUTDIR/session.txt" 2>/dev/null || true); miss="${miss:-0}"
  [ -s "$OUTDIR/session.txt" ] || rs="${rs}session-missing=1,"
  [ "$SESS_RC" = "-" ] || [ "$SESS_RC" = 0 ] || rs="${rs}session-rc=$SESS_RC,"
  [ "$CONV_RC" = "-" ] || [ "$CONV_RC" = 0 ] || rs="${rs}converter-rc=$CONV_RC,"
  [ "$miss" = 0 ] || rs="${rs}missing-shim=$miss,"
  [ "$n" -gt 0 ] || rs="${rs}no-leg-env=1,"
  [ "$rc" = 0 ] || rs="${rs}runner-rc=$rc,"
  echo "LEGSCOUNT requested=${REQ_N:-?} obtained=$n refused=$(( ${REQ_N:-0} - n )) reasons=${rs:-none} display=${DISPLAY_NUM:-none} rc=$rc session_rc=$SESS_RC conv_rc=$CONV_RC outdir=$OUTDIR"
  if [ "${REQ_N:-0}" -gt 0 ] && [ "$n" -ge "${REQ_N:-0}" ] && [ "$rc" = 0 ]; then
    echo "LEGS_RUNNER=PASS requested=${REQ_N} obtained=$n refused=0 display=${DISPLAY_NUM:-none}"
  else
    echo "LEGS_RUNNER=FAIL requested=${REQ_N:-?} obtained=$n refused=$(( ${REQ_N:-0} - n )) reasons=${rs:-unaccounted} display=${DISPLAY_NUM:-none}"
  fi
  return $rc
}
trap '_legs_count' EXIT
HAS_TRAP=1

# ── 前置 1：应用目录必须与权威一致（否则测的是陈旧件）─────────────────────────
if [ -x "$REPO/build/MilBridge/tools/sync-applocal.sh" ]; then
  chk="$(bash "$REPO/build/MilBridge/tools/sync-applocal.sh" --check "$APPDIR" 2>&1 | grep -a '^SYNC-APPLOCAL=' | head -1)"
  echo "APPSYNC: ${chk:-<无 SYNC-APPLOCAL 行 ⇒ 取不到 ⇒ NOINFO>}"
  case "$chk" in
    *drift=0*) ;;
    *) echo "device=NOINFO reason=app-stale detail=${chk:-none}"; exit 2 ;;
  esac
else
  echo "device=NOINFO reason=sync-applocal-missing"; exit 2
fi

# ── 前置 1b（`t52`）：**硬闸** —— 应用目录里的 shim/pf 必须**就是 authority** ──────────
#   为什么 `--check drift=0` 不够：它查的是"**此刻**目录里的件与权威一致"，而
#   `session_inner.sh` 的 `cp -a "$DLLS/$ARM.*"` 会在**跑腿期间**把目录覆盖回旧代
#   ⇒ 看门的那一刻是绿的、真正跑的却是旧件（实测：跑前 `6825dd7071387a46` ⇒ 跑后 `fc60c34d51fd9247`）。
AUTH_SHIM="$REPO/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
AUTH_PF="$REPO/build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll"
AUTH_SHIM16="$(sha256sum "$AUTH_SHIM" 2>/dev/null | cut -c1-16)"
AUTH_PF16="$(sha256sum "$AUTH_PF" 2>/dev/null | cut -c1-16)"
APP_SHIM16="$(sha256sum "$APPDIR/libwpfwin32.so" 2>/dev/null | cut -c1-16)"
APP_PF16="$(sha256sum "$APPDIR/PresentationFramework.dll" 2>/dev/null | cut -c1-16)"
echo "AUTHORITY: shim=$AUTH_SHIM16 pf=$AUTH_PF16 ｜ APPDIR: shim=$APP_SHIM16 pf=$APP_PF16"
if [ -z "$AUTH_SHIM16" ] || [ -z "$AUTH_PF16" ]; then
  echo "device=NOINFO reason=authority-missing shim=$AUTH_SHIM pf=$AUTH_PF"; exit 2
fi
if [ "$APP_SHIM16" != "$AUTH_SHIM16" ] || [ "$APP_PF16" != "$AUTH_PF16" ]; then
  echo "device=NOINFO reason=app-stale-vs-authority app_shim=$APP_SHIM16 auth_shim=$AUTH_SHIM16 app_pf=$APP_PF16 auth_pf=$AUTH_PF16"
  echo "  ∟ 装配口径坏 ⇒ 跑腿会产出**旧世界读数** ⇒ **拒跑**（不是"大概能跑"）。" >&2
  exit 2
fi

# ── 前置 2：显示号空闲（只读 /proc/*/cmdline；**排除自己的整条祖先链**）──────────────
#   ⚠️【落仓修 · A（D-G103 族 · 自匹配）】原口径只排除 $$／$PPID ⇒ **不够**：
#     本器被 heavy-slot.sh 调起时，槽里的 env／bash 子进程**命令行里也带着**
#     PTS_GUARD_DISPLAY=:<n> ⇒ 自己的子壳会被当成"别的车道占了显示"
#     ⇒ device=NOINFO reason=display-occupied pid=<自己的子壳>（**假 NOINFO**，实测踩到）。
#     修法：把 $$ 的**整条祖先链**（/proc/<pid>/stat 第 4 列递归）也排除 —— 按机器算，不猜。
#   ⚠️【落仓修 · B（PIPEFAIL-SIGPIPE 陷阱，`#67` gate1 现抓）】原写法
#     `if … | grep -q -- "$DISPLAY_NUM"; then` 是**末段早退**形态：`grep -q` 命中即退出并关读端
#     ⇒ 上游 `tr` 吃 SIGPIPE；在 `pipefail` 下整条管道 rc≠0 ⇒ **那个 if 可能恒假**
#     ⇒ **显示占用检查静默失效**（装置会在**别人占用的显示号**上开跑 = 假绿方向）。
#     修法：**去掉管道**，先取变量再 case 匹配（`case` 不早退、也不受 pipefail 影响）。
self_chain_pids() {
  local pid=$$ p
  while [ -n "$pid" ] && [ "$pid" != 0 ] && [ "$pid" != 1 ]; do
    printf '%s\n' "$pid"
    [ -r "/proc/$pid/stat" ] || break
    p="$(sed 's/^.*) //' "/proc/$pid/stat" 2>/dev/null | awk '{print $2}')"
    [ -n "$p" ] || break
    [ "$p" = "$pid" ] && break
    pid="$p"
  done
}
SELF_CHAIN="$(self_chain_pids | tr '\n' ' ')"
self_in_chain() { case " $SELF_CHAIN " in *" $1 "*) return 0 ;; esac; return 1; }
# ── 前置 2（⏪ `t153`，**修"静默少样本"**）：**独占号分配 ＋ 有界等待** ────────────────────────
#   旧形态（现取 `t150` 上报的病灶）：号被**上一趟自己的 Xvfb**（未即时收净）占着 ⇒ 立刻
#     `device=NOINFO reason=display-occupied` ⇒ `exit 2` ⇒ **调用方拿到的像"跑过了"、实际 0 样本**（静默少样本）。
#   新形态（三条，逐字）：
#     · **可复现的分配规则**：候选号 ＝ `$PTS_DISPLAY_BASE`（默认 `:231`）起、`$PTS_DISPLAY_SPAN`（默认 9）个
#       （`:231`..`:239`）；**取最小空闲号** ⇒ 同一进程内**连续多趟不会互相踩号**（`t150` 手工用 `:231`..`:239` 拿到 9/9 的规则，现在自动化）。
#       调用方**显式**给 `PTS_GUARD_DISPLAY=:<n>` ⇒ **只用该号**（向后兼容；被占时走下面的等待/失败）。
#     · **"空"的判据**：没有**非本链**进程的 `cmdline` 含该号 token（`self_in_chain` 跳过本进程链，避免把自己判成占用者）。
#     · **有界等待**：被占 ⇒ 每 0.5s 重扫、最多 `$PTS_DISPLAY_WAIT_SECS`（默认 30）秒（**先等上一趟自己的 Xvfb 收净**）；
#       **等不到 ⇒ 显式失败并点名**（`DISPLAY_WAIT … state=timeout` ＋ `device=NOINFO reason=display-not-free …` ＋
#       **计数行** ＋ `LEGS_RUNNER=FAIL` ＋ `exit 2`）—— **绝不静默继续**。
occupied_by() {   # occupied_by <display> ⇒ 印占用者 pid（stdout 空＝空闲）
  local d="$1" p pid cl
  for p in /proc/[0-9]*; do
    [ -r "$p/cmdline" ] || continue
    pid="${p#/proc/}"
    self_in_chain "$pid" && continue
    cl="$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null || true)"
    case "$cl" in *"$d"*) printf '%s' "$pid"; return 0 ;; esac
  done
  return 1
}
PTS_DISPLAY_BASE="${PTS_DISPLAY_BASE:-:231}"
PTS_DISPLAY_SPAN="${PTS_DISPLAY_SPAN:-9}"
PTS_DISPLAY_WAIT_SECS="${PTS_DISPLAY_WAIT_SECS:-30}"
_occ_of() { occupied_by "$1" 2>/dev/null || true; }
if [ -n "${PTS_GUARD_DISPLAY:-}" ]; then
  DISPLAY_NUM="$PTS_GUARD_DISPLAY"
  PICK_RULE="caller-fixed(PTS_GUARD_DISPLAY)"
else
  PICK_RULE="lowest-free(base=$PTS_DISPLAY_BASE span=$PTS_DISPLAY_SPAN)"
  base_num="${PTS_DISPLAY_BASE#:}"
  DISPLAY_NUM=""
  i=0
  while [ "$i" -lt "$PTS_DISPLAY_SPAN" ]; do
    cand=":$((base_num + i))"
    if [ -z "$(_occ_of "$cand")" ]; then DISPLAY_NUM="$cand"; break; fi
    i=$((i+1))
  done
  [ -n "$DISPLAY_NUM" ] || DISPLAY_NUM=":$base_num"   # 全都占着 ⇒ 用首个候选走"等待 ⇒ 超时显式失败"路径（**不静默跳过**）
fi
_waited_ms=0
while :; do
  occ="$(_occ_of "$DISPLAY_NUM")"
  [ -z "$occ" ] && break
  if [ "$_waited_ms" -ge $((PTS_DISPLAY_WAIT_SECS * 1000)) ]; then
    echo "DISPLAY_WAIT display=$DISPLAY_NUM state=timeout waited_ms=$_waited_ms occupant_pid=$occ rule=$PICK_RULE"
    echo "device=NOINFO reason=display-not-free display=$DISPLAY_NUM waited_ms=$_waited_ms occupant_pid=$occ"
    echo "LEGSCOUNT requested=$REQ_N obtained=0 refused=$REQ_N reasons=display-not-free=$REQ_N display=$DISPLAY_NUM rule=$PICK_RULE"
    echo "LEGS_RUNNER=FAIL reason=display-not-free display=$DISPLAY_NUM occupant_pid=$occ"
    _LEGSCOUNT_DONE=1   # ⏪ `t153`：本路径已印过计数 ⇒ 不让 EXIT trap 再印一遍（防重复行）
    exit 2
  fi
  [ "$_waited_ms" = 0 ] && echo "DISPLAY_WAIT display=$DISPLAY_NUM state=waiting occupant_pid=$occ rule=$PICK_RULE（先等上一趟自己的 Xvfb 收净，最多 ${PTS_DISPLAY_WAIT_SECS}s）"
  sleep 0.5; _waited_ms=$((_waited_ms + 500))
done
echo "DISPLAY_PICK display=$DISPLAY_NUM rule=$PICK_RULE waited_ms=$_waited_ms（独占号：同一进程内多趟按"最小空闲"分配 ⇒ 不互相踩号）"

# ── 前置 3：内存闸 ────────────────────────────────────────────────────────────
avail_mb=$(( $(awk '/^MemAvailable:/{print $2}' /proc/meminfo) / 1024 ))
if [ "$avail_mb" -lt "$MIN_AVAIL_MB" ]; then
  echo "device=NOINFO reason=low-memory avail=${avail_mb}MB min=${MIN_AVAIL_MB}MB"; exit 2
fi
echo "device=memok avail=${avail_mb}MB"

# ── 起 X（**自证**）──────────────────────────────────────────────────────────
Xvfb "$DISPLAY_NUM" -screen 0 1280x1024x24 > "$OUTDIR/device/xvfb.log" 2>&1 &
XVFB=$!; echo "$XVFB" > "$OUTDIR/device/xvfb.pid"
sleep 2
DISPLAY="$DISPLAY_NUM" xfwm4 --display="$DISPLAY_NUM" --compositor=off > "$OUTDIR/device/xfwm.log" 2>&1 &
XFWM=$!; echo "$XFWM" > "$OUTDIR/device/xfwm.pid"
sleep 3
if DISPLAY="$DISPLAY_NUM" xdpyinfo >/dev/null 2>&1; then
  echo "X_UP=yes display=$DISPLAY_NUM" | tee "$OUTDIR/device.txt"
else
  echo "X_UP=no display=$DISPLAY_NUM" | tee "$OUTDIR/device.txt"
  echo "device=NOINFO reason=x-not-up"; kill "$XFWM" "$XVFB" 2>/dev/null; exit 2
fi

# ⏪【`t68`，读时 2026-09-28T20:54:24.554+0800】**官方调用者的显示位 lease**（`D-G188`：修「装置互斥 ＋ 保护名义化」）。本脚本**自己**起了
#   `$DISPLAY_NUM` 的 `Xvfb`（`XVFB=$!`）⇒ 把「我是它的**亲生父亲**」写成一件 **`600`** 权限的 lease 交给下游
#   `session_inner.sh` 的占用闸。闸据此在自己的判据内区分**两种**「socket 存在」：
#     · **官方调用者的自有显示位**（lease 五条全成立：常规件／模式 `600`／`DISPLAY` 相符／`OWNER_PID` 在闸的祖先链上／
#       活 `Xvfb` 且其 `ppid` == `OWNER_PID`）⇒ **放行**（否则本脚本会被自己的闸拒死 ⇒ `PTS-PAGES` 腿路跑不起来）；
#     · **外人占用**（无 lease／伪造／过期／非祖先链／`Xvfb` 非其亲生）⇒ **仍拒跑**（闸不放水）。
#   ⚠️ 防伪造的要点：外人**拿不到**「闸进程的祖先链」这个事实；把 `WPF_X11_DIR` 指到空目录也**不**能让被占的号看着空闲
#      （闸对 `WPF_X11_DIR` 与规范目录**双边**检查）。
LEASE="$OUTDIR/device/display-lease.txt"
{
  printf 'DISPLAY=%s\n' "$DISPLAY_NUM"
  printf 'OWNER_PID=%s\n' "$$"
  printf 'XVFB_PID=%s\n' "$XVFB"
  printf 'SOCK_DIR=%s\n' "${WPF_X11_DIR:-/tmp/.X11-unix}"
  printf 'TS=%s\n' "$(date -Iseconds)"
} > "$LEASE"
chmod 600 "$LEASE"
export W67_DISPLAY_LEASE="$LEASE"
echo "DISPLAY_LEASE_FILED=$LEASE owner_pid=$$ xvfb_pid=$XVFB display=$DISPLAY_NUM mode=$(stat -c %a "$LEASE")"

# ── 跑腿（**调用方负责在重活槽里跑本脚本**）──────────────────────────────────
# ⚠️【落仓修 · C（实测踩到，两处必须同趟）】
#   ① GROUPS 是 **bash 的内置只读特殊变量**（进程的组 ID 列表）⇒ 对它赋值**静默无效**：
#      GROUPS=("A:24,23") 之后 ${#GROUPS[@]} 仍是 **9**、${GROUPS[0]} = **1000**（本用户 gid）。
#      ⇒ 那行 echo 打的是 **GID 列表**（现场：`LEGS: 1000 24 27 30 46 122 135 136 4`），
#        下一行又把**每个 GID 当一个 group** 传下去 ⇒ ARM=1000/KS=1000 … ⇒ 9 行 MISSING-SHIM、
#        **一条腿都跑不出来**。**修法 = 换名**（LEG_GROUPS）。
#      机械证 = ~/w160a/repro-groups.sh（对照 A 换名 ⇒ len=1；对照 B 原名 ⇒ len=9 且与 id -G 逐字相同）。
#   ② 下游 session_inner.sh 的接口 =「**一个 group 一个 argv**，臂与点击号用 : 连、点击号用 , 连」
#      ⇒ 原写法把 A:24／A:23 拆成两个 argv 会被读成 ARM=A/KS=A（非法输入）。
LEG_GROUPS=("A:24,23")
[ "$ALL_ARMS" = 1 ] && LEG_GROUPS=("A:24,23" "B:24,23" "C:24")
echo "LEGS: ${LEG_GROUPS[*]}"
bash "$SESS" "$(basename "$OUTDIR")" "${LEG_GROUPS[@]}" 2>&1 | tee "$OUTDIR/session.txt"
rc_sess=${PIPESTATUS[0]}
SESS_RC="$rc_sess"   # ⏪ `t153`：交给 EXIT trap 的计数行（**新增**；既有变量与用法未动）

# ── 收装置（**只按 PID**）────────────────────────────────────────────────────
for f in xfwm.pid xvfb.pid; do [ -s "$OUTDIR/device/$f" ] && kill "$(cat "$OUTDIR/device/$f")" 2>/dev/null; done
sleep 1
for f in xfwm.pid xvfb.pid; do
  [ -s "$OUTDIR/device/$f" ] && { kill -9 "$(cat "$OUTDIR/device/$f")" 2>/dev/null; rm -f "$OUTDIR/device/$f"; }
done
rm -f "$OUTDIR/device/display-lease.txt"   # ⏪【`t68`】显示位 lease 随装置收尾一并撤（不留可被复用的旧 lease）
# ⏪ `t153`：收尾**自证**（残留 ⇒ 点名并按 PID 再收一次；**不**用 pkill/pgrep -f）
for _pair in "xvfb:$XVFB" "xfwm:$XFWM"; do
  _k="${_pair%%:*}"; _p="${_pair#*:}"
  if [ -n "${_p:-}" ] && kill -0 "$_p" 2>/dev/null; then
    kill -9 "$_p" 2>/dev/null
    sleep 0.3
    if kill -0 "$_p" 2>/dev/null; then echo "DEVICE_REAP state=STILL-ALIVE who=$_k pid=$_p display=$DISPLAY_NUM"; else echo "DEVICE_REAP state=reaped-on-retry who=$_k pid=$_p display=$DISPLAY_NUM"; fi
  else
    echo "DEVICE_REAP state=clean who=$_k pid=${_p:-none} display=$DISPLAY_NUM"
  fi
done

# ── 转证据契约 ───────────────────────────────────────────────────────────────
# ⚠️【落仓加（实测需要）】session_inner.sh 把 session.txt 与原始日志写在
#   **${W67_WORK:-$HOME/w67-work}/logs/<tag>**（tag = basename "$OUTDIR"）——
#   而 legs-to-env.py:149 是**按 session.txt 所在目录**找 app_g<N>.log 的：
#   logf = os.path.join(os.path.dirname(os.path.abspath(sess)), "app_g%s.log")。
#   本次实测：$OUTDIR 里**没有** app_g*.log ⇒ 转换器读不到原始日志 ⇒ 只能退回 session 里的
#   native_gap（那条路径恒 0）⇒ 判词 PTS_GUARD=FAIL fails=native-ledger-absent(PTS_GAP n=0)
#   —— **假红**（真值：原始日志里 PTS_GAP entry= 命中 **1**，现场逐字已核）。
#   ⚠️ SESS_LOGDIR 的口径必须与 session_inner.sh 的 OUT="$W/logs/$TAG" **逐字一致**。
SESS_LOGDIR="${W67_WORK:-$HOME/w67-work}/logs/$(basename "$OUTDIR")"
echo "SESS_LOGDIR=$SESS_LOGDIR（转换器要找的 app_g*.log 就在这里）"
# **转换之前**把原始日志/读片镜像进 $OUTDIR ⇒ session.txt 与 app_g*.log **同目录**
#   ⇒ 转换器以**原始日志为权威**（它自己 docstring 就这么写的）⇒ native_gap 才取得到真值。
for _f in "$SESS_LOGDIR"/app_g*.log "$SESS_LOGDIR"/five_pre_g*.txt "$SESS_LOGDIR"/five_post_g*.txt; do
  [ -f "$_f" ] && cp -a --remove-destination "$_f" "$OUTDIR/$(basename "$_f")"
done
[ -d "$SESS_LOGDIR/shots" ] && cp -a "$SESS_LOGDIR/shots/." "$OUTDIR/shots/" 2>/dev/null
python3 "$TOENV" "$OUTDIR/session.txt" "$OUTDIR/device.txt" "$OUTDIR/shots" "$OUTDIR"
CONV_RC=$?   # ⏪ `t153`：**不再 `|| exit 1` 静默退出** —— 记 rc、印具名行，由 EXIT trap 的计数行收口（"没拿到"必须可数）
[ "$CONV_RC" = 0 ] || echo "LEGS_TO_ENV_FAIL rc=$CONV_RC outdir=$OUTDIR（转换器失败 ⇒ 该趟**样本不可用**；计数行会点名）"
POST_SHIM16="$(sha256sum "$APPDIR/libwpfwin32.so" 2>/dev/null | cut -c1-16)"
POST_PF16="$(sha256sum "$APPDIR/PresentationFramework.dll" 2>/dev/null | cut -c1-16)"
if [ "$POST_SHIM16" != "$AUTH_SHIM16" ] || [ "$POST_PF16" != "$AUTH_PF16" ]; then
  echo "device=NOINFO reason=app-swapped-during-run post_shim=$POST_SHIM16 auth_shim=$AUTH_SHIM16 post_pf=$POST_PF16 auth_pf=$AUTH_PF16"
  echo "  ∟ 跑腿期间件被换过 ⇒ 本趟读数**不可归因**（旧世界）" >&2
  echo "LEGS_RUNNER=NOINFO reason=app-swapped-during-run rc_session=$rc_sess outdir=$OUTDIR"
  exit 2
fi
echo "POSTSHIM: shim=$POST_SHIM16 pf=$POST_PF16（== authority ⇒ 读数可归因）"

LEGS_RUNNER=OK rc_session=$rc_sess outdir=$OUTDIR
