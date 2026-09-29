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
# 【两极化（`--selftest`，**9 腿**，其中 **6 腿**断言「必须红」；`t63`/W7 加 L8/L9 两条前沿腿）】合成夹具，不需要 `$R` 的真正文：
#   ⏪ `t106`（2026-09-29）**扫描形状收窄（与裁定九一致）**：复述位扫描改为**逐行分类** ——
#     **自引旧代工件**的行（行内 `libwpfwin32.so <16hex>` ≠ 现盘 `so16`，或 `<N> 导出` ≠ 现盘 `exports`）
#     ＝ **历史行**，其数字**不参与现值判定**（在场不红，只印 `PTSGAP_HISTORICAL=n=…`）；
#     其余命中行**逐处**参与（写错 ⇒ 必红 `SITE-DRIFT`）；**每字段**若只剩历史行 ⇒
#     `SITE-HISTORICAL-ONLY` ＋ `PTSGAP=NOINFO reason=current-site-absent`（`rc=3`，**绝不当绿**）。
#     ⇒ 两极化腿增至 **12 腿**（H1 历史行在场不得假红／H2 现值位写错必红／H3 只剩历史行 ⇒ NOINFO）。
#     ⚠️ **判定的域＝全树逐字段**：某**件**某字段只剩历史行只是**告示**（`SITE-HISTORICAL-ONLY`）；
#     只有当某字段**在全树**都没有现值位时 ⇒ `PTSGAP=NOINFO reason=current-site-absent fields=…`（`rc=3`）。
#     理由（现取）：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `ops`／`impl` 两字段现值位本就不在该件（现值由
#     `pts-gap-decl.txt` 侧同步），若按"每件每字段"判，真树会**永久 NOINFO** ⇒ 那样牙同样没有牙。
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
# 【`t63`／W7 新增的三条口径（**写死，防后人改读法**）】
#   ① **进度 ＝ 具名前沿跳数**，**不是缺口条数** —— `impl = ops + stubs` 是**缺口计数**
#      ⇒ **真进步让它下降**（本增量实测 `95 → 94`：能力前进一格，数却变小）⇒ 计数口径在本增量上**读反了**。
#   ② 门禁步 `PTS-PAGES` **只读** `leg_*.env` 的列（`alive`／`app_rc`／`magenta`／`colors`），
#      **不读 `entry=`** ⇒ **它的绿对「前沿位移」零证据力**（不许拿 `PTS-PAGES=PASS` 当进度证据）。
#   ③ 前沿读数的**唯一载体** = `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 里的**具名**
#      `entry=<名>` 行 ＋ `PTS_GAP entry=<名>` 台账行（应用侧自报）；「下一站**无名**」（应用只记
#      `entry=unknown`）**不算具名进度** ⇒ 印 `PTSGAP_FRONTIER_STATE=UNNAMED`（响亮、不翻 rc，但**绝不是绿**）。
# 【成本】纯读、零 `dotnet`、不写 `$R`；现测 < 3 s。
# 【卫生】临时件一律 `mktemp -d` ＋ `trap … EXIT` 自清；**不用**共享 `/tmp`
#   （根默认 `$HOME/.cache/wpf-linux/tmp`，可用 `PTSGAP_TMPROOT` 覆盖）。
# ══════════════════════════════════════════════════════════════════════════════════
set -uo pipefail

R=${R:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)}   # 波 `#77` 旧路径重指向：由仓根现推
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

# 波 `#77`（`t4` 现场要求）：读数行**带 `root=`** —— 自证这一次打在**哪个树**上
#   （旧版硬编码旧树路径 ⇒ 从 `$N` 跑时读的是**旧树**，而旧树一回收就 `NOINFO reason=R-absent`）。
LIVE="tool=$TOOL dead=$DEAD artifact=$ARTI ops=$OPS impl=$IMPL so16=$SO16 exports=$EXPORTS root=$R"
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

  leg() { # <腿名> <期望判词> <期望子串> <SITES> <DECL> [额外 env…]
    local name="$1" want="$2" sub="$3" s="$4" d="$5"; shift 5
    local out v
    out=$(env "$@" SITES="$s" DECL="$d" R="$R" PTSGAP_TMPROOT="$TMPD" bash "$SELF" --check 2>&1; echo "RC=$?")
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

  # ── `t63`／W7 新增两腿（前沿）：L8 假进度**必红**｜L9 前沿**真位移** ⇒ **不得假红** ──────
  #  夹具载体：一份只含 `entry=LoCreateContext`（未位移）／另一份含 `entry=CreateDocContext`（已位移）
  printf 'TAB entry=LoCreateContext\n' >"$TMPD/fr-notmoved.log"
  printf 'TAB entry=CreateDocContext\n' >"$TMPD/fr-moved.log"
  leg "L8 计数下降而前沿未动（假进度**必须红**）" FAIL "FAKE-PROGRESS" "$fx" "$fx/decl.txt" \
      PTSGAP_FRONTIER_CARRIER="$TMPD/fr-notmoved.log" PTSGAP_FR_BASELINE_IMPL="$((IMPL+1))"
  leg "L9 计数下降且前沿真位移（**不得假红**）" PASS "" "$fx" "$fx/decl.txt" \
      PTSGAP_FRONTIER_CARRIER="$TMPD/fr-moved.log" PTSGAP_FR_BASELINE_IMPL="$((IMPL+1))"

  # ── `t106` 新增三腿（扫描形状收窄）：H1 历史行在场**不得假红**｜H2 现值位写错**必红并点名**｜
  #    H3 某字段**只剩历史行** ⇒ `NOINFO reason=current-site-absent`（响亮、不当绿）
  local h="$TMPD/fx6"; rm -rf "$h"; cp -a "$fx" "$h"
  {
    local soexpair2="libwpfwin32.so 0000000000000000"
    printf -- '- **🆕 在册数更正（2026-09-24 车道 W154A-PTS 只读盘点，主控落册）**：工具口径 **%s**（件 %s／%s 导出）… ⇒ **可操作缺口 %s**；**实现口径 %s**\n' \
      "$((TOOL+1))" "$soexpair2" "$((EXPORTS+2))" "$((OPS+1))" "$((IMPL+1))"
    printf -- '- 现值出处（现盘）：工具口径 **%s** ⇒ **可操作缺口 %s**；**实现口径 %s**\n' "$TOOL" "$OPS" "$IMPL"
  } >>"$h/samples/WpfFeatureProbe/KNOWN-DEFECTS.md"
  leg "H1 历史行在场（自引旧代 ⇒ 不参与）**不得假红**" PASS "" "$h" "$fx/decl.txt"

  local h2="$TMPD/fx7"; rm -rf "$h2"; cp -a "$h" "$h2"
  sed -i "s/现值出处（现盘）：工具口径 \*\*$TOOL\*\*/现值出处（现盘）：工具口径 **$((TOOL+1))**/" \
      "$h2/samples/WpfFeatureProbe/KNOWN-DEFECTS.md"
  leg "H2 现值位写错（**必须红并点名**）" FAIL "SITE-DRIFT samples/WpfFeatureProbe/KNOWN-DEFECTS.md tool" "$h2" "$fx/decl.txt"

  local h3="$TMPD/fx8"; rm -rf "$h3"
  mkdir -p "$h3/docs" "$h3/build/MilBridge" "$h3/samples/WpfFeatureProbe" "$h3/src/WpfGfx.Linux.Native/src"
  # ⚠️ 反引号一律**不写进双引号**（`DQ-BACKTICK` 族；`t48`/`t60`/`t106` 都栽过）⇒ 用具名变量拼装
  local sotic='libwpfwin32.so'
  local soold='0000000000000000'
  local soexpair="$sotic $soold"
  printf -- '- 历史：工具口径 **%s** − **可操作 %s**（短）｜**实现口径 %s**（件 %s／%s 导出）；可操作缺口 %s 条／实现口径 %s 条／**可操作 %s 条\n' \
      "$((TOOL+1))" "$((OPS+1))" "$((IMPL+1))" "$soexpair" "$((EXPORTS+2))" "$((OPS+1))" "$((IMPL+1))" "$((OPS+1))" >"$h3/docs/ROUTES.md"
  printf -- '- 历史：工具口径 **%s** ⇒ **可操作缺口 %s**；**实现口径 %s**（件 %s／%s 导出）\n' \
      "$((TOOL+1))" "$((OPS+1))" "$((IMPL+1))" "$soexpair" "$((EXPORTS+2))" >"$h3/samples/WpfFeatureProbe/KNOWN-DEFECTS.md"
  printf -- '- 历史：**可操作 %s／实现口径 %s**（件 %s／%s 导出）\n' "$((OPS+1))" "$((IMPL+1))" "$soexpair" "$((EXPORTS+2))" >"$h3/README.md"
  printf -- '- 历史：**可操作 %s／实现口径 %s**（件 %s／%s 导出）\n' "$((OPS+1))" "$((IMPL+1))" "$soexpair" "$((EXPORTS+2))" >"$h3/build/MilBridge/HANDOFF-NEXT.md"
  printf -- '//   历史：可操作 %s／实现口径 %s 条（件 %s／%s 导出）\n' "$((OPS+1))" "$((IMPL+1))" "$soexpair" "$((EXPORTS+2))" >"$h3/src/WpfGfx.Linux.Native/src/win32_classification.c"
  printf -- '- 历史：工具报缺 **%s** ⇒ **可操作 %s**（件 %s／%s 导出）\n' "$((TOOL+1))" "$((OPS+1))" "$soexpair" "$((EXPORTS+2))" >"$h3/docs/unimplemented.md"
  cp -a "$SITES/docs/WAVE66-PREREGISTRATION.md" "$h3/docs/" 2>/dev/null || true   # W66 锚取自 $SITES ⇒ 夹具须同备，否则 live 不可读 ⇒ 假红
  leg "H3 某字段只剩历史行（必须 NOINFO、**绝不当绿**）" NOINFO "reason=current-site-absent" "$h3" "$fx/decl.txt"

  # ── ⏪ `t137` 新增三腿（锚族按形状扩 ＋ dated 必要件的两极化）：
  #    H4 **正极**：dated ＋ 裸件名锚（`win32shim <16hex>` ≠ 现盘）＋ `exports=<N>`（≠ 现盘）⇒ 历史行 ⇒ **不红**；
  #    H5 **反极（伪装）**：**现值行**（无 dated 措辞）但**人为加**同形状裸件名锚 ⇒ **必须仍然红**；
  #    H6 **反极（现值位写错）**：现值位 `impl` 改成 `999` ⇒ **必红并点名** `SITE-DRIFT … impl want=… got=999`。
  local h4="$TMPD/fx9"; rm -rf "$h4"; cp -a "$fx" "$h4"
  {
    local sobare='win32shim'
    local soold16='0000000000000000'
    printf -- '- 🆕 **在册数已现算（主控 2026-09-26，只读车道 W174A）** ｜**实现口径 %s**（锚 %s %s／exports=%s）；**可操作缺口 %s 条**\n' \
      "$((IMPL+1))" "$sobare" "$soold16" "$((EXPORTS+2))" "$((OPS+1))"
  } >>"$h4/docs/ROUTES.md"
  leg "H4 自引旧代 dated 锚行（裸件名 ＋ exports=）**不得假红**" PASS "" "$h4" "$fx/decl.txt"

  local h5="$TMPD/fx10"; rm -rf "$h5"; cp -a "$fx" "$h5"
  {
    local sobare5='win32shim'
    local soold5='0000000000000000'
    printf -- '- 现值出处（现盘）｜**实现口径 %s**（只加假锚：件 %s %s）；**可操作缺口 %s 条**\n' \
      "$((IMPL+1))" "$sobare5" "$soold5" "$OPS"
  } >>"$h5/docs/ROUTES.md"
  leg "H5 现值行只加假锚（**无 dated 措辞**）⇒ 仍必红" FAIL "SITE-DRIFT docs/ROUTES.md impl" "$h5" "$fx/decl.txt"

  local h6="$TMPD/fx11"; rm -rf "$h6"; cp -a "$fx" "$h6"
  sed -i "s/｜\*\*实现口径 $IMPL\*\*／｜\*\*实现口径 999**／" "$h6/docs/ROUTES.md" 2>/dev/null || true
  sed -i "s/\*\*实现口径 $IMPL\*\*/**实现口径 999**/g" "$h6/docs/ROUTES.md"
  leg "H6 现值位 impl 写错 999（**必红并点名 want/got**）" FAIL "SITE-DRIFT docs/ROUTES.md impl want=$IMPL got=999" "$h6" "$fx/decl.txt"

  printf 'PTSGAP_SELFTEST=%s pass=%d fail=%d legs=15 must_red=9\n' \
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
# ⏪ `t106`（2026-09-29，与 `build/MilBridge/P1-ptsname-result.md` §8 **裁定九**一致）
#   **扫描形状收窄：历史行不承担现值** —— 判据是**内容锚**（不看行号、不看文件）：
#   一条**命中行**被判「**历史行**」⇔ 它**自引了一个与现盘不同的工件世代**，即满足其一：
#     ① 行内出现 `libwpfwin32.so <16hex>`（或裸 `.so <16hex>`）且该 16hex ≠ 现盘 `so16`；
#     ② 行内出现 `<N> 导出` 且 `N` ≠ 现盘 `exports`。
#   ⇒ 这类行**只描述它引用的那一代**（裁定九），其数字**不参与现值判定**（**在场不红**）；
#   **其余命中行一律参与**（现值出处写错 ⇒ **必红并点名** `SITE-DRIFT <件> <字段> want=… got=…`）。
#   ⚠️ **没有**放宽到"整件不扫"：本件对**每一处命中**逐处分类（同一件可同时有历史行与现值行）；
  #   ⏪ **`t137` dated 追加（锚族按具体形状扩 ＋ 加 dated 必要件；t106 原句一字未删）**：
  #     · **锚族（四条形状，全部"具体形状"、不用任意 16 hex）**：① `.<so> <16hex>`（t106）｜② `<N> 导出`（t106）｜
  #       **③ 裸件名 ＋ 16 hex**（白名单 `HIST_ARTIFACT_RE`：`win32shim`／`libwpfwin32`／`wpfgfx_cor3`／
  #       `PresentationCore`／`PresentationFramework`／`WindowsBase`）｜**④ `exports=<N>`**。
  #     · **新增必要条件：行内须带「dated 措辞」**（`HIST_DATED_RE`：`读时`／`dated`／`⏪`／`历史`／`YYYY-MM-DD`）
  #       —— 锚形状 **且** dated 措辞**同时**成立才判历史行（**堵"只加锚即免红"的伪装口子**）。
  #     · 两条理由：① 真因现取 —— `docs/ROUTES.md` 那条「在册数已现算（主控 2026-09-26 …）」自带
  #       `win32shim fc60c34d51fd9247`／`exports=550` 却**不在旧锚族**里 ⇒ 被误当现值位（假红）；
  #       ② `:247` 那类行（含"实现口径 87 条"）**也不是**现值位，须由自引旧代锚 ＋ dated 措辞共同界定。
  #     · **残留口子（如实记）**：锚 ＋ 日期戳同时伪造仍可免红（本件只堵"只加锚"这一路）。
  #   ⚠️ **没有**放宽到"整件不扫"：本件对**每一处命中**逐处分类（同一件可同时有历史行与现值行）；
#   且**每个字段都必须至少有一处现值位**，否则 ⇒ `SITE-HISTORICAL-ONLY …` ＋
#   `PTSGAP=NOINFO reason=current-site-absent`（**响亮、`rc=3`、绝不当绿**）。
#   ⚠️ 也不采用"只扫第一处"这类脆弱口径（那会让"第二处写错"漏网）。
CUR_SITE_MISSING=0
HIST_TOTAL=0
HISTONLY=""          # 出现过"只剩历史行"的**字段标签**集合（空格分隔）
CURSEEN=""           # 出现过现值位的**字段标签**集合（空格分隔）
lab_add() { case " ${!1} " in *" $2 "*) ;; *) eval "$1=\"${!1} $2\"" ;; esac; }   # `${!1}`＝按名取现值（去重靠它）

# 该行是否"自引旧代工件"（⇒ 历史行）：$1 ＝ 行文本
# ⏪ `t137`（**锚族按具体形状扩到"自引旧代锚行"**；真因现取：`docs/ROUTES.md` 里那条
#   「🆕 在册数已现算（主控 2026-09-26，只读车道 W174A）… ⇒ **实现口径 87** ＝ 88 ＋ …（锚 `win32shim
#   fc60c34d51fd9247`／`exports=550`）」是**自引旧代的 dated 陈述**，却因**裸件名锚**不在旧锚族里而被判现值位）。
#   **白名单＝本族实测出现过的写法**（**不用**"命中任意 16 hex 即历史行"那种**过宽**规则 —— 它会过分类）：
#   `win32shim`｜`libwpfwin32`（含 `.so` 写法由旧锚 ① 覆盖）｜`wpfgfx_cor3`｜`PresentationCore`｜
#   `PresentationFramework`｜`WindowsBase`；锚形 ＝ 件名 ＋ **≤3 个非 16 进制字符** ＋ 16 hex。
#    ⚠️ 间隔参数**按实测**取 `{0,5}`：`so16` 键在 `docs/ROUTES.md` 的记法是 「`so16` **`<16hex>`」
#      ⇒ 键与 hex 之间**恰 5 个非 hex 字符**（反引号／空格／两个星号／反引号）⇒ 取 5 才盖得住；
#      **仍**不是「命中任意 16 hex」（前缀必须是白名单件名／`so16` 键，且后随 ≤5 非 hex 字符）。
HIST_ARTIFACT_RE='(win32shim|libwpfwin32|wpfgfx_cor3|PresentationCore|PresentationFramework|WindowsBase|so16)[^0-9a-f]{0,5}[0-9a-f]{16}'
#    ⏪ `t137` 追加一枚：**`so16` 键 ＋ 16 hex**（真因现取：`docs/ROUTES.md` 那条 `⏪ dated 结论 · W7` 行里写的是
#      `so16 **6825dd7071387a46 → 2a5165700a8c8579**` —— 它是**自引旧代的锚**（≠ 现盘 `so16`），但键名不带 `.so`
#      ⇒ 旧锚族与裸件名白名单都盖不住 ⇒ 与本件同族、按**具体形状**一并纳入）。

# ⏪ `t137`：**dated 措辞**（＝"这是一句自引旧代的陈述"的第二个必要件）——
#   只有它**与**锚形状**同时**成立才判历史行；否则任何人都能给现值行加个假锚来免红（**伪装口子**）。
#   本族逐条（并给理由）：① `读时`（`t14` 起在册的 dated 措辞）；② `dated`（英文同义）；
#   ③ `⏪`（本波 dated 追加的通用记号）；④ `历史`（`t106` 自测夹具与本族文书的既有写法）；
#   ⑤ **裸日期戳** `YYYY-MM-DD`（现值行的写法是"现值出处（现盘）"，不带日期戳）。
#   ⚠️ **残留口子（如实记）**：同时伪造"锚 ＋ 日期戳/历史字样"仍可免红 —— 本件只堵"只加锚"这一路。
#   ⑥ `世代`（现取动因：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `t134` dated 块自述句「**口径世代仍为**
#      `libwpfwin32.so fc60c34d51fd9247`／`550 导出`」—— 它**明写**自己所引的是哪一代 ⇒ 属自引旧代陈述；
#      这一枚是本件**唯一**为覆盖既有真历史行而加的措辞，逐条留证）。
HIST_DATED_RE='读时|dated|⏪|历史|[12][0-9]{3}-[0-9]{2}-[0-9]{2}|世代'

line_is_hist() {
  local L="$1" h e hb eb
  # ⚠️ 本行的 ERE **故意不含反引号**（双引号内的反引号会被 shell 当命令替换 ⇒ `D-G186` 同族坑）
  # ⏪ `t137`：**必要条件之一：dated 措辞**（先判，成本最低且在"伪装"测试里最先挡住）
  printf '%s' "$L" | grep -qE "$HIST_DATED_RE" 2>/dev/null || return 1
  # ① `.<so> <16hex>`（既有，未动）
  h=$(printf '%s' "$L" | LC_ALL=C grep -oE '[.]so[^0-9a-f]{0,3}[0-9a-f]{16}' 2>/dev/null | grep -oE '[0-9a-f]{16}' | head -1)
  if [ -n "$h" ] && [ "$h" != "$SO16" ]; then return 0; fi
  # ② `<N> 导出`（既有，未动）
  e=$(printf '%s' "$L" | grep -oE '[0-9]+ 导出' 2>/dev/null | grep -oE '[0-9]+' | head -1)
  if [ -n "$e" ] && [ "$e" != "$EXPORTS" ]; then return 0; fi
  # ③ ⏪ `t137` 新增：**裸件名 ＋ 16 hex**（白名单见上）
  hb=$(printf '%s' "$L" | LC_ALL=C grep -oE "$HIST_ARTIFACT_RE" 2>/dev/null | grep -oE '[0-9a-f]{16}' | head -1)
  if [ -n "$hb" ] && [ "$hb" != "$SO16" ]; then return 0; fi
  # ④ ⏪ `t137` 新增：`exports=<N>`
  eb=$(printf '%s' "$L" | grep -oE 'exports=[0-9]+' 2>/dev/null | grep -oE '[0-9]+' | head -1)
  if [ -n "$eb" ] && [ "$eb" != "$EXPORTS" ]; then return 0; fi
  return 1
}

# 现值位扫描（`t106` 起）：逐**行**分类 —— 历史行计票不判定；现值行**逐处**判定
one() {
  local p="$SITES/$1" re="$2" lab="$3" want="$4" vf="$TMPD/v.$$" nh v line vals ncur nhist
  if [ ! -s "$p" ]; then echo "  SITE-ABSENT $1"; rc=1; return; fi
  : >"$vf"; ncur=0; nhist=0
  # ⚠️ 只喂**命中行**（`grep -E` 一次过件）—— 逐行 grep 全件会把本牙从 <3 s 拖到 >50 s（`t106` 实测）
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    vals=$(printf '%s\n' "$line" | grep -oE "$re" 2>/dev/null | grep -oE '[0-9]+' 2>/dev/null || true)
    [ -n "$vals" ] || continue
    if line_is_hist "$line"; then
      nhist=$((nhist + $(printf '%s\n' "$vals" | grep -c .)))
      continue
    fi
    printf '%s\n' "$vals" >>"$vf"
    ncur=$((ncur + $(printf '%s\n' "$vals" | grep -c .)))
  done < <(grep -E "$re" "$p" 2>/dev/null || true)
  if [ "${ncur:-0}" -eq 0 ]; then
    if [ "${nhist:-0}" -gt 0 ]; then
      # ⏪ `t106`：**本件**该字段只剩历史行 ⇒ 只是**告示**（现值位可在别件）；是否 NOINFO 由**全树逐字段**在判词处裁定
      echo "  SITE-HISTORICAL-ONLY $1 $lab hist=$nhist（本件该字段只剩**自引旧代工件**的历史行 ⇒ 现值位当在别件；全树口径见 PTSGAP=NOINFO reason=current-site-absent）"
      lab_add HISTONLY "$lab"
    else
      echo "  SITE-NOHIT $1 $lab (响亮失败：形态漂移或该处未落新数)"; rc=1
    fi
    rm -f "$vf"; return
  fi
  HIST_TOTAL=$((HIST_TOTAL + nhist))
  lab_add CURSEEN "$lab"
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

# ⏪ `t106`：历史行的**可见性**（不参与判定，但**不许静默**）——只作信息行，不改 `rc`
[ "${HIST_TOTAL:-0}" -gt 0 ] && echo "PTSGAP_HISTORICAL=n=$HIST_TOTAL（自引旧代工件的**历史行**命中数：**不参与现值判定**，见裁定九）"

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

# ── ③c 前沿成对 ＋ 假进度判红（`t63`／W7 新增；口径见件头 ①②③）────────────────────
FR_CARRIER="${PTSGAP_FRONTIER_CARRIER:-$R/build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log}"
FR_BEFORE_NAME="${PTSGAP_FR_BEFORE_NAME:-LoCreateContext}"     # 本增量**之前**的具名前沿（声明值）
FR_BEFORE_N="${PTSGAP_FR_BEFORE_N:-3}"                         # 其台账行计数（声明值）
FR_BASELINE_IMPL="${PTSGAP_FR_BASELINE_IMPL:-95}"              # 本增量**之前**的 impl（假进度判据的基线）
if [ -s "$FR_CARRIER" ]; then
  FR_NOW="$(grep -ao 'entry=[A-Za-z0-9_]*' "$FR_CARRIER" 2>/dev/null | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
  FR_NOW_N="$(grep -ac "entry=${FR_NOW#entry=}" "$FR_CARRIER" 2>/dev/null || true)"; FR_NOW_N="${FR_NOW_N:-0}"
  FR_SHA="$(sha256sum "$FR_CARRIER" 2>/dev/null | cut -c1-16)"
  FR_MT="$(stat -c '%y' "$FR_CARRIER" 2>/dev/null)"
  echo "PTSGAP_FRONTIER before=${FR_BEFORE_NAME}@${FR_BEFORE_N} after=${FR_NOW#entry=}@${FR_NOW_N} carrier_sha16=$FR_SHA carrier_mtime=${FR_MT:-?} ts=$(date '+%F %T.%N %z')"
  case "${FR_NOW#entry=}" in
    ''|unknown)
      echo "PTSGAP_FRONTIER_STATE=UNNAMED（载体里**没有具名前沿**：应用侧只记 ${FR_NOW#entry=} ⇒ 本增量**不计具名进度**；**这不是绿**）" ;;
    *)
      echo "PTSGAP_FRONTIER_STATE=NAMED frontier=${FR_NOW#entry=}（具名前沿成立）" ;;
  esac
  # (B) **假进度必红**：计数下降（impl < 基线）∧ 前沿名**未动** ⇒ `#66` 的 `P03` 形态
  if [ "$IMPL" -lt "$FR_BASELINE_IMPL" ] && [ "${FR_NOW#entry=}" = "$FR_BEFORE_NAME" ]; then
    # ⏪ dated 口径对齐（`t89`，2026-09-29；**只在行尾追加 token、原句一字未改**）：
    #   判据件 `build/MilBridge/P1-w8-step1-criteria.md` 的 P5 行**逐字**要求报
    #   `FAIL reason=ledger-nonzero-frontier-unchanged`，同件「必红的判法（统一）」又写明
    #   「红而不点名（缺 `reason=`／缺 `file:` 或字段名）⇒ 该条判据判不成立」。
    #   原实现只给字段名（`impl=`／`基线`／`前沿仍是 <名>`）而**无 `reason=`** ⇒ 二选一里选**补 token**
    #   （判据件**不动**：它已由 `t81` 当契约用过；补的是**期望 token 本身**，不改判定实质）。
    #   位置选**行尾**：使原句成为新行的**逐字前缀**（`只增不改` 可机器证：`旧句 in 新行` 为真）。
    echo "  FAKE-PROGRESS impl=$IMPL < 基线 $FR_BASELINE_IMPL 而前沿仍是 ${FR_BEFORE_NAME} ⇒ **名字离开名单而能力为 0**（假进度） reason=ledger-nonzero-frontier-unchanged"
    rc=1
  fi
else
  echo "PTSGAP_FRONTIER=NOINFO reason=carrier-absent($FR_CARRIER)（载体不在 ⇒ 前沿不可判；**不许当绿**）"
fi

# ── ④ 判词 ────────────────────────────────────────────────────────────────────────
# ⏪ `t106`：**现值出处缺失**是一门**响亮**的 NOINFO（`rc=3`）——**绝不当绿**（也不当红：缺位不是矛盾）
_misslab=""
for _l in $HISTONLY; do case " $CURSEEN " in *" $_l "*) ;; *) _misslab="$_misslab $_l" ;; esac; done
if [ "$rc" -eq 0 ] && [ -n "$_misslab" ]; then
  echo "PTSGAP=NOINFO reason=current-site-absent fields=${_misslab# }（这些字段**全树**只剩历史行 ⇒ 现值出处缺失；**这不是绿**，见裁定九／t106）"
  exit 3
fi
if [ "$rc" -eq 0 ]; then echo "PTSGAP=PASS $LIVE"; else echo "PTSGAP=FAIL $LIVE"; fi
exit "$rc"
