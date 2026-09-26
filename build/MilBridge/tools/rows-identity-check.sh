#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# rows-identity-check.sh —— 「**两趟/两臂逐行比较必须区分"读数"与"标签"**」牙（`TASK-0738`／`D-G138`）
#
# 【它挡的是什么】
#   `#69` 现场：两趟应用级门禁的 `BASELINE` 六行**逐字段相同**（`drawn=261/colors=4112`、
#   `drawn=144/colors=2945`），唯一的整行差异是行尾 `rundir=…gate-r1` vs `…gate-r2` **标签**
#   ⇒ 该波自报 `ROWS_IDENTICAL=no` **是标签造成的、不是读数漂移**。
#   **若不区分**，读表人会把"零漂移"读成"有漂移"（**假红**）⇒ 去改本已正确的件。
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）】
#   rc=0  `ROWS_IDENTITY=PASS`    全部可比的 `(tier, rep-pair)` 都「**读数**逐字段相同」；
#                                 仅标签差异的场合**必印** `LABEL_ONLY_DIFF fields=…`（**不许静默**）
#   rc=1  `ROWS_IDENTITY=FAIL`    **读数**真差异（逐对逐字段点名）——**只此一种**判红
#   rc=3  `ROWS_IDENTITY=NOINFO`  算不出：语料缺席/不可读 ／ 找不到任何冻结块头 ／ 块内零 `BASELINE` 行 ／
#                                 **每一** 个 tier 都不满 2 个 `rep`（无可比对）
#
#   ⛔ **口径（`D-G138` 逐字采纳）**：凡比较两组读数的判据，必须先声明**比较域**
#      （哪些字段算读数、哪些算标签）；**只含标签差异时既不许判红、也不许不吭声**。
#   ⛔ **只含标签差异 ⇒ 必印 `LABEL_ONLY_DIFF fields=…`**，且该行**不参与 `rc`**。
#
# 【判据的输入来源声明（纪律 36，**现取不缓存**）】
#   · **语料** = `--baseline`（默认 `<root>/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）**现取**；
#     取**最新冻结块**（第一个匹配 `^# (RE-FROZEN #|⏪ )` 的块头起，到下一个同形块头之前）。
#     ⚠️ **冻结块随波变**（`#73` 是 `RE-FROZEN #73`）⇒ **行号与值一律不许写死**，全部现取。
#   · **行** = 块内 `^BASELINE tier=<名> rep=<n> <k=v>…`；字段 = 空白分隔的 `k=v`。
#   · **标签字段表**（常量，见 `RI_LABEL_FIELDS`）= `rundir`（＋日后同类"落点/轮次"标签位）。
#     其余**全部**字段算**读数**。⚠️ 这是**声明**：把某字段挪进/挪出比较域＝改判据，必须同趟说明。
#
# 【本牙自己的接线状态（**必须字面写在件头**：本牙判「件头自述 vs 接线」的对手牙会读它）】
#   **已接线**：`verify-all.sh` 的 `run_step "ROWS-IDENTITY" bash build/MilBridge/tools/rows-identity-check.sh`
#   ——⚠️ **本注释不写步号**：以现场 `verify-all.sh` 的**步序**为准（写死步号 = 下一条会漂移的陈旧自述）。
#
# 【测试钩子】`--selftest`：自带 fixture（零 `X`、零 `dotnet`、零 `$R` 依赖），两极化 ＋ 空边 ＋ 阴性对照。
#   用法：bash rows-identity-check.sh [--root DIR] [--baseline PATH] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

RC_PASS=0; RC_FAIL=1; RC_NOINFO=3
# 标签字段表（**比较域声明的唯一来源**；空格分隔）
RI_LABEL_FIELDS='rundir'
# 块头识别（与 `column-floor-check.sh` 的出口锚同形：未降级 `# RE-FROZEN #` 与降级 `# ⏪ `）
RI_BLOCK_HEAD_RE='^# (RE-FROZEN #|⏪ )'

# 抽最新块的 `行号` 范围 ⇒ 印 `<start> <end>`（end 为块内末行=下一块头-1，或 EOF）
newest_block_range() {
  awk -v re="$RI_BLOCK_HEAD_RE" '
    { if ($0 ~ re) { n++; if (n==1) s=NR; else if (n==2) { print s" "(NR-1); found=1; exit } } }
    END { if (!found) { if (n>=1) print s" "NR; else print "" } }' "$1"
}

# 把块内的 `BASELINE` 行印成 `tier<TAB>rep<TAB>k=v<TAB>k=v…`
block_rows() {  # block_rows <file> <start> <end> ⇒ `tier<TAB>rep<TAB>k=v<TAB>k=v…`（`tier=`/`rep=` 已升为列，**不再重复进字段表**）
  awk -v s="$2" -v e="$3" '
    NR>=s && NR<=e && /^BASELINE / {
      n=split($0, f, /[ \t]+/); tier=""; rep=""
      for (i=1;i<=n;i++) {
        if (f[i] ~ /^tier=/) tier=substr(f[i],6)
        else if (f[i] ~ /^rep=/) rep=substr(f[i],5)
      }
      if (tier=="" || rep=="") next
      out=tier"\t"rep
      for (i=1;i<=n;i++) {
        if (f[i] ~ /^(tier|rep)=/) continue
        if (f[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) out=out"\t"f[i]
      }
      print out
    }' "$1"
}

# 比较域：把字段列表按标签/读数切开 ⇒ 印 `LABEL<TAB>k=v…` 与 `READ<TAB>k=v…`（各自**排序**后）
split_fields() {  # split_fields <k=v k=v …>
  local -a lab=() rd=()
  local kv k
  for kv in "$@"; do
    k="${kv%%=*}"
    case " $RI_LABEL_FIELDS " in *" $k "*) lab+=("$kv") ;; *) rd+=("$kv") ;; esac
  done
  local IFS=$'\n'
  if [ "${#lab[@]}" -gt 0 ]; then printf 'LABEL\t%s\n' "$(printf '%s\n' "${lab[@]}" | LC_ALL=C sort | tr '\n' ' ')"; else printf 'LABEL\t\n'; fi
  if [ "${#rd[@]}"  -gt 0 ]; then printf 'READ\t%s\n'  "$(printf '%s\n' "${rd[@]}"  | LC_ALL=C sort | tr '\n' ' ')"; else printf 'READ\t\n';  fi
}

# 对一对：印判词；返回 0=读数相同 1=读数不同
cmp_pair() {  # cmp_pair <file_label> <tier> <repA> <fieldsA…> -- 不好传 ⇒ 用两段文本
  # 简化：调用方把两行的字段串准备好
  return 0
}

judge_file() {  # judge_file <file> ；印判词；返回 rc
  local f="$1"
  if [ ! -r "$f" ]; then echo "ROWS_IDENTITY=NOINFO reason=baseline-absent path=$f"; return $RC_NOINFO; fi
  local rng; rng="$(newest_block_range "$f")"
  if [ -z "$rng" ]; then
    echo "ROWS_IDENTITY=NOINFO reason=no-frozen-block-header path=$f re=$RI_BLOCK_HEAD_RE"
    echo "ROWS_IDENTITY_NOTE 找不到任何冻结块头 ⇒ **算不出**（不是"没有漂移"）"
    return $RC_NOINFO
  fi
  local s e; s="${rng%% *}"; e="${rng##* }"
  local rows; rows="$(block_rows "$f" "$s" "$e")"
  local nrows; nrows="$(printf '%s\n' "$rows" | grep -c $'^[^\t]' || true)"
  if [ "${nrows:-0}" -eq 0 ]; then
    echo "ROWS_IDENTITY=NOINFO reason=block-has-no-BASELINE-rows path=$f block_lines=$s-$e"
    return $RC_NOINFO
  fi

  local -A reps=() fields=()
  local line tier rep
  while IFS=$'\t' read -r tier rep line; do
    [ -z "${tier:-}" ] && continue
    reps["$tier"]=$(( ${reps["$tier"]:-0} + 1 ))
    fields["$tier|$rep"]="$line"
  done < <(printf '%s\n' "$rows" | awk -F'\t' '{printf "%s\t%s\t", $1, $2; for(i=4;i<=NF;i++) printf "%s ", $i; printf "\n"}')

  local npairs=0 nident=0 nlabel=0 ndiff=0 nskip=0 fails=0
  local -a tierlist=(); local t
  while IFS= read -r t; do [ -n "$t" ] && tierlist+=("$t"); done < <(printf '%s\n' "${!reps[@]}" | LC_ALL=C sort)

  local -a rl=() ll=()
  local a b fa fb sa sb la lb ra rb
  for t in "${tierlist[@]}"; do
    local -a rps=()
    while IFS= read -r b; do [ -n "$b" ] && rps+=("$b"); done < <(
      printf '%s\n' "$rows" | awk -F'\t' -v T="$t" '$1==T{print $2}' | LC_ALL=C sort -n)
    if [ "${#rps[@]}" -lt 2 ]; then
      nskip=$((nskip + 1))
      echo "ROWS_IDENTITY_UNCHECKED tier=$t reps=${#rps[@]} reason=rep-count-lt-2"
      continue
    fi
    local i j
    for ((i=0; i<${#rps[@]}; i++)); do
      for ((j=i+1; j<${#rps[@]}; j++)); do
        a="${rps[$i]}"; b="${rps[$j]}"
        fa="${fields["$t|$a"]}"; fb="${fields["$t|$b"]}"
        npairs=$((npairs + 1))
        # shellcheck disable=SC2086
        sa="$(split_fields $fa)"; sb="$(split_fields $fb)"
        la="$(printf '%s\n' "$sa" | awk -F'\t' '$1=="LABEL"{print $2}')"
        lb="$(printf '%s\n' "$sb" | awk -F'\t' '$1=="LABEL"{print $2}')"
        ra="$(printf '%s\n' "$sa" | awk -F'\t' '$1=="READ"{print $2}')"
        rb="$(printf '%s\n' "$sb" | awk -F'\t' '$1=="READ"{print $2}')"
        if [ "$ra" = "$rb" ]; then
          nident=$((nident + 1))
          echo "ROWS_IDENTITY_PAIR tier=$t pair=rep${a}v${b} readings_identical=yes readings=$(printf '%s' "$ra" | wc -w) labels_identical=$([ "$la" = "$lb" ] && echo yes || echo no)"
          if [ "$la" != "$lb" ]; then
            nlabel=$((nlabel + 1))
            # 逐字段点名差异（**必须上屏**）
            local names; names="$(diff <(printf '%s\n' "$la" | tr ' ' '\n') <(printf '%s\n' "$lb" | tr ' ' '\n') \
                                  | sed -n 's/^[<>] \([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' | LC_ALL=C sort -u | tr '\n' ',' | sed 's/,$//')"
            echo "LABEL_ONLY_DIFF tier=$t pair=rep${a}v${b} fields=${names:-unknown}（**只含标签差异 ⇒ 不判红**；比较域已声明：标签=[$RI_LABEL_FIELDS]，其余算读数）"
          fi
        else
          ndiff=$((ndiff + 1)); fails=$((fails + 1))
          local fn; fn="$(diff <(printf '%s\n' "$ra" | tr ' ' '\n') <(printf '%s\n' "$rb" | tr ' ' '\n') \
                          | sed -n 's/^[<>] \([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' | LC_ALL=C sort -u | tr '\n' ',' | sed 's/,$//')"
          echo "ROWS_IDENTITY_PAIR tier=$t pair=rep${a}v${b} readings_identical=no"
          echo "ROWS_IDENTITY_DIFF tier=$t pair=rep${a}v${b} fields=${fn:-unknown}（**读数真差异** ⇒ 判红）"
        fi
      done
    done
  done

  # 见证（**不判 rc**）：全文件的冻结块数 —— 证明"最新块"这个域不是空的
  local nb
  nb="$(grep -cE "$RI_BLOCK_HEAD_RE" "$f" || true)"

  echo "ROWS_IDENTITY_COUNTS blocks=${nb:-0} rows=$nrows pairs=$npairs labels_identical_readings=$nident label_only=$nlabel reading_diff=$ndiff unchecked_tiers=$nskip label_fields=[$RI_LABEL_FIELDS]"
  if [ "$npairs" -eq 0 ]; then
    echo "ROWS_IDENTITY=NOINFO reason=no-comparable-rep-pair blocks=$nb rows=$nrows unchecked_tiers=$nskip"
    return $RC_NOINFO
  fi
  if [ "$fails" -gt 0 ]; then
    echo "ROWS_IDENTITY=FAIL pairs=$npairs reading_diff=$fails label_only=$nlabel（**只有读数差异判红**；标签差异已单独打印且不判红）"
    return $RC_FAIL
  fi
  echo "ROWS_IDENTITY=PASS pairs=$npairs readings_identical=$nident label_only=$nlabel reading_diff=0 labels=[$RI_LABEL_FIELDS]"
  return $RC_PASS
}

# ── 自测 ─────────────────────────────────────────────────────────────────────
selftest() {
  local T; T="$(mktemp -d)"; trap "rm -rf $T" EXIT
  local n=0 p=0
  mkfix() { # mkfix <name> <rows…>（自动补块头；再补一个上一代块头 ⇒ "最新块"域有界）
    local nm="$1"; shift
    { printf '# RE-FROZEN #99 —— 夹具\n'
      local r; for r in "$@"; do printf '%s\n' "$r"; done
      printf '# RE-FROZEN #98 —— 上一代\n'
      printf '# ⏪ **（历史，已被 `#98` 取代）**# RE-FROZEN #97\n'
    } > "$T/$nm"
    printf '%s' "$T/$nm"
  }
  run() { # run <name> <want_rc> <must|-> <mustnot|-> <file>
    local name="$1" want="$2" must="$3" mustnot="$4" fl="$5"
    local out rc
    out="$(judge_file "$fl" 2>&1)"; rc=$?
    n=$((n + 1)); local ok=1 why=""
    [ "$rc" = "$want" ] || { ok=0; why="$why rc=$rc(want $want)"; }
    if [ "$must" != "-" ] && ! grep -qE "$must" <<< "$out"; then ok=0; why="$why missing:$must"; fi
    if [ "$mustnot" != "-" ] && grep -qE "$mustnot" <<< "$out"; then ok=0; why="$why unexpected:$mustnot"; fi
    [ $ok -eq 1 ] && p=$((p + 1))
    printf 'ROWS_SELFTEST case=%s want_rc=%s got_rc=%s => %s %s\n' "$name" "$want" "$rc" "$([ $ok -eq 1 ] && echo OK || echo NO)" "$why"
  }
  local R1='BASELINE tier=default rep=1 config=pc:aaa drawn=261 colors=4112 result=PASS rundir=/x/gate-r1'
  local R2='BASELINE tier=default rep=2 config=pc:aaa drawn=261 colors=4112 result=PASS rundir=/x/gate-r2'
  local R3='BASELINE tier=default rep=3 config=pc:aaa drawn=261 colors=4112 result=PASS rundir=/x/gate-r2'
  local E1='BASELINE tier=env rep=1 config=pc:aaa drawn=144 colors=2945 result=PASS rundir=/x/gate-r1'
  local E2='BASELINE tier=env rep=2 config=pc:aaa drawn=144 colors=2945 result=PASS rundir=/x/gate-r2'

  local f
  # SL1：**只标签差异** ⇒ PASS ＋ **必印** LABEL_ONLY_DIFF（这就是 `D-G138` 现场）
  f="$(mkfix F1 "$R1" "$R2" "$R3")"
  run SL1-label-only 0 'LABEL_ONLY_DIFF tier=default pair=rep1v2 fields=rundir' 'ROWS_IDENTITY=FAIL' "$f"
  # SL2：标签**也相同** ⇒ PASS 且 **不得**印 LABEL_ONLY_DIFF（阴性对照：不许恒印）
  f="$(mkfix F2 'BASELINE tier=default rep=1 config=pc:aaa drawn=261 rundir=/x/gate-r2' 'BASELINE tier=default rep=2 config=pc:aaa drawn=261 rundir=/x/gate-r2')"
  run SL2-labels-equal 0 'ROWS_IDENTITY=PASS' 'LABEL_ONLY_DIFF' "$f"
  # SL3：**读数真差异** ⇒ FAIL
  f="$(mkfix F3 'BASELINE tier=default rep=1 config=pc:aaa drawn=261 rundir=/x/gate-r2' 'BASELINE tier=default rep=2 config=pc:aaa drawn=260 rundir=/x/gate-r2')"
  run SL3-reading-diff 1 'ROWS_IDENTITY_DIFF tier=default pair=rep1v2 fields=drawn' 'ROWS_IDENTITY=PASS' "$f"
  # SL4：三 rep，1==2 而 3 不同 ⇒ FAIL 且点名那一对
  f="$(mkfix F4 'BASELINE tier=default rep=1 config=pc:aaa drawn=261' 'BASELINE tier=default rep=2 config=pc:aaa drawn=261' 'BASELINE tier=default rep=3 config=pc:aaa drawn=9')"
  run SL4-third-rep-diff 1 'pair=rep1v3 fields=drawn' 'ROWS_IDENTITY=PASS' "$f"
  # SL5：块头在、但零 BASELINE 行 ⇒ NOINFO
  f="$(mkfix F5 'NOT-A-ROW x=1')"
  run SL5-no-rows 3 'ROWS_IDENTITY=NOINFO reason=block-has-no-BASELINE-rows' 'ROWS_IDENTITY=PASS' "$f"
  # SL6：连块头都没有 ⇒ NOINFO
  printf 'nothing here\n' > "$T/F6"
  run SL6-no-block-header 3 'ROWS_IDENTITY=NOINFO reason=no-frozen-block-header' 'ROWS_IDENTITY=PASS' "$T/F6"
  # SL7：语料缺席 ⇒ NOINFO
  run SL7-absent 3 'ROWS_IDENTITY=NOINFO reason=baseline-absent' 'ROWS_IDENTITY=PASS' "$T/nope.md"
  # SL8：每个 tier 都只有 1 个 rep ⇒ NOINFO（无可比对），且**逐个 tier 可见**
  f="$(mkfix F8 'BASELINE tier=default rep=1 config=pc:aaa drawn=261' 'BASELINE tier=env rep=1 config=pc:aaa drawn=144')"
  run SL8-no-comparable-pair 3 'ROWS_IDENTITY=NOINFO reason=no-comparable-rep-pair' 'ROWS_IDENTITY=PASS' "$f"
  run SL8b-unchecked-visible 3 'ROWS_IDENTITY_UNCHECKED tier=default reps=1' 'ROWS_IDENTITY=PASS' "$f"
  # SL9：两 tier，一个可比一个不可比 ⇒ 仍出判词（不可比的**响亮点名**）
  f="$(mkfix F9 "$R1" "$R2" 'BASELINE tier=env rep=1 config=pc:aaa drawn=144')"
  run SL9-partial-comparable 0 'ROWS_IDENTITY=PASS pairs=1' 'ROWS_IDENTITY=NOINFO' "$f"
  # SL10：多个 tier 各自"只差标签" ⇒ PASS；`blocks=` 见证最新块域非空
  f="$(mkfix FA "$R1" "$R2" "$E1" "$E2")"
  run SL10-two-tiers 0 'ROWS_IDENTITY=PASS pairs=2 readings_identical=2 label_only=2' 'ROWS_IDENTITY=FAIL' "$f"
  run SL10b-blocks-visible 0 'ROWS_IDENTITY_COUNTS blocks=3 ' 'ROWS_IDENTITY=FAIL' "$f"

  echo "ROWS_SELFTEST_ROSTER cases=$n pass=$p fail=$((n - p))"
  if [ "$p" = "$n" ]; then echo "ROWS_SELFTEST=PASS total=$n pass=$p fail=0"; return 0; fi
  echo "ROWS_SELFTEST=FAIL total=$n pass=$p fail=$((n - p))"; return 1
}

main() {
  local root="." base=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --selftest) selftest; exit $? ;;
      --root) root="${2:-}"; shift 2 ;;
      --root=*) root="${1#*=}"; shift ;;
      --baseline) base="${2:-}"; shift 2 ;;
      --baseline=*) base="${1#*=}"; shift ;;
      -h|--help) sed -n '2,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
      *) echo "rows-identity-check.sh: 未知参数 '$1'" >&2; exit 2 ;;
    esac
  done
  local absroot; absroot="$(cd "$root" 2>/dev/null && pwd)" || {
    echo "ROWS_IDENTITY=NOINFO reason=root-absent root=$root"; exit $RC_NOINFO; }
  [ -n "$base" ] || base="$absroot/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md"
  case "$base" in /*) ;; *) base="$absroot/$base" ;; esac
  judge_file "$base"
  exit $?
}
main "$@"
