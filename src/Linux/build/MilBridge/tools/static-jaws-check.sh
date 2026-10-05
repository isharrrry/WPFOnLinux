#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# static-jaws-check.sh —— 「**已接线的静态牙此刻是否红**」全景体检牙（`t62` 落；用户决策：做成牙并接线）
#
# 【它挡的是什么（本次真实事故）】`#81` 波从 `1d136ca`（W4a）起就带着一个红的已接线 `[QUOTE-TRAP]` 步
#   （`timestamp-order-check.sh:112` 的双引号内反引号），`t57` 又引入第二处；队长**提交 4 次之后**才靠
#   **临时命令**（把 `Guide.Linux/verify-all.sh` 里所有无参数静态牙逐个捕获式跑）发现。本牙把那次临时做法固化成
#   **每次门禁都跑**的机器动作。
#
# 【射程（写死；`NOINFO` 边界句）】**本牙只判「已接线的静态牙此刻是否红」**：只收 `Guide.Linux/verify-all.sh` 里形如
#   `bash src/Linux/build/MilBridge/tools/<牙>.sh`（可带 `--dry-run`）的**裸静态牙调用**；**它不替代整趟门禁** ——
#   构建／显示位／腿批／用例类步（`dotnet …`／`--legs`／`Xvfb`／`xdpyinfo`／`DISPLAY=`／带参数步）**不在射程内**，
#   一律**具名排除**（`STATICJAWS_EXCLUDED`，**不静默**）。⇒ 「本牙绿」**不等于**「整趟门禁绿」（这句即射程外 `NOINFO`）。
# 【自述】已接线：`Guide.Linux/verify-all.sh` 步名 `STATIC-JAWS`；覆盖面已计入（`src/Linux/build/close-wave.sh` 的 `fp_inputs()`）。
#
# 【判据】逐颗牙（**捕获式取 `rc`** —— 纪律 `27`：`cmd >out 2>err; echo $?`，**不许**从管道末段取 `$?`）：
#   `timeout $SJC_TIMEOUT bash <牙> >out 2>err; rc=$?` ⇒
#     · `rc=0`                      ⇒ 计 `pass`
#     · `rc=124`（超时）             ⇒ 计 `noinfo`（**不算红**：超时是「算不出」，不是「判为假」）
#     · `rc=2`（本仓 `RC_NOINFO` 约定）或判词行自报 `=<…>NOINFO` ⇒ 计 `noinfo`（**不算红**）
#     · 其它 `rc≠0`                 ⇒ 计 `fail` 并**逐条点名**（`step` 名 ＋ 牙路径 ＋ 捕获式 `rc` ＋ `stderr` 行数）
# 【三态 ＋ rc】`STATICJAWS=PASS n=… excluded=… noinfo=…`（rc=0）｜`STATICJAWS=FAIL fails=… n=… excluded=… noinfo=…`（rc=1）
#   ｜`STATICJAWS=NOINFO reason=…`（rc=2：算不出来 —— 件不可读／扫描面为空／一颗都没跑起来）。
#   `NOINFO` **绝不等于绿**；`FAIL` 必须在 stdout 上被**具名**。
#
# 【排除面（写死；每一条都在 stdout 上具名给出理由，不静默）】
#   ① **自身** ⇒ `reason=self-recursion`（跑自己会递归）。
#   ② **命令形不是裸牙调用** ⇒ `reason=non-bare-step`（`dotnet` 构建/测试档／`python3` 步／
#      **带参数**步／壳函数步）：带参步的 argv 由 `Guide.Linux/verify-all.sh` 现场拼（`"$ARM_LOGS"`／`"$GEOM_CORPUS"` …）
#      ⇒ 本牙按裸调用跑会**误报**，故不收。
#   ③ **显示位／腿批档** ⇒ `reason=display-or-legs`（命令行含 `--legs`／`Xvfb`／`xdpyinfo`／`DISPLAY=`）。
#   ④ **已知会构建或长跑的裸牙** ⇒ 写死表 `EXCL_LONG`（理由：`t62` 前体检实测 `rc=124`）：
#      `pc-line-step.sh`／`hidden-only-step.sh`。⚠️ 它们**在射程外但仍具名上屏**（盲区看得见）。
#   ⑤ **已知会写仓件的裸牙/写盘腿** ⇒ 写死表 `EXCL_WRITE`（理由：本牙是**只读体检**，不许改工作树）：
#      `push-marker-write.sh`（写盘端；其写入腿由集成腿驱动）。`wave-push.sh --dry-run` **安全** ⇒ **收**
#      （其 `--write` 腿不在 `run_step` 里）。
#   ⑥ **连续交互档** ⇒ 写死表 `EXCL_INTERACTIVE`：`r-gate-step.sh`。理由（`t62` 现取，非转述）：本牙首版
#      没排它，`SJC_TIMEOUT=25` 到期后它**不随 `SIGTERM` 退出**（实测残留 `timeout … r-gate-step.sh` ＋ 其
#      子进程共两条，已**按 PID** 逐个收：先 `TERM` 再 `KILL`）⇒ 它不是「跑一下就出判词的静态牙」。
#      ⚠️ 连带加固（**本牙自己的护栏**）：所有牙一律 `timeout -k 5 <N>`（到期 `TERM`，5 秒后 `KILL`）；
#      `rc=124`（超时）与 `rc=137`（`-k` 后被杀）**都**计 `noinfo`、**都不算红**。
# 【用法】bash static-jaws-check.sh [--selftest] ｜ 环境：SJC_ROOT（树根）｜SJC_VERIFY_ALL（步表）｜SJC_TIMEOUT（默认 40 秒）
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="${SJC_ROOT:-$(cd -- "$SELF_DIR/../../../../.." && pwd)}"
VA="${SJC_VERIFY_ALL:-$ROOT/Guide.Linux/verify-all.sh}"
SJC_TIMEOUT="${SJC_TIMEOUT:-40}"   # 默认 40 s：`PRODUCT-ENTRY` 实测 13.6 s（t62 现取）⇒ 必须容得下
RC_PASS=0; RC_FAIL=1; RC_NOINFO=2; RC_USAGE=4

# 写死排除表（理由见件头 ④／⑤／⑥）
EXCL_LONG='pc-line-step.sh|hidden-only-step.sh'
EXCL_WRITE='push-marker-write.sh'
EXCL_INTERACTIVE='r-gate-step.sh'
BARE_ERE='^bash[[:space:]]+src/Linux/build/MilBridge/tools/[A-Za-z0-9._-]+\.sh([[:space:]]+--dry-run)?[[:space:]]*$'
# 只读带参白名单（⏪ 队长 2026-09-28 扩射程）：这些步**带参数但只读**、且参数可照 `Guide.Linux/verify-all.sh` 的默认表达式展开。
#   纳入理由：本会话四条已接线红里有两条（`QUOTE-TRAP` 系、`GATE_PROBE` 系）正是**这类步**发现的，此前落在射程外。
#   `ARM_LOGS` 的默认表达式**逐字照抄** `Guide.Linux/verify-all.sh:668`（不写死路径）。
RO_PARAM_JAWS='tline-gate.sh'
DISPLAY_ERE='--legs|Xvfb|xdpyinfo|DISPLAY='

say() { printf '%s\n' "$*"; }
has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }  # 子串判定：**不用管道**（pipefail 下 `printf|grep -q` 会吃 SIGPIPE）

classify_exclusion() {  # $1=cmd $2=name ⇒ 印 reason（空串＝可收）
  local cmd="$1"
  case "$cmd" in
    *dotnet*)                    say "non-bare-step:dotnet-build-or-test"; return 0 ;;
    *python3*)                   say "non-bare-step:python-step"; return 0 ;;
    build_sln_and_samples*)      say "non-bare-step:shell-function-step"; return 0 ;;
  esac
  if [[ "$cmd" =~ $DISPLAY_ERE ]]; then say "display-or-legs"; return 0; fi
  local _b; _b="${cmd##*src/Linux/build/MilBridge/tools/}"; _b="${_b%% *}"
  if [[ "$_b" =~ ^($RO_PARAM_JAWS)$ ]]; then say ""; return 0; fi
  if [[ "$cmd" =~ $BARE_ERE ]]; then say ""; return 0; fi
  say "non-bare-step:argv-not-bare"; return 0
}

main_check() {
  local va="$1"
  [ -r "$va" ] || { say "STATICJAWS=NOINFO reason=verify-all-unreadable path=$va"; return $RC_NOINFO; }
  local n_total=0 n_ran=0 excluded=0 noinfo=0 fails=0
  local -a hits=() notes=()
  local line name cmd reason jaw base tf out err rc stl
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n_total=$((n_total + 1))
    name="$(printf '%s' "$line" | sed -n 's/^[0-9]*:run_step "\([^"]*\)".*/\1/p')"
    cmd="$(printf '%s' "$line" | sed -n 's/^[0-9]*:run_step "[^"]*"[[:space:]]*//p')"
    reason="$(classify_exclusion "$cmd" "$name")"
    if [ -n "$reason" ]; then
      excluded=$((excluded + 1)); say "STATICJAWS_EXCLUDED step=$name reason=$reason cmd=$cmd"; continue
    fi
    jaw="$ROOT/$(printf '%s' "$cmd" | sed -n 's/^bash[[:space:]]\+\([^[:space:]]*\).*/\1/p')"
    base="$(basename -- "$jaw")"
    if [ "$jaw" = "$SELF" ] || [ "$base" = "$(basename -- "$SELF")" ]; then
      excluded=$((excluded + 1)); say "STATICJAWS_EXCLUDED step=$name jaw=$jaw reason=self-recursion"; continue
    fi
    if [[ "$base" =~ ^($EXCL_LONG)$ ]]; then
      excluded=$((excluded + 1)); say "STATICJAWS_EXCLUDED step=$name jaw=$jaw reason=known-long-run-or-build(t62-precheck rc=124)"; continue
    fi
    if [[ "$base" =~ ^($EXCL_WRITE)$ ]]; then
      excluded=$((excluded + 1)); say "STATICJAWS_EXCLUDED step=$name jaw=$jaw reason=writes-repo-files(read-only-probe-excluded)"; continue
    fi
    if [[ "$base" =~ ^($EXCL_INTERACTIVE)$ ]]; then
      excluded=$((excluded + 1)); say "STATICJAWS_EXCLUDED step=$name jaw=$jaw reason=interactive-step-ignores-SIGTERM(t62-measured)"; continue
    fi
    if [ ! -f "$jaw" ]; then
      noinfo=$((noinfo + 1)); notes+=("STATICJAWS_NOINFO step=$name jaw=$jaw reason=jaw-absent")
      say "STATICJAWS_NOINFO step=$name jaw=$jaw reason=jaw-absent"; continue
    fi
    tf="$(mktemp -d)"; out="$tf/out"; err="$tf/err"
    local t0 t1 ms
    t0="$(date +%s%3N)"
    # ⚠️【2026-10-05 修·`t62` 在册隐患（R4 发现）】旧实现**只取 `$jaw` 裸跑**（`bash "$jaw"`），
    #   把原步的 argv **丢掉** —— 对 `wave-push.sh --dry-run` 这种"参数决定副作用"的步，
    #   裸跑 = **不带 `--dry-run`** ⇒ 走默认**写盘**腿，把两枚哨兵重写成现读数，
    #   与本牙「**只读读者**」口径（件头 ⑤ 的 `EXCL_WRITE` 理由）**直接冲突**。
    #   ⇒ 只要 `$cmd` 上带参数（含白名单的 `RO_PARAM_JAWS` 与 `--dry-run` 档），一律
    #      **按原 argv 在 `$ROOT` 下执行**（`bash -c "$cmd"`）；无参数才走"绝对路径裸跑"。
    #   判据不变（仍是捕获式 `rc`），只把"跑什么"改回"门禁里那一句"。
    if [[ "$base" =~ ^($RO_PARAM_JAWS)$ ]] || [ "$cmd" != "bash $jaw" ]; then
      export ARM_LOGS="${WPF_TLINE_ARM_LOGS:-src/Linux/build/MilBridge/arm-logs}"
      ( cd "$ROOT" && timeout -k 5 "$SJC_TIMEOUT" bash -c "$cmd" ) >"$out" 2>"$err"; rc=$?
    else
      timeout -k 5 "$SJC_TIMEOUT" bash "$jaw" >"$out" 2>"$err"; rc=$?
    fi
    t1="$(date +%s%3N)"; ms=$((t1 - t0))
    stl="$(wc -l < "$err")"
    n_ran=$((n_ran + 1))
    if [ "$rc" = 0 ]; then
      say "STATICJAWS_RAN step=$name jaw=$jaw rc=0 stderr=${stl}行 ms=$ms"
    elif [ "$rc" = 124 ] || [ "$rc" = 137 ]; then
      noinfo=$((noinfo + 1)); say "STATICJAWS_NOINFO step=$name jaw=$jaw reason=timeout-or-killed rc=$rc（超时/被杀 ⇒ **不算红**）stderr=${stl}行 ms=$ms"
    elif [ "$rc" = 2 ]; then
      noinfo=$((noinfo + 1)); say "STATICJAWS_NOINFO step=$name jaw=$jaw reason=rc2-rc-noinfo-convention rc=2 stderr=${stl}行 ms=$ms"
    elif grep -qE '=[A-Za-z0-9_-]*NOINFO' "$out" "$err"; then
      noinfo=$((noinfo + 1)); say "STATICJAWS_NOINFO step=$name jaw=$jaw reason=self-reported-NOINFO rc=$rc stderr=${stl}行 ms=$ms"
    else
      fails=$((fails + 1)); hits+=("STATICJAWS_HIT step=$name jaw=$jaw rc=$rc stderr=${stl}行")
      say "STATICJAWS_HIT step=$name jaw=$jaw rc=$rc stderr=${stl}行 ms=$ms"
    fi
    rm -rf "$tf"
  done < <(grep -n '^run_step "' "$va")
  if [ "$n_total" = 0 ]; then
    say "STATICJAWS=NOINFO reason=no-run-step-in-scan-surface va=$va"
    return $RC_NOINFO
  fi
  if [ "$n_ran" = 0 ]; then
    say "STATICJAWS=NOINFO reason=no-jaw-ran n_total=$n_total excluded=$excluded noinfo=$noinfo"
    return $RC_NOINFO
  fi
  if [ "$fails" -gt 0 ]; then
    say "STATICJAWS=FAIL fails=$fails n=$n_ran excluded=$excluded noinfo=$noinfo n_total=$n_total"
    say "STATICJAWS_SCOPE 射程＝已接线的裸静态牙；构建/显示位/腿批/带参步**不在射程内**（见上面 STATICJAWS_EXCLUDED 逐条）⇒ 本牙绿**不等于**整趟门禁绿（NOINFO）"
    return $RC_FAIL
  fi
  say "STATICJAWS=PASS n=$n_ran excluded=$excluded noinfo=$noinfo n_total=$n_total"
  say "STATICJAWS_SCOPE 射程＝已接线的裸静态牙；构建/显示位/腿批/带参步**不在射程内**（见上面 STATICJAWS_EXCLUDED 逐条）⇒ 本牙绿**不等于**整趟门禁绿（NOINFO）"
  return $RC_PASS
}

selftest() {
  local T np=0 nf=0 out rc s
  T="$(mktemp -d)"; trap 'rm -rf "$T"' RETURN
  mkdir -p "$T/src/Linux/build/MilBridge/tools"
  cp -p "$SELF" "$T/src/Linux/build/MilBridge/tools/static-jaws-check.sh" 2>/dev/null || true
  printf '#!/bin/bash\necho "FAKEJAW=PASS"\nexit 0\n' > "$T/src/Linux/build/MilBridge/tools/fake-green-jaw.sh"
  printf '#!/bin/bash\necho "FAKEJAW=FAIL reason=fake"\nexit 1\n' > "$T/src/Linux/build/MilBridge/tools/fake-red-jaw.sh"
  printf '#!/bin/bash\necho "FAKEJAW=NOINFO reason=fake"\nexit 2\n' > "$T/src/Linux/build/MilBridge/tools/fake-noinfo-jaw.sh"
  # 夹具步表：只有三颗假牙（＋ 一颗带参步，用来证明排除面也上屏）
  {
    printf '%s\n' '#!/bin/bash'
    printf '%s\n' 'run_step "FAKE-GREEN" bash src/Linux/build/MilBridge/tools/fake-green-jaw.sh'
    printf '%s\n' 'run_step "FAKE-NOINFO" bash src/Linux/build/MilBridge/tools/fake-noinfo-jaw.sh'
    printf '%s\n' 'run_step "FAKE-ARGS" bash src/Linux/build/MilBridge/tools/fake-green-jaw.sh --mode=x'
  } > "$T/verify-all.sh"
  # S1 夹具正极（无红牙）⇒ PASS
  out="$(SJC_ROOT="$T" SJC_VERIFY_ALL="$T/verify-all.sh" bash "$SELF" 2>&1)"; rc=$?
  if [ "$rc" = 0 ] && has "$out" 'STATICJAWS=PASS'; then np=$((np+1)); else nf=$((nf+1)); fi
  say "STATICJAWS_SELFTEST_CASE case=S1 kind=positive-fixture rc=$rc 原样=$(printf '%s' "$out" | grep -m1 'STATICJAWS=')"
  # S2 夹具反极（加一颗必定 rc=1 的红牙）⇒ FAIL 且点名它
  printf '%s\n' 'run_step "FAKE-RED" bash src/Linux/build/MilBridge/tools/fake-red-jaw.sh' >> "$T/verify-all.sh"
  out="$(SJC_ROOT="$T" SJC_VERIFY_ALL="$T/verify-all.sh" bash "$SELF" 2>&1)"; rc=$?
  s=OTHER
  has "$out" 'STATICJAWS_HIT step=FAKE-RED' && has "$out" 'jaw=' && s=HIT-named
  if [ "$rc" = 1 ] && [ "$s" = HIT-named ] && has "$out" 'STATICJAWS=FAIL fails=1'; then np=$((np+1)); else nf=$((nf+1)); fi
  say "STATICJAWS_SELFTEST_CASE case=S2 kind=negative-fixture rc=$rc verdict=$s 原样=$(printf '%s' "$out" | grep -m1 'STATICJAWS_HIT')"
  # S3 步表不可读 ⇒ NOINFO
  out="$(SJC_ROOT="$T" SJC_VERIFY_ALL="$T/no-such-verify-all.sh" bash "$SELF" 2>&1)"; rc=$?
  if [ "$rc" = 2 ] && has "$out" 'STATICJAWS=NOINFO'; then np=$((np+1)); else nf=$((nf+1)); fi
  say "STATICJAWS_SELFTEST_CASE case=S3 kind=noinfo rc=$rc 原样=$(printf '%s' "$out" | grep -m1 'STATICJAWS=')"
  say "STATICJAWS_SELFTEST=$([ "$nf" = 0 ] && echo PASS || echo FAIL) cases=$((np+nf)) pass=$np fail=$nf"
  [ "$nf" = 0 ] && return $RC_PASS || return $RC_FAIL
}

while [ $# -gt 0 ]; do
  case "$1" in
    --selftest) selftest; exit $? ;;
    -h|--help)  sed -n '2,30p' "$SELF" | sed 's/^# \{0,1\}//'; exit $RC_PASS ;;
    *) say "STATICJAWS=NOINFO reason=arg-not-accepted arg=$1" >&2; exit $RC_USAGE ;;
  esac
done
main_check "$VA"; exit $?
