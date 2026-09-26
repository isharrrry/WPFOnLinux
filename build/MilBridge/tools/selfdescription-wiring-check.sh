#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# selfdescription-wiring-check.sh —— 「**件头自述 vs 接线**」一致性牙（`TASK-0736`／`D-G136`）
#
# 【它挡的是什么】
#   `prereg-four-requirements-check.sh` 的件头长期自述「**它还没有接进门禁**」（原件里逐字写着那两个字样），
#   而 `verify-all.sh` **早已**用 `run_step "PREREG-FOUR-REQ" … --gate …` 把它接进门禁
#   ⇒ **自述与现场相反**。这类"陈旧自述"会让接手者按假前提派活（同族：账目对齐纪律）。
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）】
#   rc=0   `SELFDESC_WIRING=PASS`   逐件都判到、且**没有**一条自述与接线相反
#   rc=1   `SELFDESC_WIRING=FAIL`   **判据红**（逐件点名 `rule=forward`／`rule=reverse`）
#   rc=3   `SELFDESC_WIRING=NOINFO` **算不出**：扫描集为空／`verify-all.sh` 缺席或不可读／`^run_step` 行数为 0
#          （**空边必须响亮失败**：纪律 27 —— "一条都没读到" ≠ "没有一条命中"）
#
#   · **正向必红**：件头里出现 `S1` 字样组（「还没接线」那一族，**逐字表见代码常量 `SD_NOTWIRED`**） ∧ 该件**在 `^run_step` 里命中**。
#   · **反向必红**：件头里出现 `S2` 字样（`SD_WIRED`，即「已经接线」）∧ 该件**在 `^run_step` 里零命中**。
#   · ⚠️ **「件头没写任何自述」不判红**（现场 12+ 件）⇒ 只计 `undeclared=`，不判。
#     理由：那要求一次改十几件件头 = **主控的裁定范围**，不是本牙的射程（**不是放宽**：本牙的射程是"自述与现场**相反**"）。
#
# 【判据的输入来源声明（纪律 36，**现取不缓存**）】
#   · **件头** = 该 `.sh` 从**开头**到**第一次匹配 `^set -` 的那一行之前**（找不到 ⇒ 取前 `HEAD_MAX` 行）。
#   · **接线事实** = `--verify-all` 指向的文件里**现取**的 `^run_step ` 行集合；"命中" = 某条该行的实参文本里
#     出现该件的 **basename**。⚠️ **步号一律不解析、不输出**（`[NN]` 会随步序漂移 ⇒ 本牙只判"接了没接"）。
#   · **扫描集** = 现取 glob `<root>/build/MilBridge/tools/*.sh`。
#
# 【本牙自己的接线状态（**必须字面写在件头**：本牙判的就是「件头自述 vs 接线」）】
#   **已接线**：`verify-all.sh` 的 `run_step "SELFDESC-WIRING" bash build/MilBridge/tools/selfdescription-wiring-check.sh`
#   ——⚠️ **本注释不写步号**：以现场 `verify-all.sh` 的**步序**为准（写死步号 = 下一条会漂移的陈旧自述）。
#   ⚠️ **本条是自洽的硬要求**：本牙落地时**必须与接线同趟**（否则本牙**当场自报 `rule=reverse`**）。
#
# 【测试钩子】`--selftest`：自带 fixture（零 `X`、零 `dotnet`、零 `$R` 依赖），两极化 ＋ 空边各一例。
#   用法：bash selfdescription-wiring-check.sh [--root DIR] [--verify-all PATH] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

# ── 判据的**字样表**（`S1`／`S2`）：**数据放代码里**，不放件头 —— 否则本牙的件头会把这两个字样
#   **当数据引用**而自我判红（排练实测：接线后本牙自报 `rule=forward`）。
#   ⚠️ **输入来源（纪律 36）**：这两个常量就是判据的**唯一**字样来源，现取（不读台账、不读别处）。
SD_NOTWIRED='未接线|不进 verify-all'
SD_WIRED='已接线'

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
HEAD_MAX=60
RC_PASS=0; RC_FAIL=1; RC_NOINFO=3

header_of() {   # 件头：到第一个 `^set -` 之前；找不到就取前 HEAD_MAX 行
  awk -v m="$HEAD_MAX" '{ if ($0 ~ /^set -/) exit; print; n++; if (n >= m) exit }' "$1"
}

check_root() {  # check_root <root> <verify-all>；印逐件行 ＋ 机读行；返回 rc
  local root="$1" va="$2" f rel hdr base hit nw w
  local examined=0 wired=0 unwired=0 undeclared=0 sdn=0 sdw=0 fails=0
  local -a scan=()
  for f in "$root"/build/MilBridge/tools/*.sh; do [ -f "$f" ] && scan+=("$f"); done
  if [ "${#scan[@]}" -eq 0 ]; then
    echo "SELFDESC_WIRING=NOINFO reason=scan-set-empty glob=$root/build/MilBridge/tools/*.sh"
    echo "SELFDESC_NOTE 空扫描集 ⇒ **算不出**（既不算绿也不算红）"
    return $RC_NOINFO
  fi
  if [ ! -r "$va" ]; then
    echo "SELFDESC_WIRING=NOINFO reason=verify-all-absent path=$va"
    echo "SELFDESC_NOTE 接线事实的来源不可读 ⇒ **算不出**"
    return $RC_NOINFO
  fi
  local runn runlines
  runn="$(awk '/^run_step /{n++} END{print n+0}' "$va")"
  runlines="$(grep -a '^run_step ' "$va" 2>/dev/null || true)"
  if [ "${runn:-0}" -eq 0 ]; then
    echo "SELFDESC_WIRING=NOINFO reason=run-step-zero path=$va examined=${#scan[@]} run_step=0"
    echo "SELFDESC_NOTE 一条 run_step 都没读到 ⇒ **算不出**（「零命中」与「没读到」必须分开）"
    return $RC_NOINFO
  fi
  for f in "${scan[@]}"; do
    examined=$((examined + 1))
    rel="${f#"$root"/}"; base="$(basename -- "$f")"
    hdr="$(header_of "$f")"
    nw=0; w=0
    local p1 p2
    p1="${SD_NOTWIRED%%|*}"; p2="${SD_NOTWIRED##*|}"
    case "$hdr" in *"$p1"*) nw=1 ;; esac
    case "$hdr" in *"$p2"*) nw=1 ;; esac
    case "$hdr" in *"$SD_WIRED"*) w=1 ;; esac
    hit=0
    case "$runlines" in *"$base"*) hit=1 ;; esac
    if [ "$hit" = 1 ]; then wired=$((wired + 1)); else unwired=$((unwired + 1)); fi
    if [ "$nw" = 1 ]; then sdn=$((sdn + 1)); fi
    if [ "$w" = 1 ]; then sdw=$((sdw + 1)); fi
    if [ "$nw" = 0 ] && [ "$w" = 0 ]; then undeclared=$((undeclared + 1)); fi
    local sd verdict rule
    if [ "$nw" = 1 ]; then sd="selfdesc-notwired"; elif [ "$w" = 1 ]; then sd="selfdesc-wired"; else sd="undeclared"; fi
    verdict="PASS"; rule="-"
    if [ "$nw" = 1 ] && [ "$hit" = 1 ]; then verdict="FAIL"; rule="forward-selfdesc-notwired-but-wired"; fi
    if [ "$w" = 1 ] && [ "$hit" = 0 ]; then verdict="FAIL"; rule="reverse-selfdesc-wired-but-not-wired"; fi
    # 逐件行**只给"有自述"的件**（没写自述的 12+ 件只进计数，避免刷屏；判词仍由 PASS/FAIL 行承载）
    if [ "$sd" != "undeclared" ]; then
      echo "SELFDESC_FILE file=$rel header=$sd run_step=$([ "$hit" = 1 ] && echo hit || echo miss) verdict=$verdict rule=$rule"
    fi
    if [ "$verdict" = "FAIL" ]; then
      fails=$((fails + 1))
      echo "SELFDESC_FAIL file=$rel rule=$rule（件头自述与现场接线**相反** ⇒ 陈旧自述，会让接手者按假前提派活）"
    fi
  done
  local v="PASS"; [ "$fails" -gt 0 ] && v="FAIL"
  echo "SELFDESC_ROSTER examined=$examined wired=$wired unwired=$unwired undeclared=$undeclared selfdesc_notwired=$sdn selfdesc_wired=$sdw fails=$fails"
  echo "SELFDESC_WIRING=$v examined=$examined wired=$wired unwired=$unwired undeclared=$undeclared fails=$fails run_step=$runn"
  [ "$v" = "FAIL" ] && return $RC_FAIL
  return $RC_PASS
}

selftest() {
  local d tot=0 pass=0 fail=0
  d="$(mktemp -d /tmp/selfdesc-st.XXXXXX)" || return 1
  mk() {  # mk <目录名> <件名> <件头自述行> <是否接线>
    local dir="$d/$1" nm="$2" sd="$3" wired="$4"
    mkdir -p "$dir/build/MilBridge/tools"
    { echo '#!/usr/bin/env bash'; [ -n "$sd" ] && echo "#   $sd"; echo 'set -uo pipefail'; echo 'exit 0'; } > "$dir/build/MilBridge/tools/$nm"
    { echo '#!/usr/bin/env bash'
      # ⚠️ **必带一条无关的 run_step**：否则 `run_step=0` ⇒ 牙判 `NOINFO`（空边响亮失败）
      #    —— 本夹具要判的是"**该件**命中没命中"，不是"有没有接线事实"
      echo 'run_step "OTHER" bash build/MilBridge/tools/other.sh'
      [ "$wired" = 1 ] && echo "run_step \"FIXTURE\" bash build/MilBridge/tools/$nm"
      echo 'exit 0'; } > "$dir/verify-all.sh"
  }
  try() {  # try <名> <目录> <期望rc> <必须出现> [<必须不出现>]
    local nm="$1" dir="$2" want="$3" must="$4" mustnot="${5:-}" o r
    o="$(check_root "$dir" "$dir/verify-all.sh" 2>&1)"; r=$?
    tot=$((tot + 1))
    if [ "$r" -eq "$want" ] && [[ -n "$(printf '%s\n' "$o" | grep -E "$must" || true)" ]] \
       && { [ -z "$mustnot" ] || [ -z "$(printf '%s\n' "$o" | grep -E "$mustnot" || true)" ]; }; then
      pass=$((pass + 1)); echo "SELFTEST $nm want_rc=$want got_rc=$r = OK"
    else
      fail=$((fail + 1)); echo "SELFTEST $nm want_rc=$want got_rc=$r must='$must' mustnot='$mustnot' = FAIL"
      printf '%s\n' "$o" | sed 's/^/    /'
    fi
  }
  mk fwd      fwd.sh      '**未接线**（不进 verify-all）' 1
  mk rev      rev.sh      '**已接线**（门禁里）'           0
  mk okw      okw.sh      '**已接线**（门禁里）'           1
  mk okn      okn.sh      '**未接线**（不进 verify-all）' 0
  mk silent   silent.sh   ''                              1
  mk emptyset nosuch.sh   '**未接线**'                    0
  rm -f "$d/emptyset/build/MilBridge/tools/nosuch.sh"
  mk nova    nova.sh      '**未接线**'                    0
  rm -f "$d/nova/verify-all.sh"
  mk norun   norun.sh     '**未接线**'                    0
  printf '#!/usr/bin/env bash\nexit 0\n' > "$d/norun/verify-all.sh"
  try "SL1 正向必红（自称未接线 ∧ 真接线）"     "$d/fwd"      1 'rule=forward-selfdesc-notwired-but-wired'
  try "SL2 反向必红（自称已接线 ∧ 零命中）"     "$d/rev"      1 'rule=reverse-selfdesc-wired-but-not-wired'
  try "SL3 正极性（自称已接线 ∧ 真接线）"       "$d/okw"      0 'SELFDESC_WIRING=PASS' 'SELFDESC_WIRING=FAIL'
  try "SL4 正极性（自称未接线 ∧ 真未接线）"     "$d/okn"      0 'SELFDESC_WIRING=PASS' 'SELFDESC_WIRING=FAIL'
  try "SL5 无自述不判红（只计 undeclared）"      "$d/silent"   0 'undeclared=1' 'SELFDESC_WIRING=FAIL'
  try "SL6 空扫描集 ⇒ NOINFO"                    "$d/emptyset" 3 'reason=scan-set-empty'
  try "SL7 verify-all 缺席 ⇒ NOINFO"             "$d/nova"     3 'reason=verify-all-absent'
  try "SL8 run_step 零行 ⇒ NOINFO"               "$d/norun"    3 'reason=run-step-zero'
  rm -rf "$d"
  echo "SELFDESC_SELFTEST_ROSTER cases=$tot pass=$pass fail=$fail"
  if [ "$fail" -eq 0 ]; then echo "SELFDESC_SELFTEST=PASS total=$tot pass=$pass fail=$fail"; return 0; fi
  echo "SELFDESC_SELFTEST=FAIL total=$tot pass=$pass fail=$fail"; return 1
}

main() {
  local root="$SELF_DIR/../../.." va="" st=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --root)        root="${2:-}"; shift 2 ;;
      --root=*)      root="${1#*=}"; shift ;;
      --verify-all)  va="${2:-}"; shift 2 ;;
      --verify-all=*) va="${1#*=}"; shift ;;
      --selftest)    st=1; shift ;;
      -h|--help)     sed -n '2,30p' "$SELF" | sed 's/^# \{0,1\}//'; return $RC_PASS ;;
      *) echo "用法：bash $SELF [--root DIR] [--verify-all PATH] [--selftest]" >&2; return 2 ;;
    esac
  done
  [ "$st" = 1 ] && { selftest; return $?; }
  root="$(cd -- "$root" 2>/dev/null && pwd)" || { echo "SELFDESC_WIRING=NOINFO reason=root-absent root=$root"; return $RC_NOINFO; }
  [ -n "$va" ] || va="$root/verify-all.sh"
  check_root "$root" "$va"
}

main "$@"
