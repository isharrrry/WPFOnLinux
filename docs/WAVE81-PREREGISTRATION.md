# 波 `#81` 预登记（**W4a 接线批** · `t47` 落册；**仪器波 · 零产品改动**）

⏪ **本件落册（`t47`，读时 `ts=2026-09-28T17:34:10.732+0800`）**：W4a 接线主体 —— 三颗交付牙接线 ＋ **四处声明**同趟 ＋ 覆盖面 **226 → 229** ＋ 第 `[42]` 步 `--expect 229`。
⏪ **⚠️ 与派单的逐字差异（如实记）**：派单写「步数 `55 → 56`」，但**同一条**又写「**三颗新牙各接一步**」⇒ 算术上 `55 ＋ 3 ＝ 58`；而判据「`grep -c '^run_step "'` **必须等于**首行 `DECL` 声明的数」⇒ **只有 `58` 自洽** ⇒ 本件按 **`58`** 落。若队长要的是 `56`（＝三牙合成一步），那是**另一种设计**，须明示后重落。

## §1 本波是什么（`#80` 之后的接线代）
- **产品改动**：**零**（本波只动门禁步表与覆盖面声明）。
- **接线三件（各接一步）**：`build/MilBridge/tools/sentinel-spec-check.sh`（哨兵「键序／字节格式」11 键；默认跑生产两枚哨兵）／`build/MilBridge/tools/wave-push.sh --dry-run`（推送预演：13 键上屏、**不写盘**）／`build/MilBridge/tools/timestamp-order-check.sh`（戳序判据；默认件 `build/MilBridge/P1-w1-close-verify.md`）。三件**纯读、秒级、零 `dotnet`**。
- **四处声明**：首行 `# VERIFYALL-STEPS-DECL: 58 gen=#81`／头注释口径句 `**`#81` 收官起 = 58 步**`／`# VERIFYALL-STEP-NAMES:`（55 → 58 项）／**本件**。**既有史实行只追加、不改动**。
- **覆盖面**：`build/close-wave.sh` 的 `fp_inputs()` **+3 行**（三颗牙的**件路径身份**，不用 glob）⇒ `coverage_n` **226 → 229**；**同趟**把第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect 226 → 229`。

## §2 冻结位移声明
- **本波不冻结**（不落 `POST.done`、不推哨兵、不动基线件）：冻结面归后续波。⇒ 本件**不含** `WFREEZE-DECL:` 行（避免与冻结器的 `GENS` 表分叉）。
- **九位**（`pc`／`pf`／`windowsbase`／`provider`／`dwf`／`win32shim`）本波**不动**（零产品改动；不许跑整趟门禁 ⇒ 不触发构建位移）。

## §3 判据与绿名单
- **本代必须同趟成立的读数**（`t47` 现取）：`VERIFYALL_SELF=PASS names=58 decl=58 gen=#81`｜`FP_MANIFEST_TEETH=PASS files_n=229 declared_expect=229`｜`WIRING_COVERAGE=PASS wiring_n=56 coverage_n=229 missing_n=0`｜两牙 `DEFREG=PASS`／`REPORTID=PASS`。
- **覆盖面入口/出口**：`inputs_fp` **必移**（`226 → 229`）；**逐件归因** ＝ 新入白名单 **3 件** ＋ `close-wave.sh` **自身**。
- **判据只许收紧**：`NOINFO` 一律具名、既不算绿也不算红；`--expect` 与现取件数**不一致 ⇒ 该步必红**（方向安全）。

### 3.1 回归判定（本波不做任何回归判定）

回归判定：**本波不做任何回归判定**（硬形态＝下一行机读行；与 `#79`／`#80` 同形）——

`PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-only-wave-81`

- **为什么**：本波 ＝ **仪器/门禁接线批**（零产品改动：三颗牙接线 ＋ 覆盖面 ＋ 四处声明）⇒ **没有可判回归的产品位移面**。
- **三态词表**：`REGRESSION`／`NOINFO`（皆见本节；`NOINFO` **不算绿**）。

## §4 停手条件（本波）
1. **不跑整趟门禁**（一跑就构建 ⇒ 让 `provider` 位位移，`B-18` 在册现象）⇒ 只跑单步自检与**不改工作树**的现取读数。
2. **四面声明与接线必须同趟全落**：漏一处 ⇒ `VERIFYALL_SELF` 报 `FAIL`/`NOINFO`（步名多重集／步数／口径句分叉）。
3. **覆盖面与 `--expect` 必须同趟**：漏改 ⇒ `FP_MANIFEST_TEETH=FAIL reason=files-n-mismatch`（方向安全）。
4. **承重件写入纪律**：写前 `stat -c %h`＝1、`cp -p` 备份在任何写之前、`temp+rename`、逐处 before/after 逐字；**不许** `git add/commit/push`。
