# M7b · native **出队侧**消息流插桩（MSGFLOW）报告

> **本轮声明：只写源码，未构建、未安装、未发桥、未重建 PC。**
> 具体到动作：**没有**产出任何 `.o`/`.so`（`obj/win32_msg.o` 仍是 16:10:01、`bin/libwpfwin32.so` 仍是 16:10:02 ——
> 都是主控上一轮构建留下的），只做了一次 **`gcc -fsyntax-only`**（不产出文件的语法检查）来确保交出去的源码能编译。
> 构建 + 同步 4 份副本 + 重建 PC + 重发桥 + 重跑门禁**全部由主控统一执行**。

---

## 0. 这一格要回答的问题

must-do「打字到不了 TextBox」的证据链（主控已逐条钉住）：

| # | 事实 | 出处 |
|---|---|---|
| 1 | shim **决定**产出 `WM_CHAR`（`'A'=0x41`、`'B'=0x42` 都对） | `[KEY_DIAG] KEY KeyPress … → WM_KEYDOWN + WM_CHAR` |
| 2 | `[msg]`（**dispatch 期** trace）里 `msg=0x0102` 计数 = **0** | `wpf_trace_msg` 在 `wpf_dispatch_to_window`（`win32_msg.c:304` → `fprintf :293`） |
| 3 | 托管侧入口探针只打 `HwndSource WM_KEYDOWN`（10 行），无 `WM_CHAR` 相关 | T1c 的 `WPF_LINUX_INPUT_TRACE`（入口在 `HwndSource.OnPreprocessMessage` 焦点早退门**之后**，`HwndSource.cs:1906`，单独不能定案） |
| 4 | 队列 filter 语义**不会**滤掉 `WM_CHAR` | `wpf_queue_pop`（`win32_msg.c:83-116`）：`hwndFilter==NULL ⇒ 任意窗口`；`lo\|\|hi` 才启用消息号区间 |

⇒ 缺口在 **「入队 → 出队」** 这一段：消息**进了队列但没从 `GetMessage` 出来**（或进了**别的线程**的队列）。
本轮插桩就是把这一段变成读数。

---

## 1. 插桩内容（`src/WpfGfx.Linux.Native/src/win32_msg.c`，**唯一改动的文件**）

开关：**`WPF_LINUX_MSGFLOW_TRACE=1`**（**缺省关**；未设/空/`0` ⇒ 一行不打）。**只打印、不改行为**
（所有插入点都在"算完之后读一眼"的位置，或纯诊断分支）。

| 行 | 内容 |
|---|---|
| `:39-44` | 前向声明（`wpf_queue_push/pop` 定义在助手之前 ⇒ 必须前置，否则 implicit-declaration 一串错**实测踩到**） |
| `:62-69` | **入队侧**：**只对 `WM_CHAR`** 打一行 `push WM_CHAR 入队 码点=… 队列长度=… 队列=… tid=…` |
| `:99-148` | 诊断骨架：`wpf_msgflow_on()` / `wpf_msgflow()`（**每进程 ≤200 行**）/ `wpf_msgflow_interesting()` / `wpf_msgflow_tid()` / `s_pop_api`（"谁在取消息"） |
| `:185-205` | **出队侧**（放锁之后打印）：`pop api=<调用来源> msg=<十进制>(0x<hex> <名字>) hwnd=0x… 剩余=<队列剩余条数> 队列=0x… tid=…` |
| `:384` | `GetMessageW` 入口标注 `wpf_msgflow_api("GetMessageW")` |
| `:412` / `:418` | `PeekMessageW` 两个分支分别标注 `"PeekMessageW(PM_REMOVE)"` / `"PeekMessageW(PM_NOREMOVE)"` |
| `:421-428` | **PM_NOREMOVE 专项**：先记"队首是什么"，用于判断本次取到的是不是队首 |
| `:446-462` | **PM_NOREMOVE 两条风险告警**：① 取到的**不是队首** ⇒ 打印"回插队首后**顺序被改变**"；② 回插 **`malloc` 失败** ⇒ 打印"**该消息被吞**" |

**防刷屏**（刻意的、已写进注释）：**关注类**消息（`WM_CHAR/WM_KEYDOWN/UP/WM_SYSKEY*/WM_SYSCHAR/WM_DEADCHAR/WM_SETFOCUS/WM_KILLFOCUS/WM_QUIT`）**必打**；
其余（`WM_PAINT/WM_TIMER` 等）只采样**前 40 条**并标注 `（非关注类，采样 n/40）` —— 否则泵里几千条会把 200 行额度吃光、
**恰好把 `WM_CHAR` 挤掉**（这正是这条诊断要防的失败模式）。

**新增的一条线索（本报告提出，插桩已覆盖）**：入队/出队两侧都打 **`队列=<指针> tid=<线程>`**。
`wpf_x11_pump_into_queue(t)` 是把 X 事件推进**调用者线程**的队列 ⇒ 若事件泵曾跑在**别的线程**上，
`WM_CHAR` 会进"错的队列"、UI 线程的泵永远取不到。两侧一对比（入队 `队列=0x…` vs 出队 `队列=0x…`）**即现**。

---

## 2. 读码判定：`PeekMessageW(PM_NOREMOVE)` 的两条风险（"能/不能 + 依据"）

现状实现（`win32_msg.c:429-462`）：把消息 `pop` 出来 → `malloc` 一个节点 → **插回队首**。

### 2.1 `malloc` 失败 ⇒ **静默丢件**：**能**（依据确凿）

```c
wpf_msg_node *n = (wpf_msg_node *)malloc(sizeof(wpf_msg_node));
if (n) { …插回队首… }
return 1;                     // ← 没有 else：即使 malloc 失败，也返回 1（"有一条消息"）
```
`wpf_queue_pop` **已经 `free(v)` 掉原节点**（`:105`）⇒ 一旦 `malloc` 失败，这条消息**从队列里消失**，
而调用方在 `PM_NOREMOVE` 语义下**以为它还在队里**（下次 `GetMessage` 应该取到它）⇒ **丢件**。
**触发条件**：仅 `malloc` 失败（内存压力）。**后果面**：任何被这次 peek 命中的消息（见 2.3 的可达性）。
**本轮已加告警**：这条路径现在会打 `⚠ PeekMessageW(PM_NOREMOVE) 回插 malloc 失败 ⇒ **该消息被吞**（msg=…）`。

### 2.2 取到的不是队首却回插到**队首** ⇒ **改序**：**能**（结构上成立）

`wpf_queue_pop` 从队首开始**扫描第一条匹配**（`hwndFilter` / `lo..hi`）⇒ 若队首那条**不匹配**，
被取走的就不是队首；而回插处是 `n->next = t->head; t->head = n;` ⇒ **它被搬到了那些"更早但不匹配"的消息之前**。
**成立条件**：调用方给 `PM_NOREMOVE` 传了**非空 filter**（窗口或消息区间）。
**本轮已加告警**：`⚠ … 取到的**不是队首**（队首=…，取到=…）⇒ 回插队首后**顺序被改变**`。

### 2.3 可达性（决定这两条是不是"纸面风险"）

全上游只有 **1 处** 功能性的 `PM_NOREMOVE` 调用点（其余是 `PM_REMOVE` 或无 filter）：

```
PresentationFramework/System/Windows/Documents/TextEditorTyping.cs:1609
  mouseInputPending = UnsafeNativeMethods.PeekMessage(ref message, new HandleRef(null, hwnd),
                          WindowMessage.WM_MOUSEFIRST, WindowMessage.WM_MOUSELAST, NativeMethods.PM_NOREMOVE);
```
⇒ **非空 filter（窗口 + 消息区间）** ⇒ **2.2 的改序条件可达**（当鼠标消息前面还压着别的消息时）。
⇒ 但它取的是**鼠标消息**，所以：
- **2.2 的改序**：可达 —— 被搬动的是**那条鼠标消息**（它被提前到队首），**不是** `WM_CHAR`；
- **2.1 的丢件**：只有当"被这次 peek 命中的那条"恰好是 `WM_CHAR` 时才吞字符，而本调用点命中鼠标区间 ⇒
  **`WM_CHAR` 不会被这个调用点直接吞掉**；吞掉的会是鼠标消息。
⇒ **结论**：这两条**不能**解释"`WM_CHAR` 没从 `GetMessage` 出来"，但**都是真缺陷**，
且 `WM_MOUSEFIRST..WM_MOUSELAST` 只覆盖鼠标区间这点依赖"上游只有这一个调用点"——**若将来新增带 filter 的
`PM_NOREMOVE`，2.1 立刻变成"能吞字符"**。⇒ 登记为**待修**（形态：`PM_NOREMOVE` 改成"只读队首、不 pop"，
或回插失败时按 Win32 语义返回 0 并把消息放回原位）。

---

## 3. 判据表（出队侧 trace 一跑就能定案）

| 观测（同一条 `WM_CHAR`：码点相同、时间相邻） | 归类 | 下一步归谁 |
|---|---|---|
| `push WM_CHAR 入队 …` **有** + `pop … WM_CHAR …` **有** | 消息**确实从 `GetMessage`/`PeekMessage` 出来了** ⇒ **托管侧没接住**（预处理吃掉/未派发） | **T1c / PC 车道**（入口探针在焦点早退门之后 ⇒ 要把探针往前挪或加"预处理期"计数） |
| `push …` **有** + `pop … WM_CHAR` **无**（且 `pop` 行里 api 有 `PM_NOREMOVE` 或 `剩余` 计数异常） | 归**队列内部**：`filter` 不匹配 / `PM_NOREMOVE` 丢件（2.1）/ 改序（2.2） | **我的车道**（本轮已把两条风险变成告警行） |
| `push …` **有**（队列=0x… tid=A）+ `pop` 只在**另一个** `队列=0x… tid=B` 上出现 | **跨线程队列**：事件泵在别的线程上把消息推进了"错的队列" | **我的车道**（`wpf_x11_pump_into_queue(t)` 的线程归属） |
| `push WM_CHAR` **无**（但 `[KEY_DIAG] KEY … → WM_KEYDOWN + WM_CHAR` 有） | 归**翻译层/入队**（`push()` → `wpf_queue_push` 的 `malloc` 失败，或根本没走到） | **我的车道** |
| 两侧都没打，`[KEY_DIAG] XEV` 也没有 | 键**没到 shim** | 输入注入侧（见 F2 报告附 A.1 的口径） |

---

## 4. 请主控执行的命令（构建 → 同步 → 一趟读数）

```bash
# ① 构建（权威件；先确认无进程 mmap 着它，否则 SIGBUS）
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/src/WpfGfx.Linux.Native && bash build-shim.sh --all

# ② 同步 4 份副本（按既有脚本/流程，**别手工 cp**）；
#    真源 = src/WpfGfx.Linux.Native/bin/libwpfwin32.so
#    副本 = build/MilBridge/tests/{ContractProbe,CompositeFontProbe}/bin/Release/、
#           build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/、以及权威部署目录（app-local）

# ③ 四份一起重读（**一条命令**，逐份带 sha/字节/mtime）
find . -name 'libwpfwin32.so' -not -path './upstream/*' | sort | while read f; do \
  printf '%s %s B %s %s\n' "$(sha256sum "$f"|cut -c1-16)" "$(stat -c%s "$f")" \
         "$(date -d @$(stat -c%Y "$f") '+%H:%M:%S')" "$f"; done

# ④ 一趟读数（**应用槽归 T3**；三个 env 同时开：键翻译 + 托管入口 + 新的消息流）
WFP_RUN_DIR=/tmp/msgflow-run \
  tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh 90 --only=textbox-edit \
  --app-env=WPF_LINUX_KEY_DIAG=1,WPF_LINUX_INPUT_TRACE=1,WPF_LINUX_MSGFLOW_TRACE=1
```

**怎么读（四行 grep，判据见 §3）**
```bash
L=/tmp/msgflow-run/probe-triage-textbox-edit.log          # 或 probe-only.log
grep -a "\[MSGFLOW\]" "$L" | head -80                     # 全貌（≤200 行额度）
grep -ac "\[MSGFLOW\] push WM_CHAR" "$L"                  # 入队条数（应 = 注入的字符数）
grep -a "\[MSGFLOW\] pop" "$L" | grep -c "WM_CHAR"        # 出队条数 ⇒ 与上一行对比即"闭环"
grep -a "\[MSGFLOW\] pop" "$L" | grep -o "api=[^ ]*" | sort | uniq -c   # **谁取走的**（关键格）
```
另看两条告警（有则直接指认缺陷）：
`grep -a "⚠" "$L"`（`PM_NOREMOVE` 丢件/改序）。

**装完作废的读数**：`win32shim:` 位**再变一次**（⇒ `WFP_ARTIFACTS`/`BASELINE` 里所有含旧 `win32shim` 的行、
以及 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 6 条）⇒ **验收基线要按 F2 报告附 C 的重冻顺序跑**；
`pc:`/`pf:` 位在这次集成波里也已变（补丁 P + T1c 输入追踪）。

---

# 第 2 版仪器（`MSGFLOW v2`）：把"WM_CHAR 从队里消失"钉死

> **本轮仍然只写源码、未构建、未安装**：`src/WpfGfx.Linux.Native/obj/win32_msg.o` 与 `bin/libwpfwin32.so`
> 的 mtime 仍是主控上一轮构建留下的值；本轮只做了 `gcc -fsyntax-only`（**不产出任何文件**）。

## V.1 实跑读数（T3，元组 `pc=8ff5cb388ca75964 win32shim=b3a716ce094c6bab bridge=e0d01832a3efea53`）

```
[MSGFLOW] push WM_CHAR 入队 码点=65(0x0041 'A') 队列长度=2 队列=0x5b1928c8e4a0 tid=131553739208512
[MSGFLOW] push WM_CHAR 入队 码点=66(0x0042 'B') 队列长度=2 队列=0x5b1928c8e4a0 tid=131553739208512
pop api=GetMessageW … 共 52 行：0x8000×26 / 0x0100×6 / 0x8009×5 / 0x0101×4 / 0x0200×2 / 0x0113×2 / 0x0007·0x0008·0x0005·0x0003·0x0018·0x000f·0x020a 各 1
**0x0102 = 0 行**（托管侧同步：① 出队 里同样 0 个 0x102）
时间序：pop 0x0100 剩余=0 → push WM_CHAR 'A' 队列长度=2 → pop 0x0100 剩余=1 → pop 0x0101 剩余=0
```
**注意最后两格**：0x0100 取走后应只剩 `WM_CHAR`（剩余=1 ✓ 与之一致），但紧接着 `pop 0x0101 剩余=0`
说明**那条 `WM_CHAR` 已经不在了** —— 而它既没被 pop 打印、也（据 T3）不可能被额度挤掉。这正是要解释的那一格。

## V.2 复核 T3 的三条读码结论（本文件当前行号）

| T3 的结论 | 复核 | 依据（当前行号） |
|---|---|---|
| 全 shim **只有 `wpf_queue_pop` 会 free 队列节点** | ✅ 成立 | `:197`（pop 内 `free(v)`）；`:351` 是 `KillTimer` 的 timer 节点，无关 |
| `wpf_msgflow_interesting()` **包含 `WM_CHAR`** ⇒ "关注类必打"对 WM_CHAR 成立 | ✅ 成立 | `:172-177` |
| 总额度没用完（106 < 200）⇒ **不是被额度挤掉** | ✅ 成立（106 < 200） | `:150-152`（`WPF_MSGFLOW_MAX`） |
| `api=` 52 行全是 `GetMessageW` ⇒ **"被嵌套 Peek 拿走"暂不成立** | ✅ 成立（本轮实跑无一条 Peek 标注） | 本报告 §1 的两个 `wpf_msgflow_api()` 标注点 |

## V.3 本版新增的三件仪器（`src/WpfGfx.Linux.Native/src/win32_msg.c`）

| # | 行 | 输出形态 | 为什么决定性 |
|---|---|---|---|
| ① | `:519`（`GetMessageW` 入口）、`:550`（`PeekMessageW` 入口） | `call api=GetMessageW hwnd=0x… lo=0x… hi=0x… tid=…` / `… remove=0x…` | **每次调用都打**（`GetMessageW` 会阻塞 ⇒ 调用数 ≈ 出队数，不会爆额度）。直接回答"**有没有带区间/带窗口的调用在跑**"——若某次带 `hwnd` 或 `lo..hi`，被它跳过的 `WM_CHAR` 就永远留在队里（判据 (a)）。**顺带把"嵌套 Peek"这条彻底关上**：Peek 即使一条都没取到，现在也会有 `call` 行 |
| ② | `:200-208`（`wpf_queue_pop` 扫描内） | `skip msg=0x0102(WM_CHAR) hwnd=0x… 原因=hwndFilter\|range filter=0x… lo=0x… hi=0x…（本节点留在队里）` | **只对 `WM_CHAR` 打**（一行成本为零）：判据 (a) 的直接证据 —— 是哪一次调用、凭哪个条件把它跳过的 |
| ③ | `:149-170`（`wpf_msgflow_snapshot`），调用点 `:66`（push 的 WM_CHAR）/`:224`（pop 的关注类） | 在两行末尾追加 `队列内容=[0x0100,0x0102] 共2（只显示前 8 条）` | 把"`WM_CHAR` 什么时候从队里消失"变成**逐行可见**，不用再靠"剩余条数"反推 |

## V.4 **离线最小复现（本轮最有价值的产出）：`tail` 不变量被破坏 ⇒ 下一次 push **孤儿化整条队列**

**读码（三处，逐字）**：
```c
// wpf_queue_push  :57
if (t->tail) t->tail->next = n; else t->head = n;      // ← 只认 tail；tail==NULL 就**覆盖 head**
t->tail = n;

// wpf_queue_pop   :186-195（扫描第一条匹配；允许带 hwndFilter / lo..hi）
wpf_msg_node *v = *pp;
*pp = v->next;
if (t->tail == v) t->tail = NULL;                      // ← 摘掉**队尾**时把 tail 置空，**没有指回新的队尾**
free(v);
```
**最小复现序列**（每一步都是普通 Win32 用法）：
1. `push A`（queue=[A]，tail=A）
2. `push B`（queue=[A,B]，tail=B）
3. `pop(filter=仅匹配 B)` —— 合法用法（例如 `GetMessage(hwnd, lo, hi)` 或 `PeekMessage` 带区间）：摘掉 B ⇒
   `A->next=NULL`、**head=A 但 tail=NULL**（不一致状态）
4. `push C` ⇒ 走 `else t->head = n;` 这一支 ⇒ **C 成为队首，A 被整条孤儿化**（既不在队列里、也没被 free
   ⇒ **没有经过任何 pop ⇒ 出队侧一行都不打** ⇒ 与"消息静默消失且日志无痕"的现场**完全吻合**）

⇒ **这解释了实跑里那条 `WM_CHAR` 的去向**：它极可能是在某次"带区间的 pop 摘掉队尾"之后，
被下一次 `push` 的 `else` 分支**整条孤儿化**掉的（而不是被某次 pop 取走）。
⇒ 而 `push WM_CHAR 'A' 队列长度=2` 那一格（刚 push 一条却已经有 2 条）也与此一致：**push 前队列里已有残留**。

**离线用例（源码，未构建）**：`src/WpfGfx.Linux.Native/tests/queue_invariant.c`（129 行，sha16 `267a90d378c27c29`）
- 场景 (a)：带区间的 pop 跳过 `WM_CHAR` 之后，**它必须仍在队里**（证明 (a) 只造成"留队"，不造成"消失"）；
- 场景 (b)：500 轮 push/filtered-pop 后 **条数守恒 + `WM_CHAR` 一条不少**；
- 场景 (c)：**上面 4 步的最小复现**，断言"正确行为"（A 与 C 都能取到）⇒ **按本节的读码判定，本用例在当前实现上应当【红】**
  （我不预写结果：构建后一跑即证，末行 `QUEUE_INVARIANT=PASS|FAIL(n)`）；
- 顺带量 `PeekMessageW(PM_NOREMOVE)`：**条数守恒**（无丢件）但**命中非队首时回插队首会改序**（缺陷 2.2 的可执行证据）。
- 跑法（**主控构建之后**，一行）：
  ```bash
  cd src/WpfGfx.Linux.Native && gcc -std=gnu11 -O1 -Isrc tests/queue_invariant.c -o /tmp/queue_invariant \
      -Lbin -lwpfwin32 -Wl,-rpath,"$PWD/bin" -lX11 -ldl -lpthread && /tmp/queue_invariant
  ```

## V.5 修法候选（**本轮不动手**，等你的号令）

1. **F-A（根因、最小）**：`wpf_queue_pop` 摘掉队尾时**把 `tail` 指回新的队尾**（或改成"哨兵/单向+计数"结构）。
   最小改法：pop 时记录 `prev`，若 `v == t->tail` 则 `t->tail = (prev == NULL) ? NULL : prev;`
   —— 一行修正，彻底消掉 `head!=NULL && tail==NULL` 这个非法状态。
2. **F-B（防御）**：`wpf_queue_push` 的 `else` 分支加断言式兜底：`if (!t->head) t->head = n;` 之外，
   若 `t->tail == NULL && t->head != NULL` ⇒ 打印**告警**并修 tail（而不是覆盖 head）。
   这条即使 F-A 有漏，也不会再出现"孤儿化静默丢件"。
3. **F-C（`PM_NOREMOVE`）**：按报告 §2.1/§2.2 —— 回插失败时按 Win32 语义返回 0 并**原位放回**；
   或干脆改成"只读队首、不 pop"（无 filter 时等价）。
4. **验收**：先跑 `tests/queue_invariant.c`（**必须 PASS**，含场景 (c)）→ 再跑一趟
   `--only=textbox-edit --app-env=…MSGFLOW_TRACE=1`，期望出队侧出现 `pop … 0x0102 WM_CHAR` 行。

## V.6 重新读数（仪器①②③ 上线后）

```bash
grep -a "\[MSGFLOW\] call " "$L" | grep -v "lo=0x0 hi=0x0" | head   # 有带区间/带窗口的调用吗（判据 a 的前置）
grep -a "\[MSGFLOW\] skip " "$L" | head                            # WM_CHAR 被谁跳过（判据 a 的直接证据）
grep -a "队列内容=" "$L" | head -20                                # WM_CHAR 何时从队里消失（判据 c）
```
判据（与 §3 同口径，现在**逐行可读**）：`call` 有区间 ⇒ 先看 `skip` 行；`skip` 没有而 `队列内容` 里 `0x0102` 莫名消失
⇒ 归 **V.4 的 `tail` 不变量**（我的车道）；`队列内容` 里一直在、而 `pop` 从不命中 ⇒ 归**调用方的 filter**
（也在我车道，但属"用法/语义"而非状态损坏）。

---

# 第 3 版：**修法落地 + 修前/修后原始输出**

> **本轮仍未构建权威件**：`obj/win32_msg.o`（16:49:23）与 `bin/libwpfwin32.so`（16:49:24）的 mtime 未变、
> 未同步、未发桥、未跑应用。为满足"**修完必须重跑 `queue_invariant` 到全 PASS**"，我在**私有目录
> `/tmp/fix-build/`** 做了一次本地构建（`sha16 290951c012d68715`，**未安装、未覆盖任何副本**）并运行用例；
> 权威构建/安装仍归主控。若要求字面"不构建"，请忽略那两条 `/tmp` 读数 —— 源码本身不依赖它们。

## W.1 修了什么（`src/WpfGfx.Linux.Native/src/win32_msg.c`，sha16 `10c6d2a0285dd7bc`）

| 编号 | 位置 | 改动 | 为什么 |
|---|---|---|---|
| **F-A 根因** | `wpf_queue_pop`（`:234` `prev`、`:250`） | `if (t->tail == v) t->tail = prev;`（旧版是无条件 `t->tail = NULL;`） | 摘掉**队尾**时若队列里还有别的节点，旧版会把 `tail` 置空 ⇒ 产生 `head!=NULL && tail==NULL` 的**非法状态**；下一次 `push` 走 `else t->head = n;` ⇒ **覆盖 head、整条链孤儿化**（既不摘链也不 free ⇒ **出队侧一行都不打**：与现场 `0x0102 = 0 行` 完全吻合） |
| **F-B 防御** | `wpf_queue_push`（`:58-75`） | `else if (t->head) { 自愈 tail 并接在**队尾**；打一行 `⚠` 告警 }` / 真为空才写 `head` | **绝不覆盖 head**；即使 F-A 有漏也不会再"静默"丢件（异常态会**说话**） |
| **F-C `PM_NOREMOVE` 语义** | 新增 `wpf_queue_peek_readonly()`（`:192-230`）+ 重写 `PeekMessageW` 的 PM_NOREMOVE 分支（`:617-633`） | 改成**只读扫描**（匹配条件与 `pop` 逐字一致，但**不摘链、不 free、不重排、不 malloc**） | 一次性去掉旧实现的两个真风险：`malloc` 失败 ⇒ 消息已 pop 掉却仍 `return 1`（**静默丢件**）；命中非队首却回插**队首** ⇒ **改序**（上游 `TextEditorTyping.cs:1609` 就是带 filter 的 `PM_NOREMOVE`）。旧版那两条 `⚠` 告警随之删除——**因为那条路已经不存在了** |
| v2 仪器 | 全部保留 | `call`（入口参数）、`skip`（**pop 与 peek 两侧各一份**，只对 WM_CHAR）、`队列内容` 快照 | 修完仍要能"逐行看见" WM_CHAR 的去向 |

## W.2 修前 / 修后原始输出

**修前（主控跑的原始输出，5 FAIL / `QUEUE_INVARIANT=FAIL(5)`）**：
```
PASS (a)×5 … PASS (b) 长序列后 count == pushed - popped … PASS (b) 排空后 count == 0
FAIL (b) 排空后 WM_CHAR 条数 == 500（一条都没少）
PASS (c) 带 filter 摘掉队尾：取到 B 且 count 应为 1（A 仍在）
FAIL (c) 之后再 push 一条：count 应为 2（**不能**丢掉 A）
FAIL (c) 排空能同时取到 A 与 C（**A 没有被孤儿化**）
FAIL Peek(PM_NOREMOVE, 命中非队首) 返回 KEYUP 且 count 不变（3）
FAIL ⇒ 回插到队首**改变了顺序**（缺陷 2.2 的离线证据）
PASS peek 之后仍能排空剩下 2 条（无丢件）
QUEUE_INVARIANT=FAIL(5)
```
**修后（我的 `/tmp/fix-build` 私有构建，16/16 全 PASS）**：
```
PASS (a) push 3 条后 count==3
PASS (a) 无 filter 的 pop 取到队首 KEYDOWN
PASS (a) 带区间(0x0100..0x0101) 的 pop 跳过 WM_CHAR、取到 KEYUP
PASS (a) 跳过后 WM_CHAR 仍在队里（count==1）
PASS (a) 后续无 filter 的 pop 取到的正是 WM_CHAR（**没有丢件**）
PASS (b) 长序列后 count == pushed - popped（无静默丢件）
PASS (b) 排空后 count == 0
PASS (b) 排空后按类别守恒：char_left+other_left == pushed - popped(排空前)（一条都没少）
PASS (b) 排空后 WM_CHAR 条数 == 500 - 循环里被取走的 CH 数
PASS (c) 带 filter 摘掉队尾：取到 B 且 count 应为 1（A 仍在）
PASS (c) 之后再 push 一条：count 应为 2（**不能**丢掉 A）
PASS (c) 排空能同时取到 A 与 C（**A 没有被孤儿化**）
PASS (PM_NOREMOVE) 拿到本线程 TLS 队列
PASS Peek(PM_NOREMOVE, 命中非队首) 返回 KEYUP 且 count 不变（3）
PASS (PM_NOREMOVE) 只读扫描**不改序**：peek 之后队首仍是 KEYDOWN
PASS peek 之后仍能排空剩下 2 条（无丢件）
QUEUE_INVARIANT=PASS
```

### ⚠️ 必须写清的"修前那 5 条红里有 3 条是**用例自己的**错"（否则会误记成"三个 shim 缺陷"）
| 修前的红 | 归属 | 说明 |
|---|---|---|
| `(b) 排空后 WM_CHAR 条数 == 500` | **用例期望写错** | 循环里被 pop 的是"最老的那条"（类别交错）⇒ 剩余 CH 数**本来就不等于 500**。已改为**逐类守恒**断言（这才是正确不变量） |
| `Peek(PM_NOREMOVE…) 返回 KEYUP 且 count 不变` | **用例写错** | `PeekMessageW` 操作的是**本线程 TLS 队列**，而当时我 push 进了**本地结构体** ⇒ peek 看不到任何东西。已改用 `wpf_thread_self()` 的队列 |
| `⇒ 回插到队首改变了顺序` | **同上（假红）** | ⇒ **"改序"这条在本用例里从未被证明过**，它仍是**读码结论**（+ 上游唯一带 filter 的 `PM_NOREMOVE` 调用点 `TextEditorTyping.cs:1609` 的可达性证据）。**F-C 仍值得做**：它把"malloc 丢件"这条真风险**整条消灭**（该风险无法用本用例证伪，因为要注入 malloc 失败） |
| `(c)` 的两条 | ✅ **真缺陷（F-A）** | 由可执行断言证实：`head!=NULL && tail==NULL` ⇒ 下次 push 孤儿化 ⇒ **静默丢件** |

## W.3 四条断言 ↔ 真实病征（判据绑定）

| 断言 | 对应的真实病征 |
|---|---|
| **(c) 两条**（push 后 `count==2`、A 与 C 都能取到） | **"`WM_CHAR` 静默消失"** —— 现场读数 `push WM_CHAR 'A' 队列长度=2` → … → `pop 0x0101 剩余=0`（那条 CH 不翼而飞、且**没有 pop 行**） |
| **(a) 五条** | **"带区间的 pop 跳过 WM_CHAR 是合法的"** ⇒ 排除"被跳过 = 被丢弃"这条误判路径（消息**留在队里**，后续无 filter 的 pop 仍能取到） |
| **(b) 三条** | F-A/F-B 的**回归网**：长序列下条数与类别守恒 ⇒ 任何"孤儿化/漏摘"都会在这里红 |
| **(PM_NOREMOVE) 四条** | **顺序不被改**（F-C 后的正确行为）；**"malloc 丢件"不在覆盖范围内**（需注入分配失败）⇒ 只作读码结论，靠 F-C 直接取消该路径 |

## W.4 主控复跑的**三条可判期望**（含"不成立往哪查"）

1. **原生出队侧出现 `WM_CHAR` 行**：日志里应有
   `[MSGFLOW] pop api=GetMessageW msg=258(0x0102 WM_CHAR) hwnd=0x… 剩余=… 队列内容=[…] …`，
   且**同一条的 push 行**（`push WM_CHAR 入队 …`）里/其后快照中能看到它在被取走前**确实在队里**。
   - 不成立①：有 `push` 无 `pop`，但**有 `skip msg=0x0102`** ⇒ 是**调用参数**把它挡住的 ⇒ 看同轮 `call api=… lo=0x… hi=0x… hwnd=0x…`（判据 a）。
   - 不成立②：连 `push WM_CHAR` 都没有 ⇒ 归**翻译层**（`[KEY_DIAG] XEV/KEY` 是否已到"决定产出"那一步）。
   - 不成立③：`队列内容=[…]` 里 `0x0102` 出现后又消失、而**没有任何 pop 行** ⇒ **回归了**（F-A 失效）⇒ 立即停下报我。
2. **`textbox-edit` 的 `changes>0`**（Ledger：`[feat] textbox-edit … changes=N`，LateVerify 同样）——即"**打字真的进 TextBox**"。
   - 若 ①成立而本条不成立 ⇒ **瓶颈在托管侧**（消息已从 `GetMessage` 出来）：看 `[INPUT_TRACE]`（T1c）有没有 WM_CHAR 相关行；再看 `HwndSource._eatCharMessages`（`HwndSource.cs:1799` 置位 / `:1857` 吞掉 / `:2429` 复位）这条上游 mitigation。
3. **`[INPUT_TRACE]` 出现 WM_CHAR 相关行**（T1c 的入口探针）。
   - 若只有 `WM_KEYDOWN`、没有 `WM_CHAR`：入口探针在**焦点早退门之后**（`HwndSource.cs:1906`）⇒ 需把探针前移或加"预处理期"计数（**T1c 车道**）；同时对照原生侧 `pop 0x0102` 已成立 ⇒ 归"WPF 在预处理期把字符消息处理掉/丢了"。

## W.5 装完作废的读数（照旧）
`win32shim:` 位**再变**（本轮修法版）⇒ `WFP_ARTIFACTS`/`BASELINE` 里含旧 `win32shim` 的行、以及
`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 6 条一并作废；`pc:`/`pf:` 也已在本次集成波里变过；
按 F2 报告附 C 的顺序**重冻一次**（装 shim → 起 PC 波 → `verify-all.sh` → `REPEAT=3 --tier both` 三连 → 替换基线）。
