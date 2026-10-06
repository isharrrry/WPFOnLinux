# 波 `#86` 预登记（**口径与生成式步表**；`TASK-口径与生成式步表` 落册；**仪器波 · 零产品逻辑改动**）

⏪ **本件落册**（`TASK-口径与生成式步表`；凡数字**以现场现取为准**）：两件**同趟落地** ——
`①`（**冻结记录模板口径**成文：`docs/PORT-SPEC.md` §5.1 ＋ `WFREEZE_TEMPLATE` 加 `kind=residue` 档：机器行里的**未替换残渣**（半填占位）⇒ 红并逐行点名）／
`②`（`Guide.Linux/verify-all.sh` 的 `run_step` 行改**由 `src/Linux/build/MilBridge/verify-all-steps.tsv` 生成**（哨兵夹块）＋ 防手改牙 `verify-all-steps-generated-check.sh`）。

## §1 本波是什么（`#86`）

- **产品改动**：**零**（只动判据件／仪器／文档）。
- **加一步**：第 `[+]` 步 `VERIFYALL-STEPS-GEN` ＝ `src/Linux/build/MilBridge/tools/verify-all-steps-generated-check.sh`（`gen-verify-all-steps.py --check` 的**薄包装**）。
- **四处声明**：首行 `# VERIFYALL-STEPS-DECL: 68 gen=#86` ／ 头注释口径句 `` **`#86` 收官起 = 68 步** `` ／ `# VERIFYALL-STEP-NAMES:`（**67 → 68** 项）／ **本件**。既有史实行只追加、不改动（纪律 61 同族）。
- **覆盖面**：`src/Linux/build/close-wave.sh` 的 `fp_inputs()` **+3 行**（`verify-all-steps.tsv` ＋ `gen-verify-all-steps.py` ＋ 新牙，**件路径身份**、不用 glob）⇒ 覆盖面 **242 → 245**；**同趟**把第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect 242 → 245`。

## §2 冻结位移声明

- **本波不重冻产品件**：九位（`bridge`／`pc`／`pf`／`windowsbase`／`provider`／`win32shim`／`wic_shim`／`hbtextline`／`dwf`）**逐位未变**（不跑整波重建、不改产品源）。
- **`inputs_fp` 必移**：覆盖面 +3 行（件路径身份）＋ 覆盖面内两件改内容（`close-wave.sh` 自改、`wave-freeze-consistency-check.py` 加 `kind=residue`）。
- 本件**不含** `WFREEZE-DECL:` 行（避免与冻结器 `GENS` 表分叉；`[5c/6]` 的 `sec_decl` 仍取最新既存声明代）。

## §3 判据（落地前写死）

### 3.1 回归判定（本波不做任何回归判定）
`PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-only-wave-86`

### 3.2 牙 `VERIFYALL-STEPS-GEN` —— 判据 · 射程 · 反极性
- **判据（唯一实现 = `tools/gen-verify-all-steps.py --check`）**：`Guide.Linux/verify-all.sh` 生成块内 `^run_step "` 行 ⇔ `verify-all-steps.tsv` 生成的行（**多/少/改了哪一步**逐条点名）＋ `DECL` 的 `N` ⇔ tsv 行数 ＋ `NAMES` 的名字序列 ⇔ tsv 的 `name` 序列。三态 `VSTEPS=PASS|FAIL|NOINFO`；**`NOINFO` 不算绿**。
- **反极性（必须真跑）**：手改某一步命令（或往 tsv 加一步不重生成）⇒ **必红并点名** `step-changed`／`count-mismatch`；复原 ⇒ `PASS`。
- **射程边界（如实）**：本牙只判「块内 `run_step` 行 ⇔ tsv」；**不**判块内非 `run_step` 行（注释／`echo`／赋值／`if`）。

### 3.3 模板面 `kind=residue` —— 判据 · 反极性
- **判据**：记录模板（`docs.Linux/evidence/freeze/w<NN>-record.txt`）的**机器行**（`^[#\s]*IDENT=`）里出现 `xx:xx`／`xx`／`TBD`／`FIXME`（半填残渣）⇒ `WFREEZE_TEMPLATE=FAIL` ＋ 点名 `WFREEZE_TEMPLATE_HIT kind=residue line=N`。
- **反极性（必须真跑）**：注入 `X=xx:xx` ⇒ **必红并点名** `kind=residue`；复原 ⇒ `PASS`；`kind=nine` 旧腿仍红（`--selftest` 全过）。
- **边界**：**只判机器行**（散文里的 "xx" 不算残渣）⇒ 不误伤正文；**不削弱** `kind=nine`／`kind=other`。
