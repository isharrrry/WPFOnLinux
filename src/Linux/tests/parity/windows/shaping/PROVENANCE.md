# U1 轨道 D · DirectWrite shaping 真值（oracle）

> 结论先行：**在本语料上，DirectWrite 与 HarfBuzz(14.4.0) 逐字形、逐 advance、
> 逐 cluster **完全一致**（56/56 用例，最大 advance 差 1e-06 DIP）**。
> 这份真值可以直接当作"路线 B（用 HarfBuzz 做真 shaping）对不对"的判据。

## 1. 生产环境（可追溯）

| 项 | 值 |
|---|---|
| 机器 | `bilintu\pc@192.168.193.97`，Windows 11 23H2 `10.0.22631.2428`，x64 |
| 引擎 | **DirectWrite**，`dwrite.dll` 文件版本 `10.0.22621.4745` |
| .NET SDK | 10.0.203（`net10.0-windows`，纯托管，无 NuGet 依赖） |
| 工作目录 | `C:\u1-shaping\`（与 `C:\u1-parity\`、`C:\u1-geom\` 并列，跑完已清理） |
| 生成时间 | 2026-09-10（`generatedUtc` 在 JSON 里） |

## 2. 字体：与 Linux 侧 `build/fonts/` **同一份文件**

字体**没有安装到系统**（`C:\Windows\Fonts` 里没有 Noto），而是用
`IDWriteFactory::CreateFontFileReference(<路径>) + CreateFontFace(...)` **直接从文件加载**，
所以不可能"撞上系统里同名但不同内容的字体"。两侧 sha256 实测一致：

| 文件 | sha256（Linux `build/fonts/` 与 `C:\u1-shaping\fonts\` 相同） |
|---|---|
| `NotoSans-Regular.ttf` | `f3961a9cde016d41a4879aecda1474d3a36d6bf54fa0e4643de029cc2248b0e8` |
| `NotoSans-Bold.ttf` | `87cb2d84472a7d66da659ee47b6cdb9552326e8c128245231f191b6ac72529d9` |
| `NotoSans-Italic.ttf` | `678288f868807d4d64a6f3b51466871d117d915780381ce9d0ed4b3bcbd06d37` |
| `NotoSans-BoldItalic.ttf` | `3d367743f371f28671d2764e911a53d7c20ec9b6aa8791d059e7090389fc52a5` |

（每个用例的 JSON 里都带 `fontSha256`，可逐个复核。）

## 3. API 调用序列（逐字节可复现）

```
DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, IID_IDWriteFactory)
IDWriteFactory::CreateFontFileReference(<我们自己的 ttf 路径>)
IDWriteFactory::CreateFontFace(DWRITE_FONT_FACE_TYPE_TRUETYPE, 1, {file}, 0, DWRITE_FONT_SIMULATIONS_NONE)
IDWriteFontFace::GetMetrics / GetGlyphCount
IDWriteFactory::CreateTextAnalyzer
IDWriteTextAnalyzer::GetGlyphs          (shaping / GSUB)
IDWriteTextAnalyzer::GetGlyphPlacements (positioning / GPOS，即 kerning)
```

* `script = 0, shapes = DWRITE_SCRIPT_SHAPES_DEFAULT`，`localeName = "en-us"`，
  **不传 `DWRITE_TYPOGRAPHIC_FEATURES`** ⇒ 用字体默认特性（kern/liga/clig 打开，与 HarfBuzz 默认一致）。
* **没有用 `IDWriteTextLayout`**：layout 需要 `IDWriteTextFormat`，而 format 需要字体能在一个
  font collection 里被解析；字体是刻意不安装的（装字体=改系统）。`IDWriteTextAnalyzer` 是
  WPF/DWrite 真正做 shaping 的那一层，取到的就是 shaping 真值。
  行高因此是**推导值**：`(ascent+descent+lineGap)*emSize/upem`，来自 `IDWriteFontFace::GetMetrics`
  （不是 layout 的 `GetMetrics`）——JSON 里字段名与 `lineHeightNote` 都写明了。

### 踩坑记录（对后来者有用）

vtable 槽位必须按 **Windows SDK 的 `dwrite.h`**（含 3 个 IUnknown 槽）：
`IDWriteFactory`: CreateFontFileReference=7, CreateFontFace=9, **CreateTextAnalyzer=21**；
`IDWriteFontFace`: GetType=3, GetMetrics=8, GetGlyphCount=9；
`IDWriteTextAnalyzer`: **GetGlyphs=7, GetGlyphPlacements=8**（3..6 是 Analyze*）。
槽位错一个就是 `0xC0000409` 栈损坏或静默返回垃圾 HRESULT。
另外 `GetGlyphPlacements` 在 `fontFace` 之后有一个 **`FLOAT fontEmSize`** 参数，
`GetGlyphs` 第 8 个参数是 `IDWriteNumberSubstitution*`（不是 typography）——
少一个/错一个，advance 全为 0。
权威表已随源码留档：`src/SDK_dwrite.h.reference`（来自 NuGet 包
`Microsoft.Windows.SDK.CPP 10.0.29648.1000-preview` 的 `um/dwrite.h`）。

## 4. 语料（固定、可复现）

字体 4 款 × 字号 2 档（**24 / 11 DIP**，与既有 golden 一致）× 文本 7 条 = **56 个用例**。

| id | 文本 | 覆盖意图 |
|---|---|---|
| `ascii-basic` | `Hello WPF on Linux` | 纯 ASCII 含空格（就是既有宽度测量用的那串） |
| `kerning` | `AV Ta To r. P.` | 经典 kerning 对 |
| `kerning-wide` | `AVATAR To Yo Wa LT` | 更多 kerning 对 |
| `ligatures` | `ffi fi fl office affluent` | 标准连字 ffi/fi/fl，含词中 |
| `mixed-cjk` | `WPF 在 Linux 上渲染文本` | 拉丁 + CJK 边界（**见 §6 注意**） |
| `punct-digits` | `Test, 123.45; (a-b) [c]!` | 标点/数字/括号/连字符 |
| `pangram` | `The quick brown fox jumps over the lazy dog` | 通用拉丁覆盖 |

## 5. 字段含义（`out/dwrite-shaping-oracle.json`）

| 字段 | 含义 |
|---|---|
| `glyphIds` | 字形 id 序列（GSUB 之后） |
| `advancesDip` | 每个字形的步进，单位 DIP（=96dpi 下的 px），`GetGlyphPlacements` 原值 |
| `offsetsDip` | 每个字形的 `{x,y}` 偏移（GPOS mark 定位用） |
| `textToGlyphMap` | **DWrite 原义**：按**文本位置**索引，值是**字形序号**（长度 = 文本长度） |
| `glyphToClusterMap` | 上面那张表的反查（按字形索引 → 首个文本位置），**与 HarfBuzz 的 cluster 同向** |
| `totalAdvanceDip` / `totalAdvanceDesignUnits` | 行宽（DIP / 设计单位） |
| `upem`,`ascentDip`,`descentDip`,`lineGapDip`,`lineHeightDip` | 字体度量（后四个已按 emSize 缩放） |
| `notdefGlyphs` | 映射到 `.notdef`(0) 的字形数 |
| `note` | 连字是否发生、notdef 提示 |

**注意 cluster 方向**：DWrite `GetGlyphs` 的 `clusterMap` 是 `_Out_writes_(textLength)`，
即**文本→字形**；HarfBuzz 给的是**字形→文本**。两份方向不同，别直接比——
`glyphToClusterMap` 才是可比的那一份。

## 6. 与 HarfBuzz 的对拍结果（`out/hb-comparison.json` / `.txt`）

HarfBuzz 用 `uharfbuzz 0.56.1`（**HarfBuzz 14.4.0**），同一份 ttf、`guess_segment_properties()`、默认特性：

| 指标 | 结果 |
|---|---|
| 用例数 | 56 |
| **字形序列完全一致** | **56 / 56** |
| **cluster 序列完全一致** | **56 / 56** |
| **advance 完全一致** | **56 / 56**（逐字形最大差 **1e-06 DIP**，纯浮点舍入） |
| 总宽最大差 | **9e-06 DIP** |
| 明确不一致的用例 | **0** |

对照证据（证明 HB 确实在 shaping，不是碰巧）：

| 文本 | 默认特性 | 关掉 `liga/clig/kern` |
|---|---|---|
| `ffi fi fl` | **5** 字形 `[1656,3,1654,3,1655]` | 9 字形 `[73,73,76,3,73,76,3,73,79]` |
| `AV` | 合计 **1199** 单位 | 合计 1239 单位（差 40 = kerning） |
| `AVATAR` | 合计 **3475** | 合计 3695（差 220） |

DWrite 侧同串给出**完全相同的**字形 id（1656/1654/1655）与相同 advance。

### 结论：能对拍 / 不能对拍

* **能对拍**：字形 id 序列、逐字形 advance、cluster、行宽、字体度量。这四项在本语料上
  DWrite 与 HB **零差异**，可以直接当判据。
* **不能对拍（本轮未覆盖）**：
  * **行高**：DWrite 侧是推导值（见 §3），不是 layout 真值；要 layout 真值必须让字体进
    font collection（安装字体=改系统，越界）或实现 `IDWriteFontCollectionLoader` 回调（未做）。
  * **CJK 真值**：`mixed-cjk` 有 6 个字映射到 `.notdef` —— `NotoSans-*.ttf` 本身**不含 CJK 字形**，
    所以这条只覆盖"拉丁 + 未映射字符"的边界行为，**不是 CJK shaping 真值**。需要 CJK 覆盖时
    请换成含 CJK 的字体（同样是"从文件加载"的路径即可），语料 ID 也要相应改名。
  * **双向文本 (bidi)、复杂脚本 (Arabic/Devanagari)、variation/`locl`/`vert` 等非默认特性**：
    本轮语料与调用都没覆盖（script 固定为 0、无 features 数组、无 bidi 分段）。
  * **hinting / 取整 / 次像素定位**：本 oracle 取的是设计单位级 shaping 结果，
    不含 GDI 兼容取整（那是 `GetGdiCompatibleGlyphPlacements`）。

## 7. 可复现步骤

```powershell
# Windows 侧（结果已在 out/ 里，无需重跑；重跑会得到逐字节相同的数据）
copy <repo>/build/fonts/NotoSans-*.ttf  C:\u1-shaping\fonts\
cd C:\u1-shaping\src ; dotnet build ; powershell -File generate.ps1
```

```bash
# Linux 侧对拍（只装 /tmp 下的 uharfbuzz，不动系统）
PYTHONPATH=/tmp/u1/hb python3 src/compare_hb.py out/dwrite-shaping-oracle.json <repo>/build/fonts out/hb-comparison.json
```

**已知环境问题**：`ShapingOracle.exe` 大约有 **一半的进程启动**会在
`IDWriteFontFace::GetMetrics` 上失败（返回**垃圾 HRESULT**，形如 `0xafc02240`，
四个字体会各自给出不同垃圾值）。同一个进程内一旦失败就全失败，再次启动就可能正常。
根因未定位（已排除：槽位、结构体布局、delegate 编组——换成 `delegate* unmanaged` 逐字节函数指针后依旧）。
`generate.ps1` 因此**带进程级重试**：反复启动直到跑满 56 个用例。
**两次成功的运行，用例数据逐字节相同**（除 `generatedUtc` 字段），已在生成脚本里自动校验。
对拍时若只需数据，直接用 `out/` 里这份即可。

---

# 追加 1 · layout 级真值（换行 + 行高）—— `out-layout/`

> 这是 **B2（`GetTextLineBreak` 换行）的判据**。任务 1，2026-09-11 交付。

## A1.1 怎么拿到未安装字体的 layout
`IDWriteTextLayout` 需要 `IDWriteTextFormat`，而 format 需要字体在一个 font collection 里。
**没有安装字体、没有改注册表**，而是实现了最小的一套 COM 回调把 TTF 直接喂给 DWrite：

| 实现的接口 | 方法数 | 作用 |
|---|---|---|
| `IDWriteFontCollectionLoader` | 1（`CreateEnumeratorFromKey`） | 按 4 字节 collection key 造枚举器 |
| `IDWriteFontFileEnumerator` | 2（`MoveNext` / `GetCurrentFontFile`） | 逐个交出 `IDWriteFontFile` |
| `IDWriteFontFileLoader` | 1（`CreateStreamFromKey`） | 按 key 造文件流 |
| `IDWriteFontFileStream` | 4（`ReadFileFragment` / `ReleaseFileFragment` / `GetFileSize` / `GetLastWriteTime`） | 从**pin 住的托管字节数组**直接回指针 |

COM 服务器是**手工搭的**（`[UnmanagedCallersOnly]` + 自建 vtable），不用 CCW / `[ComImport]` ——
上轮实测这台机器上 `[ComImport]` 编组会 `0xC0000005`。**引用计数只加减、永不 free**
（短命 oracle 进程，泄漏无害，换掉的是最难查的 use-after-free）。
字体字节用 `GCHandle.Alloc(..., Pinned)` **全程保活**（`ReadFileFragment` 回的是裸指针，这是硬要求）。

实测回调计数（证明链路真的跑起来了，不是"看起来成功"）：
`CreateEnum=1 MoveNext=5 GetCurrent=4 CreateStream=4 ReadFrag=96 GetSize=4 RelFrag=4`，
且 `FindFamilyName("Noto Sans")` → **exists=True**（family name 是**验证**出来的，不是猜的；找不到就报错退出）。

调用序列：
```
RegisterFontCollectionLoader(5) + RegisterFontFileLoader(13)
CreateCustomFontCollection(4)            -> collection
FindFamilyName(collection, "Noto Sans")  -> 验证
CreateTextFormat(15)  + TextFormat::SetWordWrapping(5) = WRAP
CreateTextLayout(18)  with maxWidth = 容器宽
TextLayout::GetMetrics(60) / GetLineMetrics(59) / HitTestTextRange(66) / HitTestTextPosition(65)
```

## A1.2 槽位（这次全对，附踩坑）
工厂槽位**权威顺序**（SDK `dwrite.h`，含 3 个 IUnknown 槽）：
`4 CreateCustomFontCollection / 5 RegisterFontCollectionLoader / 6 UnregisterFontCollectionLoader /
7 CreateFontFileReference / **8 CreateCustomFontFileReference** / 9 CreateFontFace / 13 RegisterFontFileLoader /
14 UnregisterFontFileLoader / **15 CreateTextFormat** / **18 CreateTextLayout** / 21 CreateTextAnalyzer`。
踩过的坑：① 我一开始把 `CreateCustomFontFileReference` 当成 6（那是 `UnregisterFontCollectionLoader`）→
collection 建出来是**空的**（`CreateStream=0` 一眼看出 DWrite 从没读过字体）；② `IDWriteTextFormat`
**自己有 25 个方法**（槽 3..27），所以 layout 自己的方法从 **28** 起：`58 Draw / 59 GetLineMetrics /
60 GetMetrics / 65 HitTestTextPosition / 66 HitTestTextRange`（我按 30 个方法算过，全错一位，
表现是 `GetMetrics` 返回 `E_INVALIDARG`）。③ `GetLineMetrics` **不支持 maxLineCount=0 查数量**
（返回 `E_INSUFFICIENT_BUFFER`），必须直接给缓冲区。

## A1.3 语料与字段（`out-layout/dwrite-layout-oracle.json`）
10 个用例：固定容器宽 + 长英文句 / 多短词 / **带连字符复合词** / 超窄容器 / 显式 `\n`（含空行）/
**超长单词（必须字符级紧急断行）** / 中英混排 / 纯 CJK / 粗体换行 / 斜体换行。
每例记录 `textMetrics`（width/height/lineCount/maxBidiReorderingDepth 等）+ 每行：
`startChar` / `endCharExclusive`（**UTF-16 码元下标**）/ `lengthWithNewline`（含换行符，故下一行 start = 本行 start+length）/
`newlineLength` / `trailingWhitespaceLength` / `heightDip` / `baselineDip` / `isTrimmed` /
`advanceWidthDip`（用 `HitTestTextRange` 量该行字符的最大右缘−最小左缘）/ `caretXDip`/`caretYDip`（`HitTestTextPosition(行首,0)`）/ `lineText`。

样例（en-long 除外，见文件）：`mixed` 200 DIP 容器 → 5 行，`[0,13) / [13,28) / [28,40) / [40,54) / [54,62)`，
行高 32.688（纯拉丁行）与 32.930（含 CJK 的行）。

## A1.4 能对拍 / 不能对拍
* **能对拍**：每行起止字符下标、行数、行高、baseline、行 advance、caret 坐标。这些是 B2/B3 的直接判据。
* **不能对拍（已标注）**：
  * `en-oneword` 这类**紧急断行**的具体断点依赖 DWrite 的字符级断行策略，Linux 侧若实现不同，差异是真实的，别当成 bug 掩盖。
  * **含 CJK 的 4 个用例里，DWrite 对 CJK 走了系统字体回退**（我们的 collection 里只有拉丁 Noto），
    所以那些行的**行高 32.930、advance 都带上了回退字体**——**在 Linux 上不可复现**（回退取决于系统装了哪些字体）。
    JSON 里这两条已标 `cjkCoverage: false`。**真 CJK 的换行/行高请看追加 2**（用真 CJK 字体，无回退）。
  * 没有覆盖：bidi（`readingDirection` 固定 LTR）、`paragraphAlignment`/`textAlignment` 非默认值、
    trimming、`SetLineSpacing` 非默认、tab stop。

---

# 追加 2 · CJK shaping 真值 —— `out-cjk/`

> 任务 2，2026-09-11 交付。**字段与 `out/dwrite-shaping-oracle.json` 完全同形制**，可一次跑两份。

## A2.1 字体：本机已有、OFL、**不进仓库**
| 项 | 值 |
|---|---|
| Linux 路径 | `/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc` |
| 大小 | 19,484,784 B |
| **sha256** | **`b76b0433203017ca80401b2ee0dd69350349871c4b19d504c34dbdd80541690a`** |
| 许可 / 来源 | OFL，Ubuntu 包 `fonts-noto-cjk`（`apt-get install fonts-noto-cjk`） |
| 是否进仓库 | **否**（19.5 MB，且属于系统包）。Windows 侧那份是**测试夹具**，随 `C:\u1-shaping\` 一起清理 |
| 复现校验 | 每个用例都带 `fontSha256`；harness 应**在 sha 不匹配时响亮失败**（系统升级换字体 → oracle 可检测地失效，而不是悄悄对错） |

**它是 `.ttc`（字体集合）**，一个文件 5 个面：`0=JP 1=KR 2=SC 3=TC 4=HK`。
⇒ `CreateFontFace` 的 **`fontFaceType` 必须是 `DWRITE_FONT_FACE_TYPE_OPENTYPE_COLLECTION`(=2)**、
`faceIndex` 这次是有效参数。（用 `TRUETYPE`(=1) 传 faceIndex≥1 会 `E_INVALIDARG`——踩过。）

## A2.2 语料（7 条 × 2 字号 + 2 条 locl 对照 × 3 面 = **34 例**）
| id | 覆盖 |
|---|---|
| `han-simplified` | 简体汉字 + 全角冒号/句号 |
| `han-mixed-script` | **汉字 + 假名 + 谚文**同串（真脚本边界） |
| `kana` | 平假名 + 片假名 + 表意句点 |
| `hangul` | 谚文音节 |
| `fullwidth-punct` | 只用全角标点 `：，。！？；：「」（）【】` |
| `mixed-latin-cjk` | 拉丁+CJK+数字（**就是上轮全 `.notdef` 的那串，现在真覆盖了**） |
| `latin-only-in-cjk-font` | 拉丁字符由 CJK 字体自己出（不经回退） |

**实测：34 个用例 `notdefGlyphs` 全为 0**（上轮 `mixed-cjk` 是 6 个 `.notdef`）——CJK 覆盖到位了。

## A2.3 ⭐ `locl`：从一句话变成可测量的差异量
同一批码点、不同 faceIndex（DWrite 按面自动取该面的本地化字形）：

| 文本 | JP | SC | TC |
|---|---|---|---|
| `直画骨角写门今令` | `27873 27078 45132 37448 10973 43012 9770 9808` | `27874 27079 45133 37449 10974 43013 9771 9809` | `27874 27080 45134 37448 10974 43013 9772 9810` |
| `汉字字体说明` | `23037 15364 15364 …` | `23037 15365 15365 …` | `23037 15365 15365 …` |

**逐字对照（位置 / 字 / JP / SC / TC）** —— 这一节曾写错过归因，以下为按 `out-cjk` JSON 重算的结果：

`直画骨角写门今令`（8 字）：

| pos | 字 | JP | SC | TC | 备注 |
|---|---|---|---|---|---|
| 0 | 直 | 27873 | 27874 | 27874 | |
| 1 | 画 | 27078 | 27079 | 27080 | **三面两两不同** |
| 2 | 骨 | 45132 | 45133 | 45134 | **三面两两不同** |
| 3 | 角 | **37448** | 37449 | **37448** | **JP == TC ≠ SC** |
| 4 | 写 | 10973 | 10974 | 10974 | |
| 5 | 门 | 43012 | 43013 | 43013 | |
| 6 | 今 | 9770 | 9771 | 9772 | **三面两两不同** |
| 7 | 令 | 9808 | 9809 | 9810 | **三面两两不同** |

* **JP vs SC：8/8 全不同**；**JP vs TC：7/8**（只有 `角` 相同）；**SC vs TC：5/8**（`画 骨 角 今 令`）。
* 所以正确的说法是"**多数**字在三面之间不同，但并非全部、也不是每个都两两不同"：
  `角` 恰好 **JP == TC ≠ SC**，`直 写 门` 是 **JP 单独不同**。

`汉字字体说明`（6 字）：

| pos | 字 | JP | SC | TC |
|---|---|---|---|---|
| 0 | 汉 | 23037 | 23037 | 23037 | 
| 1 | 字 | 15364 | **15365** | **15365** |
| 2 | 字 | 15364 | **15365** | **15365** |
| 3 | 体 | 9966 | 9966 | 9966 |
| 4 | 说 | 38513 | 38513 | 38513 |
| 5 | 明 | 20282 | 20282 | 20282 |

* **`汉` 三面完全相同（23037）**；不同的是**位置 1、2 的两个 `字`**（JP 15364 vs SC/TC 15365），`体 说 明` 也完全相同。
* **JP vs SC / JP vs TC 都是 2/6；SC vs TC 是 0/6（完全一致）**。
* 结论方向不变且更强：locl 是**逐字**生效的 —— 同一串里 6 个字只动了 2 个，且 SC 与 TC 在这串上没有任何差异，
  说明它**不是"按面整串换字形"**，而是按**码点的本地化变体表**逐字替换。

## A2.4 与 HarfBuzz 对拍（`out-cjk/cjk-comparison.json`）
HarfBuzz 14.4.0，同一份 `.ttc` + **同一 faceIndex**（HB 的 `hb.Face(blob, index)`）：

| 指标 | 结果 |
|---|---|
| 用例数 | 34 |
| 字形序列一致 —— **不给 language** | **30 / 34** |
| 字形序列一致 —— **给 language**（SC→`zh-Hans`、TC→`zh-Hant`、JP→`ja`、KR→`ko`） | **34 / 34** ✅ |
| advance 一致 | **34 / 34** |

**⭐ 那 4 条差异全部是 `mixed-latin-cjk`，且原因明确**：HarfBuzz 只在 buffer 设了 **language** 时才应用
`locl`；不设时它对 SC/TC 面回落到**默认（JP）字形**，于是与 DWrite（按面自动本地化）不一致。
**这条对路线 B 是可直接执行的结论：接线 HarfBuzz 时必须把 locale 传到 buffer 上**，否则简体文本会拿到日文字形。
（同一份数据也说明：`locl` 的影响面是**逐字**的，不是整串。）

## A2.5 能对拍 / 不能对拍（CJK）
* **能对拍**：字形 id 序列、advance、cluster、`.notdef` 计数、`locl` 跨面差异。
* **不能对拍/未覆盖**：
  * **竖排（`vert`）**、**变体选择符（VS/IVS）**、**Emoji/彩色字体**、**bidi（阿拉伯/希伯来）**：未覆盖。
  * **`locl` 的 language→字形映射本身**没有单独真值：本报告只给"给定面/给定 language 时的结果"。
  * 行高/换行在 CJK 下的真值请看 **追加 1**；但那 4 条含 CJK 的 layout 用例因为**字体回退**在 Linux 上不可复现，
    两者要合并成"纯 CJK 字体 + 固定容器"的用例才有意义（**建议下一步做，尚未做**）。

## A2.6 环境问题（一句话，未定位）
三台 oracle 可执行文件（`ShapingOracle` / `CjkOracle` / `LayoutOracle`）在约**一半的进程启动**中会在
`IDWriteFontFace::GetMetrics`（`LayoutOracle` 里表现为第一次 `GetMetrics`）返回**垃圾 HRESULT**（形如
`0xafc02240`）；同进程内一旦失败就全失败，重启即可。已排除槽位/结构体布局/delegate 编组
（换成 `delegate* unmanaged` 逐字节函数指针后依旧）。**是否本机专有未定位**；三个 runner 都带
**进程级重试**，并自动校验"两次成功运行的数据逐字节相同"（已通过）。**对拍直接用 `out*/` 里的数据即可，不必重跑。**

---

# 追加 3 · 纯 CJK 的 layout 真值（无字体回退）—— `out-layout/dwrite-layout-cjk-oracle.*`

> 补上追加 1 §A1.4 里标注的缺口：那 4 条含 CJK 的 layout 用例走了**系统字体回退**，Linux 不可复现。
> 这次把 `NotoSansCJK-Regular.ttc`（**同一 sha `b76b0433203017ca…`**）放进**同一个私有 collection**，
> 于是 DWrite 自己解析 family、**完全不依赖系统回退**。字段与 `out-layout/dwrite-layout-oracle.json` **完全同形制**。

## A3.1 结果概览
**25 个用例** = 10 个拉丁（追加 1 那批，原样保留）+ **15 个 CJK**。
collection 里 CJK 字体带来 **10 个 family**（`.ttc` 5 个面 × 名称变体）；
`FindFamilyName` 实测 **`Noto Sans CJK SC` → exists=True**、**`Noto Sans CJK JP` → exists=True**（同样是验证而非猜测）。
CJK 行高统一 **34.752 DIP**（24 DIP 字号）；作为对照，拉丁 Noto 行高 32.688 ——
**再没有 32.930 那种"回退字体混进来"的行高**，说明回退问题已消除。

## A3.2 ⭐ 避头尾（行首禁则 / kinsoku）：**DWrite 确实做**，且是"把前一个字拉下来"
构造方式：容器宽 **168 DIP = 正好 7 个全角字**（全角 advance = 24），文本第 8 个字就是禁则标点。
若按贪心断行，标点会落到**第 2 行行首**。实测（SC 面，24 DIP）：

| 用例 | 文本 | 行 1 | 行 2 |
|---|---|---|---|
| `cjk-kinji-comma` | `甲乙丙丁戊己庚，辛壬癸子丑寅卯` | `甲乙丙丁戊己` **[0,6) adv=144** | `庚，辛壬癸子丑` [6,13) adv=168 |
| `cjk-kinji-close` | `甲乙丙丁戊己庚）」辛壬癸子丑` | `甲乙丙丁戊己` **[0,6) adv=144** | `庚）」辛壬癸子` [6,13) adv=168 |
| `cjk-kinji-period` | `甲乙丙丁戊己庚。辛壬癸子丑寅` | `甲乙丙丁戊己` **[0,6) adv=144** | `庚。辛壬癸子丑` [13,14) adv=24 |

* **行 1 只有 6 个字（adv=144 = 6×24）**，而不是贪心的 7 个 ⇒ 第 7 个字被"拉下来"陪标点，
  所以 `，` `）` `」` `。` **没有出现在任何行的行首**。
* 行 2 是 **7 个字、正好占满 168**，说明这是**"把前字拉下来"**，不是"标点悬挂到行尾外"（hanging punctuation）。
* 这就是 B2 需要的判据：**换行不能只在空白处断，还要遵守行首禁则**。

## A3.3 其余 CJK 断行行为（可直接当判据）
| 用例 | 观察 |
|---|---|
| `cjk-para` (w=200) | 5 行，每行 8 个全角字（adv=192），末行 4 字 |
| `cjk-narrow` (w=90) | 10 行，每行 3 字（adv=72），末行 2 字 |
| `cjk-fullwidth` | 全角标点串照常断行，`：，。！？` 与 `；：「」（）` 各自成行 |
| `cjk-latin-mix` (w=200) | 断点落在**中英交界**：`在中文里嵌入␠` / `Latin words␠和␠` / `numbers 12345␠` —— **行尾保留了空格**，行 advance 各不相同（149.38 / 165.46 / 177.36） |
| `cjk-long-token` (w=150) | 超长拉丁串被**字符级强制断开**：`abcdefghijkl` / `mnopqrstuv` / `wxyz0123456` / `789␠它必须被` |
| `cjk-newlines` | 显式 `\n` 生效，空行是**零长度行** `[8,8)`（注意：`startChar == endCharExclusive`） |
| `cjk-kana` (w=180) | 假名换行；`テストです。ひ` —— 行尾是 `。` 没问题（禁的是**行首**） |
| `cjk-hangul` (w=180) | 谚文按词/音节断，行尾保留空格（`한국어 조판에서␠`） |
| `cjk-small` (11 DIP) | 行高 **15.928**，容器 150 装 13 字（adv=143） |

## A3.4 同一段中文在 **SC 面 vs JP 面**下的换行点：**完全相同**
`facecmp-sc` / `facecmp-jp`（同一串码点、同一容器 160、同一字号 24、同一 locale `zh-cn`）：

```
SC: [(0,6),(6,12),(12,18),(18,24),(24,30),(30,33)]   width=144.000  lines=6
JP: [(0,6),(6,12),(12,18),(18,24),(24,30),(30,33)]   width=144.000  lines=6
identical break positions = True
```
**结论（负结果，但有用）**：**面/locale 不改变断行位置**。原因也清楚：CJK 字形都是全角、
`locl` 只换**字形 id** 不改 **advance**（追加 2 已实测同串同 advance），而断行只看 advance。
⇒ 对 B2 而言：**locale 影响的是"出哪个字形"（shaping 层），不是"在哪里断行"（layout 层）**；
但 shaping 层必须传 locale（见追加 2 §A2.4），两件事不要混为一谈。

## A3.5 能对拍 / 不能对拍（CJK layout）
* **能对拍**：行数、每行起止字符下标、行高/baseline、行 advance、caret 坐标、**禁则标点的处理方式**（拉前字 vs 悬挂）。
* **不能对拍/未覆盖**：
  * **更多禁则字符与"行尾禁则"（如 `（` `「` 不能出现在行尾）**：本轮只测了 `，` `。` `）` `」` 四个行首禁则，
    行尾禁则、以及禁则冲突时的优先级**未覆盖**。
  * **`cjk-long-token` 这类强制断行的具体切点**依赖 DWrite 的字符级断行实现，差异是真实的，别当 bug 掩盖。
  * 未覆盖：竖排 `vert`、`textAlignment`/`paragraphAlignment` 非默认、trimming、`SetLineSpacing` 非默认、
    tab stop、bidi。locale 固定 `zh-cn`（kana/hangul 用例虽然文本是日/韩，但 locale 仍是 `zh-cn`——
    这本身也是一条信息：**断行不受 locale 影响**，见 A3.4）。

---

# 追加 4 · 禁则的另一半：**行尾禁则 + 冲突优先级 + 完整禁则表** —— `out-layout/kinsoku-table.json`

> 补上追加 3 §A3.5 标注的两个缺口。**B2 需要的是一张表，不是一个开关** —— 这份就是那张表。

## A4.1 探测构造（可自我验证）
容器宽 **168 DIP = 正好 7 个全角字**（全角 advance = 24 @24 DIP），字体 Noto Sans CJK SC：

| 探针 | 文本构造 | 判读 |
|---|---|---|
| `start` | 7 个汉字填充 + **X** + 尾巴（X 在**下标 7**） | 贪心断行会让 X 落到第 2 行**行首**。若禁则生效，DWrite 把第 7 个填充字**拉下来** ⇒ **行 1 = 6 字**；否则行 1 = 7 字 |
| `end` | 6 个汉字填充 + **X** + 尾巴（X 在**下标 6**） | 贪心断行会让 X 落在第 1 行**行尾**。若禁则生效，DWrite 把 X **推到第 2 行** ⇒ **行 1 = 6 字**；否则行 1 = 7 字 |
| 对照 | X = `甲`（汉字） | **两个方向都必须判"allowed"**，否则说明探针构造本身有问题 |

**对照实测通过**：`start` 方向行 1 = `甲乙丙丁戊己庚`（7 字，allowed）、`end` 方向行 1 = `甲乙丙丁戊己甲`（7 字，allowed）
⇒ 探针能区分"禁则"与"普通字"，判读不是靠猜。

## A4.2 行首禁则表（32 个探针 → **31 个 PROHIBITED**，1 个对照 allowed）
以下字符在 DWrite 眼里**禁止出现在行首**（实测全部把前一个字拉下来，行 1 = 6 字）：

| 类别 | 字符 |
|---|---|
| 句读/标点 | `、`U+3001 `。`U+3002 `，`U+FF0C `．`U+FF0E `：`U+FF1A `；`U+FF1B `！`U+FF01 `？`U+FF1F `…`U+2026 `‐`U+2010 |
| 右括号类 | `）`U+FF09 `］`U+FF3D `｝`U+FF5D `」`U+300D `』`U+300F `】`U+3011 `》`U+300B `〉`U+3009 `〕`U+3015 |
| 日文小字/记号 | `・`U+30FB `ー`U+30FC `々`U+3005 `ぁ`U+3041 `ぃ`U+3043 `ぅ`U+3045 `ぇ`U+3047 `ぉ`U+3049 `っ`U+3063 `ゃ`U+3083 `ゅ`U+3085 `ょ`U+3087 |

**⇒ 31/31 全部禁则**（`・`/`ー`/`々`/小假名 这些也都算了，说明 DWrite 用的是完整的 CJK 禁则类，不是只做标点）。

## A4.3 行尾禁则表（12 个探针 → **9 个 PROHIBITED + 2 个"拉 2 个字"**）
| 字符 | 实测行 1 | 判读 |
|---|---|---|
| `（`U+FF08 `［`U+FF3B `｛`U+FF5B `「`U+300C `『`U+300E `【`U+3010 `《`U+300A `〈`U+3008 `〔`U+3014 | `甲乙丙丁戊己`（6 字） | **PROHIBITED**：该字符被推到第 2 行行首 |
| **`“`U+201C、`‘`U+2018** | `甲乙丙丁戊`（**5 字**） | **也禁**，但**多拉了一个字**：行 2 = `己“辛壬癸子丑`（引号与它前一个字一起下移） |

⇒ 行尾禁则是**成立**的（10/10 都不让开括号类收尾），但**`“`/`‘` 的拉取距离与全角括号不同**（拉 2 个字 vs 拉 1 个字）——
这是"从真值才能看出、靠推理会做错"的一类细节。

## A4.4 冲突优先级（4 个**故意无解**的构造）
| 用例 | 构造 | 实测结果 | 结论 |
|---|---|---|---|
| `kinsoku-conflict-openpair` | 6 填充 + `「（` + 尾巴，容器 7 字 | 行 1 = `甲乙丙丁戊己`（6 字），行 2 = `「（辛壬癸子丑` | **两个开括号一起下移**：`「` 不能收尾、`（` 不能起首，DWrite 选择把**两个都推下去**，不悬挂、不挤压 |
| `kinsoku-conflict-both` | 6 填充 + `「」` + 尾巴 | 行 1 = 6 字，行 2 = `「」辛壬癸子丑` | 同上，`「」` 作为整体下移 |
| `kinsoku-conflict-1char` | 容器 **24 DIP（1 个字）** | 行 1 = `甲`、行 2 = `乙`…**每行 1 字** | **禁则被放弃**：无解时 DWrite **允许破例**（不悬挂、不压缩、不报错） |
| `kinsoku-conflict-2char` | 容器 **48 DIP（2 个字）**，含 `，。」` | 行 1 = `甲乙`、行 2 = `丙丁` | 同上，容器太窄时禁则让位于"至少放得下一个字" |

**⇒ 冲突时的优先级：能整体下移就整体下移（宁可让上一行短一个字）；实在放不下（容器 ≤ 字数下限）就放弃禁则、正常断行**。

## A4.5 能对拍 / 不能对拍
* **能对拍（可直接写进 B2 的判据）**：A4.2 的 31 个行首禁则字符集、A4.3 的 9+2 个行尾禁则字符集、
  冲突时的"整体下移"策略、以及"容器过窄时放弃禁则"的行为。每个探针都带
  `char` / `kind` / `verdict` / `line1EndChar` / `line1AdvanceDip` / `line1Text` / `line2Text`，**逐字符可核**。
* **不能对拍/未覆盖**：
  * **这不是"完整 UAX#14 / JLREQ 禁则集"**：只测了我挑的 44 个字符；**没测的字符 = 未知**，
    别把"表里没有"当成"允许"。
  * **半角/西文标点**（`,` `.` `)` `"`）在半角语境下的禁则未测（本轮全是全角）。
  * **禁则与"避头尾以外的断行规则"的交互**（如 hyphens、`word-wrap: break-word` 式的紧急断行）未测。
  * **行尾禁则的"拉 2 个字"是否也适用于其它引号类**（`『` 等只测了拉 1 个字的情形）未测。
  * 未覆盖：竖排 `vert`、`textAlignment` 非默认、trimming、bidi、`SetLineSpacing`。
  * 全部探针固定 **locale = `zh-cn`**。追加 3 §A3.4 已实测 **断行位置不受 face/locale 影响**，
    但**禁则是否受 locale 影响本轮没有单独验证**（若要给 B2 更硬的保证，应补一组 `ja-jp` locale 的对照）。
