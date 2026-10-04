# R17B · recon —— `WAVE17` §1 `P5`（`ContractProbe P6` / `D-F2`）**可行性与成本**

> **lane = R17B**｜写域 = 本文件 + `$HOME/wfp-runs/w17-laneR17B/`｜其余**全程只读**
> **机器约束**：本轮 **未跑** `dotnet build/test/run`、**未起任何长驻进程**、**未改任何被测件**（唯一写入 = 本文件）。
> **读数时刻**：`2026-09-15T15:26:08Z`（= 北京时间 `23:26:08`）｜`loadavg=1.68 1.27 0.64`（`/proc/loadavg`）｜`mem_available=4011 MB`（`free -m`）｜`kernel=6.8.0-138-generic`
> ⚠️ 本文件的 `loadavg` 与项目文档里那些"静树"读数**不可比**：本条是纯读取车道，取值只用于纪律 32 的出处记录。

---

## 0. 一句话裁决

| 缺陷 | 裁决 | 一句话理由 |
|---|---|---|
| **D-1 · `ContractProbe P6`** | **`CRITERION-MAY-BE-WRONG`**（且**不是** PC/shim 缺陷） | 抛点确实在上游 `GlyphRun.CheckInitialized()`，但**上游 WPF 不保证**"`BeginInit`+setter（不设 `GlyphTypeface`）构造出的 `GlyphRun` 读 `GlyphIndices` 不抛" —— 上游 `Initialize()` 要求 `glyphTypeface != null`（`GlyphRun.cs:429`）；我们的 `GlyphRun.cs` 与上游**逐字节同一份**（`csproj:543` 直接编上游文件），**没有移植分歧**；红的是**探针**（`Program.cs:198-205` 从不设 `gr.GlyphTypeface`），且它把 `EndInit` 的异常吞进一个**永不打印**的局部串 ⇒ 症状被记错了半个。**修法 = 探针 1–4 行，不动 `pc`/`shim`**（⇒ 不动 `#16` 冻结）。 |
| **D-2 · `D-F2`** | **`NEEDS-DEDICATED-TRACK`** | 不是缺导出、也不是桩：`CreateFontFace(Uri)` **能造出面**，卡在**面↔Font 反查的身份判据**（`LinuxFontCollection.cs:452` `ReferenceEquals(...)`，而两条造面路径**各自新建 `SKTypeface`**）⇒ shim 的"诚实失败"守卫返回 `null` ⇒ 上游守卫抛 `FileFormatException`。射程：`provider` 位（九位之一）必变 ⇒ **`#16` 基线当场作废 + 重冻**，且 `pc` 的 peer 里就含 provider ⇒ `pc`/`pf` 也会动；另有一条**生产路径**（`shim:3810`）与一条**现有测试**（`ProviderShapeTests.cs:155-156`）会在修好后行为改变。**量级 > 本波。** |

**登记口径更正两条**（详见 §2.2 / §1.7）：
1. `KNOWN-DEFECTS.md:610` 写的"**DWrite 的"从文件取集合"未接**"→ **不成立**：集合**接了**（有 10:35 实测：`GetFontCollectionFromFile(uri) → MS.Internal.Text.TextInterface.FontCollection`）。真缺口在**反查**。
2. `WAVE17-PREREGISTRATION.md:61` 的 `P6` 判据（"`BeginInit`/`EndInit`+setter 构造出的 `GlyphRun` 读 `GlyphIndices` 不抛"）**少了前置条件**：必须先设 `GlyphTypeface`。

---

# 1. D-1 · `ContractProbe P6`

## 1.1 探针里的真实调用链（逐行）

`build/MilBridge/tests/ContractProbe/Program.cs`（`bd4f4958578daeaa`，13,165 B，`2026-09-10 19:46:38`）`P6` 段原文（`:192-217`）：

```
195:                 var gr = new GlyphRun();
196:                 // BeginInit/EndInit 是 ISupportInitialize 的**显式实现**，必须强转才调得到
197:                 var init = (System.ComponentModel.ISupportInitialize)gr;
198:                 init.BeginInit();                   // ← setter 有 CheckInitializing()，必须先 BeginInit
199:                 gr.GlyphIndices = new List<ushort> { 43, 72, 79 };
200:                 gr.AdvanceWidths = new List<double> { 18.36, 14.328, 7.152 };
201:                 gr.FontRenderingEmSize = 24.0;
202:                 gr.BaselineOrigin = new Point(0, 20);
203:                 gr.BidiLevel = 0;
204:                 gr.IsSideways = false;
205:                 gr.PixelsPerDip = 1.0f;
206:
207:                 string endInit = "未调 EndInit";
208:                 try { init.EndInit(); endInit = "EndInit 也通过（无 GlyphTypeface 也能收尾）"; }
209:                 catch (Exception e2) { endInit = "EndInit 抛：" + e2.GetType().Name + ": " + e2.Message; }
210:
211:                 bool ok = gr.GlyphIndices.Count == 3 && Math.Abs(gr.AdvanceWidths[1] - 14.328) < 1e-9;
212:                 Report("P6", "BeginInit + 属性 setter 构造 GlyphRun", ok,
213:                     ok ? $"{endInit}；GlyphIndices={gr.GlyphIndices.Count} 个，AdvanceWidths[1]={gr.AdvanceWidths[1]}"
214:                        : "setter 未生效");
```

**三个必须点名的结构事实**（都改变结论）：

1. **`EndInit` 是被调用过的**（`:208`），而且它的异常**被吞进局部变量 `endInit`**（`:209`）。
2. **真正抛的是 `:211` 的 `gr.GlyphIndices`** —— 即 **`EndInit` 之后**的读，不是 setter、也不是 `EndInit` 本身。
3. `endInit` 这个串**只在 `ok == true` 时打印**（`:213`）；失败分支（`:214`）只印"setter 未生效" ⇒ **`EndInit` 的真实异常被诊断层丢掉了**。

**盘上实测（`#16` 世代、`pc c0763fc10173e7ff` 之后的臂日志）**：`build/MilBridge/arm-logs/textlineproto.log`（`4bceceeed570ba70`，7,926 B，`2026-09-15 18:49:29`，`links=2` 硬链接）：

```
21:   FAIL  P6  BeginInit + 属性 setter 构造 GlyphRun
22:         InvalidOperationException: The operation fails because the object is not fully initialized.
23:         栈: at System.Windows.Media.GlyphRun.CheckInitialized() in /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/GlyphRun.cs:line 2344 | at System.Windows.Media.GlyphRun.get_GlyphIndices() in /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/GlyphRun.cs:line 1072 | at MilBridge.ContractProbe.Program.Main() in /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/tests/ContractProbe/Program.cs:line 211 |
```

⇒ **注册的抛点引用（`GlyphRun.cs:2344`）逐字正确**；但链上还有两格是登记里没有的：抛出点由 **`get_GlyphIndices()` `:1072`** 承载，而**触发读的那一行是 `Program.cs:211`**（不是 setter 段、不是 `EndInit`）。
同一证据在 `build/MilBridge/gen/t1b-textline.txt:24`（`013fa060df74b0e0`，09-11 16:48）里逐字复现 ⇒ **跨世代稳定**（该旧档那趟是 `通过 3 / 失败 3`，多一条 `P4` 失败；现行是 `通过 4 / 失败 2`）。

## 1.2 移植的 `GlyphRun` 在哪、怎么产生（**决定谁能修**）

**结论：`GlyphRun` 是**从上游原样编译**的，不是应用器生成/补丁出来的。** 五条证据：

| # | 证据 | 判据 |
|---|---|---|
| ① | `build/PresentationCore.Linux/PresentationCore.Linux.csproj:543`：`<Compile Include="$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/GlyphRun.cs" />` | 直接编**上游文件本体**（`$(UpstreamWpfRoot)` 默认 = `upstream/wpf/`，见 `build/Directory.Upstream.props` 的 `PropertyGroup`） |
| ② | `grep -n 'Compile Remove' build/PresentationCore.Linux/PresentationCore.Linux.csproj \| grep -i glyph` ⇒ **0 命中**（正对照：该文件 `Compile Remove` 共 **14** 条） | 没有被"移除上游 + 换成生成物" |
| ③ | `ls build/PresentationCore.Linux/*.cs` ⇒ 无任何 `GlyphRun*.cs`；`grep -rn 'GlyphRun\.cs' src/WpfGfx.Linux.Native/tools/ build/*.py build/PresentationCore.Linux/*.py` ⇒ **0 命中**（正对照：同 pattern 在 `src/WpfGfx.Linux.Native/tools/` 里对 `TextFormatterImp` 命中 `patch-presentationcore-textline-fallback.py`） | **没有任何应用器锚点**能改到它 |
| ④ | `grep -rn 'InitializationIncomplete' --include='*.cs' .`（去 `obj/`）⇒ `GlyphRun.cs:2344` + `GlyphTypeface.cs:1677` 两处抛点，**没有第三份**（`SR.g.cs:355` 是资源串） | 没有 partial/垫片覆盖 |
| ⑤ | 臂日志的栈自带 **PDB 文件+行号**（`upstream/…/GlyphRun.cs:line 2344` / `:line 1072`），而现场文件在这两行的原文正是 `throw new InvalidOperationException(SR.InitializationIncomplete);` 与 `CheckInitialized();` | 编译进产物的**就是这一份源**（行号逐格对得上） |

⇒ **不存在"应用器一行锚点修好"这条路**：`P6` 若要改语义，只能改 `upstream/**`（本仓明令只读的另一棵树）或改 `GlyphRun` 的调用方。**这条区分把 `P6` 从"PC 侧缺陷"里排除了。**

## 1.3 `CheckInitialized()` 与它看的 flag —— 精确到"哪个成员、哪个 flag"

`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/GlyphRun.cs`（`f92c28ef01e70353`，100,511 B，`2026-08-31 09:35:23`）：

**(a) 看什么 flag**（`:2340-2349`）：
```
2340:        private void CheckInitialized()
2341:        {
2342:            if (!IsInitialized)
2343:            {
2344:                throw new InvalidOperationException(SR.InitializationIncomplete);
2345:            }
2346:
2347:            // Ensure the bits are set consistently. The object cannot be in both states.
2348:            Debug.Assert(!IsInitializing);
2349:        }
```
`IsInitialized` 是 `(_flags & GlyphRunFlags.IsInitialized) != 0`（`:2378-2392`）；**同一个 flag 位只在一处被置真**：

```
452:            IsInitialized = true; // The glyphrun is completely initialized
```
—— 位于 `private void Initialize(...)`（`:302`）的**最后一行**，而 `Initialize` 的参数校验是**先决闸门**：
```
333:            if ((glyphTypeface != null) &&
334:                 (glyphIndices != null) &&
335:                 (advanceWidths != null) &&
336:                 (renderingEmSize >= 0.0) &&
337:                 (glyphIndices.Count > 0) &&
338:                 (glyphIndices.Count <= MaxGlyphCount) &&
339:                 (advanceWidths.Count == glyphIndices.Count) &&
340:                 ((glyphOffsets == null) || (...)))
...
425:             else
426:             {
427:                 ArgumentOutOfRangeException.ThrowIfEqual(renderingEmSize, double.NaN);
428:                 ArgumentOutOfRangeException.ThrowIfNegative(renderingEmSize);
429:                 ArgumentNullException.ThrowIfNull(glyphTypeface);
```

**(b) `EndInit` 走哪条**（`:2303-2338`）：
```
2315:            Initialize(
2316:                _glyphTypeface,
2317:                _bidiLevel,
...
2335:            // User should be able to fix errors that are only caught at EndInit() time. So set Initializing flag to
2336:            // false after Initialization succeeds.
2337:            IsInitializing = false;
```
⇒ `EndInit` 把字段 **`_glyphTypeface`** 直接交给 `Initialize`。

**(c) 那个成员能不能设、怎么设**（`:888-907`）：
```
891:        public GlyphTypeface GlyphTypeface
...
899:            set
900:            {
901:                CheckInitializing(); // This can only be set during initialization.
902:
903:                ArgumentNullException.ThrowIfNull(value);
904:
905:                _glyphTypeface = value;
906:            }
```
**有公开 setter，且只要求"非 null"**。

**(d) 探针那一组 setter 都是合法的**（各属性 setter 一律先 `CheckInitializing()`，`BeginInit` 已置 `IsInitializing`）：`GlyphIndices`（`:1068-1088`）、`AdvanceWidths`（`:1098-…`）、`FontRenderingEmSize`（`:874-886`）、`BaselineOrigin`（`:857-869`）、`BidiLevel`（`:913-…`）、`IsSideways`（`:944-…`）、`PixelsPerDip`（`:797-809`）。

### ⇒ 精确的"成员 / flag 失配"（这是本节的答案）

> **失败成员 = `GlyphRun.GlyphTypeface`（`GlyphRun.cs:891`，setter `:899-906`）—— 探针从头到尾没设它**（`Program.cs:198-205` 设了 7 个属性，**清单里没有 `GlyphTypeface`**）。
> **被检查但从未置真的 flag = `GlyphRunFlags.IsInitialized`（唯一直真处 `GlyphRun.cs:452`）**。它没被置真**不是**"某个 setter 忘了置 flag"，而是 **`EndInit` 调的 `Initialize(_glyphTypeface = null, …)` 在 `:429` `ArgumentNullException.ThrowIfNull(glyphTypeface)` 就抛了**，**根本走不到 `:452`**。
> 附带事实（上游**有意**的设计）：抛在 `:429` ⇒ `:2337` 的 `IsInitializing = false` 也没执行 ⇒ **对象停留在"初始化中"态**（`:2335-2336` 的注释解释：这是为了"让用户还能补参数再 `EndInit` 一次"）。所以此处 `IsInitialized=false ∧ IsInitializing=true`，`CheckInitialized()` 抛、`CheckInitializing()` 不抛。
> **探针侧的第一个（次要）缺陷**：`:209` 把这次 `ArgumentNullException` 吞进 `endInit`，而失败分支不打印它 ⇒ **登记表因此把它记成了"setter 构造失败"，而不是"缺 `GlyphTypeface`"**。

## 1.4 上游 vs 我们：**注册的判据成立吗？**

**用上游源码回答（不是用我们的移植回答）：**

* 上游**明确要求**构造 `GlyphRun` 时给出 `GlyphTypeface`：`GlyphRun.cs:46-49` 的文档注释原文「Construct an uninitialized GlyphRun object. Caller should call ISupportInitialize.BeginInit() to begin initialization and call ISupportInitialize.EndInit() to finish the initialization. / **The GlyphRun does not support all the operations until it is fully initialized.**」+ `Initialize` 的 `:429` 硬性 `ThrowIfNull`。
* 上游**没有**"`GlyphTypeface` 可省"的任何分支：`:333` 的 `if` 第一个合取项就是 `glyphTypeface != null`。
* 探针自己的文件头就写着这件事：`ContractProbe/Program.cs:3-4`「P1 `new GlyphTypeface(new Uri(file://...))` 能不能直接指向 build/fonts 里的 ttf？／（**不能的话，`GlyphRun` 就没有 `GlyphTypeface` 可喂**）」⇒ **探针作者知道 `GlyphRun` 需要 `GlyphTypeface`，但 P6 没设**（P1 恰好在本世代是红的 = `D-F2`，于是这条前提被跳过）。
* 反向（正极性）也成立、且**可从代码判定**：把 `gr.GlyphTypeface = <真 GlyphTypeface>` 补上后，`:333` 的其余合取项**在本探针的取值下全为真**（`glyphIndices.Count=3>0` 且 `≤MaxGlyphCount`；`advanceWidths.Count=3==3`；`glyphOffsets==null`；`renderingEmSize=24.0 ≥ 0` 且非 NaN）⇒ 进 `if` 分支 ⇒ `:452` `IsInitialized = true` ⇒ `:211` 的读**不再抛**。**（这一点是"读码可判"，还差一次实跑坐实 —— 见 §4 命令 C-1。）**

> **⇒ 结论：我们的移植在上游这条语义上没有任何分歧；注册判据（`WAVE17` §1 `P5` 的 `P6` 候选判据，`docs/WAVE17-PREREGISTRATION.md:61`）少了"先设 `GlyphTypeface`"这个前置条件，字面形态上游并不保证。** 判据该改写成 `KNOWN-DEFECTS.md:620` 的②那样（"**`EndInit` 之后**同一属性必须可读"）**并补上前置**。

**另一条"我们确实和上游不同"的读数（顺手核出，登记为边界）**：`Upstream` 允许 `EndInit` 失败后**补参数再 `EndInit`**（`:2335-2336` 的注释就是为这个写的）；探针没有走这条，我们也没有证据说它不成立。**未验，不声称。**

## 1.5 成本估算（`P6`）

| # | 文件:行 | 改动 | 类型 |
|---|---|---|---|
| 1 | `build/MilBridge/tests/ContractProbe/Program.cs:198-205` | 在 `BeginInit` 与 `EndInit` 之间补 `gr.GlyphTypeface = <真 GlyphTypeface>;`。**取值来源必须自己解析**（`P2` 的 `resolvedGt`（`:66`）与 `P5` 的 `g2`（`:181`）都在各自 `try` 块作用域内、`P6` 段看不见）⇒ 建议在 P6 段内用**已知可用**的 `new Typeface(new FontFamily("Noto Sans"), …).TryGetGlyphTypeface(out …)`（`P2` 实测 `GlyphCount=6196`）| **(c) 多行行为改动**（探针内 3–4 行；**不碰 `pc`/`shim`**） |
| 2 | 同文件 `:207-214` | 把 `endInit` 串**在失败分支也打印**（把吞掉的异常还给读者）—— 否则下一个人还会重复"setter 失败"的误记 | 同文件、1 行 |
| 3 | 同文件 `:211-215` | 追加**反极性断言**（见 §1.6 的 B） | 同文件、~6 行 |
| 4 | `build/MilBridge/known-red.json`（`f9843bde351029dc`）`pending.open[1]`（`:105-109`） | 该条现在写的是「门禁**明确不据此判绿也不据此判红**（范围外·诚实披露）」⇒ 修完必须**改写这条的 `state`**（否则"绿了"和"没人看"分不开 —— 纪律 37） | **主控写域**（`arm-logs/README.md` 归属节：`known-red.json`/`tline-gate.sh`/`verify-all.sh` 归主控） |
| 5 | 重取臂 | 改探针 ⇒ `textlineproto` 臂日志内容必变；该臂是**弱配对**（日志不自报仪器 sha）⇒ 按纪律 29/34 必须**重取并 `ln -f`** 硬链接进 `build/MilBridge/arm-logs/`，且 `run.sh` 不在改动清单里 ⇒ `tree_gen` 仍会显示 `same`（这正是纪律 34 的**真空档**，只能靠人重取）| 一次 `DISPLAY=:97 bash build/MilBridge/run.sh textline` |

**不需要动的**：`pc`、`shim`、`provider`、应用器、`upstream/**` ⇒ **不动 `#16` 的任何一位 sha**（`P6` 的 `provider`/`pc` 无涉）。⇒ 这一件**可以塞进本波且不引起重冻**（前提：主控接受"判据改写 + 登记表改写"）。

## 1.6 红证设计（含"它下一次还能不能变红"）

**今天会红的断言**（盘上已实测红）：
```
A: new GlyphRun() + BeginInit + [7 个 setter，无 GlyphTypeface] + EndInit(异常被吞) + 读 gr.GlyphIndices
   ⇒ InvalidOperationException: The operation fails because the object is not fully initialized.
   证据：build/MilBridge/arm-logs/textlineproto.log:21-23（`4bceceeed570ba70`，18:49:29）
```
**修后应变绿**：同一段在补了 `gr.GlyphTypeface` 之后 `EndInit` 不抛、`gr.GlyphIndices.Count == 3`、`gr.AdvanceWidths[1] == 14.328`。

**让它修后还能变红的三种突变（防"真空绿"）**：
* **A′（证明这条判据依赖的是那一行，不是别的东西）**：删掉刚补的 `gr.GlyphTypeface = …` ⇒ **必须回到现状的 `InvalidOperationException`（抛在 `:2344`、经 `get_GlyphIndices()`）**。这不只是"防回退"，它是**本件的机制证明**。
* **B（防"用放宽 `CheckInitialized` 或让 `EndInit` 无条件置真"来假绿）**：同一段里造第二个 `GlyphRun`，`GlyphIndices` 给 3 个、`AdvanceWidths` 只给 2 个（`:339` 不成立）⇒ **`EndInit` 必须抛 `ArgumentException`，且随后读 `GlyphIndices` 仍必须抛 `InvalidOperationException`**。任何"把 `IsInitialized` 提前置真/把 `CheckInitialized` 拆掉"的修法都会让这一格变绿 ⇒ **拦住它**。
* **C（防"判据自己不算话"）**：`run.sh:229` 是 `( cd … && dotnet MilBridge.ContractProbe.dll ) || true` ⇒ **探针的 `rc=1` 被丢掉**；`tline-gate.sh:429-434` 只把 `== 探针：通过 N / 失败 M ==` 收进 `rec["contractprobe"]` 并附一句"**未登记在本门禁射程，本门禁不据此判绿也不据此判红**"。⇒ **今天 P6 在自动化里"红绿都读不出来"**。要让"修后绿"有意义，必须二选一：
  * **C1（推荐，代价最小）**：把"修后的 P6 断言"作为**一条显式 expectation** 登进 `known-red.json`（`arm=textlineproto`，"不得再出现 `FAIL  P6`"），由主控重钉；
  * **C2**：去掉 `run.sh:229` 的 `|| true`（**会改 `run.sh` = 世代仪器之一 ⇒ 必须重取五臂 + 重钉 + 若臂读数变则 `drift`**，代价明显大于 C1）。
  * **不许**只把探针改绿、然后靠"日志里没有 FAIL"当通过（纪律 37：**检查器没说话不是绿**）。

## 1.7 登记更正（`P6` 段）

| 登记处 | 原文 | 裁定 |
|---|---|---|
| `docs/CURRENT-STATE.md:225`（`ContractProbe P6` 行） | 「`FAIL P6 BeginInit + 属性 setter 构造 GlyphRun`⇒ `InvalidOperationException: …` 抛在 `GlyphRun.CheckInitialized()`（`upstream/…/GlyphRun.cs:2344`，经 `get_GlyphIndices()`）」 | **抛点三格全对**（`:2344` / `:1072` / `Program.cs:211`）。**"缺陷"定性不成立** —— 不写"setter 构造失败"是对的（它确实抛在读上）。 |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:620` | 「**反极性**：`EndInit` **之后**同一属性必须可读」 | **需要补前置**："且构造时已设非 null 的 `GlyphTypeface`"。补上后它是**正确判据**。 |
| `docs/WAVE17-PREREGISTRATION.md:61` | 「`P6` = `BeginInit`/`EndInit` + setter 构造出的 `GlyphRun` 读 `GlyphIndices` **不抛**（反极性 = 现状必抛 ⇒ 今天**必红**）」 | **"今天必红"成立**（已实测），但**"不抛"不是上游保证的性质** ⇒ 作为**缺陷判据**是错的；作为**探针回归判据**（补前置后）是好的。 |
| `build/MilBridge/tools/tline-gate.sh:433` | 「其 `P1`/`P4`/`P6` 是已知宿主侧缺口」 | **对本世代陈旧**：现行日志是 `通过 4 / 失败 2` = **P1 + P6**，**`P4` 已 `PASS`**（`textlineproto.log:17-18`）。旧档 `build/MilBridge/gen/t1b-textline.txt:26` 是 `通过 3 / 失败 3`（那一代的 P4 确实红，栈在 `:24`）⇒ 该文案是**世代残留**，不是错数。**建议**：该句改成从 `check_status` 现算，别写死编号。 |

---

# 2. D-2 · `D-F2`

## 2.1 精确调用链（`GlyphTypeface(Uri)` → 放弃点）

**(1) 入口**（`upstream/…/Media/GlyphTypeface.cs`，`fdd48459851afd5d`，77,032 B，`2026-08-31 09:35:23`）：
```
55:         public GlyphTypeface(Uri typefaceSource) : this(typefaceSource, StyleSimulations.None)
64:         public GlyphTypeface(Uri typefaceSource, StyleSimulations styleSimulations)
65:         {
66:             Initialize(typefaceSource, styleSimulations);
```
实测栈逐字（`arm-logs/textlineproto.log:10`，`P1`）：
```
FileFormatException: File 'file:///…/build/fonts/NotoSans-Bold.ttf' has an invalid file format.
 栈: at System.Windows.Media.GlyphTypeface.Initialize(Uri typefaceSource, StyleSimulations styleSimulations) in …/GlyphTypeface.cs:line 145
   | at System.Windows.Media.GlyphTypeface..ctor(Uri typefaceSource, StyleSimulations styleSimulations) in …/GlyphTypeface.cs:line 66
   | at System.Windows.Media.GlyphTypeface..ctor(Uri typefaceSource) in …/GlyphTypeface.cs:line 55
```

**(2) `Initialize` 的关键 12 行**（同上文件）：
```
136:            MS.Internal.Text.TextInterface.FontCollection fontCollection = DWriteFactory.GetFontCollectionFromFile(fontSourceUri);
137:            using (MS.Internal.Text.TextInterface.FontFace fontFaceDWrite = DWriteFactory.Instance.CreateFontFace(fontSourceUri,
138:                                                                                                                  (uint)faceIndex,
139:                                                                                                                  (MS.Internal.Text.TextInterface.FontSimulations)styleSimulations))
140:            {
141:                // This is the same behavior as 3.*. If we pass, for example, a path to a composite font file then a 
142:                // FileFormatException will be thrown!
143:                if (fontFaceDWrite == null)
144:                {
145:                    throw new System.IO.FileFormatException(typefaceSource);             
146:                }
147:                _font = fontCollection.GetFontFromFontFace(fontFaceDWrite);
```
⇒ **抛点 `:145` 只有一个含义：`CreateFontFace(...)` 返回了 `null`**。判据是"**第一帧就是抛出点**"（栈的 `at` 第一行 = 异常被 `throw` 的那一帧）：若是 `CreateFontFace` **内部**抛出的 `FileFormatException`（shim 的 `:204`/`:221` 就是这种），第一帧会落在 `PresentationCore.Factory.Linux.Factory.CreateFontFace(...)`，而不是 `GlyphTypeface.Initialize`。
⚠️ 口径披露：探针的 `Short()`（`Program.cs:236-242`，`Math.Min(3, frames.Length)`）**只打前 3 帧** ⇒ 这三帧**不能**用来排除"更深处还有别的帧"，只能用来定位**抛出点**（第一帧）与**调用者链**。

**(3) `GetFontCollectionFromFile` 这一侧（上游，编进 `pc`）**：`upstream/…/MS/internal/FontCache/DWriteFactory.cs`（`1b21da71989e42b1`，4,459 B）：
```
55:        private static Text.TextInterface.FontCollection GetFontCollectionFromFileOrFolder(Uri fontCollectionUri, bool isFolder)
57:            if (Text.TextInterface.Factory.IsLocalUri(fontCollectionUri))
60:                if (!isFolder)
62:                    // get the parent directory of the file.
63:                    localPath = Directory.GetParent(fontCollectionUri.LocalPath).FullName + Path.DirectorySeparatorChar;
...
81:                else
83:                    return DWriteFactory.Instance.GetFontCollection(new Uri(localPath));
...
99:        internal static Text.TextInterface.FontCollection GetFontCollectionFromFile(Uri fontCollectionUri)
101:            return GetFontCollectionFromFileOrFolder(fontCollectionUri, false);
```

**(4) 我们这侧的 `Factory.GetFontCollection` / `CreateFontFace`** = `build/shims/PresentationCore.Factory.Linux.cs`（`125cfaa3c9851cfd`，23,423 B，`2026-09-11 09:32:52`）：
```
270:        internal FontCollection GetFontCollection(Uri uri)
...
280:                if (Directory.Exists(localPath))
281:                    return new FontCollection(LinuxFontCollection.FromDirectory(localPath, recurse: true));
283:                if (File.Exists(localPath))
...
288:                    return new FontCollection(LinuxFontCollection.FromDirectory(parent, recurse: false));
```
```
159:        internal FontFace CreateFontFace(Uri filePathUri, uint faceIndex, FontSimulations fontSimulationFlags)
...
170:                if (File.Exists(path))
172:                    try
174:                        LinuxFontFace linuxFace = LinuxFontFace.FromFile(path, (int)faceIndex, (int)fontSimulationFlags);
...
195:                        if (!CanRoundTripFace(filePathUri, linuxFace))
196:                        {
197:                            return null;
198:                        }
200:                        return new FontFace(linuxFace);
```
⇒ **`CreateFontFace` 里唯一的 `return null`（`:197`）就是这个守卫**。守卫本体：
```
335:        private static bool CanRoundTripFace(Uri filePathUri, LinuxFontFace linuxFace)
337:            try
339:                MS.Internal.Text.TextInterface.FontCollection collection =
340:                    MS.Internal.FontCache.DWriteFactory.GetFontCollectionFromFile(filePathUri);
342:                if (collection == null || collection.LinuxCollection == null) return false;
344:                return collection.LinuxCollection.GetFontFromFontFace(linuxFace) != null;
346:            catch
348:                return false;
```

**(5) 反查为什么必失败**（provider，`build/DirectWrite.Linux/Provider/LinuxFontCollection.cs`，`e07ac1329fec10fa`，21,766 B，`2026-09-15 12:40:13`）：
```
441:        /// 上游 FontCollection::GetFontFromFontFace：从一个字体面反查它所属的 Font。
442:        /// 找不到返回 null（上游此处会走 GetMatchingFonts 兜底，我们不猜）。
444:        public LinuxFont GetFontFromFontFace(LinuxFontFace fontFace)
446:            if (fontFace == null) return null;
448:            foreach (LinuxFontFamily family in _families)
450:                foreach (LinuxFont font in family.Items)
452:                    if (ReferenceEquals(font.Typeface, fontFace.Typeface) && font.FaceEntry.FaceIndex == fontFace.FaceIndex)
453:                        return font;
457:            return null;
```
而两条造面路径**各自新建 `SKTypeface`**：`build/DirectWrite.Linux/Provider/LinuxFontFace.cs:136` `SKTypeface typeface = SkiaFontDataCache.OpenFace(path, faceIndex);`，而 `build/DirectWrite.Linux/Provider/SkiaFontDataCache.cs:91-95`：
```
 91:        internal static SKTypeface OpenFace(string path, int faceIndex)
 92:        {
 93:            SKData data = Get(path);
 94:            return data == null ? null : SKTypeface.FromData(data, faceIndex);
 95:        }
```
⇒ **缓存的是 `SKData`（每路径一份），不是 `SKTypeface`**；`SKTypeface.FromData` 每次都造一个新对象 ⇒ **`ReferenceEquals` 永远为 false**（除非 SkiaSharp 内部有实例去重 —— 见 §4 的 C-4）。

**盘上实测（`~/wfp-runs/ab13/A/compositefont-before.txt`，`ce226ca75b493047`，14,254 B，`2026-09-15 10:35:04`）**：
```
102:    FromFile(path) 两次是否同一个 SKTypeface 实例 : False
103:    FromDirectory(parent).GetFontFromFontFace(FromFile(path)) = **null**
105:    DWriteFactory.GetFontCollectionFromFile(uri) → MS.Internal.Text.TextInterface.FontCollection
106:    真链 GetFontFromFontFace(face) = **null**
107:    ⇒ 补丁「追加 1」的守卫判据（CanRoundTripFace）= false ⇒ 返回 null ⇒ 上游抛 FileFormatException
```
⚠️ **配对披露（纪律 35）**：这份日志的 mtime 是 `10:35`，**早于**现行 provider（`12:40:13`）与现行 `pc`（`18:38`）⇒ 它**不能当作现行件的读数**；它的价值是**证明了这条机制的形态**（并给出 `GetFontCollectionFromFile` 非 null 的直接读数）。**现行件的对应读数不存在**（该探针此后没再留档，见 §4 的 C-2）。

## 2.2 到底是什么缺失：(a) / (b) / (c)

**裁定：(c) —— 导出存在、也不是桩，而是"调用形态我们这侧兑现不了"。** 逐条给证据：

* **不是 (a) 缺导出**：`CreateFontFace` **在**（`PresentationCore.Factory.Linux.cs:159`，另有 2 参重载 `:150`），**且真的能造出面** —— `LinuxFontFace.FromFile(path, faceIndex, simFlags)` 在 `:174` 被调用，而这条 API 在别处**已被实测可用**：`arm-logs/textlineproto.log:19-20` `PASS P5 DWF Font → GlyphTypeface(内部 ctor) → **真 GlyphTypeface**` / `GlyphCount=3884 Version=2.015 Baseline=1.0690`。**没有一条新导出要加**（也就没有 native/ABI 面的工作）。
* **不是 (b) 桩**：这条路径上**没有 `NotWired.Throw` / `PlatformNotSupportedException`**；`return null` 是**有注释、有判据的"诚实失败"**（`:176-194` 的长注释逐字写着"**不伪造空面**"、"若将来 provider 这条反查能对上…**本守卫自动放行**，这里一个字都不用改"）。桩会抛，这里不抛。
* **(c) 的准确形态**：**上游 `GlyphTypeface.Initialize` 要求的面↔Font 反查，在我们分层实现里按 `SKTypeface` **引用相等**判定**（`LinuxFontCollection.cs:452`），而面由两个互不相识的构造点各造一份 ⇒ 反查恒 `null` ⇒ 守卫 `:195` 返回 `null` ⇒ 上游 `:143-145` 抛 `FileFormatException`。**这是"调用形态兑现不了"，不是"功能没写"。

**⚠️ 对登记口径的更正（`KNOWN-DEFECTS.md:610`）**：原文「上游这条走 `DWriteFactory.GetFontCollectionFromFile` + `CreateFontFace` ⇒ **在我们这一侧对"文件字体"不可用（DWrite"从文件取集合"未接）**」。**"从文件取集合未接"不成立**：
* 直接读数：`compositefont-before.txt:105` `DWriteFactory.GetFontCollectionFromFile(uri) → MS.Internal.Text.TextInterface.FontCollection`（**非 null**）；
* 代码：`DWriteFactory.cs:99-101` → `Factory.GetFontCollection`（`PresentationCore.Factory.Linux.cs:270-289`）**对目录与文件两种输入都实现**，且 `:285-288` 专门有"直接给一个文件 URI"的兜底；
* 同一份读数里真正为 `null` 的是**下一格**（`:106` `真链 GetFontFromFontFace(face) = **null**`）。
⇒ **正确写法**："集合接了、面也造得出；缺的是**面 → 所属 Font 的反查对齐**（身份判据按引用相等）。"这条更正把工作量从"接一条整链"缩到"改一处身份判据"，但它**不**把风险缩小（见 §2.4）。

## 2.3 调用点清单（**核实并更正**旧登记）

检索式（可复算）：
```
grep -rn 'new GlyphTypeface(new Uri\|new GlyphTypeface(uri\|new GlyphTypeface(sourceUri\|new GlyphTypeface(uriText)' --include='*.cs' . | grep -v '/obj/' | grep -v 'refs/'
```
**命中 16 行**（其中 6 行是注释/文案，10 行是构造点；**无 `refs/`、`staging/` 归档副本命中** ⇒ 归档里没有这一族）。

**A. 我们的宿主/探针（6 个文件 / 7 个构造点）**

| 文件:行 | 原文片段 | 备注 |
|---|---|---|
| `build/MilBridge/tests/ContractProbe/Program.cs:48` | `gt = new GlyphTypeface(new Uri(fontPath));` | `P1`，**无 catch 吞**，红 = 注册的 `D-F2` |
| `build/MilBridge/tests/CoverageProbe/Program.cs:716` | `if (gt == null) { try { gt = new GlyphTypeface(new Uri("file://" + fontPath)); } catch (Exception) { } }` | `--tab-oracle`；**先试 `MakeTypeface("Liberation Sans")` → `TryGetGlyphTypeface`**，失败才落到这条；`gt==null` ⇒ `return 2` |
| 同上 `:931` | 同形（`Noto Sans` 那条） | `FBCHK` 自检；`gt==null` ⇒ `Console.WriteLine("FBCHK 字体解析失败"); return 2;` |
| 同上 `:1285` | 同形（`Liberation Sans`） | `--tab-lines-oracle`（**门禁三支 tab 臂的真正仪器**）；`gt==null` ⇒ `TAB_LINES 字体解析失败` + `return 2` |
| `build/MilBridge/tests/CompositeFontProbe/Program.cs:336` | `GlyphTypeface gt = new GlyphTypeface(new Uri(_fontPath));` | **⚠️ 旧登记漏了这一处**（`S6`，判据是"最低要求 = 诚实失败，不是 NRE"，`Program.cs:333`） |
| `build/DirectWrite.Linux/FontEntryClosedLoop/Program.cs:67` | `var gt = new GlyphTypeface(new Uri(fontFile));` | A 段；另有 A2 段**逐格拆链**（`:78-100`：`GetFontCollectionFromFile` → `CreateFontFace(uri)` → `GetFontFromFontFace`），**就是为这条缺陷写的诊断器**（无留档日志，见 §4 C-2） |
| `tests/parity/windows/font-fallback/src/Program.cs:309` | `var gt = new GlyphTypeface(new Uri("file:///" + NotoFile.Replace('\\','/')));` | **Windows 真机 oracle 宿主**（此文件属 `tests/parity/windows/**`）⇒ **在我们这棵树的运行时不受影响** |

**B. 进产物的生产代码（3 处 —— 旧登记一处都没写）**

| 文件:行 | 原文片段 | 编译进哪 |
|---|---|---|
| `build/shims/PresentationCore.HbTextLine.cs:3810` | `try { return new GlyphTypeface(new Uri(uriText)); } catch (Exception) { return null; }` | **`pc`（并随 `HbShimSrc` 编进三支 tab 臂探针与 `TextLineProto`）** —— 这是**我们自己的唯一生产调用点**，位于 `FaceFromRef`（`:3787`）的**第二顺位**（第一顺位 = `:3801-3806` 族名 → `Typeface` → `TryGetGlyphTypeface`） |
| `upstream/…/PresentationFramework/System/Windows/Documents/Glyphs.cs:315` | `glyphRunProperties.glyphTypeface = new GlyphTypeface(uri, StyleSimulations);` | `pf`（`PresentationFramework.Linux.csproj:893` 编入）—— XAML `<Glyphs>` 元素 |
| `upstream/…/ReachFramework/Serialization/XpsFontSubsetter.cs:613` | `GlyphTypeface glyphTypeface = new GlyphTypeface(sourceUri);` | Reach（`ReachFramework.Linux.csproj:165` 编入） |

**计数正对照（纪律 25）**：同一 pattern 用在**别的构造形态**上同样有命中 —— `grep -rn 'new GlyphTypeface(bestMatch\|new GlyphTypeface(font)\|new GlyphTypeface(bestStyleTypeface'` ⇒ 命中 `upstream/…/PhysicalFontFamily.cs:120/182/204`（**内部 `GlyphTypeface(Font)` 构造**，与 `D-F2` 无关，今天**可用**，正是 `P5`/`A1` 走的那条）。⇒ 该 pattern **不是"什么都命中"**，也就不是"什么都没命中"。

**更正后的口径**：`D-F2` 的调用点 = **6 个宿主文件 / 7 处** + **1 处我们的生产代码（shim）** + **2 处上游生产代码（PF/Reach）**。旧登记（`KNOWN-DEFECTS.md:612`：`CoverageProbe ×3、ContractProbe、FontEntryClosedLoop、真机 oracle 宿主`）**方向对、但有漏**：漏 `CompositeFontProbe`、漏 `shim:3810`、漏上游两处。**其中 `shim:3810` 的遗漏最要紧**：它把 `D-F2` 从"探针不方便"变成"**有一条生产路径今天静默关闭、修好后会自动打开**"。

**顺带一条"计数器自己是哑的"（纪律 37 家族）**：`FaceFromRef` 失败时调 `HbFallbackDiag.NoteSegmentFaceUnresolved()`（`shim:3823`），该计数声明在 `shim:1275`；**全仓只有 3 处出现**（声明 `:1275`、自增 `:1276`、调用 `:3823`）—— **`SummaryFragment()`（`:1344-1379`）与 `DetailFragment()`（`:1382-1400`）都不打印它**（正对照：同一区间打印 `segmentFaceResolveCalls`，见 `:1366`）。⇒ **"不许静默"的计数器本身从不发声**：`FaceSlot=-1` 的规模**没有任何现成仪器看得见**。这直接决定了 §2.4 的风险评估。

## 2.4 成本与爆炸半径

**最小修法 F1（推荐）**：把身份判据从"SKTypeface 引用相等"换成"**（文件路径, 面下标）相等**"。

| # | 文件:行 | 一行描述 | 类型 |
|---|---|---|---|
| 1 | `build/DirectWrite.Linux/Provider/LinuxFontCollection.cs:452` | `ReferenceEquals(font.Typeface, fontFace.Typeface) && font.FaceEntry.FaceIndex == fontFace.FaceIndex` → `string.Equals(font.FaceEntry.FilePath, fontFace.SourcePath, StringComparison.Ordinal) && font.FaceEntry.FaceIndex == fontFace.FaceIndex`（成员都存在：`FontFaceEntry.FilePath`/`FaceIndex` = `FaceSelector.cs:47/50`；`LinuxFontFace.SourcePath`/`FaceIndex` = `LinuxFontFace.cs:73/79`） | **(a) 无注释的语义改动（1 行）** |
| 2 | `build/DirectWrite.Linux/Tests/ProviderShapeTests.cs:143-157` | **这条测试今天把缺陷当期望**：`GetFontFromFontFace_RoundTrips` 的负断言写 `using var other = LinuxFontFace.FromFile(TestLayout.FontPath(TestLayout.RegularFile)); Assert.Null(_fixture.Collection.GetFontFromFontFace(other));`，注释称"外来的面（**不在集合里**）" —— **而该文件就在集合里**（同文件 `:42-43` 断言集合的 4 个文件名**含 `NotoSans-Regular.ttf`**，`:39` 断言 `FileNames.Count == 4`）。改成用**临时目录里的副本**（该文件 `:83` 已有 `File.Copy(TestLayout.FontPath(…), Path.Combine(dir,"good.ttf"))` 的现成手法）| **(c) 多文件行为改动**（测试语义必须改） |
| 3 | `build/shims/PresentationCore.Factory.Linux.cs:195-198 / 335-350` | **不改**：守卫 `:342-344` 在 F1 之后自然放行（其注释 `:193-194` 明写"若将来 provider 这条反查能对上…本守卫自动放行"）。**留着的价值** = 同一守卫继续覆盖"面→Font 对不上"这一类回归 | 无改动（**但必须知情**） |
| 4 | `build/shims/PresentationCore.HbTextLine.cs:3810` | **不改代码**，但**行为会变**：`FaceFromRef` 的第二顺位从"恒失败"变成"可能成功" ⇒ `FaceSlot` 由 `-1` 变 `i` ⇒ **回退 run 的面集合变**。`+CJK` 34 例 / `Extent` 余差 95 / 三支 tab 臂 / 应用门禁的 `drawn/colors` **都可能位移** | **(c) 多文件影响面**（"我没改并集的代码，但我改了并集的**输入**"—— 引用 `CURRENT-STATE.md:191` 里 T1d 的原话形态） |
| 5 | `provider` 位 | `provider` 是**九位之一**（`#16` = `9aa0d744802aaa31`）⇒ **`#16` 基线作废**（`CURRENT-STATE.md:95`：「任何一位变了 ⇒ 本基线作废，必须重跑门禁并重冻」）| **(c)** |
| 6 | `pc` / `pf` | `build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt` 的**维度 B（peer）**里逐字列着 `peer=9aa0d744802aaa31  build/DirectWrite.Linux/Provider/bin/Debug/DirectWrite.Linux.Provider.dll` ⇒ **provider 字节进 `pc` 的输入哈希** ⇒ `pc` 几乎必然跟着变，`pf`/`reach` 是环成员（`CURRENT-STATE.md:98-102`）⇒ **一改就是"重取五臂 + 重钉登记表 + 重冻 + 两趟应用门禁 + `verify-all`"的整趟波** | **(c)** |

**成本评述（按实测而非口味）**：
* 代码本体**极小**（1 行 + 1 个测试）。
* 但它**必然**翻转九位之一 ⇒ 按本项目纪律（纪律 1/34/36、`CURRENT-STATE.md:95`）**必须整趟波 + 重冻**；且 `shim:3810` 与 `CoverageProbe` 三处回退、`PF`/`Reach` 两个上游消费者同时被"点亮"，**位移面正是 `WAVE17` §2 明文要保护的那一片**（`D-E1` 与 `Extent` 归因、`D-F1c`①c 的段数读数）。
* **风险量级"不可测"这件事本身是结论**：能把 `D-F2` 影响面量出来的计数器 `SegmentFaceUnresolved` **从不打印**（§2.3 末）⇒ 修前**无法**给出"会动多少条"的预测；这与 `WAVE17` 对 `P2`/`P3` 要求的"预测位移先写死"相冲突 —— **一个无法先写死预测位移的改动，不该塞进一个要求逐位归因的波。**

## 2.5 建议

**`NEEDS-DEDICATED-TRACK`（另立专项），本波不夹带。** 三条依据：
1. **必然重冻**（`provider` + 很可能 `pc`/`pf`）⇒ 与"本波只落 `P1`/`P2`/`P3`/`P4` 四件、一次重冻"的波形态冲突（`docs/WAVE17-PREREGISTRATION.md:16` 的 G2 与 §3）。
2. **预测位移写不出来**（计数器哑），而本波对每一件的普遍纪律是"射程外读数逐位不动 + 每一处位移都被归因"（`:20`）。
3. **它有一条静默的生产消费者**（`shim:3810`）与**一条把缺陷当期望的现有测试**（`ProviderShapeTests:155-156`）⇒ 需要的是"改 provider + 改测试 + 重取五臂 + 重新归因 `Extent`/`+CJK`"的**整条链**，不是一件。
   **专项启动时的第一批动作（建议写进派单）**：① 先只加**读数**（把 `SegmentFaceUnresolved`/`RunFaceSlotMissing` 打进 `SummaryFragment()`，`shim` 侧 1 行）⇒ 在**不改语义**的前提下量出"今天有多少个段面掉到 `-1`"；② 再改 `:452` 那一行；③ 重取五臂与 `run.sh tline`，逐族归因。**"先有读数、后有修法"** —— 这正是 `#16` 反复示范的形态。

## 2.6 红证（`D-F2`）

**今天会红的断言**（盘上已实测）：
```
new GlyphTypeface(new Uri("file:///…/build/fonts/NotoSans-Bold.ttf"))
  ⇒ FileFormatException: File '…' has an invalid file format.
  证据：arm-logs/textlineproto.log:8-10（`4bceceeed570ba70`）
```
**修后必须同时成立**（`KNOWN-DEFECTS.md:614` 的候选 + 补强）：
* ① 构造**成功**；② `gt.GlyphCount > 0`（`NotoSans-Regular.ttf` = `f3961a9cde016d41`、431,364 B、`00010000` 开头 = 纯 TTF，见 §3）；③ **往返一致**：`gt.FontUri.LocalPath == 输入路径`；④ `gt.FamilyNames.Count > 0`；⑤ `new GlyphTypeface(uri, StyleSimulations.None)` 同结论。
**防真空（修后必须能再变红）**：
* ⑥ **指向非字体文件**（例：`build/fonts/SHA256SUMS`）⇒ **仍必须抛 `FileFormatException`**（证明判据不是"恒真"）。
* ⑦ **同一目录里的另一个面**（例：集合里的 `NotoSans-Bold.ttf` 造出的面）**必须反查到它自己的 Font，而不是第一个**（证明路径匹配没有退化成"匹配任意"）。
* ⑧ **真正外来的面**（拷贝到临时目录的副本，`ProviderShapeTests.cs:83` 的手法）⇒ `GetFontFromFontFace` **必须 `null`**（这是更正后的 `:155-156`）。
* ⑨ **`StyleSimulations` 的边界（F1 的已知代价，必须在判据里点名）**：F1 的身份 = (路径, 面下标)，**不含模拟标志**；而 provider 侧 `LinuxFont.SimulationFlags` 是**硬编码 0**（`build/DirectWrite.Linux/Provider/FontModel.cs:171-172`：`/// 上游 Font::SimulationFlags。本工程不做字体级别名模拟 → None(0)。 public int SimulationFlags => 0;`），上游 `GlyphTypeface(Font)` 却是**从 `font.SimulationFlags` 反推**（`GlyphTypeface.cs:75` `StyleSimulations styleSimulations = (StyleSimulations)font.SimulationFlags;`）⇒ 修好后 `new GlyphTypeface(uri, StyleSimulations.BoldSimulation)` 会"**成功但拿到未模拟的度量**"。**判据要么显式拒绝这种组合（抛 `ArgumentException`），要么显式接受并断言 `StyleSimulations` 的取值** —— **不许**静默给一个不同源的 `_font`。**这一格今天是"未验"，不是"绿"。**

---

# 3. 读数表（lane=R17B｜`2026-09-15T15:26:08Z`｜`loadavg=1.68 1.27 0.64`｜`mem_available=4011 MB`｜`kernel=6.8.0-138-generic`）

**口径**：sha256 前 **16** 位小写十六进制；size = 字节；mtime = `stat -c '%y'`（本地时区 +0800）。

| 文件 | sha16 | size | mtime |
|---|---|---|---|
| `docs/WAVE17-PREREGISTRATION.md` | `8c36cedb891a263d` | 13,522 | 2026-09-15 23:20:22 |
| `docs/CURRENT-STATE.md` | `5f098102a7e239ce` | 144,199 | 2026-09-15 23:19:48 |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `cb6af309c88136a4` | 113,244 | 2026-09-15 19:01:50 |
| `build/MilBridge/tests/ContractProbe/Program.cs` | `bd4f4958578daeaa` | 13,165 | 2026-09-10 19:46:38 |
| `build/MilBridge/arm-logs/textlineproto.log` | `4bceceeed570ba70` | 7,926 | 2026-09-15 18:49:29 |
| `build/MilBridge/arm-logs/tline.log` | `89ad10ac614b4d3b` | 21,501 | 2026-09-15 18:52:42 |
| `build/MilBridge/arm-logs/tab-zero.log` | `b9d81590f3fcd800` | 11,274 | 2026-09-15 18:48:00 |
| `build/MilBridge/arm-logs/tab-anchor.log` | `99d72b385fe23a90` | 43,563 | 2026-09-15 18:49:12 |
| `build/MilBridge/arm-logs/tab-rtl.log` | `419e8aaa9c72a9a0` | 8,583 | 2026-09-15 18:49:19 |
| `build/MilBridge/arm-logs/README.md` | `6924605fab87660e` | 6,880 | 2026-09-15 16:52:15 |
| `build/MilBridge/known-red.json` | `f9843bde351029dc` | 28,734 | 2026-09-15 18:53:40 |
| `build/MilBridge/tools/tline-gate.sh` | `b37a5c9f55ae71a4` | 40,181 | 2026-09-15 16:44:01 |
| `build/MilBridge/run.sh` | `3e513e88a4fa4ec9` | 16,450 | 2026-09-15 16:53:13 |
| `build/MilBridge/gen/t1b-textline.txt` | `013fa060df74b0e0` | 7,550 | 2026-09-11 16:48:05 |
| `build/MilBridge/tests/CoverageProbe/Program.cs` | `a8727a5bed6bf049` | 108,127 | 2026-09-15 17:24:40 |
| `build/MilBridge/tests/CompositeFontProbe/Program.cs` | `6cf17867abddcd47` | 32,437 | 2026-09-11 13:54:21 |
| `build/MilBridge/tests/TextLineProto/Program.cs` | `34e31d95b29a1bd1` | 25,312 | 2026-09-15 11:15:13 |
| `build/DirectWrite.Linux/FontEntryClosedLoop/Program.cs` | `616e29ea6b03e82e` | 7,904 | 2026-09-10 20:02:26 |
| `build/DirectWrite.Linux/Provider/LinuxFontCollection.cs` | `e07ac1329fec10fa` | 21,766 | 2026-09-15 12:40:13 |
| `build/DirectWrite.Linux/Provider/LinuxFontFace.cs` | `69875ecde79b22d3` | 31,491 | 2026-09-15 12:40:13 |
| `build/DirectWrite.Linux/Provider/SkiaFontDataCache.cs` | `054ab29d10fc74e9` | 5,599 | 2026-09-15 12:40:30 |
| `build/DirectWrite.Linux/Provider/FaceSelector.cs` | `2422140ab8bce2bf` | 8,115 | 2026-09-10 15:01:01 |
| `build/DirectWrite.Linux/Provider/FontModel.cs` | `2118b673c2283363` | 14,384 | 2026-09-10 15:10:37 |
| `build/DirectWrite.Linux/Tests/ProviderShapeTests.cs` | `4ac68b237a72523c` | 17,132 | 2026-09-10 15:13:04 |
| `build/DirectWriteForwarder.Linux/ManagedSurface.cs` | `80627fe4a6eb8075` | 66,491 | 2026-09-10 15:17:52 |
| `build/shims/PresentationCore.Factory.Linux.cs` | `125cfaa3c9851cfd` | 23,423 | 2026-09-11 09:32:52 |
| `build/shims/PresentationCore.HbTextLine.cs` | `bc04c05ab6d8d82a` | 275,765 | 2026-09-15 18:25:25 |
| `build/PresentationCore.Linux/PresentationCore.Linux.csproj` | `e2558faa0cc6b5d1` | 205,471 | 2026-09-15 18:37:23 |
| `build/PresentationCore.Linux/SR.g.cs` | `66cc785da6da9f87` | 125,389 | 2026-09-15 18:37:17 |
| `build/fonts/NotoSans-Regular.ttf` | `f3961a9cde016d41` | 431,364 | 2026-08-30 17:25:44 |
| `upstream/…/PresentationCore/System/Windows/Media/GlyphRun.cs` | `f92c28ef01e70353` | 100,511 | 2026-08-31 09:35:23 |
| `upstream/…/PresentationCore/System/Windows/Media/GlyphTypeface.cs` | `fdd48459851afd5d` | 77,032 | 2026-08-31 09:35:23 |
| `upstream/…/PresentationCore/MS/internal/FontCache/DWriteFactory.cs` | `1b21da71989e42b1` | 4,459 | 2026-08-31 09:35:23 |
| `tests/parity/windows/font-fallback/src/Program.cs` | `e5217bcd6d7c9d78` | 37,695 | 2026-09-14 22:05:00 |
| `$HOME/wfp-runs/ab13/A/compositefont-before.txt` | `ce226ca75b493047` | 14,254 | 2026-09-15 10:35:04 |

**九位（引用 + 本轮的只读现场复核）**：`pc c0763fc10173e7ff`｜`provider 9aa0d744802aaa31`｜`hbtextline bc04c05ab6d8d82a`（`CURRENT-STATE.md:9-10`）。**本轮现场重算了两件**（纯 `sha256sum`，未构建）：
* `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` = **`c0763fc10173e7ff`**（4,194,816 B、`2026-09-15 18:38:14`）⇒ **与 `#16` 表头逐位相符**；
* `build/shims/PresentationCore.HbTextLine.cs` = **`bc04c05ab6d8d82a`**（275,765 B、`18:25:25`）⇒ 相符。
其余七位**未重算**（不是"未变"，是"没量"）。⇒ 本车道**没有动过冻结件**的这一条由此从"声称"变成"两件实测 + 七件未量"。

**臂日志的硬链接自证**：五份 `arm-logs/*.log` 本轮现场复算 `stat -c '%h'` **全为 `links=2`**（硬链接，符合 `arm-logs/README.md` 的约定与 `CURRENT-STATE.md:325` 的记法）⇒ 它们的 mtime 是**原始日志的** mtime，门禁的弱配对时间序判据（纪律 29）未被架空。

---

# 4. 没有构建就定不了的，与能定它的确切命令

| # | 定不了的事 | 确切命令（**本波不许跑**，留作后续车道的入口） |
|---|---|---|
| C-1 | `P6` 补 `GlyphTypeface` 之后是否真的 `EndInit` 通过 + `GlyphIndices` 可读（我目前只有"读码可判"） | `cd build/MilBridge/tests/ContractProbe && dotnet build -c Release && (cd bin/Release && dotnet MilBridge.ContractProbe.dll)` ⇒ 期望 `通过 5 / 失败 1`（仅 `P1`=D-F2 红）。**别用 `run.sh textline`**（它带 `\|\| true` 吞 rc） |
| C-2 | `D-F2` 的**现行件**逐格链（`GetFontCollectionFromFile` / `CreateFontFace(uri)` / `GetFontFromFontFace` 各自 `null` 与否）—— 手上只有 10:35 那份**旧件**读数 | `cd build/DirectWrite.Linux/FontEntryClosedLoop && dotnet build -c Release && (cd bin/Release && dotnet DirectWrite.Linux.FontEntryClosedLoop.dll)` ⇒ 看 `A=`/`A2-coll`/`A2-face`/`A2-font` 四行逐格 |
| C-3 | `SegmentFaceUnresolved` 的**规模**（`D-F2` 影响面的上界）—— 该计数器从不打印 | ①（只加读数、不改语义）`build/shims/PresentationCore.HbTextLine.cs:1366` 后追加 `sb.Append(" segUnresolved=").Append(SegmentFaceUnresolved).Append(" runFaceSlotMissing=").Append(RunFaceSlotMissing);`；② 重建三个内联 shim 的探针 + `run.sh tline`；③ 读 `[T1D_PROBE] counters:` 行（`CoverageProbe/Program.cs:485`） |
| C-4 | `SKTypeface.FromData` 是否**在 SkiaSharp 内部**对同 `SKData` 去重（若去重，`ReferenceEquals` 就可能成立 ⇒ §2.1 的机制判定要改） | `dotnet run` 一个 5 行程序：`var d=SKData.Create(p); var a=SKTypeface.FromData(d,0); var b=SKTypeface.FromData(d,0); Console.WriteLine(ReferenceEquals(a,b));`（对照：`SKTypeface.FromFile(p,0)` 两次） |
| C-5 | `provider` 改动是否**必然**改 `pc` 的字节（我引的是 `ARTIFACT-SRC-FP` 的 peer 机制自述 + `#15` 波的同向位移，**不是实测**） | 改 `provider` 一行 → `dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj` → `sha256sum build/PresentationCore.Linux/bin/Debug/PresentationCore.dll \| cut -c1-16`，与 `c0763fc10173e7ff` 比 |
| C-6 | 三支 tab 臂与 `textlineproto` 在 `D-F2` 修后是否逐字节不动（我只能**推理**"它们的字体解析走的是 `TryGetGlyphTypeface` 主路、回退语句没被执行"，依据是臂日志里有 469 行 `TAB_LINES CASE` ⇒ 探针没有在 `:717` `return 2`）| 按 `arm-logs/README.md`「新世代怎么重绿」重取四臂 + `run.sh tline`，与 `#16` 的五份日志逐字节 `cmp` |
| C-7 | 应用门禁（`drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`）在 `D-F2` 修后是否位移 | `WPTD_RUN_DIR=… WPTD_BASELINE_OUT=… bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 90 --tier both`（先确认常驻 `:97`，纪律 30） |

---

# 5. 我撤回了 / 更正了的登记项（明细）

1. **`KNOWN-DEFECTS.md:610`**「DWrite '从文件取集合' 未接」→ **撤回**：集合已接（`compositefont-before.txt:105` 非 null；代码 `DWriteFactory.cs:99-101` → shim `:270-289`）。真缺口 = **面→Font 反查的身份判据**（`LinuxFontCollection.cs:452`）。**工作量因此从"接一条链"缩到"改一行"**，但**风险不缩**（§2.4）。
2. **`WAVE17-PREREGISTRATION.md:61` 的 `P6` 判据**「…读 `GlyphIndices` 不抛（反极性 = 现状必抛 ⇒ 今天必红）」→ **"今天必红"对**（实测），但**"应不抛"不是上游性质**：上游要求先设非 null 的 `GlyphTypeface`（`GlyphRun.cs:429`）。⇒ 判据须补前置，否则它是一条**永不成立的判据**。
3. **`KNOWN-DEFECTS.md:612` / `CURRENT-STATE.md:206` 的 `D-F2` 调用点清单** → **补 3 处**：`CompositeFontProbe/Program.cs:336`、`shim:3810`（生产代码）、上游 `Glyphs.cs:315` / `XpsFontSubsetter.cs:613`。**旧清单无错项**，只是不全。
4. **`tline-gate.sh:433` 的"`P1`/`P4`/`P6`"** → 对现行世代**陈旧**：现行只有 `P1`+`P6` 红（`P4` 已 PASS；`gen/t1b-textline.txt` 那代才是 3 红）。**不是错数，是写死的编号过期**（纪律 26 家族）。
5. **"`P6` 的 `FAIL` 是 `EndInit` 或 setter 失败"**（我自己一开始的读法）→ **撤回**：抛点在 `Program.cs:211`（`EndInit` **之后**的读），`EndInit` 的异常被 `:209` 吞掉且**失败分支不打印**。**登记表没写错，但它没资格证明"setter 失败"** —— 这正是 §1.5 第 2 条要补打印的理由。
6. **`SegmentFaceUnresolved` 是"不许静默"的计数器** → 实测它**自己从不发声**（全仓 3 处出现，`SummaryFragment`/`DetailFragment` 都不含它；正对照：`segmentFaceResolveCalls` 打印在 `:1366`）。⇒ `D-F2` 的影响面**今天不可量**。

---

## 附：本文件的自我边界

* 本文件所有"实测"读数都来自**盘上已存在的日志/文件**，`lane=R17B` **没有产生任何新的运行时读数**（机器处于独占静树实验期）。
* 凡标 **✅ proven** 的形态 = 引用了盘上日志原文或**当前树**的源码行；凡标 **inference** 的（§2.3 的"主路成功"、§2.4 的 `pc` 必变）都已在正文点名；凡 **not measurable**（§4 七项）一律未写成绿。
* 我的写域只有本文件与 `$HOME/wfp-runs/w17-laneR17B/`；`pc`/`shim`/`provider`/`upstream`/`docs`/`samples`/`verify-all.sh` **一个字节都没动**（本文件是新建文件，不在任何冻结件清单里）。
