# P1-dg188 报告（`t68`）—— 修装置互斥 ＋ 占位保护名义化（`D-G188`）：官方腿路跑通、闸仍拒外人、旁路不再静默

**本件口径**：**只增不改**（两份被改装置的**原判据逐字留档**在件内注释里，一字未删；`KD` 为追加条目；`HANDOFF-NEXT.md` 为行尾 dated 追写）；读数一律**捕获式取 `rc`**（`cmd >out 2>err; echo $?`，不接管道 —— 会话第 `27` 条）；每格带**亚秒 `ts=`**；`NOINFO` 具名（§9）。**未跑整趟门禁**；重活腿走**重活槽**（`~/heavy-slot.sh`，`HEAVYSLOT=ACQUIRED/RELEASED` 有据）。

## 0. 一句话
`session_inner.sh` 的 B-9 占用闸加「**官方调用者自有显示位（lease）放行**」＋ 对 `WPF_X11_DIR` **双边检查** ⇒ ① 官方 `PTS-PAGES` 腿路由 **`rc=1`／`PARSE-ERR`／零 `leg_*.env`** 变 **`rc=0`／两腿出件**；② **外人占用仍 `rc=3`**（`DISPLAY_OCCUPIED` 逐字，**不起应用**）；③ `WPF_X11_DIR=<空目录>` 的旁路由**静默通过**变 **`rc=3` ＋ 强制上屏**。同趟立号 **`D-G188`**（八段齐全）＋ `--emit` ⇒ `DEFREG=PASS declared=223 route_ids=223`；并**顺带消掉两条红**（`REPORTID`：`t63` 报告的两处 `D-G188` 引用由 `rc=1` 点名回 `rc=0`；`HANDOFF-MV`：`cell=#1` 按第 `28` 条同趟追写后回 `PASS`）。

## 1. 写域（**5 件**）与写入前后成对读数
| 件 | 写前 `sha16`／行 | 写后 `sha16`／行 | `stat -c %a` | `git ls-files -s` |
|---|---|---|---|---|
| `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` | `a70aeb1d988ebc9e`／`142` | **`53a01752fb09da22`／`208`** | `644` | `100644` |
| `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh` | `1d95cd4d42f2646d`／`187` | **`863ef62f1761005a`／`208`** | `644` | `100644` |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `22ccdcbc47c088a2`／`3845` | **`fa2b6f9d8cbf7b3e`／`3858`** | `644` | `100644` |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `3d2b2ea02cd8c866`／`232` | **`5ac1ffa46b1e5a59`／`233`** | `644` | `100644` |
| `build/MilBridge/P1-dg188-report.md`（本件，新建） | — | 见末行自证 | `644` | 未入索引 |
**另：按队长本趟明令**（第 `28` 条维护契约）追写了 `build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1`（该件**不在本单结构化 `inScope`** ⇒ 见 §7 的契约字段缺口说明）：`575 → 579` 行；**模式两口径** `644`／`100644`（写前写后相同，`cat >>` 追加）。
- **装置件写法的「只增不改」**：两份 .sh 的**原判据 6 行**（`XDIR=…`／`if [ -S … ]`／`DISPLAY_OCCUPIED`／`exit 3`／`DISPLAY_LEASE=free`）**逐字留档在新注释块内**（`session_inner.sh` 现取 `:19–:35` 段），新判据写在它之下；`bash -n` 两件均 `rc=0`。
- **模式守恒自证（两口径成对，全部写入件）**：两件装置 `644`／`100644`；`KD` `644`／`100644`；`declared.tsv` `644`／`100644`；`HANDOFF-NEXT.md` `644`／`100644`；本件 `644`／未入索引。**零模式位移**（写前 `stat -c %h` 两件装置均 `1`；写前 `cp -p` 备份 `~/w281-scribe/bak/{session_inner.sh,run-pts-pages-legs.sh}.pre-t68`，`cmp IDENTICAL`）。

## 2. 机制（写进件内：判据 ＋ 射程句 ＋ 防伪造）
- **判据（`session_inner.sh`）**：占用判定 ＝「该号在**规范目录** `/tmp/.X11-unix` **或** `WPF_X11_DIR` 指向的目录里存在 `X<n>`」；**任一边有 socket 才走 lease**；**lease 五条全成立 ⇒ 放行**（① 常规件 ② 模式 `600` ③ `DISPLAY=` 相符 ④ `OWNER_PID` **在本脚本祖先链上** ⑤ 活 `Xvfb` 且其 `ppid` == `OWNER_PID`）；**否则 ⇒ `DISPLAY_OCCUPIED=… ⇒ 拒跑`（`rc=3`）**。
- **防伪造**：外人拿不到「闸进程的祖先链」这一事实；`OWNER_PID` 必须是闸的**祖先**、且那个 `Xvfb` 必须是它的**亲儿子** ⇒ 「另起一个 `Xvfb` 占号」（现取 `LEASE_REJECT reason=no-lease`）与「伪造 lease」（现取 `LEASE_REJECT reason=lease-owner-not-ancestor`）**都拒**。
- **射程句（写死）**：「**占用** ＝ socket 在任一边存在 ∧ **不是**由本脚本**祖先链上的 lease 持有者**亲手起的活 `Xvfb` 所持有」／「**放行** ＝ lease 五条全成立」。**射程外**：本判据**不认人**，只判「该 socket 是否由我的祖先链亲手持有」；lease 的**加密学强度**不在内（只到「祖先链 ＋ 亲儿子」，够挡现场两条旁路）。
- **调用方（`run-pts-pages-legs.sh`）**：起完 `Xvfb` 后**写 lease**（`$OUTDIR/device/display-lease.txt`，`chmod 600`，记 `DISPLAY`／`OWNER_PID=$$`／`XVFB_PID=$!`／`SOCK_DIR`／`TS`）并 `export W67_DISPLAY_LEASE`；收装置时 `rm -f` 该 lease（**不留可被复用的旧 lease**）。

## 3. 正极（**官方腿路真跑**，成对）—— 现象①消除
- **修前（我从 `~/w281-scribe/bak/*.pre-t68` 的 pre 版本现取；`ts=2026-09-28T20:57:46.951+0800`）**：`rc=1`；`APPSYNC: SYNC-APPLOCAL=PASS … drift=0`／`AUTHORITY: shim=2a5165700a8c8579 pf=b9a4f3a0e48e688d ｜ APPDIR: 同`／`X_UP=yes display=:237` 之后 ⇒ `DISPLAY_OCCUPIED=:237 sock=/tmp/.X11-unix/X237 ⇒ 拒跑（号已被占；请用 W67_DISPLAY=<空闲号> 或先按 PID 收净）` ⇒ `PARSE-ERR 一个 leg_*.env 都没写出（session.txt 里没有 23/24 的组）`；`/tmp/t68-pre-out/*.env` **`0` 件**。
- **修后（官方调用者，重活槽内；`ts=2026-09-28T20:55:25.959+0800` 起、`20:57:23.476+0800` 止；`HEAVYSLOT=RELEASED rc=0 held=31s`）**：**`rc=0`**；关键行原样（`stdout`）：
```
DISPLAY_LEASE_FILED=build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device/display-lease.txt owner_pid=487396 xvfb_pid=487985 display=:237 mode=600
DISPLAY_LEASE=official-caller-owned display=:237 sock=/tmp/.X11-unix/X237 xvfb_pid=487985 owner_pid=487396 lease=…（① 常规件 ② 模式 600 ③ DISPLAY 相符 ④ owner 在祖先链上 ⑤ 活 Xvfb 且是其亲儿子 ⇒ 放行）
X_UP=yes display=:237
LEGS_TO_ENV=OK wrote=2 outdir=build/MilBridge/tests/PtsPagesProbe/evidence/arm_A
POSTSHIM: shim=2a5165700a8c8579 pf=b9a4f3a0e48e688d（== authority ⇒ 读数可归因）
```
- **两腿出件（覆盖面内的路径）**：`evidence/arm_A/leg_23.env` `sha16 ae26bbfa7976c776`／`4` 行／`272 B`｜`evidence/arm_A/leg_24.env` `sha16 8d103daa32cf24d5`／`4` 行／`273 B`（与转换器写的 `evidence/arm_A/arm_A/leg_*.env` `cmp` **逐位相同**）。**`LEG` 行原样**：
```
LEG k=23 alive=yes app_rc=143 magenta=50468 colors=844 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=140234 ink=428003
LEG k=24 alive=yes app_rc=143 magenta=55058 colors=851 ns=HandyControlDemo.UserControl.FlowDocumentDemo ae=221246 ink=423345
```
（`app_rc=143` ＝ 仪器 `SIGTERM` 收的；`alive=yes`；两页的 `magenta`/`colors`/`ink` 都真值 ⇒ 腿是真跑出来的。）

## 4. 反极（**外人占用仍拒**，真跑）—— 闸没被废
- 外部另起 `Xvfb :236`（`pid=499091`，`sock=yes`）后：`W67_DISPLAY=:236 bash …/session_inner.sh t68neg A:0` ⇒ **`rc=3`**，`stderr` 原样两行：
```
DISPLAY_OCCUPIED=:236 sock=/tmp/.X11-unix/X236 ⇒ 拒跑（号已被占；请用 W67_DISPLAY=<空闲号> 或先按 PID 收净）
LEASE_REJECT reason=no-lease lease=<未给> display=:236（外人不放行：无 lease／伪造／过期／非祖先链／Xvfb 非其亲生 ⇒ 一律拒）
```
- **不起应用的机器证**（`app_started=none` 的等价三条）：`logs_dir_exists=no`｜`app_g_logs=0`｜`dotnet HandyControlDemo` 子进程 **0**（闸在 `session_inner.sh` 现取 `:88` 出口，**在 app 启动块之前**）。占用者已**按 PID** 收（`sock 已消失`）。

## 5. 旁路（成对 ＋ 两条防伪造腿）
- **修前（pre 版现取，`ts=2026-09-28T20:53:43.133+0800`）**：真 `Xvfb :237` 在跑，`WPF_X11_DIR=/tmp/t68-decoy W67_DISPLAY=:237` ⇒ **`rc=0`**／`DISPLAY_LEASE=free display=:237 sock=/tmp/t68-decoy/X237` ⇒ **静默通过**（一个环境变量让保护失效）。
- **修后（`ts=2026-09-28T20:58:37.608+0800` 段）**：同输入 ⇒ **`rc=3`**，先上屏再拒：
```
WPF_X11_DIR_OVERRIDE=/tmp/t68-decoy（判据不改：与规范目录 /tmp/.X11-unix **双边**检查 ⇒ 该改写不得让被占的号看着空闲；D-G188）
DISPLAY_OCCUPIED=:237 sock=/tmp/.X11-unix/X237 ⇒ 拒跑（…）
```
- **两条防伪造腿（仓外 wrapper 现取，`ts=2026-09-28T20:54:52.012/20:54:54.544+0800`）**：① **官方调用者形态**（wrapper 起 `Xvfb :235`、写 `OWNER_PID=$$` 的 `600` lease）⇒ **放行**：`DISPLAY_LEASE=official-caller-owned … xvfb_pid=467396 owner_pid=467394`，随后 `G1 MISSING-SHIM`／`ALL_GROUPS_DONE`（**wrapper_rc=0**）；② **伪造 lease**（同一做法但 `OWNER_PID=1`）⇒ **仍拒**：`rc=3` ＋ `LEASE_REJECT reason=lease-owner-not-ancestor`。

## 6. 立号 `D-G188`（**先占用检查、后入册、同趟 `--emit`**）
- **占用检查（入册前现取，`ts=2026-09-28T20:53:20.127+0800`）**：`docs/ROUTES.md`／`build/close-wave.sh`／`build/MilBridge/HANDOFF-NEXT.md`／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv` 的 `D-G188` 命中 **各 `0`**；在册**最大号 ＝ `D-G187`** ⇒ `D-G188` 可用。
- **入册**：`KNOWN-DEFECTS.md` ＋`13` 行（`3845 → 3858`），**八段齐全**：现象（两读现取）／机理（判据 vs 判据的输入）／最小复现（命令原文 ＋ 成对读数）／射程（占用与放行的定义 ＋ 射程外两条）／在册实例**逐条点名**（`t14` 落闸那次；`t20` 真占用 `:236` 与空号 `:235`；`t68` 本次互斥＋旁路两读；`t63` 报告的引用面）／🔴 口径句（**逐字照队长给的**）／判据（机器三条并列）／责任归属／边界／同族。
- **同趟 `--emit`**：`declared.tsv` `232 → 233` 行（`sha16 3d2b2ea02cd8c866 → 5ac1ffa46b1e5a59`），新增行 `ID D-G188 req=KD present=KD`。**两遍** `defect-registry-check.sh` ⇒ **均 `rc=0`**：`DEFREG=PASS declared=223 route_ids=223` ＋ `DECLDRIFT=0 keys=-`（**两值相等**）。

## 7. 顺带消掉的两条红（成对读数，**均非本席过失**）
- **`REPORT-ID-DOMAIN`**：修前（`ts=2026-09-28T20:55:40.894+0800`）`rc=1`／`REPORTID=FAIL`，点名 **两处**：`build/MilBridge/P1-w7-report.md:142` **与** `:186`（`id=D-G188（报告里写了、declared 集里没有 ⇒ 该号没入册）`）⇒ 修后（`ts=2026-09-28T20:58:18.315+0800`）**`rc=0`／`REPORTID=PASS files=223 ids=2156 declared=223`**、`D-G188` 点名 **`0`**。⇒ **「登记先于引用」的现场证据**（`t63` 的报告先引、本趟入册后合法）。
- **`HANDOFF-MV`**：修前 `rc=1`／`HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=7 manual=1 mismatch=1 uncomparable=0 reasons=,#1:covered-file-changed-since-ts`（in-repo 指纹 `37b6131…`）⇒ **按第 `28` 条在最后一次覆盖件写盘之后追写 `cell=#1`**（本席现取 `ts=2026-09-28T20:58:18.241+0800`，现值 `3cdd4b77d98f16b641469dd7ca733d9f21943fff568d37d7f0679029915c74be`）⇒ 修后 **`rc=0`／`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**、`HIT` **`0`** 条。
- **⚠️ 契约字段缺口（如实报）**：`build/MilBridge/HANDOFF-NEXT.md` **不在本单结构化 `inScope`**（写域只列 5 件）—— 该写是**队长本趟明令**（第 `28` 条维护契约要求「同趟追写」）⇒ 若平台的 `changedPaths` 校验拒收该路径，**真实改动集 = 6 件**，请队长 amend `In scope`。

## 8. 红线与并发归因
- **未越域**：`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/static-jaws-check.sh`／`src/**`／`docs/ROUTES.md`／两枚哨兵**本席一字未改**；四条不变量现取（`ts=2026-09-28T20:58:56.673+0800`）：`^run_step "` ＝ **`62`**｜覆盖面 ＝ **`234`**｜首行 `DECL` ＝ **`62 gen=#81`**｜`--expect` ＝ **`234`** ⇒ 未变。
- **哨兵（如实归因）**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **`rc=0`（IDENTICAL）**；但两枚的现取 `sha256` 前 16 位是 **`386865f802c2a1ff`**，与我本会话早前多次现取的 **`6cb3f97388c3c4dc`** 不同，且两枚 `mtime` 均为 **`2026-09-28 20:54:08.762/763 +0800`** ⇒ **不是本席写的**（本席从不写哨兵）⇒ 归因：**另一条车道/队长在 `20:54:08` 写了哨兵**（具名交接，非本趟位移）。
- **并发归因（`runner` 在跑 `t67`）**：`git status --porcelain` 现取里，**属于对方**的改动逐件点名：`README.md`／`build/MilBridge/arm-logs/tab-anchor.log`／`tab-rtl.log`／`tab-zero.log`／`build/MilBridge/tools/pts-gap-count-check.sh`／`docs/ROUTES.md`／`docs/unimplemented.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`／`win32_pts.c`／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`／`build/MilBridge/P1-tlinegate-probe-report.md`／`P1-w7-report.md`（**t63 的 11 件 ＋ 载体**）⇒ 本席**未动它们**；`inputs_fp` 若再变，按件的 `mtime` 归因给对方。
- **fp 成对**：跑腿前 `0a4fd053d0a95b9ec09f6e0b3cc789c4e63a4299753d735e273070b55a42d9f2` ⇒ 跑腿＋两件装置改后 **`3cdd4b77d98f16b641469dd7ca733d9f21943fff568d37d7f0679029915c74be`**（覆盖面件数 **`234`** 未变）；**归因**：本席两件装置（`session_inner.sh`／`run-pts-pages-legs.sh`）＋ 腿跑器写的 `evidence/app_g1.log`／`evidence/arm_A/{leg_23,leg_24}.env`（**均在覆盖面内**）⇒ **本趟位移 100% 归本席**；对方 `arm-logs/**`（若在覆盖面内）若有位移**不在**此值里（本席取值的同刻两点相同）。

## 9. `NOINFO`／自伤（具名）
- **`NOINFO`**：① **未跑整趟门禁**（本任务只修装置 ＋ 腿路，整趟门禁会构建 ⇒ `provider` 位位移）；② **lease 的加密学强度不在判据内**（只到「祖先链 ＋ 亲儿子」）；③ **未横扫**全仓其它「占用／独占」类保护（只点名在册两处）；④ `app_started=none` **不是本脚本的 token** ⇒ 用「`rc=3` 在 app 块之前 ＋ 未建 `logs/` ＋ `app_g*.log 0` ＋ `dotnet` 子进程 `0`」三条等价机器证代替。
- **自伤 1 条（当场修，零残留）**：新写的 `WPF_X11_DIR_OVERRIDE` 那行**首版把 `D-G188` 写在双引号里的反引号中** ⇒ 命令替换把该段吃掉（现场 `session_inner.sh: 行 46: D-G188: 未找到命令`）—— 正是本仓 **`D-G186` 同族**；**已改成不带反引号**，并复跑 `shell-quote-trap-check.sh` ⇒ **`SHELL_QUOTE_TRAP=PASS reason=ok traps=0`**（`ts=2026-09-28T20:54:2x`）＋ `pipefail-sigpipe-check.sh` ⇒ **`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0`**。
⏪ **本件自证（末行；口径 `head -n -1 build/MilBridge/P1-dg188-report.md | sha256sum | cut -c1-16`）**：`7371392c03f06b2d`（**整件全文 `sha256` 只在交件消息里给**，第 `24` 条）。
