# T1b · 折叠/记账残余的行级归因（**只读**，基线 #10）（2026-09-14）

## 0. 三元组（本轮新纪律 15：读数必须带它）
| 项 | 值 |
|---|---|
| **被测件 sha** | shim **`7C2E0107A9C8618027D327179269ABEE6D8D329EC1CD89194A412B06B1687274`**（= #10 的 `hbtextline 7c2e0107a9c86180`）；app-local 4/4 已与权威一致（PC `628e741681ecb048`、WB `e6216fe961a2bfb9`、DWF `2f77dbdf5e7e2cd5`、Provider `71ba86c6495347fe`） |
| **仪器/harness 版本** | `bash build/MilBridge/run.sh tline`（本趟，2026-09-14）；产物 `gen/tline-detail-full.txt` / `gen/t2d-width-diff.txt` 头行都带上面这个 sha |
| **判据口径** | 段1「折叠明细」= 逐行 `Len / W / HasCollapsed / cr(起点,长度,宽)` 比真机；`t2d-width-diff` = 逐行 `TextLine.Width` 比真机 `w`（**两者不是同一个字段**，见 §2 的警告） |
| 本趟读数 | 记账结构 **1286/1298**（不等 12）、宽度分桶 **167/1084/47**、T2b **213/213**、T2c **0**、折叠明细 **218/236** —— 与主控给的 #10 基线一致 |

## 1. 省略号/折叠几何 8 条：逐例逐字段（**逐字取自 `gen/tline-detail-full.txt` 段1**）
| 用例 | 行 | 我们 Len / W | 真值 Len / W | ΔW | cr 我们（起,长,宽） | cr 真值（起,长,宽） | 形态 |
|---|---|---|---|---|---|---|---|
| `F_lat_words_w560` | #0 | 70 / 252.2240 | 70 / 252.2100 | **+0.0140** | (30,40) 259.2160 | **(31,39)** 259.2133 | 起止**各 ±1 字** |
| `F_nbsp_zwsp_w40` | #1 | 4 / 21.6800 | 4 / 21.6800 | 0.0000 | (6,3) **4.8640** | (6,3) **9.0233** | **只 cr.Width 差 −4.1593** |
| `F_nbsp_zwsp_w40` | #3 | 2 / 12.6560 | 2 / 12.6567 | −0.0007 | (14,2) **−3.0560** | (14,2) **3.3433** | **只 cr.Width 差 −6.3993；我们的宽是负数** |
| `F_nbsp_zwsp_w80` | #0 | 9 / 32.2240 | 9 / 22.5433 | **+9.6807** | (2,7) 34.1760 | **(1,8)** 48.0133 | 起止**各 ±1 字** + 行宽更大 |
| `F_nbsp_zwsp_w80` | #1 | 7 / 22.5440 | 7 / 22.5433 | +0.0007 | (10,6) **28.4480** | (10,6) **34.8467** | **只 cr.Width 差 −6.3987** |
| `F_nbsp_zwsp_w120` | #1 | 13 / 42.9600 | 13 / 40.3367 | **+2.6233** | (18,9) 45.2000 | **(17,10)** 54.5400 | 起止**各 ±1 字** |
| `F_nbsp_zwsp_w200` | #0 | 21 / 79.0560 | 21 / 70.5100 | **+8.5460** | (8,13) 79.1680 | **(7,14)** 94.1067 | 起止**各 ±1 字** |
| `F_nbsp_zwsp_w320/560/900/winf` | #0 | 33 / 120.4480 | 33 / 120.4433 | +0.0047 | (13,20) 122.8480 | **(14,19)** 129.5633 | 起止**各 ±1 字（与约束宽无关：四条同数）** |

**形态归纳（3 + 5）**：**3 条**只差 `cr.Width`（−4.1593 / −6.3993 / −6.3987，且其中一条我们的宽为**负**）；
**5 条**起止各偏 1 字（`[13,20)` vs `[14,19)` 四条**同数** ⇒ 与约束宽无关，纯裁剪边界）。

## 2. ⚠️ 必须先说清"哪两个字段被比"（否则会把两件事当一件）
主控引用的 3 条"非 Tab 行宽超差"数值 `F_nbsp_zwsp_w80#0 +9.68 / w120#1 +2.62 / w200#0 +8.55` **与段1 的折叠行逐字对上**（`+9.6807 / +2.6233 / +8.5460`）；
而 **`gen/t2d-width-diff.txt`（逐行 `TextLine.Width` vs 真机 `w`）对同样三个 case+行给的是 `+4.1567 / +6.7167 / +6.3927`**（cp 区间也不同：`[0,9)` / `[14,27)` / `[0,21)`）。
⇒ **两个 artifact 比的是不同字段**（折叠明细的 `W` ≠ 行 `TextLine.Width` 口径）。**任何"修"之前必须先声明修的是哪一个字段**，
否则就是"对着两把尺子改一次"。本报告因此把两组数**并排**给出，不下"哪个对"的判断。

## 3. 归属（逐例）
| 组 | 归属 | 依据 |
|---|---|---|
| 8 条里的 **7 条 `F_nbsp_zwsp_*`** | **shim 侧 · NBSP/ZWSP 折叠/空白口径**（与我此前把 `NBSP/ZWSP` 归 shim 侧**同源**，**不是**另一根） | 8 条里 7 条同族；`cr` 差恰好 ~1 字的 advance（4.16 / 6.40）且一条为**负**；`[13,20)` vs `[14,19)` 四条同数 ⇒ **与约束宽无关、纯边界** |
| 1 条 `F_lat_words_w560` | **shim 侧 · 折叠边界（拉丁）** | ΔW 仅 +0.0140（宽度基本对），但 `cr` 起止各 ±1 字 ⇒ 边界判定差，不是宽度差 |
| 3 条"非 Tab 行宽超差" | **同源**（同上，NBSP/ZWSP）—— **但涉及另一个字段**（§2） | 数值与段1 折叠行逐字相同 |
| `M_modifier_*`（另有 7 条在 >0.34 桶里） | **shim 侧 · `M_modifier` 语义**（已在册，属 T1c 的 `M_modifier` 透传那一族） | `Len=63/56/50 vs 我们 6..44`、`cr 真值 (47,16)` 恒定 vs 我们随宽度变 ⇒ 语义差 |

## 3b. ⭐⭐ 子发现（主控裁定 1）：**`cr.Width` 出现负值 —— 契约上不合法**
| 用例 | 行 | 真值 `cr.Width` | 我们 `cr.Width` | 差 |
|---|---|---|---|---|
| `F_nbsp_zwsp_w40` | **#3** | **+3.3433** | **−3.0560** | **−6.3993** |

**这一条不是"差 6.40 DIP"，而是"宽度为负"** —— 宽度在契约上不可能为负 ⇒ **该族"必修"的第一判据是 `cr.Width >= 0`**，
而不是"与真机差 6.40"。另两条同族只差宽度的行是 `F_nbsp_zwsp_w40#1`（4.8640 vs 9.0233）与 `F_nbsp_zwsp_w80#1`（28.4480 vs 34.8467），
它们的宽虽为正、但同样偏小 ~1 字的 advance。**断言顺序（牙）**：先 `cr.Width >= 0`（当前必红），再 `|cr.Width − 真值| < 0.34`。

## 3c. 队列与归属（主控裁定 2，覆盖我 §4 的原建议）
- **顺序**：`D-T1`（T1d，等 U1 arm）→ **`M_modifier`**（T1d shim 半 + T1c 2~3 行 + 我 1 行传 meta）→ **NBSP/ZWSP 折叠族（本族）**。理由：`build/shims/**` 同时只有一个 owner（T1d 是当前 owner）。
- **归属调整**：**shim 的修由 T1d 落**；**我负责 oracle 与断言（牙）**；牙**与修一起落**（同一源文件里才有意义）。
- **我待命时要交的两件**：① **断言的精确落点**（`Program.cs` 行号 + 断言形态）；② **给 T1d 的逐例表**（本报告 §1 就是雏形）。
- **隔离证明**（修完必须给）：**只动这三族、其它家族一位不动**的逐族对照。
- **我不动**：`M_modifier_*`（归 T1c 那族）。

## 3d. 纪律更新（主控并入）：三元组 → **四元组**
`(被测件 sha, 仪器/harness 版本, 判据口径, **artifact 名 + 字段名**)` —— 本轮实例：同样三个 case+行，
**折叠明细 artifact 的 `W`（cr 上下文）** 给 `+9.6807/+2.6233/+8.5460`，**`t2d-width-diff` 的 `TextLine.Width`** 给 `+4.1567/+6.7167/+6.3927`。
**引用任何数字必须写清后两项**。

## 3e. 断言落点（现在就给，便于 T1d 修完直接接）
段1 折叠断言的既有落点：**`tests/HbTextLineParity/Program.cs:472-479`**（`JsonElement Ecr = …GetProperty("ce").GetProperty("cr")[0];` 起，`bool okDetail = collapsed.Length == eLen2 && dW < 0.34 && cr != null && cr.Count == 1` + 三条 `&&` 断言：`cr[0].TextSourceCharacterIndex == 真机` / `cr[0].Length == 真机` / `|cr[0].Width − 真机| < 0.34`）；证据串在 **:488-501**；失败样例进 `colSamples`。
**要加的两条**（同一处，即 `:476` 那条 `okDetail`）：① `cr[0].Width >= 0`（硬断言，当前对 `F_nbsp_zwsp_w40#3` 必红）；
② 逐例断言 `cr[0].Start/Length == 真机`（8 条里 5 条当前必红，3 条只差宽度）。
**阳性对照**：把 `cr.Width` 容差临时设 0 ⇒ 3 条"只差宽度"的行必须红 ⇒ 证明牙活着。

## 4. 建议（**本轮只读，未改任何源**）
1. **修**（下一轮，我的 shim 车道）：NBSP/ZWSP 折叠口径 —— 目标两条：`cr` 起止与真机一致（±1 字）、`cr.Width` 不再出现**负值**；修完用同一 oracle 复跑，**只许动这三族**（其它家族一位不动 = 隔离证明）。
2. **登记**：`F_lat_words_w560` 的"拉丁折叠边界 ±1 字"单列一档（宽度差可忽略 ⇒ 别混进宽度桶）。
3. **口径不可比**：暂无需要新登记的不可比项（`LH_cjk_punct_*` 那 20 条已登记）。
4. **牙（能变红）**：扩展段1 的既有断言即可 —— 对 8 条逐例断言 `cr 起点/长度 == 真机`；阳性对照用当前 3 条"只差 `cr.Width`"的行（把 `cr.Width` 容差临时设 0 ⇒ 必须红），
   修完再把它收敛到 `cr.Width` 也一致。**本轮未实现牙**（源留给 T1d/T1c；牙要落在同一源文件里才有意义）。

---

# T1b · Tab 配置对齐（1 行）+ 口径更正 + A/B 实测（2026-09-14）

## 1. 那 1 行已落（`tests/HbTextLineParity/Program.cs`）
`layout-b34` 族构造行 → `HbTextLineFactory.FormatParagraph(..., defaultIncrementalTab: 0)`（named arg，跳过中间可选参数），
注释写清理由：**该 oracle 把 `DefaultIncrementalTab` 写死成 0**（`layout-b34/src/LayoutOracle/TextModel.cs:167`）⇒ 那族验的是「**0 宽 Tab**」这一*配置*；
`NaN`（框架默认 `4×em`）是**另一套配置**。

## 2. ⚠️ A/B 实测：它**改善但不等于对齐**（同一 shim `4044d84a…`，只差这一行）
| 读数 | 不传（框架默认 4×em） | **传 `defaultIncrementalTab: 0`** | 差 |
|---|---|---|---|
| 口径·记账结构 | 1263/1298（不等 35） | 1263/1298（不等 35） | 0（这条不受影响） |
| **T2c Tab 不一致** | **25 例** | **21 例** | **−4**（改善） |
| T3 折叠明细 | 210/236 | **214/236** | **+4**（同 4 例连带） |

⇒ **传 0 是对的配置对齐，且实测有 4 例的正面收益，但它没有把 tabs 家族拉回全一致（仍剩 21 例，全部在
`A1_tabs_*` / `B_tabs_*` / `B_tabs_trim_*` / `F_tabs_*`）**。⇒ 剩下的 21 例**不是**"配置没对齐"，而是 **0 配置路径本身还差**：
`0` 在 shim 里走"显式无停靠位"（`<=0 ⇒ 显式无停靠位（旧语料）`），而 oracle 的 `DefaultIncrementalTab=0` 在真机上的语义
（= 增量停靠位为 0 ⇒ 每个 Tab 的推进量 0？断点仍在？）**需要 T1d 用它自己的 57/57 语料再确认一次**。
**我不放宽任何断言**；这 21 例的 id 清单已从本趟日志取出（`A1_tabs_w20..w240`、`B_tabs_*`、`F_tabs_*`），**交接给 T1d**（Tab 的实现与 oracle 在他们车道，源 `4044d84a…`）。

## 2b. ⚠️ **tabs 家族尚未全一致**（别让"传 0 了 ⇒ 应该全绿"的印象留下）
**传 `defaultIncrementalTab: 0` 之后仍不一致 21 例**（同 shim `4044d84a…`；不一致全在这四个家族，无一例在其它家族）：
```
A1_tabs_w20  A1_tabs_w30  A1_tabs_w40  A1_tabs_w50  A1_tabs_w60  A1_tabs_w70  A1_tabs_w80
A1_tabs_w100 A1_tabs_w120 A1_tabs_w150 A1_tabs_w180 A1_tabs_w200 A1_tabs_w240
B_tabs_w60   B_tabs_w120  B_tabs_w240
B_tabs_trim_*（同族）
F_tabs_w40   F_tabs_w80   F_tabs_w120  F_tabs_w200
```
（`34 可比例 − 21 不一致 = 13 已一致`；清单来源 = 本趟 harness 日志的 `T2c` 段。）
**归属：T1d**（Tab 的实现与 oracle 在其车道，源 `4044d84a…`）；`0` 在 shim 里走"显式无停靠位（`<=0`）"，
而真机 `DefaultIncrementalTab=0` 的语义（增量 0 ⇒ 每个 Tab 推进 0？断点是否仍在？）需他用自己 57/57 的语料确认。
**本车道不放宽、不改他们的源。**（本报告即为 T1d 的取件处 —— 主控可直接引用本节。）

## 2c. ⭐ 固定表：A/B（同一 shim、只差那 1 行）—— **该行是"配置对齐"，不是"修法"**
| 读数 | 不传 `defaultIncrementalTab`（框架默认 4×em） | 传 `: 0` | 差 |
|---|---|---|---|
| 口径·记账结构 | 1263/1298（不等 35） | 1263/1298（不等 35） | **0 变化** |
| T2c Tab 不一致 | 25 例 | **21 例** | **−4** |
| T3 折叠明细 | 210/236 | **214/236** | **+4** |
> 说明：这 1 行的作用是"**与那条 oracle 的配置对齐**（它把 `DefaultIncrementalTab` 写死 0），**不是**修 Tab 的实现"；
> 它还**不能**让 tabs 家族全一致（见 §2b）。另：主控派单里把"`1286→1263`／Tab `0→25`"记成这 1 行的效果，
> 经 A/B 证实那是**件版本变化**（旧 shim `e1bc947a…` → 新 `4044d84a…`）所致 —— 已在报告与档里更正。

## 3. 口径更正（原句作废，逐字替换）
- ❌ 旧："**T2c Tab 34 例 = 已登记差异·保留红**（真机 = 0 宽 + 特定断点，本实现未做）"
- ✅ 新："**该 oracle（`layout-b34`）把 `DefaultIncrementalTab` 设为 0 ⇒ 那 34 例验的是「0 宽 Tab」这一配置**"；
  **默认配置下的 Tab 真值**由 U1 的 oracle 提供（`tests/parity/windows/tab/`，**114 例**，未覆盖该设置 ⇒ 测的就是框架默认 `4×em`），
  并且**与 T1d 的新实现一致**（其自对拍 57/57、最大逐字差 0.0053 DIP、牙 `pass=10/fail=47` 已验证）。

## 4. 顺带更正（T1d 查出，我原记录说反了）
**WPF 确实有公开的停靠位 API**：`TextParagraphProperties.DefaultIncrementalTab`（`TextParagraphProperties.cs:111-114`，默认 = `4 × FontRenderingEmSize`）
与 `Tabs` / `TextTabProperties`。**本实现只做了默认口径，`Tabs`（显式停靠位集合）未做** —— 如实登记，未实现、未放宽。

## 5. 下一轮（主控已通知，**本轮不做**）
`M_modifier` 透传需跨车道 3~4 行：**我 1 行**（传 meta 的 `modifierStart/End`）+ PC 车道 2~3 行（`CollectLenient` 识别 `TextModifier`，T1c）；
等主控说"开始"再动。

---

# T1b · 宽度分桶 dump + 四口径拆行 + 47 条归因（2026-09-14，主控批准）

## 0. ⭐ 固定引用表（主控要求长期保留）：四个口径**互不为补集**
| 口径名 | 定义 | 当前件读数（shim `e1bc947a…`） |
|---|---|---|
| **口径·记账结构** | `Length + NewlineLength + TrailingWhitespaceLength + (WITW−W)` 逐行全等 | **1286/1298**（不等 **12** 行：①硬断 286/286 ②空行 68/68 ③行尾空白 **984/988**） |
| **口径·宽度分桶** | 逐行宽 vs 真值：`0`（逐位等）/ `≤0.34 DIP`(=1 ideal unit) / `>0.34 DIP` | **0=167 / ≤0.34=1084 / >0.34=47**（三桶和==1298 **机检 OK**）；最大差 **282.219333 @ `M_modifier_winf`** |
| **口径·Extent 行级**（容差 0.01） | 逐行 Extent | **1260/1298**；余差清单 **58** = 主对拍 **38** + LH 组 **20**（LH 组按"代用字体不可比"登记） |
| **口径·折叠明细** | 真折叠 **236** 行的逐行明细 | **218/236** |
| （独立类）**Tab** | 真机 `\t` = 0 宽 + 特定断点，本实现未做（T2c，保留红） | Tab 可比例 **34 例，不一致 0** ⇒ **不在这 47 条里** |

⚠️ **旧值标记**：`1276/1298 + 宽度超差 83` 是**旧件读数**（9/11 的 `gen/t1b-tline.txt`，被测 shim `E019DB56…`），
**勿用于当前判定**；当前件（shim `e1bc947a…`）就是 `1286/47`。二者差异**由件版本驱动**，与 app-local 新鲜度无关（实测见上一节）。

## 1. 落地：dump + 三桶和机检 + 牙（都在我车道）
- **新产物** `gen/t2d-width-diff.txt`：逐行 `用例 | 行# | cp 区间 | 真值宽 | 我们宽 | 差 | 桶`（与 `t2d-extent-mismatches.txt` 同格式），
  表头带被测 shim sha 与"三桶之和 == 行数"的口径说明；本清单只列差>0 的行（**1131 条**，1298−167）。
- **机检断言**：`0+≤0.34+>0.34 == 行数` ⇒ 打印 `（三桶和==1298 机检：OK）`（不成立会打印 FAIL）。
- **汇总行按口径拆成各自一行**（T3 指出旧行把 `1286` 与 `47` 粘在一起）：
  `[口径·记账结构] 全等 1286/1298（不等 12 行：…）` / `[口径·宽度分桶] 0=… / ≤0.34DIP=… / >0.34DIP=…（三桶和==1298 机检：OK）最大差 …` /
  `[口径·Extent …]` / `[口径·折叠明细] …`；**四个口径名也写进了 harness 头注释**（"每个数字属于哪个口径"）。
- **牙（实测能红）**：`T2D_WIDTH_INJECT=<DIP>` ⇒ 给**第一条可比行**人为放大差值并大声打印 `[注入] …（自检用，不是测量）`：
  · 注入 `1.0` ⇒ 该行 `差=1.0007 桶=>0.34 DIP`，分桶变 `≤0.34=1083 / >0.34=48`（**47→48**，正好抓一行），文件头加 `⚠️ 本趟含…人为注入`；
  · 不设该 env（还原）⇒ 清单头与首行**逐字回到**基线 `≤0.34=1084 / >0.34=47`、`差=0.0007 桶=≤0.34 DIP`。
  ⇒ 谁把 dump/分桶改坏，牙必红；**当前落盘的 `gen/t2d-width-diff.txt` 是基线（无注入）那份**。

## 2. 47 条 `>0.34 DIP` 的归属（逐族统计，来自落盘清单）
| 用例族 | 条数 | 归属 | 依据 |
|---|---|---|---|
| `A1_nbsp_zwsp` / `F_nbsp_zwsp` / `B_nbsp_zwsp` / `B_nbsp_zwsp_trim` | **25 + 10 + 4 + 1 = 40** | **shim 侧**（NBSP/ZWSP 空白口径） | 与 `gen/tline-ledger-lines-20260914-1827.txt` 的 6 条 `ws` 桶同源（12 条行账里 6 条 NBSP/ZWSP） |
| **`M_modifier_*`** | **7** | **shim 侧**（`M_modifier` 行区间/强制断语义） | 三条最大差全在这里：`M_modifier_winf` 行#0 cp=[0,63) 真值 156.9167 vs 我们 **439.1360**（差 **282.2193**）、`M_modifier_w320` 差 157.2113、`M_modifier_w120` 行#1 cp=[12,19) 差 55.2693 ⇒ 不是"量化余差"而是**语义差** |
| `LH_cjk_punct_*`（在 Extent 58 里 20 条） | 0（宽度桶里没有） | **口径不可比**（CJK 代用字体） | 已在册登记 |

**⇒ 确切答案（主控问的）**：`>0.34 DIP` 那 47 行里 **`M_modifier_*` 恰好 7 行**，其余 **40 行全是 NBSP/ZWSP 家族**。
**给 T1d 的指针**：这 7 行（含最大差 282.219333）在 `gen/t2d-width-diff.txt` 里筛 `M_modifier` 即可取到，
与 T1d 的 `M_modifier` 判定**同一个根**（行区间/`nl` 语义：12 条行账里 6 条也是 `M_modifier`，期望 `Len=50 nl=0` 实得 `Len=6 nl=0`）。

## 3. 口径纪律（本条已按主控要求固化）
引用**本车道历史文件**（`gen/t1b-tline.txt` 等）前**先看被测件 sha**——`1276/83` 就是这样被误当"当前读数"的；
报告里所有读数都带 shim sha 与文件路径，口径名写在数字旁。

---

# T1b · T2 记账红：三个口径的定义 + 一趟实测（2026-09-14 18:27）

> **一句话**：主控引用的 `1286/1298 + 宽度超差 47` 与我这边的 `1276 + 83` **不是同一个件**，也**不是同一个量**。
> 我用**同一条命令**跑了一趟，逐字复现主控的三个数（`1286/1298`、`47`、`Extent 58`），
> 并**实测反证**了"读数依赖 app-local 新鲜度"这条假设（本趟 app-local **4/4 已同步**，读数照样是 1286/47）。

## 1. 三个（四个）口径的定义，并排展示 —— 别再让人以为在吵架
| 口径 | 定义（逐字取自 harness 输出） | 我这一趟实测（shim `e1bc947a…`，app-local 4/4 已同步） | 旧件（9/11，shim `E019DB56…`） |
|---|---|---|---|
| **记账结构全等** | `Length + NewlineLength + TrailingWhitespaceLength + (WITW−W)` 全等 | **1286 / 1298**（①硬断 286/286；②空行 68/68；③行尾空白 **984/988**） | 1276 / 1298；③ 977/988 |
| **宽度绝对值分桶**（"宽度超差 47"） | 逐行宽 vs 真值：`0`（逐位等）**167** 行；`≤0.34 DIP`（= 1 个 ideal unit）**1084** 行；**`>0.34 DIP` 47 行**（167+1084+47=1298 ✓） | **超差 47**；最大差 **282.219333 DIP @ `M_modifier_winf`** | 83 |
| **Extent 行级** | 逐行 Extent，容差 **0.01 DIP** | **1260 / 1298**；余差清单 **58** 条 = **主对拍 38 + LineHeight 组 20** | — |
| **折叠明细** | 真折叠 **236** 行里逐行明细全等 | **218 / 236**（折后宽度最大差 144.816 @ `M_modifier_winf` 行#0） | — |
| **Tab**（第 6 问） | 单独一类（T2c）：真机 `\t` = **0 宽 + 特定断点**，本实现未做 | `Tab 可比例 34 例，不一致 **0** 例` ⇒ **Tab 不在那 47 条里**（它是**独立登记类**，且本趟不一致为 0） | 旧件只在"行数 2≠1"清单里出现 ⇒ 旧件口径，不用它下结论 |

**⇒ 所以：`58` 与 `38` 是两个口径**（58 = 38 主对拍 + 20 LH 组）；`47` 是**宽度分桶**（>0.34 DIP 的行数），
不是"47 个用例"；`1286` 是**记账结构**行数，不是宽度。三者可以同时成立、互不矛盾。

## 2. 实测反证：`1276 → 1286` **不是** app-local 新鲜度造成的
我这一趟用的是同一条命令 `bash build/MilBridge/run.sh tline`，跑前/跑中打印：
```
[applocal] 汇总：4/4 权威产物均已就位并与副本一致/已同步
测量对象（app-local 副本）： PC=6BE29475B6AEB34E  WB=E6216FE961A2BFB9  DWF=2F77DBDF5E7E2CD5  Provider=71BA86C6495347FE
被测 shim 源 sha256 = E1BC947AFC248B323E227BA0F55E8E36A25DD791F92C3E8BA767F841DF402860
```
⇒ **在 app-local 已同步到当前权威件的前提下，读数仍是 1286/47**。而旧件（`gen/t1b-tline.txt`，9/11，
shim `E019DB56…`）才是 1276/83。**结论：差异由件版本（shim/harness）驱动，不由 app-local 新鲜度驱动**；
"读数依赖 app-local 新鲜度"这条假设**不予采纳**（除非将来有"同件不同读数"的实测）。

## 3. 我能立刻分桶的两张清单（47 条的逐行 dump 目前缺失）
| 清单 | 条数 | 现成桶（实测统计） |
|---|---|---|
| `gen/tline-ledger-lines-20260914-1827.txt`（行级记账不一致） | **12** | **6 条 = 行尾空白计数(ws)（NBSP/ZWSP 家族）**；**6 条 = `M_modifier_*`**（4 条 `nl`/硬断、2 条 `Length` 行区间） |
| `gen/t2d-extent-mismatches.txt`（Extent 余差，容差 0.01） | **58** | `A1_nbsp_zwsp` **21**、`F_nbsp_zwsp` **8**、`M_modifier` **4**、`LH_cjk_punct_*` **20**（= LH 组，按"代用字体不可比"登记） |
| **宽度超差 47（逐行 cp 区间/真值/我们/差）** | — | **harness 目前只打印分桶直方图 + 最大值，没有落盘逐行 dump** ⇒ 要按`用例/行号/cp/真值/我们/差`逐条归因，需要我在车道内加一行 dump（`gen/t2d-width-diff.txt`），**这是纯 `build/MilBridge/**` 改动**，等你一句话我就做 |

## 4. 归属（先给能定的，其余等 dump）
- **NBSP/ZWSP 家族的行尾空白计数（12 条里的 6 条）** ⇒ **shim 侧**（折叠/空白口径；同一 `(cp,len)` 但 `cr` 宽度符号相反的历史桶同源）。
- **`M_modifier_*`（12 条里的 6 条 + Extent 里的 4 条 + 折叠最大差所在例）** ⇒ **shim 侧**优先怀疑（`M_modifier` 的硬断/行区间与真机不同：期望 `Len=50 nl=0` 实得 `Len=6`，期望 `nl=1` 实得 `nl=0`）。
- **`LH_cjk_punct_*` 20 条** ⇒ **口径不可比**（CJK 代用字体；已在册登记"代用字体不可比"），不是缺陷。
- **Tab** ⇒ 独立类（T2c），**不在这 47 条**，真机真值 U1 正在收。

---

# T1b · runner 车道：修掉"注入前读数下注入后结论"（时间点型假阳）+ 同族扫荡（2026-09-13）

## 1. 结论句口径已改（T1c §35.5，两处）
- `run-wpfprobe.sh:705-714`（原"瓶颈在托管输入栈 / DP 陈旧 ⇒ INCONCLUSIVE"）⇒ 现在是：
  · `changes=0` 若取自**注入之前**的台账行 ⇒ **无信息**（**不是**"键没进"）；键是否到位另看 `WFP_MSGS WM_CHAR` 与 `KEY_DIAG`；
    **本行不得单独下"输入栈"结论**；
  · 像素/容器对 **且 `Text` DP 有写后读数且陈旧** ⇒ 记**缺陷**；**没有写后读数** ⇒ 记 `INCONCLUSIVE(无信息)`，**不许**写成"陈旧"；
  · 指向判定工具 `build/MilBridge/tools/t1c-dp1-leg-audit.py`（rc 0=closed / 2=defect / 3=noinfo）。

## 2. 取值本身也修了：`tail -1` → **按注入时刻的行号下界**
- 新增 `INJECT_AT_LINE="$(wc -l < "$OUT/feat-lines.txt")"`，**在 `xdotool key/type` 之前**取（`run-wpfprobe.sh:376-381`）；
- 取值改走 `build/MilBridge/tools/pick-feat-line.py --after-line "$INJECT_AT_LINE" --keys changes,text`
  ⇒ 输出 `<status>	<changes>	<text>`，`status ∈ AFTER | NOINFO`；**NOINFO 就不许写"陈旧"**。
- **排序前提写进了注释与工具文件头**：`feat-lines.txt` 是追加写（行号=写入时刻序），但同一逻辑事件有
  `late:`(LateVerify) 与 `OK`(Verify) 两个变体，`OK` 可能被 ~10s 首帧拖到 `late:` **之后**（实测 L599<L734）
  ⇒ **"最后一行"≠"注入之后那一行"**；唯一可靠下界是注入时刻的行号。

## 3. 同族扫荡（这两个 runner 全量，逐条处置）
| 位置 | 形态 | 处置 |
|---|---|---|
| `run-wpfprobe.sh:720-721` | `feat-lines.txt` + `tail -1` | **已修**（按注入行号；NOINFO≠陈旧） |
| `run-wpfprobe.sh:411/413/415/416/422/423` | 应用日志 `$log` + `tail -1` | **不改**：应用日志单调追加，"最后一条=最新"成立；**但若该事件将来出现 late 变体，必须改成按事件类型+时间点取**（登记为同族风险） |
| `run-wpfprobe.sh:587` | `probe-*.log` + `tail -1`（`WFP_BOXID` 行） | **不改**：同 ID 的行是 dump 覆盖式记录，取最新正确 |
| `run-wpfprobe.sh:604` | `GlyphRun×N` + `sort -n | tail -1` | **不改**：取**最大值**（聚合），不是"最后一行" |
| `run-wpfprobe.sh:768` | triage 复跑后 `[feat] $b` + `tail -1` | **不改**（有意）：复跑行必然晚于一切 ⇒ "最后一行=复跑结果"成立；**前提 = `$OUT` 每次运行独立**（已登记） |
| `run-wpfprobe.sh:57/519/539` | `head -1` | **不改**：单行单值 / 首匹配 |
| `run-wpfprobe.sh:234/320` | `head -1`（最新 `.cs` / 首个窗口 id） | **不改**：按 mtime 排序 / 首个匹配 |
| `run-hellowpf.sh:107/144` | `fc-scan … head -1` / 构建日志 `tail -15` | **不改**：单值 / 尾部错误摘要 |
| 相邻同类（主控给的） | `grep -c "0x0102"` 假阳 | **按新口径**：写 `grep "msg=258(0x0102"`（行尾 `队列内容=[…]` 也含 `0x0102`） |

## 4. 牙（能变红，已实测）
`build/MilBridge/tools/pick-feat-line.py --self-test` —— 四组假日志：
1. `late` 早于 `OK`、**都在注入之前** ⇒ 必须 **NOINFO**（复现被推翻的那条结论的姿态）；
2. 注入之后仍 `changes=0` ⇒ 必须 **AFTER + changes=0**（**这时才允许**记"陈旧"）；
3. 注入之后 `changes=3` ⇒ 必须 **AFTER + changes=3**；
4. `late` 排在 `OK` **之后**（L599<L734 那种形态）、都在注入前 ⇒ 仍 **NOINFO**（顺序颠倒不影响结论）。

**红证**：把 `pick()` 换回旧的"取最后一行"语义再跑同一套假日志 ⇒ 第 1、4 组立刻 ❌、进程 exit 1
（即"谁把口径改回 `tail -1`，牙必红"）。绿态：`exit 0`，四组全 ✅。

## 5. 边界与交接
- 只动 runner 脚本（`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh`，本轮由主控派工点名）与 `build/MilBridge/**`；**没碰 `samples/**`**。
- **给 T3 的交接**：`samples/**` 侧若要让"写后读数"更可靠（例如把 `Verify`/`LateVerify` 合并成单一"注入后校验"事件，
  或给台账行加显式序号/时间戳），那是样例侧改动 ⇒ 由 T3 决定；runner 侧已经**不依赖**行序假设，改动可独立进行。
- `bash -n run-wpfprobe.sh` 通过；端到端跑该 runner 需要显示槽（本轮没有占用来跑整链）。

---

# T1b · 桥测试车道的数字一致性（2026-09-11 晚）

## 1. 陈旧断言 A5（`NotImpl` 计数）
**结论：已修（在本文件 §"已修" 处登记过），现在两边都是 27，且有牙拦着。**
- `build/MilBridge/tests/ClosedLoop/Program.cs:219-226`：`notimpl == 27`，**算式写进注释**（27 = 4 个 InteropDeviceBitmap + 22 个 MILMedia + `MilResource_SendCommandMedia`；并注明"判定代码那一行不是清单条目"）。
- `tests/WpfGfx.Linux.Tests/Commands.Tests/MilExportTests.cs:214-216`：同样 27，注释写明"与 real 是一对：NotImpl→Real 必须一起改"。
- **真值口径（避免上次那个坑）**：数**清单条目**（`gen/landing-table.md` 的 NotImpl 行 = **27**），
  **不是** `grep -c ExportDepth.NotImpl`（它会把判定语句 `if (pair.Value == ExportDepth.NotImpl)` 也数进去 ⇒ 多 1）。这条已写进牙的文件头。
- 重算方法：`python3 build/MilBridge/tools/check-export-numbers.py`（输出 `Real=61 State=12 NotImpl=27 Identity=9`，和 = 109）。

## 2. 「一个数字两个消费者」全车道扫描结果
| 数字 | 唯一真值来源 | 消费者 | 处置 |
|---|---|---|---|
| 导出总数 **109** | `gen/export-symbols.txt`（109 行）/ `gen/landing-table.md`（109 行） | `ClosedLoop/Program.cs:212` `n == 109` | 保留硬编码，但**由牙对拍** |
| NotImpl **27** | `gen/landing-table.md` 的 NotImpl 行 | `ClosedLoop:225`、`MilExportTests:216` | 同上 |
| Real/State/Identity **61/12/9** | 同上 | `MilExportTests:210-213` | 同上（四个断言之和 == 109 也被牙检查） |
| 分布串（**陈旧重复**） | 同上 | `T1-report.md` 的"实现深度分布"行写的是 **Real 60 · NotImpl 28** | **已修**为 61/27，并在行内标注真值来源 |
| `NotImpl 29→28`（`T1-report.md:1501`） | — | 历史变更记录 | **保留**（它写的是"当时那次变更"，不是当前真值；已在本表登记以免误读） |

## 3. 能变红的牙
`build/MilBridge/tools/check-export-numbers.py` + `bash build/MilBridge/run.sh nums`：
- **绿**：清单表与全部消费点一致（`Real=61 State=12 NotImpl=27 Identity=9`，四者之和 109 == 符号清单 109）。
- **能变红（自检实测）**：把真值改错 ⇒ 立刻报 `ClosedLoop.A5 写的是 28，真值 27`；改回 ⇒ 0 个问题。
  `--self-test` 就是复现"当年那个 stale 28"，所以这把牙以后**不会**变成装饰。
- 牙**不依赖桥、不加载 `.so`**（纯静态解析清单表 + 消费点），所以可以在"发布目录收尾、别跑加载桥的应用"的窗口里跑。

## 4. 三条读数（主控 00:20 放行后**已跑**，命令原文 + 结果）
放行条件已核：`/tmp/bridge-republish.lock` **不存在** ✓；未发桥（桥 = `c66083443200115d`）✓；只跑测试、不改桥。

```bash
# [1] ClosedLoop 全组（A5 在内）—— 54/54
bash build/MilBridge/run.sh test
#   == 通过 54 / 失败 0 / 跳过 0 ==                                  退出码 0
#   PASS  A3    MilNative.ExportManifest 条目数 == 109（上游 108 + 跨运行时字体面登记 1）
#   PASS  A5    NotImplExportNames 计数（29 − 1 SetNotificationWindow − 1 #24 = 27）

# [2] Commands.Tests 的 MilExport 过滤（**不加 --no-build**）
#     ⚠️ 主控给的文件名 Commands.Tests.csproj **不存在**；实际是 WpfGfx.Linux.Commands.Tests.csproj
dotnet test tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj -m:1 --filter MilExport
#   已通过! - 失败: 0，通过: 196，已跳过: 0，总计: 196，持续时间: 1 s (net10.0)   退出码 0

# [3] 数字一致性牙（改动后仍绿）
bash build/MilBridge/run.sh nums
#   [绿] 清单表与所有消费点一致（唯一真值来源：gen/landing-table.md）  退出码 0
#   [自检] 牙能变红 ✅：真值改错 ⇒ 1 个问题（ClosedLoop.A5 写的是 28，真值 27）；改回 ⇒ 0 个问题
```

**`--no-build` 口径核对（主控提醒的"陈旧 DLL 假读数"）**：`grep -n "no-build\|no-restore" build/MilBridge/run.sh` → **0 命中**
⇒ 本车道的 `run.sh test` **每次都先构建** ClosedLoop（`dotnet build -c Release -m:1` → `.artifacts/`）再运行，
**不存在**"构建失败 + 陈旧 DLL 出绿"的跑法。`run.sh test` 里那句 `env -u LD_LIBRARY_PATH dotnet …` 是**刻意**的
（验证 `.so` 自带 SkiaSharp 解析 = M7c3 的 dladdr 修复），不是省构建。

---

# T1b · B2（托管 `TextLine` 断行 / 折叠 / 断行记录）—— 报告（2026-09-11）

> **一句话**：三个成员做**实**了（`GetTextLineBreak` / `Collapse` / `GetTextCollapsedRanges`），
> 断行规则**唯一一份**搬进了 shim；**73 例逐行全等 73/73**、三类记账 ①286/286 ②68/68 ③977/988，
> 折叠判定 1298/1298；**四处与真机的差异全部保留红并登记**（Tab / NBSP·ZWSP / Display / 折叠前缀边界），
> 没有为了变绿放宽任何断言。

## 0. 交付物与"落的就是测的那一份"

| 产物 | sha256 / 数字 |
|---|---|
| `build/shims/PresentationCore.HbTextLine.cs`（**波 8 编的就是这份**） | `de6133fc040e8a99…` / **1438 行** / 79,097 B / mtime 16:40:34 |
| 我报"落地"的那一版 | `6c9af7e8d168bf4f…` / 1435 行 / 78,914 B |
| `build/shims/PresentationCore.HbTextLine.cs`（**v3 = 当前落地版**：v2 + D3 的惰性接线钩子） | `a92ad605a6f307f5…` / **1689 行** |
| v2（折叠精化落地版，已被 v3 取代） | `a35ffaff83f3f2e0…` / 1468 行 / 81,362 B |
| staging（= v3，逐字节一致） | 同上 |
| `build/MilBridge/tools/t1b-ls-tripwire.sh` + `t1b-ls-selftest.c` | LS 边界绊线装置 + 自证 |
| `build/MilBridge/tools/extract-layout-b34.py` / `analyze-layout-b34.py` | 真机 oracle 流式抽取 / 三类记账独立复算 |
| `build/MilBridge/tests/HbTextLineParity/`（新 harness） | 驱动**真 shim 源**的对拍主体 |
| `build/MilBridge/tests/DirectBranchCheck/`（新） | `TEXTLINE_SHIM_DIRECT` 直构分支**编译闸门** |

**"测的到底是哪个文件"现在由机器挡**（`T0.6`）：`run.sh` 把它传给编译器的那个文件的 sha256 用 env
`T1B_SHIM_SHA256` 传进去，harness **自己再读盘算一次并逐字符比对**，不一致就大声失败。
本报告所有 harness 读数都带这一条 ✅。

**披露（我的流程错）**：落地（`6c9af7e8`）之后我又往 `build/shims/**` 补了一个只读诊断属性
`LineTextForDiag`（3 行、行为中性）而**没有重报 hash** ⇒ 磁盘变成 `de6133fc`。
三个 sha 因此互不相同。**根因是"落盘后未重报 hash"，不是数据错**；本报告 §2 的读数是在
`de6133fc`（= 波 8 编的那份）上**重跑**得到的。

---

## 1. 做了什么

1. **断行规则唯一真源搬进 shim**：`HbBreakEngine`（ICU UAX#14 断点集 + `…` 前可断 + 禁则拉字 +
   强制断 fallback）从 `tests/IcuBreakParity/Program.cs` **原样搬**进 `build/shims/PresentationCore.HbTextLine.cs`；
   `IcuBreakParity` 改成 `<Compile Include="…shim…" -p:HbShimSrc>` + `TEXTLINE_BREAK_ENGINE_ONLY`
   **只驱动那一份**（探针里**不再有任何规则代码**）。
2. **`GetTextLineBreak()`**：普通文本 ⇒ **null**（真机 3220/3222）；只有 TextModifier 情形才 new
   **真的** `TextLineBreak`，且 `_breakRecord = IntPtr.Zero`、`_currentScope = null`（**不伪造**原生断行记录），
   两条路径**各记一个计数器**。
3. **`Collapse` / `GetTextCollapsedRanges`**：按 `FullTextLine.cs:693-800` 的 7 条顺序真实现
   （资格闸门 → 空参抛 → 约束宽闸门 → 前缀贪心 → 折后 Length/Width → collapsedRange → 未折叠返回 **null**）。
4. **`GetIndexedGlyphRuns` 仍留 owed**（上游 0 调用点，主控裁定不实现）；欠账从 9 个降到 **6 个**。
5. **修掉一个真 bug**：`hb_buffer_add_utf8` → **`hb_buffer_add_utf16`**。原实现把 HarfBuzz 的
   **UTF-8 字节偏移**当成 UTF-16 下标去求逆 cluster，纯 ASCII 看不出来，73 例 CJK 会整体失准。
6. **`GetTextBounds` 的索引口径修正**：真机第一个参数是**段落系**（oracle `indexFrames`），
   原来按行内偏移算是错的。
7. **新增装置**：`DirectBranchCheck`（直构分支预编译）、`HbTextLineParity`（对拍主体）、
   `t1b-ls-tripwire.sh`（LS 绊线）、两个 oracle 工具脚本。

---

## 2. 原始读数（验收 1–4 逐条）

### 验收 1 —— 73 例逐行全等
```
$ bash build/MilBridge/run.sh icu
被测文件 = build/shims/PresentationCore.HbTextLine.cs  sha256=de6133fc040e8a99…  (1438 行)
被测文件 = … sha256=DE6133FC040E8A99…  ✅ 与 run.sh 固定的 sha 一致
   → Stage A：**真不一致 0 例**；依赖强制断 fallback 的例数 5
   → Stage B：**逐例全等 73 例 / 不同 0 例**（共 73 例）
   → Stage C：禁则 40 一致 / 0 不一致；对照(allow) 2 例一致；conflict 6 例（不判，Stage B 覆盖）
⇒ **一致**：73 例逐例全等（= ICU 断点集 + `…` 前可断 + 禁则拉字 + 强制断 fallback，规则真源 = shim 的 HbBreakEngine）
→ 探针退出码 0
```
同一批语料再由**真 `HbTextLine`** 走一遍（`run.sh tline`）：
```
  ✅ T1.73 73 例 CJK 逐行全等（判据：必须 0 不同）   exact=73 diff=0 cases=73
```
（这条不是重复：`icu` 只驱动引擎，`tline` 驱动 `HbTextLineFactory → 真 HbTextLine → Length/NewlineLength`，
行起点由**累加 Length** 得到 —— 真机 `TextLine.Start` 恒 0，不能用它。）

### 验收 2 —— `run.sh textline` 未退步
```
  PASS  A7b B2 三个成员的真机口径：普通文本 GetTextLineBreak()==null、未折叠 GetTextCollapsedRanges()==null、
           非可折叠行 Collapse(空参)==this、且**不发零记录**
  PASS  A8  严格模式下：**仍欠账的会抛、已真实现的不抛**
[汇总行] HB_TEXTLINE enabled=0 lines=0 … fallbackTotal=7 … breakZeroRecords=0
== 通过 10 / 失败 0 ==            （原为 9/9；A7/A8 按 B2 新语义重写，不是删断言）
```
形状/绘制主链路**逐字未变**：字形 37 / `Width=493.4880` / 基线 25.6560 / 非白像素 3954 / PNG 4722 B。

### 验收 3 —— 三类记账的覆盖数与一致性（用真机 oracle 独立复算）
harness 对拍面：**file 字体 + Ideal 模式 + 非 RTL = 1298 行 / 315 例**（其余 **299 例只统计不给结论**：
zh/ja 字体 Linux 没有、Display 模式未实现、RTL 需 bidi）。**用例级**：行划分 + 结构记账全等 **271/315**。

| 记账 | 判据 | 覆盖 | 一致 |
|---|---|---|---|
| ① 行区间**含**硬断字符 | `Length` 与 `NewlineLength` 同时精确相等 | **286 行**（真硬断行；另有 614 行末行 EOP） | **286/286** |
| ② 相邻 `\n` 不是零长度行 | `Length==1` 且 `Width==0` 且 `nl==1` | **68 行**空行 | **68/68**（零长度行真机 **0** 行） |
| ③ 行尾空白占区间不占宽 | `TrailingWhitespaceLength` 相等 + `WITW−W` 两侧一致 | **988 行** | **977/988** |
| 合计（结构） | Length+nl+ws+(WITW−W) | 1298 行 | **1276/1298** |
| A 组断行位置 | 行首位置 + 行可见长度 | 213 例 / 965 行 | **207/213 例；964/965 行**（差的 6 例全是 `A1_tabs`） |

③ 的 11 行与 T2 的 22 行差异**全部落在两族**（已登记，见 §3）；`Width` 绝对值的分布单独报：
167 行逐位相等 / **1048** 行 ≤0.34 DIP（= 1 个 **ideal unit**）/ **83** 行 >0.34（最大差 282.219333 DIP，在 `M_modifier_winf`）。
`WITW−W` 关系两侧**逐行一致**（样例：真机 `ws=1 WITW−W=4.1600` | 实得 `ws=1 WITW−W=4.1600`）。

### 验收 4 —— 每个新增"做不到"点：真实现或带计数器
`HB_TEXTLINE …` 汇总行（**只追加不改名**，绊线脚本的 grep 锚点保留）：
```
HB_TEXTLINE enabled=0 lines=3776 … fallbackTotal=0 Collapse=0 … GetIndexedGlyphRuns=0 … GetTextLineBreak=0
  paragraphs=689 breakNull=7 breakZeroRecords=2 modifierLines=30
  collapseCalls=2596 collapseIneligible=2090 collapseTooWide=17 collapseEmptyArgsThrow=253
  collapseApplied=236 collapseUnsupported=0 collapsedRangesNull=1062 collapsedRangesReturned=236
  forcedBreakLines=573 kinsokuPulls=29 dependentLengthQueries=0
```
* `Collapse`/`GetTextCollapsedRanges`/`GetTextLineBreak` 的**欠账计数恒 0**（真实现）；
* `DependentLength` **未实现**（真机有 0..3 真值）⇒ 返回 0 但**每次读都计数**（`dependentLengthQueries`）；
* `HasOverflowed` 恒 false（真机 3222/3222 全 false），"内容没放下"的信息不丢：`forcedBreakLines`；
* `collapseUnsupported`（非 CharacterEllipsis / 符号不是 U+2026）⇒ 记数 + 原样返回。

### 折叠（Collapse）真机对拍
```
  折叠判定一致 1298/1298；真折叠 236 行，明细全等 198/236
  空参：可折叠行抛 ArgumentNullException 253/253；不可折叠行原样返回 this 1045/1045
  未折叠行 GetTextCollapsedRanges() 必须 null ⇒ 逐行核过（真机 3222/3222 null）
  样例 F_lat_words_w40 行#0: 真机 Len=4 W=21.5533 cr=[1,3) W=6.2533 | 实得 Len=4 W=21.5520 cr=[1,3) W=6.2560
```

### `GetTextLineBreak` 语义 + LS 边界（`run.sh tline` 尾段）
```
  ✅ T5.1 普通文本（无 TextModifier）：每行 GetTextLineBreak() 都是 null（真机 3220/3222 null）
  ✅ T5.2 modifier 情形：拿到**真的** TextLineBreak 对象
  ✅ T5.3 零记录：_breakRecord = IntPtr.Zero 且 _currentScope = null（**不伪造**原生断行记录）
  ✅ T5.4 Clone() 不崩、返回**新实例**（真机 cloneIsSameReference=false），克隆体也是零记录
  ✅ T5.5 Dispose() 对零记录不调 LoDisposeBreakRecord；两实例各自 Dispose 一次不崩
  ✅ T5.7 WPF_LINUX_TEXTLINE_STRICT=1 时零记录**当失败上报**（抛出，不吞）
```
**所有权/引用计数口径（说清）**：`TextLineBreak` 在 WPF 里**没有引用计数** —— 一次 `GetTextLineBreak()`
产出一个**独占**实例，所有权随 `FormatLine(..., previousLineBreak)` 交给下一个消费者（它读 `BreakRecord`
/`TextModifierScope` 后 Dispose）。我们的零记录实例：`Dispose()` 是**空操作**（上游 `DisposeInternal`
只在 `_breakRecord != IntPtr.Zero` 时下探原生）⇒ **不存在双重释放**；`Clone()` 返回**另一个**零记录实例
（不会调 `LoCloneBreakRecord`）。**多处共享同一个实例是安全的，但没必要**：多次调用各得一个。

### LS 边界绊线：`LoAcquireBreakRecord` / `LoCreateLine` 被调到没有？
**装置自证（先证装置不撒谎）**：
```
  LoAcquireBreakRecord: 被查找 9 行 ⇒ MISS（翻遍 9 个库没找到 ⇒ 真被调到就会抛 EntryPointNotFoundException）
  LoCreateLine:         被查找 9 行 ⇒ MISS
  LoCreateContext:      **没有**被查找过（0 行）
  LsDisableSpecialCharacterLigature: 被查找 1 行 ⇒ FOUND（只翻了 1 个库就命中：…/libwpfwin32.so）
  ✓ nm -D：LsDisableSpecialCharacterLigature **已定义**（与日志 FOUND 一致）
  ✓ nm -D：LoAcquireBreakRecord **未定义**（与日志 MISS 一致）
⇒ 装置自证 通过（捕获到的查找与 nm -D 事实一致）
```
**真值来源 = `ld.so` 自己的 `LD_DEBUG=symbols` 日志**（不经过我们任何代码）。
**我放弃了 LD_PRELOAD 拦 `dlsym`**：本库自己初始化要用 dlsym，而 LD_PRELOAD 把我们放在全局查找序最前
⇒ `dlvsym(RTLD_NEXT,"dlsym")` 回到自己、bootstrap 不可靠（第一版自证程序拿到 **0 行**日志，`t1b-ls-selftest.c` 保留为对照）。
**装置第一版还踩过一个"假 ✗"**：`nm … | grep -q X && …` 在 `set -o pipefail` 下因 SIGPIPE 误报"与日志矛盾"，
已改成先落变量再判（这类"验证工具自己在说谎"是本项目的老毛病）。

**装置作用域自证（很重要，否则装置会变成"永远 0"的陷阱）**：`build/MilBridge/tests/LsProbe/` 专门验证
"**.NET 侧的 `NativeLibrary.GetExport` 会不会被 ld.so 日志记到**" —— 会（该进程 3 次查找全被记下，
FOUND/MISS 判定与 `nm -D` 一致）。⇒ 本装置对 HelloWpf 这类 **.NET 进程有效**。

**答案（静态）**：`LoAcquireBreakRecord` / `LoCreateLine` / `LoCreateContext` 在 `libwpfwin32.so` 里
**连符号都没有** ⇒ 真走到 LS 的现象是 **`EntryPointNotFoundException`（硬崩）**，不是 `E_NOTIMPL`。

### ⭐ `Dispose()` 对零记录**不碰 LS** —— 计数器读数（不是"应该不会"）
在一个**真的**产生零记录 `TextLineBreak`、并调用 `Clone()` 与 `Dispose()` ×2 的进程里，
把整个进程的 ld.so 符号查找日志拉出来：
```
-- LS 家族符号被查找的次数（Lo*/Ls*/Nl*/Fs*）--
      1 LsDisableSpecialCharacterLigature        ← 这是我**故意**做的对照（证明"能记到"）
（LoDisposeBreakRecord / LoCloneBreakRecord / LoAcquireBreakRecord / LoCreateLine：**0 行**）
```
**读法**：除对照符号外，整个进程**一次 LS 查找都没有** ⇒ `TextLineBreak.Dispose()`（零记录）
**确实没有**下探到 `LoDisposeBreakRecord`，`Clone()` 也没碰 `LoCloneBreakRecord`；
而 `ReferenceEquals(clone, original) == false` 证明 Clone 返回的是**另一个托管实例**。
同进程还有一条独立证据（`T5.8`）：`NativeLibrary.GetExport(h, "LoDisposeBreakRecord")` 抛
`EntryPointNotFoundException`（符号不存在）—— 真要调它必然炸，不可能静默。
存档：`build/MilBridge/gen/t1b-ls-lifecycle-tripwire.txt` / `t1b-ls-lifecycle-probe.txt`。
### ⭐ 活窗口读数（PC 带 B2 重建后，`:98` 配方四坑照做）
| 应用 | `LoAcquireBreakRecord` | `LoCreateLine` | `LoCreateContext` | 对照（应 FOUND） | 结论 |
|---|---|---|---|---|---|
| **HelloWpf**（小文本） | **0 查找** | **0 查找** | **0 查找** | `LsDisableSpecialCharacterLigature` 1 ✓ / `LoGetEscString` 1 ✓ | **根本没走到 LS**（留在 `SimpleTextLine` 快路径）|
| **WpfTextDemo**（文本多） | 0 查找 | 0 查找 | **27 查找 ⇒ MISS** | 同上 3 / 3 ✓ | **走到 LS 且崩**：`exit=134`、`blocker=lineservices:LoCreateContext` |

⇒ 这同时是**装置的已知阳性对照**：同一装置在 WpfTextDemo 上抓到了 T3 报的那次崩溃
（`WPTD_SUMMARY=FAIL … blocker=lineservices:LoCreateContext`），在 HelloWpf 上是零查找 ——
**"没抓到"与"没发生"能区分开**，不是"永远 0"。
**修过的第二个装置缺陷**：`LD_DEBUG_OUTPUT` 是**每进程一个 `ld.<pid>`**，第一版只读 `head -1`
（= bash 自己的日志）⇒ 被监听的 .NET 子进程整段看不见（现象是 HelloWpf 建了窗口却报
`LsDisableSpecialCharacterLigature` 0 查找）。现在**聚合全部进程日志**（`ld-all.txt`）并打印聚合了几个文件。
存档：`gen/t1b-ls-live-hellowpf.txt` / `gen/t1b-ls-live-wpftextdemo.txt`。

---

## 3. 与真机的差异（**全部保留红 + 登记，未实现、未放宽**）

| # | 差异 | 规模（可比例） | 证据 | 状态 |
|---|---|---|---|---|
| 1 | **Tab（`\t`）口径** | 34 例中 **15 例**不一致（`A1_tabs`/`B_tabs`/`F_tabs`） | 真机把 `\t` 当 **0 宽**且断点行为不同（`A1_tabs_w20` 真机 2 行 `[0,4)/[4,9)`，我们 4 行；`B_tabs_w120` 真机 `W=36.35 WITW−W=0`） | **登记为独立差异类别，本轮不做** |
| 2 | **NBSP/ZWSP 的行尾空白计数** | 11 行 | 真机 `'no\xa0'` 类行：`TrailingWhitespaceLength=0` 但 `WITW−W` 仍等于该空格宽 ⇒ 两件事用了**不同判据**（宽度扣掉、计数不算） | 已定位、**未改**（要拆成两条判据，等主控许可再落） |
| 3 | **Display 模式** | 9 例（`A3_*_display`） | 真机 Display 把 advance 对齐到整像素 | **本实现无该模式**（只统计不给结论） |
| 4 | **折叠可见前缀边界** | 38/236 行明细 | 见 §4 的两条精化（簇边界 / 前缀行尾空白不计宽） | **已在 staging 修好但未落**（未获许可） |
| 5 | **`TextModifier` 未实现** | `M_modifier_*` 5 例 | 真机 modifier 会改文本流（`M_modifier_w80` 真机 2 行 vs 我们 7 行）⇒ **不是断行规则差异** | 登记（B2 范围内不做；oracle 用它只是为了拿非 null 的 `TextLineBreak`） |
| 6 | **`F_*` 家族少量行差** | `F_lat_words` 6 / `F_spaces` 4 / `F_hard_*` 3 例 | 与 #2/#4 同源（空白与被强制断行的记账） | 登记（其中可修的都在 #2/#4） |
| 5 | **`TextModifier` 未实现** | `M_modifier_*` 5 例 | 真机 modifier 会改文本流（`M_modifier_w80` 真机 2 行 vs 我们 7 行）⇒ 不是断行规则差异 | 登记（B2 范围内不做；oracle 用它只是为了拿非 null 的 `TextLineBreak`） |
| 6 | **`F_*` 家族的少量行差** | `F_lat_words` 6 例 / `F_spaces` 4 例 / `F_hard_*` 3 例 | 与 #2/#4 同源（空白与被强制断行的记账） | 登记（其中可修的都在 #2/#4） |

**另**：`Width` 绝对值的差（167 逐位等 / 1147 ≤0.34 / 83 >0.34）**不是**实现错误 ——
真机在 Windows 把每个字形 advance **量化到 1/300 英寸整数量**（实测差恰为 0.32 DIP 的整数倍），
我们走 HarfBuzz 精确 design units。**将来若要做像素级对齐，必须把这层量化显式模拟出来。**

---

## 4. staging 里已修好、**未落**的两条折叠精化（等主控许可）

1. **可见前缀按 HarfBuzz 簇贪心、绝不在簇内切**：真机 `F_hard_lf_w40` 行 `'first '`（cw=14.84）可见前缀
   是 `'fi'` 2 字 —— `fi` 在 Noto Sans 是**一个连字簇**（advance 全记在首字符）；按逐字符贪心只拿到 1 字。
2. **折后宽度 = (前缀宽 − 前缀的行尾空白宽) + 符号宽**：真机 `F_lat_words_w120` 行 `'lazy dog and '`
   （可见 5 字 `'lazy '`）折后 `W=41.4400 = w('lazy')+w('…')`，**那个空格 4.16 被丢掉**；
   而 `collapsedRange` 仍把该空格算进可见区间（`cp=40` ⇒ 可见 `[35,40)`）⇒ **可见长度与宽度是两件事**。

实测效果（**v2 落地后重跑**）：折叠明细全等 **198/236 → 210/236**（判定仍 1298/1298、空参仍全对），
73 例仍 73/73、①286/286 ②68/68 ③977/988、A 组 207/213 不变。
**v2 落地 sha = `a35ffaff83f3f2e01f99981636adacbe13413f17ff1ed490f2a78b63430693ef`（1468 行 / 81,362 B），
三档编译闸门全 0 错，`run.sh icu`(73/73, rc 0) / `tline`(带 sha 固定 ✅) 均按 v2 重跑过。**

---

## 5. 未覆盖 / 做不到（诚实清单）

1. **`GetIndexedGlyphRuns` 仍是 owed**（上游 0 调用点）—— 刻意。
2. **`DependentLength` 未实现**（真机 0..3），恒 0 但可计数。
3. **`TextTrailingWordEllipsis`（WordEllipsis）折叠未实现** —— 真机 oracle 只覆盖 CharacterEllipsis；
   **不猜**，记数后原样返回。主控新情报：CJK 上两者结果相同（无空格）⇒ 将来在 CJK 面可低成本覆盖。
4. **Display 模式未实现**（见 §3-3）。
5. **bidi/RTL 未实现**（RTL 用例不可比）。
6. **`IsTruncated` / `DependentLength` 的真机规则未复算**（本类 `IsTruncated` 走基类默认 false）。
7. **本实现对齐 `FullTextLine`**，不复刻 `SimpleTextLine` 的快路径（后者两个成员恒 null）。
8. **PC 级复验与活窗口 LS 绊线未做**（等波 8 重建 PC）。

---

### 原始输出存档（本报告所有读数的可复核来源）
| 文件 | 内容 |
|---|---|
| `build/MilBridge/gen/t1b-icu.txt` | `run.sh icu` 全文（含被测文件 sha + Stage A/B/C + 结论），退出码 0 |
| `build/MilBridge/gen/t1b-tline.txt` | `run.sh tline` 全文（T0 身份自检 / T1 73 例 / T2–T3 oracle 对拍 / T5 语义 / 计数器 / 不一致明细）|
| `build/MilBridge/gen/t1b-textline.txt` | `run.sh textline` 全文（10/10）|
| `build/MilBridge/gen/t1b-ls-tripwire-selftest.txt` | LS 绊线装置自证全文（含 ld.so 原始日志行数与 nm -D 交叉核对）|
| `build/MilBridge/gen/layout-b34-accounting.txt` | 三类记账的独立复算（不复用采集方的 verify.py）|
| `build/MilBridge/gen/layout-b34-compact.json` | 53MB 真机 dump 的流式紧凑抽取（614 例 / 3222 行）|

---

## 6. 需要主控做的事

1. **波 8 重建 PC（带 B2）** ⇒ 之后我做：① `run.sh tline` 在**直构分支**下重跑（PC 内形态）；
   ② 按你给的 `:98` 配方跑活窗口 + LS 绊线（`t1b-ls-tripwire.sh <dir> -- <hellowpf 命令>`）。
2. **是否许可落 staging 的折叠精化**（§4，`f1daeff4…`）：落则需**再起一次波**；不落我就把
   "折叠明细 198/236" 作为已登记差距留档。
3. **Tab 口径**（§3-1）：本轮不做，需你定优先级。
4. 若允许我动 `build/PresentationCore.Linux/**` + 新增应用器，我可以把
   `TextFormatterImp.FormatLineInternal` 的那条 `FullTextLine` 回退接到 `HbTextLineFactory`
   （见 §7 诊断）—— **先等你点头**。

---

## 7. 附：主控那条硬阻塞（`WpfTextDemo` 100% 崩）的诊断与证据

**结论：我们的 `HbTextLine` / 工厂（B2 产物）在这条崩溃路径上——根本不在路上。** 证据两条：
1. **零调用点**：`grep -rn "HbTextLine\|WpfLinux.Shims" upstream/wpf/src --include=*.cs` = **空**；
   `grep -rn HbTextLine build/PresentationCore.Linux/*.cs`（生成源）= **空**（只有 `shims.txt` 的登记行）。
2. **上游只有一个回退分支**（`TextFormatterImp.cs:236-246`）：
   ```
   if (!settings.Pap.AlwaysCollapsible && previousLineBreak == null && lineLength <= 0)
       textLine = SimpleTextLine.Create(...);      // 快路径
   if (textLine == null)
       textLine = new TextMetrics.FullTextLine(...); // ← 这里就进 LS
   ```
   而 `SimpleTextLine.Create` 在两类条件下返回 **null**（`SimpleTextLine.cs:87-127`）：
   (a) 段落属性不支持（RTL / Justify / TextMarker / TextIndent / ParagraphIndent / LineHeight>0 /
   AlwaysCollapsible / TextDecorations）；(b) `SimpleRun.Create` 对"复杂内容"返回 null。
   ⇒ `FullTextLine` → `new TextFormatterContext()`（`TextFormatterImp.cs:538`）→
   **`TextFormatterContext.cs:113` `LoCreateContext`** → 我们 shim 里**该符号不存在** →
   `EntryPointNotFoundException` → abort(134)。**这正是 T3 观测到的栈**，与 B2 无关。
3. **第二个同类站点**：`TextFormatterImp.cs:309`（`FormatMinMaxParagraphWidth`）也 `new FullTextLine`
   —— 将来接线时**两处都要处理**，否则 `TextBlock.MeasureOverride` 仍会崩在测量阶段。

---

## 8. D3（`FullTextLine` 回退 → 托管路径）**当前状态**：shim 侧已就绪并已落，应用器待写

**设计结论（一句话）**：**替换 LS 那条回退路，不绕过 TextFormatter** —— `SimpleTextLine` 快路径一字不动；
两处 `FullTextLine` 站点改成"**先试托管路径，接不了返回 null 再原样回退 LS**"，任何不确定输入绝不假装成功。

**已落（shim v3）**：`a92ad605a6f307f5c67e87d305f445d903595e41e36a35df7042222fd1fce1d8` / **1689 行**，
新增 **`HbTextFallback`**（`#if TEXTLINE_SHIM_DIRECT` ⇒ **只有编进 PC 时才存在**，当前 PC 的
`DefineConstants` 里没有这个常量 ⇒ 这一版**在 PC 里是惰性的、零行为变化**，已用 `run.sh icu`(73/73)、
`run.sh tline`(与 v2 逐项相同：①286/286 ②68/68 ③977/988、折叠 1298/1298 + 210/236)、
`run.sh textline`(10/10) 三跑确认；三档编译闸门 0 错）。
`HbTextFallback` 做什么：`TextSource.GetTextRun` 逐 run 收集**整段**文本（只接受 `TextCharacters`）→
`Typeface.TryGetGlyphTypeface` → **`GlyphTypeface.FontUri`（public）** 取字体文件路径 →
`HbTextLineFactory.FormatParagraph` 排整段并**缓存**（按 `TextSource` 引用 + 段起点定位，逐行交出）；
`TryMinMaxParagraphWidth`：宽=∞ 排一遍取最长行 ⇒ `MaxWidth`，宽=0（强制断，每行 1 字）取最宽行 ⇒ `MinWidth`。
**每个"交回 LS"的原因都单独计数**（`bailNoSwitch/bailRunType/bailFont/bailEmpty/bailLong/bailException/lastBail`），
并追加在 `HB_TEXTLINE …` 汇总行尾部 ⇒ "接了多少、为什么接不了"可读，不是黑箱。

**已完成**：应用器 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`
**已应用并验证**（无参运行 = 应用；`--check` 只读；幂等）：
```
[锚点] 站点1 FormatLineInternal 的 FullTextLine 回退：上游出现 1 次（要求 1）
[锚点] 站点2 FormatMinMaxParagraphWidth 的 FullTextLine 回退：上游出现 1 次（要求 1）
[断言] 托管调用点 TryFormatLine=1、TryMinMaxParagraphWidth=1；两处原 LS 回退**都还在**
[断言] `throw` 条数 上游 4 == 生成物 4 ；大括号平衡 {=64 }=64；776 → 803 行（+27 全是判断与注释）
[生成] build/PresentationCore.Linux/TextFormatterImp.Linux.cs：已从上游重生成（2 处 D3 修改）
[接线] Remove 上游 TextFormatterImp.cs + Include TextFormatterImp.Linux.cs + DefineConstants 加 TEXTLINE_SHIM_DIRECT
（再跑两次：`内容已是最新（未重写）` / `csproj 已就位（幂等，不改）`；`--check` 退出码 0）
```
**求值验证**：`-getItem:Compile | grep TextFormatterImp` ⇒ **只剩 `TextFormatterImp.Linux.cs`**（上游那条被 Remove 掉）；
`-getProperty:DefineConstants` ⇒ 含 `CORE_NATIVEMETHODS` + **`TEXTLINE_SHIM_DIRECT`**。
**⚠️ 波前编译闸门（这次也做了，避免白跑 20 分钟）**：把**打过补丁的 PC** 编到 `/tmp`（真实产物**零改动**）：
`dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -c Debug -m:1 -p:BaseOutputPath=/tmp/t1b-pccheck/bin/ -p:BaseIntermediateOutputPath=/tmp/t1b-pccheck/obj/`
⇒ **0 错 0 警**。⇒ 下一波不会因这一处接线而失败。
**锚点纪律**：脚本用**逐字**锚点并要求"恰好 1 次"，不符即**报错退出**（不静默产出未打补丁的副本）；
取锚点真值用 `grep -an`（本仓库有文件含 NUL，不加 `-a` 只会得到 "Binary file matches"）。

**接线细节（照 `patch-presentationcore-compositefont.py` 的成熟形态）**
（照 `patch-presentationcore-compositefont.py` 的成熟形态：上游→**生成物** `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`
+ csproj `Compile Remove/Include` 接线；`--check` 只读、无参=应用、幂等、锚点先 `grep -n` 取真值、不做跨行正则删除）：
1. `TextFormatterImp.cs:236-246`（`FormatLineInternal`）：`if (textLine == null) { …FullTextLine… }` 之前插入
   `textLine = WpfLinux.Shims.PresentationCore.HbTextFallback.TryFormatLine(textSource, firstCharIndex, paragraphWidth, textSource.PixelsPerDip, settings.Pap.AlwaysCollapsible);`，
   并在其后**再判一次** `if (textLine == null)` 才 `new TextMetrics.FullTextLine(...)`。
2. `TextFormatterImp.cs:309`（`FormatMinMaxParagraphWidth`）：同样两次判空，
   `new MinMaxParagraphWidth(hbMin, hbMax)`（该 ctor 是 **internal** ⇒ 直构分支可用）。
3. csproj 接线时**同时**加 `TEXTLINE_SHIM_DIRECT`（否则 PC 里编的是反射分支；顺带让 `HbTextFallback` 参与编译）。

**验收（应用器写完后照跑）**：`run-wpftextdemo.sh` 默认档 + env 档 **不再出现 `blocker=lineservices:LoCreateContext`**
（用 `t1b-ls-tripwire.sh` 复核 `LoCreateContext` 查找数应为 **0**，接线前实测 **27**）；
**HelloWpf 不得退步**（`未画种类 0` / PNG **55,913 B**；接线前实测 `LoAcquireBreakRecord`/`LoCreateLine` 零查找）。

**已核实的 API 事实（不猜）**：`GlyphTypeface.FontUri` public ✓；`MinMaxParagraphWidth(double,double)` **internal** ✓；
`TextSource.GetTextRun(int)` public abstract ✓；`CharacterBufferReference.CharacterBuffer`(internal) 返回
`MS.Internal.CharacterBuffer : IList<char>` ⇒ 逐字取文本 ✓；`TextEndOfParagraph : TextEndOfLine` ✓。

---

## 9. D3 修正（v5）：开关默认值 + bail 可见性（主控 2026-09-11 两条要求）

**背景（主控独立定位 + 我的实测一致）**：波 10 后 PC 里接线是活的（csproj `Remove/Include`、
`DefineConstants` 含 `TEXTLINE_SHIM_DIRECT`、崩溃栈里就是 `TextFormatterImp.Linux.cs:265`），
但 `TryFormatLine` 返回 null ⇒ 仍走 LS。根因是 **`Enabled` 默认关**（`ParseOnOff("")==false`），
而设计是"默认开" ⇒ **接线被一个默认值悄悄关掉了**。

| 改动 | 内容 | 验证 |
|---|---|---|
| **独立开关** | `WPF_LINUX_TEXTLINE_FALLBACK`：**未设 ⇒ 开**；`=0` ⇒ 关；`WPF_LINUX_TEXTLINE=0` 也关。`ParseOnOff` 全局语义**一字未改** | D3–D6 断言 |
| **bail 可见** | 16 处 bail 路径统一走 `Bail()`；**前 3 条无条件写 stderr**，之后 `..._DIAG=1` 门控 + 限流（理由：dump 只在正常退出写，故障时是 abort；且 T3 的 runner **连 DIAG 一起清空**）| 代码 + 注释 |
| **默认值自检** | `build/MilBridge/tests/DirectBranchCheck` 改 Exe，跑 D1–D6；`run.sh tline` 第 1 步执行 | **6/6 PASS**，编译 0 错 |

**落地**：`e9ef965597e73e1bf159b157b085945eca8dd30caab7955bb2fc91f55d93ebac` / **1739 行**。
复核：`DirectBranchCheck` 0 错 + D1–D6 全 PASS；`run.sh tline` T0.6 ✅、73 例 73/73、折叠 1298/1298 + 210/236、15 通过 / 4 登记红。

**我自己的两个失误（如实记录）**：
1. 第一次按验收跑 vol1/2/3 **没设开关** ⇒ 测的是"默认关"路径，对 D3 **无鉴别力**；
2. 随后"设 `WPF_LINUX_TEXTLINE=1`"那次**无效** —— T3 的 `run-wpftextdemo.sh` **主动清空 `WPF_LINUX_TEXTLINE*`** ⇒ 应用没起来（`exit=127 notdrawn=NA`）。
⇒ "开关打开后 `LoCreateContext` 归零"以**主控的 A/B** 为准；我的 D3 专属判据等**下一波（默认开）**重跑。

**验收分两步（照主控要求）**：
- **判据 1（D3 专属）**：`t1b-ls-tripwire.sh` 的 `LoCreateContext` **27 → 0**（下一波后复跑，无需 env）；
- **判据 2（应用级）**：`run-wpftextdemo.sh` 不再 abort —— 会先撞 `E_HANDLE`（`MILQueryInterface`/bitmap-source，已转 M7b），**暂不可能绿**，标注为**非 D3 失败**。

---

## 10. 摞印归因（LINEDIAG 读数）+ CJK `.notdef` 诊断（2026-09-11 晚）

### 10.1 摞印：**不在我们这条路上**（读数，不是推断）
`--minimal --text-volume=2`，从 staged 目录直跑（绕开 runner 清空 `WPF_LINUX_*`）：
```
HB_TEXTLINE … lines=1 paragraphs=1 breakNull=0 modifierLines=0
   fallbackCalls=1 fallbackHandled=1 fallbackBailed=0 … minmaxCalls=0 lastBail="-"
```
同一档画面是 `drawn=13 / skia 指令 180` ⇒ **整进程 `TryFormatLine` 只被调 1 次、只接手 1 段 1 行**
⇒ 画面上绝大多数行由 `SimpleTextLine` 排 ⇒ **"多行摞在同一条基线"发生在我们不在的那条路上**；
与 §A 的结论（`LineHeight` 未设时 `Height`/`Baseline` **1298/1298** 与真机一致）互相印证。
**边界**：这是 `minimal`+`vol2` 一档；全档比例待重测。`minmaxCalls=0` ⇒ 该档没走到 `FormatMinMaxParagraphWidth`。

### 10.2 装置自抓（第三次）：LINEDIAG 的沉默
LINEDIAG 的输出原本走 `HbTextLineScaffold.Diag()`，而 `Diag()` 受 `WPF_LINUX_TEXTLINE_DIAG` 门控
⇒ **只设 `LINEDIAG=1` 时一行都不打**（实测：整轮没有"接手"行，只能靠 dump 计数器读出结论）。
**已修**（v7 = `2cc87a93f3e61af8a8b6b7c92a8e71df16d9d8eb0a200c6a64c9eb0a9901041e` / 1791 行）：
LINEDIAG **直写 `Console.Error`**、**每次接手都打**（不只首次）；`DirectBranchCheck` 0 错 + D1–D6 全 PASS。
（该改动在 `#if TEXTLINE_SHIM_DIRECT` 内 ⇒ 反射分支的 harness 不编译它，故 T1/T2/T3 读数不受影响。）

### 10.3 CJK `.notdef` 根因（**诊断，未实现**）
**决定性读数**（`fc-query build/fonts-ui/UI-NoLayout.ttf` 的 charset）：**一个 CJK 码点都没有**
（`U+4E2D 中`/`U+6587 文`/`U+3002 。`/`U+FF0C ，` 全无；`U+0041 A` 有）。
叠加 **M7d 补丁 J 短路了系统复合字体回退** ⇒ **既无字形、也无回退** ⇒ shaping 只能吐 `.notdef`(id 0)
—— 与 T2b 普查（`id==0` **325/1276 = 25.5%**、`maxId=3540`、**无 id≥0x1000**）完全自洽。
**而 HarfBuzz 排 CJK 的能力已被本 harness 证过**（`T1.73 = 73/73`，喂 `NotoSansCJK-Regular.ttc`）
⇒ **缺的是"按覆盖选面/回退"，不是 shaping**。

**选面链条（读代码，上游原文）**：
`TextBlock` 的 run → `TextRunProperties.Typeface` → `Typeface.TryGetGlyphTypeface` →
`Typeface.ConstructCachedTypeface` → `FontFamily.FindFirstFontFamilyAndFace` →
`FamilyCollection.LookupFamily` →（补丁 J 之后）`SystemCompositeFonts.FindFamily` → **provider 的首个可用族**
→ `PhysicalFontFamily.MapCharacters(...)`（`MS/internal/FontFace/PhysicalFontFamily.cs:167/258`）在**该族内**挑面。
**上游真正的"按覆盖回退"就是复合字体机制**（`GlobalUserInterface` 等的 `<FontFamilyMap>` 区间映射）——
而那正是补丁 J 短路掉的东西；补丁 J 的短路原因（已登记）：`GlobalUserInterface.CompositeFont` 根为
`<FontFamilyCollection>` + 4 个 OS 段，Linux 上一段都不匹配 ⇒ `Fail()` 要
`OSVersionHelper.GetOsVersion()` ⇒ 抛 `Could not detect OS!`。

**修法方向（**只给方案，未实现**；位置必须是"选面那一层"，不是 `TryFormatLine`）**：
- **A（推荐）**：保留补丁 J 的"不解析系统复合字体"，但把其"provider 首个可用族"代偿换成
  **按码点覆盖感知的回退**：`FamilyCollection.LookupFamily` 的那一分支在"当前族不覆盖该码点"时，
  向 provider 要一个**覆盖该码点**的族；provider 答不了就**保持今天的行为并计数**（"不确定就交回"）。
  优点：`SimpleTextLine` 与我们的回退路径**同时受益**（同一层）；不伪造 OS 版本；拉丁仍走原族（不整体换字体）。
- **B**：造一个 Linux 版复合字体（Noto Sans + Noto Sans CJK 的区间映射），复用上游复合字体机制做覆盖选择；
  更贴合上游，但机器更多。
**影响面（必须先说清）**：① **拉丁不得退步** ⇒ 选择必须**按码点/按 run**，不能按段落整体换族；
② 不得把 `TypographyGate`/`CheckFastPathNominalGlyphs` 那套闸门打回 LS（**只动选面，不动行创建**）；
③ `GlyphTypeface` 公开面**没有**字形覆盖查询 —— **下一步若要查覆盖，只能读字体文件的 cmap**
（那是"读字体"，不是"读 PC 的选择"，两者必须分清；PC 选了哪个面仍要 M7b 那半的读数）。

### 10.4 仍欠
`T2e`（`cases-cd2.json` 那 10 例 `LineHeight` 真值回证）**未做** ⇒ **不声明 `LineHeight` 修复已闭环**。

---

## 11. R1：CJK 真出字 —— 诊断与设计（**先设计后动手**，2026-09-11 夜）

### 11.1 诊断（本轮代码事实，逐处给出）
T1c 已用实测否证"方案 A 能在 PC 侧生效"：`id0 325/1276 → 325/1276` 逐项不变，根因是
**复合字体"按区间选族"只活在 LS 路径上**（`GetShapeableText` 托管侧无调用者、`WrapperMapCalls=0`），
而本移植把 LS 换成了托管 shim ⇒ **(甲) 做在一条死钩子上**。**能出 CJK 的唯一活路径是本 shim。**

本 shim 现在**一段只用一种字体**，三处证据：
| 位置 | 现状 | 后果 |
|---|---|---|
| `HbTextFallback.TryCollect`（`out TextRunProperties props`）| **只取第一个** `TextCharacters` run 的 `tc.Properties` | 后面 run 的字体信息**直接丢掉** |
| `HbTextFallback.TryResolveFont(props, …)` | `props.Typeface.TryGetGlyphTypeface().FontUri` ⇒ **一个文件** | 一段一个字体文件 |
| `HbLineBreaker`/`HbTextLineFactory`（`fontPath` 是**单个 string**）| `MeasureChars` / `Shape` / `FormatLine` 全用这一个 | 缺字形的码点 ⇒ HarfBuzz 吐 `.notdef`(id 0) |

**结构性无解的一档（按要求写清，不假装可达）**：`WPF_LINUX_FONT_DIR=build/fonts-ui` 只有
`UI-NoLayout.ttf` 一个族、**0 个 CJK 码点**（`fc-query` 实证）⇒ **那一档无论怎么改选面都出不了 CJK**（T1c 复现 `id0=329/1170`）。
⇒ 本设计的可达目标 = **`UI-NoLayout` 覆盖不到的码点能落到"机器上存在的、覆盖得上的面"**（阳性对照已证：`WPF_LINUX_UI_FONT="Noto Sans CJK SC"` ⇒ `id0 325→0`、`非拉丁 0→294`、`maxId 3540→63151`）。

### 11.2 设计（四层，落点全在本 shim 内）
**① run 级收集**：`TryCollect` 改为收集 `List<(int cpStart, int length, TextRunProperties props)>`（**不再丢掉后续 run 的 props**），
文本拼接与现在一致（`StringBuilder` + `cp += tc.Length`）。非 `TextCharacters` 的 run 仍**原样 bail**（形状不变）。

**② run 级字体解析 + 缓存**：`TryResolveFont(props)` 对**每个 run 的 props** 各解析一次，
缓存键 = `TextRunProperties` 引用（或 `Typeface`+字号）；解析不到文件的 run ⇒ 沿用上一个 run 的字面并**计数**（不整体失败）。

**③ run 内**按码点**覆盖切分**（关键）：
- 覆盖判据**不需要反射**：HarfBuzz 自己就能答 —— 新增 `HbShaper.Covers(fontPath, emSize, cp)`
  （`hb_font_get_nominal_glyph`/`hb_font_get_glyph` ≠ 0 ⇒ 有字形；按 `(fontPath, cp)` **缓存**，上限清空策略同 §10）。
- 不覆盖时，从**候选面集合**里挑一个覆盖的：候选 = 当前面 + 被解析出的其余 run 面 +
  机器字体目录里"覆盖该码点"的面（首选 `NotoSansCJK-Regular.ttc`；**挑法按覆盖，不按名字**，避免"把问题挪到拉丁"）。
- 一个 run 内按覆盖切成子段（`[cpStart,cpEnd)` + 各自面），**选面粒度 = 码点段**，绝不按段落整体换族（约束 1）。

**④ 多字体整形（HarfBuzz 分段 shape + 拼回）**：
对每个子段各调一次 `HbShaper.Shape(subFontPath, subText, emSize)`，然后
**把 glyphs/advances/offsets 顺序拼接**、并把每个子段的 `cluster` **平移回段落局部下标**（`+ cpStart`）。
⇒ 产出仍是**一个** `HbShapedRun`（同样的 `Glyphs/Clusters/AdvancesPx/OffsetsXPx/Text` 字段）。
**⇒ 断行引擎、`CharAdvances()`、行记账（`Length` 含硬断、`NewlineLength`（`\r\n`=2/末行=1）、
相邻 `\n` ⇒ `Length=1`、行尾空白不占宽但占区间）**一行都不用改** —— 它们只看 `charAdv`/`Length`，
与"advance 由哪个面提供"无关。**这是"记账 1298/1298 不许退步"能同时成立的结构性理由。**

**⑤ 可观测（缺省关、独立类、绝不碰 `RenderDiagnostics`）**：`CoverageProbe/CacheHit/FallbackApplied(前 N 个码点)/FallbackTarget(族名)/FallbackFailed/RunCount>1`。

### 11.3 验收（照主控四条数字）
1. **CJK**：`id0` **325/1276 → ~0**、出现 **`id≥0x1000`**（阳性对照 `非拉丁=294 / maxId=63151`）—— **不靠 `WPF_LINUX_UI_FONT`**；
2. **拉丁不退步**：`run.sh icu` 73/73、`run.sh tline` 的 `T1.73 73/73` + `T2d 1298/1298`；
3. **记账不破**：折叠判定 1298/1298、①硬断/②空行/③行尾空白三类对拍数不降、**4–5 条登记红继续红**；
4. **流程**：读数附本次编译状态（"0 错 0 警"单独一行）；**不用 `--no-build`**。

---

## 12. T2e · `LineHeight` 维度对拍装置（交付；含牙齿自检）

**命令行**（禁 `--no-build`；装置只用 JSON + 探针，**不跑应用、不起 Xvfb**）：
```bash
SB=build/MilBridge/staging/PresentationCore.HbTextLine.cs     # ← 见下方"为什么不是真 shim"
dotnet build build/MilBridge/tests/T2eLineHeight -c Release -m:1 --nologo -p:HbShimSrc=$SB   # ⇒ 0 错 0 警
cd build/MilBridge/tests/T2eLineHeight/bin/Release
T2E_SHIM_PATH=$SB dotnet MilBridge.T2eLineHeight.dll                 # 正常对拍
T2E_SHIM_PATH=$SB dotnet MilBridge.T2eLineHeight.dll --selfcheck      # 牙齿：注入错真值 ⇒ 必须报红
```
**原始输出（节选）**：
```
T2E_SUMMARY cases=10 height_ok=10/10 textheight_ok=5/10 baseline_ok=10/10 extent_ok=0/10 lines=40
  LH_lat_words_lh10  LineHeight=10      Height 真值=10.0000 我们=10.0000 ✓ | TextHeight=21.7933 vs 21.7920 ✓ | Baseline=7.8500 vs 7.8488 ✓
  LH_lat_words_lh50  LineHeight=50      Height 真值=50.0000 我们=50.0000 ✓ | TextHeight=21.7933 vs 21.7920 ✓ | Baseline=39.2433 vs 39.2438 ✓
  LH_cjk_punct_lh50  LineHeight=50      Height 真值=50.0000 我们=50.0000 ✓ | TextHeight=21.1167 vs 23.1680 ✗ | Baseline=40.0867 vs 40.0552 ✓
  ❌ TextHeight 不一致 5/10 例
```
**读数解释（三条，逐条给依据）**：
1. **`Height` 10/10 ✓、`Baseline` 10/10 ✓** ⇒ **`LineHeight` 修复成立**（`Height=LineHeight`、`Baseline=LineHeight×自然比` 都对上了；
   v7 之前这里是"恒为自然行高"）。最大偏差都在 **0.34 DIP 容差内**（≈1 个 1/300 英寸量化单位）。
2. **`TextHeight` 5/10**：**5 个拉丁例全对**；**5 个 CJK 例不对（21.1167 vs 23.1680）不是公式错，是字体代用** ——
   真机用 Microsoft YaHei（本机没有），装置用 `NotoSansCJK-Regular.ttc` 代 ⇒ **自然文本高本来就不同**（23.168 vs 21.117）。
   ⇒ 这 5 例应读作"**不可比（字体代用）**"，装置目前只按数值判，故计成红。**这是装置的已知边界，写在这里而不是让它悄悄绿。**
3. **`Extent` 0/10**（与 1298 行那批的 0/1298 同源）——**确认缺陷**：
   - 真值语义 = **墨迹上伸**（ink ascent，A1 行 = 14.16、本批 = 18.08）；
   - 我们 = **行高**（`Extent => _height`，`HbTextLine.cs` 的 `public override double Extent => _height;`）；
   - **归因方向**：工厂/行实现**没有 ink-extent 概念**（`LineHeight` 已接但 `Extent` 与它无关），
     真值要的是**逐字形墨迹上伸**（字体 OS/2 `usWinAscent` 或字形 bbox），`GlyphTypeface` 公开面拿不到；
   - **要改的锚点**：`build/shims/PresentationCore.HbTextLine.cs` 的 `public override double Extent => _height;`
     （与 `MarkerHeight` 同一处），实现需先有"能判的表"⇒ **本轮按要求只取证与定位，不改实现**。
**牙齿自检**：`--selfcheck` 把真值 `Height` 故意 `+1.0` 后重跑 ⇒
```
T2E_SUMMARY cases=10 height_ok=0/10  ← 注入的错在 10/10 例上**全被抓出**
  ✅ 自检（牙齿）：注入错真值 ⇒ height_ok=0/10 全被抓出（装置不是打印器）
```
**⚠️ 装置的牙齿自己也有过一次牙病（如实记录）**：第一版判据写的是 `_fail > 0`，而自检模式下不会走
正常模式的 `Red()` ⇒ `_fail` 恒 0 ⇒ **"装置明明抓到了错真值，却被判成装置不可信"**。
改成看**它有没有把错的抓出来**（`height_ok==0`）后自检通过（rc 0）。
**⚠️ 为什么本轮测的是 staging 那一份（`2cc87a93…`）而不是真 shim**：取证时真 shim 正被 T1d 改到手
（当期 sha `a76840b4…`），且它**在反射模式下编不过** ——
`CS1061: GlyphTypeface 未包含 FaceIndex / GetDWriteFontAddRef`（这两个是 **PC 内部**成员）
⇒ 若 T1d 的用法**没有** `#if TEXTLINE_SHIM_DIRECT` 守卫，则**所有反射模式 harness**（`HbTextLineParity`/`T2e`/`TextLineProto`）都无法编译该文件。**这条已报主控。**

---

## 13. 摞印（行推进≈0）诊断 · 第一次取证：**仪表答不了这个问题**（不给数）

**跑了什么**（串行、`:96`、按 PID 收尾；用 T1c 的注入装置起**部署件**）：
```bash
WPTD_DISPLAY=:96 bash build/MilBridge/tools/t1c-census.sh /tmp/t1b-stack default \
    WPF_LINUX_GLYPH_CENSUS=1 WPF_LINUX_DRAW_CENSUS=1
```
**拿到的读数（原始）**：
- `WPF_LINUX_GLYPH_CENSUS`：`frame=2 runs=131 glyphs=1276 id0=0 maxId=63151 非拉丁(id>=0x1000)=322 不同面数=4渲染器=WpfGfx.Linux.Text.TextRenderer`
  ⇒ **R1 的成果在部署件上复现**（`id0=0`、`非拉丁=322`、`maxId=63151`），但**该仪表没有逐 run 的 `origin=`/Y 列**（它打的是 `handle/n/id0/max/pid/first16`）。
- `WPF_LINUX_DRAW_CENSUS`：只有**视觉级**设备矩形（`设备=(38.0,111.2,442.7x182.7)`、`(38.0,305.3,…)`、`(38.0,448.4,…)`、`(38.0,625.6,…)`…），**不是"同一段落内逐行的基线 Y"**。
⇒ **这两台仪表都答不了"同一多行段落逐行的 Y"**。按纪律：**我不给一个凑出来的 Y 读数**（"仪表答不了就不给数"与 §10.1 同一条纪律）。

**能给的一条（shim 侧，来自已有装置）**：我们交出的行度量对**我们排的那些行**是**对的** ——
`T2d`：`Height`/`Baseline` 与真机 **1298/1298**；`T2e`：`LineHeight` 维度 **Height 10/10、Baseline 10/10**。
而 `LINEDIAG` 已实测：整进程我们**只接手 1 段**（§10.1）⇒ **画面上的多行段落绝大多数不是我们排的**。

**结论与下一步（要哪台仪表）**：要判"行推进 ≈ 0"，必须拿到**逐 run/逐行的原点 Y**。三条路：
1. **给 `GLYPH_CENSUS` 加一列"该 run 的原点/基线 Y"**（那台仪表是 T2b 的 ⇒ 需主控派它，或授权我在自己车道加一个**只读**旁路装置）；
2. 读 **MIL/DUCE 侧 `MilCmdGlyphRunCreate` 的 `Origin`/变换**（M7b 的车道）；
3. `WPF_LINUX_TEXTLINE_FALLBACK=0` 那档会崩（已证），所以**不能**用它来把"我们这条路"从画面里摘出去做对照。
**未给结论**：**"我们交出的行高" vs "消费方读错字段" 两者我都没有决定性证据，不选边。**

---

## 14. T2d 的 LineHeight 覆盖补齐 + Extent 余差定位（命令 / 原始输出 / 编译状态）

**命令**（JSON+探针级别；不跑应用、不起 Xvfb；`-m:1`、无 `--no-build`）：
```bash
# 被测 shim：staging 里的 v7 副本（真 shim 正被 T1d 改到手且反射模式编不过，见 §12 尾）
dotnet build build/MilBridge/tests/HbTextLineParity -c Release -m:1 --nologo \
    -p:HbShimSrc=$PWD/build/MilBridge/staging/PresentationCore.HbTextLine.cs   # ⇒ 0 错 0 警
cd build/MilBridge/tests/HbTextLineParity/bin/Release && dotnet MilBridge.HbTextLineParity.dll
```
**① LineHeight 覆盖（原为"0 行"）—— 已补上，原始输出**：
```
**LineHeight>0 的用例**：10 例 / 40 行 （来源 cases-cd2.json：`lineHeight` 显式非空的用例；真值 = results-cd2.json）
  逐例一致：Height 10/10、TextHeight 5/10、Baseline 6/10、Extent 0/10
✅ T2d-lh T2d 的 LineHeight 覆盖不再为 0
  LH_lat_words_lh10  LineHeight=10.0000  行0: Height 真值=10.0000 我们=10.0000 | Baseline 真值=7.8500 我们=7.8488 | Extent 真值=18.0800 我们=10.0000
  LH_lat_words_lh50  LineHeight=50.0000  行0: Height 真值=50.0000 我们=50.0000 | Baseline 真值=39.2433 我们=39.2438 | Extent 真值=18.0800 我们=50.0000
```
**口径写在输出里**（不许为凑数放宽）：只取 `lineHeight` **显式非空**的用例；真值取 `results-cd2.json` 同 id 的逐行 `properties`。
**⚠️ 两台装置的容差口径不同（诚实标注，不是缺陷）**：同一批 10 例 `Baseline`，`T2e` 报 **10/10**（容差 0.34），
`T2d` 这两列报 **6/10**（容差 **0.01**）—— 差的 4 例是 **CJK 例**（真机 MS YaHei 缺失、装置用 NotoSansCJK 代用 ⇒
自然基线比略差 0.017–0.03）。`TextHeight 5/10` 同源。**要统一口径必须二选一，不能两边各留一套。**

**② Extent 余差：我这轮**给不出 39 条**，原因是**被测版本**而不是装置**：
`Extent 0/1298`（本 shim 版 = v7，`Extent => _height`，**还没实现 ink extent**）；
T1d 的 `1259/1298` 出自它**正在改的那一版**（反射模式编不过 ⇒ 我无法在本装置上编它）。
**但本轮拿到了"Extent 语义"的直接证据（10 例 × 4 行 = 40 条，全部带出处）**：
```
LH_lat_words_lh10 行#0 [NotoSans] Extent 真值=18.0800 我们=10.0000 差=-8.0800
LH_lat_words_lh10 行#2 [NotoSans] Extent 真值=14.4000 我们=10.0000 差=-4.4000
LH_lat_words_lh22 行#0 [NotoSans] Extent 真值=18.0800 我们=21.7930 差=3.7130
```
⇒ **真值 `Extent` 逐行不同（18.08 / 18.00 / 14.40 / 14.464），而我们的恒等于该行 `Height`**（10 / 21.79 / 30 / 50）
⇒ **`Extent` 只能是"逐字形墨迹上伸"**（随该行实际字形变化），**不可能由 `LineHeight` 推出**。
**这一条把"最可能的成因分类"钉成了"实现语义错"，而不是容差口径问题**（口径问题不会让真值随行内容变化）。
**要改的锚点**：`build/shims/PresentationCore.HbTextLine.cs` 的 `public override double Extent => _height;`（与 `MarkerHeight` 同处）。

**过程中我把装置弄坏过一次并已修复（如实记录）**：补 ① 时我的批量替换误删了 harness 里一行**合法**的续行，
导致 `HbTextLineParity` 编不过；**已逐点修回并通过编译（0 错 0 警）**后才继续跑读数。
教训与前几次同族：**"按模式批量删/替换"本身就是危险动作**（主控纪律里那条），这次是我自己踩的。

---

## 15. A（统一容差口径）+ B（一条命令取 Extent 余差）—— 完成

**⚠️ 顶部口径声明（主控 2026-09-11 裁定）**：本报告所有行度量对拍**同时**给两个口径 ——
**`@0.34`** = 项目口径（上游 1/300 英寸量化，1 个 ideal unit）；**`@0.01`** = 严口径（暴露更细尺度的差）。
**两个都留、都要显式标注**；要丢的是"两台装置各留一套、看起来互相矛盾"这件事 ⇒ 两台装置同一格式、同一行位置。

### A. 统一标注（`T2d` 与 `T2e` 同格式）
`T2d`（LineHeight 组）原始输出：
```
Height 一致 @0.34: 10/10 ｜ @0.01: 10/10   Baseline 一致 @0.34: 10/10 ｜ @0.01: 6/10
TextHeight 一致 @0.34: 5/10 ｜ @0.01: 5/10   Extent 一致 @0.34: 0/10 ｜ @0.01: 0/10
（严 0.01 与宽 0.34 之间的差额行：16；CJK 例为**字体代用**：本机无 MS YaHei）
```
⇒ 与 `T2e` 先前报的 `Baseline 10/10` **不再矛盾**：那是 0.34 口径；0.01 口径下 6/10，差额 4 例全为 CJK 代用字体。

### B. 一条命令取 Extent 全量明细
```bash
bash build/MilBridge/tools/t2d-extent-detail.sh [shim路径]     # 默认 = build/shims/…（真源）
```
产物 `build/MilBridge/gen/t2d-extent-mismatches.txt`（全量，文件头含**被测 shim sha256**）。
**脚本自证（用 staging v7：`Extent => _height` 形态）原始输出**：
```
# 被测 shim sha256 = 2CC87A93F3E61AF8A8B6B7C92A8E71DF16D9D8EB0A200C6A64C9EB0A9901041E
# 合计 1338 条（主对拍集 1298 + LineHeight 组 40）
A1_lat_words_w20 行#0 [file-font] Extent 真值=14.1600 我们=21.7920 差=7.6320
A1_lat_words_w20 行#1 [file-font] Extent 真值=10.8960 我们=21.7920 差=10.8960
T2D_EXTENT_SUMMARY shim_sha=2cc87a93… details=1194 harness_rc=1
```
⇒ **"有牙"成立**：在"Extent 恒等于行高"的版本上，**全部 1298 行可比行都是余差**（真值逐行不同：14.16 / 10.896 / 14.576 …）
—— 反过来，T1d 那一版若真有实现，条数应落到它报的 39 条量级。**在真 shim 上跑之前，不拿 v7 的数字解释 T1d 的 1259/1298（不同版本）。**
（`details=1194` 与文件头 `1338` 的差 = 我汇总行的 grep 只数了以用例前缀开头的行，**是汇总口径的瑕疵，不是缺数据**；文件里是 1338 条。）

### ⚠️ 过程中又抓到一处"报到另一个文件上"（第 4 次仪表自抓）
明细头第一版写的是 `ADBEE67B…`，而脚本汇总写 `2cc87a93…` —— **不是同一个文件**：
harness 用的是 `HbShimSource.File`（常量里的**默认**相对路径 = 真 shim），而我编译进 harness 的是
`-p:HbShimSrc=<staging 副本>`。**已修**：harness 改为优先读 env `T1B_SHIM_PATH`（脚本传编译路径），
现在两者逐字符相同（`2CC87A93…`）。**这正是"测的到底是哪个文件"那一族，第 4 次。**

---

## 16. `getTextRunSpans` 读数：**我的装置拿不到（且不该造）**；`Extent` 余差在**真 shim** 上复现（58 条）

### 16.1 `getTextRunSpans` → 只能由 PF 的 TextBox/FlowDocument 场景产生 ⇒ **申请 slot**
上游 `GetTextRunSpans()` 的**全部**调用点都在 **PresentationFramework**：
`MS/Internal/documents/TextBoxLine.cs:370`、`MS/Internal/Text/ComplexLine.cs:150/225`、`MS/Internal/Text/Line.cs:414`、
`MS/Internal/PtsHost/Line.cs:277/381/661` —— **PC 侧一个都没有**。
⇒ 我的 harness（只驱动 PC + `HbTextLineFactory`）**无法合法地把它变成 ≥1**；
**如果我去 harness 里自己调一下让它变 1，那就是伪造证据**（正是本项目最恨的形态）⇒ **不改、不造 → 申请一个应用 slot**。
（我的装置产出的 `HB_TEXTLINE … getTextRunSpans=0` 是**合法读数**：它只证明"harness 没问过 spans"，**不是** TextBox 场景的结论。）
**另**：真 shim 在本轮又动过 —— 主控派单里写 `d197de66…`（3708 行），我实测已是 **`ebccdb1e…` / 3766 行**；读数的 sha 我按后者钉。

### 16.2 `Extent` 余差：**真 shim 上复现**（`t2d-extent-detail.sh`，默认真源）
```
# 被测 shim sha256 = EBCCDB1EE65E6F7653DA338D70188410615062F825A10969B737CA7D48281BBF
# 合计 58 条（主对拍集 38 + LineHeight 组 20）
A1_nbsp_zwsp_w20 行#7 [file-font] Extent 真值=16.0859 我们=13.4240 差=-2.6619
A1_nbsp_zwsp_w30 行#4 [file-font] Extent 真值=19.0744 我们=17.2640 差=-1.8104
A1_nbsp_zwsp_w40 行#3 [file-font] Extent 真值=16.0859 我们=13.4240 差=-2.6619
T2D_EXTENT_SUMMARY shim_sha=ebccdb1e… details=58 harness_rc=1
```
⇒ 与 T1d 的 `1298-1259=39` **同量级但不相等（我这版 38）** —— 差异可解释：**shim 在其测量之后又改过**（`d197de66…`→`ebccdb1e…`）；**两个数不能混用**。
⇒ **定位线索**：清单**前几条全部落在 `A1_nbsp_zwsp_*`**（NBSP/ZWSP 家族，与我已登记的 NBSP/ZWSP 行尾空白差异同族），且**差值一致为负**（我们比真机小）
⇒ 最可能成因 = **零宽/不换行字符的墨迹参与方式**（`U+200B` 零宽、`U+00A0` 不换行）在 ink-extent 计算里被我们漏算/多算。**只定位，不改实现。**
⇒ 脚本的 sha 自检已修好：文件头 sha 与汇总 sha **逐字符相同**（`EBCCDB1E…`）。

---

## 17. NBSP/ZWSP 的 ink-extent 归因：**假设被否证 + 换线索**（只定位，未改实现）

**被测版本锁死**：本轮全部读数在 **`ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf` / 3766 行**（当前 shim）。
⚠️ T1d 的 **39 条**测于更早的 **`d197de66…`**，本报告的 **58 条（主对拍集 38 + LH 组 20）** 测于上述版本 ⇒ **两数不得混用**。

### 17.1 探针（新增，**不依赖 shim**）
`build/MilBridge/tests/BboxProbe/`（只 P/Invoke `libharfbuzz.so.0` 的 `hb_font_get_nominal_glyph` / `hb_font_get_glyph_extents`）：
```bash
dotnet build build/MilBridge/tests/BboxProbe -c Release -m:1 --nologo      # ⇒ 0 错
cd build/MilBridge/tests/BboxProbe/bin/Release && dotnet MilBridge.BboxProbe.dll [font] [emSize]
```
**原始输出**（`build/fonts/NotoSans-Regular.ttf` @16px）：
```
'n' (拉丁)        glyph=81   y_bearing= 8.7360 height= -8.7360  x_bearing=1.3600 width=7.2320
NBSP U+00A0       glyph=98   y_bearing= 0.0000 height=  0.0000  x_bearing=0.0000 width=0.0000
ZWSP U+200B       glyph=566  y_bearing= 0.0000 height=  0.0000  x_bearing=0.0000 width=0.0000
'与' U+4E0E       cmap 里**没有**（Noto Sans 无 CJK 字形 ⇒ shaping 落到 .notdef = glyph 0）
SPACE U+0020      glyph=3    y_bearing= 0.0000 height=  0.0000
'(' U+0028        glyph=11   y_bearing=11.4240 height=-13.9520
真机参照：A1_lat_words 行 Extent=14.1600；A1_nbsp_zwsp_w20 行#7 Extent=16.0859；我们（当前 shim）=13.4240
```

### 17.2 ⚠️ 探针自身的公式 bug（第 5 次仪表自抓，如实记录）
第一版"墨迹上伸"写成 `y_bearing + height` —— **错**：HarfBuzz 的 `height` 在 **y 向下**约定下是**负数**，
正确公式是 **上伸 = `y_bearing`**（下伸 = `-(y_bearing + height)`）。
按正确公式复读上表：`'n'` 上伸 **8.736**、`'('` 上伸 **11.424**、**NBSP / ZWSP / SPACE 上伸 = 0.0000**（advance 亦为 0）。

### 17.3 结论 1（**否证**）
**`U+200B`（零宽）与 `U+00A0`（不换行）在 Noto Sans 里的 bbox 全为零** ⇒ 它们**不可能贡献 ink-extent**。
⇒ "差值由 ZWSP/NBSP 的 bbox 解释"**不成立**；**29/38 条集中在该家族是"共现"，不是成因**（那两族用例的文本里同时含 CJK 字符）。

### 17.4 结论 2（**新线索，待证**）
`A1_nbsp_zwsp_*` 的文本含 **`与`**（CJK），而该用例字体是 **Noto Sans**（无 CJK 字形）⇒ shaping 必落到 **`.notdef`(glyph 0)**。
真机 `Extent = 16.0859`（= **1.0055 em**）比我们 `13.4240`（= 0.839 em）**大 2.6619** ⇒
**最可能是 `.notdef` 那个方框的 bbox 被真机计入 ink 上伸、而我们没有（或取了另一类上伸）**。

### 17.5 定位状态：**未完成**，缺哪条读数已写明
**缺的读数 = 逐行 glyph id 全序列 + 每个 glyph（含 glyph 0）的 bbox**，再与真值 `Extent` 逐行比。
本轮只查了 **6 个代表码点**，**没有**取失败行的逐字形序列 ⇒ **"是否 `.notdef` 能解释全部差值"尚不可判**。
（主控已把这条线索转给 T1d，并注明可复用本探针 + 修正后的公式；**我不再新开工作**。）

---

## 18. 本轮三件：A5 断言陈旧（已修）· `source run.sh` 事故（含影响面）· 牙齿未复现

### 18.1 A5 `NotImplExportNames` 计数：**断言陈旧，不是回归**（已修，闭环 0 失败）
**T1b 独立枚举**（不照抄任何人的话）：`src/WpfGfx.Linux/Interop/MilNative.Exports.cs` 里 `ExportDepth.NotImpl` 的**清单条目**共 **27** 个
（判定代码 `if (pair.Value == ExportDepth.NotImpl)` 那一行**不是条目**，`grep -c` 会多数出 1）：
`InteropDeviceBitmap_{AddDirtyRect,Create,Detach,GetAsSoftwareBitmap}`（:86-89）+
`MILFactoryCreateMediaPlayer` + `MILMedia{CanPause,Close,GetBufferingProgress,GetDownloadProgress,GetMediaLength,GetNaturalHeight,GetNaturalWidth,GetPosition,HasAudio,HasVideo,IsBuffering,NeedUIFrameUpdate,Open,ProcessExitHandler,SetBalance,SetIsScrubbingEnabled,SetPosition,SetRate,SetVolume,Shutdown,Stop}`（:96-119）+
`MilResource_SendCommandMedia`（:170）。
**交叉核对**：`tests/WpfGfx.Linux.Tests/Commands.Tests/MilExportTests.cs:216` 已是 `Assert.Equal(27, notImpl)`（注释 :214）
⇒ **本断言（28）确实停在 #24 `SendCommandBitmapSource` 升档之前**。
**已修**：`build/MilBridge/tests/ClosedLoop/Program.cs` 的 `notimpl == 28` → **27**，文案改成
`（29 − 1 SetNotificationWindow − 1 #24 = 27）`，并加注释指向 `MilExportTests.cs:216` 那对
"**real+1 / notImpl−1 必须一起改**"⇒ 防两个消费者再次各自漂移（本轮新登记的一族："一个数字两个消费者，一个陈旧"）。
**原始输出**：`PASS  A5  NotImplExportNames 计数（29 − 1 SetNotificationWindow − 1 #24 = 27）` ／ `== 通过 54 / 失败 0 / 跳过 0 ==`。

### 18.2 ⚠️ 事故：`source build/MilBridge/run.sh` 误跑了整条 `all` 流水线（**这一格是我造成的**）
**经过**：我为调用新写的 `refresh_applocal()` 写了 `source run.sh`，而脚本底部是 `case "$CMD"` 分发、`CMD` 为空 ⇒ 落到 `all`
⇒ 误跑 `gen` → **AOT 发布** → 闭环。
**影响面（实测边界）**：只写**我自己的车道** —— `build/MilBridge/gen/**`（重生成 109 个包装/符号表/落点表）、
`build/MilBridge/.artifacts/**`（AOT 发布产物）、以及 `src/MilBridge.Linux/Exports.g.cs`（`run.sh gen` 的确定性生成物）；
**未碰** `build/shims/**`、其它 `build/*.Linux/**`、`tests/**`、`samples/**`、T2/T3/T1d/M7b 的文件。
**代价（主控补充的事实，必须与我的事故绑定留档）**：那次 `all` 跑了 **AOT 发布** ⇒ **发布目录里的桥在 16:02 被覆盖**
（`66703024af8c115d` → `55a9566e…`，同为 4,937,968 B），而它是在 **T2b 突变自测窗口附近**编出来的
⇒ **主控已把该产物隔离、不作为任何证据载体**；下次发桥由主控按 `publish-milbridge.sh` 重发并留 `src/**/*.cs` 指纹。
**教训**：要用脚本里的函数就**单独抽取**（`sed -n '/^refresh_applocal() {/,/^}/p'`），**绝不 `source` 带命令分发的脚本**。

### 18.3 `refresh_applocal` 的牙齿：**未复现（如实记档）**
```
权威 DirectWriteForwarder sha = c1020f68a1d69194
① 用 WindowsBase.dll(=11c75d228a0b86a3) 覆盖 app-local 副本，mtime 更新
② 只跑 dotnet build（旧行为）⇒ 副本 sha 回到 c1020f68a1d69194 —— **被 build 修回**
⇒ "改前会假红"这一半**没有证据**；我原先的机制假设（MSBuild 因目标 mtime 更新而跳过复制）**在这条路径上不成立**。
```
**仍然成立**：树里**确实存在过**陈旧副本（`fbc6ee51…` vs 权威 `c1020f68…`）；新 helper 的价值 = 把同步从
"依赖 build 的复制语义"变成"**无条件 + 打印两侧 sha**"（可核对性提升），**不是**"必然假红"的修复。
**要真复现假红需要**：陈旧副本的 **mtime 比权威更新**（我这次相反）⇒ 留待下一轮造对照。

### 18.4 仍欠
`run.sh tline` 六项回归 —— **等主控说"可以跑"**（正在合并：PC 重建 + native shim 安装 + 桥重发；现在跑会撞 obj 且读数属中间态）。
届时：先看 `loadavg`、`-m:1`、报告注明**与谁并发**与**跑的哪份 sha**。

---

## 19. 六项回归（放行后实跑）+ `getTextRunSpans` 收口读数 + 逐例明细落盘

**并发与负荷**（逐条照主控要求）：跑前 `loadavg` = **1.46 / 3.74 / 5.57**（3 核）；**无应用在跑**（T3 让槽）、
**无人构建本仓库**，但**有外来构建 `wpf2web` 在跑**（未动它）。全程 `-m:1`、无 `--no-build`。
**现场重读 sha（不是我引用别人的）**：shim **`ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf`**（3766 行 / 206,286 B）、
PC **`8ff5cb388ca75964`**、provider **`71ba86c6495347fe`** —— 与主控给的三值一致。

### 19.1 六项原始汇总行（本轮实测）
```
PASS D1..D6（直构分支 + 默认值语义自检 6/6；== 通过 ==）
被测文件 sha256 = EBCCDB1E…   （T0.6 与 harness 实读逐字符一致）
✅ T1.73  73 例 CJK 逐行全等（exact=73 diff=0）
[A 组·断行位置] 行级 972/972；用例级 213/213          ← 比上一版（964/965、207/213）**提升**（R1 多字体生效）
行级一致：Height 1298/1298、Baseline 1298/1298、Extent 1260/1298（最大差 Height=0.0013、Baseline=0.0007）
LineHeight>0 的用例：10 例 / 40 行；逐例一致 Height 10/10、TextHeight 5/10、Baseline 6/10、Extent 5/10
折叠判定 1298/1298；真折叠 236 行，明细全等 **218/236**
不一致用例 **17 个**，按家族归并：A1_nbsp_zwsp 3 ｜ F_lat_words 1 ｜ F_nbsp_zwsp 8 ｜ M_modifier 5
❌ T2 记账结构 / ❌ T2b A 组 / ❌ T3 折叠 / ❌ T2c Tab（**四红保留** —— 与"登记差异不静默"一致）
```
⇒ **`Extent 1260/1298` = 38 条**、**折叠明细 `218/236` = 18 条** ⇒ 与 T1d/T2 关心的两组**同量级且口径一致**。

### 19.2 逐例明细落盘（兑现 T2 的请求）
`build/MilBridge/gen/tline-detail-20260913-1710.txt`（208 行，**机读**：含 §19.1 全部汇总行 +
**17 个不一致用例的逐条原因**（用例名/行号/真值 vs 我们）+ 折叠明细不符样例，样例上限已从 8 提到 **24**）。
**装置现状清点（诚实）**：折叠明细的**逐例行**目前打**样例**（≤24），不是"全部 18 条"的完整清单；
要完整清单需把 `colFailSamples` 的截断去掉并加 `用例名/行号/真值/我们/差` 五列（**原坐标**：
`HbTextLineParity/Program.cs` 的 `colFailSamples.Add(...)` 与 `familyDiff/diffCaseIds` 两处）—— **我这轮没改（预算见底），如实记缺口**。

### 19.3 `getTextRunSpans` 收口读数：**未达标（=0），且我说明缺什么**（并入 §17 的口径）
T3 落盘的整行原文（`$HOME/wfp-runs/go-*`，**以"首次接手那次落盘"为准**）：
```
HB_TEXTLINE enabled=0 lines=1 draw=0 getTextBounds=0 getTextRunSpans=0 fallbackTotal=0 Collapse=0 … paragraphs=1 breakNull=0
  … fallbackCalls=1 fallbackHandled=1 fallbackBailed=0 lastBail="-" multiFontSwitch=1 … multifont=plan=1 runs=1 runGt1=0
  cpUncovered=2 coverageProbe=63 coverageCacheHit=1 fallbackApplied=2 fallbackFailed=0 fromSystemScan=2 segments=2 chunkedLines=1
```
⇒ **`getTextRunSpans = 0`** ⇒ **判据（≥1，"TextBoxLine.EndOfParagraph 真问过我们的 spans"）在这一趟里**没有达成****。
**缺的读数（不推断）**：一趟**真正走到 EOP 分支**的 TextBox 场景运行的 dump（该趟需 `previousLineBreak==null && lineLength<=0` 之外的条件成立，
即 `TextBoxLine.cs:370` 那条链被走到）；**另外** `lines=1 / paragraphs=1 / fallbackCalls=1` 说明**那一趟我们只接手了一个单行段落**
⇒ 即使 spans 被问过，也未必问在我们这一行上。**这两条都要下一趟读数才能定**，我不拿推断补。

### 19.4 我上一轮引入的 regression（本轮自抓 + 已修）
`refresh_applocal()` 用了 `$ROOT`，而 `run.sh` **只定义了 `MB`/`ART`** ⇒ 在 `set -u` 下炸
`run.sh: 行 187: ROOT: 未绑定的变量` ⇒ **`tline`/`icu` 两个目标直接死在第一步**（本轮第一次跑就是这样，两次读数 7 行 vs 208 行）。
**已修**：脚本顶部显式 `ROOT="$(cd -- "$MB/.." && pwd)"` 并加注释。**教训**：我上一轮"加了 helper 就走了"，**没有跑一次它进入的目标** —— 这正是"改了要给门禁跑"的又一次例证。

---

## 20. 完整逐例明细（去截断）+ 条数可观测 + Extent 的 CJK 归类

**生成命令**（`-m:1`、无 `--no-build`；跑前 `loadavg` = **0.18 / 0.96 / 1.29**，机器基本空闲；**未发应用**）：
```bash
bash build/MilBridge/run.sh tline          # harness 直接写盘完整明细
```
**被测版本**：shim **`EBCCDB1EE65E6F7653DA338D70188410615062F825A10969B737CA7D48281BBF`**（3766 行）；
PC `8ff5cb388ca75964`、provider `71ba86c6495347fe`。

### 20.1 机读产物（**无截断**）
`build/MilBridge/gen/tline-detail-full.txt` —— **99 行 / 3 段**：
```
# 段1 折叠明细逐行（五列：用例|行|我们|真值|差|cr 我们|cr 真值）  条数 = 18
# 段2 Extent 余差逐行（主对拍集 38 + LineHeight 组 20；CJK 用例标 +CJK）  条数 = 58
# 段3 记账不一致用例（用例|原因）  条数 = 17
```
（同时保留全文日志 `build/MilBridge/gen/tline-detail-20260913-1730.txt`。）

### 20.2 "条数 vs 上限"已做成可观测（防下次把样例读成全部）
```
[完整明细] 折叠不符 18 条（样例上限 24 ⇒ 未截断）；记账不一致 17 条（用例样例上限 80）；Extent 余差 58 条（控制台样例上限 45）
```
⇒ **折叠 18/18** 正是 T2 要的那组（<= 上限，未截断）；**Extent 58**（主集 38 + LH 20）。

### 20.3 ⭐ Extent 38 条里的 **CJK 归类**（回答 T2 "那 4 条是否也在结构边界内"）
段2 里带 `+CJK` 标记的共 **35 条**（主集标注，判据 = 用例文本含 `>= U+2E80` 的码点）。
**非 CJK 的余差条数 = 3**（可从文件直接取：`sed -n '/^# 段2/,/^# 段3/p' tline-detail-full.txt | grep -v "+CJK" | grep -v "^#"`）：
```
（上表由本报告生成时同步打印；见下方"原始输出"）
```
**样例（每条都是五列可核）**：
```
A1_nbsp_zwsp_w20 行#7 [file-font+CJK] Extent 真值=16.0859 我们=13.4240 差=-2.6619
A1_nbsp_zwsp_w30 行#4 [file-font+CJK] Extent 真值=19.0744 我们=17.2640 差=-1.8104
```

### 20.4 折叠 18 条的样例（五列，含一处很说明问题的行）
```
F_lat_words_w560|行#0|我们 Len=70 W=252.2240|真值 Len=70 W=252.2100|差 W=0.0140|cr 我们=[30,40) W=259.2160|cr 真值=[31,39) W=259.2133
F_nbsp_zwsp_w40|行#3|我们 Len=2 W=12.6560|真值 Len=2 W=12.6567|差 W=-0.0007|cr 我们=[14,2) W=-3.0560|cr 真值=[14,2) W=3.3433
F_nbsp_zwsp_w80|行#0|我们 Len=9 W=32.2240|真值 Len=9 W=22.5433|差 W=9.6807|cr 我们=[2,7) W=34.1760|cr 真值=[1,8) W=48.0133
```
⇒ 第二行是同 `(cp,len)` 但 **cr 宽度符号相反**（我们 `-3.0560` vs 真值 `3.3433`）⇒ **宽度计算路径**问题（与 §17 的 NBSP 线索同族）；
第一行是**前缀/簇边界差 1 字**（`[30,40)` vs `[31,39)`）⇒ 即 T2 说的"可见前缀/cluster 边界"结构桶。**只定位，不改实现。**

### 20.5 本轮回归读数（同一次运行）
```
T1.73 = 73/73 ｜ A 组·断行位置 行级 972/972、用例级 213/213
Height 1298/1298、Baseline 1298/1298、Extent 1260/1298（=38）
折叠判定 1298/1298；明细全等 218/236
通过 19 / 失败 2   ← 失败项即 §19 里那两条（T2 记账 / T3 折叠）；**T2b（A 组）与 T2c（Tab）本轮已转绿**（R1 多字体生效）
```

### 20.6 `getTextRunSpans`：仍欠（未发应用）
按主控安排**未发应用**（`--only=textbox-edit` 那趟要等"槽空着"）。**缺的读数不变**：一趟真正走到 EOP 分支的 TextBox dump（§19.3 已写清）。

### 20.3-bis 更正与定论（**回答 T2 的"那 4 条"**）
上一小节我写"非 CJK = 3"是**用错了筛法**（段2 里 LH 组那 20 条的标记是 `[NotoSansCJK(da)]`，不是 `+CJK`，所以被算进了"非 CJK"）。
**正确口径（主对拍集 38 条）**：带 `+CJK` 的 **34 条** + **4 条 `M_modifier_*`** = 38。
**那 4 条逐行原文（T2 要的就是它们）**：
```
M_modifier_w80  行#1 [file-font] Extent 真值=18.0000 我们=14.3200 差=-3.6800
M_modifier_w120 行#1 [file-font] Extent 真值=18.0000 我们=14.3200 差=-3.6800
M_modifier_w320 行#0 [file-font] Extent 真值=18.0000 我们=18.0800 差= 0.0800
M_modifier_winf 行#0 [file-font] Extent 真值=18.0000 我们=18.0800 差= 0.0800
```
⇒ **4 条全部落在 `M_modifier_*`（TextModifier 未实现，已登记）**，且真值恒为 **18.0000**（整数值）
⇒ **与 T1d 的 CJK 回退边界不是同一桶**：这两条尾巴（`0.0800` / `-3.6800`）更像 **TextModifier 那条链的 EOP/段落级 extent**。
⇒ **T2 的"34 ⊂ 38 是否容差嵌套的必然结果"这个问题，答案是：38 = 34（CJK 边界）+ 4（M_modifier），不是容差嵌套**；
**LH 组另外 20 条**是 `[NotoSansCJK(da)]`（**代用字体**，真机用 MS YaHei ⇒ 不可比），**不属于主对拍集**。

---

## 21. `refresh_applocal()` 的路径拼错（死代码 + 误导性日志）—— 已修 + 牙齿 + **并发现真实影响**

### 21.1 缺陷（T1d 发现，T1b 复现并修）
`run.sh` 里 `ROOT="$(cd -- "$MB/.." && pwd)"` 已经是 **`…/wpf-linux/build` 本身**，
而 helper 写成 `$ROOT/build/…` ⇒ 拼成 **`…/wpf-linux/build/build/…`** ⇒
**复现**：`ls -d build/build` ⇒ `No such file or directory` ⇒ **四个权威件永远"缺失（跳过）"** ⇒ 该函数**一行都没生效**。
（T1d 报的原文形态：4 行 `[applocal] 权威产物缺失（跳过）：…/build/build/…`。）

### 21.2 修法（两处，都在 `build/MilBridge/run.sh`）
1. 路径改 **`$ROOT/DirectWriteForwarder.Linux/…`**（去掉多出来的 `/build`）；
2. **缺件不再静默**：每个缺失件打两行醒目告警（`⚠️⚠️ 权威产物缺失，未同步…` ＋ `无法证明探针测的是权威件 ⇒ 本次读数不可信`），
   末尾汇总 `N 个权威产物缺失` 并 **`return 1`**；4/4 就位时打 `汇总：4/4 …`（可被脚本/人一眼核对）。
   注释里同时写明**为什么这个函数不是多余的**（探针 csproj 是 HintPath+Private=true，`build` 的增量复制语义不可靠 ⇒ 本函数把它变成"无条件 cp -f + 打印两侧 sha"）。

### 21.3 ⭐ 改后实测：**影响不是零 —— 4 个副本里有 2 个确实是陈旧的**
```
[applocal] DirectWriteForwarder.dll：**陈旧 7327b80a754ec3af → 已同步为权威 284d2628d92b984f**
[applocal] DirectWrite.Linux.Provider.dll：已与权威一致（71ba86c6495347fe）
[applocal] PresentationCore.dll：**陈旧 455ddb381743df1f → 已同步为权威 6dfacf822e4163bb**
[applocal] WindowsBase.dll：已与权威一致（1bc072a0b4d567f0）
[applocal] 汇总：4/4 权威产物均已就位并与副本一致/已同步        （返回码 0）
```
⇒ **探针目录里的 `PresentationCore.dll` 与 `DirectWriteForwarder.dll` 都比权威旧**（T1d 当时看到的 `455ddb38…` 是**旧副本**，权威现已 `6dfacf82…`）。
**对既往读数的意义（必须说清）**：`T0.6` 只钉**shim 源**的表 sha，**没有钉探针目录里 PC/DWF 副本** ⇒
§19/§20 那些读数（PC 记的是 `8ff5cb38…`）**无法证明当时 app-local 副本与权威一致**。
**⇒ 结论**：**修好之后必须用同步过的副本重跑一遍 `tline`**；本轮 `loadavg = 10.02 / 12.62 / 11.11`（偏高，主控交代"跑前先看 loadavg"）
⇒ **本轮不跑**，留待下一轮（并在报告里注明：同步前的 `Extent 38 / 折叠 218/236` 等数字**来自未同步副本**，属可疑读数）。

### 21.4 牙齿（缺件必须变红）—— 用**假 ROOT** 造缺件，零触碰真实产物
```
（假 ROOT：/tmp/t1b-fake-root，四个权威件都不存在）
[applocal] ⚠️⚠️ **权威产物缺失，未同步**（这不是跳过，是没得同步）：/tmp/t1b-fake-root/PresentationCore.Linux/bin/Debug/PresentationCore.dll
[applocal] ⚠️⚠️ 缺件 = **无法证明探针测的是权威件** ⇒ 本次读数不可信，请先建出该产物
…
[applocal] 汇总：**4 个权威产物缺失** ⇒ 本次探针读数不成立（缺件不静默）
返回码=1
```
⇒ **牙齿成立**：缺件必然"醒目告警 + 非 0"，不再有"静默跳过"。

---

## 22. `T0.7`（钉住 app-local 副本）+ 重跑 `tline` 的**挂起**（loadavg 未达门槛）

### 22.1 已做：`T0.7` —— 把"探针目录里真正被加载的 4 个副本"与权威件**并排钉住**
动机（本轮实测）：`T0.6` 只钉 **shim 源**，**没钉 app-local 副本** ⇒ 曾出现
`bin/Release/PresentationCore.dll = 455ddb38…` 而权威 `= 6dfacf82…` 却照跑读数 ⇒ **"测量对象没被钉住"那一族**。
**实现**（`build/MilBridge/tests/HbTextLineParity/Program.cs`，编译 **0 错 0 警**）：新增 `T0.7`，
对 4 个副本（`PresentationCore` / `WindowsBase` / `DirectWriteForwarder` / `DirectWrite.Linux.Provider`）
逐条打印 `副本=<sha16>  权威=<sha16>  ✓/❌`，并 `Check` 要求 **4/4 相同**（不一致即红）。
⇒ 从此"探针测的是哪份 PC/DWF"与"哪份 shim"**都在读数里**。

### 22.2 挂起：重跑 `tline`（RTL 修法① 的验收④）
**本轮未跑**：`loadavg = **8.26**`（主控交代"低于 ~4 再跑，别硬上把读数搞脏"；T3 正在跑三趟应用）。
**下一轮照此执行**（命令 + 预期，已固化，不靠记忆）：
```bash
bash build/MilBridge/run.sh tline        # -m:1、无 --no-build；先看 loadavg < 4
```
**必须逐项相同的六项**（= T1d 在"内嵌修法① shim"下实测的那组；**相同 ⇒ 修法① 对全 LTR 语料零影响，验收④成立；不同 ⇒ 立刻停下当回归报**）：
```
T1.73 73/73 ｜ T2 记账 1286/1298（①286/286 ②68/68 ③984/988，宽度超差 47）
T2b 972/972 · 213/213 ｜ T2d Height/Baseline 1298/1298 + Extent 1260/1298
T3 判定 1298/1298、明细 218/236 ｜ Tab 0 例 ｜ 通过 19 / 失败 2
```
**并钉住三样**：PC 权威 sha（跑时现场重读）、shim 源 sha（主控给的应为 `d116bcb8a34769d81520a9225a9900f703631f38d3f7a7a04bdb7b89d4e2e4a4`）、
以及 **`T0.7` 那 4 行 app-local 副本 sha（应与权威一致）**。

### 22.3 读数取代关系（按主控要求写明）
**§19 / §20 两组读数**（写 PC `8ff5cb38…` 的那批）**按"app-local 副本未钉 + 早于修法①"标为可疑读数**；
**下一轮那次 `tline` 跑通后，以它取代这两组**（`Extent 38 / 折叠 218-236` 等数字若与之不同，以新跑为准）。

---

## 23. ⭐ `tline` 重跑（RTL 修法① 验收④）—— **六项逐项相同 ⇒ 验收④成立**

**现场重读（不引用任何人的值）**：`loadavg = 5.15 / 7.24 / 9.31`；
`pc = 6dfacf822e4163bb`（19:49 重建，含修法①）、`shim 源 = d116bcb8a34769d8`（3816 行）、`provider = 71ba86c6495347fe`。

### 23.1 同步 + 测量对象钉住（本轮新机制，全部生效）
```
[applocal] DirectWriteForwarder.dll：已与权威一致（284d2628d92b984f）
[applocal] DirectWrite.Linux.Provider.dll：已与权威一致（71ba86c6495347fe）
[applocal] PresentationCore.dll：已与权威一致（6dfacf822e4163bb）
[applocal] WindowsBase.dll：已与权威一致（1bc072a0b4d567f0）
[applocal] 汇总：4/4 权威产物均已就位并与副本一致/已同步
      [T0.7] PresentationCore.dll             副本=6DFACF822E4163BB  权威=6DFACF822E4163BB  ✓
      [T0.7] WindowsBase.dll                  副本=1BC072A0B4D567F0  权威=1BC072A0B4D567F0  ✓
      [T0.7] DirectWriteForwarder.dll         副本=284D2628D92B984F  权威=284D2628D92B984F  ✓
      [T0.7] DirectWrite.Linux.Provider.dll   副本=71BA86C6495347FE  权威=71BA86C6495347FE  ✓
✅ T0.6 被测文件的 sha256 == run.sh 固定的 sha256
```

### 23.2 六项逐项比对（**与主控 §22.2 固化的预期相同**）
| 项 | 预期 | 本轮实测 | 判 |
|---|---|---|---|
| T1.73 | 73/73 | `✅ 73 例 CJK 逐行全等` | ✅ 同 |
| T2 记账 | 1286/1298（①286/286 ②68/68 ③984/988、宽度超差 47） | `行 1286/1298；① 286/286；② 68/68；③ 984/988；宽度超差 47` | ✅ **逐字相同** |
| T2b | 972/972 · 213/213 | `行级 972/972；用例级 213/213` | ✅ 同 |
| T2d | Height/Baseline 1298/1298 + Extent 1260/1298 | `Height 1298/1298、Baseline 1298/1298、Extent 1260/1298` | ✅ 同 |
| T3 折叠 | 判定 1298/1298、明细 218/236 | `折叠判定一致 1298/1298；明细全等 218/236` | ✅ 同 |
| Tab | 0 例 | `Tab 可比例 34 例，其中不一致 0 例` | ✅ 同 |
| 通过/失败 | 19 / 2 | **20 / 2** | ⚠️ **唯一差异：+1 通过** |

**那 +1 的解释（不辩解，只陈述事实）**：本轮我**新增了一条检查 `T0.7`**（钉 app-local 副本，4/4 一致 ⇒ PASS）
⇒ 计数从 19 变 20 **是新增断言本身**，**不是任何一项数据变化**；**全部六项数据逐项相同**。
⇒ **判据成立：RTL 修法① 对全 LTR 语料零影响 ⇒ 验收④成立。**（失败项仍是那两条登记红：T2 记账 / T3 折叠；T2c 现为"保留红但 0 例"，T2b 已绿。）

### 23.3 取代关系（§22.3 的兑现）
本节的读数**取代** §19/§20 那两组（后者按"app-local 副本未钉 + 早于修法①"**标为可疑**）。
⇒ 此后引用 `Extent 38 / 折叠 218-236 / 记账 1286-1298 / Tab 0 例` 一律以 **§23（`pc 6dfacf82…`、`shim d116bcb8…`、4 副本 4/4 钉住）** 为准。

### 23.4 T3 的 `he_same_string_LTR` 8 列轮廓"总量不变分布变了"
按主控给出的判据：**本轮六项 LTR 语料逐项未漂** ⇒ 该项**不是本车道的回归**，
**记为"T3 那边的采样/裁图口径问题"**（判归属由主控另派 T1d）。**本报告不作其它解释。**

---

## 24. 记账残差 **行级清单**（T2 §23.6 最后一格"未判定"→ 已判定）+ 测量对象再钉一次

### 24.1 装置口径修正（**只加输出，不改阈值与语义**）
原来的记账检查是**用例级、且只记"首个原因"**（`caseWhy.Length == 0` 才赋值）⇒ "行级失败清单"取不到，
所以 T2 只能看到"≥5 行有名 + 4 行有计数无名 + 余 0–3 行无读数"。
**改法**：在**每一行**比较失败处追加一条**行级记录** `用例名 | 行号 | 期望 | 实得 | 归类桶`（阈值/语义一字未改），
并写盘 `build/MilBridge/gen/tline-ledger-lines-<date>.txt`（文件头含 **shim 源 sha + 四份 app-local 副本 sha**），
同时打印 **条数 vs 上限**：`[记账行级清单] 12 条（无上限 ⇒ 未截断）`。

### 24.2 ⭐ 12 行**全部**可点名（本轮实测，`pc/provider` 现场 sha 见文件头）
| 桶 | 条数 |
|---|---|
| 行尾空白计数(ws) —— **NBSP/ZWSP 家族** | **6** |
| **硬断计数(nl)** | **4** |
| **行区间长度(Length)** | **2** |
| 合计 | **12** |

### 24.3 测量对象再钉一次（本轮）
```
[applocal] 汇总：4/4 权威产物均已就位并与副本一致/已同步
[T0.7] PresentationCore.dll  副本=C43D351639856680  权威=C43D351639856680  ✓
[T0.7] WindowsBase.dll       副本=8C073FAB0DA88169  权威=8C073FAB0DA88169  ✓
[T0.7] DirectWriteForwarder.dll 副本=879F0020D28806DB 权威=879F0020D28806DB ✓
[T0.7] DirectWrite.Linux.Provider.dll 副本=71BA86C6495347FE 权威=71BA86C6495347FE ✓
✅ T0.6 shim 源 sha 一致（本轮 = 13992B58905D00E0…，3816 行 → 见清单文件头）
```

### 24.4 六项（本轮，与 §23 相同）
`T1.73 73/73` ｜ `A 组 972/972 · 213/213` ｜ `Height/Baseline 1298/1298、Extent 1260/1298` ｜
`折叠判定 1298/1298、明细 218/236` ｜ `Tab 0 例` ｜ `通过 20 / 失败 2`。

### 24.5 收口判定
**"新缺陷 0"成立**（12 行全部落在**已登记**的三类里：NBSP/ZWSP 的 ws 口径 6、硬断计数 nl 4、行区间长度 2；后两类属既有"硬断/记账口径"族，非新缺陷）；
**"未判定 0"成立**（不再有"无读数的 0–3 行"—— 清单是**全量 12 行**，每行有名字与桶）。
**完整 12 行原文**见 `build/MilBridge/gen/tline-ledger-lines-20260913-2100.txt`（文件头含 shim 源 sha 与四份副本 sha）。

### 24.6 §24.5 的**精确归属更正**（原句"后两类属既有硬断/记账口径族"不够准确）
把 12 行按**用例**归并后，精确归属是：
```
6 行 = A1_nbsp_zwsp_*（3 例 × 首个失败行 + 后续行）  → ws 期望 0 / 实得 1        → 桶：NBSP/ZWSP 行尾空白口径（**已登记**）
6 行 = M_modifier_*（w80 行#0/#1、w120 行#0/#1、w200 行#0、w320 行#0）→ 桶：行区间长度 2 / 硬断计数 4
      原文：M_modifier_w80 行#0 期望 Len=50 nl=0 ws=1 → 实得 Len=6 nl=0 ws=1
            M_modifier_w80 行#1 期望 Len=13 nl=1 ws=1 → 实得 Len=6 nl=0 ws=1   （余同）
```
⇒ **6 行全部落在 `M_modifier_*` = TextModifier 未实现（已登记）**：modifier 会改写文本流 ⇒ 行划分天然不同
（真机 `Len=50` vs 我们 `Len=6` 量级差，不是"计数误差"）。**不是新缺陷，也不是"硬断口径"族。**
⇒ 收口判定（**成立**）：**12 行 = 6（NBSP/ZWSP 已登记）+ 6（TextModifier 未实现，已登记）** ⇒ **新缺陷 0、未判定 0。**

---

## 25. 归属交接（主控裁定 2026-09-15）+ 我的一条纠正动作

**裁定**：`build/MilBridge/arm-logs/**`（产日志流程 = 跑五臂 → `ln -f` 硬链接 → 重钉登记表、硬链接约定、README 维护）**归 T1b**；
`known-red.json` / `tools/tline-gate.sh` / `verify-all.sh` **归主控**（全局判据与登记口径），T1b 只读。
**已落**（严格限定在裁定范围内）：`arm-logs/README.md` **只追加两节**（「归属与交接」+「重生成日志不要 `cp` 要 `ln -f`」，逐字写明"静默变绿比变红更危险"）；
`run.sh` **帮助注释**加一段指向该 README（**不改任何行为**）；本节即第三件。
**自证**：README 追加前的 sha16 与字节数已存底，追加后用 `cmp -n <原字节数>` 逐字节比对原段（原文逐字未变）。

**我的纠正动作（纪律 4 现场）**：我曾凭记忆把 `T1b-report.md` 说成 "1023 行"，实际是 **1347 行 / 113,862 B / mtime 2026-09-14 19:25:06**
（主控用 mtime 定案：**今天没有写入者**，是**我的记录陈旧**，文件没被偷写）。
⇒ **此后引用一律给 `sha16 + mtime + 字节数`，不再引用"我记得的行数"**。
**顺带记录纪律 18 的现场（同一 artifact 的不同字段/位置 = 不同读数）**：我读 `known-red.json` 的 `changelog` **尾三个**得 `['3','2','1']`，
主控读**头部**得 `rev5`；**两个读数都对、不矛盾** ⇒ 引用时必须写清"取哪一段"（我这条结论已改定为"我只读了尾部"）。
