#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# run-e3replay-probe.sh —— `TASK-0009` E3 真重放夹具的**装置**（可复跑单行命令）
#
# 【一句话】在私有 Xorg（vmware 驱动 + libinput 热插拔）上，用 `evdev/uinput`
#   注入一条**真按下**，并让**产品自己的 X 连接**上那条同步被动抓取把它
#   **重放**一次 ⇒ 产品的 E3 去重闸看到「两条同 button press、无中间 release、
#   `dt∈[0,bound]`」⇒ `cand>0` 被真正行使。
#
# 【它不做什么】不改产品 `.so`／不改 `win32_x11.c`／不跑 `verify-all`／不碰
#   `Guide.Linux/verify-all.sh`、`src/Linux/build/close-wave.sh`、`src/Linux/tools/**`。写域仅本目录。
#
# 【收尾纪律】`/dev/uinput` 用后复原 `600`；Xorg **按 PID** 关（禁 `pkill`／`pgrep -f`）；
#   显示位只用空闲 `:23x`；同步一律**有界等待**（不 `sleep N` 盲等）。
#
# 用法： bash src/Linux/build/MilBridge/tests/E3ReplayProbe/run-e3replay-probe.sh [--out=DIR] [--display=:23N]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/../../../../../.." && pwd)"
PROBE="$HERE/e3replay-probe.c"
LIB="$ROOT/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
SRC="$ROOT/src/WpfGfx.Linux.Native/src/win32_x11.c"
SUDO_PW="links"

OUT=""; DISP=""; XPID=""
for a in "$@"; do
  case "$a" in
    --out=*) OUT="${a#--out=}" ;;
    --display=*) DISP="${a#--display=}" ;;
    *) echo "E3_REPLAY=FAIL reason=usage:$a"; exit 4 ;;
  esac
done

say() { printf '%s\n' "$*"; }
die() { say "E3_REPLAY=FAIL reason=$1 ${2:-}"; [ -n "${XPID:-}" ] && sudo_kill "$XPID"; uinput_restore; exit 1; }
T16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }

sudo_do() { printf '%s\n' "$SUDO_PW" | sudo -S "$@" 2>/dev/null; }
sudo_kill() { [ -n "${1:-}" ] && printf '%s\n' "$SUDO_PW" | sudo -S kill "$1" 2>/dev/null; }
uinput_restore() { [ "${UINPUT_TOUCHED:-0}" = 1 ] && sudo_do chmod 600 /dev/uinput; }
# 收尾闸：无论怎么退场都按 PID 关 Xorg（含 sudo 包装进程）、复原 /dev/uinput（**禁** pkill/pgrep -f）
cleanup_on_exit() { uinput_restore; [ -n "${XPID:-}" ] && sudo_kill "$XPID"; [ -n "${XSUDO:-}" ] && sudo_kill "$XSUDO"; true; }
trap cleanup_on_exit EXIT INT TERM

# ── 0. 前置：工具在位 ────────────────────────────────────────────────────────
for t in Xorg xinput gcc xdpyinfo; do command -v "$t" >/dev/null 2>&1 || die "missing-tool:$t"; done
[ -r "$LIB" ] || die "missing-lib:$LIB"
[ -x /dev/uinput ] || [ -c /dev/uinput ] || die "no-/dev/uinput"

# ── 1. 产物目录 + 写前快照（④ 主链逐字节不变）───────────────────────────────
[ -n "$OUT" ] || OUT="$(mktemp -d /tmp/e3replay.XXXXXX)"
mkdir -p "$OUT"
BIN="$OUT/e3replay-probe"          # 产物落在作业目录：**不在仓内留可执行件**
CONF="$OUT/e3replay-xorg.conf"
SO_SHA_BEFORE="$(T16 "$LIB")"; SRC_SHA_BEFORE="$(T16 "$SRC")"
say "E3_REPLAY_OUT dir=$OUT"
say "E3_REPLAY_PRE lib_sha16=$SO_SHA_BEFORE win32_x11_sha16=$SRC_SHA_BEFORE"

# ── 2. 编译探针 ─────────────────────────────────────────────────────────────
if ! gcc -O2 -std=gnu11 -o "$BIN" "$PROBE" -lX11 -ldl 2>"$OUT/build.log"; then
  say "E3_REPLAY=FAIL reason=cc $(cat "$OUT/build.log")"; exit 1
fi
say "E3_REPLAY_PROBE sha16=$(T16 "$BIN") bin=$BIN"

# ── 3. 挑一个空闲显示位（只用 :23x；socket 不在、无活 Xorg）───────────────────
xorg_pid_of() {   # 只认 args 行首两段 `Xorg <display>`（argv[0] 可能带路径）
  ps -eo pid=,args= | awk -v d="$1" '
    { pid=$1; rest=$0; sub(/^[ \t]*[0-9]+[ \t]+/, "", rest)
      n=split(rest, a, /[ \t]+/)
      sub(/^.*\//, "", a[1])
      if (a[1] == "Xorg" && a[2] == d) { print pid; exit } }'
}
pick_display() {
  local n
  for n in 230 231 232 233 234 235 236 237 238 239; do
    [ -e "/tmp/.X11-unix/X$n" ] && continue
    [ -n "$(xorg_pid_of ":$n")" ] && continue
    printf ':%s\n' "$n"; return 0
  done
  return 1
}
if [ -z "$DISP" ]; then DISP="$(pick_display)" || die "no-free-display-in-23x"; fi
case "$DISP" in :23[0-9]) ;; *) die "display-out-of-whitelist:$DISP";; esac
[ -e "/tmp/.X11-unix/X${DISP#:}" ] && die "display-socket-present:$DISP"
say "E3_REPLAY_DISPLAY=$DISP"

# ── 4. 私有 Xorg（vmware 驱动 ⇒ 吃 evdev/libinput）───────────────────────────
cat > "$CONF" <<'XCONF'
Section "ServerLayout"
    Identifier "E3L"
    Screen "E3S"
EndSection
Section "Device"
    Identifier "E3D"
    Driver "vmware"
EndSection
Section "Screen"
    Identifier "E3S"
    Device "E3D"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1280x1024"
    EndSubSection
EndSection
XCONF
XLOG="$OUT/xorg$DISP.log"
sudo_do Xorg "$DISP" -config "$CONF" -noreset -ac -logfile "$XLOG" &
XSUDO=$!
# 有界等待：最多 ~10 s 等 socket 与 xdpyinfo
for i in $(seq 1 100); do
  XPID="$(xorg_pid_of "$DISP")"
  [ -n "$XPID" ] && DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1 && break
  sleep 0.1
done
[ -n "$XPID" ] || { tail -20 "$XLOG" 2>/dev/null; die "xorg-did-not-start display=$DISP"; }
DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1 || { tail -20 "$XLOG" 2>/dev/null; die "xorg-not-answering display=$DISP xpid=$XPID"; }
say "E3_REPLAY_XORG_PID=$XPID display=$DISP"

# ── 5. 临时放开 /dev/uinput（用后复原 600）───────────────────────────────────
UINPUT_TOUCHED=1
sudo_do chmod 666 /dev/uinput
say "E3_REPLAY_UINPUT perms=$(stat -c '%A' /dev/uinput)"

# ── 6. 一条腿 ───────────────────────────────────────────────────────────────
run_leg() {   # run_leg <leg> <grab|nograb> <dedup:on|off>
  local leg="$1" mode="$2" dedup="$3"
  local tag="$OUT/$leg"
  local fifo="$tag.fifo"
  rm -f "$fifo"; mkfifo "$fifo"
  local envs=(DISPLAY="$DISP" E3_DEV_NAME="e3replay-$leg" WPF_LINUX_KEY_DIAG=1 E3_LIB_SHA16="$(T16 "$LIB")")
  if [ "$dedup" = off ]; then envs+=(WPF_E3_REPLAY_DEDUP=0); else envs+=(WPF_E3_REPLAY_DEDUP=1); fi

  env "${envs[@]}" "$BIN" "$LIB" "$mode" <"$fifo" >"$tag.out" 2>"$tag.err" &
  local PPID_=$!
  exec 9>"$fifo"
  rm -f "$fifo"

  # 有界等待 ready
  local i ok=0
  for i in $(seq 1 100); do grep -q 'PROBE ready' "$tag.out" 2>/dev/null && { ok=1; break; }; sleep 0.1; done
  [ "$ok" = 1 ] || { say "E3_REPLAY_LEG leg=$leg status=no-ready"; exec 9>&-; wait "$PPID_" 2>/dev/null; return 1; }

  # 有界等待 X 认领 uinput 设备（热插拔）
  ok=0
  for i in $(seq 1 100); do
    DISPLAY="$DISP" xinput list 2>/dev/null | grep -q "e3replay-$leg" && { ok=1; break; }; sleep 0.1
  done
  say "E3_REPLAY_LEG leg=$leg mode=$mode dedup=$dedup device_claimed=$ok"

  printf 'press\n' >&9
  # 有界等待产品打出「两条 press」的那条读数（或超时）
  for i in $(seq 1 100); do
    grep -qE 'press=2' "$tag.err" 2>/dev/null && break
    grep -q 'after_press' "$tag.out" 2>/dev/null && break
    sleep 0.1
  done
  printf 'release\n' >&9
  for i in $(seq 1 50); do grep -q 'after_release' "$tag.out" 2>/dev/null && break; sleep 0.1; done
  printf 'quit\n' >&9
  exec 9>&-
  for i in $(seq 1 50); do kill -0 "$PPID_" 2>/dev/null || break; sleep 0.1; done
  kill "$PPID_" 2>/dev/null; wait "$PPID_" 2>/dev/null

  # 取末条 [E3-REPLAY] press 读数（**产品自己打的**）
  local last
  last="$(grep -a '\[E3-REPLAY\].*ev=press' "$tag.err" | tail -1)"
  printf '%s\n' "$last" > "$tag.e3line"
  grep -a 'BTN type=Press' "$tag.err" > "$tag.btn" 2>/dev/null || true
  local nbtn; nbtn="$(grep -ac . "$tag.btn" 2>/dev/null || echo 0)"
  say "E3_REPLAY_BTN leg=$leg raw_ButtonPress_lines=$nbtn（原样：$(tr '\n' '|' < "$tag.btn" | sed 's/|$//')）"
  local cand drop dt livebtn press deliver
  cand="$(sed -n 's/.* cand=\([0-9]*\).*/\1/p'   <<<"$last")"
  drop="$(sed -n 's/.* drop=\([0-9]*\).*/\1/p'   <<<"$last")"
  dt="$(sed -n 's/.* dt_ms=\(-\?[0-9]*\).*/\1/p' <<<"$last")"
  livebtn="$(sed -n 's/.* live_btn=\(-\?[0-9]*\).*/\1/p' <<<"$last")"
  press="$(sed -n 's/.* press=\([0-9]*\).*/\1/p' <<<"$last")"
  deliver="$(sed -n 's/.* deliver=\([0-9]*\).*/\1/p' <<<"$last")"
  say "E3_REPLAY_READ leg=$leg mode=$mode dedup=$dedup press=${press:-NA} deliver=${deliver:-NA} cand=${cand:-NA} drop=${drop:-NA} dt=${dt:-NA} live_button=${livebtn:-NA} b=$(sed -n 's/.* btn=\([0-9]*\).*/\1/p' <<<"$last")"
  printf 'E3_REPLAY_LINE leg=%s %s\n' "$leg" "$last"
  return 0
}

# ── 7. 三条腿：R（抓取+去重开）／D（抓取+去重关）／F（无抓取=去重开）──────────
run_leg R grab   on
run_leg D grab   off
run_leg F nograb on

# ── 8. 收尾：复原 /dev/uinput、按 PID 关 Xorg ────────────────────────────────
uinput_restore
say "E3_REPLAY_UINPUT_RESTORED perms=$(stat -c '%A' /dev/uinput)"
sudo_kill "$XPID"
for i in $(seq 1 50); do [ -d "/proc/$XPID" ] || break; sleep 0.1; done
say "E3_REPLAY_XORG_STOPPED pid=$XPID alive=$([ -d "/proc/$XPID" ] && echo 1 || echo 0)"
rm -f "/tmp/.X11-unix/X${DISP#:}" 2>/dev/null || true

# ── 9. ④ 主链逐字节不变 ─────────────────────────────────────────────────────
SO_SHA_AFTER="$(T16 "$LIB")"; SRC_SHA_AFTER="$(T16 "$SRC")"
same=0; [ "$SO_SHA_BEFORE" = "$SO_SHA_AFTER" ] && [ "$SRC_SHA_BEFORE" = "$SRC_SHA_AFTER" ] && same=1
say "E3_REPLAY_MAINCHAIN_UNCHANGED=$same lib_before=$SO_SHA_BEFORE lib_after=$SO_SHA_AFTER src_before=$SRC_SHA_BEFORE src_after=$SRC_SHA_AFTER"
say "E3_REPLAY=OK out=$OUT display=$DISP"
