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
