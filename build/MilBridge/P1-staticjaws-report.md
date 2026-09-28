# P1-staticjaws 报告（`t62`）—— 静态牙全景体检固化成常设牙 ＋ 同趟接线（覆盖面 `233→234`、步数 `61→62`）

**本件口径（写死）**：**只增不改**（本件新建，落定后除末行自证不再改）；读数一律**捕获式取 `rc`**（`cmd >out 2>err; echo $?`，**不接管道** —— 会话第 `27` 条）；每格带**亚秒 `ts=`**；`NOINFO` 具名（§10）。**不跑整趟门禁**（会构建 ⇒ `provider` 位位移）。

## 0. 一句话（含**交付状态**）
新牙 `build/MilBridge/tools/static-jaws-check.sh` 已落，判据/三态/排除面/两极化/自测**全部验过**；同趟接线（四处声明 ＋ `--expect` ＋ 覆盖面）**全部机器读数已翻绿**（§6）。**但本单有一条验收项未达 ⇒ 本席判 `failed`**：**正极（现树）不是 `PASS`，唯一一颗红是 `[HANDOFF-MV]`** —— 起因正是本趟**写域内**的接线改了两个覆盖面内件、并改了覆盖面件数与步数 ⇒ `HANDOFF-NEXT.md` 的 `cell=#1`／`#2`／`#5` 三格按维护契约必须**同趟追写**，而**那个件不在本单 `inScope`** ⇒ 本席**按铁律不越域**，改为**报队长 + 给逐字补救文本**（§9）。**补救已在仓外副本上验证成立**（`HANDOFF_MV=PASS`，`rc=0`）。

## 1. 写域（5 件；写前 `stat -c %h`＝1、写前 `cp -p` 备份、`temp+rename`）与成对读数
| 件 | 写前 `sha16`／行 | 写后 `sha16`／行 | `stat -c %a` | `git ls-files -s` |
|---|---|---|---|---|
| `build/MilBridge/tools/static-jaws-check.sh`（新建） | — | **`ff4a85ae5ee1d59e`／`188`** | `644`（见 §8 自伤①） | 未入索引 |
| `verify-all.sh` | `742175bffd5a175d`／`1322` | **`63b767b894e4292d`／`1326`** | `644` | `100644` |
| `build/close-wave.sh` | `69c39feabe148c62`／`720` | **`bce5c297692f6a0e`／`721`** | `644` | `100644` |
| `docs/WAVE81-PREREGISTRATION.md` | `c95deaaa1b906a72`／`36` | **`a622e86f32d0412f`／`41`** | `644` | `100644` |
| `build/MilBridge/P1-staticjaws-report.md`（本件） | —（新建） | 见末行自证 | `644` | 未入索引 |

- **写前备份**（**任何写之前** `cp -p`）：`~/w281-scribe/bak/verify-all.sh.pre-t62`（`742175bffd5a175d`）／`~/w281-scribe/bak/close-wave.sh.pre-t62`（`69c39feabe148c62`）／`~/w281-scribe/bak/WAVE81-PREREGISTRATION.md.pre-t62`（`c95deaaa1b906a72`）。**新建件无写前像**（本趟新建）。
- **模式守恒自证（两口径成对）**：`verify-all.sh`／`close-wave.sh`／`WAVE81-PREREGISTRATION.md` 三件写前写后均 `644`／`100644`（**逐位相同**）；新牙 `wt=644`（**修正后**，见 §8）、未入索引；本件 `644`／未入索引。
- **`bash -n`**：新牙、`verify-all.sh`、`build/close-wave.sh` 三件 `rc=0`、`stderr` `0` 行。
- **红线**：`src/**`／`build/*.Linux/**`／`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／两枚哨兵 **一字未动**；未跑整趟门禁；未 `git add`／`commit`／`push`。

## 2. 新牙是什么（判据／三态／排除面，全部写死在件内）
**射程句（写死）**：**它只判「已接线的**裸静态牙**此刻是否红」，不替代整趟门禁** —— 构建／显示位／腿批／带参步**不在射程内**，一律**具名** `STATICJAWS_EXCLUDED` 上屏（**不静默**）⇒ 「本牙绿」**不等于**「整趟门禁绿」（射程外 `NOINFO`）。
**逐颗判据（捕获式）**：`timeout -k 5 40 bash <牙> >out 2>err; rc=$?` ⇒ `rc=0` 计 `pass`；`rc=124`／`rc=137`（超时/`-k` 后被杀）或牙自报 `=<…>NOINFO` 或 `rc=2`（本仓 `RC_NOINFO` 约定）⇒ 计 **`noinfo`（不算红）**；其它 `rc≠0` ⇒ 计 `fail` 并**逐条点名** `STATICJAWS_HIT step=<名> jaw=<路径> rc=<n> stderr=<n>行`。
**三态**：`STATICJAWS=PASS n=… excluded=… noinfo=…`｜`STATICJAWS=FAIL fails=… n=… excluded=… noinfo=…`｜`STATICJAWS=NOINFO reason=…`（算不出来）。`rc`：0／1／2。
**排除面（现正极实测 `31` 条，逐条理由）**：`non-bare-step:argv-not-bare` **15**｜`non-bare-step:dotnet-build-or-test` **7**｜`non-bare-step:python-step` **2**｜`known-long-run-or-build` **2**（`pc-line-step.sh`／`hidden-only-step.sh`，写死表 ＋ 理由「`t62` 前体检实测 `rc=124`」）｜`display-or-legs` **2**｜`self-recursion` **1**（本牙自身，防递归）｜`non-bare-step:shell-function-step` **1**（`wpf-linux.sln` → `build_sln_and_samples`）｜`interactive-step-ignores-SIGTERM(t62-measured)` **1**（`r-gate-step.sh`，**本趟实测**：它到期**不随 `SIGTERM` 退出**，残留进程已**按 PID** 收）。`push-marker-write.sh`（写盘端）在 `EXCL_WRITE` 表内（**只读体检不许改工作树**）；`wave-push.sh --dry-run` **收**（`--write` 腿不在 `run_step` 里）。
**成本（现取）**：正极 `31` 颗牙合计 **≈ 41.1 s**（最慢 `PRODUCT-ENTRY` **13.9 s**、`WIRING-CLOSURE` 5.7 s、`DEFECT-REGISTRY` 3.4 s、`REPORT-ID-DOMAIN` 3.3 s）；`SJC_TIMEOUT` 默认 **40 s**（必须容得下 `PRODUCT-ENTRY`），可用环境变量收紧。

## 3. 正极（**现树**，捕获式；`ts=2026-09-28T19:26:31.917+0800`）—— **`FAIL fails=1`**
```
STATICJAWS=FAIL fails=1 n=31 excluded=31 noinfo=1 n_total=62
STATICJAWS_SCOPE 射程＝已接线的裸静态牙；构建/显示位/腿批/带参步**不在射程内**（见上面 STATICJAWS_EXCLUDED 逐条）⇒ 本牙绿**不等于**整趟门禁绿（NOINFO）
STATICJAWS_NOINFO step=FrameProbe-frame jaw=…/build/MilBridge/tools/frame-step.sh reason=rc2-rc-noinfo-convention rc=2 stderr=3行 ms=…（**不算红**）
STATICJAWS_HIT step=HANDOFF-MV jaw=…/build/MilBridge/tools/handoff-machine-values-check.sh rc=1 stderr=0行 ms=3806
```
**`31` 颗 `rc=0` 逐颗（原样，`step`／`ms`）**：`BASELINE-SHA 29`｜`ARM-LOG-SHA 61`｜`BUILD-HYGIENE 2060`｜`DEFECT-REGISTRY 3368`｜`VERIFYALL-SELF 95`｜`FP-INPUTS-HYGIENE 620`｜`COLUMN-FLOOR 423`｜`QUOTE-TRAP 577`｜`PRODUCT-ENTRY 13905`｜`PIPEFAIL-SIGPIPE 1933`｜`NUL-BYTES 333`｜`HYGIENE 2685`｜`UIA-DOOR 1351`｜`IME-LANDING 670`｜`BAK-COMPLETENESS 672`｜`SELFDESC-WIRING 180`｜`LANE-PATH 185`｜`ROWS-IDENTITY 101`｜`BOUNDARY-DECL 584`｜`WIRING-COVERAGE 390`｜`PARSER-GUARD 784`｜`ROOT-ENTRIES 152`｜`WIRING-CLOSURE 5655`｜`REPORT-ID-DOMAIN 3338`｜`SENTINEL-SPEC 192`｜`WAVE-PUSH 135`｜`TS-ORDER 一`｜`PUSH-MARKER`｜`PROVIDER-REPRO`｜`STATIC-JAWS`（**本牙自跑 `31` 颗后**；自身已被 `self-recursion` 排除）。
**唯一红的归因（本席自查，非转述）**：`HANDOFF-MV` 现取 `rc=1`／`HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=5 manual=1 mismatch=3 uncomparable=0 reasons=,#1:covered-file-changed-since-ts,#2:count-changed-since-ts,#5:count-changed-since-ts` —— 三格正是本趟**写域内**改动所致（`verify-all.sh`／`build/close-wave.sh` 属覆盖面内件 ⇒ `#1`；覆盖面 `233→234` ⇒ `#2`；步数 `61→62` ⇒ `#5`）。该格**必须同趟追写**（本牙自己的维护契约），而载体在 `build/MilBridge/HANDOFF-NEXT.md` —— **不在本单 `inScope`** ⇒ 见 §9。

## 4. 反极（**仓外沙箱**，捕获式；`ts=2026-09-28T19:26:28.100+0800`）—— **`FAIL` 且点名**
夹具做法：`mktemp -d` ⇒ `mkdir -p <沙箱>/build/MilBridge/tools` ＋ `cp -p verify-all.sh <沙箱>/` ＋ 造一颗**必定 `rc=1`** 的假静态牙 `fake-red-jaw.sh`（**`stat -c %a` ＝ `644`**，即**不可执行** ⇒ 顺带证明本牙走 `bash <件>` 调用式）＋ 往沙箱步表追加 `run_step "FAKE-RED" bash build/MilBridge/tools/fake-red-jaw.sh`：
```
STATICJAWS_HIT step=FAKE-RED jaw=/tmp/tmp.oZUSs6A4SQ/build/MilBridge/tools/fake-red-jaw.sh rc=1 stderr=0行 ms=3
STATICJAWS=FAIL fails=1 n=1 excluded=31 noinfo=31 n_total=63
```
⇒ **点名 step ＋ 牙路径 ＋ 捕获式 `rc`**；`31` 条 `jaw-absent` 记 `NOINFO`（**不算红**，`reason=jaw-absent` 具名）；**夹具已删**（`sandbox_removed=YES`），**仓内残留 0**。

## 5. 自测（`--selftest`，仓外夹具；`ts=2026-09-28T19:24:xx` 与 `19:27:44` 两趟）
```
STATICJAWS_SELFTEST_CASE case=S1 kind=positive-fixture rc=0 原样=STATICJAWS=PASS n=2 excluded=1 noinfo=1 n_total=3
STATICJAWS_SELFTEST_CASE case=S2 kind=negative-fixture rc=1 verdict=HIT-named 原样=STATICJAWS_HIT step=FAKE-RED jaw=… rc=1 stderr=0行
STATICJAWS_SELFTEST_CASE case=S3 kind=noinfo rc=2 原样=STATICJAWS=NOINFO reason=verify-all-unreadable path=…
STATICJAWS_SELFTEST=PASS cases=3 pass=3 fail=0
```

## 6. 同趟接线（**四处声明 ＋ `--expect` ＋ 覆盖面，一次到位**）与机器读数（原样，`ts=2026-09-28T19:26:08.823+0800`）
- `^run_step "` **`61 → 62`**（新步 `STATIC-JAWS`，追加在 `PROVIDER-REPRO` 之后 ⇒ 与 `STEP-NAMES` 次序一致）。
- 首行 `# VERIFYALL-STEPS-DECL:` **`61 → 62`**（**新行插在 DECL 栈顶** ⇒ `decl_line()` 取到的就是它；**既有史实行只追加、未改**）。
- 头注释口径句 **`**`#81` 收官起 = 61 步**` → `62 步`**（新行插在栈顶；历史行留档）。
- `# VERIFYALL-STEP-NAMES:` 尾部追加 ` | STATIC-JAWS`（**`61 → 62`** 项）。
- `docs/WAVE81-PREREGISTRATION.md`：**dated 追加**（`36 → 41` 行；本波步数／覆盖面／射程句／`NOINFO` 具名）。
- `[42]` 步 `--expect` **`233 → 234`**；`build/close-wave.sh` 的 `fp_inputs()` **+1 行件路径身份**（不用 glob）⇒ 覆盖面 **`233 → 234`**。
**六条机器读数（原样）**：
```
VERIFYALL_SELF=PASS names=62 decl=62 gen=#81 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=63b767b894e4292d
FP_MANIFEST_TEETH=PASS reason=ok files_n=234 files_n_uniq=234 blank_n=0 declared_expect=234 declared_paths=none
WIRING_COVERAGE=PASS run_step=62 wiring_n=60 coverage_n=234 missing_n=0 absent_n=0 allowed_n=0 examined=60
WIRING_CLOSURE=PASS steps=62 jaws_n=58 undeclared=0 reasonless=0 exempt_rows=7 black_keys=7 black_lines=16 black_exempt_keys=7 grown=0 ninfo_lines=1571 ninfo_reason_lines=993 mentions=578 fails=0 rc=0
SELFDESC_WIRING=PASS examined=73 wired=51 unwired=22 undeclared=51 fails=0 run_step=62
FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=234 artifact_n=0 missing_n=0 stderr_bytes=0
```
**成对**：`bash ~/w153a/bin/infp.sh list | wc -l` `233 → 234`；`inputs_fp` `3984df956342e2757464d40a18e6621acee5fa764463f17fee7209ad7653478e` → **`fe923e2ece0115374a39dde202f317e1f0743f156ab86c238b2d8c22b8d56897`**（`ts=2026-09-28T19:27:27.454+0800`／`19:27:44.031+0800` 两处现取**逐位相同** ⇒ 与 `chmod` 无关，指纹只吃内容）。
**相邻两条牙**：`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203 sh=114 py=89 diag=76 allow=0`（`rc=0`）｜`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=114 sites=100 hit=0 low=10 diag=5 safe=85 runs=12`（`rc=0`）。

## 7. 不变量与红线（现取，`ts=2026-09-28T19:27:27.454+0800`，`HEAD=e37f771`）
`^run_step "` ＝ **`62`**｜首行 `DECL` ＝ **`62 gen=#81`**｜`--expect` ＝ **`234`** ＝ `infp.sh list` ＝ **`234`**｜`STEP-NAMES` **`62`** 项｜两枚哨兵 `cmp` **`rc=0`（IDENTICAL）**、各 `6cb3f97388c3c4dc`（**未写**）｜`DEFREG=PASS declared=222 route_ids=222`（`rc=0`）｜`REPORTID=PASS files=216 ids=2135 declared=222`（`rc=0`）｜`porcelain` 现取恰 `3 M`（本趟三件）＋ `3 ??`（本趟两件新建 ＋ **别的车道**的 `P1-task0201-criteria.md`／`P1-task0201-recheck-report.md`）｜**未跑整趟门禁**、未 `git add`／`commit`／`push`。

## 8. 自伤与当场更正（**如实记**，全部零内容损伤）
1. **新牙落地模式 `600`（本席自己犯的 `D-G187` 同族）**：`write` 落地后现取 `stat -c %a` ＝ **`600`**（`git ls-files -s` 尚未有它 ⇒ 索引面待提交时定）。**当场修**：`chmod 644` ⇒ 现取 **`644`**；**内容 `sha16` 修前修后逐位相同**（`ff4a85ae5ee1d59e`）⇒ 纯模式修正、零内容改动。**教训**：文件新建后必须**立刻**核 `stat -c %a`（本仓已有 `D-G187` 两形态在册）。
2. **首版新牙自带 `pipefail` 危险站点 4 处**（`printf '%s' "$out" | grep -q …` 在 `if`／`&&` 里）：**被 `pipefail-sigpipe-check.sh` 当场点名**（`UNDECLARED_HIT …:163／:169／:170／:174` ⇒ `PIPEFAIL_SIGPIPE=FAIL undeclared_hit=4`）⇒ 改成**纯 bash 内建** `case` 子串判定（`has()` 帮手，**零管道**）⇒ 复跑 `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0`。**这正是本牙存在的意义：新件也会被别的已接线牙当场抓住。**
3. **首版把 `r-gate-step.sh` 收进射程** ⇒ `timeout 25` 到期它**不随 `SIGTERM` 退出**（实测残留 `timeout … r-gate-step.sh` ＋ 子进程共 **2** 条）⇒ 已**按 PID**（先 `TERM` 后 `KILL`，**未用 `pkill`/`pgrep -f`**）收掉、现取 0 条；并把它写进 `EXCL_INTERACTIVE`（理由逐字入件头）＋ 给所有牙加 `timeout -k 5` 护栏 ＋ `rc=137` 也计 `noinfo`。
4. **首版默认超时 `25 s` 会把 `PRODUCT-ENTRY` 计成 `noinfo`**（实测该牙 **13.6 s**、`rc=0`）⇒ 默认提到 **`40 s`**（否则会出现「合法牙被算成算不出」的假 `NOINFO`）。

## 9. **待办（本单验收唯一未达项）—— `HANDOFF-NEXT.md` 三格同趟刷新**（不在本单 `inScope` ⇒ 本席不越域）
- **现场**：`HANDOFF-MV` 现取 `rc=1`／`DIVERGED mismatch=3`（`#1`／`#2`／`#5`），`STATICJAWS` 正极因此 `FAIL fails=1`。
- **补救（逐字，三行 dated 追写；`ts`／`fp` 用现取值）**：
```
⏪ **机器值契约更正 · cell=#1**：以现取为准；`ts=<TS>` 时 现值 ＝ `fe923e2ece0115374a39dde202f317e1f0743f156ab86c238b2d8c22b8d56897`（命令：`bash ~/w153a/bin/infp.sh fp`）（**`t62` 加了第 `[+]` 步 `STATIC-JAWS` ⇒ 改了两个覆盖面内件 ＋ 覆盖面 233 → 234** ⇒ 本格随之刷新。）
⏪ **机器值契约更正 · cell=#2**：以现取为准；`ts=<TS>` 时 现值 ＝ `234`（命令：`bash ~/w153a/bin/infp.sh list | wc -l`）（**`t62` 覆盖面 233 → 234**。）
⏪ **机器值契约更正 · cell=#5**：以现取为准；`ts=<TS>` 时 现值 ＝ `62`（命令：`grep -c '^run_step "' verify-all.sh`）（**`t62` 步数 61 → 62**。）
```
- **补救的机器证（已在**仓外副本**上验证，`ts=2026-09-28T19:28:10.086+0800`）**：把上述三行追加到 `HANDOFF-NEXT.md` 的**副本**上，`bash build/MilBridge/tools/handoff-machine-values-check.sh --file <副本> >out 2>err; echo $?` ⇒ **`rc=0`**／`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`；副本已删（`temp_removed=YES`）。
- **⇒ 只要那三行落进 `build/MilBridge/HANDOFF-NEXT.md`，本单正极即 `PASS`**（无任何代码改动需求）。本席**请求队长把该件并入本单写域**（或另派一件）；在收到之前**不动它**。

## 10. `NOINFO`（具名，既不算绿也不算红）
1. **未跑整趟门禁**（会构建 ⇒ `provider` 位位移，`B-18` 在册）⇒ 端到端绿**未验**；本趟只跑 `bash -n`／新牙自测／两极化／单步命令。
2. **射程外的 `31` 步**（`dotnet` 构建/测试 7／带参 15／`python3` 2／长跑 2／显示位 2／壳函数 1／交互 1 ＋ 本牙自身 1）**未跑** ⇒ 「那些步此刻是否绿」**本牙管不着**（`STATICJAWS_SCOPE` 句写在每一次输出里）。
3. `HANDOFF-MV` 的 `#1`／`#2`／`#5` 三格**现取已过时**（§9）⇒ 在补齐前，`[HANDOFF-MV]` 步**不是绿**。
4. 新牙**未进 `verify-all.sh` 之外**任何声明册／台账（本任务只做接线四处 ＋ 覆盖面）；`WIRING_CLOSURE` 的 `exempt_rows`／黑名单机制**未复核**。
⏪ **本件自证（末行；口径 `head -n -1 build/MilBridge/P1-staticjaws-report.md | sha256sum | cut -c1-16`）**：`b7bf84523da1128e`（**整件全文 `sha256` 只在交件消息里给**，第 `24` 条）。
