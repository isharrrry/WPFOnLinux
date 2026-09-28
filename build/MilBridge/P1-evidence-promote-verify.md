# P1-EVIDENCE-PROMOTE-VERIFY —— `t78`（在册证据换代）**独立复核判词**

> 复核者 `verifier`（任务 `t79`）。**只读仓树**：未改 `t78` 的任何件、未跑整趟门禁、未构建、未跑腿、未占显示位、未 `git add/commit/push`；**唯一写入 ＝ 本件**（`build/MilBridge/P1-evidence-promote-verify.md`）。
> 一切现取自算；**未引 `t78` 的输出当证据**（其载体只用于对照它**自称**的值），**未引我自己早前报告**。夹具/落盘只在仓外 `~/wv88y/t79/**`。

---

## §0 快照（现取，逐条带亚秒 `ts=`）

| 项 | 现取值 | `ts=` |
|---|---|---|
| `HEAD` | **`b47cf09`**（`docs(#81): t78 在册证据换代入账 —— 门禁真读的 app_g1.log 由 entry=un…`，`2026-09-28T23:10:00+08:00`）——**换代已被队长提交入账** | `2026-09-28T23:10:51.846154141+08:00` |
| `HEAD^`（换代前） | `61ee3c3`（`2026-09-28T21:00:35+08:00`） | 同上 |
| 证据件 | `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log`：工作树 **`3729b8b5aa6b3f8d`**（1364 行/125211 B，mtime `23:04:36.935019761`）**== `HEAD` 版**；`HEAD^` 版 **`cb0a3e5510b07790`**（1137 行/108365 B） | `23:10:51.846154141` |
| 判据件 | `build/MilBridge/tools/pts-pages-guard.sh`：现盘 **`9b46dc9b3fbfda32`／643 行**（mtime `23:08:51.234778803`）｜`HEAD` 与 `HEAD^` 均 **`59bffc8e5b5a621a`**（483 行，**未提交**） | `23:09:49.016630400` |
| `t78` 载体 | `build/MilBridge/P1-evidence-promote-report.md` ＝ `03d59d1a23af2f7e`／262 行（已跟踪） | `23:10:28.037994234` |
| `porcelain` | 证据目录下**余未跟踪新件**（`arm_A/app_g1.log`、`arm_A/arm_A/`、`arm_A/device/`、`arm_A/five_*_g1.txt`、`arm_A/session.txt`、`arm_A/shots/`）；口径＝**只说明「工作树 vs `HEAD` 的差」，不说明写者数** | `23:10:51.846154141` |

---

## ① 换代是「换代」而不是「改语义」：**成立（附 `F3`／观察 `O1`）**

- **提交级对拍（最硬的一条）**：换代那笔 `b47cf09` 的 `numstat` **不碰判据** —— `git diff --numstat HEAD^ HEAD -- build/MilBridge/tools/pts-pages-guard.sh` ＝ **`0` 行**；`verify-all.sh`／`build/close-wave.sh` 亦 **`0`／`0` 行** ✓
- **证据件新旧自洽**：新 `app_g1.log` `3729b8b5aa6b3f8d`／1364 行／125211 B；旧（`HEAD^`）`cb0a3e5510b07790`／1137 行／108365 B；该笔对它的 `numstat` ＝ **`582 355`**（换代非「小改字」）✓
- **同趟配套件自洽**：换代笔同时改 `session.txt`（`24 22`）／`five_pre_g1.txt`（`4 4`）／`five_post_g1.txt`（`4 4`）／`leg_23.env`（`3 3`）／`leg_24.env`（`3 3`）／`arm_A/leg_23/24.env`／`device/xfwm.log`／`shots/g1/{k23,k24,last}.png`，`device.txt` **不在**该笔清单（未动）✓；整组 mtime 落在 **`23:04:07.068–23:04:40.689`** 一簇 ✓
- **`F3`（low）**：`t78` 载体引用的判据值 `b74d2be6f9093115`（572 行）**已不是现盘**（现 `9b46dc9b3fbfda32`／643 行）⇒ 那是**时点值**，按第 `24` 条形态应带 `ts=`／声明「以现取为准」。
- **观察 `O1`**：判据现盘被**第三方**改过（`pass=40` vs `t76` 时 `pass=37`；`HEAD` 笔 `a8b8acd` 含 `W8`/预登记字样），其 `mtime 23:08:51` **晚于**换代证据 `23:04:36` ⇒ **时序上不属本趟换代**；我判「换代未改判据」，但**无法对 572 版做逐位对拍**（仓内无 572 版载体；`~/w281-scribe/bak/pts-pages-guard.sh.pre-t76` 是 483 版）⇒ 见 `NOINFO` 1。

## ② 同趟性：**部分成立 —— 新证据自身同趟，但 `before`／`after` 仍是跨趟对（点名 `F2`）**

- **新证据自身同趟 ＝ 成立**：一簇 mtime（`23:04:07`–`23:04:40`）＋**同一笔提交**＋`five_pre == five_post`（均 `bc0012e76e369f5c`）＋两腿 env 同趟（`leg_23.env`／`leg_24.env`：`alive=yes`、`app_rc=143`、`magenta=50461/55051`、`managed_unavail=1 err=-10000 native_gap=0`）✓
- **`F2`（low，点名）**：`PTSGAP_FRONTIER before=LoCreateContext@3` 的 `before` 侧**不是同趟实测**，而是判据件里的**声明常量**（现取 `pts-gap-count-check.sh`：`FR_BEFORE_NAME="${PTSGAP_FR_BEFORE_NAME:-LoCreateContext}"`／`FR_BEFORE_N="${PTSGAP_FR_BEFORE_N:-3}"`）；`after` 侧才来自载体（并随行 `carrier_sha16=3729b8b5aa6b3f8d`／`carrier_mtime=…23:04:36…`）⇒ **该 before/after 对按实现就不可能同趟**。本次换代**解决的是「`after` 侧可具名」**（`unknown`→`LoSetDoc`），**没有**解决 t75 点名的「同趟」问题；若要「同趟」字面成立，须把 `before` 改成**从上一趟载体现取**（或在册句里明确写「`before` ＝ 上一增量的声明值」）。

## ③ 归因闭合：**成立（附观察 `O2`）**

- **权威值我自己算**（不是引 `t78` 的日志）：`AUTH_SHIM` ＝ `sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`2a5165700a8c8579`**；`AUTH_PF` ＝ `sha256sum build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` ＝ **`8ef62d37e7c2ce2e`**；APPDIR 侧（`~/w67-work/app`，现取）同值 ⇒ 与换代那笔的 `AUTHORITY: shim=2a5165700a8c8579 pf=8ef62d37e7c2ce2e` **逐位相同** ✓
- **`five_pre`／`five_post` 一致**：两件**都**＝ `bc0012e76e369f5c`，其内容列 `libwpfwin32.so=2a5165700a8c8579｜wpfgfx_cor3.so=4e25e4b27d4d5ae1｜PresentationCore.dll=5b6cfda3e12b84fc｜PresentationFramework.dll=8ef62d37e7c2ce2e｜WindowsBase.dll=9e860cbeecb352e1` ⇒ 逐位相同且**含两个权威哈希** ⇒ **前后一致、归因闭合** ✓（旧批同样是 `pre==post`：备份件 `1fbedf891db7bf66`）
- **`O2`（观察）**：`AUTHORITY`／`POSTSHIM` 两行**只存在于仓外日志** `~/t78-runner/logs/legs-promote.log`（`ts=23:04` 那一趟），**仓内证据**只通过 `five_*` 携带哈希 ⇒ 建议（不代做）把该行落进证据或载体，免后人只能查到哈希、查不到「== authority」的判词。

## ④ 旧件可回溯：**成立（附 `F1`：备份面 ≠ 换代面）**

- **备份与写前值逐位相同**：`~/t78-runner/bak/evidence-pre/app_g1.log` ＝ **`cb0a3e5510b07790`** ＝ `HEAD^` 版 ⇒ `cmp` **`SAME`**；`cp -p` 保住 mtime（备份 mtime ＝ 旧件 `20:48:56.275132855`）✓；备份目录 7 件逐件现取点名 ✓；**无静默覆盖**（新件与旧件 sha16 不同、且旧值可从 `HEAD^` 与备份两路复得）✓
- **`F1`（low，点名）**：换代笔改 **12** 件、备份只 **7** 件 ⇒ **6 件未备份**：`arm_A/leg_23.env`／`arm_A/leg_24.env`／`device/xfwm.log`／`shots/g1/k23.png`／`shots/g1/k24.png`／`shots/g1/last.png`（另有 1 件「备了但未变」＝ `device.txt`）。本例因换代**已提交**，那 6 件的旧值仍可从 `HEAD^` 追溯 ⇒ 不判「不可回溯」，但「未静默覆盖」这一条**只对 7 件逐位成立**；建议备份面 ≡ 换代面（不代做）。

## ⑤ 判据真读数：**成立 —— 门禁真读到具名，且不是凑绿**

**两模式（捕获式，现取 `ts=23:10:12.282166582`）**

| 模式 | `rc` | 判词行原样 |
|---|---|---|
| 无参数 | **`0`** | `PTS_GUARD_SELFTEST=PASS pass=40 fail=0`（**注意：现盘判据已被第三方改过 ⇒ 例数 40 ≠ `t76` 时 37**） |
| `--legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`1`** | `PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=…/TextFormatting/LineServices.cs:1470`｜`PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded` |

**判「不是凑绿」的三条自算依据**：① 换代提交对判据 **0 行**（§①）；② 证据是**重跑的一趟**而非文本替换 —— 新 `app_g1.log` 的 `entry=` 面 ＝ **`2 entry=LoSetDoc`**、`entry=unknown` 命中 **`0`**、`PTS-UNAVAILABLE` 两行逐字为 `site=FlowDocumentView.DocumentPage entry=LoSetDoc err=-10000 action=page-placeholder`，且**同趟配套件（session/leg env/shots）一并换代**；③ 判据的**另一条红** `native-ledger-absent(PTS_GAP n=0)` **原样保留**（`phase=degraded` 未改、阈值未见放宽）⇒ G10 格转绿**只**来自证据侧具名化，`PTS_GUARD` 整体仍红 ✓

## ⑥ 指纹／不变量：**成立（附观察 `O3`）**

- **四条不变量现取（`ts=23:10:28.037994234`）**：`^run_step "` ＝ **`62`**｜`--expect` ＝ **`234`**｜`# VERIFYALL-STEPS-DECL: 62 gen=#81`｜覆盖面 ＝ **`234`** ⇒ **四条全不变** ✓（换代只改证据，未碰接线面）
- **两枚哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ＝ **`IDENTICAL`**；其 `FP=d697b1e10ff48881` 是 **`BRIDGE_SRC_FP`**，与 `inputs_fp` **同名不同物**（仓内口径句在册）⇒ **本席判：不该重写哨兵**（判据件与证据件都在覆盖面内，属 `inputs_fp` 面；写不写是队长的事）
- **`inputs_fp`**（逐次现取）：`b8f10edccaf381dab7ab8583c73a1510`（`ts=23:10:28.037994234`；另于本回合 `23:10` 前后读到过 `8ea520791f2a9832…`／`ead7b6488922c1c0…` —— **多车道在飞 ⇒ 现值只作时点读数**）
- **`O3`（观察，点名）**：`grep -rl 'b8f10edccaf381da' build/MilBridge docs` ＝ **`0` 件** ⇒ 本次 `inputs_fp` 位移**仓内未留痕**；对照：**证据件的换代值已留痕**（`3729b8b5aa6b3f8d` 命中 `P1-evidence-promote-report.md` 与 `HANDOFF-NEXT.md`）✓。⇒ 判「证据侧留痕成立、指纹侧未留痕」，建议收口时以 dated 补记现值（我不代写）。

## ⑦ 载体落地与边界自证

- 载体：`build/MilBridge/P1-evidence-promote-verify.md`（**新建**，UTF-8，**首记号 ＝ `# P1-EVIDENCE-PROMOTE-VERIFY`，不是 `# ⏪ `**），mode **`644`**，**末行自带可复算自报口径 sha16**（见交件消息／末行）。
- 边界遵守自证：本回合**唯一写入 ＝ 本件**（`porcelain` 本件行 `?? build/MilBridge/P1-evidence-promote-verify.md`）；未跑整趟门禁／未构建／未跑腿／未占显示位／未 `git add/commit/push`；`t78` 的件**一字未改**（判据现盘 `9b46dc9b3fbfda32`、证据现盘 `3729b8b5aa6b3f8d` 与复核前相同）；夹具仅在仓外 `~/wv88y/t79/**`。

---

## `NOINFO`（具名，既不算绿也不算红）

1. `NOINFO(reason=572 版判据无仓内载体)`：「换代前后判据逐位不变」我只能给**提交级 0 行** ＋ **时序**（判据 mtime `23:08:51` 晚于换代 `23:04:36`）＋ **G10 逻辑仍在**（`domains=`／`decl_hit` 命中 14）三路证据；**没有** t76 终态 572 行版的副本可做逐位对拍。
2. `NOINFO(reason=未跑整趟门禁)`：`verify-all` 未跑（一跑即构建）⇒ 门禁步 `PTS-PAGES` 在整波内的端到端表现未验（只验单步两模式与四条不变量）。
3. `NOINFO(reason=未核两腿 PNG 语义)`：`shots/g1/*.png` 我只核「换代了」（`numstat` `- -`）与同趟性，**未**核其像素内容（本任务禁跑应用腿、禁占显示位）。
4. `NOINFO(reason=他车道在飞)`：`inputs_fp` 的多值位移、判据现盘的 643 行版（`pass=40`）与 `porcelain` 里 `arm_A/**` 未跟踪新件**归属未核**，不计入本判词。
5. `NOINFO(reason=未核旧批 PNG/session 差异语义)`：备份侧 7 件与 `HEAD^` 逐位相同已核；**未**核旧批 `shots/*` 与 `session.txt` 的内容差异含义。

## 推翻的话 ＋ 结论

- **点名（不推翻主结论）**：**`F1`（low）** 备份面 ≠ 换代面（12 改/7 备，6 件未备份，逐条见 §④）｜**`F2`（low）** `PTSGAP_FRONTIER` 的 `before` 侧是**声明常量** ⇒ 该对**跨趟 by construction**，本次只解决「`after` 可具名」｜**`F3`（low）** 载体引的判据 sha16 为时点值（现盘已变）｜**`O1`** 判据被第三方改过（不属换代）｜**`O2`** `AUTHORITY`/`POSTSHIM` 只在仓外日志｜**`O3`** `inputs_fp` 位移未留痕。
- **逐条成立**：① 换代≠改语义（换代笔对判据 0 行、证据新旧自洽、配套件同笔同趟）｜② 新证据**自身**同趟｜③ 归因闭合（权威两哈希我自算 == 证据内两哈希；`pre == post`）｜④ 旧件**可回溯**（备份与 `HEAD^` `cmp SAME`、`cp -p` mtime 保留、无静默覆盖）｜⑤ **门禁真读到具名**（`PTS_G10_NAME=PASS observed=LoSetDoc … decl=…:1470`）且非凑绿｜⑥ 四条不变量不变、哨兵 `cmp IDENTICAL`、**不该重写哨兵**。
- **结论**：复核项 ①–⑥ 逐条成立（**② 为「部分成立」**：新证据自身同趟成立、`before/after` 同趟未解决），附 **3 处 low（`F1`／`F2`／`F3`）＋ 3 处观察（`O1`／`O2`／`O3`）＋ 5 条 `NOINFO`**。

P1-EVIDENCE-PROMOTE-VERIFY: t79 attempt 1 | ① 成立（换代笔 b47cf09 对判据 0 行、对 verify-all/close-wave 0/0；app_g1.log cb0a3e5510b07790/1137 → 3729b8b5aa6b3f8d/1364，numstat 582 355；配套件同笔同趟 mtime 簇 23:04:07–23:04:40）＋F3 载体引的判据 sha16 b74d2be6f9093115 已非现盘（现 9b46dc9b3fbfda32/643，mtime 23:08:51 晚于换代）＋O1 判据被第三方改过（pass=40 ≠ 37）｜② 部分成立：新证据自身同趟（同笔＋同簇＋five_pre==five_post bc0012e76e369f5c＋两腿 alive=yes app_rc=143）但 PTSGAP_FRONTIER before 是声明常量（PTSGAP_FR_BEFORE_NAME/-N 默认 LoCreateContext@3）⇒ 跨趟 by construction（F2）｜③ 成立：AUTH_SHIM 2a5165700a8c8579／AUTH_PF 8ef62d37e7c2ce2e 我自算 == 证据 five_* 内两哈希，pre==post；O2 AUTHORITY/POSTSHIM 只在仓外 log｜④ 成立：备份 app_g1.log cb0a3e5510b07790 == HEAD^ cmp SAME、cp -p mtime 20:48:56 保留、7 件无静默覆盖；F1 换代 12 件只备 7 件（arm_A/leg_23.env、arm_A/leg_24.env、device/xfwm.log、shots/g1/k23.png、k24.png、last.png 未备）｜⑤ 成立：无参 rc=0 PTS_GUARD_SELFTEST=PASS pass=40 fail=0；--legs evidence rc=1 PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=…/LineServices.cs:1470 ＋ PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) … phase=degraded；非凑绿（新 log entry=unknown 0 行、PTS-UNAVAILABLE×2 逐字 entry=LoSetDoc、另一条红原样保留）｜⑥ 成立：不变量 62/234/62 gen=#81/234；两哨兵 cmp IDENTICAL（FP=d697b1e10ff48881=BRIDGE_SRC_FP ⇒ 不该重写）；O3 现 inputs_fp b8f10edccaf381dab7ab8583c73a1510 仓内 0 命中（未留痕），证据换代值 3729b8b5aa6b3f8d 已在 P1-evidence-promote-report.md 与 HANDOFF-NEXT.md 留痕｜HEAD b47cf09｜NOINFO 5 条
SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-evidence-promote-verify.md | sha256sum | cut -c1-16`）= `05635a2a8a84d3c5`
