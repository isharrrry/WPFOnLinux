# W27A · 把「列级闸（`D-G14`）」接进五臂门禁 + 钉住下限 —— **落地报告**

> 车道 **W27A**（本波唯一有写域于 `tline-gate.sh` / `known-red.json` 的车道）｜2026-09-17 17:45–18:0x +0800
> 工程根 = `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜**零 `dotnet`**｜未跑 `verify-all.sh` / `frame-step.sh` / `pc-line-step.sh` / `close-wave.sh`
> 施工件来源 = `#26` W26H 的草稿 `$HOME/w26h/gate-wiring.diff`（`sha16 181336824ddfa7c7`）。**现件与草稿基线逐位相同**（改前 `tline-gate.sh` = `b37a5c9f55ae71a4`，与草稿制作时一致）⇒ **不需要重锚行号**。

---

## §0 结论先行

| 问题 | 结论 |
|---|---|
| 接线做了吗 | **做了**。`tline-gate.sh` `b37a5c9f55ae71a4` → **`59ce84346325eb21`**（增 116 / 删 5 / 7 hunk）；`known-red.json` `84fcfb4f728deead` → **`b7a4ad0907f9d76b`** |
| 钉的下限 | **`judged_min = 615`、`released_min = 194`**（= 现臂日志**实测值本身**，不给余量；真值语料独立复算逐位吻合） |
| 正极性 | **`TLINE_GATE=PASS`** / `rc=0` / `GATE_REASON=all-as-registered`，新机读行 `GATE_COLUMN=PASS state=READINGS-OK …` |
| 反极性 | **4 档全部实测拿到**（退化日志 / `judged_min+1` / `released_min+1` / 删声明），成对读数见 §4 |
| **假绿治住了吗** | **治住了**：同一份退化日志，**改前门禁 `PASS`/`rc=0`，改后门禁 `FAIL`/`rc=1` + `column-gate-regressed`**（§4.1 逐字成对） |
| 零位移 | **机器证**：既有 13 个读取点 **13/13 KEPT**、`RED_BY_FIELD` 原六键 **6/6 KEPT**、`TLINE_GATE=` 行 **16 字段零增删**、全 stdout 除 4 处预期外**逐字节相同**（§5） |
| 世代 | `GEN_KEYS` 三项**逐字节未变**；`entries` 4 条除 `caliber.judgment_version` `/2→/3` 外**逐字节未变**；归一化后**新表 == 旧表**（§6） |
| 🔴 **事故（必须读）** | **我自己的自检脚本一度顺着硬链接改写了仓内 `arm-logs/tab-anchor.log`**，已在 **4 分钟内原地复原**、`ARMLOG_SHA=PASS`。全始末 + 修法见 **§8**。 |

---

## §1 下限的来源与选值理由（**实测，不是估**）

### §1.1 现场重取的读数

命令（**现臂日志，一字未造**）：

```
grep -a -n '^TAB_LINES START ' build/MilBridge/arm-logs/tab-anchor.log | grep -a '判定行='
```

实得（`build/MilBridge/arm-logs/tab-anchor.log:1340`，该日志 sha256 全值见 `known-red.json:generation.arm_logs.tab-anchor` = `574d012a41a3db06…`）：

```
TAB_LINES START 红=0 绿=615 判定行=615 NOINFO=0 NOINFO字形=0(构造性:本列不经字形) 字形释放行=194 非零真值行判定=171 红例=0 NOINFO例=0 对齐=Left 量=R(我方 line.Start) 真值=lineStartOffsetsDip[k] R(v)=Round(v,6,AwayFromZero) 口径=Start≡ParagraphIndent
TAB_LINES START 对账 逐例求和 红=0 绿=615 NOINFO=0 ⇒ 与汇总一致            （同文件 `:1341`）
```

### §1.2 两条**独立**复算（不引述 W26A，自己现算）

**(a) 逐例求和**（`python3` 抽 436 条逐例 `TAB_LINES START <id> 行=N 红=a 绿=b`）：

```
per-case START lines = 436   sum 行= 615   sum 红= 0   sum 绿= 615
per-case OVERFLOWED lines = 288  sum 行= 421
```

**(b) 真值语料**（`tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json`，436 例）：

```
ALL:    lines=615 nonzero=171        ← 与 判定行=615 / 非零真值行判定=171 逐位相同
  latin    lines=421 nonzero=138
  hebrew   lines=154 nonzero=33
  arabic   lines= 40 nonzero= 0
heb+ara:  lines=194 nonzero=33       ← 与 字形释放行=194 逐位相同
hasOverflowed True lines = 22 ; total lines[] entries = 615
```

⇒ **`判定行 615 = 既有 latin 可判定集 421 + 列级闸新释放的缺字形行 194`**，两半都落在真值语料的**上界**上。

### §1.3 为什么钉在**实测值本身**、不给余量

- 本闸治的病是「**放行了但一行没判**」⇒ 任何 `< 615` 都等价于「有一批行**从被判定退回不被判定**」。**给余量 = 允许静默丢掉若干行**，那正是没治住假绿。
- 615 与 194 **同时是本语料的上界**（真值侧 615/194），所以「不小于实测值」不是"过紧的工程余量"，而是**"一个都不许少"这个语义本身**。
- 代价（如实说）：将来**合法地**改变这个数（例如语料扩充、或某列批改走 `NOINFO`）⇒ 门禁会 `FAIL column-gate-regressed`。处置 = 走 `known-red.json:changelog` **重钉**，**不许**为变绿调低下限。补丁消息里已明写两种成因（纪律 30）。
- **不选**"留 1 行余量"「留 5%」这类做法：它们都会让 §4.1 那一档（`字形释放行=0`）之外的部分退化**静默通过**。

### §1.4 ⚠️ 一处**与 W26H 草稿期望值不符**的地方（我按现件为准）

W26H 的矩阵行 ⑦ 把目标形态写成 `… NOINFO=194 字形释放行=194 …`；**现盘真日志是 `NOINFO=0`**（`NOINFO字形=0(构造性:本列不经字形)`——该列**根本不经字形**，所以**零 NOINFO** 才是它对的设计值，与 W25I 的预测 `194 → [46,0]` 的下端 `0` 一致）。
⇒ W26H 的 `post-green` 夹具用了**与落地探针不同的字面**。**我的下限不受影响**（闸只读 `判定行` 与 `字形释放行`，`NOINFO` 仅作披露），但矩阵行 ⑦ 那句话**不可逐字当读数引用**。**本报告的 `GATE_COLUMN=` 行是现件实测的逐字原文。**

---

## §2 正极性（接线 + 已钉下限 + 现臂日志）

```
$ bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs --outdir <out>
rc=0
GATE_COLUMN=PASS state=READINGS-OK arm=tab-oracle-anchor col=START 判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194 非零真值行判定=171 judged_min=615 released_min=194
TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=59ce84346325eb21 judge=t1b3-tline-gate/3 outdir=<out>
GATE_REASON=all-as-registered
```

臂的「读数：」行也自动披露了新列（**零额外改动**，因为补丁把 6 个计数**注入既有 `readings` 字典**）：

```
读数：cases=436  列START·NOINFO=0  列START·判定行=615  列START·字形释放行=194  列START·红=0  列START·绿=615  列START·非零真值行判定=171  判定过=288  结构败=0
```

**上屏实测**（把 stdout 喂给 `verify-all.sh:104`/`:113` 的**逐字** pattern，`head -8` / `head -12`）：

| 趟 | `rc` | 绿分支命中 | 红分支命中 | `head -8` 首行 |
|---|---|---|---|---|
| 改前（原门禁） | 0 | 1 | 0 | `TLINE_GATE=PASS` |
| 改后 正极性 | 0 | **2** | 0 | **`GATE_COLUMN=PASS`** / `TLINE_GATE=PASS` |
| 改后 未声明（今天若抢跑） | 2 | 2 | 2 | `GATE_COLUMN=NOINFO` / `TLINE_GATE=NOINFO` |
| 改后 退化日志 | 1 | 2 | 2 | `GATE_COLUMN=FAIL` / `TLINE_GATE=FAIL` |

⇒ **`GATE_COLUMN=PASS` 在绿屏上可见，而 `verify-all.sh` 一个字都不必改**（W27B 的写域未被碰）。`head -8` 余量充分（此类行最多 2 条）。
`--quiet` 也**不**压掉该行（补丁用 `emit()`= `print`，不是 `say()`；实测 `--quiet` 下 `GATE_COLUMN` 命中 1）。

---

## §3 钉进登记表的形态（唯一声明处）

`build/MilBridge/known-red.json` → `generation.column_gate`（**新增子键，不动顶层块集合**）：

```json
"column_gate": {
  "why": "…列级闸的下限声明。读者 = tline-gate.sh 的 COL_ARM 段…低于下限 ⇒ FAIL column-gate-regressed；本节缺失 ⇒ NOINFO column-gate-undeclared（缺声明 ≠ 通过）…",
  "unit": "行（该列的逐行判定行数）",
  "arms": {
    "tab-oracle-anchor": {
      "column": "START",
      "judged_min": 615,
      "released_min": 194,
      "note": "下限 = 实测值本身…（该日志 sha256 的唯一声明处 = generation.arm_logs[\"tab-anchor\"]，本处不重抄）…"
    }
  }
}
```

**三条设计约束（逐条给依据）**：

1. **不重抄哈希**：`tab-anchor.log` 的 sha256 唯一声明处仍是 `generation.arm_logs["tab-anchor"]`（W26D 落的）⇒ 本处只**引用**，不复制（纪律 49/53）。
2. **不升 schema**：顶层块集合实测 `before == after`（7 个块，零增删）⇒ `schema: tline-known-red/4` 与既有字段表语义不动。**`_FIELDTABLE` 只加了 1 行说明**（纯人读数组，`grep -rn '_FIELDTABLE' --include='*.sh' .` 实测**只有本门禁的注释引用它**，无机器读者）。
3. **不碰 `arm_logs`**：`generation.arm_logs` 五个值**逐字节未变**（§6），核对器 `ARMLOG_SHA=PASS` 复跑通过。

---

## §4 反极性：**4 档，全部实测**（成对读数；沙箱全在 `$HOME`）

沙箱 = `$HOME/w27a-sandbox/`。日志树用**硬链接**（纪律 56：`find -type f` 会跳过符号链接——本件**另做了反证**，见 §7.3）；**凡要改写的夹具一律 `cp`**（见 §8 事故）。**仓内 `arm-logs/**` 在所有极性测试中只读**。

| 档 | 日志 | 登记表 | `rc` | `TLINE_GATE` | `GATE_REASON` | `GATE_COLUMN` |
|---|---|---|---|---|---|---|
| **配对基准 A** | 真日志 | 真表（已声明 615/194） | **0** | `PASS` | `all-as-registered` | `PASS state=READINGS-OK 判定行=615 字形释放行=194` |
| **① B 退化日志** | 汇总行改成 `判定行=421 字形释放行=0 NOINFO=194 非零真值行判定=138`（= 「放行了但一行没判」） | 真表 | **1** | **`FAIL`** | **`column-gate-regressed`** | `FAIL state=READINGS-REGRESSED 判定行=421 字形释放行=0` |
| **② D `judged_min+1`** | 真日志 | `judged_min=616` | **1** | **`FAIL`** | `column-gate-regressed` | `FAIL state=READINGS-REGRESSED … judged_min=616` |
| **③ E `released_min+1`** | 真日志 | `released_min=195` | **1** | **`FAIL`** | `column-gate-regressed` | `FAIL state=READINGS-REGRESSED … released_min=195` |
| **④ F 删声明** | 真日志 | 删掉 `generation.column_gate` | **2** | **`NOINFO`** | **`column-gate-undeclared`** | `NOINFO state=DECL-GAP` |
| （附带 C） | 删掉**汇总行**（探针没落这个字段） | 真表 | **2** | `NOINFO` | `column-gate-undeclared` | `NOINFO state=DECL-GAP` |

### §4.1 ★ 治假绿的那一档：**同一份日志，改前 `PASS` / 改后 `FAIL`**（本件最核心的成对读数）

```
OLD gate（b37a5c9f55ae71a4，草稿前原件） on degen1 : rc=0  TLINE_GATE=PASS  GATE_REASON=all-as-registered
NEW gate（59ce84346325eb21，本件）        on degen1 : rc=1  TLINE_GATE=FAIL  GATE_REASON=column-gate-regressed
```

规范化 diff（只把 outdir/自 sha/版本号抹平）后，**改前 stdout 与「放行且全绿」的 stdout 逐字相同**（= `#26` 矩阵行 ③ 的假绿），改后 stdout 多出的正是点名行：

```
  FAIL(col)        tab-oracle-anchor/START :: **列级闸退化**：判定行=421 < 声明下限 615 ⇒ 有一批行不再被判定。⚠️ 两种成因必须人工裁定：① 红检测被放松（有人收回/收窄了放行面）；② 该列有一批行改走了 NOINFO（例如 `格式化抛…` / `行数不符`）—— 后者是**装置/口径**问题，不是被测件回归（纪律 30）。
  FAIL(col)        tab-oracle-anchor/START :: **列级闸退化**：字形释放行=0 < 声明下限 194 ⇒ 有一批行不再被判定。⚠️ …
GATE_COLUMN=FAIL state=READINGS-REGRESSED arm=tab-oracle-anchor col=START 判定行=421 红=0 绿=421 NOINFO=194 字形释放行=0 非零真值行判定=138 judged_min=615 released_min=194
TLINE_GATE=FAIL …
GATE_REASON=column-gate-regressed
```

**`NOINFO` 一律 `rc≠0`**（实测 2）⇒ 不许当绿。

---

## §5 零位移机器证

### §5.1 既有读取点：**一个都没删/放宽**

两种口径都报（口径不同、结论一致）：

| 口径 | 定义 | 实得 |
|---|---|---|
| **解析点 + 认臂点**（= `#26` W26H 说的「13」） | `detect_arm` 的 grep 2 处（改前 `:160`/`:161`）+ 解析 regex 11 处（`:387/389/391/394/395/405/406/409/411/505/512`） | **13 / 13 KEPT，丢失 0** |
| **含 `TAB_LINES` 的全部代码行** | 改前 18 行含 `TAB_LINES`（2 注释 + **16 代码**），逐行按 `strip` 后比对 | **18 / 18 KEPT，丢失 0** |

逐行原文（改前行号 + 内容）见 `$HOME/w27a-run/proof/zero-displacement.txt`。样例（改前后**逐字节相同**）：

```
L160  if grep -aq '^TAB_LINES 文件=' "$f" 2>/dev/null; then
L387  f = first(r"^TAB_LINES 文件=(.+)$", t)
L389  tot = first(r"^TAB_LINES 合计 cases=\d+ 判定过=\d+ 结构败=\d+ 不可比\(缺字形\)=\d+", t)
L394  rcv = first(r"^TAB_LINES 退出码=(\d+)", t)
L405  rec["unregistered_probe"] = [l.strip() for l in t.splitlines() if l.startswith("TAB_LINES UNREGISTERED ")]
L411  mm2 = re.match(r"^TAB_LINES FAILCASE (\S+) :: (.*)$", l)
L512  mm = re.match(r"^TAB_LINES KNOWN-RED (\S+) :: (.*)$", l)
```

**5 条删除行逐条判定（有没有放宽？）**：

| 删除行（改前） | 替换为 | 判定 |
|---|---|---|
| `# T1b3 … t1b3-tline-gate/2）` | `/3` + 3 行说明 | **仅版本可见性**（纪律 15/26） |
| `JUDGE_VER="t1b3-tline-gate/2"` | `/3` | 同上 |
| `if reg_err or entry_gen_bad or noinfo_arms or n_entry_noinfo:` | 尾部**追加** `or col_noinfo` | **加严**（更多 ⇒ NOINFO） |
| `elif unregistered or n_gone or n_drift:` | 尾部**追加** `or col_fail` | **加严**（更多 ⇒ FAIL） |
| `"noinfo_arms": arm_noinfo}, f, …` | 尾部**追加** `"column_gate": {…}` | 机读读数**加键**（`gate-readings.json` 实测键集合 `+['column_gate']`、删 0） |

⇒ **没有一条读取点被删、被改、被放宽。**

### §5.2 `RED_BY_FIELD`

```
before: ['逐行记账·结构','Collapse明细全等','宽度超差行数','Extent余差条数','结构败','判据状态']   (6)
after : ['…同上 6 项…','列START·红']                                                        (7)
kept = 6/6 ; 新增 = ['列START·红']
```

新键 `列START·红: pos` 的作用 = 让「**已裁定的新列红**」**可登记**（`entries[]` 通道），与既有列的红**可分辨**（纪律 18 的四元组最后一项）。**今天没有条目用它** ⇒ `registered=4` 不变。

### §5.3 `TLINE_GATE=` 行：**16 字段零增删，除 2 项外逐项相同**

```
改前：TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2 outdir=/home/links-dev/w27a-run/before
改后：TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=59ce84346325eb21 judge=t1b3-tline-gate/3 outdir=/home/links-dev/w27a-run/final/pos
```

| 字段 | 改前 | 改后 | 判定 |
|---|---|---|---|
| `arms` `red` `green` `noinfo_arm` `registered` `unlocated` `drift` `gone` `unregistered` `caliber` `generation` `tree_gen` `saved_shim` | 5 / 2 / 3 / 0 / 4 / 1 / 0 / 0 / 0 / OK / #23 / same / e89fed55fd8e32bc | **完全相同** | **SAME ×13** |
| `gate` | `b37a5c9f55ae71a4` | `59ce84346325eb21` | DIFF（**门禁自身 sha**，改了文件必变） |
| `judge` | `t1b3-tline-gate/2` | **`t1b3-tline-gate/3`** | DIFF（**预期**：判据面扩大 ⇒ 按纪律 15/26 必须推版本） |

字段集合**零增删**（16 → 16）。`GATE_REASON` 正极性下**逐字不变** = `all-as-registered`。

### §5.4 全 stdout 归一化 diff：只剩 4 处预期改动

```
① banner           (t1b3-tline-gate/2) → (/3)
② 门禁自身          b37a5c9f55ae71a4 → 59ce84346325eb21
③ 臂读数行          尾部追加 列START·{NOINFO,判定行,字形释放行,红,绿,非零真值行判定} 6 个字段（既有字段逐字保留）
④ +1 行            GATE_COLUMN=PASS state=READINGS-OK …
```

**除此之外，两趟 stdout 逐字节相同**（含 `==================== 结论 ====================` 之后的全部点名行）。

---

## §6 世代与登记表：三件不动、`entries` 只推版本

`python3` 逐字段比对（`$HOME/w27a-run/proof/registry-diff2.txt`）：

```
GEN_KEYS 三项逐字节未变 : True          （instr_run_sh 3e513e88… / instr_program_cs 2e458928… / instr_shim e89fed55fd8e32bc…）
generation.arm_logs 逐字节未变 : True
generation 差异键 = ['column_gate']      （唯一新增子键）
entries 除 caliber.judgment_version 外逐字节未变 : True
  entry[0..3] 差异键=['caliber']，caliber 差异子键=['judgment_version'] : t1b3-tline-gate/2 → t1b3-tline-gate/3
changelog: 11 → 12 条；after[1:] == before ? True（新条目 rev=12 / by=W27A）
_FIELDTABLE: 32 → 33 行；恰由插入 1 行得到 ? True（位置 index=18）
顶层块集合 before == after（7 块，零增删）⇒ schema 无需升版
★ 归一化（抹掉上述 4 项已知改动）后  new == old ?  True
```

`tree_gen=same` 仍成立 ⇒ **不重取臂、不重钉世代三项**（预登记 §3 硬时序满足：臂日志是 `#26` 已重取的现件）。

**`pending.open[0]` 已改写**（旧措辞「RTL 那一半在本机零信号」只对**依赖字形**的列成立）：改成"依赖字形的列仍零信号；`Start` 一列在 RTL 例上**由 0 行 → 33 行**"，并附全臂读数 `判定行 421→615 / 字形释放行=194 / 非零真值行判定=171` 与真值侧独立复算（`hebrew 154 + arabic 40 = 194`，非零 `33`）。

**为什么推 `judgment_version`**：门禁今天**不比较**该字段（`:464-465` 只比三个 `GEN_KEYS`）⇒ 不推**不会**变红；但它的语义就是「这条读数属于哪一版判据」——改了判据不推它 = 自己让自己陈旧（纪律 15/26 + 53）。**预登记 §2 已把它列为预期位移**（`/2 → /3`，4 条）。

---

## §7 机读行与自检

### §7.1 新机读行的形状（逐字）

```
GATE_COLUMN=PASS state=READINGS-OK arm=tab-oracle-anchor col=START 判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194 非零真值行判定=171 judged_min=615 released_min=194
```

- 结论值**取三态** `PASS|FAIL|NOINFO`（`state=` 另放细粒度 `READINGS-OK|READINGS-REGRESSED|DECL-GAP|NONE`）⇒ **零改动**就被 `verify-all.sh:104/113` 的既有 grep 捞到。
- ⚠️ **该行只描述「读数面完不完整」，不是「该列有没有红」**：该列的红走**既有** `entries[]`/`UNREGISTERED` 通道（可登记、可点名、不改 rc），条数印在同一行的 `红=` 字段里 ⇒ `GATE_COLUMN=PASS` 与 `TLINE_GATE=FAIL` **可以同时出现**（这是刻意的，见补丁注释）。
- ⚠️ **陷阱（实测）**：`^TAB_LINES START ` 是**逐例行与汇总行的共同前缀**——真日志里 **438 行**以它开头而**只有 1 行**是汇总行，且逐例行**也**含 `红=`/`绿=`。补丁用 `re.M` + 行首 `TAB_LINES START 红=` 锚定并**要求命中恰 1 行**（实测 `grep -a -c '^TAB_LINES START 红='` = **1**；`tab-zero`/`tab-rtl` = **0** ⇒ 不误命中）。

### §7.2 最小自检命令（实测）

命令（`$HOME/w27a-run/column-selftest.sh`，`bash -n rc=0`，两半：正极性 + 退化日志，**夹具用 `cp` 且自证不同 inode**）：

```
$ bash ~/w27a-run/column-selftest.sh
半① rc=0（要求 0）  GATE_COLUMN=PASS/READINGS-OK 命中=1（要求 1）
半② rc=1（要求 1）  GATE_REASON=column-gate-regressed 命中=1（要求 1）  TLINE_GATE=FAIL 命中=1（要求 1）
COLUMN_SELFTEST=PASS
$ echo $?
0
```

**单行版**（只要正极性证据）：

```bash
bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs --outdir "$(mktemp -d)" \
 | grep -cE '^GATE_COLUMN=PASS state=READINGS-OK arm=tab-oracle-anchor col=START 判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194 非零真值行判定=171 judged_min=615 released_min=194$'   # ⇒ 1
```

### §7.3 纪律 56 反证（顺带实测）：符号链接会让日志树"消失"

```
两棵只差「有无 column_gate」的沙箱树（日志 = 硬链接，nlink=5），用 OLD gate 跑：
  ✅ cmp IDENTICAL（sha16 6527bdb7e9594c8f）⇒ 未知键对判定零影响
把同一批日志改成**符号链接**再跑：
  rc=2  TLINE_GATE=NOINFO  GATE_REASON=noinfo-arms   ⇒ find -type f 全漏，五臂全无读数
```

⇒ 纪律 56 不是形式主义：**只读的日志树可以硬链接，符号链接会让门禁直接 `NOINFO`。**

---

## §8 🔴 事故与复原（**如实披露，不许埋在附录**）

### §8.1 发生了什么

| 时刻（+0800） | 事件 |
|---|---|
| 17:50:58.626 | 我写好自检脚本 `$HOME/w27a-run/column-selftest.sh`（第 2 版，夹具生成改用 `python3 open(p,"w")`） |
| 17:50:58.805 | 脚本**第一次运行**：它用 `ln -f` 把仓内 5 支臂日志**硬链接**进 `$(mktemp -d)/degen/`，再用 `python3 open(p,"w")` 把 `degen/tab-anchor.log` 改成退化形态 ⇒ **`open(p,"w")` 是原地截断**，于是**顺着共享 inode 改写了仓内真件** `build/MilBridge/arm-logs/tab-anchor.log`（inode 5149994，当时 nlink=2） |
| 17:51:44 | 我做"我开工后的仓内改动"扫描时**发现** `arm-logs/tab-anchor.log` mtime 异常、sha16 `574d012a…` → `3126bd2133b20a02` |
| 17:52:10 | **原地复原**：`cp /home/links-dev/wfp-runs/w26a/colgate/tab-anchor.log build/MilBridge/arm-logs/tab-anchor.log`（`cp` 到已存在路径 = 原地写 ⇒ **inode 不变**，5 个共享名字**同时**复原） |
| 17:52:1x | `arm-log-sha-check.sh` 复跑 ⇒ **五支全 `PASS`**、`ARMLOG_SHA=PASS … pass=5 fail=0 noinfo=0`；字节数回到 117887 |

### §8.2 复原的取证（逐位）

```
pristine src  = /home/links-dev/wfp-runs/w26a/colgate/tab-anchor.log   sha16 574d012a41a3db06
before restore: inode=5149994 nlink=5 sha16=3126bd2133b20a02
after  restore: inode=5149994 nlink=5 sha16=574d012a41a3db06   bytes=117887
declared:                                          574d012a41a3db06bed0033ebea13ac79d7cbf5890699d88ff6a8fec1fc71446
ARMLOG_ARM=tab-anchor PASS decl=574d012a41a3db06 live=574d012a41a3db06
ARMLOG_ARM=tline/tab-zero/tab-rtl/textlineproto 全 PASS
```

`inode 5149994` 的 5 个名字（`find -inum`）：仓内 `arm-logs/tab-anchor.log`、`~/wfp-runs/w26a/final5/tab-anchor.log`（W26A 自己的产物）、我的 3 个沙箱链接 ⇒ **原地 `cp` 一次全复原**（含被我一并波及的 W26A 的 `final5` 那份）。

复原源的**可靠性**：内容 `574d012a41a3db06…` 在全盘有 **6 份独立的 `cp` 副本**互证（`~/wfp-runs/w26a/` 下 `colgate`/`confirm`/`final`/`final2`/`final3`/`final4`，均 117,887 B、sha16 全同），且与 `known-red.json:generation.arm_logs` 的声明值逐位相同 ⇒ **不是"我觉得它原来长这样"**。

### §8.3 影响面（诚实评估）

| 项 | 判定 |
|---|---|
| **我的读数有没有被污染** | **没有**。事故在 17:50:58.805；我此前的读数全部早于它（`before` 17:48:11、`pos1` 17:49:29、极性 A–F 17:50:11、未知键 17:50:31）。事故后我又**整套重跑了一遍**（§2/§4 引的即重跑值）。 |
| **内容有没有永久损失** | **没有**。内容 sha 回到声明值，逐位相同；五支臂核对器 `PASS`。 |
| **残留位移** | **只有 mtime**：`arm-logs/tab-anchor.log` 的 mtime 由 **14:31**（分精度，来自我 17:47 的 `ls -la`；**秒级原值未取到**，因为 inode 的 mtime 已被复原动作覆盖）变为 **17:52:10**（内容不变）。后果评估：弱配对判据要求 `日志 mtime ≥ 世代被测件 mtime`（shim 00:13）⇒ **仍满足**，门禁 `PASS` 实测通过；`--logdir` 的 `sort -rn` 每臂只有一份日志 ⇒ 无影响。**若主控按纪律 16 要求"臂日志 mtime 也属于证据"，这是本件唯一需要裁定的位移。** |
| **是不是我写的文件** | **是**（`ln -f` + 原地改写），**不是别的车道**。全责在我。 |

### §8.4 修法（已落地并自证）

自检脚本的夹具生成由 `ln -f` 改成 **`cp -p`**，并新增**同 inode 自证**（同 inode 即 `FAIL` 退出）；脚本头写明事故与理由。**修后实测**：

```
跑自检前 arm-anchor.log = 574d012a41a3db06 (inode 5149994)
跑自检后 arm-anchor.log = 574d012a41a3db06 (inode 5149994)
✅ 自检不改真件（sha 与 inode 双证）        COLUMN_SELFTEST=PASS
```

### §8.5 给波尾/后续车道的建议（写进纪律候选）

> **纪律候选（`#26` 纪律 56 的补刀）**：`#26` 纪律 56 只说「沙箱树要**硬链接**（否则 `find -type f` 会跳过符号链接）」——那是针对**只读**的日志树。
> **凡是要"改写"的夹具，一律 `cp`（独立 inode），绝不 `ln -f` + 原地写**：`python3 open(p,"w")` / `cp` / `truncate` / `tee` 都是**原地写**，会顺着共享 inode 打穿到仓内真件；`sed -i` 走 temp+rename 反而"安全"（它会**断链**，于是夹具与真件脱钩——但那样又会**静默测不到真件**）。
> 最小自证：造完夹具立刻 `stat -c %i` 比对，不同 inode 才继续。

**三个机制的实测对照**（`$HOME` 里 `ln` 一对硬链接再分别动手，不碰仓）：

```
初始：orig ino=4194571  link ino=4194571（同一 inode）
① python3 open(link,"w").write("BBB")  ⇒ orig="BBB" ino=4194573 / link="BBB" ino=4194573
                                        ✅ 原地写**打穿**到另一个名字（= 本件事故的机制）
② sed -i 's/AAA/BBB/' link             ⇒ orig="AAA" ino=…571 / link="BBB" ino=…572
                                        ⇒ **断链**：真件安全，但**夹具与真件脱钩**（于是那次测试测的不是真件）
③ cp -p link fixture（本件最终采用）    ⇒ 独立 inode ⇒ 改夹具**打不到**真件；配合 `stat -c %i` 自证
```
⇒ 结论：`sed -i` 不是"更对"，只是"另一种错"——**要改写的夹具必须 `cp`**。

---

## §9 风险清单（逐条）

| # | 风险 | 会不会 | 依据 / 处置 |
|---|---|---|---|
| 1 | 接线弄坏既有绿读法 | **不会** | §5 四组机器证；全 stdout 除 4 处预期外逐字节相同 |
| 2 | 接线后门禁 `NOINFO` | **会，且是设计**：若在「钉声明」之前接线 ⇒ `NOINFO column-gate-undeclared`（实测 `rc=2`，见 §4 F 档 / `predecl` 趟） | 本件已同趟钉好 ⇒ 现盘是 `PASS` |
| 3 | 接线后门禁 `FAIL` | **会**，两种：① 声明下限高于实测 ⇒ `column-gate-regressed`（**所以下限必须用实测值**）；② 释放列真红 ⇒ 走**既有** `UNREGISTERED`（**这一条今天就有牙，不依赖本件**） | §4 ②③ |
| 4 | 与在册红冲突 | **不会**：今天 4 条在册红 = 3 条 `tline` + 1 条 `tab-oracle-zero 判据状态`，**都不在 `tab-anchor`、也不在 `Start` 列**；`COL_ARM` 只声明 `tab-anchor` ⇒ 既不冲突也不误吞 | `known-red.json:entries`；`registered=4` 未变 |
| 5 | 把**装置/口径**问题误报成"列级闸回归" | **有残余**（`judged_min` 是单侧下限）⇒ 补丁消息**明写两种成因**、要求人工裁定；取证时**同时看** `NOINFO字形=`/`NOINFO=` 与 `格式化抛` 行。**不许**据一条 `FAIL` 就断言"有人收窄了红检测" | 纪律 30 |
| 6 | `verify-all` 的回显被新行挤掉（`head -8`） | **不会**：实测此类行 ≤2 | §2 附表 |
| 7 | `head -8` 未来饱和 | **需留意**：若再添几颗自报牙齿，`GATE_COLUMN` 可能被截掉 ⇒ 建议波尾复核它**确在绿屏上** | 同上 |
| 8 | 我动了 `verify-all.sh`？ | **没有**（W27B 的写域）。`verify-all.sh` 的 mtime/sha 变化**不是本车道**（实测 17:52:16 有他车道写入；本件对它**零改动**，且不需要改——§2 的上屏是"零改动捞到"） | `find -newermt` 归因 |
| 9 | `gate-readings.json` 的**下游读者** | **无**：`grep -rn --include='*.sh' --include='*.py' -- 'gate-readings' .` 实测**只有本门禁自己**（写它）。新增键是纯加法 |
| 10 | 🔴 **臂日志被误写** | **已发生并已复原**（§8）。残留 = mtime 位移一项，**请主控裁定是否接受** |
| 11 | 探针件比臂日志新 | **事实**：`build/MilBridge/tests/CoverageProbe/Program.cs` mtime **14:48:13**（sha16 `2477901979795979`）**晚于**臂日志（14:28–14:31）⇒ **现盘日志是"更早一版探针"的产物**。门禁**不哈希**该文件（不在 `GEN_KEYS`里，弱配对只用 shim mtime）⇒ 判定不受影响；但**"下限属于哪一版探针"这一点取不到** ⇒ 记 `NOINFO`（纪律 35 同族） |
| 12 | 下限把将来的**合法**口径变化判红 | **会**（预期）。处置 = 重钉 `changelog` + 下限，**不许**调低到"看着舒服" | §1.3 |

---

## §10 `NOINFO` 清单（本件**没取到 / 取不到**）

1. **探针版本与下限的配对**：现盘 `CoverageProbe/Program.cs`（14:48）比臂日志（14:31）新 ⇒ "这批读数由哪一版探针产出"**取不到**（§9-11）。
2. **真树上两趟门禁的稳定性**：只跑了一次正极性（不是连跑两趟逐字节比）⇒ **未取到**（`#26` 已给过连跑两趟相同的先例）。
3. **`verify-all` 端到端**：属主控波尾动作，本件**未跑**（纪律 51）⇒ `verify-all` 里 `[10] tline-gate` 那一格的新读数**未取到**。
4. **其余四支臂的列级读数**：`tab-zero`/`tab-rtl` 语料**无** `lineStartOffsetsDip`（`0/86`、`0/84`）⇒ 无此列；`tline`/`textlineproto` 无此列。`COL_ARM` 只声明 `tab-anchor`。
5. **`hasOverflowed` 列的下限**：本件**只接 `Start` 一列**（`OVERFLOWED` 汇总行存在但本件不读它）⇒ 该列**仍无下限牙**（`judged_min` 未覆盖）——**这是射程外，登记为后续候选**。
6. **汇总行与逐例行不一致的情形**：本闸只读**汇总行**；真日志自带 `TAB_LINES START 对账 … ⇒ 与汇总一致`，而**门禁不读那条对账行** ⇒ 若有人只改逐例行、不改汇总行，本闸**抓不到**（射程缺口，如实报）。
7. **RTL 其余列 / `tab-zero`/`tab-rtl` 对齐列 / `D-G12`**：仍无信号（`#26` W26H §8 已列，本件不扩）。
8. **事故前的原始 mtime**：`arm-logs/tab-anchor.log` 的原始 mtime 只能从 `~/wfp-runs/w26a/colgate/tab-anchor.log`（`cp -p` 保 mtime）反推，**本件未取**。

---

## §11 复算台账（纪律 49：一律现场算）

| 件 | 改前 sha16 | 改后 sha16 | 字节 |
|---|---|---|---|
| `build/MilBridge/tools/tline-gate.sh` | `b37a5c9f55ae71a4` | **`59ce84346325eb21`** | 40,181 → **49,263** |
| `build/MilBridge/known-red.json` | `84fcfb4f728deead` | **`b7a4ad0907f9d76b`** | 35,310 → **41,012** |
| `build/MilBridge/arm-logs/tab-anchor.log` | `574d012a41a3db06` | **`574d012a41a3db06`（复原后逐位相同）** | 117,887 → 117,887 |
| 其余四支臂日志 | — | **逐字节未变** | — |
| `verify-all.sh` | （非本车道） | **本件零改动**；现场 `9c49ce621aadcd99`（他车道在写） | — |

`inputs_fp`（照抄 `close-wave.sh` 的 `fp_inputs()` 管道现场算）：

```
0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8   ← 与 CURRENT-STATE.md 的 #25/#26 声明逐位相同
```

`generation` 三项：`instr_run_sh 3e513e88…` / `instr_program_cs 2e458928…` / `instr_shim e89fed55fd8e32bc…` **逐字节未变**。

`find -newermt '2026-09-17 17:45'` 归因（我开工后）：
```
17:46:46  docs/WAVE27-PREREGISTRATION.md        ← 主控（派单）
17:48:32  build/MilBridge/tools/tline-gate.sh   ← 我（接线）
17:49:26  build/MilBridge/known-red.json        ← 我（钉下限）
17:50:29  build/MilBridge/tools/defect-registry-declared.tsv  ← W27D
17:51:42  build/MilBridge/tools/defect-registry-check.sh      ← W27D
17:52:10  build/MilBridge/arm-logs/tab-anchor.log            ← 我（事故后复原，内容=声明值）
17:52:16  verify-all.sh                                       ← W27B
```
⇒ 我的写域 = **`tline-gate.sh` + `known-red.json` 两件 + 一次臂日志复原**；其余逐条归因到他车道。

---

## §12 我更正/推翻了什么（含自查）

1. **W26H 草稿的接线行数记错了**：其报告 §4.5 写「增 **106** 行 / 删 5 行」，**实测应用后是「增 116 / 删 5」**（`680 → 791` 行；`grep -c '^+' diff` = 117 减去 `+++` 表头 = 116）。差异 10 行 = 补丁里若干行被它自己漏数（多为注释块）。**不影响结论**（0 条读取点被动），但引用行数时应以本件的现场 `diff` 为准。
2. **W26H 矩阵行 ⑦ 的 `NOINFO=194` 与现件不符**：现盘真日志是 `NOINFO=0`（该列构造性不经字形）。见 §1.4。
3. **W26H 说的「13 个读取点」口径偏窄**：按"含 `TAB_LINES` 的**代码行**"应报 **16**（另 2 行注释）。两种口径都不丢失（§5.1 都给了）。**13 = `detect_arm` 2 + 解析点 11**，与它的数一致，只是没写清口径。
4. **`#26` 纪律 56 需要补刀**（本件事故直接推出，见 §8.5）：硬链接要求**只适用于只读的日志树**；**要改写的夹具一律 `cp`**。
5. **草稿的 `COL_ARM` 只覆盖一支臂**这一射程缺口**依然成立**：`hasOverflowed` 列有汇总行（`TAB_LINES OVERFLOWED …`）却**没有下限牙**（§10-5）——留给后续波次。

---

## §13 交付件（波尾可直接用）

| 路径 | 说明 |
|---|---|
| `build/MilBridge/tools/tline-gate.sh` | **落地件**（`59ce84346325eb21`） |
| `build/MilBridge/known-red.json` | **落地件**（`b7a4ad0907f9d76b`，含 `generation.column_gate` + `changelog` rev 12） |
| `build/MilBridge/W27A-report.md` | 本文件 |
| `$HOME/w27a-backups/{tline-gate.sh,known-red.json}.before` | 改前全份备份 |
| `$HOME/w27a-run/final/*.stdout` | 正极性 + 反极性四档 stdout（含 `rc`） |
| `$HOME/w27a-run/proof/*` | 零位移 / 登记表逐字段 / `TLINE_GATE` 字段对照 三份机器证 |
| `$HOME/w27a-run/column-selftest.sh` | 最小自检（正极性+退化日志两半，`COLUMN_SELFTEST=PASS`） |
| `$HOME/w27a-sandbox/` | 极性沙箱（`logs`/`degen1`/`degen2`/`treeA`/`treeB`/`reg_*.json`/`gate-old.sh`） |
