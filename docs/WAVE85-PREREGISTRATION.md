# 波 `#85` 预登记（**结构「单一来源」化波 · O1／O2／O4／O6**；`TASK-O1-O4-O6` 落册；**仪器波 · 零产品逻辑改动**）

⏪ **本件落册（`TASK-O1-O4-O6`；凡数字**以现场现取为准**）**：四项**同趟落地** ——
`O1`（九位权威路径表做成**单一来源**：仓内 `--emit-nine` 导出端 ＋ `src/Linux/build/MilBridge/nine-paths.tsv`（入库）＋ 冻结器改**读**它 ＋ `[5c/6]` 的 `WFREEZE_NINESYNC` 一致牙）／
`O2`（**禁止未登记的 `bin/Debug` 字面量**防回归牙 ＋ 豁免表）／
`O4`（冻结**记录段**进仓：`docs.Linux/evidence/freeze/w<NN>-record.txt`）／
`O6`（**入口边界厘清**：只做「一键入口清单」`Guide.Linux/README.md`，**不搬迁**）。
`O3`（`verify-all.sh` 数据驱动化）**未做**（`§⑦` 回退：低风险形态下"等价性 ＋ 66/0"不能同时成立 —— 详见收尾报告）。

## §1 本波是什么（`#85`）

- **产品改动**：**零**（`bin/Debug` 字面量修复只把 shell/python 的**权威件消费路径**改读**唯一声明**，不改产品逻辑、不改落点）。
- **加一步**：第 `[+]` 步 `NO-HARDCODEDCFG` ＝ `src/Linux/build/MilBridge/tools/no-hardcoded-config-literal-check.sh`（`TASK-O1-O4-O6` §O2）。
- **四处声明**：首行 `# VERIFYALL-STEPS-DECL: 67 gen=#85` ／ 头注释口径句 `**`#85` 收官起 = 67 步**` ／ `# VERIFYALL-STEP-NAMES:`（**66 → 67** 项）／ **本件**。**既有史实行只追加、不改动**（纪律 61 同族）。
- **覆盖面**：`src/Linux/build/close-wave.sh` 的 `fp_inputs()` **+3 行**（牙 ＋ 豁免表 ＋ `nine-paths.tsv` 的**件路径身份**，**不用 glob**）⇒ 覆盖面 **239 → 242**；**同趟**把第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect 239 → 242`。

## §2 冻结位移声明

- **本波不重冻产品件**：九位（`bridge`／`pc`／`pf`／`windowsbase`／`provider`／`win32shim`／`wic_shim`／`hbtextline`／`dwf`）**逐位未变**（本波不跑整波重建、不改产品源）。
- **记录段进仓（O4）**：新增 `docs.Linux/evidence/freeze/w85-record.txt`；冻结器 `~/w21-verify/w27-freeze.py` 的 `GENS['#85']['TXT']` 指向它（**旧代绝对路径照旧可读**，不回溯改）。
- 本件**不含** `WFREEZE-DECL:` 行（避免与冻结器 `GENS` 表分叉；`[5c/6]` 的 `sec_decl` 仍取最新既存声明代）。

## §3 判据（落地前写死）

### 3.1 回归判定（本波不做任何回归判定）
`PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-only-wave-85`

### 3.2 牙 `NO-HARDCODEDCFG` —— 判据 · 射程 · 豁免
- **判据**：源码面（`src/Linux`／`src/Microsoft.DotNet.Wpf.Linux`／`Guide.Linux` 下 `*.sh *.py *.csproj *.props *.targets`）的**代码行**里出现 `bin/Debug` ⇒ 命中；命中且**不在豁免表**（`src/Linux/build/MilBridge/hardcoded-config-exempt.tsv`，逐行带 `class`／`why`／在册缺陷号）即 `NOHARDCODEDCFG=FAIL` **逐条点名**。三态 `PASS|FAIL|NOINFO`；`NOINFO` **不算绿**。
- **注释不算命中**：`sh/py` 的整行 `#` 注释、XML 的 `<!-- … -->` 块一律跳过（"注释/文档里的 `bin/Debug` 可留"）。
- **豁免行的编号必须已入册**（`defect-registry-declared.tsv`）；挂未入册号 ⇒ 该豁免不成立、命中照旧红。
- **反极性**：往真消费点（如 `src/Linux/build/integration-wave.sh`）塞一处 `bin/Debug` ⇒ 必红点名；豁免行挂未入册号 ⇒ 必红点名。
- **射程边界（如实）**：本牙只判"**代码行里的 `bin/Debug` 字面量已登记**"，**不**判"这条路径在语义上对不对"。
