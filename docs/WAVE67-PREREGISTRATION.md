# 波 `#67` 预登记（**判据接线波 · 零产品改动**：把 `D-G122` 的牙 `PTS-PAGES` 接进门禁 · `TASK-0721`）

> 车道 **W160A-W67ARM**｜基线 `gen=#64 sha16=6b01358a776dd936`（`sed -n '9p' docs/CURRENT-STATE.md` 现读）
> 本波**零产品改动**：只加**一步**（第 `[38]` 步 `PTS-PAGES`）＋ 四处声明 ＋ `fp_inputs()` 显式清单**两行**。
> **「落地前预置」** = 门禁里**只跑判据那一半**（`--legs`，纯读、零 `dotnet`、< 1 s），
> 重活（私有 X ＋ 应用冷启 ＋ 真实点击；A 臂 2 腿 ≈ 45 s）由**波内前置**落到约定证据目录
> （`PTS_EVIDENCE_DIR`，默认 `build/MilBridge/tests/PtsPagesProbe/evidence`）。
> ⚠️ 原始施工与影子树实测在车道 `W160A`（`~/w160a/report.md`）；**落仓由本波 owner 做**。
> ⚠️ **世代口径**：在册排期 = `#67`（`grep -o 'TASK-0721 [^│]*' docs/ROUTES.md` 现取 ⇒ `排 `#67``）；
> `#65` 是**在飞的那一波**（37 步、不加步）⇒ 本波若写 `#65` 会让声明块出现
> "两行都声称 `#65`，一个 37 步、一个 38 步"的**自相矛盾**。

## §1 本波是什么

| 件 | 动作 | 入口件 |
|---|---|---|
| ① | 新步 `[38] PTS-PAGES` | `verify-all.sh` |
| ② | 四处声明同趟（`DECL 38 gen=#67`／`STEP-NAMES` 行尾／口径句／本件 H1） | `verify-all.sh` ＋ 本件 |
| ③ | `fp_inputs()` 显式清单**两行** | `build/close-wave.sh` |

**判据件（牙）**：`build/MilBridge/tools/pts-pages-guard.sh`（`--legs <dir>` / `--selftest`）
**装置（重活那一半）**：`build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`

## §2 判据（**先写**，逐字）

### 2.1 口径句（`D-G122`）

> **凡以「止损/降级」形态落地的修法，必须同时落地一条能把它咬回来的牙 ——
> 否则它是不可回归的，而不可回归的修法迟早会被静默改回。**

### 2.2 三态判据（牙的机读行）

```
PTS_GUARD=PASS      ⟸ 全部承重格都判到且都过（rc=0）
PTS_GUARD=FAIL      ⟸ **判据红**，逐格点名 fails=leg24-…,leg23-…（rc=1）
PTS_GUARD=NOINFO    ⟸ **算不出**：装置没起来／点错对象／件跑动中被换／证据缺格（rc=2）—— **门禁里同样是 ❌**
```

**承重格（进 `rc`）**：`G1/G2` 两腿 `alive=yes`｜`G3` 两腿 `app_rc ∉ {134,139}`｜
`G4/G5` 两腿洋红 `≥ 20000`（阈值先写死；观测下界 49,864 ⇒ 余量 2.49×）｜
`G8/G9` 托管侧具名行 `[PTS-UNAVAILABLE] … err≠0` 在位｜`G10` native `PTS_GAP entry=` ≥ 1。
**自证格（走 `NOINFO`）**：`G11` 装置 `X_UP=yes`｜`G12` 两腿 `five_stable=yes`（件跑动中被换 ⇒ 读数不属于同一套件）。
**诊断格（不进 `rc`）**：`D1/D2` `colors` 参考带 800–1200｜`D3` native `err=0`（假 stub 可疑）｜`D4` `AE=0`｜`D5` `PTS_GAP seq`｜`D6` `log_bytes`。
**判序**：**有红先红**（`NOINFO` 比 `FAIL` 弱，先用弱结论会把真红洗成"算不出"）。

### 2.3 判据反转（`TASK-0302` 真实现落地后**必须同趟**改）

| 格 | 现在（止损档） | `TASK-0302` 落地后（真实现档） |
|---|---|---|
| `G4/G5` 洋红 | `≥ 20000` ⇒ 绿 | **`== 0` ⇒ 绿**（`> 0` ⇒ 红） |
| `G8/G9` 具名行 | 在位 ⇒ 绿 | **缺位 ⇒ 绿**（出现 ⇒ 红） |
| `G10` native 台账 | `≥ 1` ⇒ 绿 | **`== 0` ⇒ 绿** |

**只改一半会产出「既红又绿」的读数**（真实现后具名行消失 ⇒ `G8/G9` 判红而 `G4/G5` 判绿）
⇒ 两处**必须同趟**改。全文见 `~/w156a/w67guard/criteria-flip.md`。

### 2.4 判据节内的四要件**格式声明**（**本波不适用**，但先把格式钉住）

<!-- PREREG-REGRESSION-FOUR: same-time=yes paired=yes reproducibility=yes fisher-two-tailed=yes tool=build/MilBridge/tools/regression-decision.py -->

**为什么照模板写这一行，即使本节 2.5 已声明"本波不做任何回归判定"**：这一行是**格式承诺**、
**不是"做过"的证据**；留着它是**保险丝** —— 若将来本波真的跑了回归判定（判据节里出现判定工件的机读行
—— 本波**一次都没有产出过**），四要件必须**同趟**补齐，届时这一行就是补齐的落点，**不必再补格式**。

- **① 两臂同刻**：正极（三件应用后）与反极（删步／删清单行后）**同趟**读同一份 `verify-all.sh`／`close-wave.sh`，不跨时取数。
- **② 成对归因臂**：每条反极腿**逐件只改一处**（只删 `run_step` 行／只删 `fp_inputs()` 一行或两行／把一行换成产物路径），
  读数与正极**成对**，可归因到"就是那一处"。
- **③ 复现性**：反极腿**各跑两趟**且**逐字节相同**才算数；不重合 ⇒ 判**算不出**（不是绿）。
- **④ Fisher 双尾**：本波读的是**确定性量**（步数、件数、`rc`），**不涉及率比较**；
  若将来要拿本波的读数判回归，必须用 Fisher 双尾 ＋ "**样本量不够不许判回归**"。

**判词三态**：判过 ｜ 判**算不出** ｜ `OK`（第三种判词的行名由判据件自己的口径定义）；
判据件 = `build/MilBridge/tools/regression-decision.py`（**本波不调它**，故三态对本波只是格式承诺）。

### 2.5 本波自己的两极化（**落地前写死**）

1. **正极（必现）**：应用三件（`verify-all.sh`／`build/close-wave.sh`／本件）后
   ⇒ `bash build/MilBridge/tools/verify-all-step-check.sh` 打
   `VERIFYALL_SELF=PASS names=38 decl=38 dup=0 order=OK prose=OK`、`rc=0`；
   ⇒ `bash build/MilBridge/tools/fp-inputs-hygiene-check.sh --debug-tmp` 打
   `FPHYG_COVERAGE_N=164`、`FP_INPUTS_HYGIENE=PASS`、`rc=0`。
2. **反极（必不现）**：把新步那行 `run_step "PTS-PAGES" …` **删掉但保留声明**
   ⇒ `count-mismatch` ⇒ **必红 `rc=1`**；把 `fp_inputs()` 里新加的**两行删掉**
   ⇒ 覆盖面回 **162** ⇒ **与声明不符**；把那两行之一**换成产物路径**（`obj/…`）
   ⇒ `FP_INPUTS_HYGIENE=FAIL reason=coverage-contains-artifacts` ⇒ **必红**。
3. **成本**：新步判据支秒数实落在车道 `W160A` 的 `~/w160a/cost.md`；**不用估计值顶替**。

### 2.6 本波不做任何回归判定（**判别件，不是免死金牌**）

<!-- PREREG-NO-REGRESSION-DECISION: yes -->

**本波不做任何回归判定** —— 判据全是**确定性量**（步数、件数、`rc`、覆盖面件数），
**不涉及率比较、不做任何回归结论**；因此 `TASK-0705` 那套「回归判定四要件」对**本波**不适用。

**两条口径（缺一不可，且互为约束）**：
① 上面这行声明必须在**本判据节之内**（本节标题含「判据」）；
② **全文不得出现任何回归判定证据** —— 本波**没有跑过**判定，也没有产出判定工件
   （既不引用判定工件的机读行，也不引用它的用例台账）。
⚠️ 声明**不是免死金牌**：若某天本波真的跑了判定（有了工件），那**必须同趟把四要件补齐**，
不许用一句声明把整节判据关掉。
⚠️ 与「反转文本」的分工：`§2.3` 的反转是**判据档位切换**（止损档 ⇄ 真实现档），
**不是**回归判定 ⇒ 不触发四要件。

## §3 覆盖面（`fp_inputs()`）—— **`+2` 逐件归因**

| # | 件 | sha16（现算） | 为什么**必须**在覆盖面里 |
|---|---|---|---|
| 1 | `build/MilBridge/tools/pts-pages-guard.sh` | `d42e9395f31e3681`（14,220 B） | 判据（"**PTS 两页的页级降级必须还在**" 的**唯一实现**）：它**决定门禁判什么**（`PTS_GUARD=PASS/FAIL/NOINFO`）。改它 = 改 `PASS` 的定义 ⇒ 不纳入则**改它零机器红**（与 `tline-gate.sh`／`known-red.json`／`r-gate-step.sh` 同族） |
| 2 | `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh` | `c147a584c48d48e2`（5,829 B） | 装置：它**落证据**（`leg_*.env`／`device.txt`）而不裁决，但"**装置改了读数就改了**"（少点一下、指针移出窗口、漏一面 ⇒ 判据读到的东西就变了）⇒ 同族先例：`build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh` **已在**清单里 |

判据 = 照 `#56` 那条「**读 ⇒ 进 `fp_inputs()`**」（若判"不读"，须给"命中 0"的机械证才能不进）：

```
grep -n 'pts-pages' verify-all.sh   ⇒  第 [38] 步 `--legs` 的判据件路径（**接线后波波都读**）
grep -n 'PtsPagesProbe' verify-all.sh ⇒  装置路径（步内可见性 + 前置跑腿的落点）
```

⇒ `inputs_fp` **必移**（件数 **162 → 164**）—— 这是**声明性位移**，**不是**树里别的件动了。
成对读数（**推导，不是读数**，真值须在落仓那趟**现算**）：`4c1056dd…`（162 件）→ 加两行 ⇒ 新值（164 件）；
归因腿（W160A 已实测）：**删两行 ⇒ 回 162**、**删一行 ⇒ 163**（一行一件）。

## §4 落仓**前置项**（不满足 ⇒ `verify-all` 第一次跑本步就 `NOINFO`）

1. **判据件与装置必须同趟落仓**：`build/MilBridge/tools/pts-pages-guard.sh`（`d42e9395f31e3681`）
   ＋ `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`（`c147a584c48d48e2`）。
2. **装置五件同趟落**（装置缺任何一件都跑不动）：`run-pts-pages-legs.sh`／`session_inner.sh`／
   `navclick.py`／`shotstat.py`／`legs-to-env.py`。
3. ⚠️ **装置必须先参数化**：`session_inner.sh` 的路径是**硬编码**的 ——
   落地前先 `grep -n` 打印那一行（**禁只引行号**）：
   ```
   grep -n 'W="\$HOME/w156a/w67guard"' build/MilBridge/tests/PtsPagesProbe/session_inner.sh
   ```
   现读命中行（`~/w156a/w67guard/bin/session_inner.sh:7`，**内容锚**）：
   `W="$HOME/w156a/w67guard"; BIN="$W/bin"; DLLS="$W/dlls"; APPDIR="$W/app"`
   ⇒ `BIN`／`DLLS`／`APPDIR`／`OUT` **全从它派生** ⇒ 落仓后必须改成仓内相对/可覆盖形态
   （照 `GEOM_CORPUS`／`ARM_LOGS` 的 `<env 名>:-<默认>` 惯例）。
4. **跑腿时机**：本步在门禁里**不跑腿** ⇒ 必须写明"谁在什么时候把 `evidence/` 跑出来"
   （否则本步 `NOINFO` = ❌）。建议挂在波内既有的交互步之后、`verify-all` 之前。

## §5 射程边界（如实划界，不许读成绿）

1. 本波**只**保证"止损还在"，**不**保证"该被真实现"（那是 `TASK-0302`）。
2. 抓不到"下游真缺口（`LoCreateContext` 等）被顺手 stub"。
3. 门禁里**不在同步步内跑腿** ⇒ "证据一定是本趟新跑出来的"这条**本波不声称**；
   证据缺席／不满 2 腿 ⇒ 牙**响亮 `NOINFO`**（**不是绿**）。
4. 新步**不改任何产品件** ⇒ 九位（`win32shim`／`pc`／`pf`／`wb`／`bridge`／`wic`／`probe`…）逐位不动。
