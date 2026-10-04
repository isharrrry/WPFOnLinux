# U1 · 真机 oracle：`TextEndOfSegment` 位置**在 scope 内还是外**（12 例，一个问题的定点样本）

> 目的（主控派单）：`modifier-scope` 的判据里 `closeIndex` 有两条候选——
> **(A) `closeIndex`（关闭标记本身不在 scope 内）** vs **(B) `closeIndex + 1`（关闭标记仍属旧 scope，下次取用才弹出）**——
> 上一批 99 行**都 99/99**，因为唯一满足 `closeMarker == lineEnd − 1` 的 3 行**全是末行**。
> 本批就是为这一个符号做的定点样本：**非末行**、且该行**最后一个字符正好是 `TextEndOfSegment` 的位置**。
> **全部在远端真机完成**；本地只落盘 oracle 文件，未构建、未运行应用（`:97` 归 T3）。

## 1. 构造与标定

- buffer = `"cccccccccc"` + `U+E000`(open) + `"abc"` + `U+E001`(close) + `"cccccccccccc"`
  ⇒ `openIndex = 10`、**`closeIndex = 14`**、buffer 长度 27。
  （`'c'` 的 advance 恰为 **12.000000 DIP**，所以前缀 10 个 `c` = **恰好 120.000000**，位置可精确预测。）
- 程序先**自标定**：宽度 4000 跑一遍，量出**关闭标记所在的 box 位置 = `158.693333`**（它是零宽 run，位置 = 前一个字符的末端）。
- 随后按标定值取 **11 个宽度**：`P−2 / P−1 / P−0.001 / P / P+0.001 / P+1 / P+11.999 / P+12 / P+12.001 / P+24`
  （外加 `P−30` 与 4000 两个远端），使断点分别落在关闭标记**之前 / 之处 / 之后**。
  emSize 24、Arial、`TextWrapping=Wrap`、`TextAlignment=Left`；**12 cases，id 全唯一**，`DETERMINISM=MATCH`。

## 2. ⭐ 一句话结论

> **这个"分离样本"真机根本产生不出来——不是样本不够，而是一个可测的机制：关闭标记是零宽 run，且它「粘」在它后面那个字符上。**
> 11 个宽度扫下来，`line.endCharExclusive − closeIndex` **只取到 `{−4, −1, 0, +2, +8, +13}`**，
> **唯一能让两条定义分歧的取值 `+1` 从不出现**（`+1` = 关闭标记正好是该行最后一个字符）。
> ⇒ **两条定义在本引擎能产生的所有输入上完全等价**（`A_ok=True`、`B_ok=True`、`disagree=0`）。
> ⇒ 给 shim 的可用结论：**只要 shim 也把关闭标记粘到后一个字符上（真机如此），`[open, close)` 与 `[open, close]` 都不会产生分歧**；
> 若 shim 不粘、能产生"行末正好是关闭标记"的行，则取 **`closeIndex`（半开 `[openIndex, closeIndex)`，取用配对 `TextEndOfSegment` 时弹出）**——
> 因为此时标记就在"含有它的那一行"之内。

## 3. ⭐ 三点夹逼——**塌成两点**

| 想要的 `end − close` | 含义 | 是否产生 | 实测样本 |
|---|---|---|---|
| **−1**（"close 前一个字符"） | 标记尚未被消费 | ✅ | `w=156.693/157.693/158.692/158.693`：line0 = `[0,13)` → **非 null** |
| **0**（"恰在 close 处"） | 标记仍未被消费（它落到下一行行首） | ✅ | `w=158.694/159.693/170.692/170.693`：line0 = `[0,14)` → **非 null** |
| **+1**（"close 后一个字符"） | 标记正好是该行最后一个字符 | ❌ **不产生** | 无 |
| **+2** | 标记与**其后一个字符一起**被吞进该行 | ✅ | `w=170.694/182.693`：line0 = `[0,16)` → **NULL** |

⇒ "之前"与"之处"在读数上**是同一态**（都非 null），"之后"是 NULL；**中间那一态不存在**。

**逐行的三个数（`openIndex` / `closeIndex` / `line.endCharExclusive`）**已逐行写进
`out/modifier-close-oracle.json` 的 `answers.Q2_the_three_point_bracket.lines` 与 `out/modifier-close-oracle.txt`
（共 24 行，含每条定义各自的预测列与是否吻合，见 §4 摘录）。

## 4. 逐行证据（节选，全表 24 行在 oracle 里）

| 宽度 | 行 | 行区间 | `end−close` | 含关闭标记? | 末行? | break | 定义 A 预测 | 定义 B 预测 |
|---|---|---|---|---|---|---|---|---|
| 128.693 | line0 | `[0,10)` | −4 | 否 | 否 | **NULL** | NULL ✓ | NULL ✓ |
| 128.693 | line1 | `[10,22)` | +8 | **是** | 否 | **NULL** | NULL ✓ | NULL ✓ |
| 156.693 | line0 | `[0,13)` | −1 | 否 | 否 | **非 null** | 非 null ✓ | 非 null ✓ |
| 158.693 | line0 | `[0,13)` | −1 | 否 | 否 | **非 null** | 非 null ✓ | 非 null ✓ |
| **158.694** | line0 | **`[0,14)`** | **0** | 否 | 否 | **非 null** | 非 null ✓ | 非 null ✓ |
| 170.693 | line0 | `[0,14)` | 0 | 否 | 否 | **非 null** | 非 null ✓ | 非 null ✓ |
| **170.694** | line0 | **`[0,16)`** | **+2** | **是** | 否 | **NULL** | NULL ✓ | NULL ✓ |
| 4000 | line0 | `[0,27)` | +13 | 是 | 是 | NULL | NULL ✓ | NULL ✓ |

- **定义 A 与定义 B 在全部 24 行上预测相同**（`disagree=0`）⇒ 本批**无法**、且**在原理上也无法**用这种行分辨二者。
- 顺带确认了判据的另一个边界：`w=128.693 line0` 的 `end = 10 = openIndex`，即 **modifier run 尚未被取用** ⇒ 无 scope 可携带 ⇒ **NULL** ✓
  （这是"`openIndex < lineEnd`"这一项在上一批没覆盖到的边界上的独立确认）。

## 5. 为什么 `+1` 不会出现（机制，附两个相邻宽度的读数）

标定：关闭标记（零宽）在 `158.693333`，它前一个字符（`'c'`，advance 12.0）结束于同一位置。
跨越跃迁的两个宽度：

| 宽度 | line0 区间 | 说明 |
|---|---|---|
| **170.693** | `[0,14)` | 按**宽度**算，标记（0 宽）完全放得下——但真机**把它留给了下一行**；因为标记之后的那个 `'c'` 会使位置到 `170.693333 > 170.693`，放不下 |
| **170.694** | `[0,16)` | 那个 `'c'` 放得下了 ⇒ **标记与它一起**被吞进 line0 |

⇒ 中间**没有**任何宽度能让行以标记结尾：**标记与紧随其后的 run 同进同出**。
这与上一批 `modifier-scope` 的 B 组一致：那里标记只出现在**末行**（其后无字符）。

## 6. 取不到 / 未覆盖

- 用**非零宽**的 `TextEndOfSegment` run（公开构造函数要求 `length >= 1`，但它仍然不产生 advance）能否产生 `end == close+1`，**未测**。
- 本批只有**一种文本形状**（10×`c` + scope `abc` + 12×`c`）与**一种字体**（Arial）。
- 本节结论是"**引擎能产生哪些输入、对这些输入报什么**"，**不是**对 WPF 内部实现的断言。

## 7. 产物与复现

| 文件 | 说明 |
|---|---|
| `out/modifier-close-raw.json` | **真机原始输出，未经修改**（12 cases，sha256 `514f25c457b1bd057ee0c5be21fc10af8f55f52c8908c9ff1282d53996820924`） |
| `out/modifier-close-raw.txt` | 同上人读版 |
| `out/modifier-close-oracle.json` / `.txt` | 推导产物（`cases` 原样内嵌 + 逐行三个数 + `answers` + 取不到清单） |
| `analyze.py` | `python3 analyze.py out/modifier-close-raw.json out/modifier-close-oracle` |
| `src/Program.cs` `src/ModifierClose.csproj` `src/run.ps1` | 真机测量程序（**自标定**：先量关闭标记位置，再按其 ±取宽度）；`run.ps1` 跑两遍 + 规范化 sha256 比对 + **逐文件打印 SHA256** |

`DETERMINISM=MATCH`（`A=4cefc4820e8c9ea6 B=4cefc4820e8c9ea6`），`cases: 12`，
两个输出文件 sha 与真机打印值**回传后逐文件复核一致**。

## 8. 自我纠错（本轮 1 条）

编译期两次失败（`const string` 不能由 `const char` 拼接、以及标定循环里 `List<object>` 元素的类型转换），
**都在本地改好后重新构建**，没有把失败读数带进 oracle。真机**只读**、**本地零构建零应用**照旧；
只写 `tests/parity/windows/modifier-close/**`。
