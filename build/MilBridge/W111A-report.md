# W111A 报告 —— 波 `#51` 尾部两条发现登记 ＋ 收口地图 ＋ 推第八笔文档

车道 = **W111A**｜`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**非 git 仓**）｜fork 克隆 `C=~/netTest/GitProj/WPFOnLinux`（推送用）
时段 2026-09-22 **21:45 → 21:55 +0800**｜kernel 6.8.0-138-generic｜loadavg `1.07/1.38/1.22`｜`MemAvailable = 2592 MB`（`free -m` 三值 `7923/5034/2592`）
**纪律口径**：**零 `dotnet`／零构建／零门禁／零应用／不占重活槽**（本件全程 = 读文件 ＋ 三次 `--emit`／`defect-registry-check`（纯读，不跑 harness）＋ 一次 `git push`）；**零 `pkill -f`**；**未碰**冻结基线 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（收工现场复算仍 **`38e67e834430d75c`**）、`docs/CURRENT-STATE.md:9`、`build/verify-all.sh`、`build/close-wave.sh`、任何产品件、`known-red.json`、三件 `build/MilBridge/tools/{r-gate-step,nul-bytes-check,wm-awaited}.sh`、`applier-audit-expected.txt`、`~/w105a/**`／`~/w109a/**`／`~/w110a/**`。

## §0 结论（**结论在前**）

1. **两个新号** = **`D-G98`**（退出最大化后"窗态掉了、几何没回来"的**间歇残留**）／**`D-G99`**（**回归判定**规则"`A` 臂红而 `B` 臂同腿绿 ⇒ 判回归"对**间歇**现象**不充分**）。**末号现场核 = `D-G97`**（`grep -oE 'D-G[0-9]+' 声明表 | sort -u | tail -1` ⇒ 只有它是末号时才取 `D-G98`／`D-G99`）⇒ **连续取号、无跳号**。
2. **两条新 TASK** = **`TASK-0110` [Next] 🔴**（几何还原残留：查"WM 为什么不把退出最大化的几何收回去"，**判据要先写且必须能抓 frame/client 时序分离**）／**`TASK-0705` [Next] 🔴**（把"回归判定"**四要件**写进**预登记模板**，缺一即 `NOINFO`）。
3. **`DEFREG`** = `DEFREG=PASS declared=135 route_ids=135` ＋ `DEFREG_DECLDRIFT=0`、`rc=0`、**连跑两遍逐字节相同**；**假绿探测**（**不** `--emit` 那一趟）当场 **`FAIL rc=1`** 并**逐个点名** `D-G98`／`D-G99` ⇒ 声明表这一侧的两极化**成对成立**。
4. **推送（第八笔）** = `084afe0..c4f142c`；`HEAD(local)` == `remote-tracking` == `ls-remote origin HEAD` **三者一致**、`--symref` 仍 `refs/heads/feat-Linux`；**逐件字节核对 `BYTECHECK ok=13 mismatch=0 nobody=0`**（含冻结基线 = `38e67e834430d75c` 逐位未动）。
5. **`fp_inputs` 零影响**（机械证）：覆盖面 **149 件**里本件 4 件**命中全 0** ⇒ 指纹 **开工 = 收工 = `58a6c0945b7d5358…`**（逐位相同）。
6. ⚠️ **一处更正（本件现场核出来的，不是照抄）**：W110A §7.4 点名的 **7 件不推件** 里，`build/MilBridge/src/MilBridge.Resolver/README-合并写.txt` **早已在册**（首笔 `a394a47` 就 track、`HEAD` blob = `347d4a475ab62197` = 磁盘值，1667 B **逐字节相同**）⇒ **真"未推"的是 6 件**（1 件日志 ＋ 5 件 `#48`–`#50` 遗留账本）。口径句已按**事实**写进 §15g（见 §5）。

| 件 | before sha16 | after sha16 | 大小 B | 增减 |
|---|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `5c51bff8f0353ed6` | **`cf710ed6ff09a6e2`** | 460,425 → 468,154 | +7,729 |
| `docs/ROUTES.md` | `69b2bbd3a82c3b47` | **`13aa13eab158ba49`** | 93,260 → 103,742 | +10,482 |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `ff0f400674888823` | **`da59e40a44233e22`** | 6,212 → 6,306 | +94 |
| `build/MilBridge/W111A-report.md`（本件，新建） | — | 见文末末行 | 见文末 | 新建 |

`wc -l` 复核（**行锚定改法的硬要求**）：`KNOWN-DEFECTS.md` **2580 → 2611**（+31 = 追加块行数）｜`docs/ROUTES.md` **469 → 494**（+25 = 6+6+13）｜声明表 **142 → 144**（+2 = 两个新号）。

## §1 判据（**先写**，早于任何编辑）

`~/w111a/criteria.md`（**sha16 `6711a4ee0860a7e0`**，写入时刻 21:48；**本报告第一次编辑发生在 21:49:29** ⇒ **判据确实先于改动**）。八条要点：

- **`C1`** 取号前**现场核末号**；**不许写出不存在的编号字面量**（W107A 幻影教训：`--emit` 用 `grep -noE` 全文抓编号 ⇒ 散文里一个不存在的号会**当场多出一行幻影声明**）⇒ 判词里引用的每个号**先确认已在册**。
- **`C2`** 每条判词**四要素**：① 现象（字段 = 值逐字）② 比例与间歇性（分子/分母 ＋ **臂名 ＋ 被测件 sha16**）③ 归因臂／排除机制（**独立于①**）④ `NOINFO` 层。**任务书给的历史读数一律现场复算后才写**；复算不出写 `NOINFO`。
- **`C3`** 地图改动用**行锚定**；改后 `wc -l` = 改前 ＋ 本步新增，且**另数关键锚**。
- **`C4`** `--emit` 后**连跑两遍** `defect-registry-check.sh`：必须 `DEFREG=PASS`／`DECLDRIFT=0`／`rc=0` 且两遍**逐字节相同**；`declared` 增量**必须**等于新号数。
- **`C5`** `fp_inputs` **零影响**：开工/收工各跑真调用 ＋ 覆盖面成员清单逐件 `grep -c` = 0。
- **`C6`** 推送：**逐径 `git add`**（不许 `-A`／`--force`）＋ `fetch → push → 重新 fetch ＋ `ls-remote` 交叉核` ＋ 逐件 `cmp`。
- **`C7`** **假绿探测**：**不** `--emit` 那一趟必须先取读数（新号在册、声明里没有 ⇒ 必须红或 `NOINFO`）。
- **`C8`** 任一步与判据不符 ⇒ 停下如实报；**不许**为让某格变绿而放宽判据。

## §2 ① 两个新号：判词逐字

落点 = `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（**只追加**：`D-G98` 在 **`:2582-2603`**（22 行）、`D-G99` 在 **`:2604-2611`**（8 行）；段头 **`:2185`** **只加不改**地补了一段"＋ `#51` 冻后新登记（`D-G98`…`D-G99`，2026-09-22，车道 W111A）"）。

### 2.1 `D-G98`（**产品/装置界面缺陷 · 几何还原残留**）判词要件

- **现象（字段 = 值，逐字）**：`AFTER_R2 state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok=0`｜`AFTER_R2_SETTLED state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok2=0 frame=0x2003bc fgeom=1280x1024@+0+0` ⇒ 两个 `MAXIMIZED_*` **确实掉了**（**窗态还原发生了**），而 **client 几何**与 **WM 自己的 frame 几何**（`fgeom`）**双双卡在最大化值** ⇒ **WM 没执行"退出最大化的几何还原"**，不是"应用没请求"。
- **比例与间歇性（两臂，同装置同一会话、同 26 腿同顺序、只换 shim 一个文件）**：

  | 臂 | 件 | 26 腿 | 同腿成对归因臂 | 当代合计 |
  |---|---|---|---|---|
  | A（含 `P2`） | `2a297d6fee8be389` | 红 **3**（`C-m2r2-2`／`C-m2r2-5`／`C-m1r2-2`） | 10 趟红 0 | **3/36** |
  | B（**无 `P2`** 旧冻结件） | `33352e5797031999` | 红 **1**（`C-m2r2-1`） | 10 趟红 1（`W105A-C2-p09-old`） | **2/36** |

  **Fisher 精确检验（本件**现场复算**，用 `math.comb` 逐表求和，非手抄）**：`3/36 vs 2/36 ⇒ p = 1.000`｜`3/26 vs 1/26 ⇒ p = 0.610`｜`0/10 vs 1/10 ⇒ p = 1.000`｜`3/27 vs 2/32 ⇒ p = 0.652` ⇒ **没有任何一项能分开两件** ⇒ **不是本波（`P2`）引入**。⚠️ 反向也写明：**没证明**发生率相等（36 趟/件只见得着"相差 ≥4 倍"这一档）。
- **归因臂 ＋ 排除机制（独立于上表）**：成对交替臂（同腿 `M2×R2`、旧/新各 10 趟、对间交替先后、每趟全新进程树、两件都是冻结副本且带 sha16 前置断言）＋ **外部只读观测器** `~/w105a/bin/hints-watch.sh`（每 ~0.2 s 读 `WM_NORMAL_HINTS`／`_NET_WM_STATE`／几何）。红的那一趟落在**旧件**（`p09-old`，**那一趟根本没有 `P2` 代码**）且**观测器全程记录**：轨迹 `t=0.00 800x600@+240+212` → `t=8.92 1280x1024@+0+0 [MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED]` → `t=14.17 1280x1024@+0+0 [_NET_WM_STATE_FOCUSED]`；20 趟逐趟逐采样的提示并集**只有 `program specified minimum size: 1 by 1`、没有任何 `maximum size`** ⇒ **明确排除**"`P2` 写提示把窗口卡住"。
  另：**不是"点击被吞"** —— 装置判词就是落地计数：**52 趟全 `m_ok=1`**、`r_ok=1` **46/50**、**4 条红的 `m_ok` 都是 1**。
- **交叉引用**：首次登记 = `build/MilBridge/W89A-report.md` §5.3（外部臂 `M3×R2` 的 `F-btn3`／`F-btn4`，**2/15**）；W77A §3.6 在**应用自发**那条路的**修前件**上见过同形（`AM1R2v4_a/_b`）⇒ 本条**独立立号**（此前只挂在 `TASK-0205` 行的"残留"里）。
- **`NOINFO`**：已量到"窗态掉了、client 与 frame 都卡住"，但**没抓到 frame/client 的时序分离**、**没量 WM 内部状态** ⇒ **"WM 为什么没收回几何"未归因**；两臂速率差的显著性**判不出**（要每臂数百趟）。**处置 = 只登记未修**，落地 = `TASK-0110`。

### 2.2 `D-G99`（**判据缺陷 · 样本量与随机性**）判词要件

- **现象**：W105A 判据 §4 C3 **原文** ="若 **A 臂红而 B 臂同腿绿** ⇒ 单变量归因成立 ⇒ **判 `C1 = FAIL`（回归）**"；实测 A 臂三条红腿在 B 臂**同腿全绿**⇒ 按字面该判"回归"，但 **B 臂自己在另一条腿上红了同一形态**（`C-m2r2-1`）⇒ 该推理**不成立**。
- **坏在哪**：**一条腿一个样本分不开"件相关"与"随机"** —— 新件 `3/26` 红、旧件 `1/26` 红，而**成对**臂上红的那一趟落在**旧件** ⇒ "哪条腿红"**不随件走** ⇒ 会把**间歇残留误判成回归**（方向 = **假红**）。W105A 的处置 = **照字面判 `C1 = FAIL`（不悄悄改判据）** ＋ **如实报**归因结论为"既有间歇残留"，**两条都留档由收尾链裁定**。
- **现场读数**：当代 **`3/36 vs 2/36`、Fisher 双尾 `p = 1.000`** ⇒ 判不出差别。
- **正确姿势（口径句，已进 §15g）**：**四要件**（两臂同刻 ＋ 成对归因臂 ＋ **复现性：在旧件上也要能复现该红** ＋ Fisher 双尾），**缺一即只能 `NOINFO`**。
- **与 `D-G94` 的关系**：**同族但判词不同、不许合并** —— `D-G94` 坏**分母口径**（把"没点"算进分母），本条坏**样本量与随机性** ⇒ 独立立号。
- **`NOINFO`**：本条**只登记判据缺陷、不含修法**（修法 = 写进预登记模板 = `TASK-0705`）；"**全仓还有几处预登记用了同款单腿推理**"**未逐处枚举** ⇒ `NOINFO`。

## §3 ② 两条新 TASK 逐字（`docs/ROUTES.md` §14 内，行锚定插入）

- **`TASK-0110` [Next] 🔴**（`:385-390`，6 行）：**几何还原残留：查"WM 为什么不把退出最大化的几何收回去"**（来源 = W105A §4.2／§9.1 ＋ W89A §5.3）。要点：① **现行 `AFTER_R2`／`AFTER_R2_SETTLED` 两拍不够** ⇒ 判据**必须在还原那一瞬加中间拍**（同趟逐拍读 `_NET_WM_STATE`／client 几何／`xwininfo -frame` 的 frame 几何／`_NET_FRAME_EXTENTS`），把"**先掉状态、几何滞后**"与"**状态掉了、几何再不动**"分开；② 三个候选机制（应用请求缺让 WM 重算几何的那一拍／client-frame 尺寸协商顺序／WM 内部状态机不同步），**每个都要先写"怎么证伪"**；③ **红判据** = "状态不含 `MAXIMIZED_*` 且 client 与 frame 都 ≠ 基准"**连续 ≥N 拍**（`N` **先写死**）；**反极性** = 修法拆掉后回到**同形**；④ 分母口径照 `D-G94`（`m_ok`／`r_ok` 并列报），**不承诺**在几十趟里给显著性结论。
- **`TASK-0705` [Next] 🔴**（`:417-422`，6 行）：**把"回归判定"的口径写进预登记模板**（来源 = W105A §4.5 的 `F1` ＋ §15g 口径句）。要点：① 落地前**先核"哪一份是权威模板"**，核不到 ⇒ `NOINFO`；② 模板里**必须**写死**四要件**（两臂同刻／成对归因臂／**在旧件上也要能复现**／Fisher 双尾 ＋ "样本量不够不许判回归"）；③ **这条任务自己也要有牙**：用 `D-G98` 的读数（`3/36 vs 2/36`、`p = 1.000`）做**"不许判回归"的负例**、用确定性差异做**"必须判回归"的正例**；④ **不许**改已冻结的预登记件、**不许**倒填进既有报告美化历史判词；⑤ 本行**只立号、未写模板**；"还有几处用了同款单腿推理"**未逐处枚举** ⇒ `NOINFO`。

## §4 ③ 地图：新 §15g ＋ `wc -l` 复核 ＋ diff 机器证

- 新段 **`docs/ROUTES.md` §15g**（`:483-494`，13 行，标题逐字）：`## §15g \`#51\` 收尾链闭合（\`38e67e834430d75c\`）＋ 两条新登记 \`D-G98\`／\`D-G99\` ＋ 两条新 TASK ＋ 两条口径句（**一行一条**；2026-09-22 车道 W111A 补）`，含 10 条 bullet：
  1. ✅ **`#51` 收尾链闭合**（**三句都要有**）：① 冻结 = `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **`38e67e834430d75c`**（`BASELINESHA`／`BASELINEGEN(#51)`／`BASELINEDUP(n=0)` 三牙全 PASS）② **冻后 `verify-all` ×2 = 27/27 全绿** ③ 推送 = 远端 head **`084afe0319623d54`**、`--symref` 仍 `feat-Linux`。
  2. ✅ **`TASK-9907` 接线已落地**：新第 `[27]` 步 `NUL-BYTES` = `build/MilBridge/tools/nul-bytes-check.sh`；`VERIFYALL-STEPS-DECL: 27 gen=#51`；`fp_inputs()` 同趟纳入该件 ⇒ 覆盖面 **147 → 149 件**、`inputs_fp` 现值 **`58a6c0945b7d5358…`**（本件现场真调用复算逐字相同）；⚠️ 该步的绿**只等于"声明覆盖面内 0 件含 NUL"**。
  3. 🔁 **`pf` 又自变一次**（`215c856cbca9922b → bc2c47ac7b067bad`，**同尺寸**）⇒ **`D-G92` 现场再证**，**三句都要有**：构建输入逐字相同／只有 `pf` 这一位变且同尺寸 ⇒ **构建身份本身不可复现**／冻结块里 `pf` 只作"冻结那一刻"的现场值、**不许**当漂移或回归判据。
  4. 📌 **口径句（"回归判定"）**：四要件 ＋ **单臂 26 趟只见得着"相差 ≥4 倍"**这一档（现场反例 = `D-G98` 的 `3/36 vs 2/36 ⇒ p = 1.000`）。
  5. 📌 **口径句（"哪些件不推"）**：6 件 ＋ **1 件更正**（逐字见 §5）。
  6.–9. 🆕 `D-G98`／`D-G99` 登记摘要 ＋ 🆕 `TASK-0110`／`TASK-0705` 两行。
  10. **本件写域与零影响**：4 件全**不在** `fp_inputs()` 覆盖面 ⇒ 指纹开工 = 收工；`DEFREG_DECLDRIFT` **3 → 0**（那 3 处陈旧锚点是 `#51` 冻结改了 3 份 route 件造成的，本件顺带钉齐）。
- **`wc -l` 复核**：`docs/ROUTES.md` **469 → 494**（**恰好 +25** = `TASK-0110` 6 行 ＋ `TASK-0705` 6 行 ＋ §15g 13 行）；`grep -n` 现场定位：`TASK-0109` 仍 `:380`、`TASK-0110` `:385`、`TASK-0703` `:391`（原 `:385`）、`TASK-0704` `:397`、`TASK-0705` `:417`、`TASK-9907` `:423`（原 `:411`）、`## §15` `:427`、`## §15f` `:476`、`## §15g` `:483`。
- **diff 机器证（防"编辑吞掉下一行"）**：`diff ~/w111a/ROUTES.before.md docs/ROUTES.md` ⇒ **`^<` 行数 = 0**、**`^>` 行数 = 25** ⇒ **纯追加、零改动、零删除**。`KNOWN-DEFECTS.md` 同理：`diff ~/w111a/KD.before-append.bak 本件`（备份取在**段头改后、追加之前**）⇒ **`^<` = 0、`^>` = 31** ⇒ 追加**纯增量**；段头那次改动是**同一行内扩写**（`460425 → 460501 B`，`wc -l` 不变 ⇒ **没吞下一行**），旧锚 `＋ \`#50\` 冻后第五笔登记（\`D-G97\`…` 现场 `grep -c` 仍在（1 命中）。

## §5 ④ 那 7 件不推的口径行（**逐字**）＋ 本件现场的**更正**

§15g 里那一条 bullet 的逐字：

> 📌 **口径句（"哪些件不推"，固定住、免得后人反复复议）**：以下 **7 件** —— `build/.applocal-selftest.log`｜`build/MilBridge/gen/tline-ledger-lines-20260921-{1224,1231,1540,1623,1629}.txt`（5 件）｜`build/MilBridge/src/MilBridge.Resolver/README-合并写.txt` —— **都不在** `fp_inputs()` 覆盖面、**不参与任何判据**，性质 = **运行日志／`#48`–`#50` 遗留账本／来源未清的散件** ⇒ **一律不推**（车道 W110A §7.4 逐件提名、**主控裁定维持"不推"**）⇒ **不许**为了让 `git status` 干净而把它们塞进任何后续提交。

⚠️ **本件现场核出的更正（必须记，免得后人按错事实引用）**：这 7 件里**只有 6 件**是真"未推"，第 7 件的措辞与事实不符 ——

| # | 件 | `$R` 磁盘 sha16 | 克隆磁盘 | 在 `HEAD` 里？ | 历史提交数 | 结论 |
|---|---|---|---|---|---|---|
| 1 | `build/.applocal-selftest.log` | `678b862ec893d75d`（10,666 B） | **缺** | **不在** | **0** | 真未推 |
| 2–6 | `build/MilBridge/gen/tline-ledger-lines-20260921-{1224,1231,1540,1623,1629}.txt` | `ae98f3266827f4f4`／`123af04cc2d7fa10`／`76a2be7ece9c4c66`／`76a2be7ece9c4c66`／`76a2be7ece9c4c66` | **缺** | **不在** | **0**（`git log --all` 逐件 0） | 真未推 |
| 7 | `build/MilBridge/src/MilBridge.Resolver/README-合并写.txt` | `347d4a475ab62197`（1,667 B） | `347d4a475ab62197` | **在**（blob = `347d4a475ab62197`，1667 B） | **1**（首笔 `a394a47`"整树搬入"） | ⚠️ **早已在册、与磁盘逐字节相同** ⇒ 不是"未推"，而是"**无需推**" |

⇒ **真"未推" = 6 件**（1 件日志 ＋ 5 件遗留账本）；"**一律不推**"这个**政策**不变（主控裁定），但**第 7 件的理由**应由"来源未清的散件"更正为"**已在册且同值**"（本件**未改** W110A 报告一字，只在本报告与 §15g 记事实）。

## §6 ⑤ `DEFREG` 两条机读行（**连跑两遍**）＋ 假绿探测（成对）

```
# ── 假绿探测（C7：改动后、--emit **之前**）──
$ bash build/MilBridge/tools/defect-registry-check.sh
DEFREG_DECL=n=133 route_ids=135 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=cf710ed6ff09a6e2 CS=b7b2d513cfdab2eb HO=e4dc264200b421d0 AB=38e67e834430d75c
DEFREG_EXTRA=KRJ=089b7324ba12e022 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=4 changed-route-files-since-DECL-GEN
DEFREG=FAIL reason=undeclared-id-in-route
  D-G98 first-seen=KD:2185 route=/…/samples/WpfFeatureProbe/KNOWN-DEFECTS.md
  D-G99 first-seen=KD:2185 route=/…/samples/WpfFeatureProbe/KNOWN-DEFECTS.md
rc=1                      ← **新号在册而声明表没有 ⇒ 当场红、逐个点名** ⇒ 这一侧不是"改完就绿"的空成立

# ── 重生成 ＋ 连跑两遍（C4）──
$ bash build/MilBridge/tools/defect-registry-check.sh --emit > build/MilBridge/tools/defect-registry-declared.tsv   # rc=0
$ bash build/MilBridge/tools/defect-registry-check.sh    # run 1
DEFREG_DECL=n=135 route_ids=135 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=cf710ed6ff09a6e2 CS=b7b2d513cfdab2eb HO=e4dc264200b421d0 AB=38e67e834430d75c
DEFREG_EXTRA=KRJ=089b7324ba12e022 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=135 route_ids=135（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
rc=0
$ bash build/MilBridge/tools/defect-registry-check.sh    # run 2（逐字节相同，diff 空）
（同上五行，逐字相同）    rc=0
```

- **增量对账（C4 要求）**：编号集合 `diff`（去注释行、`cut -f2 | sort`）⇒ **只有 `> D-G98`／`> D-G99` 两行** ⇒ **`declared` `133 → 135`（+2，恰等于新号数）**、**无幻影、无掉号**。
- **`--emit` 幂等**：再跑一次 `--emit`，与盘上声明表 `diff`（去掉 `# DECL-GEN` 时间戳行）⇒ **空** ⇒ `EMIT_IDEMPOTENT=yes`。
- ⚠️ **声明表的变更不止"加两行"（如实报，逐条）**：除 `# DECL-ANCHORS` 锚点行（`KD`／`CS`／`AB`／`KRJ` 四处因 `#51` 冻结与本次登记而更新）外，**5 条既有 ID 行的 `req=`／`present=` 被拓宽**（逐字）：
  ```
  D-G82  req=KD     present=KD        →  req=KD,AB   present=KD,AB,KRJ
  D-G88  req=KD,AB  present=KD,AB     →  req=KD,AB   present=KD,AB,KRJ   （req 不变、只 present 加 KRJ）
  D-G91  req=KD     present=KD        →  req=KD,AB   present=KD,AB
  D-G92  req=KD     present=KD        →  req=KD,AB   present=KD,AB,KRJ
  D-G97  req=KD     present=KD        →  req=KD,AB   present=KD,AB,KRJ
  ```
  原因是 **`#51` 冻后这几条编号也进了 `ACCEPTANCE-BASELINE.md`／`known-red.json`**，而盘上声明表停在 `#51` 冻结**之前**（现场诊断行 `DEFREG_DECLDRIFT=3`）。**本件 `--emit` 顺带把这批陈旧锚点钉齐**（收工 `DECLDRIFT=0`）。**这不是本件新增的编号**（编号集合 `diff` 只有 `+D-G98`／`+D-G99` 两行，见上一条），改动前副本 = `~/w111a/decl.before.tsv`。
- **三件未被碰**（C4 明令）：`CS`（`docs/CURRENT-STATE.md` = `b7b2d513cfdab2eb`）／`HO`（`handoff.md` = `e4dc264200b421d0`）／`AB`（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **`38e67e834430d75c`** = `#51` **冻结值**）⇒ **本件没动冻结基线一字节**。

## §7 ⑥ 推送（第八笔）：head ＋ `BYTECHECK`

```
推前 head  = 084afe0319623d54a6b20131b94e59b944e43d1d   （== origin/feat-Linux，开工现场核过）
拷贝       = 3 件从 $R 拷进 fork 克隆，逐件 cmp ⇒ 3/3 OK（零复制偏差；sha16 见 §0 表）
fetch      : git fetch origin feat-Linux:refs/remotes/origin/feat-Linux   （refspec 陷阱已避）
staged     : git status --porcelain ⇒ **只有 3 行**（M 三件），**无夹带**、**逐径 git add**、未用 -A／--force
commit     = c4f142c98a183604470e030661faa5d7c8fa6e0d   （3 件：KNOWN-DEFECTS.md／ROUTES.md／defect-registry-declared.tsv）
push       : 084afe0..c4f142c  feat-Linux -> feat-Linux   （rc=0）
核对（**push 之后重新 fetch** ＋ `ls-remote` 交叉核）:
  HEAD(local)     = c4f142c98a183604470e030661faa5d7c8fa6e0d
  remote-tracking = c4f142c98a183604470e030661faa5d7c8fa6e0d
  ls-remote HEAD  = c4f142c98a183604470e030661faa5d7c8fa6e0d   ⇒ **三者一致 ✔**（避开 W107A 的假 MISMATCH）
  ls-remote --symref origin HEAD ⇒ `ref: refs/heads/feat-Linux` ✔
BYTECHECK（rev = c4f142c… 逐件 git cat-file blob | cmp - 磁盘）:
  ok  KNOWN-DEFECTS.md cf710ed6ff09a6e2 ｜ ok  docs/ROUTES.md 13aa13eab158ba49 ｜ ok  declared.tsv da59e40a44233e22
  ok  W105A-report.md cd906e8135f2406b ｜ ok  W110A-report.md d0fd37b8f74ac684 ｜ ok  W109A-report.md b255a78e98d789a7
  ok  W106A-report.md 23cce5799c9e688b ｜ ok  W101A-report.md bbd262c6d749fc1b
  ok  ACCEPTANCE-BASELINE.md 38e67e834430d75c（**= #51 冻结值，逐位未动**）｜ ok  docs/CURRENT-STATE.md b7b2d513cfdab2eb
  ok  build/close-wave.sh c757fd5058f1bfd4 ｜ ok  verify-all.sh 1aa2ae4e94827cf3 ｜ ok  nul-bytes-check.sh 409d83d945f7d563
BYTECHECK ok=13 mismatch=0 nobody=0
```

- ⚠️ **本报告本体不在第八笔里**：它作为**第九笔**（本文件单独一笔）推送 —— 因为报告里要写第八笔的 head／`BYTECHECK`（**报告写不出自己所在 commit 的哈希**，写了就永远滞后一笔，与 `#50`"冻后刻九位不可能落在冻结块内"同一条道理）。**第九笔的最终 head 记在 `~/w111a/STATUS.md` 与回件消息里**，本文件内不写。
- 已推件**复核**：`W105A-report.md`／`W110A-report.md`（任务书点名"若尚未推"）**开工现场核 = 都在 `HEAD` 且与磁盘逐字节相同** ⇒ 本笔**无需补推**（`W101A`／`W106A`／`W109A` 同）。

## §8 ⑦ `fp_inputs` 影响（**机械证**，应为零）

```
# 真调用（把 close-wave.sh 的 fp_inputs() 原样抽出后执行，**不跑 close-wave.sh 本体**）
$ sed -n '70,230p' build/close-wave.sh > ~/w111a/fp_inputs_extract.sh; echo fp_inputs >> …
开工：58a6c0945b7d535830ce3e3e4f25752b68f3714d3f35f540253eca6e69b3dd36   （== 任务书给的 58a6c0945b7d5358…）
收工：58a6c0945b7d535830ce3e3e4f25752b68f3714d3f35f540253eca6e69b3dd36   ⇒ **逐位相同**
# 覆盖面成员清单（把同一函数的哈希尾巴换成 | LC_ALL=C sort）⇒ **149 件**
$ for p in samples/WpfFeatureProbe/KNOWN-DEFECTS.md docs/ROUTES.md \
           build/MilBridge/tools/defect-registry-declared.tsv build/MilBridge/W111A-report.md; do
      grep -c -x -F -e "$p" ~/w111a/fp_members.txt; done
0
0
0
0                      ← 本件 4 件**命中全 0**（子串泛匹配 KNOWN-DEFECTS|ROUTES|declared.tsv 也 = 0）
# 那 6 件"不推件"同样逐件 = 0（且 6 件在覆盖面里一次都不出现）
```

⇒ **`fp_inputs` 零影响、`inputs_fp` 开工 = 收工 = `58a6c0945b7d5358…`**；`DEFREG_DECLDRIFT` 由 3 → 0 是**诊断行**（不进指纹，`defect-registry-check.sh` 在覆盖面里、`declared.tsv` 不在）。

## §9 ⑧ `NOINFO`／未做（**既不算绿也不算红**）

1. **`D-G98` 最内层真因**（"WM 为什么没执行退出最大化的几何还原"）：**未归因** —— 没抓到 frame/client 时序分离、没量 WM 内部状态（本件是**登记波**，不跑应用）⇒ 该格 `NOINFO`，落地 = `TASK-0110`。
2. **两臂速率差是否显著**（`3/36 vs 2/36`）：**判不出**（`p = 1.000`；要 ≤5% 置信区间需**每臂数百趟**）⇒ `NOINFO`；本件**也没有**声称"发生率相等"。
3. **`D-G99` 的射程**："全仓还有几处预登记模板用了同款单腿推理"**未逐处枚举**（只核了 W105A 自立的 `F1`）⇒ `NOINFO`，落地 = `TASK-0705`。
4. **`TASK-0705` 的权威模板是哪一份**：本件**未核**（只立号）⇒ `NOINFO`。
5. **未做**：跑任何构建／门禁／`verify-all`／应用（**纪律禁止**，本件按"纯文本 ＋ 一次推送"交件）；`TASK-0110` 的探针**未建**；`~/w105a/**` 等三处装置**只读**、未改。
6. ⚠️ **一处如实记**：任务书写的"7 件不推"里第 7 件事实不符（见 §5）—— 本件**按现场事实写**、未照抄，也**未**改 W110A 报告一字。

## §10 ⑨ 大白话小结（≤6 行）

1. 波 `#51` 已冻结推送（`38e67e834430d75c`／冻后 27/27 ×2／head `084afe0…`），我这一笔只做**登记 ＋ 地图 ＋ 推文档**，没跑任何构建、没占重活槽。
2. 新登记**两条**：`D-G98`（退出最大化后"状态回了、几何没回"，26 腿红 3 条、旧件也红 1 条 ⇒ **不是本波引入**）、`D-G99`（"一条腿一个样本就判回归"这条规则对间歇现象**不成立**，会把随机看成回归）。
3. 新立**两条任务**：`TASK-0110`（去查 WM 为什么不收几何，判据要能抓 frame/client 时序）、`TASK-0705`（把"回归判定"四要件写进预登记模板，缺一即 `NOINFO`）。
4. 声明表重生成后 `DEFREG=PASS declared=135`／`DECLDRIFT 3→0`／`rc=0`；**不重生成就当场红**（假绿探测成对成立）。
5. 推送 `084afe0..c4f142c`，三者一致、`BYTECHECK ok=13 mismatch=0 nobody=0`；`fp_inputs` 开工 = 收工，零影响。
6. 一件更正：所谓"7 件不推"其实只有 **6 件**真未推，第 7 件（`README-合并写.txt`）**早就在册且与磁盘逐字节相同**。

## §11 复现（命令级）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; C=~/netTest/GitProj/WPFOnLinux
# 判据（先写）                 cat ~/w111a/criteria.md          # sha16 6711a4ee0860a7e0
# 开工基线                     cat ~/w111a/baseline.txt
# 末号现场核                   grep -oE 'D-G[0-9]+' $R/build/MilBridge/tools/defect-registry-declared.tsv | sort -u | tail -1
# 假绿探测                     bash $R/build/MilBridge/tools/defect-registry-check.sh            # FAIL rc=1 点名两条
# 重生成 ＋ 两遍                bash $R/build/MilBridge/tools/defect-registry-check.sh --emit > $R/build/MilBridge/tools/defect-registry-declared.tsv
#                              bash $R/build/MilBridge/tools/defect-registry-check.sh            # PASS rc=0（跑两遍，diff 空）
# 地图改动复核                 wc -l $R/docs/ROUTES.md $R/samples/WpfFeatureProbe/KNOWN-DEFECTS.md
#                              diff ~/w111a/ROUTES.before.md $R/docs/ROUTES.md | grep -c '^<'   # 0
# 指纹（真调用）               bash -c 'cd '"$R"'; source ~/w111a/fp_inputs_extract.sh; fp_inputs'
# 覆盖面成员                   bash -c 'cd '"$R"'; source ~/w111a/fp_members.sh; fp_inputs | LC_ALL=C sort' > ~/w111a/fp_members.txt
# 推送                         cd $C && git fetch origin feat-Linux:refs/remotes/origin/feat-Linux \
#                              && git add <逐径 3 件> && git commit -m '…' && git push origin feat-Linux \
#                              && git fetch origin feat-Linux:refs/remotes/origin/feat-Linux \
#                              && git rev-parse HEAD && git ls-remote origin HEAD
```

**本报告 sha16（提交版口径 = `head -n -2 本文件 | sha256sum | cut -c1-16`）与第九笔 head：见 `~/w111a/STATUS.md` 与回件消息（本文件内不写自身所在 commit 的哈希，避免自指）。**
