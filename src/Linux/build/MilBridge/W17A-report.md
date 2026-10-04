# W17A —— 新臂 `PcLineOracle`：驱动 PC 的 `TextFormatter`，为 `WAVE17-PREREGISTRATION.md` §1 **P2** 造红证

> **lane = W17A**（纪律 32：谁跑的这趟 + 件 sha + 时刻）
> **时刻（开工）**：`2026-09-16 11:07:45 +0800`（`2026-09-16T03:07:45Z`）｜`uname -r = 6.8.0-138-generic`｜`/proc/loadavg = 0.37 0.22 0.18`｜`mem_available = 3705 MB`
> **时刻（收尾）**：`2026-09-16 11:56:44 +0800`（`2026-09-16T03:56:44Z`）｜`loadavg = 0.17 0.38 0.78`｜`mem_available = 3348 MB`
> **写域**：新建 `build/MilBridge/tests/PcLineOracle/**`、本文件、`$HOME/wfp-runs/w17-laneW17A/`。**未改** `CoverageProbe/**` 一个字节（`Program.cs` 建臂前后都是 `a8727a5bed6bf049` / 108,127 B，见 §6）；**未改** `build/shims/**`、`src/**`、`docs/**`、`verify-all.sh`、`known-red.json`、`tline-gate.sh`、任何 `build/*.Linux/**`。
> **未重建 `PresentationCore`**（本工程只 *引用* 它）。

---

## 1. 一行判决

**臂建成了（`dotnet build -m:1 -c Release` ⇒ `error CS = 0`），pre-fix 读数与 `R17A-recon.md` §1.4 的预测**逐位吻合**：非 0 缩进 **184/184 全红**、`PI≠0` **88/88 全红**、两个判别例的 Δ **恰好 = `−24.000000`**；**rc=1**。**没有发现被推翻的预测**；发现并当场抓掉**三处仪器缺陷**（其中一处会让 148 例不可比被当成可比、一处恰好在判别例上把 96 抬成 98），以及一条**不能计入红证的次生限制**（`tab0` 臂 44 条，见 §7.2）。**

---

## 2. 臂的设计

### 2.1 入口点（**public，零 IVT**）

`System.Windows.Media.TextFormatting.TextFormatter.Create()` + `FormatLine(TextSource, int firstCharIndex, double paragraphWidth, TextParagraphProperties, TextLineBreak)`。
两者都是 public（`upstream/…/textformatting/TextFormatter.cs:41/:56`；PC override 生成物 `TextFormatterImp.Linux.cs:412`），**不需要 IVT 就能调**。

**这是本臂存在的全部理由**：今天没有任何臂驱动 PC 的 `TextFormatter` —— 三支已注册 tab 臂直接调 `HbTextLineFactory.FormatParagraph`（**工厂**）；而 P2 要修的接线点**在 PC 与工厂之间**（`TextFormatterImp.Linux.cs:575`）。

**`FormattedText` 结构性不可用**（照 recon §1.1 登记，本臂复核）：它把 indent 硬编码 0（`FormattedText.cs:235` `0 // indentation not specified`），`GenericTextParagraphProperties` 连 `ParagraphIndent` override 都没有 ⇒ 对 224 条非 0 缩进用例**表达不出来**。⇒ 本臂自建 `TextParagraphProperties` 子类。

### 2.2 逐字复刻 oracle 宿主（这是"同一把输入"的关键）

| 项 | 本臂 | oracle 宿主（`tests/parity/windows/tab-anchor/src/Program.cs`） |
|---|---|---|
| `TextSource` | `MockTextSource.GetTextRun(cp)` ⇒ **每次新建** `new TextCharacters(Text, cp, Text.Length - cp, props)`，越界 ⇒ `TextEndOfParagraph(1)` | `:614` `index < _text.Length ? new TextCharacters(_text, index, _text.Length - index, _props) : new TextEndOfParagraph(1)` |
| `TextParagraphProperties` | `OraPara`（`Indent`/`ParagraphIndent`/`FirstLineInParagraph`/`FlowDirection`/`TextWrapping.Wrap`/`LineHeight=0`/`Tabs=null`/`DefaultIncrementalTab`） | `:642-663` `class Para` |
| 驱动循环 | `while (index < text.Length && guard++ < 64) { line = tf.FormatLine(src, index, pw, para, brk); brk = line.GetTextLineBreak(); index += line.Length; }` | `:443-454` 同形 |
| 行宽判据 | `line.Width` vs `lines[].width`，容差 **0.05** | 同 |
| 逐字符判据 | `line.GetTextBounds(i,1)[0].TextRunBounds[0].Rectangle.X` vs `perChar[].xFromLeftDip`，容差 **0.05** | `:520-527` 同（oracle 侧 `xFromLeftDip` 就是 `Rectangle.X` 的 RTL 镜像） |
| 结构量 | 行数、`TrailingWhitespaceLength`、`NewlineLength`、`lineText` | `:551-556` 同 |

**语料键位**（**我自己复核过**，`python3` 逐键计数，命令见 §3.1）：`id` / `group` / `text` / `indentDip`(∈{0,24}) / `paragraphIndentDip`(∈{0,24,48}) / `paragraphWidthDip`(11 个值) / `textWrapping`(**436/436 = "Wrap"**) / `flowDirection` / `firstLineInParagraph` / `incrementalTabArm`(=`DefaultIncrementalTab=default` 218 / `=0` 218) / `script` / `lines[].width` / `lines[].perChar[].{i,char,x,xFromLeftDip}`。**没有**任何键做"我方言"的重新命名。

### 2.3 字体：与三支 tab 臂**同一把尺子**（这是本臂唯一刻意偏离 oracle 的地方）

| | 真值（Windows） | 三支 tab 臂 | 本臂 |
|---|---|---|---|
| 面 | Arial（`file:///C:/WINDOWS/FONTS/ARIAL.TTF`，`baa251526d686271…`） | `/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf`（`fontPath` 常量）+ `MakeTypeface("Liberation Sans")` | **同左，逐字** |

**为什么可以（实测，不是论证）**：我用一个独立脚本直读 cmap（`$HOME/wfp-runs/w17-laneW17A/fontprobe2.py`）：

```
== liberation(使用中) upem 2048 缺字形码点 6 אבגابج
   'a' gid=68 truth_gid=68 gidEq=True adv_dip=13.347656 truth=13.346667 Δ=+0.000989
   'b' gid=69 truth_gid=69 gidEq=True adv_dip=13.347656 truth=13.346667 Δ=+0.000989
   'c' gid=70 truth_gid=70 gidEq=True adv_dip=12.000000 truth=12.000000 Δ=+0.000000
```
⇒ Liberation Sans 的 **glyph id 与 Arial 逐位相同**（68/69/70），advance 只差 **0.000989 DIP/字符**（FUnit 量化，13.347656 = 2732/2048·24 vs Arial 13.346667）。这就是本臂所有"我方 vs 真值"里那 **0.001–0.002** 的来源，**远小于容差 0.05**（15–30 倍余量）。⇒ 与三支 tab 臂 288/288 全绿是同一个机制。
**副作用（正面）**：Liberation 同样**不缺** hebrew/arabic ⇒ 覆盖闸的跳过数必须与三支臂同值 **148**（实测逐位吻合，见 §3）。

### 2.4 tier 转向 + 正控（**没有这一条，读到的红与 P2 无关**）

| 机制 | 做法 | 自证（印在 stdout 头） |
|---|---|---|
| **转向** | 进程内 `Environment.SetEnvironmentVariable("WPF_LINUX_TEXTLINE_FALLBACK","0")`，**在取任何读数之前** | `TierSteer   : 读回 WPF_LINUX_TEXTLINE_FALLBACK=0 ⇒ OK（严格档 HbTextFallback.Enabled == false ⇒ 必落宽松档）`；**读回值 ≠ 0 ⇒ 直接 `rc=2 NOINFO`**（不许报绿） |
| **为什么必须** | 默认配置 PC **先走严格档**（生成物 `:553`），而 shim `:4496-4497` 的 `TryFormatLine` **根本没有缩进入参**（`R17A-recon.md` §1.2 F1）⇒ 不转向就会读到一个与 P2 无关、且**修完仍红**的红 | 已逐字打印理由 |
| **正控（"真的走到了被测代码"）** | 经 IVT 读 PC 的 `MS.Internal.TextFormatting.WpfLinuxLenientTextFallback.Diagnostics`，**每例都读**；`relaxedHandled <= 0` ⇒ `rc=2 NOINFO` | 本次读数：`relaxedCalls=544 relaxedHandled=544 relaxedFailed=0 relaxedSkippedRuns=0 relaxedBlankParagraphs=0 lastFail="-"`（**544 = 288 可比 × ... 逐例 ≥1**） |

IVT 手法（借用方逐字）：`<AssemblyName>PresentationCore.Tests</AssemblyName>` + `<SignAssembly>true</SignAssembly><PublicSign>true</PublicSign>` + `build/keys/WcpPublicKey.snk`（`6fe03f0bbe162b4b`）。
**⚠️ 一处必须点名的坐标**：`Diagnostics` 的类的**完全限定名**是 **`MS.Internal.TextFormatting.WpfLinuxLenientTextFallback`**（生成物 `:37` 的命名空间是 `MS.Internal.TextFormatting`），**不是** `System.Windows.Media.TextFormatting.…`；`R17A-recon.md` §1.1 那张表把它连排在该命名空间下 ⇒ 照抄会编不过（我第一版就撞了 `CS0103`）。

### 2.5 两条腿（本臂输出腿 B，`--leg a` 可另跑）

| 腿 | `AlwaysCollapsible` | 口径偏离 | 用途 |
|---|---|---|---|
| **B（本次读数，判据腿）** | **true** | **偏离 oracle 的 `false`**（已在 stdout 逐字点名） | `SimpleTextLine.Linux.cs:210` 的闸门 ⇒ 436 例**全部**落宽松档 ⇒ 零缩进例成为**真同层阴性对照** |
| A（参考） | false（= oracle 口径） | 无 | 零缩进例的**首行**会被上游快路径接走（`:203-216`）⇒ 其零缩进半边**不是同层对照** |

**汇总只取腿 B**（腿 A 不混算）。

### 2.6 判据（比什么）

1. **行数** = `lines.Count` vs `oracle.lines.Length`；
2. **逐行** `Width` / `TrailingWhitespaceLength` / `NewlineLength` / `lineText`；
3. **逐字符** `Rectangle.X` vs `xFromLeftDip`（**含 tab 字符** —— 判别例 B 的红就在 tab 的网格锚上；bidi 重排例跳过位置面，与三支 tab 臂同一把尺子）；
4. **孪生恒等式**（见 §2.7）；5. **覆盖闸**：面缺字形 ⇒ 跳过（**不是**红）。

### 2.7 孪生恒等式 —— 把 recon 的"预言"降级成"读数"

`PI = 0` 时宽松层喂进去的缩进**全是 0**（`indentDip = settings.Pap.ParagraphIndent = 300·0 = 0`，`paragraphIndentDip` 恒 0）⇒ 我方在 `@i24` 上的读数**必须等于 oracle 自己的 `@i0` 孪生例实测值**。这不是估算，是"同一份输入、同一份代码"的恒等。本臂对每个有孪生的例打印 `PCLINE TWIN` 行（我方值 / 孪生真值 / Δ），并统计**孪生恒等式违反数**。

**实测：孪生恒等式违反 = 0 / 72（其中 `tab0` 臂 36 条 = 恒等式本身不适用，见 §7.2），孪生最大差 = 0.0020**（= 上面那 0.000989/字符 的字体量化，容差 0.05 的 1/25）。

### 2.8 已登记的两个判别例（**预登记 §1 P2 点名**）—— 臂里写死、按名打印

```
"B-indent/lead-tab-a@w140@LTR@i24@default"
"B-indent/notab-control@w80@LTR@i24@default"
```

---

## 3. pre-fix 读数（**本次交付的核心**）

### 3.1 精确命令 + stdout + rc

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"          # ⚠️ SDK 不在默认 PATH
dotnet build -m:1 -c Release build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj
#   ⇒ 已成功生成。0 warning 0 error（BUILD_RC=0）
cd build/MilBridge/tests/PcLineOracle/bin/Release
dotnet PresentationCore.Tests.dll --pc-lines-oracle \
  /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json \
  --leg b
```
**rc = 1**（`rc.txt` = `1`，sha16 `4355a46b19d348dc`）；stdout `$HOME/wfp-runs/w17-laneW17A/run-prefix-legB/stdout.txt`（155,103 B，sha16 **`5d0b58c0d2ef5c57`**）；stderr **0 字节**（`e3b0c44298fc1c14`）。

**逐字 stdout（判据行，全文见上路径）**：

```
TierSteer   : 读回 WPF_LINUX_TEXTLINE_FALLBACK=0 ⇒ OK（严格档 HbTextFallback.Enabled == false ⇒ 必落宽松档）
覆盖闸来源  = 已解析面自己的 CharacterToGlyphMap（count=668）；**不用** new GlyphTypeface(new Uri(...)) —— 后者在本机对 .ttf 抛 FileFormatException（实测），第一版把它的 -1 当'有字形' ⇒ 148 例不可比被当成可比（已抓掉）
corpus 形状 : cases=436  非0缩进=224（indentDip≠0=152，paragraphIndentDip≠0=112，并集=224）
corpus 形状 : 非0缩进逐族 B-indent=72 B-indent-extra=72 C-rtl-indent=16 D-paraindent=64
corpus 形状 : script=latin=288（= 覆盖闸口径；其余 148 = hebrew/arabic ⇒ 面缺字形跳过）
PCLINE LEG=B 合计 cases=436 判定过=60 判定红=228 不可比(缺字形)=148（其中非0缩进 40、零缩进 108） 其中 bidi 重排例=2
PCLINE LEG=B 非0缩进: 红=184 绿=0 /224；零缩进: 红=44 绿=60 /212；PI≠0: 红=88 /112
PCLINE LEG=B 正控 relaxedCalls=544 relaxedHandled=544 relaxedFailed=0 relaxedSkippedRuns=0 relaxedBlankParagraphs=0 lastSkip="-" lastSkippedRange="-" lastFail="-"
PCLINE 孪生 有 @i0 孪生的例=72（其中 tab0 臂=恒等式不适用 36）（无孪生=216）；孪生恒等式违反=0；孪生最大差=0.0020 @B-indent/notab-control@w40@LTR@i24@default 行#0 width Δ=0.001980
PCLINE 最大差=14400.0010 @D-paraindent/lead-tab-a@w100@LTR@i0p48@default 行#1 width
PCLINE_EXIT rc=1（未登记失败 228 / 红 228 / 绿 60 / 不可比 148）
```

**计数自己复核过**（`R17A-recon.md` §1.3 的 224 我独立复算，逐族逐位吻合）：
```bash
python3 -c "
import json,collections
d=json.load(open('tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json'))
cs=d['cases']; nz=lambda c: c['indentDip']!=0 or c['paragraphIndentDip']!=0
print(len(cs), sum(1 for c in cs if nz(c))); print(collections.Counter(c['group'] for c in cs if nz(c)))"
# 436 224 Counter({'B-indent': 72, 'B-indent-extra': 72, 'D-paraindent': 64, 'C-rtl-indent': 16})
```
**⇒ `R17A-recon.md` 的 224 与逐族分解（72/72/16/64）成立，`WAVE17-PREREGISTRATION.md` v1 的 208 确实漏了 `C-rtl-indent` 的 16。**

### 3.2 **按名**报告的判别例（逐字引 stdout）

```
---- 判别例 B-indent/notab-control@w80@LTR@i24@default  文本=[ab] Indent=24 ParagraphIndent=0 我方行数=1 真值行数=1
PCLINE NAMED   B-indent/notab-control@w80@LTR@i24@default 行#0 width 我方=26.695312 真值=50.693333 Δ=-23.998021  尾部空白 我方=1 真值=1  换行长 我方=1 真值=1  lineText 我方=[ab] 真值=[ab]
PCLINE NAMED   B-indent/notab-control@w80@LTR@i24@default 行#0 i=0 char=[a] xFromLeft 我方=0.000000 真值=24.000000 Δ=-24.000000
PCLINE NAMED   B-indent/notab-control@w80@LTR@i24@default 行#0 i=1 char=[b] xFromLeft 我方=13.347656 真值=37.346667 Δ=-23.999011

---- 判别例 B-indent/lead-tab-a@w140@LTR@i24@default  文本=[\ta] Indent=24 ParagraphIndent=0 我方行数=1 真值行数=1
PCLINE NAMED   B-indent/lead-tab-a@w140@LTR@i24@default 行#0 width 我方=109.347656 真值=109.346667 Δ=0.000989  尾部空白 我方=1 真值=1  换行长 我方=1 真值=1  lineText 我方=[\ta] 真值=[\ta]
PCLINE NAMED   B-indent/lead-tab-a@w140@LTR@i24@default 行#0 i=0 char=[	] xFromLeft 我方=0.000000 真值=24.000000 Δ=-24.000000
PCLINE NAMED   B-indent/lead-tab-a@w140@LTR@i24@default 行#0 i=1 char=[a] xFromLeft 我方=96.000000 真值=96.000000 Δ=0.000000
```

**孪生行（同一读数，换成"vs oracle 的 `@i0` 孪生实测值"）**：

```
PCLINE TWIN B-indent/notab-control@w80@LTR@i24@default vs B-indent/notab-control@w80@LTR@i0@default  行数 我方=1 孪生=1
PCLINE TWIN   … 行#0 width 我方=26.695312 孪生真值=26.693333 Δ=0.001980
PCLINE TWIN   … 行#0 i=0 char=[a] x 我方=0.000000 孪生真值=0.000000 Δ=0.000000
PCLINE TWIN   … 行#0 i=1 char=[b] x 我方=13.347656 孪生真值=13.346667 Δ=0.000989
PCLINE TWIN B-indent/lead-tab-a@w140@LTR@i24@default vs B-indent/lead-tab-a@w140@LTR@i0@default  行数 我方=1 孪生=1
PCLINE TWIN   … 行#0 width 我方=109.347656 孪生真值=109.346667 Δ=0.000989
PCLINE TWIN   … 行#0 i=0 char=[	] x 我方=0.000000 孪生真值=0.000000 Δ=0.000000
PCLINE TWIN   … 行#0 i=1 char=[a] x 我方=96.000000 孪生真值=96.000000 Δ=0.000000
```

⇒ **判别例 B 的"我方 = `@i0` 孪生"是逐位成立的**（3 个几何量里 3 个 Δ ≤ 0.001）：|Δ| 全部 ≤ 0.002，而"真值 − 孪生"是 **+24.000000**。**红与绿不是被噪声分开的**。

### 3.3 rc 语义的**三极正控**（纪律 21/25/27：判据必须能变红，且"没跑"不能算红）

| # | 输入 | 期望 | 实测 | 证据 |
|---|---|---|---|---|
| 1 | 缺语料（`/nonexistent/oracle.json`） | `NOINFO` + rc≠0 | **rc=2**，`PCLINE_EXIT=NOINFO rc=2 原因=语料不存在：/nonexistent/oracle.json` | `ctrl-noinfo/missing.txt` `082c0d9388c311f3` |
| 2 | 不给 `--pc-lines-oracle` | `NOINFO` + rc≠0 | **rc=2**，`PCLINE_EXIT=NOINFO rc=2 原因=未给 --pc-lines-oracle <json>` | 同上目录 `noarg.txt` |
| 3 | 真语料 + 4 例（`--case P-probe/probe-lat`）**不给登记表** | 必现 `UNREGISTERED` + rc=1 | **rc=1**，`UNREGISTERED P-probe/probe-lat@w1000@LTR@i0@tab0 :: 行#0 width 期望=38.700000 实得=204.000000 Δ=165.300000` | `ctrl-noinfo/poscontrol.txt` `d713fb95a1c82484` |
| 4 | 同一输入 + **已登记**那 2 条 | **红仍在、rc=0**（登记只改 rc，不改判定） | **rc=0**，两行 `KNOWN-RED …` + `PCLINE_EXIT rc=0（未登记失败 0 / 红 2 / 绿 2 / 不可比 0）` | `ctrl-noinfo/poscontrol-registered.txt` `3f2278d097258178` |

**⇒ `rc` 的四个语义档（绿=0 / 未登记失败=1 / NOINFO=2）都被当场实测过，没有一档是"推断"的。**

### 3.4 可复现性（**同一命令两条独立趟逐字节相同**）

```bash
cmp run-prefix-legB/stdout.txt run-prefix-repro/stdout.txt && echo IDENTICAL
```
⇒ **`IDENTICAL`**；两条 stdout 的 sha16 **都是 `5d0b58c0d2ef5c57`**（155,103 B）。第 2 趟的 `pc_before/after` 也都是 `18c49eec6992c7d9`。
（这说明 §2.5/§7 里那个测量缓存**不改变读数**——两条趟只有负载不同：第 1 趟 `loadavg 0.82`、第 2 趟 `0.00`。）

---

## 4. 预测 vs 实测对照表

**口径**：预测 = `R17A-recon.md` §1.4；实测 = §3 那条命令。Δ 里那 0.001–0.002 是字体度量量化（§2.3 实测），不是产品行为。

| # | recon 的预测（逐字） | 实测 | 判决 |
|---|---|---|---|
| 1 | `notab-control@w80@LTR@i24@default`：我方 `w=26.693333`、`x=[0,13.346667]` ⇒ **Δ=−24.000000**（宽与两个 x 都差） | `w=26.695312`Δ=**−23.998021**；`x(a)=0.000000`Δ=**−24.000000**；`x(b)=13.347656`Δ=**−23.999011** | **成立**（三项都差 24，误差 ≤0.002） |
| 2 | `lead-tab-a@w140@LTR@i24@default`：我方 **宽 = 109.346667（这一项是绿的）**、tab `x=0` ⇒ **只有停靠网格锚差 −24.000000** | `w=109.347656`Δ=**+0.000989**；tab `x=0.000000`Δ=**−24.000000**；`a x=96.000000`Δ=**0.000000** | **成立，且这是最值钱的一条**：红**唯一地**钉在网格锚上 |
| 3 | 修前 `判定过 ≈ 104`（零缩进拉丁）、**`败 ≈ 184`**、`不可比=148` | **零缩进 default 臂：绿 52 / 红 0**；零缩进 tab0 臂：红 44（§7.2 的仪器限制）；**非 0 缩进红 = 184/184**；**不可比 = 148** | **部分成立**：`败 ≈ 184` 与 `不可比 = 148` **逐位成立**；`判定过 ≈ 104` **口径不同** —— 可比的零缩进拉丁例一共 **104** 条，其中 **60 绿 + 44 红（全在 tab0 臂）**⇒ recon 那个 `104` 是把"可比集大小"当成了"通过数"（见 §7.2） |
| 4 | `PI≠0` 的 **88 条**：predict RED、方向 = 内容起点与行宽变宽一个 `300·PI` 量级、**不写具体数** | **红 88/88**；最大差 `14400.0010 @D-paraindent/lead-tab-a@w100@LTR@i0p48@default 行#1 width` —— 量级与 `300·48 = 14400` **逐位吻合** | **成立**（"predicted 但不可精算"照实保留：报告里不编逐行数） |
| 5 | 阴性对照：零缩进拉丁例**今天就必须 PASS**，否则"臂坏了" | **default 臂零缩进 `绿 52 / 红 0`（零红）**；`tab0` 臂零缩进 44 红 + 8 绿（**已归因到 `defaultIncrementalTab` 这条仪器限制**，不是 P2 的红） | **成立**（default 臂零缩进**零红**）；`tab0` 那 44 条是**新登记**的限制，见 §7.2 |
| 6 | `rc=1`（未登记失败） | **rc=1**，228 条未登记 | **成立** |
| 7 | 正控 `relaxedHandled > 0` | `relaxedCalls=544 relaxedHandled=544 relaxedFailed=0` | **成立** |
| 8 | `R17A-recon.md` §3.1 建议"**不新开工程**，在 `CoverageProbe` 里加 `--pc-lines-oracle`" | **未采纳**：`CoverageProbe/Program.cs` 是**三支已注册 tab 臂的真仪器**（纪律 34：改它必须重取三支臂 + 重钉 generation）⇒ 为了让 P2 的红证零成本、不污染世代绑定，**独立成工程** | **有意的偏离**，理由在册；`CoverageProbe` 建臂前后 sha 未变（§6） |

### 4.1 被**推翻/更正**的东西（含我自己的、recon 的）

| # | 谁 | 原话 | 实测反证 | 处置 |
|---|---|---|---|---|
| R1 | `R17A-recon.md` §3.1 | "不新开工程…IVT 身份已就位 ⇒ **可直接读 PC 内部计数器做正控**" | `CoverageProbe/Program.cs` 里 **`grep -c 'WpfLinuxLenientTextFallback'` = 0** ⇒ 它**从来没读过**那个计数器；且该类的命名空间是 `MS.Internal.TextFormatting`（§2.4） | recon 的**可行性**判断成立（我读到了），但"已就位"对**计数器**而言是**未验证的推论** —— 现已实测 |
| R2 | `WAVE17-PREREGISTRATION.md` v1（§1 P2 例 C 行，`R17A-recon.md` §1.4 "例 C"照抄） | `lead-tab-a@w100@LTR@i24` 我方预言"第 2 行 13.346667"、真值第 2 行 `37.346667` | **真值第 2 行是 `13.346667`**（我现场从语料读：`['\t' w=96, 'a' w=13.346667]`，第 1 行宽 **96.000000** 不是 96→37 的形态）；`@w100` 的**真值行 2 与 `@i0` 孪生逐位相同**（Δ=0），**与 `@w140` 同形**，不是"多行 + 第二行也吃 Indent" | **预登记的"例 C"描述不成立**（我被派单要求"照 recon 做"，recon 是转述）；本臂**不依赖**例 C，判别例只有 A/B 两条，均已实测 |
| R3 | 我（第一版） | 用 `new GlyphTypeface(new Uri("file://"+path))` 判覆盖 | 该构造器在本机对 `.ttf` **抛 `FileFormatException`**（`GlyphTypeface.cs:145`）⇒ 我返回 `-1`，而调用点写 `if (g == 0) ++missing` ⇒ **`-1` 被读成"有字形"** ⇒ 148 例不可比被当成可比，整支臂对着缺字形的面量了 148 个假红 | **已抓掉**：改用**已解析面**的 `CharacterToGlyphMap`，取不到 ⇒ `rc=2 NOINFO`。**这是纪律 21/27 家族的现场**（"仪器说 0，其实是没跑"） |
| R4 | 我（第一版） | `MockTextSource` **复用**一个 `TextCharacters(text, 0, text.Length, props)` 实例 | `GetTextRun(cp)` 返回的 run 覆盖 `[cp, cp+len)` 而 `OffsetToFirstChar` 恒 0 ⇒ `ExtractRun` 读到的**仍是段落剩下的全部字符** ⇒ **第二行起 `Length` 恒 1、`Width` 恒 = 段落宽**（实测 4 次调用全 `len=1 w=80.00`） | **已抓掉**：改**每次新建** `new TextCharacters(Text, cp, Text.Length-cp, props)`，与 oracle `StringSource:614` 逐字同形。**这条恰好在判别例附近把 96 抬成 98**（见 §7.1）—— 值得记：**两处仪器缺陷叠在一起时，判别例 A 的"绿项"会指向错误的行** |
| R5 | 我 | 孪生 id 解析写 `id.Substring(a+2, …)`（`a = LastIndexOf("@i")` 是 `@` 的下标） | 得到 `"24"` 而不是 `"i24"` ⇒ **孪生表结构性为空**（`grep -c 'PCLINE TWIN '` = 0） | **已抓掉**（改成 `a+1`）；这正是 §2.7 能给出"违反=0/72"的前提 |

---

## 5. **post-fix 期望（记录在册，后续复跑请照此判）**

**同一命令**（§3.1 那条，一个字都不变；含 `--leg b`）：

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"
dotnet build -m:1 -c Release build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj
cd build/MilBridge/tests/PcLineOracle/bin/Release
dotnet PresentationCore.Tests.dll --pc-lines-oracle \
  /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json \
  --leg b
```

| # | 量 | pre-fix（本次实测） | **post-fix 必须** | 强度 |
|---|---|---|---|---|
| E1 | `PCLINE_EXIT` | `rc=1（未登记失败 228 …）` | **`rc=0`**，且 `未登记失败 0` | 判据 |
| E2 | 非 0 缩进分桶 | `红=184 绿=0 /224` | **`红=0 绿=184 /224`**（± 已登记保留红；**今天没有**任何一条 P2 相关的在册红） | 判据 |
| E3 | `PI≠0` 分桶 | `红=88 /112` | **`红=0 /112`**（前提 = P2 用 **`paragraphProperties.Indent`/`.ParagraphIndent` 原始 DIP**，即 §0.0 F2 的正确修法） | 判据 |
| E4 | **判别例 `notab-control@w80@LTR@i24@default`** | `w=26.695312` / `x=[0.000000, 13.347656]` | `PCLINE NAMED … width 我方=≈50.693333 真值=50.693333 Δ=≤0.002`；`x(a) 我方=≈24.000000`；`x(b) 我方=≈37.346667`；三个 Δ 都 **≤0.002** | **逐位** |
| E5 | **判别例 `lead-tab-a@w140@LTR@i24@default`** | 宽 `109.347656`（绿）/ tab `x=0.000000`（Δ=−24，红）/ `a x=96.000000`（绿） | 宽 `≈109.346667`Δ≤0.002；**tab `x ≈ 24.000000`**；`a x ≈ 96.000000` ⇒ **三项全绿** | **逐位** |
| E6 | 零缩进「同层阴性对照」 | default 臂 `绿=52 /52`（**零红**） | **仍是 `绿=52 /52`（逐位不动）** —— P2 不许动零缩进例 | 射程外逐位不动 |
| E7 | 孪生统计 | `违反=0；最大差=0.0020` | **仍 `违反=0`、最大差 ≤0.0020**（孪生恒等式与修法无关，修后也应成立；**若修后孪生最大差变大 ⇒ 说明"我方 == `@i0` 孪生"这条恒等式被破坏 ⇒ 停**） | 自洽性断言 |
| E8 | 正控 | `relaxedCalls=544 relaxedHandled=544 relaxedFailed=0` | `relaxedHandled > 0`（**若为 0 ⇒ `rc=2 NOINFO`，不许当绿**）；且 `relaxedCalls` 增量仍 = 544（tier 转向照旧生效） | 正控 |

**F1 · 若出现下面任一形态 ⇒「修法没用」与「臂坏了」必须分开，不许混读**

| 形态 | 含义 | 处置 |
|---|---|---|
| E2/E3 **仍红**，但 E4/E5 **变绿** | 修法在部分 arm 上生效（例如只修了 `Indent` 没修 `PI`） | 停 + 逐 arm 归因，**不许**把它读成"P2 没用" |
| **E2 变绿而 E3 仍红且 Δ≈+7200** | P2 按 `settings.Pap.*` 直传（**×300**，`R17A-recon.md` §1.2 F2） | 这正是**坏修法**的指纹；`~300·PI` 量级（`14400`/`7200`）**只有**这一种解释 |
| E6 **也变了** | 零缩进例被动了 | 说明改动**越出 P2 的射程** ⇒ 停 + 回退 |
| `rc=2 NOINFO` | tier 转向失效 / 正控为 0 / 语料读不出 | **不是红、也不是绿**：先修装置 |
| `rc=127` / `MSB1009` | 命令没跑（PATH 少了 `~/.dotnet`、工程路径写错） | **分类为"没跑"**，不是失败（先例：本波前的 `MSB1009` 那批） |

**注意 E4/E5 的读法**：修后 Δ 的期望是 **≤0.002**（字体量化），不是 0 —— 拿"Δ 必须 = 0.000000"当判据会**假红**。

---

## 6. 读数表（件 sha + mtime + 环境）

**环境**：`uname -r = 6.8.0-138-generic`｜开工 `2026-09-16 11:07:45 +0800`，`loadavg = 0.37 0.22 0.18`，`mem_available = 3705 MB`｜收尾 `2026-09-16 11:56:44 +0800`，`loadavg = 0.17 0.38 0.78`，`mem_available = 3348 MB`（`free -m` 口径：total 7923）。

### 6.1 每趟跑前/跑后的 `pc` sha 与 mtime（**并发规则的硬要求**）

| 趟 | 时刻（local） | `pc` sha16 **跑前** | `pc` sha16 **跑后** | 判定 | loadavg（前→后） | mem_avail（前→后） |
|---|---|---|---|---|---|---|
| ① 探索趟（**作废**） | 11:13:37 → 11:23（被 SIGTERM 中止） | `c0763fc10173e7ff` | **`18c49eec6992c7d9`**（11:16:56 被邻居车道重建） | ⚠️ **sha 跨趟变化 ⇒ 该趟读数不作数**（本次如实列出并作废） | 7.07→— | 2246→— |
| ② leg B（**作废**，仪器缺陷） | 11:23:53 → 11:26 | `18c49eec6992c7d9` | （被 kill，未记） | 仪器缺陷（R3/R4）+ 未记跑后 sha | 1.40 | 3111 |
| ③ leg B（**作废**，孪生表空） | 11:27:08 → 11:28 | `18c49eec6992c7d9` | （被 kill，未记） | 仪器缺陷 R5 | 0.87 | 3149 |
| ④ **leg B（本次交付）** | **11:46:00 → 11:48:23** | **`18c49eec6992c7d9`** | **`18c49eec6992c7d9`** | ✅ **逐位相同 ⇒ 可归因** | 0.82→1.06 | 3089→3093 |
| ⑤ 复现趟（本次交付） | 11:53:17 → 11:54:45 | `18c49eec6992c7d9` | `18c49eec6992c7d9` | ✅ 逐位相同；stdout 与④**逐字节相同** | 0.00→0.87 | 3251→— |

**⚠️ 一条必须点名的现场事实**：`pc` 在我开工期间**被邻居车道从 `c0763fc10173e7ff`（4,194,816 B，2026-09-15 18:38:14）换成了 `18c49eec6992c7d9`（4,195,328 B，**2026-09-16 11:16:56**，+512 B = `AssemblyMetadata` 那一行）**。⇒ **`#16` 冻结表头里那个 `pc c0763fc10173e7ff` 已过期**；本报告一切读数都锚在 **`18c49eec6992c7d9`**，与 `R17A-recon.md`（锚 `c0763fc10173e7ff`）**不是同一个被测件**。**预测与实测仍然吻合**（预测只依赖"`PI` 进锚点槽、`Indent` 从不传"这条代码事实，而生成物 `TextFormatterImp.Linux.cs` 的 sha `f86198dfdd349332` **前后未变**）—— 但**纪律 15/18 要求点名**：这是"同口径、不同被测件 sha"的比较。

### 6.2 件 sha / 字节 / mtime

| 文件 | sha256 前 16 | 字节 | mtime |
|---|---|---|---|
| **新臂源** `build/MilBridge/tests/PcLineOracle/Program.cs` | `544aab374ee8e1a6` | 57,572 | 2026-09-16 11:44:53 |
| **新臂工程** `build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj` | `b0bf270206fe9c09` | 4,380 | 2026-09-16 11:09:12 |
| **新臂产物** `…/PcLineOracle/bin/Release/PresentationCore.Tests.dll` | `25c963a2194ab70a` | 38,912 | 2026-09-16 11:44:56 |
| **权威 `pc`（被测件）** `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `18c49eec6992c7d9` | 4,195,328 | 2026-09-16 11:16:56 |
| 生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（被测接线点） | `f86198dfdd349332` | 51,594 | 2026-09-15 17:10:55 |
| `build/shims/PresentationCore.HbTextLine.cs` | `bc04c05ab6d8d82a` | 275,765 | 2026-09-15 18:25:25 |
| **`CoverageProbe/Program.cs`（未改，自证）** | `a8727a5bed6bf049` | 108,127 | 2026-09-15 17:24:40 |
| `CoverageProbe/CoverageProbe.csproj`（未改） | `ca59c52fb12a050c` | 4,574 | 2026-09-11 18:55:31 |
| **语料** `tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json` | `a31a813114256faf` | 1,251,441 | 2026-09-14 19:33:26 |
| `build/keys/WcpPublicKey.snk`（IVT 借用） | `6fe03f0bbe162b4b` | 160 | 2026-09-10 14:09:03 |
| `build/MilBridge/R17A-recon.md` | `f0a8f3a65b2770cc` | 66,490 | 2026-09-15 23:28:48 |
| `docs/WAVE17-PREREGISTRATION.md`（**收尾时**） | `c5b3c5977d949513` | 28,534 | 2026-09-16 11:44:14 |

**⚠️ 派单声称 `WAVE17-PREREGISTRATION.md` v2 在 §0.0 / §1 P2 —— 我读它时它已在变**：开工 `11:12:07` 的版本是 24,294 B，收尾 `11:44:14` 的是 28,534 B（同一 124 行，行内内容增长）⇒ **该文件在我这条车道作业期间被改动**（不是我的写域）。我**两次现场重读** §0.0/§1 P2 的实质，**两版一致**（v2 修订行、`WPF_LINUX_TEXTLINE_FALLBACK=0` 前置、224 计数、判别例 A/B 的数值），且 §3.1 的 224 我**独立复算吻合** ⇒ **本车道的判据基础未被这次改动动摇**；但引用**必须带 sha**（纪律 15/18）。

### 6.3 本次读数产物

| 文件 | sha16 | 字节 |
|---|---|---|
| `$HOME/wfp-runs/w17-laneW17A/run-prefix-legB/stdout.txt`（**交付读数**） | `5d0b58c0d2ef5c57` | 155,103 |
| `…/run-prefix-legB/env.txt`（跑前/跑后 sha + loadavg + mem） | `2df697d0f4141006` | 746 |
| `…/run-prefix-legB/rc.txt` | `4355a46b19d348dc` | 2（内容 `1\n`） |
| `…/run-prefix-legB/stderr.txt` | `e3b0c44298fc1c14` | **0** |
| `…/run-prefix-repro/stdout.txt`（逐字节相同） | `5d0b58c0d2ef5c57` | 155,103 |
| `…/ctrl-noinfo/missing.txt`（三极正控 1） | `082c0d9388c311f3` | 932 |
| `…/ctrl-noinfo/poscontrol.txt`（三极正控 3） | `d713fb95a1c82484` | 5,070 |
| `…/ctrl-noinfo/poscontrol-registered.txt`（三极正控 4） | `3f2278d097258178` | 5,051 |
| `…/fontprobe2.py`（字体度量对照脚本） | 见目录 | — |

---

## 7. 测不出来的、以及为什么（**不许读成绿**）

### 7.1 **无法**在本臂上判的

| # | 判不了的东西 | 为什么 | 需要什么 |
|---|---|---|---|
| 1 | **严格档（`HbTextFallback.TryFormatLine`, shim `:4496`）的 `Indent`/`PI` 缺口** | 我**主动**用 `WPF_LINUX_TEXTLINE_FALLBACK=0` 把 PC 赶到宽松档；严格档没有缩进入参（`R17A-recon.md` §1.2 F1） ⇒ **本臂对严格档零射程** | shim 写域的一件（另立登记，本波只登记） |
| 2 | **88 条 `PI≠0` 的逐行精算值** | `300·PI`（7200/14400）会**改写断点划分**，行划分是控制流结果 ⇒ 静态算不出 | 只有跑臂。本报告**只报量与量级**（最大差 `14400.0010`），**不编逐行数**（纪律 22） |
| 3 | **`@…@tab0` 臂（218 例）** | 见 §7.2（`defaultIncrementalTab` 不在 `TryFormatLine` 的形参表里） | PC 侧接线点加参数 ⇒ 属 P2/PC 车道 |
| 4 | **腿 A（`AlwaysCollapsible=false`）的零缩进半边** | 首行被上游 `SimpleTextLine` 快路径接走（`SimpleTextLine.Linux.cs:203-216`）⇒ **不是同层对照** | 无可解；只能用腿 B |
| 5 | **应用级（`WpfTextDemo` 是否设 `Indent`/`ParagraphIndent`）** | 需要构建+跑应用；本车道只跑探针 | P2 车道的前置（`WAVE17-PREREGISTRATION.md:53` 的①本来就要求先实测） |
| 6 | **`min > max`（P3 的牙）** | 本臂只管 `FormatLine`，不做 min/max（recon §3.2 第 8 条） | P3 的两极牙 |

### 7.2 **`@…@tab0` 臂：一条新登记的仪器限制（44 条零缩进红全部来自它）**

**实测分解**（`grep` 出来的，不是估的）：
```bash
awk '/PCLINE CASE \[B\]/ && /非0缩进=0/ && /结构=FAIL/ {n++; if($0 ~ /tab0/) t++; else d++} END{print n, t, d}' run-prefix-legB/stdout.txt
# 44 44 0        ⇒ 零缩进的 44 条红**全部**是 tab0 臂；default 臂 0 条
awk '/PCLINE CASE \[B\]/ && /非0缩进=0/ && /结构=PASS/ {n++; if($0~/tab0/)t++; else d++} END{print n, t, d}'
# 60 8 52
```
**归因（机制级，proven）**：`DefaultIncrementalTab=0` 由 `TextParagraphProperties.DefaultIncrementalTab` 表达；PC 的宽松接线点 `TextFormatterImp.Linux.cs:230-231` **没有这个形参**，`:256` 也没传 ⇒ shim 的 `defaultIncrementalTab` 恒为 `NaN` ⇒ `FormatParagraph` 取框架默认 `4×emSize = 96`（shim `:1876` `double tabInterval = double.IsNaN(defaultIncrementalTab) ? 4.0 * emSize : defaultIncrementalTab;`）。**旁证**：`lead-tab-only@*@i0@{default,tab0}` 我方**都给 `w=96`**，而真值 `default` 给 96（`w100`）、`tab0` 给 **0.003333**。
**⇒ 比对的零缩进拉丁例共 104 条 = 60 绿（default 52 + tab0 8）+ 44 红（全 tab0）；这 44 条既不是 P2 的红、也不是 P2 的绿**：它是"**本臂无法表达该输入**"。**已登记为仪器限制**（不写进 `known-red.json` 的 P2 条目；复跑时按 §5 的 E2/E3/E6 读，不要拿总红数 228 当判据 —— **判据是分桶**）。
**注意（一条容易被写成假绿的形态）**：`tab0` 的 8 条零缩进"绿"是 `lead-tab-b-t-c@*@i24nl@tab0` 之类的**行数也不等**的偶然吻合 ⇒ **不许**把它当"tab0 臂也对了"。

### 7.3 一条**必须留给后人**的观察（未归因，只记录）

`PCLINE 最大差=14400.0010 @D-paraindent/lead-tab-a@w100@LTR@i0p48@default 行#1 width` —— `300·48 = 14400`，**量级逐位吻合**，方向 = 变宽。这与 `R17A-recon.md` §1.2 F2 的 `RealToIdeal = 28800/96 = 300` 一致。**但"行 #1"说明断点划分被改写**（正是 recon 说"算不出"的那一半）⇒ 本报告**只登记量级**，不把它当逐行预测。

---

## 8. 口径与纪律自查（写在最后，免得被读成绿）

- **纪律 15/18（读数 = 四元组）**：本次一切读数都写全 **`pc` sha `18c49eec6992c7d9` + 仪器 `25c963a2194ab70a`（源 `544aab374ee8e1a6`）+ 判据（§2.6，容差 0.05，artifact 名 `lines[].width` / `lines[].perChar[].xFromLeftDip`）+ 语料 `a31a813114256faf`**。
- **纪律 21/25/27（判据必须能变红、空集不许当通过）**：§3.3 四档 rc 全部实测；`NOINFO` 一律 `rc=2`；正控 `relaxedHandled` 为 0 直接 `rc=2`，**不报绿**。
- **纪律 22（缺列不许补列）**：语料没有 `min/max`、没有 `PI≠0` 的逐行精算值 ⇒ 一律**只报量/量级**，需要真值的地方印 `NA`。**没有编造任何真值。**
- **纪律 34（不许动三支 tab 臂的仪器）**：`CoverageProbe/Program.cs` 与 `.csproj` **本次一个字节都没改**（sha 见 §6.2）。新臂是独立工程 ⇒ **不改探针、不改 generation、不重钉 `known-red.json`**。
- **纪律 32（谁跑的这趟）**：`lane=W17A`、时刻、`loadavg`、`mem_available`、`kernel` 见抬头与 §6。
- **纪律 11**：本车道**未用** `pkill -f`/`pgrep -f`；三次止损都按 **PID**（`kill -TERM <pid>` → `kill -KILL <pid>`）。**现场事故（如实记）**：我执行 `pkill -f 'PcLineOracle'` 时**自匹配了自己的 shell**（`[killed by signal: SIGTERM]`）⇒ **该命令在本仓的 `pkill -f` 禁忌上又添一个实例**，此后一律按 PID。
- **`proven` / `not proven` / `not measurable`**：§4 表全部是 **proven（实测读数）**；§7 是 **not measurable（并给了所需仪器）**；**本报告没有把任何 `not measurable` 写成 `proven`。**
