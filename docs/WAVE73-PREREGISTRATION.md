# 波 `#73` 预登记 —— `TASK-0726`（「静默 SEGV」那条腿的**产出端**入仓 ＋ 收编 7 份同形副本）

> **判据先写**：本文件在**任何落仓动作之前**写定（`CRITERIA_FIRST=yes`）。
> 本波落仓集（**逐件**）：`build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`（**新建**）｜
> `build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv`（**新建**）｜`build/close-wave.sh`（`fp_inputs()` **＋2 行**）｜
> `verify-all.sh`（第 `[42]` 步的 `--expect 192 → 194` ＋ 头注释两处声明）｜本文件。
> ⚠️ 本波**不改任何产品件** ⇒ 九位 sha 逐位不动。
> ⚠️ **步数：42 → 42（不动）**；`STEP-NAMES` 一字不改（**不加步**）。

## §1 本波要交什么（逐条可判否）

| # | 交付 | 判否（不满足即**拒落**） |
|---|---|---|
| H1 | 产出端 `run-silenthit-legs.sh` | `bash -n` 非 0；或缺**环境自断言**（`DISPLAY`∈`:23[0-9]` ∧ `WPF_PROBE_TAG` ∧ `WPF_PROBE_RUNDIR`，缺一即 `rc=9` 并**逐条**打读数）⇒ 拒落 |
| H2 | 剔除集 `silenthit-trim.tsv`（同目录） | 不是**从文件读**、不是**行首锚定**，或 `trimmed=yes` 行为 0 ⇒ 拒落 |
| H3 | 落仓件**零车道路径** | `grep -c "$HOME/w" <落仓件>` **≠ 0** ⇒ 拒落（`D-G137`） |
| H4 | `fp_inputs()` **＋2 行** ∧ `--expect` **同趟**改 | 覆盖面件数 ≠ 基点 +2，或第 `[42]` 步 `--expect` ≠ 覆盖面件数 ⇒ 拒落 |
| H5 | 7 份副本标废（`DEPRECATED-BY=… (WAVE73)`） | 缺任一件，或**动了** `w128a/bin/one128.sh` ⇒ 拒落 |
| H6 | 两极化 4 腿**真跑** | 任一条腿**只写「设计上应该」**而没原始读数 ⇒ 拒落 |

## §2 判据（落地前写死）

### 2.1 输入来源（纪律 36 · 逐字声明）
- **产出端**＝`build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`：**唯一**的落盘层。
- **剔除集**＝`build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv`：**唯一来源**（现取：`find $R -name '*trim*'` 命中 **0** 件；`silent-hit-v2-check.sh` 的 `trimmed` 是**吃产出端机读行**并与台账 `trimmed` 列交叉核，**不自己算剔除**）⇒ 判据端**只消费**、**不另持一份剔除口径**。这条写在这里，是为了**将来谁想再加一份都会被它挡住**。
- **第三支（`SEGV_BRANCH`）的语料来源**：`app.log`＋`app.err` 合并件（现场形态）／既有 `gdb.txt`（`--replay` 形态）。四支优先级逐字固定：`rc139` → `fate` → `term` → `stop-signo11`，`none` **不算**。
- **臂成员表来源**：`find <armdir> -type f -printf '%p\n'` ＋ 逐件 `sha256sum` ⇒ `(相对路径, 字节数, sha16)` 三元组列表（**先取成员表，再比**）。
- **`--expect` 常数来源**：`verify-all.sh` 步本体里**手写**的显式常数（`verify-all.sh` **不在** `fp_inputs()` 覆盖面 ⇒ 该常数**与生产路径无关**）。

### 2.2 判据本体（合取；**本波只把产出端做成会咬的**）
```
产出端「这一趟」算命中 ⇔  APP_TEXT_BYTES_TRIMMED == 0  ∧  STACKOVF == 0  ∧  SEGV_BRANCH ∈ {rc139,fate,term,stop-signo11}
```
两条**前置闸**（缺一即该腿 `NOINFO`，不进分母）：① `UNDECLARED_TAG_LINES > 0 ⇒ NOINFO reason=undeclared-instrumentation`（完备性闸：具名 tag 行**不在** `silenthit-trim.tsv` 的声明集里）；② `phase == teardown`（收进程期死亡）**不计命中**。**两个数都印**（`APP_TEXT_BYTES` 原始 ＋ `APP_TEXT_BYTES_TRIMMED` 剔除后）。

### 2.3 单变量构造（两臂**只差一件**）—— 反"归因不成立"的牙
`diff（A 的 (相对路径,字节数,sha16) 集合, B 的同形集合）` ⇒ **去重后的差异相对路径数**必须 **== 1** ∧ 该路径必须 **== 声明的变体路径**；否则 `ARM_GUARD=FAIL` ＋ `rc=9`，**不跑**。
⚠️ **去重是必须的**：`diff` 对"一件内容变了"会给**两行**（`<` 与 `>`）⇒ 若直接数 `diff` 行数，这条断言**恒假**（本件 `--selftest` 的 S8a **当场咬到过一次**，已修）。
⚠️ **硬链接禁令的机制化**：`cp -a` 会**保留源树内的硬链接** ⇒ 复制出来的两臂可能**共享 inode**，改一臂等于改两臂。故构造后一律**去硬链接化**（`-links +1` 的件真拷贝替换），且**覆盖变体之前与之后各断言一次** `%h == 1`。

### 2.4 两极化（正极必现／反极必不现；**每条都真跑**，原始读数见 `~/w171a/logs/pol-*.log`）

| 腿 | 臂 | 装置 | 期望 |
|---|---|---|---|
| **R1** | **真静默 SEGV**（真 C 程序 `volatile int *p=0; *p=1`；真内核裁决） | `--app-cmd <segv-demo>`，显示 `:236` | `rc=139` ∧ `APP_TEXT_BYTES_TRIMMED=0` ∧ `SEGV_BRANCH=rc139` ⇒ **必打红签名** |
| **R2** | **重放历史真现场**（既有 rundir，含 gdb 具名停止） | `--replay ~/w128a/frozen/W077`（**不起进程**） | `APP_TEXT_BYTES=0` ∧ `SEGV_BRANCH=stop-signo11` ⇒ **必打红签名** |
| **C1** | 对照：真进程**不崩**、有输出、正常退出 | `--app-cmd <quiet-ok.sh>`，`:236` | `rc=0` ∧ `branch=none` ⇒ **不得**打红 |
| **C2** | 对照：**真 WPF 应用活腿**（私有应用目录 ＋ 私有显示位，**走重活槽**） | `--app-cmd 'dotnet HandyControlDemo.dll'`，`WPF_PROBE_CWD` ＝ 私有应用目录，`:237`，`--to 40` | `rc=124` ∧ `phase=alive-after-recipe` ∧ `branch=none` ⇒ **不得**打红 |

**判否条件**：
- **判否-1（假牙）**：正极腿**不给红签名**、或反极腿**给了**红签名 ⇒ 该腿读数作废（`D-G128`）。
- **判否-2（装置没起来）**：`DEVICE=NOINFO`（显示被占／内存不足／X 起不来）⇒ 记 `NOINFO` ＋ 原因，**不许**当成"没命中"。
- **判否-3（形状完好的假读数）**：把 `NOINFO` 读成绿、或把"跑不动"写成"读数正常" ⇒ 违规。
- **判否-4（读大）**：把 `--selftest` 的 `PASS` 读成"现件代静默 SEGV 已清零" ⇒ 违规（见 §3）。

### 2.5 回归判定（本波不适用）
⚠️ **本波（`#73`）不做任何回归判定** —— 本波是**装置/产出端**波（把一条**早已在册**的观测口径做成仓内唯一产出端 ＋ 收编车道副本），**没有**任何"两臂对拍比出一个率"的主张。
`PREREG-NO-REGRESSION-DECISION: 本波只交产出端与剔除集，不给任何率、不做任何两臂对照判定；四要件对本波不适用。`
⇒ 这一句是"**这一刻不适用**"的声明，**不是**"我已经做过"的声明。

### 2.6 生效边界与射程（逐字声明）
- **生效波**：`#73` 收官起，产出端 `run-silenthit-legs.sh` 在树（**重活形态**，**不在门禁里同步跑**）。
- **射程（如实四条）**：
  1. 本件**只**把「这一趟怎么被观测」变成机读行；**不判**「现件代静默 SEGV 已清零」（率与上界属台账/分母层）。
  2. 现场形态**不跑 gdb** ⇒ 现场可观测的第三支是 `rc139`／`fate`；`term`／`stop-signo11` **只在 `--replay`**（吃既有 `gdb.txt`）形态可判。
  3. `--app-cmd` 是**极化/自检形态**（应用面被调用方替换）⇒ 它的读数**不是** WPF 应用本体的读数；R1/C1 属此形态，**C2 才是**真应用面。
  4. `--legs-from` 一致性闸在本波**未接线进 `verify-all`**（门禁里跑的是判据端的 `--cases` 那条路）⇒ 产出端与判据端的**接线**是**下一步**的事，本波只保证"产出端在树、能被真跑、表列与判据端相容"。
- **`UNWIRED` 声明（更新 `#68` 的两条）**：
  - `producer=WIRED-ON-DEMAND`（原 `#68` 的 `producer=UNWIRED-IN-STEP` 说的是"**产出端在车道目录**"）—— 本波后产出端**在仓内**，但 `verify-all.sh` 里**仍没有任何一步调用它**（判据口径限定到代码形状：`grep -cE '^[[:space:]]*run_step .*silenthit' verify-all.sh` = **0**；全文命中只作旁证）⇒ **仍不许**把第 `[39]` 步 `SILENT-HIT-V2` 的 `--cases PASS` 读成"现件代已复现／已清零"。
  - `legacy-copies=DEPRECATED×7`（本波办结）。

## §3 收编 7 份同形副本（**逐件改前/改后 `sha16` ＋ `%h`**）

现取（8 件，全部 `%h=1`）与真副本/漂移判定：
1. `~/w128a/bin/one128.sh` `b5217b83870a4d9c`（12,676 B／227 行）—— **不许动**：历史真命中的产出者证据。
2. `~/w118a/bin/one118.sh` `13674b647160f2fc`（12,676 B／227 行）—— 真副本（首段与 1 逐字同形）。
3. `~/wc06/probe/one_wc06.sh` `46d5e2c3cf9296cc`（13,099 B／234 行）—— 真副本＋私有应用目录已改。
4. `~/wc07/bin/one128g.sh` `1e09bf458957596e`（12,674 B／227 行）—— 真副本。
5. `~/wc08/bin/one_wc08.sh` `20782a3b21aec293`（13,549 B／237 行）—— 真副本。
6. `~/wc11/bin/one_wc11.sh` `8eee56d895cc21e3`（13,711 B／238 行）—— 真副本（自报 `fork of W118A/WC08`）。
7. `~/w155a/w65d109/bin/leg.sh` `15a427eca2e83f03`（11,281 B／218 行）—— **同族另一支**：**唯一**同时带 `APP_TEXT_BYTES` 与 `APP_TEXT_BYTES_TRIMMED`（混合口径的来源）。
8. `~/w159a/bin/leg.sh` `64d027a98c537b0b`（4,709 B／74 行）—— **已漂移**：`display`／`SIGSEGV`／`139` **各 0 命中**，判据面只剩 `ledger-row.tsv`。
⇒ 标废 **7 件**（去掉第 1 件），每件**首行**加 `DEPRECATED-BY=run-silenthit-legs.sh (WAVE73)`；取代者 = `build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`。
⚠️ 这 7 件**在 `$R` 之外**（车道目录）⇒ 改动**不会、也不该**进 git；逐件路径＋`sha16` 记在本节与报告里。
⚠️ 派单原文写"其余 6 件 0 处"；**现取是 7 件**（8 − `w65d109`）⇒ 以**现取**记账。

`PREREG_WAVE=#73`｜`PREREG_TASK=TASK-0726`｜`CRITERIA_FIRST=yes`｜`LANDING_OWNER=车道 W171A（拥有唯一写者集）`
