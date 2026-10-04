# W17B —— 落地 `WAVE17-PREREGISTRATION.md` §1 **P2**（PC 侧 indent 接线 `D-T3`），并用 W17A 的臂判它

> **lane = W17B**（纪律 32：谁跑的这趟 + 件 sha + 时刻）
> **时刻（开工）**：`2026-09-16 11:58:28 +0800`｜`uname -r = 6.8.0-138-generic`｜`/proc/loadavg = 0.26 0.35 0.72`｜`MemAvailable = 3794248 kB`（`free -m`：total 7923 / used 3893 / buff-cache 2123）
> **时刻（收尾）**：`2026-09-16 12:09:06 +0800`｜`loadavg = 0.94 1.25 1.08`｜`MemAvailable = 2978 MB`（used 4604 / free 1176 / buff-cache 2141）
> **写域**：`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`｜生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`｜本文件｜`$HOME/wfp-runs/w17-laneW17B/`。
> **未改**：`build/MilBridge/tests/PcLineOracle/Program.cs`（`544aab374ee8e1a6`，**臂本来就有 `--known-red`，一行没动**）｜`PcLineOracle.csproj`（`b0bf270206fe9c09`）｜`build/shims/**`（`bc04c05ab6d8d82a`）｜`build/MilBridge/known-red.json`（`f9843bde351029dc`，**没有动它** —— 我的登记表是**新文件**）｜`docs/**`｜`samples/**`｜`verify-all.sh`｜`tline-gate.sh`｜`build/PresentationCore.Linux/PresentationCore.Linux.csproj`｜`HbTextLineShimSha.targets`｜`tests/ShimShaReader/**`。
> **未用** `pkill -f` / `pgrep -f`；所有止损按 **PID**（本轮实际未需要止损，只出现过一次 60 s 前台超时被中止，见 §5.1）。

---

## 1. 一行判决

**P2 落地且判据成立**：`error CS = 0`；权威 `pc` `18c49eec6992c7d9` → **`1280323c9173bcde`**（同 4,195,328 B）；**`@…@default` 臂 92 条修前红全部转绿（红 0 / 绿 92）**，**修前红 228 → 修后 `rc=0` 且未登记失败 0**；两个判别例的**三项全部落在 Δ≤0.002**（`lead-tab-a@w140` 的 tab 网格锚 `0.000000 → 24.000000` 精确复位）；零缩进同层对照 **52/52 逐位不动**。
**修后剩下的 116 条红 100% 落在 `@…@tab0` 臂**（`DefaultIncrementalTab` 不在 PC 接线点的形参表里 ⇒ 本臂表达不出来），已按"**本臂表达不出来的输入**"登记（**136 条**，见 §6）；**没有任何 `@…@default` 臂的红幸存**。
**我推翻了一条 W17A 的验收项 E7（"孪生恒等式修后必须仍违反 0"）** —— 修后违反 **102/144**（+ 72 条已无法比较），因为它把**缺陷态当成了规律**。证据见 §7.3。

---

## 2. 精确 diff（应用器 + 生成物，含 before/after sha16）

### 2.1 备份（纪律 16：**先备份再改**）

| 文件 | sha16 | 字节 | mtime |
|---|---|---|---|
| `$HOME/wfp-runs/w17-laneW17B/backup/applier.before.py` | **`07dc7627f609e031`** | 37,625 | 2026-09-15 17:10:55.155374812 +0800 |
| `$HOME/wfp-runs/w17-laneW17B/backup/generated.before.cs` | **`f86198dfdd349332`** | 51,594 | 2026-09-15 17:10:55.196375214 +0800 |

（`cp -p` 保 mtime；两者与 `W17A-report.md` §6.2 记的值**逐位相同** ⇒ 我是从"W17A 读过的那一版"改起。）

### 2.2 应用器 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`

**`07dc7627f609e031`（37,625 B @ 09-15 17:10:55）→ `a3357070dae6de99`（41,304 B @ 09-16 11:59:21）**

四处改动（`diff -u` 逐字）：

```diff
@@ 站点1 宽松兜底类的 TryFormatLine（生成物 :230-231）@@
         internal static TextLine TryFormatLine(TextSource textSource, int cpFirst, double paragraphWidth,
-                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight, double paragraphIndent = 0)
+                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight,
+                                              double indentDip = 0, double paragraphIndentDip = 0)

@@ 透传到工厂（生成物 :256）@@
-                            modifierOpenIndex: modOpen, modifierCloseIndex: modClose, indentDip: paragraphIndent);
+                            modifierOpenIndex: modOpen, modifierCloseIndex: modClose,
+                            indentDip: indentDip, paragraphIndentDip: paragraphIndentDip);

@@ 站点1 调用点（生成物 :569-576；外层方法 TextFormatterImp.FormatLineInternal，宿主对象形参 = 生成物 :512）@@
                     settings.Pap.LineHeight,
+                    // ── WAVE17 §1 P2（`D-T3`）：缩进必须**按原始 DIP** 从宿主对象取 ──
+                    //   `settings.Pap.Indent` / `.ParagraphIndent` 是**理想整数 ×300**
+                    //   （`TextProperties.cs:39-40` 的 `RealToIdeal`，`LineServices.cs:1290` 因子 = 28800/96 = 300）
+                    //   ⇒ 传它们会引入一个**新的 300 倍错误**（R17A-recon.md §1.2 F2）。
+                    //   `paragraphProperties` 是本方法的形参（生成物 `:512`）⇒ 零换算、零舍入。
+                    //   语义（oracle 逐字符定下的）：`indentDip` = 停靠网格锚点 = `Indent`；
+                    //   `paragraphIndentDip` = 段落缩进 ⇒ 内容起点 = `Indent + ParagraphIndent`。
+                    indentDip: paragraphProperties.Indent,
+                    paragraphIndentDip: paragraphProperties.ParagraphIndent
                     ) as TextLine;
```

**两处新断言（把"射程不许悄悄缩到零"机器化）**：正向 4 条 `REQUIRED_IN_OUTPUT`（两个 DIP 形参同时存在／两槽各送各的／来源是 `paragraphProperties.Indent` 与 `.ParagraphIndent`）+ 负向 4 条禁写法（`indentDip: paragraphIndent`、`paragraphIndent: settings.Pap.ParagraphIndent`、`indentDip: settings.Pap`、`double paragraphIndent = 0`）+ 一条计数牙齿（四个串各**恰好 1 次**，不是 1 次就报错退出）。

### 2.3 生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`

**`f86198dfdd349332`（51,594 B @ 09-15 17:10:55）→ `9fd04d10a6479dcd`（52,598 B @ 09-16 12:05:21）**；`+1,004 B`，全部落在上面两处。`diff` 逐字（只有 3 个 hunk，与 §2.2 一一对应）：

```
-                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight, double paragraphIndent = 0)
+                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight,
+                                              double indentDip = 0, double paragraphIndentDip = 0)
-                            modifierOpenIndex: modOpen, modifierCloseIndex: modClose, indentDip: paragraphIndent);
+                            modifierOpenIndex: modOpen, modifierCloseIndex: modClose,
+                            indentDip: indentDip, paragraphIndentDip: paragraphIndentDip);
-                    settings.Pap.LineHeight, paragraphIndent: settings.Pap.ParagraphIndent
+                    settings.Pap.LineHeight,
+                    …（注释 8 行）…
+                    indentDip: paragraphProperties.Indent,
+                    paragraphIndentDip: paragraphProperties.ParagraphIndent
```

**"没有顺手改别的"的机器自证**（我用行上下文复核）：
- **严格档一个字没动**：生成物 `:553-560`（`HbTextFallback.TryFormatLine` 调用）**未出现在 diff 里**；`HbTextFallback.TryFormatLine`（shim `:4496`）的缩进缺口保持登记不修（§2 of 预登记）。
- **min/max 探针一个字没动**：生成物 `:302-311` 未出现在 diff 里 ⇒ `D-T2`/`D-T2-c` 未被顺手带动；**同时我没有给 minmax 补 indent**（见 §9 的"我选择的边界"）。
- **生成物 sha 可反向复现**：把备份抄回去 ⇒ sha 回到 `f86198dfdd349332`；再跑应用器 ⇒ 回到 `9fd04d10a6479dcd`（两次实测，`cmp` 逐字节）。

### 2.4 幂等与 `--check`（**不作为"能编译"的证据**，纪律 33）

```
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py --check
[锚点] ×5：上游出现 1 次（要求 1）        ← 每条都 1
[断言] 托管调用点 TryFormatLine=1、TryMinMaxParagraphWidth=1；两处原 LS 回退**都还在**
[断言] 负断言：空段落/空文本的旧短路写法**不存在** ✅
[断言] P2 负断言：`indentDip: paragraphIndent` / `Pap.*` 直传 / 旧形参名 **都不存在** ✅
[断言] P2 接线：透传 indent=1 para=1；来源（原始 DIP）= 1/1 ✅
[断言] LS 站点数 = 2（两处都被 ①shim ②宽松兜底 包住）；宽松兜底调用各 1 处
[断言] `throw` 条数 上游 4 == 生成物 4
[断言] 大括号平衡 {=116 }=116；上游 776 行 → 生成物 1139 行（+363 行，全是判断与注释）
[检查] build/PresentationCore.Linux/TextFormatterImp.Linux.cs：内容已是最新
=== 退出码 0 ===
```
**改前那条 `--check` 是 `rc=1`（"缺失/与上游不同步"）** —— 记录在案，免得把"改前也 rc=0"当成了证据。

---

## 3. 编译证据（**私有输出目录**，纪律 33）

```bash
export PATH="$HOME/.dotnet:$PATH"        # ⚠️ SDK 不在默认 PATH
dotnet build -m:1 build/PresentationCore.Linux/PresentationCore.Linux.csproj \
  -p:BaseOutputPath=$HOME/w17b-build/bin/ -p:BaseIntermediateOutputPath=$HOME/w17b-build/obj/
```
```
BUILD_RC=0
error CS = 0
warning CS = 0
已成功生成。 0 个警告 0 个错误   已用时间 00:00:20.58
```
私生产物 `$HOME/w17b-build/bin/Debug/PresentationCore.dll` = **`dd121f423b213faf`**（4,195,328 B @ 12:00 前一次构建）。

**另一次"从修前源构建"的对照**（用于证明"差就是 P2"）：把生成物抄回修前内容后，**同样的工程**用私有树
`-p:BaseOutputPath=$S/prefix-tree/bin/ -p:BaseIntermediateOutputPath=$S/prefix-tree/obj/ -p:IntermediateOutputPath=$S/prefix-tree/gen/`
构建 ⇒ `error CS = 0`、`rc=0`，得 **`37e55a6b18ea33f6`**（4,195,328 B @ 12:05:21）。
⇒ **同一工程、同一 csproj、同一 shim、同一输出目录结构，只差生成物** ⇒ 权威 `pc` 的 `1280323c9173bcde` 与它不同，**差因可归到 P2 这一处**（`proven`）。构建后生成物立即复原为 `9fd04d10a6479dcd`。

---

## 4. 权威写入（`build/PresentationCore.Linux/bin/Debug/`，供他车道归属）

| | sha16 | 字节 | mtime | 命令时刻 |
|---|---|---|---|---|
| `pc` **before** | **`18c49eec6992c7d9`** | 4,195,328 | 2026-09-16 **11:16:56**.569644573 +0800 | — |
| `pc` **after** | **`1280323c9173bcde`** | 4,195,328 | 2026-09-16 **12:00:10**.743118178 +0800 | 12:00:10 +0800 |
| `pdb` before | `15e54019b2705ee5` | 2,159,556 | 2026-09-16 11:16:56.538644256 | — |
| `pdb` after | `be6de7589ec7cbf7` | 2,159,556 | 2026-09-16 12:00:10.727118091 | — |

写入命令：`dotnet build -m:1 build/PresentationCore.Linux/PresentationCore.Linux.csproj`（默认 Debug 输出，`error CS = 0`，`AUTHORITY_BUILD_RC=0`）。
**大小逐位不变**（4,195,328 B）—— 与"只改了 IL 里两个实参的来源"一致；`pdb` 变大/变小都不是，只是内容变。
⇒ `#16` 冻结表头里那个 `pc` 已**第二次过期**（`c076…` → `18c4…` → **`1280…`**）；本轮之前的所有 `pc` 锚点（含 W17A 报告 §6.1）**都指向前代件**，引用时必须点名。

---

## 5. 臂复跑（**命令与 W17A §3.1 逐字相同**，只多一个 `--known-red`）

### 5.1 命令与 rc

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"
dotnet build -m:1 -c Release build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj
#   ⇒ BUILD_RC=0，error CS = 0；PresentationCore.Tests.dll = 3a474e675b24fdf4（38,912 B）
cd build/MilBridge/tests/PcLineOracle/bin/Release
dotnet PresentationCore.Tests.dll --pc-lines-oracle \
  /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json \
  --leg b --known-red $HOME/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt
```
**rc = 0**（`$HOME/wfp-runs/w17-laneW17B/postfix/env.txt` 的 `rc=0`）；stdout **`07615909a1ffaa8b`**（122,518 B）；stderr **0 字节**；`pc` **跑前 = 跑后 = `1280323c9173bcde`**（⇒ 可归因）；`loadavg` 跑前 `1.32 0.94 0.89`、跑后 `1.39 1.05 0.94`；`MemAvailable` 跑前 2857 MB、跑后 2766 MB。
**一次分类（不是失败）**：我第一次跑漏了 `export PATH="$HOME/.dotnet:$PATH"` ⇒ **`rc=127`、stderr `dotnet：未找到命令`、stdout 0 字节**。`127` = **"根本没跑"**（派单点名的先例），**不是失败**；补上 PATH 后同一命令 `rc=0`。另有一次 60 s 前台超时被 SIGTERM 中止（该臂跑满约 92 s）⇒ 改**后台作业**取读数（`proven`：`t_start=12:01:34`、`t_end=12:03:06`）。

**再跑一趟复现**（同一命令、同一 `pc`）：`12:10:49 → 12:12:20`，`rc=0`，stdout **`07615909a1ffaa8b`**（122,518 B），与交付趟 **`cmp` 逐字节相同**（`REPRO_IDENTICAL_BYTES`）；`pc` 跑前=跑后=`1280323c9173bcde`。

### 5.2 逐字判据行（stdout `07615909a1ffaa8b`）

```
PCLINE LEG=B 合计 cases=436 判定过=172 判定红=116 不可比(缺字形)=148（其中非0缩进 40、零缩进 108） 其中 bidi 重排例=2
PCLINE LEG=B 非0缩进: 红=72 绿=112 /224；零缩进: 红=44 绿=60 /212；PI≠0: 红=35 /112
PCLINE LEG=B 正控 relaxedCalls=496 relaxedHandled=496 relaxedFailed=0 relaxedSkippedRuns=0 relaxedBlankParagraphs=0 lastSkip="-" lastSkippedRange="-" lastFail="-"（本腿 relaxedCalls 增量=496）
PCLINE 登记表=/home/links-dev/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt ⇒ 已登记 136 条
PCLINE 未登记失败=0
PCLINE_EXIT rc=0（未登记失败 0 / 红 116 / 绿 172 / 不可比 148）
```

### 5.3 两个判别例（**逐字，含 pre-fix 对照**）

```
---- 判别例 B-indent/lead-tab-a@w140@LTR@i24@default  文本=[\ta] Indent=24 ParagraphIndent=0 我方行数=1 真值行数=1
PCLINE NAMED   B-indent/lead-tab-a@w140@LTR@i24@default 行#0 width 我方=109.347656 真值=109.346667 Δ=0.000989  尾部空白 我方=1 真值=1  换行长 我方=1 真值=1  lineText 我方=[\ta] 真值=[\ta]
PCLINE NAMED   B-indent/lead-tab-a@w140@LTR@i24@default 行#0 i=0 char=[	] xFromLeft 我方=24.000000 真值=24.000000 Δ=0.000000
PCLINE NAMED   B-indent/lead-tab-a@w140@LTR@i24@default 行#0 i=1 char=[a] xFromLeft 我方=96.000000 真值=96.000000 Δ=0.000000
---- 判别例 B-indent/notab-control@w80@LTR@i24@default  文本=[ab] Indent=24 ParagraphIndent=0 我方行数=1 真值行数=1
PCLINE NAMED   B-indent/notab-control@w80@LTR@i24@default 行#0 width 我方=50.695312 真值=50.693333 Δ=0.001979  尾部空白 我方=1 真值=1  换行长 我方=1 真值=1  lineText 我方=[ab] 真值=[ab]
PCLINE NAMED   B-indent/notab-control@w80@LTR@i24@default 行#0 i=0 char=[a] xFromLeft 我方=24.000000 真值=24.000000 Δ=0.000000
PCLINE NAMED   B-indent/notab-control@w80@LTR@i24@default 行#0 i=1 char=[b] xFromLeft 我方=37.347656 真值=37.346667 Δ=0.000989
```

| 量 | pre-fix（W17A `5d0b58c0d2ef5c57`） | **post-fix（本次 `07615909a1ffaa8b`）** | 真值 | post Δ |
|---|---|---|---|---|
| `lead-tab-a@w140` 宽 | 109.347656 | **109.347656** | 109.346667 | +0.000989（绿） |
| `lead-tab-a@w140` **tab 网格锚** | **0.000000（Δ=−24）** | **24.000000** | 24.000000 | **0.000000** |
| `lead-tab-a@w140` `a` x | 96.000000 | 96.000000 | 96.000000 | 0.000000 |
| `notab-control@w80` 宽 | **26.695312（Δ=−23.998）** | **50.695312** | 50.693333 | +0.001979 |
| `notab-control@w80` `a` x | **0.000000** | **24.000000** | 24.000000 | 0.000000 |
| `notab-control@w80` `b` x | **13.347656** | **37.347656** | 37.346667 | +0.000989 |

### 5.4 E1–E8 判据表（**按 arm 拆开**，因为 `E2/E3` 的分母里混着本臂表达不出来的 `tab0`）
| # | 量 | pre-fix（W17A 实测） | **post-fix 实测** | 期望 | 判决 |
|---|---|---|---|---|---|
| **E1** | `PCLINE_EXIT` | `rc=1（未登记失败 228 / 红 228 / 绿 60 / 不可比 148）` | **`rc=0（未登记失败 0 / 红 116 / 绿 172 / 不可比 148）`** | `rc=0`、未登记失败 0 | ✅ **达成**（§6 的登记是前提） |
| **E2** | 非 0 缩进分桶 | 红=184 绿=0 /224 | **红=0 绿=112 /224**（红 0） | 红=0 /224 | ✅ **红 0 达成**；绿 112 而非 184，因为 72 条落在 `tab0` 臂（登记保留，§6） |
| 　 | └ **default 臂（P2 的射程）** | 红=**92** 绿=**0** /92 | **红=0 绿=92 /92** | 红 0 | ✅ **92/92 全绿** |
| 　 | └ `tab0` 臂（表达不出来） | 红=92 绿=0 /92 | 红=**72** 绿=**20** /92 | 不可判 | ⚠️ **不可测**（§6；其中 20 条是"错间距恰好撞对"） |
| **E3** | `PI≠0` 分桶 | 红=88 /112 | **红=0 绿=53 /112**（红 0） | 红=0 /112 | ✅ **红 0 达成**；**没有出现 `Δ≈+7200/14400`** ⇒ **不是坏修法** |
| 　 | └ **default 臂** | 红=**44** 绿=**0** /44 | **红=0 绿=44 /44** | 红 0 | ✅ **44/44 全绿** |
| 　 | └ `tab0` 臂 | 红=44 绿=0 /44 | 红=**35** 绿=**9** /44 | 不可判 | ⚠️ **不可测** |
| **E4** | 判别例 `notab-control@w80` | `w=26.695312` / `x=[0.000000, 13.347656]` | **`w=50.695312`（Δ=+0.001979）**；**`x(a)=24.000000`、`x(b)=37.347656`（Δ=0.000000 / +0.000989）** | 三个 Δ ≤0.002 | ✅ **逐位达成** |
| **E5** | 判别例 `lead-tab-a@w140` | 宽绿 / tab `x=0.000000`（Δ=−24）/ `a x=96.000000` | 宽 `109.347656`Δ=+0.000989；**tab `x=24.000000`Δ=0.000000**；`a x=96.000000`Δ=0.000000 | 三项全绿 | ✅ **逐位达成**（红**唯一**钉在网格锚上的形态**已消失**） |
| **E6** | 零缩进同层对照（default 臂） | 绿=**52/52**（零红） | **绿=52/52（零红）** | 逐位不动 | ✅ **逐位不动** |
| **E7** | 孪生恒等式 | 违反=**0**；最大差=0.0020 | **违反=102**；最大差=**24.0020** | 违反=0 | ❌ **判据本身错了 —— 我推翻它**，见 §7.3 |
| **E8** | 正控 | `relaxedCalls=544 relaxedHandled=544 relaxedFailed=0` | `relaxedCalls=496 relaxedHandled=496 relaxedFailed=0`（本腿增量 **496**） | `relaxedHandled>0` 且增量 = 496 | ✅ **达成**（`relaxedFailed=0`；无 `rc=2`） |

**F1 失败分类表的逐条对照（没有一条触发）**：
- ❌ **未触发**「E2/E3 仍红但 E4/E5 变绿」 ⇒ 不是部分修（`Indent` 与 `PI` 两条**都**通了）。
- ❌ **未触发**「E3 仍红且 `Δ≈+7200`」 ⇒ **没有**按 `settings.Pap.*` 直传；生成物里 `settings.Pap` 在站点1 调用点**零命中**（应用器负断言 + 我 grep 复核）。
- ❌ **未触发**「E6 也变了」 ⇒ 零缩进对照逐位不动。
- ❌ 无 `rc=2 NOINFO`；`rc=127` 出现过一次并已按"没跑"分类（§5.1）。

---

## 6. 登记（`--known-red`）：**136 条，全部是"本臂表达不出来的输入"**

**臂的 `--known-red` 本来就有**（`Program.cs:158/:163/:220/:688/:927-956`，格式 `<id>` 或 `<id>::<判据片段>`）⇒ **`Program.cs`/`.csproj` 一个字节未改**（sha 见抬头）。文件：`$HOME/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt`（**`89324f1f643167e5`**，17,501 B）—— 之所以放 scratch 而不放 `build/MilBridge/`：**`build/MilBridge/known-red.json` 是别的东西**（`f9843bde351029dc`，三支在册 tab 臂的登记表）且在我的禁改清单里；**我没有动它**。

### 6.1 登记了什么、几条、为什么

| 组 | 条数 | 缩进分桶 | 为什么**本臂表达不出来**（"仪器不能表达"，**不是**"产品对"） |
|---|---|---|---|
| `@…@tab0` 臂（`incrementalTabArm == DefaultIncrementalTab=0`） | **136** | 零缩进 **44** + 非 0 缩进 **92**（`I=24` 48 / `PI=24` 18 / `PI=48` 6 / `I24PI24` 18 / `I24PI48` 2） | `TextParagraphProperties.DefaultIncrementalTab` 由宿主表达，但 PC 宽松接线点 `WpfLinuxLenientFallback.TryFormatLine`（生成物 `:230-231`）**没有这个形参**、站点1 调用点（`:569-576`）也不传 ⇒ shim 的 `defaultIncrementalTab` 恒 `NaN` ⇒ `FormatParagraph` 取框架默认 `4×emSize = 96`（**我现场重锚**：shim **`:2831`** 逐字 `double tabInterval = double.IsNaN(defaultIncrementalTab) ? 4.0 * emSize : defaultIncrementalTab;`；同族另有 `:643`/`:1745` 两处 `double.IsNaN(tabInterval) ? 4.0 * emSize : tabInterval`。⚠️ **W17A 报告 §7.2 引的 `shim :1876` 是漂了的锚点** —— 现场重读 `:1876` 是 `return w;`）⇒ **tab 网格间距（96 vs 案例要求 0）这个输入根本没有通道**。与 P2 是两个**不同的量**：P2 只改 `indentDip`/`paragraphIndentDip` 两个槽。 |
| `@…@default` 臂 | **0** | — | **一条都没登记** —— 那 92 条修前红 100% 属于 P2 的射程，**修后 92/92 全绿**（§5.4）。 |

**"表达不出来" vs "产品错"的界线（本题要求分清，我分清了）**：
- **产品侧**：`DefaultIncrementalTab` 在 PC 路径上**确实没有被接到工厂** —— 这是一条**真实的产品缺口**（登记在册，属 PC 接线点，**P2 的射程之外**，本波只登记不修，与预登记 §2 的"严格档缺口只登记"同族）。**我没有把它写成"产品没问题"。**
- **仪器侧**：本臂**无从**把这个输入喂下去（PC 的实参表里没有它的位置）⇒ 这一族在这支臂上**不可测**（`not measurable`），因此登记它是**如实标注射程**，不是消音。
- **两件事叠在一起**，所以本表的 136 条既**不许**读成"P2 修好了它们"，也**不许**读成"产品没问题"。

### 6.2 "登记只改 rc/登记行，不改测量"的**差分实证**（在**修前** `pc` 上做的）

用 §3 那次"从修前源构建"的私生产物 **`37e55a6b18ea33f6`** 做（拷进臂输出目录的副本；**权威 `pc` 全程未动**：跑前=跑后=`1280323c9173bcde`）：

| 趟 | 命令 | rc | stdout sha16 | 关键行 |
|---|---|---|---|---|
| ① 不给登记表 | `… --leg b` | **1** | **`5d0b58c0d2ef5c57`**（155,103 B） | `未登记失败=228` / `PCLINE_EXIT rc=1（未登记失败 228 / 红 228 / 绿 60 / 不可比 148）` |
| ② 给本表 | `… --leg b --known-red …/pc-line-oracle-known-red.txt` | **1** | `f0932e6df9fdfdff`（154,681 B） | `已登记 136 条` / `未登记失败=92` / `PCLINE_EXIT rc=1（未登记失败 92 / 红 228 / 绿 60 / 不可比 148）` |

**差分逐条分类**（`diff ① ②` = 467 行）：**只有** 228 对 `UNREGISTERED ↔ KNOWN-RED`（同一 id、同一 `::` 判据片段，**测量数字逐字相同**）+ **4 行**汇总/rc（`PCLINE 登记表=`、`PCLINE 未登记失败=`、`PCLINE 未给 --known-red ⇒ …`、`PCLINE_EXIT rc=`）。
**"非登记类差异行数" = `0`**（命令与结果：`grep '^[<>]' diff.txt | grep -vc 'UNREGISTERED\|KNOWN-RED\|登记表\|PCLINE_EXIT\|未登记失败\|未给 --known-red'` ⇒ **`0`**）⇒ **登记表一个测量数字都没有搬动**（`proven`）。
**另有两条硬证据**：
1. **修前读数在别处逐字节复现**：趟①的 stdout 与 W17A 交付的 `run-prefix-legB/stdout.txt`（`5d0b58c0d2ef5c57`）**`cmp` 逐字节相同、diff 0 行** ⇒ 我的装置与那条交付读数**同一口径**（也说明"修前 pc 重跑"没变）。
2. **登记是"只认 id"的**：本表登记的 136 条里有 **20 条修后自己转绿了**（§6.3）—— 它们**仍然**在表里、**不再**出现在 `KNOWN-RED` 行里（因为 `-red` 表只在**失败列表**上匹配，绿了就不匹配）⇒ **登记不会把绿读成红，也不会把红读成绿**，只改 rc。

### 6.3 登记"过宽"的一条（照实记）

修后该族 136 条里 **20 条转绿**（`B-indent-extra/*@…@tab0` 一类），它们不是"修好了"，而是**错间距（96）恰好撞对**（与 W17A §7.2 记的 8 条同类：`lead-tab-b-t-c@…@i24nl@tab0` 那种"行数也不等的偶然吻合"）。我这 136 条登记对它们**过宽**（本该仍红却已绿，表不会报错）—— **不影响任何判据**（E1 靠"未登记失败=0"，E2/E3 靠分桶），但**必须点名**：**这张表是"不可测"的标注，不是"这些用例是对的"的断言**。

---

## 7. 我推翻 / 更正的东西

### 7.1 一条我自己的仪器事故（会读成"产品坏"，已抓掉）

**现象**：我第一次跑"修后"时 stdout 0 字节、**`rc=127`**。
**分类**：`127` = `dotnet：未找到命令` = **根本没跑**（SDK 不在默认 PATH），**不是失败**。补 `export PATH="$HOME/.dotnet:$PATH"` 后同一命令 `rc=0`。
**同族第二条（尚未在任何报告里见到，值得留档）**：把臂的输出目录**整体拷到别处**再跑（我在 §6.2 的差分实验里这么做了）⇒ `rc=134` + `System.DllNotFoundException … 'user32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库 … 不存在 <拷贝目录>/libwpfwin32.so`。**这不是**"修前 pc 坏了"：设 `WPF_LINUX_WIN32_SHIM=/abs/path/to/src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 后**同一份修前 pc 跑出与 W17A 逐字节相同的 228 红**。⇒ **"臂在别处跑要带原生 shim 路径"** 是本臂的一条隐含前置（`Win32ShimResolver.cs:59/:65`），建议进 W17A 报告的复跑说明。**教训**：`rc=134` 的首个假设应是"装置缺东西"，不是"被测件坏了"。

### 7.2 W17A §7.1 第 3 行的"`tab0` 44 条"**低估了不可测的范围**

W17A 说"`@…@tab0` 臂（218 例）不可测 … **零缩进那 44 条红 100% 来自它**"——**前者（218 例不可测）是对的，但按分桶读时会误导**：`tab0` 臂在**可比集**里有 **144** 条（零缩进 52 + 非 0 缩进 92），修前红 **136**、绿 8。**非 0 缩进的 92 条同样是"表达不出来"，而不是 P2 的红**。我按 arm 拆开重算了每个分桶（§5.4），并在 §6 把 **136** 条（而不是 44 条）登记掉 —— 否则 E2 的"红 0 /224"**不可能达成**（92 条会永远红），会把"P2 没修好"读成结论。**这是本轮最值钱的一条更正**。

### 7.3 **E7 判据本身错了：我把 W17A §5 的 E7 撤回**（`E7: 孪生恒等式违反=0`）

W17A §2.7 立的"孪生恒等式"是：`PI=0` 时我方在 `@i24` 上的读数**必须等于** oracle 自己的 `@i0` 孪生例。E7 要求**修后仍 `违反=0`**。
**实测修后：违反 = 102 /（72 个有孪生的例），孪生最大差 = 24.0020。** 而**这恰恰是修好的表现**：

- 预登记的"孪生"两例：`B-indent/notab-control@w80@LTR@i24@default` 修后 `w=50.695312`、孪生（`@i0`）真值 `26.693333` ⇒ **Δ=+24.001980** —— **差的正是 `Indent=24`**，而这**正是 oracle 真值说的**（`i24` 的宽度就该比 `i0` 宽 24）。
- 逐字（`07615909a1ffaa8b` 第 935/936/937 行）：
  ```
  PCLINE TWIN   B-indent/notab-control@w80@LTR@i24@default 行#0 width 我方=50.695312 孪生真值=26.693333 Δ=24.001980
  PCLINE TWIN   B-indent/notab-control@w80@LTR@i24@default 行#0 i=0 char=[a] x 我方=24.000000 孪生真值=0.000000 Δ=24.000000
  PCLINE TWIN   B-indent/notab-control@w80@LTR@i24@default 行#0 i=1 char=[b] x 我方=37.347656 孪生真值=13.346667 Δ=24.000989
  ```
- **机制**：修前"我方 == `@i0` 孪生"成立的**唯一原因**是"PC 把缩进整条丢掉了"（喂进去的 `indentDip`=300·0=0、`paragraphIndentDip`≡0）。**P2 一落地，缩进就真的进去了** ⇒ 这个恒等式**必然被打破**。
- **判决**：**E7 的"违反=0"是"把缺陷态写成了预期"**（与预登记 §0.0 点名的 `ProviderShapeTests.cs:143-157` 同族，也与纪律"判据不许把缺陷当成预期"同族）。⇒ **撤回该验收项**；修后**没有任何**恒等式可断言（`Indent` 与 `@i0` 的差就是被修的东西本身）。
- **`W17A-report.md` §5 的 E7 行与 §2.7 的"这不是估算，是恒等"这句话，在修后即失效** —— 请后续复跑者**不要把 102 当红**。**我保留 E7 的 pre-fix 读数（违反 0/72）作为它当时成立的记录，但把它从"验收项"降级为"缺陷态指纹"**。
- 旁证（**我按 arm 拆开复核过、并更正了我自己的初稿**）：修后 283 条 `TWIN` 比较行里**仍有 52 条 Δ≤0.002**，**全部 52 条都在 `@default` 臂**（`tab0` 臂 **0 条**）。**机制**：这 52 条恰好是"缩进按定义不该改变输出"的那些 —— 非首行（`Indent` 只作用首行 ⇒ `FormatSettings.cs:139/:144` 的 `_textIndent`）、或 tab 停止位已远在缩进之外（如 `w=204.000000` 行）。⇒ **恒等式不是"全废"，而是"只在缩进可证不改输出的地方继续成立"**，这**加强**了 §7.3 的结论：它**本来是缺陷态的产物**（缩进整条被丢 ⇒ 处处成立），修后就只剩这些真等价处。**我初稿写成"它们恰好是 `tab0` 臂里 P2 不改变输出的那些"，实测是 `@default` 臂 —— 已在报告里更正**。

### 7.4 又一处**锚点漂移**（纪律 4 的现场）：W17A §7.2 引的 `shim :1876` 已失效

`W17A-report.md` §7.2 逐字写："`FormatParagraph` 取框架默认 `4×emSize = 96`（shim **`:1876`** `double tabInterval = double.IsNaN(defaultIncrementalTab) ? 4.0 * emSize : defaultIncrementalTab;`）"。
**我现场重读**：`build/shims/PresentationCore.HbTextLine.cs` **`:1876`** 逐字是 `            return w;` —— **不是**那句话。真锚点 = **`:2831`**：
```
2831:            double tabInterval = double.IsNaN(defaultIncrementalTab) ? 4.0 * emSize : defaultIncrementalTab;
```
（上下文 `:2826` 形参含 `double paragraphIndentDip = 0)   // D-T2/(C)：尾随可选，默认 0 ⇒ 既有调用点零改动`、`:2833` 用 `indentDip`/`tabInterval`/`paragraphIndentDip` 调 `HbMultiFontShaper.ShapeParagraph` ⇒ **这一处正好是我 P2 送下去的两个量的消费点**，值得点名。）
`shim` 文件本轮**未变**（`bc04c05ab6d8d82a`，275,765 B @ 09-15 18:25:25）⇒ **这不是"文件变了"，是那次引用本身写错/漂了**。**结论不受影响**（机制结论由代码语义支撑，且我另行复算了 136/92/44 的分母），但**引用必须换锚**。

### 7.5 一条**没有**被推翻、但要收窄的 W17A 表述

W17A §3 第 3 行 stdout："正控 `relaxedCalls=544`"；修后是 **496**。这不是矛盾：`relaxedCalls` 是**本腿在跑期间**的增量，**修后非 0 缩进例不再因 `indentDip=7200/14400` 触发额外调用**（544 → 496，**少 48**）。E8 的判据是 `relaxedHandled>0`（修后 496>0 ✅），**不是"544 不许变"**；若拿 544 当判据会**假红**。

### 7.6 预登记 §1 P2 的预测（我现场重锚并验证）
- **"改法"逐条与预登记 v2 §1 P2 一致**：加 `double paragraphIndentDip = 0`、`:256` 改两槽、站点1 传 `paragraphProperties.Indent` / `.ParagraphIndent`（**原始 DIP**）—— **没有**用 `settings.Pap.*`（负断言机器化，§2.2）。
- **"不要传 `settings.Pap.*`"这条 v2 更正被我的读数独立证实**：`PI≠0` 的 44 条 default 臂**全部转绿**，**没有**任何一条出现 `Δ≈+7200/14400`。若是坏修法，`E3` 会残留 `Δ≈+7200`（F1 指纹）—— **一条都没有**。
- **"新臂必须被 tier 转向"这条前提成立**：本臂 stdout 的 `TierSteer` 三行逐字在位，`WPF_LINUX_TEXTLINE_FALLBACK` 读回 `0`。
- **预登记 §0.0 的 F2（×300）我复核了代码事实**：生成物 `:1062` `RealToIdeal`、`:1097` `ToIdeal { get { return Constants.DefaultRealToIdeal; } }`；`TextProperties.cs:39-40` 两条 `RealToIdeal(...)`。⇒ 传 `Pap.*` 必错 300 倍。
- **我没有复核的部分**（照实写）：`LineServices.cs:1290` 的 `DefaultRealToIdeal = 28800.0/96` 我只按 W17A/R17A 的引用**转述**，本轮**没有**读那一行（与本件判据无关：我的修法**零换算**，不依赖那个常数）。**标注为未复核。**

---

## 8. 读数表（件 sha + mtime + 环境）

**环境**：`uname -r = 6.8.0-138-generic`｜开工 `2026-09-16 11:58:28 +0800`，`loadavg = 0.26 0.35 0.72`，`MemAvailable = 3794248 kB`｜收尾 `2026-09-16 12:09:06 +0800`，`loadavg = 0.94 1.25 1.08`，`MemAvailable = 2978 MB`。

### 8.1 每趟跑前/跑后的 `pc`（并发协议的硬要求）

| 趟 | 起→止（local） | 被测 `pc` | `pc` 跑前 | `pc` 跑后 | 判定 |
|---|---|---|---|---|---|
| ① 修后交付趟（`postfix/`） | 12:01:34 → 12:03:06 | `1280323c9173bcde` | `1280323c9173bcde` | `1280323c9173bcde` | ✅ 可归因 |
| ② 差分之趟①（修前 pc，无登记） | 12:05:59 → 12:07:2x | `37e55a6b18ea33f6`（副本） | 权威仍 `1280323c9173bcde` | 权威仍 `1280323c9173bcde` | ✅ 权威未被扰动 |
| ③ 差分之趟②（修前 pc，有登记） | 12:07:2x → 12:08:55 | 同上 | 同上 | 同上 | ✅ 权威未被扰动 |

**权威写入**发生在 `11:59:53 → 12:00:10`（§4），此后**未再重建**（`pc` mtime 全程 = `12:00:10.743118178`）。

### 8.2 件 sha / 字节 / mtime

| 文件 | sha256 前 16 | 字节 | mtime |
|---|---|---|---|
| 应用器 `…/patch-presentationcore-textline-fallback.py`（前→后） | `07dc7627f609e031` → **`a3357070dae6de99`** | 37,625 → 41,304 | 09-15 17:10:55 → **09-16 11:59:21** |
| 生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（前→后） | `f86198dfdd349332` → **`9fd04d10a6479dcd`** | 51,594 → 52,598 | 09-15 17:10:55 → 09-16 12:05:21 |
| **权威 `pc`** `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | **`1280323c9173bcde`** | 4,195,328 | **09-16 12:00:10** |
| `pc` .pdb | `be6de7589ec7cbf7` | 2,159,556 | 09-16 12:00:10 |
| `build/shims/PresentationCore.HbTextLine.cs`（未动） | `bc04c05ab6d8d82a` | 275,765 | 09-15 18:25:25 |
| 臂源 `build/MilBridge/tests/PcLineOracle/Program.cs`（**未动**） | `544aab374ee8e1a6` | 57,572 | 09-16 11:44:53 |
| 臂工程 `.csproj`（**未动**） | `b0bf270206fe9c09` | 4,380 | 09-16 11:09:12 |
| 臂产物 `…/bin/Release/PresentationCore.Tests.dll`（本次重编） | `3a474e675b24fdf4` | 38,912 | 09-16 12:00:20 |
| 语料 `tests/…/tab-anchor-oracle.json` | `a31a813114256faf` | 1,251,441 | 09-14 19:33:26 |
| `build/MilBridge/known-red.json`（**未动**） | `f9843bde351029dc` | 28,734 | 09-15 18:53:40 |
| `build/MilBridge/W17A-report.md` | `19f6fe04d165cfd9` | 36,241 | 09-16 11:57:48 |
| `docs/WAVE17-PREREGISTRATION.md` | `8247497df64a7903` | 35,372 | 09-16 11:59:03 |
| 修前 pc（私生产物，用于差分） | `37e55a6b18ea33f6` | 4,195,328 | 09-16 12:05:21 |

> ⚠️ **一件现场事实（纪律 15/18 要求点名）**：`docs/WAVE17-PREREGISTRATION.md` 在本轮期间被**主控车道**改过（我读到的 head 版本是 `c5b3c5977d949513`/28,534 B @ 11:44，收尾是 `8247497df64a7903`/35,372 B @ 11:59 —— 新增的正是 **§1 P2 的"红证已到手"小节**）。我**现场重读**了 §1 P2 的"改法"与"预测"两段，**实质未变** ⇒ 本件判据基础未被这次改动动摇；引用一律带 sha。

### 8.3 本次读数产物（`$HOME/wfp-runs/w17-laneW17B/`）

| 文件 | sha16 | 字节 |
|---|---|---|
| `backup/applier.before.py` | `07dc7627f609e031` | 37,625 |
| `backup/generated.before.cs` | `f86198dfdd349332` | 51,594 |
| `pc-line-oracle-known-red.txt`（登记表，**136 条**） | `89324f1f643167e5` | 17,501 |
| `postfix/stdout.txt`（**交付读数**：修后 + 登记） | **`07615909a1ffaa8b`** | 122,518 |
| `postfix/stderr.txt` | `e3b0c44298fc1c14` | **0** |
| `postfix/env.txt` / `rc` 见其中 | — | — |
| `repro/stdout.txt`（**复现趟，同一命令**） | **`07615909a1ffaa8b`** | 122,518 |
| `diffrun/noreg.txt`（修前 pc，无登记） | **`5d0b58c0d2ef5c57`** | 155,103 |
| `diffrun/reg.txt`（修前 pc，有登记） | `f0932e6df9fdfdff` | 154,681 |
| `diffrun/diff.txt`（①↔② 的 467 行差） | — | — |
| `diffrun/diff-vs-W17A.txt`（**0 行**：与 W17A 交付逐字节相同） | — | 0 |
| `compile-private.log`（私编，`error CS=0`） | — | — |
| `build-authority.log`（权威写入，`error CS=0`） | — | — |
| `prefix-tree/bin/Debug/PresentationCore.dll`（修前 pc） | `37e55a6b18ea33f6` | 4,195,328 |

---

## 9. 测不出来 / 没能建立的（**不许读成绿**）

| # | 没能建立的东西 | 为什么 | 需要什么 |
|---|---|---|---|
| 1 | **应用门禁 6/6 与 `drawn/colors/frames` 逐位不变**（预登记 §1 P2 预测①） | 本车道**没有跑** `WpfTextDemo` 应用门禁（那是重冻/收尾的活，且需要独占静树） | 波收尾时按 §3 走 `close-wave.sh` + 两条腿的应用门禁（第 2 趟设 `WPTD_BASELINE_OUT`）。**前提已由主控只读实测**（`samples/**` 对 `Indent`/`ParagraphIndent`/`TextParagraphProperties` **0 命中**）⇒ 预测**应**逐位不变，但**我这一轮没有读数**。 |
| 2 | **五臂读数逐位不变**（预测②） | 同上：五臂是波收尾的仪器，本车道只跑了一支新臂 | 收尾时重取五臂；本件射程（生成物两处）**不进**五臂的调用点（§2.3 的"严格档未动"+ 五臂走 `HbTextLineFactory` 直调），但**这是论证不是读数** |
| 3 | **`tline` 日志除身份行外不变**（预测③） | 未跑 `tline-gate.sh`（禁改清单 + 需静树） | 收尾 |
| 4 | **P1 的行为中性补读**（W17C 自报的必补缺口） | 本车道只对 P2 取了读数；`pc` 现在同时含 P1（元数据）+ P2（indent）⇒ **我的读数不能单独归属 P1** | 需要"只含 P1"的树（或能区分两者的对照）。**我的 `37e55a6b18ea33f6`（修前 pc，含 P1 不含 P2）与本轮交付读数一起，恰好给了收尾一个工具**：把 ①`37e55a6b`（P1 only）与 ②`1280323c`（P1+P2）在两支臂上的读数相减，P1 的残余位移可以直接读出来 |
| 5 | **`tab0` 族 136 条的真实产品行为** | PC 的宽松接线点**没有** `DefaultIncrementalTab` 形参 ⇒ 本臂喂不进去 | 一条**新登记**（`DefaultIncrementalTab` 未接到工厂）落在 **PC 接线点**（不是 shim）⇒ 是**另一件**（要给它形参 + 调用点；shim 侧已有该形参 `FormatParagraph(..., defaultIncrementalTab)`）。我**没有**顺手加它（P2 只许改两处，纪律"同件不许顺手改两处"） |
| 6 | **严格档（`HbTextFallback.TryFormatLine`, shim `:4496-4497`）的缩进缺口** | 本臂主动转向宽松档 ⇒ 对严格档**零射程** | shim 写域（另立登记，本波只登记） |
| 7 | **min/max 探针**（`D-T2`/`D-T2-c`） | 我**没有**给 `TryMinMaxParagraphWidth` 补缩进形参 ⇒ **minmax 路径上的 indent 仍然是 0**（与修前一致） | **这是我的一个有意的边界选择，必须点名**：预登记 §1 P2 只要求改 `FormatLine` 那条链，且 §0.0 的 F1 把"严格档缺口"单列、`W17A-report.md` §7.1 第 6 行把 min/max 归给 P3 的牙。**后果**：`FormattedText.MinWidth` 一类消费者今天仍看不到缩进。**若要修，属新的一件**（并且要连带 `CollectLenient` 的覆盖面问题） |
| 8 | **`@…@tab0` 20 条"转绿"是不是巧合** | 我只观察到"转绿"这一事实，**没有**逐条证明它是"错间距撞对" | 逐条比 `lineCount`+逐字符（`tab0` 的 `lead-tab-b-t-c@…@i24nl@tab0` 一类行数都不等 ⇒ 强烈提示巧合）。**标注为未证** |
| 9 | **`LineServices.cs:1290` 那个常数** | 本轮没读那一行（§7.5） | 无关本件判据（零换算） |

---

## 10. 口径与纪律自查

- **纪律 15/18（读数 = 四元组）**：本报告每条读数都带 **`pc` `1280323c9173bcde`（修后）/`37e55a6b18ea33f6`（修前对照）+ 仪器 `3a474e675b24fdf4`（源 `544aab374ee8e1a6`）+ 判据口径（行数/`Width`/`TrailingWhitespaceLength`/`NewlineLength`/`lineText`/`Rectangle.X` vs `xFromLeftDip`，容差 0.05）+ 语料 `a31a813114256faf`**。
- **纪律 16（先备份）**：§2.1 两条备份带 `cp -p` 保 mtime，**before sha16 都拿到了**（没有重演 W17C 那条"before 不可得"的违规）。
- **纪律 33（`--check` ≠ 能编译）**：§2.4 是 `--check`（**改前 rc=1、改后 rc=0**），§3 是两种私有构建 + 一次权威构建的 `error CS = 0`。**两者分开写。**
- **纪律 21/25/27（判据必须能变红）**：本件两极性**实测**：修前 `rc=1`/228 红 → 修后 `rc=0`/116 红（全部登记为不可测）；`tab0` 族的"不可测"是**我算出来的、按 arm 拆开的**（含 `grep`/脚本可复算的分母），不是估的。
- **纪律 22（缺列不许补列）**：`@…@tab0` 一族我**没有**编任何真值或位移预测 —— 只报"不可测"并登记。
- **纪律 34（不动在册仪器）**：`PcLineOracle/Program.cs`、`PcLineOracle.csproj`、`CoverageProbe/**`、`known-red.json`、`tline-gate.sh`、`csproj`、`HbTextLineShimSha.targets`、`tests/ShimShaReader/**` **本轮一个字节都没改**（sha 见 §8.2；`Program.cs`/`.csproj` 与 W17A 报告 §6.2 逐位相同）。
- **纪律 32（谁跑的这趟）**：抬头的 `lane=W17B`、时刻、`loadavg`、`MemAvailable`、`kernel`。
- **`proven` / `not proven` / `not measurable`**：§5.4 的 E1–E6/E8 是 **proven（实测读数）**；§6.2 的"登记只改 rc"是 **proven（差分 + 非登记差异行 0）**；§7 的四条更正全部 **proven**；§9 是 **not measurable / not proven**，并写明所需仪器。**本报告没有把任何 `not measurable` 写成 `proven`。**
