# VSegv — `t11` 独立复验：崩溃族（反极性 / 两极化检测力 / 上界与功效门 / 基线率闸）

**判词：`needs_revision`**（findings 见 §8）。**产品修法与测量核心我复现了**（夹具反极性、175 腿台账逐腿可复算、上界算术逐条相符）；
但**账目里那句「同 N 同体制可比」被我的现取证据推翻**，且仓内**自己的**基线率闸现取判 `VOID-PREMISE`。

- 车道：`verifier`（`t11`，attempt `eacccfe7-893b-47dc-8be3-bb20f8adf294`）；判据**先写**：`~/w29x/criteria.md`（`5,428 B`，落盘 `06:12`，在取数之前）。
- 我的读时刻：`2026-09-28T06:10:15 … 06:35:14+08:00`。资源现取（`06:10:15`）：`df_avail_kB=87,695,928`、`mem_avail_MB=3916`；三支腿批全程 `MemAvailable` 最低约 `3.0 GB`，`df` 全程 ≥ 87 GB。
- **只读 `$N`**：我的应用副本 / 夹具 / 腿目录全在 `~/w29x/`；显示 `:231`（**租约独占**，`display-lease.sh acquire` 现取 `DISPLAY_LEASE=ACQUIRED prior_absent=1 exclusive_now=1`），我自起 `Xvfb :231`（`pid=2582115`）并**按 PID 收尾**；进程一律**按 PID**，全程无 `pkill`/`killall`/`pgrep -f`；仓内唯一写入 = 本报告。

---

## §1 产品修法：**独立复算**（`V1`＋`V2`，全部我自己动手）

**① 判定点（现取行号＋原文）**：`src/WpfGfx.Linux.Native/src/win32_msg.c`（sha16 **`4a88fffb1a0cd7f1`**）
- `:56` `static void wpf_queue_corrupt_report(...)`｜`:84` `void wpf_queue_push(wpf_thread *t, const WPF_MSG *m)`
- `:104` **`} else if (t->head) {`** ← 修法所在的那一支；`:122` `wpf_msg_node *quarantine = t->head;`（只记指针）
- `:123-125` `n->next = NULL; t->head = n; t->tail = n;`｜`:126` `wpf_queue_corrupt_report(t, quarantine, m->message, …)`｜`:128` `} else {`｜`:131` `t->tail = n;`
⇒ 修法**落在** `wpf_queue_push` 那条链上，且同一处注释逐字保留旧实现（`wpf_msg_node *p = t->head; while (p->next) p = p->next;`）。

**② 反汇编（我自己 `objdump`）**：`objdump -d --disassemble=wpf_queue_push`
| 件 | `mov 0x38(%rax),%rax`（`48 8b 40 38`）计数 |
|---|---|
| `33352e5797031999`（`~/w128a/app-A`，修前） | **1**（`@0x14633`） |
| `abf6879c027c5e73`（`~/w128a/app-P`，修前） | 1 |
| **`e8127a3d7128d417`（现件）** | **0** |
| `43fcb63310be0de4`（**我回退那一支**的重建件） | **1** |

**③ 构建可复现 ＋ 真正单变量（本节最强的一格）**：我把 `src/WpfGfx.Linux.Native` 复制到 `~/w29x/shim-src/` 用**仓内同一个入口** `build-shim.sh` 重建 ⇒
```
bin/libwpfwin32.so  sha16 = e8127a3d7128d417  336,592 B  ⇒ cmp 与仓内件 BIT_IDENTICAL=yes（两次）
```
然后把 **`else if (t->head)` 那一支的支体回退**（`:105–127` 的 23 行 → 旧 3 行，别的**一个字节没动**）重建 ⇒ `43fcb63310be0de4`／336,512 B。⇒ 这才是"只差那一支"的单变量对照。

**④ 夹具矩阵（我自己的 `gcc` 构建，同一二进制 `LD_LIBRARY_PATH` 换 `.so`）**：
| 输入 | `.so` | `rc` | 逐字读数 |
|---|---|---|---|
| `corrupt 0x102` | `33352e5797031999` | **139** | `T10_CORRUPT_INJECT head=0x102 tail=NULL` ＋ `T10_SEGV si_addr=0x13a` |
| `corrupt 0x102` | `abf6879c027c5e73` | **139** | 同上（＝报告 §8 的"修前件"读数**逐字重现**） |
| `corrupt 0x102` | **`e8127a3d7128d417`** | **0** | `[QUEUE_CORRUPT] 站点=wpf_queue_push 原因=tail==NULL 而 head!=NULL（链已不可信） 可疑链头=0x102 形态判据=**必非节点指针** 对策=隔离可疑链(零解引用)+本条消息照常入队` ＋ `T10_SURVIVED count=1 head=0x…300 tail=0x…300 next=(nil)` |
| `corrupt 0x102` | **`43fcb63310be0de4`（我回退的重建）** | **139** | `T10_SEGV si_addr=0x13a`（**同源码、只差那一支 ⇒ 命中重现**） |
| `calibrate 0` | 任一 | 139 | `T10_SEGV(mode=calibrate) si_addr=0x38 si_code=1` |
| `calibrate 0x102` | 任一 | 139 | `si_addr=0x13a si_code=1` |
| `calibrate 0xdeadbe0038` | 任一 | 139 | `si_addr=0xdeadbe0070 si_code=1` |

⇒ 修法**有效**、`si_addr = P + 0x38` 两点（＋一点）校准**逐位成立**、`si_code=1` 可采。**这一条与 §8 的 findings 无关**（那是账目问题）。

---

## §2 175 腿台账：**我自己的第三实现逐腿复算**（`V3`，零差）

我按仓内参考实现（`run-silenthit-legs.sh:118-241`）**文档化的语义**自写 `~/w29x/bin/judge29.py`（不调 `judge44.py`、不调仓内牙），从 `~/w44a/run/<tag>/` 的**原始件**重算每腿：

```
TRIM_GATE=ok rows=23 trimmed_needles=7 declared_tags=19 trim_sha16=4270ab3da7a1d6d8
JUDGE29_DENOM legs=182 hits=0 noinfo=0          （175 主臂 ＋ 7 对照）
逐腿比对 legs.tsv（列 RAW/TRIMMED/GATE/STACKOVF/BRANCH/FAMILY/UNDECL/HIT/RC）⇒ legs_with_any_diff = 0
```
- **仓内唯一实现**（我自己跑）：`SILENTHIT=PASS`、`SILENTHIT_RC=0`；**第二实现**（我自己跑）：`JUDGE44_DENOM legs=175 hits=0 noinfo=0 n134_or_stackovf=0 alive_timeout=175`／`ub95=1.6973%` ⇒ 三份实现**逐腿一致**。
- **具名台账零出现**（我自己 `grep` 175 个腿目录）：含 `[QUEUE_CORRUPT]` 的腿 **0**、`[POSTMSG_DEAD_TARGET]` **0**、`SIGSEGV` **0**、`Unhandled exception.` **0**、`Stack overflow` **0**；`RAW=115` 的腿 **175/175**（那 115 B 逐字 = 一条 `[G147_WORKAREA] source=fallback-screen … prop_n=0`）。
- 台账指纹：`~/w44a/legs.tsv` = **`f94be573393b9971`**（与报告一致）、`runs.tsv` 182 行、7 批各 25 腿 ＋ 1 对照（我从 `~/w44a/STATUS.md` 的 7 行 `完成 A?` 逐行取出：`ok=25 skip=0 bad=0 ctrl_ok=1 n134=0 hit139=none elapsed=1314–1315 s`）。

---

## §3 我**自己的**两极化腿批（`V4`；`display=:231`，`WM_CHECK=_NET_SUPPORTING_WM_CHECK: no such atom`＝无 WM，与 `:186` 同档）

臂/件全在 `~/w29x/`（私有副本，`sha16` 逐件现取）；配方 `mode=click`／9 击腿／`PAD` 取自**同一份** `pads175.txt`（我现取 `sha16 = 0d3b966b7e1c3ecf`，与 `~/w128a/pads175.txt` **逐位相同**）。

| 臂 | 应用目录 | `libwpfwin32.so` | arm／TO | N | 结局 | `RAW`/`TRIMMED` | `HIT` |
|---|---|---|---|---|---|---|---|
| **POST** | `app-POST`（＝`app-A` 逐字节副本 ＋ 只换现件） | **`e8127a3d7128d417`** | nogdb／50 | 10 | `124`×10（alive） | `115`/`0` | **0** |
| **PRE** | `app-PRE`（`~/w128a/app-A` 副本） | `33352e5797031999` | nogdb／50 | 10 | `124`×10（alive） | `242`/`0` | **0** |
| **HIS**（**历史主臂体制**） | `app-PREP`（`~/w128a/app-P` 副本） | **`abf6879c027c5e73`** | **gdb／75** | 4 | **`134`×4／family=`134-stackovf`／`stackovf=1`／`faults=3`／`sigs=11,11,6,`** | `18.9 K`–`6.4 M` | 0 |
| **HISA**（消歧） | `app-PRE`（app-A） | `33352e5797031999` | **gdb／75** | 2 | `124`×2（alive，`faults=1`／`sigs=11,`） | `242`/`0` | 0 |

- **装置自证**：三批每腿 `CLICKS_LANDED ∈ {7,8}`（`entry=nav1,nav9,ctrl_tb,nav10,ctrl_cb,popitem,nav2,tab3,nav3` 全在）、`OOM=0`、`device=ok`；批 1 `elapsed=1008 s`（20 腿）、批 2 `142 s`（4 腿）、批 3 `151 s`（2 腿）；窗口 `2026-09-28T06:13:12–06:34:23`。
- **仪器同构（强证据）**：我的 POST 臂 10 腿**逐格**与 `t44` 175 腿同形（`RAW=115／TRIMMED=0／STACKOVF=0／BRANCH=none／FAMILY=alive／rc=124`）⇒ **器件/口径在我手里没有走形**。
- 🔴 **检测力（我这一批的空白，如实）**：我对**静默 SEGV**（历史点估计 `1.14%`）**零功效** —— N=10/臂 ⇒ 95% 单侧上界 `25.89%`；N=20 ⇒ `13.91%`。我的样本**既证实不了也证伪不了** `1.6973%`。它**能**证的是：① 装置可用；② **历史主臂的 `134` 族在我手里 4/4 复现**（`app-P`＋`gdb`＋`TO=75`）；③ **同一 `gdb` 臂换 `app-A` 则 0/2 复现** ⇒ `134` 族的判别量**不是 PAD**（见 §8-F4）。

---

## §4 上界与功效：我自己数值解一遍（`V5`）

| 口径 | 我算 | 声明 | 差 |
|---|---|---|---|
| `0/175` 95% 单侧上界（`1−0.05^(1/175)`） | **1.697278%** | `1.6973%` | 2.2e-5 pp ✅ |
| `2/175` Clopper-Pearson 单侧上界（解 `P(X≤2;175,p)=0.05`） | **3.553694%** | `3.5537%` | ✅ |
| 门 `≥131 腿` | **2.260869%** | `2.26%` | ✅ |
| 门 `≥299 腿` | **0.996915%** | `1.00%` | ✅ |
| `2/175` 点估计 | 1.142857% | `1.14%` | ✅ |

判别式逐字（在两处我自己的样本上现算）：`SILENT_SEGV_HIT ⇔ APP_TEXT_BYTES_TRIMMED==0 ∧ STACKOVF==0 ∧ SEGV_BRANCH≠none`，且 `UNDECL≠0` 或 `phase=teardown` ⇒ `NOINFO`（不进分母）。我的实现与仓内实现同形且逐腿同判（§2）。

---

## §5 同窗基线率闸：**现取**（`V6`）—— 本件最重要的"反证"

**① 我要的窗（我自己从台账算）**：`~/w44a/runs.tsv` 主臂 `n=175`、`ts_end` 从 `2026-09-28 03:35:57` 到 `06:07:37` ⇒ 与报告 §11④ 的 `0/175 @ 2026-09-28T03:35:57–06:07:37` **逐字相符**。

**② 历史基线那一侧（我自己读 `~/w128a/runs.tsv`，183 行）**：
- 主臂 175 腿**全部** `arm=gdb`／`shim=abf6879c027c5e73`／`TO=75`／`disp=:185`；对照 8 腿 `arm=nogdb`／`shim=33352e5797031999`／`TO=50`。
- `app_rc` 分布：`134`×173、`124`×8（＝对照）、`1`×1、`0`×1；窗 `2026-09-23 10:04:58 – 13:04:05`。
- 那两个"静默 SEGV 命中"逐字：`W071`（`app_rc=0`／`family=other`／`sigs=11,11,11,`／`faults=3`／`pcsym0=wpf_queue_push`／**`ext_kill_suspect=yes`**／**`app_outcome_observed=no`**）与 `W077`（`app_rc=1`，同形）⇒ **两条都是 `gdb` 臂读数、且带"外部击杀可疑"标记**。

**③ 仓内自己的闸（我跑）**：
```
bash build/MilBridge/tools/baseline-rate-gate.sh \
  --registered '2/175@2026-09-23T10:04:58+08:00-13:04:05+08:00+display=:185' \
  --observed '0/175' --gate 0.035537 --effect 0.011429
⇒ BASELINERATE=FAIL  BASELINERATE_REASON=VOID-PREMISE ① ci_upper(0.0152) < gate(0.0355)；② observed(0.0000) < effect(0.0114) ⇒ 该效应在现世界不可发生
   observed=0/175  registered_in_observed_ci=1  gate_closed=1  gate_verdict_1s=closed  gate_verdict_2s=closed  rc=1
（同形重跑 `--gate 0.06 --effect 0.06`（`6% vs 0%` 框架）⇒ 同样 VOID-PREMISE，rc=1）
（把在册文本原样喂入：`--registered '2/175'`（**无窗**）⇒ NOINFO-NO-WINDOW「不许用它定 N（D-G118）」rc=3）
```
⇒ 两条独立读数：**(a) 历史速率 `1.1429%` 落在新样本 95% CI 之内（`registered_in_observed_ci=1`）；(b) 该比较按仓内自己的闸是 `VOID-PREMISE`**。这与报告 §11④ 自己写的"`NOINFO reason=rate-difference-not-resolvable-at-N=175`"**方向一致**，但 `docs/ROUTES.md:205`／`:388` 与报告 §11① 的措辞（"**同 N 同体制**可比"＋"上界严格低于修前件代"）**与这两条读数冲突**（见 §8-F1/F2/F3）。

---

## §6 口径污染检查（`V7`，逐条对着在册件读原文）

| 在册误判 | 原文要旨 | 本波是否重踩（我的现取） |
|---|---|---|
| `D-G87`（拿**日志体积**当签名） | "日志体积不是可靠签名；可靠的是**退出码 ＋ 栈/首行 ＋ 有无 `Unhandled`**" | **未重踩**：判别式是 `branch≠none ∧ TRIMMED==0 ∧ STACKOVF==0`，不是体积；且 `timeout:` 那一行已在剔除集里（`trail_sp=1`，`W98A-F7` 的假阴性修法在位）。旁证：`HIS03` 腿 `RAW=6.4 MB` 与 `HIS02` `RAW=18.9 KB` 同判 `134-stackovf` ⇒ 体积确实没参与判定 |
| `D-G94`（把"没点"算进点击数 ⇒ 唯一真 `139` 被剔出分母） | 点击分母口径 | **未重踩**：175 腿 `CLICKS_LANDED` 分布 = `7`×13／`8`×162（**无 `0`／无 `SKIP dead` 计入**）；分母 `175/175`，**零剔除**；`oom=0`／`device=ok` 全 175 |
| `D-G106`（`ARM=gdb` ⇒ `app.rc` 不是应用 rc ⇒ **假可疑**剔分母） | 装置缺陷 | **本波主臂未重踩**（`arm=nogdb`、`ext_kill_suspect=no`×175、`app_outcome_observed=yes`×175）—— **但历史基线那 2 条命中正是 `gdb` 臂且两条都带 `ext_kill_suspect=yes`／`app_outcome_observed=no`**，而本波把它**当作对照臂的速率**引用 ⇒ 该形态**经由基线被引进比较**（§8-F2） |
| `D-G107`（线程名含空格 ⇒ 整行不匹配 ⇒ 误判 `NOINFO`） | 解析器缺陷 | **本波不可达**（`arm=nogdb` ⇒ `gdb.txt` 为空，`term`/`stop-signo11` 两支取不到）；我另发现**两实现该支不等价**（见 §8-F7） |

另：**剔除集唯一来源** —— `grep -rln 'silenthit-trim\|TRIM_NEEDLES'` 只有**一处实现**（`build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`）＋清单引用（`build/close-wave.sh:365`）；`legs.tsv` **两列都印**（`APP_TEXT_BYTES`／`APP_TEXT_BYTES_TRIMMED`）✅；`--denom` 有**跨件代合池即违规**的硬断言 ✅。

---

## §7 九位 / 步数 / 覆盖面 / 推送 / 哨兵 / `w21-verify`（`V9`）

- **九位（我自己现取，cfg=Release，权威路径表 `wave-freeze-consistency-check.py:104-115`）**：`bridge 4e25e4b27d4d5ae1`／`pc 38ae477949238306`／`pf 12fb36e7b0df1802`／`windowsbase ed04eb65081c2d3a`／**`provider` 现取 `8cb1b50619f4c133` vs 声明 `759ac1686e5ef87d`（已在册的重建位，`t41` 具名、指派 `t46`）**／**`win32shim e8127a3d7128d417`（＝声明）**／`wic_shim f7b3026c8c019be2`／`hbtextline 921ba9c65e9fb3be`／`dwf 0d25f64a7dbb4c78` ⇒ **8/9 逐位相同**。
- **步数**：`grep -c '^run_step "' verify-all.sh` = **55**，`VERIFYALL-STEPS-DECL: 55 gen=#79`；`verify-all.sh` 对 `HEAD` 的 diff **恰 1 行**：`:1194 --expect 225 → 226` ✅（与 `t44` 声明一致）。
- **覆盖面**：`infp.sh fp` = **`37d4c6ab22f9606e0ad90fe34220e64a545bd3cc6c45da5fe3bbfeb5cdaad83b`**、`files=226` ⇒ 与 `t44` 声明**逐位相同**；`FP_MANIFEST_TEETH=PASS files_n=226 declared_expect=226`、`FP_INPUTS_HYGIENE=PASS coverage_n=226`；`docs/ROUTES.md`／`verify-all.sh`／报告**不在覆盖面**（我逐条 `grep` 覆盖清单 = 0）、新夹具与 trim 清单**在覆盖面**（各 1）。
- **推送 / 哨兵**：`git ls-remote origin refs/heads/feat-Linux` = `71603bd3762059b3e1791be4a5eac2359657e01f` = **本地 `HEAD`**；`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**（`BASELINE=#79`／`BASELINE_SHA16=901619543b3d913b`／`WAVE=w79-freeze`；`PROVIDER=8cb1b50619f4c133`＝重建后的现取）。`porcelain` = `t44` 声明的 5 件（`P0-mvp-segv-report.md`／`P0-w79-anchors-repin.md`／`silenthit-trim.tsv`／`docs/ROUTES.md`／`verify-all.sh`）＋ 新夹具 `??` ＋ 我的报告 ⇒ **本波未推送**（与声明一致）。
- **`~/w21-verify/`（我自己读，不当单方面声明）**：`w79-POST.done` = **0 字节标记**（`mtime 2026-09-28 01:12:39.388`，＝冻结时刻）；`w79-pre.sha` 列出**预冻九位**（`provider a00895e8158189b9`、`dwf 9a8975db981cee8f`……）；`ACCEPTANCE-BASELINE.md` 现取 **`901619543b3d913b`** ＝ `docs/CURRENT-STATE.md:9` 的机器行声明值 ⇒ 三者自洽。
- 基线**未动**（`901619543b3d913b`），本波零产品改动（`git log -S'隔离可疑链'` ⇒ 修法是**波 `#55`**（`ef1dc8f`，`2026-09-23 22:18:04`）落的；本波只落夹具＋剔除集＋常数＋两处账目）。

---

## §8 账目一致性（`V10`）＋ **findings**（判词 = `needs_revision`）

`docs/ROUTES.md` 三处现取：`:205`（`TASK-0201` 行，本波 append）｜`:388`（§「账目清零」下新增一行）｜`:206`（`TASK-0209` 的 dated 更正行）。与报告 §11 的机器读数**数字层面一致**（`0/175`、`1.6973%`、trim `4270ab3da7a1d6d8`、窗 `03:35:57–06:07:37`）—— 但**归属层面**有一句被我的证据推翻，且缺一格现取。

### F1（`blocker`）「**同 N 同体制**可比」**不成立** —— 四处体制差异
- `docs/ROUTES.md:205`／`:388` 与报告 §11① 都写"与修前件代 `2/175 ⇒ 3.5537%` **同 N 同体制**可比"。
- 我的现取（`~/w128a/runs.tsv` 183 行）：**历史主臂 175 腿 = `arm=gdb`／`shim=abf6879c027c5e73`／`TO=75`／`disp=:185`**；本波 175 腿 = **`arm=nogdb`／`shim=e8127a3d7128d417`／`TO=50`／`disp=:186`** ⇒ 只同 `N`。
- 我自己的 4 腿在**历史体制**下 4/4 复现 `134-stackovf`，而同件换 `nogdb/TO=50` 则 0/10 ⇒ **臂/装置差异是行为上活的**，不是纸面差异。
- `requiredFix`：把 `docs/ROUTES.md:205`／`:388` 与报告 §11① 的"同体制"字样**删掉或改写**，逐格列出上述四个差异；`2/175` 一律标注为 **`gdb` 臂口径**，并把本波样本标注为 **`nogdb` 臂口径**（不得再称"同体制"）。

### F2（`blocker`）**修前臂从未在本装置里跑过** ＋ 两代用的是**两套判别式**
- 本波装置只跑了 `app-C`（＝`app-A` 副本 ＋ 现件 shim，差异件数 1，我复验一致）；"修前"那一侧直接引用**历史 `gdb` 臂**台账。
- 历史 2 命中 `W071`/`W077` 的读出方式（`gdb` 的 `term` 支 ＋ `pcsym0=wpf_queue_push` ＋ `app_rc∈{0,1}` ＋ `ext_kill_suspect=yes`）与本波判据（`rc139`／`trimmed` 三合取）**不是同一个判别式**；且我在 `gdb` 臂上实测**剔除集不咬**（`HIS` 腿 `TRIMMED==RAW`），即"`TRIMMED==0`"这一条在 `gdb` 臂**结构上不可达**。
- `requiredFix`：在同一装置（`nogdb`／`TO=50`／无 WM `:23x`）里跑**成对修前臂**（`app-A` 目录 ＋ 修前 shim，`33352e5797031999` 或 `abf6879c027c5e73`，单变量只换 `.so`），把两臂并列上报；在补齐之前，**不得**用历史 `gdb` 臂速率充当本波对照。

### F3（`high`）仓内**自己的**基线率闸现取 = `VOID-PREMISE`，账目里没有这一格
- 我跑（§5③）：`BASELINERATE=FAIL reason=VOID-PREMISE`、`registered_in_observed_ci=1`、`gate_closed=1`（`--gate 0.035537/0.06` 两种框架同判）；把在册文本原样喂入（**无窗**）⇒ `NOINFO-NO-WINDOW rc=3`。
- `requiredFix`：把该闸的现取读数（含 `registered_in_observed_ci=1`）写进 `docs/ROUTES.md:205`／`:388` 与报告 §11④，并**补上历史速率的时间窗**（我现取：`2026-09-23T10:04:58–13:04:05+08:00`）；据此改写"上界严格低于"的表述为"两条上界各自成立，但**该比较按仓内闸为 `VOID-PREMISE`**"。

### F4（`medium`）`134` 族的归因**被我的现取证伪**
- 报告 §11⑤.2 写"`PAD` 扫描在本代**不再产生 `134` 族死亡**"／"相位分布与历史不同"；而**两代用的是同一份** `pads175.txt`（两车道 sha16 同为 `0d3b966b7e1c3ecf`，历史主臂 `pad` 列就是该表 0…2807 的逐行值）。
- 我自己的对照：`app-P`＋`gdb`＋`TO=75` ⇒ `134-stackovf` **4/4**；`app-A`＋**同一个 `gdb`/`TO=75`** ⇒ **0/2**（`faults=1`、无 `Stack overflow`）；`app-A`＋`nogdb`/`TO=50` ⇒ 0/10 ⇒ 判别量落在**臂的 `gdb` 与件代（`abf6879c` vs `33352e`）**上，**与 PAD 相位无关**。
- `requiredFix`：把该句改写为"`134` 族在本波装置（`nogdb`/`TO=50`/`app-A` 目录）不复现；我未做同相位同臂的对照 ⇒ 归因 `NOINFO`"，并把 PAD 同一性写明。

### F5（`low`）两处**指针/读数**更正
- 报告 §11② 点名的台账 `~/w44a/logs/batches.txt` **不存在**（`~/w44a/logs/` 全列：`A?.log`／`*.slot.txt`／`memwatch.log`／`inrepo-final.txt`／`judge44-final.txt`…；同数据在 `~/w44a/STATUS.md` 的 7 行 `完成 A?`）。
- 报告 §8⑤ 的窗口 `268.7 s` 与两 `mtime` 之差不符 —— 我现算 `03:33:59.648774886 − 03:29:31.911072632 = **267.7 s**`。
- `requiredFix`：把台账指针改成 `~/w44a/STATUS.md`（或补落该文件）；窗口改 `267.7 s`。

### F6（`low`）`stop-signo11` 支**两实现不等价**（本波不可达）
- 仓内：`^W[0-9]+[A-Z]*-STOP-[1-9][0-9]* .*signo=11`（要求**第 ≥10 次**停止）；第二实现 `~/w44a/bin/judge44.py`：`W118A-STOP-\d+.*signo=11` 或任意 `signo=11`。
- 本波 `arm=nogdb` ⇒ `gdb.txt` 为空 ⇒ 两支都取不到 ⇒ "两份实现逐腿一致"**在本波成立只是因为该支不可达**（我实测 `HIS` 腿确实落在 `stop-signo11`，说明该支在 `gdb` 臂上是活的）。
- `requiredFix`：写明该边界，或把两支统一到同一正则。

---

## §9 我**推翻／更正**了哪些话

1. **"`app-C`＝`app-A` 副本 ＋ 只换 shim ⇒ 与历史 `2/175` 同 N 同体制可比"** ⇒ 推翻：历史主臂是 `arm=gdb`／`TO=75`／`:185`／`abf6879c`，本波是 `nogdb`／`50`／`:186`／`e8127a3d`（F1）；且两边**判别式不同**（F2）。
2. **"`PAD` 相位在本代不再产生 `134` 族死亡"** ⇒ 推翻：两代同一份 `pads175.txt`；`134` 族在我手里 `app-P+gdb` **4/4** 复现、`app-A+gdb` **0/2**（F4）。
3. **"上界严格低于修前件代 ⇒（可读作）收紧"** ⇒ 更正口径：两条上界各自成立，但仓内自己的闸判 `VOID-PREMISE` 且 `registered_in_observed_ci=1`（F3）。
4. **`~/w44a/logs/batches.txt`** ⇒ 该文件不存在（F5）；**窗口 `268.7 s`** ⇒ 实为 `267.7 s`（F5）。
5. **未推翻的（我逐位复现/实测）**：修法落在 `win32_msg.c:104-128` 那一条链上（反汇编 ＋ 回退重建 ⇒ 崩）；夹具两极化（`139/0x13a` ↔ `rc=0`＋`[QUEUE_CORRUPT]`＋`T10_SURVIVED count=1 head==tail next=(nil)`）；`si_addr=P+0x38`／`si_code=1` 三点校准；175 腿台账**逐腿**可复算且 `0` 命中；具名台账零出现、`RAW=115`×175；上界/门算术四条；`run_step=55`；`--expect 226`；`inputs_fp=37d4c6ab…`／226 件；哨兵 `cmp` IDENTICAL；远端==`71603bd`；基线 `901619543b3d913b` 未动；剔除集唯一来源、两列都印、`--denom` 反合池断言在位。

## §10 边界 / `NOINFO`（如实划界）

- **B1**：我自己的腿批对**静默 SEGV** 零功效（N=10/臂 ⇒ 上界 `25.89%`）⇒ 我不声称"率变低了"，也不声称"率没变"。
- **B2**：我**没有**重跑 `verify-all`（单趟 ~37 min，且会写仓内日志）⇒ 步数/覆盖面/哨兵/推送等格取自**逐件现取**而非一次整链；`t44` 的"窗口 `268.7 s`／唯一红格 `FP_MANIFEST_TEETH=FAIL delta=1`"这一格我只能核 `mtime` 与常数（一致），**当时那一刻的红格不复现** ⇒ 该格 `NOINFO`。
- **B3**：`provider` 九位差（`8cb1b506…` vs 声明 `759ac168…`）是**在册的**重建位（`t41` 具名、`t46` 重取），本件只报事实。
- **B4**：历史 2 命中**是否算真命中**，我不重判（那是 `W130A` 的判词）；我只指出它们的**读出方式与臂**与本波不同。
- **B5**：我跑了一遍 `judge44.py --lane ~/w44a`，该脚本会**重写** `~/w44a/legs.tsv`（内容与 `sha16` 未变：`f94be573393b9971`）—— 如实记为我对外车道的一次写动作。

## §11 落仓与自指

本件 `build/MilBridge/VSegv-verify-report.md`（仓内唯一写入；`temp+rename`、`%h=1`）。
自指口径：`head -n -1 <本件> | sha256sum | cut -c1-16`。
