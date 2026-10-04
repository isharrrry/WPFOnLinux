# U1 · Windows 真机「混合方向文本」oracle

> 判据输入，供 T1d 的 `build/MilBridge/T1d-bidi-decision.md` §5 使用。
> **全部在远端真机完成**（本地只落盘 oracle 文件，未跑应用、未构建）。

## 1. 元组（口径）

| 项 | 值 |
|---|---|
| 机器 | `bilintu\pc@192.168.193.97`，Windows 11 23H2 `10.0.22631`，x64 |
| 运行时 | **.NET 10.0.7**（`Microsoft.WindowsDesktop.App 10.0.7`），PresentationCore 10.0.0.0 |
| **测量方式** | `System.Windows.Media.TextFormatting.TextFormatter.Create().FormatLine(source, 0, 10000, paraProps, null)` → `TextLine` |
| 每字 x 区间 | `TextLine.GetTextBounds(i, 1)`（i = 0..N−1）→ `TextBounds.Rectangle` |
| 整行 | `TextLine.GetTextBounds(0, line.Length)` |
| 行/段信息 | `TextLine.Length / NewlineLength / Width / Height / Baseline / HasOverflowed` + `TextLine.GetTextRunSpans()` |
| **Dpi** | **96**。`TextFormatter` 与分辨率无关，x/width 是 DIP（=96dpi 下的 px），不随显示器 DPI 变 |
| emSize | **24 DIP**；paragraphWidth = 10000 DIP（宽到不会折行，全是单行） |
| 段落方向 | **两种都跑**：`FlowDirection.LeftToRight` 与 `RightToLeft`（各 9 串 → 18 例） |
| 字体 | **Arial**，`file:///C:/WINDOWS/FONTS/ARIAL.TTF`，**sha256 `baa251526d6862712a58e613ef451d8a2b60482142ec6aab1d47fb8e23e21a7c`** |
| 为什么是 Arial | 程序在 `{Arial, Segoe UI, Tahoma, Times New Roman, David}` 里挑**第一个覆盖语料全部码点**的：用 `Typeface.TryGetGlyphTypeface` → `GlyphTypeface.CharacterToGlyphMap.ContainsKey(cp)` **逐码点验证**，覆盖表完整落在 JSON 的 `fontCoverageTable`。⇒ **不会发生字体回退，分段不受系统字体影响** |

原始输出：`out/bidi-oracle.json`（机器可读，逐字 x/width/方向/run 信息）、`out/bidi-oracle.txt`（人可读）。源码：`src/Program.cs`、`src/BidiOracle.csproj`、`src/run.ps1`。

## 2. ⚠️ 读这份数据必须先知道的一件事：**RTL 段落的 x 原点在右边缘**

`TextBounds.Rectangle.X` 的原点是**行原点**，而 **RTL 段落的行原点在右边缘** ⇒ 那里 **raw x 是向左递增的**。
直接按 x 升序当"从左到右"会**把视觉序读反**（我第一版就踩了这个坑，已修）。

因此每个字符同时给两个字段：
* `x` / `width`：**raw**（`TextBounds.Rectangle` 原值，语义随 `flowDirection` 变）；
* **`xFromLeftDip`：归一化值**（该字符左缘到**行左缘**的距离），**两个方向可直接比较**；本文所有视觉序都由它推出。

## 3. 结果（视觉序 = 从左到右扫到的字符；`RRRRRLLL` 是**逐字 bidi 方向**，取自 `TextBounds.FlowDirection`）

| 用例 | 段落方向 | 逻辑串 | **视觉序（L→R）** | 逐字方向 | 行宽 DIP |
|---|---|---|---|---|---|
| `he-pure` | Lef | `שלום עולם` | `םלוע םולש` | `RRRRRRRRR` | 98.820 |
| `he-pure` | Rig | `שלום עולם` | `םלוע םולש` | `RRRRRRRRR` | 98.820 |
| `ltr-pure` | Lef | `abc 123` | `abc 123` | `LLLLLLL` | 85.400 |
| `ltr-pure` | Rig | `abc 123` | `abc 123` | `LLLLLLL` | 85.400 |
| `ltr-digits` | Lef | `123 abc` | `123 abc` | `LLLLLLL` | 85.400 |
| `ltr-digits` | Rig | `123 abc` | `abc 123` | `LLLRLLL` | 85.400 |
| `he-period` | Lef | `שלום.` | `םולש.` | `RRRRL` | 54.723 |
| `he-period` | Rig | `שלום.` | `.םולש` | `RRRRR` | 54.723 |
| `he-123` | Lef | `שלום 123` | `123 םולש` | `RRRRRLLL` | 94.763 |
| `he-123` | Rig | `שלום 123` | `123 םולש` | `RRRRRLLL` | 94.763 |
| `he-123-he` | Lef | `שלום 123 עולם` | `םלוע 123 םולש` | `RRRRRLLLRRRRR` | 145.527 |
| `he-123-he` | Rig | `שלום 123 עולם` | `םלוע 123 םולש` | `RRRRRLLLRRRRR` | 145.527 |
| `he-latin` | Lef | `שלום abc` | `םולש abc` | `RRRRLLLL` | 93.417 |
| `he-latin` | Rig | `שלום abc` | `abc םולש` | `RRRRRLLL` | 93.417 |
| `latin-he` | Lef | `abc שלום` | `abc םולש` | `LLLLRRRR` | 93.417 |
| `latin-he` | Rig | `abc שלום` | `םולש abc` | `LLLRRRRR` | 93.417 |
| `mixed-long` | Lef | `abc שלום 123 def` | `abc 123 םולש def` | `LLLLRRRRRLLLLLLL` | 180.150 |
| `mixed-long` | Rig | `abc שלום 123 def` | `def 123 םולש abc` | `LLLRRRRRRLLLRLLL` | 180.150 |
**控制组自证装置没量错**：`ltr-pure`（纯 LTR）两个方向都得到 `abc 123`；`he-pure`（纯 RTL）两个方向都得到 `םלוע םולש`（希伯来词内反序）✓。

### 与 UBA 规则 L2 手工核对（证明数据本身是对的）
* `he-123`「שלום 123」：希伯来 level 1、空格随段落、数字 level 2 ⇒ 最高层 2、最低奇层 1；
  先在 level≥2 反（数字 run 自身，不变），再在 level≥1 反**连续序列**（希伯来+空格+数字全 ≥1）⇒ 数字跑到最左：
  **`123 םולש`**。**两种段落方向都得同一结果**（因为要反的都是同一条 level≥1 连续段）——**实测一致** ✓。
* `latin-he`「abc שלום」：abc level 0、空格取段落层、希伯来 level 1 ⇒ 最高层 1、最低奇层 1，
  只反 level≥1 的那一段（希伯来自身）⇒ `abc םולש`（LTR 基）/ `םולש abc`（RTL 基）——**实测一致** ✓。

## 4. ⭐ 对你们 shim 的直接判据

| 现象 | 真值 | 你们现在 |
|---|---|---|
| `שלום 123`（RTL 基） | **`123 םולש`**：数字是**独立 LTR run**，`1` 在最左、`3` 在次左（`xFromLeftDip` 0 / 13.3 / 26.7），希伯来在右 | 画成 `321 םולש`（整段当一个 RTL run ⇒ 数字被反） |
| `abc שלום`（LTR 基） | **`abc םולש`**：希伯来字母逐字反序，拉丁不动 | 逐个反希伯来字母（整段当 LTR） |
| 逐字方向 | `he-123@RTL` = `RRRRRLLL`；`mixed-long@LTR` = `LLLLRRRRRLLLLLLL` | 你们实测 `runs=1 / BidiLevel=0 / ClusterMap=0..N-1` ⇒ **逐字方向永远是单一值** |

⇒ **判据是"逐字方向序列 + 每个 run 的边界"，不是"整行看起来对不对"**。
JSON 里每个用例都有 `perChar[].flowDirection`（逐字）与 `perChar[].xFromLeftDip`（位置），可以逐字对拍。

## 5. 你们要的 `TextLine` 层信息：**取到了，但要说明白**
* ✅ `Length` / `NewlineLength` / 行数 / `GetTextRunSpans()` 的 span 边界与 `TextEndOfParagraph` 位置 **都取到了**：
  `line.Length = 文本长度 + 1`，`NewlineLength = 1`，spans = `[TextCharacters(0..N), TextEndOfParagraph(N,1)]`。
* ⚠️ **重要口径**：`GetTextRunSpans()` **按 `TextSource` 返回的 run 切分，不按 bidi 层切分** ——
  本 oracle 的 source 一次返回整串，所以 18 例全部只看到 **1 个 `TextCharacters`**，
  **光看 span 边界是看不出方向分段的**。要逐字方向请看 `perChar[].flowDirection`（这才是 bidi 解析结果）。
* 另：`GetTextBounds(i,1)` 在本语料上**每个字符都只返回 1 个 fragment**（162/162），
  `TextRunBounds` 的实际成员是 `TextSourceCharacterIndex` / `Length` / `Rectangle` / `TextRun`（已逐字记录在 `perChar[].textRunBounds`）。

## 6. 可复算（真机命令）
```powershell
# 源码已在 C:\u1-shaping\src\BidiOracle\
cd C:\u1-shaping\src\BidiOracle
dotnet build
powershell -File C:\Windows\Temp\run.ps1      # 跑并打印 EXITCODE / stdout / stderr / 产物大小
# 产物： C:\u1-shaping\out-bidi\bidi-oracle.{json,txt}
```
输出里 `generatedUtc` 每次不同，其余内容**逐字节确定**（无随机、无时间依赖；字体与字号都固定）。真机侧只读：没有安装任何东西、没有改工程配置、没有动别人的文件；工作目录 `C:\u1-shaping\` 已清理。

## 7. 能对拍 / 不能对拍
**能对拍**：逐字 `xFromLeftDip` / `width`、逐字 `flowDirection`（bidi 解析）、整行 `width`/`height`/`baseline`、视觉序、`TextLine.Length`/`NewlineLength`。
**不能对拍/未覆盖**：
1. **`GetTextRunSpans()` 不给 bidi 分段**（见 §5）——别拿它当 run 边界真值；要 run 边界只能从 `perChar[].flowDirection` 的**变化点**推。
2. **多行/折行下的 bidi**：本轮 paragraphWidth=10000，**全是单行**；跨行重排（UBA L1 的 whitespace 复位）未覆盖。
3. **数字类型细分**：只测了欧洲数字（EN）；阿拉伯-印度数字（AN）、阿拉伯语/叙利亚语、RTL 标点配对（括号镜像）未覆盖。
4. **`TextAlignment` 非 Left、`TextWrapping` 非 NoWrap、`LineHeight`/`Indent` 非默认**未覆盖（本 oracle 全用默认）。
5. **字体**固定 Arial；换成别的字体时**分组可能变化**（本 oracle 已用"全码点覆盖"排除了回退干扰，但换字体仍需重跑）。
6. 真值只代表 **WPF `TextFormatter` 这一层**；`TextBlock`/`FormattedText` 走同一层，理论上一致，但**本轮没有交叉验证**。
