# 波 `#58` 预登记（`WAVE58-PREREGISTRATION`）—— **仪器波**：回归判定四要件整包落地

> 车道 **W150A**（落地 ＋ 收尾链）。判据先行件 = `~/w150a/criteria.md`（`a65401c07aacb61c`）｜链报告 = `~/w150a/report.md`。
> 模板 = `docs/PREREG-TEMPLATE.md`（**本波**落 `17927a59d050fc83`；六处插入 D1–D6）。

---

## §1 本波要做什么（**零产品改动**）

三件，全在**仪器／判据面**：

| # | 件 | 动作 | 预期 |
|---|---|---|---|
| **A** | `docs/PREREG-TEMPLATE.md` | 六处**行锚定插入**（**已在稿原文一字未动**，全部追加） | `75dfc5f3fbc9df40 → 17927a59d050fc83`（`171 → 212` 行、`+41`/`−0`） |
| **B** | `build/MilBridge/tools/prereg-four-requirements-check.sh` | **新建**（扫预登记文档：四要件缺一 ⇒ `FAIL`） | `57de293df5be263d`／272 行；`--selftest` **10/10**；**不接线** |
| **C** | `build/MilBridge/tools/regression-decision.py` | 修三处缺陷（`F-A`／`F-B`／`F-C`） | `1eda9e3575960cba → 71734fce77842478`；`--selftest` `22/22 → 26/26`；台账 `7/7` **逐字节不变** |

**为什么是仪器波**：三件都不是产品件（`src/**`／`build/shims/**`／native 源**一字节未动**）⇒ **九位预期零产品位移**（`pf` 是环成员 `D-G92`，整波重建必变、**同尺寸 6,123,520 B**，**不许当漂移/回归判据**）。

---

## §2 判据节（**四要件逐字，照 `docs/PREREG-TEMPLATE.md` §1 抄**）

<!-- PREREG-REGRESSION-FOUR: same-time=yes paired=yes reproducibility=yes fisher-two-tailed=yes tool=build/MilBridge/tools/regression-decision.py -->
**机器声明**：本波凡称"做过回归判定"处，`PREREG-REGRESSION-FOUR` **四键全 `yes`**（`same-time`／`paired`／`reproducibility`／`fisher-two-tailed`），**判据件** = `build/MilBridge/tools/regression-decision.py`（本波落 `71734fce77842478`；**这颗牙的判据节本体就是下面四条**）。

本波凡声称"做过回归判定"处，**四件必须同时在位**，**缺一件 ⇒ `NOINFO`**（**既不算绿也不算红**）：

1. **两臂同刻**：同一装置／同一会话／只换一个文件；两臂**交替**取读数；**禁止跨时刻拼接**。工具侧 = `--same-time` ＋ `--old-sha16`／`--new-sha16` 两条前置断言。
2. **成对归因臂**：`--pairs N`（同腿旧/新交替）；可选 `--pair-both`／`--pair-old-only`／`--pair-new-only` 做**一致性核对**（**它们不参与 `p` 的计算** —— `p` 来自 2×2 **非配对**表，**不许读成 McNemar**）。
3. **复现性**：`--old-repro yes|no` **必须与旧臂红数自洽** —— `yes ⇒ 旧臂红数 > 0`、`no ⇒ 旧臂红数 == 0`；**违反 ⇒ `rc=2` ＋ `REGDEC_REFUSE=repro-inconsistent`（拒绝）**。
4. **统计口径**：Fisher **双尾** ＋ 分母**只算真尝试过的趟**（`D-G94`；不合规 ⇒ `rc=2` 拒绝）＋ **先写趟数与功效**（`--planned-legs` 必须等于现场 `--pairs`、`--planned-power ≥ ` 目标；缺 ⇒ `plan-absent`）。
   判 `p ≤ alpha` **一律用机器行原值**，**三位小数只作显示**（`F-C`：`0/25 vs 5/25 ⇒ p=0.050152` ⇒ `NOINFO`；三位 `0.050` ⇒ **人读会翻成回归**）。

**三态**：`REGRESSION`（回归）｜`NOINFO`（**既不算绿也不算红**）｜`OK`（判得出"不是回归"）。**`rc`**：`0`／**`3`**（证据不足）／**`2`**（分母不合规、或 ③ 与计数矛盾 ⇒ **拒绝**）。

---

## §3 两极化（**先写、后跑**；逐条见 `~/w150a/criteria.md` §1）

| 缺口 | 正极性（**必须拦**） | 反极性（**不许修过头**） |
|---|---|---|
| **`F-A`**（假绿） | `--old-repro yes` ＋ `--planned-legs 99`（现场 `pairs=16`）⇒ **`NOINFO/rc=3/plan-mismatch`** | 合法计划（`legs=16,power=0.80`）⇒ **仍** `REGRESSION/rate-aggravated/rc=0`；`D-G98`（`2/36 vs 3/36`）⇒ **仍** `OK`；"缺 `pairs` ∧ 缺计划" ⇒ **仍** `missing-paired-arm` |
| **`F-B`**（假陈述／假分类） | `repro=yes` ＋ 旧臂 `0/5`／`repro=no` ＋ 旧臂 `3/16` ⇒ **`NOINFO/rc=2/REGDEC_REFUSE=repro-inconsistent`** | 自洽的两支**必须仍走原路径**；**`DG94` 台账行仍打分母理由**（`denominator-unreconciled`）⇒ **覆盖不丢** |
| **`F-C`**（显示位数翻转） | `0/25 vs 5/25` ⇒ `NOINFO` ∧ 新行 `p_display_only=0.050` 与 `p_raw=0.050152` **并排** | `0/22 vs 5/22 ⇒ p=0.048497` ⇒ **仍** `REGRESSION`（原值比较） |

**验收合格线**：`--selftest` `fail=0` ∧ `total ≥ 22`（实测 **26/26**）｜台账 `rows=7 pass=7 fail=0` 且**整份输出逐字节不变**｜20 夹具逐例比**修前/修后整份输出** ⇒ `changed` **恰好 = 3 个新夹具**（16 例既有逐字节不变）｜本车道 `verify-fix.sh` 18 条两极性：修后 `PASS total=18`，**同一脚本对修前件 `pass=10 fail=8`**（8 条红恰好是缺陷条）。

---

## §4 样本量（**现算，不许抄**）

本波**不引用**任何回归判定读数（**仪器波**）⇒ 无需趟数/功效设计。**若**下一步要用该牙判回归，按模板 `§4` 现算：现场历史口径 `16 腿 / 6%` ⇒ `NOINFO` 且**所需 126 趟/臂**（备择 `6% vs 0%` ⇒ **131 趟/臂**）；`16 腿` 的 MDE = **38.5%**、`0/16` 的 95% 上界 = **17.07%**。

---

## §5 边界与 `NOINFO`（**照实写，不许缩小**）

- **`F-A`／`F-B` 的射程未枚举**：全仓还有几处判词"被支路绕过／假陈述"**未逐处枚举** ⇒ `NOINFO`。
- **`run_cases` 只比 `state`＋`rc`、不比 `reason`**（源码逐字 `ok = (got_state == want_state and got_rc == want_rc)`）⇒ **未修**；`F-B` 的覆盖因此**不靠台账**，靠**位置约束（放分母守门之后）＋ 逐字人核**承担。
- **新牙 `prereg-four-requirements-check.sh` 的射程**：它只证明"**文档里四要件缺件必红／齐全必绿**"，**不证明**任何具体预登记件的四要件**内容为真**（后者仍靠命令行断言 ＋ 人核）。
- **`F-C` 的人读纪律机器强制不了**：只做到"两种读法并排印出、逐字标注"。
- **`inputs_fp` 只在树静止时有意义**；本波位移 `abd349fd… → 4c4d99f5…`，**100% 归因**于覆盖面 155 件里的 1 件（`regression-decision.py`；机械反证：换回修前件 ⇒ 指纹**逐位回到** `abd349fd…`）。模板件与新牙**都不在覆盖面**（现场 `grep` 命中 0）。
