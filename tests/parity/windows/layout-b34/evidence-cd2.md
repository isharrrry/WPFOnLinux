# C/D 第二批证据：对齐（AL）/ bidi（BD）/ 行高（LH）

106 例：AL 64、BD 30、LH 12。来源 `results-cd2.json`（真机 WPF 10.0.7）。

## 1. 对齐（AL 组）：观察量是 run 矩形的 X 偏移

`TextLine.Width` **不随对齐变化**（仍是文本宽度），对齐体现在 `GetTextBounds()` 的 `Rectangle.X`：

| 用例 | 行 | Length | Width | run X | 与公式比对 |
|---|---|---|---|---|---|
| `Left` 行0 | 0 | 20 | 151.640 | 0.000 | 0 → 0.000 |
| `Left` 行1 | 1 | 24 | 179.063 | 0.000 | 0 → 0.000 |
| `Left` 行2 | 2 | 26 | 172.400 | 0.000 | 0 → 0.000 |
| `Right` 行0 | 0 | 20 | 151.640 | 48.360 | w-W → 48.360 |
| `Right` 行1 | 1 | 24 | 179.063 | 20.937 | w-W → 20.937 |
| `Right` 行2 | 2 | 26 | 172.400 | 27.600 | w-W → 27.600 |
| `Center` 行0 | 0 | 20 | 151.640 | 24.180 | (w-W)/2 → 24.180 |
| `Center` 行1 | 1 | 24 | 179.063 | 10.467 | (w-W)/2 → 10.468 |
| `Center` 行2 | 2 | 26 | 172.400 | 13.800 | (w-W)/2 → 13.800 |

**全量核对**：Right 用 `w-W`、Center 用 `(w-W)/2`，符合 **104** 行，不符 **0** 行（容差 0.6 DIP）。

### 1.1 Justify：非末行拉到段落宽，**末行不拉伸**

| 行 | Justify Width | Left Width | NewlineLength | 是末行 |
|---|---|---|---|---|
| 0 | 200.000 | 151.640 | 0 | False |
| 1 | 200.000 | 179.063 | 0 | False |
| 2 | 200.000 | 172.400 | 0 | False |
| 3 | 61.770 | 61.770 | 1 | True |

⇒ 非末行 `Width` **恰好等于段落宽**（200.000），末行保持自然宽（61.770）且 `NewlineLength=1`（段落结束）。

### 1.2 ★ Justify × CJK：与 Left **逐行完全相同**

| 用例对 | 行数 | 逐行 (Length,Width) 相同 |
|---|---|---|
| `cjk_punct` w=120 | 7 | True |
| `cjk_punct` w=200 | 4 | True |
| `cjk_punct` w=320 | 3 | True |
| `cjk_punct` w=600 | 2 | True |
| `cjk_nospace` w=120 | 5 | True |
| `cjk_nospace` w=200 | 3 | True |
| `cjk_nospace` w=320 | 2 | True |
| `cjk_nospace` w=600 | 1 | True |

⇒ **WPF 的 Justify 只拉伸「空格」**；CJK 文本没有空格 ⇒ **完全不拉伸**，结果与 Left 逐行一致。
这条直接决定 Linux 侧 CJK 两端对齐的实现：没有可拉伸空格时应当原样输出，不能自作聪明按字间距均分。

## 2. bidi / RTL（BD 组）

字体全部落在 `SEGOEUI.TTF`（**逐例**记了物理文件 sha256，取自 `fontProof.fontFileSha256`）：
* `74f2b3d0c20cf7380eb121a09fd7cdfdc1ccdd12a00db83caec0feb48b4db9f7`

| 文本 | 段落方向 | runs | 逻辑序（TextSourceCharacterIndex） | 视觉序（按 run X 排序） | 同序 | 行宽 |
|---|---|---|---|---|---|---|
| `he_only` | LTR | 1 | [0] | [0] | True | 179.10 |
| `he_only` | RTL | 1 | [0] | [0] | True | 179.10 |
| `ar_only` | LTR | 1 | [0] | [0] | True | 179.19 |
| `ar_only` | RTL | 1 | [0] | [0] | True | 179.19 |
| `he_lat_digits` | LTR | 4 | [0, 8, 12, 21] | [0, 8, 12, 21] | True | 191.18 |
| `he_lat_digits` | RTL | 4 | [0, 7, 13, 20] | [0, 7, 13, 20] | True | 191.18 |
| `ar_parens` | LTR | 4 | [0, 21, 24, 32] | [24, 21, 0, 32] | False | 228.53 |
| `ar_parens` | RTL | 4 | [0, 21, 24, 32] | [0, 21, 24, 32] | True | 228.53 |
| `mixed_3way` | LTR | 5 | [0, 6, 11, 17, 20] | [0, 17, 11, 6, 20] | False | 189.25 |
| `mixed_3way` | RTL | 6 | [0, 5, 11, 17, 20, 21] | [0, 5, 11, 17, 20, 21] | True | 189.25 |

读法：**RTL 段落**下视觉序 == 逻辑序（5/5 文本）；**LTR 段落里的 RTL 片段会被重排**
（`ar_parens` 视觉序 `[24,21,0,32]`、`mixed_3way` `[0,17,11,6,20]`）。
另外 `mixed_3way` 在 LTR 下是 **5 个 run**、RTL 下是 **6 个 run** —— **run 切分本身随段落方向变化**，
Linux 侧不能假设两边 run 数一致。

`GetTextBounds()` 的 `FlowDirection` 字段给出每个 text-bounds 条目的方向（纯希伯来文本在 **LTR 段落**里也报 `RightToLeft`）。

## 3. 行高（LH 组）—— `LineStackingStrategy` 无公开面，只覆盖 `LineHeight`

| 文本 | LineHeight | Height | Baseline | TextHeight | MarkerHeight |
|---|---|---|---|---|---|
| `lat_words` | 未设置 | 21.793 | 17.103 | 21.793 | 21.793 |
| `lat_words` | 10 | 10.000 | 7.850 | 21.793 | 10.000 |
| `lat_words` | 30 | 30.000 | 23.547 | 21.793 | 30.000 |
| `lat_words` | 50 | 50.000 | 39.243 | 21.793 | 50.000 |
| `cjk_punct` | 未设置 | 21.117 | 16.930 | 21.117 | 21.117 |
| `cjk_punct` | 10 | 10.000 | 8.017 | 21.117 | 10.000 |
| `cjk_punct` | 30 | 30.000 | 24.050 | 21.117 | 30.000 |
| `cjk_punct` | 50 | 50.000 | 40.087 | 21.117 | 50.000 |

实测三条公式（6 组数据全对）：

1. `Height = LineHeight`（未设置时 = 字体自然行高）
2. `TextHeight` **恒为字体自然文本高**（不随 LineHeight 变）⇒ `TextHeight ≠ Height`
3. `Baseline = LineHeight × (自然Baseline / 自然Height)`

| 文本 | 自然比值 | LineHeight | Baseline 实测 | 公式预测 | Δ |
|---|---|---|---|---|---|
| `lat_words` | 0.784797 | 10 | 7.850 | 7.848 | +0.0020 |
| `lat_words` | 0.784797 | 30 | 23.547 | 23.544 | +0.0028 |
| `lat_words` | 0.784797 | 50 | 39.243 | 39.240 | +0.0035 |
| `cjk_punct` | 0.801736 | 10 | 8.017 | 8.017 | -0.0007 |
| `cjk_punct` | 0.801736 | 30 | 24.050 | 24.052 | -0.0021 |
| `cjk_punct` | 0.801736 | 50 | 40.087 | 40.087 | -0.0002 |

最大偏差 **0.0035 DIP**（float32 量级）。`MarkerHeight` 也跟随 `Height`。

`AlwaysCollapsible=true` 那一格（`LH_*_lh30_ac1`）与 `ac0` 数值完全一致 ⇒ 行高不受实现选择影响。

⚠️ **`LineStackingStrategy`（`MaxHeight` / `BlockLineHeight`）在 `TextFormatter` 公开面上拿不到**：
`TextParagraphProperties` 的公开与非公开成员里都没有它（见 `probe.json.apiSurface` + `windows-results.json.apiFacts`）。要它只能走 `TextBlock`/`FlowDocument` 那一层，属于另一个 API 面。
