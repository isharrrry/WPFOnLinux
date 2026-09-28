# VPts — `t13` 独立复验：PTS 那一波（闭包数／判据反转／前沿独立性／23・24 两页／零回归）

**判词：`needs_revision`**（findings **F-A／F-B** 主判，**F-C／F-D** 具名；其余承重读数我**逐条独立复算通过**）。
- 车道 `verifier`（`t13`，attempt `c99b52c9-7fad-4503-9eff-f3eed21313b2`）；读时刻 `2026-09-28T09:38:36 … 09:43:55+08:00`。
- 判据先写：`~/w30x/criteria.md`（落盘先于取数）。资源现取（`09:38:36`）：`df_avail_kB=85,563,748`、`mem_avail_MB=9140`。
- **零重活**：未取槽、未跑应用腿、未跑 `verify-all`（见 §9 边界）。**只读 `$N`**；夹具全在 `~/w30x/`。

---

## §1 闭包数与分档（P1）—— 我自己端到端重算 ⇒ **逐项相符**

我自写 python 复算（**不复用其 `LIVE` 输出**；读时 `09:39:49+08:00`）：
```
MY  tool=100 dead=11 artifact=1 ops=88 stub=7 impl=95 exports=556 so16=6825dd7071387a46
identity1  tool−dead−artifact = 100−11−1 = 88 == ops=88          ✓
identity2  ops+stub          =  88+7    = 95 == impl=95         ✓
dead(11)=FsDuplicatePageBreakRecord/FsGetEmptySpaces/…/FsSetDebugFlags（全为 Pts.cs `#if NEVER`）
wrapper 误报集 5 条，其中命中 exports.txt 者 1（⇒ artifact=1）✓
```
- 取数路径我逐条核过：`tool` = `src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier all` 的 `[PresentationNative_cor3.dll]` 行数（**`awk` 口径，容忍行首空格**——我第一次用 `startswith` 得到 0，是我的解析错，非牙错）；`dead` = 该集合 ∩ `Pts.cs` `#if NEVER` 成员；`stub` = `win32_pts.c` 里 `return wpf_pts_gap("…")` 的 **7** 个调用点（名字：`CreateDocContext`／`DestroyDocContext`／`GetFloaterHandlerInfo`／`GetTableObjHandlerInfo`／`LoCreateContext`／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle`）—— 7 个都返回 `WPF_PTS_ERR_NOT_IMPLEMENTED = -10000`（`:51` 宏，`wpf_pts_gap` 尾 `return WPF_PTS_ERR_NOT_IMPLEMENTED;`）⇒ **"恒 `-10000` 的导出数 = 7" 成立**。
- **分档 10/18/60=88**：载体＝`~/w302-pts/tiers.tsv`（`tier/entry/upstream_site/reason/cost`，24,560 B），我**自己计数**：`T1-有意降级=10`／`T2-闭包内·做得到·逐跳=18`／`T3-闭包外·做件无收益=60`，合计 **88** ✓ 与在册分档一致。
- 现读牙判词（`09:38:51+08:00`）：`PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556 root=/home/links-dev/netTest/GitProj/WPFOnLinux` ＋ `PTSGAP_CITED=PASS refs=1 strict=1` ✓。
- ⚠️ **口径更正（非缺陷）**：主控给的期望「`exports 550 → 552`」与现场不符 —— 我现取 **`exports=556`**（＝`bin/exports.txt` 行数＝我 `nm -D --defined-only | wc -l` 也 556）；报告 §7.4 自己写的也是 **556** ✓；`pts-gap-decl.txt` 的 `#78` 注释记「导出 550→554」⇒ 556 应是 `#78` 之后的再一次增加。**`exports.txt` 未被 git 跟踪**（`git ls-files` 未命中）⇒ 550/554/556 的中间值**不可从库内复推**，只能凭现取。

## §2 在册数面的守卫（P2）—— 四条全成立

① 判词 **`PTSGAP=PASS`** ✓（此前 `FAIL` 已消）；② 读数行**含 `root=`** 且＝`$N` ✓；③ `build/close-wave.sh:648` ＝ `run "[5b/6] pts-gap-count-check.sh" env R="$ROOT" bash build/MilBridge/tools/pts-gap-count-check.sh` ⇒ **显式传 `R=`** ✓；④ 该步在 `close-wave.sh:646` 的 `[5b/6]`，位于 `[5/6]` 与 `[6/6]` 之间且**不在** `SKIP_VERIFY` 分支内 ⇒ **接进冻前** ✓。

## §3 反转判据：**先判可不可判**（P3）—— 证据位**已加**，且我自造三态全对

**可判性**：`leg_23.env`／`leg_24.env` **已带 `ink=`**（`428205`／`423547`，sha16 `9fb8af8d6fdebb45`／`afb1081916bd0d0d`，读时 `09:40:46`）；产者侧 `shotstat.py:17-24` 现算 `ink = total − magenta − 出现最多的底色`，`legs-to-env.py:69-71` 明文「旧产者不给该格 ⇒ 记 `-`（**不是 0**）」⇒ `t4` 顶出的"没有真实排版证据位"**已修** ✓。
**我自造形态并现看判词**（夹具 `~/w30x/forms/`，全在车道；判据件用真树 `--legs`）：
| 形态（我造） | 判词（现取） |
|---|---|
| 正极（degraded：`magenta>0 ∧ 具名行 err=-10000 ∧ native_gap≥1`） | **`PTS_GUARD=PASS legs=2/2 … phase=degraded`** ✓ |
| `N2-b` 只降级不画（`magenta=0 ∧ 具名行在`） | **`FAIL`** `leg24/23-placeholder-missing` ＋ `leg24-I1-incomplete(magenta=0 named=1)` ✓ |
| 空白（`magenta=0 ∧ 无具名行`） | **`FAIL`**（`placeholder-missing`）⇒ **空白没被读成绿** ✓ |
| `N2-b'` 类比（成功/无具名行/`native_gap=0`/`ink=0`） | **`FAIL`**（`placeholder-missing` ＋ `native-ledger-absent`） ✓ |
| 修前成对件形态（`alive=no ∧ app_rc=134`） | **`FAIL`**（`not-alive` ＋ `abort`） ✓ |
**反转期（`realized`）**：我把判据件复制到自己车道并把 in-file `phase=` 改 `realized`（`~/w30x/guard-realized.sh`，真树不动），再跑同一批夹具：
| 形态 | 判词 |
|---|---|
| `magenta=0 ∧ 无具名行 ∧ ink>0 ∧ native_gap=0`＝真实形态 | **`PASS … phase=realized`** ✓ |
| `ink=` 缺（旧产者 ⇒ `-`） | **`NOINFO`** `cannot=leg24/23(no-real-layout-evidence)` ⇒ **永不当绿** ✓ |
| `ink=0`（空白） | **`FAIL`** `no-real-ink(ink=0)` ✓ |
| 具名行仍在 | **`FAIL`**（`named-line-still-present` ＋ `I1-incomplete`） ✓ |
| native 台账仍在 | **`FAIL`** `native-ledger-still-present(PTS_GAP n=2∧phase=realized)` ✓ |
**口径住在判据件自身（`D-G142`）**：我把 `# PTS-DIRECTION:` 行从**车道副本**删掉 ⇒ `PTS_DIRECTION=FAIL reason=directive-absent` ＋ `PTS_GUARD=FAIL legs=0/2 fails=direction(missing)` ✓ ⇒ 不是只活在历史 `DECL` 行里 ✓。

## §4 四个假绿探测器（P5）—— **一个能咬、三个无实现**

- **`N2-b`（只降级不画）⇒ 真会红** ✓（上表，我自造形态）。
- **`N2-b'`（成功但 `*pInstalledObjects=NULL`）**：**仓内/车道均无"让 stub 假成功"的旋钮**（`win32_pts.c` 只有 `WPF_LINUX_PTS_DIAG` 一个环境变量，无 fake 模式）⇒ 我只能测**判据侧**类比形态（上表第 4 行 **`FAIL`** ✓）；**native 侧真形态未跑** ⇒ 该子格 `NOINFO reason=no-fake-success-knob`。
- **`N2-c`（前沿伪装）／`N3`（一次两跳 ⇒ 预期 `rc=134`）**：全仓（非 `upstream/`）与车道里**只有定义、没有实现** —— 定义在 `~/w302-pts/criteria.md:151-154`（表：「`N2-b'` 格 1 专用·新增／`N2-c` 只改报告文本·新增／`N3` 一次做两跳·新增」），且 `~/w302-pts/report.md:229` 自认「**`N3` 的 `rc=134` 是依据两条上游路径推算，未实测**」⇒ 两项**无法被我行使** ⇒ `NOINFO reason=detector-not-implemented`，**点名**：应由 PTS 车道在 `t12` 遗留项里落地（并写明它落在 shim 还是腿跑器）。

## §5 前沿读数的独立性（P6）

- **不是表序**：shim 里 `first=`／`last=` 已被明文判为不可靠，且有独立的**调用序**表 `k_pts_call_order = {0,6,7,8,2,1,3,4,5}`；`wpf_pts_frontier()`（`win32_pts.c:114-126`）沿调用序取**第一个 `g_pts_calls[i] > 0`** 的入口 ⇒ **真实调用面**（计数器在每次真调用时自增），**不是** `k_pts_entries[]` 的表序。
- **真调用的落盘形态**（车道件 `~/w12a/pts-legs-C/app_g1.log`，mtime `09:32:46`，sha16 `eb6af2e16ba2bcfb`）：`PTS_GAP entry=LoCreateContext seq=1 err=-10000 calls=1` ＋ 2× `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=LoCreateContext err=-10000 action=page-placeholder` ⇒ **`seq=1` 说明"第一个被问到且如实失败的入口"就是 `LoCreateContext`**（`CreateInstalledObjectsInfo` 已不再失败）⇒ 与"预期前沿 idx6"（`LoCreateContext` 表序 6）一致 ✓。
- **`t4` 对 `W78A §2.1` 的更正**：`W78A-report.md:170` 称 `GetFloaterHandlerInfo`「上下文创建期**无条件**调用」；t4 更正为"不在创建链上 ⇒ 预期前沿由 idx4 改 idx6"。**操作结论（idx6）我核得住**（§上）；但我现读 managed 侧 `build/PresentationFramework.Linux/PtsCache.Linux.cs`：`CreatePTSContext`（`:507`）**体内**确实调 `InitFloaterObjInfo`（`:526`）／`InitTableObjInfo`（`:527`）⇒ **"4/5 绝不在创建链上"这句要限定**（若链走到那一步它们会被调到；`W78A:170` 那句"无条件调用"并非纯粹臆造）。**观测面**足够判当前前沿（`seq=1` 已存在），故该格不判红，仅作口径更正。

## §6 进度口径与在册数面（P7）

- **进度＝具名前沿跳数**：报告 §7.3 三句限定里第 ② 句逐字「**`impl` 变小（97→95）≠ 进度**（本趟的进度度量是**前沿跳数**）」 ✓，且 `TASK-0302` 行仍 `🔴`（`docs/ROUTES.md:226`）⇒ 没有拿缺口条数当进度；`#66` `P03` 的假进度形态（3 个 `Lo*` 名字离开名单而能力为 0）在本口径下**会被"前沿是否真位移"挡住** ✓。
- 三个数现取（`09:39:06`／`09:39:27`）：`impl=95` ✓（`ROUTES:226` 由 t52 备份的「**97 条**」改为「**95 条**」，我 diff 过 `~/w12a/backup-ROUTES.md.t52` 的同名行）｜`exports=556`（见 §1 口径更正）｜`so16=6825dd7071387a46`（＝我 `sha256sum` 现取）✓。
- **在册面复述位**：我 grep 全仓非 `upstream/` 后，仍含旧值 `impl=97` 的**唯一非夹具处**是 **`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt:36`** 的 `#78` 注释（`…#78 重锚…ops=88/impl=97/…由本趟 LIVE 现算逐字段相等，未动`）⇒ 见 **F-D**；另有 `docs/WAVE77-PREREGISTRATION.md:144`／`build/MilBridge/P0-w77-report.md:67` 属**历史转述**（记 `W77` 当时的现场），不构成本波陈旧复述 ✓。

## §7 第 23／24 两页**分开**复核（P8）—— 数字真、但**载体在车道**

我用**仓内 `shotstat.py`** 对自己选的 PNG 现算（读时 `09:42:26`）：
| 页 | 车道新件（`~/w12a/pts-legs-C/shots/g1/`） | 仓内在册旧件（`evidence/shots/g1/`） |
|---|---|---|
| **24** `FlowDocumentDemo` | `colors=851 magenta=54826 total=1310720 ink=423547` | `colors=851 magenta=54454 ink=423896` |
| **23** `RichTextBoxDemo` | `colors=843 magenta=50236 total=1310720 ink=428205` | `colors=843 magenta=49864 ink=428554` |
逐页落盘证据（`evidence/leg_2{3,4}.env`）：两页均 `alive=yes app_rc=143`，`ink=` 在位，`NAMED managed_unavail=1 err=-10000 native_gap=1 native_err=-10000`，`DEV x_up=yes five_stable=yes shim=6825dd7071387a46 pf=876f70dd7c0cbf7a`（**＝authority**）✓ ⇒ **装配口径的硬闸口径成立**（旧世界 `shim=fc60c34d51fd9247`／`pf=cbd1884faeb4837e`）。
**分开性**：报告 §7.3 是**逐页**表；第 23 页另附「不在射程内（≈27 条额外）」的限定 ✓；我未见任何"用第 24 页结论盖第 23 页"的句子 ✓。两页 `magenta ≥ 20000` ⇒ **止损仍在** ✓。

## §8 🔴 findings（本环主判）

### F-A（`blocker`）仓内在册证据**不支撑**所声称的前沿位移
- 我现取（`09:42:05`）：**`$N/build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log`** ＝ mtime **`2026-09-24 20:43:01`**、sha16 **`3a3544fe9d6f8132`**、**3 处 `entry=CreateInstalledObjectsInfo`**、`git status` 里**未修改**（仍是 `#50` 那一代）；而同目录 `leg_23.env`／`leg_24.env`／`device.txt` 是 **09-28 09:33** 的新件；`evidence/shots/`、`session.txt`、`five_*_g1.txt` 亦仍是 **09-24 20:43**。
- 位移读数只在**车道**：`~/w12a/pts-legs-C/app_g1.log` mtime `09:32:46`、sha16 `eb6af2e16ba2bcfb`、**3 处 `entry=LoCreateContext`**。
- ⇒ **同一 `evidence/` 目录里两代混装**：腿参数/`DEV shim` 是新代，具名行与截图是旧代；而门禁 `verify-all.sh:1173` 的 `PTS-PAGES` 读的正**是**这个目录（`verify-all.sh:668` 默认 `PTS_EVIDENCE_DIR=build/MilBridge/tests/PtsPagesProbe/evidence`）⇒ **门禁绿只读 env 列，读不到 `entry=`**，故"绿"对前沿位移**零证据力**；在册记录反而写着"前沿没动"。
- `requiredFix`（两条选一，**具名、不许混着留**）：**（甲）** 把本代两页证据（`app_g1.log`／`shots/g1/*.png`／`session.txt` 等）按仓内既有形态落进 `evidence/`（**同趟**声明 `inputs_fp` 位移与读取时刻 —— 该目录**在覆盖面内**，我现取 `infp` 清单含 21 件 `PtsPagesProbe` 条目）；**（乙）** 若设计上"该目录只放上一代已发布证据、本代证据留车道"，则必须在报告 §7.3 与 `PTS-GAP` 行旁**具名载体**：车道路径 ＋ sha16 ＋ 读取时刻，并写明"复算需该目录"。
### F-B（`high`）报告 §7.3 的「新证据已入 `evidence/`」是**夸大**
- 只有 3 件（`device.txt`／`leg_23.env`／`leg_24.env`）是新代；`app_g1.log`／`shots/`／`session.txt`／`five_pre|post_g1.txt`／`arm_A/`／`device/` 仍是 09-24。`requiredFix`：逐件写明"本代已入/未入"，或按 F-A（甲）整批落仓。
### F-C（`medium`）`N2-c`／`N3`（及 native 侧 `N2-b'`）**无实现**，`N2-b` 之外三个探测器**无法被行使**
- 见 §4：仓内/车道只有定义（`~/w302-pts/criteria.md:151-154`），且 `~/w302-pts/report.md:229` 自认 `N3` 的 `rc=134` **推算未实测**。`requiredFix`：由 PTS 车道实现并落 `t12` 遗留项（写明落在 shim 还是腿跑器、给可重放命令），否则本环"四个探测器必红"只能记 `NOINFO`。
### F-D（`low`）`pts-gap-decl.txt:36` 的 `#78` 注释仍写 `impl=97`
- 机器行已是 `impl=95`；牙的引用面（`PTSGAP_CITED`）不扫该注释 ⇒ 现场留下"声明件自己说 97"的陈旧句。`requiredFix`：改注释（或标注为 `#78` 历史值）。

## §9 零回归 / 全局 / 诚实性（P9–P11）与边界

- **零回归**：`bash build/check-appliers.sh` ⇒ `APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0` ✓；`Invariant.Assert` 计数：现件 `build/PresentationFramework.Linux/PtsCache.Linux.cs` **32** ＝ `t12` 前备份（`~/w12a/backup-PtsCache.Linux.cs.t12`）**32** ⇒ **未减** ✓；A2 的 `catch` 已补释放：`:272-273` `if (created.InstalledObjects != IntPtr.Zero) PTS.IgnoreError(PTS.DestroyInstalledObjectsInfo(created.InstalledObjects));`（且注释具名上游唯一释放口被绕过）✓。
- **九位/步数/哨兵/推送**：`ACCEPTANCE-BASELINE.md=901619543b3d913b` ✓；`HEAD=71603bd` ＝ 远端 `ls-remote` ✓（**未重推/未重冻**）；`run_step=55`／`DECL 55 gen=#79` ✓；两哨兵 `cmp` **IDENTICAL**（`BASELINE=#79`／`BASELINE_SHA16=901619543b3d913b`；`PROVIDER=8cb1b50619f4c133` 为在册重建位）✓；`PTS-PAGES` 步在 `verify-all.sh:1173`（`--legs "$PTS_EVIDENCE_DIR"`）✓。`~/w21-verify/w79-POST.done`（0 B，`mtime 01:12:39.388`）＋ `w79-pre.sha` 与 `CURRENT-STATE.md:9` 自洽 ✓。
- **计数读数带读时刻**：`inputs_fp = c5c032d0bc75e19950ddb088bea7edd545b101e383ef475611e6aae4c64a4f0c`／**226** 件 @`2026-09-28T09:42:35+08:00`（与主控 `09:41:22` 现取一致）。
- **收手边界诚实性**：in-file `phase=degraded` ✓；`docs/ROUTES.md:226` 的 `TASK-0302` **仍 `🔴`**、判词句未改、数由**97→95** 同趟改准 ✓（与机器读数一致）；报告 §7.3 **带三句限定**（前沿位移 ≠ 渲染／`impl` 变小 ≠ 进度／第 23 页不在射程内）✓。
- **边界／`NOINFO`**：① 我**未跑应用腿**（零重活）⇒ "正极（现件）＋两条反极各跑一趟"的**应用级**部分我以**判据件等价形态**（§3 表）完成，应用级 `PTS_GUARD=PASS` 我以**现读其落盘证据**（`leg_2{3,4}.env`，`09:33`）＋**自己现算 PNG** 复核 ⇒ 应用级三趟记 `NOINFO reason=no-app-run-this-pass`；② `hbtextline`／`pc` 的**成对像素四区**与 `BrushDemo` 的 `compare -metric AE` 我**未复算**（不属本波交付面，其载体在 `hbtextline`/`pc` 波；本件只核到 `check-appliers` 与两页 `ae=`/`colors=` 现值）⇒ `NOINFO`；③ `N2-b'`（native 侧）／`N2-c`／`N3` 见 F-C。
- **我推翻/更正的话**：① 主控期望的 `exports 550→552` ⇒ 现取 **556**（§1）；② `W78A`-更正里的「4/5 不在创建链上」需限定（managed `CreatePTSContext` 体内确有 `InitFloaterObjInfo`/`InitTableObjInfo`，§5）；③ 报告 §7.3「新证据已入 `evidence/`」⇒ **只入 3 件**（F-B）；④ `t4` 说的"`leg_*.env` 没有真实排版证据位"⇒ **已修**（`ink=` 在位，§3）。

## §10 落仓与自指

车道件 `~/w30x/t13-verify.md` 与仓内件 `build/MilBridge/VPts-verify-report.md`（逐字节相同、`temp+rename`、`%h=1`）。
自指口径：`head -n -1 <本件> | sha256sum | cut -c1-16`。
