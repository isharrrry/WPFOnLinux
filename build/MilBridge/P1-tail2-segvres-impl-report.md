# `P1-tail2` · `T-A64` · `TASK-0201` 产品侧静默 `rc=139` 残余（`D-G109`／`TASK-0209`）—— 实现报告（**判决：具名根因清单逐条现取；「可诚实定位者」＝ `wpf_queue_push` 里 F1 的**同根因另一半**（`tail≠NULL` 而非合法节点指针）⇒ 确定性静默 SEGV，已修＋两极化；其余（`D-G109` 偶发同因／「谁写坏 `next`」／`TASK-0211` 可利用性）如实划界 `NOINFO`；`nm==exports`／`PTSGAP=PASS`／`DEFREG`／`REPORTID`／`HANDOFF_MV` 全 `rc=0`；症状门逐格同、三帧 `AE=0`**）

- **读时**：`2026-10-01T18:1x–18:4x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`（**未 `git add/commit/push`**）。
- **改前件备份（仓外 `~/tA64-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_msg.c`（`4a88fffb1a0cd7f1`）／`bin/libwpfwin32.so`（`2197fd72497619fb`，490248 B）／`bin/exports.txt`（`20b6d9aa3125bbc4`）／`tools/pts-gap-decl.txt`（`12778c62c4dc153f`）／`build/MilBridge/HANDOFF-NEXT.md`。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_msg.c`（**`wpf_queue_push` 加 `tail` 零解引用守卫**，F1 的**同根因另一半**）／`src/WpfGfx.Linux.Native/bin/{libwpfwin32.so,exports.txt}`（**构建重产**，非手改）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行 `so16` 跟权威件换 ＋ dated `T-A64` 重锚追注）／**复述位现值位**（`build/MilBridge/HANDOFF-NEXT.md`：文件尾只增一条 `cell=#1／cell=#3` 机器值契约更正行）／**新建载体** 本件。
- **未改**：`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（**本趟无计数变化，不改现值位**；其中 `ROUTES.md` 的 `win32_msg.c 4a88fffb1a0cd7f1` 是**dated 历史引文**，见 §6-5）／`tests/queue_corrupt_chain_fixture.c`（**一字未动**，复现夹具置于仓外 `/tmp`）。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`upstream/**`／`samples/**`；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**3 趟 native 构建**（主链 1 ＋ 复核 2）＋ **5 趟跑器**（`before`／`after`／`before2`／`after2`／`after` 首趟），全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=RELEASED rc=0`）；进程只按 PID；显示位只用空闲 `:231/:232/:233/:234`；禁 `sleep` 轮询；写前 `cp -p`；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／夹具 `gcc` 直编直跑／`bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check}.sh`）。

---

## §0 结论速览（自包含）

1. **① 具名根因清单（逐条现取，件:行见 §1）**：`D-G109`＝`win32_internal.h:383-401`（`sizeof(wpf_thread)==sizeof(wpf_msg_node)==64` 的**类型混淆**）＋ `win32_msg.c` 的 `wpf_queue_push` 链解引用；`TASK-0209`＝`win32_msg.c:47-72`（F2 具名台账）＋ `:125-151`（F1 零解引用隔离分支，**已落地·随波 `#55`**）；`TASK-0211`＝`win32_msg.c:852-914`（站点 A）／`:918-949`（站点 B）／`win32_core.c:147-161`（第 3 处 fd，**已落地·W146A**，可利用性未证）。**处置状态**见 §1 表。
2. 🔴 **② 可诚实定位者（本趟唯一修法）**：`D-G109` 的同一类型混淆还有**另一半**——`sizeof` 相同 ⇒ 已 free 的线程块被复用成消息节点，按 `wpf_thread` 视图读得 `tail(@16) = msg.wParam`；**`wp≠0`** 时 `tail` 非空却指着**根本不是节点的值** ⇒ 旧实现 `if (t->tail) t->tail->next = n;`（改前 `win32_msg.c:102-103`）解引用坏指针 ⇒ **确定性静默 SEGV（一行台账都没有）**。F1 只堵了 `tail==NULL` 那一支 ⇒ **本趟把 F1 的零解引用形态判据对称地用到 `tail` 上**（改后 `win32_msg.c:102-124`：非法即隔离 ＋ 具名 `[QUEUE_CORRUPT] 原因=tail 非合法节点指针`）。
3. ✅ **确定性复现（先复现、再修、再证伪）**：夹具注入 `head=NULL, tail=0x102` ⇒ 反腿（**修前件** `2197fd72497619fb`）`rc=139`＋`T64_SEGV si_addr=0x13a`（`0x102+0x38`，**静默、无台账**）；正腿（**本案** `969536ee1549ef39`）同一注入 ⇒ `rc=0`＋`[QUEUE_CORRUPT] … 原因=tail 非合法节点指针（链已不可信） … 对策=隔离可疑链(零解引用)+本条消息照常入队`＋`T64_SURVIVED count=1`。**正常路径**（`push×3`）两件同：`count=3 msg=[0x200,0x201,0x202] tail_next_null=1`（**不改变正常语义**）。
4. ✅ **门禁全绿**：`nm==exports`（718，逐名 `diff` 零差异）｜`PTSGAP=PASS tool=59 dead=11 artifact=1 ops=47 impl=47 so16=969536ee1549ef39 exports=718`（`rc=0`）｜`DEFREG=PASS declared=225 route_ids=225`（`rc=0`）｜`REPORTID=PASS files=340 ids=2247`（`rc=0`）｜`HANDOFF_MV=PASS cells=9 equal=8 manual=1`（`rc=0`）｜`PTS_GUARD=PASS legs=2/2`／`PTS_ENFE=PASS total=0`／`PTS_COLORANCHOR=PASS hits=3`／`PTS_N1_GATE=PASS`。
5. ✅ **症状门 ＋ 帧面成对（只差 `.so`）**：腿 `before`（旧 `.so 2197fd72497619fb`）与 `after`（新 `.so 969536ee1549ef39`）**三帧逐字节相同**（`AE=0`：`boot b21eb530afd3c66c`／`k23 10d0b9d54e649c10`／`k24 0bdb2dfd05952bc9`）、症状门逐格同（`alive=yes／app_rc=143／magenta=0／ink=480000／colors 1220/636／ae 220019/136292`）。
6. 🔴 **③ `SILENT_SEGV_HIT` 率**：逐字口径见 §3；**本趟未跑**整批应用腿 ⇒ **无新率**（具名 `NOINFO`）；在册现件代读数 `0/300 ⇒ 0.993608%`（`t204`，私有扩展 `trim` 口径）／`0/175 ⇒ 1.6973%`（`t44`/`t7`，在册口径）。本趟新增的是**确定性夹具层面**的命中形态（tail 注入 = 命中 ⇒ 修复后不命中），**不是率**。
7. ⚠️ **不宣称**「产品侧静默 `rc=139` 已清零」：`D-G109` 的「偶发 `1.14%` 是否同因」／「谁写坏 `next`」仍 `NOINFO`；`TASK-0211` 的窄 `TOCTOU` **另计**；「`tail` 假合法而 `head` 坏」这一**未观测形态**本趟**不冒充**（见 §6）。

---

## §1 ① 具名根因清单（**逐条现取，件:行**；行号**仅本次有效**）

| 号 | 指向的件:行（现取） | 形态（逐字要点） | 处置状态（现取） |
|---|---|---|---|
| **`D-G109`** | 在册条目 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2896`（标题）｜**类型混淆** `src/WpfGfx.Linux.Native/src/win32_internal.h:383-401`（`typedef struct wpf_msg_node` ＋ `_Static_assert(sizeof(wpf_msg_node)==64)`）｜**崩点** `src/WpfGfx.Linux.Native/src/win32_msg.c:126-151` 的注释里逐字留着旧实现（`:129` `while (p->next) p = p->next;` ←崩点） | `.NET Finalizer` 线程里 `HwndWrapper::Finalize()` → P/Invoke → `PostMessageW` → `wpf_queue_push` 链遍历踩坏指针 ⇒ **进程静默死（应用 0 字节输出）**；`si_addr = p+0x38`（字段可采信，`t45` dated 更正） | **🟡 仍红**（**只对「异源＋残余」那一半成立**，与 `TASK-0203` 的测量交付**分开记账**） |
| **`TASK-0209`** | **F2 具名台账** `win32_msg.c:47-72`（`wpf_queue_corrupt_report()`，`static` ⇒ 不新增导出）｜**F1 隔离分支** `win32_msg.c:125-151`（`else if (t->head)` ⇒ **零解引用** ＋ 具名 `[QUEUE_CORRUPT]`）｜源件（改前）`sha16=4a88fffb1a0cd7f1` | 队列链遍历**禁止再走链**：可疑链**隔离登记**（有界、具名、可归因），本条消息照常入队成干净单节点 ⇒ 不崩 ∧ **不静默丢件** | **✅ 已落地**（随波 `#55` 冻结并推送；`ef1dc8f`；`~/w136a/LANDED.done`；`§15w` 写 `🔴→✅`） |
| **`TASK-0211`** | **站点 A** `win32_msg.c:852-914`（`PostMessageW`：**唯一一次放锁在 `push` 之后**）｜**站点 B** `win32_msg.c:918-949`（`PostThreadMessageW` 同形）｜**第 3 处（fd）** `win32_core.c:147-161`（`wpf_thread_destroy` **锁内置 `-1` 再 `close`**） | 「查表→判死→取 `pt`→入队」同一临界区；消除「读到 `owner_thread`（非空）↔ 该线程退出并 `free(t)`」的**微秒级窗口** | **✅ 已落地**（W146A）｜⚠️ **可利用性 = `NOINFO`（另计）**；修法**只靠递归锁计数成立**（前提由仓外 `~/w146a/bin/premise.py` 盯） |
| **🆕 `T-A64` 本轮** | **`win32_msg.c:102-103`**（改前）：`if (t->tail) { t->tail->next = n; }` —— **未对 `t->tail` 做零解引用形态判据** | **`D-G109` 同根因的另一半**：`tail = msg.wParam`（`wp≠0`）⇒ `tail` 非空却非节点 ⇒ 解引用 `tail+0x38` ⇒ **确定性静默 SEGV** | **✅ 本趟修**（见 §2；`win32_msg.c:102-124`） |

> **三件的「指向」与 `D-G109` 的关系**：`D-G109` 是**本体**；`TASK-0209` 修它的**现场形态**（`tail==NULL ∧ head!=NULL`）；`TASK-0211` 修**同族（`wpf_thread*` UAF）但异窗口**（锁缝）。本趟补的是**本体里 F1 未覆盖的那一支**。

---

## §2 ② 可诚实定位者：修法（先复现、再修、再证伪）

### 2.1 改动（逐处）

**`win32_msg.c` 的改动（改后 `:102-124`，逐字）**：

```c
    uintptr_t tv = (uintptr_t)t->tail;
    int tail_bad = t->tail && !((tv >= 0x10000u) && ((tv & 0xFu) == 0));
    if (tail_bad) {
        wpf_msg_node *quarantine = t->tail;      // 只记指针，**绝不解引用**
        n->next = NULL;
        t->head = n;
        t->tail = n;
        wpf_queue_corrupt_report(t, quarantine, m->message,
                                 "tail 非合法节点指针（链已不可信）");
    } else if (t->tail) {
        t->tail->next = n;
    } else if (t->head) {          /* ← F1 原文，一字未动（含其台账文案） */
```

- **判据与 F1 同款、同强度**：`≥0x10000 ∧ 16 字节对齐`（malloc 指针在 x86-64 必然满足）⇒ **零解引用**。「只加空指针守卫」被**明令禁止**（同 F1：那会把「链被写坏」降级成「静默丢消息」）。
- **最小侵入**：F1 分支**原文保留**（`corrupt` 夹具的台账文案 `tail==NULL 而 head!=NULL` 逐字不变，见 §2.3 第 4 行）——守卫**只**在 `tail` 非空且非法时先手拦截。
- **不改变正常语义**：正常队列 `tail` 恒合法 ⇒ 走 `else if (t->tail)` 原路径（§2.3 第 3 行）。

### 2.2 复现命令（**零槽、零 X、零 `dotnet`**；夹具在仓外 `/tmp/tA64-work/tail.c`）

```bash
R=/home/links-dev/netTest/GitProj/WPFOnLinux/src/WpfGfx.Linux.Native
# 反腿：对**改前件**链接
cp -p ~/tA64-work/bak/libwpfwin32.so /tmp/tA64-work/oldlib/libwpfwin32.so
gcc -std=gnu11 -O1 -I$R/src /tmp/tA64-work/tail.c -o /tmp/tA64-work/tailfix_old \
    -L/tmp/tA64-work/oldlib -lwpfwin32 -Wl,-rpath,/tmp/tA64-work/oldlib -ldl -lpthread
unset DISPLAY; /tmp/tA64-work/tailfix_old tail 0x102 ; echo "rc=$?"
# 正腿：对**改后件**链接
gcc -std=gnu11 -O1 -I$R/src /tmp/tA64-work/tail.c -o /tmp/tA64-work/tailfix \
    -L$R/bin -lwpfwin32 -Wl,-rpath,$R/bin -ldl -lpthread
unset DISPLAY; /tmp/tA64-work/tailfix tail 0x102 ; echo "rc=$?"
```
（`tail.c` 只做三件事：`t.head=NULL; t.tail=(wpf_msg_node*)P; wpf_queue_push(&t,&m);`。）

### 2.3 修前／修后成对读数（**单变量：只换 `libwpfwin32.so`**）

| # | 注入 | **反腿**（修前 `2197fd72497619fb`） | **正腿**（本案 `969536ee1549ef39`） |
|---|---|---|---|
| 1 | `head=NULL, tail=0x102` | `rc=139`｜`T64_SEGV si_addr=0x13a si_code=1`（**无 `[QUEUE_CORRUPT]`**） | `rc=0`｜`[QUEUE_CORRUPT] 站点=wpf_queue_push 原因=tail 非合法节点指针（链已不可信） 可疑链头=0x102 形态判据=**必非节点指针**（低值/未对齐…） 对策=隔离可疑链(零解引用)+本条消息照常入队`｜`T64_SURVIVED count=1 head==tail` |
| 2 | `head=NULL, tail=0x1`（`wp=1` 复用形态） | `rc=139`｜`T64_SEGV si_addr=0x39` | `rc=0`｜同上（`可疑链头=0x1`） |
| 3 | 正常 `push×3` | `T64_NORMAL count=3 msg=[0x200,0x201,0x202] tail_next_null=1` | **同**（逐字相同） |
| 4 | 仓内夹具 `corrupt 0x102`（F1 形态：`head=0x102,tail=NULL`） | `rc=0`｜`[QUEUE_CORRUPT] … 原因=tail==NULL 而 head!=NULL（链已不可信）`＋`T10_SURVIVED` | **同**（F1 原文案**逐字保留**） |

### 2.4 反极性（**该红必红**；防假绿）

- **反极 A（假绿探测）**：把 `tail` 守卫**摘掉**（＝回到修前件 `2197fd72497619fb`）⇒ 判据**变红**（`rc=139`＋静默，第 1/2 行）。✓
- **反极 B（正常语义不破）**：正/反两件的正常路径读数**逐字相同**（第 3 行）⇒ 守卫**没有**误伤正常队列。✓
- **反极 C（既存修法不被扰动）**：F1 形态（第 4 行）在**两件**上都 `rc=0` 且台账文案**逐字相同** ⇒ 本趟没动 `TASK-0209` 的既有行为。✓
- **反极 D（注入点即崩点）**：`si_addr` 随 `P` **逐位跟随**（`0x102→0x13a`、`0x1→0x39`，恒 `P+0x38`，与 F1 崩点同一条指令 `mov 0x38(%rax),%rax`）⇒ **确系同一根因**、不是造出来的另一处。✓

---

## §3 ③ `SILENT_SEGV_HIT` 口径与率（**逐字**）

### 3.1 逐字口径（现取；出处两处，**只引用、不重写**）

- **实现本体（唯一）** `build/MilBridge/tools/silent-hit-v2-check.sh` 的 `judge()`，现取 `:85-105`：
  > `c1 = (trimmed == 0); c2 = (so == 0); c3 = (br in BRANCHES)`｜`BRANCHES = ("rc139","fate","term","stop-signo11")`；两条**前置闸**：`undeclared != 0 ⇒ NOINFO(undeclared-instrumentation)`／`phase == "teardown" ⇒ NOINFO(teardown-death-not-a-hit)`。
- **在册散文形态** `docs/ROUTES.md:243`（`TASK-0203` 子树口径句，逐字）：
  > `SILENT_SEGV_HIT ⇔ 应用输出 == 0 B（剔 timeout: 行）∧ STACKOVF == 0 ∧ 死于 SIGSEGV（RC==139 ∨ APP_FATE 含 SIGSEGV ∨ gdb.txt 含 "Program terminated with signal SIGSEGV" ∨ gdb.txt 存在 W118A-STOP-N(N≥1) 且 signo=11）` —— 末支抗收尾截断。
- **机读形态** `docs/ROUTES.md:229`（`TASK-0201` 行内）：`SILENT_SEGV_HIT ⇔ APP_TEXT_BYTES_TRIMMED==0 ∧ STACKOVF==0 ∧ SEGV_BRANCH!=none`。

### 3.2 现件代率（**本趟未跑整批 ⇒ 无新率，如实记**）

| 口径 | 现件代读数（在册，**只对本装置**） | 备注 |
|---|---|---|
| 私有扩展 `trim` 口径 | **`0/300 ⇒ 95% 单侧 0.993608%`**（`t204`／`T-C2`，现件 `.so 26da177686acb1f0`） | 跨过在册 1% 门 |
| **在册 `trim` 口径** | **`NOINFO reason=empty-denominator`**（同批 300 腿 `undeclared=18/腿`，tag `[E3-REPLAY]` **当时未声明** ⇒ 分母 0） | 现取 `silenthit-trim.tsv` **已含** `[E3-REPLAY]`（`8f93be10a5ca57f5`）⇒ **该阻断已消**，但**未重跑取证** |
| 老口径（`t44`/`t7`） | **`0/175 ⇒ 95% 单侧 1.6973%`** | 任务书所引上界 |

- 🔴 **本趟新增的是「命中形态」的确定性复现/消除，不是「率」**：`tail` 注入（`head=NULL,tail=0x102`）在修前件上满足**该口径全三支**（`trimmed=0` ∧ `stackovf=0` ∧ `branch=rc139`，应用输出 0 B）⇒ **是一个 `SILENT_SEGV_HIT` 的确定性触发子**；修复后同一注入 **不满足**第三支「死于 SIGSEGV」。
- ⚠️ **`NOINFO（具名）`**：本趟**未**跑「起 X ＋ 起应用 ＋ 9 击配方」的整批腿（≥131／299／300 腿 ⇒ 数槽小时）⇒ **拿不出新率**；**不许**用近似读数凑绿。`T-A60` 已闭装置侧可比时间窗，率仍归 `TASK-0201`／`TASK-0212` 那条线。

---

## §4 ④ 门禁（现取，逐条给 `rc`）

| 门 | 读数 | rc |
|---|---|---|
| **`nm==exports`** | `nm -D --defined-only` ＝ **718** ＝ `exports.txt` 行数；逐名 `diff` **零差异** | 0 |
| **`PTSGAP`** | `PASS tool=59 dead=11 artifact=1 ops=47 impl=47 so16=969536ee1549ef39 exports=718`（`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`）；`DISK_HEADROOM=PASS` | 0 |
| **`DEFREG`** | `PASS declared=225 route_ids=225`（`DECLDRIFT=0 keys=-`；本趟**未改任何 route 件**） | 0 |
| **`REPORTID`** | `PASS files=340 ids=2247 declared=225` | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0`（本趟只增一条 `cell=#1／cell=#3` 更正行） | 0 |
| `PTS_GUARD` | `PASS legs=2/2 fails=- cannot=- diag=leg24-colors-out-of-band=1220,leg23-colors-out-of-band=636` | 0 |
| `PTS_COLORANCHOR` | `PASS k=24 hits=3`（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`） | — |
| `PTS_ENFE` | `PASS total=0 by_name=none` | — |
| `PTS_N1_GATE` | `PASS phase=realized positive=differ(via=compare)` | — |

> `PTSGAP` 改前现取为 `FAIL`（`DRIFT so16 decl=2197fd72497619fb live=969536ee1549ef39`）⇒ 本趟**同趟更新** `tools/pts-gap-decl.txt` 的 DECL 行 `so16` 后转 `PASS`（见 §2.1 与 §7）。

---

## §5 ⑤ 症状门成对 ＋ ⑥ 帧面成对（**同装置；只差 `.so`**）

- 腿跑器：`build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh <证据目录>`（每腿 `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`；`POSTSHIM: shim=… pf=1c6c58df6d757f3f（== authority ⇒ 读数可归因）`）。
- 证据目录：`~/tA64-work/legs/{before,before2,after,after2}/`。

| 量 | **`before2`**（旧 `.so 2197fd72497619fb`，`:233`） | **`after2`**（新 `.so 969536ee1549ef39`，`:234`） |
|---|---|---|
| `leg_24` | `alive=yes app_rc=143 magenta=0 colors=1220 ns=…FlowDocumentDemo ae=220019 ink=480000` | **同**（逐格相同） |
| `leg_23` | `alive=yes app_rc=143 magenta=0 colors=636 ns=…RichTextBoxDemo ae=136292 ink=480000` | **同** |
| `FAILLINE` | `failfast=0 unrec=0` | **同** |
| `NAMED` | `managed_unavail=0 native_gap=0 native_err=-` | **同** |
| `[QUEUE_CORRUPT]` 命中 | **`0`** | **`0`**（守卫**全程未触发** ⇒ 正常路径零足迹） |
| `[E3-REPLAY]` 行数 | `4` | `4` |

**帧面成对（只读 PNG，逐件 `sha16`）**：

| 帧 | `before2` | `after2` | `AE` |
|---|---|---|---|
| `boot.png` | `b21eb530afd3c66c` | `b21eb530afd3c66c` | **0** |
| `k23.png` | `10d0b9d54e649c10` | `10d0b9d54e649c10` | **0** |
| `k24.png` | `0bdb2dfd05952bc9` | `0bdb2dfd05952bc9` | **0** |

- ⇒ **队列守卫在产品路径上零位移**（这正是本节要证的事，不是"没测"）。**装置确定性对照**：`before`（`:231`）与 `before2`（`:233`）两趟**逐字相同** ⇒ 同 `.so` 可复现。

---

## §6 主动披露 / `NOINFO` / 边界（逐条）

1. 🔴 **装置一次偶发非确定性（如实）**：本席**首趟** `after`（`:232`）读到 `colors 1219/635`＋`k23 fr_sha=94933b5a37d1c537`（与旧件不同）；同 `.so` 重跑 `after2`（`:234`）**复现**旧件值（`1220/636`、`10d0b9d54e649c10`）⇒ 该首趟为**装置偶发**、**非本修法所致**（守卫全程 `[QUEUE_CORRUPT]=0`）。本报告**以 `before2`／`after2` 这一对为成对读数**（`AE=0`），首趟作为**已披露的异常样本**保留在 `~/tA64-work/legs/after/`。
2. 🔴 **`NOINFO`（具名，逐条）**：
   - **`NOINFO reason=heavy-legs-not-run`**：本趟**未跑** `SILENT_SEGV_HIT` 整批应用腿 ⇒ **无新率**（§3）。
   - **`NOINFO`**：`D-G109` 的「**偶发 `1.14%` 是否与确定性形态同因**」—— 在册未闭（判别量＝「崩掉那趟里到底有没有 `wpf_thread_destroy`」）；本趟**未取到新证据**。
   - **`NOINFO`**：「**谁写坏 `next`**」—— 在册未取证；本趟**未动**。
   - **`NOINFO`**：`TASK-0211` 两处窄 `TOCTOU` 的**可利用性** —— **另计**（任务书明示）；本趟**只引用**其落地事实与「前提靠递归锁」的限制。
   - **`NOINFO`**：「**`tail` 假合法（≥0x10000 ∧ 16 对齐）而 `head` 坏**」—— **未观测形态**；本守卫**只覆盖 `tail`**，该形态**不冒充**（如需另立夹具取证）。
3. **F2 的 `magic` 字段仍「只写不读」**（现取 `grep -n '->magic' win32_msg.c` ⇒ 仅 `:96` 写入）：本趟**不**用 magic 做校验 —— 因为**校验需解引用**，对非规范/未映射指针会崩；形态判据（零解引用）才是 F1 既定的安全口径。**如实登记**为「`F2` 的取证字段待有读者」，**不新号**。
4. **本趟只覆盖现件 `shim`**：腿上 `PresentationFramework.dll`(`pf`)＝`1c6c58df6d757f3f`（＝仓 Release，`POSTSHIM` 自证）；`bin/libwpfwin32.so`／`bin/exports.txt` **不在 git**（本地物件），`so16` 与哨兵 `WIN32SHIM` 在**冻结波**才会同步。
5. ⚠️ **`docs/ROUTES.md` 的 `win32_msg.c 4a88fffb1a0cd7f1` 未改**：那是 `TASK-0209` **落地那一刻**的 dated 历史引文（`ROUTES.md:243`），**不是现值位**；本趟改后 `win32_msg.c` 现取 `2ff25905778edeb9`。⇒ 若后人要求"现值位"对拍，须以本行 `ts` 为准（**本趟不越域改 route 件**）。
6. **本趟未做**：整趟 `verify-all`／`close-wave`／任何 `dotnet` 构建／`git add/commit/push`；`tests/queue_corrupt_chain_fixture.c` **一字未动**（复现夹具置于仓外 `/tmp`）。

---

## §7 复算命令（逐条可重放）

```bash
R=/home/links-dev/netTest/GitProj/WPFOnLinux; cd "$R"
# 件位（现取）
sha256sum src/WpfGfx.Linux.Native/src/win32_msg.c | cut -c1-16                          # 2ff25905778edeb9
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16                        # 969536ee1549ef39
sha256sum src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt | cut -c1-16                    # d78e5b0c65dc1e89
# 构建（改后）
bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- \
  bash -c 'cd src/WpfGfx.Linux.Native && ./build-shim.sh --symbols'
# 夹具两极化
gcc -std=gnu11 -O1 -Isrc/WpfGfx.Linux.Native/src /tmp/tA64-work/tail.c -o /tmp/tA64-work/tailfix \
    -Lsrc/WpfGfx.Linux.Native/bin -lwpfwin32 -Wl,-rpath,$PWD/src/WpfGfx.Linux.Native/bin -ldl -lpthread
unset DISPLAY; /tmp/tA64-work/tailfix tail 0x102; /tmp/tA64-work/tailfix tail 0x1; /tmp/tA64-work/tailfix normal
# 腿（before/after，走槽）
bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- bash ~/tA64-work/legs-before.sh
bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- bash ~/tA64-work/legs-after.sh
# 门禁
bash build/MilBridge/tools/pts-gap-count-check.sh | tail -1
bash build/MilBridge/tools/defect-registry-check.sh | tail -1
bash build/MilBridge/tools/report-id-domain-check.sh | tail -1
bash build/MilBridge/tools/handoff-machine-values-check.sh | tail -1
bash build/MilBridge/tools/pts-pages-guard.sh --legs ~/tA64-work/legs/after2 | grep -E '^PTS_(GUARD|ENFE|N1_GATE)|^PTS_COLORANCHOR=PASS'
nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | sort > /tmp/nm.txt
diff /tmp/nm.txt <(sort src/WpfGfx.Linux.Native/bin/exports.txt) && echo "nm==exports OK"
```

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-segvres-impl-report.md | sha256sum | cut -c1-16`）= `76a8666a0f68c637`
