#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# xvfb-census-check.sh —— 「**长跑自起的显示位/后台进程必须收尾收净并自查**」牙（`TASK-0739`／`D-G139`）
#
# 【它挡的是什么】
#   `verify-all` 的 `[0]` 段**自起 Xvfb 且跑完不收**（`ppid=1` 挂着）⇒ 无界慢性泄漏、
#   占**固定号**显示位、并让"零遗留进程"**不可判定**（每条车道自报只覆盖自己那一段）。
#   `#73` 前主控按 PID 清掉 **5 个跨波累积的孤儿显示位**（`:233`/`:234`/`:235`/`:99`/`:97`，最老 13 h14 m）。
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）】
#   rc=0  `X_CENSUS=PASS`     链前基线之后**没有**新增"不属于本趟"的存活显示位，也没有新增**无主** socket
#   rc=1  `X_CENSUS=FAIL`     逐条点名：`X_CENSUS_LEAK pid=… display=…`（新增存活显示位，非本趟）
#                             ／`X_CENSUS_ORPHAN_SOCK name=X…`（新增**无主** socket ⇒ 本趟留下的残渣）
#   rc=3  `X_CENSUS=NOINFO`   算不出：基线缺席/为空、`ps` 读不到、socket 目录不存在
#                             （**空边必须响亮失败**：纪律 27 —— "一条都没读到" ≠ "没有新增"）
#
#   ⛔ **两种"没进程的 socket"必须分开判**（本件的第一条真实实例：现取 `/tmp/.X11-unix/` 有
#      `X0 X1 X10 X239` 而 `ps` 上 `Xvfb :` **0 个** ⇒ `X239` 是**跨波残留的死 socket**）：
#        · **基线里就有** ⇒ `X_CENSUS_PREEXISTING_DEAD_SOCK name=…`：**具名可见、不判红**
#          （它早于本趟，**无法归因**给任何一趟；把它判红会让牙在干净机器上假红）；
#        · **基线上没有、现在有、且无主** ⇒ `FAIL reason=orphan-socket-residue`（那是**本趟留下的**）。
#   ⚠️ **口径限定**：本件的"有主/无主"只认 **`Xvfb`** 主人（`TASK-0739` 的对象就是长跑自起的 Xvfb）
#      ⇒ 一个由**别的** X server（如 `Xorg :0`）持有的 socket 会出现在
#      `X_CENSUS_PREEXISTING_DEAD_SOCK` 见证行里 —— **只是可见、不判红**（不冒充"无主"结论）。
#   ⛔ **本趟自起的显示位不算泄漏**（`--own-pid`／env `X_CENSUS_OWN_PIDS`）：它**在跑**、且由
#      `verify-all.sh` 的 `trap` 退出即按 PID 收 ⇒ 本件判的是"**除我自己的以外**有没有新增"。
#   ⛔ **复用的显示位永不判红、也永不被收**（`D-G59` 故意复用别人几何相符的显示）——
#      它**在基线里** ⇒ 既不进 `LEAK` 也不进 `own`。
#
# 【判据的输入来源声明（纪律 36，**现取不缓存**；并遵 `D-G140` 口径）】
#   ⚠️【`#75` 自伤与根治】本件第一版用 `printf … | grep -qx` 判成员 ⇒ 被仓内 `PIPEFAIL-SIGPIPE` 牙判
#      `undeclared_hit=4`（`pipefail` × 非末段多次写 × 末段早退 ⇒ `printf` 收 SIGPIPE）⇒
#      **全部改成 here-string**（`grep -qx … <<< "$var"`：**无管道 ⇒ 无 SIGPIPE**）。
#   · **存活显示位** = `ps -eo pid=,args=` **现取**，只认 `args` **行首**即 `Xvfb :<数字>` 的行
#     （⇒ 一条"只是提到 Xvfb / 提到 `Xvfb :97`"的旁观 shell **匹配不上**；也不再用
#      `pgrep`／`pgrep -f` —— 那些是 `D-G103` 族自杀式误杀的来源）。
#   · **socket** = `/tmp/.X11-unix/` **现取**目录成员（`X<数字>` ⇒ 显示号）。
#   · **链前基线** = 调用方（`verify-all.sh` 的 `[0]` 段）在本趟**任何显示位被起之前**用
#     `--snapshot <文件>` 落的一份快照。⇒ **语料清单**：`ps` 全机 `Xvfb :` 进程 ＋ `/tmp/.X11-unix/` 成员；
#     **时刻**：本趟 `[0]`；**每次运行都重扫**（不是一次性扫描的结论）。
#   · `D-G140` 口径：本件**每次运行重扫**，输出里带 `X_CENSUS_AT=`（时刻）与 `X_CENSUS_SRC=`（来源），
#     所以它给出的是**本次读数**，不是"当时扫描"的快照。
#
# 【本牙自己的接线状态（**必须字面写在件头**）】
#   **已接线**：`verify-all.sh` 的 `run_step "X-CENSUS" bash build/MilBridge/tools/xvfb-census-check.sh …`
#   ——⚠️ **本注释不写步号**：以现场 `verify-all.sh` 的**步序**为准（写死步号 = 下一条会漂移的陈旧自述）。
#
# 【测试钩子】`--selftest`：自带 fixture（`--ps-file` ＋ `--sock-dir` 注入 ⇒ **不碰真机进程**）。
#   用法：bash xvfb-census-check.sh --snapshot FILE ｜ --baseline FILE [--own-pid PID]…
#                                     [--ps-file F] [--sock-dir D] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

RC_PASS=0; RC_FAIL=1; RC_NOINFO=3
XC_PS_FILE=""; XC_SOCK_DIR="/tmp/.X11-unix"; XC_OWN=""

read_ps_raw() {  # ⇒ 原始 `ps -eo pid=,args=` 行（**不做判定**）
  local src="$1"
  if [ -z "$src" ]; then ps -eo pid=,args= 2>/dev/null; else cat "$src" 2>/dev/null; fi
}

filter_ps_live() {  # ⇒ `pid<TAB>display`（只认 args **行首**即 `Xvfb :N`）
  awk '
      { pid=$1; sub(/^[ \t]+/, "", pid)
        args=$0; sub(/^[ \t]*[0-9]+[ \t]+/, "", args)
        if (args ~ /^Xvfb[ \t]+:[0-9]+/) {
          d=args; sub(/^Xvfb[ \t]+:/, "", d); sub(/[^0-9].*$/, "", d)
          if (pid ~ /^[0-9]+$/ && d != "") printf "%s\t:%s\n", pid, d
        } }'
}

read_socks() {  # ⇒ 每行 `X<num>`
  local d="$1"
  [ -d "$d" ] || return 3
  find "$d" -maxdepth 1 -mindepth 1 -printf '%f\n' 2>/dev/null | LC_ALL=C sort
}

snapshot() {  # snapshot <file>
  local out="$1"
  [ -n "$XC_PS_FILE" ] && { echo "X_CENSUS=NOINFO reason=snapshot-with-ps-file（快照必须来自真机 ps）"; return $RC_NOINFO; }
  local T; T="$(mktemp)"; trap "rm -f $T" EXIT
  {
    printf '# X_CENSUS v1 at=%s src=ps -eo pid=,args= + %s\n' "$(date -Is)" "$XC_SOCK_DIR"
    read_ps_raw "" | filter_ps_live | awk -F'\t' '{printf "P\t%s\t%s\n", $1, $2}'
    local s
    while IFS= read -r s; do [ -n "$s" ] && printf 'S\t%s\n' "$s"; done < <(read_socks "$XC_SOCK_DIR")
  } > "$T"
  mv -f "$T" "$out" || { echo "X_CENSUS=NOINFO reason=snapshot-unwritable path=$out"; return $RC_NOINFO; }
  echo "X_CENSUS_SNAPSHOT=PASS path=$out lines=$(grep -c . "$out" || true) at=$(date -Is)"
  return $RC_PASS
}

judge() {  # judge <baseline>
  local base="$1"
  if [ ! -r "$base" ]; then echo "X_CENSUS=NOINFO reason=baseline-absent path=$base"; return $RC_NOINFO; fi
  if ! grep -q '^# X_CENSUS v1' "$base" 2>/dev/null; then
    echo "X_CENSUS=NOINFO reason=baseline-format-unknown path=$base head=$(head -1 "$base" | cut -c1-40)"
    return $RC_NOINFO; fi
  # ⚠️ 「**源读不到**」（`ps` 全空）与「**读到 0 个 Xvfb**」必须分开：
  #    前者 ⇒ `NOINFO`（纪律 27：空边必须响亮失败）；后者是**合法读数**（这台机器就是没有显示位）。
  local raw_ps raw_n now_ps
  raw_ps="$(read_ps_raw "$XC_PS_FILE")"
  raw_n="$(printf '%s\n' "$raw_ps" | grep -c . || true)"
  if [ "${raw_n:-0}" -eq 0 ]; then
    echo "X_CENSUS=NOINFO reason=ps-empty-or-unreadable src=${XC_PS_FILE:-ps -eo pid=,args=}"
    echo "X_CENSUS_NOTE 进程清单一行都没读到（**源失败**）⇒ **算不出**（不是"没有新增"）"; return $RC_NOINFO; fi
  now_ps="$(printf '%s\n' "$raw_ps" | filter_ps_live)"
  echo "X_CENSUS_PS_SRC lines=$raw_n xvfb_live=$([ -n "$now_ps" ] && printf '%s\n' "$now_ps" | grep -c . || echo 0)" 
  # ⚠️ `$?` **必须在赋值语句之后立刻取**（`local x="$(cmd)"` 的 `$?` 是 `local` 的、不是 `cmd` 的）
  local now_socks src_rc=0
  now_socks="$(read_socks "$XC_SOCK_DIR")"; src_rc=$?
  if [ "$src_rc" -eq 3 ] || [ ! -d "$XC_SOCK_DIR" ]; then
    echo "X_CENSUS=NOINFO reason=sock-dir-absent dir=$XC_SOCK_DIR"; return $RC_NOINFO; fi

  local base_pids base_disps base_socks
  base_pids="$(awk -F'\t' '$1=="P"{print $2}' "$base" | LC_ALL=C sort)"
  base_disps="$(awk -F'\t' '$1=="P"{print $3}' "$base" | LC_ALL=C sort)"
  base_socks="$(awk -F'\t' '$1=="S"{print $2}' "$base" | LC_ALL=C sort)"

  local now_disps; now_disps="$(printf '%s\n' "$now_ps" | awk -F'\t' 'NF{print $2}' | LC_ALL=C sort)"
  local own_disps=""
  local op
  for op in $XC_OWN; do
    [ -z "$op" ] && continue
    local od; od="$(printf '%s\n' "$now_ps" | awk -F'\t' -v p="$op" '$1==p{print $2; exit}')"
    if [ -n "$od" ]; then own_disps="$own_disps $od"; fi
    echo "X_CENSUS_OWN pid=$op display=${od:-<none>}（**本趟自起** ⇒ 计入豁免，收尾由 verify-all 的 EXIT trap 按 PID 收）"
  done

  local fails=0 leaks=0
  local pid disp
  while IFS=$'\t' read -r pid disp; do
    [ -z "${pid:-}" ] && continue
    grep -qx "$pid" <<< "$base_pids" && continue                     # 基线里就有 ⇒ 复用的/别人的
    case " $own_disps " in *" $disp "*) continue ;; esac              # 本趟自起 ⇒ 豁免
    leaks=$((leaks + 1)); fails=$((fails + 1))
    echo "X_CENSUS_LEAK pid=$pid display=$disp（基线上没有、也不属于本趟 ⇒ **跨趟泄漏**；按 PID 收）"
  done <<< "$now_ps"

  local preexisting_dead=0 new_orphan=0 s
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    local n="${s#X}"
    grep -qx "$s" <<< "$base_socks" && {
      # 基线里就有：若现在**仍无主** ⇒ 具名可见、**不判红**（早于本趟、无法归因）
      if ! grep -qx ":$n" <<< "$now_disps"; then
        preexisting_dead=$((preexisting_dead + 1))
        echo "X_CENSUS_PREEXISTING_DEAD_SOCK name=$s display=:$n（**基线里就有**且无主 ⇒ 跨趟残留；**不判红**、无法归因）"
      fi
      continue
    }
    if grep -qx ":$n" <<< "$now_disps"; then
      case " $own_disps " in *" :$n "*) continue ;; esac              # 本趟自起的那一块 ⇒ 豁免
      continue                                                          # 有主且非本趟 ⇒ 上面已按 pid 判过
    fi
    new_orphan=$((new_orphan + 1)); fails=$((fails + 1))
    echo "X_CENSUS_ORPHAN_SOCK name=$s display=:$n（**基线上没有、现在有、且无主** ⇒ 本趟留下的 socket 残渣）"
  done <<< "$now_socks"

  local nb_pid nb_sock nn_pid nn_sock
  nb_pid="$(printf '%s\n' "$base_pids" | grep -c . || true)"; nb_sock="$(printf '%s\n' "$base_socks" | grep -c . || true)"
  nn_pid="$(printf '%s\n' "$now_ps" | grep -c . || true)";   nn_sock="$(printf '%s\n' "$now_socks" | grep -c . || true)"
  echo "X_CENSUS_AT=$(date -Is) X_CENSUS_SRC=ps:+${XC_SOCK_DIR}（**每次运行重扫**，遵 D-G140 口径）"
  echo "X_CENSUS_COUNTS base_live=$nb_pid now_live=$nn_pid base_socks=$nb_sock now_socks=$nn_sock own=$([ -n "$own_disps" ] && echo ${own_disps# } || echo none) preexisting_dead_sock=$preexisting_dead new_orphan_sock=$new_orphan leaks=$leaks"
  if [ "$fails" -gt 0 ]; then
    echo "X_CENSUS=FAIL leaks=$leaks new_orphan_sock=$new_orphan（逐条点名见上；收进程**只按 PID**）"
    return $RC_FAIL
  fi
  echo "X_CENSUS=PASS leaks=0 new_orphan_sock=0 base_live=$nb_pid now_live=$nn_pid base_socks=$nb_sock now_socks=$nn_sock"
  return $RC_PASS
}

# ── 自测（**注入 `ps` 与 socket 目录** ⇒ 不碰真机进程）──────────────────────────
selftest() {
  local T; T="$(mktemp -d)"; trap "rm -rf $T" EXIT
  local n=0 p=0
  mksock() { local d="$T/$1"; shift; mkdir -p "$d"; local x; for x in "$@"; do : > "$d/$x"; done; }
  mkbase() { # mkbase <name> <ps 文件> <sock 名…>
    local nm="$1" psf="$2"; shift 2
    { printf '# X_CENSUS v1 at=2026-09-26T00:00:00+08:00 src=fixture\n'
      awk '{printf "P\t%s\t%s\n", $1, $2}' "$psf"
      local x; for x in "$@"; do printf 'S\t%s\n' "$x"; done
    } > "$T/$nm"
    printf '%s' "$T/$nm"
  }
  run() { # run <name> <want_rc> <must> <mustnot> <baseline> <psfile> <sockdir> <own…>
    local name="$1" want="$2" must="$3" mustnot="$4" bl="$5" psf="$6" sd="$7"; shift 7
    local save_ps="$XC_PS_FILE" save_sd="$XC_SOCK_DIR" save_own="$XC_OWN"
    XC_PS_FILE="$psf"; XC_SOCK_DIR="$sd"; XC_OWN="$*"
    local out rc; out="$(judge "$bl" 2>&1)"; rc=$?
    XC_PS_FILE="$save_ps"; XC_SOCK_DIR="$save_sd"; XC_OWN="$save_own"
    n=$((n + 1)); local ok=1 why=""
    [ "$rc" = "$want" ] || { ok=0; why="$why rc=$rc(want $want)"; }
    if [ "$must" != "-" ] && ! grep -qE "$must" <<< "$out"; then ok=0; why="$why missing:$must"; fi
    if [ "$mustnot" != "-" ] && grep -qE "$mustnot" <<< "$out"; then ok=0; why="$why unexpected:$mustnot"; fi
    [ $ok -eq 1 ] && p=$((p + 1))
    printf 'XCENSUS_SELFTEST case=%s want_rc=%s got_rc=%s => %s %s\n' "$name" "$want" "$rc" "$([ $ok -eq 1 ] && echo OK || echo NO)" "$why"
  }

  # 现场形：基线 0 个存活 + 4 个 socket（含 X239 死 socket）；现在**一模一样** ⇒ PASS ＋ 具名死 socket
  mksock S1 X0 X1 X10 X239
  : > "$T/ps-empty"                                  # **真·空源**（模拟 `ps` 失败）
  printf '  1 /sbin/init\n  2 [kthreadd]\n' > "$T/ps-none"   # 源有行、但**没有一个 Xvfb**
  printf '  1234 Xvfb :97 -screen 0 1280x1024x24\n' > "$T/ps-97"
  local bl
  bl="$(mkbase B1 "$T/ps-none" X0 X1 X10 X239)"
  run C1-baseline-clean 0 'X_CENSUS=PASS' 'X_CENSUS=FAIL' "$bl" "$T/ps-none" "$T/S1"
  run C1b-dead-sock-named 0 'X_CENSUS_PREEXISTING_DEAD_SOCK name=X239 display=:239' 'X_CENSUS=FAIL' "$bl" "$T/ps-none" "$T/S1"

  # C2：新增一个**不是我起的**存活显示位 ⇒ 必红并点名 PID
  printf '  1234 Xvfb :97 -screen 0 1280x1024x24\n' > "$T/ps-97-only"
  run C2-leak 1 'X_CENSUS_LEAK pid=1234 display=:97' 'X_CENSUS=PASS' "$bl" "$T/ps-97-only" "$T/S1"
  # C3：同一个存活显示位，但**是本趟自起的** ⇒ 必绿（"起过 ⇒ 不算泄漏"）
  run C3-own-exempt 0 'X_CENSUS=PASS' 'X_CENSUS_LEAK' "$bl" "$T/ps-97-only" "$T/S1" 1234
  # C4：新增一个**无主** socket ⇒ 必红（本趟留下的残渣）
  mksock S4 X0 X1 X10 X239 X240
  run C4-orphan-sock 1 'X_CENSUS_ORPHAN_SOCK name=X240 display=:240' 'X_CENSUS=PASS' "$bl" "$T/ps-none" "$T/S4"
  # C5：基线里就有的那个显示位现在还在（复用/别人）⇒ 必绿
  bl="$(mkbase B5 "$T/ps-97" X0 X1 X10 X239)"
  run C5-reused-ok 0 'X_CENSUS=PASS' 'X_CENSUS_LEAK' "$bl" "$T/ps-97-only" "$T/S1"
  # C6：`ps` 读不到（空）⇒ NOINFO（空边响亮）
  run C6-ps-empty 3 'X_CENSUS=NOINFO reason=ps-empty-or-unreadable' 'X_CENSUS=PASS' "$bl" "$T/ps-empty" "$T/S1"
  # C7：基线缺席 ⇒ NOINFO
  run C7-baseline-absent 3 'X_CENSUS=NOINFO reason=baseline-absent' 'X_CENSUS=PASS' "$T/nope" "$T/ps-empty" "$T/S1"
  # C8：socket 目录不存在 ⇒ NOINFO
  run C8-sockdir-absent 3 'X_CENSUS=NOINFO reason=sock-dir-absent' 'X_CENSUS=PASS' "$bl" "$T/ps-none" "$T/nodir"
  # C9：基线格式不认 ⇒ NOINFO
  printf 'random\n' > "$T/bad"
  run C9-baseline-format 3 'X_CENSUS=NOINFO reason=baseline-format-unknown' 'X_CENSUS=PASS' "$T/bad" "$T/ps-empty" "$T/S1"
  # C10：**旁观 shell 提到 Xvfb** 不算（行首不是 `Xvfb :`）⇒ 必绿（反向射程）
  printf '  2222 bash -c echo Xvfb :97\n  3333 grep Xvfb :97\n' > "$T/ps-bystander"
  run C10-bystander-not-leak 0 'X_CENSUS=PASS' 'X_CENSUS_LEAK' "$bl" "$T/ps-bystander" "$T/S1"
  # C11：快照模式必须来自真机 `ps`（`--ps-file` 下拒绝）⇒ NOINFO
  XC_PS_FILE="$T/ps-empty"; local so; so="$(snapshot "$T/snap" 2>&1)"; local src=$?
  XC_PS_FILE=""; n=$((n + 1)); local ok=1
  { [ "$src" = "3" ] && grep -q 'reason=snapshot-with-ps-file' <<< "$so"; } || ok=0
  [ $ok -eq 1 ] && p=$((p + 1))
  printf 'XCENSUS_SELFTEST case=%s want_rc=3 got_rc=%s => %s\n' C11-snapshot-real-ps-only "$src" "$([ $ok -eq 1 ] && echo OK || echo NO)"

  echo "XCENSUS_SELFTEST_ROSTER cases=$n pass=$p fail=$((n - p))"
  if [ "$p" = "$n" ]; then echo "XCENSUS_SELFTEST=PASS total=$n pass=$p fail=0"; return 0; fi
  echo "XCENSUS_SELFTEST=FAIL total=$n pass=$p fail=$((n - p))"; return 1
}

main() {
  local mode="" base=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --selftest) selftest; exit $? ;;
      --snapshot) mode=snap; base="${2:-}"; shift 2 ;;
      --snapshot=*) mode=snap; base="${1#*=}"; shift ;;
      --baseline) mode=cmp; base="${2:-}"; shift 2 ;;
      --baseline=*) mode=cmp; base="${1#*=}"; shift ;;
      --own-pid) XC_OWN="$XC_OWN ${2:-}"; shift 2 ;;
      --own-pid=*) XC_OWN="$XC_OWN ${1#*=}"; shift ;;
      --ps-file) XC_PS_FILE="${2:-}"; shift 2 ;;
      --ps-file=*) XC_PS_FILE="${1#*=}"; shift ;;
      --sock-dir) XC_SOCK_DIR="${2:-}"; shift 2 ;;
      --sock-dir=*) XC_SOCK_DIR="${1#*=}"; shift ;;
      -h|--help) sed -n '2,48p' "${BASH_SOURCE[0]}"; exit 0 ;;
      *) echo "xvfb-census-check.sh: 未知参数 '$1'" >&2; exit 2 ;;
    esac
  done
  # env 里的本趟自起 PID（`verify-all.sh` 用 `export X_CENSUS_OWN_PIDS=` 传）
  if [ -n "${X_CENSUS_OWN_PIDS:-}" ]; then XC_OWN="$XC_OWN $X_CENSUS_OWN_PIDS"; fi
  [ -n "$mode" ] || { echo "用法：--snapshot FILE ｜ --baseline FILE [--own-pid PID]… [--selftest]" >&2; exit 2; }
  case "$mode" in
    snap) snapshot "$base"; exit $? ;;
    cmp)  judge "$base";    exit $? ;;
  esac
}
main "$@"
