# W116A 报告 —— 波 `#52` 前半段登记（第九笔）：新号 `D-G100`（**已修**）＋ `D-G98` 两条"**被证伪**" ＋ 地图两条 TASK ＋ 推送

> 车道 = **W116A**｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（本机 `R` **不是** git 仓库；推送在 fork 克隆里做）
> fork 克隆 = `~/netTest/GitProj/WPFOnLinux`（`feat-Linux`）｜冻结基线 = **`#51` `38e67e834430d75c`**｜`DEFREG` 起点 = `PASS declared=135`
> 判据 = `~/w116a/criteria.md`（**先写**，见 §2；本报告 §3–§6 的读数**全部**在本件编辑之后才取）
> **本报告 sha16 的口径**：`grep -v '^<!-- SHA16' 本文件 | sha256sum | cut -c1-16`（最后一行是自指行，剔除）
> **本件性质**：**纯文本编辑 ＋ 一次推送** —— **零 `dotnet`／零构建／零门禁／零应用／不占槽**（`verify-all`／`close-wave`／`integration-wave`／`r-gate-step` **一次都没跑**）。
> 逐字块的取法：§3–§6 的引文由脚本**从落盘文件里抽出来**（不是手抄），并在 §9 逐行 `grep -Fxq` 复核。

---

## §0 一句话结论（**结论在前**）

> 登记**全部落地**：新号 = **`D-G100`**（`SetWindowPos(SWP_NOSIZE|SWP_NOMOVE)` 无条件落一次 X 几何写；**已由车道 W114A 修**，**但它不修 `D-G98`**）；`D-G98` 条**追加**了两条"**被证伪**"＋新首选嫌疑＋功效教训＋一条判据级更正（**原文一字未动**，机械证 = `diff` **0 删 / 27 增**）；地图上 `TASK-0110` **`🔴 → 🟡`**（**未**转 ✅，缺哪一格逐字写明）＋ 新 `TASK-0111 [Next] 🔴` ＋ 新 `§15i`（`wc -l` **513 → 533**）。
> `DEFREG` **两遍都** `PASS declared=136 route_ids=136`／`DECLDRIFT=0`／`rc=0`（`declared 135 → 136`，**恰好 +1**）。
> 推送（**第九笔**）：`f6f1383d1067c703ea35211bb059ebe4117edfa4 → **cd90c018391e64d9cd067138d8374b319b7e05f4**`（`--symref` 仍 `feat-Linux`，push 后**重新 fetch ＋ `ls-remote` 交叉核**一致）；`BYTECHECK **ok=6 mismatch=0 nobody=0**`。
> ⚠️ 两条**如实**记录：① `fp_inputs` **现值 = `72c5f2263f62a83d…` ≠ `#51`** 的值（**归因到 W114A 的 2 件 native 源 ＋ W113A 的 4 件，本件编辑的 4 件命中 0**，见 §8）；② **新发现（只报不改）**：W113A 改的那 4 件（`check-applocal-sync.sh`／`frame-presence-check.sh`／`pipefail-sigpipe-check.sh`／`integration-wave.sh`）**在 fork `HEAD` 里仍是改前内容 ⇒ 尚未推**；那 4 件是**产品/门禁件**，**本件不代它推**（裁定权在主控）。

---

## §1 起点现场（**现场现算**，非手抄）

| 量 | 值 | 来源 |
|---|---|---|
| 冻结基线 | `#51`（`38e67e834430d75c`） | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 现场 `sha256sum` |
| 末号（新增编号的起点） | **`D-G99`**（`KNOWN-DEFECTS.md` 末条；全文 `grep -oh 'D-G[0-9]*'` 取 max = `99`） | 现场 |
| `W115A` 报告 | **不存在**（`ls` `rc=2`）⇒ 涉 `W115A` 的一切写法**只许**"待 W115A" | 现场 |
| `KNOWN-DEFECTS.md` 开工 | `4a69e48dfe948306`（1,563 KB 级；`wc -l` **2648**） | 现场 |
| `docs/ROUTES.md` 开工 | `0ea763147cd0103a`（`wc -l` **513**） | 现场 |
| `build/MilBridge/tools/defect-registry-declared.tsv` 开工 | `53602b0fc8dd9079`（`135` 条 `ID` 行） | 现场 |
| 禁改件开工（**逐件核，收工复核**） | `docs/CURRENT-STATE.md` = `b7b2d513cfdab2eb`｜`build/MilBridge/known-red.json` = `089b7324ba12e022`｜`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = `38e67e834430d75c`｜`handoff.md` = `e4dc264200b421d0` | 现场 |
| 推前 head | `f6f1383d1067c703ea35211bb059ebe4117edfa4`（本地 `rev-parse HEAD` 与 `ls-remote origin feat-Linux` **两处逐字符相同**） | 现场 |
| 产品位移（本波前半段，主控已复核；本件**只引用**） | `win32shim` = `bd037229be8db4f6`（导出 **547** 不变）｜源 `win32_core.c` = `3117923a7c899e05`／`win32_x11.c` = `11142fbef049eb66` | 现场 `sha256sum` 复核 |
| ⚠️ 判据/取证件里的**一处行号口径差异**（如实记） | 主控转来的"同族并案位 `win32_x11.c:1435-1437`"与 `W114A` §4 记的 `:1435-1441` **指同一处**；本件用 `git show HEAD:<path>` 现算复核 ⇒ 那段 `push(t, h, WM_SIZE, …)` 就在 **`:1436-1437`** 两行上 | 现场复核 |

---

## §2 判据（**先写**；逐字见 `~/w116a/criteria.md`）

| 格 | 判据 | 实测 |
|---|---|---|
| `C1` | 新号 = `D-G100`，条内含判定点（文件:行）／对照（`P2` 那拍**有**守卫）／上游调用者／成对读数／"**不修 `D-G98`**"那句／同族并案位按 `W114A` 写实 | **全中**（§3） |
| `C2` | `D-G98` 追加 5 条 bullet 逐条在场，**旧文一字未动** | **全中**；`diff` **0 删 / 27 增**（§4） |
| `C3` | 新 `TASK-0111 [Next] 🔴` 写成"**待 W115A**"，**不许**替它下结论 | **全中**（§5） |
| `C4` | `TASK-0110` 状态位 `🔴 → 🟡`（**不是 ✅**）＋ 收口行写明"缺哪一格" | **全中**；那一行的**逐字节差异只有 emoji**（§5.1） |
| `C5` | `--emit` 后 `DEFREG=PASS declared=136 route_ids=136`／`DECLDRIFT=0`／`rc=0`，**两遍一致**；`CS`/`HO`/`AB` 锚点逐位未动 | **全中**（§6） |
| `C6` | 逐径 `git add`（禁 `-A`／`--force`）＋ 显式 refspec fetch ＋ push 后**重新 fetch ＋ `ls-remote origin HEAD` 交叉核** ＋ `--symref` ＋ 逐件字节核对 | **全中**（§7） |
| `C7` | `fp_inputs` 影响给**机械证**：本件 4 件命中 0；位移归因到 W114A／W113A | **全中**（§8） |
| `C8` | 口径：`NOINFO` 不算绿也不算红；不手抄哈希；改别人报告只许追加 | 遵守（§9） |

**先写的预测 vs 实测**：`P1`（`declared 135 → 136`，**恰好 +1**）**命中**｜`P2`（`DECLDRIFT` 保持 0）**命中**｜`P3`（`KNOWN-DEFECTS` 只有插入；`ROUTES` 恰好 1 行是"改"）**命中**（`ROUTES` 的**唯一**删除行就是 `TASK-0110` 那行的状态位）｜`P4`（三件禁改件 sha16 开工=收工）**命中**｜`P5`（不跑任何构建/门禁）**命中**。

---

## §3 新号 `D-G100`（**逐字**；已入册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 文件尾）

```markdown
### `D-G100`（**产品缺陷 · Win32 语义**）：`SetWindowPos(SWP_NOSIZE|SWP_NOMOVE)` 那一次"**本应无副作用**"的调用被落成**真实的 X 几何写**（写的是**窗口表缓存**里的矩形）
- **判定点（文件:行；两个状态的源码本件都现场复核过，**不许手抄**）**：
  - **修前源**（`src/WpfGfx.Linux.Native/src/win32_core.c` = **`e0cbc965772d06c1`**，= fork `HEAD` 版，本件用 `git show HEAD:<path>` 现算复核）：`SetWindowPos`（定义在 `:1154`）里
    - `:1184-1189` —— `nx/ny` 在 `SWP_NOMOVE` 时取 `win->x`／`win->y`、`nw/nh` 在 `SWP_NOSIZE` 时取 `win->width`／`win->height`：**四个值全部取自窗口表缓存**（**不是**调用参数）；
    - `:1207` —— 把同一组值**原样写回** `win->x/y/width/height`（这两个位下是**恒等赋值**）；
    - **`:1210`** —— 紧接着**无条件** `wpf_x11_move_resize(hwnd, nx, ny, nw, nh);` ⇒ 一次"本应无副作用"的调用被落成一次**真实 X 几何写**（`wpf_x11_move_resize` = `XMoveResizeWindow` ＋ `XFlush`，`win32_x11.c:481-483` ⇒ 请求**立即上线路**），写出的内容是**缓存里的矩形**。
  - **对照（同一个函数里就有正确写法，对照鲜明）**：紧邻的 `P2` 那一拍（修前 `:1214-1215`；盘上修后态 `:1234`，= `1214+20`，与 `F1` 的 `-1/+21` 相符，本件现场复核）是 `if (!(flags & SWP_NOSIZE) && (nw != old_w || nh != old_h)) wpf_hints_publish(hwnd, "after-SetWindowPos");` —— **有** `!(flags & SWP_NOSIZE)` 守卫；`WM_SIZE`／`WM_MOVE` 的派发（盘上修后态 `:1240`／`:1242`）也各带 `!(flags & SWP_NOSIZE)`／`!(flags & SWP_NOMOVE)` 守卫 ⇒ **同一条路径上只有这一处 X 写没有守卫**。
- **上游调用者是"几何意图为零"的声明（本仓已登记，`win32_core.c:544-548`）**：`WindowChromeWorker._ApplyNewCustomChrome()` 的 `SetWindowPos(…, _SwpFlags)`，`_SwpFlags = FRAMECHANGED|NOSIZE|NOMOVE|NOZORDER|NOOWNERZORDER|NOACTIVATE`（`upstream/wpf/…/WindowChromeWorker.cs:28/246`）；另一条同标志族 = `HwndStyleManager.Flush()`（`Window.cs:6845-6867`，实测标志 `0x37`）。⇒ **Win32 语义下这两次调用什么都不改**，本 shim 却把它们落成真实的几何写 —— **这就是缺陷**。
- ✅ **已修（车道 W114A，波 `#52`；本件 W116A **只登记、未改任何产品件**；本段**不覆盖**上面的判词）** —— 修法（盘上修后态 `:1229-1230`）：
  ```c
  if (!((flags & SWP_NOSIZE) && (flags & SWP_NOMOVE)))
      wpf_x11_move_resize(hwnd, nx, ny, nw, nh);
  ```
  - **成对读数（承重的**确定性**判据，逐腿 100% 成立）**：来自 `SetWindowPos` 帧的 X 几何写 **修前 6 条／38 腿（38/38 腿）→ 修后 1 条／16 腿（16/16 腿）**；消失的正是 **5 条** `SWP_NOSIZE|SWP_NOMOVE` 的写（`a=567`×4 ＋ `a=55`×1），保留的那 1 条是 `a=0x14`（**真的带尺寸**的启动调用）。
  - **只挡 X 写、不挡语义**：`[SHOW_DIAG]` 逐趟 **9 行**（`a=20`×1、`a=567`×4、`a=55`×1、`ShowWindow`×3）修前修后**逐字相同**。
  - **零回归**：`D-G83` 四格全绿（`667 by 500`／`521 by 417`／未声明**缺席**／`reg58` 出现 **0** 次）＋ `R-GATE=PASS crit=13/13` ＋ 权威件导出数 **547 不变**；**反极性源级＋件级双向闭合**（源逐字节复原 ⇒ 件逐位回 `8392fc09564779a1`、写条数回 6；重放补丁 ⇒ 件逐位回 `bd037229be8db4f6`）。
  - **世代位** = `win32shim 8392fc09564779a1 → bd037229be8db4f6`（源 `win32_core.c` = `3117923a7c899e05`／`win32_x11.c` = `11142fbef049eb66`，本件现场现算）。
- ⚠️ **它不修 `D-G98`（必读，防误引）**：本条的修法**只**干掉"多余几何写"，而 `D-G98`（退出最大化后几何还原残留）在**修后件上照样红** —— 修前 17 腿 1 红（5.9%）→ 修后 16 腿 1 红（6.2%）、Fisher 双尾 `p = 1.00`；且红腿 `W114A-F-07` **全趟只有 1 条** `XMoveResizeWindow`（启动那次）**照样被打回** ⇒ **本条与 `D-G98` 是两件事**（`D-G98` 条已同趟追加两条证伪 bullet）。**不许**把本条读成"`D-G98` 的一部分被修好了"。
- **同族并案位（按 `W114A` 报告写实，本件**不替它下结论**）**：`src/WpfGfx.Linux.Native/src/win32_x11.c` 的 `case PropertyNotify` 支用 `wpf_x11_sync_window_state` 交回的**陈旧** `w->width/height` 发 `WM_SIZE`（**修前源 = `6477af56fdcfdf20`**，本件用 `git show HEAD:<path>` 现算复核：`push(t, h, WM_SIZE, …)` 就在 **`:1436-1437`**，即 `W114A` §4 记的 `:1435-1441` 区间内、主控转来的写法 `:1435-1437` 指同一处）；`W114A` 的 `F2` 已**一并**改成**现场几何**（`wpf_x11_query_geometry`，取不到则**回落**采纳值、不拿 0 当"好读数"）⇒ 即**一并修了**；其**独立射程**记 `NOINFO`（`W114A` §8 第 2 条：`F1`＋`F2` 一起落地、未单跑 `F2`-only 臂 ⇒ 拆分不改结论）。
- **处置边界**：本条**已修**（修法出自**同波**的车道 W114A，由本件登记；修前/修后源与件 sha16 三样齐）；判词里"**Win32 语义**"那一层**不依赖任何竞态** ⇒ **每腿可复现**；**残留 = `D-G98` 本体（仍红，见上）**。
```

---

## §4 `D-G98` 追加 bullet（**逐字**；旧文**一字未动**，只追加）

```markdown
- ✅ **追加（车道 W116A，2026-09-22；本件**只登记、未改任何产品件**；上面判词**一字未动**）—— 两条独立读数把"**那次多余几何写是 `D-G98` 的成因**"**证伪**（出处 = 车道 W114A 报告 `build/MilBridge/W114A-report.md`，改后口径 `grep -v '^<!-- SHA16'` = `253b935c5415c841`；`W112A` §6.1／§6.5 的**最后一跳就此作废**，**不许**再被当结论引用）：
  - **① 证伪（决定性；`W114A` §5.2／§5.3）**：把那次写**彻底删掉**之后那族**照样红** —— 修前 17 腿 1 红（5.9%）→ 修后 16 腿 1 红（6.2%），Fisher 双尾 `p = 1.00`；**决定性命中** = 红腿 `W114A-F-07`（`SHIM=bd037229be8db4f6`）**全趟只有 1 条 `XMoveResizeWindow`**（`(240,212,800x600)`，即**启动那次真带尺寸的** `a=0x14`），窗口**照样**被打回 `1280x1024@+0+0`（`AFTER_R2 … r_ok=0`／`AFTER_R2_SETTLED … r_ok2=0 frame=0x200854 fgeom=1280x1024@+0+0`）⇒ 那次写**连必要条件都不是**，它是"**被打回**"的**后果/读数**。
  - **② 证伪（相关口径；`W114A` §5.3 第 1 条 ＋ 其判据 `C5`）**：`W112A` §5.5 那条相关系数（"**写＝最大化矩形 ⇒ 红 1/1**；**写＝基准矩形 ⇒ 绿 0/14**"，Fisher 双尾 `p = 0.067`）**是混淆的** —— 两种竞态走向在 tracer 上都表现为 `(0,0,1280x1024)`，且"被打回"的通告在行序上**早于**那次写 ⇒ **不许当证据引用**（只能作旁证，而旁证也已被 ① 取代）。
- 🆕 **新首选嫌疑（待验，属 `NOINFO`；本件写成时正由车道 W115A 做纯 X 高功效探针）**：红绿两态在 **X 事件层（`watch.txt`）与 shim 诊断层（`WINSTATE_DIAG`）逐字同形**（红腿只多末尾那一对 `ConfigureNotify 1280x1024@+0+0`，`SUB=③-ii`）⇒ **差别只在时序**；而唯一在"被打回"之前**必发**、且纯 X 装置 `xmimic` **不会发**的**非几何请求** = 还原那一拍 `SWP_FRAMECHANGED`（`win32_core.c` 修前 `:1167-1178`，本件现场复核）顺手重写的 **`_MOTIF_WM_HINTS`**（`wpf_x11_set_decorations`：**值"幂等"、X 流量不幂等**）⇒ 首选嫌疑 = **这次属性重写照 WM 的 unmaximize 序列**。⚠️ **本件不替 W115A 下结论**：`build/MilBridge/W115A-report.md` 此刻**不存在**（现场 `ls` `rc=2`）⇒ "必要性"**待 W115A**（每臂 **≥200 趟**）。**已排除**（`W114A` §8 第 1 条）：几何写族（`XMoveResizeWindow`／`XMoveWindow`／`XResizeWindow`／`XConfigureWindow` 在 `F1` 之后**一条都没有**，而红腿照样红）｜`xmimic` 纯 X 单客户端 add/remove `_NET_WM_STATE` **0/40 红**、正对照 4/4 红｜`maximum size` 提示 40＋16 趟**全程缺席**。
- 📌 **功效教训（与 `D-G99` 交叉引用；口径句）**：**6% 红率下 16 腿判不出**（修前 `1/17` vs 修后 `1/16` ⇒ Fisher 双尾 `p = 1.00`）⇒ 本族（**间歇、低红率**）的成对读数**至少 ≥40 腿/臂**（`0/40` 的 95% 单侧上界才压到 `7.2%`，低于修前点估计）。三次实际红率与趟数并列（**逐条现场复核自各自报告**）：`W105A` 的 `R2` 腿 **4/30**（两臂各 26 腿里 `R2` 腿各 15 ⇒ A 臂 `3/15`＋B 臂 `1/15`）｜`W112A` 修前红率 **`2/16 = 12.5%`**（其预登记 §5 自记）｜`W114A` 修前 **`1/17 = 5.9%`** → 修后 **`1/16 = 6.2%`**。⚠️ **承重判据不许只靠红率**：`W114A` 的承重格是**确定性**的 `C2`（"来自 `SetWindowPos` 帧的 X 几何写条数"，**每腿 100% 成立**：修前 **6**、38/38 腿 → 修后 **1**、16/16 腿）。
- 📌 **判据级更正（可并入 `D-G94` 的"口径"族，**不新开号**；本条只交叉引用）**：`W105A` §5 那句"**装置的判词就是落地计数**"**字面不成立** —— `m_ok`／`r_ok` 是**结果计数**（判"动作的结果对不对"），**不是**独立于判词的**落地证据**；真正的**独立落地证据**是 **`L`** = `[SHOW_DIAG] ShowWindow hwnd=… a=9`（`SW_RESTORE`）**＋** `[WINSTATE_DIAG] APPLY_WM_STATE … maximize=0`（我们真把 `_NET_WM_STATE` REMOVE 发出去了）。⇒ **新判据（三段）** = ① **三类判别式**（**①落地失败**／**②窗态未还原**／**③本族**：窗态已还原、而 client 与 frame 几何**双双卡住**）＋ ② `SUB=i/ii/iii` 细分（**`iii` = 还原后又被**打回**；本族 = `③-ii`**）＋ ③ **`L`** 与结果计数 `m_ok`／`r_ok`／`r_ok2` **并列报**。⚠️ 本条**只更正口径**：`W105A` 的判词与读数**一字未动**，其 `C1 = FAIL` 的处置**不变**（`D-G99` 那条"照字面判、不悄悄改判据"的纪律**照样成立**）。
```

**机械证（本件现场算）**：`diff <(git show HEAD:samples/WpfFeatureProbe/KNOWN-DEFECTS.md) <R 的那份>` ⇒ **删除行 0／插入行 27**；`wc -l` **2648 → 2675**；新号 `D-G100` 只出现 **1 次**（`2656` 行 = 新条标题），`D-G98` 条内新增 bullet 落在 `2640`–`2645`。

---

## §5 地图改动（**逐字**）＋ `wc -l` 复核

### 5.1 `TASK-0110` 收口行（状态位 `🔴 → 🟡`；**未**转 ✅）

**状态位那一行的逐字节证**：把改动前后那一行 `fold -w1` 后比 ⇒ **只有第 24/25 个字节不同**（`F0 9F 94 B4` = `🔴` → `F0 9F 9F A1` = `🟡`），**行锚定没吞行**。

```markdown
  - 🟡 **收口（车道 W116A，2026-09-22 第九笔；**只追加，上文一字未动**）—— 本行**未**转 ✅**：真因**部分定位／部分证伪**、缺陷**仍红**、新首选嫌疑**正在验** ⇒ 状态位 `🔴 → 🟡`。逐条：
    - **① 定位到行（来源 = `W112A` §6.1，已独立立号 = `D-G100`）**：链条 = 还原那一拍的 `SetWindowPos(0x237 = NOSIZE|NOMOVE|NOZORDER|NOACTIVATE|FRAMECHANGED|NOOWNERZORDER)` 把**窗口表缓存**值**无条件**落成一次 X 几何写（修前源 `win32_core.c:1210`，本件用 `git show HEAD:<path>` 现场复核）。
    - **② 部分证伪（来源 = `W114A` §5.2／§5.3；两条独立读数）**：把那次写**彻底删掉**之后那族**照样红** —— 承重的**确定性**判据（来自 `SetWindowPos` 帧的 X 几何写条数）**6 → 1**（38/38 腿 → 16/16 腿，**命中**），可红率**无位移**（修前 17 腿 1 红 5.9% → 修后 16 腿 1 红 6.2%，Fisher 双尾 `p = 1.00`）；且红腿 `W114A-F-07` **全趟只有 1 条** `XMoveResizeWindow`（启动那次真带尺寸的）**照样被打回** ⇒ 那次写是**后果/读数**、**连必要条件都不是**。**`W112A` §6.1／§6.5 的最后一跳就此作废**（`D-G98` 条已同趟追加两条证伪 bullet）。
    - **③ 新首选嫌疑（属 `NOINFO`；**正在验**）**：红绿两态在 X 事件层与 shim 诊断层**逐字同形**、差别**只在时序**；唯一在"被打回"之前**必发**、且纯 X 装置 `xmimic` **不会发**的非几何请求 = 还原那一拍 `SWP_FRAMECHANGED` 顺手重写的 **`_MOTIF_WM_HINTS`**（值"幂等"、**X 流量不幂等**）⇒ **正在由车道 W115A 做纯 X 高功效探针（每臂 ≥200 趟）钉"必要性"**；本行进 `TASK-0111`。
    - **④ 缺哪一格（本行不转 ✅ 的机械理由）**：缺"**被打回的那条客户端请求到底是哪一条**"（`D-G98` 的 `NOINFO` 第 1 条，**本件写成时仍无答案**）＋ 缺"**≥40 腿/臂**的成对读数"（6% 红率下 16 腿判不出，`D-G99` 的口径） —— **两格都还没有**。
    - **⑤ 世代位（波 `#52` 前半段）**：`win32shim 8392fc09564779a1 → bd037229be8db4f6`（`F1`＋`F2`，**独立卫生修**，**不修 `D-G98`**；导出仍 **547**）；**零回归** = `D-G83` 四格全绿 ＋ `R-GATE=PASS crit=13/13`；**反极性源级＋件级双向闭合**（复原 ⇒ `8392fc09564779a1`；重放补丁 ⇒ `bd037229be8db4f6`）。出处 = `build/MilBridge/W114A-report.md`（口径 `grep -v '^<!-- SHA16'` = `253b935c5415c841`）／`docs/WAVE52-PREREGISTRATION.md`（`834e370053f7ef2b`）／登记件 = `build/MilBridge/W116A-report.md`。
```

### 5.2 新 `TASK-0111 [Next] 🔴`

```markdown
- `TASK-0111` [Next] 🔴 **`_MOTIF_WM_HINTS` 那一跳的落地**（`D-G98` 的**首选嫌疑**；来源 = `W114A` §8 第 1 条 ＋ §8b 的 `N1`）：
  - **修法方向**：让 `wpf_x11_set_decorations`（`src/WpfGfx.Linux.Native/src/win32_x11.c`）**值没变就不写** `_MOTIF_WM_HINTS`（现状 = 运行期每个带 `SWP_FRAMECHANGED` 的 `SetWindowPos` **都会重写一次**：`win32_core.c` 盘上修后态 `:1167-1178` ⇒ 值"幂等"、**X 流量不幂等**）。
  - **⚠️ 先决条件（逐字）**：**待 W115A** —— 本件写成时 `build/MilBridge/W115A-report.md` **不存在**（现场 `ls` `rc=2`）；它正在做**纯 X 高功效探针**（每臂 **≥200 趟**）钉"**这次属性重写是不是"被打回"的必要条件**"。**本行不替它下结论**。
  - **分支 A（W115A 判"必要性成立"）**：落地"**值没变就不写该属性**"＋ **反极性**（拆掉 ⇒ 必须回到同形）＋ **零回归**（`D-G83` 四格／`R-GATE crit=13/13`／权威件导出数不变）＋ **成对读数 ≥40 腿/臂**（6% 红率下 16 腿判不出，见 `D-G99`）。
  - **分支 B（W115A 判"不成立"）**：**撤号**，或按现场读数改写为"**剩余候选**"（**不许**把红写成绿、**不许**为了保号而放宽判据）。
```

### 5.3 新 `§15i`（`#52` 前半段／第九笔）

```markdown
## §15i `#52` 前半段（第九笔）：新登记 `D-G100`（**已修**）＋ `D-G98` 两条"**被证伪**" ＋ `TASK-0111` ＋ `win32shim` 位移（**一行一条**；2026-09-22 车道 W116A 补）

- 🆕 **新登记 `D-G100`（**产品缺陷 · Win32 语义**；**已修**）**：`SetWindowPos(SWP_NOSIZE|SWP_NOMOVE)` 那一次"**本应无副作用**"的调用被落成**真实的 X 几何写**（写的是**窗口表缓存**里的矩形）。**判定点（文件:行）** = 修前源 `src/WpfGfx.Linux.Native/src/win32_core.c`（**`e0cbc965772d06c1`**，本件用 `git show HEAD:<path>` 现算复核）：`:1184-1189`（`nx/ny/nw/nh` **全取自缓存**）→ `:1207`（原样写回 `win->…`）→ **`:1210` 无条件** `wpf_x11_move_resize(...)`；**对照** = 紧邻的 `P2` 那拍（修前 `:1214-1215`／盘上修后态 `:1234`，= `1214+20`，与 `-1/+21` 相符）**有** `!(flags & SWP_NOSIZE)` 守卫 ⇒ **同一条路径上只有这一处 X 写没有守卫**。**修法**（车道 **W114A**，波 `#52`）= `if (!((flags & SWP_NOSIZE) && (flags & SWP_NOMOVE))) wpf_x11_move_resize(...)`。**成对读数（确定性、逐腿 100%）** = 来自 `SetWindowPos` 帧的 X 几何写 **6 条/38 腿 → 1 条/16 腿**（消失的正是 5 条 `a=567`×4＋`a=55`×1）；`[SHOW_DIAG]` 逐趟 9 行修前修后**逐字相同**；**零回归** = `D-G83` 四格全绿 ＋ `R-GATE crit=13/13` ＋ 导出 **547** 不变；**反极性源级＋件级双向闭合**。⚠️ **它不修 `D-G98`**（修后那族照样红，Fisher 双尾 `p = 1.00`，且红腿全趟只剩 1 条启动期 `XMoveResizeWindow` 仍被打回）—— **不许**读成"`D-G98` 的一部分被修好了"。
- 🆕 **`D-G98` 追加两条"**被证伪**"（判词原文一字未动，只追加 dated bullet）**：① **"那次多余几何写是 `D-G98` 的成因"不成立**（删掉之后照样红 ⇒ **连必要条件都不是**，它是**后果/读数**）；② **`W112A` §5.5 那条相关系数（`p=0.067`）是混淆的**、**不许**当证据引用。同趟另加：**新首选嫌疑**（还原那拍 `SWP_FRAMECHANGED` 顺手重写的 `_MOTIF_WM_HINTS`：值"幂等"、**X 流量不幂等**；**待 W115A 验**）＋ **功效教训**（6% 红率下 **≥40 腿/臂**；`R2 4/30`／`2/16`／`1/17→1/16` 三次并列）＋ **一条判据级更正**（`r_ok` 是**结果计数**、**独立落地证据是 `L`**；新判据 = 三类判别式 ＋ `SUB=i/ii/iii` ＋ `L`，**可并入 `D-G94`、不新号**）。
- 🆕 **新任务 `TASK-0111` [Next] 🔴**：**`_MOTIF_WM_HINTS` 那一跳的落地** —— **先决条件逐字 = 待 W115A**（纯 X 高功效探针、每臂 **≥200 趟**，钉"这次属性重写是不是**被打回**的必要条件"；本件写成时 `W115A` 报告**不存在**）；**分支 A（必要性成立）= "值没变就不写该属性" ＋ 反极性 ＋ 零回归 ＋ ≥40 腿/臂成对**；**分支 B（不成立）= 撤号或改写为"剩余候选"**。
- ✅ **地图更新（本件只追加；`TASK-0110` 行**未**转 ✅）**：`TASK-0110` 状态位 **`🔴 → 🟡`**（真因**部分定位／部分证伪**、缺陷**仍红**、新嫌疑**正在验**）＋ 收口行；**"缺哪一格"逐字** = ①"**被打回的那条客户端请求到底是哪一条**"**仍无答案**（`D-G98` 的 `NOINFO` 第 1 条）②"**≥40 腿/臂**的成对读数"**未取**（`D-G99` 的口径）。
- 🔁 **`#52` 前半段的产品位移（口径句；后续引用者按这句判"要不要重冻"）**：**只有 `win32shim` 一位** —— `8392fc09564779a1 → **bd037229be8db4f6**`（源 `win32_core.c` = `e0cbc965772d06c1 → **3117923a7c899e05**`／`win32_x11.c` = `6477af56fdcfdf20 → **11142fbef049eb66**`；导出仍 **547**），性质 = **独立卫生修**（对齐 Win32 语义）、**不修 `D-G98`**；**其余八位与 `#51` 逐位相同** ⇒ **收尾链必须重钉世代（`repin-generation.py --why`）＋ 重冻 `#52`**。
- ⚠️ **`inputs_fp` 现值与位移归因（**本件现场机械证**）**：⚠️ **现在必然 ≠ `#51` 冻结时的值**（`src/WpfGfx.Linux.Native/**/*.c|*.h` **在 `close-wave.sh` 的 `fp_inputs()` 覆盖面内**）。本件现场**真调用** = **`72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015`**；把覆盖面里"与 fork `HEAD` 不同"的件**逐件换成 `HEAD` 版**再算（**只换内容、不换路径**，机械证）⇒ 先只换两件 native 源 = **`d67880cbb8487cfd…`（＝ `§15h` 记的 W113A 后值，逐字符相同）**，再连 W113A 那 4 件一起换 = **`58a6c0945b7d5358…`（＝ `§15g` 记的 `#51` 值，逐字符相同）** ⇒ **位移 100% 归因到 W113A 的 4 件（尚未推）＋ W114A 的 2 件 native 源**；而**本件编辑的 4 件**（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/W116A-report.md`）**在覆盖面里命中 0**（现场 `grep` 逐个 = 0）。⚠️ **另发现（只报不改）**：W113A 改的那 4 件**在 fork 克隆 `HEAD` 里仍是改前内容** ⇒ **尚未推**；本件按任务书只推本笔列明的件，**不代 W113A 补推**（那 4 件是产品/门禁件，**裁定权在主控**）。
```

**`wc -l` 复核**：`docs/ROUTES.md` **513 → 533**（净 +20）；与 fork `HEAD` 的 `diff` = **删除 1 行**（就是 §5.1 那一行）＋ **插入 21 行**。

---

## §6 `DEFREG` —— 两条机读行（**两遍**，现场跑）

```text
$ bash build/MilBridge/tools/defect-registry-check.sh        # 第 1 遍
DEFREG_DECL=n=136 route_ids=136 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=f2c1d0d787db80f2 CS=b7b2d513cfdab2eb HO=e4dc264200b421d0 AB=38e67e834430d75c
DEFREG_EXTRA=KRJ=089b7324ba12e022 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=136 route_ids=136（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
rc=0
```

**第 2 遍**（`> /tmp/w116a-defreg2.txt`）与上表**逐行相同**，`rc=0`。
**声明表**：`defect-registry-check.sh --emit` 重生成 ⇒ `53602b0fc8dd9079 → **934a29ed9ab399ab**`；新增行逐字 = `ID	D-G100	req=KD	present=KD`；`ID` 行数 **135 → 136**。
**锚点三件核**（本件**只**改了 `KD`）：`KD 4a69e48dfe948306 → f2c1d0d787db80f2`（= 我改后的 `KNOWN-DEFECTS.md` 现场值）｜`CS` **`b7b2d513cfdab2eb` 未动**｜`HO` **`e4dc264200b421d0` 未动**｜`AB` **`38e67e834430d75c` 未动** ⇒ `DECLDRIFT` 由 0 保持 0。
⚠️ **引号级核对**：`D-G100` 在 `--emit` **之前**就已经写进缺陷册（`req=KD`），**不是**"先引用后补登记"⇒ **没有**幻影声明行（`declared` 恰好 +1，不是 +2）。

---

## §7 推送（**第九笔**）：前后 head ＋ `BYTECHECK`

**做法（两笔提交 = 同一"笔"）**：本仓一个提交**装不进自己的哈希** ⇒ 按本仓既有惯例（`1e06b58`／`52c6edd`）：**件**先提交（= `A`）并推送，**本报告**随后作为第二笔提交（= `B`）推送；报告里记的"推送后 head" = **`A`**（本笔承载**全部登记件**的那个提交）。

| 步 | 命令（现场逐条跑） | 读数 |
|---|---|---|
| ① 推前双读 | `git rev-parse HEAD` ＋ `git ls-remote origin feat-Linux` | **两处都 = `f6f1383d1067c703ea35211bb059ebe4117edfa4`** |
| ② 逐径 stage | `cp -p` 6 件从 `R` 进克隆 ⇒ `git add -- <path>` ×6（**无 `-A`／`--force`**） | `git status --porcelain` = **恰好 6 行**（3 `M` ＋ 3 `A`） |
| ③ fetch（**显式 refspec**） | `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux` | `rc=0`；`rev-list --left-right --count HEAD...origin/feat-Linux` = **`0 0`**（无落后、无分叉） |
| ④ commit `A` | `git commit -F -`（消息见下） | **`cd90c018391e64d9cd067138d8374b319b7e05f4`** |
| ⑤ push | `git push origin feat-Linux` | `f6f1383..cd90c01  feat-Linux -> feat-Linux`，`rc=0` |
| ⑥ push **后重新 fetch** | `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux` | `rc=0` |
| ⑦ 交叉核 | `git ls-remote origin HEAD` ＋ `ls-remote origin feat-Linux` ＋ `ls-remote --symref origin HEAD` | **`cd90c018391e64d9cd067138d8374b319b7e05f4`**（两处相同）；`--symref` = **`ref: refs/heads/feat-Linux`**（仍是它）；`rev-list --left-right --count` = **`0 0`** |

⇒ **推送前 head = `f6f1383d1067c703ea35211bb059ebe4117edfa4`｜推送后 head = `cd90c018391e64d9cd067138d8374b319b7e05f4`**。

**`BYTECHECK`（逐件字节核对 = 推上去的 blob vs `R` 里那份，全 64 位比对）**：**`ok=6 mismatch=0 nobody=0`**

| 件 | sha16（推上去的 blob == `R` 那份） |
|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `f2c1d0d787db80f2` |
| `docs/ROUTES.md` | `9fd75833eeb33224` |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `934a29ed9ab399ab` |
| `build/MilBridge/W112A-report.md`（**补推**；此前不在 `HEAD`） | `cb1b99b4f1aecb45` |
| `build/MilBridge/W114A-report.md`（**补推**；此前不在 `HEAD`） | `3728cea78d617103` |
| `docs/WAVE52-PREREGISTRATION.md`（**补推**；此前不在 `HEAD`） | `834e370053f7ef2b` |

- `W115A-report.md`：**不存在**（现场 `ls` `rc=2`）⇒ **不推**（`nobody` 里没有它，因为本笔件清单里也没有它）。
- `W105A-report.md`：已在 `HEAD` 里、与 `R` **逐字节相同** ⇒ **不在本笔**。

**提交消息（逐字）**：

```text
docs(#52): 波#52 前半段登记 —— 新增 D-G100（SetWindowPos(NOSIZE|NOMOVE) 无条件落一次 X 几何写；W114A 已修：6→1 条/38→16 腿，源级+件级反极性双向闭合，不修 D-G98）＋ D-G98 追加两条"被证伪"bullet＋新首选嫌疑（_MOTIF_WM_HINTS 那一跳，待 W115A）＋功效教训（≥40 腿/臂）＋一条判据级更正（r_ok 是结果计数、独立落地证据是 L）；ROUTES §15i（#52 位移=win32shim 一位 ⇒ 重钉世代+重冻；inputs_fp 现值 72c5f226…、位移归因到 W113A 的 4 件+W114A 的 2 件）＋ TASK-0110 🔴→🟡 收口（缺哪一格逐字）＋新 TASK-0111；--emit 重生成声明表（declared 135→136、DECLDRIFT 0）；补推 W112A/W114A 报告与 WAVE52 预登记
```

**本笔的边界（如实写）**：本笔**只**推上表 6 件 ＋ 本报告；**没有**推任何 `src/**`／`build/shims/**`／applier／门禁件（**本件也没改它们**）。

---

## §8 `fp_inputs` 影响（**机械证**，不是"我猜"）

**结论：现值必然 ≠ `#51` 冻结时的值，而位移 100% 与本件无关。**

| 量 | 值（现场现算） |
|---|---|
| `fp_inputs()` **真调用**（从 `build/close-wave.sh` 抽出函数原样跑，零改写） | **`72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015`** |
| 覆盖面件数 | **149** |
| 覆盖面里**与 fork `HEAD` 不同**的件 | **6 件**：`win32_core.c`（`e0cbc965772d06c1→3117923a7c899e05`）／`win32_x11.c`（`6477af56fdcfdf20→11142fbef049eb66`）＝**W114A**；`check-applocal-sync.sh`／`frame-presence-check.sh`／`pipefail-sigpipe-check.sh`／`integration-wave.sh`＝**W113A**（`R` 侧是修后值） |
| **本件编辑的 4 件在覆盖面里命中** | **全 0**（`KNOWN-DEFECTS`／`ROUTES.md`／`defect-registry-declared`／`W116A` 逐词 `grep` = 0） |
| 归因（**只换内容、不换路径**地重算） | 把 2 件 native 源换回 `HEAD` 版 ⇒ **`d67880cbb8487cfd386bde0648e647624ffdf8d800a892297f93d03d6f9fefb0`**（**逐字符 = `§15h` 记的 W113A 后值**）；再连 W113A 那 4 件一起换 ⇒ **`58a6c0945b7d535830ce3e3e4f25752b68f3714d3f35f540253eca6e69b3dd36`**（**逐字符 = `§15g` 记的 `#51` 值**） |

⇒ **① 从 `#51` 值到现值的一次位移可分解为"W113A 的 4 件"＋"W114A 的 2 件"，两段都被上述重算复现到逐字符**；**② 本件（纯文本登记）对 `fp_inputs` 的贡献 = 0**；**③ 因此该位移不许记到本件头上**，但**收尾链必须按"输入变了"处理**（重钉世代 ＋ 重冻）—— 那本来就是 W114A 的产品改动要求的。
⚠️ **附带发现（只报不改，见 §0）**：W113A 那 4 件**尚未推**（在 fork `HEAD` 里仍是改前内容）⇒ 若主控要 fork 与 `R` 对齐，需要**单独一笔**推它们；本件**不越权代推**。

---

## §9 纪律核对 ＋ `NOINFO`／未做

**纪律核对（逐条）**：
1. **判据先写**：`~/w116a/criteria.md` 写成于 **23:24**，**早于**任何编辑（首件编辑 23:25 之后）⇒ 成立。
2. **引文逐行核对**：§3–§6 的逐字块由脚本从落盘文件抽出，并对每一行 `grep -Fxq -e "$line"` 核过（见 §9 末的核对行）⇒ **零手抄**。
3. **不许手抄哈希**：本报告里**每一个** sha16 都是现场 `sha256sum`／`git show | sha256sum` 算的。
4. **改别人报告只许追加**：`W112A-report.md`／`W114A-report.md` **本件一个字节都没写**（只 `cp -p` 进克隆推送，推上去的 blob 与 `R` 那份逐字节相同）；`D-G98`／`D-G99`／`D-G100` 判词旧文**一字未动**（机械证 = 0 删）。
5. **禁改件**：`docs/CURRENT-STATE.md`（含 `:9` 机器行）／`known-red.json`／`ACCEPTANCE-BASELINE.md`／`handoff.md`／`verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／`r-gate-step.sh`／任何 `src/**` 与 `build/shims/**`／applier —— **全部零写**（开工 sha16 见 §1，收工见 §9 末表）。
6. **零 `pkill -f`**、零 `dotnet`、零构建、零门禁、零应用、零槽。
7. 本件**没有**为了让某格变绿而放宽任何判据：`TASK-0110` **未**转 ✅、`D-G98` **仍红**、`W115A` 的结论**留白**（写成"待 W115A"）。

**`NOINFO`（既不算绿也不算红）**：
1. **`_MOTIF_WM_HINTS` 那次重写的"必要性"**：**`NOINFO`**（`W115A` 报告不存在 ⇒ 本件按现场读数**只登记为"首选嫌疑"**，**不许**当结论）。
2. **`D-G98` 的"被打回的那条客户端请求到底是哪一条"**：**`NOINFO`**（`W114A` §8 第 1 条，本件**只转述，不重取**）。
3. **`F2`（同族并案位）的独立射程**：**`NOINFO`**（`W114A` §8 第 2 条：未单跑 `F2`-only 臂）。
4. **`D-G100` 修法对"真实应用"的观感影响**：**`NOINFO`**（本件零应用、零腿；判词只建立在 `W114A` 的 `C2`（X 几何写条数）与零回归四格上）。
5. **W113A 那 4 件未推的处置**：**`NOINFO`**（**裁定权在主控**；本件只报不改、不代推）。
6. **本笔报告自身提交（`A` 之后那一笔）的 head**：**依构造**不可能写进它自己的内容 ⇒ 读数走 `git log --oneline cd90c01..HEAD`（本仓惯例，见 `1e06b58`／`52c6edd`）。

**未做（如实）**：`W115A` 的探针/腿（不在射程）；`D-G98` 的任何重取（本件零应用）；`W113A` 4 件的补推（越权）；`W116A` 的 `--selftest`（`defect-registry-check.sh` 有自测例，但本件**未跑**它——它不在任务书要求里，且本件不碰该脚本）。

**收工复核三件禁改件（与 §1 逐位比对）**：见下表（§9 末的现场输出）。

| 件 | 开工 sha16 | 收工 sha16 | 判 |
|---|---|---|---|
| `docs/CURRENT-STATE.md` | `b7b2d513cfdab2eb` | `b7b2d513cfdab2eb` | **未动** |
| `build/MilBridge/known-red.json` | `089b7324ba12e022` | `089b7324ba12e022` | **未动** |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `38e67e834430d75c` | `38e67e834430d75c` | **未动** |
| `handoff.md` | `e4dc264200b421d0` | `e4dc264200b421d0` | **未动** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `4a69e48dfe948306` | `f2c1d0d787db80f2` | **已改（本件声明写域内的 3 件之一）** |
| `docs/ROUTES.md` | `0ea763147cd0103a` | `9fd75833eeb33224` | **已改（本件声明写域内的 3 件之一）** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `53602b0fc8dd9079` | `934a29ed9ab399ab` | **已改（本件声明写域内的 3 件之一）** |

**逐行引文核对（机械跑，零手抄）**：把本报告 §3–§5 逐字块里的**每一行**拿去对 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`docs/ROUTES.md` **逐行集合比对**（脚本 `~/w116a/bin/verbatim-check.py`，现场输出逐字抄在下）⇒ **命中 37／失配 0**：

```text
§3 D-G100              行=12 命中=12 失配=0 []
§4 D-G98追加             行=6 命中=6 失配=0 []
§5.1 TASK-0110收口       行=6 命中=6 失配=0 []
§5.2 TASK-0111         行=5 命中=5 失配=0 []
§5.3 §15i              行=8 命中=8 失配=0 []
TOTAL 命中=37 失配=0
```

**⑦ 本报告自身（第二笔提交 `B`）的记账（如实写）**：本报告随**本笔的末位提交**推送；那个提交的 sha **装不进它自己的内容**（任何提交都装不下自己的哈希）⇒ 按本仓惯例（`1e06b58` 记 `084afe0..c4f142c`、`52c6edd` 是其后的回填）本报告**只记账到 `A`**；末位提交的 sha 与它的逐件字节核对读数**由车道在最终回复里给出**（现场命令 = `git log --oneline -1` ＋ `git show B:build/MilBridge/W116A-report.md | sha256sum` vs `R` 的那份）。

---

## §10 大白话小结（≤6 行）

1. 给"`SetWindowPos` 里那次多余几何写"**立了新号 `D-G100`**：它的三个判定点（`nx/ny/nw/nh` **全取自缓存** → 原样写回 → **无条件**落 X 写）与"旁边那拍 `P2` **反而有**守卫"的对照都写进去了；**W114A 已经把它修了**（每次还原少 5 条多余的 X 写，6 → 1 条，每条腿都成立）。
2. ⚠️ **但它不修 `D-G98`**：这条我也逐字写进册里了 —— 修完那族**照样红**（Fisher `p = 1.00`），**不许**把 `D-G100` 读成"`D-G98` 修了一半"。
3. `D-G98` 条**只追加、不改旧文**：把"那次多余几何写是成因"和"W112A 那个 `p=0.067` 相关系数"**两条都标成"被证伪"**，并把剩下的首选嫌疑（还原那一拍重写 `_MOTIF_WM_HINTS`）**挂到 W115A 名下待验**，没替它下结论。
4. 地图上 `TASK-0110` **没敢标 ✅**：改成 🟡，并写明**还缺哪两格**（"被打回的请求是哪一条"没答案 ＋ "≥40 腿/臂"的读数没取）；新开 `TASK-0111` 备着"值没变就不写 `_MOTIF_WM_HINTS`"这条修法。
5. 声明表 `--emit` 重生成后 **`DEFREG=PASS declared=136`**（135 + 1，没出幻影行）、`DECLDRIFT=0`，**两遍一致**。
6. 第九笔已推：head `f6f1383d… → cd90c018…`，`BYTECHECK ok=6 mismatch=0 nobody=0`；另外**发现** W113A 改的 4 件其实还没推（我只报，不代推）；`fp_inputs` 现值变了**跟本件无关**（机械证：本件 4 件在覆盖面里命中 0）。
<!-- SHA16 7f3f6c906ad77ce1 -->
