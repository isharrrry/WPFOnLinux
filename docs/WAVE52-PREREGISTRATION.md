# 波 `#52` —— 预登记（`TASK-0111`／`D-G98`：几何还原被自己的缓存写打回）

> 本文件是**落地前写死**的预登记（纪律：**判据先写、读数后取**；判据写定后不许"事后对齐"）。
> 建立者：车道 **W114A**（波 `#52` 第一条产品车道）。写成时刻早于本车道**任何产品改动**（见 `~/w114a/STATUS.md` 的追加行）。
> 判据全文（逐格、含反极性与 `NOINFO` 口径）：`~/w114a/criteria.md`（同刻写成，同 sha 口径）。
> 取证件（**只读复用**）：`build/MilBridge/W112A-report.md`（口径 `head -n -2` = `3e1223d42b8f23a4`）§5.4/§5.5/§6.1/§6.5
> ｜`~/w112a/criteria.md`（`d98380adfb2efce7`）｜`build/MilBridge/W105A-report.md`（`ae61f7f0dc5f25f5`）｜`build/MilBridge/W110A-report.md`（`d0fd37b8f74ac684`）。
> ⚠️ W112A 的 10 条 `NOINFO`（其报告 §6.4）与 `~/w112a` 的器材**不是**已知项，本件不得把它们当结论；只借用它们的**读数**。

---

## §0 起点现场（**现场现算**，非手抄）

| 量 | 值 | 来源 |
|---|---|---|
| 冻结基线 | `#51`（`38e67e834430d75c`） | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| 位 `win32shim`（权威） | `8392fc09564779a1` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 现场 `sha256sum` |
| 权威件导出数 | **547** | `nm -D --defined-only … \| wc -l` |
| 源 `win32_core.c` | `e0cbc965772d06c1` | 现场 |
| 源 `win32_x11.c` | `6477af56fdcfdf20` | 现场 |
| 源 `win32_internal.h` | `e4f2de8d038e4780` | 现场 |
| 诊断腿装置（**仓外只读**） | `~/w112a/bin/leg-diag.sh`（`061d0ec73c4b57cf`）＝ `~/w89a/bin/hc-arm-inner.sh`（`ca7ef5d23ab5a032`）＋ 5 处公告差异 | 现场 |
| 腿的件（W112A 那批，每趟 `probe.txt` 现印） | `SHIM=2a297d6fee8be389`（`~/w89a/app` 冻结副本）｜`BRIDGE=feef049e9d0e313a`｜`PC=56ee75ced8d6aece`｜`PF=2a5b7641f6fba0fb`｜`WB=2e4e46e539a72cd7` | W112A §5.1 |
| 观测器／归因仪器（**仓外只读**） | `~/w112a/bin/xeventwatch`｜`~/w112a/bin/libxgeomtrace.so`（`8f23232cb3dc53a8`，源 `~/w112a/src/xgeomtrace.c`） | 现场 |

## §1 缺陷陈述（W112A 已定位到行；本件**照 §6.5 修**）

**机制**（W112A §6.1，三条独立证据：`backtrace` 符号链／事件级观测器 `SUB=ii`／写的内容相关）：

```
应用点"还原" ⇒ ShowWindow(SW_RESTORE, a=9) ⇒ _NET_WM_STATE REMOVE 发出      ← 落地证据 L
同一拍的下一次 SetWindowPos(a=0x237 = NOSIZE|NOMOVE|NOZORDER|NOACTIVATE|FRAMECHANGED|NOOWNERZORDER)
   ⇒ shim 把 nx,ny,nw,nh **全部取自窗口表缓存**（win32_core.c:1184-1189）
   ⇒ 却**无条件**调 wpf_x11_move_resize(hwnd,nx,ny,nw,nh)（win32_core.c:1210）
   ⇒ XMoveResizeWindow（win32_x11.c:481）＝ 一次**本应无副作用**的调用被落成真实几何写
   ⇒ 该写是客户端 ConfigureRequest 且排在 REMOVE **之后**
   ⇒ WM 先完成 unmaximize（几何回基准），**再**顺从这条请求把窗口改回最大化矩形
   ⇒ 终态 = `_NET_WM_STATE_FOCUSED`（窗态已还原）＋ client 与 frame **双双卡在 `1280x1024@+0+0`** ＝ `D-G98`
```

**上游调用者的身份**（本仓已登记，`win32_core.c:544-548`）：`WindowChromeWorker._ApplyNewCustomChrome()`
的 `SetWindowPos(…, _SwpFlags)`，`_SwpFlags = FRAMECHANGED|NOSIZE|NOMOVE|NOZORDER|NOOWNERZORDER|NOACTIVATE`
（`upstream/wpf/…/WindowChromeWorker.cs:28/246`）＝**"我重算了窗框"的声明，几何意图为零**；
另一条同标志族的是 `HwndStyleManager.Flush()`（`Window.cs:6845-6867`，实测标志 `0x37`）。
⇒ Win32 语义下这两次调用**什么都不改**；本 shim 却把它们落成真实的几何写。**这就是缺陷**。

**间歇性**（W112A §6.1 第 5 条）＝**缓存值的竞态**：UI 线程上这次"无副作用的 `SetWindowPos`"
与 X 泵把 WM 的还原 `ConfigureNotify` 采纳进缓存（`win32_x11.c:1047-1059`）谁先到。
⇒ 缓存**仍是**最大化矩形那一瞬 ⇒ 写出的就是最大化矩形。

## §2 落地的改动（`F1` 主修 ＋ `F2` 并案；逐字见 `~/w114a/criteria.md` §3）

| 项 | 文件:行 | 内容 | 依据 |
|---|---|---|---|
| **`F1`**（主修） | `src/WpfGfx.Linux.Native/src/win32_core.c:1210` | `SWP_NOSIZE` **与** `SWP_NOMOVE` **同时**置位时**不再调** `wpf_x11_move_resize`（Win32 语义下这次调用不改几何；窗框/装饰的副作用已由本函数上半段的 `wpf_x11_set_decorations` 承担） | W112A §6.5 **首选** |
| **`F2`**（同族并案） | `src/WpfGfx.Linux.Native/src/win32_x11.c:1435-1441`（`PropertyNotify` 支） | 派发 `WM_SIZE` 的 `ww/hh` 从**陈旧窗口表缓存**（`wpf_x11_adopt_maximized` 返回的 `w->width/height`）改成**现场几何**（`wpf_x11_query_geometry`，与 `CONFIGURE` 支已经在用的 `ev.xconfigure` 同口径） | W112A §6.5 **次选** |

**不做的事**：`F1` **不**引入任何新的 X 往返、**不**新增导出、**不**改 `WM_GETMINMAXINFO`/`DefWindowProcW`
（`D-G83` 的语义一字不动）、**不**放宽任何判据、**不**动 PF/PC/桥。

## §3 判据（**先写死**；逐格见 `~/w114a/criteria.md`）

- **`C1`（主判据）**：修后 `D-G98` 那族在诊断腿上由 **红 2/16** 变 **红 0/N（N≥16）**；落地证据 `L`＝`N/N`、
  `m_ok=1`＝`N/N`（证明**不是**靠"点击没落地"变绿）；`SUB=ii` 消失（或**逐字写明**它变成了什么）。
- **`C2`（承重的**确定性**判据；本件对 W112A 判据的**加强**）**：逐腿用 `LD_PRELOAD` 归因，数
  **"来自 `SetWindowPos` 帧的 X 几何写"**条数。**修前每条 M2×R2 腿恒为 6（15/15 已见）**；
  **修后必须为 1**（只剩启动那次**真的带尺寸**的 `SetWindowPos(a=0x14, cx=800, cy=600)`）。
  ⇒ 这一格是**每腿 100% 复现**的成对读数，**不依赖竞态**（`C1` 的红率才是竞态相关的）。
- **`C3`（零回归）**：`D-G83` 四格仍 `VERDICT=PASS`；`R-GATE` 那格仍 `crit=13/13`；权威件导出数仍 **547**。
- **`C4`（反极性，必做）**：源**逐字节复原** ＋ 重编 ⇒ `win32shim` **逐位回 `8392fc09564779a1`**，
  且 `C2` 的条数**回 6**、`C1` 的族**红回来**（成对）。
- **`C5`（弱数据必须标弱）**：W112A 的"写＝最大化矩形 ⇒ 1/1 红；写＝基准 ⇒ 0/14 绿"是
  **Fisher 双尾 p=0.067**，只作**旁证** ⇒ 本件结论**不许**建立在这条上（承重的是 `C2`）。
- **`C6`（口径纪律）**：`NOINFO` 既不算绿也不算红；`rc=127/126` ＝ 从来没跑过；**不许**用日志体积当判别量；
  **不许**把 `timeout: …已核心转储` 那 43 B 当应用输出；每趟读数**必须绑 `SHIM=`**（现场印出的那份）。

## §4 先写的预测（**可被证伪**；偏离必须逐条入报告）

| # | 预测 | 证伪条件 |
|---|---|---|
| `P1` | `F1` 落地 ⇒ `C2` 每条腿的"`SetWindowPos` 帧 X 写"由 **6 → 1** | 仍是 6（守卫没生效）或 ≠1（误伤别的写路径） |
| `P2` | `F1` 落地 ⇒ `C1` 那族**红 0/N**、`SUB=ii` 不再出现 | 出现红 ⇒ 另有机制（必须归因，不许压绿） |
| `P3` | `F1` **不会**改坏最大化本身：`m_ok=1` 仍 `N/N`、`START_MAX=0` 仍 `N/N` | 最大化失败 ⇒ 守卫过宽 |
| `P4` | `F2` 单独落地**不改变** `C2` 的条数（它不动几何写路径） | 条数变了 ⇒ 我读错了 `F2` 的射程 |
| `P5` | `F1` 落地**不动**既有导出数（547）与九位里除 `win32shim` 外的八位 | 有任何一位动 ⇒ 写域越界 |
| `P6` | `F2` 落地**不引入**新的几何写（`C2` 仍 1） | 出现新的写 ⇒ `F2` 越界 |

## §5 样本量（**先算好**，不事后挑）

修前红率（W112A 装置）＝ **2/16 = 12.5%**。`0/N` 的 95% 单侧上界 ＝ `1-0.05^(1/N)`：
`N=16 → 17.3%`｜`N=24 → 11.7%`｜`N=30 → 9.5%`｜`N=40 → 7.2%`。
⇒ **只靠红率**要 `N≈40` 才能把上界压到修前点估计之下 ⇒ **红率不是本件承重的判据**（如实写明，不假装显著）；
**承重的是 `C2`**（修前 15/15 恒 6 条、每腿 100%）。落地后红率仍取 **N=30**（硬下限 `N≥16`）当旁证。

## §6 `NOINFO` 的预留位

1. **"缓存为何仍是最大化矩形"的最内层**（W112A §6.4 第 1 条）：本件若仍取不到托管侧仪器读数 ⇒ 继续 `NOINFO`。
2. `F2` 的独立射程：若 `F2` 单独落地后读数与 `F1` 后逐字相同 ⇒ 它的贡献记 `NOINFO`（不是"无用"，是"本装置量不出"）。
3. 无 WM（裸 `Xvfb`）下的约束效力：本族靠 WM 发起 ⇒ 不适用，记 `NOINFO`（不冒充绿）。

---

**写成时刻**：见 `~/w114a/STATUS.md` 的 `STEP 1` 追加行（早于本车道任何 `src/**` 改动）。
**本文件的 sha16**：现场算（见 W114A 报告 §0）。
