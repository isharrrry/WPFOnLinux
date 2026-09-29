# P1-LEGS-ACCOUNTING（`t153` · W73：装置件「静默少样本」修法 —— 跑前独占号 ＋ 有界等待 ＋ 被拒/被跳样本数计入输出）

> **来源**：`t150` 上报（九样本首轮只 1 个拿到读数；成因＝上一趟自己起的 Xvfb 未即时收净 ⇒ `device=NOINFO reason=display-occupied` **立即拒跑**，而失败形态是**静默少样本**）。队长判为**「未触达/未计数」族**（同族：裁定三十七 (d)、裁定三十八）。
> **写域**：`build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh` ＋ 本件。**未碰** `src/**`（`t151`／`t152` 在飞）／`build/MilBridge/tools/**`／`docs/**`／任何 `.cs`／两枚哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`；**`session_inner.sh`／`legs-to-env.py` 一字未改**（⇒ `CLICK`／`FAILLINE`／`FRAME`／`PHASE` 等列**既没改也不会改**，见 §3）；相位位 `degraded` 未翻；未 `git add/commit/push`；未跑整趟门禁／未构建。

## §1 收尾必交①④：件态 ＋ 号分配规则（现取原文）

| 件 | 改前 sha16 / 行数 | 改后 sha16 / 行数 | `numstat` | 删行 |
|---|---|---|---|---|
| `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh` | `863ef62f1761005a` / 208 | **`0ab03550a11a3e0a`** / 299 | **`101 10`** | **10**（＝旧 `display-occupied` 立即拒跑块 9 行 ＋ 转换器 `|| exit 1` 那 1 行，逐行可追溯；写前像 `~/w281-scribe/t153/bak/run-pts-pages-legs.sh.pre-t153`，写前 `h=1`、`mode 644` 不变） |

**号分配规则（现取原文，逐字）**：
```
PTS_DISPLAY_BASE="${PTS_DISPLAY_BASE:-:231}"
PTS_DISPLAY_SPAN="${PTS_DISPLAY_SPAN:-9}"
PTS_DISPLAY_WAIT_SECS="${PTS_DISPLAY_WAIT_SECS:-30}"
```
- **规则**：候选号 ＝ `$PTS_DISPLAY_BASE` 起、`$PTS_DISPLAY_SPAN` 个（默认 `:231`..`:239`）⇒ **取最小空闲号**（`occupied_by()`＝扫 `/proc/*/cmdline` 找**非本链**进程是否含该号 token）⇒ **同一进程内连续多趟不会互相踩号**（＝`t150` 手工用 `:231`..`:239` 拿到 9/9 的规则，现在自动化）；
- **向后兼容**：调用方**显式**给 `PTS_GUARD_DISPLAY=:<n>` ⇒ **只用该号**（被占时走下面的等待/失败）；
- **有界等待**：被占 ⇒ 每 0.5s 重扫、最多 `$PTS_DISPLAY_WAIT_SECS`（默认 30）秒 ⇒ **等不到 ⇒ 显式失败并点名**（`DISPLAY_WAIT … state=timeout` ＋ `device=NOINFO reason=display-not-free` ＋ 计数行 ＋ `LEGS_RUNNER=FAIL` ＋ `exit 2`）—— **绝不静默继续**；
- **新增测试缝**：`SESS="${PTS_INNER:-$SELF_DIR/session_inner.sh}"`（默认值不变；夹具可注入**桩**）。

## §2 收尾必交②：三条判据成对读数（**真跑**；夹具＝仓外桩 `~/w281-scribe/t153/fx/stub_session.sh`）

夹具环境（每趟同一条命令、只改括号里那一个变量）：`W67_WORK=~/w281-scribe/t153/fx/w`、`PTS_GUARD_APPDIR=~/w67-work/app`（**装置自己的装配命令**已把它同步到权威：现取 `SYNC-APPLOCAL=PASS … drift=0`）、`PTS_INNER=<桩>`。

| # | 构造 | 现取读数（原文片段） |
|---|---|---|
| **(a) 正极** | 号空闲，**连续 3 趟**（默认 `base=:231 span=9`） | 三趟均 `rc=0`：`DISPLAY_PICK display=:231 rule=lowest-free(base=:231 span=9) waited_ms=0`；**`LEGSCOUNT requested=2 obtained=2 refused=0 reasons=none display=:231 rc=0 session_rc=0 conv_rc=0`**；`LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`；`DEVICE_REAP state=clean`（xvfb/xfwm 各一条）；`arm_A/leg_*.env` ＝ **2** ✓ |
| **(b) 反极（故意占号）** | 先占住 `:231`（`bash -c 'while :; do sleep 1; done' :231`，现取 `cmdline` 含 `:231`）＋ `PTS_DISPLAY_SPAN=1` ＋ `PTS_DISPLAY_WAIT_SECS=2` | `rc=2`；**点名**：`DISPLAY_WAIT display=:231 state=waiting occupant_pid=3707693 rule=lowest-free(base=:231 span=1)（先等上一趟自己的 Xvfb 收净，最多 2s）` ⇒ `DISPLAY_WAIT display=:231 state=timeout waited_ms=2000 occupant_pid=3707693` ⇒ `device=NOINFO reason=display-not-free display=:231 waited_ms=2000 occupant_pid=3707693`；**计数可见**：**`LEGSCOUNT requested=2 obtained=0 refused=2 reasons=display-not-free=2 display=:231`**；`LEGS_RUNNER=FAIL reason=display-not-free display=:231 occupant_pid=3707693` ⇒ **"看起来跑过、实际 0 样本"这种输出**已不可能（请求 2／实得 0／被拒 2 逐格可见）✓ |
| **(b′) 换号（不踩号）** | 同一占用不变，只把 `PTS_DISPLAY_SPAN` 由 1 改成 9 | `rc=0`；**`DISPLAY_PICK display=:232 rule=lowest-free(base=:231 span=9) waited_ms=0`**（⇒ 被占的 `:231` 被跳过、**不踩号**）；`LEGSCOUNT requested=2 obtained=2 refused=0 display=:232`；`LEGS_RUNNER=PASS` ✓ |
| **(c) 因果对** | 把 (b) 的占用**按 PID 解除**（`kill -9 3707693`）⇒ **同一条命令**（仍 `span=1`） | `rc=0`；`DISPLAY_PICK display=:231 rule=lowest-free(base=:231 span=1) waited_ms=0`；`LEGSCOUNT requested=2 obtained=2 refused=0 reasons=none`；`LEGS_RUNNER=PASS` ✓ ⇒ **唯一变量（占用）变化引起 FAIL→PASS 翻转** |

**计数行的覆盖面（本趟的真实收成）**：计数走 **`EXIT` trap**（`_legs_count`），因此**前置拒绝／转换器失败／中途退出**都会印：本趟实测就撞到一次**前置拒绝**（`PTS_GUARD_APPDIR` 指向私存而私存当时 `drift=1`）⇒ 输出里出现 `device=NOINFO reason=app-stale` ＋ **`LEGSCOUNT requested=2 obtained=0 refused=2 reasons=session-missing=1,no-leg-env=1,runner-rc=2`** ＋ `LEGS_RUNNER=FAIL`（**旧形态在此会静默 exit 2、零计数**）✓；转换器失败也不再 `|| exit 1` 静默退出（新增 `LEGS_TO_ENV_FAIL rc=… ` 具名行 ＋ 归入计数）。

## §3 收尾必交③：(d) 既有列**字段名与形状未变**的证据（逐列对拍）

- **既有输出语句被删数 ＝ 0**（现取：对"改前/改后"两份件的 `echo|printf` 语句集合做 `diff`，`^<` 行数 ＝ **0**）⇒ 既有判词行**一条没删**，新增全是**新增行**。
- **逐列计数对拍（改前/改后相等）**：`X_UP=` 3/3｜`LEGS: ` 2/2｜`AUTHORITY: ` 1/1｜`device=memok` 1/1｜`DISPLAY_LEASE_FILED=` 1/1｜`POSTSHIM: ` 1/1｜`SESS_LOGDIR=` 2/2 ✓。
- **腿级机读列（`CLICK`／`FAILLINE`／`FRAME`／`PHASE`／`FILE=`／`APP_RC=`／`FIVE_STABLE_G*`）**：它们由 **`session_inner.sh`（产出）＋ `legs-to-env.py`（转换）** 负责，而**本件对这两件一字未改**（⇒ `git diff` 为空 ⇒ 列名与形状**结构性不变**）；本件只**新增** `DISPLAY_PICK=`／`DISPLAY_WAIT=`／`DEVICE_REAP=`／`LEGSCOUNT=`／`LEGS_RUNNER=`／`LEGS_TO_ENV_FAIL=` 六类**新行**（机器可读 key=value，互不冲突）。
- **既有语义未动**：`LEGS:`／`X_UP=`／`device=`／`AUTHORITY:`／`DISPLAY_LEASE_FILED=`／`SESS_LOGDIR=`／`POSTSHIM:` 的**文本与位置**不变（现取 §3 第一行对拍）；**旧唯一出口码语义变了一点、如实记**：转换器失败与"实得<请求"现在走**具名 FAIL**（`exit 1`）而非裸 `exit 1`；前置拒绝**仍 `exit 2`** ⇒ 上位读数机检口径（`rc`）**不变**。

## §4 收尾必交⑤⑥：载体自证 ＋ 主动点名

- **守卫/门禁**：本件**未动** `build/MilBridge/tools/**` 与守卫 ⇒ `PTS_GUARD`／`PTSGAP`／`SHELL_QUOTE_TRAP` 读数与本件无关（**未跑**它们）；**已跑**（收工现取）：`REPORTID=PASS files=275 ids=2208 declared=224`；`DEFREG=PASS declared=224 route_ids=224` ＋ **`DECLDRIFT=0 keys=-`**。
- ⏪ **收工时刻的补充读数（诚实归因；现取）**：**本席那几趟**（(a) 三趟／(b)／(b′)／(c)）的**跑前与跑后**读数均为 `/tmp/.X11-unix/` ＝ **`X0 X1`** ✓（中途出现的 `X232`／`X233` 等**本席自己的**无主 socket 已按 PID 收净后清掉）；收工前另有一次读数含 **`X238`** —— 现取其持有者 `Xvfb :238` 的**父进程属同一 harness 下的另一个 shell**（`ppid` 指向 `node dsh web`，**不在本席进程链上**）且该进程**现已退出** ⇒ **那不是本件那几趟**，本席**未动它**（纪律：进程只按 PID 收、不得杀别人的装置）。**收工终局现取** ＝ `. .. X0 X1`。
- **显示位收净（硬约束要求）**：**跑前** `/tmp/.X11-unix/` ＝ `X0 X1`；**跑后**（含中途几趟失败/被拒）＝ **`X0 X1`** ✓（中途出现的 `X232`／`X233`／`X236` 已按**PID 收净**并清掉**无主** socket，命令逐条记在读数日志；**未用** `pkill`／`pgrep -f`）。
- **装置装配副作用（如实记）**：为让前置 1/1b 通过，本席跑了装置**自己的**装配命令 `bash build/MilBridge/tools/sync-applocal.sh --force ~/w67-work/app`（**仓外私有暂存**）⇒ 现取 `SYNC-APPLOCAL=PASS … drift=0`（这不是改仓件，且是装置正常准备步骤）。
- **`cell=#1`**：`run-pts-pages-legs.sh` **在覆盖面内**（现取命中 **1**）⇒ 按第 `28` 条本应登记；派单硬约束**明令不碰** `HANDOFF-NEXT.md` 的 `cell=#1` ⇒ **本件有意未登记**；指纹本席现取 ＝ `fa5b819f4ea666be343fb0437f7f9e72aa98c2317304adaa941fe931fa33c5ef`。
- **主动点名 `NOINFO`（没跑/没核/取不到）**：① **未跑真腿**（桩替代 `session_inner.sh`；本件只验**会计与号分配**，**没有**验真应用/N1/N3 面）⇒ 「九样本真跑 9/9」这句话**本件不声称**（`t150` 的 9/9 是它自己的读数）；② 未跑整趟门禁／未构建；③ `CLICK`／`FRAME` 等列的新鲜度未核（不动它们 ⇒ 无需核）；④ 未核 `~/w67-work/app` 与 authority 的**长期**一致性（只需当趟一致 ✓ 已核）；⑤ 载体以外的两个中介件（`session_inner.sh`／`legs-to-env.py`）**本件未改**（`numstat` 空）。

**本件自证**：`head -n -1 build/MilBridge/P1-legs-accounting-report.md | sha256sum | cut -c1-16` ＝ 595f94744d006b9c（末行不计入自身）
