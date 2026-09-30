# T-A49 · P1 尾波2 `#82` · E5 重取臂（五臂换代）＋ 登记同步 —— 完成报告

> 车道：**实现/装置（本轮唯一写者）**。载体本件 = `build/MilBridge/P1-tail2-retake-report.md`。
> 写域（逐字）：`build/MilBridge/arm-logs/**`（换代）／`build/MilBridge/known-red.json`（`generation` 三项 ＋ `arm_logs` 五项 ＋ `evidence_log_sha256` ＋ `entries[*].caliber.instr_shim` ＋ `changelog`）／新建本载体。
> `build/MilBridge/tools/retake-arms-w23.sh` **未改**（在册装置体例已够用，无需修 ⇒ 无两极化义务）。

---

## 0. 一句话结论

**目标达成**：`TLINE_GATE=PASS … tree_gen=same drift=0 gone=0 unregistered=0`（`rc=0`）—— 五臂读数**随树换代重取**、世代重钉齐。
**五臂红/绿结论与在册逐字相同**（tline 红、tab-oracle-zero 红、其余三臂绿）⇒ **无结论变化 ⇒ 不触发「报停」条款**。
**但**：本趟重取必然使 `COLUMN-FLOOR` 转红（冻结块 `#80` 的 5 行 `# ARM-LOG-SHA` 未同趟重冻结）—— 该冻结件在**本车道写域之外**（改它会连带要求改 `docs/CURRENT-STATE.md:9` 的 `BASELINE-FROZEN`，属**队长重冻结批**）⇒ 本件**如实具名**，**未**越界重冻结、**未**掐红。

---

## 1. 起手现取（前置 / 在册装置 / 缺口现场）

### 1.1 唯一残余失败的现场

```
$ bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs      # 重取前
TLINE_GATE=NOINFO arms=5 red=1 green=0 noinfo_arm=4 registered=3 unlocated=1 drift=0 gone=0 unregistered=0
            caliber=OK generation=#23 tree_gen=advanced saved_shim=e2fa9ec9be1a6cf1 gate=747c078dbf040862 judge=t1b3-tline-gate/7
GATE_REASON=noinfo-arms                                                                  rc=2
```

- 四支**弱配对**臂（三支 `tab-*` + `textlineproto`，日志不自报仪器 sha）⇒ `caliber=UNVERIFIABLE` ⇒ **NOINFO**（口径过期保护，**设计如此**：树已前进就无法证明日志属于登记世代 `#23`）。
- `tline` 是**强配对**（日志自报 shim `921ba9c65e9fb3be` = 登记世代）⇒ `caliber=OK-declared`，仍红（在册红）。

### 1.2 根因：树 shim 换代（合法产品位移）

| 件 | 重取前现盘 sha16 | 说明 |
|---|---|---|
| `build/shims/PresentationCore.HbTextLine.cs` | **`e2fa9ec9be1a6cf1`** | 300,974 B，mtime `2026-09-30 15:45:16 +0800`；`git log` 显示改它的是提交 **`fe4c471`**「P1 尾波2 (#82)：T-A29/T-A30 行模型元素安全起点」—— `git show --numstat` = **`113  17`**（真代码改动，非注释/空白） |
| 登记世代 `generation.instr_shim` | `921ba9c65e9fb3be` | 停在 `2026-09-28` 的世代 ⇒ `tree_gen=advanced` |
| `build/MilBridge/run.sh` | `711f39f468f61cc8` | **未变** |
| `build/MilBridge/tests/HbTextLineParity/Program.cs` | `dda989bb024d20e6` | **未变** |

⇒ 世代绑定三项之一（`instr_shim`）变 ⇒ 按纪律 34/59 **必须重取五臂**（五臂宿主都把 shim 源编进去：`run.sh` 的 harness / `CoverageProbe` / 契约限时原型）。

### 1.3 在册装置体例（起手现读）

- `retake-arms-w23.sh`：`OUT=${ARMS_OUT:-$HOME/wfp-runs/arms23}`（env 可覆写）；**硬链接别名守卫**（`$OUT/<臂>.log` 与 `build/MilBridge/arm-logs/<臂>.log` **同 inode** ⇒ `exit 4`、逐支点名、**零写入**）；第 5 步 `ln -f` 落位（**绝不 `cp`**：顶 mtime 会架空弱配对判据；**绝不 `ln -s`**：`find -type f` 会漏）。
- `tline-gate.sh` 五臂与判据：`ARMS=(tline tab-oracle-zero tab-oracle-anchor tab-oracle-rtl textlineproto)`；世代 = `GEN_KEYS=(instr_run_sh instr_program_cs instr_shim)`；列级下限声明读 `generation.column_gate.{arms,additional.arms}`（`judged_min`/`released_min`）。
- `known-red.json` 现状：`generation.id=#23`；`arm_logs` 五值 = `2026-09-28` 世代；`instr_shim=921ba9c6…`。

### 1.4 旧件归档（写前 `cp -p`）

```
build/MilBridge/arm-logs/*.log  →  $HOME/p1-tail2-run/backup/armlogs/       (cp -p，mtime 保留)
build/MilBridge/known-red.json  →  $HOME/p1-tail2-run/backup/known-red.json.before   (cp -p，模式 644)
```

---

## 2. 重取（装置 / 命令 / 环境）

```
$ bash ~/heavy-slot.sh --min-avail 1500 --max-hold 5400 --wait 3600 -- \
      env ARMS_OUT=$HOME/p1-tail2-run/arms82 bash build/MilBridge/tools/retake-arms-w23.sh
HEAVYSLOT=ACQUIRED waited=0s      HEAVYSLOT=MEMOK avail=24127MB min_avail=1500MB
=== arms re-take 2026-09-30 21:28:33 loadavg=0.75 0.59 0.57 ===
shim      = e2fa9ec9be1a6cf1      pc = 5902d3aff84467a9      run.sh = 711f39f468f61cc8   Parity.cs = dda989bb024d20e6
ARMS_DISPLAY=:97 source=none ⇒ **自起 Xvfb**      ARMS_DISPLAY=:97 source=self-started xvfb_pid=8329（跑完按 PID 收回）
--- rebuild CoverageProbe -c Release ---   CoverageProbe build rc=0
--- arm 1/5 tline ---          tline rc=1
--- arm tab-zero ---           tab-zero rc=1
--- arm tab-anchor ---         tab-anchor rc=0
--- arm tab-rtl ---            tab-rtl rc=0
--- arm 5/5 textlineproto ---  textlineproto rc=0
--- hard-link into arm-logs ---  ln -f ×5    (links=2)
HEAVYSLOT=RELEASED rc=0 held=358s max_hold=5400s
```

- **走重活槽**（`~/heavy-slot.sh`）；**显示位只用 `:97`**（脚本写死，`ARMS_DISPLAY=:97 source=self-started` ⇒ **无 X 混淆风险**，`D-G77` 现场不会重演）；跑完按 PID 收回自起的 Xvfb；进程按 PID。
- `ARMS_OUT` 指向**与 `arm-logs/` 不同 inode** 的 `$HOME/p1-tail2-run/arms82` ⇒ 守卫放行（`rc=0`），未触碰别名。
- 落位 = `ln -f`（在册体例），五件 `nlink=2`。

---

## 3. ① 五臂新旧 sha16 成对 ＋ 红/绿结论对照

### 3.1 逐臂 sha16 成对

| 臂 | 旧 sha16（`09-28` 世代） | 新 sha16（本趟） | 变 | `arm-logs/` 现盘 nlink |
|---|---|---|---|---|
| `tline` | `0153827e9c590d1e` | **`e1cdf3628952f5c5`** | 变 | 2 |
| `tab-zero` | `b5239c4e5b95fa56` | **`baa3b212fc8395cf`** | 变 | 2 |
| `tab-anchor` | `2e62d68ed5edd5e7` | **`e11255665d711ea6`** | 变 | 2 |
| `tab-rtl` | `70feb4b5d4ab80f7` | **`ae1983717152ae02`** | 变 | 2 |
| `textlineproto` | `c537f0c007a6c922` | **`ef314d4e4a4dbc68`** | 变 | 2 |

（`tline`/`textlineproto` 含耗时/日期戳与 app-local 同步行 ⇒ sha 每趟必动，**不是产品信号**；判据行才是。）

### 3.2 红/绿结论对照（**结论一字未变**）

| 臂 | 重取前结论（现读旧件） | 重取后结论（现读新件） | 变？ |
|---|---|---|---|
| `tline` | **RED** — `通过 22 / 失败 2`；`❌ T3`、`❌ T3b` | **RED** — `通过 22 / 失败 2`；`❌ T3`、`❌ T3b` | **否** |
| `tab-oracle-zero` | **RED** — `结构败=1`，`FAILCASE notab-control@w40@em24@RTL@tab0` | **RED** — `结构败=1`，同一条 `FAILCASE` | **否** |
| `tab-oracle-anchor` | **GREEN** — `cases=436 判定过=288 结构败=0` | **GREEN** — `cases=436 判定过=288 结构败=0` | **否** |
| `tab-oracle-rtl` | **GREEN** — `cases=84 判定过=8 结构败=0` | **GREEN** — `cases=84 判定过=8 结构败=0` | **否** |
| `textlineproto` | **GREEN** — `== 通过 10 / 失败 0 ==`（`ContractProbe 4/2` 为**范围外**） | **GREEN** — `== 通过 10 / 失败 0 ==` | **否** |

⇒ **无红绿结论变化** ⇒ 按派单书第 3 条，**不需要报停**；登记表照实重钉。

### 3.3 在册读数零漂移（逐条回日志核过，未照抄）

| 登记项 | 登记 `expected_shape` | 本趟实得 | 相符 |
|---|---|---|---|
| `tline/T3-Collapse明细`（`Collapse明细全等`） | `232/236` | `232/236`（判定一致 `1297/1298`、真折叠 `236`） | ✅ |
| `tline/T2d-Extent余差`（`Extent余差条数`） | `count==1242` | `1242` | ✅ |
| `tline/T3b`（`判据状态`） | `❌` | `❌` | ✅ |
| `tab-zero/notab-control@w40@em24@RTL@tab0` | `❌` | `结构=FAIL` | ✅ |

列级闸读数（`generation.column_gate`，重取后**逐位相符**）：
`tab-anchor START 判定行=615 字形释放行=194 非零真值行判定=171`｜`tab-anchor OVERFLOWED 判定行=421 NOINFO=194`｜`tab-zero OVERFLOWED 判定行=0 NOINFO=138`（`judged_min:none`）｜`tab-rtl OVERFLOWED 判定行=0 NOINFO=163`（`judged_min:none`）。
探针身份自报 `TAB_LINES_PROBE sha256=c78ed88fc1fd34f4… path=build/MilBridge/tests/CoverageProbe/Program.cs`（= 现场，`D-G26` 闸 PASS）。

---

## 4. ② `tline-gate.sh` 现取判词（重取后）

```
$ bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs
TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0
            caliber=OK generation=#23 tree_gen=same saved_shim=e2fa9ec9be1a6cf1 gate=747c078dbf040862 judge=t1b3-tline-gate/7
GATE_COLUMN=PASS state=READINGS-OK arm=tab-oracle-anchor col=START 判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194 非零真值行判定=171 judged_min=615 released_min=194
GATE_COLUMN_EXTRA=PASS state=READINGS-OK arm=tab-oracle-anchor col=OVERFLOWED 判定行=421 … judged_min=421;
                   arm=tab-oracle-rtl col=OVERFLOWED 判定行=0 … judged_min=none; arm=tab-oracle-zero col=OVERFLOWED 判定行=0 … judged_min=none
GATE_PROBE=PASS state=READINGS-OK …（三支 tab 臂自报 = 现场）
GATE_REASON=all-as-registered                                                          rc=0
```

- `tree_gen=same`（树 == 登记世代）、`caliber=OK`、`drift=0 gone=0 unregistered=0 noinfo_arm=0`。
- `registered=4 unlocated=1`：4 条在册红逐条**形状如登记**（其中 `T3b` 为 `KNOWN_RED_UNLOCATED`）。
- `pending` 里那条 `textlineproto` 的 `ContractProbe 4/2`（`P1`/`P6`）**仍明确在射程之外**（门禁不据此判绿也不据此判红）—— **未**借它变绿。

---

## 5. ③ 登记同步 ＋ `arm-log-sha-check.sh` 现取

### 5.1 同趟改了什么（`known-red.json` 唯一写者 = 本车道）

用**在册装置** `build/MilBridge/tools/repin-generation.py`（一处改齐四类落点；写盘 = `temp + os.replace`、**保住 644 权限位**）：

```
$ python3 build/MilBridge/tools/repin-generation.py --why 'T-A49（P1 尾波2 #82）：…'
REPIN_GENERATION=APPLIED
  generation.instr_run_sh = 711f39f468f61cc8          （未变）
  generation.instr_program_cs = dda989bb024d20e6      （未变）
  generation.instr_shim = e2fa9ec9be1a6cf1            ← 921ba9c65e9fb3be
  generation.evidence_log_sha256 = e1cdf3628952f5c5  ← 0153827e9c590d1e
  entries[*].caliber 改动字段数 = 5                    （只动 instr_shim）
```

| 落点 | 旧 | 新 |
|---|---|---|
| `generation.instr_shim` | `921ba9c6…b30dc2b` | `e2fa9ec9…d3d33c0` |
| `generation.evidence_log_sha256` | `0153827e9c590d1e` | `e1cdf3628952f5c5` |
| `generation.arm_logs.tline` | `0153827e…951eb3` | `e1cdf362…49f3787` |
| `generation.arm_logs.tab-zero` | `b5239c4e…e54ae07` | `baa3b212…f59ba12` |
| `generation.arm_logs.tab-anchor` | `2e62d68e…9674948` | `e1125566…78a8518d` |
| `generation.arm_logs.tab-rtl` | `70feb4b5…091a2b25e` | `ae198371…b3054674` |
| `generation.arm_logs.textlineproto` | `c537f0c0…d32c901a` | `ef314d4e…350c2880` |
| `entries[*].caliber.instr_shim`（5 条） | `921ba9c6…` | `e2fa9ec9…` |

**同趟另改**：`generation.arms_retaken`（`--why`：如实追加 `history`，覆盖 `when`/`why`，**不覆盖历史**）＋ `changelog` 新增 `rev:14`（`README.md` §"新世代怎么重绿"第 3 步要求 `changelog` 写清"为什么重钉"）。

**未改**（刻意）：`entries` 的 `expected_shape`/`carrier`/`reason`/`unlocated`/读数、`generation.id`/`label`（沿用 `#23`，与既有多趟只有 `arm_logs` 换代的成法一致）、`generation.column_gate`（下限值本趟读数**逐位相符**，无需重钉）、`schema`/`_FIELDTABLE`/`note`。

`known-red.json` sha16：`29219b6f071c6361` → **`dcc22fd3c80cfcac`**（80,585 B，`644`）。

### 5.2 一致性复算

```
$ python3 build/MilBridge/tools/repin-generation.py --check
REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + 5 条 entries 的 caliber 全部一致）        rc=0

$ bash build/MilBridge/tools/arm-log-sha-check.sh
ARMLOG_ARM=tline         PASS decl=e1cdf3628952f5c5 live=e1cdf3628952f5c5 nlink=2
ARMLOG_ARM=tab-zero      PASS decl=baa3b212fc8395cf live=baa3b212fc8395cf nlink=2
ARMLOG_ARM=tab-rtl       PASS decl=ae1983717152ae02 live=ae1983717152ae02 nlink=2
ARMLOG_ARM=tab-anchor    PASS decl=e11255665d711ea6 live=e11255665d711ea6 nlink=2
ARMLOG_ARM=textlineproto PASS decl=ef314d4e4a4dbc68 live=ef314d4e4a4dbc68 nlink=2
ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0                   rc=0
```

⇒ ③ 满足：`known-red.json` 的 `ARM-LOG-SHA` 与现盘臂日志**逐件相符（全 64 位）**。

---

## 6. ④ `column-floor-check.sh` / `DEFREG` / `REPORTID` 现取

```
$ bash build/MilBridge/tools/column-floor-check.sh
COLUMN_FLOOR_OVERFLOWED_JUDGED_MIN=PASS arm=tab-oracle-anchor col=OVERFLOWED key=judged_min decl=421 frozen=421 corpus_min=421
COLUMN_FLOOR_START_JUDGED_MIN=PASS     arm=tab-oracle-anchor col=START      key=judged_min decl=615 frozen=615 corpus_min=615
COLUMN_FLOOR_START_RELEASED_MIN=PASS   arm=tab-oracle-anchor col=START      key=released_min decl=194 frozen=194 corpus_min=194
COLUMN_FLOOR_CORPUS=PASS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json live=0cebc0afd5142fbf decl=0cebc0afd5142fbf
COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=0 bad= tab-anchor tab-zero tab-rtl tline textlineproto
     [COLUMN_FLOOR_ARMLOG] arm=tab-anchor **MISMATCH** 冻结块声明=2e62d68ed5edd5e7 登记表=e11255665d711ea6（arm_logs 被同趟改过 ⇒ 自指吞掉了 ARM-LOG-SHA 那条牙）
     （tab-zero / tab-rtl / tline / textlineproto 同形，各 1 条）
COLUMN_FLOOR_SELFREPORT=PASS gate=747c078dbf040862
COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS
                 reg=dcc22fd3c80cfcac base=b27ff6332f263495 corpus=0cebc0afd5142fbf       rc=1
```

- 下限三条 + 语料 + 门禁自报 **全 PASS**；**唯一红** = `COLUMN_FLOOR_ARMLOG`（冻结块 ⇔ 登记表的臂日志 sha 三角未对齐）。
- **成因具名（不是产品回归、也不是下限被下调）**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的**当前** `# RE-FROZEN #80` 块第 61–65 行的 `# ARM-LOG-SHA` 五行仍是 `2026-09-28`（`t67`）世代的 sha16；本趟换代后登记表已改、冻结块未改。
- **该件在写域之外**：更新它会改该**整份件**的 sha16 ⇒ 连带要求改 `docs/CURRENT-STATE.md:9` 的 `BASELINE-FROZEN … sha16=`（否则第 `[7]` 步 `BASELINE-SHA` 由 PASS 转 FAIL）—— 属**队长重冻结批**（在册成法：`t74 重冻结批（队长执行）`，提交 `335185e`；`#80` 块的 09-28 那次重钉也是队长做的）。⇒ **本车道不越界重冻结、也不掐这条红**（"红在每个方向上都是真话"）。

```
$ bash build/MilBridge/tools/defect-registry-check.sh            ⇒ DEFREG=PASS declared=225 route_ids=225   rc=0
     DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KRJ      # 本趟改了 known-red.json（route 键 KRJ）⇒ declared.tsv 的锚 29219b6f… 现陈旧（信息性；DEFREG 仍 PASS）
$ bash build/MilBridge/tools/report-id-domain-check.sh           ⇒ REPORTID=PASS files=326 …               rc=0
```

---

## 7. 两极化红证（门禁牙齿仍在；**未**假成功）

在 `/tmp` 的登记表**副本**上做（**不触碰真表**）：

| 极性 | 动作 | 现取 |
|---|---|---|
| 正 | 真表（重钉后） | `TLINE_GATE=PASS … rc=0`、`GATE_REASON=all-as-registered` |
| 反① | 副本删 1 条 `entries`（`T3-Collapse明细`） | `TLINE_GATE=FAIL … unregistered=1`；`UNREGISTERED tline/T3`；`GATE_REASON=unregistered-failure`；`rc=1` |
| 反② | 副本改 1 条 `expected_shape`（`count==1242` → `count==9999`） | `TLINE_GATE=FAIL … drift=1`；`KNOWN_RED_DRIFT tline/T2d-Extent余差`；`GATE_REASON=registry-stale(drift)`；`rc=1` |

⇒ 门禁对"未登记失败"与"登记表过期"两条方向都**真的红**（不是恒绿通道）。

---

## 8. 具名前置 / 未闭项 / 边界（如实）

1. **`COLUMN-FLOOR`（写域外，须队长重冻结批）** —— `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 当前 `# RE-FROZEN #80` 块的 5 行 `# ARM-LOG-SHA` 需同趟改为本报告 §5.1 的新 sha16（`tline e1cdf3628952f5c5`／`tab-zero baa3b212fc8395cf`／`tab-anchor e11255665d711ea6`／`tab-rtl ae1983717152ae02`／`textlineproto ef314d4e4a4dbc68`），并同趟重钉 `docs/CURRENT-STATE.md:9` 的 `BASELINE-FROZEN gen=#NN sha16=<该件新 sha16>`。**在那之前 `ARM-LOG-SHA` 步已绿、`COLUMN-FLOOR` 步必红**（三角未对齐的唯一表现）。
2. **`DEFREG_DECLDRIFT=1 keys=KRJ`** —— `build/MilBridge/tools/defect-registry-declared.tsv` 的 `DECL-ANCHORS KRJ=` 锚随本趟 `known-red.json` 改动而陈旧（信息性，`DEFREG` 仍 `PASS`／`rc=0`）；声明件在写域外。
3. **`HANDOFF-MV` 的 `cell=#1/#2/#5` 未追写** —— 本趟改了覆盖面内件（`known-red.json`／`arm-logs/**`）⇒ 按纪律第 28 条须同趟追写；但 `build/MilBridge/HANDOFF-NEXT.md` **不在本车道写域** ⇒ 归队长。
4. **重取装置的固有产物（写域外，如实披露）** —— `retake-arms-w23.sh` 的 `run.sh tline` 会自然重产 `build/MilBridge/gen/t2d-*.txt`、`gen/tline-detail-full.txt`、`gen/tline-ledger-lines-20260930-2130.txt`（本趟已变/新增）；这是**在册重取命令的固有行为**，非本车道手工写他人产物。
5. **`generation.id` 仍为 `#23`** —— 沿用既有多趟"只换 `arm_logs`/重钉世代三项、不动 `id`/`label`"的成法（`id`/`label` 门禁只印不校验）。若队长要求按 `#82` 改签，属另一次登记动作。
6. **`textlineproto` 的 `ContractProbe 4/2`（`P1`/`P6`）** —— 仍在**门禁射程之外**（诚实披露位），本趟**未**借它判绿。

---

## 9. 复算命令（逐条可重跑）

```bash
R=/home/links-dev/netTest/GitProj/WPFOnLinux ; cd "$R"
# ① 重取（换代）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 5400 --wait 3600 -- \
     env ARMS_OUT=$HOME/p1-tail2-run/arms82 bash build/MilBridge/tools/retake-arms-w23.sh
# ② 登记同步（四处一起钉）
python3 build/MilBridge/tools/repin-generation.py --check
python3 build/MilBridge/tools/repin-generation.py --why '<为什么>'
# ③ 复核
bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs
bash build/MilBridge/tools/arm-log-sha-check.sh
bash build/MilBridge/tools/column-floor-check.sh
bash build/MilBridge/tools/defect-registry-check.sh
bash build/MilBridge/tools/report-id-domain-check.sh
# 旧件归档在 $HOME/p1-tail2-run/backup/{armlogs,known-red.json.before}
```
