# P1-W4b 修复报告（第二轮 · `t57`＝`t55` 判 `needs_revision` 的 G1–G4）—— 交件载体

⏪ **§0 判据（先写）**：① 一切数值**现取＋给命令＋给 `ts`**；② 成对读数两值都给；③ **自证值只携末行**（`head -n -1`），本报告不写自身全文 `sha16`；④ `NOINFO` 具名；⑤ 改写既有件**显式保模式**。读时 `ts=2026-09-28T18:23:28.762+0800`。

⏪ **§1 G1（high）已闭：`cell=#8` 换判据 —— 从「全机脏件数」改成「被门禁覆盖的世界的函数」**
⏪ **旧判据的病**（队长现取）：旧命令 `git status --porcelain | grep -vE ... | wc -l` 的排除前缀只有 `build/`／`docs/`／根 `verify-all.sh`，**漏 `samples/`（缺陷册住这里）／`src/`／根件** ⇒ **任何别的车道改 `KD` 都会把已接线的门禁步打红**（实测 `18:13:34` 改 `KD` ⇒ 该格 `0→1` ⇒ `HANDOFF_MV=FAIL`；`18:15:23` 提交 ⇒ 回 `0`；**3 分 25 秒摆动 3 次**）。
⏪ **新判据（甲案）**：`cell=#8` ⇒ **本波预登记在位谓词** —— 命令 `test -s docs/WAVE81-PREREGISTRATION.md && echo in-wave-81-registered || echo no-registration`，现取 **`in-wave-81-registered`**；**锚一并改写**（现取 `anchor=§2 在飞（本波预登记在位谓词…）`）。「其它车道在飞」的信息**只进旁注**：`HANDOFF_MV_NOTE lane-activity=0（= 写域面（build/ docs/ samples/ src/ 根件）之外的脏件数；**旁注，不进 equal 计数、不影响 rc**）`（**不进 `equal`、不影响 `rc`**）。**腿①（有牙证明）**：夹具把该格谓词改错 ⇒ `HANDOFF_MV_HIT cell=#8 anchor=§2 在飞（本波预登记在位谓词…） rule=cell-mismatch reason=cell-value-changed-since-ts` ＋ `HANDOFF_MV=DIVERGED … mismatch=2`（**点名该格** ✓）。

⏪ **§2 G2（medium）已闭：报头分化 ＋ 逐格 `reason=`** —— `HANDOFF_MV=PASS`（`rc=0`）／**`HANDOFF_MV=DIVERGED reason=cell-mismatch`**（有格与现取不符 ⇒ 追写 dated 更正行）／**`HANDOFF_MV=FOREIGN reason=cell-not-comparable`**（差异源**不在本件写域**：拒收族/不可比格）／**`HANDOFF_MV=NOINFO reason=…`**（表/锚缺失、行数≠9、不可读）。**逐格归因**现取：`reasons=#1:covered-file-changed-since-ts`／`#2|#5:count-changed-since-ts`／`#3|#6|#9:external-state-changed-since-ts`／`#4:route-file-changed-since-ts`（各 reason 名**可机读**）。实测成对：`#8` 腿① ⇒ `DIVERGED`（值过时）；`#7`／拒收族腿 ⇒ `FOREIGN`（不可比）⇒ **一个 `FAIL` 不再承担三种语义**。

⏪ **§3 G3（medium）已闭：`cell=#7` 加**真牙** ＋ 拒收族**：**腿②（专名 rule）**：夹具把 `#7` 改回机读形态（含 `现值 ＝ ` 与 `命令：`）⇒ **`HANDOFF_MV_HIT cell=#7 anchor=§7-6 推送面 rule=cell-7-not-comparable-to-HEAD reason=not-comparable cmd=git log --oneline -1 | cut -c1-7`** ＋ `HANDOFF_MV=FOREIGN reason=cell-not-comparable`（`rc=1`）⇒ **`t50` F1 的时间炸弹自此有牙拦**。**腿③（拒收族）**：夹具把 `#5` 的命令换成 `git rev-parse --short HEAD` ⇒ **`rule=cell-not-comparable-to-pipeline-state`** 点名 `cell=#5`（拒收正则 `HEAD|git log|git status|git rev-parse|git ls-remote`）。

⏪ **§4 G4（medium）已闭：自测**自主**（正极不再拿活件当夹具）**：`--selftest` 的 **S1 正极改用自造夹具**（仓外 `mktemp -d`，9 格＋9 更正行全用本地 `printf`/`echo` 命令）⇒ **闸只含 S1–S4**（夹具正极／篡改点名／行数≠9／回退），**与活件解耦**。**现取**：`HANDOFF_MV_SELFTEST_CASE case=S1 kind=positive-fixture rc=0 原样=HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none
HANDOFF_MV_SELFTEST_CASE case=S2 kind=negative-fixture rc=1 verdict=HIT-named-this-cell target=cell=#9 mismatch=1 原样=HANDOFF_MV_HIT cell=#9 anchor=夹具格9 rule=cell-mismatch reason=external-state-changed-since-ts in-repo=FIX0 live=FIX9 cmd=printf FIX9
HANDOFF_MV_SELFTEST_CASE case=S3 kind=noinfo rc=2 原样=HANDOFF_MV=NOINFO reason=table-rows!=9 got=8 anchor=逐格对照（「现取值」全部由右侧命令现跑取得 file=/tmp/tmp.pflh13wfgM/f3.md
HANDOFF_MV_SELFTEST_CASE case=S4 kind=revert rc=0 原样=HANDOFF_MV_CELL cell=#9 anchor=夹具格9 state=equal table=FIX9 corrected=FIX9 live=FIX9
HANDOFF_MV_SELFTEST_CASE case=S5 kind=autonomy-stale-production 陈旧活件沙箱下 selftest=PASS；该沙箱的活件腿 原样=HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=4 manual=1 mismatch=4 uncomparable=0 reasons=,#3:external-state-changed-since-ts,#4:route-file-changed-since-ts,#8:cell-value-changed-since-ts,#9:external-state-changed-since-ts（**两条腿分开：自测不依赖活件；活件好坏由正极真跑判**）
HANDOFF_MV_SELFTEST_CASE case=S6 kind=production rc=0 原样=HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none
HANDOFF_MV_SELFTEST=PASS cases=5 pass=5 fail=0（闸只含 S1–S4；S5／S6 为信息腿）`（`rc=0`），其中 **S5（自主性真跑证明）**＝把**活件副本改陈旧**放进沙箱 `HMVC_ROOT` 跑 `--selftest` ⇒ **`selftest=PASS`**，而该沙箱的**活件腿** `DIVERGED … mismatch=4` ⇒ **两条腿分开**（自测不依赖活件；活件好坏由正极真跑判）✓；**S6（活件真跑）** 现取 ＝ `HANDOFF_MV_CELL cell=#1 anchor=§7-4 输入指纹 state=equal table=abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f corrected=75d21468cc3d495e7d055f515f4ff61bc9d2db8c7e047683ec4f39a4181f07f5 live=75d21468cc3d495e7d055f515f4ff61bc9d2db8c7e047683ec4f39a4181f07f5
HANDOFF_MV_CELL cell=#2 anchor=§7-4 覆盖面件数 state=equal table=226 corrected=233 live=233
HANDOFF_MV_CELL cell=#3 anchor=§7-1 冻结世代 state=equal table=BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md corrected=> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md live=> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
HANDOFF_MV_DIAG cell=#4 declared_live=222 route_ids_live=222 declared_inrepo=222 route_ids_inrepo=222（**计数不是被判量**）
HANDOFF_MV_CELL cell=#4 anchor=§7-3 登记册自洽 state=equal table=DEFREG=PASS declared=215 route_ids=215 corrected=DEFREG=PASS declared=222 route_ids=222（每个声明编号在其 req 的每个 route 文件里都在 ∧ **现场 route 出现集未超出 req**；无未声明编号） live=DEFREG=PASS declared=222 route_ids=222（每个声明编号在其 req 的每个 route 文件里都在 ∧ **现场 route 出现集未超出 req**；无未声明编号）（判据＝前缀 ∧ 两值相等）
HANDOFF_MV_CELL cell=#5 anchor=§7-5 步数 state=equal table=55（首行声明 # VERIFYALL-STEPS-DECL: 55 gen=#79） corrected=61 live=61
HANDOFF_MV_CELL cell=#6 anchor=§7-5 放行标记（**行内 glob 只覆盖 `w6*`**） state=equal table=w6*-POST.done=10／w6*-record.txt=10（**全量** w*-POST.done=25／*record*=49，最末 w77-record.txt） corrected=w*-POST.done=25／*record*=49 live=w*-POST.done=25／*record*=49
HANDOFF_MV_CELL cell=#7 anchor=§7-6 推送面 state=manual table=本地 HEAD == ls-remote == 88ab841414b6b5e2 corrected=- live=-（该格不对拍：见牙头口径句①②④）
HANDOFF_MV_CELL cell=#8 anchor=§2 在飞（本波预登记在位谓词（锚已在更正行改写；表内原锚='§2 在飞'） state=equal table=**无链在跑**（#80 已全链闭环；本件 dated 对齐 · §2 行已载） corrected=in-wave-81-registered live=in-wave-81-registered
HANDOFF_MV_CELL cell=#9 anchor=§1 九位 state=equal table=本件 dated 对齐 行已给 #80 九值；**权威路径表** ＝ build/MilBridge/tools/wave-freeze-consistency-check.py:104-115 corrected=f951e80b55e85782 live=f951e80b55e85782
HANDOFF_MV_NOTE lane-activity=0（= 写域面（build/ docs/ samples/ src/ 根件）之外的脏件数；**旁注，不进 equal 计数、不影响 rc**）
HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`。

⏪ **§5 `cell=#4` 处置（G2 附项）：改**形态判据**（不是移出 `equal`）** —— 判据现取 ＝ `^DEFREG=PASS` 前缀 ∧ **`declared=(\d+) route_ids=\1` 两值相等**；**具体计数只进诊断列**：`HANDOFF_MV_DIAG cell=#4 declared_live=222 route_ids_live=222 declared_inrepo=222 route_ids_inrepo=222（**计数不是被判量**）` ⇒ **「计数不再是被判量」**（每个登记批都会改 `declared=`，故不许拿数值当判据）。⇒ 现取 `cell=#4 state=equal` ✓。

⏪ **§6 成对读数（`ts=2026-09-28T18:23:28.762+0800`）**：**牙** `e4c13eea198753ff`／198 行 ⇒ **`cde265d7eaad36d5`／`238` 行**（模式 `644` 保位）｜**`HANDOFF-NEXT.md`** `b81567e26c29a527`／516 行 ⇒ **`3044dd66c84cc903`／`526` 行**（`#8` 换判据＋锚改写、`#4` 形态判据口径、`#1` 末次刷新，全部 dated 更正行、**原句一字未删**）｜**正极两行（修前→修后）**：修前 `HANDOFF_MV=FAIL`（`#4` 与 `#8` 格；写前 `ts=2026-09-28T18:19:12.936+0800`）⇒ 修后 **`HANDOFF_MV_CELL cell=#1 anchor=§7-4 输入指纹 state=equal table=abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f corrected=75d21468cc3d495e7d055f515f4ff61bc9d2db8c7e047683ec4f39a4181f07f5 live=75d21468cc3d495e7d055f515f4ff61bc9d2db8c7e047683ec4f39a4181f07f5
HANDOFF_MV_CELL cell=#2 anchor=§7-4 覆盖面件数 state=equal table=226 corrected=233 live=233
HANDOFF_MV_CELL cell=#3 anchor=§7-1 冻结世代 state=equal table=BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md corrected=> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md live=> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
HANDOFF_MV_DIAG cell=#4 declared_live=222 route_ids_live=222 declared_inrepo=222 route_ids_inrepo=222（**计数不是被判量**）
HANDOFF_MV_CELL cell=#4 anchor=§7-3 登记册自洽 state=equal table=DEFREG=PASS declared=215 route_ids=215 corrected=DEFREG=PASS declared=222 route_ids=222（每个声明编号在其 req 的每个 route 文件里都在 ∧ **现场 route 出现集未超出 req**；无未声明编号） live=DEFREG=PASS declared=222 route_ids=222（每个声明编号在其 req 的每个 route 文件里都在 ∧ **现场 route 出现集未超出 req**；无未声明编号）（判据＝前缀 ∧ 两值相等）
HANDOFF_MV_CELL cell=#5 anchor=§7-5 步数 state=equal table=55（首行声明 # VERIFYALL-STEPS-DECL: 55 gen=#79） corrected=61 live=61
HANDOFF_MV_CELL cell=#6 anchor=§7-5 放行标记（**行内 glob 只覆盖 `w6*`**） state=equal table=w6*-POST.done=10／w6*-record.txt=10（**全量** w*-POST.done=25／*record*=49，最末 w77-record.txt） corrected=w*-POST.done=25／*record*=49 live=w*-POST.done=25／*record*=49
HANDOFF_MV_CELL cell=#7 anchor=§7-6 推送面 state=manual table=本地 HEAD == ls-remote == 88ab841414b6b5e2 corrected=- live=-（该格不对拍：见牙头口径句①②④）
HANDOFF_MV_CELL cell=#8 anchor=§2 在飞（本波预登记在位谓词（锚已在更正行改写；表内原锚='§2 在飞'） state=equal table=**无链在跑**（#80 已全链闭环；本件 dated 对齐 · §2 行已载） corrected=in-wave-81-registered live=in-wave-81-registered
HANDOFF_MV_CELL cell=#9 anchor=§1 九位 state=equal table=本件 dated 对齐 行已给 #80 九值；**权威路径表** ＝ build/MilBridge/tools/wave-freeze-consistency-check.py:104-115 corrected=f951e80b55e85782 live=f951e80b55e85782
HANDOFF_MV_NOTE lane-activity=0（= 写域面（build/ docs/ samples/ src/ 根件）之外的脏件数；**旁注，不进 equal 计数、不影响 rc**）
HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**（`rc=0`）｜**自测** 修前 `FAIL cases=4 pass=3`（S1 拿活件）⇒ 修后 **`PASS cases=5 pass=5 fail=0`**。

⏪ **§7 四条不变量 ＋ 两牙（现取）**：`^run_step "` ＝ **`61`**｜覆盖面 ＝ **`233`**｜首行 `DECL` ＝ **`# VERIFYALL-STEPS-DECL: 61 gen=#81   ← ⏪ ``**｜`STEP-NAMES` ＝ **`61`**｜`--expect` ＝ **`fp-manifest-step.sh --expect 233`**（**两值相等、四处一致**，本波未改件数/步数）｜`DEFREG=PASS declared=222 route_ids=222（每个声明编号在其 req 的每个 `｜`SELFDESC_WIRING=PASS examined=72 wired=50 unwired=22 undeclared=51 fails=0 run_step=61`（**未回退**）｜`REPORTID=PASS files=212 ids=2107 declared=222 glob=build`｜`SSC_SELFTEST=PASS cases=4 pass=4 fail=0`／`TSORDER_SELFTEST=PASS cases=8 pass=8 fail=0`。

⏪ **§8 边界与纪律（现取）**：只写**两件**在写域内（牙／`HANDOFF-NEXT.md`）＋ 本报告；**未动** `verify-all.sh`／`build/close-wave.sh`／`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`declared.tsv`／三颗别的牙／两枚哨兵（`t56` 在复 `t53` 的那三件，未撞）；**未跑整趟门禁**；**未** `git add/commit/push`；`porcelain` 现取 `M build/MilBridge/HANDOFF-NEXT.md｜ M build/MilBridge/tools/handoff-machine-values-check.sh｜?? build/MilBridge/P1-task0201-criteria.md｜?? build/MilBridge/P1-w4b-verify.md`；夹具全部在 `mktemp -d`、仓内残留 `0`。

⏪ **`NOINFO`（具名）**：① **跨提交/跨车道第二次跑**（`#1` 是覆盖面快照 ⇒ 任何覆盖面内改动都会让它过时）⇒ 维护契约已写进牙头，**追写义务在写者**；② 「其它车道在飞」**只是旁注**（不进判据）⇒ **不判红、也不据此判绿**；③ 拒收族只覆盖**命令文本**命中正则者（命令被间接包装 ⇒ 射程外）；④ 未跑整趟门禁。

⏪ **本件自证（全文 `sha16` 只在交件消息里给；本行只携带 `head -n -1` 口径值）**：`head -n -1 build/MilBridge/P1-w4b-repair2-report.md` ＝ `125f8e907db6d48b`（口径＝**末行之前的全文**；末行＝**本行**）。
