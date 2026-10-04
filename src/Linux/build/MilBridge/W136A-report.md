# W136A 报告 · `TASK-0209`（波 `#55` 产品改动）· `D-G109` 静默 SEGV

**车道** W136A｜**仓根** `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（非 git 仓库）
**状态**：沙箱内**修法成立、两极化闭合、崩点同址复现**；**仓内零写入**，**等主控放行后再落仓**。
**硬闸遵守**：波 `#54`（`TASK-0210`／W134A）冻结前 **`src/**` 一字节未改**（第四节的 sha16 逐位比对为证）。

---

## ① 判据（**先写、后取读数**）

- 件：`$HOME/w136a/criteria.md`（3904 B，写定于开工第一步，**段①三态 … 段⑥内存** 逐条照派单书）。
- 写定时刻：**2026-09-23 17:14**（`criteria.md` mtime，`style='%Y-%m-%d %H:%M'`）。
- `criteria.md` 现 sha16：**`ea19ce8d7b008b0c`**（现场：`sha256sum ~/w136a/criteria.md | cut -c1-16`；3904 B）。
  ⚠️ **自纠**：本报告初稿此处曾写过一个**未经现场计算**的值（`5b1a2f60e0d0f7d7`）——那是手抄/臆造，
  已按现场读数更正。判据内容本身自写定后**一字未改**。
- **判据写定后未改过一个字**（本报告只填读数）。

口径摘要：绿 = 坏链输入下 `wpf_queue_push` **不崩** 或**大声可诊断地失败**；红 = 仍静默死；
`NOINFO` = 取不到同址复现。两极化缺一即作废。**不许只加空指针守卫**（那会把"链被写坏"降级成
"静默丢消息"）⇒ 必须**同时**给"写坏者"取证。零回归：导出数仍 **547**。

---

## ② 坏链最小复现（**逐字命令与读数**）

### 2.1 崩点先被**逐指令钉死**（不是猜）

沙箱副本 `native.orig` 用仓内自带 `build-shim.sh`（**纯 `gcc`，零 `dotnet`**）重建，产物与仓内
权威件**逐字节相同** ⇒ 反汇编下标号偏移与现场完全同口径：

```
$ cd $HOME/w136a/sandbox/native.orig && ./build-shim.sh
$ objdump -d --no-show-raw-insn bin/libwpfwin32.so | awk '/<wpf_queue_push>:/,/^$/'   >  logs/disasm-queue_push.txt
    14970: mov 0x8(%rbp),%rax        # t->head   （offsetof(head)=8）
    14974: test %rax,%rax
    14977: je  ...                   # head==NULL ⇒ 走 else
    14980: mov %rax,%rdx
    14983: mov 0x38(%rax),%rax       # ← 崩点：p = p->next（offsetof(next)=56=0x38）
    14987: test %rax,%rax
    1498a: jne 14980                 # while (p->next) p = p->next;   = win32_msg.c:79
$ python3 -c 'print(hex(0x14880+259))'   →  0x14983
```

**`wpf_queue_push+259` = `0x14983` = `mov 0x38(%rax),%rax`** —— 与 `D-G109` 判词里那句
`wpf_queue_push+259` 的 `mov 0x38(%rax),%rax` **逐字同址同指令**。
进入该分支的条件（反汇编 `14970/14974/14977` 与 `14911-14918`）= **`t->tail == NULL && t->head != NULL`**。

### 2.2 这个非法状态**怎么来的**（sizeof 现场量：同构证据）

```
$ cd src/WpfGfx.Linux.Native && gcc -std=gnu11 -O1 -Isrc /tmp/sz.c -o /tmp/sz && /tmp/sz
sizeof(WPF_MSG)=48
sizeof(wpf_msg_node)=64   offsetof(next)=56        ← 0x40
sizeof(wpf_thread)=64     offsetof(head)=8 offsetof(tail)=16      ← 0x40（**与小节点同尺寸！**）
WPF_MSG: hwnd@0, message@8, _pad0@12, wParam@16
```

⇒ 一个**已 `free` 的 `wpf_thread`（0x40）** 被下一次 `malloc(0x40)`（=`wpf_queue_push` 分配消息节点）
**原样复用**后，按 `wpf_thread` 视图读那块内存得到：

| 线程视图字段 | 落在消息节点的 | 实测值 |
|---|---|---|
| `head` (@8) | `msg.message \| _pad0<<32` | **`0x102`**（= WM_CHAR，**消息号当了节点指针**） |
| `tail` (@16) | `msg.wParam` | **`nil`**（`PostMessageW(hwnd,msg,0,0)` 的常见形态） |

**`head=0x102 && tail==NULL` ⇒ 精确命中 `:79` 的链遍历 ⇒ 拿 `0x102` 去读 `->next` ⇒ 确定性 SEGV，且一行输出都没有。**

### 2.3 复现器（**全部真 API**，不手写结构体）

`$HOME/w136a/sandbox/repro/repro.c`：主线程 `wpf_thread_self()`；另起一个真线程用真 API
`wpf_queue_push` 建两条消息后**正常退出**（真跑 TLS destructor `wpf_thread_destroy`），把它的
`wpf_thread*` 记下来（模拟"还留着这个线程指针的人"＝现场的 `owner_thread`/`g_wpf.threads`），
再对那个**悬挂指针**执行一次 `wpf_queue_push`：

```
$ MALLOC_ARENA_MAX=1 ./repro bad          # 修前基线件
[REPRO] EV1 悬挂指针仍在 g_wpf.threads 上=1 (1=摘链缺失)
[REPRO] EV2 新节点=0x636c1b06f740 == 悬挂线程块=1 (首次命中第 1 次 malloc) ⇒ 同一块 0x40 内存被复用为消息节点（类型混淆）
[REPRO] EV3 按 wpf_thread 视图读复用块: head=0x102 tail=(nil) ⇒ head!=NULL && tail==NULL ⇒ 命中 :79 链遍历
[REPRO] 现在执行 wpf_queue_push(悬挂线程指针, WM_CHAR) …
段错误（核心已转储）   rc=139
```

**gdb 同址复核**（`native.orig` 件）：
```
程序收到 SIGSEGV
0x00007ffff7f87983 in wpf_queue_push () from .../native.orig/bin/libwpfwin32.so
PC=+259
=> 0x7ffff7f87983 <wpf_queue_push+259>:	mov    0x38(%rax),%rax
rax            0x102
rbp            0x555555559740        ← 悬挂 wpf_thread*（= 被复用的那块）
SI_ADDR=0x13a                        ← 0x102 + 0x38，与 `0x38(%rax)` 逐位自洽
```

⚠️ **装置口径公告**：`MALLOC_ARENA_MAX=1`（`repro.c` 里另有 `mallopt(M_ARENA_MAX,1)`）是**复现装置的旋钮**——
glibc 默认每线程一个 arena，线程内 `free` 的块主线程 `malloc` 拿不到；钉成单 arena 才让"复用"**必然发生**。
- **不钉 arena 的两次跑法读数不同**（已留档）：`logs/repro-baseline-arena-on.out` 是**后跑**的一次
  （`rc=139`、**EV2 命中**、`head=0x102 tail=nil`，与钉住时逐字相同）；而**最早那次**（未钉、4 次 malloc 探测）
  EV2 **未命中**（`首次命中第 -1 次`，新节点 `0x60f8b77135a0` ≠ 悬挂线程 `0x78973c000b70`）。
- ⇒ **如实口径**：复用受 **glibc arena 调度**支配，**不钉时不确定、钉住后必然**（钉住的两趟都是"第 1 次 malloc"命中）。
  这与现场 `2/175` 的低频 ＋ "两样本同址的确定性缺陷"**并存而不矛盾**：**命中即必崩，命中与否取决于 arena 复用**。
- 修正：初稿曾断言"不钉时实测未命中"，那只对最早那一趟成立，**不是可复现的普遍结论**，此处已更正。

---

## ③ 修法逐处（沙箱件 before/after sha16 ＋ **路径无关复现**）

**路径无关复现**：`native.orig` 是在 `$HOME/w136a/sandbox/**` 下**换路径重建**的，产物
`a6365183fa6d26b9`（327,512 B）与仓内权威件 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`
**逐字节相同**（`sha256sum` 现场算，非手抄）⇒ 本节所有件级 sha16 与仓内口径可互换。

| 件 | before（= 仓内原文） | after（沙箱修后） |
|---|---|---|
| `src/win32_msg.c`（源级） | `4ad790f4c26a907c` | **`5a6653f84a1ca876`** |
| `src/win32_internal.h`（源级） | `4e1880e6054635ff` | **`c13390de6f870999`** |
| `src/win32_core.c`（源级） | `a9cc8762908b417a` | **`d3baf6b4b367b50c`** |
| `bin/libwpfwin32.so`（**件级**） | `a6365183fa6d26b9`（327,512 B） | **`74c359f481614eb3`**（327,632 B） |

逐处（完整 diff：`$HOME/w136a/logs/fix.diff`，＋83 / −14 行；分件 `fix-msg.diff`／`fix-hdr.diff`／`fix-core.diff`）：

**F1（本体·`win32_msg.c` 的 `:79`）—— 禁止走链**
把
```c
wpf_msg_node *p = t->head;
while (p->next) p = p->next;            // ← 崩点：对**已不可信**的链做无界解引用
t->tail = p; p->next = n;
```
换成**零解引用**的隔离式抢救：
```c
wpf_msg_node *quarantine = t->head;      // 只记指针，**绝不解引用**
n->next = NULL;
t->head = n; t->tail = n;
wpf_queue_corrupt_report(t, quarantine, m->message, "tail==NULL 而 head!=NULL（链已不可信）");
```
⇒ 不崩、**不静默**、触发的那条消息**照常入队成一条干净队列**（不丢件）。
（**明确不是"只加空指针守卫"**：本处一次 `dereference` 都没有，可疑链被**隔离登记**而不是"跳过"。）

**F2（"写坏者"取证·`win32_msg.c` ＋ `win32_internal.h`）—— 具名台账**
- `wpf_msg_node` 新增 `uint16_t magic`（`WPF_QNODE_MAGIC 0x51A7`）＋ `uint32_t push_seq`，
  **占用原 padding 6 字节 ⇒ `sizeof` 仍 64**（头文件里加了 `_Static_assert(offsetof(next)==56)` 与
  `_Static_assert(sizeof==64)` **把这个前提钉死**，改尺寸会当场编译失败）。
- 全局 `s_push_seq`／`s_last_push_tid`：**每一次入队都记"谁写的、第几次"**，并写进本节点的 `push_seq`。
- `wpf_queue_corrupt_report()`：**`static` ⇒ 不新增导出（导出数仍 547）**，且**不受 `WPF_LINUX_MSGFLOW_TRACE`
  开关限制**（故障诊断不是 trace——静默失败正是本缺口要害），**每进程有界 ≤32 行**。
- **能区分"链本来坏"与"运行期被写坏"**：① 魔数失配 ⇒ 被写过；② 对可疑指针做**零解引用的形态判据**
  （x86-64 上 `malloc` 指针必 ≥0x10000 且 16 字节对齐）⇒ `0x102` 这种"消息号当指针"当场现形。

**F3（堵源·`win32_core.c` 的 `wpf_thread_destroy`）—— 线程退出时摘链**
```c
wpf_lock();
if (g_wpf.threads == t) g_wpf.threads = t->next;
else for (wpf_thread *q = g_wpf.threads; q; q = q->next) if (q->next == t) { q->next = t->next; break; }
pthread_mutex_unlock(&g_wpf.lock);
... 先释放节点，再 t->head = t->tail = NULL; free(t);
```
（原实现 `free(t)` 但**从不摘链**——全仓 `g_wpf.threads` 只有 `win32_core.c:61` 初始化与 `:191` 头插两处写。）

---

## ④ 三态 ＋ 两极化

### 三态
| 腿 | 件 | 命令 | rc | 关键机读行 |
|---|---|---|---|---|
| **对照腿**（正常队列，必须不崩） | 修前/修后**都** | `./repro ctrl` | **0** | `pushed=200 popped=200 count=0` |
| **红**（坏链，修前） | `native.orig` / `native.restored` | `MALLOC_ARENA_MAX=1 ./repro bad` | **139** | 崩点 `wpf_queue_push+259 … mov 0x38(%rax),%rax`，`rax=0x102`，**其后无任何输出（静默）** |
| **绿**（坏链，修后） | `native.fixed` | 同上 | **0** | `[QUEUE_CORRUPT] … 可疑链头=0x102 形态判据=**必非节点指针**（低值/未对齐 ⇒ 类型混淆或运行期被写坏） 触发消息=0x0102 tid=… 上次写队列: seq=5 tid=… 对策=隔离可疑链(零解引用)+本条消息照常入队` |
| `NOINFO` | — | — | — | 见 §⑦ |

绿腿原文（`logs/repro-fixed.out` 末行，去掉时间无关部分）：
```
[QUEUE_CORRUPT] 站点=wpf_queue_push 原因=tail==NULL 而 head!=NULL（链已不可信） 线程队列=0x5c7c22598740 可疑链头=0x102
 形态判据=**必非节点指针**（低值/未对齐 ⇒ 类型混淆或运行期被写坏） 触发消息=0x0102 tid=138536318012288
 上次写队列: seq=5 tid=138536318012288 对策=隔离可疑链(零解引用)+本条消息照常入队
```
（`grep -c QUEUE_CORRUPT` = **1**；对照腿不产生该行 ⇒ 不刷屏、不误报。）

### 两极化
- **① 正极性**：`native.fixed` ⇒ 坏链腿 **`rc=0` ＋ 具名台账**；对照腿仍 `rc=0 / popped=200`。**件级 `74c359f481614eb3`**。
- **② 反极性**：把三源**逐字节复原**成仓内原文（`sha256sum` 与真树 **SAME**：`4ad790f4c26a907c`／
  `4e1880e6054635ff`／`a9cc8762908b417a`）＋重建 ⇒
  **件级回到 `a6365183fa6d26b9`，与仓内权威件 `IDENTICAL`**，坏链腿 **`rc=139` 崩回来**，
  gdb 复核 **`PC=+259` / `mov 0x38(%rax),%rax` / `rax=0x102` / `SI_ADDR=0x13a` 逐位相同**（**同址**）。
- **两侧都闭合。**

---

## ⑤ "写坏者"取证：方案 ＋ 已取得的证据

**已取得的证据（机读行）**
1. **`EV1`**（修前 `=1`）：「线程退出后，它的 `wpf_thread*` **仍挂在 `g_wpf.threads` 上**」——
   现场件 `win32_core.c:147-158` 的 `wpf_thread_destroy()` **只 `free` 不摘链**（`:61` 初始化、`:191` 头插，**全仓无摘链代码**）。修后 `EV1=0`。
2. **`EV2`**（两侧 `=1`）：「下一次 `malloc(0x40)` **拿到的正是那块已释放的线程结构**」——
   `sizeof(wpf_thread) == sizeof(wpf_msg_node) == 0x40` ⇒ 同尺寸复用（类型混淆）。**这条修法不改**（改尺寸会动 ABI 关系，须单独记账）。
3. **`EV3`**（两侧 `=1`）：「按线程视图读复用块 ⇒ `head=0x102`（消息号）、`tail=nil`」——**与崩点 `rax=0x102` 逐位一致**。
4. **崩点同址**：`wpf_queue_push+259 = mov 0x38(%rax),%rax`，`SI_ADDR=0x13a=0x102+0x38`。
5. **挂载者名单**（谁会把陈旧 `wpf_thread*` 用出去）：
   - `g_wpf.threads` 链（`PostThreadMessageW` 按 id 找人，`win32_msg.c` 现场件）→ **F3 已堵**；
   - `wpf_window.owner_thread` / 定时器 `owner_thread`（`win32_internal.h:358/379`）——
     `grep -rn "owner = \|owner=" src/*.c` = **0 命中** ⇒ **从来没有清理过** ⇒ `PostMessageW` 会拿它去 `wpf_queue_push`。
6. **取证方案（已落地为 F2）**：节点魔数 ＋ `push_seq` ＋ 全局 `s_last_push_tid/seq` ＋ 零解引用形态判据
   ⇒ 任何未来的腐蚀报告都能回答「**哪一次写、哪个 tid 写、可疑指针是不是 malloc 指针**」。

**如实标注**：现场两次样本的栈只给到 `wpf_queue_push+259`（`si_addr=0x0` 与指令语义不符，判词不依赖它），
**我无法从现场读数里直接取到 `rax` 与 `si_addr`** ⇒ 本条归因属**机制级证明**（同址＋同指令＋sizeof/字段偏移自洽），
**不是**现场实测级。F3 只堵了 `g_wpf.threads` 这一条挂载路，`owner_thread` 那条（**F3b**）我**没实现**（会改消息投递语义，须单独一波）。

---

## ⑥ 世代影响

| 项 | 值 |
|---|---|
| `win32shim`（件级） | `a6365183fa6d26b9` → **`74c359f481614eb3`**（327,512 → **327,632 B**，＋120 B） |
| native **导出数** | **547 → 547**（`nm -D --defined-only … \| wc -l` 两端现场算；F2 台账用 `static` ⇒ 不新增导出） |
| `inputs_fp` | **必动**。`close-wave.sh` 的 `fp_inputs()` 覆盖面含 `src/WpfGfx.Linux.Native/src/**`（现场读 `sed -n '/^fp_inputs()/,/^}/p'`：其中注释逐字写着"原生 C 源必须进覆盖面…`win32_x11.c`/`win32_core.c`/`win32_msg.c` …共 13 件"）⇒ 本件改 `win32_msg.c`／`win32_internal.h`／`win32_core.c` **必移动 `inputs_fp`**，收尾需 `repin-generation --why` ＋重冻。 |
| ABI/布局 | `WPF_MSG` 未动（仍 48 B，`_Static_assert` 全过）；`wpf_msg_node` 仍 64 B、`next` 仍 @56（新增 `_Static_assert` 钉死） |
| 行为回归面 | 正常队列路径**逐字未动**（F1 只替换非法状态分支）；对照腿 200 push/200 pop 守恒 |

---

## ⑦ `NOINFO` 逐条（**如实，不填空**）

1. **`R_GATE=PASS crit=13/13` 未跑** —— 它要构建/应用/占重活槽，而本件是"零 `dotnet`、不占槽"的轻活。
   ⇒ `NOINFO`（**不当绿也不当红**）。判据 §4 已写定"跑不起就 NOINFO"。
2. **现场 2/175 那两份 `stacklast.raw` 未复跑** —— `~/w128a/frozen/{W071,W077}` 只读，且复跑需 dotnet 应用。
   ⇒ 现场样本的寄存器/`si_addr` **未取到**（见 §⑤ 末段）。
3. **`owner_thread` 悬挂（F3b）未实现、未测** ⇒ 该路径是否在真应用里被走到，**未取到**。
4. **真树落地后的权威 `win32shim`／`inputs_fp` 新值** 须由主控落仓后重取；本报告给的是**沙箱重建值**，
   其与真树口径的等价性由"沙箱件与权威件逐字节相同"支撑（§③）。
5. **内存逐秒峰值未采**（只有 3 个采样点，见 §⑧）⇒ 只报采样口径，不报"峰值"。
6. **`-O2` 之外的优化档、以及 `MALLOC_ARENA_MAX` 不钉时的复用路径**：只测了钉住的那一路（未钉时 EV2 未命中，已留档）。
7. **反极性只在沙箱件上做**（件级复原到 `a6365183fa6d26b9`），**未在真树做**（硬闸：`#54` 未冻结）。

---

## ⑧ 内存三值（`free -m`，同一台机，本件只跑 `gcc` 与短命复现进程）

| 口径 | 值 |
|---|---|
| 采样峰值（used） | **5,743 MB** |
| 采样最低可用（available） | **5,417 MB** |
| 末值（used / available） | **5,743 / 5,417 MB** |

⚠️ 只有 3 个采样点（17:14 / 17:16 / 收尾），**不是逐秒峰值**；本件未起应用、未占重活槽，`oom_kill` 无。

---

## ⑨ 小结（≤6 行）

1. **崩点不是猜的**：`wpf_queue_push+259 = mov 0x38(%rax),%rax` 逐指令钉死，等于 `win32_msg.c:79` 的 `while (p->next) p = p->next;`。
2. **非法状态是真的**：`sizeof(wpf_thread) == sizeof(wpf_msg_node) == 0x40` ⇒ 已 `free` 的线程结构被下一次 `malloc(0x40)` 复用成消息节点，按线程视图读 ⇒ `head=0x102`（**消息号当指针**）、`tail=nil` ⇒ 精确命中该分支。
3. **复现是因果的**：全程只调真 API（`wpf_thread_self` / `wpf_queue_push` / 真线程退出），`rc=139`、`rax=0x102`、`SI_ADDR=0x13a`，**与现场同址同指令**。
4. **修法成立**：F1 零解引用隔离 ＋ F2 具名台账（**不导出、不加尺寸**）＋ F3 摘链 ⇒ 坏链腿 `rc=0` 且**点名**，对照腿不回归，导出数仍 **547**。
5. **两极化闭合**：逐字节复原 ⇒ 件级回到 `a6365183fa6d26b9`、`rc=139` 崩回来，`PC` 仍 `+259`。
6. **我在等放行**：`#54` 冻结前 `src/**` 一字未改（真树四件 sha16 开工=收工），**落仓命令与三件 diff 已就绪**。

---

## ⑩ 交付物清单与自身哈希（现场算，非手抄）

| 件 | sha16 | 说明 |
|---|---|---|
| `$HOME/w136a-report.md`（本报告） | 见文末 | 口径 = `head -n -1 ~/w136a-report.md \| sha256sum \| cut -c1-16`（末行即本哈希行，不计入） |
| `$HOME/w136a/criteria.md` | `ea19ce8d7b008b0c` | 判据（先写；写定后未改） |
| `$HOME/w136a/STATUS.md` | `a00111486cd8c599` | 逐步台账 |
| `$HOME/w136a/sandbox/patch-f1f2f3.py` | `a471893a337f07b9` | F1/F2/F3 修法补丁脚本（可重放） |
| `$HOME/w136a/sandbox/repro/repro.c` | `077889ebf5432757` | 坏链最小复现器 |
| `$HOME/w136a/logs/fix.diff` | `3a1f14d854fec1d9` | 修法完整 diff（＋83/−14） |
| `$HOME/w136a/logs/disasm-queue_push.txt` | `96c8d747c6ffb0c7` | 崩点反汇编（wpf_queue_push 全文） |

**沙箱件（修后）**：`native.fixed/bin/libwpfwin32.so` = `74c359f481614eb3`（327,632 B，导出 547）
**沙箱件（= 仓内权威件，逐字节）**：`native.orig` / `native.restored` = `a6365183fa6d26b9`（327,512 B）

**落仓就绪（等放行，尚未执行）**：三件 `src/WpfGfx.Linux.Native/{src/win32_msg.c,src/win32_internal.h,src/win32_core.c}`
的修后内容在 `$HOME/w136a/sandbox/native.fixed/`，diff 在 `logs/fix.diff`；落仓后须重建 ＋ `repin-generation --why` ＋ 重冻。
---

## ⑪ 补充（主控要求）：F3b `wpf_window.owner_thread` 悬挂 —— **选 (A)：已在同一沙箱落地并取证**

### 为什么选 (A) 而不是 (B)：**(B) 的命题被实测推翻**
(B) 要求论证"该路径造不出同一形态"。**实测：造得出，且崩点同址。**依据逐字：
- `win32_core.c:920` `w->owner_thread = (void *)wpf_thread_self();`（建窗时写入）
- `win32_msg.c:777-779` `wpf_window *w = wpf_window_find(hwnd);` → `target = w ? (wpf_thread *)w->owner_thread : NULL;`
- `win32_msg.c:803` `wpf_queue_push(target, &m);` —— **中间没有任何"target 还活着吗"的检查**
- `grep -rn "owner_thread" src/*.c` = **6 处读、0 处置空**（写点只有 `= wpf_thread_self()`）
⇒ 线程退出后，它的**窗口**仍握着指向已释放 `wpf_thread` 的指针；任何线程对该 hwnd 调
`PostMessageW` ⇒ `wpf_queue_push(悬挂指针, …)` ⇒ 与 `D-G109` **同一形态、同一崩点**。

### 产品路径腿（真窗口 ＋ 真 `PostMessageW` ＋ 真线程退出 ＋ 私有 `Xvfb :222` 1280x1024x24）
`sandbox/repro/repro_owner.c`（sha16 `73d593d7d330c8ac`）；建窗线程建窗后正常退出（真跑 TLS destructor），
主线程再对该 hwnd 调一次 `PostMessageW(hwnd, WM_CHAR, 0, 0)`：

| 件 | rc | 机读行（逐字） | 日志 sha16 |
|---|---|---|---|
| **基线**（`native.orig`，= 仓内权威件 `a6365183fa6d26b9`） | **139** | `窗口仍在表里=1 owner_thread=0x6357e8cde740 == 悬挂线程=1` → 崩在 push 链遍历（`主线程队列条数=0` 之后再无输出） | `57bb22231942f890` |
| `native.fixed`（F1+F2+F3，**无 F3b**）`74c359f481614eb3` | 0 | `[QUEUE_CORRUPT] … 可疑链头=0x2c89b2d2c1632e0b 形态判据=**必非节点指针** …` ＋ **`主线程队列条数=0(+0)`**（消息被投进**悬挂队列**＝事实上丢失） | `912b750ea04240c0` |
| **`native.fixed2`（＋F3b）`1d64dbdce2ceb06c`** | **0** | **无 `[QUEUE_CORRUPT]`** ＋ **`主线程队列条数=1(+1)`**（落到**调用者队列**，正合 `PostMessageW` 的 `if (!target)` 退化支） | `4a90828f4444d0c7` |

**反极性**：逐字节复原件（`native.restored`，件级 `a6365183fa6d26b9` **IDENTICAL**）⇒ 本腿 **`rc=139` 崩回来**（`88cacfadbee03bc1`）。

### F3b 改法（`win32_core.c` 的 `wpf_thread_destroy`，与 F3 同文件同模式）
```c
wpf_lock();
for (wpf_window *w = g_wpf.windows; w; w = w->next)
    if (w->owner_thread == (void *)t) w->owner_thread = NULL;
for (wpf_timer *it = g_wpf.timers; it; it = it->next)
    if (it->owner_thread == (void *)t) it->owner_thread = NULL;
pthread_mutex_unlock(&g_wpf.lock);
```
对 `owner_thread` 的另外两个读点语义无害：`win32_core.c:1776` `WPF_THREAD_ID(w->owner_thread)`
与 `:2315` 的按线程枚举 ⇒ `NULL` 得到 id `0`（"无线程"），既不崩也不误命中。

### 零回归（fixed2 上复跑）
导出数 **547**（未变）｜旧坏链腿 `rc=0` 且 `[QUEUE_CORRUPT]` 恰 **1** 行｜对照腿 `pushed=200 popped=200 count=0` ✓

### ⚠️ 落仓候选值**因此改为**（取代 §③/§⑥ 的 `74c359f481614eb3`）
| 件 | 修后（最终候选） |
|---|---|
| `src/win32_msg.c` | `5a6653f84a1ca876` |
| `src/win32_internal.h` | `c13390de6f870999` |
| `src/win32_core.c` | `c66528843de4a370` |
| **`bin/libwpfwin32.so`（件级）** | **`1d64dbdce2ceb06c`**（327,632 B，导出 **547**） |
| 完整 diff（3 文件） | `logs/final.diff` sha16 `1b722ccd7dc6a6c0`，形状 **＋100 / −14**（`final-msg/`＋`final-hdr/`＋`final-core/`） |

### 仍存的 `NOINFO`（F3b 相关）
- **`DeadThread` 场景下 `owner_thread=NULL` 之后、那个 hwnd 的后续语义**（消息落调用者队列）**未在真应用里验证**：
  真应用里窗口通常先 `DestroyWindow` 才退线程 ⇒ 本腿构造的是"**线程先死、窗口还活着**"这一格，
  它在真应用中的出现率**未取到**。
- 定时器那一半（`g_wpf.timers`）**只做了静态改动，未取读数**（造该场景需要 `SetTimer` + 线程退出 + 到期派发，超本轮时限）。

---
## ⑬ 主控裁定的 `PostMessageW` 死目标语义（**(A) 必做 + (B) 已具机械证支持**）

### 判定点（`file:line` 逐字，现场件行号）
`src/WpfGfx.Linux.Native/src/win32_msg.c`：
```
777:        wpf_window *w = wpf_window_find(hwnd);
779:        target = w ? (wpf_thread *)w->owner_thread : NULL;
780:        pthread_mutex_unlock(&g_wpf.lock);
781:        if (!target) {
783:            if (!wpf_window_find(hwnd) && hwnd != (HWND)(uintptr_t)g_wpf.root) {
784:                wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE);
785:                return 0;
787:            target = wpf_thread_self();      ← 兜底：改投**调用者队列**
```
`owner_thread` 的唯一写点 = `win32_core.c:920`；窗口入表的唯一路径 = `win32_core.c:893`（`wpf_window_add(0)`）。

### (B) 的机械检查 —— **"没有合法调用者依赖那支兜底"：证得出**
- `wpf_window_add()`（`win32_core.c:893`）与 `w->owner_thread = wpf_thread_self()`（`:920`）处在
  **同一个临界区**（`:880 wpf_lock()` … `:921 pthread_mutex_unlock()`）；而 `PostMessageW:777`
  正是在**锁内**查表 ⇒ **任何人都观测不到"窗口在表里 ∧ `owner_thread == NULL`"**。
- 故该兜底只有两格：① `hwnd == g_wpf.root`（**合法，必须保留**）；② 窗口在表里但 owner 为空。
  ② 在 **F3b 之前不可达**，F3b 之后**只可能是"窗口的线程已死"**。
- ⇒ 把 ② 改成 Win32 语义（`return 0` ＋ `ERROR_INVALID_WINDOW_HANDLE`）**不影响任何既有场景**；
  ① 原样保留（`target = wpf_thread_self();` 那行**一字未动**）。**结论：(B) 落地。**

### (A) 具名台账（**不许静默改投**）
```
[POSTMSG_DEAD_TARGET] hwnd=0x200001 owner_thread=(nil) 原因=该窗口的线程已退出 caller_tid=127367341738880
  处理=拒绝投递(return 0 + ERROR_INVALID_WINDOW_HANDLE) **不再改投调用者队列**
  （Win32：窗口线程退出后该 hwnd 已不可用；改投会导致窗口过程在错误线程上执行）
```
`static` ⇒ **不新增导出（导出数仍 547）**；**不受 MSGFLOW 开关限制**；每进程有界 ≤32 行；
判定用的布尔 `owner_dead_in_table` **在锁内取**（解锁后 `w` 可能已被 `DestroyWindow` 释放 ⇒ 悬垂）。

### 四档成对读数（同一腿：真窗口 ＋ 真线程退出 ＋ 真 `PostMessageW`）
| 件 | 返回 | 主队列 | `[POSTMSG_DEAD_TARGET]` | `[QUEUE_CORRUPT]` | rc | 结局 |
|---|---|---|---|---|---|---|
| 基线 `a6365183fa6d26b9`（= 仓内权威件） | — | — | — | — | **139** | **崩** |
| `fixed` `74c359f481614eb3`（F1+F2+F3） | 1 | **+0** | 0 行 | 1 行 | 0 | 消息投进**悬挂队列** ⇒ **事实丢失** |
| `fixed2` `1d64dbdce2ceb06c`（＋F3b） | 1 | **+1** | 0 行 | 0 行 | 0 | **静默改投**调用者队列（可跨线程派发） |
| **`fixed3` `2067cb1c97728791`（＋A＋B）** | **0** | **+0** | **1 行** | 0 行 | 0 | **大声拒绝**（Win32 语义） |

（`grep -c POSTMSG_DEAD_TARGET`：`owner-fixed3.out` = **1**、`owner-fixed2.out` = **0** ⇒ 新行由本次改动带来，非环境噪声。）

### 零回归（fixed3 上复跑）
导出数 **547**｜旧坏链腿 `rc=0`、`[QUEUE_CORRUPT]` 恰 **1** 行｜对照腿 `pushed=200 popped=200 count=0` ✓

### 落仓候选值**再次改写**（取代 §⑪ 的 `1d64dbdce2ceb06c`）
| 件 | 最终候选（fixed3） |
|---|---|
| `src/win32_msg.c` | `12175591b736bb3f` |
| `src/win32_internal.h` | `c13390de6f870999` |
| `src/win32_core.c` | `c66528843de4a370` |
| **`bin/libwpfwin32.so`（件级）** | **`2067cb1c97728791`**（327,672 B，导出 **547**） |
| 完整 diff（3 文件） | `logs/final3.diff` `f20eae90651a1c49`，形状 **＋135 / −14** |
| 腿读数日志 | `owner-fixed3.out` `2e1ec19374edc87c`／`repro-fixed3.out` `a7c2124d3fce2d5f` |

### 待登记候选（**登记归主控**）
> **`PostMessageW` 对"窗口线程已死"的目标返回 1 并把消息改投调用者队列**（可能跨线程派发到一扇属别人线程的窗）。
> 现场件：`win32_msg.c:777-788`（兜底 `target = wpf_thread_self()`）；致命面见 `D-G109`（同一悬垂指针令
> `wpf_queue_push` 静默 SEGV）。本件处置：F3b 置空 `owner_thread` ＋ **(A)** 具名台账 ＋ **(B)** Win32 语义拒绝投递。

### 本节新增 `NOINFO`（逐条）
1. **托管侧（.NET/WPF）对 `PostMessageW` 返回 0 的反应未验证**（本件零 `dotnet`，只到 native 层）；
   机械上只可能发生在"窗口线程已死"这一格。
2. **`[POSTMSG_DEAD_TARGET]` 在真应用中的出现率未取到**（只在构造腿上取到 1 行）。
3. **定时器那一半（`g_wpf.timers` 的 `owner_thread`）仍无读数**（§⑪ 已记）。
4. **(B) 的保守回退配方**：删掉 `if (owner_dead_in_table) { … return 0; }` 这 4 行即可回退到"改投调用者队列"，
   **(A) 的台账行保留**（届时它变成"即将改投"的告警）。

---
## ⑭ 已落仓（主控放行后执行；守卫式：三条自证全通过才动手；重建走机器级槽）

**放行三条**（落仓前现场复核）：① `docs/CURRENT-STATE.md:9` = `gen=#54`；② 重活扫描（按 PID 读 `/proc/*/cmdline`）命中 **0**；③ 远端 head ≠ `1b44615b564b5adcafea07fb09eb569599db6834`。
等待窗口的逐行判定与三条现场证据原文见 `logs/landing.log` 的 `POLL ts=… c1=… c2=… c3=… heavy=… head=…`。

**落仓动作**：`sha256sum` 重核三源与沙箱基线**逐位相同** ⇒ 备份 `$HOME/w136a/backup-landing/` ⇒ `cp` 三件 ＋ `touch`
⇒ 重建（`bash ~/heavy-slot.sh --min-avail 1500 --max-hold 600 --wait 1800 -- bash -c 'cd … && ./build-shim.sh --all'`，**不裸跑**）
⇒ **`cmp` 对沙箱期望件**（不只看 `rc=0`）。

**落仓读数**：见 `logs/landing.log` 的「件级=…／导出=…／CURRENT-STATE:9」三行（现场算，非手抄）。

**`inputs_fp`（真函数 `fp_inputs()` 算）**
- 旧（落仓前）：`5ba630999c60a746aca0ea582ba19324c535cfb4c89be2a6db36683209697365`
- 新（落仓后）：`4e9c2dbe320cac27d99aff02066db1ac49fa119e2ca98c77caf5dd2dc4ba3e42`

**`repin-generation.py`**：`--why` ＋ `--check` ⇒ 结果见 `logs/repin-check.log`（期望 `REPIN_GENERATION=PASS`）。


---

## ⑫ 报告自身哈希：**仓规两行口径都给**

主控独立核过的两行（口径确认无误）——它们对应**本文件更新前的那一版**（277 行 / 18,893 B）：
```
sha256sum $HOME/w136a-report.md                          → 38b3dc395d988930    （FULL）
head -n -2 $HOME/w136a-report.md | sha256sum             → 48ac106b189cf005
head -n -1 $HOME/w136a-report.md | sha256sum             → a5c3b656f78703d8
```
本次追加 §⑪/§⑫ 后**全文件哈希必然改变**（这是全文件自哈希的固有循环性）。故本车道固定采用两个
**可复算且不循环**的口径，命令逐字如下（读者可当场复算）：
```
# 口径甲：正文（§①–§⑪，**不含 §⑫ 本块**）—— 本块内不引用它自身，故稳定
#   head -c 29035 $HOME/w136a-report.md | sha256sum     ← 22871 = §⑫ 起始前的**字节数**（现场量）
# 口径乙：去掉末行（末行即自哈希行，天然不循环）
head -n -1 $HOME/w136a-report.md | sha256sum               → 见本文件末行
```
**正文 sha16（口径甲，现场算）** = `02069430ae5e2418`
报告自身 sha16（口径乙 = `head -n -1 ~/w136a-report.md | sha256sum | cut -c1-16`）= 96dc6f442f95e449
