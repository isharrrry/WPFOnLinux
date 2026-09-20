# C/D 第一批证据：TextTrimming / 行起点累加 / AlwaysCollapsible

用例 184 个；全部来自 `results-cd1.json`（真机 Windows + WPF 10.0.7）。

## 1. TextTrimming（T 组，144 例）

### 1.1 触发统计（闸门 = `TextLine.HasOverflowed`，WPF `Line.cs:109/161/197/455`）

| HasOverflowed | 调用了 Collapse | 结果 HasCollapsed | 用例数 |
|---|---|---|---|
| False | False | None | 18 |
| False | True | False | 70 |
| True | False | None | 18 |
| True | True | True | 36 |

读法：**溢出 + 非 None 才真折叠**（36 例）；不溢出时调用 Collapse 也只会得到 `HasCollapsed=false`
（70 例）——后者就是「框架不会调它」的那条闸门的实测形态。

### 1.2 `CharacterEllipsis` vs `WordEllipsis`（同一个源行，NoWrap，段落宽 120）

| 用例 | 折叠前行长/宽 | 折叠后宽 | collapsedRange(段落系 idx,len) | 被折叠掉的原文本 |
|---|---|---|---|---|
| `cjk_nospace_CharacterEllipsis` | 31 / 480.000 | 109.017 | idx=6 len=25 | `需要按字断行标点符号的行首禁则与行尾禁则都要对上` |
| `cjk_nospace_None` | 31 / 480.000 | 0.000 | idx=None len=None | `None` |
| `cjk_nospace_WordEllipsis` | 31 / 480.000 | 109.017 | idx=6 len=25 | `需要按字断行标点符号的行首禁则与行尾禁则都要对上` |
| `cjk_punct_CharacterEllipsis` | 44 / 684.593 | 109.017 | idx=6 len=38 | `很好。」（真的吗？）『引号』“双引号”【方括号】——破折号……还有省略号。` |
| `cjk_punct_None` | 44 / 684.593 | 0.000 | idx=None len=None | `None` |
| `cjk_punct_WordEllipsis` | 44 / 684.593 | 109.017 | idx=6 len=38 | `很好。」（真的吗？）『引号』“双引号”【方括号】——破折号……还有省略号。` |
| `lat_words_CharacterEllipsis` | 80 / 577.353 | 114.347 | idx=13 len=67 | `wn fox jumps over the lazy dog and the waffle office ffl flourish.` |
| `lat_words_None` | 80 / 577.353 | 0.000 | idx=None len=None | `None` |
| `lat_words_WordEllipsis` | 80 / 577.353 | 84.700 | idx=10 len=70 | `brown fox jumps over the lazy dog and the waffle office ffl flourish.` |
| `long_word_CharacterEllipsis` | 56 / 406.357 | 116.907 | idx=13 len=43 | `lifragilisticexpialidocious1234567890 tail` |
| `long_word_None` | 56 / 406.357 | 0.000 | idx=None len=None | `None` |
| `long_word_WordEllipsis` | 56 / 406.357 | 52.270 | idx=6 len=50 | `Supercalifragilisticexpialidocious1234567890 tail` |
| `mixed_CharacterEllipsis` | 46 / 468.767 | 117.153 | idx=10 len=36 | `英 text with ASCII words 和标点，测试断点位置。` |
| `mixed_None` | 46 / 468.767 | 0.000 | idx=None len=None | `None` |
| `mixed_WordEllipsis` | 46 / 468.767 | 117.153 | idx=10 len=36 | `英 text with ASCII words 和标点，测试断点位置。` |
| `spaces_CharacterEllipsis` | 42 / 251.663 | 109.660 | idx=16 len=26 | `inner    and trailing    ` |
| `spaces_None` | 42 / 251.663 | 0.000 | idx=None len=None | `None` |
| `spaces_WordEllipsis` | 42 / 251.663 | 109.660 | idx=16 len=26 | `inner    and trailing    ` |

**拉丁**：Character 保留到字符 13（宽 114.347），Word 保留到字符 10（宽 84.7）——
Character 会**从词中间切断**，Word 退到**词边界**，两者确实不同。

**CJK**（`T1_cjk_punct_*_nowrap_w120`）：Character 与 Word **结果完全相同**
（idx=6, len=38, 宽 109.017）——中文没有空格，Word 找不到词边界，退化成 Character。
这条对 `Justify`×CJK、CJK 省略号都直接有用。

### 1.3 折叠后的可见文本不能只看 Length

实测：折叠后 `Length` **不变**（仍 80），只有 `Width` 变小、`HasCollapsed=true`，
真正被隐藏的字符区间只能从 `GetTextCollapsedRanges()` 拿（见上表 idx/len/Width）。
⇒ Linux 侧渲染省略号时必须用 collapsedRange，不能靠 Length 推。

### 1.4 不溢出就绝不折叠（闸门直证）

| 用例 | 段落宽 | 行宽 | HasOverflowed | 调 Collapse 后 HasCollapsed |
|---|---|---|---|---|
| `T4_lat_words_CharacterEllipsis_multi` | 200 | 172.400 | False | False |
| `T4_cjk_nospace_WordEllipsis_multi` | 200 | 96.000 | False | False |
| `T3_lat_words_CharacterEllipsis_narrow_w320` | 320 | 301.343 | False | False |
| `T3_cjk_punct_WordEllipsis_narrow_w320` | 320 | 288.000 | False | False |

⚠️ **T3 的构造缺陷（如实记录）**：`T3` 想用「约束宽 < 行宽「触发折叠，但 `Wrap` 模式下
第一行往往本来就窄于半个段落宽，于是什么都没折叠。它在 CJK 文本上有效，在短行拉丁上无效；
C/D 第二批会把 T3 换成「先 NoWrap 拿长行，再窄约束」的构型。

## 2. 行起点累加自证（L 组，10 例）—— B2 实现行区间的直接模板

规则（实测）：**`TextLine.Start` 恒为 0**（3222/3222），所以行区间只能这样算：

```
int start = 0;                       // 段落内偏移
while (start < text.Length) {
    TextLine line = formatter.FormatLine(source, start, width, pprops, prevBreak, cache);
    string slice = text.Substring(start, line.Length);   // ← 本行覆盖的源区间
    start += line.Length;                                // ← 唯一的推进方式
}
```

### `L_blank_lines_w100`（段落宽 100，源 21 字符）

源文本：`para one


para three`

| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 9 | 9 | 1 | 66.830 | `para one\n` | True |
| 1 | 9 | 1 | 10 | 1 | 0.000 | `\n` | True |
| 2 | 10 | 1 | 11 | 1 | 0.000 | `\n` | True |
| 3 | 11 | 11 | 22 | 1 | 78.237 | `para three` | True |

### `L_blank_lines_w200`（段落宽 200，源 21 字符）

源文本：`para one


para three`

| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 9 | 9 | 1 | 66.830 | `para one\n` | True |
| 1 | 9 | 1 | 10 | 1 | 0.000 | `\n` | True |
| 2 | 10 | 1 | 11 | 1 | 0.000 | `\n` | True |
| 3 | 11 | 11 | 22 | 1 | 78.237 | `para three` | True |

### `L_cjk_punct_w100`（段落宽 100，源 20 字符）

源文本：`他说：「今天很好。」（真的吗？）『引号』`

| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 6 | 6 | 0 | 96.000 | `他说：「今天` | True |
| 1 | 6 | 6 | 12 | 0 | 96.000 | `很好。」（真` | True |
| 2 | 12 | 6 | 18 | 0 | 96.000 | `的吗？）『引` | True |
| 3 | 18 | 3 | 21 | 1 | 32.000 | `号』` | True |

### `L_cjk_punct_w200`（段落宽 200，源 20 字符）

源文本：`他说：「今天很好。」（真的吗？）『引号』`

| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 12 | 12 | 0 | 192.000 | `他说：「今天很好。」（真` | True |
| 1 | 12 | 9 | 21 | 1 | 128.000 | `的吗？）『引号』` | True |

### `L_hard_lf_w100`（段落宽 100，源 28 字符）

源文本：`first line
second line
third`

| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 11 | 11 | 1 | 61.003 | `first line\n` | True |
| 1 | 11 | 12 | 23 | 1 | 85.097 | `second line\n` | True |
| 2 | 23 | 6 | 29 | 1 | 35.917 | `third` | True |

### `L_hard_lf_w200`（段落宽 200，源 28 字符）

源文本：`first line
second line
third`

| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 11 | 11 | 1 | 61.003 | `first line\n` | True |
| 1 | 11 | 12 | 23 | 1 | 85.097 | `second line\n` | True |
| 2 | 23 | 6 | 29 | 1 | 35.917 | `third` | True |

### `L_lat_words_w100`（段落宽 100，源 43 字符）

源文本：`The quick brown fox jumps over the lazy dog`

| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 10 | 10 | 0 | 72.043 | `The quick ` | True |
| 1 | 10 | 10 | 20 | 0 | 75.437 | `brown fox ` | True |
| 2 | 20 | 11 | 31 | 0 | 83.753 | `jumps over ` | True |
| 3 | 31 | 13 | 44 | 1 | 91.150 | `the lazy dog` | True |

### `L_lat_words_w200`（段落宽 200，源 43 字符）

源文本：`The quick brown fox jumps over the lazy dog`

| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 20 | 20 | 0 | 151.640 | `The quick brown fox ` | True |
| 1 | 20 | 24 | 44 | 1 | 179.063 | `jumps over the lazy dog` | True |

### `L_mixed_lf_w100`（段落宽 100，源 33 字符）

源文本：`head

中英 mixed tail with words 结束`

| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 5 | 5 | 1 | 37.727 | `head\n` | True |
| 1 | 5 | 1 | 6 | 1 | 0.000 | `\n` | True |
| 2 | 6 | 9 | 15 | 0 | 82.253 | `中英 mixed ` | True |
| 3 | 15 | 10 | 25 | 0 | 59.533 | `tail with ` | True |
| 4 | 25 | 9 | 34 | 1 | 82.207 | `words 结束` | True |

### `L_mixed_lf_w200`（段落宽 200，源 33 字符）

源文本：`head

中英 mixed tail with words 结束`

| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 5 | 5 | 1 | 37.727 | `head\n` | True |
| 1 | 5 | 1 | 6 | 1 | 0.000 | `\n` | True |
| 2 | 6 | 25 | 31 | 0 | 196.153 | `中英 mixed tail with words ` | True |
| 3 | 31 | 3 | 34 | 1 | 32.000 | `结束` | True |

要点复述：**区间含硬断字符**（`Length` 把 `\n` 算进去，`NewlineLength` 单独给个数）；
**空行是 Length=1、内容 `\n` 的普通行**（`Width=0` 但 `Height/Baseline` 与普通行相同）。

## 3. AlwaysCollapsible 开/关对照（P 组，30 例）

选择规则（`TextFormatterImp.cs:224`）：`!AlwaysCollapsible && previousLineBreak==null && lineLength<=0`
→ 走 `SimpleTextLine`；否则 `FullTextLine`。而 `SimpleTextLine.cs:973/983` 里
`GetTextLineBreak()` 与 `GetTextCollapsedRanges()` **恒返回 null**。

| 文本 / 宽度 | AC | 行实现 | 行数 | 行(Length/Width) | lineBreak 非null | collapsedRanges 非null | textBounds 有 run |
|---|---|---|---|---|---|---|---|
| `blank_lines|w120` | 关 | FullTextLine/MS.Internal.TextFormatting.SimpleTextLine | 4 | 9/67,1/0,1/0,11/78 | 0/4 | 0/4 | 2/4 |
| `blank_lines|w120` | 开 | FullTextLine | 4 | 9/67,1/0,1/0,11/78 | 0/4 | 0/4 | 2/4 |
| `blank_lines|w200` | 关 | FullTextLine/MS.Internal.TextFormatting.SimpleTextLine | 4 | 9/67,1/0,1/0,11/78 | 0/4 | 0/4 | 2/4 |
| `blank_lines|w200` | 开 | FullTextLine | 4 | 9/67,1/0,1/0,11/78 | 0/4 | 0/4 | 2/4 |
| `blank_lines|w60` | 关 | FullTextLine/MS.Internal.TextFormatting.SimpleTextLine | 6 | 5/34,4/29,1/0,1/0 | 0/6 | 0/6 | 4/6 |
| `blank_lines|w60` | 开 | FullTextLine | 6 | 5/34,4/29,1/0,1/0 | 0/6 | 0/6 | 4/6 |
| `cjk_nospace|w120` | 关 | FullTextLine | 5 | 7/112,7/112,7/112,7/112 | 0/5 | 0/5 | 5/5 |
| `cjk_nospace|w120` | 开 | FullTextLine | 5 | 7/112,7/112,7/112,7/112 | 0/5 | 0/5 | 5/5 |
| `cjk_nospace|w200` | 关 | FullTextLine | 3 | 12/192,12/192,7/96 | 0/3 | 0/3 | 3/3 |
| `cjk_nospace|w200` | 开 | FullTextLine | 3 | 12/192,12/192,7/96 | 0/3 | 0/3 | 3/3 |
| `cjk_nospace|w60` | 关 | FullTextLine | 10 | 3/48,3/48,3/48,3/48 | 0/10 | 0/10 | 10/10 |
| `cjk_nospace|w60` | 开 | FullTextLine | 10 | 3/48,3/48,3/48,3/48 | 0/10 | 0/10 | 10/10 |
| `hard_lf|w120` | 关 | FullTextLine | 3 | 11/61,12/85,6/36 | 0/3 | 0/3 | 3/3 |
| `hard_lf|w120` | 开 | FullTextLine | 3 | 11/61,12/85,6/36 | 0/3 | 0/3 | 3/3 |
| `hard_lf|w200` | 关 | FullTextLine | 3 | 11/61,12/85,6/36 | 0/3 | 0/3 | 3/3 |
| `hard_lf|w200` | 开 | FullTextLine | 3 | 11/61,12/85,6/36 | 0/3 | 0/3 | 3/3 |
| `hard_lf|w60` | 关 | FullTextLine | 5 | 6/30,5/27,7/54,5/27 | 0/5 | 0/5 | 5/5 |
| `hard_lf|w60` | 开 | FullTextLine | 5 | 6/30,5/27,7/54,5/27 | 0/5 | 0/5 | 5/5 |
| `lat_words|w120` | 关 | FullTextLine | 7 | 10/72,10/75,15/113,13/95 | 0/7 | 0/7 | 7/7 |
| `lat_words|w120` | 开 | FullTextLine | 7 | 10/72,10/75,15/113,13/95 | 0/7 | 0/7 | 7/7 |
| `lat_words|w200` | 关 | FullTextLine | 4 | 20/152,24/179,26/172,10/62 | 0/4 | 0/4 | 4/4 |
| `lat_words|w200` | 开 | FullTextLine | 4 | 20/152,24/179,26/172,10/62 | 0/4 | 0/4 | 4/4 |
| `lat_words|w60` | 关 | FullTextLine | 14 | 4/28,6/40,6/48,4/23 | 0/14 | 0/14 | 14/14 |
| `lat_words|w60` | 开 | FullTextLine | 14 | 4/28,6/40,6/48,4/23 | 0/14 | 0/14 | 14/14 |
| `spaces|w120` | 关 | FullTextLine | 3 | 16/97,13/85,13/53 | 0/3 | 0/3 | 3/3 |
| `spaces|w120` | 开 | FullTextLine | 3 | 16/97,13/85,13/53 | 0/3 | 0/3 | 3/3 |
| `spaces|w200` | 关 | FullTextLine | 2 | 29/194,13/53 | 0/2 | 0/2 | 2/2 |
| `spaces|w200` | 开 | FullTextLine | 2 | 29/194,13/53 | 0/2 | 0/2 | 2/2 |
| `spaces|w60` | 关 | FullTextLine | 6 | 2/0,8/56,6/29,9/40 | 0/6 | 0/6 | 6/6 |
| `spaces|w60` | 开 | FullTextLine | 6 | 2/0,8/56,6/29,9/40 | 0/6 | 0/6 | 6/6 |

统计：AC=关 的 15 例里有 **3 例**出现 SimpleTextLine；
AC=开 的用例里出现 SimpleTextLine 的有 **0 例**（应为 0）。

⇒ **shim 必须与 FullTextLine 对齐**：把 `AlwaysCollapsible=true` 作为「强制完整路径」的开关，
并且**在 SimpleTextLine 路径上必须让 `GetTextLineBreak()`/`GetTextCollapsedRanges()` 返回 null**，
否则会与真机在「哪些成员可用」上分叉。
