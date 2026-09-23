# 波 `#56` 预登记（仪器波 · `TASK-0708`：把四件新牙接线）

> ⚠️ **本件由车道 W137A 在接线前补建（主控授权）；本波判据先写于四件牙各自的既有判据与
> `~/w137a/criteria.md`，本件不发明新判据。**

## §1 本波是什么

**只做接线，零产品改动。**

`#52` 收口时登记的四件牙**牙已备、无人跑**（各自在自己那份报告里被登记为「未接线」）：

| 步 | 牙 | 建牙车道 | 未接线登记处 |
|---|---|---|---|
| `[28]` `HYGIENE` | `build/MilBridge/tools/hygiene-tooth.sh` | W119A | `build/MilBridge/W119A-report.md` §5 |
| `[29]` `REGRESSION-DECISION` | `build/MilBridge/tools/regression-decision.py` | W117A | `build/MilBridge/W117A-report.md` §5 |
| `[30]` `UIA-DOOR` | `build/MilBridge/tools/uia-door-check.sh`（**走在册红形态** —— 由新消费者 `known-red-arms-check.sh` 承载） | W121A | `build/MilBridge/W121A-report.md` §5 |
| `[31]` `IME-LANDING` | `build/MilBridge/tools/ime-landing-check.sh` | W122A | 同上 §5 |

⇒ `verify-all.sh` **27 → 31 步**；四处声明（`DECL`／`STEP-NAMES`／口径句／本件 H1）**同趟**改。

## §2 判据（**先写**；逐字全文见 `~/w137a/criteria.md` §1 的 J1–J7）

- **J1** 四件牙逐件能单独跑出机读行且与派单书给的现场值**逐字相同**。
- **J2** 打补丁的副本上 `VERIFYALL_SELF=PASS names=31 decl=31 gen=#56 prose=OK order=OK dup=0`。
- **J3** `--revert` 后目标件 sha256 **逐字节**回到打补丁前（`PATCH_REVERT_BITEQUAL=yes`）。
- **J4** `--apply` 幂等（第二次 `PATCH=already-applied`，不动一个字节）。
- **J5** 四步**同趟**声明一致（四处任一缺 ⇒ 第 `[11]` 步正确红）。
- **J6** 本件的标题行含 `#56`（否则 `verify-all-step-check.sh:206-220` 判 `prereg-absent` ⇒ `rc=2`）。
- **J7** 在册红消费者三态：红∧相符 ⇒ `0`；红不在册 **或** 在册却已转绿 ⇒ `1`；读不到 ⇒ `2`。

## §3 位移预期（**落地前先写，落地后现场重算对账**）

| 件 | 预期位移 | 原因 |
|---|---|---|
| `verify-all.sh` | sha16 **必变**；`27 → 31` 步 | 四处声明 ＋ 四步本体 |
| `build/MilBridge/known-red.json` | sha16 **必变** | 追加 `arm=uia-door` 一条 `entries[]`（`merge=true` 的那条；`arm=ime-landing` 那条 `merge=false` **不并入**，理由见 `plan.md` §2） |
| `build/close-wave.sh` | sha16 **必变** | `fp_inputs()` 显式名单追加 4 件 |
| `inputs_fp` | **必变**（位移原因 = **新增 4 件**；⚠️ 具体值**必须落地那趟现场重算** —— `#54` 的桥源与 `#55` 的 `win32_msg.c` 都在覆盖面内 ⇒ 现在算的值到落地时已过期） | 同上 |
| 九位（`win32shim`/`pc`/`pf`/`wb`/`bridge`/`gfx`/`hbtextline`/`pcshim`/`instr_*`） | **逐位不动** | 本波零产品改动 |
| `GEN_KEYS`（`instr_run_sh`/`instr_program_cs`/`instr_shim`） | **逐位不动** | 被测件与探针都不动 |

**新增件（落地趟随本件一起落）**：`build/MilBridge/tools/known-red-arms-check.sh`（在册红消费者，
带 `--selftest` 10 例）｜`build/MilBridge/tools/regression-decision-cases.tsv`（台账，
来源 = W117A 起草件 `~/w117a/regression-decision-cases.tsv` `5d3c26a1c8d83688`，
W137A 现场复算 **7/7 PASS**）｜本件。

## §4 回滚姿势（= 撤销接线）

1. `python3 $HOME/w137a/patch-verify-all.py --target verify-all.sh --revert`
   ⇒ 断言 `PATCH_REVERT_BITEQUAL=yes`（**逐字节**回到打补丁前）。
2. `known-red.json`：删掉追加的那条 `entries[]`（消费者读数 `KNOWN_RED_ARMS` 会回到
   `NOINFO reason=no-out-of-gate-arms-entries` ⇒ **不许当绿**，这是设计）。
3. `close-wave.sh` 的 `fp_inputs()`：撤掉追加的 4 行 ⇒ `inputs_fp` 回旧值。
4. 新增件可按需删除；删 `known-red-arms-check.sh` 前**先**把 `[30]` 步撤掉（否则步本体指向缺件）。

## §5 边界（不许被读成"已覆盖"）

- 本件**只**覆盖"四件牙接进 `verify-all`"这一件事；四件牙**各自判什么**由它们自己的报告与
  判据件负责，本件**不复述、不放宽**。
- `UIA-DOOR` 那一步的绿 = 「**那个红在册**」，**≠**「UIA 的门装好了」（门今天仍不存在，`D-G75`）。
- `IME-LANDING` 的绿 = 「**世界与 `D-G76` 那条有意降级声明一致**」，**≠**「IME 有落点了」。
- `HYGIENE` 的 `HYGIENE_SCOPE` **永不为 `PASS`**（恒 `REPORT`）⇒ 它**不**声称全域干净。
