# 波 `#75` 预登记（**四件合波**：`TASK-0736` ＋ `TASK-0737` ＋ `TASK-0738` ＋ `TASK-0739`）

- **本波是合波**（主控裁定，为减少串行链数）：原各需一波的四件**装置/判据卫生**合成**一条变更集一次冻结**。
- **零产品改动**：不碰 `src/**`、不碰任何 shim、不碰产品路径 ⇒ 世代九位里只有环成员位移。
- 四件都是「**装置/判据卫生**」：判的是**牙自己**（自述 vs 接线／默认路径／比较域／自起进程），
  不是产品行为。

## 1 范围（逐件）

| 件 | 缺陷 | 落点 | 判词 |
|---|---|---|---|
| `TASK-0736` | `D-G136` 件头自述 vs 接线不符 | 改 `build/MilBridge/tools/prereg-four-requirements-check.sh` 件头自述 ＋ **新牙** `build/MilBridge/tools/selfdescription-wiring-check.sh` ＋ **接线为一步** | `SELFDESC_WIRING=PASS\|FAIL\|NOINFO` |
| `TASK-0737` | `D-G137` 落地件默认路径指向车道目录 | **新牙** `build/MilBridge/tools/lane-path-check.sh` ＋ **声明式出处清单** `build/MilBridge/lane-path-provenance.tsv` ＋ **同趟修三处真默认值** | `LANEPATH=PASS\|FAIL\|NOINFO` |
| `TASK-0738` | `D-G138` 比较域把"标签"混进"读数" ⇒ 假红 | **新牙** `build/MilBridge/tools/rows-identity-check.sh`（吃**在册确定性语料**） | `ROWS_IDENTITY=PASS\|FAIL\|NOINFO` |
| `TASK-0739` | `D-G139` 长跑自起显示位不收 ⇒ 跨波慢性泄漏 | 改 `verify-all.sh`（**自起 PID ＋ `trap` 按 PID 收**）＋ **新牙** `build/MilBridge/tools/xvfb-census-check.sh`（**链前自含基线**普查） | `X_CENSUS=PASS\|FAIL\|NOINFO` |

**`TASK-0739` 的第三支（显示位改"租用"、去掉硬编码 `:97`／`:99`）本波 `NOINFO`**：
硬编码在**仓外车道件**里，且与 `D-G59`「复用别人几何相符的显示」的**故意行为**冲突 ⇒
**另开一波**，本波**不塞**。

## 2 判据（**判据先写**；四件各自的三态见 `~/w173a/w75/criteria.md`）

- **本波不做任何回归判定** —— 四件全部是**装置/判据卫生**，判的是牙自己，不判产品回归。
  <!-- PREREG-NO-REGRESSION-DECISION: 本波为零产品改动的仪器波，四件均判装置/判据卫生，不做任何回归率比较 -->
- **三态口径（四件通用）**：`PASS`／`FAIL`／`NOINFO`；**`NOINFO` 不算绿**（本仓铁律）。
- **空边必须响亮失败**：扫描集为空／清单缺席／语料缺席／`ps` 读不到 ⇒ 一律 `NOINFO`，
  **禁**把"一条都没读到"读成"没有一条命中"（纪律 27）。
- **只加不删**：四处声明（`DECL`／`STEP-NAMES`／口径句／本件 H1）**同趟**改；既有步序**一字不动**。
- **`D-G140` 口径（全量断言必须写明语料＋时刻）**：本波的两处"全量"断言 ——
  ① `TASK-0737` 的出处清单普查（语料＝`build/MilBridge/tools/*.sh` ＋ `build/MilBridge/tests/**` 的
  **代码件** `*.sh`／`*.py`；**每次运行重扫**，读数里带 `examined=` 与 `hits=`）；
  ② `TASK-0739` 的显示位普查（语料＝`ps -eo pid=,args=` 全机 `Xvfb :` 进程 ＋ `/tmp/.X11-unix/` 成员；
  **每次运行重扫**，读数里带 `X_CENSUS_AT=` 与 `X_CENSUS_SRC=`）—— 都是**接线牙**，不是一次性扫描结论。

## 3 两极化（**必须真跑，不许只设计**；逐条原始读数见 `~/w173a/w75/polarity.md`）

| 件 | 正极（必绿） | 反极（必红／必变） |
|---|---|---|
| `0736` | 件头"已接线" ∧ `^run_step` 命中 ⇒ `PASS` | 件头"未接线" ∧ 命中 ⇒ `FAIL rule=forward…`；件头"已接线" ∧ 零命中 ⇒ `FAIL rule=reverse…` |
| `0737` | 三处真默认值改完 ＋ 声明齐全 ⇒ `PASS` | 可执行行上车道路径 ⇒ `FAIL rule=code-default-lane-path`（**写进清单也照样红**）；未声明的 `comment` ⇒ `FAIL rule=undeclared-lane-path-mention`；现读 > 上限 ⇒ `FAIL rule=provenance-tree-grown` |
| `0738` | 只标签差异 ⇒ `PASS` ＋ **必印** `LABEL_ONLY_DIFF fields=…` | 读数真差异 ⇒ `FAIL`；**标签也相同 ⇒ 不得印** `LABEL_ONLY_DIFF`（阴性对照，防"恒印"） |
| `0739` | 自起 ⇒ 收尾后该号无进程；复用/没起过 ⇒ **一个都不杀**；基线不变 ⇒ `PASS` | 新增"非本趟"存活显示位 ⇒ `FAIL` ＋ 点名 PID；新增**无主** socket ⇒ `FAIL reason=orphan-socket-residue` |

## 3b 主控裁定（`hidden-only-step.sh`）：**射程缩减必须显式可见 ＋ 出处必须记下来**
- `HIDDEN_ONLY_OLDPC` 的车道默认值改掉后，第 `[19]` 步 `HIDDEN-ONLY` （**更正**：门禁跑生产模式，**多打 3 条「未取到」/ `skip=` 这一格都不存在** —— 见文末更正节）
  （**判词仍 `PASS`**）⇒ 裁定：**接受该射程缩减，但不许把 `PASS` 读成「全射程通过」**：
  ① 判词**行尾**挂 `${OLDPC_NOTE}`（`range-reduced reason=oldpc-not-in-repo` ／ `…not-on-disk path=…` ／ **空**）；
  ② 出处清单里落 **`# RETIRED`** 记录（牙校验形状；逐条上屏 ＋ `LANEPATH_RETIRED n=`），
     写明那条夹具**是什么／在哪／谁造的／何时／怎么恢复**（`when` 只写现取到的，取不到就写"未取到"）。
- ★ **声明值（落纸）**：`hidden-only-step.sh --selftest` 现读 `HIDDEN_ONLY_SELFTEST=PASS cases=12 pass=12 fail=0 skip=1 range-reduced reason=oldpc-not-in-repo`（**声明值 `skip=1`**；门禁 `[19]` 无此格）。
  `skip=1` 是**本波声明的射程代价**（**只许来自现读**）（判词行里 `skip=$nsk` **现算**，不许改成常量）；
  **对账**：链跑完 `bash ~/w173a/w75/landing.sh --root $R --check-skip-decl <冻前 verify-all 日志>`
  ⇒ `OK(0)`／`MISMATCH(9 ⇒ 停手报主控，不许当场改声明值)`／`NOINFO(3 ⇒ 未取到不算绿)`。
- ★ **三极化的腿 3 是防"恒挂"腿**（`OLDPC` 指向真存在文件 ⇒ 后缀**必须为空**）：恒挂会把"射程完整"
  也读成缩减 ⇒ 判词作废；抽块守卫（抽出行数 > 20 ⇒ `NOINFO`）同趟保留。
- 另两处（`geom-revert-beat-check.sh:93` ⇒ `mktemp -d`；`tests/W81AWindowProbe/run-w81a-legs.sh:59` ⇒ `$HOME/.cache/wpf-linux/w81a-out`）
  **不在门禁** ⇒ **门禁读数零变化**，照实记档。

## 4 声明与账（**落仓那刻一律现取**；本件不写死步号／件数）

- **新件 5**：`selfdescription-wiring-check.sh`／`lane-path-check.sh`／`lane-path-provenance.tsv`／
  `rows-identity-check.sh`／`xvfb-census-check.sh`（全在 `fp_inputs()` 覆盖面内 ⇒ 覆盖面 **+5**）。
- **改件 6**：`prereg-four-requirements-check.sh`（件头一处）／`hidden-only-step.sh`（一处默认值）／
  `geom-revert-beat-check.sh`（一处默认值）／`tests/W81AWindowProbe/run-w81a-legs.sh`（一处默认值 ＋
  一处陈旧注释）／`verify-all.sh`（四处声明 ＋ 自起 PID/`trap` ＋ 链前快照 ＋ 四步）／`build/close-wave.sh`
  （白名单 +5 行）。
- **步数**：现取 ⇒ **+4 步**（`SELFDESC-WIRING`／`LANE-PATH`／`ROWS-IDENTITY`／`X-CENSUS`）。
- **覆盖面**：现取 `C` ⇒ **`C+5`**，且 `verify-all.sh` 步本体里的 `--expect` **同趟**改成 `C+5`
  （漏改 ⇒ `FAIL reason=files-n-mismatch`，方向安全）。
- ⚠️ **`verify-all.sh` 不在覆盖面**（现取：`fp_inputs()` 里只有 `find … -name 'close-wave.sh'` 与显式清单）
  ⇒ 改它**不动** `inputs_fp`；改 `build/close-wave.sh` **必动**（本函数自含 `close-wave.sh`）。
- ⚠️ **`prereg-four-requirements-check.sh` 不在覆盖面**（现取 `grep -n 'prereg-four' build/close-wave.sh` = 0 命中）。

## 4b **放行条件（`#75` 冻结前必须兑现）**：射程声明**当场销账**
链里（`冻前 verify-all` 之后、`冻结` 之前）跑一行：
`bash ~/w173a/w75/polarity/skip-decl-freeze-hook.sh --log <冻前 verify-all 日志> --out <冻结报告片段>`
⇒ 读数写进**冻结报告**：`SKIP_DECL_FREEZE=OK declared=1 observed=1 range_reduced=yes` ⇒ 正常冻；
**`MISMATCH` ⇒ 停手报主控**（**不许**当场改声明值、**不许**把声明值改成"实得"）；
`NOINFO` ⇒ **不算绿**，写进报告并**点名 reason**（`no-verdict-line`／`log-absent`／`log-unreadable`／`skip-field-unparsable`）。
逐字命令／期望读数／硬边界见 `~/w173a/w75/PRE-FREEZE-HOOKS.md`；钩子自测 **8/8**，判据牙自测 **7/7**。

## 5 硬前置（缺一即停手报主控）

1. **`0736` 件头补丁 ＋ 新牙 ＋ 接线三者同趟**（牙件头自己写着"必须与接线同趟"，否则当场自报 `rule=reverse`）。
2. **三处真默认值必须同趟修**：不修 ⇒ 新牙落地**当场红** ⇒ 本波冻不了。
3. **`--expect` 与覆盖面同趟改**（现取件数）。
4. `#74` 落地后 **re-anchor 现取五格**（`verify-all.sh` sha16／首行 `DECL` 步数／`^run_step "` 计数／
   `--expect` 现值／`close-wave.sh` sha16 ＋ 实跑 `fp_inputs()` 现算件数）；结构不变量不成立 ⇒ `rc=9` 拒跑。

## ✍️ 声明值更正（`2026-09-26 12:5x`；主控裁定 **(甲)**，**本节的声明值取代前文**）
**前提更正（逐字，三处同趟）**：
1. **门禁里第 `[19]` 步跑的是生产模式**（`run_step "HIDDEN-ONLY" bash …/hidden-only-step.sh`，**没有 `--selftest`**）
   ⇒ 判词是 `HIDDEN_ONLY_STEP=PASS 判定例=32/32 …`，**根本没有 `skip=` 这一格**；
   而 `HIDDEN_ONLY_OLDPC` 与 S12/S13/S14 **只存在于 `--selftest` 里** ⇒ **门禁的射程一点没缩**。
   ⚠️ 因此前文任何「门禁射程**未缩**（生产模式无 `skip=` 格）／`[19]` 会多打 3 条未取到」的说法**一律作废**（`D-G146` 同族：声明比实况强）。
2. **射程缩减 ＋ S12/S13/S14 只在 `--selftest`**。
3. **现读**（经重活槽真跑 `hidden-only-step.sh --selftest`，`held≈7 s`）：
   `HIDDEN_ONLY_SELFTEST=PASS cases=12 pass=12 fail=0 **skip=1** range-reduced reason=oldpc-not-in-repo`
   —— 更正：**`cases=12`**（不是 14）；**`--selftest` 耗时 ≈7 s**（先前那句"110–160 s"是**生产模式**的耗时）。
4. ⇒ **声明值 = `skip=1`**（**只许来自现读**，不许来自任何人的转述）；`range-reduced reason=oldpc-not-in-repo` 后缀在真跑里可见 ✓。
5. **销账钩子的输入必须指 `--selftest` 的日志**（链条日志里没有这一格）⇒ 冻结报告那一格应为
   **`SKIP_DECL_FREEZE=OK declared=1 observed=1 range_reduced=yes`**（`MISMATCH` ⇒ 停手；`NOINFO` ⇒ 不算绿并点名 reason）。
