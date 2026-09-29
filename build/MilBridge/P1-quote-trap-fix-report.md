# P1-QUOTE-TRAP-FIX（`t147` · W67：修 `pts-pages-guard.sh` 的 22 处 `DQ-BACKTICK` —— 命名变量拼装，输出逐字不变）

> **来源**：已接线牙 `bash build/MilBridge/tools/shell-quote-trap-check.sh` **现取 `rc=1`**（`traps=22 files=203 sh=114 py=89 diag=76 allow=0`），22 处**全在** `build/MilBridge/tools/pts-pages-guard.sh`，且**全是 `t145` 新增的色锚／`N4` 判词**（双引号 `echo` 内嵌反引号）。
> **写域**：`build/MilBridge/tools/pts-pages-guard.sh` ＋ 本件。**未碰** `src/**`（`runner` 的 `t146` 在飞）／`docs/**`／任何 `.cs`／两枚哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`；**相位位 `degraded` 未翻**；未 `git add/commit/push`；未跑整趟门禁／构建／跑腿／显示位；**夹具全部仓外**（本次**没有**在仓内放过任何临时件，故无需"零残留"补救）。

## §1 收尾必交①：22 处**逐处**「改前形态 → 改后形态」（同一位点对照）

位点**自己现取**（调用牙解析 `SHELL_QUOTE_HIT … line=L col=C`，不引用派单清单）：**22 个反引号 ＝ 11 对**，落在**5 行**上。修法：件内新增**单引号变量** `BT='`'`（持有反引号字符本身），逐处把双引号串里的裸反引号换成 `${BT}`。

| # | 行（改前，**仅本次有效**） | 对数 | 改前形态 → 改后形态（逐处） |
|---|---|---|---|
| 1 | `:632` | 1 | `` `LightGray` `` → `${BT}LightGray${BT}` |
| 2 | `:635` | 3 | `` `RichTextBoxDemo.xaml` `` → `${BT}RichTextBoxDemo.xaml${BT}`；`` `t145` `` → `${BT}t145${BT}`；`` `cannot` `` → `${BT}cannot${BT}` |
| 3 | `:644` | 4 | `` `t145` `` → `${BT}t145${BT}`；`` `cannot` `` → `${BT}cannot${BT}`；`` `n4` `` ×2 → `${BT}n4${BT}` ×2 |
| 4 | `:655` | 2 | `` `N1` `` → `${BT}N1${BT}`；`` `N3` `` → `${BT}N3${BT}` |
| 5 | `:657` | 1 | `` `FlowDocumentDemo` `` → `${BT}FlowDocumentDemo${BT}` |
| — | 新增 3 行（`BT` 定义块，插在 `COLOR_ANCHOR_K24=` 之前） | — | 该块**注释行**里另有一对反引号（示例写法），但它们**在注释里**、**不是**陷阱（修后牙 `traps=0` 现取为证 ✓） |

**逐处对照的机械证明（word-diff）**：对 5 行逐行做「把裸反引号与 `${BT}` 各自切行后 diff」⇒ **差异行全部是** `` ` `` ↔ `${BT}`（每对 2 行）：`:632`→4 行（＝2×1）／`:635`→12 行（＝2×3＋… 共 6 个反引号 ⇒ 12）／`:644`→16 行／`:655`→8 行／`:657`→4 行 ⇒ 合计 **2×(1+3+4+2+1) ＝ 22** ✓ **与牙的 22 个命中逐一吻合**；除该替换外**该 5 行没有任何其他字节变化**（`git diff` 现取：`numstat 8 5`，其中 5 行＝这 5 行、3 行＝`BT` 定义块）。

## §2 收尾必交②：牙的前后成对读数（`rc` ＋ `traps=`）

| 时机 | 读数 |
|---|---|
| 改前 | `rc=1`；**`SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=22 files=203 sh=114 py=89 diag=76 allow=0`** |
| 改后 | **`rc=0`**；**`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203 sh=114 py=89 diag=76 allow=0`**（`files=203` **不变** ⇒ 件集未被扰动） |

## §3 收尾必交③：**输出逐字守恒**证据

**静态证明（覆盖全部 22 处）**：① `BT='`'` 是**单引号**变量，其值就是一个反引号字节——现取 `printf '%s' "${BT}" | xxd` ＝ **`60`**（＝反引号）⇒ 每个 `${BT}` 展开出的字节与改前那个裸反引号**逐字节相同**；② 逐行 word-diff（§1）显示 5 行上**只有**该替换 ⇒ **判词内容零改动**（改的是**源码形态**）。

**经验证明（覆盖执行到的分支）**：把**写前像**（`pre`）、**修后**（`post`）、以及**把 `${BT}` 全改回裸反引号的复发版**（`mut`）三份**放在同一路径**（`~/w281-scribe/t147/run/guard.sh`，轮换）逐个跑同一输入（`--legs build/MilBridge/tests/PtsPagesProbe/evidence`，`degraded`）：
- **`pre` vs `post`：`DIFFERS`** —— 差 **11 行**；其中 **5 行是 bash 的错误噪声**（`…: 行 632: LightGray: 未找到命令` 之类），另 6 行是被吃掉的判词文本 ⇒ **这正是陷阱的真实危害：它把判词文本改了、还往 stderr 吐错**（不是"只是源码不好看"）。
- **`pre` vs `mut`（把 bash 报的行号归一化后）：`IDENTICAL`** ✓ ⇒ **输出差异完全由「陷阱形态」（＋ 我插入 3 行导致的行号位移）造成，与"我改了输出内容"无关** —— 这是本件最强的因果证据。
- 判词行守恒：**`PTS_GUARD=` 行 `cmp` ＝ `IDENTICAL`**（改前/改后逐字节相同）✓；`post` 输出里能**逐字**找到源码指定的反引号片段（现取：`` `LightGray` ``／`` `RichTextBoxDemo.xaml` ``／`` `FlowDocumentDemo` ``／`` `t145` `` 各 1 命中，`pre` 全 0 命中）；落在**未执行分支**上的那几对（如 `N1`／`N3`／`n4`）由上面①＋②的静态证明覆盖（源码展开值 ＝ 原字节）。

## §4 收尾必交④：两极化（**仓外**夹具 ＋ 牙的 `--root`）

| 变体（仓外 1 件树 `~/w281-scribe/t147/fixroot/`） | 牙读数（现取） |
|---|---|
| **把其中一处改回"双引号内反引号"**（`mut` ＝ 修后源码把 `${BT}` 全改回裸反引号） | **`rc=1`**；`SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=22 …`；**逐条点名** `SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/pts-pages-guard.sh line=635 col=284`（另 21 条同形；`file:line:col` **三件齐**）✓ |
| **再改回来**（`post` ＝ 修后源码） | **`rc=0`**；`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 …` ✓ |
| 夹具说明 | 1 件树需放低件集下限 ⇒ 用牙**自身提供**的 `QT_MIN_FILES=1`／`QT_MIN_TOOLS=0` ＋ `--anchors off`（`aT` 该三枚是牙的**常规旋钮**，用途即夹具）；**夹具树、变体副本全在仓外**，仓内**零临时件** |

## §5 收尾必交⑤：`--selftest` 前后成对（**开工自己现取**的基线）

| 时机 | 读数 |
|---|---|
| **开工自取基线**（不是派单给的值） | **`PASS pass=80 fail=0`**（守卫 `265b9d6b72853749`；与 `t145` 交出的值一致） |
| 改后 | **`PASS pass=80 fail=0`**（**未低于基线**；无期望值改动、无新腿） |
| 写前像同跑（对照） | `PASS pass=80 fail=0`（⇒ 本件对自测**零影响**，符合"只改源码形态"） |

## §6 收尾必交⑥：`degraded` 判词行逐字相同

- **`PTS_GUARD=` 判词行**：改前/改后 **`cmp` ＝ `IDENTICAL`** ✓（现取：`PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=degraded`，`rc` 两侧同为 **1**）。
- 整份 `degraded` 输出的 11 行差异**全部**由「bash 错误噪声消失 ＋ 被吃的反引号文本归位」解释（§3 的 `pre vs mut` 因果证据）⇒ **裁定三十四 (b) 射程内无改动**。

## §7 收尾必交⑦⑧：载体自证 ＋ 成因判定

- **成因判定（如实记）**：**是"新增判词文本里带反引号（markdown 式标记／命令写法）＋ 落在双引号 `echo` 内"**，**不是**"刻意 `echo "… \`x\` …"` 想输出字面反引号"。证据：22 个命中全部落在**中文判词的强调／名指物**处（`LightGray`／`RichTextBoxDemo.xaml`／`FlowDocumentDemo`／`n4`／`N1`／`N3`／`cannot`／`t145`），且**陷阱真的执行了**（bash 报 `LightGray: 未找到命令` ×5 行、判词文本被吃）⇒ 作者（本席 `t145`）写的是"给人看的 markdown 标记"，**不是**"想让反引号出现在输出里"。
- **同族复发（如实记）**：本件是 `t106`（立"禁 `eval`"禁令与命名变量形制）之后、`t136`（同类中招并审计一次）之后的**又一次同类复发**（本席在 `t145` 里**边审边引**却仍再次引入 22 处）。**复发根因写死**：**判词文本用 markdown 风格写、又直接塞进双引号 `echo`** —— 只要不引入"把判词当作**字面模板**"的机制（如统一 `printf '%s\n'` ＋ 单引号 heredoc／变量拼装），它就会**反复**出现。⇒ 建议（不在本件写域，仅建议）：把"**判词模板一律经单引号变量／`${BT}` 类变量拼装**"写进纪律族，并在**每次改 `tools/**` 判词**时先跑本牙。
- **牙齿（收工现取）**：`shell-quote-trap-check.sh` `rc=0 traps=0`；`pts-pages-guard.sh --selftest` `PASS 80/0`；`REPORTID=PASS files=271 ids=2208 declared=224`；`DEFREG=PASS declared=224 route_ids=224` ＋ `DECLDRIFT=0 keys=-`。
- **覆盖面／`cell=#1`**：守卫件**在覆盖面内**（现取 `infp.sh list | grep -c 'pts-pages-guard.sh'` ＝ **1**）⇒ 按第 `28` 条本应登记；派单硬约束**明令不碰** `HANDOFF-NEXT.md` 的 `cell=#1`（队长收口）⇒ **本件有意未登记**；指纹本席现取 ＝ `0399b5be8f3cb07f30d374b9faada20c26cce3ac8d0359dba90623ac07ce26cd`。
- **未做／`NOINFO`**：① 未跑整趟门禁／构建／跑腿／显示位；② **未**在**其他件**上做同类审计（本件只修 `pts-pages-guard.sh`；牙现取 `files=203` 里**其余件 0 命中** ✓ ⇒ 无他件待修）；③ 未把"判词模板机制"落成代码（**不在写域**，只给建议）；④ 未复核派单给的 22 条 `file:line:col` 之外的任何清单（位点系本席**自己现取**，与派单逐条一致 ✓）。
- **件态（收尾必交①）**：`pts-pages-guard.sh` `265b9d6b72853749`／1301 行 ⇒ **`a37f8330a593c3ae`**／**1304** 行；`numstat 8 5`（**删行 5**，逐行为 §1 的 5 行）；写前像 `~/w281-scribe/t147/bak/pts-pages-guard.sh.pre-t147`（写前 `stat -c %h` ＝ 1、`mode 755` 不变）。

**本件自证**：`head -n -1 build/MilBridge/P1-quote-trap-fix-report.md | sha256sum | cut -c1-16` ＝ 386b7dd58e87d3af（末行不计入自身）
