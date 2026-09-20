# W22B 报告 —— `#22` P2 / `D-G1`：把 `TextLine.Start` 接进 `CoverageProbe`（门禁的三支 tab 臂）

**lane=W22B** ｜ 2026-09-16 19:40:49 → 19:54 +0800（+0800） ｜ kernel `6.8.0-138-generic` ｜ `nproc=3`
loadavg 开工 `3.30 0.84 0.42` ｜ `MemAvailable 3467412 kB` ｜ `DISPLAY=:97` = **UP**（未自起 Xvfb）｜ 全程未 `pkill -f`

---

## 0 · 一行判决

**新列落地且修后为绿**：`TAB_LINES START 红=0 绿=421 判定行=421 NOINFO=194 红例=0 NOINFO例=148 对齐=Left`；
**反极性（修前 shim 源）= 红 138 行 / 88 例**，与预登记预测**逐位吻合**，`rc=1`；
**既有判据行逐字节未动**（469 → 469，`cmp` 相同，0 条 `<`）；**四支无关臂日志逐字节不变**；
门禁仍 `TLINE_GATE=PASS … generation=#21 tree_gen=same … drift=0 gone=0 unregistered=0`、`rc=0`；**九位与 `inputs_fp` 逐位不变**。

**§5 预测表之外的位移：无**（另见 §8.2 一条**我自己造成的仪器事故**，已如实登记，不是位移）。

---

## 1 · 开工前：九位 / `inputs_fp` 复算（与 `#21` 逐位一致）

`fp_inputs()` 的管道**逐字照抄** `build/close-wave.sh:73-78`（未自己发明）：

| 位 | 现场复算 | `#21` 基线 | 判定 |
|---|---|---|---|
| `bridge` | `d567c26f197ec1e3` | `d567c26f197ec1e3` | ✅ |
| `pc` | `e7cabff9417ed380` | `e7cabff9417ed380` | ✅ |
| `pf` | `2fb1a896f8277647` | `2fb1a896f8277647` | ✅ |
| `windowsbase` | `1114a28ec5a03ab7` | `1114a28ec5a03ab7` | ✅ |
| `provider` | `9aa0d744802aaa31` | `9aa0d744802aaa31` | ✅ |
| `win32shim` | `0098234982391bbf` | `0098234982391bbf` | ✅ |
| `wic_shim` | `03b67fbcd7c385b6` | `03b67fbcd7c385b6` | ✅ |
| `hbtextline` | `76089e1de586ac91` | `76089e1de586ac91` | ✅ |
| `dwf` | `0ed422ef2dd46445` | `0ed422ef2dd46445` | ✅ |
| `inputs_fp` | `a2b74537427ecc4a987edbe52a59c5d01d4817d54de58f445833c33dfb0e78e0` | 同左 | ✅ |

`BRIDGE_SRC_FP=b6acdba4f01599d8`（与基线同）。⇒ **树未被别人动过**，未触发"停并报告"。

---

## 2 · 留档与"改前"基线

### 2.1 留档（`cp -p`，纪律 35）

| 件 | 路径 | before sha16 | 字节 | mtime |
|---|---|---|---|---|
| 仪器源码 | `build/MilBridge/tests/CoverageProbe/Program.cs` | `a8727a5bed6bf049` | 108127 | 2026-09-15 17:24:40 |
| 仪器产物 | `build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll` | `c74a53c5f0ada1d0` | 137728 | 2026-09-16 18:49 |
| 仪器 pdb | 同上 `.pdb` | `ec0dc3c205e2a4c3` | 56120 | — |
| 输出目录里的 pc | 同上 `PresentationCore.dll` | `e7cabff9417ed380` | 4196864 | — |

备份落在 `$HOME/w22b-laneW22B/backup/Program.cs.before` 与 `$HOME/w22b-laneW22B/backup/binRelease/`（后者三件，后文 §5 用 `cmp` 证明逐字节复原）。
仓内 `build/MilBridge/tests/CoverageProbe/known-red.txt` sha16 **`e37603a8825d85ae`**（**全程未被触碰**，见 §5.4）。

### 2.2 "改前"三支 tab 臂读数（用**未改动**的仪器重跑 `#21` 命令）

命令（与 `build/MilBridge/arm-logs/README.md` 的表逐字一致，**未带** `--known-red`，与 `#21` 日志里的"登记表 <未给>"一致）：

```
(cd build/MilBridge/tests/CoverageProbe/bin/Release && \
 dotnet PresentationCore.Tests.dll --tab-lines-oracle <R>/tests/parity/windows/tab-<x>/out/tab-<x>-oracle.json)
```

| 臂 | 我重跑的日志 sha16 | `#21` `arm-logs/` 里的 sha16 | `cmp` |
|---|---|---|---|
| `tab-zero` | `b9d81590f3fcd800` | `b9d81590f3fcd800` | ✅ IDENTICAL |
| `tab-anchor` | `99d72b385fe23a90` | `99d72b385fe23a90` | ✅ IDENTICAL |
| `tab-rtl` | `419e8aaa9c72a9a0` | `419e8aaa9c72a9a0` | ✅ IDENTICAL |

`rc`：`tab-zero=1`（在册红 1 条）、`tab-anchor=0`、`tab-rtl=0`；耗时 `33.8s / 63s / 7s`（3 核机，另有两条车道在跑）。
⇒ **改前基线成立**：三支都逐字节复现 `#21`。

### 2.3 现状核实（预登记 §2.1 的两条）

- `grep -c 'lineStartOffsetsDip' build/MilBridge/tests/CoverageProbe/Program.cs` ⇒ **0**（改前）。
- `grep -n '\.Start\b' …Program.cs` ⇒ **0 命中**（改前）。
⇒ `D-G1` 的"结构性原因"**属实**：本臂对 `Start`/`lineStartOffsetsDip` 零引用。

---

## 3 · 新列的确切语义，以及"为何只新增"

### 3.1 新增输出（全部以 `TAB_LINES START` 开头，是**唯一**新增的行前缀）

| 形态 | 何时印 | 原文样例 |
|---|---|---|
| 逐例判定 | 语料带 `lineStartOffsetsDip` 且 `TextAlignment=Left` 且该例进了比较 | `TAB_LINES START A-anchor/lat-a-t-b@w96@LTR@i0@default 行=3 红=0 绿=3` |
| 逐行红明细 | 该例有红行 | `TAB_LINES START-RED <id> 行#<k> Start 期望=24.000000 实得=0.000000 Δ=-24.000000` |
| 逐例 NOINFO | 该例不可判（面缺字形 / 格式化抛 / 行数不符 / 对齐非 Left） | `TAB_LINES START <id> 行=<n> NOINFO=面缺字形<N>` |
| **可点名计数器** | 每次跑，有语料字段时印一次 | `TAB_LINES START 红=0 绿=421 判定行=421 NOINFO=194 红例=0 NOINFO例=148 对齐=Left 量=R(我方 line.Start) 真值=lineStartOffsetsDip[k] R(v)=Round(v,6,AwayFromZero) 口径=Start≡ParagraphIndent` |
| 对账 | 紧接上一行 | `TAB_LINES START 对账 逐例求和 红=0 绿=421 NOINFO=194 ⇒ 与汇总一致` |

**量**：逐行 `R(我方 HbTextLine.Start)` vs 语料 `cases[].lineStartOffsetsDip[k]`，**精确相等**（`!=` 即红）。
`R(v) = Math.Round(v, 6, MidpointRounding.AwayFromZero)`，口径出处 **`tests/parity/windows/tab-anchor/src/Program.cs:583`**（该字段的产地是同一文件 `:445` 的 `lineIndents.Add(R(line.Start));`）。
实现落点（**行号 = 改后/当前文件 `421fe394bea93fe2`**；`--tab-lines-oracle` 的比较区在改前文件里整体 **−33 行**）：

| 落点 | 行号 |
|---|---|
| 语料级探测（对齐 + 有无该字段 + 计数器声明） | `Program.cs:1294-1316` |
| 覆盖闸跳过 ⇒ NOINFO | `:1354-1355` |
| 格式化抛 ⇒ NOINFO | `:1387-1388` |
| **逐例/逐行比较块**（新列主体） | `:1495-1533` |
| 可点名计数器 + 对账 | `:1549-1556` |
| 红例喂给 `failures`（rc 承载） | `:1557-1560` |
| `R6()` / `StartTruthCount()` / `StartAlignmentOf()` | `:1582` / `:1585-1587` / `:1593-1603` |

### 3.2 只对 `TextAlignment=Left` 断言（**语料头钉死**）

对齐从语料头 `paragraphProperties.fixed` 的 `TextAlignment=` 字段**现读**（`StartAlignmentOf()`），**不硬编码**。实测原值：
`"TextAlignment=Left, TextWrapping=Wrap, LineHeight=0 (natural), Tabs=null, TextDecorations=null, TextMarkerProperties=null, AlwaysCollapsible=false"`
非 `Left` / 取不到 ⇒ 该例逐行 **NOINFO**，**不发明公式**（两极化见 §5.5）。

### 3.3 为何"只新增"：机器证

- 改前/改后**同一条命令**（`tab-anchor`）的日志：**469 行 → 907 行**。
- `diff <#21 原日志> <新日志>` ⇒ **`0` 条 `<`**（无删除/无修改）、**`438` 条 `>`**，且**每一行 `>` 都以 `TAB_LINES START` 开头**（例外数 = 0）。
- `grep -v '^TAB_LINES START' <新日志> | cmp - <#21 原日志>` ⇒ **逐字节相同**。
⇒ `结构=` / `位置=` / 家族分桶 / `合计` / `最大差` / `退出码=` 等**既有口径一个字节未动**。

### 3.4 退出码承载（**只加强，不放松**）

新列的红例被**追加进既有的 `failures` 列表**，因此：

- 走**同一张** `--known-red` 表、**同一个** `UNREGISTERED/KNOWN-RED` 通道、**同一个** rc 出口 ⇒ **不需要第二套口径**；
- **未登记红 ⇒ rc=1**（§5.1 实测：`退出码=1（未登记失败 88 / 失败共 88）`；§5.4 单例两极化：无表 `rc=1` / 有表 `rc=0`）；
- **没有**任何把未登记红压成 0 的动作；**没有**为了让门禁保持绿而把新红写成"已登记"（仓内 `known-red.txt` 与 `known-red.json` 我**一个字节都没碰**）；
- 全绿时既有 `退出码=` 行**逐字节不变**（因为它本来就算 0）。

### 3.5 仪器变更披露（纪律 40 / 纪律 35：读数是在**哪一版仪器**上取的）

| 件 | before sha16 | after sha16 | 字节 |
|---|---|---|---|
| `CoverageProbe/Program.cs` | `a8727a5bed6bf049` | **`421fe394bea93fe2`** | 108127 → 116496 |
| `CoverageProbe/bin/Release/PresentationCore.Tests.dll` | `c74a53c5f0ada1d0` | **`5baf3616723c4625`** | 137728 → 140800 |

构建：`dotnet build build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj -c Release` ⇒ **`0 个警告 0 个错误`**。
⇒ **§6 的 `arm-logs/tab-anchor.log` 是在新仪器 `421fe394bea93fe2` / `5baf3616723c4625` 上取的**；另外四支日志在**旧仪器**上取、**本轮未重取**（见 §7.3 的归因边界）。

---

## 4 · 计数器与逐例点名的对账（两个方向都闭合）

### 4.1 从日志反向重算（python，不看臂的汇总行）

| 量 | 从 436 条逐例 `START` 行求和 | 臂的汇总行 | 一致 |
|---|---|---|---|
| 红 | **0** | `红=0` | ✅ |
| 绿 | **421** | `绿=421` | ✅ |
| 判定行 | **421** | `判定行=421` | ✅ |
| NOINFO | **194** | `NOINFO=194` | ✅ |
| 逐例条数 | 436（= 288 判定 + 148 NOINFO） | `红例=0 NOINFO例=148` | ✅ |

### 4.2 从**语料**独立重算（不看臂）

`tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json`（sha16 **`0cebc0afd5142fbf`**）：

- `script=latin` = **288 例 / 421 行**；其中 `lineStartOffsetsDip` 非零 = **138 行 / 88 例**；
- 非 latin = **194 行**（116 hebrew + 32 arabic）—— **恰好等于**臂的 `NOINFO=194`；
- `lineStartOffsetsDip` 的取值域 = `{0:444, 24:131, 48:40}` ⇒ 非零 **171 行**（**全域**口径，含被覆盖闸跳过的 hebrew/arabic）。

⇒ **分母口径（纪律 39）成立**：本列的可判定集 = `latin` 的 **288 例 / 421 行 / 138 行非零**，**不是**整份语料的 436 例 / 615 行 / 171 行。**§5 的预测数一律按 421/138 写**。

### 4.3 真值自身的交叉校验（新列真值的阳性对照）

语料里另有一个**从未被任何臂读过**的逐行字段 `paragraphStartOffsetDip`。实测：

- `lineStartOffsetsDip[k] == lines[k].paragraphStartOffsetDip` 对**全部 615 行**成立；
- `lines[k].paragraphStartOffsetDip == cases[].paragraphIndentDip` 对**全部 615 行**成立。

⇒ 新列的真值有**三份互相独立的语料字段**互证（且三者域都是 `{0,24,48}`）⇒ "真值本身"不是单一来源的孤证。

---

## 5 · 反极性：**新列能红**（本件的唯一"不是恒绿"证据）

### 5.1 红证：`-p:HbShimSrc=<修前 shim 源>`

- 旋钮出处：`CoverageProbe.csproj:38`（`<HbShimSrc Condition="'$(HbShimSrc)' == ''">…/shims/PresentationCore.HbTextLine.cs</HbShimSrc>`）。
- 指向 `$HOME/w21a-pre/PresentationCore.HbTextLine.cs.pre`，sha16 **`fe1b7ed8fa3ed231`**（= `#19` 世代 shim，`Start => 0`）✅ 与预登记要求一致。
- **构建方式：原地**（见 §8.2 为什么**不能**用私有输出目录）。红臂产物 `PresentationCore.Tests.dll` = **`cd392d34332d8c96`**；输出目录里的 pc 仍是权威 `e7cabff9417ed380`。

**全语料读数**（日志 `$HOME/w22b-laneW22B/red/tab-anchor-red.log`，sha16 **`8889000a35689436`**，`rc=1`，70s）：

```
TAB_LINES START 红=138 绿=283 判定行=421 NOINFO=194 红例=88 NOINFO例=148 对齐=Left 量=R(我方 line.Start) 真值=lineStartOffsetsDip[k] R(v)=Round(v,6,AwayFromZero) 口径=Start≡ParagraphIndent
TAB_LINES START 对账 逐例求和 红=138 绿=283 NOINFO=194 ⇒ 与汇总一致
TAB_LINES 退出码=1（未登记失败 88 / 失败共 88 / 登记表 <未给>）
```

逐行点名前 3 条原样：

```
TAB_LINES START-RED B-indent-extra/lead-tab-a@w40@LTR@i24p24@default 行#0 Start 期望=24.000000 实得=0.000000 Δ=-24.000000
TAB_LINES START-RED B-indent-extra/lead-tab-a@w40@LTR@i24p24@default 行#1 Start 期望=24.000000 实得=0.000000 Δ=-24.000000
TAB_LINES START-RED B-indent-extra/lead-tab-a@w40@LTR@i24p24@tab0 行#0 Start 期望=24.000000 实得=0.000000 Δ=-24.000000
```

| 量 | 预登记 §2.2 预测 | 实测 | 判定 |
|---|---|---|---|
| 红行 | **138** | **138** | ✅ 逐位 |
| 红例 | （未写死；独立重算 = 88） | **88** | ✅ |
| 绿行 | — | 283 | — |
| 判定行 | 421 | 421 | ✅ |
| `rc` | 非 0 | **1** | ✅ |

**逐条核过**：`START-RED` 明细行数 = **138** = 汇总红行数；**全部 138 条的"实得"都是 `0.000000`**、Δ 全为 `−真值`（`−24` / `−48`）⇒ 与"修前 shim `Start => 0`"这一条机理**逐位吻合**，不是别的东西碰巧红了。

**决定性旁证（"只有 `Start` 变了"）**：同一次红跑的**既有列**与绿跑**逐字相同** ——
`TAB_LINES 合计 cases=436 判定过=288 结构败=0 不可比(缺字形)=148 其中 bidi 重排例=2；…`、`TAB_LINES 最大差=0.0000 @`。
⇒ 两版 shim 在**本臂既有射程内零差异**，新列是**唯一**动过的那一列。

### 5.2 复原（逐字节证明）

用真 shim 源原地重建后：

| 件 | 复原后 sha16 | 与备份 `cmp` |
|---|---|---|
| `bin/Release/PresentationCore.Tests.dll` | **`5baf3616723c4625`** | ✅ 逐字节相同 |
| `bin/Release/PresentationCore.Tests.pdb` | **`ec0dc3c205e2a4c3`** | ✅ 逐字节相同 |
| `bin/Release/PresentationCore.dll` | **`e7cabff9417ed380`** | ✅ 逐字节相同（仍是权威件） |

**临时态零残留**：私有输出目录（`redbin/`、`redobj/`）与两份临时语料、临时登记表**全部在 `$HOME/w22b-laneW22B/` 下**，**仓内不新增任何文件**。

### 5.3 绿证（本节即"新列在修后是绿"）：`tab-anchor` 全语料

```
TAB_LINES START 红=0 绿=421 判定行=421 NOINFO=194 红例=0 NOINFO例=148 对齐=Left 量=R(我方 line.Start) 真值=lineStartOffsetsDip[k] R(v)=Round(v,6,AwayFromZero) 口径=Start≡ParagraphIndent
TAB_LINES START 对账 逐例求和 红=0 绿=421 NOINFO=194 ⇒ 与汇总一致
```
⇒ **修后全绿 421/421、Δ 无一条非零**；**没有**触发预登记 §6 停条件 #3（"新列红 ⇒ 停"）。

### 5.4 登记路径两极化（**临时**表，仓内表未碰）

用 **2 例**小语料（`$HOME/w22b-laneW22B/tiny.json`，取自真语料：1 例 `lineStartOffsetsDip=[24,24]` + 1 例 `=[0,0,0]`）在**红臂**上跑，登记表写在 `$HOME`：

| 极性 | 输出 | 判定 |
|---|---|---|
| **无** `--known-red` | `TAB_LINES UNREGISTERED B-indent-extra/lead-tab-a@w40@LTR@i24p24@default :: 行#0 Start 期望=24.000000 实得=0.000000 Δ=-24.000000；行#1 …` + `TAB_LINES 退出码=1（未登记失败 1 / 失败共 1 / 登记表 <未给>）` | ✅ 未登记红**抬 rc** |
| **有** `--known-red`（该例已登记） | `TAB_LINES KNOWN-RED …（已登记，不改退出码）` + `TAB_LINES 退出码=0（未登记失败 0 / 失败共 1 / …）` | ✅ 登记路径**通** |

⇒ 新红是**可登记的**（不是硬失败），主控若裁"保留红"有路可走；**我没有替主控登记任何东西**。
同一小语料上**零缩进对照例**（`A-anchor/lat-a-t-b@w96@LTR@i0@default`）在红臂上仍是 `行=3 红=0 绿=3` ⇒ 新列**不是整片红**。

### 5.5 `TextAlignment≠Left ⇒ NOINFO` 两极化（"不许发明公式"的机器证）

把 `tiny.json` 的语料头 `paragraphProperties.fixed` 由 `TextAlignment=Left` 改成 `TextAlignment=Right`（其余一字不改），**修后臂**上跑：

```
TAB_LINES START B-indent-extra/lead-tab-a@w40@LTR@i24p24@default 行=2 NOINFO=对齐非Left(Right)
TAB_LINES START A-anchor/lat-a-t-b@w96@LTR@i0@default 行=3 NOINFO=对齐非Left(Right)
TAB_LINES START 红=0 绿=0 判定行=0 NOINFO=5 红例=0 NOINFO例=2 对齐=Right 量=… 口径=Start≡ParagraphIndent
```
⇒ **判定行 0、全部 NOINFO**，`红=0` **不是**"通过" ⇒ 覆盖边界外**不会**产生假绿。

### 5.6 新列不会退化成"恒绿"：三态都取到了读数

| 态 | 判定行 | 红 | 绿 | NOINFO | 含义 |
|---|---|---|---|---|---|
| 修后 shim（真语料） | 421 | 0 | 421 | 194 | 正常绿 |
| 修前 shim（真语料） | 421 | **138** | 283 | 194 | **能红** |
| `TextAlignment=Right`（小语料） | **0** | 0 | 0 | 5 | **能 NOINFO**（不是绿） |
| 失效构建（§8.2，小语料） | **0** | 0 | 0 | 5 | **能 NOINFO**（不是绿） |

---

## 6 · 既有判据行逐字不动 + 五臂重取

### 6.1 重取（按 `arm-logs/README.md`：先落临时目录，再 **`ln -f`**；**未** `cp`、**未** `ln -s`）

```bash
ln -f $HOME/w22b-laneW22B/logs/final/tab-anchor.log build/MilBridge/arm-logs/tab-anchor.log
```

| 项 | 改前 | 改后 |
|---|---|---|
| `arm-logs/tab-anchor.log` inode / links | `5141091` / 2 | **`5142560` / 2** |
| 字节 | 43563 | **78715** |
| mtime | 18:52:47 | **19:51:33**（≥ shim mtime `18:31:48` ⇒ 弱配对判据有效） |
| sha16 | `99d72b385fe23a90` | **`1a5bc7181d0155c3`** |

**只重链了 `tab-anchor` 一支**。`tab-zero`/`tab-rtl` 我**重跑了并逐字节复现**（§2.2），但**没有触碰** `arm-logs/` 里的那两个文件（内容相同 ⇒ 无需重链）⇒ 它们的 inode、mtime、sha16 **三位都没动**。

### 6.2 diff 证据（新日志 vs `#21` 原日志 `$HOME/wfp-runs/arms21/tab-anchor.log`）

```
行数: #21=469   新(剔掉新增行)=469   新(全)=907
✅ 剔掉新增行后与 #21 逐字节相同（cmp 无输出）
diff 行数: 0 条 '<'（删除/修改），438 条 '>'（新增）
新增行里不以 'TAB_LINES START' 开头的：0 条
```

⇒ **既有判据行逐字不动**（不是"看起来差不多"，是 `cmp` 级别）。

### 6.3 四支无关臂：逐字节不变（内容 + mtime + inode 三重）

| 臂日志 | 内容 vs `#21` 原日志 | inode 是否被触碰 | sha16 |
|---|---|---|---|
| `tab-zero.log` | `cmp` 相同 | 未触碰（`5139804`，mtime 18:51:49 不变） | `b9d81590f3fcd800` |
| `tab-rtl.log` | `cmp` 相同 | 未触碰（`5141093`，mtime 18:52:53 不变） | `419e8aaa9c72a9a0` |
| `textlineproto.log` | `cmp` 相同 | 未触碰（`5141094`，mtime 18:53:05 不变） | `4bceceeed570ba70` |
| `tline.log` | `cmp` 相同 | 未触碰（`5141090`，mtime 18:51:16 不变） | `de605bf708dcdb5a` |

五支终局 sha16：`tab-zero b9d81590f3fcd800`｜`tab-anchor 1a5bc7181d0155c3`｜`tab-rtl 419e8aaa9c72a9a0`｜`textlineproto 4bceceeed570ba70`｜`tline de605bf708dcdb5a`。

---

## 7 · 复算：门禁 / 九位 / `inputs_fp` / 无关臂

### 7.1 门禁（终局）

```
$ bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs   # GATE_RC=0
TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#21 tree_gen=same saved_shim=76089e1de586ac91 gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2 outdir=/home/links-dev/wfp-runs/tline-gate-20260916-195254
GATE_REASON=all-as-registered
```

⇒ **`PASS`**、`generation=#21`、**`tree_gen=same`**、**`drift=0 gone=0 unregistered=0`**、`rc=0`，与 `#21` 基线**逐字相同**。
§6 停条件 #2 未触发（**没有**任何 drift/gone/unregistered）；预登记 §2.3 的"`CoverageProbe` 不在世代绑定三项内 ⇒ 不需要重钉"**成立**（`known-red.json` 未动）。
门禁对 tab 臂的读数里，`真值文件=tab-anchor-oracle.json  TAB_LINES 退出码=0` ⇒ **新列没有干扰门禁的解析**。

### 7.2 九位 / `inputs_fp`（波后复算，逐位不变）

与 §1 表**逐位相同**（`bridge d567c26f197ec1e3`、`pc e7cabff9417ed380`、`pf 2fb1a896f8277647`、`windowsbase 1114a28ec5a03ab7`、`provider 9aa0d744802aaa31`、`win32shim 0098234982391bbf`、`wic_shim 03b67fbcd7c385b6`、`hbtextline 76089e1de586ac91`、`dwf 0ed422ef2dd46445`）；`inputs_fp` = `a2b74537427ecc4a987edbe52a59c5d01d4817d54de58f445833c33dfb0e78e0`。
⇒ **§5 位移预测表：零位移**（`build/MilBridge/tests/**` 不在 `inputs_fp` 覆盖面内，与预登记一致）。

### 7.3 归因边界（**不许读错**）

四支无关臂的日志**本轮未重取**，因此"四支逐字节不变"的**强形态**（"在新仪器上重跑仍逐字节相同"）**只对 `tab-zero`/`tab-rtl` 成立**（§2.2 我确实在新旧仪器上都跑了、且相同：改前用旧仪器、改后用新仪器，两者 sha16 都是 `b9d81590f3fcd800` / `419e8aaa9c72a9a0`）。
`textlineproto` 与 `tline` **只在 `arm-logs/` 里保持原样**（未重跑）⇒ 我给的证据是"**文件未被触碰**"，**不是**"用新仪器重跑仍相同"。**这两句不许混读。**

---

## 8 · 同族字段普查：**还有哪些真值躺在语料里没人看**

### 8.1 逐字段实测（"语料里有吗？本臂比较了吗？"）

"本臂比较了吗"= `build/MilBridge/tests/CoverageProbe/Program.cs` 的 `--tab-lines-oracle` 路径里是否**参与判定**（不是只被 `FAILCASE` 打印）。
语料 = `tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json`（`0cebc0afd5142fbf`，436 例 / 615 行）。
**行号 = 改后/当前文件 `421fe394bea93fe2`**（b34 `--layout` 臂的行号不受我的改动影响；`--tab-lines-oracle` 的比较区比改前 **+33 行**）。

| 真值字段 | 语料里有？ | **本臂比较？** | 行号级证据 | 我方可取读数的成员 | 真值域（判别力） |
|---|---|---|---|---|---|
| `width` | ✅ 615/615，null 0 | **✅ 比** | `Program.cs:1400-1402` | `Width` | 连续、有判别力 |
| `trailingWhitespaceLength` | ✅ 615/615 | **✅ 比** | `Program.cs:1403-1404` | `TrailingWhitespaceLength` | `{0:179,1:436}` |
| `newlineLength` | ✅ 615/615 | **✅ 比** | `Program.cs:1405-1406` | `NewlineLength` | `{0:179,1:436}` |
| `perChar[].xFromLeftDip` | ✅ | **✅ 比** | `Program.cs:1456-1463` | `GetTextBounds(i,1)` | 连续 |
| **`lineStartOffsetsDip`** | ✅ **436/436** | **✅ 本波新增** | 比较块 `:1495-1533`；`R6()` `:1582`；`StartTruthCount()` `:1585` | `Start` | `{0:444,24:131,48:40}`（138 latin 非零） |
| `startChar`（**逐行**，不是逐例） | ✅ 615/615 | **❌ 没比** | 唯一命中 `:1032` —— 那是 **b34 `--layout` 臂**，**不在本径** | 无公开成员（帧要扫描/加内部口） | `{0:436,1:87,2:69,3:23}`（**全域非零 179**） |
| `height` | ✅ 615/615 | **❌ 没比** | `grep -c '"height"'` = **0** | `Height`（shim `:3361`） | **恒 27.596667** ⇒ **零判别力** |
| `baseline` | ✅ 615/615 | **❌ 没比** | `grep -c '"baseline"'` = **0** | `Baseline`（`:3359`） | **恒 22.12** ⇒ **零判别力** |
| `hasOverflowed` | ✅ 615/615 | **❌ 没比** | `grep -c '"hasOverflowed"'` = **0** | `HasOverflowed`（`:3466`） | `{False:593, True:22}` ⇒ 有判别力 |
| `dependentLength` | ✅ 615/615 | **❌ 没比** | `grep -c '"dependentLength"'` = **0** | `DependentLength`（`:3440`） | `{0:436,1:80,2:79,3:20}` |
| `widthIncludingTrailingWhitespace` | ✅ 615/615 | **❌ 没比** | `grep -c …` = **0** | `WidthIncludingTrailingWhitespace`（`:3411`） | 与 `width` **不等**（多例） |
| `inkRightDip` | ✅ 615/615 | **❌ 没比** | `grep -c '"inkRightDip"'` = **0** | **无同名成员**（只有 `Extent`=墨迹**高**） | 连续（真机臂 `Program.cs:567` 落盘） |
| `paragraphStartOffsetDip` | ✅ 615/615 | **❌ 没比** | `grep -c …` = **0** | 无同名成员 | `{0:444,24:131,48:40}` —— **与新列真值逐行恒等**（§4.3） |
| `endCharExclusive` / `lengthWithNewline` | ✅ 615/615 | **❌ 没比** | `:1021` 只在 b34 臂 | 无同名成员（可由 `Length` 推） | 多个值 |
| `lineCount`（逐例） | ✅ 436/436 | **❌ 没比** | `grep -c '"lineCount"'` = **0** | `lines.Count`（**唾手可得**） | `{1:329,2:50,3:42,4:15}` |
| `stoppedEarlyBecauseLineLengthWasZero`（逐例） | ✅ 436/436 | **❌ 没比** | `grep -c …` = **0** | `Length<=0`（**唾手可得**） | **恒 False** ⇒ 零判别力 |
| `tabCount`（逐例） | ✅ 436/436 | **❌ 没比** | `grep -c …` = **0** | 需自己数 | `{0:50,1:324,2:62}` |
| `lineText` | ✅ 615/615 | **❌ 不比**（只**打印**） | Q3 clamp 条件 `:1416`、FAILCASE 转储 `:1472` | （字符串，仅诊断用） | — |

### 8.2 ⇒ **"还有哪些真值躺在语料里没人看"清单（按价值排序）**

1. **`lineStartOffsetsDip` —— 本波已收（这条正是 `D-G1`）**。
2. **`startChar`（帧，179 行非零 / latin 133 行）** —— **`D-T6-b` 的判据真值**，现在仍**零射程**（`PcLineOracle` 也不在门禁里）。⚠️ 见 §9.3 的数字更正。
3. **`hasOverflowed`（22 行 True）** —— 真值在、我方有 `HasOverflowed` 成员、**从没人比**。`D-O1` 刚动过这条实现，**却没有真值判据盯它**。
4. **`dependentLength`（179 行非零）/ `widthIncludingTrailingWhitespace` / `inkRightDip`** —— 真值在、我方有/可推、**从没人比**（`inkRightDip` 还缺成员，要先定口径）。
5. **`lineCount`（42 例 ≥3 行）** —— 真值在、**比较成本几乎为 0**（`lines.Count`），**从没人比**（不过 `结构=` 实际上等价地覆盖了它）。
6. **`height` / `baseline` / `stoppedEarlyBecauseLineLengthWasZero`** —— 真值在，但**恒为常数** ⇒ 加列是**零判别力**的"假判据"，**不建议**当红判据（登记时要说清）。
7. `paragraphStartOffsetDip` —— 与新列真值逐行恒等 ⇒ 可当**交叉校验列**（不是新信息，但能防"真值取错字段"）。

---

## 9 · 我推翻 / 更正的话（含**我自己的**仪器事故）

### 9.1 预登记 §2.1 的"它实际比较的字段"清单**不成立**（推翻）

原文并列了 `lineText` / `startChar` / `maxWidth` / `modifierStart` / `visibleText`。实测：

- `startChar` 在 `Program.cs` 里**只有 1 处命中**（`:1032`），属于 **b34 `--layout` 臂**的 `perChar` 遍历，**不在 `--tab-lines-oracle` 路径**；
- `maxWidth` / `modifierStart` / `visibleText` 只在 **`:1076` / `:1164` / `:1165`**，同样属于 b34 臂；
- `lineText` 在本径只被**打印**（`:1383` 的 Q3 clamp 条件、`:1439` 的 FAILCASE 转储），**不参与判定**。
⇒ 本径**实际参与判定**的只有 4 个：`width`、`trailingWhitespaceLength`、`newlineLength`、`perChar[].xFromLeftDip`（§8.1 行号）。
（"零引用 `lineStartOffsetsDip`/`TextLine.Start`"那一条**对**，`D-G1` 的结论不受影响。）

### 9.2 **我自己的仪器事故**：`-p:BaseOutputPath`/`-p:BaseIntermediateOutputPath` **不能**用来隔离红构建（新登记的隐患）

我原想"把红臂建到私有输出目录，免得动真臂"，于是加了这两个旋钮。**结果那趟构建把一份陈旧 `pc` 拷进了输出目录**：

- 私有输出目录里的 `PresentationCore.dll` = **`9adac6b8d8e285c3`**（4188672 B，mtime **2026-09-15 10:58:33**），与 `build/MilBridge/tests/CoverageProbe/bin/Debug/PresentationCore.dll` **`cmp` 逐字节相同**；
- 权威件 = **`e7cabff9417ed380`**（4196864 B）⇒ **不是**权威件，是**上一代（`#18`）的陈旧副本**；
- 后果：那趟 **436 例全部** `抛 DllNotFoundException`（288 latin 例无一判定）⇒ `判定过=0`。
- **机制锚（逐字证据）**：两次构建各自的 RAR 缓存记的解析路径不同 ——
  - 真构建 `obj/Release/CoverageProbe.csproj.AssemblyReference.cache`：`…/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`（= `HintPath`，权威）；
  - 私有 obj 构建 `$HOME/w22b-laneW22B/redobj/Release/CoverageProbe.csproj.AssemblyReference.cache`：`…/build/MilBridge/tests/CoverageProbe/bin/Debug/PresentationCore.dll`（= 本工程 `bin/Debug` 里的陈旧副本）。
  - **RAR 为什么改选它 ⇒ `NOINFO`（未归因）**，但**事实**由上面两份缓存逐字证明、并由 `cmp` 与 sha16 双证。
- **它同时是一条"好消息"**：那趟**没有**给出假绿 —— 新列报的是 `红=0 绿=0 判定行=0 NOINFO=615`（日志 `$HOME/w22b-laneW22B/red/degenerate-private-obj.log`，sha16 `d747a5ac77d18075`）⇒ 判据在"根本判不了"时**如实 NOINFO**，不冒充通过（见 §5.6）。
- **建议主控登记**（我不写主控的文件）：① "私有 obj/out 重定向下 `CoverageProbe` 的 `PresentationCore` 引用会解析到本工程 `bin/Debug` 的陈旧副本"是 `D-R8` 的同族隐患，且**没有任何判据盯 `bin/Debug` 里的 pc 副本**（与 P4/D-A2 的副本盲区一致）；② 纪律候选：**反极性/红证的构建必须原地做**，或**必须显式校验输出目录里 `pc` 的 sha16 == 权威**（我这趟若没查，就会拿 `DllNotFound` 当"新列没红"或拿 615 NOINFO 当"绿"）。

### 9.3 `startChar` ≠ `lineStartOffsetsDip`：预登记 §3.2 的折算数**用错了字段**（更正，供 W22C 用）

§3.2 写："宽松档腿每行 `startChar>0` 必红（**≥171 行**口径下按 latin 折算 = **138 行**）"。但 `startChar` 是**另一个字段**，其统计独立算出为：

| 字段 | 全域非零行 /615 | latin 非零行 /421 | latin 含非零的例 /288 |
|---|---|---|---|
| `lineStartOffsetsDip`（本波新列真值） | **171** | **138** | **88** |
| **`startChar`**（P3 的帧真值） | **179** | **133** | **80** |

⇒ P3 若要写预测数，**只能用 179 / 133 / 80**；171/138/88 是 `Start` 那一列的口径，**搬过去就是错的分母**（这正是纪律 39 要防的那类错）。**我没有替 P3 取任何读数**，只更正数字。

### 9.4 一条正面的加证（不是推翻，是加固）

新列真值有三份语料字段互证（`lineStartOffsetsDip` ≡ `paragraphStartOffsetDip` ≡ `paragraphIndentDip`，**全部 615 行**）—— 见 §4.3。

---

## 10 · 未测清单（`NOINFO`，不许读成"已验证"）

1. **RTL 半边未行使**：新列的 138 个非零行**全部在 `latin` 组**，而 latin 的 421 行**恰好全 LTR**；语料里那 33 个 RTL 非零行全在 `C-rtl-indent`（Hebrew）⇒ 被**覆盖闸（面缺字形）**跳过 ⇒ 本列对它们只报 `NOINFO`。**不许**写成"判据覆盖了 RTL 或 RTL 也绿"。
2. **`TextAlignment` 除 `Left`/`Right` 外的取值未测**（`Center`/`Justify`）：语料里不存在这种档；我只做了 `Left→Right` 的两极化（§5.5）。`Justify`/`Center` 走同一条 `!= "Left" ⇒ NOINFO` 分支，但**没有实测读数**。
3. **`行数不符` 的 NOINFO 分支未行使**：真语料上 `len(lineStartOffsetsDip) == len(lines)` 对 436/436 成立，我方 `结构败=0` ⇒ 该分支**只有代码、无读数**。
4. **`textlineproto` / `tline` 未用新仪器重跑**（§7.3）⇒ 我对它们只有"文件未被触碰"的证据，没有"重跑仍相同"的读数。
5. **私有 obj 重定向下 RAR 改选陈旧副本的机制未归因**（§9.2）—— 事实已证，机理 `NOINFO`。
6. **新列的"产品侧"射程未测**：本臂直调 `HbTextLineFactory.FormatParagraph`，**不经 PC 的 `TextFormatter`/`HbTextFrame`** ⇒ 它证的是"**源直调**这一层的 `Start` 正确"，**不是**"应用路径上的 `Start` 正确"。后者由 `#21` 的 `PcLineOracle`/`verify-all` 第 11 步承担，**不在本件射程**。
7. **`GetTextBounds` 的帧语义（`D-T6-b`）本件一点没碰**：按预登记 §3.6，本波默认"只登记不落地"，我**未修改 `build/shims/**`**。

---

## 11 · 读数表

| 项 | 值 |
|---|---|
| lane | **W22B** |
| 起止（本地） | 2026-09-16 19:40:49 → 19:54 +0800 |
| kernel | `6.8.0-138-generic` |
| `nproc` | 3 |
| loadavg（开工 / 收尾） | `3.30 0.84 0.42` / `2.01 2.85 2.05` |
| `MemAvailable`（开工 / 收尾） | `3467412 kB` / `2747740 kB`（3 核机、另有两条车道在跑） |
| `DISPLAY=:97` | **UP**（未自起 Xvfb） |
| `pc` sha16（开工前 / 收尾） | `e7cabff9417ed380` / `e7cabff9417ed380` |
| `hbtextline` sha16（开工前 / 收尾） | `76089e1de586ac91` / `76089e1de586ac91` |
| 仪器 `Program.cs`（before → after） | `a8727a5bed6bf049` → **`421fe394bea93fe2`** |
| 仪器 `PresentationCore.Tests.dll`（before → after） | `c74a53c5f0ada1d0` → **`5baf3616723c4625`** |
| 五臂 `arm-logs` sha16（终局） | `tab-zero b9d81590f3fcd800`｜**`tab-anchor 1a5bc7181d0155c3`**｜`tab-rtl 419e8aaa9c72a9a0`｜`textlineproto 4bceceeed570ba70`｜`tline de605bf708dcdb5a` |
| 门禁 | `TLINE_GATE=PASS … generation=#21 tree_gen=same … drift=0 gone=0 unregistered=0`、`GATE_RC=0` |
| 九位 / `inputs_fp` | **逐位不变** |
| 未触碰（主控写域） | `known-red.json`、`tline-gate.sh`、`verify-all.sh`、`build/shims/**`、`pc-line-step.sh`、`build/PresentationCore.Linux/**`、`CoverageProbe/known-red.txt`(`e37603a8825d85ae`) |

### 11.2 ⚠️ 一条**不是我的**漂移（如实披露，供主控归因）

我按"未触碰"清单复算未触碰件的 sha16 时发现：**`verify-all.sh` 现为 `279b958dda238447`（size 12120，mtime 2026-09-16 **18:56:52**）**，而 `#21` 的记录是 **`a68823631e8f8919`**（见 `W19A-report.md` 的仪器清单与 `ACCEPTANCE-BASELINE.md` 的 `#19` 段）。

- **不是本波造成的**：`find … -newermt '2026-09-16 19:40'` 对 `verify-all.sh`/`known-red.json`/`tline-gate.sh`/`build/shims/**` **零命中**；且它的 mtime `18:56:52` **早于**我开工的 `19:40:49`。
- **但它落在 `#21` 冻结点（19:03:17）之前 6 分钟** ⇒ 要么 `#21` 的基线/报告漏记了它，要么它在 `#21` 收尾时被改而文档未跟。
- **我没有跑 `verify-all`**（不在本件射程），因此**不判断**它改了什么；只报告"**文档记录的 sha ≠ 现场 sha**"这一事实。⇒ 建议主控核：`verify-all.sh` 的当前 sha 是否应写进 `#22` 的基线表头。

### 11.1 读数 artifact 索引（全在 `$HOME`，仓内只多 `Program.cs` 改动与本报告）

| artifact | sha16 | 说明 |
|---|---|---|
| `$HOME/w22b-laneW22B/logs/before/tab-{zero,anchor,rtl}.log` | `b9d81590f3fcd800` / `99d72b385fe23a90` / `419e8aaa9c72a9a0` | 改前基线（复现 `#21`） |
| `$HOME/w22b-laneW22B/logs/final/tab-anchor.log` | `1a5bc7181d0155c3` | 新仪器绿证（= `arm-logs/tab-anchor.log`，硬链接） |
| `$HOME/w22b-laneW22B/red/tab-anchor-red.log` | `8889000a35689436` | **反极性红 138** |
| `$HOME/w22b-laneW22B/red/degenerate-private-obj.log` | `d747a5ac77d18075` | §9.2 事故证物（全 NOINFO，不是绿） |
| `$HOME/w22b-laneW22B/gate/gate-final.out` | — | 终局门禁 stdout |
| `$HOME/w22b-laneW22B/tiny.json` / `tiny-right.json` | — | 2 例小语料 / 对齐改 `Right` |
| `$HOME/w22b-laneW22B/backup/Program.cs.before`、`backup/binRelease/*` | `a8727a5bed6bf049` 等 | 留档（`cmp` 已证复原） |
