# T1c · 方案 A（按码点覆盖感知的字体回退）—— 报告（2026-09-11）

> **一句话**：**代码按规格落完、四道闸门全绿**；但**实测证明这一层当前不在 CJK 的活路上** ——
> 包装族被创建（`Wrap` 有自报）而它的按区间选族钩子 **一次都没被问到**（`WrapperMapCalls=0`），
> 因此**没有修好豆腐块**（`id0` 关/开都是 **325/1276**）。**真凶与真修法见 §4**（不在我的边界内）。
> 本条**保留红**，不放宽任何断言。

---

## 0. 交付物与"落的就是测的那一份"（sha256）

| 件 | sha256 | 说明 |
|---|---|---|
| 应用器 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py` | `3610e096981daab8899bfe5f3afbf1358aeef9877c86a98b482b85e2940faef9` | 唯一改动的**源头**（9 处 EDITS：7 处 M7d 补丁 J + **2 处新增 T1c**） |
| 生成物 `build/PresentationCore.Linux/FamilyCollection.Linux.cs` | `19a42240f59af07348e7ce4addb950c3335b4c819095c81ce22763dfebe7801f` | 2162 行（上游 681 行 + 1481） |
| **波前编译闸门用的 PC**（编到 `/tmp`，**真实产物零改动**） | `c964485a3927f894f3ade61d57f6cc643d3355ba8c7d427ae12cc261c1ec78b7` | `4125696` B，`0 错 0 警` |
| 部署/权威 PC（**我没重建**，留给集成波） | `b1decf1665d6519a074d92b7a0992147bdee3404483dde1b750a8bbdc685d039` | 17:55 的那一份（**不含** T1c） |
| shim（**未改**，`v7`） | `2cc87a93f3e61af8a8b6b7c92a8e71df16d9d8eb0a200c6a64c9eb0a9901041e` | 1791 行 |
| 我新增的测量装置 | `build/MilBridge/tools/t1c-census.sh` | 自己装配运行目录 + 注入诊断 env（**不改** runner、**不改**样例） |

---

## 1. 改动摘要：`FamilyCollection.Linux.cs` 改动前后（哪几处、为什么）

**改动前**（`8608db5e…`）：补丁 J 的 7 处（①短路 ②provider 默认族代偿 ③枚举 null 守卫 ④计数一致 ⑤返回类型）。

**改动后**（`19a42240f…`）：上述 7 处**逐字保留**，另有 **2 处新增**（都在"选面"那一层）：

| # | 位置 | 改动 | 为什么 |
|---|---|---|---|
| ⑧ | `namespace MS.Internal.FontCache` 里、`FamilyCollection` 类之前（`+~570` 行） | 新增两个**独立内部类**：`HbCoverageFallback`（**只查覆盖 + 计数**）与 `HbCoverageFallbackFamily`（覆盖感知的族包装） | 规格要求的新类；覆盖查询的降级链（provider 面 → 直读字体文件 cmap）、按码点缓存、七个计数器都在这里 |
| ⑨ | `LookupFamily` 的**找到族**那一处出口（上游 `:424`） | `return new PhysicalFontFamily(fontFamilyDWrite);` → `return HbCoverageFallback.Wrap(…, _fontCollection, fontFamilyDWrite);` | 两条出口都要包：只包 ② 的话，**真应用**（默认 UI 字体在集合里**找得到**）走的不是 ② 那条路 |
| ② | 补丁 J ② 的 `GetProviderFallbackFamily`（2 处 `return`） | 同样过 `Wrap(...)` | 规格原话："把其'provider 首个可用族'代偿换成按码点覆盖感知的回退" |

**包装类只改写一个成员**：`IFontFamily.GetMapTargetFamilyNameAndScale`（上游**复合字体协议**的"这一段交给哪个族"钩子，
`MS.Internal.Shaping.TypefaceMap.MapByFontFamily` 调用它）。其余 8 个成员（`Names` / `Baseline` / `BaselineDesign` /
`LineSpacing` / `LineSpacingDesign` / `GetTypefaceMetrics` / `GetDeviceFont` / `GetTypefaces`）**逐字转发**给今天那个族。
逻辑：区间开头不覆盖 ⇒ 向 provider 要一个**覆盖该码点**的族，只交出"连续被该族覆盖"的前缀；**覆盖 / 查不出 / 找不到 ⇒ 答本族名**
（= 机制随即走与今天**逐字相同**的 `MapByFontFaceFamily`）。

**开关（未设语义写死并用可跑读数钉住）**：
* `WPF_LINUX_COVERAGE_FALLBACK`：**未设/空 ⇒ 开**（`0/false/off/no` ⇒ 关 ⇒ **连包装都不做**）；
* `WPF_LINUX_COVERAGE_DIAG`：**未设/空 ⇒ 关**（计数器**缺省关**、独立成类、**不碰 `RenderDiagnostics`**、不进任何 runner 判据）；
* `WPF_LINUX_COVERAGE_DUMP=<路径>`：把原始读数落盘（应用是被 `SIGTERM` 收尾的，`ProcessExit` 汇总**实测没跑**必须兜住）。
  运行期自报原文（真实读数，不是文档自称）：
  `WPF_LINUX_COVERAGE_FALLBACK=<未设> ⇒ Enabled=true（**未设时就是开**） ; WPF_LINUX_COVERAGE_DIAG=1 ⇒ Diag=true`。

---

## 2. 原始读数

### 2.1 应用器纪律（`--check` / 幂等 / 求值验证）

```
$ python3 …/patch-presentationcore-compositefont.py --check      # rc=0
[锚点] 9 处各"上游出现 1 次（要求 1）"（7 处补丁 J + 2 处 T1c）
[断言] `throw` 条数 上游 1 == 生成物 1（短路，未搬运异常）
[断言] 上游 681 行 → 生成物 2162 行（+1481 行，全部是判断与注释）
[检查] build/PresentationCore.Linux/FamilyCollection.Linux.cs：内容已是最新
[接线] csproj 已就位（幂等，不改）
幂等：连续两次无参运行，生成物 sha 均为 19a42240…（第二次打印"内容已是最新（未重写）"）
--check 不改文件：前后 sha 相同 ✅
接线（**不读 XML**，msbuild -getItem:Compile 求值）：
   Compile 里上游 internal/FontCache/FamilyCollection.cs  条数 = 0（要求 0）✅
   Compile 里生成物 build/PresentationCore.Linux/FamilyCollection.Linux.cs 条数 = 1（要求 >=1）✅
DefineConstants（求值级）：CORE_NATIVEMETHODS;PRESENTATION_CORE;COMMONDPS;WINDOWS_BASE_OR_PC;TEXTLINE_SHIM_DIRECT;DEBUG
```

### 2.2 波前编译闸门（**编到 `/tmp`，真实产物零改动**）

```
$ dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 -c Debug \
      -p:BaseOutputPath=/tmp/t1c/pcbuild/bin/ -p:BaseIntermediateOutputPath=/tmp/t1c/pcbuild/obj/
已成功生成。   0 个警告   0 个错误
→ /tmp/t1c/pcbuild/bin/Debug/PresentationCore.dll  sha256=c964485a3927f894…  （4125696 B）
```

### 2.3 验收 1 —— **拉丁不退步**（不降）

```
$ bash build/MilBridge/run.sh tline      # 被测文件 = shim（sha 2cc87a93…，**我未改**）
  ✅ T1.73  73 例 CJK 逐行全等（exact=73 diff=0 cases=73）
  ✅ T2d 行度量与真机一致：Height 1298/1298、Baseline 1298/1298（Extent 0/1298 = 已登记项）
  通过 16 / 失败 4 —— 4 条红全是 T1b 报告里**已登记的未实现项**（T2 记账结构 1276/1298、
     T2b A 组断行、T3 Collapse 明细 210/236、T2c Tab），**本改动不触碰它们的输入**
$ bash build/MilBridge/run.sh icu
  → Stage B 逐例全等 73/73（不同 0）；Stage C 禁则不一致 0 ⇒ **一致**
```

### 2.4 验收 2 —— **CJK：没有改善**（如实登记，红）

同一装置、同一 PC（`c964485a…`）、同一档（default，系统字体目录），只切开关：

| 档 | `id0` | `非拉丁(id>=0x1000)` | `maxId` | `glyphs/runs` | `skia 指令` | 截图 |
|---|---|---|---|---|---|---|
| **关**（`WPF_LINUX_COVERAGE_FALLBACK=0`） | **325** / 1276 | **0** | 3540 | 1276 / 48 | 180（未画种类 0） | `colors=2659` |
| **开**（未设 ⇒ 开） | **325** / 1276 | **0** | 3540 | 1276 / 48 | 180（未画种类 0） | `colors=2659` |

> 与 T2b 的基线**逐项相同**（`325/1276`、`maxId=3540`、两个面）。**验收 2 未达标**，原因见 §4。

### 2.5 验收 3 —— 七个计数器的**原始读数**（缺省关；开了才有）

```
# 关档（WPF_LINUX_COVERAGE_FALLBACK=0）—— WPF_LINUX_COVERAGE_DIAG=1 + DUMP
[COVERAGE_FALLBACK] 开关: WPF_LINUX_COVERAGE_FALLBACK=0 ⇒ 本次 Enabled=false（关：连包装都不做 ⇒ 行为=接线前）
[COVERAGE_FALLBACK] 计数: CoverageProbe=0 CacheHit=0 CacheMiss=0 CacheCleared=0 FallbackApplied=0
  FallbackTarget(不同族数)=0 FallbackFailed=0 ProviderCapabilityMissing=0
  ProviderUnknownTreatedAsReturn=0 ProviderQueries=0 ProviderCollectionFace=0 ProviderLoopFace=0
  ProviderInvokeErrors=0 ProviderCollectionFaceError=- NoProviderCollection=0 NoProviderFamily=0
  CmapQueries=0 CmapFilesRead=0 CmapDisagreesWithProvider=0 PrefixSplit=0 AnswerNotResolved=0
  WrapCalls=1 WrapperMapCalls=0 AllCoveredRanges=0
[COVERAGE_FALLBACK] FallbackTarget: <无>
[COVERAGE_FALLBACK] FallbackAppliedCodePoints(top16): <无>

# 开档（未设 ⇒ 开）
[COVERAGE_FALLBACK] 开关: WPF_LINUX_COVERAGE_FALLBACK=<未设> ⇒ 本次 Enabled=true（**未设时就是开**）
[COVERAGE_FALLBACK] 计数: CoverageProbe=0 CacheHit=0 CacheMiss=0 … **WrapperMapCalls=0** AllCoveredRanges=0
                        （其余与关档逐项相同；WrapCalls=1）
```

**七个规格计数器**：`CoverageProbe=0`、`CacheHit=0`、`CacheMiss=0`、`FallbackApplied=0`、
`FallbackTarget=<无>`、`FallbackFailed=0`、`ProviderCapabilityMissing=0`
（另附 12 个 extra：`CacheCleared / ProviderUnknownTreatedAsReturn / ProviderQueries /
ProviderCollectionFace / ProviderLoopFace / ProviderInvokeErrors / ProviderCollectionFaceError /
NoProviderCollection / NoProviderFamily / CmapQueries / CmapFilesRead / CmapDisagreesWithProvider /
PrefixSplit / AnswerNotResolved / WrapCalls / WrapperMapCalls / AllCoveredRanges`）。

**provider 能力探测原文**（主控点名要的"探测到了什么、按什么签名"）：

```
providerFace=MS.Internal.Text.TextInterface.Linux.FamilyCoverageQuery@DirectWrite.Linux.Provider；
QueryCoverage(LinuxFontFamily,int)->FamilyCoverage=有；Covers(LinuxFontFamily,int)->bool=有；
QueryCoverage(LinuxFontCollection,int,out LinuxFontFamily)->FamilyCoverage=有；
TryFindFamilyCovering(LinuxFontCollection,int,out LinuxFontFamily)->bool=有（只报，不调：集合级 QueryCoverage 语义更全）；
typeof(LinuxFontFamily).GetMethod(Covers)=无（它是扩展方法，本就在静态类上）；
决策=集合级 QueryCoverage（三态：Unknown 不当成没有）
```

> ⇒ **主控给的那条情报是对的、也是必要的**：按"实例方法"探测会得到"无" ⇒ 永远走 cmap 降级链而**所有读数都是绿的**。
> 这里把两种探测的结论都打进读数（上面那行），并且 `Unknown` **不当成"没有"**（⇒ `ProviderUnknownTreatedAsReturn`）。

### 2.6 验收 4 —— 开/关 A/B（**逐项相同**；但见下面的"真空真"标注）

| 项 | 关 | 开 | 判定 |
|---|---|---|---|
| 逐 run 普查明细（40 run × 2 帧，去掉句柄后） | — | — | `diff` 完全相同 ✅ |
| `MilGlyphRun` 资源数 | 50 | 50 | 相同 ✅ |
| `skia 指令 / 未画种类` | 180 / 0 | 180 / 0 | 相同 ✅ |
| 截图像素差（`compare -metric AE`，938×938） | — | — | **0**（逐像素相同）✅ |
| PNG **文件** sha256 | `0d9eb829…` | `73c4e368…` | ⚠️ **不同**（仅 PNG 容器元数据/时间戳；像素差 0）—— 记一笔"用文件哈希判像素会撒谎" |

> ⚠️ **这一条是"真空真"**：因为钩子**一次都没被调用**（`WrapperMapCalls=0`），"相同"是**恒等**的结果，
> **不能**当成"按码点选面没有副作用"的证明。见 §4。

---

## 3. ⚠️ 我自己的判据也做了"它会不会撒谎"的自检

* `Wrap` 计数（`WrapCalls=1`）证明**包装确实被创建**：所以"没有回退"**不是**因为开关没生效；
* `WrapperMapCalls` 只在诊断开着时累加，且**前 8 次必打**一行 —— 它是"钩子有没有被问到"的**直接**读数（=0）；
* 关档 `Enabled=false` 与开档 `Enabled=true` 两条自报都拿到 ⇒ 开关语义是**实测**的，不是文档自称；
* 计数器的七个/extra 读数**落盘**（`WPF_LINUX_COVERAGE_DUMP`）⇒ 不依赖 `ProcessExit`（实测本装置下它没跑）；
* 阴性结论配了**阳性对照**（§4.3）⇒ 不是"我改的东西没用"而是"我改的层不在这条路上"。

---

## 4. 🔴 关键发现：方案 A **不在 CJK 的活路上**（这是本次任务的真正结论）

### 4.1 读数（不是推断）

1. `Wrap` 有自报、`WrapCalls=1`，但 **`WrapperMapCalls=0`** ⇒ `IFontFamily.GetMapTargetFamilyNameAndScale`
   **一次都没被问过**（诊断开着，前 8 次必打）。
2. 上游 `GetShapeableText`（喂 `TypefaceMap`/`GlyphingCache` 的那个入口）**在托管 PresentationCore 里没有任何调用者**
   （`grep -rn "GetShapeableText" upstream/…/PresentationCore` 只剩定义处与 `TypefaceMap` 自己）
   ⇒ 复合字体那套"按区间选族"**只活在 LineServices 路径上**，而本移植已把 LS 换成托管 shim。
3. `WPF_LINUX_TEXTLINE_FALLBACK=0`（关掉 shim）⇒ 应用**当场崩**：
   `EntryPointNotFoundException: … 'LoCreateContext' … PresentationNative_cor3.dll`，`rc=134`
   ⇒ 含 CJK 的行（`SimpleTextLine` 快路径因 `CheckFastPathNominalGlyphs` 见到 `glyph==0` 而返回 false）
   **确实落到 shim**。
4. shim 的形状是"**一段一个字体文件**"：`TryCollect` 只取**第一个 run** 的 `properties`（把整段字符拼成一个串），
   `TryResolveFont` 从 `props.Typeface.TryGetGlyphTypeface().FontUri` 取**一个**文件，再交给 HarfBuzz
   ⇒ **没有覆盖感知、也没有 per-run 字体**。
5. LINEDIAG：`LS_FALLBACK 接手` **69 次**（截图同一帧）。
6. **补丁 J ② 那条路本身也没被走到**：`WPF_LINUX_FONT_DIAG=1` 全程 **0 行** `[FONT_DIAG] providerFallback`
   （默认档与 env 档各测一次）⇒ `GetProviderFallbackFamily` 未被调用（两种档位下应用的字体名都在集合里**找得到**）。
   ⇒ 主控在派单时给的"选面链条走到 ②"是**读代码推出来的**；实测**不成立**（这正是"推断 ≠ 结论"那一族）。

**⇒ 选面发生在"run 的 `Typeface`"这一层，而一个 run 只用一个字体文件。**
`FamilyCollection.LookupFamily` 只拿到**族名**（看不到该 run 的字符），
而唯一"带字符"的钩子（`GetMapTargetFamilyNameAndScale`）**在本移植里没人消费**。

### 4.2 顺带纠正一条被当成事实的链路

`§10` 的选面链条（`Typeface → … → LookupFamily → provider 首个可用族 → MapCharacters`）**只对"解析 Typeface"成立**；
"**按码点选面**"那一跳（`TypefaceMap`）在本移植里是**死代码**。T1b 的"缺的是按覆盖选面"结论仍然对，
但**修法位置**不是 `FamilyCollection`，而是 **shim 的字体解析**。

### 4.3 阳性对照（证明上面的因果，而不是"我改的东西无效"）

同一应用、同一 PC（`c964485a…`）、同一档，**只改默认 UI 字族**：

```
default（= DejaVu Sans，SPI 给的）      : runs=48 glyphs=1276 id0=325 maxId=3540  非拉丁=0     截图：中文全是豆腐块
+ WPF_LINUX_UI_FONT="Noto Sans CJK SC" : runs=40 glyphs=1064 id0=0   maxId=63151 非拉丁=294   截图：中文正常
```

**读图复核（不是直方图推断）**：我看了两张截图 —— 前者（`/tmp/t1c/final-off/shot-1.png`）
所有中文是方框（豆腐块）；后者（`/tmp/t1c/final-cjkfont/shot-1.png`）"① 多行折行 · 中英混排"、"
绑定项 01 / Item 01"、"当前选中（ElementName 绑定）"等**都是真汉字**。
⇒ **一个字体文件覆盖得住，就全对**：这既是"缺的是选面"的确认，也是"选面在 run 这一层"的确认。

### 4.4 建议的真修法（**不在我的边界内，需主控派单**）

* **R1（结构性正解）**：`build/shims/PresentationCore.HbTextLine.cs` 的字体解析那一层 ——
  `TryCollect` **按 run** 收集（现在只用第一个 run 的 properties）、`TryResolveFont` **按 run** 取字体，
  并在一个 run 内做**按码点覆盖回退**（可以复用 provider 的 `FamilyCoverageQuery`：集合级 `QueryCoverage(cp)`；
  HarfBuzz 支持按 run/按簇换字体整形）。**该文件是 T1b 的 v7 车道，我按边界没碰**。
* **R2（配置级止血，零代码）**：给应用/默认 UI 字族一个覆盖得住目标脚本的族
  （实测 `WPF_LINUX_UI_FONT="Noto Sans CJK SC"` 即可把 `id0` 325 → 0）。
  注意 `build/fonts-ui/UI-NoLayout.ttf`（部署用的 UI 字体）**一个 CJK 码点都没有**，且 env 档的字体集合里
  **根本没有 CJK 族** ⇒ **那一档无论怎么改选面都不可能出 CJK**（详见 §5 的 B 条）。
* **R3（如果坚持要用 A 这条路）**：得先让"带字符的那个钩子"活着 ——
  即让 `TextCharacters.GetShapeableText`/`TypefaceMap` 重新进入文本路径（本移植里它是 LS 专属）。
  代价大，且与"只动选面、不动行创建"的约束冲突面更广。

---

## 5. 未覆盖 / 做不到（诚实清单）

1. **验收 2 未达标**：`id0` 325 → 325（关/开都一样）。**根因不是实现错误，而是落点不在活路上**（§4）。
2. **降级链 b（直读 cmap）没有"跑出真读数"**：provider 面在（`=有`），所以 `CmapQueries=0`、
   `CmapFilesRead=0`、`CmapDisagreesWithProvider=0` —— **cmap 读取器一次都没被执行到**。
   它只做了编译期验证 + 结构断言，**未经运行期实证**（要实证可临时把 provider 面屏蔽；我这轮没做，登记为欠账）。
3. **方案 A 的"前缀断开/按码点选"逻辑未经运行期实证**（因为钩子没被调到）——同一原因。
4. **env 档（`WPF_LINUX_FONT_DIR=build/fonts-ui`）结构性无解**：实测该档字体集合只有 `UI-NoLayout.ttf` 一个族
   （`fc-query`：0 个 CJK 码点）⇒ **没有任何族可回退**。该档 `id0=329/1170`（我复现过 T2b 的口径：
   默认档 325/1276 逐项相同）。要修这一档**必须先让它能看见字体**（改字体集合，不是改选面）。
5. **拉丁不退步的证明里有"真空真"成分**（§2.6 已标注）：强证据是"钩子没被调用 ⇒ 零行为面"，
   而不是"选面在拉丁上被验证过"。
6. **`T2e`（`cases-cd2.json` 那 10 例 `LineHeight` 真值回证）仍未做**（T1b 的欠账，我没碰）。
7. 我没做：重建 PC（主控在集成波做）、跑 `verify-all.sh`、改 shim / provider / 渲染器 / 样例。

---

## 6. 需要主控做什么

1. **决定 (甲) 的去留**：代码已落且四道闸门全绿，但**在当前活路上没有任何效果**。三个选项：
   * **(a) 保留并起波**（我的默认交付形态）：零行为差（关/开逐像素相同），**给将来的"钩子复活"留好机制**；
     缺省值保持**未设即开**（自报行可复核）。
   * **(b) 保留但缺省关**（一行改动：`ParseBehavior` 的空值分支返回 `false`）⇒ 更保守，但会埋下
     "设计说开、实现却关"的旧坑（本项目栽过一次）。
   * **(c) 回滚**，等 R1 落地后再谈。我不推荐——现在回滚等于把 §4 的证据链和测量装置一起丢掉。
2. **派单 R1（真修法）**：`build/shims/PresentationCore.HbTextLine.cs` 的 `TryCollect`/`TryResolveFont` +
   按码点覆盖回退（HarfBuzz 多字体整形）。**这是唯一能让 WpfTextDemo 的 CJK 真出字的代码路径**。
   我这一轮**没有**越界去改它（边界）。
3. **如果主控要我继续**，我在边界内还能做：给 (A) 补上"降级链 b 的运行期实证"（临时屏蔽 provider 面）、
   以及把 `WrapperMapCalls=0` 的结论做成**波后自动复验**（一个断言：若 `WrapperMapCalls>0` 则说明
   TypefaceMap 复活了 —— 那正是 A 开始生效的信号）。
4. **复验用的现成命令**（都在我的车道内，主控可直接跑）：
   ```
   python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py --check        # 期望 rc=0
   bash build/MilBridge/tools/t1c-census.sh /tmp/recheck default \
        WPF_LINUX_GLYPH_CENSUS=1 WPF_LINUX_COVERAGE_DIAG=1 \
        WPF_LINUX_COVERAGE_DUMP=/tmp/recheck/coverage.txt                                     # 期望 id0=325
   bash build/MilBridge/tools/t1c-census.sh /tmp/recheck-cjk default \
        WPF_LINUX_GLYPH_CENSUS=1 WPF_LINUX_UI_FONT="Noto Sans CJK SC" \
        WPF_LINUX_TEXT_FONT_FAMILY="Noto Sans CJK SC"                                         # 期望 id0=0 / 非拉丁=294
   ```
   （第二/三条默认用**权威 PC**（`build/PresentationCore.Linux/bin/Debug/`）；我这轮为了拿到"带 T1c 的件"
   用了 `PC_OVERRIDE=/tmp/t1c/pcbuild/bin/Debug/PresentationCore.dll` = `c964485a…`，**没有写回任何权威产物**。）

---

## 7. 边界与纪律声明

* 我只改了 **1 个应用器** + 它的**生成物**（`FamilyCollection.Linux.cs`）+ **新增 1 个测量装置**；
  `build/shims/PresentationCore.HbTextLine.cs` 的 sha 仍是我接手时的 `2cc87a93…`（**未碰**）。
* `PresentationCore` **没有重建**（真实产物 `b1decf16…` 未变）；波前闸门只编到 `/tmp`。
* 本报告里所有"因果"结论都配了**改这一处 → 现象翻转**的对照：④.1 的 2/3/4 三条读数 + ④.3 的阳性对照。
* 反面证据（`WrapperMapCalls=0`）**保留为红**，没有为了好看把 A/B 写成"验证通过"。

---

## 8. 增补（主控裁定之后，2026-09-11 晚）

### 8.1 裁定照办：**(甲) 按 (a) 保留 + 起波**，**文件已冻结并逐字复验**

主控裁定 (a)（保留 + 起波，不关不回滚），理由与我的建议一致（零行为差、把机制与测量装置留在树上、
避免重演"设计说开、实现却关"）。**交付件与裁定时的 sha 逐字一致**（下面是我在裁定后复验的原始读数）：

```
sha256(src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py) = 3610e096981daab8899bfe5f3afbf1358aeef9877c86a98b482b85e2940faef9   ← 与裁定值一致
sha256(build/PresentationCore.Linux/FamilyCollection.Linux.cs)               = 19a42240f59af07348e7ce4addb950c3335b4c819095c81ce22763dfebe7801f   ← 与裁定值一致
python3 …/patch-presentationcore-compositefont.py --check                    → rc=0（"内容已是最新" / "接线已就位"）
波前编译闸门（重新编到 /tmp）                                                  → 0 个警告 0 个错误
sha256(/tmp/t1c/pcbuild/bin/Debug/PresentationCore.dll)                      = c964485a3927f894f3ade61d57f6cc643d3355ba8c7d427ae12cc261c1ec78b7
                                                                               （与 §2.2 的 A/B 用件**逐字节相同** ⇒ 上面所有 A/B 读数的被测件可复现）
```

**过程如实登记**：裁定前我曾另加过一段"覆盖链自检"（见 8.2），**裁定后我把它整段撤回**，
用"还原后的 sha == 冻结 sha"作为**撤回是否逐字节干净**的判据（applier `3610e096…` ✓、生成物 `19a42240…` ✓）。
自检变体留在 `/tmp/t1c/applier-selftest-variant.py`（**不在树上**），其读数见 8.2，**不计入交付件**。

### 8.2 自检**变体**（scratch，未落树）给出的两条运行期读数：**降级链 b 有实证了**

我此前的"未覆盖清单"里挂着一条红：**直读字体文件 cmap 的那条链没有运行期实证**（`CmapQueries=0`）。
借这次自检变体（`WPF_LINUX_COVERAGE_SELFTEST=1`，缺省关）把两条链**并排真跑了一遍**（8 个取样码点）：

**默认档（系统字体目录）** —— 基线族 `DejaVu Sans`：
```
U+0041 provider=Covered    cmap=Covered    | 覆盖族: provider=AR PL UKai CN      cmap=AR PL UKai CN
U+00DF provider=Covered    cmap=Covered    | 覆盖族: provider=AR PL UKai CN      cmap=AR PL UKai CN
U+4E2D provider=NotCovered cmap=NotCovered | 覆盖族: provider=AR PL UKai CN      cmap=AR PL UKai CN
U+3002 provider=NotCovered cmap=NotCovered | 覆盖族: provider=AR PL UKai CN      cmap=AR PL UKai CN
U+FF0C provider=NotCovered cmap=NotCovered | 覆盖族: provider=AR PL UKai CN      cmap=AR PL UKai CN
U+3042 provider=NotCovered cmap=NotCovered | 覆盖族: provider=AR PL UKai CN      cmap=AR PL UKai CN
U+AC00 provider=NotCovered cmap=NotCovered | 覆盖族: provider=Droid Sans Fallback cmap=Droid Sans Fallback
U+1F600 provider=Covered   cmap=Covered    | 覆盖族: provider=DejaVu Sans         cmap=DejaVu Sans
自检完成: CmapQueries=42 CmapFilesRead=26 CmapDisagreesWithProvider=0
```
**env 档（`WPF_LINUX_FONT_DIR=build/fonts-ui`）** —— 基线族 `Noto Sans`（即 `UI-NoLayout.ttf`）：
```
U+0041 Covered/Covered | 覆盖族: Noto Sans / Noto Sans
U+4E2D / U+3002 / U+FF0C / U+3042 / U+AC00 / U+1F600 : provider=NotCovered cmap=NotCovered
                        | 覆盖族: provider=<无>(NotCovered) cmap=<无>(NotCovered)
自检完成: CmapQueries=8 CmapFilesRead=1 CmapDisagreesWithProvider=0
```
⇒ 三件事：① **两条链 8/8 一致**（`CmapDisagreesWithProvider=0`）⇒ cmap 读取器（format 4/12 + TTC 面下标）
可用、且与 provider（Skia 口径）结论相同；② `DejaVu Sans` 对 CJK/假名/谚文/CJK 标点**确实不覆盖**
（而 `A`/`ß`/emoji 覆盖）—— 与 §4 的因果一致；③ **env 档结构性无解**再获一条直接读数
（集合里**没有任何族**覆盖这些码点）。
**边界（不许含糊）**：这份读数来自**未落树的自检变体**；树上交付件**不含**自检代码，
因此"降级链 b 有实证"这句话**只对那份变体成立** —— 若要把它变成常设能力，需要主控许可再加回（约 140 行，缺省关）。

### 8.3 R1 复测装置：**已备好**（在 `build/MilBridge/**`，不碰被测件、不碰 `RenderDiagnostics`）

`build/MilBridge/tools/t1c-census.sh`（加了三件装置选项）+ 新脚本 `build/MilBridge/tools/t1c-census-summary.py`：

| 想要什么 | 怎么用 |
|---|---|
| **权威数**（CJK 修没修） | `T1C_CENSUS_SUMMARY frame=3 runs=48 glyphs=1276 id0=325 nonlatin=0 maxid=3540 allnotdefruns=0 distinctpids=2`（**整帧**，取自 census 自己的汇总行） |
| **形态数**（多字体整形：几份面、各承担多少） | `T1C_CENSUS_SHAPE detail_runs=40(of frame runs=48…) pids=[0x20000003(7runs/133g/id0=45),0x20000004(33runs/964g/id0=237)]` |
| **R1 新仪器的读数**（shim 里新加的键） | `T1C_FORWARD_KEYS=<正则>` 转发（默认 `HBFACE\|HBFALLBACK\|FACE_\|SEGMENT\|MULTIFONT\|GLYPH_FACE\|RUN_FACE`）⇒ **R1 加读数不用改我的脚本** |
| **差值对照**（`id0 325→~0`） | 先跑基线（`WPF_LINUX_COVERAGE_FALLBACK=0`）留 `readings.txt`，再跑一次带 `T1C_AB_BASE=<基线 readings.txt>` |
| **像素对照**（拉丁不退步） | `T1C_AB_PIXELS=<上一轮 shot-1.png>` ⇒ `compare -metric AE`（**并附一句：PNG 文件 sha 不同不代表像素不同**） |

**装置自检（仪器自己不许撒谎）**：
* 解析器拿**已知日志**验过：`frame=3 runs=48 glyphs=1276 id0=325 maxid=3540 nonlatin=0 distinctpids=2` **逐项与 census 原行一致**；
* **空真护栏**：只有空帧时打 `T1C_CENSUS_EMPTY … （id0=0/nonlatin=0 是空真，不能当"没有豆腐块"）` 且 **rc=3**；
* 没有任何 census 行时**不说话**（rc=1）—— 宁可不说话，也不说不可信的话；
* **明细上限如实标注**：`detail_runs=40(of frame runs=48（明细行每帧上限 40 ⇒ 少于整帧数不代表丢 run）)`；
* 踩过并修好一次"仪器悄悄不工作"：`T1C_AB_*` 原先被当成**应用 env** 传走 ⇒ 装置自己看不见它 ⇒ 那两行**静默不出现**；
  现在 `T1C_*` 是**装置自己的选项**，且基线文件缺汇总行时会打"无差值可算"而不是**空值**。
* 复跑验证（现成命令，基线 = 冻结件）：
  ```
  bash build/MilBridge/tools/t1c-census.sh /tmp/r1base default WPF_LINUX_GLYPH_CENSUS=1 \
       WPF_LINUX_COVERAGE_FALLBACK=0 PC_OVERRIDE=<波后 PC>
  bash build/MilBridge/tools/t1c-census.sh /tmp/r1now default WPF_LINUX_GLYPH_CENSUS=1 \
       T1C_AB_BASE=/tmp/r1base/readings.txt T1C_AB_PIXELS=/tmp/r1base/shot-1.png PC_OVERRIDE=<波后 PC>
  ```
  （实测：基线 `id0=325 nonlatin=0`；对照 `id0=325 nonlatin=0`；`T1C_AB_PIXELS AE=0`）

### 8.4 仍未做（账上保留）
* **R1**（shim 的按 run 取字体 + 按码点覆盖回退）：已由主控派给 T1b，**不在我边界内**；
* **`T2e`**（`cases-cd2.json` 那 10 例 `LineHeight` 真值回证）：仍未做，**不声明 `LineHeight` 闭环**；
* 常设化"覆盖链自检"（8.2）需要主控许可（**变体未落树**）；
* R2（`WPF_LINUX_UI_FONT` 换 CJK 族）**按主控裁定只作诊断/止血**，不作修法（会把问题挪到拉丁）。

---

## 9. 增补：(乙) PC 半边 —— **可判 + 可翻转 + 面身份**（2026-09-11 晚，主控改派后的收口）

> **结论**：**(乙) 的 PC 半边无需新实现** —— 在部署件上它按构造就是通的；缺的只是**可判性**与**A/B 翻转**。
> 我加的是"开关 + 诊断出口"（不改默认行为），并用**成对读数**把 `48/0/0 ⇄ 0/0/48` 翻了出来，
> 顺带把**面身份**三点对齐（登记 `(path, faceIndex)` ↔ 令牌 ↔ 逐 run `pid` ↔ 渲染器解析到的面+文件）。

### 9.1 我改的唯一文件（+ 判据锚点）

| 文件 | 改动 | 为什么 |
|---|---|---|
| `build/shims/PresentationCore.FontBridge.cs`（面令牌相关 ⇒ 本轮授权边界内） | ① 新增 **A/B 开关** `WPF_LINUX_FACE_HANDOFF`（**未设 ⇒ 开**；`0/false/off/no` ⇒ 关）+ 纯函数 `ParseHandoff`；② 新增**可判性出口** `WPF_LINUX_FACE_HANDOFF_DIAG`（**未设 ⇒ 关**，≤12 行，前缀 `[FACE_HANDOFF]`）；③ 新增档位 `FontFaceBridgeMode.DisabledBySwitch`；④ 登记处打印 `token/path/faceIndex/simFlags` | 在此之前 `Status/AllocatorCalls/NativeAllocations` 在真应用里**读不到**（无消费者）；没有开关就**无法排除"另有登记者"** |

**未改**：`src/WpfGfx.Linux/**`（桥）、`build/DirectWrite.Linux/Provider/**` 的既有逻辑、PC 的其它应用器产物。
**隔离编译闸门**（因当时 T1d 的 shim 正在中途编辑、全量 PC 编不过）：
```
dotnet build /tmp/t1c/fbgate/fbgate.csproj -m:1 --nologo -v q
已成功生成。   0 个警告   0 个错误
```
**全量 PC 闸门**（T1d 落完后再编，**编到 /tmp、权威件不动**）：
```
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 -c Debug \
    -p:BaseOutputPath=/tmp/t1c/pcbuild/bin/ -p:BaseIntermediateOutputPath=/tmp/t1c/pcbuild/obj/
已成功生成。   0 个警告   0 个错误
→ /tmp/t1c/pcbuild/bin/Debug/PresentationCore.dll sha256=d5403f394d9f3d7843b455adc7052768d8d96c21b774579bdfcfb40828680c47
```
（权威 PC `b1decf16…` **未重建**；权威 shim 此时已被 T1d 改成 `192f7d38e98c0961cf2259c0a46f5afdbcbf73166e27281c5f5531389ecf743c` / 3122 行 —— 不是我改的。）

### 9.2 A/B 成对读数（**两档同一套产物**；每档的 `WPTD_ARTIFACTS` 都在读数文件里）

两档共同的产物（我当次跑出来的原始行）：
```
PC        d5403f394d9f3d7843b455adc7052768d8d96c21b774579bdfcfb40828680c47  (4147200 B，/tmp 闸门件)
provider  a3c026c501ee96214aa47441ff30f83838ce9a9f6873d81bc164ba81fec30b91  (109568 B，含 §10 新增的自检文件)
桥        cefd7281f670a1fbd750717593575e0023bd3539959f723b5f05980eaa81cc92  (4896624 B)
shim      192f7d38e98c0961cf2259c0a46f5afdbcbf73166e27281c5f5531389ecf743c  (166906 B，T1d 的 R1 件)
```

**① 开档（`WPF_LINUX_FACE_HANDOFF` 未设 ⇒ 开）**
```
[FACE_HANDOFF] Install: WPF_LINUX_FACE_HANDOFF=<未设> ⇒ 解析为 **开**（未设时就是开）; handoff=on(未设即开)
               status=NativeAotExport milHandle=0x6108958CCFD0 exportProbed=True
               registerExport=找到(MilFontFace_RegisterFromFile) allocatorCalls=0 nativeAllocations=0
[FACE_HANDOFF] 登记#1 token=0x20000003 path=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf faceIndex=0 simFlags=0
[FACE_HANDOFF] 登记#2 token=0x20000004 path=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf      faceIndex=0 simFlags=0
[glyph-census] 面来源（债务 #14）：**按句柄命中 = 48** / **回落族名（无句柄）= 0** / **有句柄但解析失败 = 0**
[glyph-census]   面 …family=DejaVu Sans file=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf faceIndex=0 覆盖U+4E2D=否 runs=8  glyphs=140  zeroIds=50
[glyph-census]   面 …family=DejaVu Sans file=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf      faceIndex=0 覆盖U+4E2D=否 runs=40 glyphs=1136 zeroIds=275
```
**② 关档（`WPF_LINUX_FACE_HANDOFF=0`）**
```
[FACE_HANDOFF] Install: WPF_LINUX_FACE_HANDOFF=0 ⇒ 解析为 **关** ⇒ 不装路径式分配器（令牌来自进程内表；MIL 将解析不到）
[glyph-census] 面来源（债务 #14）：**按句柄命中 = 0** / **回落族名（无句柄）= 0** / **有句柄但解析失败 = 48**
[glyph-census]   面 …family=DejaVu Sans file=DejaVuSans.ttf faceIndex=0 覆盖U+4E2D=<未测> runs=48 glyphs=1276 zeroIds=325
```

⇒ **翻转成立**：`48/0/0` ⇄ `0/0/48`，且"关"档下**命中精确归零** ⇒ **不存在"另有登记者"**（这正是只报 `48/0/0` 排除不掉的那件事）。
⇒ 并且"关"档暴露了债务 #14 的**实质**：**48 个 run 全部落在一份面（Regular）上**，连粗体的 run 也用 Regular 光栅化。

### 9.3 面身份：三点对齐（登记 ↔ 令牌 ↔ 逐 run pid ↔ 渲染器解析到的面）

| 令牌 | 登记时给的路径/面下标（PC 侧，`[FACE_HANDOFF]`） | 逐 run `pid` 计数（命令式普查） | 渲染器解析到的面（M7b 的 census） |
|---|---|---|---|
| `0x20000003` | `DejaVuSans-Bold.ttf` faceIndex=0 | **14** runs | `DejaVu Sans` / `DejaVuSans-Bold.ttf#0` runs=8（明细行上限 40，整帧 14） |
| `0x20000004` | `DejaVuSans.ttf` faceIndex=0 | **66** runs | `DejaVu Sans` / `DejaVuSans.ttf#0` runs=40（整帧 66） |

`14/66` 与 T2b 逐 run 明细的出处**逐值相同**（T2b：`0x20000003` 14 runs / `0x20000004` 66 runs）。
⇒ **这 48 个 run 用的两份面，就是 PC 整形时用的那两份**（同一个 `LinuxFontFace`：
`GlyphRun.cs:1876 → Font.DWriteFontAddRef → FontHandleTable.Register(GetFontFace())`，
`SourcePath/FaceIndex/SimulationFlags` 取自该面）。
⇒ **它们不是 CJK 面**：`覆盖U+4E2D=否`（我另用独立 cmap 读取复核 `DejaVuSans.ttf`/`DejaVuSans-Bold.ttf` 都不含 U+4E2D）
—— 这与"当前 325 个 CJK 字形 id 全是 0"自洽：**PC 从来没有用 CJK 面整形过**（那是 R1/T1d 的事）。

### 9.4 开关的**可见后果**（"面由 run 决定"不是空话）

| 项 | 开档 | 关档 |
|---|---|---|
| 帧像素差（`compare -metric AE`，938×938） | — | **8340**（差异包围盒 `661x827+38+42`） |
| 标题区（粗体，420×46+30+22）墨量 | **2167** px | **1361** px |
| `skia 指令 / 未画种类` | 180 / 0 | 180 / 0 |
| 字形普查 | `48 runs / 1276 glyphs / id0=325 / maxId=3540 / 2 面` | 同（逐项相同） |

⇒ 关档把**粗体文本用 Regular 面光栅化**（墨量少 37%），开档用 Bold 面 —— 这就是债务 #14 的可视化差异。
（**读图**：我看过两张全图，同族同字号下肉眼看不出差别；差异靠区域墨量 + 包围盒量化给出，不靠感觉。）

### 9.5 与 R1 的契约（写死，供 T1d 对齐）

* 令牌携带的 `(path, faceIndex, simFlags)` **就是**整形用的那份面 —— 只要"每个字体子段一个 `GlyphRun`"里
  每个子段的 `GlyphTypeface` 是**它实际整形用的那份面**，令牌会自动跟着走，**provider 不需要新 API**。
* ⚠️ **一个会踩空的坑**：若子段用的是"从**字节流**造的 face"（`LinuxFontFace.FromBytes` ⇒ `SourcePath == null`，
  见 `build/DirectWrite.Linux/Provider/LinuxFontFace.cs:170`），路径式分配器**拿不到路径** ⇒ 回落进程内表
  ⇒ MIL 解析不到。我在诊断里让这种情况**可见**（`登记#N path 为空 ⇒ 不接管`），T1d 落地后跑一次即可判定。
* 幂等前提已由 M7b 保证（`(path, faceIndex, simFlags)` 同 key 同句柄）⇒ 重复登记不会让旧 run 的令牌失效。

### 9.6 如实登记的两件小事

1. **一次抓屏失败**：开档第一次跑（`/tmp/t1c/hand-on/`）时 `:98` 当时是**down**（X 侧竞态），应用仍画了、
   但装置 `SHOT frames=0`（无截图）；**重跑**（`hand-on2`）6 帧正常。⇒ 上表的像素/墨量读数取自 `hand-on2`。
2. **头条读数我不引主控口头那组**（`145 / 938×646`，那是更早的桥 `9eb4c88c` 的口径）。本报告只引：
   ① 我当次的原始行（上表）；② `WPTD_ARTIFACTS` 四件 sha（§9.2 已列）。本档我读到的是
   `skia 指令 180 / 未画种类 0 / 938×938 / exit=143`。

### 9.7 未做 / 待办

* **全量 `run.sh tline` 的 T1.73/T2d 复跑落在 T1d 的 R1 shim 上**（shim 已从 `2cc87a93…` 变成 `192f7d38…`/3122 行）
  ⇒ 那两条读数**不再是"我这轮改动的护栏"**（我的改动在 PC 侧，完全不进该 harness 的输入：它只编 shim 源 + oracle）。
  我的改动护栏是：隔离编译闸门 0/0 + 全量 PC 闸门 0/0 + 上表两档头条逐项相同。
  **复跑读数（供 T1d 对照，附被测件 sha）**：`被测文件 = build/shims/PresentationCore.HbTextLine.cs`（`192f7d38…`）⇒
  ✅ **T1.73 73 例 CJK 逐行全等**（`用例 73；逐行全等 73 / 不同 0`）；
  ✅ **T2d 行度量 Height 1298/1298、Baseline 1298/1298**（`Extent 0/1298` 为已登记项）；
  `通过 16 / 失败 4` —— 4 条红为已登记项，其中 `T2b` 已是 T1d 的新数（`行级 964/965；用例级 207/213`）。
* 面身份里的**"是不是 CJK 面"**在 R1 落地前只能回答"**当前不是**"；R1 之后需用同一套读数复验（命令已备好）。

---

## 10. 增补：**覆盖查询自检常设**（主控批准后落地；关掉"降级链 b 无运行期实证"那条红）

**新文件**（独立成文件，**未改** `FamilyCoverage.cs` 的既有逻辑）：`build/DirectWrite.Linux/Provider/FamilyCoverageSelfTest.cs`
**探针**（命令行 + 原始输出）：`build/MilBridge/tests/FamilyCoverageSelfTest/`（`Program.cs` + `.csproj`）

四条条件的落实：

| 条件 | 落地 |
|---|---|
| ① 独立新文件 | `FamilyCoverageSelfTest.cs`（只用 `FamilyCoverageQuery` 的 public 面）；**点名**：我改了 provider 的**新增**文件，`FamilyCoverage.cs` 一个字节未动 |
| ② 缺省关 | `WPF_LINUX_COVERAGE_SELFTEST` **未设/空白 ⇒ 关**（纯函数 `ParseOnOff`）；关时 `Run()` **直接返回**：不输出、不查询 |
| ③ "缺省下逐字节不改变行为"的**断言** | 探针缺省档比较三项：`Enabled=false`、输出字符数 `0`、`FamilyCoverageQuery.Stats.Queries` 调用前后 `0->0` ⇒ `SELFTEST_DEFAULT_ASSERT=PASS` |
| ④ 命令行 + 原始输出 | 见下（两档原始输出） |

**命令行**
```
dotnet build build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj -c Debug -m:1    # 0 错 0 警
dotnet build build/MilBridge/tests/FamilyCoverageSelfTest/FamilyCoverageSelfTest.csproj -c Release -m:1   # 0 错 0 警
D=build/MilBridge/tests/FamilyCoverageSelfTest/bin/Release/MilBridge.FamilyCoverageSelfTest.dll
dotnet $D              # ① 缺省档：断言"什么都不做"
dotnet $D --enabled    # ② 打开档：两条链并排
```
**原始输出 ①（缺省档）**
```
SELFTEST_ARM=default env=<未设> dirs=[/usr/share/fonts] family=<第一个族>
SELFTEST_PROVIDER dll=…/bin/Release/DirectWrite.Linux.Provider.dll sha256=a3c026c501ee96214aa47441ff30f83838ce9a9f6873d81bc164ba81fec30b91
SELFTEST_COLLECTION families=165 files=299
SELFTEST_BASEFAMILY name=AR PL UKai CN
SELFTEST_REPORT enabled=False ran=False samples=0 disagreements=0 queries=0->0 lines=0 raw=<未设>
SELFTEST_DEFAULT_ASSERT=PASS enabled=False ran=False outputChars=0 queries=0->0
```
**原始输出 ②（打开档，节选）**
```
SELFTEST_REPORT enabled=True ran=True samples=9 disagreements=0 queries=0->52 lines=12 raw=1
[COVERAGE_SELFTEST] probe: face=MS.Internal.Text.TextInterface.Linux.FamilyCoverageQuery@DirectWrite.Linux.Provider
   Covers(Family,int)=有 QueryCoverage(Family,int)=有 QueryCoverage(Collection,int,out Family)=有 TryFindFamilyCovering=有
[COVERAGE_SELFTEST] U+0041 base:provider=Covered    cmap=Covered    | 覆盖族:provider=AR PL UKai CN cmap=AR PL UKai CN
[COVERAGE_SELFTEST] U+4E2D base:provider=Covered    cmap=Covered    | 覆盖族:provider=AR PL UKai CN cmap=AR PL UKai CN
[COVERAGE_SELFTEST] U+AC00 base:provider=NotCovered cmap=NotCovered | 覆盖族:provider=Droid Sans Fallback cmap=Droid Sans Fallback
[COVERAGE_SELFTEST] U+1F600 base:provider=NotCovered cmap=NotCovered | 覆盖族:provider=DejaVu Sans cmap=DejaVu Sans
[COVERAGE_SELFTEST] stats: queries=0->52 covered=16 notCovered=36 unknown=0 disagreements=0
SELFTEST_ENABLED_ASSERT=PASS enabled=True ran=True outputChars=1434 samples=9 disagreements=0
```
⇒ **两条链 9/9 一致**（provider 面 = Skia 口径；cmap 面 = 本文件自带的**独立第二实现**，format 4/12 + TTC 面下标）
⇒ §5 里那条"降级链 b 无运行期实证"的红，**以常设、可跑、可复验的形式关掉**。
（注：本文件的 cmap 读取器是**对照用**的独立实现；产品路径里那份读取器的实测见 §8.2。）

---

## 11. D-d 定位（**只定位、未改任何行为**）：1×1 是**上游的"解码失败占位"**，触发者是 **shim 不支持子矩形 `CopyPixels`**

### 11.1 结论（一句话）

`BitmapSource.Create(96×96 Bgra32)` 本身**没问题**（样例自报 `PixelWidth=96 PixelHeight=96 Format=Bgra32`）。
问题发生在**提交到 MIL 的那一刻**：上游 `BitmapSource.DUCECompatiblePtr` 为了"强制在 UI 线程解码整图"，
会对源做一次 **1×1 的 `CopyPixels` 探针**；我们的 WIC shim **只支持整图 `CopyPixels`**，
对子矩形**诚实地返回 `WINCODEC_ERR_UNSUPPORTEDOPERATION`**；上游把这个失败当成
**"像素数据损坏 / 解码失败"**，于是按既有设计把源**换成 1×1 的 Pbgra32 空图**并抛 `DecodeFailed`。
⇒ 交给 MIL 的就是那张 1×1 占位图（与 M7b 的进程内 trace 逐字节吻合）。

### 11.2 逐跳定位（文件:行 + 判定条件）

| # | 位置 | 发生什么 | 判定条件 |
|---|---|---|---|
| 1 | 样例 `samples/WpfTextDemo/MainWindow.xaml.cs:211` | `BitmapSource.Create(N,N,96,96,PixelFormats.Bgra32,null,px,stride)` | — |
| 2 | 上游 `Imaging/BitmapSource.cs:47` → `CachedBitmap.cs:85` | 返回 `CachedBitmap`，构造里 `IsSourceCached = true` | — |
| 3 | 上游 `BitmapSource.cs:877` `AddRefOnChannelCore` → `:739 UpdateResource` → `:913 UpdateBitmapSourceResource` | 提交时取 `DUCECompatiblePtr` | `_duceResource.IsOnChannel` |
| 4 | 上游 `BitmapSource.cs:742` `DUCECompatiblePtr` | 决定走哪条路 | **`:757 if (UsableWithoutCache)`**，而 `UsableWithoutCache = HasCompatibleFormat && _isSourceCached`（`:1561-1566`）⇒ **true**（Bgra32 在 `s_supportedDUCEFormats` 里 `:1602`；`CachedBitmap` 已 cached） |
| 5 | 上游 `BitmapSource.cs:773-795` **1×1 探针** | `Int32Rect(0,0,1,1)`；`bufferSize=(32+7)/8=4`；`new byte[4]`；`WICBitmapSource.CopyPixels(src, rect, 4, 4, buf)` | 目的写在注释里：*"we call CopyPixels for the first pixel which will decode the entire image"*（**故意**的整图解码手段） |
| 6 | **`build/DirectWrite.Linux/wic-shim/wic_proxy.c:1035-1053`** | `full = (!prc) \|\| (x==0&&y==0&&(w==0\|\|w==width)&&(h==0\|\|h==height))` ⇒ 探针 `(0,0,1,1)` 对 96×96 源 **不是 full** ⇒ **`return WINCODEC_ERR_UNSUPPORTEDOPERATION`** | 代码注释原文："*本轮明确只支持整图 —— 不支持的形态给 UNSUPPORTEDOPERATION，不静默截断*" |
| 7 | 上游 `BitmapSource.cs:797-803` | `catch (Exception e) { RecoverFromDecodeFailure(e); pIWICSource = WicSourceHandle; }` | `HRESULT.Check(...)` 抛 |
| 8 | **上游 `BitmapSource.cs:950-957` `RecoverFromDecodeFailure`** | **换源**：`WicSourceHandle = Create(1, 1, 96, 96, PixelFormats.Pbgra32, null, new byte[4], 4).WicSourceHandle; IsSourceCached = true;` 然后 `OnDecodeFailed(...)`（抛 `DecodeFailed` 事件） | 上游注释："*Set the source to an empty image in case the user doesn't respond to the failed event*" |
| 9 | 上游 `BitmapSource.cs:870-874` | `CreateCWICWrapperBitmap(pIWICSource /* 已经是 1×1 */, out wrapper)`；`_convertedDUCEPtr` 缓存它 | — |
| 10 | MIL（M7b 的 trace） | 收到 **`size=1x1 rowBytes=4 format=…c910 decoded=1 foreign=0 ownedByWic=1`** | — |

**另一条分支已排除**：`:806 else (needs caching)` 那条走 `CreateFormatConverter` + `CreateBitmapFromSource`；
后者在 shim 里是**真实现**（`wic_proxy.c:865-899`：整图物化 + memcpy，内存位图不会失败）
⇒ 不会产生 1×1 ⇒ **落到 `RecoverFromDecodeFailure` 的就是第 5 步那条探针**。

### 11.3 它是什么：**"解码失败占位"，不是"尺寸查询返回 0 的兜底"**

`RecoverFromDecodeFailure` 是上游**文档化**的兜底（"给用户一张空图，同时抛 `DecodeFailed` 让他优雅处理"）。
⇒ 真问题不是"PC 选错了源"，而是**"我们 shim 的一次诚实拒绝"被上游归类成"解码失败"**。
尺寸来源不是查询失败：句柄里那份对象**自己就报 1×1**（`describe … size=1x1`），因为它是**刚被造出来的空图**。

### 11.4 可判据（**零代码改动**，已实跑）

```
bash build/MilBridge/tools/t1c-census.sh /tmp/dd default \
     WPF_LINUX_CWIC_TRACE=1 WPF_LINUX_WIC_TRACE=1
```
原始行（本次实测）：
```
WIC_TRACE COPY_PIXELS h=2 96x96 rowBytes=384 foreign=0        ← 第 5 步的探针打在 **96×96 的源**上（rect 不在这行里，见 §11.5）
WIC_TRACE COPY_PIXELS h=3 1x1 rowBytes=4 foreign=0            ← 换源之后，句柄 h=3 已经是 1×1 的占位
[cwic-trace] source=0x3 ownedByWic=True materialize尺寸=1x1 foreignSources=0 shimGetSize=1x1（第二次=1x1 ok=True）
             format=6fddc324-4e03-4bfe-b185-3d77768dc910 → SKBitmap=1x1 colorType=Bgra8888 alphaType=Premul stride=4 bufferSize=4 copyPixels=S_OK
[cwic-trace]   describe(source)= h=3 via=slot kind=Frame/Source foreign=0 ownedByWic=1 refs=4 size=1x1 rowBytes=4 fmt=…c910 pixels=yes decoded=1
[wptd] 位图源自报：BitmapSource PixelWidth=96 PixelHeight=96 Format=Bgra32 DpiX=96     ← 源侧没问题
```
**判据的核心是格式 GUID 判等**（不靠猜）：
* 样例那张图是 **Bgra32** = `WICPixelFormat32bppBGRA` = `…c9**0f**`（上游 `WpfGfx/include/wgx_exports.cs:266`）；
* 交到 MIL 的却是 `…c9**10**` = **`WICPixelFormat32bppPBGRA`**（同文件 `:267`）；
* 而 `RecoverFromDecodeFailure` 恰好就是用 **`PixelFormats.Pbgra32`** 造占位（`BitmapSource.cs:953`）。
⇒ **"交下来的不是样例那张图，而是占位图"这件事，由格式 GUID 独立坐实**（不需要任何插桩）。

### 11.5 观测缺口（**这也是一条缺陷**，建议同批修）

`wic_proxy.c` 的 `COPY_PIXELS` trace **只打源的尺寸，不打 `prc`（矩形）也不打拒绝原因**；
而"子矩形 ⇒ `UNSUPPORTEDOPERATION`"这条路径**完全静默**（只有 `decode_pixels` 失败那条有 `WIC_TRACE FAIL`）。
⇒ 只看 shim 日志会得出"`CopyPixels` 被调过、看起来正常"的**错误结论**（"仪器沉默 ≠ 没发生"，本项目的老朋友）。

### 11.6 候选修法（**未实施，等主控裁定**）

| 方案 | 落点 | 说明 | 我的评估 |
|---|---|---|---|
| **A（首选）** | shim `IWICBitmapSource_CopyPixels_Proxy`（`wic_proxy.c:1049-1053`，**T2 车道**） | 支持任意 `prc`：按矩形逐行拷贝（shim 的像素**已整图解码**，实现只是行偏移算术）；顺带把 `prc` 与拒绝原因加进 trace | **最小且最贴合上游语义**（Windows 的 WIC 支持任意 rect；探针是上游**故意**的"UI 线程解码"手段）。风险低 |
| B | 同上，但只特判 1×1 | 语义最小改动 | 次选：治了症状没治形态（别的 rect 仍会踩） |
| C | PC 侧绕开探针（我的车道） | 改 `UsableWithoutCache` 或跳过探针 | **不推荐**：会削弱"渲染线程不解码"的正确性保证，且属**行为改动**，须单独立项 |

**建议主控裁定**：按 **A** 派给 T2（一句话可验收：`WPF_LINUX_WIC_TRACE=1` 下探针那次 `CopyPixels` 返回 `S_OK`，
且 `[cwic-trace]` 里的 `size` 从 `1x1` 变回 `96x96`、`fmt` 从 `…c910` 回到 `…c90f`；样例卡片图的四象限色重新出现）。
我这轮**没有**动 shim、没有动 `src/WpfGfx.Linux/**`、没有重建 PC。

> **版本标注**：本节所有读数取自**当次部署件**；此前 §9 引用的桥 sha `cefd7281…` 是**当时那一版**，
> 主控已告知最新部署桥为 `f519eff9d0559eec11cd17968934f470b2bce16acd1a208803471ed4d150d365`（4,900,752 B）。

---

## 12. R1 收口验证：**per-段 `GlyphRun` 真的拿到了对应的面**（2026-09-11 晚，权威 PC `f31822ce…`）

**装置**：`bash build/MilBridge/tools/t1c-census.sh /tmp/t1c-r1 default WPF_LINUX_GLYPH_CENSUS=1 \
WPF_LINUX_FACE_HANDOFF_DIAG=1 WPF_LINUX_GLYPH_FACE_CENSUS=1 WPTD_DISPLAY=:96 HOLD_SECONDS=30`
（**无 `PC_OVERRIDE` = 跑权威件**；`:96` 当时已存活 ⇒ 复用、未自起 Xvfb ⇒ 无 PID 需杀；本装置只在自起时按 PID 收尾，从不 `pkill`）

**产物（读数文件里的 `ARTIFACT` 行；与官方 runner 的 `WPTD_ARTIFACTS` 等价）**
```
WPTD_ARTIFACTS bridge_sha=f519eff9c892a31e bridge_bytes=4900752 pc_sha=f31822ce4a3e510d
               pf_sha=24a1260262483979 shim_sha=4c023937421db45f
ARTIFACT wpfgfx_cor3.so        f519eff9c892a31e272a0f61ca538a85181d5a863b63840ce130ed87ab26bf44 (4900752)
ARTIFACT PresentationCore.dll  f31822ce4a3e510d5cd724a6654b29a29bb44d3a8027cec33f5116e89c09101b (4155904)
ENV tier=default WPF_LINUX_GLYPH_CENSUS=1 WPF_LINUX_FACE_HANDOFF_DIAG=1 WPF_LINUX_GLYPH_FACE_CENSUS=1
uptime: 19:11 up 2 days, load 2.78/2.34/5.75 ; free -m: total 7923 used 4230 free 727
```

### 12.1 ① `[FACE_HANDOFF]` 逐条登记（**恰好 4 个令牌**）

```
[FACE_HANDOFF] Install: WPF_LINUX_FACE_HANDOFF=<未设> ⇒ 解析为 **开**（未设时就是开）; handoff=on(未设即开)
               status=NativeAotExport registerExport=找到(MilFontFace_RegisterFromFile) allocatorCalls=0 nativeAllocations=0
[FACE_HANDOFF] 登记#1 token=0x20000003 path=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf        faceIndex=0 simFlags=0
[FACE_HANDOFF] 登记#2 token=0x20000004 path=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf             faceIndex=0 simFlags=0
[FACE_HANDOFF] 登记#3 token=0x20000005 path=/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc      faceIndex=0 simFlags=0
[FACE_HANDOFF] 登记#4 token=0x20000006 path=/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc         faceIndex=0 simFlags=0
```

### 12.2 ② 三点对齐（token ↔ 登记 (path,faceIndex) ↔ 逐 run pid ↔ 渲染器实际用的面）

| token | 登记时的 (path, faceIndex) | 逐 run `pid`（明细行，上限 40） | 渲染器实际用的面（整帧，M7b 字段） |
|---|---|---|---|
| `0x20000003` | `DejaVuSans-Bold.ttf` #0 | 5 | `DejaVu Sans` / `DejaVuSans-Bold.ttf#0` / **覆盖U+4E2D=否** / runs=13 |
| `0x20000004` | `DejaVuSans.ttf` #0 | 17 | `DejaVu Sans` / `DejaVuSans.ttf#0` / **覆盖U+4E2D=否** / runs=57 |
| **`0x20000005`** | **`NotoSansCJK-Regular.ttc` #0** | 14 | `Noto Sans CJK JP` / `NotoSansCJK-Regular.ttc#0` / **覆盖U+4E2D=是** / runs=49 |
| **`0x20000006`** | **`NotoSansCJK-Bold.ttc` #0** | 4 | `Noto Sans CJK JP` / `NotoSansCJK-Bold.ttc#0` / **覆盖U+4E2D=是** / runs=12 |

* **路径逐字相同**（4/4）⇒ 令牌携带的 `(path, faceIndex)` 与渲染器实际打开的文件**完全一致**；
* 新增的 `0x20000005/06` **指向 CJK 面且 `覆盖U+4E2D=是`** ✓（与期望一致）；`0x20000003/04` 仍是 DejaVu 且 `否` ✓；
* 渲染器四分面 `runs=13/57/49/12` **合计 131 = 整帧 `runs(绘制次数)=131`**（逐项对得上）；
  逐 run pid 计数取自**明细行**（每帧上限 40）⇒ `5/17/14/4 = 40`，**次序与比例一致、总数被上限截断**（不拿它当整帧数）。

### 12.3 ③ 那个坑**没有被踩上**

`[FACE_HANDOFF] … path 为空 ⇒ 不接管` 出现次数 = **0**；4 条登记**全部带完整文件路径** ⇒
T1d"每段的面都是文件路径 + faceIndex"的说法在**本次配置**下成立（⇒ 路径式分配器接管，未回落进程内表）。
**范围限定**：这次没有出现"字节流造的 face"（`FromBytes ⇒ SourcePath==null`）那条路；它在本样例里未被触发，
所以这是**对该配置的证实**，不是对"任何输入都不会踩"的证明。

### 12.4 与主控读数的对照（**逐项一致**）

```
[GLYPH_CENSUS] frame=3 runs(绘制次数)=131 不同句柄=131 全notdef的run=0 glyphs=1276
               id0=0 maxId=63151 非拉丁(id>=0x1000)=322
               桶[0]=0 [1,FF]=939 [100,FFF]=15 [1000,3FFF]=98 [>=4000]=224
               面标识: pid==0的run=0 不同面数=4
[glyph-census] 四个面 zeroIds 全 0（含 CJK 面）
SHOT frames=3 best_colors=3679 best=/tmp/t1c-r1/shot-5.png
```
⇒ `id0=0 / nonlatin=322 / maxId=63151 / 面数=4` 与主控读数**逐项相同**；另附 `T1C_CENSUS_SUMMARY` 机读行：
`frame=3 runs=131 handles=131 glyphs=1276 id0=0 nonlatin=322 maxid=63151 allnotdefruns=0 distinctpids=4`。

---

## 13. 装置修复：普查装置**不再漏孤儿应用进程**（T3 报的那一族）

**装置**：`build/MilBridge/tools/t1c-census.sh`（sha256 `5eac3bda23b117b6a278420df4c8fdd7b911b3500357bef306cb2e524e1d1e5c`，339 行）
**范围**：只改这一个文件（`t1c-census-summary.py` 未改）；未动 `samples/**`、`build/shims/**`、`build/*.Linux/**`、`src/**`。

### 13.1 根因（T3 的归因 + 代码确认，两条独立证据）

旧代码：
```bash
( cd "$RUN" && env … dotnet WpfTextDemo.dll > "$LOG" 2>&1 ) &     # ← 后台起的是**子 shell**
APP_PID=$!                                                        # ← $! 是子 shell 的 PID，不是 dotnet
…
kill -TERM "$APP_PID"                                             # ← 只杀掉子 shell
```
子 shell 一死，`dotnet` 被 reparent 到 **ppid==1** 并带着 ~2 GB RSS 留下（T3 的回收器实测抓到 1 个：`ppid==1`、RSS 2.0–2.1 GB）。
**"rc 正常、日志完整"正是它难发现的原因** —— 收尾看起来成功了。

### 13.2 修法（逐条对应主控给的四条）

| # | 要求 | 落地 |
|---|---|---|
| 1 | 起应用用 `exec`，让 `$!` **就是应用** | `( cd "$RUN" && exec env … dotnet WpfTextDemo.dll > "$LOG" 2>&1 ) &` —— 子 shell 被子 shell 内 `exec` 取代 ⇒ `$!` 即 dotnet |
| 2 | 不用 `pkill -f`、命令行不写要匹配的进程名 | 全文**没有任何** `pkill/pgrep/setsid` 调用（只剩注释）；收尾一律 `kill <PID>` + `wait` |
| 3 | 收尾**断言无残留**（`/proc/<pid>/cmdline` 精确比对；**只认 ppid==1**），有残留**报出来** | 新增 `list_app_orphans()`：`ppid==1 ∧ basename(argv[0])=='dotnet' ∧ argv[1]=='WpfTextDemo.dll' ∧ cwd 以 /tmp/t1c 开头`；有残留 ⇒ 打印列表 + `❌` + **装置退出码 1** |
| 4 | 固定输出行 + 复跑验证 | 固定行 `CENSUS_ORPHANS before=0 after=0`（同时进 stderr 与读数文件）；另加启动自证行 `[自证] APP_PID=… 的 cmdline 含 WpfTextDemo.dll ✓（$! 就是应用，不是子 shell）` |
| ＋ | 顺手同类隐患 | ① 自起的 Xvfb **不再用 `setsid`**（`setsid` 可能 fork ⇒ `$!` 不是 Xvfb ⇒ 按 PID 收尾会漏），并校验 `/proc/$XPID/cmdline` 像 Xvfb；② 新增 `trap 'cleanup; exit 143' TERM INT`（`timeout` 发 SIGTERM 时 EXIT trap 不跑 ⇒ 自起的 Xvfb 会变孤儿） |

### 13.3 复跑（**同一套参数**，`:96`；装置改了、读数必须不变）

```
bash build/MilBridge/tools/t1c-census.sh /tmp/t1c-r1b default \
     WPF_LINUX_GLYPH_CENSUS=1 WPF_LINUX_FACE_HANDOFF_DIAG=1 WPF_LINUX_GLYPH_FACE_CENSUS=1 \
     WPTD_DISPLAY=:96 HOLD_SECONDS=30
   [自证] APP_PID=1348871 的 cmdline 含 WpfTextDemo.dll ✓（$! 就是应用，不是子 shell）
   SHOT frames=6 best_colors=3679 best=/tmp/t1c-r1b/shot-1.png
   APP_EXIT rc=143
   CENSUS_ORPHANS before=0 after=0
   T1C_CENSUS_SUMMARY frame=3 runs=131 handles=131 glyphs=1276 id0=0 nonlatin=322 maxid=63151 allnotdefruns=0 distinctpids=4
   → 装置退出码 0（CENSUS_ORPHANS before=0 after=0；自起 Xvfb=1348722）
```
**读数与改前逐项相同**（改前那一轮：`frame=3 runs=131 handles=131 glyphs=1276 id0=0 nonlatin=322 maxid=63151 allnotdefruns=0 distinctpids=4`）
⇒ **装置改了，观测没变** ✓；且 `before=0 after=0`、退出码 0。

### 13.4 收尾证据（含"不误伤别人"）

* 自起的那台 Xvfb（PID `1348722`）**已按 PID 收掉**（复算：进程不存在）；`:98` / `:99`（别人的）**仍 ALIVE**、未被触碰 ✓
* 残留孤儿复算（同一判据）= **0** ✓
* **判据的反例自检**（免得"只认 ppid==1 ∧ dotnet"误伤别人）：本机此刻有 **5 个 `ppid==1` 的 dotnet**，全是 MSBuild worker（`argv[1]==MSBuild.dll`）⇒ 被 `argv[1]=='WpfTextDemo.dll'` 正确排除；我自己那条命令行里含 `WpfTextDemo.dll` 字面量的 `bash -c` 也被 `basename(argv[0])=='dotnet'` 排除 ✓

### 13.5 如实说明（没做的那一步）

我**没有故意复现泄漏**（内存当时只剩 ~727 MB free / 2.2 GB available，故意再开一个 2 GB 应用会牵连同机的 `verify-all.sh`）。
机制已由两条独立证据坐实：① T3 的回收器**实测抓到** `ppid==1`、2.0–2.1 GB 的孤儿；② 新装置的 `[自证]` 行直接证明**修后 `$!` 就是应用**（修前不是）——
"改这一处 → 现象翻转"的对照正好落在这条自证行上，不需要再制造一次泄漏。

---

## 14. 字体度量诊断（只读；主控派单："多行摞印的可能真凶是不是 provider 的度量"）

**结论先说：按代码与字体文件真值算，行距应是 14–21 DIP，而观测步长是 0.928 DIP ⇒ 差 15–22 倍。
⇒ "度量/行距公式"这条**不被支持**；真凶在别处，并且我用两条算术把它缩小到了"DIP 浮点路径 + 行高塌成 ~1 量级"。**

### 14.1 度量链路（逐跳，file:line）

| 跳 | 位置 | 干什么 |
|---|---|---|
| ① 取表 | `build/DirectWrite.Linux/Provider/MetricsFactory.cs:130-149` | `DesignUnitsPerEm = head.unitsPerEm`；**`Ascent/Descent/LineGap = hhea.ascender / -hhea.descender / hhea.lineGap`**；`CapHeight/XHeight/下划线/删除线 = OS/2 + post`；**只有 hhea 全 0** 才回落到 `OS/2.usWin*`。每次读数都带 `Provenance` 原文（既有工件例：`PROVENANCE upem=head; asc/desc/gap=hhea(1069,-293,0); …`，`build/DirectWrite.Linux/artifacts/probe-summary.txt:4-6`） |
| ② 比例 | `Provider/MetricModels.cs:66,82` | `Baseline = (Ascent + LineGap*0.5)/upem`；`LineSpacing = (double)(Ascent+Descent+LineGap)/upem` |
| ③ 骨架同名成员 | `build/DirectWriteForwarder.Linux/ManagedSurface.cs:335,342` | **两处都带 `(double)` 强转** ⇒ 不会发生整数除法塌成 1 |
| ④ 适配 | `build/DirectWriteForwarder.Linux/ProviderAdapters.cs:52-69` | 字段逐一拷贝，无重算 |
| ⑤ 显示度量 | `Provider/MetricsFactory.cs:224-256`（`ToDisplay`） | 每个字段吸附成"像素为整数"的**设计单位值**（`round(round(v·scale)/scale)`），**并保留 `DesignUnitsPerEm`** ⇒ 比例不失真 |
| ⑥ 行距公式 | 上游 `PhysicalFontFamily.cs:422-433` | Ideal：`emSize × ratio`；Display：`RoundDipForDisplayMode(DisplayMetrics(realEmSize,ppd).LineSpacing × realEmSize, ppd) / toReal` |
| ⑦ 消费 | 上游 `Typeface.cs:275,280` → `SimpleTextLine.cs:1338,1349`（`SimpleRun.Height/Baseline`，`toReal=1`、em 以 **DIP** 计）与 `:325`（**仅空行**用 `DefaultTypeface.LineSpacing`，`toReal=1/300`、em 以 **ideal** 计） | 非空行的行高 = 该行 **run 的 Height 取大**，不是 `LineSpacing` 本身 |

**⚠️ 一条要纠正的旧记录**：`MetricModels.cs:68-82` 的注释说"骨架漏了 `(double)` ⇒ Noto Sans 会返回 1.0 而不是 1.362，直接影响行高"。
**我逐字读了当前文件：`ManagedSurface.cs:342` 已经有 `(double)` 强转**（`:335` 的 `Baseline` 因 `LineGap*0.5` 本来也是 double）
⇒ **那条隐患已不存在**（注释过时），**不要再把它当成未修的行高 bug**。

### 14.2 两枚面的**实际数值**（字体文件真值 = provider 声称读取的同一批字段）

| face | upem | hhea (asc, desc, gap) | ratio=(asc+desc+gap)/upem | **em 12 / 13 / 14 DIP 的行距** |
|---|---|---|---|---|
| `DejaVuSans.ttf`（default 档实际用的族） | 2048 | (1901, −483, 0) | **1.164062** | **13.969 / 15.133 / 16.297** |
| `DejaVuSans-Bold.ttf` | 2048 | (1901, −483, 0) | 1.164062 | 13.969 / 15.133 / 16.297 |
| `NotoSansCJK-Regular.ttc#0`（R1 新增的 CJK 面） | 1000 | (1160, −288, 0) | **1.448000** | **17.376 / 18.824 / 20.272** |
| `build/fonts-ui/UI-NoLayout.ttf`（部署 UI 字体，env 档） | 1000 | (1069, −293, 0) | 1.362000 | 16.344 / 17.706 / 19.068 |

（`NotoSansCJK-Regular.ttc` 是 **10 面**的 TTC；上表是 **face#0** —— provider 取的就是它。
本表由**只读解析字体文件**算出，命令与实现在报告末尾；**没有跑应用、没有跑探针**。）

### 14.3 与真值对照（主控第 2 条）

* **`tests/parity/systemfonts/windows-results.json`：没有对应项。**
  实测：该 JSON 里 `ascent/ascent/LineSpacing` 等度量字段 **0 个命中**；字体集合里**没有 `DejaVu Sans`**（只有 `DejaVu Math TeX Gyre`、`DejaVu Sans Mono`），**也没有任何 Noto CJK**
  ⇒ **按主控要求明说"没有"**，**不拿别的字体凑**。
* 但**行度量**的真机真值在另一份 oracle 里：`build/MilBridge/gen/layout-b34-compact.json`（真机 614 例）
  ⇒ `fontSize=16` 时 `h = 21.7933 / 21.1167 / 25.6333`、`bl = 17.1033 / 16.93 / 18.2767`（DIP）
  ⇒ **真机行高 ≈ 1.32–1.60 × em**，与我上面按公式算的 14–21 DIP **同量级**。

### 14.4 算一遍行距 ⇒ **公式不解释 0.928 DIP**（并按主控要求把"别处"缩小）

* 公式（Ideal 分支，`emSize` 以 DIP 计）：`lineHeight = emSize × (asc+desc+gap)/upem`
  ⇒ DejaVu @12.5 DIP = **14.55 DIP**；NotoCJK @12.5 = **18.10 DIP**。**与实测 0.928 DIP 差 15–20 倍。**
* **两条算术排除**（不依赖任何未测项）：
  1. **0.928 不在 LS ideal 网格上**：ideal 网格步长 = `DefaultIdealToReal` = 1/300 DIP；
     `0.928 × 300 = 278.4 ∉ ℤ` ⇒ 它**不是** `IdealToReal(int)` 的输出，**也不是**两个这种输出之差
     （整数倍 1/300 的差仍是 1/300 的整数倍）⇒ **这些 Y 值来自 DIP 浮点路径，不是 ideal 单位路径**。
     （旁证：`11.139 × 300 = 3341.7`、`12.995 × 300 = 3898.5` 同样不在网格上，超出 F.3 打印的取整容差。）
  2. **0.928 ≈ 1 个设备像素**：`1/0.928 = 1.0776`。若 `TextFormattingMode=Display` 且 `ppd=1.0776`，
     则 `RoundDipForDisplayMode(v,ppd)=round(v·ppd)/ppd` 的输出正是 1/ppd 的整数倍 ⇒ 那意味着
     **行高被算成 ~1 DIP 量级（约 1/15），而不是 14–21**。
     ⚠️ **但这个 ppd 我在现有读数里查不到**：窗口 XAML 是 `Width=900 Height=900`，而截到的窗口是 **938×938 px**
     ⇒ 若 900 按 DIP 解释则 `ppd=1.0422`（此时 0.928 **不是**整数个像素）；若 900 被当成 px 再加 38 px 边框，则它是 938 px、`ppd=1.0`。
     ⇒ **"1 px" 与 "1.0422 ppd" 两种解释互斥，靠现有读数判不了** —— 这正是下一步要补的仪器（见 14.5）。
* ⇒ 按主控给的判据（"公式给出 ~16 DIP 而实测 0.928 ⇒ 真凶在别处"）：**真凶在别处**，
  且已被缩小到：**一条 DIP 浮点路径，且行高塌成 ~1 量级**（≈ 1 px 或 ≈ 1 DIP，取 14.5 的读数定夺）。

### 14.5 下一步判据（**需要跑一次应用 ⇒ 等主控许可/slot**；不改行为，只加只读一行）

在 `SimpleRun.Height/Baseline`（`SimpleTextLine.cs:1338/1349`）与 `SimpleTextLine.cs:325` 的调用点**各加一条 gated trace**
（`WPF_LINUX_LINEHEIGHT_TRACE=1`，缺省关、有界），打印**每个 run/每行**：
```
[fam=<族名>] FontRenderingEmSize=<DIP> ppd=<pixelsPerDip> mode=<Ideal|Display>
             LineSpacing(em,toReal,ppd)=<ret>  Baseline(...)=<ret>  run.Height=<ret>  line._height=<ret>
```
一跑就能把 0.928 归到**唯一**一类：
1. `emSize` 太小（如 ~0.8 而不是 ~12.5）⇒ 上游传参/单位问题；
2. `ppd` 太大/太小 ⇒ 设备变换问题；
3. `LineSpacing(...)` 返回值 ≈ 0.07–1 ⇒ **度量比例塌了**（那时才轮到 provider 的度量，用 §14.1 的链路逐跳查）；
4. 以上都正常（≈14–15 DIP）而 Y 仍是 0.928 ⇒ 真凶在 **`BaselineOrigin` 语义/渲染变换链**（`GlyphRun.BaselineOrigin → IndexedGlyphRun → MilGlyphRun → 渲染器`）。
**没有这条读数之前，我不宣称任何一类**（避免"读代码推因果"当结论）。

**§14.2 那张表的复算命令**（只读字体文件；不跑应用/探针，<1s）：
见 `build/MilBridge/T1c-report.md` 本节的提取脚本（hhea/head/OS-2 逐字段解析，含 TTC 面下标）。

---

## 15. 行高/行偏移：**先写归因表，再插桩**（主控批准的执行口径；本轮**未跑应用**）

### 15.1 🔴 重大发现（纯算术 + XAML 对齐，**5/5 命中 <0.001 DIP**）：那 6 个 origin Y 是 `FontSize × DejaVu 基线比`

T2b 的读数：`distinct_origin_y=6  Y值(DIP)=[10.210,10.210,11.139,12.067,12.995,24.133]`
样例 XAML 的**全部字号**：`FontSize="11"/"12"/"13"/"14"/"26"`（`samples/WpfTextDemo/MainWindow.xaml`，唯一集合）
DejaVuSans 的 `hhea.ascent / head.unitsPerEm` = **1901/2048 = 0.928223**

| FontSize | 计算 `FontSize × 0.928223` | 观测 Y | 差 |
|---|---|---|---|
| 11 | 10.2104 | **10.210** | 0.0004 |
| 12 | 11.1387 | **11.139** | 0.0003 |
| 13 | 12.0669 | **12.067** | 0.0001 |
| 14 | 12.9951 | **12.995** | 0.0001 |
| 26 | 24.1338 | **24.133** | 0.0008 |

⇒ **origin Y 是"FontSize"的纯函数**（真源 = `SimpleTextLine._baselineOffset` 那条链：`run.Baseline =
emSize × (ascent/upem)` 取大 → `IdealToReal(RealToIdeal(...))`）⇒ **同一字号的 run，无论在**哪一行**，拿到的 origin Y 完全相同**
⇒ **每一行都被画在同一个 Y 上 = "多行摞印"** ✓✓（与"多个 x=0 起始的 run 共享同一个 Y"完全自洽）

**同时纠正主控那条"行推进 0.928 DIP"的读法**：`0.928` 不是行距，而是 **FontSize +1** 带来的 `_baselineOffset` 增量
（`(n+1)×0.928223 − n×0.928223 = 0.928223`）⇒ 那 6 个值是 **6 个字号的行内基线偏移**，不是 6 行的位置。

### 15.2 ⚠️ 我自己的更正（§14 的排除项 #1 **不成立**）

§14 我写"`0.928 × 300 = 278.4 ∉ ℤ` ⇒ 不在 1/300 ideal 网格 ⇒ 不是 `IdealToReal(int)` 的产物"。
**这条排除是错的**：日志用 `F.3` 打印（±0.0005 DIP ⇒ 在 ideal 单位里 ±0.15），而 `11.139 × 300 = 3341.7`
与真正的理想值 `3342`（= `round(11.1387×300)`）只差 0.3 —— **判据的容差被我估错了**，够不着"排除"的强度。
正确的判据是 §15.1 那条**整数倍恒等式**（5/5，误差 <0.001 DIP）。**保留 §14 的其余部分**（度量链路与数值、oracle 无对应项、公式算得 14–21 DIP）。

### 15.3 归因表（五类互斥；**先写判据，跑完只填数**）

读数来源：`WPF_LINUX_LINEHEIGHT_TRACE=1`（缺省关、≤60 行）打出的四类行：
`run.Baseline` / `run.Height` / `line … _height _baselineOffset` / `draw origin=(x,y) …`。

| 类 | 判据（**看到什么才算这一类**） | 结论指向 |
|---|---|---|
| **(1) emSize 太小** | `run.*` 行里 `em` 明显小于该 run 应有的 DIP（如 ~0.8 而非 11–26） | 上游传参/单位（em 与 ideal 混用） |
| **(2) ppd 异常** | `ppd` 不为 ~1（如 1.0776/1.0422 之外的怪值，或与窗口不匹配） | 设备变换链（`pixelsPerDip` 来源） |
| **(3) 度量/rato 塌了** | `run.Height` 返回值 ≈ 0.07–1（而不是 `em × 1.16` ≈ 13–30）**且** `line._height` 同步塌 | **才轮到 provider 度量**（按 §14.1 逐跳查） |
| **(4) 行偏移没带上** | `run.*` 与 `line._height` 都正常（≈13–30），但 **`draw origin=(x, y)` 的 `y` 每行相同**（或 `y == _baselineOffset`，即只含行内基线偏移、不含该行在段落里的位置） | **宿主/存储的行推进**（`TextLine.Height/TextHeight` 的消费者、PF 侧行定位） |
| **(5) 以上都正常** | 四类行都正常（`run.Height`≈13–30、`origin.y` 逐行递增）却仍摞印 | `BaselineOrigin → IndexedGlyphRun → MilGlyphRun → 渲染器` 语义/变换链（`src/WpfGfx.Linux/**`，需报主控） |

**当前先验**（来自 §15.1 的纯算术）：**最像 (4)**（`origin.y` = `_baselineOffset`，与行号无关）。
但这只是**先验**，**等读数落格**（主控的 slot 放行后再跑）。

### 15.4 插桩应用器（已落地，四道闸门全绿；**未跑应用**）

* 应用器：`src/WpfGfx.Linux.Native/tools/patch-presentationcore-lineheight-trace.py`
  sha256 `175fca92b9bbbb3a724b695e1a5873efb2a0f85527c429e6cae1b5b6c4ff30a6`
* 生成物：`build/PresentationCore.Linux/SimpleTextLine.Linux.cs`
  sha256 `78121619095fefe7fa6e1f43f7127564270dcac12d93e497f3b77ee52cd8f959`（上游 2015 行 → 2130 行，+115）
* 5 处**逐字锚点**（各恰好 1 次）：① `SimpleRun.Baseline` 的 return；② `SimpleRun.Height` 的 return；
  ③ 行级 `_height/_baselineOffset` 定值之后；④ `Draw(...)` 收到 `origin` 之后；⑤ 插桩类本体（插在 `internal class SimpleTextLine : TextLine` 之前）。
* **只读三条**：缺省关（`WPF_LINUX_LINEHEIGHT_TRACE` 未设 ⇒ 一行不打）、有界（≤60 行，`Interlocked`）、
  调用点都是"算完读一眼再 `return` 同一个值"（`return runBaseline;` / `return runHeight;` 有断言钉住）。

**四道闸门（原始读数）**
```
① --check（不经管道取 rc）：rc=0
   [断言] `throw` 条数 上游 0 == 生成物 0（只读插桩，未改行为）
   [断言] 上游 2015 行 → 生成物 2130 行（+115 行，全部是插桩与注释）
② 幂等：再跑一次 ⇒「内容已是最新（未重写）」；生成物 sha 不变 ✅
③ 接线求值（-getItem:Compile，不读 XML）：上游 SimpleTextLine.cs 条数 = 0（要求 0）；生成物 = 1（要求 1）✅
④ 编到 /tmp：**0 个警告 0 个错误**
   ⇒ /tmp/t1c/pcbuild/bin/Debug/PresentationCore.dll sha256 = 72ce9f22b711efceeb27e4789e121050f015141923e5eb26bbcdae54444c4686
```
**权威 PC 未重建**：`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` 仍是 `f31822ce4a3e510d…` ✅

**跑应用的命令**（等主控 slot；不要重建权威 PC）：
```
bash build/MilBridge/tools/t1c-census.sh /tmp/t1c-lh default \
     WPF_LINUX_LINEHEIGHT_TRACE=1 WPF_LINUX_GLYPH_CENSUS=1 \
     PC_OVERRIDE=/tmp/t1c/pcbuild/bin/Debug/PresentationCore.dll
grep -a "LINEHEIGHT" /tmp/t1c-lh/app.log | head -40
```
**注意**（家族教训）：本应用器的 csproj 接线**只在由它重放时才活得下来**（波的第 1 步会重写 csproj）；
下一波之后若 `-getItem:Compile` 里又出现上游那条，就说明接线被波冲掉了 ⇒ **重跑本应用器**。

### 15.5 顺带：一条我自己踩到的读数陷阱（记进手册）

第一次测「应用器的 `--check` 退出码」时我写成 `python3 $A --check | tail -4; echo rc=$?` ⇒ `rc` 是 **`tail` 的**，
当场把"锚点缺失 ⇒ 应 exit 1"读成了 `rc=0`。这正是本项目记过的那条（`RC=$?` 写在管道后恒 0）。
**已按纪律复测**：不经管道取 `rc=0`（当前已就位状态）✅ —— 记一笔，免得后人复现同一个坑。

---

## 16. 插桩实跑（主控 slot）：**归因表落格 —— (1)(2)(3) 全排除，(4) 在 SimpleTextLine 这条路上被否证**

### 16.1 环境与产物（原始行）

```
uptime: 19:28 up 2 days, load 0.88/1.68/3.09 ; free -m: total 7923 used 3530 free 1149 available 3140
跑前：应用实例数 = 0；:96 down（自起）/:98 ALIVE /:99 ALIVE
WPTD_ARTIFACTS bridge_sha=bc9754b44e5ccf8b bridge_bytes=4929728 pc_sha=4be3422cf5aeccec pf_sha=24a1260262483979 shim_sha=4c023937421db45f
ARTIFACT PresentationCore.dll = 4be3422cf5aeccec85bc69d75b886660b9dadf4b11fe188fba2cc4e5ce3310e3（插桩件，PC_OVERRIDE）
[自证] APP_PID=1402877 的 cmdline 含 WpfTextDemo.dll ✓    APP_EXIT rc=143
CENSUS_ORPHANS before=0 after=0      装置退出码 0（自起 Xvfb=1404161，已按 PID 收掉）
T1C_CENSUS_SUMMARY frame=3 runs=131 handles=131 glyphs=1276 id0=0 nonlatin=322 maxid=63151 allnotdefruns=0 distinctpids=4
编译：0 错 0 警（编到 /tmp；**权威 PC f31822ce… 未重建**）
```

### 16.2 原始 `LINEHEIGHT` 行（关键几类；共 60 行上限内：run 28 / line 64 / **draw 40**）

**run 级（度量返回值）**
```
[LINEHEIGHT] run.Height   fam="DejaVu Sans" em=26.0000 ppd=1.0417 mode=Ideal ret=30.2656
[LINEHEIGHT] run.Baseline fam="DejaVu Sans" em=26.0000 ppd=1.0417 mode=Ideal ret=24.1338
[LINEHEIGHT] run.Height   fam="DejaVu Sans" em=11.0000 ppd=1.0417 mode=Ideal ret=12.8047
[LINEHEIGHT] run.Baseline fam="DejaVu Sans" em=11.0000 ppd=1.0417 mode=Ideal ret=10.2104
```
**line 级（`_height`/`_baselineOffset`）**
```
[LINEHEIGHT] line realAscent=24.1338 realDescent=6.1318 realHeight=30.2656 _height=30.2667 _baselineOffset=24.1333 ppd=1.0417 mode=Ideal
[LINEHEIGHT] line realAscent=10.2104 realDescent=2.5942 realHeight=12.8047 _height=12.8033 _baselineOffset=10.2100 ppd=1.0417 mode=Ideal
[LINEHEIGHT] line realAscent=0.0000 realDescent=0.0000 realHeight=0.0000 _height=13.9700 _baselineOffset=11.1400 ppd=1.0417 mode=Ideal   ← 空行分支（Ghost/EOT），兜底值也是对的
```
**draw 级（宿主传进来的行 origin）——本轮关键**
```
[LINEHEIGHT] draw cpFirst=0   origin=(0.0000,0.0000)   _height=30.2667 _baselineOffset=24.1333 runs=2
[LINEHEIGHT] draw cpFirst=53  origin=(0.0000,13.9688)  _height=13.9700 _baselineOffset=11.1400 runs=1
[LINEHEIGHT] draw cpFirst=14  origin=(0.0000,15.1328)  _height=15.1333 _baselineOffset=12.0667 runs=1
[LINEHEIGHT] draw cpFirst=61  origin=(0.0000,27.9375)  _height=13.9700 _baselineOffset=11.1400 runs=1
[LINEHEIGHT] draw cpFirst=103 origin=(0.0000,48.8906)  _height=16.2967 _baselineOffset=12.9967 runs=1
[LINEHEIGHT] draw cpFirst=246 origin=(0.0000,97.7812)  _height=16.2967 _baselineOffset=12.9967 runs=1
```

### 16.3 归因表落格（判据见 §15.3）

| 类 | 判据 | 读数 | 结论 |
|---|---|---|---|
| **(1) emSize 太小** | `run.*` 的 `em` 偏小 | `em=11.0000 / 26.0000`（= XAML 字号） | ❌ **排除** |
| **(2) ppd 异常** | `ppd` 不为 ~1 / 与窗口不匹配 | `ppd=1.0417`（=25/24，与 938px/900DIP 一致） | ❌ **排除** |
| **(3) 度量比例塌了** | `run.Height` ≈0.07–1 | `em11→12.8047 = 11×1.164062`、`em26→30.2656 = 26×1.164062`；`Baseline = em×0.928223` **逐位精确** | ❌ **排除**（provider 度量与 §14.2 的字体真值**完全一致**） |
| **(4) 行偏移没带上** | `draw origin` 的 `y` 每行相同 | `origin.x` 恒 0 ✓；但 **`origin.y` 逐行递增**：`0 → 13.9688 → 27.9375 → 48.8906 → 97.7812`，且 `y / 行高 = 1.000 / 2.000 / 3.000 / 6.000`（与逐行 ×16.2969 也整倍） | ❌ **在 SimpleTextLine 这条路上被否证** |
| **(5) 都正常仍摞印** | 四类都正常 | 见 §16.4 | ✅ **剩下的空间：不在 PC 的 SimpleTextLine 路径** |

### 16.4 现象复核（读图）：**摞印只出现在"会折行的段落"**

我读了本轮截图（`/tmp/t1c-lh2/shot-1.png`，938×938）：
* **单行块全部正常**：标题、③ 三档对齐、④ 位图标签、⑥ ListBox 各条、⑦ 命中条 —— 位置与文字都对；
* **①（多行折行 · 中英混排）与 ②（TextTrimming 省略号）两块的正文有明显叠字**（同一框里多行挤在近似位置、并混入别处的字串）；
* **好消息**：**④ 的 96×96 位图现在真的画出来了**（四象限红/绿/蓝/黄 + 白框）⇒ **D-d 的 A 方案在部署件上生效**（T3 的验收我这条腿观察一致）；
* CJK 全是真汉字（`id0=0 / nonlatin=322`）✓。

⇒ ① ② 正是**会折行**的两块，也正是**唯一会落到 `HbTextFallback`（我们的 shim）**的那条路（T1b 的 LINEDIAG：`TryFormatLine` 只接手极少数段落；我此处亦见 131 个 run 里绝大多数是 `runs=1` 的 SimpleTextLine 单行绘制）。
⇒ **摞印不在 PC 的 `SimpleTextLine` 路径上**（本轮已证：行高正确 + 行 origin 逐行递增）；**它在"我们接手的多行段落"那条路上**（shim 的 `HbTextLine` 行定位 / 或该段的绘制变换）。

### 16.5 我自己的仪器缺陷（如实登记 + 已修）

第一次跑（插桩件 `72ce9f22…`）**`draw origin` 一行都没打**：四个调用点共用一个 60 行预算，而**测量期先跑**把预算吃光（`run 14 / line 33 / draw 0`）。
**已修**：① draw 拿**独立预算** `MaxDrawLines=40`（不会被饿死）；② draw 行加 `cpFirst`（按行定位）。
第二次跑（插桩件 `4be3422c…`）⇒ `run 28 / line 64 / draw 40` ✓。
**教训**：多站点共享一个有界预算 = "最晚发生的那个站点永远看不到" —— 记进手册（与"空=两种含义"同族）。

### 16.6 下一步（**不在我当前授权内，请主控派单**）

把同一套插桩挪到**我们接手的那条路**上，判据同样是"行 origin 有没有逐行递增"：
* `build/shims/PresentationCore.HbTextLine.cs`（T1d 的 R1 文件）——`HbTextLineFactory.FormatParagraph` 产出的每行 `Height/Baseline` 与**该行被画到哪里**（`HbTextLine.Draw` 收到的 origin / 或 `TryFormatLine` 返回 `first` 后宿主如何逐行取）；
* 或（若 shim 侧无 Draw 概念）在 `src/WpfGfx.Linux/**` 的渲染变换链上读"同一段的 3–5 行各自的设备 Y"。
**这两处都出我的边界**（shim 是 T1d 的 v7 文件；`src/**` 属桥/渲染车道）⇒ 我只报定位、不动手，等你派。

---

## 17. RTL abort(134) 定位 + 宽松兜底（T1c，2026-09-11 深夜）

### 17.1 现场清单（`grep -an` 真值）：**两处 `FullTextLine` 站点都已接线**，主控那条"这个站点没接"的前提**不成立**

```
build/PresentationCore.Linux/TextFormatterImp.Linux.cs
  :266   textLine = new TextMetrics.FullTextLine(        ← 站点1（上游 :241）
          ↑ 紧邻其上的 :251-262 就是 **已接的** `HbTextFallback.TryFormatLine(...)`
  :347   TextMetrics.FullTextLine line = new ...(        ← 站点2（上游 :309）
          ↑ :333-343 就是 **已接的** `HbTextFallback.TryMinMaxParagraphWidth(...)`
  :537/:576  AcquireContext → new TextFormatterContext()  ← LS 引擎本体（不适用"接线"）
上游 TextFormatterImp.cs：FullTextLine 仅 :241 / :309 两处；`LoCreateContext` **在 TextFormatterImp 里 0 处**（在 `TextFormatterContext` 里调用）
```
⇒ **没有"漏接的站点"**。真凶是：**shim 的托管路径对 RTL 输入 `bail`** ⇒ 两个 `if (textLine == null)` 都落空 ⇒ 走到 `FullTextLine`
⇒ `LoCreateContext`（Linux 上不存在）⇒ **abort(134)**。
**bail 的最可能出处**（读代码）：`build/shims/PresentationCore.HbTextLine.cs:3298`
`Bail(ref BailRunType, "run 类型 " + run.GetType().Name + " 不支持")` —— `TryCollect` 只接受
`TextCharacters` 与 `TextEndOfLine`，而 **RTL/bidi 段落会带别的 run 类型**（分段/隐藏等）⇒ 一 bail 就交回 LS。
（**未跑应用，故 `lastBail` 原文待 T3 那一跑给出**；我按"先落格再结论"办，这只是最可能的一条。）

### 17.2 我方改动（我的车道）：**宽松托管兜底**（不碰 T1d 的 shim 文件）

`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` 新增 3 处 EDIT：
1. **新类 `WpfLinuxLenientTextFallback`**（生成进 `TextFormatterImp.Linux.cs`，与 shim 同程序集）：
   * `CollectLenient`：**跳过**非 `TextCharacters`/`TextEndOfLine` 的 run（`++skipped` 计数 + 记住类型名），
     **不再 bail**（这就是把 RTL 从"交回 LS ⇒ abort"里救出来的关键放宽）；
   * `ResolveFont`：与 shim 同源（`Typeface → GlyphTypeface.FontUri → 本地文件存在`）；
   * 调 `HbTextLineFactory.FormatParagraph(...)`（**只用 shim 已有的 API，不改 shim**；失败路径**照旧返回 null**）；
   * 读数 `Diagnostics`：`relaxedCalls / relaxedHandled / relaxedFailed / relaxedSkippedRuns / lastSkip / lastFail`；
     诊断行 `[TEXTLINE_RELAXED] …` 用**与 shim 同源的** `WPF_LINUX_TEXTLINE_DIAG` 门控（缺省关）。
2. **站点1**：在 LS 之前插入宽松兜底调用 ⇒ 三层：①`SimpleTextLine` ②shim ③**宽松兜底** ⇒ 才轮到 LS。
3. **站点2**（MinMax）：同样插入宽松版（与 shim 同构：宽=∞ 取 Max、宽=0 取 Min）。
**如实登记的方向限制**：`FormatParagraph` 目前没有 bidi/RTL 参数 ⇒ **本兜底保证不崩，但 RTL 的视觉顺序可能仍是 LTR**；
真正的 RTL 排版（bidi 级别）属排版车道（需要在工厂里支持），本类**不假装支持**。

### 17.3 闸门（原始读数；**权威 PC 未重建**）

```
① 应用器 --check（rc **不经管道**取）：rc=0
   [断言] 托管调用点 TryFormatLine=1、TryMinMaxParagraphWidth=1；两处原 LS 回退**都还在**
   [断言] LS 站点数 = 2（两处都被 ①shim ②宽松兜底 包住）；宽松兜底调用各 1 处
   [断言] `throw` 条数 上游 4 == 生成物 4；大括号平衡 {=101 }=101；上游 776 行 → 生成物 1029 行（+253）
② 幂等：再跑一次 ⇒「内容已是最新」；生成物 sha 不变 ✅
③ 闸门 A（PC 编到 /tmp）：**0 个警告 0 个错误** ⇒ /tmp/t1c/pcbuild/bin/Debug/PresentationCore.dll = 893286a4adf8fd5a319d58021801c5a8820735c58969b437dce29cae050bad4e
④ 闸门 B（第二种编译形态 = CoverageProbe 直构分支）：**0 个警告 0 个错误** ✅
⑤ 权威 PC：build/PresentationCore.Linux/bin/Debug/PresentationCore.dll 仍 f31822ce4a3e510d… ✅（未动）
```

### 17.4 牙齿（**可复现**，两次都按纪律**不经管道**取 rc）

变体测试（把应用器连同**改坏的上游副本**放到 `/tmp/t1c/teeth2` 的**同构路径**下再跑）：

| 变体 | 破坏方式 | 结果 |
|---|---|---|
| A | 删掉"站点1 的 LS 回退"锚点（模拟上游改过/站点被挪走） | `--check` **rc=1**，输出 `[锚点] 站点1 …：上游出现 0 次（要求 1）` + `[失败] 锚点缺失或重复` ✅ |
| B | **新增第三处** `new TextMetrics.FullTextLine(`（模拟"又出现一条会 abort 的路"） | `--check` **rc=1**，输出 `[失败] 生成物里 new TextMetrics.FullTextLine( 出现 3 次（要求 2）—— 多出来那一处就是没接兜底的 LS 站点` ✅ |

**⚠️ 这个牙齿测试我自己先踩了一次"假绿"（如实登记）**：第一版把应用器放在 `/tmp/t1c/teeth/tools/`，
而应用器用 `HERE/../../..` 推 `ROOT` ⇒ 它去 `/tmp/upstream/...` 找上游 ⇒ **两次都 rc=1，但理由是"找不到上游"而不是"锚点不符"**
（"验证器走了另一条分支"那一族）。改成同构路径 `/tmp/t1c/teeth2/src/WpfGfx.Linux.Native/tools/` 后才真正打到锚点检查与站点计数两条判据。

### 17.5 未做 / 待主控

* **没跑应用**（按你要求）：`run-wpfprobe.sh 90 --only=text-rtl` 的复现与"`INCONCLUSIVE`→`OK`"由你或 T3 放行后跑；
  跑的时候建议同时带 `WPF_LINUX_TEXTLINE_DIAG=1` —— 那样能同时拿到 ①shim 的 `lastBail`（判"到底哪种 run 类型把它顶回去"）
  与 ②我的 `[TEXTLINE_RELAXED]`（判"宽松兜底有没有接手"），一次跑清两件事。
* **没有跑 `run.sh tline`**：本改动**只在 PC 侧**（生成物 + 应用器），而该 harness 吃的是 **shim 源 + 真机 oracle**，
  与我的改动无交集；且你交代"重编译尽量少"（T2b/M7b 在跑）。⇒ 那一组读数请由放行方在波前/波后复跑确认。
* **RTL 的视觉正确性**（顺序/镜像）不在本兜底范围内（见 17.2 的如实登记）。

---

## 18. RTL 根因修复（T3 波 6 读数把我自己那段代码钉死了）

### 18.1 根因（T3 原始读数 + 我的代码）

```
[TEXTLINE_DIAG] R1 面计划：runs=1 {[0,29) …/DejaVuSans.ttf#0 …}      ← 段落**确实有 29 个字符**
[TEXTLINE_DIAG] LS_FALLBACK 交回 LS（前3条无条件）：空段落              ← 而我们这边拼出**空文本**
栈：LoCreateContext ← FullTextLine ← TextFormatterImp.Linux.cs:483 ← FormatLine:353 ← TextBlock.MeasureOverride:1271
```
我 §17 的宽松收集里写了这一句（旧版）：
```csharp
TextCharacters tc = run as TextCharacters;
if (tc != null) { … sb.Append(Extract(tc)); continue; }     // ← 只认 TextCharacters
… ++skipped; …                                               // ← 其它类型**整段丢掉**
if (text.Length == 0) { s_lastFail = "空段落"; return false; } // ← 于是"空"⇒ **交回 LS** ⇒ abort
```
**RTL/bidi 段落的 run 不是 `TextCharacters`** ⇒ 字符被整段丢掉 ⇒ 拼出空文本 ⇒ `return false` ⇒ `FullTextLine` ⇒ LS ⇒ **abort(134)**。
⇒ **是我的代码把 RTL 顶回 LS 的**（T3 的定位正确）。

### 18.2 修法（两条，都有依据）

| # | 改动 | 依据 |
|---|---|---|
| **①** | **从"任意 `TextRun`"取字符**：`CharacterBufferReference` 与 `Length` 是 **`TextRun` 基类**就有的（不必是 `TextCharacters`）⇒ 新 `ExtractRun(TextRun)`；非 `TextCharacters` 的 run **仍计数**（`skipped` + 类型 + **区间** `lastSkippedRange=[start,end) 类型`），但**字符进 sb 不再丢** | `R1 面计划` 有 29 字符、我们拼出 0 ⇒ 两者矛盾 = bug；基类 API 证明字符本来可读 |
| **②** | **"空文本"绝不交回 LS**：真的一个字都取不到时，用**一个空格顶一行"空白行"**（画不出东西），`relaxedBlankParagraphs` 计数 + `DiagBeforeReturn` 诊断；minmax 版则诚实返回 `min=max=0` | 主控原则："LS 在 Linux 上不存在，任何'交回 LS'都等于 abort"；空白行 + 计数 + 诊断是**诚实**表达（不假装有内容） |
| **③** | **进了 `return false` 之前先诊断**（`DiagBeforeReturn`）：直接写 `**即将交回 LS**（Linux 上等于 abort）原因：…` | 波 6 那次诊断"走的是被 abort 截断的那条路"⇒ 一行都没出来 |
| **④** | **顺手堵同类漏洞**：**空段落只有 EOL run** ⇒ 旧代码在 EOL 处 `break` 前没抓 `Properties` ⇒ `props==null` ⇒ 连空白行都产不出 ⇒ **又回 LS**。"空"有两种含义（没有正文 vs 连 run 都没有），现在两者都兜住 | 同族缺陷（`空=两种含义`）在同一个函数里又出现一次，一起修 |

**如实登记的剩余边界**：`relaxedBlankParagraphs`/空白行是**不画内容**的兜底；RTL 的**视觉顺序**仍可能是 LTR（工厂无 bidi 参数）；
若连 properties 都取不到（理论上：一个 run 都没有），仍会 `return false` ⇒ LS —— 这条现在**必有 `DiagBeforeReturn` 行**可查（不再静默）。

### 18.3 闸门（原始读数；权威 PC 未重建）

```
--check（rc **不经管道**）：rc=0
 [断言] 托管调用点 TryFormatLine=1、TryMinMaxParagraphWidth=1；两处原 LS 回退都还在
 [断言] **负断言：空段落/空文本的旧短路写法不存在** ✅
 [断言] LS 站点数 = 2（两处都被 ①shim ②宽松兜底 包住）；宽松兜底调用各 1 处
 [断言] throw 4==4；大括号 {=114 }=114；上游 776 行 → 生成物 1111 行（+335）
幂等：再跑「内容已是最新」（生成物 sha 不变）
闸门A PC 编到 /tmp：**0 错 0 警** ⇒ PresentationCore.dll = 8692ccd0ff4f52f2dc87…（**这是 RTL 修复件**）
闸门B CoverageProbe（第二种编译形态）：**0 错 0 警** ✅
生成物 TextFormatterImp.Linux.cs = 569fefc718340086f202…；应用器 = f5966d67160d30285482…
权威 PC build/PresentationCore.Linux/bin/Debug/PresentationCore.dll 未被我改动
```

### 18.4 牙齿（**能红的**；rc 不经管道取）

| 变体 | 破坏方式 | 结果 |
|---|---|---|
| 空文本分支改回 `s_lastFail = "空段落"; return false;`（**就是波 6 的根因写法**） | 改应用器模板 ⇒ 生成物里出现被禁用写法 | `--check` **rc=1**，输出 `[失败] 生成物里出现**被禁用**的写法：空段落直接 return false（会把 RTL 交回 LS ⇒ abort） —— 那正是波 6 abort 的根因` ✅ |
| （§17.4 的旧两条仍有效）删站点锚点 / 加第三处 `FullTextLine` | — | 各自 `rc=1`，理由分别是"锚点 0 次"与"LS 站点数 3≠2" ✅ |

### 18.5 请放行的一跑（我不跑应用）

```
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh 90 --only=text-rtl --app-env=WPF_LINUX_TEXTLINE_DIAG=1
```
**必须用含本修复的 PC**：权威件若仍是波 6 那一版（`17d9910c…`，不含 §17/§18），请先用
`PC_OVERRIDE=/tmp/t1c/pcbuild/bin/Debug/PresentationCore.dll`（= `8692ccd0ff4f52f2dc87…`，**RTL 修复件**）跑一次性验证；
或起波时重放本应用器后重建权威 PC 再跑（推荐）。
**期望**：`exit=143`（或正常退出），且 stderr 上出现 `[TEXTLINE_RELAXED]`；若仍有 `**即将交回 LS**` 行，把那行原文发我 —— 那就是唯一剩下的 LS 路径，我按它继续收。

---

## 19. OpacityMask 定位（只读；**结论与派单前提相反：PC 发了，MIL 收了但没用**）

### 19.1 两条**互不相同**的发射路径（这是本次定位的关键）

| 路径 | 谁用 | 发射链（file:line） | 载体 | DRAW_CENSUS 能不能看见 |
|---|---|---|---|---|
| **A. UIElement/`Visual.OpacityMask`** | **探针的 3 个 `Border`**（`samples/WpfFeatureProbe/FeatureBlocks.cs:212-227`） | `Visual.cs:1250 UpdateOpacityMask(...)` → `:1340-1363` → **`DUCE.CompositionNode.SetAlphaMask`**（编码体 `Common/Graphics/exports.cs:1771-1790`，写 `MILCMD.MilCmdVisualSetAlphaMask`＝**0x23**） | **通道命令**（视觉属性） | ❌ **看不见**（census 只走 RenderData 指令） |
| **B. `DrawingGroup.OpacityMask`** | 探针**没有**用 | `DrawingGroup.cs:210 ctx.PushOpacityMask(...)` → `RenderDataDrawingContext.cs:961-990`（写 `MILCMD.MilPushOpacityMask`） | **RenderData 指令** | ✅ 看得见（T2b 单测走的正是这条） |

**装置边界（T2b 的 census 自己写着）**：`src/WpfGfx.Linux/Rendering/DrawInstructionCensus.cs:311-313`
`if (e.Value.Resource is not MilRenderDataResource rd …) continue;` → `foreach (MilDrawInstruction ins in rd.RenderData.Instructions)`
⇒ **它数的只有 RenderData 里的指令**。T2b 的"解码器无条件 Add ⇒ `PushOpacityMask` 计数 = 0 ⇔ PC 没发"这半句，**只对路径 B 成立**；
探针用的是路径 A ⇒ **census 永远数不到**。

### 19.2 逐跳落点（两侧对照，含"我方有没有补丁碰过"）

| 跳 | 位置 | 状态 |
|---|---|---|
| ① 属性置脏 | 上游 `Visual.cs:3719-3745`（`VisualOpacityMask` setter） | 未打补丁 ✓ |
| ② 逐视觉更新时派发 | 上游 `Visual.cs:1250 UpdateOpacityMask(channel, handle, flags, isOnChannel)` | 未打补丁 ✓ |
| ③ 置 `IsOpacityMaskDirty` 就发 | 上游 `Visual.cs:1340-1363`：`SetAlphaMask(handle, ((DUCE.IResource)opacityMask).AddRefOnChannel(channel), channel)`；`null` 时发 `ResourceHandle.Null` | 未打补丁 ✓ |
| ④ 编码 | 上游 `Common/Graphics/exports.cs:1771-1790`（`command.Type = MilCmdVisualSetAlphaMask; Handle=…; hAlphaMask=…; channel.SendCommand(...)`） | **PC 的 csproj 编入了**：`Common/Graphics/{exports.cs, wgx_core_types.cs, Generated/wgx_commands.cs}`（csproj:45-52）✓ |
| ⑤ 我方 MIL 解码 | `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs:215-219`：`case MilCmd.MilCmdVisualSetAlphaMask → v.Visual.AlphaMask = …HAlphaMask` ✓ 布局 `MilCommandLayout.cs:71 => 12` 字节、`MilCommandStructs.cs:280 [FieldOffset(8)] HAlphaMask` ✓ | **收了** ✓ |
| ⑥ 存起来 | `src/WpfGfx.Linux/Resources/MilVisualNode.cs:14,46`（`AlphaMask` 字段） | ✓ |
| ⑦ **谁来用它** | **`grep -rn "AlphaMask" src/`（排除 Commands/Contracts/Resources）⇒ 0 命中** | ❌ **没有读者 ⇒ 静默忽略** |

⇒ **判定**：**PC 侧按代码是发的**（①→④ 全在，且没被任何补丁改动；`grep` 我方树里 `OpacityMask` 相关字样 = 0）；
**真正丢的一跳是 ⑦：MIL 收了 `AlphaMask` 却从不消费它** ⇒ 遮罩对画面无任何影响
⇒ 与 T3 的像素读数（`alpha=0` 遮罩下 `#8B5CF6` 仍 **29946 px** 完整可见）**完全一致**。
**⇒ 派单前提"PC 侧被丢掉了"由代码否证**；修法落点在 **`src/WpfGfx.Linux/Rendering/**`（不是我的车道）**。

### 19.3 验收判据必须改（否则**修好了也是假红**）

主控给的判据是"`census` 里出现 `PushOpacityMask×N`" —— 对探针这三个 `Border`（路径 A）**这条判据永远不可能满足**（§19.1 的装置边界）。
建议三选一/并用：
1. **（首选）以像素为准**（你已有）：`alpha=0` 遮罩 ⇒ `#8B5CF6` **消失**；`alpha=255` ⇒ `#22C55E` **出现**；渐变遮罩 ⇒ `#38BDF8` 只作读图证据。这条判据与"路径 A"语义一致，且**现在就是红的**（= 缺陷仍在）。
2. **补一条通道侧计数**（M7b/T2b 车道）：在 `MilCommandDispatcher` 的 `MilCmdVisualSetAlphaMask` 分支计数（并记 mask 句柄是否为 `Null`）⇒ 一跑就能把"PC 没发"与"MIL 收了不用"分开；我这边已用代码把后者钉死，但**装置化**更稳。
3. 若确实想看 `PushOpacityMask` 的 census 读数：给探针**加一个 `DrawingGroup` 版本的遮罩元素**（路径 B）——那才会进 RenderData、才会被 census 数到（`SkiaRenderBackend.cs:458` 已支持该指令，T2b 单测已证）。

### 19.4 候选修法（**都不在我车道 ⇒ 报主控派单**）

| 方案 | 落点 | 说明 / 代价 |
|---|---|---|
| **①（正解，推荐）** | `src/WpfGfx.Linux/Rendering/**`（消费 `MilVisualNode.AlphaMask`） | 语义与上游一致：遮罩作用于**该视觉的整个子树**（含子元素）。渲染器已有能力：RenderData 版遮罩走后端 `case MilDrawCommand.MilPushOpacityMask:`（`SkiaRenderBackend.cs:458`），T2b 单测证明"纯色遮罩 ⇒ SaveLayer 整层 alpha"可行 ⇒ 把同一套用到"视觉子树"这一层即可 |
| ② 把 PC 改成往 RenderData 里推 | `patch-presentationcore-*.py`（我的车道） | ⚠️ **语义不同**：`dc.PushOpacityMask` 只遮**该视觉自己绘制的内容**，**不遮子元素**；而 `UIElement.OpacityMask` 上游是**子树**级 ⇒ 会把"遮罩子元素"的语义改坏。**不建议**（除非只当临时止血并**明确登记语义差异**） |
| ③ 让 MIL 端把 `AlphaMask` 翻译成一个 RenderData 推入 | `src/WpfGfx.Linux/**` | 与①同侧，但"在 MIL 里合成 RenderData"更绕；不如①直接 |

### 19.5 我没做的事（守边界）

* **没跑应用**（应用跑由你/T3 放行）；**没编译**（波 7 在跑，按你要求等它完）；**没动 `src/**`**（要动先报你）。
* 本轮的产出**只有定位与判据建议**（外加这一节报告）：`build/MilBridge/T1c-report.md` §19。
* **无 PC 侧改动可做**：`grep` 我方树的 `OpacityMask`/`SetAlphaMask`/`CompositionNode` = **0 命中** ⇒ 这条链一个补丁都没碰过，
  PC 侧"发射"这半段**没有可修的代码**（除非你要走 §19.4 ②那条有语义代价的路）。

---

## 20. RTL「视觉顺序对不对」判定（只读；先写判据，再给结论）

### 20.1 判据（**先写死**，然后只往上贴读数）

| 结论 | 看到什么才算 |
|---|---|
| **(甲) 顺序已正确** | ① 探针 RTL 串里的**拉丁子串**（`"RTL"`）交给 MIL 的 glyph 序列是**逻辑序**（'R','T','L' 的字形按顺序、advance 同向累加），且 ② 阿拉伯/希伯来子串的字形是**视觉序**（末字符在左、首字符在右），且 ③ 整行的 x 起点/对齐按 `FlowDirection=RightToLeft` 镜像 |
| **(乙) 顺序错（静默画错）** | 出现任一条：拉丁子串字形**反序**（'L','T','R'）；或方向变化处**没有重排**（UBA 未施加）；或整行仍按 LTR 起点/对齐摆放 |
| **(丙) 判不了** | 拿不到上面任一读数（缺 glyph 序列 / 缺图 / 缺真机对照）——**必须写清缺哪一条** |

### 20.2 代码证据（**实测部分**：全部来自只读 `grep`/读文件，非推断）

| 事实 | 出处 |
|---|---|
| 我们的整形**不传方向**，用 HarfBuzz **自动猜** | `build/shims/PresentationCore.HbTextLine.cs:205 hb_buffer_guess_segment_properties(buf)` → `:208 hb_shape(...)` |
| 整形结果**按输出顺序**逐项消费（无任何重排/镜像） | 同文件 `:222-238`（`r.Glyphs[i]=gi.Codepoint`、`r.AdvancesPx[i]=gp.XAdvance*scale`），且全文 **`RightToLeft/reverse/visual/mirror` 命中 = 0** |
| 工厂 API **没有方向参数** | `HbTextLineFactory.FormatParagraph(text, fontPath, emSize, width, glyphTypeface, ppd, runProperties, alwaysCollapsible, hasModifierScope, lineHeight, out consumed, plan, segmentFaces)`（`PresentationCore.HbTextLine.cs:2753-2766`） |
| 上游**有** bidi 服务，且 `TextStore` 会算**每段 bidi level** | `MS/internal/TextFormatting/Bidi.cs`（`class Bidi`）；`TextStore.cs:166-322`（`bidiLevels` / `lastBidiLevel` / `BidiAnalyze`）——上游把 level 交给 **LineServices** 去重排 |
| 我们的路径**把 level 丢掉了** | 我们的收集只把各 run 的**字符**按 `GetTextRun` 顺序拼成一个串（§17/§18 的 `CollectLenient`/shim `TryCollect`），**从不读 level、也不重排** |
| ICU **已经在用**（可用作 bidi 实现） | `run.sh icu` 驱动 shim 的断行（`HbBreakEngine`）⇒ 同一份 ICU 里 `ubidi_*` 也在手边 |

### 20.3 结论

* **(乙) —— 对"混合方向"文本成立，且这是**代码级确定**的**：探针那段是
  `"مرحبا بالعالم — RTL שלום עולם"`（阿拉伯 + 拉丁 `"RTL"` + 希伯来）。
  我们把**整段**丢进**一个** buffer，方向由 `guess_segment_properties` **猜成 RTL**（首强字符是阿拉伯）
  ⇒ ① 拉丁子串 `"RTL"` 也被按 **RTL** 整形 ⇒ 其字形在屏上**是反的**；② 方向变化处**没有 UBA 重排**
  （`" — RTL "` 该落在阿拉伯左侧，现在不会）；③ 整行仍按 **LTR** 起点/对齐摆放（`FlowDirection` 从未参与）。
  ⇒ **这就是静默画错**（不报错、不 abort，用户看到的是错的顺序）。
* **(丙) —— 对"纯 RTL 单段"（例如只有阿拉伯）我判不了最后一步**，缺**一条读数**（见 20.4）：
  按 HarfBuzz 文档语义，RTL buffer 的输出**已是视觉序** ⇒ **字形顺序很可能是对的**，
  但**行的 x 起点/对齐**仍是 LTR ⇒ 与 Windows 不一致。**这一段是推断（依据 HB 文档语义），不是实测。**
* **明确标注**：20.2 全部是**实测（读代码）**；20.3 中"拉丁子串必反"是**代码级确定**；
  "纯 RTL 字形顺序可能对"是**推断**，等 20.4 的读数落定。

### 20.4 把 (丙) 变 (甲)/(乙) 只需要一条读数（**请给 slot**）

一次运行即可（不需要新写仪器，用现成的）：
```
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh 90 --only=text-rtl \
     --app-env=WPF_LINUX_GLYPH_CENSUS=1 --app-env=WPF_LINUX_TEXTLINE_DIAG=1
```
**要读的三样**（我已把判据写死在 §20.1，读数一到就能落格）：
1. **数据级（最硬）**：RTL 行那条 `[GLYPH_CENSUS] run#… first16=…` —— 找 `"RTL"` 三个拉丁字母对应的字形 id：
   若是 `R,T,L` 的顺序 ⇒ 拉丁子串**逻辑序** ✓；若是 `L,T,R`（反序）⇒ **(乙) 实测坐实**。
   （拉丁字形 id 互不相同 ⇒ 这条可判；探针串里的 `"RTL"` 就是天然的判别子串。）
2. **像素级（补充）**：`--only=text-rtl` 的截图 —— **读图**看那块 RTL 行的拉丁部分是否可正常辨读（`RTL` vs `LTR`），
   以及整行是否贴左（LTR 对齐）而 Windows 上应贴右。
3. **shim 侧**：`[TEXTLINE_DIAG]` 里的 `R1 面计划` 行 —— 看它给整段规划的**面/段**是否只有 1 段（无方向分段 ⇒ 佐证未做 bidi）。

### 20.5 若判 (乙)：修法方向 + 工作量 + 需要谁的输入（**不顺手修**）

| 项 | 内容 |
|---|---|
| **shim（T1d 车道）** | 用**已经在用的 ICU** 做 UBA：`ubidi_setPara` → `ubidi_getLevels` → 按 level 切**方向段** → 每段 `hb_buffer_set_direction(RTL/LTR)` **显式**整形（不再靠猜）→ 用 `ubidi_reorderVisual`/level 序排段、RTL 段从右往左摆（含 advance 方向与镜像） |
| **PC 侧（我的车道）** | 把 `paragraphProperties.FlowDirection` + 解析后的 `TextAlignment` **传进兜底调用**（现在完全没传）；工厂 API 需加"方向/对齐"参数（shim 改）⇒ 我这边是**接线**（~50 行 applier 改动） |
| **渲染侧** | 若行内镜像由布局层做（`FlowDirection` 的视觉镜像），需确认与 shim 的摆法**不要二次镜像**（`src/WpfGfx.Linux/**`，非我车道） |
| **工作量** | **M–L（约 2–4 天级）**：ICU bidi ~150 行 + 逐方向段整形/摆位 ~150 行 + 接线 ~50 行 + 测试 |
| **需要谁的输入** | ① **真机对照**：现有 oracle（`layout-b34-compact.json`）**没有 RTL 用例** ⇒ "对了"只能靠 UBA 规则 + 读图判定 ⇒ **建议你决定是否要 T3/M7b 采一份 Windows RTL 行度量/位置 dump**；② shim 的车主（T1d）接 ICU bidi；③ 若涉及布局镜像，需要渲染/布局车道的确认 |

**我没做**：没跑应用（T3 独占 `:97`）、没编译、没动 shim/`src/**`；本轮只往报告追加 §20。

---

## 21. 输入链 v2：早退门之前的那一格 + 托管侧出队读数（T1c · 源码与报告，**未生成物/未重建/未跑**）

> 详细版在 `build/MilBridge/T1c-inputtrace-report.md`（v2）。本节只记**交接要点**。

### 21.1 交付物（sha256）

| 件 | sha256 |
|---|---|
| `src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py` **v2** | `4eac185d5ae049a8fca2a39d268b0cdb6272c11b4e29fd56f984570767fa1d34` |
| `src/WpfGfx.Linux.Native/tools/patch-windowsbase-msgflow.py`（**新**，WindowsBase 车道第一件） | `cf3c1d79312ccf34812a534749dcba1d302713af78768a50bdea1b0543817469` |
| 生成物（**重放后**应当是；现在磁盘上 `HwndSource.Linux.cs` 仍是 v1 `9408a440…`） | `HwndSource.Linux.cs` `385a6014…`；`HwndKeyboardInputProvider.Linux.cs` `f56e647e…`（不变）；`Dispatcher.Linux.cs`（新）`cbb971f5…` |
| 本文件（§21 追加后） | 不自我登记 sha（写进去就会变）；请以 `sha256sum build/MilBridge/T1c-report.md` 现取为准 |
| `build/MilBridge/T1c-inputtrace-report.md`（v2 全文重写，含行号下移说明之后） | `ded4db2b947a02bf2fd1fde12e079442c47b9cf301acf2bc8f74e1c38f0d4daa`（其后又追加了"行号下移"注，以现取为准） |

**v2 三处改动**
0. **行号整体下移**：插桩类比 v1 多 ~22 行（新增 `PreprocessEarlyGate`），而它插在文件**最前面** ⇒ H1…H7 全部下移。
   **焦点门**由 v1 的 `HwndSource.Linux.cs:1906-1909` 变为 v2 的 **`:1933-1936`**（H0 就在它前面）。审阅请以 `T1c-inputtrace-report.md` §2 的 v2 行号为准，别拿 v1 行号找点位。
1. **H0**：`HwndSource.OnPreprocessMessage` 的**所有早退门之前**（生成物 `:1927`，上游 `HwndSource.cs:1778-1781` 焦点门之前）——
   `msg / hwnd / wParam(码点) / HasFocusWithin() / IsInExclusiveMenuMode / _eatCharMessages`，`HasFocusWithin()` **惰性**求值（关掉时零代价）。
2. 原 `:1984` 那条入口探针**改名**为 `入口(**过焦点门后**)` —— 它在 `switch` 里、过了焦点门，**回答不了**"消息到没到"。
3. **WindowsBase `Dispatcher.TranslateAndDispatchMessage`** 三格：`① 出队(msg.message/hwnd/wParam/lParam)` / `② RaiseThreadMessage 的 handled` / `③ 交给 DispatchMessageW`。
   - 开关：`WPF_LINUX_MSGFLOW_TRACE`（**与原生侧同名同义**：非空且非 `0`）**或** `WPF_LINUX_INPUT_TRACE`（PC 侧严格解析）；开哪路打在首行 `via=` + 原始读数。
     **一条命令同时开原生 `[MSGFLOW]` 与托管 `[MSGFLOW_TRACE]`**（前缀可分离）。
   - 输入消息**单独预算 150 行**（不被几千条 `WM_PAINT/WM_TIMER` 饿死）+ 每 200 条一行统计（**总量永远看得到**）+ 硬上限 200 行。

### 21.2 判据升级为**互斥四格**（`_eatCharMessages` **降级**）

| 格 | 读数 | 结论 |
|---|---|---|
| ① 上游丢 | 托管 `① 出队` 里**没有** `0x0102` | 不在 PC/托管逻辑里 → 原生侧（**现场证据偏向这格**：原生记录 2026-09-12 现场 `[msg]` 0 条 WM_KEYDOWN / 0 条 WM_CHAR） |
| ② 取不出来 | 原生 `push WM_CHAR 入队` 有、托管 `① 出队` 没有 | 队列里有、泵没取到（filter 不匹配 / 被嵌套 `PeekMessage(PM_NOREMOVE)` 拿走 / 进了别人的队列） |
| ③ 被预处理吃掉 | 托管 `①` 有 `0x102` 且 `② handled=True` | 被线程预处理 filter 处理掉；看 PC 侧 H0 有没有打（打 ⇒ 就是 `OnPreprocessMessage`；没打 ⇒ 别的注册者） |
| ④ 到了 `OnPreprocessMessage` | H0 打了 | ④a H0 有 / H3 无 ⇒ **焦点门挡回去**（v2 才能指认）；④b H3 有 ⇒ 进 char 分支，再看 `_eatCharMessages` 与 H4/H5/H6 谁置 true |

**`_eatCharMessages` 从头号嫌疑降为 ④b 的子格**：v1 的入口探针在焦点门之后，"没打印"有三种含义；且现场证据（0 条 KEYDOWN/CHAR）指向更上游。
**另一条被证伪的假设**：`TranslateMessage`（`win32_msg.c:570-576`）是**故意空实现**⇒ WM_CHAR 全由 X11 翻译层产生，"TranslateMessage 吞了"不成立。

### 21.3 主控清单里"提供方那三处没接上"——**与生成物不符**
`EDITS_HK` **3 条**编辑产生 **5 个**调用点，全在生成物里：`HwndKeyboardInputProvider.Linux.cs:204 / 243 / 279 / 284 / 289`。
⇒ 是**接了**的（复核：`grep -an "WpfLinuxInputTrace\." build/PresentationCore.Linux/HwndKeyboardInputProvider.Linux.cs`）。
"以生成物里的调用点为准，不以脚本里的 EDITS 表为准"这条纪律，这次恰好把**清单**证伪了。

### 21.4 给 M7b 的原生侧坐标
**已有**（`WPF_LINUX_MSGFLOW_TRACE` / `WPF_LINUX_KEY_DIAG`）：`push WM_CHAR 入队`(win32_msg.c:63-65)、`pop api=…`(:187-198)、
取消息者标注(:480/510/514)、`PeekMessageW(PM_NOREMOVE)` 两处告警(:551/:559)、X11 `XEV/KEY/DROP`(:191-197,:596,:610)。
**还缺**：① `GetMessageW`(:475) **返回路径**的读数（`pop` 打了、托管没收到 ⇒ 断点就在 `pop` 与 `return` 之间的 filter/wait）；
② `PM_NOREMOVE` **回插之后**的队首 id（会不会被反复弹到尾）；③ X11 `push()`(:475-487) 对 `WM_KEYDOWN/WM_SETFOCUS` 也打（否则"键没到进程"与"没产 char"分不开）。
纪律同我这边：**探针必须在所有早退门之前**，否则"没打印"有多种含义。

### 21.5 本轮的**未做/待办**（不假装绿）
1. **没生成物、没重建 PC/WindowsBase、没发桥、没跑应用**（按主控指令，统一重放）；`--check` 现在 rc=1（正确表示"未应用"）。
2. **没编译** ⇒ "两份生成物能编过"只有人工核对（作用域/形参/全限定名），没有编译器证据。
3. **探针装置 `tests/InputTraceProbe/` 的两臂断言未重跑**（v2 新增 H0 与 W1…W3 后需要一次）；离线自检目前是结构断言 16/16（PC）+ 14/14（WB）+ `--prove` 的"只插入"证明。
4. **假树预测**（只写 `/tmp`）给出了重放后的期待 sha 与行号；若重放后对不上 ⇒ 先查上游/应用器是否被改，再信读数。
5. **两个假绿陷阱**已写进应用器输出：`port-lib.py WindowsBase` 会整份重写 csproj（接线被抹掉**不报错**、只表现为"一行都不打"）；`--check` rc 必须**不经管道**取。

---

## 22. 输入链**第 2 批**（P1…P6）：只写源码与报告（**未生成物/未重建/未跑**）

> 详细版在 `build/MilBridge/T1c-inputtrace-report.md` 的「第 2 批」整节（§8.1-§8.8）。本节只记交接要点。

**第 1 批实测已改写判据**：`_eatCharMessages` **所有描点全 `False`**、三步都没置 handled、
最后 **`ProcessTextInputAction ⇒ handled=True`** 而样例 `changes=0` ⇒ "置位/吞掉/复位"那套判据**作废**；
第 2 批改问 **"`TextInput` 有没有被 raise、raise 给了谁、TextBox 的处理器跑没跑"**。

**交付（5 个 PC 应用器 + 1 个 PF 应用器；sha256）**
| 应用器 | sha256 | 干什么 |
|---|---|---|
| `patch-presentationcore-inputtrace.py` **v3** | `62a0822d…` | 插桩类里加 P1…P5 helper + **第 2 批独立预算**（Text 类必打/其它采样 20 行） |
| `patch-presentationcore-inputsite-trace.py` **新** | `e257247a…` | **P1** `InputProviderSite.ReportInput`（生成 `InputProviderSite.Linux.cs` + 接线） |
| `patch-presentationcore-apartment.py` **扩展** | `0a52507b…` | **P2/P2'**（`InputManager.ProcessInput` 入口+返回，含 **`KeyboardDevice.FocusedElement`**）、**P5/P5'**（`RaiseEvent` 前后 + **目标元素**）；补丁 H **逐字未改** |
| `patch-presentationcore-registry.py` **扩展** | `13ee8456…` | **P3a/P3b/P4a/P4b**（`Raw→StartComposition` 全程）；补丁 J 的 `?.` **逐字未改** |
| `patch-presentationframework-texteditor-trace.py` **新** | `aba49330…` | **P6a/P6b1/P6b2/P6c/P6d**（TextBox 的 `OnTextInput`，自带 `WpfLinuxPfInputTrace`） |

**预测 sha（/tmp 假树跑出来的真值；上一批的预测已被主控重放**逐字节**证实 ⇒ 可当验收判据）**
`HwndSource.Linux.cs` `47934329…`（v3，会变）｜`InputManager.Linux.cs` `70a5d54b…`｜
`TextCompositionManager.Linux.cs` `e56065a8…`｜`InputProviderSite.Linux.cs`（新）`3a079a8f…`｜
`TextEditorTyping.Linux.cs`（新）`1f8eb295…`｜`HwndKeyboardInputProvider.Linux.cs` `f56e647e…`（不变）｜
`Dispatcher.Linux.cs` `cbb971f5…`（不变）。

**判据（互斥六格）**：甲 P1 有/P3a 无（没到 Raw 段）→ 乙 P3a 有/P5 无（没 raise）→
丙 P5 有但目标 ≠ 你的 TextBox（焦点/路由，比 `Type#hash` 三方对齐）→ 丁 P5 目标对/P6a 没跑（PF 处理器没被调）→
戊 P6a 有/P6b1 有（**TextBox 跑了但第一道门就 return**，行里直接读出四个条件真假）→ 己 P6c/P6d 有而文本仍不变（往 `TextEditor` 插入路径查）。

**纪律**：两个"别人的"生成物（`InputManager.Linux.cs`、`TextCompositionManager.Linux.cs`）我**扩展原应用器**而**不另起写者**
（否则"谁后跑谁赢"会静默抹掉补丁 H/J 或这批探针 ⇒ 只表现为"一行都不打"）；跨命名空间调用点**全限定**（编译错误级坑）；
顺手修了 `registry` 的 `--check` 语义（原来生成物过时也 rc=0）。

**没做**：没生成物、没编译（PC/WindowsBase/PF 都没编）、没发桥、没跑应用 ⇒ §8.3 的"实跑是否出现过"整列 `未跑`。
**波表**：两个新应用器名字落在 `patch-presentation*` 通配里（自动兜底会跑，但会打 ⚠）⇒ 建议登记进 `APPLIERS_EXPLICIT`（顺序无依赖）。

---

## 23. 输入链**第 3 批**（Q1…Q4，**待重放**）：只写源码与报告

> 详细版：`build/MilBridge/T1c-inputtrace-report.md` 的「第 3 批」整节（§8.9 澄清 + §9.1-§9.6）。

**第 2 批结论**：六格命中"己"（`P6c`/`P6d` 全绿、`ScheduleInput` 已排队 `text="A"`、样例 `changes=0`）。
读上游 `TextEditorTyping.ScheduleInput:1569-1591` ⇒ 普通输入的插入排在 **`DispatcherPriority.Background`** 的
`DispatcherOperation`（`BackgroundInputCallback`）上 ⇒ 第 3 批钉住"排队之后"这条整路。

**交付**：`tools/patch-presentationframework-texteditor-trace.py` **v3** = `44456383ecabd7085dfdf5cb1fe7270093436f162b5bd70777dec3bfe3ed324b`
（在第 2 批 P6 五处之上加 **Q0 五处 + Q1…Q4 十三处**；**Q0b 是决定性那一格**：`PendingInputItems == null` 的真假）：`BackgroundInputCallback` 入口/出口、`_FlushPendingInputItems` 入口/每条 item/出口、
`TextInputItem.Do()` 入口/`UiScope==null` 早退/返回、`DoTextInput` 入口/过滤后/**写之前**/**写之后**/异常/出口）。
**预测 sha**：`build/PresentationFramework.Linux/TextEditorTyping.Linux.cs` = **`5430f349fc7912664d838aec075a9cc6bad673a4c616d2d4b50c146f3e983514`**；**其余生成物一律不变**。
> ✅ 预测机制**连续两批逐字节命中**：本轮核对仓库，第 2 批预测的五个 sha（`47934329`/`70a5d54b`/`e56065a8`/`3a079a8f`/`1f8eb295`）与落盘**全部相同** ⇒ 本批重放**只改 1 个文件**。

**唯一一处非纯插入**（已在应用器里点名断言，不是放水）：`DoTextInput` 整个方法体被包一层 `try/catch`，
`catch` 里**记录后 `throw;`**（异常类型/栈/控制流不变）；`throw` 条数断言 = 上游 0 + 1 处故意 rethrow；大括号盈亏 312/312 不变；
`--prove` 逆序回代后与上游**逐字节相同**（`9e62a288…`）。

**判据（九格互斥）**：① Q1 从不出现 ⇒ Background 操作**从未执行**（卡调度）→ ② Q1 有但 flush 队列里没有 `TextInputItem` →
③ item 在队列里而 Q3 不出现 → ④ Q3b 命中（`UiScope==null` 静默丢弃）→ ⑤ Q4b 过滤后长度 0（`_FilterText` 吃掉）→
⑥ Q4d 显示文档没变（`SetSelectedText` 没写进容器，**第 4 批的入口**）→ ⑦ Q4d 变了但 Q4f 是 `Rollback`（被 undo 回滚）→
⑧ Q4e 有（**抛异常了**，类型/栈在行里）→ ⑨ 全绿且文档确实变了而样例仍旧 ⇒ 问题在样例读取/刷新（T3 侧）。

**顺带给出一个强假设的坐标清单**（§9.5，**先不写、等授权**）：`Dispatcher.ProcessQueue` 的
`backgroundProcessingOK = !IsInputPending()`（:1986）+ `_foregroundPriorityRange`（Loaded..Send，:2819，**Background 不在内**）
+ `IsInputPending()` → `MsgWaitForMultipleObjectsEx(QS_INPUT|QS_EVENT|QS_POSTMESSAGE)`（:2271-2314）；
而原生 shim 的 `MsgWaitForMultipleObjectsEx`（`win32_msg.c:788/804/810`）把"**队列里任何一条消息**"（含 `_msgProcessQueue` 0x8000、`WM_PAINT`、`WM_TIMER`）
都算成"有输入"⇒ **Background 操作永远排不上，而 Normal/Input 照走** ⇒ 与"其它功能正常、只有打字不进"完全吻合。

**没做**：没写第 4 批（等 T3 结论）、没写 WB/原生探针（等授权）、没生成物、没重放、没编译、没跑应用。
**已按要求澄清**：`composition == null` 是**预期的**（`as FrameworkTextComposition` 对非 IME 输入返回 null ⇒ 走 `ScheduleInput`），**不是线索**。

**本轮追加（主控两条新要求）**
1. **Q0（决定性那一格）**：`ScheduleInput` 入口打 `PendingInputItems == null` 的真假（`:2082`），
   并在 `BeginInvoke` 之后（`:2089` 已投递）与 `Add` 之后（`:2095` count）各打一行；
   **Q1 的入口探针特意移到两条 `Invariant.Assert` 之前**（`:2130`）—— 断言若 FailFast，读数也必须已经出去。
   **四格判据**：① Q0b=False ⇒ **从不投递**（根因=谁把字段留成非 null）→ ② Q0b=True 有 Q0c 但 Q1 无 ⇒ 投了没跑（回 WB）→
   ③ Q1 有、Q4f 出口文档长度不变 ⇒ 插入路径本身失败（Q3b/Q4b/Q4e/Q4f）→ ④ Q4f 长度变了而样例不变 ⇒ 两个对象不是同一个。
2. **我上一版那条"Background 被 `IsInputPending()` 饿死"的推断已撤回**（T3 实测四优先级全执行，含最低的 ContextIdle）；
   同时也**放弃**"用消息号推优先级"（shim 的进程队列通知只用 `0x8000` 一个号）。WB/原生坐标降级为**备用**（只有判到格 ② 才需要）。
3. **"吞异常点"的答案**：这条插入路径上（`TextEditorTyping.cs` / `TextEditor.cs` / `TextSelection.cs` / `TextRange.cs` / `TextContainer.cs` / `TextPointer.cs`）
   **`catch` 计数全是 0** ⇒ 不存在静默吞异常；有 `catch` 的都在别的子系统（CopyPaste 8 / RtfToXamlReader 9 / DragDrop 2 …）。
   `DoTextInput` 内异常已由 Q4e 全部留痕（唯一可能"吞"的是外层 Dispatcher 操作异常路径 = 格 ② 的范畴）。

---

## 24. 输入链**第 4 批**（Q5…Q9）：`TextContainer.Changed` → `TextBox.Text` DP（**待重放**）

> 详细版：`build/MilBridge/T1c-inputtrace-report.md` 第 4 批整节（§10.0-§10.6）+ 顶部**命题改写横幅**。

**命题改写（第 3 批实跑后）**：**键入到了、容器改了、屏幕也画出来了**（注入后帧里 TextBox 就是 `AB` 加光标，
`Q4d` 读到 `len=1 text="A"`、`Q3c` 读到 `len=2 text="AB"`）；坏的是 **`TextBox.Text` 这个 DP（与 `TextChanged`）一直停在旧值** ——
**不是**「打字到不了 TextBox」。**"键入腿"判据换口径**：`changes>0` **降为旁证**，主判据 = 注入前后 `WFP_BOXID` 矩形内的像素/字形差异；
T3 此前两趟 burst 的"屏幕还是旧文本"读数**作废**（都在注入之前）。
⭐ **我上一版把嫌疑押在 `BackgroundInputCallback` 上，方向错了**：`Q0i` 显示 `AcceptsRichContent=False` ⇒ 走**立即执行支路**，不经 Background 投递。已登记。

**交付（新增 4 个生成物，其余一律不变）**
| 件 | sha256 |
|---|---|
| `tools/patch-presentationframework-textbox-textdp-trace.py`（**新**） | `f4eca0065b7575adc7419c2308a50ee029b1d8a986590546764659a4b9878493` |
| 生成物 `TextContainer.Linux.cs`（含 tracer 类） | `5a5cb2e709697933a6fa09011b84180ca5b744c4142baf12b8d6048652a7545e` |
| 生成物 `TextBoxBase.Linux.cs` | `e316a49dc3b336760404fbf17c29012d1d358b92047c1d868851dff84753bef0` |
| 生成物 `TextBox.Linux.cs` | `704e7aea3ebb30b09c9ed96736b4be96d0a80d791e075498fa5ff7f53c45c243` |
| 生成物 `DeferredTextReference.Linux.cs` | `1f144da79c6a9071a92e6bec9e422439f4599bee610cd90493374ef8f4c42b4c` |
csproj 注入 **8 行**（4 × Remove 上游 + 4 × Include）；`port-lib.py PresentationFramework` 会抹掉 ⇒ 必须重跑。

**逐点（生成物:行；helper 定义行同在 TextContainer.Linux.cs）**
`Q9a BeginChange 计数` `:3567`(`:230`) · `Q5a EndChange 入口` `:597`(`:246`) · `Q9b 计数自减后` `:602`(`:237`) ·
**`Q5b raise 之前`（`ChangedHandler==null?`）` :622`(`:253`)** · **`Q5c raise 之后` `:629`(`:261`)** ·
`Q6a TextBoxBase 入口`(早退门之前) `TextBoxBase.Linux.cs:1362`(`:269`) · `Q6 早退门命中` `:1369`(`:277`) · `Q6b 走到 OnTextChanged 之前` `:1412`(`:284`) · `Q6c 出口` `:1421`(`:292`) ·
`Q7a TextBox 入口` `TextBox.Linux.cs:1208`(`:300`) · **`Q7b 到达 SetCurrentDeferredValue` `:1232`(`:312`)** · `Q7c 出口` `:1266`(`:320`) ·
`Q8a GetValue 入口（含 Parent 类型）` `DeferredTextReference.Linux.cs:55`(`:328`) · **`Q8b 取到的字符串` `:60`(`:337`)**。

**判据（互斥九格）**：① Q5b/Q5c 不出现且 Q9b 计数不归零 ⇒ 变更块没关（谁多 Begin 少 End）｜①' Q9b 归零但 `ChangedHandler=null` ⇒
**没人订阅**（`TextBoxBase.cs:1435`）｜② Q5c 有 / Q6a 无 ⇒ 订阅链断｜③ Q6a 有 / **早退门命中** ⇒ `TextChanged` 被 `:1352` 那道门挡回｜
④ Q6b 有 / Q7a 无 ⇒ 多态转发断｜⑤ Q7a 有 / Q7b 无 ⇒ `_isInsideTextContentChange` 守卫卡住｜⑥ Q7b 有 / Q8 从不出现 ⇒ 没人来读 DP｜
⑦ Q8b 取到新串而样例仍旧 ⇒ DP 值解析/缓存链（下一批：`OnDeferredTextReferenceResolved` + `TextBox.Text` getter）｜
⑧ `Q8a` 的 `Parent=(null)` ⇒ `tb?.…` 不回调（静默）｜⑨ `Q7c resetText=True` ⇒ 命中"把容器拉回"的分支。

**两条硬约束**：① 探针**不读任何 DP**（读 DP 会触发 deferred 解析 = 观测者效应），只读容器文本与 `_newTextValue` 类型；
② 入口探针**都在早退门之前**。**闸门**：13 锚点各 1 次；`throw` 逐字不变（3/10/3/0）；大括号盈亏一致（451/276/223/5）；结构断言 24/24；
`--prove` 四文件逆序回代后与上游**逐字节相同**；/tmp apply rc=0 → `--check` rc=0 → **幂等 ✅**。
**没做**：没生成物、没重放、没编译、没跑应用。

---

## 25. 输入链**第 5 批**（W1…W4）：读路径为什么不解析 deferred（WindowsBase，**待重放**）

> 详细版：`build/MilBridge/T1c-inputtrace-report.md` 第 5 批整节（§11.0-§11.6）。

**第 4 批结果（命中⑥格）**：PF 侧**全链已绿**（`Q5c Changed 已 raise`、`Q6b 即将 RaiseEvent(TextChangedEvent)`、`Q7b 已 SetCurrentDeferredValue(TextProperty, dtr)`），
而 **`Q8a/Q8b`（`DeferredTextReference.GetValue`）0 行**；T3 口径修正：样例读了 **18 次** `.Text` 而解析点一次没触发
⇒ **读路径从不解析 deferred**，读者一直拿旧 local 值。**PF 侧按主控要求停手**，只留 `Q8a/Q8b` 当哨兵。

**交付（新增 1 个生成物）**
| 件 | sha256 |
|---|---|
| `tools/patch-windowsbase-dpvalue-trace.py`（**新**） | `3ed499887ac7279201f82b5d106f8762f8522969944e5a385b85220a33838a78` |
| 生成物 `build/WindowsBase.Linux/DependencyObject.Linux.cs` | **`f898a901c45e638d110a8c8e5e3317b9466668c8374ff436af4be7b9fe01b3ef`**（修 CS0103 之后；仓库里现在那件 `8909dd56…` 是**坏件**） |
其余一律不变（`Dispatcher.Linux.cs cbb971f5…`、PF 四个第 4 批生成物、PC 五个）。

**逐点（生成物:行；helper 定义行同文件）**：`W1 GetValue 入口 :429`(def `:199`) · `W2 GetEffectiveValue 入口 :577`(`:207`) ·
**`W3a 提前返回（判 A/B + B 打调用栈前 4 帧）:582`(`:224`)** · `W3b 真解析(经典路径) :615`(`:240`) · `W3c 修改值分支 reference==null :653`(`:250`) ·
`W3d 修改值分支真解析 :682`(`:264`) · **`W4a 存值之后 :1062`(`:281`)** · `W4b SetValueCommon 出口 :1110`(`:296`)。

**判据（互斥）**：① W1 有而 W2/W3x 全无 ⇒ 读的根本不是这条路（查 `_tb.Text` 用的哪条 API）｜
**②=A** `W3a` 原因=`IsDeferredReference==false` ⇒ 写侧没留住标记（看 W4a/W4b）｜**③=B** `W3a` 原因=`requests` 带 `DeferredReferences/RawEntry` ⇒
**读方主动要原始 deferred**（栈前 4 帧直接指人）｜④=C1 `W3c` 有 ⇒ 有 modifier 但不是 expression/coerced｜
⑤=C2 `W3b/W3d` 有 ⇒ 路径其实通了（与哨兵 0 行**矛盾**，回头查哨兵）｜⑥ W4a/W4b 有而读侧全无 ⇒ 同 ①。

**三条硬约束**：**只对 `dp.Name=="Text"` 打**（最热路径）｜**入口探针在各早退门之前**｜**不读任何 DP**、
字段读取全在 helper 内 try/catch、调用点只传局部变量/结构体副本（不在调用点做字段/下标访问）。
**关于"W1 打返回值的类型"**：改到 **W3 四个出口**各打一行（既给类型又给路径，且**保持纯插入** —— 在 `GetValue` 里拆 `return` 会变成等价改写，把"只插入"降级）。

**闸门**：8 锚点各 1 次；`throw` 16==16；大括号 530/530；结构断言 19/19；`--prove` 逆序回代后与上游**逐字节相同**（`edeb712d…`）；
/tmp apply rc=0 → `--check` rc=0 → **幂等 ✅**。
**波表**：`patch-windowsbase-dpvalue-trace` **不在** `patch-presentation*` 通配里 ⇒ **必须显式登记进 `APPLIERS_EXPLICIT`**（与 `patch-windowsbase-msgflow` 同理）。
**没做**：没生成物、没重放、没编译、没跑应用。**"键入腿"按新口径写**：像素三极性牙 PASS，但 `D-P1` = **INCONCLUSIVE**（不许用"画得对"冒充"读得对"）。


**第 5 批修正（CS0103，被集成波的构建步骤抓住）**：`W3d` 探针把 `referenceFromExpression`（**修改值分支内部作用域**里声明的变量，
上游 `DependencyObject.cs:348-350`）传出了块外 ⇒ 编译失败。**修法**：把 W3d **挪进 else 块之内**（纯插入，读数不减）。
**新增机械闸门** `build/MilBridge/tools/t1c-trace-args-scope.py`（审计"调用点实参在不在可见作用域"；**牙齿测试**：坏件报出唯一 1 条真阳性、
修好后 0、五棵预测树 109 个调用点全绿）。**两条教训升级为流程要求**：**预测 sha ≠ 能编过**、**`--prove` ≠ 能编过** ——
两者都只证"生成/插入的确定性"，**与"能过编译器"是独立的两件事**。
修正后：应用器 `3ed49988…`；重放后生成物应为 **`f898a901c45e638d110a8c8e5e3317b9466668c8374ff436af4be7b9fe01b3ef`**；其余 7 个应用器 `--check` 仍全 rc=0。

---

## 26. 输入链**第 6 批**（W4 身份 / W5 写入口 / W6 有效值槽 / W7 flatten）：谁把它换回去了（**待重放**）

> 详细版：`build/MilBridge/T1c-inputtrace-report.md` 第 6 批整节（§12.0-§12.6）。

**第 5 批命中 A 格**：写侧出口 `IsDeferredReference=True`（`newEntry.Value=ModifiedValue`），
读侧 `effectiveEntry.IsDeferredReference=False` 且值仍是旧串 `"seed-文本"` ⇒ **有效值槽被换回了普通字符串**。

**交付（两个生成物会变；其余一律不变）**
| 件 | sha256 |
|---|---|
| `tools/patch-windowsbase-dpvalue-trace.py`（第 5+6 批 + CS1503 修正） | `a689691ce0b1308f154c842b9873ee0302524838cb7a778edf32e643e064b207` |
| **新** `tools/patch-windowsbase-entry-flatten-trace.py`（W7） | `901a2f92875256f1f5b54e7ecb07e8e319e98fbdf075cd9dd167111aa57c9906` |
| 生成物 `DependencyObject.Linux.cs` | **`e2118ef2ecdb2e51e897a6b5ab643cbcb88a45098f80f641f2e10d39d667f8ac`**（`fda25e29…` 是编译失败那一版） |
| **新**生成物 `EffectiveValueEntry.Linux.cs` | **`c53a2f1a27dc98c430e2a7ee0a9f0e1464207dfa3b97f23b8a72dbd9fcf51c0f`** |

**逐点**：**W5** 写 "Text" 的**八个入口**各打一行 + **调用栈前 4 帧**（`SetValue` `:782`／`SetCurrentValue` `:810`／`SetValueInternal` `:854`／
`SetCurrentValueInternal` `:876`／`SetDeferredValue` `:892`／`SetValue(key,value)` `:944`／`CoerceValue` `:1463`／`SetValueCommon` `:1006`，均在各自早退门之前）；
**W4a** `:1161`（**target 挪到行首** + `dp.GlobalIndex` + `entryIndex` —— 第 5 批 target 在行尾、易被截断，这是主控点名的观测缺口）；
**W6a** `:1199`（进 `UpdateEffectiveValue` 之前：operationType + new/old + 当前有效值槽）与 **W6b** `:1213`（之后：**有效值槽**的 `IsDeferredReference`/`Value`）；
**W7** `EffectiveValueEntry.Linux.cs:336/:358/:442`（`GetFlattenedEntry` 三个 return：无修饰/只有表达式标记/有修饰，**只对 deferred 条目打 ⇒ 有界**）。

**判据（互斥）**：**a** 写读 **`target=`/`dp.GlobalIndex=` 不同** ⇒ 不是同一对象/属性（D-P1 归属要重写）｜
**b** 目标相同且 deferred 写**之后**还有一次 `value=string` 的写 ⇒ **栈指人**（谁换回去的就是根因）｜
**c** 没有第二次写而 **W6b** 显示槽已非 deferred ⇒ **槽被写坏**（进 `UpdateEffectiveValue`）｜
**d** 都不成立（槽里确是 deferred、读侧却拿到非 deferred）⇒ **读侧取错槽位/索引**（看 `LookupEntry`/W7）。

**依赖**：`EffectiveValueEntry.Linux.cs` 用到的 tracer 类定义在 `DependencyObject.Linux.cs`（同 namespace/程序集）⇒ **两个应用器必须同波应用**；
B 的 `--check` **显式核对** A 的接线标记，缺了直接报错。**两个名字都不在 `patch-presentation*` 通配里 ⇒ 都要登记进 `APPLIERS_EXPLICIT`**。

**顺带发现（值得单独清一遍）**：上游 `EffectiveValueEntry.cs:423` 那条 `Debug.Assert`
（"**`IsDeferredReference` 与 `Value is DeferredReference` 必须同步**"）**正是本族要的断言**，
但 `Debug.Assert` 是 `[Conditional("DEBUG")]` ⇒ **Release 下被编译掉**，所以它没能替我们发现 —— M7b 的 `Invariant` 补丁只覆盖 `Invariant.Assert`。

**闸门**：A 16 锚点各 1 次 / `throw` 16==16 / 大括号 543/543 / 结构断言 26/26 / `--prove` 逐字节相同；B 3 锚点各 1 次 / 132/132 / 6/6 / `--prove` 逐字节相同；
/tmp A→B 顺序 apply 均 rc=0、两个 `--check` 均 rc=0、幂等 ✅。
**机械尺子**（第 5 批 CS0103 后新增的流程要求）：本批两件 **20 个调用点 SUSPECT 0**；全量 **121 个调用点 SUSPECT 0**（上一批 109）。
**没做**：没生成物、没重放、没构建、没跑应用；**仍未编译**。


**第 6 批修正（两处 CS1503，`uint`→`int`）**：`EntryIndex.Index` 是 **`uint`**，而 `W4StoreLocal`/`W6AfterUpdate`/`Tgt` 形参写成 `int`。
**修法**：形参统一改 **`long`**（取方案 (b) 的"调用点零改动"精神；用 `long` 而非 `uint` 是因为 `Tgt` 还要接哨兵 `-1`）。
**全量扫过所有 helper 的形参 vs 实参**（本批 + 历史各批），只此两处不一致。
**尺子升级**：`t1c-trace-args-scope.py` 增加**类型-lite**（形参类型 vs 实参表达式；已知成员 `EntryIndex.Index`=uint、`GlobalIndex`=int…；判不了的**列出来**）。
**牙齿**：拿波失败那一版当输入 ⇒ 报出**恰好这 2 处**；修好后 ⇒ 0；全量 80 调用点 / 0 / 0。
**✅ 已编译（自带证据）**：`dotnet build build/WindowsBase.Linux/WindowsBase.Linux.csproj -m:1 --nologo -v q -p:BaseOutputPath=/tmp/t1c-verify/bin/ -p:BaseIntermediateOutputPath=/tmp/t1c-verify/obj/`
⇒ **0 个警告 / 0 个错误 / BUILD_RC=0**（产物与 FileListAbsolute 都在 `/tmp/t1c-verify`，含两份生成物；仓库 bin/obj 未动）。
**流程要求（本批起）**：每批必须写明 **`✅ 已编译（命令 + 0 错 0 警）`** 或 **`❌ 未编译（原因）`**。


---

## 27. 第 6 批**运行期修正**：实参不惰性 ⇒ 探针关着也求值 ⇒ 静态初始化期 NRE（已修 + 两闸门自跑）

**崩溃**：`ManagedLayer.Tests.HwndSource_Characterization_OnLinux` 崩在 `Transform..cctor → MatrixTransform.set_Matrix → SetValueCommon`，
`DependencyObject.Linux.cs:1200` 就是 W6a 调用点 —— 我把 `_effectiveValues[entryIndex.Index]` **写在实参里**，
⇒ **探针关着也求值**，而静态初始化期 `_effectiveValues` 还是 null ⇒ NRE。
（我上一批拿"上游 `:807` 也有同款下标"开的口子**站不住**：上游那处在受保护的守卫分支里，我的落点在守卫之外。）

**修法**：调用点只传**原件**（`entryIndex` + `_effectiveValues`），**null/越界判断全在 helper 内**，取不到就打"越界/不可用"，**绝不抛**。
**全批惰性化**（8 处）：WB `W6a/W6b/W4a`；PF `Q2b`（`PendingInputItems[i]`，T3 扫出的残留）、`Q3`（`TextEditor.UiScope`）、
`Q7a/Q7b/Q7c`（`this.TextContainer`）、`Q6b`（`undoAction.ToString()`）；PC `P3b`（`e.StagingItem.Input.Source` 属性链）。
**我自己引入并被自己的编译闸门抓住的一处**（如实登记）：PF `ContainerOf` 里 `TextBox` 未全限定 ⇒ CS0246，已修（全限定 + 走 `TextEditor._GetTextEditor`）。

**尺子新增第三条检查（实参形态 ARGSHAPE）**：实参只允许 `this`／普通局部变量／基元枚举结构体／字符串字面量／纯强制转换／白名单成员；
**不许**下标、属性链（≥2 个 `.`）、`new`、方法调用。**牙齿**：修前的 `TextEditorTyping`（`:599`）与坏件 `DependencyObject`（`:1199`）**各报 1 处**；修后全量 **80 调用点 / 0 / 0 / 0**。

**两条闸门（本轮自己跑，原文）**
```
PRIVATE_RC_WindowsBase=0 / PRIVATE_RC_PresentationCore=0 / PRIVATE_RC_PresentationFramework=0   （各 0 警告 0 错误，私有输出目录 /tmp/t1c-verify/**）
REPO_RC_WindowsBase=0 / REPO_RC_PresentationCore=0 / REPO_RC_PresentationFramework=0            （同上，编进仓库 bin 供测试用）
Xvfb :96（自起，PID 自管）→ DISPLAY=:96 dotnet test …/ManagedLayer.Tests.csproj -m:1 --nologo
已通过! - 失败: 0，通过: 58，已跳过: 0，总计: 58，持续时间: 33 s     TEST_RC=0     XVFB_KILLED=<自己的 PID>
```

**流程第三条（与"预测 sha ≠ 能编过""`--prove` ≠ 能编过"并列）**：**"关掉 ≠ 无副作用"** —— 探针关着时**实参照样求值**，
所以实参必须惰性（裸原件），下标/属性链/分配/方法调用一律挪进 helper 并在里面 try/catch。

**当前生效 sha（本轮改动过的）**：`patch-windowsbase-dpvalue-trace.py 44c15aa0…`｜`patch-presentationframework-texteditor-trace.py 91828203…`｜
`patch-presentationframework-textbox-textdp-trace.py fd773c66…`｜`patch-presentationcore-inputtrace.py d54e3ccc…`｜`patch-presentationcore-registry.py f1a8f73f…`｜
尺子 `35b68f03…`；生成物见 `T1c-inputtrace-report.md` §12.8 末尾表。

---

## 28. 第 6 批**读数修正（L12）**：额度触顶必须看得见 + W7 独立额度 + W7 收窄到 Text

**阻塞**：WB 一趟 `W*=199/200`，其中 **W7=144** ⇒ 输入时刻的读数全被静默丢弃（"没打"与"没发生"分不开）。

**W7 过滤读码判定**：**过滤是生效的**，问题是"太宽 + 共用额度" ——
`EffectiveValueEntry.cs:56` `IsDeferredReference = value is DeferredReference;`，
而 `DeferredReference` 的子类不止文本那一族：**`DeferredResourceReference`（资源/样式/模板，SystemResources.cs:1700）**、
`DeferredRunTextReference`、`DeferredSelectedIndexReference`、`DeferredTextReference`、`DeferredMutableDefaultReference`
⇒ 启动期大量资源查找都命中 ⇒ 144 行是**预期**。

**三条修法**：① 总上限 **200 → 2000** + **触顶打一行**（`NoticeBudget`，文案含"已打 N 行"与"「没打」≠「没发生」"）；
② **W7 独立额度 16 行** + 自己的触顶通知（再也吃不光主格额度）；
③ **W7 收窄到 Text**：上游 `_propertyIndex = (short) dp.GlobalIndex`（`EffectiveValueEntry.cs:29/35`）⇒
在 `IsTextDp` 里记下 TextProperty 的 GlobalIndex，W7 只在 `PropertyIndex == 它 || requests 带 DeferredReferences/RawEntry` 时打。
同一模式推广到**全部 5 个 tracer**。

**⚠️ 我自己又踩的坑（编译器 warning 抓住）**：第一次的 `NoticeBudget` 加在 `if(… > MaxLines) return;` **之后** ⇒
**不可达代码**（CS0162，`HwndSource:99`/`Dispatcher:191`/`TextEditorTyping:120`/`TextContainer:192`），**通知根本不会打** ——
"看得见"这个修法本身变成了假的。已改写成"条件 + 块"，现在 6 次编译全 **0 警告 0 错误**。⇒ **warning 是读数**。

**闸门（最终）**：私有目录编译 3 工程 **0/0**；仓库编译 3 工程 **0/0**；
`DISPLAY=:96 ManagedLayer.Tests` ⇒ **失败 0 / 通过 58 / 跳过 0**（`TEST_RC=0`，Xvfb 自起自灭）；
尺子全量 **80 调用点 / 作用域 0 / 类型 0 / 实参形态 0**。

**流程第四条（L12）**：**额度触顶必须看得见**（任何有上限的探针，触顶都要打一行含"已打 N 行"）；
辅助格要有**独立**额度；**能靠过滤收窄就别靠限额**。

---

## 29. 第 7 批：读侧把**索引**打出来（四格命中 d 之后的收尾）

**交付**：`patch-windowsbase-dpvalue-trace.py` = `2b5cee682ca16d183b4af6382d5ad3dc3ed74adbf59996a29acc9b871691330e`；
生成物 `DependencyObject.Linux.cs` = **`4bf6dde4ed97289717951e7f6ed3cdc5bc0b30bc548707edd1f19f5a753f47ae`**（`EffectiveValueEntry` 未变）。

**新增读数**：`W1`（`GetValue` 入口）打**读侧 `LookupEntry` 得到的 `Index/Found`**（惰性：helper 内调，实参只有 `this/dp`）；
`W2`/`W3a` 打**读路径实际传入的 `entryIndex`**；`W8/W8'` 打 `LookupEntry` 入口 + **四条出口**（含"未找到⇒插入位"）；
`W9/W9'` 打 `CheckEntryIndex` 入口 + **出口[沿用旧索引]**（"重新查找"由紧随的 W8 读数体现）。全部只对 Text 的 `targetIndex` 打 ⇒ 有界。

**`EntryIndex` 编码（逐字依据）**：`EntryIndex.cs:17-45` —— `_store` 是打包 `uint`，**bit31 = `Found`**，**bit0-30 = `Index`**（取值时掩掉 bit31）
⇒ **`Index` 不可能为 -1**，也没有 local/effective 标志位；`Found=false` 时 `Index` 是"**插入位置**"（`LookupEntry` 注释逐字）。
⚠️ 因此第 6 批 `W5` 行里的 `entryIndex=-1` **是我自己的哨兵**（该调用点没有索引），已改成打 `(该点没有索引)` —— 又一处"把非读数打成读数"，登记。

**陈旧索引机制（逐字依据）**：上游 `CheckEntryIndex` 上方注释自己写明："…we have made a call out and thereby caused changes to
the `_effectiveValues` store on the current element. In that case we would need to aquire new value for the index."；
`CheckEntryIndex:3030` 槽主匹配 ⇒ 沿用，否则 `LookupEntry` 重查；`InsertEntry:3102` 插入即整体后移、`:2854-2861` 压缩、
`:3120-3132` 增长同样搬动条目 ⇒ 跨调用持有的索引可能指向别人的槽。`DependencyObject` 里**没有** `EntryIndex` 字段（索引只在局部变量里）。

**两处我自己引入的缺陷（本轮登记）**：① 一次脚本在断言处中断 ⇒ helper 签名与调用点只改了一半（5 实参 vs 4 形参），
**被我自己的尺子当场报出 6 条**（未走到编译器）；② `-1` 哨兵冒充运行时读数。两处修完才跑闸门。

**闸门**：私有目录编译 3 工程 **0/0**；仓库编译 3 工程 **0/0**；`DISPLAY=:96 ManagedLayer.Tests` ⇒ **失败 0 / 通过 58 / 跳过 0**（`TEST_RC=0`，Xvfb 自起自灭）；
尺子 **87 调用点 / 作用域 0 / 类型 0 / 实参形态 0**。

---

## 30. 第 8 批：原始槽 vs ModifiedValue vs effectiveEntry（并排）+ flatten 取值归属

**交付**：`patch-windowsbase-dpvalue-trace.py` = `6a32c4d82eef845720c8bdbce7d5c5b5cb4723b7bc86e39bb5d0c40a4586981e`；
`patch-windowsbase-entry-flatten-trace.py` = `909df7198f6fafef76b42ed314b031e9e3a0b56fc9a010782e0ce4e356f4cceb`；
生成物 `DependencyObject.Linux.cs` = **`0a4a7ba5510a0b55624ea3e23ce7921703b8cfe77fb7f1c54aef2aacd2e57a77`**、
`EffectiveValueEntry.Linux.cs` = **`9854366f0ef5d747714c9666eacc5ad8e810b34aafc45cafe4c60be2cb0c570a`**。

**新增读数**：`W2'`（原始槽标志 + `ModifiedValue` 四字段类型）与 `W2''`（算出的 effectiveEntry）**并排**（零新增实参：`entry` 就是调用点的 `_effectiveValues[idx]`）；
`W10` 在 `GetFlattenedEntry` 的**九个 `entry.Value = …` 取值点**各打一行（采用值类型 + entry 标志 + `ModifiedValue` 四字段）⇒ 直接判"flatten 取了哪个 modifier 值"；
`W8` 加**调用序号 + 相对时刻**（判那 3 次 `Index=24` 是否在输入之后）。`_source` 是 private 且无访问器 ⇒ 打它的**派生标志**（报告里明说这处缺口）。

**判据四格**：① 取了 `BaseValue` 而 `CoercedValue` 是 deferred ⇒ **flatten 取值选择错**（能指到行）；② `ModifiedValue` 三字段都不是 deferred ⇒ 写侧没放进 modifier；
③ W7a"无修饰 ⇒ return this" ⇒ 与 `W6b` 观感矛盾 ⇒ **修正 `W6b` 的判读口径**；④ 取对了值但 flattened entry 没带 mark ⇒ 查 `:345-355`。

**闸门**：私有目录编译 3 工程 **0/0**；仓库编译 3 工程 **0/0**；`DISPLAY=:96 ManagedLayer.Tests` ⇒ **失败 0 / 通过 58 / 跳过 0**（`TEST_RC=0`，Xvfb 自起自灭）；
尺子 **96 调用点 / 作用域 0 / 类型 0 / 实参形态 0**。
⚠️ **权威产物已被我的闸门构建改动，需主控整波重建**：PC `b5fc5ba10dc0bbd8…`（20:16:53）、WindowsBase `8c073fab0da88169…`（20:13:57）、PF `b580c9234dde04d8…`（20:21:15）。

---

## 31. 第 9 批：RTL 镜像 —— **实推变换 vs 报告口径**（PF 侧探针）

**交付**：`patch-presentationframework-mirror-trace.py` = `a4e6599a8f0a9e754487cd50adebe8177e6eea5b519058fa8a269db589f980c4`；
生成物 `FrameworkElement.Linux.cs` = **`61a5f1e45e6017fbe50dc3717d84faab3222023677c0946278e6fd13661c66ea`**、
`TextBlock.Linux.cs` = **`6067276d0fc3a8da10ca7b0623431d0e51944ff89facf4df369f696ee41826f5`**。

**读码修正（主控假设）**：`ApplyMirrorTransform(parentFD, thisFD)`（`FrameworkElement.cs:4030`）**只做方向判定、没有 offsetX**；
offsetX 在 `GetFlowDirectionTransform():3940` 里（`MatrixTransform(-1,0,0,1,RenderSize.Width,0)`）。
**实推路径** = `SetLayoutOffset:5197`（视觉变换组装点，注释逐字列了 VisualTransform 依赖含 Mirror/RenderSize.Width/FlowDirection）
+ `InternalSetLayoutTransform:5135`（推给元素）+ `GetLayoutClip:4925`（裁剪）。

**逐点**：`M1 :4156`（入口）｜`M1' :4161`（**OffsetX 读数**）｜`M1'' :4166`｜**`M2 :5427`（组装点：offset/oldRenderSize/镜像并排 = 核心格）**｜`M3 :5363`｜`M4 :5151`｜`M5 :4253`（纯插入）｜`M6 TextBlock.Linux.cs:1489`。

**怎么读**：M2 的 `offset.X` 与 M1' 的 `OffsetX` 相同 ⇒ 实推=报告（差异在别处）；**不同 ⇒ 实推镜像中心 ≠ 报告口径（本任务要钉的那一格）**；
M1'' 命中而墨迹仍镜像 ⇒ 镜像不在 FrameworkElement 这条路上；M3/M4 与 M2 不同值 ⇒ 两条路用了不同时刻的 `RenderSize.Width`（裁剪框与墨迹框按不同镜像算）。

**闸门**：私有目录编译 3 工程 **0/0**；仓库编译 3 工程 **0/0**；`ManagedLayer.Tests` ⇒ **失败 0 / 通过 58 / 跳过 0**（`TEST_RC=0`，Xvfb 自起自灭）；
尺子 **103 调用点 / 0 / 0 / 0**。
⚠️ **权威产物已被我的闸门构建改动，需主控整波重建**：PC `c43d351639856680…`、WindowsBase `8c073fab0da88169…`、PF `d9c875ce8095ba18…`。

---

## 32. 债务 #13：把"应用器被登记了但其实没生效"变成**会红的闸门**（只读检查器 + 实测牙齿）

> 对应事故形态：`patch-shared-hwndwrapper-diag` 差点被 `port-lib.py` 静默抹掉接线 —— 那种"跑过、exit 0、什么都没生效"。
> 本轮**只读**：没有跑构建、没有改 `build/integration-wave.sh` / `port-lib.py`（**接线片段写在下面，请你自己接**）。

### 32.1 审计口径（**期望值从应用器自己的声明算出来，不看树**）
对 `APPLIERS_EXPLICIT` 里每个应用器 `<name>`（模块 `src/WpfGfx.Linux.Native/tools/<name>.py`），分三级：

| 级 | 判据 | 期望值怎么来的 |
|---|---|---|
| **A（强）** | **变换等价**：把该模块**自己声明**的编辑表（`EDITS` / `EDITS_HS`+`EDITS_HK` / `TARGETS` / `PATCHES` / `GENERATED`+`ANCHOR`,`REPLACEMENT`）**按顺序应用到上游文本**（内存里），要求结果**出现在落盘的生成物里**；不一致 ⇒ miss | 上游文本 + 应用器声明；**与当前树无关**，树只是被检对象。替换语义跟住应用器：`EDITS/ANCHOR` 只替换 1 次，`PATCHES`（registry/olecontext）是 `out.replace(old,new)` **全部**替换 |
| **B（中）** | 生成物（`TARGET`/`GENERATED`/`GEN_FILE`/`GEN_NAME`）**存在** + 生成物 banner **提到本脚本** + csproj 里该文件的 `<Compile Include=…>` 行 | 应用器模块里的路径常量 |
| **C（弱）** | 只查 csproj 里该应用器的 `MARKER_BEGIN`（**只能抓"接线被 port-lib 抹掉"**，抓不了"内容没生效"——**明说**） | `MARKER_BEGIN` 常量 |

**加一层独立于 wave 的登记清单**（`build/MilBridge/tools/applier-audit-expected.txt`，一行一个）：
否则"某应用器被从 `APPLIERS_EXPLICIT` 摘掉"这件事**在 wave 侧不可见**（少一条 ≠ 红）。清单里显式写明了"必须有"的那几个
（`patch-shared-*`、`patch-uiautomationtypes-*`、`patch-windowsbase-*` —— 名字不带 `presentation` ⇒ 兜底 glob 抓不到）。

**为什么不"跑一遍看是否非零"**：那对 **exit 0 + 命中 0** 是瞎的（正是补丁 N/M 那类事故的形态）。

### 32.2 交付（只读；机读行 `APPLIER_AUDIT …` / `APPLIER_AUDIT_SUMMARY …`）
```
67e18dd64a33ac0a0bfc255f0fd308b8f8341b31fed2ab6f2b0b2881a0016140  build/MilBridge/tools/applier-audit.py
025d7f5148af36b9db18be943982f77f6858ced984ff3321af276f5e103148c9  build/check-appliers.sh
5b93e3943d03798135e3dba875fe9ba2b6e12754bdcc0b3d1f0f81ee5c493686  build/MilBridge/tools/applier-audit-expected.txt
```
**真实树读数（本轮）**
```
bash build/check-appliers.sh              → APPLIER_AUDIT_SUMMARY appliers=20 ok=74  miss=0 red=0 rc=0
bash build/check-appliers.sh --with-check → APPLIER_AUDIT_SUMMARY appliers=20 ok=94  miss=0 red=0 rc=0   （额外跑各自 --check，均 rc=0）
```
A 级 14 个，B 级 6 个（olecontext / textservices / securityzone / xamlaccess / uiautomationtypes-reservedvalue / shared-invariant-failfast / shared-hwndwrapper-diag ⇒ 其中 6 个是 B，其余全是 A）。

**请你自己接到 `build/integration-wave.sh` 的 step 2 之后（一行）**
```bash
python3 build/MilBridge/tools/applier-audit.py || { echo "[波] 应用器审计 RED ⇒ 中止（债务 #13）"; exit 1; }
```
（`--with-check` 可选；它会给每个应用器多跑一次只读 `--check`。我没改你的脚本，只给出这一行。）

### 32.3 牙齿（实测，红→绿；全在 `/tmp/t1c/teeth` 沙箱，**没碰仓库**）
```
(a) 把**声明的期望**改错（给应用器凭空多塞一条编辑）：
    APPLIER_AUDIT applier=patch-presentationcore-inputsite-trace tier=A ok=2 miss=1 \
      detail=InputProviderSite.Linux.cs:生成物与声明的变换不一致
    APPLIER_AUDIT_SUMMARY appliers=1 ok=2 miss=1 red=1 rc=1        ⇒ 红 ✓
    改回 ⇒ … ok=3 miss=0 red=0 rc=0                               ⇒ 绿 ✓
(b1) **注册了但被摘掉登记**（沙箱 wave 清空；登记清单仍要求它在）：
    APPLIER_AUDIT applier=patch-presentationcore-inputsite-trace tier=- ok=0 miss=1 \
      detail=**未登记**（不在 APPLIERS_EXPLICIT 里；登记清单 expect.txt 要求它在）
    APPLIER_AUDIT_SUMMARY appliers=0 ok=0 miss=1 red=1 rc=1        ⇒ 红 ✓
(b2) **登记在、但生成物是未打补丁的上游**（= 应用器没生效）：
    APPLIER_AUDIT applier=patch-presentationcore-inputsite-trace tier=A ok=2 miss=1 \
      detail=InputProviderSite.Linux.cs:**生成物 == 未打补丁的上游（应用器没跑？）**
    APPLIER_AUDIT_SUMMARY appliers=1 ok=2 miss=1 red=1 rc=1        ⇒ 红 ✓
    恢复 ⇒ … ok=3 miss=0 red=0 rc=0                               ⇒ 绿 ✓
```
顺带修掉两个**我自己的**判定缺陷（都是实测暴露的，不是想出来的）：
① 一开始用"逐条 `repl` 计数 == 1"当 A 级判据 ⇒ **把"设计上互相覆盖"的编辑误报成 miss**
   （实测 `patch-presentationcore-textline-fallback`：T1c/RTL 的两条宽松兜底**故意覆盖**了 T1b/D3 的同名站点）⇒ 改成**变换等价**；
② wave 解析用非贪婪 `(.*?)` ⇒ 注释里的 `abort(134)` 这种 ASCII 括号会让解析**提前收尾**，实测**漏掉两个应用器**
   （`patch-presentationcore-textline-fallback`、`patch-presentationframework-xamlaccess`）⇒ 改成"收到单独一行 `)` 为止"。

### 32.4 债务 #4（顺手定性）：`ReachFramework.dll` 两份 sha 不一致
| 实例 | sha256 前 12 | mtime | 大小 |
|---|---|---|---|
| **权威** `build/ReachFramework.Linux/{obj,bin}/Debug/ReachFramework.dll` | `f64b76d43d8a` | **09-13 22:24:20** | 741376 |
| app-local：`samples/WpfFeatureProbe/bin/Debug/net10.0`、`samples/WpfTextDemo/…`、`tests/…/ManagedLayer.Tests/bin/Debug/net10.0`、`build/PresentationFramework.Linux/bin/Debug` | `daf9b6f073f6` | **09-13 22:23:22** | 741376 |
| 更老的一组：`build/PresentationFramework.Classic.Linux/bin/Debug`、`build/DirectWrite.Linux/SystemFontsProbe/bin/Debug`、`samples/HelloWpf/bin/Release/…` | `e88196688ecd` | 09-10 15:07:40 | 741376 |
| `samples/HelloWpf/bin/Debug/net10.0` | `00723a05d843` | 09-11 19:02:42 | 741376 |
| `build/CycleStub.ReachFramework.Linux/{bin,obj}/Debug/ReachFramework.dll` | `067c03858367` | 09-10 14:49:45 | **5120**（**不是同一个东西**：循环桩） |

**判定：既不是"生成物没重编"，也不是"跨配置比对口径错"，而是"app-local 副本只在**消费者构建时**拷贝 ⇒ 权威件后来重编，副本自然落后一代"（= 副本同步机制缺一条）。**
依据：
1. **权威件本身是新的**：`obj/Debug` 与 `bin/Debug` **同 sha**（`f64b76d43d8a`）⇒ 该项目没有"bin 落后于 obj"的问题；而 app-local 那四份的 mtime **整齐一致地早了 62 秒**（22:23:22 vs 22:24:20）⇒ 是**上一轮构建**拷过去的；
2. **一个副本年龄 = 该消费者的最后一次构建时间**：三份 `daf9b6f073f6` 同刻、`00723a05d843`（HelloWpf Debug，09-11）、`e88196688ecd`（三家，09-10）——**同一份权威件在不同消费者目录里有不同年龄** ⇒ 正是 `HintPath + Private=true` 的"消费者构建时拷一次"语义，而不是配置/内容差异；
3. **大小完全相同（741376）**⇒ 同一身份/同一 Debug 配置的产物，不是 Release/Debug 混杂（真正的 `Release` 那份在 `HelloWpf/bin/Release`，属上面那组老的）；
4. **口径错的那一面确实存在**：`CycleStub.ReachFramework.Linux` 里那个 **5120 字节的同名 DLL** 是循环桩 —— 任何"比对同名文件"的口径一旦扫到它，必然报不一致 ⇒ 建议比对口径**限定在"权威项目 bin/obj"与"明确列出的消费目录"**，并且把 app-local 的**陈旧性**按 **mtime** 单独报（不要混进"内容不一致"）。
**建议（不动别人车道，只提）**：要么在波里加一步"权威件变了 ⇒ 刷新已列出的 app-local 副本"；要么把这条 advisory 的口径改成"同类比同类 + app-local 只按 mtime 报陈旧"。

### 32.5 边界与产物
本轮**只读**：没跑构建、没重放、没跑应用；**没改** `build/integration-wave.sh`、`port-lib.py`、`src/**`、`build/shims/**`、`build/DirectWrite.Linux/**`、`samples/**`、`CoverageProbe/refs/**`。
权威产物**没有因本轮变化**。
⚠️ **更正（记录陈旧，我自己复核过）**：本节前一版写"权威产物仍是 PC `c43d351639856680…`、PF `d9c875ce8095ba18…`，仍需整波重建" ——
**这句话已过时**：那两个 sha 是**我 2026-09-13 21:02:36 / 21:05:14 那次闸门构建**的现场读数；此后主控的整波重建（22:23）把产物换掉了。
**现场可复核的表述**（我 22:5x 只读复核 + 主控独立枚举一致）：
```
build/PresentationCore.Linux/{obj,bin}/Debug/PresentationCore.dll  = 23567d420f0dbbaa…  (09-13 22:23:05)
全仓所有 Debug 消费目录里的 PresentationCore.dll（ReachFramework/System.Printing/PresentationFramework/CycleStub.*/samples×2/tests）同 sha ⇒ 与基线 pc_sha 一致
我引用的 c43d3516… / d9c875ce… 在全仓已不存在（find 枚举为空）
```
⇒ **"仍需整波重建"这句作废**；凡引用产物 sha，一律**当场复核 + 标注是哪一次跑的**（这次就是"引旧读数去派活"的实例）。


### 32.6 教训条目（主控点名要写进报告）
1. **解析器不许用非贪婪跨行匹配 shell 代码**：`APPLIERS_EXPLICIT=( … )` 的第一版解析用 `\((.*?)\)`（非贪婪 + `re.S`），
   被注释里的 ASCII 括号 **`abort(134)`** 提前收尾 ⇒ **静默漏掉两个应用器**（`patch-presentationcore-textline-fallback`、
   `patch-presentationframework-xamlaccess`）。**可复用规则**：跨行块解析的收尾判据必须是"**这一行就是 `)`**"，
   而不是"这行里有 `)`"；并**立刻用"条目数 == 期望数"自证**（我当时是 18 != 20 才发现的）。
   这与本轮最有价值的那类缺陷同族：**仪器看不见对象，却盖了绿章**。
2. **逐条替换计数 ≠ 生效**：拿"每条编辑的 `repl` 恰好出现 1 次"当判据，会把**设计上故意互相覆盖**的编辑误报成 miss
   （实测 `patch-presentationcore-textline-fallback`：T1c/RTL 的两条宽松兜底**故意覆盖**了 T1b/D3 的同名站点）。
   ⇒ A 级判据改成**变换等价**（从声明重算期望文本，再与落盘件比）；同时**替换语义要跟住应用器**
   （`EDITS/ANCHOR` 只替换 1 次、`PATCHES` 是 `replace(old,new)` **全部**替换 —— 后者在 `registry` 的 `StylusLogic` 上实测暴露）。
3. **记录自己会陈旧**：引用任何**读数/产物 sha** 派活之前**先复核**，并**标注它是哪一次跑出来的**
   （反例见 §32.5 的更正：那两个 sha 只在我那次闸门构建之后的一段时间内成立）。

---

## 33. 生成物**身份指纹**（ARTIFACT-SRC-FP）：三个工程各一份（照 `bridge-src-fp.sh` 的思路）

### 33.1 覆盖口径（**决定产物的三方**；期望不是"跑一遍看非零"）
| # | 覆盖 | 怎么抽出来的 |
|---|---|---|
| 1 | **上游文本**（被该工程编译的源） | 从**生成的** `build/<Proj>.Linux/<Proj>.Linux.csproj` 里取 `Compile Include="$(UpstreamWpfRoot)…"`，**减去** `Compile Remove="$(UpstreamWpfRoot)…"`（被换掉的上游文件不该算） |
| 2 | **本工程生成物 / 垫片** | 同一份 csproj 里 `Compile Include="$(WpfLinuxRoot)…"` 指到的文件（`*.Linux.cs`、`build/shims/**`） |
| 3 | **决定这些生成物的应用器** | 从 `APPLIERS_EXPLICIT` + 兜底 glob 取全部应用器，**按声明**筛出"提到 `build/<Proj>.Linux/**` 或该工程 csproj"的那些 ⇒ **整脚本 sha** 纳入（脚本 = 声明 + 逻辑） |
| 4 | **port-lib 的输入** | 上游 `<Proj>.csproj` 本体 + `build/port-lib.py` + `build/<Proj>.Linux/reapply-patches.py`（若有） |
**排除**：`build/<Proj>.Linux/{bin,obj}/**`、`.artifacts/**`、以及**指纹文件自己**
（`obj/` 里有构建生成的 `AssemblyInfo` 之类 ⇒ 纳入就会随"构建过一次"自变 ⇒ **恒 yes 的假警报**）。

**指纹算法**：对"逐文件 `sha256` 的**有序**清单"（`"<sha>  <relpath>"` 行，按路径排序）再取 `sha256`，前 16 位。
**路径参与**指纹（重命名 = 变化），与桥那边一致。

### 33.2 写进产物 + 门禁重算（缺文件 ⇒ **无信息，不报绿**）
```
bash build/artifact-src-fp.sh --write    # 写 build/<Proj>.Linux/ARTIFACT-SRC-FP.txt（构建/发布时做）
bash build/artifact-src-fp.sh --check    # 门禁：重算比对；rc=0 ok / 2 stale / 3 noinfo
```
**本轮现场读数**
```
ARTIFACT_SRC_FP proj=PresentationCore      fp=2377e09bbedd2634 n=1369 state=ok
ARTIFACT_SRC_FP proj=WindowsBase           fp=e21a98e9e3b1aaff n=325  state=ok
ARTIFACT_SRC_FP proj=PresentationFramework fp=8985f926169f3473 n=1361 state=ok
```
**请你自己接到波里（一行；`--write` 放在重建之后、`--check` 放在门禁入口）**
```bash
python3 build/artifact-src-fp.py --write || echo "[波] 指纹写失败 ⇒ 记为无信息（不要当绿）"
python3 build/artifact-src-fp.py --check || echo "[波] ARTIFACT_SRC_FP stale/noinfo ⇒ 产物与源不一致（rc=2 stale / rc=3 缺文件）"
```
（我没改 `build/integration-wave.sh`，也没碰 `port-lib.py`。）

### 33.3 牙齿（全实测；**注释那一条不猜，直接测**）
```
--selftest（四极性，exit 0=PASS）：
  FP_SELFTEST proj=WindowsBase fp0=e21a98e9e3b1aaff
  FP_SELFTEST fp1=47ebe93d8fa10c2e（给**上游被编译的源**加一行注释 ⇒ 期望 != fp0）⇒ **变了**
  FP_SELFTEST fp2=e21a98e9e3b1aaff（还原 ⇒ 期望 == fp0）⇒ **逐位回绿**
  FP_SELFTEST fp3=e21a98e9e3b1aaff（只在 obj/ 加 .cs ⇒ 期望 == fp0）⇒ **没变**（obj 真被排除）
  FP_SELFTEST fp4=e21a98e9e3b1aaff（只在 bin/ 加 .cs ⇒ 期望 == fp0）⇒ **没变**
  FP_SELFTEST=PASS（四极性全对）
其它两颗牙（手工）：
  · 只给**应用器脚本** `patch-windowsbase-msgflow.py` 加一行注释（不改逻辑）：
      state=**stale**（记录 e21a98e9e3b1aaff ≠ 重算 4492712227d0b41e）rc=2 ⇒ 还原 ⇒ state=ok
      ⇒ **结论（实测）**：这是**内容**指纹 ⇒ **只加注释也会变**；它是"源身份"而非"语义等价"
  · 把 `build/WindowsBase.Linux/ARTIFACT-SRC-FP.txt` 挪走：state=**noinfo**，**rc=3（不经管道取）** ⇒ 放回 ⇒ state=ok
```
**边界（显式写出，否则就是脚本自己在骗人）**
1. 它**不证明产物能编过**、也**不证明"产物就是这些源编出来的"**（那需要"重建后逐字节可复现"；桥那边有实测支撑，**这三个工程没有**）；
2. **只加注释也会变**（上面实测）⇒ 报 stale 时先看 diff 类型，别把"注释级改动"当成"产物一定不同"；
3. 若给某工程新增了这四类之外的输入（新的 `ProjectReference`、新的 `build/*.props`…），**必须回来加口径** —— 指纹不会自己发现（`--list` 是给人核对的入口）。

**交付 sha**
```
ea06b20c71e961840f16447db6cf78659f9ab927d66689593fc1ae727bac5f41  build/artifact-src-fp.py
8b2a0dc851dd0a3e7a344ffcb5a6c2a8fff07b8e6e13a06d51dc50f79d2e03c3  build/artifact-src-fp.sh（仅包装）
6b9e2227e6577be6273a5a7eccf3a84a2a260f5a09d43fd0207603ea4a637f19  build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt
deac97adba53bbb6d65ad5daf88415aa5a27ab610273d45940fb00fbb3bf8b02  build/WindowsBase.Linux/ARTIFACT-SRC-FP.txt
1396408819a047f7ddc7b9623a7db049d94d6838c9c14ef1569b977f087a2f6d  build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt
```

---

## 34. D-P1 定位（**只读**，T1c）：断点**不在代码链上**，在**读数窗口** —— 附两条独立反证

> 指派（主控 2026-09-14 09:20）：把「`AB` 从编辑器文档出发后**该由谁**写进 `Text` DP / 触发通知」钉到 `file:line`，
> 并说明「为什么没发生」；若根因在别车道只给证据与归属。
> **本轮全程只读**（正逢波 19：未写任何 `patch-*.py` / 生成器 / `build/*.Linux/**` 生成物 / `samples/**`；
> 只读代码 + 只读既有日志 + 只跑应用器的 `--prove`（只读））。
> 读数来源三条：
> ① 主控/T3 那趟桥跑的应用日志 `~/wfp-runs/dp1-native-keep/probe-only.log`（sha256 前 16 = **`b4d4027f16affbeb`**；
> `--only=textbox-edit`；桥 `c66083443200115d` / pc `23567d420f0dbbaa`，09-14 09:17 存档）；
> ② 仓库里**已有**的 `--only=text-dp-min` 趟 `~/wfp-runs/go-dpmin/probe-only.log`（**`bfe935e0730e3437`**，2026-09-13 20:48）；
> ③ 上游源码原文（`upstream/wpf/...`，行号**今天重读**，与我旧记录一致）。

**一行结论**：写路径与上游语义**一致，而且已经走到底**（`TextBox.OnTextContainerChanged` → `SetCurrentDeferredValue(TextProperty, DeferredTextReference)`，
DP 槽 `IsDeferredReference=True`）；**字符串只在读时现算**。「`Text` DP 陈旧 / TextChanged=0」这半句
**在已落盘的任何读数里都没有写后样本** ⇒ **无信息（≠ 陈旧，也 ≠ 回归）**；
而**同一个应用、同一个 runner** 的 `text-dp-min` 趟里有一条**写后读数**：`t2='A' c2=1`（DP 立刻就是新值，`TextChanged` 立刻 +1）。

### 34.1 「谁该写、谁该通知」：上游原文逐条（可核）
| # | 位置（`upstream/wpf/src/Microsoft.DotNet.Wpf/src/…`） | 这一行干什么 |
|---|---|---|
| 1 | `PresentationFramework/…/Primitives/TextBoxBase.cs:1435` | `_textContainer.Changed += new TextContainerChangedEventHandler(OnTextContainerChanged);` ← **订阅点** |
| 2 | `PresentationFramework/…/Documents/TextContainer.cs:375` | `ChangedHandler(this, changes);` ← **Changed 真正 raise 的那一行**（前置：`:357 if (_changeBlockLevel == 0)`） |
| 3 | `PresentationFramework/…/Primitives/TextBoxBase.cs:1348` | `internal virtual void OnTextContainerChanged(object sender, TextContainerChangedEventArgs e)`（早退门 `!HasContentAddedOrRemoved && !HasLocalPropertyValueChange` 在 `:1360` 一带） |
| 4 | `PresentationFramework/…/Primitives/TextBoxBase.cs:1395` | `OnTextChanged(new TextChangedEventArgs(TextChangedEvent, undoAction, …))` ← **`TextChanged` 的 raise** |
| 5 | `PresentationFramework/…/Controls/TextBox.cs:1194` | `internal override void OnTextContainerChanged(...)`（`TextBox` 这一层） |
| 6 | `PresentationFramework/…/Controls/TextBox.cs:1206/1214/1216` | 守卫 `if (!_isInsideTextContentChange)` → `DeferredTextReference dtr = new DeferredTextReference(this.TextContainer);` → **`SetCurrentDeferredValue(TextProperty, dtr);`** ← **"谁写的"就是这一行** |
| 7 | `PresentationFramework/…/Controls/TextBox.cs:1279-1285` | `OnDeferredTextReferenceResolved(dtr, s)`（解析回填 `_newTextValue`，只在解析**已经发生**时有用） |
| 8 | `WindowsBase/…/Windows/DependencyObject.cs:524-530` | `SetCurrentDeferredValue(dp, deferredReference)` ⇒ `SetValueCommon(..., coerceWithDeferredReference: true, coerceWithCurrentValue: true, OperationType.Unknown)` |
| 9 | `PresentationFramework/…/Controls/DeferredTextReference.cs:41-49` | `GetValue(BaseValueSourceInternal) { string s = TextRangeBase.GetTextInternal(_textContainer.Start, _textContainer.End); … }` ← **字符串只在这一刻产生** |
| 10 | `WindowsBase/…/EffectiveValueEntry.cs:320/351` | `GetFlattenedEntry(requests)`：ModifiedValue 分支**保留** `IsDeferredReference = IsDeferredReference`（`:351`） |
| 11 | `WindowsBase/…/DependencyObject.cs:166-170` | `GetValue(dp)` ⇒ `GetValueEntry(..., RequestFlags.FullyResolved)`（枚举 `:3483 FullyResolved = 0x00` ⇒ **不含** `DeferredReferences`/`RawEntry`） |
| 12 | `WindowsBase/…/DependencyObject.cs:295-306` | `GetEffectiveValue`：`:303` 早退条件（请求了 `DeferredReferences|RawEntry` **或** `!IsDeferredReference`）⇒ 我们这一格**两个条件都不成立**，继续往下 |
| 13 | `WindowsBase/…/DependencyObject.cs:339-398` | 有修饰符分支：`:352-357`（`IsCoercedWithCurrentValue && !IsAnimated` ⇒ `reference = modifiedValue.CoercedValue as DeferredReference`）→ **`:375 object value = reference.GetValue(...)`** → `:384 CheckEntryIndex` → `:392 SetCoercedValue(value, …)` → **DP 读出的就是解析后的字符串** |
| 14 | `PresentationFramework/…/Documents/TextRangeBase.cs:649 / 1236+1257` | `GetTextInternal(start, end)`；`TextRange.Text` → `ITextRange.Text` → `GetText(…)` → **同一个 `GetTextInternal`**（`TextRange.cs:1332-1337`） |

⇒ 结论（**回答"该由谁写 / 为什么没发生"**）：**该由 `TextBox.cs:1216` 写一个"延迟引用"**，而**字符串根本不写进 DP**；
所以「DP 里只有 seed 字符串 + 两次 `DeferredTextReference`」**正是上游设计的样子**，**不是缺陷证据**。
写后是否变新，**只能靠"写后再读一次 DP"** 来判 —— 而那一格在当前读数里**不存在**（见 34.4）。

### 34.2 同一趟里链**已经走到底**（原文逐行；行号 = `probe-only.log` 的物理行号）
第一字符 `"A"`（第二字符 `"AB"` 完全同形，行号 `1790/1799/1800/1801/1822/1823/1826/1828/1829`）：
```
1626 Q4d SetSelectedText 返回后（**文档到底变了没有**）len=1 text="A" 选区[0,1]="A"（写的是 "A"）
1635 Q5b 即将 raise Changed：ChangedHandler=有 skipEvents=False changes=1 HasContentAddedOrRemoved=True HasLocalPropertyValueChange=False TextContainer#1222db6
1636 Q5c **Changed 已 raise**（订阅者被调） changes=1 … 容器 len=1 text="A"
1637 Q7a TextBox.OnTextContainerChanged 入口 TextBox#33cafbe _isInsideTextContentChange=False _changeEventNestingCount=0 … （进入时 容器 len=1 text="A"）
1638 W5 **写入口 SetValueCommon** 写入的 value=DeferredTextReference target=TextBox#33cafbe dp.GlobalIndex=432 entryIndex=(该点没有索引)
1639 W5-> 谁写的（前 4 帧） #0 WpfLinuxDpValueTrace.W5WriteEntry @DependencyObject.Linux.cs:545
1640 W5-> 谁写的（前 4 帧） #1 DependencyObject.SetValueCommon @DependencyObject.Linux.cs:1227
1641 W5-> 谁写的（前 4 帧） #2 DependencyObject.SetCurrentDeferredValue @DependencyObject.Linux.cs:1129
1642 W5-> 谁写的（前 4 帧） #3 TextBox.OnTextContainerChanged @TextBox.Linux.cs:1230
1645 W4a SetValueCommon **newEntry.Value = value** … 写入的 value=DeferredTextReference isDeferredReference=True ⇒ newEntry.IsDeferredReference=True
1651 W10 flatten **取值[CoercedValue（IsCoercedWithCurrentValue ⇒ SetCurrentDeferredValue 那一支）]** … ModifiedValue: Base=string(len=7) "seed-文本" Coerced=DeferredTextReference
1657 W6b UpdateEffectiveValue **之后** … 有效值槽.Value=ModifiedValue 有效值槽.IsDeferredReference=True target=TextBox#33cafbe dp.GlobalIndex=432 entryIndex=27
1658 Q7b **已 SetCurrentDeferredValue(TextProperty, DeferredTextReference#3d7e188)** TextBox#33cafbe（此时 容器 len=1 text="A"）
1659 Q7c TextBox.OnTextContainerChanged 出口 resetText=False _changeEventNestingCount=0 … 容器 len=1 text="A"
1660 Q6a TextBoxBase.OnTextContainerChanged 入口 TextBox#33cafbe changes=1 … （进入时 容器 len=1 text="A"）
1661 Q6b 即将 OnTextChanged(...) → RaiseEvent(TextChangedEvent) undoAction=Create changes=1
1662 Q6c TextBoxBase.OnTextContainerChanged 出口 changes=1
1663 Q4f DoTextInput 出口 UndoCloseAction=Commit（Rollback ⇒ 上面写进去的会被撤掉）len=1 text="A"
1664 Q3c TextInputItem.Do() 正常返回 text="A" len=1 text="A"
```
⇒ **订阅点没丢、raise 发生了、`TextBox` 那一层走到了 `SetCurrentDeferredValue`、DP 槽拿到了 deferred 标记、
`TextChanged` 走到了 `RaiseEvent`**。这与 M7b 判定的"**编辑器文档已变（AB, Commit）→ `Text` DP/通知链从未收到**"**第一句相符、第二句未被测到**。

### 34.3 为什么"DP 里没有 AB 字符串"**不能**当缺陷证据
`SetCurrentDeferredValue`（上游 `:1216`）按设计写的就是 `DeferredReference`；`DeferredReference` 里**没有任何缓存**
（`WindowsBase/…/DeferredReference.cs:35` 只有抽象的 `GetValue`；`DeferredMutableDefaultReference` 也是每次现算）
⇒ 只要真读一次 `Text`，`:375 reference.GetValue(...)` 必然用 `_textContainer.Start/End` **当场**取串。
所以判据**只能是"写后读"**：写侧读数（`W5/W4a/W6*/W10`）在结构上**无法**区分"DP 已更新"与"DP 陈旧"。

### 34.4 「20 条采样」的构成与时间窗（**口径锚定**；这是本节最关键的更正）
```
grep -c 'changes=0' probe-only.log                      = 20   ← 被读成"20 条采样"
  ├ WFP_TEXTWATCH ……                                     = 18  （FeatureBlocks.cs:471 `if (_watchLogs++ < 18)`，400ms 间隔）
  └ [feat] textbox-edit …… changes=0                     =  2  （LateVerify 行 + Verify 行）
18 条 WFP_TEXTWATCH 的行号 = 584 … 1412（t=10161 … 17021ms），**最后一条 L1412**
注入首条 [KEY_DIAG]                                       = 1492
第一次 Q4d（文档变成 "A"）                                 = 1626
解引用点探针 Q8a（`DeferredTextReference.GetValue` 入口）  = **0 次**（整趟）
最后一次 W1 GetValue(…) 读 "Text" target=TextBox#33cafbe   = 1405
LateVerify 行（`[feat] … INCONCLUSIVE late`）              = 599
Verify 行（`[feat] … OK`，其中做了 Focus+SelectAll+post 四个优先级探针=723） = 734
```
⇒ **20 条"采样"全部早于注入**（最后一条 L1412 < 首条注入 L1492），且 **LateVerify(L599) 早于 Verify(L734)**：
后者的铁证是 L589 `WFP_DISPATCH_PRIO normal=False input=False background=False contextidle=False` ——
四个探针是在 **L723** 才 `posted` 的，若 LateVerify 晚于 Verify 就不可能全 False；同刻 `focus=False selLen=0`，
而 L866+ 的采样已是 `focused=True sel=0,7`。根因：`samples/WpfFeatureProbe/MainWindow.xaml.cs:77`
`Loaded += (s,e) => Dispatcher.BeginInvoke(DispatcherPriority.ContextIdle, new Action(VerifyAll));`
被 ~10s 的首帧拖到 **Background** 的 6s late 定时器（`:78-83`）之后。
⇒ **本趟里"注入后"这一侧只有像素读数，没有任何 `Text`/`TextChanged` 读数**；`changes=0` 与"`Text` DP 陈旧"
都是**注入前**的行。**无信息 ≠ 陈旧。**

### 34.5 反证①：同一应用、同一 runner 的 `--only=text-dp-min` 趟里**有写后读数**（无 X 注入）
`~/wfp-runs/go-dpmin/probe-only.log`（`bfe935e0730e3437`，2026-09-13 20:48；`WFP_ARTIFACTS … pc_sha=c43d351639856680
pf_sha=e5c6f5a7eeef9b81 bridge_sha=e0d01832a3efea53 win32shim_sha=f84d65a62e0c7fa4`）：
```
[wfp] 模式：blocks=text-dp-min 数量=1 late_ms=6000
WFP_TEXTDP t1='seed-文本' c1=0 sel=''    line0='seed-文本'
WFP_TEXTDP t2='A'         c2=1 sel='A'   line0='A'      ← **写后立刻读 DP：已经是新值**
WFP_TEXTDP t3='A'         c3=1 sel='A'   line0='A'      ← 一个 Background 回合后
WFP_TEXTDP t4='A'         c4=1 sel='A'   line0='A'      ← +500ms
[feat] text-dp-min OK WFP_TEXTDP t4='A' c4=1 …
```
该块的 `Snap()`（`samples/WpfFeatureProbe/FeatureBlocks.cs:750-757`）读的是 **`_tb.Text`（DP 读路径）** + `_changes`（TextChanged 计数）
+ `sel/line0`（容器侧），序列是 `SelectAll(); SelectedText="A";`（`:765`，`TextBox.SelectedText` setter = `TextBox.cs:764-777`
→ `TextSelectionInternal.Text`；与键入路径的 `TextEditor.SetSelectedText`（`TextEditor.cs:431`）同属"经文本对象模型改容器并 raise `Changed`"这一族）
⇒ **"容器改了但 DP 不跟"在同一应用里当场就是 `t2='A'`（绿）**，`TextChanged` 也当场 +1。

### 34.6 反证②：M7b 的 12 例装置（**更新的一批件**，全部"DP 已更新"）
`/tmp/dp1-run6.log`（09-14 09:14，桥 `c66083443200115d` / pc `23567d420f0dbbaa` / PF `bfb10fe2a01a986b`）：
`DP1_a/b/c/d/e/f/g1/g2/h/i` 九个形态 + 底座用例，读数一律 `DP.Text == 容器`（例：`[g1-同帧连发] DP.Text="AB" 容器="AB" TextChanged=2`、
`[d-xdotool真注入] DP.Text="aABseed-文本" 容器="aABseed-文本" TextChanged=3`），`测试总数 12 / 通过数 12`。
⇒ 两个**不同批次**的产物、两条**不同注入方式**、外加一条**零注入**路径，都测到"DP 跟着走"。

### 34.7 判定与归属
- **(甲)/(乙) 都不成立**：既不是"上游本来就这样、我们改口径"，也**不是移植回归** ——
  **"容器变了而 `Text` DP 陈旧"这一现象在所有已落盘、可复核的配置里都没有出现**；出现的是**仪器/时序缺口**。
- **归属（不在我车道，按指派只给证据）**：
  1. `samples/WpfFeatureProbe/MainWindow.xaml.cs:77-83` + `FeatureBlocks.cs:466-475/493-520`（**T3** 车道）：
     `VerifyAll` 的 `ContextIdle` 与 6s late 定时器（Background）**顺序会倒**；`_watchLogs++ < 18` 让采样窗在 ~7.2s 后**永久关闭**（注入在其后）。
  2. runner `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh:720-721`：
     `ch_now/txt_now` 用 `grep … | tail -1` 取 `feat-lines.txt` 的**最后一行**；本趟该行是 **Verify（注入前）**那一行
     ⇒ 再在 `:730-732` 把它当"注入后可观测模型陈旧"的证据 ⇒ **拿注入前的 `changes=`/`text=` 与注入后的像素并排比较**（T1b/T3 车道）。
     `:713-714` 的结论句与 `:705-707`（"瓶颈在托管输入栈 —— M7b 的 F4"）**以此为准应改写**。
- `build/shims/**`、`src/WpfGfx.Linux/**` **无涉**（不需要转车道）。

### 34.8 修法（**我这车道**，等波 19 结束、主控放行后再动写）
1. **写后读回探针**（加进 `patch-presentationframework-textbox-textdp-trace.py`，插在 `TextBox.OnTextContainerChanged` 末尾、
   `base.OnTextContainerChanged(sender, e);` **之后**）：读一次 `this.Text`（**真实读路径**）并打一行机读读数；
   **独立开关 `WPF_LINUX_TEXTDP_READBACK`（缺省关）** —— 它会触发 deferred 解析（`:392 SetCoercedValue` 把槽落成字符串）
   ⇒ **有观测者效应**，因此**不能**挂在现有 `WPF_LINUX_INPUT_TRACE` 下（那批的文档口径是"不读任何 DP"）；独立额度 + 触顶提示（L12）。
   判据：读到 `"AB"` ⇒ **绿**；读到旧值 ⇒ **红**；`(string)GetValue(…)` 抛 `InvalidCastException`（即 DP 返回的不是字符串 ⇒ 引用未解析）⇒ **红**，且异常类型本身定位到"解析没发生"。
2. **判据工具**（`build/MilBridge/tools/t1c-dp1-leg-audit.py`，只读）：扫一趟日志，输出
   `DP1_LEG state=closed|defect|noinfo rc=0|2|3`；**没有"写后读数"一律 `noinfo` rc=3（不许报绿/报红）**；
   `--selftest` 三极性（写后读=新值 ⇒ closed；写后读=旧值 ⇒ defect；只有写侧 ⇒ noinfo）。
3. 两件都在我车道、都只影响我的生成物；**本轮未动手写**。

### 34.9 最省的一步（**不需要我动写**，建议立刻派给 T3，用 #8 冻结件）
- **(i)** `--only=text-dp-min` 重跑一趟（零注入、零代码改动）：期望 `t2='A' c2=1` 复现；若复现 ⇒ D-P1 的 DP 腿当场关闭。
- **(ii)** `--only=textbox-edit` 重跑一趟，让"注入后"这一侧**真的有一条 `Text`/`TextChanged` 读数**：
  三条互不等价的候选（T3 任选，属它的车道）：① `VerifyAll` 不再用 `ContextIdle`（`Loaded` 直接调，或提到 `Input`）；
  ② `TextBoxBlock` 的采样窗上限提高/在 late 阶段再补一行；③ runner 的 `ch_now/txt_now` 改从 **late 行**取，
  并在没有"晚于注入的 late 行"时**一律记为 `无信息`**（不许用注入前的行）。
- **(iii)** 判据：`changes=2` + `text='AB'`（或 `Q8b GetTextInternal 取到 len=2 text="AB"`）⇒ 绿；仍 `changes=0` 且**确有写后读数** ⇒ 才轮到查托管输入栈。

### 34.10 口径教训（本轮新增两条，登记）
- **A. "同一记号"还有第三种歧义：时间点。** 上一轮学的是"同一行里 `0x0102` 有两种含义"，这一轮是
  "**同一个 `changes=`/`text=` 字段，注入前一行、判据按注入后使用**"（`run-wpfprobe.sh:720-721` 的 `tail -1`）。
  ⇒ 计数型/取值型判据除了**锚到唯一形态**，还要**锚到时间点**（"该行写在注入前还是注入后"，必须能机读判定）。
- **B. 写侧形态 ≠ 读侧值。** 上游的 `SetCurrentDeferredValue` 是**按设计的非字符串写**（`:1216` + `DeferredTextReference.cs:43`）
  ⇒ "DP 里没有那个字符串"**永远不能**当缺陷判据；此链上唯一有效判据是**写后读**（我第 4 批的 `Q8a/Q8b` 就在解引用点，
  本趟出现 0 次 ⇒ 该判据**未被触发**，不是"被违反"）。

### 34.11 来源、边界与"需重新冻结"提示
- 本节**没有改任何生成物/应用器/脚本**：`patch-*.py` 最新 mtime 仍为 09-14_00:23:09；我车道 `build/*.Linux/*.Linux.cs` 最新 09-13_21:00:28 ⇒
  §33 的三份 `ARTIFACT-SRC-FP.txt`、§32 的 `APPLIER_AUDIT_SUMMARY` **不受影响，无需重算**。
- 本节读数来自**别人的存档目录**（`~/wfp-runs/**`）与**上游源码**，均为只读；引用的两个日志已给 sha256 前 16 位。
- `go-dpmin` 趟的 pc `c43d351639856680` **在波后已不存在**（父级 22:23 波后我复核过）⇒ 34.5 的读数按
  "**旧件批次**的现场读数"引用，**不要**拿它对波后产物背书；要用当前件请走 34.9(i) 的复跑。
- 本节**不主张**"托管输入栈没问题"，只主张：**本链在写侧已通、读侧未测、且已有两条独立反证**。

### 34.12 交接补遗（给 T3 / 给 runner 所有者；都是**别人车道**，我只给行号与判据）
1. **`--only=text-dp-min` 的读法**：runner 的 `BLOCKS` 白名单（`run-wpfprobe.sh:479`）**不含** `text-dp-min`
   ⇒ 汇总会打 `skipped=10`、也没有像素腿 —— **这不是失败**：读数在**应用日志**里
   （`$OUT/probe-only.log`，`grep -a 'WFP_TEXTDP\|^\[feat\] text-dp-min'`），`go-dpmin` 那趟就是这么读的（34.5）。
2. **同一族 `tail -1`（时间点歧义）还有一处**：`run-wpfprobe.sh:768`（崩溃分诊：`local_v=… feat-lines.txt | tail -1`）
   —— 风险低于 `:720-721`（只决定分诊趟的判定行），但**同族**，改 `:720-721` 时一并看一眼；
   对照：`:604` 的 `tail -1` 前面有 `sort -n`（取的是**最大值**不是最后一行），**不是**同族，不必动。
3. **`:720-732` 的最小改法草案**（T1b/T3 定稿；我只写在这里，**没动该文件**）：
   ① 先算"注入后是否存在 `[feat] … late:` 行"，**存在**才用它的 `changes=`/`text=`；
   ② 若不存在 ⇒ `ch_now=NA` 并把该块的键入腿记 **`INCONCLUSIVE(无注入后读数)`**，
   **不许**回落到 `tail -1` 的注入前行；③ 证据串里把取值来源也打出来（`changes=…@late` / `…@verify`）⇒ 下次一眼看出时间点。
4. **新开关名无冲突**（已核）：`WPF_LINUX_TEXTDP_READBACK` 在仓库里目前**只出现在本报告**（§34.8 设计），
   可安全用作第 34.8 节写后读回探针的开关名。

---

## 35. D-P1「DP 腿」判据审计器（**只吃日志、不产出构建物**）+ 与 T3 `WFP_POSTWRITE` 的等价性判定

> 主控 2026-09-14「放行写，但**先不要动 PF 探针**」⇒ 本轮只交付 §34.8 两件里的**第二件**（判据工具），
> 并回答指派里的问题：**T3 新加的 `WFP_POSTWRITE`（轮询读 `_tb.Text`）是否等价于我要的"写后读回"**。
> **本件不产出任何构建物 ⇒ 不影响任何 sha**（自身 sha 见 35.1）。

### 35.1 交付
```
75a10d05a822387fab4eb024569c65184473a79155e76d7a391faac0ce1d5bd5  build/MilBridge/tools/t1c-dp1-leg-audit.py（359 行；py_compile OK）
```
用法与退出码：
```bash
python3 build/MilBridge/tools/t1c-dp1-leg-audit.py --selftest                     # 7 极性自检（不读真实文件）
python3 build/MilBridge/tools/t1c-dp1-leg-audit.py --log <probe.log> [--log …]    # 判定
# rc: 0=closed / 2=defect / 3=**noinfo（无信息）** / 1=用法或读文件失败
# 机读行：DP1_LEG state=… rc=… write_rows=… reads_after_write=… object=TextBox# dp=432 file=… [hit@L…]
```
**核心规则（写死，不许绕过）**：判「DP 陈旧」**必须**有**写后读数**；
① 若日志里还有注入标记，则"写后读数"还必须**晚于注入**（`--allow-pre-injection` 才能关掉这条，**默认不许**）；
② 没有写后读数 ⇒ **一律 `noinfo rc=3`**（不许报绿，也不许报红）；③ 写侧读数再多也不能替代读侧。

### 35.2 三份真实日志的判定（**原样读数**；都是现成存档日志）
| 日志（sha256 前 16） | 判定 | 依据（脚本自己打印的行号） |
|---|---|---|
| `~/wfp-runs/dp1-native-keep/probe-only.log`（`b4d4027f16affbeb`，D-P1 现场那趟） | **`noinfo` rc=3** | 链上读数齐（`Q5c=3 Q7a=3 Q7b=2 Q6b=3`），但 **`reads_after_write=0`**：最后一条写行 **L1809**、最后一条读行 **L1412**、首条注入 **L1492** ⇒ 「写后没有任何 DP 读数」 |
| `~/wfp-runs/go-dpmin/probe-only.log`（`bfe935e0730e3437`，`--only=text-dp-min`） | **`closed(app-seq)` rc=0** | `WFP_TEXTDP t1='seed-文本' c1=0` → `t2='A' c2=1`（同一步内读 DP，值变 + `TextChanged` 递增）⇒ 链闭合；**口径限制**由脚本自己打在 `DP1_LEG_WHY` 里（背书的是"经文本对象模型改容器"那一族写，不逐字等于键入路径） |
| `~/wfp-runs/go-textbox-dp1b/probe-only.log`（`ee9a7a5471dddcd2`） | **`noinfo` rc=3** | 该趟没开 `INPUT_TRACE/MSGFLOW_TRACE` ⇒ 既无 deferred 写读数也无 `WFP_TEXTDP` 对 ⇒ **不是这条链的日志**（脚本明说，而不是猜） |

### 35.3 牙（三极性；**在真实日志的副本上**做，`/tmp`，未碰仓库）
| 牙 | 造法 | 读数 |
|---|---|---|
| **绿** | 把 T3 新仪器那两行（`WFP_POSTWRITE-EVENT … text='A'` + `WFP_POSTWRITE t=22500 变更 text='AB' len=2 sel=2,0 changes=2`）**追加到现场日志副本**末尾 | `state=closed rc=0`，`hit@L2155`，`DP1_LEG_WHY 写后读到的 DP 值 == 写后容器真值（"AB"）` |
| **红** | 同上但追加 `text='seed-文本'`（旧值） | `state=defect rc=2`，`DP1_LEG_WHY …（"seed-文本"）== **写前**值，而写后容器真值已经变成（"AB"）⇒ **陈旧**` |
| **无信息** | 原日志（不追加） | `state=noinfo rc=3` |
| 自带自检 | `--selftest` | `DP1_LEG_SELFTEST=PASS（7/7）`：closed / defect / defect-ex(`InvalidCastException`) / 只有写侧 / **写后但注入前** / 同一日志加 `--allow-pre-injection` ⇒ 红（证明该开关真的在起作用） / `closed(app-seq)` |

### 35.4 与 T3 `WFP_POSTWRITE` 的**等价性判定**：**等价（成立）⇒ 不必改 PF**
T3 的实现（`samples/WpfFeatureProbe/FeatureBlocks.cs:484-524` + `:436-441`）：
* `:510 text = _tb.Text;` —— **正是** `TextBox.Text` 的 getter ⇒ `TextBox.cs:675 (string)GetValue(TextProperty)` ⇒
  `DependencyObject.GetValue` ⇒ `GetEffectiveValue` ⇒ `DeferredTextReference.GetValue`：**与 §34.8 我要的"写后读回"是同一条读路径**；
* `WFP_POSTWRITE-EVENT`（`:440`）在 **`TextChanged` 处理器内**读 DP ⇒ 时点同步落在 `TextBoxBase.cs:1395 RaiseEvent` 里，
  比我原计划的落点（`base.OnTextContainerChanged` **之后**）**更早、更贴**；
* `:514 catch … Console.WriteLine($"WFP_POSTWRITE t={ms} 读取异常 {ex.GetType().Name}")` ⇒ **正好**是我要的红极性
  （DP 返回的不是字符串 ⇒ `(string)` 抛 `InvalidCastException` ⇒ 引用没被解析）。
**两条必须满足的条件**（否则回到"无信息"）：
1. 读数**必须真的落在写入/注入之后**（本工具按行号自动判：写后 **且** 注入后；不满足 ⇒ `noinfo`）；
2. 取值要与**容器真值**可比 ⇒ 要么同趟里有 `Q4d`（容器侧，键入路径），要么读数行自带 `sel=`/`changes=`（自洽旁证）。
**三条要转给 T3 的注意**（它的车道，我只提）：
1. `StartPostWriteRead()` 目前在 `Build` 里**无条件启动**（无 env 开关）：每 300ms 读一次 DP ⇒ **会把 deferred 槽提前解析成字符串**
   （这正是我在 §34.8 坚持"独立开关 + 缺省关"的原因）。值不变，但**表示形式**被改；建议加 `WFP_POSTWRITE=1` 一类开关，
   只在需要写后读数的趟打开（否则以后排查"惰性解析"类缺陷时，仪器本身会把它掩盖掉）。
2. 轮询额度 `_postLogs>=30`（`:505`）≈ 心跳 2s 一条 ⇒ 约 60s 后自停；`WFP_POSTWRITE-EVENT` 额度 10（`:439`）。
   若注入很晚（本例注入在 t≈17s 之后）仍够用，但**不是无限**；额度用尽与否请照 L12 口径**明确打一行**。
3. 判据仍要锚**时间点**（§34.10-A）：`WFP_POSTWRITE` 在注入**前**也会有若干行（`t=300 变更 text='seed-文本'`），
   **不能**拿它们当"注入后"读数。

### 35.5 给 runner 的结论句改写建议（`run-wpfprobe.sh:705-707` / `:713-714`；T1b/T3 车道，我只给文字）
- `:705-707` 现文：「`changes=0`（注入的键没进 TextBox）… 瓶颈在托管输入栈 —— M7b 的 F4」⇒ 建议改为：
  「`changes=0` 若取自**注入前**的台账行 ⇒ **无信息**（不是"键没进"）；键是否到位另有 `WFP_MSGS WM_CHAR` 与 `KEY_DIAG` 两格；
  本行**不得**单独下"输入栈"结论」。
- `:713-714` 现文：「像素/容器对、而 `Text` DP 陈旧 ⇒ 记 INCONCLUSIVE（缺陷，不是通过）」⇒ 建议改为：
  「像素/容器对，且 `Text` DP **有写后读数且陈旧** ⇒ 记 INCONCLUSIVE（缺陷）；**没有写后读数** ⇒ 记 `INCONCLUSIVE(无信息)`，
  不许写成"陈旧"（判据/工具见 `build/MilBridge/tools/t1c-dp1-leg-audit.py`）」。

### 35.6 边界与对齐
- 本件**只新增一个工具**：不产出构建物、不改 `patch-*.py`、不改生成物、不碰 `samples/**`（T3 车道）与 runner（T1b/T3 车道）
  ⇒ **任何 sha 都不受影响**（§33 三份 `ARTIFACT-SRC-FP.txt`、§32 `APPLIER_AUDIT_SUMMARY` 无需重算）。
- 供后续对齐的**新件**（主控 2026-09-14 波 19 后给）：桥 `759a322431f1e457`（fp `705ed5ccd0c498a1`）、PC `ebf4cf872c76e4a1`、
  PF `3136f66563f858cd`、`libwpfwin32.so b2301ee237e72e5c`、shim `e1bc947afc248b32`。**旧读数不得与新件混用**（§34.5 已标）。
- 本工具**只判这一条腿**（`TextBox.Text` 在容器写之后有没有被读过、读到什么）；它**不判**渲染、也**不判**"托管输入栈"。

---

## 36. 旧债复跑：`InputTraceProbe` 两臂断言（v3 后首次）+ L17 全域扫同族

> 主控 2026-09-14 派：①复跑 `tests/InputTraceProbe` 两臂断言并给逐字输出、判"断言陈旧 vs 真回归"；②照 L17 扫我自己的应用器/探针里还有没有"按注入前的读数下结论"（D-P1 假"陈旧"的同族）。
> **路径更正**：该装置实际在 `build/MilBridge/tests/InputTraceProbe/`（**不是** `tests/InputTraceProbe/`），是个**纯控制台探针**（不起 WPF、不开 X），驱动器 = `build/MilBridge/tools/t1c-inputtrace-verify.py`。
> 本轮**未碰** `src/**`、`build/shims/**`、`samples/**`、别人的 `build/MilBridge/**`；**没跑应用**（`:97` 归 T3）。

### 36.1 复跑命令与逐字读数（修好装置之后；`-m:1`、**未用** `--no-build`）
```bash
python3 build/MilBridge/tools/t1c-inputtrace-verify.py      # 驱动器：①只插入证明 → ②写探针工程并编译 → ③两臂各跑一次
```
```
[① 只插入] HwndSource：摘掉插桩后与上游**逐字节相同** ✓ sha256=16736b57faf2acefb9b10e14…
[① 只插入] HwndKeyboardInputProvider：摘掉插桩后与上游**逐字节相同** ✓ sha256=b394aa2a16b97e1de14aae0f…
[② 探针编译] cmd=dotnet build …/InputTraceProbe.csproj -c Release -m:1 --nologo -v q
[② 探针编译] OK：    0 个错误 /  / 已用时间 00:00:02.36
[③ 被测真件] PC=build/PresentationCore.Linux/bin/Debug/PresentationCore.dll sha16=ebf4cf872c76e4a1 开关=WPF_LINUX_INPUT_TRACE（反射调用；无 WPF 引用、不起 WPF）
[③ 臂 default] rc=0
PROBE arm=default env=<unset> type=System.Windows.Interop.WpfLinuxInputTrace asm=PresentationCore.dll sha16=ebf4cf872c76e4a1
INPUT_TRACE_DEFAULT_ASSERT=PASS enabled=False lines=0 lineCount=0 每入口行数=[PreprocessCharEntry(5)=0 PreprocessCharStep(2)=0 PreprocessCharStep(2)=0 PreprocessCharStep(2)=0 SourceKeyDown(3)=0 SourceKeyDown(3)=0 RestoreCharMessagesCalled(0)=0 ProviderKeyDown(4)=0 ProviderKeyDownReset(2)=0 ProviderChar(4)=0 ProviderChar(4)=0]
[③ 臂 enabled] rc=0
PROBE arm=enabled env=1 type=System.Windows.Interop.WpfLinuxInputTrace asm=PresentationCore.dll sha16=ebf4cf872c76e4a1
INPUT_TRACE_ENABLED_ASSERT=PASS enabled=True linesAfter11Apis=11/11 零行入口数=0 totalLines=201 lineCount=200（有界 ≤200）hasPrefix=True
INPUT_TRACE_ENABLED_PERAPI PreprocessCharEntry(5)=1 … ProviderChar(4)=1        # 11 个入口每个恰好 1 行
---- 原始输出（前 3 行）----
[INPUT_TRACE] PreprocessMessage WM_CHAR 入口(**过焦点门后**) hwnd=0x200005 msg=0x102 wParam=65 _eatCharMessages=True IsInExclusiveMenuMode=False
[INPUT_TRACE] PreprocessMessage WM_CHAR 步骤 TranslateChar ⇒ handled=False
[INPUT_TRACE] PreprocessMessage WM_CHAR 步骤 OnMnemonic ⇒ handled=False
== 自检结论：全部通过 ✅ ==
```
**计数（按主控要的口径）**：两臂 **2 个断言、2 通过、0 失败、0 跳过**（这是控制台探针，不是 xunit 用例集 ⇒ "跳过"无此概念）；构建 **0 错 0 警**；臂 rc 均 = 0。
**顺带一格**：`lineCount=200`（额度满）+ `totalLines=201` ⇒ 多出来的那 1 行正是 **L12 的"预算用尽"提示**（不占额度）⇒ 该提示**实测可见**，不是纸面承诺。

### 36.2 判定：**装置陈旧（不是回归）** —— 三段证据 + 两处装置缺陷（已修）
第一次复跑（未修装置）结果是 **`[② 探针编译] FAIL`**，而**不是**断言失败：
1. **根因**：v3 之后插桩类的方法签名/方法体引用了 PresentationCore 的**内部/受限类型**
   （`…/HwndSource.Linux.cs` 里 `PreprocessEarlyGate(..., IKeyboardInputSink sink)`；另有 `InputReport`、`InputReportEventArgs`）
   ⇒ "把类抽出来独立编"必然 `CS0246`（`IKeyboardInputSink` 在 **WindowsBase**）与 `CS0122`（内部类型不可访问）。
   **这不可能是回归**：同一段文本在 PC 里**编过且实跑执行过** —— 现场日志
   `~/wfp-runs/dp1-native-keep/probe-only.log` 里 `PreprocessMessage WM_CHAR 入口(**过焦点门后**) … wParam=65` / `wParam=66` **各一次**（该签名所在方法被执行）。
2. **装置缺陷 A（藏失败）**：驱动器只打编译输出的**最后 3 行** ⇒ 真正的 `error CS…` 被吞成"1 个错误"，
   于是"编译失败"极易被读成"断言失败"。已改为：打印**所有** error 行（最多 12 行 + 计数）并明写
   **"两个臂都没有跑（装置编译失败，不是断言失败）"**；结论行也加了同一句。
3. **装置缺陷 B（转义）**：模板里的 `Split('\n')` 在 Python 三引号里被解释成**真换行** ⇒ 生成的 C# 报 `CS1010/CS1011/CS1012`（"常量中有换行符"）。已改为 `Split('\\n')`。
4. **修法（我这车道、不碰 PC）**：把"抽出来编"改成 **反射调用真件**：探针 `Assembly.LoadFrom(PresentationCore.dll)`
   → `GetType("System.Windows.Interop.WpfLinuxInputTrace")` → 反射调那 11 个入口、反射读 `Enabled`/`LineCount`；
   探针工程 `EnableDefaultCompileItems=false` 只编 `Program.cs`，**不需要任何 WPF 引用**（抽出的 `.cs` 仅存档、不参与编译）。
   ⇒ 装置反而**更强**：测的是**真件里的那个类型**（不是副本），且输出里带 `asm=PresentationCore.dll sha16=ebf4cf872c76e4a1`（**来源可核**）。
   `InternalsVisibleTo` 那条路**没走**（要改 PC 源码 = 一轮波）。
5. **断言本身没陈旧**：`linesAfter11Apis == 11`、`零行入口数=0`、`≤200`、`hasPrefix` 全部**照旧成立** ⇒ 失效的是装置，不是断言。

### 36.3 L17 全域扫同族（"结论说的对象/时刻 ≠ 读数的对象/时刻"）
扫法：逐条看**会打出去的**插桩行里带推断标记（`⇒`/`**已`/`**没有`/`说明`）的句子，问两件事：这一格的读数**是不是同一时刻、同一对象**。
| # | 位置 | 是不是同族 | 处置 |
|---|---|---|---|
| 1 | `patch-windowsbase-dpvalue-trace.py:422`（生成物 `build/WindowsBase.Linux/DependencyObject.Linux.cs` 内**已出厂**）`W3a … 原因=**A：effectiveEntry.IsDeferredReference == false（写侧没留住 deferred 标记）**` | **是**：从**读侧**一个标志推**写侧**的事实（与 D-P1 同一个病根：结论的对象 ≠ 读数的对象）。真实情况可能是"该值**从来就不是** deferred" | **未动**（改它要重生成 WB ⇒ 一轮波）。**待批**改法：把括号里改成「**本格因此不解析**；写侧到底有没有 deferred，看写侧那行 `W6b 有效值槽.IsDeferredReference=…`」 |
| 2 | `patch-presentationframework-textbox-textdp-trace.py:25/:68/:69/:571` —— 文档头/生成物头里那句「坏的是 `TextBox.Text` 这个 DP（与 `TextChanged`）**一直停在旧值**」经 §34 已证**是注入前的读数**，但该句**随生成物出厂**（`build/PresentationFramework.Linux/TextContainer.Linux.cs` ×2、`TextBox.Linux.cs` ×1） | **是**（结论随时间失效却留在仪器文本里） | **未动**（PF 探针本轮被点名别动）。**待批**改法：改成「**本批只问"Changed 有没有 raise、有没有推到 DP"**；"DP 是否陈旧"须由**写后读数**判（见 §34/§35）」 |
| 3 | `patch-presentationframework-textbox-textdp-trace.py:242` `Q6 **早退门命中**（…）⇒ 不会放 TextChanged` | 否 | 该格就在早退门那一行，后面紧接 `return`；无需改 |
| 4 | `…texteditor-trace.py:209 P6c 已过两道门 ⇒ e.Handled=true`；`:430 Q3b 命中早退 …`；`patch-windowsbase-dpvalue-trace.py:447 W3c … ⇒ 提前返回（不解析）` | 否 | 均**在分枝当场**打，且把实际值一并打出；无需改 |
| 5 | 我自己的 `t1c-dp1-leg-audit.py`（§35） | **是**（旧版用"写后容器值集合"比对 ⇒ "读到**更早一次**编辑的值"会被误判为绿） | **已修**：改成 **as-of**（用"该读**那一刻**之前最后一次容器读数"作真值），并新增极性 `defect-lag-one-edit` ⇒ `--selftest 8/8 PASS` |
| 6 | `t1c-inputtrace-verify.py`（本报告 36.2 的装置缺陷 A） | **是**（L12 的姊妹：**失败被藏起来**） | **已修**（打印全部 error 行 + 明确"两个臂没跑"） |
| 7 | app 侧 `WFP_TEXTWATCH`/`LateVerify` 早于注入、runner `tail -1`（D-P1 本体） | **是** | 已在 §34.7/§35.5 转 T3/T1b（不是我的车道） |

### 36.4 任务 1 的准备（等 T3 的日志路径）
- **工具已按"注入语义变了"加固**：`t1c-dp1-leg-audit.py` 的"容器真值"**一律从容器侧读数（`Q4d/Q5c/Q7a/Q7b`）量出来**，
  **不从注入方式推断**；比对改成 **as-of**（该读那一刻的真值）⇒ Ctrl+A 生效后"插入 vs 替换"只改变**期望值本身**，不改变判据结构。
  新增极性专测主控点名的风险：容器已到 `"AB"` 而写后读拿到更早的 `"A"` ⇒ **判红**（旧版会误判绿）。
- **日志到手后一条命令**：`python3 build/MilBridge/tools/t1c-dp1-leg-audit.py --log <path>` ⇒ `closed` / `defect` / `noinfo`（含 `hit@L…` 与所用行号）。

### 36.5 本轮 sha 与边界
```
434402f4c36719a0  build/MilBridge/tools/t1c-inputtrace-verify.py（驱动装置；含反射版探针模板）
965d8a32d9b31d26  build/MilBridge/tools/t1c-dp1-leg-audit.py（as-of 加固 + 8 极性自检）
9f9ef7d085a0b5ae  build/MilBridge/tests/InputTraceProbe/Program.cs（**生成物**：反射驱动，不参与任何工程编译）
3013e1dd5c9d021d  build/MilBridge/tests/InputTraceProbe/InputTraceProbe.csproj（**生成物**）
96c8f5f9765db8e4  build/MilBridge/tests/InputTraceProbe/WpfLinuxInputTrace.extracted.cs（**存档用，不参与编译**）
```
- 以上**全部落在 `build/MilBridge/**` 我这一侧**（工具 + 自建探针工程）⇒ **不产出任何工程构建物、不影响任何应用器/生成物 sha**；§33 指纹、§32 审计无需重算。
- 两臂测的**真件**：`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` sha16 **`ebf4cf872c76e4a1`**（= 主控给的波 19 新件，现场重算，非转抄）。
- 仍需人工批准才能动的两处（§36.3 第 1、2 行）都是**文本级**改动，一旦批准会改到 WB/PF 生成物 ⇒ **各需一轮波**；本轮**一个字都没动**。

---

## 37. L17 文本级修正（主控 2026-09-14 批准，随 wave 21 合并）：**源已定**

> 批准范围 = §36.3 的第 1、2 行；要求：**只改消息文本 / 不改任何判据与控制流**，并给出"生成物 diff 只有字符串"的证据。
> ✅ **源已定**：两个应用器已改完并**已重生成**对应生成物；`--prove`（只插入）**照旧成立**、`--check` rc=0、家族审计读数未变。
> ❗ **产物需由 wave 21 重建**（WB/PF 的 DLL 与 `ARTIFACT-SRC-FP.txt` 记录要跟着刷新，见 37.5）。

### 37.1 改了什么（5 处，全部是**字符串/注释**，一行代码都没动）
| # | 位置（应用器源） | 旧文 | 新文（要点） |
|---|---|---|---|
| ① | `patch-windowsbase-dpvalue-trace.py:29`（docstring） | 「…IsDeferredReference == false（**写侧没留住 deferred 标记**，看 W4）」 | 「…（**读到的 effectiveEntry 没有 deferred 标志 ⇒ 本格不解析**；⚠️ 这**不**等于"写侧没留住标记" —— 写侧到底有没有写过 deferred，须看**写侧**读数 `W4a`/`W6b`）」 |
| ② | 同上 `:423`（**W3a 运行时会打出去的那一句**） | `"**A：…== false（写侧没留住 deferred 标记）**"` | `"**A：…== false ⇒ 本格不解析**（写侧有没有 deferred 须看写侧那行 W6b 有效值槽.IsDeferredReference=…）"` |
| ③ | `patch-presentationframework-textbox-textdp-trace.py:24-26`（docstring） | 「坏的是 **`TextBox.Text` 这个 DP（以及 `TextChanged`）一直停在旧值**」 | 「**本批只问**：Changed 有没有 raise、有没有推到 DP；⚠️「是否陈旧」**本批不判**（那批 `changes=0`/`'seed-文本'` 经复核是**注入之前**的读数 ⇒ **无信息**）⇒ 须由**写后读数**判（§34/§35）」 |
| ④ | 同上 `:68-70`（`TRACE_CLASS` 头，**会进生成物**） | 同 ③ 的旧句 | 同 ③ 的新句 |
| ⑤ | 同上 `:574-576`（`HEADER`，**会进 4 个生成物的文件头**） | 同 ③ 的旧句 | 同 ③ 的新句 |

### 37.2 证据 A：生成物 diff **只有字符串/注释**（逐文件行数）
```
DependencyObject.Linux.cs        变更 2 行（1 增 1 删）—— 全在 W3a 那个**字符串字面量**里
TextContainer.Linux.cs           变更 12 行 —— 全在**文件头注释块** + **插桩类自带注释头**（不含代码）
TextBoxBase.Linux.cs             变更 5 行  —— 全在**文件头注释块**
TextBox.Linux.cs                 变更 5 行  —— 全在**文件头注释块**
DeferredTextReference.Linux.cs   变更 5 行  —— 全在**文件头注释块**
```
WB 的 diff 原文（示范"改的就是那个字符串"）：
```
-                           : "**A：effectiveEntry.IsDeferredReference == false（写侧没留住 deferred 标记）**")
+                           : "**A：effectiveEntry.IsDeferredReference == false ⇒ 本格不解析**（写侧有没有 deferred 须看写侧那行 W6b 有效值槽.IsDeferredReference=…）")
```

### 37.3 证据 B：「只插入」口径**照旧成立**，且**上游 sha 与改动前完全相同**
```
③ python3 …/patch-windowsbase-dpvalue-trace.py --prove          rc=0
   [① 只插入] 逆序回代后与上游**逐字节相同** ✓ sha256=edeb712d0bc7b433…（== 上游 edeb712d0bc7b433…）
④ python3 …/patch-presentationframework-textbox-textdp-trace.py --prove   rc=0
   TextContainer.Linux.cs         → 上游 ✓ sha256=72af036450302ddc7693a606…
   TextBoxBase.Linux.cs           → 上游 ✓ sha256=f27c058d32ade51e2da057d4…
   TextBox.Linux.cs               → 上游 ✓ sha256=91c52a195870feefd9d761da…
   DeferredTextReference.Linux.cs → 上游 ✓ sha256=317e13afac62cbd417255f18…
   （上面四个 = **直接对上游那四个 .cs 文件重算**的 sha，现场独立复算，一模一样 ⇒ 摘掉插桩后就是上游原文）
```
⇒ 把插桩**摘掉**后仍是上游逐字节原文，**且这些上游 sha 与改动前一字不差** ⇒ 改的**只在插桩文本内部**。
辅证（应用器自带断言，读数与改动前一致）：WB `throw 16==16`、大括号 `598/598`、结构断言 **45/45**；
PF `throw 10==10 / 3==3 / 0==0`、大括号 `276/276 / 223/223 / 5/5`、结构断言 **5/5、4/4、3/3**。
`--check` 两个应用器 **rc=0**（生成物 = 当前应用器输出）；家族审计 `APPLIER_AUDIT_SUMMARY appliers=20 ok=74 miss=0 red=0 rc=0`（**与改动前同一读数**）。

### 37.4 新 sha（旧 → 新）
| 对象 | 旧 | 新 |
|---|---|---|
| `patch-windowsbase-dpvalue-trace.py` | `6a32c4d82eef8457…` | **`1bff235f3d389788d6af6c11…`** |
| `patch-presentationframework-textbox-textdp-trace.py` | `f4dbda6db716ee88…` | **`9206ea83512f6fd58211e67c…`** |
| `build/WindowsBase.Linux/DependencyObject.Linux.cs` | `0a4a7ba5510a0b55` | **`cdd5867fc742ffee`** |
| `build/PresentationFramework.Linux/TextContainer.Linux.cs` | `a01d9367c37b16e3` | **`2859b73dd347fd8b`** |
| `build/PresentationFramework.Linux/TextBoxBase.Linux.cs` | `900390c6c2baa7a1` | **`a371e5b48b40447b`** |
| `build/PresentationFramework.Linux/TextBox.Linux.cs` | `2c2e306e6025932a` | **`6d769e8508f42b40`** |
| `build/PresentationFramework.Linux/DeferredTextReference.Linux.cs` | `1f144da79c6a9071` | **`6d508ccc41d0e07b`** |
（PF 四个文件都变了：那句旧文在 `HEADER` 里 ⇒ 四个生成物的文件头都带它 ⇒ 全部重写。）

### 37.5 wave 21 会看到的状态（**先说清，免得被读成"破了"**）
```
bash build/artifact-src-fp.sh --check
  ARTIFACT_SRC_FP proj=PresentationCore    fp=d6676597c9517ee1 n=1369 state=ok
  ARTIFACT_SRC_FP proj=WindowsBase         fp=e8e18b887b6535bd n=325  state=**stale**（记录 e21a98e9e3b1aaff ≠ 重算 e8e18b887b6535bd）
  ARTIFACT_SRC_FP proj=PresentationFramework fp=80bc2130203ad9a2 n=1361 state=**stale**（记录 8985f926169f3473 ≠ 重算 80bc2130203ad9a2）
  rc=2
```
- **这是设计如此**：应用器脚本 sha 是指纹的输入之一 ⇒ 源一改，重算值必变；**PC `state=ok`（本轮没碰 PC）**。
- wave 21 重建 WB/PF 之后，用 `build/artifact-src-fp.py --write`（或父级的 3.5 步骤）**重新记录**即可回到 `ok`；在此之前任何"stale"读数都**不是**缺陷信号。
- 本轮**未碰** `build/integration-wave.sh`、`build/port-lib.py`，也**未碰** `src/**`（除上述两个应用器）、`build/shims/**`、`samples/**`、别人的 `build/MilBridge/**`；**没跑应用**（`:97` 归 T3）。

---

## 38. 生成物指纹对 **peer（被引产物）** 诚实：两维度 + `kind` 分类（主控 2026-09-14 派）

> 主控查清的**结构级事实**：`PresentationFramework ⇄ ReachFramework` 是**真互引**（真件引用真件，`CycleStub.*` 只用于 bootstrap pass 1）
> ⇒ 该对**在字节上永无不动点**（交替 `PF⇒Reach⇒PF⇒Reach` 得四个不同 sha）；机制 = Roslyn 确定性输出把**被引件字节**纳入输入哈希
> ⇒ **`pf_sha` 每趟波必变**（#4→#8 的 churn 由此而来），且**只覆盖"源"的 `state=ok` 是必要不充分**（源没变、peer 变了 ⇒ 产物照样变）。
> 本件改的是我那份 `build/artifact-src-fp.py`（我的车道）；**不产出任何工程构建物**（唯一例外见 38.3 的故障注入，已字节级还原）。

### 38.1 改了什么（口径 + 机读行**向后兼容**）
1. **新增维度 B（peer）**：把该工程 csproj 里 `$(WpfLinuxRoot)` 指向的**本仓内引用件字节**纳入指纹 ——
   `<Reference><HintPath>$(WpfLinuxRoot)build/…</HintPath>` 与 `<ProjectReference Include="$(WpfLinuxRoot)…csproj">`（后者折算成 `bin/Debug/<X>.dll`）；
   **自指排除**（产物名 == `<proj>.dll` 一律跳过）；XML 注释里的引用**不算**（PC 的 `PresentationCore.csproj:1518` 那条注释里的 `<ProjectReference>` 就是为此）。
   实测纳入数：**PC 7 条 / WB 1 条 / PF 8 条**（PF 含 `ReachFramework.dll` = 环的另一半）。
2. **机读行**：`ARTIFACT_SRC_FP proj=… fp=… n=… peer_fp=… peer_n=… state=… note=…`
   —— `proj/fp/n/state/note` **语义与 token 不变**（父级 3.5/4 步的旧解析不会坏），只**新增** `peer_fp=`/`peer_n=`。
3. **`state=ok` 的新含义写进文件头**：「**源 + 被引产物都没变**」；`stale` **必须给 `kind`**：
   `kind=src`（源维度：上游文本/生成物/应用器/port-lib 输入）/ `kind=peer`（**被引产物**变了 ⇒ 本工程源一字未动但产物同样会变）/
   `kind=src+peer`；peer 变化还会**逐条点名**并给旧→新短 sha（`note=… build/…/X.dll bf20bd9e57290b09→359243210ff35ed7`）。
4. **`noinfo`（rc=3，**不报绿**）三类**：缺本指纹文件 / **缺任一所引产物** / **旧格式记录**（只有 `fp=` 没有 `peer_fp=` ⇒ 无法为 peer 维度背书）。
   —— 第③类正是本轮切换瞬间的真实形态：波 18:16:55 写的三份记录是旧格式 ⇒ 现在 `--check` 报 `noinfo` 并明说"请跑 --write 重记"。
5. 新子命令 `--peers <Proj>`：**可对非被测工程**用（例：`--peers ReachFramework` ⇒ 它的 peer 里就有 PF）。`--list <Proj>` 现在分两段（A 源 / B peer）。
6. `build/artifact-src-fp.sh` 包装脚本的注释同步（两个维度 + kind + 六极性）；**`samples/WpfTextDemo/ARTIFACT-TUPLE-COVERAGE.md` 只加了一段"指针"**（T3 的表，未改任何结论）。

### 38.2 当场读数（三个工程）
```
ARTIFACT_SRC_FP proj=PresentationCore       fp=d6676597c9517ee1 n=1369 peer_fp=c1f4fcef3bf77968 peer_n=7
ARTIFACT_SRC_FP proj=WindowsBase            fp=e8e18b887b6535bd n=325  peer_fp=806512a8ef23435e peer_n=1
ARTIFACT_SRC_FP proj=PresentationFramework  fp=80bc2130203ad9a2 n=1361 peer_fp=80765a9eb86697a9 peer_n=8
（--write 后 --check 三行 state=ok rc=0）
```
**环关系的实锤（与主控给的数字对上）**：`--peers ReachFramework` 里出现
`build/PresentationFramework.Linux/bin/Debug/PresentationFramework.dll = 2dec4286d80159e9`（= 主控观察到的 `pf …→2dec4286…`），
而 PF 的 peer 里 `build/ReachFramework.Linux/bin/Debug/ReachFramework.dll = 1fd4fe8a2ffd20b1`（= 主控观察到的 `reach …→1fd4fe8a…`）；
另 `PresentationCore.dll=6be29475b6aeb34e`、`WindowsBase.dll=e6216fe961a2bfb9` 与主控给的 #8 停止点**逐位相同**。

### 38.3 牙（红→绿；`--selftest` 六极性 + 三颗真实树牙）
**① `--selftest` ⇒ `FP_SELFTEST=PASS`（六极性全对）**
```
FP_SELFTEST fp0=e8e18b887b6535bd
           fp1=c463f1833b0500f0（上游被编译源加一行注释 ⇒ 变）
           fp2=e8e18b887b6535bd（还原 ⇒ 逐位回绿）
           fp3=fp4=fp0（只在 obj/ 、bin/ 加 .cs ⇒ 不变）
FP_SELFTEST_PEER peer1=9c80d34679116ec4（沙箱：1 被引件 + 1 自指件 ⇒ **只纳入 Bar、自指被排除**）
                 peer2=d2ee15c6f98ed9a1（改被引件字节 ⇒ 变）／peer3=peer1（还原 ⇒ 逐位回）
FP_SELFTEST_KIND kinds=['src', 'peer', 'src+peer', None]（期望一致）
```
**② 真实树牙·都不动** ⇒ `--check` 三行 `state=ok` rc=0（38.2）。
**③ 真实树牙·源变**（临时给我自己的 PF 应用器加一行注释，随后按 sha 还原）：
```
state=stale note=kind=src；源记录 80bc2130203ad9a2 ≠ 重算 7c156715007e9ee1（⇒ 本工程需重建）   rc=2
还原后 rc=0；应用器 sha16 回到 9206ea83512f6fd5（= §37 记录值）
```
**④ 真实树牙·peer 变**（**故障注入**：给 PF 的 peer `build/CycleStub.PresentationUI.Linux/bin/Debug/PresentationUI.dll` 追加 1 字节，随后**逐字节还原**）：
```
注入前 bf20bd9e57290b09 → 注入后 359243210ff35ed7
state=stale note=kind=peer；**被引产物变了**（源一个字没动 …）：build/CycleStub.PresentationUI.Linux/bin/Debug/PresentationUI.dll bf20bd9e57290b09→359243210ff35ed7   rc=2
还原后 sha=bf20bd9e57290b09（**与注入前逐位相同**）⇒ --check 三行 state=ok rc=0
```

### 38.4 一处**实测更正**（主控口径"重建被引工程 ⇒ 必 stale"要收窄成"**若重建真的改字节**"）
按单子先试了"**重建 ReachFramework**"这条路，实测**在已一致的树里不会产生新字节**：
```
dotnet build build/ReachFramework.Linux/ReachFramework.Linux.csproj -m:1 --nologo -p:BuildProjectReferences=false
  ⇒ 已成功生成 / 0 警告 / 0 错误 / 1.59s ⇒ reach sha **不变** = 1fd4fe8a2ffd20b1（up-to-date：Reach.dll 18:22:32 晚于 PF.dll 18:22:24）
加 -t:Rebuild（强制重编，6.44s）⇒ **同样 sha** 1fd4fe8a2ffd20b1 ⇒ 该工程输出**按输入字节确定**
```
⇒ 结论：`kind=peer` 的触发条件是"**被引产物的字节与记录不同**"，而**不是**"重建这个动作"。
  在一致树里重建 peer ＝ no-op 或逐字节复现 ⇒ 不会红；**churn 来自按环序重建**（`PF⇒Reach⇒PF…`，每一级拿到的 peer 都变了）
  ⇒ 这正是主控测到"四个不同 sha"的机制，也是本工具现在能**点名**的东西。
  所以牙④ 用**受控故障注入 + 字节级还原**来给出"红→绿"，注入窗口在一次命令内，且**当场验证还原 sha 与注入前逐位相同**（树内容零残留）。

### 38.5 sha 与边界
```
30abca613580cb77  build/artifact-src-fp.py（唯一实现；本次改）
e33f0fb1b83fd1bb  build/artifact-src-fp.sh（仅注释同步）
e70efa828bbe9d68  build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt（新格式，含 7 条 peer）
4b1d3e9e692a210f  build/WindowsBase.Linux/ARTIFACT-SRC-FP.txt（新格式，含 1 条 peer）
496794aad74e92e2  build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt（新格式，含 8 条 peer）
8342a217c1b93b65  samples/WpfTextDemo/ARTIFACT-TUPLE-COVERAGE.md（**只追加了指针段**）
```
- **本轮没有改变任何工程产物的字节**：三颗真实树牙之后逐一比对 sha（Reach `1fd4fe8a2ffd20b1` 未变、`PresentationUI.dll` 还原逐位相同、三个指纹 `--check` rc=0）。
- Reach 的**强制重建**改写了 `build/ReachFramework.Linux/obj|bin` 的**中间件/mtime**，但产物字节确定 ⇒ **冻结元组不受影响**；若父级要绝对干净，可在下一趟波里自然覆盖。
- 未碰 `build/integration-wave.sh`、`build/port-lib.py`、`src/**`、`build/shims/**`；`samples/**` 只加了上面那段指针（未改结论）；**没跑应用**。

---

## 39. `tline` 的 `T3 Collapse` 归因（**进行中**，已到契约层 + 分层；只读）

> 主控 2026-09-14 派：钉 18 条差额是"明细内容错"还是"该问没问" + 契约层 file:line 对照 + 归属 + 判据。**本轮只读**（未跑应用、未改 `src/**`、未改 `build/shims/**`）。

### 39.1 先问"它到底在比什么"（照主控纪律）
`build/MilBridge/tests/HbTextLineParity/Program.cs:433-441`：对**真折叠的 236 行**比 **6 个量** ——
行 `collapsed.Length`、行 `collapsed.Width`（容差 **0.34 DIP**）、`HasCollapsed`、`cr.Count == 1`、
`cr[0].TextSourceCharacterIndex`、`cr[0].Length`、`cr[0].Width`（后者容差同为 0.34）。
⇒ 所以 `判定 1298/1298` **只说明 `HasCollapsed` 一致**（资格闸门那一格），`明细 x/236` 是**其余量里至少一个不等**。
⇒ 也所以：**"折叠明细不符"这五个字本身不是"折叠错了"** —— 若行本体（`Len/W`）就已经和真机不同，折叠只是**症状**。

### 39.2 读数**时效更正**（重要：别再引用"18 条"）
| 来源 | 时刻 | T3 Collapse 读数 |
|---|---|---|
| `~/wfp-runs/tline-wave21final.log` | 09-14 10:01 | 判定 1298/1298；**明细 218/236**（18 条）；空参抛 253/253；空参返回 this 1045/1045 |
| `~/wfp-runs/tline-wave22.log` | 09-14 **18:52** | 判定 1298/1298；**明细 214/236**（**22 条**）；同两条空参子判据不变；`[完整明细] 折叠不符 22 / Extent 68 / 记账 38` |
| `build/MilBridge/gen/tline-detail-full.txt` | 09-14 **19:02:12**（**瞬时版，已作废**） | 文件**自称** `段1 条数 = 26 / 段2 = 101 / 段3 = 53`，共 **186 行** ⇒ **T1d 迭代期间的瞬时版本**（那段时间 harness 被反复重写）**不是当前树的值** |
| `build/MilBridge/gen/tline-detail-full.txt` | 09-14 **19:03:21**（**权威**，文件 sha16 `27860c819f3b7ec2`） | 头两行自证被测件：`# 被测 shim sha256 = 4044D84A66539C429F8F635A33EAB1CEB5D2485ED63D03CA957EAA70D8331B0B`；`段1 = 22 / 段2 = 68 / 段3 = 38` ⇒ **与 #9（18:52）逐项一致** |
⇒ **"18"是 10:01 的旧值；`#9`/当前树上是 `明细 214/236`（22 条）**，以 19:03:21 那份文件的自证 sha（`4044d84a`）为锚（§39.8 的逐条表就是按它落的）。**任何"18 条/哪 18 条"的逐条结论只对 10:01 那棵树成立。**

### 39.3 契约层：上游 ↔ 我们的 `file:line` 对照
| 环节 | 上游（`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/…`） | 我们 |
|---|---|---|
| 抽象契约 | `System/Windows/Media/textformatting/TextLine.cs:59 public abstract TextLine Collapse(…)`、`:67 public abstract IList<TextCollapsedRange> GetTextCollapsedRanges();` | 同（PC 侧照上游） |
| 折叠明细的数据形状 | `System/Windows/Media/textformatting/TextCollapsingProperties.cs:58 internal TextCollapsedRange(…)`；`:73 public int TextSourceCharacterIndex`；`:82 public int Length`；`:91 public double Width` | 同（**三个字段都公开可比** ⇒ 契约层"可比"，不是口径不可比） |
| 真实现（真机） | `MS/internal/TextFormatting/FullTextLine.cs:810 GetTextCollapsedRanges()`；`SimpleTextLine.cs:983`（**不可折叠**那条支路） | **shim**：`build/shims/PresentationCore.HbTextLine.cs` 的 `Collapse(…)` / `GetTextCollapsedRanges()`（真实现；计数器 `collapseCalls=2596 / collapseApplied=236 / collapsedRangesReturned=236` 就在这个文件里）<br>⚠️ **行号会动**：我 19:02 读到的是 `:3079` / `:3181`，而 **T1d 在 19:03:03 改了 shim** ⇒ 19:03:59 重读已是 **`:3011` / `:3113`**（shim sha16 `4044d84a66539c42`）。**引用本行前请现场重读**（"记录会过期"这条对 shim 尤其成立）。 |
| 我们 PC 侧的"不可折叠"支路 | — | `build/PresentationCore.Linux/SimpleTextLine.Linux.cs:641 Collapse(…)` / `:1111 GetTextCollapsedRanges()`，`:1114 Invariant.Assert(!HasCollapsed)` + "A collapsed line is never implemented as simple text line" ⇒ **它按设计不可能产出折叠行** |

### 39.4 归属：**shim（T1d/T1b）**，不是我这条（结论方向）
推论只需一步：**236 条"真折叠"只可能由 `HbTextLine.Collapse` 产生**（PC 侧 `SimpleTextLine.Linux.cs` 按断言不可能折叠）⇒ 明细不符发生在 shim 的裁剪/度量决策里。
`M_modifier_*` 那一簇更靠上游（**行本体 `Len/W` 就先不一致**，如 `M_modifier_winf`：我们 `Len=63 W=218.8960` vs 真值 `Len=63 W=74.0800`）⇒ 根在**断行/修饰符记账**（同一 shim 的 break-engine），折叠只是症状。
**本轮我没动手**（按指派：归属 T1d ⇒ 只给证据与建议，交父级转）。

### 39.5 分层（按 19:02 明细文件；三簇的**修法不同**，别混）
| 簇 | 条数 | 特征（该文件逐行） | 修法归属 |
|---|---|---|---|
| **Tab 家族** `F_tabs_*` | 8 | 行本体 `Len` 就不等（`行W差=8.9773` 恒定）⇒ 与 **T2c 已确认的 Tab 真缺陷**（填宽侧 `ApplyTabStops` 用框架默认、排版侧 `FormatParagraph` 用段落真值）**同源** | T1d 正在修 Tab ⇒ 这 8 条**应随 Tab 修法一起回绿**，不要单独去改折叠 |
| **省略号裁剪/几何** `F_lat_words_w560` + `F_nbsp_zwsp_*` | 11 | 行本体一致（`Len` 等、行 `W` 差 <0.34），折叠明细不等。两小类：**(a) cr 起止一致但 cr 宽差 3.0–6.7 DIP**（`F_nbsp_zwsp_w40#1/w40#3/w80#1`）；**(b) cr 起止差 ±1 字符**（我们 `[30,40)` vs 真值 `[31,39)`、`[13,20)` vs `[14,19)`） | shim 折叠实现（`HbTextLine.cs:3124-3200` 那段：符号宽 + HarfBuzz 簇贪心） |
| **修饰符/断行** `M_modifier_*` | 7 | 行本体 `Len` 或 `W` 先分叉（最大 `行W差=144.8160`） | shim break-engine；**PC 侧 `CollectLenient` 那 2–3 行归我、等 #10 之后**（主控已点名） |

### 39.6 判据（怎么算修好 / 没修好 / 红旗）
- **修好**：`明细 x/236` 的 `x` 回到 236，**且**同一趟的 `[完整明细] 折叠不符 0 条`；`判定 1298/1298`、`空参抛 253/253`、`空参返回 this 1045/1045` 三条**不得回退**。
- **没修好（可接受的中间态）**：Tab 家族 8 条随 Tab 修法消失后，剩下的几何/修饰符两簇**必须逐条给出"差在哪一列"**（本报告 39.5 的表就是模板）。
- **红旗（本族特有）**：
  ① 用"**折叠明细不符**"这五个字当结论 —— 它没说是哪一列不等（39.1）；② 拿 10:01 的 18 条对 18:52/19:02 的树下判断（39.2）；
  ③ 为了让 `x` 变大而**放宽 0.34 DIP 容差**或把 `cr.Count==1` 改成"≥1" —— 那是把仪器调松，不是修好；
  ④ 单独去改折叠实现以掩盖 Tab/修饰符的行本体检修（顺序必须是：**行本体先等于真机，再谈折叠明细**）。

### 39.7 边界
- 本轮**只读**：未跑应用（`:97` 归 T3）、未改 `src/**`/`build/shims/**`/`build/PresentationCore.Linux/**`、未改别人 `build/MilBridge/**`；只读 `~/wfp-runs/**`、`build/MilBridge/gen/**`、`build/shims/**`（读）、上游与本报告。
- **待补**：~~19:02 那趟的日志路径~~ ⇒ **已由父级查清，不需要**（见 §39.8：那份文件自己带"被测件 sha"，19:03:21 版 = `4044d84a`，与 #9 一致）。

### 39.8 **落定表（锚 = 文件头自证 sha `4044D84A…`；`tline-detail-full.txt` 19:03:21 / sha16 `27860c819f3b7ec2`）**
**三簇（按当前树、共 22 条）**：
| 簇 | 条数 | 判据特征 | 归属 |
|---|---|---|---|
| `M_modifier_*` | **7** | **行本体先分叉**（行 `Len` 不等，或行 `W` 差 ≥0.34） | shim break-engine/修饰符记账（PC 侧 `CollectLenient` 那 2–3 行归我，**等 #10**） |
| 省略号几何·**起止一致** | **3** | 行 `Len` 等、行 `W` 差 <0.34；`cr` 起止**相同**、只是 **`cr.Width` 差 −4.16/−6.40/−6.40 DIP** | shim 折叠实现（符号宽/簇度量） |
| 省略号几何·**起止±1** | **5** | 行本体一致；`cr` 起点 ±1、长度 ∓1（`[30,40)`↔`[31,39)`、`[13,20)`↔`[14,19)`） | 同上（裁剪边界决策） |
| **Tab 家族** | **4** | 行 `Len` 不等且 `行W差 = −8.9773` **恒定**（`F_tabs_w40/w80/w120/w200`） | **与 T2c 已确认的 Tab 真缺陷同源** ⇒ 随 T1d 的 Tab 修法回绿（**别单独改折叠**）。<br>⚠️ 本行原写的"10:01 时是 8 条 ⇒ Tab 修法已吃掉 4 条"**已撤回**，理由见 **39.8.1** |
| 行本体已分叉（非 Tab/非 modifier） | **3** | 行 `Len` 等但行 `W` 差 +9.68/+2.62/+8.55（`F_nbsp_zwsp_w80#0`、`w120#1`、`w200#0`） | 度量/断行（同一 schim break-engine） |

**逐条（22 行原文摘要；"我们→真值"）**：
```
F_lat_words_w560  #0 行 70→70 (ΔW +0.0140)  cr 起30→31 长40→39 宽259.2160→259.2133 (Δ-0.0027)  几何·起止±1
F_tabs_w40        #0 行  1→ 9 (ΔW -8.9773)  cr 起 0→ 1 长 1→ 8 宽 -3.6800→ 14.7167 (Δ-18.3967) Tab
F_tabs_w80        #0 行  3→ 9 (ΔW -8.9773)  cr 起 0→ 1 长 3→ 8 宽  6.1600→ 14.7167 (Δ -8.5567) Tab
F_tabs_w120       #0 行  3→ 9 (ΔW -8.9773)  cr 起 0→ 1 长 3→ 8 宽  6.1600→ 14.7167 (Δ -8.5567) Tab
F_tabs_w200       #0 行  6→ 9 (ΔW -0.0013)  cr 起 1→ 1 长 5→ 8 宽  4.8640→ 14.7167 (Δ -9.8527) Tab
F_nbsp_zwsp_w40   #1 行  4→ 4 (ΔW +0.0000)  cr 起 6→ 6 长 3→ 3 宽  4.8640→  9.0233 (Δ -4.1593) 几何·起止一致
F_nbsp_zwsp_w40   #3 行  2→ 2 (ΔW -0.0007)  cr 起14→14 长 2→ 2 宽 -3.0560→  3.3433 (Δ -6.3993) 几何·起止一致
F_nbsp_zwsp_w80   #0 行  9→ 9 (ΔW +9.6807)  cr 起 2→ 1 长 7→ 8 宽 34.1760→ 48.0133 (Δ-13.8373) 行W超差
F_nbsp_zwsp_w80   #1 行  7→ 7 (ΔW +0.0007)  cr 起10→10 长 6→ 6 宽 28.4480→ 34.8467 (Δ -6.3987) 几何·起止一致
F_nbsp_zwsp_w120  #1 行 13→13 (ΔW +2.6233)  cr 起18→17 长 9→10 宽 45.2000→ 54.5400 (Δ -9.3400) 行W超差
F_nbsp_zwsp_w200  #0 行 21→21 (ΔW +8.5460)  cr 起 8→ 7 长13→14 宽 79.1680→ 94.1067 (Δ-14.9387) 行W超差
F_nbsp_zwsp_w320  #0 行 33→33 (ΔW +0.0047)  cr 起13→14 长20→19 宽122.8480→129.5633 (Δ -6.7153) 几何·起止±1
F_nbsp_zwsp_w560  #0 同上（与 w320/w900/winf **四个宽度同值**）                                              几何·起止±1
F_nbsp_zwsp_w900  #0 同上                                                                                  几何·起止±1
F_nbsp_zwsp_winf  #0 同上                                                                                  几何·起止±1
M_modifier_w80    #0 行  6→50 (ΔW-13.9680)  cr 起 1→ 3 长 5→47 宽 20.1760→ 38.9733 (Δ-18.7973) M
M_modifier_w80    #1 行  6→13 (ΔW-14.0140)  cr 起 7→53 长 5→10 宽 20.4160→ 41.6733 (Δ-21.2573) M
M_modifier_w120   #0 行 12→56 (ΔW-18.8633)  cr 起 3→ 6 长 9→50 宽 53.2800→ 61.2267 (Δ -7.9467) M
M_modifier_w120   #1 行 14→ 7 (ΔW+29.0247)  cr 起16→57 长10→ 6 宽 46.5280→ 20.2833 (Δ+26.2447) M
M_modifier_w200   #0 行 26→63 (ΔW+17.7760)  cr 起10→47 长16→16 宽 93.5200→ 82.8367 (Δ+10.6833) M
M_modifier_w320   #0 行 44→63 (ΔW+82.0480)  cr 起19→47 长25→16 宽158.0000→ 82.8367 (Δ+75.1633) M
M_modifier_winf   #0 行 63→63 (ΔW+144.816)  cr 起28→47 长35→16 宽220.2400→ 82.8367 (Δ+137.403) M
```
**结构观察（可直接给 T1d 当线索）**：① `M_modifier_w200/w320/winf` 三条的真值**完全相同**（`cr=[47,16) W=82.8367`、行 `W=74.0800`）⇒ 真机在 modifier 行上**不随约束宽变化**，而我们随约束宽一路变（`93.52→158.0→220.24`）⇒ 像"**modifier 行没进折叠/或约束宽没作用到 modifier 行**"；② `F_nbsp_zwsp_w320/w560/w900/winf` 四条**我们与真值都是同一组数**（`[13,20)` vs `[14,19)`）⇒ 与约束宽无关，纯粹是**裁剪边界取 ±1 字符**；③ Tab 家族 `行W差` 恒定 `−8.9773` ⇒ 与 Tab 度量绑定，不是折叠自身。

### 39.9 两条口径教训（主控点名写进 §39）
1. **读"落盘读数文件"前，先读它自己的"被测件 sha"**：`tline-detail-full.txt` 第 2 行 `# 被测 shim sha256 = …` 就是自证锚（本报告 §39.8 已按 `4044D84A…` 落定）。没有这一行时，**不许**把文件内容当成"当前树"的读数。
2. **迭代期间不要读别人的落盘产物**：T1d 当时正在反复重写 harness，19:02:12 那一版（26/101/53）是**瞬时版本** ⇒ 要么等对方停手，要么**只按文件头 sha** 判定归属；我这一步的教训是"同一路径两次读到的条数不同（26 → 22）"，**先说清拿的是哪一版**再下结论。

### 39.10 交接文本（**给父级转 T1d/T1b**；我不动手）
> **T1c → T1d/T1b（`T3 Collapse` 明细 214/236 的 22 条，锚 = shim `4044D84A…`）**
> 1) **口径先钉住**：harness 比 6 个量（行 `Len`/`Width`(0.34 DIP)、`HasCollapsed`、`cr.Count==1`、`cr[0].TextSourceCharacterIndex`/`Length`/`Width`）；`判定 1298/1298` 只等于 `HasCollapsed` 一致 ⇒ **"折叠明细不符"这五个字不等于"折叠错了"**。
> 2) **22 条分三簇（修法不同，别混）**：`M_modifier_*` 7 条（**行本体先分叉**，真值在 w200/w320/winf 上恒定 `cr=[47,16) W=82.8367`、行 `W=74.08`，而我们随约束宽变化 ⇒ 疑"modifier 行没进折叠/约束宽没生效"）；省略号几何 8 条（3 条起止一致、仅 `cr.Width` 差 −4.16…−6.40；5 条起止 ±1 字符，其中 `w320/w560/w900/winf` 四条我们与真值同组数 ⇒ 纯裁剪边界）；Tab 家族 4 条（`行W差=−8.9773` 恒定 ⇒ 与 Tab 真缺陷同源，**随你的 Tab 修法回绿，别单独改折叠**）；另有 3 条非 Tab 的行 `W` 超差（+9.68/+2.62/+8.55）属度量/断行。
> 3) **实现位置**（**行号随版本移动，引用前现场重读**）：折叠真实现 = `build/shims/PresentationCore.HbTextLine.cs` 的 `Collapse(…)` / `GetTextCollapsedRanges()`（`4044d84a` 上是 **`:3011` / `:3113`**）；其中"符号宽 + HarfBuzz 簇贪心"那段是裁剪边界与 `cr.Width` 的来源（我 19:02 读到的 `:3124-3200` 区段在 `4044d84a` 上亦有偏移，**以现场重读为准**）。PC 侧 `build/PresentationCore.Linux/SimpleTextLine.Linux.cs:1114 Invariant.Assert(!HasCollapsed)` ⇒ 折叠行**不可能**来自 PC 侧（归属 shim 的硬证据）。
> 4) **判据（怎么算修好）**：`明细` 回到 **236/236** 且 `[完整明细] 折叠不符 0`，同时 `判定 1298/1298`、`空参抛 253/253`、`空参返回 this 1045/1045` 不回退。**红旗**：放宽 0.34 DIP 容差、把 `cr.Count==1` 改 ≥1、拿 10:01 那棵树的 18 条对现在的树、**先改折叠去掩盖行本体检修**。
> 5) 逐条 22 行原文（我们→真值、Δ）见 `build/MilBridge/T1c-report.md` §39.8。

### 39.8.1 **撤回**："10:01 是 8 条 ⇒ Tab 修法已吃掉 4 条"（跨树/跨版本，不作归因）
主控要求二选一（立证 / 撤回）⇒ **执行 (b) 撤回**，并把原因钉住（**为什么 (a) 立不了证**）：
1. **10:01 那棵树没有留下"折叠明细的逐行清单"**：10:01 的 `tline-detail-full.txt` 与现在是**同一路径**（已被后续 run 覆盖）。10:01 的日志里**只有条数**（`折叠不符 18 条`、`已写 …（99 行；含 3 段：折叠 18 / Extent 58 / 记账 17）`），**没有**那 18 行的逐行数据。
2. 10:01 日志里确实有一段**用例级**清单（`~/wfp-runs/tline-wave21final.log:128-145` 附近），但它的"原因"是**记账类**（例如 `F_nbsp_zwsp_w40(行#1 期望 Len=4 nl=0 ws=0 | 实得 Len=4 nl=0 ws=1)`），**不是** `折叠明细不符` ⇒ **拿它数 Tab 家族 = 换了口径**，不能当"同一分簇方法"。
3. 我引用的那个"**8**"**根本不是 10:01 那棵树的数**：它出自 **19:02:12 的瞬时文件**（26 行版本，其中 `F_tabs_*` 8 条）—— 那是**同一 era、另一版 harness** 的落盘文件（被测件同为 `4044d84a`，但**测量侧口径被 T1d 改过两次**）。⇒ 我的原句把"另一版 harness 的 8"错挂到"10:01 的树"上，**双重不可比**。
4. 10:01 那棵树**自证 sha 是可查的**（`~/wfp-runs/tline-wave21final.log:3/:43/:51`：`build/shims/PresentationCore.HbTextLine.cs sha256=E1BC947A…`）⇒ 若要**真的**立证，只有一条路：用 `e1bc947a` 的 shim 重跑**同一版** harness（而 harness 已被改过多次 ⇒ 还得回到当时的 harness 版本）—— **成本远大于收益，且属 T3/T1d 的车道**，本轮不做。
**替代表述（可复核、就写这一句）**：
> **当前树（`4044d84a`）Tab 家族 = 4 条**；**与 10:01（`e1bc947a`）的对比未做** —— 跨树 + 跨 harness 版本，差值里混着"版本效应"与"改动效应"，**不作归因**。

### 39.11 「给未来的人」：PC 侧 `CollectLenient` 那 2–3 行的**判据**（等 #10 之后我动手）
`M_modifier_*` 7 条给出的**结构性事实**（§39.8 逐条）：真机在 `M_modifier_w200 / w320 / winf` 上给出**完全相同**的折叠结果 ——
**行 `W = 74.0800`、`cr = [47,16) W = 82.8367`**（与约束宽无关）；
而我们随约束宽**一路变**：行 `W = 93.52 → 158.00 → 220.24`、`cr = [10,16)/[19,25)/[28,35)`。
⇒ 这不像"裁剪算错一个字符"，更像"**约束宽没作用到 modifier 行**"（该行没被当作可折叠处理 / modifier 元素没进折叠路径）。
**改完那 2–3 行（`CollectLenient` 里识别 `TextModifier`）后的验收判据**（写死，别只看"少了几条"）：
1. `M_modifier_w200 / w320 / winf` 三条的折叠结果**必须不再随约束宽变化**，且与真值同为 **行 `W=74.0800`、`cr=[47,16) W=82.8367`**；
2. 同三条在 `明细` 一栏从"不符"变"相符"，且**其余 19 条不得因这次改动而变动**（改前/改后逐条对照 `build/MilBridge/gen/tline-detail-full.txt` 的 段1，**以文件头被测件 sha 为锚**）；
3. `判定 1298/1298`、`空参抛 253/253`、`空参返回 this 1045/1045` 三条子判据不回退。
**红旗**：只把 `M_modifier` 的条数压下去、但"随约束宽变化"这一特征仍在（那说明改的是症状）；或顺手动了折叠实现（那是 shim/T1d 的车道）。

---

## 40. `M_modifier` 那 2–3 行的**只读准备**（PC 侧；等 #11 之后落）

> 主控 2026-09-14 派（当前基线 **#10**：`pc 628e741681ecb048` / `hbtextline 7c2e0107a9c86180`，两者我都**现场实测**过 ✓）。
> 本轮**只读**：未改 `src/**`、`build/**`、`build/shims/**`；未跑应用。

### 40.0 锚（本节的每个数字都挂在这上面）
`build/MilBridge/gen/tline-detail-full.txt`：mtime **19:23:56**，头行 `# 被测 shim sha256 = 7C2E0107A9C8618027D327179269ABEE6D8D329EC1CD89194A412B06B1687274`，
`段1 = 18 / 段2 = 58 / 段3 = 17`。分簇（按 40.3 的同一判据）：**`F_nbsp_zwsp` 10 + `M_modifier` 7 + `F_lat_words` 1 = 18**，**`F_tabs` = 0**。

### 40.1 要改的**确切代码形态**（现状 → 目标；本节只给形态，**先不落**）
**现状**（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:101-157`）：
`CollectLenient` ① 只取**第一个**非 null 的 props（`:129-132`）；② 把**每个 run 的字符平铺**进 `sb`（`:137 ExtractRun` → `:146 sb.Append` → `:156 cp += run.Length`），非 `TextCharacters` 只在 `:148-154` 记一次"放宽"。
⇒ `TextModifier` 的字符**本来就计入**了（所以 `len` 不差），但**没人记它在哪**。
**目标（3 行）**：
```csharp
int modStart = -1, modLen = 0;                                   // ① 两个局部量（默认 -1/0 ⇒ 与今天逐位相同）
...
if (run is TextModifier tm) { modStart = cp - cpFirst; modLen = tm.Length; }   // ② 平铺照旧，只多记一次位置
...
var lines = WpfLinux.Shims.PresentationCore.HbTextLineFactory.FormatParagraph(
    text, fontPath, props.FontRenderingEmSize, paragraphWidth, gt, (float)pixelsPerDip,
    props, alwaysCollapsible, /*hasModifierScope:*/ modStart >= 0, lineHeight, out consumed,
    modifierStart: modStart, modifierLength: modLen);            // ③ 传下去（两个调用点都传）
```
要点（逐条对着主控问的三件事）：
1. **怎么拿到 `modifierStart/End`**：`TextModifier` 是**公开**抽象类（`System.Windows.Media.TextFormatting.TextModifier`）⇒ PC 侧 `run is TextModifier tm` 不需要 friend；`tm.Length` 就是 run 长度。
   区间**必须重基到收集串**：`CollectLenient` 产出的 `text` 从 `cpFirst` 起 ⇒ `modStart = cp - cpFirst`（不是段落的绝对 `cp`）。oracle 用例的绝对区间是 `ModifierStart=6 / ModifierEnd=45`（`LayoutOracle/Cases.cs:302-303`）。
2. **"零宽占位、仍计入 `len`"怎么过接口**：不要在 PC 侧抽掉字符（那会让 `len` 与真机差 39）——**照旧平铺**，只把**区间**传下去；由 shim 在按行排版时把落在该行的部分标成"零宽但计入 `len`/`cr` 索引"。接口语义 = **段落相对** `[modifierStart, modifierStart+modifierLength)`；跨行时由 shim 求交。
3. **保持既有调用零影响**：shim 的 `FormatParagraph`（`build/shims/PresentationCore.HbTextLine.cs:3340-3355`）**已经**用"尾随可选参数"这一惯例（`HbFontPlan plan = null`、`GlyphTypeface[] segmentFaces = null`、`TextRunProperties[] runProps = null`、`double indentDip = 0`、`double defaultIncrementalTab = NaN`、`bool wrap = true`）⇒ 追加 `int modifierStart = -1, int modifierLength = 0` 在末尾，**所有旧调用点逐位不变**；`hasModifierScope` 仍按 `modStart >= 0` 传（今天那条 `TextLineBreak` 语义不变）。
   两个 PC 调用点：`TryFormatLine`（`:238-241`，真正出行的那条）与 `TryMinMaxParagraphWidth`（`:285-288`，只量宽；传了也无副作用）。

### 40.2 验收判据对 **#10** 复核：**真值仍成立、症状仍在**（数字更新）
| 项 | #10 的读数 |
|---|---|
| 真值（三条） | `M_modifier_w200/w320/winf` ⇒ **真值 `Len=63 W=74.0800`、`cr 真值=[47,16) W=82.8367`**（明细文件三行原文，与 §39.8 一致）✓ **判据不用改** |
| 我们的症状 | `Len=26/44/63`、`W=91.8560/156.1280/218.8960`、`cr=[10,16)/[19,25)/[28,35)` ⇒ **仍随约束宽变化** ✓ 要修的就是它 |
| 段1 条数与"其余不动" | **18 条**（不是 22）：`F_nbsp_zwsp 10 + M_modifier 7 + F_lat_words 1`；⇒ **判据 2 的"其余 19 条"应改为"其余 15 条"**（18 − 3 条要修的） |
| Tab 家族 | **0 条**（旧值是"8"/"4"，此处**只用 #10 自己的文件**说事，**不作跨树归因**——同 §39.8.1） |
⇒ **更新后的判据**：① 三条的折叠结果**不再随约束宽变化**且与真值同为 `W=74.0800 / cr=[47,16) W=82.8367`；② 同三条由不符转相符，**其余 15 条逐行不变**（改前/改后对照段1，**锚 = 文件头被测件 sha**）；③ `判定 1298/1298`、`空参抛 253/253`、`空参返回 this 1045/1045` 不回退；④ **加一条**：段2 的 `Extent` 余差条数（#10 = 58）**不得因本次改动而变**（见 40.4）。

### 40.3 要 T1b 传的**那 1 行**（`build/MilBridge/tests/HbTextLineParity/Program.cs`）
现成调用点（**已有** `hasModifier` 形参）：`:325`
```csharp
lines = HbTextLineFactory.FormatParagraph(text, font, em, width, gt, 1.0f, props, ac, hasModifier, lineHeight, out consumed, …);
```
要加的就是**尾部两个具名实参**（oracle 用例里已有 `ModifierStart/ModifierEnd`）：
```csharp
    …, out consumed, modifierStart: spec.ModifierStart, modifierLength: spec.ModifierEnd - spec.ModifierStart);
```
同族调用点（如需一起覆盖）：`:193`、`:638`、`:818`、`:831`（T5.1 的 modifier 专测）。
**签名（T1d 侧，追加尾随可选参数；零影响）**：
```csharp
internal static List<HbTextLine> FormatParagraph(
    string text, string fontPath, double emSize, double paragraphWidthDip, GlyphTypeface glyphTypeface,
    float pixelsPerDip, TextRunProperties runProperties, bool alwaysCollapsible, bool hasModifierScope,
    double lineHeight, out int consumedLength, HbFontPlan plan = null, GlyphTypeface[] segmentFaces = null,
    TextRunProperties[] runProps = null, double indentDip = 0, double defaultIncrementalTab = double.NaN,
    bool wrap = true, int modifierStart = -1, int modifierLength = 0);      // ← 新增的两个（默认 ⇒ 逐位同今天）
```

### 40.4 真机语义判定（主控问的"是不是只有零宽占位 + 计入 len"）：**不止，还有一条**（且有两条"必须不动"）
`layout-b34` 的 `M_modifier` 用例（`LayoutOracle/Cases.cs:288-305` + `TextModel.cs:55-68`）构造的是：`OracleModifier : TextModifier`，`Length = ModifierEnd-ModifierStart = 39`，`ModifyProperties(p) => p`（**恒等**）、`HasDirectionalEmbedding => false`、`FlowDirection = LeftToRight`，覆盖 `[6,45)`、**跨越换行点**。
1. **零宽占位 + 计入 `len`/字符索引** ✓（字符不产生可见宽度，但 `len` 与 `cr` 的索引都按它占位计）；
2. **`TextLineBreak` 非 null（带 `TextModifierScope`）** —— 这才是这一组的**真正目的**（用例注释："验证 TextLineBreak 何时非 null"；上游 `TextMetrics.cs:299-308`：只有末 run 的 `TextModifierScope != null` 且末 run 不是 EOP 时才 `new`；shim 侧对应 `_hasModifierScope` / `s_modifierLines`，harness `T5.1` 专测"无 modifier ⇒ 每行 `GetTextLineBreak()` 为 null"）⇒ **改完必须仍然一致**（`modifierLines` 计数与 `GetTextLineBreak()` 的 null/非 null 分布）；
3. **不改 `Extent`/`Baseline`**：由构造保证（恒等 `ModifyProperties` + 无方向嵌入 + LTR）⇒ 这正是判据 ④ 的由来：**段2 的 `Extent` 余差条数不得变**（#10 = 58）。若改完 `Extent` 变了 ⇒ 说明我们把 modifier 的**字符**当成了"要算宽的字符"，那是错的方向。

### 40.5 边界与状态
- 本轮**只读**：未改 `src/**`/`build/**`/`build/shims/**`/`build/MilBridge/**` 的任何文件（只写本报告）；未跑应用（`:97` 归 T3）。
- 落地顺序：**等 #11 之后**按 40.1 落 PC 侧 3 行（届时先报"源已定"）；40.3 那 1 行由 T1b 在其车道加（两者**必须同波**，否则 `modifierStart` 传不到 shim ⇒ 只改 PC 侧不产生任何效果，别误读成"修法无效"）。

---

## 41. NBSP/ZWSP 族的**机制分解**（只读；锚 = 冻件 #10 的三份 19:23 文件）

> 主控 2026-09-14 派：坐实/推翻"块1 的 30 条是**另一个机制（行 advance/空白推进）**、不是折叠口径"。

### 41.0 锚与**一处 provenance 缺口**（先说清）
| 文件 | mtime | 自带被测件 sha？ |
|---|---|---|
| `build/MilBridge/gen/tline-detail-full.txt` | 19:23:56 | **有**：`# 被测 shim sha256 = 7C2E0107A9C86180…`（段1 18 / 段2 58 / 段3 17） |
| `build/MilBridge/gen/t2d-extent-mismatches.txt` | 19:23:56 | **有**（同一 sha） |
| `build/MilBridge/gen/t2d-width-diff.txt` | 19:23:54 | **没有**（头只有标题/列名/口径）⇒ 只能靠"同趟 mtime"归属 |
⇒ **建议**（T1b/T1d 顺手）：给 `t2d-width-diff.txt` 补一行 `# 被测 shim sha256 = …`，与另两份对齐 —— 这正是我们刚立的"引用读数先看被测件 sha"。本节对它的一切引用都注明"按同趟 mtime 归属"。

### 41.1 机制判定：**推翻"折叠口径"、坐实"行度量（advance/空白）"**
1. **三族在折叠清单里根本不出现**（机读判据 = 段1 的用例前缀计数）：段1 共 18 条 = `F_nbsp 10 + F_lat 1 + M_modifier 7`，其中 **`A1_` = 0、`B_nbsp` = 0**。
   ⇒ `A1_nbsp_zwsp / B_nbsp_zwsp / B_nbsp_zwsp_trim` 与折叠明细**无关**（不是"折叠算错"，也不是"折叠没问"）。
2. 三族都出现在**行度量**两张表里：宽度超差（桶 >0.34）`A1 25 / B 4 / B_trim 1`；Extent 余差 `21 / 4 / 1`。
3. **代码落点（"我们是这么算的"）**：
   - 行宽 = shim 的**逐字形 advance 求和**：`build/shims/PresentationCore.HbTextLine.cs` `:244 r.AdvancesPx[i] = gp.XAdvance * scale`（HarfBuzz `XAdvance`，无符号）→ 求和 `:100 foreach (double a in AdvancesPx) s += a` → 字符级聚合 `:107-113 CharAdvances()`（`adv[c] += AdvancesPx[i]`）。
   - **PC 侧不参与宽度决策**：它只把字符**原样平铺**——`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:81-91 ExtractRun`（逐 `buf[off+i]` 复制，**无归一化**）+ `:110-157` 平铺循环（`:156 cp += run.Length`）。
   ⇒ 可修的一侧只可能在**shim 的度量**（`XAdvance` 的取用/缩放）或**PC 传下去的字符/属性**；**不在折叠实现里**。
4. 真机侧的**机制假设（未在本次核到上游 file:line ⇒ 按纪律标为假设）**：`Extent` 与 `Width` 对**行尾空白**口径不同（NBSP＝非折叠空格、ZWSP＝零宽格式符）。实测形态与之相符：三族 Extent 差**全为负**（我们更小，如 −2.6619 / −1.8104 / −0.6661）⇒ 疑"我们把行尾 NBSP/ZWSP 当行尾空白扣掉了，而真机计入"。
   **定向读数（要什么 / 怎么跑 / 判据）**：对 `A1_nbsp_zwsp_w20 行#7` 与 `B_nbsp_zwsp_trim` 的那条，打一行三元读数 `逐字符 advance | TrailingWhitespaceLength | Extent / Width / WidthIncludingTrailingWhitespace`（harness 旁路一行，T1b 车道）。判据：若 `TrailingWhitespaceLength` 把 ZWSP（或 NBSP）计了而真机没计（或反之）⇒ 机制坐实；若三量自洽而仅 `Extent` 偏小 ⇒ 转查 shim 的 Extent/ink 口径（`Extent` 是墨迹口径，不是 advance 之和）。

### 41.2 `(用例,行#)` 集合代数（**逐键求交**，不用条数相近推）
| 族 | 宽度超差 | Extent 余差 | **交** | 仅宽 | 仅 Extent |
|---|---|---|---|---|---|
| `A1_nbsp_zwsp` | 25 | 21 | **21** | **4** | **0** |
| `B_nbsp_zwsp` | 4 | 4 | **4**（集合**相等**，由键相等得出） | 0 | 0 |
| `B_nbsp_zwsp_trim` | 1 | 1 | **1** | 0 | 0 |
- `A1_nbsp_zwsp` 仅宽的 4 条 = `(w30,行#0)`、`(w30,行#2)`、`(w40,行#1)`、`(w80,行#0)`；**仅 Extent = 0** ⇒ **Extent 集合是宽集合的真子集**。
- 含义（不是"两个机制"）：Extent ⊂ 宽 ⇒ 两个字段**同源**；那 4 条"宽度差而 Extent 不动"是**分辨器**——先修宽度侧，再看 Extent 是否**自动**消失；若宽度修好而 Extent 仍在 ⇒ 才是第二个（Extent 墨迹口径）机制。

### 41.3 回答 T1b 卡住的那一项（"8 条省略号几何"的出处）
- 那张表出自**我的 §39.5**，而 §39.5 的数字来自 **19:02:12 的瞬时文件（26 行版）** ⇒ **不是冻件**，T1b 拿不到一致口径是对的。
- **机读源 = `build/MilBridge/gen/tline-detail-full.txt` 的「段1」**；字段名逐字：`用例 | 行#N | 我们 Len=… W=… | 真值 Len=… W=… | 差 W=… | cr 我们=[起,长) W=… | cr 真值=[起,长) W=…`；**覆盖 = 段1 全量**（#10 = 18 条；**不是** `F_*` 子集）。
- 我在 **#10 段1** 上按同一判据重算（判据：行 `Len` 相等 ∧ `|Δ行W| < 0.34` ⇒ "行本体一致"，否则"行W超差"；再逐个比 `cr` 起/长/宽）：
  **F 家族 11 条 = 起止一致 3 条**（`F_nbsp_zwsp_w40#1`、`w40#3`、`w80#1`）**+ 起止±1 5 条**（`w320/w560/w900/winf#0`、`F_lat_words_w560#0`）**+ 行W超差 3 条**（`F_nbsp_zwsp_w80#0`、`w120#1`、`w200#0`）。
  ⇒ T1b 提到的"**8**"= `3 + 5`（**排除**那 3 条行W超差）；请用**上面这个 #10 口径**的三分类去与块1/块3 按 `(用例,行#)` 求交。

### 41.4 修法预案（**只写不落**）+ 重分类判据
- **分支 A（主预期：真缺陷）**：修 **shim 的度量** —— ZWSP 必须 **零 advance**、NBSP 必须 **等于空格 advance**，行尾空白口径按真机；落点锚 `build/shims/PresentationCore.HbTextLine.cs:231-244`（advance 填充）与 `:100/:107-113`（求和/字符聚合）。PC 侧只在"字符或属性传错"时才动（`:81-91` 无归一化 ⇒ 若发现传下去的字符被替换过，那才是 PC 的锅）。
- **分支 B（判为口径不可比）**：**必须先给不可比的理由**（哪条真机语义在公开契约里取不到，**为什么不是我们能修的那一侧**），并满足三条重分类判据：① 真机三个公开量（`Extent` / `Width` / `WidthIncludingTrailingWhitespace`）之间的关系能复算且与我们的差**方向一致**；② 差异不随内容/约束宽/字体单调变化（是口径而非度量 bug）；③ **同族对照行逐位相等**（如 `A1_lat_words` 现在就是逐位相等）——三条缺一条就**不许**改判为"不可比"。
- **不许当挡箭牌**：**契约不合法**的值一律算缺陷 —— #10 段1 里 `F_nbsp_zwsp_w40|行#3 cr 我们=[14,2) W=-3.0560`（负的折叠区间宽）就是这样一条，**不能用"不可比"解释掉**。

### 41.5 我自己的口径陷阱（登记，第 4 次同族）
扫"负宽"时我先用 `W=-` ⇒ 它同时命中 **`差 W=-13.9680`**（差值）与 **`cr 我们=[…] W=-3.0560`**（区间宽）两种字段 ⇒ 前 3 条 M_modifier 是**假阳**。正确写法要锚到 `cr 我们=[` 之后。**同一族教训（"同一记号两种含义"）第 4 次**。

### 41.6 边界
本轮**只读**：未跑 harness、未重编、未碰 `build/shims/**`、未写 `gen/*`（只读）；本节所有数字**锚在 #10 的三份 19:23 文件**上（`t2d-width-diff.txt` 按同趟 mtime 归属，见 41.0），**跨树不引用**。PC 正为 `D-T1` 重建 ⇒ 需要定向读数时按 41.1 的"要什么/怎么跑/判据"排到 #11 之后。

---

## 42. `#13 M_modifier` **PC 侧设计稿（只读；不落码）** —— 按 U1 的 scope 新语义重写

> 主控 2026-09-14：U1 把 scope 语义定死（**99/99 吻合**）⇒ 我原 `(start,length)` 方案**作废**。本节只给设计 + 判据 + **前置待确认项**；`#13` 未解卡前**不落码**（PC 重建与波由主控发起）。

### 42.1 新语义（照抄 U1 的结论，作为设计的唯一前提）
- `GetTextLineBreak()` 非 null ⟺ **非末行 ∧ 该行结束时 `TextModifier` 作用域仍打开**。
- scope 的开关 = **客户端 run 序列上的两个位置**：`openIndex` = `GetTextRun(i)` 返回 `TextModifier` 的**缓冲/字符下标**；`closeIndex` = 客户端返回**配对 `TextEndOfSegment(1)`** 的下标（`-1` = 从不关闭 ⇒ 到段末）。
- **`TextModifier.Length` 恒为 1**（= 合成边缘字符的长度），**不是** scope 长度（真实覆盖 A=4 / B=30→34 / C=36 字符）。
- 判别式（U1）：`lbNull == !( !isLastLine && ∃m: m.openIndex < nextLineStart ≤ m.endOfSegmentIndex )`。

### 42.2 `CollectLenient`（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:101-157`）要加什么
**现状（已核对，行号未动：该文件 mtime 09-11 23:07:42）**：`:117 if (run is TextEndOfLine) break;`、`:137 s = ExtractRun(run)`、`:146 sb.Append(s)`、`:148 if (!(run is TextCharacters)) ++skipped`、`:156 cp += run.Length`。
**设计（只加"记位置"，不改平铺/`len`口径）**：
```csharp
int modOpen = -1, modClose = -1;                        // 段落相对（收集串）下标；-1 = 无
...
if (run is TextModifier) { modOpen = cp - cpFirst; }    // ① 记"开"：该 run 只占 1 个合成字符 ⇒ **绝不当 scope 长**
if (modOpen >= 0 && modClose < 0 && run is TextEndOfSegment) { modClose = cp - cpFirst; }   // ② 记"关"（见 42.3 待确认）
... // 平铺、skipped 记账、cp += run.Length 一律照旧
```
- **索引空间**：两个位置都**重基到收集串**（`cp - cpFirst`），与 `HbLineRange` 同一空间；`TextModifier.Length` **不参与**任何计算（它恒为 1，只说明 marker 自己占 1 个字符）。
- **配对方式（R1，待确认）**：`TextEndOfSegment` 在**公开面**上只有 `public TextEndOfSegment(int length)` / `Length` / `CharacterBufferReference` / `Properties`（上游 `System/Windows/Media/textformatting/TextEndOfSegment.cs:19/29/42/51/60`），**没有段号可读** ⇒ PC 侧**无法**按"段号 1"判配对。R1 = "`TextModifier` 之后的**第一个** `TextEndOfSegment` 即配对者"（多 scope 时逐 scope 重复）。若语料里同一段会出现多个 `TextEndOfSegment` ⇒ 见 42.3 的待确认项，此时 PC 侧公开面判不了，需 U1/T1b 给一个**公开可判**的判别式。
- **不改的东西**：平铺（`:137/:146`）、`skipped` 记账（`:148-154`）、`cp += run.Length`（`:156`）、`props` 取第一个非 null（`:129-132`）——现状 `len=63` 已与真值相符，**不要**为了 scope 去抽字符。

### 42.3 传给 shim 的形态（尾随可选参数；零影响）
```csharp
internal static List<HbTextLine> FormatParagraph(…, bool wrap = true,
        int modifierOpenIndex = -1, int modifierCloseIndex = -1);   // 追加在末尾
```
- 默认 `-1/-1` ⇒ **与今天逐位相同**（沿用该文件既有的 `plan = null`/`runProps = null`/`wrap = true` 惯例）。两个 PC 调用点都要传：`TryFormatLine`（`:238-241`）与 `TryMinMaxParagraphWidth`（`:285-288`，量宽用；传了无副作用）。
- **shim 侧契约（T1d 的那一半）**：拿到 `(openIndex, closeIndex)` 后，① 落在 `(openIndex, closeIndex)` 里的**字符** `adv[]` 置零（喂填宽 + `GlyphRun.AdvanceWidths`），但 `len/nl/ws/dep` **照旧**来自字符区间（真值 `len=63`）；② `lbNull` 只用判别式 `!( !isLastLine && openIndex >= 0 && nextLineStart <= closeIndex )`（`closeIndex = -1` ⇒ 视为"到段末"）。

### 42.4 判据（我交付时按这个写；主控给的 4 条，逐条保留）
1. **同波、同仪器 A/B**：不传 vs 显式传默认值 ⇒ `tline` 六项 + 三套 oracle + 三份明细 **逐位相同**（`diff` 空）。
2. **`Extent`/`Baseline` 绝不能动**：段2 余差 **58** 不得变；**必须与 #13 同仪器取数**（跨版本无意义）。
3. `M_modifier_*` 那 7 行宽度从 `91.856/156.128/218.896` 收敛到真值 **`74.0800`**（`cr=[47,16) W=82.8367`）。
4. **`TextLineBreak` 只用 null/非 null 这一位**；`_cp/_modifier/_parentScope` 是**非公开反射**读到的，**不许进判据**。

### 42.5 前置待确认项（**卡在这里，未解不落码**；主控已派 T1b）
1. **配对的可判定性**：语料里同一段会不会出现**多个** `TextEndOfSegment`？若有 ⇒ PC 侧公开面无法判"配对者"，需要 U1/T1b 给公开判别式（这是 42.2 的 R1/R2 分岔）。
2. **`TextEndOfSegment.Length` 的实际值**（0 还是 1？）—— 它决定 `closeIndex` 本身是否已经等于"scope 之后第一个字符"的下标；设计里我一律取 **run 起点**下标，所以不受影响，但**判据 3 的对齐会受影响** ⇒ 请顺带给出实际值。
3. **T1b 那两条核实**：(i) 45 处到底发没发 `TextEndOfSegment`；(ii) 我们的 `lbNull` 是否就是 `TextLineBreak == null`。—— 若 (i) 为"没发"且真值 `lbNull=false` ⇒ 与 U1 新规则冲突，得先解这个矛盾（**不是**先改代码）。

### 42.6 边界
本轮**只读**：未写 `src/**`/`build/**`（含 `TextFormatterImp.Linux.cs`）；`#12` 冻结件（`pc 293f99525f5af4f2`、`hbtextline 3081d088cda0431c`）未动；live 仪器 `HbTextLineParity/Program.cs 6e077361609f02ad` / `CoverageProbe/Program.cs cc61299d6dc72277` 只读引用。落码时先报"源已定"，并**与 T1b 那 1 行、T1d 的 shim 半同波**。

### 42.7 主控裁定与我的自查补齐（2026-09-14 晚；仍**只读**）
**① 配对：取 R1，但记为「未验证的选择」（不是"真机如此"）**
- 采纳 **R1 = `TextModifier` 之后**第一个** `TextEndOfSegment` 即配对者**；依据 = U1 的 53 例里每个 scope **恰好一个** close（`A`=4、`B`=34、`C/C2/E`=−1），**真值没有"同段多 close"的样本**；且公开面确实读不到段号。
- **登记边界**（写死）：**"若某客户端在同一段里发多个 `TextEndOfSegment`，R1 可能配错 ⇒ 需要公开可判的判别式；本仓今天没有这种真值。"**
- **落码时的退化行为**（随 R1 一起写进注释/断言）：找不到 `TextEndOfSegment` ⇒ `closeIndex = -1` ⇒ scope 到段末 —— 与本仓 b34 语料一致。

**② `TextEndOfSegment.Length` 的实际值（自查结果；父级说得对，仓里可定）**
- `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/textformatting/TextEndOfSegment.cs:29`：`public TextEndOfSegment(int length)`，紧随 `:31 ArgumentOutOfRangeException.ThrowIfNegativeOrZero(length);`、`:33 _length = length;`；`:51 public sealed override int Length { get { return _length; } }`。
  ⇒ **`Length` 由客户端给，且构造期强制 ≥ 1（不可能为 0）**；**没有任何"恒为 1"的保证**（1 只是 U1 在 `TextModifier` 上测到的值）。
- 另一条自查（纠正"框架自己也在用"这个假设）：`grep -rn 'new TextEndOfSegment' PresentationCore --include=*.cs`（排除 `/ref/`）⇒ **0 命中**；`elementEdgeCharacterLength` 在本仓 PresentationCore 内**也 0 命中** ⇒ 该类型的构造点在**客户端**（我们的 harness/语料即客户端），不在框架侧。
- **对设计的含义**：`closeIndex` 唯一稳的定义是 **close run 的起点下标**（我的设计就是这样），"scope 之后第一个字符"= `closeIndex + Length` ⇒ 两者相差 `Length ≥ 1`，**不许假设为 1**。**判据 3（7 行宽度收敛）的对齐要按语料实测 `Length` 写**；等 U1 的单样本三点夹逼结论（它会同时钉死"零宽跨度**是否含**关闭标记"）再定稿。

**③ 父级已答的两条（记录在案，替换我 §42.5 的待确认项）**
- 我们 b34 语料 **从不发 `TextEndOfSegment`**（父级 `grep -rn "TextEndOfSegment" tests/parity/windows/layout-b34/src/` ⇒ **0 命中**，而 `TextModifier` 有命中）⇒ 走 **`close=-1`（到段末）** 分支，与 U1 规则**不冲突**；语料 note 里的 `[6,45)` 只是作者意图描述。**故我原先担心的"先解矛盾"情形不存在。**
- 我们的 `lbNull` = **`TextLineBreak == null`**（行级）：`extract-layout-b34.py:108` + `analyze-layout-b34.py:181-183` ✓。
- 仍待 T1b 的一处：`TextModel.cs:80+` 的 `GetTextRun` 是否**间接**关闭 scope（结论到了再定稿）。

**④ 放行条件与前置检查（照抄主控）**
- `#12` 已冻结、T3 独立复取已完成（两档 3/3、6/6 `result=PASS`）。
- ⚠️ **本机与另一工程共享 CPU**（`wpf2web` 22:0x 起多个构建、`loadavg` 一度 **6.62`）⇒ **落码/取数前先 `uptime` 并确认无外来重负载**（`D-R2` 的假红很可能与外部负载相关）。
- 放行 = **U1 的单样本结论** + **T1b 那处间接关闭核实** ⇒ 主控发起 **`#13` 同波**（我两处调用点 + T1b 1 行 + T1d shim 半；**PC 重建由主控发起**）。在那之前**只读**。

---

## 43. `ARTIFACT-SRC-FP.txt` 加**逐文件行**（只读设计；落码等 `#13` 之后统一排）

### 43.0 缺口（父级两条证据，我复核过）
`grep -c HbTextLine build/{PresentationCore,WindowsBase,PresentationFramework}.Linux/ARTIFACT-SRC-FP.txt` ⇒ **三份都是 0**（现场复核 ✓）⇒ "**PC 到底编的是哪一份 shim**"今天**答不了**；于是 `hbtextline_shim_stale` 只能靠 **mtime 代理**，今晚两个方向都被它骗过（同内容重写 ⇒ 假报警；`cp -p` 保 mtime ⇒ 假红）。

### 43.1 形态与落点（`build/artifact-src-fp.py` 的 `do_write()`）
现在写的是：头 6 行注释 + `fp=` / `n=` / `peer_fp=` / `peer_n=` / `tool_sha256=` + 一段 `peer=<sha16>  <rel>`。
**落点 = `peer=` 段之后**，新增一段（**与 `peer=` 同布局**，便于同一套 reader 复用）：
```
# 逐文件（**源侧**）：sha256 前 16 + 仓库相对路径；只列**本仓自有输入**（上游 1335/302/1343 条不列，见 43.2）
file=3f2a…c9  build/shims/PresentationCore.HbTextLine.cs
file=…        build/PresentationCore.Linux/TextFormatterImp.Linux.cs
```
**为什么选这个形态**：① 前缀 `file=` 与既有 `fp=`/`n=`/`peer_fp=`/`peer_n=`/`peer=`/`tool_sha256=` **互不为前缀** ⇒ 任何按 `^key=` 解析的消费者读不到它、更不会读错；② 列布局与 `peer=` 一致（读者只需把 `peer=` 换成 `file=`）；③ **控制台机读行 `ARTIFACT_SRC_FP … state=… note=…` 一个字都不动**（`state=ok/stale/kind=` 语义不变）。

### 43.2 覆盖与取舍（现场数出来的条数）
用工具自己的 `manifest()` 数：**本仓自有输入 = PC 34 / WB 23 / PF 18 条**（其余 1335/302/1343 全是 `upstream/**`）。
⇒ **建议逐文件段覆盖"全部本仓自有输入"**（每份 +18~34 行，文件只涨 ~2–3%），`build/shims/**` 只要在 manifest 里就**自动包含**（`PresentationCore.HbTextLine.cs` 就在 PC 那 34 条里，现场可核）。
**不逐条列 upstream**：会把文件吹到 ~150KB 且**没有新信息**（`fp=` 已覆盖它们的聚合）；真要逐条看，已有 `--list <Proj>`。
**T1b2 头行可直接用的一行**（把 mtime 代理换成内容比对）：
```bash
rec=$(awk '/^file=[0-9a-f]{16}  build\/shims\/PresentationCore\.HbTextLine\.cs$/{sub("file=","",$1);print $1}' build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt)
cur=$(sha256sum build/shims/PresentationCore.HbTextLine.cs | cut -c1-16)
[ "$rec" = "$cur" ] && echo "hbtextline_shim_stale=no basis=content" || echo "hbtextline_shim_stale=yes basis=content rec=$rec cur=$cur"
```

### 43.3 消费者清单（逐个 grep，证明"加行不改语义"）
| 消费者 | 命中 | 它读什么 |
|---|---|---|
| `build/close-wave.sh` | `:149 python3 build/artifact-src-fp.py --check >>"$LOG"` | **只取 rc**（0/2/3）⇒ 不受影响 |
| `build/integration-wave.sh` | `:410 python3 build/artifact-src-fp.py --write` | 只**写**，不解析文件内容 ⇒ 不受影响 |
| `tests/…/run-wpftextdemo.sh` | `:668 WPTD_ARTIFACTS … hbtextline_shim_sha=… hbtextline_shim_stale=… hbtextline_stale_basis=… mtime` ／ `:702 WPTD_ARTIFACTS_EXT` | 自己 `sha256sum` + **mtime 代理**，**不读 FP 文件** ⇒ 不受影响（且 43.2 那一行正是它的升级路径） |
| `tests/…/run-wpfprobe.sh` | `:283`（注释：字段名/顺序与 `WPTD_ARTIFACTS` 逐字段一致） | 同上，不读 FP 文件 ⇒ 不受影响 |
| 我自己的工具 | `--check` 里只读 `fp=` / `peer_fp=` / `peer=` | `file=` 不参与 `state` 计算 ⇒ 语义不变 |

### 43.4 判据与牙（落码后按此跑；**给命令与预期输出**）
1. **`--selftest` 仍过**：`python3 build/artifact-src-fp.py --selftest` ⇒ `FP_SELFTEST=PASS（六极性全对…）`，`rc=0`（新段不参与指纹）。
2. **`state=ok` 判定逐字不变**：落码前 `cp build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt /tmp/fp.before`；落码 + `--write` 后 `python3 build/artifact-src-fp.py --check` ⇒ 三行 `state=ok` `rc=0`，且 `fp=`/`n=`/`peer_fp=`/`peer_n=` 与 `/tmp/fp.before` **逐字相同**（`diff <(grep -E '^(fp|n|peer_fp|peer_n)=' /tmp/fp.before) <(grep -E '^(fp|n|peer_fp|peer_n)=' …)` ⇒ 空）。
3. **新能力的两极化牙**（⚠️ 改的是 `build/shims/**` = **T1d 车道** ⇒ 由主控安排，我不动）：
   - ① 给 `build/shims/PresentationCore.HbTextLine.cs` **加一行注释** ⇒ `--write` 后 `file=` 行的 sha16 **≠** 现源 `sha256sum | cut -c1-16`，且 `--check` 报 `state=stale kind=src`；
   - ② 还原 ⇒ 两者**相同**、`--check` 回 `state=ok`。
   预期输出形如：`hbtextline_shim_stale=yes basis=content rec=aaaaaaaaaaaaaaaa cur=bbbbbbbbbbbbbbbb` → 还原后 `… =no basis=content`。

### 43.5 诚实边界（**必须写死，免得下一个人当"产物内 sha"用**）
`file=` 只记**源的样子**（`--write` 那一刻该文件的 sha256 前 16），**不证明产物里真的编进了它**。要做到"**产物内 sha**"还缺（都属 **build 侧**，T1d/port-lib，本设计不承诺）：
1. **构建时把内容哈希写进产物**：例如让 port-lib/构建侧把一个由 `build/shims/PresentationCore.HbTextLine.cs` 内容算出的常量生成进 shim（现有 `Tag = "T1b/B2 · 2026-09-11 · …"` 就是这个位置的雏形）⇒ 之后可从 DLL 元数据/`strings` 直接读；
2. 或读 **PDB 的编译单元哈希 / SourceLink**（能证明"这个源参与了那次编译"）；
3. 或对产物做**元数据取证**（现有 `Tag` 字符串只能证明"某版本 shim 的字面量在里面"，**不含内容哈希**）。
⇒ 一句话：**本设计把"mtime 代理"升级成"源内容比对"，但仍是"源侧"证据；"产物侧证据"要等 1/2/3 里的一条落地。**

### 43.6 边界
本轮**只读** + 只写本报告：未改 `build/artifact-src-fp.py`、未碰 `build/shims/**`/`samples/**`/`docs/**`/`handoff.md`；**未跑波、未跑重负载**（现场 `uptime` loadavg ≈ 6.7，外部工程在跑）。
> ⚠️ 本节"未改 `build/artifact-src-fp.py`"的状态**已被 §45 打破**（§43 的设计已落码）—— 按"记录会过期"纪律就地标注。

---

## 44. `#13` 我这一半**已落**（PC 侧）——**源已定**

### 44.1 交付与 sha
```
build/PresentationCore.Linux/TextFormatterImp.Linux.cs     569fefc718340086 → 5dedc21f5f372c78（主控已确认进了 pc d7a848dfeedcf29b）
属主应用器 src/…/tools/patch-presentationcore-textline-fallback.py → 02a483e0feeee2f7
备份（两份原件，按父级要求放 $HOME、不放 /tmp）：$HOME/t1c-13-backup-221419/
```
**改的是应用器**（`TextFormatterImp.Linux.cs` 是它生成的；直接改生成物会被重放抹掉），随后**重生成**（`=== 退出码 0 ===`、`大括号平衡 {=116 }=116`、上游 776 行 → 生成物 1128 行、+352 行均为既有插桩）。

### 44.2 diff 行数断言（对照备份，逐行已核）：**新增 23 行 / 删除 6 行**
1. `CollectLenient` 签名加 `out int modifierOpenIndex, out int modifierCloseIndex`；
2. 顶部 `modifierOpenIndex = -1; modifierCloseIndex = -1;` + **R1 注释块**（未验证的选择 / 同段多 close 的边界 / 退化行为 `-1`⇒到段末 / `TextEndOfSegment.Length ≥ 1` ⇒ closeIndex = **close run 起点下标**）；
3. 循环里**平铺之外**多记两行：`if (run is TextModifier) { modifierOpenIndex = cp - cpFirst; }` 与 `if (modifierOpenIndex >= 0 && modifierCloseIndex < 0 && run is TextEndOfSegment) { modifierCloseIndex = cp - cpFirst; }`；
4. 两个调用点各加 `int modOpen/modClose`（②为 `…2`）+ 给 `FormatParagraph(…)` 追加 `modifierOpenIndex:` / `modifierCloseIndex:`。
**未动（逐字保留）**：平铺、`skipped` 记账、`cp += run.Length`、`props` 取第一个非 null、两方法其余控制流。生成物 `grep -c modifierOpenIndex` = **6**。

### 44.3 编译依赖（本波联合；我没编译、也没发波）
两个具名实参指向 **shim 侧尚未存在**的参数 ⇒ 单独编 PC 会 CS1739 —— 预期内：本波 = **我（PC 两处）+ T1b2（harness 传两下标）+ T1d（`FormatParagraph` 尾随可选参数）**；PC 重建由主控发起。

### 44.4 wave 判据（照主控 4 条）
① 同仪器 A/B（不传 vs 显式 `(-1,-1)`）⇒ 六项 + 三套 oracle + 三份明细**逐位相同**，两侧各记**被测 DLL sha + 仪器 sha 跑前/跑后**；② `Extent`/`Baseline` 不动（段2 余差 **58**，同仪器）；③ `M_modifier_*` 7 行宽度收敛到 **`74.0800`** / `cr=[47,16) W=82.8367`；④ **`len` 仍含 39 字符**（真值 63）。收尾再跑 `--check` + `applier-audit`。

---

## 45. §43 落码：`ARTIFACT-SRC-FP.txt` 的**逐文件段**（已落 + 判据读数）

### 45.1 落点与 diff 断言
- `build/artifact-src-fp.py`：在 **`do_write()` 的 `peer=` 循环之后**插入一段（12 行说明注释 + 1 行表头注释 + `for rel,sha in d["entries"]: if not rel.startswith("upstream/"): f.write("file=%s  %s\n" …)`）。
- **新增 16 行 / 删除 0 行**（纯插入）；工具 sha16 **`30abca613580cb77…` → `687ff7dabe87fda4…`**（旧值取自 `$HOME/t1c-43-before/ARTIFACT-SRC-FP.txt` 记录的 `tool_sha256=`，新值现场）。
- `build/artifact-src-fp.sh` **未改**（其注释已涵盖两维度/kind，`file=` 不改用法）。

### 45.2 判据读数（①② 实测；③ 待口令）
**① `--selftest`** ⇒ `FP_SELFTEST=PASS（六极性全对…）`，`rc=0`。
**② 落码前后 `--check` 语义逐字不变**：
```
diff <(grep -E '^(fp|n|peer_fp|peer_n)=' build/<P>.Linux/ARTIFACT-SRC-FP.txt) $HOME/t1c-43-before/<P>.keys
  ⇒ PresentationCore=空  WindowsBase=空  PresentationFramework=空
--check ⇒ 三行 state=ok，rc=0（PC d9b7cac83d3c2016/1369/c1f4fcef3bf77968/7、WB e8e18b887b6535bd/325/806512a8ef23435e/1、PF 80bc2130203ad9a2/1361/10cc527231b25c47/8）
```
**`file=` 段真实样例（前三行）+ 覆盖数**：
```
file=d2e034e81ce265bc  build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs
file=19a42240f59af073  build/PresentationCore.Linux/FamilyCollection.Linux.cs
file=b7a5621f00aad1cd  build/PresentationCore.Linux/FontCacheUtil.Linux.cs
PC 34 行（**含 `build/shims/PresentationCore.HbTextLine.cs`，命中 1**）／WB 23 行／PF 18 行
文件行数：PC 55、WB 38、PF 40（PF 改前副本里 `file=` 命中 0 ⇒ 段是新的）
```
**③ 新能力两极化（待主控给 shim 窗口）**：`cp -p` 备份 shim 到 `$HOME` ⇒ 加一行注释 ⇒ 期望 `file=` 的 sha16 **≠** 现源、`--check` 报 `state=stale kind=src`；**还原用 `cp -p` + `touch`**（防增量构建静默沿用旧 mtime）⇒ 相同且回 `ok`。**我不动 shim，等口令。**

### 45.3 诚实边界（写死）
`file=` 只记**源的样子**（`--write` 那一刻的 sha256 前 16），**不证明产物里真的编进了它**；"产物内 sha"还缺 build 侧手段（构建时把内容哈希生成进产物 / 读 PDB 编译单元哈希 / 产物元数据取证），本段不承诺。

### 45.4 边界
本轮**未跑波、未跑重负载**：只跑 `--selftest`（自还原）与 `--write`/`--check`（纯哈希 + 写三份 `.txt`）；未碰 `build/shims/**`/`samples/**`/`docs/**`/`handoff.md`；未改 `build/artifact-src-fp.sh`。

### 45.5 判据③（两极化牙）**已预检基线、等主控口令**——不能现在动 `build/shims/**`
**为什么不能现在做**（主控裁定，非 T1d 原因）：`T3` 正在该 tuple 上取 `#13` 读数；**动 shim 会让 `hbtextline` 位变 ⇒ 冻结 tuple 被顶掉**（哪怕只加一行注释）。
**口令**：等主控说"**静树 + 可动 shim**"。**在此之前的预检（只读，已做）**：
| 项 | 现场值 | 主控给的期望值 | 一致？ |
|---|---|---|---|
| `sha256sum build/shims/PresentationCore.HbTextLine.cs \| cut -c1-16` | `fde9e511e8443cf2` | `fde9e511e8443cf2` | ✓ |
| `stat -c %Y` （mtime epoch） | `1789438795` = 2026-09-15 10:19:55 | `1789438795`（2026-09-15 10:19:55） | ✓ |
| FP 记录行 | `file=fde9e511e8443cf2  build/shims/PresentationCore.HbTextLine.cs` | — | 已含该行（新能力当前为"绿"） |
**待执行的 5 步（一次命令内，逐字节可复核）**：
1. `cp -p build/shims/PresentationCore.HbTextLine.cs $HOME/t1c-45-shim.bak`；
2. `printf '\n// T1c tooth (§45.5)\n' >> build/shims/PresentationCore.HbTextLine.cs`；
3. 断言 `sha256sum … | cut -c1-16` **≠ `fde9e511e8443cf2`**，且 `python3 build/artifact-src-fp.py --check | grep PresentationCore` ⇒ **`state=stale` + `note=kind=src`**（记录 fde9e511… ≠ 重算值）；
4. `cp -p $HOME/t1c-45-shim.bak build/shims/PresentationCore.HbTextLine.cs && touch -d @1789438795 build/shims/PresentationCore.HbTextLine.cs`（**`touch` 防增量构建静默沿用旧 mtime —— 纪律 25**）；
5. 断言 **sha 回到 `fde9e511e8443cf2`、mtime 回到 `1789438795`**；不一致 ⇒ **立刻报主控**。收尾再跑一次 `--check` ⇒ 三行 `state=ok`。

### 45.6 判据③ **已实测**（主控口令"静树 + 可动 shim"，T1d 此刻不动该文件；T3 那趟**不编 shim** ⇒ 窗口内无编译趟）
**五步结果（一次命令内，逐项断言）**：
```
① cp -p 备份 → $HOME/t1c-45-shim.bak：sha16=fde9e511e8443cf2  mtime=1789438795
② 追加一行注释 → shim sha16=72313e438cd2bb44（**≠ fde9e511e8443cf2**）⇒ 断言A PASS
③ --check（**牙中**，rc=2）：
   ARTIFACT_SRC_FP proj=PresentationCore fp=8a8f65c9664451e1 n=1369 peer_fp=c1f4fcef3bf77968 peer_n=7 state=stale note=kind=src；源记录 d9b7cac83d3c2016 ≠ 重算 8a8f65c9664451e1（⇒ 本工程需重建）
   ARTIFACT_SRC_FP proj=WindowsBase fp=e8e18b887b6535bd n=325 peer_fp=806512a8ef23435e peer_n=1 state=ok
   ARTIFACT_SRC_FP proj=PresentationFramework fp=80bc2130203ad9a2 n=1361 peer_fp=10cc527231b25c47 peer_n=8 state=ok
   ⇒ **`state=stale` + `note=kind=src`** ✓（红）
④ cp -p 还原 + touch -d @1789438795 → sha16=fde9e511e8443cf2  mtime=1789438795 ⇒ 断言B/C PASS
⑤ --check（**还原后**，rc=0）：三行 state=ok；PC 回到 fp=d9b7cac83d3c2016 ✓（绿）
```
**内容级对照（同一条命令内捕获的两个值，直接可比）**：记录的 `file=` 行 `fde9e511e8443cf2` vs 牙中现源 `72313e438cd2bb44` ⇒ T1b2 那条配方此刻会打印 **`hbtextline_shim_stale=yes basis=content rec=fde9e511e8443cf2 cur=72313e438cd2bb44`**；还原后两者相等 ⇒ `=no basis=content`。
**shim 已逐字节还给 T1d**（sha 与 mtime 都回到原值，断言 B/C PASS）⇒ `D-F1` 可以照常落。**牙期间未跑 `--write`**（否则会把注释版记进 FP 文件）——判据只需 `--check`，记录保持原样。

---

## 46. `#16` PC 半落地（`D-T2` 的 `ParagraphIndent` 接线）——**含一次真实编译拦截与纪律补充**

### 46.1 交付（3 留 2 撤；**编译 0 错**）
- **留**：A `TextFormatterImp.Linux.cs:230-231` 签名加 `double paragraphIndent = 0`；B `:253` 出行那处 `FormatParagraph(…, indentDip: paragraphIndent)`；E **`:575`** 调用点传 `settings.Pap.ParagraphIndent`。
- **撤**：C `:305`（`TryMinMaxParagraphWidth` 的 maxWidth 探针，作用域内无 `paragraphIndent` ⇒ CS0103 根因）；D `:559`（我错误地把同一补丁串套到**另一个类**的同名方法上 ⇒ CS1739 根因）。
- **类解析（本次跨类事故）**：`TryFormatLine` 在生成物里共 **3 处文本** = 1 定义（`:230`，我的 `WpfLinuxLenientTextFallback`）+ 2 调用：**`:553` → `WpfLinux.Shims.PresentationCore.HbTextFallback.TryFormatLine`（shim 类，T1d 车道）**、`:569` → 我的类。
  ⇒ **`:553` 要接 indent，必须先由 T1d 在 shim 的 `TryFormatLine` 上加参数**（否则本波只覆盖"宽松兜底"路径 —— 已报主控裁定）。
- sha16：`TextFormatterImp.Linux.cs` `5dedc21f5f372c78 → 52be04f1ff12111a →（修正后）f86198dfdd349332`；应用器 `02a483e0feeee2f7 → 28658bb1b17821cf → 07dc7627f609e031`；备份 `$HOME/t1c-16-backup/`。

### 46.2 逐字错误（波第一步 `close-wave.sh --skip-verify-all` 在 `PresentationCore.Linux` 处拦下）
```
(559,46): error CS1739: “TryFormatLine”的最佳重载没有名为“paragraphIndent”的参数
(305,100): error CS0103: 当前上下文中不存在名称“paragraphIndent”
```

### 46.3 计数判据（修正后）
`grep -cF ParagraphIndent` = **1**（非 2：第二处需 T1d 的 shim 签名）｜`indentDip: paragraphIndent` = **1**｜`TryFormatLine(` = **3（不变）**｜`HbTextLineFactory.FormatParagraph(` = **3（不变）**｜`GetFiniteFormatWidth` = 0。
`--check` ×2 ⇒ rc=0 / 0；`check-appliers.sh` ⇒ `appliers=20 ok=74 miss=0 red=0 rc=0`。

### 46.4 ★纪律补充（主控点名，写死）
> **凡改"生成物会被编译进产物"的源，落地判据必须含"该工程 `dotnet build` = 0 错"**；
> `--check` rc=0 与应用器审计 **只证明应用器自己幂等 + 锚点命中**，**完全不证明生成物能编译**（本次差点把"构建失败"当成"PC 半已落"）。
> **可复用做法（本轮实测）**：用**私有输出目录**编译，既拿"0 错"证据又不碰权威产物：
> `dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 --nologo -v q -p:BaseOutputPath=$HOME/t1c-16-build/bin/ -p:BaseIntermediateOutputPath=$HOME/t1c-16-build/obj/`
> ⇒ 本轮读数：`0 个警告 / 0 个错误 / 17.53s`，`grep -c 'error CS'` = **0**，且 `pc dll` 保持 `532c7f54f7573070`（未被改写）。

### 46.5 边界
未发波、未编权威 `pc`、未改 `known-red.json`/`verify-all.sh`/`docs/**`/`build/shims/**`/`samples/**`；`:305` 按主控 (a) 裁定维持不接（五臂不消费 `minWidth`，结论已在报告 §45 之外的口头/消息中给出）。

### 46.6 主控裁定入档（2026-09-15）+ 私有目录编译的**边界**（防后人误用）
**① 私有目录编译 = 只"编"，不"跑"（与纪律 23 不冲突）**
```
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 --nologo -v q \
  -p:BaseOutputPath=$HOME/t1c-16-build/bin/ -p:BaseIntermediateOutputPath=$HOME/t1c-16-build/obj/
⇒ 用途：拿"该工程 0 错"的**编译**证据，**不碰权威 bin/obj、不改写 `pc` 的 DLL**（本轮实测 0 警告/0 错误/17.53s，`pc dll` 仍 532c7f54f7573070）。
⇒ **边界**：它**只证明"能编"**。**"跑"**（门禁/探针/应用）**不许**用这种隔离输出目录 —— 纪律 23：只隔离 `OutputPath` 而不一并处理 native 副本 ⇒ **必崩**。
   两条讲的是**不同动作**（编 vs 跑），不可互相引用。
**② `:553`（shim 主路）并入 T1d 的 `(A)` 那一趟**（主控裁定）：`:553` 是**第一选择**、我这份是**兜底** ⇒ 若 shim 的 `HbTextFallback.TryFormatLine` 不接 `paragraphIndent`，**应用主路会用默认 0** = "注册了但没生效"族 ⇒ 不许留着。
   ⇒ **顺序**：① T1d 落 `(A)`（判据 + after-tab 资格 `>=`）时，顺手补 `HbTextFallback.TryFormatLine` 的签名与透传；② **之后**我才把 `:559` 那 1 行加回。
**③ 计数口径更正（两段，别拿"2"比"1"）**：预登记原写 `ParagraphIndent 0 → 2` ⇒ 正确写法 =
   **T1c 这一趟 `0 → 1`**（`TextFormatterImp.Linux.cs`）＋ **T1d 补 shim 签名后 `1 → 2`**。
**④ `:305`（min-width 探针）**按 (a) 维持不接（五臂不消费 `minWidth`，结论已给）。
**⑤ 我的当前状态**：**等 T1d 补 shim 签名**；**不碰 `build/shims/**`**；**波期间（主控重发 `#16` 第一步、`pc` 将重建到 `f86198dfdd349332` 这一版）我的写域保持静默**（避免 `inputs_fp` 判输入不稳定）。
