# 车道 `W117A` 报告 —— `TASK-0705`：把"回归判定四要件"落成**可复算的判据**

> lane=W117A｜2026-09-22 23:33:26 → 23:59 +0800｜kernel 6.8.0-138-generic｜`nproc=3`｜MemAvailable 2,706,144 kB｜loadavg 2.91/2.45/1.66
> 冻结基线 = **`#51` `38e67e834430d75c`**｜`DEFREG=PASS declared=136`
> **零 `dotnet`**｜**零构建**｜**零应用**｜**没跑** `verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／任何门禁／任何牙的实跑（本件只跑**自己新建的**工具）
> 交付：① 判据 `~/w117a/criteria.md`（`47544e5343b66257`）② 牙 `build/MilBridge/tools/regression-decision.py`（`1eda9e3575960cba`）
> ③ 权威模板 `docs/PREREG-TEMPLATE.md`（`75dfc5f3fbc9df40`）④ `docs/ROUTES.md` 的 `TASK-0705` 行下追加（`9fd75833eeb33224 → f9f3c68d23377f18`）⑤ 本报告
> **不接线**（接线 = 加步 = 打破刚冻结的 `27 gen=#51` 声明）⇒ §5 只给**逐字草案**。

---

## §0 一句话结论

**四要件已成"可复算的判据"**：文本落在**新建的权威模板** `docs/PREREG-TEMPLATE.md`（原来**确实没有**权威模板，判定依据见 §4），
判断落在**新牙** `build/MilBridge/tools/regression-decision.py`（三态 `REGRESSION|NOINFO|OK`，`--selftest` **22/22 PASS**，零 `dotnet`、**0.5 s**）；
拿**仓内四条历史读数**（`p = 1.000`／`0.078`／`0.030`／`0.067`）把 Fisher 实现**钉死**，并用 `D-G98` 的 `3/36 vs 2/36` 做**历史重放**（⇒ `OK`，**不许判回归**）。
**现场那一格（`16` 腿、`6%`）本件给出了具体数字**：要分辨 `6%` 与 `0%` 需 **131 趟/臂**；而 `16` 腿、旧臂 `0/16` 时**最小可检出效应 = 38.5%**
⇒ 观测到的 `1/16 = 6.25%` **只能记 `NOINFO`**。**接线草案**已逐字给全（四处 ＋ 一件台账 ＋ 一处隐含的第五处）。

---

## §1 判据（**先写**；写成本刻早于任何落地动作）

判据文件 = `~/w117a/criteria.md`（**67 行**，sha16 **`47544e5343b66257`**，现场 `sha256sum`）。
写成本刻 = `~/w117a/STATUS.md` 第 2 行 `2026-09-22 23:33:26 +0800`（**早于**本车道**任何**仓内写动作；三件落地的 mtime 全部晚于它）。
判据的七条：`C1a/C1b/C1c`（权威模板判定）｜`C2a`–`C2e`（工具：三态 ＋ 四条历史读数吻合 ＋ `D-G94` 拒绝 ＋ 两极化 `--selftest` ＋ 汇总形态）｜
`C3a`–`C3c`（文档：四要件逐字 ＋ **只加不删** ＋ 三态写死）｜`C4`（接线草案 ＋ `fp_inputs` 机械核）｜`D`（零污染）｜`E`（可复算的"完成"定义）。
**每一格在下面的 §3–§6 里都有现场读数**（`E4`）。

---

## §2 四要件（**逐字文本**，已落进 `docs/PREREG-TEMPLATE.md` §1；可直接抄进任何预登记）

**① 两臂同刻**

    ① **两臂同刻**：同一装置、同一会话、**只换一个件**；两臂**交替**跑，且两个件都在**跑之前**带
       `sha256sum` 前置断言（`sha16` 写进判据，事后补的不算）。**不许跨时刻比**（"昨天新件红、今天旧件绿"
       这种跨会话拼接**不是**两臂读数）。

**② 成对归因臂**

    ② **成对归因臂**：同一条腿在旧件/新件上**各跑一遍**成对，对与对之间**交替先后**（不是"先把旧件跑完
       再跑新件"），**每趟全新进程树**（不许复用常驻进程/缓存）。对数 `N` **先写死**，跑完不许改。

**③ 复现性**

    ③ **复现性**：该红必须**可复现**（确定性判据逐位可分，或在新件上重复出现）。
       ⚠️ **若该红在旧件上也能复现同一形态 ⇒ 不得称"本波引入"** —— 那只能记"**既有现象的复现**"；
       两臂速率**都判不出差别**时，判词就是 **`OK`（不是回归）**（这就是 `D-G99` 的**假红**方向，必须拦住）。

**④ 统计口径**

    ④ **统计口径**：**Fisher 精确检验 · 双尾**（2×2 表、固定边缘、超几何零分布；**双尾 = 所有"概率 ≤ 观测表概率"
       的表的概率之和**，不是 `2×单侧`）。**分母只算"真尝试过的趟"**（`D-G94`：`SKIP dead`／"没点"的趟
       **不许进分母**，进了就是**读数不可归因**）。**趟数与功效必须先写**（`D-G99`）：先写死每臂报多少趟、
       目标功效多少，再报读数；**p > α 且旧件 0 红 ⇒ 分不开"随机"与"件相关" ⇒ `NOINFO`**，**不许**判回归。
       **缺任何一件 ⇒ `NOINFO`**。

**判词口径（三态）**

    **判词三态**：`REGRESSION`（回归）｜`NOINFO`（要件缺一／样本不足／功效不足 ⇒ **既不算绿也不算红**）｜
       `OK`（判得出"不是回归"）。**判据件** = `build/MilBridge/tools/regression-decision.py`
       （`--selftest` 自带两极化；机读行 `REGRESSION_DECISION=` ＋ `rc`）。

### §2.1 ⚠️ 一处**如实登记的口径张力**（要件 ③ 的字面 vs 操作）

`docs/ROUTES.md:431` 与 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2651` 里 **③ 的原话**是
「**在旧件上也要能复现该红** —— 只有新件上红 ⇒ **不足以**判回归」。**按字面**读，这句话禁止"只在新件上红"时判回归；
而 `TASK-0705` 的反极性要求里同时写着「用那类**确定性**差异做"**必须判回归**"的**正例**」（派单书 §2 的 `--selftest` ② 也是"只在原件红、旧件 `0/N` 且 `N` 足够 ⇒ 判 `REGRESSION``）。
⇒ **两句按字面互相排斥**。本车道的处置（**不悄悄选一边**）：

- **判据文本在模板里逐字保留 `ROUTES` 的原话**（`§1` ③），**不改一个字**；
- **工具按操作读法实现**，并把读法**写在工具头注释与 `REGDEC_REASON` 里**：
  ③ = "**该红必须可复现**（确定性逐位可分，或在新件上重复出现）；**若旧件也复现同一形态** ⇒ 判词**只能是 `OK`（既有现象）或 `REGRESSION(rate-aggravated)`（速率被显著加重），**不许**记成"本波引入"」；
- 这条张力**登记在此、待主控裁定**（改哪一边都要动 `ROUTES`/`KNOWN-DEFECTS.md` 的**已立判词**，**不在本车道写域**）。
  **`NOINFO` 一格**：`ROUTES.md:431` 那句到底要"字面执行"还是"操作读法"，本件**未裁定**。

---

## §3 牙：`build/MilBridge/tools/regression-decision.py`

**件**：`build/MilBridge/tools/regression-decision.py`｜**943 行**／51,886 B｜sha16 **`1eda9e3575960cba`**｜零第三方依赖（只用标准库）｜零 `dotnet`｜单趟 **0.5 s**。

### 3.1 三态与退出码（`C2a`）

| 机读行 | `rc` | 含义 |
|---|---|---|
| `REGRESSION_DECISION=REGRESSION` | **0** | 四要件齐备 ∧ Fisher 双尾 `p ≤ α` ∧ 计划在位且与现场一致 |
| `REGRESSION_DECISION=OK` | **0** | **判得出"不是回归"**（两臂皆 0 红／旧件也复现同一形态而速率判不出差别／新件那点红不显著） |
| `REGRESSION_DECISION=NOINFO` | **3** | 要件缺输入／样本不足（`p>α` 且旧件 0 红）／计划缺位 ⇒ **不许当绿** |
| `REGRESSION_DECISION=NOINFO` | **2** | **分母口径不合规**（`D-G94`）⇒ **拒绝** ＋ `REGDEC_REFUSE=<点名>` ⇒ **读数不可归因** |

⚠️ **`rc=2` 与 `rc=3` 印的是同一个词 `NOINFO`，区别只在原因码** —— 这是**故意**的：**不许造第四态**，
但"连分母都不可信"与"分母可信而证据不足"必须分得开（前者**拒绝**、后者**可判**）。

### 3.2 Fisher 双尾实现被**仓内四条历史读数**钉死（`C2b`）

口径 = 2×2 表、固定边缘、超几何零分布，**双尾 = 所有"概率 ≤ 观测表概率"的表的概率之和**（**不是** `2×单侧`）。
**两条独立数值路径**（A = `math.lgamma` 对数域求和；B = `math.comb` 精确整数比）在**每一例**上必须一致，
再与**仓内四条已发表的读数**逐字对照（容差 = 三位小数）：

| 现场读数（出处） | 表 | 本件 A | 本件 B | 报告里写的 | 判 |
|---|---|---|---|---|---|
| `D-G98`（`KNOWN-DEFECTS.md:2650`） | `3/36 vs 2/36` | `1.000000` | `1.000000` | **`1.000`** | ✅ |
| `W112A` §1.5/§5.3 | `0/40 vs 2/16` | `0.077922` | `0.077922` | **`0.078`** | ✅ |
| `W112A` §1.5 | `0/40 vs 4/30` | `0.029889` | `0.029889` | **`0.030`** | ✅ |
| `W112A` §5.4 | `1/1 vs 0/14` | `0.066667` | `0.066667` | **`0.067`** | ✅ |

> ⇒ 这不是"我选的公式自洽"，而是**四条**别人算过的数**逐个重合** —— 换一种双尾定义（例如 `2×单侧`）会立刻在 `D-G98` 那格给出 `0.64` 而不是 `1.000`。

### 3.3 `--selftest` 逐例读数（`C2d`／`C2e`；**22 例 · pass=22 · fail=0**）

`python3 build/MilBridge/tools/regression-decision.py --selftest` ⇒ 汇总行
**`REGDEC_SELFTEST=PASS total=22 pass=22 fail=0`**，`rc=0`（原文另存 `~/w117a/selftest-run1.txt`；**两趟逐字相同**）。

**A. 判词例 16 条**（每条**同时**断言"三态词"与"`rc`"）：

| 例 | fixture | 判词 | `rc` |
|---|---|---|---|
| `repro-on-old-OK` | `3/16 vs 4/16`，成对臂 `both=3 new_only=1` | **`OK`** | 0 |
| `deterministic-new-only-REGRESSION` | `0/5 vs 5/5`（每腿都红） | **`REGRESSION`**（`deterministic-new-only`） | 0 |
| `sixteen-legs-six-percent-NOINFO` | **`0/16 vs 1/16`** | **`NOINFO`** ＋ 印 `per_arm=126` | 3 |
| `sixteen-legs-alt-6pct-NOINFO` | 同 ＋ 备择 `6% vs 0%` | **`NOINFO`** ＋ 印 `per_arm=131` | 3 |
| `missing-paired-arm-NOINFO` | 缺 `--pairs` | `NOINFO` | 3 |
| `denominator-counts-skipped-REFUSE` | `--old-total 9 --old-skipped 2`（`D-G94` 现场形态） | `NOINFO` ＋ **`REGDEC_REFUSE=denominator-unreconciled`** | **2** |
| `denominator-total-REFUSE` | `--denominator total` | `NOINFO` ＋ **`REGDEC_REFUSE=denominator-not-tried`** | **2** |
| `historical-DG98-OK` | **`2/36 vs 3/36`**（历史重放） | **`OK`**（`p=1.000000` 逐字断言） | 0 |
| `both-green-OK` | `0/16 vs 0/16` | `OK` | 0 |
| `new-only-not-significant-NOINFO` | `0/16 vs 4/16`（`p=0.101224` 逐字断言） | `NOINFO` | 3 |
| `plan-absent-NOINFO` | 显著但没给计划 | `NOINFO`（`plan-absent`） | 3 |
| `missing-same-time-NOINFO` | 缺 `--same-time` | `NOINFO` | 3 |
| `significant-intermittent-REGRESSION` | `0/16 vs 5/16`（`p=0.043382`） | `REGRESSION`（`statistical-new-only`） | 0 |
| `planned-power-below-target-NOINFO` | 计划功效 `0.50` | `NOINFO` | 3 |
| `plan-mismatch-NOINFO` | `planned_legs=40 ≠ pairs=5` | `NOINFO` | 3 |
| `pair-inconsistent-NOINFO` | 成对数与两臂红数对不上 | `NOINFO` | 3 |

**B. `CROSSPATH` 4 例**（§3.2 的表，两路径 ＋ 历史读数三方对照）⇒ 4/4 `OK`。
**C. `POWER` 6 例**（功效算法与**独立穷举实现**给出的"所需趟数"逐个相同；第 5、6 例同参 ⇒ 是**防抖复跑**、不是两组不同的数）：

| 备择（旧→新） | 本件 | 独立实现 | 功效 |
|---|---|---|---|
| `0% → 6%` | **131** | 131 | 0.8041 |
| `0% → 6.25%` | **126** | 126 | 0.8059 |
| `0% → 5.9%` | **133** | 133 | 0.8027 |
| `0% → 12.5%` | **62** | 62 | 0.8030 |
| `0% → 10%` | **78** | 78 | 0.8042 |

**D. `MDE` 4 例 ＋ `MDE-INVERSE` 2 例**（MDE 与"所需趟数"是**两个方向相反**的算法，必须咬合）：

| 例 | 读数 |
|---|---|
| `n=16, p0=0` | `MDE=0.3845`（独立穷举 `0.385`） |
| `n=36, p0=0` | `MDE=0.2107`（独立 `0.211`） |
| `n=36, p0=0.0556` | `MDE=0.3239`（独立 `0.324`） |
| `n=126, p0=0` | `MDE=0.0620`（独立 `0.0625`）← **正好咬回 `required_n(0, 6.25%) = 126`** |
| `MDE-INVERSE n=126` | `required_n(0, 0.0620) = 126` ✅ |
| `MDE-INVERSE n=40` | `required_n(0, 0.1905) = 40` ✅ |

**E. 台账模式 2 例**：`--cases`（5 行全对 ⇒ `REGRESSION_LEDGER=PASS rows=5`）；**反极性** = 把台账里**声明的期望**改坏一行 ⇒ **必须 `FAIL`**（否则台账模式是橡皮图章）。

**F. 自证**：`ST_ATTEST=PASS self=…/regression-decision.py sha16=1eda9e3575960cba（自测期间本件未变 ⇒ 上面读数可归因）`。

### 3.4 ★现场那一格（`16` 腿 `6%`）的**具体数字**（派单书点名要的数）

```
$ python3 build/MilBridge/tools/regression-decision.py --old 0/16 --new 1/16 --pairs 16 \
    --same-time --old-sha16 aaaa --new-sha16 bbbb --old-repro no --planned-legs 16 --planned-power 0.80
REGRESSION_DECISION=NOINFO
REGDEC_RC=3
REGDEC_TABLE old=0/16 new=1/16 alpha=0.05 power_target=0.80
REGDEC_FISHER p=1.000000 two_tailed=yes method=hypergeometric-le-observed
REGDEC_GATES same_time=yes sha16=yes paired=yes repro_input=no plan=yes
REGDEC_MDE n_per_arm=16 p0=0.0000 min_detectable_p1=0.385 power=0.8000（本设计**本来**能检出的最小效应；观测后功效只作诊断、不当门）
REGDEC_POWER_NOW observed=0.0023 target=0.80
REGDEC_REQUIRED_N_OBS per_arm=126 power=0.8059 observed_rates=0.0000-vs-0.0625 window=exact-window=[77,177] approx=117.7
REGDEC_CI0_OLD 0/16 的单侧95%上界=0.1707
REGDEC_REASON reason=not-significant(fisher_p=1>alpha=0.05 且旧件 0 红 ⇒ 分不开「随机」与「件相关」；见 D-G99)
```

**四个可直接引用的数**（全部现场现算，不手抄）：

1. **`16` 腿判不出** —— 该设计的最小可检出效应 **`MDE = 38.5%`**（旧臂 `0/16` 时）；观测到的是 `6.25%` ⇒ **`NOINFO`**。
   （同义的另一种说法：旧臂 `0/16` 时新臂**至少要 5 红**（`p = 0.0434`）才显著；`1` 红 ⇒ `p = 1.000`。）
2. **要判得出就得加趟数** —— 分辨 `6.25% vs 0%` 需 **126 趟/臂**；分辨 **`6% vs 0%` 需 `131` 趟/臂**（派单书点名的那个例子）。
3. **`0/16` 的 95% 单侧上界 = `17.07%`** —— 即"旧件真是 0 红时它的速率最多能有多高"。
4. **两个口径都要报**：仓内此前那句「**≥40 腿/臂**」走的是**区间口径**（`0/40 ⇒ 7.2%`、`0/49 ⇒ 5.9%`），
   **不是**功效口径的 `131` —— **它们回答不同问题**（"旧件速率上界压到多低" vs "两个速率要分辨得开"）⇒ 模板 §4 把**两个数并列写死**，不许互相替代。

### 3.5 ⚠️ 一处**自我更正**（如实留痕）

第一版把「**观测后功效**」（`power_at(p0_obs, p1_obs, n0, n1)`）当成了 `REGRESSION` 的**门**：于是 `0/16 vs 5/16`
（`p = 0.0434`，**已经显著**）被判 `NOINFO(underpowered)`。**这是错的**：**观测后功效是 `p` 值的单调函数**，
拿它当门 = **偷偷把 `alpha` 改小**（统计学上的常识性错误，与本仓"不许悄悄改判据"直接冲突）。
⇒ 改法：**门**改成"**先写的计划**"（`--planned-legs` 必须等于现场成对臂对数、`--planned-power ≥ 目标`），
`REGDEC_POWER_NOW` **降级为诊断**（照印），另加与之**互补**的 `REGDEC_MDE`（"这个设计**本来**能检出多大效应"）。
⇒ 改后 `0/16 vs 5/16` 判 **`REGRESSION(statistical-new-only)`**（第 15 例），而 `16 腿 6%` **仍然** `NOINFO`（第 3 例）。
**两个自测例都在**（改前那版正是被自测当场照出来的）。

### 3.6 台账模式 `--cases`（接线时让牙**真咬当波读数**）

```
$ python3 build/MilBridge/tools/regression-decision.py --cases build/MilBridge/tools/regression-decision-cases.tsv
LEDGER ROW DG98-historical-replay         = PASS old=2/36 new=3/36 state=OK want=OK rc=0 want_rc=0
LEDGER ROW W112A-old-clean-not-significant = PASS old=0/40 new=2/16 state=NOINFO want=NOINFO rc=3 want_rc=3
LEDGER ROW W114A-sixteen-legs-6pct        = PASS old=0/16 new=1/16 state=NOINFO want=NOINFO rc=3 want_rc=3
LEDGER ROW deterministic-new-only-5-of-5  = PASS old=0/5 new=5/5 state=REGRESSION want=REGRESSION rc=0 want_rc=0
LEDGER ROW significant-intermittent-5-of-16 = PASS old=0/16 new=5/16 state=REGRESSION want=REGRESSION rc=0 want_rc=0
LEDGER ROW DG94-denominator-counts-skipped = PASS old=7/9 new=4/9 state=NOINFO want=NOINFO rc=2 want_rc=2
LEDGER ROW both-arms-green                = PASS old=0/16 new=0/16 state=OK want=OK rc=0 want_rc=0
REGRESSION_LEDGER=PASS rows=7 pass=7 fail=0    （rc=0）
```

台账草案（**7 行**，本车道**只在 `~/w117a/` 起草**、**未落仓** —— 仓内路径按写域不归本车道）：
`~/w117a/regression-decision-cases.tsv`（sha16 `5d3c26a1c8d83688`，逐字内容见 §5.2）。
**台账的语义**：它是"**我声明的期望**"，牙判的是"**工具给的判词 == 声明的期望**" ⇒ **换个人跑、换一代跑，判词不许变**。

---

## §4 `C1`：**权威模板是哪一份**（判定依据 · 文件:行）

**结论：原先**确实没有**权威模板 ⇒ 本件**新建** `docs/PREREG-TEMPLATE.md`（`TASK-0705` 允许的那条分支）。

| 判据 | 现场命令 | 读数 | 结论 |
|---|---|---|---|
| `C1a` 有件**被指名**为模板？ | `grep -rn --include='*.md' -e '权威模板' -e '预登记模板' -e 'PREREG-TEMPLATE' .` | 判定时刻命中 **12 行**：`docs/ROUTES.md:429/430/510/512`、`build/MilBridge/W111A-report.md:10/65/70/191/192/200`、`build/MilBridge/W112A-report.md:240`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2653` —— **全是任务叙述**（"要写进预登记模板"），**没有一行指名任何一个路径**；`W111A-report.md:192` 自己写着「**`TASK-0705` 的权威模板是哪一份**：本件**未核**（只立号）⇒ `NOINFO`」 | **否** |
| `C1b` 33 件预登记有**同一套骨架**？ | 逐件抽 `^## ` | `## §N` 风格 **21** 件／`## N.` 风格 **12** 件；节数 **min 5 / max 37 / 中位 9**（`n=33`） | **否** |
| `C1c` 判据正文有**仓内唯一真源**？ | `grep -l 'criteria\.md' docs/WAVE*-PREREGISTRATION.md` | 只有 **3** 件（`W49`/`W51`/`W52`）把**逐格判据全文**指向**仓外** `$HOME/w<车道>/criteria.md`；其余各波把判据**内联在自己那一节** | **否** |

⚠️ **`C1a` 那一格不可复跑**（如实记）：判定之后，**本件自己新建的两件**（`W117A-report.md` 11 行、`PREREG-TEMPLATE.md` 5 行）＋ **并发车道**的 `build/MilBridge/W115A-report.md:195` 也含这几个词
⇒ 现在重跑同一条 `grep` 得 **31 行**（而不是判定时刻的 12 行）。**"写入者把自己也算进读数"**是本仓反复登记的形态 ⇒ 这一格的读数必须**带时刻**看。

**为什么不是别的件**（逐条，防"只改一份副本就宣称模板已改"）：

1. `docs/INDEX.md:33` 只把 `docs/WAVE<NN>-PREREGISTRATION.md` 描述成**一类**件（"判据先写死"的预登记），**没有**指名任何一份是模板；
2. `docs/PORT-SPEC.md:19`（"判据先写死，再取读数……必须在动手前把判据 + 反极性写进 `docs/WAVE*-PREREGISTRATION.md`（或本轮的预登记节）"）与 `:66`（"① 预登记 `docs/WAVE<NN>-PREREGISTRATION.md`（判据先写死、§4 预期位移先写死）"）是**规范本身**、**没有给判据节的骨架/清单**；
3. 33 件预登记**都是冻结证据、彼此不继承**（`docs/INDEX.md:34` 明说报告们是"**冻结记录的证据日志**"、**不要移动/删除**；`:41` 说历史件"**留在原位**"）⇒ 只改其中一份 = `ROUTES.md:430` 点名禁止的形态；
4. 已冻结件**只加不改**（`ROUTES.md:433`）= 本件**一个字都没动它们**（§7 的零污染证明里含 `docs/WAVE*-PREREGISTRATION.md` 未改）。

**加在哪**：
- **新建** `docs/PREREG-TEMPLATE.md`（**171 行**／12,348 B／sha16 **`75dfc5f3fbc9df40`**）：`§0` 判定依据（上表 ＋ 为什么不是别的件）｜`§1` **四要件逐字** ＋ 判词三态｜`§2` 为什么现行写法不够（三条现场读数：`W105A` 的 `F1` 单腿推理／`W98A` 把唯一一次真命中从分母剔掉／三条实际红率 `4/30`、`2/16`、`1/17→1/16`）｜`§3` **可抄的判据节骨架**｜`§4` 现算的样本量参考（两个口径并列）｜`§5` 怎么用那把牙（含"观测后功效不当门"的理由）｜`§6` 边界与 `NOINFO`。
- **追加** `docs/ROUTES.md` 的 `TASK-0705` 行下（`:435-440`，**只加不删**）：把"权威模板 = `docs/PREREG-TEMPLATE.md`"＋判定依据＋牙＋现场数字＋未接线与 `fp_inputs` 结论逐条写进去。
  **机器证**（`C3b`）：改前副本取自 fork 克隆 `HEAD:docs/ROUTES.md`（**独立来源**，sha16 **`9fd75833eeb33224`** ＝ 本车道开工时现场算的值，逐位相同）⇒
  `comm -23`（`LC_ALL=C`）**改前独有行 = 0**；`diff` = **删除 0 行／新增 6 行**；`533 → 539` 行。

---

## §5 接线草案（**逐字，不落地**）

### 5.0 本波为什么不接

`verify-all.sh` 现在 `# VERIFYALL-STEPS-DECL: 27 gen=#51`（现场 `sha256sum` = **`1aa2ae4e94827cf3`**，`grep -c '^run_step "'` = **27**）。
接进去 = **加一步** ⇒ 四处声明全部当场过期，而 `#51` 的冻结语义要求"**声明与本体同趟一致**"；
`docs/CURRENT-STATE.md:9` 的机器行 `gen=#51` 与 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`38e67e834430d75c`）**都不归本车道** ⇒
**加步必须由"接线那一波"连同重冻一起做**。本波**只给草案**（这也是派单书的硬要求）。

### 5.1 四处必改（＋**第五处隐含的**）

**① 口径句**（头注释；`verify-all-step-check.sh:169` 用 `grep -qF "**\`$gen\` 收官起 = $n 步**"` 逐字比对 ⇒ **半句必须逐字**）。
在头注释"步数口径"段（现件 `:20-42` 那段）**追加**（`#31` 段之后、`# ── 步名/步数声明` 之前）：

    #   **`#52` 收官起 = 28 步**（`#52` 一次接一件「**牙已备、无人跑**」的判据件：第 `[28]` 步 `REGRESSION-DECISION`
    #   （`TASK-0705`：回归判定四要件 —— ① 两臂同刻 ＋ ② 成对归因臂 ＋ ③ 复现性 ＋ ④ Fisher 精确检验**双尾**
    #   ＋ 分母**只算真尝试过的趟**［`D-G94`］＋ **先写趟数与功效**［`D-G99`］，**缺一即 `NOINFO`**）。
    #   **纯读、零 `dotnet`、`≈0.5 s`、`--selftest` 22/22**；本步**不改产品件** ⇒ 九位逐位不动。
    #   ⚠️ **本步的绿**只等于「**台账里每一行的读数**都判出了**台账里声明的那个判词**」，
    #      **≠**「那些读数本身是真的」—— ①"同刻"／②"交替"／④"计划是先写的"只能靠调用方断言，本步判不了；
    #      分母口径不合规（`D-G94`）⇒ `rc=2` ＋ `REGDEC_REFUSE=` 点名（**不许当绿**）。）

**② `VERIFYALL-STEPS-DECL`**（现件 `:44` 之前**插入**一行；**旧的 `27 gen=#51` 原样留**）：

    # VERIFYALL-STEPS-DECL: 28 gen=#52   ← `#52` **加一步**（27 → 28）：第 `[28]` 步 `REGRESSION-DECISION` —— `TASK-0705` 的牙（`build/MilBridge/tools/regression-decision.py`）：判「**凡回归判定**」的**四要件**（① 两臂同刻 ② 成对归因臂 ③ 复现性 ④ Fisher 精确检验**双尾** ＋ 分母**只算真尝试过的趟**［`D-G94`］＋ **先写趟数与功效**［`D-G99`］），**缺一即 `NOINFO`**。三态机读行 `REGRESSION_DECISION=REGRESSION|NOINFO|OK`；`rc` = `0`（判词成立）／`3`（证据不足的 `NOINFO`）／`2`（**分母口径不合规 ⇒ 拒绝** ＋ `REGDEC_REFUSE=` 点名）。**纯读、零 `dotnet`、`≈0.5 s`**；本步不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：27 → 28**）

**③ `VERIFYALL-STEP-NAMES`**（现件 `:65`）：行尾**追加** ` | REGRESSION-DECISION`
（即 `… | R-GATE（连续交互） | NUL-BYTES | REGRESSION-DECISION`；⚠️ 与 `run_step "REGRESSION-DECISION"` **逐字相同**）。

**④ 步骤本体**：插在 `[27] NUL-BYTES` 之后（现件 `:891` 那一行与它的 `echo` 之后）、汇总段之前：

    echo "[28] 回归判定四要件（TASK-0705）"
    # ⚠️ 本步**不是构建者**（纯 python、≈0.5 s、零 `dotnet`）；它**不吃**本波的产品读数：
    #    真实读数进的是**报告 + 台账**（`build/MilBridge/tools/regression-decision-cases.tsv`），
    #    本步判的是"**台账里每一行的读数 == 台账里声明的判词**"∧"台账每行都显式声明了期望"。
    run_step "REGRESSION-DECISION" python3 build/MilBridge/tools/regression-decision.py --cases build/MilBridge/tools/regression-decision-cases.tsv

**⑤（隐含的第五处，**别漏**）预登记 H1**：`verify-all-step-check.sh:206-220` 会拿**新的 `gen=`** 去扫
`docs/WAVE<新代>-PREREGISTRATION.md` 的**标题行**；找不到 ⇒ `report_noinfo prereg-absent` ⇒ **`rc=2 NOINFO`**（**缺声明 ≠ 通过**）。
⇒ 接线那一代**必须先有自己的预登记件**（`#52` 现件已有：`docs/WAVE52-PREREGISTRATION.md`（`834e370053f7ef2b`）标题行含 `#52` ⇒ `prereg=PASS`）。

### 5.2 台账（接线那一波新建的文件；本车道只在 `~/w117a/` 起草）

`build/MilBridge/tools/regression-decision-cases.tsv` —— 逐字（TAB 分隔；`#` 注释；`-` = 该格不给）：

    # regression-decision-cases.tsv —— 「回归判定」的**台账**（`TASK-0705` 的牙 · **接线件**；W117A 起草、接线那一波落）
    #   ⚠️ 台账 = "**我声明的期望**"；牙判的是"工具给的判词 == 这里的期望"，两者不符 ⇒ 红。
    #   列序（TAB 分隔、`#` 注释、空行忽略；`-` = 该格不给）：
    #     name  old  new  pairs  repro  planned_legs  planned_power  alt_old  alt_new  denominator  old_total  old_skipped  want_state  want_rc
    #   `old`/`new` = **红数/真尝试过的趟数**（`D-G94`：分母只算"真尝试过的趟"）。
    #   `want_state ∈ REGRESSION|NOINFO|OK`；`want_rc ∈ 0|2|3`。
    DG98-historical-replay	2/36	3/36	36	yes	36	0.80	-	-	tried	-	-	OK	0
    W112A-old-clean-not-significant	0/40	2/16	16	no	16	0.80	-	-	tried	-	-	NOINFO	3
    W114A-sixteen-legs-6pct	0/16	1/16	16	no	16	0.80	-	-	tried	-	-	NOINFO	3
    deterministic-new-only-5-of-5	0/5	5/5	5	no	5	0.80	-	-	tried	-	-	REGRESSION	0
    significant-intermittent-5-of-16	0/16	5/16	16	no	16	0.80	-	-	tried	-	-	REGRESSION	0
    DG94-denominator-counts-skipped	7/9	4/9	9	no	9	0.80	-	-	tried	9	2	NOINFO	2
    both-arms-green	0/16	0/16	16	no	16	0.80	-	-	tried	-	-	OK	0

新波**每组回归判定**再加一行（`want_state`/`want_rc` 必须**先写**）；改一行 = 改判据的期望 ⇒ **要留痕**。
**最小的替代方案**（不建台账）：把第 ④ 步换成 `run_step "REGRESSION-DECISION" python3 build/MilBridge/tools/regression-decision.py --selftest`
—— 但它只证"牙自己两极化"，**咬不到任何当波读数**（仓内现有 27 步**没有任何一步**是按 `--selftest` 跑的，见 §5.3）⇒ **不推荐**。

### 5.3 接线前**必读**的三条现场事实

1. **仓内现有 27 步里，没有任何一步是把 `--selftest` 当步骤本体跑的**（`grep -n 'selftest' verify-all.sh` 命中的全是**注释**）⇒ 若走"最小替代方案"，本步会是**首例**，形态上要单独过主控。
2. **`python3` 调用的既有先例**：`verify-all.sh:505` `run_step "verify-cmd-layout.py" python3 tests/…/verify-cmd-layout.py` ⇒ 第 ④ 步的写法与它同形。
3. **本步不是构建者**：`0.5 s`／零 `dotnet`／纯读 ⇒ 与 `[13] HIDDEN-ONLY`（`+102 s`、`35` 次 `dotnet`/趟）**完全不同量级**，
   不触发"构建者独占"那条纪律冲突。

---

## §6 `fp_inputs` 影响（**机械核**，不吃我的判断）

**覆盖面本体**（`build/close-wave.sh:214-221` 的 `printf` 名单［21 行件］＋ 它上面四段 `find`）。现场**真调用** `fp_inputs()` 得到的现值 = **`72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015`**
（与 `docs/ROUTES.md` §15g 记的 `#51` 冻结值 `58a6c094…` **不同** —— 那属于**波内他车位移**：`src/WpfGfx.Linux.Native/**/*.c|*.h` 在覆盖面内，`W113A`/`W114A` 改过它们；**本件不改那些**）。

**① 新工具现在**不在**覆盖面里（跑真链，不是判断）**：

    $ find src/WpfGfx.Linux.Native/tools build \( -maxdepth 2 -name 'patch-*.py' -o -maxdepth 1 -name 'port-lib.py' \
        -o -maxdepth 1 -name 'integration-wave.sh' -o -maxdepth 1 -name 'close-wave.sh' \) \
        -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/.artifacts/*' | grep -c 'MilBridge/tools'
    0
    （⚠️ 链里那个 `-maxdepth 2` 是**死子句**：GNU find 的 `-maxdepth` 是**全局、最后一个胜** ⇒ 生效值 = 链尾的 `1`）

⇒ 新工具**落在 0 件那一格里**，加它**不会**自动改 `inputs_fp`。

**② 但按仓内惯例把它纳入 `printf` 名单 ⇒ `inputs_fp` **必然**移动（成对读数，`cp -p` 沙箱，仓内零写）**：

| 配置 | `inputs_fp`（现场算） |
|---|---|
| 现件（工具**不**在名单里） | `72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015` |
| 沙箱：把 `build/MilBridge/tools/regression-decision.py` **追加进 `printf` 名单** | **`e4ec6c6ebeef3cd68c3b7196b732e2b096b41dc16d4f02c625b9b1c9ab46e11d`** |

⇒ **两值不同 ⇒ 必动**。**流程约束**（与 `tline-gate.sh`/`nul-bytes-check.sh` 同一条，`close-wave.sh:123`）：
**这一改必须安排在 `IN_FP_0` 采样之前**（`IN_FP_0` 在 `close-wave.sh:202`，即 `[0/6]` 之后、`[1/6]` 之前），
否则 `close-wave.sh` 自己的 `[4/6]` 输入稳定性检查会 `IN_FP_0 != IN_FP_1` ⇒ **`exit 5`**。

⚠️ **本波没有改 `close-wave.sh`**（`c757fd5058f1bfd4`，与 fork `HEAD` 逐位相同）⇒ 现值仍是 `72c5f226…`。

---

## §7 零污染 / 未做 / `NOINFO`

### 7.1 仓内只写了 3 件（全在写域内）

| 件 | before | after | 说明 |
|---|---|---|---|
| `build/MilBridge/tools/regression-decision.py` | —（新建） | **`1eda9e3575960cba`**（943 行） | 牙 |
| `docs/PREREG-TEMPLATE.md` | —（新建） | **`75dfc5f3fbc9df40`**（171 行） | 权威模板 |
| `docs/ROUTES.md` | **`9fd75833eeb33224`**（533 行；fork `HEAD` 独立复核） | **`f9f3c68d23377f18`**（539 行） | `TASK-0705` 行下**只加 6 行** |

**写域外关键件：现件 sha16 **逐位相同于** fork 克隆 `HEAD`** ⇒ 自上次推送以来未动 ⇒ 更非本车道所改：
`verify-all.sh` `1aa2ae4e94827cf3`｜`build/close-wave.sh` `c757fd5058f1bfd4`｜`build/MilBridge/known-red.json` `089b7324ba12e022`｜
`docs/CURRENT-STATE.md` `b7b2d513cfdab2eb`｜`handoff.md` `e4dc264200b421d0`｜`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` `38e67e834430d75c`｜
`docs/PORT-SPEC.md` `7f36186d68a18332`｜`docs/INDEX.md` `c36ed5fe2a5904a7`｜`build/MilBridge/tools/defect-registry-declared.tsv` `934a29ed9ab399ab`｜
`build/integration-wave.sh` `39e52f0049373059`。**33 件 `docs/WAVE*-PREREGISTRATION.md` 一件未动**（`find -newermt <会话起点>` 里 0 命中）。

### 7.2 起点之后的**全部**新 mtime（机械清点）

    $ find build docs samples -type f -newermt '2026-09-22 23:33:26'
    build/MilBridge/tools/__pycache__/regression-decision.cpython-310.pyc   ← 我 py_compile 的副产物，**已删**
    （删掉之后重跑 = 只剩 §7.1 那三件；`find build/MilBridge/tools/__pycache__ -name 'regression*' | wc -l` = **0**）
    `find ~/w117a -type f -links +1 | wc -l` = **0**（全程 `cp -p` 真复制，零 `ln`）

### 7.3 没跑什么（**如实**）

- **没跑** `verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／任何构建／任何门禁／任何既有牙的实跑；
  只跑了**本件新建的** `regression-decision.py`（`--selftest`／`--cases`／单例判词）＋ 只读命令（`grep`/`find`/`sha256sum`/`wc`/`diff`/`comm`/`git show`）。
- **没接线**（§5 只给草案）；**没动** `docs/PORT-SPEC.md` 与 `docs/INDEX.md` 的指针行（不在写域）。

### 7.4 `NOINFO`（**既不算绿也不算红**）

1. **要件 ③ 的字面 vs 操作读法**未裁定（§2.1）—— 两句在原话里**互相排斥**，本件按操作读法实现并**逐字保留原话**，**待主控裁定**。
2. **`D-G99` 的射程未枚举**：「全仓还有几处预登记用了同款单腿推理」**未逐处枚举**（`W111A` 也记的是 `NOINFO`）⇒ 本件只把**以后新写的**判据钉住；**历史 33 件按"只加不改"处理**。
3. **`MDE`／所需趟数是近似定位 ＋ 精确窗口**：`n_approx ±(40,60)` 窗口内**逐个精确求值取最小 `N`**；窗口外**未证**（`n_approx > NMAX(400)` 时印 `CAP` ＋ 近似值，例如 `D-G98` 那对 `2/36 vs 3/36` ⇒ `CAP approx≈1311`）。**窗口选择本身是启发式**，`--selftest` 的 5 个 `POWER` 锚 ＋ 2 个 `MDE-INVERSE` 锚把它在**现实现场**上钉住了，但**不是**对任意 `(p0,p1,N)` 的证明。
4. **"计划是不是**先**写的"判不了**：工具只能要求计划**在场且与现场一致**；"先写"这件事靠 `STATUS.md`／`criteria.md` 的**时间戳**（人看）。
5. **台账只起草在 `~/w117a/`**：仓内那份 `build/MilBridge/tools/regression-decision-cases.tsv` **未建**（写域）。
6. **`docs/PORT-SPEC.md` / `docs/INDEX.md` 的指针行未加**（写域）⇒ 两处各欠**一行**。

---

## §8 大白话小结（≤6 行）

1. **"回归判定"以前只有一句口号，现在有文本、有算法、有牙**：文本在**新建的 `docs/PREREG-TEMPLATE.md`**（因为**全仓原先确实没有**权威模板，三条判据全是"否"，依据都写在 `§0`），算法在**新牙 `regression-decision.py`**（`--selftest` **22/22**、零 `dotnet`、0.5 s）。
2. **牙是被别人的数钉住的**：`D-G98` 的 `1.000` 与 `W112A` 的 `0.078`／`0.030`／`0.067` 四条**现场历史读数**逐字重合，`D-G98` 那格**重放**出来是 **`OK`（不许判回归）**，确定性的 `5/5 vs 0/5` 是 **`REGRESSION`**。
3. **本波现场那格（16 腿 6%）的答案是"判不出"**：`16` 腿只能检出 **38.5%** 量级的跳变，要分辨 `6% vs 0%` 得 **131 趟/臂**（`0/16` 的 95% 上界是 **17.07%**）⇒ 这一格**只能是 `NOINFO`**。
4. **`NOINFO` 不算绿、也不算红**：`rc=3` 是"证据不足"，`rc=2` 是"**分母不可信 ⇒ 拒绝**"（`D-G94`：把没点的趟算进分母，工具**当场点名拒绝**）。
5. **接线没做**（加步会打破刚冻结的 `27 gen=#51`），但草案逐字给全：四处 ＋ 台账一件 ＋ **第五处隐含的**（新 `gen=` 必须有对应的预登记件，否则 `prereg-absent` ⇒ `NOINFO`）；机械核过：工具**现在不在** `fp_inputs()` 覆盖面，但进 `printf` 名单**必然**移动它（`72c5f226… → e4ec6c6e…`）⇒ 那一改要排在 `IN_FP_0` **之前**。
6. **一条我自己的错**已留痕：第一版拿"观测后功效"当门（它是 `p` 的单调函数 ⇒ 等于偷偷改 α），**被自测当场照出来**并改成"先写的计划当门 ＋ MDE 作诊断"。

---

<!-- SHA16-W117A 见下（口径：`grep -v '^<!-- SHA16' 本文件 | sha256sum | cut -c1-16`） -->
<!-- SHA16 592fb5b7fff7b094 -->
