# 根 `README.md` 重写前的 dated 更正段（**原文另存**）

[English](README.md) | [中文](README.zh-CN.md) | [Español](README.es.md)

> 本文属于 **docs.Linux/evidence** —— 回 [证据索引](README.zh-CN.md)（[English](README.md) · [Español](README.es.md)）· [移植侧文档总线](../README.zh-CN.md)。

> ⚠️ **本区为历史证据，勿据此判现状。** 现状一律以 [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md)（机器行 `:9` = 冻结基线）与 [`docs/ROUTES.md`](../../docs/ROUTES.md) 为准。
>
> **为什么有这一件**：阶段 1（文档面）把仓根 `README.md` 改写成 ason 式**门面**（它是什么 / 现在能做什么 / 三条命令 / 去哪看）。
> 门面里那**两大段逐波追加的 dated 更正**（`T-A33`…`T-B19` 与 `T-A47`…`T-B24`）**原文另存在这里** ——
> **不许丢原文**（它们是"这条移植怎么被验证出来的"唯一书面链）。门面里只留一行链接指过来。

## §0 出处与读数（可复算）

- **来源**：`README.md`（阶段 1 重写**之前**的根门面），工作副本备份 `/tmp/README-original.md`。
- **重写前读到的原读数（逐字）**：

```text
254 行 / 32,707 B
sha256 = 4a06b1e1a32d271cc98a3dd2ac73060511435bfe3c7c879d2c39eddb3604ebc1
```

```bash
# 当前（重写后）根 README 与本文 §2 的差 = 本次改写本身；取回重写前的原文：
git -C ~/netTest/GitProj/WPFOnLinux show fc995cd8:README.md | sha256sum
# 期望：4a06b1e1a32d271cc98a3dd2ac73060511435bfe3c7c879d2c39eddb3604ebc1
```

- **§1 收录范围**：重写前根 `README.md` 的 `28–36` 行（§0 现状表下的 dated 块）与 `236–254` 行（文末 `dated 收口` 起至文件末），**逐字**。
- **§2 收录范围**：重写前根 `README.md` **全文**（254 行），**逐字** —— 连同 §1 一起，保证"原文一个字节都不丢"。

---
## §1 dated 更正段（原文逐字；重写前根 `README.md` 的 28–36 行 ＋ 236–254 行）

<!-- 以下为逐字摘录，不改一字（含空行）。-->

> ⏪ **本表上一版是 2026-09-24 的 4 行（①必死 `rc=134`／②`TASK-0302`／③读数须重取／④只差一条腿）**，其逐条更正见下方 `T-A75` dated 行；更早的 8 行版（2026-09-20）已删，全文可从 git 历史逐字取回（`git -C ~/netTest/GitProj/WPFOnLinux log --oneline -- README.md`）。逐条细节见 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 与 `docs/ROUTES.md`。
>
> ⏪ **dated 更正（`T-A33`，读时 `2026-09-30`；只增不改，上面两行**原文保留**）**：① 行「必死 `rc=134`／洋红占位」**已不成立** —— `T-A33` 落地 **native 查询期文本行回填**（`FsQueryTextDetails`／三入口按**行记录台账**真填出参）后，切「富文本」23／「流文档」24 **不再崩**（`alive=yes app_rc=143 failfast=0`），且**占位图消失、内容区首次出现真实像素**（改前/反极性：占位 `129792` px、`AE(content)=0`；改后：占位 **0** px、`AE(content)=203949`／`174476`）。② 行「PTS／LineServices 真实现」**仍**是长线（`TASK-0302`；`可操作 70／实现口径 73` **未变**）。⚠️ 免读宽：`PTS` 本体仍是**降级实现**，新前沿见 `docs/ROUTES.md` §15x 的 `T-A33` 行与载体 `build/MilBridge/P1-tail2-backfill-impl-report.md`。
> ⏪ **dated 更正（`T-A36`，读时 `2026-09-30`；只增不改，上面各行**原文保留**）**：`T-A36` 落地 **native「PTS 附属对象回填」**（`Figure`/`Floater` 建台账 ＋ 查询期回填 `cAttachedObjects`，并新增 `FsQueryAttachedObjectList`／`FsQuerySubpageDetails`／`FsQueryFigureObjectDetails`／`FsQueryFloaterDetails` **四导出**）后，`k=24` 帧上**首现具名色块**（`PTS_COLORANCHOR` `hits 0→1`；**`GhostWhite 0→29637 px`**），`colors 654→724`，帧 `fa7df9222ebb199f → 1487caf78fd88886`；症状门**无回归**（`[HC-UNHANDLED]=1`）。⚠️ **免读宽**：**四具名色仍只出 1 个**（`Beige`/`DarkGreen`/`LightGoldenrodYellow` 在 `Figure`/`Floater` 的**内容**里，需"附属对象内容排版"驱动 ⇒ 下一增量）；`PTS` 本体仍是**降级实现**。现值位随动：`可操作 66／实现口径 69`（`.so=21ad5f39ef3c4034`／`exports=681`）。载体 `build/MilBridge/P1-tail2-attach-impl-report.md`。

> ⏪ **dated 更正（`T-A41`，读时 `2026-09-30T18:5x+0800`；只增不改，上面各行**原文保留**）**：`T-A41` 同趟落两件 —— ① **native 只读判别器 `D0`**（`[FSQVP]`）：把「页轨枚举经由哪条支（arrange／visual／viewport）」按**紧邻事件＋页查询状态**判开（**推断**，行尾具名 `NOINFO=viewport-branch-callsite`，**不是**直读）；② **托管侧视口驱动**（`FlowDocumentView.Linux.cs`，由 `reapply-patches.py` 生成；`WPF_FSVIEW_VIEWPORT_DRIVE=0` 可整点撤掉）＋ 只读台账 `[FSVIEW]`。**成对读数（现取，6 腿）**：`via=viewport` **78–171 次（≠0）**⇒ `A40` 的断点判定（「视口支整条未发生」）**被证伪**（该支一直在跑）；判别器三标签分布 `arrange≈visual≈viewport≈每轮 1 条`、**自洽性反例 ZERO**。🔴 **本页上驱动成空转**：`[FSVIEW]` 现取 `handed == viewport`（`638.4x366.72` DIP）、页盒仅 `39.81x39.17` DIP、`visbounds=empty`（本移植 `VisualTreeHelper.GetDescendantBounds` 取不到）⇒ **帧面逐字节不变**（`k24=1487caf78fd88886`／`colors=724`／`GhostWhite=29637 px`、余 3 色仍 `0`）⇒ **判据 ② 未达**（`PTS_COLORANCHOR=FAIL hits=1`）。症状门**无回归**（`alive=yes app_rc=143 failfast=0 magenta=0 [HC-UNHANDLED]=1`）。现值位随动：`.so 606dad49ae7b34a1 → dd9865c38e18ed81`；`exports=683` 不变；`PTSGAP=PASS`（`tool=76 dead=11 artifact=1 ops=64 impl=67`，与 `win32_classification.c:52` 的「可操作 64／实现口径 67」**逐数相符**）；`nm==exports`；`DEFREG`／`REPORTID` rc=0。载体 `build/MilBridge/P1-tail2-fsview-impl-report.md`。

> ⏪ **dated 更正（`T-B1..T-B19` hc demo 修复链，读时 `2026-10-03`；只增不改，上面各行**原文保留**）**：hc demo（HandyControl 示例）**已知缺陷表全部已修** —— ① **「流文档」视图文字重叠**（`T-B3`／`T-B4`／`T-B15`：行盒取"段在页中的原点" ＋ 浮动绕排 ⇒ 重叠量 `58.8% → 0`、`touch_fig_rows 17→0`／`touch_flo_rows 6→0`）；② **「流文档单页视图」（tab2）空白**（`T-B12`：分页页视觉换父接回 ⇒ `colors 551→841` ＋ 具名色）；③ **「流文档查看器」（tab3）空白**（`T-B16`／`T-B17`／`T-B18`／`T-B19`：PresentationUI 主题字典补齐 ＋ `E_HANDLE` 具名／`PRECOND-WIC-RTB` 解除 ＋ 修体挪到渲染遍历入口 ⇒ 文档区 `148→731`、具名色 `0/0/0/0 → 9449/842/16/5861`）；④ **关窗 `rc=134`**（`T-B14`：`APP_RC 134→0`）。⇒ `~/run-hc.sh` 的「**⛔ 暂时别点：左侧「富文本」「流文档」…**」警告**已撤**（该警告的旧前提 `EntryPointNotFoundException`／不可捕获 `FailFast` 已全部不再成立）。⚠️ **免读宽**：本表 ①②③④ 四行**仍是 2026-10-02 的读数**（`T-A33..A59` 链），本行只作 **hc demo 面** 的 dated 更正；`TASK-0302`（PTS 真实现）仍**长线**。载体：`build/MilBridge/P1-hcbookkeep-report.md`。


---

## ⏪ **dated 收口（2026-09-28 · 车道 `t14`；上文一字未动）**

- **账一**：上文 §7 的 `upstream/wpf/` 行已逐字点名「**根目录那份不使用**」**被证伪**（两条独立机制：根 `Directory.Build.props` 被 MSBuild 自动导入 ⇒ `error MSB4236`；其 **92 个 csproj** 进 build-hygiene 候选集；现取读数见该行）。⚠️ **该事实的"入册"（`KNOWN-DEFECTS.md` 新号）尚未落** —— 逐字状态＝**待配号**（本趟不动 route 件；登记批由 `t57`／队长安排）。
- ⏪ **dated 更正（`t66`，读时 `2026-09-28T13:17+08:00`；上文「尚未落／待配号」原文保留）**：**该事实的入册已经落** —— 现取 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:3666` 有 **`### 🆕 D-G180`**（「fork 根级上游件会改变整棵树的求值结果」）；声明表现取有 **`ID	D-G180	req=KD`**；`DEFREG=PASS declared=`**`215`**（**已含 `D-G180`**；读时同上）⇒ **不再是"待配号"**。
- 🔴 **九位权威产物是「本地物件」**：`src/WpfGfx.Linux.Native/bin/` 被 `.gitignore`（`:22-26`）忽略 ⇒ `git ls-files src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **0**、`…/exports.txt` ＝ **0**（现取）⇒ **干净克隆取不回、必须重建**。凡本文档任何"产物已在库/已在远端"的暗示都是**假绿方向** —— `R8` 判据① 正是「**干净 clone ＋ 按 README 从零构建**」。
- **导出面三种口径（现取，读时 `2026-09-28T12:26+08:00`）**：在册口径（`wc -l < src/WpfGfx.Linux.Native/bin/exports.txt`）＝ **556**｜`nm -D --defined-only` ＝ **556**｜`nm -D` 全量 ＝ **648** ⇒ 引用必须写明口径。
- **交接面**：九位产物不进 git ⇒ 交接必须靠**构建**或 `~/w-keep-shims/`（HANDOFF-NEXT 的未结账项里已写）。

⏪ **dated 落地（`T-A47`／`TASK-0302` 增量；读时 `2026-09-30T20:2x+0800`；只增不改）**：**消掉"相位翻最后一阻"＝缺省路径残留的 1 条 `[HC-UNHANDLED]`**。①（托管，走生成器 `P8`）生成件 `PtsHelper.Linux.cs` 的 `UpdateFloatingElementVisuals` **补浮层视觉的换父**（照上游自己的 `UpdateParaListVisuals` 同形先例）；②（native）`src/WpfGfx.Linux.Native/src/win32_pts.c` 的 `drive-handles-released(page-destroyed)` **两处**拒因**收窄**为"下一次填充必然要发 `+176 CreateParaclient` 时才拒"。**成对（同 `.so 1dbea9026dd7d3d7`／同装置 `:231`／只差 env）**：缺省 **`[HC-UNHANDLED]=0`**｜`WPF_FLOAT_REPARENT=0` ⇒ **1**（`ArgumentException`）｜`WPF_PTS_QTP_LIVE_NARROW=0` ⇒ **1**（`PtsException … '-10000'`）。**零回归**：`PTS_COLORANCHOR=PASS k=24 hits=2`（`Beige=910`／`DarkGreen=44`）、`k24 fr_sha=791696291d51470b` 未变；`nm==exports==683`；`PTSGAP`／`DEFREG`／`REPORTID` 各 `rc=0`。⚠️ 拒因收窄后**分页器走完整个文档**（`[QPD] page=` 去重 **280** 页 vs 改前 ~7）—— 如实记，**帧面逐字节未变**。载体：`build/MilBridge/P1-tail2-hcres-impl-report.md`。

⏪ **dated 收尾对齐（`T-A49`／`T-A50`／`T-A51`，读时 `2026-09-30T23:59+0800`；只增不改）**：① `T-A49`（E5 重取臂 · 五臂换代）：世代绑定项 `instr_shim 921ba9c65e9fb3be → e2fa9ec9be1a6cf1` ⇒ 五臂重取，`TLINE_GATE=PASS tree_gen=same drift=0 gone=0 unregistered=0`；五臂红/绿结论与在册逐字相同（`known-red.json 29219b6f071c6361 → dcc22fd3c80cfcac`）；同趟 `repo-alias-allow.tsv` 补声明臂日志输出树 ⇒ `ALIAS=PASS`。② `T-A50`（重冻结冻结块 5 行 `# ARM-LOG-SHA`）：`COLUMN_FLOOR=FAIL → PASS`；基线件 `b27ff6332f263495 → bd64f2c1a3eaaa05`（**世代仍 `#80`**）。③ `T-A51`（收尾）：**现取六闸逐条 `rc=0`**（`SSC`／`HANDOFF_MV`／`DEFREG=PASS declared=225`／`REPORTID`／`COLUMN_FLOOR`／`ARMLOG_SHA`）；整波旁生件 `git checkout HEAD --` 归位（旁生件归 0）；`declared.tsv` 重发 225 条。载体：`build/MilBridge/P1-tail2-closeout-report.md`。

⏪ **dated 现值位随动（`T-A52`／`T-A53`／`T-A54`，读时 `2026-10-01T08:0x+0800`；只增不改，上两段原文保留）**：三连落地后**第 4 具名色 `LightGoldenrodYellow` 缺省落位** —— `T-A52`（`GetFloaterHandlerInfo` 真实现 ＋ Floater 内容排版驱动；缺省关，零回归）⇒ 真阻挡前移 ＝ `Floater` 内 `<Table>` 撞未导出 `FsQueryTableObjDetails`；`T-A53`（**Table 族五入口导出**，`exports 683→688`）⇒ 开闸腿 `LightGoldenrodYellow=1998 px`；`T-A54`（两闸转**缺省开**）⇒ **缺省腿** `LightGoldenrodYellow = 1998 px`、`PTS_COLORANCHOR=PASS k=24 hits=3`、缺省零回归（三帧与 `T-A53` 开闸腿逐字节同）。**现值位（现取）**：`可操作 59／实现口径 60`；`.so 642019f680d75d87`／`exports 688`（`PTSGAP=PASS tool=71 dead=11 artifact=1 ops=59 impl=60 so16=642019f680d75d87 exports=688`）。⚠️ **免读宽**：第 4 色所在层 ＝ **`TableRow Background`（表行背景）**，只让行背景落像素；`FsQueryTableObjRowDetails` 仍一律 `cCells=0`（诚实的空）⇒ 表单元文本未绘（具名下一靶）。载体：`build/MilBridge/P1-tail2-{floatercbk,tableobj,gate-on}-impl-report.md`。

⏪ **dated 现值位随动（`T-A56`／`T-A57`／`T-A58` 冻结收口，读时 `2026-10-01T12:5x+0800`；只增不改，上两段原文保留）**：① `T-A56`（表单元内容排版 `pfnFormatCellFinite` 真发调）⇒ 开闸腿第 4 色 `LightGoldenrodYellow = 5830 px`（表区 `dark(<140)=4318`）；② `T-A57`（`WPF_PTS_TABLECELL` 转**缺省开**）⇒ **缺省路径**即含表单元内容（`[FSTABLECELL] v=CELL-SUBPAGE`×16）；③ **`T-A58` 新一代冻结**：基线件 `bd64f2c1a3eaaa05 → 7cd1bc5c37a74e8d`（世代 `#80 → #81`），`verify-all 64✅/0❌ ×2`、六闸 `rc=0`。**现值位（现取）**：`.so d406f243cdc2c402`／`exports 689`（`PTSGAP=PASS tool=70 dead=11 artifact=1 ops=58 impl=59 so16=d406f243cdc2c402 exports=689`）。⚠️ **如实划界**：门禁 `[38]` 步读的**仓内证据目录** `build/MilBridge/tests/PtsPagesProbe/evidence/` 仍是 `T-A52` 之前的旧件 ⇒ **门禁现取 `PTS_COLORANCHOR=PASS hits=2`**（`LightGoldenrodYellow=0`），与车道腿的 `hits=3` **不同源**（详见 `build/MilBridge/P1-tail2-freeze81-report.md` §2）。载体：`build/MilBridge/P1-tail2-{textline,cellgate-on}-impl-report.md`／`build/MilBridge/P1-tail2-freeze81-report.md`。

⏪ **dated 更正（`T-A75`／本会话 `T-A58..A74` 入册；读时 `2026-10-02T09:08:09+0800`；只增不改，上文一字未动）**：本段（§0「现状」2026-09-24 快照与其上 dated 行）有六处须按现场更正 —— ① **「必死 `rc=134`／洋红占位」已不成立**：切「富文本」23／「流文档」24 现取 `phase=realized`／`magenta=0`／`[HC-UNHANDLED]=0`（`alive=yes app_rc=143 failfast=0`；承 `T-A33` 起的内容回填链 ＋ `T-A45..A57` 色锚链）；② **`TASK-0302` 现值 ＝ `ops=42`**（`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846`；`nm==exports==846`）—— 上文表内「可操作 42／实现口径 42」**现值仍在位**，但本会话 `T-A61`／`A62`／`A66` 已各把缺口**真实现**一批（`exports 689→846`、`stubs 0`）；③ **静默 `rc=139` 产品侧已修**（`T-A64`：`wpf_queue_push` 的 `tail` 零解引用守卫；`D-G109` 同根因另一半、确定性静默 SEGV 消除；⚠️ **率未重取、不宣称清零**）；④ **`TASK-0301` 反极性腿已办**（**在本会话之前的波次**由车道 W161A 在 `#64` 现件上跑完，见 `docs/ROUTES.md` §12 区与 `D-G129`）⇒ 上表第 ④ 行「只差这一条腿」**已闭**；⑤ **`DEFREG declared` 现值 ＝ `225`**（`DEFREG=PASS declared=225 route_ids=225`；`DEFREG_DECLDRIFT=0`）；⑥ **`BASELINE-FROZEN gen=#81`**（`docs/CURRENT-STATE.md:9` ＝ `BASELINE-FROZEN gen=#81 sha16=7cd1bc5c37a74e8d file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`；`T-A58` 重冻）。⚠️ **免读宽**：`TASK-0302` 本体（PTS／原生 LineServices）**仍是长线**（`ops=42`／`stubs 0`；`T-A67`／`A74` 判丁类 16 条**可诚实实施者 0**）。载体见 `build/MilBridge/P1-tail2-bookkeep2-report.md`。

⏪ **dated 收口（`T-B24`／`#82` 重冻入册；读时 `2026-10-03T20:3x+0800`；只增不改，上文一字未动）**：新一代冻结 —— 基线件 `7cd1bc5c37a74e8d → 05c5e521c3b14ace`（世代 `#81 → #82`；`1,238,130 → 1,248,947 B`）；冻后 `verify-all` ×2 各 `64 ✅ / 0 ❌`（`rc=0`）；`SSC=BASELINE=#82`。**本代内容**＝ hc demo 修复链（`T-B1..T-B19`：三 tab 视觉 ＋ 关窗不崩）＋ WIN-INTEROP L1/L3 ＋ 率重取（`T-B21`）＋ `R-GATE` 回归修（`T-B23`）＋ 尾波2 后续（`T-A59..A75`）。**值位（现取）**：`win32shim 5f9ed647c68197ae`／`exports 846`／`bridge 7152f9ac119e1bb0`／`pf 7ef0dbb210db54e3`／`pc 83c71acfb20f26d7`／`provider 4f01368cec2a728b`／`dwf e0fcfd13ad86b2b4`／`wic_shim f7b3026c8c019be2`／`hbtextline e2fa9ec9be1a6cf1`；`BRIDGE_SRC_FP 75c7883cc3145dc8`／`inputs_fp fd9b4064ed0f8532…`。载体 `build/MilBridge/P1-freeze82b-report.md`。

---

## §2 重写前的根 `README.md` 全文（254 行，逐字保留）

<!-- 以下为逐字全文，不改一字。⚠️ 因是逐字存档，文内的相对链接（如 `docs/PORT-SPEC.md`）仍按**仓根**解析 —— 它们是原文的一部分，**刻意不改写**（改了就违反"原文另存"）。 -->

# WPF on Linux —— 把 `dotnet/wpf` 移植成 Linux 原生可编译 + 可渲染

> **目标**：让 WPF 应用**在 Linux 上从源码编译、开窗、真的画出界面、并且能用鼠标键盘操作**。
> **边界（明说）**：**不**兼容"在 Windows 上编译好的 WPF 二进制"——这个边界砍掉了整条二进制兼容路线的工作量。
> **上游**：`upstream/wpf/`（`dotnet/wpf` 的一个快照，MIT，见 `upstream/wpf/LICENSE.TXT`）；上游**原始 README** 已保留为 [`README-Window.md`](README-Window.md)。
> **工程规范**（并行车道必须遵守）：[`docs/PORT-SPEC.md`](docs/PORT-SPEC.md)｜**并行路线图**：[`docs/ROUTES.md`](docs/ROUTES.md)｜**文档地图**：[`docs/INDEX.md`](docs/INDEX.md)｜**发 fork / 推分支**：[`docs/FORK-AND-PUSH.md`](docs/FORK-AND-PUSH.md)。

## 0. 现状（现读 2026-10-02；**本段是快照，权威一律以现场为准**）

**MVP 成立**：真实 WPF 应用（HandyControl 示例）**从源码编译通过 → 开窗 → 渲染 → 交互**，一条命令跑起来（`bash ~/run-hc.sh`；`--no-sync` 只启动，`--diag` 开输入仪器）。真机口径：hc 示例**逐页实测 29/31 页可用**。

| 现读入口 | 位置 |
|---|---|
| **世代与基线** | `docs/CURRENT-STATE.md:9`（现读 `gen=#82`，基线件 `05c5e521c3b14ace`／1,248,947 B） |
| **交接件（新会话先读这个）** | `build/MilBridge/HANDOFF-NEXT.md`（§5 = **23 条纪律**；§7 = **七条命令**重建存活态） |
| **路线图（权威状态）** | `docs/ROUTES.md` **§13 树**；`§15x+` = 逐波记录；`§14` = `[Next]` 清单 |
| **牙齿自检（一条命令）** | `bash build/MilBridge/tools/defect-registry-check.sh`（现读 `DEFREG=PASS declared=225`） |

**仍然已知的问题（2026-10-02 现读）**：

| # | 现象 | 状态 / 处置 |
|---|---|---|
| ① | 切「富文本」23／「流文档」24 | ✅ **已成立（不再是红）** —— 现取 `phase=realized`／`magenta=0`／`[HC-UNHANDLED]=0`（`alive=yes app_rc=143 failfast=0`）；**四具名色锚齐**：`PTS_COLORANCHOR=PASS hits=3`（`GhostWhite=9794`／`Beige=910`／`DarkGreen=44`／`LightGoldenrodYellow=5830`，基线四色全 `0`）；`PTS_GUARD=PASS`（在册证据 `build/MilBridge/tests/PtsPagesProbe/evidence/`）。判据面随 `T-A33..A59` 链闭合 |
| ② | **PTS／原生 LineServices 真实现** | 🟡 **长线（不再是阻塞项）** —— 现值 `PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42`／`.so=df27801beb222f05`／`exports=846`／`stubs=0`（`nm==exports`），即 **可操作 42／实现口径 42**；余 42 条**逐条具名且已证为合法终点**：乙 20（本侧无测量源）／丙 6（`Nl*` 在册有意降级）／丁 16（**LS 链已被 shim 替换 ⇒ 无真腿可达 ⇒ 可诚实实施者 0**，`T-A67`／`A74`） |
| ③ | 静默 `rc=139`＋0 字节日志 | 🟡 **产品侧已修** —— `T-A64`：`wpf_queue_push` 的 `tail` 零解引用守卫（`D-G109` 同根因另一半；反腿 `rc=139`＋`si_addr=0x13a` ⇒ 正腿 `rc=0`）；装置侧可比时间窗已闭（`T-A60`：`BASELINERATE` 由 `VOID-PREMISE` 转**可判定 `FAIL`＋点名**）。⚠️ **率未重取、不宣称清零**（残余窄 `TOCTOU`＝`TASK-0211` 另计） |
| ④ | 零墨修法的**反极性腿**未跑 | ✅ **已办**（车道 W161A 在 `#64` 现件上真跑，见 `docs/ROUTES.md` §12 区与 `D-G129`） |

> ⏪ **本表上一版是 2026-09-24 的 4 行（①必死 `rc=134`／②`TASK-0302`／③读数须重取／④只差一条腿）**，其逐条更正见下方 `T-A75` dated 行；更早的 8 行版（2026-09-20）已删，全文可从 git 历史逐字取回（`git -C ~/netTest/GitProj/WPFOnLinux log --oneline -- README.md`）。逐条细节见 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 与 `docs/ROUTES.md`。
>
> ⏪ **dated 更正（`T-A33`，读时 `2026-09-30`；只增不改，上面两行**原文保留**）**：① 行「必死 `rc=134`／洋红占位」**已不成立** —— `T-A33` 落地 **native 查询期文本行回填**（`FsQueryTextDetails`／三入口按**行记录台账**真填出参）后，切「富文本」23／「流文档」24 **不再崩**（`alive=yes app_rc=143 failfast=0`），且**占位图消失、内容区首次出现真实像素**（改前/反极性：占位 `129792` px、`AE(content)=0`；改后：占位 **0** px、`AE(content)=203949`／`174476`）。② 行「PTS／LineServices 真实现」**仍**是长线（`TASK-0302`；`可操作 70／实现口径 73` **未变**）。⚠️ 免读宽：`PTS` 本体仍是**降级实现**，新前沿见 `docs/ROUTES.md` §15x 的 `T-A33` 行与载体 `build/MilBridge/P1-tail2-backfill-impl-report.md`。
> ⏪ **dated 更正（`T-A36`，读时 `2026-09-30`；只增不改，上面各行**原文保留**）**：`T-A36` 落地 **native「PTS 附属对象回填」**（`Figure`/`Floater` 建台账 ＋ 查询期回填 `cAttachedObjects`，并新增 `FsQueryAttachedObjectList`／`FsQuerySubpageDetails`／`FsQueryFigureObjectDetails`／`FsQueryFloaterDetails` **四导出**）后，`k=24` 帧上**首现具名色块**（`PTS_COLORANCHOR` `hits 0→1`；**`GhostWhite 0→29637 px`**），`colors 654→724`，帧 `fa7df9222ebb199f → 1487caf78fd88886`；症状门**无回归**（`[HC-UNHANDLED]=1`）。⚠️ **免读宽**：**四具名色仍只出 1 个**（`Beige`/`DarkGreen`/`LightGoldenrodYellow` 在 `Figure`/`Floater` 的**内容**里，需"附属对象内容排版"驱动 ⇒ 下一增量）；`PTS` 本体仍是**降级实现**。现值位随动：`可操作 66／实现口径 69`（`.so=21ad5f39ef3c4034`／`exports=681`）。载体 `build/MilBridge/P1-tail2-attach-impl-report.md`。

> ⏪ **dated 更正（`T-A41`，读时 `2026-09-30T18:5x+0800`；只增不改，上面各行**原文保留**）**：`T-A41` 同趟落两件 —— ① **native 只读判别器 `D0`**（`[FSQVP]`）：把「页轨枚举经由哪条支（arrange／visual／viewport）」按**紧邻事件＋页查询状态**判开（**推断**，行尾具名 `NOINFO=viewport-branch-callsite`，**不是**直读）；② **托管侧视口驱动**（`FlowDocumentView.Linux.cs`，由 `reapply-patches.py` 生成；`WPF_FSVIEW_VIEWPORT_DRIVE=0` 可整点撤掉）＋ 只读台账 `[FSVIEW]`。**成对读数（现取，6 腿）**：`via=viewport` **78–171 次（≠0）**⇒ `A40` 的断点判定（「视口支整条未发生」）**被证伪**（该支一直在跑）；判别器三标签分布 `arrange≈visual≈viewport≈每轮 1 条`、**自洽性反例 ZERO**。🔴 **本页上驱动成空转**：`[FSVIEW]` 现取 `handed == viewport`（`638.4x366.72` DIP）、页盒仅 `39.81x39.17` DIP、`visbounds=empty`（本移植 `VisualTreeHelper.GetDescendantBounds` 取不到）⇒ **帧面逐字节不变**（`k24=1487caf78fd88886`／`colors=724`／`GhostWhite=29637 px`、余 3 色仍 `0`）⇒ **判据 ② 未达**（`PTS_COLORANCHOR=FAIL hits=1`）。症状门**无回归**（`alive=yes app_rc=143 failfast=0 magenta=0 [HC-UNHANDLED]=1`）。现值位随动：`.so 606dad49ae7b34a1 → dd9865c38e18ed81`；`exports=683` 不变；`PTSGAP=PASS`（`tool=76 dead=11 artifact=1 ops=64 impl=67`，与 `win32_classification.c:52` 的「可操作 64／实现口径 67」**逐数相符**）；`nm==exports`；`DEFREG`／`REPORTID` rc=0。载体 `build/MilBridge/P1-tail2-fsview-impl-report.md`。

> ⏪ **dated 更正（`T-B1..T-B19` hc demo 修复链，读时 `2026-10-03`；只增不改，上面各行**原文保留**）**：hc demo（HandyControl 示例）**已知缺陷表全部已修** —— ① **「流文档」视图文字重叠**（`T-B3`／`T-B4`／`T-B15`：行盒取"段在页中的原点" ＋ 浮动绕排 ⇒ 重叠量 `58.8% → 0`、`touch_fig_rows 17→0`／`touch_flo_rows 6→0`）；② **「流文档单页视图」（tab2）空白**（`T-B12`：分页页视觉换父接回 ⇒ `colors 551→841` ＋ 具名色）；③ **「流文档查看器」（tab3）空白**（`T-B16`／`T-B17`／`T-B18`／`T-B19`：PresentationUI 主题字典补齐 ＋ `E_HANDLE` 具名／`PRECOND-WIC-RTB` 解除 ＋ 修体挪到渲染遍历入口 ⇒ 文档区 `148→731`、具名色 `0/0/0/0 → 9449/842/16/5861`）；④ **关窗 `rc=134`**（`T-B14`：`APP_RC 134→0`）。⇒ `~/run-hc.sh` 的「**⛔ 暂时别点：左侧「富文本」「流文档」…**」警告**已撤**（该警告的旧前提 `EntryPointNotFoundException`／不可捕获 `FailFast` 已全部不再成立）。⚠️ **免读宽**：本表 ①②③④ 四行**仍是 2026-10-02 的读数**（`T-A33..A59` 链），本行只作 **hc demo 面** 的 dated 更正；`TASK-0302`（PTS 真实现）仍**长线**。载体：`build/MilBridge/P1-hcbookkeep-report.md`。


## 1. 今天能做什么（每条都可复算）

| 能力 | 现状 | 复算入口 |
|---|---|---|
| **编译** WPF 托管层 | `PresentationCore` / `PresentationFramework` / `WindowsBase` / `System.Xaml` / `DirectWriteForwarder` / `DirectWrite.Linux.Provider` 全部 0 error | `WAVE_OWNER=<你> bash build/integration-wave.sh` |
| **原生侧** | `libwpfwin32.so`（窗口/消息/GDI/OEM/GDI+ 面）、`libwpfwic.so`（WIC → Skia 解码）、`wpfgfx_cor3.so`（AOT 的 milcore 渲染核心） | `bash src/WpfGfx.Linux.Native/build-shim.sh`、`bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh`、`bash build/MilBridge/run.sh build` |
| **开窗 + 渲染**（仓内样本） | `samples/WpfTextDemo`：默认档（**清空全部字体 env**）窗口内 **3960 色**、`14/14` 帧非空、`未画种类 0` | `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both` |
| **第三方形态（仓内判据）** | `samples/ThirdPartyMini`：只经 `build/third-party/WpfLinux.props` 接线、不进 sln、产物**复制到仓外**再跑；`WindowChrome` ＋ 图片解码（`Bgra32`）＋ 中文/图标 ＋ 数据绑定全部渲染（窗口内 **1485 色**） | `bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25`（`verify-all` 第 `[19]` 步） |
| **第三方真实应用（仓外实证）** | HandyControl 示例工程：库 + demo **0 error**（148 个 Page 进 BAML）、**开窗并渲染出完整界面**（自定义 chrome ＋ 中文控件名 ＋ 图标 ＋ 图片；窗口内 **1275 色**，**零探针装置**） | 见 §4；⚠️ 该实证在**仓外** ⇒ 它是产品事实，**不单独构成仓内判据**（仓内判据见上一行） |
| **一键验收** | `verify-all.sh`：**64 步**、**875 用例通过**、2 跳过，含五臂对拍 / 应用门禁 / 冻结基线核对 / 第三方形态样本（现读 `64 ✅ / 0 ❌`，rc=0） | `bash verify-all.sh` |

**"可复算"是本工程的硬要求**：每个结论都得有一条命令能重算，并且**判据件自己也被看着**
（`verify-all` 的 64 步里**相当一部分**是"看仪器的仪器"：门禁自检、输入覆盖面自检、引号陷阱、`pipefail` SIGPIPE 普查、隐形段牙齿、列级下限外挂读者……）。

---

## 2. 快速开始

### 2.1 依赖

```bash
# 编译器与系统库（原生 shim 需要 X11 头文件；AOT 需要 clang）
sudo apt-get install -y gcc libc6-dev libx11-dev zlib1g-dev clang
# X11 / 截图 / 字体工具（验收用；跑样本也需要一个 X server）
sudo apt-get install -y xvfb x11-apps x11-utils imagemagick fontconfig libfontconfig1
# .NET SDK 10（仓内 global.json 锁 10.0.111；用 dotnet-install.sh 或发行版包皆可）
dotnet --version
```

一键装环境（含 NuGet 源、SkiaSharp 预热、测试字体、`global.json` 锁定）：

```bash
bash build/setup-env.sh     # ⚠️ 它会把 NuGet 源写成国内镜像（见脚本内 NUGET_MIRROR）；正常网络下请自行改回 nuget.org
bash build/verify-env.sh    # 打印环境清单，逐项 OK/WARN/FAIL
```

> ⚠️ `setup-env.sh` 里的镜像（`mirrors.huaweicloud.com` / `gh-proxy.com`）是**当年沙箱网络**的产物，
> 不是产品依赖：把 `~/.nuget/NuGet/NuGet.Config` 换回你自己的源同样能跑。

### 2.2 从零构建（移植 + 编译）

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh     # 顺序：port-lib 重生成 → 应用器重放 → 按依赖序重建
```

- `WAVE_OWNER` 是**结构约束**（不是礼貌）：没有它脚本直接退出。每一趟都往 `build/wave-audit.log`
  追加一条可追溯记录（时间/pid/ppid/tty/命令行/owner）——"认领不到人的重建"从此不可能悄悄发生。
- 这一步会跑 `build/port-lib.py` **整体重写**各 `*.Linux.csproj`，
  再按 `build/integration-wave.sh` 里的登记表重放**应用器**（`src/WpfGfx.Linux.Native/tools/patch-*.py`）。
  ⚠️ **手工改 csproj 会在下一次 `port-lib` 时被抹掉** —— 接线要写进应用器（`--check` 幂等）。

### 2.3 开窗渲染（一条命令）

```bash
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both
# 默认档 = 清空全部 WPF_LINUX_*/HLWPF_* 字体 env（这才是真应用拿到的配置）；env 档只作对照
# 机读行会打印：WPTD_SUMMARY / WPTD_GATE / 每帧 PNG 路径（人眼复核用）
```

它自己起 `Xvfb :97`、截屏、判据四条（进程存活＋`未画种类 0`＋截图非空非纯色＋逐特性颜色计数），
两档都必须过；只要一档过 = 失败。

### 2.4 一键验收（要一个 X server，`verify-all.sh` 自己会用 `:99`）

```bash
bash verify-all.sh          # 64 步；含构建、测试、五臂对拍、应用门禁、冻结基线核对、时间分辨画面读者
```

---

## 3. 架构（30 秒版）

```
upstream/wpf/**            只读上游（不改）
      │  build/port-lib.py  （剔除 Windows-only 源 + 纳入生成的 *.Linux.cs；**整体重写** csproj）
      ▼
build/*.Linux/*.csproj  ──构建──▶  六个托管程序集（pc / pf / windowsbase / system.xaml / dwf / provider）
      │  应用器重放（patch-*.py：补丁式接线，幂等 + --check + 锚点数断言）
      ▼
原生三件：libwpfwin32.so（Win32/GDI/OEM/GDI+ 面，口径=能真做的真做、做不到的**如实失败**）
          libwpfwic.so   （WIC → Skia 解码桥）
          wpfgfx_cor3.so （AOT 的 milcore：渲染核心）
```

细节（含"为什么用替换式而不是 fork 式"、DPI/字体/资源管线/主题栈的处理）见 **`docs/ARCHITECTURE.md`**；
逐波的技术账（每一波的预登记、读数、被推翻的旧结论）见 **`docs/WAVE*-PREREGISTRATION.md`** 与 **`handoff.md`**。

---

## 4. 第三方 WPF 应用怎么用

两条事实（都实测过）：

1. **原生 interop 的正道通道**：`Win32ShimResolver` 挂了**默认 ALC 级钩子**
   （`AssemblyLoadContext.Default.ResolvingUnmanagedDll`）⇒ **第三方程序集**的
   `[DllImport("user32.dll")]` / `"shell32.dll"` / `"gdiplus.dll"` … 也能落到我们的 shim 上。
2. **部署布局：零环境变量**。把下面这些**放在应用输出目录**（和 `YourApp.dll` 同目录）即可：

```
YourApp.dll
libwpfwin32.so          # Win32/GDI/OEM/GDI+ shim
libwpfwic.so            # WIC → Skia 解码桥
wpfgfx_cor3.so          # AOT milcore（渲染核心）
libSkiaSharp.so         # 来自 NuGet 包 SkiaSharp.NativeAssets.Linux（与托管包版本必须配对）
```

工程侧最小改动：`<UseWPF>false</UseWPF>` ＋ 显式引用自建的六个程序集与 `PresentationFramework.Classic`
（配方模板 = `build/third-party/WpfLinux.props`，逐条说明见 `docs/THIRD-PARTY-APPS.md`；
**仓内就有一个按这个配方做的可跑样本** = `samples/ThirdPartyMini`（独立 csproj、不进 sln、
产物**复制到仓外**再跑），先用它验证你的环境：`bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25`）。

⚠️ **已知会让第三方应用踩坑的边界**（详见 §6）：官方 `System.Windows.Extensions` 包在非 Windows 上**必抛**
（`XamlAccessLevel`/`SoundPlayer`/`X509Certificate2UI`）—— **本仓已用 Linux 原生替身打通**（`#38`；
配方见 `build/third-party/WpfLinux.props`：留一条"排除 `compile;runtime` 资产"的占位包引用 ＋ 指向替身的 `<Reference>`）；⚠️ 但**Debug 权威件带着"活的"`Invariant.Assert`** ⇒ 真实第三方应用可能在模板解析时被断言终止（**`D-G47`**，待"权威件切 Release"治）；
GDI+ 的**图像编解码族**只做到"应用能起来"；`ntdll` 面只有 `RtlGetVersion`。

---

## 5. 可复算性：这个仓的"牙齿"

| 机制 | 一句话 |
|---|---|
| `verify-all.sh`（64 步） | 构建 + 测试 + 五臂对拍 + 应用门禁 + 一堆"看仪器的仪器"；`NOINFO` 一律不许当绿 |
| `build/integration-wave.sh` | 移植 + 构建的唯一入口；波必须**认领**（`WAVE_OWNER`）并留审计行 |
| 五臂对拍（`tline`/`tab-*`/`textlineproto`） | Linux 与 Windows 真值逐行比；臂日志 sha 有机器声明 |
| 应用门禁（两档 × 3 rep） | 真开窗、真截屏、真数色；`BASELINE … result=PASS` 机读行 |
| 冻结基线 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 是**唯一权威**；整份 sha 只由 `docs/CURRENT-STATE.md` 里那一行机器声明；谁改都要过 `baseline-sha-check.sh` |
| 九位产物身份 | 九个权威件的 sha16 逐位记录在冻结块里（`pf` 是"环成员"，它的位移按惯例如实记录） |
| 已知红 | `build/MilBridge/known-red.json` ＋ 声明表；"已知红"必须是**登记过的**，不许口头豁免 |

---

## 6. 已知边界（诚实清单，发布初版照抄）

- **权威件构建配置 = `Release`**（**`#40` 起已经切换并冻结**；唯一声明 = `build/SelfBuiltConfig.props`，自检 `bash build/selfbuilt-config.sh --check`）。⏪ 原句写「权威件是 Debug 构建（切 Release 是下一步）」**已过期**，其全文可从 git 历史取回。
- **GDI+ 图像族**（`GdipCreateBitmapFromFile`/`Save`…）返回"如实失败"；查询类返回空结果 ⇒ 依赖 GDI+ 解码的第三方代码会走不到图。
- **`D-T4`**：帧步的 3 条**结构族**红（已登记、判据刻意不判结构族）。修它会让像素变、需重取五臂与 136 条 `tab0` 真值 ⇒ 独立成波。
- **`D-G45`**：`System.Windows.Extensions` 的 Linux 原生替身**已写好但停用**（接线后 `PresentationFramework` 报 `CS0012`：程序集身份不一致）。
- **第三方实证在仓外**（HandyControl 样本工程与探针都不在本仓）⇒ 仓内判据只覆盖自建样本。
- **Windows-only 特性的处理口径**：能降级的降级（DWM＝"有 DWM、合成关闭"、uxtheme＝"无活动主题"），
  做不到的**如实失败**（返回错误码，而不是假装成功）——**不许用谎话换绿屏**。
- 逐条细节见 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 与 `docs/CURRENT-STATE.md`。

---

## 7. 目录导航

| 路径 | 是什么 |
|---|---|
| `upstream/wpf/` | 上游 `dotnet/wpf` 快照（**只读**；基点 commit `1cfc37f708f9`）。<br>🔴 **账一已结（2026-09-26 · P0 迁移）**：fork 根目录里那棵 dotnet/wpf **自带**的重复树，原先按「暂按保持现状」处置、并断言「**根目录那份不使用**」—— **那句已被证伪**，两条**独立机制**（现取）：① 它的根 `Directory.Build.props` 会被 MSBuild **自动导入**（`eng/WpfArcadeSdk/Sdk/Sdk.props:5` ⇒ `Sdk="Microsoft.DotNet.Arcade.Sdk"`）⇒ `samples/HelloMil/HelloMil.csproj` **求值即** `error MSB4236`（同一命令在无那棵树的树上给出正常 JSON）；② 它的 **92 个 csproj** 会进 `build-hygiene-import-check.sh` 的候选集 ⇒ `verify-all.sh` 第 `[9]` 步 `cand=88→180`、`undeclared=0→92`、`reason=drift`。⇒ 该重复树**已结构性移出**（19 条路径／7346 件／125,377,211 B；逐件清单口径见报告 §5），移出后 `[9]` 回到 `BHYGIENE_IMPORT=PASS reason=ok cand=88 undeclared=0`。**本仓构建仍只读 `upstream/wpf/**`** —— 且它现在是**唯一**被读的那一份：`build/port-lib.py` 的 `upstream_nowarn()` 上界就是 `upstream/wpf`；`build/MilBridge/tools/applier-audit.py` 把 `src/Microsoft.DotNet.Wpf/` 这一拼写**显式重定向**到 `upstream/wpf/`。全文／复算命令／回滚路径见 `build/MilBridge/P0-migrate-report.md`。 |
| `build/port-lib.py` | 移植生成器（重写 `*.Linux.csproj`） |
| `build/integration-wave.sh` | 移植 + 构建的唯一入口 |
| `build/*.Linux/` | 各 Linux 工程的骨架与生成物 |
| `src/WpfGfx.Linux.Native/` | 原生 shim 源码（C）与应用器（`tools/patch-*.py`） |
| `build/MilBridge/` | AOT milcore 桥 + 五臂 + 门禁 + 冻结/核对工具 |
| `samples/` | 仓内样本（`WpfTextDemo` 是门禁样本） |
| `tests/` | 测试套件与 runner（含应用门禁 runner） |
| `docs/CURRENT-STATE.md` | **接手先读这一个文件**（当前状态一页纸） |
| `docs/ARCHITECTURE.md` | 架构与设计取舍 |
| `handoff.md` | 逐波技术账（长，按需查） |
| `verify-all.sh` | 一键验收 |

---

## 8. 发布（本仓准备开源时的清单）

⚠️ **发布前必办**（实测数字与处置见 **`docs/RELEASE-READINESS.md`**）：

1. **`.gitignore`**（仓根已备）：不忽略的话 `git add -A` 会把 129 个 `bin/obj/.artifacts` 目录（≈3.3 GB）一起进库。
2. **GitHub 单文件 100 MB 硬限**：`tests/parity/geometry/u14/linux-results-u14.json` = **118.2 MB**
   ⇒ 直接 `git push` **会被拒**。**已实测查明不必用 LFS**：那份 JSON **全仓没有任何读者**（只是探针输出，
   重算 = 跑 `tests/parity/geometry/u14/U14.csproj`），另一份 55 MB 的 Windows 真机 dump 也**只作为派生件的来源**
   （真值读者读的是仓内 3.1 MB 的 `build/MilBridge/gen/layout-b34-compact.json` ＋ 4.7 KB 的 `ProductEntryArm/inputs.json`）
   ⇒ 两份都已写进 `.gitignore`（**排除 ≠ 删除**：工作树里照旧），仓库从 **382M → 202M**、且**没有任何现有判据失去可复算性**。
3. **第三方资源许可**：`build/fonts/`（Noto Sans，OFL 1.1）已随附 `LICENSE-OFL.txt`；
   上游 `upstream/wpf/LICENSE.TXT` 在库；`build/keys/WcpPublicKey.snk` 是**公钥**（公开签名，无险）。
4. **上游快照的出处** ✅ 已钉死：`upstream/wpf/` = `dotnet/wpf` 的裁剪快照，**基点 commit = `1cfc37f708f91ff4556bd25af414546c446f3a16`**
   （`#11837`，2026-08-21）。判据 = 6414 件里 **6384 件逐字节相同** ＋ 29 件仅换行不同 ＋ 1 件刻意改的 `.gitattributes`
   ＋ 954 件已登记的裁剪；复算命令见 [`docs/UPSTREAM-PROVENANCE.md`](docs/UPSTREAM-PROVENANCE.md) §1.1。
   ⚠️ 发布说明要写清：`tests/parity/windows/layout-b34/windows-results.json`（53 MB，已不入库）**只能在 Windows 侧重录**，
   不是「凭空可重算」的（见 [`docs/RELEASE-READINESS.md`](docs/RELEASE-READINESS.md)）。

---

## 9. 许可

- 上游 `upstream/wpf/**` 沿用其 **MIT** 许可（`upstream/wpf/LICENSE.TXT`）。
- 本仓新增部分（`build/`、`src/WpfGfx.Linux.Native/`、`samples/`、`tests/`、`docs/` 等）随本仓许可发布。
- `build/keys/WcpPublicKey.snk` 是**公钥**（生成物用 `PublicSign` 公开签名），不含私钥。


- 上游 `upstream/wpf/**`：**MIT**（见其 `LICENSE.TXT`）。
- `build/fonts/*.ttf`：**SIL OFL 1.1**（见 `build/fonts/LICENSE-OFL.txt`）。
- 其余新增部分：随本仓许可发布（发布时由作者选定具体许可证）。


---

## ⏪ **dated 收口（2026-09-28 · 车道 `t14`；上文一字未动）**

- **账一**：上文 §7 的 `upstream/wpf/` 行已逐字点名「**根目录那份不使用**」**被证伪**（两条独立机制：根 `Directory.Build.props` 被 MSBuild 自动导入 ⇒ `error MSB4236`；其 **92 个 csproj** 进 build-hygiene 候选集；现取读数见该行）。⚠️ **该事实的"入册"（`KNOWN-DEFECTS.md` 新号）尚未落** —— 逐字状态＝**待配号**（本趟不动 route 件；登记批由 `t57`／队长安排）。
- ⏪ **dated 更正（`t66`，读时 `2026-09-28T13:17+08:00`；上文「尚未落／待配号」原文保留）**：**该事实的入册已经落** —— 现取 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:3666` 有 **`### 🆕 D-G180`**（「fork 根级上游件会改变整棵树的求值结果」）；声明表现取有 **`ID	D-G180	req=KD`**；`DEFREG=PASS declared=`**`215`**（**已含 `D-G180`**；读时同上）⇒ **不再是"待配号"**。
- 🔴 **九位权威产物是「本地物件」**：`src/WpfGfx.Linux.Native/bin/` 被 `.gitignore`（`:22-26`）忽略 ⇒ `git ls-files src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **0**、`…/exports.txt` ＝ **0**（现取）⇒ **干净克隆取不回、必须重建**。凡本文档任何"产物已在库/已在远端"的暗示都是**假绿方向** —— `R8` 判据① 正是「**干净 clone ＋ 按 README 从零构建**」。
- **导出面三种口径（现取，读时 `2026-09-28T12:26+08:00`）**：在册口径（`wc -l < src/WpfGfx.Linux.Native/bin/exports.txt`）＝ **556**｜`nm -D --defined-only` ＝ **556**｜`nm -D` 全量 ＝ **648** ⇒ 引用必须写明口径。
- **交接面**：九位产物不进 git ⇒ 交接必须靠**构建**或 `~/w-keep-shims/`（HANDOFF-NEXT 的未结账项里已写）。

⏪ **dated 落地（`T-A47`／`TASK-0302` 增量；读时 `2026-09-30T20:2x+0800`；只增不改）**：**消掉"相位翻最后一阻"＝缺省路径残留的 1 条 `[HC-UNHANDLED]`**。①（托管，走生成器 `P8`）生成件 `PtsHelper.Linux.cs` 的 `UpdateFloatingElementVisuals` **补浮层视觉的换父**（照上游自己的 `UpdateParaListVisuals` 同形先例）；②（native）`src/WpfGfx.Linux.Native/src/win32_pts.c` 的 `drive-handles-released(page-destroyed)` **两处**拒因**收窄**为"下一次填充必然要发 `+176 CreateParaclient` 时才拒"。**成对（同 `.so 1dbea9026dd7d3d7`／同装置 `:231`／只差 env）**：缺省 **`[HC-UNHANDLED]=0`**｜`WPF_FLOAT_REPARENT=0` ⇒ **1**（`ArgumentException`）｜`WPF_PTS_QTP_LIVE_NARROW=0` ⇒ **1**（`PtsException … '-10000'`）。**零回归**：`PTS_COLORANCHOR=PASS k=24 hits=2`（`Beige=910`／`DarkGreen=44`）、`k24 fr_sha=791696291d51470b` 未变；`nm==exports==683`；`PTSGAP`／`DEFREG`／`REPORTID` 各 `rc=0`。⚠️ 拒因收窄后**分页器走完整个文档**（`[QPD] page=` 去重 **280** 页 vs 改前 ~7）—— 如实记，**帧面逐字节未变**。载体：`build/MilBridge/P1-tail2-hcres-impl-report.md`。

⏪ **dated 收尾对齐（`T-A49`／`T-A50`／`T-A51`，读时 `2026-09-30T23:59+0800`；只增不改）**：① `T-A49`（E5 重取臂 · 五臂换代）：世代绑定项 `instr_shim 921ba9c65e9fb3be → e2fa9ec9be1a6cf1` ⇒ 五臂重取，`TLINE_GATE=PASS tree_gen=same drift=0 gone=0 unregistered=0`；五臂红/绿结论与在册逐字相同（`known-red.json 29219b6f071c6361 → dcc22fd3c80cfcac`）；同趟 `repo-alias-allow.tsv` 补声明臂日志输出树 ⇒ `ALIAS=PASS`。② `T-A50`（重冻结冻结块 5 行 `# ARM-LOG-SHA`）：`COLUMN_FLOOR=FAIL → PASS`；基线件 `b27ff6332f263495 → bd64f2c1a3eaaa05`（**世代仍 `#80`**）。③ `T-A51`（收尾）：**现取六闸逐条 `rc=0`**（`SSC`／`HANDOFF_MV`／`DEFREG=PASS declared=225`／`REPORTID`／`COLUMN_FLOOR`／`ARMLOG_SHA`）；整波旁生件 `git checkout HEAD --` 归位（旁生件归 0）；`declared.tsv` 重发 225 条。载体：`build/MilBridge/P1-tail2-closeout-report.md`。

⏪ **dated 现值位随动（`T-A52`／`T-A53`／`T-A54`，读时 `2026-10-01T08:0x+0800`；只增不改，上两段原文保留）**：三连落地后**第 4 具名色 `LightGoldenrodYellow` 缺省落位** —— `T-A52`（`GetFloaterHandlerInfo` 真实现 ＋ Floater 内容排版驱动；缺省关，零回归）⇒ 真阻挡前移 ＝ `Floater` 内 `<Table>` 撞未导出 `FsQueryTableObjDetails`；`T-A53`（**Table 族五入口导出**，`exports 683→688`）⇒ 开闸腿 `LightGoldenrodYellow=1998 px`；`T-A54`（两闸转**缺省开**）⇒ **缺省腿** `LightGoldenrodYellow = 1998 px`、`PTS_COLORANCHOR=PASS k=24 hits=3`、缺省零回归（三帧与 `T-A53` 开闸腿逐字节同）。**现值位（现取）**：`可操作 59／实现口径 60`；`.so 642019f680d75d87`／`exports 688`（`PTSGAP=PASS tool=71 dead=11 artifact=1 ops=59 impl=60 so16=642019f680d75d87 exports=688`）。⚠️ **免读宽**：第 4 色所在层 ＝ **`TableRow Background`（表行背景）**，只让行背景落像素；`FsQueryTableObjRowDetails` 仍一律 `cCells=0`（诚实的空）⇒ 表单元文本未绘（具名下一靶）。载体：`build/MilBridge/P1-tail2-{floatercbk,tableobj,gate-on}-impl-report.md`。

⏪ **dated 现值位随动（`T-A56`／`T-A57`／`T-A58` 冻结收口，读时 `2026-10-01T12:5x+0800`；只增不改，上两段原文保留）**：① `T-A56`（表单元内容排版 `pfnFormatCellFinite` 真发调）⇒ 开闸腿第 4 色 `LightGoldenrodYellow = 5830 px`（表区 `dark(<140)=4318`）；② `T-A57`（`WPF_PTS_TABLECELL` 转**缺省开**）⇒ **缺省路径**即含表单元内容（`[FSTABLECELL] v=CELL-SUBPAGE`×16）；③ **`T-A58` 新一代冻结**：基线件 `bd64f2c1a3eaaa05 → 7cd1bc5c37a74e8d`（世代 `#80 → #81`），`verify-all 64✅/0❌ ×2`、六闸 `rc=0`。**现值位（现取）**：`.so d406f243cdc2c402`／`exports 689`（`PTSGAP=PASS tool=70 dead=11 artifact=1 ops=58 impl=59 so16=d406f243cdc2c402 exports=689`）。⚠️ **如实划界**：门禁 `[38]` 步读的**仓内证据目录** `build/MilBridge/tests/PtsPagesProbe/evidence/` 仍是 `T-A52` 之前的旧件 ⇒ **门禁现取 `PTS_COLORANCHOR=PASS hits=2`**（`LightGoldenrodYellow=0`），与车道腿的 `hits=3` **不同源**（详见 `build/MilBridge/P1-tail2-freeze81-report.md` §2）。载体：`build/MilBridge/P1-tail2-{textline,cellgate-on}-impl-report.md`／`build/MilBridge/P1-tail2-freeze81-report.md`。

⏪ **dated 更正（`T-A75`／本会话 `T-A58..A74` 入册；读时 `2026-10-02T09:08:09+0800`；只增不改，上文一字未动）**：本段（§0「现状」2026-09-24 快照与其上 dated 行）有六处须按现场更正 —— ① **「必死 `rc=134`／洋红占位」已不成立**：切「富文本」23／「流文档」24 现取 `phase=realized`／`magenta=0`／`[HC-UNHANDLED]=0`（`alive=yes app_rc=143 failfast=0`；承 `T-A33` 起的内容回填链 ＋ `T-A45..A57` 色锚链）；② **`TASK-0302` 现值 ＝ `ops=42`**（`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846`；`nm==exports==846`）—— 上文表内「可操作 42／实现口径 42」**现值仍在位**，但本会话 `T-A61`／`A62`／`A66` 已各把缺口**真实现**一批（`exports 689→846`、`stubs 0`）；③ **静默 `rc=139` 产品侧已修**（`T-A64`：`wpf_queue_push` 的 `tail` 零解引用守卫；`D-G109` 同根因另一半、确定性静默 SEGV 消除；⚠️ **率未重取、不宣称清零**）；④ **`TASK-0301` 反极性腿已办**（**在本会话之前的波次**由车道 W161A 在 `#64` 现件上跑完，见 `docs/ROUTES.md` §12 区与 `D-G129`）⇒ 上表第 ④ 行「只差这一条腿」**已闭**；⑤ **`DEFREG declared` 现值 ＝ `225`**（`DEFREG=PASS declared=225 route_ids=225`；`DEFREG_DECLDRIFT=0`）；⑥ **`BASELINE-FROZEN gen=#81`**（`docs/CURRENT-STATE.md:9` ＝ `BASELINE-FROZEN gen=#81 sha16=7cd1bc5c37a74e8d file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`；`T-A58` 重冻）。⚠️ **免读宽**：`TASK-0302` 本体（PTS／原生 LineServices）**仍是长线**（`ops=42`／`stubs 0`；`T-A67`／`A74` 判丁类 16 条**可诚实实施者 0**）。载体见 `build/MilBridge/P1-tail2-bookkeep2-report.md`。

⏪ **dated 收口（`T-B24`／`#82` 重冻入册；读时 `2026-10-03T20:3x+0800`；只增不改，上文一字未动）**：新一代冻结 —— 基线件 `7cd1bc5c37a74e8d → 05c5e521c3b14ace`（世代 `#81 → #82`；`1,238,130 → 1,248,947 B`）；冻后 `verify-all` ×2 各 `64 ✅ / 0 ❌`（`rc=0`）；`SSC=BASELINE=#82`。**本代内容**＝ hc demo 修复链（`T-B1..T-B19`：三 tab 视觉 ＋ 关窗不崩）＋ WIN-INTEROP L1/L3 ＋ 率重取（`T-B21`）＋ `R-GATE` 回归修（`T-B23`）＋ 尾波2 后续（`T-A59..A75`）。**值位（现取）**：`win32shim 5f9ed647c68197ae`／`exports 846`／`bridge 7152f9ac119e1bb0`／`pf 7ef0dbb210db54e3`／`pc 83c71acfb20f26d7`／`provider 4f01368cec2a728b`／`dwf e0fcfd13ad86b2b4`／`wic_shim f7b3026c8c019be2`／`hbtextline e2fa9ec9be1a6cf1`；`BRIDGE_SRC_FP 75c7883cc3145dc8`／`inputs_fp fd9b4064ed0f8532…`。载体 `build/MilBridge/P1-freeze82b-report.md`。

---

[English](README.md) | [中文](README.zh-CN.md) | [Español](README.es.md) · [证据索引](README.zh-CN.md) · [移植侧文档总线](../README.zh-CN.md)
