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

REPO="${PTS_GUARD_REPO:-/home/links-dev/netTest/wpf-linux-20260906/wpf-linux}"
# ⚠️【落仓参数化（纪律 34）】原值指向**仓外共享应用安装**（~/hc-linux/...）
#   ⇒ 跑腿会把权威五件**写进那个共享安装**（副作用）。现在默认 = **仓外私有暂存**，
#     由 ~/w160a/stage-app.sh 装配（照 RGateClickProbe 的形制）。
APPDIR="${PTS_GUARD_APPDIR:-${W67_WORK:-$HOME/w67-work}/app}"
DISPLAY_NUM="${PTS_GUARD_DISPLAY:-:237}"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
SESS="$SELF_DIR/session_inner.sh"          # 私有腿跑器（与判据同目录）
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
for p in /proc/[0-9]*; do
  [ -r "$p/cmdline" ] || continue
  pid="${p#/proc/}"
  self_in_chain "$pid" && continue
  cl="$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null || true)"
  case "$cl" in
    *"$DISPLAY_NUM"*) echo "device=NOINFO reason=display-occupied display=$DISPLAY_NUM pid=$pid"; exit 2 ;;
  esac
done

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

# ── 收装置（**只按 PID**）────────────────────────────────────────────────────
for f in xfwm.pid xvfb.pid; do [ -s "$OUTDIR/device/$f" ] && kill "$(cat "$OUTDIR/device/$f")" 2>/dev/null; done
sleep 1
for f in xfwm.pid xvfb.pid; do
  [ -s "$OUTDIR/device/$f" ] && { kill -9 "$(cat "$OUTDIR/device/$f")" 2>/dev/null; rm -f "$OUTDIR/device/$f"; }
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
python3 "$TOENV" "$OUTDIR/session.txt" "$OUTDIR/device.txt" "$OUTDIR/shots" "$OUTDIR" || exit 1
echo "LEGS_RUNNER=OK rc_session=$rc_sess outdir=$OUTDIR"
