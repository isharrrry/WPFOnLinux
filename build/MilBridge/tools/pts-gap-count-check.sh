#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════════
# `build/MilBridge/tools/pts-gap-count-check.sh` —— `D-G70`「在册数」**防漂移牙**
#    （`TASK-0720` 残项；模块由车道 W175A 出，落仓由波 `#76` 的唯一写者执行）
#
# 【件头自述 · 接线状态】**未接线**（不进 verify-all，由主控编排）
#   —— 本件**不是** `verify-all.sh` 的任何一步（`grep -c 'pts-gap-count-check' verify-all.sh`
#   故意恒为 `0`）。它的读者是 `build/close-wave.sh` 的
#   `──── [5b/6] 在册数防漂移（D-G70）` 段（`#76` 接线）。
#   ⚠️ 主控 `2026-09-26` 裁定：**接线走 `close-wave.sh` 冻前，不加 `verify-all` 步** ——
#      理由是「冻结那一刻才是这个数说话的地方」。
#   ⚠️ 本自述句是**承重文本**：本模块的 `landing.sh` 会断言
#      「件头这句」与「`verify-all.sh` 里真没有本件的 `run_step`」**同时成立**（`D-G136` 族）。
#
# 【它判什么】`D-G70` 的「在册数」此前是一条**零守卫的裸文本**：`#66` 在**同一波里**
#   既把 111 更正为 `103／91／97`、又落了 `P03`（`win32_pts.c` 新增 3 条 `LsErr` 诚实失败导出，
#   `exports 547→550`）⇒ 那 3 个 `Lo*` 名字当场**离开缺口名单**，于是**更正它的那一刻它就已经过期了**
#   （真值 `100／88／97`）。而当时**没有任何在跑读数会响**（现算：`check-shim-coverage`／
#   `nl-intent-check`／`111-sweep`／`check-numbers` 在 `verify-all.sh`／`integration-wave.sh`／
#   `known-red.json` 里**全 0 命中**）。本牙把这三个数变成**每次冻结都现算 ＋ 逐字段对账**。
#
# 【怎么判（三档，零余量）】
#   ① **现算**（唯一命令）：`python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier all`
#      ⇒ 取 `[PresentationNative_cor3.dll]` 那一节的名单，再按三条**机械**扣减/加项：
#        `dead`     =（`Pts.cs` 里 `#if NEVER` 区间成员 ∩ 缺口名单）   ← 工具不求值预处理
#        `artifact` =（`*Wrapper` 尾名 ∧ 其 **`EntryPoint` 逐字已在 `exports.txt`**）← 工具误报
#        `stubs`    =（`win32_pts.c` 里 `return wpf_pts_gap("…)` 的条数，须 == `k_pts_entries[]` 表长）
#        `ops = tool − dead − artifact` ｜ `impl = ops + stubs`
#   ② **对账声明行**（唯一机读行，本仓体例 `VERIFYALL-STEPS-DECL`／`DEFREG_DECL` 同族）：
#        `# PTSGAP-DECL: tool=… dead=… artifact=… ops=… impl=… so16=… exports=… w66pre16=…`
#      **逐字段相等**（`!=` 即红，**不给余量**）。后三格是**内容锚（pin）**：
#        · `so16`／`exports` 一变 ⇒ 报「导出面变了，在册数该重算」，而不是悄悄放过；
#        · `w66pre16` = `docs/WAVE66-PREREGISTRATION.md` 的 sha16 —— 那是 `C1` 的**冻证据**。
#          `C1` 要求 `win32_classification.c:52` 保留「可操作 91」；本波的第 9 处替换**必然**违反它，
#          处置是「**冻证据一字不动**」⇒ 本钉把这句话变成**机器断言**（该件被改 ⇒ 当场红）。
#   ③ **正文复述位**（**内容锚**，不许引绝对行号）：`docs/ROUTES.md`（三种写法）／
#      `README.md`／`build/MilBridge/HANDOFF-NEXT.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`
#      （`D-G70`）／`docs/unimplemented.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`
#      —— 逐处抽数，**任一处不等 ⇒ 逐处点名并红**。
#   ④ **空边必须响亮失败**（不算绿）：输入缺失／工具 `rc≠0`／抽取命中数 `==0`／
#      `Wrapper` 集合为空 ⇒ `PTSGAP=NOINFO reason=…` ＋ `rc=3`。
#   ⑤ **`D-G141` 族**：复述位里**写进去的命令必须真能跑** —— 把复述位那些行里的
#      `bash <path>.sh` 引用解出来，逐条断言 `$SITES/<path>` **真存在**；有引用却指向不存在的件
#      ⇒ `PTSGAP_CITED=FAIL` ＋ `rc=1`（**可用 `PTSGAP_CITED_STRICT=0` 降为诊断，不改 `rc`**）。
#      现场动因：主控备好的第 1 处替换文本里写的是 `bash build/MilBridge/tools/pts-gap-count.sh`，
#      而本件的真名是 `…-check.sh` ⇒ 那句引用**永远跑不起来**。抽到 **0 条引用** ⇒
#      `PTSGAP_CITED=NOINFO`（**响亮**，但不改 `rc` —— 它是辅助轨，不是本牙的判定本体）。
#
# 【两极化（`--selftest`，7 腿，其中 5 腿断言「必须红」）】合成夹具，不需要 `$R` 的真正文：
#   L1 正极性（全部复述位 == 现算 ∧ 声明自洽）⇒ `PASS`｜L2 正文某处 +1 ⇒ `FAIL` 并点名该件
#   ｜L3 声明 `ops` +1 ⇒ `FAIL` `DRIFT ops`｜L4 复述位整件缺席 ⇒ `FAIL SITE-ABSENT`
#   ｜L5 复述位在但抽不到（形态漂移）⇒ `FAIL SITE-NOHIT`｜L6 声明件缺席 ⇒ `NOINFO`＋`rc=3`
#   ｜L7 内容锚 `so16` 错 ⇒ `FAIL DRIFT so16`。
#   ⚠️ **为什么用合成夹具而不是真件**：真件的正极性依赖「主控那 8 处替换已落仓」，
#      把它写进自测 ⇒ **自测会随主控的批次状态变红/变绿**（不可复现的仪器）。
#      真树上的两极化由本模块的 `polarity.sh` 单独给读数（现读：**真树今天就是红的**）。
#
# 【射程边界（如实写，不许读宽）】
#   · 它判「**在册数与其复述位一致**」，**不判**「88／97 这个数**在语义上**对不对」
#     （工具的 `--tier all` 口径本身是否正确，不在本牙射程内 —— 那是 `D-G70` 的取证部分）。
#   · 它**只认**复述位的**形态**；主控若把某个复述位改成第四种写法 ⇒ 本牙报
#     `SITE-NOHIT`（**响亮**，方向安全），需要**同趟**补一条抽取式。
#   · `Nl*` 6 条「有意降级」判据不由本件承担（那是 `nl-intent-check.sh`，`#66` 已入覆盖面）。
#   · 复述位所在的**文档件本身**不在 `build/close-wave.sh` 的 `fp_inputs()` 覆盖面里
#     ⇒ 「文档被改」**不**移动 `inputs_fp`；但改了**数**会在**每一次冻结**当场可见（本牙每次都跑）。
#     这是**如实登记的射程边界**，不是疏漏（见 `criteria.md` §4）。
#
# 【成本】纯读、零 `dotnet`、不写 `$R`；现测 < 3 s。
# 【卫生】临时件一律 `mktemp -d` ＋ `trap … EXIT` 自清；**不用**共享 `/tmp`
#   （根默认 `$HOME/.cache/wpf-linux/tmp`，可用 `PTSGAP_TMPROOT` 覆盖）。
# ══════════════════════════════════════════════════════════════════════════════════
set -uo pipefail

R=${R:-/home/links-dev/netTest/wpf-linux-20260906/wpf-linux}
N=src/WpfGfx.Linux.Native
DECL=${DECL:-$N/tools/pts-gap-decl.txt}
SITES=${SITES:-$R}                                   # 复述位的**根**
CITED_STRICT=${PTSGAP_CITED_STRICT:-1}               # 1 = 引用不存在 ⇒ 红；0 = 只诊断
SELFTEST=0
case "${1:-}" in
  --selftest) SELFTEST=1 ;;
  ""|--check) ;;
  *) echo "用法: $0 [--selftest]" >&2; exit 2 ;;
esac
SELF=$(readlink -f "$0")   # ⚠️ 本脚本会 cd 到 $R ⇒ 自调用必须用绝对路径（否则 --selftest 静默跑空）

# ── 临时区（私有根 ＋ 自清 trap；纪律 43／44：不许共享 /tmp）──────────────────────
TMPROOT=${PTSGAP_TMPROOT:-$HOME/.cache/wpf-linux/tmp}
mkdir -p "$TMPROOT" 2>/dev/null || { echo "PTSGAP=NOINFO reason=tmp-root-unwritable($TMPROOT)"; exit 3; }
TMPD=$(mktemp -d "$TMPROOT/ptsgap.XXXXXX") || { echo "PTSGAP=NOINFO reason=mktemp"; exit 3; }
trap 'rm -rf "$TMPD"' EXIT

rc=0
cd "$R" 2>/dev/null || { echo "PTSGAP=NOINFO reason=R-absent($R)"; exit 3; }

# ── ① 现算（`--selftest` 也要走这一段：夹具的正极性值就是现算值）──────────────────
DFK=$(df -Pk "$TMPROOT" 2>/dev/null | awk 'NR==2{print $4}')
case "${DFK:-}" in
  ''|*[!0-9]*) echo "PTSGAP=NOINFO reason=disk-headroom-unreadable"; exit 3 ;;
  *) if [ "$DFK" -lt 524288 ]; then
       echo "PTSGAP=NOINFO reason=disk-headroom have_kb=$DFK need_kb=524288"; exit 3
     fi
     [ "$SELFTEST" -eq 1 ] || echo "DISK_HEADROOM=PASS avail_kb=$DFK" ;;
esac

RAW="$TMPD/raw.txt"; GAP="$TMPD/gap.txt"
python3 "$N/tools/check-shim-coverage.py" --tier all >"$RAW" 2>&1 \
  || { echo "PTSGAP=NOINFO reason=tool-rc"; exit 3; }
awk '$1=="PresentationNative_cor3.dll"{print $2}' "$RAW" | LC_ALL=C sort >"$GAP"
TOOL=$(wc -l < "$GAP" | tr -d ' ')
[ "${TOOL:-0}" -gt 0 ] || { echo "PTSGAP=NOINFO reason=empty-gap"; exit 3; }

DEAD=$(python3 - "$R/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs" "$GAP" <<'PYX'
import re, sys
L = open(sys.argv[1], encoding='utf-8', errors='replace').read().split('\n')
gap = set(l.strip() for l in open(sys.argv[2], encoding='utf-8') if l.strip())
inb, names = False, set()
for l in L:
    if re.search(r'#if\s+NEVER', l): inb = True; continue
    if inb and re.search(r'#endif', l): inb = False; continue
    if inb:
        for m in re.finditer(r'\b([A-Za-z_][A-Za-z0-9_]*)\s*\(', l): names.add(m.group(1))
print(len(names & gap))
PYX
) || { echo "PTSGAP=NOINFO reason=dead-extract-rc"; exit 3; }
case "${DEAD:-}" in ''|*[!0-9]*) echo "PTSGAP=NOINFO reason=dead-unreadable"; exit 3 ;; esac

# `artifact`：`*Wrapper` 尾名 ∧ EntryPoint 逐字已在 exports.txt。⚠️ 空集合 ⇒ NOINFO（不当 0 用）
WRP="$TMPD/wrapper.txt"
grep -E 'Wrapper$' "$GAP" >"$WRP" || true
WRP_N=$(wc -l < "$WRP" | tr -d ' ')
[ "${WRP_N:-0}" -gt 0 ] || { echo "PTSGAP=NOINFO reason=wrapper-set-empty"; exit 3; }
ARTI=0
while IFS= read -r n; do
  [ -n "$n" ] || continue
  grep -qxF "$n" "$N/bin/exports.txt" && ARTI=$((ARTI+1))
done <"$WRP"

STUB=$(grep -cE '^[[:space:]]*return wpf_pts_gap\("' "$N/src/win32_pts.c")
case "${STUB:-}" in ''|*[!0-9]*) echo "PTSGAP=NOINFO reason=stubs-unreadable"; exit 3 ;; esac
OPS=$((TOOL-DEAD-ARTI)); IMPL=$((OPS+STUB))
SO16=$(sha256sum "$N/bin/libwpfwin32.so" 2>/dev/null | cut -c1-16)
[ -n "$SO16" ] || { echo "PTSGAP=NOINFO reason=so-absent"; exit 3; }
EXPORTS=$(wc -l < "$N/bin/exports.txt" | tr -d ' ')
W66=$(sha256sum "$SITES/docs/WAVE66-PREREGISTRATION.md" 2>/dev/null | cut -c1-16)

LIVE="tool=$TOOL dead=$DEAD artifact=$ARTI ops=$OPS impl=$IMPL so16=$SO16 exports=$EXPORTS"
[ "$SELFTEST" -eq 1 ] || { echo "LIVE  $LIVE"; echo "W66PRE16 live=${W66:-未取到}"; }

# ══ ②③⑤ 自测（合成夹具，7 腿，5 腿断言必须红）════════════════════════════════════
selftest() {
  local fx="$TMPD/fx" npass=0 nfail=0
  mkdir -p "$fx/docs" "$fx/build/MilBridge" "$fx/samples/WpfFeatureProbe" \
           "$fx/src/WpfGfx.Linux.Native/src"
  {
    echo "工具口径 **$TOOL** − **11 条 NEVER** ⇒ **可操作 $OPS**（x）｜**实现口径 $IMPL**（y）"
    echo "**可操作缺口 $OPS 条／实现口径 $IMPL 条**"
    echo "- **可操作 $OPS 条／实现口径 $IMPL 条**"
  } >"$fx/docs/ROUTES.md"
  echo "工具口径 **$TOOL** ⇒ **可操作缺口 $OPS**（x）；**实现口径 $IMPL**（y）" \
      >"$fx/samples/WpfFeatureProbe/KNOWN-DEFECTS.md"
  echo "| ① | **可操作 $OPS／实现口径 $IMPL** |" >"$fx/README.md"
  echo "3. 未绿：**可操作 $OPS／实现口径 $IMPL**" >"$fx/build/MilBridge/HANDOFF-NEXT.md"
  echo "//   可操作 $OPS／实现口径 $IMPL 条 缺口就是它" \
      >"$fx/src/WpfGfx.Linux.Native/src/win32_classification.c"
  echo "工具报缺 **$TOOL**（其中死声明 11、误报 1 ⇒ **可操作 $OPS**）" >"$fx/docs/unimplemented.md"
  cp -a "$SITES/docs/WAVE66-PREREGISTRATION.md" "$fx/docs/" 2>/dev/null || true
  printf '# PTSGAP-DECL: tool=%s dead=%s artifact=%s ops=%s impl=%s so16=%s exports=%s w66pre16=%s\n' \
      "$TOOL" "$DEAD" "$ARTI" "$OPS" "$IMPL" "$SO16" "$EXPORTS" "${W66:-none}" >"$fx/decl.txt"

  leg() { # <腿名> <期望判词> <期望子串> <SITES> <DECL>
    local name="$1" want="$2" sub="$3" s="$4" d="$5" out v
    out=$(SITES="$s" DECL="$d" R="$R" PTSGAP_TMPROOT="$TMPD" bash "$SELF" --check 2>&1; echo "RC=$?")
    case "$out" in *"PTSGAP=PASS"*) v=PASS ;; *"PTSGAP=FAIL"*) v=FAIL ;;
                    *"PTSGAP=NOINFO"*) v=NOINFO ;; *) v=OTHER ;; esac
    if [ "$v" = "$want" ] && { [ -z "$sub" ] || grep -qF -- "$sub" <<< "$out"; }; then
      echo "  ${name} ⇒ ${v}  ok"; npass=$((npass+1))
    else
      echo "  ${name} ⇒ ${v}  **FAIL(期望 ${want}${sub:+ ∧ 含『${sub}』})**"; nfail=$((nfail+1))
    fi
  }

  leg "L1 正极性（复述位==现算 ∧ 声明自洽）" PASS "" "$fx" "$fx/decl.txt"

  local b="$TMPD/fx2"; rm -rf "$b"; cp -a "$fx" "$b"
  sed -i "s/可操作缺口 $OPS 条／实现口径/可操作缺口 $((OPS+1)) 条／实现口径/" "$b/docs/ROUTES.md"
  leg "L2 正文 ops +1（必须红）" FAIL "SITE-DRIFT docs/ROUTES.md" "$b" "$fx/decl.txt"

  sed 's/ops=[0-9]*/ops=9999/' "$fx/decl.txt" >"$TMPD/decl-liar.txt"
  leg "L3 声明 ops 造假（必须红）" FAIL "DRIFT ops" "$fx" "$TMPD/decl-liar.txt"

  local c="$TMPD/fx4"; rm -rf "$c"; cp -a "$fx" "$c"; rm -f "$c/README.md"
  leg "L4 复述位整件缺席（必须红）" FAIL "SITE-ABSENT README.md" "$c" "$fx/decl.txt"

  local d="$TMPD/fx5"; rm -rf "$d"; cp -a "$fx" "$d"; echo "可操作 88 实现口径 97" >"$d/README.md"
  leg "L5 形态漂移抽不到（必须红）" FAIL "SITE-NOHIT README.md" "$d" "$fx/decl.txt"

  leg "L6 声明件缺席（必须 NOINFO）" NOINFO "reason=decl-absent" "$fx" "$TMPD/absent-decl.txt"

  sed 's/so16=[0-9a-f]*/so16=0000000000000000/' "$fx/decl.txt" >"$TMPD/decl-so.txt"
  leg "L7 内容锚 so16 造假（必须红）" FAIL "DRIFT so16" "$fx" "$TMPD/decl-so.txt"

  printf 'PTSGAP_SELFTEST=%s pass=%d fail=%d legs=7 must_red=5\n' \
      "$([ "$nfail" -eq 0 ] && echo PASS || echo FAIL)" "$npass" "$nfail"
  [ "$nfail" -eq 0 ] || return 1
  return 0
}
if [ "$SELFTEST" -eq 1 ]; then selftest; exit $?; fi

# ── ② 对账声明行（逐字段相等，零余量）─────────────────────────────────────────────
[ -s "$DECL" ] || { echo "PTSGAP=NOINFO reason=decl-absent($DECL)"; exit 3; }
D=$(sed -n 's/^# PTSGAP-DECL: //p' "$DECL" | head -1)
[ -n "$D" ] || { echo "PTSGAP=NOINFO reason=decl-line-absent"; exit 3; }
for k in tool dead artifact ops impl so16 exports w66pre16; do
  dv=$(printf '%s\n' "$D" | tr ' ' '\n' | sed -n "s/^$k=//p")
  case "$k" in
    w66pre16) lv="${W66:-}" ;;
    *)        lv=$(printf '%s\n' "$LIVE" | tr ' ' '\n' | sed -n "s/^$k=//p") ;;
  esac
  if [ -z "$dv" ];    then echo "  FIELD-MISSING decl:$k"; rc=1
  elif [ -z "$lv" ];  then echo "  FIELD-UNREADABLE live:$k"; rc=1
  elif [ "$dv" != "$lv" ]; then echo "  DRIFT $k decl=$dv live=$lv"; rc=1; fi
done

# ── ③ 正文复述位（内容锚抽取；命中数 ==0 ⇒ 响亮失败）────────────────────────────
# `one <相对路径> <含数的上下文 ERE> <标签> <期望值>`：该式在**该件里的每一次命中**都必须等于期望值。
one() {
  local p="$SITES/$1" re="$2" lab="$3" want="$4" vf="$TMPD/v.$$" nh v
  if [ ! -s "$p" ]; then echo "  SITE-ABSENT $1"; rc=1; return; fi
  grep -oE "$re" "$p" 2>/dev/null | grep -oE '[0-9]+' >"$vf" 2>/dev/null || true
  nh=$(wc -l < "$vf" | tr -d ' ')
  if [ "${nh:-0}" -eq 0 ]; then
    echo "  SITE-NOHIT $1 $lab (响亮失败：形态漂移或该处未落新数)"; rc=1; rm -f "$vf"; return
  fi
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    [ "$v" = "$want" ] || { echo "  SITE-DRIFT $1 $lab want=$want got=$v"; rc=1; }
  done <"$vf"
  rm -f "$vf"
}
# `ROUTES.md` 三种写法（`:277` 口径段 / `:223` / `:357`）—— ⚠️ `:277` 是 W174A 草案的**漏网位**，
#   它同时带着**工具口径**与两个数，本件显式补上（否则「口径段」改了数也无人看着）。
one docs/ROUTES.md              '工具口径 \*\*[0-9]+\*\*'            tool "$TOOL"
one docs/ROUTES.md              '\*\*可操作 [0-9]+\*\*（'            ops  "$OPS"
one docs/ROUTES.md              '｜\*\*实现口径 [0-9]+\*\*'           impl "$IMPL"
one docs/ROUTES.md              '可操作缺口 [0-9]+ 条'                ops  "$OPS"
one docs/ROUTES.md              '实现口径 [0-9]+ 条'                  impl "$IMPL"
one docs/ROUTES.md              '\*\*可操作 [0-9]+ 条'                ops  "$OPS"
one samples/WpfFeatureProbe/KNOWN-DEFECTS.md '工具口径 \*\*[0-9]+\*\*'     tool "$TOOL"
one samples/WpfFeatureProbe/KNOWN-DEFECTS.md '\*\*可操作缺口 [0-9]+\*\*'   ops  "$OPS"
one samples/WpfFeatureProbe/KNOWN-DEFECTS.md '；\*\*实现口径 [0-9]+\*\*'   impl "$IMPL"
one README.md                   '\*\*可操作 [0-9]+／'                ops  "$OPS"
one README.md                   '／实现口径 [0-9]+\*\*'               impl "$IMPL"
one build/MilBridge/HANDOFF-NEXT.md '\*\*可操作 [0-9]+／'             ops  "$OPS"
one build/MilBridge/HANDOFF-NEXT.md '／实现口径 [0-9]+\*\*'            impl "$IMPL"
one src/WpfGfx.Linux.Native/src/win32_classification.c '可操作 [0-9]+／'      ops  "$OPS"
one src/WpfGfx.Linux.Native/src/win32_classification.c '／实现口径 [0-9]+ 条' impl "$IMPL"
one docs/unimplemented.md       '工具报缺 \*\*[0-9]+\*\*'             tool "$TOOL"
one docs/unimplemented.md       '⇒ \*\*可操作 [0-9]+\*\*'             ops  "$OPS"

# ── ③b `D-G141` 族：复述位里写进去的命令必须真能跑 ────────────────────────────────
LINES="$TMPD/cited-lines.txt"; : >"$LINES"
for rel in docs/ROUTES.md docs/unimplemented.md samples/WpfFeatureProbe/KNOWN-DEFECTS.md \
           README.md build/MilBridge/HANDOFF-NEXT.md \
           src/WpfGfx.Linux.Native/src/win32_classification.c; do
  [ -s "$SITES/$rel" ] && grep -nE '可操作|实现口径' "$SITES/$rel" >>"$LINES" 2>/dev/null
done
CIT_N=0; CITED=NOINFO
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  CIT_N=$((CIT_N+1))
  if [ -f "$SITES/$ref" ]; then
    CITED=PASS
  else
    echo "  CITED-MISSING ref=$ref （证据里写的命令在树里不存在）"
    CITED=FAIL
    [ "$CITED_STRICT" = 1 ] && rc=1
  fi
done < <(grep -ohE 'bash [A-Za-z0-9_./-]+\.sh' "$LINES" 2>/dev/null | awk '{print $2}' | LC_ALL=C sort -u)
echo "PTSGAP_CITED=$CITED refs=$CIT_N strict=$CITED_STRICT"
[ "$CITED" = NOINFO ] && echo "  ⚠️ 复述位里一条 bash 命令引用都没抽到 ⇒ 辅助轨不可判（**这不是绿**）"

# ── ④ 判词 ────────────────────────────────────────────────────────────────────────
if [ "$rc" -eq 0 ]; then echo "PTSGAP=PASS $LIVE"; else echo "PTSGAP=FAIL $LIVE"; fi
exit "$rc"
