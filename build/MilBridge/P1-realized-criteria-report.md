# P1-W42 · 把 `N1–N4` 落成可执行判据 ＋ 截图同趟自证要件 ＋ 新定靶口径 ＋ 相位翻转包（`t118`／`scribe`）

写者 `scribe`（`t118` attempt 1／`fd57b9b3-6181-49f6-a832-1b74d214fd88`）｜仓根 `/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`）｜读时 `2026-09-29T03:4x–04:0x+0800`
**一切读数现取自算**（`t117` 的侦察与队长裁定二十/二十一作**材料**，本件逐条重新现取）。本件**不做实现、不构建、不跑腿、不占显示位、不跑整趟门禁、不 `git add/commit/push`**；夹具无（本件只用现盘件与在册证据）。
**写域** ＝ 本载体（新建）＋ `P1-fontstack-fallback-criteria.md`／`P1-w8-step4-criteria.md`／`P1-w8-step4-verify.md`（dated 追加）＋ `docs/ROUTES.md §15af`（一行）。**未**动 `src/**`／生成件／`build/MilBridge/tools/**`（守卫）／`build/MilBridge/tests/PtsPagesProbe/**`（装置，`t116` 在动）／`verify-all.sh`／`close-wave.sh`／哨兵／`samples/**`。

## §0 一句话

`N1–N4` 已落成**可执行判据**（每条：objective／acceptance／**可跑 verify 单行**／取哪个字段／期望形状，并写明**取代/补充**了哪个既有要件）；截图类证据的**同趟自证**升为**通用要件**；**新定靶口径**（托管具名异常面）与三条代价入册并写明与已空的台账口径**不是同一个量**；**相位翻转包**整理成一次做完的清单 ＋ **重申硬前置**（`N1–N4` 同趟，否则翻转＝判据放松）。

## §1 `N1–N4`（可执行判据；本席现取读数见每条的"今天的值"）

### `N1` —— `ink>0` **没有区分力**；改为「**帧身份 ＋ 帧位移**」双要件

- **objective**：把 `realized` 期的「画出了内容」从**粗代理**升级为**有区分力**的读数。
- **现取（本席自算，四条帧）**：`shotstat.py` ⇒ `boot` `colors=386 ink=480000`｜`k23`＝`k24`＝`last` `colors=383 ink=480000` ⇒ **`ink=480000` 在四帧上完全同值** ⇒ 既有要件 `ink -gt 0`（守卫 `:378-391` 的 realized 支）**在今天的读数上恒真**，对「空态页 vs 真内容」**零区分力**（它是 `total − magenta − dominant` 的粗差，见 `t116` 的 `O-4` 口径）。
- **acceptance（逐字）**：① **帧身份**：该页帧的 `sha256`（前16）**∉ 登记的空态参照集**；② **帧位移**：`AE(boot, 该页帧) > 0` **且** 每次点击后的 `AE(上一帧, 该页帧) > 0`（除非命中 `N3` 的同貌例外）；③ **`ink>0` 降级为"必要不充分"**：保留但**不再单独**满足本条。
- **verify（单行）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; python3 build/MilBridge/tests/PtsPagesProbe/shotstat.py "$D"/shots/g1/{boot,k23,k24}.png; compare -metric AE "$D"/shots/g1/boot.png "$D"/shots/g1/k24.png null:
```
- **取哪个字段／期望形状**：`sha256`（前16）／`shotstat` 的 `colors,magenta,ink`／`AE` 整数。**期望**：帧 `sha256` ∉ 空态参照集（今天参照集 ＝ `{ef3fd6765f18f51b}`，即 `k23`＝`k24`＝`last` 那三帧；`boot` ＝ `b21eb530afd3c66c`）；`AE(boot,k24) > 0`（今天 **15386** ⇒ 该项**今天也满足**⇒ 说明它**单独不够**）。
- **取代/补充**：**取代** `ink>0` 作为"内容"要件（`ink` 降为辅助）；**补充** `N4` 的正身份（见下）。
- ⚠️ **边界（如实写）**：① 本条**只对"已登记的空态参照"有分辨力** —— 空态换版必须**同趟重登记**；② `AE` 是**像素位移**，不是"内容对不对"。

### `N2` —— **ENFE 必须留痕**（含按入口名过滤）

- **objective**：运行期出现 `EntryPointNotFoundException`（符号不存在）时，**账面必须看得见**，否则相位翻转会把"异常被吞"判成"排版成功"。
- **现取（本席自算）**：`grep -c 'Unable to find an entry point named' evidence/app_g1.log` ＝ **1081**；按入口名过滤 ⇒ **1080×`FsCreatePageBottomless` ＋ 1×`FsCreatePageFinite`**；`[HC-UNHANDLED]` 计数同 **1081**（每条 ENFE 一行）。守卫**一个字都不读它**（现取 `grep -c 'HC-UNHANDLED\|Unable to find an entry point' tools/pts-pages-guard.sh` ＝ 0）。
- **acceptance（逐字）**：① 证据里必须能现算 `ENFE_TOTAL=<n>` 与 `ENFE_BY_NAME=<名>:<n>,…`（**按入口名**，不按消息原文）；② **`ENFE_TOTAL>0` 时，判据面不得给出"排版成功"的绿** —— 除非**该批入口名**在判据里被**显式列入"本步非目标清单"**（allowlist 必须逐名可核）；③ **归因按入口名过滤**（同一条日志可能混入任何族的 ENFE；**不得**按计数或均值归因）。
- **verify（单行）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; grep -c 'Unable to find an entry point named' "$D"/app_g1.log; grep -o "entry point named '[A-Za-z0-9_]*'" "$D"/app_g1.log | sed "s/.*named '//;s/'$//" | LC_ALL=C sort | uniq -c | sort -rn
```
- **取哪个字段／期望形状**：`ENFE_TOTAL`（整数）＋ 按名直方图。**期望**：`ENFE_TOTAL` 与**非目标 allowlist** 的差集为 **0**（今天：**1081 ≠ 0** ⇒ 若此刻翻相位，本条**必红**）。
- **补充**：与 `O-1`（`form=unnamed` ≠ 具名前进）**互补**：那条管"托管具名面"，本条管"**异常面**"。

### `N3` —— 两页帧相同 ⇒ **对照腿**判据

- **objective**：判开 `leg23-AE=0` 的两种语义 ——（i）**两页本来就同貌** /（ii）**第 23 页根本没重绘**。
- **现取（本席自算）**：`k23.png`＝`k24.png`＝`last.png`（`sha256` 前16 ＝ **`ef3fd6765f18f51b`**，各 189716 B）；`AE(k23,k24)` ＝ **0**；`AE(boot,k23)` ＝ **15386**；`leg_23.env` 的 `ae=0`、`leg_24.env` 的 `ae=15386`。
- **acceptance（逐字）**：**对照腿**（同一趟、`clicks=[23,24]`；现取装置支持 `clicks=[…]` 列表）必须给出：① 两条腿各自的**帧 `sha256`**；② **两帧必须不同**（`sha256` 不等）；**若相同** ⇒ 必须给出「**两页内容确实同貌**」的证据（两页 `ns=` 指向**同一 UI 且该 UI 无页别差异**）⇒ 否则判**（ii）没重绘**（**红**）。③ 每次点击后的 `AE(上一帧, 本帧) > 0`，同上例外。
- **verify（单行）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=<对照腿目录>; sha256sum "$D"/shots/g1/k23.png "$D"/shots/g1/k24.png | awk '{print $1}' | LC_ALL=C sort -u | wc -l; compare -metric AE "$D"/shots/g1/k23.png "$D"/shots/g1/k24.png null:; grep -E '^LEG k=2[34]' "$D"/leg_2[34].env
```
- **取哪个字段／期望形状**：帧 `sha256` 去重计数（**期望 2**）／`AE`（**期望 >0**）／两条 `LEG` 行的 `ae`。**今天**：去重计数 ＝ **1**、`AE=0` ⇒ 本条**今天红**（这正是"两页真排版"不成立的证据面）。
- **补充**：把 `AE=0` 从**诊断**（守卫现取 `diags+=leg$k-AE=0(点击前后无像素差)`，`:395`）升为**本条下的判据项**（红/例外二选一）。

### `N4` —— **内容身份**（`ns=` 不承担它）

- **objective**：证明"画面是该页**自己的内容**"，而不是应用的空态页。
- **现取（本席自算）**：三帧 `sha256` 同值且等于 demo 的**「敬请期待」空态页**（`~/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Main/UnderConstruction.xaml:16` 的 `LangKeys.ComingSoon` 那一格）；`grep -ci 'neptune' evidence/app_g1.log` ＝ **0**；而 `leg_24.env` 的 `ns=HandyControlDemo.UserControl.FlowDocumentDemo` ⇒ **`ns=` 与"空态画面"同时成立**（`t110` 那趟的反例）⇒ **`ns=` 只证"加载了那个类型"**。
- **acceptance（逐字）**：① **负身份**（今天可达）＝ `N1①` 的帧身份（∉ 空态参照集）；② **正身份**（今天**无载体**）＝ 必须给出**该页专属**的期望指纹（例如登记一次已知良好渲染的帧 `sha256`，或该页专属的结构读数如 `TabControl` 的 tab 数）；③ **`ns=` 不得单独**承担内容身份；④ 在没有 ② 之前，本条记 **`NOINFO(无正身份载体)`**，**不得折绿**。
- **verify（单行）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; grep -E '^LEG k=24' "$D"/leg_24.env; grep -ci 'neptune' "$D"/app_g1.log
```
- **取哪个字段／期望形状**：帧 `sha256`／`LEG … ns=`／内容 token 命中数。**期望**：帧 `sha256` ＝ **登记的期望指纹**（今天**无此登记** ⇒ `NOINFO`）；`ns=` 只作**辅助**。
- **补充/取代**：`N4` **取代**「`ns=` 正确 ⇒ 内容正确」的隐含读法（`t117` 已把该反例记在册）。

## §2 截图类证据的**同趟自证**（通用要件；含实例）

- **要件（逐字）**：**凡以截图为承重件**，必须同时给出 **①** 截图的 `sha256`（前16）；**②** 该截图与所引读数**同趟**的证明（照 `C7` 的做法：引**同趟字段** —— `DEV` 行的 `shim=`／`pf=` 与 `session.txt` 的 `ts`／或该趟 `POSTSHIM`）；**③** 该截图的 `shotstat` **现读**与 `leg_*.env` 的 `colors`／`magenta`／`ink` **逐格相等**。**缺任一 ⇒ 截图只作辅助件，不得单独承重**。
- **verify（单行）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; python3 build/MilBridge/tests/PtsPagesProbe/shotstat.py "$D"/shots/g1/k24.png; grep -E '^LEG k=24' "$D"/leg_24.env; grep -E '^DEV ' "$D"/leg_24.env
```
- **实例（`t117` 登记的那处不一致，本席如实转记并标来源）**：`02:48` 那趟自己的 `session.txt`／`leg_24.env` 写 `colors=1 magenta=0 ink=0`；而**仓库内** `k24.png` 现取（本席 03:5x 复量）＝ **383 色**、且与 03:14 那趟**逐字节相同** ⇒ 那趟的截图**与其 env 不同趟**（或 env 是另一趟的）⇒ **该截图只作辅助**。本席现取的三者**一致**（`shotstat` 383 ＝ `leg_24.env colors=383` ＝ `session.txt` 的帧行 383）⇒ **今天的在册截图满足本条** ✓。

## §3 新定靶口径（入册；与"台账口径"**不是同一个量**）

- **口径句（逐字，采用 `t117` §1.2 并补边界）**：
  - **域名面**：**托管具名异常面** `^\[HC-UNHANDLED\] #<n> EntryPointNotFoundException: Unable to find an entry point named '<入口名>' in shared library '<dll>'`；**域名册** ＝ 上游 `upstream/wpf/…/PresentationFramework/MS/Internal/PtsHost/Pts.cs` 的 `DllImport` 声明名（现取 `Pts.cs` 的 `DllImport` 行 **73** 条）。
  - **下一跳** ＝ 该面按**入口名**计数后的**最高频未处理名**（**现取：`FsCreatePageBottomless` 1080 次**，其后 `FsCreatePageFinite` **1** 次）。
  - **与台账口径的关系（逐字）**：台账口径（`^PTS_GAP entry=`，按 `seq=` 排序）**今天为空**（现取 0 行）且**结构性失明** —— 名册 `k_pts_entries[]` 13 名里**一个 `Fs*` 都没有**、`Fs*` **一个都没导出** ⇒ 异常在 **CLR** 里抛、**native 一行都进不去**；⇒ **两口径不是同一个量**：**引用读数必须标注取的是哪一个**（台账口径给"已导出但未实现"的站；具名异常面给"符号不存在"的站）。
- **三条代价（逐字，必须随引用一起写）**：① 该面**只给"名字 ＋ 次数"**，给不出 native 侧状态（`g_pts_calls`／`g_pts_seen`／`live` 面全无）；② 该面的**发射方是第三方应用**（其钩子）⇒ **不在本仓写域**（不能改它、只能读它）；③ 它**会混入任何 ENFE**（别的族/别的 shim 名）⇒ **归因必须按入口名过滤**（与 `N2③` 同款）。

## §4 相位翻转包（**一次做完**的执行清单；供后人执行）

**硬前置（重申，逐字）**：**`N1–N4` 与本清单同趟落定**；否则「直接翻相位 ⇒ 守卫 `PASS`」＝**判据放松**（把"没排版"判成"排版了"）。现取反证（本席复核 `t117` 的算法）：把今天两腿读数喂给 `realized` 支 ⇒ `magenta=0` **✔** ∧ 无具名行 **✔** ∧ `ink>0`（**480000**）**✔** ∧ `native_gap=0` **✔** ⇒ **会 PASS**，而 `ENFE_TOTAL=1081`、两页帧**逐字节相同**、画面是空态页。

**A. 要改的位（逐条现取原文，本席复核）**

| # | 位点（现取） | 翻转要做什么 |
|---|---|---|
| `F1` | 守卫件头**唯一机读声明行**：`# PTS-DIRECTION: absent="magenta=0" present-floor=20000 red-when="…" source=TASK-0741 phase=degraded` | `phase=degraded` → **`phase=realized`**；**同趟**把该行文字里 `absent=` 那句从"缺席语义"改写成"应然语义"（否则件头自相矛盾） |
| `F2` | 解析＋校验：`PHASE="$(… sed -n 's/.*phase=\([a-z]*\).*/\1/p')"`；非法 ⇒ `PTS_DIRECTION=FAIL reason=phase-missing-or-invalid` | **不动**（这是"取不到就响亮失败"的牙） |
| `F3` | 腿级两支（现取 `:378-391`）：`realized` ⇒ `magenta -eq 0` ∧ 无具名行 ∧ `ink>0`；`degraded` ⇒ `magenta ≥ 20000` ∧ `err=-10000` | 翻到 `realized` 支后 **必须同时**按 `N1` 换掉 `ink>0` 单要件 |
| `F4` | 台账要件（现取 `:405-410`）：`realized` ⇒ `ngap_total -eq 0`；`degraded` ⇒ `ngap_total -ge 1` | 翻后须补 `N2`（否则"ENFE 吞掉"也绿） |
| `F5` | 自检里的 realized 副本生成点（现取 `:555`）：`sed 's/^\(# PTS-DIRECTION: .*\)phase=degraded$/\1phase=realized/' "$0" > "$_rz"` | **不动**（两极化装置）；但 `c15–c19` 的期望值须随 `N1–N4` **同趟**更新 |
| `F5b` | **本席新增点名**：另一条极性副本（现取 `:582`）：`sed 's/…phase=degraded/\1phase=/' "$0" > "$_pf"`（造"相位非法"） | **不动**；但**翻转后**它仍必须红（`phase=` 空 ⇒ `phase-missing-or-invalid`）⇒ 列入翻转后回归 |
| `F6` | 诊断带（现取 `:393-395`）：`colors` 带 `800..1200` ⇒ `colors-out-of-band`；`ae=0` ⇒ `AE=0(点击前后无像素差)` | 随相位重划（`colors` 带今天 `383` ⇒ **在带内**；`ae=0` 在 `N3` 下升级为判据项） |
| `F7` | 复核位（**另一族**）：`PTS_G10_NAME=PASS form=unnamed` | **不受相位影响**（名字归属判据）⇒ **不动**；但与 `N4` **口径不同，禁止混** |

**B. `degraded` 正控 `c1–c10` 的相位相关性（现取：自检共 **24** 条 `chk`）**

| 例 | 相位相关性 | 翻转时要做的事 |
|---|---|---|
| `c1`（全好 54454/49864） | **相位相关** | 翻转后 `magenta=54454≠0` ⇒ **期望反向（FAIL）** |
| `c2`（rc=134/alive=no） | 无关 | 不动（两期都红） |
| `c3`（alive 但洋红 0） | **相位相关** | 翻转后 `magenta=0` 正是绿条件 ⇒ **期望反向（PASS）** |
| `c4`（洋红 19999 < 门槛） | **相位相关** | `MAGENTA_FLOOR` 只在 `degraded` 支用 ⇒ 期望改 |
| `c5`（洋红 =20000 边界） | **相位相关** | 同上 |
| `c6`（`ns=BrushDemo` 点错对象） | 无关 | 不动（NOINFO） |
| `c7`（无具名行） | **相位相关** | `realized` 期"无具名行"是**绿** ⇒ **期望反向** |
| `c8`（`native err=0`） | **相位相关** | 依赖具名行要件 ⇒ 期望改 |
| `c9`（`x_up=no`） | 无关 | 不动（NOINFO，装置自证） |
| `c10`（空证据目录） | 无关 | 不动（NOINFO） |

**C. `realized` 侧既有 5 例（现取 `c15–c19`）**：`rz c15 PASS "realized·真实形态"`／`c16 NOINFO "realized·缺 ink ⇒ NOINFO"`／`c17 FAIL "realized·占位仍在 ⇒ FAIL"`／`c18 FAIL "realized·具名行仍在 ⇒ FAIL"`（`c19` 同族）⇒ 翻转包**必须**把 `c1/c3/c4/c5/c7/c8` 的期望按 `realized` 支重写，并**新增 `c2x` 例**覆盖 `N1–N4`（每题**正极必绿 ＋ 反腿必红并点名**成对）。
**D. 六类会变语义的既有读数（逐条点名）**：`magenta`（`≥20000` 绿 ⇒ `=0` 绿）｜`NAMED … err=`（必须 `-10000` ⇒ 必须 `-`／空）｜`native_gap`（`≥1` ⇒ `=0`）｜`ink`（不被读 ⇒ 被读，且按 `N1` **不再是单要件**）｜`PTS-DIRECTION` 行文字（`absent=` 语义⇒应然语义，**必须同趟重写**）｜`direction=in-file`／`phase=degraded` 的**判词尾串**（所有"逐字相同"型对拍都要同趟跟）。

## §5 不变量 / 指纹 / 牙（现取）

```
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ｜ `62 gen=#81` ＝ 1 ｜ `--expect 234` ＝ 1 ⇒ 四条未变
覆盖面成员（本席现算）：本件四类件（carrier／三件 criteria,verify／ROUTES）**各 0** ⇒ **无 `cell=#1` 登记义务**（本件未改覆盖面内件）
指纹：fp 现取（见交付回执的 `ts`）—— 本件只作"读数时刻"记录，**未追写**
牙：REPORTID／DEFREG／HANDOFF_MV／SENTINEL-SPEC／QUOTE-TRAP／PIPEFAIL-SIGPIPE／STATIC-JAWS 读数见交付回执（本件不改任何被牙扫描的件，除 `docs/ROUTES.md`（不在覆盖面内））
```

## §6 未做项 / `NOINFO` ＋ 边界自证

- **`NOINFO①`（`N4` 的正身份）**：**今天无载体**（没有"该页专属期望指纹"的登记）⇒ 判据写成"必须有正身份读数"，但**该读数需另派单**（登记一次已知良好渲染的帧/结构读数）。
- **`NOINFO②`（`N2` 的守卫接线）**：`N2` 的**执行**落在守卫（`build/MilBridge/tools/**`）——**不在本件写域** ⇒ 本件只落**判据与 verify 单行**；接线（让守卫读 `ENFE_TOTAL`）**另派单**。
- **`NOINFO③`（`N3` 的对照腿真跑）**：对照腿（`clicks=[23,24]`）**本件不跑腿** ⇒ 判据给出 verify 单行与期望形状，**未**得对照腿的真实读数。
- **`NOINFO④`（空态参照集的维护）**：`N1` 只对"已登记的空态参照"有分辨力；**谁在什么时候重登记**未定（列为翻转包的前置维护项）。
- **边界自证**：`git status --porcelain` 里属于**本席**的改动只有上面那 4 类件；`src/**`／`build/PresentationCore.Linux/**`／`build/WindowsBase.Linux/**`／`build/MilBridge/tools/**`／`build/MilBridge/tests/PtsPagesProbe/**`／`verify-all.sh`／`close-wave.sh`／哨兵／`samples/**` **零碰**；未构建／未跑腿／未占显示位／未跑整趟门禁／未 `git add|commit|push`；**无夹具**（未新增临时件）。
- **第 `29` 条**：改动面 4 类件（1 新建 ＋ 3 dated 追加 ＋ ROUTES 一行）≡ 备份面（写前 `stat -c %h` ＝ 1 ＋ `cp -p` 逐件）。
- **第 `30` 条**：本件引用的读数**全是批式件读数**（`shotstat`／`compare`／`grep -c`／`sha256sum`）或**引用他人登记并标明来源**（`t117` 的 `02:48` 实例）⇒ 不含"进程内状态敏感仪器"引用。
## §7 落盘后补记（同趟；只增不改）—— 牙读数与指纹（**载体自带读数**，不再只指回执）

```
REPORTID=PASS files=252 ids=2202 declared=224（本载体计入 ⇒ 251→252）
DEFREG=PASS declared=224 route_ids=224 ｜ ⚠️ DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD（**他者面**：KD 的声明锚与 route 面位移 ⇒ 须持 --emit 权限者同趟刷新）
SENTINEL-SPEC rc=0 ⇒ SSC=PASS（13 个 key 全 PASS；与队长记的"哨兵不缺位"一致）
SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203 ｜ PIPEFAIL_SIGPIPE=PASS undeclared_hit=0
HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 ｜ STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62（**0 HIT**）
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ｜ `62 gen=#81` ＝ 1 ｜ `--expect 234` ＝ 1 ⇒ 四条未变
覆盖面成员（现算）：本件四类件（realized-criteria-report／fontstack-fallback-criteria／P1-w8-step4-criteria,verify／ROUTES.md）**各 0** ⇒ **无 `cell=#1` 登记义务**
指纹：fp 现取 b1624c7bad84d073d301b65fd9b876e2a7b91c6b03bce982de6d6bddbe087302（ts=2026-09-29T03:30:54.476642283+0800）
      ⇒ **与 `HANDOFF-NEXT.md` 末条登记值同值**（本件未改覆盖面内件 ⇒ 位移非本件所致）；按纪律**未追写**。
件面（现取）：P1-realized-criteria-report.md 本载体（自报 fbe1898dea9aa6e1→见末行）｜P1-fontstack-fallback-criteria.md 449→**488 行**（自报 862166d879740fe0）｜P1-w8-step4-criteria.md 450→**459 行**（自报 b81ade4b7b809f2c）｜P1-w8-step4-verify.md 190→**197 行**（自报 597e1a901ee39c12）｜docs/ROUTES.md 910→**920 行**
```
**本件自证（落盘后）**：`head -n -1 build/MilBridge/P1-realized-criteria-report.md | sha256sum | cut -c1-16` ＝ e5879a1c0863490e（末行不计入自身；上一行 fbe1898dea9aa6e1 系**补记前**全文值，原样保留）
---

## ⏪ `t122` dated 追加 —— `N2` **守卫接线**（收紧）＋ `N4` 正身份**三选一**（取（甲））＋ **空态参照集重登记与归属建议**（读时 `2026-09-29T04:1x–04:3x+0800`；上方原文**一字未删**，本段**只加行**）

### `N2` 守卫接线（**方向＝收紧**；落点 `build/MilBridge/tools/pts-pages-guard.sh`）
- **接线内容（逐字）**：`judge_legs` 在台账要件之后新增 **ENFE 面**：
  - **口径**：`ENFE_TOTAL` ＝ `<证据目录>/app_g1.log` 里 **`entry point named '<名>'`** 的**行数**（**来源＝应用日志**；与 `[HC-UNHANDLED]` 行**同源** —— 现取二者计数相等，均 **1152**）；`ENFE_BY_NAME` ＝ 按**入口名**直方图。
  - **allowlist**：`PTS_ENFE_ALLOWLIST`（**逗号分隔入口名**，**默认空** ⇒ 一个都不许）；判词行打印 `allow=` 与 `non_allow=`，红行**点名每一个** non_allow 名。
  - **判据**：**`realized` 期**，`ENFE_TOTAL>0` ∧ `non_allow` 非空 ⇒ **红并点名**（名＋计数）＋ `reason=enfe-present-after-phase-realized`；**`degraded` 期**只印 `PTS_ENFE=INFO …`（**不据此判红** —— 止损期的绿语义是"占位还在"）；**日志取不到** ⇒ `PTS_ENFE=NOINFO` ＋ `cannot+=`（**绝不当绿**）。
  - **只增不减**：未改任何既有要件、未改三态语义（`PASS`/`FAIL`/`NOINFO`）、未动阈值。
- **成对读数（真证据副本，仓外；`ts≈04:1x`）**：
```
(degraded) 修前：PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000)
(degraded) 修后：PTS_GUARD=FAIL legs=2/2 fails=（**同上三条，逐字相同**） ＋ 新增一行 PTS_ENFE=INFO（degraded 期不据此判红）
(realized 副本) (a) 有 ENFE：PTS_ENFE=FAIL total=1152 by_name=FsCreatePageBottomless:1151,FsCreatePageFinite:1, non_allow=FsCreatePageBottomless,FsCreatePageFinite
                PTS_GUARD=FAIL fails=enfe-unhandled(total=1152,non_allow=…)（**红并点名**）
(realized 副本) (b) 同一夹具**只剥掉** log 里的 ENFE 行：PTS_ENFE=PASS total=0 ⇒ PTS_GUARD=PASS fails=-
                ⇒ **两腿唯一的差别就是那批 ENFE 行** ⇒ 这条规则**确实**是 verdict 翻转的唯一原因（收紧有效、且不误红）
(realized 副本) (c) allowlist ＝ 这两个名：PTS_ENFE=PASS total=1152 allow=FsCreatePageBottomless,FsCreatePageFinite non_allow=none ⇒ PTS_GUARD=PASS（**逐名可核**）
(realized 副本) (d) 删掉 app 日志：PTS_ENFE=NOINFO reason=enfe-log-absent(…) ⇒ PTS_GUARD=NOINFO cannot=enfe-log-absent（**绝不当绿**）
```
- **自测（同趟）**：`pts-pages-guard.sh --selftest` ⇒ 从 `PASS pass=40 fail=0` ⇒ **`PASS pass=46 fail=0`**（新增 6 条断言：`c32` realized·ENFE>0 必红 ＋ 点名(名+计数)／`c33` allowlist 全列 ⇒ 不红 ＋ 逐名可核／`c34` degraded ⇒ 只印 INFO／`c35` 日志缺 ⇒ NOINFO）。
- **相位翻转的硬前置（据此收紧为可执行）**：现在**可以**写成可判式 —— **`ENFE_TOTAL=0`（或全部在 allowlist 里）** 才允许翻 `phase=realized`；否则翻完第一个 `realized` 判词就是 `FAIL enfe-unhandled(…)`。**今天 `ENFE_TOTAL=1152` ∧ allowlist 为空 ⇒ 翻转即红**（这正是"不许为换绿而放宽"的可执行形态）。

### `N4` 正身份：**取（甲）** —— 登记为「**待补**」，并写明补的条件与责任人
- **理由（本席现取）**：**今天没有任何"已知良好渲染"的样本** —— 两页帧 `sha256` **逐字节相同**（`k23`＝`k24`＝`last`＝`1a76488aa4a790b3`）、渲染循环每次布局都抛 `FsCreatePageBottomless`、日志里 `neptune` 命中 **0** ⇒ **正身份读数今天不可得**。
- **为什么不取（乙）**：今天**做不到**"该页专属的结构面读数"—— 要它就得先有"页面内可枚举的结构量"（`TabControl` 的 tab 数、`Figure/Floater/Table` 计数一类），而那需要**UI 侧仪器**（本仓今天没有；且两页帧相同 ⇒ 连"两页有各自结构"这件事都还没发生）⇒ 若把它写成判据，就是一条**今天不可判**的格（本仓禁"永不可能绿"的格）。**取其"未来候选"身份**：等真绘出后用**结构面**做正身份（比帧指纹更稳、对像素抖动不敏感）——记为**候选方案（乙′）**，不落判据。
- **为什么不单取（丙）**：`t118` 已经把该格定为 `NOINFO(无正身份载体)`、不许折绿 ⇒ 本件**保留**该纪律，但**不**止于"留个问号"：按（甲）**登记待补 ＋ 写明补的条件与责任人**。
- **补的条件与责任人（逐字）**：
  - **条件**：`FsCreatePageBottomless`（及其后 `FsCreatePageFinite`）**真落地**、两页**首次各自绘出内容**之后（可判标志：`ENFE_TOTAL=0` **且** `k23.png` 与 `k24.png` 的 `sha256` **不相等**）。
  - **责任人（建议）**：**当趟实现件的写者**（即让 `FsCreatePageBottomless` 落地的那位）**同趟**登记该页专属期望指纹（帧 `sha256` 或（乙′）的结构面读数），**落点**＝本件（`P1-realized-criteria-report.md`）的 dated 段；**复核方**（独立复核者）在下一件里独立复算该指纹是否可复现。
  - **代价（如实记）**：在条件满足前，`N4` 的**正身份**一直 `NOINFO` ⇒ **相位翻转的"内容身份"要件不完整**（负身份由 `N1①` 承担；今天两页帧相同 ⇒ 连负身份也指着**同一个回退画面**）⇒ **`N4` 未闭是相位翻转的未闭项**（与 `N2` 的可执行前置并列）。

### ⏪ `t145` dated 追加 —— `N4` 正身份：**四条被 `t142` 判死／受限的读数** ＋ 新立前置 `PRECOND-KNOWN-GOOD-FRAME`（只增不改）

- **口径四条（写死；均带本席 `t145` 现取或逐处标注引自哪一件）**：
  - **① `ink` 四帧恒 `480000` ⇒ 禁用**：本席 `t145` 独立复算现盘四帧（`evidence/shots/g1/{boot,k23,k24,last}.png`）**全 ＝ 480000**（`dominant` 恒为黑 `830720`）⇒ `ink` 是**恒真量**、**零区分力** ⇒ **不得**当身份、**不得**设阈值、**不得**与 `magenta`／`colors` 并列称同等可复算。
  - **② 行带数四帧全 `1` ⇒ 判死**：本席 `t145` 独立复算（＝"非底色像素的连续行带数"）四帧**全 ＝ 1** ⇒ 四帧同值 ⇒ **零区分力、判死**。
  - **③ `[GEO]` 面不得当内容身份**：现取 `[GEO]` **927** 行；内容侧结构名现取 `nm=DocumentPage` ＝ **0**、`nm=ContentControl` ＝ **0**、`nm=Run` ＝ **0**。⚠️ **如实更正一处（本席复现不全）**：`t142` 写「内容侧元素**一个都没有**」，但本席现取 `nm=TextBlock`／`nm=FlowDocument`／`nm=ScrollViewer` **各 16**（**非 0**）⇒ 该句按**上列三名 0 命中**读，且那 16 次命中**不足以**当"该页内容画出来"的证据。⇒ 要**结构化**读数须**新仪器**：**`PRECOND-CONTENT-TREE-DUMP`**（托管侧内容树转储）／**`PRECOND-CONTENT-DRAW-COUNTER`**（"该页绘了几行／几个 glyph"计数器）。
  - **④ OCR 今天关门**：`tesseract`／`ffmpeg`／`magick`／`gocr` 本席 `command -v` 现取 **四个全 ABSENT** ⇒ 「帧里有没有那几个字」今天**不可判**（`NOINFO`）；替代路径 ＝ **色锚（`C-A`）**或**托管侧计数器**（`PRECOND-CONTENT-DRAW-COUNTER`）。
- **新立前置 `PRECOND-KNOWN-GOOD-FRAME`（写死）**：现取**全仓 `1280×1024` 的 PNG 只有 8 枚**，且**全是同一批 4 帧的两份拷贝**（在册证据 ＋ 其副本）⇒ **今天不存在任何"已知良好帧"**（正向参照**不存在**是**实测结论**，不是推断）⇒ `N4` 正身份的"**正向参照**"这条路**今天不可走**。
- **⚠️ 与之配套的写死句（`C-C` 的判据侧镜像）**：**不许把「第一次恰好出现的帧」登记为「已知良好」** —— 任何"正身份登记"都必须带**独立可证伪支撑**（指纹对拍之外的第二条读数，且由判据方**自己现算**）；只登记、无支撑 ⇒ 判 **`N4-DECLARED-ONLY`**、**不给绿**。〔实现与成对读数见 `build/MilBridge/P1-n4-gate-report.md`；守卫侧落点 ＝ `pts-pages-guard.sh` 的 `n4` 源 ＋ 色锚面〕

### 空态参照集：**重登记**（本趟换版）＋ **归属建议**
- **本席现取（`ts≈04:1x`）**：`shots/g1/k23.png` ＝ `k24.png` ＝ `last.png` ＝ **`1a76488aa4a790b3`**（各 189716 B）；`shots/g1/boot.png` ＝ **`b21eb530afd3c66c`**（190413 B）。
- **重登记（逐字）**：**空态参照集（`N1①` 用）＝ `{1a76488aa4a790b3}`**（＝"回退画面"当前版；来源＝`build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{k23,k24,last}.png`；取值时刻＝`2026-09-29T04:1x+0800`）；**`boot.png` 不入参照集**（它是启动帧，不是"回退画面"）。
  **旧值作废**：`{ef3fd6765f18f51b}`（`t118` 登记的那一版）⇒ **已失效**（画面换版）⇒ 保留原句、以本段为准（只增不改）。
- **归属建议（建议＋理由；不要只留问号）**：
  - **建议归属**：**守卫的写者**（`build/MilBridge/tools/**` 属主）**为该参照集的唯一登记人**；**触发条件 ＝ 任一变化即须同趟重登记**：① 相位翻转包执行时（**必查**）；② `evidence/shots/g1/{k23,k24,last}.png` 三帧 `sha256` 与登记值**不等**时（装置重跑换代亦算）。
  - **理由**：① 该集合的**唯一消费者是守卫**（`N1` 接线落在守卫里）⇒ 消费方持有登记值，读到"对不上"时能**当场红/请求重登记**，不必跨件追；② 相位翻转包本身也由守卫写者执行 ⇒ 触发点①与执行人重合；③ 装置侧（runner）只负责**把三帧 `sha256` 打出来**（今天腿 env **没有**帧 sha 格 ⇒ **装置侧缺口，另派单**），避免"登记人还要自己去找图"。
  - **可跑检测（交给任何发现者；单行）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k23.png "$D"/shots/g1/k24.png "$D"/shots/g1/last.png | awk '{print substr($1,1,16)}' | LC_ALL=C sort -u; echo "登记值=1a76488aa4a790b3（不等 ⇒ 触发重登记）"
```
**本件自证（`t122` dated 追加后）**：`head -n -1 build/MilBridge/P1-realized-criteria-report.md | sha256sum | cut -c1-16` ＝ 51c160413a32545c（末行不计入自身；上一行 e5879a1c0863490e 系**追加前**全文值，原样保留）

- ⏪ **dated 追加（`t124`／scribe，`2026-09-29T11:4x+0800`；只增不改）—— `N1` 双要件**落成守卫要件**（`realized` 期判、`degraded` 期只 `INFO`）＋ 装置侧帧 sha 格补齐**
  - **装置侧取值格（本趟闭 `t122` 点名的装置侧缺口）**：`build/MilBridge/tests/PtsPagesProbe/session_inner.sh` 新增 `FRAME` 行（落在 `CLICK` 与 `PHASE` 之间，**既有行一字未动**）、`legs-to-env.py` 带成 `leg_<k>.env` 的**第五段**（前四段字段一个不动）；口径（`fr_sha`＝`k<k>.png` 的 `sha256sum` 前 16 位／`fr_lsha`＝同刻 `last.png` 前 16 位／`fr_ae_boot`＝`compare -metric AE boot.png k<k>.png`）与 `-` 语义（没测到，不是 0）见 `build/MilBridge/P1-frame-identity-report.md` §1。**只加行**：老格式 session ⇒ 四格 `-`；**老产者 env vs 新产者 env ⇒ 每腿只差 1 行**（`4a5`）。
  - **守卫接线**：件头**唯一登记处** `FRAME_EMPTY_SET` ＝ **`{1a76488aa4a790b3}`**（`t122` 重登记值**原样写死**；旧 `ef3fd6765f18f51b` 作废；**不设 env 旋钮**）；`realized` 期 `fr_sha` ∉ 集合 ∧ `fr_ae_boot>0` **任一不满足 ⇒ 红并点名**（哪一帧／哪个要件／实测值／参照集）；`degraded` 期只印 `PTS_N1=INFO`；`FRAME` 行缺／值不可解析 ⇒ `PTS_N1=NOINFO` ＋ `cannot`（**绝不当绿**）。既有要件／三态／阈值**一字未动**；自测 **`PASS pass=55 fail=0`**（`t122` 后 46 ⇒ `t124` +9 条断言）。
  - **成对读数（本席现算；夹具仓外、用完删）**：(a) 帧 ∈ 集 ⇒ `FAIL` 且点名 `criterion=frame-identity(sha16=1a76488aa4a790b3∈{1a76488aa4a790b3})`；(b) **只**改 `fr_sha` 为 ∉ 集的值（每腿只差 1 行）⇒ `PASS` ⇒ **该规则是 verdict 单独翻转的原因**；**修前对同一 (a) 夹具 ⇒ `PASS` 且 `PTS_N1` 行 0 行**；(c) `fr_ae_boot=0` ⇒ `FAIL` 且点名 `criterion=frame-displacement(ae_boot=0)`；(d) 删 `FRAME` 行 ⇒ `NOINFO`；(e) **`degraded` 期判词修前/修后逐字相同**（`PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded`），修后**多** `PTS_N1=INFO` 两行。⇒ 相位翻转包 `F3` 的「**翻后必须按 `N1` 换掉 `ink>0` 单要件**」这一条**今天已在守卫里可判**；翻转包的其余位（`F1`／`F4`／`F5`／`F6` 与 `c1–c19` 期望）**仍未执行**。
  - **`N1` 仍未闭的一格（如实记）**：登记集**只含"回退画面"那一枚**；在册证据目录**现势** `k24.png`＝`last.png`＝`2a60a00fc582e97d`（311 B、`colors=1 magenta=0 ink=0` ＝**整屏单色空拍**）**不在集内**、且 `AE(boot,k24)=480000>0` ⇒ `N1①②` **都不红它**；**兜住它的是既有 `ink>0`**（`realized` 期 `ink=0` ⇒ 必红）。是否把"整屏单色空拍"并入空态参照集（**收紧**）⇒ **建议守卫写者在收口时裁定**（本件**未**擅自扩集）。
  - **旧格式腿的判词变化（有意的收紧）**：无 `FRAME` 行的腿在 `degraded` 期会多出 `cannot=leg2x(n1-frame-cell-missing=fr_sha,fr_ae_boot)` ⇒ **干净夹具由 `PASS` 变 `NOINFO`**；在册证据目录那条**颜色不变**（`FAIL` 由既有 `fails=` 决定）、只在 `cannot=` 加两格。
  - **载体**：`build/MilBridge/P1-frame-identity-report.md`（本席新建）＋ `docs/ROUTES.md` §15af 与 `build/MilBridge/HANDOFF-NEXT.md` 的**同日 dated 追写**。
**本件自证（`t124` dated 追加后）**：`head -n -1 build/MilBridge/P1-realized-criteria-report.md | sha256sum | cut -c1-16` ＝ a2c7dcd97544fa01（末行不计入自身；上一行 `51c160413a32545c` 系**追加前**全文值，原样保留）
### ⏪ dated 追加（`t136`／scribe，读时 `2026-09-29T14:2x–14:3x+0800`；只增不改）—— `N1` 降「必要非充分」／累积登记＋作废纪律／`N3` 例外支写死／读数绑定与契约口径更正

- **①`N1` 要件①降「必要非充分」（`t120` `F-3`）**：`realized` 期「`fr_sha` ∉ `FRAME_EMPTY_SET`」**只是必要条件**；**「∉ 参照集」不得单独作为排版绿的依据** —— 它的绿必须**同时**附**正证据**且**点名是哪一种**：(a) `N4` 正身份登记（env `PTS_N4_POSITIVE_FP="<k23 sha16>,<k24 sha16>"`；**未登记** ⇒ `NOINFO`、**不得给绿**）；(b) **内容锚**（`PTS_CONTENT_ANCHOR_RE` 默认 `[Nn]eptune` 在 `<dir>/app_g1.log` 命中 **>0**）；(c) **`AE(k23,k24)>0`**（`compare` 实测优先；两图不在时用两腿 `fr_sha` 不等，判词 `via=` 点名）。**今天三源一个都不在场**（现取：两腿 `fr_sha=ef3fd6765f18f51b` 同值、`neptune` 命中 `0`、`N4` 无登记载体）⇒ `realized` 期新闸**必红并点名** `PTS_N1_GATE=FAIL … reason=only-necessary-condition-no-positive-evidence`。守卫侧判词随之改：旧 `PTS_N1=PASS`（必要件齐即绿）⇒ 现 `PTS_N1=NECESSARY`（**不再单独发绿**），绿由循环后的**正证据闸**裁定。
- **②空态参照集＝累积登记 ＋ 作废纪律（`F-3`）**：`FRAME_EMPTY_SET` 由 `{1a76488aa4a790b3}`（单成员）⇒ **`{1a76488aa4a790b3,ef3fd6765f18f51b}`** —— 两枚都是**已发生**的空态回退指纹（后者出处 ＝ 在册 `build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{k23,k24,last}.png` 三帧同值；`t119` 那趟 `00:52` 代照进在册证据；本席现取两腿 `FRAME` 行与三帧 `sha256` 前 16 位逐位相同、各 `189716` B）。**作废纪律（写死、并进守卫件头）**：**把一枚帧身份从登记集里"作废／移出"这个动作本身是危险的 —— 只有拿到 `N4` 正身份或内容锚正证据才准移出；只凭"换了一版画面"不得移出**。⇒ `t124` 段那句"旧登记 `ef3fd6765f18f51b` 作废"**按本段收回**（原文一字未删，以本段为准）。**收紧证据**：实况帧恰是被"作废"的那一枚 ⇒ `realized` 副本现取**两腿均红**：`criterion=frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b})`（**假绿形态被就地堵死**）。
- **③`N3` 例外支条件（写死；`F-1`）**：**例外仅当两页「内容定义」相同**（＝`PTS_N3_SAME_CONTENT_PROOF` **非空**的正证据声明）**且两页都确已绘出内容**（两腿 `ink>0`）；**「两页都没绘出内容」不构成例外 ⇒ 必红**。例外成立只**免红**（`PTS_N1_GATE=EXCEPTION`），**不冒充**排版正身份。⇒ `t119` 载体当年用它免掉 `N1②` 的红，**按本条不成立**（该例两页**都没有绘出内容**）—— 细节见 `build/MilBridge/P1-realized-probe-report.md` 的同日 dated 追记。
- **④读数绑定与契约口径更正**：
  - **`F-2`（`ENFE_TOTAL` 必须绑「日志 ＋ `sha16`」）**：守卫每条 `PTS_ENFE=` 行**新增 `log=`／`log_sha16=`**（现取真腿：`log=build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log`、`log_sha16=84db0eb62d15e0b2`、`total=0`）。**`t119` 载体引的 `ENFE_TOTAL=1152` 记具名 `NOINFO`**：其原始载体由 `t119` 车道持有（`~/t119-runner/bak/**`），**本席取不到**；可核者只有 `t120` 现取三处 —— 对照腿原始日志 `run-N3-app_g1.log` ＝ **1121**、`evidence.pre-t119` ＝ **1121**、可扫提交面 `057d08a` ＝ **1081**（本席另于 `t134` 现取工作树现值日志 ＝ **1085**，`2026-09-29T13:16:56`）⇒ **不留一个无载体的 `1152` 当读数**。
  - **`O-1`（`N2` 契约口径 dated 更正）**：本件 `:153` 那句「`ENFE_TOTAL` … 与 `[HC-UNHANDLED]` 行**同源** —— 现取二者计数相等」**今天已解耦** ⇒ 两个量**各自**定义、**不得互相折算**：`ENFE_TOTAL` ＝ 日志里 `entry point named '<名>'` 的行数（**缺符号面**；现取 **0**）；`[HC-UNHANDLED]` ＝ 同名标记的行数（**托管未处理异常面**，内容现取为 **`PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'`** 族；现取 **1123**）。（原句一字未删，以本行为准。）
  - **`O-2`（相位必须写明）**：**凡引用 `N1` 的结论必须写明相位** —— `degraded` 期只印 `PTS_N1=INFO`、**不进 `rc`**；只有 `realized` 期进 `rc`。守卫侧每条 `PTS_N1*` 行现取都带 `phase=`。
  - **`F-4`（契约件标识成对重取）**：`t119` 载体写契约 ＝ 本件 **`55d6f050ecbe4c7d`／146 行**；本席现取（本趟追加前）＝ **`fcb20f641bdbbf3b`／200 行**；追加后全文值见本件末行自证（**成对读数**）。
- **守卫侧成对读数**：`--selftest` **改前 `PASS pass=55 fail=0`** ⇒ 收紧后**原样复跑**得 **`pass=50 fail=5`**（5 条**旧期望随收紧而该红**：`c15`／`c16`／`c33`／`c37` 的期望值 ＋ `c36` 的参照集断言串）⇒ **把这 5 处期望按收紧方向改严**（`PASS→FAIL` ×3、`NOINFO→FAIL` ×1、断言串改为**累积集**）＋ **新增 11 条断言**（`c40` 累积集新成员必红／`c41` 只有必要件必红／`c42` 例外支成立正极／`c43` 同夹具去声明因果对／`c44` 内容锚正证据／`c45` `N4` 登记正证据）⇒ **终态 `PASS pass=66 fail=0`**。**无一处放宽**（逐条方向见载体 `build/MilBridge/P1-guard-n1-n3-tighten-report.md`）。`degraded` 期真树判词**修前/修后逐字相同** ✓（`PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=degraded`）。
- **载体**：`build/MilBridge/P1-guard-n1-n3-tighten-report.md`（本席新建）。

**本件自证（`t136` dated 追加后）**：`head -n -1 build/MilBridge/P1-realized-criteria-report.md | sha256sum | cut -c1-16` ＝ 5cac8981307b0ff9（末行不计入自身；上方两条自证行原文一字未删，以本行为准）
