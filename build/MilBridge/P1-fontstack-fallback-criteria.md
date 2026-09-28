# P1-W36 · 字体栈**降级路径**预登记判据 —— 族解析失败必须**可降级**（页级占位／回退族），而不是 `FailFast` 打死进程

> **本件是判据件（先写），不是实现件**：本件**不做**实现、**不构建**、**不跑腿**、**不占显示位**，供随后的**实现件**与**独立复核件**当契约用。
> **一切读数由我现取**（命令与输出原样贴出）；**未引任何既有报告当证据**（`build/MilBridge/P1-w8-step4-report.md`／`W60A-report.md` 等**一条读数未抄**；`docs/ROUTES.md` 只作"该栈**在册位置**"的**指针**，其数字不承重）。
> **边界（硬）**：只读仓树；唯一写入 ＝ 本件；**未** `dotnet build`、**未**跑腿、**未**占显示位、**未**跑整趟门禁、**未** `git add/commit/push`；未改任何产品件／判据件／`ROUTES.md`／`HANDOFF-NEXT.md`／`tools/**`／`src/**`。
> **读取时刻**：`ts=2026-09-29T03:03:51.152+0800`（起点）→ `2026-09-29T03:04:18.389+0800`（末取）。**本件为 `t112` 的 attempt 2**（attempt 1 被中断，未落任何件）。

---

## §0 快照与现取读数

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`9d43014`**（`docs(#81): 补 t110 的两处复述位（README/win32_classification.c）+ t111 W8 第四步复核载体入账`） | `git log --oneline -3` |
| 工作树 | **干净**：只有 2 个 `??`（`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`、`src/tests/`）—— **均为他人**（`t110` 落地后 `arm_A` 被移出索引） | `git status --porcelain` |
| 导出面 | `nm -D --defined-only … \| awk '{print $3}' \| grep -c .` ＝ **572** ＝ `wc -l src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **572**（`exports.txt` sha16 `b1996a77bfbf869d`） | `nm`／`wc -l`／`sha256sum` |
| 权威 `.so` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`a131ea4e6f5cc4f5`** | `sha256sum` |
| 在册腿证据 | `leg_23.env` ＝ **`f1fc16ac52965971`**（277 B，`mtime 02:20:36`）｜`leg_24.env` ＝ **`9c229380a3659c01`**（253 B，`mtime 02:48:38`）｜`app_g1.log` ＝ **`eeb96339eebd35a6`**（79337 B，`mtime 02:48:33`）｜`session.txt` ＝ **`e19a80642461efc9`**（1989 B）｜`device.txt` ＝ `5cec7306388ebe1e` | `sha256sum`／`stat` |
| `leg_23`（现取原文） | `LEG k=23 alive=yes app_rc=143 magenta=49923 colors=844 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=141323 ink=428491`｜`NAMED managed_unavail=1 err=-10000 native_gap=2 native_err=-10000`｜`DEV x_up=yes five_stable=yes shim=a2de5ff2b667f33f pf=6893d1d3fb1ee110` | `cat` |
| `leg_24`（现取原文） | `LEG k=24 alive=no app_rc=134 magenta=0 colors=1 ns=HandyControlDemo.UserControl.PracticalDemo ae=480000 ink=0`｜`NAMED managed_unavail=0 err=- native_gap=0 native_err=-`｜`DEV x_up=yes five_stable=yes shim=a131ea4e6f5cc4f5 pf=2988f5154ecac5dd` | `cat` |
| 会话面板 | `GROUP 1 arm=A clicks=[24,23] 02:48:16`｜`shim_sha16=a131ea4e6f5cc4f5 pf_sha16=2988f5154ecac5dd`｜`CLICK k=24 alive=no expect=FlowDocumentDemo AE=480000 pts_unavail=0 pts_gap=0 guard=0 fatal=2 unh=0 ns_last=…PracticalDemo`｜`PHASE k=24 c1_ep=- c2_pts_gap=- c3_pts_unavail=- c4_unrecoverable=796 managed_err= native_err=`｜`APP_RC=134` | `grep`（`session.txt`） |
| 台账/具名面（**现取为零**） | `grep -cE '^PTS_GAP entry=' app_g1.log` ＝ **0**；`grep -c 'PTS-UNAVAILABLE'` ＝ **0** ⇒ **PTS 族完全退出舞台**（`t110` 的效应，本件现取复算） | `grep -c` |
| 崩溃面 | `grep -c 'Invariant.FailFast' app_g1.log` ＝ **1**；「`Unrecoverable system error.`」**两行**（`:796`／`:798`），`od -c` 现取 **两行都以 `.\n` 收尾、无 `: <msg>` 后缀** | `grep -c`／`sed`／`od -c` |
| 守卫（现取） | `bash build/MilBridge/tools/pts-pages-guard.sh --legs <evidence>` ⇒ **`rc=1`**；`PTS_GUARD=FAIL legs=2/2 fails=leg24-not-alive(alive=no),leg24-abort(app_rc=134),leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-) cannot=leg24(ns=…PracticalDemo≠…FlowDocumentDemo) diag=leg24-colors-out-of-band=1 direction=in-file phase=degraded`；`PTS_G10_NAME=PASS form=unnamed reason=frontier-unnamed` | 现跑 |
| `fc-list` | 行数 ＝ **414**；`fc-list : family` 去重后 **233** 个族串；**匹配 `^arial`（不分大小写）＝ 0**；`DejaVu Sans` **在**（6 个文件，`/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf` 等） | `fc-list`／`fc-match` |
| `fc-match` 面 | `fc-match Arial` ⇒ `LiberationSans-Regular.ttf: "Liberation Sans" "Regular"`（**替换**，不是族存在）；`fc-match 'Global User Interface'` ⇒ `NotoSansCJK-Regular.ttc: "Noto Sans CJK SC"` | `fc-match` |
| `fp_inputs()` 覆盖面 | 活清单 **234** 件（现算，见 §1.4 命令） | 现算 |
| `ARTIFACT-SRC-FP`（**第二覆盖面**） | 现跑 `artifact-src-fp.py`：`PresentationCore fp=2f3e458da268e872 n=1374`／`WindowsBase fp=d8e289bb176fed09 n=327`／`PresentationFramework fp=611e5304aa3dcb6b n=1363`；`PROJECTS` 只有这三工程 | 现跑（纯读，`--list`／无参） |

⚠️ **本趟两处必须如实登记、不当红**（**写死，供复核件识别**）：
1. **两条腿不是同一代**：`leg_23` 的 `DEV shim=a2de5ff2b667f33f`（`mtime 02:20:36`，`t103` 那一代），`leg_24` 的 `DEV shim=a131ea4e6f5cc4f5`（`mtime 02:48:38`，现盘那一代）⇒ **现盘 `leg_*.env` 是跨代拼盘**。成因可读：会话面板 `clicks=[24,23]` ⇒ **k=24 先跑且进程当场死** ⇒ k=23 **根本没跑**（`leg_23.env` 是上一趟留下的旧件）。
2. **`pts-pages-guard.sh` 看不见这件事**：现取该件 `grep -n 'shim'` 只命中 `--selftest` 的夹具写出行（`:486`）与件头注释（`:61-63`），**活的腿解析段不读 `DEV … shim=`** ⇒ 它对跨代拼盘照样报 `legs=2/2`。⇒ **同趟性必须由本判据自带一条牙**（见 C7），**不许**拿守卫的 `legs=2/2` 当"两腿同代"。

---

## §1 ① 域定位（**本件必答**）

### 1.1 崩溃栈逐帧 → 件 / `file:line` / 原文

| 栈帧（`app_g1.log:803-808` 现取） | 实际实现在哪个件 | 现取 `file:line` 与原文 |
|---|---|---|
| `MS.Internal.Invariant.FailFast(String, String)` | **`build/WindowsBase.Linux/Invariant.Linux.cs`**（sha16 `d0a35feec973655e`；**生成件**，见 1.2）；上游原型 `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Shared/MS/Internal/Invariant.cs` | `Invariant.Linux.cs:~203 _FailFast(string message, string detailMessage)` 内 `Environment.FailFast(BuildInvariantFailureText(message, detailMessage));`；上游 `Invariant.cs:192-204` 同形（`Environment.FailFast(SR.InvariantFailure)`） |
| `System.Windows.Media.FontFamily.get_FirstFontFamily()` | **`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/FontFamily.cs:311-347`**（sha16 `8be2d3540c60f438`）；**无 `.Linux.cs` 覆盖**（全树 `grep -rn 'FirstFontFamily' --include=*.cs` 排除 `upstream/` 后命中 **0**） | `:311 internal IFontFamily FirstFontFamily { get { … } }` |
| `System.Windows.Media.FontFamily.get_LineSpacing()` | 同件 | `:235 return FirstFontFamily.LineSpacing(emSize, 1, pixelsPerDip, TextFormattingMode.Display);` |
| `MS.Internal.Text.DynamicPropertyReader.GetLineHeightValue(DependencyObject)` | `upstream/.../PresentationFramework/MS/Internal/Text/DynamicPropertyReader.cs:200-211` | `:208 lineHeight = fontFamily.LineSpacing * fontSize;` |
| `MS.Internal.Documents.FlowDocumentFormatter.ComputePageMargin()` | `upstream/.../PresentationFramework/MS/Internal/documents/FlowDocumentFormatter.cs:218` | `:220 double lineHeight = MS.Internal.Text.DynamicPropertyReader.GetLineHeightValue(_document);` |
| `MS.Internal.Documents.FlowDocumentFormatter.Format(Size)` | 同件 | `:51 internal void Format(Size constraint)`；`:90 pageMargin = ComputePageMargin();` |
| 其余 `Measure*`／`Grid.Measure*` 帧 | 标准布局链 | 与本族无关（只是调用者） |

⇒ **域定位结论（一句话）**：本族**不在** `build/DirectWrite.Linux/**` 的字体解析面里**被决定**，而是 **`FontFamily.cs`（上游编译源，托管）里的一条 `Invariant.Assert`** —— **解析结果的消费者**在托管；解析结果的**生产者**是 `FamilyCollection.Linux.cs`（生成件）＋ provider（`build/DirectWrite.Linux/Provider/**`）。**修在"消费者"或"生产者"两侧都成立，但两侧的可覆盖性差别很大（见 1.4）。**

### 1.2 `FailFast` 的**精确定位**（**机读**，不是猜）

上游 `Invariant.cs` 有三个到达 `FailFast` 的入口：
```
: 98 internal static void Assert(bool condition, string invariantMessage)  ⇒ FailFast(invariantMessage, null)
:118 internal static void Assert(bool condition, string invariantMessage, string detailMessage) ⇒ FailFast(…, …)
: 68 internal static void Assert(bool condition)                            ⇒ FailFast(message: null, detailMessage: null)
```
`Invariant.Linux.cs`（补丁 N）在 `FailFast` 开头**把原文打出去**、并把原文**拼进终止文本**：
```
private static void FailFast(string message, string detailMessage)
{
    PrintInvariantFailure(message, detailMessage);           // ← 打 stderr
    …
    Environment.FailFast(BuildInvariantFailureText(message, detailMessage));
}
private static string BuildInvariantFailureText(string message, string detailMessage)
{
    string text = SR.InvariantFailure;
    if (!string.IsNullOrEmpty(message))       { text += ": " + message; }
    if (!string.IsNullOrEmpty(detailMessage)) { text += " — " + detailMessage; }
    return text;
}
```
**现取机读**（`sed -n '796p;798p' … | od -c`）：两行**都恰好是** `Unrecoverable system error.\n`，**没有** `: ` 后缀、**没有** ` — ` 后缀 ⇒ **`message` 与 `detailMessage` 都是空** ⇒ **走的是 1 参重载 `Invariant.Assert(bool)`**。

⇒ 而 `FontFamily.get_FirstFontFamily`（`:311-347`）**体内只有一条** `Invariant.Assert`，且它**正是 1 参**：
```
:332                         if (family == null)
:333                         {
:334                             // fall back to null font
:335                             family = LookupFontFamily(NullFontFamilyCanonicalName);
:336                             Invariant.Assert(family != null);
:337                         }
```
**⇒ FailFast 位点 ＝ `FontFamily.cs:336`（机读确定；`Invariant.cs:192-204` 那条路只是它的下落）**。
**排除的两个同族候选（现取，供复核件对拍）**：`:445 Invariant.Assert(_firstFontFamily != null, "Unnamed FontFamily should have a non-null first font family");` 与 `:396 Invariant.Assert(fontFamily != null, "Unable to create null font family");` —— **两者都是 2 参**（带消息）⇒ 若命中它们，日志里会出现 `: <消息>` 后缀；**现取没有** ⇒ **不是它们**。

### 1.3 触发条件（源码级：**什么输入会走到它**）

```
: 38  internal static readonly CanonicalFontFamilyReference NullFontFamilyCanonicalName
          = CanonicalFontFamilyReference.Create(null, "#ARIAL");        ← 「空字体」的规范名 = #ARIAL
:314  IFontFamily family = _firstFontFamily;
:317  if (family == null)
:320      _familyIdentifier.Canonicalize();
:323      family = TypefaceMetricsCache.ReadonlyLookup(FamilyIdentifier) as IFontFamily;
:325      if (family == null)
:330          family = FindFirstFontFamilyAndFace(ref style, ref weight, ref stretch);   ← ① 请求的族能不能解析
:332          if (family == null)
:335              family = LookupFontFamily(NullFontFamilyCanonicalName);                ← ② 空字体 #ARIAL 能不能解析
:336              Invariant.Assert(family != null);                                     ← ★ FailFast 位点
```
⇒ **触发条件（写死）**：**「① 请求的族解析不到」∧「② 空字体 `#ARIAL` 解析不到」** ⇒ `Invariant.Assert` ⇒ `Environment.FailFast`（**不可捕获**，绕过 `DispatcherUnhandledException`，因为它是 `Environment.FailFast` 而不是托管异常）。

**② 这一半在本机上是不是"必假"？—— 现取证据（三条，独立）**：
1. **本机没有 Arial 这个族**：`fc-list : family \| tr ',' '\n' \| sed 's/^ *//' \| sort -u \| grep -ci '^arial'` ⇒ **0**（共 233 个族串）。
2. **`#ARIAL` 走不到"系统复合字体"那条已被打补丁的回退支**：`FamilyCollection.Linux.cs` 的 provider 回退**带名字闸**：
```
:1736 if (!OperatingSystem.IsWindows() && SystemCompositeFonts.IsSystemCompositeFontName(familyName))
:1738     IFontFamily providerFallback = GetProviderFallbackFamily();
```
 而闸内名单**只有 4 个系统复合字体名**（现取 `:1537`）：`"Global User Interface"／"Global Monospace"／"Global Sans Serif"／"Global Serif"` ⇒ **`"Arial"` 不在其中** ⇒ `LookupFamily("Arial")` 落到 `:1746 _fontCollection["Arial"]` ⇒ **null**（本机无此族）⇒ `LookupFontFamily("#ARIAL")` 返回 **null** ⇒ **`:336` 必红**。
3. **`CanonicalFontFamilyReference.Create(null, "#ARIAL")` 本身是"已解析"的**（现取 `CanonicalFontFamilyReference.cs:36-41`：`locationString == null` ⇒ `fileName = null; resolved = true`）⇒ **不是**"因为规范名没解析所以返回 null"，而是**真的去集合里查了、查不到**。

⇒ **结论（本族的核心判据前提，写死）**：**只要①发生，②必然也发生 ⇒ 必 FailFast。** 这解释了为什么 `fc-list=414`／`DejaVu Sans` **装了**都不救场：**救场点在②（`#ARIAL` 对端），而它今天没有任何回退**。
⚠️ **本件不声称"① 到底请求了哪个族名"** —— 见 §2.2（三个代码级候选）与 §6-N1（`NOINFO`）。

### 1.4 **拟改件清单**及覆盖面（现取命令 + 读数）

**覆盖面 A ＝ `fp_inputs()`**（现取命令，纯读；把该函数的**末段**由 `xargs sha256sum …` 换成 `cat` 以拿到清单，`sed`/`python3` 只写 `/tmp`）：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux
sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh > /tmp/t112_fpfn_raw.sh
python3 - <<'PY'
src=open('/tmp/t112_fpfn_raw.sh',encoding='utf-8').read()
assert 'xargs sha256sum | sha256sum' in src
open('/tmp/t112_fpfn.sh','w',encoding='utf-8').write(src.replace("xargs sha256sum | sha256sum | cut -d' ' -f1","cat"))
PY
bash -c 'source /tmp/t112_fpfn.sh; fp_inputs' | LC_ALL=C sort > /tmp/t112_fp_list.txt; wc -l < /tmp/t112_fp_list.txt
```
⇒ **`n=234`**（`rc=0`）。

**覆盖面 B ＝ `ARTIFACT-SRC-FP`**（现取命令，纯读）：`python3 build/artifact-src-fp.py`／`--list <PROJ>` ⇒ `PresentationCore fp=2f3e458da268e872 n=1374`、`WindowsBase fp=d8e289bb176fed09 n=327`、`PresentationFramework fp=611e5304aa3dcb6b n=1363`；`PROJECTS` 现取只有这三工程（`build/artifact-src-fp.py:65`）。

| # | 拟改件 | 角色 | sha16（现取） | `fp_inputs()` | `ARTIFACT-SRC-FP` |
|---|---|---|---|---|---|
| M1 | `upstream/wpf/…/PresentationCore/System/Windows/Media/FontFamily.cs` | **首选修点**：`#ARIAL` 回退后的 `:336` 断言（"降级"就在这里断掉） | `8be2d3540c60f438` | **不在（0）** | **在**（`--list PresentationCore:851`，sha 与直取**逐位相同** `8be2d3540c60f438`） |
| M2 | `build/PresentationCore.Linux/FamilyCollection.Linux.cs` | **次选修点**：`LookupFamily` 给 `#Arial` 一类"非系统复合字体名"也做 provider 回退（对端修法） | `19a42240f59af073` | **不在（0）** | **在**（PC 面） |
| M3 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py` | **M2 的生成器**（**改 M2 必须改它**，否则下次生成即回退） | `3610e096981daab8` | **在（1）** | **在**（PC 面 `:30`） |
| M4 | `build/shims/PresentationCore.Factory.Linux.cs` | 系统字体集合/目录解析（`WPF_LINUX_FONT_DIR` ＋ 候选目录） | `125cfaa3c9851cfd` | **在（1）** | **在**（PC 面） |
| M5 | `build/shims/PresentationCore.HbTextLine.cs` | 行级**按码点回退**诊断面（`HbFallbackDiag`，`fallbackApplied/fallbackFailed/…`） | `921ba9c65e9fb3be` | **在（1）** | **在**（PC 面） |
| M6 | `build/DirectWrite.Linux/Provider/DefaultFontFamily.cs` | provider 默认族选定（偏好序 → `fc-match` sans-serif → 族名序）＋ `WPF_LINUX_FONT_DIAG` | `d574c3acd6cc6939` | **不在（0）** | **不在**（三工程 src 面都不收 `build/DirectWrite.Linux/**`；该 DLL 只作为 PC 面的 **peer** 出现） |
| M7 | `build/DirectWrite.Linux/Provider/LinuxFontCollection.cs` | 族名索引（`_familyIndex`，`OrdinalIgnoreCase`） | `e07ac1329fec10fa` | **不在（0）** | **不在**（同上） |
| M8 | `build/WindowsBase.Linux/Invariant.Linux.cs` | `FailFast` 的**输出**形态（补丁 N：打原文） | `d0a35feec973655e` | **不在（0）** | **在**（WB 面） |
| M9 | `src/WpfGfx.Linux.Native/tools/patch-shared-invariant-failfast.py` | M8 的生成器 | `e2a7da444a2e7080` | **在（1）** | 现取 `--list WindowsBase` 面**未见**该件在 src 面（**只报"我未命中"**，不断言机制） |
| M10 | `src/WpfGfx.Linux.Native/src/win32_misc.c` | `SystemFonts.MessageFontFamily` 的来源（`SPI_GETNONCLIENTMETRICS` → `lfMessageFont.lfFaceName`） | `02bfe06166e7f425` | **在（1）**（`*.c` 那行 `find`） | **不在**（PC/WB/PF 三面都不收 `src/WpfGfx.Linux.Native/src/**`） |
| M11 | `upstream/wpf/…/PresentationFramework/System/Windows/Documents/TextElement.cs` | 默认 `FontFamily` 的元数据（`= SystemFonts.MessageFontFamily`） | 现件在（`:443-449`） | **不在** | 在 PF 面（未逐条取，**不以"未取到"当结论**） |

⇒ **覆盖面结论（写死，供实现件排流程）**：
- **M1／M2／M8 是"改它必须一并想清楚覆盖面"的件**：`fp_inputs()` **看不见它们**，但 `ARTIFACT-SRC-FP` **看得见**（`src` 面），⇒ **不移动 `inputs_fp`，但移动对应工程的 `ARTIFACT_SRC_FP`**。
- **M6／M7（provider）在三工程 src 面之外** ⇒ 改它们 **两个指纹都不动**（**残留缺口**，如实登记；本件不主张扩面）。
- **M3／M9（生成器）在 `fp_inputs()` 里** ⇒ 改生成器 **必然移动 `inputs_fp`**（`close-wave.sh` 自含于覆盖面，设计使然）。
- ⚠️ **生成件的铁律**：M2／M8 是**由脚本从上游重生成**的（M2 件头现取逐字「本文件由 …patch-presentationcore-compositefont.py **生成**，不要手改」）⇒ **改生成件而不改生成器 ＝ 下次生成即静默回退**。

---

## §2 ② 现取复现面（只读侧）

### 2.1 字体面（`fc-list`／`fontconfig`）
- `fc-list` 行数 **414**；`fc-list : family` 去重 **233** 族；`^arial`（ci）**0**；`DejaVu Sans` **在**。
- `fc-match Arial` ⇒ `Liberation Sans`（**fontconfig 的替换规则**，不是"Arial 这个族存在"）。
- ⇒ **教训（写进判据）**：**不许**把 `fc-match` 的输出当成"该族存在"的证据。**存在性**只能由"集合里查到了"证明（C4 给读数口径）。

### 2.2 该 Run 请求的族名 —— **三个代码级候选 ＋ `NOINFO` 声明**
现取到的**唯一**默认族链路（**逐条 `file:line`**）：
```
TextElement.cs:443-449      TextElement.FontFamilyProperty 的默认值 = SystemFonts.MessageFontFamily
SystemFonts.cs:441-451      MessageFontFamily = new FontFamily(SystemParameters.NonClientMetrics.lfMessageFont.lfFaceName)
win32_misc.c:679-705        SPI_GETNONCLIENTMETRICS ⇒ fill_logfont(&ncm->lfMessageFont, …, face)   // face = ui_font_face()
win32_misc.c:589            #define WPF_DEFAULT_UI_FONT      "DejaVu Sans"
win32_misc.c:596-600        ui_font_face() ⇒ getenv("WPF_LINUX_UI_FONT") ?: "DejaVu Sans"
```
⇒ **候选 ①**：`"DejaVu Sans"`（shim 的默认 UI 族，**本机存在**）—— 若它是实际请求值，则①不该失败 ⇒ 与崩溃矛盾。
⇒ **候选 ②**：`$WPF_LINUX_UI_FONT`（现取 `env \| grep -i 'WPF_LINUX\|FONT'` ⇒ **本 shell 无该变量**；腿跑器与 `session_inner.sh` 里现取**没有** export 它；仓内 `grep -rn 'WPF_LINUX_UI_FONT'` 的**唯一**实现位就是 `win32_misc.c`）⇒ 若腿环境另有设置（例如由仓外装配脚本注入），**本件看不见**。
⇒ **候选 ③**：演示侧自己设的族（仓外第三方应用现取命中 3 处：`Resources/Themes/Styles/Style.xaml:90 FontFamily={StaticResource FabricIcons}`、`:124 FontFamily="Consolas"`、`Resources/Themes/Basic/Fonts.xaml:4 <FontFamily x:Key="FabricIcons">pack://…/fabric-icons.ttf#Fabric MDL2 Assets</FontFamily>`）—— 其中 `#Fabric MDL2 Assets` 是**资源内嵌字体**，**不在系统集合里**。
⇒ 而 `FlowDocumentDemo.xaml` **本身**现取 `grep -n FontFamily` **0 命中** ⇒ 该文档的 `FontFamily` 是**继承值**（不是页面自己写的）。
**⇒ 本件写死**：**「① 实际请求了哪个族名」＝ `NOINFO(reason=需运行期读数)`**（见 §6-N1）。**判据不依赖它** —— 见 §3 的"两极化必须由**受控**族名承载"（a＝受控的不存在族；b＝受控的存在族），这正是绕过该 `NOINFO` 的**正解**，而不是"猜一个"。

### 2.3 现取证据面（**这一节的数字全部自己取**）
- `app_g1.log`：`^PTS_GAP entry=` ＝ **0**、`PTS-UNAVAILABLE` ＝ **0**（**两族同时为零** ⇒ "PTS 族已让位、本族接手"是**现取事实**）；
- 崩溃栈在 `:799-808`；`Unrecoverable system error.` 两行 `:796`／`:798`（**无消息后缀** ⇒ §1.2 的 1 参判据）；
- `session.txt`：`clicks=[24,23]`、`APP_RC=134`、`fatal=2 unh=0`、`PHASE … c4_unrecoverable=796`、`k24.png` `colors=1 magenta=0 ink=0 total=1310720`（**整屏一色** ⇒ 不是"画错"而是"没画"）；
- `k=23` **没有本趟读数**（见 §0 的告警 1）⇒ **本趟的"两页症状面"只能给一页**；
- 守卫 `rc=1` 且**四条 `fails` 全部点名 `leg24-*`**，`cannot` 点名 `ns` 不匹配 ⇒ **"降级没发生"这件事是四条独立的机器判词，不是靠肉眼**。

### 2.4 本件**不能**取、必须交实现件的项（写清"谁能取"）
| 项 | 本件状态 | 谁能取 / 消掉需要什么 |
|---|---|---|
| 腿跑时 `WPF_LINUX_UI_FONT`／`WPF_LINUX_FONT_DIR` 的**实际值** | `NOINFO(reason=读不到腿进程的 environ；本件不跑腿)` | 实现件：在腿日志里打这两格，或读 `/proc/<pid>/environ`（**按 PID**，禁 `pgrep -f`） |
| 该 Run 实际请求的族名 | `NOINFO(reason=需运行期读数)` | 实现件：让解析失败路径打**一行具名诊断**（含请求名） |
| `SystemFonts.MessageFontFamily.Source` | `NOINFO(reason=需跑进程)` | 实现件：`SystemFontsProbe`（仓内已有装置）或腿日志 |
| `LinuxFontCollection` 实际索引到多少个族／有没有 `DejaVu Sans` | `NOINFO(reason=需跑进程；本件只能给"目录解析规则"与"fontconfig 侧存在性")` | 实现件：`Factory.SystemFontDirectoryDiagnostics`（`PresentationCore.Factory.Linux.cs:248-263` 现取有这个诊断串） |

---

## §3 ③ 诚实边界：最小可辩护实现 / 假成功 / 非目标

> **分界句（沿用 W8 各步口径，逐字）**：**"崩得少一点"不是证据，"没崩"也不是证据**；证据是「**该次解析失败在本进程内留下了与该输入绑定、可被独立读取的判定结果**（请求名 → 选中族 或 明确的"未解析"），
> **并且**能在**同一份读数**里区分"降级发生了"与"降级没发生"」。

- **最小可辩护实现（本族，两条路任选其一，但都必须满足 C1–C5）**：
  1. **对端修法（推荐）**：把「空字体 `#ARIAL`」这一支接上 provider 默认族 —— 即让 `LookupFontFamily(NullFontFamilyCanonicalName)` 在 Linux 上**返回一个真实族**（等价于 `FamilyCollection.Linux.cs:1736-1743` 那条**已有**回退，只是**把闸从"4 个系统复合字体名"放宽到"任何解析不到的族名"**或**至少放宽到空字体名**）。
  2. **调用侧修法**：在 `FontFamily.FirstFontFamily` 的 `:332-337` 那段把 `Invariant.Assert` 换成**具名降级**（返回一个真实族 ＋ 记一行诊断），**不碰** `Invariant` 本体。
  ⇒ **共同硬要求**：① **有可读的降级判定**（请求名／是否降级／落到谁）；② **降级 ≠ 静默**（必须留下一行可机读的诊断）；③ **不许把"降级"做成"总是降级"**（见下）。
- **算「假成功」（逐条写死，必红）**：
  - **只把 `FailFast` 改成静默 `return`／吞掉**（进程活了，但**没有降级**：要么继续用 null 族、要么随便挑一个族）⇒ **必红**（C4／C5 会红：没有判定行、且 C6 的正向腿会误降级）。
  - **永远返回占位/默认族**（不管请求的是存在族还是不存在族）⇒ **必红**（正向腿 C6 红）。
  - **只改计数/仪表**（改声明件、改 guard 的阈值、把 `magenta` 地板调低）⇒ **必红**（P2）。
  - **把 `FailFast` 全局改成 no-op**（改 `Invariant` 本体的全局语义）⇒ **越域 ＋ 必红**（非目标，且会掩护本仓其它 `Invariant.Assert`）。
- **非目标（明确不做）**：不实现字体族匹配/复合字体的**全部语义**（不做完整的 fontconfig 匹配、不做 composite family 解析）；**不改** `Invariant.FailFast` 的**全局语义**（它必须仍然"真的终止进程"，只是本族不该走到它）；**不动第三方**（HandyControl 演示应用／`~/hc-linux` 一个字不改）；不承诺两页真排版；不顺手扩 `fp_inputs()` 覆盖面（M6／M7 的缺口**只登记**）。

---

## §4 ④ 判据 C1–C10

> **通用**：每条 verify **必须捕获式取 `rc`**（`cmd >out 2>err; echo $?`）；**不许**从管道末段取 `$?`。
> **通用反过读句**：任何"绿"都不许被读成"该文档**排版正确**"——本族的绿**只**意味着"**解析失败被降级、进程没被打死**"。
> **通用界句**：**`alive=yes` 本身不是证据**（把 `FailFast` 删掉也能 `alive=yes`）；必须**同时**有 C4/C5 的降级判定与 C6 的正向不误降级。

### C1 构建面：改动真进了产物
- **objective**：改动真的编进权威五件之一（而不是只改了生成器/源）。
- **acceptance**：`bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >out 2>err; echo $?` ⇒ `rc=0`（若只改托管面，改走对应工程的构建）；**改到的每个工程**的 `ARTIFACT_SRC_FP` 同趟取值并给出 `so16`／`dll sha16` 与 before 的成对；**改了 M2／M8 生成件 ⇒ 必须重跑其生成器并证明生成物逐字节等于手改后内容**（否则下次生成回退）。
- **取哪个字段**：`src/WpfGfx.Linux.Native/bin/exports.txt` 行数／`.so` sha16；`python3 build/artifact-src-fp.py` 的 `fp=`／`n=`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && a=$(nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -c .); b=$(wc -l < src/WpfGfx.Linux.Native/bin/exports.txt); echo "nm=$a exports=$b equal=$([ "$a" = "$b" ] && echo yes || echo NO)"; python3 build/artifact-src-fp.py
```
- **期望形状**：两值**相等** ∧ **≥ 572**（**不得下降**）；`ARTIFACT_SRC_FP` 三行**只要有一条 `fp=` 变**，必须逐条点名"哪一件变了"。

### C2 导出/接口面：**不靠改导出面收尾**
- **objective**：本族**不是**"缺符号"族 ⇒ **不得**用"加一个导出"冒充修好。
- **acceptance**：`nm` 与 `exports.txt` 的行数**相等**且**≥ 572**；**若**出口数变化 ⇒ **逐名给出新增/删除的符号名**，并证明它是修法的**必要**部分（而不是顺手加的观测量）。
- **取哪个字段**：`nm` 逐名集合与 `exports.txt` 的 `comm -3` 差集。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | LC_ALL=C sort -u > /tmp/t112_nm.txt; LC_ALL=C sort -u src/WpfGfx.Linux.Native/bin/exports.txt > /tmp/t112_ex.txt; echo "nm=$(wc -l < /tmp/t112_nm.txt) ex=$(wc -l < /tmp/t112_ex.txt) diff=$(comm -3 /tmp/t112_nm.txt /tmp/t112_ex.txt | wc -l)"; comm -3 /tmp/t112_nm.txt /tmp/t112_ex.txt | head
```
- **期望形状**：`diff=0`；`≥ 572`；**本条的绿不构成"前进"证据**。

### C3 进程存活面：**两页都要有本趟读数**
- **objective**：崩进程这件事消失，且**是在同一趟里两页都读过**之后。
- **acceptance**：**新的腿证据目录**里 `leg_23.env` 与 `leg_24.env` **同趟**（见 C7）且两条 `LEG … alive=yes`、`app_rc ∉ {134,139}`；`session.txt` 里 **`APP_RC` 不是 134/139**，且 `clicks=` 覆盖 **k=23 与 k=24 两者**（**现存缺陷正是 `clicks=[24,23]` 且第一条就死**）。
- **取哪个字段**：`leg_{23,24}.env` 的 `LEG` 行；`session.txt` 的 `clicks=`／`APP_RC=`／`CLICK k=` 行。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D="${1:-build/MilBridge/tests/PtsPagesProbe/evidence}"; grep -hE '^LEG ' "$D"/leg_23.env "$D"/leg_24.env; grep -nE 'clicks=|^APP_RC|=CFL|CLICK k=' "$D"/session.txt
```
- **期望形状**：两行 `alive=yes`、`app_rc ∉ {134,139}`；`clicks=` 里两页都在；**`APP_RC=134` ⇒ 本条直接红**（不许用"另一页活了"辩解）。

### C4 **降级可判**面（解析失败必须留可读诊断，不许静默）
- **objective**：失败被**具名**记下，人能/机能读出"请求了什么、有没有降级、落到谁"。
- **acceptance**：腿日志里**至少一行**可机读诊断，**同时含** ① **请求族名** ② **是否降级**（二值）③ **实际选中族名或显式 "none"**；**且**该行在"请求不存在的族"那一条腿上**必然出现**（P3 反腿会验：把它删掉 ⇒ 必红）。
  ⚠️ **不许**拿"日志里没有 `Unrecoverable system error.`"当降级证据（那是"没崩"，不是"降了级"）。
- **取哪个字段**：腿日志里该诊断行的字段（实现件**必须把字段名同趟写死**并写进载体；本件不预判字段名）。
- **verify**（形状；字段名由实现件填）：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D="${1:-build/MilBridge/tests/PtsPagesProbe/evidence}"; grep -cE '<FALLBACK-DIAG 前缀>.*requested=.*fallback=(yes|no).*resolved=' "$D"/app_g1.log; grep -nE '<FALLBACK-DIAG 前缀>' "$D"/app_g1.log | head
```
- **期望形状**：计数 **≥1**（不存在族那条腿上）；**且**每一行三个字段都在。

### C5 **正向不误降级**面（族存在时不许降级）＋ **两态可区分**
- **objective**：降级是**条件性**的，不是"永远降级"。
- **acceptance**：**同一份读数**里给出**成对**的两条腿：**a) 受控的不存在族** ⇒ `fallback=yes`（且 `alive=yes`）；**b) 受控的存在族** ⇒ `fallback=no`。**两态必须由同一仪器、同一口径产出**（不许一个来自日志、另一个来自源码阅读）。
- **取哪个字段**：C4 那行的 `fallback=`／`requested=`／`resolved=`；两腿的 `LEG alive`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D="${1:-build/MilBridge/tests/PtsPagesProbe/evidence}"; grep -oE 'requested=[^ ]+ fallback=[a-z]+' "$D"/app_g1.log | sort | uniq -c
```
- **期望形状**：**至少出现 `fallback=yes` 与 `fallback=no` 各一次**（否则本条红：分不出两态 ⇒ 就是"永远降级"或"从不降级"）。

### C6 两页症状面（`magenta`／`ink`／`ns`／`colors`）
- **objective**：降级之后**页级现象**自洽：要么正常排版、要么**真的**画了页级占位 —— 不许"既没排版、也没占位"。
- **acceptance**：k=23／k=24 两条腿的 `magenta`／`ink`／`colors`／`ns` **成对给出**，并**注明落在哪一态**：
  - **degraded 态**（解析失败被降级 ⇒ 画占位）：`magenta ≥ 20000`（`MAGENTA_FLOOR` 缺省＝`20000`，`pts-pages-guard.sh:75`）**且** `ns=` 与 `expect=` 相符；
  - **realized 态**（真排版）：`magenta = 0` **且** `ink > 0` **且**无具名降级行；
  - **禁区（必红）**：`colors ≤ 2`（现取 `k24.png colors=1` 就是"整屏一色"）／`magenta=0 ∧ ink=0`（**既非占位也非排版**，本仓在册禁忌："空白不许读成绿"）。
- **取哪个字段**：`leg_{23,24}.env` 的 `LEG` 行；守卫输出的 `fails=`／`diag=`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D="${1:-build/MilBridge/tests/PtsPagesProbe/evidence}"; bash build/MilBridge/tools/pts-pages-guard.sh --legs "$D" >/tmp/t112_c6.out 2>/tmp/t112_c6.err; echo "rc=$?"; grep -E '^(PTS_GUARD|PTS_G10_NAME)=' /tmp/t112_c6.out; grep -hE '^LEG ' "$D"/leg_23.env "$D"/leg_24.env
```
- **期望形状**：`rc=0` 且 `PTS_GUARD=PASS`；两腿各落 `degraded` 或 `realized` **之一**且自洽（见上）。⚠️ **现取 before ＝ `rc=1`**（§0 那行四条 `fails` 全点名 `leg24-*`）⇒ after 必须 `rc=0` **且不靠调阈值**（P2 会验）。

### C7 **同趟性**（本步**必查**，且**不能靠守卫**）
- **objective**：before/after 的所有面取自**同一趟**；两条腿**同一代**。
- **acceptance**：`leg_23.env` 与 `leg_24.env` 的 `DEV … shim=`／`pf=` **逐位相同**，且**等于**现盘权威件 sha16；**并且**它们与 `session.txt` 的 `shim_sha16=`／`five_pre:` **同值**；`mtime` 三件同趟给出。
  🔴 **本条必须自带，因为守卫没有这条牙**：现取 `pts-pages-guard.sh` 的**活腿解析段不读 `DEV … shim=`**（只有 `--selftest` 夹具写出处 `:486` 用到），⇒ **跨代拼盘它照样报 `legs=2/2`**（§0 告警 2 已用现取的跨代读数证明）。**不许**把 `legs=2/2` 当同趟证据。
- **取哪个字段**：两腿 `DEV` 行的 `shim=`／`pf=`；`session.txt` 的 `shim_sha16=`／`five_pre`；现盘 `.so` sha16；三件 `mtime`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D="${1:-build/MilBridge/tests/PtsPagesProbe/evidence}"; s=$(sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16); a=$(grep -h '^DEV ' "$D"/leg_23.env | grep -o 'shim=[0-9a-f]*' | cut -d= -f2); b=$(grep -h '^DEV ' "$D"/leg_24.env | grep -o 'shim=[0-9a-f]*' | cut -d= -f2); c=$(grep -o 'shim_sha16=[0-9a-f]*' "$D"/session.txt | cut -d= -f2); echo "disk=$s leg23=$a leg24=$b session=$c same=$([ "$s" = "$a" ] && [ "$s" = "$b" ] && [ "$s" = "$c" ] && echo yes || echo NO)"; stat -c '%y %n' "$D"/leg_23.env "$D"/leg_24.env "$D"/session.txt
```
- **期望形状**：`same=yes`。**现取 before ＝ `NO`**（`leg23=a2de5ff2b667f33f` ≠ `leg24=a131ea4e6f5cc4f5`）⇒ **before 这一格本来就是红的**，after 必须变 `yes`。

### C8 **`FailFast` 位点**面：该位点**不再被执行**（且 `FailFast` 本体没被改）
- **objective**：靶点是 `FontFamily.cs:336` 那条断言**不再达成**；而 `Invariant.FailFast` 的全局语义**未被动过**。
- **acceptance**：① 腿日志里 `grep -c 'Invariant.FailFast'` ＝ **0** 且 `grep -c 'Unrecoverable system error.'` ＝ **0**；② `Invariant.Linux.cs`／`Invariant.cs` 的**语义**未被改成 no-op（现取 `git diff --numstat` 逐件给出，**若这两件被改，必须逐行说明改了什么、为什么仍"真的终止"**）；③ **若**修法是"把断言换成降级"，必须给出**同一位置**的**新**具名行为（C4 那行）与**旧**行为（`Assert`）的成对说明。
- **取哪个字段**：腿日志两处计数；`git diff --numstat` 对 `Invariant*` 两件；载体里的成对说明。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D="${1:-build/MilBridge/tests/PtsPagesProbe/evidence}"; echo "failfast=$(grep -c 'Invariant.FailFast' "$D"/app_g1.log) unrec=$(grep -c 'Unrecoverable system error.' "$D"/app_g1.log)"; git diff --numstat -- build/WindowsBase.Linux/Invariant.Linux.cs upstream/wpf/src/Microsoft.DotNet.Wpf/src/Shared/MS/Internal/Invariant.cs; echo "numstat_rc=$?"
```
- **期望形状**：两个计数都 ＝ **0**；`Invariant*` 两件 **`numstat` 为空**（未改）或**逐行申报**。
  ⚠️ **反过读**：**计数为 0 不等于"降级发生"** —— 必须与 C4/C5 合读。

### C9 **两极化必须成对存在**（缺一即作废）
- **objective**：修法在**两极**都被证明（不是只有"不崩"）。
- **acceptance**：同一趟读数里 **a)** 受控**不存在**族 ⇒ 降级 ＋ `alive=yes`；**b)** 受控**存在**族 ⇒ **不降级** ＋ 正常（`fallback=no`）；**c)** **反腿**（副本文档）：把降级实现换成"永远降级/永远返回占位" ⇒ **b 腿必红并点名**。
- **取哪个字段**：见 C5；c 的判词与点名。
- **verify**：见 §5（本条的 verify 就是 §5 的三条命令）。
- **期望形状**：a 绿、b 绿、c 红**并点名**。**缺 c ⇒ 本条不成立**（"反腿未红或红而不点名 ⇒ 判不成立"）。

### C10 **正向族怎么选**（写死，防"随手挑一个能过的族"）
- **objective**：b 腿的"存在族"必须是**受控、可复算、与本机无关地命名**的族，不许挑"恰好通过的那个"。
- **acceptance**：b 腿的族名**同时**满足：① 它在**引擎集合里**可解析（由 C4 那行的 `resolved=` 本人证明，**不许**用 `fc-match` 当证据）；② 它的**选取依据**由实现件写死并给出（例如 provider 偏好序里的族，`DefaultFontFamily.cs` 的 `PreferredFamilies` 现取为 `Noto Sans`／`DejaVu Sans`／`Liberation Sans`）；③ a 腿的"不存在族"必须是**不依赖本机状态**的构造名（例如一个带明确不该存在后缀的合成名），并给出"本机确实没有"的现取读数。
- **取哪个字段**：两个族名 ＋ `resolved=` ＋ a 腿族名的机器可验证不存在性读数。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && fc-list : family | tr ',' '\n' | sed 's/^ *//' | LC_ALL=C sort -u | grep -ci '^<a 腿族名的正则>'; fc-list : family | tr ',' '\n' | sed 's/^ *//' | LC_ALL=C sort -u | grep -ci '^Noto Sans$'
```
- **期望形状**：第一个 **＝ 0**；第二个 **≥ 1**（示例族）。

---

## §5 ⑤ 两极化（**缺一即作废**）＋ 反腿

**总则（写死）**：**反腿未红、或红而不点名 ⇒ 该条判不成立**；**反腿必须在副本文档上跑**（副本落 `/tmp` 或仓外），`git status --porcelain` 不得出现被改的仓内件。

| 腿 | 构造 | 必绿/必红 | 取哪个字段 | **点名要求** |
|---|---|---|---|---|
| **a（负极）** | 请求一个**受控的不存在族**（合成名；C10 给出"本机 0 命中"读数） | **必绿**：`alive=yes`、`fallback=yes`、有 C4 诊断行、且页级现象落在**degraded 态**（`magenta ≥ 20000` 或"占位＋具名行"自洽） | `leg_*.env` 的 `LEG alive`；C4 行 `requested=/fallback=`；守卫 `PTS_GUARD=` | 若 `fallback=no` 或进程死 ⇒ **红并点名**（`reason=fallback-not-taken` / `reason=process-abort`） |
| **b（正极）** | 请求一个**受控的存在族**（C10 的三条约束） | **必绿**：`alive=yes`、`fallback=no`、**无**降级诊断行；现象落在 **realized 态**或**与"未降级"自洽**（`magenta=0 ∧ ink>0`，或与该装置口径一致的正常态） | 同上 + `ink`／`colors` | 若 `fallback=yes`（误降级）⇒ **红并点名**（`reason=spurious-fallback`），并给出 `resolved=` 里的实际族名 |
| **c（反腿）** | **副本文档**上把降级实现改成"**永远降级/永远返回占位**" | **必红**，且**由 b 腿红**（不是由 a 腿红） | b 腿的 `fallback=`／页级现象 | **必须点名 `reason=spurious-fallback`（或字段名等价物）＋ 指出"是 b 腿抓的"**；若 a、b **两腿都红** ⇒ 说明反腿把 a 也污染了 ⇒ **本条另判**（不许当"通过"） |

**判「假成功」的两条必红（与 §3 对齐）**：
- **P-静默**：只把 `FailFast` 换成 `return`／吞掉 ⇒ **a 腿** `fallback=` 恒 `no` 或诊断行缺失 ⇒ **必红**。
- **P-恒定**：降级实现"永远降级" ⇒ **b 腿**必红（就是 c 的那一形态，只是成因不同）。

---

## §6 ⑥ 假进度必红 P1–P8

| # | 假形式 | 正腿（必绿） | 反腿（**必红并点名**） | 必红点（字段/token 二者之一） |
|---|---|---|---|---|
| **P1** | **只把 `FailFast` 改成静默 return**（吞错不降级） | 真实现 ⇒ C4 有诊断行且 `fallback` 二值可读 | 副本上把断言换成空 `return`／`return null` 族 ⇒ **a 腿**必红 | 缺 C4 诊断行 或 `fallback` 字段缺席 ⇒ 红（`reason=silent-swallow` 或字段名等价物） |
| **P2** | **只改计数/仪表**（改声明件、调 `MAGENTA_FLOOR`、改 guard 阈值） | 真实现 ⇒ C6 的 `rc=0` 且**两态自洽** | 副本上把地板从 `20000` 调低／把 `fails` 白名单化 ⇒ 必红 | 守卫件的门限/判据位与 before **逐字相同**；不同 ⇒ 红（`reason=criteria-relaxed`） |
| **P3** | **症状列不派生**（`magenta`／`ink` 与日志口径对不上） | C6 的三列与 C4 的诊断行**同一趟、同一腿** | 只改 `.env` 的 `magenta` 而不改日志 ⇒ 必红 | `.env` 与原始日志**两条口径交叉核**不一致 ⇒ 红（`reason=symptom-not-derived`） |
| **P4** | **跨趟拼读数** | C7 的 `same=yes` | 拿**上一代** `leg_23.env`（现取 `shim=a2de5ff2b667f33f` 那份）配本趟 `.so` ⇒ 必红 | `disk/leg23/leg24/session` 四值不等 ⇒ 红（`reason=cross-run-pairing`） |
| **P5** | **🔴 观测镜环容量假设未重验**（`t110` 实测教训，**本件现取原话**） | 自检/夹具的**环容量假设**与"链上真实 push 条数"同趟对拍 | 让链**多 push 一条**（或把 `WPF_PTS_JMP_MAX` 调小）而**不改夹具的复原次序** ⇒ 夹具必红 | `win32_pts.c:1700-1707` 现取逐字：「修前 `CreateDocContext` 是 stub ⇒ 它**不 push**，链一共只 push 3 条（环 `WPF_PTS_JMP_MAX=4` ⇒ 放得下）；本步它变成真实现 ⇒ 链 push 4 条 ⇒ **环刚好写满**，格 6 夹具自己那两条 push 就会把**它要找的那条覆盖掉**」（该趟 `diag=86`）⇒ 红并点名"环容量/次序"那一格 |
| **P6** | **恒绿自检没有牙** | 自检能证伪（P1/P5 的副本） | 把自检改成恒 `return 1`／恒 `diag=0` ⇒ **三档探针判词全同** ⇒ 必红 | 正极/负极/边界三档的 `rc`／`diag` **完全相同** ⇒ 红 |
| **P7** | **拿"没崩"当降级证据** | C4＋C5 成对给两态 | 只在 a 腿跑、b 腿缺 ⇒ 必红 | 缺 b 腿或其 `fallback=no` ⇒ 红（`reason=no-positive-polarity`） |
| **P8** | **改生成件而不改生成器**（M2／M8 的静默回退） | 重跑生成器后生成物与改后内容**逐字节相同** | 只改生成物、下次生成即回退 ⇒ 必红 | 生成器（M3／M9）与生成物的内容一致性读数 ⇒ 不一致 ⇒ 红（`reason=generator-drift`） |

---

## §7 ⑦ 纪律第 `30` 条（在册）对本判据的硬约束

**在册确认（现取，本件自己取）**：`build/MilBridge/HANDOFF-NEXT.md` 在册块头 `:611`（内容锚「dated 纪律追加 · 第 `30` 条（**进程内状态敏感仪器**的调用史约束）」，**行号仅本次有效**），口径句 `:614`；在位自检命令现跑 `grep -c '进程新鲜[度]' build/MilBridge/HANDOFF-NEXT.md` ⇒ **`3`**（≥1）。

**本判据的硬约束（写死）**
1. **凡引用自检/探针/镜像/`live` 读数（含 C4 的诊断行、P5 的环、P6 的自检），同趟必须给三格**：① **进程新鲜度**（fresh 进程，**或**同进程＋**已发生的关键调用序**，逐条列出：建过几个上下文/罚分模块、是否调过 `CreateDocContext`／`DestroyDocContext`、是否走过字体解析）② **关键前置量**（该读数依赖的那些计数/`live`/环占用数的**当时值**）③ **判词**（`rc`／`diag`）。**缺任一格 ⇒ 该读数不许当证据。**
2. **正腿必须在 fresh 进程里跑**；带历史腿**必须独立进程**且历史逐条可复现。
3. **两种误导形态（写清）**：
   - **带历史的红 ＝ 假红**：同一 `.so` 在 fresh 与带历史两种前置下判词不同，成因是**调用序**（本仓现成机制见 P5：链 push 条数变了）。
   - **🔴 本族的「fresh 的绿 ＝ 假绿」＝「净腿不崩就以为修好了」**：**崩进程类缺陷**上，`alive=yes` 是**最廉价**的绿 —— 把 `FailFast` 删掉、把断言换成 `return`、把页面整页画成占位，三种做法**都能让净腿不崩**。⇒ **本判据把这一条升为必要条款**：**凡以"净腿不崩"为唯一证据的断言，必须再给一条"能让它变红的前置/反腿"**（＝ §5 的 **c** 与 **b**），否则该断言的绿**不算证据**（对应 P7 判红）。
4. **第三格之外再加一格（本族特有）**：**凡涉及"降级/未降级"的读数，必须标明它的取值源**（日志诊断行／`.env` 症状列／源码阅读**三选一**）。**不写源 ⇒ 该判定不许当证据**（W8 第三步那趟 `F-1` 的教训：多缺口态下"名字"会指错人，**定名必须只认一个源**）。

---

## §8 ⑧ `NOINFO` 预期（**此刻必然拿不到**；逐条给"消掉需要什么证据"）

1. **该 Run 实际请求的族名**：`NOINFO(reason=需运行期读数；本件只读，且崩溃在"解析不到"之后，日志不留请求名)`. **消掉需要**：实现件让失败路径打**一行含请求名**的诊断（C4 的字段）；**判据不依赖它**（两极化用**受控族名**承载，见 C9／C10）。
2. **腿进程的 `WPF_LINUX_UI_FONT`／`WPF_LINUX_FONT_DIR` 实际值**：`NOINFO(reason=读不到腿进程 environ；本件不跑腿)`. **消掉需要**：实现件在腿日志里打这两格（**按 PID** 读 `/proc/<pid>/environ`，禁 `pgrep -f`）。
3. **引擎集合里到底索引到哪些族**：`NOINFO(reason=需跑进程；`LinuxFontCollection` 的索引只在进程内)`. **消掉需要**：`Factory.SystemFontDirectoryDiagnostics`（`PresentationCore.Factory.Linux.cs:248-263` 现取有该诊断串）在腿日志里落一行。
4. **`#ARIAL` 是本趟**唯一**的破点还是另有破点**：`NOINFO(reason=本件只能证"②必假"（源码＋本机读数），证不了"①是这一次的成因")`. **消掉需要**：同时拿到"请求名"与"集合索引"两格（上两条）后即可判定。
5. **`k=23` 在**本趟**的表现**：`NOINFO(reason=本趟 `clicks=[24,23]`，k=24 先跑且当场死 ⇒ k=23 未跑，`leg_23.env` 是上一代旧件)`. **消掉需要**：修后**重跑一趟**（且取证时确认两条腿 `mtime` 同趟，见 C7）。
6. **`ns=…PracticalDemo` 的成因**（为什么崩溃时窗口还停在 PracticalDemo 而栈里是 `FlowDocumentFormatter`）：`NOINFO(reason=需运行期读数；可能＝"新页测量先于导航提交"，本件分不开)`. **消掉需要**：实现件在导航与测量两处各打一格（或用 `HC_GEO_EVERY` 的现成读数交叉）。
7. **`Invariant` 的**精确**调用者集合**（本仓还有多少条 1 参 `Invariant.Assert` 会在别的族上炸）：`NOINFO(reason=本件未做全树普查；只证了本族的位点)`. **消掉需要**：一次全树 `Invariant.Assert(` 的 1 参/2 参分类普查（可复算命令可写进后续判据）。
8. **`DIRECTWRITE 三工程缺口的机制**（M6／M7 改了两个指纹都不动）**：`NOINFO(reason=覆盖面事实已现取，机制未定)`. **消掉需要**：主控裁定是否把 `build/DirectWrite.Linux/**` 纳入任一覆盖面（**本件只登记缺口，不主张扩面**）。
9. **`MAGENTA_FLOOR` 的门禁注入值**：本件现取到**缺省** `20000`（`pts-pages-guard.sh:75`）；**门禁实际注入值未取** ⇒ `NOINFO(reason=未跑整趟门禁)`. **消掉需要**：跑腿者给出同趟该变量现值。

---

## §9 ⑨ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-fontstack-fallback-criteria.md`（新建；UTF-8；模式 **644**；**首记号不是 `# ⏪ `**；末行自带可复算自报口径）。
- **只读**：本件全部命令为 `grep`／`sed`／`awk`／`tr`／`cat`／`od`／`nm`／`fc-list`／`fc-match`／`sha256sum`／`wc`／`stat`／`env`／`git log`／`git status`／`git diff`／`git ls-files` ＋ 三个**纯读**件（`pts-pages-guard.sh --legs`（判据端只读）／`artifact-src-fp.py`（`--list`／无参，**不 `--write`**）／`close-wave.sh` 的 `fp_inputs()`（**抽出到 `/tmp` 后只跑 `cat` 支**，**不改仓内件**））。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
  ⚠️ **仓外只读**：为定位"该 Run 请求的族名"曾对**第三方安装**做窄范围**只读** `grep`（`~/hc-linux/src/Shared/HandyControlDemo_Shared/**`），**未写入、未运行**；其读数在 §2.2 逐条标注为"仓外现取"。
- **未改任何其它件**：`git status --porcelain` 原样 ——
```
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log
?? src/tests/
```
  ⇒ **两项全属他人**（`arm_A` 未跟踪件、`src/tests/`）；**本件是本次唯一新增件**。
- **未引既有报告当证据**：`W60A-report.md`／`P1-w8-step4-report.md` 等**读数一条未抄**（本件所有数字均由本趟命令现取，命令已逐条写在 §1.4／§2／§4）；`docs/ROUTES.md:193` 只作"该栈**在册**"的**位置指针**（**不读其数字**）。§1.2 的"1 参 Assert"判定是**我自己**从 `od -c` 的字节事实 ＋ `Invariant.Linux.cs` 的拼接源码推出来的，**不是**转述。
- **末行自报口径当场可复算**：见末行。

---

### 结语（自包含）

- **① 域定位（结论）**：`FontFamily.get_FirstFontFamily`／`get_LineSpacing` 的实现在 **`upstream/wpf/…/PresentationCore/System/Windows/Media/FontFamily.cs:311-347`／`:235`**（**无 `.Linux.cs` 覆盖**）；`Invariant.FailFast` 在 **`build/WindowsBase.Linux/Invariant.Linux.cs`**（生成件；编进 `WindowsBase.Linux.csproj:72`）。**FailFast 位点机读确定 ＝ `FontFamily.cs:336` 的 1 参 `Invariant.Assert`**（依据：日志两行 `Unrecoverable system error.` **无消息后缀** ⇒ 1 参重载；该法体内**唯一**就是这一条 1 参断言）。**触发条件 ＝ 请求族解析不到 ∧ 空字体 `#ARIAL` 解析不到**，而后者在本机**必然**失败（`fc-list` 无 Arial＝0；provider 回退的名字闸只认 4 个系统复合字体名，`FamilyCollection.Linux.cs:1736`＋`:1537`）。**拟改件清单 M1–M11 见 §1.4**，其中 **M1／M2／M8 不在 `fp_inputs()`（234 件）但在 `ARTIFACT-SRC-FP`（PC 1374／WB 327）**，**M6／M7 两个覆盖面都不在（残留缺口，如实登记）**，**M3／M9 生成器在 `fp_inputs()` 里**。
- **② 现取复现面**：`fc-list=414`／族串 233／`^arial`=0／`DejaVu Sans` 在；`fc-match Arial` 只是**替换**；**台账 `PTS_GAP`＝0／`PTS-UNAVAILABLE`＝0**；崩溃栈在 `:799-808`；`APP_RC=134`；`k24.png colors=1`；守卫 **`rc=1`** 并四条 `fails` 全点名 `leg24-*`；**两条腿跨代**（`leg23 shim=a2de5ff2b667f33f` vs `leg24 shim=a131ea4e6f5cc4f5`，`clicks=[24,23]` 导致 k=23 未跑）。
- **③ 诚实边界**：「崩得少一点不是证据、`alive=yes` 也不是证据」；证据是**与该输入绑定、可被独立读取的降级判定**（请求名／是否降级／落到谁）**＋ 正向腿不许误降级**；**假成功**三条（静默吞错、永远降级、只改仪表）逐条必红；**非目标**（不改 `FailFast` 全局语义、不实现全部匹配语义、不动第三方、不顺手扩覆盖面）。
- **④ 判据 C1–C10**：构建／导出面（不靠加导出收尾）／**两页都要有本趟读数**／**降级可判**／**正向不误降级（两态可区分）**／两页症状（`magenta`／`ink`／`colors`／`ns` 各自落态，禁"空白读绿"）／**同趟性（守卫没有这条牙，判据自带）**／`FailFast` 位点不再执行／两极化成对／正向族怎么选。
- **⑤ 两极化 a/b/c ＋ 反腿**：**a** 受控不存在族 ⇒ 必降级且活；**b** 受控存在族 ⇒ 必不降级；**c** 副本上"永远降级" ⇒ **必由 b 腿红并点名**。**缺一即作废**；**反腿在副本文档上跑**。
- **⑥ 假进度必红 P1–P8**：含**只把 `FailFast` 改静默**（P1）、**只改计数/仪表**（P2）、**症状列不派生**（P3）、**跨趟拼读数**（P4）、**`t110` 的环容量教训**（P5，原话已现取）、**恒绿自检**（P6）、**拿"没崩"当降级证据**（P7）、**改生成件不改生成器**（P8）。
- **⑦ 纪律第 `30` 条**：三格 ＋ 调用序 ＋ 两种误导形态；**并把"净腿不崩就以为修好了"升为必要条款**（崩进程族的 `fresh 的绿＝假绿`）；另加"降级判定必须标明取值源"。
- **⑧ `NOINFO` 9 条**，各带"消掉需要什么证据"。
`P1-FONTSTACK-FALLBACK-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 1f5f79d9f3a41971（口径＝末行之前的全文；末行＝本行）`

---

## ⏪ `t116` dated 追加 —— `t115` 余项关账（`F-1` 直接读数落进装置 ＋ `F-2` 行数口径 ＋ `O-1` ／ `O-3` ／ `O-4` 口径）（读时 `2026-09-29T03:2x+0800`；上方原文**一字未删**，本段**只加行**）

### `F-1`（low，主项）—— **按（甲）**：把「位点不再执行」变成**装置输出里的直接读数**

- **做了什么（只加行，既有行一字未动）**：`build/MilBridge/tests/PtsPagesProbe/session_inner.sh` 在 `CLICK` 行之后、`PHASE` 行之前**新增一行机读**：
  `FAILLINE k=<k> failfast=<n> unrec=<n> src=app_g<gi>.log:FailFast|Unrecoverable`；
  `build/MilBridge/tests/PtsPagesProbe/legs-to-env.py` 把它**带进 `leg_<k>.env` 的第四段**（既有三段 `LEG`／`NAMED`／`DEV` 字段**一个不动**）。
- **口径（逐字）**：**`failfast=`** ＝ 该腿**原始 app 日志**里 **`FailFast`** 字样的**行数**（.NET `Environment.FailFast` 的失败位点标记；来源行＝`$GLOG`，即 `app_g<gi>.log`）；**`unrec=`** ＝ 同日志里 **`Unrecoverable system error`** 的**行数**（**与既有 `fatal=` 同源同量 ⇒ 两者逐字等价**；保留 `fatal=` 只为不破坏既有读法）。**判「`FailFast` 位点这次有没有执行」看 `failfast=`**；`alive=yes`／`ink>0`／崩溃栈消失**只是辅证**，**不得**再冒充直接读数。
- **可判性成对读数（本席现取；仓外夹具，**不跑应用**）**：① **修前**：在册证据里 `grep -oE 'failfast=[0-9]+|unrec=[0-9]+' evidence/**` ⇒ **0 命中**（只有 `session.txt` 的 `fatal=0` ×2）⇒ 该对读数**无载体**；② **修后**：用**同源 `cnt`/`$GLOG` 干跑该 printf** ⇒ 无标记时 `failfast=0 unrec=0`、日志里注入两行标记后 ⇒ **`failfast=1 unrec=1`**（**计数器有响应**，不是常量）；③ **转换器**（仓外夹具 session ＋ 空 `app_g1.log`）⇒ `leg_24.env` 出现 `FAILLINE k=24 failfast=0 unrec=0 src=app_g1.log:FailFast|Unrecoverable`，而 `LEG`／`NAMED`／`DEV` 三段**逐字同形**；④ **反兼容**：旧格式 session（删掉该行）⇒ 两格给 **`-`（＝"没测到"，不是 0**；与 `ink=` 同一约定）。
- **装置仍工作（不跑腿的可判证明）**：守卫 `pts-pages-guard.sh` 对装置件**零引用**（现取 `grep -c 'session_inner\|legs-to-env' tools/pts-pages-guard.sh` ＝ **0**）⇒ `--legs` 的判词**与装置改动无关**（对同一目录结果不变）；`bash -n session_inner.sh` 与 Python 语法编译**均过**；**新行只落在 `CLICK`–`PHASE` 之间**，而转换器的 region token 扫描**按既有规则自动带走**（未新增解析器、未改锚）。
- **代价如实记**：装置件在覆盖面内 ⇒ 本件同趟追写 `cell=#1`；**未**跑腿（派单禁）⇒ "整趟腿仍工作"这一格**只有**上面三条**间接**证明（零引用／语法／夹具往返），**没有**一整趟真腿的端到端读数 —— 该格记 **`NOINFO(未跑腿)`**。

### `F-2`（low）—— 生成器自报行数与生成件实际行数**差 33**：口径差，**不是**内容差
- **现取（我自读＋自算）**：生成器 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py` 印的是 `[断言] 上游 N 行 → 生成物 **2202** 行` ＝ **`len(out.splitlines())`（正文 `out`）**；而**写盘**的是 **`output = HEADER + out`**（同一函数里紧接的下一句）⇒ 落盘件＝ `build/PresentationCore.Linux/FamilyCollection.Linux.cs` ＝ **2235** 行（我现取 `wc -l`）。**我自算 `HEADER` 的行数 ＝ 33** ⇒ **`2235 = 2202 + 33`**（差**恰为**头注释块）。
- ⇒ **口径（逐字）**：该自报数**是"正文行数"、不是"整件行数"**；整件行数 ＝ 正文 ＋ `HEADER`（今天 `HEADER` ＝ 33 行）。**两者都不参与 `identical` 判定**（后者比的是**整件字节**）。
- ⚠️ **本件不改生成器**（`src/**` 不在写域）⇒ 只把口径写进册；**若**后人要把自报改成整件口径，那是 `src/**` 的改写 ⇒ 另派单（且须同趟跑 `--check` 复验 `identical`）。

### `O-1`（观察，必落册）—— **`form=unnamed` 不是「具名前进」的证据**
- **现取**：在册证据 `entry=unknown` ＝ **0**、`[PTS-UNAVAILABLE]` ＝ **0** ⇒ 托管具名面**整趟为空** ⇒ 守卫只能给 `PTS_G10_NAME=PASS **form=unnamed** reason=frontier-unnamed`。
- **口径（逐字）**：**`form=unnamed` 只说"没有具名行可判、形态判据按其形态通过"**，**不**是"具名前进"。**"具名前进"的证据面**是 **`PTSGAP`／台账**（`^PTS_GAP entry=` 行与 `PTSGAP_FRONTIER` 的 `before`→`after` 名更换）；两者**是两件事**，**禁止**互相折算。⚠️ 本趟**正是**"具名面为空 + 台账面 0 行"的态（第四步已把靶心 `CreateDocContext` 做真 ⇒ 该站的具名行**不再出现**）⇒ 该态**不是**"具名倒退"，也**不是**"具名前进"。

### `O-3`（观察）—— c 反腿（「永远降级」）的仪器级执法位今天空 ⇒ **按（乙）改成证据面判据**
- **现状（现取）**：副本级反腿仍 `NOINFO` ⇒ 该条**仪器级**执法位**今天空**；现实中只能靠"同趟两态并存 ＋ 直方图 `fallback=no=7 > fallback=yes=4`"作替代。
- **本件处置＝（乙）**（只落判据，不实现仪器）：把 `C9` 的 c 格**改成证据面可判形式** —— **要求同一趟读数里同时出现两种方言**：
  ① **`requested=<受控不存在族> … fallback=yes`**（≥1 条）；② **`requested=<受控存在族> … fallback=no`**（≥1 条）。
  ⇒ **判"永远降级"**：若只有 ①、没有 ② ⇒ **必红并点名**（"两态分不开：疑似永远降级"）；若只有 ②、没有 ① ⇒ 也**必红**。
- ⚠️ **口径只收到"今天可达"的边界（如实记）**：我现取的三元组直方图是 `requested=DEJAVU fallback=no resolved=none`×3／`requested=ARIAL fallback=yes resolved=none`×2／`requested=GEORGIA fallback=no resolved=none`×1 ⇒ **`resolved=` 今天恒 `none`** ⇒ 所以本格**不要求** `resolved=<该族自身>`：**那样会造出一条今天永不可能绿的判据**（本仓禁此）。⇒ 本格压在两轴上：**`requested=`（点名受控族）＋ `fallback=`（两方言并存）**。**若将来** `resolved=` 真携带解析结果，**可**把要求收紧到 `resolved=<该族自身>`（记为**未来项**，非本件）。
- **（甲）路线的代价（只写要求、不实现）**：要给出**可构建副本或旁路开关**（把"永远降级"做成第二个产物代）⇒ 触及 `src/**` ＋ 构建/跑腿 ⇒ **另派单**；本件不实现。

### `O-4`（观察）—— `ink=` 的口径**写死**（它是"非占位、非底色"的像素数，**不是**深色像素数）
- **现取（我自读 `shotstat.py` ＋ 自算复验）**：`ink = W×H − magenta − dominant`，其中 `dominant` ＝ 该图**出现次数最多的单色**的像素数（页底/背景的代理），`ink<0 ⇒ 0`；**定义无阈值**。复验（在册 `shots/g1/k24.png`，1280×1024）：`shotstat.py` ⇒ `ink=480000`；**我按同式自算** ⇒ `480000 = 1310720 − 0 − 830720` ✓（**可复算**）。
- **与 PNG 像素统计的关系（逐字）**：`colors=`／`magenta=` 是**可逐位复算**的量；`ink=` 是**粗代理**——复核者自量的"深色像素" **871/840070 量级**（阈值不同：他 837862、我按"三通道和 < 384"得 840070）**不是同一个量**（一图一值、依赖"众数色"假设）。
- **口径（逐字）**：`ink=` **只可作"这页是不是纯空白"的粗证**（守卫的 `realized` 期只要求 `magenta==0 ∧ ink>0`）；**不得**用它做任何**阈值/比例/逐位**断言，也**不得**与 `magenta`／`colors` 并列当"同等可复算"。**本件不改 `shotstat.py`**（它已把口径写在注释里；我把它**抬进判据册**以免后人误读）。
`P1-FONTSTACK-FALLBACK-CRITERIA dated 追加后自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 1646ab12fee8ab65（口径＝末行不计入自身取值；原自证行系**追加前**全文值，原样保留）
---

## ⏪ `t118` dated 追加 —— **`realized` 期的四条新判据 `N1–N4` ＋ 截图同趟自证要件**（读时 `2026-09-29T03:4x–04:0x+0800`；上方原文**一字未删**，本段**只加行**）

> **为什么加在本件**：本件的 `C5`/`C6`/`C9` 就是「两页是否真排版」的判据面；`t117` 现取证明**今天那三条绿条件（`magenta=0` ∧ 无具名行 ∧ `ink>0`）＋ `native_gap=0` 会一起成立，而画面仍是 demo 的「敬请期待」空态页** ⇒ 相位翻转前必须把「画出了内容」这件事**变成有区分力的读数**。⇒ 下面四条是**相位翻转的硬前置**（裁定二十一的 ②/③）。

### `N1` **`ink>0` 没有区分力 ⇒ 改为「帧身份 ＋ 帧位移」双要件**
- **objective**：把 `realized` 期的"画出了内容"从**粗代理**升级为**有区分力**的读数。
- **acceptance**：① **帧身份**：该页帧 `sha256`（前16）**∉ 登记的空态参照集**；② **帧位移**：`AE(boot,该页帧) > 0` **且**每次点击后 `AE(上一帧,本帧) > 0`（除非命中 `N3` 同貌例外）；③ **`ink>0` 降级为"必要不充分"**（保留但**不再单独**满足本条）。
- **verify（单行）**：`D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; python3 build/MilBridge/tests/PtsPagesProbe/shotstat.py "$D"/shots/g1/{boot,k23,k24}.png; compare -metric AE "$D"/shots/g1/boot.png "$D"/shots/g1/k24.png null:`
- **取哪个字段／期望形状**：`sha256` 前16／`colors,magenta,ink`／`AE` 整数。**期望**：帧 `sha256` ∉ 空态参照集（今天参照集 ＝ `{ef3fd6765f18f51b}`；`boot` ＝ `b21eb530afd3c66c`）、`AE(boot,k24) > 0`（今天 **15386** ⇒ 该项**单独不够**）。
- **现取依据**：`shotstat` 四帧 `ink` **全为 480000**（`boot` `colors=386`；`k23`＝`k24`＝`last` `colors=383`）⇒ 既有 `ink -gt 0` **恒真**。
- ⚠️ **边界**：本条只对**已登记的空态参照**有分辨力（空态换版须同趟重登记）；`AE` 是**像素位移**，不是"内容对不对"。

### `N2` **运行期 ENFE 必须留痕（按入口名过滤）**
- **objective**：`EntryPointNotFoundException` 被吞后账面必须看得见，否则相位翻转会把"异常被吞"判成"排版成功"。
- **acceptance**：① 证据必须能现算 `ENFE_TOTAL=<n>` 与 `ENFE_BY_NAME=<名>:<n>,…`（**按入口名**）；② **`ENFE_TOTAL>0` 时判据面不得给"排版成功"的绿**，除非该批入口名被**显式列入本步非目标清单**（逐名可核）；③ **归因按入口名过滤**（不得按计数/均值归因）。
- **verify（单行）**：`D=build/MilBridge/tests/PtsPagesProbe/evidence; grep -c 'Unable to find an entry point named' "$D"/app_g1.log; grep -o "entry point named '[A-Za-z0-9_]*'" "$D"/app_g1.log | sed "s/.*named '//;s/'$//" | LC_ALL=C sort | uniq -c | sort -rn`
- **取哪个字段／期望形状**：`ENFE_TOTAL` ＋ 按名直方图；**期望** `ENFE_TOTAL` 与**非目标 allowlist** 差集为 **0**。**现取：1081**（**1080×`FsCreatePageBottomless` ＋ 1×`FsCreatePageFinite`**）⇒ 若此刻翻相位，本条**必红**。
- **接线提示**：`N2` 的**执行位在守卫**（`build/MilBridge/tools/**`，非本件写域）⇒ 本件只落判据与 verify 单行；守卫侧接线**另派单**。

### `N3` **两页帧相同 ⇒ 对照腿判据**
- **objective**：判开 `leg23-AE=0` 的两种语义（（i）两页本来同貌 /（ii）第 23 页没重绘）。
- **acceptance**：**对照腿**（同一趟、`clicks=[23,24]`）必须给出：① 两腿各自帧 `sha256`；② **两帧必须不同**；**若相同** ⇒ 必须给出「两页确实同貌」的证据（两页 `ns=` 指向**同一 UI 且该 UI 无页别差异**），否则判**（ii）没重绘 ⇒ 红**；③ 每次点击后 `AE>0`（同上例外）。
- **verify（单行）**：`D=<对照腿目录>; sha256sum "$D"/shots/g1/k23.png "$D"/shots/g1/k24.png | awk '{print $1}' | LC_ALL=C sort -u | wc -l; compare -metric AE "$D"/shots/g1/k23.png "$D"/shots/g1/k24.png null:; grep -E '^LEG k=2[34]' "$D"/leg_2[34].env`
- **取哪个字段／期望形状**：`sha256` 去重计数（**期望 2**）／`AE`（**期望 >0**）／两条 `LEG` 的 `ae`。**现取：去重计数 ＝ 1、`AE(k23,k24)` ＝ 0** ⇒ 本条**今天红**。
- **补充**：把 `AE=0` 从**诊断**（守卫现取 `diags+=leg$k-AE=0(点击前后无像素差)`）升为**本条下的判据项**（红/例外二选一）。

### `N4` **内容身份**（`ns=` **不承担**它）
- **objective**：证明"画面是该页**自己的内容**"，不是应用的空态页。
- **acceptance**：① **负身份**（今天可达）＝ `N1①` 的帧身份；② **正身份**（今天**无载体**）＝ 该页**专属**期望指纹（登记一次已知良好渲染的帧 `sha256`，或该页专属结构读数如 `TabControl` 的 tab 数）；③ **`ns=` 不得单独**承担内容身份；④ 在 ② 落地前，本条记 **`NOINFO(无正身份载体)`**，**不得折绿**。
- **verify（单行）**：`D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; grep -E '^LEG k=24' "$D"/leg_24.env; grep -ci 'neptune' "$D"/app_g1.log`
- **现取依据**：三帧 `sha256` 同值，且画面是 demo 的「敬请期待」空态页（`~/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Main/UnderConstruction.xaml:16` 的 `LangKeys.ComingSoon` 那一格）；`grep -ci 'neptune'` ＝ **0**；而 `leg_24.env` 的 `ns=…FlowDocumentDemo` ⇒ **`ns=` 与空态画面同时成立**（`t110` 反例）⇒ `ns=` 只证"加载了那个类型"。

### 截图类证据的**同趟自证**（**通用要件**；照 `C7` 的做法）
- **要件（逐字）**：**凡以截图为承重件**，必须同时给出 **①** 截图 `sha256`（前16）；**②** 该截图与所引读数**同趟**的证明（引**同趟字段**：`DEV` 行的 `shim=`／`pf=`、`session.txt` 的 `ts`、或该趟 `POSTSHIM`）；**③** 该截图的 `shotstat` **现读**与 `leg_*.env` 的 `colors`／`magenta`／`ink` **逐格相等**。**缺任一 ⇒ 截图只作辅助件，不得单独承重**。
- **verify（单行）**：`D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; python3 build/MilBridge/tests/PtsPagesProbe/shotstat.py "$D"/shots/g1/k24.png; grep -E '^LEG k=24' "$D"/leg_24.env; grep -E '^DEV ' "$D"/leg_24.env`
- **实例（`t117` 登记，本席如实转记）**：`02:48` 那趟 `session.txt`／`leg_24.env` 写 `colors=1 magenta=0 ink=0`，而仓库内 `k24.png` 现取（03:5x 复量）＝ **383 色**且与 03:14 那趟**逐字节相同** ⇒ 该趟截图**与其 env 不同趟** ⇒ **只作辅助**。**今天**三者一致（`shotstat` 383 ＝ `leg_24.env colors=383` ＝ `session.txt` 帧行 383）⇒ 在册截图**满足本条** ✓。
`P1-FONTSTACK-FALLBACK-CRITERIA dated 追加后自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 862166d879740fe0（口径＝末行不计入自身取值；原自证行系**追加前**全文值，原样保留）
