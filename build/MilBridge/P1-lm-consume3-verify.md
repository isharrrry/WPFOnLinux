# P1-W107 独立裁决（`verifier`／`t206`）—— `PtsHelper.cs:174-180` 的数组填写者之争

> **本件只覆盖 `t206`**（本席**未**按 `t199` 契约开工 ⇒ 无两件合并；若队长要把 `t199` 并入本载体，请给 `t199` 契约）。
>
> **裁决（一句）：分路径裁决 —— `t198` 的驳回在 `track-path` 上成立；`t195` 的 `W-1` 在 `track-path` 上被推翻、在 `subtrack-path` 上成立。** 故 **`PRECOND-PARADESC-SOURCE-MISSING` 应收窄为 `scope=subtrack-path(ContainerParaClient.cs:70→:72)`，不覆盖 `track-path(PtsHelper.cs:134→:137)`** ⇒ `t198` §8.3 的提议**成立**；`(甲)` **不回退**。
>
> **两造件与代际（本席现取，读时 `2026-09-29T23:05–23:09+0800`）**
> | 件 | 行数 | sha16 | 自证（本席复算） |
> |---|---|---|---|
> | `build/MilBridge/P1-lm-consume2-verify.md`（`t195` 侧） | **110** | `31dfda00ef739289` | `59095ac60f913ea5` **MATCH ✓** |
> | `build/MilBridge/P1-lm-consume3-report.md`（`t198` 侧） | **133** | `67da86e40e3e3ef1` | 末行**含两个** sha16，**当前值在前** ＝ `699184dd3eed173f` ＝本席复算值 **MATCH ✓**（后一个 `681cdbea6add7d72` 是它自陈的**上一条**自证值） |
> - 上游针 `upstream/wpf/…/PtsHost/PtsHelper.cs` ＝ **`f2ed9552e983fed1`**／963 行；`ContainerParaClient.cs` 现取（行号「仅本次有效」）
> - `win32_pts.c` 现取 **`57a80e0bb51d17ea`**／4529 行／`mtime 22:59:12`（＝`t198` 自陈收尾代 ✓）｜主链 `.so` 现取 **`9bb3df7f83fa5a77`**／`exports` **669** 行（§6：已移代，非 `t198` 之责）
> - **§A 自用**：行号一律整行取；引他人读数带代际／时刻并标"未独立复算"（§9）；未改任何人写的件、未 `git add/commit/push`。

---

## §1 判据① `:174-180` 所在函数与它的实参（逐行现取）

**函数＝`ArrangeParaList`**（`PtsHelper.cs:145-150` 现取）：
```
145:         internal static void ArrangeParaList(
146:             PtsContext ptsContext,
147:             PTS.FSRECT rcTrackContent,
148:             PTS.FSPARADESCRIPTION [] arrayParaDesc,
149:             uint fswdirTrack)
150:         {
```
⇒ `arrayParaDesc` 是**形参**；`:174-180` 读的就是**调用点给的那个数组**（`:174/:177` 读 `arrayParaDesc[index].dvrTopSpace/.dvrUsed`，`:179` 用 `arrayParaDesc[index].pfspara`）。

**它的调用点＝恰好两处**（`grep -rn 'ArrangeParaList('` 全托管树，排除定义，现取）：
| # | 调用点 | 实参（逐行） | 数组来源 |
|---|---|---|---|
| 1 | `PtsHelper.cs:137`（在 `ArrangeTrack`（`:117` 起）内） | `137:                     ArrangeParaList(ptsContext, trackDesc.fsrc, arrayParaDesc, fswdirTrack);` | `133: PTS.FSPARADESCRIPTION[] arrayParaDesc;` ＋ `134: ParaListFromTrack(ptsContext, trackDesc.pfstrack, ref trackDetails, out arrayParaDesc);` |
| 2 | `ContainerParaClient.cs:72` | `72:                 PtsHelper.ArrangeParaList(PtsContext, subtrackDetails.fsrc, arrayParaDesc, fswdirSubtrack);` | `69: PTS.FSPARADESCRIPTION [] arrayParaDesc;` ＋ `70: PtsHelper.ParaListFromSubtrack(PtsContext, _paraHandle, ref subtrackDetails, out arrayParaDesc);` |
⇒ **判**：`:174-180` **不属于"某一个数组"** —— 它按调用点服务**两个不同的数组**（track 路／subtrack 路）。`t195` 把它当"唯一数组"是本争端的根源。

## §2 判据② `:614` 与 `:633` 的函数／数组身份（逐行现取）

| 面 | `track` 路的填写者 | `subtrack` 路的填写者 |
|---|---|---|
| 定义函数 | `604:         internal static unsafe void ParaListFromTrack(` | `623:         internal static unsafe void ParaListFromSubtrack(` |
| 分配 | `610:             arrayParaDesc = new PTS.FSPARADESCRIPTION [trackDetails.cParas];` | `629:             arrayParaDesc = new PTS.FSPARADESCRIPTION [subtrackDetails.cParas];` |
| **native 入口** | `614:                 PTS.Validate(PTS.FsQueryTrackParaList(ptsContext.Context, track, trackDetails.cParas,` | `633:                 PTS.Validate(PTS.FsQuerySubtrackParaList(ptsContext.Context, subtrack, subtrackDetails.cParas,` |
| 托管声明／调用点（现取） | `Pts.cs:3696` 声明；唯一调用 `PtsHelper.cs:614` | `Pts.cs:3742` 声明；唯一调用 `PtsHelper.cs:633` |
| native 现取 | **已实现且已导出**：`win32_pts.c:3603 int FsQueryTrackParaList(…)`；`exports` 命中 **1**、`nm` **1** | **未实现**：全 native 树 **1 处注释**（`:3803` 系注释；另 `grep -c` 见 §3）；`exports` **0**、`nm` **0** |
⇒ **判**：`:614` 与 `:633` 属**两个不同函数、两个不同数组**（各自 `out` 参数各自分配）；**`:137` 传的是 `:614` 那一支**（`ParaListFromTrack` 的 out 参数）⇒ **`t198` §8.2 的分叉表逐行成立** ✓；`t195` 的"唯一填写者＝`:633`"**只对 `subtrack` 路成立**。

## §3 判据③ 运行期证据（本席自算，不许采信任一造）

**`[FSPARALIST-FILL]` 行的 `entry=` 值分布**（`grep -a '\[FSPARALIST-FILL\]' <腿> | grep -o 'entry=[A-Za-z]*' | sort | uniq -c`，现取）：
| 波 | 腿数 | 每腿 FILL 行 | `entry=` 取值分布 | 其他 entry |
|---|---|---|---|---|
| `t194` | 3（`wit1/wit2/nodvr`） | **2** | **2×`entry=FsQueryTrackParaList`** | 无 |
| `t198` | 10（`wit1/wit2/wit3/ctl3/ctlgen2/undecl/undecl3/dvrnod/dvrnod3/resize1`） | **2** | **2×`entry=FsQueryTrackParaList`** | 无 |
| 合计 | **13 腿** | 26 行 | **26/26 ＝ `FsQueryTrackParaList`**；`FsQuerySubtrackParaList` **0 行** | — |
**该入口是否只有托管这条路**：`FsQueryTrackParaList` 的**唯一托管调用点是 `PtsHelper.cs:614`**（§2 现取）；native 打印点 `win32_pts.c:3843` 位于**该入口实现体内**（`:3603` 起）⇒ **`entry=…reason=ok` 只可能由托管侧 `ParaListFromTrack` 的调用产生**。
**能否据此判"宿主这次真调了 track-path"** ⇒ **能**（就"填了 track-path 数组"这一事实）：每腿 2 次成功填充 ＝ 该入口被调 2 次；且随之宿主侧链路可见（§5 的 `desc_*` 读数）。
**旁证（本席现取，`t198/app-wit3.log` 首条）**：`[LMWIT-ARRIVAL] port=counting-entry fills=1 consumes=0 resolve_ok=0 gen=1 quota=1 gen_size_knob=1 declared=1 led_n=1 desc_dvr_used=16 desc_dvr_top_space=0 desc_dv=16 desc_src=LM1-SEGMENT-LEDGER arrival_ok=0 arith_descriptor_ok=1 …` ⇒ **描述符字段确被写入并回读**（`desc_src=LM1-SEGMENT-LEDGER`）。

## §4 判据④ 裁决（**分路径**，逐条点名）

| 主张 | 本席裁决 | 依据 |
|---|---|---|
| `t195`：「`:174-180` 读的数组的**唯一填写者**是 `:633 FsQuerySubtrackParaList`」 | 🔴 **不成立（over-broad）** | §2：`:174-180` 按调用点服务两个数组；`track` 路由 `:614` 填，`subtrack` 路由 `:633` 填 |
| `t195`：「该入口 native 未实现 ⇒ `:174-180` **不可达**、两操作数无源」 | 🔴 **对 `track-path` 不成立**；🟢 **对 `subtrack-path` 成立** | §2 表：`:614` 已实现＋已导出；`:633` 未实现（exports/nm 0）。§3：13 腿 26 行全为 `FsQueryTrackParaList reason=ok` ⇒ track 路**真被走** |
| `t198`：「该数组＝`:134 ParaListFromTrack` 的 out 参数、经 `:137` 传进 `ArrangeParaList`；唯一填写者＝`:614`」 | 🟢 **成立（限 track 路）** | §1 表#1、§2、§3 |
| `t198`：「`:633` 属另一函数 `:623 ParaListFromSubtrack`、另一数组（另一调用点 `ContainerParaClient.cs:70→:72`）」 | 🟢 **成立** | §1 表#2、§2 |
| `t198`：「前置应收窄为 `scope=subtrack-path`、`(甲)` 未回退」 | 🟢 **成立**（`(甲)` 的合法性见 §5，**附一条措辞低项**） | §5 |
**⇒ `t195` 的 `W-1` 被推翻（就有 track-path 的那部分）**：其"唯一填写者"与"`:174-180` 不可达"两句**必须按路径收窄**；因此 `t195` 载体与依其入册的 `t200` 三件里的 `PRECOND-PARADESC-SOURCE-MISSING` **都应加 `scope=subtrack-path`**（见 §10 `A-1`／`A-2`）。
**机器可判别分叉点（本席现取，供下一件一键复核）**：`nm -D --defined-only libwpfwin32.so | grep -c FsQueryTrackParaList` ＝ **1**（`FsQuerySubtrackParaList` ＝ **0**）＋`[FSPARALIST-FILL] entry=` 的取值只有 `FsQueryTrackParaList`。

## §5 判据⑤ 连带判 `(甲)` 的作者性 —— **合法**（附 1 条 low 措辞项＋1 条 NOINFO）

**逐字段作者性（本席现取整行）**：
- 值来源：`1596:     const int seg_h = 16;  /* 本侧段高（作者：本侧；由本侧页几何尺度定） */`、`1597:     const int top_sp = 0;`；
- 段账入册：`1605:     wpf_pts_lm1_led_add(seg_h, top_sp, fits);`（生产者 `1541: static void wpf_pts_lm1_led_add(int dvr_used, int dvr_top_space, int fits)`）；
- 描述符写点：`3782: #if WPF_PTS_FSP_PL_DVR` … `3777: memset((void *)&rg[i], 0, sizeof(rg[i]));` → `3788: rg[i].dvr_used = WPF_PTS_FSP_PL_DVR_NODVR ? 0 : le->dvr_used;`／`3789: … dvr_top_space = …` → 回读 `3790/:3791`。
⇒ **判**：① **不是"为凑 `dv>0` 填常数"**：写点**只读** `g_pts_lm1_led[]`（`:3787` 取 `le`），不在此处造值；② **段账不足即不写＋具名**：`3786: if (g_pts_lm1_led_n >= cParas) { … } else { if (i == 0) g_pts_lm1_led_short++; g_pts_lm1_led_ok = 0; g_pts_lmwit_desc_src = "NOINFO(lm1-ledger-short:led_n<cParas)"; }`（`:3796-3799`）⇒ **该句真落（代码面 ✓）**；③ 反腿射程正确：`DVR_NODVR` 只把**描述符这一对**打 0（`:3788-3789`），运行期 `app-dvrnod.log` 现取 `desc_dvr_used=0 desc_dv=0 desc_src=LM1-LEDGER(zeroed-by-DVR_NODVR-reverse-leg)` ✓。
- ⚠️ **low（措辞）**：`t198` 的"描述符字段**求真值**"（载体 §0.1／§1 标题／§2 表头；native `:121`／`:3783`）读起来像"内容/版式真值"，而**写入值恒为本侧模型常量 `seg_h=16`／`top_sp=0`（每段同一对值）** ⇒ 它**零判别力**（正落"恒真断言族"的"数值无判别力"形态）。`t198` 自己在 §1 末条与 §9.4 已写"`16` 是本侧建模段高，不是宿主算出的真实版式 ⇒ 只主张通路与操作数身份" ✓ ⇒ **实质诚实、只需改词**（见 §10 `A-3`）。

## §6 判据⑥ `#if` 隔离与主链（现取）

- **缺省 0 ✓**：`110: #ifndef WPF_PTS_FSP_PL_LMWIT` → `112: #define WPF_PTS_FSP_PL_LMWIT 0`；`120: #ifndef WPF_PTS_FSP_PL_DVR` → `124: #define WPF_PTS_FSP_PL_DVR 0`（另有 `_LMWIT_NODVR`／`_LMWIT_NOARR`／`_DVR_NODVR` 同样缺省 0）。
- **新只读导出确实被 `#if` 关住 ✓**：`1529: #if WPF_PTS_FSP_PL_DVR` … `1552-1554` 三段 `WpfLinuxWin32_PtsLm1LedN/Push/Short` … `1555: #endif` ⇒ 主链现取 `nm -D | grep -c PtsLm1Led` ＝ **0**、`exports` 命中 **0** ✓（`t198` §7:79 的声明成立）。
- **静默阈值确已删 ✓**：`:3659 #if WPF_PTS_FSP_PL_LMWIT` → `3660-3661` 注释「去掉静默阈值（`t196` §6 条款）—— 回收一到就打，且**必打**」＋ `3665 fprintf("[LMWIT] part=arrival …")` **在回收分支内无条件**（无 `>=2` 门）✓。
- ⚠️ **主链 `.so` 已移代（须记清，不属 `t198`）**：`t198` §7 报其**两次重建**均 `352855f8dfbf8dc7`／`MAIN_BYTE_IDENTICAL=yes`；本席现取 `.so` ＝ **`9bb3df7f83fa5a77`**（`mtime 23:07:38`），而 **`src/WpfGfx.Linux.Native/src/win32_x11.c` 现取为新 ` M`**、`t205` 车道 **23:07 活动** ⇒ **该次重建属在飞写者 `t205`**（非 `t198`）⇒ `t198` 的 pre/post 对**本席不可复核**（§9 `N-1`），但**无矛盾证据**；`exports` 现取 **669 行** ✓（与 `t198` 报同值）。

## §7 反腿（本席自造，一对）

**反腿①「把 `:174-180` 的数组当"唯一来源"」**：我构造的不是假想，而是**分叉表**（§1/§2）—— `ArrangeParaList` 两个调用点 × 两个 filler × 两个托管调用点，四格全有现取行号 ⇒ "唯一"在**类型上**就不可能成立（形参由调用点决定）。⇒ 本反腿**推翻了 `t195` 的表述**，同时**验证了 `t198` 的表述**。
**反腿②（P9／P10 自用）**：在裁 `t198` 成立之前，我先证明**我要求的那条读数真的在**：① `FsQueryTrackParaList` 的**唯一**托管调用点＝`PtsHelper.cs:614`（`grep -rn` 全托管树，仅声明 `Pts.cs:3696` 与调用 `:614`）；② 13 腿 × 2 ＝ 26 行 `[FSPARALIST-FILL]` 全为 `entry=FsQueryTrackParaList reason=ok`（不是拿 `t198` 的 12 行照抄）；③ 原生打印点在该入口实现体内（`:3603` 起）。

## §8 推翻的话

**我推翻了 `t195` 的 `W-1` 的 track-path 部分**（含我自己写的两句："唯一填写者＝`:633`"、"`:174-180` 今天不可达、两操作数无源"）——**它只在 `subtrack-path` 上成立**。⇒ `t195` 载体（`P1-lm-consume2-verify.md`）与依其入册的 `t200` 三件需要 **dated 收窄（加 `scope=subtrack-path`）**；**本件未动它们**（派单：只写自己的载体），见 §10 `A-1`／`A-2`。
**我未推翻**：`t198` 的数组身份判别（§2）、运行期判别（§3）、`(甲)` 的作者性链与"段账不足不写＋具名"（§5）、`#if` 隔离与"新导出不进主链"（§6）、其 §11 的两处自曝与 §12 的两条线索（如实记，未发现夸大）；亦未推翻 `t198` §9 的两条限制句（尤其 §9.3「回收被走到 ≠ `:174-180` 被走到」——与本席 `t195` `W-2` 同向，**它保留得对**）。

## §9 具名 `NOINFO`

- **`N-1`** `t198` 的"两次重建 `.so` 同值／`MAIN_BYTE_IDENTICAL=yes`"：其产物现已被 `t205` 的 23:07 重建覆盖 ⇒ **本席不可复核**（现取值 `9bb3df7f83fa5a77` 已记，且 ` M win32_x11.c` 解释了位移）。
- **`N-2`** `NOINFO(lm1-ledger-short:led_n<cParas)` 降级路径：**代码在 ✓**，但 `t198` 自陈"本次 12 腿均未触发"，本席现取亦未见该串 ⇒ **无运行期实例**（属代码面成立、读数面未验）。
- **`N-3`** `:174-180` **是否在本次运行里真被执行**：本席只证到"track-path 数组被填 ＋ `:137` 紧接着无条件调用 ＋ `:617` 的 `Assert(cParas==paraCount)` 在我方 `*cParaDesc=cParas` 下成立"这一**逻辑链**（与 `t198` §9.2 同口径）；**直读宿主局部**仍无载体 ⇒ `NOINFO`（这正是 `t195` `W-2` 的原始缺口，**未被本裁决填补**）。
- **`N-4`** `push` 面：未取远端状态（两造均自陈未 push；`git diff --cached` 本席未用于本件判词）。
- **`N-5`** 本件**未跑腿／未构建／未占显示位**（`/tmp/.X11-unix` 未重取）。

## §10 新发现的问题（点名 `文件:行` ＋ 机制；**本件不修**）

- **`A-1`（medium）｜`t195` 载体的 `W-1` 需 dated 收窄**：`build/MilBridge/P1-lm-consume2-verify.md:37`（"`arrayParaDesc[index].dvrUsed/.dvrTopSpace` 今天既无写入者、其宿主路径也不可达"）与 `:3`／`:94`（"唯一源 `PtsHelper.cs:633`…未实现"）**对 `track-path` 不成立**（§1/§2/§3 现取）。机制：该载体把**形参**当成**某个固定数组**；`ArrangeParaList` 的数组由**调用点**决定（两处：`PtsHelper.cs:137`／`ContainerParaClient.cs:72`）。`requiredFix`：在该件做 **dated 追加**（原文一字不删）：「`W-1` 的两句仅对 `subtrack-path` 成立；`track-path` 的填写者＝`:614 FsQueryTrackParaList`（已实现/已导出；13 腿 26 行 `entry=FsQueryTrackParaList reason=ok`）⇒ 前置收窄为 `scope=subtrack-path`」。（本件未改它：派单限"只写自己的载体"。）
- **`A-2`（medium）｜`t200` 三件里的新前置缺 `scope`**：`build/MilBridge/P1-host-consume-route-criteria.md:183`／`build/MilBridge/P1-lm-consume2-report.md:91`／`build/MilBridge/P1-lm-consume-witness-criteria.md:153` 同写 `PRECOND-PARADESC-SOURCE-MISSING`，**只写了射程＝`PtsHelper.cs:174-180` 那条计算**，未限路径 ⇒ 按字面会把 **track-path 一并免掉**（而 track 路今天有源）。`requiredFix`：三件各做 dated 收窄，把该前置改为 `scope=subtrack-path(ContainerParaClient.cs:70→:72)`，并注明 `track-path(PtsHelper.cs:134→:137)` **不在射程内**。
- **`A-3`（low）｜"求真值"措辞**：`build/MilBridge/P1-lm-consume3-report.md:8`（"描述符 `+36/+60` 有**真值**"）／`:15` 表头／`:24` 表头，以及 `src/WpfGfx.Linux.Native/src/win32_pts.c:121`／`:3783` 的"描述符字段**求真值**" ⇒ 写入值恒为**本侧模型常量** `seg_h=16`／`top_sp=0`（`:1596-1597`→`:1605`→`:3788-3789`），**零判别力**（"数值无判别力"形态）。`requiredFix`：改词为「描述符字段＝**本侧模型值**（常量 `seg_h=16`／`top_sp=0`；非版式真值）」；其余限制句（`:22`／`:113`）**已写对，保留**。
- **观察（不改判词）**：`t198` §4:56 的"具名缺省行"本席现取**成立** ✓（`t198/app-noarr3.log`：`fills=0 consumes=NOINFO(reason=lmwit-noarr-reverse-leg(不填列表 ⇒ 到达见证恒 0)) …`）——但该 token（`lmwit-noarr-reverse-leg`）与本席 `t201` `F-3` 记的另两个写法（`no-leg`／`no-arrival-leg`）**仍未统一**（建议下一件一并规范化）。

## §11 证据在册 ＋ 资源 ＋ 自证

- 本件唯一写入：`build/MilBridge/P1-lm-consume3-verify.md`（`temp → os.replace`；临时件落 `/tmp/p1-lm-consume3-verify.tmp`）。
- 只读来源（现取）：`PtsHelper.cs`（`:110-150`／`:600-640` 整行）、`ContainerParaClient.cs`（`:64-74`）、`Pts.cs`（`:3696`／`:3742`）、`win32_pts.c`（`:108-126`／`:1500-1556`／`:1588-1620`／`:3600-3610`／`:3650-3680`／`:3760-3800`／`:3843-3884` 整行）、`bin/{libwpfwin32.so,exports.txt}`（`nm`／`wc`）、`~/…/logs/{t194,t198}/app-*.log`（`grep`）、`ls -lt logs/`、两造载体（`sha256sum`／`wc`／自证复算）。
- **资源（§A #10）**：`MemAvailable` 三次现取 ＝ **15012344 kB**（`23:08:32`）／**15003848 kB**（`23:08:33`）／**15005388 kB**（`23:08:34`）；`MemTotal=28831496 kB`；`SwapFree=2096636 kB`；`df -h /home` ⇒ `/dev/sda2 187G 106G 72G 60% /`。本件为**纯只读裁决**：未起腿／未构建／未占显示位。
- **`P9`／`P10` 用在自己身上**：见 §7 反腿②（裁 `t198` 成立前先取"唯一托管调用点＋26 行 entry 值＋打印点归属"三件互不依赖的现取）；判 `A-1` 前先**逐行**核对 `:145-150` 形参、两个调用点的**每个实参**与 `:604-637` 两段定义，而不是只看一段。

**本件自证（落盘后）**：`head -n -1 build/MilBridge/P1-lm-consume3-verify.md | sha256sum | cut -c1-16` ＝ 818df822191c0c31（末行不计入自身；末行＝本行）
