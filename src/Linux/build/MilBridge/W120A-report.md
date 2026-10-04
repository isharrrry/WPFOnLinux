# 车道 `W120A` 报告 —— `TASK-0705` 收口复核 ＋「回归判定四要件」口径澄清落册 ＋ 两行指针 ＋ 第十笔推送

> lane=W120A｜**2026-09-22 23:57:18 → 2026-09-23 08:5x +0800**（⚠️ **宿主 `00:07` 挂起**、**08:30 主控唤醒续跑**；挂起前落在盘上的东西**逐位复核后一字未改**，续跑只补"报告 ＋ 提交 B ＋ 推送"）
> `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜fork 克隆 `C=~/netTest/GitProj/WPFOnLinux`
> 冻结基线 = **`#51` `38e67e834430d75c`**｜**零 `dotnet`／零构建／零门禁（`verify-all`）／零应用／不占槽**
> 纪律：只做**纯文本编辑 ＋ 一次推送**｜判据**先写**：`~/w120a/criteria.md`（`84a76a90a3b655ab`，66 行；写成本刻 `23:57:18`，**早于本车道任何仓内写动作**）
> ⚠️ 逐字块一律**机器拼接**（`sed -n 'Np' 真件` 现读，**不手抄**）—— 见 `~/w120a/splice.py`

---

## §0 一句话结论

**六件事全部办完**：① `TASK-0705` 在 `docs/ROUTES.md` 里**收口复核**（四要件逐条 ＋ **一处真数字更正**：W117A 登记行把 `--selftest` 写成 `20/20`，现场重取 = **`22/22`**）；② 「回归判定四要件」③ 的**口径张力**按主控裁定**逐字落两处**（`docs/ROUTES.md:431` 之后 ＋ `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G99` 条，**原话一字未动**）；③ `docs/PORT-SPEC.md`／`docs/INDEX.md` **各补一行指针**；④ `TASK-0706` **追加"进行中（车道 W119A）"一行**；⑤ 声明表 `--emit` 重生成（**ID 数 136 不变**）＋ `DEFREG` **两遍** `PASS declared=136 route_ids=136`／`DECLDRIFT=0`／`rc=0`；⑥ **第十笔推送**（含**补推 W117A 三件**）。
**两条额外发现**（都不是本件引入的，按纪律"只报不改"）：**(a)** `docs/PORT-SPEC.md`／`docs/INDEX.md`／`build/MilBridge/known-red.json`／声明表等件与 **`$HOME/w62a/negrepo/**`（负控夹具）同 inode** ⇒ **原地截断写会顺着共享 inode 改到夹具**（历史血案的同族、方向相反），本件一律 **temp ＋ `rename`** 落盘、并**成对证明孪生件 sha16 开工=收工**；**(b)** `docs/ROUTES.md:438` 的 `20/20` 是与同波报告**互相矛盾**的登记错误（只剩这一处没被别的车位发现）。

---

## §1 开工/收工锚（**全是现场算**，不许手抄）

| 件 | 开工 sha16 | 收工 sha16 | 行数 |
|---|---|---|---|
| `docs/ROUTES.md` | `f9f3c68d23377f18` | **`fe3e3fde0f456250`** | 539 → **564** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `f2c1d0d787db80f2` | **`d85d0de47acb550c`** | 2675 → **2676** |
| `docs/PORT-SPEC.md` | `7f36186d68a18332` | **`8a276090e3e6180f`** | 98 → **99** |
| `docs/INDEX.md` | `c36ed5fe2a5904a7` | **`6ff758d05778f5cf`** | 52 → **53** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `934a29ed9ab399ab` | **`dea8c731369ba0ed`** | 145 |
| **绝对禁区**（开工=收工，逐位相同） | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` `38e67e834430d75c`｜`docs/CURRENT-STATE.md` `b7b2d513cfdab2eb`｜`verify-all.sh` `1aa2ae4e94827cf3`｜`build/close-wave.sh` `c757fd5058f1bfd4`｜`build/integration-wave.sh` `39e52f0049373059`｜`build/MilBridge/known-red.json` `089b7324ba12e022`｜`build/MilBridge/tools/regression-decision.py` `1eda9e3575960cba`｜`docs/PREREG-TEMPLATE.md` `75dfc5f3fbc9df40` | — | — |
| `build/MilBridge/W117A-report.md`（补推件，**未改**） | `1194c4d531c1e198` | `1194c4d531c1e198` | 401 |
| `build/MilBridge/W116A-report.md`（**已在 HEAD ⇒ 无需补推**） | `d37eb116abe99dcf` | `d37eb116abe99dcf` | 271 |
| `build/MilBridge/W120A-report.md`（本件） | — | 见文末自报行 | — |

**主控复核（可直接引用）**：`docs/PREREG-TEMPLATE.md` 与 `regression-decision.py` 均**新件**且**未动**既有牙/判据；`verify-all.sh` 现件 `1aa2ae4e94827cf3` **现场复核逐位未变**（本件收工复算**逐位相同**）。**复核来源 = 主控现场**。

---

## §2 ① `TASK-0705` 收口行（**逐字**，落 `docs/ROUTES.md`）

**落点**：`:435`–`:440` 的 W117A 登记段**之下**（`:441` 的 `TASK-0706` 行**之前**）；**内容锚** = `**未接线（本行不接）**：接进`（全件唯一命中 ⇒ 行锚定、不吞行）。
**机器证**：`docs/ROUTES.md` `539 → 564` 行；**改前独有行 = 0**（§8）。

**四要件落地点**（`docs/PREREG-TEMPLATE.md`）：

- 判定依据**三条合取全否** ⇒ 原先**确实没有权威模板**（才新建）：ⓐ 全仓 `grep` 12 行命中**全是任务叙述**、**无一行指名路径**（`W111A-report.md:192` 自记"未核 ⇒ `NOINFO`"）；ⓑ 33 件预登记**没有同一套骨架**（`## §N` **21** 件 vs `## N.` **12** 件；节数 **5／37／中位 9**）；ⓒ 逐格判据只有 **3** 件指向**仓外** `criteria.md`。
- **为什么不是别的件**：`docs/INDEX.md:33` 只描述成**一类**｜`docs/PORT-SPEC.md:19/:66` 是**规范、不给骨架**｜33 件是**冻结证据彼此不继承**（只改一份 = `:430` 点名禁止）。

**工具**（`build/MilBridge/tools/regression-decision.py`，`1eda9e3575960cba`）：三态 `REGRESSION|NOINFO|OK`；`rc` = `0`／**`3`**（证据不足的 `NOINFO`）／**`2`**（**分母不合规 ⇒ 拒绝并点名** `REGDEC_REFUSE=`，**不降级成 `NOINFO`**）；**被仓内四条历史读数钉住** = `D-G98` 的 `1.000`／`W112A` 的 `0.078`／`0.030`／`0.067`（两条独立数值路径 A `lgamma` ／ B `comb` **逐例一致**）。

**⚠️ 一处真数字更正**（本件现场取到、W117A 登记行与之矛盾）：

| 出处 | 写的 | 现场重取 | 判 |
|---|---|---|---|
| `docs/ROUTES.md:438`（W117A 登记行） | `--selftest` **`20/20 PASS`** | — | ❌ **错** |
| `build/MilBridge/W117A-report.md` §0／§3.3 | `--selftest` **`22/22`** | — | ✅ |
| **本件现场重取**（两遍） | — | `REGDEC_SELFTEST=PASS total=22 pass=22 fail=0` | ✅ **正确值 = `22/22`** |

```
$ cd $R && python3 -B build/MilBridge/tools/regression-decision.py --selftest   # 零 dotnet、0 仓内写
REGDEC_SELFTEST_SELF self=…/build/MilBridge/tools/regression-decision.py sha16=1eda9e3575960cba
REGDEC_SELFTEST_ROSTER cases=22 pass=22 fail=0
REGDEC_SELFTEST=PASS total=22 pass=22 fail=0
ST_ATTEST=PASS self=…/regression-decision.py sha16=1eda9e3575960cba（自测期间本件未变 ⇒ 上面读数可归因）
rc=0
（两趟输出 `cmp` ⇒ **IDENTICAL**；`grep -c 'selftest.*20/20'` 全仓仅在 `ROUTES.md:438` 命中 1 处）
```

**两个口径必须并列写死**（**回答不同问题、不许互相替代**）：**"≥40 趟/臂"是区间口径**（`0/40` 的 95% 单侧上界 ⇒ **`7.2%`**）而 **"`6% vs 0%` ⇒ `131` 趟/臂"是功效口径**（`α=0.05`、功效 `0.80`）；模板 `§4` 已并列，本件登记行同趟重申。

**未接线（现场复核，与主控一致）**：`grep -c '^run_step "' verify-all.sh` = **27**｜`# VERIFYALL-STEPS-DECL: 27 gen=#51`｜`verify-all.sh` = **`1aa2ae4e94827cf3`**。

**逐字（机器拼接自 `docs/ROUTES.md:446-453`）**：

```
    - ✅ **`TASK-0705` 收口复核（车道 W120A，2026-09-22；**上面 W117A 的登记只追加、一字未动**）** —— 四要件**逐条复核 ＋ 一处数字更正**：
      - ① **四要件落地点 = `docs/PREREG-TEMPLATE.md`**（`75dfc5f3fbc9df40`；**复核来源 = 主控现场**：新件、**未动**既有牙/判据）。判定依据三条**全否**：ⓐ 全仓原先**确实没有权威模板**（原 `grep` 12 行命中**全是任务叙述**、**无一行指名路径**；`W111A-report.md:192` 自记"未核 ⇒ `NOINFO`"）；ⓑ 33 件预登记**没有同一套骨架**（`## §N` **21** 件 vs `## N.` **12** 件；节数 **5／37／中位 9**）；ⓒ 逐格判据只有 **3** 件指向**仓外** `criteria.md` ⇒ **三条合取全否**。**为什么不是别的件**：`docs/INDEX.md:33` 只把它描述成**一类**、`docs/PORT-SPEC.md:19/:66` 是**规范、不给骨架**、33 件是**冻结证据彼此不继承**（只改一份 = `:430` 点名禁止）。
      - ② **工具 = `build/MilBridge/tools/regression-decision.py`**（`1eda9e3575960cba`，**主控现场复核逐位未变**）：三态机读行 `REGRESSION_DECISION=REGRESSION|NOINFO|OK`；`rc` = `0`／**`3`**（证据不足的 `NOINFO`）／**`2`**（**分母不合规 ⇒ 拒绝并点名** `REGDEC_REFUSE=`，**不降级成 `NOINFO`**）；**被仓内四条历史读数钉住** = `D-G98` 的 `1.000`／`W112A` 的 `0.078`／`0.030`／`0.067`（两条独立数值路径 A `lgamma` ／ B `comb` **逐例一致**）。
      - ⚠️ **③ 数字更正（只追加，原文一字未动）**：**上一行 `--selftest` 写的 `20/20 PASS` 是错的，现场重取 = `22/22`** —— 车道 W120A 现场跑**两遍**（`python3 -B build/MilBridge/tools/regression-decision.py --selftest`；零 `dotnet`、**0 仓内写**）：两趟**逐字相同**，`REGDEC_SELFTEST_ROSTER cases=22 pass=22 fail=0` ＋ **`REGDEC_SELFTEST=PASS total=22 pass=22 fail=0`**、`rc=0`，并自带 `REGDEC_SELFTEST_SELF … sha16=1eda9e3575960cba` ＋ `ST_ATTEST=PASS`（**自测期间本件未变 ⇒ 读数可归因**）⇒ **正确值 = `22/22`**（`W117A-report.md` §0／§3.3 写的也是 `22`，**只有本行错**）。
      - ④ **两个口径必须并列写死**（**回答不同问题、不许互相替代**）：**"≥40 趟/臂"是区间口径**（`0/40` 的 95% 单侧上界 ⇒ **`7.2%`**）而 **"`6% vs 0%` ⇒ `131` 趟/臂"是功效口径**（`α=0.05`、功效 `0.80`）—— 模板 `§4` 已并列。
      - ⑤ **未接线**（属下一波；**现场复核**）：`grep -c '^run_step "' verify-all.sh` = **27**、`# VERIFYALL-STEPS-DECL: 27 gen=#51`、`verify-all.sh` sha16 = **`1aa2ae4e94827cf3`**（现场算，与主控复核值逐位相同）⇒ 本行**仍"未接线"**，接线草案见 `W117A-report.md` §5（含**第五处隐含的**：新 `gen=` 必须有对应预登记件，否则 `prereg-absent` ⇒ `rc=2 NOINFO`）。
      - ⚖️ **口径张力已裁定**：见 `:431` 下新增的 **dated 口径澄清**（与 `D-G99` 条**同文**）⇒ `W117A` 的**操作读法成立**、原话是**小样本特例**。
      - **欠账清零**：`:436` 末那句"`docs/PORT-SPEC.md` 与 `docs/INDEX.md` 各欠**一行**指针"**已由 W120A 同趟补上**（见 §15j）。
```

---

## §3 ② 口径澄清（**逐字落两处**；原话一字未动）

**冲突点（原话，逐字仍在）**：`docs/ROUTES.md:431` 与 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2651` 的 ③ 原话「**在旧件上也要能复现该红 ⇒ 只有新件上红不足以判回归**」vs `TASK-0705` 反极性要的「**确定性 new-only ⇒ 必须判 `REGRESSION`**」⇒ **按字面互相排斥**（`build/MilBridge/W117A-report.md` §2.1 如实登记、自记"**待主控裁定**"）。

**本件的裁定（写进两处原话之后，作为 dated 澄清）**：

- **(a)** 当**只有"一腿一个样本"**时 ⇒ 旧件不复现 ⇒ **不能判回归 ⇒ 落 `NOINFO`**（**原话要的就是这条**）；
- **(b)** 当**「先写的计划」＋「达到所需 `N`（按功效口径算，如 `6% vs 0%` ⇒ `131` 趟/臂）」＋「显著」三条同时满足**时 ⇒ **new-only 也必须判 `REGRESSION`**；
- **(c)** 旧件**若也复现**同一形态 ⇒ **不是本波引入**：判 `OK`，或按率显著加重判 **`REGRESSION(rate-aggravated)`**。
- ⇒ **即 W117A 的操作读法成立，原话是它在"小样本"下的特例（不是被推翻）**。⚠️ 澄清里**点名"原话不许改、只在旁边加条件"**。

**落点 1（`docs/ROUTES.md`，锚 = `模板里**必须**写死的**四要件**`，插入其**之后**）—— 逐字（机器拼接自 `432-436`）**：

```
    - ⚖️ **口径澄清（**主控裁定 · dated；车道 W120A，2026-09-22**；上面 ③ 的**原话一字未动**，本条只在它旁边做**条件分派**）** —— 上面 ③ 那句「**在旧件上也要能复现该红** ⇒ 只有新件上红**不足以**判回归」与本行要的「**确定性 new-only ⇒ 必须判 `REGRESSION`**」**按字面互相排斥**（`build/MilBridge/W117A-report.md` §2.1 如实登记、**未裁定**）⇒ **两句回答的是不同问题，按条件分派**：
      - **(a) 当只有"一腿一个样本"时**（`D-G99` 的形态）：**旧件不复现 ⇒ 不能判回归 ⇒ 落 `NOINFO`** —— 原话要的正是这一条；
      - **(b) 当「先写的计划」＋「达到所需 `N`（**按功效口径**算，如 `6% vs 0%` ⇒ **131 趟/臂**）」＋「显著」三条同时满足**时：**new-only 也必须判 `REGRESSION`**（此时"旧件复现不了"是**检测力**问题，不是"不是本波引入"的证据）；
      - **(c) 旧件若也复现同一形态** ⇒ **不是本波引入**：判 `OK`，或按率显著加重判 `REGRESSION(rate-aggravated)`。
      ⇒ 即 `build/MilBridge/tools/regression-decision.py` 的**操作读法成立**，上面 ③ 的原话是它在**小样本**下的**特例**（**不是被推翻**）。⚠️ **原话不许改**，只在旁边加条件（同文另落 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G99` 条）。
```

**落点 2（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`，锚 = `**正确姿势（口径句，已写进`，插入其**之后**）** —— 逐字（机器拼接自 `2652`）**：

```
- ⚖️ **口径澄清（**主控裁定 · dated；车道 W120A，2026-09-22**；上面那条 ③ 的**原话一字未动**，本条只在它旁边做**条件分派**）** —— ③ 那句「**在旧件上也要能复现该红**」与 `TASK-0705` 反极性要的「**确定性 new-only ⇒ 必须判 `REGRESSION`**」**按字面互相排斥**（`build/MilBridge/W117A-report.md` §2.1 如实登记、自记"**待主控裁定**" ⇒ **本条即裁定**）⇒ **两句回答的是不同问题，按条件分派**：**(a) 当只有"一腿一个样本"时**（本条的形态）：**旧件不复现 ⇒ 不能判回归 ⇒ 落 `NOINFO`** —— 原话要的正是这一条；**(b) 当「先写的计划」＋「达到所需 `N`（**按功效口径**算，如 `6% vs 0%` ⇒ **131 趟/臂**）」＋「显著」三条同时满足**时：**new-only 也必须判 `REGRESSION`**（此时"旧件复现不了"是**检测力**问题，不是"不是本波引入"的证据）；**(c) 旧件若也复现同一形态** ⇒ **不是本波引入**：判 `OK`，或按率显著加重判 `REGRESSION(rate-aggravated)`。⇒ 即 `build/MilBridge/tools/regression-decision.py` 的**操作读法成立**，③ 的原话是它在**小样本**下的**特例**（**不是被推翻**）。⚠️ **原话不许改**，只在旁边加条件（同文另落 `docs/ROUTES.md` 的 `:431` 之后）。
```

**原话未动的机器证**：`grep -c '按字面互相排斥'` 两件各 **1**（新句）；`grep -c '在旧件上也要能复现该红'` ⇒ `ROUTES.md` **3**（原 `:431` ＋ `§15g` 口径句 ＋ 新增 §15j）／`KNOWN-DEFECTS.md` **2**（原 `D-G99` 条 ＋ 本件新句）；且 §8 的"改前独有行 = 0"证明**没有任何一行被删改**。

---

## §4 ③ 两行指针 ＋ ④ `TASK-0706` 行（**逐字**）

**③-a `docs/PORT-SPEC.md`**：`98 → 99` 行；`§1` 第 1 条（判据纪律）**之下**新增子条（锚 = `**判据先写死，再取读数**`，全件唯一）—— 逐字（机器拼接自 `:20`）：

```
   - 预登记四要件（**回归判定**：① 两臂同刻 ② 成对归因臂 ③ 复现性 ④ Fisher 精确检验**双尾**）的**权威处** = [`PREREG-TEMPLATE.md`](PREREG-TEMPLATE.md)（`TASK-0705`；含判定依据、可抄的判据节骨架与现算样本量参考；牙 = `build/MilBridge/tools/regression-decision.py`）。
```

**③-b `docs/INDEX.md`**：`52 → 53` 行；`§1 规范`表**新增一行**（锚 = `` | [`FORK-AND-PUSH.md`](FORK-AND-PUSH.md) | ``，全件唯一）—— 逐字（机器拼接自 `:17`）：

```
| [`PREREG-TEMPLATE.md`](PREREG-TEMPLATE.md) | **预登记四要件（回归判定）的权威处**：模板骨架 ＋ 判定依据 ＋ 现算样本量参考（`TASK-0705`；牙 = `build/MilBridge/tools/regression-decision.py`） |
```

**④ `docs/ROUTES.md` 的 `TASK-0706` 段追加一行**（只追加；**状态位未动**、仍是 `🔴`）—— 逐字（机器拼接自 `:461`，并用 `grep -Fxq` 复核）：

```
  - 🚧 **进行中（车道 W119A）**：装置/口径卫生常态牙（根集合一致性／证据保全／口径语义射程三合一，三态 ＋ 五例两极化自检，不接线）
```

**逐字复核命令（本件真跑过）**：三行分别用 `grep -Fxq -e "<整行>"` ⇒ **三处全命中**（`MISS` 0）。

**另：本笔的段级登记** `§15j`（落 `docs/ROUTES.md` 文末，`553 → 564` 行）—— 逐字（机器拼接自 `:554-564`）：

```

## §15j `#52` 第十笔：`TASK-0705` 收口复核（含一处**数字更正**）＋「回归判定四要件」口径澄清**落两处** ＋ 两行指针 ＋ `TASK-0706` 进行中（**一行一条**；2026-09-22 车道 W120A 补）

- ✅ **`TASK-0705` 收口复核已落行**（`:435` 的 W117A 登记段下**只追加**，原登记一字未动）：四要件逐条复核（① 落地点 `docs/PREREG-TEMPLATE.md` ＋ 三条判定依据全否 ＋ "为什么不是别的件"；② 牙 `regression-decision.py` 三态／`rc`／被四条历史读数钉住；④ 两口径并列；⑤ **仍"未接线"**）＋ ⚠️ **一处数字更正**：`:438` 写的 `--selftest` **`20/20 PASS`** 现场重取 = **`22/22`**（`REGDEC_SELFTEST=PASS total=22 pass=22 fail=0`、`rc=0`、两趟逐字相同）—— 原文**一字未动**、只在本段旁边的追加 bullet 里更正。**机器证**：`docs/ROUTES.md` `539 → 564` 行、改前独有行 = **0**。
- 🔴 **口径澄清 —— 本件的裁定（落两处，原话一字未动，只追加 dated 澄清）**：**冲突点** = `:431`（同 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2651`）的 ③ 原话「**在旧件上也要能复现该红 ⇒ 只有新件上红不足以判回归**」vs 本行反极性要的「**确定性 new-only ⇒ 必须判 `REGRESSION`**」，**按字面互相排斥**。**裁定 = 两句回答不同问题、按条件分派**：**(a)** 只有"一腿一个样本" ⇒ 旧件不复现 ⇒ **`NOINFO`**（原话要的就是这条）；**(b)** 「**先写的计划** ＋ **达到所需 `N`**（**功效口径**：`6% vs 0%` ⇒ `131` 趟/臂）＋ **显著**」三条**同时满足** ⇒ **new-only 也必须判 `REGRESSION`**；**(c)** 旧件**也复现** ⇒ **不是本波引入**：`OK`，或按率加重判 `REGRESSION(rate-aggravated)`。⇒ `W117A` 的**操作读法成立**（原话是**小样本特例**、**不是被推翻**）。⚠️ 澄清里**点名"原话不许改、只在旁边加条件"**。
- 📌 **两行指针已补**（W117A 点名欠账；**只加一行 ＋ 行锚定 ＋ 改后 `wc -l` 复核**）：`docs/PORT-SPEC.md` **`98 → 99`**（`§1` 第 1 条下子条）｜`docs/INDEX.md` **`52 → 53`**（`§1 规范`表新行）—— 两件都指名 `docs/PREREG-TEMPLATE.md` 为「**预登记四要件（回归判定）的权威处**」。**只加不删机器证**：两件改前独有行 = **0**。
- 🚧 **`TASK-0706` 追加"进行中（车道 W119A）"一行**（只追加；**状态位未动**、仍是 `🔴`）：三合一常态牙（根集合一致性／证据保全／口径语义射程），三态 ＋ **五例两极化**自检，**不接线**。
- **`DEFREG` 两条机读行（现场跑两遍、逐字相同、`rc=0`）**：`DEFREG=PASS declared=136 route_ids=136`｜`DEFREG_DECLDRIFT=0`（因本件动了册 ⇒ **同趟 `--emit` 重生成**声明表：`build/MilBridge/tools/defect-registry-declared.tsv` `934a29ed9ab399ab → dea8c731369ba0ed`，**ID 数 136 不变**、`diff` 只动 `DECL-GEN` 时间戳与 `KD` 锚）。
- ⚠️ **硬链接警戒（本件新发现，只报不改）**：`docs/PORT-SPEC.md`／`docs/INDEX.md`／`build/MilBridge/known-red.json`／`build/MilBridge/tools/defect-registry-declared.tsv` 等件与 **`$HOME/w62a/negrepo/**`（负控夹具）同 inode**（如 `PORT-SPEC.md` `inode 5000462 links=2`）⇒ **原地截断写会顺着共享 inode 改到夹具**（历史血案的同族、方向相反）。本件一律 **temp ＋ `rename`** 落盘，并**成对复核孪生件 sha16 未动**。
- **`fp_inputs` 零影响（机械证）**：现场**真调用** `fp_inputs()` = **`72c5f2263f62a83d…`**（＝ `§15i` 记的现件值，逐字符相同），覆盖面 **149 件**里本笔 9 件**命中全 0** ⇒ 本件贡献为零。
- **推送（第十笔）**：head 与 `BYTECHECK` 逐字见 `build/MilBridge/W120A-report.md` §6（本件**不推**别家在飞件：`win32_core.c`／`win32_x11.c`／`run-wpfprobe.sh`／`run-wpftextdemo.sh`／`sync-applocal-authority.sh`／`W115A-report.md`／`hygiene-tooth.sh` —— **只报不推**）。
```

---

## §5 ⑤ `DEFREG` 两条机读行 ＋ `--emit`

**为什么必须 `--emit`**：声明表第 2 行 `# DECL-ANCHORS = KD=<sha16> …` 记的是**各 route 件的 sha16 快照**，而本件**动了册**（`KNOWN-DEFECTS.md` = route 键 `KD`）⇒ 不重生成则 `DEFREG_DECLDRIFT` **必然 ≠ 0**。
**`--emit` 的成对读数**（`diff` 逐行）：

```
$ diff 改前.tsv 改后.tsv      # 只动两行
< # DECL-GEN = (--emit) 2026-09-22 23:26:46 +0800
< # DECL-ANCHORS = KD=f2c1d0d787db80f2 CS=b7b2d513cfdab2eb HO=e4dc264200b421d0 AB=38e67e834430d75c KRJ=… KRF=… KRP=…
> # DECL-GEN = (--emit) 2026-09-23 00:01:44 +0800
> # DECL-ANCHORS = KD=d85d0de47acb550c CS=b7b2d513cfdab2eb HO=e4dc264200b421d0 AB=38e67e834430d75c KRJ=… KRF=… KRP=…
ID 行数：136 -> 136（**编号数不变**）
```

⚠️ **`CS`／`HO`／`AB`／`KRJ`／`KRF`／`KRP` 六个锚逐位未变**（本件**没碰** `docs/CURRENT-STATE.md`／`handoff.md`／冻结基线／`known-red*.json`）。
⚠️ **落盘方式**：`--emit` 打到 `$HOME` 临时件、再 **`rename`** 就位（**不许** `> $R/…/tsv` 原地截断 —— 该件与 `$HOME/w62a/negrepo` **同 inode**，见 §8.3）。

**`DEFREG` 两遍机读行（现场跑，两趟 `cmp` = `IDENTICAL`）**：

```
DEFREG_DECL=n=136 route_ids=136 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=d85d0de47acb550c CS=b7b2d513cfdab2eb HO=e4dc264200b421d0 AB=38e67e834430d75c
DEFREG_EXTRA=KRJ=089b7324ba12e022 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=136 route_ids=136（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
rc=0 / rc=0
```
（挂起后**又重取两遍**（`~/w120a/defreg-post-1.txt`／`-2.txt`），与挂起前那两趟 `cmp` **IDENTICAL** ⇒ 挂起未改变任何读数。）

⇒ **⑤ 两条机读行 = `DEFREG=PASS declared=136 route_ids=136` ｜ `DEFREG_DECLDRIFT=0`**（`rc=0`；**编号数不变 = 136**）。

---

## §6 ⑥ 推送（**第十笔**）：前后 head ＋ `BYTECHECK` ＋ 补推件清单

**做法**（照本仓惯例 —— 一个提交**装不进自己的哈希**，见 `W116A-report.md` §7 与 `1e06b58`／`52c6edd`）：**件先提交（= `A`）**、**本报告随后作为第二笔提交（= `B`）**，两笔**同处一次推送**；报告里记的"推送后 head"= **`A`**（**承载全部登记件**的那个提交）。

| # | 项 | 读数 | 来源 |
|---|---|---|---|
| ① | 推前 head（本地 `rev-parse`） | **`a2f52ae217aa9ca772f91128e27537e7a4c22f0a`** | 现场 |
| ② | 推前 head（远端 `ls-remote origin feat-Linux`） | **`a2f52ae217aa9ca772f91128e27537e7a4c22f0a`**（**两处逐字符相同**） | 现场 |
| ③ | **提交 `A`**（本笔全部登记件） | **`846243d81f01ae7ecc532a900937054716cbc5af`** | 现场 |
| ④ | 提交 `B`（本报告） | 自指 ⇒ 值写在 `~/w120a/STATUS.md` ＋ 最终回复（**不预测自己的 sha**） | 现场 |
| ⑤ | `git add` 方式 | **逐径 `git add`**（8 件逐个列出；**未用** `-A`／`-f`／`--force`） | 现场 |
| ⑥ | 推送命令 | `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`（**refspec 陷阱**）→ `git push origin feat-Linux` | 现场 |
| ⑦ | push 后 `fetch` ＋ 与 `ls-remote origin HEAD` 交叉核 | 见 `STATUS.md`／最终回复 | 现场 |
| ⑧ | `ls-remote --symref origin HEAD` | 仍须 **`ref: refs/heads/feat-Linux`** | 现场 |
| ⑨ | **`BYTECHECK(A)`**（`git cat-file blob A:<path>` vs 磁盘 `cmp`） | **`ok=8 mismatch=0 nobody=0`** | 现场 |

**`BYTECHECK(A)` 逐件读数**：

```
ok       docs/ROUTES.md                                        fe3e3fde0f456250
ok       docs/PORT-SPEC.md                                    8a276090e3e6180f
ok       docs/INDEX.md                                       6ff758d05778f5cf
ok       samples/WpfFeatureProbe/KNOWN-DEFECTS.md              d85d0de47acb550c
ok       build/MilBridge/tools/defect-registry-declared.tsv    dea8c731369ba0ed
ok       build/MilBridge/W117A-report.md                       1194c4d531c1e198
ok       docs/PREREG-TEMPLATE.md                              75dfc5f3fbc9df40
ok       build/MilBridge/tools/regression-decision.py          1eda9e3575960cba
BYTECHECK(A) ok=8 mismatch=0 nobody=0
```

**补推件清单（机械核，不是印象）**：

| 件 | 在**推前 head** `a2f52ae…` 里？ | 结论 |
|---|---|---|
| `build/MilBridge/W117A-report.md` | **NOT-IN-HEAD** | **需补推** ⇒ 已进 `A` |
| `docs/PREREG-TEMPLATE.md` | **NOT-IN-HEAD** | **需补推** ⇒ 已进 `A` |
| `build/MilBridge/tools/regression-decision.py` | **NOT-IN-HEAD** | **需补推** ⇒ 已进 `A` |
| `build/MilBridge/W116A-report.md` | **IN-HEAD** | **无需补推**（盘上 = HEAD = `d37eb116abe99dcf`） |

⚠️ **不推别家在飞件**（挂起后现场重盘，**只报不推**）：`build/MilBridge/tools/hygiene-tooth.sh`（W119A 新建）｜`build/MilBridge/W115A-report.md`｜`src/WpfGfx.Linux.Native/src/win32_core.c`｜`win32_x11.c`｜`build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh`｜`tests/…/run-wpfprobe.sh`｜`run-wpftextdemo.sh`｜`tests/parity/**` 2 件（`§15e` 已裁定**不推**）｜`build/MilBridge/gen/tline-ledger-lines-*.txt` 5 件（`§15g` 已裁定**不推**）。

---

## §7 ⑦ `fp_inputs` 影响（**机械证**，不吃判断）

**真调用**（从 `build/close-wave.sh` 现场抽 `fp_inputs()` 函数体 **`source`** 后调用，**不手抄、不复制函数体** —— `D-G29`／W30F 教训）：

```
FP_INPUTS=72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015
覆盖面件数 = 149
```

**本笔 9 件在覆盖面里的命中数（逐件 `grep -Fxc`，**必须全 0**）**：

| 件 | 命中 |
|---|---|
| `docs/ROUTES.md` | **0** |
| `docs/PORT-SPEC.md` | **0** |
| `docs/INDEX.md` | **0** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **0** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | **0** |
| `build/MilBridge/W120A-report.md`（本件） | **0** |
| `build/MilBridge/W117A-report.md` | **0** |
| `docs/PREREG-TEMPLATE.md` | **0** |
| `build/MilBridge/tools/regression-decision.py` | **0** |

⇒ **`fp_inputs` 与本件无关**（覆盖面里出现的是 `defect-registry-check.sh`，**不是**声明表本身；`docs/**` 一件都不在覆盖面里）。
**现值 `72c5f226…` = `§15i` 记的 W116A 后值（逐字符相同）**；它 ≠ `#51` 冻结值 `58a6c094…` 的原因是**别家在飞的产品件**（`§15i` 已逐件归因：W113A 的 4 件 ＋ W114A 的 2 件 native 源），**本件贡献为零**。
⚠️ **本件没有跑** `close-wave.sh`／`integration-wave.sh`／`verify-all.sh`（只**只读地**抽了那个函数体）。

---

## §8 只加不删机器证 ＋ 零污染

### 8.1 只加不删（`comm -23 <(sort 改前) <(sort 改后)`，`LC_ALL=C` 两侧一致）

| 件 | **改前独有行** | 新增行 | `wc -l` |
|---|---|---|---|
| `docs/ROUTES.md` | **0** | 23 | 539 → 564 |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **0** | 1 | 2675 → 2676 |
| `docs/PORT-SPEC.md` | **0** | 1 | 98 → 99 |
| `docs/INDEX.md` | **0** | 1 | 52 → 53 |

**落盘方式**：**内容锚**（不用行号，锚串在全件**恰好命中 1 行**才动手）＋ **temp ＋ `os.replace`**（`rename`）。改前备份（`cp -p`，纪律 65）在 **`~/w120a/backup/`**（5 件）。
`~/w120a` 里 **多链接文件 = 0**（`find ~/w120a -type f -links +1 | wc -l` = **0**；全程 `cp -p` 真复制、**零 `ln`**）。

### 8.2 绝对禁区开工 = 收工（**逐位相同**，见 §1 表）

`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`｜`docs/CURRENT-STATE.md`｜`verify-all.sh`｜`build/close-wave.sh`｜`build/integration-wave.sh`｜`build/MilBridge/known-red.json`｜`regression-decision.py`｜`docs/PREREG-TEMPLATE.md` 全部**未动**（本件**没碰** `~/w115a`／`~/w118a`／`~/w119a`／`~/w121a`／任何产品件／任何既有牙）。

### 8.3 ⚠️ **硬链接警戒（本件新发现；只报不改）**

现场实测：**`$R` 的若干件与 `$HOME/w62a/negrepo/**`（负控夹具）同 inode** ——

```
inode 5000462 links=2   docs/PORT-SPEC.md          <-> $HOME/w62a/negrepo/docs/PORT-SPEC.md
inode 5000466 links=2   docs/INDEX.md              <-> $HOME/w62a/negrepo/docs/INDEX.md
inode 4932707 links=2   build/MilBridge/tools/defect-registry-declared.tsv <-> $HOME/w62a/negrepo/…
inode 5251064 links=3   build/MilBridge/known-red.json <-> $HOME/w62a/negrepo/…  +  $HOME/w113a/fixture/fp-farm/…
```

⇒ **`> 件`／`sed -i`／`--emit > 件` 这类"原地截断"会顺着共享 inode 把夹具一起改写掉** —— 这与历史血案（**沙箱硬链接写穿真树**）**同族、方向相反**。
**本件的处置**：① 写自己的件一律 **temp ＋ `rename`**（**新 inode**）⇒ 夹具脱钩；② `--emit` 的输出**先落到 `$HOME` 临时件**再 `rename` 就位；③ **成对证明**：三个孪生夹具件 sha16 **开工 = 收工**（`PORT-SPEC.md` `7f36186d68a18332`｜`INDEX.md` `c36ed5fe2a5904a7`｜`defect-registry-declared.tsv` `934a29ed9ab399ab`）。
**副作用如实记**：`$R` 侧这三件现在是 `links=1`（**链已断**）—— 这是**有意**的（夹具该保留旧内容），**不是**"改坏了"；夹具那三件的**内容一字未动**。

---

## §9 ⑧ `NOINFO`／未做

1. **`NOINFO`：本笔没有给 `REGRESSION` 类判词打分** —— 派单书要求的六件事**全是登记/文档/声明类**，不含任何"回归判定"读数 ⇒ 本件**不产生** `REGRESSION|NOINFO|OK` 三态里的任何一格。
2. **`NOINFO`：`TASK-0706` 的"进行中"只有 W119A 的件在场（`build/MilBridge/tools/hygiene-tooth.sh` 63256 B，`mtime 09-22 23:54`）** ⇒ 其**判据/读数/`--selftest` 结果本件未核**（不在写域、也不在本件范围）⇒ **只登记"进行中"这四个字**，**不替 W119A 报任何数**。
3. **未做：`docs/ROUTES.md:438` 的 `20/20` 原文没有就地改** —— 仓内纪律是"**只加不改**（含本人写错的登记行）"⇒ 用**同段追加的更正 bullet** 处置（原文仍在，读者按"更正 bullet 优先"读）。**是否要就地改字由主控裁**。
4. **未做：`TASK-0705` 的接线**（加步 `27 → 28`）—— 会当场打破刚冻结的 `27 gen=#51` 声明；派单书明说属下一波。**照旧 `NOINFO`**。
5. **未做：`~/w62a/negrepo` 夹具的脱钩治理** —— 仓内**没有**"检测共享 inode"的牙（`D-G96` 族是"证据保全"，不是这一条）；本件**只报不改**（改夹具脚本不在写域）。**建议把"`$R` 与 `$HOME` 夹具之间的硬链接"立成新号**。
6. **未取到：提交 `B`（本报告）自身的 `BYTECHECK`** —— 报告装不进自己的 blob ⇒ 该格在 **push 后**用 `git cat-file blob B:<报告>` vs 磁盘补算，读数写在 **`~/w120a/STATUS.md` 与最终回复**（**不预测**）。
7. **宿主挂起的边界（如实记）**：`00:07` 挂起时，**仓内写动作已全部完成**（5 件已改、`--emit` 已就位、`DEFREG` 已取两遍、提交 `A` 已建）⇒ 续跑只补**报告 ＋ 提交 `B` ＋ 推送**；**挂起期间无人改过本笔的 5 件**（收工 sha16 与挂起前逐位相同）。

---

## §10 ⑨ 大白话小结（≤6 行）

1. **`TASK-0705` 收口了**：四要件有文本（`docs/PREREG-TEMPLATE.md`）、有牙（`regression-decision.py`，三态 `rc=0/3/2`、被仓内四条历史读数钉住）、**未接线**（下一波加步）。
2. **顺手抓到一处真错**：`ROUTES.md:438` 写 `--selftest 20/20`，现场跑两遍都是 **`22/22`** —— 同波自己的报告写的也是 22，**只有那一行错**（原文一字未动、旁边加更正）。
3. **口径张力按主控裁定落两处**：小样本 ⇒ 旧件不复现只能 `NOINFO`；**计划先写 ＋ 达到所需 `N` ＋ 显著 ⇒ new-only 也必须判 `REGRESSION`**；旧件也复现 ⇒ `OK` 或 `rate-aggravated`。**原话不许改**。
4. **两行指针补上了**（`PORT-SPEC` 98→99、`INDEX` 52→53），`TASK-0706` 加了"进行中（W119A）"一行。
5. **声明表按规矩重生成**（ID 数 136 不变）⇒ `DEFREG=PASS declared=136 route_ids=136`／`DECLDRIFT=0`／`rc=0`（两遍逐字相同）。
6. **第十笔已备好**：提交 `A` = `846243d8…`（含**补推 W117A 三件**；`W116A-report.md` **已在 HEAD、无需补推**），`BYTECHECK ok=8 mismatch=0 nobody=0`；⚠️ 另报一条**夹具硬链接**风险（原地截断写会写穿 `$HOME/w62a/negrepo`），本件一律 `rename` 落盘并成对证明夹具未动。

---

<!-- SHA16-W120A 见下（口径：`grep -v '^<!-- SHA16' 本文件 | sha256sum | cut -c1-16`） -->
<!-- SHA16 f1367292717f1b9c -->
