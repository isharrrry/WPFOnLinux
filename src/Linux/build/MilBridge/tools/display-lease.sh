#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# display-lease.sh —— **显示号租借**装置（`TASK-0739` 残留③；车道 `W183A`，预备包）
#
# 【它挡的是什么】并发车道各按"约定俗成"挑 `:23x`／`:97` 一类显示号，**没有租借/占位机制**
#   ⇒ 两趟重活可能挑到同一个号（`Xvfb` 已占则第二趟起不来或起在别处，判据随之失真），
#   且**泄漏的显示位优先占坑**会让后来者**静默换号**（`TASK-0739` 原文；`D-G130` 实例②同族）。
#
# 【判据（**先写死在 `criteria.md`，本件只是执行者**）】
#   rc=0  `DISPLAY_LEASE=ACQUIRED … prior_absent=1 exclusive_now=1 …`
#          绿 = 号拿到手，且**两条独立证明**齐：①占位动作**原子成功**（"前无来者"是**操作结果**、
#          不是**观察结论**——`D-G130②`：判据输入不许取自瞬时状态）②占位后当场复核"除我无人持此号"。
#   rc=1  `DISPLAY_LEASE=FAIL reason=<具名>`   红 = **显式失败**：被别人持有／被外部进程占／
#          租约畸形／池空／不是自己的租约。（**绝不静默换号**——这是本装置存在的理由。）
#   rc=3  `DISPLAY_LEASE=NOINFO reason=<具名>` 算不出：`/proc` 不可读／`ps` 空／socket 目录缺失／
#          租赁目录不可写／`lstart` 取不到。**空边必须响亮失败**（纪律 27：一条都没读到 ≠ 没有占用）。
#   rc=4  用法错 或 **逃逸闸拒跑**（见下）。
#
# 【只按 PID 判活】`/proc/<pid>` 存在性 ＋ `ps -o pid= -p <pid>`（**不加 `-e`**）。
#   **禁** `pgrep`／`pgrep -f`／`pkill`／`pkill -f`（`D-G103`：按模式匹配会自匹配杀掉自己/祖先链）。
#   另按 **`lstart`** 挡 PID 复用：租约里的 PID 现在活着、但启动时刻与租约不符 ⇒ **不是**我的持有者。
#
# 【逃逸闸（**纪律 47**；本车道 `$R` 零写入的执行机制）】
#   凡**写入**路径（租赁目录）都过两闸：①字面前缀 `case "$X" in "$R"/*) exit 4` ②`readlink -f`
#   **解析后**前缀闸（防符号链接越界）。拒跑必打逐字判词且**写入件数 0**。
#
# 【输入来源声明（纪律 36；现取不缓存；`D-G140` 口径）】活 server=`ps -eo pid=,args=` 现取（只认
#   `args` **行首** `Xvfb :<N>`）；存活=`/proc`＋`ps -o pid= -p`；启动时刻=`ps -o lstart= -p`；
#   socket=`/tmp/.X11-unix/` 现取目录成员；租约=`$DISPLAY_LEASE_DIR` 现读。输出带 `LEASE_AT=`／`LEASE_SRC=`。
#
# 【测试钩子】`DISPLAY_LEASE_DIR`／`X_SOCK_DIR`／`DISPLAY_LEASE_PS_FILE`（fixture 注入 ⇒ 不碰真机）。
#   用法: display-lease.sh acquire --pool 230:239 [--lane L] [--job J] [--display :N] [--json-ish]
#         display-lease.sh release --display :N | --all-mine
#         display-lease.sh renew|verify --display :N
#         display-lease.sh reap [--dry] [--force :N] ; list ; --selftest
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

RC_OK=0; RC_FAIL=1; RC_NOINFO=3; RC_USAGE=4

R_DEFAULT="/home/links-dev/netTest/GitProj/WPFOnLinux"
R="${R:-$R_DEFAULT}"
LEASE_DIR="${DISPLAY_LEASE_DIR:-$HOME/.display-lease}"
X_SOCK_DIR="${X_SOCK_DIR:-/tmp/.X11-unix}"
PS_FILE="${DISPLAY_LEASE_PS_FILE:-}"
POOL_RE='^:?23[0-9]$'          # 号池白名单：私有显示只有 :23x 族
DEFAULT_POOL="230:239"
GEOM_REQ="1280x1024x24"

AT="$(date -Is)"
# ⚠️ 本装置**不按模式扫 `/proc`**：一律 `ps -o pid= -p <pid>` ＋ `/proc/<pid>` 存在性（**只按 PID**）。
#   下面这行只是**读数来源描述串**（`PROCGUARD` 会把其中的字面量当扫描现场 ⇒ 改写成不歧义的措辞）。
SRC_DESC="ps-pid-existence + proc-pid-cmdline-by-pid + $X_SOCK_DIR + $LEASE_DIR"
say() { printf '%s\n' "$*"; }
fail()  { say "DISPLAY_LEASE=FAIL reason=$1 ${2:-}"; exit $RC_FAIL; }
noinfo(){ say "DISPLAY_LEASE=NOINFO reason=$1 ${2:-}"; exit $RC_NOINFO; }
usage_fail(){ say "DISPLAY_LEASE=FAIL reason=usage:$1"; exit $RC_USAGE; }
T16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }

# ── ① 逃逸闸（**两闸**；只对写入侧 = 租赁目录）────────────────────────────────
escape_gate() {   # escape_gate <path> <what>
  local X="$1" what="$2" RX
  case "$X" in
    "$R"/*) say "DISPLAY_LEASE=FAIL reason=escape-gate-literal target=$X R=$R what=$what（拒跑：目标落在权威树内）"; exit $RC_USAGE ;;
  esac
  RX="$(readlink -f -- "$X" 2>/dev/null || true)"
  [ -n "$RX" ] || RX="$X"
  case "$RX" in
    "$R"|"$R"/*) say "DISPLAY_LEASE=FAIL reason=escape-gate-resolved target=$X resolved=$RX R=$R what=$what（拒跑：解析后落在权威树内，符号链接越界）"; exit $RC_USAGE ;;
  esac
}

# ── ② 输入来源闸（**空边响亮失败**）───────────────────────────────────────────
src_guard() {     # 成功 ⇒ 导出 PS_RAW / PS_N；失败 ⇒ NOINFO 退场
  if [ ! -r /proc/self/cmdline ]; then noinfo "proc-unreadable" "dir=/proc"; fi
  PS_RAW="$(if [ -n "$PS_FILE" ]; then cat "$PS_FILE" 2>/dev/null; else ps -eo pid=,args= 2>/dev/null; fi)"
  PS_N="$(printf '%s\n' "$PS_RAW" | grep -c . || true)"
  if [ "${PS_N:-0}" -eq 0 ]; then
    noinfo "proc-unreadable-or-ps-empty" "src=${PS_FILE:-ps -eo pid=,args=}"
  fi
  if [ ! -d "$X_SOCK_DIR" ]; then noinfo "sock-dir-absent" "dir=$X_SOCK_DIR"; fi
}

# ── ③ 只按 PID 的判活与启动时刻（**禁模式匹配**）──────────────────────────────
pid_alive() {     # 0 = 活
  local p="$1"
  [ -n "$p" ] || return 1
  case "$p" in ''|*[!0-9]*) return 1;; esac
  [ -d "/proc/$p" ] || return 1
  local o; o="$(ps -o pid= -p "$p" 2>/dev/null | tr -d ' \n')"
  [ "$o" = "$p" ]
}
lstart_of() {     # ⇒ 逐字 lstart（取不到 ⇒ 空）
  local p="$1" o=""
  [ -n "$p" ] || { printf ''; return 0; }
  o="$(ps -o lstart= -p "$p" 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$o"
}
start_epoch_of() { # ⇒ /proc/<pid>/stat 第 22 字段（starttime，jiffies）；取不到 ⇒ 空
  local p="$1"
  [ -r "/proc/$p/stat" ] || { printf ''; return 0; }
  awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+$/) { n++; if (n == 20) { print $i; exit } } }' "/proc/$p/stat" 2>/dev/null
}
lstart_ok() {     # lstart_ok <pid> <租约里的 lstart> ⇒ 0 = 相符
  local p="$1" want="$2" got
  got="$(lstart_of "$p")"
  [ -n "$got" ] || return 1
  [ -n "$want" ] || return 1
  [ "$got" = "$want" ]
}

# ── ④ 现取：活 server / socket / 外部占用者 ───────────────────────────────────
live_servers() {  # ⇒ 每行 `pid<TAB>:N`（只认 args **行首** `Xvfb :N`）
  printf '%s\n' "$PS_RAW" | awk '
    { pid=$1; sub(/^[ \t]+/, "", pid)
      args=$0; sub(/^[ \t]*[0-9]+[ \t]+/, "", args)
      if (args ~ /^Xvfb[ \t]+:[0-9]+/) {
        d=args; sub(/^Xvfb[ \t]+:/, "", d); sub(/[^0-9].*$/, "", d)
        if (pid ~ /^[0-9]+$/ && d != "") printf "%s\t:%s\n", pid, d
      } }'
}
own_chain() {     # ⇒ 本进程祖先链（含自身）的 PID，一行一个（**禁** pgrep）
  local p=$$ guard=0
  while [ -n "$p" ] && [ "$p" != "0" ] && [ "$guard" -lt 64 ]; do
    printf '%s\n' "$p"
    p="$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null)"
    guard=$((guard+1))
  done
}
CHAIN="$(own_chain | tr '\n' ' ')"
in_chain() { case " $CHAIN " in *" $1 "*) return 0;; esac; return 1; }

occupants_of() {  # occupants_of :N ⇒ 逐行 `pid<TAB>src`（src=server|socket），**排除我的祖先链**
  local n="$1" pid d found=0
  while IFS=$'\t' read -r pid d; do
    [ -z "${pid:-}" ] && continue
    [ "$d" = "$n" ] || continue
    in_chain "$pid" && continue
    printf '%s\tserver\n' "$pid"; found=1
  done <<< "$(live_servers)"
  [ -e "$X_SOCK_DIR/X${n#:}" ] && printf '%s\tsocket\n' "-"
  return 0
}
occupant_count() { occupants_of "$1" | grep -c . || true; }

# ── ⑤ 租约读写（**唯一真源** = 一个文件一个号）────────────────────────────────
lease_path() { printf '%s/display-%s.lease\n' "$LEASE_DIR" "${1#:}"; }
claim_dir()  { printf '%s/.claim-%s\n' "$LEASE_DIR" "${1#:}"; }

lease_write() {  # lease_write <:N> <pid> <lstart> <lane> <job> <claim_epoch> <socket_absent>
  local n="$1" p="$2" ls="$3" lane="$4" job="$5" ce="$6" sa="$7"
  local f; f="$(lease_path "$n")"; local t="$f.tmp.$$"
  { printf 'display=%s\n' "$n"
    printf 'pid=%s\n' "$p"
    printf 'lstart=%s\n' "$ls"
    printf 'lane=%s\n' "$lane"
    printf 'job=%s\n' "$job"
    printf 'claim_epoch=%s\n' "$ce"
    printf 'socket_absent=%s\n' "$sa"
    printf 'geom=%s\n' "$GEOM_REQ"
  } > "$t" || return 1
  mv -f -- "$t" "$f" || return 1
  chmod 0644 "$f" 2>/dev/null || true
  return 0
}
lease_read() {   # lease_read <:N> ⇒ 打 k=v 行；rc=0 正常 / 1 不存在 / 2 畸形
  local f; f="$(lease_path "$1")"
  [ -e "$f" ] || return 1
  [ -r "$f" ] || return 2
  # 形态硬判：必须 ≥6 行且每行 `k=v`、且四个必需键在、且值非空
  local bad=0 nk=0 k
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in *=*) nk=$((nk+1));; *) bad=1;; esac
  done < "$f"
  for k in display pid lstart lane job claim_epoch socket_absent; do
    grep -qx "$k=.*" "$f" || bad=1
    grep -q "^$k=$" "$f" && bad=1
  done
  [ "$nk" -ge 7 ] || bad=1
  [ "$bad" -eq 0 ] || return 2
  cat "$f"; return 0
}
lget() { local k="$1"; awk -F= -v k="$k" '$1==k{sub(/^[^=]*=/,"");print;exit}'; }

# ── ⑥ 号池 ────────────────────────────────────────────────────────────────────
pool_numbers() { # ⇒ 逐行 `:N`
  local lo="${POOL_LO}" hi="${POOL_HI}" i
  case "$lo$hi" in *[!0-9]*) return 1;; esac
  [ "$lo" -le "$hi" ] || return 1
  for ((i = lo; i <= hi; i++)); do printf ':%s\n' "$i"; done
}
pool_member() { case "$1" in :23[0-9]) return 0;; esac; return 1; }

# ── ⑦ 原子占位（**"前无来者"的证明就在这里**）─────────────────────────────────
claim_atomic() {  # 0 = 我占上（prior_absent=1）；1 = 已被占（EEXIST 语义）
  local c t; c="$(claim_dir "$1")"
  mkdir -- "$c" 2>/dev/null || return 1
  # ⚠️ `owner` 必须**原子出现**（temp ＋ rename）：否则并发的另一方可能读到"目录在、owner 空"
  #    ⇒ 误判"占位者已死"（本车道自伤族的第二种触发路径）。写不上 ⇒ **撤占位并返回失败**。
  t="$c/owner.tmp.$$"
  if printf '%s' "$$" > "$t" 2>/dev/null && mv -f -- "$t" "$c/owner" 2>/dev/null; then return 0; fi
  rm -rf -- "$c" 2>/dev/null || true
  return 1
}
claim_drop() { rm -rf -- "$(claim_dir "$1")" 2>/dev/null || true; }

selftest() {
  local T; T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
  local n=0 p=0
  local save_ld="$LEASE_DIR" save_sd="$X_SOCK_DIR" save_ps="$PS_FILE"
  run() { # run <name> <want_rc> <must> <mustnot> <argv…>
    local name="$1" want="$2" must="$3" mustnot="$4"; shift 4
    local out rc; out="$(bash "$0" "$@" 2>&1)"; rc=$?
    n=$((n+1)); local ok=1 why=""
    [ "$rc" = "$want" ] || { ok=0; why="$why rc=$rc(want $want)"; }
    [ "$must" = "-" ] || { grep -qE "$must" <<<"$out" || { ok=0; why="$why missing:$must"; }; }
    [ "$mustnot" = "-" ] || { grep -qE "$mustnot" <<<"$out" && { ok=0; why="$why unexpected:$mustnot"; }; }
    [ $ok -eq 1 ] && p=$((p+1))
    printf 'LEASE_SELFTEST case=%s want_rc=%s got_rc=%s => %s %s\n' "$name" "$want" "$rc" "$([ $ok -eq 1 ] && echo OK || echo NO)" "$why"
  }
  local LD="$T/leases" SD="$T/socks" PSF="$T/ps"; mkdir -p "$LD" "$SD"
  printf '  1 /sbin/init\n  2 [kthreadd]\n' > "$PSF"
  LEASE_DIR="$LD"; X_SOCK_DIR="$SD"; PS_FILE="$PSF"     # 装置内部函数用的是**全局**变量
  export DISPLAY_LEASE_DIR="$LD" X_SOCK_DIR="$SD" DISPLAY_LEASE_PS_FILE="$PSF"

  # S3 死租约 ⇒ acquire 拒、reap 收
  lease_write ":236" "4000000" "proc-gone" "deadlane" "deadjob" "1" "1"
  run S3a-dead-lease-acquire-refuses 1 'reason=stale-lease-needs-reap.*display=:236' 'ACQUIRED' acquire --display :236
  run S3b-reap-collects 0 'DISPLAY_LEASE=REAPED display=:236 pid=4000000 lstart_match=1' 'FAIL' reap
  run S3c-acquire-after-reap 0 'DISPLAY_LEASE=ACQUIRED display=:236 prior_absent=1 exclusive_now=1' 'FAIL' acquire --display :236
  # `release` 的"我的/别人的"判定要有一个**在本进程活着**的持有者：把租约的 pid 改成本 shell 的 `$$`
  #   （改动只发生在**自测的 fixture 租约**里；断言命中数，纪律 06）
  vbefore="$(grep -c '^pid=' "$LD/display-236.lease" || true)"
  sed -i "s/^pid=.*/pid=$$/" "$LD/display-236.lease"
  [ "$(grep -c '^pid=' "$LD/display-236.lease")" = "$vbefore" ] || { echo "SELFTEST_ASSERT ❌ pid 行数变了"; fail=1; }
  printf 'FIXTURE_PROOF kind=lease-pid-rewrite lease_pid=%s shell_pid=%s hits=%s\n' "$(lget pid < "$LD/display-236.lease")" "$$" "$vbefore"
  run S3d-release-other-pid-refused 1 'reason=not-my-lease display=:236' 'released=yes' release --display :236
  run S3e-release-mine 0 'DISPLAY_LEASE=RELEASED display=:236 released=yes' 'FAIL' release --display :236 --holder-pid $$
  run S3f-release-again-noop 0 'released=noop' 'FAIL' release --display :236

  # S4 畸形租约 ⇒ FAIL
  printf 'garbage\n' > "$LD/display-237.lease"
  run S4-malformed-lease 1 'reason=lease-malformed display=:237' 'ACQUIRED' acquire --display :237
  run S4b-malformed-leaves-file 0 'DISPLAY_LEASE_LIST' '-' list

  # S7 池空（237 畸形、236 已释放 ⇒ 只用 237:237 这一格）
  rm -f "$LD/display-237.lease"
  printf 'display=:237\npid=4000001\nlstart=x\nlane=L\njob=J\nclaim_epoch=1\nsocket_absent=1\n' > "$LD/display-237.lease"
  run S7-pool-exhausted 1 'reason=pool-exhausted pool=237:237' 'ACQUIRED' acquire --pool 237:237
  rm -f "$LD/display-237.lease"

  # S1 外部占用（socket 槽位在场、无租约）⇒ FAIL occupied-without-lease
  : > "$SD/X238"
  run S1-occupied-without-lease 1 'reason=occupied-without-lease display=:238' 'ACQUIRED' acquire --display :238
  rm -f "$SD/X238"

  # S5 源读不到（ps 空）⇒ NOINFO
  : > "$T/ps-empty"
  PS_FILE="$T/ps-empty"; export DISPLAY_LEASE_PS_FILE="$PS_FILE"
  run S5-ps-empty-noinfo 3 'DISPLAY_LEASE=NOINFO reason=proc-unreadable-or-ps-empty' 'ACQUIRED' acquire --pool 230:239
  PS_FILE="$PSF"; export DISPLAY_LEASE_PS_FILE="$PS_FILE"

  # S6 socket 目录不存在 ⇒ NOINFO（用不存在的 sock 目录）
  X_SOCK_DIR="$T/nodir"; export X_SOCK_DIR="$X_SOCK_DIR"
  run S6-sockdir-absent 3 'DISPLAY_LEASE=NOINFO reason=sock-dir-absent dir=' 'ACQUIRED' acquire --pool 230:239
  X_SOCK_DIR="$SD"; export X_SOCK_DIR="$X_SOCK_DIR"

  # 池外号被白名单挡住 ⇒ 用法/池口径（判 NOINFO pool-out-of-whitelist）
  run S8-pool-outside-whitelist 3 'NOINFO reason=pool-out-of-whitelist' 'ACQUIRED' acquire --display :99

  # S2 活 PID 持有 ⇒ FAIL held-by-live-pid（fixture 真起一个 sleep 并按 PID 自证）
  sleep 600 & local sp=$!
  local sl; sl="$(lstart_of "$sp")"
  lease_write ":239" "$sp" "$sl" "heldlane" "heldjob" "1" "1"
  printf 'FIXTURE_PROOF pid=%s live=%s kind=sleep\n' "$sp" "$(pid_alive "$sp" && echo 1 || echo 0)"
  run S2-held-by-live-pid 1 "reason=held-by-live-pid display=:239 holder_pid=$sp" 'ACQUIRED' acquire --display :239
  run S2b-reap-keeps-live 0 'kept_live=1' 'REAPED display=:239' reap
  kill "$sp" 2>/dev/null || true; wait "$sp" 2>/dev/null || true
  printf 'FIXTURE_TEARDOWN pid=%s live=%s\n' "$sp" "$(pid_alive "$sp" && echo 1 || echo 0)"
  run S2c-reap-after-kill 0 'DISPLAY_LEASE=REAPED display=:239' 'kept_live=1' reap
  rm -f "$LD/display-239.lease" "$LD/display-236.lease"

  # 逃逸闸：租赁目录指向权威树内 ⇒ rc=4 拒跑、写入件数 0
  # ⚠️【本车道自伤留档】第一版拿**整棵权威树**的 `find -newermt` 当"零写入"证据 ⇒ 别的车道同时在重建
  #   （现取 179 件新件）⇒ 该腿**恒红**（`before=25 after=26`）。判据必须**指向自己的目标**：
  #   ①逐字点名"我会写的那两个路径"（它们**必须都不存在**）②用**窄窗**对账（本腿前后各取一次，差异逐条打印）。
  local probe_dirs="$R/.w183a-escape-probe $R/.display-lease-work"
  local before after bl al mine_exists newfiles diff d
  mine_exists=0
  for d in $probe_dirs; do [ -e "$d" ] && mine_exists=$((mine_exists+1)); done
  before="$(find "$R" -newermt "$AT" -type f 2>/dev/null | LC_ALL=C sort)"
  LEASE_DIR="$R/.w183a-escape-probe"; export DISPLAY_LEASE_DIR="$LEASE_DIR"
  run E-escape-literal 4 'reason=escape-gate-literal' 'ACQUIRED' acquire --pool 230:231
  LEASE_DIR="$T/link-to-R"; export DISPLAY_LEASE_DIR="$LEASE_DIR"
  ln -sfn "$R" "$T/link-to-R"
  run E-escape-resolved 4 'reason=escape-gate-resolved' 'ACQUIRED' acquire --pool 230:231
  after="$(find "$R" -newermt "$AT" -type f 2>/dev/null | LC_ALL=C sort)"
  bl="$(printf '%s\n' "$before" | grep -c . || true)"; al="$(printf '%s\n' "$after" | grep -c . || true)"
  newfiles="$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | grep -c . || true)"
  for d in $probe_dirs; do [ -e "$d" ] && mine_exists=$((mine_exists+1)); done
  printf 'ESCAPE_GATE_R_WRITES window_before=%s window_after=%s mine_paths_present=%s probe_dirs=[%s]\n' \
    "$bl" "$al" "$mine_exists" "$probe_dirs"
  if [ "$newfiles" != 0 ]; then
    diff="$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | head -3 | tr '\n' ' ')"
    printf 'ESCAPE_GATE_NOTE 窗口内权威树新增 %s 件（**别的车道在飞 ⇒ 不算我的写入**，逐条可见以便归因）：%s\n' "$newfiles" "$diff"
  fi
  if [ "$mine_exists" = 0 ]; then p=$((p+1)); printf 'ESCAPE_GATE_OK ✅ 我点名的目标路径均未被创建（拒跑 ⇒ 写入件数 0）\n'
  else echo "ESCAPE_GATE ❌ 自测在权威树里创建了目标路径"; fi
  n=$((n+1))
  LEASE_DIR="$save_ld"; X_SOCK_DIR="$save_sd"; PS_FILE="$save_ps"; export DISPLAY_LEASE_DIR="$save_ld" X_SOCK_DIR="$save_sd" DISPLAY_LEASE_PS_FILE="$save_ps"
  echo "LEASE_SELFTEST=$([ "$p" -eq "$n" ] && echo PASS || echo FAIL) pass=$p fail=$((n-p)) examined=$n"
  [ "$p" -eq "$n" ] || exit 1
  exit 0
}

# ── 主流程 ────────────────────────────────────────────────────────────────────
CMD="${1:-}"; shift 2>/dev/null || true
[ "$CMD" = "--selftest" ] && selftest
[ -n "$CMD" ] || usage_fail "no-subcommand"

POOL="$DEFAULT_POOL"; WANT_DISP=""; LANE="${W183A_LANE:-${LANE:-unknown}}"; JOB="$$-$RANDOM"; DRY=0; FORCE=""; ALL_MINE=0; HOLDER_PID=""
while [ $# -gt 0 ]; do
  case "$1" in
    --pool)   POOL="${2:-}"; shift 2 ;;
    --display) WANT_DISP="${2:-}"; shift 2 ;;
    --lane)   LANE="${2:-}"; shift 2 ;;
    --job)    JOB="${2:-}"; shift 2 ;;
    --dry)    DRY=1; shift ;;
    --force)  FORCE="${2:-}"; shift 2 ;;
    --all-mine) ALL_MINE=1; shift ;;
    --holder-pid) HOLDER_PID="${2:-}"; shift 2 ;;
    --lease-dir) LEASE_DIR="${2:-}"; shift 2 ;;
    *) usage_fail "unknown-arg:$1" ;;
  esac
done
orphan_owner=""
POOL_LO="${POOL%%:*}"; POOL_HI="${POOL##*:}"
case "$POOL_LO$POOL_HI" in ''|*[!0-9]*) usage_fail "bad-pool:$POOL";; esac

# 持有者 PID：默认 $$；允许外层调用者用 --holder-pid 把"真正的长跑进程"交上来（例：`--holder-pid $$`
#   在子 shell 里调用本装置时把**外层 shell** 记成持有者）。⚠️ 给出者必须真活着且 lstart 可读。
if [ -z "$HOLDER_PID" ]; then HOLDER_PID="$$"; fi
case "$HOLDER_PID" in ''|*[!0-9]*) usage_fail "bad-holder-pid:$HOLDER_PID";; esac
if [ "$HOLDER_PID" != "$$" ]; then
  pid_alive "$HOLDER_PID" || fail "holder-pid-not-alive" "holder_pid=$HOLDER_PID my_pid=$$"
  [ -n "$(lstart_of "$HOLDER_PID")" ] || noinfo "holder-lstart-unavailable" "holder_pid=$HOLDER_PID"
fi

# 写入侧：逃逸闸（**在参数解析之后**由同一个 R 现推）
escape_gate "$LEASE_DIR" "lease-dir"
if [ "$DRY" -eq 0 ]; then
  mkdir -p -- "$LEASE_DIR" 2>/dev/null || noinfo "lease-dir-unwritable" "dir=$LEASE_DIR"
fi
LEASE_DIR="$(readlink -f -- "$LEASE_DIR" 2>/dev/null || printf '%s' "$LEASE_DIR")"

src_guard

case "$CMD" in
  list)
    n=0
    while IFS= read -r f; do
      [ -e "$f" ] || continue
      n=$((n+1)); say "DISPLAY_LEASE_ROW file=$(basename "$f") $(tr '\n' ' ' < "$f")"
    done <<< "$(find "$LEASE_DIR" -maxdepth 1 -name 'display-*.lease' 2>/dev/null | LC_ALL=C sort)"
    say "DISPLAY_LEASE_LIST=OK n=$n at=$AT src=$SRC_DESC"
    exit $RC_OK ;;
  acquire) ;;
  release|renew|verify)
    if [ "$ALL_MINE" -eq 1 ] && [ "$CMD" = "release" ]; then :; else
      [ -n "$WANT_DISP" ] || usage_fail "$CMD-needs--display"
      pool_member "$WANT_DISP" || noinfo "pool-out-of-whitelist" "display=$WANT_DISP whitelist=$POOL_RE"
    fi ;;
  reap) ;;
  *) usage_fail "unknown-subcommand:$CMD" ;;
esac

case "$CMD" in
  acquire)
    if [ -n "$WANT_DISP" ]; then
      pool_member "$WANT_DISP" || noinfo "pool-out-of-whitelist" "display=$WANT_DISP whitelist=$POOL_RE"
      candidates="$WANT_DISP"
    else
      candidates="$(pool_numbers)" || usage_fail "bad-pool:$POOL"
    fi
    chosen=""; prior_absent=0
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      pool_member "$d" || continue
      # 池内：无租约 ∧ 无活 server ∧ 无 socket 才算候选
      if [ -e "$(lease_path "$d")" ]; then continue; fi
      # 「有活 server／有 socket」的号在**号池扫描**里直接跳过（它不该被我占）。
      #   ⚠️ 只 **`--display` 点名**的路径**不**跳过，而要**响亮拒跑**（"泄漏的显示位优先占坑"
      #     必须可见）——那条路径的判词在下面 `occupied-without-lease` 分支里。
      if [ -z "$WANT_DISP" ] && [ "$(occupant_count "$d")" != "0" ]; then continue; fi
      # 【占位目录的两种形态：**只按 PID 判活**（口径与 §1.5 同源）】
      #   ① 占位者**活着** ⇒ 那是**在飞的同行**（租约还没落）⇒ **跳过该号**（互斥语义，不许抢）
      #   ② 占位者**已死** ⇒ 孤儿占位（崩在"占位之后、落租约之前"）⇒ 原子改名到 `.reap-<mine>-<rand>`
      #      后再试**一次** `mkdir`；`mkdir` 成功本身仍是"前无来者"的**操作证明**。
      #   ⚠️ 本车道自伤现场（已留档）：第一版把**任何**无租约占位都当孤儿 ⇒ 并发两趟**都**拿到同一个号
      #      （牙 D2 当场抓到 `winner=[k1 k2]`）——这正是 `polarity.md` 里"非原子占位"反极腿的真实形态。
      if ! claim_atomic "$d"; then
        orphan_owner="$(cat "$(claim_dir "$d")/owner" 2>/dev/null || echo unknown)"
        # ① 占位者**活着** ⇒ 在飞的同行 ⇒ 按互斥跳过该号（**绝不抢**）
        if [ "$orphan_owner" = "$$" ] || pid_alive "$orphan_owner"; then continue; fi
        # ② 占位者**已死**（或 owner 记录读不到）⇒ 试回收。⚠️ 回收必须**原子**且**只有一个赢家**：
        #    · `mv -T` 是原子的 ⇒ 两个并发者只有一个把那个目录挪走；
        #    · 挪走后**必须复核 `owner` 没变**（否则"我读到的那个死 owner"已被别人换过 ⇒ 放弃）；
        #    · 复核后**再**试一次 `mkdir`；成功本身仍是"前无来者"的**操作证明**。
        #    ⛔【本车道自伤留档 · 真实并发现场】第一版只做 `mv` 就 `mkdir` ⇒ 两个并发者**都**
        #      读到同一个死 owner、**都** `mv` 成功（第二次`mv`挪走的是对方新建的占位）⇒ **双双 ACQUIRED**
        #      （牙 D2 现取：`winner=[k1 k2]`，两行都印 `owner_pid=… reason=claim-owner-dead`）。
        local cur_owner
        mv -T -- "$(claim_dir "$d")" "$LEASE_DIR/.reap-$$-$RANDOM" 2>/dev/null || continue
        cur_owner="$(cat "$(claim_dir "$d")/owner" 2>/dev/null || echo unknown)"
        if [ "$cur_owner" != "$orphan_owner" ]; then continue; fi
        claim_atomic "$d" || continue
        say "DISPLAY_LEASE_ORPHAN_CLAIM_RECLAIMED display=$d owner_pid=$orphan_owner reason=claim-owner-dead recheck=owner-unchanged"
        rm -rf -- "$LEASE_DIR"/.reap-$$-* 2>/dev/null || true
      fi   # 到这里＝原子占位成功 ⇒ "前无来者"是**操作结果**、不是观察结论
      chosen="$d"; prior_absent=1; break
    done <<< "$candidates"

    if [ -z "$chosen" ]; then
      if [ -n "$WANT_DISP" ]; then
        # 指定号：逐条给出**为什么**不能要（点名，不静默换号）
        f="$(lease_path "$WANT_DISP")"
        if [ -e "$f" ]; then
          if lease_read "$WANT_DISP" >/dev/null 2>&1; then
            lr="$(lease_read "$WANT_DISP")"
            hp="$(printf '%s\n' "$lr" | lget pid)"; hl="$(printf '%s\n' "$lr" | lget lane)"
            hj="$(printf '%s\n' "$lr" | lget job)"; hls="$(printf '%s\n' "$lr" | lget lstart)"
            if pid_alive "$hp" && lstart_ok "$hp" "$hls"; then
              fail "held-by-live-pid" "display=$WANT_DISP holder_pid=$hp holder_lane=$hl holder_job=$hj my_pid=$$"
            elif ! pid_alive "$hp"; then
              fail "stale-lease-needs-reap" "display=$WANT_DISP holder_pid=$hp holder_lstart=$hls"
            else
              fail "lstart-mismatch-live-pid" "display=$WANT_DISP holder_pid=$hp want_lstart=$hls got_lstart=$(lstart_of "$hp")"
            fi
          else
            fail "lease-malformed" "display=$WANT_DISP detail=no-kv path=$f"
          fi
        fi
        c="$(occupant_count "$WANT_DISP")"
        if [ "$c" != "0" ]; then fail "occupied-without-lease" "display=$WANT_DISP occupants=$c"; fi
        fail "pool-exhausted" "pool=$POOL display=$WANT_DISP"
      fi
      fail "pool-exhausted" "pool=$POOL"
    fi

    # 原子占位成功后**当场复核独占面**（两条证明的第二条）
    c="$(occupant_count "$chosen")"
    if [ "$c" != "0" ]; then
      claim_drop "$chosen"
      fail "occupied-without-lease" "display=$chosen occupants=$c race=post-claim"
    fi
    sock_absent=0; [ -e "$X_SOCK_DIR/X${chosen#:}" ] || sock_absent=1
    OLSL="$(lstart_of "$HOLDER_PID")"
    if [ -z "$OLSL" ]; then claim_drop "$chosen"; noinfo "lstart-unavailable" "pid=$HOLDER_PID display=$chosen"; fi
    lease_write "$chosen" "$HOLDER_PID" "$OLSL" "$LANE" "$JOB" "$(date +%s)" "$sock_absent" \
      || { claim_drop "$chosen"; fail "lease-write-failed" "display=$chosen path=$(lease_path "$chosen")"; }
    # 复读回归（写进去的东西必须能读回来，纪律 06 同族：断言命中数）
    lr="$(lease_read "$chosen")" || { claim_drop "$chosen"; fail "lease-reread-failed" "display=$chosen"; }
    for k in display pid lstart lane job socket_absent; do
      grep -q "^$k=" <<< "$lr" || { claim_drop "$chosen"; fail "lease-reread-missing-key" "key=$k display=$chosen"; }
    done
    say "DISPLAY_LEASE=ACQUIRED display=$chosen prior_absent=$prior_absent exclusive_now=1 holder_pid=$HOLDER_PID lstart='$OLSL' lane=$LANE job=$JOB claim_epoch=$(date +%s) socket_absent=$sock_absent lease=$(lease_path "$chosen") LEASE_AT=$AT LEASE_SRC=$SRC_DESC"
    exit $RC_OK ;;

  release)
    if [ "$ALL_MINE" -eq 1 ]; then
      rel=0; noop=0; refuse=0
      while IFS= read -r f; do
        [ -e "$f" ] || continue
        d=":$(basename "$f" .lease | sed 's/^display-//')"
        lr="$(lease_read "$d" 2>/dev/null)" || { refuse=$((refuse+1)); say "DISPLAY_LEASE=FAIL reason=release-malformed display=$d"; continue; }
        hp="$(printf '%s\n' "$lr" | lget pid)"
        if [ "$hp" = "$HOLDER_PID" ]; then rm -f -- "$f"; rm -rf -- "$(claim_dir "$d")"; rel=$((rel+1)); say "DISPLAY_LEASE=RELEASED display=$d released=yes"
        else refuse=$((refuse+1)); say "DISPLAY_LEASE=FAIL reason=not-my-lease display=$d holder_pid=$hp my_pid=$HOLDER_PID"; fi
      done <<< "$(find "$LEASE_DIR" -maxdepth 1 -name 'display-*.lease' 2>/dev/null | LC_ALL=C sort)"
      say "DISPLAY_LEASE_RELEASE_ALL released=$rel refused=$refuse"
      [ "$refuse" -eq 0 ] || exit $RC_FAIL
      exit $RC_OK
    fi
    f="$(lease_path "$WANT_DISP")"
    if [ ! -e "$f" ]; then
      say "DISPLAY_LEASE=RELEASED display=$WANT_DISP released=noop rc_idempotent=0（租约不存在 ⇒ 幂等成功）"
      exit $RC_OK
    fi
    lr="$(lease_read "$WANT_DISP" 2>/dev/null)" || fail "release-malformed" "display=$WANT_DISP path=$f"
    hp="$(printf '%s\n' "$lr" | lget pid)"
    [ "$hp" = "$HOLDER_PID" ] || fail "not-my-lease" "display=$WANT_DISP holder_pid=$hp my_pid=$HOLDER_PID"
    rm -f -- "$f"; rm -rf -- "$(claim_dir "$WANT_DISP")"
    say "DISPLAY_LEASE=RELEASED display=$WANT_DISP released=yes holder_pid=$HOLDER_PID"
    exit $RC_OK ;;

  renew|verify)
    f="$(lease_path "$WANT_DISP")"
    [ -e "$f" ] || fail "no-lease" "display=$WANT_DISP"
    lr="$(lease_read "$WANT_DISP" 2>/dev/null)" || fail "lease-malformed" "display=$WANT_DISP path=$f"
    hp="$(printf '%s\n' "$lr" | lget pid)"; hl="$(printf '%s\n' "$lr" | lget lstart)"
    [ "$hp" = "$HOLDER_PID" ] || fail "not-my-lease" "display=$WANT_DISP holder_pid=$hp my_pid=$HOLDER_PID"
    lstart_ok "$hp" "$hl" || fail "lstart-mismatch" "display=$WANT_DISP holder_pid=$hp want=$hl got=$(lstart_of "$hp")"
    c="$(occupant_count "$WANT_DISP")"
    [ "$c" = "0" ] || fail "occupied-by-others" "display=$WANT_DISP occupants=$c"
    if [ "$CMD" = "renew" ]; then
      gp="$(lget geom < "$f")"
      lease_write "$WANT_DISP" "$hp" "$hl" "$(lget lane < "$f")" "$(lget job < "$f")" "$(date +%s)" "$(lget socket_absent < "$f")" || fail "renew-write-failed" "display=$WANT_DISP"
    fi
    say "DISPLAY_LEASE=$([ "$CMD" = renew ] && echo RENEWED || echo VERIFIED) display=$WANT_DISP holder_pid=$hp exclusive_now=1 geom=$GEOM_REQ"
    exit $RC_OK ;;

  reap)
    n=0; reaped=0; kept=0; noinfos=0
    while IFS= read -r f; do
      [ -e "$f" ] || continue
      n=$((n+1))
      d=":$(basename "$f" .lease | sed 's/^display-//')"
      if ! lr="$(lease_read "$d" 2>/dev/null)"; then
        noinfos=$((noinfos+1)); say "DISPLAY_LEASE=NOINFO reason=reap-lease-malformed display=$d path=$f"; continue
      fi
      hp="$(printf '%s\n' "$lr" | lget pid)"; hl="$(printf '%s\n' "$lr" | lget lstart)"
      if pid_alive "$hp"; then
        # PID 活着 ⇒ 不回收。**但要挡 PID 复用**（`D-G103` 族近亲）：这里按 lstart 只做**诊断**，
        # 只有"活着且 lstart 不符"才降级 NOINFO（那说明写租约的那个进程早已不在）。
        if ! lstart_ok "$hp" "$hl"; then
          noinfos=$((noinfos+1))
          say "DISPLAY_LEASE=NOINFO reason=live-pid-lstart-mismatch display=$d pid=$hp want_lstart=$hl got_lstart=$(lstart_of "$hp")（PID 复用嫌疑 ⇒ **不回收**）"
          continue
        fi
        kept=$((kept+1)); say "DISPLAY_LEASE_KEEP display=$d pid=$hp reason=pid-alive"; continue
      fi
      if ! lstart_ok "$hp" "$hl"; then
        # 死 PID 取不到 lstart 是**正常**（进程没了）⇒ 用租约里的标记判断：
        # 只有"标了 PID 复用嫌疑"才拒收
        case "$hl" in proc-reused) noinfos=$((noinfos+1)); say "DISPLAY_LEASE=NOINFO reason=pid-reuse-suspected display=$d pid=$hp（**不回收**，需人工 --force）"; continue;; esac
      fi
      c="$(occupant_count "$d")"
      if [ "$c" != "0" ]; then
        noinfos=$((noinfos+1)); say "DISPLAY_LEASE=NOINFO reason=socket-or-server-owned display=$d occupants=$c（不回收）"; continue
      fi
      if [ "$DRY" -eq 1 ]; then say "DISPLAY_LEASE_REAP_DRY display=$d pid=$hp would_reap=1"; reaped=$((reaped+1)); continue; fi
      rm -f -- "$f"; rm -rf -- "$(claim_dir "$d")"
      reaped=$((reaped+1)); say "DISPLAY_LEASE=REAPED display=$d pid=$hp lstart_match=1"
    done <<< "$(find "$LEASE_DIR" -maxdepth 1 -name 'display-*.lease' 2>/dev/null | LC_ALL=C sort)"
    say "DISPLAY_LEASE_REAP=OK examined=$n reaped=$reaped kept_live=$kept noinfo=$noinfos dry=$DRY"
    [ "$noinfos" -eq 0 ] || exit $RC_NOINFO
    exit $RC_OK ;;
esac
usage_fail "fell-through"
