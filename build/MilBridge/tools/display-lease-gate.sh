#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# display-lease-gate.sh —— 牙：**显示号租借**（`TASK-0739` 残留③；车道 `W183A` 预备包）
#
# 【它挡的是什么】`TASK-0739` 残留③：「显示位改为**租用**（带 pid 标记）而不是硬编码 `:97`／`:99`」。
#   要挡的**病**是"静默换号"与"两趟撞到同一个号"——两者都让**读数失真而无人知晓**。
#   本牙判的**不是**装置内部实现，而是装置**对外可观察的义务**：
#     ①要号必须**证明**独占（`prior_absent=1` 是**占位操作的结果**，不是观察）
#     ②被占必须**显式失败并点名**（**绝不**静默换号）
#     ③`NOINFO`（源读不到）**不许**当绿
#     ④并发两趟的号**必不相同**（动态面**真跑**）
#
# 【判据（**先写死在 `criteria.md`；本件是它的执行者**）】
#   rc=0  `DISPLAY_LEASE_GATE=PASS static=<p>/<n> dynamic=<p>/<n>`
#   rc=1  `DISPLAY_LEASE_GATE=FAIL …`（逐条点名 `case=`/`want=`/`got=`）
#   rc=3  `DISPLAY_LEASE_GATE=NOINFO reason=…`（装置缺失／`xdpyinfo` 缺失／Xvfb 起不来）
#   ⛔ **`examined=0` 判红**（纪律 05：零检查也是红，否则假绿）。
#   ⛔ **仪器自证**（`D-G102` 同族）：每条腿进 `examined` 计数；每条起真进程的腿必打
#      `FIXTURE_PROOF pid=… live=1`；整个牙必打 `LEASE_DEV_SHA16=`（被测装置的**现算**哈希）。
#   ⛔ **号不是写死的**：装置的号池搜索是动态的（有租约／有活 server／有 socket 都算占）⇒
#      需要引"号"的地方一律引**当场取到的那个数**，并把它打进判词。
#
# 【两极化】正极＝装置在册（各腿 `want`）；反极＝**真跑**装置副本的**逐字节破坏版**
#   （见 `~/w183a/polarity.md` 与 `run-polarity.sh`：4 条反极腿，每条先断言 `hits>=1`）。
#
# 【本牙自己的接线状态】**未接线**（本波＝预备包；落地由主控排波）。⚠️ 本件**不**自称"接线完成"——
#   仓内已有牙件因自述与接线不符被 `SELFDESC-WIRING` 抓过（`D-G136`）。
#
# 用法：bash display-lease-gate.sh [--dev <装置路径>] [--static|--dynamic|--both] [--keep]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

RC_PASS=0; RC_FAIL=1; RC_NOINFO=3; RC_USAGE=4
SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEV="${DISPLAY_LEASE_DEV:-}"
if [ -z "$DEV" ]; then
  # 落地后的位置＝本牙的同目录；预备包里装置在 `new/`（下一条只是**路径解析**，不改判据）
  for c in "$SELF_DIR/display-lease.sh" "$SELF_DIR/../new/display-lease.sh"; do
    [ -r "$c" ] && { DEV="$(readlink -f -- "$c")"; break; }
  done
fi
[ -n "$DEV" ] || DEV="$SELF_DIR/display-lease.sh"
FACE="both"; KEEP=0
AT="$(date -Is)"

say() { printf '%s\n' "$*"; }
noinfo() { say "DISPLAY_LEASE_GATE=NOINFO reason=$1 ${2:-}"; exit $RC_NOINFO; }
usage_fail(){ say "DISPLAY_LEASE_GATE=FAIL reason=usage:$1"; exit $RC_USAGE; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dev)   DEV="${2:-}"; shift 2 ;;
    --static) FACE="static"; shift ;;
    --dynamic) FACE="dynamic"; shift ;;
    --both)  FACE="both"; shift ;;
    --keep)  KEEP=1; shift ;;
    -h|--help) say "用法: display-lease-gate.sh [--dev <装置>] [--static|--dynamic|--both] [--keep]"; exit 0 ;;
    *) usage_fail "unknown-arg:$1" ;;
  esac
done

[ -r "$DEV" ] || noinfo "device-absent" "path=$DEV"
command -v xdpyinfo >/dev/null 2>&1 || noinfo "xdpyinfo-absent" "（动态面判不了"号真活了没有"）"
DEV_SHA16="$(sha256sum "$DEV" | cut -c1-16)"
say "LEASE_DEV_SHA16=$DEV_SHA16 dev=$DEV at=$AT"
if [ "$FACE" != "static" ]; then
  case "$DEV_SHA16" in
    "$(sha256sum "$SELF_DIR/display-lease.sh" 2>/dev/null | cut -c1-16)") say "LEASE_DEV_IS_INREPO_COPY=yes sha16=$DEV_SHA16" ;;
    *) say "LEASE_DEV_IS_INREPO_COPY=no sha16=$DEV_SHA16（装置副本 ⇒ 反极腿用）" ;;
  esac
fi

# `LEASE_GATE_RIG=<dir>` ⇒ 用**固定**工作目录（反极腿要跨"正极/反极"两次运行共用同一套 fixture）
if [ -n "${LEASE_GATE_RIG:-}" ]; then WORK="$LEASE_GATE_RIG"; mkdir -p "$WORK"
else WORK="$(mktemp -d "${TMPDIR:-/tmp}/w183a-lease.XXXXXX")"; fi
PIDFILE="$WORK/own.pids"; : > "$PIDFILE"
LDIR="$WORK/leases"; mkdir -p "$LDIR"
# 持有者：一个**长寿**进程 ⇒ 租约写的是"活着的 PID"，判词可复算（不用子 shell 自己的 $$）
sleep 900 >/dev/null 2>&1 & HOLDER=$!
printf '%s\n' "$HOLDER" >> "$PIDFILE"

cleanup() {
  # 只按 PID 收自己起的东西（`D-G103`：**禁** pgrep／pkill／pgrep -f）
  local p
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    kill "$p" 2>/dev/null || true
  done < "$PIDFILE"
  # ⚠️ **不许**裸 `wait`（会等所有后台作业 ⇒ 卡在睡眠的持有者上，本车道自伤一次）
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    timeout 2 tail --pid="$p" -f /dev/null 2>/dev/null || true   # 有上限的"回收确认"（**不用裸 wait**）
  done < "$PIDFILE"
  if [ "$KEEP" -eq 1 ] || [ -n "${LEASE_GATE_RIG:-}" ]; then :; else rm -rf -- "$WORK"; fi
}
trap cleanup EXIT

N_STATIC=0; P_STATIC=0; N_DYN=0; P_DYN=0; EXAMINED=0

J() { # J <face> <name> <want_rc> <must> <mustnot> <out> <rc> [counter]
  local face="$1" name="$2" want="$3" must="$4" mustnot="$5" out="$6" rc="$7"
  local ok=1 why=""
  EXAMINED=$((EXAMINED+1))
  [ "$rc" = "$want" ] || { ok=0; why="$why rc=$rc(want=$want)"; }
  if [ "$must" != "-" ] && [ "$must" != "IGNORED" ]; then grep -qE "$must" <<<"$out" || { ok=0; why="$why missing:$must"; }; fi
  if [ "$mustnot" != "-" ]; then grep -qE "$mustnot" <<<"$out" && { ok=0; why="$why unexpected:$mustnot"; }; fi
  if [ "$face" = static ]; then N_STATIC=$((N_STATIC+1)); [ $ok -eq 1 ] && P_STATIC=$((P_STATIC+1))
  else N_DYN=$((N_DYN+1)); [ $ok -eq 1 ] && P_DYN=$((P_DYN+1)); fi
  say "LEASE_GATE case=$name face=$face want_rc=$want got_rc=$rc => $([ $ok -eq 1 ] && echo OK || echo NO)$why"
}
finalize() {
  say "LEASE_GATE_COUNTS static=$P_STATIC/$N_STATIC dynamic=$P_DYN/$N_DYN examined=$EXAMINED at=$(date -Is)"
  if [ "$EXAMINED" -eq 0 ]; then say "DISPLAY_LEASE_GATE=FAIL reason=examined-zero（一条腿都没跑 ⇒ 假绿方向）"; exit $RC_FAIL; fi
  if [ "$P_STATIC" = "$N_STATIC" ] && [ "$P_DYN" = "$N_DYN" ]; then
    say "DISPLAY_LEASE_GATE=PASS static=$P_STATIC/$N_STATIC dynamic=$P_DYN/$N_DYN examined=$EXAMINED dev_sha16=$DEV_SHA16"
    exit $RC_PASS
  fi
  say "DISPLAY_LEASE_GATE=FAIL static=$P_STATIC/$N_STATIC dynamic=$P_DYN/$N_DYN examined=$EXAMINED dev_sha16=$DEV_SHA16"
  exit $RC_FAIL
}

# ── 静态面：装置自测（fixture 注入 ⇒ 不碰真机进程）────────────────────────────
static_face() {
  local out rc ex
  out="$(DISPLAY_LEASE_DIR="$WORK/static-leases" bash "$DEV" --selftest 2>&1)"; rc=$?
  say "$out"
  J static dev-selftest 0 'LEASE_SELFTEST=PASS pass=[0-9]+ fail=0' 'LEASE_SELFTEST=FAIL' "$out" "$rc"
  ex="$(grep -oE 'examined=[0-9]+' <<<"$out" | tail -1 | cut -d= -f2)"
  say "LEASE_GATE_SELFTEST_EXAMINED=${ex:-<none>}（判据：>=15；取不到或 0 ⇒ 红）"
  local ok=1
  case "${ex:-0}" in ''|0) ok=0;; esac
  [ "${ex:-0}" -ge 15 ] 2>/dev/null || ok=0
  say "LEASE_GATE_COUNTER_CHECK selftest_examined=${ex:-none} want_min=15 verdict=$([ $ok -eq 1 ] && echo OK || echo NO)"
  J static dev-selftest-counter $([ $ok -eq 1 ] && echo 0 || echo 1) 'IGNORED' '-' "$out" $([ $ok -eq 1 ] && echo 0 || echo 1)
  # 逃逸自证：判据＝**我点名的目标路径**一个都没被创建（窄窗对账逐条可见；别的车道在飞不算我写入）
  J static dev-selftest-no-R-write 0 'ESCAPE_GATE_OK .*目标路径均未被创建|mine_paths_present=0' '❌' "$out" "$rc"
}

# ── 动态面：真跑（真 Xvfb／真 sleep／真并发）──────────────────────────────────
ACQ() { # ACQ <tag> <pool|:N> ⇒ rc；stdout 落 $WORK/dyn/<tag>.out
  local tag="$1" sel="$2" flag="--pool"
  case "$sel" in :*) flag="--display" ;; esac
  DISPLAY_LEASE_DIR="$LDIR" bash "$DEV" acquire "$flag" "$sel" --lane W183A --job "$tag" --holder-pid "$HOLDER" > "$WORK/dyn/$tag.out" 2>&1
  printf '%s' "$?" > "$WORK/dyn/$tag.rc"
  cp -f "$WORK/dyn/$tag.out" "${LEASE_GATE_LOG_DIR:-$WORK/logs}/$tag.out" 2>/dev/null || true
}
disp_of() { grep -oE 'display=:[0-9]+' "$1" 2>/dev/null | head -1 | cut -d= -f2; }
newpid() { sleep 900 >/dev/null 2>&1 & local p=$!; printf '%s\n' "$p" >> "$PIDFILE"; printf '%s' "$p"; }

dynamic_face() {
  local od="$WORK/dyn"; mkdir -p "$od"
  # 逐腿 stdout 留档（**可复算**：`--keep` 之外也留一份，落 $LEASE_GATE_LOG_DIR 或 $WORK）
  local LOGD="${LEASE_GATE_LOG_DIR:-$WORK/logs}"; mkdir -p "$LOGD"; say "LEASE_GATE_LOG_DIR=$LOGD"
  local rc1 rc2 d1 d2 keep_live

  # ── D1 并发两趟取号 ⇒ **号必不相同** ────────────────────────────────────────
  ACQ j1 "236:239" & local a1=$!
  ACQ j2 "236:239" & local a2=$!
  wait $a1; wait $a2
  rc1="$(cat "$od/j1.rc")"; rc2="$(cat "$od/j2.rc")"
  d1="$(disp_of "$od/j1.out")"; d2="$(disp_of "$od/j2.out")"
  d1="${d1:-<none>}"; d2="${d2:-<none>}"
  say "LEASE_GATE_D1_CONCURRENT rc1=$rc1 rc2=$rc2 disp1=$d1 disp2=$d2 holder_pid=$HOLDER（**号由装置现取，非写死**）"
  local a_ok=0
  grep -qE '^DISPLAY_LEASE=ACQUIRED .*prior_absent=1 exclusive_now=1' "$od/j1.out" && \
  grep -qE '^DISPLAY_LEASE=ACQUIRED .*prior_absent=1 exclusive_now=1' "$od/j2.out" && a_ok=0 || a_ok=1
  J dyn D1a-both-succeed 0 'IGNORED' '-' "both_succeed=$([ $a_ok -eq 0 ] && echo 1 || echo 0) rc1=$rc1 rc2=$rc2 out1=$(head -1 "$od/j1.out" | cut -c1-120) out2=$(head -1 "$od/j2.out" | cut -c1-120)" $a_ok
  local distinct=0
  { [ "$d1" != "<none>" ] && [ "$d2" != "<none>" ] && [ "$d1" != "$d2" ]; } || distinct=1
  J dyn D1b-numbers-distinct 0 'IGNORED' '-' "distinct_verdict=$([ $distinct -eq 0 ] && echo distinct || echo SAME) disp1=$d1 disp2=$d2" $distinct
  # 租约文件必须**逐号到场**且 pid 是持有者（不是子 shell 的 $$）
  local lf lreal
  lf="$(find "$LDIR" -maxdepth 1 -name 'display-*.lease' | LC_ALL=C sort)"
  lreal="$(printf '%s\n' "$lf" | grep -c . || true)"
  say "LEASE_GATE_D1_LEASES n=$lreal 逐件: $(printf '%s ' $lf)"
  J dyn D1c-leases-written 0 "^pid=$HOLDER$" '-' "$(cat $lf 2>/dev/null)" $([ "$lreal" = 2 ] && echo 0 || echo 1)

  # reap 在持有者**活着**时不许收（按 PID 判活）
  keep_live="$(DISPLAY_LEASE_DIR="$LDIR" bash "$DEV" reap 2>&1)"; local kr=$?
  say "$keep_live"
  J dyn D1d-reap-keeps-live-holder 0 'DISPLAY_LEASE_KEEP .*reason=pid-alive' 'DISPLAY_LEASE=REAPED' "$keep_live" $kr
  rm -f "$LDIR"/display-*.lease

  # ── D2 同号并发（点名 `:238`）⇒ **恰一个**成功 ──────────────────────────────
  ACQ k1 ":238" & local b1=$!
  ACQ k2 ":238" & local b2=$!
  wait $b1; wait $b2
  rc1="$(cat "$od/k1.rc")"; rc2="$(cat "$od/k2.rc")"
  # ⚠️【本车道自伤留档 · bash 陷阱】原来写的是 `local okc=1` ＋ `{…} || {…} || okc=0`：
  #   `local` **是成功的命令** ⇒ `||` 链在 `local okc=1` 处就成功收尾，`okc=0` **从不执行**
  #   ⇒ 腿**明明全对**却判红（本仓同族：`local x="$(cmd)"` 的 `$?` 是 `local` 的）。
  local okc=1
  if { [ "$rc1" = 0 ] && [ "$rc2" = 1 ]; } || { [ "$rc1" = 1 ] && [ "$rc2" = 0 ]; }; then okc=0; fi
  say "LEASE_GATE_D2_SAME rc1=$rc1 rc2=$rc2 exactly_one_success=$([ $okc -eq 0 ] && echo 1 || echo 0)"
  local loser="" winner="" c1f c2f c1a c2a
  c1f="$(grep -cE '^DISPLAY_LEASE=FAIL reason=held-by-live-pid display=:238' "$od/k1.out" || true)"
  c2f="$(grep -cE '^DISPLAY_LEASE=FAIL reason=held-by-live-pid display=:238' "$od/k2.out" || true)"
  c1a="$(grep -cE '^DISPLAY_LEASE=ACQUIRED display=:238 .*prior_absent=1 exclusive_now=1' "$od/k1.out" || true)"
  c2a="$(grep -cE '^DISPLAY_LEASE=ACQUIRED display=:238 .*prior_absent=1 exclusive_now=1' "$od/k2.out" || true)"
  say "LEASE_GATE_D2_GREP k1_fail=$c1f k2_fail=$c2f k1_acq=$c1a k2_acq=$c2a k1_head=[$(head -1 "$od/k1.out" | cut -c1-90)] k2_head=[$(head -1 "$od/k2.out" | cut -c1-90)]"
  case "$c1f" in ''|0) ;; *) loser="k1" ;; esac
  case "$c2f" in ''|0) ;; *) loser="$loser k2" ;; esac
  case "$c1a" in ''|0) ;; *) winner="$winner k1" ;; esac
  case "$c2a" in ''|0) ;; *) winner="$winner k2" ;; esac
  say "LEASE_GATE_D2_SPLIT winner=[${winner# }] reason_named=[${loser# }]（'」'reason='」' 形态只作**诊断**，见下）"
  # ⚠️【判据口径 · 本车道现场修正（实测两次不同形态）】"同号并发"里**失者**的判词有两种**都合法**的形态：
  #   ① `held-by-live-pid`（失者看到了那趟在飞同行的**租约文件**）
  #   ② `pool-exhausted`（失者看到的是**占位目录**、`owner` 是活着的同行 ⇒ 按互斥语义**跳过该号**，
  #      池内再无可占号 ⇒ 响亮失败）
  #   ⇒ 判据不许钉在措辞上；要害＝**"恰一个拿到 :238 的租约"**（下面用 `k?_acq` 的**计数器**判）。
  local split_ok=0 w_n=0
  w_n="$(printf '%s' "$winner" | wc -w)"
  [ "$w_n" = 1 ] || split_ok=1
  say "LEASE_GATE_D2_COUNTER winner_n=$w_n split_ok=$split_ok okc=$okc（判据＝恰一个 '」'ACQUIRED display=:238'」'）"
  # ⚠️ 判据口径（本车道现场修正）：**号池请求**在"该号被在飞同行占位"时的正确行为是
  #   **换下一个池内号**（不是红）——所以本题的"失者"判词允许 `pool-exhausted`（池内再无可占号）。
  #   要害不在判词措辞，而在**可复算的独占证据**：失者**没有**拿到 `:238` 的租约。
  local l2=""
  case "$c1a" in ''|0) l2="$l2 k1";; esac
  case "$c2a" in ''|0) l2="$l2 k2";; esac
  local l2n; l2n="$(printf '%s' "$l2" | wc -w)"
  say "LEASE_GATE_D2_NONWINNER=[${l2# }] n=$l2n（判据：恰 1 个腿**没有**拿到 :238 的租约）"
  # ⚠️ 本车道自伤留档：上面这里曾漏写 `local`（`d2rc=0` 污染外层同名变量）⇒ 腿**明明全对却判红**
  local d2rc=0
  if [ "$split_ok" != 0 ] || [ "$okc" != 0 ] || [ "$l2n" != 1 ]; then d2rc=1; fi
  J dyn D2a-exactly-one-wins 0 'IGNORED' '-' "winner=[${winner# }] loser=[${loser# }] split_ok=$split_ok okc=$okc nonwinner_n=$l2n rc1=$rc1 rc2=$rc2 out1=$(head -1 "$od/k1.out" | cut -c1-110) out2=$(head -1 "$od/k2.out" | cut -c1-110)" "$d2rc"
  local nl; nl="$(find "$LDIR" -maxdepth 1 -name 'display-238.lease' | grep -c . || true)"
  J dyn D2b-only-one-lease 0 'IGNORED' '-' "lease_files_for_238=$nl must_be_1" $([ "$nl" = 1 ] && echo 0 || echo 1)
  rm -f "$LDIR"/display-*.lease

  # ── D3 死租约 ⇒ reap 必回收并点名；回收后同号可取 ───────────────────────────
  printf 'display=:237\npid=4000000\nlstart=proc-gone\nlane=deadlane\njob=deadjob\nclaim_epoch=1\nsocket_absent=1\ngeom=1280x1024x24\n' > "$LDIR/display-237.lease"
  local r3; r3="$(DISPLAY_LEASE_DIR="$LDIR" bash "$DEV" reap 2>&1)"; local rc3=$?
  say "$r3"
  J dyn D3a-reap-dead-lease 0 'DISPLAY_LEASE=REAPED display=:237 pid=4000000 lstart_match=1' 'FAIL' "$r3" "$rc3"
  ACQ after-reap ":237"; local rc4; rc4="$(cat "$od/after-reap.rc")"
  say "$(cat "$od/after-reap.out")"
  J dyn D3b-acquire-after-reap 0 'DISPLAY_LEASE=ACQUIRED display=:237 prior_absent=1' 'FAIL' "$(cat "$od/after-reap.out")" "$rc4"
  rm -f "$LDIR"/display-*.lease

  # ── D4 真·占号（真 Xvfb）＋ 活 PID 租约 ⇒ 必显式失败点名 ────────────────────
  Xvfb :239 -screen 0 1280x1024x24 > "$WORK/xvfb239.log" 2>&1 </dev/null &
  local xp=$!; printf '%s\n' "$xp" >> "$PIDFILE"
  sleep 2
  DISPLAY=:239 xdpyinfo >/dev/null 2>&1 || noinfo "xvfb-not-up" "display=:239 log=$WORK/xvfb239.log dims_want=1280x1024"
  say "FIXTURE_PROOF pid=$xp display=:239 live=$([ -d "/proc/$xp" ] && echo 1 || echo 0) kind=Xvfb dims=$(DISPLAY=:239 xdpyinfo | sed -n 's/^ *dimensions: *\([0-9x]*\).*/\1/p')"
  ACQ ext ":239"; local rc5; rc5="$(cat "$od/ext.rc")"
  say "$(cat "$od/ext.out")"
  J dyn D4a-external-occupant-refused 1 'reason=occupied-without-lease display=:239 occupants=[1-9]' 'DISPLAY_LEASE=ACQUIRED display=:239' "$(cat "$od/ext.out")" "$rc5"
  local sp sl
  sp="$(newpid)"; sl="$(ps -o lstart= -p "$sp" | sed -e 's/^ *//' -e 's/ *$//')"
  printf 'display=:239\npid=%s\nlstart=%s\nlane=otherlane\njob=J\nclaim_epoch=1\nsocket_absent=0\ngeom=1280x1024x24\n' "$sp" "$sl" > "$LDIR/display-239.lease"
  say "FIXTURE_PROOF pid=$sp display=:239 live=$([ -d "/proc/$sp" ] && echo 1 || echo 0) kind=sleep lstart='$sl'"
  ACQ live ":239"; local rc6; rc6="$(cat "$od/live.rc")"
  say "$(cat "$od/live.out")"
  J dyn D4b-live-lease-named 1 "reason=held-by-live-pid display=:239 holder_pid=$sp holder_lane=otherlane" 'DISPLAY_LEASE=ACQUIRED' "$(cat "$od/live.out")" "$rc6"
  kill "$sp" "$xp" 2>/dev/null || true; wait "$sp" 2>/dev/null || true; wait "$xp" 2>/dev/null || true; sleep 0.3
  say "FIXTURE_TEARDOWN sleep_pid=$sp x_pid=$xp sleep_live=$([ -d "/proc/$sp" ] && echo 1 || echo 0) x_live=$([ -d "/proc/$xp" ] && echo 1 || echo 0)"
  rm -f "$LDIR"/display-*.lease

  # ── D5 socket 槽位（无 server、无租约）⇒ 必拒（"泄漏的显示位优先占坑"要响亮） ─
  if [ -w /tmp/.X11-unix ]; then
    if : > "/tmp/.X11-unix/X236" 2>/dev/null; then
      ACQ slot ":236"; local rc7; rc7="$(cat "$od/slot.rc")"
      say "$(cat "$od/slot.out")"
      J dyn D5-socket-slot-refused 1 'reason=occupied-without-lease display=:236' 'DISPLAY_LEASE=ACQUIRED display=:236' "$(cat "$od/slot.out")" "$rc7"
      rm -f "/tmp/.X11-unix/X236"
      say "FIXTURE_TEARDOWN socket=/tmp/.X11-unix/X236 present=$([ -e /tmp/.X11-unix/X236 ] && echo yes || echo no)"
    else
      say "LEASE_GATE case=D5-socket-slot-refused face=dyn => SKIP（/tmp/.X11-unix 写不进）"
    fi
  else
    say "LEASE_GATE case=D5-socket-slot-refused face=dyn => SKIP（/tmp/.X11-unix 不可写）"
  fi
}

[ "$FACE" = dynamic ] || static_face
[ "$FACE" = static ] || dynamic_face
finalize
