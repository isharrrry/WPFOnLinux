# 追加答复：`closeIndex` 到底取的是什么值（**不新出行**，只读既有真机数据）

> 本文件是 `modifier-scope` arm 的**追加说明**。**未改动任何已交付产物**——
> `out/modifier-scope-raw.json`、`out/modifier-scope-oracle.json`、`out/modifier-scope-oracle.txt`、
> `out/modifier-scope-raw.txt` 的 sha256 与交付时**逐位相同**（见文末复核）。
> 复算脚本：`python3 closeindex-check.py out/modifier-scope-raw.json`（只读 raw，输出到 stdout）。

## 1. `openIndex` / `closeIndex` 的数据来源与逐组取值

两者**都不是从 WPF 读出来的**，而是**客户端自己声明的 run 序列位置**，在 raw 输出里逐用例记录：

| 符号 | raw 字段 | 含义 |
|---|---|---|
| `openIndex` | `modifierOpenIndex` | 客户端 `TextSource.GetTextRun(index)` **返回 `TextModifier` run** 的那个缓冲下标 |
| `closeIndex` | `modifierCloseIndex` | 客户端返回**配对 `TextEndOfSegment(1)`** 的那个缓冲下标；**`-1` = 客户端始终不关闭**（scope 一直到段末） |

构造见 raw 的 `markers` 字段：`U+E000`/`U+E001` 两个合成"元素边缘"字符各占一个字符下标、无字形无宽度。

| 组 | `openIndex` | `closeIndex`（客户端 `TextEndOfSegment` 位置） | `TextModifier.Length` | buffer 长度 |
|---|---|---|---|---|
| `A-scope-line0` | 0 | **4** | 1 | 32 |
| `A-rtl-scope-line0` | 0 | **4** | 1 | 20 |
| `B-scope-lastline` | 30 | **34** | 1 | 35 |
| `C-scope-whole` | 0 | **-1（从不关闭）** | 1 | 37 |
| `C2-scope-visible` | 0 | **-1** | 1 | 37 |
| `D-nomodifier` | **-1（根本没有 modifier）** | -1 | — | 36 |
| `E-scope-oneline` | 0 | **-1** | 1 | 4 |

⇒ **我拟合时用的是"客户端返回 `TextEndOfSegment` 的下标"，既不是 `modifierStart + Length`，也不是"段落末端"。**

## 2. 两种候选定义各拟合一遍（99 行）

```
D_client_closeMarker   (TextEndOfSegment 的下标，本次实际使用)      99/99
D_client_closeMarker+1 (把关闭标记本身也算进 scope)                 99/99   ← 本数据分不开，见 §4
D_i  = open + TextModifier.Length      (候选 i)                    56/99   ✗ 43 处不符
D_ii = 段落末端                         (候选 ii)                   85/99   ✗ 14 处不符
```

**两条候选都被既有真机数据否掉**，且**各自的反例就在 B / C / A 三组里**（不需要新出行）：

**否掉 (i) 的样本（21 行）**——scope 在该行结束时**仍然打开**，但 `open + Length` 早就越过了行尾，于是 (i) 预测 NULL、真机给**非 null**：

| 用例 | 行 | 行区间 | `open+Length` | (i) 预测 | 真机 |
|---|---|---|---|---|---|
| `B-scope-lastline@w80` | line4 | `[25,32)` | 31 | NULL | **非 null** |
| `B-scope-lastline@w100` | line3 | `[24,32)` | 31 | NULL | **非 null** |
| `B-scope-lastline@w140` | line2 | `[22,33)` | 31 | NULL | **非 null** |
| `C-scope-whole@w80/100/140` | 全部非末行（14 行） | 如 `[0,7)` | 1 | NULL | **非 null** |

**否掉 (ii) 的样本（14 行）**——段落带 modifier、行不是末行，但 scope 在**该行之内**就关闭了，于是 (ii) 预测非 null、真机给 **NULL**：

| 用例 | 行 | 行区间 | 客户端 close | (ii) 预测 | 真机 |
|---|---|---|---|---|---|
| `A-scope-line0@w80` | line0 | `[0,8)` | 4 | 非 null | **NULL** |
| `A-scope-line0@w80/100/140` | line1..line3 | 如 `[8,15)` | 4 | 非 null | **NULL** |
| `A-rtl-scope-line0@w80/100/140` | line0/line1 | 如 `[0,9)` | 4 | 非 null | **NULL** |

⇒ **既有数据里有 21 行能让 (i) 与 (ii) 给出相反预测，并且真机读数把两者都否掉、只支持"客户端 `TextEndOfSegment` 的位置"这一条。**
（你提的"典型样本 = scope 在段中提前关闭、且有一行从 scope 内部开始、跨过 scope 末端结束"**我的数据里已经有**：
`A-scope-line0` 的 line0 = `[0,8)` / `[0,10)` / `[0,14)`，scope `[0,4)` —— 该形状 6 个非末行实例**全部 NULL**。）

## 3. 更利于落地的等价表述

"该行结束时 scope 仍打开"与"**下一行起点落在某个已打开 scope 内部**"是**同一个下标**，等价，按后者写更好实现：

```
lbNull(line) == !( !line.isLastLine
                   && exists modifier m: m.openIndex < nextLineStart
                                         && m.endOfSegmentIndex >= nextLineStart )
              where nextLineStart == line.endCharExclusive
```

## 4. `TextModifier.Length` 与"scope 实际关闭位置"是否一致？→ **不一致，而且这正是候选 (i) 的致命处**

- 本 arm 里 `TextModifier.Length` **恒为 1**（它只占那个合成边缘字符），而 scope 真实覆盖：
  `A` = 4 个字符、`B` = 从 30 到 34、**`C/C2` = 36 个字符**。
- **`C2-scope-visible` 用几何把这件事钉死了**：该 modifier 的 `ModifyProperties` 把 emSize 翻倍，
  container=80 时行数 **6 → 14**、最宽字符 advance **19.993333 → 39.983333** ——**36 个字符全都变了**，
  而开启它的那个 `TextModifier` run 的 `Length` 是 **1**。
- 这也与 WPF 自身用法一致：`PresentationFramework` 的 `TextSpanModifier(_elementEdgeCharacterLength, …)`
  传的同样是**合成边缘字符长度**，不是 span 长度；scope 的边界由**配对的 `TextEndOfSegment` 被取用的位置**决定。

⇒ **`closeIndex := modifierStart + TextModifier.Length` 在这个 API 里没有依据**：
`Length` 是"这个 marker run 自己占多少字符"，不是"scope 有多长"。

## 5. ⚠️ 与你们 `M_modifier` 语料的冲突（请核对）

你们给的输入：note 写 scope 覆盖 `[6,45)`，`M_modifier_w80 行#0` 行区间 `[0,50)`，真值 `lbNull=false`。
按本 arm 的规则，**只要 45 处真的有一个 `TextEndOfSegment`**，那么 line0 = `[0,50)` 跨过了它 ⇒
scope 在该行结束时**已关闭** ⇒ 预测 **NULL**，与你们 `lbNull=false` **相反**。

⇒ 二者只能有一个是对的，请核对其中一项：
1. **45 处是否真的返回了 `TextEndOfSegment`？**（若 scope 实际一直开到段末，则预测非 null，与你们一致）；
2. 你们 `lbNull` 的语义是否就是 **`TextLineBreak == null`**？（若是"行尾不需要携带 scope"之类的其它含义，那它对不上是正常的）

**我这边**：上面 §2 的 99/99 拟合、以及 §4 的几何反证，都**只依赖 `modifier-scope` 已交付的真机数据**，
没有新增出行、没有新读数。

## 6. 本数据**分不开**的一项（若你们要落地到这个粒度，需要一趟小样本）

`closeIndex`（"关闭标记下标"）与 `closeIndex + 1`（"关闭标记本身仍属旧 scope"）在 99 行上**都 99/99**，
因为唯一满足 `closeMarker == lineEnd − 1` 的 **3 行全是末行**（`B@w80 line5`、`B@w100 line4`、`B@w140 line3`），
而末行被 `!isLastLine` 一项直接判成 NULL，两条定义在这一项上无差别。

**需要的样本（一条就够）**：**非末行**、且该行**最后一个字符正好是 `TextEndOfSegment` 的位置**。
构造方法：`长文本 + [open]abc[close] + 更多文本`，并把容器宽度调到**恰好让 line0 在 close 处断开**。
- 若真值 NULL ⇒ "关闭标记本身已不在 scope 里"（`closeMarker`，本次使用的定义）
- 若真值非 null ⇒ "关闭标记仍属旧 scope、下一次取用时才弹出"（`closeMarker + 1`）

## 7. sha256 复核（证明已交付产物未被改动）

```
88559d670f1bb955f4714e2a764a7fffbb29bcc2e6137289440df1540c9f1586  tab-anchor/out/tab-anchor-raw.json
6818b4783061cda3e13895b40c0a47cf42ed7b3fca8ba8a3c032523e12453232  modifier-scope/out/modifier-scope-raw.json
cc4b722e7ee52659...                                              modifier-scope/out/modifier-scope-oracle.json
b32c620734d293e8...                                              modifier-scope/out/modifier-scope-oracle.txt
a66f11763e134cd9e7814341afface1f85b9618d2b5ebab0a2a59a339d17992a  modifier-scope/out/modifier-scope-raw.txt
```

（完整值以 `sha256sum` 现场输出为准；本文件与 `closeindex-check.py` 为**新增**文件，不影响上述任何 sha。）
