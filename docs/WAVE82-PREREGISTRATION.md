# 波 `#82` 预登记（**P1 尾波 2 · 两颗判据牙接线批** · `T-D2` 落册；**仪器波 · 零产品改动**）

⏪ **本件落册（`T-D2`；读时 `ts=2026-09-30T00:44:02+0800`；凡数字**以现场现取为准**）**：`TASK-0756`（`SJC-FIELD-ID` **弱版**）＋ `TASK-0757`（**静默阈值禁令** `R-7`）**同趟落地并接线** —— 两颗新牙 ＋ **四处声明**（首行 `DECL`／头注释口径句／`STEP-NAMES`／本件）＋ 覆盖面 **234 → 236** ＋ 第 `[42]` 步 `--expect 234 → 236`。步数 **62 → 64**。
⏪ **上游出处**：只读侦察载体 `build/MilBridge/P1-tail2-jaws-recon.md`（`T-D0`；`§1` 接线点表／`§2` 正则草案／`§3.1` 现取命中／`§4` 判据草案）＋ 首裁件 `build/MilBridge/tasks-tail2/T-D2.md` 的**队长裁决 (a)(b)(c)**（覆盖侦察件的「待裁」项）。

## §1 本波是什么（`#82`）
- **产品改动**：**零**（只动门禁步表、覆盖面声明与两颗判据牙；不碰 `src/**`／`build/*.Linux/**`／`.so`）。
- **接线两件（各接一步，**共用一次加步窗口**）**：
  - ① **`SJC-FIELD-ID`** ＝ `build/MilBridge/tools/sjc-field-id-check.sh`（`TASK-0756`）—— 判「证据行是否**同给**『结构偏移 ＋ 写点』两要素」。**弱版**：**只判「同给」、不判「对得上」**；强版需 `field-write-registry.tsv`（本波记 `NOINFO`，件内 `SJC_FIELD_ID_STRONG_VERSION` 行上屏）。
  - ② **`SILENT-THRESHOLD`** ＝ `build/MilBridge/tools/silent-threshold-ban-check.sh`（`TASK-0757`／`R-7`）—— `(if|&&).*>[[:space:]]*[0-9]+.*fprintf` **命中即红**；**射程＝源码**（`*.c`／`*.h`／`*.sh`／`*.py`）。
- **四处声明**：首行 `# VERIFYALL-STEPS-DECL: 64 gen=#82` ／ 头注释口径句 `**`#82` 收官起 = 64 步**` ／ `# VERIFYALL-STEP-NAMES:`（**62 → 64** 项）／ **本件**。**既有史实行只追加、不改动**（纪律 61 同族）。
- **覆盖面**：`build/close-wave.sh` 的 `fp_inputs()` **+2 行**（两颗牙的**件路径身份**，**不用 glob**）⇒ 覆盖面 **234 → 236**；**同趟**把第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect 234 → 236`。

## §2 冻结位移声明
- **本波不冻结**（不落 `POST.done`、不推哨兵、不动基线件）：冻结面归后续波。⇒ 本件**不含** `WFREEZE-DECL:` 行（避免与冻结器的 `GENS` 表分叉）。
- **九位**（`pc`／`pf`／`windowsbase`／`provider`／`dwf`／`win32shim`）本波**不动**：**不跑整趟门禁**（一跑就构建 ⇒ `provider` 位位移，`B-18` 在册现象）⇒ 只跑单步自检与**不改工作树**的现取读数。主链产物 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（`sha16=26da177686acb1f0`）**本波不碰**。

## §3 判据（落地前写死）

### 3.1 牙①`SJC-FIELD-ID`（弱版）—— 判据 · 射程 · 豁免
- **判据**：受检行（＝命中**结构偏移强形态**的行：`<标识符>@+<N>` 或 `off=+<N>`）须**同行**同给**写点要素**（`<文件>.{c,h,cs,py,sh}:<行号>` 或裸 `:<三位以上>`）；缺一 ⇒ `SJC_FIELD_ID=FAIL reason=missing-element` 并**逐行点名 `文件:行`**。三态 `PASS|FAIL|NOINFO`。
- **强弱分界（判词里明写）**：**只判「同给两要素」，不判「对得上」**（`t194` 式「齐但错面」的行在弱版下仍 `PASS` —— **这是设计，非缺陷**）。
- **射程**：件级「件路径身份」，`--dir` 现取 glob ＝ `build/MilBridge/*.md`（**`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 不在射程内**：侦察现取该册无「结构偏移 ＋ 写点」同行的合格正样本）。
- **形态边界（**如实划界**）**：**裸 `+N`**／`offset=N`（无 `+`）／`off_<名>=N`（无 `+`）**不纳入受检行**（现取在 `build/MilBridge/*.md` 命中 4xx 行、绝大多数是几何/像素/字节偏移 ⇒ 照收会把整面判红＝假红）；未纳入形态的命中数**如实上屏** `SJC_FIELD_ID_WIDE_UNCOVERED n=…`（诊断，不进 `rc`）。
- **具名豁免**：**引用/定义行**（逐字引用反例、或描述判据自己）⇒ 判据的域不覆盖它们（`D-G130` 自指污染族）。清单是**闭集**（`件路径|行内容锚|为什么`），本版 `cap=4`、现读 **4 行**（3 行在侦察件、1 行在 `P1-HANDOFF-20260929.md` 的「错法」引文行）；**超上限即红**、逐行**上屏**（不静默）。⚠️ 主动披露：按 `C2` 的字面口径这 4 行**本可判红**，归入「引用/定义行」而豁免是**本版的可裁项**（删豁免 ⇒ 当场翻红，自测 `S6` 钉住）。
- **防空过**：受检行 `=0` ⇒ **只许 `NOINFO`**（`reason=no-evidence-line-examined`）；`PASS` 必带 `files=`／`examined=`／`compliant=`／`exempt=`。

### 3.2 牙②`SILENT-THRESHOLD`（`R-7`）—— 判据 · 射程 · 豁免
- **判据**：`(if|&&).*>[[:space:]]*[0-9]+.*fprintf` **命中即红**（逐行点名 `文件:行`，`reason=silent-threshold`）；三态 `PASS|FAIL|NOINFO`。缺省行 token 目标统一为 `no-leg`。
- **射程（队长裁决 (a)）**：**只扫源码** `*.c`／`*.h`／`*.sh`／`*.py`，**不扫 `*.md`** —— 一举消掉两处假红：① 载体/侦察件的**自指**；② `build/MilBridge/*.md` 里**引用判据行**的证据件被误判。判词永远带 `files=`／`lines=`（现取 241 件 / 96823 行）。
- **具名豁免（队长裁决 (b)）**：`build/DirectWrite.Linux/wic-shim/wic_proxy.c` **3 处** `g_trace_budget-- > 0` ＝ **有界 trace 预算**型限流（预算耗尽即静默），**不是**「读数判别式」的实数闸 ⇒ 纳入**具名豁免清单**（`cap=3`），**必上屏** `SILENT_THRESHOLD_ALLOW n=3 cap=3 sites=…`（＋逐处 `…_SITE` 明细），**不静默**；**上限＝现读处数 ⇒ 树长大也红**。
- **待裁项上屏（不判）**：`no-leg` 变体的「红 / 警告」**待主裁** ⇒ 本件只印 `SILENT_THRESHOLD_TOKEN_SCAN hits=… decision=deferred`（现取 `hits=1`，站点 `src/WpfGfx.Linux.Native/src/win32_pts.c:3621`）——**不进 `rc`**、不冒充红。
- **防空过**：射程件 `=0` 或扫到 `=0` 行 ⇒ **`NOINFO`**（`reason=no-source-in-scope`／`no-line-scanned`）。

### 3.3 两牙的两极化自测（`--selftest`，自带夹具、不依赖活件）
- `SJC_FIELD_ID_SELFTEST` **9 例**：正极（两要素齐 ⇒ `PASS`）／反极①（只给偏移 ⇒ 必红点名）／反极②（`--lines` 下只给写点 ⇒ 必红点名）／**空集 ⇒ `NOINFO`（不许 PASS）**／豁免在位 ⇒ `PASS` ＋ `ALLOW` 上屏／**删豁免 ⇒ 翻红**（证明豁免是「被看着」而非「恰好没坏」）／豁免超上限 ⇒ `FAIL reason=allow-cap-exceeded`／射程 0 件 ⇒ `NOINFO`。
- `SILENT_THRESHOLD_SELFTEST` **8 例**：正极（无条件打 ＋ 具名缺省行 ⇒ `PASS`）／反极（静默阈值 ⇒ 必红点名）／豁免在位（3 处 ⇒ `PASS` ＋ `ALLOW n=3 cap=3` 上屏）／**删豁免 ⇒ 翻红**／豁免超上限 ⇒ `FAIL`／射程 0 件 ⇒ `NOINFO`。夹具的违规样例**运行时拼装**（不把字面样例写进牙源码 ⇒ 不自指）。

### 3.4 回归判定（本波不做任何回归判定）

`PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-only-wave-82`

- **为什么**：本波 ＝ **仪器/门禁接线批**（零产品改动：两颗判据牙 ＋ 覆盖面 ＋ 四处声明）⇒ **没有可判回归的产品位移面**。
- **三态词表**：`REGRESSION`／`NOINFO`（皆见本节；`NOINFO` **不算绿**）。
- ⚠️ 本件**不引用**任何回归判定工件（不写判定工件机读行的字样，也不引它的台账）⇒ 适用 `PREREG4=NA`（**与 `PASS` 分开计数**）。

## §4 停手条件（本波）
1. **不跑整趟门禁**（一跑就构建 ⇒ `provider` 位位移）⇒ 只跑单步自检与**不改工作树**的现取读数。
2. **四面声明与接线必须同趟全落**：漏一处 ⇒ `VERIFYALL_SELF` 报 `FAIL`/`NOINFO`（步名多重集／步数／口径句分叉）。
3. **覆盖面与 `--expect` 必须同趟**：漏改 ⇒ `FP_MANIFEST_TEETH=FAIL reason=files-n-mismatch`（方向安全）。
4. **承重件写入纪律**：写前 `stat -c %h`＝1、`cp -p` 备份在任何写之前、`temp+rename`、逐处 before/after 逐字；**不许** `git add/commit/push`。

## §5 现取读数（本件落册时；可复跑）
- 步数：`grep -c '^run_step "' verify-all.sh` ⇒ **64**（＝首行 `DECL` 声明的数）。
- 覆盖面活清单：``fp_inputs()`` 现取件数 ⇒ **236**（＝第 `[42]` 步 `--expect 236`）。
- 两牙自测：`SJC_FIELD_ID_SELFTEST=PASS cases=9 pass=9 fail=0`／`SILENT_THRESHOLD_SELFTEST=PASS cases=8 pass=8 fail=0`。
- 两牙现跑：`SJC_FIELD_ID=PASS files=420 examined=13 compliant=9 exempt=4`／`SILENT_THRESHOLD=PASS files=241 lines=96823 hits=0 allow=3 cap=3`。
- `bash build/MilBridge/tools/defect-registry-check.sh` ⇒ `DEFREG=PASS`。
- **未跑** 整趟 `verify-all`、**未跑** `static-jaws-check.sh` 全表（边界条款）；**未动** `.so`。
