#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# sentinel-spec-check.sh —— 哨兵「键序／字节格式」规范牙（`t23`／W3a；**本件不接线**，接线归 W4）
#
# 【它挡的是什么】`C-1`：哨兵的**键序／字节格式无规范** ⇒ 同一"哨兵内容"可用不同字节表达 ⇒
#   `sha16` 不可对拍、后人照抄「十键」这类与现场不符的说法（现取是 **13 键**）。
#
# 【规范（载体 ＝ `build/MilBridge/HANDOFF-NEXT.md` 纪律区 dated 行；本件逐条判）】
#   ① 行数 ＝ **13**、**键名集合与键序** 逐字固定（现取）
#   ② 每行形如 `<KEY>=<VALUE>`，**行尾单个 `\n`**、**无空行**、**无 CR**
#   ③ 两枚哨兵 `cmp` 必须相同
#   ④ 各键值 == **权威路径现取**（`provider` 走**工程产出目录**、**禁副本**；`FP` 走 `bridge-src-fp.sh`，**不是** `inputs_fp`）
#   ⑤ `WAVE`／`BASELINE`／`BASELINE_SHA16` == `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN` 行（`w<NN>-freeze`／`#<NN>`／`sha16=`）
#   ⑥ **任何字段不许为空**：取不到必须写 **`none(<reason>)`**（该形态**允许且上屏**，**不判红**；**空值判红**）
#
# 【三态】`rc=0` `SSC=PASS`｜`rc=1` `SSC=FAIL`（逐条点名）｜`rc=2` `SSC=NOINFO`（算不出来 ⇒ **不算绿**）
# 用法：`bash sentinel-spec-check.sh [--selftest]`；环境覆盖：`SSC_S1`／`SSC_S2`／`SSC_CS`／`SSC_CFG`／`SSC_FPNOW`
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SPEC_KEYS='SHA FP PC PF WB WIN32SHIM HBTL WIC PROVIDER DWF WAVE BASELINE BASELINE_SHA16'
SPEC_LINES=13
SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
R="$(cd -- "$SELF_DIR/../../.." && pwd)"
S1="${SSC_S1:-/tmp/bridge-frozen.flag}"
S2="${SSC_S2:-$HOME/wfp-runs/bridge-frozen.flag}"
CS="${SSC_CS:-$R/docs/CURRENT-STATE.md}"
CFG="${SSC_CFG:-Release}"
say() { printf '%s\n' "$*"; }
auth_path() { case "$1" in
  SHA) echo "$R/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so";;
  PC) echo "$R/build/PresentationCore.Linux/bin/$CFG/PresentationCore.dll";;
  PF) echo "$R/build/PresentationFramework.Linux/bin/$CFG/PresentationFramework.dll";;
  WB) echo "$R/build/WindowsBase.Linux/bin/$CFG/WindowsBase.dll";;
  PROVIDER) echo "$R/build/DirectWrite.Linux/Provider/bin/$CFG/DirectWrite.Linux.Provider.dll";;
  WIN32SHIM) echo "$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so";;
  WIC) echo "$R/build/DirectWrite.Linux/wic-shim/libwpfwic.so";;
  HBTL) echo "$R/build/shims/PresentationCore.HbTextLine.cs";;
  DWF) echo "$R/build/DirectWriteForwarder.Linux/bin/$CFG/DirectWriteForwarder.dll";;
  *) return 1;; esac; }
keys_of() { grep -o '^[A-Z0-9_]*=' "$1" 2>/dev/null | sed 's/=$//' | tr '\n' ' '; }
val_of()  { sed -n "s/^$2=//p" "$1" 2>/dev/null | head -1; }

check_one() {   # check_one <file> <label>  ⇒ 打印逐条；rc 由 bad 汇出
  local f="$1" label="$2" bad=0 ks n k v want
  n="$(wc -l < "$f")"
  if [ "$n" -eq "$SPEC_LINES" ]; then say "SSC_LINES=PASS sentinel=$label n=$n"; else say "SSC_LINES=FAIL sentinel=$label got=$n want=$SPEC_LINES"; bad=1; fi
  ks="$(keys_of "$f")"
  if [ "$ks" = "$SPEC_KEYS " ]; then say "SSC_KEYSET=PASS sentinel=$label keys=13 order=spec"; else say "SSC_KEYSET=FAIL sentinel=$label got=[$ks] want=[$SPEC_KEYS ]"; bad=1; fi
  if LC_ALL=C grep -q $'\r' "$f"; then say "SSC_CR=FAIL sentinel=$label 含 CR"; bad=1; else say "SSC_CR=PASS sentinel=$label 无 CR"; fi
  if LC_ALL=C grep -q '^[[:space:]]*$' "$f"; then say "SSC_BLANK=FAIL sentinel=$label 含空行"; bad=1; else say "SSC_BLANK=PASS sentinel=$label 无空行"; fi
  local empties; empties="$(grep -n '=$' "$f" | cut -d: -f1 | tr '\n' ',' )"
  if [ -n "$empties" ]; then say "SSC_EMPTY=FAIL sentinel=$label 空值行=$empties（取不到须写 none(<reason>)）"; bad=1; else say "SSC_EMPTY=PASS sentinel=$label 无空值"; fi
  local nones=''
  for k in $SPEC_KEYS; do v="$(val_of "$f" "$k")"
    case "$v" in none\(*\)) nones="$nones $k";; esac; done
  [ -n "$nones" ] && say "SSC_NONE=ALLOWED sentinel=$label keys=$nones（规范允许的占位形态，上屏不判红）"
  return $bad
}

check_values() {  # 各键值 vs 权威路径现取
  local f="$1" bad=0 k v got
  for k in SHA PC PF WB PROVIDER WIN32SHIM WIC HBTL DWF; do
    v="$(val_of "$f" "$k")"; case "$v" in none\(*\)) continue;; esac
    local p; p="$(auth_path "$k")" || continue
    if [ ! -f "$p" ]; then say "SSC_VALUE=NOINFO key=$k reason=权威件缺席 path=$p"; continue; fi
    got="$(sha256sum "$p" | cut -c1-16)"
    if [ "$v" = "$got" ]; then say "SSC_VALUE=PASS key=$k v=$v"; else say "SSC_VALUE=FAIL key=$k got=$v want=$got path=$p"; bad=1; fi
  done
  v="$(val_of "$f" FP)"
  case "$v" in none\(*\)) : ;; *) got="${SSC_FPNOW:-$(bash "$R/build/bridge-src-fp.sh" 2>/dev/null | sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p')}"
    if [ -z "$got" ]; then say "SSC_VALUE=NOINFO key=FP reason=bridge-src-fp.sh 取不到"; elif [ "$v" = "$got" ]; then say "SSC_VALUE=PASS key=FP v=$v（BRIDGE_SRC_FP，**不是** inputs_fp）"; else say "SSC_VALUE=FAIL key=FP got=$v want=$got（口径：FP=BRIDGE_SRC_FP）"; bad=1; fi;; esac
  # WAVE / BASELINE / BASELINE_SHA16 ⇔ CURRENT-STATE.md 的 BASELINE-FROZEN 行
  local ln gen sha
  ln="$(grep -m1 'BASELINE-FROZEN' "$CS" 2>/dev/null)"
  gen="$(printf '%s\n' "$ln" | sed -n 's/.*gen=#\([0-9][0-9]*\).*/\1/p')"
  sha="$(printf '%s\n' "$ln" | sed -n 's/.*sha16=\([0-9a-f]*\).*/\1/p')"
  if [ -z "$gen" ] || [ -z "$sha" ]; then say "SSC_CS=NOINFO reason=BASELINE-FROZEN 行取不到 cs=$CS"; return $bad; fi
  local w b bs; w="$(val_of "$f" WAVE)"; b="$(val_of "$f" BASELINE)"; bs="$(val_of "$f" BASELINE_SHA16)"
  [ "$b" = "#$gen" ] && say "SSC_VALUE=PASS key=BASELINE v=$b" || { say "SSC_VALUE=FAIL key=BASELINE got=$b want=#$gen"; bad=1; }
  [ "$bs" = "$sha" ] && say "SSC_VALUE=PASS key=BASELINE_SHA16 v=$bs" || { say "SSC_VALUE=FAIL key=BASELINE_SHA16 got=$bs want=$sha"; bad=1; }
  [ "$w" = "w$gen-freeze" ] && say "SSC_VALUE=PASS key=WAVE v=$w" || { say "SSC_VALUE=FAIL key=WAVE got=$w want=w$gen-freeze"; bad=1; }
  return $bad
}

run() {
  local bad=0 rc2=0
  for s in "$S1" "$S2"; do [ -f "$s" ] || { say "SSC=NOINFO reason=sentinel-absent path=$s（**缺一枚不许静默判等**）"; return 2; }; done
  check_one "$S1" a || bad=1
  check_one "$S2" b || bad=1
  if cmp -s "$S1" "$S2"; then say "SSC_CMP=PASS 两枚哨兵 IDENTICAL"; else say "SSC_CMP=FAIL 两枚哨兵不同"; bad=1; fi
  check_values "$S1" || bad=1
  if [ "$bad" -ne 0 ]; then say "SSC=FAIL 规范不满足（逐条见上）"; return 1; fi
  say "SSC=PASS lines=$SPEC_LINES keys=13 cmp=IDENTICAL"; return 0
}

selftest() {
  T="$(mktemp -d)"; trap 'rm -rf "${T:-}"' EXIT
  local np=0 nf=0
  arm() { local name="$1" want="$2" got="$3"
    if [ "$got" = "$want" ]; then np=$((np+1)); say "  ok   $name（rc=$got）"; else nf=$((nf+1)); say "  FAIL $name（got=$got want=$want）"; fi; }
  cp "$S1" "$T/good"; cp "$S1" "$T/good2"
  printf '%s\n' "$(sed -n '1p' "$T/good")" "$(sed -n '3p' "$T/good")" "$(sed -n '2p' "$T/good")" "$(sed -n '4,13p' "$T/good")" > "$T/disorder"
  sed 's/^PROVIDER=.*/PROVIDER=/' "$T/good" > "$T/emptied"
  export SSC_CS="$CS"
  SSC_S1="$T/good" SSC_S2="$T/good2" bash "$0" >/dev/null 2>&1; arm '正常 ⇒ 绿(rc=0)' 0 "$?"
  SSC_S1="$T/disorder" SSC_S2="$T/disorder" bash "$0" >/dev/null 2>&1; arm '键序打乱 ⇒ 红(rc=1)' 1 "$?"
  SSC_S1="$T/emptied" SSC_S2="$T/emptied" bash "$0" >/dev/null 2>&1; arm '字段清空 ⇒ 红(rc=1)' 1 "$?"
  SSC_S1="$T/good" SSC_S2="$T/nope" bash "$0" >/dev/null 2>&1; arm '缺一枚 ⇒ NOINFO(rc=2)' 2 "$?"
  say "SSC_SELFTEST=$( [ "$nf" -eq 0 ] && echo PASS || echo FAIL ) cases=$((np+nf)) pass=$np fail=$nf"
  [ "$nf" -eq 0 ] && return 0 || return 1
}

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  '') run; exit $? ;;
  *) echo "用法: $0 [--selftest]" >&2; exit 2 ;;
esac
