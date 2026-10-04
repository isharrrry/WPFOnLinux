# T1d · R1 —— run 级字体 + 按码点覆盖回退 + 多字体整形（2026-09-11）

## 0. 版本纪律（2026-09-13 追加，**读数前先看这一格**）

**当前 shim 源 = `ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf`（3766 行，mtime `2026-09-13 00:36:31.032156734`）**
**当前 app-local PC = `684424fea3a0812ab123c6e1…`（mtime `2026-09-13 00:00:23.362964668`）**

> ⚠️ **app-local PC 比 shim 源旧 36 分钟**（两条 mtime 是我自己 `stat` 取的原文）⇒
> **在此之前的所有"应用级颜色读数"都是在旧的文本栈上取的**（旧栈里没有 per-run 前景色的 `RunSlot`），
> **不能用来判 13.1 的改动**。判"取旧件"的顺序见 §16 第 0 条。
>
> 另：**T1b 的 58 条（38+20）与我的 34/39 条按各自 sha 记**（我早先的 39 条测于 `d197de66…`，
> §13 的全部读数已在 `ebccdb1e…` 上重取）—— **跨版本不混用**。

**被测文件（落的就是测的那一份）**

| 项 | 值 |
|---|---|
| `build/shims/PresentationCore.HbTextLine.cs` | sha256 = `fbda5f88d826a88382b743e7aad5657c1546ff94a72e6ac9072731bd820f9e8b`，**3234 行 / 173733 B** |
| 改前（T1b 交接基线） | `2cc87a93f3e61af8a8b6b7c92a8e71df16d9d8eb0a200c6a64c9eb0a9901041e`（1791 行） |
| 权威 PresentationCore（**未重建**） | `b1decf16…`（主控在集成波里重建） |
| 新增探针 | `build/MilBridge/tests/CoverageProbe/`（exe，程序集名 = `PresentationCore.Tests`，借 PC 的 IVT 名额） |
| 新增装置 | `build/MilBridge/tools/t1d-probe.sh` + `build/MilBridge/run.sh t1d` |

---

## 0. 一句话

中文出真字这件事**不靠任何 env**：按**码点段**换面（HarfBuzz 自己答"覆盖面"），并且**每个字体子段发一张带自己 `GlyphTypeface` 的 `GlyphRun`**。
`WPF_LINUX_MULTIFONT=0` 时与今天**逐位相同**（245 个 glyph id 逐项相等，机器比对）。

---

## 1. 前任设计里的**一个洞**（已修，是本轮最重要的改动）

§11 通篇没提 `GlyphTypeface` / `GlyphRun`。但**渲染用哪份面是由 `GlyphRun` 自带的 `GlyphTypeface` 决定的**，三处原文：

* 上游 `GlyphRun.cs:1876`：`command.pIDWriteFont = (UInt64)_glyphTypeface.GetDWriteFontAddRef;`
* 本移植 `build/DirectWrite.Linux/Provider/FontModel.cs:285`：`LinuxFont.DWriteFontAddRef => FontHandleTable.Register(GetFontFace())`（令牌 = 路径 + 面下标）
* 渲染侧 `src/WpfGfx.Linux/Text/TextRenderer.cs:116-137` + `Interop/MilPresentation.cs:439-445`：按 `PIDWriteFont` → `MilFontFaceTable.TryResolveExact` → `SKTypeface.FromFile(path, faceIndex)`

⇒ **一个 `GlyphRun` 只能一份面**。若只按 §11 改字形 id，普查会 `id0→0 / 非拉丁>0` 变绿，而**像素仍是垃圾**（CJK 的 id 用拉丁面光栅化）——这是**本轮预先预测、并由设计规避掉的一条假绿**（预测：普查绿 + 读图否证）。
⇒ 实现改为**每个字体子段一张 `GlyphRun`**（各自面 + 各自 baseline origin），并把"一面一 run"做成**可观测读数**（见 §5）。

**面下标也是硬约束**（HB 实测，`hb_font_get_nominal_glyph`）：`NotoSansCJK-Regular.ttc` face0(JP) 与 face2(SC) 对 `文`(U+6587) 是 **20035 vs 20036**、`漢` **24227 vs 58935** ⇒ 整形用哪个面下标，渲染就必须用哪个。

---

## 2. 做了什么（四层 + 两处工程修正）

1. **run 级收集**：`HbTextFallback.TryCollect` 收 `List<CollectedRun>{Start,Length,Props}`，**每个 run 的 props 都留下**（改前只留第一个）；非 `TextCharacters` 仍**原样 bail**。
2. **run 级取面 + 缓存**：按 `TextRunProperties` **引用**缓存（`RefComparer`）⇒ 一个 run 一个 `HbFaceRef(路径, 面下标)` + `GlyphTypeface` + OS/2 三要素；某 run 解析不到 ⇒ **沿用上一个成功的面 + 计数**（`runFontUnresolved`），不整体失败。
3. **run 内按码点覆盖切段**：覆盖判据 = **`HbShaper.CoversFace`**（`hb_font_get_nominal_glyph != 0`，按 `(面,码点)` 缓存）——**不碰 provider 反射**（`FamilyCoverageQuery.*` 是扩展方法，反射恒 null，这条前任的理由我核过，成立）。候选顺序 = ①当前面 ②**其余 run 的面** ③**机器字体目录扫描**（目录口径**逐字对齐** `Factory.Linux.cs:ResolveSystemFontDirectories`：`WPF_LINUX_FONT_DIR`（`:` 分隔）→ XDG → `/usr/share/fonts` → `/usr/local/share/fonts` → `~/.local/share/fonts` → `~/.fonts`）。**挑法按覆盖**，同覆盖才按 HB 读到的 OS/2 `(字重,拉伸,斜体)` 就近（⇒ 7 个 CJK ttc 里挑到 Regular，不是 Black）；**不按字体名/文件名**。
4. **多字体整形**：各子段分别 `Shape`，glyphs/advances/offsets **顺序拼接**，cluster **平移回局部下标**（`+ 段起点`）⇒ 仍是**一个** `HbShapedRun`。
5. **面物化 + 闸门**：候选面只在**通过闸门**后才进计划 —— 闸门 = 覆盖 **且** 能物化成 `GlyphTypeface` **且** 身份三重校验：`FontUri.LocalPath == 文件` ∧ `FaceIndex == 整形下标` ∧ `CharacterToGlyphMap[cp] == HB nominal_glyph(cp)`（**逐回退码点**）。不过闸 ⇒ `fallbackFailed++` 并**沿用当前面**（绝不静默画错字）。
   * 只走**文件路径 + faceIndex**（`FontFamily → TryGetGlyphTypeface`，其 `_font` 来自 provider 的 `SKTypeface.FromFile(path, faceIndex)`）——**不用 `FromBytes` 造面**（T1c 的约束：`SourcePath==null` ⇒ 路径式令牌分配器拿不到路径 ⇒ MIL 解析不到）。探针里用 `SKTypeface.FromFile(path, faceIndex)` **独立复核**每一张 `GlyphRun` 的面可加载。
6. **开关**：`WPF_LINUX_MULTIFONT`，**缺省开**，显式 `0/false/off/no` 关；关掉 = **只用第一个 run 的面 + 单面整形**（= 今天）。
7. **两种编译形态**：新增 `HbFaceInternals`（`#if TEXTLINE_SHIM_DIRECT` 真读 `GlyphTypeface.FaceIndex`/`GetDWriteFontAddRef`；`#else` **诚实降级**：面下标按 0、令牌报"不可用"，并计 `faceInternalsSkipped`）——反射形态（`HbTextLineParity`/`TextLineProto`）必须能编过，否则"拉丁不退步"那三条读数就再也量不了。

**断行规则与行记账：一行未动**（只换 advance 的来源）。`HbBreakEngine` 的规则集、`HbLineRange`/`Length`/`NewlineLength`/`TrailingWhitespaceLength`/`WITW−W` 的算法都是原样。

---

## 3. 四条验收的读数（附**本次编译状态**）

**编译状态（`-m:1` 串行；这是本次所有读数的前提）**
```
[1] DIRECT 形态  DirectBranchCheck（TEXTLINE_SHIM_DIRECT + IVT 编译闸门）：**0 个错误 0 个警告**
[2] 反射形态    HbTextLineParity（驱动 build/shims 真源）：**0 个错误 0 个警告**
[3] CoverageProbe（新探针）：**0 个错误 0 个警告**
```

### 验收 2/3 —— 拉丁与记账**不退步**（`bash build/MilBridge/run.sh tline`，sha 已钉 `fbda5f88…`）

| 判据 | 改前 `2cc87a93…` | 改后 `fbda5f88…` |
|---|---|---|
| `T1.73` 73 例 CJK 逐行全等 | ✅ 73/73 | ✅ **73/73** |
| `T2` 记账结构（行） | 1276/1298；①286/286 ②68/68 ③977/988；宽度超差 83 | **逐项相同** |
| `T2b` A 组断行 | 964/965；用例级 207/213 | **逐项相同** |
| `T2d` Height/Baseline/Extent | ✅（1298/1298） | ✅ **1298/1298** |
| `T3` 折叠 | 判定 1298/1298；明细 **210/236**；空参抛 253/253；空参返回 this 1045/1045 | **逐项相同** |
| `T2c` Tab（**已登记红**） | 34 例中 15 例不一致 | **仍是 15 例（保留红）** |
| 通过/失败 | 15/5（其中 1 条是 `-p:HbShimSrc` 覆盖源文件导致的 T0.6 身份红，见下） | 16/4 |

> 改前那份是我把 **staging 的 `2cc87a93…` 原样副本** 用 `-p:HbShimSrc=` 编进同一个 harness 跑的。它多出来的那 1 条红是 `T0.6「编进去的那份 ≠ 磁盘那份」`——**仪器工作正常**的读数（我确实覆盖了源文件），不是退步。

`bash build/MilBridge/run.sh icu`：**73 例逐例一致**（Stage A/B/C 不一致均为 0）⇒ `73/73`。

### 验收 1 —— CJK 真出字（**不靠 `WPF_LINUX_UI_FONT`**）

装置：`bash build/MilBridge/run.sh t1d`（或 `bash build/MilBridge/tools/t1d-probe.sh /tmp/t1d-readings`），
驱动**真 shim 源**的**应用路径** `HbTextFallback.TryFormatLine`，输入 = `samples/WpfTextDemo/MainWindow.xaml` ① 号文本块的**同一串**中英混排（245 字）。

| 档位 | `id0` | `非拉丁(≥0x1000)` | `maxId` | glyphs | 张 GlyphRun | 拆过的行 |
|---|---|---|---|---|---|---|
| **① default（R1 生效）** | **0** | **58** | **63151** | 245 | 18 | 5 |
| ② `WPF_LINUX_MULTIFONT=0`（= 今天） | 60 | 0 | 93 | 245 | 6 | 0 |
| ③ two-run（3 个 run，其一自带 CJK 面） | 0 | 58 | 63151 | 245 | 20 | 5 |
| ④ `WPF_LINUX_FONT_DIR=build/fonts-ui` | 60 | 0 | 93 | 245 | 6 | 0 |

* `maxId=63151` 与主控给的阳性对照（`maxId=63151`）**逐字相同**；`非拉丁=58` 是这一串文本里的 CJK 字符数。
* ④ 就是**结构性无解**那一档：`candidates=1`（只有 `UI-NoLayout.ttf`）⇒ `fallbackApplied=0 / fallbackFailed=60 / fromSystemScan=0`，**与今天完全相同**（不假装可达）。

**A/B 的"逐位"证据（机器比对，不是论证）**：
```
[T1D_PROBE] ab(逐位): compared=True same=True 本条路径 245 个 id vs 单字体入口（改前那段代码）245 个 id ⇒ **逐项相等**
```
（`MULTIFONT=0` 时的 id 序列 vs `HbTextLineFactory.FormatParagraph` 单字体入口——后者是**本轮一行没改**的代码。）

### 六个计数器的原文（`default` 档）

```
[T1D_PROBE] counters: multifont=plan=1 runs=1 runGt1=0 cpUncovered=60 coverageProbe=1925 coverageCacheHit=497
             fallbackApplied=60 fallbackFailed=0 fallbackUnrenderable=0 fromRunFaces=0 fromSystemScan=60
             segments=12 chunkedLines=5 faceResolve=1/0(缓存命中60) candidates=371(扫描1次)
[T1D_PROBE] detail:   fallbackTargets=Noto Sans CJK JP@/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc#0×60
                      样例码点=U+8FD9@…ttc#0,U+662F@…ttc#0,U+4E00@…ttc#0,U+6BB5@…ttc#0,…
                      未找到覆盖面=(无)  覆盖但物化不了=(无)
```
`two-run` 档：`runs=3 runGt1=1 cpUncovered=56 fallbackApplied=56 **fromRunFaces=56 fromSystemScan=0**` ⇒ 候选②（其余 run 的面）**确实优先于**候选③。
**"无信息"与 "0" 分家**：`MULTIFONT=0` 档整段写 `multifont=未使用(plan=0) 覆盖/回退各项=**无信息**（不是 0）`。

### 验收 4 —— 逐 run 可观测（"一面一 run"契约，原文节选）

```
glyphRuns=2 [r0 cp=0..20  glyphs=20 face=/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc faceIndex=0 token=0x20000002 origin=0.000   chars="这是一段用于验证自动折行的中英混排文字："]
            [r1 cp=20..27 glyphs=7  face=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf            faceIndex=0 token=0x20000001 origin=320.000 chars="WPF on "]
glyphRuns=3 [r0 cp=113..115 glyphs=2 face=…NotoSansCJK-Regular.ttc faceIndex=0 token=0x20000002 origin=0.000  chars="保证"]
            [r1 cp=115..120 glyphs=5 face=…DejaVuSans.ttf          faceIndex=0 token=0x20000001 origin=32.000 chars=" CJK "]
            [r2 cp=120..138 glyphs=18 face=…NotoSansCJK-Regular.ttc faceIndex=0 token=0x20000002 origin=68.555 chars="字符之间可以正常断行、标点不会跑到行"]
```
（`token` 读的是 `GlyphTypeface.GetDWriteFontAddRef` —— 就是上游塞进 `pIDWriteFont` 的那一个值。它**会幂等登记**（同 `(path,faceIndex,simFlags)` 恒得同一句柄），属"有副作用的观测"，故缺省关、只在探针里取。）

### 探针自检（仪器会不会撒谎）

| 检查 | default | ab-off | fonts-ui |
|---|---|---|---|
| P1 应用路径接下了这一段 | PASS | PASS | PASS |
| P2 每张 `GlyphRun` 的面能被**渲染器那条链**加载（`SKTypeface.FromFile(path,faceIndex)`） | PASS（18 张） | PASS（6 张） | PASS（6 张） |
| P3 每张 run 的面令牌非 0（MIL 能反查） | PASS | PASS | PASS |
| **P6（强）** 画出来的 id 必须**存在于它所挂的那份面**里（`id < face.GlyphCount`） | PASS（0 越界） | PASS | PASS |
| P4 整形面 == 渲染面（渲染面 cmap vs **HB 对同一份面**的 nominal glyph，逐簇首） | PASS（245 簇首，不符 0） | **FAIL**（cmap 缺项 60 = 病灶可见） | **FAIL**（同上） |
| P5 真拆过（`chunkedLines>0`）且张数 ≥ 行数 | PASS | **FAIL**（没拆） | **FAIL**（没拆） |

⇒ **P4/P5 在"没生效"的档里如实报红**（不是"没数据也算绿"）；`default` 档 0 个 `.notdef`、0 个越界 id。

---

## 4. 本轮**自己抓到的两个缺陷**（都已修，如实登记）

1. **`HbFontPlan.Sub()` 只裁剪、不重定基**：改前第 2 行以后 `e = min(段末,行末) < s = max(段首,0)` ⇒ 段被整段跳过 ⇒ **第 2 行起 0 字形、`Width=0`**（行"消失"）。
   **单字体入口看不见它**（不走计划）⇒ 三个既有 harness（`icu`/`tline`/`textline`）**全绿也发现不了**；是我的新探针第 1 次运行就抓到的（`lines=7 glyphRuns=3` 对不上）。修法：`Sub` 重定基到 0。
2. **`hb_ot_name_get_utf8` 协议坑**：`text==NULL` 时它把"需要的字节数"**当返回值**给出来，**不写 `*text_size`**（写 0）。第一版按 `*text_size` 判空 ⇒ 永远读不到族名 ⇒ 闸门把候选面全拒（`fallbackFailed=60`）。**这恰好证明闸门在干活**（宁可不出字，也不静默用错面）；修法：用返回值。
3. **探针自己的两条假绿**（也修了）：① P2–P5 在"0 张 run"时**真空通过** ⇒ 现在无数据一律报"**无信息**"并判失败；② P5 的**标签**写"chunkedLines>0"而**条件**没查它 ⇒ 在没拆的档里也 PASS，现在条件里就是它。

---

## 5. 未覆盖 / 做不到（诚实清单）

1. **应用级普查（`id0=325→~0 / 非拉丁 0→294 / maxid 3540→63151`）我没有量**：要有**含本 shim 的 PC**。按主控裁决走 (a)：不重建 PC、不编 `/tmp`。本报告的 CJK 读数是**shim 边界**的量（shim 交给渲染器的那批 id），**没经过 MIL 往返、没光栅化**。
2. **`WPF_LINUX_FONT_DIR=build/fonts-ui` 档结构性无解**（`UI-NoLayout.ttf` 0 个 CJK 码点）⇒ 该档 `id0=60 / 非拉丁=0`，与今天相同，**不假装可达**。
3. **per-run 字号（`FontRenderingEmSize`）未支持**：整段仍用第一个 run 的字号（与今天一致）；run 之间字号不同时**只换面、不换字号**。
4. **不实现 bidi / 竖排**：与今天一致（有 RTL 的用例本来就不可比）。
5. **`Extent` 仍是行高**（`Extent => _height`）——主控明确"这轮别动"。
6. **`GetIndexedGlyphRuns` 仍欠账**（上游 0 调用点，主控裁定不实现）。
7. 面缓存的**上限策略**是"满 512 个面 / 262144 条覆盖记录就**整表清空**"（不是 LRU），清空次数计 `faceEvictions`；本档实测 `faceEvictions=0`。
8. 反射形态下 `FaceIndex` 拿不到 ⇒ 三重校验里的**面下标那一条被跳过**（`faceInternalsSkipped`），cmap 那条**照验**（用的是 public `CharacterToGlyphMap`）。**不声称验过**。

---

## 6. 需要主控做什么

1. **起集成波重建 PC**（我不重建；落完即冻 `build/shims/**`，本文件到此不再改）。
2. 波后按下面的**期望清单**收应用级读数（`bash build/MilBridge/tools/t1c-census.sh <outdir> default WPF_LINUX_GLYPH_CENSUS=1`）：
   | 读数 | 基线（波前） | **波后期望** |
   |---|---|---|
   | `id0` | 325/1276 | **≈ 0**（CJK 有真字形） |
   | `非拉丁(id≥0x1000)` | 0 | **> 0**（阳性对照 294 量级） |
   | `maxId` | 3540 | **≈ 63151**（CJK 面） |
   | `不同面数` / `distinctPids` | 2（`0x20000003`×14 + `0x20000004`×66） | **≥3**（多出 `NotoSansCJK-Regular.ttc` 那一个令牌；张数会随行划分变） |
   | `未画种类` | 0 | **仍 0**（不许为了出字把某个指令类弄丢） |
   | 帧 | 938×938 | 同尺寸；**读图看中文**（这一步不能省：普查绿 ≠ 像素对） |
3. 需要我做的：**A/B 关档**的应用级对照（`WPF_LINUX_MULTIFONT=0` 应回到 `id0=325`），波后我可以在你的 runner 里补跑。

---

## 7. 追加（2026-09-11 晚）：摞印定位的**只读插桩**（`WPF_LINUX_HBLINE_TRACE`）

**sha 变更**：`fbda5f88…` → **`262db454ff0b50e20515330cb9ec810371132a3471404da307d64cd0483c686c`**（3353 行）。
**只加插桩，R1 行为逻辑一行未动**；`WPF_LINUX_HBLINE_TRACE` **缺省关**，设 `=0` 或不设 ⇒ 零输出。

| 站点 | 落点 | 打什么 |
|---|---|---|
| A | `HbTextLineFactory.FormatParagraph` 每产出一行 | `cpFirst/cpLast/len/nl/h/bl/w/glyphRuns/runOrigins` |
| B | `HbTextLine.Draw` 每次被调用 | 上面全部 + **`hostOrigin=(x,y)`** + `firstRunOriginY-minus-hostOriginY` |
| C | `HbTextFallback.TryFormatLine` 交出整段 | `段起点/行数/perLine=[cp:h:bl]` |

**每站独立预算 60 行**（T1c 踩过"共享预算 ⇒ 最晚站点永远看不见"），预算用尽打一行 `**预算用尽**` 标记。
纯只读：不发 HB 调用、**不取面令牌**（`GetDWriteFontAddRef` 会登记）、不碰计数器、不改调用次数。

**判据的规范依据（上游原文 `MS/internal/TextFormatting/SimpleTextLine.cs:572-605`）**
```csharp
double y = origin.Y + Baseline;
drawingContext?.PushGuidelineY1(y);
foreach (SimpleRun run) run.Draw(dc, IdealToReal(idealXRelativeToOrigin, PixelsPerDip) + origin.X, y, false);
```
⇒ `TextLine.Draw(dc, origin, …)` **必须**把 `origin` 带进绘制；本 shim 的 `Draw` 只用自己算的 `(pen, baseline)`。

**实测（探针，自起空显示号 `:95`，跑前 `xdpyinfo`、按 PID 收尾、无残留；**hostOrigin 是探针自选的模拟值，不是真宿主**）**
```
HBLINE B#0   cpFirst=0   hostOrigin=(0.0000,0.0000)   runOrigins=[(0.000,14.852) (320.000,14.852)] firstRunOriginY-minus-hostOriginY=14.8516
HBLINE B#27  cpFirst=27  hostOrigin=(0.0000,18.6250)  runOrigins=[(0.000,14.852)]                   firstRunOriginY-minus-hostOriginY=-3.7734
HBLINE B#72  cpFirst=72  hostOrigin=(0.0000,37.2500)  runOrigins=[(0.000,14.852) (299.242,14.852)] firstRunOriginY-minus-hostOriginY=-22.3984
HBLINE B#113 cpFirst=113 hostOrigin=(0.0000,55.8750)  runOrigins=[(0.000,14.852) (32.000,14.852) (68.555,14.852)] firstRunOriginY-minus-hostOriginY=-41.0234
HBLINE B#180 cpFirst=180 hostOrigin=(0.0000,93.1250)  runOrigins=[(0.000,14.852) …]                firstRunOriginY-minus-hostOriginY=-78.2734
HBLINE B#211 cpFirst=211 hostOrigin=(0.0000,111.7500) runOrigins=[(0.000,14.852)]                   firstRunOriginY-minus-hostOriginY=-96.8984
```
⇒ **代码路径事实**：我们的 `runOrigins` 恒为 `(…, 14.852)`（行内 `Baseline`），**从不带 `origin`**；`firstRunOriginY−hostOriginY` 每行恰好掉一个行高（−18.625/行）。
⇒ **判定**：宿主若逐行给递增 `origin.y`（T1c 在 `SimpleTextLine` 上实测 `0 → 13.9688 → 27.9375 → 48.8906 → 97.7812`），则①、②两块里**我们这条路的每一行都画在同一个 y** ⇒ **多行摞印**。
⇒ **本轮按主控边界只插桩、未修**；真宿主给的 `origin` 序列需跑应用（等主控 slot）。

**"没改行为"的两条机器证据**
1. 同一显示号下 trace OFF vs ON：剔除 `HBLINE` 行后**逐字节相同**（含 `draw=` 计数、字形普查、六个 R1 计数器、探针自检）。
2. `run.sh tline`（sha 钉 `262db454…`）与插桩前 `fbda5f88…` **逐项相同**：`T1.73 ✅73/73`、`T2 1276/1298 ①286/286 ②68/68 ③977/988 宽度超差83`、`T2b 964/965·207/213`、`T2d ✅1298/1298`、`T3 判定1298/1298 明细210/236`、`T2c` Tab **15 例保留红**。
**编译状态**：DIRECT / 反射 / CoverageProbe **各 0 错 0 警**。

---

## 8. 摞印**修法**（2026-09-11，主控批准的行为改动）

**sha**：`262db454…`（仅插桩）→ **`ba5c777c0d4f652f7c55a984345d9aa415a6cd5a297ca595b512cdbeb417302f`**（3423 行）。

**一句话**：`HbTextLine.Draw` 现在把宿主给的**行原点**带进绘制 —— 与上游 `SimpleTextLine.cs:572-605` 的
`double y = origin.Y + Baseline; run.Draw(dc, x + origin.X, y, false);` **逐字同构**。

**为什么不是 `PushTransform`**：`GlyphRun.BaselineOrigin` 的 setter 是 **init-only**（`CheckInitializing()`，构造后 set 抛）⇒ 不能原地改；
`MilPushTransform` 与"烘进 run"在本工程**都能生效**（`GlyphRunPainter` 走 `canvas.DrawText`，吃画布矩阵），选"烘进 run"是因为
**判据能直接量在我们真正画出去的那份数据上**，且它是上游快路径的原形态。
落点正确性已核：`GlyphRun.cs:1869-1870` `command.Origin.X/Y = (float)_baselineOrigin.X/Y`
⇒ 改动**正是** `MilGlyphRun.Origin`（T2b 的 `devY` 列所量），`ManagedBounds` 也随之偏移（与上游一致）。

**范围**：只动"画到哪里"。`GlyphTypeface`/glyph id/advance/offset/cluster/caretStop 原样；`HbBreakEngine`、记账、R1 选面与切段、六个计数器**一行未改**；`origin==(0,0)` 时返回**原来那批对象**（首位行逐位不变）；同一 origin 复用同一批 run（每帧零分配）。

**station B 实测（探针，`:95`；hostOrigin 为探针自选的模拟值）**
```
改前：runOrigins 恒 (…,14.852)；Δ = 14.85 / −3.77 / −22.40 / −41.02 / −78.27 / −96.90
改后：runOrigins y = 14.852 → 33.477 → 52.102 → 70.727 → 89.352 → 107.977 → 126.602（步长恒 +18.625 = 行高）
      delta(firstRunOriginY-(hostOriginY+Baseline)) = 0.0000（每一行）
```
**"只改了画到哪里"的机器证据**：同一显示号下，改前 vs 改后探针输出**剔除 `HBLINE` 行后逐字节相同**（普查/六个计数器/记账/自检全不变）。
**不回归**：`run.sh tline`（sha 钉 `ba5c777c…`）与改前**逐项相同**（`T1.73 73/73`、`T2 1276/1298 (①286/286 ②68/68 ③977/988)`、`T2b 964/965·207/213`、`T2d 1298/1298`、`T3 210/236`、Tab 15 例红）。
**编译**：DIRECT / 反射 / CoverageProbe **各 0 错 0 警**。插桩保留（缺省关、每站独立预算 60）。

**待主控 slot**：应用级 `devY`（① 卡 5 个 run 应从"全等 175.486"变成逐行递增 ≈19.4 设备像素）+ 改前/改后两张图。

---

## 9. `Extent` = 墨迹盒高度（2026-09-11，主控派单）

**sha**：`ba5c777c…` → **`49fdda9a34e3c42d1fb28826105a97cc396a2854e9bfb4644295b5a602f38792`**（3469 行）。
**只动 `Extent`**（`Height`/`Baseline`/`TextHeight`/`MarkerHeight`/断行/记账/R1 选面切段/六个计数器一行未改）。

**语义依据（上游原文三条）**
- `SimpleTextLine.cs:1796-1802`：`inkBoundingBox = glyphRun.ComputeInkBoundingBox();` 再按 `BaselineOrigin` 平移、并集；
- `SimpleTextLine.cs:1071-1083`：`Extent => _boundingBox.Bottom - _boundingBox.Top`，注释原文 “the **height of the actual black** of the line”；
- `FullTextLine.cs:2333-2338 / 2640`：`Extent = _overhang.Extent = boundingBox.Bottom - boundingBox.Top`。
⇒ 实现用**同一条公式**（逐张 `GlyphRun` 取 `ComputeInkBoundingBox()`、按各自基线原点平移后并集；空 ⇒ 0），
不是另挑近似口径。每张 run 用**它自己那份面** ⇒ 墨迹与 R1 的分段渲染面天然一致。

**为什么不选 HarfBuzz extents（实测否证）**：HB 的逐字形墨迹并集给 Latin **16.0800**、CJK **15.2320**，
而真值是 **18.0800 / 18.0859**（Δ=−2.00 / −2.85）⇒ HB 口径**不是**真机口径；
而 `ComputeInkBoundingBox` 在 Latin 上给出 **18.0800 = 真值逐位相等**（Δ=0.0000）。

**读数（判据 = T1b 现成装置 `T2eLineHeight`，`run.sh tline` 也带 T2d 的 Extent 列）**
```
T2e：extent_ok  **0/10 → 5/10**（height_ok 10/10、baseline_ok 10/10 不变；textheight_ok 5/10 = 早已登记的 CJK 字体代用）
     过的是 5 个 Latin 例（逐位相等）；红的 5 个是 CJK 例
T2d：Extent 列 **0/1298 → 1259/1298**（容差 0.01 DIP！）Height/Baseline 仍 **1298/1298**
T1.73 ✅73/73；T2 记账 1276/1298（①286/286 ②68/68 ③977/988）；T2b 964/965·207/213；T3 折叠 210/236
```
**CJK 那 5 例：根因已定位到 provider 车道（不是本 shim）**
`build/DirectWrite.Linux/Provider/LinuxFontFace.cs:295-299` 的实现说明写着
`rsb = advanceWidth - lsb - inkWidth（inkWidth = glyf 的 xMax-xMin，空轮廓为 0）`：
- `NotoSansCJK-Regular.ttc`：**`glyf = 0 B`、`CFF = 15,458,582 B`**（HB 表长实测；`.otf`/CJK `.ttc` 都是 CFF 轮廓）
  ⇒ `inkWidth = 0` ⇒ 每个字形 `left == right` ⇒ `ComputeInkBoundingBoxLtoR` 的 “skip blank glyphs” 把**整行**跳过
  ⇒ 墨迹盒 `Rect.Empty` ⇒ 我们 `Extent = 0`（实测：`--family "Noto Sans CJK JP"` 时 `Extent=0.0000`，而字形度量本身完全正常：
  `aw=16.000 lsb=0.288 rsb=15.712 tsb=0.672 bsb=15.328`，`lsb+rsb == aw`）。
- 对照 `NotoSans-Regular.ttf`（`glyf = 242,879 B`）⇒ 墨迹盒正确 ⇒ 5 个 Latin 例**逐位相等**。
⇒ 这是**CFF 字体墨迹盒缺失**的 provider 缺陷（同一缺陷也让 CJK 的 `ManagedBounds` 退化），
**修在 `build/DirectWrite.Linux/Provider/**`（T2 车道）**，本轮**照实留红**、未绕道、未放宽。

**消费者普查（主控要求 5）**：`TextLine.Extent` 在仓内**只有** `FormattedText.cs:1752/1779`
（`blackBoxTop = blackBoxBottom - currentLine.Extent`、`metrics.Extent = accBottom - accTop`）——
**只进"黑盒度量"这个报告量**；行推进用的是 `currentLine.Height`（`:1764 AdvanceLineOrigin`）；
**`TextBlock` 全文不消费 `Extent`**（`TextBlock.cs` 里 0 处匹配）⇒ 我的改动**不牵动布局**。

**未诊断**：T2d 的 39 条余差（容差 0.01、远严于项目口径的 0.34；不在 CJK/CFF 家族内，comparable 集合全是 glyf 字体）——
本轮**未定位**，如实登记为欠账。

---

## 10. Tab（`\t`）口径 —— **规格先钉死，再改代码**（2026-09-11）

### 10.1 真值里到底有什么（可复算）
`build/MilBridge/gen/layout-b34-compact.json` 里 `fontKey=="file"` 且含 `\t` 的用例 **34 个**，家族 `A1_tabs`(21) / `B_tabs`(4) / `B_tabs_trim`(1) / `F_tabs`(8)；
**34 个用例的文本全都是同一串**：`'a\tb\t\tc\td'`（8 字；`\t` 在 1/3/4/6），字体 = `build/fonts/NotoSans-Regular.ttf`，`em=16`，宽度从 20 到 ∞。

| 观察 | 真值 | 说明 |
|---|---|---|
| 宽 ≥ 40（含 ∞） | **1 行**：`i=0 len=9 nl=1 ws=1 w=36.3500` | `len=9` = 8 字 + EOP；`36.35` = **四个字母之和**（a+b+c+d）⇒ **`\t` 宽 = 0** |
| `w=20` | `[0,4) w=18.8233 ws=0` + `[4,9) w=17.5267 ws=1` | 断点 **4**；行 0 以 `\t` 结尾而 **`ws=0`**（⇒ `\t` **不算行尾空白**）；行 0 的 `w==witw` ⇒ 那个 `\t` 对 WITW 也没贡献 |
| `w=30` | `[0,6) w=26.5067 ws=0` + `[6,9) w=9.8433 ws=1` | 断点 **6** |

### 10.2 与 ICU（UAX#14）的差异（实测，不是推断）
```
ICU 70 对 'a\tb\t\tc\td'（zh-CN / root）断点集 = [0, 2, 5, 7, 8]
```
即 ICU 把 U+0009 当 **BA（其后可断）**：2 = `\t`@1 之后、5 = 两个连续 `\t` 之后、7 = `\t`@6 之后；**两个连续 `\t` 之间（4）ICU 不给断点**。
而真值的断点 **4 / 6 恰好都是"某个 `\t` 之前"**，且**不是**"`\t` 之后"：

| 假设 | w=20 会给 | w=30 会给 | 与真值 |
|---|---|---|---|
| ICU 原样（`\t` 之后可断）+ `\t` 宽 0 | `[0,5)`（18.816 ≤ 20 且 5 是候选） | `[0,7)` | ✗✗ |
| `\t` **之前**可断（{1,3,4,6}）+ `\t` 宽 0 | `[0,4)` ✓ | `[0,6)`（26.496 ≤ 30，下一候选 6；8 为段末）✓ | **✓✓** |
| `\t` 之后可断但当"下一个也是 `\t`"时不可断 | `[0,4)` ✓ | `[0,7)` ✗ | ✗ |

⇒ **规格（三条，按真值钉死）**：
1. **宽度**：`\t` 的 advance = **0**（对 `Width` 与 `WidthIncludingTrailingWhitespace` 都不贡献）；
2. **断点**：**每个 `\t` 之前**是断点；**`\t` 之后不是断点**（覆盖掉 ICU 的 BA 语义）；
3. **记账**：`\t` **不计入** `TrailingWhitespaceLength`（真值行 0 以 `\t` 结尾而 `ws=0`）。
   `\t` 仍**占区间**（`Length` 含它 ✓ 与既有记账 ① 一致）。

**规格的已知边界（诚实登记）**：oracle 里**只有这一串**含 `\t` 的文本（34 例同串），所以"`\t` 之后不可断"这条的**直接证据**只有两处（`w=20` 不选 5、`w=30` 不选 7）；"`\t` 之前可断"由 4/6 两个断点直接支撑。与 `TextTrimming` 的相互作用**无真值**（`B_tabs_trim` 在 w=120 下根本不折行）⇒ 未做、不改。

### 10.3 实现与读数（sha `adbee67b0cc2f6dd179c94eb41546fbe5826868cec55375968e4249794b04fca` / 3528 行）

**三处改动（都在本 shim；断行规则与记账的其余部分一行未动）**
1. `HbShaper.Shape` 末尾调 `ZeroTabAdvances(r, text, font)`：`\t` 所在 cluster 的 advance/offset 清零，
   **并把它的字形换成该字体的 space 字形**（否则会在零步进处叠一个 `.notdef` 豆腐块；取不到 space 字形就只清零，如实保留）。
2. `HbBreakEngine.OverlayTabs(set, text)`（**规则 4**）：每个 `\t` 之前加断点、`i+1` 去掉断点；
   **禁则参考集也用这份**（`rawTab`）—— 否则"`\t` 之前"会被 `CannotStartLine` 当禁则位置、触发规则 2 拉字。
   无 `\t` 的文本**恒等**（逐字符判断）⇒ 其余用例不受影响。
3. `HbBreakEngine.IsTrailingWhitespace(c) = char.IsWhiteSpace(c) && c != '\t'`：`TrailingWhitespaceCount` 与
   `EffectiveWidth` 都用它（真机：行以 `\t` 结尾 ⇒ `TrailingWhitespaceLength = 0`）。

**判据（`bash build/MilBridge/run.sh tline`，sha 已钉）**
```
T2c：Tab 可比例 34 例，其中不一致 **15 → 0**（家族列表变空）⇒ 该 Check 由 ❌ 变 ✅
T1.73 ✅73/73（不变）        T2d ✅ Height/Baseline 1298/1298（不变）      T2d-lh ✅
T2  记账结构  1276 → **1286**/1298（①286/286 ②68/68 ③977 → **984**/988；宽度超差 83 → **47**）
T2b A 组      964/965 · 207/213（不变）      T3 折叠 判定1298/1298（不变）、明细 210 → **218**/236
通过 **16 → 19** / 失败 **4 → 2**
```
**逐例对照（"没有一条变坏"）**：不一致用例 32 → 17，**新出现的不一致 = 无**；消失的 15 个恰好是
`A1_tabs_w20/w30/w40/w50/w60/w70`、`B_tabs_w60`、`F_tabs_w40/w80/w120/w200/w320/w560/w900/winf`。
（T2/T3 那几个计数**变好**而不是"不变"，正是因为这 34 个 Tab 用例也进那几本账 —— 它们的行以前测错、现在测对。）

### 10.4 **牙齿：两条规则各突变一次，判据必须变红**（命令照抄可复算）
```bash
cp build/shims/PresentationCore.HbTextLine.cs /tmp/t1d-shim-baseline.cs        # 留底（还原要逐字节一致）
# M1：关掉"tab 零宽" —— 把零宽调用注释掉
#     （原文）                ZeroTabAdvances(r, text, font);
#     （突变）                // 【突变 M1】关掉 tab 零宽：ZeroTabAdvances(r, text, font);
# M2：关掉"tab 之前可断/之后不可断" —— 把规则 4 的接入换回原样
#     （原文）  List<int> rawTab = OverlayTabs(new List<int>(raw), para);
#     （突变）  List<int> rawTab = new List<int>(raw);   // 【突变 M2】…
cd build/MilBridge/tests/HbTextLineParity && dotnet build -c Release -m:1 --nologo \
  && dotnet bin/Release/MilBridge.HbTextLineParity.dll | grep -a 'Tab 可比例'
cp /tmp/t1d-shim-baseline.cs build/shims/PresentationCore.HbTextLine.cs          # 还原
```
实测读数（两次突变都**必须红**，否则判据没牙）：
```
M1（tab 宽度非 0）：Tab 可比例 34 例，其中不一致 **15 例**（家族：A1_tabs,B_tabs,F_tabs）  ⇒ T2c ❌
M2（断点规则关掉）：Tab 可比例 34 例，其中不一致 **2 例**（家族：A1_tabs）                ⇒ T2c ❌
还原后 sha = adbee67b…（与基线逐字节相同）⇒ Tab 34 例不一致 **0**                        ⇒ T2c ✅
```
**编译状态**（本次全部读数前提）：DIRECT / 反射 / CoverageProbe **各 0 错 0 警**。
**未做**（真值里没有）：`\t` 与 `TextTrimming`/对齐的相互作用（`B_tabs_trim` 在 w=120 下不折行，给不出证据）；
制表位（tab stop）语义 —— 真机这 34 例的 tab **总宽贡献恒为 0**，故本实现**不引入制表位**。
**顺带一条给 T1b**：`T2c` 的 **文案**仍写着"本实现未做"（判据已是 `tabDiff == 0`），我按边界没改它的文件。

---

## 11. P0：RTL 文本崩溃（`InvertAxes`）—— 2026-09-11

**sha**：`adbee67b…` → **`fdffc703e277355afd5a130ee6082018c0105554dfc12aeedc4afab18c9bf8cc`**（3664 行）。

### 11.1 现场（谁抛、什么条件、为什么 RTL 会带这个值）
- 抛出点：`HbTextLine.Draw` 里的 `throw new NotSupportedException("B1/B2 只支持 InvertAxes.None")`。
- **调用方与取值**：`MS/Internal/Text/Line.cs:79` `_mirror = (lineProperties.FlowDirection == FlowDirection.RightToLeft);`
  ⇒ `:116` `line.Draw(ctx, new Point(lineOffset.X + delta, lineOffset.Y), (_mirror ? InvertAxes.Horizontal : InvertAxes.None));`
  ⇒ **只看段落方向**（与文本内容无关）：任何 `FlowDirection=RightToLeft` 的 `TextBlock`/FlowDocument 都传 `Horizontal`。
- 后果链：`TextBlock.OnRender → UIElement.Arrange → StackPanel.ArrangeOverride` 里抛 ⇒ **窗口都出不来**（`exit=134`）。
- **上游语义**（✅ 已核，不是我推的）：`TextFormatterImp.CreateAntiInversionTransform`（`TextFormatterImp.cs:565-595`）是**纯矩阵**：
  `Horizontal ⇒ m11=−1, offsetX=paragraphWidth`；`Vertical ⇒ m22=−1, offsetY=lineHeight`；`Both ⇒ 两者`；
  `None ⇒ null`。`SimpleTextLine.Draw`（`:482-501`）的做法就是：`antiInversion = CreateAntiInversionTransform(...)`，非 null 就 `PushTransform` 后照常画、`finally Pop`。

### 11.2 判 (a) 还是 (b)：**(a) 做掉**（工作量小，且不需要任何降级）
**B1 要镜像什么**：把整行的**绘制坐标系**按 `x' = 段落宽 − x` 镜像（Vertical 同理 `y' = 行高 − y`），
**不是**重排列、也不是逐 glyph 翻转（上游就是 push 一个矩阵）。
**我们手里有没有那个量**：**有** —— `FormatParagraph(... paragraphWidthDip ...)` 一直是入参（只是以前没存进行里）。
⇒ 实现 = 存 `_paragraphWidth` + push 矩阵（`DrawCore` 承担真正的绘制，`Draw` 只管 push/pop，与上游同构）。
⇒ **`InvertAxes` 四种取值全部支持，没有一种走降级**（唯一降级分支见下表：段落宽**未知(0)** 时）。

| `InvertAxes` | 我们 | 判据 |
|---|---|---|
| `None` (0) | ✅ 不 push | 与改前一致（`anti == null`） |
| `Horizontal` (1) | ✅ `x' = 段落宽 − x` | P8：绘制树里真有 `M11=-1 OffsetX=380`；P9：run 原点逐位不变 |
| `Vertical` (2) | ✅ `y' = 行高 − y` | P10：`M11=1 M22=-1 OffsetY=21.792` |
| `Both` (3) | ✅ 两者 | P10：`M11=-1 M22=-1 OffsetX=380 OffsetY=21.792` |
| 任意 + **段落宽=0**（未知） | ⚠️ **降级**：不镜像、按 LTR 画 + 计数 `invertedNoWidth` + 前 3 次无条件 stderr | P11 |
| **真 bidi 视觉顺序**（UBA 重排/混合方向行） | ❌ **未实现**（T1c 已判"静默画错"）→ **M–L 独立立项**；本行`invertedLines` 计数 + 文档登记 | §11.4 |

**"同式"是被验证的**：矩阵用公开 API 自建（因为上游函数是 PC 的 internal、反射形态看不见），
**DIRECT 形态下每次都与上游函数逐字段比对**，不一致就计 `antiMatrixMismatch`（实测恒 **0**）。

### 11.3 读数
```
探针（--invert，:95 自起自灭）：
  P7 Draw(Horizontal) 不抛 ✅          P8 真的 push 了镜像矩阵 ✅（M11=-1 OffsetX=380）
  P9 Draw 前后 run 原点/字形数逐位不变 ✅   P10 Vertical/Both 矩阵正确 ✅
  P11 段落宽未知 ⇒ 不抛/不镜像/计数 ✅（invertedNoWidth 0→1，且 stderr 有无条件诊断）
  [读数] invertedLines=4 invertedNoWidth=1 antiMatrixMismatch=0
不回归（run.sh tline，sha 钉 fdffc703…）：
  T1.73 ✅73/73   T2 记账 1286/1298（①286/286 ②68/68 ③984/988 宽度超差 47）
  T2b 972/972·213/213   T2d ✅1298/1298   T3 判定1298/1298 明细218/236   Tab 0 例不一致
  通过 19 / 失败 2（剩 T2 记账、T3 折叠两条既有红）
编译：DIRECT / 反射 / CoverageProbe **各 0 错 0 警**；探针 P1–P6 仍全 PASS
```
### 11.4 牙齿（两条突变，命令可复算）
```bash
cp build/shims/PresentationCore.HbTextLine.cs /tmp/t1d-shim-rtl-baseline.cs
# T1：把"抛 NotSupportedException"放回来（即改前行为）
#     （在 `if (inversion != InvertAxes.None) {` 之后插一行）  throw new NotSupportedException("突变T1：恢复改前的 InvertAxes 限制");
# T2：关掉镜像                （原文）anti = BuildAntiInversion(inversion, _paragraphWidth, _height);
#                             （突变）anti = null;   // 【突变 T2】
cd build/MilBridge/tests/CoverageProbe && dotnet build -c Release -m:1 --nologo
bash build/MilBridge/tools/t1d-probe.sh    # 或直接跑 --invert（见 §11.3）
cp /tmp/t1d-shim-rtl-baseline.cs build/shims/PresentationCore.HbTextLine.cs
```
```
T1（恢复抛异常）：P7 ❌ P8 ❌ P10 ❌ P11 ❌   ⇒ **"不崩"这条判据有牙**
T2（镜像关掉）  ：P7 ✅（不崩）但 P8 ❌ P10 ❌ ⇒ **"真镜像"这条判据也有牙**（不是只看"不抛"）
还原后 sha = fdffc703…（逐字节相同）
```
### 11.5 未做 / 边界
- **真 bidi**（UBA 重排、混合方向行的视觉顺序、阿拉伯字母整形上下文）**未做** —— 独立立项（M–L）。
  现状：RTL 段落**不再崩**、镜像按上游契约做了，但**混合方向行的视觉顺序仍不对**（T1c 判定），
  故 `invertedLines` 计数 + 本节登记；**不声称 RTL 显示正确**。
- M7b 在本文件的两处（`GetTextRunSpans` 一族）**一字未碰**（改前 `grep -an` 取锚点、断言恰好命中 1 次）。
- 顺带记录：本轮期间 `HbTextLineParity` harness 被 T1b 更新过（`T2b` 从 964/965·207/213 变成 **972/972·213/213**、多了 `T2d-lh` 列）——**我贴的读数是更新后那一版**。

---

## 12. P0 线索「同一 TextBox 里 拉丁橙 / CJK 蓝」—— **只读定性**（2026-09-11）

**sha**：`fdffc703…` → **`d197de66f651f95d442db9ddea097f7b3b2b1244d49eaa1ce470797143d8ef6a`**（3708 行）。
**本轮只加"缺省关的只读读数"（站点 D），没有改任何行为。**

### 12.1 判据（先写死，再查）
- **(甲) 子段带着正确的 run 属性** ⇐ 每张子段 `GlyphRun` 都带**它所属源 run 的** `ForegroundBrush`；
  **且**当两个源 run 的 foreground 不同时，两张 `GlyphRunDrawing.ForegroundBrush` **不同**。
- **(乙) 子段丢了 run 属性（静默画错）** ⇐ 存在一张 `GlyphRunDrawing` 的 brush 为 `null`、或等于"别的 run"的 brush。
- ⚠️ **必须与第三种形状分开报**：若**两段都用同一个（第一个 run 的）brush** ⇒ 那**不是"子段丢字段"**，而是
  **行级压平**（结果 = 整行单色）——**它产生不了"同一行两色"**，把它当成"两色的成因"会走错方向。

### 12.2 查代码（file:line）
| 位置 | 事实 |
|---|---|
| `HbTextLine.DrawCore` **:2380** | `drawingContext.DrawGlyphRun(_run.Props != null ? _run.Props.ForegroundBrush : null, gr);` ⇒ **每张子段 run 都用同一把画刷**（行级 `_run.Props`） |
| `HbTextLine.FormatLine` **:2132-2136** | 整行只造**一个** `HbTextRun`，其 props = 传进来的 `runProperties`（或由它构造的 `HbRunProperties`） |
| `HbTextFallback.TryBuildPlan` **:3300** | `primaryProps = runs[0].Props;` ⇒ **整段的多 run 属性被压成第一个 run 的**（`foreground` 也在内），`:3498` 交给 `FormatParagraph` |
| 上游对照 `SimpleTextLine.cs:1740` | `Brush foregroundBrush = TextRun.Properties.ForegroundBrush;` 在 **`SimpleRun.Draw` 内** ⇒ **上游是"每个 run 用自己那把"** ⇒ 我们这条**与上游不一致** |

### 12.3 读数（探针，`:95` 自起自灭；默认档 = 系统字体，R1 真切段）
```
C1（**单 run**·橙，文本 'seed-文本'）：
  [T1D_RUNPROPS] brush=#FFFFA500 face=DejaVuSans.ttf          glyphs=5 chars="seed-"     ← R1 的第 1 段
  [T1D_RUNPROPS] brush=#FFFFA500 face=NotoSansCJK-Regular.ttc glyphs=2 chars="文本"       ← R1 的第 2 段（回退面）
  P12 ✅ 两张子段 run **都带画刷**，且是**同一把** ⇒ **(甲) 对"子段带画刷"成立**；分段本身不产生两色
C2（**两个 run**：run0 橙 'seed-' / run1 **蓝** '文本'）：
  [T1D_RUNPROPS] brush=#FFFFA500 face=DejaVuSans.ttf          glyphs=5 chars="seed-"
  [T1D_RUNPROPS] brush=#FFFFA500 face=NotoSansCJK-Regular.ttc glyphs=2 chars="文本"
  P13 ❌ **第二个 run 的蓝被丢了**（两段都画成第一个 run 的橙）= §12.2 :3300 的行级压平
```
**新增站点 D**（`WPF_LINUX_HBLINE_TRACE=1`，缺省关、独立预算 60）—— 就是给应用级"这一行到底拿了哪把画刷"用的：
```
HBLINE D#0 cpFirst=0 brush=#FFFFA500 glyphRuns=2 [r0 face=DejaVuSans.ttf glyphs=5 chars="seed-"] [r1 face=NotoSansCJK-Regular.ttc glyphs=2 chars="文本"]
```

### 12.4 结论
**(甲) + 一条确认的 #26 同族字段丢**：
1. **R1 的子段带着画刷**（都带，且同一把）⇒ **"同一行两色"不是我们这次分段造出来的** —— 机器读数直接证明（P12）。
2. **但确实存在"投影时丢字段"**：段落里**多个 run 的 `foreground` 被压成第一个 run 的**（`:3300` → `:2132-2136` → `:2380`），
   与上游"每 run 各用各的"（`SimpleTextLine.cs:1740`）不一致。**它的可见后果是"整行变单色"，不是"两色"**。
3. ⇒ T3 观察到的"拉丁橙 / CJK 蓝"**另有来源**，三条候选（都能用站点 D 在应用里一次判掉）：
   **H1** CJK 那部分**不是我们画的**（站点 D 只会为我们的 Draw 打行；若某部分没有 D 行 ⇒ 另有消费者）；
   **H2** 那一段拿到的 brush 是 `null`（= **根本没画**，屏上的蓝是**选中高亮底色**透出来）；
   **H3** 同一视觉行被**两条不同 props 的 TextLine** 画了（会出现两条 cp 重叠、brush 不同的 D 行）。
   ⇒ 需要 **T3 的原始分辨率裁图**（分清"蓝色字形" vs "蓝色块"）+ 一次**同 slot 的应用级复现**（`WPF_LINUX_HBLINE_TRACE=1`）才能钉。

### 12.5 建议的修法（**等主控裁决，本轮未动**）
**"每 run 各用各的 foreground"**（把 §12.2 的压平改成逐段）：
- `HbFontSegment` 已有 `FaceSlot`，再加 `RunSlot`（= 该码点所属 run 的序号，`HbFontPlanner.Build` 里从 `HbRunFaceInfo` 带上）；
- `HbShapedChunk` 带 `RunSlot`；`HbTextLine` 存 `Brush[] runBrushes`（来自每个 run 的 props）；`DrawCore` 用 `runBrushes[chunk.RunSlot]`；
- `HbTextLineFactory.FormatParagraph` 增一个 `TextRunProperties[] runProps` 入参（不传 ⇒ 与今天逐位相同）。
**风险与边界**：`GetTextRunSpans()` 也有同样的压平（它只报一个 span），**那正是 M7b 改过的两处** ⇒ 若一起改**必须与 M7b 排波序**（本轮我**一字未碰**）。

### 12.6 修法已落：**per-run foreground**（主控批准；2026-09-11）

**sha**：`d197de66…` → **`ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf`**（3766 行）。

**改了什么**（只动"每段用哪把画刷"，`GetTextRunSpans()` **一字未碰**）
- `HbRunFaceInfo` / `HbFontSegment` / `HbShapedChunk` 各加 `RunSlot`（= 该段属于**哪个源 run**）；
  `Sub()` 的合并条件与分段合并条件都带上它 ⇒ **不会把两个 run 的段并掉**；
- `HbTextLine` 新增 `_runBrushes`（逐 run 的 `ForegroundBrush`）与 `_glyphRunRunSlot`（每张 GlyphRun → run 序号），
  `DrawCore` 改用 `BrushForRunIndex(i)`；
- `FormatLine` / `FormatParagraph` 新增可选 `TextRunProperties[] runProps`；**不传 ⇒ `_runBrushes == null` ⇒ 回落行级画刷 = 与今天逐位相同**；
- `TryBuildPlan` 回传逐 run 的 props 数组（`RunSlot = ri`）。
- **语义**：**面可以被回退换掉，前景色永远跟着源 run 走**（上游 `SimpleTextLine.cs:1740` 就是在 `SimpleRun.Draw` 内取本 run 的 brush）。

**读数（判据①，探针默认档 = 真切段）**
```
C1 单 run·橙： face=DejaVuSans.ttf brush=#FFFFA500 "seed-"   +   face=NotoSansCJK-Regular.ttc brush=#FFFFA500 "文本"   ⇒ P12 ✅
C2 两 run（橙+蓝）： face=DejaVuSans.ttf brush=#FFFFA500 "seed-"   +   face=NotoSansCJK-Regular.ttc brush=**#FF0000FF** "文本"
   ⇒ P13 **❌ → ✅**（第二个 run 的蓝活着；且它用的是**回退面**却仍是**自己 run 的**颜色）
```

**牙齿（判据③）**
```
突变 T3：`RunSlot = ri` → `RunSlot = -1`（关掉传递）⇒ C2 两张又都变 #FFFFA500 ⇒ P13 **❌**
还原后 sha 逐字节回到 ebccdb1e…
```

**不回归（判据②）**：`T1.73 ✅73/73`、`T2 记账 1286/1298`（①286/286 ②68/68 ③984/988 宽度超差 47）、
`T2b 972/972·213/213`、`T2d ✅1298/1298`、`T3 判定1298/1298 明细218/236`、`Tab 0 例不一致`、通过19/失败2；
编译 `DirectBranchCheck` / `HbTextLineParity` / `CoverageProbe` **各 0 错 0 警**。

**仍然分开的一条**（保持口径，别混读）：**"同一 TextBox 两色"仍未裁定**（H1/H2/H3 已排给 T3）。
本节修的是**已确证的"行级压平"（后果 = 整行单色）**，**不是**"把两色修好了"。

---

## 13. 收口（2026-09-13）：per-run 前景色 + `.notdef` bbox 线索定位

> ### 状态行
> **已钉**：① per-run 前景色（`RunSlot`）**已落完整套**，四条自检全过（原始输出见 13.1）；② `.notdef` bbox 假设 = **否证**，真因 = **harness 单字体路径没有 CJK 回退**（13.2，决定性实验 2 条）。
> **未完成 + 缺什么读数**：harness 的 `Extent 1260/1298`（**容差 0.01**）里，**34 条**已定位（= 全部含 CJK 的行）；**剩 4 条是 0.01–0.34 的近差，未定位** —— 缺的读数是 **harness 逐行 |ΔExtent| 的 top-N + 用例/行号**（该 harness 只打聚合数；我这边要跑 600+ 次探针才能复现，本机有外来构建在吃 CPU，故未做）。
> **版本纪律**：本节所有读数都在 **`ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf`（3766 行）** 上重取；T1b 的 58 条（38+20）测于同一 sha，我早先报的 39 条测于 `d197de66…` —— **两数不混用**。
> **本轮未跑应用、未重建 PC、未发桥**；`GetTextRunSpans()`（M7b 的两处）**一字未碰**。

### 13.1 per-run 前景色：落点 + 四条自检（原始输出）
**落点**（本 shim）：`HbRunFaceInfo.RunSlot`（:1077 区）→ `HbFontSegment.RunSlot`（:139）→ `Sub()`/分段合并条件都带上它 →
`HbShapedChunk.RunSlot` → `HbTextLine._runBrushes/_glyphRunRunSlot`（:1938 区）+ `BrushForRunIndex()` → `DrawCore`
（`:2380` 改为 `DrawGlyphRun(BrushForRunIndex(i), drawn[i])`）；`FormatLine`/`FormatParagraph` 新增可选
`TextRunProperties[] runProps`（**不传 ⇒ `_runBrushes == null` ⇒ 回落行级画刷**）；`TryBuildPlan` 回传逐 run props（`RunSlot = ri`）。

**① 两趟画刷必须不同（C2：run0 橙 / run1 蓝）—— 贴实际取到的值**（`CoverageProbe --runprops`，默认档 = 系统字体，R1 真切段）：
```
[T1D_RUNPROPS] C1(单run·橙) brush=#FFFFA500 face=DejaVuSans.ttf          glyphs=5 chars="seed-"
[T1D_RUNPROPS] C1(单run·橙) brush=#FFFFA500 face=NotoSansCJK-Regular.ttc glyphs=2 chars="文本"
  PASS  P12 单 run 的两个子段都带画刷、且同一把
[T1D_RUNPROPS] C2(两run·橙+蓝) brush=#FFFFA500 face=DejaVuSans.ttf          glyphs=5 chars="seed-"
[T1D_RUNPROPS] C2(两run·橙+蓝) brush=#FF0000FF face=NotoSansCJK-Regular.ttc glyphs=2 chars="文本"
  PASS  P13 **两趟画刷不同**：拉丁段 #FFFFA500（run0 的橙）、CJK 段 #FF0000FF（run1 的蓝）
```
（注意：CJK 段用的是**回退面**却仍是**自己 run 的**颜色 ⇒ "面可以回退，颜色跟着源 run"。）

**② 不传新入参 ⇒ 与今天逐位相同**（harness 走的正是这条：它只传老参数）：
改前 `fdffc703…` 与改后 `ebccdb1e…` 的 `HbTextLineParity` 输出**逐字节 diff**，差异**只有 4 行、全是 `T0.6` 的 sha 行**：
```
diff <(grep -av 'sha256\|被测文件\|build/shims' /tmp/t1d-rtl.txt) <(grep -av … /tmp/t1d-brush.txt) ⇒ 仅 2 行 sha 对（固定=…/实读=…）
```

**③ 六个 tline 项**（`ebccdb1e…`，sha 已钉）：`T1.73 ✅73/73`、`T2 记账 1286/1298`（①286/286 ②68/68 ③984/988 宽度超差 47）、
`T2b 972/972·213/213`、`T2d ✅1298/1298`、`T3 判定1298/1298 明细218/236`、`Tab 0 例不一致`、通过19/失败2。
**三形态 0 错 0 警**：`DirectBranchCheck` / `HbTextLineParity` / `CoverageProbe` 各 `0 个错误 0 个警告`。

**④ 牙齿**：突变 `RunSlot = ri` → `RunSlot = -1`（关掉传递）⇒ C2 两张又都变 `#FFFFA500` ⇒ **P13 ❌**；还原后 sha 逐字节回到 `ebccdb1e…`。

### 13.2 `.notdef`（glyph 0）bbox 线索 —— **否证 + 真因定位**
**判据**：先问"那 2.6619 的差额是否由 `.notdef` 的 bbox 没算进 ink 解释"。

**(a) 公式核对**（`build/MilBridge/tests/BboxProbe/Program.cs:40` 写的是 `y_bearing + height`，那是**下伸**；上伸应为 `y_bearing`）。
我用**修正后**的口径逐字形实测（`NotoSans-Regular.ttf`，upem=1000，em=16；脚本 `/tmp/t1d-notdef.py`）：
```
'T'(gid55)   上伸(y_bearing)=11.4240 下伸=-(y_bearing+height)=0.0000 raw=(xb=10, yb=714, w=535, h=-714)
'n'(gid81)   上伸= 8.7360 下伸=0.0000                       raw=(xb=85, yb=546, w=452, h=-546)
'('(gid11)   上伸=11.4240 下伸=2.5280                       raw=(xb=40, yb=714, w=230, h=-872)
SPACE(gid3)  上伸= 0.0000 下伸=0.0000                       raw=(0,0,0,0)      ⇒ 无墨迹（advance 也 0）
**.notdef(gid0) 上伸=11.4240 下伸=0.0000**                  raw=(xb=94, yb=714, w=411, h=-714)  ⇒ **.notdef 是有墨迹的方框（0.714em 高）**
```
**(b) 逐行 glyph id 全序列 + 每个 glyph 的 bbox**（读数来源：`CoverageProbe --inkdiag`，它按 run 打
`inkBox=… h=… face=… glyphIds=[全序列] chars=…`，另打前 4 个 glyph 的 provider 度量；文本/宽度/em 由 `--text/--width/--em` 给）：
```
行 '与 '      ⇒ 我们 Extent=**13.4240**；glyphIds=[0,3] chars=与␠；inkBox=(0.504,-12.424)-(9.080,1.000) h=13.424
                  g0(.notdef): aw=9.600 lsb=1.504 rsb=1.520 tsb=0.496 bsb=0.496（**非退化 ⇒ 有墨迹、被算进去了**）
行 '与 zero' ⇒ 我们 Extent=13.5840；glyphIds=[0,3,93,72,85,82,3]
行 'nbsp 与 '⇒ 我们 Extent=18.0000；glyphIds=[81,69,86,83,3,0,3]
```
⇒ **.notdef 的墨迹并没有被漏算**：它的盒子确实进了我们的 ink box（13.424 = HB 纯墨迹 11.424 + provider 度量路径的 +2.000 垫值；
同一 +2.000 在拉丁行上也在：HB 16.0800 vs 我们/真值 18.0800）。

**(c) 决定性实验（把"真因"钉出来）**：给 `与` 一个**真 CJK 面**（字体目录 = `build/fonts:/usr/share/fonts/opentype/noto`
⇒ UI 面仍是 Noto Sans，但候选集合里有 Noto CJK ⇒ R1 回退），同一文本重测：
```
'与 '      ⇒ 我们 Extent=**16.2080**（真值 16.0859，Δ=+0.1221 ✓ 容差内）；r0 face=NotoSansCJK-Regular.ttc glyphIds=[9498]
'nbsp 与 ' ⇒ 我们 Extent=**18.9280**（真值 19.0744，Δ=−0.1464 ✓）；r1 face=NotoSansCJK-Regular.ttc
```
**(d) 全量复测（当前 shim，`ebccdb1e…`）**：34 个 nbsp/zwsp 用例、114 条可判行 ⇒
**超容差（0.34）34 条，且 34 条全部是含 `与` 的行；不含 `与` 的行 0 条超差**；
而 34 例里含 `与` 的行总数恰好 = **34** ⇒ **100% 命中、0% 误伤**。
> ⚠️ 与 harness 的 38 条对不上是**容差不同**：harness 的 `T2d` 用 **0.01 DIP**（`de < 0.01`），我用项目口径 **0.34**。

### 13.3 结论（按你要求给"是/否/未判定"）
1. **"2.6619 由 `.notdef` bbox 漏算解释" = 否（否证）**：`.notdef` 有墨迹（0.714em=11.424@16px）且**已被算进**我们的 ink box；
   真正成因是 **真机（Windows）把 `与` 交给了 CJK 回退面**，而 `run.sh tline` 走的是**单字体入口**（R1 的刻意边界：按码点回退只在 run 感知/应用路径生效）
   ⇒ 那 34 条在 harness 里**结构上不可能对齐**。给 CJK 面之后 Δ 只有 0.12/0.15 ✓。
2. **"R1 的应用路径是否因此受益"**：是 —— 同一文本在**应用路径**（`TryFormatLine`）下已回退到 CJK 面（上表 r0 face=NotoSansCJK）。
   若要把这 34 条在 harness 里也对齐，**需要主控裁决**：给 harness 的单字体入口开"回退"= 会改变 `T1.73/T2/T2b/T2d` 的既有基线（我**没动**）。
3. **未判定**：harness 38 条里的另 **4 条**（0.01–0.34 的近差）。**缺的读数** = harness 逐行 `|ΔExtent|` 的 top-N + 用例/行号
   （harness 只打聚合；用探针复现要 600+ 次运行，本机有外来构建在吃 CPU，故未做）。

---

## 14. `.notdef` / CJK 行的 `Extent`：**结构性不可比**登记（主控裁决 2026-09-13）

### 14.1 原读数（当前 shim `ebccdb1e…`，可复算）
34 个 `*_nbsp_zwsp_*` 用例（文本 `'no\xa0break\xa0nbsp 与 zero\u200bwidth\u200bspace'`，`fontKey=file` = Noto Sans）：
```
34 例 · 114 条可判行（容差 0.34 DIP）
超容差 = **34 条**，且 **34 条全部是含 '与' 的行**；不含 '与' 的行 **0 条**超差
34 例里含 '与' 的行总数 = **34**            ⇒ **100% 命中 / 0% 误伤**
真值 ext 取值集合 = {16.0859, 19.0744}；给 与 一个真 CJK 面后我们 = {16.2080, 18.9280} ⇒ Δ = +0.1221 / −0.1464（容差内）
```
逐行明细（`--inkdiag`，含 glyid 全序列）：`'与 '` → `glyphIds=[0,3]`、我们 `Extent=13.4240`、inkBox `h=13.424`
（= HB 纯墨迹 11.424 + provider 度量路径 **+2.000** 垫值）；`'nbsp 与 '` → `glyphIds=[81,69,86,83,3,0,3]`、我们 `18.0000`。
**⇒ 假设"`.notdef` 的 bbox 没被算进 ink 上伸" = 否证**（`.notdef` 有墨迹 0.714em，且确实进了盒子）。

### 14.2 裁决（主控原文）
> 判定："**否证**"接受；真因"**harness 单字体入口按 R1 边界不回退、真机有 CJK 回退**"接受，因为你的决定性实验（给 `与` 一个真 CJK 面 ⇒ Δ 从 +2.66 掉到 ±0.15）**是双向的**。
> **裁决：不给单字体入口开回退**（会动 `T1.73/T2/T2b/T2d` 四条基线，且 harness 的边界是刻意设计的）。那 34 条**按"结构性不可比"登记**，**不**记为缺陷。

⇒ 本报告据此登记：**34 条 = 结构性不可比（不是缺陷、不是欠账、不需要修）**，理由是"oracle 的真值来自**有 CJK 复合字体回退**的真机文本栈，
而 `run.sh tline` 走的是**刻意不回落**的单字体入口"；两者的差**只出现在含 CJK 的行**（100% 命中、0% 误伤）。

### 14.3 将来若要"真对齐"（**不要放宽 harness**）
1. **走应用级/多面入口**：真值口径本来就是"真机复合字体回退之后的墨迹" ⇒ 对齐必须在**有回退的入口**上做
   （应用路径 `TryFormatLine` + R1 的按码点回退，或专门造一个"多面 oracle"），**不是**把 harness 的单字体入口改成会回退
   （那等于换掉 `T1.73/T2/T2b/T2d` 的判据基线，属于"为了变绿改判据"）。
2. 若确实要一条**可判的**读数：把这类用例单独成组（例如 `*-cjkfallback-*`）并在**应用级普查**里比 `Extent`，
   期望值就是 §14.1 里那两条（16.2080 / 18.9280，容差 0.34）。
3. **不许**把 34 条从 harness 里"删掉/跳过"来让数字变好看（保持"保留红 + 登记"的既有形态）。

---

## 15. "Latin 一段色 / CJK 另一段色"：**可读判据 + 应用级期望值**（H1/H2/H3）

### 15.1 harness 级已判：逐 run 颜色**已经是对的**
```
C2（两个源 run：run0 'seed-' 橙 / run1 '文本' 蓝）:
  [T1D_RUNPROPS] brush=#FFFFA500 face=DejaVuSans.ttf          glyphs=5 chars="seed-"   ⇒ run0 的橙
  [T1D_RUNPROPS] brush=#FF0000FF face=NotoSansCJK-Regular.ttc glyphs=2 chars="文本"     ⇒ run1 的蓝（且用的是回退面）
  PASS P13（改前是 FAIL：两张都 #FFFFA500）
C1（**一个**源 run，橙）:
  两张子段都 = #FFFFA500（面不同：DejaVu + Noto CJK）  ⇒ PASS P12
```

### 15.2 规则（照这五条判，够用且互斥）
| # | 规则 | 判定 |
|---|---|---|
| **R1** | 同一视觉行里两段**颜色不同** ⟺ 它们属于**不同的源 run** 且那两个 run 的 `TextRunProperties.ForegroundBrush` 不同 | **正确** |
| **R2** | **同一个源 run** 被 R1 按码点切成多段（回退面）⇒ 各段**必须同色**，**面可以不同** | **正确** |
| **R3** | 两段 **`RunSlot` 相同**（同一源 run）却颜色不同 ⇒ **我们错**（分段或画刷传递） | **错** |
| **R4** | 应用只给了**一个** run（或两个 run 的 `Foreground` 相同）却看到两色 ⇒ **颜色不是我们画的** ⇒ 转 H1/H3（另有消费者 / 选中高亮底 / 另一条 TextLine） | **错（但不是本 shim 的 Draw）** |
| **R5** | **app-local PC 比 shim 源旧** ⇒ 本次应用级颜色读数**无效**，先重建再判 | **判不了** |

### 15.3 PC 重建后，应用级**应当**看到什么（期望值）
以 `TextBox` 文本 `'seed-文本'`、`Foreground=#F97316`、`selLen=7`（整串选中）为例：
1. **站点 D 应当为每一行各打 1 条**（或按段落缓存的行数），且该行内**所有** `HBLINE D#` 的 `brush=` **相同**
   （= 若应用只给了 1 个 run）——例如 `brush=#FFF97316`；
2. 同一行内 `glyphRuns` 可以是 **2**（拉丁段 DejaVu + CJK 段 Noto CJK）而 `brush` **仍相同** ⇒ 符合 **R2**；
3. 若某段**没有**对应的 D 行 ⇒ 那部分**不是我们画的** ⇒ **H1**；
4. 若某条 D 行的 `brush=<null：等于不画>` ⇒ 该段**根本没画**，屏上的蓝是**选中高亮底**透出来 ⇒ **H2**
   （与 `selLen=7` 的观测自洽）；
5. 若同一视觉区域出现**两条 `cp` 重叠、`brush` 不同**的 D 行 ⇒ 同一行被**两条 TextLine**画了 ⇒ **H3**。

### 15.4 排查顺序（若不符，按这个顺序判）
```
0) 先判"取旧件"：stat/sha 比 app-local PC 与 shim 源（§16 第 0 条）—— 旧就先重建，别下结论（R5）
1) 再判"分段错"：D 行里各段的 cp 区间必须**恰好铺满**该行可见区间一次（无空洞/无重叠），
   且 chars= 顺序拼起来 == 该行文本；不满足 ⇒ 是分段错（本 shim 车道）
2) 再判"画刷错"：把每条 D 行的 brush= 与该行**源 run 的 Foreground** 对照
   （单 run ⇒ 全部相同；多 run ⇒ 各自相同）；不符 ⇒ 画刷错（本 shim 车道）
3) 上面两条都过 ⇒ 颜色来自**别处**：按 §15.3 的 3/4/5 分 H1 / H2 / H3（那不是本 shim 的 Draw）
```

---

## 16. **PC 重建后逐条复验清单**（命令 + 期望读数 + 判定）

> 前提：本章命令都在仓库根 `<repo>` 下跑；`export PATH="$HOME/.dotnet:$PATH"`；**`-m:1`**；
> 应用级项需要 **T3 的 slot**（我不抢）。

| # | 命令 | 期望读数 | 判定 |
|---|---|---|---|
| **0** | `sha256sum build/shims/PresentationCore.HbTextLine.cs build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` + `stat -c '%y %n'` 两者 | shim=`ebccdb1e…`；**PC 的 mtime 必须比 shim 新**（重建前的原文：PC `00:00:23.362964668` **旧于** shim `00:36:31.032156734`） | 若 PC 仍旧 ⇒ **取旧件**，后面一律不判（R5） |
| **1** | 三形态编译：`cd build/MilBridge/tests/{DirectBranchCheck,HbTextLineParity,CoverageProbe} && dotnet build -c Release -m:1 --nologo` | 各 **`0 个错误 0 个警告`** | 任一非 0 ⇒ 停，先修编译 |
| **2** | 两趟画刷：起 `Xvfb :95`（按 PID 收尾）后 `cd build/MilBridge/tests/CoverageProbe/bin/Release && DISPLAY=:95 dotnet PresentationCore.Tests.dll --scenario single --width 380 --runprops` | `C2: brush=#FFFFA500 …"seed-"` 与 `brush=#FF0000FF …"文本"`；**P13 PASS**（C1 两段同色同刷：P12 PASS） | 两趟**必须不同**；若又相同 ⇒ per-run 画刷回退，红 |
| **3** | 六项不回归：`bash build/MilBridge/run.sh tline` | `T1.73 ✅73/73`；`T2 记账 1286/1298`（①286/286 ②68/68 ③984/988 宽度超差 47）；`T2b 972/972·213/213`；`T2d ✅1298/1298`；`T3 判定1298/1298 明细218/236`；`Tab 0 例不一致`；通过19/失败2 | 任一项比上面差 ⇒ 红（变好也请标注来源，别记到本车道） |
| **4** | 站点 D（应用级，需 slot）：`WPF_LINUX_HBLINE_TRACE=1` 起 `WpfTextDemo`/`WpfFeatureProbe` | 每行 ≥1 条 `HBLINE D#… brush=…`；同一行内 brush 应相同（单 run 时） | 按 §15.2 的 R1–R5 判；**注意**：`WPF_LINUX_*` 会被 T3 的 runner 清空 ⇒ 用能注入 env 的装置（如 `t1c-census.sh` 的 `EXTRA_ENV`） |
| **5** | 应用级普查（需 slot）：`t1c-census.sh <outdir> default WPF_LINUX_GLYPH_CENSUS=1 WPF_LINUX_HBLINE_TRACE=1` | `id0≈0 / nonlatin>0 / maxid≈63151`；`未画种类 0`；并**读图** | 颜色问题按 §15.4 顺序；`未画种类` 非 0 ⇒ 先停下报主控 |
| **6** | 牙齿（可选，验证判据仍有牙）：临时把 `RunSlot = ri` 改成 `-1` ⇒ 复跑 #2 | C2 两张又都 `#FFFFA500`、**P13 FAIL** | 若突变后仍 PASS ⇒ 判据没牙（红）；**改完必须还原并核对 sha 逐字节回 `ebccdb1e…`** |
