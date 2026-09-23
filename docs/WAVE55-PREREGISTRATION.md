# 波 `#55` —— 预登记（`TASK-0209`：**修 `win32_msg.c:57-82` 队列链遍历 ＋ 给"写坏者"取证**，判 `D-G109` 静默 SEGV）

> ⚠️ **本件的来历（逐字声明）**：本件由车道 **W141A** 在 `#55` 收尾链中**补建**（**主控授权**，同 `#53`/`#54`/`#56` 先例）；
> **本波判据先写于车道 W136A 的 `~/w136a/criteria.md`（写定 2026-09-23 17:14；sha16 = `ea19ce8d7b008b0c`，3,904 B）**
> —— **本件不发明新判据**。W136A 的产品落地报告 = `build/MilBridge/W136A-report.md`（落仓读数见其 §⑭）。
> （先例 = `docs/WAVE54-PREREGISTRATION.md`（W139A 于 `#54` 收尾链补建）／`docs/WAVE53-PREREGISTRATION.md`（W133A 补建）；同族机械要求。）
>
> 补建的理由是**仓规机械要求**，不是本车道想加码：`verify-all.sh` 第 `[11]` 步的判据件
> `build/MilBridge/tools/verify-all-step-check.sh`（`:207-218`）在标题行里按 `grep -qE "^#+ .*${gen_decl}"` 找本代号，
> **找不到就 `report_noinfo prereg-absent` ⇒ 该步 `NOINFO rc=2`**（缺声明 ≠ 通过）；
> 而该步变红 ⇒ 冻结器 `w27-freeze.py` 的 `green` 名单（含 `VERIFYALL-SELF`）**必失败** ⇒ **`#55` 冻不了**。
> 现场读数（补建前，本车道实测）：`VERIFYALL_SELF=NOINFO reason=prereg-absent gen=#55 扫了 35 件 docs/WAVE*-PREREGISTRATION.md，本代号没出现在任何标题行里`。
>
> ⚠️ **收尾链的判据在** `$HOME/w141a/criteria.md`（写定时刻 = `2026-09-23 21:1x +0800`，sha16 = `97b2e9825040a061`）。

---

## §0 本波事实（**逐条现场现算，非手抄**）

| 量 | 值 | 来源 |
|---|---|---|
| 本波唯一产品改动 | `TASK-0209`（修 `win32_msg.c:57-82` **队列链遍历** ＋ 给"写坏者"取证），判 **`D-G109`** | 主控派单 ＋ 车道 **W136A** 落地 |
| 判定点原文 | `docs/ROUTES.md`（`TASK-0209`）／`D-G109` | 现场只读 |
| 源 `win32_msg.c` | `4ad790f4c26a907c` → **`12175591b736bb3f`** | 现场 `sha256sum` |
| 源 `win32_internal.h` | `4e1880e6054635ff` → **`c13390de6f870999`** | 现场 `sha256sum` |
| 源 `win32_core.c` | `a9cc8762908b417a` → **`c66528843de4a370`** | 现场 `sha256sum` |
| 件 `win32shim` | `a6365183fa6d26b9` → **`2067cb1c97728791`**（**327,672 B**） | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 现场 |
| 权威件导出数 | **547**（**不变** —— 台账是 `static`，不新增导出面） | `nm -D --defined-only` |
| `bridge`（**本波不动**） | **`4e25e4b27d4d5ae1`**（5,028,208 B） | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` 现场 |
| 上一代冻结 | `#54`（整份 `f9948196858bc9db`；`docs/CURRENT-STATE.md:9`） | 现场 |
| 本地 = 远端 head（开工时） | `0de067cf49709b075781df6ed66c754b7b7f19aa` | `git ls-remote --symref origin HEAD` 现场 |

---

## §1 缺陷与判定点（`D-G109`，逐字）

**崩溃链** = `.NET Finalizer`（`tid=6`）→ `HwndWrapper::Finalize()` → P/Invoke `PostMessageW` →
**`wpf_queue_push+259`**（`libwpfwin32.so+0x11df3` 的逐字指令 `mov 0x38(%rax),%rax`）⇒ 踩到**已被写坏的节点**
⇒ 进程**静默死**（**应用自己 0 字节输出**）。

**与 `134` 族异源**：`tid=6` vs `1`｜栈深 **`7,088 B`**（浅）vs `8,388,672 B`｜**无重复环**（`R1=R2=False`）｜**0 字节输出**。
**两样本同址**（`W071`／`W077`，`PC` 逐位同 `0x7fff740dcdf3`）⇒ **确定性缺陷**（命中即必崩）；频度 **`2/175 ⇒ 95% 单侧上界 3.55%`**。

**机制（W136A 现场量，非推理）**：`sizeof(wpf_thread) == sizeof(wpf_msg_node) == 0x40`
⇒ 一个**已 `free` 的 `wpf_thread`** 被下一次 `malloc(0x40)`（队列节点）**原样复用**，按 `wpf_thread` 视图读得到
`head = 0x102`（消息号当了节点指针）∧ `tail == NULL` ⇒ **精确命中 `win32_msg.c:79` 的 `while (p->next) p = p->next;`**
⇒ 拿 `0x102` 去读 `->next` ⇒ 确定性 SEGV。

---

## §2 修法（**不是**只加空指针守卫 —— 那样会把"写坏链"降级成"静默丢消息"）

四件：**F1** 零解引用隔离抢救｜**F2** 具名台账 `[QUEUE_CORRUPT]`（`static` ⇒ 不新增导出）｜
**F3** `wpf_thread_destroy` 摘链｜**F3b** 置空 `owner_thread`。主控裁定另加 **(A)** 具名台账 `[POSTMSG_DEAD_TARGET]`
＋ **(B)** Win32 语义**拒绝投递**（`return 0` ＋ `ERROR_INVALID_WINDOW_HANDLE`，**不再改投调用者队列**）。

**四档成对读数**（同一腿：真窗口 ＋ 真线程退出 ＋ 真 `PostMessageW`）：

| 件 | 返回 | 主队列 | `[POSTMSG_DEAD_TARGET]` | `[QUEUE_CORRUPT]` | rc | 结局 |
|---|---|---|---|---|---|---|
| 基线 `a6365183fa6d26b9` | — | — | 0 | — | **139** | **崩** |
| `fixed` `74c359f481614eb3` | 1 | **+0** | 0 | 1 行 | 0 | 消息投进**悬挂队列** ⇒ 事实丢失 |
| `fixed2` `1d64dbdce2ceb06c` | 1 | **+1** | 0 | 0 | 0 | **静默改投**调用者队列 |
| **`fixed3` `2067cb1c97728791`** | **0** | **+0** | **1 行** | 0 | 0 | **大声拒绝**（Win32 语义）✓ |

**反极性**：逐字节复原件 ⇒ 件级 **`cmp` 逐字节回 `a6365183fa6d26b9`** ⇒ 本腿 **`rc=139` 崩回来**。
**零回归**：导出仍 **547**｜对照腿 `pushed=200 popped=200 count=0` ✓

---

## §3 本波预期位移（**写死在取数之前**）

| 位 | 预期 | 依据 |
|---|---|---|
| `win32shim` | **变**（`a6365183fa6d26b9` → `2067cb1c97728791`） | `TASK-0209`（产品，**已由 W136A 落仓**） |
| `pf` | **变**（**同尺寸**） | `D-G92`（环成员，**不是构建身份**，不许当漂移/回归判据） |
| `bridge` | **逐位不变**（仍 `4e25e4b27d4d5ae1`） | 本波零别的产品改动 |
| 其余七位（`pc`/`provider`/`wic_shim`/`hbtextline`/`windowsbase`/`dwf`） | **逐位不变** | ⇒ **任何第三位变 = 停手报主控** |

`inputs_fp`：**预期变**（重钉 `known-red.json` —— 它在 `fp_inputs()` 覆盖面内，`#28` 起的设计使然）。

---

## §4 装置继承（从 `#54`）

- **空盘/可写预检**（`#54` 冻后第 2 趟 ENOSPC 教训）：每条重活趟之前 `df --output=avail /` ≥ 5 GiB ＋ `/tmp` 可写自检。
- **显示几何守卫**（`D-G105`）：`XREQ_GEOM=1280x1024`；冻前 `verify-all` 的 `[0]` 段预期 `X-REUSE=reused`。
- **逐径 `git add`**（`D-G108`：绝不 `-A`／`--force`）＋ `porcelain` 逐件计数对账。
- **`repin-generation.py` 的 `temp`＋`os.replace`**（`D-G101`／跨区硬链）。
- **`ENOSPC ⇒ rc=2 NOINFO` 会被 `verify-all` 汇总计成 `❌`** —— 那是**环境成因，不是回归**（作废 ＋ 重跑）。

---

## §5 回滚姿势（**源逐字节还原 ⇒ 件级逐字节回旧值**）

1. 把三件原生源**逐字节**还原为 `4ad790f4c26a907c`／`4e1880e6054635ff`／`a9cc8762908b417a`（W136A 的反极性已做过一次）；
2. **重建 shim**（`bash src/WpfGfx.Linux.Native/build-shim.sh --all`）⇒ 件**逐字节**回到 **`a6365183fa6d26b9`**
   （W136A 实测 `cmp` = `IDENTICAL`；W136A 的路径无关复现已证同源重建可复现）；
3. 放回修法 ⇒ 件**独立复现** **`2067cb1c97728791`**。
   ⇒ 冻结器 `GENS['#55']` 的 `allow_changed = {'win32shim','pf'}` 与 `#54` 的 `prev_*` 常数把这条回滚姿势**机器化**。

## §6 方法学纪律（本波实测的坑，**逐字记**）

1. > **「改件后重建必须 `touch` ＋ `cmp` 到期望件，不许只看 `rc=0`」**（`#54` 已入册；本波沿用）。
2. > **「复现装置的旋钮必须公告」**：W136A 的坏链复现靠 `MALLOC_ARENA_MAX=1`（glibc 每线程一个 arena ⇒
   > 不钉时"复用"不确定、钉住后必然）⇒ 这**与现场 `2/175` 的低频并存而不矛盾**：**命中即必崩，命中与否取决于 arena 复用**。
   > 不许把"钉住装置下的必然"写成"现场必然"。
3. > **「`ENOSPC` 会把 `rc=2 NOINFO` 变成汇总里的 `❌`」** —— 那是**环境成因**，记"作废（非读数）"并**重跑**，
   > **不许当红、也不许隐瞒**（判据 `C6`／`C13`）。

---

## §7 `NOINFO`（**波级，逐条；不猜**）

1. **托管侧（.NET/WPF）对 `PostMessageW` 返回 0 的反应未验证**（W136A 零 `dotnet`，只到 native 层）⇒ `NOINFO`。
2. **`[POSTMSG_DEAD_TARGET]` 在真应用中的出现率未取到**（只在构造腿上 1 行）⇒ `NOINFO`。
3. **定时器那一半（`g_wpf.timers` 的 `owner_thread`）仍无读数**（静态改动，未造场景）⇒ `NOINFO`。
4. **`DeadThread` 场景（线程先死、窗口还活着）在真应用中的出现率未取到** ⇒ `NOINFO`。
5. **两样本为何都在第 7 击 `nav2`**（时序耦合）⇒ `NOINFO`。
6. **「`siaddr=0x0`」不作为判据**（与指令语义不符；`D-G109` 判词不依赖它）⇒ 该格 `NOINFO`。
