#!/usr/bin/env bash
# ==============================================================================
# WPF-on-Linux · `Nl*`（连字/拼写）**有意降级声明** 的判据牙
#   —— `#66` 待落地件（`TASK-0720`）；**单文件自足**（不依赖任何同目录伴生件）
#
# 【⚖️ 口径句（**先写死，防后人再栽**）】
#   · **声明必须独占一行**；
#   · **同一行里只要出现否决词 —— 哪怕它出现在与本题无关的另一句里 —— 该行即判「提案」**。
#   （本仓已栽过一次：某行含 `必须` 用来描述**另一件事**，结果整行被判成提案 ⇒ "已声明"变成"没声明"。）
#
# 【它判什么】三态（`NOINFO` **不算绿**）：
#   段① **导出面**：6 个 `Nl*`（`NlCreateHyphenator`／`NlDestroyHyphenator`／`NlGetClassObject`／
#        `NlHyphenate`／`NlLoad`／`NlUnload`）在 `.so` 里**一个都不许有**。
#        今天为真（能力 = 0）；**若哪天有人导出/实现它们** ⇒ 本段**必红**（"有意降级"这句话不再成立，
#        必须重测行为并更新在册声明）。
#   段② **声明面**：登记面里必须有**合格声明行** —— **逐行**合取四组词、**排除报告面**。
#   段③ **行为锚（3 处，内容锚不是行号）**：(a) ctor 里 `NlCreateHyphenator` 的调用被
#        `catch (EntryPointNotFoundException)` 包住；(b) `AnalyzeText` 有
#        `_hyphenatorResource == IntPtr.Zero ⇒ return null` 守卫（含 `No hyphenator available`）；
#        (c) `TextParagraph` 有 `isHyphenationEnabled ⇒ _lineProperties.Hyphenator = StructuralCache.Hyphenator`。
#   段④ **UI 入口（`NOINFO` 格）**：仓外真 demo 里那条路是否开着；**仓外件不存在 ⇒ `NOINFO`**
#        （**不许**因缺件判红、也不许判绿）。
#
# 【词表出处】**逐字**取自 `build/MilBridge/tools/ime-landing-check.sh` 的 `:108-110`
#   （该件头部写死的坑：「要求登记 ≠ 已登记」，引用缺陷册自己那行会**假绿**）：
#     DECISION='有意降级|有意保留'
#     REG='已登记|已在册|在册裁定|已裁|裁定|✅'
#     VETO='必须|要求|建议|应当|需要登记|需在册|未落地|只登记|要登记|待登记'
#   本件的 TRIGGER 组按对象替换为：'Nl[A-Z]|连字|Hyphenation|NaturalLanguageHyphenator'。
#   判据 = **逐行**：TRIGGER ∧ DECISION ∧ REG ∧ **零 VETO**。
#
# 【登记面 vs 报告面】登记面 = `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ＋ `docs/**/*.md`
#   ＋ `build/MilBridge/tools/*.tsv`；**排除** `build/MilBridge/*.md`（报告只可见、不计数，
#   否则"自己写一份报告"就能转绿）。
#
# 【金丝雀（**每次真跑前都做**）】合成夹具四格，任一格不符 ⇒ `NOINFO reason=canary-blind`（**不是绿**）：
#   ① 合格声明 ⇒ `hits≥1`；② 提案行（含否决词）⇒ `hits==0` 且可见为 PROPOSAL；
#   ③ 命中词但**无裁定标记** ⇒ 可见为 SKIP；④ 放在**报告面路径**下的"合格声明" ⇒ **不进登记面名单**。
#
# 【两极化（`--selftest`，四极；**阳性对照当场编译**，不依赖仓外件）】
#   极 1 真 shim ⇒ 导出面 `CAPABILITY_ZERO`；
#   极 2 **现场 gcc 编出的假 `.so`**（导出 6 名 + `NlCreateHyphenator` 返回**非 NULL 假句柄**）
#        ⇒ 导出面 `RED_IMPLEMENTED`（**这就是"真实现之后"的阳性对照**）；
#   极 3 合成登记面放合格声明 ⇒ 段② PASS；极 4 放提案行 ⇒ 段② FAIL。
#   ⚠️ **gcc 缺失 ⇒ 极 2 判 `NOINFO`，整个 `--selftest` 报 `NOINFO`（绝不算 PASS）**。
#
# 用法：
#   nl-intent-check.sh [--root DIR] [--so PATH] [--hcxaml PATH]
#   nl-intent-check.sh --selftest
# 退出码：0 = PASS，1 = FAIL，2 = NOINFO
# 成本：单趟 ≈ 1 s、零 `dotnet`、零世代成本（不动九位/`known-red.json`/不动被测树）。
# ==============================================================================
set -u

# `$R` 的默认值：**先证明路径是对的**（本仓 `D-G119 ⑫` 同族：`[ -d ]` 不等于"这是仓库根"）
#   —— 判据 = 那个根下面**真的有** shim。猜错根 ⇒ 极 1 会静默变成"找不到 .so"。
if [ -z "${R:-}" ]; then
    for cand in "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." 2>/dev/null && pwd)"; do
        if [ -n "$cand" ] && [ -f "$cand/src/WpfGfx.Linux.Native/bin/libwpfwin32.so" ]; then
            R="$cand"; break
        fi
    done
fi
R="${R:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)}"   # 波 `#77` 旧路径重指向：由仓根现推
HERE="$(cd "$(dirname "$0")" && pwd)"
SO="$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
HC_XAML="${HC_XAML:-/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Styles/FlowDocumentDemo.xaml}"
NL_SRC_NAME="PresentationFramework/System/Windows/Documents/NaturalLanguageHyphenator.cs"
TP_SRC_NAME="PresentationFramework/MS/Internal/PtsHost/TextParagraph.cs"
NAMES="NlCreateHyphenator NlDestroyHyphenator NlGetClassObject NlHyphenate NlLoad NlUnload"
UP="$R/upstream/wpf/src/Microsoft.DotNet.Wpf/src"
NL_SRC="$UP/$NL_SRC_NAME"
TP_SRC="$UP/$TP_SRC_NAME"

selftest=0; ROOT_OVERRIDE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --selftest) selftest=1; shift ;;
        --root) ROOT_OVERRIDE="$2"; shift 2 ;;
        --so) SO="$2"; shift 2 ;;
        --hcxaml) HC_XAML="$2"; shift 2 ;;
        *) echo "unknown arg: $1"; exit 2 ;;
    esac
done

# ── 嵌入的声明检测器（登记面 / 逐行四组词 / 金丝雀）────────────────────────────
#   参数：$1 = root；$2 = 是否跑金丝雀（1/0）。
#   输出：stdout 只有一个词 `PASS|FAIL|NOINFO`；明细走 stderr。
decl_verdict() {
    python3 - "$1" "${2:-1}" <<'PY_DECL' 2>/dev/null
import glob, os, re, shutil, sys, tempfile

root, run_canary = sys.argv[1], sys.argv[2] == "1"
TRIGGER = r"Nl[A-Z]|连字|Hyphenation|NaturalLanguageHyphenator"
DECISION = r"有意降级|有意保留"
REG = r"已登记|已在册|在册裁定|已裁|裁定|✅"
VETO = r"必须|要求|建议|应当|需要登记|需在册|未落地|只登记|要登记|待登记"

def registry_files(root):
    out = []
    f = os.path.join(root, "samples", "WpfFeatureProbe", "KNOWN-DEFECTS.md")
    if os.path.exists(f):
        out.append(f)
    for pat in ("docs/**/*.md", "build/MilBridge/tools/*.tsv"):
        out += glob.glob(os.path.join(root, pat), recursive=True)
    return sorted(set(out))

def report_files(root):
    return sorted(glob.glob(os.path.join(root, "build", "MilBridge", "*.md")))

def scan(files):
    hits, props, skips = [], [], []
    for p in files:
        try:
            lines = open(p, encoding="utf-8", errors="replace").read().split("\n")
        except OSError:
            continue
        for ln, line in enumerate(lines, 1):
            if not re.search(TRIGGER, line) or not re.search(DECISION, line):
                continue
            tag = "%s:%d" % (os.path.relpath(p), ln)
            if re.search(VETO, line):
                props.append(tag); continue
            (hits if re.search(REG, line) else skips).append(tag)
    return hits, props, skips

def canary():
    tmp = tempfile.mkdtemp(prefix="nlint-canary-")
    try:
        os.makedirs(os.path.join(tmp, "docs"))
        os.makedirs(os.path.join(tmp, "build", "MilBridge"))
        open(os.path.join(tmp, "docs", "DECL.md"), "w", encoding="utf-8").write(
            "`Nl*` 6 条连字/拼写在本移植不可用：**有意降级**，主控**已裁定**在册。\n")
        open(os.path.join(tmp, "docs", "PROP.md"), "w", encoding="utf-8").write(
            "建议把 `Nl*` 连字族登记为「有意降级」—— **必须**在册写明（待登记）。\n")
        open(os.path.join(tmp, "docs", "NOMARK.md"), "w", encoding="utf-8").write(
            "`Nl*` 连字这一族是**有意降级**。（本行没写谁裁的）\n")
        open(os.path.join(tmp, "build", "MilBridge", "WXX-report.md"), "w", encoding="utf-8").write(
            "`Nl*` 连字族**有意降级**，主控**已裁定**在册。\n")
        h, p, s = scan(registry_files(tmp))
        reg = registry_files(tmp)
        ok4 = (not any(os.path.basename(x) == "WXX-report.md" for x in reg)) and \
              (not any("WXX-report.md" in x for x in h))
        ok = len(h) >= 1 and len(p) >= 1 and len(s) >= 1 and ok4
        print("NL_DECL_CANARY=%s declared_fixture=%d proposal_fixture=%d skipped_fixture=%d report_in_registry=%s"
              % ("PASS" if ok else "FAIL", len(h), len(p), len(s), not ok4), file=sys.stderr)
        return ok
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

if run_canary and not canary():
    print("NOINFO"); sys.exit(0)
if not os.path.isdir(root):
    print("NOINFO"); sys.exit(0)
reg = registry_files(root)
if not reg:
    print("NOINFO"); sys.exit(0)
h, p, s = scan(reg)
rep_h, _, _ = scan(report_files(root))
for x in h:
    print("NL_DECL_HIT %s" % x, file=sys.stderr)
for x in p:
    print("NL_DECL_PROPOSAL %s（**提案，不是声明**：含否决词 ⇒ 不计）" % x, file=sys.stderr)
for x in s:
    print("NL_DECL_SKIP %s（命中词但**没有裁定标记** ⇒ 不计）" % x, file=sys.stderr)
print("NL_DECL_SCOPE registry_files=%d report_files=%d（报告面命中 %d 行，**不计数**）"
      % (len(reg), len(report_files(root)), len(rep_h)), file=sys.stderr)
print("PASS" if h else "FAIL")
PY_DECL
}

probe_exports() {   # $1 = .so ⇒ 命中个数（文件不存在 ⇒ -1）
    [ -f "$1" ] || { echo "-1"; return; }
    local n=0 s
    for s in $NAMES; do
        nm -D --defined-only "$1" 2>/dev/null | awk '{print $3}' | grep -qx "$s" && n=$((n+1))
    done
    echo "$n"
}

anchor_count() {    # 3 处行为锚（内容锚）
    local n=0
    if [ -f "$NL_SRC" ] && grep -q 'NlCreateHyphenator' "$NL_SRC" \
        && grep -q 'catch (EntryPointNotFoundException)' "$NL_SRC"; then n=$((n+1)); fi
    if [ -f "$NL_SRC" ] && grep -q '_hyphenatorResource == IntPtr.Zero' "$NL_SRC" \
        && grep -q 'No hyphenator available' "$NL_SRC"; then n=$((n+1)); fi
    if [ -f "$TP_SRC" ] && grep -q '_lineProperties.Hyphenator = StructuralCache.Hyphenator' "$TP_SRC"; then n=$((n+1)); fi
    echo "$n"
}

build_fake_so() {   # $1 = 输出路径；成功 ⇒ 0
    cat > "$1.c" <<'C_EOF'
#include <stddef.h>
#define FAKE_HANDLE ((void *)(size_t)0xA5A5A5A5UL)
void *NlCreateHyphenator(void) { return FAKE_HANDLE; }              /* 非 NULL **假句柄** */
void  NlDestroyHyphenator(void **h) { if (h) *h = NULL; }
int   NlLoad(void) { return 0; }
void  NlUnload(void) { }
int   NlGetClassObject(void *c, void *i, void **o) { (void)c; (void)i; if (o) *o = NULL; return 0; }
int   NlHyphenate(void *h, const void *t, int n, int l, void *pos, int cap)
{
    (void)t; (void)l;
    if (!h || !pos || n <= 0 || cap <= 0) return -1;
    unsigned char *b = (unsigned char *)pos;
    for (int i = 0; i < n; i += 4) b[i >> 3] |= (unsigned char)(1u << (i & 7));
    return 0;
}
C_EOF
    gcc -shared -fPIC -O1 -o "$1" "$1.c" 2>/dev/null
}

run_case() {   # $1=so $2=root
    EXPORTS="$(probe_exports "$1")"
    DECL="$(decl_verdict "$2" 1)"
    ANCHORS="$(anchor_count)"
    if [ "$EXPORTS" = "-1" ]; then EXPORT_STATE="NOINFO"
    elif [ "$EXPORTS" = 0 ]; then EXPORT_STATE="CAPABILITY_ZERO"
    else EXPORT_STATE="RED_IMPLEMENTED"; fi
}

# ── 自测（四极）──────────────────────────────────────────────────────────────
if [ "$selftest" = 1 ]; then
    TMP="$(mktemp -d "${TMPDIR:-/tmp}/nlint-XXXXXX")"
    trap 'rm -rf "$TMP"' EXIT
    mkdir -p "$TMP/ok/docs" "$TMP/prop/docs"
    printf '`Nl*` 6 条连字/拼写在本移植不可用：**有意降级**，主控**已裁定**在册。\n' > "$TMP/ok/docs/DECL-NL.md"
    printf '建议把 `Nl*` 连字族登记为「有意降级」—— **必须在册**写明（待登记）。\n' > "$TMP/prop/docs/PROP-NL.md"
    ok=0; total=0
    echo "== 极 1：真 shim（无 Nl* 导出）⇒ 导出面必须 CAPABILITY_ZERO =="
    total=$((total+1)); run_case "$SO" "$TMP/prop"
    echo "  EXPORTS=$EXPORTS state=$EXPORT_STATE ⇒ $([ "$EXPORT_STATE" = CAPABILITY_ZERO ] && echo OK || echo BAD)"
    [ "$EXPORTS" = "-1" ] && echo "  ⚠️ 真 shim 找不到：so=$SO（**先修路径再判**；这一极没量到东西）"
    [ "$EXPORT_STATE" = CAPABILITY_ZERO ] && ok=$((ok+1))
    echo "== 极 2：现场 gcc 编出的假 .so（6 名 + 非 NULL 假句柄）⇒ 导出面必红 =="
    if command -v gcc >/dev/null 2>&1 && build_fake_so "$TMP/libnl_fake.so"; then
        total=$((total+1)); run_case "$TMP/libnl_fake.so" "$TMP/prop"
        echo "  EXPORTS=$EXPORTS state=$EXPORT_STATE ⇒ $([ "$EXPORT_STATE" = RED_IMPLEMENTED ] && echo OK || echo BAD)"
        [ "$EXPORT_STATE" = RED_IMPLEMENTED ] && ok=$((ok+1))
    else
        echo "  gcc 不可用或编译失败 ⇒ **本极判 NOINFO**（绝不算 PASS）"
    fi
    echo "== 极 3：合成登记面放合格声明 ⇒ 段② 必须 PASS =="
    total=$((total+1)); run_case "$SO" "$TMP/ok"
    echo "  DECL=$DECL ⇒ $([ "$DECL" = PASS ] && echo OK || echo BAD)"
    [ "$DECL" = PASS ] && ok=$((ok+1))
    echo "== 极 4：合成登记面放提案行（含否决词）⇒ 段② 必须 FAIL =="
    total=$((total+1)); run_case "$SO" "$TMP/prop"
    echo "  DECL=$DECL ⇒ $([ "$DECL" = FAIL ] && echo OK || echo BAD)"
    [ "$DECL" = FAIL ] && ok=$((ok+1))
    if [ "$total" -lt 4 ]; then echo "NL_TOOTH_SELFTEST=NOINFO ok=$ok/$total（gcc 缺失 ⇒ 阳性对照没造出来）"; exit 2; fi
    if [ "$ok" = "$total" ]; then echo "NL_TOOTH_SELFTEST=PASS $ok/$total"; exit 0; fi
    echo "NL_TOOTH_SELFTEST=FAIL $ok/$total"; exit 1
fi

# ── 真跑 ────────────────────────────────────────────────────────────────────
ROOT="${ROOT_OVERRIDE:-$R}"
run_case "$SO" "$ROOT"
HC_UI="NOINFO"
[ -f "$HC_XAML" ] && HC_UI="$(grep -q 'IsHyphenationEnabled="True"' "$HC_XAML" && echo yes || echo no)"
echo "NL_INTENT exports=$EXPORTS export_state=$EXPORT_STATE decl=$DECL anchors=$ANCHORS/3 hc_uientry=$HC_UI so=$SO"
if [ "$EXPORT_STATE" = NOINFO ] || [ "$DECL" = NOINFO ]; then
    echo "NL_INTENT_RESULT=NOINFO reason=no-so-or-canary-blind"; exit 2
fi
if [ "$EXPORT_STATE" = RED_IMPLEMENTED ]; then
    echo "NL_INTENT_RESULT=FAIL reason=implemented（Nl* 已在导出面 ⇒ 「有意降级」不再成立：必须重测行为并更新在册）"; exit 1
fi
if [ "$DECL" != PASS ]; then
    echo "NL_INTENT_RESULT=FAIL reason=not-declared（导出面已是能力 0，但合格声明行为 0）"; exit 1
fi
if [ "$ANCHORS" -lt 3 ]; then
    echo "NL_INTENT_RESULT=FAIL reason=anchors=$ANCHORS/3（行为链前提锚缺失）"; exit 1
fi
echo "NL_INTENT_RESULT=PASS capability=0 declared=yes anchors=$ANCHORS/3 hc_ui=$HC_UI"
exit 0
