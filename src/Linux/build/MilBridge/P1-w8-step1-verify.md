# P1-W8-STEP1-VERIFY —— `t81`（W8 第一步：`LoSetDoc`／`LoSetBreaking` 诚实实现）**独立复核判词**

> 复核者 `verifier`（任务 `t83`，attempt 2）。**只读仓树**：未改 `t81` 的任何件、未跑整趟门禁、未构建、未跑应用腿、未占显示位、未 `git add/commit/push`；**唯一写入 ＝ 本件**。
> 一切现取自算；**未引 `t81` 的输出当证据**（其报告只用于对照它**自称**的读数），**未引我自己早前报告**。**第二实现**＝ 我在仓外用 Python＋`ctypes` **`dlopen` 仓内 `.so`**（**不构建**）直接调用导出面：`LoCreateContext`／`LoDestroyContext`／`LoSetDoc`／`LoSetBreaking`／`WpfLinuxWin32_PtsJmpProbe`／`WpfLinuxWin32_PtsGapReport`／`WpfLinuxWin32_PtsGapSelfCheck(Diag)`。夹具全在仓外 `~/wv88y/t83/**`，**收尾删净**。
> 对拍标准 ＝ **先写的判据件** `build/MilBridge/P1-w8-step1-criteria.md`（现取 `40d8460366461d02`／306 行，与描述一致）。

---

## §0 快照（现取，带亚秒 `ts=`）

| 项 | 现取值 | `ts=` |
|---|---|---|
| `HEAD` | **`7a89ad7`**（`t85 复核关账批入册…`，`2026-09-28T23:24:09+08:00`） | `2026-09-28T23:26:02.282679673+08:00` |
| 实现面 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`ddc21eb68d2d67e8`／878 行／61644 B**｜`bin/exports.txt` ＝ **`71d651b16c6d9d6e`／561 行**｜`bin/libwpfwin32.so` ＝ **`3bd193e54785b5db`／346032 B** | 同上 |
| `t81` 载体 | `build/MilBridge/P1-w8-step1-report.md` ＝ `25024c43d29e7a5b`／228 行 | `23:50:27.567565515` |
| 证据面 | `…/PtsPagesProbe/evidence/{app_g1.log,leg_23.env,leg_24.env}`：`app_g1.log` ＝ `3729b8b5aa6b3f8d`（＝ `HEAD` 版**同值**）；两 `leg_*.env` **与 `HEAD` 版逐字节相同**、mtime `2026-09-28 23:04:40.688045132` | `23:50:08.464938078` |
| `porcelain` | 15 行（**写域内存在未提交差异，归属未核**；口径＝只说明「工作树 vs `HEAD` 的差」，**不说明写者数**） | `23:26:02.282679673` |

---

## ① 诚实性（本件最重的一条）：**成立** ＋ 一处 low 点名（`F-①`）

**我的第二实现（`ctypes`，现取 `ts=23:50:08.464938078`／`23:50:17.276099009`，原样）**

| 步骤 | 现取读数 | 判 |
|---|---|---|
| 建两个上下文 A／B | `create A rc=0 ploc=0x6001e56d2f60`｜`create B rc=0 ploc=0x6001e56d2fb0`（**地址不同**） | ✓ |
| A 写 `LoSetDoc(1,0,dev=11/22/33/44)`｜B 写 `LoSetDoc(0,1,dev=55/66/77/88)` | A ⇒ `probe(A)=(ret=1, addr_ok=0, [1, 0, 11, 33])`；B ⇒ `(ret=1, 0, [0, 1, 55, 77])` | **两对象各存各的 ⇒ 非全局单例、非「只改计数」** ✓ |
| A 写 `LoSetBreaking(7)`｜B 写 `LoSetBreaking(9)` | `probe(A)=(1,0,[7,0,0,0])`｜`probe(B)=(1,0,[9,0,0,0])` | 同上 ✓ |
| 未知句柄 `0xdeadbeef` | `LoSetDoc ⇒ rc=-10000`；`probe=(0,0,[0,0,0,0])`（**无记录、进程存活 ⇒ 未 deref**） | ✓ 拒绝 |
| `NULL` 句柄 | `LoSetDoc ⇒ -10000`｜`LoSetBreaking ⇒ -10000` | ✓ 拒绝 |
| 重复销毁 / 销毁后使用 | `destroy A rc=0`｜**再 destroy A ⇒ `-10000`**｜`setdoc(A) ⇒ -10000`｜`setbreaking(A) ⇒ -10000` | ✓ 拒绝且不改对象 |
| 计数自洽（`PtsGapReport` 现取） | `loc_creates=2 loc_destroys=2 loc_rej=1 setdoc_sets=2 setdoc_rej=3 setbrk_sets=2 setbrk_rej=2` —— **与我的调用序逐项吻合**（2 建／2 销毁／1 重复销毁被拒／2 成功 setdoc ＋3 被拒／2 成功 setbrk ＋2 被拒） | ✓ 不是捏造的数字 |
| 两态可区分（未设置 vs 已设置） | 新对象的 `probe(A)=(0,0,[0,0,0,0])`（写前）→ 写后 `(1,0,[…])` | ✓ |

- **`F-①`（low，点名）**：自检**不是纯函数** —— 同一进程里 **先跑自检** ⇒ `rc=1 diag=0`（健康）；**先调过 `LoCreateContext`＋`LoSetDoc` 再跑** ⇒ **`rc=0 diag=25`**；销毁后（`live=0`）再跑 ⇒ 仍 `rc=0 diag=25`（另一路 ctypes 脚本里见 `diag=32`）⇒ **结论随调用史翻转**，且只给**格号**、不点名字段。它自带了「保存/复原 counters ＋ 观测镜」的机制（现取 `win32_pts.c` 的 `save_*` 段），但**显然还有被调用史影响的状态未复原**。影响面：门禁在**新鲜进程**里跑它 ⇒ 现树读数是 `rc=1 diag=0` ✓；但作为「**能证伪的自检**」，须在件头写明「**必须在未调用过本模块 API 的进程里跑**」或补齐复原（**我不代改**）。
- **观察 `O-①`**：`WpfLinuxWin32_PtsJmpProbe` 读的是**调用史镜像**（键 ＝ `ploc` 值），**不是活状态读取器** —— 我实测**已销毁**的 A 仍能 `probe(A)=(1,0,[1,0,11,33])`（陈旧记录）；所以拿它当「对象上真落盘」的证据时**必须同时约束调用序／用不同 `ploc` 成对**（本件正是如此做的）。

## ② 判据 C1–C6 逐条复算：**C1 部分成立｜C2 成立｜C3 成立｜C4 不成立｜C5 不成立｜C6 部分成立**

- **C1 部分成立**：`nm -D --defined-only … | awk '{print $3}' | grep -c .` ＝ **`561`** **==** `exports.txt` 行数 **`561`** ∧ 两值 **> 557** ✓；`LoSetDoc`／`LoSetBreaking` 在导出清单各 `1` ✓；`WpfLinuxWin32_.*SelfCheck` 计数 **`4`**（他件 3）✓。**但**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的**九位（Release 权威件）行**现树与 `HEAD` 版**逐字相同**，其中 `win32shim` 仍写 **`6825dd7071387a46`**，而现盘 `.so` ＝ **`3bd193e54785b5db`** ⇒ **文档面未体现本次位移**（点名，low）。⇒ 若九位行按 C1 口径要随增量追写 ⇒ 该格**不成立**；若它是「Release 冻结值」不随开发面动 ⇒ **须在判据件里写明哪一份承重**（本件不代改）。
- **C2 成立**：`check-shim-coverage.py --tier mapped`（`rc=0`）⇒ `^  PresentationNative_cor3\.dll  (LoSetDoc|LoSetBreaking) ` 明细命中 **`0`**；汇总 `[PresentationNative_cor3.dll]` **`99 → 97`** ⇒ **减幅恰 `2` ＝ 真补入口数** ✓。
- **C3 成立**：`pts-gap-count-check.sh`（`rc=0`）⇒ **`PTSGAP=PASS tool=97 dead=11 artifact=1 ops=85 impl=91 so16=3bd193e54785b5db exports=561`**（三格 `99/87/93 → 97/85/91`，**各减 `2`**、与 C2 同幅）＋ **`PTSGAP_FRONTIER_STATE=NAMED frontier=LoSetDoc`**（≠`UNNAMED`）＋ `PTSGAP_FRONTIER before=LoCreateContext@3 after=LoSetDoc@2 carrier_sha16=3729b8b5aa6b3f8d …` ✓ **未靠只改计数造进度**（三格与缺口明细同幅下降）。
- **C4 不成立（两份证据都拿不到绿）**：门禁读的**在册证据** `entry=` 面现取 ＝ **`2 entry=LoSetDoc`**（＝ `t78` 那一趟，**本增量未换代在册腿**）；`t81` 自己那趟（`~/t81-runner/legs/app_g1.log`，**仓外**）＝ **`2 entry=dll:NotImplemented` ＋ `1 entry=LoAcquirePenaltyModule`**，其中 `EntryPoint="NotImplemented"`／`"dll"` 在上游命中 **`0`**（我自算）⇒ **不可回溯** ⇒ 按 C4 自己的判法**即红**（与 `t81` 自报一致）。
- **C5 不成立**：**在册腿** `leg_23/24.env`：`alive=yes` ✓／`app_rc=143` ✓／**`native_gap=0` ✗（要求 >0）**，`PTS_GUARD=FAIL … fails=native-ledger-absent(PTS_GAP n=0)` ⇒ `rc=1`（要求 `rc=0`）。**`t81` 自己那趟**（仓外）：`alive=yes`／`app_rc=143`／**`native_gap=1`** ✓，但 `PTS_GUARD=FAIL … fails=g10-name-off-roster(dll)` ⇒ 仍 `rc=1`。
- **C6 部分成立**：新自检**已导出**（`SelfCheck` 3→**4**）✓；两种状态下读数可区分（见 ①）✓；**但**自检**调用史敏感**、且**探针与自检不互校** ⇒ `F-①`／`O-①`。

## ③ 假进度必红 P1–P6：**P4 现场即红｜P5 我自造反腿成立（一处 token 不一致）｜P2／P6 记 `NOINFO`**

- **P5（台账非零但前沿不动）＝ 我自己造的真夹具**（判据自带 env 钩子，**在副本/仓外跑**）：`PTSGAP_FRONTIER_CARRIER=<我写的 stuck 载体 entry=LoCreateContext> PTSGAP_FR_BASELINE_IMPL=999 bash pts-gap-count-check.sh` ⇒ **`rc=1`** ＋
  `PTSGAP_FRONTIER before=LoCreateContext@3 after=LoCreateContext@1 …`｜`PTSGAP_FRONTIER_STATE=NAMED frontier=LoCreateContext`｜**`FAKE-PROGRESS impl=91 < 基线 999 而前沿仍是 LoCreateContext ⇒ **名字离开名单而能力为 0**（假进度）`**｜`PTSGAP=FAIL …` ⇒ **红成立、且点名了 `impl`／基线／前沿名三个字段** ✓
  **正腿对照**（真载体＋真基线）⇒ `rc=0`／`PTSGAP=PASS …` ✓
  **但（low 点名）**：判据件 P5 的「必红点」写的是 `FAIL reason=ledger-nonzero-frontier-unchanged`，**现实现打的是 `FAKE-PROGRESS …` 行（无 `reason=` token）** ⇒ 若按**字面 token** 断言则**不满足**；建议把判据的必红点对齐实现的实际 token（或在实现里补该 `reason=`）。
- **P3 现场即反例（我独立复现）**：`t81` 那趟的 `entry=dll:NotImplemented` ⇒ `PTS_G10_NAME=FAIL frontier=dll off-roster=dll roster=12 domains=pts-declared,unattributable decl=none` ⇒ **红并点名** ✓
- **P4 同趟性 ⇒ 见 ④（现场即红）**。
- **P2（`return 0` 无副作用）／P6（自检恒绿）＝ `NOINFO`**：两者的**反腿都需要「重编译一份改过的 shim」**，而本任务硬条款**禁构建** ⇒ 我**没有**自跑这两条反腿（`NOINFO(reason=反腿需重编译副本)`）；我给的是**检测器面**证据：自检**会红**（`diag` 格号 ≠ 0 ⇒ `rc=0`，见 `F-①`），但**探针不读自检的返回值** ⇒ 「自检被改成恒 `1`」这一形态**不会被探针抓住**（与 `t81` 自报的 `NOINFO` 同源，我独立确认该缺口存在）。

## ④ 同趟性：**不成立（判红点名）**

- 现盘 `.so`（`pts-gap-count-check.sh` 的 `so16=`）＝ **`3bd193e54785b5db`**；而**门禁读的在册腿** `leg_23/24.env` 的 `DEV … shim=` ＝ **`2a5165700a8c8579`** ⇒ **两值不等** ⇒ 按判据 P4 的必红点「`so16=` vs `DEV shim=` 不等即红」**现场即红** ✓（这正是 C4／C5 在册面拿不到绿的同一根因：**本增量未把腿证据换代**）。
- 对照：`t81` 自己那趟（仓外）`shim=3bd193e54785b5db` **==** `so16` ⇒ **它那趟是同趟的**（但那不是门禁读的那份）。

## ⑤ 零症状回归：**在册证据面不成立**；`native-ledger-absent` **仍红（如实）**

- **成对（before 取 `HEAD` 版；`HEAD=7a89ad7`）**：`leg_23.env`／`leg_24.env` 的现盘与 `HEAD` 版**逐字节相同**，mtime 均为 `2026-09-28 23:04:40.688045132`（＝ `t78` 那趟）⇒ **本增量没有带来新的在册腿读数** ⇒ 「零症状回归」在**门禁证据面无法成立**（不是劣化，而是**无新读数**）。
- **`t81` 自己那趟（仓外，只读）**：`leg_23` `alive=yes app_rc=143 magenta=50094 native_gap=1 native_err=-10000 shim=3bd193e54785b5db`｜`leg_24` `alive=yes app_rc=143 magenta=54684 native_gap=1 shim=3bd193e54785b5db` ⇒ 四条（`alive`／`app_rc∉{134,139}`／`magenta`／`native_gap>0`）**在该趟达标** ✓。
- **队长裁定的那条真红**：`native-ledger-absent(PTS_GAP n=0)` **仍红**（现取：`PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded`，`rc=1`）—— **它没有被「转绿」**，因为门禁读的在册腿仍是旧 shim 那趟（`native_gap=0`）；而在 `t81` 自己那趟它**已不出现**（`native_gap=1` ⇒ 台账真非零）**但换来另一条红** `g10-name-off-roster(dll)` ⇒ **两份证据上门禁都是红的，只是红的族不同**。

## ⑥ 不变量／指纹：**成立**

- **四条不变量（现取 `ts=23:50:27.567565515`）**：`^run_step "` ＝ **`62`**｜`--expect` ＝ **`234`**｜`# VERIFYALL-STEPS-DECL: 62 gen=#81`｜覆盖面 ＝ **`234`** ⇒ **全不变** ✓
- **两枚哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ＝ **`IDENTICAL`**；其 `FP=d697b1e10ff48881`（＝ `BRIDGE_SRC_FP`，与 `inputs_fp` 同名不同物）⇒ **本席判：不该重写哨兵** ✓
- **`inputs_fp` 位移已如实留痕**：我现取 `input_fp` ＝ **`bf1edb1bf82c15137dab0be3d62a0d7f`**；`build/MilBridge/HANDOFF-NEXT.md:607` 的 **`cell=#1` 追写**记 `ts=2026-09-28T23:24:29.950477561+0800` 现值 ＝ `bf1edb1bf82c15137dab0be3d62a0d7fdc05fb326f02434cda2d230ca1b074de`（前 16 位与现取**逐位一致**）＋ 命令原文 ⇒ **一致** ✓（注：`evidence/**` 另有换代在飞，取值时刻已写明；`fp` 本回合前后还读到过其它值，故只作时点读数）

## ⑦ 载体落地与边界自证

- 载体：`build/MilBridge/P1-w8-step1-verify.md`（**新建**，UTF-8，**首记号 ＝ `# P1-W8-STEP1-VERIFY`，不是 `# ⏪ `**），mode **`644`**，**末行自带可复算自报口径 sha16**。
- 边界自证：**唯一写入 ＝ 本件**；未跑整趟门禁／未构建／未跑应用腿／未占显示位／未 `git add/commit/push`；`t81` 的件**一字未改**（`win32_pts.c` 现取 `ddc21eb68d2d67e8`、`exports.txt` `71d651b16c6d9d6e`、`.so` `3bd193e54785b5db` 与复核前相同）；夹具（ctypes 脚本／stuck 载体／各腿 `*.out`）**在仓外 `~/wv88y/t83/**` 且收尾删净**。

---

## `NOINFO`（具名，既不算绿也不算红）

1. `NOINFO(reason=反腿需重编译副本)`：P2（`return 0` 无副作用）与 P6（自检恒绿）的**反腿**都要一份**改过的 shim**，本任务禁构建 ⇒ 未自跑；只给检测器面证据（见 ③）。
2. `NOINFO(reason=未跑整趟门禁)`：`verify-all` 未跑（一跑即构建）⇒ `PTS-PAGES` 在整波内的端到端表现未验。
3. `NOINFO(reason=未验两页真排版)`：本增量明示**不**承诺排版可用；两页仍走页级占位（`magenta` 非 0 是降级面，不是排版面）。
4. `NOINFO(reason=LoSetDoc 真实 LS 语义无规格)`：本仓无 LineServices 语义规格 ⇒ 本件只验「参数真落盘／句柄真校验」，**不**验语义正确性。
5. `NOINFO(reason=他车道在飞)`：`inputs_fp` 多值位移、`evidence/**` 换代、以及九位行是否应随增量追写的**权威口径**（Release 冻结 vs 开发面）**归属/裁定未定**，不计入本判词。

## 推翻的话 ＋ 结论

- **推翻／点名（不翻「实现本身诚实」这一主结论）**：
  1. **C4 不成立**（在册证据 `entry=` 面**未换代**；`t81` 那趟的 `dll:NotImplemented` **不可回溯** ⇒ 按其自己的判法即红）。
  2. **C5 不成立**（在册 `native_gap=0` 且 `rc=1`；`t81` 那趟 `native_gap=1` 仍 `rc=1`）。
  3. **P4／④ 同趟性不成立（现场即红）**：在册腿 `DEV shim=2a5165700a8c8579` ≠ `so16=3bd193e54785b5db`。
  4. **⑤ 零症状回归在册面不成立**（两 `leg_*.env` 与 `HEAD` 逐字节相同 ⇒ 无新读数）；`native-ledger-absent` **仍红**（在 `t81` 那趟换成 `g10-name-off-roster(dll)` 红）。
  5. **C1 的九位行未追写**（文档面仍 `6825dd7071387a46`）；**P5 的必红 token 与实现不一致**（`FAKE-PROGRESS` vs `reason=ledger-nonzero-frontier-unchanged`）；**`F-①`** 自检调用史敏感。
- **逐条成立**：**① 诚实性成立**（per-`ploc` 真落盘、两对象可区分、非单例、计数自洽；未知／`NULL`／重复销毁／销毁后句柄一律 `-10000` 且不 deref）｜**C2／C3 成立**（缺口 99→97 减幅＝2，三格同幅，`FRONTIER_STATE=NAMED`）｜**C6 部分成立**（自检已导出且会红）｜**⑥ 成立**（四条不变量、哨兵 `cmp IDENTICAL`、`cell=#1` 追写与现取一致）。
- **结论**：本件判词 ＝ **① 成立｜② C1 部分成立、C2 成立、C3 成立、C4 不成立、C5 不成立、C6 部分成立｜③ P5 成立（token 一处不一致）、P3 成立、P2/P6 `NOINFO`｜④ 不成立｜⑤ 不成立（在册面）｜⑥ 成立｜⑦ 成立**，附 **1 处 low（`F-①`）＋ 1 处观察（`O-①`）＋ 5 条 `NOINFO`**。
  ⇒ **本增量在「源码／导出／缺口／台账」四面是真前进**（`nm`=`exports`=`561`、缺口 `99→97`、`impl 93→91`、`FRONTIER_STATE=NAMED`、`PTSGAP=PASS`），**但「在册腿证据」未随趟换代** ⇒ **C4／C5／P4 三条在门禁读面上拿不到绿** ⇒ 若要按 W13 关账，**必须先重跑并换代在册腿证据**（那是 `t78` 型的一次换代，归写者，不在本席写域）。

P1-W8-STEP1-VERIFY: t83 attempt 2 | ① 诚实性成立（ctypes 第二实现：A/B 两上下文 LoSetDoc(1,0,11/22/33/44) vs (0,1,55/66/77/88) ⇒ probe [1,0,11,33] vs [0,1,55,77]；LoSetBreaking 7 vs 9；未知 0xdeadbeef/NULL/重复销毁/销毁后 ⇒ 全 -10000 且不 deref；报告计数 loc_creates=2 loc_destroys=2 loc_rej=1 setdoc_sets=2 setdoc_rej=3 setbrk_sets=2 setbrk_rej=2 与调用序逐项吻合）＋F-① low（自检调用史敏感：全新进程 rc=1 diag=0 ⇒ 调过 LoCreateContext+LoSetDoc 后 rc=0 diag=25/32）＋O-①（探针是调用史镜像，已销毁对象的旧记录仍在）｜② C1 部分成立（nm=561=exports 561 ∧ >557；两新符号在册；SelfCheck 3→4；**但九位行未追写，仍写 win32shim=6825dd7071387a46 而现盘 .so=3bd193e54785b5db**）｜C2 成立（mapped 明细命中 0；汇总 99→97 减幅=2=真补入口数）｜C3 成立（PTSGAP=PASS tool=97 dead=11 artifact=1 ops=85 impl=91 so16=3bd193e54785b5db exports=561；99/87/93→97/85/91 各减 2；FRONTIER_STATE=NAMED frontier=LoSetDoc）｜C4 不成立（在册 evidence entry= 仍 2 entry=LoSetDoc 未换代；t81 那趟 2 entry=dll:NotImplemented + 1 entry=LoAcquirePenaltyModule，NotImplemented/dll 上游命中 0 ⇒ 不可回溯）｜C5 不成立（在册 native_gap=0 且 rc=1 fails=native-ledger-absent；t81 那趟 native_gap=1 但 rc=1 fails=g10-name-off-roster(dll)）｜C6 部分成立（已导出且会红；探针不互校）｜③ P5 我自造反腿成立（PTSGAP_FRONTIER_CARRIER=stuck + PTSGAP_FR_BASELINE_IMPL=999 ⇒ rc=1 ＋ FAKE-PROGRESS impl=91 < 基线 999 而前沿仍是 LoCreateContext ＋ PTSGAP=FAIL；正腿 rc=0 PTSGAP=PASS）＋token 不一致 low（判据期望 reason=ledger-nonzero-frontier-unchanged）｜P3 现场即红（off-roster=dll 点名）｜P2/P6 NOINFO（反腿需重编译副本，禁构建）｜④ 同趟性不成立（在册 DEV shim=2a5165700a8c8579 ≠ so16=3bd193e54785b5db；t81 那趟 == so16 但非门禁读面）｜⑤ 在册面不成立（leg_23/24.env 与 HEAD 版逐字节相同、mtime 23:04:40、native_gap=0）；t81 那趟 alive=yes/app_rc=143/magenta 50094,54684/native_gap=1；native-ledger-absent 仍红如实｜⑥ 成立（不变量 62/234/62 gen=#81/234；哨兵 cmp IDENTICAL FP=d697b1e10ff48881 不该重写；inputs_fp bf1edb1bf82c15137dab0be3d62a0d7f 与 HANDOFF-NEXT.md:607 cell=#1 追写 ts=23:24:29.950477561 前 16 位一致）｜⑦ 载体新建 UTF-8 首记号 # P1-W8-STEP1-VERIFY mode 644 末行自报｜HEAD 7a89ad7｜NOINFO 5 条
SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-w8-step1-verify.md | sha256sum | cut -c1-16`）= `0ec05f3fb48f9059`

## ⏪ **`t89` dated 追加 —— `t83` 余项关账（仪器面/口径面）＋ 九位「历史 vs 现盘」分辨 ＋ 哨兵世代标签分辨**（读时 `ts=2026-09-29T00:1x+08:00`；**本节为追加，上文一字未删**）

### §A 九位：「历史 vs 现盘」三个不同的物（本条取代 `t83` 的「九位行未追写」读法）
- **① 历史（不许改写）**：`build/MilBridge/HANDOFF-NEXT.md` 顶部「九位（`#77` 冻结值；取法见 §7-2）」那一行 ＝ **`#77` 冻结世代**的值；紧随其下 `⏪ **dated 对齐（`t58`…）**：**现九位（现取，`#80`）**…` 那一行 ＝ **`#80` 冻结世代**的值。两行都是**冻结世代的历史对比**，`t83` 说它们"未追写"**属实但不构成缺陷** —— **不许**把世代值改写成当盘值（那会把"历史"抹掉）。
- **② 另一个物（`cell=#9`）**：`HANDOFF_MV` 的 `cell=#9` 判的是**权威路径表**（`build/MilBridge/tools/wave-freeze-consistency-check.py` 的 `NINE_PATHS` → 首个 `]`），现取 `f951e80b55e85782`，`handoff-machine-values-check.sh` 报 `state=equal`。**它与"九件产物 sha16"不是同一物**：一个判「**路径表**有没有被改写」，一个记「**九个产物**当时是什么」。⇒ 引 `cell=#9` 时**不得**读成"九件 sha16 对上了"。
- **③ 现盘九值（本席现取快照；`ts=2026-09-29T00:1x+0800`；取法＝按上面那张 `NINE_PATHS` 现取，`{CFG}` ⇒ `Release`）**：
  | 位 | 现盘 sha16 | 路径 |
  |---|---|---|
  | `bridge` | `4e25e4b27d4d5ae1` | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` |
  | `pc` | `5b6cfda3e12b84fc` | `build/PresentationCore.Linux/bin/Release/PresentationCore.dll` |
  | `pf` | **`b3f0d129f0234b58`** | `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` |
  | `windowsbase` | `9e860cbeecb352e1` | `build/WindowsBase.Linux/bin/Release/WindowsBase.dll` |
  | `provider` | `24e4e0a731dbed40` | `build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll` |
  | `win32shim` | **`3bd193e54785b5db`** | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` |
  | `wic_shim` | `f7b3026c8c019be2` | `build/DirectWrite.Linux/wic-shim/libwpfwic.so` |
  | `hbtextline` | `921ba9c65e9fb3be` | `build/shims/PresentationCore.HbTextLine.cs` |
  | `dwf` | `c83be96f18759edc` | `build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll` |
- **④ 本波（`#81`）内的移位（如实记，带来源）**：`win32shim` `2a5165700a8c8579` → **`3bd193e54785b5db`**（`t81` 的 native 增量：`LoSetDoc`／`LoSetBreaking` 诚实实现）；`pf` `8ef62d37e7c2ce2e`（在册旧值）→ `cff36ea4c64455e4`（**本席 `t87` 的 before 构建**）→ **`b3f0d129f0234b58`**（**本席 `t87` 终态构建**：`entry=` 归因修复）。⇒ **本波收尾时须再取一次「现盘九值」**（若其后又移位），并与 `#80 九值` 并列写清「谁是谁的历史」。

### §B 哨兵世代标签（队长 `t89` 追加裁定 ①）：`w80-freeze`/`#80` **与现盘一致**，不许改
- `HANDOFF_MV` 的 `cell=#3`（§7-1 冻结世代）现取仍 `BASELINE-FROZEN gen=#80 sha16=…` 且 `state=equal` ⇒ **当前冻结世代仍是 `#80`**。
- 而 `#81` 是**波号**（`verify-all.sh` 首行 `# VERIFYALL-STEPS-DECL: 62 gen=#81`）—— **与"冻结世代"不是同一量**（量名看着像，所指不同）。
- ⇒ 哨兵写 `WAVE=w80-freeze`／`BASELINE=#80` **与现盘一致**；**不许**为"跟上 `#81`"改写哨兵；`t86` 报的「逐键一致、唯 `WAVE`/`BASELINE` 与 `#81` 不一致」按本条**判为不构成缺陷**。**本席从未写哨兵。**

### §C `t83` 判词的**时点**（队长 `t89` 追加裁定 ②）：`C4`/`C5` 的前提已被刷新
- `t83` 的「**`C4`／`C5` 在在册面不成立**」＋「同趟性不成立」＋「在册零回归不成立」**只对它的那个时点成立**（当时在册腿证据**未随趟换代**：`DEV shim=2a5165700a8c8579` ≠ `so16=3bd193e54785b5db`、`native_gap=0`）。
- **现取（本席自算，默认证据目录；`ts=2026-09-29T00:1x+0800`）**：`bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` ⇒ **`rc=0`**／`PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared`／**`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`**；在册 `app_g1.log` 现取 **`3 entry=LoAcquirePenaltyModule`**（`sha16=e348b4ef70ab521e`）、`leg_23.env` 现取 `NAMED managed_unavail=1 err=-10000 native_gap=1 native_err=-10000`。
- ⇒ 「那条真红 `native-ledger-absent(PTS_GAP n=0)`」已被 **W8 增量（`native_gap 0→1`）＋ 在册重取（`t86`）** 消解；**判据件本趟只读**（`pts-pages-guard.sh` 未动）。⇒ 读 `t83` 判词时**必须同时读它的时点**，不得读成现行结论。

### §D P5 反腿 token 口径（本件关账 ②；落点在工具件）
- 判据件 `build/MilBridge/P1-w8-step1-criteria.md` 的 P5 行**逐字**要求 `FAIL reason=ledger-nonzero-frontier-unchanged`，且同件「必红的判法（统一）」写明「红而不点名（缺 `reason=`／缺 `file:` 或字段名）⇒ **该条判据判不成立**」。
- 实现 `build/MilBridge/tools/pts-gap-count-check.sh` 原只给字段名（`impl=`／`基线`／`前沿仍是 <名>`）⇒ **本席选"补 token"**（判据件**不动**：它已由 `t81` 当契约用过；补的是**期望 token 本身**，不改判定实质）。
- **成对读数（本席自造仓外夹具 `~/t89-runner/p5/stuck.log` ＝ 一行 `entry=LoCreateContext`；`PTSGAP_FR_BASELINE_IMPL=999`）**：改前 `rc=1` ＋ `FAKE-PROGRESS impl=91 < 基线 999 而前沿仍是 LoCreateContext ⇒ …（假进度）`（**无 `reason=`**）⇒ 改后 `rc=1` ＋ **`FAKE-PROGRESS reason=ledger-nonzero-frontier-unchanged impl=91 < 基线 999 而前沿仍是 LoCreateContext ⇒ …（假进度）`**；工具 `--selftest` 改前改后**同值**：`PTSGAP_SELFTEST=PASS pass=9 fail=0 legs=9 must_red=6`；工具件 `4f31e67461e13090` → **`450938d411489c15`**（模式 `755` 保）。

### §E `F-①`／`O-①` 调用史约束（本件关账 ①；落点在纪律区）
- 已升格为 **`build/MilBridge/HANDOFF-NEXT.md` 纪律第 `30` 条**（口径句逐字＋现场成对读数＋机制原文＋条在位自检命令），本件不再复写；**成对读数**（本席现取，`so16=3bd193e54785b5db`，`ts=2026-09-29T00:13:16.217+0800`）：自检 fresh ⇒ `rc=1 diag=0`｜先建活上下文 ⇒ `rc=0 diag=25`（报表 `loc_live=2`）｜先写 doc/brk（已收干净）⇒ `rc=0 diag=32`（报表 `setdoc_sets=1 setbrk_sets=1 calls=2`）；探针 `probe(live)=(1,0,[1,0,11,33])` ⇒ **销毁后同值**（调用史镜像）、未知句柄 `(0,…)`。夹具＝仓外 `~/t89-runner/fixt_probe.py`（Python＋`ctypes`，**不构建/不起应用/不占显示位**）。
SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-w8-step1-verify.md | sha256sum | cut -c1-16`）= `675d68a45c1b3694`（**本行系 `t89` 追加后的口径**；上一行 `0ec05f3fb48f9059` 是 `t83` 当时的正文口径，**原样保留**）

- ⏪ **同趟更正（`t89`／`scribe`，`ts=2026-09-29T00:16:0x+0800`）**：上一条里引的 P5 反腿输出**位置口径**更正 —— 实现最终落法是**行尾追加**（目的是让**旧句成为新行的逐字前缀**，使「只增不改」可机器证：`旧句 in 新行` 为真），故**原样输出**是：`  FAKE-PROGRESS impl=91 < 基线 999 而前沿仍是 LoCreateContext ⇒ **名字离开名单而能力为 0**（假进度） reason=ledger-nonzero-frontier-unchanged`。工具件终值 `4f31e67461e13090` → **`e490ab4ea9fea678`**（338 行／模式 `755`／`numstat 8 1`；那 `1` 个删行 ＝ 被改写的那条红行，其**全文是新行的前缀**）；`--selftest` 前后同值 `PTSGAP_SELFTEST=PASS pass=9 fail=0 legs=9 must_red=6`；正腿 `PTSGAP=PASS tool=97 dead=11 artifact=1 ops=85 impl=91 so16=3bd193e54785b5db exports=561`（`so16` 与现盘 shim 同值）。判据件 `P1-w8-step1-criteria.md` 的 P5 期望 token 与「红必点名」判法**均满足**（token 在行尾，仍可 `grep`）。
SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-w8-step1-verify.md | sha256sum | cut -c1-16`）= `a95ecd660bf01318`（**本行系 `t89` 同趟更正后的口径**；其上分别是 `t83` 的 `0ec05f3fb48f9059` 与 `t89` 首次追加的 `675d68a45c1b3694`，**均原样保留**）
