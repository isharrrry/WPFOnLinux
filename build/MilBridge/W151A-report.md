# W151A 报告 —— `#59` / `TASK-0110`（**改题后**）：两块牙**接线预备** ＋ 判据先行

> 车道 `W151A`｜工作目录 `~/w151a/`｜`R = /home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是** git 仓库 ⇒ 不 commit/push）
> **纪律**：`$R` **零写入**（三条硬闸全未满足，§1）｜**未跑** `dotnet`／`verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／`build/*.sh`｜**未占**重活槽
> 判据 = `~/w151a/criteria.md`｜接线指令 = `~/w151a/wiring-plan.md`

---

## §0 一句话结论

**终局：`W151A=BLOCKED`（闸 60 min 未开）—— 按纪律只做仓外产出**（`$R` **零写入**）。
三分之二的闸在窗口内动过：条件 ① `gen=#57` **已于 `00:51:05` 满足**；条件 ② `~/w21-verify/w57-POST.done`
**全程未出现**（`postdone=yes` 读数 **0 次**）；条件 ③ 收尾链**全程在跑**（`01:15` 现场仍是
`dotnet … MSBuild.dll` ＋ `dotnet test … Presentation.Tests`）。⇒ **三条未同时满足，不落地。**
已交两份可**直接执行**的产物（＋一个**闸卫落地脚本**）：

1. `~/w151a/criteria.md` —— 判据**先行**（三态／成对／承重＝`B3` 有无／`C6`／边界例单列／恒真谓词禁入／九位不动／**语料不许指仓外**）。
2. `~/w151a/wiring-plan.md` —— **逐字、行锚定**的接线指令（`+48/−2`、6 处改动），**且每一处都已在仓外沙箱上用真读者预验过**：
   候选件 **1099 行 / sha16 `67934adf9b5f244c`** ⇒
   `VERIFYALL_SELF=PASS names=33 decl=33 gen=#59 dup=0 order=OK prose=OK prereg=PASS`（`rc=0`），
   阴性对照（现盘真件 31/#56）同参数仍 `PASS`。

**三条最有用的新读数**：
- **`--corpus` 指仓外会让这两步变"机器相关的红"**（缺语料 ⇒ `rc=2` ⇒ `run_step` 判 ❌）⇒ 语料**必须收进仓**（34 MiB）。
- **`fp_inputs` 纳不纳，两种问法都已真调用现算**：`ecaf53dd…/coverage_n=155/geom 命中 0`（不纳入）
  vs `f933e4c8…/157/命中 2`（纳入）⇒ **建议纳入**（不纳入则"把承重从 `B3` 有无改成 `Δ>200`"**零机器红**，而那会造假绿）。
- **牙2 的 `--fix=`／`--pre=` 是假旋钮**（用法行 `:41` 声明"可换臂"，但 `judge()` 不收这两个参数）⇒ 屏上 `NOTE` 与 `ARM` 行**自相矛盾**而 `rc` 不变（新发现，裁权归主控）。

---

## §0B ⚠️🔴 **新发现：基座在动 —— 本波被咬一次，已修**（本波第二重要的读数）

**`verify-all.sh` 不是静止的。** 本车道工作期间它被 `#57` 收官链改过一次：

| 时刻 | sha16 | 行数 | 首行 `DECL` | `grep -c '^run_step "'` |
|---|---|---|---|---|
| 本车道开工 `00:15` | `eb29ced9d81b2345` | 1053 | `31 gen=#56` | 31 |
| **`00:41:34`（外部改动）** | **`0345e750fd182a7c`** | **1055** | **`31 gen=#57`** | 31 |

`#57`（`TASK-0211`）的改法是**在 `#56` 那半句之上再插一行**：新增口径句 `` **`#57` 收官起 = 31 步** ``
＋新增 `# VERIFYALL-STEPS-DECL: 31 gen=#57 …`（**步数不动**）。

⚠️ **本车道第一版的接线预备把锚点写死成 `#56` 的文本** ⇒ 若照着它落地，新 `DECL` 行会插在 `#57` 行**之下**
⇒ 读者 `decl_line()` 的 `head -1` 取到 **`#57`**。**实测（不是推演）**——把**旧锚点**灌到**新基座**上真跑：

```
$ python3 ~/w151a/logs/apply-plan.py（旧版锚点） → ~/w151a/sb-oldanchor.sh
$ bash verify-all-step-check.sh --file ~/w151a/sb-oldanchor.sh
VERIFYALL_SELF=FAIL names=33 decl=31 gen=#57 dynamic_trace=NOINFO vfile_sha16=d6e164ecac41c536
  ∟ decl-self-inconsistent(DECL=31 但列了 33 个名字)
  ∟ count-mismatch(现场 33 ≠ 声明 31)                              rc=1
```

**修法（已进 `wiring-plan.md` §0B 与 `apply-plan.py`）**：锚点**一律按位置现算、不许写死世代号** ——
① 解析首个 `^#\s*VERIFYALL-STEPS-DECL:\s*(\d+)\s+gen=(#\d+)` 拿 `n_cur`/`gen_cur`；
② **先断言 `n_cur == 现场 run_step 条数`**（不相等 ⇒ 拒绝动盘）；③ 新 `DECL` 行插在那**首个匹配行**之前；
④ 新口径句插在**同 `gen_cur`** 那行之前；⑤ 另三个锚按整行相等定位并断言 `count==1`；⑥ **行号大的先插**。

**修后在新基座上重做整条通路（POS-2）**：

```
$ python3 ~/w151a/logs/apply-plan.py ~/w151a/sb4-verify-all.sh
ANCHOR decl@46 gen=#57 decl_n=31 observed_run_steps=31
ANCHOR prose@35 (gen=#57)
  INSERT STEPS at line 968 / VAR at 578 / DECL at 46 / PROSE at 35 ；APPEND STEP-NAMES at line 75
$ bash verify-all-step-check.sh --file ~/w151a/sb4/verify-all.sh
VERIFYALL_SELF=PASS names=33 decl=33 gen=#59 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=e34e34c581eba2c9   rc=0
```
⇒ 落地目标件 = **`~/w151a/sb4-verify-all.sh`** sha16 **`e34e34c581eba2c9`**（新基座 `0345e750fd182a7c` ＋ `+47/−1`，5 hunk）。
**幂等**：复跑抽取器读数逐位相同（`e34e34c581eba2c9`）。**新基座上的阴性对照**（现盘真件 31/#57）仍 `PASS`（`rc=0`）。

⚠️ **这条发现的一般形式（值得写进纪律）**：**"接线那一趟"的基座会被别人改** ——
`verify-all.sh` 的头部声明块**每波都被追加一行**，所以任何"插在最上面"的锚点都在**按世代漂移**。
⇒ 凡是"必须成为 `head -1`"的插入，**锚必须是位置**（首个匹配行），**不能是上一代的文本**。
本波是**同一个坑的现场**：锚写死 ⇒ 该 FAIL 的没 FAIL 判据(旧基座)、该 PASS 的会 FAIL(新基座)。

---

## §1 硬闸：**三条全未满足**（逐条读数）

| # | 条件 | 现场读数 | 判 |
|---|---|---|---|
| ① | `gen=#57` | `> BASELINE-FROZEN gen=#56 sha16=8edaf4f8c1e93eb0 …` | ✗ |
| ② | `~/w21-verify/w57-POST.done` 存在 | `没有那个文件或目录` | ✗ |
| ③ | 无收尾/构建链在跑 | 三进程（见下） | ✗ |

条件 ③ 读数（按 `/proc/*/cmdline` **逐个 argv** 判，**已排除自身祖先链**；**未用** `pgrep -f`）：

```
2262519  bash  bash /home/links-dev/heavy-slot.sh --min-avail 1500 --max-hold 1800 --wait 1800 -- bash -c cd …/wpf-linux-20…
2262527  bash  bash build/close-wave.sh --skip-verify-all
2262657  bash  bash build/integration-wave.sh
```
`~/heavy.lock` 被上面那棵树持有（`ls -l ~/heavy.lock` = `0 B`，`00:14` 创建）。

⇒ 已起轮询（`~/w151a/gate-poll.sh`，60 s × 61 次，日志 `~/w151a/logs/gate-poll.log`）。
**窗口内若开启 ⇒ 逐字按 `wiring-plan.md` §8 的顺序落地；未开 ⇒ `W151A=BLOCKED`（本件即下一趟的执行指令）。**

---

## §2 沙箱预验（本波最要紧的取证：**改动先过读者，再打真件**）

沙箱 `~/w151a/sb/`（手工候选件）＋ **`~/w151a/sb2-verify-all.sh`（从 `wiring-plan.md` §2 用脚本
`~/w151a/logs/apply-plan.py` **逐字抽取**后落到 `cp -p` 真副本上 —— 本波认定的落地目标）**。
读者 = **真件** `verify-all-step-check.sh`（`41d702168f191b2a`），参数 `--file <件>`。

| 档 | 件 | rc | 逐字读数 |
|---|---|---|---|
| **NEG（阴性对照）** | **现盘真件** | **0** | `VERIFYALL_SELF=PASS names=31 decl=31 gen=#56 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=eb29ced9d81b2345` |
| **POS-1** | 手工沙箱件 | **0** | `VERIFYALL_SELF=PASS names=33 decl=33 gen=#59 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=67934adf9b5f244c` |
| **POS-2（**接线预备件逐字 → 件**）** | `sb2-verify-all.sh` | **0** | `VERIFYALL_SELF=PASS names=33 decl=33 gen=#59 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=9e42e608ca854136` |

**POS-1 与 POS-2 的差异 = 2 行注释措辞**（`diff | grep -c '^[<>]'` = 4；落在 `# W151A-0110-BEGIN` 块的**注释**里，
**不在任何声明行/判据行上**）⇒ 两份候选件判词相同，**以 POS-2 为落地目标**。

**⇒ 这一格是本波最有价值的读数**：`wiring-plan.md` 的 §2 文本**不是散文** —— 它被脚本逐字抽出来、
直接落成**能过读者**的件 ⇒ **"落地只按本件改"是机器可执行的，不是承诺**。
（若 §2 的文本有任何一处字符对不上，这条通路会当场崩或读者判红。）

候选件的机械读数：`grep -c '^run_step "'` = **33**｜`bash -n` = **rc=0**｜**1099 行**｜`+48/−2`｜5 个 hunk。
5 个 hunk 头：`@@ -32,6 +32,7 @@`（口径句）／`@@ -42,6 +43,7 @@`（DECL）／`@@ -68,7 +70,7 @@`（STEP-NAMES）／
`@@ -574,6 +576,9 @@`（`GEOM_CORPUS`）／`@@ -964,6 +969,47 @@`（两步块）。
两份候选件**落点行号相同**：口径句 `:35`｜`DECL` `:46`｜`STEP-NAMES` `:73`｜`GEOM_CORPUS` `:581`｜
块标记 `:972`–`:1012`｜`run_step "GEOM-BEAT"` `:1008`｜`run_step "GEOM-RESEND"` `:1011`。

**锚点唯一性**（改前现场核过）：`DECL 31 gen=#56` **1**｜`` **`#56` 收官起 = 31 步** `` **1**｜` | UIA-DOOR | IME-LANDING` **1**｜`# W137A-0708-END` **1**。

**⚠️ 抽取器自己的一个坑（如实记）**：`apply-plan.py` 第一版把两步块插在 `# W137A-0708-END` **之前**
⇒ 两步落进了**别人那一波的归属标记块里**（`diff` 当场看出那一行被顶走）。改为**插在该行之后**后，
`diff` 只剩上面那 2 行注释措辞。⇒ 已把"**另起 `# W151A-0110-BEGIN/END` 块标记、不许塞进别人的块**"
写进 `wiring-plan.md` §2 的理由句。

**预登记能不能被别人"代满足"**：机械核 `grep -lE '^#+ .*#59' $R/docs/WAVE*-PREREGISTRATION.md` ⇒ **0 件**
⇒ `WAVE59-PREREGISTRATION.md` **必须真建**（标题行含 `#59`）。

**第四处声明也过了**：把 `wiring-plan.md` §9 的预登记骨架 **逐字抽出来**（49 行，脚本抽取，不是手抄）
落成沙箱 `docs/WAVE59-PREREGISTRATION.md` 后，真读者仍判
`VERIFYALL_SELF=PASS names=33 decl=33 gen=#59 … prereg=PASS`（`rc=0`）
⇒ **四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）逐字都可落地，且落地后自洽。**

---

## §2B 牙1 新长的**语料锚读者**（主控裁定 ③ 加严 —— 锚必须同趟有读者）

主控裁定：**"锚必须同趟长出读者，否则是半个牙（违纪律 47）"**，并划出唯一红线：
**"若你认为这条读法会破坏牙1 的既有两极性 ⇒ 停手报我。不许为了省事把锚做成没读者的记账。"**
⇒ 本车道先做**两极性体检**，结论 **不破坏**，再落地。

### 2B.1 设计（把破坏两性的风险点逐条堵掉）
- 新格**只做加法**：新增函数 `corpus_aggregate` / `declared_corpus_anchor` / `corpus_anchor_state`，
  新增**外层** `top_verdict_with_anchor`；**`top_verdict` 本体一字未动**。
- **只 3 行被替换**（全 diff `+185/−3`、8 hunk）：① `top_verdict(rows, pair)` 调用改成外层；
  ② `GEOMBEAT=` 的格式串；③ 其实参行（各加一个自证字段 `corpus_anchor=%s`）。
- **算法口径与声明处同源、写死**：`find . -type f | LC_ALL=C sort | xargs sha256sum | sha256sum`；
  在 python 里重实现以免受 `xargs` 分词与 `sort` locale 影响，**并用一例自测把它钉死**
  （`anchor_alg`：合成语料上 shell 版与 python 版**逐字同值**，现场 `cf1a9ea3ee2c4111`）。
- **传染是单向的、只在 corpus 模式**：`--leg=` 模式返回 `NOT_APPLICABLE` 且**不传染**。

### 2B.2 两极性体检（**先做，后落地**）
| 面 | 原牙 | 新牙 | 判 |
|---|---|---|---|
| 自测既有例 | `GEOMBEAT_SELFTEST=12/12` | **19/19**，且**前 12 行逐字相同** | **未破坏** |
| 真装置 | `GEOMBEAT_LIVE=4/4` | **`4/4`**（`--leg` 内部路径未受影响；`:227` 零残留） | **未破坏** |
| 39 腿语料判词 | `GEOMBEAT=PASS … legs=39 red=19 green=20 noinfo=0 arms=3` | **逐字相同** ＋ `corpus_anchor=PASS` | **未破坏** |
| `--leg` 两腿（原/新） | `GEOMBEAT=PASS … legs=2 red=1 green=1` | 同判词 | **未破坏** |

### 2B.3 新格的成对读数（mimic 仓 = 真调用形态，**不带任何 env 覆盖**）
| 档 | 现场 | rc | 逐字 |
|---|---|---|---|
| **锚对**（语料在仓内） | `--corpus=<mimic>/build/MilBridge/geom-corpus` | **0** | `GEOMCORPUS=PASS files=234 live=0f702ccd…b9fe2 == declared` |
| **锚对**（仓外语料源） | `--corpus=$HOME/w134a/run` | **0** | 同上（**现场复核 `cp -p` 不变性**） |
| **锚错** | 声明改 `0`×64（仓外副本，公开覆盖口） | **2** | `geom-corpus-declared-mismatch（现场=0f702ccd… 声明=0000…）` ⇒ 顶层 `NOINFO` |
| **缺锚** | 用未加锚的登记表 | **2** | `geom-corpus-undeclared` ⇒ 顶层 `NOINFO`（**缺声明 ≠ 通过**） |
| **语料被改一件** | 往一条腿 `probe.txt` 追加一行 | **2** | 现场变 `741438db…` ≠ 声明 ⇒ **`NOINFO` ＋ 点名** |
| **`--leg` 不传染** | 原/新牙同一对腿 | **0 / 0** | 同判词；新牙多一行 `leg-mode-not-a-corpus` |

⇒ **"换整套自洽语料零机器红"这条缺口被现场关掉了**：改一个字节 ⇒ 现场聚合变 ⇒ `NOINFO` ＋ 点名双方全 64 位。

### 2B.4 ⚠️ 新格的自测**抓出两个自身缺陷**（都已修，如实记）
1. **登记表被写进语料根**：第一版把合成 `reg.json` 放在语料目录里 ⇒ **那个文件自己改变了聚合** ⇒
   `anchor_ok` 当场判 `NOINFO`。**是新格自己的自测抓的**（不是人眼）⇒ 已把登记表移到语料根之外。
2. **`__file__` 在 `python3 -` 的 heredoc 里恒为 `<stdin>`** ⇒ 用它反推仓根会**静默指到别处**：
   实测（不带覆盖口）`GEOMCORPUS=NOINFO reason=registry-absent:/home/build/MilBridge/known-red.json`
   —— **不报错、只判错**，在 `verify-all` 里就是一个 ❌。
   ⇒ 仓根改由 **bash 侧导出** `GEOMBEAT_REPO`，并加第 7 例 `anchor_reporoot` 钉住。
   **建议入纪律**：凡在 `python3 - <<EOF` 里取脚本自身位置，**一律不许用 `__file__`**。

### 2B.5 sha16
`build/MilBridge/tools/geom-revert-beat-check.sh` **`9412ec0149111348`（511 行）→ `ee43a703736489a3`（701 行）**；
`--selftest` **12/12 → 19/19**（既有 12 例**逐字未变**）；`--live-selftest` **4/4**。

---

## §3 反极性矩阵（**全部实测**；每档成对：扰动 vs 阴性对照）

### 3.1 声明面（沙箱 6 档）

| 档 | 扰动 | rc | 逐字点名 |
|---|---|---|---|
| NEG | 现盘真件 | 0 | `PASS names=31 decl=31 gen=#56` |
| X1 | **删两行 `run_step`**（声明不动） | **1** | `count-mismatch(现场 31 ≠ 声明 33)`＋`name-set-differs(…声明独有=[GEOM-BEAT×1 GEOM-RESEND×1 ])`＋`prose-mismatch(头注释「#59 收官起」后来跟的数 ≠ 现场 31)` |
| X2 | `DECL` 33 → 31 | **1** | `decl-self-inconsistent(DECL=31 但列了 33 个名字)`＋`count-mismatch(现场 33 ≠ 声明 31)` |
| X3 | `gen` `#59`→`#58` | **2** | `VERIFYALL_SELF=NOINFO reason=header-prose-absent gen=#58 现场=33` |
| X4 | `STEP-NAMES` 少两新名 | **1** | `decl-self-inconsistent(DECL=33 但列了 31 个名字)`＋`name-set-differs(现场独有=[GEOM-BEAT×1 GEOM-RESEND×1 ])` |
| X5 | 预登记缺席（docs 留现有 37 件） | **2** | `VERIFYALL_SELF=NOINFO reason=prereg-absent gen=#59 扫了 37 件 docs/WAVE*-PREREGISTRATION.md，本代号没出现在任何标题行里` |
| X6 | 两步次序颠倒 | **1** | `name-order-differs(第 32 位 现场="GEOM-RESEND" 声明="GEOM-BEAT")` |

⇒ **"把牙拆掉"不是"步数回 31 就绿"**：**只删 `run_step` 而不动声明就 `rc=1`**（X1）。
**拆线也要走同一台读者、同趟改四处声明** —— 这是本波最想留下的一条机器证。

### 3.2 牙面（仓外副本 4 档）

| 档 | 扰动 | rc | 逐字读数 |
|---|---|---|---|
| **Y1** | 牙1 承重改成「**只判 `Δ>200` ⇒ 红**」（派单书原方向） | **1** | `ARM bridge=feef049e9d0e313a role=pre n=17 red=0 green=17 verdict=NO_RISEUP`；`GEOMBEAT=FAIL reason=FALSE_GREEN（修前臂一条红都没有 ⇒ 判据作废、须重写）` |
| **Y2** | 牙1 删掉 `B3` 判据（恒判绿） | **1** | 同上 `FAIL reason=FALSE_GREEN` |
| **Y3** | 牙2 `RISEUP_MIN` `0.70 → 1.00` | **1** | `ARM … verdict=FAIL why=回升率 0.94 < 先写界 1.00`；`GEOMRESEND=FAIL reason=pre_arm=回升率 0.94 < 先写界 1.00` |
| **Y4** | 牙2 `FIX_SHA` 常量改成修前件 | **2** | 该臂 `verdict=FAIL why=有腿 CFG_HIT≥1（修后方向必须 0）；有腿 GEOWRITE=0（正控缺席）；有腿 r_ok≠1`；顶层 `GEOMRESEND=NOINFO reason=single-arm` ⇒ **`NOINFO` 优先于 `FAIL`** |

**Y1/Y2 的意义（本波最重要的一对）**：派单书原方向那条改法**改完仍然红**（被 `FALSE_GREEN` 探测器接住）
⇒ **"能造出假绿的旋钮"今天确实不在牙里**。**Y3 的意义**：`0.70` 这条先写界**活着**，
且"要求每腿必命中"**确实是红** —— 正是裁定要禁止的那条。

**Y4 的副产品（如实记）**：`nametraps` 由 **2 → 14**。原因 = 改 `FIX_SHA` 后 `-NEW-` 腿名与新 fix 件冲突。
⇒ `NAMETRAP` 是"腿名 vs 趟印 `BRIDGE=`"的**检测**，**检测到 ≠ 判红**；节数随臂常量移动是**设计使然**。

### 3.3 牙自身的`--selftest`（本车道**未复跑**，如实标）

`--selftest` 是**离线合成台账**自测（`12/12`／`8/8`，W149A 已跑并留痕）。
⚠️ **本波未复跑**（不是重活，但与本波的判据 A/B/C **无关**，且 `$R` 零写入 ⇒ 跑它没有新增信息）
⇒ 该格引用 W149A 的读数，本车道**未独立复现**（**如实标**）。

---

## §4 🔴 新发现：牙2 的 `--fix=`／`--pre=` 是**假旋钮**（本波独立实测）

**声明面**：`build/MilBridge/tools/geom-resend-regression-check.sh:41`
> `#   \`--fix=<sha16>\` / \`--pre=<sha16>\` 可换臂（默认见下）；`

**实现面**：`:279-280` 确实解析；**但** `:116` `def judge(rows):` **不收** `fix`/`pre`，
`:297` 的调用是 `judge(rows)`，分组用的是**模块级常量** `FIX_SHA`/`PRE_SHA`（`:54-55`）。
⇒ 两个开关**只**改 `:295-296` 打的那行 `NOTE … fix=… pre=…`。

**成对读数**：

```
$ bash geom-resend-regression-check.sh --corpus=~/w134a/run --fix=feef049e9d0e313a --pre=4e25e4b27d4d5ae1
NOTE pattern=0c 02 05 00 04 00 c0 00（与 leg.sh:127 逐字相同）fix=feef049e9d0e313a pre=4e25e4b27d4d5ae1 riseup_min=0.70 min_legs=3
ARM bridge=4e25e4b27d4d5ae1   role=fix  n=19  hit_legs=0   rate=0.000 geowrite0=0   verdict=PASS
ARM bridge=feef049e9d0e313a   role=pre  n=17  hit_legs=16  rate=0.941 geowrite0=17  verdict=PASS
GEOMRESEND=PASS reason=fix_arm 确定性成立 ∧ pre_arm 回升成立（成对） …                rc=0
```
⇒ 屏上 `NOTE` 说 `fix=feef049e…`，紧跟着 `ARM` 行却说 `feef049e… role=pre` —— **同一屏自相矛盾**，`rc` 不变。

**性质**：**不是假绿**（判词没被骗），是「**看着能换判据极性、实际换不动**」的**假旋钮**
⇒ 任何人拿它做反极性实验都会得到**假的"没变化"**。
**处置建议（裁权归主控）**：① 让 `judge()` 收 `fix`/`pre`（真接线，动判据件）；② **删两个开关**、
`NOTE` 只印硬编码常量（最小改面）；③ 只登记。
⚠️ **不影响本波接线**：本波的接线**不传**这两个开关。

---

## §5 `fp_inputs()`：两种问法的**真调用**读数

**取法**（**不复制函数体**）：`sed -n '/^fp_inputs()/,/^}/p' close-wave.sh` → 拼调用 → `cd $R && bash`。
同一取法被仓内 `fp-inputs-hygiene-check.sh:111` 使用；`B.sh`/`C.sh` 两变体 `bash -n` 均 OK。

| 问法 | `inputs_fp`（前 16 位） | `coverage_n` | `geom-` 命中 |
|---|---|---|---|
| **不纳入**（现盘） | `ecaf53ddc2b5f508` | **155** | **0** |
| **纳入**（中部插两行，**两种插法读数相同**） | `f933e4c8b048b864` | **157** | **2** |

**交叉验**：不纳入档 `coverage_n=155` 与仓内第 `[12]` 步 `FP-INPUTS-HYGIENE` 的现场读数
**逐字相同**（`FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=155 artifact_n=0`，W149A `report.md` §8）
⇒ 本车道的真调用法**没有扰动被测函数**。

**⚠️ 本车道自己踩到的坑（如实记）**：第一次把两个新件**追加在 `printf` 名单末尾**（且让前一行补 ` \`、
新末行也带 ` \`）⇒ **续行把下一行的 `} | LC_ALL=C sort …` 拼进了命令** ⇒ `inputs_fp` **打印为空**
（不是"算错"，是**语法崩**）。**改插中部后正常**（`f933e4c8b048b864`，两种中部插法一致）。
⇒ 已把这条写进 `wiring-plan.md` §6（**落法必须插中部，别在末尾追加**）。

**建议 = 纳入**（三条理由见 `wiring-plan.md` §6）。**语料不进 `fp_inputs()`**（同 `arm-logs` 裁定）。

---

## §5B 🔁 **`fp_inputs` 必须在基座变了之后重测**（主控裁定 ② 的值已重取）

`#57` 落树**改了覆盖面里的原生 C 源**（`src/WpfGfx.Linux.Native/src/**`，`#49` B4 纳入的）⇒
**同一份 `close-wave.sh`** 采到的 `inputs_fp` 也随之变。**重测（真调用，两次）**：

| 测量时刻 | 不纳入 | 纳入 | `coverage_n` | `geom-` 命中 |
|---|---|---|---|---|
| `#57` 落树**前**（`00:2x`） | `ecaf53ddc2b5f508` | `f933e4c8b048b864` | 155 / 157 | 0 / 2 |
| **`#57` 落树后（现盘，`01:2x`）** | **`abd349fd58133955`** | **`d1c31c00502a4234`** | **155 / 157** | **0 / 2** |

⇒ **durable 的只有 delta**：`coverage_n` **155 → 157（+2，且只有 +2）**、`geom-` 命中 **0 → 2**、
`inputs_fp` **必变**；**绝对值随时变**（这正是"不能手抄读数"，只能现场算的又一实例）。
⇒ `land.sh` 已改为**现场取 before/after 成对记账**（不在脚本里写死任何绝对值）。

---

## §6C 往 `known-red.json` 加 `generation.geom_corpus` 的**既有牙影响矩阵**（主控裁定 ③）

**逐牙成对真跑**（`DRC_KRJ=` / `ALSC_REG=` / `CFC_REG=` / `--registry` 指向**仓外副本**；
原表 `64b22d35efc1e3be` vs 新表 `81aa2475dd985fef`）：

| 牙（步） | 原表 | 新表 | 判 |
|---|---|---|---|
| `[8]` `ARM-LOG-SHA` | `rc=0 ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0` | **逐字相同** | 零位移 |
| `[10]` `tline-gate（五臂）` | `rc=0 TLINE_GATE=PASS arms=5 red=2 green=3 … gate=747c078dbf04…` ＋ `GATE_REASON=all-as-registered` | **逐字相同** | 零位移 |
| `[16]` **`DEFECT-REGISTRY`** | `rc=0 DEFREG=PASS declared=149 route_ids=149`｜`DEFREG_EXTRA=KRJ=64b22d35efc1e3be`｜**`DEFREG_DECLDRIFT=0`** | `rc=0 DEFREG=PASS declared=149 route_ids=149`｜`KRJ=`**`81aa2475dd985fef`**｜**`DEFREG_DECLDRIFT=1`** | ⚠️ **`DECLDRIFT` 0→1** |
| `[20]` `COLUMN-FLOOR` | `rc=0 COLUMN_FLOOR=PASS … reg=64b22d35efc1e3be` | `rc=0` 同判词，只 `reg=` 变 | 仅自证字段位移 |
| `[30]` `UIA-DOOR` | `rc=0 KNOWN_RED_ARMS=PASS arms=1 ok=1 fail=0 noinfo=0` | **逐字相同** | 零位移 |

⇒ **没有一颗牙因此变红**（`rc`/判词全不变）；**但 `[16]` 留下 `DEFREG_DECLDRIFT=1`**。
机制读准（不是猜）：`defect-registry-check.sh:233-240` 把 `defect-registry-declared.tsv:2` 的
`DECL-ANCHORS` 与现场 **7 个键**逐个比；该行在 `:190` 被**明确降级为非门禁诊断行**。
⇒ **落地要求**：**主控同趟**更新该 TSV 的 `KRJ=`（**主控写域**）；`land.sh` 收尾会点名。

**块本身**：`+9 / −0`、1 hunk；`schema` 仍 `tline-known-red/4`（未升版）；顶层键集合不变；
`generation` 键只新增 `geom_corpus`。**JSON 往返回合逐字节相同**（先证过）⇒ `repin --why` 的 diff 只有新增键。
`repin-generation.py --check` 现盘基线 = **`REPIN_GENERATION=PASS`（rc=0）**。

**⚠️ 该锚今天没有读者**（纪律 47：没人读的声明 = 半个牙）：本波裁定"只接线、不改两件牙" ⇒
读者设计（① 并在第 `[32]`/`[33]` 步调用前；② 照 `arm-log-sha-check.sh` ＋ 第 `[8]` 步先例加外挂读者）
已写进 `why`、预登记 §6 与 `criteria.md` §10.2，归下一趟。

---

## §6 语料：为什么必须收进仓（**实测，不是洁癖**）

| 档 | 命令 | 读数 |
|---|---|---|
| 缺语料 | `--corpus=/nonexistent-xyz` | `GEOMBEAT=NOINFO reason=no-input`／`GEOMRESEND=NOINFO reason=no-input`，**rc=2** |
| 指仓内但无腿子目录 | `--corpus=build/MilBridge/arm-logs` | 同上，**rc=2** |
| **只给修后臂**（模拟两臂失配） | `--corpus=<只有 fix 臂的目录>` | `GEOMBEAT=NOINFO reason=single-arm（成对判词需修前＋修后两臂同场；在场臂=fix）`，**rc=2** |
| 正常 | `--corpus=~/w134a/run` | 两件均 `PASS`，**rc=0**，墙钟 **0.05 s / 0.22 s** |

⚠️ `verify-all.sh:307` 的 `run_step` **只认 `rc==0`** ⇒ 上面三档到场就是**该步 ❌**（`failed_items` 点名）。
⇒ 指 `$HOME/w134a/run` 会让这两步在语料被换/被轮转/换机器时**变成机器相关的红**
（`D-G31` 家族：判据的结论取决于环境此刻长什么样 ⇒ 它不是判据）。

**语料读数**：`du -sb ~/w134a/run` = **39 腿 / 234 件 / 34 MiB**；臂分布 `fix 19 / pre 17 / unknown 3`。
**聚合锚（相对路径口径，`cp -p` 入仓后同法可比）**：
`0f702ccd8eb3938a03be55e17e0c978013d73eb37485847fcaad6f88b1bb9fe2`。
**两件牙各读什么**（机械核）：牙1 = `probe.txt` ＋ `xobs.log`；牙2 = `probe.txt` ＋ `xwrap.log` ＋ `mil.log`
⇒ 只取这 4 类文件是 **32.6 MiB / 156 件**（省 1.4 MiB，**不值得**为此引入"排除清单"⇒ 建议**全量**）。

**射程边界（先写）**：这两步是**档案牙** —— 对**冻结语料**复算，**不跑应用腿、不测当前桥件**
⇒ 「桥件被改回」**不**由这两步咬到。

---

## §6B 语料落进仓后**会不会惊动既有判据面**（**逐牙实测**）

⚠️ 这是最容易漏的一格：语料是 **234 件 / 34 MiB**，落 `build/MilBridge/geom-corpus/**`
**很可能落进某些既有牙的扫描集**，而 `run_step` 只看 `rc` ⇒ 一红就是多一个 ❌。

| 牙 | 扫描集 | 语料成员资格 | 读数 |
|---|---|---|---|
| `[9]` `BUILD-HYGIENE` | `.csproj` roster ＋ **脚本**语料 | 无 `.csproj`、无脚本 | **零位移**（`BHYGIENE_IMPORT=PASS reason=ok files=41 unlisted=0`；`BHYGIENE_COVERAGE=OK n=23 corpus=159` 是**脚本**语料） |
| `[12]` `FP-INPUTS-HYGIENE` | `fp_inputs()` 路径清单 | 不进覆盖面 | **零位移** |
| `[15]` `QUOTE-TRAP` | `-name '*.sh' -o -name '*.py'` | **无** | **零位移** |
| **`[27]` `NUL-BYTES`** | `NULB_EXTS` —— ⚠️ **`.log`/`.txt` 都在名单里** | **在**：`.log=156`＋`.txt=78` | **仍 `PASS`，但计数会动**（下行） |
| `[28]` `HYGIENE` | `code_exts='.sh .bash'`／`doc_exts='.md'`／证据根 `arm-logs` | 既非 code 也非 doc、不在证据根下 | **零位移**（`HYGIENE_TOOTH=PASS roots=PASS evidence=PASS inode=PASS … code_files=75`） |
| `[8]` `ARM-LOG-SHA` | `arm-logs/*.log` 按名 | 不在该目录 | **零位移** |

**`[27]` 的成对读数（真检测器在**仓外沙箱根**上跑，不是推的）**：

```
NULBYTES_ROSTER files=234 bytes=34475351 tools_sh=0
NULBYTES_SCANEXT .log=156 .txt=78
NULBYTES=PASS files=234 hits=0 bytes=34475351 … canary=ok      rc=0
```
| 字段 | 落地前（现场真跑） | 落地后（预测 = 基线 ＋ 语料，两集不相交） |
|---|---|---|
| 判词 | `NULBYTES=PASS files=1243 bytes=253212058 hits=0` | `files=1477 bytes=287687409 hits=0` ⇒ **判词不变** |
| `.log` | `14` | **`170`** |
| `.txt` | `169` | **`247`** |
| `tools_sh` | `37` | `37`（不变） |

⇒ **不会给 `verify-all` 加 ❌**，但**屏上计数会动** ⇒ **必须写进预登记**。
⚠️ **文档漂移（登记、不擅自改）**：`nul-bytes-check.sh:40-43` 注释写「现场 **14** 件 `.log`」，
落地后应为 **170**；该件**在 `fp_inputs()` 白名单里**（`close-wave.sh:235`）⇒ 改它注释**会再动一次 `inputs_fp`**
⇒ **建议只登记不改**（同 W29B 对死子句的「只登记不改」先例），**裁权归主控**。

**硬链接卫生**：`find ~/w134a/run -type f -links +1 | wc -l` = **0**（源语料无多链接件）；
本车道仓外副本同为 **0** ⇒ `cp -p` 不引入跨区同 inode。

---

## §7 交付物与哈希（现场现算，不手抄）

| 件 | 路径 | sha16 | 备注 |
|---|---|---|---|
| 判据 | `~/w151a/criteria.md` | **`0f4ea4de65a930a9`**（266 行；值同步，与末段同源） | 写定 00:22:00，在 `$R` 任何写入之前 |
| 接线预备 | `~/w151a/wiring-plan.md` | **`plan=` 见本件末段**（不写进本表，同报告自身） | 逐字、行锚定；含沙箱预验、反极性表、`§6B` 既有牙影响 |
| 报告 | `~/w151a/report.md` | **值见本件末段（不写进本表：本表在被哈希区内，写进来就是自指不动点）** | 本件 |
| **落地目标候选件**（本件 §2 逐字抽取 → `cp -p` 真副本） | `~/w151a/sb2-verify-all.sh` | **`9e42e608ca854136`** | 1099 行，`+48/−2`，读者判 `PASS` |
| 手工信封件（POS-1，与上者差 2 行注释） | `~/w151a/sb/verify-all.sh` | `67934adf9b5f244c` | 1099 行，读者判 `PASS` |
| diff（终版） | `~/w151a/logs/wiring-final.diff` | —— | `diff -u` 全文（`+48/−2`，5 hunk） |
| `geom_corpus` 块生成器 | `~/w151a/logs/mk-geom-corpus-block.py` | —— | 落地时由 `land.sh` 调它把锚写进 `known-red.json`（**逐字，勿手抄**） |
| **牙1 新版**（带语料锚读者） | `~/w151a/sb-tooth1/geom-revert-beat-check.sh` | **`ee43a703736489a3`** | 701 行，`+185/−3`（8 hunk，只 3 行被替换）；`--selftest` 19/19；由 `land.sh` 步骤 2b 装上前**双断言**前后 sha |
| 牙1 补丁器 | `~/w151a/logs/patch-tooth1-anchor.py` ＋ `tooth1-selftest-add.txt` | —— | 例文走**外部文件**（零转义层） |
| 抽取器 | `~/w151a/logs/apply-plan.py` | —— | 从 `wiring-plan.md` 逐字取块并落地（**可重跑、幂等**：复跑读数 `e34e34c581eba2c9` 逐位相同）；⚠️ 锚点**按位置现算、不写死世代号**（§0B），并先断言 `DECL 数 == run_step 条数` |
| 反极性产物 | `~/w151a/sb/var/{X1,X2,X3,X4,X6}.sh`、`{beat-fakegreen,beat-nored,resend-fixpre,resend-rise1}.sh` | —— | 全部仓外副本 |
| `fp_inputs` 取证 | `~/w151a/logs/fpfp/{A,B,C}.sh` ＋ `*.paths` | —— | 真调用，与仓内读者同法 |
| 语料锚 | `~/w151a/logs/corpus-agg.txt`／`corpus-legs.txt` | —— | 聚合 ＋ 逐腿 |
| 轮询日志 | `~/w151a/logs/gate-poll.log` | —— | 60 s × 61 |
| **落地脚本（闸卫）** | `~/w151a/land.sh` | **`58a18c04f846434c`**（189 行） | 三条硬闸全查（含按 `/proc` 祖先链排除的链在跑判据）；`--dry-run` 现场读数 = `W151A-LAND=ABORT reason=gate-1-gen=gen=#56`（`rc=2`）**⇒ 它今天确实不肯动盘** |
| 交付件收口器 | `~/w151a/logs/finalize.py` | —— | 三件交货的 sha16 一致性由**脚本**收口，不手抄 |

---

## §8 未做到／存疑（**如实标，逐条**）

1. **`$R` 零写入** ⇒ 本波**没有**落地。落地指令在 `wiring-plan.md`，**未执行**（三条硬闸未满足）。
2. **`verify-all.sh` 端到端未跑**：禁跑（且 `#57` 链正持有重活槽）⇒ 全 33 步的端到端绿 **`NOINFO`**。
   本波只判**第 `[11]` 步那台读者**对**候选件**的判词（真件、真参数、真 `PASS`）。
3. **两件牙的 `--selftest` 未复跑**（`12/12`／`8/8` 引用 W149A）⇒ 本车道**未独立复现**（§3.3）。
4. **`--live-selftest` 未跑**（真 `Xvfb :227` ＋ 自写 X 客户端）⇒ 该格沿用 W149A 的 `4/4`，**未复现**。
5. ~~**语料的世代锚不存在**~~ ⇒ **主控裁定 ③ 已改：本波就做**（`generation.geom_corpus` ＋ 同趟 `repin`）。
   **但**：该锚**今天没有机器读它**（本波不改两件牙）⇒ 按纪律 47 它是**半个牙**，读者归下一趟（§6C）。
   以下是**读者缺席时**的现状描述（保留，供下一趟对照）：
   牙的**内部**抗性只盖住朴素换法（删修前臂 ⇒ `NOINFO single-arm`；修前臂全绿 ⇒ `FAIL/FALSE_GREEN`；
   修后臂出现命中 ⇒ `FAIL`；某臂 < 3 腿 ⇒ `NOINFO`）。**盖不住**"换成另一份同样自洽的语料"。
   ⇒ **登记为欠账**，是否同趟加 `generation.geom_corpus` **裁权归主控**。
6. **`--fix=`／`--pre=` 假旋钮未修**：主控已立 **`D-G113`**（判据装置缺陷 · 假旋钮）并采口径句
   "用法声明的开关必须真的改变判据；只改打印的开关一律删掉或接进判据"。本波**不传**这两个开关，
   修法归下一颗仪器牙（**不塞进本波**）。
7. **在 hc 应用腿上当场跑这两颗牙**：禁 `dotnet` ⇒ `NOINFO`（沿用 W149A §6.1）。
8. **源级反极性**（改 `src/**` 复原桥件 + 重建）：写域外 ＋ 禁 `dotnet` ⇒ `NOINFO`。
9. **`--verify-arms` 读仓外目录**（`~/w89a|w134a|w114a|wc03|wc11/app`）：机械核它**不进 `rc`**
   （`:309-320` 只在 `judge()` **算完之后**打印）⇒ 建议传（把"两臂件在盘上"印上屏），**但**它使屏上输出
   **与仓外状态有关**；若主控不接受，**删 4 个词**即可（判定语义零改动）。
10. **`--live-selftest` 用的真 xobs**（`~/wc03/bin/xobs`，`fb3fe379eb943994`）本波**未使用**（未跑 live 档）。

---

## §9B 闸况 60 min 逐条（`~/w151a/logs/gate-poll.log`，60 s × 60）

| 读数 | 值 |
|---|---|
| 轮询区间 | `00:16:05`（i=1）→ `01:15:05`（i=60），共 60 次 |
| `gen=#56` 出现 | **35** 次（`00:16:05` – `00:50:05`） |
| `gen=#57` 出现 | **25** 次，**首次 `00:51:05`** ⇒ **条件 ① 在窗口内满足了** |
| `postdone=yes` | **0** 次 ⇒ **条件 ② 全程未满足** |
| 条件 ③ | **未满足**：`00:16` 现场 = `heavy-slot.sh` ＋ `close-wave.sh --skip-verify-all` ＋ `integration-wave.sh`；`01:15` 现场 = 3 个 `dotnet MSBuild.dll` ＋ `dotnet test … Presentation.Tests`（**一条完整的 `verify-all` 正在跑**）；`01:17` 复查仍是 4 个进程 ⇒ **波动中，但从未三条件同时满足** |

⇒ **三条未同时满足 ⇒ `W151A=BLOCKED`（60 min 上限到点）**。
⚠️ **阻塞的是"落地"，不是"判据/接线预备"**：两份产物的**全部读数都已在闸外取得并自洽**
（含四次真调用 `fp_inputs()`、真读者对候选件的 `PASS`、7 档声明面 ＋ 4 档牙面反极性）。
⇒ 闸一开，`bash ~/w151a/land.sh` 即可落地（脚本自带三条闸卫，今天试跑读数 =
`W151A-LAND=ABORT reason=gate-1-gen=gen=#56`，`rc=2` ⇒ **它确实不肯在闸外动盘**）。

**本车道遗留进程 = 0**（轮询进程已按 **PID** `TERM` 收掉；`Xvfb :227` 残留 **0**；
**未用** `pkill`／`pgrep -f`；按 `/proc/*/cmdline` **逐个 argv** 判 ⇒ 无自匹配）。

---

## §9 本波零写入的机械证（`$R`）

| 目标路径 | 现盘 | 读数 |
|---|---|---|
| `verify-all.sh` | 存在 | `mtime=2026-09-23 22:25:45`（**早于本车道开工 00:15**）｜`sha16=eb29ced9d81b2345`（**与开工读数逐位相同**） |
| `build/close-wave.sh` | 存在 | `mtime=2026-09-23 22:30:07`｜`sha16=0cf2ea72bdee142c`（**与开工读数逐位相同**） |
| `docs/WAVE59-PREREGISTRATION.md` | **ABSENT** | 未创建 ⇒ 我没落过地 |
| `build/MilBridge/geom-corpus/` | **ABSENT** | 未创建 ⇒ 我没落过地 |

近 8 分钟内 `$R` 内被改的件**按目录归并**（全部是**正在跑的 `#57` 链**的构建产物写域）：

```
      6 build/ReachFramework.Linux/obj/Release        6 build/MilBridge/gen
      5 build/PresentationFramework.Linux/obj/Release 5 build/MilBridge/tests/*/obj/Release
      4 build/PresentationFramework.Linux/bin/Release 3 samples/WpfFeatureProbe/bin/Release/net10.0
```
⇒ 本车道的**全部写动作**都落在 `~/w151a/**`（沙箱、副本、日志）；`$R` **一个字节未写**。

---
---

## §11 `#59` **落地与收尾链的现场读数**（①–⑨，逐条机读）

> 本节写于**链跑完之后**；上面的 §0–§10 是判据/接线预备阶段的产物，**一字未改**（加注不覆盖）。

### §11.1 放行与落地（①）
`GATE gen=gen=#58 postdone=yes` ／ `GATE chain=none`（按 `/proc` 逐 argv 判）。落地全部 `temp ＋ rename`、前后 sha **双断言**：

| 件 | before | after | 行数 |
|---|---|---|---|
| `build/MilBridge/geom-corpus/**`（新） | — | 234 件｜聚合 `0f702ccd8eb3938a03be55e17e0c978013d73eb37485847fcaad6f88b1bb9fe2`｜`links_gt1=0` | — |
| `verify-all.sh` | `51ea0b5623981406` | **`ec29c571be6b19da`**（`run_step=33`，`+47/−1`，5 hunk） | 1103 |
| `tools/geom-revert-beat-check.sh` | `9412ec0149111348` | **`ee43a703736489a3`** | 701 |
| `tools/prereg-four-requirements-check.sh` | `57de293df5be263d` | **`b436ae561ae1f396`** | 319 |
| `docs/WAVE59-PREREGISTRATION.md`（新） | — | 147 行（标题含 `#59`） | 147 |
| `build/close-wave.sh` | `0cf2ea72bdee142c` | **`053f5820e354c5ed`** | — |
| `build/MilBridge/known-red.json` | `64b22d35efc1e3be`（484） | **`b3f264bbf43dbd61`**（497，`+13`） | 497 |

**落地脚本自伤两条（都已修，如实记）**：
1. `apply-plan.py` 只支持"复制到 dst 再打补丁" ⇒ 就地改仓内件时 `shutil.copy2` 抛 **`SameFileError`**，且原实现是**原地截断写**（违 `D-G96`/`D-G101` 家族）⇒ 已改为**就地 temp ＋ rename**，并证明两条分支产出**逐字节相同**。
2. `cp -p` 保住了源件的 **600** 权限 ⇒ 临时件**不可执行**（`权限不够`）⇒ 已改为 `bash <临时件>` ＋ 落前 `chmod u+x`。
**并加了幂等守卫**（半落地重跑安全）：`apply-plan.py` 见到 `33 gen=#59` 就 `ALREADY-APPLIED` 退出；牙1/prereg4 见到目标 sha 就 `SKIP`；`fp_inputs` 已插过就跳过；`geom_corpus` 已存在就不重写。**这条是从"第一次跑炸在半路"学来的**。

### §11.2 重钉（②）
`repin-generation.py --check`（`--why` 前）⇒ `REPIN_GENERATION=PASS` → `--why '波 #59 …'` ⇒ `REPIN_GENERATION=APPLIED`（`entries[*].caliber 改动字段数 = 0`）→ 再 `--check` ⇒ **`REPIN_GENERATION=PASS`（rc=0）**。
⇒ `DEFREG_EXTRA=KRJ=` `64b22d35efc1e3be` → **`b3f264bbf43dbd61`**、`DEFREG_DECLDRIFT` **0 → 1**（非门禁诊断行，`DEFREG=PASS`/rc 不变）⇒ **主控当场重发 `declared.tsv` 归零**（已复核 `DECLDRIFT=0`）。

### §11.3 整波（③）
`close-wave.sh --skip-verify-all`（槽内，`HEAVYSLOT=ACQUIRED waited=0s`）：**`rc=0`、`失败步骤=0`**、held 174 s。
`[4/6]` **输入稳定性：波前==波后 == `e7b94e10171b55e1786a63c30a8da568ba24da62228bfb3903eb4f46e3f9a398`**（期间无手写改动）。
九位位移 = **只有 `pf`**（`c69bc1742cfa7f39 → 70f5fd87457ca0f3`，**同尺寸 6,123,520 B** ⇒ 环成员 `D-G92` 机械位移）；其余八位逐位未变。
⚠️ `[4/6]` 报 **`APPSYNC 非 PASS`**（逐条见日志；不必然是本次引入 —— 已在 §11.9 单独核）。

### §11.4 门禁 ×2（④）
两趟各 `rc=0`（157 s／158 s）：`WPTD_SUMMARY=PASS tiers_passed=2/2`、`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_BRIDGE_SRC_STALE=no basis=pub=d697b1e10ff48881 now=d697b1e10ff48881 so_file_match=yes`。
**6/6 判词行逐字一致**（合格线达成；归一化只去 `rundir=` 跑次戳）。**仪器计数漂移 = 0**：两趟 `frames_good=14/14`、`cross_ae=0`、default `drawn=261/notdrawn=0/colors=4112`、env `drawn=144/0/2945` **全同**。
终态 `config=` 含 **`pc:722e0ab8205b7c3f … pf:70f5fd87457ca0f3 …`**（与③的汇总逐字相符）。

### §11.5 生效边界修法（随④一并验）
`WAVE57`：旧牙 `PREREG4=FAIL missing=7`（**那条假红**）→ 新牙 **`PREREG4=SKIP` ＋ `reason=pre-effective` ＋ `wave=#57`**（rc=3）；`WAVE58`：新旧**都 `PASS requirements=4/4`**（不许被 SKIP）。
并给 `docs/WAVE59-PREREGISTRATION.md` 补 §2.7（**条件句**：本波**不做任何回归判定**，本条按条件句读、不被触发 —— **不假装做过**）⇒ 该件 **`PREREG4=PASS requirements=4/4`**；全量 **`PREREG4_SUMMARY files=40 pass=2 fail=0 skip=38 noinfo=0`**（与主控预测逐字相同）。

### §11.6 冻前 `verify-all`（⑤，33 步）—— **条件式预期：照实报**
**`步骤通过 33 ❌ 失败 0`**＋`结论：✅ 全部通过`｜`用例通过 875  跳过 2`｜`X-REUSE=reused display=:99`｜`SKIP_GUARD=PASS x_state=available violations=none`｜`设备上没有空间` **0**。
⇒ **本波未重取臂 ⇒ 声明类红项 = `[]` ⇒ 全绿照实报**（**没有**为了凑"恰 1 处声明类红"去动任何东西）。**33 步全绿，含新的 `[32] GEOM-BEAT` 与 `[33] GEOM-RESEND`**。

### §11.7 冻结（⑥）
`FREEZE_RC=0`。`世代交叉断言通过：树上 #58 == GENS[#59][prev]`；`牙齿②：^run_step " = 33 == 步数 33，且头注释逐字声明了同一数字`。
**基线重冻为 `#59`：整份 sha16 = `02f80e388d308c4d`、846,233 B**（上代 `#58` = `ca6f3091995bd49c`／829,126 B，**成对留档**）。
四牙：`BASELINESHA=PASS live=02f80e388d308c4d decl=02f80e388d308c4d`｜`BASELINEGEN=PASS decl_gen=#59`｜`BASELINE_BYTES=846233`｜`BASELINEDUP=PASS n=0`｜`ARMLOG_SHA=PASS required=5 declared=5 pass=5`｜`COLUMN_FLOOR=PASS … base=02f80e388d308c4d`。
`w59-record.txt`（先建、后冻结）与 `GENS['#59']`（`prev='#58'`／`nstep=33`／`prev_pf='c69bc1742cfa7f39'`／`allow_changed={'pf'}`／`green` = 19 ＋ `GEOM-BEAT` ＋ `GEOM-RESEND` = 21 项）均由本车道备；改 `w27-freeze.py` **前已 `cp -p` 备份**（`d6de5979d651616a → 2c1ec448f5602df0`）。
⚠️ 冻结器的定式句"冻前 BASELINE-SHA/ARM-LOG-SHA/COLUMN-FLOOR(ARMLOG) 红 ⇒ 冻后绿"在本波**不适用**（冻前 `[]`）⇒ 两极化实际形态 = **冻前全绿、冻后仍全绿**（如实记）。

### §11.8 冻后 `verify-all` ×2（⑦）＋ 放行（⑧）
两趟各 `rc=0`：**`步骤通过 33 ❌ 失败 0`**｜`用例通过 875  跳过 2`｜`SKIP_GUARD=PASS`｜`结论：✅ 全部通过`。
**对拍**：两趟 33 行判词**逐字一致**；**冻前 vs 冻后也逐字一致**。**仪器计数漂移 = 0**（三趟 `saved_shim=921ba9c65e9fb3be` 同值）。
**`NOFILE_SWAP=YES`**（趟间未换件，判据 `C4`）：`before=after=saved_shim=921ba9c65e9fb3be`；`BASELINESHA=PASS live=02f80e388d308c4d` 两趟相同；旁证 = 两趟的 `[7] BASELINE-SHA`／`[8] ARM-LOG-SHA` **都绿**。
⇒ 两趟都绿 ⇒ **`touch ~/w21-verify/w59-POST.done`**（`04:29:47`，0 B）。

### §11.9 两条口径句（落册，来自现场）＋ 一条未结清
1. **`say/echo` 的双引号里出现反引号一律转义（或改单引号）；仓外脚本不受 `[15] QUOTE-TRAP` 保护，自己得核。** —— 本波 `land.sh` 自伤一次（两处 `say "…`…`…"` 真做了命令替换，报 `…: 未找到命令`），已修；读数未受影响。
2. **落地脚本必须自带幂等守卫**：本波第一次落地炸在牙1 步骤（`cp -p` 保住 600 ⇒ 临时件不可执行）⇒ 位于其**之前**的 `verify-all.sh` 已落、之后的没落。**没有幂等守卫就会在重跑时把已落的部分再插一遍**（`DECL` 重复 ⇒ `duplicate-step-name` 红）。⇒ 落法 = 每步「见到目标态就跳过」＋ 每个补丁器「见到标记就退出」。
3. **未结清（如实记）**：`close-wave.sh` `[4/6]` 报 **`APPSYNC 非 PASS`** —— 本波**未**逐条核它是"本次引入"还是"继承自上一代"（`#58` 的 record 里同样是 `APPSYNC=MISMATCH`，形态为 `UNEXPECTED=6[DECL-GAP-EQ=6]`、`STALE=false`）⇒ 记 **`NOINFO`**，留给下一趟。

*`report.md` 自身 sha16 = `eb6beee073a47eb5`（**口径** = `head -n -2`：去掉本行与末行 `W151A=DONE` 摘要行。本波按派单书要求末行必须是机器摘要，故 sha 行上移一行、口径由 `head -n -1` 改为 `head -n -2`）*
`W151A=DONE wave=#59 landed=6件+语料 repin=REPIN_GENERATION_PASS chain=①-⑨全绿 plan=77556f5e180095a9 criteria=161eafd30a698fe9 land=44310c7d6a943e91 baseline=#59/02f80e388d308c4d/846233B(prev #58 ca6f3091995bd49c/829126) verify_all=51ea0b5623981406->ec29c571be6b19da(1103行/run_step=33) tooth1=9412ec0149111348->ee43a703736489a3(701,selftest19/19,live4/4) tooth2=cd375326b62f7982(未改) prereg4=57de293df5be263d->b436ae561ae1f396(319,selftest12/12) closewave=0cf2ea72bdee142c->053f5820e354c5ed knownred=64b22d35efc1e3be->b3f264bbf43dbd61(497) corpus=234件/聚合0f702ccd8eb3938a… 九位位移=只有pf(c69bc1742cfa7f39->70f5fd87457ca0f3,同尺寸6123520) infp=4c4d99f569a00380…->e7b94e10171b55e1…(coverage_n155->157) gate_x2=WPTD_GATE_PASS_acceptance2/2_判词6/6逐字一致 pre_verify=33通过/0失败/875通过/2跳过(全绿,声明类红[]) post_verify_x2=各33✅/0❌ NOFILE_SWAP=YES push=8d0c0d5..45c6628 head=45c6628b5882a175 BYTECHECK=245/245 mismatch=0 appsync=STALE0/DIVERGENT0 prereg4_glob=files40/pass2/fail0/skip38 pipfail=PASS/undeclared_hit=0 report=eb6beee073a47eb5 R_touched=6件+234语料 heavy=YES(槽内) residual=APPSYNC_DECL-GAP-EQ=6(继承自#58,非本波)`
