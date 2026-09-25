#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run-silenthit-legs.sh —— 「**静默 SEGV**」那条腿的**产出端**（仓内唯一；`TASK-0726`）
#
# 【它在链上的位置（判据端 vs 产出端，逐字说清）】
#   · **判据端** = `build/MilBridge/tools/silent-hit-v2-check.sh`（纯读、门禁里跑）——
#     它判 `SILENT_SEGV_HIT ⇔ APP_TEXT_BYTES_TRIMMED == 0 ∧ STACKOVF == 0 ∧ 死于 SIGSEGV`。
#     ⚠️ 判据端**不产数**：它的 `--cases` 吃的是**确定性台账**，`--legs-from` 吃的是**本产出端**的机读行。
#   · **产出端** = 本件（重活那一半：起显示、起应用、跑配方、收装置、把观测变成机读行）。
#   · 两者**通过一张表**相接：本件写 `$RUNDIR/legs.tsv`，判据端用
#     `--legs-from $RUNDIR/legs.tsv` 读它（列口径见下）。⇒ **改本件不会改判据**，改判据也不会改本件。
#   · ⚠️ **本件不判"现件代静默 SEGV 已清零"** —— 它只把**这一趟观测**变成读数；上界与率由台账层（分母表）算。
#
# 【用法】
#   run-silenthit-legs.sh --pair      <ARM_A_DIR> <ARM_B_DIR>            # 两臂目录已就绪，只核"只差一件"
#   run-silenthit-legs.sh --only-shim <BASE_APPDIR> <SHIM_SO>            # 单变量构造：只换 shim（libwpfwin32.so）
#   run-silenthit-legs.sh --only-app  <BASE_APPDIR> <APP_DLL>            # 单变量构造：只换应用主体
#   run-silenthit-legs.sh --app-cmd   '<CMD...>'                         # ⚠️ **极化/自检形态**：应用面换成给定真命令
#   run-silenthit-legs.sh --replay    <RUNDIR>                           # ⚠️ **重放形态**：从既有 rundir 重算机读行（不起进程）
#   公共参数：`--tag <T>`｜`--out <DIR>`｜`--to <SEC>`｜`--mode start|click`｜`--selftest`
#
# 【纪律 38 · 自断言收到了目标环境变量（缺一 ⇒ rc=9，逐条打读数）】
#   `DISPLAY`（必须落在**私有显示白名单** `:23[0-9]`）｜`WPF_PROBE_TAG`｜`WPF_PROBE_RUNDIR`。
#   `--tag`／`--out` 若给了就**必须**与 `WPF_PROBE_TAG`／`WPF_PROBE_RUNDIR` **逐字相同**
#   （否则同一件东西有两个名字 ⇒ 读数会指到别处）。三条**各自单独打印**，不用一句合起来的话。
#
# 【剔除集（trim）—— **从文件读、行首锚定、禁子串包含式剔除**】
#   文件 = 同目录 `silenthit-trim.tsv`（可用 `SILENTHIT_TRIM` 覆盖）。
#   每行 `needle<TAB>trail_sp<TAB>trimmed<TAB>tag<TAB>surface<TAB>provenance`；
#   `trail_sp` = 该 needle 在语料里**尾部空格的个数**（TSV 里尾部空格会被字段切分吃掉 ⇒ 显式记数重建）。
#   `trimmed=yes` ⇒ 该 needle 参与剔除；`trimmed=no` ⇒ **不许剔**（只用于声明合法 tag 集 ⇒ 完备性闸的分母）。
#   完备性闸：`^[[:space:]]*\[[A-Za-z][A-Za-z0-9_-]*\]` 命中的 tag **不在**声明的 tag 集里 ⇒ 计一格
#   `UNDECLARED_TAG_LINES`；它 > 0 ⇒ 该腿 `NOINFO`（**不进分母**，绝不冒充绿）。
#
# 【三支的载荷化（`SEGV_BRANCH`）—— 优先级逐字固定，`none` 不算】
#   ① `rc139`        —— 包装壳（`timeout`）退出码 139（= 128+11）
#   ② `fate`         —— 应用输出里**出现** `SIGSEGV`
#   ③ `term`         —— `gdb` 日志里出现 `Program terminated with signal SIGSEGV`
#   ④ `stop-signo11` —— `gdb` 日志里出现第 ≥1 个具名停止且带 `signo=11`
#   否则 `none`（**模糊谓词不算**）。
#   ⚠️ **射程（如实）**：本件**现场形态不跑 gdb** ⇒ 现场可观测的第三支是 ①／②；
#      ③／④ 只在 `--replay`（吃既有 `gdb.txt`）形态可判。
#
# 【单变量构造（两臂只差一件）】
#   构造后逐件取（相对路径, 字节数, sha16）清单做**集合差**：
#   `diff_n == 1` ∧ 唯一差异的**相对路径 == 声明的变体路径** ⇒ `ARM_GUARD=ok`；否则 `FAIL`＋rc=9。
#   ⚠️ 写盘前逐件断言 `%h == 1`（**禁** `cp -al`／`cp -l`／`ln`）：`cp -a` 会**保留源树内的硬链接**
#      ⇒ 复制出来的两臂可能**共享 inode** ⇒ 改一臂等于改两臂（本仓实测过的最危险形态）。
#      故构造后一律**去硬链接化**（`-links +1` 的件**真拷贝替换**），再去核单变量。
#
# 【机读行（末行）】
#   `SILENTHIT_LEGS state=<DONE|NOINFO|FAIL> legs=<n> hits=<n> diff_n=<n> only=<rel|none> ledger=<path>`
#   ⚠️ 另打印的 `SILENT_SEGV_HIT=yes …` 行是**红签名**：它只表示"这一趟**观测到**命中"，
#      **不**表示"该现象在现件代已复现／已清零"。
#
# 纪律：显示只用 `:23x`｜进程**只按 PID** 收（先 TERM 后 KILL）｜**禁** `pkill`／`killall`／`pgrep -f`
#       ｜输出 ≤2 KB 摘要 ＋ 一条机读末行（全量明细落 `$RUNDIR`）｜零 `dotnet` 依赖的形态不做重活
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

RC_OK=0; RC_HIT=1; RC_NOINFO=2; RC_USAGE=3; RC_REFUSE=9

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO=""
[ -f "$SELF_DIR/../../../close-wave.sh" ] && REPO="$(cd -- "$SELF_DIR/../../../.." && pwd)"
TRIM_TSV="${SILENTHIT_TRIM:-$SELF_DIR/silenthit-trim.tsv}"
DISP_RE=':23[0-9]'
MIN_AVAIL_MB="${WPF_PROBE_MIN_AVAIL_MB:-1200}"

usage() {
  echo "用法: run-silenthit-legs.sh --pair <A> <B> | --only-shim <BASE> <SHIM_SO> | --only-app <BASE> <DLL> | --app-cmd <CMD> | --replay <RUNDIR>" >&2
  echo "      [--tag <T>] [--out <DIR>] [--to <SEC>] [--mode start|click] [--window <NAME>] [--selftest]" >&2
  echo "必需环境: DISPLAY(∈$DISP_RE) WPF_PROBE_TAG WPF_PROBE_RUNDIR" >&2
}

MODE=""; A1=""; A2=""; TAG=""; OUT=""; TO=60; UMODE="start"; WINNAME="HandyControlDemo"

while [ $# -gt 0 ]; do
  case "$1" in
    --pair|--only-shim|--only-app) MODE="$1"; A1="${2:-}"; A2="${3:-}"; shift 3 ;;
    --app-cmd) MODE="--app-cmd"; A1="${2:-}"; shift 2 ;;
    --replay)  MODE="--replay"; A1="${2:-}"; shift 2 ;;
    --tag)     TAG="${2:-}"; shift 2 ;;
    --out)     OUT="${2:-}"; shift 2 ;;
    --to)      TO="${2:-}"; shift 2 ;;
    --mode)    UMODE="${2:-}"; shift 2 ;;
    --window)  WINNAME="${2:-}"; shift 2 ;;
    --selftest) MODE="--selftest"; shift ;;
    -h|--help) usage; exit $RC_OK ;;
    *) echo "SILENTHIT_LEGS=FAIL reason=usage:unknown-arg $1"; usage; exit $RC_USAGE ;;
  esac
done

T16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }
say() { echo "$*"; }

# ── ① 环境自断言（纪律 38：逐条打读数，不合并成一句）──────────────────────────
env_guard() {
  local bad=""
  local dv="${DISPLAY:-}" pt="${WPF_PROBE_TAG:-}" pr="${WPF_PROBE_RUNDIR:-}"
  say "ENV_ITEM DISPLAY=${dv:-<unset>} whitelist=$DISP_RE"
  say "ENV_ITEM WPF_PROBE_TAG=${pt:-<unset>}"
  say "ENV_ITEM WPF_PROBE_RUNDIR=${pr:-<unset>}"
  [ -n "$dv" ] || bad="$bad DISPLAY"
  [ -n "$pt" ] || bad="$bad WPF_PROBE_TAG"
  [ -n "$pr" ] || bad="$bad WPF_PROBE_RUNDIR"
  if [ -n "$dv" ]; then
    case "$dv" in $DISP_RE) ;; *) bad="$bad DISPLAY-out-of-whitelist($dv)";; esac
  fi
  if [ -n "$TAG" ] && [ -n "$pt" ] && [ "$TAG" != "$pt" ]; then bad="$bad TAG!=WPF_PROBE_TAG($TAG/$pt)"; fi
  if [ -n "$OUT" ] && [ -n "$pr" ] && [ "$OUT" != "$pr" ]; then bad="$bad OUT!=WPF_PROBE_RUNDIR($OUT/$pr)"; fi
  if [ -n "$bad" ]; then
    say "ENVGUARD=FAIL missing_or_mismatch:$bad"
    return $RC_REFUSE
  fi
  say "ENVGUARD=ok display=$dv"
  return 0
}

# ── ② 剔除集（**从文件读**；行首锚定逐字，trail_sp 重建尾部空格）──────────────
TRIM_NEEDLES=(); DECL_TAGS=""
load_trim() {
  [ -r "$TRIM_TSV" ] || { say "TRIM_GATE=noinfo reason=trim-tsv-absent file=$TRIM_TSV"; return $RC_NOINFO; }
  local n=0 t=0
  while IFS=$'\t' read -r needle trail trimmed tag surface prov; do
    [ "$needle" = "needle" ] && continue
    [ -n "$needle" ] || continue
    n=$(( n + 1 ))
    # 重建尾部空格（TSV 字段切分会吃掉行尾空白 ⇒ 用显式计数复原）
    case "$trail" in ''|*[!0-9]*) trail=0;; esac
    local pad=""
    local i=0
    while [ "$i" -lt "$trail" ]; do pad="$pad "; i=$(( i + 1 )); done
    local full="$needle$pad"
    if [ "$tag" != "-" ] && [ -n "$tag" ]; then DECL_TAGS="$DECL_TAGS $tag"; fi
    case "$trimmed" in
      yes) TRIM_NEEDLES+=("$full"); t=$(( t + 1 )) ;;
      no)  ;;
      *)   say "TRIM_GATE=noinfo reason=bad-trimmed-column row=$n value=$trimmed"; return $RC_NOINFO ;;
    esac
  done < "$TRIM_TSV"
  if [ "$n" -eq 0 ]; then say "TRIM_GATE=noinfo reason=trim-tsv-zero-rows file=$TRIM_TSV"; return $RC_NOINFO; fi
  if [ "$t" -eq 0 ]; then say "TRIM_GATE=noinfo reason=trim-needles-zero"; return $RC_NOINFO; fi
  if [ -z "$DECL_TAGS" ]; then say "TRIM_GATE=noinfo reason=declared-tags-zero"; return $RC_NOINFO; fi
  say "TRIM_GATE=ok rows=$n trimmed_needles=$t file=$TRIM_TSV sha16=$(T16 "$TRIM_TSV")"
  return 0
}

tag_is_declared() {
  local tg="$1"
  case " $DECL_TAGS " in *" $tg "*) return 0;; esac
  return 1
}

# ── ③ 观测 → 机读格子（**唯一实现**；判据端只读它产出的表）────────────────────
#   入：$1=rundir（含 app.log/app.err/app.rc；可选 gdb.txt）
#   出：全局 LEG_* 变量
analyse_rundir() {
  local d="$1"
  local rc=-1
  [ -r "$d/app.rc" ] && rc="$(cat "$d/app.rc" 2>/dev/null)"
  case "$rc" in ''|*[!0-9-]*) rc=-1;; esac
  APP_BOTH="$d/app.both"
  if [ -r "$d/app.log" ] || [ -r "$d/app.err" ]; then
    cat "$d/app.log" "$d/app.err" > "$APP_BOTH" 2>/dev/null
  fi
  [ -r "$APP_BOTH" ] || { APP_BOTH="$d/app.log"; }
  if [ ! -r "$APP_BOTH" ]; then
    LEG_GATE="noinfo"; LEG_GATE_REASON="no-app-output"
    LEG_RAW=0; LEG_TRIMMED=0; LEG_TRIMLINES=0; LEG_STACKOVF=0; LEG_UNDECL=0
    LEG_BRANCH="none"; LEG_FAMILY="noinfo"; LEG_HIT="NOINFO"; LEG_RC="$rc"
    return $RC_NOINFO
  fi
  LEG_RAW="$(stat -c%s "$APP_BOTH" 2>/dev/null || echo 0)"
  # 行首锚定剔除（禁子串包含）：逐行，命中即丢
  local keep="$d/app.trimmed" tl=0
  : > "$keep"
  local line nd hit
  while IFS= read -r line || [ -n "$line" ]; do
    hit=""
    for nd in "${TRIM_NEEDLES[@]}"; do
      case "$line" in "$nd"*) hit="$nd"; break;; esac
    done
    if [ -n "$hit" ]; then tl=$(( tl + 1 )); else printf '%s\n' "$line" >> "$keep"; fi
  done < "$APP_BOTH"
  LEG_TRIMMED="$(stat -c%s "$keep" 2>/dev/null || echo 0)"
  LEG_TRIMLINES="$tl"
  LEG_STACKOVF="$(grep -ac 'Stack overflow' "$APP_BOTH" 2>/dev/null)"
  LEG_STACKOVF="${LEG_STACKOVF:-0}"
  # 完备性闸：具名 tag 行里**未声明**的格数
  LEG_UNDECL=0
  local tg
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *'['*)
        tg=""
        case "$line" in
          \[*) tg="$(printf '%s' "$line" | sed -n 's/^\[\([A-Za-z][A-Za-z0-9_-]*\)\].*/\1/p')";;
        esac
        if [ -n "$tg" ] && ! tag_is_declared "$tg"; then LEG_UNDECL=$(( LEG_UNDECL + 1 )); fi
        ;;
    esac
  done < "$APP_BOTH"
  # 第三支（优先级固定）
  LEG_BRANCH="none"
  local gdb="$d/gdb.txt"
  if [ "$rc" = "139" ]; then
    LEG_BRANCH="rc139"
  elif grep -aq 'SIGSEGV' "$APP_BOTH" 2>/dev/null; then
    LEG_BRANCH="fate"
  elif [ -r "$gdb" ] && grep -aq 'Program terminated with signal SIGSEGV' "$gdb" 2>/dev/null; then
    LEG_BRANCH="term"
  elif [ -r "$gdb" ] && grep -aqE '^W[0-9]+[A-Z]*-STOP-[1-9][0-9]* .*signo=11' "$gdb" 2>/dev/null; then
    LEG_BRANCH="stop-signo11"
  fi
  LEG_RC="$rc"
  case "$rc" in
    124) LEG_FAMILY="alive" ;;
    139) LEG_FAMILY="139-segv" ;;
    134) LEG_FAMILY="134-abort" ;;
    *)   LEG_FAMILY="other" ;;
  esac
  [ "$LEG_STACKOVF" != "0" ] && LEG_FAMILY="134-stackovf"
  # 判据（**与判据端同形**的合取；本件只算"这一趟"，不算率）
  if [ "$LEG_UNDECL" != "0" ]; then
    LEG_HIT="NOINFO"; LEG_GATE="noinfo"; LEG_GATE_REASON="undeclared-instrumentation"
  elif [ "$PHASE" = "teardown" ]; then
    LEG_HIT="NOINFO"; LEG_GATE="noinfo"; LEG_GATE_REASON="teardown-death-not-a-hit"
  else
    LEG_GATE="ok"; LEG_GATE_REASON=""
    case "$LEG_BRANCH" in
      rc139|fate|term|stop-signo11)
        if [ "$LEG_TRIMMED" = "0" ] && [ "$LEG_STACKOVF" = "0" ]; then LEG_HIT="yes"; else LEG_HIT="no"; fi ;;
      *) LEG_HIT="no" ;;
    esac
  fi
  return 0
}

emit_row() {   # $1=tag $2=arm $3=legsha   （追加到 $LEDGER）
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$1" "$2" "$LEG_RAW" "$LEG_TRIMMED" "$LEG_GATE" "$LEG_STACKOVF" "$LEG_BRANCH" \
    "$3" "$LEG_FAMILY" "$PHASE" "$LEG_UNDECL" "$LEG_HIT" "$LEG_RC" >> "$LEDGER"
}

# ── ④ 装置：显示（自证起来）＋ 空闲检查（只读 /proc，禁 pgrep -f）＋ 内存闸 ────
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
self_in_chain() { case " $SELF_CHAIN " in *" $1 "*) return 0;; esac; return 1; }

display_busy() {
  local p pid cl
  for p in /proc/[0-9]*; do
    [ -r "$p/cmdline" ] || continue
    pid="${p#/proc/}"
    self_in_chain "$pid" && continue
    cl="$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null || true)"
    case "$cl" in *"$DISPLAY"*) return 0;; esac
  done
  return 1
}

X_PID=""; WM_PID=""
start_device() {
  local d="$RUNDIR/device"; mkdir -p "$d"
  local avail_mb
  avail_mb=$(( $(awk '/^MemAvailable:/{print $2}' /proc/meminfo) / 1024 ))
  if [ "$avail_mb" -lt "$MIN_AVAIL_MB" ]; then
    say "DEVICE=NOINFO reason=low-memory avail=${avail_mb}MB min=${MIN_AVAIL_MB}MB"
    return $RC_NOINFO
  fi
  if display_busy; then
    say "DEVICE=NOINFO reason=display-occupied display=$DISPLAY"
    return $RC_NOINFO
  fi
  Xvfb "$DISPLAY" -screen 0 1280x1024x24 > "$d/xvfb.log" 2>&1 &
  X_PID=$!; echo "$X_PID" > "$d/xvfb.pid"
  sleep 2
  if command -v xfwm4 >/dev/null 2>&1; then
    DISPLAY="$DISPLAY" xfwm4 --display="$DISPLAY" --compositor=off > "$d/xfwm.log" 2>&1 &
    WM_PID=$!; echo "$WM_PID" > "$d/xfwm.pid"
    sleep 3
  fi
  if DISPLAY="$DISPLAY" xdpyinfo >/dev/null 2>&1; then
    say "DEVICE=ok display=$DISPLAY x_pid=$X_PID wm_pid=${WM_PID:-none} avail=${avail_mb}MB"
    return 0
  fi
  say "DEVICE=NOINFO reason=x-not-up display=$DISPLAY"
  stop_device
  return $RC_NOINFO
}

stop_device() {   # **只按 PID**
  local f pid
  for f in xfwm.pid xvfb.pid; do
    [ -s "$RUNDIR/device/$f" ] || continue
    pid="$(cat "$RUNDIR/device/$f" 2>/dev/null)"
    case "$pid" in ''|*[!0-9]*) continue;; esac
    kill "$pid" 2>/dev/null
  done
  sleep 1
  for f in xfwm.pid xvfb.pid; do
    [ -s "$RUNDIR/device/$f" ] || continue
    pid="$(cat "$RUNDIR/device/$f" 2>/dev/null)"
    case "$pid" in ''|*[!0-9]*) continue;; esac
    kill -9 "$pid" 2>/dev/null
    rm -f "$RUNDIR/device/$f"
  done
}

# ── ⑤ 一趟腿（真进程树；配方照 9 击腿口径）──────────────────────────────────
TEARDOWN_STARTED=0
run_leg() {   # $1=arm 名 $2=臂目录 $3=tag
  local arm="$1" dir="$2" t="$3"
  local out="$RUNDIR/legs/$t"; mkdir -p "$out"
  local shim="$dir/libwpfwin32.so"
  local legsha="none"
  [ -f "$shim" ] && legsha="$(T16 "$shim")"
  PHASE="nav"
  # ⚠️ 应用跑在**内层 `bash -c`** 里，且**内层第一件事**是把**内层自己的 stderr** 重定向到
  #   `wrapper.err`：否则应用被信号打死时，**内层 shell** 会往我们的屏上打一行
  #   `<pid> 段错误 …`（那是**壳的**诊断，不是应用的输出）⇒ 会污染 ≤2 KB 摘要、也可能被误读
  #   成"产出端自己崩了"。包一层后**作业退出码恒为普通退出**、信号事实落到 `app.rc`。
  bash -c '
    out="$1"; to="$2"; dir="$3"; disp="$4"; shift 4
    exec 2> "$out/wrapper.err"
    cd "$dir" || { echo 90 > "$out/app.rc"; exit 90; }
    export DISPLAY="$disp" PATH="$HOME/.dotnet:$PATH" DOTNET_gcServer=0
    unset LD_PRELOAD LD_DEBUG LD_DEBUG_OUTPUT LD_BIND_NOW
    timeout -k 5 "$to" "$@" > "$out/app.log" 2> "$out/app.err"
    echo $? > "$out/app.rc"
  ' _ "$out" "$TO" "$dir" "$DISPLAY" "${APPCMD_ARR[@]}" &
  local runner=$!
  echo "$runner" > "$out/runner.pid"
  if [ "$UMODE" = "click" ]; then run_recipe "$runner" "$out"; fi
  wait "$runner" 2>/dev/null
  local rc
  rc="$(cat "$out/app.rc" 2>/dev/null || echo -1)"
  case "$rc" in
    124) PHASE="alive-after-recipe" ;;
    *)   if [ "$TEARDOWN_STARTED" = "1" ]; then PHASE="teardown"; else PHASE="nav"; fi ;;
  esac
  analyse_rundir "$out" || true
  emit_row "$t" "$arm" "$legsha"
  printf 'LEG tag=%s arm=%s rc=%s APP_TEXT_BYTES=%s APP_TEXT_BYTES_TRIMMED=%s TRIM_GATE=%s STACKOVF=%s SEGV_BRANCH=%s FAMILY=%s phase=%s undeclared=%s LEG_SHA16=%s HIT=%s\n' \
    "$t" "$arm" "$LEG_RC" "$LEG_RAW" "$LEG_TRIMMED" "$LEG_GATE" "$LEG_STACKOVF" "$LEG_BRANCH" \
    "$LEG_FAMILY" "$PHASE" "$LEG_UNDECL" "$legsha" "$LEG_HIT"
  if [ "$LEG_HIT" = "yes" ]; then
    printf 'SILENT_SEGV_HIT=yes tag=%s arm=%s SEGV_BRANCH=%s FAMILY=%s APP_TEXT_BYTES=%s APP_TEXT_BYTES_TRIMMED=%s STACKOVF=%s LEG_SHA16=%s\n' \
      "$t" "$arm" "$LEG_BRANCH" "$LEG_FAMILY" "$LEG_RAW" "$LEG_TRIMMED" "$LEG_STACKOVF" "$legsha"
    HITS=$(( HITS + 1 ))
  fi
  LEGS=$(( LEGS + 1 ))
}

# 9 击配方（坐标/等待/AE 口径）：**逐字照**历史 9 击腿；窗口名可参数化
run_recipe() {   # $1=runner pid $2=out
  local runner="$1" out="$2"
  local cl="$out/clicks.txt"; : > "$cl"
  local wid="" i=0
  while [ "$i" -lt 90 ]; do
    i=$(( i + 1 ))
    wid="$(DISPLAY="$DISPLAY" xdotool search --onlyvisible --name "$WINNAME" 2>/dev/null | head -1)"
    [ -n "$wid" ] && break
    kill -0 "$runner" 2>/dev/null || break
    sleep 0.5
  done
  if [ -z "$wid" ]; then
    echo "NOINFO_WINDOW=1" >> "$cl"
    return 0
  fi
  local WX=0 WY=0 WW=0 WH=0
  eval "$(DISPLAY="$DISPLAY" xdotool getwindowgeometry --shell "$wid" 2>/dev/null | tr -d '\r')"
  WX="${X:-0}"; WY="${Y:-0}"; WW="${WIDTH:-0}"; WH="${HEIGHT:-0}"
  echo "WINDOW id=$wid X=$WX Y=$WY ${WW}x${WH}" >> "$cl"
  local c=0
  DISPLAY="$DISPLAY" import -window root "png:$out/conv0.png" 2>/dev/null
  while [ "$c" -lt 30 ]; do
    c=$(( c + 1 ))
    cp -f "$out/conv0.png" "$out/conv1.png" 2>/dev/null
    sleep 1.0
    DISPLAY="$DISPLAY" import -window root "png:$out/conv0.png" 2>/dev/null
    local ae
    ae="$(DISPLAY="$DISPLAY" compare -metric AE "$out/conv1.png" "$out/conv0.png" null: 2>&1 | tr -d '\n')"
    [ "$ae" = "0" ] && break
    kill -0 "$runner" 2>/dev/null || break
  done
  echo "CONVERGED iters=$c" >> "$cl"
  click_at "$runner" "$out" "$cl" "$WX" "$WY" 129 210 nav1 2.4
  click_at "$runner" "$out" "$cl" "$WX" "$WY" 129 458 nav9 2.4
  click_at "$runner" "$out" "$cl" "$WX" "$WY" 569 128 ctrl_tb 2.2
  if kill -0 "$runner" 2>/dev/null; then
    DISPLAY="$DISPLAY" xdotool type --delay 120 abc 2>/dev/null
    sleep 1.5
    echo "TYPE abc done" >> "$cl"
  fi
  click_at "$runner" "$out" "$cl" "$WX" "$WY" 129 489 nav10 2.4
  click_at "$runner" "$out" "$cl" "$WX" "$WY" 129 241 nav2 2.4
  click_at "$runner" "$out" "$cl" "$WX" "$WY" 210 106 tab3 2.6
  click_at "$runner" "$out" "$cl" "$WX" "$WY" 129 272 nav3 2.4
  return 0
}

click_at() {   # $1=runner $2=out $3=clicks $4=wx $5=wy $6=rx $7=ry $8=name $9=wait
  local runner="$1" out="$2" cl="$3" wx="$4" wy="$5" rx="$6" ry="$7" name="$8" wait="$9"
  kill -0 "$runner" 2>/dev/null || { echo "CLICK $name SKIP dead" >> "$cl"; return 1; }
  local ax=$(( wx + rx )) ay=$(( wy + ry ))
  DISPLAY="$DISPLAY" import -window root "png:$out/$name-b.png" 2>/dev/null
  DISPLAY="$DISPLAY" xdotool mousemove "$ax" "$ay" 2>/dev/null
  sleep 0.35
  DISPLAY="$DISPLAY" xdotool mousedown 1 2>/dev/null
  sleep 0.18
  DISPLAY="$DISPLAY" xdotool mouseup 1 2>/dev/null
  sleep "$wait"
  DISPLAY="$DISPLAY" import -window root "png:$out/$name-a.png" 2>/dev/null
  local ae
  ae="$(DISPLAY="$DISPLAY" compare -metric AE "$out/$name-b.png" "$out/$name-a.png" null: 2>&1 | tr -d '\n')"
  echo "CLICK $name abs=($ax,$ay) rel=($rx,$ry) AE=$ae" >> "$cl"
  return 0
}

# ── ⑥ 臂清单与单变量断言 ────────────────────────────────────────────────────
mk_arm_dir() {   # $1=可选既有目录（WPF_PROBE_CWD）⇒ 打印"应用 cwd"目录
  local want="$1"
  if [ -n "$want" ] && [ -d "$want" ]; then printf '%s\n' "$want"; return 0; fi
  mkdir -p "$RUNDIR/arm_cmd" || return 1
  printf '%s\n' "$RUNDIR/arm_cmd"
  return 0
}

inventory() {   # $1=dir ⇒ "relpath<TAB>size<TAB>sha16" 有序
  ( cd "$1" 2>/dev/null || exit 1
    find . -type f -printf '%p\n' 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
      printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f" 2>/dev/null || echo 0)" "$(T16 "$f")"
    done )
}

delinearize() {   # 去硬链接化（**禁**共享 inode）；写完逐件断言 %h==1
  local tree="$1" n=0 bad=0
  while IFS= read -r f; do
    n=$(( n + 1 ))
    cp --remove-destination "$f" "$f.silenthit-new" 2>/dev/null && mv -f "$f.silenthit-new" "$f" 2>/dev/null || bad=$(( bad + 1 ))
  done < <( find "$tree" -type f -links +1 2>/dev/null )
  local tot=0
  while IFS= read -r f; do
    tot=$(( tot + 1 ))
    [ "$(stat -c %h "$f" 2>/dev/null)" = "1" ] || bad=$(( bad + 1 ))
  done < <( find "$tree" -type f 2>/dev/null )
  say "DELINK tree=$tree relinked=$n files=$tot bad=$bad"
  [ "$bad" = "0" ]
}

arm_diff() {   # $1=dirA $2=dirB $3=期望变体相对路径 ⇒ 设 ARM_DIFF_N / ARM_ONLY
  local a="$1" b="$2" w="$3"
  inventory "$a" > "$RUNDIR/arm_A.inv"
  inventory "$b" > "$RUNDIR/arm_B.inv"
  cut -f1,3 "$RUNDIR/arm_A.inv" > "$RUNDIR/arm_A.key"
  cut -f1,3 "$RUNDIR/arm_B.inv" > "$RUNDIR/arm_B.key"
  diff "$RUNDIR/arm_A.key" "$RUNDIR/arm_B.key" > "$RUNDIR/arm.diff" 2>/dev/null || true
  # ⚠️ `diff` 对「一件内容变了」会给**两行**（`<` 与 `>`）⇒ 计数必须取**去重后的相对路径数**，
  #    否则"只差一件"会被数成 2 ⇒ 这条断言**恒假**（本件自检 S8a 当场咬到过一次）。
  local dset
  dset="$(sed -n 's/^[<>] \.\/\(.*\)\t.*/\1/p' "$RUNDIR/arm.diff" | LC_ALL=C sort -u)"
  ARM_DIFF_N=0; ARM_ONLY=""
  local one
  while IFS= read -r one; do
    [ -n "$one" ] || continue
    ARM_DIFF_N=$(( ARM_DIFF_N + 1 ))
    ARM_ONLY="${ARM_ONLY}${ARM_ONLY:+,}${one}"
  done <<< "$dset"
  ALL_A="$(cut -f1 "$RUNDIR/arm_A.inv" | LC_ALL=C sort | tr '\n' ',')"
  ALL_B="$(cut -f1 "$RUNDIR/arm_B.inv" | LC_ALL=C sort | tr '\n' ',')"
  say "ARM_DIFF diff_n=$ARM_DIFF_N only=${ARM_ONLY:-none} want=$w same_memberset=$([ "$ALL_A" = "$ALL_B" ] && echo yes || echo no)"
  [ "$ARM_DIFF_N" = "1" ] || return 1
  [ "$ARM_ONLY" = "$w" ] || return 1
  return 0
}

# ── ⑦ 重放形态（从既有 rundir 重算；**不起进程**）────────────────────────────
replay_mode() {
  local d="$1" t="$2"
  PHASE="nav"
  analyse_rundir "$d" || true
  local shim="$d/../../app-P/libwpfwin32.so"
  local legsha="replay"
  emit_row "$t" "replay" "$legsha"
  printf 'LEG tag=%s arm=replay rc=%s APP_TEXT_BYTES=%s APP_TEXT_BYTES_TRIMMED=%s TRIM_GATE=%s STACKOVF=%s SEGV_BRANCH=%s FAMILY=%s phase=%s undeclared=%s LEG_SHA16=%s HIT=%s\n' \
    "$t" "$LEG_RC" "$LEG_RAW" "$LEG_TRIMMED" "$LEG_GATE" "$LEG_STACKOVF" "$LEG_BRANCH" \
    "$LEG_FAMILY" "$PHASE" "$LEG_UNDECL" "$legsha" "$LEG_HIT"
  LEGS=$(( LEGS + 1 ))
  [ "$LEG_HIT" = "yes" ] && { HITS=$(( HITS + 1 ));
    printf 'SILENT_SEGV_HIT=yes tag=%s arm=replay SEGV_BRANCH=%s APP_TEXT_BYTES=%s STACKOVF=%s\n' \
      "$t" "$LEG_BRANCH" "$LEG_RAW" "$LEG_STACKOVF"; }
  return 0
}

# ── ⑧ 自检（判据/装置的**反极性**：喂造的档，不碰真盘）──────────────────────
selftest() {
  local d fail=0 t
  d="$(mktemp -d "${TMPDIR:-$HOME}/silenthit-st.XXXXXX")" || return $RC_NOINFO
  trap 'rm -rf "$d"' RETURN
  # S1 剔除集装载
  if load_trim > "$d/t.log" 2>&1; then say "  OK  S1 trim-load"; else say "  ERR S1 trim-load"; fail=$(( fail + 1 )); fi
  # S2 真静默 SEGV 档 ⇒ 必 HIT(rc139)
  mkdir -p "$d/s2"; printf 'timeout: 被监视的命令已核心转储\n' > "$d/s2/app.err"; : > "$d/s2/app.log"; echo 139 > "$d/s2/app.rc"
  PHASE="nav"; analyse_rundir "$d/s2" >/dev/null 2>&1
  [ "$LEG_BRANCH" = "rc139" ] && [ "$LEG_TRIMMED" = "0" ] && [ "$LEG_HIT" = "yes" ] \
    && say "  OK  S2 silent-segv must-HIT branch=$LEG_BRANCH trimmed=$LEG_TRIMMED" \
    || { say "  ERR S2 got branch=$LEG_BRANCH trimmed=$LEG_TRIMMED hit=$LEG_HIT"; fail=$(( fail + 1 )); }
  # S3 活腿档（有输出、无信号）⇒ 必 NOT-HIT
  mkdir -p "$d/s3"; printf 'hello\n' > "$d/s3/app.log"; : > "$d/s3/app.err"; echo 0 > "$d/s3/app.rc"
  PHASE="nav"; analyse_rundir "$d/s3" >/dev/null 2>&1
  [ "$LEG_HIT" = "no" ] && say "  OK  S3 alive must-NOT-HIT" \
    || { say "  ERR S3 got hit=$LEG_HIT"; fail=$(( fail + 1 )); }
  # S4 未声明 tag ⇒ 必 NOINFO（恒真闸的反极性）
  mkdir -p "$d/s4"; printf '[NEWTAG] x\n' > "$d/s4/app.log"; : > "$d/s4/app.err"; echo 139 > "$d/s4/app.rc"
  PHASE="nav"; analyse_rundir "$d/s4" >/dev/null 2>&1
  [ "$LEG_HIT" = "NOINFO" ] && [ "$LEG_UNDECL" = "1" ] && say "  OK  S4 undeclared-tag must-NOINFO" \
    || { say "  ERR S4 got hit=$LEG_HIT undecl=$LEG_UNDECL"; fail=$(( fail + 1 )); }
  # S5 已声明 tag ⇒ 不得算未声明（**成对**）
  mkdir -p "$d/s5"; printf '[HC-UNHANDLED] #1 EntryPointNotFoundException\n' > "$d/s5/app.log"; : > "$d/s5/app.err"; echo 139 > "$d/s5/app.rc"
  PHASE="nav"; analyse_rundir "$d/s5" >/dev/null 2>&1
  [ "$LEG_UNDECL" = "0" ] && [ "$LEG_TRIMMED" = "0" ] && say "  OK  S5 declared-tag must-0 undecl trimmed=$LEG_TRIMMED" \
    || { say "  ERR S5 undecl=$LEG_UNDECL trimmed=$LEG_TRIMMED"; fail=$(( fail + 1 )); }
  # S6 尾部空格 needle 的**精确性**（**成对**）：`[POSTMSG_DEAD_TARGET]x`（无空格）⇒ **不许剔**；
  #    `[POSTMSG_DEAD_TARGET] x`（有空格）⇒ **必须剔**。两腿只差一个空格。
  mkdir -p "$d/s6a" "$d/s6b"
  printf '[POSTMSG_DEAD_TARGET]x\n'  > "$d/s6a/app.log"; : > "$d/s6a/app.err"; echo 0 > "$d/s6a/app.rc"
  printf '[POSTMSG_DEAD_TARGET] x\n' > "$d/s6b/app.log"; : > "$d/s6b/app.err"; echo 0 > "$d/s6b/app.rc"
  PHASE="nav"; analyse_rundir "$d/s6a" >/dev/null 2>&1; local t6a="$LEG_TRIMMED"
  PHASE="nav"; analyse_rundir "$d/s6b" >/dev/null 2>&1; local t6b="$LEG_TRIMMED"
  if [ "$t6a" = "23" ] && [ "$t6b" = "0" ]; then say "  OK  S6 trail-space pair no-space=$t6a with-space=$t6b"
  else say "  ERR S6 pair no-space=$t6a(want 23) with-space=$t6b(want 0)"; fail=$(( fail + 1 )); fi
  # S7 环境闸的反极性（子壳里清空 ⇒ 必 rc=9）
  local rc7=0
  ( unset DISPLAY WPF_PROBE_TAG WPF_PROBE_RUNDIR; env_guard >/dev/null 2>&1 ) || rc7=$?
  [ "$rc7" = "9" ] && say "  OK  S7 envguard must-refuse rc=9" \
    || { say "  ERR S7 rc=$rc7"; fail=$(( fail + 1 )); }
  # S8 单变量断言的反极性（造两个只差一件的目录 ⇒ ok；再加一件 ⇒ FAIL）
  mkdir -p "$d/a/x" "$d/b/x"
  printf 'p' > "$d/a/x/libwpfwin32.so"; printf 'q' > "$d/b/x/libwpfwin32.so"
  printf 'k' > "$d/a/x/k.dll";        printf 'k' > "$d/b/x/k.dll"
  RUNDIR="$d"; ARM_DIFF_N=0; ARM_ONLY=""
  if arm_diff "$d/a/x" "$d/b/x" "libwpfwin32.so" >/dev/null 2>&1; then say "  OK  S8a single-variable accepted diff_n=$ARM_DIFF_N"; else say "  ERR S8a"; fail=$(( fail + 1 )); fi
  printf 'z' > "$d/b/x/extra.dll"
  if arm_diff "$d/a/x" "$d/b/x" "libwpfwin32.so" >/dev/null 2>&1; then say "  ERR S8b extra-file accepted"; fail=$(( fail + 1 )); else say "  OK  S8b extra-file rejected diff_n=$ARM_DIFF_N"; fi
  say "SILENTHIT_LEGS_SELFTEST=$([ "$fail" = "0" ] && echo PASS || echo FAIL) cases=8 fail=$fail"
  [ "$fail" = "0" ] && return $RC_OK || return $RC_HIT
}

# ── ⑨ 主 ────────────────────────────────────────────────────────────────────
[ -n "$MODE" ] || { usage; exit $RC_USAGE; }
if [ "$MODE" = "--selftest" ]; then selftest; exit $?; fi

# 环境自断言先（**未过一律不往下走**）
if ! env_guard; then
  say "SILENTHIT_LEGS state=NOINFO reason=envguard legs=0 hits=0"
  exit $RC_REFUSE
fi
TAG="${TAG:-$WPF_PROBE_TAG}"
RUNDIR="${OUT:-$WPF_PROBE_RUNDIR}"
mkdir -p "$RUNDIR" || { say "SILENTHIT_LEGS state=FAIL reason=rundir-unwritable dir=$RUNDIR"; exit $RC_REFUSE; }
LEDGER="$RUNDIR/legs.tsv"
printf 'tag\tarm\tAPP_TEXT_BYTES\tAPP_TEXT_BYTES_TRIMMED\tTRIM_GATE\tSTACKOVF\tSEGV_BRANCH\tLEG_SHA16\tFAMILY\tphase\tundeclared\tSILENT_SEGV_HIT\trc\n' > "$LEDGER"
LEGS=0; HITS=0
say "SILENTHIT_LEGS_SELF=$SELF_DIR trim=$TRIM_TSV repo=${REPO:-none} to=$TO mode=$UMODE tag=$TAG"

if ! load_trim; then
  say "SILENTHIT_LEGS state=NOINFO reason=trim-unavailable legs=0 hits=0"
  exit $RC_NOINFO
fi

APPCMD_ARR=(dotnet HandyControlDemo.dll)
ARM_DIFF_N=0; ARM_ONLY="none"

case "$MODE" in
  --replay)
    [ -d "$A1" ] || { say "SILENTHIT_LEGS state=NOINFO reason=rundir-absent dir=$A1"; exit $RC_NOINFO; }
    replay_mode "$A1" "$TAG"
    ;;
  --app-cmd)
    [ -n "$A1" ] || { say "SILENTHIT_LEGS state=FAIL reason=empty-app-cmd"; exit $RC_USAGE; }
    read -r -a APPCMD_ARR <<< "$A1"
    say "APP_CMD=${APPCMD_ARR[*]} (⚠️ 极化/自检形态：应用面被替换 ⇒ 不是 WPF 应用本体的读数)"
    CMDA="$(mk_arm_dir "${WPF_PROBE_CWD:-}")"
    say "APP_CWD=$CMDA"
    if ! start_device; then say "SILENTHIT_LEGS state=NOINFO reason=device legs=0 hits=0"; exit $RC_NOINFO; fi
    run_leg "cmd" "$CMDA" "$TAG"
    TEARDOWN_STARTED=1; stop_device
    ;;
  --pair|--only-shim|--only-app)
    [ -n "$A1" ] && [ -d "$A1" ] || { say "SILENTHIT_LEGS state=NOINFO reason=armA-absent dir=$A1"; exit $RC_NOINFO; }
    ARMA="$A1"; ARMB=""; WANT=""
    case "$MODE" in
      --pair)
        [ -n "$A2" ] && [ -d "$A2" ] || { say "SILENTHIT_LEGS state=NOINFO reason=armB-absent dir=$A2"; exit $RC_NOINFO; }
        ARMB="$A2"; WANT="${SILENTHIT_WANT:-}"
        ;;
      --only-shim|--only-app)
        [ -n "$A2" ] && [ -f "$A2" ] || { say "SILENTHIT_LEGS state=NOINFO reason=variant-absent file=$A2"; exit $RC_NOINFO; }
        local_base="$(basename "$A1")"
        ARMA="$RUNDIR/arms/A"; ARMB="$RUNDIR/arms/B"
        rm -rf "$RUNDIR/arms"; mkdir -p "$RUNDIR/arms"
        cp -a --remove-destination "$A1" "$ARMA" 2>/dev/null || { say "SILENTHIT_LEGS state=FAIL reason=armA-copy"; exit $RC_REFUSE; }
        cp -a --remove-destination "$A1" "$ARMB" 2>/dev/null || { say "SILENTHIT_LEGS state=FAIL reason=armB-copy"; exit $RC_REFUSE; }
        delinearize "$ARMA" || { say "SILENTHIT_LEGS state=FAIL reason=armA-hardlinks"; exit $RC_REFUSE; }
        delinearize "$ARMB" || { say "SILENTHIT_LEGS state=FAIL reason=armB-hardlinks"; exit $RC_REFUSE; }
        if [ "$MODE" = "--only-shim" ]; then WANT="libwpfwin32.so"; else WANT="HandyControlDemo.dll"; fi
        [ "$(stat -c %h "$ARMB/${WANT#./}")" = "1" ] || { say "SILENTHIT_LEGS state=FAIL reason=variant-hardlinked path=$ARMB/${WANT#./}"; exit $RC_REFUSE; }
        cp --remove-destination "$A2" "$ARMB/${WANT#./}" || { say "SILENTHIT_LEGS state=FAIL reason=variant-write"; exit $RC_REFUSE; }
        [ "$(stat -c %h "$ARMB/${WANT#./}")" = "1" ] || { say "SILENTHIT_LEGS state=FAIL reason=variant-hardlinked-after"; exit $RC_REFUSE; }
        ;;
    esac
    if [ -n "$WANT" ]; then
      if ! arm_diff "$ARMA" "$ARMB" "$WANT"; then
        say "SILENTHIT_LEGS state=FAIL reason=arm-not-single-variable diff_n=$ARM_DIFF_N only=${ARM_ONLY:-none} want=$WANT"
        exit $RC_REFUSE
      fi
    else
      say "ARM_DIFF diff_n=SKIP only=none reason=want-not-declared（--pair 需 SILENTHIT_WANT 才核单变量）"
    fi
    if ! start_device; then say "SILENTHIT_LEGS state=NOINFO reason=device legs=0 hits=0"; exit $RC_NOINFO; fi
    run_leg "A" "$ARMA" "$TAG-A"
    run_leg "B" "$ARMB" "$TAG-B"
    TEARDOWN_STARTED=1; stop_device
    ;;
esac

STATE="DONE"
[ "$LEGS" = "0" ] && STATE="NOINFO"
say "LEDGER=$LEDGER rows=$(wc -l < "$LEDGER") sha16=$(T16 "$LEDGER")"
say "SILENTHIT_LEGS state=$STATE legs=$LEGS hits=$HITS diff_n=$ARM_DIFF_N only=${ARM_ONLY:-none} ledger=$LEDGER"
[ "$STATE" = "DONE" ] && exit $RC_OK || exit $RC_NOINFO
