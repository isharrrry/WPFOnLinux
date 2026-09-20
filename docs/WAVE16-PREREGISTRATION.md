# 波 `#16` 预登记（**落地前**写死判据、前置与位移预测）

> 写于 **2026-09-15 17:0x**，波 `#15` 收官并重冻基线**之后**、任何 `#16` 落码**之前**。
> 上一波的基线（**作废即重算**）：`pc 532c7f54f7573070`｜`hbtextline b5118424dc977aef`（mtime `12:45:34`）｜`bridge caf7baf9e67719aa`｜门禁 `TLINE_GATE=PASS`（仪器 `b37a5c9f55ae71a4`、登记表 `cebd534238c3b649`）｜`verify-all` **10 步**。

## 0. 内容与顺序（**顺序不许颠倒**）

| 序 | 件 | 写域 | 为什么这个顺序 |
|---|---|---|---|
| 1 | **`D-T2` shim 半**（A/B/C 三处） | **T1d**（`build/shims/PresentationCore.HbTextLine.cs`） | `D-T2` 必须先取一次**独立读数**（否则被 `D-O1` 的折叠位移污染 ⇒ 归因作废） |
| 2 | **`D-T2` PC 半**（`Indent` / `ParagraphIndent` 接线） | **T1c**（`build/{PC,WB,PF}.Linux/**`，**不许手改**，走应用器） | **与 1 同波、且必须在取读数之前落地**：否则应用路径 `indentDip ≡ 0` ⇒ **读数一位不变，看起来像"修法无效"**（T1d 前置判据） |
| 3 | **`D-O1`**（`HasOverflowed` 真实现） | **T1d** | 它**会打开折叠路径** ⇒ **必须在 `D-T2` 读数之后**单独落、单独取数 |
| 4 | 五臂重取 + 重钉登记表 + `verify-all` 第 10 步 + 重冻基线 | **T1b**（臂日志）/ **主控**（登记表、`verify-all`、波、表头） | 见 §4 |

**⚠️ 一条硬前置（T1d 提出，主控采纳）**：`D-T2` 的落地**必须与 PC 半同波**，且**PC 半先于取读数**。理由：`Indent`/`ParagraphIndent` 现在**从未传到 shim**（PC 侧 `grep -cF ParagraphIndent TextFormatterImp.Linux.cs = 0`、`GetFiniteFormatWidth` 在 `build/PresentationCore.Linux/*.cs` **0 命中**）⇒ 只落 shim 半 ⇒ **位数不变**，会被误读成"修法无效"。

## 1. 本波要解决的问题（**逐条可复算**）

### 1.1 `D-T2`：**不是"补上 Tab 支持"**（那套机器已在），而是**三个互相独立的子缺口**
落地前基线（**必须引用，不许改**）：`tab-anchor` 臂 **436 例、`结构败=132`**、探针层 `未登记失败 178`（日志 `build/MilBridge/arm-logs/tab-anchor.log`，sha16 `7080853d7ddd9b2f`；同批 `tab-zero` `结构败=1`、`tab-rtl` `结构败=0`+`不可比=76`）。**逐族**（T1d/D-T2 双方一致）：`A-anchor` 4 / `B-indent` 64 / `B-indent-extra` 70 / `D-paraindent` 40（= 178）。

| 缺口 | 现树锚点（**T1d 现树实读，权威**） | 真值口径 | 落地后应转绿 |
|---|---|---|---|
| **(A)** 行中 `\t` 的"放不下"判据 | `:1859` `double stop = zero ? pen : (Math.Floor(pen / tabInterval) + 1.0) * tabInterval;`｜`:1860` `a = stop - pen;`｜判据 `:1865` `if (a > room && HbShaper.IsLineStartTab(pen, lineContentStart)) { a = room; tabClamped = true; }` | **"放不下"= `pen_before + 一个完整 interval > lineBoxWidth` ⇒ 断在 tab 之前**（注意：`stop − pen` 是 advance，**不是**"放不下"的判据本身） | `A-anchor` 族 4 条 |
| **(B)** `Indent` 只给段落首行 | `:1758` `double lineContentStart = (pos == 0 && start == 0) ? indentDip : 0;`（注释 `:1757`"仅段落首行吃 `Indent`"） | **每行都给**（上游 `LineServicesCallbacks.cs:376 lsLineProps.durLeft = settings.TextIndent`；`i24nl` 臂 `FirstLineInParagraph=false` 时第 2 行仍 `xFromLeftDip=24`） | `B-indent` 64 + `B-indent-extra` 70 |
| **(C)** `ParagraphIndent` 从未接线（**不是"拿不到"**） | `:390` `private static double TabClampInset(double paragraphIndent) => 0.0;`（**参数收下、直接返回 0.0**）＋三处**字面量** `0.0` = `:1743`、`:2781`、`:2786`（各为 `HbShaper.TabClampWidthFor(wrap, …, 0.0)`）＋`FormatParagraph` 签名无该参数 | `lineBoxWidth = container − ParagraphIndent`（上游 `FormatSettings.cs:164-175`，`:166` 注释 `indent is part of our text line but not of LS line`） | `D-paraindent` 40 |

**同时**：① `@tab0` 变体**全过**、`@default` 变红 ⇒ **"停靠位非 0 时的锚定/折行语义"** 是主战场；② `不可比(缺字形)=148`（oracle `script=hebrew` 116 + `arabic` 32）= 本机 Arial 替身（Liberation Sans）缺这些码点 ⇒ **RTL 那一半在本机零信号**，**不是我们的缺陷**，不许计入修法成败。

### 1.2 `D-O1`：`HasOverflowed` 恒 `false`
现树：`:3357` `public override bool HasOverflowed => false;`｜闸门 `:3413` `if (!HasOverflowed && !_keepState) → return this;`｜计数 `:1938` 的 `s_collapseEarlyReturnIneligible` 注释同源。
**它把折叠资格闸门焊死** ⇒ 「只有 `_keepState` 路径会折叠」（这也解释了 `F_nbsp_zwsp_w40#3` 的 CR 极必须用 `alwaysCollapsible:true` 才测得出）。
**候选落地法**：**内容盒右缘 vs 行盒远缘**（Q11 退化 4 例应为 `true`；"**恰好到达边缘**"那批**必须** `false`）。
**⚠️ 位移集合必须包含"折叠"族**（逐族修前/修后对照 + 方向解释）。

## 2. 判据（**落地前写死**）

### 2.1 正极性（必须成立才算达成）
| # | 判据 | 形态 |
|---|---|---|
| P1 | **`tab-anchor` 的登记红逐族清零** | `known-red.json` 里 `tab-oracle-anchor` 的 178 条 → 0 条；探针 `结构败 132 → 0`、`未登记失败 178 → 0`（**逐族**给，不许只给总数） |
| P1′ | **⚠️ 族级期望必须先按"哪一半修了"分开写（2026-09-15 17:1x 修正，来自 T1d 实测）** | **shim 半（`(B)+(C)`）落完 ⇒ 只应期待 `B-indent` 64 + `B-indent-extra` 70 转绿**；**`D-paraindent`(40) 不应期待从 shim 半转绿** —— 因为 `(C)` 那四处（`:1743`/`:2781`/`:2786` + 签名）在 **S6（`TabClampInset(double paragraphIndent) => 0.0`）未改的前提下行为惰性**：它**收下入参、直接返回 0.0** ⇒ 传进去的值不影响任何结果。`D-paraindent` 要的是 `container − ParagraphIndent` 当 `paragraphWidth` 传下去的**"盒侧"**（= S6）。**`A-anchor` 4 条另属 `(A)`，单独一趟**。⇒ 验收时**别把"没达成"误判成"修法无效"** |
| P2 | **`tab-zero` 的老红** | `notab-control@w40@em24@RTL@tab0`（`行#0 尾部空白 期望=0 实得=1`）—— 属**真值侧方向相关**的 `tws`，**不在本波射程** ⇒ **允许保留**，但**必须仍在册**（不许"顺手洗白"） |
| P3 | **`D-O1`** | Q11 那 4 例 `true`；**"恰好到达边缘"**那批 `false`（反例批）；`T3`/`T3b` 若随之转绿 ⇒ **必须重钉登记表**（否则门禁报 `KNOWN_RED_GONE` 判 FAIL，**那是设计**） |
| P4 | **`T2c` 判据重写为正判据** | 现状是**空洞为真**：布尔 `tabDiff == 0` 而 `tabCases` **只在"已出现不一致"时**才被填（`:760` 在 `else` 分支）⇒ **空集 ⇒ ✅**，而它的文字在断言"本实现未做"。⇒ 落地后**不会自动变 ❌**（反向陷阱：只有真出错才变 ❌）⇒ 必须改成：**断言样本集非空**（空集 ⇒ `NOINFO`，**不许 ✅**）＋样本必须来自 **`defaultIncrementalTab ≠ 0`** 的真机样本（b34 那 34 例是 `= 0` 配置） |
| P5 | **`verify-all` + 五臂门禁** | 重取五臂（**`ln -f`**）⇒ 重钉 `generation` ⇒ `TLINE_GATE=PASS … drift=0 gone=0 unregistered=0`；`verify-all` **10 步 0 失败** |

### 2.2 负极性（**修法必须能被否证**）
| # | 判据 | 形态 |
|---|---|---|
| N1 | 关掉 (A) 的判据改法（回到 `a > room` 旧式）⇒ `tab-anchor` 的 `A-anchor` 4 条**重新变红** | 可复现的失败才算牙 |
| N2 | 关掉 (B)（回到"仅段落首行吃 `Indent`"）⇒ `B-indent*` 族**重新变红** | 同上 |
| N3 | `D-O1` 回退 ⇒ 折叠资格闸门重新焊死（`collapseIneligible` 回到 2090 量级、Q11 4 例回到 `false`） | 同上 |

### 2.3 **不许变**的读数（任一条动了 ⇒ 停、报主控；**逐条给复算入口**）
`candidates`：1CJK **10** / 系统 **371**（7CJK **45** 待复取）｜`Scans = 1`｜**面选择普查 26/26 逐格相同**｜`LINE_W = 16.0000`｜`CR_W = 3.3440`｜`GID = 9498`（`GID_LT_COUNT=true`）｜`ADV_DIP = 16.0000`｜`ADV_FROM_TYPEFACE = 16.0000`｜`FACE_URI = …/NotoSansCJK-Regular.ttc`（face 0 **不带 `#`**）｜`CRITERIA = PASS`｜`TOOTH-D-F1b-ABSENT = PASS`｜记账 **1298/1298**（①286/286 ②68/68 ③988/988）｜**`+CJK` 34 条逐名不变**｜`Rendering.Tests` golden 零变化｜`WPTD_GATE=PASS`（两档 3/3）。
**已声明允许变**：`coverageProbe`（现值 53）、`coverageCacheHit`（12）、`faceLoads`（22）、`releaseCalls`（0）、外加本波新增计数；**除这些以外逐位相同才算过**。

### 2.4 **`Extent` +36 的判别读数（本波不作为目标，但必须证明"没有被弄得更糟"）**
已知：紧口径（0.01 DIP）`Extent` 余差 **`59 → 95`**，**36 条全 `*_tabs_*`**、**同值 `+0.0628`**、**布局（断点/宽度/真值宽/我们宽）逐位不变 36/36**；**另有 59 条共有行里 34 条"我们"值也变了**（`14.3200 → 16.2080`）⇒ 动了**共用墨迹/run 组合路径**（T1d 的**反证**：`ComputeInkExtent()` `:3317–3330` 本身**无取整**，且 `#13`→现行的**所有相邻备份两两 diff** 显示 `Union`/`ComputeInkExtent` **零改动**、窗口 10 的 hunk 全在 `:137–:1351`）。
⇒ **本波的机器断言**：`*_tabs_*` 余差行数 **== 36** 且 `差 == +0.0628`（若变 ⇒ 修法**越界到字形/面**，**立即停**）；同时 `Extent` 总余差 **不得从 95 再涨**。

**⚠️ 两条口径补正（2026-09-15 17:0x，主控；来自 `PLUS36-NARROW.md` `49a9fac105ded497`）**：
1. **"位移量"与"当前值"不是一回事**：断言里的 `差 == +0.0628` 指的是**本趟 artifact 里那一列的值**（`14.3828 − 14.3200`，可逐行核）；而**相对 `#13` 的位移**只能写成 **`+0.0628 ± 0.0100`**（`#13` 出货档里**没有 tabs 行** ⇒ 0.01 容差下只能断言 `#13` 的 tabs 我方值 ∈ `[14.3100, 14.3300]`）。**引用时别把这两个数混用**（主控此前混过，已自纠）。
2. **归因已定（本波不必再查，但必须"不弄坏"）**：`#13→本趟` 唯一改变"参与纵向墨迹并集的 run/面/字形集合"的代码 = **`shim:3792-3837`**（`D-F1`「单面路径也先构造计划」、`allowFallback:true`、闸门恒真、**无 env 开关**），引入于 **`fde9e511` → `46aa73a3`**；**36 条 tabs 与 34 条 `*_nbsp_zwsp*` 同源**。⇒ **本波落地时不许碰 `:3792-3837` 的语义**（否则 36 条与那 34 条会一起变、归因被冲掉）。**另**：真机对 `GlyphRun` 边界做 `Inflate(min(emSize/7, 1))`（上游 `GlyphRun.cs:1378-1386`）而我方不做 ⇒ 系统性 `+2.0 @ em=16` 偏置，已立为在册项 **`D-E1`**，**本波同样不许顺手修**。


## 3. 落地纪律（**逐条来自实测事故**）

1. **先重锚再落**：`D-O1.md` 的锚点是**旧行号**（`:3086`/`:3142`），现树是 **`:3357`/`:3413`** ⇒ **落地前逐处按现树重读**；每处给**逐字锚点 + `grep -cF '<锚点>' <文件>` 期望计数**（纪律 4/9）。
2. **PC 侧不许手改**：`build/PresentationCore.Linux/**` 由 `port-lib.py`/应用器生成（`PORT-CHANGES.md:3` 自述）⇒ PC 半走应用器 + `check-appliers.sh`（期望 `appliers=20 ok=74 miss=0`）。
   **⚠️ 补一条落地判据（2026-09-15 17:1x 现场踩到，纪律 33）**：**`--check` / 应用器审计只证明"应用器自己"**（幂等、锚点命中），**不证明生成物能编译**。⇒ 凡改"生成物会被编译进产物"的源，**落地判据必须含**：
   ```bash
   export PATH="$HOME/.dotnet:$PATH"
   dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 --nologo -v q 2>&1 | tail -3   # 必须 `0 个错误`
   ```
   **可复用的正确做法（T1c 实测）**：编到**私有输出目录** ⇒ `dotnet build … -p:BaseOutputPath=$HOME/t1c-16-build/bin/ -p:BaseIntermediateOutputPath=$HOME/t1c-16-build/obj/` ⇒ 既拿"0 错"又不碰权威 `bin/obj`、**不改写 `pc` 的 DLL**。**边界**：这条**只用于"编"**；**"跑"（门禁/探针/应用）不许用隔离输出目录**（纪律 23 讲的是"只隔离 `OutputPath` 而不处理 native 副本 ⇒ 必崩"，两条**讲不同动作，不可互引**）。
   **本次现场**：只验 `--check`+审计 ⇒ 波里 PC **❌ 2 个错误**（`CS1739`：改了 `:230` 的 `TryFormatLine`，而 `:553` 调用的是**另一个类**的 `HbTextFallback.TryFormatLine`；`CS0103`：在 `TryMinMaxParagraphWidth` 里引用了该作用域不存在的 `paragraphIndent`）；**波在 `[1/6]` 正确中止、`pc` 未被改写**。
3. **`ParagraphIndent` 的接线计数必须"两段"写（防后人拿 `2` 比 `1` 以为丢了一处）**：**T1c 这一趟 `0 → 1`**（`TextFormatterImp.Linux.cs`：A 签名 + B `:253` 出行处）＋ **T1d 落 `(A)` 时顺手补 `HbTextFallback.TryFormatLine` 的签名/透传 ⇒ 之后 T1c 才把 `:559` 那 1 行加回 ⇒ `1 → 2`**。**为什么必须补**：`:553` 是**应用路径的第一路**（shim 的 `HbTextFallback`）、T1c 那份是**宽松兜底** ⇒ shim 不接 `paragraphIndent` ⇒ **主路用默认 0** ⇒ 那正是"**注册了但没生效**"族（本项目最爱出事的一类）。`:305`（min-width 探针）**维持不接**（五臂不消费 `minWidth`，已成结论）。
3. **还原源码后必须强制重编**（`touch` 源或清 `obj`）：`cp -p` 保旧 mtime 会让增量构建跳过重编 ⇒ **假红/假绿**（纪律 24）。
4. **一次只跑一个应用**；`:97`=门禁/探针、`:96`=装置、`:99`=`verify-all`（`:0`/`:1` 是活桌面）；**跑门禁前先 `DISPLAY=:97 xdpyinfo` 确认 `:97` 已存在**（runner 自起 Xvfb 有**就绪竞态** ⇒ 会产出"应用 `exit=134`"的**假红**，纪律 30）。
5. **改 `build/MilBridge/run.sh`（哪怕只改注释）会作废五臂世代绑定 ⇒ 门禁 `NOINFO`**（纪律 31）⇒ **先做完读数再改**，或接受 `NOINFO` 并重取四臂 + 重钉。
6. **臂日志只许 `ln -f`，绝不 `cp`**（`cp` 会顶 mtime ⇒ **架空**"日志 mtime ≥ 世代被测件 mtime"的弱配对判据 ⇒ 判据**静默变绿**）；**不许 `rm`/重写** `arm-logs/*.log`（见该目录 `README.md`）。
7. **`D-T2` 与 `D-O1` 分开取数**（同批 ⇒ 两族齐变 ⇒ 该结论作废）。
8. **静树取数**：记 `loadavg` + `free -m`；`D-R2`（`ManagedLayer.Tests` 测试主机并发崩溃）**仍开** ⇒ `verify-all` 读数须在静树取，并如实记 `loadavg`。
9. **`rc=124/143` 记无信息、不重试**（`L27`）；判据包"跑完"= **结论段 present ∧ `=== 结束 ===` ∧ `rc ∉ {124,143}`**（`L29`）。

## 4. 落地后的收尾清单（**每件留 sha**）

**⚠️ 波命令的形式变了（2026-09-15 17:1x，因为第 10 步已接）**：`verify-all` 的第 10 步是五臂门禁，而**任何仪器件（`run.sh` / `Parity` / shim）一变，弱配对臂的世代绑定即失效** ⇒ 门禁报 `NOINFO`(rc=2) ⇒ **`close-wave.sh` 会在 `[5/6] verify-all` 处判失败并中止**。⇒ 本波及以后**改仪器件的波**必须走**两步**：
```
# 1) 只做"重建 + 身份"（不发基线）
WAVE_OWNER=主控 bash build/close-wave.sh --skip-verify-all
# 2) 重取五臂（ln -f）⇒ 重钉 known-red.json 的 generation/entries ⇒ 再全量回归
bash verify-all.sh          # 期望 10 步 0 失败
```
**这条代价是"把门禁接进 `verify-all`"的必然结果**，也是 `L26`（"判据存在但没人跑 = 没有判据"）的代价：**你改仪器，就得重新给这个仪器出读数**。不许用"把第 10 步指向空目录/旧日志"来绕过（那是把判据关掉）。

1. 五臂重取 → **`ln -f`** 进 `build/MilBridge/arm-logs/`（**T1b**；先重建会编 shim 的宿主：`CoverageProbe` / `TextLineProto` / `HbTextLineParity`）。
2. **重钉 `known-red.json`** 的 `generation`（三项仪器 sha + 世代标签 `#16`）与 `entries`（`tab-anchor` 178 条应全 `gone` ⇒ 逐条注销；`tab-zero` 1 条保留；`T2c` 判据重写）；`changelog rev6` 写清"为什么重钉"。
3. 门禁应给 `TLINE_GATE=PASS … drift=0 gone=0 unregistered=0`；`verify-all` 10 步 0 失败。
4. **重冻基线**：新九位写进 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 **`#16` 表头**（本波内容 + 哪条判据成立/不成立 + 未做项 + 仪器版本），并更新 `docs/CURRENT-STATE.md` §1/§4、`handoff.md` 波记录。
5. `D-R2` 计数；**`D-F1c`①c**（1CJK 该 `.ttc` 波后 **3 段**、目标 1–2、残余在 **shim 侧回退扫描期的瞬时映射**）**单列**，不混进本波 —— T1d 已提示：窗口 10 后 `OpenFileBlob`/`CloseFileBlob` 是**共享 blob 的引用计数** ⇒ **扫描进行中**那份 blob 按设计就是活的 ⇒ 要定案得**单独**在扫描窗口内取 `/proc/<pid>/maps` 归属快照（**当前无读数**）。

## 4.5 `(A)` 的 oracle 判别结果（2026-09-15 17:1x，**落地前**就拿到，先记在这里）
T1d 在 `tab-anchor` oracle 里找到 **4 条落在判别区**（`r` 不在网格上 **且** `stop ≤ W < r + I`）的样本，`emSizeDip=24 ⇒ I = 4×24 = 96`（与真值 `[\t] w=96.0000` 自洽）、`indentDip=0`、`arm=default`：

| 用例 | `r` | `I` | `W` | 现行 `stop>W` | 提出 `r+I>W` | 真值（`breakCause` 是 **oracle 自带逐字标签**） |
|---|---|---|---|---|---|---|
| `lat-a-t-b@w96@…@default` | 13.3467 | 96 | 96 | **否** | **是** | 行0 `[a]` **`breakCause=before-tab`** ⇒ **断** |
| `lat-a-t-b@w100@…` | 13.3467 | 96 | 100 | **否** | **是** | **断** |
| `lat-ab-t-c@w96@…` | 26.6933 | 96 | 96 | **否** | **是** | 行0 `[ab]` **`before-tab`** ⇒ **断** |
| `lat-ab-t-c@w100@…` | 26.6933 | 96 | 100 | **否** | **是** | **断** |

⇒ **4/4 支持"判据改法"**（按 §2.1/裁定里写死的那句：真值在该区仍断行 ⇒ 走判据改法，不是只改 `pen` 起点）。
**同时炸出耦合的第二条**：真值 行1 = `[\t] w=96.0000` 且 **`breakCause="after-tab"`**，而我方 行1 = `[\tb] w=109.35`（**超宽**）⇒ 我方在 tab 之后**没能断**（`:1762-1765` 的 after-tab 资格被跳过）⇒ 真值那边 tab 是**被钳满**的。⇒ **`(A)` = 「判据 + after-tab 资格（`tabClamped`）」一对，必须单独一趟、单独取数**（落地时机在 `(B)+(C)` 的权威读数**之后**）。



### 4.6.1 落地与读数的逐轮流水（**每轮都留日志 sha16**）

| 轮 | 落了什么 | `tab-anchor` 日志 | `判定过` / `结构败` / `未登记失败` | 其它臂 | 判定 |
|---|---|---|---|---|---|
| 0（`#15`） | 无 | `7080853d7ddd9b2f` | 110 / 132 / 178 | — | 基线 |
| 1 | **只修探针**（补 `indentDip`/`paragraphIndentDip`；shim 未动） | `94bfd595b93e68da` | **180 / 49 / 108** | 未取 | ✅ T1d 预言成立（`(B)` 是正解） |
| 2 | **件 2 的测量侧**（`shim ba16db440e50fd8d`：内容起点 = `I+PI`、拟合 `wb+lineContentStart`、两侧 `room` 减起点） | `c466edf47dfb0905` | **233 / 55 / 55** | `tab-zero`/`tab-rtl` **逐字节不变** ✓ | **混合**：位置面 74→**0** ✓、未登记 108→55 ✓，但 **`B-indent/lead-tab-*` +10 反向**（0→4、5→7、0→3、5→6）⇒ **按"任一族反向即停"停** |
| 3 | **件 2b 整形侧**（`shim 0bec7a9679fcafe5`：`ShapeParagraph`/`ApplyTabStops` 的 `startPenX = 0`、`lineContentStartX = I+PI`；1 hunk `+6/−4`；件 2+2b 合计 5 hunk `+16/−9`） | `b95d03c1f65cfd60` | **243 / 45 / 45** | `tab-zero`/`tab-rtl` **逐字节不变** ✓、`tline` **数值不变** ✓ | **部分达成 + 两条预言被否**：`B-indent-extra/*` 5/7/7→**2/2/2** ✓、`D-paraindent` 4/4→**3/3** ✓；但 **`B-indent/*` 12→23（显著反向）**、**`notab-control` 8 条一条不动**（预期→0）⇒ **按"任一族反向即停"停** |
| 4 | **件 2c**（`shim ab5acf697d0c5af6`：强制断 fallback 的塞满循环补内容起点 `:1784`；1 行，含把声明提出 `foreach`） | `40a0ef9198f4fd80` | **251 / 37 / 37** | `tab-zero`/`tab-rtl` 逐字节不变 ✓、`tline` 数值不变 ✓ | ✅ **T1d 的可证伪预言逐条成立**：`notab-control` **8 → 0**（`FAILCASE.*notab-control` 已无失败行）、其它族一条不动 ⇒ 机制 M 证实 |
| 5 | **件 2d**（`shim ba72881990b6a035`：①`startPenX = indentDip + paragraphIndentDip`（网格锚回内容起点）＋ ②`room = clampWidth − lineStart`（不再减 `pen`，等价于还原 D-T1 原式 `stop > clampWidth`）；3 hunk `+6/−4`；件2..2d 合计 6 hunk `+26/−14`） | `2786a8eee1b963e8` | **253 / 35 / 35** | `tab-zero`/`tab-rtl` 逐字节不变 ✓、`tline` 数值不变 ✓ | **预言 1 成立（case 级）**：`B-indent/lead-tab-a@w40` 与 `@w140` 的**四个变体全 PASS**、族级 5→**0**、`lead-tab-only` 2→**0**、`mid-tab-a-t-b` 7→2、`lead-tab-b-t-c` 7→3；**预言 2 被否**：`D-paraindent/lead-tab-a` 3→**10**、`mid-tab-a-t-b` 3→**10**（`@default` 红、`@tab0` 全 PASS；原文 `行#0 行宽 期望=109.3467 实得=85.3477 / 61.3477`）⇒ **按"任一族反向即停"停** |

**机制 M（T1d 定案，逐位复现我的实测值）**：件 2 的第三处（`:1771`）**确实生效**（`best = -1`），但紧接着的**「规则 3：强制断 fallback」**在 `:1783-1784` 只比 `w + adv[e] <= width`、**漏了内容起点** ⇒ 两个字符被一起塞进一行 ⇒ 我方 `行数=1、w = 26.6933 + 24 = 50.6933` —— **与我实测的 `w=50.70` 逐位相同** ✓ ⇒ 这就是 `notab-control` 8 条不动的真因。**全文件"含 width 的拟合比较"只剩两条**：`:1771`（已改 ✓）与 `:1784`（**漏改**）。**件 2c（已授权）** = `:1784` 改成 `w + lineContentStart + adv[e] <= width + 1e-9`；**可证伪预言**：`notab-control@w40@i24` 应从 `1 行 w=50.70` → **`2 行 w=37.3467/37.3467`**（= 真值），而 `@w80@i24`（走 `:1771`）不受影响。
**轮 1→2→3 的日志（供集合差）**：`~/wfp-runs/w16/tab-anchor.probefix.log`（`94bfd595b93e68da`）｜`~/wfp-runs/w16/item2/tab-anchor.log`（`c466edf47dfb0905`）｜`~/wfp-runs/w16/item2b/tab-anchor.log`（`b95d03c1f65cfd60`）｜轮 0 = `build/MilBridge/arm-logs/tab-anchor.log`（`7080853d7ddd9b2f`）。**`B-indent/lead-tab-*` 反向（12→23）的机制未定**，待集合差；T1d 的代数假设（2b 使行首 tab 写出 advance `0→16`）**方向与真值一致**（`witw = 16 + I = 40.0000` ✓）⇒ 反向另有原因。

**轮 3 的最尖线索（`notab-control`，纯缩进无 tab）**：`@w40@i24` 真值 = **2 行** `[a]w=37.35 | [b]w=37.35`（`37.35 = 24 + 13.35` ⇒ 行宽自盒原点起、含 `Indent`），我方 = **1 行** `w=50.70`（`= 24 + 26.69`）⇒ **行宽公式已对、但没断行**，而按第三处（`:1767` `wb + lineContentStart > width`）应有 `26.69 + 24 = 50.70 > 40` ⇒ **必须断**。⇒ **`:1767` 在这条路径上没有生效**（或生效的不是这条路径）⇒ 已派 T1d 只读追（判据形态 + 逐字锚点；**件 1 暂不落**）。

### 4.6.3 **tab 的两个角色必须分开**（T1d 用 oracle `perChar` 定案，4/4 逐位）

| 用例 | `I` | `PI` | `W` | 行0 | tab **x** | tab **adv** | 行宽 |
|---|---|---|---|---|---|---|---|
| `B-indent/lead-tab-a@w140@i24p0` | 24 | 0 | 140 | `[\ta]` | **24** | **72** | 109.3467 |
| `B-indent/lead-tab-a@w40@i24p0` | 24 | 0 | 40 | `[\t]` | **24** | **16** | 40.0000 |
| `D-paraindent/lead-tab-a@w220@i24p24` | 24 | 24 | 220 | `[\ta]` | **48** | **72** | 109.3467 |
| `D-paraindent/lead-tab-a@w220@i24p48` | 24 | 48 | 220 | `[\ta]` | **72** | **72** | 109.3467 |

⇒ **tab 的 `adv` 恒为 `I_tab − Indent`（`72`），与 `PI` 无关；tab 的 `x` = `Indent + PI`（24/48/72）**。⇒ 两个角色分开：
- **网格锚（决定 `stop` 与 advance）= `Indent`（不含 `PI`）** ⇒ 整形侧 `startPenX = indentDip`；
- **内容起点（决定 `IsLineStartTab`、`room` 起算、`GetTextBounds` 的 x）= `Indent + PI`** ⇒ `lineContentStartX = indentDip + paragraphIndentDip`（**不变**）。

**件 2d 的 ①（`startPenX = indentDip + PI`）因此是错的** ⇒ **件 2e（已授权）= 只把 `:2797`/`:2803` 的 `startPenX` 改回 `indentDip`**，其余（`lineContentStartX`、②、`_startPenX`、`:2819`、S6、2c）全不动。
**可证伪机制（T1d 原文）**：*若网格锚不含 `PI`，则 `@i24p24`/`@i24p48` 的 `TotalWidthPx` 都应是 **85.3467**、行宽 **109.3467**；若含 `PI`，则退化成 **85.3477 / 61.3477** —— 后者正是轮 5 的实测值。***
**恒等性**：`PI=0` 时 ①′ ≡ 2d ⇒ **`B-indent/lead-tab-*` 那 5 条已 PASS 的不受碰**（这正是主控对 ①′ 设的前提）。

**两条登记（"登记 ≠ 已理解"）**：
1. **测量侧网格锚仍是 0**（`EffectiveWidthTab` 的 `double pen = 0;`）与整形侧 `indentDip` **不是同一锚** ⇒ 四个样本上无可观测差异（`room` 相同、fit 两侧都过），但**紧宽度可能分叉**；**无证据不改**，判据 = 找一个"小 `W` + 大 `Indent` 且两侧候选取舍不同"的样本（本轮不找）。
2. **旧稿 `Q7/Q8` 的措辞与真值相反**：备稿写"`Indent` **不**移动网格 / `ParagraphIndent` **移动**网格"，而四条 `perChar` 真值给出的**正好相反**（`adv` 只随 `Indent` 变、`x` 两者都随）⇒ **后续引用 Q7/Q8 前必须按现树/oracle 重读，不许照抄旧措辞**。


### 4.6.4 **"一条判据不够"的定案**（T1d 只读复算，2026-09-15 18:0x）

**组 A（真值断、我们不断，8 条）** = **判据贡献记错**：`A-anchor/lat-a-t-b@w96`（`I_tab=96`、`I=PI=0`、`W=96`）的候选 `[a\t]` **实际**宽 = `13.3467 + (96−13.3467) = 96 ≤ 96` ⇒ 现行判据通过 ⇒ 不断 ✗；按**贡献 = `I`**：`13.3467 + 96 = 109.3467 > 96` ⇒ 断 ✓。**改动 = 件 1b**（测量侧：行中 tab 贡献 = `I`；写出仍 `stop − pen`；`:1771` 资格含等号）。

**组 B（真值不断、我们断，6 条）** = **测量侧网格锚 = 0**（**不是判据松紧**）。以 `B-indent-extra/lead-tab-a@w140@i24p24@default` 逐位复算（现树 `4e57654535241864`）：
```
测量侧 pen 从 0 起（锚=0）⇒ stop = 96 ⇒ tab 贡献 = 96
  候选 b=2（整行 "\ta"）: wb = 96 + 13.3467 = 109.3467；fit  109.3467 + 48 = 157.35 > 140 ⇒ 拒
  候选 b=1（仅 tab）    : wb = 96；                  fit  96 + 48 = 144 > 140     ⇒ 拒
  ⇒ 进强制断 fallback：48 + 96 = 144 > 140 ⇒ best = 1 ⇒ 行0 [\t] w = 72 + 24 = 96.00；行1 [a] w = 13.3467 + 24 = 37.35
```
⇒ **与我方实测 `[len=1]w=96.00 / [len=1]w=37.35` 逐位相同** ✓；而**真值**（锚 = `Indent=24` ⇒ tab adv **72**）⇒ `85.3467 + 48 = 133.35 ≤ 140` ⇒ **1 行 `w=109.35`** ✓。**改动 = 件 1a**（测量侧网格锚 = `Indent`，与整形侧同锚）。

⇒ **两件互相独立、互不掩盖**（A 只动"行中 tab 的贡献值"，B 只动"网格起点"），且 **A 的 `I=PI=0` ⇒ 锚 0 ≡ `Indent=0` ⇒ 1a 不干扰 A**；**B 的 tab 在行首 ⇒ 不受"行中贡献"影响 ⇒ 1b 不干扰 B**。**顺序 = 1a → 取数（预期 14→8）→ 1b → 取数（预期 8→0、`判定过 288/288`）**。

**登记状态更新**：先前"测量侧锚 0 vs 整形侧 `indentDip` ⇒ 无证据不改"的疑点 ⇒ **已变成有证据的缺陷**（组 B 6 条）；**判据** = `@w140@i24p24@default` 应给出 **1 行 `w=109.35`**。
**签名变更（已授权）**：`EffectiveWidthTab(...)` 只拿到 `lineContentStart = I + PI`，而 1a 需要锚 = `Indent`（不含 `PI`，`i24p24` 时 24 vs 48）⇒ 加锚入参 **或** 调用点就地算 `gridAnchor = indentDip` 传入（两处都要逐字锚点 + 改前/改后计数）。
**逐轮流水（结构败 / 判定过）**：`#15` 132/110 → 只修探针 49/180 → 件 2 55/233 → 件 2b 45/243 → 件 2c 37/251 → 件 2d 35/253 → 件 2e 14/274 → 件 1a 8/280 → 件 1b 10（已回退）→ 件 1b′ 8（零位移）→ 件 1c 4/284 → **件 1d 0/288 ✅✅（`tab-anchor` 全绿、`rc=0`）**。

### 4.6.8 🎯 **`tab-anchor` 达成全绿**（轮 11，件 1d；shim `19a8d2a15fd4138d`）

### 4.6.9 `D-O1` 的重锚与"缺一个标量"（2026-09-15 18:3x，T1d 只读）

### 4.6.10 🎯 **`#16` 的 shim 定稿 + 门禁回绿**（2026-09-15 18:2x–18:3x）

**`D-O1` 落地（`bc04c05ab6d8d82a`，275,765 B，18:25:25）**：5 处 —— ① `_startPenX` 注释**改正**（旧注只写 `Indent`，实际是 `Indent + ParagraphIndent`）＋ 新增字段 `_boxOriginX`；② 构造尾追 `double boxOriginX = 0`；③ 构造赋值；④ `FormatLine` 传 `paragraphIndentDip`；⑤ `:3409` 换真实现（三分支：`!(_paragraphWidth > 0) ⇒ false`；`_startPenX >= _paragraphWidth ⇒ true`；否则 `_boxOriginX + _width > _paragraphWidth + 1e-9`）。三连 `error CS = 0/0/0`；`_boxOriginX` 全文件 4 处收支一致；旧恒假表达式计数 **0**。

**轮 12 读数（`D-O1` 单独）**：三支 tab 臂**全部如预言**（`tab-anchor` **288/0** 仍全绿、`tab-zero` `结构败=1` 老红仍在、`tab-rtl` 0）；`tline` 出现**一处可归因位移**：
```
折叠判定一致   1298/1298 → 1297/1298      ← 新增 A1_nbsp_zwsp_w40|行#0 Collapse hasCollapsed 期望 False 实得 True
记账不一致     4 → 5                       （新增项就是上面那一条）
lines          3788 → 3789
collapseIneligible 2090 → 2088 ▼    collapseApplied 236 → 237 ▲
collapsedRangesReturned 236 → 237 ▲  collapsedRangesNull 1062 → 1061 ▼   collapseCalls 2596 → 2596（不变）
Extent 余差     95 → 95（不变）    *_tabs_* 36 / 差 0.0628（不变）
```
⇒ **主控要的"方向测试"逐条通过**：`collapseIneligible` **下降**、`collapseApplied`/`collapsedRangesReturned` **上升** ⇒ 位移**由"折叠闸门放行"逐条归因**（按 §4.6.6 替换口径 ⇒ **接受**）。**这是"打开折叠路径必然产生位移"的正面证据**，也是 `D-O1` 的目的本身。

**✅ 五臂重取 + `ln -f`（最终世代）**：`build/MilBridge/arm-logs/` 五份硬链接（链接数均 2）——`tline.log ad07ead4022539d2`｜`tab-zero.log b9d81590f3fcd800`（与 `#15` 逐字节相同）｜`tab-anchor.log 99d72b385fe23a90`（全绿那趟）｜`tab-rtl.log 419e8aaa9c72a9a0`（同 `#15`）｜`textlineproto.log 4bceceeed570ba70`（同 `#15`）。

**✅ 登记表重钉到 `#16`（`cebd534238c3b649` → `391c907c7d114e01`；`schema 4`、`rev 6`、entries 182 → 4）**：`generation.instr_shim = bc04c05ab6d8d82a…`（`run.sh`/`Parity` 未变）；**注销 `tab-oracle-anchor` 全部 178 条**（该臂已 `结构败 0`）；保留 `tab-oracle-zero` 1 条 + `tline` 3 条（`T3` 的 `carrier`/`reason` 已按上面那处可归因位移更新）；`pending` 重写（`判定过=110` 的矛盾**已消解**）。

**✅ 门禁（五臂，`#16` 世代）**：
```
TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0
caliber=OK generation=#16 tree_gen=same saved_shim=bc04c05ab6d8d82a gate=b37a5c9f55ae71a4   GATE_REASON=all-as-registered
```
⇒ **`green=3`**（`tab-anchor`/`tab-rtl`/`textlineproto`）+ `red=2`（`tline` 的 T3/T3b 保留红、`tab-oracle-zero` 的老红）—— **每一处红都在册**。

**重锚（旧值全部作废，落地用现树值）**：`HasOverflowed` 定义 **`:3409`**（旧报 `:3357`/`:3366`）｜折叠资格闸门 **`:3465`**（旧 `:3413`/`:3422`）｜计数注释 **`:1987`**（旧 `:1938`）。`HasOverflowed` 全文件仍 **4** 处（`:1987` 注释、`:3409` 定义、`:3451` 注释、`:3465` 闸门）。

**缺的那一个标量**：判"内容**右缘** vs **行盒远缘**"需要盒原点 `PI`，而 `HbTextLine` **只存了 `startPenX = I + PI` 这个合量**（`:2849`），`PI` 与 `Indent` **都没单独存** ⇒ 用现字段**算不出 `PI`** ⇒ 不加参就只能"假设 `PI = 0`"，那在 `D-paraindent`（`PI=24/48`）上**系统性判错**。

**✅ 主控裁定 ①：准加 `boxOriginX` 形参**（+ 字段 + `FormatLine` 一处传参）—— 理由三条：① **与件 `1a` 加 `gridAnchor` 是同一个模式**（"网格锚与内容起点是两个量，签名上必须分开"）；② 既有调用点零改动（尾追可选、默认 0），三条分支自检成立（退化族 `true`、恰好到边 `false`、`_paragraphWidth == 0` 的旧调用点**保持恒 false** ⇒ `tline`/`tab-*` 不受影响）；③ 真值口径支持（`Width = Indent + 内容` 盒坐标系 + 盒原点 `= PI`）。
**实现（T1d 给）**：`!(_paragraphWidth > 0) ⇒ false`；`_startPenX >= _paragraphWidth ⇒ true`（退化族）；否则 `_boxOriginX + _width > _paragraphWidth + 1e-9`（**严格 `>`** ⇒ 恰好到边不算溢出）。**主控加一条**：`:2633` 的注释**已过时且会说谎**（写"内容起点（`Indent`…）"，实际是 `Indent + ParagraphIndent`）⇒ **本次一并改正**（逐字锚点 + 计数）。

**轮 12 的写死预言 / 口径**：① `tab-anchor` **仍 0**；② **`T3`/`T3b` 只允许"不动"或"转绿"**，出现新 ❌ ⇒ 停；③ `tab-zero` 1 条老红仍在、`tab-rtl` 仍 0；④ **折叠族逐族给修前/修后 + 方向解释**，并给 `s_collapseEarlyReturnIneligible` 的**方向**（闸门放行变多 ⇒ 该计数应**下降**）；⑤ **`Extent` / `*_tabs_*` 按 §4.6.6 替换口径**（允许位移、每处必须由"折叠闸门放行"逐条归因；无法归因 ⇒ 停）—— **主控明确不再写成"必须 36 条不变"**，理由同 §4.6.6；⑥ `tline` 其它六项若动同样逐条归因。

| 臂 | 日志 sha16 | 判据 |
|---|---|---|
| **`tab-anchor`** | **`99d72b385fe23a90`** | **`rc=0`、`判定过 288 / 结构败 0 / 未登记失败 0`**（假集只剩 `不可比(缺字形)=148` = 真值侧字体问题） |
| `tab-zero` | `b9d81590f3fcd800` | **逐字节不变** ✓（`tabIntervalUse > 0` 守卫生效） |
| `tab-rtl` | `419e8aaa9c72a9a0` | **逐字节不变** ✓ |
| `tline` | `a1d07d4856b8813e` | `exact=73 diff=0`、记账 `1298/1298`、宽度 `>0.34=0`、折叠 `232/236`、`Extent 95` ⇒ **数值不变** ✓ |
| `Extent` 不变量 | `gen/t2d-extent-mismatches.txt` | `*_tabs_*` **36** / 差 `0.0628` / 总 **95** ✓ |

**预言逐条成立**：剩余 4 → **0**、`判定过 **288/288**`；`@w96` 与 `@w140@i24`/`@w140@i24nl` 无反向（**无任何特例**）；`tab-zero`/`tab-rtl` 逐字节不变；`tline`/`Extent` 不变量保持；**§4.6.6 的口径变更最终未被触发**。

**本波 `D-T2` 的落地件清单（9 件，全部单独取过读数）**：`2`（测量侧 `room = W − (I+PI) − pen`、拟合含起点）｜`2b`（整形侧 `startPenX=0`、`lineContentStartX=I+PI`）｜`2c`（强制断 fallback 补内容起点）｜`2d`（网格锚回内容起点、`room` 不再减 `pen`）｜`2e`（网格锚 ≠ 内容起点：`startPenX=indentDip`）｜`1a`（测量侧网格锚 = `Indent` + 拟合 `+ PI`，含签名加 `gridAnchor`）｜`1b′`（行中 tab 贡献**条件式**：`pen + I > W` 才取 `I`）｜`1c`（fallback 同尺 + `a >= room`）｜`1d`（fallback 按**行笔位**重算 `\t` 的 advance）。**其中 `1b` 因净回归被回退**（0 修好 / 2 新坏）⇒ 留下了完整的"否证—回退—条件式重生"链。

**🔄 顺序调整（主控，2026-09-15 18:2x）**：`D-O1` **提到"手续"之前** —— 门禁 generation 绑三项仪器 sha（含 shim），**`D-O1` 一落 shim 又变、世代绑定再次失效** ⇒ 先把 shim 定稿（`D-O1` 是最后一件 shim 改动），再**一次性**做"五臂重取 + `ln -f` + 重钉 `known-red.json` 到 `#16` + `verify-all` 10 步 + 重冻 `#16` 表头"。

**✅ `adv[]` 读数（T1d 只读，2026-09-15 18:1x）**：`HbShapedRun.CharAdvances()` `:108-117` 按 cluster 归并 `AdvancesPx` ⇒ **`adv[\t] = AdvancesPx[tab]`**（`"a\tb"` ⇒ **82.653**、`"ab\tc"` ⇒ **69.3067**）。**关键**：`BreakParagraph` 的 `adv[]` 来自**段落级**整形（`:1693` `HbShaper.Shape(...).CharAdvances()`），而那次 `Shape` 内部 `:336` 调 `ApplyTabStops(r, text, font, 0, 4.0*r.EmSize)` ⇒ **clampWidth = +∞（不钳）+ 锚 0 + `I_tab = 4×emSize`**，与用例的 `W`/`I`/`PI`/`defaultIncrementalTab` **全无关** ⇒ **fallback 量的是"另一个世界里的 tab"**（"两把尺子"的物证）。
**零位移被逐位解释**：`lat-a-t-b@w96` 的 fallback 用 `82.653` ⇒ `13.3467 + 82.653 = 96 ≤ 96` ⇒ `best=2` ⇒ 行0 = `[a\t]`，与 1b′ 之前**同一行划分** ⇒ 输出逐字节相同 ✓。

**❗ 单改 fallback 不够（T1d 复算）**：行0 会修好，**行1 仍错**（我方 `[\tb]` vs 真值 `[\t]` 独占 `w=96.00`）—— 因为 `:1777` 的 **after-tab 资格**被 `tabClamped=false` 挡住；**唯一能放行的是等号**：行1 处 `a = 96`、`room = clampWidth(96) − lineStart(0) = 96` ⇒ `a >= room` ⇒ `tabClamped=true` ⇒ 放行 ⇒ `best=2` ⇒ **3 行逐位吻合真值**。
⇒ **主控改判：`>=` 落**（先前拒落的两条理由中"无证据"这一半**被推翻**；"`tab-rtl` 风险"这一半仍成立 ⇒ 见下口径变更）。

**🔄 口径变更（主控负责，2026-09-15 18:1x）**：`tab-rtl` / `tab-zero` 的守卫由 **"逐字节不变"** 改为 **"允许位移，但每一处位移必须由 `a == room ⇒ tabClamped=true ⇒ after-tab 资格放行` 这条机制逐条归因；任何无法这样归因的位移 ⇒ 立即停、报主控，并按回退处理"**。
**为什么这不是"为了让改动落地而放宽"**：① 新口径在**归因**这一维上更严（原来不需要解释，现在逐条必须解释）；② 坚持"逐字节不变"会在"**压住一个语义保真改动**"与"**把语义保真误判成回归**"之间二选一，两者都是本项目明令避免的；③ 原口径是**上一轮步骤的守卫**，不是波次不变量（`#16` 的真正不变量是 §2.3 那张表 + `tab-anchor` 的读数）。


### 4.6.7 **件 1c = 8 → 4**（轮 10）：残余被压缩到"`W` 96 vs 100"一个差别上

**件 1c 落地（`b4af623f4851d285`，273,894 B）**：① fallback 塞满循环对 `\t` 套**同一条条件式**（`para[e]=='\t' && tabIntervalUse>0 && w+lineContentStart+tabIntervalUse > width+1e-9 ⇒ break`）；② 测量侧钳位 `a > room` → **`a >= room`**（`tabClamped` 含等号）。**两处都带条件**（①的 `tabIntervalUse>0` 兼作 `zero` 守卫）；旧式计数均 **0** ✓；三连 `error CS = 0/0/0` ✓。

**轮 10 读数**：`tab-anchor 0a7e03ac2b5dbcdb` ⇒ **`判定过 284 / 结构败 4 / 未登记 4`**（轮 9：280/8/8）；`tab-zero`/`tab-rtl` **逐字节不变** ✓✓；`tline 30923a752fd56c75` 数值不变（`exact=73 diff=0`、记账 `1298/1298`、宽度 `>0.34=0`、折叠 `232/236`、`Extent 95`）✓。
**⇒ 我的口径变更（§4.6.6）本轮根本没被触发**（两臂都逐字节不变）⇒ 风险为零、无需逐条归因。

**✅ 分叉点定案（T1d 逐位，2026-09-15 18:2x）**：
```
@w100 行1：候选 [\t] 被拟合接受，但资格 :1777 跳过（a=96 >= room=100 为假 ⇒ tabClamped=false）
        ⇒ 候选 [\tb] 被拒 ⇒ best=-1 ⇒ 落进强制断 fallback
        ⇒ fallback 用段落级 adv[\t] = 82.653（而这一行 tab 在行首、真实 advance = 96）
        ⇒ 少算 13.3467 ⇒ [\tb] 当成 96 ≤ 100 塞下 ⇒ 2 行 ✗
@w96 行1 ：a = 96 == room = 96 ⇒ 1c② 等号 ⇒ tabClamped=true ⇒ :1777 直接接受 ⇒ 根本不进 fallback
        ⇒ 那把旧尺子没机会出错 ⇒ 3 行 ✓
```
⇒ **`96` 与 `100` 的唯一分叉 = "是否落进 fallback"**（主控推演里漏的正是"资格跳过 ⇒ 落进 fallback"这一步 —— **由 T1d 补上**）。

**件 1d（已授权，统一规则、非特例）**：fallback 里对 `\t` 那一格按**当前行笔位**重算 advance：
```
pen_line = lineContentStart + w
若 pen_line + tabInterval > width ⇒ 该格按 tabInterval 计（放不下 ⇒ break）
否则 ⇒ stop_line = (⌊pen_line/tabInterval⌋+1) × tabInterval；该格按 (stop_line − pen_line) 计
```
**必须保留 `tabIntervalUse > 0` 守卫**（`I_tab=0` ⇒ `zero` ⇒ 不许 `stop_line` 退化为 0）；判据 = `tab-zero` 逐字节不变。
**写死预言（轮 11）**：**剩余 4 条 → 0 ⇒ `结构败 0`、`判定过 288/288`**；`@w96` 两条与 `@w140@i24`/`@w140@i24nl` **不许反向**（T1d 已承诺反向即停、不加特例）；`tab-zero`/`tab-rtl` 逐字节不变（`tab-rtl` 按 §4.6.6 替换口径）；`tline` 数值不变；`Extent` 36/`0.0628`/95。
**剩余 4 条（线索干净）**：`A-anchor/lat-a-t-b@w96`、`lat-ab-t-c@w96` **全 PASS**；`lat-a-t-b@w100`、`lat-ab-t-c@w100` **仍红**（`行数 期望=3 实得=2`）。⇒ **残余被压缩到"`W` 96 → 100"这一个差别上**。
**已派 T1d 只读复算 `w100` 那两条**，并明确：按主控的推演 `w100` 也应是 3 行（`pen+I = 109.3467 > 100` ⇒ 拒 ⇒ fallback 同尺 ⇒ `[a]`；行1 `[	]` 拟合 `96 ≤ 100` 应被接受 ⇒ `best=2`）⇒ **与实测 2 行不符 ⇒ 说明主控对某一步的理解有错**，要 T1d 找出真正分叉点并给可证伪修法；**若"`>` 与 `>=` 需在两种 `W` 下并存" ⇒ 报主控**（说明还有一条条件）。

**件 1c（已授权，两处同落）**：① fallback 的塞满循环对 `\t` 套**同一条条件式**；② 测量侧钳位判据 `a > room` → **`a >= room`**。
**写死预言（轮 10）**：**组 A 8 → 0 ⇒ 结构败 8 → 0、`判定过 288/288`**；`@w140@i24`/`@w140@i24nl` **仍 1 行 `w=109.35`**；`tline` 数值不变；`Extent` 36/`0.0628`/95；`tab-zero`/`tab-rtl` 按替换口径判。**1b′ 留**（零位移 + 1c 同源前提）。
### 4.6.6 **件 1b′ = 零位移**（轮 9），它把"强制断 fallback 那把尺子"钉成唯一缺口

**件 1b′（纯新增 7 行，条件式）**：`bool lineStartTab = IsLineStartTab(pen, lineContentStart); if (!zero && !lineStartTab && pen + tabInterval > clampWidth) a = tabInterval;`
**轮 9 读数（`tab-anchor`）**：日志 **`7e5b906b69ca5658`** —— **与轮 7 逐字节相同**；`判定过 280 / 结构败 8`（与轮 7 完全一致）；`tab-zero`/`tab-rtl` 逐字节不变 ✓；`tline 6071ce9d710f17b4` 数值不变 ✓。
⇒ **件 1b′ 的可观测位移 = 0**。**这个"零位移"本身就是决定性读数**（它不是"没测到变化"，而是"**证明改动未产生效果**"）：`:1777` 按条件式确实拒了组 A 的候选（`pen + I > W` ⇒ 贡献取 `I` ⇒ `109.3467 > 96/100` ⇒ 拒），但**紧接的强制断 fallback（`adv[e]` 那把尺子）又把同一行塞回** ⇒ 净效果为零。

⇒ **唯一剩余缺口 = "让 fallback 与 `:1777` 用同一把尺子"（件 1c，已派）**；**缺的读数 = `adv[]` 对 `\t` 的取值**（`CharAdvances()` 的 tab 项：是否等于整形侧 `stop − pen`、是否含 `clampUse`/`gridAnchor`）。
**件 1c 的写死预言**：**组 A 8 → 0**（⇒ `结构败 8 → 0`、`判定过 288/288`）；**`@w140@i24` 与 `@w140@i24nl` 仍 1 行 `w=109.35`**（fallback 里也必须**带条件**，无条件就是 1b 的老错）；`tab-zero`/`tab-rtl` 逐字节不变、`tline` 数值不变、`Extent` 36/`0.0628`/95。

**方法论登记（值得单独记）**：**"跨轮日志 sha 相同"是一个**正面证据**，不是"没变化"** —— 它证明"改动在读数面上未生效"（本轮据此把 fallback 定为唯一缺口）；与之相对，T1d 早前那次"探针改了、日志也逐字节相同"却是因为**改错了块**（`RunTabOracle` vs `RunTabLinesOracle`）⇒ **同一个现象（日志不变）有两种完全不同的解释，必须靠代码级定位区分**。

**轮 8 回退（已验收）**：`ed88989b92ed5d64`（轮 7 态）—— `cmp` 逐字节 ✓、`touch` **强制重编** ✓、三连 `error CS = 0/0/0` ✓、1b 行计数 **0** ✓ ⇒ 净回归移除，回到结构败 **8**。

**✅ "两把尺子"假设成立（T1d 用算式对上两条读数）**：`:1777` 的拟合用"经 `EffectiveWidthTab` 的贡献"，而**强制断 fallback（2c 改过的 `:1784`）用 `adv[e]`（逐字符 advance）** ⇒ `:1777` 判拒后 fallback 把同一行塞回 ⇒ **组 A 一条不动**（与读数一致）；`@w140@i24` 那条亦由此解释（我方 `[len=1]w=37.35 | [len=3]w=109.35` 与推演逐位相同）。

**✅ 真正的判别式（T1d 定案，5 条同一张表）—— 条件式，不是无条件**：
```
行中 tab：若 pen + tabInterval > clampWidth ⇒ 贡献取 I（候选必然超宽 ⇒ 断在 tab 之前）
          否则                          ⇒ 照旧 stop − pen（写出/advance 也是它）
```
| 用例 | `W` | `I` | `PI` | tab 前 pen | `pen + I` | 真值 | 真值 tab adv |
|---|---|---|---|---|---|---|---|
| `lat-a-t-b@w96@i0` | 96 | 0 | 0 | 13.3467 | **109.35 > 96** | 断（3 行） | — |
| `lat-a-t-b@w100@i0` | 100 | 0 | 0 | 13.3467 | **109.35 > 100** | 断（3 行） | — |
| `lat-ab-t-c@w96@i0` | 96 | 0 | 0 | 26.6933 | **122.69 > 96** | 断（3 行） | — |
| `mid-tab-a-t-b@w140@i24` | 140 | 24 | 0 | 37.3467 | **133.35 ≤ 140** | **不断（1 行 `w=109.35`）** | **58.653** = 96 − 37.3467 |
| `lead-tab-b-t-c@w220@i24` | 220 | 24 | 0 | 37.3467 | 133.35 ≤ 220 | 不断（1 行 `w=204.00`） | 58.653 |

⇒ **件 1b 的错被定量指出**：无条件替换凭空多出 `96 − 58.653 = 37.35`，把 `[a\tb]` 顶到 `146.69 > 140` ⇒ 过早断行（正是那 2 条新坏）。
⇒ **件 1b′（已授权，条件式）**：`if (!zero && !lineStartTab && pen + tabInterval > clampWidth) a = tabInterval;`
**写死预言**：**组 A 8 → 0**、`mid-tab-a-t-b@w140@i24` 与 `@w140@i24nl` **保持/回到 1 行 `w=109.35`** ⇒ **结构败 8 → 0、`判定过 288/288`**；`tab-zero`/`tab-rtl` 逐字节不变、`tline` 数值不变、`Extent` 36/`0.0628`/95。
**若组 A 仍不动** ⇒ 下一份待取读数 = **`adv[]` 对 `\t` 的取值**（`CharAdvances()` 的 tab 项），用它对齐 fallback 的尺子；**不许猜**。
**另一条独立佐证（T1d 交叉核对）**：组 A 的 `w100` 里真值 `[\t]w=96.00` **停在网格 96、未被钳到 100** ⇒ 与 `room = clampWidth − lineStart` 在 `96 ≤ 100` 下不触发一致 ✓。

### 4.6.5 **件 1b 被自己的读数否掉**（轮 8，2026-09-15 18:0x）

**件 1b（纯新增 `+5/−0`）**：测量侧 `EffectiveWidthTab` 内加 `bool lineStartTab = IsLineStartTab(pen, lineContentStart); if (!zero && !lineStartTab) a = tabInterval;`（行中 tab 的判据贡献 = `I`）。**它没落 `:1771` 资格含等号**（拒绝理由成立：等号会把 `tabClamped` 在 `a == room` 时翻真 ⇒ 改变资格 ⇒ 可能改 `tab-rtl` 行划分，而 `tab-rtl` 是不变量）⇒ **主控裁定 `>=` 不落**，并记档"宁可停下也不动写死的不变量"是对的。

**轮 8 读数（`tab-anchor 93294453ef36ccb5`）**：`判定过 278`（轮 7 280）、**`结构败 10`（轮 7 8）**、`未登记 10`；`tab-zero`/`tab-rtl` 逐字节不变 ✓、`tline 205aaa54f8a8abcd` 数值不变 ✓。
**集合差（轮 7 → 轮 8，逐 case id）**：**✅ 修好 = 0 条**（组 A 那 8 条**一条未动**）、**❌ 新坏 = 2 条**：`B-indent/mid-tab-a-t-b@w140@i24@default` 与 `B-indent-extra/mid-tab-a-t-b@w140@i24nl@default`（真值 1 行 `[a\tb]w=109.35`，我方 2 行 `[len=1]w=37.35 | [len=3]w=109.35`）。⇒ **净回归 8 → 10**。

**裁定与后续**：① **回退 1b**（回 `ed88989b92ed5d64` = 轮 7 的**已测最佳状态**）—— 这不是"为了变绿而回退"，而是**移除一个被自己读数否掉的改动**（0 修好 / 2 新坏 / 净回归），照纪律 `cp` + `cmp` + **强制重编**；② 回退后**只读诊断**，复算必须**同时解释那 2 条新坏**；③ **主控假设（待证实/否掉）**：`:1771` 的拟合用"经 `EffectiveWidthTab` 的贡献"，而**紧接的强制断 fallback（2c 改过的 `:1784`）用的是 `adv[e]`（逐字符 advance = 整形侧写出的 `stop − pen`）** ⇒ 两把尺子 ⇒ `:1771` 判拒后 fallback 又把同一行塞回 ⇒ **组 A 一条不动**（正是读数所见）；④ **新坏那 2 条同时说明"行中 tab 贡献恒取 `I`"过强**（`@w140@i24` 真值 1 行 `[a\tb]`，而按 `I` 算 `122.69 + 24 = 146.69 > 140` ⇒ 被拒 ⇒ 断在 tab 之前，与真值相反）⇒ 要求 T1d 把组 A 8 条与这 2 条**放进同一张表**逐位对比，找出**真正的判别式**。
**件 2c 的机制 M（T1d，逐位复现实测）**：`:1771` 先判"放不下" ⇒ `best = -1` ⇒ 进「规则 3 强制断 fallback」，而该 fallback 的塞满循环在 `:1784` **只比 `w + adv[e] <= width`、漏了内容起点** ⇒ 两字符被一起塞进一行 ⇒ 我方 `w = 26.6933 + 24 = 50.6933` —— **与实测 `w=50.70` 逐位相同**。**普查**：全文件"含 width 的拟合比较"只剩两条（`:1771` 已改、`:1784` 漏改）⇒ 2c = 补这一条。

**件 2 的族级明细（轮 1 → 轮 2）**：`B-indent-extra/lead-tab-b-t-c` 7→5、`mid-tab-a-t-b` 7→5（**好转**）；`B-indent/lead-tab-a` **0→4**、`lead-tab-b-t-c` 5→7、`lead-tab-only` **0→3**、`mid-tab-a-t-b` 5→6（**反向，合计 +10**）；`A-anchor`/`D-paraindent`/`notab-control` **不动**。
**诊断（T1d 复算 4/4）**：`B-indent/lead-tab-*` 恰是 `I=24, PI=0` 那一族 ⇒ 测量侧已按**内容起点**算 `room`，而**整形侧 `ApplyTabStops` 仍用旧约定**（现行 `startPenX = indentDip`、`lineContentStartX = indentDip`；真值要 **`startPenX = 0` + `lineContentStartX = I + PI`**）⇒ 两侧错位。**落点 = `:2794`（`FormatLine` 内）+ `:651`（`HbMultiFontShaper` 路径）**，已授权补完（件 2 的第二半）。

### 4.6.2 件 1 的落法**修正**（我的"两侧逐字同改"作废，按 oracle 直证改）

T1d 用 oracle 的 `perChar` **直接证**明：被保留的行里，**行中 tab 写出的 advance 一律是 `stop − pen`**（`82.6533` / `69.3067` / `82.4867`），**从不是 `I`**（96）；而**断行判据**必须把行中 tab 的贡献记成 **`I`**（`13.3467 + 96 = 109.3467 > 96/100`）才与真值的 3 行一致。
⇒ **判据用 `I`、写出用 `stop − pen`，两者刻意不同**（"报出宽 = 各行实际 advance 之和"，真值本身就允许判据宽 ≠ 报出宽）。
⇒ 件 1 的正确形态 = **测量侧改判据**（行中 tab 贡献 = `I`）＋ **整形侧照旧写 `stop − pen`** ＋ `:1771` 资格按 `tabClamped` **含等号**。
⇒ **可判别读数（两条，互斥）**：若实际 advance 取 `I` ⇒ `lat-a-t-b@w140` 行宽应为 `122.69`、tab 的 `perChar.width` = 96；若取 `stop − pen` ⇒ 行宽 `109.3467`、`perChar.width = 82.6533`（**真值 = 后者** ⇒ 定案）。

## 4.6 落地清单的最终收敛（2026-09-15 17:4x；`(A)` + 缩进几何一组）

**① 探针是前置，已修并已验证**：`build/MilBridge/tests/CoverageProbe/Program.cs` 的 `RunTabLinesOracle`（**门禁三支 tab 臂的真正仪器**）
此前**从未把 oracle 的 `indentDip`/`paragraphIndentDip` 喂下去**（该段 `grep -c "indent"` = 0）⇒ 208 条非 0 缩进用例结构性不可比。
**修法**（`Program.cs 9bece92645db596a → 492f651680d1bf14 → a8727a5bed6bf049`）：按 oracle 原值喂。**决定性读数（shim 一行未改）**：
`结构败 132 → 49`、`判定过 110 → 180`、`未登记失败 178 → 108`、日志 `7080853d7ddd9b2f → 94bfd595b93e68da`。
⇒ **T1d 的预言成立**：shim 侧本来就对、**`(B) :3874` 是正解**（"零位移"只因 `indent ≡ 0` 时新旧恒等）。

**② 剩余 49 条 = 两件**：**件 1 = `(A)` 一对**（`:1867`/`:1873` 测量侧 + `:409`/`:417` 整形侧**同改** + `:1771` 资格含等号）；
**件 2 = "缩进进几何"一组**（第三处 `:1764`/`:1767`/`:2837` + 翻 **S6** `:390 TabClampInset(pi) => pi`）。
**第三处的证据（notab-control 8 条，纯缩进无 tab）**：`@w40@i24` 真值 **2 行** x=24（`24 + 26.69 > 40` ⇒ 断），而我方 `:1767` 的 `wb` 是**纯内容宽、没加内容起点** ⇒ 误判放得下 ⇒ 只出 1 行 ✓ 与实测吻合。

**③ 主控裁定（`Width` 公式的"矛盾"）：判 (a) —— `:2819` 不动。** 理由（**推断，待测**）：notab 两条直接测出 `Width = Indent + 内容`
（`@i24p0` ⇒ 50.6933 = 24+26.69；`@i0p24` ⇒ 26.6933）＝现式；tab 那条 `[\t] w=76.0` **不需要**改公式即可由 **钳位目标 = `W − PI = 76`** + "tab 的 adv 在行盒坐标系里算"解释。
**待测判别读数（写死）**：翻 S6 后，`D-paraindent/lead-tab-a@w100@i0p24@default` 我方应给出 **`[\t] w=76.00`**；**若给出 52 或其他值 ⇒ 我的推断被否 ⇒ 停、改 `:2819`**。

**④ 预期读数（落地后照此验；任一族不动或反向 ⇒ 停）**：`A-anchor` 4 → **0**｜`B-indent*`（12 + 25/39）**显著下降**｜`D-paraindent`（8 + 35）**显著下降**（受 ③ 影响可能留一部分）｜`notab-control` 8 → **0**｜`tab-zero`/`tab-rtl`/`textlineproto`/`tline` **不动**（`PI=0` 时 `TabClampInset(0)=0` 恒等；b34 不传 `indentDip` ⇒ 件 2 在那条路径恒回退 0）。

## 5. 回滚

- **shim**：每一步整份备份进 `~/t1d-backups/`（文件名带 sha16），`cmp`/`sha256sum` 自证 + **强制重编**（纪律 24）；回退后**必须**重取读数（旧读数已随世代绑定作废）。
- **PC 半**：走应用器 ⇒ 用应用器自身的前后 `--check` + `check-appliers.sh`（`miss=0`）；**PC/PF/桥任一变了 ⇒ 波作废、重跑波**。
- **`D-O1` 单独回滚**（它是唯一"打开折叠路径"的改动）：回退后 `T3`/`T3b` 的读数应回到 `#15` 形态（`232/236` 等），若没回 ⇒ **说明位移来自别处**，立即停并报主控。

## 6. 本预登记自己的口径

- 凡引用"某读数 = 某值"，必须连 **件 sha + 仪器 sha + 判据口径 + artifact/字段** 一起写（纪律 15/18/26）。
- **主判据 = "段数 / Σ虚拟"**（内存类）；**RSS 只作旁证**。
- **行号会漂**：本文件所有 `:NNNN` 都标了"现树实读"的出处；**落地前必须现场重读**（已在 `#15` 被咬过一次：`:3086`/`:1589`/`:331` 全已位移）。
- 本文件与 `docs/WAVE15-PREREGISTRATION.md`/`docs/WAVE15-RUNBOOK.md` 冲突时，**以本文件为准**（它更晚、且吸收了 `#15` 的实测教训）。

## 7. `#16` 收官（2026-09-15 18:37–19:0x，主控）—— **本节的读数取代本文件此前所有"波前"读数**

### 7.1 波（`close-wave.sh`，`WAVE_OWNER=主控`）
`18:37:16 → 18:41:17`、`OUT=$HOME/wfp-runs/close-wave-w16`、`W16_WAVE_EXIT=0`：**native 重建=0／桥重发=0／`verify_all=PASS`**；汇总 `close-wave-summary.txt`。
**发波原因**：门禁曾报 **`hbtextline_shim_stale=yes`** —— 当时 `pc` = `303604882d71f954`，**早于**最终 shim 件（`bc04c05ab6d8d82a`）⇒ 那一趟 `PASS` 是"用旧文本栈盖章的相容"，**不能**当最终基线。**本波的作用就是重建 `pc`**（`303604882d71f954 → c0763fc10173e7ff`）。

### 7.2 ⚠️ **本文件 §4.6.10 里那批五臂日志 sha 已被取代**（纪律 4 的现场，如实记）
§4.6.10 记的是 `18:26–18:31` 那一批（`tline.log ad07ead4022539d2` 等）。**`pc` 在 `18:38:14` 变了** ⇒ 三支 tab 臂 + `textlineproto` 是**弱配对**（日志不自报被测件）⇒ 与其推理"`pc` 为什么不影响它们"，**主控在波后树上把五臂重取了一遍**（`18:46:50–18:52:42`；先按 `arm-logs/README.md` 步骤 1 重建 `CoverageProbe`/`TextLineProto`，再逐条重跑，最后 `ln -f` 入 `arm-logs/`）。
- **结果**：`tab-zero b9d81590f3fcd800`、`tab-anchor 99d72b385fe23a90`、`tab-rtl 419e8aaa9c72a9a0`、`textlineproto 4bceceeed570ba70` **四条逐字节不变**（在 `pc` 变了、探针本地那份 `pc` 副本也被换掉的条件下）⇒ **这是"这三支臂量的是 shim 源、不是 `pc` DLL"的实测证明**（机制：`CoverageProbe.csproj` 的 `HbShimSrc` + `TEXTLINE_SHIM_DIRECT` 直接编 shim 源，`HbTextLineFactory` 声明在 shim 源内 `shim:3777`，`CS0436` 内联者胜出；佐证：探针二进制 mtime `18:25:50` ≥ shim 冻结 `18:25:25`）。**以前是推理，现在是实测。**
- **`tline` 如实记录**：`ad07ead4022539d2 → 89ad10ac614b4d3b`，`diff` **14 行、逐行都是身份/管道**（`[applocal]`/`[T0.7]` 的 `pc` 权威 sha `303604882d71f954 → C0763FC10173E7FF`、`已用时间`、`/tmp/tmp.*`、带时间戳的 artifact 路径与"上一趟 artifact"回显），**零条判据/读数行移动**，四条登记读数逐条复现。
  ⇒ **口径教训（升为纪律 36）**：这里的"同不同"**不能**用"逐字节相同"判（会误报），只能用预登记 §4.6.6 那条 **"位移允许、但每一行移动都必须被归因"**。
- **旧日志逐字保留**在 `$HOME/wfp-runs/w16/do1/*.log`（`ln -f` 只换 `arm-logs/` 那份名字，旧 inode 仍挂在原名下）。

### 7.3 登记表：`rev 6 → rev 7`（`391c907c7d114e01 → f9843bde351029dc`）
- `generation.instr_pc` `4e73167ba0aa7f5c → c0763fc10173e7ff`（**该项不参与世代绑定**：实测 `tline-gate.sh:234` 的 `GEN_KEYS = (instr_run_sh, instr_program_cs, instr_shim)`）；`evidence_log` 指向 `build/MilBridge/arm-logs/tline.log`（`89ad10ac614b4d3b`）；新增 `arms_retaken` 块（7.2 的机制证明）。
- 顺手修一条**陈旧路径**：`tab-oracle-zero` 条目的 `artifact` 原写 `$HOME/wfp-runs/tab-zero-w15.log` ⇒ 改为 `build/MilBridge/arm-logs/tab-zero.log`（旧路径存进新字段 `artifact_origin`）。
- **未新增/未删除任何判据、未放宽任何口径**；`entries` 的 `expected_shape`/`expected_reading` **一字未改**；`entries` 仍 4 条。
- **重跑门禁**：`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#16 tree_gen=same`、`GATE_REASON=all-as-registered`、`rc=0`。
- **两极化重做**：删 `tab-oracle-zero` 条目 ⇒ `unregistered=1` + `GATE_REASON=unregistered-failure` + `rc=1`；删 `tline/T3b` ⇒ 同因 + `rc=1`；真表 ⇒ `rc=0`。

### 7.4 应用门禁（两趟都留档；冻结表头取第二趟）
- 第一趟 `18:42–18:44`（`run_dir=…/mygate16`，`$HOME/wfp-runs/gate16.out` **`559d85a9bf1ac32d`**）：**6/6 `RESULT=PASS`**，读数与第二趟逐项相同；但**没设 `WPTD_BASELINE_OUT`** ⇒ **没有机读 `BASELINE` 行** ⇒ 只能当旁证。**这是主控的操作失误（runner 行为正确），如实记。**
- 第二趟 `18:53:52` 起（`run_dir=…/mygate16b`，基线文件 `$HOME/wfp-runs/w16-pre/baseline16-run2.md` **`cfd38fe2a3393fda`**，屏日志 `…/gate16b.out` **`2db6fb0e2457406b`**）：**6/6 `BASELINE … result=PASS`**，`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10 runs=167`；`drawn=260`（default）／`144`（env）、`colors=3960／2828`、`frames_good=14/14`、`capture=ok`、`scroll=ok`、`cross_ae=0`、`leftover_after=0`；`hbtextline_shim_stale=no`（**这一位就是本波存在的理由**）、`BRIDGE_SRC_STALE=no`。

### 7.5 冻结
- `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`：置入 **`#16` 表头**（`#15` 表头降为历史块，原文逐字保留）。九位：`bridge caf7baf9e67719aa`(4,983,696 B)｜`pc c0763fc10173e7ff`｜`pf 9ef136caddb10370`｜`windowsbase e6216fe961a2bfb9`｜`provider 9aa0d744802aaa31`｜`win32shim 0098234982391bbf`(283,648 B)｜`wic_shim 03b67fbcd7c385b6`｜`hbtextline bc04c05ab6d8d82a`(`stale=no`)｜`dwf b6743030ff1eb907`；`BRIDGE_SRC_FP=0b7c5a54267064fc`；`inputs_fp=fe1bbcae1e20ae7caadcdf5106172401c28cea6edfd4b66b55cc841b3de29adf`（**波前 == 波后 == 三车道收工后复算** 逐位相同）。渲染侧 `WpfGfx.Linux.dll 0c597fb6ec1eec70`（本波未重建）。
- `bash verify-all.sh`（**10 步**，静树）：**`步骤通过 10  ❌ 失败 0`**、`用例通过 871  跳过 2`、`rc=0`、第 10 步 ✅（日志 `$HOME/wfp-runs/w16-pre/verify-all-16.out` **`ce174c8cde3e9692`**）。

### 7.6 本波另开的三条车道（都只写自己的新文件；主控逐条复核过关键读数）
- **T17A**（`#17` 产物侧 shim sha）：`build/MilBridge/tools/shim-in-artifact.sh` **`e2e1a42b5f0e5b45`**、报告 `build/MilBridge/T17A-report.md` **`de044cb22c77c9c8`**；`SHIM_IN_ARTIFACT=PASS`（`new=2/2 stable=14/14`、`rc=0`），三份旧 DLL 上 `MISMATCH rc=1`、六种 `NOINFO rc=2`。**只是下界**（靠 `D-O1` 的两个新符号）⇒ **改 shim 的波必须点名新符号**，否则退化成 `WEAK-PASS rc=3`。**未接进 `verify-all.sh`。**
- **TAPPS**（app-local 检查器）：`applocal-expect.py` → **`6eafbea14e7ea41e`**、`check-applocal-sync.sh` → **`aad23482f84bdf44`**、报告 `build/DirectWrite.Linux/TAPPS-blind-half-report.md` **`9071d4bcf39918b8`**；`D-A1` 加固成 `UNEXPECTED=N[DECL-GAP-EQ/DIFF]`（类别名未改、计数未变、仍 `rc=1`），自检 17/17。**另查出 `ITEMS` 只覆盖 5 个件**（`FallbackCriteria/bin/Debug` 17 个 DLL 只有 2 个被判定；`.so` 副本连权威都没有 ⇒ 等值副本也报 `OK`+`rc=0`）与**枚举器自身漏报**（18/20、只扫 `build/**/*.sh`、只匹配字面名）。
- **TDT2**（`D-T2` 边界复核）：报告 `build/MilBridge/TDT2-boundary-report.md` **`6388461b4ecd0de7`**。**原登记的"indent 不对称"被推翻**（生成物里 `indentDip` 只有 `:256` 一处命中、两个探针都不传 indent；那个版本只存在于一份**从未编译过**的草稿）；**真身 = `TextModifier` 作用域实参不对称**（判为缺陷、量级未测）。**"没有臂消费 `minWidth`"被更强地确认**（13 宿主 0 命中；30 份 oracle JSON 都没有 min/max 输出字段；**没有任何臂驱动 PC 的 `TextFormatter`**）。
- **主控自己复核并新登记**：PC 侧 `:575` 把 `Pap.ParagraphIndent` 送进 `:256` 的 **`indentDip`** 槽（`paragraphIndentDip` 恒 0、**`Pap.Indent` 从不被传**）⇒ 应用路径的**停靠网格锚点会变成 `PI` 而不是 `Indent`**；**五臂不可见**（`layout-b34` 语料 `Indent = PI = 0`，614/614）；**量级未测、本波不许修**（一改就动 `pc`）。

### 7.7 本波**没能**收掉的（不许当绿）
`D-F1c`①c（1CJK 该 ttc **3 段**，目标 1–2）｜`D-F3`（按目录全量预载 ⇒ 内存地板）｜`D-F2`｜`ContractProbe P6`｜`D-E1`｜`D-B1`(用户已决定不开专项)｜`D-K1` 四项未闭｜`7CJK candidates=45`｜MIL 侧 `CachedFileCount/CachedBytes/LiveFaceCount`（需一个会加载 MIL 的宿主）｜`Tabs` 显式停靠位（公开 API 不存在 ⇒ 边界）｜`Extent` 余差 `95`（含 `*_tabs_*` 36 条同值位移）｜`D-R2`（静树带环境记录的绿趟计数，见 `docs/CURRENT-STATE.md`）｜`shim-in-artifact.sh` 未接线｜`ITEMS` 扩表。
