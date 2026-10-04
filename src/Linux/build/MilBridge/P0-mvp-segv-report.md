# P0-mvp-segv-report —— `TASK-0201` 重取 ＋ 零槽确定性夹具两极化（`t10`）

> **一句话**：**契约的第一项（"先落地 `TASK-0209` 的产品修法"）在现树上已经没有对象** —— 修法 2026-09-23 随波 `#55` 落树、`#57` 补 `TOCTOU`，`#79` 已冻结并推送。本件据实改判：**不重做已落地的修法、不代跑别人的整波链**，改为交付**真正还开着的那一格** —— **零槽确定性夹具两极化**（真跑，硬证据在下 §2），并给出 `TASK-0201` 应用级重测的**就绪设计**（§4，需槽，本件不跑）。
> **报告自报 sha16**：见末行 `SELF-SHA16`（口径＝`head -n -1 | sha256sum | cut -c1-16`）。
> **读取时刻**：全部读数现取于 **2026-09-28 01:5x–02:0x**（`#79` 冻结 `2026-09-28 01:12:39` 之后）。

---

## §0 前提更正（**本件最重要的一格**）

| 契约要求 | 现树事实（现取，附证据） | 判定 |
|---|---|---|
| "**先落地 `TASK-0209` 的产品修法**（判定点 `win32_msg.c` 约 `:57-82` 的 `while (p->next) p = p->next;`）" | `src/WpfGfx.Linux.Native/src/win32_msg.c` 里**该遍历已不存在**：`grep -n 'while (p->next)'` ⇒ **唯一命中在 `:108` 的注释**（逐字留着旧实现供后人读）；F1 零解引用隔离分支在 **`:102-128`**、F2 具名台账 `[QUEUE_CORRUPT]` 在 **`:56-71`**；件级 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **`e8127a3d7128d417`**（＝ `#79` 冻结的 `win32shim` 值） | **已落地** ⇒ 本件无对象 |
| "**整波链走到底** ⇒ … ⇒ **冻结新代** ⇒ 推送 ⇒ 两哨兵" | `docs/CURRENT-STATE.md:9` = **`BASELINE-FROZEN gen=#79 sha16=901619543b3d913b`**；`#79` 已由波内车道冻结、冻后两趟各 `55 ❌ 0`、推送 `6a245bd`（本地==远端）、两哨兵 `cmp IDENTICAL`（见 `t23`／`t24` 交件） | **已做过**，且**不是本件的写域**（串行纪律：整波链归主控/`waveman`） |
| "**`TASK-0201` 按在册口径重测**（上界收紧；`≥131 腿`＝2.26%／`≥299 腿`＝1.00%）" | `docs/ROUTES.md:205` 仍 `🟡`，读数是**修前件代**的 `15` 趟零命中、上界≈`20%`；`TASK-0203` 的同族上界为 `2/175 ⇒ 3.55%` | **真·开口**，但**要跑应用＋两条腿 ≈1.6–2.7 槽小时** ⇒ 需主控派槽（本件**未跑**） |
| 报告路径 `build/MilBridge/P0-mvp-segv-report.md` | 本件落仓前**不存在**；该路径**不在** `fp_inputs()` 覆盖面（`infp.sh list` 命中 **0**） | 落仓（本文件） |

**⇒ 本件的处置**：**不重做已落地的产品修法**；把本件缩到「**验**」这一半，并**只做零槽、零足迹**的那部分（下述 §2 已做完），把需要槽的 `TASK-0201` 应用级重测**留成一份可直接照做的设计**（§4）。

---

## §1 零槽与零足迹（本件自身）

- 全程**未起 X**、**未起应用**、**未跑门禁**、**未占机器级重活槽**；进程只按 PID（未用 `pkill`／`pgrep -f`）。
- 落仓前现取 `bash ~/w153a/bin/infp.sh fp` = **`4c096e9c0705a95d8a2a69617f777df06686e48b8e0ce40ae16eec75e095f180`**，覆盖面 **225**（＝ `#79` 冻结后的同一值）⇒ **本件的夹具与读数**（只落 `/tmp` ＋ 本报告）**不动 `inputs_fp`**（本报告不在覆盖面；夹具在 `/tmp`）。

---

## §2 交付物①：**零槽确定性夹具两极化**（真跑）

### 2.1 夹具（**逐字**，落 `/tmp/t10-qcorrupt.c`，sha16 **`c4ce076eadf0fa4b`**）

坏链注入的**最小形态**取自在册判词的机制（`D-G109`：`sizeof(wpf_thread)==sizeof(wpf_msg_node)==64` ⇒ 已 `free` 的线程结构被复用成消息节点 ⇒ 按 `wpf_thread` 视图读得 `head = msg.message = 0x0102`、`tail = msg.wParam = 0`）：

```c
/* t10 · 零槽确定性夹具：坏链（head=0x102 ∧ tail=NULL）注入 ⇒ 两极化
   ⚠️ 只读仓内头文件、只链接既有 .so；不写仓、不起 X、零 dotnet。 */
#include <stdio.h> … #include "win32_internal.h"
void wpf_queue_push(wpf_thread *t, const WPF_MSG *m);
int  wpf_queue_count(wpf_thread *t);
/* SIGSEGV 处理器：直接印 si_addr（这样可以**逐位校准**故障地址，见 §3） */
int main(void) {
    static wpf_thread t;  t.wake_read = -1; t.wake_write = -1;
    WPF_MSG m; memset(&m, 0, sizeof m); m.message = 0x0102; m.wParam = 0;
    t.head = (wpf_msg_node *)(uintptr_t)0x102;   /* 消息号当指针 ＝ 现场崩点形态 */
    t.tail = NULL;
    wpf_queue_push(&t, &m);                      /* ← 修前件在此崩、修后件在此隔离并照常入队 */
    fprintf(stderr, "T10_SURVIVED count=%d head=%p tail=%p next=%p\n", …);
    return 0;
}
```
编译（**单变量**：同一份夹具，**只换 `.so`**）：
```
gcc -std=gnu11 -O1 -I<repo>/src/WpfGfx.Linux.Native/src /tmp/t10-qcorrupt.c -o /tmp/t10-<v> \
    -L<so-dir> -lwpfwin32 -Wl,-rpath,<so-dir> -lX11 -ldl -lpthread
```

### 2.2 两极化读数（**真跑，逐字**）

| 臂 | `.so`（sha16） | 读数 | rc |
|---|---|---|---|
| **修前（＝"还原旧件"腿）** | **`abf6879c027c5e73`**（`~/w128a/app-P/libwpfwin32.so`，**在册历史红臂本体，逐位相同**） | **`T10_SEGV si_addr=0x13a`** | **139** |
| **修后（现件代）** | **`e8127a3d7128d417`**（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`） | `[QUEUE_CORRUPT] 站点=wpf_queue_push 原因=tail==NULL 而 head!=NULL（链已不可信） 线程队列=… 可疑链头=0x102 形态判据=**必非节点指针**（低值/未对齐 ⇒ 类型混淆或运行期被写坏） 触发消息=0x0102 … 对策=隔离可疑链(零解引用)+本条消息照常入队` ＋ `T10_SURVIVED count=1 head=… tail=… next=(nil)` | **0** |

两臂可执行件 sha16：`/tmp/t10-pre` = **`6900125fd07acb02`**、`/tmp/t10-post` = **`ae0bd56dbbd675d6`**。

**逐条判据（先写后跑）**
1. **"还原 ⇒ 旧 `.so` 逐位相同、命中重现"**：成立 —— 修前臂用的就是**在册红臂件本体**（`abf6879c027c5e73`），**未做任何还原动作即逐位相同**，且**命中重现**（`rc=139`）。
2. **"修前成对件 ⇒ 命中必现"**：成立，且是**确定性**的（不是概率）—— 同一夹具、同一相位、连续运行读数一致。
3. **"修后 ⇒ 不现"**：成立（`rc=0`，无 SIGSEGV）。
4. **"修法不是只加空指针守卫"（在册硬要求）**：**机器证** —— 修后件**既没崩、也没静默丢件**：`count=1`、`head==tail`、`next=(nil)`，并**打出具名台账** `[QUEUE_CORRUPT]`（含 `形态判据=**必非节点指针**`、`上次写队列: seq=1 tid=…`）。空指针守卫形态会**静默丢件且无台账** ⇒ 与本读数**不相容**。
5. **每格检测力（`D-G116`）**：**有**（确定性、单变量、两臂各真跑）。

---

## §3 🔴 我推翻了哪句话（**对在册判词的更正**）

**在册 `D-G109` 逐字写着**：「⚠️ **不许把 `siaddr=0x0` 当依据**：该字段与指令语义不符（`mov 0x38(%rax),%rax` 的故障地址应是 `p+0x38`，且入口与循环都已排除 `p==NULL`）⇒ **本号判词不依赖 `siaddr`**」。

**本件证伪了"该字段与指令语义不符"这半句**：坏链注入时（`p = 0x102`）现读 **`si_addr = 0x13a`** —— **恰好 `= 0x102 + 0x38 = p + offsetof(next)`**，也就是 `mov 0x38(%rax),%rax` 的**故障地址逐位正确**（`0x38 = offsetof(wpf_msg_node,next) = 56`，与在册反汇编口径一致）。
⇒ **正确判词应当是**：`siaddr` **语义正确、可采信**；而在册 `W071`／`W077` 的**三次停止点全报 `0x0`** 是**记录层坏**（`D-G104` 同族："两份读数都要给，别把读不出来的当不存在"），**不是**"这个字段没有意义"。
⇒ **建议处置**（不在本件写域，交主控）：把 `D-G109` 那句从「不采信」改成「**字段可采信，但在册那三格是记录层坏**」，并把本夹具的**两极化校准**（`p=0` ⇒ 预期 `si_addr=0x38`、`p=0x102` ⇒ `0x13a`）作为该字段的**稳定判据**入册。（本件只跑了 `p=0x102` 一支；`p=0` 那一支**未跑** ⇒ 见 §6 `NOINFO`。）

---

## §4 交付物②：`TASK-0201` 应用级重测**就绪设计**（**本件未跑**，需槽）

判据件（先写、已存在）：`~/w2-segv-a/criteria.md` sha16 **`16b42789baa53f27`**（本会话 `t3` 交件；含逐字判别式、剔除集口径、功效表、两腿检测力、止损六格）。

**① `SILENT_SEGV_HIT` 逐字判别式（只引用，不重写）**：`应用输出 == 0 B（剔 timeout: 行 ∧ 剔应用自报插桩行 [HC-UNHANDLED] #N）∧ STACKOVF == 0 ∧ 死于 SIGSEGV`；**两个数都印**（原始＋剔除后）；**跨件代不混比**（分母按件代分开 ⇒ `abf6879c027c5e73`／`e8127a3d7128d417` 两张表）。

**② 功效与腿数（先写门，现算）**：`ub(0/N) = 1 − 0.05^(1/N)`：

| 目标上界 | 最少腿数 | 该 N 的 ub | 在册锚 |
|---|---|---|---|
| `≤5%` | **59** | 4.9508% | — |
| `≤2%` | **149** | 1.9905% | — |
| **`≤1.0%`** | **299** | **0.9969%** | 在册"`≥299 腿` = 1.00%" ✓ |
| `≤0.5%` | **598** | 0.4997% | 在册"598 趟 ≈ 5.3 槽小时" ✓ |
| （对照） | 131 | **2.2609%** | 在册"`≥131 腿` = 2.26%" ✓ |

**本件建议主档 = `N=175`**：与历史 `2/175` **同 N** ⇒ 同体制可比（`D-G116`）；0 命中时 `ub = 1.6973%`，**严格低于**修前的 `3.5537%` ⇒ 这才是可读的收紧；代价 `175 × 32 s ≈ 1.56 槽小时`（32 s/腿取自 `W128A` 现读：批内实占 `5,880 s`／183 腿）。〔⚠️ **dated 指针（2026-09-28 · 车道 `t50`，读时 2026-09-28T07:39:37+08:00）**：本句的「**同体制可比**」**已由 §13／§14 撤回** ⇒ 正确说法＝**只同 `N`**（两臂四项逐格不同，见 §13①）；本行的「`0 命中时 ub = 1.6973%` **严格低于**修前的 `3.5537%`」**亦不成立**（`3.5537%` 是 `gdb` 臂口径；成对数据下两个上界 ＝ `1.697278%`／`3.815851%`，差值 CI 含 0 ⇒ 两臂分不开）。**本行其余（功效表口径与腿数）保留**：撤回只针对「可比」与「收紧」两处。〕

**③ 两条腿的检测力（**每格必须标**；无检测力的格不许读成绿）**：
- **无 WM 腿**：**有**检测力 —— 历史两个命中（`W071`／`W077`）**都出自无 WM 的 `:185`**（`xprop -root _NET_SUPPORTING_WM_CHECK` = 无此属性）。⇒ 绿只许由这条腿承担。
- **有 WM 腿**：**无**检测力 —— 在册成对读数：有 WM 腿对修前件**点击被吞**（`C2B1/C2B2` 逐击 `AE = 348243, 0, 0, 0, 0, 0, 0, 0` ⇒ 落地 `1/8`、`detect=no`；`WAVE49 §13.4-⑦` 同证）⇒ 那一格 `0/2` **不算数**；本腿判词上限 = `NOINFO reason=no-detection-power`。
- **运行期自证 `WM_PRESENT`**（每腿现取 `xprop -root _NET_SUPPORTING_WM_CHECK`）—— 防 `D-G95`（"自称 WM 腿其实无 WM"）；产出端自报 `wm_pid=` **不算证据**（`D-G113`）。

**④ 同窗现取基线率闸（`D-G118`）**：注册速率必须带时间窗（`R/N@窗+display`）；缺窗／空样本 ⇒ **响亮 `NOINFO`**；`FAIL` 必须点名"历史速率落在新样本 CI 之外"；口径之争 ⇒ `NOINFO reason=caliber-disagreement`。

**⑤ 产出端（收编仓内）**：`build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`（`64574cfe296dac19`）＋ **唯一剔除集来源** `silenthit-trim.tsv`（`d2bcd611f2506ce0`）；`--selftest`（在册 8 例）＋ `--replay ~/w128a/frozen/{W071,W077}`（**零槽**重放两个在册真命中）先跑。⚠️ `tests/**` 不在 `fp_inputs()` 覆盖面 ⇒ 若改该件必须**显式声明**（否则同 `D-G108`／`D-G120`：声明指不到、读数会假绿）。
**⑥ 止损六格**（到即停手报主控）：修后件在离线夹具上崩／夹具无检测力／`TRIM_GATE != ok` 累计 ≥2 腿／格 B 前 25 腿出命中（`tid=6`、`depth≈7088`）／`df` <5 GB 或 `MemAvailable` <1500 MB 持续／出现需要 `pkill|pgrep -f` 的需求。

**⇒ `TASK-0201` 的状态位**：本件**不改**（仍是 `🟡`）。卡在哪一格，逐字：**卡在"需要一条机器级重活槽 + 串行波次窗口"** —— 应用级腿（起 X ＋ 起应用 ＋ 9 击配方）**本件按纪律未跑**，因此**拿不出新的上界**，也**不能**把 `🟡` 转 `✅`。

---

## §5 复算命令（逐条可重放）

```bash
R=/home/links-dev/netTest/GitProj/WPFOnLinux; cd "$R"
sed -n '50,90p' src/WpfGfx.Linux.Native/src/win32_msg.c      # 判定点原文（旧遍历已只在注释里）
grep -n 'while (p->next)' src/WpfGfx.Linux.Native/src/win32_msg.c   # 唯一命中 = :108（注释）
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16    # e8127a3d7128d417（#79 冻结值）
sed -n '9p' docs/CURRENT-STATE.md && grep -c '^run_step "' verify-all.sh
bash ~/w153a/bin/infp.sh fp && bash ~/w153a/bin/infp.sh list | wc -l
# 两极化（夹具在 /tmp，见 §2.1；单变量＝只换 .so）
gcc -std=gnu11 -O1 -Isrc/WpfGfx.Linux.Native/src /tmp/t10-qcorrupt.c -o /tmp/t10-post \
    -Lsrc/WpfGfx.Linux.Native/bin -lwpfwin32 -Wl,-rpath,$PWD/src/WpfGfx.Linux.Native/bin -lX11 -ldl -lpthread
timeout 30 /tmp/t10-post;  echo "rc=$?"      # 期望 rc=0 ＋ [QUEUE_CORRUPT] ＋ T10_SURVIVED count=1
```

---

## §6 `NOINFO` / 边界 / 未做（逐条）

1. **应用级重测（`N=175`／两条腿／基线率闸）本件未跑** ⇒ `TASK-0201` **无新上界**，状态位仍 `🟡`（**卡在缺槽**，§4 末）。
2. **`si_addr` 的 `p=0` 那一支未跑**（只跑了 `p=0x102`）⇒ §3 的校准是**单点**，另一支的预期值 `0x38` 是**预测**而非读数。
3. **修前/修后两臂只用一个夹具源**（`/tmp/t10-qcorrupt.c`）⇒ **无第二实现互证**；两臂的可执行件 sha16 已给，但**未**做"同一份源两次编译 `.so` 逐位相同"的可复现性检查。
4. **未验证修后件在真应用上的行为**（应用级两极化 = §4，需槽）。
5. **本件未落任何仓内夹具**：`src/WpfGfx.Linux.Native/tests/queue_invariant.c`（在册 146 行**已在覆盖面内**）**未改**；把 §2 的夹具收进仓需**单列一步**（会动 `inputs_fp`，且 `tests/**` 需显式声明）。
6. **未碰** `verify-all.sh`／`close-wave.sh`／任何牙／任何产品件；**未**改 `docs/ROUTES.md`（账目同趟对齐那条**未做** —— 因为本件既没落地修法、也没产生新读数）。
7. **整波链/冻结新代/推送/哨兵**：**不是本件的活**（`#79` 已由波内车道完成，见 §0）⇒ 该项**未做**，并**不**声明为待办。

---

## §7 给主控的建议拆单（本件做不到的两件，各自需要什么）

1. **`TASK-0209` 收尾（建议 `verification-only`，零槽）**：把 §2 的夹具**收进仓**（`src/WpfGfx.Linux.Native/tests/queue_invariant.c` 追加用例，或新增件 ⇒ **须显式声明 `tests/**` 不在覆盖面**），并把 §3 的 `si_addr` 两极化校准（`p=0` ⇒ `0x38`；`p=0x102` ⇒ `0x13a`）补成第二条腿。**不需要**槽、不需要 X、不需要应用。
2. **`TASK-0201` 重取（需一条机器级重活槽）**：按 §4 照做（主档 `N=175`，两条腿，`D-G118` 同窗闸，止损六格），产出新上界并把 `ROUTES.md:205` 的 `🟡` 或转 `✅` 或如实写明卡点。**串行**：须排在某波之间，不与其他重活并行。

- 🔁 **（车道 `t45` 追加，读取时刻 **2026-09-28T02:16:39+08:00**）**`D-G109` 的在册句**已做 dated 更正**（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`，`D-G109` 条目末段）—— 本报告 §3 的结论与它同向且**已入册**：**`si_addr = p + 0x38` 逐位正确 ⇒ 该字段可采信**；在册 `W071`／`W077` 那几格 `0x0` 属**记录层欠采**（判别量 `si_code` 从未被采），**不是**「字段与指令语义不符」。⚠️ 本行在 `head -n -1` 口径**之内** ⇒ 末行 `SELF-SHA16` 已按本笔同步重算。
---

## §8 `TASK-0209` 收编：确定性夹具入仓 ＋ `si_addr` **两点校准**（本笔；**零槽**；读数全部现取）

**① 落仓件（本笔唯一新增的仓内件）**：`src/WpfGfx.Linux.Native/tests/queue_corrupt_chain_fixture.c`
　sha16 **`862fee1594289ceb`**／**114 行**／mtime `2026-09-28T03:29:31.911072632+08:00`（inode 5274733）。
　**收编关系**：正文 ＝ 车道 `t10` 真跑过的 `/tmp/t10-qcorrupt.c`（`c4ce076eadf0fa4b`）**逐字**（含输出标记
　`T10_SEGV`／`T10_SURVIVED`／`T10_CORRUPT_INJECT`），**只多**一个 `calibrate` 模式；两件**合并成一件**的理由
　＝ `fp_inputs()` 用 `find src/WpfGfx.Linux.Native -type f -name '*.c'` 收源 ⇒ **每多一件 `.c` 就多一格覆盖面**。
　⚠️ **落仓方式如实记（不足）**：新件是**直写创建**（原路径不存在 ⇒ 没有"覆盖正在被读的件"的窗口），其后一处
　`#include <unistd.h>` 修正也是直写；**严格按本波"temp+rename"规矩，这两笔都不够格**（读侧无窗口是事实，
　但纪律是纪律）—— 本报告后面两笔（`verify-all.sh`／本报告）都走了 `temp+rename`。

**② 两极化（**单变量：只换 `libwpfwin32.so`**；读时 `2026-09-28T03:29:27–03:29:49+08:00`）**：

| 臂 | `.so`（sha16） | 命令 | 读数 |
|---|---|---|---|
| 修前 | `abf6879c027c5e73`（`~/w128a/app-P`，在册证据） | `corrupt 0x102` | **`rc=139`**、`T10_SEGV si_addr=0x13a` |
| 修后 | **`e8127a3d7128d417`**（`#79` 冻结九位之一，仓内 `bin/libwpfwin32.so`） | `corrupt 0x102` | **`rc=0`** ＋ `[QUEUE_CORRUPT] … 可疑链头=0x102 形态判据=必非节点指针 … 对策=隔离可疑链(零解引用)+本条消息照常入队` ＋ `T10_SURVIVED count=1 head=0x…330 tail=0x…330 next=(nil)` |

　⇒ **修后件不崩 ∧ 不静默丢件**（件照常入队、链被隔离）；两臂可执行件：`/tmp/t44-pre`、`/tmp/t44-post`。

**③ `si_addr` 两点校准（本笔新增的那一格；同型指令 `mov 0x38(%rax),%rax`，与 shim `p = p->next` 逐字同形）**：

| `P` | 期望 | 现取 `si_addr` | `si_code` |
|---|---|---|---|
| `0` | `0x38` | **`0x38`** | `1`（`SEGV_MAPERR`） |
| `0x102` | `0x13a` | **`0x13a`** | `1` |
| `0xdeadbe0038`（附） | `0xdeadbe0070` | **`0xdeadbe0070`** | `1` |

　⇒ `si_addr` **随 `P` 逐位跟随** ⇒ 字段**可采信**（与 `D-G109` 的 dated 更正同向，那笔已入册）。
　**边界（逐字，防后人误用）**：本校准走的是 **`#PF`（地址未映射）** ⇒ `si_code=1`；而应用里那几格 `si_addr=0x0`
　是 **`#GP`（非规范地址 ⇒ `SI_KERNEL` ⇒ `si_code=0x80`）** 形态 ⇒ **"字段可信"与"那一格欠采 `si_code`"是两件事**，
　本校准只证前者。**本件不声称采过 `W071`／`W077` 的 `si_code`**（仍是 `NOINFO`）。

**④ 零足迹（A 段的）**：**未起 X、未占槽、零 `dotnet`、零应用趟**；夹具只**读**仓内头文件、只**链接**既有 `.so`。

**⑤ ⚠️ 覆盖面/代际声明（本笔的第二处，必须与 `[42]` 同读）**：
- 该件**在 `fp_inputs()` 覆盖面内**（`find src/WpfGfx.Linux.Native … -name '*.c'` 那条）⇒ 覆盖面 **225 → 226**、
　`inputs_fp` `cb7fbecaf8cd09fb639cd0c27e42bd0b1848848cb313d5aeebfd8b8e5748ac91` →
　**`3d5ac10b94f8a4e0dba9ded8d41c5d44e9033b2dbb6dec99b384d318b2e1d9a9`**（现取 `2026-09-28T03:33:0x+08:00`，`list=226`）。
　**这属"下一代的覆盖面变化"** ⇒ 由波 `#80` 冻结进声明（`t46`）。
- **同趟把 `[42]` 的声明改准（主控 03:33 点名，本笔执行）**：`verify-all.sh`
　`bb7a286b99dba757` → **`e270cb6800cbdfc2`**，**只改 `:1194` 的 `--expect 225 → 226`**（常数仍独立写死；
　`:69` 的 `t27` 历史 DECL 注释**一字未动**）⇒ 自跑 `FP_MANIFEST_TEETH=PASS reason=ok files_n=226
　files_n_uniq=226 blank_n=0 shape_bad=0 declared_expect=226`、`FP_MANIFEST_STEP_RC=0`（牙本体 `be19edddf7f02797` 未动）。
- **不一致窗口（如实公布，不抹）**：覆盖面变 226 的时刻 ＝ 新件 mtime **`03:29:31.911072632`** →
　`--expect` 变 226 的时刻 **`03:33:59.648774886`** ⇒ **窗口 `268.7 s`**、方向 **`delta=+1`
　（声明落后于事实）**；窗口内**唯一主动报红的一格** ＝ `FP_MANIFEST_TEETH=FAIL reason=files-n-mismatch
　files_n=226 expect=225 delta=1`（形状可完全合法 ⇒ 只有这一格看得见）。**顺序自评（如实）**：本笔做反了 ——
　凡"落一件就多一行覆盖面"的改动，正确顺序是**先把 `--expect` 写成新值（声明领先，窗口 `delta=−1`）**、
　**再落件**；"覆盖面在 `close-wave.sh`、`--expect` 在 `verify-all.sh`，两件无法一次原子替换"（`D-G158` 同族）
　只解释"为什么有窗口"，**不解释"为什么把方向选反"**。
- 该件**未被 git 跟踪** ⇒ **必须进波 `#80` 那一笔推送的清单**（`t46`）。

**⑥ 复算命令（逐条可重放，零槽）**：
```bash
R=/home/links-dev/netTest/GitProj/WPFOnLinux; cd "$R/src/WpfGfx.Linux.Native"
gcc -std=gnu11 -O1 -Isrc tests/queue_corrupt_chain_fixture.c -o /tmp/t44-post \
    -L"$PWD/bin" -lwpfwin32 -Wl,-rpath,"$PWD/bin" -ldl -lpthread      # 修后臂
gcc -std=gnu11 -O1 -Isrc tests/queue_corrupt_chain_fixture.c -o /tmp/t44-pre \
    -L"$HOME/w128a/app-P" -lwpfwin32 -Wl,-rpath,"$HOME/w128a/app-P" -ldl -lpthread
/tmp/t44-pre  corrupt   0x102     # ⇒ rc=139 ＋ T10_SEGV si_addr=0x13a
/tmp/t44-post corrupt   0x102     # ⇒ rc=0 ＋ [QUEUE_CORRUPT] ＋ T10_SURVIVED count=1
/tmp/t44-post calibrate 0         # ⇒ si_addr=0x38
/tmp/t44-post calibrate 0x102     # ⇒ si_addr=0x13a
```

---

## §9 `TASK-0201` 重取（本笔）：装置已开跑 ＋ 🔴 **结构性阻断**（按现口径**拿不出上界**；本笔现取）

**① 装置（先写后判，判据件 `~/w44a/criteria-t44.md` `341bb136e711bf60`／mtime `03:34:10+08:00`）**
- 车道 `~/w44a`（W128A 的 `one128.sh` 派生：车道根逐字替换；驱动 `chain44.sh`／`group44.sh`）。
- **单变量**：`app-C` ＝ `app-A` 的逐字节副本 ＋ **只换 `libwpfwin32.so`**（`33352e5797031999` → **现件 `e8127a3d7128d417`**），
　差异件数断言 ＝ **1**；**分母 `N=175`**（与历史 `2/175` 同 N）；`PAD` 取 `pads175.txt`（同值 `0d3b966b7e1c3ecf`）。
- **无 WM 腿**（`:186`：`xprop -root _NET_SUPPORTING_WM_CHECK` ⇒ `no such atom`）＝**有检测力**那条腿；`nogdb`／`click`／`TO=50`
　（＝ W128A 对照臂配置；`nogdb` ⇒ `app.rc` 是**应用自己的** rc，支①`rc139` 直接可用）。
- 每批 1 趟**装置对照腿**：`rc=124 family=alive landed=8 shim=e8127a3d7128d417` ⇒ 装置自证成立。
- 槽：每批一次 `--min-avail 1500 --max-hold 1800 --wait 3600`，批内每腿 `NESTED_SKIP`；长跑前现取 `df -Pk /`（`89,0xx,xxx KB` 可用）
　与 `SwapFree`（`1,249,276 kB`）。

**② 判词架构（不许两处实现打架）**：**唯一实现 ＝ 仓内 `tools/silent-hit-v2-check.sh` 的 `judge()`**
（自测：`SILENTHIT_SELFTEST=PASS cases=9 fail=0 degenerate_flips=3 three_state=3/4/2`／`SILENTHIT_GATESELFTEST=PASS cases=12 fail=0`）；
本笔另写**第二实现** `~/w44a/bin/judge44.py`（**跑批前落盘**）只做两件事：把历史格式观测换算成产出端列口径
（`legs.tsv`）＋ 用同口径再算一遍 ⇒ **两份逐腿一致**（实测一致：见 ③）。

**③ 🔴 阻断（本笔现取，**两次独立**：仓内产出端 `--replay` ＋ 本笔第二实现逐字相同）**
```
$ DISPLAY=:237 WPF_PROBE_TAG=WT01 … bash build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh --replay ~/w44a/pilot/WT01 --tag WT01
LEG tag=WT01 arm=replay rc=124 APP_TEXT_BYTES=115 APP_TEXT_BYTES_TRIMMED=115 TRIM_GATE=noinfo \
    STACKOVF=0 SEGV_BRANCH=none FAMILY=alive phase=nav undeclared=1 LEG_SHA16=replay HIT=NOINFO
```
- **根因（逐字）**：无 WM 腿**每腿恒打一行 115 B** 的 shim 台账 —
　`[G147_WORKAREA] source=fallback-screen GetMonitorInfo mon=0,0,1280,1024 work=0,0,1280,1024 prop_present=0 prop_n=0`
　（`TASK-0747` 的运行期台账；**只在无 WM 路径出现**）——而它的 tag **不在剔除集申报里**：
　`grep -c G147 build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv` ＝ **0**（该件 `d2bcd611f2506ce0`／22 行／6 needle）
　⇒ 完备性闸 ⇒ `undeclared=1` ⇒ `TRIM_GATE=noinfo` ⇒ 该腿 `NOINFO`、**不进分母**。
- **两条腿互斥（这才是真阻断）**：**无 WM 腿**＝唯一**有检测力**（历史两个命中全出自无 WM）但现在**每腿 `NOINFO`**；
　**有 WM 腿**＝`TRIM_GATE=ok` 但**无检测力**（在册：点击被吞、`landed 1/8`）⇒ 判词上限 `NOINFO reason=no-detection-power`。
　⇒ **按现口径，"能进分母的腿"与"有检测力的腿"没有交集** ⇒ **`TASK-0201` 的结构性上界本笔拿不到**（不许用近似读数凑绿）。
- **已报主控请裁定（三条）**：(A) 授权在 `silenthit-trim.tsv` 加**一行**（与 `[POSTMSG_DEAD_TARGET]`／`[QUEUE_CORRUPT]` 同类，
　代价＝`inputs_fp` 本代**再位移一次**＋一次声明，该件属 `TASK-0726` 那条线）｜(B) 不动 tsv、在报告里**dated 增补口径**
　（上界在**明示增补口径**下算、`TRIM_GATE=noinfo` 那格照旧可见 ⇒ 是本笔**不推荐**的一条）｜(C) 判本波**仍不可测**：
　批链按 `NOINFO reason=producer-gate-excludes-no-WM-leg` 交件、`ROUTES.md` 两行**不动**、阻断具名转 `TASK-0726` 线条。
- **本笔当前动作**：批链**在跑**（7 批 × 25 腿，ETA `06:2x`）—— 保留的理由是"腿的原始件全在、重判只要秒级"，
　若裁定 (A)/(B) 则这 2.5 槽小时**立刻**变成有效读数；**若判 (C) 则按 PID 停链并释放槽**（给 `t46` 让路）。
- **`D-G118` 同窗闸**：本笔速率必须带时间窗；**本次因分母恒 0 ⇒ 该格 `NOINFO`**（缺窗/空样本不许当绿）。
- **止损六格**：本笔到 `⑤`（资源）与 `⑥`（纪律）两格**未触发**；`①`（修后件在离线夹具上崩）**未触发**（§8 ②）；
　`②`（装置无检测力）**未触发**（对照腿活满窗口、`landed=8`）；`③` `TRIM_GATE != ok` 累计 ≥2 腿 —— **已触发**
　（这正是阻断本身，不是"止损"，故报主控裁定而非自行停手）；`④` 前 25 腿出 `tid=6`／`depth≈7088` 形态命中 —— 未触发（截至本笔现取）。
- **`ROUTES.md` 状态行**：**本笔未动**（拿不到新上界就不许改；仍 `🟡`）。


---

## §10 `TASK-0201` 阻断的修法（**主控裁定 (A)**）：`silenthit-trim.tsv` 加一行 ＋ 两条极性腿 ＋ 窗口（本笔；`2026-09-28T03:38:07+08:00`）

**① 这一笔是"主控授权的域外写"（reason 逐字）**：主控 2026-09-28 03:4x 裁定 **走 (A)**，**驳回 (B)**（"那是**在读数层放宽** …… 缺陷会留在装置里，只是账上好看"）、**不采用 (C)**（"它诚实，但 (A) 是**把判不了变成真判**的形态"）。
⇒ 本笔改动 **不在** `t44` 原契约的 inScope 里（原写域＝仓内夹具落点／本报告／`ROUTES.md` 两行），**按 `t27` 先例逐字声明于此而不列进 `changedPaths`**。改动面 **只有一行**，落点 ＝ `build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv`（**唯一剔除集来源**；该件在 `fp_inputs()` 覆盖面内）。

**② 那"一行"逐字（插在 `trimmed=yes` 块末、`trimmed=no` 块之前；文件 23 → 24 行）**：
```
[G147_WORKAREA]	1	yes	G147_WORKAREA	win32shim	src/WpfGfx.Linux.Native/src/win32_x11.c:1721 `wpf_x11_workarea_declare()` 里**无条件** `fprintf(stderr, "[G147_WORKAREA] source=%s %s", g_wpf_workarea_src, cur)`（唯一开关 `WPF_LINUX_G147_DECL`，默认**开**且源码注释自述"是判据的取证口、不是调试噪音"；同 `who` 同内容节流，但被抑制次数以 `suppressed_since_last=` 照样上屏）⇒ 无 WM 腿**每腿恒一行**，属 shim 具名台账、非产品文本
```
- **出处证据（不是"看起来像台账"，是代码位）**：`grep -rn 'G147_WORKAREA' src/WpfGfx.Linux.Native/src/` ⇒ **唯一命中 `win32_x11.c:1721`**，即 `wpf_x11_workarea_declare()` 里那一句（上方 20 行是 `snprintf` 拼串，其后是 `fputs("\n", stderr)`）。
- **无条件性**：唯一开关是环境变量 `WPF_LINUX_G147_DECL`，**默认开**（`on = (!e || !*e || strcmp(e,"0") != 0) ? 1 : 0`）；源码注释逐字写着"这是**判据的取证口**，不是调试噪音；若判定为噪音可用 `=0` 关掉，但**关掉即失去声明**" ⇒ 与 `trimmed=no` 那批"诊断开关（默认关）"**不同类**，与 `[POSTMSG_DEAD_TARGET]`／`[QUEUE_CORRUPT]` **同类**。
- `trail_sp=1` ＝ 该行在语料里 `]` 之后**恰有一个空格**（`"] source=%s"`）⇒ needle 重建为 `"[G147_WORKAREA] "`。

**③ 两条极性腿（**副本夹具** `~/w44a/fixtures/`，真树与在册证据零写；判词由**仓内实现** `run-silenthit-legs.sh --replay` 亲下）**：
```
① 正极（同一条真腿 pos-g147＝WT01 的副本，rc=124）——**只说剔除集这一个变量**：
   [旧 tsv d2bcd611f2506ce0] LEG tag=pos-g147 rc=124 APP_TEXT_BYTES=115 APP_TEXT_BYTES_TRIMMED=115 TRIM_GATE=noinfo STACKOVF=0 SEGV_BRANCH=none FAMILY=alive undeclared=1 HIT=NOINFO
   [新 tsv 4270ab3da7a1d6d8] LEG tag=pos-g147 rc=124 APP_TEXT_BYTES=115 APP_TEXT_BYTES_TRIMMED=0   TRIM_GATE=ok     STACKOVF=0 SEGV_BRANCH=none FAMILY=alive undeclared=0 HIT=no
   ⇒ `undeclared 1→0`、`TRIM_GATE noinfo→ok`、该腿**从"不进分母"变成"可计数（本腿判 no-hit）"**。
② 负极（防"一剔了之"两条，均为副本夹具）：
   [真命中形 neg-hit-real：rc=139 且语料只剩可剔行] ⇒ LEG … APP_TEXT_BYTES=115 APP_TEXT_BYTES_TRIMMED=0 TRIM_GATE=ok STACKOVF=0 SEGV_BRANCH=rc139 FAMILY=139-segv undeclared=0 **HIT=yes**（**真命中照旧打得响**）
   [含不可剔的真话行 neg-nontrimable：rc=139 ＋ `Unhandled exception.`] ⇒ LEG … APP_TEXT_BYTES=136 APP_TEXT_BYTES_TRIMMED=21 TRIM_GATE=ok STACKOVF=0 SEGV_BRANCH=rc139 FAMILY=139-segv undeclared=0 **HIT=no**（**真话行没被吃掉** ⇒ 不是"什么都剔"）
TRIM_GATE=ok rows=23 trimmed_needles=7 file=…/silenthit-trim.tsv sha16=4270ab3da7a1d6d8（改前 rows=22／needles=6）
```

**④ 声明与窗口（照 `t27` 立的口径）**：
- **件数不变、`--expect` 不动**：该件**本来就在**覆盖面内 ⇒ `list=226`（改前/改后都是 226）⇒ `[42]` 的常数**不需要再动**。
- **`inputs_fp` 再位移一次（本代第 5 次）**：`3d5ac10b94f8a4e0dba9ded8d41c5d44e9033b2dbb6dec99b384d318b2e1d9a9` → **`37d4c6ab22f9606e0ad90fe34220e64a545bd3cc6c45da5fe3bbfeb5cdaad83b`**（读时 `2026-09-28T03:37:2x+08:00`）。
- **该件的时刻对**：改前 `mtime=2026-09-26 00:29:17.403038589 +0800`（inode 5523570，2073 B）→ 改后 **`mtime=2026-09-28 03:37:26.776852035 +0800`**（inode 5517288，**2571 B**，`temp+rename`、无 `.t44.tmp` 残留）。
- **窗口内危险读数清单（如实）**：`temp+rename` ⇒ **不存在半态窗口**（读侧要么见旧件、要么见新件）；真正的"危险"是 **同一趟里取到两个 `inputs_fp` 值**（跨 `03:37:26.776852` 的任何"两读对比"会把它记成一次**读数类差异**），以及**任何以旧 tsv 为输入的判词**（旧 tsv 下无 WM 腿恒 `TRIM_GATE=noinfo`）。**本笔的批链不受影响**：腿的原始件不含剔除集，判词在**跑完后**统一用**新 tsv** 现算（读时见 §11）。
- **边界（记住它不是"放宽"）**：这一行改的是**输入**（"哪一行不算产品文本"），**不是判据**（`HIT ⇔ TRIMMED==0 ∧ STACKOVF==0 ∧ SEGV_BRANCH!=none` **一字未动**），且**两条负极腿**证明真命中照旧响、真话行照旧算 ⇒ 与 (B) 那种"在读数层放宽"不同类。

**⑤ 资源止损（主控 2026-09-28 新加硬要求，本笔即刻兑现）**：
- 新件 `~/w44a/bin/memwatch44.sh`（后台看门，pid `971140`）；**每 15 s** 用 `/proc/meminfo` 现取（**不用** `free`，本机本地化输出）`MemAvailable` 与 `SwapFree`，逐行写 `~/w44a/logs/memwatch.log`。
- **触线**：`SwapFree < 512 MB` **或** `MemAvailable < 2000 MB` ⇒ **立即停链**、落盘 `~/w44a/CHAIN_ABORTED reason=swapfloor swapfree_mb=… avail_mb=… at=… pids=…`、**保留已完成腿的全部原始件**，并在报告里具名"停在哪一批、为什么"（**不许**静默缩短批数、**不许**把没跑的腿当成 0）。
- **纪律兑现方式**：看门**每轮先只枚举**链进程树（从 `chain44.pid` 递归走 `/proc/*/stat` 的 PPID）写 `~/w44a/abort.pids`，**触线时只 kill 上一轮已写好的那份清单** ⇒ **枚举与击杀不在同一条命令里**，且**全程只按 PID**（无 `pkill`／`killall`／`pgrep -f`）。
- 首两读（现取）：`avail_mb=3020 swapfree_mb=1222`（03:37:14）→ `avail_mb=3512 swapfree_mb=1222`（03:37:33）⇒ **两闸都在线上**。


---

## §11 `TASK-0201` 重取**结果**（现件代，**175 腿**；读时 `2026-09-28T06:09:11+08:00`）

**① 一句话**：`TASK-0209` 修法落地后的**现件**（`e8127a3d7128d417`）上，**`0/175` 命中 ⇒ 95% 单侧上界 `1.6973%`**（点估计 `0`）—— **上界严格低于**修前件代的 `2/175 ⇒ 3.5537%`。（**同 N 同体制**可比：`D-G116`。）

**② 装置（单变量，逐条可核）**：
- `app-C` ＝ `app-A` 的**逐字节副本** ＋ **只换** `libwpfwin32.so`（`33352e5797031999` → **现件 `e8127a3d7128d417`**），**差异件数 = 1**。
- **无 WM 腿**（`:186`，`xprop -root _NET_SUPPORTING_WM_CHECK` ⇒ `no such atom`）＝**有检测力**那条腿；`arm=nogdb`（`app.rc` 是应用自己的 rc）／`mode=click`（9 击腿逐字同 `W128A`／`W98A`）／`TO=50`（＝`W128A` 对照臂配置）。
- `PAD` 相位逐腿取自 `pads175.txt`（同 `~/w128a/pads175.txt`，sha16 `0d3b966b7e1c3ecf`）；实测前五点 `0,16,32,48,65` 与表**逐行相符**。
- **每批 1 趟装置对照腿**（7 批 7 腿）：**`7/7` `rc=124`／`family=alive`／`landed=8`／`shim=e8127a3d7128d417`** ⇒ 装置自证成立。
- 主臂 `CLICKS_LANDED ∈ {7,8}`（175 腿全部 ≥7）⇒ **配方确实投递到位**（检测力的前提）。
- 槽：每批一次 `--min-avail 1500 --max-hold 1800 --wait 3600`；批内每腿 `NESTED_SKIP`。7 批台账：`A1..A7` 各
  `OK=25 SKIP=0 BAD=0 CTRL_OK=1 CTRL_BAD=0 N134=0 HIT139=none ELAPSED_S≈1314–1315 s`（`~/w44a/logs/batches.txt`）。

**③ 判词（两份实现**逐腿一致**；判词以仓内那份为准）**：
```
仓内唯一实现  bash build/MilBridge/tools/silent-hit-v2-check.sh --legs-from ~/w44a/legs.tsv
              ⇒ SILENTHIT_LEGS rows=175 hits=0 ／ SILENTHIT=PASS
本件第二实现  python3 ~/w44a/bin/judge44.py --lane ~/w44a
              ⇒ JUDGE44_DENOM legs=175 hits=0 noinfo=0 n134_or_stackovf=0 alive_timeout=175
                JUDGE44_RATE hits=0/175 point=0.000000 ub95=1.6973%
口径（一字未动）：SILENT_SEGV_HIT ⇔ APP_TEXT_BYTES_TRIMMED==0 ∧ STACKOVF==0 ∧ SEGV_BRANCH!=none
剔除集：silenthit-trim.tsv 4270ab3da7a1d6d8（本代按主控裁定 +1 行，见 §10）
腿表：~/w44a/legs.tsv sha16 f94be573393b9971 ｜ 台账：~/w44a/runs.tsv 182 行（175 主臂 ＋ 7 对照）
```
**逐格现取（175 主臂腿全同）**：`RAW=115`／`TRIMMED=0`／`STACKOVF=0`／`SEGV_BRANCH=none`／`rc=124`（`FAMILY=alive`）
⇒ **`n134=0`**（**没有任何 `134` 族死亡**）；具名台账**一次都没出现**：含 `[QUEUE_CORRUPT]` 的腿 **0**、含 `[POSTMSG_DEAD_TARGET]` **0**、含 `SIGSEGV`／`Unhandled exception.` **0**；`OOM` 列合计 **0**。

**④ `D-G118` 同窗闸（速率必须带窗，逐字）**：
`R/N @ 窗 + display` ＝ **`0/175 @ 2026-09-28T03:35:57–06:07:37 +08:00, display=:186（无 WM）`**。
- **⚠️ 诚实的那一格（不许把"上界收紧"读成"率显著变低"）**：修前件代点估计 `1.14%`（`2/175`）**落在**本样本 95% 单侧上界
  `1.6973%` **之内** ⇒ **同 N 下"`0/175` vs `2/175`"分辨不了 `0` 与 `1.14%`** ⇒ 该比较记
  **`NOINFO reason=rate-difference-not-resolvable-at-N=175`**；**只有"上界"这一格**是严格收紧的（`3.5537% → 1.6973%`）。

**⑤ 边界（逐条，未猜）**：
1. **只对本装置成立**（`Xvfb 1280x1024`、**无 WM**；用户现场是 xrdp ＋ xfwm4）⇒ **有 WM 腿无检测力**（在册：点击被吞、`landed 1/8`），本件**不跑**、该格 `NOINFO reason=no-detection-power`。
2. **相位分布与历史不同**：本代 175 腿**全部活满窗口**（`n134=0`），而历史主臂 **173/175 死于 `134-stackovf`** ⇒
   `PAD` 扫描在本代**不再产生 134 族死亡** ⇒ **同 N 可比、同相位分布不可比**（如实划界，不掩饰）。
   覆盖窗口本身相同：历史两个命中都发生在**第 7 击（配方内）**，本代配方同形且 `landed≥7`。
3. **本件不针对残余窄 `TOCTOU`**（`TASK-0211`：`PostMessageW` 锁内取指针、锁外使用）⇒ `0/175` **不等于**该窗口已绝迹，只给它的率一个上界（同 `1.6973%`）。
4. **本件不改任何产品件**（`app-C` 只在仓外车道目录；仓内只落了 §8 那一件夹具）⇒ 九位/基线不动。
5. **`PAD` 关的是"内核给进程的栈顶数据量"**，不是"配方"；本件对它的作用是**相位多样性**，不参与判据。

**⑥ 资源与纪律（全程现取）**：
- 看门 `~/w44a/bin/memwatch44.sh`：**全程 478 次现取**，`MemAvailable` **最低 `3,020 MB`**、`SwapFree` **最低 `1,226 MB`**
  ⇒ **两闸（`2000 MB`／`512 MB`）一次都没触线**；`CHAIN_ABORTED` 标记**不存在**。
- ⚠️ **如实**：正因为没触线，看门的**击杀路径（按 PID 停链）全程未被执行** ⇒ 它只能算"已接线"、**不能算"已验证"**（该格的极性腿本件没有做，如实记）。
- 磁盘：跑前 `89.0 GB` 可用 → 跑后 `87.7 GB` 可用（脚本体量 ≈1.3 GB，主要是每腿截图）；`df` 全程 ≥ 5 GB 远超。
- 进程**只按 PID**：看门枚举走 `/proc/*/stat` 的 PPID 树，**枚举与击杀分属两条命令**；全程无 `pkill`／`killall`／`pgrep -f`。
- 长跑走槽；批链 `~/w44a` 与在册证据 `~/w128a` **物理分离**（`w128a` 只读、零写）。

**⑦ `docs/ROUTES.md` 两行状态（本笔按现取读数更新，`append` 式、原文一字未删）**：
- 活状态行（`:205`）：原句保留，行尾追加 dated 子句（`0/175 ⇒ 95% 单侧上界 1.6973%` ＋ 口径/装置/复算入口 ＋ 三条限定）。
- §「账目清零」里的历史行（`:386`／`:387`）**一字不动**，其后**插入一行** dated 子行（同一读数 ＋ `n134=0` 的相位边界 ＋ "上界收紧 ≠ 率显著变低"）。
- 指纹：`docs/ROUTES.md` `f8b43ab042932fb4`（778 行）→ **`1b4ab3a380cd341c`**（779 行）；`git diff --numstat` ＝ **`2 1`**（其中那 1 处"删除"＝ ① 行被替换成"原文＋追加" ⇒ **原文逐字保留**）；`temp+rename`、无 `.t44.tmp` 残留。

**⑧ 本笔自伤（如实，两条）**：
1. `--expect` 的窗口方向选反（见 §8 ⑤）—— **先落件、后改常数**，窗口变 `delta=+1`。
2. `~/w44a/criteria-t44.md` 首版把剔除集 `sha16` 写成一个**未核实的值**（`f0ecb5c6…`），现取后改成真值 `d2bcd611f2506ce0`（**判据件也在同趟被更正**，指纹 `ac4197bf5bc5c75f → 341bb136e711bf60`）；另 `judge44.py` 首版的 `strftime('%FT%T%:z')` 在本机 python 上打出**字面 `%:z`**（已修）。


---

## §12 主控裁定的落实（两处 append ＋ 一条升为口径；`2026-09-28T06:11:07+08:00`）

**① `:205` 的状态怎么留 —— 主控裁定：保持"原文 `🟡` 一字不删 ＋ 行尾 dated 括号"，不就地翻 ✅。**
理由（逐字收下）：ROUTES 状态树是**结账表**，`[MVP]` 那链的**最终翻绿权在 `t14`/`t15`**（`t15` ＝ "ROUTES 状态 ⇔ 机器读数抽查 ＋ 未闭项判决"）⇒ **本笔只把"读数已重取"这一事实落册，不越权翻绿**（这个分寸对）。

**② 四项限定语补齐（**只增不改**：每行都是"原文＋追加"，前缀逐字保留）**：
- `:205`（活状态行）——补第 ④ 项（原文已有 ①②③）：新增
　`；④ 资源看门（`~/w44a/bin/memwatch44.sh`）的**击杀路径记「已接线、未验证」** —— 两闸（`2000 MB`／`512 MB`）全程**未触线** ⇒ 击杀分支**未被执行**〕`
- `:388`（本笔插入的那条 dated 子行）——补 ③④ 两项（原文已有 ①②）：新增
　`③ `0/175` **不等于**残余窄 `TOCTOU`（`TASK-0211`）已绝迹；④ 资源看门的击杀路径记 **「已接线、未验证」**（两闸全程未触线 ⇒ 击杀分支未被执行）；`
- **现取核对（补齐后，两行各四项都在）**：`grep -c` 分别命中 `只对本装置=1 上界收紧=1 TOCTOU=1 已接线=1`（`:205`）与 **同四值**（`:388`）。
- 指纹：`docs/ROUTES.md` `1b4ab3a380cd341c` → **`f8ba705646fa7f33`**（行数不变）；`git diff --numstat -- docs/ROUTES.md` ＝ **`2 1`**；`temp+rename`、无 `.t44.tmp` 残留。
- 四项限定语逐字（防后人缩水）：① 上界**只对本装置**（`Xvfb 1280x1024` **无 WM**）；② **只能说「上界收紧」、不能说「率显著变低」**（历史 `1.14%` 落在新上界内 ⇒ `NOINFO reason=rate-difference-not-resolvable-at-N=175`）；③ `0/175` **≠** 残余窄 `TOCTOU`（`TASK-0211`）绝迹；④ 击杀路径 **「已接线、未验证」**。

**③ 新口径句（由本笔 §11 ⑩ 的观察**升格**，主控采纳并交给波 `#80`）**：
> 🔴 **「『远端事实』只许 `git ls-remote` 现取；本地 tracking ref 是缓存，不是远端。」**
（与"`cmp` 相同 ≠ 当代"**同族**：都是"手里那份副本/缓存**不是**权威现场"。）

**本笔的三个读数（现取，逐字，供后人复算）**：
```
git rev-parse HEAD                          ⇒ 71603bd3762059b3e1791be4a5eac2359657e01f
git ls-remote origin refs/heads/feat-Linux  ⇒ 71603bd3762059b3e1791be4a5eac2359657e01f   ← 远端事实（== HEAD ✓）
git rev-parse origin/feat-Linux             ⇒ 6a245bd5…（**陈旧缓存**；`git log -1 origin/feat-Linux` = `6a245bd … TASK-0747`）
git log --oneline -1 origin/HEAD            ⇒ a914148 [main] Source code updates from dotnet/dotnet (#11951)（**另一个陈旧缓存**）
```
⚠️ **危险方向（逐字记）**：凡是把 `origin/feat-Linux` 当"远端事实"的读数（例："远端是否已含本波那一笔"），会**过期**而**报出假红**（本笔现场：`6a245bd5` 会让人以为 `t40` 的推送没成功，而 `ls-remote` 现取证明推送成立）。

**④ 主控对 (A) 与 B 的裁定（逐字收下，不改本报告任何既有判词）**：(A) 的落地判**合格**（理由列给的是**代码位出处**、两条负极腿证明不是"一剔了之"）；B 的边界划分**必须保留**（`0/175 ⇒ 1.6973%` ＝ "**上界收紧**"成立、"**率显著变低**"不成立；`n134=0` 与历史 `173/175 134-stackovf` ⇒ **同 N 可比、相位分布不可比**，**不许合并成一句"率变低了"**）。


---

## §13 `t11` findings 的关账（F1／F3／F4／F5／F6；**一律 dated 追加、原判词一字不改**；`2026-09-28T06:39:30+08:00`）

> 本节的六条更正**不删上文任何字**：§11① 里"**同 N 同体制**可比"那句**在此声明撤回**，其余（`1.6973%` 的适用范围、"上界收紧 ≠ 率显著变低"）**保留**。（**`t50` 补（dated，读时 2026-09-28T07:39:37+08:00）**：撤回清单**补点名 §4／`:102`** —— 该处同句直到本笔才被指到；另 §13② 的 `N＝175` 已补指针指向 §14② 的成对 `N`。）
> `verifier`（车道 `t11`）的 findings 由主控逐条转达，其中 **F1 我已独立复算成立**（下面①给出我自己的现取数字）；**F2** 的处置见 §14（成对修前臂）。

**① F1（blocker）：「同 N **同体制**可比」= **假** ⇒ 改为「**只同 N**」（本条第 2 次声明，数字全部本件现取）**
- 本件按列解析 `~/w128a/runs.tsv`（**184 行 = 表头 ＋ 183 腿**，读时 `2026-09-28T06:39:30+08:00`）：
```
arm   gdb=175    ｜ nogdb=8
TO    75=175     ｜ 50=8
disp  :185=183
shim  abf6879c027c5e73=175 ｜ 33352e5797039999=8
family  134-stackovf=173 ｜ other=2 ｜ alive=8
两命中行 W071／W077：arm=gdb TO=75 disp=:185 shim=abf6879c027c5e73 family=other ext_kill_suspect=yes app_outcome_observed=no
本波（~/w44a/legs.tsv）：175 行全为 arm=nogdb、RAW=115、TRIM=0、SEGV_BRANCH=none、rc=124
```
- ⇒ **两臂只同 `N`**；**四项逐格不同**：`arm` **gdb ↔ nogdb**｜`TO` **75 ↔ 50**｜`shim` **abf6879c027c5e73 ↔ e8127a3d7128d417**｜`disp` **:185 ↔ :186**。
- ⇒ **`2/175 ⇒ 3.5537%` 一律读作「gdb 臂口径」**（`arm=gdb`／`TO=75`／`disp=:185`／`shim=abf6879c027c5e73`），**不得**当作本波（`nogdb`／`50`／`:186`）的对照。
- ⇒ **`1.6973%` 只对「本装置 ＋ 本波 `nogdb`／`TO=50`／无 WM `:186`／`app-C`（现件）口径」成立**（原写法保留）。
- ⚠️ **追加的独立理由（`verifier` 的机制发现）**：`gdb` 臂上**剔除集不咬**（`TRIMMED==RAW`）⇒ `TRIMMED==0` 在该臂**结构不可达**
　⇒ 历史那 2 个命中**既不是本波口径的对照、也不是本波判据口径下的命中**（它们连 `TRIMMED==0` 这一支都过不了）。

**② F2（blocker）：修前臂在本装置**从未跑过** ⇒ 本件补**同装置成对修前臂**（结果见 §14）**
- 装置/口径与现件臂**逐格对齐**（`nogdb`／`TO=50`／无 WM `:186`／同 `pads175.txt` `0d3b966b7e1c3ecf`／同 `app-A` 底座，**只换 `libwpfwin32.so`**）；车道 `~/w48a`，主臂 `app-H`（修前件 `abf6879c027c5e73`），每批 1 趟装置对照腿用现件 `app-C`（`e8127a3d7128d417`，只证"装置没坏"，**不进任何分母**）。
- **N＝175**（槽预算内；与现件臂同 N ⇒ 成对表逐格可比）；两臂各自的 95% 单侧上界 ＋ 差值 CI ＋ Fisher 单侧 p 一并给在 §14，〔⚠️ **dated 指针（2026-09-28 · 车道 `t50`，读时 2026-09-28T07:39:37+08:00）**：本行的 `N＝175` 是**计划值**；**成对修前臂实际 `N=77`**（**命中即停**，见 §14②），现件臂仍 `N=175` ⇒ 两臂**不同 `N`**。〕
　措辞一律用「**成对臂在新口径下的两个上界**」。

**③ F3（high）**基线率闸**（`D-G118` 的牙）现取读数入账**（本件现取复跑，读时 `2026-09-28T06:39:30+08:00`）**：
```
bash build/MilBridge/tools/baseline-rate-gate.sh \
  --registered '2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185' \
  --observed 0/175 --gate 0.035537 --effect 0.011429
⇒ BASELINERATE=FAIL   BASELINERATE_RC=1
  BASELINERATE_REASON=VOID-PREMISE ① ci_upper(0.0152) < gate(0.0355);以② observed(0.0000) < effect(0.0114) ⇒ 该效应在现世界不可发生
  observed=0/175  observed_rate=0.0000  ci_upper=0.0152  ci_upper_2s=0.0215  ci_lower_2s=0.0000
  registered_in_observed_ci=1  gate=0.0355  effect=0.0114  required_n=NONE  required_n_power=0.0000
  gate_closed=1  effect_impossible=1  gate_verdict_1s=closed  gate_verdict_2s=closed
把在册历史速率**缺时间窗**原样喂入（`--registered '2/175'`）⇒ BASELINERATE=NOINFO  reason=NOINFO-NO-WINDOW  BASELINERATE_RC=3
```
- 🔴 **前提失效（VOID-PREMISE）**：**在册速率落在观测 CI 内**（`registered_in_observed_ci=1`）**且**要排除的效应量在现世界**不可发生**（`effect_impossible=1`）⇒ **不得据此宣称改善**。
- **四条算术（功效表口径，逐字保留）**：`ub95(0/175)=1.697278%`｜`ub95(2/175)=3.553694%`｜`ub95(0/131)=2.260869%`｜`ub95(0/299)=0.996915%`。
- ⚠️ **两个上界口径必须并列、不许混用**（同族：`D-G118` 的"口径之争先于结论"）：**功效表口径** `1 − 0.05^(1/N)` ⇒ `0/175 = 1.697278%`；
　**闸的 Wilson 单侧 95%** ⇒ `0/175 = 0.0152`（`1.52%`）。**两者都印，判词用哪一个必须写明**（本件：功效表口径用于"上界收紧"那句；闸口径用于 `VOID-PREMISE` 判定）。

**④ F4（medium）：`134` 族**归因于 `PAD` 相位**被证伪 ⇒ 判据改为「**判别量是臂/件代（`arm` 与 `shim`），与 `PAD` 相位无关**」**
- 依据①（本件现取）：三个车道的 `pads175.txt` **sha16 逐位相同**（`~/w44a`／`~/w48a`／`~/w128a` 均 `0d3b966b7e1c3ecf`）⇒ **相位表不是自变量**。
- 依据②（`verifier` 自跑）：HIS 臂 **4/4** 出 `134-stackovf`，而**现件臂 175/175 不出**（`n134=0`）—— **同一份 `PAD` 表、不同 `arm`/`shim`** ⇒ 判别量在臂/件代。
- 本件成对修前臂（§14）给出**同装置、同 pads、只换 shim** 的直接读数 ⇒ 该更正由**成对表**收口。

**⑤ F5（low）两处指向/算术更正**
- **`~/w44a/logs/batches.txt` 的指向改准（dated）**：该件**只在第 1 批收批之后才出现**（本笔链 `06:07` 收工时 7 行）；`verifier` 在**批次未收批前**读它 ⇒ `不存在` **当时为真**。**现值（读时 `2026-09-28T06:39:30+08:00`）**：`batches.txt` **769 B／7 行／mtime 2026-09-28 06:07**；**始终存在**的批级摘要源是 **`~/w44a/STATUS.md` 的 7 行 `完成 …`**（两处内容同源、逐行同形）。
  - 🔁 **dated 更正（2026-09-28 · 车道 `t50`，读时 2026-09-28T07:39:37+08:00）：「不存在」整条撤回** —— `~/w44a/logs/batches.txt` **存在**：现取 `769 B／7 行／mtime 2026-09-28 06:07`（`t49` 的读取时刻 `06:16`，那时链**早已结束**）；⇒ **「不存在」是假阳**，成因＝**读法截断**（`t11` 用 `ls | tail -8` 列清单，7 行恰好落在被砍掉的那一段）—— **不是**「时序（未收批前读）」（我上一版把归因写错了，一并更正；「只在第 1 批收批后才出现」这一点**不构成**「不存在」的理由）。**F5 至此只剩窗口一条成立**（`267.7 s`，`267.737702 s` 复算）。**该假阳记为 `t11` 自己的错**（具名：`verifier`／车道 `t11`；**不**推给 `t48`、**不**推给主控）。🔴 **口径句（收进登记）**：「**凡判『某件不存在』，必须给 `ls -l`（不经 `tail`／`head` 截断）或 `test -e` 的原文；不许拿被截断的清单当『不存在』。**」
- **窗口算术改准（dated）**：`268.7 s` → **`267.7 s`**（`03:33:59.648774886 − 03:29:31.911072632 = 267.737702 s`）。**§8 ⑤ 里那个 268.7 s 作废**，其余各格（两个 mtime、方向 `delta=+1`、唯一红格）不变。

**⑥ F6（low）：`stop-signo11` 两支**不等价**（具名写清；本波不可达）**
- **仓内（唯一实现）**：`run-silenthit-legs.sh:213` 逐字 = `grep -aqE '^W[0-9]+[A-Z]*-STOP-[1-9][0-9]* .*signo=11'` ⇒ **锚行首**、要求 **`STOP-` 号首位非零**（⇒ `STOP-0` 排除）、并要求 STOP 号后**有空格**。
- **本件第二实现**：`judge44.py:111` 逐字 = `re.search(rb"W118A-STOP-\d+.*signo=11", gt) or re.search(rb"signo=11", gt)` ⇒（a）**把批次前缀写死成 `W118A`**（本波是 `H%03d`／`W%03d` ⇒ 形态不同），（b）**还接受任意位置的裸 `signo=11`** ⇒ **更宽**。
- ⇒ **两支不等价**（宽窄不同、锚不同）⇒ **不许当等价腿**。
- ⚠️ **对主控 finding 里一句的如实更正**：finding 写"仓内要求 `STOP>=10`"，**与代码不符** —— `[1-9][0-9]*` 的真实语义是"**首位非零**"＝ **`STOP-1` 及以上**（排除 `STOP-0`），**不是 `≥10`**（本件按正则现读，逐字在上）。
- ⚠️ **本波不可达**：本波两条臂都是 `nogdb` ⇒ **根本没有 `gdb.txt`** ⇒ `term`／`stop-signo11` 两支**都不可达**，判词只能落到 `rc139`／`fate` ⇒ **该差异不影响本波任何读数**（也不影响 §14 的成对表）。


---

## §14 成对修前臂（F2 的主体）：**同装置、同口径、只换 `shim`** —— 结果与两个上界（读时 `2026-09-28T07:30:55+08:00`）

**① 设计（逐格对齐现件臂，唯一变量 ＝ `libwpfwin32.so`）**
- 车道 `~/w48a`；主臂 `app-H` ＝ **`app-C` 的逐字节副本 ＋ 只换修前件 `abf6879c027c5e73`**（差异件数断言 ＝ **1**，与 `app-C` 只差 `libwpfwin32.so`）。
- 口径**逐格照抄 `t44` 现件臂**：`arm=nogdb`／`mode=click`（9 击腿）／`TO=50`／**无 WM `:186`**（`xprop` ⇒ `no such atom`）／`PAD` 逐腿取 `pads175.txt`（与前两车道**同值** `0d3b966b7e1c3ecf`）。
- 每批 1 趟**装置对照腿**用**现件** `app-C`（只证"装置没坏"，**不进任何分母**）；实测 `B1C..B4C` **4/4** `rc=124`／`family=alive`／`landed=7..8`／`shim=e8127a3d7128d417`。
- 槽：每批一次 `--min-avail 1500 --max-hold 1800 --wait 3600`；**每批开跑前的资源头**（`/proc/meminfo` 现取，不用 `free`）逐批印在 `~/w48a/logs/chain48.log` 的 `BATCH_HEAD` 行：`avail_mb` `3458→3529→3588`／`swapfree_mb` `1035→1033→1032`。

**② 为什么 `N=77`（不是计划的 175）——**装置的注册行为："命中即停 ＋ 立刻冻结"**
- `B4` 的第 2 腿 **`H077`（`pad=1226`）命中** ⇒ 批链**按注册行为停批并冻结** `~/w48a/frozen/H077`（`frozen/HIT-139.txt`／`LAST-HIT` 在位）。
- 实跑 = **77 主臂腿**（`H001..H077`）＋ 4 对照腿；批级台账：`B1..B3` 各 `OK=25 SKIP=0 BAD=0 N134=25 hit139=none`，`B4 OK=1 … hit139=H077`。
  ⇒ 与"命中即停"一致：**该停不是失败，是装置的设计动作**（在册 `W128A` 同款规则）。

**③ 成对表（逐格，两个上界都用两种口径并列）**

| 臂 | `shim` | 分母 `N` | 命中 | `FAMILY` 分布 | 逐格 | 功效表口径 `ub95=1−0.05^(1/N)` | 闸口径 Wilson 单侧 95% |
|---|---|---|---|---|---|---|---|
| **现件**（`t44`） | `e8127a3d7128d417` | **175** | **0** | `alive=175` | `RAW=115`／`TRIMMED=0`／`TRIM_GATE=ok`／`STACKOVF=0`／`BRANCH=none`／`rc=124` | **1.697278%** | **1.522487%**（闸现算 `ci_upper=0.0152` 逐位相符） |
| **修前**（本件） | `abf6879c027c5e73` | **77** | **1** | `stackovf=76` ＋ `other=1` | 76 腿：`RAW≈6.46M`（栈溢出文本）／`TRIMMED≈RAW`／`STACKOVF=1`／`BRANCH=none`／`rc=134`；**1 腿 `H077`：`RAW=43`／`TRIMMED=0`／`STACKOVF=0`／`BRANCH=rc139`／`rc=139`** | **3.815851%** | **5.613394%** |

**④ 命中腿 `H077` 的原始读数（与历史 `W077` 逐格对照）**

| 格 | 本件 `H077`（`nogdb`/`TO=50`/`:186`） | 历史 `W077`（`gdb`/`TO=75`/`:185`） |
|---|---|---|
| `pad` | **1226** | **1226** |
| `shim` | `abf6879c027c5e73` | `abf6879c027c5e73` |
| 死亡相位 | **第 7 击 `nav2`**（`landed=7`；`tab3`/`nav3` 已 `SKIP dead`） | **第 7 击 `nav2`**（`entry_detail=nav1,nav9,ctrl_tb,nav10,ctrl_cb,popitem,nav2`） |
| 输出 | `app.log` ＝ **43 B**（`timeout: 被监视的命令已核心转储`）⇒ **`TRIMMED=0`** | `app.both` ＝ **0 B** |
| `rc` | `APP_RC=139`／`TIMEOUT_RC=139`／**`WRAPPER_KILLSIG=11`** | `app_rc=1`（gdb 层）/`timeout_rc=1`/`wrapper_killsig=none` |
| `family` | **`other`** | **`other`** |
| `stackovf` | `0` | `0` |
| `oom` | **`0`** | `0` |
| `dead_at_s` | 34（槽 `--max-hold 150 s` ⇒ **不是被槽杀**；SIGSEGV=11 而外部杀是 15/9） | 29 |
| `ext_kill_suspect` | `yes`（与历史两趟**同形态**；判别量是 `WRAPPER_KILLSIG=11` ∧ `oom=0` ∧ 死前无外部杀） | `yes` |

**⑤ 判词（两份实现逐腿一致）**：本件第二实现 `JUDGE44_DENOM legs=77 hits=1 noinfo=0 n134_or_stackovf=76`／`HIT=yes`（`H077`）；
仓内唯一实现 `silent-hit-v2-check.sh --legs-from` ⇒ **`H076 NOT-HIT`／`H077 HIT`**、`SILENTHIT=PASS` ⇒ **该命中是仓内判据端亲自判的**。

**⑥ 两个上界与差值 CI（措辞照主控 F2）**：
- **成对臂在新口径下的两个上界**：**现件臂 `0/175 ⇒ ≤1.697278%`**（功效表口径；闸口径 `1.522487%`）｜**修前臂 `1/77 ⇒ ≤3.815851%`**（功效表口径；闸口径 `5.613394%`）。
- **率差**（修前 − 现件）＝ `1.298701% − 0 = +1.298701%`，**Newcombe 混合 score 95% CI ＝ `[−6.996199%, +1.100611%]`（含 0）**；**Fisher 精确单侧 `p=0.305556`** ⇒ **两臂分不开**。〔⚠️ **dated 更正（2026-09-28 · 车道 `t50`，读时 2026-09-28T07:39:37+08:00）**：**本行的 CI 曾镜像** —— 旧值 `[−6.996199%, +1.100611%]` **作废**（`newcombe()` 两对配对写反 ⇒ **点估计与区间的来向相反**）；**正确值＝`[−1.100611%, +6.996199%]`**。**校准依据**：文献例 `56/70 vs 48/80 ⇒ d=±0.2、CI=(0.0524, 0.3339)`（本件用**同一实现**对 `d=+0.2` 得 `(0.0523, 0.3337)`，按符号对称作 `(−0.3339, −0.0524)` 后逐位相符）；**重算命令**＝`python3 ~/w48a/bin/pairstats48.py ~/w44a/legs.tsv ~/w48a/legs.tsv`（修好**配对**与**调用点臂序**后现取 `DIFF(old-new) point=1.298701% CI95=[-1.100611%, 6.996199%]`）。⇒ **「含 0 ⇒ 两臂分不开」的结论不变**；**两臂上界（`1.697278%`／`3.815851%`）与 Fisher `p=0.305556` 不受影响**。车道记录同趟 append（`~/w48a/STATUS.md` 末行；`pairstats48.py` 现读 `df4e25c529f212eb`）。〕
- ⇒ 🔴 **本波不宣称"上界收紧"**。（`t44` 里"`1.6973%` 严格低于修前 `3.5537%`"这句**只**在"拿 `gdb` 臂口径当对照"时才表面上成立 —— 那条**已按 F1 撤回**；本件成对数据**不支持**任何收紧结论。）
- **修前臂上界比现件臂宽**的唯一原因是 **`N` 小**（77 vs 175）——"命中即停"换来了**一条真命中 ＋ 证据冻结**，代价是上界变宽；**两件事都如实记**。

**⑦ 基线率闸（`D-G118`）在**成对数据**上再跑一次（读时 `2026-09-28T07:30:55+08:00`）**：
```
--registered '1/77@2026-09-28T06:39:59..2026-09-28T07:28:48+display=:186' --observed 0/175 \
--gate 0.03815851 --effect 0.01298701
⇒ BASELINERATE=FAIL  BASELINERATE_RC=1
  BASELINERATE_REASON=VOID-PREMISE ① ci_upper(0.0152) < gate(0.0382);以② observed(0.0000) < effect(0.0130) ⇒ 该效应在现世界不可发生
  registered_in_observed_ci=1  gate_closed=1  effect_impossible=1  gate_verdict_1s=closed  gate_verdict_2s=closed  required_n=NONE
```
⇒ **即便换成"同装置成对基线"，闸仍判 `VOID-PREMISE`** ⇒ **不得据此宣称改善**（与 §13③ 的两组读数并列在册）。

**⑧ F4 由本件成对数据收口**：**同一装置、同一份 `pads175.txt`（`0d3b966b7e1c3ecf`）、同一 `arm`/`TO`/显示，只换 `shim`** ⇒
修前臂 `134-stackovf` **76/77**、现件臂 **0/175** ⇒ **判别量是臂/件代（`arm` 与 `shim`），与 `PAD` 相位无关**。
（`pad=1226` 这一相位**仍会复现命中** ⇒ 说明 `PAD` 是"相位旋钮"、**不是**成因 —— 这与上面那句**不冲突**：相位决定"在哪条腿上打出来"，臂/件代决定"打不打得出来"。）

**⑨ 边界（逐条）**
1. 本件与 `t44` 的两臂**都是单装置结论**（`Xvfb 1280x1024` 无 WM）⇒ 对用户现场（xrdp ＋ xfwm4）**不外推**。
2. 修前臂 `N=77`（命中即停）⇒ 其上界宽于现件臂是**分母小**，**不是**"修前更差"的证据。
3. 修前臂 76 条 `134` 腿的语料是**巨量栈溢出文本**（≈6.46 MB/腿，`TRIMMED≈RAW`）⇒ 这 76 腿按判据**结构上不可能**判成静默 SEGV（`STACKOVF==0` 不成立）—— 与 `gdb` 臂"剔除集不咬"那条同族、但**成因不同**（此处的不可剔是**真话文本**，不是剔除集缺项）。
4. `ext_kill_suspect=yes` 在历史两趟与本趟**都是 `yes`** ⇒ 该旗标**不是**判别量；判别量是 `WRAPPER_KILLSIG=11` ∧ `oom=0` ∧ `dead_at_s=34s`（远小于槽 `--max-hold 150 s`）。
5. **装置自伤如实记（一条）**：第一次起链时我漏改 `one128.sh` 的车道根（复制自 `~/w44a`，仍是 `$HOME/w44a`）⇒ **两条未完成的腿目录**（`B1C`／`H001`）**误落进 `~/w44a/run/`**（06:38:35–06:39:48 约 73 s）。**处置**：按 PID 停链 → 修车道根 → 把两条误落目录移到 `~/w48a/strays/`（**留证不删**）→ 06:39:59 重起链；**核对**：`~/w44a/run` 仍 182 目录、`~/w44a/legs.tsv` sha16 **仍 `f94be573393b9971`**（与 `t44` 交件值逐位相同）⇒ **`t44` 的读数未受任何影响**。
6. **台账瑕疵（如实，两条）**：(a) 上面那条误落的对照腿在 `~/w48a/runs.tsv` 留了一行 `noresult` ⇒ 它让 `group48` 的对照检查误读成 `CTRL_BAD=1`（`B1` 的 `CTRL_OK=0`）——**该对照腿本身是通过的**（`B1C rc=124/alive/landed=7/shim=e8127a3d7128d417`）；该行已按"比对后重写"（CAS：写入前后 stat 一致才落盘）剔除，`runs.tsv` 现读 sha16 `7c98cf812bc1dd6e`。(b) 本件**未**改任何仓内件（只 append 报告与 `ROUTES` 的 dated 追加）。


SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P0-mvp-segv-report.md | sha256sum | cut -c1-16`）= `db4cb49b321ec9c2`

## §15 ⏪ dated 结账（W6／`t52`，读时 2026-09-28T20:25:57.094+0800）—— `t7` 复测 ＋ `t9` 独立判词的读数入账

- **`t9` 判词的八条主判词逐条成立**（`P1-task0201-verify.md`，整件 `sha16` `9e06936d9309f981`／`117` 行），推翻 `t7` 主结论的话 ＝ **没有**；`t9` 的两条 medium（`F2` 闸口径混用／`F3` 冻结块计数）与三条 low（`F1`／`F4`／`F5`）**不翻主结论**。
- **命中与分母（按件代分开 ＋ 按 `tag` 去重）**：主臂（现件代 `6825dd7071387a46`）`0/175`；修前臂（`abf6879c027c5e73`）`1/140`（`H140`）。台账现取 `358` 总行／`357` 数据／唯一 `tag` `335`／重复 `22`（**逐条**：`A6C,B3C,H051–H059,W126–W136`）；去重依据 ＝ `t9` §1（22 组里仅 `ts_end` 22/22 不同、`dead_at_s` `10` 组差 `±1 s`、其余列 22/22 逐格相同 ⇒ 无重放未复现）。我自算件代口径：现件代 `195`／修前件代 `140`（`t9` 另有 `主臂 175＋对照 16＋pilot 4` 的细分，**台账无 arm 列 ⇒ 我未能独立复现该细分**，引 `t9` 具名）。
- **上界两口径（我自算）**：`CP(0,175) = 1.697278%`（＝功效表口径）｜`Wilson 单侧(0,175) = 1.522487%`｜`CP(1,140) = 3.343503%`｜`CP(2,175) = 3.553694%`（注册基线 `2/175` 的正确闸值）。
- **闸（器具现取，捕获式）**：`registered=1/140@2026-09-28T18:39:39..2026-09-28T20:11:55+display=:238`／`gate=0.0334`／`effect=0.0071` ⇒ `BASELINERATE=FAIL`＋`REASON=VOID-PREMISE`；注册基线形态 `registered=2/175@…+display=:185`／`gate=0.0355`／`effect=0.0114` ⇒ 同样 `FAIL`／`VOID-PREMISE`；**缺时间窗** ⇒ `BASELINERATE=NOINFO`／`NOINFO-NO-WINDOW`（`rc=3`）。
- **可分性（器具现取）**：`REGRESSION_DECISION=NOINFO`（`rc=3`）／`REGDEC_FISHER p=0.444444 two_tailed=yes method=hypergeometric-le-observed`／`REGDEC_MDE … min_detectable_p1=0.056`／`REGDEC_REQUIRED_N_OBS per_arm=CAP approx=1091 > NMAX=400`；Newcombe 自算（「旧−新」）`[−1.512733%, +3.934839%]` 含 `0`；**`REGDEC_DIRECTION=` 器具未印**（未显著 ⇒ 按设计不印）⇒ **本件不断言方向、不得宣称改善**。
- **`F3` 更正后现值**：`dead_at_s` 差 `1 s` 的 `tag` ＝ **`10`** 个（`H052/H053/H056/H057/H058/H059/W127/W130/W133/W135`）；本报告 `§16` 原写的 `4` **以本行为准**（更正批 `t66` 正落 dated 更正）。
- **`NOINFO`（具名）**：① 未跑整趟门禁；② 未重跑任何重活腿（本任务只结账）；③ `t9` 的 `主臂 175／对照 16／pilot 4` 细分**我未能独立复现**（台账无 arm 列）；④ 产出端 `--replay` 在本环境被环境闸拒（`t9` 现取 `rc=9 reason=envguard`）。
