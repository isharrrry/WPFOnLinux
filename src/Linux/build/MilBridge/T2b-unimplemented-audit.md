# T2b · `docs/unimplemented.md` §2.7 对码审计（只读）

**审计人 / 时间 / 对象**：T2b，2026-09-13，对 **当前权威件**（刚换过的那份）。
**结论：§2.7 的 `27 / 1 / 26` 三个数字在新件上仍然成立，无需改动。** 唯一建议是**把取证命令写精确**（见 §4）。

## 0. 本次核验的可复现信息（供文档引用）

| 项 | 值 |
|---|---|
| 权威件 | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` |
| sha256（前 32） | `e1691fd8440da926cb411a06cba23227` |
| 大小 | **269,616 B** |
| 动态导出总数 | **462** |
| 其中 `WpfLinuxWin32_*` | **19** |
| 命令 | `nm -D --defined-only <so>`（取第 3 列符号名，`sort -u`） |
| 上游名单 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs` 的 `EntryPoint = "…"`，**共 27 个** |

## 1. 逐条表（27 个名字 × 实测）

| 名字 | §2.7 说的 | nm 实测 | 结论 |
|---|---|---|---|
| `LoAcquireBreakRecord` | 缺 | 无 | ✅ 一致 |
| `LoAcquirePenaltyModule` | 缺 | 无 | ✅ 一致 |
| `LocbkGetObjectHandlerInfo` | 缺 | 无 | ✅ 一致 |
| `LoCloneBreakRecord` | 缺 | 无 | ✅ 一致 |
| `LoCreateBreaks` | 缺 | 无 | ✅ 一致 |
| `LoCreateContext` | 缺 | 无 | ✅ 一致 |
| `LoCreateLine` | 缺 | 无 | ✅ 一致 |
| `LoCreateParaBreakingSession` | 缺 | 无 | ✅ 一致 |
| `LoDestroyContext` | 缺 | 无 | ✅ 一致 |
| `LoDisplayLine` | 缺 | 无 | ✅ 一致 |
| `LoDisposeBreakRecord` | 缺 | 无 | ✅ 一致 |
| `LoDisposeLine` | 缺 | 无 | ✅ 一致 |
| `LoDisposeParaBreakingSession` | 缺 | 无 | ✅ 一致 |
| `LoDisposePenaltyModule` | 缺 | 无 | ✅ 一致 |
| `LoEnumLine` | 缺 | 无 | ✅ 一致 |
| **`LoGetEscString`** | **已实现（1 条）** | **有** | ✅ 一致 |
| `LoGetPenaltyModuleInternalHandle` | 缺 | 无 | ✅ 一致 |
| `LoQueryLineCpPpoint` | 缺 | 无 | ✅ 一致 |
| `LoQueryLinePointPcp` | 缺 | 无 | ✅ 一致 |
| `LoRelievePenaltyResource` | 缺 | 无 | ✅ 一致 |
| `LoSetBreaking` | 缺 | 无 | ✅ 一致 |
| `LoSetDoc` | 缺 | 无 | ✅ 一致 |
| `LoSetTabs` | 缺 | 无 | ✅ 一致 |
| `CreateTextAnalysisSink` | 缺 | 无 | ✅ 一致 |
| `CreateTextAnalysisSource` | 缺 | 无 | ✅ 一致 |
| `GetNumberSubstitutionList` | 缺 | 无 | ✅ 一致 |
| `GetScriptAnalysisList` | 缺 | 无 | ✅ 一致 |

**计数：有 1 ｜ 缺 26 ｜ 共 27** ⇒ **与 §2.7 的 `27 / 1 / 26` 逐个吻合**（不是只总数吻合，是 27 行逐行吻合）。

## 2. M7b 本轮新增的导出**没有补上任何 `Lo*`**

19 个 `WpfLinuxWin32_*` 全名单（`nm -D` 实测）：
```
WpfLinuxWin32_AbiLayout              WpfLinuxWin32_CharAttrOf            WpfLinuxWin32_ClassificationClassCount
WpfLinuxWin32_ClassificationSelfCheck WpfLinuxWin32_EnsureX11            WpfLinuxWin32_EscStringSelfCheck
WpfLinuxWin32_GetClassName           WpfLinuxWin32_GetWndProc            WpfLinuxWin32_GetX11ConnectionNumber
WpfLinuxWin32_GetX11Display          WpfLinuxWin32_GetX11RootWindow      WpfLinuxWin32_GetX11Screen
WpfLinuxWin32_GetX11Window           WpfLinuxWin32_LastError             WpfLinuxWin32_PostUserMessage
WpfLinuxWin32_PumpOnce               WpfLinuxWin32_ShimVersion           WpfLinuxWin32_UnicodeClassOf
WpfLinuxWin32_WindowCount
```
**判据**：`nm -D --defined-only … | awk '{print $3}' | grep -cE '^WpfLinuxWin32_.*(Lo|Ls|LineServ)'` → **0**
⇒ **这 19 个新导出与 LS（LineServices）无关**，**没有把 §2.7 的 26 条缺口补掉任何一条**。
⇒ 所以 `27 / 1 / 26` **不因本轮新增导出而变化**；§2.7 无需改数字。

## 3. §2.7 那条取证纪律在**当前件**上仍成立

**纪律原文**：「`Lo*` 连符号都没有 ⇒ 真走到 LS 是 `EntryPointNotFoundException`（硬崩），所以『撞上 `E_NOTIMPL` 就说明走到 LS』的取证设计是错的」。

**当前件证据**：**27 个名字里 26 个一条符号都没有**（§1 表），其中就包含 `LoCreateContext`/`LoCreateLine`/`LoAcquireBreakRecord` —— 即 **`nm` 层查无此名** ⇒ `dlsym` 必然失败 ⇒ 真走到那条路是**硬崩**，不会是 `E_NOTIMPL`。
⇒ **纪律仍成立，不需要改。**

## 4. ⚠️ 唯一建议：把 §2.7 引用的**取证命令写精确**

当前文档若用 `nm -D … | grep " Lo"` 这类片段当证据，**它并不精确** —— 同一片段会把**非 LS 的 `Load*`/`Local*` 一起捞进来**。本次实测的原始片段：
```
000000000000f630 T LoadCursor          ← 不是 Lo*（是 LoadCursor）
000000000000f620 T LoadCursorA
000000000000f640 T LoadCursorW
0000000000014230 T LoadImage
0000000000014910 T LoadLibrary
0000000000014840 T LoadLibraryW
0000000000014bb0 T LocalFree
0000000000016890 T LoGetEscString      ← **本片段里唯一的真 Lo\* 符号**
```
**建议落笔文本（可直接用）**：

> §2.7 的清单核验请用**逐名比对**，不要用 `grep " Lo"` 这类子串片段 —— 后者会捞进 `LoadCursor`/`LoadLibrary`/`LocalFree` 等同前缀的 Win32 名字。
> 可复现命令：先取上游 27 个 `EntryPoint` 名，
> `grep -oE 'EntryPoint *= *"[A-Za-z0-9_]+"' <upstream>/…/LineServices.cs | sed 's/.*"\(.*\)"/\1/' | sort -u`
> 再 `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | sort -u` 后逐名比对。
> **核验留痕**：T2b，2026-09-13，件 `e1691fd8440da926…` / 269,616 B / 导出 462（`WpfLinuxWin32_*` 19）⇒ **有 1（`LoGetEscString`）/ 缺 26 / 共 27**，与 §2.7 逐行一致。

## 5. 边界遵守

**只读**：未编辑任何 `.cs`/`.md`（`docs/**` 未动，本报告是新建的独立文件）；**未跑 `dotnet build`、未跑应用**（T3 在用应用槽）；未动 `src/**`、`build/shims/**`、native shim、`build/PresentationCore.Linux/**`、`build/DirectWrite.Linux/**`、`samples/**`、`Presentation.Tests/**`。主控的集成波指纹（波前==波后 `143a9f79…`）**未被我触碰**。
