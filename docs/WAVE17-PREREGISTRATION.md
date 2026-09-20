# WAVE17 预登记（`#17` 波）—— **落地前先写死判据、预测位移与"红则停"**

日期：2026-09-15（主控）。**被 `#16` 冻结为基线**：九位见 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#16` 表头。本波一切读数都以那九位为参照。

## 0.0 ⚠️ 修订 **v2**（2026-09-15 23:3x，主控）—— **v1 里有两处是错的，本波开工前先改掉**

两条只读侦察车道（`R17A` `build/MilBridge/R17A-recon.md` `f0a8f3a65b2770cc`｜`R17B` `build/MilBridge/R17B-recon.md` `9c8f11eb6f29d15f`）在**不动树**的前提下把 v1 推翻。**v1 原文保留**（见 §1 P2/P5），更正如下：

| # | v1 写的 | 实测是 | 后果 |
|---|---|---|---|
| **F2** | P2 改法：`indentDip: settings.Pap.Indent, paragraphIndentDip: settings.Pap.ParagraphIndent` | **`settings.Pap.Indent` / `Pap.ParagraphIndent` 是**理想整数 ×300**（`TextProperties.cs:39-40/82-87`、`LineServices.cs:1290` 的 `28800.0/96`）⇒ PI=24 DIP 到达 DIP 槽时是 **7200**。**v1 这个改法自己也 ×300 错。** 正确做法 = 传 `paragraphProperties.Indent` / `.ParagraphIndent`（**原始 DIP**；`paragraphProperties` 已是 `FormatLineInternal` 的形参，gen `:512` 在作用域内） | 按 v1 落会引入一个**新的 300 倍错误**；同时说明**现状**的偏差不只是"进错槽"，还有**量级** |
| **F1** | 假定新臂走 PC 就能照出 P2 的缺陷 | 默认配置下 PC **先进严格档**（gen `:553`），而 `HbTextFallback.TryFormatLine` **根本没有 indent 形参**（shim `:4496-4497`、调用 `:4518-4521`）⇒ **`Indent` 与 `PI` 在应用活路径上被整条丢掉**（活读数 `handoff.md:1923`：`fallbackCalls=1 fallbackHandled=1 minmaxCalls=0`）。P2 只修**宽松档** | **新臂必须被引导**（`WPF_LINUX_TEXTLINE_FALLBACK=0`），否则**修完仍然是红的** ⇒ 会把"修法没用"读成结论。**严格档那条缺口另立登记**（shim 写域） |
| **计数** | 208 例非 0 缩进 | **224**（`B-indent` 72/144＋`B-indent-extra` 72/72＋**`C-rtl-indent` 16/32**＋`D-paraindent` 64/64）—— v1 漏了 `C-rtl-indent` 的 16 | 判据的分母错会让"全绿"的射程被高估 |
| **P6** | 当成"PC 侧缺陷，本波修" | **`CRITERION-MAY-BE-WRONG`**：探针**从未设置 `GlyphRun.GlyphTypeface`**（`Program.cs:198-205` 设了 7 个属性、没有这一个），而 `EndInit` → `Initialize(glyphTypeface: null, …)` 在 `GlyphRun.cs:429` `ThrowIfNull` 抛 ⇒ `GlyphRunFlags.IsInitialized`（唯一赋值点 `:452`）永远到不了 ⇒ 读 `GlyphIndices` 抛。**`GlyphRun.cs` 逐字编上游**（`csproj:543`，无应用器、无 override）⇒ **我方没有偏离上游**，上游**也不保证**登记的那条判据 | **P6 不是产品缺陷、是仪器缺陷** ⇒ 本波**改判据**（改探针 + 给它一条能变红/变绿的登记），**不碰 `pc`** |
| **`D-F2`** | 列在 P5"本波修"候选 | **`NEEDS-DEDICATED-TRACK`**，且是"**导出存在、没被 stub、但这个调用形态我方兑现不了**"：失败点 = **诚实失败守卫** `PresentationCore.Factory.Linux.cs:197`，其 `CanRoundTripFace` 用 **`ReferenceEquals` 比 SKTypeface**（`LinuxFontCollection.cs:452`），而 `SkiaFontDataCache.OpenFace`（`:91-95`）**每次调用都新建一个 SKTypeface**（缓存 SKData、不缓存 typeface）⇒ 身份永不相等 ⇒ 守卫为假 ⇒ `CreateFontFace` 返回 null ⇒ `FileFormatException`。**登记里那句"从文件取集合没接"是错的**（`DWriteFactory.GetFontCollectionFromFile` 实测非 null） | 一行语义改动**会翻 `provider` 这一位**（九位之一 ⇒ 必然重冻），还可能连带 `pc`/`pf`/`reach`；**且 `shim:3810` 是它唯一的生产调用者** ⇒ 修好会**静默打开**回退的第二条路（`FaceSlot` −1 → i）⇒ `Extent` 余差 95 / `+CJK` 34 / 三支 tab 臂 / 应用门禁都可能位移。**关键**：量爆炸半径的计数器 **`HbFallbackDiag.SegmentFaceUnresolved`（`shim:1275`，`:3823` 自增）从无任何打印点**（全仓 3 处、零打印）⇒ **写不出位移预测**，与本波"逐件先写死预测"的纪律冲突 ⇒ **移出本波、单独立项**，第一步 = **把该计数器印出来**（shim 1 行、无语义变化），先拿读数再谈修 |

**顺带纠正的登记错误**：
- `D-F2` 的**调用者清单**漏了 `CompositeFontProbe:336`（宿主）**和三个生产调用者**：`build/shims/PresentationCore.HbTextLine.cs:3810`（我方**唯一**生产调用者）、`upstream Glyphs.cs:315`（编进 `pf`）、`upstream XpsFontSubsetter.cs:613`（编进 `reach`）⇒ 实际 = **6 宿主文件/7 处 + 1 生产 + 2 上游**。
- `ProviderShapeTests.cs:143-157` **把缺陷写成了预期**：那条负断言的注释称喂进去的是"外来的面（不在集合里）"，而 `NotoSans-Regular.ttf` **就在** fixture 集合里（`:39`/`:42-43`）⇒ 与 `L25` 同族（**判据不许把缺陷当成预期**）。
- `P6` **今天没有任何自动红/绿**：`run.sh:229` 用 `|| true` **丢掉探针 rc**，`tline-gate.sh:429-434` 明说**不判它** ⇒ "日志里没有 FAIL" ≠ "通过"（纪律 27 家族）。

## 0. 本波要达成什么（两个目标，别混）

### G1（机制）= 把 `hbtextline_shim_stale` 从"下界"升级成"等号"
`#17` 三次派发、前两次车道中途死掉；第三次（车道 **T17A**）交了工具 `build/MilBridge/tools/shim-in-artifact.sh`（`e2e1a42b5f0e5b45`），读数 `SHIM_IN_ARTIFACT=PASS artifact=c0763fc10173e7ff shim=bc04c05ab6d8d82a new=2/2 stable=14/14 refs=23`、`rc=0`，并**自己写明**它是**下界**：

> 它靠 `D-O1` 新引入的两个符号（`_boxOriginX`/`boxOriginX`）才能判红；**将来某次 shim 改动若不引入新符号，这条检查会退化成 `WEAK-PASS rc=3`**。

**本波把这条边界关掉**：落地 T1c 早已备好的 **`AssemblyMetadata("HbTextLineShimSha", <现树 shim 的 sha16>)`** 路线 ⇒ 「产物里写着哪个 shim sha」变成**直接读数**，与"有没有新符号"无关。这条同时给 `#17` 那句话补上落点：**判据的射程会随被测件变化悄悄缩到零，而它当时仍然是绿的**。

### G2（真缺陷）= PC 侧三件（本波明确**不许**顺手带动 `D-E1`）
`D-T3`（`Pap.ParagraphIndent` 被送进 `indentDip` 槽）｜`D-T2` 的**真身**（`TextModifier` 作用域实参不对称）｜`HasOverflowed` 的**过时文档注释**。
三件都在 PC 侧（生成物/应用器），**一次波一起落、一次重冻**；`D-E1`（真机对 `GlyphRun` 边界 `Inflate`）**本波不碰**（预登记原文：一改就会全线位移 `Extent`，把归因冲掉）。

## 1. 落地件与逐件判据（顺序即落地顺序）

> **通用纪律**：① 每件落完**各自取一次读数**（不许两件一起测，否则归因作废）；② 凡改"会被编译进产物"的源 ⇒ **落地判据必须含 `dotnet build …` 的 `error CS = 0`**（纪律 33：应用器 `--check` rc=0 **不等于**能编译，`#16` 波第一步就因此拦下一次坏件）；③ 每件的**射程外读数必须逐位不动**，动了且归因不到 ⇒ **停 + 回退**。

### P1 · `AssemblyMetadata` 路线（G1）
- **改什么**：PC 工程的编译输入里加一条 assembly 级元数据。**注意**：`PresentationCore.Linux` 是 `GenerateAssemblyInfo=false` ⇒ 今天**一条 `AssemblyMetadata` 都没有**（T1c 实测 63 个 assembly attribute 里没有这一类）⇒ 要么由应用器/构建**生成**一个只含这一行的 `.cs`，要么显式补进 `Compile` 项。**由 PC 侧车道决定形态并在报告里写清**。
- **正极性判据**：用 `PEReader`+`MetadataReader`（**不加载程序集**）读出 `HbTextLineShimSha`，且**逐字等于现树 `build/shims/PresentationCore.HbTextLine.cs` 的 sha16**（自证闭环：写进去的和读出来的是同一个数）。
- **红证（三条，全部要）**：
  - **A**：改 shim **一个字节**但用 `cp -p` **保留旧 mtime**、**不重建** ⇒ 产物里的值**仍是旧 sha**；此时**旧的 mtime 代理会给假绿 `no`** ⇒ 这条正是 $17$ 存在的理由。
  - **B**：把源**改回去**但**不重建**（产物里仍是突变内容）⇒ 判据必须与"产物"一致（读数写 `yes`），**不是**"是否重建过"。
  - **C**：**重建** ⇒ `no`。
- **三态**：`no` / `yes` / **`NOINFO`**（算不出 ⇒ `NOINFO`，**不许报绿**）。`NOINFO` 至少覆盖：DLL 不存在、非 PE、`BadImageFormatException`、shim 源不存在、仓库根定不出。
- **风险与"红则停"**：① `GenerateAssemblyInfo=false` 下**手写** `[assembly: AssemblyMetadata]` 可能与既有 attribute 撞成 `CS0579`（重复）⇒ **实测编译，`error CS != 0` 就停**；② 它**必然改 `pc` 的 sha** ⇒ 本波必然重冻（见 §3）；③ **不许**用"改 `hbtextline_shim_stale` 的判据口径"来达成 —— 那是放宽，不是修好。

### P1 · ✅ **已落地**（车道 W17C，2026-09-16 11:07–11:20）
- **结论：下界变成了等号。** 产物现在**自报**它编译时所用的 shim 内容 sha256，**读的是编译后的产物、不加载程序集**。
- **权威写入（供 W17A 的读数归属）**：`pc c0763fc10173e7ff`（4,194,816 B @ `09-15 18:38:14.829`）→ **`18c49eec6992c7d9`**（4,195,328 B @ **`09-16 11:16:56.569`**，**+512 B = 一条 assembly attribute**）；`shim` **未变**（`bc04c05ab6d8d82a`、275,765 B、`09-15 18:25:25`）；`pdb e1aef41d033deb70 → 15e54019b2705ee5`。
- **读者（新，`PEReader`+`MetadataReader`，不 `Assembly.Load`）**：`build/MilBridge/tests/ShimShaReader/**`（`Program.cs 0ef57677afef9f6d`）。机读行（逐字）：
  `SHIM_SHA=no reason=content-compare artifact=18c49eec6992c7d9 artifact_bytes=4195328 shim=bc04c05ab6d8d82a product_sha16=bc04c05ab6d8d82a tree_sha16=bc04c05ab6d8d82a asm=PresentationCore cmp=full64 …`，`rc=0`。**三态 `rc`：`0=no` / `1=yes` / `2=NOINFO`**；**7 个 `NOINFO` 用例**全部 `rc=2` 且写明原因（产物不存在/是目录、`bad-image-format`×2、**在旧 pc 上 `attribute-absent`**、shim 源缺失、仓库根定不出）。
- **两极化 A/B/C（全带命令与输出）**：**A** 改 shim 一字节 + `cp -p` 保旧 mtime + **不重建** ⇒ **`yes` rc=1**（**旧的 mtime 代理在这里给的是假绿 `no`**）；**B** 源改回 + **不重建** ⇒ **`yes` rc=1**（判据是**内容相等**，不是"有没有重建"）；**C** 重建 ⇒ **`no` rc=0** 且 `error CS = 0`。**确定性实测**：两次构建 + 一次干净重建在私有输出里都给 `pc 3d365f38811140bf`，且重建 #2 生成文件 mtime 未变。只读性与可重复性已证（树快照 `b401137438647840` 未变、机读行连跑三次逐字节相同）。
- **生成物**：`build/PresentationCore.Linux/HbTextLineShimSha.targets`（`3aa64fd08fc7ea05`，`GetFileHash` 已实测存在于本 SDK、返回**大写**⇒ 已转小写）、`PresentationCore.Linux.csproj`（`26ce64b8f4452ed4`，第 4 行插入 6 行）。
- **⚠️ 由此更正登记（重要，比 P1 本身更值钱）：`shim-in-artifact.sh` 的 `PASS` 不区分内容** —— 车道用三份**内容不同**的 shim（`bc04…`/`b1f7…`/`6f34…`）各造一份产物，**那条工具三次都打 `PASS rc=0`**；也就是说它自述的"无新符号 ⇒ 退化成 `WEAK-PASS rc=3`"**是错的**（`WEAK-PASS` 今天**不可达**，因为它的前提 `_boxOriginX` 已永久留在树里）⇒ **那个 `PASS` 是"下界成立"的意思，不是"内容相符"的意思**。⇒ **`#17` 的判据从此以 W17C 的**等号读者**为准**；T17A 的工具降级为"**只证下界**"，**不许**再当"产物里是哪个 shim"的判据。
- **✅ 那条必补读数已经取到，缺口关闭（主控 2026-09-16 12:2x，三点对照，臂 = `PcLineOracle` 私拷副本，`WPF_LINUX_WIN32_SHIM` 已设）**：
  · **P1-off** = `c0763fc10173e7ff`（`#16` 的 pc，副本存于 `$HOME/wfp-runs/w17-laneW17A/ivtprobe/…`）⇒ `非0缩进 红=184 /224`、`rc=1`、stdout **`2bca3316fcdb264b`**；
  · **P1-only** = `18c49eec6992c7d9` ⇒ 同样 `红=184 /224`、`rc=1`、stdout **`2bca3316fcdb264b`** ⇒ **两者逐字节相同** ⇒ **"只加元数据、行为不变"从论证变成读数（`cmp` 级）**；
  · **P1+P2** = `1280323c9173bcde` ⇒ `红=72 /224`、`rc=0`、stdout `dfb250295761b4ce`（与 P1-only 差 **917 行**）⇒ **P2 的效应真实且可分离**。
  ⇒ **本条按"读数"结清**。⏪ 原缺口记载（保留）：P1 只加一条 assembly attribute、源没动 ⇒ "行为不变"当时**只是论证**，车道**没跑行为臂**。⇒ **本波收尾必须补**：在**只含 P1** 的树上（或与 P2 一起、但必须能区分）取一次行为读数 —— 判据 = **五臂读数 + 应用门禁 `drawn/colors/frames` 逐位等于 `#16`**（`#16` 的六条 `BASELINE … result=PASS` 就是现成的对照）。**若不等** ⇒ P1 不是"只加元数据"⇒ **停**。**理由**：纪律 3 的反面同样成立 —— **"应该没影响"也是一句需要读数的话**。
- **未证（照实记）**：**编进去的是哪个 `.cs` 文件**（元数据没有路径）；"诚实编译"（直接改二进制）未测；`WEAK-PASS` 分支未被执行；**"一字节突变且仍能编译"没做到**（裸追加一字节 ⇒ `error CS = 6`）⇒ 案例 C 用的是"+1 行注释"。
- **车道自报的纪律 16 违规（留档、不掩盖）**：它**改 csproj 前没有备份**、且本仓无 `git` ⇒ **csproj 的 before sha16 已不可得**（只能给 before 大小 = `205,471 = 205,939 − 468`）。

### P2 · `D-T3`：PC 侧 indent 接线
- **今天的代码事实（主控自己复核过生成物，逐行）**：`build/PresentationCore.Linux/TextFormatterImp.Linux.cs` 里 `TryFormatLine` **只有一份**（`:230-231`，形参 `double paragraphIndent = 0`）；`:256` 把它传给 `HbTextLineFactory.FormatParagraph(…, indentDip: paragraphIndent)`；`:575` 的调用点是 `paragraphIndent: settings.Pap.ParagraphIndent`。⇒ **`Pap.ParagraphIndent` 落进 `indentDip` 槽**、`paragraphIndentDip` 恒 0、**`Pap.Indent` 从不被传**。
- **改法（**已按修订 v2 更正**；PC 侧车道仍须现场重锚）**：给宽松回退的 `TryFormatLine` 加 `double paragraphIndentDip = 0`；`:256` 改成 `indentDip: indentDip, paragraphIndentDip: paragraphIndentDip`；`:575` 传 **`paragraphProperties.Indent` / `paragraphProperties.ParagraphIndent`（原始 DIP）** —— ⚠️ **不要**传 `settings.Pap.Indent`/`Pap.ParagraphIndent`（**理想整数 ×300**，见 §0.0 的 F2）。- **新臂的前置（**必须写死**）**：新臂要**强制走宽松档**（`WPF_LINUX_TEXTLINE_FALLBACK=0`），否则默认配置先进严格档、`Indent`/`PI` 被整条丢掉（§0.0 的 F1）⇒ **修完仍会红**，会把"修法没用"读成结论。- **严格档那条缺口另立登记**：`HbTextFallback.TryFormatLine`（shim `:4496-4497`）**根本没有 indent 形参** ⇒ 应用活路径上 `Indent`/`PI` 全丢（活读数 `fallbackCalls=1 fallbackHandled=1`）—— 属 shim 写域，**本波只登记、不修**。**语义依据** = 本波（`#16`）由 oracle 逐字符定下来的：`indentDip` = **网格锚点**（`startPenX`），内容起点 = `Indent + PI`；三支 tab 臂自己就是这么接的（`indentDip: indentDipCase, paragraphIndentDip: paraIndentCase`）。
- **预测位移（先写死，落完照此验）**：
  - ① **应用门禁 6/6 不变**，且 `drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`cross_ae=0`、`leftover_after=0` **逐位不变**。**✅ 前提已实测（主控 2026-09-16 11:1x，只读 grep）**：`samples/WpfTextDemo/*.cs|*.xaml` 对 `Indent` **0 命中**；全 `samples/**`（排除 `bin/`/`obj/`）对 `ParagraphIndent`/`TextParagraphProperties`/`.Indent` **全 0 命中** ⇒ **demo 与样例都不设这两者** ⇒ **本预测（应用门禁逐位不变）前提成立、可以逐字照验**；若验出任何一位变了 ⇒ 说明位移来自**别处**（P2 射程外）⇒ **停、按"红则停"回退该件**。
  - ② **五臂读数逐位不变**（臂不经过这个调用点 ⇒ 这是"射程外逐位不动"的机器断言）。
  - ③ `tline` 日志**除身份/管道行外**不变（口径 = §4.6.6："位移允许，但每一行移动都要被归因"）。
- **红证（本波必须造，否则 P2 不可判）**：**新臂 = 用已有的 `tab-anchor` 语料（其中 **224** 例非 0 缩进 —— v1 写的 208 漏了 `C-rtl-indent` 的 16）驱动 PC 的 `TextFormatter` 路径**（今天**没有任何臂驱动 PC 的 `TextFormatter`** —— TDT2 已 13 个宿主 0 命中证实），与**同一份 oracle 真值**比对。**修前该臂必红**（PC 把 `PI` 放进了锚点槽），**修后应绿** ⇒ 这就是两极性。**真值不需要重录**（`tab-anchor` 的 oracle 本来就逐例带 `Indent`/`PI` 与逐字符位置）。
- **具体预测（R17A 从 oracle 数据手算，`PI=0` 的用例可精确算：我方值必须等于 oracle 自己的 `@i0` 孪生例）**：
  · `B-indent/notab-control@w80@LTR@i24@default`：真值 `w=50.693333`、`x=[24,37.346667]` ⇒ 预测我方 `w=26.693333`、`x=[0,13.346667]` ⇒ **Δ = −24.000000**（宽与两个 x 都差）。
  · `B-indent/lead-tab-a@w140@LTR@i24@default`：真值 `w=109.346667`、tab `x=24`、`a x=96` ⇒ 预测我方 **宽 = 109.346667（这一项是绿的）**、**tab `x=0`** ⇒ **只有停靠网格锚点差 −24.000000** —— **这一条正是把红钉在"锚点槽"上的判别例**（与 P2 的机制声称一致）；**若这一例在修前不红 ⇒ 按"红则停"撤回机制判断**。
  · **88 例 `PI≠0`**（`i0p24`/`i0p48`/`i24p24`/`i24p48`）预测为红、量级 ~`300·PI`，但**逐行精确值从语料算不出来**（7200 会改写断点划分）—— **照实写"预测但不可精算"，不许编**。
- **"红则停"**：若新臂在**修前不红** ⇒ 说明"PC 把 `PI` 进锚点槽会造成可观测差异"这个机制判断**错了** ⇒ **停、撤回该结论**（不许为了保住结论去调判据）。

#### P2 的**红证已到手**（车道 W17A，2026-09-16 11:46–11:48；臂 = 新工程 `build/MilBridge/tests/PcLineOracle/**`，报告 `build/MilBridge/W17A-report.md` **`19f6fe04d165cfd9`**）
- **臂怎么造的**：入口 = **public** `TextFormatter.Create()` + `FormatLine`（**零 IVT 即可**）；IVT 只用来读正控 `MS.Internal.TextFormatting.WpfLinuxLenientTextFallback.Diagnostics`；**tier 转向 `WPF_LINUX_TEXTLINE_FALLBACK=0` 且读回自证**（读回≠0 ⇒ `rc=2 NOINFO`）。**`CoverageProbe/**` 一个字节未改**（`a8727a5bed6bf049`）—— 那条纪律 34 守住了。
- **pre-fix 读数**（命令见报告 §3.1；`rc=1`；stdout `5d0b58c0d2ef5c57`，**两条独立趟逐字节相同**）：`判定过=60 判定红=228 不可比(缺字形)=148`；**非 0 缩进 `红=184 绿=0 /224`**；**`PI≠0 红=88 /112`**；**零缩进 default 臂 `绿=52 /52`（零红）**；孪生恒等式**违反 0/72**；正控 `relaxedCalls=544 relaxedHandled=544 relaxedFailed=0`；最大差 `14400.0010 @D-paraindent/lead-tab-a@w100@LTR@i0p48@default 行#1 width`（= **300·48**，正是 `PI≠0` 的量级指纹）。
- **两个判别例：预测成立**（这是"红钉在网格锚上"的判别）：`B-indent/lead-tab-a@w140@LTR@i24@default` ⇒ 宽 `109.347656` vs 真值 `109.346667`（**绿**）、**tab `x=0.000000` vs `24.000000`（Δ=−24.000000，红）**、`a x=96.000000`（绿）⇒ **只有网格锚差**；`B-indent/notab-control@w80@LTR@i24@default` ⇒ 宽 `26.695312` vs `50.693333`、两个 `x` 各差 ≈24。
- **Δ 里那 0.001–0.002 是字体量化**（Liberation 与 Arial glyph id 逐位相同、advance 差 `0.000989`/字符）⇒ **E4/E5 的验收是 `Δ≤0.002`，不是 `Δ=0`**（拿 0 当判据会**假红**）。
- **验收表 E1–E8 与 F1 的失败分类表都在报告 §5**（含"**坏修法指纹** = `E3` 仍红且 `Δ≈+7200/14400` ⇒ 按 `settings.Pap.*` 直传的 ×300 错"）。
- **W17A 自己推翻的东西（都留档）**：① 本预登记 §1 P2 里我写的"**例 C（`@w100`）**"描述**不成立**（真值第 2 行是 `13.346667`、第 1 行宽 `96.000000`，且与 `@i0` 孪生**逐位相同** ⇒ 结构与 `@w140` 同型，不是"多行+第二行也吃 Indent"）；② **recon §1.3 的"判定过 ≈104"是口径错** —— 那是**可比集大小**，不是通过数；③ recon 建议"不新开工程、加进 `CoverageProbe`"**未采纳**（纪律 34）。
- **它抓掉自己三处仪器缺陷（都会造假红/假绿，照实记）**：① `new GlyphTypeface(new Uri(...))` 在本机对 `.ttf` 抛 `FileFormatException` ⇒ 它返回 −1 而调用点把 −1 读成"**有**字形" ⇒ **148 例不可比被当成可比**（红数一度虚高到 **395**）；② 孪生 id 取子串起止写错 ⇒ 孪生表**结构性为空**；③ `MockTextSource` 复用单个 `TextCharacters` ⇒ `GetTextRun(cp)` 的 run 覆盖全段剩余字符 ⇒ 第 2 行起 `Width` 恒 = 段落宽（**恰好在判别例附近把 96 抬成 98**）。
- **两条射程限制（**不是产品缺陷**，判据必须**按分桶**读，不许拿总红数 228 当判据）**：① **`@…@tab0` 臂 218 例不可测** —— `DefaultIncrementalTab` **不在** PC `TryFormatLine` 的形参表里（生成物 `:230-231`）⇒ shim 恒取 `4×em=96` ⇒ **零缩进那 44 条红 100% 来自它**（default 臂零红）；② **严格档零射程**（shim `:4496` 无缩进入参）⇒ 本臂**主动转向宽松档**，严格档那条缺口仍属**另立登记**（shim 写域）。
- **并发协议按设计生效**：`pc` 在它作业期间被 W17C 从 `c0763fc10173e7ff` 换成 `18c49eec6992c7d9` ⇒ 它 **11:13 的第一趟作废**并**如实列进报告 §6.1**，交付读数锚在新 pc 上；`TextFormatterImp.Linux.cs` sha 未变（`f86198dfdd349332`）⇒ 预测仍可比，但**纪律 15 要求点名**这是"**同口径、不同被测件 sha**"。

#### P2 · ✅ **已落地，判据成立**（车道 W17B，2026-09-16 11:58–12:09；报告 `build/MilBridge/W17B-report.md` **`995595e2487a94e7`**（终版；早先读到的 `d2bfb047a6faa60a` 是同一文件的中途版本））
- **件**：应用器 `07dc7627f609e031`（37,625 B）→ **`a3357070dae6de99`**（41,304 B）；生成物 `f86198dfdd349332`（51,594 B）→ **`9fd04d10a6479dcd`**；权威 **`pc 18c49eec6992c7d9 → 1280323c9173bcde`**（同 4,195,328 B）。**改前先 `cp -p` 备份**（纪律 16），编译证据走**私有输出目录**且 `error CS = 0`（纪律 33）。
- **E1–E8（按 arm 拆开读，因为 `E2/E3` 的分母里混着本臂表达不出来的 `tab0`）**：
  · **E1** `rc=1（未登记失败 228）` → **`rc=0（未登记失败 0 / 红 116 / 绿 172 / 不可比 148）`** ✅
  · **E2** 非 0 缩进 红 184 → **红 0**；其中 **default 臂 `92/92 全绿`** ✅（另 72 条落 `tab0` 臂，登记保留）
  · **E3** `PI≠0` 红 88 → **红 0**；**且没有出现 `Δ≈+7200/14400`** ⇒ **不是坏修法**（`settings.Pap` 在调用点**零命中**，应用器负断言 + `grep` 复核）✅
  · **E4/E5** 两个判别例**三项全落 `Δ≤0.002`**：`lead-tab-a@w140` 的 **tab 网格锚 `0.000000 → 24.000000`（Δ=0.000000，精确复位）**、宽 `Δ=+0.000989`；`notab-control@w80` 宽 `Δ=+0.001979`、两个 `x` `Δ=0/+0.000989` ✅
  · **E6** 零缩进同层对照 **`52/52` 逐位不动**（射程外不动）✅ ｜ **E8** 正控 `relaxedHandled=496`（=本腿增量）、`relaxedFailed=0` ✅
  · **E7 ❌ 判据本身错了 ⇒ 被 W17B 推翻（我采纳）**：E7 要求"孪生恒等式修后仍违反 0"，实测**违反 102/144**。**理由**：那条恒等式（我方值 == `@i0` 孪生值）**在修前成立，恰恰是因为两边错得一样** —— 它把**缺陷态当成了规律**。修后我方值对了，自然不再等于"没有缩进的孪生例" ⇒ **E7 作废**（与 `L25`、`ProviderShapeTests` 同族：**判据不许把缺陷当成预期**）。
- **登记（136 条，全在 `tab0` 臂）**：`--known-red` **臂本来就有**（`Program.cs` **一个字节未改**）。**必须分清的两件事（W17B 分清了）**：① **仪器侧** = 本臂**无从**把 `DefaultIncrementalTab` 喂下去（PC 实参表里没有它的位置）⇒ 该族**不可测**，登记是**如实标注射程**；② **产品侧** = `DefaultIncrementalTab` 在 PC 路径上**确实没接到工厂** ⇒ **这是一条真实的产品缺口**，本波**只登记不修**（另立 `D-T4`，见下）。
  **差分实证（把"登记会不会动测量"这件事本身测掉）**：在**修前** pc 的私生产物上跑两趟（不给表/给表）⇒ `diff` 467 行**全部**是 `UNREGISTERED ↔ KNOWN-RED` + 4 行汇总，**"非登记类差异行数" = 0** ⇒ **登记表一个测量数字都没动**；且不给表那趟的 stdout 与 W17A 交付的 `5d0b58c0d2ef5c57` **`cmp` 逐字节相同**（同口径交叉复核）。
  **照实记的一条"登记过宽"**：该族 136 条里修后 **20 条自己转绿**了 —— 它们**不是修好了**，而是"**错间距 96 恰好撞对**"，仍留在表里。
- **本件顺带产出的登记**：**`D-T4`（产品缺口）** = PC 路径不携带 `DefaultIncrementalTab` ⇒ 该族在**任何**走 PC 的臂上不可测、且在应用路径上也是缺口；**`D-T2-c`** 仍在（max 探针 `scopeEnd=-1`，前置未满足前不许改）。
- **纪律 4 现场**：W17A §7.2 引的 `shim :1876` **已失效**（W17B 复核），锚点引用一律以现场重读为准。

### P3 · `D-T2` 真身：min 探针的 `TextModifier` 作用域实参
- **今天的代码事实（TDT2 只读复核）**：生成物 `:302`/`:305`（max 探针）**传** `modifierOpenIndex/CloseIndex`，`:309`（min 探针）**一个都不传** ⇒ `ParagraphIndent ≠ 0` 时 max 含 indent 而 min 不含。**⚠️ 原登记写的"indent 不对称"已被推翻**（`grep -n indentDip` 全文件**只有 `:256` 一处命中**，两个探针都不传 indent；那个接法只存在于**一份从未编译过的草稿**，与 `(305,100) CS0103` 对得上）⇒ **本件处理的是"`TextModifier` 作用域实参不对称"**，不是 indent。
- **改什么**：让 min 探针与 max 探针**用同一把尺子**（补上 `modifierOpenIndex/CloseIndex`）。**一次只改这一处**：max 探针那条 `scopeEnd = -1`（"到段末"）**是否也要改**，由 **recon 车道**给结论；**同件里不许顺手改两处**（否则归因作废）。
- **预测位移**：只在"min 探针被调用**且** modifier scope 非空"时可观测 ⇒ **五臂与 `tline` 逐位不变**（没有任何臂消费 `minWidth`）。
- **红证**：构造用例使 `min > max`（TDT2 报告 §2.5）⇒ 修前必现 `min > max`，修后应 `min = max`。**若修前翻不过来 ⇒ 撤回 TDT2 §2.5 的声称、不改代码**（该车道自己在报告里写了这条退出条件）。
- **量级诚实的写法**：TDT2 给的量级是**预测不是实测** ⇒ 报告里必须照写。
- **同族必须新登记 `D-T2-c`（R17A 建议，主控采纳）**：**max 探针那条 `scopeEnd = -1`（"到段末"）也是已知错的尺子**（shim `:3855-3858` 自己标注），而 PC 的 `CollectLenient`（gen `:101-103`）**根本收集不到覆盖区的结束位置** ⇒ **今天不能改 max**（改就等于**编一个值** —— 纪律 22 明令禁止）。⇒ **本波只给 min 补成"参数对等"**，把"两个探针共用一把已知错的尺子"单列为 `D-T2-c`，前置 = `CollectLenient` 记录 `modifierScopeEnd`。

#### 应用门禁 · **两趟都做了，读数与 `#16` 逐位相同**（主控）
- **run1**（`pc=14086882b1509dcd`，P1+P2+P3；日志 `$HOME/wfp-runs/w17-pre/gate17.out`；基线 `baseline17-run1.md` **`591500e4fed84871`**）：`WPTD_GATE=PASS`、6/6 `result=PASS`。**装置来源：runner 自起的 `Xvfb :97`**（常驻 `:97` 当时已挂 —— 见 §3.1 第 7 步我那次失误的留档）。
- **run2**（`pc=ac16320a14f549d4`、`pf=3eb2367d7fa18191` = **波后九位**；日志 `$HOME/wfp-runs/w17-pre/gate17b.out`；基线 `baseline17-run2.md` **`7b73fe7a20616021`**）：`xxdpyinfo` 先确认、**runner 走"复用已存在的 X server：`:97`"分支**（常驻，纪律 30 的正路）⇒ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `BASELINE … result=PASS`**。
- **与 `#16` 的逐位对照（两趟都成立）**：`default drawn=260 colors=3960`、`env drawn=144 colors=2828`、`frames_good=14 frames_total=14 frames_blank=0`、`shot_dims=938x938`、`cross_ae=0`、`max_concurrent_apps=1`、`leftover_after=0`、`scroll=ok`、`exit=143`。
- ⚠️ **这两趟之后 `pc` 还会再变一次**：波把 P1 的元数据抹掉了（见 §1 P1 的重落与纪律 38），重落后必然重建 ⇒ **冻结表头要用重落之后那一趟的应用门禁**，本两趟是"P2/P3 验收 + 与 `#16` 的逐位对照"的证据，**不是**最终冻结行。

#### P3 · ✅ **已落地，翻转实测成立**（车道 W17D，2026-09-16 12:11–12:20；报告 `build/MilBridge/W17D-report.md` **`4b0680f0d94cf7f7`**）
- **件**：应用器 `a3357070dae6de99 →` **`188f75a67294138f`**；生成物 `9fd04d10a6479dcd →` **`56a5b4a5be1c6bcc`**；权威 **`pc 1280323c9173bcde → 14086882b1509dcd`**（同 4,195,328 B）；`pdb be6de7589ec7cbf7 → e31bef2b22c2b8c8`；**同一源复建得同 sha**（确定性）。编译：私有目录 `error CS = 0`、`warning CS = 0`；应用器 `--check` 改前 `rc=1` / 改后 `rc=0`。
- **新臂 `build/MilBridge/tests/MinMaxProbe/**`**（public `TextFormatter.Create().FormatMinMaxParagraphWidth`；零 IVT 做红证，IVT 只读正控）。**构造用例翻转（测出来的，不是断言的）**：
  · 判别例 `mod0`（**零长** `TextModifier` 在 cp=0）：**修前 `min=22.652344 max=0.000000 rel=gt`（Min>Max，真机契约禁止）⇒ 修后 `min=0.000000 max=0.000000 rel=eq`**；
  · 阴性对照 `control`（同文本无 modifier）：`min=22.652344 max=90.609375 rel=lt`，**两相逐位不动**；
  · **单变量归因**：两例唯一差别 = `CollectLenient` 有没有在 cp=0 记下 modifier ⇒ 修前 `max` 从 `90.609375` 掉到 `0.000000` **只能**归给 max 探针的 `modifierOpenIndex`（min 拿不到它 ⇒ 两例 min 都是 `22.652344`）。
- **既有臂逐位不动（射程外的机器断言）**：`PcLineOracle` 按 `W17B-report.md` §5.1 逐字复跑 ⇒ `rc=0`、stdout **`07615909a1ffaa8b`**，与 W17B 交付**`cmp` 逐字节相同**（红 116 / 绿 172 / 不可比 148 / 未登记 0）。
- **牙齿两极性**：负断言（旧形态 `out c2);`）与计数牙齿（modifier 实参必须恰好 2 处 = max+min）各被注入实验打红一次（`rc=1`），应用器随后**逐字节还原**（`188f75a67294138f`）。
- **⚠️ 它推翻的两条（都比本件值钱，已采纳）**：
  1. **TDT2 §2.5 设计的构造例（`TextModifier` 且 `Length=1`）根本到不了被测代码** —— 实测 `relaxedFailed=1 relaxedHandled=0`、`GetTextRun` 只调 1 次、随后交回 LS ⇒ `EntryPointNotFoundException: LoCreateContext`。**代码级 + 实测双证**：`TextModifier.CharacterBufferReference` 是 **sealed default** ⇒ `ExtractRun` 返 null ⇒ `CollectLenient`（生成物 `:149-152`）**必然 return false** ⇒ **只有 `Length ≤ 0` 的 modifier 能过**。⇒ TDT2 那张 worked-example 表**按字面是死的**（红证改用零长 modifier 才成立）。
  2. **由此暴露一条更硬的缺口（P3 射程外，只登记 ⇒ 新立 `D-T5`）**：**含 `Length ≥ 1` 的 `TextModifier`/`TextEndOfSegment` 的段落在 PC 路径上整条交回 LS**（Linux 侧抛 `EntryPointNotFoundException: LoCreateContext`）⇒ `CollectLenient` 里那套 modifier 记账（`:156-157`）在**真实源**上**永不生效**；`#13` 的零宽接线**只被工厂级臂验证过**。

#### P2 的应用门禁预测 ① + P1 的中性 —— ✅ **成立（一把读数同时确认两条）**（主控 2026-09-16 12:2x，`pc=14086882b1509dcd` = P1+P2+P3）
- **读数**：`run-wpftextdemo.sh 90 --tier both`（`repeat=3`）⇒ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `BASELINE … result=PASS`**（日志 `$HOME/wfp-runs/w17-pre/gate17.out`；基线文件 `baseline17-run1.md`）。
- **逐位对照 `#16`**：`default drawn=260 colors=3960`、`env drawn=144 colors=2828`、两档 `frames_good=14 frames_total=14 frames_blank=0`、`shot_dims=938x938`、`cross_ae=0`、`leftover_after=0`、`scroll=ok` —— **全部逐位相同**（`#16` 表头的 6 条 `BASELINE` 行就是现成对照）。
- **为什么一把读数能同时确认两条（把理由写清，免得被读成"两件一起测"）**：P2 的预测① 与 P1 的"行为中性"**都预测"不变"** ⇒ **没有位移就没有需要归属的东西**；而"P2 的效应真实存在"这件事**已经由臂分离测出**（三点对照 + E 表：非0缩进红 184→72、tab 网格锚 `0→24.000000`）。
  **反过来才是不许的**：若这趟读数**变了**，就必须**停**并逐件分离 —— 那时"两件一起测"才会变成归因问题。
- **装置来源（点名，纪律 30）**：这一趟跑在 **runner 自起的 `Xvfb :97`** 上（常驻 `:97` 当时已挂）—— 见 §3.1 第 7 步留档的我那次失误；**重冻那趟必须跑在常驻 `:97` 上**。

### P4 · `HasOverflowed` 的过时文档注释 —— ⏸️ **本波不做（主控裁决 2026-09-16 12:2x，理由写死）**
**裁决 = 推迟到"下一件要动 shim 的波"**。**三条理由**：① 本波 P1/P2/P3 **全在 PC 侧**、`shim` **一个字节未动** ⇒ 世代绑定（`run.sh`/`Parity`/shim）**没变** ⇒ 已实测 `tree_gen=same`、门禁 `PASS` ⇒ **本波不需要重取五臂、不需要重钉登记表**；而 P4 一改 shim **就会强制**一次完整的重取+重钉周期（5 臂 + 两极化），**换来的只是"一行注释"**；② 它原本的"附带价值"（演示 `#17` 那条"无新符号就退化"的边界）**已被取代** —— W17C 的**等号读者**让"无新符号"这个问题**不再成立**，而且 W17C 已经用一份**更强**的实验把 T17A 那条边界**推翻**了（三份**内容不同**的产物都打 `PASS`）；③ 纪律 31 的第一条出路就是"**先做完该做的读数、再改仪器文件**"。⇒ **登记为已知的"代码内陈述过期"，随下一件动 shim 的活一起做**（与"严格档 indent 缺口"同批，那次本来就要重取臂）。

⏪ 以下为原计划（保留备查）：
- **现象**：`build/shims/PresentationCore.HbTextLine.cs` 里 `HasOverflowed` **上方的文档注释仍写着"本实现恒 false"**，而该属性在 `#16` 已改成三分支真实现（`D-O1`）。`D-O1` 落地时**顺手更正过** `_startPenX` 的注释，**这一处漏了**。
- **改什么**：只改注释文字（`build/shims/**` = shim 侧车道）。**不许夹带任何语义改动**。
- **预测（先写死）**：`shim` 的 sha 变、`pc` 的 sha 因重建而变；**所有判据读数逐位不变**（依据 = `#17` 的实测：纯注释短语 `行盒远缘` 与局部变量名 `penLine` 在 DLL 里**处处 0 命中** ⇒ **注释不进元数据**）。**这条预测本身就是"注释不改行为"的机器断言**：若 `tline`/`tab-anchor` 有任何读数位移 ⇒ **停**，因为那说明位移来自别处。
- **附带价值 —— 已被 P1 的实测改写（保留原预测以供对照）**：原预测是"若 P1 未落，`shim-in-artifact.sh` 会退化成 `WEAK-PASS rc=3`"。**实测（W17C）：不会退化，它照样打 `PASS rc=0`，哪怕产物内容不同** ⇒ 那个 `PASS` **不区分内容**。⇒ **本件的验收改用 W17C 的等号读者**：注释改动后 `pc` 重建，读者必须仍报 **`SHIM_SHA=no`**（**等号**），而这与"有没有新符号"无关 —— **这正是 P1 买来的东西**。**两种结果都要逐字记录**：① 等号读者 `no`（预期）；② 等号读者 `yes` ⇒ 说明 `AssemblyMetadata` 没有跟着重建更新 ⇒ **停**。

### P5 · `P6`（**改判为仪器缺陷**）与 `D-F2`（**移出本波**）—— v2 按两条 recon 改判

#### P5-a · `P6` = **判据错，不是产品错** ⇒ 本波修**探针 + 登记**，**不碰 `pc`**
- **实测链**（R17B）：抛点在 **`ContractProbe/Program.cs:211`**，即 **在 `EndInit`（`:208`）之后**；`:209` 把 `EndInit` 的异常**吞进一个从不打印的局部变量** ⇒ 现场只剩"读 `GlyphIndices` 抛 `InvalidOperationException`"这一半。
- **真实缺的是什么**：探针在 `:198-205` 设了 **7 个属性、唯独没设 `GlyphRun.GlyphTypeface`**（setter 在 `GlyphRun.cs:899-906`）；于是 `EndInit` → `Initialize(_glyphTypeface = null, …)` 在 **`GlyphRun.cs:429` `ArgumentNullException.ThrowIfNull(glyphTypeface)`** 抛 ⇒ `GlyphRunFlags.IsInitialized`（**唯一赋值点 `:452`**）永远到不了 ⇒ `CheckInitialized()`（`:2337`/`:2344`）抛。上游 `GlyphRun.cs:46-49` 原文写明"**完全初始化之前不支持全部操作**"。
- **归因**：`GlyphRun.cs` **逐字编上游**（`build/PresentationCore.Linux/PresentationCore.Linux.csproj:543`；`src/WpfGfx.Linux.Native/tools/patch-*.py` 对它 **0 命中**，正对照 `TextFormatterImp` 有命中）⇒ **没有应用器锚点可改，我方也没有偏离上游** ⇒ **登记的那条判据本身不成立**。
- **本波改什么**：① 探针补 `gr.GlyphTypeface = <真 GT>`；② **把 `:209` 吞掉的 `EndInit` 异常打出来**（否则下次再出这种"半截现场"）；③ **登记一条能变红的期望** —— 因为 `P6` **今天没有任何自动红/绿**：`run.sh:229` 用 `|| true` 丢掉探针 rc、`tline-gate.sh:429-434` 明说不判它 ⇒ **"日志里没有 FAIL"必须写清它不是通过**。
- **红证（非空性，两条）**：**A′** 把补的那行 `GlyphTypeface` 删掉 ⇒ 原异常**必须回来**；**B** 另造一个"3 个 glyphIndices / 2 个 advanceWidths"的 `GlyphRun` ⇒ `EndInit` 必须抛 `ArgumentException`、且读 `GlyphIndices` **仍然必须抛** —— 这条专门堵"把 `CheckInitialized` 改松"这种作弊。
- **顺带一条（R17B 提醒）**：`LinuxFont.SimulationFlags => 0` 是硬编码（`FontModel.cs:171-172`），而上游从 `font.SimulationFlags` 推（`GlyphTypeface.cs:75`）⇒ 若将来走"路径+面号"身份，会**丢掉 StyleSimulations** ⇒ 要么显式断言、要么拒绝该组合。

#### P5-b · `D-F2` = **`NEEDS-DEDICATED-TRACK`，移出本波**
- **改判依据**见 §0.0 的 `D-F2` 行（失败点 = `ReferenceEquals` 身份守卫 vs `OpenFace` 每次新建 SKTypeface；登记里"从文件取集合没接"**被实测推翻**）。
- **移出的硬理由（不是"太难"）**：修它**必然翻 `provider` 这一位**（九位之一 ⇒ 必然重冻），且 `shim:3810`（我方唯一生产调用者）的行为会**静默打开回退第二条路**（`FaceSlot` −1 → i）⇒ `Extent` 余差 95 / `+CJK` 34 / 三支 tab 臂 / 应用门禁**都可能位移**；而**量这些位移的计数器 `HbFallbackDiag.SegmentFaceUnresolved` 从无打印点** ⇒ **本波的"逐件先写死预测位移"这条纪律在这一件上做不到** ⇒ 纪律冲突 ⇒ **另立专项**。
- **专项第一步（写死）**：把 `SegmentFaceUnresolved`（`shim:1275`，在 `:3823` 自增）**印进 `SummaryFragment()`**（shim 1 行、无语义变化）⇒ 先拿"今天有多少面解析不出来"的读数，**再**谈修 `D-F2`。**同批要改的**：`ProviderShapeTests.cs:143-157` 那条负断言**把缺陷写成了预期**（注释说喂的是"外来的面"、其实那个 .ttf **在** fixture 集合里）。

## 2. 本波**不做**的（写清，免得被"顺手"带走）
- **`D-E1`**（真机 `Inflate`）：一改就全线位移 `Extent`。
- **`D-F1c`①c 的修法**：本波只**取读数**（见 §5），不改 provider 的面建策略。
- **`shim-in-artifact.sh` 接进 `verify-all`**、**runner 的 X 竞态前置拒绝**：两条都会改判据面，**放在本波重冻之后**（§3 之后单独做）。
- **`D-A1` 的 EQ 类**：已裁定**保持红**（见 `docs/CURRENT-STATE.md` §4 的裁决行）；合法变绿的路子是**在 csproj 里把副本声明出来**，不是消音。
- **严格档（`HbTextFallback.TryFormatLine`）的 indent 缺口**：shim 写域，**本波只登记**（§1 P2 的 F1）。
- **`D-T2-c`**（max 探针 `scopeEnd=-1` 与 `CollectLenient` 收不到覆盖面结束）：**只登记**，前置未满足前不许改（改 = 编一个值，纪律 22）。
- **`D-F2` 专项**与 `ProviderShapeTests` 的"把缺陷当预期"：见 P5-b，**本波不动**。
- **`D-R2` 的关闭序列**：本波开工时它必须已经跑完（见 §4）。

## 3. 波形态与重冻（本波必然重冻）
- 改动落在 `pc`（应用器生成物）与 `shim` ⇒ **世代绑定（`run.sh` / `HbTextLineParity/Program.cs` / shim）里的 shim 会变** ⇒ 按纪律 34：**每件落地后重取受影响的臂**；shim 变 ⇒ **五臂重取 + 登记表重钉**（`changelog` 记探针/仪器新 sha），再跑 `verify-all`。
- 走 `WAVE_OWNER=… bash build/close-wave.sh`；**波有 `--skip-verify-all` 两段式**（`#16` 已用）：先建成、重取臂/重钉表、再 `verify-all`（10 步）。
- 重冻：新九位 + 两趟应用门禁（第 2 趟**必须**设 `WPTD_BASELINE_OUT`）+ 冻树 `verify-all` + 更新 `#16` 表头为 `#17`（`#16` 降为历史块，原文保留）。

### 3.1 `#17` 收尾清单（**逐步，不许省**；每步都要出可复算读数）
1. **P1/P2/P3/P4 逐件落地**（每件落完各自取一次读数；**不许两件一起测**）。P2 的判据 = W17A 报告 §5 的 **E1–E8**；P2 落地后**必须**用报告 §5 的**同一条命令**复跑（一个字都不改）。
2. **P1 的行为中性必须补读数**（§1 P1 那条诚实缺口）：五臂读数 + 应用门禁 `drawn/colors/frames` **逐位等于 `#16`** ⇒ 才成立"只加元数据"。
3. **P2 的应用门禁预测（§1 P2 的 ①）**：前提已实测（`samples/**` 对 `Indent`/`ParagraphIndent` 全 0 命中）⇒ 判据 = **6/6 `BASELINE … result=PASS` 且 `drawn/colors/frames/cross_ae/leftover_after` 逐位不变**；**任何一位变了 ⇒ 停**（位移来自 P2 射程外）。
4. **P4 之后**（shim sha 变）⇒ 按纪律 34：**重取五臂 + 重钉 `known-red.json`**（`changelog` 记新 sha）；并**复核**"本波新引入的符号"是否要写进 `run.sh` 自检（本波决定不接，但**要写明**）。
5. **波**：`WAVE_OWNER=… bash build/close-wave.sh`（本波改 `pc`/shim ⇒ 必然重建；能 `--skip-verify-all` 两段式就两步走）。
6. **在册红门禁**：`bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs` ⇒ 目标 `TLINE_GATE=PASS … drift=0 gone=0 unregistered=0`；**两极化重做**（删 1 条 ⇒ `rc=1`；恢复 ⇒ `rc=0`）。
7. **应用门禁两趟**（第 2 趟**必须**设 `WPTD_BASELINE_OUT`；跑前先 `DISPLAY=:97 xdpyinfo` 确认常驻 X 还在 —— 纪律 30）。**⚠️ 本波我自己在这里踩过一次（留档）**：我把 `xdpyinfo` 检查与门禁**写在同一条命令里**，检查打出 **`:97 DOWN`** 却**没有拦住运行** ⇒ 那一趟是 **runner 自起的 Xvfb**（就绪竞态的正中靶心）。**结果侥幸是干净的**（6/6 PASS、无 `exit=134`/all-blank、读数与 `#16` 逐位相同），**但装置来源更弱** ⇒ 冻结表头里**必须点名**它，且**重冻那趟要在常驻 `:97` 上跑**。**判据**：`xdpyinfo` 不在 ⇒ **先起常驻 `Xvfb :97`（`setsid nohup … &`）再跑**，**不许**把检查写成"只打印不拦人"。
8. **`verify-all`**（10 步；静树；每趟记 `loadavg`/`mem_available`）。
9. **等号读者**（W17C 的 `ShimShaReader`）在新产物上必须 `SHIM_SHA=no`；**同批**记 T17A 工具的 `PASS` —— 两者**并列留档**，因为"两条都绿、其中一条其实不分内容"正是本项目最怕的假绿（见 §4 的 `D-R4`）。
10. **重冻 `#17`**：新九位 + 6 条 `BASELINE` 行 + `inputs_fp` + 仪器版本；`#16` 表头降为历史块（**原文逐字保留**）；**撤掉顶部的"在飞"横幅**（它此刻正在生效）。
11. **文档收尾**：`docs/CURRENT-STATE.md` §1/§3/§4（`D-R3`/`D-R4`、P1–P4 的落地与残项）、`handoff.md` 波记录、本文件收官节、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`P6` **改判为仪器缺陷** + `D-F2` 专项 + `D-R3`/`D-R4`）。
12. **不许省的边界**：`#17` **不接** `shim-in-artifact.sh` / 等号读者进 `verify-all`（接线另议，接前要先定 `rc` 语义与"每波点名新符号"的制度）；`D-E1`、`D-F2`、**严格档的 indent 缺口**、`D-T2-c`、（`@…@tab0` 臂的射程限制）**本波只登记、不修**。
13. **每一步都要回答"这趟是谁跑的 + 哪个文件 + sha"**（纪律 32），并且**任何非 0 退出码先分类再下结论**（`127`/`MSB1009` = 没跑）。

## 4. 先决条件（顺序不可颠倒）
1. ✅ **已达成（2026-09-15 23:5x）**：`D-R2` 不但**跑完**，而且**根因定案并已关闭**（测试程序集的 `SetDllImportResolver` 单槽位竞态；修在 `tests/**`，**不动九位**），并按关闭判据**连续 5 趟静树 `verify-all` 全绿**。⇒ **静树已归还**，可以开构建车道。⏪ 原条款保留：它要**独占静树**（`#16` 收官时正是"实验中途开车道"把归因搞脏过一次 —— 我自己的 `MSB1009` 那批）。
2. **本预登记先落盘**（本文）。
3. **各车道写域先宣告**（`docs/CURRENT-STATE.md` §7 的表要更新）。
4. 开工前**现场重读**所有 `:NNNN` 锚点（行号会漂 —— `#15` 被咬过一次：`:3086`/`:1589`/`:331` 全已位移）。

## 5. 本波顺带要取的读数（只读，不改）
- **`D-F1c`①c**：1CJK 该 `.ttc` = **3 段**（目标 1–2）⇒ 缺的是**回退扫描窗口内的 `/proc/<pid>/maps` 归因快照**（T2 定性"瞬时 1 段在 shim 回退扫描期"）。**主判据 = 段数 / Σ虚拟**，RSS 只作旁证。
- **`Extent` 余差 95 的可证伪预言**：36 条 `*_tabs_*` 位移归因到 `D-F1`+`D-F1b` 那一对 ⇒ 把 `allowFallback:true` 改 `false`（**锚点 `:3824`**）后 36 条应消失、34 条应回到 `#13` 值。**只读车道 + 只做判别实验，不改树**（若要做，必须先备份并 `cmp` 自证还原）。

## 6. 本预登记自己的口径
- 凡引用"某读数 = 某值"，必须连 **件 sha + 仪器 sha + 判据口径 + artifact 名/字段名** 一起写（纪律 15/18/26）。
- **红检测只许加强、不许放宽**（纪律 3）；**放宽口径达成"绿"一律判为造假**。
- 凡"缺数据"⇒ **`NOINFO`**，**不许报绿**；凡非 0 退出码在当结论前**先分清它是哪一类**（`127`/`MSB1009` 是"没跑"，不是"失败"）。
- 本文件与 `docs/WAVE16-PREREGISTRATION.md` 冲突时**以本文件为准**（它更晚）。

## 7. `#17` 收官（2026-09-16 12:5x，主控）—— **本节的读数取代本文件此前所有"落地前/中途"读数**

### 7.1 三件全部落地（逐件读数见 §1 各自的"已落地"小节）
`P1` 等号元数据 ✅｜`P2` indent 接线 ✅（E1–E6/E8 全过、E7 被推翻）｜`P3` min 探针 ✅（构造例**实测翻转**）｜**`P4` 裁决不做**（理由见 §1 P4）｜**`P5` 改判**（`P6` = 仪器缺陷、`D-F2` = 另立专项）。

### 7.2 发了两次波（**第一次的那份产物不能当基线**）
`close-wave-w17`（`12:24`）：`verify_all=PASS`，但**静默抹掉了 P1**（`port-lib.py` 重生成 csproj ⇒ 手加的 6 行 import 被连同重写）⇒ `pc` 退回 `ac16320a14f549d4`（无元数据）。**所有绿判据都没红，唯一红它的是 P1 自己的等号读者** ⇒ **纪律 38** 已立（红线判据 = 跑一次 `port-lib.py` 后它还在），W17C 按正确通道重落。
`close-wave-w17b`（`12:42`）：`W17B_WAVE_EXIT=0`、`verify_all=PASS`（10 步 0 失败 / 871 通过）、**接线活过了波**、等号读者给 `SHIM_SHA=no` ⇒ **P1 耐久**。**冻结值取自这一趟之后**。

### 7.3 冻结点
九位：`bridge caf7baf9e67719aa`｜**`pc df6dbb1c2bfb4162`**（4,195,328 B）｜**`pf 388053cd4c9ba91f`**｜`windowsbase e6216fe961a2bfb9`｜`provider 9aa0d744802aaa31`｜`win32shim 0098234982391bbf`｜`wic_shim 03b67fbcd7c385b6`｜**`hbtextline bc04c05ab6d8d82a`**（本波未动）｜`dwf b6743030ff1eb907`；`BRIDGE_SRC_FP=0b7c5a54267064fc`；`inputs_fp=db3110fc78bb0346564ef37e7753e0b8483d8bf95de6642b7a2d3bf1b297738c`。**相对 `#16` 只动 `pc`/`pf` 两位。**
`Samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`：置入 `#17` 表头（**`02d29280936bbf6c`**，428 行；`#16` 降为历史块、**在飞横幅已撤**）。
应用门禁**三趟**读数逐位相同（`drawn=260/144`、`colors=3960/2828`、`frames=14/14`、`cross_ae=0`、`leftover_after=0`）；第 2/3 趟在**常驻 `:97`** 上（纪律 30 的正路），第 1 趟跑在 runner 自起的 X 上（**我那次"打印了检查却没拦人"的失误，已留档并在 §3.1 第 7 步写成判据**）。
在册红门禁 `TLINE_GATE=PASS … drift=0 gone=0 unregistered=0`、`generation=#16 tree_gen=same`（**本波 shim 未动 ⇒ 无需重取/重钉**），两极化重做（删 `T3b` ⇒ `rc=1`；真表 ⇒ `rc=0`）。

### 7.4 本波**没能**收掉的（不许当绿）
`#17` 未接任何新判据进 `verify-all.sh`｜`D-T5`/`D-T4`/`D-T2-c` 只登记未修｜严格档 indent 缺口仍在｜`P4`（注释）裁决不做｜`D-E1`/`D-F2`/`D-A1`/`D-A2`/`D-A3`/`D-R3`/`D-F1c`①c/`D-F3`/`7CJK candidates=45`/MIL 侧三个计数 —— 未动或未取到读数。

### 7.5 下一波候选（按优先级）
① **`D-R3`**（两个**产品侧无保护**的 `SetDllImportResolver` 安装点，都会翻九位）；② **`P4` + 严格档 indent 缺口**（同批动 shim ⇒ 一次重取+重钉覆盖两件）；③ **`D-T5`/`D-T4` 的判据补录**（真 modifier 的应用级可达性；`DefaultIncrementalTab` 真值需 Windows 重录）。
