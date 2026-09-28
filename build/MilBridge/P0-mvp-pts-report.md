# `P0-mvp-pts` —— `TASK-0302` 首个真增量（`t12`）· 落地与边界

> 车道 `t12`（成员 `pts`）｜attempt `3f11c74a-312b-4c06-802b-1904ebc971c8`
> **判词：本趟只到「格 1 落地 ＋ 单元级复算 ＋ 判据反转入位」，两页应用级复测被一个
> **仪器级阻塞**挡住（见 §3），因此**不宣称** 23/24 两页有任何改善、**不更新在册数**。**

## 1. 已落地（逐件 before/after sha16）

| 件 | before | after | 证据 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `bcb9858919e6237e` | **`73bb1ba58a264f72`** | 9 条 stub → **7 条**（`CreateInstalledObjectsInfo`／`DestroyInstalledObjectsInfo` **真实现**）；自检同步改写 |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `e8127a3d7128d417` | **`6825dd7071387a46`** | 336592→336984 B |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | 554 行 | **556** | **+2** 只读面：`WpfLinuxWin32_PtsInstalledObjectsLive`／`…Creates` |
| `build/PresentationFramework.Linux/reapply-patches.py` | `c439c7c00f09f909` | **`1769524cac043730`** | A2 `catch` 补 `created.InstalledObjects` 释放（不补＝每失败漏一块） |
| `build/PresentationFramework.Linux/PtsCache.Linux.cs` | `627c8d23aa7ef233` | **`4e2e50729b495b94`** | 重放生成（5 处改动 needle 全命中） |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `12fb36e7b0df1802` | **`876f70dd7c0cbf7a`** | `heavy-slot` 内 `dotnet build -c Release -m:1`，**81 s**，rc=0 |
| `build/MilBridge/tools/pts-pages-guard.sh` | `da8c48cc118e134e` | **`aa764a0e98e131fc`** | `phase=degraded\|realized` ＋ `I1` 三态完备性 ＋ realized 分支 |
| `build/MilBridge/tests/PtsPagesProbe/shotstat.py` | 18 行版 | **含 `ink=`** | 真实排版证据位（除占位洋红与出现最多的底色之外的内容像素） |
| `build/MilBridge/tests/PtsPagesProbe/legs-to-env.py` | —— | **`LEG … ink=%s`** | 证据位进入机读面（旧产者缺该格记 `-`，**不是 0**） |

`FlowDocumentView.Linux.cs` **未变**（`ecb0263b200c18dc`）；`PresentationFramework.Linux.csproj` 我**回退**到跑脚本前的 `e22a7457dc4a8010`（重放会把它内部 38 行**搬位**，属另一件的事，见 §5 陷阱②）。

## 2. 单元级复算（不依赖应用；`ctypes` 直调 `.so`）

```
SELFCHECK = 1                      （1 = 通过；**幂等**，连跑两次都 1）
自检后 live=0 creates=0            （自检**不改变可观测状态**）
Create  rc=0 handle=0x5d72b1468b80 count=2 live=1 creates=2
Destroy(真句柄) rc=0 live=0 ｜ Destroy(重复) rc=-10000 ｜ Destroy(未知名) rc=-10000 ｜ Destroy(NULL) rc=-10000
REPORT = PTS_GAP_REPORT mode=honest-fail entries=0 calls=0 first=- last=- err=-10000 frontier=-
         entry_calls=0:0 … installed_objects_live=0 creates=2 destroys=2 rejected=5
```
⇒ 格 1 的三条性质**真跑得到**：真分配／真表长（2 槽）／真摧毁／**不泄漏**（`live` 回 0）／**重复与未知名释放必被拒**（不 `free` 任意指针）。
新增只读面 `frontier=`／`entry_calls=`／`installed_objects_live=`／`creates=` 按 `t4` 设计进入**报告行**（`frontier=` 按**调用序**算，不信 `first=`/`last=`）。

## 3. 🔴 阻塞（本趟**没有**拿到两页的应用级复测）

`build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh` 的私有应用目录由 `~/w160a/stage-app.sh`
（mtime **2026-09-24 20:30**）装配，它把**那一代的五件**灌进 `~/w67-work/app` ⇒ 跑腿前我同步成功的
`shim=6825dd7071387a46 pf=876f70dd7c0cbf7a` 在**跑腿期间被换回** `shim=fc60c34d51fd9247 pf=cbd1884faeb4837e`：

```
PRE  app shim=6825dd7071387a46 pf=876f70dd7c0cbf7a      （我 sync-applocal.sh 后现取）
LEGS2_RC=0 shim_after=fc60c34d51fd9247                  （跑完现取 ⇒ 被换回旧件）
leg_24.env: DEV … shim=fc60c34d51fd9247 pf=cbd1884faeb4837e
            NAMED … err=-10000 native_err=-10000
[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=CreateInstalledObjectsInfo
```
⇒ **两次腿跑（`pts-legs-A`／`pts-legs-B`）测的都是 09-24 那一代**，与 authority（`6825dd70…`／`876f70dd…`）**不是同一份件**；
`DEV shim=` 这一格**如实地**报了它用的是旧件（所以这不是"无从察觉"，而是"报了没人拦"）。
⇒ 因此：**第 24／23 两页的读数本趟不可得**（`magenta=54454／49864` 与 09-24 逐字相同 = 旧世界），
`entry=` 仍是 `CreateInstalledObjectsInfo`（前沿**未**位移的证据**不成立**，因为它测的不是新件）。

**谁该做**：先修 `stage-app.sh`／跑腿器的装配口径（或让跑腿器**拒绝** `--check` 与 `DEV shim` 不一致的目录），再重跑两页 —— 那是**下一条车道的第一件事**。

## 4. 判据反转（已到位，`--selftest` 真跑）

`--selftest`：**17 → 24 腿，24/24 PASS**（原腿一条未删）。新增并真跑的极性：
- `realized·真实形态`（`magenta=0` ∧ 无具名行 ∧ `native_gap=0` ∧ `ink>0`）⇒ **PASS**
- `realized·缺 ink` ⇒ **`NOINFO reason=no-real-layout-evidence`**（**不许**因 `magenta=0` 判绿）
- `realized·占位仍在` ⇒ **FAIL** ｜ `realized·具名行仍在` ⇒ **FAIL**
- `I1`/`N2-b`（`degraded` 期「只降级不画」：`alive=yes`＋具名行在位＋`magenta=0`）⇒ **必红** ✔
- `phase` 位缺失 ⇒ `PTS_DIRECTION=FAIL` ＋ 判词必红 ✔
退化期回归：旧证据（无 `ink`）仍 **`PTS_GUARD=PASS legs=2/2 … phase=degraded` rc=0**。

## 5. 我推翻了哪句话 ＋ 两条陷阱
① **`t4` §3(a) 的"不补必漏"在旧 `pf` 上不可见**：旧 `pf` 里 `InstalledObjects` 恒 `IntPtr.Zero` ⇒ 那条 `catch` 本来漏不了；**只有格 1 落地后才漏** —— 所以这条修**必须**与 native 同趟，本趟已同趟落。
② **重放脚本会搬位**：`python3 reapply-patches.py` 会把 csproj 里**别的补丁注入的 38 行**搬到 marker 之后（`38 增 38 删`，不是新增）⇒ 跑一次就脏一次 csproj。我已回退，此陷阱入册。

## 6. 边界与 `NOINFO`（逐条）
1. 两页应用级复测：**不可得**（§3 阻塞）⇒ 不更新 `ROUTES.md` 的 `TASK-0302`（仍 🔴）、不改 `CURRENT-STATE.md:9`；
2. 在册数 `impl 97 → 95`／`so16`／复述位：**未改**（`pts-gap-count-check.sh` 会因 `stubs=7` 报 `impl=95`，但**在有应用级读数之前不改**——否则就是"用单元读数改在册口径"）；
3. 闭包实测（`t1b-ls-tripwire` 的 `LD_DEBUG` 序列）：**未跑**（要跑应用；被同一阻塞挡住）；
4. `N2-b'`（成功但 `*pInstalledObjects=NULL`）／`N2-c`（前沿伪装）／`N3`（一次做两跳 ⇒ 预期 `rc=134`）：**未跑**（要跑应用）；
5. `Nl*` 有意降级牙（`IsHyphenationEnabled` True≡False 行为等价）：**未加**（属下一趟；今天两页都不可渲染，该等价无信息）；
6. 整波链（五臂／`repin`／门禁 ×2／冻结／冻后 ×2／推送／哨兵）：**未做**（本趟只到组件级）。

---

# §7 `t52` 追加：装配口径修复 ＋ 硬闸 ＋ 两页真跑（**前沿已位移**）＋ 在册数同趟改准

> 读取时刻：**2026-09-28T09:5x+08:00**（各条另注）。本趟**不推送、不重冻**（归 `t46`）。

## 7.1 根因（在仓内，不在 `stage-app.sh`）
`build/MilBridge/tests/PtsPagesProbe/session_inner.sh:51` 原文
`cp -a "$SHIM" "$APPDIR/libwpfwin32.so"; cp -a "$PF" "$APPDIR/PresentationFramework.dll"`
其中 `$SHIM/$PF = $DLLS/$ARM.*`，而 `~/w67-work/dlls/A.*` 是 `~/w160a/stage-arms.sh` **2026-09-24 20:30** 落的快照
⇒ **A 臂的语义（"现权威五件"）与取件路径不符**：跑腿期间把 `sync-applocal.sh` 刚灌好的现件**就地覆盖回旧代**。
**选这条修法（而不是改 `stage-app.sh`）的理由**：覆盖动作发生在**仓内**、发生在 stager **之后** ⇒ 只修外层 stager 无用（旧快照仍会赢）。

**改法**：`session_inner.sh` 里 A 臂改取**仓内权威路径**（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`／`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`）；
B/C 反极性臂仍按 `$DLLS` 取（它们本来就该是别的件）；`PTS_GUARD_ARM_FROM_DLLS=1` 强制回旧行为（给硬闸造反极性腿用）。
`session_inner.sh` `1c1e…` → **`f687ad65fd05f6e2`**。

## 7.2 硬闸（跑腿器）＋ 两条极性腿
`run-pts-pages-legs.sh` 加：**前置闸**（`APPDIR/libwpfwin32.so|PresentationFramework.dll` ≠ authority ⇒ `device=NOINFO reason=app-stale-vs-authority`，**拒跑**）
＋ **跑后复核**（跑完再比一次，不等 ⇒ `device=NOINFO reason=app-swapped-during-run`，rc=2）。
**为什么 `--check drift=0` 不够**：它只看"**看门那一刻**"，看不见"跑到一半被换回"。`run-pts-pages-legs.sh` → **`1d95cd4d42f2646d`**。
- 极性腿①（装配陈旧：把 `dlls/A.libwpfwin32.so` 塞进 app 目录）⇒ `SYNC-APPLOCAL=DRIFT … drift=2 rc=3` ⇒ **`device=NOINFO reason=app-stale` ＋ rc=2（拒跑、出声）** ✔
- 极性腿②（**跑到一半换回**：`PTS_GUARD_ARM_FROM_DLLS=1`，app 目录先复原为 authority）⇒ **跑后复核咬住**（逐字）：
```
device=NOINFO reason=app-swapped-during-run post_shim=fc60c34d51fd9247 auth_shim=6825dd7071387a46 post_pf=cbd1884faeb4837e auth_pf=876f70dd7c0cbf7a
LEGS_RUNNER=NOINFO reason=app-swapped-during-run rc_session=0 outdir=~/w12a/pts-legs-POL5
RUN_POL5=2
```
  ⇒ **这正是旧仪器（`--check drift=0`）会静默放过的形**：看门那一刻是绿的、跑的是旧件 ⇒ 本趟把它变成**硬的拒绝** ✔
  （过程如实：前两次尝试死于我自己的引号/赋值错误、第三次（`RUN_POL4=2`）被"上一趟留下的陈旧 app 目录"在**前置闸**先挡住、具名行是 `reason=app-stale` 而**不是**本闸；**复原 app 目录后第四次（`RUN_POL5`）才真正取到本闸的成对读数**。）
- 正极（现件口径）⇒ 前置闸 `AUTHORITY: shim=6825dd7071387a46 pf=876f70dd7c0cbf7a ｜ APPDIR: 同` ⇒ 正常跑 ✔

## 7.3 🔴 两页真跑（**新件**）—— 前沿位移**已证**，页面**仍是可见降级**
`~/w12a/pts-legs-C/`（`heavy-slot` 内，`HEAVYSLOT=MEMOK`，槽内 31 s）：

| 页 | alive | app_rc | magenta | colors | ink | 具名行 |
|---|---|---|---|---|---|---|
| **24** `FlowDocumentDemo` 页签 | yes | 143 | **54826** | 851 | 423547 | `[PTS-UNAVAILABLE] … entry=`**`LoCreateContext`** `err=-10000` |
| **23** `RichTextBoxDemo` 页签 | yes | 143 | **50236** | 843 | 428205 | 同上（**同一条链**） |

`DEV x_up=yes five_stable=yes **shim=6825dd7071387a46 pf=876f70dd7c0cbf7a**` ⇒ **测的是当前 authority**（旧世界是 `54454／49864`）。**成对读数**：

| | before（09-24 旧件） | **after（本趟，新件）** |
|---|---|---|
| 具名前沿 `entry=` | `CreateInstalledObjectsInfo`（第 1 跳） | **`LoCreateContext`（第 6 跳）** ⇒ **前沿跳数 0 → 1** |
| 第 24 页 `magenta` | 54454 | **54826**（**仍 ≥ 20000**） |
| 第 23 页 `magenta` | 49864 | **50236**（**仍 ≥ 20000**） |

**三句限定（照 `t4` §8，一字不许省）**：① **前沿位移 ≠ 渲染** —— 两页**仍是洋红占位**，`entry=` 只是从"第一跳就失败"变成"进到 LS 构造期"；
② **`impl` 变小（97→95）≠ 进度**（本趟的进度度量是**前沿跳数**）；③ **第 23 页不在射程内**（表对象 5＋子页 12＋浮动/图形 2＋断字 6＋多列 2 ≈ 27 条额外）。
判据件现读：`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`（新证据已入 `evidence/`，旧证据备份在 `~/w12a/backup-evidence-before.t52/`）。

## 7.4 在册数**同趟**改准（`t12` 遗留的红已消）
`pts-gap-decl.txt` DECL 行 ⇒ `tool=100 dead=11 artifact=1 ops=88 **impl=95** **so16=6825dd7071387a46** **exports=556** w66pre16=bf6b683d94549087`；
**7 处复述位同趟改**（`实现口径 97→95` ×10、`97 实现口径→95` ×1）：`docs/ROUTES.md`（6）／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（1）／`README.md`（1）／`build/MilBridge/HANDOFF-NEXT.md`（1）／`src/WpfGfx.Linux.Native/src/win32_classification.c`（1）。
**现读：`PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556 root=$N`** ✔（`t12` 时是 `FAIL`）。

**覆盖面包位移（给 `t46`）**：`win32_pts.c`（在覆盖面内）＋`pts-gap-decl.txt`＋`close-wave.sh` 白名单件均改过 ⇒ `inputs_fp` **必移**。
`inputs_fp` **旧＝`37d4c6ab22f9606e…`（`#79` 冻后声明值，读取时刻 09-28T02:0x）** ⇒ **新＝见本报告末尾现取行**（读取时刻 **09-28T09:5x+08:00**）。
本趟改动面（相对 `t12` 收口时）：`session_inner.sh`／`run-pts-pages-legs.sh`／`evidence/{leg_23,leg_24,device.txt}`／`pts-gap-decl.txt`／5 处复述位文件；**`win32_pts.c`／`libwpfwin32.so`／`exports.txt`／`PtsCache.Linux.cs`／`reapply-patches.py`／`PresentationFramework.dll`／`pts-pages-guard.sh`／`shotstat.py`／`legs-to-env.py` 是 `t12` 落的那一批（本趟未再改）**。
⇒ **终值请 `t46` 在 `#80` 冻结时现取并冻进九位**（本趟**不冻不推**）。

## 7.5 边界与 `NOINFO`（逐条）
1. **闭包 `LD_DEBUG` 需求序列：本趟未跑** —— 需一次应用运行 ＋ `LD_DEBUG=symbols` 全量日志（`t4` 配方带 6 GB 预算闸），本趟预算已用于"装配修复＋两页真跑＋在册数"，**如实记 `NOINFO`**（不冒充）；前沿位移**不依赖**它（前沿由具名行直接给出）。
2. `N2-b′`（成功但 `*pInstalledObjects=NULL`）／`N2-c`（前沿伪装）／`N3`（一次做两跳 ⇒ 预期 `rc=134`）：**未跑**（属 `t12` 遗留，不在本件四件之内）。
3. `verify-all.sh` 的 `DECL` 口径句：**未改**（不在本件"只动"清单内 ⇒ 归 `t46`）。
4. `t12` 的单元级结果照抄（未重跑）：`SELFCHECK=1`（幂等）｜`Create rc=0 handle=0x5d72b1468b80 count=2 live=1 creates=2`｜`Destroy(真) rc=0 live=0`｜重复/未知名/NULL 释放全 `-10000`｜自检后 `live=0 creates=0`｜`pts-pages-guard.sh --selftest` **24/24 PASS**。
5. 本趟两处**自伤自纠**（如实入册）：`run-pts-pages-legs.sh` 的跑后复核首版有两处引号/赋值错误（`echo "POST_SHIM16="$(…)` 漏赋值、行尾多一个 `"`）⇒ 两次 `RUN_*` 以**解析错误**而非**闸**结束；已修（现读 `1d95cd4d42f2646d`）并复跑极性腿②得 `RUN_POL4=2`。

**`inputs_fp` 现取（读取时刻 2026-09-28T09:36:21+08:00）**：`c5c032d0bc75e19950ddb088bea7edd545b101e383ef475611e6aae4c64a4f0c`（`sha16 c5c032d0bc75e199`）；旧＝`37d4c6ab22f9606e…`（`#79` 冻后声明值）。

---

# §8 `t55`：关 `t13` 的 F-A–F-D（**原判词一字不改，一律 dated 追加**）

> 读取时刻：**2026-09-28T09:47:25+08:00**（各条另注）。本趟**不推送、不重冻**。`t13` 的报告 `build/MilBridge/VPts-verify-report.md` = `2e5dac82392ba9b7`，其判词 `needs_revision` **保留不改**。

## 8.1 F-A（🔴 blocker）——**本代证据已落进在册**（走"甲"）

**落仓动作**：把**同一趟**（run 戳 `2026-09-28 09:32:20–09:32:49`，车道 `~/w12a/pts-legs-C/`）的证据面**整目录逐件**落进 `build/MilBridge/tests/PtsPagesProbe/evidence/`（全部 `cp -p` 保 mtime ＋ `temp+rename`；旧代全套备份在 `~/w12a/backup-evidence-registered-0924/`）。

| 件 | 落/不落 | 理由 | sha16（落仓后） |
|---|---|---|---|
| `app_g1.log` | **落** | **承重件**：具名行 `entry=` 的载体 | **`eb6af2e16ba2bcfb`**（`3× entry=LoCreateContext`／`0× CreateInstalledObjectsInfo`） |
| `session.txt` | **落** | 该趟唯一的 run 戳与腿序 | `9488744993d13812` |
| `five_pre_g1.txt`／`five_post_g1.txt` | **落** | 五件稳定性成对读数（同趟） | `1fbedf891db7bf66`（两件同值） |
| `leg_24.env`／`leg_23.env` | **落** | 判据读的机读列 | `afb1081916bd0d0d`／`9fb8af8d6fdebb45` |
| `device.txt` | **落** | `X_UP=yes` 装置自证 | `6d2cf7572e7323b7` |
| `arm_A/{leg_24,leg_23,device}.env\|txt` | **落** | A 臂副本（`leg_*.env` 的 arm 目录形态） | `afb10819…`／`9fb8af8d…`／`6d2cf757…` |
| `device/{xvfb.log,xfwm.log}` | **落** | 显示装置日志（`xvfb.log` 0 B = 无告警） | `e3b0c442…`／`8ef9e0450181ec31` |
| `shots/g1/{boot,k24,k23,last}.png` | **落** | **真拍图**（`t13` 自算洋红就靠它） | `b21eb530afd3c66c`／`30fa8476edb8d69a`／`6c4e46b5024bf942`／`6c4e46b5024bf942` |

**判据现读**：① **在册 `app_g1.log` 现取 = `3× entry=LoCreateContext`**（旧代为 `3a3544fe9d6f8132`／`3× CreateInstalledObjectsInfo`）✔；② **两处载体逐字节同**：`cmp -s evidence/app_g1.log ~/w12a/pts-legs-C/app_g1.log` ⇒ **IDENTICAL**；`session.txt` 同 ⇒ **同一趟** ✔。
**`inputs_fp` 位移（同趟声明）**：**旧＝`37d4c6ab22f9606e…`（`#79` 冻后声明值）→ 新＝`5aa65b7d9d706d50d9440ff172d4069e768e5656805bfb104803d6cf2c2d2aeb`（读取时刻 2026-09-28T09:47:25+08:00）**；该目录**在覆盖面内**，本趟动了 18 件 ⇒ 位移归因 = `evidence/**` 整目录（＋`t52` 的 `pts-gap-decl.txt`）。**终值请 `t46` 在 `#80` 冻结时现取**。

## 8.2 F-B（high）——§7.3 声称的 **dated 更正** ＋ 同趟自洽性 ＋ 一条零证据力口径

**原句（§7.3，一字不改地留在这里再更正）**：「判据件现读：… （新证据已入 `evidence/`，旧证据备份在 `~/w12a/backup-evidence-before.t52/`）。」
**更正（dated 2026-09-28T09:47:25+08:00）**：该句在写下的那一刻（09:33）**只入了 3 件**（`leg_23.env`／`leg_24.env`／`device.txt`），**其余 15 件仍是 09-24 20:43 旧代** ⇒ 当时是**两代混装**，**不能**解释成同一趟。⇒ 已在 §8.1 **整目录换成同一趟**（现读全部 `2026-09-28 09:32:2x–09:32:49`）。
**同趟自洽性读数**（`ls -l --time-style=+%F_%T` 逐件，读取时刻 2026-09-28T09:47:25+08:00）：`app_g1.log 09:32:46`／`session.txt 09:32:48`／`five_pre_g1.txt 09:32:25`／`five_post_g1.txt 09:32:46`／`leg_24.env 09:32:49`／`leg_23.env 09:32:49`／`device.txt 09:32:49`／`arm_A/* 09:32:49`／`device/xvfb.log 09:32:20`／`device/xfwm.log 09:32:22`／`shots/g1/boot.png 09:32:33`／`k24.png 09:32:40`／`k23.png 09:32:44`／`last.png 09:32:45` ⇒ **全部落在同一个 29 秒窗口内**（run 戳 = `09:32:2x–09:32:49`）。
**⚠️ 零证据力口径（`t13` 的读数，逐字入册）**：门禁步 `PTS-PAGES`（`verify-all.sh:1173`，默认读本目录）**只读 `leg_*.env` 的列，不读 `entry=`** ⇒ **它的绿对"前沿位移"零证据力**。⇒ 本报告里凡引用 `PTS_GUARD=PASS`，一律**不得**被读成"前沿已位移"；前沿位移的**唯一**载体是 `app_g1.log` 的具名行（§8.1）。

## 8.3 F-C（medium）——**走"乙"：明确判出范围**（具名，不静默）

三个假绿探测器 **`N2-b'`／`N2-c`／`N3` 本波不实现**，逐条具名：
- **`NOINFO reason=detector-not-implemented`**（`N2-b'`：`CreateInstalledObjectsInfo` 改成"成功但 `*pInstalledObjects=NULL`" ⇒ 判据必须红）；
- **`NOINFO reason=detector-not-implemented`**（`N2-c`：只改报告/台账文本伪造前沿 ⇒ 判据必须红；**台账不是真值来源**）；
- **`NOINFO reason=detector-not-implemented`**（`N3`：一次做两跳 ⇒ **`rc=134` 仍未实测**；`~/w302-pts/report.md:229` 自认是"推算"——本趟**不改那个性质**，只把它从"未标"变成"在册 `NOINFO`"）。
**归属**：**归 `t12` 遗留项**（`t4` 设计 `criteria.md:151-154` 有定义、无实现）；**下一波候选（甲）**：在 `win32_pts.c` 加一个**只读门控**（如 `WPF_LINUX_PTS_STUB_MODE=1` 让 `CreateInstalledObjectsInfo` 走"成功但空"分支）＋ 一条 `pts-pages-guard.sh --selftest` 的合成腿断言"成功但空 ⇒ 必红"；`N2-c` 用"台账文本 vs `nm`/计数器交叉核"；`N3` 需要**两次应用运行**（一跳 vs 两跳）才能实测 `rc=134`。**在 `pts-gap-decl.txt` 旁已写同句**（见 §8.4 末）。

## 8.4 F-D（low）——注释口径与机读行对齐
`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`：改前 `eae178df2bd56e04` → **改后 `cb1888419575ff88`**；`:36` 的 `#` 注释 `impl=97` ⇒ **`impl=95`**（`temp+rename`；备份 `~/w12a/backup-pts-gap-decl.t55.txt`）。**牙现读仍 `PTSGAP=PASS … impl=95 so16=6825dd7071387a46 exports=556`**（读取时刻 2026-09-28T09:47:25+08:00）。
> 同件旁注（F-C 的 `NOINFO` 落点）：本件**只**承载"在册数"机读声明；`N2-b'`／`N2-c`／`N3` 的"未实现"**不写进本件的机读行**（会污染牙的射程），改写在本报告 §8.3 ＋ 下一波候选，避免"同一件两处口径"重现（这正是 F-D 的教训）。
