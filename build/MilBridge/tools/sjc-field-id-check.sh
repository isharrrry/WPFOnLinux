#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# sjc-field-id-check.sh —— 「**证据行是否同给『结构偏移 ＋ 写点』两要素**」牙（**弱版**）
#                          （`TASK-0756`；`T-D2` 落；来源口径 `R-2`／`t197`／`P1-tail2-jaws-recon.md §2`）
#
# 【它挡的是什么（`t194` 现场）】
#   `t194` 把**描述符字段** `dvr_used@+36` 当证据，却引**子轨出参** `win32_pts.c:1550/:1554`
#   ⇒ 写点不落在该结构的写入面上 ⇒ 证据无效。本牙是 `SJC-FIELD-ID` 的**弱版**：
#   **只判「同给两要素」**（该不该给、给没给），**不判「对得上」**（写点是否落在该结构写入面）。
#   后者需要一份机器可读的「结构/字段/偏移/写点」注册表（`field-write-registry.tsv`）——
#   本波**没有** ⇒ 本牙对该半句记 **`NOINFO`**（见下方「射程边界」）。
#
# 【判据（先写死；三态；`NOINFO` 不算绿）】
#   rc=0 `SJC_FIELD_ID=PASS`     受检行数 > 0 ∧ 每一行都同给两要素（或落在**具名豁免**内）∧ 豁免数 ≤ 上限
#   rc=1 `SJC_FIELD_ID=FAIL`     逐行点名 `文件:行`：`reason=missing-element`（缺一要素）／
#                                `reason=allow-cap-exceeded`（豁免条数 > 上限 ⇒ **树长大也红**）
#   rc=2 `SJC_FIELD_ID=NOINFO`   算不出：射程件 0 件／**受检行 0 行**（空集不许当 PASS ⇒ `L25`）／射程目录缺席
#   rc=4 用法错（`reason=arg-not-accepted`）
#
# 【受检行（＝证据行）＝ 命中「结构偏移**强形态**」的行】
#   · `A`：`<标识符>@+<N>`（字段＠结构偏移；例 `dvr_used@+36`）
#   · `C`：`off=+<N>`（带加号的显式偏移；例 `field=pfspara off=+8 write=win32_pts.c:3713`）
#   **写点要素** = `<文件>.{c,h,cs,py,sh}:<行号>` 或裸行号形态 `:<三位以上>`（例 `:3713`）。
#   ⚠️ **逐行判定**：跨行的证据单元（偏移在一行、写点在下一行）**本版不判** ⇒ 记 `NOINFO(跨行单元未判)`。
#
# 【形态边界（**如实划界，不静默**）—— 这是本牙最重要的自限】
#   本版**不**把下列形态纳入受检行：**裸 `+N`**（`| **+8** |` 那种表列）、`offset=N`（无 `+`）、
#   `off_<名>=N`（无 `+`）、`offX=`／`gate-off=`（非结构偏移）。**理由（现取）**：这些形态在
#   `build/MilBridge/*.md` 里命中 **4xx 行**，其中绝大多数是**几何/像素/字节偏移**（`800x600@+0+0`、
#   `off=0x…`、`NULBYTES_HIT … offset=15`）⇒ 照收会把整个面判红（**假红**），而假红会侵蚀对红数的信任。
#   ⇒ 本版把「未纳入形态的偏移命中行」**如实印计数** `SJC_FIELD_ID_WIDE_UNCOVERED n=…`（**诊断，不进 rc**）：
#     **射程缺口看得见**，既不把它当绿、也不把它冒充成红。
#   反极性口径（`--lines` 逐行模式）：**只给偏移 ⇒ 红**；**只给写点 ⇒ 也红**（两要素缺一即红）。
#
# 【具名豁免（声明式；逐行给为什么；**超上限即红**；**必上屏、不静默**）】
#   口径：**引用/定义行不是「本侧证据主张」**（它们逐字引用反例、或描述判据自己）⇒ 判据的域不覆盖它们
#   （`D-G130` 自指污染族）。清单是**闭集**：`件路径|行内容锚|为什么`（**不许按关键词自我豁免** ——
#   否则后来者只要在违规行里写上「错法」二字就能自免）。`build/MilBridge/*.md` **首版现取 4 行**。
#   ⚠️ **主动披露（可裁项）**：按本牙 `C2` 的**字面**口径（只给偏移 ⇒ 缺一要素），这 4 行**本可判红**；
#   本版把它们归入「引用/定义行」而豁免。**队长若要硬判：删掉豁免清单里对应行 ⇒ 当场翻红**（自测 `S6` 钉住）。
#
# 【射程】件级**件路径身份**（`--dir` 现取 glob；默认 `<root>/build/MilBridge/*.md`）。
#   `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` **不在射程内**（侦察现取：该册是缺陷登记、不是字段身份表，
#   无「结构偏移 ＋ 写点」同行的合格正样本）。判词**永远带 `files=`／`examined=`**（禁把"没扫到"当"不存在"）。
#   ⚠️ **强版记 `NOINFO`**：本牙**判不了**「写点与偏移对得上吗」—— 缺 `field-write-registry.tsv`，
#      且 `PASS` 一字都不代表「该证据成立」；它只代表「这一行把两要素都给了」。
# 【自述】已接线：`verify-all.sh` 步名 `SJC-FIELD-ID`；覆盖面已计入（`build/close-wave.sh` 的 `fp_inputs()`）。
# 【用法】bash sjc-field-id-check.sh [--root DIR] [--dir DIR] [--file F] [--lines] [--allow F] [--allow-cap N] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="${SJC_FID_ROOT:-$(cd -- "$SELF_DIR/../../.." && pwd)}"
DIR="${SJC_FID_DIR:-}"          # 空 ⇒ 解析完参数后落到 "$ROOT/build/MilBridge"（见下方收口）
ONE_FILE="${SJC_FID_FILE:-}"
ALLOW_FILE="${SJC_FID_ALLOW:-}"
LINES_MODE="${SJC_FID_LINES:-0}"
ALLOW_CAP="${SJC_FID_ALLOW_CAP:-4}"
RC_PASS=0; RC_FAIL=1; RC_NOINFO=2; RC_USAGE=4
W=""
say() { printf '%s\n' "$*"; }

# ── 判据的**唯一**字样来源（现取；不读台账、不读别处）─────────────────────────────
#   `OFF_A`／`OFF_C` = 结构偏移**强形态**（受检行触发）；`WPT` = 写点要素；
#   `WIDE` = **放宽形态**（只作诊断计数，见件头「形态边界」——它**不进**判据）。
OFF_A='(^|[^0-9A-Za-z_])[A-Za-z_][A-Za-z0-9_]*@\+[0-9]+([^0-9]|$)'
OFF_C='(^|[^0-9A-Za-z_])off[[:space:]]*=[[:space:]]*\+[0-9]+([^0-9]|$)'
WPT='([A-Za-z0-9_./-]+\.(c|h|cs|py|sh):[0-9]+|:[0-9]{3,})'
WIDE='(^|[^0-9A-Za-z_])\+[0-9]+([^0-9]|$)'

# ── 内置豁免清单（**闭集**：`件路径|行内容锚|为什么`；`#` 起头为注释）────────────────
allow_builtin() {
  cat <<'ALLOW'
build/MilBridge/P1-HANDOFF-20260929.md|只把**子轨出参**置 0|引用行：逐字引用「错法」反例（描述**错的**修法），不是本侧证据主张
build/MilBridge/P1-tail2-jaws-recon.md|NODVR|同上反例行的逐字引用（侦察件 §2.2 的 N-3 引文）
build/MilBridge/P1-tail2-jaws-recon.md|强形态**（推荐首版）|正则草案**定义句**（句内出现 off=+8 字样 ⇒ 定义句而非证据主张）
build/MilBridge/P1-tail2-jaws-recon.md|喂**只给偏移**|C2 **夹具定义句**（把违规形态当「反极夹具」来描述）
ALLOW
}

rel_of() {
  local p
  p="$(realpath -m --relative-to="$ROOT" "$1" 2>/dev/null || printf '%s' "$1")"
  printf '%s' "$p"
}

collect_files() {
  local f
  if [ -n "$ONE_FILE" ]; then
    [ -f "$ONE_FILE" ] && printf '%s\n' "$ONE_FILE"
    return 0
  fi
  for f in "$DIR"/*.md; do [ -f "$f" ] && printf '%s\n' "$f"; done
}

has_off() { [[ "$1" =~ $OFF_A ]] && return 0; [[ "$1" =~ $OFF_C ]] && return 0; return 1; }
has_wpt() { [[ "$1" =~ $WPT ]]; }

is_allow() {  # $1=rel件 $2=行内容 ⇒ 命中则**上屏** why 并返回 0
  local rel="$1" line="$2" r a w
  while IFS='|' read -r r a w; do
    [ -n "${r:-}" ] || continue
    case "$r" in '#'*) continue ;; esac
    [ "$r" = "$rel" ] || continue
    case "$line" in
      *"$a"*) say "SJC_FIELD_ID_ALLOW file=$rel anchor=$a why=$w"; return 0 ;;
    esac
  done < "$W/allow.tsv"
  return 1
}

run_check() {
  W="$(mktemp -d)"; trap 'rm -rf "$W"' RETURN
  if [ -n "$ALLOW_FILE" ]; then
    [ -r "$ALLOW_FILE" ] || { say "SJC_FIELD_ID=NOINFO reason=allow-file-unreadable path=$ALLOW_FILE"; return $RC_NOINFO; }
    cp -p "$ALLOW_FILE" "$W/allow.tsv"
  else
    allow_builtin > "$W/allow.tsv"
  fi
  local n_allow_rows; n_allow_rows="$(grep -c . "$W/allow.tsv" || true)"
  collect_files > "$W/files.txt" || true
  local n_files; n_files="$(grep -c . "$W/files.txt" || true)"
  if [ "$n_files" = 0 ]; then
    say "SJC_FIELD_ID=NOINFO reason=no-scope-file dir=$DIR glob=*.md"
    return $RC_NOINFO
  fi
  say "SJC_FIELD_ID_SCOPE dir=$DIR glob=*.md files=$n_files form=A|C(结构偏移强形态) lines_mode=$LINES_MODE"

  local examined=0 compliant=0 exempt=0 fail=0 wide=0
  local f rel wc_ hf hl ln content
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="$(rel_of "$f")"
    hf="$W/hits.$$"
    if [ "$LINES_MODE" = 1 ]; then
      grep -nE '.' "$f" > "$hf" 2>/dev/null || true
    else
      grep -nE "$OFF_A|$OFF_C" "$f" > "$hf" 2>/dev/null || true
    fi
    while IFS= read -r hl; do
      [ -n "$hl" ] || continue
      ln="${hl%%:*}"; content="${hl#*:}"
      examined=$((examined+1))
      if has_off "$content" && has_wpt "$content"; then compliant=$((compliant+1)); continue; fi
      if is_allow "$rel" "$content"; then exempt=$((exempt+1)); continue; fi
      fail=$((fail+1))
      say "SJC_FIELD_ID_HIT file=$rel:$ln reason=missing-element need=offset+write-point snippet=$content"
    done < "$hf"
    rm -f "$hf"
    # 放宽形态（**不判**）的命中计数：`WIDE` 命中而**不在**受检行里的那些行
    wc_="$( { grep -E "$WIDE" "$f" 2>/dev/null || true; } | { grep -vE "$OFF_A|$OFF_C" 2>/dev/null || true; } | grep -c . || true)"
    wide=$((wide + wc_))
  done < "$W/files.txt"

  local over=0
  [ "$exempt" -gt "$ALLOW_CAP" ] && over=1
  say "SJC_FIELD_ID_ALLOW_CAP cap=$ALLOW_CAP rows=$n_allow_rows exempt=$exempt over=$over"
  say "SJC_FIELD_ID_WIDE_UNCOVERED n=$wide note=放宽形态(裸 +N／offset=N／off_名=N)本版不判（见件头「形态边界」）"
  say "SJC_FIELD_ID_STRONG_VERSION=NOINFO reason=no-field-write-registry（强版需 field-write-registry.tsv：结构/字段/偏移/写点 ⇒ 本牙不判「对得上」）"

  if [ "$examined" = 0 ]; then
    say "SJC_FIELD_ID=NOINFO reason=no-evidence-line-examined files=$n_files dir=$DIR（空集不许当 PASS）"
    return $RC_NOINFO
  fi
  if [ "$over" = 1 ]; then
    say "SJC_FIELD_ID=FAIL reason=allow-cap-exceeded files=$n_files examined=$examined compliant=$compliant exempt=$exempt cap=$ALLOW_CAP"
    return $RC_FAIL
  fi
  if [ "$fail" -gt 0 ]; then
    say "SJC_FIELD_ID=FAIL files=$n_files examined=$examined compliant=$compliant exempt=$exempt fail=$fail reason=missing-element"
    return $RC_FAIL
  fi
  say "SJC_FIELD_ID=PASS files=$n_files examined=$examined compliant=$compliant exempt=$exempt cap=$ALLOW_CAP fail=0（弱版：只判「同给两要素」，**不判**「对得上」）"
  return $RC_PASS
}

# ─────────────────────────── 两极化自测（零 `X`、零 `dotnet`、不依赖真仓） ───────────────────────────
selftest() {
  local T np=0 nf=0 tot=0 out rc
  T="$(mktemp -d)"; trap 'rm -rf "$T"' RETURN
  mkdir -p "$T/good" "$T/none"
  # 夹具（**自造**；不依赖活件）——
  {
    printf '%s\n' '- 正例：field=pfspara off=+8 write=win32_pts.c:3713（两要素齐全）'
    printf '%s\n' '- 正例：dvr_used@+36 的写点 :3713 rg[i].dvr_used = 0;（两要素齐全）'
  } > "$T/good/ev.md"
  # 反极①：只给偏移（无写点）
  {
    printf '%s\n' '- 错法：标 dvr_used@+36 却没给写点'
    printf '%s\n' '- 错法：field=pfspara off=+8 同上'
  } > "$T/bad.md"
  # 反极②：只给写点（`--lines` 逐行模式才受检）
  printf '%s\n' '- 只给写点：:3713 rg[i].pfspara = (void *)para_val;' > "$T/wptonly.md"
  # 空集（无任何 token）
  printf '%s\n' '# 空面' '' '- 本节只谈方法，不给任何证据行。' > "$T/none/empty.md"
  # 豁免夹具：一行缺写点，其（件,锚）由 `--allow` 决定是否在清单里
  printf '%s\n' '- 错法：标 dvr_used@+36 却没给写点' > "$T/allowcase.md"
  printf '%s\n' 'allowcase.md|dvr_used@+36|夹具：把该行声明为「引用/定义行」' > "$T/allow-1.tsv"
  printf '%s\n' '# 空清单（同一行**不在**豁免里 ⇒ 必须翻红）' > "$T/allow-0.tsv"
  : > "$T/allow-5.tsv"
  : > "$T/capdata.md"
  local i
  for i in 1 2 3 4 5; do
    printf '%s\n' "capdata.md|dvr_used@+36|夹具：第 $i 行（用于撞上限）" >> "$T/allow-5.tsv"
    printf -- '- 错法：第 %s 行标 dvr_used@+36 却没给写点\n' "$i" >> "$T/capdata.md"
  done

  run() {  # run <名> <期望rc> <必须出现> <必须不出现> <argv…>
    local nm="$1" want="$2" must="$3" mustnot="$4"; shift 4
    local o; o="$(bash "$SELF" "$@" 2>&1)"; rc=$?
    tot=$((tot+1))
    local ok=1
    [ "$rc" = "$want" ] || ok=0
    case "$o" in *"$must"*) ;; *) ok=0 ;; esac
    if [ -n "$mustnot" ]; then case "$o" in *"$mustnot"*) ok=0 ;; esac; fi
    if [ "$ok" = 1 ]; then np=$((np+1)); else nf=$((nf+1)); fi
    printf 'SJC_FIELD_ID_SELFTEST_CASE case=%s want_rc=%s got_rc=%s must=%s => %s\n' \
      "$nm" "$want" "$rc" "$must" "$([ "$ok" = 1 ] && echo OK || echo FAIL)"
  }

  run S1-positive-fixture 0 'SJC_FIELD_ID=PASS files=1 examined=2 compliant=2' '' --root "$T" --file "$T/good/ev.md"
  run S2-negative-missing-write-point 1 'SJC_FIELD_ID_HIT file=bad.md:1 reason=missing-element' '' --root "$T" --file "$T/bad.md"
  run S2b-negative-verdict 1 'SJC_FIELD_ID=FAIL files=1 examined=2 compliant=0 exempt=0 fail=2 reason=missing-element' '' --root "$T" --file "$T/bad.md"
  run S3-negative-write-point-only 1 'SJC_FIELD_ID_HIT file=wptonly.md:1' '' --root "$T" --lines --file "$T/wptonly.md"
  run S4-empty-set-must-not-pass 2 'SJC_FIELD_ID=NOINFO reason=no-evidence-line-examined' 'SJC_FIELD_ID=PASS' --root "$T" --file "$T/none/empty.md"
  run S5-exempt-in-place 0 'SJC_FIELD_ID_ALLOW file=allowcase.md' '' --root "$T" --file "$T/allowcase.md" --allow "$T/allow-1.tsv"
  run S6-exempt-removed-must-red 1 'SJC_FIELD_ID_HIT file=allowcase.md:1' '' --root "$T" --file "$T/allowcase.md" --allow "$T/allow-0.tsv"
  run S7-exempt-cap-exceeded 1 'SJC_FIELD_ID=FAIL reason=allow-cap-exceeded' '' --root "$T" --file "$T/capdata.md" --allow "$T/allow-5.tsv" --allow-cap 4
  run S8-no-scope-file 2 'SJC_FIELD_ID=NOINFO reason=no-scope-file' '' --root "$T" --dir "$T/emptydir"

  say "SJC_FIELD_ID_SELFTEST=$([ "$nf" = 0 ] && echo PASS || echo FAIL) cases=$tot pass=$np fail=$nf"
  [ "$nf" = 0 ] && return $RC_PASS || return $RC_FAIL
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root)      ROOT="${2:-}"; shift 2 ;;
    --dir)       DIR="${2:-}"; shift 2 ;;
    --file)      ONE_FILE="${2:-}"; shift 2 ;;
    --allow)     ALLOW_FILE="${2:-}"; shift 2 ;;
    --allow-cap) ALLOW_CAP="${2:-4}"; shift 2 ;;
    --lines)     LINES_MODE=1; shift ;;
    --selftest)  selftest; exit $? ;;
    -h|--help)   sed -n '2,50p' "$SELF" | sed 's/^# \{0,1\}//'; exit $RC_PASS ;;
    *) say "SJC_FIELD_ID=NOINFO reason=arg-not-accepted arg=$1" >&2; exit $RC_USAGE ;;
  esac
done
[ -n "$DIR" ] || DIR="$ROOT/build/MilBridge"    # 射程目录收口（`--root` 改根时随之改）
run_check; exit $?
