# W78A · `TASK-0303`（R3 长线头一步）**只读侦察 + 最小第一步设计**

- **车道**：`W78A`｜**任务**：`TASK-0303`（`docs/ROUTES.md:200`）「PTS 最小实现（**长线**；直接救 23/24 两页）」
- **本件性质**：**只是设计，零实现**。**没有改任何产品代码**，仓内只**新增本报告一个文件**。
- **纪律实测**：零 `dotnet`｜零应用｜零构建｜零 `verify-all`/`integration-wave`｜零 `pkill`｜未碰四个路由件与 `defect-registry-declared.tsv`。
  只跑**只读**命令：`nm -D` / `grep` / `sed` / `find` / `sha256sum` / `python3`（解析源码，不写仓内）。
- **时间**：`2026-09-21 15:2x–15:5x +0800`｜`nproc=3`｜`loadavg` 开工 `2.04 2.21 1.41` → 收工 `1.02 1.59 1.60`｜`MemAvailable 1962884 kB`（开工）
- **并发**：另两条车道在跑重活（活件 mtime `15:34–15:36` ⇒ 整波重建在进行中；`pgrep -a dotnet | wc -l` = 1）。
  ⇒ **本报告里"现件"的哈希一律是"采样时刻读数"，不是冻结基线**（见 §5 NOINFO 第 7 条）。
- **重派复验**：上一条同名车道 `W75A` 的目录 `~/w75a` **不存在**（`ls: 无法访问 '/home/links-dev/w75a'`）⇒ 本车道从零开始，没有继承任何读数。
- **写入面自证**（血案纪律）：
  - 本车道对仓内的**写操作只有一处**：`build/MilBridge/W78A-report.md`（本文件，567 行）；`find $R -name '*W78A*' -o -name '*w78a*'` → **只此一件**。
    ⚠️ 本文件**刻意不写自己的 sha16**（写进去就随每次编辑自指失效）；终稿 sha16 由收尾消息给出，可 `sha256sum build/MilBridge/W78A-report.md | cut -c1-16` 现算复核。
  - 其余一切落在仓外的 `~/w78a/`：`exports.live.txt`（现算导出清单）｜`exports.old.txt`（仓内陈旧件的 `cp -p` 副本）｜`tools/check-shim-coverage.py`（工具的 `cp -p` 副本，只改 `EXPORTS`/`ROOT` 两个常量）｜`out/*.txt|json`（读数留档）。
  - 实验一律 `cp -p` **真复制**、**零 `ln`/硬链接**：`find ~/w78a -type f -links +1 | wc -l` = **0**。
  - ⚠️ 仓内 `find … -newermt '2026-09-21 15:20'` 有 **447 件**被改 —— **那不是本车道**：全部落在 `.artifacts/**`、`arm-logs/**`、`gen/**`、`known-red.json`、`defect-registry-declared.tsv` 这些**整波重建/重取臂的产物**上，是正在跑波 `#49` 收尾链的另两条车道（`W76A`/`W77A`）写的；本车道**一次构建、一次应用、一次 `verify-all` 都没跑**。

---

## 0. 先给三句话（怕你只读一段）

1. 这族缺口**一共 109 条**（工具口径，现件 `nm` 现算）；扣掉 **9 条 `#if NEVER` 死声明**与 **1 条探测序误报** ⇒ **真会炸的 99 条**：`Fs*` 66、`Lo*` 22、`Nl*` 6、`*Wrapper` 5、其它 10。
2. **最小闭包（让"`FlowDocument` + `Paragraph` + `Run`"活下来）= 27 条入口**（16 条 `Fs*` + 6 条 PTS 对象/上下文入口 + 5 条 LS 构造期）——但它们**不是 27 个小函数**，而是**一个真在工作的分页引擎的对外契约**。
3. **推荐的最小第一步不是"实现 PTS"，而是"把'缺 PTS'从『整进程 `FailFast`』变成『具名、可判、可见的能力边界』"**，并**同时**修掉那条让失败必然升级成 `FailFast` 的**毒池项**；`TASK-0303` 的"长线本体"（真实现）**必须排在它之后**，否则长线的每一次中间状态都**没有读数**（详见 §3）。

---

## 1. 入口清单（`PresentationNative_cor3.dll` 的 PTS / LineServices 族）

### 1.1 这族"在哪"——`PresentationNative_cor3.dll` 在本移植里**就是我们 shim 的别名**

证据链（三处，都是现件）：

| # | 事实 | 证据（`文件:行`） |
|---|---|---|
| 1 | `PresentationNative_cor3.dll` 被解析器**映射到同一份 `libwpfwin32.so`** | `build/shims/Win32ShimResolver.cs:92`；实测解析出的 `MappedLibraries`（11 个，含 `presentationnative_cor3.dll`，小写） |
| 2 | **app-local 别名复制**把 `libwpfwin32.so` 复制成 `PresentationNative_cor3.dll` 等四个别名 | `build/MilBridge/tools/sync-applocal.sh:166`（`for a in uxtheme.dll wtsapi32.dll shell32.dll PresentationNative_cor3.dll`） |
| 3 | ⇒ **凡是"缺导出"，缺的就是我们 `.so` 里的导出**，不是系统里的某个库 | 同上；且 `nm -D --defined-only …libwpfwin32.so` 里 **`CreateInstalledObjectsInfo` 不存在**（见 §1.2 命令） |

> ⚠️ 顺带排除一个常见误解：全盘那些叫 `PresentationNative_cor3.dll` 的文件（`~/w37-gate-b/`、`~/w51b-app/` …）**都是我们自己的 ELF shim 的副本**，不是 Windows 二进制：
> `file ~/w37-gate-b/PresentationNative_cor3.dll` → `ELF 64-bit LSB shared object, x86-64`。

### 1.2 命令与总读数（**正对照**：另一族已知存在）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
SO=$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so

# 现件身份
sha256sum $SO | cut -c1-16            # c493639d15678803   （322056 B；mtime 2026-09-21 12:31:05）
nm -D --defined-only $SO | wc -l      # 535（动态定义导出总数）
nm -D --defined-only $SO | awk '{print $3}' | grep -x 'CreateInstalledObjectsInfo' || echo "NOT FOUND"
                                      # → NOT FOUND（**这就是 D-G70 的第一跳**）
```

覆盖率口径用**仓内既有工具** `src/WpfGfx.Linux.Native/tools/check-shim-coverage.py`
（它按 .NET 在 Unix 上的**真实探测顺序**算每条 `[DllImport]` 会去找哪些名字）。**但有一处必须纠正**（否则读数会被旧件污染）：

> 🔴 **仓内的 `src/WpfGfx.Linux.Native/bin/exports.txt` 是陈旧件（2026-09-14）**：
> 现件 `nm` **535** 行 vs `exports.txt` **472** 行，`diff` 显示现件多出整族 `Gdip*` / `Dwm*` / `AlphaBlend` / `CallNextHookEx` …
> ⇒ **我不用它**，改用现算清单（`nm -D --defined-only $SO | awk '{print $3}' | sort > ~/w78a/exports.live.txt`，535 行，sha16 `f44cabae3690e81d`）。
> （`docs/unimplemented.md` §2.7 早就写过这条警告；本轮**独立复现**。）

**实测总读数**（现算清单，`--tier mapped`）：

```
扫描到 419 条 DllImport 指向本 shim 映射的 DLL
  已有导出可用 : 291
  会 EntryPointNotFoundException : 128
```

**只看 `PresentationNative_cor3.dll`**（`145` 条去重后的 `[DllImport]`）：

| 项 | 读数 |
|---|---|
| 指向 `PresentationNative_cor3.dll` 的 `[DllImport]`（去重后） | **145** |
| **已有导出可用** | **36** |
| **会 `EntryPointNotFoundException`** | **109** |

**正对照（另一族已知存在，证明"读数不是全红瞎报"）**：可用 36 条里，**`IsWindows*` OSVersionHelper 全族 20 条一条不缺**
（`IsWindowsXPOrGreater` / `IsWindows7OrGreater` / `IsWindows10RS5OrGreater` / … 20 条，
与 shim 自述的"版本判定家族 20 个导出"吻合：`src/WpfGfx.Linux.Native/src/win32_misc.c:1222`），
另有 `*Wrapper` 直通 13 条、`LoGetEscString`、`MILGetClassificationTables`、`LsDisableSpecialCharacterLigature`。
⇒ **工具能分开"有/没有"**，不是一把抓。

### 1.3 逐族表（109 条，按**声明它的上游文件与 native 头文件**分组）

计数命令（可复现）：

```bash
grep 'PresentationNative_cor3.dll ' ~/w78a/out/cov-live.txt \
  | awk '{n=$2; sub(/\/.*/,"",n); print n}' | sort | uniq -c | sort -rn
```

| 族（前缀 / 来源） | 条数 | 活 / `#if NEVER` 死 | 功能 | 挡什么 |
|---|---|---|---|---|
| `Fs*` `fscrpage.h`（页） | 8 | **7 / 1** | 有限页 / 无底页 的建·改·清·销毁 | **分页** |
| `Fs*` `fscrsubp.h`（子页 = 浮动/图形容器） | 12 | 12 / 0 | 子页 建·改·比·销毁·栏平衡·脚注数·显示信息转移 | 浮动对象 / `Figure` / `Floater` |
| `Fs*` `fscrsubtrack.h`（子道 = 嵌套容器） | 12 | 12 / 0 | 子道 建·改·比·销毁·栏平衡·脚注数·同步 | 表格单元 / 嵌套块 |
| `Fs*` `fsquery.h`（查询） | 21 | **17 / 4** | 页/节/道/子道/文本/行列表/行元素/附着对象/*ColumnSpan* 查询 | **整条"读排版结果"的接口** |
| `Fs*` `fstableobjquery.h`（表格对象） | 5 | 5 / 0 | 表对象 / 行 / 单元 的查询 | **表格** |
| `Fs*` `fsgeom.h` | 4 | **1 / 3** | 空位 / 空位数 / 下一刻度 / 浮动障碍登记 | 几何（活的那条是 `FsGetEmptySpaces`） |
| `Fs*` `fstransform.h` | 2 | 2 / 0 | 矩形 / bbox 坐标变换 | 把排版坐标映射到渲染 |
| `Fs*` `fsfloaterquery.h` | 1 | 1 / 0 | 浮动对象详情 | `Floater` |
| `Fs*` `fscrcontxt.h`（上下文） | 3 | **2 / 1** | 建 / 销毁 文档上下文 | **第二跳**（`CreateDocContext`） |
| **对象处理器 4 条**（无头注释） | 4 | 4 / 0 | `CreateInstalledObjectsInfo` / `DestroyInstalledObjectsInfo` / `GetFloaterHandlerInfo` / `GetTableObjHandlerInfo` | **第一跳** + 浮动/表格处理器 |
| `Lo*` + 分析族（`LineServices.cs`） | **26** | 26 / 0 | 22 条 `Lo*`（行对象/断行/罚分）+ `CreateTextAnalysisSource/Sink` / `GetScriptAnalysisList` / `GetNumberSubstitutionList` | LineServices 行引擎 |
| `Nl*`（断字） | 6 | 6 / 0 | `NlLoad`/`NlUnload`/`NlGetClassObject`（`NLGSpellerInterop.cs`）+ `NlCreateHyphenator`/`NlHyphenate`/`NlDestroyHyphenator`（`NaturalLanguageHyphenator.cs`） | 断字 |
| `*Wrapper`（Win32 直通，`NativeMethodsSetLastError.cs`） | 5 | 5 / 0（**其中 1 条是误报**） | `FindWindowExWrapper` / `GetMenuBarInfoWrapper` / `GetTextExtentPoint32Wrapper` / `GlobalDeleteAtomWrapper` / `SetScrollPosWrapper` | 各自对应的 Win32 面 |
| **合计** | **109** | **100 / 9** | | |

**`Fs*` 逐条明细（66 条，按头文件；`✗dead` = `#if NEVER`）**：

```
[fscrcontxt.h  2+1] CreateDocContext  DestroyDocContext                       | ✗dead FsSetDebugFlags(@Pts.cs:3101)
[fscrpage.h    7+1] FsCreatePageFinite FsCreatePageBottomless FsUpdateFinitePage FsUpdateBottomlessPage
                    FsClearUpdateInfoInPage FsDestroyPage FsDestroyPageBreakRecord
                                                                              | ✗dead FsDuplicatePageBreakRecord(@:3153)
[fscrsubp.h     12] FsCreateSubpageFinite FsCreateSubpageBottomless FsUpdateBottomlessSubpage
                    FsClearUpdateInfoInSubpage FsCompareSubpages FsDestroySubpage FsDestroySubpageBreakRecord
                    FsDuplicateSubpageBreakRecord FsGetNumberSubpageFootnotes FsGetSubpageFootnoteInfo
                    FsGetSubpageColumnBalancingInfo FsTransferDisplayInfoSubpage
[fscrsubtrack.h 12] FsFormatSubtrackFinite FsFormatSubtrackBottomless FsUpdateBottomlessSubtrack
                    FsSynchronizeBottomlessSubtrack FsClearUpdateInfoInSubtrack FsCompareSubtrack
                    FsDestroySubtrack FsDestroySubtrackBreakRecord FsDuplicateSubtrackBreakRecord
                    FsGetNumberSubtrackFootnotes FsGetSubtrackColumnBalancingInfo FsTransferDisplayInfoSubtrack
[fsquery.h     17+4] FsQueryPageDetails FsQueryPageSectionList FsQuerySectionDetails FsQuerySectionBasicColumnList
                    FsQueryTrackDetails FsQueryTrackParaList FsQuerySubtrackDetails FsQuerySubtrackParaList
                    FsQuerySubpageDetails FsQuerySubpageBasicColumnList FsQueryTextDetails
                    FsQueryLineListSingle FsQueryLineListComposite FsQueryLineCompositeElementList
                    FsQueryAttachedObjectList FsQueryFloaterDetails FsQueryFigureObjectDetails
                    FsQueryDcpLineVariantsFromCachedTextPara
                    | ✗dead FsQuerySegmentDefinedColumnSpanAreaList(@:3641) FsQueryHeightDefinedColumnSpanAreaList(@:3649)
                            FsQuerySubpageSegmentDefinedColumnSpanAreaList(@:3718) FsQuerySubpageHeightDefinedColumnSpanAreaList(@:3726)
[fsgeom.h       1+3] FsGetEmptySpaces | ✗dead FsRegisterFloatObstacle(@:3510) FsGetMaxNumberEmptySpaces(@:3518) FsGetNextTick(@:3545)
[fstableobjquery.h 5] FsQueryTableObjDetails FsQueryTableObjTableProperDetails FsQueryTableObjRowList
                      FsQueryTableObjRowDetails FsQueryTableObjCellList
[fstransform.h  2] FsTransformRectangle FsTransformBbox
[fsfloaterquery.h 1] FsQueryFloaterDetails
```

> **9 条 `#if NEVER`**（工具不求值预处理 ⇒ 被算进 109）：`FsSetDebugFlags`、`FsDuplicatePageBreakRecord`、`FsRegisterFloatObstacle`、`FsGetMaxNumberEmptySpaces`、`FsGetNextTick`、`FsQuerySegmentDefinedColumnSpanAreaList`、`FsQueryHeightDefinedColumnSpanAreaList`、`FsQuerySubpageSegmentDefinedColumnSpanAreaList`、`FsQuerySubpageHeightDefinedColumnSpanAreaList`。
> **独立交叉验证**：这 9 条**全部落在**"`PTS.<名>(` 在全仓**零调用**"的 **11 条**里（见 §1.5）⇒ 两条独立方法给出**一致的子集关系**（`dead ⊆ zero-call`，且 `dead − zero-call = ∅`）。**但 11 ≠ 9**，多出的 2 条不是死声明（`NOINFO`，见 §1.5/§5）。

### 1.4 三条必须知道的口径更正（我实测出来的）

| # | 说法 | 实测 | 处置 |
|---|---|---|---|
| 1 | 用 `bin/exports.txt` 算缺口（工具默认） | **陈旧**：472 行 vs 现件 `nm` 535 行 | **改用现算清单**；工具默认路径会**低估**现有导出 ⇒ 缺口**虚高** |
| 2 | `FindWindowExWrapper` 缺 | **`.so` 里有它**（现算清单第 94 行）；工具判缺是因为它拿 `FindWindowExWrapperW` 当第一候选（`CharSet.Unicode` + 显式 `EntryPoint` ⇒ Unix 上**不补 `W`**） | **扣 1 条**（与 `docs/unimplemented.md` §2.7 既有裁定一致） |
| 3 | §2.7 记的"**97** 缺失" | 我算 **99**（= 109 − 9 死 − 1 误报） | **差 2，未解 ⇒ 记 `NOINFO`**（§5 第 6 条）；本报告**以我自己的现算读数为准**，不引用 97 |

### 1.5 谁调用它——两个方向必须分开（**这条决定"最小闭包"怎么算**）

命令：

```bash
cd $R/upstream/wpf/src/Microsoft.DotNet.Wpf/src
grep -rhoE '\bPTS\.[A-Za-z0-9_]+\s*\(' PresentationFramework/ PresentationCore/ WindowsBase/ \
  | sed 's/[[:space:]]*($//;s/($//' | sort | uniq -c | sort -rn
```

**方向一：托管 → native（真正的 `[DllImport]`）**：`Pts.cs` 的 `#region Exported functions`（`:3057-3910`）里 **72 条** `extern`（census 权威值）；
其中被托管代码**实际调用**的 **61 条**（`Fs*` 为主，另 6 条对象/上下文入口），**零调用 11 条**（§1.5 末）。
**第一跳的调用点逐字**：

| native 入口 | 调用点 | 备注 |
|---|---|---|
| **`CreateInstalledObjectsInfo`** | `PtsCache.cs:640`（`InitInstalledObjectsInfo` 内，`PTS.Validate(...)`；由 `CreatePTSContext` 在 **`PtsCache.cs:433`** 调起） | **D-G70 崩在这里** |
| `GetFloaterHandlerInfo` | `PtsCache.cs:259`（由 `:440` `InitFloaterObjInfo` 调起） | 上下文创建期**无条件**调用 |
| `GetTableObjHandlerInfo` | `PtsCache.cs:278`（由 `:441` `InitTableObjInfo` 调起） | 同上 |
| **`CreateDocContext`** | **`PtsCache.cs:462`** | **第二跳** |
| `DestroyDocContext` / `DestroyInstalledObjectsInfo` | `PtsCache.cs:330/332`（`DestroyPTSContexts`）、`:402/404`（释放路径） | 拆卸 |
| `FsCreatePageFinite` | `PtsPage.cs:397` | 分页入口 |
| `FsUpdateFinitePage` | `PtsPage.cs:457` | |
| `FsQueryPageDetails` | `FlowDocumentPage.cs:430`、`PtsPage.cs:503/553` | |
| `FsQuerySectionDetails` | `FlowDocumentPage.cs:464`、`PtsPage.cs:902/950/1113/1316/1374` | |
| `FsQueryTrackDetails` | `FlowDocumentPage.cs:440/494/534/569`、`PtsHelper.cs:127/218/320/379/456/732`、`FloaterParaClient.cs:575/616/671/696`、`FigureParaClient.cs:567/607/662/687` | 调用点最多（22） |
| `FsQuerySubtrackDetails` | `ContainerParaClient.cs:47/89/142/177/218/240/271/325/375`、`ListParaClient.cs:46` | |
| `FsQueryTextDetails` | `TextParaClient.cs:56/149/194/253/345/…`（20 处） | 文本段的行结果 |
| `FsQueryLineListSingle` / `…Composite` / `FsQueryLineCompositeElementList` | `PtsHelper.cs:652` / `:671` / `:689` | 行列表 |
| `FsQueryAttachedObjectList` | `PtsHelper.cs:708` | 附着对象（表格/浮动） |
| `FsTransformRectangle` | `PtsHelper.cs:169`、`ContainerParagraph.cs:497/498/646/770`、`SubpageParagraph.cs` 等（18 处） | 坐标映射 |
| `FsDestroyPage` / `FsDestroyPageBreakRecord` | `PtsContext.cs:103/490` / `:85/524` | 拆卸 |

- **零调用的 native 声明 = 11 条**（现算：`Pts.cs` 声明的 72 条里，`PTS\.<名>(` 在全仓 `PresentationFramework` 里 **0 命中**的 11 条）：
  `FsDuplicatePageBreakRecord`、`FsGetEmptySpaces`、`FsGetMaxNumberEmptySpaces`、`FsGetNextTick`、
  `FsQueryDcpLineVariantsFromCachedTextPara`、`FsQueryHeightDefinedColumnSpanAreaList`、`FsQuerySegmentDefinedColumnSpanAreaList`、
  `FsQuerySubpageHeightDefinedColumnSpanAreaList`、`FsQuerySubpageSegmentDefinedColumnSpanAreaList`、`FsRegisterFloatObstacle`、`FsSetDebugFlags`。
  **其中 9 条正好是 §1.3 的 `#if NEVER` 集合**（两条独立方法给出**一致的子集关系**：9 ⊂ 11，且 `dead − zero-call = ∅`）。
  ⚠️ **但 11 ≠ 9**：多出的 2 条（`FsGetEmptySpaces`、`FsQueryDcpLineVariantsFromCachedTextPara`）**不是** `#if NEVER`，却也零调用
  ⇒ "另一种调用形态"还是"又一条死声明"，**未深究 ⇒ `NOINFO`**（§5 第 5 条）。**不许把两个集合当成一个。**

**方向二：native → 托管（回调，**反向**）**：`PtsCache.cs` 里共 **151 处回调赋值**（`… = new PTS.<Delegate>(ptsHost.<方法>)`），**去重后 135 个不同回调名**，装进 `FSMETHODS`/`FSCONTEXTINFO` 及各对象手柄结构交给 native。
实测分布（`grep -c '= new PTS\.' PtsCache.cs` = 151）：`contextInfo.fscbk.cbkgen` **32**｜`cbktxt` **31**｜`cbkobj` **5**｜`cbkfig` **3**｜`contextInfo.pfnAssertFailed` **1**｜`subtrackParaInfo` **16**｜`subpageParaInfo` **16**｜`floaterInit.fsfloatercbk` **16**｜`tableobjInit.tablecbkfetch` **15**｜`tableobjInit.tablecbkcell` **12**｜`tableobjInit.tableobjcbk` **4**（合计 151）。
典型：`pfnFormatLine = ptsHost.FormatLine`（`PtsCache.cs:568`）、`pfnGetFirstPara`、`pfnGetParaProperties`、`pfnCreateParaclient`、`pfnObjFormatParaFinite` …
⇒ **这些名字（`FormatLine` / `GetNextPara` / `Obj*` / `Upd*` …）是"我们要实现的"，不是"我们要导出的"**。
（把它们算进"缺口"是一个**很容易犯的方向性错误**：`grep 'PTS\.'` 一次能捞出 216 个名字，其中**只有 61 个是 native 入口**。）

---

## 2. 最小闭包：让「最小页面（`FlowDocument` + 一个 `Paragraph` + `Run`）」活下来

### 2.1 唯一的入口链（静态可证）

```
FlowDocument 布局
  └─ StructuralCache.EnsurePtsContext()                    StructuralCache.cs:477-484   ← **唯一**建 PTS 上下文的地方
       └─ new PtsContext(true, textFormattingMode)          StructuralCache.cs:480       ← ★ 恒传 true（见 §2.4）
            └─ PtsCache.AcquireContext(this, mode)          PtsContext.cs:53
                 └─ AcquireContextCore(...)                 PtsCache.cs:177-212
                      ├─ _contextPool.Add(new ContextDesc())        :195   ← ★ 失败会留下"毒池项"
                      ├─ _contextPool[index].PtsHost = new PtsHost() :197
                      └─ PtsHost.Context = CreatePTSContext(...)    :198
                           ├─ InitInstalledObjectsInfo → **CreateInstalledObjectsInfo**  :433 → :640   ← 第一跳（今天崩在这）
                           ├─ InitGenericInfo（纯托管，装回调表）                          :437
                           ├─ InitFloaterObjInfo  → GetFloaterHandlerInfo                 :440 → :259
                           ├─ InitTableObjInfo    → GetTableObjHandlerInfo                 :441 → :278
                           ├─ [optimal 分支] TextFormatterContext()   → **LoCreateContext**        :446 → TextFormatterContext.cs:113
                           │                 GetTextPenaltyModule() → **LoAcquirePenaltyModule**  :447 → TextPenaltyModule.cs:26
                           │                 DangerousGetHandle()   → **LoGetPenaltyModuleInternalHandle** :448 → TextPenaltyModule.cs:80
                           │                 ContextInfo.ptsPenaltyModule = …（句柄交给 native PTS）:451
                           └─ **CreateDocContext**                                        :462   ← 第二跳
  └─ 之后才是 FsCreatePageFinite / FsQuery* 一族（PtsPage / FlowDocumentPage / PtsHelper / TextParaClient）
```

### 2.2 必需集（真实现，**27 条入口**：16 条 `Fs*` + 6 条 PTS 对象/上下文入口 + 5 条 LS 构造期）

**A. 上下文创建期（**无条件**，6 条）**
`CreateInstalledObjectsInfo`｜`GetFloaterHandlerInfo`｜`GetTableObjHandlerInfo`｜`CreateDocContext`｜＋拆卸 `DestroyInstalledObjectsInfo` / `DestroyDocContext`
**依据**：`PtsCache.cs:433/440/441/462`（前四条在**同一函数内顺序执行**，与文档内容无关）。

**B. 构造期 LS 罚分模块（**无条件**，3 条 + 2 条拆卸）**
`LoCreateContext`｜`LoAcquirePenaltyModule`｜`LoGetPenaltyModuleInternalHandle`｜（拆卸 `LoDisposePenaltyModule` / `LoDestroyContext`）
**依据**：`StructuralCache.cs:480` 恒传 `isOptimalParagraphEnabled = true` ⇒ `PtsCache.cs:446-452` 必然进入 optimal 分支。
**⚠️ 这 3 条与 `FlowDocument` 的 `IsOptimalParagraphEnabled` DP **无关**（该 DP 默认 `false`，`FlowDocument.cs:514-523`）；恒 `true` 的是 `PtsContext` 的构造参数。**（这条很容易看错，见 §2.4）

**C. 页 / 节 / 道 / 子道 结构（7 条）**
`FsCreatePageFinite`｜`FsUpdateFinitePage`｜`FsQueryPageDetails`｜`FsQuerySectionDetails`｜`FsQueryTrackDetails`｜`FsQuerySubtrackDetails`｜`FsQuerySectionBasicColumnList`
**依据**：`PtsPage.cs:397/457/503`、`FlowDocumentPage.cs:430/440/464`、`PtsHelper.cs:595/614/633`、`ContainerParaClient.cs:47`。

**D. 文本段 → 行（7 条：6 条具名 + `FsTransformBbox`）**
`FsQueryTextDetails`｜`FsQueryLineListSingle`｜`FsQueryLineListComposite`｜`FsQueryLineCompositeElementList`｜`FsQueryAttachedObjectList`｜`FsTransformRectangle`（+`FsTransformBbox`）
**依据**：`TextParaClient.cs:56/…`、`PtsHelper.cs:652/671/689/708/169`。

**E. 拆卸（2 条）**：`FsDestroyPage`｜`FsDestroyPageBreakRecord`（`PtsContext.cs:103/490`、`:85/524`）

⇒ **A+B+C+D+E ≈ 27 个入口**（去重后 §2.2 表内合计：6 + 5 + 7 + 7 + 2 = 27）。

> ⚠️ **"27 条"不是"27 个小函数"**：这些是**一个分页引擎的对外契约**。
> `FsQueryPageDetails`/`FsQueryTrackDetails`/`FsQueryTextDetails`/`FsQueryLineList*` 交出去的
> 是**排版结果的完整几何**（页/节/道/子道 desc、行 desc、行元素、附着对象），
> 而 native 还必须**反向驱动 **151 处回调（135 个不同名）****来取内容（§1.5 方向二）。
> ⇒ 真实现 = **写一个分页引擎 + 一套回调 ABI**，不是"补 27 个 stub"。

### 2.3 可以"如实失败"的（逐族 + 理由）

| 族 | 条数 | 对"最小页面"为何可缓 | 对 hc **第 23 页** |
|---|---|---|---|
| `fstableobjquery.h` 表对象 5 条 | 5 | 最小页面无表格 | ❌ **不可缓**（该页有 `Table`） |
| `fscrsubp.h` 子页族（浮动/图形）12 条 | 12 | 最小页面无 `Figure`/`Floater` | ❌ **不可缓**（该页有 `Figure`+`Floater`） |
| `FsQueryFloaterDetails` / `FsQueryFigureObjectDetails` | 2 | 同上 | ❌ |
| 脚注族 `FsGetNumber*Footnotes` / `FsGet*FootnoteInfo`（5 条，散在 subp/subtrack） | 5 | 两页都无脚注 | ✅ 可缓 |
| `fscrsubtrack.h` 的 `FsFormatSubtrack*` / `FsCompare*` / `FsSynchronize*` / `FsTransferDisplayInfo*`（8 条） | 8 | 最小页面**无嵌套容器**（子道用于表格单元/嵌套块） | ❌ 部分需要（表格） |
| `Nl*` 断字 6 条 | 6 | `IsHyphenationEnabled` 默认 `false` | ❌ 该页显式 `True` |
| **`Lo*` 行引擎 20 条**（`LoCreateLine`/`LoDisplayLine`/`LoEnumLine`/`LoQueryLine*`/`LoCreateBreaks`/`LocbkGetObjectHandlerInfo`/`LoCreateParaBreakingSession`/`LoSet*`/`LoRelievePenaltyResource`/`LoCloneBreakRecord`/`LoAcquireBreakRecord`/`LoDispose*` …） | 20 | **行由托管层排**（§2.5），本移植已接**两层**托管兜底 | ❌ 同左（本移植同样不需要） |
| `CreateTextAnalysisSource/Sink` / `GetScriptAnalysisList` / `GetNumberSubstitutionList` | 4 | 属 LS 的文本分析面，托管路由不过去 | 同左 |
| `*Wrapper` 4 条（扣掉误报） | 4 | 与排版无关（`GetTextExtentPoint32Wrapper` 属 T2 文本度量） | 同左 |
| `#if NEVER` 9 条 | 9 | **永远不需要**（死声明） | 同左 |

### 2.4 反直觉结论 ①：LS 被需要**不是因为要"排行"，而是因为"构造期要一枚罚分模块的句柄"**

- `StructuralCache.cs:480` 硬编码 `new PtsContext(true, …)` ⇒ PTS 上下文**永远是 optimal 版**；
- ⇒ `PtsCache.cs:446-452` 必然 `new TextFormatterContext()`（→`LoCreateContext`）＋ `GetTextPenaltyModule()`（→`LoAcquirePenaltyModule`）；
- ⇒ 并把那个**LS 罚分模块的裸句柄**塞进 `ContextInfo.ptsPenaltyModule`（`PtsCache.cs:451`）**交给 native PTS 用**。
- ⇒ **结论**：即使你把 `Fs*` 分页器整族重写，**只要 still 走 `PtsCache`**，就必须有一个**LS 上下文对象**且其罚分模块句柄对 native 有意义。
  **PTS 与 LS 在构造期是耦合的，不是两条独立缺口线。**
- **唯一的"摘钩"办法**：改 `pf`（`StructuralCache.cs:480` 的 `true` → `false`）**并且**补上 `_ptsContext.TextFormatter == null` 时的接线（`PtsCache.cs:204-207` 那段会跳过 ⇒ `StructuralCache.cs:481` 会拿 null 建 `TextFormatterHost`）。
  ⇒ **不是一行开关**，且会改断行质量（optimal paragraph 关闭）⇒ 属"行为改动"，必须走成对判据。

### 2.5 反直觉结论 ②：**行是托管排的** ⇒ "真实现 PTS" ≠ "移植 LineServices"

- PTS native 取行的方式是**回调**：`pfnFormatLine = ptsHost.FormatLine`（`PtsCache.cs:568`）；托管侧 `TextParagraph.FormatLine` → `TextFormatter`（`TextFormatterHost`）。
- 本移植在这条路上已经接了**两层托管兜底**（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`）：
  ① `SimpleTextLine.Create`（`:679`）→ ② `WpfLinux.Shims.PresentationCore.HbTextFallback.TryFormatLine`（`:690`）→ ③ `WpfLinuxLenientTextFallback.TryFormatLine`（`:723`）→ ④ 只有**三层都失败**才落到 `TextMetrics.FullTextLine`（`:756`，那才需要 LS）。
  源码注释逐字："**Linux 上没有 LineServices ⇒ 原样回落 = `LoCreateContext` 抛 ⇒ abort(134)**"（`:717-719`）。
- ⇒ **20 条 `Lo*` 行引擎不在最小闭包里**（这正是 `run-wpftextdemo.sh` / hc 其余 29 页今天能出字的原因）。
- ⇒ 因此"**PTS 最小实现**"的正确形状是：**native 做页/道/段结构与几何，行内容通过回调交给已经绿的托管文本栈**。
  这既让闭包**小得多**，也把最大的技术风险（从零写行布局引擎）**移出射程**。

### 2.6 hc 那两页的**真实**差距（这条决定了"先救哪一页"）

读数命令与结果：

```bash
cd /home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Styles
grep -oE '<[A-Za-z:]+' FlowDocumentDemo.xaml | sort | uniq -c | sort -rn
#   13 <Paragraph   8 <TableCell   5 <TableRow   3 <TabItem   2 <Table   2 <TableColumn
#    1 <TableRowGroup  1 <Section  1 <Hyperlink  1 <FlowDocumentReader  1 <FlowDocumentPageViewer
#    1 <FlowDocumentScrollViewer  1 <FlowDocument  1 <Floater  1 <Figure  1 <Bold
wc -l RichTextBoxDemo.xaml      # 23 行
```

| 页 | 内容 | 距最小闭包 |
|---|---|---|
| **第 24 项 `RichTextBoxDemo`**（23 行） | `RichTextBox` → `FlowDocument` → 3×`Paragraph`（各一个 `Run`；其中一条 `ConverterParameter=1000` 的重复文本）＋ 一个 `Hyperlink` | **≈ 就是"最小页面"** ⇒ **闭包 C+D 那 14 条**（7+7；多行 + 断行 ⇒ 需要真正的行/页结构） |
| **第 23 项 `FlowDocumentDemo`**（114 行） | 3 个 `TabItem`（`FlowDocumentScrollViewer`/`PageViewer`/`Reader`），`ColumnWidth="400"`（**多列**）、`IsOptimalParagraphEnabled="True"`、`IsHyphenationEnabled="True"`；正文含 **`Figure` + `Floater` + `Table`(2 列 / 8 单元) + `Hyperlink` + `Bold`** | **几乎要整族**：表对象 5 + 子页 12 + 浮动/图形 2 + 断字 6 + 多列查询 2 ⇒ **不在最小闭包射程内** |

> ⇒ **口径建议**：把 `D-G70` 的"直接救 23/24 两页"**拆成两条**：`24 页（近最小闭包）` 与 `23 页（需要表/浮动/图形/多列/断字 ⇒ 长线本体）`。
> 今天把两页当一个目标，会让"完成度"永远说不清。

---

## 3. 最小第一步方案（**一个**：方案 `A′`）

### 3.0 为什么不把"真实现最小 `PtsContext`"（方案 B）当第一步

| 判据 | 读数 / 依据 |
|---|---|
| 闭包规模 | §2.2 的 **27 条入口**，但它们是**一套分页引擎 + 151 处回调（135 个不同名）的 ABI**（§2.5），不是 27 个 stub |
| **有没有参考实现** | **没有**。`find upstream -type d \( -iname ls -o -iname pts -o -iname nl \)` → **空**；`upstream/…/src/redist/` **不存在**；代表符号在上游**非 `.cs` 命中 = 0**（`LoCreateLine`/`LoDisplayLine`/`LoCreateContext`/`FsCreatePageFinite`/`NlGetClassObject`/`CreateInstalledObjectsInfo` 各 0）——**我独立复现**（与 `docs/unimplemented.md` §2.7 的结论一致） |
| **有没有可运行的真机对照物** | **没有**。全盘名为 `PresentationNative_cor3.dll` 的文件**全是我们自己的 ELF shim 副本**（`file` 实测）；NuGet 缓存只有 `microsoft.windowsdesktop.app.ref`（**托管引用程序集**，无原生件）；**无 wine**（`command -v wine` 空）⇒ 即便能从网上取到 `Microsoft.WindowsDesktop.App.Runtime.win-x64` 里的真 PE，**也只能静态看，不能当行为 oracle** |
| ⇒ 结论 | **B 不能作为"第一步"**：它每一步中间状态都（a）撞下面 §3.5 的 `FailFast`，（b）没有任何真值可比 ⇒ **不可判** |

> 同理 **方案 C（托管 FlowDocument 分页器，绕开 PTS）**也不作第一步：代价与 B 同量级，
> 且**天然半通**（表/浮动/图形/分栏/脚注都做不了，很容易"静默丢内容"）——本仓最忌讳的那种失败。

### 3.1 方案 `A′`：**把"缺 PTS"从「整进程必死」变成「具名、可判、可见的能力边界」**（四件）

> 一句话：**不假装 PTS 能用**；把"不能用"做成一条**有名字、有读数、能变红**的事实，并**拆掉那条让任何失败都升级成 `Environment.FailFast` 的地雷**。这是 B 的**前置**，不是 B 的替代。

#### A0 · 先把"需求序列"录下来（**零世代位、零产品改动、装置已存在**）

- 装置：`build/MilBridge/tools/t1b-ls-tripwire.sh`（sha16 `82f6a05afb1f9db9`，自证件 `t1b-ls-selftest.c` sha16 `936fda22bfe2f092`）。
  它的**真值来源 = `ld.so` 自己的 `LD_DEBUG=symbols` 日志**（注释逐字："**日志由 ld.so 自己写**，不经过任何我们的代码 ⇒ **不可撒谎**"），
  且汇总行**已经**在统计 `^(Lo|Ls|Nl|Fs)[A-Za-z]` 家族的查找 ⇒ **`Fs*` 现成覆盖**。
- 做法：`bash build/MilBridge/tools/t1b-ls-tripwire.sh <outdir> -- <跑 hc 应用并切到第 24 项>`
  ⇒ 读 `<outdir>/ls-tripwire.txt` 里 `Fs*` 被查找的**名字与顺序** ⇒ **把 §2.2 的"必需集"从静态推断变成实测**。
- 代价：**零产品改动、零世代位**；一次应用运行。风险：无（装置自带 `--selftest` 与 `ST_ATTEST`（自测期间本件被改写 ⇒ `rc=2`/`NOINFO`）防止"装置自己撒谎"）。

#### A1 · native 侧：把 PTS 上下文族的 6 个入口**导出**，但**如实失败**

- 新件：`src/WpfGfx.Linux.Native/src/win32_pts.c`（`build-shim.sh` 的 `SRCS` 加一行），导出
  `CreateInstalledObjectsInfo` / `DestroyInstalledObjectsInfo` / `CreateDocContext` / `DestroyDocContext` /
  `GetFloaterHandlerInfo` / `GetTableObjHandlerInfo`。
- 行为：**返回非零 `LsErr`**（"未实现"，不是 0！）＋ 每次调用写一条**具名台账**（env 门控，照既有 `WPF_LINUX_*_DIAG` 先例）：
  `PTS_GAP entry=CreateInstalledObjectsInfo seq=1 err=…`；再加一个**机器可读自检导出** `WpfLinuxWin32_PtsGapReport(...)`
  （照 `WpfLinuxWin32_EscStringSelfCheck` / `ClassificationSelfCheck` 的现成形状）。
- **它买到的东西**：失败从"**绑定期** `EntryPointNotFoundException`"（P/Invoke 边界，**台账挂不上**）变成
  "**定义好的错误码 + 名字 + 调用序号**"——即**缺口变成数据**，且为 B 的增量实现留出**同一个契约**（先 stub 后真实现，托管侧一行不用改）。
- **它**不**买到的东西（必须说清）**：**它一点也不让页面能渲染**，且**不**改变崩不崩（崩在 A2）。

#### A2 · `pf` 侧：拆掉"毒池项"，让失败可捕获、不 `FailFast`、不重试风暴（**这一件才是"救进程"**）

- **① 毒池项清理**：`PtsCache.AcquireContextCore` 在 `:198` `CreatePTSContext` 抛异常时，那条 `ContextDesc`
  （`:195/:196/:197` 已建、`InUse` 仍是 `false`、`PtsHost.Context == IntPtr.Zero`）**必须从 `_contextPool` 里移除**。
  今天它留在池里 ⇒ 下一趟布局在 `:182-189` 的循环里**把它当"空闲项"复用**（**跳过**创建）⇒ 拿一个 `Context == Zero` 的 host 继续用 ⇒ 见 §3.5。
- **② 具名能力闩 + 具名异常**：首次失败后，该 `Dispatcher` 的 `PtsCache` 记住"PTS 不可用"，
  后续 `AcquireContext` **立即抛一个具名托管异常**（如 `PtsUnavailableException`，带 `entry=…`），
  **不再调 native、不再反复布局**；每次仍然**打具名行**（不许静默）。
- **③ 幂等**：把"不可用"落在**文档/控件级**（`StructuralCache` 级）的 flag 上，保证**一次失败只发生一次布局异常**（否则每次布局抛一次 ⇒ 布局循环/CPU 打转，见 §3.4 风险 2）。
- **④ `Invariant.Assert` 一个都不删、不放宽**：A2 的目标是让它们**不再被走到**；若仍被走到 ⇒ 那是**新缺陷**，断言照旧响亮。⚠️ 这条必须写进实现纪律。

#### A3 · "不支持"必须**看得见**，而且**不许把空白读成绿**

- 需要一处**页级降级呈现**：`FlowDocumentView` / `FlowDocumentFormatter` / `DocumentPageHost` 一级
  （**产品侧**，PF）在"PTS 不可用"时给一个**具名占位**（非零墨的可识别矩形/文字），而不是留一块白。
- **止损版（若 A3 不在本步射程）**：只在 hc 侧（**仓外**，`App.xaml.cs` 的 `InstallUnhandledGuard()`，W60A 先例）拦截，
  **并明写"这不是产品修法"**；判据里"页面非静默空白"那一格随之**降级为 `NOINFO`**，不许当绿。

### 3.2 判据（三态 + 两条反极性）——**写死，交给落地车道**

| 格 | 条件 | 期望 | 反极性如何证伪 |
|---|---|---|---|
| **P1 正极性（进程）** | hc 点第 **24** 项 ⇒ 进程 | `alive=yes` ∧ `rc ≠ 134` | 撤 A1 ⇒ `rc=134` |
| **P2 正极性（具名）** | 日志 | 含具名行（`PTS-UNAVAILABLE` + `entry=CreateInstalledObjectsInfo`，或 A1 的 `PTS_GAP entry=…`） | 撤 A1 ⇒ 日志逐字含 `Unable to find an entry point named 'CreateInstalledObjectsInfo' in shared library 'PresentationNative_cor3.dll'` |
| **P3 正极性（不许静默空白）** | 页面矩形 | **要么**具名占位有墨（非零像素/可识别），**要么**判据**记红**；**空白 ⇒ 不许读成 PASS** | A3 未落地 ⇒ 本格 `NOINFO`（**明写，不许当绿**） |
| **P4 正极性（可继续用）** | 切回正常页（如导航项 0） | 能换页 ∧ 帧差 `AE > 0`（"别的页还能用"的**唯一**证明） | 撤 A3/A2 ⇒ 进程已死，本格不可达 |
| **N1 反极性①（能力真缺）** | 撤 A1 的 stub | 复现 `rc=134` + 上面那条逐字签名 | —— |
| **N2 反极性②（**假绿探测器**）** | **把 A1 的 stub 改成返回 `0`（成功）而其余不变** | **判据必须变红**（页面空白且无 `PTS-UNAVAILABLE` ⇒ 不许 PASS） | 若这一格**仍然绿** ⇒ 判据没有拦住"静默半通" ⇒ **方案不可接受** |

> **N2 是本方案的核心牙齿**：它把"不许把假 context 当能用"变成**一条能变红的判据**，而不是一句口号。

### 3.3 会动哪些世代位 & 代价量级

九位（`build/close-wave.sh:356-364` 判据：`bridge`/`pc`/`pf`/`windowsbase`/`provider`/`wic_shim`/`dwf`/`win32shim`/`hbtextline`）：

| 件 | 动？ | 为什么 |
|---|---|---|
| **`win32shim`** = `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（`close-wave.sh:275`） | **✅ 变** | A1 新增源文件 + 6 个导出 |
| **`pf`** = `build/PresentationFramework.Linux/bin/Debug/PresentationFramework.dll` | **✅ 变** | A2（`PtsCache` 毒池项 + 闩，PF csproj 的 `Remove`/`Include` 两行或 patch 脚本）＋ A3 |
| `pc` / `hbtextline` | **❌ 不动** | 未碰 `PresentationCore`；行引擎不参与 ⇒ **`tline` 等自报 `pc` 的臂预期不动**（这使本步比"动 pc"便宜一档） |
| `bridge` / `windowsbase` / `provider` / `wic_shim` / `dwf` | **❌ 不动**（重建时字节可复现，按既有经验） | 与文本栈无关 |

**代价量级**：A0 ≈ **一次应用运行**（零世代位）｜A1 ≈ **150–250 行 C + 一次 `build-shim.sh`**｜A2 ≈ **40–90 行托管（PF）+ csproj 两行**｜A3 ≈ **一条页级降级 + 一条判据脚本**。
流程代价 = 标准一波：重建（shim+PF）→ 重取五臂 → `repin-generation --why` → 门禁 ×2 → 冻前 `verify-all` → 冻结 → 冻后 ×2。
**总量 ≈ 半天机时量级**（对比 B 的**月级**）。

### 3.4 风险（逐条，按严重性）

1. **🔴 最大风险 = 把 `FailFast` 变成"静默半通"**（正是任务书点名的那条）。
   机理：A1 一旦被后人"顺手"改成返回 `0`（看起来更"能跑"），`CreateDocContext` 会返回一个**假句柄** ⇒ `PtsHost.Context != Zero` ⇒ 断言全过 ⇒ 页面**空白但进程活着** ⇒ **没有任何红**。
   **缓解（三条都要）**：① A1 的返回值**硬编码非零**并写注释"改成 0 就是制造静默半通"；② `WpfLinuxWin32_PtsGapReport()` 让"stub 模式"**可被机器读到**；③ **N2 反极性机器化**（§3.2）。
2. **🟠 重试风暴 / 布局循环**：A2 的闩若只挡 native 调用而**不挡布局重入**，每次 Measure 都抛一次 ⇒ CPU 打转或"永远量不完"。
   **缓解**：A2 ③ 的文档级幂等 flag；判据里加"点完这一页后 CPU/加载不持续"的观察（或至少如实记 `NOINFO`）。
3. **🟠 A2 会"降低发现能力"**：它把"失败必死"改成"失败可捕获"，于是**别的**真缺陷也可能从"必死"变成"半通"。
   **缓解**：闩**只**对"PTS 能力不可用"这**一个具名条件**生效（**不许写成兜底 catch-all**）；每一次都打具名行；
   落地车道必须逐条解释"本趟有哪些以前会死的路径现在不死了"。
4. **🟡 可比性**：本步**改的是失败形态，不是渲染**。必须同趟更新"会崩/不支持页清单"话术（`README` / `KNOWN-DEFECTS.md` 的 `D-G70` 段），否则读者会把 `alive=yes` 读成"能用了"。
5. **🟡 A3 的落点选择**：落在 PF（产品级、可移植）比落在 hc（仓外、只救一个应用）贵，但后者会**在别的应用上重现整进程死**。建议 PF；若本步只能做 hc 版，P3 格必须 `NOINFO`。

### 3.5 【更正任务书的单点说法】`FailFast` 不止一处，根因是「**毒池项**」

任务书写"`PtsHost.cs:52-55` 的 `Invariant.Assert(_ptsContext != null)` ⇒ `Invariant.cs:192-204`"。**逐字核实**：`PtsHost.cs:52/54` 与 `Invariant.cs:194`（`private static void FailFast`）**都对得上**。
但**静态追踪后必须补一句**：**能 FailFast 的断言至少 7 处**，且**真正的原因不是某个 getter，而是"创建失败留下毒池项"**：

| # | 断言（逐字） | 位置 | 何时被走到 |
|---|---|---|---|
| 1 | `Invariant.Assert(_ptsContext != null)` | `PtsHost.cs:54` | 半初始化状态下任何**回调**被调起（native→managed 方向） |
| 2 | `Invariant.Assert(_context != IntPtr.Zero)` | `PtsHost.cs:63` | 第二趟布局复用毒池项后，第一次问 `PtsHost.Context`（`FlowDocumentPage.cs:430`、`PtsPage.cs:503` 等**数十处**） |
| 3 | `Invariant.Assert(_contextPool[index].PtsHost.Context != IntPtr.Zero, "PTS Context handle is not valid.")` | `PtsCache.cs:329`（`DestroyPTSContexts`） | 关闭/释放时 |
| 4 | `Invariant.Assert(_contextPool[index].InstalledObjects != IntPtr.Zero, "Installed Objects handle is not valid.")` | `PtsCache.cs:331` | 同上 |
| 5 | 同 3（释放路径） | `PtsCache.cs:401` | `ReleaseContext` 之后 |
| 6 | 同 4（释放路径） | `PtsCache.cs:403` | 同上 |
| 7 | `Invariant.Assert(_contextPool[index].PtsHost.Context == ptsContext.Context, "PTS Context mismatch.")` | `PtsCache.cs:316` | 拆卸期 |

⇒ **修法落点因此不是"改某个 getter 的断言"，而是 A2 ①（把失败的池项清掉）**：
池项清掉之后 #2–#7 **结构上不可达**；#1 只在"native 已能回调"时才可能（A1 的 stub 永不回调）。
**这一点直接改变实现方案**，所以单列。

---

## 4. 不可绕 vs 可缓

### 4.1 不可绕（要"让那两页真能用"就必须有）

| # | 项 | 依据 |
|---|---|---|
| U1 | **一个真在工作的分页引擎** —— WPF 里 `FlowDocument`/`RichTextBox` 的排版**只有 PTS 一条路**，没有第二个 formatter | `StructuralCache.cs:477-484` 是唯一创建点；`PtsCache.cs:177-212` 是唯一取用点 |
| U2 | **`CreateInstalledObjectsInfo` 必须被满足或被显式拒绝** —— 它是链上第一跳，**不能"路过"** | `PtsCache.cs:433 → :640` |
| U3 | **native 必须能回调托管**（**151 处回调赋值 / 135 个不同回调名**，`PtsCache.cs:511-713`） | 方向不可绕；**但这也意味着行引擎（`Lo*` 20 条）可以不在 native 里**（§2.5） |
| U4 | **构造期 LS 罚分模块**：`LoCreateContext` + `LoAcquirePenaltyModule` + `LoGetPenaltyModuleInternalHandle`，且句柄要交给 native（`ContextInfo.ptsPenaltyModule`） | `StructuralCache.cs:480`（恒 `true`）→ `PtsCache.cs:446-452` |
| | ⇒ **U4 是"要么实现这 3 条 LS、要么改 `pf` 摘钩"的二选一**（摘钩**不是**一行开关：还要补 `TextFormatter` 接线，且改断行质量） | §2.4 |

### 4.2 可缓（对"最小页面 / 第 24 页"）

`FsQueryTableObj*` 5｜子页/浮动/图形族 ~14｜脚注族 5｜`Nl*` 6｜**`Lo*` 行引擎 20 + 文本分析 4**｜`*Wrapper` 4｜`#if NEVER` 9｜多列/栏平衡（第 24 页单列）｜`FsCompare*`/`FsSynchronize*`（无嵌套容器的情形）

**⇒ 可缓的合计 = 109 − 27 = 82 条**（**这是"补集大小"，不是上列各项相加**：脚注族落在子页/子道族内部、`FsCompare*`/`FsSynchronize*` 也在子道族内部，**有重叠，不许相加**）。
其中**第 23 页把可缓的又拉回来一大半**（表对象 5 + 子页 12 + 浮动/图形 2 + 断字 6 + 多列查询 2 ≈ 27 条）。

### 4.3 一句话的分野

- **"不崩"** 只依赖 **A2**（拆毒池项 + 闩）——**与 PTS 实现无关**，且今天就能做。
- **"能渲染"** 才依赖 **U1–U4**（长线本体）。
- 这两件事**被 `D-G70` 混在一格里**（"必死 `rc=134`"），所以优先级一直说不清。**本报告的建议就是先把它们拆开。**

---

## 5. `NOINFO` 清单（**既不算绿也不算红**）

| # | 项 | 为什么没取到 |
|---|---|---|
| 1 | **"最小页面"真正第一个被请求的 native 入口**（顺序） | 静态推断第一跳是 `CreateInstalledObjectsInfo`（`PtsCache.cs:433` 第一句），**但那是推断**；实测要跑 A0 的绊线（本车道禁跑应用） |
| 2 | **A′ 的 P1/P2 预测是否成真**（`alive=yes`） | 机制已给（毒池项 + 闩），**未实测**；W60A 只证到"守护接住了第一个异常、随后 `FailFast`" |
| 3 | **A2 的闩会不会引起布局重入/挂死** | 未测（设计里已把"文档级幂等 flag"写成硬要求） |
| 4 | **第 23 页的真闭包** | 只做了 XAML 元素静态统计（§2.6）⇒ 具体还差哪些 `Fs*` **未实测** |
| 5 | `FsGetEmptySpaces` / `FsQueryDcpLineVariantsFromCachedTextPara` | 在册但 `PTS\.<名>(` **0 命中** ⇒ "另一种调用形态"还是"又一条死声明"，**未深究** |
| 6 | `docs/unimplemented.md` §2.7 的"**97** 缺失" vs 我算的"**99**" | **差 2，未解**；我以现算读数为准，不去改别人的数 |
| 7 | **"现件"哈希的基线含义** | 采样时整波重建正在进行（活件 mtime `15:34–15:36`，有 `dotnet` 在跑）⇒ 我给的 sha16 一律**只是采样时刻读数**，**不是冻结基线**，不可用于钉值 |
| 8 | **仓内自产件里有没有 LS/PTS 的隐藏实现** | 我独立复验的是**上游**（`upstream/` 零命中 + `redist/` 不存在）；仓内 `src/`/`build/` 我只抽查了 **shim 的导出面**（`nm` 无 `Fs*`；`Lo*` 只有 `LoGetEscString`），**未逐目录穷举** |
| 9 | `WindowsDesktop.App.Runtime.win-x64` 里的真 PE 能提供多少信息 | 未取（本车道不下网/不装包）；**且本机无 wine ⇒ 即便取到也不能当行为 oracle**，只能静态看 |

---

## 6. 大白话小结（6 行）

1. 这族缺 **109** 条导出，扣掉 9 条死声明和 1 条工具误报，**真会炸的 99 条**；`CreateInstalledObjectsInfo` 只是**第一跳**。
2. 想让"最小页面"活下来，**= 27 条入口**要真实现——但它们是**一套分页引擎的契约**，不是 27 个小函数；`TASK-0303` 是**月级长线**。
3. 好消息：**行不用我们排**（本移植已接两层托管兜底）⇒ **20 条 `Lo*` 行引擎不在闭包里**；坏消息：**构造期那 3 条 LS 跑不掉**（`PtsCache` 恒开 optimal），除非改 `pf` 摘钩。
4. **第一步不该是"实现 PTS"，而是"把缺 PTS 做成具名可判的能力边界"**：给 6 个入口导出但**如实失败**＋**拆掉"毒池项"**（这才是现在整进程必死的真因，能 FailFast 的断言至少 7 处）＋**让"不支持"看得见**。
5. 这件事**顺带把"不崩"和"能渲染"拆开**：前者今天就能做且便宜（动 `win32shim` + `pf` 两位）；后者才是长线本体（无参考实现、无可运行真机对照物 ⇒ 从零写）。
6. 最大风险是**把 `FailFast` 变成"静默半通"**——所以判据里必须有一条"**把 stub 改成返回成功，判据必须变红**"的反极性；这条牙齿比功能本身重要。

---

## 7. 复现命令与件 sha16

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
SO=$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so

# ① 现件身份与"缺不缺"
sha256sum $SO | cut -c1-16                                   # c493639d15678803
nm -D --defined-only $SO | wc -l                             # 535
nm -D --defined-only $SO | awk '{print $3}' | grep -x CreateInstalledObjectsInfo || echo NOT-FOUND

# ② 现算导出清单（**不要用仓内那份 9月14 的 bin/exports.txt**）
nm -D --defined-only $SO | awk '{print $3}' | sort > ~/w78a/exports.live.txt   # 535 行 / f44cabae3690e81d

# ③ 覆盖率口径（工具的**沙箱副本**，只改 EXPORTS 与 ROOT 两个常量指向现算清单与真树）
python3 ~/w78a/tools/check-shim-coverage.py --tier mapped > ~/w78a/out/cov-live.txt

# ④ 族分组
grep 'PresentationNative_cor3.dll ' ~/w78a/out/cov-live.txt | awk '{n=$2; sub(/\/.*/,"",n); print n}' | sort | uniq -c | sort -rn

# ⑤ PTS native 入口 vs 托管回调（方向性区分）
cd $R/upstream/wpf/src/Microsoft.DotNet.Wpf/src
grep -rhoE '\bPTS\.[A-Za-z0-9_]+\s*\(' PresentationFramework/ PresentationCore/ WindowsBase/ \
  | sed 's/[[:space:]]*($//;s/($//' | sort | uniq -c | sort -rn

# ⑥ #if NEVER 死声明（工具不求值预处理 ⇒ 会把这 9 条算进"缺口"）
python3 - "$R/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs" <<'PY'
import re,sys
depth=0
for i,l in enumerate(open(sys.argv[1],encoding='utf-8')):
    if re.match(r'\s*#if NEVER',l): depth+=1; continue
    if re.match(r'\s*#endif',l) and depth>0: depth-=1; continue
    if depth>0:
        m=re.match(r'\s*internal static extern (?:unsafe )?[A-Za-z0-9_<>\[\]\.]+\s+([A-Za-z0-9_]+)\s*\(',l)
        if m: print(m.group(1), i+1)
PY
# → 9 条：FsSetDebugFlags 3101 / FsDuplicatePageBreakRecord 3153 / FsRegisterFloatObstacle 3511 /
#          FsGetMaxNumberEmptySpaces 3519 / FsGetNextTick 3546 / FsQuerySegmentDefinedColumnSpanAreaList 3642 /
#          FsQueryHeightDefinedColumnSpanAreaList 3650 / FsQuerySubpageSegmentDefinedColumnSpanAreaList 3719 /
#          FsQuerySubpageHeightDefinedColumnSpanAreaList 3727

# ⑦ 72 条 PTS 声明里"被托管调用"与"零调用"（方向性区分，见 §1.5）
#    （先把 ⑥ 的 9 条与 ⑦ 的 11 条各自算出，再取交集：9 ⊂ 11）
python3 - <<'PY'
import re,os,collections
UP='upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework'
pts=[]
for l in open(os.path.expanduser('~/w78a/out/cov-live.txt'),encoding='utf-8'):
    if 'PresentationNative_cor3.dll ' not in l: continue
    f=l.split(); fp=f[-1].rsplit(':',1)[0]          # ⚠️ 末列是 `文件:行`，先剥行号再判后缀
    if fp.endswith('PtsHost/Pts.cs'): pts.append(f[1].split('/')[0])   # ⚠️ base 列是 `名字/候选名`，取前半
called=collections.Counter()
for root,_,fs in os.walk(UP):
    for fn in fs:
        if fn.endswith('.cs'):
            for m in re.finditer(r'\bPTS\.([A-Za-z0-9_]+)\s*\(', open(os.path.join(root,fn),encoding='utf-8',errors='replace').read()):
                called[m.group(1)]+=1
print('声明',len(pts),'｜被调用',sum(1 for n in pts if called[n]),'｜零调用',sorted(n for n in pts if not called[n]))
PY
```

**件 sha16（采样时刻 `2026-09-21 15:52 +0800`；采样后整波仍在跑 ⇒ 仅供定位，不可当基线）**：

| 件 | sha16 | 备注 |
|---|---|---|
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `c493639d15678803` | 322,056 B（= `#49` 已冻结的 `win32shim` 值） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `f051f5625cb66b1d` | **陈旧**（472 行，2026-09-14） |
| `build/shims/Win32ShimResolver.cs` | `670d4e37592c3a64` | `MappedLibraries` 来源 |
| `build/MilBridge/tools/t1b-ls-tripwire.sh` | `82f6a05afb1f9db9` | A0 的装置（已有） |
| `build/MilBridge/tools/t1b-ls-selftest.c` | `936fda22bfe2f092` | 装置自证 |
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | `fa058b134c64e068` | 两层托管兜底的**生成物**（PC 侧） |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `1e17b8331c2d3d73` | "111 条缺口"自述的出处（`:52`） |
| `upstream/…/PtsHost/Pts.cs` | `1a8575a18767a956` | 72 条 PTS `extern` |
| `upstream/…/PtsHost/PtsCache.cs` | `25a3e0b6c50c2461` | 毒池项与断言 |
| `upstream/…/TextFormatting/LineServices.cs` | `8b2bc2167f5c0bd3` | 27 条 LS `[DllImport]` |
| `build/PresentationFramework.Linux/bin/Debug/PresentationFramework.dll` | `6375fabf89ac7fef` | `pf` 采样值（**正在被整波重建**） |
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `56ee75ced8d6aece` | `pc` 采样值（同上） |
| `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` | `feef049e9d0e313a` | `bridge` 采样值（同上） |
| `build/shims/PresentationCore.HbTextLine.cs` | `921ba9c65e9fb3be` | `hbtextline` |
| `build/MilBridge/known-red.json` | `e38300c235593d3b` | 采样值 |

**本报告**：`$R/build/MilBridge/W78A-report.md` —— sha16 见收尾消息（生成后现算）。
