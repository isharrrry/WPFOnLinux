#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# handoff-machine-values-check.sh —— 「机器值格有牙看着」牙（`B-11`；`t48` 落、`t54` F1–F5、`t57` G1–G4）
#
# 【判据（逐格可判真假）】对 `HANDOFF-NEXT.md` 那 **9 格表**逐格**现跑该格命令**，与件内现值比对。
#   取值优先级：① 件内 `机器值契约更正 · cell=#N` **最后一条**（只增不改 ⇒ 追加取代旧行）② 表内「现取值」列。
#   状态：`state=equal`｜`state=manual`（该格**不对拍**）｜`state=mismatch`（有差异 ⇒ 逐格点名）。
#
# 【口径句（`t57` 写死）】
#   ① **表原文列**（9 行 `| N | …` 的「现取值」列）**自 `t48` 起为留档**：判据面在**更正行**；逐格把
#      `table=`／`corrected=`／`live=` **三值都上屏**（只改表列 ⇒ 可见、**不判**：已知边界，不许当绿）。
#   ② **维护契约（逐字）**：「**改了覆盖面内任一件 ⇒ 必须同趟追写 `cell=#1` 的 `ts=` 更正行**；
#      改了**任一 route 件** ⇒ 追写 `cell=#4`（本波已把 `#4` 改成**只判稳定子串**：`^DEFREG=PASS` 前缀 ∧
#      `declared=(\d+) route_ids=\1` **形态等价** ⇒ **具体计数不再是被判量**，只进 `HANDOFF_MV_DIAG` 诊断列）。」
#   ③ **门禁判据只能是**被门禁覆盖的世界**的函数**（`t57`／G1）：`cell=#8` **不再**对拍「全机脏件数」，
#      改判**本波预登记在位谓词**（命令取 `docs/WAVE81-PREREGISTRATION.md` 的**存在且非空**）；「其它车道在飞」
#      的信息**只进旁注** `HANDOFF_MV_NOTE lane-activity=<n>`（**不进 `equal` 计数、不影响 `rc``）。
#   ④ **拒收族（`t57`／G3）**：**「对拍 `HEAD`／工作树状态／流水线相位」类命令一律拒收**（正则
#      `HEAD|git log|git status|git rev-parse|git ls-remote`）⇒ `rule=cell-not-comparable-to-pipeline-state`；
#      **`cell=#7`（推送面）若呈机读形态**（同行同时给出 `现值 ＝ ` 与 `命令：`）⇒
#      **`rule=cell-7-not-comparable-to-HEAD`**（`t50` F1 的时间炸弹 ⇒ 由本牙拦住）。
#   ⑤ **报头分化（`t57`／G2）**：`HANDOFF_MV=PASS`（`rc=0`）／**`HANDOFF_MV=DIVERGED reason=cell-mismatch`**
#      （有格与现取不符 ⇒ **追写 dated 更正行**）／**`HANDOFF_MV=FOREIGN reason=<…>`**（差异源**不在本件写域**：
#      拒收族、不可比格）／**`HANDOFF_MV=NOINFO reason=<…>`**（表/锚缺失、行数≠9、不可读）⇒ **一个 `FAIL` 不许承担三种语义**。
#   ⑥ **自测自主性（`t57`／G4）**：`--selftest` 的**正极用自造夹具**（仓外 `mktemp -d`）⇒ **不依赖活件**；
#      活件好坏由**正极真跑**那条腿判（它本就该随世界变）。夹具腿：S1 正极／S2 篡改点名／S3 行数≠9／S4 回退／
#      S5 **活件副本被改陈旧 ⇒ 自测仍 PASS**（自主性证明）／S6 **活件真跑仍如实反映**。
# 【自述】已接线：`verify-all.sh` 步名 `HANDOFF-MV`；覆盖面已计入（`build/close-wave.sh` 的 `fp_inputs()`）。
# 【用法】bash handoff-machine-values-check.sh [--file PATH] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail
SELF="${BASH_SOURCE[0]}"; SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="${HMVC_ROOT:-$(cd -- "$SELF_DIR/../../.." && pwd)}"
LEADIN='逐格对照（「现取值」全部由右侧命令现跑取得'
REJECT_ERE='HEAD|git log|git status|git rev-parse|git ls-remote'
RC_PASS=0; RC_FAIL=1; RC_NOINFO=2; RC_USAGE=4
FILE=""
split_row() {  # $1=行 ⇒ 印 5 个字段（1-based 1..5；`\|` 哨兵还原）
  local s="$1"; s="${s//\\|/$'\x01'}"; local IFS='|'; local -a f=($s)
  local f1="${f[1]//$'\x01'/|}" f2="${f[2]//$'\x01'/|}" f3="${f[3]//$'\x01'/|}" f4="${f[4]//$'\x01'/|}" f5="${f[5]//$'\x01'/|}"
  printf '%s\n' "$f1" "$f2" "$f3" "$f4" "$f5"
}
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }
strip_bt() { local s="$1"; s="${s//\`/}"; printf '%s' "$s"; }
corr_of() {  # $1=件 $2=格号 ⇒ "值<TAB>命令<TAB>形态<TAB>锚"（**最后一条为准**；无 ⇒ 空）
  local n="$2" line LAST_V='' LAST_C='' LAST_FORM='value' LAST_ANC='' FOUND=0
  while IFS= read -r line; do
    case "$line" in *'机器值契约更正'*"cell=#$n"*) ;; *) continue ;; esac
    local form='value' v='' c='' anc=''
    case "$line" in *'非机读'*) form='manual' ;; esac
    v="${line#*现值 ＝ \`}"; v="${v%%\`*}"
    c="${line#*命令：\`}"; c="${c%%\`*}"
    anc="${line#*锚=}"; case "$line" in *'锚='*) anc="${anc%%[，,；;]*}" ;; *) anc='' ;; esac
    if [ "$form" = value ] && { [ -z "$v" ] || [ "$v" = "$line" ]; }; then
      FIRST_BAD=1
    fi
    LAST_V="$v"; LAST_C="$c"; LAST_FORM="$form"; LAST_ANC="$anc"; FOUND=1
  done < "$1"
  if [ "${FIRST_BAD:-0}" = 1 ] && [ -z "$LAST_V" ]; then printf 'PARSE-FAIL\t\t%s\t' "$LAST_FORM"; return 0; fi
  [ "$FOUND" = 1 ] && printf '%s\t%s\t%s\t%s' "$LAST_V" "$LAST_C" "$LAST_FORM" "$LAST_ANC"
  printf ''
}
run_cmd() { local out; out="$(cd "$ROOT" && timeout 120 bash -c "$1" 2>/dev/null | head -1 || true)"; printf '%s' "$(trim "$out")"; }
check_file() {  # $1=件 ⇒ 印判词；rc=0 PASS／1 DIVERGED|FOREIGN／2 NOINFO
  local f="$1" line nhits lead
  [ -r "$f" ] || { echo "HANDOFF_MV=NOINFO reason=file-unreadable file=$f"; return $RC_NOINFO; }
  nhits="$(grep -c -F -- "$LEADIN" "$f" || true)"
  lead="$(grep -n -F -- "$LEADIN" "$f" | head -1 | cut -d: -f1 || true)"
  [ -n "$lead" ] || { echo "HANDOFF_MV=NOINFO reason=leadin-anchor-absent anchor=$LEADIN file=$f"; return $RC_NOINFO; }
  [ "$nhits" = 1 ] || { echo "HANDOFF_MV=NOINFO reason=leadin-not-unique hits=$nhits file=$f"; return $RC_NOINFO; }
  local -a rows=(); local seen=0
  while IFS= read -r line; do
    if [ "$seen" = 0 ]; then case "$line" in *"$LEADIN"*) seen=1 ;; esac; continue; fi
    case "$line" in '') [ "${#rows[@]}" -gt 0 ] && break; continue ;; esac
    case "$line" in '| '[0-9]' '*) rows+=("$line") ;; esac
  done < "$f"
  [ "${#rows[@]}" = 9 ] || { echo "HANDOFF_MV=NOINFO reason=table-rows!=9 got=${#rows[@]} anchor=$LEADIN file=$f"; return $RC_NOINFO; }
  local equal=0 manual=0 mism=0 uncomparable=0 reasons='' rc_reason=''
  for line in "${rows[@]}"; do
    local -a F=(); mapfile -t F < <(split_row "$line")
    local ci anch inrepo corr v c form live why
    ci="$(trim "${F[0]}")"; ci="${ci//[^0-9]/}"
    anch="$(trim "${F[1]}")"
    inrepo="$(trim "$(strip_bt "${F[3]}")")"
    corr="$(corr_of "$f" "$ci")"
    form='row'; v="$inrepo"; c="$(strip_bt "${F[4]}")"
    if [ -n "$corr" ]; then
      v="$(printf '%s' "$corr" | cut -f1)"; c="$(printf '%s' "$corr" | cut -f2)"
      form="$(printf '%s' "$corr" | cut -f3)"; local canc; canc="$(printf '%s' "$corr" | cut -f4)"
      [ -n "$canc" ] && anch="$canc（锚已在更正行改写；表内原锚='$anch'）"
    fi
    # ④ 拒收族：`#7` 机读形态 ＋ 「对拍流水线/工作树状态」类命令
    if [ "$ci" = 7 ]; then
      if [ "$form" = value ] && [ -n "$v" ] && [ -n "$c" ]; then echo "HANDOFF_MV_HIT cell=#7 anchor=${anch} rule=cell-7-not-comparable-to-HEAD reason=not-comparable cmd=$c（`#7` 是推送面/流水线敏感量 ⇒ 不许呈机读形态）"; uncomparable=$((uncomparable+1)); continue; fi
    fi
    if [ -n "$c" ] && printf '%s' "$c" | grep -qE "$REJECT_ERE"; then
      echo "HANDOFF_MV_HIT cell=#$ci anchor=${anch} rule=cell-not-comparable-to-pipeline-state reason=not-comparable cmd=$c"
      uncomparable=$((uncomparable+1)); continue
    fi
    if [ "$v" = 'PARSE-FAIL' ]; then
      echo "HANDOFF_MV_HIT cell=#$ci anchor=${anch} rule=correction-parse-failed reason=not-comparable"; uncomparable=$((uncomparable+1)); continue
    fi
    if [ "$form" = manual ]; then
      echo "HANDOFF_MV_CELL cell=#$ci anchor=${anch} state=manual table=$inrepo corrected=- live=-（该格不对拍：见牙头口径句①②④）"
      manual=$((manual+1)); continue
    fi
    case "$c" in ''|*'…'*|*'＋'*|*'；'*) echo "HANDOFF_MV_HIT cell=#$ci anchor=${anch} rule=command-not-executable reason=not-comparable cmd=$c"; uncomparable=$((uncomparable+1)); continue ;; esac
    live="$(run_cmd "$c")"
    if [ "$ci" = 4 ]; then
      # ② `#4`：只判**稳定子串**（前缀 ∧ `declared=(\\d+) route_ids=\\1` 形态等价）；计数只进诊断列
      local ep lp ev lv
      ep="$(printf '%s' "$v"  | grep -oE '^DEFREG=[A-Z]+' | head -1)"
      lp="$(printf '%s' "$live" | grep -oE '^DEFREG=[A-Z]+' | head -1)"
      ev="$(printf '%s' "$v"  | grep -oE 'declared=[0-9]+ route_ids=[0-9]+' | head -1)"
      lv="$(printf '%s' "$live" | grep -oE 'declared=[0-9]+ route_ids=[0-9]+' | head -1)"
      local lv_ok=1; [ -n "$lv" ] || lv_ok=0
      if [ "$lv_ok" = 1 ]; then
        [ "$(printf '%s' "$lv" | awk '{print $1}' | sed 's/^declared=//')" = "$(printf '%s' "$lv" | awk '{print $2}' | sed 's/^route_ids=//')" ] || lv_ok=0
      fi
      echo "HANDOFF_MV_DIAG cell=#4 declared_live=$(printf '%s' "$lv" | awk '{print $1}' | sed 's/^declared=//') route_ids_live=$(printf '%s' "$lv" | awk '{print $2}' | sed 's/^route_ids=//') declared_inrepo=$(printf '%s' "$ev" | awk '{print $1}' | sed 's/^declared=//') route_ids_inrepo=$(printf '%s' "$ev" | awk '{print $2}' | sed 's/^route_ids=//')（**计数不是被判量**）"
      if [ "$ep" = "$lp" ] && [ "$lv_ok" = 1 ]; then
        echo "HANDOFF_MV_CELL cell=#4 anchor=${anch} state=equal table=$inrepo corrected=$v live=$live（判据＝前缀 ∧ 两值相等）"
        equal=$((equal+1))
      else
        echo "HANDOFF_MV_HIT cell=#4 anchor=${anch} rule=route-file-changed-since-ts reason=foreign-lane-activity in-repo=$v live=$live"
        mism=$((mism+1)); reasons="$reasons,#4:route-file-changed-since-ts"
      fi
      continue
    fi
    if [ "$live" = "$v" ]; then
      echo "HANDOFF_MV_CELL cell=#$ci anchor=${anch} state=equal table=$inrepo corrected=$v live=$live"
      equal=$((equal+1))
    else
      case "$ci" in
        1) why='covered-file-changed-since-ts' ;;
        2|5) why='count-changed-since-ts' ;;
        3|6|9) why='external-state-changed-since-ts' ;;
        *) why='cell-value-changed-since-ts' ;;
      esac
      echo "HANDOFF_MV_HIT cell=#$ci anchor=${anch} rule=cell-mismatch reason=$why in-repo=$v live=$live cmd=$c"
      mism=$((mism+1)); reasons="$reasons,#$ci:$why"
    fi
  done
  local lane; lane="$(cd "$ROOT" && git status --porcelain 2>/dev/null | grep -vcE '^.. (build/|docs/|samples/|src/|verify-all\.sh|README\.md|handoff\.md)' || true)"
  echo "HANDOFF_MV_NOTE lane-activity=${lane}（= 写域面（build/ docs/ samples/ src/ 根件）之外的脏件数；**旁注，不进 equal 计数、不影响 rc**）"
  if [ "$uncomparable" -gt 0 ]; then
    echo "HANDOFF_MV=FOREIGN reason=cell-not-comparable cells=9 equal=$equal manual=$manual mismatch=$mism uncomparable=$uncomparable reasons=${reasons:-none}"
    return $RC_FAIL
  fi
  if [ "$mism" -gt 0 ]; then
    echo "HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=$equal manual=$manual mismatch=$mism uncomparable=$uncomparable reasons=${reasons:-none}"
    return $RC_FAIL
  fi
  echo "HANDOFF_MV=PASS cells=9 equal=$equal manual=$manual mismatch=0 uncomparable=0 reasons=${reasons:-none}"
  return $RC_PASS
}
make_fixture() {  # $1=目标件路径 ⇒ 造一份**自治夹具**（9 格 ＋ 9 条更正行；全部用本地 printf 命令）
  local out="$1" i
  {
    printf '%s\n' "$LEADIN（**夹具**）"; printf '\n'
    printf '| # | 处（内容锚） | 在册原文 | 现取值 | 现取生成命令 |\n|---|---|---|---|---|\n'
    for i in 1 2 3 4 5 6 7 8 9; do
      if [ "$i" = 4 ]; then printf '| 4 | §7-3 登记册自洽 |  | `DEFREG=PASS declared=218 route_ids=218` | `echo DEFREG=PASS declared=218 route_ids=218` |\n'
      else printf '| %s | 夹具格%s |  | `FIX%s` | `printf FIX%s` |\n' "$i" "$i" "$i" "$i"; fi
    done
    printf '\n'
    for i in 1 2 3 4 5 6 7 8 9; do
      if [ "$i" = 4 ]; then printf '⏪ **机器值契约更正 · cell=#4**：以现取为准；`ts=2026-01-01T00:00:00.000+0800` 时 现值 ＝ `DEFREG=PASS declared=218 route_ids=218`（命令：`echo DEFREG=PASS declared=218 route_ids=218`）\n'
      elif [ "$i" = 7 ]; then printf '⏪ **机器值契约更正 · cell=#7**：非机读（夹具：推送面不对拍）\n'
      else printf '⏪ **机器值契约更正 · cell=#%s**：以现取为准；`ts=2026-01-01T00:00:00.000+0800` 时 现值 ＝ `FIX%s`（命令：`printf FIX%s`）\n' "$i" "$i" "$i"; fi
    done
  } > "$out"
}
selftest() {
  local T np=0 nf=0 out rc INNER="${HMVC_SELFTEST_INNER:-0}"
  T="$(mktemp -d)"; trap 'rm -rf "$T"' RETURN
  local src="$ROOT/build/MilBridge/HANDOFF-NEXT.md"
  make_fixture "$T/fix.md"
  # S1 正极（**自造夹具**，不依赖活件）
  out="$(bash "$SELF" --file "$T/fix.md" 2>&1)"; rc=$?
  case "$out" in *HANDOFF_MV=PASS*cells=9*) [ "$rc" = 0 ] && np=$((np+1)) || nf=$((nf+1)) ;; *) nf=$((nf+1)) ;; esac
  echo "HANDOFF_MV_SELFTEST_CASE case=S1 kind=positive-fixture rc=$rc 原样=$(printf '%s' "$out" | grep -m1 'HANDOFF_MV=')"
  # S2 反极：篡改夹具中 **cell=#9** 最后一条更正行的现值 ⇒ 必红且**点名该格** ＋ mismatch≥1
  TARGET_CELL=9
  cp -p "$T/fix.md" "$T/f2.md"
  python3 -c '
import re,sys
p=sys.argv[1]; c=sys.argv[2]; s=open(p,encoding="utf-8").read().split("\n"); tgt=None
for i,l in enumerate(s):
    if "机器值契约更正" in l and ("cell=#"+c) in l: tgt=i
assert tgt is not None
l=s[tgt]; m=re.search(r"现值 ＝ `([^`]+)`", l); assert m
v=m.group(1); nv=v[:-1]+("0" if v[-1]!="0" else "1")
s[tgt]=l.replace("现值 ＝ `"+v+"`","现值 ＝ `"+nv+"`",1)
open(p,"w",encoding="utf-8").write("\n".join(s))' "$T/f2.md" "$TARGET_CELL"
  out="$(bash "$SELF" --file "$T/f2.md" 2>&1)"; rc=$?
  local mm; mm="$(printf '%s\n' "$out" | sed -n 's/.*mismatch=\([0-9]*\).*/\1/p' | tail -1)"
  local v2=OTHER
  printf '%s\n' "$out" | grep -qF "HANDOFF_MV_HIT cell=#$TARGET_CELL" && printf '%s\n' "$out" | grep -qF 'rule=cell-mismatch' && v2=HIT-named-this-cell
  [ "$rc" = 1 ] && [ "$v2" = HIT-named-this-cell ] && [ -n "$mm" ] && [ "$mm" -ge 1 ] && np=$((np+1)) || nf=$((nf+1))
  echo "HANDOFF_MV_SELFTEST_CASE case=S2 kind=negative-fixture rc=$rc verdict=$v2 target=cell=#$TARGET_CELL mismatch=$mm 原样=$(printf '%s' "$out" | grep -m1 "HANDOFF_MV_HIT cell=#$TARGET_CELL")"
  # S3 夹具行数≠9 ⇒ NOINFO
  grep -v '^| 9 | 夹具格9' "$T/fix.md" > "$T/f3.md"
  out="$(bash "$SELF" --file "$T/f3.md" 2>&1)"; rc=$?
  case "$out" in *HANDOFF_MV=NOINFO*table-rows!=9*) [ "$rc" = 2 ] && np=$((np+1)) || nf=$((nf+1)) ;; *) nf=$((nf+1)) ;; esac
  echo "HANDOFF_MV_SELFTEST_CASE case=S3 kind=noinfo rc=$rc 原样=$(printf '%s' "$out" | grep -m1 'HANDOFF_MV=')"
  # S4 回退：未篡改夹具 ⇒ 该格回 equal
  out="$(bash "$SELF" --file "$T/fix.md" 2>&1)"; rc=$?
  printf '%s\n' "$out" | grep -F "HANDOFF_MV_CELL cell=#$TARGET_CELL" | grep -q 'state=equal' && np=$((np+1)) || nf=$((nf+1))
  echo "HANDOFF_MV_SELFTEST_CASE case=S4 kind=revert rc=$rc 原样=$(printf '%s' "$out" | grep -m1 "HANDOFF_MV_CELL cell=#$TARGET_CELL")"
  # S5 自主性（`t57`／G4 验收②）：把**活件副本改陈旧**放进沙箱 ROOT ⇒ 用 `HMVC_ROOT` 跑 `--selftest` ⇒ **仍须 PASS**
  if [ -r "$src" ] && [ "$INNER" = 0 ]; then
    mkdir -p "$T/prod/build/MilBridge"; cp -p "$src" "$T/prod/build/MilBridge/HANDOFF-NEXT.md"
    printf '⏪ **机器值契约更正 · cell=#5**：以现取为准；`ts=2026-01-01T00:00:00.000+0800` 时 现值 ＝ `STALE-BOGUS`（命令：`printf STALE-BOGUS`）\n' >> "$T/prod/build/MilBridge/HANDOFF-NEXT.md"
    out="$(HMVC_SELFTEST_INNER=1 HMVC_ROOT="$T/prod" bash "$SELF" --selftest 2>&1)"; rc=$?
    local s5; s5="$(printf '%s' "$out" | sed -n 's/.*HANDOFF_MV_SELFTEST=\([A-Z]*\).*/\1/p' | tail -1)"
    local s5prod; s5prod="$(printf '%s' "$out" | grep -m1 'case=S6' | sed 's/.*原样=//')"
    if [ "$s5" = PASS ] && [ "$rc" = 0 ]; then np=$((np+1)); else nf=$((nf+1)); fi
    echo "HANDOFF_MV_SELFTEST_CASE case=S5 kind=autonomy-stale-production 陈旧活件沙箱下 selftest=$s5；该沙箱的活件腿 原样=${s5prod}（**两条腿分开：自测不依赖活件；活件好坏由正极真跑判**）"
  fi
  # S6 正极真跑（活件）—— **如实反映**（不参与自测的闸，只上屏）
  if [ -r "$src" ]; then
    out="$(bash "$SELF" --file "$src" 2>&1)"; rc=$?
    echo "HANDOFF_MV_SELFTEST_CASE case=S6 kind=production rc=$rc 原样=$(printf '%s' "$out" | grep -m1 'HANDOFF_MV=')"
  fi
  echo "HANDOFF_MV_SELFTEST=$([ "$nf" = 0 ] && echo PASS || echo FAIL) cases=$((np+nf)) pass=$np fail=$nf（闸只含 S1–S4；S5／S6 为信息腿）"
  [ "$nf" = 0 ] && return $RC_PASS || return $RC_FAIL
}
while [ $# -gt 0 ]; do
  case "$1" in
    --file) FILE="${2:-}"; shift 2 ;;
    --selftest) selftest; exit $? ;;
    -h|--help) sed -n '2,28p' "$SELF" | sed 's/^# \{0,1\}//'; exit $RC_PASS ;;
    *) echo "HANDOFF_MV=NOINFO reason=arg-not-accepted arg=$1" >&2; exit $RC_USAGE ;;
  esac
done
[ -n "$FILE" ] || FILE="$ROOT/build/MilBridge/HANDOFF-NEXT.md"
check_file "$FILE"; exit $?
