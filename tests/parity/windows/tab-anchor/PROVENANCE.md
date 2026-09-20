# U1 · 真机 oracle：Tab **锚点判别**（非整数倍行宽）+ **Indent / ParagraphIndent** 语义（436 例）

> 起因：T1d 在 `tab-rtl` 上量到**设计缺陷** —— 命中的那些行的行宽**恰好是 interval(96) 的整数倍**
> （96 / 192）⇒ "网格锚在左缘"与"锚在右缘"在数学上**不可区分**（两种假设给出同一组位置）。
> ⇒ Q1/Q2 的"方向性锚点"结论**建立在无法区分两种假设的样本上**。
>
> 本 arm 只改宽度（取非整数倍），把"哪条边落格 / 网格从哪条边数"变成**可判定的读数**；
> 同一趟出行追加了 `Indent × 行首 tab` 与 `ParagraphIndent` 维度，回答 T1d 落地 `D-T1` 前缺的两条定义。
> **全部在远端真机完成**；本地只落盘 oracle 文件，未构建、未运行应用（`:97` 归 T3）。
> 停止点参照：沿用 `tab-rtl/PROVENANCE.md` 登记值，**本轮未重新测**。

## 1. 元组

| 项 | 值 |
|---|---|
| 机器 / 运行时 | `bilintu\pc`（Windows NT 10.0.22631.0）／ **.NET 10.0.7**，PresentationCore 10.0.0.0 |
| 测量 | `TextFormatter.Create().FormatLine(...)`，按 `TextLine.GetTextLineBreak()` 循环到段末（每行都给；`TextLine.Start` 是 double 不是字符下标） |
| 设置 | 同 `layout-b34` TextModel：`TextAlignment=Left`、`TextWrapping=Wrap`、`LineHeight=0`(自然)、`Tabs=null`、`AlwaysCollapsible=false` |
| 新增维度 | **`Indent` ∈ {0,24}**、**`ParagraphIndent` ∈ {0,24,48}**、**`FirstLineInParagraph` ∈ {true,false}** |
| arm | tab 两臂：`default`（不覆盖 `DefaultIncrementalTab`）／`tab0`（=0） |
| Dpi / emSize / interval | 96 / **24** / **96**（**实测**，见 §3；不是拿 4×emSize 当假设） |
| 宽度 | 锚点块 **96 / 100 / 140 / 192 / 200 / 220 / 260**；Indent 块 **40 / 80 / 96 / 100 / 140 / 160 / 192 / 220**；探针 1000 |
| 方向 | LTR 为主（拉丁 `a\tb`、`ab\tc`）；RTL 用**纯希伯来 / 纯阿拉伯**（不含拉丁）；另加"希伯来内容 + LTR 段落"对照臂 |
| 字体 | **Arial**，`file:///C:/WINDOWS/FONTS/ARIAL.TTF`，**sha256 `baa251526d6862712a58e613ef451d8a2b60482142ec6aab1d47fb8e23e21a7c`** |
| 覆盖率 | **单字体模式**：Arial 覆盖本轮用到的**全部**码点（拉丁 + 希伯来 + 阿拉伯），`missing=[]`；逐码点覆盖表 + **双向 advance 对照表**在 `out/tab-anchor-oracle.json` 的 `fonts` 段 |

字体选用规则：优先选一个覆盖**所有脚本**全部码点的族（本轮 Arial 直接满足 ⇒ `latin/hebrew/arabic -> Arial`），
因此**希伯来/阿拉伯用例与本机拉丁用例同字体、可比** —— 这正是 `tab-rtl` 那批"两侧 advance 不一致"的可比性问题的答案：
本轮**逐码点测了同一字符在 LTR 段落与 RTL 段落中的 advance**（`advanceLtrParagraphDip` / `advanceRtlParagraphDip` / `advanceSameInBothDirections`），
供核对是否存在方向相关的 advance。

## 2. ⭐ 交付：12 个可判定问题的真机答案

所有答案都由 `analyze.py` 从真机几何**推导**（脚本随仓库提交，可复跑），`answers` 段逐条给出**证据行**。

### 2.1 锚点（本 arm 的正题）

| # | 问题 | 答案 |
|---|---|---|
| **Q1** | **行宽非 interval 整数倍**时，tab 的哪条边落在网格上？网格从行框哪条边数？ | **LTR：tab 的右边缘（沿前进方向的远侧）精确落格**，网格从**行框起点边**（device 左缘 + `ParagraphIndent`）数起 |
| **Q2** | RTL 段落 + 纯希伯来/阿拉伯内容，是否严格镜像？ | **是。镜像成立**：RTL 下**tab 的左边缘**（device 坐标，= 沿 RTL 前进方向的远侧）精确落格，网格从行框起点边（RTL 下是 device **右**缘 − `ParagraphIndent`）数起 |
| **Q3** | 两种方向是否各取自己前进方向的**远侧**？ | **是**（LTR 10/10 取右边缘；RTL 20/20 取左边缘） |
| **Q4** | 纯希伯来内容放进 **LTR 段落**：锚点跟段落方向还是跟解析后的 run 方向？ | **跟段落 `FlowDirection`**：仍是"右边缘落格、从 device 左缘数"，与 LTR 拉丁用例同构 |

**统一的规则表述（box 坐标，两种方向同一条）**：`tab.boxRight == k × interval`，其中
`box = raw − ParagraphIndent`，`raw` 是 WPF 自己报的 `TextBounds` 坐标（**从行的起点边起算、沿前进方向递增**；
LTR 起点边=左缘故 `raw==device x`，**RTL 起点边=右缘**故 `raw == inkRightEdge − deviceX`）。

**判别力是怎么做出来的**（正面回应"旧样本不可区分"）：

- 把 6 个可能锚点写成显式假设 A0…A5，逐样本算**残差**（`res_A0`…`res_A5` 在每条证据行里）；
- A0 = 本 arm 的主张；A1/A4 = "锚在行框远侧边"（即旧样本无法排除的那一族）；A2/A5 = "锚在行的远端墨迹边"（**旧 `tab-rtl` 实际用的那条读数**）；A3 = "锚在起点边但取近侧边"；
- 结果：**A0 在全部 30 条锚点样本上残差恰好 0.000000**；旧读数 A2 在 RTL 上是 **0.506666**（非 0）⇒ **旧结论从"0.5067 比 13.0067 更接近"升级为"0.000000 比 0.506666"**；
- **decisive 样本**：LTR 4/10、RTL 16/20；**非 decisive 的样本被逐条标注原因**，其中就包括 T1d 命中的那一类：

| 为什么某些样本不 decisive（原文进 json 的 `whyNotDecisive`） | 条数 |
|---|---|
| `w=192`：容器是 interval 的**整数倍** ⇒ "从起点边数的网格"与"从远侧边数的网格"是**同一组点**，此宽度**天生无法分离**（= T1d 命中的歧义） | LTR 2 / RTL 4 |
| `a\tb`：文本**前后缀 advance 相等** ⇒ "近侧边从远端墨迹边量"也落格（**对称文本不是好样本**） | LTR 4 |

⇒ 结论：**用 `ab\tc` 这类前后缀 advance 不等、且宽度非整数倍的样本才可判**。每文本的判别余量：

| 文本 | decisive 样本 | 最小竞争假设余量 |
|---|---|---|
| `ab\tc`（LTR） | 4 | **1.306667** |
| `א\tב`（RTL） | 4 | **0.506666** |
| `אב\tג`（RTL） | 4 | **1.48** |
| `ا\tب`（RTL） | 4 | **3.03** |
| `اب\tج`（RTL） | 4 | **5.91** |
| `a\tb`（LTR，对称） | **0** | —（不可判，见上表） |

### 2.2 `Indent × 行首 tab`（主控追加的第一个符号）

| # | 问题 | 答案 |
|---|---|---|
| **Q5** | `Indent=24` + 行首 tab 越界 ⇒ **钳满**还是**断行**？"行首"按哪个起点判？ | **钳满**（clamp）。且"行首"判据按**缩进后的内容起点**，**不是**绝对 `pen == 0`；等价说法："tab 是该行第一个字符" |
| **Q6** | 被钳满的 tab：目标是**行宽**（`[0,w]`）还是**内容宽**（`[indent,w]`）？ | **`[indent, w]`**，不是 `[0,w]`。通用式：box 跨度 `[Indent, container − ParagraphIndent]`；device 跨度 LTR `[ParagraphIndent+Indent, container]`、RTL `[0, container−ParagraphIndent−Indent]` |
| **Q7** | `Indent>0` 时网格是否仍锚在行原点？ | **是，`Indent` 不移动网格**（在 w=140/220 等非整数倍宽度上复核成立） |
| **Q8** | **追加发现**：`ParagraphIndent=24` 时停靠位是 **120** 而不是 96 —— `ParagraphIndent` 会移动网格吗？ | **会，且移动量恰为 `ParagraphIndent`**。用 `ParagraphIndent ∈ {24,48}` × `Indent ∈ {0,24}` × LTR/RTL 全组合确证：停靠位 = `ParagraphIndent + k×interval` |
| **Q9** | `ParagraphIndent>0` 时 `TextLine.Width` 是什么？ | **`line.Width = rawMax − ParagraphIndent`**（**不含** `ParagraphIndent`，但**含** `Indent`）。⇒ 陷阱：`ParagraphIndent>0` 时 `line.Width` 既不是"从 device x=0 到墨迹远端"也不是"内容 advance 宽" |
| **Q10** | `DefaultIncrementalTab = 0` 臂 | 每个 tab 宽度塌成 **0**（字符保留、advance 为 0），与前一轮 tab-zero 一致；本轮 224 条 tab0 样本**全部 0 宽** |
| **Q11** | 模型不适用的样本？ | `ParagraphIndent + Indent ≥ container` 时内容起点已在行框远端之外 ⇒ tab 钳成**零宽**且 `HasOverflowed=true`（如 `Indent=24+ParagraphIndent=24, w=40` ⇒ box 跨度 `[24,24]`、`line.Width=24`、溢出）；**4 条，单独列出不并入钳位统计** |
| **Q12** | 哪些样本"看起来被钳"其实不是？ | **146 条**：其自然停靠位（`pen` 之上最小的 `k×interval`）**本来就等于**行框宽 ⇒ 两种假设读数相同、**不含钳位信息**，单独列出 |

### 2.3 关键证据（逐条可核对，全部取自 `out/tab-anchor-oracle.json` 的 `cases`）

**① 行首 tab 越界 ⇒ 钳满（不是断行），且左缘是 24 不是 0**（`Indent=24`，emSize24 ⇒ interval 96）

| 用例 | 容器 | 行文本 | 行宽 | tab 的 box/device 跨度 | `HasOverflowed` |
|---|---|---|---|---|---|
| `lead-tab-a@w40@LTR@i0` | 40 | `\t` | 40 | `[0, 40]` | False |
| `lead-tab-a@w40@LTR@i24` | 40 | `\t` | 40 | **`[24, 40]`** ← 不是 `[0,40]` | False |
| `lead-tab-a@w80@LTR@i24` | 80 | `\t` | 80 | **`[24, 80]`** | False |
| `lead-tab-only@w40@LTR@i24` | 40 | `\t` | 40 | **`[24, 40]`** | False |
| `mid-tab-a-t-b@w40@LTR@i24` | 40 | `a` / `\t` / `b` | 37.346667 / 40 / 37.346667 | 首行在 tab 前断；**tab 独占第 2 行并被钳到 `[24,40]`** | False |

**为什么这证明"不是断到下一行"**：文本是 `\ta`，tab 是**第一个**字符 ⇒ "在 tab 之前断行"会留下**空行 0**。
实测第 0 行**就是那个 tab**、且其跨度终止在行框远端，随后的 `a` 在第 1 行。
同一机制在 `a\tb` 上表现为：先在 tab 前断（第 0 行只剩 `a`），tab 落到第 1 行后**又**被钳满而不是再断一次
——这正是循环能终止的原因，也说明判据是"**该行第一个字符**/内容起点"而不是绝对 `pen==0`。

**② `Indent=24` 时网格不动、`ParagraphIndent` 才动**

| 用例 | 内容起点(device) | tab 停靠位(box) | 结论 |
|---|---|---|---|
| `lead-tab-a@w140@LTR@i24` | 24 | **96** = 1×96 | `Indent` 不移动网格（w=140 mod 96 = 44，**可判**） |
| `lead-tab-a@w220@LTR@i24` | 24 | **96** = 1×96 | 同上（220 mod 96 = 28） |
| `lead-tab-a@w140@LTR@i0p24` | 24 (`ParagraphIndent`) | **96**（raw 120 − pInd 24） | `ParagraphIndent` 移动了网格 |
| `lead-tab-a@w140@LTR@i24p24` | 48 | **96**（raw 120 − pInd 24） | 锚点 = `ParagraphIndent`，**不是**内容起点 48 |
| `lead-tab-a@w220@LTR@i0p48` | 48 | **96**（raw 144 − pInd 48） | `ParagraphIndent=48` 同样成立 |
| `he-lead-tab-a@w220@RTL@i0p48` | 48 | **96**（raw 144 − pInd 48） | **RTL 同构** |
| `he-mid-tab@w140@RTL@i0p24` | 24 | **96**（raw 120 − pInd 24） | RTL 且行中 tab 同样成立 |

## 3. 实测 interval（不夹带 4×emSize 假设）

用**两个相邻 tab** 做仪器：一个 tab 暴露 0 → 首个停靠位，两个相邻 tab 暴露**两个连续停靠位**，
两者同侧边的距离即 interval。三个脚本 × 两个段落方向共 6 条 default 样本：

| 探针 | LTR 左缘距 | LTR 右缘距 | RTL 左缘距 | RTL 右缘距 |
|---|---|---|---|---|
| `ab\t\tc` | 69.306667 | **96.000000** | **96.000000** | 69.306667 |
| `אב\t\tג` | 69.48 | **96.000000** | **96.000000** | 69.48 |
| `اب\t\tج` | 73.91 | **96.000000** | **96.000000** | 73.91 |

⇒ **interval = 96**，且**拉丁/希伯来/阿拉伯三脚本一致**；那个"等于 96 的边"在 LTR 是**右缘**、在 RTL 是**左缘**
——**仪器本身就独立复现了 Q3 的"取前进方向远侧"**。
（`4×emSize = 96` 只作对照打印，`analyze.py` 的判定全部针对**实测值**。）

## 4. 产物与复现

| 文件 | 说明 |
|---|---|
| `out/tab-anchor-raw.json` | **真机原始输出，未经修改**（436 cases，sha256 `88559d670f1bb955f4714e2a764a7fffbb29bcc2e6137289440df1540c9f1586`） |
| `out/tab-anchor-raw.txt` | 上述原始输出的人读版（含逐行 / 含 tab 行的逐字几何） |
| `out/tab-anchor-oracle.json` | **推导产物**：`cases` 为原始数组**原样内嵌**，另加 `fonts` / `intervalMeasurement` / `model` / `answers` / `unavailableOrUntested` |
| `out/tab-anchor-oracle.txt` | 同上的人读版（问题 → 答案 → 证据行） |
| `analyze.py` | 推导脚本（提交入库，可复跑）：`python3 analyze.py out/tab-anchor-raw.json out/tab-anchor-oracle` |
| `src/Program.cs` `src/TabAnchorOracle.csproj` `src/run.ps1` | 真机侧测量程序；`run.ps1` **跑两遍**并用"去掉 `generatedUtc` 行"的规范化 sha256 比对**确定性** |

复现：`dotnet build` 于 `C:\u1-shaping\src\TabAnchorOracle` → `powershell -File src\run.ps1` → 取 `C:\u1-shaping\out-tabanchor\tab-anchor-raw.*`。
本轮 `DETERMINISM=MATCH`（两次运行规范化 sha256 相同）；`cases: 436`；进程级重试把已知的
`IDWriteFontFace::GetMetrics` ~50% 垃圾 HRESULT 启动噪声挡在数据之外（本轮 2 次运行均 `attempt 1` 即成功）。

## 5. 自我纠错记录（两处，均已在代码中修掉）

1. **重复 case id（我的缺陷）**：第一版没有给 id 加块前缀，`D-paraindent` 与 `B-indent` / `C-rtl-indent` 在
   相同 (text,width,arm) 上撞 id ⇒ 436 条里出现 32 条**同 id 不同块**的条目，json 会变得**有歧义**。
   已改为 `id = 组名/文本@w…@方向@indentArm@tabArm`，使"同一 id 只出现一次"**由构造保证**，
   并在 C# 里加了**硬护栏**：出现重复 id 直接 `return 4` 不出文件。第二个块里与已有块**逐字节重复**的 `I0` 分支也一并删掉。
2. **`run.ps1` 里那句 "INCONSISTENT" 措辞错误（我的缺陷）**：探针的左缘距与右缘距**本来就不相等**
   （两个 tab run 宽度不同），我却把"两值不等"写成了 `INCONSISTENT` —— 这是**判读规则写错**，不是数据问题。
   已改为中性表述："两个边的 delta 都报出来，跨全部探针复现的那个才是 interval，另一个按构造等于
   `interval − 第一个 tab run 的宽度`"。

3. **回传时漏掉一个文件（我的操作缺陷）**：`scp` 一次给两个远端源文件时，**只传回了第一个**，
   第二个人读文件 `tab-anchor-raw.txt` 静默保持旧版 ⇒ 一度出现 `raw.json` 是 436 例、`raw.txt` 还是 372 例的**不一致**。
   已改为**每个文件单独 scp**，并加了落盘后校验：`grep -c '^== \[' out/tab-anchor-raw.txt` 必须等于 json 的 `cases` 数（436），
   且必须含块前缀（`D-paraindent` 64 条）。两个文件现已同一次运行产出。

## 6. 必须标注为**推导值** / **取不到**（无信息就报无信息）

**推导值（不是 API 读数）**
- 每行 `breakCause`（`before-tab` / `after-tab` / `end-of-text` / `at-space` / `mid-token` …）：WPF `TextFormatter`/`TextLine`
  **不暴露**"为什么在这里断"，json 里 `breakReasonApi` 字段明写 `NOT AVAILABLE`，行内 `breakCauseNote` 标注 `DERIVED`。
- `clampClass`（`natural` / `ambiguous-exactly-at-the-edge` / `definitely-clamped` / `degenerate-zero-width-overflow`）：
  由"自然停靠位 vs 行框宽"的**比较**推出，不是 API 字段；Q6 的钳位统计**只取 `definitely-clamped`**，其余单列（Q12 / Q11）。
- 所有 `res_A0…res_A5`、`matchedHypotheses`、`decisive`：由实测几何按显式假设表算出，假设表随 json 给出。

**取不到 / 未覆盖**
- `TextTrimming`：`TextParagraphProperties` **无该成员**，只报 `TextLine.HasOverflowed`。
- `Tabs`（非 null 自定义制表位数组）：**本轮与整个 tab 族一样仍是 `Tabs = null`**，未测。
- `TextWrapping`：只测 `Wrap`；`NoWrap` / `WrapWithOverflow` 未测。
- "`pen` **恰好落在**网格停靠位上时 tab 是前进 0 还是一个 interval"：无样本，未测。
- `FirstLineInParagraph`：各臂对**每一行**传常量（与 `layout-b34` 一致）⇒ 本 oracle **无法拆开**"按段"与"按行"施加 `Indent`/`ParagraphIndent`。
- RTL 下 `Indent>0` **且** `ParagraphIndent>0` 的组合未测（RTL 只测了 `ParagraphIndent ∈ {24,48}` 配 `Indent=0`）。
- 字体固定单族 Arial，无跨字体交叉验证。
- `TextLine.Start` 每条行都是 0，**未被任何答案使用**。

## 7. 与前几轮的关系（口径变更点，请 T1d 注意）

1. **`tab-rtl` 的"锚点"结论口径偏弱，本轮给出强口径**：旧结论基于 RTL 下
   `line.Width − tabLeftEdge mod 96` 的**非零残差 0.506666** 与竞争值 13.006667 的**大小比较**；
   本轮在非整数倍宽度上给出 **A0 残差 0.000000 / 竞争读数 0.506666**，并且**逐样本列出 6 个候选锚点的残差**。
2. **旧结论"Indent 不移动 Tab 网格"成立，但不能外推成"没有段落级属性移动网格"**：
   `ParagraphIndent` **会**移动（Q8）。这是本轮新发现，此前三套 oracle 都没有这个维度。
3. **旧 Q3 的"钳满 = `tabLeftEdge=0 / tabRightEdge=container`"只在 `Indent=0` 时对**：
   `Indent>0` 时左缘是**内容起点**（Q6）。**T1d 代码取"行宽"作为钳位宽度会多出 `Indent`（以及 `ParagraphIndent`）。**
4. **旧 Q2 的"`reachedStopEdge = flow==RTL ? left : right`"成立**，本轮在可判别样本上 30/30 复核通过（Q1/Q2/Q3）。

## 8. 合规与清理

- 真机**只读**：未安装任何软件、未改工程配置、未动他人文件；只在自己的 `C:\u1-shaping\` 下写源码与输出，收完删除。
- **本地零构建、零应用**；未跑 `integration-wave.sh`；只写 `tests/parity/windows/tab-anchor/**`；
  未碰 `src/`、`build/`、`samples/`、`tests/parity/{linux,geometry}/`、`tests/golden/`、`docs/unimplemented.md`、`verify-all.sh`、`upstream/`、`handoff.md`。
