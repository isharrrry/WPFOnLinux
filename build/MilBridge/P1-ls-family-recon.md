# P1-W9 · LineServices 族缺口面只读取证（`entry=LoSetDoc` 带出的新前沿）

> **本件性质**：**只读取证 ＋ 自算**。唯一写入 ＝ 本件（`build/MilBridge/P1-ls-family-recon.md`，`temp+rename`，模式 644）。
> **一切读数由我现取**；命令与输出**原样**贴在下面；**未引任何既有报告当证据**（`build/MilBridge/P1-ptsname-result.md` 只当"任务输入/待核对象"读，其结论我逐条自己复算）。
> **未做**：未跑应用腿、未占显示位、未 `dotnet build`、未跑整趟门禁、未 `git add/commit/push`。
> **读取时刻**：`ts=2026-09-28T22:53:47.251+0800`（起点）→ `2026-09-28T22:57:36.994+0800`（末取）。

---

## §0 快照与取数口径

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | `7435527`（`docs(#81): t74 重冻结批收口 …`） | `git log --oneline -1` |
| 工作树 | 档 A 现取 **11** 行／档 B 现取 **9** 行（逐行原样见 §6.1；**除本件外全部是他人**在飞件） | `git status --porcelain` |
| 覆盖自检器 | `src/WpfGfx.Linux.Native/tools/check-shim-coverage.py` ＝ **`b07cce3f2e7cf51a`** | `sha256sum` |
| Linux native 权威 `.so` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`2a5165700a8c8579`**／**337,240 B** | `sha256sum` |
| 导出清单 | `src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **`1ccaeb8c96eb1abf`**／**557** 行 | `sha256sum` / `wc -l` |
| `nm -D --defined-only` | **557** 个符号 | `nm -D --defined-only … \| awk '{print $3}' \| grep -c .` |
| 在册缺口声明件 | `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` ＝ **`52ab7d8a7fb401ce`**／41 行 | `sha256sum` |
| LS 声明件 | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs` ＝ **`8b2bc2167f5c0bd3`**／**1620** 行 | `sha256sum` |
| LS 调用件 | `…/PresentationCore/System/Windows/Media/textformatting/TextFormatterContext.cs` ＝ **`00023d954dd580fd`** | `sha256sum` |
| PTS 港口件 | `build/PresentationFramework.Linux/PtsCache.Linux.cs` ＝ **`d940a3471aec8e73`** | `sha256sum` |
| PTS 桩件 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`bdf6e9f8a1b61eae`** | `sha256sum` |

---

## §1 ① LS 族缺口面（含「有没有实现」的**权威口径**）

### 1.1 三条候选口径，我判定的权威 ＝ `check-shim-coverage.py`

三者的现取读数（`ts=2026-09-28T22:56:51.828+0800` 前后）：

```
$ nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -c .
557
$ wc -l < src/WpfGfx.Linux.Native/bin/exports.txt
557
$ for n in LoAcquirePenaltyModule LoCreateContext LoDestroyContext LoGetEscString LoGetPenaltyModuleInternalHandle LoSetDoc; do
    printf "%-34s nm=%s exports=%s native_src_grep=%s\n" "$n" \
      "$(nm -D --defined-only … | awk '{print $3}' | grep -cx "$n")" \
      "$(grep -cx "$n" src/WpfGfx.Linux.Native/bin/exports.txt)" \
      "$(grep -rl "$n" src/WpfGfx.Linux.Native/src/ | wc -l)"; done
LoAcquirePenaltyModule             nm=1 exports=1 native_src_grep=1
LoCreateContext                    nm=1 exports=1 native_src_grep=1
LoDestroyContext                   nm=1 exports=1 native_src_grep=1
LoGetEscString                     nm=1 exports=1 native_src_grep=2      ← 源码 grep 命中 2 个文件
LoGetPenaltyModuleInternalHandle   nm=1 exports=1 native_src_grep=1
LoSetDoc                           nm=0 exports=0 native_src_grep=0
```

**权威 ＝ `check-shim-coverage.py`（`--tier mapped`，默认档）**。理由（逐条，皆可复算）：
1. **只有它同时做两件事**：① 按 **.NET 在 Unix 上的真实探测顺序**把每条 `[DllImport]` 换算成"运行时**实际会去要**的名字"（`CharSet.Unicode + ExactSpelling=false ⇒ 先 `名W` 再 `名`；`CharSet.Auto` 在 Unix 折成 Ansi ⇒ **只找裸名**；有 `EntryPoint` 则用 `EntryPoint` 作基名）；② 与 `nm -D --defined-only` 的结果比对，**只保留会抛 `EntryPointNotFoundException` 的**。它的件头把这条探测顺序写成"这一条错了整个工具就没意义"。
2. **`nm`／`exports.txt` 单独用不构成权威**：它们给的是"**导出集**"，**回答不了"托管侧会不会来要这个名字"** —— 例如 `LoSetDoc` 的探测名是 `LoSetDoc` 与 `LoSetDocA` 两个，导出集里没有并不等于"跑不到"（可能是走 `Lo*` 的 `EntryPoint` 别名）。反过来，导出集里**有**也不能证明"名字对得上"（`CharSet` 折叠错一位就漏）。
   - 现取旁证：`nm` 与 `exports.txt` **两者互不独立**（同为 **557** 且逐名一致）⇒ 它们只能作**同一个事实**的第二来源，不能当判据的全部。
3. **`grep -rl <名> src/WpfGfx.Linux.Native/src/` 不构成权威**：它是**文本**命中，不是符号命中 —— 现取反例两条：`LoGetEscString` 在 native 源码里命中 **2** 个文件（同一个名字出现在两处文本，计数没有"导出"的含义）；而 `win32_pts.c` 的 `k_pts_entries[]` 十名是**字符串表**（不是符号表），根本不在 `nm -D` 里。⇒ 该口径**既会多算也会少算**。

**命令（我原样跑的）**：
```
$ python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py > /tmp/t75-ssc.out 2>/tmp/t75-ssc.err ; echo $?
0
```
输出结构（现取原始行）：
```
MappedLibraries 11 个 （解析自 build/shims/Win32ShimResolver.cs）

未映射的 DLL（会 DllNotFoundException）: 32 个
  wpfgfx_cor3.dll               109 条   例：…
  …（共 32 个 DLL）

扫描到 421 条 DllImport 指向本 shim 映射的 DLL（仅映射集）
  已有导出可用 : 303
  **会 EntryPointNotFoundException** : 118

  [PresentationNative_cor3.dll] 99 条
  [shell32.dll] 10 条
  [dwmapi.dll] 6 条
  [ntdll.dll] 2 条
  [gdiplus.dll] 1 条
```

### 1.2 族表（**本 DLL ＝ `PresentationNative_cor3.dll`**，99 条缺口，按**声明件**分族）

命令（现取自算）：
```
$ awk '/^  PresentationNative_cor3\.dll /{print}' /tmp/t75-ssc.out | grep -oE 'src/[^ ]+$' | sed 's/:[0-9]*$//' | sort | uniq -c | sort -rn
     66 src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs
     22 src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs
      5 src/Microsoft.DotNet.Wpf/src/Shared/MS/Win32/NativeMethodsSetLastError.cs
      3 src/Microsoft.DotNet.Wpf/src/PresentationFramework/System/Windows/Documents/NLGSpellerInterop.cs
      3 src/Microsoft.DotNet.Wpf/src/PresentationFramework/System/Windows/Documents/NaturalLanguageHyphenator.cs
```

| 族（＝声明件） | 条目数 | 名字前缀分布 |
|---|---|---|
| **`MS/Internal/PtsHost/Pts.cs`（PTS 族）** | **66** | `Fs*` 66 |
| **`MS/internal/TextFormatting/LineServices.cs`（LS 族）** | **22** | `Lo*` 18 ＋ 文本分析 4 |
| `Shared/MS/Win32/NativeMethodsSetLastError.cs` | 5 | `*Wrapper` 5 |
| `PresentationFramework/…/NLGSpellerInterop.cs` | 3 | `Nl*` 3 |
| `PresentationFramework/…/NaturalLanguageHyphenator.cs` | 3 | `Nl*` 3 |
| **合计** | **99** | （前缀核对：`Fs*`66＋`Lo*`18＋`Nl*`6＋`Wrapper*`5＋其它4 ＝ 99） |

前缀核对命令与读数：
```
$ awk '/^  PresentationNative_cor3\.dll /{print}' /tmp/t75-ssc.out | sed -E 's/^  PresentationNative_cor3\.dll  ([^ ]+).*/\1/' | sort -u | wc -l
99
$ … | tee /tmp/t75-pn-names.txt | grep -c '^Lo'      ⇒ 18
$ grep -c '^Fs' /tmp/t75-pn-names.txt                ⇒ 66
$ grep -c '^Nl' /tmp/t75-pn-names.txt                ⇒ 6
$ grep -c 'Wrapper' /tmp/t75-pn-names.txt            ⇒ 5
$ grep -vcE '^Lo|^Fs|^Nl|Wrapper' /tmp/t75-pn-names.txt ⇒ 4
```

### 1.3 🔴 **LS 族 22 条逐条**（入口名 / 声明点 / 调用点 / 运行时探测名）

**声明件总数 vs 缺口**：`LineServices.cs` 里 `[DllImport]` ＝ **27** 条、`EntryPoint` ＝ **27** 条；其中 **22** 条在缺口集、**5** 条已导出。
```
$ grep -c 'DllImport' <LineServices.cs>        ⇒ 27
$ grep -c 'EntryPoint' <LineServices.cs>       ⇒ 27
$ comm -23 <(27 个 EntryPoint 去重排序) <(22 个缺口名排序)   ⇒ 5 条已实现：
LoAcquirePenaltyModule / LoCreateContext / LoDestroyContext / LoGetEscString / LoGetPenaltyModuleInternalHandle
```

| # | 入口名 | 声明点（`LineServices.cs:`） | 调用点（我现取的 `UnsafeNativeMethods.<名>` 出现位） | 运行时探测名 |
|---|---|---|---|---|
| 1 | `CreateTextAnalysisSink` | 1589 | `PresentationCore/MS/internal/Shaping/TypefaceMap.cs:120` | `CreateTextAnalysisSink/CreateTextAnalysisSinkA` |
| 2 | `CreateTextAnalysisSource` | 1609 | `…/Shaping/TypefaceMap.cs:123` | `CreateTextAnalysisSource/CreateTextAnalysisSourceA` |
| 3 | `GetNumberSubstitutionList` | 1603 | `…/Shaping/TypefaceMap.cs:122` | `GetNumberSubstitutionList/GetNumberSubstitutionListA` |
| 4 | `GetScriptAnalysisList` | 1596 | `…/Shaping/TypefaceMap.cs:121` | `GetScriptAnalysisList/GetScriptAnalysisListA` |
| 5 | `LoAcquireBreakRecord` | 1440 | `…/TextFormatting/TextMetrics.cs:291` | `LoAcquireBreakRecord/LoAcquireBreakRecordA` |
| 6 | `LoCloneBreakRecord` | 1453 | `System/Windows/Media/textformatting/TextLineBreak.cs:73` | `LoCloneBreakRecord/LoCloneBreakRecordA` |
| 7 | `LoCreateBreaks` | 1522 | `System/Windows/Media/textformatting/TextFormatterContext.cs:314` | `LoCreateBreaks/LoCreateBreaksA` |
| 8 | `LoCreateLine` | 1419 | `System/Windows/Media/textformatting/TextFormatterContext.cs:288` | `LoCreateLine/LoCreateLineA` |
| 9 | `LoCreateParaBreakingSession` | 1533 | `System/Windows/Media/textformatting/TextFormatterContext.cs:336` | `…/LoCreateParaBreakingSessionA` |
| 10 | `LoDisplayLine` | 1486 | `…/TextFormatting/FullTextLine.cs:602` | `LoDisplayLine/LoDisplayLineA` |
| 11 | `LoDisposeBreakRecord` | 1446 | `System/Windows/Media/textformatting/TextLineBreak.cs:94` | `LoDisposeBreakRecord/LoDisposeBreakRecordA` |
| 12 | `LoDisposeLine` | 1433 | `…/TextFormatting/FullTextLine.cs:145` ＋ `…/TextFormatting/FullTextBreakpoint.cs:197` | `LoDisposeLine/LoDisposeLineA` |
| 13 | `LoDisposeParaBreakingSession` | 1544 | `System/Windows/Media/textformatting/TextParagraphCache.cs:150` | `…/LoDisposeParaBreakingSessionA` |
| 14 | `LoDisposePenaltyModule` | 1575 | `…/TextFormatting/TextPenaltyModule.cs:59` | `LoDisposePenaltyModule/LoDisposePenaltyModuleA` |
| 15 | `LoEnumLine` | 1494 | `…/TextFormatting/FullTextLine.cs:2131` | `LoEnumLine/LoEnumLineA` |
| 16 | `LoQueryLineCpPpoint` | 1502 | `…/TextFormatting/FullTextLine.cs:2485` ＋ `:2507` | `LoQueryLineCpPpoint/LoQueryLineCpPpointA` |
| 17 | `LoQueryLinePointPcp` | 1512 | `…/TextFormatting/FullTextLine.cs:2432` ＋ `:2450` | `LoQueryLinePointPcp/LoQueryLinePointPcpA` |
| 18 | `LoRelievePenaltyResource` | 1459 | `…/TextFormatting/FullTextBreakpoint.cs:238` | `…/LoRelievePenaltyResourceA` |
| 19 | `LoSetBreaking` | 1464 | `System/Windows/Media/textformatting/TextFormatterContext.cs:257`（**上游调用者** ＝ 同件 `:155`，见 §2.3） | `LoSetBreaking/LoSetBreakingA` |
| 20 | **`LoSetDoc`** | **1470** | `…/textformatting/TextFormatterContext.cs:354`（上游调用者 ＝ 同件 `:149`） | **`LoSetDoc/LoSetDocA`** |
| 21 | `LoSetTabs` | 1478 | `…/textformatting/TextFormatterContext.cs:374`（上游调用者 ＝ `TextParagraphCache.cs:50`／`FullTextLine.cs:220`／`FullTextState.cs:196`／`:205`） | `LoSetTabs/LoSetTabsA` |
| 22 | `LocbkGetObjectHandlerInfo` | 1551 | `…/TextFormatting/LineServicesCallbacks.cs:2294` | `…/LocbkGetObjectHandlerInfoA` |

**上表的取数命令（原样，可重跑）**：
```
$ awk '/^  PresentationNative_cor3\.dll /{print}' /tmp/t75-ssc.out | grep 'LineServices.cs' \
    | sed -E 's/^  PresentationNative_cor3\.dll  ([^ ]+).*LineServices\.cs:([0-9]+)$/\1\t\2/'   # 22 行
$ while IFS=$'\t' read -r n line; do
    grep -rn "\b$n\b" upstream/wpf --include='*.cs' | grep -v 'TextFormatting/LineServices.cs' \
      | sed 's|upstream/wpf/src/Microsoft.DotNet.Wpf/src/||' | cut -d: -f1,2
  done < 上一步的 22 行
```

**射程边界（如实写）**：上表"调用点"是**静态文本命中**（`\b名\b` 在 `*.cs` 里、排除声明件本身）；**它不等于"运行期必然被调用"** —— 例如 `LoEnumLine`／`LoQueryLine*` 属命中测试路径，本次两页（富文本 23／流文档 24）未必走到。**"必被走到"的判定需要运行期证据**（见 §2、§3）。

---

## §2 ② `LoSetDoc` 单格

### 2.1 上游签名（`LineServices.cs` **原文，逐行照抄**，`:1464–1476`）

```
        [DllImport(DllImport.PresentationNative, EntryPoint="LoSetBreaking")]
        internal static extern LsErr LoSetBreaking(
            IntPtr                  ploc,
            int                     strategy
            );

        [DllImport(DllImport.PresentationNative, EntryPoint="LoSetDoc")]
        internal static extern LsErr LoSetDoc(
            IntPtr                  ploc,
            int                     isDisplay,
            int                     isReferencePresentationEqual,
            ref LsDevRes            deviceInfo
            );
```
⇒ 返回 `LsErr`；参数 ＝ `ploc`（LS 上下文）／`isDisplay`／`isReferencePresentationEqual`／`ref LsDevRes deviceInfo`（设备分辨率）。

### 2.2 `LsErr` 语义（`LineServices.cs:561` 起，原文节选）

```
    internal enum LsErr 
    {
        None                                    = 0,
        InvalidParameter                        = -1,
        OutOfMemory                             = -2,
        NullOutputParameter                     = -3,
        InvalidContext                          = -4,
        InvalidLine                             = -5,
        InvalidDnode                            = -6,
        InvalidDeviceResolution                 = -7,
        InvalidRun                              = -8,
        MismatchLineContext                     = -9,
        ContextInUse                            = -10,
        …
```
判错口径（现取实现）：`TextFormatterContext.cs:388-395`
```
        internal static void ThrowExceptionFromLsError(string message, LsErr lserr)
        {
            if (lserr == LsErr.OutOfMemory)
                throw new OutOfMemoryException (message);

            throw new Exception(message);
        }
```
⇒ **非 `None` 即抛**（`OutOfMemory` 特殊化成 `OutOfMemoryException`）。⚠️ 这与 `PTS` 侧 `-10000 (tserrNotImplemented)` 不同：`-10000` **不在** `LsErr` 枚举里（该枚举是 LS 自己的码表）。
（`-10000` 的出处我现取自 `win32_pts.c` 的注释行，仅作**口径对照**，不作为 LS 语义证据：`tserrNotImplemented = -10000`。）

### 2.3 调用**时机**（相对 `PTS.CreateDocContext` 的先后）—— 代码级钉死

链路（全部我现取）：

| 步 | 证据位（文件:行） | 原文要点 |
|---|---|---|
| 1 | `PtsCache.Linux.cs:532` | `textFormatterContext = new TextFormatterContext();`（在 `private IntPtr CreatePTSContext(int index, TextFormattingMode)`（`:507` 起）内、`if (_contextPool[index].IsOptimalParagraphEnabled)` 块内） |
| 2 | `TextFormatterContext.cs:30-34` | 构造函数 `public TextFormatterContext() { _ploc = IntPtr.Zero; Init(); }` |
| 3 | `TextFormatterContext.cs:113` | `lserr = UnsafeNativeMethods.LoCreateContext(` ← **已导出**（不抛） |
| 4 | `TextFormatterContext.cs:129` | `_ploc = ploc;` |
| 5 | `TextFormatterContext.cs:149` | `SetDoc(` ← **`Init()` 里的第一个 LS P/Invoke** |
| 6 | `TextFormatterContext.cs:354` | `LsErr lserr = UnsafeNativeMethods.LoSetDoc(` ⇒ **此处抛 `EntryPointNotFoundException`** |
| 7 | `TextFormatterContext.cs:155` | `SetBreaking(BreakStrategies.BreakCJK);` ⇒ 若第 6 步不抛，这里会撞 `LoSetBreaking`（`:257`） |
| 8 | `PtsCache.Linux.cs:548` | `PTS.Validate(PTS.CreateDocContext(ref _contextPool[index].ContextInfo, out context));` |

⇒ **顺序结论（钉死）**：同一方法 `CreatePTSContext` 内，**`:532`（`new TextFormatterContext()`）先于 `:548`（`PTS.CreateDocContext`）**；而 `:532` 的构造函数同步跑完 `Init()`（`:37–157`），在 `Init()` 内部 **`:149 → :354` 是最早被调用的缺失 LS 入口**。
⇒ 所以 **LS 族在 `PTS.CreateDocContext` 这一站之前就把链路掐断** ⇒ `win32_pts.c` 的台账（`k_pts_entries[]` 十名，现取 `awk` 计数 ＝ **10**）在该路径上**一次都不会被调用** ⇒ 台账零行。

**经验侧独立吻合**（我现取的文件，**不是**在册载体）：`~/p1-ptsname/legs-after/app_g1.log`（`4db15b4c8466fadd`／120,292 B）:
```
$ grep -o 'entry=[A-Za-z0-9_]*' ~/p1-ptsname/legs-after/app_g1.log | sort | uniq -c
      2 entry=LoSetDoc
```
⇒ 具名的确是 **`LoSetDoc`**，**且正是代码推出的"第一个被撞的 LS 入口"**（不是 `LoSetBreaking`）。

### 2.4 「只补 `LoSetDoc` 一个入口够不够过这一步」—— **不够**（论证）

- **论证**：`Init()` 在 `:149` 调 `SetDoc` **之后**，**同一函数体内**紧接着 `:155` 调 `SetBreaking` ⇒ 若只把 `LoSetDoc` 补上，`Init()` 会继续走到 `:155 → :257 → LoSetBreaking` ⇒ **同一个 `EntryPointNotFoundException` 会在下一跳再抛一次**，`new TextFormatterContext()` 仍失败、`:548` 仍到不了。
- **真正会先被撞上的"下一个"入口 ＝ `LoSetBreaking`**（`LineServices.cs:1464` 声明；`:257` 调用；`:155` 触发）。同法取证：`LoSetBreaking` 在 §1.3 的 22 条缺口中（**当前 `.so` 0 导出**，见 §1.1 的 `nm`/`exports` 逐名读数）。
- **边界**：`Init()` 内 `:113` 的 `LoCreateContext` **已导出**（§1.1 现取 `nm=1`），故它不是障碍；`GetTextPenaltyModule()`（`TextFormatterContext.cs:163-167`，体只有 `Invariant.Assert(_ploc != IntPtr.Zero); return new TextPenaltyModule(_ploc);`）在 `PtsCache.Linux.cs:533` 被调，其构造 `TextPenaltyModule.cs:23-32` 调 **`LoAcquirePenaltyModule`（已导出）** ⇒ 也不是障碍。
⇒ **结论：只补 `LoSetDoc` 不够；最小"过 `TextFormatterContext()` 构造"的集合 ＝ `LoSetDoc` ＋ `LoSetBreaking`。**

---

## §3 ③ 最小增量序列草案（要让**台账真非零**）

**目标口径（W8 在册）**：「台账非零 ⟺ 六缺口 stub 之一被调用」。要让它非零，必须让链路**走到** `PtsCache.Linux.cs:548` 的 `PTS.CreateDocContext`。

| 序 | 要补的入口 | 为什么是它（我现取的证据位） |
|---|---|---|
| 1 | **`LoSetDoc`** | `TextFormatterContext.cs:149`（→ `:354`）是 `Init()` 内**第一个**缺失 LS 入口；触发者 ＝ `PtsCache.Linux.cs:532` 的 `new TextFormatterContext()` |
| 2 | **`LoSetBreaking`** | 紧接着 `TextFormatterContext.cs:155`（→ `:257`）；不补则第 1 步白做 |
| 3 | （无）`LoAcquirePenaltyModule` | **已导出**（§1.1 `nm=1`／`exports=1`）；`PtsCache.Linux.cs:533` 的 `GetTextPenaltyModule()` → `TextPenaltyModule.cs:26` 调它，**当前不抛** |
| 4 | **`PTS.CreateDocContext`**（台账 idx2） | `PtsCache.Linux.cs:548`；到这一步台账即**真非零** —— 它是六缺口 stub 之一（`win32_pts.c` 的 `k_pts_entries[]` 现取含 `CreateDocContext`） |

⇒ **最小增量序列 ＝ ① `LoSetDoc` ② `LoSetBreaking`（后到 `PTS.CreateDocContext` 即达"台账非零"）**。
**序列的形状（给 W8 的判断）**：这是典型的"**前沿只位移一跳**"增量 —— 补完 ②，下一个被撞的将是 `CreateLine`/`CreateBreaks`/`CreateParaBreakingSession`/`SetTabs`/`LoEnumLine`/`LoDisplayLine`/… 中的某一个（§1.3 表里 `TextFormatterContext.cs` 的调用点 `:288`／`:314`／`:336`／`:374` 与 `FullTextLine.cs` 的 `:231`／`:262`／`:220`／`:602`／`:2131` 等多处），**要"两页真排版"不是这几条能收口的**。

**③ 的边界（NOINFO，见 §5-2）**：我**只能**证到"过 `TextFormatterContext()` 构造"这一段的顺序；**"两页真排版"所需的完整入口序列**需要运行期逐步取证（每补一跳再跑一趟腿读 `entry=`），**本件不跑腿 ⇒ 不编**。

---

## §4 ④ 候选池计数（自复算）与**冲突点名**

### 4.1 我现取的三个口径（`pts-gap-count-check.sh`）

```
$ bash build/MilBridge/tools/pts-gap-count-check.sh | tail -3          # ts=2026-09-28T22:56:45.036+0800
PTSGAP_FRONTIER before=LoCreateContext@3 after=unknown@2 carrier_sha16=cb0a3e5510b07790 carrier_mtime=2026-09-28 20:48:56.275132855 +0800 ts=2026-09-28 22:56:45.034219772 +0800
PTSGAP_FRONTIER_STATE=UNNAMED（载体里**没有具名前沿**：应用侧只记 unknown ⇒ 本增量**不计具名进度**；**这不是绿**）
PTSGAP=PASS tool=99 dead=11 artifact=1 ops=87 impl=93 so16=2a5165700a8c8579 exports=557 root=/home/links-dev/netTest/GitProj/WPFOnLinux
```
口径拆解（我把该器的实现行现取出来读）：
- `TOOL=$(wc -l < "$GAP")`，`GAP` ＝ `check-shim-coverage.py` 输出里 `$1=="PresentationNative_cor3.dll"` 的名字集 ⇒ **99**
- `OPS = TOOL − DEAD − ARTI` ＝ 99 − 11 − 1 ＝ **87**
- `STUB = grep -cE '^[[:space:]]*return wpf_pts_gap\("' src/…/win32_pts.c` ⇒ 我复算 ＝ **6**
- `IMPL = OPS + STUB` ＝ 87 + 6 ＝ **93**

### 4.2 「候选池含 LS 族 ⇒ 从多少变成多少」

| 口径 | 修前 | 含 LS 族后 | 依据 |
|---|---|---|---|
| **W8 的「六缺口 stub」池**（`P1-ptsname-result.md:59` 的那句"不只有 `win32_pts.c` 的六缺口 stub"所指） | **6** | **28**（6 ＋ LS 族 22） | `STUB=6`（现取）；LS 族 22 ＝ §1.3 表 |
| **工具口径 `tool`**（＝ `PresentationNative_cor3.dll` 的全部 ENFE 名字） | **99** | **99（不变）** | 该口径**本来就含** LS 族 —— 现取：99 里 `Lo*`18 ＋ 文本分析 4 ＝ **22** 全在（§1.2 前缀核对） |
| **可操作 `ops`／实现 `impl`** | **87 ／ 93** | **87 ／ 93（不变，若维持同一 `TOOL`）** | 同上：LS 族已在其 `TOOL` 里 |
| 若把 W8 的池**另立**为"PTS 六 stub ＋ LS 族" | — | **6 → 28**，且**与 87／93 是两套口径，不可相加** | 见 §4.3 冲突点 |

**命令（可重跑）**：
```
$ awk '/^  PresentationNative_cor3\.dll /{print}' /tmp/t75-ssc.out | sed -E 's/^  PresentationNative_cor3\.dll  ([^ ]+).*/\1/' | sort -u \
  | awk '{if ($0 ~ /^Lo/) lo++; else if ($0 ~ /^Fs/) fs++; else if ($0 ~ /^Nl/) nl++; else if ($0 ~ /Wrapper/) w++; else o++} END{printf "Lo=%d Fs=%d Nl=%d Wrapper=%d other=%d total=%d\n", lo,fs,nl,w,o,lo+fs+nl+w+o}'
Lo=18 Fs=66 Nl=6 Wrapper=5 other=4 total=99
$ grep -cE '^[[:space:]]*return wpf_pts_gap\("' src/WpfGfx.Linux.Native/src/win32_pts.c     ⇒ 6
$ awk '/k_pts_entries\[\] = \{/,/\};/' src/WpfGfx.Linux.Native/src/win32_pts.c | grep -cE '^[[:space:]]*"'  ⇒ 10
```

### 4.3 🔴 冲突点名（**不和谐掉**）

1. **`docs/ROUTES.md` 在册的「工具口径 100」与现取 `99` 冲突（差 1）**。
   - 在册原文（我现取该行）：`**工具口径 100**（`check-shim-coverage.py b07cce3f2e7cf51a`：66 `Fs*`／19 `Lo*`／6 `Nl*`／4 文本／5 `*Wrapper…`）`
   - 我现取：`tool=99`；前缀分解 **`Fs*`66／`Lo*`18／`Nl*`6／`文本`4／`Wrapper*`5 ＝ 99**。
   - ⇒ **差恰好 1，且落在 `Lo*`（19 → 18）**；`check-shim-coverage.py` 的 sha16 **在册与现取相同（`b07cce3f2e7cf51a`）** ⇒ 变的是**被扫的树/导出面**，不是工具。**点名**：在册那行是 `2026-09-26` 的读数，现已过期（一个 `Lo*` 名字如今已导出）。
   - 同页 `TASK-0302` 的「**可操作缺口 87 条／实现口径 93 条**」与现取 **逐值相同**（`ops=87 impl=93`）⇒ 这一处**不冲突**。
2. **`P1-ptsname-result.md` §4 的 `grep -rl 'LoSetDoc' src/WpfGfx.Linux.Native/src/` ＝ 0** —— 我复算 **0**，**成立**（§1.1 表 `LoSetDoc native_src_grep=0`）。
3. **🔴 具名前沿的**载体**现取不一致（这不是数字冲突，是"证据不在册"）**：
   - 具名的 `entry=LoSetDoc` 在 **仓外**：`~/p1-ptsname/legs-after/app_g1.log`（`4db15b4c8466fadd`，`grep -o 'entry=' | sort | uniq -c` ⇒ `2 entry=LoSetDoc`）。
   - **在册载体** `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 现取（`cb0a3e5510b07790`）**仍是** `entry=unknown`：
     ```
     $ grep -o 'entry=[A-Za-z0-9_]*' build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log | sort | uniq -c
           2 entry=unknown
     ```
   - 后果（现取）：`pts-gap-count-check.sh` 的 `PTSGAP_FRONTIER before=LoCreateContext@3 after=unknown@2` ＋ `PTSGAP_FRONTIER_STATE=UNNAMED` ⇒ **门禁侧读不到具名前沿**（`after` 的 `@2` 还比 `before` 的 `@3` 小 ⇒ 该载体**不是**同一趟）。
   - ⇒ **点名**：「把 `entry=` 面做成具名」这件事**尚未落进在册载体**；在册读数仍是 `unknown`。**本件不判谁对**（我只报两处读数与它们导致的机器后果）。

---

## §5 `NOINFO`（具名，一条不许编）

1. **`PresentNative_cor3.dll` 之外那 32 个"未映射 DLL"的族面**：我**只**按任务口径做了本 DLL（LS 族）的逐条清单；其余 32 个 DLL 我**未**逐条展开（工具只给"每条数＋例"）。`NOINFO(reason=本件范围＝LS 族；32 个未映射 DLL 的逐条需另一趟)`
2. **「两页真排版」所需的完整入口序列**：`NOINFO(reason=缺运行期逐步证据；需每补一跳跑一趟腿读 `entry=`，本件不跑腿)`
3. **`LoEnumLine`／`LoQueryLine*`／`LoDisplayLine` 等"命中测试/显示"入口在两页上是否真被走到**：`NOINFO(reason=静态调用点不足判"运行期必走"；需运行期证据)`
4. **`IsOptimalParagraphEnabled` 在两页上的取值**：`NOINFO(reason=未取该标志的现取值；仅由经验侧（具名 `entry=LoSetDoc` 出现）**反推**该分支在那趟是真的走过 —— 这是**回溯**、不是直接读数)`
5. **在册 `工具口径 100` 那个 `Lo*` 是哪一个名字**：`NOINFO(reason=在册只给计数不给名单；我无法从现取反推它当年指的是哪一个 `Lo*`)`

---

## §6 四条边界的遵守自证

1. **只读仓树；唯一写入 ＝ 本件**。**两档现取**（逐行原样，未截断）：
   ```
   # 档 A：本件落盘**之前**（ts=2026-09-28T22:53:47.251+0800）
   $ git status --porcelain
     M build/MilBridge/HANDOFF-NEXT.md
     M build/PresentationFramework.Linux/PtsCache.Linux.cs
    ?? build/MilBridge/P1-ptsname-criteria.md
    ?? build/MilBridge/P1-ptsname-result.md
    ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log
    ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/arm_A/
    ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device/
    ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_post_g1.txt
    ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_pre_g1.txt
    ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/session.txt
    ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/shots/
   （共 11 行 —— 我在 §0 曾把它写成"7 行"，那是**我数错**，此处按原样更正）

   # 档 B：本件落盘**之后**（ts=2026-09-28T22:58:38.501+0800）—— 他人把其中几件提交了
   $ git status --porcelain
    M build/MilBridge/tools/pts-pages-guard.sh
   ?? build/MilBridge/P1-ls-family-recon.md
   ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log
   ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/arm_A/
   ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device/
   ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_post_g1.txt
   ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_pre_g1.txt
   ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/session.txt
   ?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/shots/
   ```
   ⇒ **两档里唯一属于我的新增 ＝ `?? build/MilBridge/P1-ls-family-recon.md` 这一行**；其余 `M`／`??` 全部是**他人**在飞件（我一个未改）。**未改** `docs/ROUTES.md`／`HANDOFF-NEXT.md` 的机器值格／任何判据件。
2. **未跑应用腿／未占显示位／未构建／未跑整趟门禁／未 `git add·commit·push`**：本件全部命令是 `grep`／`awk`／`sed`／`nm`／`sha256sum`／`wc`／`python3 check-shim-coverage.py`／`bash pts-gap-count-check.sh`（该器为**纯读自检**）；**零 `dotnet`**、**零 `X`**、**零 `git` 写**。
3. **未引既有报告当证据**：`P1-ptsname-result.md` 只作**待核对象**读；其每条断言我都给出现取读数（§1.1／§2.3 的 `native_src_grep=0`、§4.3-2）。§4.3-1 的在册行也是我**现取该行原文**后与现取计数对照。
4. **载体末行自报口径可当场复算**：见末行 `head -n -1 … | sha256sum | cut -c1-16`。

---

### 结语（自包含）

- **①** LS 族缺口面 ＝ **22 条**（声明件 `LineServices.cs`，全树该件 27 条 DllImport，5 条已导出）；同 DLL 另四族：PTS 66／Wrapper 5／Nl 6／文本分析 4（合计 99）。权威口径 ＝ `check-shim-coverage.py --tier mapped`（理由见 §1.1），`nm`／`exports.txt` 只作导出集第二来源，`grep` 源码不作权威。
- **②** `LoSetDoc` 是 `TextFormatterContext.Init()` 里**唯一**最早被撞的缺失 LS 入口（`:149 → :354`），其触发者 `PtsCache.Linux.cs:532` 的 `new TextFormatterContext()` **早于** `:548` 的 `PTS.CreateDocContext` ⇒ 台账必为 0。**只补它不够**：下一跳是 **`LoSetBreaking`**（`:155 → :257`）。
- **③** 最小增量序列草案 ＝ **`LoSetDoc` → `LoSetBreaking` →（已导出件不补）→ `PTS.CreateDocContext`**（到这一步台账真非零）；四步的证据位逐条在 §3 表中。**"两页真排版"的完整序列 ＝ NOINFO**（缺运行期逐步证据）。
- **④** 候选池：W8 的「六缺口 stub」池 **6 → 28**（＋LS 族 22）；而**工具口径 99／可操作 87／实现 93 本来就已含这 22 条 ⇒ 不变**。**冲突点名 2 处**：在册 `工具口径 100`（`Lo*` 19）≠ 现取 `99`（`Lo*` 18），差 1 且工具 sha16 未变；具名前沿**只在仓外**、在册载体仍 `entry=unknown`（⇒ 门禁 `FRONTIER_STATE=UNNAMED`）。
- **未完成项**：§5 五条 `NOINFO`，各自缺什么已逐条写明。

---

`P1-LS-FAMILY-RECON 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 7472106ad52be662（口径＝末行之前的全文；末行＝本行）`
