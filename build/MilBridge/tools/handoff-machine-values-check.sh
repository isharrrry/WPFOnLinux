#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# handoff-machine-values-check.sh —— 「机器值格有牙看着」牙（`B-11` 的牙面；`t48`／W4b 落地）
#
# 【要解决的缺口】`build/MilBridge/HANDOFF-NEXT.md` 的「机器值『现取生成契约』」（`t10`／W1）那张
#   **9 格表**是**手抄现跑**的 ⇒ 此后每代必陈旧，而**仓内零读者**（无牙看着）。
#
# 【判据（逐格可判真假）】对表内 9 格**逐格现跑该格的现取生成命令**，与**件内该格的现值**比对：
#   · 一致 ⇒ `state=equal`；不等 ⇒ `HANDOFF_MV=FAIL` 并**逐格点名** `cell=#N anchor=… in-repo=… live=…`
#   · 「现值」的来源（**优先级**）：① 本件内 **dated 更正行**（`机器值契约更正 · cell=#N`）里给的现值
#     ② 表内该行「现取值」列原文。⇒ 更正行**不是**免死金牌：它的值同样被现跑命令对拍。
#   · **非机读格**（`非机读` 具名）：该格的「现取值」列是**散文**、无单行机读形态 ⇒ 上屏 `state=manual`
#     并计数；**这不是「解析不了就跳过」**：它是**显式分类 + 上屏 + 计数**（跳过会是静默）。
#   · ⚠️ **射程边界（如实写）**：本牙判「**值与件内记载是否一致**」，**不**判「该值本身是否可信」；
#     表格行数 ≠ 9 / 表头锚找不到 / 更正行解析失败 ⇒ `HANDOFF_MV=NOINFO|FAIL`（**不许静默判绿**）。
#
# 【三态】rc=0 `HANDOFF_MV=PASS cells=9 …`｜rc=1 `HANDOFF_MV=FAIL`（逐格点名）｜rc=2 `=NOINFO`（表/锚缺失）
# 【自述】已接线：`verify-all.sh` 步名 `HANDOFF-MV`；覆盖面已计入（`build/close-wave.sh` 的 `fp_inputs()`）。
# 【测试钩子】`--selftest`：三例（真件正极／改一字符反极／行数≠9 ⇒ NOINFO），零网络、零 `$R` 写入。
# 用法：bash handoff-machine-values-check.sh [--file PATH] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="${HMVC_ROOT:-$(cd -- "$SELF_DIR/../../.." && pwd)}"
LEADIN='逐格对照（「现取值」全部由右侧命令现跑取得'
RC_PASS=0; RC_FAIL=1; RC_NOINFO=2; RC_USAGE=4
FILE=""

usage() { sed -n '2,26p' "$SELF" | sed 's/^# \{0,1\}//'; }

# ── 单格：解析 → 现跑 → 比对 ────────────────────────────────────────────────────
# 行文本切分：先把 `\|` 换成哨兵，再按 `|` 切（表格单元里含转义竖线）
split_row() {  # $1=行 ⇒ 每字段一行（1-based：1=#,2=处,3=在册原文,4=现取值,5=命令）
  local s="$1"
  s="${s//\\|/$'\x01'}"
  local IFS='|'
  local -a f=($s)
  local f1="${f[1]//$'\x01'/|}" f2="${f[2]//$'\x01'/|}" f3="${f[3]//$'\x01'/|}"
  local f4="${f[4]//$'\x01'/|}" f5="${f[5]//$'\x01'/|}"
  printf '%s\n' "$f1" "$f2" "$f3" "$f4" "$f5"
}
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }
strip_bt() { local s="$1"; s="${s//\`/}"; printf '%s' "$s"; }

# 更正行取值：`机器值契约更正 · cell=#N` 且同行含 `现值 ＝ \`X\`` 与 `命令：\`Y\``（非机读格给 `非机读`）
corr_of() {  # $1=文件 $2=格号 ⇒ 印 "值<TAB>命令<TAB>形态"（无更正 ⇒ 空）
  local n="$2" line LAST_V='' LAST_C='' LAST_FORM='value' FOUND=0
  while IFS= read -r line; do
    case "$line" in *'机器值契约更正'*"cell=#$n"*) ;; *) continue ;; esac
    local form='value' v=''
    case "$line" in *'非机读'*) form='manual' ;; esac
    v="${line#*现值 ＝ \`}"; v="${v%%\`*}"
    local c="${line#*命令：\`}"; c="${c%%\`*}"
    if [ "$form" = value ] && { [ -z "$v" ] || [ "$v" = "$line" ]; }; then
      printf 'PARSE-FAIL\t\t%s' "$form"; return 0
    fi
    LAST_V="$v"; LAST_C="$c"; LAST_FORM="$form"; FOUND=1
  done < "$1"
  if [ "${FOUND:-0}" = 1 ]; then printf '%s\t%s\t%s' "$LAST_V" "$LAST_C" "$LAST_FORM"; return 0; fi
  printf ''
}

run_cmd() {  # $1=命令 ⇒ stdout 首行（去尾空白）
  local out
  out="$(cd "$ROOT" && timeout 120 bash -c "$1" 2>/dev/null | head -1 || true)"
  printf '%s' "$(trim "$out")"
}

check_file() {  # $1=件 ⇒ rc
  local f="$1" i n=0 line
  [ -r "$f" ] || { echo "HANDOFF_MV=NOINFO reason=file-unreadable file=$f"; return $RC_NOINFO; }
  local lead nhits
  nhits="$(grep -c -F -- "$LEADIN" "$f" || true)"
  lead="$(grep -n -F -- "$LEADIN" "$f" | head -1 | cut -d: -f1 || true)"
  if [ -z "$lead" ]; then echo "HANDOFF_MV=NOINFO reason=leadin-anchor-absent anchor=$LEADIN file=$f"; return $RC_NOINFO; fi
  if [ "$nhits" != 1 ]; then echo "HANDOFF_MV=NOINFO reason=leadin-not-unique hits=$nhits anchor=$LEADIN file=$f"; return $RC_NOINFO; fi
  # 逐行扫，收集连续 9 行 `| N |`
  local -a rows=()
  local seen=0
  while IFS= read -r line; do
    if [ "$seen" = 0 ]; then
      case "$line" in *"$LEADIN"*) seen=1 ;; esac
      continue
    fi
    case "$line" in
      '') if [ "${#rows[@]}" -gt 0 ]; then break; fi; continue ;;
    esac
    case "$line" in
      '| '[0-9]' '*) rows+=("$line") ;;
    esac
  done < "$f"
  n="${#rows[@]}"
  if [ "$n" != 9 ]; then
    echo "HANDOFF_MV=NOINFO reason=table-rows!=9 got=$n anchor=$LEADIN file=$f"
    return $RC_NOINFO
  fi
  local fail=0 equal=0 manual=0 ci v c form live inrepo anchors_put corr
  for line in "${rows[@]}"; do
    mapfile -t F < <(split_row "$line")
    ci="$(trim "${F[0]}")"; ci="${ci//[^0-9]/}"
    local anchors_put; anchors_put="$(trim "${F[1]}")"
    inrepo="$(trim "$(strip_bt "${F[3]}")")"
    corr="$(corr_of "$f" "$ci")"
    form='row'; v="$inrepo"; c="$(strip_bt "${F[4]}")"
    if [ -n "$corr" ]; then
      v="$(printf '%s' "$corr" | cut -f1)"; c="$(printf '%s' "$corr" | cut -f2)"; form="$(printf '%s' "$corr" | cut -f3)"
    fi
    if [ "$v" = 'PARSE-FAIL' ]; then
      echo "HANDOFF_MV_HIT cell=#$ci anchor=${anchors_put} rule=correction-parse-failed"
      fail=$((fail+1)); continue
    fi
    if [ "$form" = manual ]; then
      echo "HANDOFF_MV_CELL cell=#$ci anchor=${anchors_put} state=manual（非机读格：现取值列是散文、无单行机读形态）"
      manual=$((manual+1)); continue
    fi
    case "$c" in ''|*'…'*|*'＋'*|*'；'*) echo "HANDOFF_MV_HIT cell=#$ci anchor=${anchors_put} rule=command-not-executable cmd=$c"; fail=$((fail+1)); continue ;; esac
    live="$(run_cmd "$c")"
    if [ "$live" = "$v" ]; then
      echo "HANDOFF_MV_CELL cell=#$ci anchor=${anchors_put} state=equal live=$live"
      equal=$((equal+1))
    else
      echo "HANDOFF_MV_HIT cell=#$ci anchor=${anchors_put} in-repo=$v live=$live cmd=$c"
      fail=$((fail+1))
    fi
  done
  if [ "$fail" -gt 0 ]; then
    echo "HANDOFF_MV=FAIL cells=9 equal=$equal manual=$manual mismatch=$fail file=$f"
    return $RC_FAIL
  fi
  echo "HANDOFF_MV=PASS cells=9 equal=$equal manual=$manual file=$f"
  return $RC_PASS
}

selftest() {
  local T nf=0 np=0 out rc1 rc2 rc3 v1 v2 v3
  T="$(mktemp -d)"; trap 'rm -rf "$T"' RETURN
  local src="$ROOT/build/MilBridge/HANDOFF-NEXT.md"
  # S1 正极：真件 ⇒ PASS cells=9
  out="$(bash "$SELF" --file "$src" 2>&1)"; rc1=$?
  case "$out" in *HANDOFF_MV=PASS*cells=9*) v1=PASS ;; *) v1=FAIL ;; esac
  [ "$rc1" = 0 ] && [ "$v1" = PASS ] && np=$((np+1)) || nf=$((nf+1))
  echo "HANDOFF_MV_SELFTEST_CASE case=S1 kind=positive rc=$rc1 verdict=$v1 原样=$(printf '%s' "$out" | grep -m1 'HANDOFF_MV=')"
  # S2 反极：把**最后一条**更正行（＝真正 govern 的那条）的现值改一位 ⇒ 必红并点名
  cp -p "$src" "$T/f2.md"
  python3 -c 'import re,sys
p=sys.argv[1]; s=open(p,encoding="utf-8").read().split("\n"); tgt=None
for i,l in enumerate(s):
    if "机器值契约更正" in l and "cell=#" in l: tgt=i
assert tgt is not None
l=s[tgt]; m=re.search(r"现值 ＝ `([^`]+)`", l); assert m
v=m.group(1); nv=v[:-1]+("0" if v[-1]!="0" else "1")
s[tgt]=l.replace("现值 ＝ `"+v+"`","现值 ＝ `"+nv+"`",1)
open(p,"w",encoding="utf-8").write("\n".join(s))' "$T/f2.md"
  out="$(bash "$SELF" --file "$T/f2.md" 2>&1)"; rc2=$?
  v2=OTHER
  case "$out" in *HANDOFF_MV_HIT*) case "$out" in *HANDOFF_MV=FAIL*) v2=FAIL-named ;; esac ;; esac
  [ "$rc2" = 1 ] && [ "$v2" = FAIL-named ] && np=$((np+1)) || nf=$((nf+1))
  echo "HANDOFF_MV_SELFTEST_CASE case=S2 kind=negative rc=$rc2 verdict=$v2 原样=$(printf '%s' "$out" | grep -m1 'HANDOFF_MV_HIT')"
  # S3 行数≠9（只在 9 格表区内删第 9 行）⇒ NOINFO（不许静默判绿）
  grep -v '^| 9 | §1 九位' "$src" > "$T/f3.md"   # 内容锚：只删 9 格表的第 9 行
  out="$(bash "$SELF" --file "$T/f3.md" 2>&1)"; rc3=$?
  case "$out" in *HANDOFF_MV=NOINFO*table-rows!=9*) v3=NOINFO ;; *) v3=OTHER ;; esac
  [ "$rc3" = 2 ] && [ "$v3" = NOINFO ] && np=$((np+1)) || nf=$((nf+1))
  echo "HANDOFF_MV_SELFTEST_CASE case=S3 kind=noinfo rc=$rc3 verdict=$v3 原样=$(printf '%s' "$out" | grep -m1 'HANDOFF_MV=')"
  echo "HANDOFF_MV_SELFTEST=$([ "$nf" = 0 ] && echo PASS || echo FAIL) cases=$((np+nf)) pass=$np fail=$nf"
  [ "$nf" = 0 ] && return $RC_PASS || return $RC_FAIL
}

while [ $# -gt 0 ]; do
  case "$1" in
    --file) FILE="${2:-}"; shift 2 ;;
    --selftest) selftest; exit $? ;;
    -h|--help) usage; exit $RC_PASS ;;
    *) echo "HANDOFF_MV=NOINFO reason=arg-not-accepted $1" >&2; exit $RC_USAGE ;;
  esac
done
[ -n "$FILE" ] || FILE="$ROOT/build/MilBridge/HANDOFF-NEXT.md"
check_file "$FILE"; exit $?
