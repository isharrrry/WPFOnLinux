# T1 · MilCore 导出桥接 —— 报告（2026-09-10）

> ## 🔧 M7d 补丁 J ② 改接线（2026-09-11 下午，门禁解除后第 1 件）
>
> **改动**：`GetProviderFallbackFamily` 从 `new PhysicalFontFamily(_fontCollection[0])` 改为
> **T2 的公开 API** `MS.Internal.Text.TextInterface.Linux.DefaultFontFamily.SelectFamilyName(_fontCollection.LinuxCollection)`
> + `_fontCollection[name]`（**只用公开面，没有给 Provider 加新接口**）。
> 生成物 `build/PresentationCore.Linux/FamilyCollection.Linux.cs` 874 行、`sha256 8608db5e…`；
> 应用器 `sha256 db41fac2b40051f3…`；`--check` = 0、幂等 ✅、`-getItem:Compile` 求值：上游那条 **0 条** ✅、语法检查 **0 条 CS1xxx** ✅。
>
> **理由（主控 ① 要求 2 的漂移实测：同一个二进制、两种字体目录配置）**：
>
> | `WPF_LINUX_FONT_DIR` | 集合 FamilyCount | 旧 `_fontCollection[0]` | 新 `SelectFamilyName` |
> |---|---|---|---|
> | 只 `build/fonts` | 1 | `Noto Sans` | **`Noto Sans`**（reason=`preferred-list`） |
> | `build/fonts:/usr/share/fonts` | 166 | **`AR PL UKai CN`（楷体）** | **`Noto Sans`**（**一致**） |
>
> `Detail` 原文：`偏好序命中 Noto Sans（fontconfig sans-serif = Noto Sans CJK SC，仅作第二档）`
> ⇒ **默认 UI 字体不再随"扫到了哪些目录"变**（Windows 的默认 UI 字体也是固定族 Segoe UI）。
>
> **诚实回退（主控 ① 要求 1：不许静默退回 `[0]`）**：`Select` 内部已按 `collection.Entries` 保证候选来自本集合，
> 这里**仍然再验一次**；四条失败路径（集合 null / 集合空 / 选了但取不到 / 抛异常）**全部记数 + 打诊断**：
> ```
> WPF_LINUX_FONT_DIAG=1 ⇒ stderr: [FONT_DIAG] providerFallback: <原因> (hits=N misses=M)   # 前缀与 T2 诊断同款
> 反射读数（探针/复验）：MS.Internal.FontCache.FamilyCollection.ProviderFallbackDiagnostics
>        ⇒ "providerFallbackHits=N providerFallbackMisses=M"
> ```
> 取不到时**不静默**：先留痕（上面两条读数），再退到"集合第 0 个"这条**有痕的**兜底 ——
> "按档序取下一个候选"在现有公开面上做不到（偏好序表在 Provider 里是 private，而主控禁止加新公开面）。
> **将来若真需要"按档序取下一个"**：正确修法是**让 T2 的 `Select` 直接返回有序候选列表**（Provider 接口演进），
> **不是**让 PC 反射 Provider 的私有字段 —— 本补丁**没有留任何"以后反射一下"的钩子**。
>
> **⭐ 界线（主控要求写清，否则将来一定有人把它们当成一件事去修）**：
> · **本条 = PC 侧默认族**：决定"找不到族"时落到哪个族（`DefaultFontFamily`，实测两种配置都选 `Noto Sans`）；
> · **另一条 = 渲染器挂哪个面**：`MilPresentation.EnsureGlyphRenderer()` 目前只对齐目录、没对齐面（默认配置下文字整段不画，已登记 P0 派给 M7b）。
> 两条链**互不相干**：PC 侧选对了族，渲染器仍可能拿另一个面去光栅化（违反 handoff:1539"glyph id 必须与 WPF 侧同一份字体"）。**别混修。**
>
> **重建后这一条的预期**：`run.sh compositefont` 的 **S2 仍是"provider 回退"**，但在"只 build/fonts"下落到 `Noto Sans Regular`；
> 带上 `/usr/share/fonts` 时**同样**落到 `Noto Sans`（改之前会落到 `AR PL UKai CN`）。设 `WPF_LINUX_FONT_DIAG=1` 应看到
> 一行 `[FONT_DIAG] providerFallback: 默认族 = "Noto Sans" (hits=1 misses=0)`。

> # 🔬 B2 预检 · ICU(UAX#14) vs DWrite 行断对拍（73 例）（2026-09-11）
>
> **结论：②「不一致」—— 不能直接用 ICU。** 但差异**很小且可枚举**（2 类字符 + 2 条自叠规则），
> **不是"整个禁则表都要自己写"**：48 行 kinsoku 探针里的**禁则部分 40/40 与 ICU 一致**。
>
> 探针：`build/MilBridge/tests/IcuBreakParity/`（**不引用 PC**，只 P/Invoke `libicuuc.so.70` + 读 oracle JSON ⇒ 与 PC 重建无关）
> 一键：`bash build/MilBridge/run.sh icu`　存档：`build/MilBridge/gen/icu-break-parity.txt`（273 行，逐例明细）
> ICU 版本实测：`u_getVersion` = **70.1.0.0**
>
> | 段 | 方法 | 结果 |
> |---|---|---|
> | Stage 1（必要条件） | DWrite 的每个换行点必须 ∈ ICU 断点集 | 73 例中 **5 例不一致** |
> | Stage 2（充分性） | 用 ICU 断点集 + 贪心填宽（全角 advance = 逐例 `emSizeDip`，实测 24/11 两种）重算行划分，逐行对拍 | 纯 CJK 可用 59 例：**58 例逐行全等**、**3 例不同**（2 真差异 + 1 记账口径） |
> | Stage 3（禁则 crux） | 48 行 kinsoku 表逐字符：ICU 是否允许"把标点留到行首/行尾"的那个断点 | **禁则 40/40 一致、对照 2/2 一致、不一致 0** |
>
> ---
>
> ## ⭐ 好消息：UAX#14 确实编码了你担心的那些字符
>
> 31 个"行首禁则"探针**全部**与 ICU 一致 —— 包含 `・`(U+30FB)、`ー`(U+30FC)、`々`(U+3005)、
> **小假名 9 个**（`ぁぃぅぇぉっゃゅょ`）、`…`、`‐`，以及 9 个"行尾禁则"（`（［｛「『【《〈〔`）**全部**一致。
> 对照探针 `甲` 两个方向都 allowed ⇒ 探针构造有效（不是"把所有字符都判禁"）。
>
> ## ❌ 真差异 1：`…`(U+2026) —— DWrite 允许在它**之前**断，UAX#14 禁止
>
> `cjk-fullwidth`（`全角标点：，。！？；：「」（）【】《》——……`，w=160，em=24）：
> ```
> DWrite  : [0,3) [3,9) [9,15) [15,21) [21,23)
> ICU 贪心: [0,3) [3,9) [9,15) [15,19) [19,23)     ← 只差最后一行：21 vs 19
> ```
> UAX#14 把 `…` 归 **IN**（前后都不可断），DWrite 允许在它前断 ⇒ ICU 提前 2 字断。
> 附带发现：DWrite 会把**整段标点**下移（行 1 只有 3 字 `全角标`，把 `点：，。！？` 整段留到下一行），
> 而 ICU 的断点集在 3..11 之间**一个断点都没有** ⇒ 贪心**恰好**复现了这个行为（`[0,3)` 全等）—— 这条不用自己写。
>
> ## ❌ 真差异 2：`“`(U+201C) —— ICU 允许在它之前断，DWrite 把它**连同前一个字**一起拉下来
>
> `kinsoku-end-“`（`甲乙丙丁戊己“辛壬癸子丑寅卯辰`，w=168 = 7 个全角）：
> ```
> DWrite  : [0,5) [5,12) [12,15)      ← 行 1 = 5 字（己 与 “ 一起下移）
> ICU 贪心: [0,6) [6,13) [13,15)      ← 行 1 = 6 字 ⇒ “ 到了行首
> ```
> 实测的不对称：ICU 对 `“`(U+201C) **允许**在其前断、对 `‘`(U+2018) **禁止** ⇒ 两个引号在 UAX#14 里不同类。
> ⇒ 至少要给 `“` 补一条"其前不可断"（与 `‘` 对齐），DWrite 的"拉前一个字"才复现。
>
> ## ⚠️ 另外 3 处 Stage-1 不一致：是**紧急断行**，不是 ICU 缺陷
>
> | 例 | DWrite | ICU | 性质 |
> |---|---|---|---|
> | `en-oneword` | 单词内逐字符断 | 整串只有一个断点 | 无断点可用 ⇒ 按字符强制断（B2 用不用 ICU 都要做；探针的贪心 fallback 已复现） |
> | `cjk-long-token` | 字符级强制断开 | 只有部分位置可断 | 同上 |
> | `kinsoku-conflict-1char`(w=24) / `-2char`(w=48) | **放弃禁则**、正常断行 | 仍禁止 | ⭐ **同一条 fallback 恰好复现**（Stage 2 这两例**逐行全等**）⇒ "容器窄到放不下就放弃禁则"**不需要单独写规则** |
>
> ## 记账口径（不是 ICU 的差异，但 B2 必须按 DWrite 来）
>
> `cjk-newlines`：DWrite 的行区间**不含**换行符（`lengthWithNewline` / `newlineLength` 分开给），空行产出**零长度行** `[8,8)`；
> 探针把 `\n` 算进了区间 ⇒ 只有这一例"不同"。**这是探针的记账，不是 ICU 的错。**
>
> ## 附带实测（回答 U1 没测的那一项）
>
> `ubrk_open` 的 status：`zh-CN` = **-128（U_USING_FALLBACK_WARNING）**、`en-US` = **-127（U_USING_DEFAULT_WARNING）**
> ⇒ ICU **没有 zh-CN 专属断行数据，用的是 root 规则** ⇒ 与你的结论一致：**断行点集与 locale 无关**（两种 locale 逐例断点集相同）。
> （ICU 里 locale 影响断行的例外只有泰/老/高棉/缅甸的词典断行，不在本语料内。）
>
> ## 对 B2 的意义（建议，供你定夺）
>
> B2 断行器 = **ICU 断点集 + 贪心填宽 + 2~3 条自叠规则**：
> 1. **无断点可放 ⇒ 按字符强制断**（同时自动实现"禁则放弃"，实测两例全等）；
> 2. **`…`(U+2026) 前允许断**（覆盖 UAX#14 的 IN 类）；
> 3. **`“`(U+201C) 前禁止断**（= 与 `‘` 对齐，复现"拉前一个字"）。
>
> 再加上行区间/空行/硬断的口径。⇒ **禁则表不用自己写**（40/40 已由 ICU 覆盖），
> 量级仍是"贪心 + 断点集"，但**回归必须钉在这 73 例上**（目前 58/59 纯 CJK 例逐行全等，差的那 1 例就是 `…`）。

> # 🔤 M7d · 复合字体短路（PRESENTATIONCORE 补丁 J）+ `GlyphTypeface(Uri)` 诚实失败（追加 1）（2026-09-11）
>
> **一句话**：非 Windows 上**不再解析系统复合字体**（连 `LoadXml` 都不执行），
> 并把"系统回退族"这一层**交给 provider**；`new GlyphTypeface(new Uri(ttf))` 由 NRE 变成**诚实的 `FileFormatException`**。
> Windows 分支逐字不变；**没有**碰 OS 版本；**没有**伪造任何空面。
>
> | 交付物 | 状态 |
> |---|---|
> | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py` | **新增（唯一新增文件）** `sha256 24ee0400…` |
> | `build/PresentationCore.Linux/FamilyCollection.Linux.cs` | 生成物（上游 681 行 → 782 行）`sha256 1d99d32b…` |
> | `build/PresentationCore.Linux/PresentationCore.Linux.csproj` | 只加了 `Remove` + `Include` 两行 `sha256 6506e67a…` |
> | `build/shims/PresentationCore.Factory.Linux.cs` | 追加 1：能力探测守卫（424 行）`sha256 125cfaa3…` |
> | `build/MilBridge/tests/CompositeFontProbe/` | 验收探针（同一份程序，重建前后各跑一次） |
> | `build/MilBridge/gen/compositefont-before.txt` | 重建**前**的实测输出（PC.dll `sha256 5c8406d6…`） |
> | `build/MilBridge/gen/compositefont-simulated-shortcircuit.txt` | 只做①不做②的对照（见 §3） |
> | `bash build/MilBridge/run.sh compositefont` | 一键复现（含接线求值 + 探针 + 对照） |
>
> **`build/PresentationCore.Linux/` 下既有生成物一个没动**（`FontCacheUtil.Linux.cs`/`SecurityHelper.Linux.cs`/… 的 Compile 项实测都在，见 §5）。
> **没有重建 PC**（留给集成波）。
>
> ---
>
> ## 0. 结论先行（三条，都需要你裁决/复验的已标 ⚠️）
>
> 1. **短路点确实是唯一咽喉**：4 个系统复合字体的**加载**只有 `GetCompositeFontFamilyAtIndex` 一个入口
>    （`FindFamily` / `GetFallbackFontForArabicLegacyFonts` / `GetFontFamilies` 枚举 / `FamilyCount` 间接）。
> 2. ⚠️ **只做短路会把异常"换个地方冒"** —— 我实测出来了：`FindFamily` 全 null 之后，
>    `Typeface.ConstructCachedTypeface` 会走到 `firstFontFamily.GetTypefaceMetrics(...)`（`Typeface.cs:786`）
>    **解引用 null** ⇒ NRE。**这条链上"诚实失败"被堵死**：`CachedTypeface` 的构造有
>    `Invariant.Assert(firstFontFamily != null && typefaceMetrics != null)`（`CachedTypeface.cs:42`），
>    Debug 构建里传 null = 断言炸进程。⇒ 必须再做 ②：把"系统回退族"这个名字**交给 provider**
>    （返回 provider 首个可用族 = 真字体，不是造的族、不是空的族）。实测：`FindFamily` 全 null 时
>    S2 = **NRE**；加上 ② 的成分（S8 实测拿到了真 `GlyphTypeface`）后 S2 = **provider 回退**。
> 3. ⚠️ **4 个复合字体里只有 `GlobalUserInterface` 会抛**（3 个实测能加载）；短路是"4 个都不加载"，
>    所以代价比"丢掉 GlobalUserInterface 回退链"**多**了那 3 个 —— 但那 3 个今天也**全部不可达**
>    （唯一入口 `Fonts.SystemFontFamilies` 枚举在第 0 个上就抛了；只剩显式写 `FontFamily="Global Monospace"` 这一种用法）。
>
> ---
>
> ## 1. 根因（实测，非推断）
>
> `GlobalUserInterface.CompositeFont` 是 4 个里**唯一**根元素为 `<FontFamilyCollection>` 的，带 4 个 OS 段：
>
> | 资源 | 根元素 | OS 段数 | 本移植上 |
> |---|---|---|---|
> | `GlobalUserInterface.CompositeFont` | `<FontFamilyCollection>` | **4**（`Windows10RS5` / `Windows10RS1` / `Windows10` / `WindowsXPSP2`） | **抛** |
> | `GlobalMonospace` / `GlobalSansSerif` / `GlobalSerif` | `<FontFamily>` | 0 | **能加载**（实测） |
>
> `CompositeFontParser.ParseFontFamilyCollectionElement`（`:324`）按 `OS` 属性挑段
> → `OSVersionHelper.IsOsVersionOrGreater` 一律 false（`DeviceFamily`/`IsWindows*` 全 false，**这是诚实的**）
> → 一段都挑不中 → `Fail(...)` 而 Fail 的消息要 `OSVersionHelper.GetOsVersion().ToString()`（`:344`）→ **抛**。
>
> **❌ 为什么禁做"伪造 OS 版本"（本补丁一个字节都没碰它）**：
> `OS` 属性挑的是**平台专属的族链表** —— 4 段里写的是 Windows 装的字体名（Segoe UI / Microsoft YaHei…）。
> 谎报版本 = 以造假换安静，且会把"Linux 上没有这些字体"这件事掩盖掉。
>
> 触发入口不是"某个特定族名"，而是**任何找不到的族名**：
>
> ```
> new FontFamily("Arial")               canonical 名 = ARIAL（1 token，实测 dump）
> new Typeface(family, Normal×3)        兜底族 = FontFamily.FontFamilyGlobalUI
>                                       （FontFamily.cs:40 "#GLOBAL USER INTERFACE"）
> TryGetGlyphTypeface
>   → Typeface.ConstructCachedTypeface              Typeface.cs:755（= FallbackFontFamily 分支）
>   → "#GLOBAL USER INTERFACE".FindFirstFontFamilyAndFace   FontFamily.cs:455
>   → LookupFontFamilyAndFace                       FontFamily.cs:511
>   → FamilyCollection.LookupFamily                 FamilyCollection.cs:340
>   → SystemCompositeFonts.FindFamily               FamilyCollection.cs:221 → index 0
>   → GetCompositeFontFamilyAtIndex(0)              FamilyCollection.cs:242
>   → CompositeFontParser.LoadXml → ParseFontFamilyCollectionElement  :344
>   → OSVersionHelper.GetOsVersion()                ❌ 抛
> ```
>
> 探针 S2b 的逐名对照（`SystemCompositeFonts.FindFamily` 直接反射调用）：
> `Arial`→null、`Noto Sans`→null、**`Global User Interface`→抛**、`Global Monospace/Sans Serif/Serif`→**已加载**。
>
> ---
>
> ## 2. 修法：7 处修改（都在同一个文件里，同一套机制）
>
> | # | 位置 | 改动 | 不做会怎样（实测/结构性） |
> |---|---|---|---|
> | ① | `GetCompositeFontFamilyAtIndex`（:230） | 非 Windows ⇒ 方法体最前面 `return null` | 就是根因本身 |
> | ② | `LookupFamily`（:338） | 名字命中系统复合字体但没拿到族 ⇒ 非 Windows 返回 **provider 首个可用族** | **NRE**（`Typeface.cs:786`，见 §3） |
> | ③ | `GetFontFamilies` 枚举（:626） | `GetCompositeFontFamilyAtIndex(j)` 结果加 null 守卫 `continue` | **NRE**（`CreateFontFamily` 无 null 守卫，`Fonts.SystemFontFamilies` 在 Window 静态构造链上） |
> | ④ | `FamilyCount`（:675） | 非 Windows 且 `UseSystemFonts` ⇒ 不 +4 | 计数比枚举多 4 ⇒ `GetFontFamilies` 预分配数组尾部 4 个 null + `Debug.Assert(i == FamilyCount)` 失败 |
> | ⑤ | `SystemCompositeFonts.FindFamily`（:216） | 返回类型 `CompositeFontFamily` → `IFontFamily`（② 要返回 `PhysicalFontFamily`） | 编译不过 |
> | ⑥ | 新增 `SystemCompositeFonts.IsSystemCompositeFontName` | ② 的判定 | 编译不过 |
> | ⑦ | 新增 `FamilyCollection.GetProviderFallbackFamily` | `new PhysicalFontFamily(_fontCollection[0])`，空集合返回 null | 编译不过 |
>
> **② 的语义**（这是本次唯一"策略性"的决定，请过目）：
> `#GLOBAL USER INTERFACE` 在上游的角色就是**"找不到字体时的兜底入口"**（`Typeface` 4 参构造把它当 `FallbackFontFamily`），
> Windows 上它落到 GlobalUI 的字体映射（最差也是 Arial，因为 `NullFontFamilyCanonicalName = "#ARIAL"` 兜底）。
> 本移植上这一层改成"**provider 的首个可用族**"，理由是**上游契约不允许这一层返回 null**（§0.2 实测 + `CachedTypeface` 断言）。
> 判定的依据（实测）：`DWriteFactory.GetFontCollectionFromFile` 走的是 provider 集合，`GetFontFromFontFace` 才做族定位；
> ② 只在**名字命中 4 个系统复合字体**时触发 ⇒ 用户写的 `"NoSuchFont, Noto Sans"` 这种逗号回退链**不受影响**（token 语义原样保留）。
>
> **⚠️ ② 的已知粗糙点**：`_fontCollection[0]` 是"provider 族序的第一个"，实测依赖扫到的目录：
>
> | `WPF_LINUX_FONT_DIR` | `FamilyCount` | `[0]` | ② 之后 `FontFamily("Arial")` 落到 |
> |---|---|---|---|
> | 只有 `build/fonts` | 1 | **Noto Sans** | Noto Sans Regular（`GlyphCount=3884 Version=2.015`，= 基线面） |
> | `build/fonts:/usr/share/fonts` | 166 | AR PL UKai CN | AR PL UKai CN（楷体，拉丁字形不理想） |
> | 只有 `/usr/share/fonts` | 165 | AR PL UKai CN | 同上 |
>
> 想要"合理的默认族"需要 provider 侧提供一个 default-family 出口（T2）或查 fontconfig 别名 —— 都不在本轮授权内。
> **若你要的是"诚实失败"而不是"provider 回退"，那必须先松开 `CachedTypeface.cs:42` 的 `Invariant.Assert`（= 再动一个上游文件）。**
> 探针的 `run.sh compositefont` 刻意**只给 `build/fonts`**，所以复现是确定的（`[0]` = Noto Sans）。
>
> ---
>
> ## 3. ⭐ 短路前后调用序列对照（证明是"短路"，不是"异常换地方冒"）
>
> 方法：**同一份探针**（`tests/CompositeFontProbe`）在"未打补丁的 PC"上跑 = BEFORE；
> 用 `--simulate-shortcircuit`（把 `SystemCompositeFonts._systemCompositeFontsNames` 清空 ⇒ `FindFamily` 一律 null，
> **仅进程内、磁盘未改**）跑 = 只做①的效果。输出存档见 §交付物两处。
>
> | 步骤 | BEFORE（实测） | 只做 ①（实测） | ①+②（成分实测 + 上游代码路径） |
> |---|---|---|---|
> | `FindFamily("GLOBAL USER INTERFACE")` | **抛 OSVersionHelper** | `null`（**不执行 LoadXml**） | `null`（同左） |
> | `LookupFamily` 返回 | 不返回 | `null` | **`PhysicalFontFamily(provider[0])`** |
> | `firstFontFamily` | 不返回 | `null` | 非 null |
> | `firstFontFamily.GetTypefaceMetrics(Normal)` | 不返回 | **NRE**（`Typeface.cs:786`） | `GlyphTypeface`（S8 实测 `[0]`=Noto Sans ⇒ 3884/2.015） |
> | `TryGetGlyphTypeface` | **抛 OSVersionHelper** | **抛 NRE** ← 换地方冒 | **`true`（provider 回退）** |
> | `Fonts.SystemFontFamilies` | `TypeInitializationException`（内层 OSVersionHelper） | —（模拟不覆盖枚举） | 枚举 `_fontCollection.FamilyCount` 个、无 null（③④ 保证） |
>
> **机械证据**：生成物里的 `throw` 条数与上游**逐字相同（1 == 1）**，脚本每次断言 ⇒ 没有新增/搬运异常；
> 代码行差异只有 §2 那 7 处（`diff` 见脚本 `--check` 输出）。
>
> ---
>
> ## 4. 验收矩阵
>
> | # | 判据 | BEFORE（实测，PC=`5c8406d6…`） | 重建后**应当**看到 |
> |---|---|---|---|
> | ① | `FontFamily("Noto Sans")`→`Typeface`→`TryGetGlyphTypeface` | **已经 PASS**：`GlyphCount=3884 Version=2.015 Baseline=1.069 Height=1.362 CharToGlyph=2965` | **不变**（逐项相同） |
> | ② | `FontFamily("Arial")` 不抛 OSVersionHelper | **FAIL**：抛（栈见 §1） | **PASS**：`TryGetGlyphTypeface=true`，落到 provider 首个族 = **Noto Sans Regular**（"provider 回退"，不是诚实失败 —— 理由见 §0.2） |
> | ③ | 私有字体 URI `new FontFamily(baseUri, "./NotoSans-Regular.ttf#Noto Sans")` | **已经 PASS**（不走复合字体） | **不变** |
> | ④ | `MS.Internal.FontCache.Util.Dpi` / `WindowsFontsUriObject`（补丁 I 的回归面） | **PASS**：`Dpi=96`、`file:///usr/share/fonts/` | **不变** |
> | ④′ | `Fonts.SystemFontFamilies` 枚举 | **FAIL**：`TypeInitializationException` ← OSVersionHelper | **PASS**：枚举出真族、**无 null 元素**（这条同时压 ③④） |
> | ⑤ | `SystemFonts.MessageFontFamily` / HelloWpf | 本轮**不跑**（你禁止） | 由你在集成波复验；我给了等价面 `Fonts.SystemFontFamilies` + `Util.Dpi`（`Window` 静态构造链上的两步） |
> | 追加1 | `new GlyphTypeface(new Uri(ttf))` | **FAIL**：`NullReferenceException`（`FontFaceLayoutInfo.cs:642 ← :70 ← GlyphTypeface.cs:150`） | **PASS**：`FileFormatException`（诚实） |
>
> ---
>
> ## 5. 接线（不读 XML，用求值）
>
> ```
> python3 …/patch-presentationcore-compositefont.py --check      → 退出码 0（生成物最新 + csproj 已接线）
> python3 …/patch-presentationcore-compositefont.py              → 幂等：两个文件字节不变（sha256 实测）
> 锚点不符/缺失 → **报错退出 1**（用 /tmp 里的变异上游实测两例：改名锚点、删锚点 → 都退出 1）
>
> dotnet msbuild build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 --nologo \
>     -getItem:Compile -p:Configuration=Debug | grep -i FamilyCollection
>   → 上游 …/MS/internal/FontCache/FamilyCollection.cs        **0 条**（被 Remove 掉）✅
>   → build/PresentationCore.Linux/FamilyCollection.Linux.cs  **在**（Identity+FullPath 2 条）✅
>   → 既有生成物 FontCacheUtil.Linux.cs / SecurityHelper.Linux.cs / InputManager.Linux.cs /
>     OleServicesContext.Linux.cs / StylusLogic.Linux.cs / TextCompositionManager.Linux.cs /
>     WispTabletDeviceCollection.Linux.cs **全部仍在** ✅（一个没动）
> ```
>
> 两个接线坑都按你说的处理：整块（含 `<ItemGroup>`）插在 `  <Import Project="Sdk.targets" …/>` **行之前**（不会嵌套 ⇒ 不会 MSB4232）；
> `Remove` 落在上游 `Include`（csproj:1241）**之后** ⇒ 文档顺序正确。
>
> **⚠️ 集成波需要加一行**（`integration-wave.sh` 不在我的授权内，所以只在此登记）：
> 在 `patch-presentationcore-fontcache.py`（补丁 I）之后追加
> `python3 "$ROOT/src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py"`。
> **不加也能重建**（生成物已在树里、csproj 已接线），加了才有"重放 + 校验"能力。
>
> ---
>
> ## 6. 追加 1：`GlyphTypeface(Uri)` 的诚实失败（`build/shims/PresentationCore.Factory.Linux.cs`）
>
> **根因（实测）**：上游 `GlyphTypeface.Initialize` 拿面之后必定走
> `DWriteFactory.GetFontCollectionFromFile(uri).GetFontFromFontFace(face)`，而本移植上
> "面"是 `LinuxFontFace.FromFile` 单独造的、"集合"是 `LinuxFontCollection.FromDirectory` 另造的，
> provider 的反查按 **`SKTypeface` 引用相等**匹配（`LinuxFontCollection.cs:443`）⇒ **必然 null**
> ⇒ 由 `ManagedSurface.cs:714 Require.GetFontFace()` 的 null 一路传到 `FontFaceLayoutInfo.IntMap`（:642）才爆 NRE。
>
> **探针 S7 用真上游链量了同一个判据**（反射调 `DWriteFactory.GetFontCollectionFromFile` + DWF `GetFontFromFontFace`）：
>
> ```
> FromFile(path) 两次是否同一个 SKTypeface 实例 : False
> FromDirectory(parent).GetFontFromFontFace(FromFile(path)) = **null**
> 真链 GetFontFromFontFace(face) = **null**
> ⇒ 守卫判据 CanRoundTripFace = false ⇒ CreateFontFace 返回 null ⇒ 上游抛 FileFormatException
> ```
>
> **改法（4 行有效代码 + 长注释）**：`CreateFontFace(Uri, uint, FontSimulations)` 本地文件分支里，
> 造出面之后做一次**能力探测** `CanRoundTripFace(uri, linuxFace)`：
> 用**同一个** `DWriteFactory.GetFontCollectionFromFile` 拿集合，再问 provider"这个面能回到它所属的 Font 吗"
> （等价于 DWF `FontCollection.GetFontFromFontFace` 的判据，见 `ManagedSurface.cs:883`）。
> 返回 false ⇒ `return null` ⇒ **触发上游既有守卫**（`GlyphTypeface.cs:140-143`）⇒ `FileFormatException`。
> **没有伪造空面**：探测是在真实 provider 状态上问的（判据实测 = null）；将来 provider 这条反查能对上（例如共享 SKTypeface 缓存），
> 守卫**自动放行**，这里一个字都不用改。
>
> ---
>
> ## 7. 我重建后应当看到什么（请照单复验）
>
> 1. `bash build/MilBridge/run.sh compositefont` → **`=== 通过 6 / 失败 0 ===`、探针退出码 0**
>    （S1 3884/2.015；**S2 PASS = provider 回退到 Noto Sans**；S3/S4 PASS；**S5 枚举出真族、0 个 null**；
>     **S6 = `FileFormatException`**；S2b 六个名字**全 null**、无异常；S7/S8 是取证项）。
> 2. 同样的命令输出里，PC.dll 的 `sha256` **不再是 `5c8406d6…`**（新构建）—— 用它区分前后两份存档。
> 3. `dotnet msbuild … -getItem:Compile` → 上游 `FamilyCollection.cs` **0 条**、生成物在、既有生成物都在（§5）。
> 4. 编译期风险已静态排除（我**没有**重建 PC，所以这一条是"消掉已知的编译风险"，不是"编过了"）：
>    `global using System;`（上游 `GlobalUsings.cs`，实测在 Compile 项里）⇒ `OperatingSystem.IsWindows()` 可用；
>    `NumOfSystemCompositeFonts` 仍是 `const`（:675 的三元式依赖常量表达式）；
>    `_fontCollection[0]` 用的是上游已在用的 uint 索引器（`FamilyCollection.cs:552` 同款）；
>    `PhysicalFontFamily(Text.TextInterface.FontFamily)` 是既有 internal ctor（`PhysicalFontFamily.cs:57`）；
>    DWF 对 PC 有 `InternalsVisibleTo`（`build/DirectWriteForwarder.Linux/AssemblyAttrs.cs:13`）⇒ `collection.LinuxCollection` 可见；
>    `build/shims/PresentationCore.Factory.Linux.cs` 单独送 `csc` 做**语法检查**：只有 CS0246/CS0234（缺引用，预期），**0 条语法错**。
>    生成物 `FamilyCollection.Linux.cs` 同样单独送 `csc`：**0 条 CS1xxx 语法错**（其余 CS0246/CS0308/CS0234/CS0540/CS0538 全是"缺引用导致类型解析不到"的连带）。
> 5. ✅ 复验后如果 ①②③④′ 全 PASS，请把 `build/MilBridge/gen/compositefont-before.txt` 与新的输出一起留档 —— 那就是"短路前后"的完整对照。
>
> **登记（未实现 + 恢复条件）**：系统复合字体解析在 Linux 上**未实现**（回退由 provider 承担）。
> 恢复条件 = 有人把 `GlobalUserInterface.CompositeFont` 的 4 个 OS 段**按 Linux 自己的字体栈重写**（而不是谎报 OS 版本），
> 或 provider 提供一个 default-family 出口让 ② 有更好的落点。

> # 🧱 轨道A/B1 · `TextLine` 落地脚手架（2026-09-10 晚）
>
> **一句话**：把原型按 `build/shims/` 机制**编译进 PresentationCore**，把反射换成**直构**，
> 把 9 个欠账从"抛异常"改成**安全回退 + 命中计数**，加 env 开关（**默认关**）。
> **本轮不接线**（没动 PC 的选路逻辑），所以它是**惰性**的。
>
> | 项 | 结果 |
> |---|---|
> | 验证 | **9 / 9 通过**（`bash build/MilBridge/run.sh textline`） |
> | 验证的是**真 shim 源文件**本身 | ✅ 不是副本 —— `TextLineProto.csproj` 直接 `<Compile Include>` 了 `build/shims/PresentationCore.HbTextLine.cs` |
> | 行为与原型**逐项相同** | ✅ 37 字形 / 宽 493.4880 / advance 逐项相等 / **PNG 都是 4722 字节、3954 非白像素** |
> | OFF 时零影响 | ✅ **结构性惰性**（PC 侧零调用点，见 §4） |
>
> ---
>
> ## 1. 反射 → 直构（唯一差别点）
>
> | 原来（原型） | 现在（编进 PC） |
> |---|---|
> | `TextBounds` 反射调 internal ctor | `#if TEXTLINE_SHIM_DIRECT` → **`new TextBounds(r, dir, runs)`** |
> | `TextRunBounds` 反射调 internal ctor | 同分支 → **`new TextRunBounds(r, cpFirst, cpEnd, run)`** |
> | `GlyphTypeface(Font)` 反射 | **不再需要** —— 落地形态由调用方直接传 `GlyphTypeface`（构造函数签名就是它） |
>
> **同一个源文件编两次**（`TEXTLINE_SHIM_DIRECT` 定/不定义），两种模式**只有"怎么拿到 `TextBounds`"这一点不同**，
> shaping → glyph/advance/度量 → `GlyphRun` 主链路逐字相同。所以"换方式后行为不变"是**可证**的：
> 同一串文本喂同一条链路，输出逐项相等 —— 实测见 §3。
>
> **直构分支的签名已按上游原文核对**（`TextBounds.cs:23` / `:77`）：
> ```
> internal TextBounds(Rect bounds, FlowDirection flowDirection, IList<TextRunBounds> runBounds)
> internal TextRunBounds(Rect bounds, int cpFirst, int cpEnd, TextRun textRun)
> ```
> ⚠️ 该分支**只有编进 PC 才能编译**（internal 可见性），所以它在本次验证里**没有被编译过** ——
> 见 §5「需要主控重建 PC 后复验的四件事」。
>
> ---
>
> ## 2. ⭐ 9 个欠账：**安全回退，不抛**
>
> | override | 回退值 | 单行/不裁剪语义下是否说得通 |
> |---|---|---|
> | `GetTextLineBreak` | **`null`** | ✅ "这一行之后没有换行、也没有更多内容" —— 对不含 `\n` 的单行文本是**正确**答案 |
> | `GetTextCollapsedRanges` | 空列表 | ✅ "没有折叠" |
> | `Collapse(...)` | `this` | ✅ 接受折叠参数但不折叠 |
> | `GetIndexedGlyphRuns` | 空序列 | ⚠️ 渲染后端本轮不该依赖它（**而全上游 0 个调用点**，见 §6） |
> | 光标/命中 5 个 | `CharacterHit(0,0)` / `0.0` / 原样返回 | ⚠️ 安全但**语义不正确**，属 B3 |
>
> **为什么不能抛**：`GetTextLineBreak` 在欠账里，而 WPF **换行时会调它**
> （`PtsHost/TextParagraph.cs`、`FormattedText.cs`、`TextBlock.cs`…，见 §6）——
> 抛出去 = **一换行就崩**；回退 = 降级但可用。产品上是天壤之别。
>
> **严格模式**：`WPF_LINUX_TEXTLINE_STRICT=1` 时改为抛 —— bring-up 期定位用（实测 A8 通过）。
>
> **计数器可被测试读到**（不是只打日志）：`HbTextLineScaffold` 是 **public**，
> 暴露 `HitCount(member)` / `TotalFallbackHits` / `SummaryLine()`；
> 并支持 `WPF_LINUX_TEXTLINE_DUMP=<path>` 在**进程退出时**把汇总写盘 —— 这正是"跑 HelloWpf 取数"要用的口子。
>
> ---
>
> ## 3. 实测（`run.sh textline`，9/9）
>
> ```
> A1 真 GlyphTypeface（GlyphCount=3884）
> A2 GetTextRunSpans → 1 span / 长度 41
> A3 GetTextBounds → 真 TextBounds，矩形宽 493.4880 == TextLine.Width
> A4 Draw null 守卫正确
> A5 GlyphRun 与 HarfBuzz 直算逐项相等（37 个字形、advance 1e-9）
> A6 光栅化 → 非白像素 3954 / 51200（7.72%），PNG 4722 字节
> A7 **9 个欠账全部安全回退、0 个抛**，各自命中计数 = 1（总计 9/9）
> A8 严格模式下确实会抛（定位用）
> A9 开关 WPF_LINUX_TEXTLINE 未设时为关
> == 通过 9 / 失败 0 ==
>
> [汇总行] HB_TEXTLINE enabled=0 lines=0 draw=0 getTextBounds=0 getTextRunSpans=0 fallbackTotal=10
>          Collapse=1 GetBackspaceCaretCharacterHit=1 GetCharacterHitFromDistance=1
>          GetDistanceFromCharacterHit=1 GetIndexedGlyphRuns=1 GetNextCaretCharacterHit=1
>          GetPreviousCaretCharacterHit=1 GetTextCollapsedRanges=1 GetTextLineBreak=2
> ```
>
> **与原型逐项相同**（这就是"换方式后行为不变"的对照）：
> | 量 | 原型（反射版，其自身文件） | 现在（**真 shim 源文件**，反射分支） |
> |---|---|---|
> | 字形数 | 37 | **37** |
> | `TextLine.Width` | 493.4880 | **493.4880** |
> | `Height` / `Baseline` | 32.6880 / 25.6560 | **32.6880 / 25.6560** |
> | advance 与 HB 直算 | 逐项相等 | **逐项相等** |
> | 光栅化非白像素 / PNG | 3954 / 4722 B | **3954 / 4722 B** |
>
> ---
>
> ## 4. OFF ⇒ 零影响（证据）
>
> 1. **结构性惰性**：新文件只**新增类型**，**PC 侧零调用点** ——
>    实测 `grep -rn "HbTextLine|HbShaper|WpfLinux.Shims.PresentationCore"` 在整个
>    `PresentationCore.csproj` / `upstream/**.cs` 上**只命中 shims.txt 的登记行本身**，没有任何调用。
> 2. 唯一入口是 `WPF_LINUX_TEXTLINE`，而在接线落地前**没有任何代码读它**。
> 3. 开关解析口径：**未设 / 认不出来 ⇒ 关**（实测 A9）。
> 4. ⚠️ **本轮没有跑 HelloWpf**：按主控要求"本轮不改选路逻辑"⇒ HelloWpf **不可能构造出 `HbTextLine`**，
>    跑一次只能得到全 0 的计数器，**测不出 B2/B3 的优先级**，反而有和 M7b 抢 `:99` 的风险。
>    ⇒ 该项实测**留给接线后的集成波**（过程见 §7）。
>
> ---
>
> ## 5. 需要主控重建 PC 后复验的四件事
>
> 1. **直构分支能编译**：`#if TEXTLINE_SHIM_DIRECT` 那一支从未被编译过（internal 可见性只有 PC 里有）。
>    若编译报错，最可能是 `TextBounds`/`TextRunBounds` 的 ctor 签名与 §1 抄的不一致 —— 按上游原文改即可。
> 2. **直构分支行为与反射分支相同**：重建后跑 `run.sh textline`（把 `TextLineProto.csproj` 加上
>    `-p:DefineConstants=TEXTLINE_SHIM_DIRECT`），应看到 **A1–A9 完全相同**，尤其
>    **字形 37 / Width 493.4880 / 非白像素 3954**。
> 3. **PC 编译面没有回归**：新文件进了 `PresentationCore.shims.txt`，下次 `port-lib.py` 会把它编进 PC。
>    预期 **0 错 0 警**；若撞名，只可能是 `WpfLinux.Shims.PresentationCore` 命名空间冲突（当前无）。
> 4. **既有 742 用例逐项不变**：开关默认关 + 零调用点 ⇒ 应当**逐字不变**。
>
> ---
>
> ## 6. ⭐ 欠账命中次数的**优先级**：静态调用点普查（比估计硬）
>
> 全上游（PC + PF + UIAutomation）对这 9 个成员**在 `TextLine` 上的调用点**：
>
> | override | 调用点 | 主要调用者 | 优先级 |
> |---|---|---|---|
> | **`GetTextLineBreak`** | **9** | `PtsHost/TextParagraph.cs`(2)、**`FormattedText.cs`(2)**、**`TextBlock.cs`(1)**、`Text/Line.cs`、`PtsHost.cs` | **B2 第一优先（就是"换行"本身）** |
> | `Collapse` | 12 | `Text/Line.cs`(6)、`PtsHost/Line.cs`(6) | B2（PF 排版引擎，任何带 Trim 的 TextBlock） |
> | `GetCharacterHitFromDistance` | 9 | `PtsHost/Line.cs`(4)、`Text/Line.cs`(2)、`ComplexLine.cs`(2)、`TextBoxLine.cs` | B3（命中测试/光标） |
> | caret 家族 4 个 | 7–8 各 | `Line.cs` / `ComplexLine.cs` / `TextBoxLine.cs` | B3 |
> | `GetTextCollapsedRanges` | 2 | `Text/Line.cs`、`PtsHost/Line.cs` | B2（与 `Collapse` 同行） |
> | **`GetIndexedGlyphRuns`** | **0** | **全上游没有任何调用点** | **可以砍掉/降级** —— 这条与"B2 要做它"的直觉相反，值得记一笔 |
>
> **结论**：B2 的真实内容是 **`GetTextLineBreak` + `Collapse` + `GetTextCollapsedRanges`**（换行与折叠），
> **不是** `GetIndexedGlyphRuns`（零调用者）。B3 是光标/命中家族。
>
> > ⚠️ 诚实标注：这是**静态调用点普查**（`upstream/` 源码），**不是运行期命中次数**。
> > 运行期数字要等接线：见 §7。
>
> ---
>
> ## 7. 接线后取"运行期命中次数"的**精确过程**（留给集成波）
>
> ```bash
> # 1) 主控在集成波里做接线（改 TextFormatterImp 挑行的那段 —— 本轮刻意没动）
> # 2) 开开关、指定落盘路径，跑一次 HelloWpf
> export WPF_LINUX_TEXTLINE=1
> export WPF_LINUX_TEXTLINE_DUMP=/tmp/hbtextline.txt
> DISPLAY=:99 tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh
> cat /tmp/hbtextline.txt        # 每次进程退出追加一行汇总行
> ```
> 期望看到的**就是 §3 那条汇总行的格式**；`fallbackTotal` 与 9 个分量即"B2/B3 真实优先级"。
> 若 `lines=0` ⇒ 接线没生效（选路没走到新实现）。
>
> ---
>
> ## 8. 产物与边界
>
> | 产物 | 说明 |
> |---|---|
> | `build/shims/PresentationCore.HbTextLine.cs` | **本轮主交付**（约 640 行）：HarfBuzz 绑定 + `TextLine` 契约 + 开关/计数/落盘 |
> | `build/shims/PresentationCore.shims.txt` | 登记（+7 行注释与路径） |
> | `build/MilBridge/tests/TextLineProto/` | 验证工程（**编真 shim 源文件**）+ 驱动 |
> | `bash build/MilBridge/run.sh textline` | 一键复跑（9/9） |
>
> **只改了**：`build/shims/PresentationCore.HbTextLine.cs`（新）、`build/shims/PresentationCore.shims.txt`、`build/MilBridge/**`。
> **未碰**：`build/shims/Win32ShimResolver.cs`（主控/T2 的）、`src/`、`build/DirectWrite.Linux/`、
> `build/PresentationCore.Linux/`、`build/PresentationFramework*.Linux/`、`fonts*`、`samples/`、
> `tests/.../Presentation.Tests/`、`handoff.md`、`docs/unimplemented.md`、`verify-all.sh`、`upstream/`。
> **未重建 PC、未跑 verify-all、未跑 HelloWpf**；`-m:1`。
>
> ---

> # 🧪 轨道A · `TextLine` 契约限时原型 —— 路线 B 的工程量实测
>
> ## 结论（二选一，不含糊）
>
> **B 的成本可控，但比 M7c4 的外推略高：461 行（其中 311 行非空非注释代码），
> 卡点不在代码量，而在 4 条"实现位置"级别的连锁 —— 尤其第 1 条决定了它必须编译进 PresentationCore。**
>
> 判据（主控给的二选一）：
> - "≤400 行且能出字" ⇒ 本原型 **461 行 / 311 代码行**，**能出字**（实测 3954 个非白像素 + 可读 PNG）。
>   按"代码行"口径 **< 400**，按"含注释的总行数"口径 **略超**（+61 行）。**属于同一量级，不是"被低估"**。
> - "一上手就牵动 DrawingState/TextRunCache/TextMetrics 的连锁" ⇒ **没有**。
>   本原型**一次都没有碰**这三个类型（`grep -c 'DrawingState\|TextRunCache\|TextMetrics'` = 0）。
>   连锁在**别处**：见 §2。
>
> ---
>
> ## 1. 数字
>
> ### 1.1 净增行数（分文件）
> | 文件 | 总行 | 代码 | 注释 | 空行 | 角色 |
> |---|---|---|---|---|---|
> | `HbShaper.cs` | **123** | 102 | 7 | 14 | HarfBuzz 绑定 + shaping（可复用 M7c4 spike 的同一个 P/Invoke 面） |
> | `HbTextLine.cs` | **338** | 209 | 78 | 51 | **`TextLine` 契约实现本体**（32 个成员）+ `TextRunProperties`/`TextRun` 子类 + `TextBounds` 反射工厂 |
> | **小计（= 路线 B 的净增）** | **461** | **311** | 85 | 65 | |
> | `Program.cs` | 254 | 191 | 30 | 33 | **驱动 + 取证**（不是实现的一部分） |
> | `TextLineProto.csproj` | 45 | — | — | — | |
>
> ### 1.2 契约规模与欠账
>
> `TextLine` 是 `public abstract`，**必须实现 32 个成员**（另有 1 个 `virtual IsTruncated` 有默认实现、不欠）：
>
> | 类别 | 数量 | 本原型 |
> |---|---|---|
> | abstract 属性 | **19** | **19 全真实现**（全部由 shaping 结果直接算出，一行一个） |
> | abstract 方法 | **13** | **真实现 3 个**（`GetTextRunSpans` / `GetTextBounds` / `Draw`）+ `Dispose` + **9 个抛 `NotSupportedException`** |
>
> **欠 9 个 override**：`Collapse`、`GetBackspaceCaretCharacterHit`、`GetCharacterHitFromDistance`、
> `GetDistanceFromCharacterHit`、`GetIndexedGlyphRuns`、`GetNextCaretCharacterHit`、
> `GetPreviousCaretCharacterHit`、`GetTextCollapsedRanges`、`GetTextLineBreak`。
> 全部属于"裁剪 / 命中测试 / 光标 / 换行"面 —— 正是本原型刻意排除的范围。
>
> ---
>
> ## 2. ⭐ 踩到的连锁（4 条，全部有栈有据）
>
> ### 连锁 1（**最硬的**）：`TextBounds`/`TextRunBounds` 的构造是 `internal`
> ```
> TextBounds:     public ctor=0  非公开 ctor=1
> TextRunBounds:  public ctor=0  非公开 ctor=1
> ```
> ⇒ 外部程序集**只能用反射**造 `GetTextBounds` 的返回值（本原型就是这么做的，P3 通过）。
> ⇒ **真正落地时必须把实现编译进 PresentationCore** —— 也就是 `build/shims/` 那条既有机制
>   （和 `Win32ShimResolver`/`FontBridge` 同一个位置）。**这不是缺陷，但它把"实现放哪"这件事定死了**。
>
> ### 连锁 2：`new GlyphTypeface(Uri)` 在本移植上直接 NRE
> ```
> NullReferenceException
>  at MS.Internal.FontCache.FontFaceLayoutInfo.IntMap.TryGetValue(Int32, UInt16&)  FontFaceLayoutInfo.cs:642
>  at MS.Internal.FontCache.FontFaceLayoutInfo..ctor(Font)                        FontFaceLayoutInfo.cs:70
>  at System.Windows.Media.GlyphTypeface.Initialize(Uri, StyleSimulations)        GlyphTypeface.cs:150
> ```
> `_font.GetFontFace()` 返回了 **null**。⇒ "指向 ttf 文件拿 GlyphTypeface"这条最自然的路**是坏的**。
> **绕法**（本原型采用，P5 通过）：走 DWF `Font` → **内部** `GlyphTypeface(Font)` 构造（反射），
> 实测拿到 `GlyphCount=3884 Version=2.015`。
> ⚠️ **这条值得 T2 查**：它是 `GlyphTypeface(Uri)` 的公开入口，任何用 `new GlyphTypeface(new Uri(path))` 的代码都会踩。
>
> ### 连锁 3：按名字建 `FontFamily` 会撞 `OSVersionHelper`
> ```
> Exception: OSVersionHelper.GetOsVersion Could not detect OS!
>  at System.Windows.Interop.OSVersionHelper.GetOsVersion()          OSVersionHelper.cs:318
>  at MS.Internal.FontFace.CompositeFontParser.ParseFontFamilyCollectionElement()  CompositeFontParser.cs:344
> ```
> 根因是**设计使然**：Win32 shim 的 `IsWindows*` 一律返回 false（`win32_misc.c:1217+`），
> 而 `OSVersionHelper` 至少要 `IsOsWindowsXPSP2OrGreater` 为真才肯返回。
> ⇒ `TextRunProperties.Typeface` **没法走常规路径构造**。本原型把它留 null（`GetTextBounds`/`Draw` 都不需要它）。
>
> ### 连锁 4：**无头环境下连 `Brush` 都构造不出来**，`Draw` 驱动不了
> ```
> Win32Exception (1400) at CreateWindowEx
>  ← MessageOnlyHwndWrapper..ctor()  ← Dispatcher..ctor()  ← DispatcherObject..ctor()
>  ← DependencyObject..ctor() ← Freezable..ctor() ← Animatable..ctor() ← Transform..ctor()
>  ← Transform..cctor() ← Brush..cctor() ← Brushes.get_Black()
> ```
> 以及 `new DrawingVisual().RenderOpen()` **同一条链**（`MessageOnlyHwndWrapper`）。
> ⇒ 任何 `Freezable`/`DependencyObject`（`Brush`、`Transform`、`DrawingVisual`）都要求**一个活着的窗口**。
> ⇒ 本原型把 `Draw` **照实现**（本体一行：`drawingContext.DrawGlyphRun(brush, _glyphRun)`），
>   但字形证据走"把 `GlyphRun` 交给 Skia 光栅化"；`Draw` 只验证了 null 守卫。
>   （有窗口的应用里画刷由调用方提供，这一条不构成设计缺陷 —— 但**它意味着路线 B 的端到端验证必须跑窗口**。）
>
> ### 连带：`GlyphRun` 自身的三条契约（不是"连锁"，是必须知道的细节）
> | 契约 | 实测 |
> |---|---|
> | `clusterMap` | 个数 == `characters.Count`；`[0]` 必须 0；**单调不减**；每个值 **< GlyphCount**（`GlyphRun.cs:370-392`）。HarfBuzz 给的是**字形→字符**，必须**求逆**；连字时多字符映到同一字形 |
> | `caretStops` | 个数 == `characters.Count` **+ 1**（`GlyphRun.cs:411`） |
> | `GlyphTypeface` | **不能为 null**：`BeginInit`+setter 那条路 `EndInit` 会抛 "not fully initialized"（P6）⇒ 必须用完整公开构造 + 真 `GlyphTypeface` |
>
> ---
>
> ## 3. 字形真的画出来了吗（证据）
>
> ```
> A1 拿到真 GlyphTypeface（DWF Font → 内部 ctor）      GlyphCount=3884 Version=2.015 Baseline=1.0690
> A2 GetTextRunSpans()   → 1 个 span，长度 41
> A3 GetTextBounds()     → 真 TextBounds（反射构造 internal ctor）
>                          矩形=0,0,493.488,32.688（宽 493.4880 == TextLine.Width 493.4880）
> A4 Draw() 的 null 守卫正确（本体一行；真驱动需活窗口）
> A5 GlyphRun 与 HarfBuzz 直算**逐项相等**（37 个字形、advance 逐项 == ）
> A6 光栅化到 SKSurface → **非白像素 3954 / 51200（7.72%）**，PNG 4722 字节
> == 通过 6 / 失败 0 ==
> ```
>
> **PNG 证据**：`build/MilBridge/gen/textline-proto.png`（640×80）——
> 渲染出 **`Hello WPF on Linux — AVATAR To office ffi`**，
> 肉眼可确认 **`AVATAR`/`To` 的字距（kerning）生效**、**`ffi` 是单个连字字形**。
> （第一版我把 y 多翻了一次，PNG 里的字是倒的 —— 像素计数不受影响，但证据图不可读；已修。）
>
> ---
>
> ## 4. 与 HarfBuzz 直算的一致性
>
> ```
> GlyphRun.GlyphIndices = 37 个，与 HB 直算逐项相等 = True
> AdvanceWidths[0..2]   = [18.3600 14.3280 7.1520]，与 HB 直算逐项相等（阈值 1e-9）= True
> ```
> 即：**经我的 `TextLine` 出来的 advance 与 HarfBuzz 直算完全同值** —— 中间没有丢精度、没有单位错位。
>
> ### 与"现行快路径"的差（复用 M7c4 基线）
> ```
> 快路径（cmap+hmtx 名义字形）: 41 字形，总宽 500.5425px
> HarfBuzz shaping          : 37 字形，总宽 493.4880px
> 差                        : -4 字形，Δ = -7.0545px
> ```
> 与 M7c4 的基线（真实字体 37 vs 快路径 41、Δ≈−7px）**同量级且方向一致**。
>
> ---
>
> ## 5. 分阶段切分建议（既然结论是"可控"）
>
> | 阶段 | 内容 | 估计量级 | 依据 |
> |---|---|---|---|
> | **B1**（本原型 = 已完成） | 单行 / LTR / 不裁剪：`GetTextRunSpans` + `GetTextBounds` + `Draw` + 19 属性 | **461 行**（实测） | 本文件 |
> | **B2** | `GetIndexedGlyphRuns`（渲染后端取字形用）+ `GetTextLineBreak`（换行状态） | ~150–250 行 | 两者都能从现有 shaping 结果直接投影 |
> | **B3** | 光标/命中测试 5 个（`GetCharacterHitFromDistance` / `GetDistanceFromCharacterHit` / 前后 `CaretCharacterHit` / `GetBackspace…`） | ~300–450 行 | 需要 clusterMap 的**双向**查询 + advance 前缀和（本原型已有前缀和） |
> | **B4** | 多行 + 断行（ICU `ubrk_*`，M7c4 的 M6 已证可用）+ `Collapse`/`GetTextCollapsedRanges` | ~600–900 行 | 断行是新依赖；折叠/裁剪独立 |
>
> **关键前提**：实现必须**编译进 PresentationCore**（连锁 1）—— 也就是落进 `build/shims/`，
> 而不是像本原型这样外部引用。这会改变"谁能改"的边界，需要在里程碑里先定。
>
> ---
>
> ## 6. 边界与产物
>
> **只新增 `build/MilBridge/tests/{ContractProbe,TextLineProto}/`** 与 `run.sh` 的 `textline` 目标 + `gen/textline-proto.png`。
> **未碰**：`src/`（含 `Interop/`、`Windowing/`）、`build/DirectWrite.Linux/`、`build/shims/`、`build/PresentationCore.Linux/`、
> `build/fonts*`、`samples/`、`tests/.../Presentation.Tests/`、`handoff.md`、`docs/unimplemented.md`、`verify-all.sh`、`upstream/`。
> **未重建 PC、未跑 verify-all、未跑 X**；`-m:1`。
> （探针/原型**只读**引用已构建的 `PresentationCore.dll` + `WindowsBase.dll` + `DirectWriteForwarder.dll`。）
>
> 复现：`bash build/MilBridge/run.sh textline`
>
> ---
>

> # 🔌 M7c6 · `MILQueryInterface` / `MILRelease` 的 WIC 句柄桥（2026-09-10 晚）
>
> **一句话**：上游 PC 在纯上游代码路径上就对 **WIC 源句柄**调 `MILQueryInterface`，
> 而这个 P/Invoke 落在本 .so。现在 `Resolve()` 失败时问句柄的**所有者**（`libwpfwic.so`）：
> 白名单 GUID → `WicShim_AddRef` + `S_OK`；**`MILRelease` 转发 `WicShim_Release`**。
> 未装 WIC 时行为**一字未变**。
>
> | 门禁 | 结果 |
> |---|---|
> | 闭环 `tests/ClosedLoop` | **54 / 54 全绿，0 跳过**（G 组 7 条全是 WIC 取证） |
> | `Commands.Tests` | **562 / 562 全绿** |
> | `run.sh` | `t2` ✅ · `hb` 7/7 · `strip` 21/21 · **`wic` 54/54** · `test` 54/54 |
> | GUID 漂移检查 | **三处一致**（本工程 / 上游两份 `wgx_exports.cs` / PC 的 `[Guid]`） |
> | `.so` | **4,531,824 B**，SHA256 **`0aa95aaf3f2ec1dcd60083c7c4c8a83f38d30d8157a480f4e96a2a744273d86c`** |
> | `nm -D` | 总 `T` **127** · **MIL ABI 109（不变）** · **缺失 0** · 诊断面 **16** |
>
> ---
>
> ## ① 实现
>
> `src/WpfGfx.Linux/Interop/MilNative.Misc.cs`（单文件）：
> - `MILQueryInterface`：`MilDeviceObjectTable.Resolve()` 命中 → **原语义一字未动**；
>   未命中 → `MilExternalHandleBridge.QueryInterface`。
> - `MILRelease`：未命中 MIL 表 **且** 是 WIC 句柄 → **转发 `WicShim_Release`**。
> - 新增 `public static class MilExternalHandleBridge`（惰性 `dlopen` + 计数 + 契约注释）。
>
> ### GUID 怎么拿到的（主控专门问的）
>
> `IID_IWICBitmapSource = 00000120-A8F2-4877-BA0A-FD2B6645FB94`，权威定义在
> `Common/Graphics/wgx_exports.cs:268` 的 `MILGuidData.IID_IWICBitmapSource`（`internal static readonly`）。
> **WpfGfx.Linux 编译期拿不到它**：引用 PresentationCore 会把整个 PC 拉进 AOT 镜像（绝不可行），
> AOT 运行时里也没有 PC 可反射。所以是**逐字抄写 + 机械核对**：
> `build/MilBridge/tools/check-mil-guids.py` 重新解析上游三处并与本工程常量比对，**上游一改就红**。
>
> ```
> 本工程   IID_IWICBitmapSource = 00000120-A8F2-4877-BA0A-FD2B6645FB94   (MilNative.Misc.cs)
> 上游     IID_IWICBitmapSource = 00000120-A8F2-4877-BA0A-FD2B6645FB94   (Common/Graphics/wgx_exports.cs)  一致
> 上游     IID_IWICBitmapSource = 00000120-A8F2-4877-BA0A-FD2B6645FB94   (WpfGfx/include/wgx_exports.cs)   一致
> PC       IWICBitmapSource [Guid]                                     (BitmapSource.cs)                 一致
> ```
>
> > 没做"编译期生成"的理由：那要往上游只读树加生成步骤、或往 `src/` 塞生成文件（本轮 lane 之外）；
> > 而测试/脚本级核对给出**同样的漂移保护**，零构建复杂度。
>
> ### fail-safe（默认行为一字不变）
> `.so` 找不到 / `dlopen` 失败 / **三个必需符号缺任何一个** / 句柄不属于它 ⇒ 一律 `E_HANDLE`。
> ⚠️ **三个符号必须齐全**才算"接上"：只有 `OwnsHandle` 而没有 AddRef/Release 的旧版 .so
> 会让放行变成**单边账本**（放行了却减不掉引用）—— 那正是明令禁止的形态。
>
> ---
>
> ## ② 引用计数契约（⭐ 本轮的重点）
>
> ### 2.1 PC 的真实序列 —— **AddRef 是必需的，不是可选项**
>
> | 步 | 上游原文 | 含义 |
> |---|---|---|
> | 1 | `BitmapFrameDecode.cs:701` `_frameSource = new BitmapSourceSafeMILHandle(frameDecode);` | 原句柄 **refs=1，且会被释放**（构造注释："SafeMILHandle owns the release of the parameter"） |
> | 2 | `BitmapFrameDecode.cs:448` `WicSourceHandle = _frameSource;` | 触发 `BitmapSource.cs:581-586` 的 QI → **+1 = 2** |
> | 3 | `BitmapFrameDecode.cs:453` `WicSourceHandle = CreateCachedBitmap(...)` | **覆盖** `_wicSource` ⇒ 第 2 步拿到的句柄**立刻被释放** → **1** |
> | 4 | `SafeMILHandle.cs:63` `ReleaseHandle → MILUnknown.ReleaseInterface` | 最终释放 `_frameSource` → **0，回收** |
>
> **⇒ 账本：1 → 2 → 1 → 0。**
>
> ### 2.2 为什么"放行但不 AddRef"**不安全**（对 T2 那条备选形态的反面证据）
>
> 若 QI 不 +1：`1 →（不 +1）1 → 释放 QI 句柄 = **0，对象当场回收** → 第 4 步再释放一次`
> ⇒ **引用计数下溢 / 二次释放（use-after-free）**。
> 因为第 1 步的 `_frameSource` 与第 2 步的 QI 句柄是**两个各自独立的持有者**，
> 而内存里它们是**同一个句柄值**（WIC 句柄是不透明整数，QI 只能返回同一个）。
> **所以本桥只实现 AddRef + 转发 Release 这一种自洽形态。**
>
> ### 2.3 契约条文（已写进 `MilExternalHandleBridge` 类注释）
>
> | 句柄类别 | QI | Release |
> |---|---|---|
> | MIL 自己下发的对象 | `IID_IUnknown` → 同句柄 + `MilDeviceObjectTable.AddRef`；其它 IID → `E_NOINTERFACE` | `MilDeviceObjectTable.Release`（**原语义**） |
> | **WIC 句柄** | 白名单 GUID → `WicShim_AddRef`(+1) → 同句柄 + `S_OK`；AddRef 返回 ≤0（已失效）→ `E_HANDLE` | **`WicShim_Release`(−1)**；归零由 shim 回收 |
> | 其它 | `E_NOINTERFACE` | — |
> | 无法判定 / 库不可用 | `E_HANDLE` | 走原路径（`E_HANDLE`） |
>
> ### 2.4 不转发 Release 是**硬失败**（实测复现）
>
> shim 对象表上限 `WIC_OBJ_MAX = 256`，第 257 次 `obj_new` 返回 0 ⇒ `CreateDecoderFromFileHandle` 直接失败。
> **本轮实测复现过**：在桥还没接上（Release 没转发）的那次运行里：
> ```
> G6b  创建失败=216  QI失败=84  Release失败=168；live 3→256（应回到基线）；peak=256
> ```
> 接上转发之后同一用例：**创建失败 0**、live 回到基线、`peak=6`、**每一轮的 handle 都是 0x6（槽位在复用）**。
>
> ---
>
> ## ③ 跨边界配平实测（主控要求含**高水位**）
>
> ```
> G6  500×(MILQueryInterface + MILRelease) 跨边界配平
>     循环失败=0/1000；live 3→3（应相等）；**peak 3→3（应相等）**；
>     句柄仍认领=True 仍可用=True；MILAddRef 前=0 后=0（应都 0）
>
> G6b 复用同一工厂/解码器连建 300 个帧（> 表上限 256）全部成功
>     创建失败=0 QI失败=0 Release失败=0 槽位复用异常=0；
>     live 5→5（应回到基线）；peak=6（远小于 300 ⇒ 在复用）；
>     第1轮 handle=0x6   第300轮 handle=0x6
> ```
>
> 三个判据都齐：
> - **live 回基线**（`WicShim_HandleCount`）
> - **peak 不随轮数上涨**（`WicShim_PeakHandleCount` —— 专防"计数相等但高水位一直涨"的花架子回收）
> - **MIL 侧无账**（`MILAddRef(wicHandle)` 前后都是 0 ⇒ 没被建进 MIL 的设备对象表）
>
> 其余取证：
> ```
> G1  非 WIC / 未登记句柄 → E_HANDLE（fail-safe）        hr=0x80070006
> G2  空句柄 → E_INVALIDARG                              hr=0x80070057
> G3  QI(IID_IWICBitmapSource) → S_OK + 同一句柄         hr=0x00000000 ppv=0x3
> G4  QI(IID_IUnknown)         → S_OK + 同一句柄         hr=0x00000000 ppv=0x3
> G5  白名单外 4 个 IID → 全部 E_NOINTERFACE 且 ppv=0
> G7  MIL 设备对象：IUnknown→S_OK+AddRef（计数 3）；其它 IID→E_NOINTERFACE（原语义不变）
> ```
>
> ---
>
> ## ④ 过程中发现的两个坑（都会影响别的 lane）
>
> ### 4.1 ⭐ `libwpfwic.so` **必须是同一个实例**（否则两张独立的对象表）
>
> 我第一版测试在**宿主进程**里加载 `build/DirectWrite.Linux/wic-shim/libwpfwic.so` 建句柄，
> 而 .so 内部的桥加载的是**另一份副本** ⇒ `dlopen` 按路径去重，两个不同路径 = **两个对象**、
> **两张 `g_objs` 表** ⇒ 宿主建的句柄在桥那侧"不属于它" ⇒ 全部 `E_HANDLE`。
> **生产部署天然满足**（应用目录只有一个 `libwpfwic.so`），但这是个**真实约束**：
> **任何加载 `libwpfwic.so` 的代码都必须用同一个路径**，否则句柄互不认账。
>
> ### 4.2 AOT 共享库里的 `AppContext.BaseDirectory` **不是宿主应用目录**
>
> 与 M7c3 给 `libSkiaSharp` 踩的是同一个坑：桥按"应用目录"找 `libwpfwic.so` 找不到。
> 修法沿用 M7c3 的思路 —— 桥接层已经用 `dladdr` 算出 .so 自己的目录并通过
> `MilBridge_SetNativeDir` 送进来，现在**同一条通道**也把目录交给 `MilExternalHandleBridge`
> （`NativeSearchPath.SetNativeDir` → `SetSearchDirectory`）。注入目录是候选里的**第一优先**。
>
> ---
>
> ## ⑤ 边界、产物与复现
>
> **只改 `src/WpfGfx.Linux/Interop/MilNative.Misc.cs`**（单文件）+ `build/MilBridge/`。
> **未碰**：`build/DirectWrite.Linux/`（含 `wic-shim/`）、`src/WpfGfx.Linux.Native/`、`build/shims/`、
> `build/PresentationCore.Linux/`、`build/fonts*`、`samples/`、`tests/.../Presentation.Tests/`、
> `handoff.md`、`verify-all.sh`、`upstream/`。**未重建 PC、未跑 X**；`-m:1`。
>
> | 产物 | 说明 |
> |---|---|
> | `build/MilBridge/tools/check-mil-guids.py` | GUID 漂移检查（三处比对） |
> | `build/MilBridge/tests/ClosedLoop/Program.cs` | G 组 7 条（WIC 取证 + 配平） |
> | `bash build/MilBridge/run.sh wic` | 一键复跑（GUID 检查 + 54/54） |
>
> ### 关于"MIL 提供外部句柄登记导出"这条备选路线（只评估，未实施）
>
> | | 惰性 dlopen（**本轮采用**） | MIL 侧登记导出 |
> |---|---|---|
> | 代价 | 桥内 ~200 行；**MIL 对 WIC 零依赖** | MIL 多一个 public 导出 + shim 启动时注册 |
> | 单实例问题 | 靠"同路径"约定（4.1） | **天然解决**（shim 主动把表交给 MIL） |
> | 反向依赖 | 无 | **shim 要能找到 MIL 的 .so**（同一个问题的镜像）+ 初始化顺序 |
> | fail-safe | 天然（找不到就 E_HANDLE） | 需要额外设计"没注册时"的语义 |
> | 结论 | **保持现状** —— 已验证可用且有 fail-safe；备选的收益不足以抵掉新增的初始化顺序耦合 |
>
> ---
>

> # 🧩 M7c5 · 路线 C 交付：运行期 GSUB/GPOS 剥离（2026-09-10 晚）
>
> **一句话**：任何字体在加载时按需剥掉 `GSUB`/`GPOS`，于是**任何字体都能过闸门 2**，
> 解除"只有默认 UI 字体能出字"这条产品级限制。**验收 ①–⑤ 全部达成**，
> 其中 ① 是**字节全等**、② 走的是**真实 PC 代码路径**。
>
> | 验收 | 结果 |
> |---|---|
> | ① 与 Python oracle 等价 | ✅ **整份文件字节全等**（332,736 B / 332,736 B）；表集合、逐表内容全等 |
> | ② 闸门 2 真的过了（真实 PC） | ✅ Noto **21 → 0**、DejaVu **23 → 0**；`CheckFastPathNominalGlyphs` **False → True** |
> | ③ 零额外语义损失 | ✅ upem / glyphCount(3884) / **3884 个字形步进+lsb** / **65536 个 BMP 码点** / Skia 加载与步进 全部一致 |
> | ④ 关掉时行为不变 | ✅ 全量套件 **94 → 115 全绿**（连跑 2 次）；T2 的 `probe-digest.txt` **值未变** |
> | ⑤ 失败要明说 | ✅ 6 类失败各自有原因码，**一律原字节返回**，绝不产出半个字体 |
>
> ---
>
> ## ① 实现与落点
>
> | 文件 | 作用 |
> |---|---|
> | `Provider/FontTableStripper.cs`（**改**） | 新增 `TryStripTables`（**不抛**、失败返原字节 + `FailureReason`）。原有的 `StripTables`（抛）保留，成功路径逐字节相同 |
> | `Provider/FontLayoutStripping.cs`（**新增**） | 开关（env / 编译期默认 / 逐次旁路）、统计、`Apply` 落地 |
> | `Provider/LinuxFontFace.cs`、`LinuxFontCollection.cs`、`LinuxFontFile.cs`（**改**） | 三个加载入口接上剥离；集合路径**每文件只读+剥一次**（面下标探测不再重复读） |
> | `Probe/ProbeDigest.cs`（**改**） | **显式旁路** —— 探针是"原始语料"诊断，见 §④ |
>
> **只剥 `GSUB`/`GPOS`**（与 `build/gen-ui-font.py` 的 `DEFAULT_STRIP` 一致）；`GDEF`/`kern`/`glyf`/`hmtx`/`cmap`… 一律不动（有断言：`GDEF` 剥后仍在）。
>
> **不改磁盘**：剥发生在**字节读进内存之后**，输出是新数组。
>
> ---
>
> ## ② 验收 ①：与 Python oracle 等价 —— **字节全等**
>
> ```
> C#     表集合: GDEF,OS/2,cmap,glyf,head,hhea,hmtx,loca,maxp,name,post
> oracle 表集合: GDEF,OS/2,cmap,glyf,head,hhea,hmtx,loca,maxp,name,post
> 整份文件字节全等 = True（C# 332736 B / oracle 332736 B）
> ```
>
> 逐表内容也逐字节比对通过。**唯一的字节差异在 `head` 表**，而且是与**原始文件**比：
>
> ```
> head 表与原文的差异字节数=4，首个=8（checkSumAdjustment 在偏移 8..11）
> ```
>
> 这是 **OpenType 规范的强制要求**：`head.checkSumAdjustment = 0xB1B0AFBA − 整份文件 checksum`，
> 剥掉两张表之后整份 checksum 变了，必须重算。Python oracle 同样这么做，所以 C# 与 oracle 的 `head` **完全一致**。
> ⇒ "剥离后字体与原文逐字节相同"这个说法**不成立**，准确口径是"**除 `head` 偏移 8..11 的 4 字节外全等**"。
> 这一点后面 §④ 直接导致了两条既有断言必须改成显式测原始文件。
>
> ---
>
> ## ③ 验收 ②：闸门 2 真的过了（**真实 PC 代码路径**）
>
> 用 `WiringSmoke`（T2 既有的独立路子，跑在真实 PC 装配里）—— 它调的是 PC 自己的
> `MS.Internal.FontCache.FontFaceLayoutInfo` 与 `System.Windows.Media.Typeface.CheckFastPathNominalGlyphs`
> （即 `SimpleTextLine.cs:1665` 那个入口），不是我们的估算。
>
> ```
> ### Noto Sans（build/fonts），WPF_LINUX_STRIP_LAYOUT=0
> HANDOFF TTO_GSUB=0x47535542 ok=True  len=11960
> HANDOFF TTO_GPOS=0x47504F53 ok=True  len=85704
> TYPOGRAPHY_MASK=21        FASTPATH_CHECK=False stringLengthFit=18
> ### Noto Sans，WPF_LINUX_STRIP_LAYOUT=1（默认）
> HANDOFF TTO_GSUB=0x47535542 ok=False len=-1
> HANDOFF TTO_GPOS=0x47504F53 ok=False len=-1
> TYPOGRAPHY_MASK=0         FASTPATH_CHECK=True  stringLengthFit=18
> STRIP_LAYOUT_LAST_REASON=stripped(GSUB,GPOS)   STRIP_LAYOUT_STRIPPED=14
>
> ### DejaVu Sans（/usr/share/fonts/truetype/dejavu），strip=0 → strip=1
> TYPOGRAPHY_MASK=23        FASTPATH_CHECK=False stringLengthFit=18
> TYPOGRAPHY_MASK=0         FASTPATH_CHECK=True  stringLengthFit=18
> STRIP_LAYOUT_STRIPPED=20
> ```
>
> 两个语料的掩码位组合**不同**（这正是要两个都测的原因）：
> - Noto Sans `21` = `Available(1) | FastTextTypographyAvailable(4) | FastTextExtraLanguageLocalizedFormAvailable(16)`
> - DejaVu Sans `23` = 上面三个 `| IdeoTypographyAvailable(2)`
>
> 逐字体（provider 侧掩码，来自 `FontLayoutStrippingTests`）：
> | 字体 | 原始掩码 | 剥后掩码 | 快路径 |
> |---|---|---|---|
> | `NotoSans-Regular.ttf` | 21 | **0** | False → **True** |
> | `NotoSans-Bold.ttf` | 21 | **0** | False → **True** |
> | `DejaVuSans.ttf` | 23 | **0** | False → **True** |
>
> ---
>
> ## ④ 验收 ③：零额外语义损失
>
> 在 `LinuxFontFace.FromFile(..., stripLayout:true)` vs `stripLayout:false` 之间逐项断言：
> - `UnitsPerEm`、`NumGlyphs`（**3884**）、`HheaAscender/Descender`、`CapHeight`、`XHeight`、`UnderlinePosition`
> - **3884 个字形**的 `AdvanceWidth` 与 `LeftSideBearing`
> - **全部 65536 个 BMP 码点**的 `CmapLookup`
> - Skia 侧：`GlyphCount` / `UnitsPerEm` / `FamilyName` / `FontWeight` / ASCII 区 `GetGlyph`
> - Skia 侧步进：size=upem、`LinearMetrics`、无 hint 下逐字形 `GetGlyphWidths` 数组相等
>
> ---
>
> ## ⑤ 验收 ④：关掉时行为不变 + **受影响的既有断言逐条清单**
>
> ### 5.1 全量回归
>
> | | 改前 | 改后 |
> |---|---|---|
> | `DirectWrite.Linux.Tests` | **94 / 94** | **115 / 115**（连跑 **2 次**一致） |
> | 新增 | — | **+21**（`FontLayoutStrippingTests` 18 + `StripLayoutSmokeTests` 3） |
> | `src/` 构建 | — | 未碰 |
>
> `bash build/MilBridge/run.sh strip` → 21/21。
>
> ### 5.2 受影响的既有断言：**恰好 3 条**，全部是"原始文件保真"类
>
> | # | 断言 | 为什么受影响 | 怎么处理 |
> |---|---|---|---|
> | 1 | `OpenTypeOracleTests.TableBytes_FromSkia_MatchRawFileBytes_AllFaces` | 它比对"provider 的表 vs 磁盘原文件"，默认剥后 GSUB/GPOS 消失、`head` 的 4 字节变了 | `FontFixture` 改为 `FromDirectory(..., stripLayout:false)`（装置语义本就是"原始语料"），断言**一字未改** |
> | 2 | `M1ConsistencyTests.M1_FontSet_ResolvesSameFileForEveryStyle` | 同上（它用 `head` 表 sha 证明"同一个文件"，而 `head` 的 checkSumAdjustment 会变） | 同 #1（共用 `FontFixture`），断言**一字未改** |
> | 3 | `WiringTests.WiredSkeleton_ReturnsRealFontData`（`FACE_HEADTABLE_SHA_MATCH`） | 它逐字节比对"骨架给的 head vs 测试从 .ttf 切的 head" | `RunSmoke()` 里显式 `WPF_LINUX_STRIP_LAYOUT=0`，**并新增 2 条断言把"确实跑在不剥模式"钉住**（`STRIP_LAYOUT_LAST_REASON=disabled` / `STRIP_LAYOUT_STRIPPED=0`）。原断言**一字未改** |
>
> **没有任何断言被改小、删掉或放宽**；"原始 21/23" 与 "运行期剥后 0" 现在**各自有独立的断言**：
> - 原始：`RuntimeStrip_TurnsGate2MaskToZero_AndAllowsFastPath` 的前半段（`stripLayout:false` → `Assert.Equal(21/23)`）、`Bypass_LeavesTheFaceIndistinguishableFromTheRawFile`、`CollectionBypass_KeepsEveryFaceRaw`、以及 `StripLayoutSmokeTests` 的 `strip=0` 分支
> - 剥后：同一条测试的后半段、`CollectionDefault_StripsEveryFace`、`StripLayoutSmokeTests` 的 `strip=1` 与**默认分支**
>
> **`TypographyGateTests`（8 条）一行未改且全绿** —— 它走 `OpenTypeFontData.FromSfnt`（不经加载路径），语义本就是"原始字节"，因此**不受默认值影响**。
>
> ### 5.3 T2 的已提交产物：**值未变**
>
> ```
> build/DirectWrite.Linux/artifacts/probe-digest.txt
> in-process: d8c7def143e83602355b50945561e93941f9ae99ca95c2850b9f2e2780330b1e   ← 与改动前逐字相同
> ```
> `probe-summary.txt` 的 `TABLES GDEF,GPOS,GSUB,...` 行也仍在、文件未被改写（mtime 仍是 T2 的 15:25）。
> 做法：`ProbeDigest.Build` 里**显式** `FromDirectory(fontDir, recurse:false, stripLayout:false)` ——
> 探针是"原始语料"的诊断，语义上就该测原始字节。
>
> ---
>
> ## ⑥ 验收 ⑤：失败一律原字节 + 原因码
>
> `FontTableStripper.TryStripTables` **不抛异常**，契约是
> `result = 原字节`、`stripResult = false`、`reason = 具体原因`。实测矩阵：
>
> | 输入 | 原因码 | 返回 |
> |---|---|---|
> | 随机字节（表目录读出来是垃圾） | `corrupt-table-directory` | 原字节 ✅ |
> | 长度 < 12 | `too-short` | 原字节 ✅ |
> | 空数组 | `too-short` | 原字节 ✅ |
> | 目录完好但 `numTables` 越界 | `corrupt-table-directory` | 原字节 ✅ |
> | 目录完好但没有 `head` | `no-head-table` | 原字节 ✅ |
> | `ttcf`（TTC） | `ttc-unsupported` | 原字节 ✅ |
> | **本来就没有 GSUB/GPOS**（`UI-NoLayout.ttf`） | `no-layout-tables` | 原字节 ✅ |
>
> **`no-layout-tables` 不算失败**（单列一个计数器）：开关开着但字体本就没有布局表是**正常情况**，
> 把它记成失败会让"剥失败"这个词失去意义。统计口径：
> `StrippedCount` / `NoLayoutTablesCount` / `BypassedCount` / `FailedCount` / `LastReason`，
> 全部经 `WiringSmoke` 打印（`STRIP_LAYOUT_*`），可被测试与排障直接读。
>
> ---
>
> ## ⑦ 默认值：**开**，以及论证（主控要求用"哪些既有断言会变"来论证）
>
> ### 7.1 逐条论证
>
> | 维度 | 默认**开** | 默认**关** |
> |---|---|---|
> | 应用显式指定真实字体时 | 过闸门 2 → **名义字形出字** | 闸门 2 拒 → `FullTextLine` → `LoCreateContext` 等 **26 个原生符号缺失**（本仓库没有那套 C++）→ **崩** |
> | 排版质量 | 无 kerning / 无连字（**与今天完全一样**：本工程没有 shaper） | 同左（因为根本走不到） |
> | 字体元数据 | `TryGetFontTable(GSUB/GPOS)` 返回 false ⇒ WPF `FontCapabilities` 之类报"无特性" | 保真 |
>
> **结论**：在"没有 shaper"这个前提下，"剥"严格优于"不剥" —— 它把**崩溃**换成**正确渲染**，
> 唯一代价是元数据保真度，而**没有任何消费者能使用那些特性**（GSUB/GPOS 在本工程任何路径下都不会被应用）。
>
> ### 7.2 会变的既有断言（**这就是代价的准确清单**）
>
> 只有 §5.2 那 **3 条**，且全部是"provider 的表 == 磁盘原文件"这一类**保真**断言。
> 它们全部通过"把装置的语义显式化为原始语料"来保全，**没有一条被放宽**；
> 同时**新增 21 条断言**覆盖剥离后的行为（含默认分支）。
> 换句话说：**默认开没有让任何一条既有断言从"21"悄悄变成"0"** ——
> 21 与 0 现在分别在两条各自成立的断言里。
>
> ### 7.3 开关
>
> | 形式 | 用法 |
> |---|---|
> | 环境变量 | `WPF_LINUX_STRIP_LAYOUT=0` 关（也接受 `1/true/on/yes`、`0/false/off/no`；**认不出来回默认**，不因为打错字改行为） |
> | 编译期 | `FontLayoutStripping.DefaultEnabled = true` |
> | **逐次旁路** | 加载入口的显式参数：`null`=默认 / `false`=本次不剥 / `true`=本次强制剥 |
>
> ---
>
> ## ⑧ 过程中踩到并修掉的三个坑（都会影响后续工作，值得留档）
>
> ### 8.1 ⚠️ **可选参数是二进制破坏性改动**
>
> 我最初把 `stripLayout` 写成 `FromDirectory(string, bool recurse = false, bool? stripLayout = null)`。
> 编译通过、provider 自己测也过，但 `WiringSmoke` 立刻炸：
> ```
> SMOKE_FAILED: System.MissingMethodException:
>   Method not found: 'LinuxFontCollection LinuxFontCollection.FromDirectory(System.String, Boolean)'.
> ```
> **原因**：C# 的"可选参数"是**编译期糖**，调用点会把默认值填进去、绑定到完整签名；
> 改签名 ⇒ **预编译程序集**（`DirectWriteForwarder.dll` / `PresentationCore.dll`，本轮不重建）绑不上。
> **修法**：一律**新增重载**，既有签名（连同默认值）**逐字保持**。
> ⇒ **对整个移植的通用教训**：只要 PC/DWF 是预编译产物，动 provider 的公共签名就必须走重载。
>
> ### 8.2 `head.checkSumAdjustment` 必然变（见 §2）
> 这条直接决定了 §5.2 的 3 条断言要改成"显式测原始文件"。
>
> ### 8.3 用反射调 PC 的 `CheckFastPathNominalGlyphs` 有三处反直觉
> 1. `FontStyle.Normal` **不存在** —— 常量住在**复数**静态类 `FontStyles`/`FontWeights`/`FontStretches` 上；
>    而且它们是 **static readonly 字段**，不是属性（`GetProperty` 找不到）。
> 2. `Typeface` 的 4 参构造要用 `GetConstructor` 显式取，`Activator.CreateInstance` 的 binder 形态会失败。
> 3. `Typeface` 有**两个** `TryGetGlyphTypeface` 重载（一个 `out` 版、一个返回实例版）⇒ `GetMethod` 抛 `AmbiguousMatchException`，要按参数表精确取。
>
> ---
>
> ## ⑨ 路线 B 第 2 步是否还缺那条限时原型实测
>
> **仍然缺，而且结论不变。** 路线 C 只解决了"**能不能出字**"（名义字形），
> **没有**解决"**排版是否正确**"（kerning / 连字 / locl）。要让真实字体走**真实 shaping**，
> 仍然只有路线 B：HarfBuzz（M7c4 的 M1–M6 已证 7/7）+ ICU 断行，
> 在托管侧实现 `TextLine` 契约（`FullTextLine` 有 33 个 `public override`）。
>
> M7c4 报告里那条"**不足以决定**"依旧成立：**代价区间（1,500–2,500 行）是外推的，不是写出来的**。
> 缺的实测仍是：给 `TextLine` 契约做**限时原型**（单行 / LTR / 不裁剪），
> 只实现 `GetTextRunSpans` + `GetTextBounds` + `Draw` 三个 override，
> 用 HarfBuzz run 喂 `GlyphRun`，跑通一次 `FormattedText` 测量 + 一次绘制。
> （路线 C 落地后，这条原型的**紧迫性下降**了 —— 字体已经能出字 —— 但它仍是"排版正确性"的唯一入口。）
>
> ---
>
> ## ⑩ 产物与复现
>
> | 产物 | 说明 |
> |---|---|
> | `build/DirectWrite.Linux/Provider/FontLayoutStripping.cs` | 新增：开关 + 统计 + 落地 |
> | `build/DirectWrite.Linux/Tests/FontLayoutStrippingTests.cs` | 新增：验收 ①③④⑤（18 条） |
> | `build/DirectWrite.Linux/Tests/StripLayoutSmokeTests.cs` | 新增：验收 ②（真实 PC，3 条） |
> | `bash build/MilBridge/run.sh strip` | 一键复跑（21/21） |
>
> ```bash
> # 全量
> dotnet test build/DirectWrite.Linux/Tests/DirectWrite.Linux.Tests.csproj -c Debug -m:1   # 115/115
> # 只看剥离两套
> bash build/MilBridge/run.sh strip                                                        # 21/21
> # 真实 PC 路径单跑（两种模式对照）
> W=build/DirectWrite.Linux/WiringSmoke/bin/Debug/DirectWrite.Linux.WiringSmoke.dll
> env WPF_LINUX_STRIP_LAYOUT=0 WPF_LINUX_FONT_DIR=$PWD/build/fonts dotnet $W --font-dir $PWD/build/fonts
> env WPF_LINUX_STRIP_LAYOUT=1 WPF_LINUX_FONT_DIR=$PWD/build/fonts dotnet $W --font-dir $PWD/build/fonts
> ```
>
> **本轮边界**：只动 `build/DirectWrite.Linux/`（`wic-shim/` **未碰**）与 `build/MilBridge/run.sh`；
> `src/`、`build/PresentationCore.Linux/`、`build/DirectWriteForwarder.Linux/`、`build/shims/`、
> `build/fonts*`、`build/gen-ui-font.py`、`samples/`、`docs/unimplemented.md`、`handoff.md`、
> `verify-all.sh`、`upstream/` **一行未改**；**未重建 PC、未跑 X**；全程 `-m:1`。
>
> ---
>

> # 🧭 M7c4 · 真实文字栈：路线决策报告（2026-09-10 晚）
>
> **结论先行（三句话）**
> 1. **路线 A「补齐 LineServices」在原仓库里不成立** —— 那套 C++ **一行都不存在**（实测：`Lo*/Fs*/Nl*` 在 `upstream/` 的 0 个 C++ 文件里，`redist/PresentationNative/PresentationNative.vcxproj` 整个目录缺失）。它不是"移植"，是**没有参考实现地从零写一个 OpenType 排版引擎**。
> 2. **推荐路线 B（HarfBuzz shaping + ICU 断行，托管侧重写 `TextLine`）**，关键假设已用 7 条实测对照证明（M0–M6 全绿）。
> 3. **但 B 的工程量我给不出实测数字，只给区间估计** —— 见 §③ 末尾的「不足以决定的那一条」。在拿到那条实测之前，**建议先落路线 C（stopgap，~300 行）把"只有默认 UI 字体能出字"这条产品级限制解掉**，B 作为目标态分阶段做。
>
> ---
>
> ## ① 缺口到底在哪一层（逐层实测）
>
> ### 1.1 `MS.Internal.Text.TextInterface` 是什么、现在什么状态
>
> - **它不是一个类型，只是一个命名空间** —— 上游 `MS.Internal.Text.TextInterface.*` 是 C++/CLI 工程 `DirectWriteForwarder.vcxproj` 的**托管面**（该工程已被 `port-lib.py` 丢弃）。
> - Linux 替代：`build/DirectWriteForwarder.Linux/ManagedSurface.cs`（**1325 行**）+ `NativeMirrors.cs` + `ProviderAdapters.cs`，下沉到 `build/DirectWrite.Linux/Provider/`（**4708 行 / 15 文件**，Skia + FreeType）。接线见 `build/PresentationCore.Linux/PresentationCore.Linux.csproj:1518-1523`、`:1535-1540`。
> - **PNSE 存根：15 条**（T2 重接线后从 62 降到 15）。其中**与 shaping 直接相关的 6 条全在 `TextAnalyzer`**：
>
> | 成员 | file:line | 语义 | 谁在调 |
> |---|---|---|---|
> | `TextAnalyzer.Itemize` | `ManagedSurface.cs:1120` | 脚本分段 | `MS/Internal/Shaping/TypefaceMap.cs:110`（仅复杂路径） |
> | `TextAnalyzer.GetGlyphs` | `:1139` | **GSUB shaping** | `LineServicesCallbacks.cs:1618` |
> | `TextAnalyzer.GetGlyphPlacements` | `:1150` | **GPOS 定位** | `LineServicesCallbacks.cs:1703` |
> | `TextAnalyzer.GetGlyphsAndTheirPlacements` | `:1162` | 两者合一 | `FormattedTextSymbols.cs:121`（省略号裁剪） |
> | `AnalyzeExtendedAndItemize` / `ReleaseItemizationNativeResources` | `:1130` / `:1134` | Itemize 内部 | — |
>
> ⚠️ **这一条改变了整个问题的形状**：复杂路径的 **shaping 回调是托管的**，不是原生的。原生 LineServices 只是**回调**它们。也就是说 —— "实现 shaping" 和 "实现 LineServices" 是**两件独立的事**，前者不能替代后者。
>
> ### 1.2 LineServices 原生回调的缺失清单（**决定一切的数字**）
>
> 整个 LS 的 P/Invoke 面**只在一个文件里**：`PresentationCore/MS/internal/TextFormatting/LineServices.cs:1407-1618`，**27 条** `[DllImport(DllImport.PresentationNative)]`，解析到 **`PresentationNative_cor3.dll`**（`Shared/RefAssemblyAttrs.cs:69`）。
>
> | 检查 | 结果 |
> |---|---|
> | `wpfgfx_cor3.so` 里存在的 LS 符号 | **0**（`nm -D` 全表比对 128 个名字 → 0 命中） |
> | `libwpfwin32.so` 里存在的 LS 符号 | **1**（`LoGetEscString`，M7b 刚实现：`src/WpfGfx.Linux.Native/src/win32_classification.c:171`） |
> | **LS 文本路径缺口** | **27 − 1 = 26 条** |
> | `PresentationNative` 全体（活的声明） | 128 个名字：**30 存在 / 97 缺失** |
>
> **「110 条」这个数字要更正**（`check-shim-coverage.py` 的口径）：110 = **94 条 LS/FS/NL 族**（`Fs*`55 + `Lo*`22 + `Locbk*`1 + `Nl*`6 + `TextAnalysis*`4 + FS 对象/上下文 6）+ **4 条 Win32 直通包装**（不是 LineServices）+ **11 条 `#if NEVER` 死声明**（工具不求值预处理）+ **1 条误报**（`FindWindowExWrapper`，Unicode 探测序导致）− **1 条已实现**（`LoGetEscString`）。
>
> 每条符号对应的**上游原生实现文件**：**全部 "NOT FOUND"**。见 §②A。
>
> ### 1.3 ⭐ 决定性事实：那套 C++ 不在仓库里
>
> | 证据 | 命令 | 结果 |
> |---|---|---|
> | `LoCreateLine` / `LoDisplayLine` / `LoEnumLine` / `LoCreateContext` / `LoQueryLinePointPcp` / `FsGetBreakOpportunities` / `NlGetGlyphs` 在 C++ 里的出现 | `grep -rl … upstream/ --include=*.cpp --include=*.h` | **0 个文件** |
> | `WpfGfx` 全部 C++ | `find upstream -name "*.cpp" \| wc -l` | 583 个 / 1093 文件 / **398,138 行** —— 覆盖 `core/{hw,resources,geometry,fxjit,uce,av,sw,common,…}`，**没有 text / ls / pts / nl 目录** |
> | `LineServices` / `FS(PTS)` / `NL` 的 C++ | 目录树 + `wpfgfx.def` 导出 + `LSERR`/`LSTXTCFG`/`LSCONTEXTINFO` 关键字 | **0 文件 / 0 行** |
> | 工程文件 | `Microsoft.Dotnet.Wpf.sln:247` → `src\Microsoft.DotNet.Wpf\redist\PresentationNative\PresentationNative.vcxproj` | **该工程缺失**（`redist/` 目录整个不存在） |
> | 有没有编译好的 `PresentationNative_cor3.dll` 可供对拍 | `find / -iname "*PresentationNative*"` | **空** |
>
> **⇒ 路线 A 不是"移植 24 万行 C++ 里的 LS 那部分"，而是"在没有任何参考实现、没有任何 Windows 二进制可对拍的前提下，从零写一个行布局引擎"。** 这直接推翻了 §2.6 里"补齐 LineServices 的 110 条导出"这个措辞背后的成本假设。
>
> ### 1.4 反向方向（原生→托管）也同样空转
>
> `LineServices.cs:36-373` 声明 **28 个委托**；`LineServicesCallbacks.cs`（**3503 行，0 个 DllImport**）通过 `PopulateContextInfo`（`:3295-3325`）把 **26 个**装进 `LsContextInfo`/`LscbkRedefined`，另有 2 个对象处理器（`InlineFormat`/`InlineDraw`，`:3360-3390`）。**没有原生引擎，这 3503 行全是死代码。**
>
> ### 1.5 当前走到哪一步（把三条闸门串起来）
>
> ```
> TextFormatterImp.cs:219 闸门 → SimpleTextLine.Create (SimpleTextLine.cs:78)
>   └ :1665 Typeface.CheckFastPathNominalGlyphs → Typeface.cs:522-562 **闸门 2：TypographyAvailabilities**
>       ├ 通过 → SimpleTextLine.cs:935/:1780 GlyphTypeface.ComputeUnshapedGlyphRun → 出字 ✅
>       └ 拒绝 → SimpleTextLine.cs:1683 return null
>                 → TextFormatterImp.cs:232/241 new TextMetrics.FullTextLine
>                   → FullTextLine.cs:103 → TextStore.cs:73-77 LoGetEscString  ← M7b 已补 ✅
>                   → FullTextLine.cs:215 → TextFormatterContext.cs:113 LoCreateContext ← **缺** ❌
>                     （后面还排着 25 条）
> ```
>
> **闸门 2 是唯一还挡着的**，也是当前"只有派生字体能出字"的原因。
>
> ---
>
> ## ② 两条路线（+ 我加的第三条）的真实代价
>
> ### ②A 路线 A：补齐 LineServices —— **否决**，理由不是"贵"，是"没有源"
>
> | 项 | 实测 |
> |---|---|
> | 要写多少代码 | **94 条活的原生入口**（`Fs*`55 / `Lo*`22 / `Locbk*`1 / `Nl*`6 / `TextAnalysis*`4 / FS 对象·上下文 6）+ **28 个反向委托**（`LineServicesCallbacks.cs` 3503 行要重新对齐）+ 4 条托管 shaping 回调 |
> | 参考实现 | **0 行**（§1.3） |
> | 对拍基准 | **无**（机器上没有任何 `PresentationNative` 二进制） |
> | 碰哪些目录 | 需要一个全新的原生工程；**不能**放进 `upstream/`（只读），只能新建（如 `src/WpfGfx.Linux.Native/ls/`，但那是 M7b 的目录 → 需协调） |
> | 跨运行时 | 指针式 API（`LSCONTEXT`/`PLOLINE`）跨 P/Invoke 边界技术上可行（句柄对托管不透明），但**状态必须活在 .so 那个运行时里** —— 与 `MilFontFaceTable` 同一个坑，只是量级大得多 |
> | 能否复用 MilBridge AOT | 能（把 C# 实现用 `[UnmanagedCallersOnly]` 导出），但那就是"用 C# 重写 LS"，仍属路线 B 的范畴 |
> | **净结论** | **不可行**：没有源、没有基准、入口 94 条、语义（断行/对齐/制表/首尾修饰/惩罚模块/对象处理器）无文档 |
>
> ### ②B 路线 B：HarfBuzz（+ ICU）—— **推荐为目标态**
>
> **依赖可得性（实测，不是查文档）**
>
> | 依赖 | 实测 | 说明 |
> |---|---|---|
> | `libharfbuzz.so.0` | ✅ **在** `/usr/lib/x86_64-linux-gnu/`，版本 **2.7.4**，**395 个导出的 `hb_*` 符号** | ⚠️ **`ldconfig` 这个命令在机器上不存在** —— 我第一遍用 `ldconfig -p \| grep harfbuzz` 得到空，差点得出"没有 HarfBuzz"的错误结论；改用 `ls /usr/lib/x86_64-linux-gnu/` 才发现 |
> | 传递依赖 | ✅ `libglib-2.0.so.0` / `libfreetype.so.6` / `libgraphite2.so.3` 都在 | `readelf -d` 实测 NEEDED |
> | 版本化符号名 | ⚠️ 只有 `libharfbuzz.so.0`，**没有** `libharfbuzz.so`（未装 dev 包）⇒ `DllImport` 必须写全名 `"libharfbuzz.so.0"` | 已实测可用 |
> | 是否需要 ICU 做 Unicode | ❌ **不需要**：`hb_unicode_funcs_get_default` 自带 UCD | `libharfbuzz` 的 NEEDED 里**没有 ICU** |
> | ICU（断行/脚本属性） | ✅ `libicuuc.so.70` / `libicui18n.so.70`，`ubrk_open_70` 等**带版本后缀**的符号齐全 | 见 M6 |
> | 缺什么 | `hb_font_set_synthetic_bold` **无**（HarfBuzz 8.0 才有）⇒ 合成粗体仍由 Skia `SKFont.Embolden` 负责（MilBridge 已实现） | |
> | NuGet/vendored 需要 | **不需要**。两者都是系统库，零新增包、零 vendoring | 对比：`HarfBuzzSharp` 包是可选替代，但没必要 |
>
> **工程代价（我实测到的部分）**
>
> | 项 | 实测 |
> |---|---|
> | 要实现的托管面 | `TextLine` 契约 —— `FullTextLine` 有 **33 个 `public override`**；其中 `Draw`/`GetCharacterHitFromDistance`/`GetTextBounds`/`GetTextRunSpans`/`GetTextLineBreak` 是主入口 |
> | `Lo*` 调用点密度 | 极低：`FullTextLine.cs` **5 处**、`TextFormatterContext.cs` **8 处**，整个 TextFormatting 里每个 `Lo*` 符号只出现 2 次（1 次声明 + 1 次调用） |
> | 可以复用、不用重写的 | `Bidi.cs`（2528 行，已托管已编译）、`TextFormatterImp`（776）、`SimpleTextLine`（2015）、`TextCharacters`/`TextProperties`/`GlyphTypeface`/`FontFaceLayoutInfo` |
> | 跨运行时 | **shaping 侧没有跨运行时问题** —— HarfBuzz 是系统 .so，shaping 在托管 PresentationCore 进程里做（M5 实测）；**轮廓侧**才跨边界，而那已经被 T1 的 `MilFontFace_RegisterFromFile` + `MilGlyphRun_GetGlyphOutline` 打通（M5：13/13 字形拿到真轮廓） |
> | 能否复用 MilBridge AOT | 轮廓侧已经在复用；shaping 侧不需要 |
> | 落地位置 | `build/shims/PresentationCore.*.cs`（既有注入机制）+ provider；`upstream/` 一行不动 |
>
> **代码量估计：1,500–2,500 行**（最小可用：单行 / LTR / 不裁剪 / 不对齐），多行 + 双向 + 对齐 + 裁剪 + 首尾修饰再 +2,000–4,000 行。
> ⚠️ **这是估计，不是实测** —— 见 §③ 末尾。
>
> ### ②C 路线 C（我加的）：把当前的"降级"通用化 —— **建议立刻做**
>
> 现在的降级只对**默认 UI 字体**生效（`build/fonts-ui/UI-NoLayout.ttf`），别的字体仍然撞闸门 2。但**剥离 GSUB/GPOS 这件事本身是可以运行期做的**：
>
> | 项 | 实测/估算 |
> |---|---|
> | 现成的实现 | `build/gen-ui-font.py`（**232 行 Python**）：解析 sfnt 表目录、丢掉 `GSUB`/`GPOS`、重算 checksum 重建 sfnt |
> | C# 移植量 | **~300 行**（纯字节操作，无依赖） |
> | 语义代价 | **零额外损失**：M0 实测 `UI-NoLayout` 与 `NotoSans-Regular` 的 **upem / 字形数（3884）/ 逐字形 hmtx 步进全部一致**，M4 实测它在 HarfBuzz 下的总宽与快路径差 **0.001px** —— 剥离后渲染结果**就是**名义字形结果 |
> | 收益 | 解除"只有默认 UI 字体能出字"这条**产品级限制**；任何字体都能过闸门 2 |
> | 不解决什么 | kerning / 连字 / locl —— 也就是排版正确性 |
>
> ---
>
> ## ③ 路线 B 的关键假设 —— spike 实测（M0–M6，**7/7 通过**）
>
> 工程：`build/MilBridge/tests/HbSpike/`（原始输出 `gen/hbspike-output.txt`；`bash build/MilBridge/run.sh hb` 可复跑）。
> 文本 `"Hello WPF on Linux"` @ NotoSans **24px**；单位统一换算后逐项对照。
>
> | ID | 假设 | 实测 | 结论 |
> |---|---|---|---|
> | **M0** | 对照前提：`UI-NoLayout` 是 `NotoSans-Regular` 的纯 GSUB/GPOS 剥离件 | upem **1000/1000**；glyphCount **3884/3884**；**逐字形 hmtx 步进 3884 个全部一致，不一致 0** | ✅ 对照组合法 |
> | **M1** | HB 管线读数正确（剥离字体无 GPOS ⇒ HB 必须等于 hmtx） | 字形数 18/18；**步进差异 0 处** | ✅ HB 管线可信 |
> | **M2** | GPOS **真的**生效 | 扫 22 对常见 kern 对，**18 对命中**：`r.`Δ−3.840px、`P.`Δ−3.120px、`Ta`Δ−1.920px、`To`Δ−1.680px… | ✅ 字距真在做 |
> | **M3** | GSUB **真的**生效 | `ffi`→**1 字形**/3 字符；`fi`→1/2；`fl`→1/2；`office`→4/6；`affluent`→6/8 | ✅ 连字真在做 |
> | **M4** | shape 结果与快路径**确实不同**（否则没收益） | 真实字体：HB **37 字形 / 快路径 41 字形**，总宽 **Δ=−6.959px**(Regular) / **Δ=−7.055px**(Bold)；降级字体：**Δ=+0.001px** | ✅ 有收益；且证明当前降级=快路径语义 |
> | **M5** | **渲染闭环**：HB 字形 id 能被 MIL 取到轮廓（跨 AOT 边界） | `.so` 侧字体面令牌 `0x20000001`；**13/13 个不同字形成功**，共 **9136 字节**真轮廓 | ✅ 跨运行时链路通 |
> | **M6** | 第二个依赖（UAX#14 断行）可从托管侧调 | ICU 70 `ubrk_open_70`/`ubrk_next_70`：15 个断点，`Hello \| WPF \| on \| Linux, \| long- \| word- \| hyphenation \| and \| 中 \| 文 \| 断 \| 行 \| 测 \| 试` | ✅ 断行可用 |
>
> ### ⚠️ 反面证据一：Windows 对照数据**不覆盖 shaping**
>
> 题目要求"和 Windows 真机的对照数据（`tests/parity/windows/`）比"。**实测：比不了。**
> `tests/parity/windows/` 里全是**场景级渲染对拍**（15 个 scene 的 PNG + DUCE 命令流），
> 没有 glyph id / advance 层面的基准。我扫了 7 个 `.stream`（含 `tests/U1-golden/`）：
> `MilCmdGlyphRunCreate(0x3a)` 只在 2 个文件里各出现 1–2 次、`MilCmdGlyphRunDrawing(0x88)` 7–9 次 ——
> **是场景里的字形资源命令，不是"同一串文本的 DWrite 步进基准"**。
> ⇒ **本轮没有任何 Windows/DWrite shaping 真值可以对拍**；M1–M4 的对照全部是"HB ↔ Skia"内部一致性 + "剥离件 ↔ 基准件"配对对照。
> 要拿到真值，需要在 Windows 上跑一次 `IDWriteTextLayout` 导出 glyph id + advance（或 `dumpbin /exports PresentationNative_cor3.dll` 至少把 LS 面钉下来）。
>
> ### ⚠️ 反面证据二：我自己踩的两个方法学错误（对照实验本身需要被对照）
>
> | # | 错误 | 症状 | 怎么发现的 |
> |---|---|---|---|
> | 1 | 拿 HB 的**未 hint 字体单位步进**去比 SkiaSharp 默认的 **hinted 取整步进** | 18 个字形里 **16 处**"差异"，看着像 shaping 不一致 | Skia 的值**全是整数**（18/14/7…）—— 不可能是字体单位换算的结果。修：`Hinting=None; Subpixel=true` 后 **0 处差异** |
> | 2 | 拿 `NotoSans-**Bold**` 去比 `UI-NoLayout`（派生自 **Regular**） | 每个字形步进都不同，看着像"shaping 差异" | 对照组 M0 直接打脸：两字体 hmtx 本就必须一致，实测却不一致 ⇒ 比错对象。修：改成配对（Regular ↔ UI-NoLayout） |
>
> ### ⚠️ 反面证据三：`docs/unimplemented.md` §2.6 的"正解"两个半边都要改
>
> 现文写：「实现 shaping（HarfBuzz 级 GSUB/GPOS）**或**补齐 LineServices 的 110 条导出」。
> - **"或"不成立**：这两件事**不互斥、也不互相替代**。复杂路径的 shaping 是**托管回调**（`TextAnalyzer.GetGlyphs`/`GetGlyphPlacements`，现为 PNSE），原生 LS 只是回调它们；而 LS 引擎本身（26 条）缺失是**独立的**。只做 HarfBuzz 回调 → 仍然进不去；只补 LS → 拿不到字形。
> - **"110 条"不准**：见 §1.2 的分解（94 + 4，工具口径含 11 条死声明 + 1 条误报 − 1 条已实现）。
> - **"补齐 LineServices"的成本被严重低估**：没有源、没有基准（§1.3）。
>
> ### ❗ 不足以决定的那一条（诚实声明）
>
> **路线 B 的工程量我给不出实测数字。** 我实测到的是：`TextLine` 契约 = 33 个 override、`Lo*` 调用点极稀（13 处）、两个依赖都可调、跨运行时链路已通。但"**1,500–2,500 行**"这个区间是从 `SimpleTextLine.cs`（2015 行）体量**外推**的，不是写出来的。
> **缺的那一条实测**：给 `TextLine` 契约做一个**限时原型**（单行 / LTR / 不裁剪），只实现 `GetTextRunSpans` + `GetTextBounds` + `Draw` 三个 override，用 HarfBuzz run 直接喂给 `GlyphRun`，跑通 `FormattedText` 一次测量+一次绘制。
> - 若原型 ≤ 400 行且能出字 ⇒ B 的成本可控，按阶段做；
> - 若原型就开始碰 `DrawingState`/`TextRunCache`/`TextMetrics` 的连锁 ⇒ B 的成本被低估，应重新评估。
>
> **在拿到这条之前，我不给"B 一定划算"的结论** —— 只给"**A 不可行（已实测）、C 值得立刻做（已实测）、B 是目前唯一有实证支撑的目标态（关键假设 7/7 通过）**"。
>
> ---
>
> ## ④ 对 `docs/unimplemented.md` 的修正建议（**只出文本，我不改那个文件**）
>
> ### ④.1 §2.6 建议替换为（保留原有实测段落，改「正解」与登记口径）
>
> ```markdown
> **正解（独立里程碑，分两步）**：
>
> 第 1 步 · **把降级通用化（低成本，先做）**：把 `build/gen-ui-font.py` 的 GSUB/GPOS 剥离
> 逻辑（232 行 Python）移植成运行期能力（~300 行 C#，纯字节操作），置于 provider 的字体加载路径。
> 收益：任何字体都能过 `Typeface.CheckFastPathNominalGlyphs` 的闸门 2，解除"只有默认 UI 字体能出字"
> 这条产品级限制。语义代价为零额外损失 —— 实测 `UI-NoLayout` 与 `NotoSans-Regular` 的
> upem/字形数(3884)/逐字形 hmtx 步进**全部一致**，HarfBuzz 下的总宽与快路径差 **0.001px**。
> 仍不提供 kerning/连字/locl。
>
> 第 2 步 · **真实 shaping + 行布局（目标态）**：用 **HarfBuzz 2.7.4**（系统 `libharfbuzz.so.0`，
> 395 个导出符号，自带 UCD 不需 ICU；`DllImport` 必须写全名，因为未装 dev 包没有 `libharfbuzz.so`）
> 做 GSUB/GPOS，用 **ICU 70**（`libicuuc.so.70` 的 `ubrk_*_70`，UAX#14）做断行，
> 在**托管侧**实现 `MS.Internal.TextFormatting.TextLine` 的契约（`FullTextLine` 有 33 个
> `public override`），从而**绕开整个 `PresentationNative_cor3.dll`**。
> shaping 侧**没有跨运行时问题**（HarfBuzz 是系统 .so，跑在 PC 进程里）；
> 轮廓侧跨 AOT 边界，已由 `MilFontFace_RegisterFromFile` + `MilGlyphRun_GetGlyphOutline` 打通
> （实测 13/13 字形取到真轮廓，共 9136 字节）。
>
> ⚠️ **不要再写"补齐 LineServices 的 110 条导出"**：那套 C++ **不在本仓库**
> （`Lo*/Fs*/Nl*` 在 `upstream/` 的 0 个 C++ 文件里；`redist/PresentationNative/PresentationNative.vcxproj`
> 整个目录缺失；机器上也没有任何 `PresentationNative` 二进制可对拍）。
> 正确口径见 §2.7。
>
> ⚠️ **shaping 与 LineServices 不互斥、不互相替代**：复杂路径的 shaping 是**托管回调**
> （`TextAnalyzer.GetGlyphs` @ `DirectWriteForwarder.Linux/ManagedSurface.cs:1139`、
> `GetGlyphPlacements` @ `:1150`，现为 PNSE），原生 LS 只是回调它们；
> 而 LS 引擎本身（26 条未实现）是**独立的**缺口。只做 HarfBuzz 回调进不去，只补 LS 拿不到字形。
> ```
>
> ### ④.2 建议**新增 §2.7**（把 LineServices 的数字与"没有源"这件事固定下来）
>
> ```markdown
> ### 2.7 LineServices / PresentationNative 的真实缺口（T1 · 2026-09-10 实测）
>
> **LS 的 P/Invoke 面只在一个文件里**：`PresentationCore/MS/internal/TextFormatting/LineServices.cs:1407-1618`，
> **27 条** `[DllImport(DllImport.PresentationNative)]` → `PresentationNative_cor3.dll`
> （`Shared/RefAssemblyAttrs.cs:69`）。当前状态：
> - `libwpfwin32.so` 已实现 **1** 条（`LoGetEscString`，`src/WpfGfx.Linux.Native/src/win32_classification.c:171`）
> - Linux `.so`（`wpfgfx_cor3.so`）里 **0** 条
> - **文本路径缺口 = 26 条**（`LoCreateContext`/`LoCreateLine`/`LoDisplayLine`/`LoEnumLine`/
>   `LoQueryLinePointPcp`/`LoQueryLineCpPpoint`/`LoCreateBreaks`/`LoCreateParaBreakingSession`/
>   `LoAcquirePenaltyModule`/`CreateTextAnalysisSink`/`GetScriptAnalysisList`/… 逐条见 T1 报告）
>
> **`PresentationNative` 全体**：128 个活名字 → 30 存在 / **97 缺失**
> （= 93 条文本布局引擎族 + 4 条 Win32 直通包装）。
>
> ⚠️ **工具口径「110」要更正**：110 = 94（LS/FS/NL 族）+ 4（Win32 包装）
> + 11（`Pts.cs` 里 `#if NEVER` 的**死声明**，工具不求值预处理）+ 1（`FindWindowExWrapper` 误报，
> Unicode 探测序）− 1（`LoGetEscString` 已实现）。另注：`src/WpfGfx.Linux.Native/bin/exports.txt`
> 相对 `.so` **已过期**（缺 `LoGetEscString`），重跑 `build-shim.sh --symbols` 前不要用它算缺口。
>
> ⚠️ **这些符号没有上游 C++ 实现**：`grep -rl LoCreateLine|LoGetEscString|FsGetBreakOpportunities|NlGetGlyphs
> upstream/ --include=*.cpp --include=*.h` → **0 文件**；`WpfGfx` 的 583 个 .cpp / 398,138 行里
> **没有 text/ls/pts/nl 目录**；`Microsoft.Dotnet.Wpf.sln:247` 指向的
> `redist/PresentationNative/PresentationNative.vcxproj` **整个目录不存在**。
> ⇒ 这条**不是"移植未做"，是"没有可移植的源"**，任何"补齐 110 条"的估算都必须从这个前提出发。
>
> **反向方向同样空转**：`LineServices.cs:36-373` 的 28 个委托、`LineServicesCallbacks.cs`（3503 行，
> 0 个 DllImport）的 26 个回调装配（`:3295-3325`）在没有原生引擎时**全是死代码**。
>
> **落地建议**：见 §2.6 的两步正解；路线取舍的实测依据见
> `build/MilBridge/T1-report.md` 的「M7c4 路线决策报告」节。
> ```
>
> ---
>
> ## ⑤ M7c4 的产物与复现
>
> | 产物 | 说明 |
> |---|---|
> | `build/MilBridge/tests/HbSpike/` | 路线 B spike（M0–M6，7 条对照） |
> | `build/MilBridge/gen/hbspike-output.txt` | spike 原始输出 |
> | `bash build/MilBridge/run.sh hb` | 一键复跑 spike |
>
> **本轮边界**：只在 `build/MilBridge/tests/` 与 `build/MilBridge/` 下新增；`src/`、`build/shims/`、`build/DirectWrite.Linux/`、`build/PresentationCore.Linux/`、`samples/`、`handoff.md`、`verify-all.sh`、`upstream/` **一行未改**；未跑 X、未跑 `verify-all`、未重建 PC。
>
> ---
>

> ## 🔧 M7c3 修复（2026-09-10 晚）—— `MilFontFace_RegisterFromFile` 从托管侧返回 0
>
> **T2 报告的现象**：`registerExport=找到(MilFontFace_RegisterFromFile)` 但
> `nativeAllocations=0` ⇒ 令牌仍由宿主进程内的表发放 ⇒ `.so` 里没有这个令牌 ⇒
> `MilGlyphRun_GetGlyphOutline` 返回 `E_HANDLE` ⇒ **字形轮廓画不出来**。
>
> ### ① 根因（已三条路复现 + A/B/C 对照，不是推测）
>
> **不是**字符串封送、**不是**参数宽度、**不是** `MilFontFaceTable` 未初始化 ——
> 是 **`.so` 运行时找不到自己的依赖库 `libSkiaSharp.so`**。
>
> AOT 镜像里的 SkiaSharp 走运行时 `dlopen("libSkiaSharp")`（**不是** `.so` 的 `DT_NEEDED`），
> 而 M7c3 之前镜像**只有**在托管侧的 `MilCoreDllImportResolver` 跑过一次
> （它调 `MilBridge_SetNativeDir` 注入目录）之后才知道自己在哪。
> T2 的 `FontBridge.ProbeMilExport` 是**直接** `NativeLibrary.TryLoad(<绝对路径>)` 加载 .so 的，
> **完全绕开了解析器** ⇒ `s_nativeDir` 为空、`AppContext.BaseDirectory` 又是宿主应用目录
> （没有 `libSkiaSharp.so`）⇒ `SKTypeface.FromFile` 抛 `DllNotFoundException: libSkiaSharp`
> ⇒ 被 `catch → 0` 吞掉。
>
> **最小复现**：`build/MilBridge/tests/T2Repro/`（逐字照抄 FontBridge 的
> `TryLoad` + `TryGetExport` + `Marshal.GetDelegateForFunctionPointer` + `StringToCoTaskMemUTF8`）。
> 原始输出 `gen/t2repro-output.txt`。A/B/C 三条对照把因果钉死：
>
> | 场景 | `s_nativeDir` 注入 | `libSkiaSharp` 可寻 | 令牌 |
> |---|---|---|---|
> | **A** T2 姿势（不经 resolver、无 `LD_LIBRARY_PATH`） | ❌ | ❌ | **`0x0`** ← 复现 |
> | **B** 先走一次 MilCore 的 `[DllImport]`，再按 T2 姿势 | ✅ | ✅ | `0x20000001` |
> | **C** T2 姿势 + `LD_LIBRARY_PATH=<publish 目录>` | ❌ | ✅ | `0x20000001` |
>
> ### ② 修法：让 .so **自己**定位自己（`dladdr`）
>
> `build/MilBridge/src/MilBridge.Linux/NativeSearchPath.cs`：
> 对**自己的某个 `[UnmanagedCallersOnly]` 导出**取地址 → `dladdr` → 得到本 `.so` 的路径
> → `libSkiaSharp.so` 就相对这个目录找。**与宿主无关、与调用顺序无关**，
> 托管宿主和纯 C 宿主一视同仁。
>
> `Candidates()` 现在的顺序：① 托管注入目录 → ② **dladdr 自定位目录（新）** →
> ③ 宿主应用目录 → ④ `runtimes/linux-x64/native`。
>
> **实测令牌值**（`build/fonts/NotoSans-Regular.ttf`，**T2 的调用姿势、零环境变量**）：
>
> ```
> [probe] registerExport = 找到(MilFontFace_RegisterFromFile)
> [state] MilCoreDllImportResolver.IsLoaded = False    ← 解析器确实没跑过
> [call]  MilFontFace_RegisterFromFile(".../NotoSans-Regular.ttf", 0, 0) = 0x20000001
> ```
>
> 副作用（**顺手修掉了上一轮登记的缺口**）：纯 C 宿主不再需要 `LD_LIBRARY_PATH` ——
> 之前"不带就全返回 0x0"的那条限制**没了**。
>
> ### ③ 跨运行时闭环（T2 姿势，经真 C ABI）
>
> ```
> [cross-runtime] 令牌交给 .so 内的 MilGlyphRun_GetGlyphOutline
>   hr=0x00000000 size=800 bytes fillRule=1   ✅ 跨运行时接通（真轮廓）
>   对照：伪造令牌 hr=0x80070006（期望 E_HANDLE）
>   释放轮廓缓冲 hr=0x00000000
> ```
>
> ### ④ 新诊断导出（T2 ask #4；把"返回 0"从黑盒变成可查）
>
> | 导出 | 签名 | 语义 |
> |---|---|---|
> | `MilBridge_Diag_LastFontFaceError` | `int(void)` | 最近一次失败码；`0` = 无失败 |
> | `MilBridge_Diag_LastFontFaceErrorMessage` | `const char*(void)` | 失败详情（UTF-8，**静态缓冲，不要 free**）；无失败时 `NULL` |
> | `MilBridge_Diag_ResetFontFaceError` | `void(void)` | 清掉记录（测试/诊断用） |
> | `MilBridge_Diag_SelfDirectory` | `const char*(void)` | dladdr 自定位到的 .so 目录（静态缓冲） |
>
> 失败码（`MilFontFaceDiagnostics.Failure`）：
> `0 None · 1 NullPath · 2 EmptyPath · 3 PathTooLong · 4 InvalidUtf8 ·
> 5 FileNotFound · 6 NegativeFaceIndex · 7 TypefaceLoadFailed · 8 Exception`
>
> **实测诊断矩阵**（每条失败路径都能说出原因；`gen/t2repro-output.txt`）：
>
> | 用例 | 返回 | code | 文本 |
> |---|---|---|---|
> | 文件不存在 | `0x0` | `5 FileNotFound` | `/nonexistent/NoSuchFont.ttf` |
> | `faceIndex < 0` | `0x0` | `6 NegativeFaceIndex` | `faceIndex=-1` |
> | `faceIndex` 越界 | `0x0` | `7 TypefaceLoadFailed` | `SKTypeface.FromFile 返回 null：... faceIndex=9999` |
> | `NULL` 路径 | `0x0` | `1 NullPath` | `utf8Path == NULL` |
> | 空串 | `0x0` | `2 EmptyPath` | `空路径` |
> | 非法 UTF-8（真 0xFF 字节） | `0x0` | `8 Exception` | `System.Text.DecoderFallbackException: ...` |
> | 成功 | `0x20000001` | `0 None` | `(null)` |
>
> > 有了这一条，**T2 当初那次失败会直接显示 `code=8(Exception)` +
> > `System.DllNotFoundException: DllNotFound_Linux, libSkiaSharp, ...`** ——
> > 一眼定位，不用再猜。
>
> ### ⑤ 回归 + `nm -D` 变化
>
> | 门禁 | 结果 |
> |---|---|
> | 闭环 `tests/ClosedLoop` | **46 / 46 全绿** |
> | `Commands.Tests` | **562 / 562 全绿** |
> | `src/WpfGfx.Linux` / `MilBridge.Linux` 构建 | **0 错 0 警** |
> | T2Repro（T2 姿势，零环境变量） | **通过**（令牌 `0x20000001` + 800 字节轮廓） |
> | 纯 C 探针（零环境变量） | **通过**（`0x20000001`；修前是全 `0x0`） |
>
> | `nm -D` | 值 |
> |---|---|
> | MIL ABI 导出（清单口径） | **109**（未变；SIL 面没动） |
> | 诊断面 `MilBridge_*` | 10 → **14**（+4：LastFontFaceError / LastFontFaceErrorMessage / ResetFontFaceError / SelfDirectory） |
> | 总 `T` 符号 | 121 → **125** |
> | 缺失 | **0** |
>
> | .so | 值 |
> |---|---|
> | 大小 | 4,213,584 → **4,519,360 B** |
> | **SHA256** | **`fa70a21b91bda6f2a821f4146174458f0a37d71a409b1713faaf2efa8d172c5e`** |
> | 发布 | `-m:1`，**一次成功，9.9s**，未重跑 |
>
> ### ⑥ 给 T2 的结论
>
> **T2 的调用侧没有问题，不用改**：`Marshal.StringToCoTaskMemUTF8` + `Cdecl` 委托 +
> `(IntPtr, int, int)` 的参数形状与我这边的 `[UnmanagedCallersOnly(byte*, int, int)]` 严格匹配。
> 唯一的问题是 .so 侧的依赖库定位，已在本轮修掉 —— **T2 重新拉一次新 .so 即可，无需改代码**。
> 建议 T2 在 `FontFaceBridge.RefreshDiagnostics()` 里顺带回读
> `MilBridge_Diag_LastFontFaceError`，失败时把原因码打进诊断串（可选）。
>
> ---
>

> ## 📌 追加交付（2026-09-10 下午）—— 两处改动，**同一次 .so 重建**
>
> 本节是第二次交付的**全部证据**；下面 §1–§6 是第一次交付（机制选型 + 108 导出）的原文，
> 其中的「108」在本次之后应读作「108 上游 + 1 自有 = **109**」。
>
> ### 变更 1 · `MilChannel_SetNotificationWindow`：E_NOTIMPL → **真实现**（State 档）
>
> M7c 定位：`MediaContext.CreateChannels() → HookNotifications() →
> MediaContextNotificationWindow.SetAsChannelNotificationWindow()` 是**任何 WPF 应用
> 启动路径的必经点**，返回 E_NOTIMPL ⇒ `HRESULT.Check` 抛 NotImplementedException。
> **必须在 .so 侧落地**（P/Invoke 由 AOT 包装承接，只改托管源码不生效 —— M7c 实测）。
>
> 语义（落点 `src/WpfGfx.Linux/Interop/MilNative.NotificationWindow.cs`）：
>
> | 入参 | 结果 |
> |---|---|
> | `pChannel` 无法解析 | `E_HANDLE` `0x80070006` |
> | `hwnd == 0` | **解绑**；`S_OK`，**幂等**（未登记过也 S_OK） |
> | `hwnd != 0` 且 `message == 0` | `E_INVALIDARG` `0x80070057` |
> | `hwnd != 0`（含同值重复登记） | **登记 / 覆盖登记**；`S_OK`（`SetCount` 累加，不产生第二条记录） |
>
> 另：`MilConnection_DestroyChannel` 会随之摘掉该通道的登记（句柄单调不复用，不摘会永久悬挂）。
> `MilNative.ExportManifest` 里该条 `NotImpl → State`；于是 **State 11→12、NotImpl 29→28**。
>
> **不真的 `PostMessage`**（刻意，非偷懒）：本工程 DUCE 传输从 M7a 起是**进程内**的
> （`MilChannelBackChannel` 队列 + `MilComposition_PeekNextMessage` 出队），通道 MarshalType 恒为
> `SameThread` —— 同线程呈现下"入队即送达"，没有需要唤醒的线程。上游 Windows 版那条
> `::PostMessage` 的唯一理由是**跨线程传输**。跨线程的唤醒落点已预留：
> `MilChannelBackChannel.Post` → `MilChannelNotificationRegistry.OnBackChannelPosted`，
> 后者在 SameThread 下**什么都不做**、计数器恒 0（有测试钉住，不假装唤醒过）。
>
> ### 变更 2 · 新增导出 `MilFontFace_RegisterFromFile`（跨运行时字体面登记）
>
> T2 实测发现的**跨运行时边界**：T1 之后 MIL 跑在 NativeAOT 共享库 = **另一个 .NET 运行时**，
> `MilFontFaceTable` 的静态状态与宿主进程各一份 → 托管侧直接 `Register` 只写进一个
> `.so` 永远看不见的副本（`status=ProcessLocalOnly`，字形轮廓画不出来）。跨得过去的只有 **C ABI**。
>
> 契约（实现落点 `src/WpfGfx.Linux/Interop/MilNative.FontFace.cs`）：
>
> ```c
> intptr_t MilFontFace_RegisterFromFile(const char* utf8Path, int32 faceIndex, int32 simFlags);
> // 非 0 = .so 运行时内的字体面令牌；0 = 失败（**不是 HRESULT**）
> ```
>
> | 失败条件 | 返回 |
> |---|---|
> | `utf8Path == NULL` / 空串 / 长度 ≥ 32768 / **非法 UTF-8**（严格解码，不做 U+FFFD 替换） | 0 |
> | 文件不存在 | 0 |
> | Skia 无法解析（含 Skia 抛异常） | 0 |
> | `faceIndex < 0` 或越界 | 0 |
>
> **绝不抛异常穿 ABI**（全部 `try/catch → 0`）。
> `simFlags` = DWrite `DWRITE_FONT_SIMULATIONS`：`1 = Bold`、`2 = Oblique`；
> 高位未知位不报错、原样记录（`MilFontFaceTable.TryGetSimFlags` 可查），生效的只有这两位。
> **施加点**：`MilGlyphRun_GetGlyphOutline` 里 `font.Embolden` / `font.SkewX = -0.25f`
> —— `simFlags` 不是空参数（有测试钉住 Bold 轮廓 ≠ 普通轮廓）。
>
> **实测令牌值（`build/fonts/NotoSans-Regular.ttf`）**
>
> | 调用 | 令牌 |
> |---|---|
> | `RegisterFromFile(path, 0, 0)` | **`0x20000001`** |
> | `RegisterFromFile(path, 0, 1)` (Bold) | `0x20000002` |
> | `RegisterFromFile(path, 0, 2)` (Oblique) | `0x20000003` |
> | 文件不存在 / `faceIndex=-1` / `faceIndex=999` / `NULL` 路径 / 空串 | 全部 `0x0` |
>
> **两条独立验证路径都把上面的值跑出来了**：
> 1. 托管侧经真 P/Invoke（闭环 F 组）。
> 2. **完全不经过 .NET** 的纯 C 探针（`dlopen` + `dlsym`，见下 §8）。
>
> ### 本次 .so 重建证据
>
> | 项 | 值 |
> |---|---|
> | 发布命令 | `dotnet publish -c Release -r linux-x64 -m:1 -p:NativeLib=Shared -p:PublishAot=true -p:ArtifactsPath=build/MilBridge/.artifacts` |
> | 耗时 | **13.9s**（热，一次成功，未重跑） |
> | 产物 | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` |
> | 大小 | **4,213,584 B**（改前 4,105,312 B，+108,272 B） |
> | **SHA256** | **`8026c4db9db2a263f49a2e8b487ff4a07b2fa8952f9210657131c5dd0ec759c0`** |
>
> `nm -D` 前后对比（`gen/export-symbols.txt` 对拍，缺失 0）：
>
> | | 改前 | 改后 |
> |---|---|---|
> | 清单导出名 | 108 | **109** |
> | `.so` 里实到 | 108 | **109**（缺失 **0**） |
> | `nm -D` 总 `T` 符号 | 118 | **121**（109 导出 + 10 诊断 + 2 运行时） |
> | `MilChannel_SetNotificationWindow` | `T ...@@V1.0`（返回 E_NOTIMPL 常量） | 同一符号，**行为已变**（B5 实测 `S_OK`） |
> | `MilFontFace_RegisterFromFile` | 不存在 | **`0000000000133230 T MilFontFace_RegisterFromFile@@V1.0`** |
>
> ### 回归
>
> | 门禁 | 结果 |
> |---|---|
> | 闭环 `tests/ClosedLoop` | **46 / 46 全绿**（原 40 + 新增 F 组 6 条；B5 由"期望 E_NOTIMPL"改为新语义断言） |
> | `Commands.Tests` | **562 / 562 全绿**，连跑 **3 次一致**（基线 552：−1 旧断言 +13 新用例） |
> | `src/WpfGfx.Linux` 构建 | **0 错 0 警** |
> | `MilBridge.Linux` 构建 | **0 错 0 警** |
> | app-local `/tmp` 部署（模拟 M7c runner） | **46 / 46 全绿**，零环境变量 |
>
> ### ⚠️ `.so` 部署位置（M7c Phase 2 runner 必须知道的一行）
>
> **把 `wpfgfx_cor3.so` 和 `libSkiaSharp.so` 两个文件一起放进 HelloWpf 的**应用目录**（`HelloWpf.dll` 同级）。**
> M7c 的 runner 在 `/tmp` 下 app-local 部署，那时解析器的「开发树回退」档失效，
> **只有"应用目录"这一档可用**；而 `.so` 一旦在应用目录被找到，AOT 镜像内部的 SkiaSharp
> 就**只在该目录**找 `libSkiaSharp.so`（目录由 `MilBridge_SetNativeDir` 注入）——
> 只拷 `.so` 不拷 `libSkiaSharp.so` 会得到 `DllNotFoundException: libSkiaSharp`。
> 已实测：`/tmp/mb-deploy` 里两个文件 + `ClosedLoop` 产物，**零环境变量 46/46 全绿**。
> 备选：`MILBRIDGE_MILCORE_DIR=<含这两个文件的目录>`。
>
> ---
>

> 目标：让托管层 108 条 `[DllImport("wpfgfx_cor3.dll")]` 在 Linux 上真正调到
> `src/WpfGfx.Linux/` 的 C# 实现。M2（HelloWpf 跑起来）的最后一道硬关口。
>
> 结论：**机制已打通并端到端验证（闭环 40/40 通过），108 个导出全部铺开，
> 符号 108/108 实到，零缺失。推荐路线 A（NativeAOT 共享库 + DllImportResolver）。**
>
> 本轮**只写 `build/MilBridge/`**，未改任何共享文件；接线清单在第 4 节，由主控串行落地。

---

## 1. 机制结论：两条路线实测对比

### 1.1 路线 A —— NativeAOT 共享库 + `SetDllImportResolver`（**推荐**）

`wpfgfx_cor3.so`（NativeAOT `NativeLib=Shared`）导出 108 个 C ABI 符号；
托管层 108 条 `[DllImport]` **一个字都不改**，只加一个解析器把库名重定向过去。

### 1.2 路线 B —— 编译期替换（把 `[DllImport]` 换成对 `MilNative` 的托管直调）

探针工程：`build/MilBridge/alt-route-b/ProbeB/`（原始诊断：`gen/route-b-diagnostics.txt`）。

### 1.3 实测对比表（全部是实测数字，非推断）

| 维度 | 路线 A：NativeAOT .so + resolver | 路线 B：编译期替换直调 |
|---|---|---|
| **覆盖全部 108 个导出** | ✅ **108/108**（`nm -D` 对拍，缺失 0） | ⚠️ 需改 **10 个源文件**、**108 个调用点**；其中 `Common/Graphics/exports.cs`(2537 行)、`wgx_exports.cs`(344 行) 是 **`<Compile Include="$(UpstreamWpfRoot)…">` 直接从 `upstream/` 编进来的** —— 要么改 `upstream/`（违反只读纪律），要么 fork 这 2881 行 |
| **对托管层的改动面** | **新增 1 个文件**（`MilCoreDllImportResolver.cs`，加进 shims 清单）+ 在既有 `Win32ShimResolver.Resolve` 里加 **3 行** | 10 个文件 × 108 处调用点重写；`PresentationCore.Linux.csproj` 加 `ProjectReference` |
| **是否符合「对上游零改动」** | ✅ 完全符合。上游 10 个文件逐字编译，一个字符都没动 | ❌ 直接违背 handoff 决策 3「接入点收敛到一个文件」「严禁散弹式修改托管层其他文件」 |
| **实测编译结果** | 0 错 0 警（`MilBridge.Linux`），AOT 发布 0 错 | 朴素写法 **7 个编译错误**（5 类）；适配后 0 错，但另出 **CS8002 警告** |
| **实测阻塞** | 无（唯一坑是 `libSkiaSharp` 搜索路径，已解决，见 §3.4） | ① `DUCE.ResourceHandle` **类型同一性**：PC 的 `System.Windows.Media.Composition.DUCE.ResourceHandle` 与 `WpfGfx.Linux.Interop.DUCE.ResourceHandle` 是两个类型 → CS1503（by value 与 ref 都中）<br>② `MilMatrix3x2D*` → `double*` → CS1503<br>③ `WindowMessage` → `uint` → CS1503<br>④ `out bool` → `out int` → CS1503<br>⑤ `DUCE.ResourceType` → 另一个 `DUCE.ResourceType` → CS1503 |
| **强名称** | 不涉及（PC 不引用 WpfGfx.Linux） | PC 是 `SignAssembly+PublicSign`，引用未签名的 `WpfGfx.Linux` → **warning CS8002**（不是错误），会让 PC 从「0 警」退化 |
| **`PreserveSig=false` 语义** | ✅ **自动正确**：CLR 按上游声明照旧「失败即抛」，包装返回 HRESULT 即可 | ❌ 需在 **3 处**调用点手写 `if (hr<0) Marshal.ThrowExceptionForHR(hr)`，漏一处就是**失败被静默吞掉** |
| **构建产物 / 成本** | `wpfgfx_cor3.so` **4,105,312 B（4.0 MB）** + `libSkiaSharp.so` 9.2 MB；发布 **29s 冷 / 11s 热**（3 核，`-m:1`） | 无新增产物，但 PresentationCore 每次全量重编（1348 个源文件） |
| **调试体验** | 两侧都是 C#，`wpfgfx_cor3.so.dbg` 带完整符号 | 两侧也都是 C#，同进程调试更直接 ✔ |
| **风险** | ① AOT 裁剪要显式 root（已用 `TrimmerRootAssembly`，见 §3.5）② 多一个 ~44 MB 运行时镜像（4.0 + 9.2 + …） | ① 逐点手工适配 108 处，**语义漂移风险高**（尤其 PreserveSig、`byte[]` 拷贝方向、委托 ABI）② 与上游 `exports.cs` 的 fork 长期漂移 |

### 1.4 推荐：**路线 A**，理由（按权重排序）

1. **它是唯一覆盖 108/108 且不需要动 `upstream/` 的方案。** 路线 B 的 55 条（`exports.cs` 19 + `wgx_exports.cs` 28 + `Composition.cs` 8）里，47 条所在的两个文件是上游原文直编，任务书里说的「把我们控制的编译列表里…换成同名同签名的本地实现」在这两个文件上**不成立** —— 它们不在我们的编译列表里，`$(UpstreamWpfRoot)` 直接指向上游树。
2. **它是唯一不破坏 `PreserveSig=false` 语义的方案。** 3 条这类声明（`MilUtility_CopyPixelBuffer` / `MILSwDoubleBufferedBitmapGetBackBuffer` / `AddDirtyRect`）在路线 B 下必须手写异常转换，而这是**静默失败**类的坑。
3. **它把「类型映射」这件事从 108 个调用点挪到了 1 个地方。** 上游的 `SafeMILHandle`/`MilMatrix3x2D*`/`WindowMessage` 等类型差异，在 ABI 层面是**逐字节等价**的（`docs/unimplemented.md` §2.5 那张表），所以 P/Invoke 路径天然不需要转换；路线 B 却要在每个调用点显式转。
4. 唯一的代价是产物体积（4.0 MB + Skia 9.2 MB）与 AOT 发布步骤 —— 相对上面三条是次要的。

**路线 B 的合理用途**：如果将来出现「必须单进程、不能带 NativeAOT 运行时」的约束，或者只需要替换少数几个导出时，路线 B 才划算。它的适配写法已在 `alt-route-b/ProbeB/AdaptedCallSites.cs` 里逐条给出（6 类适配），可直接复用。

---

## 2. Phase 1 证据

### 2.1 Phase 1-A：NativeAOT 导出机制（spike）

| 项 | 值 |
|---|---|
| 工程 | `build/MilBridge/spike/AotLib/`（2 个函数：`aotspike_add` 返回 int、`aotspike_sum_bytes` 收 `byte*`、`aotspike_identity` 写托管静态状态） |
| 构建命令 | `dotnet publish -c Release -r linux-x64 -m:1 -p:NativeLib=Shared -p:PublishAot=true` |
| 构建耗时 | **28.0s**（含 12.3s restore；user 12.2s / sys 3.6s） |
| 产物 | `aotspike.so` **838,624 B（820 KB）** + `aotspike.so.dbg` 1,980,136 B |
| `nm -D` 符号 | `T aotspike_add@@V1.0` / `T aotspike_sum_bytes@@V1.0` / `T aotspike_identity@@V1.0`（共 5 条 dynsym） |
| 文件类型 | `ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, stripped` |

闭环（`spike/SmokeTest/`，普通托管控制台 + `[ModuleInitializer]` + `SetDllImportResolver`）：

```
  PASS  A1 默认探测 wpfgfx_cor3.dll 必失败   threw=True DllNotFoundException
  PASS  A2a [DllImport] -> AOT .so: Add(40,2)  got 42, resolverCalls=1
  PASS  A2b AOT 库内托管状态往返              got 1234
  PASS  A3  byte* 参数逐字节读                sum=28 expect=28
  PASS  A3b null 指针走错误路径               hr=0x80070057
== 通过 5 / 失败 0 ==
```

> 关键：**先用 `NativeLibrary.Load("wpfgfx_cor3.dll")` 证明不加 resolver 必然
> `DllNotFoundException`**，再加 resolver 证明能调到 —— 否则"成功"没有说服力。

### 2.2 Phase 1-B：13 个 DUCE 导出的 AOT 包装 + **可见性实测结论**

**可见性问题的实测答案：`InternalsVisibleTo` 和 public 门面都不需要。**

- `MilNative` 已是 `public static unsafe partial class`，**108 个导出方法全部是 `public static`**，
  参数类型也全部是 public（M7a 被 CS0051 逼出来的）。
- 实测：`MilBridge.Linux.csproj` 只写一行 `<ProjectReference Include="…/WpfGfx.Linux.csproj" />`，
  直接 `MilNative.MilResource_CreateOrAddRefOnChannel(...)`，**0 错 0 警通过**。
- 因此本工程**没有** `InternalsVisibleTo`、**没有**任何门面/adapter 类型。
  唯一的代价：`MilUtility_*` 的矩阵参数是 `double*` 而不是 `MilMatrix3x2D*`（同 §2.5 说明）。

内容物：

| 文件 | 作用 |
|---|---|
| `src/MilBridge.Linux/MilBridge.Linux.csproj` | `PublishAot` + `NativeLib=Shared` + `AssemblyName=wpfgfx_cor3` |
| `src/MilBridge.Linux/Exports.g.cs` | **108 个** `[UnmanagedCallersOnly(EntryPoint=…)]` 包装（生成器产出） |
| `src/MilBridge.Linux/Diagnostics.cs` | 8 个 `MilBridge_Diag_*` 导出（**不属于 MIL ABI**，闭环测试用） |
| `src/MilBridge.Linux/NativeSearchPath.cs` | AOT 镜像内 `MilBridge_SetNativeDir` + SkiaSharp 解析器（见 §3.4） |

### 2.3 Phase 1-C：闭环断言（`tests/ClosedLoop/`，**40 / 40 通过，退出码 0**）

原始输出：`gen/closed-loop-output.txt`。运行方式（**刻意不设 `LD_LIBRARY_PATH`**）：

```
cd build/MilBridge/.artifacts/bin/ClosedLoop/release && dotnet MilBridge.ClosedLoop.dll
```

测试扮演「模拟托管层」：声明形状逐字照抄上游 `exports.cs` / `UnsafeNativeMethodsMilCoreApi.cs`，
库名就是 `wpfgfx_cor3.dll`。

**A 组 · 机制（6 条）**

| ID | 断言 | 实测 |
|---|---|---|
| A1 | 无 resolver 时 `wpfgfx_cor3.dll` 默认探测失败 | `DllNotFoundException` ✅ |
| A2 | resolver 把库名指向 AOT .so | `TryResolve → True, handle=0x608FD5EBEBD0, IsLoaded=True` |
| A3 | `MilNative.ExportManifest` == 108 | `got 108` |
| A4 | `MissingExports()` 在 AOT 镜像内为空（裁剪没裁掉） | `missing = 0` |
| A5 | `NotImplExportNames` 计数 | `got 29`（与 M7a 台账一致） |
| A6 | `CreateChannel` 后 .so 内通道表 +1 | `handle=0x10000001, count 0→1` |

**B 组 · 通道语义 / HRESULT（8 条）** — 含 **3 条 E_HANDLE 错误路径**

| ID | 断言 | 实测 HRESULT |
|---|---|---|
| B1 | `GetMarshalType(有效通道)` → S_OK + SameThread(1) | `0x00000000 / 1` |
| B2 | `GetMarshalType(0xDEADBEEF)` → **E_HANDLE** | `0x80070006` |
| B3 | `CreateChannel(参考通道=伪句柄)` → **E_HANDLE** | `0x80070006` |
| B4 | `CloseBatch` 干净批次 → S_OK | `0x00000000` |
| B5 | `SetNotificationWindow` → E_NOTIMPL（M1 台账既有缺口） | `0x80004001` |
| B6 | `DestroyChannel` 后同一句柄 → **E_HANDLE**（句柄值**不复用**） | `0x00000000 → 0x80070006` |
| B7 | `CreateChannel(参考通道=有效)` → 共享分区 | `sibling=0x10000003` |
| B8 | `WgxConnection_SameThreadPresent(0)` → S_OK | `0x00000000` |

**C 组 · 资源表（8 条，全部经真 ABI 观测）**

| ID | 断言 | 实测 |
|---|---|---|
| C1 | `CreateOrAddRef(TYPE_VISUAL, 空)` → S_OK + 新句柄 | `handle=0x00000001` |
| C2 | `GetRefCount` → RefCount == 1 | `1` |
| C3 | 再次 `CreateOrAddRef` → AddRef, RefCount == 2 | `2` |
| C4 | `ReleaseOnChannel` → deleted=0, RefCount 2→1 | `0 / 1` |
| C5 | `GetRefCount(伪通道)` → E_HANDLE | `0x80070006` |
| C6 | `DuplicateHandle` **跨分区** → E_INVALIDARG | `0x80070057` |
| C7 | `DuplicateHandle` 同分区 → S_OK，目标通道 RefCount ≥ 1 | `dup=0x00000001 rc=1` |
| C8 | `ReleaseOnChannel(不存在句柄)` → E_HANDLE | `0x80070006` |

**D 组 · 命令闭环（12 条）—— 本任务的核心**

| ID | 断言 | 实测 |
|---|---|---|
| D1 | `BeginCommand(8B 头, cbExtra=16)` + `AppendCommandData(16B)` + `EndCommand` + `Commit` 全 S_OK | `0/0/0/0` |
| **D2** | **`channel.CommittedCommands == 1`** | **`value=1`** ✅（经 .so 内反射读，见 §3.5） |
| D3 | `MilResource_SendCommand` 整条 24B 命令一次发出 → S_OK | `0x00000000` |
| D4 | `SendCommand(null,…)` / `SendCommand(…,cbSize=0)` → E_INVALIDARG | `0x80070057 / 0x80070057` |
| D5 | `SendCommand(E_NOTIMPL 命令 0x0a)` → E_NOTIMPL | `0x80004001` |
| **D6** | **`channel.NotImplCommands == 1`** | **`value=1`** ✅ |
| D7 | 命令短于 `FixedSize` → E_INVALIDARG（dispatcher 长度校验） | `0x80070057` |
| D8 | 嵌套 `BeginCommand` → E_UNEXPECTED | `0x8000FFFF` |
| D9 | 未 `EndCommand` 就 `Commit` → E_UNEXPECTED | `0x8000FFFF` |
| D10 | `AppendCommandData` 超出 `cbExtra` → E_INVALIDARG | `0x80070057` |
| **D11** | **真实命令字节 `MilCmdChannelDeleteResource` 被既有 `MilCommandDispatcher` 解码执行** → 资源从通道表消失 | `commit=0`，`GetRefCount(after)=0x80070006`（before rc=1） |
| D12 | 对照：Type@0 正确但 Handle 错位到 offset 8 → 资源**仍在** | `commit=0`，`refCount=1` |

> D11/D12 是**纯 ABI 可观测**的状态突变证据：不需要读 `CommittedCommands`，
> 只靠 `MilResource_GetRefCountOnChannel` 的前后差异就证明「命令字节真的进了
> 既有 dispatcher 并被执行」。这比读计数器更强。

**E 组 · 结构体参数的逐字节布局（6 条）**

| ID | 断言 | 实测 |
|---|---|---|
| E1 | **`MILCMD` 头 = `Type@0(u32)` / `Handle@4(u32)` / 总宽 8** | 由 D11（Handle@4 → 资源消失）与 D12（Handle 错位到 offset 8 → 资源保留）**差分证明** |
| E2a | **`MilMatrix3x2D` 以 `double*` 传（6×8=48B）**被接受 | `cPieces(identity)=4, cPieces(translate)=4` |
| E2b | **offset 32/40 的 DX/DY 被当成平移**（逐点 Δ=(100,200)，容差 1e-4） | 4 点全部命中，**最大偏差 7.629E-006** |
| E2c | 100 写 **offset 16（S_21 槽）** ≠ 写 **offset 32（DX 槽）** → DX **只在 offset 32** 被读 | 错位矩阵首点 `(-292.92, -2.66)`，与平移结果不可互换 |
| E3 | `DUCE.ResourceHandle` by value = 4 字节 | C1/C3/C6/D11 全部 by-value 4B 传递无错位 |
| E4 | `MilPoint`/`MilSize` 按值 16 字节（2×double） | E2a 的 ptStart/rRadii/ptEnd 按值传递且数值正确 |

> **诚实备注（E2b 的 7.6e-6 偏差）**：`MilGeometryEngine.ArcToBezier` 把 `double` 矩阵
> 转成 Skia 的 **float** `SKMatrix` 再调 `sk_matrix_map_xy`，所以输出只有 float 精度。
> 这是**内层实现的保真度问题，不是桥接问题**（`double*` 的 48 字节确实逐偏移正确读到了）。
> 已在 `docs/unimplemented.md` 的语义存疑清单里，建议后续 milestone 用 double 直算替换 Skia 变换。

### 2.4 AOT 库的大小与构建命令

```
dotnet publish -c Release -r linux-x64 -m:1 -p:NativeLib=Shared -p:PublishAot=true -p:ArtifactsPath=build/MilBridge/.artifacts
```

| 产物 | 大小 |
|---|---|
| `wpfgfx_cor3.so` | **4,105,312 B（4.0 MB）** |
| `wpfgfx_cor3.so.dbg` | 4,858,392 B |
| `libSkiaSharp.so`（NativeAssets.Linux 带出） | 9,244,960 B |
| 构建耗时 | 冷 29.2s / 热 11.2s（3 核，`-m:1`） |

### 2.5 符号对拍

```
nm -D --defined-only wpfgfx_cor3.so | sed 's/.* T //; s/@@.*//' | sort -u
```
- 清单 `gen/export-symbols.txt`：**108** 个
- `.so` 实到：**108**（另有 8 个 `MilBridge_Diag_*` 诊断符号 + 2 个 AOT 运行时符号）
- **缺失：0**

---

## 3. Phase 2 状态

| 项 | 值 |
|---|---|
| 按 `MilNative.ExportManifest` 铺开的导出 | **109 / 109**（上游 108 + 本工程自有 1，见顶部追加交付） |
| 落地方式（AOT 包装） | **109**（其中 **10 条** 含显式类型适配：`byte[]`×2、`string`(BSTR)×1、委托×4、`PreserveSig=false`×2、`IntPtr[]`×1） |
| `.so` 实到符号 | **109 / 109**（缺失 0） |
| 实现深度分布 | Real **61** · NotImpl **27** · State **12** · Identity **9**（唯一真值来源 `gen/landing-table.md`，见 `tools/check-export-numbers.py`） |
| 符号清单文件 | `build/MilBridge/gen/export-symbols.txt`（109 行） |
| 「每个导出的落地方式」表 | `build/MilBridge/gen/landing-table.md`（109 行，逐条给实现深度 + 内层实现文件） |
| 上游声明原始扫描 | `build/MilBridge/gen/milcore-dllimports.json`（110 条属性 / 108 导出名 / 105 方法名） |

复现：`bash build/MilBridge/run.sh`（gen → AOT publish → 符号对拍 → 闭环）。

---

## 4. 接线清单（**给主控串行执行**，本轮未做）

需要改 **2 个共享文件**、加 **1 行到 shims 清单**、复制 **2 个产物**。

### 4.0 前置（重要，先读）

- PresentationCore.Linux 里 **已经有一个 `[ModuleInitializer]` + `SetDllImportResolver`**：
  `build/shims/Win32ShimResolver.cs`（M7b）。
  `SetDllImportResolver` 对同一程序集**只能调用一次**，且 `Win32ShimResolver.Register`
  **没有 catch** —— 所以**绝不能让第二个自装器进 PresentationCore**，
  否则谁先跑谁赢，输的那个抛未捕获异常 → 模块初始化失败。
  因此 `build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs`
  **刻意不含 `[ModuleInitializer]`**，只提供 `TryResolve`；自装器在另一个文件
  （`MilCoreStandaloneInstaller.cs`），**只给独立宿主用，不要加进 shims 清单**。

### 4.1 `build/shims/PresentationCore.shims.txt` —— 追加 1 行（**原文**）

在文件末尾追加：

```
# T1：MilCore 导出桥接 —— 把 108 条 [DllImport("wpfgfx_cor3.dll")] 解析到
#   NativeAOT 实现 build/MilBridge/（产物 wpfgfx_cor3.so）。
#   注意：**不要**加 MilCoreStandaloneInstaller.cs —— PC 已有 Win32ShimResolver
#   占着 SetDllImportResolver 槽位，本文件只提供 TryResolve，由它调用。
build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs
```

### 4.2 `build/shims/Win32ShimResolver.cs` —— `Resolve()` 开头插入 3 行（**原文**）

```csharp
        private static nint Resolve(string libraryName, Assembly assembly,
                                    DllImportSearchPath? searchPath)
        {
            // ↓↓↓ T1 新增：MIL Core 的 108 条 [DllImport(DllImport.MilCore)] 走 NativeAOT 实现
            if (WpfGfx.Linux.Bridge.MilCoreDllImportResolver.TryResolve(libraryName, out nint milCore))
                return milCore;
            // ↑↑↑ T1 新增

            if (!IsMapped(libraryName))
                return IntPtr.Zero;
```

> 位置必须在 `IsMapped` **之前**：`wpfgfx_cor3.dll` 不在 `MappedLibraries` 里，
> 放后面就永远走不到。

### 4.3 `.so` 放哪儿（三种布局，任选其一）

**路线 A 下 PresentationCore 不引用 `WpfGfx.Linux`**，所以 PC 的输出目录里
既没有 `wpfgfx_cor3.so` 也没有 `libSkiaSharp.so`，必须显式处理。
`MilCoreDllImportResolver` 的查找顺序见 `TryResolve`，**关键约束是
`wpfgfx_cor3.so` 与 `libSkiaSharp.so` 必须在同一个目录**。

| 布局 | 怎么做 | 适用 |
|---|---|---|
| **① 零拷贝（推荐，开发期实测可用）** | **什么都不做**。解析器的第 5 档回退会从 app 目录向上找到 `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so`，那个目录里正好有 `libSkiaSharp.so` | 本仓库内跑 HelloWpf / 测试 |
| ② 发布布局 | 两个文件**一起**拷到 app 目录：<br>`cp build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/{wpfgfx_cor3.so,libSkiaSharp.so} <app 输出目录>/` | 打独立发布包 |
| ③ 环境变量 | `export MILBRIDGE_MILCORE_DIR=<publish 目录>`（目录内同样要有这两个文件） | 多版本并存 |

> ⚠️ **只拷 `wpfgfx_cor3.so` 不拷 `libSkiaSharp.so` 会失败**：
> 一旦 .so 在 app 目录被找到，`s_nativeDir` 就是 app 目录，镜像内部的 SkiaSharp
> 解析器只在那里找 —— 找不到就退回默认探测，最终还是 `DllNotFoundException`。

**验证方法**：跑 `dotnet MilBridge.ClosedLoop.dll`（**不要设 `LD_LIBRARY_PATH`**），
E2a/E2b 会真的调 `MilUtility_ArcToBezier`（内部走 Skia），通过即说明两个文件都找得到。

### 4.4 PresentationCore 是否要加 `ProjectReference`？

**不需要。** 路线 A 下 PC 不引用 `WpfGfx.Linux`，只多编一个源文件 + 运行时加载一个 `.so`。
（这是路线 A 相对路线 B 的最大结构性优势：PC 保持"上游纯移植 + 1 个新增文件"。）

### 4.5 无需改动（确认项）

- `build/PresentationCore.Linux/PresentationCore.Linux.csproj`：**不用改**
  （shims 由 `port-lib.py` 读 `PresentationCore.shims.txt` 注入）。
- `build/PresentationCore.Linux/reapply-patches.py`：**不用改**。
- `Directory.Upstream.props` / `verify-all.sh` / `wpf-linux.sln`：**不用改**。
- `WindowsBase.Linux`：108 条声明**一条都不在它里面**，不用接线。
- `upstream/`：**一个字都不用改**。

---

## 5. 诚实清单

### 5.1 只能 E_NOTIMPL / 占位的导出（29 条）

**全部是 M7a 的既有台账**，桥接层不改变它们的实现深度 —— AOT 包装照样正确转发，
返回 `E_NOTIMPL`（不是空实现，出参会写安全默认值）：

- **`MilChannel_SetNotificationWindow` 已从本清单移出**（2026-09-10 下午落地为真实现，见顶部追加交付）。
- **媒体 21 条**：`MILMediaOpen/Close/Stop/Shutdown/ProcessExitHandler/CanPause/IsBuffering/
  GetPosition/SetPosition/GetDownloadProgress/GetBufferingProgress/SetRate/SetVolume/
  SetBalance/SetIsScrubbingEnabled/HasVideo/HasAudio/GetNaturalHeight/GetNaturalWidth/
  GetMediaLength/NeedUIFrameUpdate`
- **D3D 互操作 4 条**：`InteropDeviceBitmap_Create/Detach/AddDirtyRect/GetAsSoftwareBitmap`
- **`MILFactoryCreateMediaPlayer`**
- **2 条 M1 存量**：`MilResource_SendCommandMedia`、`MilResource_SendCommandBitmapSource`
  （`MilChannel_SetNotificationWindow` 已落地）

### 5.2 HRESULT 语义存疑的地方

| 项 | 存疑点 | 建议 |
|---|---|---|
| `MILRelease` | 上游声明 `int`，返回 `UInt32` 的 `MILAddRef` 语义是"引用计数"；若调用方把 `MILRelease` 的返回值当引用计数用，`int`/`uint` 在 ABI 上等价但我们只保证 HRESULT 语义 | 接线后用真程序跑一遍，若 `MILRelease` 返回值被当计数用会立刻暴露 |
| `GetNextPerfElementId` | 返回 `long`（非 HRESULT），无错误通道 | 保持；已在 M7a 台账 |
| `RenderOptions_IsSoftwareRenderingForcedForProcess` / `WgxConnection_ShouldForceSoftwareForGraphicsStreamClient` | 上游返回 `bool`（4 字节 Win32 BOOL）。包装里 `[UnmanagedCallersOnly]` **不允许 `bool`**，转成 `int` 0/1 返回。CLR 按 `bool` 读 AL 得到正确结果，但**若将来上游改成 `[MarshalAs(UnmanagedType.U1)]` 就会错位** | 已加注释锚点；`MarshalAs` 变更时同步 |
| `MILUtility_CopyPixelBuffer` | `PreserveSig=false`，上游调用点依赖"失败即抛"。AOT 包装返回 HRESULT，CLR 会照抛 ✅（路线 A 自动正确） | 无需动作 |
| `MILSwDoubleBufferedBitmapGetBackBuffer` / `AddDirtyRect` | `PreserveSig=false`，但内层 `MilNative` 返回 `void` —— **没有错误信号**，包装只能返回 `S_OK`。真失败会被当成成功 | **建议 M7a 侧把这两个方法改成返回 `int`**（本次不改 `src/`），否则这是静默失败面 |
| `MilUtility_ArcToBezier` 等几何精度 | 矩阵走 Skia **float** `SKMatrix`，double 精度丢失（实测偏差 7.6e-6） | 后续 milestone 用 double 直算 |
| `MILMediaOpen` 的 `string` | 上游 `[MarshalAs(UnmanagedType.BStr)]` → ABI 是 `wchar_t*`；包装按 `new string((char*)src)` 转。**若上游实际用 `LPStr`（Ansi）就是错的** | M7a 的 `MILMediaOpen` 本来就是 E_NOTIMPL，暂无影响；将来接媒体时按真机 BSTR 对拍 |

### 5.3 需要后续 milestone 的

1. **M7b/M7c**：HWND 绑定 4 条（`MilContent_/MilVisualTarget_AttachToHwnd/DetachFromHwnd`）
   目前是**身份映射**，真接窗在 M7b/M7c。
2. **媒体 U3**：21 条要真实现，需要 Linux 侧的视频/音频栈。
3. **`libSkiaSharp.so` 的分发**：接线清单 §4.3 依赖 `SkiaSharp.NativeAssets.Linux` 把它带到
   PC 输出目录。建议在 `verify-all.sh` 里加一条"两文件同目录"的自检。
4. **`MilBridge_Diag_*` 的定位**：它是**测试专用面**，不属于 MIL ABI。
   若主控不希望它出现在发布产物里，可在 csproj 加 `Condition` 排除 `Diagnostics.cs`
   —— 但闭环 D2/D6 会随之变成 SKIP（不会假通过）。
5. **AOT 裁剪回归**：`TrimmerRootAssembly=WpfGfx.Linux` 会让 .so 从 3.5 MB 涨到 4.0 MB。
   若将来要瘦身，需保留 `MilChannelRegistry` / `MilChannel` 的元数据（诊断面依赖）。

### 5.4 本轮没能做到的

- **没有真的把 PresentationCore 编一遍验证接线**（受边界限制，也不能改共享文件）。
  闭环用的是「形状逐字照抄上游声明」的**同构**调用方，不是 PC 本身。
  → 主控按 §4 接线后，请跑一次 `PresentationCore.Linux` 0 错 0 警 + HelloWpf 烟测。
- **没有做跨进程/多线程压测**。解析器的加载路径已加 `lock (s_gate)` 双检（
  `s_loaded` 先置位以避免 `NotifyNativeDir` 的 P/Invoke 重入死锁），
  但**没有并发压测数据**支撑"高并发下无重复 dlopen"。

---

## 6. 产物与文件清单

```
build/MilBridge/
├── T1-report.md                          ★ 本报告
├── NuGet.config                          MilBridge 局部源（华为镜像，避免动共享 build/NuGet.config）
├── run.sh                                一键复现：gen → AOT publish → 符号对拍 → 闭环
├── src/
│   ├── MilBridge.Linux/                  ★ NativeAOT 共享库（产物 wpfgfx_cor3.so）
│   │   ├── MilBridge.Linux.csproj
│   │   ├── Exports.g.cs                  【生成】108 个 [UnmanagedCallersOnly] 包装
│   │   ├── Diagnostics.cs                8 个 MilBridge_Diag_*（测试专用，非 MIL ABI）
│   │   └── NativeSearchPath.cs           镜像内 SkiaSharp 解析 + MilBridge_SetNativeDir
│   └── MilBridge.Resolver/
│       ├── MilCoreDllImportResolver.cs   ★ 接线用（**无 ModuleInitializer**，只提供 TryResolve）
│       ├── MilCoreStandaloneInstaller.cs 独立宿主自装器（**不要加进 PC shims 清单**）
│       └── README-合并写.txt              与 M7b 解析器合并的两种形态说明
├── tests/ClosedLoop/                     闭环测试（模拟托管层）：40 断言
├── spike/
│   ├── AotLib/                           Phase 1-A 最小 AOT 库
│   └── SmokeTest/                        Phase 1-A 的 P/Invoke 闭环（5 断言）
├── alt-route-b/ProbeB/                   路线 B 可编译性探针（朴素/适配/强名称 三组）
├── tools/
│   ├── scan-milcore-dllimports.py        扫描上游 110 条 [DllImport(DllImport.MilCore)]
│   └── gen-exports.py                    ★ 108 个包装的生成器（含 ABI 类型映射表）
└── gen/
    ├── milcore-dllimports.json           上游声明原始扫描（110 属性/108 导出名）
    ├── side-by-side.txt                  上游签名 vs MilNative 签名 逐条对照
    ├── export-symbols.txt                ★ 符号清单（108，nm 对拍用）
    ├── landing-table.md                  ★ 每个导出的落地方式表（108 行）
    ├── closed-loop-output.txt            ★ 闭环 40/40 原始输出
    └── route-b-diagnostics.txt           ★ 路线 B 三组探针原始诊断
```

**构建产物**（`git` 无关，可删）：`build/MilBridge/.artifacts/`
— publish 输出 `wpfgfx_cor3.so` 4,105,312 B + `libSkiaSharp.so` + `wpfgfx_cor3.so.dbg`。

### 对 `src/` 的影响（披露）

构建 `MilBridge.Linux` 会引用 `src/WpfGfx.Linux/WpfGfx.Linux.csproj`。
最初两次构建走默认输出路径，在 `src/WpfGfx.Linux/` 下产生过 `bin/Release/`、`obj/Release/`，
**已删除复原**；随后改用 `-p:ArtifactsPath=build/MilBridge/.artifacts`（实测两工程各得独立子目录，
不撞 `AssemblyInfo`），此后 `src/` **零写入**。`run.sh` 固定带该参数。

---

## 7. 追加交付 · 复现命令与原始证据文件

```bash
cd <repo>; export PATH="$HOME/.dotnet:$PATH"

# 1) 重新扫描上游 + 重新生成 109 个 AOT 包装
bash build/MilBridge/run.sh gen

# 2) AOT 发布（一次成功；-m:1）
dotnet publish build/MilBridge/src/MilBridge.Linux/MilBridge.Linux.csproj \
    -c Release -r linux-x64 -m:1 -p:ArtifactsPath=build/MilBridge/.artifacts

# 3) 符号对拍：109 个清单 / 缺失 0
nm -D --defined-only build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so \
  | grep -E "MilChannel_SetNotificationWindow|MilFontFace_RegisterFromFile"

# 4) 闭环（刻意不设 LD_LIBRARY_PATH）
cd build/MilBridge/.artifacts/bin/ClosedLoop/release && dotnet MilBridge.ClosedLoop.dll   # 46/46

# 5) MIL 侧单元测试
dotnet test tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj -c Debug -m:1   # 562/562

# 6) 纯 C 探针（不经过 .NET）
gcc -O1 -o /tmp/mb-cprobe/probe /tmp/mb-cprobe/probe.c -ldl
LD_LIBRARY_PATH=<publish 目录> /tmp/mb-cprobe/probe <publish 目录>/wpfgfx_cor3.so \
    build/fonts/NotoSans-Regular.ttf

# 7) app-local 部署模拟（M7c runner 形态）
mkdir -p /tmp/mb-deploy && cp build/MilBridge/.artifacts/bin/ClosedLoop/release/* /tmp/mb-deploy/
cp <publish 目录>/{wpfgfx_cor3.so,libSkiaSharp.so} /tmp/mb-deploy/
cd /tmp/mb-deploy && MILBRIDGE_TEST_FONT=<repo>/build/fonts/NotoSans-Regular.ttf dotnet MilBridge.ClosedLoop.dll
```

| 原始证据文件 | 内容 |
|---|---|
| `gen/closed-loop-output.txt` | 闭环 **46/46** 全文（含 F 组 6 条） |
| `gen/cprobe-output.txt` | **纯 C `dlopen`/`dlsym` 探针**输出（令牌 `0x20000001`） |
| `gen/export-symbols.txt` | **109** 个导出名的清单（`nm -D` 对拍源） |
| `gen/landing-table.md` | 109 行落地方式表 |
| `gen/milcore-dllimports.json` | 上游 110 条 `[DllImport]` 原始扫描 |

---

## 8. 追加交付 · 纯 C 探针原始输出（不经过 .NET）

`/tmp/mb-cprobe/probe.c` 只用 `dlopen` + `dlsym`，证明导出面是**真正的 C ABI**：

```
dlopen OK: .../wpfgfx_cor3.so
dlsym MilFontFace_RegisterFromFile     = 0x7dc5a2d33230
dlsym MilChannel_SetNotificationWindow = 0x7dc5a2d32e30
dlsym MilGlyphRun_GetGlyphOutline      = 0x7dc5a2d33340
MilFontFace_RegisterFromFile(".../NotoSans-Regular.ttf", 0, 0) = 0x20000001
missing file  -> 0x0
faceIndex=-1  -> 0x0
faceIndex=999 -> 0x0
NULL path     -> 0x0
simFlags=1    -> 0x20000002
```

> ⚠️ **探针必须带 `LD_LIBRARY_PATH=<publish 目录>`**：`libSkiaSharp.so` 不是 `.so` 的
> `DT_NEEDED`（SkiaSharp 走运行时 `dlopen`），而纯 C 宿主不会调托管侧的
> `MilBridge_SetNativeDir`，AOT 镜像就不知道自己的目录。**不带 `LD_LIBRARY_PATH` 时
> 上面第一次运行的结果是全 `0x0`**（已实测并留档）—— 这不是"符号没导出"，
> 而是"Skia 加载不到，`RegisterFromFile` 按契约把异常吞成 0"。
> 托管路径（HelloWpf / T2）不受影响，因为 `MilCoreDllImportResolver` 会注入目录。
> 若将来真需要"纯 C 宿主零配置"，一行即可根治：
> `MilBridge.Linux.csproj` 加 `<CustomLinkerArg Include="-Wl,-rpath,$ORIGIN" />`（本轮未做，避免第二次 publish）。

---

## 9. 追加交付 · 剩余缺口

| # | 缺口 | 挡什么 | 建议 |
|---|---|---|---|
| 1 | `libSkiaSharp.so` 必须与 `wpfgfx_cor3.so` **同目录** | 挡 app-local 部署（M7c runner） | runner 一次拷两个文件；或做 RPATH（§8 末尾一行） |
| 2 | `MilFontFace_RegisterFromFile` 失败原因不可区分（文件坏 / Skia 加载不了 / faceIndex 越界，都返回 0） | 不挡功能，挡排障 | 后续可加一个 `MilBridge_Diag_*` 式查询导出回读"最近一次失败原因"；本轮未做 |
| 3 | 跨线程 DUCE 传输 + 通知窗口唤醒 | 不挡单线程 HelloWpf | `MilChannelNotificationRegistry.OnBackChannelPosted` 已是落点；引入 CrossThread 时在那里调 PostMessage |
| 4 | `simFlags` 的高位未知位被静默忽略 | 不挡 | 已记录原始值、可查；若要严格拒绝未知位，改 `RegisterFromFile` 一处即可 |
| 5 | `MilChannel_SetNotificationWindow` 的 hwnd **不校验**是否为本进程已知 HWND | 不挡（故意） | 通知窗口由 Win32 shim 建，`MilHwndRegistry` 里可能没有它（`MilContent_AttachToHwnd` 只在 DWM 变化时才调）；校验会误杀 HelloWpf，故不校验 |

---

## 10. M7c3 · 复现与验证命令

```bash
cd <repo>; export PATH="$HOME/.dotnet:$PATH"
MB=build/MilBridge
PUB=$MB/.artifacts/publish/MilBridge.Linux/release_linux-x64

# 0) AOT 发布（改完 MIL 侧源码后必须重建，否则 .so 里还是旧实现）
dotnet publish $MB/src/MilBridge.Linux/MilBridge.Linux.csproj \
    -c Release -r linux-x64 -m:1 -p:ArtifactsPath=$MB/.artifacts

# 1) T2 调用姿势复现（**刻意不设 LD_LIBRARY_PATH**）—— M7c3 的回归门禁
bash $MB/run.sh t2

# 2) 闭环 46/46
cd $MB/.artifacts/bin/ClosedLoop/release && dotnet MilBridge.ClosedLoop.dll

# 3) 纯 C 探针（零环境变量；修前必须带 LD_LIBRARY_PATH，现在不用了）
gcc -O1 -o /tmp/mb-cprobe/probe $MB/tools/cprobe/probe.c -ldl
/tmp/mb-cprobe/probe $PUB/wpfgfx_cor3.so build/fonts/NotoSans-Regular.ttf
```

| 原始证据文件 | 内容 |
|---|---|
| `gen/t2repro-output.txt` | T2 姿势：令牌 `0x20000001` + 诊断矩阵 + 跨运行时 800 字节轮廓 |
| `gen/cprobe-output.txt` | 纯 C `dlopen` 探针（零环境变量）+ `MilBridge_Diag_SelfDirectory` |
| `gen/closed-loop-output.txt` | 闭环 46/46 |

## 11. M7c3 · 剩余缺口

| # | 缺口 | 说明 |
|---|---|---|
| 1 | `dladdr` 依赖 `libdl.so.2`（回退 `libc.so.6`） | glibc ≥ 2.34 把 dladdr 并进 libc，代码里已经两条都试；两者都不可用时退回旧的候选链（宿主应用目录），行为等同修前 |
| 2 | 诊断是**进程内单槽**（只记最近一次） | 并发登记时后一次会覆盖前一次；作为排障用足够，不做无锁环形缓冲 |
| 3 | 失败码 `7 TypefaceLoadFailed` 同时覆盖"faceIndex 越界"和"文件不是字体" | Skia 对两者都只返回 null；要区分需查 TTC 头，量级不值当 |
| 4 | `MilBridge_Diag_*` 是**测试/诊断面**，不属于 MIL ABI | 若要发布产物不含它，可从 `Diagnostics.cs` 的条件编译排除 |
