#!/usr/bin/env bash
#
# 一键验证：Xvfb → 构建 → 6 个测试套件 → 命令线格校验 → 在册红门禁（五臂）
#           → PC 侧行对拍（`TextLine.Start` 列）→ **帧列（`FrameProbe`，帧原点机制）**。
#
# ⚠️ **步数口径（引用前必读；三个数不能互相引用）**：
#   **`#77` 收官起 = 50 步**（`#77` **加三步**（47 → 50）：三颗判据牙同趟接线 —— `WIRING-COVERAGE`（`TASK-0740`）／`PARSER-GUARD`（`TASK-0742`）／`PROTO-ATTR`（`TASK-0744`）；覆盖面 **205 → 211**、`--expect` 同趟改。**仪器波 · 零产品改动**。**步数：47 → 50**）
#   **`#76` 收官起 = 47 步**（`#76` **加一步**（46 → 47）：第 `[47]` 步 `BOUNDARY-DECL` ＝ `TASK-0732`「把『未接线／已弃用』这类**边界声明**做成**有机读读者**」—— 声明**从预登记语料读回**（牙里零硬编码），谓词的域是**件路径身份**而非拼写，三态齐全，**覆盖闭包**把「没有谓词的声明」逐条点名成红；同趟 `close-wave.sh` 覆盖面 **+3**、`[42] --expect` 同趟改。**步数：46 → 47**）
#   **`#75` 收官起 = 46 步**（`#75` **加四步**：四件装置/判据卫生合波 —— `TASK-0736` 件头自述 vs 接线牙／`TASK-0737` 落地件不许带车道路径牙（＋同趟修三处真默认值）／`TASK-0738` 比较域区分读数与标签牙／`TASK-0739` 自起显示位按 PID 收 ＋ 普查牙。四处声明同趟改；覆盖面 +5 件、`--expect` 同趟改 202；**零产品改动**。⚠️ 本半句是 `verify-all-step-check.sh:169` 用 `grep -qF` **逐字**找的 ⇒ 一个字符都不能改。**步数：42 → 46**）
#   `#15` = **9 步** / 869 通过 ｜ `#16`–`#20` = **10 步** / 871 通过 ｜ `#21`–`#23` = **11 步** ｜ `#24` = **12 步** ｜ **`#24` 收官起 = 13 步**（收官时加第 `[7]` 步 `BASELINE-SHA`）。
#   第 10 步 = 在册红门禁（五臂）；第 11 步 = `PcLineOracle·Start 列`（`#21` 加）；第 12 步 = `FrameProbe-frame`（`#24` 加）；**第 13 步 = `BASELINE-SHA`**（`#24` 收官加）。
#
#   ⚠️ **上一行的"13 步"是 `#24` 收官当时的史实，不是今天**（`#27` 主控更正；原第 8 行末尾还拖着一截
#      残句"（24\` 加）。"，一并删掉 —— 属**注释残渣**，与判据无关）：
#   **`#25`/`#26` = 14 步**（`#26` 收官加第 `[8]` 步 `ARM-LOG-SHA`）｜**`#27` 收官起 = 16 步**
#   （`#27` 加第 `[9]` 步 `BUILD-HYGIENE` 与第 `[10]` 步 `DEFECT-REGISTRY`）｜**`#28` 收官起 = 17 步**
#   （`#28` 加第 `[11]` 步 `VERIFYALL-SELF`）。第 14 步 = `ARM-LOG-SHA`（`#26` 加）；
#   第 15 步 = `BUILD-HYGIENE`（`#27` 加）；第 16 步 = `DEFECT-REGISTRY`（`#27` 加）；第 17 步 = `VERIFYALL-SELF`（`#28` 加）。
#   **`#30` 收官起 = 18 步**（⚠️ **本波不动步数** —— 它是仪器加固波：`D-G26` 探针身份、`D-G27` 外挂读者、`D-G33` 见证换判据、`D-G34` `pgrep` 自匹配；
#   两件新牙 `hidden-only-step.sh` 与 `column-floor-check.sh` **本波刻意不接线**，留给 `#31` 与它们各自的声明行同趟落）。
#   **`#31` 收官起 = 21 步**（`#31` 一次接三件「**牙已备、无人跑**」的件：第 `[13]` 步 `HIDDEN-ONLY`
#   （`D-T5-R` 的 32 格对照，**构建者**）、第 `[14]` 步 `COLUMN-FLOOR`（`D-G27`：给**下限值本身**一个
#   外挂读者）、第 `[15]` 步 `QUOTE-TRAP`（双引号里的反引号 = 命令替换，本仓现场发生过 **4** 次））。
#   ⚠️ 后两件**只读、零 `dotnet`**；第 `[13]` 步是构建者，实测 ≈ +102 s／趟、35 次 `dotnet`／趟。
#   ⚠️ **机器证（引用前自己重算，别抄我这个数）**：`grep -c '^run_step "' verify-all.sh` ⇒ `#31` 收官后应为 **21**
#      （`#28`=17、`#29`=18、`#30`=18、`#31`=21；**这一串也只是"上次现场算的结果"，引用前重算**）。
#   ⚠️ **而且这个数从 `#28` 起有牙了**：第 `[11]` 步 `VERIFYALL-SELF` **每趟**都核对「抽出的步名/步数/次序/无重名
#      ⇔ 下面的机器读声明块 ⇔ 上面口径句里的数字」，三者分叉即红（`D-G22`；此前它只靠人记得 ——
#      `#24` 收官后那句"当前期望是 13 步"就是这样静默陈旧的，`#26`/`#27` 连加 3 步它都不知道）。
#      （⚠️ **`grep -c run_step` 不带锚会数到函数定义与注释** —— 而且这个差额**不是常数**：
#        `#27` 实测"多 5 行"（函数定义 1 ＋ 注释 4），接 `[9]` 之前是"多 3 行"。
#        ⇒ **别把不带锚的计数当判据，也别引用任何写死的差额**（本行原先写"得 17"就是抄来的、
#        当场就被 `#27` W28B 实测推翻 —— 纪律 49 的形态：**数一律现场算**）。）
#   （本行 `#24` 更正：原头注释还写着"**4 个测试套件**"，那是 `#15` 之前的旧描述 —— 车道 W24B 指出，主控已改。）
#   **时间预算（实测，不是估计）**：第 11 步 ≈66 s；**第 12 步 `WALL≈394–428 s`、峰值 RSS ≈690 MB**
#   （干净单跑 394 s / 并发下 428 s）⇒ 整趟 `verify-all` 比 `#23` **长约 7 分钟**。
#
#   **`#61` 收官起 = 34 步**（`#61` **不动步数**（34 → 34）：本波 = **判据接线/射程波**（**零产品改动**）—— 三处**旋钮/旁路/写点**接死：① `D-G113`「假旋钮」⇒ **connect**（`build/MilBridge/tools/geom-resend-regression-check.sh`：`--fix=`/`--pre=` 必须**真的**从 `main` 传进 `judge()`，修前两开关只改 `NOTE` 打印；相等 ⇒ 拒载）② `TASK-0710` `--leg=` 旁路 ⇒ **judge**（`geom-revert-beat-check.sh`：派生语料**真判**，`--leg` 档打 `NOT_APPLICABLE` 且**不传染**）③ `TASK-0711` **方案 A**（`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh`：**仓内 runner 首写点截断**，仓外 belt `~/w142a/bin/run-gate.sh` **不落仓**）。**都不加步** ⇒ `VERIFYALL_SELF` 现场 = `names=34 decl=34`（`gen` 与代号一致）。**步数：34 → 34（不动）**）
#   **`#66` 收官起 = 37 步**（`#66` **不动步数**（37 → 37）：本波 = `TASK-0720` 落仓 —— `P01`「111 条」口径更正（旧数已证 `TOOL-UNSOUND`）／`P02` 11 条 `#if NEVER` 死声明名单落册／`P03`＋`P03X` 批 2a 三条 `LsErr` 诚实失败（导出 `547 → 550`）＋ **自检牙齿修订**（`D-G128` 实例①：`P03` 与 `P03X` **必须同趟**，分开落会留假牙）／`P04` 新建 `build/MilBridge/tools/nl-intent-check.sh`（`Nl*` 有意降级声明牙）／`P05` `close-wave.sh` 白名单 **+1 行**。**不加步** ⇒ 步名清单与步数口径句一律不动；**`inputs_fp` 必移**（覆盖面 162 → 163）。⚠️ `nl-intent-check.sh` **在覆盖面内但未被 `verify-all` 调用**（`UNWIRED`）⇒ **不许算绿**（接线归 `[Next] TASK-0724`）。）
#   **`#65` 收官起 = 37 步**（`#65` **不动步数**（37 → 37）：本波 = **判据装置批 E · 零产品改动** —— `D-G125`（静默丢行 ⇒ 假绿）的修法 ＋ `DECL_UPPER=EVALUATED|NOT-EVALUATED` 承重 token ＋ 四条册级不变量 ＋ 3‑9 改判；另**接入仓**两件牙（`TASK-0718`：`shell-quote-trap-check.sh` 换件、`fp-manifest-teeth-check.sh` 新建）。**不加步** ⇒ 步名清单不动；**`inputs_fp` 必移** `f1482034…`（161 件）→ **`4c1056dd…`**（162 件，白名单 +1 行）。⚠️ `fp-manifest-teeth-check.sh` **在覆盖面内但未被调用**（`UNWIRED`，`rc=2 NOINFO` ⇒ 不许算绿；接线归 `[Next] TASK-0724`）。
#   **`#74` 收官起 = 42 步**（`#74` **不动步数**（42 → 42）：本波 = 「**装置自清理 ＋ `NA` 判据收紧**」（`TASK-0733` ＋ `TASK-0734` ＋ `TASK-0735`，**仪器波 · 零产品改动**）。① `TASK-0733`（`D-G133`，现场＝`/tmp/r-gate-step-*` 累计把宿主写满、**反手击停正在跑的波**）修 `build/MilBridge/tools/r-gate-step.sh`：默认档 `mktemp -d` ＋ `trap … EXIT` **自清理**（`R_GATE_OUT` 显式给出 ⇒ `ownership=external`，**不删别人的**）＋ **janitor 按 TTL 只清同前缀旧件**（本趟／新鲜／非前缀／符号链接**永不入清空集**）＋ `--keep` **逐字语义**（唯一效果＝不被删 ∧ 必上屏 `R_GATE_OUT_KEPT=`，**不改 `rc`**）＋ **长跑前余量闸**（现取 `df -Pk` 第 4 列；低于阈值 ⇒ `DISK_HEADROOM=FAIL` ＋ `rc=2` ＋ `NOINFO reason=disk-headroom`，**不冒充产品红**；取不到数 ⇒ `NOINFO`）。② `TASK-0734`（`D-G134`）修 `build/MilBridge/tools/prereg-four-requirements-check.sh`：`NA` 由「**提及**」触发改为**声明形态**（**行首锚定声明句** ∨ **机读行** `PREREG-NO-REGRESSION-DECISION:` 值非空非否定）⇒ 假绿通道堵死、既有能力不动、「声明＋证据」照旧 `FAIL`。③ `TASK-0735`（`D-G135`）：**软形态**（锚定句）授予的 `NA` **必须**上屏 `PREREG4_NA_FORM … residual=self-negation-not-checked`（**不进计数、不改 `rc`**），**机读行**（硬形态）**不得**带该令牌。④ **同趟显式扩面**（主控裁定）：`close-wave.sh` 白名单 **+3 行**（三件承重却未受保护的接线件）⇒ 覆盖面 **194 → 197**，`[42]` 的 `--expect` **同趟**改 `197`。**不加步** ⇒ `STEP-NAMES` 一字不改。**`inputs_fp` 必移**。**步数：42 → 42（不动）**）
#   **`#73` 收官起 = 42 步**（`#73` **不动步数**（42 → 42）：本波 = `TASK-0726`「把**静默 SEGV** 那条腿的**产出端**收进仓 ＋ 收编同形副本」（**仪器波 · 零产品改动**）—— ① 新建 `build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`：仓内**唯一**产出端（起显示＋起应用＋跑 9 击配方＋收装置＋把观测变成机读行），**自断言收到了目标环境变量**（`DISPLAY` ∈ `:23[0-9]` ∧ `WPF_PROBE_TAG` ∧ `WPF_PROBE_RUNDIR`，缺一即 `rc=9` 并**逐条**打读数）；② 同目录 `silenthit-trim.tsv` ＝ 剔除集的**唯一来源**（行首锚定逐字 needle ＋ `trail_sp` 重建尾部空格 ＋ 已声明 tag 集），判据端**只消费**、**不另持一份口径**；③ **单变量构造**（`--only-shim`／`--only-app`／`--pair`）＋ 去硬链接化 ⇒ 两臂**只差一件**才跑；④ 车道 7 份同形副本标 `DEPRECATED-BY=… (WAVE73)`（`~/w128a/bin/one128.sh` 留作历史证据**不许动**）。⚠️ 覆盖面变 ⇒ 第 `[42]` 步 `--expect 192 → 194`（**同趟**；漏改 ⇒ `FAIL reason=files-n-mismatch`，方向安全）。⚠️ **`UNWIRED` 仍在**：产出端**在仓内**但 `verify-all` **没有任何一步调用它** ⇒ **不许**把第 `[39]` 步的 `--cases PASS` 读成「现件代已复现／已清零」。⚠️ 本半句是 `verify-all-step-check.sh` 用 `grep -qF` **逐字**找的 ⇒ 一个字符都不能改。**步数：42 → 42（不动）**）
#   **`#71` 收官起 = 42 步**（`#71` **不动步数**（42 → 42）：本波 = 「覆盖面与前置检查」（`TASK-0729` ＋ `TASK-0727`，**零产品改动**）—— ① `TASK-0729`：`build/MilBridge/tests/PtsPagesProbe/` 的**装置四件**＋**`evidence/` 十六件**（共 20 件）入 `close-wave.sh` 的 `fp_inputs()`（覆盖面 **172 → 192**；原先只有判据件与装置入口两件在名单里 ⇒ 改其余 20 件**零机器红**）；② `TASK-0727`：前置检查从「按命令行文本匹配」（`pgrep -af` ⇒ **一条只是提到该模式的旁观 shell 就假阳挡波**）改成「**按可执行件名**」的三面判据；面③（`dotnet` 宿主而 `argv` 判不了）**刻意记 `NOINFO`／`cap=1`：判不了就不挡，但绝不冒充绿**（风险方向＝假阴）。⚠️ 覆盖面变 ⇒ **步本体里的 `--expect` 必须同趟改**（`172 → 192`；漏改 ⇒ `files-n-mismatch`，方向安全）。**本半句是 `verify-all-step-check.sh` 用 `grep -qF` 逐字找的 ⇒ 一个字符都不能改。**）
#   **`#72` 收官起 = 42 步**（`#72` **不动步数**（42 → 42）：本波 = 「**冻结器与抽取器锚在语义上**」（**仪器波 · 零产品改动**）—— ① 冻结器**自动核每个 `prev_*`**、不符即**拒冻**（且基线件零字节改动）＋ 冻前自留备份进冻结器；② 「找块」抽取器**退出条件锚行首** ＋ 两条响亮守卫（块尾找不到 / 出口锚的域失配）。两件都不改产品、不加步。）
#   **`#70` 收官起 = 42 步**（`#70` **加一步**（41 → 42）：本波 = 「清单/指纹**要有牙**」—— `TASK-0724`（第 `[42]` 步 `FP-MANIFEST-TEETH`：把 `#65` 落仓却**从未被调用**的牙 `build/MilBridge/tools/fp-manifest-teeth-check.sh` 接进门禁，驱动件 `build/MilBridge/tools/fp-manifest-step.sh` 以**同码路径拦截**取权威名字表并端出**活清单**）＋ `TASK-0728`（**折叠进既有第 `[12]` 步**，**不另开步**：覆盖面**逐行存在性** ∧ `sha256sum` `stderr` 非空 ⇒ `FAIL`，并把**旧口径的假指纹**当场印出来））
#   **`#69` 收官起 = 41 步**（`#69` **加两步**（39 → 41）：第 `[40]` 步 `BAK-COMPLETENESS`（`D-G126` 牙 `backup-completeness-gate.sh` 的 `--selftest` ＋ 其 `producer=UNWIRED-IN-STEP` 声明的**可跑谓词**，驱动件 `bak-completeness-step.sh`）／第 `[41]` 步 `REPO-ALIAS`（`D-G127` 牙 `repo-alias-check.sh --allow build/MilBridge/repo-alias-allow.tsv`：`$R` 内 `h>1` 的件在**仓外**有孪生 ⇒ `FAIL`；白名单是**声明式豁免**、只降 `aliased_out` 一项，**未覆盖照旧红、树长大也红**）。三态 `PASS|FAIL|NOINFO`，**`NOINFO` 不算绿**。⚠️ 本半句是 `verify-all-step-check.sh` 用 `grep -qF` **逐字**找的 ⇒ 一个字符都不能改。）
#   **`#68` 收官起 = 39 步**（`#68` **加一步**（38 → 39）：第 `[39]` 步 `SILENT-HIT-V2` —— `D-G123` 口径修法（判据端入仓：合取 ＋ 第三支具名 ＋ 阳性对照门槛 ＋ 禁合池 ＋ 零检查报红）。⚠️ **产出端仍 `UNWIRED`**（腿驱动在车道，`verify-all` 不调它）⇒ 本步的 `PASS` **只**证「判据装置还活着」，**不**证「现件代已复现／已清零」。）
#   **`#67` 收官起 = 38 步**（`#67` **加一步**（37 → 38）：本波 = `TASK-0721`（把 `D-G122` 的牙 `PTS-PAGES` 接进门禁 —— **落地前预置**形态）：第 `[38]` 步 `PTS-PAGES` 判「`#50` 的 `A1`＋`A2`＋`A3` 那套『**页级可见降级（洋红占位）＋ 具名行 ＋ 进程不死**』的止损**还在不在**」—— 判据件 `build/MilBridge/tools/pts-pages-guard.sh`（三态 `PTS_GUARD=PASS|FAIL|NOINFO`）、装置 `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`。**门禁里只跑判据那一半**（`--legs`，纯读 < 1 s），重活（起 X ＋ 冷启 ＋ 真实点击）由**波内前置**落到约定证据目录（`PTS_EVIDENCE_DIR` 可覆盖）⇒ 判据与重活解耦；证据缺席 ⇒ **响亮 `NOINFO`**（**不是绿**）。门槛先写死：两腿 `alive=yes` ∧ `app_rc ∉ {134,139}` ∧ 洋红 `≥ 20000` ∧ 具名行 `err≠0` ∧ `PTS_GAP ≥ 1`；`NOINFO` 在门禁里同样是 ❌，且**判序有红先红**。另 `fp_inputs()` 显式清单加**两行**（覆盖面 **162 → 164**）。**步数：37 → 38**）
#   **`#64` 收官起 = 37 步**（`#64` **加一步**（36 → 37）：本波 = `TASK-0717`（把 W157A 的「基线率闸」做成仓内牙）—— 第 `[37]` 步 `BASELINE-RATE-GATE`（`build/MilBridge/tools/baseline-rate-gate.sh`，`--cases` 形态）：判「**在册速率还能不能用来定 `N`**」。三态 `BASELINERATE=PASS|FAIL|NOINFO`；`FAIL` **必须点名「历史速率落在新样本 CI 之外」**；`VOID-PREMISE` **两条并列**（① `ci_upper < gate` ② `observed < effect`）；**缺时间窗／空样本／`n` 非正 ⇒ 响亮 `NOINFO`**。🆕 **口径之争先于结论**：Wilson **单侧**为主判据（`ci_upper=`）、**双侧**只作诊断（`ci_upper_2s=`），两者在**闸比较**上结论不同 ⇒ `NOINFO` ＋ 具名 `reason=caliber-disagreement`，**禁止**用「对我方有利的那一界」下 `PASS`/`FAIL`。牙＋台账两件同时进 `fp_inputs()`（先例：回归判定牙与它的台账**成对**在名单里）⇒ `files 159 → 161`。**本步是确定性合成用例 ⇒ 即使现世界红率已漂到 25%，本步仍恒绿**（判据步不许随被测世界漂移而红/绿）。⚠️ 本半句是 `verify-all-step-check.sh` 用 `grep -qF` **逐字**找的 ⇒ 一个字符都不能改。）
#   **`#63` 收官起 = 36 步**（`#63` **加一步**：第 `[36]` 步 `REGIME-IDENTITY` —— `D-G116` 的牙 `build/MilBridge/tools/regime-identity-check.sh`：判「**对照臂与被试臂同体制**」（体制四列逐项相同）＋「**判红 = 四件合取**」；**结果侧只作诊断、不进 `rc`** —— 口径句：**把结果算进体制，等于用『保护可比性』的名义否掉可比性**。`--selftest` **12 例**（同体制 `PASS`／换体制 `FAIL`＋点名＋标不可比／单格判红 `FAIL`／缺列与空台账**响亮 `NOINFO`**）。⚠️ 本半步是 `verify-all-step-check.sh` 用 `grep -qF` **逐字**找的 ⇒ 一个字符都不能改。）
#   **`#62` 收官起 = 35 步**（`#62` **加一步**（34 → 35）：本波 = `TASK-0714`（把「按模式匹配命令行收/数进程」做成牙 ＋ **同趟修 6 处真站点**）＋ `TASK-0715`（`docs/FORK-AND-PUSH.md`／`docs/PORT-SPEC.md` 对齐现读世代）。牙**进树后会被自己扫到** ⇒ `files 161 → 162`；四处声明**同趟**。⚠️ 「无法复现的历史读数」已在记录里写明成因。⚠️ 这半句是 `verify-all-step-check.sh:169` 用 `grep -qF` **逐字**找的 ⇒ 一个字符都不能改。）
#   **`#60` 收官起 = 34 步**（`#60` **加一步**：第 `[34]` 步 `PREREG-FOUR-REQ` —— `TASK-0709` 的牙 `build/MilBridge/tools/prereg-four-requirements-check.sh`，走**批次门禁形态** `--gate`：① 新增 `PREREG4=NA`（判据节逐字声明「本波不做任何回归判定」∧ 全文无回归判定证据 ⇒ 四要件对本波 `N/A`），**与 `PASS` 分开计数**（`na=` 独立一格）；② 早于生效边界的件不判但**逐件点名 ＋ 计数**（`PREREG4_OUT-OF-SCOPE`／`out_of_scope=`）；③ 批次 `rc` 只由 `fail`／`noinfo` 决定。⚠️ 本半步是 `verify-all-step-check.sh:169` 用 `grep -qF` **逐字**找的 ⇒ 一个字符都不能改。）
#   **`#59` 收官起 = 33 步**（`#59` **加两步**：第 `[32]` 步 `GEOM-BEAT`（`D-G112`／`TASK-0110` 改题后；牙 = `build/MilBridge/tools/geom-revert-beat-check.sh`）＋ 第 `[33]` 步 `GEOM-RESEND`（`TASK-0210` 的确定性回归牙 `build/MilBridge/tools/geom-resend-regression-check.sh`）。⚠️ **这两步的射程 = 冻结语料 `build/MilBridge/geom-corpus/**`**：它们对该语料作**只读复算**，**不跑应用腿、不测当前桥件** ⇒ 「桥件被改回」**不**由这两步咬到（射程边界逐条见 `docs/WAVE59-PREREGISTRATION.md` §5）。⚠️ 这半句是 `verify-all-step-check.sh:169` 用 `grep -qF` **逐字**找的 ⇒ 一个字符都不能改。）
#   **`#58` 收官起 = 31 步**（`#58` **不动步数**：本波 = **仪器波**（**零产品改动**）—— `TASK-0705`「回归判定四要件」整包落地：① `docs/PREREG-TEMPLATE.md` 六处行锚定插入（`171 → 212`；**已在稿原文一字未动**）② 新牙 `build/MilBridge/tools/prereg-four-requirements-check.sh`（`--selftest` 10/10）③ 牙本体 `regression-decision.py` 修 `F-A`／`F-B`／`F-C` 三处（`--selftest` `22/22 → 26/26`、台账 `7/7` 逐字节不变）。⚠️ `#57` 链已把本文件改到 `0345e750fd182a7c` ⇒ 本波两处插入**全部用位置锚**（`head -1` 语义）)
#   **`#57` 收官起 = 31 步**（`#57` **不动步数**：本波 = `TASK-0211` 三处窄 `TOCTOU`／生命周期缺陷的产品修法 —— ① `PostMessageW`／② `PostThreadMessageW` 的**唯一一次放锁挪到 `wpf_queue_push` 之后**（`g_wpf.lock` 可重入 ⇒ push `:98` 再取、`:132` 只把深度 2 掉回 1）；③ `wpf_thread_destroy` 的 `wake_read/wake_write` **锁内先置 -1 再 close**。⇒ `win32shim` `2067cb1c97728791` → `d2b76a0a56a41be1`（**327,672 B 不变**；**导出符号 547 不变**）。**不加步** ⇒ `VERIFYALL_SELF` 现场 = `names=31 decl=31`。⚠️ 同理这半句被 `verify-all-step-check.sh` 用 `grep -qF` 逐字找。）
#   **`#56` 收官起 = 31 步**（`#56` **加四步**：第 `[28]` 步 `HYGIENE` ＋ 第 `[29]` 步 `REGRESSION-DECISION` ＋ 第 `[30]` 步 `UIA-DOOR`（**在册红**形态）＋ 第 `[31]` 步 `IME-LANDING`；`TASK-0708` 的接线，四件**纯读、零 `dotnet`、秒级**。⚠️ 这半句是 `verify-all-step-check.sh:169` 用 `grep -qF` **逐字**找的 ⇒ 一个字符都不能改。）
# ── 步名/步数声明（**机器读**；`D-G22` 的「声明的集合」= 这一段；**改步必同趟改本块**）──────
#   读者 = `build/MilBridge/tools/verify-all-step-check.sh`（第 `[11]` 步）。它比对三件事：
#     ① 本块的**步名清单** ⇔ 现场 `^run_step "` 抽出的步名（**多重集合 + 次序 + 无重名**）；
#     ② 本块的**步数** ⇔ 现场条数 ⇔ 清单里的名字个数；
#     ③ 上面口径句里的「**`#NN` 收官起 = N 步**」⇔ 现场条数。
#   ⚠️ **三者任一缺失/分叉 ⇒ 不是绿**：分叉 ⇒ `FAIL`，**缺声明 ⇒ `NOINFO`**（`rc=2`，**不许当绿**）。
#   ⚠️ 本块**故意放在同一个文件里**：跨文件的手工声明在本仓**已经失败过一次**（`docs/CURRENT-STATE.md`
#      那句"当前期望是 N 步"在 `#26`/`#27` 连加 3 步时毫无反应、全程零红）⇒ 声明必须与本体同趟改、同趟审。
#   ⚠️ **不许**用 `echo "====="` 当接线锚（它在本文件里有 **4** 处）；锚用 `run_step "DEFECT-REGISTRY" …`。
# VERIFYALL-STEPS-DECL: 50 gen=#77   ← `#77` **加三步**（47 → 50）：① 第 `[+]` 步 `WIRING-COVERAGE`（`TASK-0740`：接线件集合 ⊆ `fp_inputs()` 覆盖面，**每次现扫**、缺一件即红点名）② 第 `[+]` 步 `PARSER-GUARD`（`TASK-0742`/`D-G143`：解析器不许把『解析不出』静默中性化 ＋ 继承环境必须校验并逐字打印）③ 第 `[+]` 步 `PROTO-ATTR`（`TASK-0744`/`D-G144`：协议级归因牙，三态 `ATTRIBUTED`/`NOT_ATTRIBUTED`/`NOINFO`）。同趟：覆盖面 **205 → 211**（本波 5 件 ＋ `TASK-0740` 收编的 1 件）＋ 第 `[42]` 步 `--expect 205 → 211` ＋ 四处声明。**步数：47 → 50**）
# VERIFYALL-STEPS-DECL: 47 gen=#76   ← `#76` **加一步**（46 → 47）：第 `[47]` 步 `BOUNDARY-DECL`（`TASK-0732`：把"未接线／已弃用"边界声明做成**有机读读者** —— 牙从 `docs/WAVE*-PREREGISTRATION.md` **读回**声明与谓词参数，按**件路径身份**（`run_step` argv 归一 ＋ 包装件传递闭包）在真树上求值；域**不是**拼写；三态 `PASS`/`FAIL`/`NOINFO`；覆盖闭包把"没有谓词的声明"点名成红。**只有本件加步**；`TASK-0720` 的牙走 `close-wave.sh` **冻前**（不加步）、`TASK-0721` 纯文档面（不加步不加件）、`TASK-0741` 改判据件自身（不加步）。**步数：46 → 47**）
# VERIFYALL-STEPS-DECL: 46 gen=#75   ← `#75` **加四步**（42 → 46）：「**四件装置/判据卫生**」合波（`TASK-0736` ＋ `TASK-0737` ＋ `TASK-0738` ＋ `TASK-0739`，**仪器波 · 零产品改动**）：`[+] SELFDESC-WIRING`（**件头自述 vs 接线**：自述"未接线"而 `^run_step` 命中该件 ⇒ 必红；反向（自述"已接线"而零命中）⇒ 也必红；`--selftest` 8/8）／`[+] LANE-PATH`（**落地件不许出现车道路径**：`kind=code` 必红且**永不许豁免**；`comment`/`data` 走声明式出处清单 `build/MilBridge/lane-path-provenance.tsv` ＋ **每类件数上限**（现读 > 上限 ⇒ 红）；`--selftest` 13/13）／`[+] ROWS-IDENTITY`（**比较域必须区分读数与标签**：只标签差异 ⇒ `PASS` ＋**必印** `LABEL_ONLY_DIFF fields=…`；读数真差异 ⇒ `FAIL`；语料＝`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **最新冻结块**现取；`--selftest` 12/12）／`[+] X-CENSUS`（**长跑自起显示位收尾收净并自查**：以 `[0]` 段落的**自含链前基线**比对 `ps` ＋ `/tmp/.X11-unix/`，差异**点名 PID**；"死 socket" 与"活泄漏"**分开判**；`--selftest` 12/12）。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。覆盖面 **+5 件** ⇒ 第 `[+]` 步 `FP-MANIFEST-TEETH` 的 `--expect` 同趟改 **202**。**步数：42 → 46**
# VERIFYALL-STEPS-DECL: 42 gen=#74   ← `#74` **不动步数**（42 → 42）：本波 = 「**装置自清理 ＋ `NA` 判据收紧**」（`TASK-0733` ＋ `TASK-0734` ＋ `TASK-0735`，**仪器波 · 零产品改动**）：`TASK-0733` 给 `build/MilBridge/tools/r-gate-step.sh` 加**两条会红的**机器判据 —— ① **临时件自清理**：默认档一律 `mktemp -d` ＋ `trap … EXIT` 回收（旧版默认 `OUT="${R_GATE_OUT:-/tmp/r-gate-step-$$}"` **永不清理** ⇒ 现场 `/tmp/r-gate-step-*` **66 件 / 6.8 GB** ⇒ 宿主 `ENOSPC` **反手击停正在跑的波 `#68`**，两段日志 0 B ＋ 40 s 内 `rc=1` 差点被读成"判据红"）＋ **janitor 按 TTL 只清同前缀旧件**（本趟目录／新鲜件／非前缀件／符号链接**永不入清空集**，且 `readlink -f` 须直接位于 `OUT_ROOT` 之下防逃逸）＋ `--keep` 的**唯一效果**（不被删 ∧ **必上屏** `R_GATE_OUT_KEPT=`，**不改 `rc`、不改判据**）＋ **所有权**（`R_GATE_OUT` 由调用者给出 ⇒ `ownership=external`，**既不删也不入清空集**）；② **磁盘余量闸**：长跑前**现取** `df -Pk` **第 4 列**，闸 `OUT_ROOT`／仓根／**调用者给的 `OUT` 那一侧**取**更小者**，低于阈值（默认 5 GB）⇒ `DISK_HEADROOM=FAIL` ＋ **`rc=2`** ＋ 判 `NOINFO reason=disk-headroom`（**不冒充产品红**）；取不到数 ⇒ `NOINFO`（**永不放行**）。`TASK-0734` 把 `build/MilBridge/tools/prereg-four-requirements-check.sh` 的 `NA` 从「**整节正则／令牌出现即算**」（判据节里一句**散文"提及"**就能打开「跳过回归判定四要件」这道门 ＝ **假 N/A**）收紧为**两形态**（都**只在判据节内**）：① **行首锚定声明句**（剥装饰后须以 `本波` 起头且**同一行**含那句话）② **机读行** `PREREG-NO-REGRESSION-DECISION:` 且值**非空 ∧ 非否定令牌**（`none`／`no`／`false`／`0`／`n/a`／`na`／`null`／`-`）；只提及 ⇒ 打 `PREREG4_NOTE mention-only` 并**走正常路径**（该 `FAIL` 就 `FAIL`）；**「声明 ∧ 引用判定工件」仍 `FAIL`（不放宽）**。`TASK-0735` 加**可见性**：`NA` 由**软形态**（锚定句）授予 ⇒ **必须**上屏 `PREREG4_NA_FORM form=anchor-sentence residual=self-negation-not-checked`（**不进计数、不改 `rc`**）；**机读行**（硬形态）⇒ **不得**出现 `residual=`。**同趟显式扩面（主控 `2026-09-26` 裁定，`TASK-0729` 同族）**：`build/close-wave.sh` 的 `fp_inputs()` 白名单 **+3 行**（`prereg-four-requirements-check.sh`／`pc-line-step.sh`／`frame-step.sh` —— 三件**都在门禁里承重**却**不在覆盖面**，依据成文惯例「**读 ⇒ 进 `fp_inputs()`**」）⇒ 覆盖面 **194 → 197**，并**同趟**把第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect 194` 改成 **`197`**（**声明常数**；漏改 ⇒ `FAIL reason=files-n-mismatch delta=-3`，**方向安全**）；收口判据＝复跑普查得「**未被覆盖面保护的接线件 = 0**」。**不加步** ⇒ `STEP-NAMES` 一字不改（仅追加本行与口径句）。**`inputs_fp` 必移**（三件新入名单 ＋ 两件改内容，**全在名单内**）。⚠️ 两极化**全部真跑**（`TASK-0733` 清零正极／残留反极／余量反极＋正极／桩 `df` 不可解析 ⇒ `NOINFO`／`--keep` 保留 `KEPT` 行；`TASK-0734` 仅提及 ⇒ `FAIL missing=8`／锚定句 ⇒ `NA rc=0`／机读行 `yes` ⇒ `NA rc=0` 且**不带** `residual=`／值 `none`·空值·句中令牌 ⇒ `FAIL`／声明＋证据 ⇒ **仍 `FAIL`**；`TASK-0735` 软⇒有该行、硬⇒无该行），并对仓内**全部** `docs/WAVE*-PREREGISTRATION.md` 做**射程扫描**（**无一件 `NA→FAIL`**）。**步数：42 → 42（不动）**
# VERIFYALL-STEPS-DECL: 42 gen=#73   ← `#73` **不动步数**（42 → 42）：本波 = `TASK-0726`「把**静默 SEGV** 那条腿的**产出端**收进仓 ＋ 收编同形副本」（**仪器波 · 零产品改动**）：第 `[39]` 步 `SILENT-HIT-V2` 在 `#68` 落仓的只是**判据端**（纯读、吃台账），**产出端一直在车道目录**（8 份同形副本）⇒ 本波把它做成仓内**唯一**产出端 `build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`（重活那一半：起显示、起应用、跑 9 击配方、收装置、把观测变成机读行；**自断言目标环境变量已收到**；**单变量构造**两臂只差一件；**禁**硬链接并逐件断言 `%h==1`）＋ 同目录 `silenthit-trim.tsv`（剔除集**唯一来源**：行首锚定逐字 needle ＋ `trail_sp` 重建尾部空格 ＋ 已声明 tag 集；判据端**只消费**产出端自报的 `APP_TEXT_BYTES_TRIMMED` 并与台账 `trimmed` 列交叉核 ⇒ **不另持一份剔除口径**）。两极化 4 腿**真跑**（R1 真静默 SEGV ⇒ `rc139`＋红签名／R2 重放历史真现场 ⇒ `stop-signo11`＋红签名／C1 真进程不崩 ⇒ 不打红／C2 **真 WPF 应用活腿** ⇒ `alive-after-recipe` 不打红）。**不加步** ⇒ `STEP-NAMES` 一字不改（仅追加本行与口径句）。覆盖面 **192 → 194**（白名单 **+2 行**）⇒ 同趟把第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect 192` 改成 **`194`**；**`inputs_fp` 必移**。⚠️ **`UNWIRED`**：产出端**在仓内但未被任何一步调用**（判据口径限定到代码形状 `grep -cE '^[[:space:]]*run_step .*silenthit' verify-all.sh` = 0；全文命中只作旁证）⇒ **不许把第 `[39]` 步的 `--cases PASS` 读成「现件代已复现／已清零」**。**步数：42 → 42（不动）**
# VERIFYALL-STEPS-DECL: 42 gen=#72   ← `#72` **不动步数**（42 → 42）：本波 = 「**冻结器与抽取器锚在语义上**」（`TASK-0730` ＋ `TASK-0731`，**零产品改动**）：`TASK-0730` 让**仓外**冻结器 `~/w21-verify/w27-freeze.py` **自动核每个 `prev_*`** 与基线件 `^# RE-FROZEN #<prev>` 块（九位行／`BRIDGE_SRC_FP` 行／`inputs_fp` 行）逐位一致，**不符即拒冻**（非零退出 ∧ **基线件零字节改动**，核验插在**任何写盘之前**），同趟把 `B.pre-freeze.<gen>.bak` 做进冻结器本身；`TASK-0731` 把 `build/MilBridge/tools/column-floor-check.sh` 的「找块」抽取器 `extract_newest_block()` 的**退出条件锚到行首**（旧写法用**无锚**的「`RE-FROZEN` ＋ 井号」当退出条件 ⇒ 块内正文只要提到该字样就**提前截断**，把紧随其后的 `# COLUMN-FLOOR`／`# COLUMN-CORPUS`／`# ARM-LOG-SHA` 声明行全排除 ⇒ `COLUMN_FLOOR=NOINFO`（**病因错**）），并新增两条**响亮**守卫（块尾找不到 ⇒ `NOINFO reason=block-end-not-found`；出口锚的**域**由两种机制现取自证 ⇒ `NOINFO reason=block-header-form-mismatch`）。**不加步** ⇒ `STEP-NAMES` 一字不改。**`inputs_fp` 必移**（`column-floor-check.sh` 在覆盖面内）但**覆盖面行数不变**（192 → 192）⇒ 第 `[42]` 步的 `--expect 192` **不动**。**步数：42 → 42（不动）**
# VERIFYALL-STEPS-DECL: 42 gen=#71   ← `#71` **不动步数**（42 → 42）：本波 = 「覆盖面与前置检查」（`TASK-0729` ＋ `TASK-0727`，**零产品改动**）：`TASK-0729` 把 `build/MilBridge/tests/PtsPagesProbe/` 的**装置 4 件 ＋ `evidence/` 16 件共 20 件**收进 `build/close-wave.sh` 的 `fp_inputs()` 覆盖面（**172 → 192**，逐件归因；原先只有 `pts-pages-guard.sh`（判据件）与 `run-pts-pages-legs.sh`（装置入口）两件在名单里 ⇒ 改其余 20 件**零机器红**）；ⓘ 覆盖面变 ⇒ **步本体里那个显式常数必须同趟改**：本行同趟把第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect 172` 改成 **`--expect 192`**（**声明常数**；`verify-all.sh` **不在**覆盖面 ⇒ 与生产路径无关；**漏改 ⇒ `FAIL reason=files-n-mismatch delta=-20`**，方向安全 —— 成对读数见 `docs/WAVE71-PREREGISTRATION.md` §2）。`TASK-0727` 把 `close-wave.sh` 的前置检查从「**按命令行文本匹配**」（`pgrep -af "$APP_PROBE_RE"`：一条**只是提到**该模式的旁观 shell 就能**假阳挡波**，`#66` 现场 `18:42:45`）改成「**按可执行件名**」的三面判据（面① `/proc/<pid>/exe` 基名 = 应用本体；面② `dotnet` 宿主的**被执行项**、或 shell ＋ 启动器脚本名；面③ `dotnet` 宿主而 `argv` 判不了 ⇒ `cap=1`／`NOINFO`：**判不了就不挡、绝不冒充绿**）。**不加步** ⇒ `STEP-NAMES` 一字不改（仅追加本行与口径句）。**`inputs_fp` 必移**（覆盖面 +20 件；本函数自含 `close-wave.sh`）。**步数：42 → 42（不动）**
# VERIFYALL-STEPS-DECL: 42 gen=#70   ← `#70` **加一步**（41 → 42）：`TASK-0724` 把 `#65` 落仓、**从未被调用**的指纹清单牙 `build/MilBridge/tools/fp-manifest-teeth-check.sh`（那时它“在册但没牙床”：正常运行恒 `FP_MANIFEST_TEETH=NOINFO reason=no-manifest`、`rc=2`）**接进门禁** —— 第 `[42]` 步 `FP-MANIFEST-TEETH`（驱动件 `build/MilBridge/tools/fp-manifest-step.sh`）：以**内容锚**从 `build/close-wave.sh` 抽出 `fp_inputs()` **函数体原文**（`sed -n '/^fp_inputs()/,/^}/p'`，**一个字都不改**）**原样执行**，用 `PATH` 前置的同名 `sha256sum` shim 收 **`xargs` 真正交给 `sha256sum` 的那些名字**（`xargs` 是 `exec`、看不见 shell 函数 ⇒ 只能从 `PATH` 拦），再以**生产同形**命令 `LC_ALL=C xargs sha256sum` 产出**活清单**交给牙 —— 判「**清单/指纹有牙**」：① **逐行形状** `^[0-9a-f]{64}  .+`（污染行 ⇒ 逐条点名 `FP_MANIFEST_HIT kind=MANIFEST-SHAPE file=… line=…`）② **件数对账**（`files_n` == `--expect N`，`N` = **本步步本体里手写的显式常数**；`verify-all.sh` **不在** `fp_inputs()` 覆盖面 ⇒ 常数**与生产路径无关**，是牙头推荐的唯一来源；**漏改 ⇒ `FAIL reason=files-n-mismatch delta=±k`**，方向安全）③ 空清单 ⇒ `FAIL reason=empty-manifest`；三态 `FP_MANIFEST_TEETH=PASS|FAIL|NOINFO`（`PASS⇒rc=0`／`FAIL⇒rc=1`／`NOINFO⇒rc=2`，**`NOINFO` 不算绿**）；驱动另有四条守卫（抽得出 ／ **拦截不扰动**（拦截指纹==无拦截指纹）／ 名字表非空 ／ `sha256sum` `stderr` 空 ∧ 清单行数==名字数）任一不过 ⇒ 一律非零（**宁可不判、不许假绿**）；**同趟**把 `TASK-0728`（「`fp_inputs()` 白名单每一行都真存在」做成**硬判据**：逐行 `-e ∧ -f` **∧ `sha256sum` `stderr` 非空 ⇒ FAIL**，并把**旧口径在同样这份缺件覆盖面上会给出的那个形状完好的 64-hex** 当场印出来 —— `would_be_fp=`）**折叠进既有第 `[12]` 步** `FP-INPUTS-HYGIENE`（**不另开步**：本件已握有**被 `cmp` 证完备**的权威成员表，另起一件就必须**再抽一次覆盖面** ⇒ 正是「同一份逻辑存在两处必然分叉」）；**纯读、零 `dotnet`、秒级**（现测 `[42]≈0.4 s`）；不写 `$R`（临时件走 `mktemp -d`）；不改产品件 ⇒ 九位逐位不动；同趟落 `build/close-wave.sh` 覆盖面白名单 **+1 行**（`fp-manifest-step.sh`）⇒ `coverage_n` **171 → 172**、`inputs_fp` 必变。**步数：41 → 42**
# VERIFYALL-STEPS-DECL: 41 gen=#69   ← `#69` **加两步**（39 → 41）：`TASK-0725` 把两条“**会红的牙**”接进门禁 —— 第 `[40]` 步 `BAK-COMPLETENESS`（`D-G126` 牙 `build/MilBridge/tools/backup-completeness-gate.sh` 的 `--selftest` **＋** 它的 `producer=UNWIRED-IN-STEP` 声明的**可跑谓词**，驱动件 `build/MilBridge/tools/bak-completeness-step.sh`：`n_wired = grep -E '^[[:space:]]*run_step .*backup-completeness-gate\.sh.*--plan' verify-all.sh` **== 0 才绿**，产出端一旦被接线 ⇒ **当场翻红**）／第 `[41]` 步 `REPO-ALIAS`（`D-G127` 牙 `build/MilBridge/tools/repo-alias-check.sh --allow build/MilBridge/repo-alias-allow.tsv`：判「`$R` 内有没有 **inode 共享**（`h>1` 且孪生**在仓外**）—— 那是“在别处对权威树做原地写”的**唯一可见形态**」）；三态 `BAK_COMPLETENESS=PASS|FAIL|NOINFO`／`ALIAS=PASS|FAIL|NOINFO`（`PASS⇒rc=0`／`FAIL⇒rc=1`／`NOINFO⇒rc=3`，**`NOINFO` 不算绿**）；**零检查必红**（`examined==0`）；**扫不完 ⇒ `NOINFO`**（超时／根不存在，绝不把“没扫完”当“没孪生”）；🔴 **口径句：允许清单是声明式豁免，不是把牙关掉** —— 白名单**只降 `aliased_out` 一项**（降成 `aliased_allowed`）、四项计数照打，**未被覆盖的孪生照旧 `FAIL reason=out-of-repo-alias`**，**当前件数 > 上限 ⇒ `FAIL reason=allowed-tree-grown`**（**树长大也要红**），唯一一种“有孪生还给绿”= **全部覆盖 ∧ 各有界**（`reason=known-alias-trees`）；⚠️ **两处如实划界**：① `BAK-COMPLETENESS` 跑的是**牙的自测**（证“装置还活着 ＋ 五条负腿真会红”），牙的**真用法**（落地前 `--plan` 驱动的完备性判定）**不在门禁里** ⇒ `producer=UNWIRED-IN-STEP` **由本步的谓词求值**；② `REPO-ALIAS` **只覆盖 inode 共享**（同内容的独立真拷贝不报＝正确行为；孪生在 `--roots` 外／深于 `--maxdepth` ⇒ 不检出；符号链接影子、**写穿已发生的历史** ⇒ 不覆盖）。**纯读、零 `dotnet`、秒级**（现测 `[40]≈0.5 s`／`[41]≈4.8 s`）；产物落**仓外**（`$HOME/.cache/wpf-linux/`）⇒ **不写 `$R`**；不改产品件 ⇒ 九位逐位不动；同趟落 `build/MilBridge/repo-alias-allow.tsv`（**每行带“为什么允许”**）。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：39 → 41**）
# VERIFYALL-STEPS-DECL: 39 gen=#68   ← `#68` **加一步**（38 → 39）：第 `[39]` 步 `SILENT-HIT-V2`（`D-G123` 口径修法入仓 —— 牙 `build/MilBridge/tools/silent-hit-v2-check.sh --cases build/MilBridge/tools/silent-hit-v2-cases.tsv --expect 12`：**三条件合取** ∧ 第三支 `SEGV_BRANCH` **具名**（四支白名单）∧ **阳性对照＝开跑门槛**（无 HIT 行 ⇒ `FAIL reason=untriggerable`）∧ 跨件代**禁止合池**；两个字节数**都印**；三态 `SILENTHIT=PASS|FAIL|NOINFO`；**空表／缺列／非整数／零行被检查 ⇒ `NOINFO rc=2`**（零检查必须报红）；台账 12 行 = **确定性用例 ＋ 在册 4 条历史真命中**（`W071`／`W077`／`L1B024`／`W8AA-04`）⇒ 本步**不随被测世界漂移**；纯读、零 `dotnet`、秒级；不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。)⚠️ **UNWIRED 两条**：① `producer=UNWIRED-IN-STEP` —— 产出端（腿驱动）**仍在车道**（8 份同形副本），`verify-all` 里**没有任何一步调用它**（判据口径须限定到代码形状 `grep -cE '^[[:space:]]*run_step .*silenthit' verify-all.sh` = 0；**全文 `grep` 命中只作旁证**，`D-G119` 实例㉔）⇒ **不许把 `--cases` 的 `PASS` 读成「现件代已复现／已清零」**；② `legacy-copies=DEPRECATED×7`（待 `TASK-0726`）。
# VERIFYALL-STEPS-DECL: 38 gen=#67   ← `#67` **加一步**（37 → 38）：本波 = `TASK-0721`（把 `D-G122` 的牙 `PTS-PAGES` 接进门禁 —— **落地前预置**形态）：第 `[38]` 步 `PTS-PAGES`（判据件 `build/MilBridge/tools/pts-pages-guard.sh`，装置 `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`）：判「`#50` 的 `A1`＋`A2`＋`A3` 把『切富文本 23／流文档 24 必死 `rc=134`』降级成『页级可见降级（洋红占位）＋ 具名行 ＋ 进程不死』—— **这个止损还在不在**」：三态机读行 `PTS_GUARD=PASS|FAIL|NOINFO`；承重格 `G1/G2` 两腿 `alive=yes`、`G3` 两腿 `app_rc ∉ {134,139}`、`G4/G5` 两腿洋红 `≥ 20000`（阈值先写死；观测下界 49,864 ⇒ 余量 2.49×）、`G8/G9` 托管侧具名行 `[PTS-UNAVAILABLE] … err≠0` 在位、`G10` native `PTS_GAP entry=` ≥ 1；`G6/G7`（点错对象）与 `G11/G12`（装置没起来／件跑动中被换）**走 `NOINFO` 不当红**，`D1–D6` 只诊断不进 `rc`；**判序：有红先红**（`NOINFO` 比 `FAIL` 弱，先用弱结论会把真红洗成『算不出』），而 `NOINFO` 在门禁里**同样是 ❌**。🆕 **本步只跑判据那一半**（`--legs <已落盘证据目录>`，纯读、零 `dotnet`、< 1 s）—— **重活（起私有 X ＋ 应用冷启 ＋ 真实点击；A 臂 2 腿 ≈ 45 s）不在门禁里同步跑**，由**波内前置**产出并落在约定路径（`PTS_EVIDENCE_DIR` 覆盖，默认 `build/MilBridge/tests/PtsPagesProbe/evidence`）⇒ 判据与重活**解耦**（这正是本牙把『判据／装置』分成两件的原因）；证据目录缺席／不满 2 腿 ⇒ **响亮 `NOINFO`**，**禁静默判绿**。⚠️ **同趟落「判据反转」文本**（`TASK-0302` 真实现落地后绿条件改为 `洋红=0 ∧ 无具名行 ∧ native_gap=0`）—— **反转必须成对**（绿条件与红条件同趟改，否则两个时代的绿会混在一起）。⚠️ 射程（如实划界）：本步**只**保证『止损还在』，**不**保证『该被真实现』（真缺口是 `TASK-0302`）；抓不到『下游真缺口被顺手 stub』。**纯读、零 `dotnet`**；不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改；另**两行**入 `fp_inputs()` 显式清单（**覆盖面 162 → 164**）。**步数：37 → 38**）
# VERIFYALL-STEPS-DECL: 37 gen=#66   ← `#66` **不动步数**（37 → 37）：本波 = `TASK-0720` 落仓 —— `P01`「111 条」口径更正（旧数已证 `TOOL-UNSOUND`）／`P02` 11 条 `#if NEVER` 死声明名单落册／`P03`＋`P03X` 批 2a 三条 `LsErr` 诚实失败（导出 `547 → 550`）＋ **自检牙齿修订**（`D-G128` 实例①：`P03` 与 `P03X` **必须同趟**，分开落会留假牙）／`P04` 新建 `build/MilBridge/tools/nl-intent-check.sh`（`Nl*` 有意降级声明牙）／`P05` `close-wave.sh` 白名单 **+1 行**。**不加步** ⇒ 步名清单与步数口径句一律不动；**`inputs_fp` 必移**（覆盖面 162 → 163）。⚠️ `nl-intent-check.sh` **在覆盖面内但未被 `verify-all` 调用**（`UNWIRED`）⇒ **不许算绿**（接线归 `[Next] TASK-0724`）。
# VERIFYALL-STEPS-DECL: 37 gen=#65   ← `#65` **不动步数**（37 → 37）：本波 = **判据装置批 E · 零产品改动**（`D-G125` 静态丢行的修法 ＋ `DECL_UPPER` 承重 token ＋ `AMENDMENT-2/3` ＋ 四条册级不变量 ＋ 3‑9 改判；另**接入仓**两件牙 `TASK-0718`）。**不加步** ⇒ **步名清单（`VERIFYALL-STEP-NAMES`）与步数口径句一律不动**。**`inputs_fp` 必移**：`f1482034…`（161 件）→ **`4c1056dd…`**（162 件，白名单 +1 行 `build/MilBridge/tools/fp-manifest-teeth-check.sh`）；**逐件归因成对**（5 个 file-line：`shell-quote-trap` 换内容／`fp-manifest` 新建并入名单／`close-wave.sh` 自改／`baseline-rate-gate.sh` 与 `baseline-rate-cases.tsv` 被改），**32 行交叉表**：全部退回 ⇒ 逐位 == `f1482034…`。⚠️ **`UNWIRED`**：`fp-manifest-teeth-check.sh` 在覆盖面内但**未被 `verify-all` 调用**（`grep -c` = 0），其正常运行 = `NOINFO reason=no-manifest`（`rc=2`）⇒ **不许算绿**（接线归 `[Next] TASK-0724`）。
# VERIFYALL-STEPS-DECL: 37 gen=#64   ← `#64` **加一步**（36 → 37）：第 `[37]` 步 `BASELINE-RATE-GATE`（`D-G118` 的牙 `build/MilBridge/tools/baseline-rate-gate.sh`：判「**在册速率还能不能用来定 `N`**」—— 逐项印 `registered=<R>/<n>@<时间窗>`／`observed=`／`fisher_p=`／`ci_upper=`／`gate=`／`effect=`／`required_n=`；三态 `BASELINERATE=PASS|FAIL|NOINFO`：`FAIL` **必须点名「历史速率落在新样本 CI 之外」**；`VOID-PREMISE` **两条并列**（① `ci_upper < gate` ② `observed < effect` ⇒ 该效应在现世界不可发生）；**缺时间窗／空样本／`n` 非正／`r` 越界 ⇒ 响亮 `NOINFO`**（纪律 27：解析任一侧为空必须响亮失败，禁静默判等）；🆕 **口径之争先于结论**：Wilson 单侧为主判据（`ci_upper=`）、双侧只作诊断（`ci_upper_2s=`），两者在**闸比较**上结论不同 ⇒ `NOINFO` ＋ 具名 `reason=caliber-disagreement`，**禁**挑有利的界。台账 `build/MilBridge/tools/baseline-rate-cases.tsv`（**11 行确定性合成用例**，不依赖现场腿读数 ⇒ **本步不会随被测世界漂移而红/绿**）。本步**纯读、零 `dotnet`、秒级**；不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：36 → 37**）
# VERIFYALL-STEPS-DECL: 36 gen=#63   ← `#63` **加一步**（35 → 36）：第 `[36]` 步 `REGIME-IDENTITY`（`D-G116` 的牙 `build/MilBridge/tools/regime-identity-check.sh`：给定逐腿台账，断言同一 `pair` 各臂的**体制四列**（`BASE`／`AFTER_M1` 几何／`START_MAX`／`m_ok`）**逐项相同**，不等 ⇒ 该 `pair` 标 `INCOMPARABLE`＋**逐腿点名**；并断言「**判红 = 四件合取**」（`START_MAX=0 ∧ m_ok=1 ∧ r_ok2=0 ∧ APP_ALIVE=yes`）⇒ 单格 `r_ok2` 判红（退化腿/死腿）**必须判违规**。⚠️ **结果侧**（`after_R` 几何／`r_ok`／`r_ok2`／`fgeom`）**只作诊断列、不进 `rc`** —— 它们与被试项**同向**，算进体制就等于**用「保护可比性」的名义否掉可比性**（口径句 `D-G116`）。三态 `REGIME_IDENTITY=PASS|FAIL|NOINFO`：**空台账／缺列／无多臂 pair ⇒ 响亮 `NOINFO`**（**禁静默判等**）。**射程缺口**：`frame-at-base`（T0 装饰几何）现台账不记录 ⇒ `REGIME_NOT_IN_LEDGER` ＋ `REGIME_UNCHECKED=1` 逐字上屏。两极化 **12 例**（`--selftest`）。本步**纯读、零 `dotnet`、秒级**；不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：35 → 36**）
# VERIFYALL-STEPS-DECL: 35 gen=#62   ← `#62` **加一步**（34 → 35）：第 `[35]` 步 `PROC-PATTERN-GUARD`（`TASK-0714` 的牙 `build/MilBridge/tools/proc-pattern-guard.sh`：扫全仓 `*.sh`/`*.py` 里**按模式匹配命令行**收/数进程的调用，**必须能证明排除了自身**（`$$` ∧ `$PPID`；`pgrep -P "$$" -f …` **不算** —— 它只是**集合限定**），否则 `FAIL` 逐处点名 `file:line`；三态 `PROCGUARD=PASS|FAIL|NOINFO`：**缺声明 ≠ 通过**、**红优先于 `NOINFO`**）。牙**进 `build/MilBridge/tools/` 后会被自己扫到** ⇒ `files 161 → 162`（预期，不是树里别的件动了）。**同趟修 6 处真站点**（`tests/**` 里按模式收/数进程者）⇒ 接线那一刻 `partial=0 ⇒ PASS`（与 `full` 数量无关）。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：34 → 35**）
# VERIFYALL-STEPS-DECL: 34 gen=#61   ← `#61` **不动步数**（34 → 34）：本波 = **判据接线/射程波 · 零产品改动**，三件**同时在 `fp_inputs()` 白名单内**（项 `26`/`27`）⇒ **`inputs_fp` 必移**：`5390d01e…`（157 件）→ **`a00bf53a…`**（157 件），**逐件归因成对**（只退 resend ⇒ `8a2c531a…`；只退 revert ⇒ `a72e3290…`；两件都退 ⇒ **逐位回到 before**）⇒ **无第三隐形位移**；仓内 runner **不在覆盖面**（0 命中）⇒ 不参与位移。三件：① `D-G113`（**假旋钮 ⇒ connect**）`build/MilBridge/tools/geom-resend-regression-check.sh` `cd375326b62f7982` → `9e619f18dc864c7f`（`+25/−14`；9 hunks／12 锚）② `TASK-0710`（`--leg=` 旁路 ⇒ **judge**）`build/MilBridge/tools/geom-revert-beat-check.sh` `ee43a703736489a3` → `ade2b2e292df2ace`（`+87/−18`；9 hunks／10 锚；`--selftest` 12/12 → 22/22）③ `TASK-0711`（**方案 A**：**仓内 runner 首写点截断**）`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh` `ca0482bda5043909` → `57180b9fad939748`（`+4/−1`；1 hunks／1 锚）。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：34 → 34（不动）**）
# VERIFYALL-STEPS-DECL: 34 gen=#60   ← `#60` **加一步**（33 → 34）：第 `[34]` 步 `PREREG-FOUR-REQ`（`TASK-0709` 的牙 `build/MilBridge/tools/prereg-four-requirements-check.sh`：判**预登记文档**里「回归判定四要件」在不在；**新增 `PREREG4=NA`** —— 判据节**逐字**声明「本波不做任何回归判定」∧ 全文**无回归判定证据**（`REGRESSION_DECISION=`／`regression-decision-cases.tsv`）⇒ 该要求**对本波 `N/A`**，**与 `PASS` 分开计数**（`na=` 独立一格）＋ 逐件点名；**留声明却引用了证据 ⇒ 仍 `FAIL`**（声明不许当免死金牌）；**缺声明 ∧ 无四要件 ⇒ 照旧 `FAIL`**。本步走**批次门禁形态** `--gate`：早于生效边界 `REQ_EFFECTIVE_WAVE=58` 的件**不判**、逐件点名 `PREREG4_OUT-OF-SCOPE` ＋ 计数 `out_of_scope=`（**永不静默**），批次 `rc` 只由**违规**与**查不动**决定（`fail>0 ⇒ 1`／`noinfo>0 ⇒ 3`），`na`／`out_of_scope` 是**适用性/射程**声明、不进 `rc` —— 否则批次永不为 0、门禁永远接不上、只会把人推向「吞掉 rc」（**真**假绿）。**逐件形态的 `SKIP ⇒ rc=3` 一字未动**。本步**纯读、零 `dotnet`、秒级**；不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：33 → 34**）
# VERIFYALL-STEPS-DECL: 33 gen=#59   ← `#59` **加两步**（31 → 33）：第 `[32]` 步 `GEOM-BEAT`（`D-G112` 的牙 `build/MilBridge/tools/geom-revert-beat-check.sh`：判「`B2`（frame 回到基准）**之后**出现了 `B3`（几何被推到屏尺寸）」这对**事件**的 `Δ_push`，**承重 = `B3` 的有无**、`Δ_push` **只作诊断列**；三态机读行 `GEOMBEAT=PASS|FAIL|NOINFO`）＋ 第 `[33]` 步 `GEOM-RESEND`（`TASK-0210` 的**确定性**回归牙 `build/MilBridge/tools/geom-resend-regression-check.sh`：**按趟印 `BRIDGE=` 分组**、断言修后臂**每腿** `CFG_HIT=0 ∧ GEOWRITE≥1 ∧ r_ok=1`，修前臂只判「**回升 ＋ 成对**」；三态 `GEOMRESEND=`）。两件**纯读、零 `dotnet`、秒级**（现场实测墙钟 **0.05 s / 0.22 s**、峰值 RSS **12.9 / 17.4 MB**，均无网络、无 `X`）；不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：31 → 33**）
# VERIFYALL-STEPS-DECL: 31 gen=#58   ← `#58` **不动步数**（**仪器波 · 零产品改动**：① `docs/PREREG-TEMPLATE.md` 六处行锚定插入（`171 → 212` 行、`+41`/`−0`；D1/D5 两处文字由本波改写）② 新牙 `build/MilBridge/tools/prereg-four-requirements-check.sh`（`57de293df5be263d`，`--selftest` 10/10；**未接线**）③ 牙本体 `regression-decision.py` 三处缺陷修复（`1eda9e3575960cba → 71734fce77842478`：`F-A` ④ 三格前移到判词分支之前／`F-B` 加 `rc=2`＋`REGDEC_REFUSE=repro-inconsistent`（放分母守门之后）／`F-C` 加一行机读并列 `REGDEC_ALPHA`；`--selftest` `22/22 → 26/26`、台账 `7/7` **逐字节不变**）。第 `[29]` 步 `REGRESSION-DECISION` 跑的就是本波修好的那颗牙 ⇒ 冻前该步仍绿；九位**零产品位移**（`pf` 是环成员 `D-G92`）。
# VERIFYALL-STEPS-DECL: 31 gen=#57   ← `#57` **不动步数**（`TASK-0211`：`D-G109` 残余的三处窄 `TOCTOU`／生命周期缺陷落地 —— 站点 A `PostMessageW`「查表→判死→取 pt→入队」收进**同一个临界区**（删 `:848` 与 `:882` 两次放锁，改为 `wpf_queue_push` 之后放一次；两条早退支各自先放锁）；站点 B `PostThreadMessageW` 同形（删 `:896`，`if (!target)` 展开为先放锁再报 1444）；点位 fd `wpf_thread_destroy` 的 `close(wake_read/wake_write)` 改为**锁内先置 -1 再 close**（修前锁外且不置 -1 ⇒ `wpf_queue_wake` 会写已关闭/已复用的 fd 号）。三处**各自独立成对**反极性：只退 A ⇒ A 回 `BROKEN` 而 B 仍 `HELD`；只退 B 反之；只退 fd ⇒ `FDSTALE` 而 A/B 仍 `HELD`。**修法的前提**（由 `premise.py` 盯住）：本修法**只靠递归锁计数成立**（push `:132` 只把深度 2 掉回 1 ⇒ `wake`/`msgflow` 仍在临界区内）。⇒ `win32shim` `2067cb1c97728791` → `d2b76a0a56a41be1`（**327,672 B 不变**；**导出符号 547 不变**）；`pf` 位随整波重建机械位移（`D-G92`，**同尺寸 6,123,520**）。**不加步**（本波零接线）⇒ `VERIFYALL_SELF` 现场 = `names=31 decl=31`（`gen` 与代号一致）。**步数：31 → 31（不动）**）
# VERIFYALL-STEPS-DECL: 31 gen=#56   ← `#56` **加四步**（27 → 31）：第 `[28]` 步 `HYGIENE`（`TASK-0706` 的牙 `build/MilBridge/tools/hygiene-tooth.sh`：四类装置/口径卫生 —— ① `D-G91` 根集合一致性 ② `D-G96` 证据保全 ③ `D-G97`/`D-G42` 口径射程**审计报告** ④ 跨区同 inode；`HYGIENE_SCOPE` **永不为 PASS**（恒 `REPORT`/`NOINFO`）⇒ 它**不**声称全域干净）＋ 第 `[29]` 步 `REGRESSION-DECISION`（`TASK-0705`：回归判定四要件，缺一即 `NOINFO`）＋ 第 `[30]` 步 `UIA-DOOR`（`D-G75` 的牙，**走在册红形态**：该步跑新消费者 `build/MilBridge/tools/known-red-arms-check.sh`，**红 == 在册 ⇒ `rc=0`；红不在册 ⇒ `rc=1`** —— 直接跑 `uia-door-check.sh` 会每趟多一个 ❌，因为 UIA 的门今天**不存在**、红是设计）＋ 第 `[31]` 步 `IME-LANDING`（`D-G76` 的牙，靠本册那条「有意降级」的正式声明才绿）。四件**纯读、零 `dotnet`、秒级**；不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：27 → 31**）
# VERIFYALL-STEPS-DECL: 27 gen=#55   ← `#55` **不动步数**（本波 = **`TASK-0209`：「静默 SEGV／`D-G109`」的产品修法** —— `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82` 的**队列链遍历**（约 `:79` 的 `while (p->next) p = p->next;`）在**坏链**输入下踩到被写坏的节点 ⇒ 进程静默死（应用自己 0 字节输出）；机制 = `sizeof(wpf_thread)==sizeof(wpf_msg_node)==0x40` ⇒ 线程退出 `free` 的块被下一次 `malloc(0x40)` 复用成消息节点／`owner_thread` 悬垂。修法四件（**不是**只加空指针守卫）：F1 零解引用隔离抢救 ＋ F2 具名台账 `[QUEUE_CORRUPT]`（`static`）＋ F3 `wpf_thread_destroy` 摘链 ＋ F3b 置空 `owner_thread`／拒绝投递 `[POSTMSG_DEAD_TARGET]`。⇒ `win32shim` `a6365183fa6d26b9` → `2067cb1c97728791`（**327,672 B**；**导出符号 547 不变**）。两极化**四档成对**：基线 `rc=139` → `fixed` 主队列 +0 → `fixed2` +1（静默改投）→ `fixed3` 返回 0／+0／具名行；件级逐字节回 `a6365183fa6d26b9`。**不加步**（本波零接线）⇒ `VERIFYALL_SELF` 现场 = `names=27 decl=27`（`gen` 与代号一致）。**步数：27 → 27（不动）**）
# VERIFYALL-STEPS-DECL: 27 gen=#54   ← `#54` **不动步数**（本波 = **`TASK-0210`：「桥侧几何重发／接管」**，修 `D-G98` 族；唯一产品改动 = `src/WpfGfx.Linux/Interop/MilPresentation.cs`（`8b44b61f944aeeaa` → `a5ecf1a8faaa2a00`），**唯一改动点 `:1086-1115`**：接既有窗（`OwnsWindow==false`）时**只读尺寸、不写几何**，自建窗分支逐字保留 ⇒ `bridge` `feef049e9d0e313a` → `4e25e4b27d4d5ae1`（**5,028,208 B 尺寸不变**）。W134A 两点承重判据：**① 协议台账那条 `ConfigureWindow` 命中数 12/12 → 0**（旧件 12/12 红 ⇒ 新件 0/12 红）；**② `xobs` 时间轴四跳 → 三跳**（末态 `800x600`）；率（`N=12`/臂）**只作支撑**。**不加步**（本波零接线）⇒ `VERIFYALL_SELF` 现场 = `names=27 decl=27`（`gen` 与代号一致）。**步数：27 → 27（不动）**）
# VERIFYALL-STEPS-DECL: 27 gen=#53   ← `#53` **不动步数**（本波 = **`TASK-0109`：「WM 已死但 EWMH 属性残留 ⇒ 静默丢一次移动」** —— 与 `D-G81` 同族）：把 `wpf_x11_has_ewmh_wm()` 的语义从「**属性在不在**」改成「**属性在 ∧ 那个检查窗此刻真的在树里**」（临时 `XSetErrorHandler` ＋ `XSync` 换回；判活**不按错误码白名单** —— 同一语义「窗没了」`XGetWindowAttributes`/`XGetWindowProperty`/`XQueryTree` 报 `BadWindow(3)` 而 `XGetGeometry` 报 `9`）；两处调用点**同因同修**（`win32_x11.c` 的 `moveresize` ＋ `win32_core.c:653` 的**窗态最大/还原**）＋ 一条**无条件大声诊断** `[WMCHECK_STALE]`（`M3`）；**保持返回 1 的对外契约**。⇒ `win32shim` `bd037229be8db4f6` → `a6365183fa6d26b9`（**导出符号 547 不变**）。W131A 深仪器三态：修前 `green=7 red=5 noinfo=0` ⇒ 修后 **`green=12 red=0`**；两极化闭合（复原源 ⇒ `.so` `cmp` 逐字节回 `bd037229…`）。**不加步**（本波零接线）⇒ `VERIFYALL_SELF` 现场 = `names=27 decl=27`（`gen` 与代号一致）。**步数：27 → 27（不动）**）
# VERIFYALL-STEPS-DECL: 27 gen=#52   ← `#52` **不动步数**（本波 = 「`D-G100` 独立卫生修」＋ **装置/危险处置三件**：跨区硬链断链（`D-G101`，车道 W123A）／`repin-generation.py` 写者改 `temp`＋`os.replace`／两件新牙未接线）。产品侧**唯一**改动 = `D-G100`（`src/WpfGfx.Linux.Native/src/win32_core.c` ＋ `win32_x11.c`）⇒ `win32shim` 位变（**导出符号 547 不变** —— 卫生修不动导出面）；⚠️ **不修 `D-G98`**（真因已转向「过期尺寸约束挡还原」，属 `TASK-0111`）。**不加步**（四件新牙的接线走 `TASK-0708` 仪器波）⇒ `VERIFYALL_SELF` 现场 = `names=27 decl=27`（`gen` 与代号一致）。**步数：27 → 27（不动）**）
# VERIFYALL-STEPS-DECL: 27 gen=#51   ← `#51` **加一步**（26 → 27）：第 `[27]` 步 `NUL-BYTES` —— `D-G82` 的牙（`TASK-9907`）：判「**被判二进制、本意是文本**的源件」，即**声明覆盖面**（扩展名白名单 ＋ 基名清单 ＋ 基名 glob，排除 `upstream/**` 与 `obj|bin|.artifacts|__pycache__|TestResults`）里**不许有真 NUL 字节**（现场 1186 件 / 250.8 MB，`hits=0`）。三态 `NULBYTES=PASS|FAIL|NOINFO` ＋ **内置金丝雀**（每次真跑先自证扫描器没瞎、偏移/行号算得对、声明被遵守）；**纯读、零 `dotnet`、≈0.4 s**；本步不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：26 → 27**）
# VERIFYALL-STEPS-DECL: 26 gen=#50   ← `#50` **加一步**（25 → 26）：第 `[26]` 步 `R-GATE（连续交互）` —— `TASK-0702`：把「连续点击/交互响应」从**仓外仪器**（`$HOME/w47b-click.sh`，`#47` 车道 W47B 留）**收编进仓**并接进门禁（装置 `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh` ＋ **判据唯一实现** `build/MilBridge/tools/r-gate-step.sh`；13 格判据 ＋ 三态机读行 `R_GATE=`；判据**逐格继承** `#49` 预登记 §3 B3 的六格表，见 `docs/WAVE50-PREREGISTRATION.md` §1）。⚠️ 与 `#49` 预登记 §3 B3 那句「并进既有门禁步、步数保持 25」**分叉** —— 本波按任务书 `TASK-0702` 新加一步，四处声明同趟改。**步数：25 → 26**）
# VERIFYALL-STEPS-DECL: 25 gen=#49   ← `#49` **不动步数**（本波产品改源三处：① `D-G57` 文字零墨 —— `build/shims/PresentationCore.HbTextLine.cs` 单段分支改按**计划面**取字形 id ⇒ 页签/按钮/搜索框出墨（`hbtextline` 位变）＋ `build/PresentationCore.Linux/**` 重建（`pc` 位变）；② `D-G72`/`TASK-0008` —— shim `GetMonitorInfoW` 按 `cbSize` 写入 ⇒ 点顶部菜单条不再 NRE（`win32shim` 位变）；③ `TASK-0403` 通道级具名台账进 `MilChannel`/`MilCommandDispatcher` ⇒ **桥必重发**（`bridge` 位变）。仪器侧：`B4`/`R-CSRC` 把 `src/WpfGfx.Linux.Native/**/*.{c,h}` 纳入 `fp_inputs()` ＋ `C2`/`C4` 纳入 `sync-applocal.sh`／`check-applocal-sync.sh`／`applocal-expect.py` ⇒ **`inputs_fp` 必变**（设计性变更，见 `docs/WAVE49-PREREGISTRATION.md` §4）；`B1` 修"选显示号后不复核"；步数**不动**）
# VERIFYALL-STEPS-DECL: 25 gen=#48   ← `#48` **不动步数**（修 `D-G56`：两个 applier 把插桩横幅插在**类属性块与类声明之间** ⇒ 属性挂错类 ⇒ `NameScope` 挂不上 ⇒ BAML 页加载即 abort；**整波后实测动三位** `windowsbase`/`pc`/`pf`；`D-G57` 本波只取证未修）
# VERIFYALL-STEPS-DECL: 25 gen=#47   ← `#47` **不动步数**（修 `D-G55`：`SetCapture/ReleaseCapture` 不派发 `WM_CAPTURECHANGED` ⇒ `Mouse.Captured` 恒不复位；只动 `win32shim` 一位）
# VERIFYALL-STEPS-DECL: 25 gen=#46   ← `#46` **不动步数**（修 `D-G50`／`D-G54`：shim 的**焦点回送**不再被重复翻译 ＋ 弹窗呈现链；动 `win32shim`／`bridge`／`pc` 三位）
# VERIFYALL-STEPS-DECL: 25 gen=#44   ← `#44` **不动步数**（修 `D-G49`：shim 的**鼠标五键 `GetKeyState`** —— 只动 `win32shim` 一位）
# VERIFYALL-STEPS-DECL: 25 gen=#40   ← `#40` **不动步数**（权威件 Debug → Release；`#41` F／`#42` G 同趟）
# VERIFYALL-STEPS-DECL: 25 gen=#39   ← `#39` **不动步数**（权威件配置收敛到"唯一声明处"，阶段 1；值仍是 Debug）
# VERIFYALL-STEPS-DECL: 25 gen=#38   ← `#38` **不动步数**（把 `D-G45` 打通：官方 `System.Windows.Extensions` 包 → 仓内替身）
# VERIFYALL-STEPS-DECL: 25 gen=#37   ← `#37` 加第 `[19]` 步 `THIRD-PARTY`（第三方形态样本，仓内判据）
# VERIFYALL-STEPS-DECL: 24 gen=#36   ← `#36` 加第 `[18]` 步 `FRAME-PRESENCE`（时间分辨的画面读者）
# VERIFYALL-STEPS-DECL: 23 gen=#35   ← **`#35` 不动步数**（本波改的是运行期 interop 面与解析器，未接新步）
# VERIFYALL-STEPS-DECL: 23 gen=#34   ← **`#34` 不动步数**（新读者 `frame-presence-check.sh` 已进仓、**未接线**）
# VERIFYALL-STEPS-DECL: 23 gen=#33
# VERIFYALL-STEPS-DECL: 22 gen=#32   ← **史实行**（`#32` 由 21 → 22：加第 `[16]` 步 `PRODUCT-ENTRY`）
# VERIFYALL-STEPS-DECL: 21 gen=#31   ← **史实行**（`#31` 收官当时的步数；`#31` 由 18 → 21：
#   `[13] HIDDEN-ONLY` ＋ `[14] COLUMN-FLOOR` ＋ `[15] QUOTE-TRAP`）
# VERIFYALL-STEPS-DECL: 18 gen=#30   ← **史实行**（`#30` 收官当时的步数 —— 那一波**一步未加**）
#   ⚠️ 读者 `decl_line()` 取**第一条**（`sed -n … | head -1`）⇒ **最上面那条才是当前口径**；
#   下面两条只为「本波从哪一代起、加了几步」留机读痕迹。⚠️ **史实行只许追加、不许改**（纪律 61 同族）。
# VERIFYALL-STEP-NAMES: 主工程 WpfGfx.Linux | wpf-linux.sln | Commands.Tests | Rendering.Tests | Windowing.Tests | HelloMil.Tests | ManagedLayer.Tests | Presentation.Tests | verify-cmd-layout.py | tline-gate（五臂） | PcLineOracle·Start 列 | FrameProbe-frame | BASELINE-SHA | ARM-LOG-SHA | BUILD-HYGIENE | DEFECT-REGISTRY | VERIFYALL-SELF | FP-INPUTS-HYGIENE | HIDDEN-ONLY | COLUMN-FLOOR | QUOTE-TRAP | PRODUCT-ENTRY | FRAME-PRESENCE | PIPEFAIL-SIGPIPE | THIRD-PARTY | R-GATE（连续交互） | NUL-BYTES | HYGIENE | REGRESSION-DECISION | UIA-DOOR | IME-LANDING | GEOM-BEAT | GEOM-RESEND | PREREG-FOUR-REQ | PROC-PATTERN-GUARD | REGIME-IDENTITY | BASELINE-RATE-GATE | PTS-PAGES | SILENT-HIT-V2 | BAK-COMPLETENESS | REPO-ALIAS | FP-MANIFEST-TEETH | SELFDESC-WIRING | LANE-PATH | ROWS-IDENTITY | X-CENSUS | BOUNDARY-DECL | WIRING-COVERAGE | PARSER-GUARD | PROTO-ATTR
#   **`#28` 收官起 = 17 步**（`#28` 加第 `[11]` 步 `VERIFYALL-SELF`）｜**`#29` 收官起 = 18 步**
#   （`#29` 加第 `[12]` 步 `FP-INPUTS-HYGIENE`：核对 `fp_inputs()` 的覆盖面里**不许出现产物路径**）｜
#   **`#30` 收官起 = 18 步**（**仪器加固波、步数一步未加**）｜**`#31` 收官起 = 21 步**（`#31` 加第 `[13]` 步
#   `HIDDEN-ONLY`、第 `[14]` 步 `COLUMN-FLOOR`、第 `[15]` 步 `QUOTE-TRAP`）｜**`#32` 收官起 = 22 步**
#   （`#32` 加第 `[16]` 步 `PRODUCT-ENTRY`：**走产品入口**的 `M_modifier` 臂 —— `D-G38`/`D-T2-c` 的回归网；
#    它是 `#31` 建起来、`#32` 修好根因之后才敢接的**普通绿步**，**没有"预期红"**）｜
#   **`#33` 收官起 = 23 步**（`#33` 加第 `[17]` 步 `PIPEFAIL-SIGPIPE`：把「`pipefail` ＋ 管道左侧被
#   **`#34` 收官起 = 23 步**（本波**不动步数**：★ 的产物修法＋仪器加固；新读者 `frame-presence-check.sh`
#   **`#35` 收官起 = 23 步**（**不动步数**：本波落第三方原生的正道通道 —— ALC 级钩子 ＋ 5 个映射名 ＋ shim 的 OEM/GDI+ 最小面；
#   **`#55` 收官起 = 27 步**（**不动步数**：`TASK-0209` —— 「静默 SEGV／`D-G109`」的产品修法：`src/WpfGfx.Linux.Native/src/win32_msg.c:57-82` 的**队列链遍历**在**坏链**输入下踩到被写坏的节点（`.NET Finalizer`(`tid=6`) → `HwndWrapper::Finalize()` → `PostMessageW` → `wpf_queue_push+259`）⇒ 静默死、应用 0 字节输出。修法 = 零解引用隔离抢救 ＋ 具名台账 `[QUEUE_CORRUPT]` ＋ `wpf_thread_destroy` 摘链 ＋ 置空 `owner_thread`／拒绝投递 `[POSTMSG_DEAD_TARGET]`（**不是**只加空指针守卫）。`win32shim` `a6365183fa6d26b9` → `2067cb1c97728791`（**导出 547 不变**）。本波**零接线、不加步**。）｜
#   **`#54` 收官起 = 27 步**（**不动步数**：`TASK-0210` —— 「桥侧几何重发／接管」（修 `D-G98` 族）的产品修法：桥在 `OwnsWindow==false`（接既有窗）路径上**只读尺寸、不再把过期的 `target.WindowRect` 写回 X**（`src/WpfGfx.Linux/Interop/MilPresentation.cs` `:1086-1115`）。`bridge` `feef049e9d0e313a` → `4e25e4b27d4d5ae1`（**同尺寸 5,028,208 B**）；`win32shim` **不动**（仍 `a6365183fa6d26b9`）、native 导出仍 **547**。本波**零接线、不加步**。）｜
#   **`#53` 收官起 = 27 步**（**不动步数**：`TASK-0109` —— 「WM 已死但 EWMH 属性残留 ⇒ 静默丢一次移动」的产品修法（与 `D-G81` 同族）：`wpf_x11_has_ewmh_wm()` 的语义升级为「属性在 ∧ 检查窗仍在树中」，`win32_x11.c` 的 moveresize 与 `win32_core.c` 的窗态**两处同因同修**，并加一条无条件大声诊断 `[WMCHECK_STALE]`；`win32shim` `bd037229be8db4f6` → `a6365183fa6d26b9`（**导出 547 不变**）。本波**零接线、不加步**。）｜
#   **`#52` 收官起 = 27 步**（**不动步数**：`D-G100` 独立卫生修 ⇒ `win32shim` 位变、**导出 547 不变**；
#     装置/危险处置三件（跨区硬链断链 `D-G101`／`repin-generation.py` `temp`＋`os.replace`／两件新牙未接线）**都不加步**。
#     本波**零接线**；四件新牙走 `TASK-0708`。）｜
#   **`#51` 收官起 = 27 步**（**加一步**：第 `[27]` 步 `NUL-BYTES` —— `TASK-9907`／`D-G82`：
#     判据 = `build/MilBridge/tools/nul-bytes-check.sh`（声明覆盖面里不许有真 NUL 字节；
#     三态机读行 `NULBYTES=`；**内置金丝雀**每次真跑先自证）。**纯读、零 `dotnet`、≈0.4 s**、
#     不动九位。⚠️ 若同趟把它纳入 `fp_inputs()` 的 `printf` 名单，**必须安排在 `IN_FP_0` 采样之前**。
#     判据与逐例自测（31 例）见 `build/MilBridge/W97A-report.md`。）
#     ⚠️ **本步「绿」的边界（逐字写死，免得被读成「全仓 0 件」）**：本步的绿 = **声明覆盖面内 0 件含 NUL**，
#       **≠** 全仓 0 件；`upstream/**`（6417 件）未测 ⇒ 该格 **`NOINFO`**；11 件**无扩展名 ELF** 只 `DIAG` **不判红**。
#   **`#50` 收官起 = 26 步**（**加一步**：第 `[26]` 步 `R-GATE（连续交互）` —— `TASK-0702`：
#     把「连续点击/交互响应」从**仓外仪器**（`$HOME/w47b-click.sh`）**收编进仓**并接进门禁。
#     装置 = `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh`（私有 Xvfb ＋ 私有 app 目录 ＋
#     `xdotool` 真实节奏 `mousedown`→停 150 ms→`mouseup`，**只落证据**）；**判据唯一实现** =
#     `build/MilBridge/tools/r-gate-step.sh`（13 格判据 ＋ 三态机读行 `R_GATE=`）。
#     判据**逐格继承** `#49` 预登记 §3 B3 的六格表（①…⑥）＋ 承重连做腿⑦ ＋ 像素通道⑧（见 `docs/WAVE50-PREREGISTRATION.md` §1）。
#     **本步不改产品件** ⇒ 九位逐位不动。⚠️ 与 `#49` 预登记 §3 B3 那句「并进既有门禁步、步数保持 25」**分叉**：
#     本波按任务书 `TASK-0702` **新加一步** —— 四处声明（`DECL`／`STEP-NAMES`／本口径句／预登记 H1）**同趟**改。）
#   **`#49` 收官起 = 25 步**（**不动步数**：本波产品改源三处 —— ① 零墨修法落 `hbtextline`（`hbtextline` 位变）＋ `pc` 重建（位变）；
#     ② `D-G72`/`TASK-0008` 的 `GetMonitorInfoW` 修法落 shim C 源（`win32shim` 位变）；③ `TASK-0403` 台账进 `MilChannel`/`MilCommandDispatcher` ⇒ 桥重发（`bridge` 位变）。
#     仪器侧：`B4` 纳入原生 C 源、`C2`/`C4` 纳入三件判据件 ⇒ **`inputs_fp` 必变**；`B1` 修显示号复查。)
#   **`#48` 收官起 = 25 步**（**不动步数**：修 **`D-G56`** —— `patch-windowsbase-dpvalue-trace.py` / `patch-presentationframework-mirror-trace.py`
#     的插入锚上移到**属性块之外**（判据＝`[NS] ATTRCOUNT DependencyObject ≥ 2`、`[NS] scope=NameScope`、Tools 页加载后**进程活着**）；
#     整波后实测动三位 `windowsbase`/`pc`/`pf`（被引件字节进 Roslyn 输入哈希 ⇒ 级联）；**`D-G57`（文字零墨）本波只取证、未修**。)
#   **`#47` 收官起 = 25 步**（**不动步数**：修 **`D-G55`** —— 上游 `MouseDevice` 清捕获状态只认 `RawMouseAction.CancelCapture`，其唯一来源是
#     `HwndMouseInputProvider` 处理 `WM_CAPTURECHANGED`；本 shim 的 `SetCapture/ReleaseCapture` 原本只改软状态、不派发该消息
#     ⇒ `Mouse.Captured` 永不复位 ⇒ **点过一次之后后续点击全被路由到那个控件**（仓内 ⑬ 块 `clickprobe` 两极化读数）。）
#   **`#46` 收官起 = 25 步**（**不动步数**：修 **`D-G50`**（`SetFocus` 已同步派发过焦点消息，X 的**回送**又被翻译一次 ⇒ 主窗口收到第二条 `WM_SETFOCUS` ⇒ 上游 `OnSetFocus` 的 `Keyboard.ClearFocus()` ⇒ `ComboBox` 判"焦点跑了"就 `Close()`）
#     ＋ **`D-G54`**（弹窗那棵树没接上呈现：目标没设根／`ConfigureNotify` 归属到错窗口 ⇒ 弹窗内容零渲染）。）
#   **`#44` 收官起 = 25 步**（**不动步数**：修 **`D-G49`** —— 上游 `Win32MouseDevice:45,61` 判按钮状态**只看**
#     `GetKeyState(VK_LBUTTON) & 0x8000`，而本 shim 的键盘状态表里**从来没有鼠标五键** ⇒ 恒 `Released`
#     ⇒ `ButtonBase` 只 `Focus()` 不激活（真实第三方应用里**复选框不勾、下拉不开、滑块不动**）。
#     修法三处（全在 shim 的 C 源）：新增 `wpf_x11_mouse_keystate()`（问 `XQueryPointer` 的真实指针按键态）
#     ＋ `wpf_keystate_read()` 仅对五个鼠标 VK 改走它 ＋ 头声明。**只动 `win32shim` 一位**（`pc`/`pf` 因整波重建而变）。）
#   **`#40` 收官起 = 25 步**（**不动步数**：权威件从 Debug 切到 **Release** —— 唯一声明 `build/SelfBuiltConfig.props`
#     ＋ 161 处消费点接线 ＋ 五臂重取/重钉（`repin-generation.py`）；同趟落 `#41` F（GDI+ 图像族真解码）
#     与 `#42` G（`D-T4` 定位读数 ⇒ 新缺陷 `D-G48`）。**九位里六位换配置** —— 那是本波的目的。）
#   **`#39` 收官起 = 25 步**（**不动步数**：把"自产件用哪个配置"收敛到**唯一声明处**
#     —— 新 `build/SelfBuiltConfig.props` ＋ 唯一 shell 读取器 `build/selfbuilt-config.sh`（`--check` 两颗牙、
#     `--debt`/`--debt-check` 棘轮）＋ 14 处关键消费点接线；**值仍是 Debug ⇒ 行为等价**，切 Release 属阶段 2/3。）
#   **`#38` 收官起 = 25 步**（**不动步数**：把 `D-G45` 打通 —— 官方 `System.Windows.Extensions` 包
#     换成仓内替身；两条根因 = HintPath 写死 Release ＋ `System.Security.Permissions` 传递依赖；
#     修后 7 工程 + 4 样本 **0 error**，替身进应用输出，`GeneratedInternalTypeHelper` 用例
#     **正极性 PASS / 反极性（官方包）`PlatformNotSupportedException` 崩**。）
#   **`#37` 收官起 = 25 步**（加第 `[19]` 步 `THIRD-PARTY`：**第三方形态**样本 `samples/ThirdPartyMini` ——
#    只经 `build/third-party/WpfLinux.props` 接线、不进 sln、产物复制到**仓外**再跑，判据 = 窗口内颜色数 ≥800；
#    反极性 = 不部署 `libwpfwin32.so` ⇒ `FAIL`。它是"把仓外口头证据变成仓内判据"那一件。）
#   **`#36` 收官起 = 24 步**（加第 `[18]` 步 `FRAME-PRESENCE`：**时间分辨**的画面读者，判据 = 采样窗口内
#   **标记色是否出现过**；`--selftest` 五例覆盖三态。同趟本波还把官方 `System.Windows.Extensions` 包的**运行期**
#   换成 Linux 原生替身（应用器 `patch-swe-linux`）。）
#   并修好 `RtlGetVersion` 的越界写、登记 `D-G44`；新读者 `frame-presence-check.sh` 仍未接线。）
#   **已进仓但未接进本步骤表** ⇒ 步骤数仍 23；接线留给下一波。）
#    SIGPIPE 杀死 ⇒ 判据错」这一族**普查化**；它是**纯读者**、单趟 ≈4.8 s）。
#
#   ./verify-all.sh            # 全部跑
#   ./verify-all.sh --no-x     # 不启动 Xvfb（Windowing/HelloMil 会缺 DISPLAY 而跳过部分用例）
#
# 约定（handoff 并发约定）：
#   * 跑测试一律不带 --artifacts-path —— 各测试项目的 RepoLayout 靠 AppContext.BaseDirectory
#     定位仓库根，改路径会造成大面积假失败（实测炸 2/18/26 条）。
#   * 遇文件锁：dotnet build-server shutdown 后重试 2 次。

set -uo pipefail
# ★ `#39` 阶段 2/3：构建/测试的配置来自**唯一声明**（`build/SelfBuiltConfig.props`）。
#   ⚠️ **本脚本有 `set -u`** ⇒ 不 source 这里，下面每一处 `"$SELFBUILT_CONFIG"` 都会以
#   "未绑定的变量"直接 abort（`#39` 实测：那一版就是这么在第一步死掉的）。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/build/selfbuilt-config.sh"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# ── 【`#75` `TASK-0739`／`D-G139` 修法①：**本趟自起的显示位，退出即按 PID 收**（只加不删）】──
#   现场：本脚本 `[0]` 段自起 `Xvfb` 后**从不回收**（`ppid=1` 孤儿）⇒ 跨波慢性泄漏（`#73` 前
#   主控按 PID 清掉 5 个累积孤儿，最老 13h14m）。
#   ⚠️ **只收本趟自己起的那个 PID**（`XVFB_OWN_PID` 为空 ⇒ 一个都不杀）：
#      · 复用别人几何相符的显示（`X-REUSE=reused`，`D-G59` 的**故意行为**）⇒ 变量为空 ⇒ **不杀**；
#      · `--no-x` ⇒ 变量为空 ⇒ **不杀**。
#   ⚠️ 收进程**只按 PID**（**禁** `pkill`／`pgrep -f`：本仓 `D-G103` 有自匹配误杀事故）。
XVFB_OWN_PID=""
x_reap_own_display() {
  if [ -n "${XVFB_OWN_PID:-}" ]; then
    kill "$XVFB_OWN_PID" 2>/dev/null || true
    XVFB_OWN_PID=""
  fi
}
trap x_reap_own_display EXIT

# ── 2026-09-11 主控补：本脚本**自己把 SDK 补进 PATH**，并在开跑前断言 dotnet 可用 ──
# 【为什么】它历史上被 `setsid bash -c './verify-all.sh …'` 以"没有 dotnet 的 PATH"启动过 ⇒
#   8 个步骤**全部** `rc=127`（命令未找到），最后打印"步骤通过 1 / 失败 8" ——
#   一个**假红**，主控差点据此去查"树是不是坏了"。
# 【教训】缺工具要**当场说清**，不要退化成 8 行 `❌ (rc=127)` 让人去猜。
#   （同源问题另见 handoff 方法学一节：`RC=$?` 写在管道后、`pkill -f` 匹配自己命令行等。）
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
if ! command -v dotnet >/dev/null 2>&1; then
    echo "❌ 找不到 dotnet（当前 PATH=$PATH）" >&2
    echo "   请先 export PATH=\"\$HOME/.dotnet:\$PATH\"（或用本脚本：它已自带这一行，走到这里说明 SDK 真不在 ~/.dotnet）" >&2
    exit 127
fi

DISPLAY_NUM=99
USE_X=1
[ "${1:-}" = "--no-x" ] && USE_X=0

pass=0
fail=0
failed_items=()

# ═══════════════════════════════════════════════════════════════════════════════
# 【`#27` W27B 落地 · **`D-G17`：跳过不许无声、也不许无界**（**只加不删**）】
# ── 缺陷现场（`#26` W26F 查明、主控复核）──────────────────────────────────────
#   本脚本原来的总判据**只有** `if [ $fail -eq 0 ]`（见文件末尾「结论」）⇒ `total_skipped`
#   **只被打印、从不断言**；而 `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs`
#   的 `X11FactAttribute` 在**发现期**就 `Skip = X11Probe.SkipReason`（`!X11Probe.Available` 时，
#   `:69-76`）⇒ 在 `--no-x`（`:14` 明文支持）或**任何没有 X 的机器**上，依赖 X 的那批用例
#   **静默变成 Skip**，整趟仍报「结论：✅ 全部通过」⇒ **一批牙被静默关掉、没有任何东西会红**。
# ── 本块加的四件事 ────────────────────────────────────────────────────────────
#   ① **声明上限表**（静态 / 语料·产物 / 依赖 X 三列）—— 值必须与**测试源码里的发现期跳过来源**
#      一致，逐条出处写在表下；**改了测试的跳过来源就必须同步改这里**（否则下面的断言会报红）；
#   ② 每步把**跳过清单**打到屏上（原来只有一个数字）；
#   ③ 末尾**上限断言**：`本步跳过数 ≤ 静态 + 语料 + (X 不可用 ? 依赖X : 0)`
#      ⇒ 越过上限 = **出现了未声明来源的跳过** ⇒ 本步判失败（`SKIP_GUARD=FAIL`）；
#      ⚠️ 这**不是**「跳过即失败」（预登记 §4 明令禁止误伤：`--no-x` 是受支持的用法）；
#   ④ 依赖 X 的用例被跳过时，**结论区必须逐字带上"射程缩减"**（`SKIP_GUARD=REDUCED`）。
# ── 为什么 `REDUCED` 不等于三态里的 `NOINFO` ──────────────────────────────────
#   三态（`PASS`/`FAIL`/`NOINFO`）是**判据**的词汇；本表是**射程**的注解。
#   `REDUCED` **不冒充红、也不冒充绿**：它**不进** `fail` 计数（把 `--no-x` 做成失败 = 误伤），
#   但**必须**出现在结论区，让"这批牙本趟没行使"**不可能被读成"这批牙通过了"**。
# ── 上限值的来源（逐条可复核；`#27` W27B 现场清点 + 归档交叉核对）──────────────
#   静态（源码里硬写 `Skip=`，与 X / 语料都无关）：
#     Rendering.Tests = 2 ← `Rendering.Tests/DrawingBrushTests.cs:201`（`[Fact(Skip=…)]` 空壳用例）
#                          ＋ `Rendering.Tests/TileFlipTruthTests.cs:240`（`[Theory(Skip=…)]` T2b 登记缺口）；
#     交叉核对：5 份归档的 `Rendering.Tests … 跳过 2` 逐趟相同（`~/wfp-runs/verify-all-24.out`、
#       `w25-verify13b.out`、`w26-verify14.out`、`w26-verify14b.out`、`w26-verify14c.out`）。
#   语料 / 产物（发现期 `Skip`，与 X 无关；判据是"真值/产物在不在"）：
#     Commands.Tests   = 2  ← `Commands.Tests/GeometryOracleTests.cs:35`（缺 `tests/parity/geometry/windows-results.json`）
#                             ＋ `Commands.Tests/GoldenBinaryReplayTests.cs:28`（缺 `tests/U1-golden/*.stream`）
#     Rendering.Tests  = 25 ← `Rendering.Tests/ParityTests.cs:42` 的 `[ParityFact]` ×25（`ParityData.Available`）
#     ManagedLayer.Tests = 1 ← `ManagedLayer.Tests/M7cInputPathTests.cs:476` 的 `[PatchOFact]`（生成物比 dll 新时跳过）
#   依赖 X（**只在 X 不可用时**才计入上限；X 可用时上限里这一项 = 0 ⇒ 此时再有跳过就是"静默关牙"）：
#     Windowing.Tests   = 18 ← `[X11Fact]` ×9 ＋ `[X11Theory]` ×4（`X11RealInputEventTests.cs:102/137/167/202`
#                             的 `[InlineData]` 逐行 2+3+2+2 = 9）
#     HelloMil.Tests    = 1  ← `HelloMil.Tests/HelloMilTests.cs:563` 的 `[HelloMilX11Fact]`
#     ManagedLayer.Tests = 26 ← `[X11Fact]` ×26（`DP1ReproTests`×15、`DispatcherPumpTests`×5、
#                              `M7cRealAttachmentTests`×3、`ManagedWindowTests`×2、`LinuxEnvironmentDiagnosticsTests`×1；
#                              ⚠️ `DispatcherPumpTests.cs:13` 那处是**注释**，不计）
#     Presentation.Tests = 7 ← `M7cChainTests`×2 ＋ `X11WindowWrapTests`×5
#   ⚠️ 口径（报数必须写清）：上表数的是**用例数**（`[Fact]` 级各 1；`[Theory]` 按 `[InlineData]` 行数），
#      不是"属性出现次数"、也不是"文件数"。
declare -A SKIP_CEIL_STATIC=(
  [Commands.Tests]=0 [Rendering.Tests]=2 [Windowing.Tests]=0
  [HelloMil.Tests]=0 [ManagedLayer.Tests]=0 [Presentation.Tests]=0
)
declare -A SKIP_CEIL_CORPUS=(
  [Commands.Tests]=2 [Rendering.Tests]=25 [Windowing.Tests]=0
  [HelloMil.Tests]=0 [ManagedLayer.Tests]=1 [Presentation.Tests]=0
)
declare -A SKIP_CEIL_X=(
  [Commands.Tests]=0 [Rendering.Tests]=0 [Windowing.Tests]=18
  [HelloMil.Tests]=1 [ManagedLayer.Tests]=26 [Presentation.Tests]=7
)
declare -A SKIP_SRC=(
  [Commands.Tests]="[GeometryOracleFact]×1（GeometryOracleTests.cs:35 缺 geometry 真值）+ [GoldenStreamFact]×1（GoldenBinaryReplayTests.cs:28 缺 U1-golden/*.stream）"
  [Rendering.Tests]="静态 2（DrawingBrushTests.cs:201 空壳用例 + TileFlipTruthTests.cs:240 T2b 登记缺口）+ [ParityFact]×25（ParityTests.cs:42 缺 ParityData）"
  [Windowing.Tests]="[X11Fact]×9（X11WindowTests×4 + X11PresentationTargetTests×4 + X11RealInputEventTests×1）+ [X11Theory]×4（InlineData 2+3+2+2=9）—— 依赖 X"
  [HelloMil.Tests]="[HelloMilX11Fact]×1（HelloMilTests.cs:563）—— 依赖 X"
  [ManagedLayer.Tests]="[X11Fact]×26（DP1ReproTests×15 + DispatcherPumpTests×5 + M7cRealAttachmentTests×3 + ManagedWindowTests×2 + LinuxEnvironmentDiagnosticsTests×1）—— 依赖 X；另 [PatchOFact]×1（M7cInputPathTests.cs:476 生成物比 dll 新）"
  [Presentation.Tests]="[X11Fact]×7（M7cChainTests×2 + X11WindowWrapTests×5）—— 依赖 X"
)
declare -A SKIP_OBS=()      # 实测：套件名 → 本趟跳过数（由 run_step 绿分支填写）
SKIP_GUARD=PASS             # PASS / FAIL / REDUCED（射程注解，见上）

# 上限公式的**唯一实现**（每步回显与末尾断言**共用**它 —— 两处各写一遍必然分叉）
skip_ceiling() {
  local suite="$1"
  local st="${SKIP_CEIL_STATIC[$suite]:-0}" co="${SKIP_CEIL_CORPUS[$suite]:-0}" xc="${SKIP_CEIL_X[$suite]:-0}"
  if [ "${X_STATE:-unavailable}" = available ]; then
    echo $((st + co))
  else
    echo $((st + co + xc))
  fi
}

# 把"这一步跳过了什么"打到屏上（只读已取到的计数与声明表，不碰 rc / pass / fail）
skip_manifest() {
  local suite="$1" n="$2" log="${3:-}"
  [ "${n:-0}" -gt 0 ] || return 0
  printf '      ↳ 跳过清单 %s：%s 例（**跳过不许无声**）｜本步上限 = %s 例（静态 %s ＋ 语料 %s ＋ X 项 %s，X_STATE=%s）\n' \
    "$suite" "$n" "$(skip_ceiling "$suite")" \
    "${SKIP_CEIL_STATIC[$suite]:-0}" "${SKIP_CEIL_CORPUS[$suite]:-0}" \
    "$([ "${X_STATE:-unavailable}" = available ] && echo 0 || echo "${SKIP_CEIL_X[$suite]:-0}")" \
    "${X_STATE:-unavailable}"
  printf '         声明来源：%s\n' "${SKIP_SRC[$suite]:-未声明来源（⇒ 会越过上限 ⇒ SKIP_GUARD=FAIL）}"
  if [ -n "$log" ] && [ -f "$log" ]; then
    local details
    details="$(grep -E '(已跳过|Skipped)' "$log" | grep -vE '(已跳过|Skipped):[[:space:]]*[0-9]+' | head -12)"
    if [ -n "$details" ]; then
      printf '%s\n' "$details" | sed 's/^/         · 逐例 /'
    else
      printf '         · 逐例跳过行：本步日志在 `-v q` 下不含（口径：本行只报"套件级计数 ＋ 声明来源"；\n'
      printf '           要看逐例名，需把该套件的 `dotnet test` 提 verbosity —— 属仪器变更，本波不做）\n'
    fi
  fi
}

# 解析 "Passed!  - Failed:     0, Passed:   321, Skipped:     0, Total:   321"
# 与中文 locale 的 "已通过! - 失败:     0，通过:   321，已跳过:     0，总计:   321"
# 输出 "passed skipped total"
parse_counts() {
  local log="$1"
  local p s t
  p="$(grep -oE '(通过|Passed):[[:space:]]*[0-9]+' "$log" | tail -1 | grep -oE '[0-9]+$')"
  s="$(grep -oE '(已跳过|Skipped):[[:space:]]*[0-9]+' "$log" | tail -1 | grep -oE '[0-9]+$')"
  t="$(grep -oE '(总计|Total):[[:space:]]*[0-9]+' "$log" | tail -1 | grep -oE '[0-9]+$')"
  echo "${p:-0} ${s:-0} ${t:-0}"
}

# run_step <名称> <命令...>
run_step() {
  local name="$1"; shift
  local log
  log="$(mktemp)"

  local attempt=0 rc=0
  while :; do
    attempt=$((attempt + 1))
    "$@" > "$log" 2>&1
    rc=$?
    if [ $rc -eq 0 ] || [ $attempt -ge 3 ]; then break; fi
    if grep -qE "MSB3021|MSB3027|being used by another process|The process cannot access the file" "$log"; then
      echo "    ↻ $name 第 $attempt 次遇文件锁，build-server shutdown 后重试"
      dotnet build-server shutdown > /dev/null 2>&1
      sleep 2
      continue
    fi
    break
  done

  if [ $rc -eq 0 ]; then
    pass=$((pass + 1))
    if grep -qE "Total:|总计:" "$log"; then
      read -r p s t <<< "$(parse_counts "$log")"
      printf '  %-28s %s  通过 %-4s 跳过 %-3s 合计 %s\n' "$name" "✅" "$p" "$s" "$t"
      total_passed=$((total_passed + p))
      total_skipped=$((total_skipped + s))
      # ── 【`#27` W27B 落地 · `D-G17`：**把跳过记下来、并当场打到屏上**（只加不删）】─────
      #   改前：跳过数只被**汇总进 `total_skipped`**（末尾一个数字），逐套件的来源、上限、
      #         "这些用例本趟到底有没有行使" 在屏上**一个字都没有**。
      #   现在：记进 `SKIP_OBS[套件]`（供末尾上限断言用）＋ 立刻印**声明来源清单**。
      #   ⚠️ 本行**不碰 `rc`/`pass`/`fail`/`failed_items`** ⇒ 判定语义零改动。
      SKIP_OBS["$name"]="$s"
      skip_manifest "$name" "$s" "$log"
    else
      printf '  %-28s %s\n' "$name" "✅"
    fi
    # ── 【`#26` W26B 落地 · `D-G10`：**绿的时候也要在屏上留下"这一步判了什么"**（只加不删）】──────
    #   ⚠️ 缺口**不在牙齿**：三颗牙齿今天就在自报 —— `pc-line-step.sh:103` 吐
    #     `PCLINE_START_STEP=PASS Start 列 红=0 绿=421 判定行=421 NOINFO=0`、
    #     `frame-step.sh` 的终局行吐 `FRAME_STEP=PASS …`（`#26` W26B 另加 `FRAME_STEP_LEGS=` 逐腿口径行）、
    #     `baseline-sha-check.sh:62-64/:76` 吐 `BASELINESHA=/BASELINEGEN=/BASELINE_BYTES=/BASELINEDUP=`。
    #     缺口在**本函数**：绿分支只印一个 `✅`，而末尾又无条件把日志 `rm -f`（改前 `:89` / `:102`）
    #     ⇒ 口径行**永远上不了屏**（逐字证据：`~/wfp-runs/w25-verify13b.out`，13 步全绿、口径 **0** 行）。
    #   ⚠️ 模式**锚定行首**且只认 `PASS|FAIL|NOINFO` 三种**结论值** ⇒ `红=0 绿=421 判定行=421 NOINFO=0`
    #     这类"键后是数字"的字段**不会被误捞**（实测：真绿 `frame-step` 日志上失败 grep 0 命中 / 本法 1 命中）。
    #   ⚠️ 位置在**内层 `fi` 之后、外层 `else` 之前**（改前行号 `:90` / `:91`；本块自身把行号顶开了）
    #     ⇒ **无论本步有没有 `Total:`/`总计:` 都执行**（四颗牙齿的日志里 `Total:`/`总计:` 各出现 **0** 次
    #     ⇒ 放进上面那个 `if` 里就一行都印不出来）。
    #   ⚠️ 本行**只读 `$log`、只 `echo`**：不碰 `rc`/`pass`/`fail`/`failed_items` ⇒ **判据语义零改动**。
    # ── 【`#31` 主控：行窗 `8 → 12`（**只放宽显示窗，判定语义零改动**）】────────────────────
    #   现场实测（`#31` W31D 报告 §9.1）：新第 `[14]` 步 `COLUMN_FLOOR` 匹配 **7 行**，
    #   **总判行 `COLUMN_FLOOR=` 正好是第 7 个** ⇒ 再涨 2 行就会被 `head -8` **截掉总判**。
    #   而那 2 行是**已经算得出来的**（W31B 把两支 `judged_min:null` 臂写进登记表；
    #   一旦冻结块也声明它们 ⇒ `OVERFLOWED` 逐档行 3 → 5 ⇒ 上屏 9 行）。
    #   ⇒ "总判看不见"是**仪器形态缺陷**（读日志的人会以为这一步只有内档、没有总判）；
    #     放宽到 12 只是给窗留余量，**不改任何一条 `KEY=VALUE` 的语义、不参与 `rc`**。
    #   ⚠️ 与之配对的那条裁定：本波**故意不插**那两行 `# COLUMN-FLOOR … judged_min=none`
    #     （`D-G19` 的「无下限就刻意不声明」；插它还会撞上 W31D §9.2 的**行名前缀不再唯一**）
    #     ⇒ 留给 `#32` 与行名口径（`COLUMN_FLOOR_<臂>_<列>_<键>`）**同趟**改。
    # ★ `#63` W152A／`D-G117` 半②：**择一表把状态吃掉** ⇒ 半可见 ＝ 假绿方向。
    #   修①：值词表纳入 `NA`／`SKIP`／`REPORT`（**本仓工具今天真会印的状态词**，逐字来自各件件头口径）
    #        —— 否则「下一个新状态」照样被吃掉（`PREREG4=NA` 就是这么消失的）。
    #   修②：**汇总/计数/射程** 三类行（`…_SUMMARY`／`…_COUNTS`／`…_SCOPE`）**另开一个出口**
    #        —— 它们承载四态计数与射程边界，形态**不是**「行首即 `KEY=VALUE`」⇒ 旧正则全吃不到。
    #   ⚠️ 显示窗 `12 → 16`：**只放宽显示窗、判定语义零改动**（与 `#31` 那次 `8 → 12` 同口径）；
    #      仍**必须**保证「总判行」落在窗内（本波在冻前 `verify-all` 里逐步骤核对匹配行数）。
    grep -E '^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO|NA|SKIP|REPORT)( |$)|^[A-Z][A-Z0-9_]*_(SUMMARY|COUNTS|SCOPE) ' "$log" | head -16 | sed 's/^/      · 自报口径 /'
  else
    fail=$((fail + 1))
    failed_items+=("$name")
    printf '  %-28s %s  (rc=%d)\n' "$name" "❌" "$rc"
    # 【`#24` P2 车道提出的诊断缺口（主控采纳并补）】原 grep 只认 `error XXnnnn` 与 `Failed`，
    #   而本项目各步的失败**是用 `KEY=FAIL` / `KEY=NOINFO` 自报的**
    #   （`FRAME_STEP=FAIL …`、`PCLINE_START_STEP=FAIL …`、`TLINE_GATE=FAIL/NOINFO …` —— **都不含 `Failed`**）
    #   ⇒ 失败时屏上只有 `❌ (rc=1)`，细节全在被拷走的日志里 ⇒ 补这条。**只加不删**（旧 pattern 原样保留）。
    grep -E "error [A-Z]+[0-9]+|Failed!|Failed [A-Za-z]|[A-Z][A-Z0-9_]*=(FAIL|NOINFO)" "$log" | head -12 | sed 's/^/      /'
    # ── 【`#26` W26B 落地 · **零命中兜底**（只加不删）】──────────────────────────────
    #   上面那条宽 grep **一条都没命中**时，屏上除 `❌ (rc=N)` 一个字都没有 —— 而"**死在打印结论
    #   之前**"的步恰恰是这个形态（`rc=127` 命令没找到、`rc=137` 被杀、`set -u` 崩、参数缺失早退）。
    #   **实测真例**（`#26` W26B）：`bash build/MilBridge/tools/tline-gate.sh --logdir`（缺参数，
    #   `tline-gate.sh:99`）⇒ `rc=3`，它那句 `NOINFO --logdir 缺参数` **不含 `=`** ⇒ 本 grep
    #   **0 命中**、屏上除 `❌` 一字皆无。⇒ 兜底打日志末 12 行（成对读数见 `W26B-report.md`）。
    #   ⚠️ 本行的模式串与上面那条**逐字相同**（改一处必须两处一起改，否则兜底条件与显示条件会分叉）。
    if ! grep -qE "error [A-Z]+[0-9]+|Failed!|Failed [A-Za-z]|[A-Z][A-Z0-9_]*=(FAIL|NOINFO)" "$log"; then
      echo "      ⚠️ 诊断 grep 零命中（本步既没自报 KEY=FAIL/NOINFO、也没报编译器错）⇒ 兜底打日志末 12 行："
      tail -12 "$log" | sed 's/^/      | /'
    fi
    cp "$log" "/tmp/verify-all-$(echo "$name" | tr -c 'A-Za-z0-9' '_').log"
    # ── 【`#26` W26B 落地 · 把被拷走的日志路径印上屏（只加不删）】────────────────────
    #   原来**只 `cp` 不打印路径** ⇒ 屏上有个 `❌` 却**不知道去哪看**（只能去 `/tmp` 里猜文件名）。
    #   表达式与上一行 `cp` 的**逐字相同**（同一处替换、同一个 `/tmp` 落点）。
    echo "      完整日志：/tmp/verify-all-$(echo "$name" | tr -c 'A-Za-z0-9' '_').log"
  fi
  rm -f "$log"
}

total_passed=0
total_skipped=0

echo "======================================================"
echo " WpfGfx.Linux 一键验证"
echo " 根目录: $ROOT   $(date '+%F %T')"
echo "======================================================"

# ---------------------------------------------------------
# [0] Xvfb
# ---------------------------------------------------------
echo
# 🦷【`#52` W126A · 几何守卫的**共同定义**（提到顶层：`[0]` 与 `x_recheck_alive()` **两处复用显示**都要用）】
#   判据：**能连上 ∧ 几何 == `$XREQ_GEOM`**；不符 ⇒ 跳过并点名。规格必须与本闸门自起那行逐字一致。
XREQ_GEOM="1280x1024"
_disp_geom() {                   # _disp_geom <号> ⇒ 打该显示的 `WxH`（连不上/取不到 ⇒ 空）
  DISPLAY=:$1 xdpyinfo 2>/dev/null \
    | sed -n 's/^[[:space:]]*dimensions:[[:space:]]*\([0-9][0-9]*x[0-9][0-9]*\).*/\1/p' | head -1
}
# ── 【`#75` `TASK-0739` 修法②：**链前基线**（本趟任何显示位被起**之前**取）】──────────
#   口径：`D-G139` 要求"链结束后 `ps` 与 `/tmp/.X11-unix/` 必须回到**链前基线**，差异点名 PID"
#   ⇒ 这里落一份**自含**快照（不依赖任何外部文件），末尾由第 `[X-CENSUS]` 步比对。
#   `D-G140` 口径：该步**每次运行重扫**，输出带 `X_CENSUS_AT=` 与 `X_CENSUS_SRC=`。
X_CENSUS_BASE="$(mktemp /tmp/w75-xcensus.XXXXXX)"
bash "$ROOT/build/MilBridge/tools/xvfb-census-check.sh" --snapshot "$X_CENSUS_BASE" \
  || echo "  ⚠️ X_CENSUS_BASE=NOINFO（快照没落成 ⇒ 末尾那一步会响亮 NOINFO，不当绿）"
export X_CENSUS_BASE
export X_CENSUS_OWN_PIDS=""
echo "[0] Xvfb（目标 :$DISPLAY_NUM）"
if [ $USE_X -eq 0 ]; then
  echo "  --no-x：跳过 Xvfb"
else
  # ⚠️ 2026-09-11 主控修（**实测假红**）：原逻辑是「只要 `pgrep -x Xvfb` 有进程就复用」，
  #    然后**无条件** `export DISPLAY=:$DISPLAY_NUM`。实测当时活着的 Xvfb 在 **:98**，而
  #    `DISPLAY_NUM=99` ?? `DISPLAY=:99` 指向**一个没人听的 display** ⇒ ManagedLayer 的端到端
  #    输入用例**假红**（应用 `CreateWindowEx` 抛 1400）、Windowing/HelloMil 大面积跳过。
  #    ⇒ **判据必须落在"这个 display 能不能连上"（`xdpyinfo`），不是"有没有 Xvfb 进程"**；
  #       并且**复用时要复用它真实所在的那个 display**。
  # ── 🦷【`#52` W126A 加：**几何守卫**（授权 = 主控 2026-09-23 10:2x；**更严，不是放宽**）──────
  #   为什么加（现场，非推测）：`#52` 冻前 `verify-all` 报 `Windowing.Tests ❌`（`失败: 3，通过: 41，总计: 44`）
  #   三条全是 `[X11Fact]`/`[X11Theory]`：`EventLoop_DeliversExpose_And_Close`｜
  #   `PresentationTarget_SatisfiesContract`｜`MouseMove_DeliversMotionNotify_WithExactCoordinates(x:473,y:2)`。
  #   根因 = 本段**只验"这个 display 连得上"、不验几何** ⇒ 复用了**别的车道**（W128A）的
  #   `Xvfb :185 -screen 0 1024x768x24`，而本闸门自己起的是 **1280x1024x24**（见下方自起那行）
  #   ⇒ 依赖窗口几何/指针坐标的用例在**别人的几何**上假红。对照：`#51` 时 `用例通过 875`，
  #   本趟 `831`，差 **44 = Windowing 全套件总数**。
  #   ⇒ 判据从「能连上」加严成「能连上 **∧** 几何 == 本闸门要求的 `$XREQ_GEOM`」；
  #     不符的**跳过并点名**（不静默），全都不符就**照常自起自己的**。
  #   ⚠️ 三态机读行（供人/机核对，逐条可见）：`X-REUSE=reused`｜`X-REUSE=skipped-geom-mismatch`｜`X-REUSE=self-started`。
  chosen=""
  if DISPLAY=:$DISPLAY_NUM xdpyinfo > /dev/null 2>&1; then
    if [ "$(_disp_geom "$DISPLAY_NUM")" = "$XREQ_GEOM" ]; then
      chosen=":$DISPLAY_NUM"
      echo "  ✅ X-REUSE=reused display=:$DISPLAY_NUM（:$DISPLAY_NUM 上已有可用 X server，几何 $XREQ_GEOM 相符而复用）"
    else
      echo "  ⏭ X-REUSE=skipped-geom-mismatch display=:$DISPLAY_NUM 实测几何=$(_disp_geom "$DISPLAY_NUM")（空=取不到）≠ 本闸门要求 $XREQ_GEOM ⇒ **不复用它**（几何不符会让 [X11Fact]/[X11Theory] 假红）"
    fi
  else
    # 【`D-G59` 修法①：**数值序**】原先是 `sort -u`（字符串序）⇒ `:10` 会排在 `:66`/`:97` 前面，
    #   跨趟**不可复算**（`#47` 冻后 run2 就是这样选到 `:66` 的死显示）。改成 `sort -n`。
    for d in $(pgrep -a Xvfb 2>/dev/null | grep -oE ' :[0-9]+' | tr -d ' :' | LC_ALL=C sort -n -u); do
      if DISPLAY=:$d xdpyinfo > /dev/null 2>&1; then
        if [ "$(_disp_geom "$d")" = "$XREQ_GEOM" ]; then
          chosen=":$d"
          echo "  ✅ X-REUSE=reused display=:$d（已运行的 Xvfb；几何 $XREQ_GEOM 相符；注意不是 :$DISPLAY_NUM）"
          break
        fi
        echo "  ⏭ X-REUSE=skipped-geom-mismatch display=:$d 实测几何=$(_disp_geom "$d")（空=取不到）≠ 本闸门要求 $XREQ_GEOM ⇒ **跳过它**（几何不符会让 [X11Fact]/[X11Theory] 假红）"
      fi
    done
  fi
  if [ -z "$chosen" ]; then
    # 自起时**避开被占用但几何不符的号**（否则 Xvfb 起不来 ⇒ 制造新的假红）
    _n="$DISPLAY_NUM"
    while DISPLAY=:$_n xdpyinfo > /dev/null 2>&1; do
      _n=$((_n + 1))
      [ "$_n" -gt $((DISPLAY_NUM + 20)) ] && break
    done
    Xvfb :$_n -screen 0 ${XREQ_GEOM}x24 > /tmp/xvfb-$_n.log 2>&1 &
    XVFB_OWN_PID=$!   # 【`#75` `TASK-0739`】本趟自起 ⇒ 退出时按 PID 收
    for _ in $(seq 1 40); do
      sleep 0.25
      DISPLAY=:$_n xdpyinfo > /dev/null 2>&1 && break
    done
    if DISPLAY=:$_n xdpyinfo > /dev/null 2>&1; then
      chosen=":$_n"
      echo "  ✅ X-REUSE=self-started display=:$_n -screen 0 ${XREQ_GEOM}x24"
    else
      echo "  ❌ Xvfb 启动失败（详见 /tmp/xvfb-$_n.log）；X 相关用例将不可信"
      fail=$((fail + 1))
      failed_items+=("Xvfb")
    fi
  fi
  if [ -n "$chosen" ]; then
    export X_CENSUS_OWN_PIDS="${XVFB_OWN_PID:-}"   # 【`#75` `TASK-0739`】豁免名单（空=一个都不豁免）
    export DISPLAY="$chosen"
    echo "  DISPLAY=$DISPLAY（已用 xdpyinfo 验证可连）"
  fi
fi

# ── 【`#27` W27B 落地 · `D-G17`：把"X 到底有没有"变成一个**对判据可见的状态**（只加不删）】──
#   口径与上面 [0] 段**逐字同一条纪律**：不认"有没有 Xvfb 进程"、也不认"命令行给了哪个开关"，
#   只认**这个 `DISPLAY` 现在真能连上**（`xdpyinfo`）—— 因为测试侧的 `X11Probe`（PInvoke
#   `XOpenDisplay`）与 `xdpyinfo` 判的是同一件事。它决定了下面上限表里"依赖 X"那一列算不算数：
#     X_STATE=available   ⇒ 上限里 **X 项 = 0** ⇒ 依赖 X 的用例**不许再被跳过**（再有就是静默关牙）
#     X_STATE=unavailable ⇒ 上限里 **X 项计入** ⇒ 跳过**允许，但必须逐条可见并写进结论**（REDUCED）
X_STATE=unavailable
if [ -n "${DISPLAY:-}" ] && DISPLAY="$DISPLAY" xdpyinfo > /dev/null 2>&1; then
  X_STATE=available
fi
echo "  X_STATE=$X_STATE（判据：xdpyinfo 对 DISPLAY=${DISPLAY:-<未设置>} 成功 ⇒ available）"

# ── 【`D-G59` 修法②：**选定不是终局** —— 整趟要复核】 ───────────────────────────────
#   现场（`#47` 冻后 run2，车道 W49A）：`[0]` 选中了别人遗留的 `:66`，该显示在 `[2]` 之前就死了
#   ⇒ `X_STATE` 仍是 `available`，而 47 例 X 用例**静默变跳过**（只有 `SKIP_GUARD=FAIL` 抓住了它），
#     另有一条端到端用例硬红。⇒ 判据：**每次要用 X 之前都复核一次**；死了就按**数值序**换一个活显示，
#     一个活的都没有 ⇒ `X_STATE=unavailable` ＋ **具名** `X_DIED=1`（**不许把跳过读成通过**）。
X_DIED=0
x_recheck_alive() {   # $1 = 调用点说明（进日志，便于归因）
  [ "${USE_X:-1}" = 0 ] && return 0
  [ -n "${DISPLAY:-}" ] || { X_STATE=unavailable; return 0; }
  if DISPLAY="$DISPLAY" xdpyinfo > /dev/null 2>&1; then return 0; fi
  echo "  ⚠️ X 复核（$1）：DISPLAY=$DISPLAY **连不上了** ⇒ 按数值序重取一个活显示"
  local d2
  for d2 in $(pgrep -a Xvfb 2>/dev/null | grep -oE ' :[0-9]+' | tr -d ' :' | LC_ALL=C sort -n -u); do
    [ ":$d2" = "$DISPLAY" ] && continue
    if DISPLAY=":$d2" xdpyinfo > /dev/null 2>&1; then
      if [ "$(_disp_geom "$d2")" != "$XREQ_GEOM" ]; then
        echo "  ⏭ X-REUSE=skipped-geom-mismatch display=:$d2（X 复核 $1）实测几何=$(_disp_geom "$d2")（空=取不到）≠ 本闸门要求 $XREQ_GEOM ⇒ **跳过它**（换过去会制造 [X11Fact]/[X11Theory] 假红）"
        continue
      fi
      export DISPLAY=":$d2"; X_STATE=available
      echo "  ✅ X-REUSE=reused display=:$d2（X 复核 $1：换到它，几何 $XREQ_GEOM 相符 ⇒ 仍 available）"
      return 0
    fi
  done
  X_STATE=unavailable; X_DIED=1
  echo "  ❌ X 复核（$1）：**没有任何可用 X 显示** ⇒ X_STATE=unavailable ＋ **X_DIED=1**"
  echo "     ⇒ 本趟 X 相关用例会被跳过（**射程缩减**，见 SKIP_GUARD 与结论区）；**这不是绿**。"
  return 0
}
x_recheck_alive "选定之后立即复核"

# ---------------------------------------------------------
# [1] 构建
# ---------------------------------------------------------
echo
echo "[1] 构建"
run_step "主工程 WpfGfx.Linux" dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj -c "$SELFBUILT_CONFIG" --nologo -v q
# ★ `#40`：**样本不在 `wpf-linux.sln` 里**（实测 `grep -c WpfTextDemo wpf-linux.sln` = 0）
#   ⇒ 只建 sln 的话 `samples/*/bin/<声明配置>/` 根本不存在，而**应用门禁与帧读者都以 `--no-build` 跑**
#   ⇒ 它们会在"找不到样本产物"上以 rc=2 失败（`#40` 实测：门禁 rc=2、FRAME-PRESENCE frames=4 max_colors=1）。
#   所以本步同时按**唯一声明**把样本建起来（步名不变 ⇒ 三处声明不受影响）。
build_sln_and_samples() {
    dotnet build wpf-linux.sln -c "$SELFBUILT_CONFIG" --nologo -v q || return 1
    local proj
    for proj in samples/*/*.csproj; do
        [ -f "$proj" ] || continue
        dotnet build "$proj" -c "$SELFBUILT_CONFIG" -m:1 --nologo -v q || return 1
    done
    return 0
}
run_step "wpf-linux.sln"       build_sln_and_samples

# ---------------------------------------------------------
# [2] 测试套件（一律不带 --artifacts-path）
# ---------------------------------------------------------
echo
x_recheck_alive "进入 [2] 测试套件之前"
echo "[2] 测试套件"
run_step "Commands.Tests"  dotnet test -c "$SELFBUILT_CONFIG" tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj   --nologo -v q
run_step "Rendering.Tests" dotnet test -c "$SELFBUILT_CONFIG" tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj --nologo -v q
run_step "Windowing.Tests" dotnet test -c "$SELFBUILT_CONFIG" tests/WpfGfx.Linux.Tests/Windowing.Tests/WpfGfx.Linux.Windowing.Tests.csproj --nologo -v q
run_step "HelloMil.Tests"  dotnet test -c "$SELFBUILT_CONFIG" tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMil.Tests.csproj                --nologo -v q
# M7b 新增：托管层在 Linux 上真的跑起来（Dispatcher 消息泵 + 真 X11 窗口 + WndProc 链 + 输入事件）
# 无 X server 时 **26** 条 `[X11Fact]` 在发现期跳过，不会红
#   〔⏪ `#27` W28B 更正：原写"8 条"是 `M7b` 时代该工程只有 19 例时的旧数；现测 **26**
#     —— 与本文件 `:94`/`:110`/`:117` 的自报上限表逐位一致（**同文件自相矛盾**已消除）。
#     取证：`grep -rn --include='*.cs' -e '^\s*\[X11Fact\]' tests/WpfGfx.Linux.Tests/ManagedLayer.Tests | wc -l` ⇒ 26。
#     ⚠️ 与 `docs/ARCHITECTURE.md:347` 的"8 条需真 server"**不是同一个口径**（那里是"X 依赖总项"）。〕
run_step "ManagedLayer.Tests" dotnet test -c "$SELFBUILT_CONFIG" tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj     --nologo -v q
# M7c 新增：接窗链路（原生导出面 → 真 X11 窗口 → xwd 逐像素；依赖 libwpfwin32.so，缺了会失败而非跳过）
run_step "Presentation.Tests" dotnet test -c "$SELFBUILT_CONFIG" tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj --nologo -v q

# ---------------------------------------------------------
# [3] 命令线格校验（与上游逐 FieldOffset 比对）
# ---------------------------------------------------------
echo
echo "[3] 命令线格校验"
run_step "verify-cmd-layout.py" python3 tests/WpfGfx.Linux.Tests/Commands.Tests/tools/verify-cmd-layout.py

# ---------------------------------------------------------
# [4] 在册红门禁（五臂）
# ---------------------------------------------------------
# 【为什么加这一步（事故 `L26`：判据存在但没人跑 = 没有判据）】
#   本脚本此前只有 2 个构建 + 7 个测试工程 + 1 个 python 校验，**完全不含**
#   `run.sh tline`（1298 行逐例读数）、`CoverageProbe` 的三支 tab oracle、`TextLineProto`。
#   实测后果：`TextLineProto/Program.cs` 里一段 `[IGR]` 代码落盘后**从未被编译过**（`CS1503`），
#   **没有任何自动环节因此变红**。⇒ 把门禁接成第 10 步（步数 9 → 10，**口径已变**）。
# 【五臂日志放哪】`build/MilBridge/arm-logs/`（**硬链接（`ln -f`），既不是拷贝、也不是符号链接** ——
#   拷贝会把 mtime 顶到当下，从而**架空**门禁的"弱配对"判据「日志 mtime ≥ 该世代被测件 mtime」；
#   而**符号链接**会被门禁的 `find "$LOGDIR" -maxdepth 1 -type f` **漏掉** ⇒ 一个日志都扫不到 ⇒
#   全臂 `NOINFO`（实测 `rc=2`）。本行 `#21` 更正：原文写"**符号链接，不是拷贝**"是**错话**，
#   与 `arm-logs/README.md:3-8`、`:60-64` 的实测结论相反）。约定与重绿步骤
#   见该目录的 `README.md`；新世代必须重取五臂日志并重钉 `known-red.json`。
# 【判据】门禁自己是"只读读者"：`PASS`（rc=0）/ `FAIL`（rc=1：未登记失败 或 登记表过期）/
#   `NOINFO`（rc=2：缺臂、口径不一致、**算不出**）。**`NOINFO` 不是通过** ⇒ 本步同样算失败。
#   可用 `WPF_TLINE_ARM_LOGS=<目录>` 覆盖日志目录（临时验证用）。
echo
echo "[4] 在册红门禁（五臂：tline + 三支 tab oracle + textlineproto）"
# 【`#59` W151A】两件几何牙的**语料根**（39 腿，每条腿一个子目录；`#59` 收进仓）。
#   可用 `WPF_GEOM_CORPUS=<目录>` 覆盖（临时验证用）—— 与 `ARM_LOGS` 同一套机制。
GEOM_CORPUS="${WPF_GEOM_CORPUS:-build/MilBridge/geom-corpus}"
ARM_LOGS="${WPF_TLINE_ARM_LOGS:-build/MilBridge/arm-logs}"
# ── 【`#67` W160A（`TASK-0721`）第 `[38]` 步的**证据目录**（"落地前预置"的落点）】──────────────
#   判据支（`--legs`）是**纯读**：它判的是**已落盘**的腿证据。重活（起私有 X ＋ 应用冷启 ＋ 真实点击）
#   **不在门禁里同步跑** —— 它要抢重活槽（前序那批 `waited=1144s`），放同步步就是"每趟 `verify-all`
#   排一个 19 分钟的队"。⇒ 由**波内前置**产出，落在下面这个约定路径。
#   ⚠️ 与 `WPF_GEOM_CORPUS`／`WPF_TLINE_ARM_LOGS` **同一套覆盖机制**（临时验证用）：
#      设 `PTS_EVIDENCE_DIR=<目录>` 即可把本步指向别处（本车道两极化腿用 `WPF_*` 同款惯例）。
PTS_EVIDENCE_DIR="${PTS_EVIDENCE_DIR:-build/MilBridge/tests/PtsPagesProbe/evidence}"
run_step "tline-gate（五臂）" bash build/MilBridge/tools/tline-gate.sh --logdir "$ARM_LOGS"

# ---------------------------------------------------------
# [5] PC 侧行对拍 —— `TextLine.Start` 的冻树牙齿（`#21` 新增；步数 **10 → 11，口径已变**）
# ---------------------------------------------------------
# 【为什么加这一步（事故 `L26` 的同族第二次发作）】
#   `#21` 查出：**真正驱动"产品 `PresentationCore.dll`"的那一层，在冻树回路里没有任何自动红/绿**。
#   证据（三条，都可复算）：
#     ① 第 [4] 步那五支臂**全部直调 `HbTextLineFactory.FormatParagraph`** ⇒ **不经 `HbTextFrame`、
#        不经 PC 的 `TextFormatter`**；`grep -c PcLineOracle build/MilBridge/tools/tline-gate.sh`
#        = **0**（`ARMS=` 是固定五项，且门禁是**只读读者**，不跑 harness）。
#     ② 三支 tab 臂的宿主 `build/MilBridge/tests/CoverageProbe/Program.cs` 里
#        `lineStartOffsetsDip` / `TextLine.Start` 出现 **0** 次 ⇒ **门禁对 `Start` 零判别力** ——
#        语料里一直躺着 **615 个真值**（171 行非零），**从来没有被比较过**。
#     ③ 后果实测：`D-T6-c`（`HbTextLine.Start => 0`，与真机法律 `Start ≡ ParagraphIndent` **相反**）
#        活了很久，**期间没有任何自动环节变红**；`D-T3` 的另一半（严格档 indent）同样只活在报告文字里。
#   ⇒ 把 `PcLineOracle` 的 **`Start` 列**接进冻树回路（判据与"它不覆盖什么"写在
#     `build/MilBridge/tools/pc-line-step.sh` 的文件头，务必与读数一起读）。
# 【两极化已实测，不是声明】修前 pc `f4a454c8fe69cdfe` ⇒ `红=138 / 判定行=421`；
#   修后 pc `e7cabff9417ed380` ⇒ `红=0 / 绿=421`。⇒ 这个判据**能变红**。
echo
echo "[5] PC 侧行对拍（TextLine.Start 列；产品 pc，经 TextFormatter/HbTextFrame）"
run_step "PcLineOracle·Start 列" bash build/MilBridge/tools/pc-line-step.sh

# ---------------------------------------------------------
# [6] 帧列（`FrameProbe`）—— `#24` 新增；步数 **11 → 12，口径已变**
# ---------------------------------------------------------
# 【为什么加这一步（`#21` 那一步的同一族，第二次）】
#   `#23` 实测：`FrameProbe`（`#22` 建的 `D-T6-b` 帧判据探针）在
#   `verify-all.sh` / `tline-gate.sh` / `pc-line-step.sh` / `run.sh` / `arm-logs/README.md`
#   **五处 grep 全 0** ⇒ 它**不在任何冻树回路里**；而它报的残余红**今天无处可登记**
#   （`FrameProbe` 不读任何在册红表）⇒ **欠的是接线，不是登记**（`#23` 的 W23D 结论，主控采纳）。
#   而"帧"这一列在冻树上**没有任何别的牙齿**：第 [5] 步只判 `TextLine.Start` 一列。
# 【本步判**哪一列**：`帧红`，**不是** `红行` —— 这是本步最重要的一条口径】
#   `#23` 已定性：`红行=3` 那 3 条**全是"行数不等"结构族**（`行数我方=4 真值=2`），**不是帧错**。
#   ⇒ 本步断言 **`帧红 == 0`**，**绝不**断言 `红行 == 0`（后者会把结构族吞进来 ⇒ 与 `#23` 的教训相反）。
#   ⚠️ **本步不覆盖**那 3 条结构族红（它们**属主控的登记决定**，`frame-step.sh` 只点名供登记）。
# 【两极化已实测】`#24` 的三条腿（strict / lenient / strict+prefix40）都 `帧红=0`、`判定行=421`、
#   `仪器族NOINFO=0`、`自洽=1`；反极性 = 结构族/帧族可分开点名，且 `frame-step.sh` 自带
#   `判定行>0`（防恒绿退化）与"产物副本 == 权威"自检。
# 【时间预算（主控实测，不是估计）】三条腿全跑 **WALL=428 s（≈7.1 min）、峰值 RSS 692 MB**
#   （干净机器单跑；并发时会到 ~11 min）。⇒ **`verify-all` 的时长预期 +≈7 min**，已写进文档。
echo
echo "[6] 帧列（FrameProbe：帧原点机制；断 帧红==0，不判结构族）"
run_step "FrameProbe-frame" bash build/MilBridge/tools/frame-step.sh

# ---------------------------------------------------------
# ---------------------------------------------------------
# [7] 冻结基线的「整份 sha + 世代」核对 —— `#24` 新增；步数 **12 → 13，口径已变**
# ---------------------------------------------------------
# 【为什么加这一步】`#24` 收官时发现：**顶层结论本身（"当前冻结基线是哪一代、整份 sha 是多少"）
#   是唯一没有牙齿的东西** —— `#23` 的整份 sha 在 `docs/CURRENT-STATE.md` 与
#   `docs/WAVE24-PREREGISTRATION.md` 里**记成了两个不同的值**（`5ccdf74a56955096` /
#   `87ae111462ca2159`），而 `#23` 的内容已被 `#24` 覆盖 ⇒ **今天谁也复算不出来**。
#   这就是纪律 49（"哈希一律脚本算、不许手抄"）的事故现场：手抄错一个字符**没有任何东西会红**。
# 【本步判什么】`baseline-sha-check.sh` 现场重算 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`
#   的 sha16，与 `docs/CURRENT-STATE.md` 里的**机器声明行**
#   `> BASELINE-FROZEN gen=#NN sha16=<hex16> file=<path>` 逐位比对；并核对
#   "文档声明的世代 == 基线文件里**最新**那行 `# RE-FROZEN #NN` 的世代"。
# 【三态，"没声明"必须出声】PASS / FAIL / **NOINFO（文档缺机器行 ⇒ 无从判定，**不是**"一致"）**；
#   `rc=0` **只在两项全 PASS 时**给出 ⇒ NOINFO 也会让本步失败（**防静默绿**）。
# 【反极性已实测】`--selftest` **5/5 PASS**：声明正确 ⇒ PASS｜sha 扰动一位 ⇒ FAIL｜
#   删掉声明行 ⇒ NOINFO｜声明世代写错 ⇒ `BASELINEGEN=FAIL`｜文件里出现更新的世代 ⇒ `BASELINEGEN=FAIL`。
#   ⚠️ 自测**当场抓出两个真缺陷**（扰动值只造出 15 位 ⇒ 只证出 NOINFO、没证出 FAIL；抽取没取首行 ⇒
#   声明缺失时匹配到两行、比较永远失败）⇒ **"反极性自测本身也要被检验"**。
echo
echo "[7] 冻结基线核对（整份 sha + 世代；机器声明行 vs 现场重算）"
run_step "BASELINE-SHA" bash build/MilBridge/tools/baseline-sha-check.sh

echo
echo "[8] 臂日志 sha 核对（结构化登记 vs 现场硬链接件；#26 加）"
run_step "ARM-LOG-SHA" bash build/MilBridge/tools/arm-log-sha-check.sh

# ---------------------------------------------------------
# [9] 构建卫生（`BuildHygiene.props` 的"接线有没有掉"）—— `#27` 新增；步数 **14 → 15，口径已变**
# ---------------------------------------------------------
# 【为什么加这一步】`D-R8` 在 `#21` W21B 报过一次"**props 残差**"，之后 **5 个世代**里
#   "这 40 份 csproj 到底还接不接着仓库根的 `BuildHygiene.props`" **没有任何东西会红** ——
#   机器证：改正 `grep` 过滤器写法后，仓内**任何 `.sh`/`.py` 里 `BuildHygiene` 命中 = 0**
#   （阳性对照 = `baseline-sha-check.sh` 同法能命中）。⇒ 一个**默认静默**的面。
# 【本步判什么】四档合一，任一条不成立即红，且**逐条点名到文件**：
#   ① 名单里每份应有的 csproj **恰有 1 行**规范 `<Import … BuildHygiene.props …>`（少 = 掉线，多 = 重复）；
#   ② 树里**没有未登记的用户**——
#      ⚠️ **口径必须读窄（`#27` W28A 独立取证后主控改；原句写"新加的 csproj 没进名单 ⇒ 抓得住"是写宽了）**：
#      `unlisted` **只在 `grep -cF "$IMPORT_LINE" > 0` 时才可能触发**（`build-hygiene-import-check.sh:198-201`）
#      ⇒ **它只能看见"已经带了规范 `<Import>` 的文件"**。一份**新加的、本该接线却根本没接线**的工程
#      （这正是 `D-R8` 暴露的形态）**这一档看不见** ⇒ 已登记为 **`D-G21`**。
#      🔴 **主控原写在这里的一句被判据推翻了（`#28` W28F 独立复核，2026-09-17）：**
#      原文写"那 42 份**不是**漏接线的暴露工程（主控逐份核过）" —— **错**。按**推导谓词 P1**
#      （「默认 `Compile` glob 生效 ∧ 仓内 `obj|bin` 有 `*.cs`」，谓词脚本 `$HOME/w28f/pred_p1.py`）：
#      **真有一份"暴露却没接线" = `src/WpfGfx.Linux/WpfGfx.Linux.csproj`**（仓内 `obj/Debug/net10.0/`
#      下两份 `*.cs` 在场），而且 **`#21` W21B 自己的表早就标着它 `*** STILL EXPOSED ***`、
#      §4.1 写着"有意挂起给主控裁定"** ⇒ 我的"逐份核过"只核了 **csproj 里字面写的** `BaseIntermediateOutputPath`，
#      **没核"glob 是否生效"** —— 这正是 `D-G21` 说的那类洞，而且**今天就有活的实例**。
#      ⚠️ 另外两处我写错的理由：① "6 份真不暴露"的理由**不是**"SDK 的 `DefaultItemExcludes` 恰好覆盖"
#      （命令行手法下不成立，全仓 `TreatAsLocalProperty` 命中 **0**；该机制**未实测**）—— 真理由是
#      **`EnableDefaultCompileItems=false`**（W21B `:139` 早就这么判）；② "仓内 `.sh`/`.py` 里
#      `-p:BaseIntermediateOutputPath` 命中 **0**" ⇒ **今天机器计数是 1，而那 1 处就是本文件里的注释行**
#      —— **我写下那句话的动作本身毁掉了它的证据**（与 `D-G15` 的"自我 disqualifying"同形）。
#      正确说法："**0 条真命令**"；且 `.md` 里有 61 行手工命令行**可推导** ⇒ 措辞应从"无法推导"收窄成
#      "**推导不完整、不可当权威**"。③ 脚本 `:126-127` 注释里"`obj/` 下的 53 份"**归属写错**：
#      那 53 份全在 **`upstream/`** 下（`obj|bin` 下 `*.csproj` 各 **0**、`.artifacts/` **不存在**）。
#      机器证（主控现场重算）：候选 `*.csproj` **82 份（这是"文件"数！）**（脚本自己的 `collect_candidates()`，含
#      `-not -path '*/upstream/*' -not -path '*/.artifacts/*'` 两处排除 **—— 少了这两处会数到 135，那是错口径**），
#      其中**带规范 `<Import>` 的 = 40**（= 名单，`unlisted=0` 自洽）、**不带的 = 42**。
#      ⚠️ 那 42 份**不是**"漏接线的暴露工程"：其中 6 份自设的是 `$(MSBuildThisFileDirectory)obj\`
#      （**仍在工程目录下**，SDK 自己的 `DefaultItemExcludes` 恰好覆盖 ⇒ 真不暴露），
#      另 2 份只在 Target 里**引用** `$(IntermediateOutputPath)`；而**暴露的真实触发是命令行**
#      `-p:BaseIntermediateOutputPath=<仓外>`（见 `BuildHygiene.props` 头注释）——
#      那条手法在今天仓内 **`.sh`/`.py` 命中 0**（只在车道报告 `.md` 与手工命令里出现过）
#      ⇒ **今天无法用"推导名单"关掉这个洞**，只能靠**声明式名单**（即下面的 ④）。别把 42 读成 42 个缺陷。
#   ③ `BuildHygiene.props` 在**且内容仍带那条排除**（"删整份"与"掏空内容"都抓得住）；
#      ⚠️ **实测只有一条**（`BuildHygiene.props:61` 的 `obj/**;bin/**`，`grep -cF` = **1**）——
#      原句写"那**两条**"是错的（`#27` W28A 查出；`BuildHygiene.props:11-12` 那"两条"是**注释里 SDK 的路径**、
#      而判据本体 `build-hygiene-import-check.sh:71` 只查一条）。**引用时别把 2 当断言数。**
#   ④ 名单 = **内嵌 golden 40 行 ＋ `EXPECT_N=40`**（不用遍历推 —— 遍历推必然与坏件同步缩水，`D-R4` 同族）。
# 【三态，"没声明"必须出声】`rc=0` PASS ／ `rc=1` FAIL（`BHYGIENE_DRIFT=FAIL kind=…  path=…`）／
#   `rc=2` **NOINFO**（名单缺失/不可解析 ⇒ **不是**"一致"）。
# 【反极性已实测】`--selftest` **9/9**：6 例断言"**必须红**"、2 例断言"**必须 `NOINFO`**"、1 例正极性；
#   **每例的红都点名到具体文件**（`kind=DISAPPEARED/DUP/FILE-ABSENT/UNLISTED/PROPS-MISSING/PROPS-CONTENT-LOST`）
#   ⇒ **不是"碰巧红了"**。现场正极性：`BHYGIENE_IMPORT=PASS … files=40 lines=40 list=40`、`rc=0`。
# 【✅ 独立咬合取证（`#27` W28A，**不是作者自测**）】`--selftest` 是"作者的判据在作者的 fixture 上"
#   ⇒ 另派一条车道在**真实那 40 份 csproj 的真副本**上（`cp -p`，**无硬链接**）独立扰动：
#   `E7` 阴性对照 `rc=0` ／ `E1` 删一行 ⇒ `rc=1 DISAPPEARED path=…HbTextLineParity.csproj c=0` ／
#   `E2` 加一行 ⇒ `rc=1 DUP c=2` ／ `E3` 新增未登记工程 ⇒ `rc=1 UNLISTED` ／
#   `E4` 删 props ⇒ `rc=1 PROPS-MISSING` ／ `E5` 掏空内容 ⇒ `rc=1 PROPS-CONTENT-LOST` ／
#   `E6` **合并坏法**（删 props ＋ 摘掉 40 行）⇒ 仍 `rc=1` ／ `E9` 射程探针 ⇒ `rc=1`。
#   **六种坏法全部逐条点名到具体文件**；阴性对照证明"红"不是沙箱噪声；真树**零污染**
#   （3 个件 + csproj 聚合 sha 开工==收工逐位相同，`-links +1` 命中 0）。报告 `$HOME/w28a-report.md`。
#   ⚠️ **一处射程缩减（如实记录，今天不产生假绿）**：副本模式下反向扫描的候选集 = **被镜像的子树**
#   （真树 **82 个 `*.csproj` 文件** → 副本 40 个）；42 份缺口件里带规范 `<Import>` 的 = **0**（E7a/E7b 逐字节相同即证）
#   ⚠️ **别把这里的 82 与 `mention_lines=82` 混为一谈（`#27` W28B 查出）**：那是**两个不同的量撞成同一个数** ——
#      "候选**文件**数 = 82" 与 "含 `BuildHygiene.props` 字样的**行**数 = 82"，今天**恰好都等于 82**。
#      ⇒ **引用时必须写清"文件"还是"行"**（主控已在本块与 `KNOWN-DEFECTS.md` 两处都注明）。
#   ⇒ 只有**整树 `cp -a`** 才与真树等价。
# 【🔴 口径更正（`#27` W27C 查出，主控已改 `KNOWN-DEFECTS.md`）】历史上有 `38/40/42` 三个数：
#   **38** = `#21` W21B 的**动作计数**（当时对、今陈旧，差额 2 份已逐条点名）；**40 = ✅ 现值**；
#   **42 = 错**（42 是"含 `Import` 子串的行"数，其中 2 行是注释散文里的 `<Import` 子串）。
# 【本步**不**判什么（不许读宽）】① **不证**"私有 obj 构建已验证"（`CS0579` 端到端要 `dotnet`）；
#   ② `GetPathOfFileAbove` 的"同名 props 截胡"**不判**（已核仓内只有 1 份、在仓根）。
#   ⚠️ 本步**零 `dotnet`**（纯读）⇒ 可在零-dotnet 车道上跑。
echo
echo "[9] 构建卫生核对（41 份 csproj 的 BuildHygiene 接线；逐条点名；#27 加；#31 更正份数：40 → 41）"
run_step "BUILD-HYGIENE" bash build/MilBridge/tools/build-hygiene-import-check.sh

# ---------------------------------------------------------
# [10] 缺陷编号对账（`D-G15`）—— `#27` 新增；步数 **15 → 16，口径已变**
# ---------------------------------------------------------
# 【为什么加这一步】`D-G15`（`#26` W26F 登记）：**同一个缺陷编号的登记地点是散的** ——
#   `D-G2`/`D-G3` 只在 `docs/CURRENT-STATE.md` 里有陈述，缺陷册 `KNOWN-DEFECTS.md` 里**没有条目**；
#   而 `#26` 之前"**某个编号在哪些文件里、有没有漏登记**"**没有任何机器会红**。
# 【本步判什么】把 `KNOWN-DEFECTS.md`(KD) / `CURRENT-STATE.md`(CS) / `handoff.md`(HO) /
#   `ACCEPTANCE-BASELINE.md`(AB) 四个 **route 件**现场抽出的 `D-` 编号集合，
#   与**声明件** `build/MilBridge/tools/defect-registry-declared.tsv` **双向**比对，**逐条点名**：
#   ① 声明了、而它 `req=` 指名的某个 route 件里**没有** ⇒ `FAIL reason=declared-id-missing-in-route`
#      （= **声明是伪证**）；② route 件里出现、而**声明里没有** ⇒ `FAIL reason=undeclared-id-in-route`
#      （= **新登记的编号没被声明**）。
# 【为什么声明件不是"又一份手工清单"（`D-R4` 同族）】它由本核对器自己的 `--emit` **机械生成**
#   （`req=` 直接由现场出现点推出）⇒ **它不是权威、是一个必须与现场同步的快照**；
#   `DEFREG_DECLDRIFT` 行把"快照之后 route 件又变了"如实打出来（**诊断行，不判红**）。
# 【三态】`rc=0` PASS ／ `rc=1` FAIL ／ **`rc=2` NOINFO**（声明件缺失 / 解析后 0 条 / 有畸形行
#   ⇒ **不许当绿**）。现场绿形态 = `DEFREG=PASS declared=56 route_ids=56`（与 `[9]` 一样是**纯读、零 `dotnet`**）。
# 【⚠️ 两处口径必须读窄（`#27` W27D 自报 + 主控独立复核）】
#   ① `present=` **不进判据**（只作诊断行 `DEFREG_DECLMETA=`）—— 因为它含
#      `known-red*.json` 这类**会被其它车道并发改**的件 ⇒ 判红会变成**假红**。主控裁定：**维持不判红**。
#   ② `--selftest` 的汇总行里 `pass=`/`fail=`/`noinfo=` **数的是"现场 `got=` 值"的个数，不是"通过例数"**
#      ⇒ **别读成"只有 2 例通过"**。权威字段是 **`not-as-expected=`**（今天 = **0**）：
#      它才表示"10 例逐例的**值 ∧ `rc` ∧ `reason`** 全部符合预期"。
#      （`#27` 主控已把这条写进记录；**没有改它的判据** —— 只加不删。）
# 【反极性已实测】`--selftest` **10/10**（`not-as-expected=0`，rc=0）：**逐例同时断言"值"与"`rc`"**
#   （三态 `0/1/2`）—— 其中 **5 例断言"必须红"**（含"声明里有、route 里删掉"与"route 里多一个未声明编号"
#   两个方向）、3 例断言"必须 `NOINFO`"（缺声明件 / 0 条 / 畸形行）、2 例正极性。
#   ⚠️ **主控独立复核（不是照抄它的自报）**：主控用**自己的** python 复算了两侧集合 ——
#   现场并集 **56** / 声明 **56**、**双向差集皆空**（`req` 逐条声明也全对得上）。
#   ⚠️ 复核中主控**自己先错了一次**：第一版匹配器用 `(?<![A-Za-z0-9-])` 做左界 ⇒ 把
#   `TOOTH-D-F1b-ABSENT` 这种**嵌在更长标识符里的编号**全判成"不存在"，一度报出 4 处假违规。
#   真相 = 核对器用**最长匹配**（`TOKRE="\bD-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*\b"`）⇒
#   `D-F1b-ABSENT` 是**独立编号**、`D-F1b` **不会**被它冒充。⇒ **错的复核器比没有复核更危险。**
# 【本步**不**判什么（不许读宽）】不判编号的**语义**是否重复、不扫历史波预登记
#   （`docs/WAVE*-PREREGISTRATION.md`）、不扫车道报告（`build/**/*.md`）、
#   不判"编号定义内容与正文是否一致"。
echo
echo "[10] 缺陷编号对账（声明 ⇔ 四个 route 件；双向点名；NOINFO 不许当绿；#27 加）"
run_step "DEFECT-REGISTRY" bash build/MilBridge/tools/defect-registry-check.sh

# ---------------------------------------------------------
# [11] 门禁自检（步名/步数/口径句 ⇔ 现场）—— `#28` 新增；步数 **16 → 17，口径已变**
# ---------------------------------------------------------
# 【为什么加这一步】`D-G22`：**本脚本自己不在 `inputs_fp()` 覆盖面里、也没有任何自指指纹牙**
#   ⇒ **波中改门禁不会有任何东西红**（`#27` 一趟里它被改了 5 次，全靠人工记账跟住）。
#   ⚠️ 更早的实例：`#24` 收官时写的"**当前期望是 13 步**"在 `#26`/`#27` **连加 3 步**时**毫无反应**、
#   全程零红 ⇒ 正是"**顶层结论本身没有牙齿**"那一族的第二次现场。
# 【本步判什么】把「本脚本头注释里的**机器读声明块**」（`VERIFYALL-STEPS-DECL: <N> gen=#NN` ＋
#   `VERIFYALL-STEP-NAMES: …`）与「现场 `^run_step "` 抽出的**步名多重集合/条数/次序/无重名**」以及
#   「口径句里的数字」三者对齐；任一缺失/分叉 ⇒ `FAIL`，**缺声明 ⇒ `NOINFO`**（`rc=2`，**不许当绿**）。
#   ⚠️ 锚 `^run_step "` 是**故意的**：缩进的、被注释掉的、换成别的函数名的调用**都不计入**
#   ⇒ 那些形态一旦出现就与声明不等 ⇒ 红（这是判据，不是缺陷）。**同名步只有"重名检测"能抓**
#   （把声明与口径句全部配平后，"集合相等"会全绿漏过；`--selftest` 19/19 里有这一例）。
# 【它是什么、不是什么】**不是**自指改写（本核对器**全文只读** `verify-all.sh`）；也**不是**"换了别的文件声明"
#   —— 声明与本体**同一个文件**，改步必同趟改本块。⚠️ **它抓不到"整份 `verify-all.sh` 被换成 `exit 0`"**
#   （牙长在体内）⇒ 那需要**外挂**读者，已登记为 `D-G22` 的残余。
#   ⚠️ 本步**零 `dotnet`、纯读**（单趟 ≤0.01 s）。
echo
echo "[11] 门禁自检（步名/步数/口径句 ⇔ 现场；D-G22；NOINFO 不许当绿；#28 加）"
run_step "VERIFYALL-SELF" bash build/MilBridge/tools/verify-all-step-check.sh

# ---------------------------------------------------------
# [12] 输入覆盖面自检（`fp_inputs()` 里不许有产物路径）—— `#29` 新增；步数 **17 → 18，口径已变**
# ---------------------------------------------------------
# 【为什么加这一步】`D-G31`：`fp_inputs()` 的 `find` **没排除 `obj/`** ⇒ 吃进 **2 份构建生成的文件**
#   ⇒ **每构建一次 `inputs_fp` 就变一次**（`#28` 现场：`close-wave` 报一个值，其后 `verify-all`
#   只跑一次 `dotnet build` ⇒ 当场变另一个值，**期间无人手写任何覆盖面文件**）⇒ 它量的**不是"输入"**。
#   `#28`/`#29` 已把三条 `find` 都加上排除（⚠️ **`-a` 比 `-o` 紧 ⇒ 必须用 `\( \)` 把 `-o` 链括起来**，
#   否则排除只作用于最后一支，是**假修** —— `#29` W29B 实测 `obj/patch-a.py` 仍被吃进）。
# 【本步判什么】断言 **`fp_inputs()` 的覆盖面里 `obj/`、`bin/`、`.artifacts/` 下 0 件**。三态
#   `rc=0` 干净 ／ `rc=1` 发现产物 ⇒ **逐条点名** ／ `rc=2` **`NOINFO`**（取不到覆盖面 ⇒ **不许当绿**）。
# 【⭐ 它怎么取覆盖面（这条设计值得复用）】**拒绝"第二实现"** —— 另写一份 `find` 会与被测者**共模**：
#   覆盖面被偷偷改小时，核对器**同步缩水** ⇒ **该响的时候反而绿**。改用**同码路径拦截**：抽出
#   `fp_inputs()` 的函数体在本进程执行，只拦 `find`/`printf`（shell 函数）与 `sha256sum`
#   （`xargs` 是 exec ⇒ 用 `PATH` 前置同名 shim 收 argv）⇒ **逻辑只有一份**。三条机器守卫：
#   **不扰动**（拦截指纹 == 无拦截指纹）／**完备**（拦截集合 `cmp` 实际交给 `sha256sum` 的 argv 集合）／
#   **生产者白名单**；任一不满足 ⇒ `NOINFO`（**宁可不判，不许假绿**）。
# 【反极性已实测】`--selftest` **16/16**（自带 `TMPDIR`，纪律 63）；**注入反极性成对读数**：同一棵毒树
#   **修前件 `rc=1` 点名 5 条**（2 份真产物 ＋ 3 份注入）／**修后件 `rc=0`**；并复现历史现场
#   `112 = 110 + 2`（正是 `#28` 记的那两份）。
# 【本步**不**判什么】① 该收的没收（覆盖面缺项）；② 产物不在 `obj|bin|.artifacts` 三个名字下；
#   ③ `fp_inputs()` 整体换逻辑（那时它自己也会变 ⇒ 靠人）。⚠️ 另记一条**已登记不改**：`-o` 链尾的
#   `-maxdepth 2` 是**死子句**（`find` 的全局选项**最后一个胜**，实测）—— 今天 0 位移，改动会动覆盖面语义。
#   ⚠️ 本步**零 `dotnet`、纯读**（单趟 ≈0.37 s）。
echo
echo "[12] 输入覆盖面自检（『fp_inputs()』里不许有产物路径；D-G31；NOINFO 不许当绿；#29 加）"
# 🆕 【`#70`（`TASK-0728`）**折叠进本步**】本步从 `#70` 起**不只**判「覆盖面里没有产物」：同趟加上**集合完整性**两条硬判据 —— ① 覆盖面里**每一行都真存在且是常规文件**；② `sha256sum` 的 `stderr` **必须为空**（现场：`#67` 白名单两行**指向不存在的件** ⇒ `xargs sha256sum` 把抱怨打到 `stderr`、`stdout` 仍是部分结果、管道 rc 取自最后一段 `cut` ⇒ 恒 0 ⇒ **形状完好的 64-hex 假指纹**）。触发时**逐条点名**并当场印出 `would_be_fp=`（旧口径会给的那个假指纹）。**判词随之扩写**：`PASS` 行尾多 `missing_n=0 stderr_bytes=0`，`FAIL` 新增 `reason=coverage-member-missing` / `reason=sha256sum-stderr-nonempty`（**产物族仍先判** ⇒ `reason` 不混）。为什么要折叠进本步：本步已握有**被 `cmp` 证完备**的权威成员表（`sha256sum` 的 `argv`），另起一件就必须**再抽一次覆盖面**。
run_step "FP-INPUTS-HYGIENE" bash build/MilBridge/tools/fp-inputs-hygiene-check.sh

# ---------------------------------------------------------
# [13] `D-T5-R` 的牙（`hiddenonly` 四格）—— `#31` 新增；**本步是构建者**
# ---------------------------------------------------------
# 【判什么】用 `build/MilBridge/tests/D5CbrProbe/` 在**关掉快路径**（`--collapsible`）的条件下，
#   把 8 用例 × 2 档（strict/lenient）× 2 模式（catch/nocatch）= **32 格**逐格与**预期判词表**比对；
#   `hiddenonly` 四格必须 `GREEN` **且兜底分支被走到**（兜底计数 0→≥1 的**机制证**），
#   `declaredgap` 四格必须 `RED-LENGTH`（证明 `A3` 码元账守恒**不是空断言**）；
#   任一格不符 ⇒ 本步红。三态：`rc=0` 通过 ／ `rc=1` 红 ／ `rc=2` `NOINFO`（算不出，**不许当绿**）。
# 【为什么它必须接线】`#25` 实测 `grep -r -- 'D5CbrProbe|hiddenonly'` 在 `verify-all.sh` 与
#   **全部** `build/MilBridge/tools/*.sh` 里都是 **0** ⇒ 「缺陷已修好」≠「有牙」⇒ 事故 `L26`
#   （判据存在但没人跑 = 没有判据）。它是 `#28` W28H 交付、`#30` W30D 修两处、`#31` **首次接线**。
# 【成本（实测，不是估计）】`#31` 主控实跑：≈ +102 s／趟、35 次 `dotnet`／趟 ⇒ 它是**构建者**
#   ⇒ 不许与别的构建者并行（内存纪律）；本步位置在 `[12]` 之后，前面的步都跑完了。
# 【射程边界】`A1/A2/A3` 三条腿**从不读任何几何** ⇒ 本步的绿 **≠**「隐形语义已正确」。
echo
echo "[13] 隐形段牙齿（D-T5-R：hiddenonly 四格；32 格对照；本步是构建者；#31 加）"
run_step "HIDDEN-ONLY" bash build/MilBridge/tools/hidden-only-step.sh

# ---------------------------------------------------------
# [14] 列级下限的**外挂读者**（`D-G27`）—— `#31` 新增；**只读、零 dotnet**
# ---------------------------------------------------------
# 【判什么】对冻结块声明的**每一个** (臂, 列, 键) 三元组：① 登记表声明值 == 冻结块声明值；
#   ② 声明值 ≥ **真值语料当场复算**出的下界；③ 语料件整份 sha16 == 冻结块 `# COLUMN-CORPUS` 声明；
#   ④ 门禁机读行**自报**的 `judged_min=`/`released_min=` == 冻结块声明；⑤ `generation.arm_logs`
#   ⇔ 冻结块 `# ARM-LOG-SHA` 行。**只有 ② 回答「这个数该是多少」**：①④⑤ 都是「两处声明互证」，
#   两者可以一起被改；② 把答案锚在**真值语料**上（语料一变，615/194/421 就变）。
# 【它治什么】两颗列级下限 ＋ `arm_logs` 原先**唯一声明处就是登记表自己**（自指）⇒ `#30` 实测
#   `615→421`／`421→400`／`194→0`／两处同降 **四档全 `rc=0`**，且两条机读行归一化后
#   `cmp` **逐字节 IDENTICAL**；同趟改 `arm_logs` 亦能洗绿 `ARMLOG_SHA`。
# 【三态】`rc=0` 全 PASS ／ `rc=1` 有下降/不一致（**点名是哪个键、哪两个数**）／
#   `rc=2` `NOINFO`（缺声明/缺件/算不出 —— **缺项不许计入通过**；**合法上调也判 `NOINFO`**：逼重冻）。
# ⚠️ 它读的 4 类**外挂声明行**就在冻结基线**最新块**里（`# COLUMN-FLOOR`／`# COLUMN-CORPUS`／
#   `# ARM-LOG-SHA`）—— 那几行**必须与本步接线同趟**：只插声明不接线 ⇒ 无人读（空窗）；
#   只接线不插声明 ⇒ 本步 `NOINFO`（第 `[7]` 步 `BASELINE-SHA` 也会红）⇒ 这就是纪律
#   「声明与判据同趟」的现场。
echo
echo "[14] 列级下限外挂读者（『D-G27』：登记表⇔冻结块⇔语料复算⇔门禁自报；NOINFO 不许当绿；#31 加）"
run_step "COLUMN-FLOOR" bash build/MilBridge/tools/column-floor-check.sh

# ---------------------------------------------------------
# [15] 「双引号里的反引号」的机器检查 —— `#31` 新增；**只读、零 dotnet**
# ---------------------------------------------------------
# 【判什么】扫全仓 `.sh`/`.py`，把**双引号内部的反引号**（= 命令替换 ⇒ 实测会**吞字**并往 stderr
#   吐「未找到命令」）逐条点名。**同一陷阱在本项目已现场发生 4 次**（`run-wpfprobe.sh:659`、W28F、
#   `#30` 主控在 `[12]` 的 `echo`、W30C）—— 前四次里**只有一次**被别的牙偶然抓到。
# 【为什么 `bash -n` 不算判据】实测：那几处 `bash -n` **全部静默通过**（语法合法，只是运行行为不对）
#   ⇒ 判据只能是「**把那一行原样抽出来真跑**」（`#31` W31C 逐条做过，12 条全真、0 误报）。
# 【三态】`rc=0` `SHELL_QUOTE_TRAP=PASS traps=0` ／ `rc=1` 逐条点名 ／ `rc=2` `NOINFO`
#   （件集缩小 ⇒ 射程可能缩到零 ／ **内置金丝雀不符**）—— **弄瞎它当场变 `NOINFO`，不是绿**。
#   每趟跑**内置金丝雀**（必命中 4 条 ＋ 必不命中 6 条，逐反引号计恰 8 条）。
# 【边界】Python 不做命令替换 ⇒ `.py` 只报量级（`PY-BACKTICK-FILE`）、**不判红**；
#   定界符带空格的 `<< EOF` 形态不被识别 ⇒ 失败方向是**假红不是假绿**（本仓 43 处 `<<` 实测全部紧邻）。
echo
echo "[15] 引号陷阱自检（双引号里的反引号 = 命令替换；逐条点名；NOINFO 不许当绿；#31 加）"
run_step "QUOTE-TRAP" bash build/MilBridge/tools/shell-quote-trap-check.sh

# ---------------------------------------------------------
# [16] 产品入口臂（**走 `TextFormatter.Create()` ＋ `FormatLine`**）—— `#32` 新增
# ---------------------------------------------------------
# 【判什么】把 `build/MilBridge/tests/ProductEntryArm/` 的 **8 个例**（5 个 `M_modifier` ＋
#   3 个 `F_lat_words` 阴性对照）逐行与真值比对：`PEA_SUM` 的 `red`/`noinfo`、**逐例正控
#   `PEA_POSCTL`**（5 个 M 例必须各走一次**宽松档** —— 严格档在 `TextModifier` 上必 bail）、
#   以及**两条下界**（`EXPECT_CASES=8`／`EXPECT_CELLS=147`）。三态 `rc=0/1/2`。
# 【为什么是这一步、为什么是现在】`#30` 立了纪律 67：「"零产品位移"可能是"**没有一支臂走产品
#   入口**"的副产品」。`#31` 把这支臂建起来并量到真缺陷（`D-G38`：5 例 18 条逐行红、宽度少
#   `110.948667` DIP），但它**当时按设计是红的** ⇒ 不能接线。`#32` 把根因（`D-T2-c`：
#   `CollectLenient` 没收 modifier 覆盖终点）修好之后，它**变成一支普通的绿臂** ⇒ 直接接进来。
#   ⚠️ **本步刻意没有"预期红"**：它在现役树上红 = 产品侧那条链路坏了，**正确动作是去查产品侧**。
# 【与五臂的分工】`tline`/`tab-*` 喂**语料 meta**、**绕过 PC**；本步**走产品入口**（`pc`）。
#   ⇒ 两者**互补**：那五臂量"仪器"，本步量"产品"。
# 【成本】构建 ≈1.6 s ＋ 跑 ≈13 s ⇒ **≈15 s/趟**（内存纪律：所有 `dotnet` 命令 `-m:1`）。
echo
echo "[16] 产品入口臂（TextFormatter.Create()+FormatLine 的 M_modifier 8 例；D-G38/D-T2-c；#32 加）"
run_step "PRODUCT-ENTRY" bash build/MilBridge/tools/product-entry-step.sh

# ---------------------------------------------------------
# [17] 「`pipefail` ＋ 管道左侧被 SIGPIPE 杀死 ⇒ 判据错」的全仓普查 —— `#33` 新增
# ---------------------------------------------------------
# 【判什么】扫全仓 `*.sh`，找出**四判据同时成立**的站点 —— ① 该件 `set -o pipefail`；
#   ② 管线的**非末段**产出不止一次 `write()`（多行 或 很大）；③ 末段**会提前退出**
#   （`grep -q`／`grep -m1`／`head`／`sed …q`／`awk … exit`）；④ 该管线的 **rc 被消费**
#   （在 `if`／`while`／`&&`／`||`／`!` 里）。满足 ⇒ SIGPIPE 把**管道事故**变成**判据错**：
#   `if … | grep -q PAT` 会**静默走 else 支**（假绿）或**凭空走 then 支**（假红）。
# 【⭐ 判据不是正则】：每个候选站点**抽进沙箱真跑**（造"左端多行 ≫ 管道缓冲、右端命中即退"的
#   最小复现），**实测**那条管线在 `pipefail` 下真的非 0 才算 `HIT`；抽不出来跑的降级为 `DIAG`
#   （只报量级、不进 rc）；数据面够不着的单列 `LOW`（可见、不入 rc）。三态 `rc=0/1/2`。
# 【为什么需要它（本仓三次现场）】① `#26` W26C 在 `check-applocal-sync.sh` 的 M 段实测 ≈6.6%/趟；
#   ② `#31`/`#32` 的 `defect-registry-check.sh`：`load1≈7.8` 时 **40 趟里 20 趟伪红**（点名 18 个
#   编号**全在声明表里**）；③ `#33` W33A 的全仓普查：**5 件里共 57 处**，其中
#   `integration-wave.sh:407`（「**0 错 0 警**」的**唯一**检查）与 `:297/:329`（空操作护栏）
#   属**假绿**方向 ⇒ 一个没做事的应用器会被报 ✅、编译器警告会静默通过。
# 【金丝雀】每趟跑内置探针（含"**单行左端 ⇒ 必不命中**"这条阴性对照），不符 ⇒
#   `NOINFO reason=canary-blind`（**不是绿**）；声明表里的例外若已过期（`decl_stale`）也出声。
# 【成本】纯读、零 `dotnet`，单趟 **≈4.8 s**。
echo
echo "[17] 管道 SIGPIPE 普查（pipefail × 非末段多次写 × 末段早退 × rc 被消费；抽出来真跑；#33 加）"
# ── `#36` 波新增：**时间分辨**的画面读者（`D-G45` 的落点）─────────────────────────
#   为什么需要它：判据③原先取"**颜色数最多**的一帧" ⇒ 任何"让颜色数**下降**的变化"被系统性漏掉
#   （`#34` 现场：换 `Content` 之后颜色数从 3960 降到 2556 ⇒ 采用帧永远落在**变化之前**，
#    我据此报过一条**假红**）；而"跑了 N 秒"也不等于"拍了 N 秒"。本步用**标记色在采样窗口内
#   是否出现过**作判据（时间分辨），并把采样窗口印出来。
#   ⚠️ 它是**构建者之外的重步**（≈90 s：跑一次应用门禁的 default 档 ＋ 每 0.5 s 抓帧）。
run_step "FRAME-PRESENCE" bash build/MilBridge/tools/frame-presence-check.sh --app-args=--late-content --seconds=40 --magenta
run_step "PIPEFAIL-SIGPIPE" bash build/MilBridge/tools/pipefail-sigpipe-check.sh
# 【`#37` B：**第三方形态**（仓内判据）—— 把"第三方 app 能渲染"从仓外口头证据变成仓内判据】
#   它从 `build/third-party/WpfLinux.props` 接线、**不进 sln**、把产物**复制到仓外**再跑，
#   并断言"四个 `.so` 与 app 同目录 ⇒ 零环境变量可渲染"（反极性：不部署 shim ⇒ FAIL）。
run_step "THIRD-PARTY" bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25
# ── 【`#50` W84A 加：第 `[26]` 步 `R-GATE` —— 「连续点击/交互响应」的**仓内**判据】────────────
#   为什么加它（`docs/ROUTES.md:73` 的原话是这条欠账）：门禁里与"点击"有关的牙原先只有
#   `run-wpfprobe.sh` 的 `EXPECT=(… "clickprobe:!22D3EE")` —— 那是**负向式**（"关着时不许有测试色"），
#   它**不证明"点了有反应"**；而用户报的正是"点了没反应"（`D-G49`/`D-G55` 两次真缺陷都在这一族）。
#   判据**逐格继承** `#49` 预登记 §3 B3 六格表（①点 ListBox／②点 TextBox／③键入／④点 ComboBox 出下拉／
#   ⑤点弹窗项／⑥mouse-up 后 `cap=none`）＋ 承重连做腿（**窗口内连点三下**，单发点击会假绿 —— `#47` 实测）
#   ＋ 像素通道（下拉打开时测试色 `22D3EE` > 0）。
#   三态：`R_GATE=PASS|FAIL|NOINFO`（`NOINFO` 在门禁里同样是 ❌；`--judge-dir` 只在复核已落盘证据时用，
#   用了它机读行里带 `src=external`）。成本实测 ≈30–40 s/趟（见 `build/MilBridge/W84A-report.md` §5）。
echo "[26] R-GATE：连续点击/交互响应（私有 Xvfb ＋ 真实节奏点击 ＋ 逐格判据）"
run_step "R-GATE（连续交互）" bash build/MilBridge/tools/r-gate-step.sh

# ── 【`#51` W110A 落地：第 `[27]` 步 `NUL-BYTES` —— 「被判二进制、本意是文本」的源件牙（`D-G82`）】──
#   `D-G82`（缺陷册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`）：源件里出现**真 NUL 字节** ⇒
#   `file` 判 `data`／`grep -n` **rc=0 但 stdout 0 字节**（行号静默消失），而本仓**一切判据都建在
#   「文件:行」上**。`#50` W83A 修掉了仓内唯一一件（`wic_proxy.c:289` 的 3 个 NUL），并明确登记
#   "**修了一次、没有牙**" ⇒ 本步就是那颗牙（工具见 `build/MilBridge/W97A-report.md`，接线见 `W110A-report.md`）。
#   判据：声明覆盖面里 `hits` 必须为 0；三态 `NULBYTES=PASS|FAIL|NOINFO`（`NOINFO` 在门禁里同样是 ❌）。
#   **纯读、零 `dotnet`、≈0.4 s**（现场 1186 件 / 250.8 MB）。
#   ⚠️ **「绿」的边界（逐字，与头注释口径句同款）**：本步的绿 = **声明覆盖面内 0 件含 NUL**，**≠** 全仓 0 件；
#     `upstream/**` 未测 ⇒ `NOINFO`；11 件**无扩展名 ELF**（首 NUL 恒在偏移 7）只 `DIAG`、**不判红**。
echo
echo "[27] 源卫生：声明覆盖面里不许有真 NUL 字节（D-G82 的牙；只读、零 dotnet、≈0.4 s；#51 加）"
run_step "NUL-BYTES" bash build/MilBridge/tools/nul-bytes-check.sh
# W137A-0708-BEGIN
# ── 【第 `[28]`–`[31]` 步 —— `TASK-0708`（波 `#56` 仪器波）：四件新牙**同趟**接线】──────
#   为什么加：四件牙此前**牙已备、无人跑**（`build/MilBridge/W119A-report.md` §5、
#   `W117A-report.md` §5、`W121A-report.md` §5 各自登记为"未接线"）。
#   ⚠️ **`UIA-DOOR` 那一步跑的**不是 `uia-door-check.sh` 本身**而是新消费者**
#      `known-red-arms-check.sh` —— 因为 `D-G75` 的 UIA 门今天**不存在**，那件牙
#      `rc=1` **是设计**；直接 `run_step` ⇒ 每趟多一个 ❌（冻结脚本 `nfail == _expected_red`
#      当场失败）⇒ 必须走仓内既有的「**在册红**」形态（样板 = `tline-gate.sh` 的
#      `GATE_REASON=all-as-registered`：**红 == 在册 ⇒ 绿；红不在册 ⇒ 红**）。
#   ⚠️ 且**只加 `known-red.json` 的 `entries[]` 是惰性的** —— 门禁的臂是硬编码 5 臂
#      （`tline-gate.sh:124 ARMS=(…)`），`arm ∉ ARMS` 的条目**永远不会被取到**、且
#      无任何未知臂告警（现场机械核）⇒ 必须有消费者，本步就是。
echo
echo "[28] 装置/口径卫生：根集合一致性 ＋ 证据保全 ＋ 口径射程 ＋ 跨区同 inode（TASK-0706 的牙；只读、零 dotnet、秒级；#56 加）"
run_step "HYGIENE" bash build/MilBridge/tools/hygiene-tooth.sh
echo
echo "[29] 回归判定四要件：两臂同刻 ＋ 成对归因臂 ＋ 复现性 ＋ Fisher 双尾（TASK-0705 的牙；纯 python、零 dotnet；#56 加）"
run_step "REGRESSION-DECISION" python3 build/MilBridge/tools/regression-decision.py --cases build/MilBridge/tools/regression-decision-cases.tsv
echo
echo "[30] 在册红臂（不在门禁 5 臂内的那些）：UIA-DOOR / D-G75 的门今天不存在（纯读、零 dotnet；#56 加）"
run_step "UIA-DOOR" bash build/MilBridge/tools/known-red-arms-check.sh
echo
echo "[31] IME 落点 ＋ 那道『巧合关闭的门』的在册声明（D-G76；纯读、零 dotnet；#56 加）"
run_step "IME-LANDING" bash build/MilBridge/tools/ime-landing-check.sh
# W151A-0110-BEGIN
# ── 【第 `[32]`–`[33]` 步 —— `TASK-0110`（**改题后**）＋ `D-G112`：两块新牙**同趟**接线】──────
#   为什么加：两块牙 `#56` 收官后**牙已备、无人跑**（车道 `W149A` 落地并各自登记为「未接线」，
#   见 `~/w149a/report.md` §5 与 `~/w149a/criteria.md`）。"接线"必须与**四处声明同趟**改，
#   否则第 `[11]` 步 `VERIFYALL-SELF` 当场红（`count-mismatch` ＋ `name-set-differs`）。
#
#   ⚠️ **题面前提已被推翻（`D-G112`）**：`TASK-0110` 原题问"WM 为什么不把退出最大化的几何收回去"，
#      而台账 70 腿里**红腿 27/32 的 `frame` 回过基准**、**41–86 ms（median 81）后被桥顶回**；
#      旧结论是**欠采样伪影**（`176 ms` 级口径把整对事件吞掉）。
#      ⇒ 改题后判的是 **`B2 → B3` 这对事件的时刻差**，**不是**"某一拍 `frame ≠ client`"。
#
#   ⚠️ **承重 = `B3` 的有无，`200 ms` 不是"Δ>200 ⇒ 红"**：现场实测修前臂 `Δ_push` 落在
#      **64.4–104.3 ms（median 76.25）**，**全部 ≤ 200 ms** ⇒ 若按"慢 ⇒ 红"判，
#      **修前臂 16/16 会判绿 = 假绿**。那次方向冲突已由主控裁定冻结（`~/w149a/criteria.md` §7.1），
#      牙里**已删掉那条反向开关**（能造出假绿的旋钮不许留）。
#
#   ⚠️ **反极性是两块各自成对、禁止合并判一次**：
#      · `[32]` 成对 = 修前臂 `feef049e9d0e313a` **红 16/17** ∧ 修后臂 `4e25e4b27d4d5ae1` **绿 19/19**；
#        **边界例 1 条**（`W134A-B1-M1R2-2`，修前臂上"无顶回"）**必须单列、不许静默剔除**；
#      · `[33]` 成对 = 修后臂**每腿** `CFG_HIT=0 ∧ GEOWRITE≥1 ∧ r_ok=1` ∧ 修前臂**回升率 0.941 ≥ 0.70**
#        （**只判"回升＋成对"，禁止"每腿必命中"**）；反例 1 条单列、`POL-OLD-*` 命名陷阱 2 条点名。
#
#   ⚠️ **语料不许指仓外**：两件牙都以 `--corpus=<root>` 取「每条腿一个子目录」的目录树。
#      实测（W151A）：`--corpus=<不存在>` / `--corpus=<仓内 arm-logs（无腿目录）>` ⇒ 两件**都** `rc=2`
#      （`GEOMBEAT=NOINFO reason=no-input` / `GEOMRESEND=NOINFO reason=no-input`）
#      ⇒ 若指 `$HOME/w134a/run` 这类**仓外可变态**，这两步会在语料被换/被轮转/换机器时**变机器相关的红**
#      （`D-G31` 家族：判据的结论取决于环境此刻长什么样 ⇒ 它不是判据）。
#      ⇒ 本波把语料**收进仓**：`build/MilBridge/geom-corpus/`（39 腿，`cp -p` 真复制）。
#        可用 `WPF_GEOM_CORPUS=<目录>` 覆盖（与 `WPF_TLINE_ARM_LOGS` 同一套临时验证机制）。
#
#   ⚠️ **`GEOM_CORPUS` 是"仓内相对路径"**：本脚本 `:152-153` 已 `ROOT=…` ＋ `cd "$ROOT"`。
#
#   ⚠️ **两件都不读** `_NET_FRAME_EXTENTS`（现场全台账 `233/233 = 0,0,0,0` 的**恒真谓词**）——
#      恒真谓词进判据就是假牙（纪律 47 家族）。
echo
echo "[32] frame/client 时序（事件锚定）：B2（frame 回到基准）之后出现 B3（几何被顶回屏尺寸）⇒ 红（D-G112 的牙；只读、零 dotnet、秒级；#59 加）"
run_step "GEOM-BEAT" bash build/MilBridge/tools/geom-revert-beat-check.sh --corpus="$GEOM_CORPUS"
echo
echo "[33] 桥侧几何重发的确定性回归（按趟印 BRIDGE= 分组；TASK-0210 的牙；只读、零 dotnet、秒级；#59 加）"
run_step "GEOM-RESEND" bash build/MilBridge/tools/geom-resend-regression-check.sh --corpus="$GEOM_CORPUS" --verify-arms

# ── `#60` W152A（`TASK-0709`）第 `[34]` 步：预登记四要件（**批次门禁形态**）────────────────────
#   ⚠️ 本步走 `--gate` 而不是裸 `--glob`：裸 `--glob` 因「早于生效边界的件 ⇒ `SKIP` ⇒ `rc=3`」
#      **每趟都会多一个 ❌**（`run_step` 把任何 `rc≠0` 判 `❌`）。`--gate` 下那些件**不判但逐件点名**
#      （`PREREG4_OUT-OF-SCOPE` ＋ `out_of_scope=`），批次 `rc` 只由**违规**与**查不动**决定。
echo
echo "[34] 预登记四要件（判据节里四要件在不在；不做回归判定的波按 --gate 标 N/A；只读、零 dotnet、秒级；#60 加）"
run_step "PREREG-FOUR-REQ" bash build/MilBridge/tools/prereg-four-requirements-check.sh --gate --glob 'docs/WAVE*-PREREGISTRATION.md'
# W152A-0709-END
echo
echo "[35] 按模式收/数进程的自匹配牙（D-G103 族／TASK-0714；只读、零 dotnet、无 X、秒级；#62 加）"
run_step "PROC-PATTERN-GUARD" bash build/MilBridge/tools/proc-pattern-guard.sh --repo="$ROOT"

# ── `#63` W152A（`D-G116`）第 `[36]` 步：跨臂体制同一性（**只读、零 dotnet、秒级**）────────────
#   ⚠️ 它**只判「可比性」**（体制是否同一 ∧ 判红是否四件合取），**不**重判 `GEOM-BEAT`/`GEOM-RESEND`
#      的结论；射程边界逐条见 `docs/WAVE63-PREREGISTRATION.md` §5。
echo
echo "[36] 跨臂体制同一性（体制四列逐项相同 + 判红=四件合取；revert 牙的语料；只读、零 dotnet、秒级；#63 加）"
run_step "REGIME-IDENTITY" bash build/MilBridge/tools/regime-identity-check.sh --corpus="$GEOM_CORPUS"
# W152A-DG116-END
# ── `#64` W157A（`D-G118`）第 `[37]` 步：基线率闸（**只读、零 dotnet、秒级、确定性**）────────────
#   ⚠️ 射程：本步判的是「**在册速率还能不能用来定 `N`**」（`D-G118`），**不**重判任何回归结论；
#      跑的是 `--cases`（**确定性合成用例**）⇒ **不会随被测世界漂移而红/绿**（这正是接线要求）。
echo
echo "[37] 基线率闸（在册速率带时间窗否 / 同窗现取基线率 / 闸是否被排除；确定性两极化；只读、零 dotnet、秒级；#64 加）"
run_step "BASELINE-RATE-GATE" bash build/MilBridge/tools/baseline-rate-gate.sh --cases build/MilBridge/tools/baseline-rate-cases.tsv
# W157A-0717-END
# ── `#67` W160A（`TASK-0721`／`D-G122`）第 `[38]` 步：`PTS` 两页（23／24）的**页级降级必须还在** ──────
#   【它挡的是什么】`#50` 的 `A1`＋`A2`＋`A3` 把「切富文本 23／流文档 24 必死 `rc=134`」降级成
#     「页级**可见**降级（洋红占位）＋ 具名行 ＋ 进程不死」—— **而这两页当时不在任何在跑门禁里**
#     （现场机械核：`grep -rn 'FlowDocument|RichTextBox|TASK-0007' verify-all.sh build/integration-wave.sh`
#      = **0 命中**、`known-red.json` 5 条无一相关）⇒ 那套止损**不可回归**：将来谁"顺手"把 A2/A3
#     改回／删掉，**没有任何自动读数会响**。口径句 `D-G122`：**凡以「止损/降级」形态落地的修法，
#     必须同时落地一条能把它咬回来的牙 —— 否则它是不可回归的**。
#   【本步判什么】判据的**唯一实现**在 `build/MilBridge/tools/pts-pages-guard.sh`（承重 `G1`–`G10`、
#     装置自证 `G11/G12` 走 `NOINFO`、`D1–D6` 只诊断）—— 本行**不重复任何判据**，只做三件事：
#     ① 报「证据目录在哪、有几条腿」（**把「预置」这件事印在屏上**：跑腿不是本步做的）；
#     ② 报「本趟这棵树上，跑腿装置在不在」（**接线缺口必须可见** —— 装置若还没落仓，
#        本步会 `NOINFO` 而屏上只有一个"证据目录不存在"，**分不清是没跑腿还是没装置**）；
#     ③ 把牙的三态 `rc` 如实转成本步的 `rc`（**`NOINFO` 在门禁里同样是 ❌**）。
#   【射程（如实划界）】只保证「止损还在」，**不**保证「该被真实现」（真缺口 `TASK-0302`）；
#     抓不到「下游真缺口被顺手 stub」。**反转文本**在 `~/w156a/w67guard/criteria-flip.md`
#     （本波只引用、不改写）。
echo
echo "[38] PTS 两页（23/24）的页级降级必须还在（D-G122 的牙；判据支纯读、零 dotnet、秒级；#67 加）"
echo "      · 证据目录（**预置**：本步不跑腿）：$PTS_EVIDENCE_DIR"
echo "      · 装置（跑腿那一半，由波内前置执行）：build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh"
if [ -x build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh ]; then
  echo "      · 装置在位：build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh"
else
  echo "      · ⚠️ 装置**不在位**（build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh）"
  echo "        ⇒ 这也解释了「证据目录不存在」：本趟**没人跑得了腿**（接线缺口，不是产品红）"
fi
if [ -d "$PTS_EVIDENCE_DIR" ]; then
  n_leg="$(find "$PTS_EVIDENCE_DIR" -maxdepth 2 -type f -name 'leg_*.env' 2>/dev/null | LC_ALL=C sort | wc -l | tr -d " ")"
  echo "      · 证据落地：leg_*.env = ${n_leg:-0} 件（判据要 2 条：k=23 与 k=24）"
else
  echo "      · 证据落地：**目录不存在** ⇒ 牙会响亮 NOINFO（**这不是绿**，也不是产品红）"
fi
run_step "PTS-PAGES" bash build/MilBridge/tools/pts-pages-guard.sh --legs "$PTS_EVIDENCE_DIR"
run_step "SILENT-HIT-V2" bash build/MilBridge/tools/silent-hit-v2-check.sh --cases build/MilBridge/tools/silent-hit-v2-cases.tsv --expect 12
run_step "BAK-COMPLETENESS" bash build/MilBridge/tools/bak-completeness-step.sh
run_step "REPO-ALIAS" bash build/MilBridge/tools/repo-alias-check.sh --allow build/MilBridge/repo-alias-allow.tsv
# W167A-0725-END
# ---------------------------------------------------------
# [42] 指纹清单的牙（`TASK-0724` —— `fp-manifest-teeth-check.sh` **首次接线**）—— `#70` 新增
# ---------------------------------------------------------
# 【判什么】`build/close-wave.sh` 的 `fp_inputs()` 是**手写输入指纹**：件表被污染（续行里插注释 ⇒
#   参数表下半截被吃掉）时，最终 `inputs_fp` **仍是一个形状完美的 64 位十六进制**，而管道 rc 取自
#   最后一段 `cut` ⇒ **恒 0**。`#65` 落仓的牙 `fp-manifest-teeth-check.sh` 就是为这一族做的（逐行形状
#   断言 ＋ 件数对账），但它**从未被任何一步调用**（"在册但没牙床"）⇒ 正常运行恒
#   `NOINFO reason=no-manifest`、`rc=2`。本步把它接上。
# 【清单从哪来】`verify-all.sh` **不在** `fp_inputs()` 覆盖面 ⇒ 步本体里的 `--expect N` 是
#   **与生产路径无关**的显式常数（漏改 ⇒ `files-n-mismatch` 红，方向安全）；清单本身由驱动件
#   `fp-manifest-step.sh` 以**同码路径拦截**从 `close-wave.sh` 现取（函数体一字未改）。
# 【成本】纯读、零 `dotnet`、秒级（现测 ≈0.4 s）；不写 `$R`。
# 【射程边界（如实写）】本步判「**清单/指纹有牙**」：清单形状合法 ∧ 件数与声明相符 ∧ 名字都真存在
#   ∧ `sha256sum` `stderr` 空。它**不**判「清单**内容正确**」—— 判不了"该收的没收"（覆盖面缺项）。
echo
echo "[42] 指纹清单的牙（清单逐行形状 ＋ 件数对账；D-G120②；NOINFO 不算绿；#70 加）"
run_step "FP-MANIFEST-TEETH" bash build/MilBridge/tools/fp-manifest-step.sh --expect 212
run_step "SELFDESC-WIRING" bash build/MilBridge/tools/selfdescription-wiring-check.sh
run_step "LANE-PATH" bash build/MilBridge/tools/lane-path-check.sh
run_step "ROWS-IDENTITY" bash build/MilBridge/tools/rows-identity-check.sh
run_step "X-CENSUS" bash build/MilBridge/tools/xvfb-census-check.sh --baseline "${X_CENSUS_BASE:-/dev/null}"
run_step "BOUNDARY-DECL" bash build/MilBridge/tools/boundary-decl-check.sh
run_step "WIRING-COVERAGE" bash build/MilBridge/tools/wiring-coverage-check.sh
run_step "PARSER-GUARD" bash build/MilBridge/tools/parser-guard-check.sh
run_step "PROTO-ATTR" bash build/MilBridge/tools/proto-attribution-check.sh --cases build/MilBridge/tools/proto-attribution-cases.tsv --expect 18
# W168A-0724-END
# W160A-0721-END
# W154A-0714-END
# W151A-0110-END
# W137A-0708-END

echo
echo "======================================================"
echo " 步骤通过 $pass  ❌ 失败 $fail"
echo " 用例通过 $total_passed  跳过 $total_skipped"
# ── 【`#27` W27B 落地 · `D-G17`：**跳过数的上限断言 ＋ 写进结论区**（只加不删）】────────────
#   判据（与文件上方声明块逐字一致）：对每个报过 `Total:` 的套件，
#     `跳过数 ≤ 静态上限 ＋ 语料上限 ＋ (X_STATE=unavailable ? 依赖X上限 : 0)`
#   ⇒ 越过上限 = **本趟出现了声明表里没有的来源的跳过**（新加的 `Skip=`、新写的自建
#     `FactAttribute`、被静默摘掉的用例…）⇒ `SKIP_GUARD=FAIL` ⇒ **计入 `fail`**（`rc=1`）。
#   ⇒ 依赖 X 的用例在 **X 可用时**被跳过（上面已判定"X 项 = 0"）同样 ⇒ `FAIL`：
#     这正是 `D-G17` 那条"**要求了 X，却把一批牙静默关掉还报全绿**"。
#   ⚠️ 依赖 X 的用例在 **X 不可用 / `--no-x`** 时被跳过 ⇒ **不判失败**（预登记 §4：不许误伤），
#      但必须 `SKIP_GUARD=REDUCED` ＋ 结论区逐字写明"射程缩减" ⇒ **不许无声**。
#   ⚠️ 本块**只加**：不动上面那行 `结论：…`（"只加不删"的机器证见 `W27B-report.md` §3），
#      新增的判词一律另起一行印。
skip_summary=""
skip_violations=""
skip_why_x=0
skip_why_undeclared=0
skip_x_skipped=0
skip_x_suites=0
skip_x_corpus_max=0
if [ "${#SKIP_OBS[@]}" -gt 0 ]; then
  for skip_suite in $(printf '%s\n' "${!SKIP_OBS[@]}" | sort); do
    skip_n="${SKIP_OBS[$skip_suite]}"
    [ "${skip_n:-0}" -gt 0 ] || continue
    skip_st="${SKIP_CEIL_STATIC[$skip_suite]:-0}"
    skip_co="${SKIP_CEIL_CORPUS[$skip_suite]:-0}"
    skip_xc="${SKIP_CEIL_X[$skip_suite]:-0}"
    # 「依赖 X 的套件里到底跳了多少」**无条件**统计（与 X 可不可用无关）——
    # 这样"X 明明可用、这些用例却跳了"这一行数据在屏上是**看得见**的，不靠推断。
    # ⚠️ 口径（不许把第三读成第一）：这是**套件级**计数，日志在 `-v q` 下不含逐例名 ⇒
    #   "这 N 例里有几例是 X 类、几例是语料类（如 `[PatchOFact]`）"**本趟不可区分**；
    #   可区分的只有**上界**：语料类不超过 `SKIP_CEIL_CORPUS`。
    if [ "$skip_xc" -gt 0 ]; then
      skip_x_skipped=$((skip_x_skipped + skip_n))
      skip_x_suites=$((skip_x_suites + 1))
      skip_x_corpus_max=$((skip_x_corpus_max + skip_co))
    fi
    skip_ceil="$(skip_ceiling "$skip_suite")"
    skip_summary="${skip_summary}${skip_suite}=${skip_n}/${skip_ceil} "
    if [ "$skip_n" -gt "$skip_ceil" ]; then
      if [ "$skip_xc" -gt 0 ] && [ "$X_STATE" = available ]; then
        skip_violations="${skip_violations} ${skip_suite}(跳过 ${skip_n} > 上限 ${skip_ceil}：X 可用却被跳过)"
        skip_why_x=1
      else
        skip_violations="${skip_violations} ${skip_suite}(跳过 ${skip_n} > 上限 ${skip_ceil}：声明表里没有这个来源)"
        skip_why_undeclared=1
      fi
    fi
  done
fi
# reason 只报**类别**（每类一次），不随越界套件数重复
skip_why=""
if [ "$skip_why_x" -eq 1 ]; then skip_why="${skip_why}x-required-but-skipped "; fi
if [ "$skip_why_undeclared" -eq 1 ]; then skip_why="${skip_why}undeclared-source "; fi
if [ -n "$skip_violations" ]; then
  SKIP_GUARD=FAIL
  fail=$((fail + 1))
  failed_items+=("SKIP-GUARD")
  echo " ⚠️ 跳过越界（= 静默关牙，判据不当绿）：${skip_violations}"
elif [ "$X_STATE" != available ] && [ "$skip_x_skipped" -gt 0 ]; then
  SKIP_GUARD=REDUCED
fi
echo " D-G17 跳过汇总（实测/上限；上限 = 静态＋语料＋X_STATE=$X_STATE 的 X 项）：${skip_summary:-无跳过}"
echo " SKIP_GUARD=$SKIP_GUARD x_state=$X_STATE x_died=$X_DIED x_suite_skipped=$skip_x_skipped x_suite_units=$skip_x_suites x_suite_corpus_max=$skip_x_corpus_max total_skipped=$total_skipped violations=${skip_violations:-none} reason=${skip_why:-none}"
# 【`D-G59` 修法③】**"中途死过显示"必须具名**（`x_died=1`）：否则读者会把"重取成功、继续跑完"读成"这一趟 X 一直好好的"，而实际上有一段用例是在**另一个**显示上跑的（换显示 = 换了环境）。
if [ $fail -eq 0 ]; then
  echo " 结论：✅ 全部通过"
else
  echo " 结论：❌ 失败项：${failed_items[*]}"
fi
# ── 【`#27` W27B 落地 · `D-G17`：**射程必须写在结论区里**（只加不删）】──────────────────────
#   为什么这一行必须存在：上面那句 `结论：✅ 全部通过` **是既有判词、一字未动**（"只加不删"），
#   而 `--no-x`／无 X 的机器上"全部通过"**并不等于"全部判据都行使了"** ⇒
#   本行紧贴着结论印出**射程**，让"这批牙本趟没行使"**不可能被读成"这批牙通过了"**。
if [ "$SKIP_GUARD" = REDUCED ]; then
  echo " 射程：⚠️ **缩减** —— 依赖 X 的套件本趟共跳过 ${skip_x_skipped} 例（${skip_x_suites} 个套件）。"
  echo "       口径（不许把第三读成第一）：这是**套件级**计数，log 在 \`-v q\` 下不含逐例名 ⇒"
  echo "       其中**至多 ${skip_x_corpus_max} 例**可能是语料/产物类（如 \`[PatchOFact]\`）而非 X 类，本趟**不可逐例区分**。"
  echo "       这些用例的判据**没有被行使**（上面那个 ✅ 只覆盖已行使的判据）；清单见上方「跳过清单」与「D-G17 跳过汇总」。"
elif [ "$SKIP_GUARD" = FAIL ]; then
  echo " 射程：❌ 跳过**越过声明上限**（静默关牙；reason=${skip_why:-none}）：${skip_violations}"
fi
echo "======================================================"
exit $((fail == 0 ? 0 : 1))
