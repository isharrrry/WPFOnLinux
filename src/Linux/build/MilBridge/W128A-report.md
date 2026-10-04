# W128A 报告 —— `TASK-0203` 最后一跳：**抓一份「静默 `139`」的栈**，判定它与 `134` 族同源／异源

> **一句话**：**抓到了两趟**（`W071` 第 71 趟、`W077` 第 77 趟，**崩点 `PC` 逐位同址** `0x7fff740dcdf3`）——但它们的机制**不是**那条 21 帧键盘焦点回声递归，
> 而是**另一处**：`.NET Finalizer` 线程 → `HwndWrapper::Finalize()` → P/Invoke → `PostMessageW`
> → `wpf_queue_push` 的**非法队列状态自愈分支**里 `while (p->next) p = p->next;` 踩坏链 ⇒ **SIGSEGV ⇒ 进程静默死**（应用输出 **0 字节**）。
> ⇒ 判词 **`异源`**（四条独立读数 ＋ 反汇编级判定点，**两份独立样本同址**）。
> **本报告里"命中"＝上述产品签名（死于 `SIGSEGV` ∧ **应用输出 0 字节** ∧ `STACKOVF=0`）**，**不是**字面的 `rc=139`（理由见 §⑨）。
> **终值**：**175/175 趟有效（零作废）、`173 × 134` ＋ `2 × 静默 SEGV`**（点估计 **1.14%**，95% 单侧上界 **3.55%**）；对照臂 **8/8 `124/alive/落地 8`**。

**写域**：私有工域 `$HOME/w128a/**`（`bin/`、`run/`、`logs/`、`frozen/`、`runs.tsv`、`STATUS.md`、`criteria.md`、`pads175.txt`、两棵私有 app 树）
＋ 仓内**只写一个文件**：`build/MilBridge/W128A-report.md`（本文件）。**未改任何产品件/牙/路由件/冻结物**；**未构建**；**未跑** `verify-all`／波链。

---

## 0 环境与器材（逐项现场现算，不手抄）

| 项 | 值 |
|---|---|
| 仓根 `R` | `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（本机 `R` **不是** git 仓库 ⇒ 无推送动作） |
| 私有显示 | **`Xvfb :185 -screen 0 1024x768x24`**（PID 见 `~/w128a/xvfb185.pid`）；`xprop -root _NET_SUPPORTING_WM_CHECK` = **无此属性** ⇒ **无 WM** ✓ |
| 仪器 | `ARM=gdb`（`gdb128.cmds.tmpl`＝W118A 的 **v4** 模板**逐位相同** `575334471eb5e970`：`handle SIGSEGV stop print pass`，**不改终止方式**）／`DOTNET_PerfMapEnabled=1`／`DOTNET_gcServer=0`／`MODE=click`／`TO=75`／**9 击腿逐字相同**（`nav1,nav9,ctrl_tb,type,nav10,ctrl_cb[,popitem],nav2,tab3,nav3`） |
| 两棵私有树（**只读 `cp -a` 自 `~/w118a/`**） | `app-P` = 修前件 **`abf6879c027c5e73`**（主臂）｜`app-A` = 固定件 **`33352e5797031999`**（对照臂） |
| 单变量断言（现算） | `diff <(app-A 全件 sha) <(app-P 全件 sha)` ⇒ **只差 1 件**（`libwpfwin32.so`，两行 `<`/`>`）✓ |
| 其余四件（两树同快照） | bridge `feef049e9d0e313a`／pc `722e0ab8205b7c3f`／pf `f34bc297d19778fd`／wb `2e4e46e539a72cd7` |
| 本批器材 sha16 | `criteria.md 23a3f4f6d0d69091`（**第一条样本之前**写成）｜`pads175.txt 0d3b966b7e1c3ecf`｜`one128.sh b5217b83870a4d9c`｜`gdb128.cmds.tmpl 575334471eb5e970`｜`sig.py 7177461121057d0b`｜`scan.py 41cf5aa6f6cca19d`｜`group128.sh 04b252451c2b06c5`｜`chain128.sh 8ef0dfc69a3a542c`｜`judge128.py 3964e730490d0911`｜`mktable128.py 7670b98e614f4ef2`｜`analyze128.py 2b2595be1ea582b8`｜`rescan128.py 5af4189ab0d4fdf4`｜`winwatch.sh 19f4e0328b495d28` |
| 前序（只读引用） | `~/w118a/criteria.md 110b44e10788287d`｜`W118A-report.md` 口径 `head -n -2` = `a22eb8a7881e01ba`｜`W98A-report.md` 口径 `head -n -2` = `f987bcbcce03ae91` |

---

## ① 判据（**第一条样本之前**写死：`~/w128a/criteria.md` sha16 `23a3f4f6d0d69091`）
逐字要点（全文在私有工域，此处给判据骨架）：
1. **批次规格**：**175 趟主臂**（`app-P` 修前件 `abf6879c027c5e73` × `:185` 无 WM × 同一 9 击腿）；
   **命中即停、未命中跑满**；分母只算"真尝试过且未作废"的趟。
2. **相位**：`PAD_i = round(i×2823/175) ≈ 16.13·i` B（`i=0…174`，**步长 16–17 B，正好铺满一个 2,823 B 递归环**）；**声明相位不是判据变量**，只是"找窗口"的旋钮。
3. **三态判词（三个正交读数）**：
   - `R1 CYCLE` ⇔ 栈扫描有 **≥200 次**重复族 ∧ 字节周期 **1–8 KB**；
   - `R2 SAMESET` ⇔ 环内**同时**含 ① `libwpfwin32.so` 的 `SetFocus/wpf_*` ② `IL_STUB_PInvoke|ReversePInvoke` ③ 托管 `KeyboardDevice.*|HwndKeyboardInputProvider|InputManager.` 一族 ④ `HwndWrapper::WndProc|SubclassWndProc`；
   - `R3` 几何：**`EXH`** ⇔ `rsp ≤ stack_lo+4096 ∧ 0 ≤ si_addr < stack_lo+4096`｜**`NEAR`** ⇔ 越界更大但仍在栈邻域（=W118A 修正假说 `H2` 的预言形态）｜**`WILD`** ⇔ 野地址 **或 深度 < 1 MB**；
   - **`同源`** ⇔ `R1 ∧ R2 ∧ (EXH ∨ NEAR)`；**`异源`** ⇔ `WILD ∨ ¬R1 ∨ ¬R2`（并给人格化差异）；**其余 ⇒ `NOINFO`**。
4. **未命中** ⇒ `NOINFO` ＋ 本批 95% 单侧上界 ＋ 与 W98A 同件同腿合并的上界 ＋ "再压到 ≤0.5%／≤1% 各需多少趟/槽小时"（**不自行开跑**）。
5. **阳性对照（每批 ≥2 趟）**：固定件臂 `33352e5797031999` 必须 `124/alive/落地≥1`；修前件臂批内 ≥1 趟必须 `134-stackovf`；不成立 ⇒ 该批作废。
6. **槽纪律**：分批入槽（每批 = 一次 `heavy-slot --min-avail 1500 --max-hold 1200 --wait 1800`）＋**批间释放**；批内自计 `elapsed+45 s > 1120 s` 主动收批（防 `MAXHOLD_KILL` 作废趟）；让路优先给 `#52` 收尾链。
7. **纪律**：**零 `pkill`／`killall`／`pgrep -f`**（`D-G93` 同族，今天刚出过误杀事故）；探活读 `/proc/*/cmdline`；私有 `:185` 按 PID 收。

## ② 批次规格与相位（**跑之前落盘**）
- `~/w128a/pads175.txt`（sha16 `0d3b966b7e1c3ecf`）：175 行 `i<TAB>pad`，`pad_i = round(i×2823/175)`；
  实测**步长 16/17 B 交替**，且 `pad174 → pad0` 的回绕步长也是 **16 B** ⇒ **闭合铺满一个环** ✓。
- 分批：`K0`（1 主臂 ＋ 1 对照，自检）→ `K1`(下标 1–24) → `K2`(25–49) → `K3`(50–74) → `K4`(75–99) → `K5`(100–124) → `K6`(125–149) → `K7`(150–174)；
  合计 **1 + 24 + 6×25 = 175 趟主臂**，每批**先跑 1 趟对照臂**（`app-A`／`nogdb`／`TO=50`，与 W118A `B701/B702` 逐字同款）。
- 驱动链 `chain128.sh`：批间**重新获取槽**；某批因自计 elapsed 主动收批 ⇒ 按 `resume.txt` 从缺的下标续跑（批名带 `r<下标>`）；**命中即停**。

## ③ 逐批读数（读数表见文末 §⑮ 终表；此处给纪律性读数）
- **每批一次独立入槽**，`HEAVYSLOT` 行逐批现算（waited＝**让路**、held＝本批占用）：

| 批 | `HEAVYSLOT=ACQUIRED waited=`（让路） | `RELEASED held=` | 让给谁 |
|---|---|---|---|
| `K0` | **72 s** | 82 s | W126A 门禁 |
| `K1` | **782 s** | 811 s | **W126A 的 `verify-all`**（其日志 `held=911s`，与我拿锁时刻 10:20:41 **对齐**） |
| `K2` | **854 s** | 847 s | W126A `verify-all`（pre2） |
| `K3` | **867 s** | 837 s | W126A |
| `K4` | **854 s** | 852 s | W126A |
| `K5` | **745 s** | 848 s | W126A |
| `K6` | **185 s** | 842 s | W126A |
| `K7` | **419 s** | 843 s | W126A |

⇒ **让路合计 = 4,778 s ≈ 80 min**（72+782+854+867+854+745+185+419），全部让给 `#52` 收尾链（**优先级更高**，判据 §7 明文）；**批内实占合计 = 5,880 s ≈ 98 min**（8 批 × ~12–14 min，**批间一律释放槽再重新获取**）；
`HEAVYSLOT=NOINFO reason=low-memory`／`MAXHOLD_KILL`／`HEAVYSLOT=TIMEOUT` **0 次** ⇒ **零趟因槽作废**。

## ④ 命中清单 —— `W071`（第 71 趟，`PAD=903`，11:28）＋ `W077`（第 77 趟，`PAD=1226`，11:47）：**两趟同址**
**产品签名**（两趟相同）：**应用输出 0 字节**（`app.log`/`app.err` **皆 0**）＋ 死于 `SIGSEGV` ＋ `STACKOVF=0` ⇒ **正是"静默 `139`"那一族的形态**（`W98A-L1B024`：`rc=139`、`LOGBYTES=43`＝**只有 `timeout:` 那行**、`STACKOVF=0`、`DEVICE=ok`）。

**两趟的逐字段对照（现算；"同址"是最强的复现证据）**
| 字段 | `W071` | `W077` | 说明 |
|---|---|---|---|
| `PC0` | **`0x7fff740dcdf3`** | **`0x7fff740dcdf3`** | **逐位相同** ⇒ `wpf_queue_push + 259`（`0x11df3`） |
| `PCSYM0` | `wpf_queue_push + 259` | 同 | 同一 shim `abf6879c027c5e73`、同一装载基址 |
| `BT` | `#0 wpf_queue_push` ← `#1 **PostMessageW**` | 同 | 调用者 `+0xc7` |
| 线程 | **`.NET Finalizer` tid=6** | 同 | 不是主线程 |
| `depth` | `7,088 B` | `7,088 B` | **浅栈**（vs `134` 族满 8 MB） |
| `rsp` / 栈映射 | `0x7fff7600a450` / `0x7fff7580c000-0x7fff7600c000` | **全同** | 同一线程栈 |
| `GDBSTOP_SIGS` | `11,11,11` | `11,11,11` | 启动期良性 → 崩点 → 崩点 |
| 应用输出 | **0 B** | **0 B** | 运行时的 `Stack overflow.` 一个字都没来 |
| 落地/死点 | `landed=7`，**死在 `nav2`**（`AE=480000`） | 同 | 第 7 击 |
| `stacklast.raw` sha16 | `9ff31a24fa90f56e` | `9cd325be4e5381b0` | 栈**内容**不同（指针各异）、**几何全同** |
| `maps.txt` sha16 | `6380b3f0dabc8bb9` | `d0d45bdbe7ec9ebd` | `maps_mtime_delta_s = 0.0`（**同刻**）✓ |
| `gdb.txt` sha16 | `96bcfd0b72ed009e` | `c26baa3c0f19627c` | 后者**收尾被截断**（`APP_FATE=none`，`W118A-F7` 现象）⇒ §⑨ 的第三个子条件就是为此加的 |
⇒ **同一条确定性缺陷的两个样本**（同址 ⇒ 不是漂移、不是噪声）。

**四条独立读数（现算；`W077` 在四条上**逐项相同**）**
| # | 读数 | `W071`（静默 SEGV） | `134` 族（本批 74 趟 ＋ W118A 61 趟） |
|---|---|---|---|
| 1 | **线程** | **`.NET Finalizer`（tid=6）** | **恒为主线程 `dotnet`（tid=1）** |
| 2 | **栈深** | `depth = 7,088 B`（**浅**） | `8,388,656…8,388,672 B`（**满 8 MB 栈底**） |
| 3 | **环** | `R1_CYCLE=False`（**无 ≥200 次重复族**）＋ `R2_SAMESET=False`（缺 ③托管输入族 与 ④`HwndWrapper/SubclassWndProc`） | `R1=True ∧ R2=True`（12/12 全符号化趟）、轮数 2,937–2,987、字节周期 2,808–2,856 |
| 4 | **终止形态** | **0 字节输出**，运行时的 `Stack overflow.` 一个字都没来 | 先打 62,094 帧托管栈（或 18–19 KB 折叠形）再 `FailStack` ⇒ `rc=134` |

**崩溃点（反汇编级，逐字）**
- `gdb` 的 `PC = 0x7fff740dcdf3`，符号化 = **`wpf_queue_push + 259`**（`libwpfwin32.so`，函数入口 `0x11cf0` ⇒ 偏移 `+0x103` = **`0x11df3`**）；
- `objdump -d --disassemble=wpf_queue_push app-P/libwpfwin32.so` 该处逐字：
  ```
  11de0: mov 0x8(%rbp),%rax        ; rax = t->head
  11de4: test %rax,%rax
  11de7: je  11e88                 ; head == NULL ⇒ 走正常路径
  11df0: mov %rax,%rdx
  11df3: mov 0x38(%rax),%rax       ; ← 崩在这条：p = p->next
  11df7: test %rax,%rax
  11dfa: jne 11df0
  ```
- `BT` 逐帧：`#0 wpf_queue_push`（`libwpfwin32.so`）← `#1 **PostMessageW**`（`libwpfwin32.so`，`+0xc7`）；
  浅栈扫描（8,192 B 全量倒出）另证**调用链**：`HwndWrapper::Finalize()`（JIT `QuickJitted`）／`System.GC::RunFinalizers()`／`IL_STUB_PInvoke(…WindowMessage…)`／`PostMessageW+0xc7`／`wpf_queue_push+0x103`／`wpf_lock+0xd`／`wpf_global_init+0x44`。
- ⇒ **判定点 = `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82`** 的**非法队列状态自愈分支**（`t->tail == NULL ∧ t->head != NULL`），其中 **`while (p->next) p = p->next;`（约 79 行）**踩到已被写坏的 `head` 链 ⇒ `SIGSEGV` ⇒ **静默死**。
  源码注释自己写着这条分支的存在理由（旧实现会"覆盖 head、把整条链孤儿化 ⇒ 静默丢件"）⇒ **走到这条分支，就等于"队列状态此前已经被弄坏"**。

**同刻证据（判据要求，逐项现算）**
| 项 | 读数 |
|---|---|
| `stacklast.raw` | `8,192 B`（**该线程浅栈全量**），sha16 **`9ff31a24fa90f56e`** |
| `maps.txt` | sha16 **`6380b3f0dabc8bb9`**；`maps_mtime_delta_s = 0.0`（**与 `stacklast.raw` 同刻**，v4 模板崩点覆盖式写）✓ |
| `perf.map` | `5,258,627 B`（崩点那一刻的 JIT 符号表） |
| `gdb.txt` | sha16 **`96bcfd0b72ed009e`**；停止点序列 `11,11,11`（启动期良性 → 崩点 → 崩点），`FAULTCOUNT=3 NDEEP=2 GDBSTOP_SIGS=11,11,11` |
| 落地证据 | `CLICKS_TRIED=9 CLICKS_LANDED=7 ENTRY_N=7`，`ENTRY_DETAIL=nav1,nav9,ctrl_tb,nav10,ctrl_cb,popitem,nav2` ⇒ **死在 `nav2` 那一击**（`AE=480000`＝满窗重绘＝窗口消失），前 6 击 `AE` 与全批**逐字相同**（`342624/212062/8191/35365/29274/21570`） |
| 冻结 | `cp -a run/W071 → ~/w128a/frozen/W071/`（`D-G96`：证据要活过重跑）＋ `frozen/HIT-SILENT-SEGV.txt` |

**与 W98A 那次 `139` 的人格对照**（高度一致，但**不是同一份证据**）：两者都 **0 字节应用输出**、都**死在第 7 击附近的 `nav2`**、都是 `DEVICE=ok` 且 shim 为修前件。⇒ 我把它算作"**同一族的第二个样本**"，但**不宣称**与 `L1B024` 是同一个事件（那趟的栈当年没抓到，记 `NOINFO`）。

## ⑤ 判定：**`异源`**（按先写死的三态规则，逐条给读数）
| 判据 | 读数 | 结论 |
|---|---|---|
| `R1 CYCLE` | **False**（8 KB 浅栈上无 ≥200 次重复族；`top_count=3`、`byteperiod=336`、`cycle_frames=0`） | ¬R1 |
| `R2 SAMESET` | **False**（`r2a_shim_setfocus=True` 但 `r2c_managed_input=False`、`r2d_hwndwrapper=False`） | ¬R2 |
| `R3` 几何 | **`WILD`**（`depth=7,088 B < 1 MB` 当场成立；且故障在 `wpf_queue_push` 链遍历，与本线程栈底无关） | WILD |
| ⇒ 判词 | **`异源`**（`wild∨¬R1∨¬R2` 三条**全中**） | **静默 SEGV 族 ≢ 21 帧键盘焦点回声递归** |

**机制对照（一句话各表）**
- **`134` 族**：主线程 `tid=1`，8 MB 栈被 **21 帧回声环**灌满 ~2,950 轮（`SetFocus ⇄ WM_SETFOCUS`），运行时认作 managed stack overflow ⇒ `Stack overflow.` ⇒ `FailFast` ⇒ `rc=134`。
- **静默 SEGV 族**（本批 `W071`）：**`.NET Finalizer`** 线程，**浅栈**，`HwndWrapper::Finalize()` → `PostMessageW` → **`wpf_queue_push` 的非法队列状态分支** → 链遍历踩坏指针 ⇒ 运行时不认（消息队列路径，不是栈耗尽）⇒ **进程直接静默死**（`timeout` 侧就是 `rc=139`）。
⇒ **两者唯一的共同点是"都被点击序列触发、都活不过第 8 击"**；**根因、线程、层、几何、终止路径全不同**。

**`NOINFO` 单列**：`W071` 的 `siaddr` 字段印 `0x0`，但**该指令的故障地址在语义上应是 `p+0x38`**（`mov 0x38(%rax),%rax`，且入口与循环都排除了 `p==NULL`）⇒ **该字段这一趟不可信，记 `NOINFO`**（判词**不依赖**它：浅栈一项已足以判 `WILD`）。

## ⑥ 上界与新口径计数（全部 python 现算，逐条见 §⑮）
| 口径 | 命中/有效 N | 95% 单侧上界 | 点估计 |
|---|---|---|---|
| **本批（175 趟，全部有效）** | **2 / 175** | **3.55%** | **1.14%** |
| **与 W98A 同件同腿合并**（历史 `1/60` ＋ 本批 `2/175`） | 3 / 235 | **3.27%** | 1.28% |
| **本装置全部**（W118A 61 趟有效 134 ＋ 本批 175） | 2 / 236 | **2.64%** | 0.85% |
| 跑批中途的读数（供对照，已被上表取代） | 1 / 75 ⇒ 5.86%｜2 / 100 ⇒ 2.00% | — | — |

**"再压"的代价（现算，**不自行开跑**，报主控裁）**：
- 要 **95% 单侧上界 ≤ 0.5%**：**零命中**口径需再跑 **N = 598 趟 ≈ 5.3 槽小时**（@32 s/趟）；**带 1 命中**口径需 **N = 947 趟 ≈ 8.4 槽小时**；
- 要 **≤ 1.0%**：零命中 **N = 299 趟 ≈ 2.7 h**；带 1 命中 **N = 473 趟 ≈ 4.2 h**。
**重要限定**：上界是**"静默 SEGV 发生率"的上界**，**不是**"移植没问题"的证据；本批**2 趟命中恰好落在 W98A 的历史基线 `1.7%` 量级上**（点估计 1.14% vs 1.7%）⇒ **"修前件的静默 SEGV 是稳定可复现的，不是偶发"**。

## ⑦ 阳性对照读数（**8 批 × ≥2 趟，逐批成立、无一批作废**）
- **固定件臂**（`app-A`／**`33352e5797031999`**／`nogdb`／`TO=50`）：**`K0C…K7C` 共 8 趟**，**全部 `APP_RC=124` ∧ `FAMILY=alive` ∧ `落地=8` ∧ `SHIM_CHECK=33352e5797031999`** ✓（逐趟见 §⑮ 终表对照列）
- **修前件臂**（`app-P`／`abf6879c027c5e73`）：**每批批内 ≥1 趟 `134-stackovf`**（`app.err` 认到 `Stack overflow.`）✓ —— 8 批各自的 `134` 数：`1/24/25/24/24/25/25/25`
- ⇒ **每批 ≥2 趟对照读数成立；整套读数不作废**（判据 §6）。

## ⑧ `NOINFO` 与作废趟清单（既不算绿也不算红）
1. `W071` 的 **`siaddr` 字段** ⇒ `NOINFO`（见 §⑤ 末）；
2. **`139` 的"自然发生率"**（不带 gdb）：本批一律 `ARM=gdb` ⇒ 给的是**机制读数**，不是自然发生率；有 WM 腿**未跑**（W98A/W85A 已证该腿对修前件**无检测力**）；
3. **前 27 趟无显示自证**：`winwatch` 自 10:34:28 起才有采样 ⇒ 更早的趟 `win_*` 记 `not-instrumented`（用 §⑪ 的槽互斥＋截屏审计补足）；
4. 两件之间差 **25 个导出**（W98A §3.4）⇒ 判决点最多下到"这个 `.so` 的改动集"，**不许**归因到单一函数（`wpf_queue_push` 是**崩溃点**，不是已定的**根因**点）；
5. `Xvfb 1024x768` 无 WM 与用户现场（`:10` xrdp ＋ xfwm4）**不同构** ⇒ 结论只对本装置成立；
6. **未做**：`createdump` 核臂（本批不需要）、`ulimit -s`／`PAD` 之外的相位旋钮、对 `wpf_queue_push` 的**上游写坏者**取证（那是新号的活）。
7. **原始件保留策略（收尾因本机磁盘到 94% 而做，**零信息损失**，逐条给机械证）**：
   - 删 **`stack.raw` ×173**：这 173 趟的 `stack.raw` 与 `stacklast.raw` **逐字节相同**（`cmp -s` 逐趟核过；**只有 2 趟命中不同** —— 它们各有 2 个深停止点 ⇒ **两趟命中的 `stack.raw` 与 `stacklast.raw` 都完整保留**）⇒ 删的是**重复字节**；
   - 删 **`app.both` ×183**：它就是 `cat app.log app.err`（**可一条命令重建**）；
   - **未删**：`frozen/W071`、`frozen/W077`（**整目录原样**，含 `stack.raw`/`stacklast.raw`/`maps.txt`/`perf.map`）、`W001`（报告引用的 `134` 参考趟）的 `stacklast.raw`/`perf.map`/`maps.txt`、以及**所有**趟的 `result.env`/`meta.txt`/`gdb.txt`/`clicks.txt`/`maps*.txt`/`perf.map`/`stacklast.raw`；
   - 净释放 **2,256 MB**（`/` 余量 6.5 GB → 8.8 GB）；⇒ 报告里**所有**读数仍**可从留下的件复算**（除 `stack.raw` 那份重复副本本身）。

## ⑨ 口径重扫（主控 11:4x 追加要求 ①；**改口径 ⇒ 逐字写明差异**）
**旧口径（判据字面）**：命中 ⇔ `APP_RC == 139`。
**新口径（修正后）**：命中 ⇔ **死于 `SIGSEGV`**（`RC==139` ∨ `APP_FATE` 含 `SIGSEGV` ∨ `gdb.txt` 含 `Program terminated with signal SIGSEGV`）∧ **应用输出 0 B**（去掉 `timeout:` 那行，`W98A-F7`）∧ `STACKOVF==0`。
**为什么改**：`ARM=gdb` 下 `RC` 是 **gdb 自己的 rc**，与应用结局无关 ⇒ 旧口径在 gdb 臂上**天生打不着**；同一个错还连坐出**假可疑**（`FAMILY=other` ⇒ `EXTERNAL_KILL_SUSPECT=yes`）。

**重扫结果（`bin/rescan128.py`，三代仪器一起扫，现算）**
| 树 | 趟数 | 旧口径命中 | 新口径命中 | 旧口径**漏判** | 旧口径**误判** | 被标 `EXTERNAL_KILL_SUSPECT=yes` | 结论是否改变 |
|---|---|---|---|---|---|---|---|
| `~/w128a`（本批，**跑满 175**） | 183（175 主臂 ＋ 8 对照） | **0** | **2（`W071`,`W077`）** | **`W071`,`W077`** | 无 | **2（同为这两趟）** | **改变**：漏 2 命中 ＋ 误剔 2 趟 |
| `~/w118a`（上批 41 趟＋前置批） | 71 | 0 | 0 | 无 | 无 | 0 | **不变** |
| `~/w98a`（历史 60 趟/腿等） | 128 | **1（`L1B024`）** | **1（`L1B024`）** | 无 | 无 | 0 | **不变**（那趟是 `nogdb`，`rc=139` 本就可见） |

⇒ **差异趟清单 = `[W071, W077]`**，两处错一起犯：**① 漏判命中**（真信号被记成"没信息"）；**② 误剔**（同一趟被当"外部打断"剔出分母）。

**⚠️ 新口径还必须带第三个子条件（跑批中途我自己撞上，当场修）**：`W077` 的 `gdb` 记录**在收尾被截断**（`W118A-F7` 的已知现象）⇒ `result.env` 里 **`APP_FATE=none` ∧ `NDEEP=0`**，于是"看 `APP_FATE` 含 SIGSEGV"这条**也失灵**、`W077` 被判成 `OTHER` 并**剔出分母**（**又漏一趟命中**）。
⇒ **最终口径（判据逐字，三条件合取）**：
```
SILENT_SEGV_HIT ⇔ 应用输出 == 0 B（去掉 `timeout:` 行）
                ∧ STACKOVF == 0
                ∧ 死于 SIGSEGV：RC==139 ∨ APP_FATE 含 SIGSEGV
                              ∨ gdb.txt 含 "Program terminated with signal SIGSEGV"
                              ∨ gdb.txt 里存在 W118A-STOP-N（N≥1）且 signo=11      ← 新增，抗截断
```
最后那一支**直接从 `gdb.txt` 的停止点行读**（不依赖收尾打印）⇒ 记录被截断也认得出。
已写进 `bin/rescan128.py`／`bin/analyze128.py`（函数 `gdb_nonstart_segv()`，docstring 写明"为什么需要它"）。
**回代核对（防假阳）**：`W118A` 的 `B101–B105`（我登记过的"参数没替换"作废趟，应用 0 字节）**没有 `N≥1` 的 SIGSEGV 停止点** ⇒ **不算命中** ✓；`G20301` 只有启动期那一拍 ⇒ 仍判"**说不清**、剔除" ✓（与 W118A §15.1 的原判一致）。

⇒ **修正后的处置**：`W071`／`W077` **计入分母且计为命中**；`EXTERNAL_KILL_SUSPECT=yes` **不再**单独构成剔除理由（只点名）——理由：这两趟都有 **gdb 亲自捕获的 3 次 `SIGSEGV`** 且停在**我方 shim 的 PC** 上，**外部 kill 长不成这样**。

## ⑩ 两条仪器缺陷（**建议开号；号码由主控统一分配，我不自开**）

**建议新号 A —— 仪器/解析缺陷·"多词线程名 ⇒ 整行不匹配"族**
- **判词要件**：`W118A` 的 STOP 行正则用 `thread=(\S+)`，而 gdb 打印的线程名**可以含空格**（`.NET Finalizer`／`.NET TP Worker`…）⇒ **整行 `re.findall` 不匹配** ⇒ 崩在**非主线程**的趟被解析成"**没有任何 deep 停止点**" ⇒ **一律误判 `NOINFO`**。
- **危险方向 = 漏判命中**（把真信号读成"没信息"），**不是**造假红。
- **现场**：`sig.py`／`judge128.py` 首读 `W071` 都是 `nstop=1 ndeep=0 verdict=NOINFO`；把 `thread=(\S+)` 改成 **`thread=(.*?)`** 后立刻出真读数（`nstop=3 ndeep=2 tid=6 thread=.NET Finalizer`）。
- **写域纪律**：我改的是**我自己那份副本** `~/w128a/bin/{sig.py,judge128.py}`，**未触碰 `~/w118a/**`**（只读复制）。
- **建议判据（回归牙）**：任取一份 `gdb.txt`，断言 `len(re.findall(STOP_RE)) == 文件里 'W118A-STOP-' 行数`；**两极化例**：合成一行 `thread=.NET Finalizer tid=6`（必须匹配）vs `thread=dotnet tid=1`（必须匹配）。

**建议新号 B —— 口径缺陷·"`ARM=gdb` 下命中判据不可达 ＋ 假可疑"族**
- **判词要件**：`ARM=gdb` 时 `result.env` 的 `RC`／`APP_RC`／`VERDICT` 记的是 **gdb 的 rc**（本批 `W071` 记成 `RC=0`、`VERDICT=exit0`、`FAMILY=other`），**应用结局只出现在 `APP_FATE`／`APP_TEXT_BYTES`**；而"命中即停"的口径写成 `APP_RC=139` ⇒ **天生打不着**。
- **连坐**：`FAMILY=other ∧ RC!=124 ⇒ EXTERNAL_KILL_SUSPECT=yes` ⇒ **假可疑** ⇒ 真命中被**剔出分母**。
- **正确口径（判据逐字）**：`SILENT_SEGV_HIT ⇔ (RC==139 ∨ APP_FATE 含 SIGSEGV) ∧ 应用输出==0 B（去 timeout 行）∧ STACKOVF==0`；
  `EXTERNAL_KILL_SUSPECT` **只**可在"**没有任何正向产品死亡归属**"时用于剔除（有 `gdb` 捕获的 `SIGSEGV` 停在**我方 shim PC** 上 ⇒ **不得**判外部 kill）。
- **影响面（实算）**：本批 **2 趟**（`W071`、`W077`──后者还叠了"记录被截断"这一层）；`W118A`／`W98A` 重扫**零影响**（§⑨）。

## ⑪ 装置被闸门借用 —— 审计（主控 10:2x 告警；**机械核对**）
**事实**：`W126A` 的 `verify-all`（其 pmax-hold 1500 s）在 **10:05:30 → 10:20:41** 持槽期间，其"复用外部 Xvfb"逻辑**挑中了我的 `:185`**（只验可连、不验几何）。
**影响评估：与我的趟零重叠**（两条独立日志互证）：
- 我方 `K0` 持槽 **10:04:08 → 10:05:30**（`held=82s`，最后一趟 `W001` 的 `TS_END=10:05:30`）＝ 闸门的 `ACQUIRED` 时刻；
- 我方 `K1` 的 `HEAVYSLOT=ACQUIRED waited=782s`（**10:20:41 拿到锁**，即 10:07:39 起就在等）＝ 闸门的 `RELEASED` 时刻（其日志 `RELEASED rc=1 held=911s`，`10:05:30 + 911 s = 10:20:41` ✓）。
⇒ **闸门跑 X 套件的整个 911 s 里，我一趟都没在跑**（**槽互斥**把两条时间线切成互不相交的两段）。
**"我屏上有没有第三方的窗"三段证据**：
1. **期望值**：`:185` 空闲时子窗口数 = **0**（`xwininfo -root -children` 现读 `0 children`；跑趟时 7–8 个，全部是我方指纹）；
2. **逐像素**：`W001`（借用前 10:04:59）与 `K1` 各趟的 `conv0.png` **AE = 0**（`W002/004/006/010/015/020/024` 全 0）⇒ 屏上连一个外来窗都没有；
3. **点击 AE 向量**：`K1` 各趟**彼此逐字相同**；与 `W001` 唯一差异是 `nav10: 35347 vs 35365`（**18 像素**），而 `35347` 在 **W118A 借用前那一批 71 趟里出现 8 次**（`35365` 55 次）⇒ **本装置原有抖动**，外来窗的签名是**几十万像素**级，不是 18。
**结论**：**0 趟剔除**，分母不变；`§⑨` 的 `1/75` 不受影响。
**后续风险已消失**：`W126A` 几何守卫落地后，其 `07b-verify-all-pre2` 日志现读 `X-REUSE=reused display=:97（已运行；几何 1280x1024 相符）` ⇒ **不再挑 `:185`**；我**不搬显示号**（搬了要重取装置自检，且 `:185` 已无风险）。
**新增机读自证**：`bin/winwatch.sh`（PID 记在 `~/w128a/winwatch.pid`）每 5 s 采样 `:185` 的**子窗口数 ＋ 窗口指纹** → `logs/winwatch.log`；
`mktable128.py` 把每趟的 `[TS_START, TS_END]` 与该采样**配对**，输出 **`win_samples / win_cnt_min / win_cnt_max / win_foreign / win_own_seen / win_span_s`** 六列进 `runs.tsv`（"外来窗"规则在**分析侧**算：名字不在 `{HandyControlDemo, SystemResourceNotifyWindow, MediaContextNotificationWindow}` **且**几何不是 `800x600`；另有**计数闸**：>8 即报）。
**已知局限**：指纹对**无名**窗不友好（`(has no name)` 含空格被切碎）⇒ 无名的外来窗**只**能被计数闸抓到（记 `NOINFO`：本批计数闸**从未触发**，`win_cnt_max ≤ 8`）。

## ⑫ 自伤与纪律偏离（如实入册，不辩解）
| 编号 | 症状 | 真因 | 处置 |
|---|---|---|---|
| `W128A-F1` | `K0` 的 `STATUS.md` 行里 `family=`／`landed=` 读成空，且对照自检误报 `CTRL **FAIL**` | 我把 `result.env` 当"行首键值"读，而它多处是**同行多键**（`DEVICE=ok VERDICT=… OOM=0`、`APP_TEXT_BYTES=… FAMILY=…`） | 当场改 `gv(){ grep -ao 'KEY=[^ ]*' }`；台账权威口径改为 `mktable128.py` **重算**（`runs.tsv` 全部由 `result.env` 重建）⇒ 该批**未受影响**（`K0C` 实为 `124/alive/落地 8` ✓） |
| `W128A-F2` | `judge128.py` 首读 `W071` 判 `NOINFO` | 与**建议新号 A** 同源（`thread=(\S+)`） | 改 `thread=(.*?)`（**只改我自己那份副本**）；改后 `W001` 复算**逐字不变**（`top_count=5915 byteperiod=1600 R1/R2=True R3=EXH`）⇒ 无回归 |
| `W128A-F3` | `judge128.py` 单趟耗时 **76 s** | 逐帧 `mapof` 线性扫 maps ＋ CANON 循环二次符号化 | 改**二分 + 记忆化**（`--nosig` **1.3 s**）；**语义等价**以 `sig.py` 交叉核对为准（`xcheck_agree=True`，`top_count/byteperiod` 逐字相同） |
| `W128A-F4` | `winwatch` 起了**两个实例**（日志格式混行） | 我用 `for /proc/*/cmdline` 抓 PID 时**匹配到自己的 `bash -c` 包装行** | 按 **PID** 收掉两个，重起单实例（PID 由**日志自报**行取）；混行日志留档 `logs/winwatch.v2mixed.log` |
| **口径偏离** | **命中后没有停批** | 判据字面是 `APP_RC=139`（**不可达**，见建议新号 B），而 `W071` 的**产品签名**是静默 SEGV | 按主控裁定：**跑满 175**（上界需要 N）；`W071` 已**冻结**并**计为命中**；此处**如实登记为"判据文字与实际字段不符"**，**不是**"我放宽了判据" |
| 宿主/环境 | `Xvfb` 一次起失败（`logs/` 不存在） | 我在建目录前就 `nohup` 了 | 建目录后重起（`xvfb185.pid` 记录 PID） |
**纪律正项**：**全程零 `pkill`／零 `killall`／零 `pgrep -f`**（收进程只按 PID、探活读 `/proc/*/cmdline`）；私有 `Xvfb :185` 按 PID 收（收工核对残留）；**未碰**产品件／牙／路由件／冻结物；**未跑** `verify-all`／波链；**未构建**。

## ⑬ ≤8 行大白话小结
1. **要把的那只"静默 `139`"抓到了，而且抓到两趟**（`W071` 第 71 趟、`W077` 第 77 趟），**两趟崩点 `PC` 逐位同址**（`0x7fff740dcdf3`）；`stacklast.raw`／`maps.txt`／`perf.map` **同刻齐全**（`maps_mtime_delta_s=0.0`），两趟都已冻结。
2. **它跟 `134` 那条递归不是一回事**：崩在 **`.NET Finalizer` 线程**（不是主线程）、**浅栈 7 KB**（不是满 8 MB）、**没有那个 21 帧回声环**、**应用一个字都没打**。
3. **崩点指得很死**：`PC = wpf_queue_push+259`（`0x11df3` 的 `mov 0x38(%rax),%rax`），回溯 `PostMessageW`，链是 `HwndWrapper::Finalize()` → P/Invoke → `PostMessageW` → `wpf_queue_push`。
4. **判定点**：`src/WpfGfx.Linux.Native/src/win32_msg.c:57-82` 的**非法队列状态自愈分支**，`while (p->next) p = p->next;`（约 79 行）踩到写坏了的 `head` 链 ⇒ 建议**独立开号**（"消息队列被写坏"的下游症状，与 134 递归不同源）。
5. **判词 `异源`**；`siaddr=0x0` 与指令语义不符 ⇒ 该字段 `NOINFO`（判词不依赖它：浅栈一项已足以判 `WILD`）。
6. **顺带挖出两条仪器/口径缺陷**（多词线程名整行不匹配 ⇒ **漏判命中**；`ARM=gdb` 下 `APP_RC=139` 不可达 ＋ 假可疑 ⇒ **误剔趟**），已按"建议新号 ＋ 判词要件"交主控统一开号。
7. **口径重扫**：本批旧口径**漏 2 命中 ＋ 误剔 2 趟**（就是 `W071`/`W077`；`W077` 还暴露了新口径自己的第三个漏洞 ⇒ 已补"从 `gdb.txt` 停止点行直接读"那一支）；`W118A`／`W98A` 重扫**零影响**、结论不变。
8. **跑满 175 趟、零作废**（173×134 ＋ 2×静默 SEGV，点估计 **1.14%**、95% 上界 **3.55%**；对照臂 **8/8 活满**）；**让路 ≈80 min**（K1 782／K2 854／K3 867／K4 854／K5 745／K6 185／K7 419 s）全给 `#52` 收尾链；**装置借用与我的趟零重叠**（0 趟剔除）。

## ⑭ 复算命令（照抄即可；全部现算，不手抄）
```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd ~/w128a
# 0) 判据与器材
sha256sum criteria.md pads175.txt | cut -c1-16
for f in bin/*.sh bin/*.py; do printf '%s %s\n' "$(sha256sum $f|cut -c1-16)" $f; done
# 1) 单变量（差异应恰好 1 件）
diff <(cd app-A && find . -type f|sort|xargs sha256sum) <(cd app-P && find . -type f|sort|xargs sha256sum) | grep -c '^[<>]'
# 2) 台账权威重建 ＋ 分析（逐批表、几何、上界）
python3 bin/mktable128.py && python3 bin/analyze128.py
# 3) 命中趟的三态判词（**关键读数**；必须与 sig.py 交叉一致）
python3 bin/judge128.py run/W071              # verdict=异源
python3 bin/judge128.py run/W071 --nosig      # 快版（1.3 s）
python3 bin/sig.py     run/W071               # 交叉核对（W118A 原版分类器）
# 4) 崩溃点定位（反汇编级）
objdump -d --disassemble=wpf_queue_push app-P/libwpfwin32.so | sed -n '/11de0:/,/11dfa:/p'
grep -a 'PCSYM-1=\|BT-1' run/W071/gdb.txt
# 5) 同一命中的"线程/深度/无环"三条读数
grep -a 'W118A-STOP-' run/W071/gdb.txt
stat -c '%y %n' run/W071/maps.txt run/W071/stacklast.raw    # 同刻（delta 0.0 s）
# 6) 口径重扫（三代仪器）
python3 bin/rescan128.py
# 7) 显示借用审计（零重叠）
grep -a 'HEAVYSLOT=ACQUIRED\|RELEASED rc=' logs/K0.log logs/K1.log
grep -a 'TS_START' run/W001/meta.txt; grep -a '^TS_END=' run/W001/result.env
compare -metric AE run/W001/conv0.png run/W010/conv0.png null:   # 0
# 8) 显示自证（每趟显示号＋窗口数）
awk -F'\t' 'NR==1||$2=="K5"{print $1,$5,$32,$33,$34,$35,$36}' runs.tsv
```

---
### 报告口径两行
- **全文 sha256**：见下方 `§⑯` 的 `报告自身 sha256`（写入后现算）。
- **`head -n -2` 口径**：`head -n -2 build/MilBridge/W128A-report.md | sha256sum` 的 sha16 见 `§⑯`（"正文含本行"的字节）。

## ⑮ 终表（跑满后由 `analyze128.py` / `rescan128.py` 现算，逐字粘贴）
### ⑮-1 逐批终表（`python3 bin/mktable128.py && python3 bin/analyze128.py` 现算）
```
主臂趟 = 175 ｜ 有效分母 = 175 ｜ 剔除/作废 = 0 ｜ 对照臂 = 8
结局分布（有效）: {'134': 173, 'SILENT-SEGV': 2}
剔除/作废逐趟: 无
EXTERNAL_KILL_SUSPECT=yes 的趟（不再据此剔除，仅点名）: ['W071/cls=SILENT-SEGV', 'W077/cls=SILENT-SEGV']
静默 SEGV 命中: 2 ['W071', 'W077']
```
| 批 | 主臂 | 有效 | 剔除 | `134` | 静默 SEGV | alive | 对照臂（app-A 固定件） | 槽 waited／held |
|---|---|---|---|---|---|---|---|---|
| `K0` | 1 | 1 | 0 | 1 | 0 | 0 | `124/alive/8` | 72 s ／ 82 s |
| `K1` | 24 | 24 | 0 | 24 | 0 | 0 | `124/alive/8` | 782 s ／ 811 s |
| `K2` | 25 | 25 | 0 | 25 | 0 | 0 | `124/alive/8` | 854 s ／ 847 s |
| `K3` | 25 | 25 | 0 | 24 | **1（`W071`）** | 0 | `124/alive/8` | 867 s ／ 837 s |
| `K4` | 25 | 25 | 0 | 24 | **1（`W077`）** | 0 | `124/alive/8` | 854 s ／ 852 s |
| `K5` | 25 | 25 | 0 | 25 | 0 | 0 | `124/alive/8` | 745 s ／ 848 s |
| `K6` | 25 | 25 | 0 | 25 | 0 | 0 | `124/alive/8` | 185 s ／ 842 s |
| `K7` | 25 | 25 | 0 | 25 | 0 | 0 | `124/alive/8` | 419 s ／ 843 s |
| **合计** | **175** | **175** | **0** | **173** | **2** | 0 | **8/8 全绿** | 让路 4,778 s ／ 实占 5,880 s |

**几何/形态读数（现算，只作并列读数）**
- `si_addr − 长满后栈底`：`−8` ×96、`−16` ×18、`−40` ×9、`−24` ×8、`−56`/`−104`/`−120` 各 ×7、…（**2 趟静默 SEGV 落"野地址"档**，即 `siaddr=0x0` 相对线程栈）；
- **崩溃拍**（`ENTRY_DETAIL` 末项）：**`tab3` ×172**（第 8 击）｜**`nav2` ×2**（＝两趟静默 SEGV，第 7 击）｜`nav3` ×1（`W042`：9 击全落地后仍 `134`，死在第 34 s）；
- **日志形状**（`D-G87`，**只作并列读数**）：折叠形（18–19 KB）**32 趟**（占 173 趟的 18.5%）／全量（>1 MB）**141 趟** —— 与 `D-G87` 记的 23% 同量级。
  ⚠️ **口径更正（收尾清盘时我自己抓到）**：`W071`/`W077` 的**应用输出是 `0` 字节**，**不是**"折叠形"；把 0 字节当折叠形会得到 **34** 这个**偏大**的数 ⇒ **正确读数是 32**（0 字节的趟**不计入**形状分布）。这再次印证 `D-G87` 的立场：**形状不能当判别量**。

### ⑮-2 口径重扫终表（`python3 bin/rescan128.py` 现算，三代仪器一起扫）
```
== ~/w128a ==  趟数=183（175 主臂 + 8 对照）
  旧口径命中（rc/APP_RC=139）: 0 []
  新口径命中（静默 SEGV）  : 2 ['W071', 'W077']
  被标 EXTERNAL_KILL_SUSPECT=yes: 2 ['W071', 'W077']
  新命中−旧命中（旧口径漏判的）: ['W071', 'W077']
  旧命中−新命中（旧口径误判的）: 无
  134 族（STACKOVF=1）: 173
== ~/w118a ==  趟数=71
  旧口径命中: 0 ｜ 新口径命中: 0 ｜ 漏判: 无 ｜ 误判: 无 ｜ 结论不变
== ~/w98a ==  趟数=128
  旧口径命中: 1 ['L1B024'] ｜ 新口径命中: 1 ['L1B024'] ｜ 漏判: 无 ｜ 误判: 无 ｜ 结论不变
```
⇒ **差异趟清单 = `[W071, W077]`**（旧口径漏判 2 ＋ 误剔 2）；**上界因重扫而下修**（若沿用旧口径会得到"0/175 ⇒ 1.69%"，但那是**漏判出来的假绿**）。

### ⑮-3 显示自证终表（主控 10:2x 要求 ②；`win_*` 六列在 `runs.tsv`）
```
win_foreign=no 的趟 = 150（子窗口数范围 0..8，全部是我方指纹）
not-instrumented   = 25（winwatch 自 10:34:28 起采样 ⇒ 更早的 25 趟无采样，用 §⑪ 的槽互斥＋截屏审计补足）
其它/异常           = 0
winwatch 采样本身：1,832 行（5 s 一拍），其中"非零窗"采样 911 行（= 正在跑趟）
```
### ⑮-4 95% 上界与"再压"代价（`analyze128.py` 现算）
```
本批:                        2/175  ⇒ 95% 单侧上界 = 3.55%（点估计 1.14%）
与 W98A 同件同腿合并:        3/235  ⇒ 95% 单侧上界 = 3.27%（点估计 1.28%）
本装置全部（＋W118A 61 趟）: 2/236  ⇒ 95% 单侧上界 = 2.64%
再压到 ≤0.5%：零命中需 N=598（≈5.3 槽小时 @32s/趟）；带 1 命中需 N=947（≈8.4 h）
再压到 ≤1.0%：零命中需 N=299（≈2.7 h）；              带 1 命中需 N=473（≈4.2 h）
```

## ⑯ 报告自身口径（**两行都给**）
- **FULL sha256**（整文件口径，**含**末尾两行）＝ **见交件消息与 `~/w128a/STATUS.md` 末节**（自指：把该值写进本文件就会改变它 ⇒ 不落在文件里，只在文件外落账 —— 这是本仓既有口径）。
- **`head -n -2` 口径 sha16** ＝ 见本文件最后一行。
（末两行 = 本行 ＋ sha16 行；口径 `head -n -2 <本文件> | sha256sum | cut -c1-16`，即"正文含本行"的字节）
本报告 sha16 = `d014ebd90d45840e`
