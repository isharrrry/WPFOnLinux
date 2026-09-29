# P1-W59 · `FSCBK` **103 回调槽**的声明序逐槽侦察 —— 定位 `pfnCreateParaclient`（与 `t133` 运行期实测交叉验证；本件不跑腿、不取 `t133` 的值）

> **本件是只读侦察件**：**不构建、不跑腿、不占显示位、不跑整趟门禁、不 `git add/commit/push`**；**未碰** `src/WpfGfx.Linux.Native/**` 任何源件的**一个字节**（`runner` 的 `t133` 在飞）、**未碰**任何 `.cs`、**未碰** `build/MilBridge/tools/**`。
> **唯一写入** ＝ 本件 `build/MilBridge/P1-fscbk-slot-recon.md`。
> **一切读数由我现取**（命令与输出原样贴出）；**未引任何既有报告当证据** —— `t132` 的四个候选值按任务书**逐字引用**（引用处标明「引用」），**其推导与结论我一条未抄**：本件的偏移全部**我自己按声明算出**（算式见 §1，第三方可复算）。
> **读取时刻**：`ts=2026-09-29T14:18:34.721+0800`（起点）→ `ts=2026-09-29T14:20:32,249202983+08:00`（末取；**本件全部命令的末次执行时刻**见 §8 末行）。

---

## §0 现取快照

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`443c5f9`**（`fix(#81): t136 N1/N3/空态参照集收紧（相位翻转前置）…`） | `git log --oneline -3` |
| 源件（本件唯一的偏移依据） | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs` ＝ **`1a8575a18767a956`** | `sha256sum` |
| `FSCBK` 本体声明 | `Pts.cs:548-555`（`[StructLayout(LayoutKind.Sequential)]` 在 `:547`） | `sed` |
| **`FSCBK` 的成员顺序（决定展平序）** | `:550 cbkgen` → `:551 cbktxt` → `:552 cbkobj` → `:553 cbkfig` → `:554 cbkwrd` | `sed` |
| 五个子结构 | `FSCBKFIG` `:560-565`（3 字段）｜`FSCBKGEN` `:600-634`（**32**）｜`FSCBKOBJ` `:650-660`（8）｜`FSCBKTXT` `:665-698`（**31**）｜`FSCBKWRD` `:773-804`（**29**） | 自算（§1 的 parser） |
| **槽数复核** | 32 ＋ 31 ＋ 8 ＋ 3 ＋ 29 ＝ **103** ⇒**与 `t132` 的 103 一致** | 同上 |
| 布局属性（逐个子结构现取） | **六个都带** `[StructLayout(LayoutKind.Sequential)]`（`FSCBK :547`／`FSCBKFIG :559`／`FSCBKGEN :599`／`FSCBKOBJ :649`／`FSCBKTXT :664`／`FSCBKWRD :772`）；**`:540-830` 内 `Pack =` 命中 0**；**`:548-810` 内 `FieldOffset` 命中 0**、`MarshalAs` 命中 0 | `sed`／`grep -c` |
| `FSCONTEXTINFO` | `Pts.cs:833-844`，成员序：`version`／`fsffi`／`drMinColumnBalancingStep`／`cInstalledObjects`／`pInstalledObjects`／`pfsclient`／`ptsPenaltyModule`／**`fscbk`**／`pfnAssertFailed` | `sed` |
| `pfnCreateParaclient` 字段声明 | **`Pts.cs:619`**（`FSCBKGEN` 内**第 18** 个字段 ⇒ 子内序 **17**） | `grep -n` |

---

## §1 布局依据（**可被第三方复算**）

**四条规则 ＋ 两条算式 ＋ 一条适用范围**：

| # | 依据 | 现取支撑 |
|---|---|---|
| **R1** | **`LayoutKind.Sequential` ⇒ 字段严格按声明序、CLR 不重排** | 六个 `[StructLayout(LayoutKind.Sequential)]` 逐条现取（§0） |
| **R2** | **默认 pack（无 `Pack=`）⇒ 自然对齐**：字段按其**类型自身对齐**落到最近的合法偏移 | `:540-830` 内 `Pack =` **0 命中**；`:548-810` 内无 `FieldOffset`／`MarshalAs` |
| **R3** | **本结构的 103 个字段全部是 8 字节引用／`IntPtr`** ⇒ 每个字段 **size=8、align=8** ⇒ **字段间零填充** | 逐字段类型见 §2 全表（`FSCBKGEN`／`FSCBKTXT`／`FSCBKFIG` 是**委托类型**；`FSCBKOBJ` 前 3 个与 `FSCBKWRD` 全部 29 个是 **`IntPtr`**）。**x64 上委托引用与 `IntPtr` 同为 8 B／8 对齐** |
| **R4** | **五个子结构的尺寸都是 8 的倍数** ⇒ **子结构之间零填充** | 32／31／8／3／29 个字段 ×8 ＝ 256／248／64／24／232，皆为 8 的倍数 |

**算式（第三方可逐格复算）**
```
FrameA(k) = 8 * k                        # k = 展平序号 0..102，基址 = &fscbk
子结构起点(FrameA)：cbkgen 0 | cbktxt 256 | cbkobj 504 | cbkfig 568 | cbkwrd 592
FSCBK 尺寸(FrameA)  = 8 * 103 = 824

FSCONTEXTINFO 前缀 = 4(uint version)+4(uint fsffi)+4(int drMinColumnBalancingStep)
                   +4(int cInstalledObjects)+8(IntPtr pInstalledObjects)+8(IntPtr pfsclient)
                   +8(IntPtr ptsPenaltyModule) = 40        # 每项自然对齐，无填充
FrameB(k) = 40 + FrameA(k)               # 基址 = 传给 native 的 FSCONTEXTINFO*
fscbk 成员在 FSCONTEXTINFO 内的偏移 = 40；其尾部 pfnAssertFailed = 40+824 = 864
```

**适用范围（写死）**：以上**仅在 x64（指针 8 B）成立**；若目标是 x86（指针 4 B、委托引用 4 B），**全部数值须重算**（本件不提供 x86 列，见 §7-N3）。

**parser（本件生成 §2 全表的只读脚本，落在 `/tmp`，不改仓内件）**
```
P=upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs
# 按 `internal struct <名>` 起、按 brace 配平找 body 末行；正则取 `internal <Type> <name>;`
# 五个子结构按 FSCBK:550-554 的成员序展平；FrameA=8k、FrameB=40+8k
python3 /tmp/t138_parse.py     # 输出 n=32/31/8/3/29 ⇒ 合计 103、size=824
```

---

## §2 `FSCBK` **103 槽全表**（序号／子结构／子内序／字段名／声明类型／**Frame A**／**Frame B**／源件:行）

> **两个帧都在表里，因为它们是本件的核心结论（§4）** —— **Frame A** ＝ 以 `&fscbk` 为基；**Frame B** ＝ 以 native 实际拿到的 `FSCONTEXTINFO*` 为基（＝ `40 + FrameA`）。

| 序号 | 子结构 | 子内序 | 字段名 | 声明类型 | Frame A：FSCBK 内偏移 | Frame B：FSCONTEXTINFO 内偏移 | 源件:行 |
|---|---|---|---|---|---|---|---|
| 0 | `FSCBKGEN` | 0 | `pfnFSkipPage` | `FSkipPage` | +0 | +40 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:602` |
| 1 | `FSCBKGEN` | 1 | `pfnGetPageDimensions` | `GetPageDimensions` | +8 | +48 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:603` |
| 2 | `FSCBKGEN` | 2 | `pfnGetNextSection` | `GetNextSection` | +16 | +56 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:604` |
| 3 | `FSCBKGEN` | 3 | `pfnGetSectionProperties` | `GetSectionProperties` | +24 | +64 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:605` |
| 4 | `FSCBKGEN` | 4 | `pfnGetJustificationProperties` | `GetJustificationProperties` | +32 | +72 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:606` |
| 5 | `FSCBKGEN` | 5 | `pfnGetMainTextSegment` | `GetMainTextSegment` | +40 | +80 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:607` |
| 6 | `FSCBKGEN` | 6 | `pfnGetHeaderSegment` | `GetHeaderSegment` | +48 | +88 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:608` |
| 7 | `FSCBKGEN` | 7 | `pfnGetFooterSegment` | `GetFooterSegment` | +56 | +96 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:609` |
| 8 | `FSCBKGEN` | 8 | `pfnUpdGetSegmentChange` | `UpdGetSegmentChange` | +64 | +104 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:610` |
| 9 | `FSCBKGEN` | 9 | `pfnGetSectionColumnInfo` | `GetSectionColumnInfo` | +72 | +112 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:611` |
| 10 | `FSCBKGEN` | 10 | `pfnGetSegmentDefinedColumnSpanAreaInfo` | `GetSegmentDefinedColumnSpanAreaInfo` | +80 | +120 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:612` |
| 11 | `FSCBKGEN` | 11 | `pfnGetHeightDefinedColumnSpanAreaInfo` | `GetHeightDefinedColumnSpanAreaInfo` | +88 | +128 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:613` |
| 12 | `FSCBKGEN` | 12 | `pfnGetFirstPara` | `GetFirstPara` | +96 | +136 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:614` |
| 13 | `FSCBKGEN` | 13 | `pfnGetNextPara` | `GetNextPara` | +104 | +144 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:615` |
| 14 | `FSCBKGEN` | 14 | `pfnUpdGetFirstChangeInSegment` | `UpdGetFirstChangeInSegment` | +112 | +152 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:616` |
| 15 | `FSCBKGEN` | 15 | `pfnUpdGetParaChange` | `UpdGetParaChange` | +120 | +160 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:617` |
| 16 | `FSCBKGEN` | 16 | `pfnGetParaProperties` | `GetParaProperties` | +128 | +168 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:618` |
| 17 | `FSCBKGEN` | 17 | `pfnCreateParaclient` | `CreateParaclient` | +136 | +176 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:619` |
| 18 | `FSCBKGEN` | 18 | `pfnTransferDisplayInfo` | `TransferDisplayInfo` | +144 | +184 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:620` |
| 19 | `FSCBKGEN` | 19 | `pfnDestroyParaclient` | `DestroyParaclient` | +152 | +192 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:621` |
| 20 | `FSCBKGEN` | 20 | `pfnFInterruptFormattingAfterPara` | `FInterruptFormattingAfterPara` | +160 | +200 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:622` |
| 21 | `FSCBKGEN` | 21 | `pfnGetEndnoteSeparators` | `GetEndnoteSeparators` | +168 | +208 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:623` |
| 22 | `FSCBKGEN` | 22 | `pfnGetEndnoteSegment` | `GetEndnoteSegment` | +176 | +216 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:624` |
| 23 | `FSCBKGEN` | 23 | `pfnGetNumberEndnoteColumns` | `GetNumberEndnoteColumns` | +184 | +224 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:625` |
| 24 | `FSCBKGEN` | 24 | `pfnGetEndnoteColumnInfo` | `GetEndnoteColumnInfo` | +192 | +232 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:626` |
| 25 | `FSCBKGEN` | 25 | `pfnGetFootnoteSeparators` | `GetFootnoteSeparators` | +200 | +240 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:627` |
| 26 | `FSCBKGEN` | 26 | `pfnFFootnoteBeneathText` | `FFootnoteBeneathText` | +208 | +248 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:628` |
| 27 | `FSCBKGEN` | 27 | `pfnGetNumberFootnoteColumns` | `GetNumberFootnoteColumns` | +216 | +256 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:629` |
| 28 | `FSCBKGEN` | 28 | `pfnGetFootnoteColumnInfo` | `GetFootnoteColumnInfo` | +224 | +264 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:630` |
| 29 | `FSCBKGEN` | 29 | `pfnGetFootnoteSegment` | `GetFootnoteSegment` | +232 | +272 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:631` |
| 30 | `FSCBKGEN` | 30 | `pfnGetFootnotePresentationAndRejectionOrder` | `GetFootnotePresentationAndRejectionOrder` | +240 | +280 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:632` |
| 31 | `FSCBKGEN` | 31 | `pfnFAllowFootnoteSeparation` | `FAllowFootnoteSeparation` | +248 | +288 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:633` |
| 32 | `FSCBKTXT` | 0 | `pfnCreateParaBreakingSession` | `CreateParaBreakingSession` | +256 | +296 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:667` |
| 33 | `FSCBKTXT` | 1 | `pfnDestroyParaBreakingSession` | `DestroyParaBreakingSession` | +264 | +304 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:668` |
| 34 | `FSCBKTXT` | 2 | `pfnGetTextProperties` | `GetTextProperties` | +272 | +312 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:669` |
| 35 | `FSCBKTXT` | 3 | `pfnGetNumberFootnotes` | `GetNumberFootnotes` | +280 | +320 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:670` |
| 36 | `FSCBKTXT` | 4 | `pfnGetFootnotes` | `GetFootnotes` | +288 | +328 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:671` |
| 37 | `FSCBKTXT` | 5 | `pfnFormatDropCap` | `FormatDropCap` | +296 | +336 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:672` |
| 38 | `FSCBKTXT` | 6 | `pfnGetDropCapPolygons` | `GetDropCapPolygons` | +304 | +344 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:673` |
| 39 | `FSCBKTXT` | 7 | `pfnDestroyDropCap` | `DestroyDropCap` | +312 | +352 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:674` |
| 40 | `FSCBKTXT` | 8 | `pfnFormatBottomText` | `FormatBottomText` | +320 | +360 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:675` |
| 41 | `FSCBKTXT` | 9 | `pfnFormatLine` | `FormatLine` | +328 | +368 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:676` |
| 42 | `FSCBKTXT` | 10 | `pfnFormatLineForced` | `FormatLineForced` | +336 | +376 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:677` |
| 43 | `FSCBKTXT` | 11 | `pfnFormatLineVariants` | `FormatLineVariants` | +344 | +384 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:678` |
| 44 | `FSCBKTXT` | 12 | `pfnReconstructLineVariant` | `ReconstructLineVariant` | +352 | +392 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:679` |
| 45 | `FSCBKTXT` | 13 | `pfnDestroyLine` | `DestroyLine` | +360 | +400 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:680` |
| 46 | `FSCBKTXT` | 14 | `pfnDuplicateLineBreakRecord` | `DuplicateLineBreakRecord` | +368 | +408 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:681` |
| 47 | `FSCBKTXT` | 15 | `pfnDestroyLineBreakRecord` | `DestroyLineBreakRecord` | +376 | +416 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:682` |
| 48 | `FSCBKTXT` | 16 | `pfnSnapGridVertical` | `SnapGridVertical` | +384 | +424 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:683` |
| 49 | `FSCBKTXT` | 17 | `pfnGetDvrSuppressibleBottomSpace` | `GetDvrSuppressibleBottomSpace` | +392 | +432 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:684` |
| 50 | `FSCBKTXT` | 18 | `pfnGetDvrAdvance` | `GetDvrAdvance` | +400 | +440 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:685` |
| 51 | `FSCBKTXT` | 19 | `pfnUpdGetChangeInText` | `UpdGetChangeInText` | +408 | +448 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:686` |
| 52 | `FSCBKTXT` | 20 | `pfnUpdGetDropCapChange` | `UpdGetDropCapChange` | +416 | +456 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:687` |
| 53 | `FSCBKTXT` | 21 | `pfnFInterruptFormattingText` | `FInterruptFormattingText` | +424 | +464 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:688` |
| 54 | `FSCBKTXT` | 22 | `pfnGetTextParaCache` | `GetTextParaCache` | +432 | +472 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:689` |
| 55 | `FSCBKTXT` | 23 | `pfnSetTextParaCache` | `SetTextParaCache` | +440 | +480 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:690` |
| 56 | `FSCBKTXT` | 24 | `pfnGetOptimalLineDcpCache` | `GetOptimalLineDcpCache` | +448 | +488 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:691` |
| 57 | `FSCBKTXT` | 25 | `pfnGetNumberAttachedObjectsBeforeTextLine` | `GetNumberAttachedObjectsBeforeTextLine` | +456 | +496 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:692` |
| 58 | `FSCBKTXT` | 26 | `pfnGetAttachedObjectsBeforeTextLine` | `GetAttachedObjectsBeforeTextLine` | +464 | +504 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:693` |
| 59 | `FSCBKTXT` | 27 | `pfnGetNumberAttachedObjectsInTextLine` | `GetNumberAttachedObjectsInTextLine` | +472 | +512 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:694` |
| 60 | `FSCBKTXT` | 28 | `pfnGetAttachedObjectsInTextLine` | `GetAttachedObjectsInTextLine` | +480 | +520 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:695` |
| 61 | `FSCBKTXT` | 29 | `pfnUpdGetAttachedObjectChange` | `UpdGetAttachedObjectChange` | +488 | +528 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:696` |
| 62 | `FSCBKTXT` | 30 | `pfnGetDurFigureAnchor` | `GetDurFigureAnchor` | +496 | +536 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:697` |
| 63 | `FSCBKOBJ` | 0 | `pfnNewPtr` | `IntPtr` | +504 | +544 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:652` |
| 64 | `FSCBKOBJ` | 1 | `pfnDisposePtr` | `IntPtr` | +512 | +552 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:653` |
| 65 | `FSCBKOBJ` | 2 | `pfnReallocPtr` | `IntPtr` | +520 | +560 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:654` |
| 66 | `FSCBKOBJ` | 3 | `pfnDuplicateMcsclient` | `DuplicateMcsclient` | +528 | +568 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:655` |
| 67 | `FSCBKOBJ` | 4 | `pfnDestroyMcsclient` | `DestroyMcsclient` | +536 | +576 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:656` |
| 68 | `FSCBKOBJ` | 5 | `pfnFEqualMcsclient` | `FEqualMcsclient` | +544 | +584 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:657` |
| 69 | `FSCBKOBJ` | 6 | `pfnConvertMcsclient` | `ConvertMcsclient` | +552 | +592 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:658` |
| 70 | `FSCBKOBJ` | 7 | `pfnGetObjectHandlerInfo` | `GetObjectHandlerInfo` | +560 | +600 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:659` |
| 71 | `FSCBKFIG` | 0 | `pfnGetFigureProperties` | `GetFigureProperties` | +568 | +608 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:562` |
| 72 | `FSCBKFIG` | 1 | `pfnGetFigurePolygons` | `GetFigurePolygons` | +576 | +616 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:563` |
| 73 | `FSCBKFIG` | 2 | `pfnCalcFigurePosition` | `CalcFigurePosition` | +584 | +624 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:564` |
| 74 | `FSCBKWRD` | 0 | `pfnGetSectionHorizMargins` | `IntPtr` | +592 | +632 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:775` |
| 75 | `FSCBKWRD` | 1 | `pfnFPerformColumnBalancing` | `IntPtr` | +600 | +640 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:776` |
| 76 | `FSCBKWRD` | 2 | `pfnCalculateColumnBalancingApproximateHeight` | `IntPtr` | +608 | +648 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:777` |
| 77 | `FSCBKWRD` | 3 | `pfnCalculateColumnBalancingStep` | `IntPtr` | +616 | +656 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:778` |
| 78 | `FSCBKWRD` | 4 | `pfnGetColumnSectionBreak` | `IntPtr` | +624 | +664 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:779` |
| 79 | `FSCBKWRD` | 5 | `pfnFSuppressKeepWithNextAtTopOfPage` | `IntPtr` | +632 | +672 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:780` |
| 80 | `FSCBKWRD` | 6 | `pfnFSuppressKeepTogetherAtTopOfPage` | `IntPtr` | +640 | +680 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:781` |
| 81 | `FSCBKWRD` | 7 | `pfnFAllowSpaceAfterOverhang` | `IntPtr` | +648 | +688 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:782` |
| 82 | `FSCBKWRD` | 8 | `pfnFormatLineWord` | `IntPtr` | +656 | +696 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:783` |
| 83 | `FSCBKWRD` | 9 | `pfnGetSuppressedTopSpace` | `IntPtr` | +664 | +704 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:784` |
| 84 | `FSCBKWRD` | 10 | `pfnChangeSplatLineHeight` | `IntPtr` | +672 | +712 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:785` |
| 85 | `FSCBKWRD` | 11 | `pfnGetDvrAdvanceWord` | `IntPtr` | +680 | +720 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:786` |
| 86 | `FSCBKWRD` | 12 | `pfnGetMinDvrAdvance` | `IntPtr` | +688 | +728 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:787` |
| 87 | `FSCBKWRD` | 13 | `pfnGetDurTooNarrowForFigure` | `IntPtr` | +696 | +736 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:788` |
| 88 | `FSCBKWRD` | 14 | `pfnResolveOverlap` | `IntPtr` | +704 | +744 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:789` |
| 89 | `FSCBKWRD` | 15 | `pfnGetOffsetForFlowAroundAndBBox` | `IntPtr` | +712 | +752 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:790` |
| 90 | `FSCBKWRD` | 16 | `pfnGetClientGeometryHandle` | `IntPtr` | +720 | +760 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:791` |
| 91 | `FSCBKWRD` | 17 | `pfnDuplicateClientGeometryHandle` | `IntPtr` | +728 | +768 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:792` |
| 92 | `FSCBKWRD` | 18 | `pfnDestroyClientGeometryHandle` | `IntPtr` | +736 | +776 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:793` |
| 93 | `FSCBKWRD` | 19 | `pfnObstacleAddNotification` | `IntPtr` | +744 | +784 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:794` |
| 94 | `FSCBKWRD` | 20 | `pfnGetFigureObstaclesForRestart` | `IntPtr` | +752 | +792 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:795` |
| 95 | `FSCBKWRD` | 21 | `pfnRepositionFigure` | `IntPtr` | +760 | +800 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:796` |
| 96 | `FSCBKWRD` | 22 | `pfnFStopBeforeLr` | `IntPtr` | +768 | +808 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:797` |
| 97 | `FSCBKWRD` | 23 | `pfnFStopBeforeLine` | `IntPtr` | +776 | +816 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:798` |
| 98 | `FSCBKWRD` | 24 | `pfnFIgnoreCollision` | `IntPtr` | +784 | +824 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:799` |
| 99 | `FSCBKWRD` | 25 | `pfnGetNumberOfLinesForColumnBalancing` | `IntPtr` | +792 | +832 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:800` |
| 100 | `FSCBKWRD` | 26 | `pfnFCancelPageBreakBefore` | `IntPtr` | +800 | +840 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:801` |
| 101 | `FSCBKWRD` | 27 | `pfnChangeVrTopLineForFigure` | `IntPtr` | +808 | +848 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:802` |
| 102 | `FSCBKWRD` | 28 | `pfnFApplyWidowOrphanControlInFootnoteResolution` | `IntPtr` | +816 | +856 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:803` |
| — | **合计** | — | **103 个字段** | — | **size=824** | **占 FSCONTEXTINFO 的 [40,864)** | — |

---

## §3 `pfnCreateParaclient` 的**定位**与**名字映射链**（逐跳原文）

### 3.1 结论（两个帧都给，语义归属唯一）
- **字段** ＝ `Pts.cs:619 internal CreateParaclient pfnCreateParaclient;`（在 `FSCBKGEN` 内，子内序 **17** ⇒ 展平序号 **17**）
- **Frame A（`&fscbk` 基）＝ `+136`**
- **Frame B（`FSCONTEXTINFO*` 基）＝ `+176`** ⇐ **native 驱动实际要用的那个**（理由见 §4.2）

### 3.2 名字映射链（四跳，逐跳 `<路径>:<行>` ＋ 原文）

**跳 1 —— 委托声明**：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:2128`
```
2128:         internal delegate int CreateParaclient(
                  IntPtr pfsclient,                   // IN:  client opaque data
                  IntPtr nmp,                         // IN:  name of paragraph
                  out IntPtr pfsparaclient);          // OUT: opaque to PTS paragraph client
```
**跳 2 —— 托管侧装配点**：`build/PresentationFramework.Linux/PtsCache.Linux.cs:620`（该件**在飞**：现取 `sha16 = c7d97972e9e71dda`、`mtime 2026-09-29 14:08:40`）
```
620:            contextInfo.fscbk.cbkgen.pfnCreateParaclient = new PTS.CreateParaclient(ptsHost.CreateParaclient);
```
⇒ **这一行同时钉死了三件事**：① 该槽在 **`cbkgen`** 里；② 它的**装配路径**是 `PTS.CreateParaclient(ptsHost.CreateParaclient)`；③ **托管侧确实在装配它**（不是空槽）。
**跳 3 —— 实现**：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsHost.cs:724-740`
```
724:        internal int CreateParaclient(
725:            IntPtr pfsclient,                   // IN:  client opaque data
726:            IntPtr nmp,                         // IN:  name of paragraph
727:            out IntPtr pfsparaclient)           // OUT: opaque to PTS paragraph client
728:        {
729:            int fserr = PTS.fserrNone;
730:            try
731:            {
732:                BaseParagraph para = PtsContext.HandleToObject(nmp) as BaseParagraph;
733:                PTS.ValidateHandle(para);
734:                para.CreateParaclient(out pfsparaclient);
735:            }
736:            catch (Exception e) { pfsparaclient = IntPtr.Zero; PtsContext.CallbackException = e; fserr = PTS.fserrCallbackException; … }
```
**跳 4 —— 再往下（承前一件的**自有**判据，交叉引用而非证据）**：`Paragraph.CreateParaclient` → 五处 `new *ParaClient` → `BaseParaClient : UnmanagedHandle` → `PtsContext.CreateHandle` ⇒ `pfsparaclient` 就是**托管 `_unmanagedHandles` 的槽号**。**该结论我已在 `build/MilBridge/P1-managed-handle-criteria.md`（`t130`）里逐行钉过**（引用我自己那一件；**本件不重复其读数**）。
⚠️ **由跳 3 现取可见的一条硬事实（与本件主题直接相关）**：`CreateParaclient` 回调**第一句就是 `PtsContext.HandleToObject(nmp)`** ⇒ native 若真去驱动这条链，**必须先自己造出合法的 `nmp`**，否则 `:247`／`:248` 两条断言 ⇒ `Invariant.FailFast`（**不可捕获**）。这与 `t130` 的 `PRECOND-MANAGED-PARACLIENT-LIVE` 同族，**本件只登记、不展开**。

---

## §4 与 `t132` 的四个候选对照（**本件最重要的更正**）

### 4.1 逐候选落点（**两帧并列**）
| 候选（**引用** `t132`） | 帧 A（`&fscbk` 基）落在哪个槽 | 帧 B（`FSCONTEXTINFO*` 基）落在哪个槽 |
|---|---|---|
| **`+40`** | 序号 **0** ＝ `cbkgen.pfnFSkipPage` | **`fscbk` 成员本体的偏移**（≡ 帧 B 的基址本身，不是任何槽） |
| **`+56`** | 序号 **7** ＝ `cbkgen.pfnGetFooterSegment` | 序号 **2** ＝ `cbkgen.pfnGetNextSection` |
| **`+136`** | 序号 **17** ＝ **`cbkgen.pfnCreateParaclient`** | 序号 **12** ＝ `cbkgen.pfnGetFirstPara` |
| **`+176`** | 序号 **22** ＝ `cbkgen.pfnGetEndnoteSegment` | 序号 **17** ＝ **`cbkgen.pfnCreateParaclient`** |

### 4.2 **判定：操作帧 ＝ 帧 B ⇒ `pfnCreateParaclient` ＝ `+176`**（理由三条，皆本件自取）
1. **native 拿到的是 `FSCONTEXTINFO*`**：声明是 `int CreateDocContext(ref FSCONTEXTINFO fscontextinfo, out IntPtr pfscontext)`（`Pts.cs:3091-3094`）⇒ **一切偏移以它为基**；native 要拿 `&fscbk` 得**先加 40**。
2. **`FSCONTEXTINFO` 前缀算式 ＝ 40**（§1 逐项现取：4+4+4+4+8+8+8）⇒ `40 + 136 = 176`。
3. **帧 A 只有在"native 已持有 `&fscbk`"时才是直接可用的量**，而拿到 `&fscbk` 本身就要先做帧 B 的第一步（+40）⇒ **对 native 驱动而言，帧 B 是唯一自足的口径**。

### 4.3 由此得到的一条**形态判定**（写死，供 `t133` 的实测裁决）
`+136` 与 `+176` **不是两个不同的槽**，而是**同一个槽在两个不同基址下的两个数**；两者相差 **正好 40 B ＝ `FSCONTEXTINFO` 的前缀长度**。
⇒ **若** `t132` 的四个候选取自**同一个帧**，那么其中一个必然**系统性偏 40 B**；**本件不判它偏的是哪一侧**（`t132` 的取帧未在任务书里给出，记 `NOINFO`，见 §7-N4）——**这正是 `t127` 那类"差一个结构前缀"的自伤形态**（该形态我按任务书**引用**其教训，**不引用其数字**）。

---

## §5 **交叉验证表**（声明序 vs `t133` 运行期实测）—— **已按队长追加指令填成真对照**

> **引用纪律（队长追加指令②，逐字遵守）**：**实测值只能当"被对照的主张"，不是本件的证据。** 本节右列全部标注 **「引自 `t133` 载体，本席未独立复算」**；其载体我**自己现取**过 —— `build/MilBridge/P1-fscbk-offsets-report.md`，**`sha256 = 94ec8e09efd75e6065ceaabaf8847a131c77c20f175e9908bc1fe57dd613cefb`**（＝队长所给值，我复算相符）、**205 行**、`mode 644`、`mtime 2026-09-29 14:20:13.156307151 +0800`、**读取时刻 `ts=2026-09-29T14:21:40.251682705+0800`**。
> **占位行的处置（如实记）**：本节原为占位（右两列全 `NOINFO`、并写"`t133` 尚未回来一格不填"）⇒ 现**被下面的真对照实质取代**（队长追加指令①；**不是**我改口迁就实测）。**本件左列（声明序）一个数未改。**

### 5.1 逐量对照（**28 项，今日全部 `MATCH`，零 `MISMATCH`**）

| # | 量（`t133` 实测口径） | **`t133` 实测值**（引自其载体，本席未独立复算） | **本件声明序值**（§1 算式） | 判定 |
|---|---|---|---|---|
| 1 | sizeof(FSCONTEXTINFO) | 872 | 40+824+8=872 | **MATCH** |
| 2 | sizeof(FSCBK) | 824 | 8*103=824 | **MATCH** |
| 3 | sizeof(FSCBKGEN) | 256 | 32*8=256 | **MATCH** |
| 4 | sizeof(FSCBKTXT) | 248 | 31*8=248 | **MATCH** |
| 5 | sizeof(FSCBKOBJ) | 64 | 8*8=64 | **MATCH** |
| 6 | sizeof(FSCBKFIG) | 24 | 3*8=24 | **MATCH** |
| 7 | sizeof(FSCBKWRD) | 232 | 29*8=232 | **MATCH** |
| 8 | offsetof(FSCONTEXTINFO,fscbk) | 40 | 4+4+4+4+8+8+8=40 | **MATCH** |
| 9 | FSCBK.cbkgen（相对） | 0 | 0 | **MATCH** |
| 10 | FSCBK.cbktxt（相对） | 256 | 32*8=256 | **MATCH** |
| 11 | FSCBK.cbkobj（相对） | 504 | (32+31)*8=504 | **MATCH** |
| 12 | FSCBK.cbkfig（相对） | 568 | (32+31+8)*8=568 | **MATCH** |
| 13 | FSCBK.cbkwrd（相对） | 592 | (32+31+8+3)*8=592 | **MATCH** |
| 14 | cbkgen.pfnGetNextSection（绝对） | 56 | 40+16=56 | **MATCH** |
| 15 | cbkgen.pfnGetSectionProperties（绝对） | 64 | 40+24=64 | **MATCH** |
| 16 | cbkgen.pfnGetMainTextSegment（绝对） | 80 | 40+40=80 | **MATCH** |
| 17 | cbkgen.pfnGetFirstPara（绝对） | 136 | 40+96=136 | **MATCH** |
| 18 | cbkgen.pfnGetNextPara（绝对） | 144 | 40+104=144 | **MATCH** |
| 19 | cbkgen.pfnGetParaProperties（绝对） | 168 | 40+128=168 | **MATCH** |
| 20 | cbkgen.pfnCreateParaclient（绝对） | 176 | 40+136=176 | **MATCH** |
| 21 | cbkgen.pfnTransferDisplayInfo（绝对） | 184 | 40+144=184 | **MATCH** |
| 22 | cbkgen.pfnDestroyParaclient（绝对） | 192 | 40+152=192 | **MATCH** |
| 23 | cbkobj.pfnNewPtr（绝对） | 544 | 40+504+0=544 | **MATCH** |
| 24 | cbkobj.pfnDisposePtr（绝对） | 552 | 40+504+8=552 | **MATCH** |
| 25 | cbkobj.pfnReallocPtr（绝对） | 560 | 40+504+16=560 | **MATCH** |
| 26 | cbkwrd.pfnGetSectionHorizMargins（绝对） | 632 | 40+592+0=632 | **MATCH** |
| 27 | cbkwrd 末槽 pfnFApplyWidowOrphanControlInFootnoteResolution（绝对） | 856 | 40+816=856 | **MATCH** |
| 28 | 空槽计数 nulls | 32 | cbkobj 前 3 ＋ cbkwrd 29 = 32 | **MATCH** |

### 5.2 逐槽覆盖度（103 槽里"哪些格今天只能记 `NOINFO`"）

| 分组 | 槽数 | 判定 |
|---|---|---|
| `cbkgen` 第 1–20 槽（含 **`pfnCreateParaclient`**） | 20 | `t133` 实测其中 **9** 格（含核心槽）⇒ 那 9 格 **MATCH**；其余 **11** 格 **`NOINFO(未逐格实测)`** |
| `cbkgen` 第 21–32 槽 | 12 | **`NOINFO(未逐格实测)`** |
| `cbktxt` 全 31 槽 | 31 | **`NOINFO(未逐格实测)`**（`t133` 只给**组基址**；其载体 §5-2 自述"其余由整窗 103 字的 `[FSCBK-WORD]` 覆盖，可事后按绝对偏移复核"） |
| `cbkobj` 8 槽 | 8 | 前 **3** 个（`IntPtr`）**MATCH**；后 **5** 个 **`NOINFO(未逐格实测)`** |
| `cbkfig` 全 3 槽 | 3 | **`NOINFO(未逐格实测)`** |
| `cbkwrd` 全 29 槽 | 29 | 首槽 **MATCH**、**组级**"应 0 且实测 0" **MATCH**；逐槽 **`NOINFO(未逐格实测)`** |
| **合计** | **103** | **逐格 MATCH 12 格／组级 MATCH 6 项／其余 `NOINFO`** |

⇒ **两件互补（写死）**：**本件给"声明序"这一层（103 槽全有：字段名＋两个帧的偏移＋源件:行）**，`t133` 只给**组基址 ＋ 8 个目标槽 ＋ 两个尺寸**（其载体自述）⇒ **声明序让"任何一个槽"都能算出绝对偏移；实测让"算出来的那 28 项"有机器背书。**

### 5.3 我此前的一条**假设被实测证伪**（如实记，且**不改我的任何数**）

§4.3 我曾写「若 `t132` 的四个候选取自同一帧，则**必有一个系统性偏 40 B**」。`t133` 载体 §0（我现取）显示：四个候选**各有自己的槽名**——`fscbk=+40`／`pfnGetNextSection=+56`／`pfnGetFirstPara=+136`／`pfnCreateParaclient=+176`，且**实测逐项相同** ⇒ **四条都是帧 B 下的四个不同量，不存在 40 B 系统偏差** ⇒ **该假设被证伪，我撤回它**。
⚠️ **但 §4.1／§4.2 的"两帧分解 ＋ 操作帧＝帧 B"仍成立，且正是它让对上成为可能**：帧 B 下 `+136` 归 `pfnGetFirstPara`、`+176` 归 **`pfnCreateParaclient`** —— 与 `t133` 的槽名标注**逐项吻合**（若按帧 A 读，`+136` 会被错读成 `pfnCreateParaclient` ⇒ 那才是真错）。**本件的声明序数值一格未改。**

### 5.4 本件**核心结论**的实测状态（一句话）

**`pfnCreateParaclient` 的绝对偏移 ＝ `+176`** —— 本件**声明序推算**与 `t133` **运行期实测**（其载体 §1／§3.2，**引自 `t133` 载体，本席未独立复算**）**一致 ⇒ `MATCH`**；且该槽在 `t133` 的对拍里是 `EXACT ✓` 的 10 槽之一（`val = 托管 canary` 逐位相等、`±8` 邻居俱不等 ⇒ 有分辨力）。

---

## §6 诚实边界（写死）

1. 🔴 **声明序偏移 ≠ 运行期实际偏移。** `LayoutKind.Sequential` 的**实际字节布局由 CLR 在运行时按目标平台确定**：`Pack`（本件只证"未见显式 `Pack=`"）、显式 `Size`、`[MarshalAs]`、字段类型的运行时实现（委托引用的宽度）、以及**目标架构**都可能改变结果；**本件没有任何一句是运行期读数**。⇒ 在 `t133` 的实测回来之前，§2／§4／§5 的**全部数值**都只是**"声明序推算值"**。
2. **不声称"打通回调链"**：本件只回答"**哪个槽语义上是 `pfnCreateParaclient`**、它在两个帧下的偏移是多少"；**不**声称该槽可被安全调用、**不**声称造得出合法 `nmp`（§3 已现取：错 `nmp` ⇒ 不可捕获的 `FailFast`）。
3. **凡取不到的 ⇒ 具名 `NOINFO`**（§7），**不许用推算值冒充**。
4. **不取 `t133` 的任何值**：本件**未**从任何在飞件/台账里转录 `t133` 的实测偏移（§8 有披露与自证）。

---

## §7 具名 `NOINFO` 清单（逐条给"消掉需要什么"）

| # | 项 | 状态 | 消掉需要 |
|---|---|---|---|
| **N1** | `t133` 的**运行期实测偏移**（本件 §5 右两列的全部格） | `NOINFO(reason=该实测由 runner 在 t133 在飞；契约明禁预填)` | `t133` 交件后按其载体/日志逐格填 |
| **N2** | **本机 CLR 实际的布局**（真实 `Pack`／是否存在平台相关重排／`FSCBK` 的实际 `Marshal.SizeOf`） | `NOINFO(reason=需运行期 `Marshal.OffsetOf`／`Marshal.SizeOf`；本件不跑腿、不构建)` | 一条托管侧只读探针（`t133` 的形态即此）给出 `SizeOf(FSCBK)` 与逐槽 `OffsetOf` |
| **N3** | **x86（指针 4 B）下的偏移** | `NOINFO(reason=本件只按 x64 算式给；x86 下全部须重算)` | 在 x86 目标上重跑同一算式（或声明本移植的锁定架构） |
| **N4** | **`t132` 的四个候选用的是哪个帧** | `NOINFO(reason=任务书未给出其取帧；本件只能并列两帧的落点，判不出它指哪一侧)` | `t132` 载体或其推导过程里明写"基址 = `&fscbk` 还是 `FSCONTEXTINFO*`" |
| **N5** | `pfnAssertFailed`（`FSCONTEXTINFO:843`）的类型与偏移是否确为 +864 | `NOINFO(reason=按 §1 算式应得 +864，但**未运行期验证**；且它是委托字段，算式一致只说明"推算自洽")` | 同 N2 的探针一并给 |
| **N6** | **103 槽里哪些真的被托管侧装配过**（`PtsCache.Linux.cs` 只装配了其中一部分） | `NOINFO(reason=逐槽装配清单需遍历该件的装配段；本件只按任务书钉了 `:620` 这一条)` | 一次对 `PtsCache.Linux.cs` 装配段的**逐槽普查**（另派单） |
| **N7** | `FSCBKWRD` 的 **29 个 `IntPtr`**（**声明里就不是强类型委托**）的语义与调用约定 | `NOINFO(reason=源码只给 `IntPtr`，读不出签名；调用约定与参数表无从现取)` | `Pts.cs` 之外的来源（例如上游 C 头 / 调用点），或声明为"本移植不支持这一族" |

---

## §8 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-fscbk-slot-recon.md`（新建；UTF-8；模式 **644**；**首记号 `# P1-W59 …`（不是 `# ⏪ `）**；末行自带可复算自报口径）。
- **末行自证口径当场复算（本件自带 MATCH）**：口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`；**末行所载值 == 当场重算值 ⇒ MATCH**（值见末行；复算命令亦写在末行）。
- **只读命令清单**：本件全部命令为 `grep`／`sed`／`awk`／`cat`／`sha256sum`／`stat`／`wc`／`sort`／`git log`／`git status` ＋ **一个只读 python parser**（`/tmp/t138_parse.py`，只读 `Pts.cs`，输出落 `/tmp`）。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- 🔴 **一处必须披露的只读接触**：为回答"**native 侧有没有自己的 `fscbk` 镜像**"这一静态问题，我对 `src/WpfGfx.Linux.Native/src/*.c`／`*.h` 做了**一次只读 `grep -rn 'fscbk'`**，命中 `win32_pts.c` 里一段**属于 `t133` 的在飞注释块**（该块含其实测值与"候选 vs 实测"对照文字）。**处置**：① 我**未修改该文件一个字节**（只读）；② 我**未把其中任何实测值或对照文字转录进本件**（§5 右列全部 `NOINFO`）；③ 本件对"帧"的判定（§4.2）**完全由我自己的静态算式 ＋ `Pts.cs:3091-3094` 的 `ref FSCONTEXTINFO` 声明推出**，**不依赖**那段注释。
- **本件命令的末次执行时刻**：`ts=2026-09-29T14:20:32,249202983+08:00`（`date -Ins` 现取；取值与下方 `git status` 同趟）。
- **未改任何其它件**：`git status --porcelain` 现取 ——
```
 M build/MilBridge/HANDOFF-NEXT.md
 M build/MilBridge/tests/PtsPagesProbe/evidence/{app_g1.log,device.txt,device/xfwm.log,five_post_g1.txt,five_pre_g1.txt,leg_23.env,leg_24.env,session.txt}
 M build/PresentationFramework.Linux/PtsCache.Linux.cs        ← t133 在飞
 M src/WpfGfx.Linux.Native/src/win32_pts.c                     ← t133 在飞
 M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/{app_g1.log,device.txt,leg_23.env,leg_24.env}
```
  ⇒ **上述全部属他人**（`t133` 在飞件、证据面、`arm_A` 组）；**本件是本次唯一新增件**。

---

### 结语（自包含）

- **① 103 槽全表**：见 §2（序号／子结构／子内序／字段名／声明类型／**Frame A**／**Frame B**／`Pts.cs:<行>` 逐格可回溯）；**槽数现取复核 ＝ 103**（32＋31＋8＋3＋29），与 `t132` 一致。
- **② `pfnCreateParaclient`**：声明 **`Pts.cs:619`**（`FSCBKGEN` 子内序 **17**／展平序号 **17**）；**帧 A ＝ `+136`**、**帧 B ＝ `+176`**；名字映射链四跳原文见 §3（`:2128` 委托 → `PtsCache.Linux.cs:620` 装配 → `PtsHost.cs:724-740` 实现 → `Paragraph.CreateParaclient`→`CreateHandle`，末跳引用我自己的 `t130` 件）。
- **③ 与四个候选的对照（本件最重要的更正）**：`+40`／`+56`／`+136`／`+176` 在**两个帧下各自落在哪个槽**已逐条给出（§4.1）；**判定：操作帧 ＝ 帧 B ⇒ `pfnCreateParaclient` ＝ `+176`**；`+136` 与 `+176` **是同一槽在相差 40 B 的两个基址下的两个数**，**不是两个槽** ⇒ 若四个候选取自同一帧，则**必有一个系统性偏 40 B**（哪一侧记 `NOINFO`）。
- **④ 布局依据**：`LayoutKind.Sequential`（六个属性逐条现取）＋ 默认 pack（无 `Pack=`）＋ **103 个字段全为 8 B 引用/`IntPtr`** ⇒ 零填充；算式 `FrameA=8k`／`FrameB=40+8k`／子结构起点 `0/256/504/568/592`／`FSCBK=824`／`FSCONTEXTINFO=872`；**仅 x64 成立**（§1）。
- **⑤ 具名 `NOINFO`**：§7 共 **7 条**（含 §5 右两列的全部格在今天**一格都不填**）。
- **⑥ 载体**：路径／行数／全文 sha16／自报口径值 ⇒ 见交件消息；**末行自证当场复算 MATCH**（§8）。

### §8-bis 收尾时刻的一处观察（**只增不改，如实登记**；`ts=2026-09-29T14:20:43,330622135+08:00`）

- 我在**末次** `git status --porcelain` 里现取到新增未跟踪件 `?? build/MilBridge/P1-fscbk-offsets-report.md` ⇒ **`t133` 的载体正在落盘**（`runner` 在飞）。
- **处置（按契约）**：**我没有打开它** —— 任务书明禁"预填 `t133` 的值"，本件也不重复它的活。⇒ **§5 的右两列维持全部 `NOINFO`**，本件的静态值**已冻结**在本件 `sha16` 里（见末行），**与 `t133` 的实测可作良定义的成对对照**。
- **若要做"填表式交叉验证"**，它应是 `t133` 交件后的**另一趟**（届时右两列由 `t133` 的载体逐格给，本件左两列照抄即可；"一致？"列必须**逐格**判，不许一句"一致"）。**本件不含该动作。**

### §8-ter 收尾后的**第二次编辑**（**只增不改，如实登记**；`ts=2026-09-29T14:22:23,454489350+08:00`）

- **触发**：队长**追加指令** —— `runner` 的 `t133` 已交件落盘，要求：① 把 §5 的占位**改成真对照**（逐格标 `MATCH`／`MISMATCH`／`NOINFO`，`MISMATCH` 必须给我的成因假设且**不得改口去迁就实测**）；② **实测值只能当"被对照的主张"，不得当我的证据**（引用必须自己现取并标注「引自 `t133` 载体，本席未独立复算」＋取值时刻）；③ 澄清 `build/MilBridge/P1-fscbk-slot-recon.md` **不是**并发冲突件（它是我本件 `t138` 的载体，队长派的）⇒ 按原射程继续写。
- **我做的（逐条）**：① **自己现取** `build/MilBridge/P1-fscbk-offsets-report.md`（`sha256 94ec8e09efd75e6065ceaabaf8847a131c77c20f175e9908bc1fe57dd613cefb`、205 行、`mode 644`、`mtime 2026-09-29 14:20:13.156307151 +0800`、**读取 `ts=2026-09-29T14:21:40.251682705+0800`**）⇒ 逐量对照填进 **§5.1**（**28 项全 `MATCH`、零 `MISMATCH`**）；② 新增 **§5.2 逐槽覆盖度**（103 槽里哪些格今天只能记 `NOINFO(未逐格实测)`）；③ 新增 **§5.3**：我此前 §4.3 的"必有一个系统性偏 40 B"假设**被实测证伪 ⇒ 撤回**，**且我未改任何声明序数值**；④ 本节。
- 🔴 **本件 `sha16` 换代（并列，供引用时带代际）**：第一次交件 ＝ **`614d60178dc44692`**（319 行）→ **本次编辑后 ＝ 见末行**。按 §7 第 3 条「同名件跨代复写 ⇒ 跨代相减无意义」，**引用本件读数必须带「载体 ＋ `ts` ＋ 代际」**。
- **未改**：§1／§2／§3／§4／§6／§7 的**正文一字未动**；§5 的**原占位行**按队长指令被实质取代，其"原样表述"已在 §5 顶部的「占位行的处置」里如实留下。
`P1-FSCBK-SLOT-RECON 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ be53d76aaa1e12c6（口径＝末行之前的全文；末行＝本行）`
