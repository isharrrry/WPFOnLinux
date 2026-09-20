# W21A 报告 —— `#21` §1 **P1**：`D-T6-c`（真机 `TextLine.Start` 的法律）判据 + 落地

> lane = **W21A** ｜ 2026-09-16 18:22 → 18:46 +0800 ｜ host `linksdev-VirtualBox` ｜ kernel `6.8.0-138-generic` ｜ `nproc=3` ｜ display `:97`（`xdpyinfo` = **UP**，未自起 Xvfb）
> 仓库根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux` ｜ SDK 经 `export PATH="$HOME/.dotnet:$PATH"` 可见（`dotnet --version` = `10.0.111`）
> 读数期间 `loadavg` / `MemAvailable` 逐趟逐条列在 §8。所有 `sha256` 前缀 = **16 位小写十六进制**（纪律：纪律 32 的读数责任人 = 本报告全篇 `lane=W21A`）。

---

## ① 一句话判决

**判据建成、红证 (a) 与绿证都拿到、修法落地、红证 (b) 也红；本波三条读数与主控独立重算的修正口径「138 行 / 88 例」逐位吻合，`Start` 已从「只印不判」变成「能决定红、能进出口码」。**

| 读数 | 值 |
|---|---|
| **红证 (a)**（修前 `pc` + 新判据） | `PCLINE START 腿=汇总(B) 红=`**`138`**` 绿=283 判定行=421 NOINFO=0 红例=`**`88`**` Start-only红例=24 未比真值行=0 最大Δ=24.000000` ｜ `rc=1` |
| **绿证**（修后 `pc`） | `红=`**`0`**` 绿=`**`421`**` 判定行=421 NOINFO=0 最大Δ=`**`0.000000`** ｜ `rc=1`（残留全是 `D-T6`/`@tab0` 族，与本件无关） |
| **红证 (b)**（临时 `Start = Indent`） | `红=`**`222`**` 绿=199 判定行=421 红例=`**`148`**` ｜ `rc=1`；随后**逐字节复原**（`cmp` 通过，`pc` 复算回 `e7cabff9417ed380`） |
| 工具链位移 | `hbtextline` `fe1b7ed8fa3ed231` → **`76089e1de586ac91`** ｜ `pc` `f4a454c8fe69cdfe` → **`e7cabff9417ed380`** |

**§5 表外位移：无。** 但表内**有一条预测未兑现**（`pf` 预测"变"、实测**未变**）—— 见 §7，那是主控波尾 `close-wave` 的步骤，不在本车道射程。

---

## ② 开工前：九位重算 vs `#19` —— **逐位一致**

`#19` 权威表头（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）sha16 = `f5d8a6f1cdf49635`（本车道实测 ✓）；预登记 `docs/WAVE21-PREREGISTRATION.md` sha16 = `9d1e2dddda5b24e8`（实测 ✓，与任务书给的一致）。

| 位 | `#19` 表头 | 本车道开工前重算 | 一致 |
|---|---|---|---|
| `bridge` | `d567c26f197ec1e3`（4,987,840 B） | `d567c26f197ec1e3` | ✅ |
| `pc` | `f4a454c8fe69cdfe`（4,196,864 B） | `f4a454c8fe69cdfe`（4,196,864 B） | ✅ |
| `pf` | `bd4e28e6a6f8b0e5` | `bd4e28e6a6f8b0e5` | ✅ |
| `windowsbase` | `1114a28ec5a03ab7` | `1114a28ec5a03ab7` | ✅ |
| `provider` | `9aa0d744802aaa31` | `9aa0d744802aaa31` | ✅ |
| `win32shim` | `0098234982391bbf` | `0098234982391bbf` | ✅ |
| `wic_shim` | `03b67fbcd7c385b6` | `03b67fbcd7c385b6` | ✅ |
| `hbtextline` | `fe1b7ed8fa3ed231`（278,692 B） | `fe1b7ed8fa3ed231`（278,692 B） | ✅ |
| `dwf` | `0ed422ef2dd46445` | `0ed422ef2dd46445` | ✅ |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | `b6acdba4f01599d8`（`BRIDGE_SRC_N=78`） | ✅ |

命令（`bridge`/`pc`/`provider`/`win32shim`/`wic_shim` 取**部署目录** `/home/links-dev/wfp-runs/w19-gate2/`，与 `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh:626-665` 同一取值面）：

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
for f in /home/links-dev/wfp-runs/w19-gate2/{wpfgfx_cor3.so,PresentationCore.dll,DirectWrite.Linux.Provider.dll,libwpfwin32.so,libwpfwic.so} \
         build/PresentationFramework.Linux/bin/Debug/PresentationFramework.dll \
         build/WindowsBase.Linux/bin/Debug/WindowsBase.dll \
         build/shims/PresentationCore.HbTextLine.cs \
         build/DirectWriteForwarder.Linux/bin/Debug/DirectWriteForwarder.dll; do
  printf '%s %s %s\n' "$(sha256sum "$f"|cut -c1-16)" "$(stat -c %s "$f")" "$f"; done
bash build/bridge-src-fp.sh
```
⇒ **九位 + 桥源指纹全部与 `#19` 逐位一致 ⇒ 树未被别人动过，可以开工**（未触发"停并报告"）。

### ②b 我**独立复核**了主控的三条腿（可复核，未重做其取证）

主控要求"可以复核但不要重做"。我复核的是**数**，不是它的结论：

| 断言 | 主控 | 本车道重算（`python3` 直读语料） | 一致 |
|---|---|---|---|
| 语料行数 / 例数 | 615 / 436 | 615 / 436 | ✅ |
| `Start == ParagraphIndent` | 615/615 | **615/615** | ✅ |
| `Start == Indent` | 337/615 | **337/615** | ✅ |
| `PI=0 而 Start≠0` / `PI≠0 而 Start==0` | 0 / 0 | **0 / 0** | ✅ |
| 取值域 | `{0:444, 24:131, 48:40}` | **同**（与 `PI∈{0,24,48}` **双射**） | ✅ |
| `lineStartOffsetsDip[k]` == `lines[k].paragraphStartOffsetDip` | 615/615 | **615/615** | ✅ |
| `flowDirection` 逐例变量 | LTR 318 / RTL 118 | **LTR 318 / RTL 118** | ✅ |
| 非零值行的方向分布 | LTR 138 / RTL 33 | **LTR 138 / RTL 33** | ✅ |

---

## ③ 判据改动（**只新增一列**）

### 3.1 文件 sha16 before → after

| 文件 | before | after | 备注 |
|---|---|---|---|
| `build/MilBridge/tests/PcLineOracle/Program.cs` | **`19f9e7e78e9bb5c7`**（90,087 B，mtime 16:24:47） | **`a787a9db23c3302c`**（113,209 B，mtime 18:31:09） | 纪律 35：**本报告所有读数都取在 `a787a9db23c3302c` 这一版仪器上** |
| 臂产物 `bin/Release/PresentationCore.Tests.dll` | `d3ae846a9a8b4717` | **`c76bdf2254b9a00e`** | `dotnet build … -c Release -m:1` ⇒ **`error CS = 0`、`0 警告 0 错误`** |

> 主控 §③ 点名的"改动前 `19f9e7e78e9bb5c7`"实测一致；更早的 `a46e5e046583f69a` 是 `#19` 冻结时那一版（W19B 产出）。

**未改动**：`build/MilBridge/tests/PcLineOracle/known-red.txt` = `89324f1f643167e5`（17,501 B，155 行 / 136 条，重钉归主控）；语料 `tab-anchor-raw.json` = `88559d670f1bb955`（1,196,289 B）**只读**。

### 3.2 新增列的确切语义

**新列 = 逐行 `R(我方 TextLine.Start)` vs 语料 `lineStartOffsetsDip[k]`**，其中 `R(v) = Math.Round(v, 6, MidpointRounding.AwayFromZero)`（口径出处 `tests/parity/windows/tab-anchor/src/Program.cs:583`，与真值落盘**同一把尺子**）。真值出处 = 同文件 `:445` 的 `lineIndents.Add(R(line.Start));`。

新输出的判据行（`key=value` 空格分隔，**可被机器 grep**）：

```
PCLINE START 腿=B 红=<n> 绿=<m> 判定行=<N> NOINFO=<k> 红例=<c> Start-only红例=<s> 未比真值行=<u> 最大Δ=<v> @<id>
PCLINE LEG=B Start 口径 断言=**只对 TextAlignment=Left** …
PCLINE START <id> 行#<k> Start 我方=… 真值=… Δ=…          ← 逐例可归因（每个失配一行）
PCLINE START-CASE <id> 本列=PASS|FAIL 比过=<N> 行 红行=<r> 绿行=<g> 真值行数=<t>   ← 逐例卷起，**红行数 == 上面的 START 行数**（可对账）
PCLINE START-NOINFO <id> 原因=…                              ← 未断言例（既不算红也不算绿）
PCLINE START-RC 腿=B 未登记失败=<n> 其中点名Start列=<m> ⇒ rc≠0…
PCLINE START 腿=汇总(B) …                                    ← 汇总只取腿 B（与既有各列同一取舍）
```
外加 `StartCol :` 两行（**在拿任何读数之前**把"能不能断言"钉死）与 `lane(edits) = W21A` 一行。

### 3.3 四条**有意**的口径决定（都不是遗漏）

1. **断言边界 = 只对 `TextAlignment=Left`**。真法律 `Start == ParagraphIndent` 只在 Left 下成立（`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/TextMetrics.cs:255-263` 的 `default:` 分支）。本语料把对齐**钉死在语料头**（`paragraphProperties.fixed` = `"TextAlignment=Left, TextWrapping=Wrap, …"`，**不是逐例变量**；436 例的 key 并集里没有 `textAlignment`）⇒ 臂解析该串，**只有明确写着 `TextAlignment=Left` 才断言**；声明 `Right`/`Center` 或**压根没有该字段** ⇒ **整列 `NOINFO` + `rc=2`**，**绝不发明** `Right`（`paragraphWidth − _textWidthAtTrailing`）/`Center`（`(paragraphWidth + _textStart − _textWidthAtTrailing)/2`）的公式——本语料零覆盖 = 无真值。另留逐例 `textAlignment` 覆盖入口（将来语料变成逐例变量时只排除该例）。
2. **判据 = 精确相等**（`R(我方) == 真值`，**不**用既有列的 `Tol=0.05`）。理由：两边是**同一个物理量的同一个取整口径**，且真法律是**恒等式**不是近似 ⇒ 用 0.05 会让"差 0.04"读成绿。为便于人核，另印 `最大Δ`。
3. **比较独立于 `structOk`** —— 这是**实测逼出来的**，不是设计洁癖：第一版把新列放进既有的 `if (structOk) { … }` 逐行块，实测**只有 355/615 行被比过**（行划分不一致的整例不进那个块）。而 `Start` 是**段落级常量**（`= ParagraphIndent`，**每一行都相同**），与我方怎么切行**无关** ⇒ 只要交回了第 k 行，第 k 行的 `Start` 就可比。改独立后 `判定行=421`、`未比真值行=0`（**覆盖完整**）。
4. **bidi 重排例不跳**。既有「逐字符 x」列对 `reordered` 例跳过（行内下标与真值的对应被重排破坏）；`Start` 是**段落帧**量 ⇒ 两个方向都断言。本语料 `reordered` 仅 2 例，差别可忽略，但口径必须写清。

### 3.4 为什么"只新增"

- 既有判据行 `PCLINE CASE`（`臂=/wrap=/I=/PI=/非0缩进=/结构=/位置=`）、`PCLINE STRUCT`、`PCLINE TWIN`、`PCLINE NAMED`、`PCLINE GUARD`、`PCLINE 合计`、`PCLINE 分桶`、`PCLINE_EXIT` 的**口径一个字节未改**。
- **机器证据（不是人眼比 diff）**：取同一版仪器（`a787a9db23c3302c`）在**修前 `pc`** 与**修后 `pc`** 上的两份日志，按列解析后逐段对比 ⇒

| 段 | 修前 | 修后 | 逐位相同 |
|---|---|---|---|
| `PCLINE CASE [B]` **头**（`结构=`/`位置=`/`I=`/`PI=`…，去掉 `:: 原因`） | 436 例 | 436 例 | **436/436 相同，0 例不同** |
| `PCLINE STRUCT` | 56 行 | 56 行 | ✅ |
| `PCLINE TWIN` | 355 行 | 355 行 | ✅ |
| `PCLINE NAMED` | 6 行 | 6 行 | ✅ |
| `PCLINE GUARD` | 74 行 | 74 行 | ✅ |
| 新增的 `UNREGISTERED`（修后**多出来的**红） | — | **0 例** | ✅（修法**没有引入任何新红**） |

- 唯一随修法变化的是**那 24 例只错新列**的例：`UNREGISTERED 87 → 67`（消失的 20 例**恰好就是** Start-only 红里未登记的那 20 例，逐例点名已核），`KNOWN-RED 127 → 123`（Δ=4 = 4 例 `@tab0` 的 Start-only 红）。

> **一处必须披露的副作用**：新列并进用例级判定后，若某例**只**错这一列，`why`（`PCLINE CASE … :: <原因>` 的第一条原因）原本会走既有兜底串（`"位置量不一致"`）——**那是个假标签**（位置列其实全过）。⇒ 我让新列**先于**兜底串登记 `why`（值形如 `行#0 Start 我方=… 真值=… Δ=…`）。这是"新增列要能被判"的必然结果，**只新增原因、不放松任何既有列**；上表 436/436 的头相同已证明它不改任何既有列。

> **另一条被本波作废的旧契约**：W20A 立过"`--guard off` ⇒ 输出与 W20A 之前**逐字节**相同"。本波加的是**判据**（不是守卫），无条件打印 ⇒ **该契约自本波起失效**。已在 `Program.cs` 头部与 `lane(edits)` 行写明理由。

---

## ④ 红证 (a)：判据有判别力（**修前 `pc`**）

**留档**（`cp -p`，`$HOME/w21a-pre/`）：

| 件 | sha16 | 大小 | mtime |
|---|---|---|---|
| `PresentationCore.HbTextLine.cs`（修前 shim） | `fe1b7ed8fa3ed231` | 278,692 | 2026-09-16 15:30:15.645713935 +0800 |
| `PresentationCore.dll.pre`（**修前 pc**，`#19` 权威件） | `f4a454c8fe69cdfe` | 4,196,864 | 2026-09-16 15:40:28.680874188 +0800 |

> ⚠️ 本工程输出目录里有**自己的** `PresentationCore.dll` 副本（csproj `HintPath` + `Private=true`）⇒ 测修前 `pc` 时**必须替换这个副本**，只换树里那份没用。本车道逐趟用 `sha256sum` 打印该副本，读数前 = `f4a454c8fe69cdfe`。

### 4.1 确切命令与 rc（`cwd = R/build/MilBridge/tests/PcLineOracle/bin/Release`，`DISPLAY=:97`，`--guard` **缺省 `label`**）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
dotnet PresentationCore.Tests.dll \
  --pc-lines-oracle $R/tests/parity/windows/tab-anchor/out/tab-anchor-raw.json \
  --leg b --tier strict \
  --known-red $R/build/MilBridge/tests/PcLineOracle/known-red.txt
```
`rc=1`（`s_fail>0`）｜stdout 日志 `$HOME/w21a-run/redA-prefixpc-v2.out` **`e2d8ada6cdbdde2c`**（243,705 B，1,654 行）｜`ELAPSED=88.83`｜`pc` 跑前=跑后=`f4a454c8fe69cdfe`（**可归因**）。

> **口径点名（回答主控的疑点）**：本趟**不是** `--guard enforce`。⇒ 全部 `rc` 都落在 oracle 的**三态 0/1/2** 上（`1` = 有未登记失败），`rc=3` 在本趟**不可达**。W20A 的 guard 强制与本波的 `Start` 列**互不干扰**（新列的 NOINFO 检查写在 guard 强制**之后**）。**我从未产出一份 451 行 / `rc=3` 的日志**；本车道 `$HOME/w21a-run/` 下**没有**任何含 `GUARD_FAIL` 的日志（`grep -rl GUARD_FAIL` 命中 0）。
>
> **为把这条口径钉死，我另跑了一趟 `--guard enforce`（修前 `pc`）**，日志 `$HOME/w21a-run/guard-enforce-prefixpc.out` **`6686816f90fb356c`**（`pc`=`f4a454c8fe69cdfe`，18:44:04，`loadavg 1.38 1.78 1.52`）：
> ```
> PCLINE_EXIT rc=1（未登记失败 87 / 红 214 / 绿 74 / 不可比 148）
> ```
> ⇒ **`--guard enforce` 本身给的是 `rc=1`，不是 `rc=3`。** 逐字读代码（`Program.cs`）：`if (s_guard == "enforce" && s_guardFailed > 0) return 3;` ⇒ **`rc=3` 的必要条件是"守卫的贴标签前提不成立"**（`gNoBounds`/`gDelta`/`gNothing` > 0），**不是"开了 enforce"**；本趟 `装置限制(读法口径) 判定=74 例 ｜贴标签=74；重读仍取不到=0；|Δ|>容差=0；拿不到行对象=0` ⇒ `s_guardFailed=0` ⇒ 落回三态的 `rc=1`。（另：`enforce` 而**一例家族例都没有** ⇒ `rc=2`。）**这条是对主控"`rc=3` = `--guard enforce` 的出口码"这一表述的精确化**：`enforce` 是**必要不充分**。

### 4.2 原样摘录（判据的核心行）

```
PCLINE START 腿=B 红=138 绿=283 判定行=421 NOINFO=0 红例=88 Start-only红例=24 未比真值行=0 最大Δ=48.000000 @D-paraindent/lead-tab-a@w100@LTR@i0p48@default 行#0
PCLINE LEG=B Start 口径 断言=**只对 TextAlignment=Left**（本语料头钉死） ｜ 真值=语料 `lineStartOffsetsDip[k]` ｜ R(v)=Round(v,6,AwayFromZero) ｜ 判据=**精确相等**（真法律是恒等式，不是近似） ｜ 比较**独立于 `structOk`**（`Start` 是段落级常量 ⇒ 与我方怎么切行无关） ｜ bidi 例**不跳**（`Start` 是段落帧量）
PCLINE START 腿=汇总(B) 红=138 绿=283 判定行=421 NOINFO=0 红例=88 Start-only红例=24 未比真值行=0 未登记失败=87 其中点名Start列=20 最大Δ=48.000000 @D-paraindent/lead-tab-a@w100@LTR@i0p48@default 行#0
PCLINE START-RC 腿=B 未登记失败=87 其中点名Start列=20 ⇒ rc≠0（本列有未登记红，**不许压成 0**）
PCLINE START-RC 汇总 点名Start列的**未登记**红=20 ⇒ rc 必须非 0（本趟 rc=1）；登记表=…/known-red.txt，**本车道未改登记表**（重钉归主控）
PCLINE_EXIT rc=1（未登记失败 87 / 红 214 / 绿 74 / 不可比 148）
```

**判别例 `B-indent-extra/lead-tab-a@w40@LTR@i24p24@default` 行 0/1（预登记 §1.6 点名）原样：**

```
PCLINE START B-indent-extra/lead-tab-a@w40@LTR@i24p24@default 行#0 Start 我方=0.000000 真值=24.000000 Δ=-24.000000
PCLINE START B-indent-extra/lead-tab-a@w40@LTR@i24p24@default 行#1 Start 我方=0.000000 真值=24.000000 Δ=-24.000000
PCLINE START-CASE B-indent-extra/lead-tab-a@w40@LTR@i24p24@default 本列=FAIL 比过=2 行 红行=2 绿行=0 真值行数=2 ⇒ 本列**判决该例为红**
```
⇒ 与预登记 §1.6 的预测（`0.000000` vs `24.000000`，行 0/1）**逐字吻合**。

### 4.3 与主控独立重算的**逐位对账**（含 §11 的修正口径）

主控先给的目标（整份语料 **171 行 / 112 例**）**不是本臂该报的数**（本臂有覆盖闸）；随后主控自查并更正为 **138 行 / 88 例**。我把臂的逐行点名行**导出后与主控冻结的期望集做了集合比对**：

| 项 | 值 |
|---|---|
| 臂产出的 `PCLINE START` 行数 | **138**（distinct `(id,行号)` = **138**，无重复） |
| 臂报的红**例**数 | **88** |
| 主控期望集 `$HOME/w21-verify/expected-red.tsv`（sha16 **`52fe6204f09be64a`**，172 行 = 1 表头 + 171 数据） | 171 行 |
| 期望集**限定 `script==latin`** 后的行数 | **138** |
| **臂的 138 集合 == 期望集(latin) 的 138 集合？** | ✅ **完全相等**（only-in-arm = **0**，only-in-exp = **0**） |
| 我方取值 | **138/138 全为 `0.000000`**，且 Δ 全部 `== −真值` |
| 真值直方图（latin 子集） | `24.0 × 116`、`48.0 × 22` |
| 方向 | latin 子集的 138 行**全为 `LeftToRight`** |

**结论**：**与主控独立重算吻合（138 行 / 88 例），且是集合级相等，不是计数巧合。**

### 4.4 判据有**判决权**（把主控的硬要求 ① 做成了读数）

主控的疑点成立且重要：光有"逐行点名行"不等于"被判"。本列的证据是**机器可核**的三条：

1. **Start-only 红 = 24 例**：这 24 例的 `结构=PASS` **且** `位置=PASS`，**只**因为新列而红 ⇒ 新列**不是**任何既有列的重复，**确实有独立判决权**。
2. **并进用例级判定**：`oneCase = structOk && (reordered || posOk) && startOk` ⇒ 新列一变红，该例**必进 `failIds`** ⇒ 进既有 `--known-red` 裁定 ⇒ 未登记就进 `unregistered` ⇒ **`rc` 非 0**。实测：20 例未登记（`redA-prefixpc-v2` 的 `未登记失败=87` 里点名 Start 的 20 例）。
3. **rc 显式反映**（硬要求 ③）：单独印 `PCLINE START-RC`，`点名Start列的未登记红=20 ⇒ rc 必须非 0`；并印"若全部在册则 rc 保持 0（在册机制，不是洗绿）"的分支，避免读者把"rc=0"误读成"本列没红"。**本车道未改登记表**；`Start` 红要留册 ⇒ **需要主控重钉**。

> **对主控疑点的诚实回应**：您看到的"同一处 Start 失配、`位置=` 一个 FAIL 一个 PASS"是真的，但原因**不是**"没进判决"，而是 **`位置=` 这一列按定义只反映逐字符 x 列**（`Program.cs` 里 `(reordered ? "跳过(bidi 重排)" : (posOk ? "PASS" : "FAIL"))`），**不**反映新列。您引的那两份日志（451 行 / `rc=3`）**不是本车道的产物**（本车道两份主日志是 1,311 行 `rc=1` 与 1,654 行 `rc=1`），所以那两个 `PCLINE CASE` 行的出处我无法核到；但**该形态完全可能出现**在修前的第一版日志 `redA-prefixpc.out`（`f023a3b8ffee144a`，1,311 行）里，且它正是"列存在但不可点名"的形态。按您的三条硬要求，我已把**可对账的计数器 + 逐例卷起行 + rc 显式化**补齐（§3.2/§4.2），并把"逐行点名行与计数能对上"做成了**集合级**核验（§4.3）。

### 4.5 覆盖闸的边界（主控 §11 的连带更正，我实测确认）

| 口径 | 例数 | 行数 | `Start≠0` 的行 |
|---|---|---|---|
| 整份语料 | 436 | 615 | 171 |
| **本臂真正判定的（`latin`，`script` 字段）** | **288** | **421** | **138** |
| 被覆盖闸跳过（`hebrew` 116 + `arabic` 32） | 148 | 194 | 33 |

⇒ **本臂的红应当（且实测就是）138 行 / 88 例**；报 171 才说明覆盖闸失效。**并且**：RTL 那 33 行非零值**全在 `C-rtl-indent`（Hebrew）** ⇒ **全部被覆盖闸跳过**；latin 的 138 行**全是 LTR**。
⇒ **法律本身**在 LTR(138 行) / RTL(33 行) 两向都是 0 反例（**语料侧**独立证据，成立）；但**本臂实际只行使了 LTR 那一半**。报告不得写成"判据覆盖了 RTL"——**"在门的射程内" ≠ "门真的看了"**（与 `#19` 在册纪律同一形态）。
> 覆盖闸的机制是**字形可用性**（`NominalGlyph(ch)==0` ⇒ 跳过），不是 `script` 字段；本语料上两者**恰好重合**（跳过的 148 例 = 非 latin 的 148 例），我按机制复述，不按字段复述。

### 4.6 判据的**两极化**（自己给自己的红证，规则 25）

判据的 `NOINFO` 支路必须能变红，否则"恒绿"。我对语料做了两个变体（只改语料头，不动臂）：

| 变体 | 语料 sha16 | 结果 | `rc` |
|---|---|---|---|
| `paragraphProperties.fixed` 改成 `TextAlignment=Right` | `c0084eb311f3da51` | `PCLINE START 腿=汇总(B) 红=0 绿=0 判定行=0 NOINFO=216` + `PCLINE START-NOINFO …（逐例）` | **2** |
| 删掉 `paragraphProperties.fixed` | `1ab19e993d7ef0dc` | 同上（原因 = "缺失或不是字符串 ⇒ 对齐不可判定"） | **2** |
| **阳性对照**：真语料 + 同一命令（`--case B-indent`） | `88559d670f1bb955` | `红=86 绿=243 判定行=329 NOINFO=0` | **1** |

⇒ 三个极性都实测在册：**声明非 Left ⇒ NOINFO/rc=2**；**缺声明 ⇒ NOINFO/rc=2**（"缺声明 ≠ 是 Left"）；**真语料 ⇒ 真断言**。

### 4.7 这一版仪器的一个**已知不足**（如实记）

第一版（`redA-prefixpc.out`，`f023a3b8ffee144a`）把新列放在 `if (structOk)` 内 ⇒ **只比了 355/615 行**，红数虚低到 117。**这是我自己的仪器缺陷，不是产品读数**，已按 §3.3 决定 3 修正并重取。附带损失：那一趟 3 分钟白跑。留档以便审计。

---

## ⑤ 修法（**最小面**）与绿证

### 5.1 shim 改动：`build/shims/PresentationCore.HbTextLine.cs`

| | sha16 | 大小 | mtime |
|---|---|---|---|
| 修前 | `fe1b7ed8fa3ed231` | 278,692 | 2026-09-16 15:30:15.645713935 +0800 |
| **修后** | **`76089e1de586ac91`** | **283,557** | 2026-09-16 18:31:48.296647240 +0800 |

逐处改动点（**行号为修后文件**）：

| # | 位置 | 改动 |
|---|---|---|
| 1 | `:2637-2656`（原 `:2636` 之后） | 新增字段 `private readonly double _paragraphIndentDip;` + 一段文档注释（真法律三条腿、**为什么必须单存**、折叠路径未测的披露） |
| 2 | `:2722-2729`（`private HbTextLine(…)`） | 形参表**末尾**追加 `double paragraphIndentDip = 0`（**带默认值** ⇒ 既有调用点零改动）；构造体新增 `_paragraphIndentDip = paragraphIndentDip;` |
| 3 | `:2901-2906`（行构造，`new HbTextLine(…)`） | 末参追加 `paragraphIndentDip`（即 `TextParagraphProperties.ParagraphIndent` 原始 DIP），与 `startPenX = indentDip + paragraphIndentDip`、`boxOriginX = paragraphIndentDip` **并列** |
| 4 | `:3646-3653`（**折叠路径 `BuildCollapsedLine`**） | 用**命名实参** `paragraphIndentDip: _paragraphIndentDip` 转发（该构造点原本止于 `_paragraphWidth`，**没传** `runProps`/`startPenX`/`boxOriginX` ⇒ 走默认 0） |
| 5 | `:3412-3439`（`Start` 属性） | `public override double Start => 0;` → **`public override double Start => _paragraphIndentDip;`**；并把那句**已被推翻的注释**（`// 真机实测恒为 0（3222/3222），不是段落内偏移`）改成**真法律 + 一份完整的更正说明**（旧注释原文照录、`3222/3222` 的来源语料 `layout-b34` 四个文件里 `'ParagraphIndent'`/`'Indent'` 各出现 **0** 次 ⇒ 那是**语料性质**不是实现规律） |
| 6 | `:2694-2700`（单 run 便捷构造） | **未改**（走默认 0 ⇒ `Start=0`，与"无段落缩进"一致）。其 **PI 语义未测**，仅如实登记 |

**禁止项遵守情况**：**未**用 `_startPenX` / `_boxOriginX` 反推 PI（新增独立字段）；`_startPenX` 是合量（`shim:2633` 已写明）；`_boxOriginX` 今天取值同为 PI，但让 `Start` 依赖**渲染布局量**会在下次动盒坐标时静默改掉 `Start` ⇒ 各存一份（已写进代码注释）。**未碰** `build/MilBridge/staging/**`、`build/MilBridge/tests/CoverageProbe/refs/*.cs`。

**折叠行的诚实边界（主控口径 ①，我照办并如实披露）**：折叠路径**已转发** `_paragraphIndentDip`（否则同段落里"正常行 `Start=PI`、折叠行 `Start=0`"两套框架并存）。但 **折叠行在 `PI≠0` 下的 `Start` 真值，本语料没有覆盖** ⇒ 那是 **`NOINFO`**；转发是"**为保持成员自洽**"的选择，**不是实测结论**。单 run 便捷构造同上（其 PI 语义未测）。

### 5.2 重建 `pc`

```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -c Debug -m:1
# ⇒ 已成功生成。 0 个警告 0 个错误   （error CS = 0）
```
- `pc` `f4a454c8fe69cdfe`（4,196,864 B）→ **`e7cabff9417ed380`**（4,196,864 B，mtime 2026-09-16 18:38:37.617997302 +0800）
- **"`pc` 变"不蕴含"行为变"**（`#19` 起的新口径）：`#16` 的 P1 把 **shim 整文件 sha** 编进 `AssemblyMetadata` ⇒ 改一句注释就改 DLL 字节。**归因用等号读者，不用比 `pc` 的 sha 变没变**。
- **等号读者**（W17C 的 `ShimShaReader`，只读、不加载程序集）实测：
  ```
  SHIM_SHA=no reason=content-compare artifact=e7cabff9417ed380 artifact_bytes=4196864 shim=76089e1de586ac91
  product_sha16=76089e1de586ac91 tree_sha16=76089e1de586ac91 asm=PresentationCore cmp=full64
  ```
  rc=0 ⇒ **产物确实是用这一份（改过的）shim 编出来的**（`no` = 内容相等），**不是"应该是"**。
- **附带测得：构建可复现** —— 复原 shim 后**再构建一次**，`pc` 复算回**同一个 `e7cabff9417ed380`**（见 §6）。

### 5.3 绿证

同一命令、同一仪器，仅把臂输出目录里的 `pc` 副本换成修后 `pc`（`e7cabff9417ed380`）：

```
PCLINE START 腿=汇总(B) 红=0 绿=421 判定行=421 NOINFO=0 红例=0 Start-only红例=0 未比真值行=0 未登记失败=67 其中点名Start列=0 最大Δ=0.000000 @-
PCLINE 合计 判定红=190 判定绿=98 不可比(缺字形)=148 其中 bidi 重排例=2 NOINFO例=0
PCLINE 分桶 非0缩进: 红=127 绿=57 /224；零缩进: 红=63 绿=41 /212；其中 PI≠0: 红=64 /112
PCLINE_EXIT rc=1（未登记失败 67 / 红 190 / 绿 98 / 不可比 148）
```
`rc=1` ｜ 日志 `$HOME/w21a-run/greenA-postfix.out` **`7a28349a61ef7ace`**（218,978 B）｜`ELAPSED=70.73`｜`pc` 跑前=跑后=`e7cabff9417ed380`。

- **`红=0 / 绿=421`、`最大Δ=0.000000`** ⇒ 绿证到手（**分母 421 而非任务书写的 615**，理由见 §4.5；主控 §11 已独立确认 421/138 才是本臂的口径）。
- **`PI=0` 的行逐位不动**：`PI=0` 的 latin 行 = `421 − 138 = 283` 行，**修前 283 行全绿、修后 283 行仍全绿**，且 §3.4 的 436/436 `CASE` 头相同证明它们**一个字节没动**。（任务书写的"444 行"是**整份语料**的 `PI=0` 行数；本臂口径下是 **283**。）

### 5.4 重复性

同一命令、同一 `pc` **独立跑两趟**：`greenA-postfix.out`（`7a28349a61ef7ace`）与 `greenA-postfix-v2.out`（`c2d47e78665763d1`）**逐行相同**，差异**仅在 3 行环境头**（时间戳、`loadavg`、`MemAvailable`；v2 另加了一行 `shim=`）。判据行、分桶、逐行台账**全部逐字节一致**。

### 5.5 与 `#19` 冻结基线的对照（**无回归**）

| 读数 | `#19` 冻结基线（**未改动的臂** + 修前 `pc`，`baseline-arm-pre.out` = `7e249e02bf8518ba`） | 本波修后（**新仪器** + 修后 `pc`，`7a28349a61ef7ace`） |
|---|---|---|
| `合计` | `判定红=190 判定绿=98 不可比=148` | **同** |
| `分桶` | `非0缩进 红=127 绿=57 /224；零缩进 红=63 绿=41 /212；PI≠0 红=64 /112` | **同** |
| `未登记失败` / `rc` | `67` / `1` | **同** |
| 层级来源 | `严格档接手=270 例、宽松档接手=0 例、缓存复用=18 例` | **同** |

⇒ `#19` 冻结基线的**每一条既有读数本波修后逐位复现**。两层含义：(1) 新增列**不扰动**既有列；(2) 本修法在 `Start` 之外**零射程**（与 §3.4 的"修后新增红 = 0 例"互证）。

---

## ⑥ 红证 (b)：错驱动量也红 ⇒ **222 行 / 148 例**

**做法**（任务书允许的"等价地把传进来的值换成 `Indent`"）：把 `:2905` 行构造的**末参**从 `paragraphIndentDip` 临时改成 `indentDip` ⇒ `Start = Indent`。

| 步 | 件 | sha16 |
|---|---|---|
| 临时态 shim | `build/shims/PresentationCore.HbTextLine.cs` | `da2e5e3a6ae6caf7` |
| 临时态 `pc`（重建，`0 个警告 0 个错误`） | `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `9c1335e998c5d88a` |

读数（日志 `$HOME/w21a-run/redB-wrongqty.out` **`2caaa16b588926b1`**，`ELAPSED=68.63`，`pc` 跑前=跑后=`9c1335e998c5d88a`）：

```
PCLINE START 腿=汇总(B) 红=222 绿=199 判定行=421 NOINFO=0 红例=148 Start-only红例=47 未比真值行=0 未登记失败=103 其中点名Start列=36 最大Δ=48.000000 @D-paraindent/lead-tab-a@w100@LTR@i0p48@default 行#0
PCLINE 合计 判定红=237 判定绿=51 不可比(缺字形)=148 其中 bidi 重排例=2 NOINFO例=0
PCLINE_EXIT rc=1（未登记失败 103 / 红 237 / 绿 51 / 不可比 148）
```
- **红 222 行 / 148 例** ⇒ 与预登记 §6(b) 的 **278** 的关系：**278 是整份语料的口径**（`Start==Indent` 命中 `337/615` ⇒ 错 `278/615`），**本臂的实际口径是 `222/421`** —— 我独立重算的三组数与实测**逐位吻合**：

| 口径 | `Start==Indent` 错的行 | 命中 |
|---|---|---|
| 整份语料 | **278** / 615 | 337 / 615 |
| **本臂（latin）** | **222** / 421 | 199 / 421 |
| 实测臂读数 | **222** | 199（`绿=199`） |

- **判据确实在区分两个候选驱动量**（这是 (b) 的意义）：错驱动量下 **`i24p24` 反而绿**（`Indent==PI==24`）、**`i0p24` 转红**（`Indent=0 ≠ PI=24`）：
  ```
  PCLINE START B-indent-extra/lead-tab-a@w40@LTR@i0p24@default 行#0 Start 我方=0.000000 真值=24.000000 Δ=-24.000000
  PCLINE START B-indent-extra/lead-tab-a@w40@LTR@i0p24@default 行#1 Start 我方=0.000000 真值=24.000000 Δ=-24.000000
  ```
  而正确驱动量下这两例**全绿**。⇒ **`PI` 与 `Indent` 被本判据分开了**，不是同一个数换了名字。

**复原**（逐字节，未留在树里）：

| 检查 | 结果 |
|---|---|
| `cp -p $HOME/w21a-pre/PresentationCore.HbTextLine.cs.postfix build/shims/PresentationCore.HbTextLine.cs` | — |
| shim sha16 | **`76089e1de586ac91`**（= 修后值）✅ |
| `cmp` 与备份 | **BYTE-IDENTICAL** ✅ |
| mtime | `2026-09-16 18:31:48.296647240 +0800`（`cp -p` 还原）✅ |
| 重建 `pc`（`0 个警告 0 个错误`） | **`e7cabff9417ed380`**（= 修后值）✅ |

---

## ⑦ 我**推翻 / 修正**了主控什么（**必须如实写，预登记不是免责的**）

1. **推翻：`§1.6` 判别例的"红 171 / 绿 444"这个分母对本臂不成立。**
   任务书与预登记 §1.6 写"红 → 绿 615 行"，§6(c) 写"修后须 红 0 / 绿 615"。**本臂有覆盖闸**（字形可用性），只判定 **421 行**：⇒ 正确的分母是 **421**，红是 **138**（不是 171），§6(c) 的"绿 615"应是"**绿 421**"。
   **这一条主控已自查并主动更正（§11），我在实测前就已用同一组数独立重算过**（latin 288 例 / 421 行 / 138 非零），两方结果**逐位一致**。记为主控自查更正，**不算我的更正**；但报告的分母口径以 **421/138/222** 为准。
2. **推翻：`§6(b)` 的"必须红 278"对本臂不成立** —— 同上，本臂口径是 **222**（278 是整份语料）。实测 `红=222 绿=199` 与独立重算吻合。
3. **修正：预登记 §1.4 的"判据覆盖 LTR + RTL"表述会误导。** 法律**在语料侧**两向都是 0 反例（LTR 138 / RTL 33）；但**本臂实际只行使 LTR**（RTL 那 33 行全在 `C-rtl-indent`，Hebrew，被覆盖闸跳过）。**"在门的射程内" ≠ "门真的看了"**。（主控 §11 已作同一更正。）
4. **修正（本车道自查，非主控）：主控引用的那份"451 行 / `rc=3`"日志不是本车道的产物。** 本车道两份主日志为 1,311 行（`f023a3b8ffee144a`）与 1,654 行（`e2d8ada6cdbdde2c`），`rc` 均为 1；`$HOME/w21a-run/` 下 **没有任何**含 `GUARD_FAIL` 的日志。**红证 (a) 是在 `--guard` 缺省（`label`）下取的**，`rc=3` 在本趟不可达 ⇒ 与 oracle 三态 0/1/2 **不会**混读。主控据以立论的技术形态（"列存在但不可点名"）**成立且我照办补齐**，只是那两份具体日志的出处我核不到。
5. **修正：`§1.6` 表里"判别例"的 id 与我臂的实测最大值不同例。** 预登记点名的判别例 `B-indent-extra/lead-tab-a@w40@LTR@i24p24@default` **确有**（行 0/1 逐字吻合，见 §4.2）；但**最大 Δ 落在 `D-paraindent/lead-tab-a@w100@LTR@i0p48@default 行#0`（Δ=48.000000）**，因为 `PI=48` 那族比 `PI=24` 差得更多。不是矛盾，但"最大差"这个读数应点 `PI=48` 的例。
6. **未兑现的预测（提请主控处置，不是位移）**：§5 表预测 `pf` **变**（"环成员，每趟波必变"），本车道实测 **`bd4e28e6a6f8b0e5` 未变**。原因：`pf` 只在**波尾** `close-wave.sh` 重编时才变，本车道只构建了 `pc`。⇒ **不是 §5 表外位移**（§7 停条件 1 是"位移落在表外"，这里是"表内预测未兑现"），**未触发停**；但请主控在波尾复算时注意：**`pf` 的"每趟必变"依赖 `close-wave` 真的重编它**，若波尾 `pf` 仍不变，那说明该预测的前提不成立。

**我没有推翻的**：主控三条腿（公式 / 615-615 实测 / 移植版不硬编码 0）我独立复核后**全部成立**；"3222/3222 是 `layout-b34` 语料性质"我**独立复核了那个语料**的四个文件（`'ParagraphIndent'`=0、`'Indent'`=0）⇒ 成立。

---

## ⑧ 读数表（纪律 32：每条读数都记责任人 / 时间 / 负载 / 内存 / 内核）

`lane=`**`W21A`** ｜ kernel **`6.8.0-138-generic`** ｜ `nproc=3` ｜ `DISPLAY=:97`（`xdpyinfo` = UP）｜ 仪器 `Program.cs` = **`a787a9db23c3302c`**、臂 dll = **`c76bdf2254b9a00e`**（除第 1 行注明者外）

| # | 读数 | 时间 (+0800) | `loadavg` | `MemAvailable` | `pc` 跑前 → 跑后 | 日志 sha16 | rc |
|---|---|---|---|---|---|---|---|
| 1 | 基线（**未改动仪器** `19f9e7e78e9bb5c7`，修前 `pc`） | 18:25:01 | `1.04 0.40 0.15` | 3,702,932 kB | `f4a454c8fe69cdfe` → 同 | `7e249e02bf8518ba` | 1 |
| 2 | **红证 (a) 第一版（仪器缺陷，已作废并留档）** | 18:28:38 | `2.14 1.68 0.79` | 3,835,880 kB | `f4a454c8fe69cdfe` → 同 | `f023a3b8ffee144a` | 1 |
| 3 | **红证 (a)（有效版）** | 18:31:18 | `2.01 1.81 0.99` | 3,723,376 kB | `f4a454c8fe69cdfe` → 同 | `e2d8ada6cdbdde2c` | **1** |
| 4 | 对齐闸变体 `Right`（`--case B-indent`） | 18:35:58 | (未记) | (未记) | `f4a454c8fe69cdfe` → 同 | `604260d76819fa6a` | **2** |
| 5 | 对齐闸变体 无声明（`--case B-indent`） | 18:37:08 | (未记) | (未记) | 同 | `2cb56d1b749482b5` | **2** |
| 6 | 对齐闸阳性对照（真语料，`--case B-indent`） | 18:38:06 | (未记) | (未记) | 同 | `449325527d4064cb` | 1 |
| 7 | 重建 `pc`（shim 修后） | ≈18:38:37（由 `pc` mtime 推） | — | — | `f4a454c8fe69cdfe` → **`e7cabff9417ed380`** | —（build 日志） | 0 |
| 8 | **绿证** | 18:38:56 | `2.74 2.20 1.49` | 2,606,408 kB | `e7cabff9417ed380` → 同 | `7a28349a61ef7ace` | 1 |
| 9 | 临时态重建 `pc`（错驱动量） | ≈18:40 | — | — | → `9c1335e998c5d88a` | — | 0 |
| 10 | **红证 (b)** | 18:41:06 | `(见日志头)` | 2,819,536 kB | `9c1335e998c5d88a` → 同 | `2caaa16b588926b1` | 1 |
| 11 | **复原 shim + 重建 `pc`** | 18:42:42（`pc` mtime） | — | — | → **`e7cabff9417ed380`** | — | 0 |
| 12 | **绿证 复跑（重复性）** | 18:42:48 | `1.62 1.91 1.54` | 2,686,736 kB | `e7cabff9417ed380` → 同 | `c2d47e78665763d1` | 1 |
| 13 | `--guard enforce`（换回修前 `pc`，口径对照） | 18:44:04 | `1.38 1.78 1.52` | 见日志头 | `f4a454c8fe69cdfe` → 同 | `6686816f90fb356c` | **1**（**不是** 3，见 §4.1） |

> **时序如实记**：第 10 趟（红证 b）在 **18:41:06**，第 11 趟（复原）在 **18:42:42** ⇒ **临时错驱动量态只存在于树里约 2 分钟**（18:40→18:42:42），且**当日任何时刻都不在树里**——已 `cmp` + sha + 复算 `pc` 三重证明（§6）。第 13 趟为口径对照，用的是**留档的修前 `pc`**（`f4a454c8fe69cdfe`），跑完已把臂输出目录里的副本换回修后 `e7cabff9417ed380`（实测确认）。

**归因**：第 3/8/9/11 趟的 `pc` 跑前=跑后，**读数全部可归因**（无"跑中途被换 sha"的情形）。第 2 趟为**仪器缺陷**留档，**不作为任何判据**。

**§5 位移表逐条对照**（本车道实测）：

| 位 | `#19` | 预测 | 本车道实测 | 判定 |
|---|---|---|---|---|
| `bridge` | `d567c26f197ec1e3` | 不变 | `d567c26f197ec1e3` | ✅ |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | 不变 | `b6acdba4f01599d8` | ✅（`build/shims` 不在其覆盖根内） |
| **`pc`** | `f4a454c8fe69cdfe` | **变** | **`e7cabff9417ed380`** | ✅ |
| **`hbtextline`** | `fe1b7ed8fa3ed231` | **变** | **`76089e1de586ac91`** | ✅ |
| `pf` | `bd4e28e6a6f8b0e5` | 变 | `bd4e28e6a6f8b0e5`（**未变**） | ⚠️ 见 §7-6 |
| `windowsbase` | `1114a28ec5a03ab7` | 不变 | `1114a28ec5a03ab7` | ✅ |
| `provider` | `9aa0d744802aaa31` | 不变 | `9aa0d744802aaa31` | ✅ |
| `win32shim` | `0098234982391bbf` | 不变 | `0098234982391bbf` | ✅ |
| `wic_shim` | `03b67fbcd7c385b6` | 不变 | `03b67fbcd7c385b6` | ✅ |
| `dwf` | `0ed422ef2dd46445` | 不变 | `0ed422ef2dd46445` | ✅ |
| **`inputs_fp`** | `288447d98d255f4c…68d39` | **变** | **`5c84419f748c12a792fff1037f8ff7e2ba9144fd1e106a6cb0400dc9622e114f`** | ✅（`fp_inputs()` 覆盖 `build/shims/**/*.cs`） |
| 五臂门禁 | `generation=#19 tree_gen=same` | 先 `NOINFO/rc=2 tree_gen=advanced` ⇒ 重取+重钉 | **本车道不跑**（主控波尾） | — |
| 应用门禁 / `verify-all` / 等号读者 | — | 逐位不变 / 同前 / `no` | **本车道不跑**（等号读者已单独实测 = `no`，见 §5.2） | — |

**⇒ §5 表外位移：无。**

---

## ⑨ 未测清单 / 风险（**不许读成绿**）

1. **折叠行（`BuildCollapsedLine`）在 `PI≠0` 下的 `Start` 真值：本语料没有覆盖 ⇒ `NOINFO`。** 那里转发 `_paragraphIndentDip` 是"**为保持成员自洽**"的选择，**不是实测结论**。同理 **`:2694` 单 run 便捷构造的 PI 语义未测**（走默认 0）。
2. **`Right` / `Center` 的 `Start` 公式：本臂不发明、也未测。** 真机公式为 `paragraphWidth − _textWidthAtTrailing`（Right）/ `(paragraphWidth + _textStart − _textWidthAtTrailing)/2`（Center），**本语料零覆盖** ⇒ 要测必须**另录真机语料**（登记为后续项）。
3. **RTL 半边未行使**：法律的 RTL 证据来自**语料侧**（33 行非零，全在 `C-rtl-indent`），**本臂因字形缺失全部跳过** ⇒ 本臂的 138 行**全是 LTR**（§4.5）。
4. **覆盖闸之外的 148 例（194 行）从未被本列看过** —— 它们的 `Start` 既不算红也不算绿。这是覆盖闸的既有边界，不是本列新增的。
5. **`Start` 的消费者未归因（watch item，主控 §5 已列）**：本波只证明 `Start` **读数**正确，**未**证明渲染路径是否消费它。应用门禁两趟由主控在波尾跑；**若应用门禁读数变了 ⇒ 不是失败，是发现，必须先归因**。
6. **冻树上仍然没有任何自动红/绿盯着 `Start`**（主控 §④，我独立复核）：
   - 五臂门禁的 tab 三臂宿主 `build/MilBridge/tests/CoverageProbe/Program.cs` 里 **`lineStartOffsetsDip` 出现 0 次**；`grep -c '\.Start'` 的**唯一**命中在 `:1160` 是 `id.StartsWith("M_modifier", …)` —— **字符串方法**，**不是 `TextLine.Start`** ⇒ **门禁对 `Start` 零判别力**（逐字给出，避免"0 命中"被误引）。
   - `grep -c 'PcLineOracle' build/MilBridge/tools/tline-gate.sh verify-all.sh` ⇒ **两边都是 0** ⇒ `PcLineOracle` **不在五臂门禁、也不在 `verify-all`**。
   - ⇒ **本件修完之后，冻树上仍无自动判据盯 `Start`**；须由主控在波尾把 `PcLineOracle` 接进 `verify-all`（本车道未接，任务书禁止）。
7. **`known-red.txt` 未改、也未重钉**（`89324f1f643167e5`，136 条全 `@tab0`）。`Start` 族**需要新的在册条目**（修前 138 行 / 88 例中 20 例未登记、4 例落在既有 `@tab0` 条目上）⇒ **需要主控重钉**；本车道**没有把未登记红压成 rc=0**（`rc=1`）。
8. **本波改动使 W20A 的一条旧契约失效**：`--guard off` 不再等于"W20A 之前的逐字节基线"（新列与 `--guard` 无关、无条件打印）。**已在代码注释与 `lane(edits)` 行写明**。
9. **`pc` 大小巧合**：`f4a454c8fe69cdfe` 与 `e7cabff9417ed380` **字节数相同**（4,196,864 B）。**未查明原因**；等号读者已证明**内容**确实换了（`product_sha16=76089e1de586ac91` = 新 shim）⇒ 大小相同不影响归因，但"大小相同"**不能**当作"没变"的证据（这正是 `#19` 起的口径）。
10. **并行车道的活动（归因相关，如实记）**：任务书说"本波只有你这一条车道在跑构建"，但 `find -newermt '18:20'` 显示**同时有别的车道在写**：`BuildHygiene.props`（18:28，新件）、**约 30 个 `.csproj`**、`build/MilBridge/{W21B,W21C,W21D}-report.md`、`docs/WAVE21-PREREGISTRATION.md`（主控更新 §10/§11）、`build/MilBridge/tools/pc-line-step.sh`（18:26）。
    - **对本车道读数的影响 = 无**：本车道四份有效读数（第 3/8/10/12 趟）的**被测件与语料 sha 逐趟记录在案且跑前=跑后**——`shim 76089e1de586ac91`、`pc e7cabff9417ed380`（或临时态 `9c1335e998c5d88a`）、语料 `tab-anchor-raw.json 88559d670f1bb955`（mtime `2026-09-14 19:32:35`，**全程未变**）。
    - ⚠️ **一条观察（不是我的写域）**：`tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json` 与 `analyze.py` 的 mtime 是 **18:39:23 / 18:39**，即在**本波进行中**被写过。**本车道的判据只用 `tab-anchor-raw.json`**（`88559d670f1bb955`，未变），所以不受影响；但那条改动**不在我车道写域内**，**我未查证是谁改的、改了什么**，请主控核（纪律 4：引注前现场重读）。
    - 本车道**只**构建了 `PresentationCore.Linux`（`)` 与自己的臂工程，**未**并行跑多个 `dotnet build`（每趟单条 `-m:1`）。

---

## ⑩ 交付物

| 件 | sha16 | 备注 |
|---|---|---|
| `build/MilBridge/tests/PcLineOracle/Program.cs` | `a787a9db23c3302c` | 仪器（**只新增一列比较 + 计数器 + rc 口径**） |
| `build/shims/PresentationCore.HbTextLine.cs` | `76089e1de586ac91` | 修法（`Start => _paragraphIndentDip` + 字段/构造点透传 + 注释更正） |
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `e7cabff9417ed380` | 权威 `pc`（等号读者 = `no`） |
| `build/MilBridge/W21A-report.md` | 见下（`sha256sum` 自印） | 本报告 |
| 留档 | `$HOME/w21a-pre/{PresentationCore.HbTextLine.cs.pre, PresentationCore.HbTextLine.cs.postfix, PresentationCore.dll.pre}` | `fe1b7ed8fa3ed231` / `76089e1de586ac91` / `f4a454c8fe69cdfe` |
| 日志 | `$HOME/w21a-run/*.out` | 见 §8 读数表 |

**本车道未碰**：`build/MilBridge/known-red.json`、`build/MilBridge/tests/CoverageProbe/**`、`build/MilBridge/tools/tline-gate.sh`、`verify-all.sh`、`docs/**`、`samples/**`、`build/MilBridge/staging/**`、`src/**`。**未运行** `pkill -f`（全程未杀任何进程）；**未自起 Xvfb**。
