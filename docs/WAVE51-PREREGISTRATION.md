# 波 `#51` —— 预登记（`TASK-0108`：让"运行期改尺寸提示"真的到得了 X）

> 本文件是**落地前写死**的预登记（纪律：**判据先写、读数后取**；改了判据必须在本文件里留痕，不许"事后对齐"）。
> 建立者：车道 **W101A**（波 `#51` 第一条产品车道）。写成时刻见 `~/w101a/STATUS.md` 的首行 —— **早于本车道任何产品改动**。
> 判据全文（逐格、含反极性与 `NOINFO` 口径）：`~/w101a/criteria.md`（同刻写成）。
> 前序取证件：`build/MilBridge/W93A-report.md`（`TASK-0107`，**零产品改动**的取证 + 设计；其 §5 的 `P1`–`P4` 是本件的技术依据）。
> ⚠️ W93A 的 10 条 `NOINFO`（其报告 §7）**不是**已知项，本件不得引用它们当结论。

---

## §0 起点现场（可复算）

| 量 | 值 | 来源 |
|---|---|---|
| 冻结基线 | `#50`（`gen=#50`，`1f4189c1257737a9`） | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| 位 `win32shim` | `33352e5797031999` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 现场 `sha256sum` |
| 源 `win32_core.c` | `9aa0d2d1b1ed8d55` | 现场 |
| 源 `win32_internal.h` | `c3dbf6b936a36239` | 现场 |
| 修前读数（本件要复现的那 4 格） | `SUMMARY A1_informative=29 PASS=5 FAIL=4 VACUOUS=20`；4 个 `FAIL` = `W1-TIGHTEN`／`W2-DECLARE`／`W2-TIGHTEN`／`W3-DECLARE` | W93A 报告 §2.2（两腿逐格相同） |
| 装置（**仓外·只读复用**） | `~/w93a/run-w93a-legs.sh`（腿）＋ `~/w93a/judge.py`（**判据唯一实现**）＋ `~/w93a/probe/`（探针） | 本件**不改**它们 |

## §1 两句话的缺陷陈述（为什么必须改）

`WM_NORMAL_HINTS` 的**唯一**写入者是 `wpf_ask_minmaxinfo_apply_hints()`（`win32_core.c:704-748`），
而它的**触发**受两个停止条件夹住（`:751-790`）：`hints_map_declared`（**问出过一次声明 = 终态**）与
`hints_map_asks < WPF_HINTS_REASK_MAX(3)`（**计的是"问"不是"改"**）。后果（W93A 实测，两类吞法都取到读数）：

1. **"已声明终态"型**：`W1` 首次问出声明后 `hints_map_declared=1` ⇒ **运行期再改永不重发**；
2. **"预算耗尽"型**：`W3` 被 4 次无意义的 `HIDE/SHOW` 花光 3 次预算 ⇒ **第一次真声明也永久发不出去**。

⇒ 唯一能引发重问的既有触发器是 `ShowWindow(map=1)`（`:1074`）；`MoveWindow`/`SetWindowPos` 两条改尺寸路径
**都不派发** `WM_GETMINMAXINFO`（`:1078-1172`）。上游 `Window.cs:5864-5884` 只在**改紧**时 `SetWindowPos`
（**调高**时什么都不做）。⇒ 缺的**不是值**（应用侧答案一直是对的），是**触发器**与**按值变化的发布判据**。

## §2 落地的改动（`P1`＋`P2`＋`P4`；`P3` 见 `§4`）

| 项 | 内容 | 依据 |
|---|---|---|
| `P1` | 把"**终态 `hints_map_declared` ＋ 次数上限 3**"**换成**"缓存上次已发布的 `(min,max)`，**值变了才** `XSetWMNormalHints`"（幂等发布） | W93A §5 `P1` |
| `P2` | `MoveWindow`/`SetWindowPos` 在**尺寸真的变了**时补一拍刷新（这就是"运行期改"的触发器：改紧时上游**一定**走 `SetWindowPos`） | W93A §5 `P2` |
| `P4` | `hints_in_refresh` **重入闸**（刷新函数会**同步回调托管代码**，可能再进 `SetWindowPos`） | W93A §5 `P4` |
| `P3` | "改**大**但没有 resize"那一半：先做 `P3-a`（PF shim `OverrideMetadata` 链式挂钩）的**最小探针**判合法性；不成立 ⇒ `P3-b` **保守兜底** ＋ 逐字写残留边界 | W93A §5 `P3`（其合法性 W93A 记 `NOINFO`） |

**不许动的**：`D-G83` 的修法本体（`wpf_ask_minmaxinfo_apply_hints` 的"只发应用真的改过的上限"语义 ＋
`DefWindowProcW` 的 `WM_GETMINMAXINFO` **no-op**）**语义不变**；波 59 的"未声明 ⇒ 不发 `PMaxSize`"**不变**；
**一个 `Invariant.Assert` 都不删**；**不许**用"只把上限 `3` 改大"冒充修好（`P3-c` 明令禁止）。

## §3 判据 `P`／`K`／`I`／`R`／`A`（**逐格写死于 `~/w101a/criteria.md`；此处只列清单**）

- **`P`（正极性，4 格 `FAIL`→`PASS`，两腿各自判）**：`W1-TIGHTEN`／`W2-DECLARE`／`W2-TIGHTEN`／`W3-DECLARE`
  ⇒ 判决**只认 `judge.py` 的 `A1` 行**（期望值 = 同 stage 的**应用侧自查答案**，不是我先猜的像素数）。
  `W2-DECLARE` 最值钱：应用**自己**缩窗 `625x521→521x417` 时 X 侧必须**出现** `maximum size`。
- **`K`（保持不变）**：`W1-SHOW`／`W2-SHOW`／`W3-SHOW`／`W2-TOGGLE`（**正对照**）仍 `PASS`；
  未声明窗 `maximum size` **仍缺席**（波 59 语义）；`reg58`（出现 `1280 by 1024`）**仍 0**；
  `W1-REVERT` 的 `A3` 格修后应**从 `VACUOUS` 变成有信息的 `PASS`**（提示真的移动过）；若仍 `VACUOUS` ⇒ `NOINFO` ＋ 逐字原因。
- **`I`（新判据：幂等 ⇒ 无风暴）**：`X 调用次数 == 值变化次数`，观测面 = `xprop -spy -id <xid> WM_NORMAL_HINTS`
  的行数 vs 值序列的**相邻重复**；**判别力自证先写死**：**修前件上本判据必须 `FAIL`**，否则记 `NOINFO`（不许当绿）。
- **`R`（零回归）**：`D-G83` 四格（`667 by 500`／`521 by 417`／缺席／`reg58=0`）＋ `0104` 四入口＋`N1`＝**26/26** ＋ 裸 `Xvfb` 启动路径。
- **`A`（反极性，成对）**：源 `cp -p` 备份 → 改 → 重建（记新 `win32shim`）→ **逐字节复原** ＋ 重建
  ⇒ `win32shim` **必须回到 `33352e5797031999`** ∧ 那 4 格**回到 `FAIL`**；复原后不等 ⇒ 反极性**不成立**（不许当绿）。
- **两腿都要**：**无 WM（裸 `Xvfb`）＋ 有 WM（私有 `Xvfb`＋`xfwm4 --compositor=off`）**；
  ⚠️ 有 WM 时"**点击能不能落地**"是历史共变量 ⇒ 与"落地计数"**同列**（W93A §3.3 已证其合成点击**两臂都没落地** ⇒ 该格 `NOINFO`）。
- **`NOINFO` 既不算绿也不算红**；`rc=127`/`126` ＝没跑过；**结论必须"artifact ＋ 字段 ＋ sha16"三样齐**。

## §4 `P3` 的两条路与**先写死**的兜底边界

- `P3-a`：新建 PF 侧 shim，模块初始化时对 `MaxWidthProperty/Min*Property` 用 `OverrideMetadata(typeof(Window), …)`
  **链式**挂回调 ⇒ 任何 DP 变化都通知 shim（新导出）去刷新。**判据**：`LEGAL`（装得上、应用起得来、原 `_OnMaxWidthChanged` 零回归）
  ∧ `NOTIFIED`（**含调高**的改动 ⇒ 通知真的到）⇒ 才叫可行。
- `P3-b`（兜底）：挂在 `WM_SIZE`／`WM_WINDOWPOSCHANGING` 上 ⇒ **下次窗口活动才发布**。**残留边界（逐字，必须写进报告与登记件）**：
  **"调高上限且此后不产生任何尺寸活动 ⇒ X 侧仍旧值"**。
- `P3-c`（**不许当修好**）：只把 `WPF_HINTS_REASK_MAX` 改大。

## §5 世代与位（先声明，免得冻后读成事故）

| 位 | 预期 | 理由 |
|---|---|---|
| `win32shim` | **变** | 本件改 `win32_core.c` ＋ `win32_internal.h`（native C 源**不在**任何 applier 的重放集里 —— 现场 `grep -l win32_core src/WpfGfx.Linux.Native/tools/*.py` = 空 ⇒ 手改不会被波覆盖） |
| `bridge`/`pc`/`pf`/`windowsbase`/`provider`/`wic_shim`/`hbtextline`/`dwf` | **预期不变** | 本件不碰托管侧（`P3-a` 若落地则 `pf`/`hbtextline` 可能变 ⇒ 届时**逐位报**） |
| `verify-all.sh` / `known-red.json` / 五臂 | **不动**（本件不跑完整 `verify-all`、不重取臂、不冻结） | 收尾链另派车道 |

## §6 交付与纪律

- 报告：`build/MilBridge/W101A-report.md`（①判据②修前 4 格复现③改了哪几处（文件:行＋逐字 diff 摘要）④修后两腿读数⑤零回归⑥反极性成对⑦`P3` 结论⑧`win32shim` 新 sha16 与九位未动项⑨作废趟/纪律偏离/自伤⑩≤8 行小结）。
- 实验装置类改动（`cp`、临时换件、私有 X、复制腿脚本）**公告留痕**并事后还原；**不改别的车道的件**；
  私有显示只用 `:18x`；**零 `pkill -f`**（按 PID 收工）；**不碰** `:0/:1/:10/:97/:99` 与用户真实会话。
