# P1-W57 独立复核（`verifier`）—— `t136`「`N1`/`N3`/空态参照集 收紧」方向判词

- **复核对象（现取）**：`HEAD=443c5f9651531ac88b84179c4edd2295ecdf3b32`（短 `443c5f9`，`2026-09-29T14:18:10+08:00`，父 `aea0481`）；本笔四条落点
  - `build/MilBridge/tools/pts-pages-guard.sh` ＝ **`201eca63e6820011`／1068 行**（修前版 `git show aea0481:…` ＝ **`e74ec5c2f6a87f0f`／921 行**；`numstat 160 13`）
  - `build/MilBridge/P1-realized-criteria-report.md` ＝ **`281b40613d6f1f34`／214 行**（`+14 0`）
  - `build/MilBridge/P1-realized-probe-report.md` ＝ **`186c918f2937d355`／179 行**（`+2 0`）
  - `build/MilBridge/P1-guard-n1-n3-tighten-report.md` ＝ **`a72f2594fdf81b14`／83 行**（`t136` 自载体）
- **本席读时**：`2026-09-29T14:20–14:26+0800`；**所有读数在本件命令里现取**（禁引上一代列印）；夹具与副本全部仓外（`~/wv88y/t139/**`），只用仓内件作**只读**输入。
- **判词（总）**：**「方向只有收紧」成立** —— 逐格自算后**未找到任何放松**（详见 §1–§4）；**不触发 `needs_revision`**。同时**点名 1 条本笔新引入、与自身写死契约不符的判词面缺陷（`F-1`，medium，不改变任何 verdict、也不放松任何既有要件）**与若干观察（§8），本件**不修**。
- 复核口径：`rc`（0/1/2）＋ `PTS_GUARD=` 判词行 ＋ **具名字段原文**；`NOINFO` 既不算绿也不算红（§7 具名）。

---

## §1 五处自测期望改动 —— 逐格「严/松」判词（每个格都有本席自己的旧/新成对实测）

方法：期望行的**语义**由「该夹具在**修前守卫**与**修后守卫**上各得什么 verdict」实测钉死（旧件 realized 副本 `~/wv88y/t139/mirror/build/MilBridge/tools/old-realized.sh` ＝ 由 `git show aea0481:…` 现取后仅改相位位；新件 `…/new-realized.sh` 同法）。

| 格 | 期望改动（新件行） | 夹具（本席自造，仓外） | **修前**实测 | **修后**实测 | 方向 |
|---|---|---|---|---|---|
| `c15` | `rz c15 PASS` ⇒ `rz c15 FAIL "realized·真实形态（必要件齐但无正证据 ⇒ 必红）"`（`:747`） | `fx/A2`（两腿 `fr_sha=c0ffee1234abcd99`∉集、`fr_ae_boot=15386>0`、两腿 `ink=480000>0`、同帧、无锚/无 `N4` 登记） | `rc=0 PTS_GUARD=PASS` | `rc=1 PTS_GUARD=FAIL`（`fails=n1-only-necessary-condition-no-positive-evidence(sha23=c0ffee1234abcd99,sha24=c0ffee1234abcd99,anchor=0,n4=absent)`） | **收紧** |
| `c16` | `rz c16 NOINFO` ⇒ `rz c16 FAIL "realized·缺 ink（且无正证据）⇒ 必红"`（`:752`） | `fx/F16`（`LEG` 行**不含 `ink=`**，其余同上） | `rc=2 PTS_GUARD=NOINFO` | `rc=1 PTS_GUARD=FAIL`（同时 `cannot=leg24(no-real-layout-evidence),leg23(no-real-layout-evidence)` 仍在） | **收紧**（门禁里 `NOINFO` 同为 ❌；此格把"算不出"改判为"红"，见 §8 `F-1` 的同类误标） |
| `c33` | `chk PASS` ⇒ `chk FAIL "realized·ENFE 全在 allowlist（但无 N1 正证据 ⇒ 整步红）"`（`:785`） | `fx/F33`（`A2` ＋ `[HC-UNHANDLED] … 'FsCreatePageBottomless'/'FsCreatePageFinite'` 两行）＋ `PTS_ENFE_ALLOWLIST=FsCreatePageBottomless,FsCreatePageFinite` | `rc=0 PTS_GUARD=PASS` | `rc=1 PTS_GUARD=FAIL`；`PTS_ENFE=PASS total=2 … allow=FsCreatePageBottomless,FsCreatePageFinite non_allow=none`（**ENFE 那一条本身仍不红**，红来自新闸） | **收紧** |
| `c36` | 断言串 `sha16=1a76488aa4a790b3∈{1a76488aa4a790b3}` ⇒ **`∈{1a76488aa4a790b3,ef3fd6765f18f51b}`**（`:816`；`chk FAIL` 期望**未动**） | `c36` 夹具＝两腿 `fr_sha=1a76488aa4a790b3` | 断言串跟随的是**单成员**登记值 | 断言串跟随**两成员累积**登记值；**可证伪实证**：把该字面回退成单成员后 `--selftest` 立刻 ✗（本席回退副本：`N1·点名(帧+要件+参照集) => no ✗`，见 §3） | **收紧**（断言跟随收紧后的登记值；非放松） |
| `c37` | `chk PASS` ⇒ `chk FAIL "realized·帧∉集∧位移>0 **但只有必要件** ⇒ 必红"`（`:825`） | `c36` 夹具 `sed fr_sha=c0ffee1234abcd99`（＝本席 `fx/A2` 同形） | `rc=0 PTS_GUARD=PASS`（`F-3` 那个**假绿形态**） | `rc=1 PTS_GUARD=FAIL` | **收紧** |

**五格合计**：4 格 `PASS/NOINFO ⇒ FAIL`（更严）＋ 1 格断言串改跟随累积集（更严）；**无一格放松**。
**名单完备性（本席自测证）**：把上述 5 处期望**逐一回退**的副本跑 `--selftest` ⇒ `PTS_GUARD_SELFTEST=FAIL pass=60 fail=6`，**6 条 ✗ 恰为**：`realized·真实形态`、`realized·缺 ink ⇒ NOINFO`、`realized·ENFE 全在 allowlist ⇒ 本条不红`、`N1·点名(帧+要件+参照集)`、`realized·帧∉集∧位移>0 ⇒ 不因该条红`，＋（因同一字面被一并回退的）`t136·新成员点名(累积集)` ⇒ **除这 5 处外没有任何别的既有期望被本笔逼着改**（`t136` 自陈「5 处」＝完备 ✓）。

---

## §2 13 处删除 —— 逐行追踪（`numstat 160 13` 的 13）

| # | 旧件行 | 删掉的是什么 | 新件行 | 语义是否变 | 方向 |
|---|---|---|---|---|---|
| ① | `85` `FRAME_EMPTY_SET="1a76488aa4a790b3"` | 单成员登记值 | `:98` `FRAME_EMPTY_SET="1a76488aa4a790b3,ef3fd6765f18f51b"` | **变**：更多帧被视为空态 ⇒ `N1①`（∉参照集）更难成立 | **收紧**（真树 realized 实测：修前 `PASS` ⇒ 修后 `FAIL`） |
| ② | `417` 注释 `⚠️ 只增不减：不改任何既有要件、三态语义、阈值。` | 一句注释 | `:445` 同句**保留**并加限定「（`t136` 只把"单独发绿"这一路堵死）」 | 无（注释；原句一字未删） | 中性（口径叙述；不涉判据） |
| ③ | `427` `PTS_N1=NOINFO …`（无 `phase=`） | 该判词行 | `:458` 同句 ＋ **`phase=$PHASE`**，尾句改指 `t136 O-2` 段 | 变：**加字段**（相位写明）；`NOINFO` 语义与折 `cannot` 不变 | **收紧**（`O-2`） |
| ④ | `443` `PTS_N1=PASS … criteria=frame-identity,frame-displacement` | **唯一一处"绿"** | `:474` `PTS_N1=NECESSARY … criteria-satisfied=…`（本腿不再自行发绿，绿改由循环后闸裁定） | **变**：必要件齐不再单独发绿 | **收紧**（`F-3` 假绿形态的正面手术） |
| ⑤ | `487` `ENFE-UNHANDLED total=…` | 该行 | `:574` 同句 ＋ `log=${_elog}`／`log_sha16=${_esha}` | 变：**加绑定**（读数必带日志＋`sha16`） | **收紧**（`F-2`） |
| ⑥ | `488` `PTS_ENFE=FAIL …` | 该判词行 | `:575` 同句 ＋ `log=`／`log_sha16=` | 同上 | **收紧** |
| ⑦ | `491` `PTS_ENFE=PASS …` | 该判词行 | `:578` 同句 ＋ `log=`／`log_sha16=` | 同上 | **收紧** |
| ⑧ | `494` `PTS_ENFE=INFO …`（degraded） | 该判词行 | `:581` 同句 ＋ `log=`／`log_sha16=` ＋ 尾句「引用必须连 `log` ＋ `log_sha16` 一起引」 | 同上 | **收紧** |
| ⑨ | `659` `rz c15 PASS …` | 自测期望 | `:747` `rz c15 FAIL …` | 见 §1 | **收紧** |
| ⑩ | `663` `rz c16 NOINFO …` | 自测期望 | `:752` `rz c16 FAIL …` | 见 §1 | **收紧** |
| ⑪ | `695` `chk PASS … "realized·ENFE 全在 allowlist ⇒ 本条不红"` | 自测期望 | `:785` `chk FAIL …（但无 N1 正证据 ⇒ 整步红）` | 见 §1 | **收紧** |
| ⑫ | `726` 断言串 `∈{1a76488aa4a790b3}` | 断言字面 | `:816` `∈{1a76488aa4a790b3,ef3fd6765f18f51b}` | 见 §1 | **收紧** |
| ⑬ | `734` `chk PASS … "realized·帧∉集∧位移>0 ⇒ 不因该条红"` | 自测期望 | `:825` `chk FAIL …"**但只有必要件** ⇒ 必红"` | 见 §1 | **收紧** |

**结论**：13 处删除中 **0 处删掉判据、阈值或三态语义**；分类＝①集合加成员 1 处／②注释 1 处（原句保留）／③④判词行 2 处（1 加字段、1 把绿改必要）／⑤–⑧ ENFE 判词行 4 处（加绑定位）／⑨–⑬ 自测期望或断言 5 处。
**附带风险已查（删字符串的机读消费者）**：仓内现取 `grep -rn --exclude-dir=.git 'PTS_N1'` ⇒ 命中只在 `.md` 报告、`evidence/**` 的 `.env`／`.txt`、`team.json`／`inbox/*.jsonl`，**无任何 `.sh`／`.py` 工具**依赖旧字面 `PTS_N1=PASS` ⇒ 删该字面**不打断机读契约**（旧报告里的旧字面按只增不改纪律保留）。

---

## §3 新增 11 条断言 —— 逐条 + 可证伪性判（含"把机制拆掉"的实证）

**证伪工具**：`~/wv88y/t139/mirror/build/MilBridge/tools/new-nogate.sh` ＝ 现行守卫**逐字**删掉整段新闸（第 `481`–`534` 行，54 行，内容锚定位：`/^  # ── ⏪ \`t136\`…正证据闸 ＋ …例外支/` ⇒ `/^  # G10 native 台账/`），其余一字不动。其 `--selftest` ⇒ **`FAIL pass=56 fail=10`**，10 条 ✗ 为：`§1` 那 4 条旧期望 ＋（新 11 条中）`t136·只有必要件 ⇒ 必红`、`t136·缺正证据点名`、`t136·例外支点名`、`t136·同夹具无例外声明 ⇒ 必红（因果对）`、`t136·anchor 点名`、`t136·n4 点名(含 differ)`。

| # | 断言（新件行） | 拆掉机制后 | 判 |
|---|---|---|---|
| 1 | `chk FAIL "$(out "$_o")" "realized·累积集新成员 ⇒ 必红"`（`:861`，`c40`） | **仍 ok**（该夹具的红来自**既有腿级判据** `criterion=frame-identity`，与新闸无关） | **对机制无区分力**；作为"新闸不得洗掉既有红"的**回归位**有效（见 §4 `X1`） |
| 2 | `grep -qF 'sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b}'`（`:862`） | **仍 ok**（该字面出现在腿级 `FAIL` 行里） | 可证伪＝**是**：回退字面成单成员即 ✗（`§1` 实证） |
| 3 | `chk FAIL … "realized·只有必要件 ⇒ 必红"`（`:871`，`c41`） | **✗**（拆掉后该夹具变 `PASS`） | **可证伪 ✓（承重）** |
| 4 | `grep PTS_N1_GATE=FAIL` ∧ `reason=only-necessary-condition-no-positive-evidence` ∧ `grep 'PTS_N1_POS=phase=realized positive=none'`（`:872`） | **✗** | **可证伪 ✓（承重）**；三条件并列 ⇒ 不能靠单一噪声字面蒙过 |
| 5 | `chk PASS … "t136·例外支成立 ⇒ 不红（正极）"`（`:881`，`c42`） | **仍 ok**（无闸时该夹具本来就 `PASS`） | **单独无区分力**；其判据力全在 #6 配对（`t136` 已配 ✓） |
| 6 | `grep -qF 'PTS_N1_GATE=EXCEPTION'`（`:882`） | **✗** | **可证伪 ✓（承重）** |
| 7 | `chk FAIL … "t136·同夹具无例外声明 ⇒ 必红（因果对）"`（`:888`） | **✗** | **可证伪 ✓＋因果对**（同夹具只去声明 ⇒ 红）：直接证伪"声明与判词无关"的读法 |
| 8 | `chk PASS … "t136·内容锚 >0 ⇒ 正证据 anchor"`（`:894`，`c44`） | **仍 ok** | **单独无区分力**；判据力在 #9（另有 §4 `X9`／`X10` 取值两极化实证） |
| 9 | `grep -qF 'positive=anchor(hits=1)'`（`:895`） | **✗** | **可证伪 ✓（承重）** |
| 10 | `chk PASS … "t136·N4 正身份登记匹配 ⇒ 正证据 n4"`（`:904`，`c45`） | **仍 ok** | **单独无区分力**；判据力在 #11（另有 §4 `X8c`／`X8d` 实证） |
| 11 | `grep -qF 'positive=n4,differ'`（`:905`） | **✗** | **可证伪 ✓（承重）** |

**合计**：11 条中 **6 条承重**（拆机制即 ✗）、**5 条不承重但成对/回归**（3 条 `chk PASS` 极性腿各配一条具名 `grep`；`c40` 的 `chk FAIL`＋`grep` 是既有腿级红的回归位）。**无一条是同义反复**（没有"印什么就断言什么"的恒真式）。

---

## §4 三组两极化夹具 ＋ 自设绕过尝试（全部本席自造，仓外，`rc` 现取）

夹具构造：`app_g1.log`（`TAB entry=FsQueryTrackParaList`，令 `G10` 不扰动）＋ `device.txt(X_UP=yes)` ＋ 双腿 `LEG/NAMED/DEV/FRAME`（自写，不抄自测 `mk()`）。新/旧 realized 副本见 §1。

**三组两极化**（每组必须有"另一方面"的对照格）：

| 组 | 正极 | 负极 | 读 |
|---|---|---|---|
| (a) 累积集成员 | `A1`：两腿 `fr_sha=ef3fd6765f18f51b`（**新登记成员**） | `A2`：两腿 `c0ffee1234abcd99`（∉集） | `A1` **修前 `rc=0 PASS` ⇒ 修后 `rc=1 FAIL`**（`criterion=frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b})`，两腿各一条） |
| (b) 只有必要件／正证据 | `A2a`：`A2` ＋ 自造锚行 `neptune-anchor: …` | `A2`：无锚、无 `N4`、两腿同帧 | `A2 FAIL`／`A2a PASS`（`PTS_N1_POS=… positive=anchor(hits=1)`、`PTS_N1_GATE=PASS`）；另 `B3`（两腿 `fr_sha` 不等、无图）⇒ `PASS positive=differ(via=fr-sha-inequality)` |
| (c) `N3` 例外支 | `C1`：`A2` ＋ `PTS_N3_SAME_CONTENT_PROOF=<声明>`（两腿 `ink=480000>0`） | `C1` 无声明／`C6`（两腿 `ink=0`）＋声明／`C6b`（仅一腿 `ink=0`）＋声明 | `C1+声明 PASS`（`PTS_N1_GATE=EXCEPTION`）／`C1 无声明 FAIL`／**`C6 FAIL`／`C6b FAIL`** ⇒ `t136` 写死的「两页都没绘出内容不构成例外」**被实测执行** |

**自设绕过尝试（10 条；`none` 成功造出假绿）**：

| # | 绕过手法 | 结果（现取） | 判 |
|---|---|---|---|
| `X1` | 累积集成员 **＋** 内容锚（能否让新闸 `PASS` 把腿级红"洗掉"） | `rc=1 FAIL`；`PTS_N1_GATE=PASS` 与 `fails=leg24-n1-frame-unestablished(…),leg23-n1-frame-unestablished(…)` **并存** | **洗不掉** ✓（新闸只加红，不消红：`GATE=PASS` 不进 `fails`／不减既有 `fails`） |
| `X1b` | 累积集成员 **＋** 例外声明 | `rc=1 FAIL`（`GATE=EXCEPTION` 亦不能消腿级红） | ✓ |
| `X3` | **整条 `leg_23.env` 缺失** | `rc=1 FAIL`；`PTS_N1_GATE=FAIL … sha23=none …`；`cannot=leg23(env-absent)`、`legs=1/1` | 不假绿 ✓；但 **理由误标**（`F-1`） |
| `X4` | 两图**同一张**（`shots/g1/k23.png`＝`k24.png`＝在册 `k23.png`）＋两腿 `fr_sha` 记**不同**值 | `rc=1 FAIL`；`positive=none … differ=0 via=compare` | **关键否证**：`compare` 实测优先，**不从"两腿 `fr_sha` 不等"反推两页真不同** ✓ |
| `X5` | 两图**真不同**（在册 `k23.png`＋`boot.png`）＋两腿 `fr_sha` 记**相等**值 | `rc=0 PASS`；`positive=differ(via=compare)` | 内容面真实生效 ✓ |
| `X6` | `PTS_N4_POSITIVE_FP` 值**不匹配** | `rc=1 FAIL`；`n4=deadbeefdeadbeef,c0ffee1234abcd99 … n4_unregistered=1`、`positive=none` | ✓ |
| `X7` | `PTS_N4_POSITIVE_FP='c0ffee1234abcd99,c0ffee1234abcd99'`（逐位匹配） | `rc=0 PASS`；`positive=n4` | 登记路径**可操作** ✓（注意它是自声明 env，见 §8 `O-2`） |
| `X8c` | 同 `X4` 夹具 ＋ `N4` 串**顺序颠倒**（`0a0b…,1213…`） | `rc=1 FAIL`；`n4_unregistered=1`、`positive=none` | 登记是**逐字＋固定顺序**比较 ✓（`X8d` 正序 ⇒ `PASS positive=n4`） |
| `X9` | **锚 regex 现设**命中日志里别的东西：`PTS_CONTENT_ANCHOR_RE='TAB entry'`（命中夹具自身那条 `G10` 行） | `rc=0 PASS`；`positive=anchor(hits=1)` | **唯一的旋钮式绿路**（如实点名，`O-2`）；相对修前**不新增绿面** ⇒ 不算放松 |
| `X10` | `PTS_CONTENT_ANCHOR_RE` 设为不命中 | `rc=1 FAIL`、`positive=none` | 取值敏感 ✓（证明锚是真 grep，不是恒真） |
| `Y1` | **派单点名反极①**：「**只给 `AE(k23,k24)>0` 而不给真内容**」——两腿 `ink=0`（`LEG … ink=0`）＋两张 PNG **真不同**（`compare` AE>0） | `rc=1 FAIL`；`PTS_N1_POS=… positive=differ(via=compare) differ=1`、`PTS_N1_GATE=PASS`，但 `fails=leg24-no-real-ink(ink=0),leg23-no-real-ink(ink=0)` | **造不出整步绿** ✓（`ink=0` 由既有腿级判据点红）；但 `GATE=PASS` 本身**不含"真画出来了"的语义**，如实点名（§8 `O-7`） |
| `Y2b` | **派单点名反极②**：「**让正证据闸在 `degraded` 期泄漏进 `rc`**」——真干净 degraded 夹具（两腿 `magenta=54454/49864` ＋ 具名行 `err=-10000` ＋ `ink=480000`） | 修前 `rc=0 PASS`／修后 `rc=0 PASS`；修后输出里 **`PTS_N1_GATE`／`PTS_N1_POS` 命中 0 行**，只有两条 `PTS_N1=INFO … phase=degraded` | **无泄漏** ✓（`degraded` 期的 `rc` 与本笔前逐字同级：`fails=- cannot=- diag=-`） |

**④ 结论**：**12 条绕过全部失败**（无一条造出"修前红、修后绿"或"新闸洗掉既有红"）；派单点名的两条反极（`Y1`／`Y2b`）也**都没能拿到绿**。

---

## §5 不变量五格（逐格现取）

1. **`--selftest`**：现行件 **`PTS_GUARD_SELFTEST=PASS pass=66 fail=0`**（`~/wv88y/t139/selftest-new.log` 末行，`rc=0`，本席经 `heavy-slot` 现跑）；修前件 **`PASS pass=55 fail=0`**（`selftest-old.log`）⇒ `66 = 55 + 11` **算术相符**。另两副本：期望回退 **`FAIL pass=60 fail=6`**、闸删 **`FAIL pass=56 fail=10`**（§1／§3）。
2. **degraded 真树修前/修后**（同一在册证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence`，读数绑定时：`leg_23.env=285913567aad8516`、`leg_24.env=f89dac2796faa25d`、`app_g1.log=84db0eb62d15e0b2`、`device.txt=6d2cf7572e7323b7`、`shots/g1/k23.png=k24.png=ef3fd6765f18f51b`；`mtime 2026-09-29 14:12`）：
   - `rc` **两侧同为 `1`**；**判词行逐字节相同**：`PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=degraded`。
   - ⚠️ **全文并非逐字节相同**（`diff` 现取 3 行差异，均为本笔**有意**变更、**不进 `rc`**）：① 两条 `PTS_N1=INFO` 行的 `in_empty_set=no ⇒ yes` 与 `set={1a76488aa4a790b3} ⇒ set={1a76488aa4a790b3,ef3fd6765f18f51b}`（累积登记的可见后果）；② 一条 `PTS_ENFE=INFO` 行加 `log=build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log log_sha16=84db0eb62d15e0b2` ＋尾句。**按"判词（verdict）逐字节相同"读＝成立；按"整份 stdout 逐字节相同"读＝不成立**，如实两读并记。
   - **修前/修后 realized 真树**：修前 `rc=0 PTS_GUARD=PASS legs=2/2 fails=-`；修后 `rc=1 PTS_GUARD=FAIL`（两腿 `criterion=frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b})` ＋ 新闸 `reason=only-necessary-condition-no-positive-evidence`）⇒ **收紧在真树上落地**，且 `PTS_N1_POS=… anchor_hits=0 differ=0 via=compare n4=absent` ⇒ `t136` 自陈「今天三源一个都不在场」**成立**。
3. **相位仍 `degraded`**：`build/MilBridge/tools/pts-pages-guard.sh:51` 现取整行 `# PTS-DIRECTION: absent="magenta=0" present-floor=20000 red-when="magenta=0 AND no-named-line AND native_gap=0" source=TASK-0741 phase=degraded` ⇒ 未翻转 ✓（真树 degraded 判词仍 `phase=degraded`）。**另测"闸是否从 `degraded` 泄漏进 `rc`"**：真干净 degraded 夹具（`fx/Y2b`）修前 `rc=0 PASS`／修后 `rc=0 PASS`，修后输出 `PTS_N1_GATE`／`PTS_N1_POS` 命中 **0 行** ⇒ 本笔对 `degraded` 期语义**零改动**（§4 `Y2b`）。
4. **`FRAME_EMPTY_SET` 两成员累积 ＋ 逐枚溯源**（`P1-guard-n1-tighten` 契约）：值 `:98` ＝ `1a76488aa4a790b3,ef3fd6765f18f51b`（**2 枚**，`set={` 输出实测两枚）：
   - 成员 `ef3fd6765f18f51b`：**可在仓内复现** ✓ —— `git show HEAD:build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/k23.png | sha256sum` ＝ `ef3fd6765f18f51b`（`189716 B`，与 `k24/last` 同值），且两腿 `FRAME` 行同值 ⇒ 出处（`t119` 那趟 00:52 代照进在册证据）**可核**。
   - 成员 `1a76488aa4a790b3`：**出处今天不可复现**（该路径现势 ＝ 另一枚；且该路径可达史 6 版 `057d08a/28b04be/f1aedbe/e528f53/ac29ff1/b47cf09` **均非** `1a76…`）⇒ **NOINFO 半格**（§7 `N-1`）；其值的真实载体在本席车道外：`~/t119-runner/bak/run-N3-runner-shots/g1/k23.png`（本席自算 sha16 ＝ `1a76488aa4a790b3`，`189742 B`）。
   - 作废纪律写死 ✓（件内 `:92-96` 段：「只有拿到 `N4` 正身份或内容锚正证据才准移出」＋ 依据 `t120` 现取的假绿形态）；`t124` 段"旧登记作废"原句**一字未删**、以新段为准 ✓（只增不改纪律）。
5. **`PTS_ENFE=` 必带 `log=` ＋ `log_sha16=`** ✓：degraded 实测 `PTS_ENFE=INFO … phase=degraded log=build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log log_sha16=84db0eb62d15e0b2`；realized 实测 `PTS_ENFE=PASS total=0 … log=… log_sha16=84db0eb62d15e0b2`。`84db0eb62d15e0b2` ＝ **本席自算** `sha256sum evidence/app_g1.log | cut -c1-16`（同值）⇒ 绑定位真、可复算。

---

## §6 推翻的话

**`none`** —— 我未能推翻「方向只有收紧」：§1／§4 的 5 组成对读数与 **12 条**自设绕过（含派单点名的两条反极 `Y1`「只给 `AE>0` 不给真内容」／`Y2b`「闸泄漏进 `degraded` 的 `rc`」）**全部**指向同一方向（修前绿/NOINFO ⇒ 修后红；新闸不消既有红；三源取值两极化都对判词有效）；反向证据（"某处被放松"）**一格都没找到**。我**只**找到 §8 那些 **不改变任何 verdict、也不放松任何既有要件** 的本笔新增缺陷/观察。
（若下一位拿到的读数与 §1／§5 不同 ⇒ 先查证据件的 `mtime`／`sha16` 是否与 §5 绑定值不同趟。）

## §7 NOINFO 名单（具名；既不算绿也不算红）

- **`N-1`** 成员 `1a76488aa4a790b3` 的**逐枚溯源**：件内出处路径今天不可复现（现势＝另一枚；可达史 6 版均非它）⇒ 该半格 **NOINFO**（值本身有仓外载体，见 §5.4）。
- **`N-2`** 新闸的 `PTS_N1_GATE=NOINFO reason=necessary-input-missing(…)` 路由：**本席未能在任何实测里命中** —— 缺整条 `leg_23.env` 走的是 `cannot=leg23(env-absent)` 后**直接进闸的 FAIL 支**（§4 `X3`），`N1_NECMISS` 只在"腿件在、`fr_sha` 空或 `-`"时置位 ⇒ 该路由今天**只有注释声明、无实测命中** ⇒ 我无法判它"在场"。
- **`N-3`** 正证据源 (a) `PTS_N4_POSITIVE_FP` 的**真值**（该页专属正身份）：判据件自陈今天无载体 ⇒ 真树上不可达（我只能用 `c45`／`X7`／`X8d` 的**自造登记值**证明机制可操作）。
- **`N-4`** `t136` 自陈的「现取真腿 `log=`／`log_sha16=`」一类的**第三方原始日志**（如 `t119` 车道 `bak/run-N3-app_g1.log`）：本席只按需要现取，未逐份复跑 ⇒ 与 `t119`／`t120` 数字的一致性**不列为本件判词**。

## §8 本笔新引入的问题（本件**不修**；点名 `file:line` ＋ 机制 ＋ 为什么是缺陷）

- **`F-1`（medium，本笔新引入；**不放松、不改变任何 verdict**）**：新闸的 `FAIL` 支**没有"必要件是否真的成立"这一前置**，因此会在**必要件本身不成立**的场合照样印 `reason=only-necessary-condition-no-positive-evidence` 并把该条塞进 `fails=`。
  - **载体**：`build/MilBridge/tools/pts-pages-guard.sh:529-533`（`N1-ONLY-NECESSARY`／`PTS_N1_GATE=FAIL`／`fails+=("n1-only-necessary-condition-no-positive-evidence(…")`）；契约文本在同件 `:492-494`（写死「**两腿必要件齐**（`N1_SHA_*` 可用、均 ∉ 参照集、`fr_ae_boot>0`）∧ 正证据为空 ∧ 例外不成立 ⇒ 红」）—— **实现比写死的契约弱**（只查 `fr_sha` 非空）。
  - **两处实测**：① **真树 realized**（§5.2）：两腿 `in_empty_set=yes`（要件①**不成立**），`fails=` 里仍多出 `n1-only-necessary-condition-no-positive-evidence(sha23=ef3fd6765f18f51b,sha24=ef3fd6765f18f51b,anchor=0,n4=absent)`；② **`X3`**（缺整条腿件）：闸不从 `NOINFO(necessary-input-missing)` 走，改印 `PTS_N1_GATE=FAIL … sha23=none … reason=only-necessary-condition-no-positive-evidence`，而该腿的必要件是**未知**、不是"成立"。
  - **为什么是缺陷**：这是**机读理由与事实相反**的判词面缺陷（`fails=` 是给门禁/下一位读的）。它**不放松任何既有要件**（红仍是红、且既有腿级红仍在），因此**不触发 `needs_revision`**；但下一位若按该 `reason` 反推"必要件已齐、只缺正证据"，会读出一个**不成立的中间状态**。修法建议（下一波，属判词面小改）：把"必要件成立"做成 per-leg 位（只在 `:474` 的 `NECESSARY` 分支置位）并作为闸 `FAIL` 支的前置，否则改印 `NOINFO/DIAG reason=necessary-not-satisfied`。
- **`F-2`（medium，残留口径相反，本笔点名并只修了一半）**：同一 ENFE 口径在仓内**两处相反**：`pts-pages-guard.sh:550` 与 `:1018` 仍写「与 `[HC-UNHANDLED]` 行**同源** —— 现取：二者计数相等」，而本笔在判据件侧已 dated 更正为「两个量**各自**定义、**不得互相折算**」（`P1-realized-criteria-report.md:208` 的 `O-1`），现取实况也**不相等**（`PTS_ENFE=INFO total=0` vs `[HC-UNHANDLED]` 族 1123 条，本席 14:2x 现取）。**为什么是缺陷**：本线自己的纪律是"口径文本必须在**判据件自身**在场"，两处相反 ⇒ 下一位按守卫那句去判"二者相等"会把 1123 条 `PtsException` 读成 ENFE 红（或反之把 ENFE=0 读成"异常面干净"）。**注意**：该句是 `t122` 代原文、`t136` 只改了判据件那一处 ⇒ 属"本笔没改完"而非放松；且 `docs/ROUTES.md`／`silent-hit-v2-check.sh` 现取都**没有**把该等式接成判据（`HC-UNHANDLED` 在守卫里只出现在注释与自测夹具）⇒ **无执行面判据被改**。
- **`O-1`（low，注释与行为不符，本笔新引入）**：`pts-pages-guard.sh:496` 写「**`degraded` 期**：本闸**不参与**（只印 `PTS_N1_POS=` 由 `INFO` 行带出）」，但 `PTS_N1_POS` 的 `echo` 在该件 `:498` 的 `if [ "$PHASE" = realized ]` **块内** ⇒ degraded 期实测 **`PTS_N1_POS` 命中 0 行**（本席 `A1` degraded 实测；真树 degraded 输出同样无此行）。
- **`O-2`（low，观察；非放松）**：正证据三源中 **(a)(b) 的取值可由跑者现设**，且判据件只登记了 `PTS_CONTENT_ANCHOR_RE` 的**默认值** `[Nn]eptune`（今天真树命中 0）：`X9` 实证 `PTS_CONTENT_ANCHOR_RE='TAB entry'` 能命中日志里夹具自身的 `G10` 行 ⇒ 闸 `PASS positive=anchor(hits=1)`。相对修前**不新增任何绿面**（同夹具修前也绿），故**不算放松**；建议下一波把三源的**合法取值/登记处**写进判据件（或对未登记的 env 覆盖判 `NOINFO`）。
- **`O-3`（low，观察）**：`N4` 登记串是**逐字＋固定顺序**（`k23,k24`）比较（`X8c` 颠倒 ⇒ `n4_unregistered=1`）⇒ 登记写法必须照抄腿序；判据件 `:203` 已把写法写成 `<k23 sha16>,<k24 sha16>` ✓，但未注明"顺序敏感"，建议补一句。
- **`O-4`（low，pre-`t136` 行，只报不改）**：`P1-realized-criteria-report.md:181` 把「`k23=k24=last=1a76488aa4a790b3`」与「各 `189716 B`」写在一起，但同 sha 的存活字节（车道 `t119` 帧，本席自算）是 **`189742 B`**，而 `189716 B` 恰是**另一枚**（`ef3f…`）代的尺寸（`git show HEAD:…` 复核）⇒ **同 sha 不可能两尺寸** ⇒ 该行数字为**误记**（与本笔方向无关；本笔的 dated 段 ② 未重复该尺寸 ✓）。
- **`O-5`（low，观察）**：拆掉整段新闸后仍全绿的三条 `chk PASS` 极性腿（`c42`／`c44`／`c45`，§3 #5/#8/#10）**自身无区分力**，判据力全在配对 `grep`（本笔三条都配了 ✓）⇒ 建议后续新极性腿一律"极性腿＋具名 `grep`"成对提交（本笔已合规）。
- **`O-7`（low，观察；直接回答派单点名的反极①）**：正证据源 (c) `differ` **只证明"两页帧不同"，不证明"画出了内容"** ⇒ `PTS_N1_GATE=PASS` 可与 `fails=…no-real-ink(ink=0)` 并存（`Y1` 实测）。因此 `GATE=PASS` 行的文案「正证据在场 ⇒ 必要件之上**重新**成立」**不得**被读成"排版成立／内容已绘出"。**不构成假绿**：`realized` 期只要两腿 `ink` 不为 `>0`（`ink=0` 或缺失）就另有腿级红（`no-real-ink`／`no-real-layout-evidence`）⇒ 整步进不了绿；故**非放松**，仅需在下一波把这个语义边界写进判据件（建议 `GATE=PASS` 行补 `content_evidence=no` 之类标记）。
- **`O-6`（low，观察／登记面空洞，pre-`t136`）**：`[HC-UNHANDLED]` 族（今天 1123 条、内容为 `PtsException: … Error code: '-10000'`）现取**没有任何判据绑定**（守卫 `ENFE_TOTAL` 只数 `entry point named '<名>'` 行；`silent-hit-v2-check.sh` 只在注释里提到它）⇒ `O-1` 那句等式撤下后，该族在判据面**无人看守**；本席只登记，建议下一波明确"补一条判据或明确豁免"。

---

## §9 证据在册（本席车道；仓内只读）

- 本件：`build/MilBridge/P1-guard-tighten-verify.md`（**全文 sha16 与行数写在件外的回执里**——写进件内会改变自身哈希；件内只放末行自证＝`head -n -1` 口径）。
- 车道（仓外）：`~/wv88y/t139/guard.diff`（`aea0481→443c5f9` 的 `-U3` diff，270 行）、`old-guard.sh`（修前件现取副本 `e74ec5c2f6a87f0f`）、`mirror/build/MilBridge/tools/{old-guard,old-realized,new-realized,new-nogate,new-reverted}.sh`（相位位/机制拆解副本）、`selftest-{new,old,nogate,reverted}.log`、`fx-full.log`（全部 `rc` 与判词原文）、`fx-summary.log`、`real-{new,old}-{degraded,realized}.log`、夹具脚本 `fx.sh`／`fx2.sh`／`fx3.sh`／`fx4.sh`／`fx5.sh`（夹具本体跑完已删，读数留在 `fx-full.log`／`fx-summary.log`）。
- 复核手段一律只读：`git show`／`git ls-files`／`git log -- <path>`／`sha256sum`／`grep`／`diff`／`sed`／`ImageMagick compare`（经守卫内部）＋ `heavy-slot`（`selftest` 两趟）。
- 本件未改任何仓内产品件/文档件；未跑 `dotnet build`／`verify-all`／`close-wave`；未起腿、未占显示槽。

**本件自证（落盘后）**：`head -n -1 build/MilBridge/P1-guard-tighten-verify.md | sha256sum | cut -c1-16` ＝ 208d3a7a7c721452（末行不计入自身；末行＝本行；口径与仓内各件一致）
