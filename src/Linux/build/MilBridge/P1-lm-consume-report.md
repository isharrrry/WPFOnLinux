# P1-W101（`t184`）· `LM-1` 第 4 条（宿主侧消费证据）—— **做不到（具名前置）**

**结论（诚实失败，合法终点）**：本件要求的"托管侧**只加只读打印**"在本件写域
（`build/PresentationFramework.Linux/**`）里**没有可落点** —— 第 4 条要观测的量
（`PtsHelper.ArrangeParaList` 里那个 `rcPara.dv`）**只存在于上游件**，而本侧**没有**该件的替身文件可插打印。

⇒ 落**具名前置**：`PRECOND-HOST-CONSUME-OBSERVATORY-OUT-OF-DOMAIN`
（授权出处＝判据件 `acceptance` 第 4 条；射程＝**托管侧 `.cs`**；粒度＝**单次 `ArrangeParaList` 调用**；逐入口＝不适用）。

**零写入声明**：本件**未改任何 `.cs`**、未构建、未跑腿；**唯一写入 ＝ 本载体**。
`LM-1` 第 4 条**维持 `NOINFO`**、`S-2a` **维持 7/8（`S-2a-PARTIAL`）** —— 本件**不**把它们改绿。

---

## 1. 判据要什么（**逐字**引自判据件）

`build/MilBridge/P1-layout-model-criteria.md`（**本席现取**：226 行／`sha16=92b7b68379410b6d`／`mtime 2026-09-29 19:35:14`）：
- `acceptance` **第 4 条**（逐字）：「宿主侧**出现**消费证据：`ArrangeParaList` 走过至少一次且 **`rcPara.dv > 0`**（可用 `_rect`／`GetFirstTextLineBaseline` 的读回证明）」；
- 同件 §2.1／§2.2 把消费面钉成两处：**消费面 A** ＝ `PtsHost/ContainerParagraph.cs`（该件现取 `1d0128592496706d`／1292 行）；**消费面 B** ＝ `PtsHost/PtsHelper.cs:150-181`（`ArrangeParaList` 读段落描述里的 `dvrUsed`／`dvrTopSpace` 并算每段矩形）。

## 2. 观测点的精确坐标（**行号仅本次有效**）

| 件（**都在 `upstream/**`**） | 代际（本席现取） | 该行原文（整行） |
|---|---|---|
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsHelper.cs` | 963 行／`sha16=f2ed9552e983fed1`／`mtime 2026-08-31 09:35:23` | **第 177 行**：`rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;` |
| 同上（调用点） | 同上 | 第 145 行 `internal static void ArrangeParaList(`（第 137 行 `ArrangeParaList(ptsContext, trackDesc.fsrc, arrayParaDesc, fswdirTrack);`） |

## 3. 为什么在**本件写域**里落不了（可复核的域证据）

1. **该量是上游方法的局部**：`rcPara.dv` 是 `ArrangeParaList` 里由 `arrayParaDesc[index]` 算出的局部结果，**只在该方法作用域内**；要打印它必须在该方法体内插语句。
2. **本侧没有该件的替身**（决定性）：`build/PresentationFramework.Linux/PresentationFramework.Linux.csproj`（现取 1562 行／`sha256=e22a7457dc4a8010`）里 `<Compile Remove` 共 **11** 处（含 `PtsCache.cs`／`FlowDocumentView.cs`／`SystemResources.cs`／`Window.cs`／`TextEditorTyping.cs`／`TextContainer.cs` 等），其中 **`PtsHelper` 命中 0、`ContainerParagraph` 命中 0** ⇒ 这两件**按上游原样编译**，本侧**没有**可插打印的替身（对照：`PtsCache.cs` 正是"Remove 上游 ＋ Include 本侧 `*.Linux.cs`"的形制，本件要的那两件**不是**该形制）。
3. **本侧源件里没有该量**（判别命令与结果）：`grep -rln 'rcPara\.dv\|dvrUsed' build/PresentationFramework.Linux/` 命中的**只有编译产物**（`obj/**`、`bin/**` 的 `PresentationFramework.dll`），**12 个 `.cs` 源件（`DeferredTextReference.Linux.cs`／`FlowDocumentView.Linux.cs`／`FrameworkElement.Linux.cs`／`PtsCache.Linux.cs`／`SR.g.cs`／`SystemResources.Linux.cs`／`TextBlock.Linux.cs`／`TextBoxBase.Linux.cs`／`TextBox.Linux.cs`／`TextContainer.Linux.cs`／`TextEditorTyping.Linux.cs`／`Window.Linux.cs`）** 里 **0 命中** ⇒ 本侧**无源文件**持有该变量。
4. **本侧的同名/邻近面都不是它**（逐条排除，避免"看着像就写"）：`FlowDocumentView.Linux.cs` 的 `ArrangeOverride`（第 140 行起）是本侧**视图**的排布；`TextBlock.Linux.cs` 第 84 行 `IContentHost.GetRectangles` 返回的是**内容矩形**；`FrameworkElement.Linux.cs` 里 `Arrange` 只出现在**注释**（第 419／521-529 行）—— **三者都拿不到 `ArrangeParaList` 的 `rcPara.dv`**（它不在它们的作用域里）。

## 4. 三条可行路线（及各自需要的写域 —— **都不在本件写域**）

| 路线 | 要动什么 | 需要谁 |
|---|---|---|
| (a) 在上游 `PtsHelper.cs:177` 后加只读打印 | `upstream/**` | 域含 `upstream/**` 的件主 |
| (b) 造本侧替身件（`PtsHelper.Linux.cs`）＋改 `csproj` 的 `<Compile Remove>`/`<Compile Include>`（或 `reapply-patches.py`） | **非 `.cs`** 的工程件 ＋ 新替身件 | 派单里"只改托管 `.cs`＋载体"之外的授权 |
| (c) 由 **native 驱动面**给出等价的消费见证（如驱动侧回读宿主矩形的量） | `src/WpfGfx.Linux.Native/**` | native 件主 |

⇒ 本席**不自行扩域**、**不自行合件**（队规：超域即停手报队长）。

## 5. `P10` 口径（被拒/被跳样本必须计入）

本件**未产生任何被拒/被跳样本**：因为**没有任何打印点可落** ⇒ 未构建、未跑腿、**零样本**。
如实记（不虚报"跑了但没读到"——那才是 `P10` 要防的形态）。

## 6. 具名 `NOINFO`（本件未做/取不到的）

1. **`rcPara.dv` 今天是否 `> 0`**：**未测**（本件无法观测）；`LM-1` 第 4 条**维持 `NOINFO`**。
2. **`S-2a`**：**维持 7/8**（`S-2a-PARTIAL`），本件**未**推进到 8/8。
3. **"每段高度声称 0"的成对反例**：**未产出**（它是"能观测后才有的反腿"；观测点缺失 ⇒ 反腿同样缺失）。
4. **两腿成对读数（有/无 `M2`）**：**未跑**（无打印点 ⇒ 无两腿）。
5. **副本专用口径（主链 `.so` 重建前后逐字节不变）**：本件**未构建** ⇒ 该条**不发生**（无代际扰动，`src/**` 一件未碰）。
6. 本件**未跑整趟门禁**、**未占显示位**（`/tmp/.X11-unix` 现取 `X0 X1`）、**未 `git add/commit/push`**。

## 7. 纪律

- 写域：本件**只**新建本载体（`build/MilBridge/P1-lm-consume-report.md`）；**未碰**任何 `.cs`、`src/**`、`tools/**`、`tests/**`、`docs/**`、两枚哨兵、`HANDOFF-NEXT.md` 的 `cell=#1`。
- 判据件未动：`P1-layout-model-criteria.md` `92b7b68379410b6d`、`P1-layout-model-report.md`（现取 78 行／`93e738bb15144a21`）**均未改**；相位位不涉（未碰 `pts-pages-guard.sh`）。
- 一切数字**本席现取**（命令与时刻见 §2／§3；未复算他件读数）。

self16=c869fb94966cfc15
