# P1-tail2-segv-report —— `TASK-0212` 现件代静默 `rc=139` 功效重取（**主档 `N=300`**）

> **车道**：`t204-captain/c2`（实现/测量子代理）。任务：`build/MilBridge/tasks-tail2/T-C2.md`。
> **侦察件**：`build/MilBridge/P1-tail2-segv-recon.md`（`34c10aaa0279e6f4`，`§1` 判别式／`§2` 算式／`§3` 装置／`§4` 基线率闸／`§5` 判据）。
> **判据先写**：`~/t204-captain/c2/criteria.md`（`f0f4c7e7fe03c3f0`，趟数＋功效在**起跑前**落盘）。本件＝交付载体。
> **一句话**：现件代 `win32shim=26da177686acb1f0` 在**无 WM 腿**上跑满 **`N=300`**，`SILENT_SEGV_HIT` 命中 **`k=0`** ⇒ **95% 单侧上界 `0.993608%`**（功效表口径 `1−0.05^(1/N)`；Clopper–Pearson 单侧逐位同）；**同装置只换件的成对修前臂**（`abf6879c027c5e73`）**`1/60` 命中**（`H060`：`rc=139`＋应用输出剔后 `0 B`＋`STACKOVF=0`）⇒ **装置检测力本趟被真命中自证**；基线率闸现取两组皆 `FAIL reason=VOID-PREMISE`（缺窗 `NOINFO`）⇒ **不得宣称静默 SEGV 已清零**。
> **读取时刻**：主臂 `2026-09-30T01:09:49–05:56:34+0800`｜修前臂 `05:57:58–06:30:55+0800`｜核算 `06:31:59+0800`。
> 🔴 **首要披露（见 §2/§10）**：**在在册 trim 集（`4270ab3da7a1d6d8`）下，本现件代 300 腿全判 `NOINFO`**（每腿 18 行未声明 tag `[E3-REPLAY]`）⇒ 分母 `0`。上表 `0/300 ⇒ 0.993608%` 是**在「本席显式扩展的 trim 集」下**取的；**两口径都如实并列**。
> **自报 sha16**：见末行 `SELF-SHA16`（口径 ＝ `head -n -1 … | sha256sum | cut -c1-16`）。

---

## §0 结论摘要（先给结论，证据在下）

| 格 | 读数（现取） |
|---|---|
| **现件代 `.so`（win32shim）** | **`26da177686acb1f0`**（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`，406,608 B；**跑前＝跑后**） |
| 现件代 `pf`（Release） | **`0b4b65f2c6c7ffd4`**（`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`；跑前＝跑后） |
| **主臂**（现件，`N=300`，`:237` 无 WM） | **在册 trim 集 ⇒ 300/300 `NOINFO`（分母 0）**｜**扩展 trim 集 ⇒ `0/300`** |
| **主臂上界**（`k=0`，**扩展口径**） | 功效表口径 `1−0.05^(1/N)` ＝ **`0.993608%`**｜Wilson 单侧 95% ＝ `0.893787%`｜`α=0.025` 双侧 CP ＝ `1.222097%`｜校准：`k=0` 的 CP 单侧**逐位同** `0.993608%` |
| **成对修前臂**（`abf6879c027c5e73`，`N=60`，`:238` 无 WM） | **`1/60`**（`H060`）；`134-stackovf`×59 ＋ `139-segv`×1 |
| **成对臂上界**（`k=1` ⇒ 走 `k>0` 支） | 点估计 `1.666667%`｜**CP 单侧 95% `7.663999%`**｜Wilson 单侧 `7.131488%`｜`α=0.025` 双侧 `8.939905%`｜⚠️ 误用 `k=0` 式会报 `4.870291%`（**低报 2.79 pp**） |
| 两臂可分辨性 | Fisher 单侧 `p=0.166667`；率差 `+1.666667%`，Newcombe 95% CI **`[−0.198922%, +8.855130%]`（含 0）** ⇒ **分不开** |
| 基线率闸 | 带窗（在册 `2/175`）⇒ `FAIL reason=VOID-PREMISE`；带窗（成对 `1/140`）⇒ 同样 `VOID-PREMISE`；**缺窗 ⇒ `NOINFO reason=NOINFO-NO-WINDOW`（rc=3）** |
| 槽 | 正常批 **15**（主臂 `A1..A12` ＋ 修前臂 `B1..B3`）；`HEAVYSLOT=TIMEOUT/NOINFO/MAXHOLD_KILL/WAITMEM` **各 0**；槽内实占合计 **`19,303 s ≈ 5.36 h`**（含误循环期 34 次空批） |
| 装置入口（在册件） | `run-silenthit-legs.sh 64574cfe296dac19`｜`silenthit-trim.tsv 4270ab3da7a1d6d8`｜`silent-hit-v2-check.sh 9eccf056bf2d7417`｜`baseline-rate-gate.sh 1bad58c07a8264e6` |

---

## §1 装置与件位（**现件代指纹，跑前／跑后各一次**）

| 件 | 路径 | 现取 sha16 |
|---|---|---|
| **现件 `.so`** | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **`26da177686acb1f0`**（跑前 `01:05`／跑后 `06:31` **同值**） |
| **现件 `pf`** | `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | **`0b4b65f2c6c7ffd4`**（跑前／跑后同值） |
| 主臂腿文件 `app-N/libwpfwin32.so` | 私有臂目录 | `26da177686acb1f0`（**逐腿 `shim_check` 300/300 同值**） |
| 修前件（在册红臂本体） | `~/w128a/app-P/libwpfwin32.so` | `abf6879c027c5e73`（299,040 B） |
| 成对臂腿文件 `app-P/libwpfwin32.so` | 私有臂目录 | `abf6879c027c5e73`（**逐腿 `shim_check` 60/60 同值**） |
| 装置底座 | `~/w128a/app-A`（94 件，照在册装置） | `HandyControlDemo.dll=1ac5e587cda3fb20` |

- **单变量断言（逐件清单差，机械）**：`app-N` vs 底座 ＝ **1 件**（只有 `libwpfwin32.so`）｜`app-P` vs 底座 ＝ **1 件**｜`app-N` vs `app-P` ＝ **1 件**（`INTERARM_DIFF_N=1`）⇒ **两臂只差那一件**；两臂各 94 件、**零硬链接**（`links_of_shim=1`／`hardlinked_files=0`）。
- **装置**：`Xvfb :237`／`:238`，`-screen 0 1280x1024x24`，**无 WM**（逐腿 `xprop -root _NET_SUPPORTING_WM_CHECK` ⇒ `no such atom on any window.` **300/300 ＋ 60/60**）；配方 ＝ 照在册 `one-leg.sh` 9 击腿（`nogdb`／`TO=50`／`click`）；相位旋钮 `pad` 表 ＝ 在册 `pads175.txt`（0..174 逐字）＋ 线性延长（175..299，**披露**）。
- 🔴 **托管件面（如实记）**：腿上实际跑的 `PresentationFramework.dll`(`PF_CHECK`) 取自**底座** `~/w128a/app-A` ＝ **`f34bc297d19778fd`** ≠ 仓 **Release** `pf` `0b4b65f2c6c7ffd4`。照在册装置口径（**只换 `shim`**）⇒ **本读数只覆盖「现件 `libwpfwin32.so`（shim）」**，不覆盖现树全部产物（同 `t7` §12③ 边界）。
- **世代**：`git HEAD` 跑中由 `14f542115c49…` 前进到 `044c7556d399…`（他件改动）⇒ **本读数与某笔 `HEAD` 无关，只与现件 `.so` 的 sha16 绑定**（`D-G104` 同族）。

---

## §2 主臂读数（现件 `26da177686acb1f0`，`N=300`，`:237` 无 WM）

**① 在册 trim 集（`silenthit-trim.tsv 4270ab3da7a1d6d8`，23 行／7 剔针）**

```
== 第二实现（独立复算）pfx=W ==
LEGS_TOTAL=300  IN_DENOM=0  VOID=300  HITS=0
VOID_WHY={'gate=noinfo': 300}
TRIM_GATE={'noinfo': 300}  SHIM={'26da177686acb1f0': 300}  WM={'…no_such_atom_on_any_window.': 300}
BOUNDS=NOINFO reason=empty-denominator
```
仓内产出端（`--replay`，**唯一实现**）对 `W001` 逐字：
```
LEG tag=W001 arm=replay rc=124 APP_TEXT_BYTES=5911 APP_TEXT_BYTES_TRIMMED=5796 TRIM_GATE=noinfo STACKOVF=0 SEGV_BRANCH=none FAMILY=alive phase=nav undeclared=18 LEG_SHA16=replay HIT=NOINFO
```
⇒ **在册口径下：现件代 300 腿全部 `NOINFO`（分母 `0`）；`undeclared=18/腿`，具名 tag ＝ `[E3-REPLAY]`。**
根因（现取）：`[E3-REPLAY]` 由 **`src/WpfGfx.Linux.Native/src/win32_x11.c:344` 无条件 `fprintf(stderr, …)`** 打出（无开关可关；`WPF_E3_REPLAY_DEDUP`／`_DT_MS` 只调去重与时限，不关发射）⇒ **每腿 18 行**；在册 trim 集**未声明**该 tag ⇒ 完备性闸判 `undeclared>0` ⇒ **不进分母（`D-G94`）**。

**② 扩展 trim 集（本席私有 `~/t204-captain/c2/silenthit-trim-c2.tsv` ＝ `f1f07d6ce14f2a74`；在册集 **＋1 行**声明 `[E3-REPLAY]` `trimmed=yes`，按 shim 具名台账，与 `[G147_WORKAREA]` 同族）**

```
== 第二实现（独立复算）pfx=W ==
LEGS_TOTAL=300  IN_DENOM=300  VOID=0  HITS=0
FAMILY={'alive': 300}
BRANCH={'none': 300}
RC={124: 300}
LANDED={8: 300}
TRIM_GATE={'ok': 300}  SHIM={'26da177686acb1f0': 300}  WM={'…no_such_atom_on_any_window.': 300}
PAIRS(raw,trimmed)={(5911, 0): 298, (6231, 0): 2}
```
仓内产出端（`--replay`，`SILENTHIT_TRIM=扩展集`）对 `W001` 逐字：
```
TRIM_GATE=ok rows=24 trimmed_needles=8 file=…/silenthit-trim-c2.tsv sha16=f1f07d6ce14f2a74
LEG tag=W001 arm=replay rc=124 APP_TEXT_BYTES=5911 APP_TEXT_BYTES_TRIMMED=0 TRIM_GATE=ok STACKOVF=0 SEGV_BRANCH=none FAMILY=alive phase=nav undeclared=0 HIT=no
```
仓内牙 `--legs-from legs-W-den.tsv`（301 行含表头）⇒ `SILENTHIT_LEGS rows=300 hits=0`／`SILENTHIT=PASS` rc=0。
**逐腿官方复核（`--replay` ×300，零进程／零槽）**：`W REPLAY legs=300 rows=300 HIT=yes0 GATE_noinfo=0`（`replay/W/rows.txt` `82a5d0f4e67ae7ac`）⇒ **仓内唯一产出端亲判现件 300 腿零命中**。
⇒ **扩展口径下：现件代 `0/300`；`FAMILY=alive ×300`、`rc=124 ×300`、`SEGV_BRANCH=none ×300`、`landed=8 ×300`、`TRIM_GATE=ok ×300`、`shim` 单代 `26da177686acb1f0` ×300。**

| 格 | 值（现取） |
|---|---|
| 腿数（按 `tag` 去重后） | **300**（`W001..W300`，无缺） |
| 入分母／作废／跳过 | **300／0／0**（在册口径：**0／300／0**） |
| `FAMILY`／`RC`／`SEGV_BRANCH` | `alive=300`／`124=300`／`none=300`（现场可达两支 `rc139`／`fate` **零命中**；`term`／`stop-signo11` 现场不可达） |
| `(APP_TEXT_BYTES, TRIMMED)` | `(5911, 0)×298 ＋ (6231, 0)×2`（`W193`／`W211` 多 320 B，剔后仍 `0`） |
| `wm_check`／`shim_check`／`OOM` | `no such atom…`×300／`26da177686acb1f0`×300／`0`×300 |
| **`SILENT_SEGV_HIT`** | **扩大口径 `0/300`**｜在册口径 `NOINFO`（分母 0） |
| 时间窗（`D-G118` 带窗） | `0/300 @ 2026-09-30T01:09:49..05:56:34+0800, display=:237（无 WM）` |

---

## §3 上界（**含算式与代入值**；`k=0` 支）

| 口径 | 公式 / 代入 | `0/300` |
|---|---|---|
| **功效表（在册）** | `ub(0/N) = 1 − 0.05^(1/N)` ＝ `1 − 0.05^(1/300)` | **`0.993608%`** |
| 校准 | Clopper–Pearson 单侧 95%（`k=0`）＝ `1 − 0.05^(1/N)` | `0.993608%`（**逐位同**） |
| 闸口径 Wilson 单侧 95% | Wilson score，`z=1.6448536` | `0.893787%` |
| `α=0.025` 双侧（并列，`D-G104`） | Clopper–Pearson | `1.222097%` |
| 点估计 | `k/N` | `0.000000%` |

**在册锚对照（本席自算，`N` 取整批）：** `N=131 ⇒ 2.260869%`（在册 `≥131 腿`＝2.26% ✓）｜`N=299 ⇒ 0.996915%`（在册 `≥299 腿`＝1.00% ✓）｜`N=175 ⇒ 1.697278%`（在册 `t44`/`t7` 同值 ✓）。**本趟取到 `N=300 ⇒ 0.993608%`，跨过在册 `0.996915%` 的 1% 门。**
**断言**：① `k=0` 与 `k>0` 走**不同公式**（`judge.py` 的 `if k==0 … else …`；本趟两臂各走一支）；② 每处上界同印**公式名 ＋ `k` ＋ `N`**；③ **没有**把 `k=0` 式用在含命中的样本上（详见 §4 与 §7 反极 C）。

---

## §4 成对修前臂（`abf6879c027c5e73`，`N=60`，`:238` 无 WM）—— **检测力自证**

- **构造**：`app-P` ＝ 底座 `~/w128a/app-A` 的逐字节副本 **＋ 只换** `libwpfwin32.so`（`abf6879c027c5e73`）⇒ 与 `app-N` 只差 1 件。**注册行为＝命中即停** ⇒ 实际 `N=60`（非上限 300）。
- **分母**（`D-G94`）：有效 `60`／作废 `0`／跳过 `0`；`FAMILY = 134-stackovf×59 ＋ 139-segv×1`；`RC = 134×59 ＋ 139×1`；`landed = 8×59 ＋ 7×1`；**在册口径与扩展口径逐格相同**（`TRIM_GATE=ok 60/60`，`undeclared=0`）。
- **命中腿 `H060`（逐字）**：
  ```
  H060  B3  nogdb  click  :238  50  952  abf6879c027c5e73  139  other  0   …  0  none none none none  ok  crash-segv  0  9  7  7  28  yes  139  11  no  …  2026-09-30 06:30:55
  ```
  `app.log` ＝ **43 B、逐字一行** `timeout: 被监视的命令已核心转储`（`app.err`＝`0 B`，`app.rc`＝`139`）⇒ 行首锚定剔掉 `timeout:` 后**应用输出＝`0 B`** ⇒ **`SILENT_SEGV_HIT = yes`（`SEGV_BRANCH=rc139`）**。
  **仓内产出端亲判（`--replay`，两口径皆同）**：`LEG tag=H060 rc=139 APP_TEXT_BYTES=43 APP_TEXT_BYTES_TRIMMED=0 TRIM_GATE=ok STACKOVF=0 SEGV_BRANCH=rc139 FAMILY=139-segv undeclared=0 HIT=yes` ＋ `SILENT_SEGV_HIT=yes …`。证据已冻结：`~/t204-captain/c2/frozen/H060/`（整目录）＋ `frozen/HIT-139.txt` ＋ `frozen/LAST-HIT`；链停：`=== 相 2 停：修前臂命中（H060）06:30:55 ===`。
- 仓内牙 `--legs-from legs-H-den.tsv`（61 行含表头）⇒ `SILENTHIT_LEGS rows=60 hits=1`（`H001..H059 NOT-HIT`；`H060 HIT`）／`SILENTHIT=PASS` rc=0。
- **逐腿官方复核（`--replay` ×60，零进程）**：`H REPLAY legs=60 rows=60 HIT=yes1`（`replay/H/rows.txt` `4d94f8e5e5df75e6`），唯命中行 `H060 … HIT=yes` ⇒ **仓内唯一产出端亲判**。
- **成对臂上界**（`k=1` ⇒ **只许** `k>0` 支）：点估计 `1.666667%`｜**CP 单侧 95% `7.663999%`**｜Wilson 单侧 `7.131488%`｜`α=0.025` 双侧 `8.939905%`｜⚠️ **误用 `k=0` 式（`1−0.05^(1/60)`＝`4.870291%`）低报 2.79 pp** ⇒ 正是 `D-G121` 那一族，**本趟以实测样本复现**。
- **检测力自证（本件用法）**：同一装置、同一批脚本、同一相位表、**只换一件** ⇒ 修前件打出**真命中**、现件 `0/300` ⇒ **本趟的"零命中"不是"装置坏了"**。

| 臂 | `shim` | `N`（入分母） | 命中 | `FAMILY` | 功效表口径 `ub95` | Wilson 单侧 95% |
|---|---|---|---|---|---|---|
| **现件**（主臂） | `26da177686acb1f0` | **300** | **0** | `alive=300` | **`0.993608%`** | `0.893787%` |
| **修前**（成对臂） | `abf6879c027c5e73` | **60** | **1** | `134-stackovf=59 ＋ 139-segv=1` | `4.870291%`（`k=0` 式，**仅对照**）；**正确 CP 单侧 `7.663999%`** | `7.131488%` |

- **可分辨性**（在册实现 `~/w48a/bin/pairstats48.py`）：NEW `300/0` vs OLD `60/1` ⇒ 率差 `+1.666667%`，**Newcombe 95% CI `[−0.198922%, +8.855130%]`（含 0）**；**Fisher 单侧 `p=0.166667`** ⇒ **两臂分不开**（不得据此宣称"率变低"）。

---

## §5 基线率闸 `BASELINERATE`（现取判词原文 ＋ `reason=`）

```
① 在册同装置 gdb 臂基线（带窗）vs 本趟现件臂
   --registered '2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185' --observed 0/300 --gate 0.035537 --effect 0.011429
   ⇒ BASELINERATE=FAIL  BASELINERATE_RC=1
     BASELINERATE_REASON=VOID-PREMISE ① ci_upper(0.0089) < gate(0.0355);以② observed(0.0000) < effect(0.0114) ⇒ 该效应在现世界不可发生
     registered=2/175  window=2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185  observed=0/300
     ci_upper=0.0089  ci_upper_2s=0.0126  cp_upper=0.0099  fisher_p=0.1352
     registered_in_observed_ci=1  gate_closed=1  effect_impossible=1  caliber_disagreement=0
② 成对修前臂基线（带窗）vs 本趟现件臂
   --registered '1/140@2026-09-28T18:39:39..2026-09-28T20:11:55+display=:238' --observed 0/300 --gate 0.033435 --effect 0.007143
   ⇒ BASELINERATE=FAIL  VOID-PREMISE（ci_upper(0.0089) < gate(0.0334)；observed(0.0000) < effect(0.0071)）  fisher_p=0.3182  rc=1
③ 缺时间窗（降级形态）
   --registered '2/175' --observed 0/300 --gate 0.035537 --effect 0.011429
   ⇒ BASELINERATE=NOINFO  reason=NOINFO-NO-WINDOW …（rc=3，**不是绿，也不许当 0**）
```
**两条硬结论**：① 闸在**带窗**与**缺窗**两形态下结论不同（`FAIL/VOID-PREMISE` vs `NOINFO`）⇒ 缺窗只许 `NOINFO`；② 即便换成**同装置成对基线**，闸仍判 `VOID-PREMISE`（`registered_in_observed_ci=1`：在册速率**落在**观测 CI 内）⇒ **不得据此宣称改善/率变低**。

---

## §6 验收项 → 证据映射（可复跑命令原文 ＋ 原始输出）

| # | 验收项（`T-C2 §③`） | 证据（见 §1–§5） | 状态 |
|---|---|---|---|
| ① | 单代 `N` 趟、逐趟现取代际指纹；跨代 ⇒ 该趟 `VOID` | §1（`auth_so16=26da177686acb1f0`／`auth_pf16=0b4b65f2c6c7ffd4`）＋逐腿 `shim_check` `26da177686acb1f0` **300/300**（修前臂 `abf6879c027c5e73` **60/60**）⇒ **单代、零跨代** | ✓ |
| ② | `0/N` 或命中数 ＋ 95% 单侧上界（含算式与代入值） | §2＋§3：**`0/300`** ⇒ `1−0.05^(1/300)` ＝ **`0.993608%`** | ✓ |
| ③ | 成对修前臂命中（检测力自证）或 `NOINFO` | §4：**`1/60` 命中（`H060`）** ⇒ 检测力被真命中自证 | ✓ |
| ④ | 基线率闸现取判词原文 ＋ `reason=` | §5：两组 `FAIL reason=VOID-PREMISE`；缺窗 `NOINFO reason=NOINFO-NO-WINDOW` | ✓ |
| ⑤ | 边界：只对「本装置＋本波配置」成立；不宣称已清零 | §10：**不宣称静默 SEGV 已清零** | ✓ |

**复跑命令（逐条可重放；`L=~/t204-captain/c2`，`N=仓根`）**
```bash
# 件位
sha256sum $N/src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16            # 26da177686acb1f0
sha256sum $N/build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll | cut -c1-16  # 0b4b65f2c6c7ffd4
# 两实现逐腿对拍 / 分母内腿表
python3 $L/bin/judge.py $L/runs.tsv $L/run $N/build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv W --out $L/legs-W-i.tsv     # 在册口径：IN_DENOM=0
python3 $L/bin/judge.py $L/runs.tsv $L/run $L/silenthit-trim-c2.tsv             W --out $L/legs-W.tsv --out2 $L/legs-W-den.tsv    # 扩展口径：0/300
python3 $L/bin/judge.py $L/runs.tsv $L/run $L/silenthit-trim-c2.tsv             H --out $L/legs-H.tsv --out2 $L/legs-H-den.tsv    # 1/60
# 仓内唯一实现（--replay 逐腿亲判，零进程）
DISPLAY=:237 WPF_PROBE_TAG=W001 WPF_PROBE_RUNDIR=$L/replay/W001e SILENTHIT_TRIM=$L/silenthit-trim-c2.tsv \
  bash $N/build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh --replay $L/run/W001
DISPLAY=:238 WPF_PROBE_TAG=H060 WPF_PROBE_RUNDIR=$L/replay/H060e \
  bash $N/build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh --replay $L/run/H060
# 仓内牙：判据端 --legs-from ＋ 跨件代 --denom
bash $N/build/MilBridge/tools/silent-hit-v2-check.sh --legs-from $L/legs-W-den.tsv    # rows=300 hits=0
bash $N/build/MilBridge/tools/silent-hit-v2-check.sh --legs-from $L/legs-H-den.tsv    # rows=60  hits=1（H060）
bash $N/build/MilBridge/tools/silent-hit-v2-check.sh --denom $L/logs/den-table.txt    # PASS 真件代=3 合池行=0
# 上界复算 ＋ 基线率闸三形态
python3 -c 'print(1-0.05**(1/300))'                                                   # 0.009936…
bash $N/build/MilBridge/tools/baseline-rate-gate.sh --registered '2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185' --observed 0/300 --gate 0.035537 --effect 0.011429
bash $N/build/MilBridge/tools/baseline-rate-gate.sh --registered '2/175' --observed 0/300 --gate 0.035537 --effect 0.011429   # NOINFO rc=3
# 逐腿官方复核（--replay ×300/×60，零进程）
bash $L/bin/replay-all.sh
# 收工核算（一键）
bash $L/bin/collect.sh
```

---

## §7 反极性（**必写，防假绿**；逐条现取）

- **反极 A（假绿探测）**：把现件代换成修前件 ⇒ 判据**变红**（`H060`：`HIT=yes`／`SEGV_BRANCH=rc139`／`TRIM=0`）✓（§4）。
- **反极 B（装置造假／"一剔了之"）**：把剔除集**加宽**（在册集 → 扩展集：新增 `[E3-REPLAY]` 剔针）⇒ 现件腿从 `TRIM_GATE=noinfo`（`undeclared=18`）**翻转**到 `TRIM_GATE=ok`（`undeclared=0`）✓；且负极腿 `H060` 的 `HIT=yes` 在两口径下**都不被剔掉**（真命中不被"一剔了之"抹掉）✓。
- **反极 C（上界口径）**：对 `k>0` 样本（`1/126`）套 `k=0` 公式 ⇒ 闸**真红点名**：
  `BASELINERATE=FAIL`／`reason=zero-hit-formula-on-nonzero-sample`／`decl_upper=0.0235（该式值）` vs `正确 cp-1s=0.0371` ⇒ **低报 0.0136** ✓。正确口径（`cp-1s`）同样本 ⇒ `DECL_UPPER=EVALUATED checked=ok` ✓。
- **反极 D（代际）**：腿上 `shim_check` 列**逐腿现取**；本趟两臂各**单代**（`26da177686acb1f0`×300／`abf6879c027c5e73`×60），与现取 `.so` **逐位相同**；跨代行会被 `--denom` 的"合池即违规"挡下（本趟 `SILENTHIT_DENOM=PASS 真件代=3 合池行=0`）✓。

---

## §8 槽读数（逐批，现取自动账）

- **正常批 15**：主臂 `A1..A12`（各 `1310 s`，`A12` `1260 s`）＋ 修前臂 `B1..B3`（`847/846/366 s`）；**每批 1 趟装置对照腿**（`A*C`／`B*C`，**不入任何分母**）：`CTRL_OK=1 CTRL_BAD=0` 逐批。
- **异常计数**：`HEAVYSLOT=TIMEOUT` **0**／`NOINFO low-memory` **0**／`MAXHOLD_KILL` **0**／`WAITMEM` **0**；逐腿 `OOM=0`；停手线（`avail<2000MB ∨ swapfree<512MB`）**一次未触**（`CHAIN_ABORTED=none`／`CHAIN_STOP=none`）⇒ **没有任何一条腿被槽杀／被内存闸拒**。
- **槽内实占合计**（有 `RELEASED rc=0` 的行）＝ **`19,303 s ≈ 5.36 h`**；其中含**误循环期**（见 §10 自伤 1）34 次空批（≈`1,734 s`）⇒ 净跑腿约 `17,569 s`。
- 全程 `--min-avail 2500 --max-hold 1800 --wait 3600`，批间一律释放；`HEAVYSLOT=NESTED_SKIP` 为**预期**（批内每腿复用祖先槽）。

---

## §9 自包含结论（≤8 行）

1. **现件代 `26da177686acb1f0` 在无 WM 腿上跑满 `N=300`，`SILENT_SEGV_HIT` 零命中**（扩展口径 `0/300`）⇒ 95% 单侧上界 **`0.993608%`**（功效表口径；Wilson 单侧 `0.893787%`；`α=0.025` 双侧 `1.222097%`），**跨过在册 1% 门（`0/299 ⇒ 0.996915%`）**。
2. 🔴 **但在在册 trim 集下，本现件代 300 腿全判 `NOINFO`**：`win32_x11.c:344` 无条件发射的 **`[E3-REPLAY]`（18 行/腿）未在 `silenthit-trim.tsv` 声明** ⇒ 完备性闸 `undeclared>0` ⇒ 分母 `0`。**这是现件代引入的新插桩 tag 未随 trim 集登记**（真事实，见 §10）。
3. **检测力本趟被真命中自证**：同装置、只换一件，修前件 `abf6879c027c5e73` 打出 **`1/60`** 真静默 SEGV（`H060`：`rc=139`＋应用输出剔后 `0 B`）⇒ 现件的"零命中"**不是装置坏了**。
4. 但**两臂统计上分不开**（Fisher `p=0.167`、差值 CI 含 0），且**基线率闸判 `VOID-PREMISE`** ⇒ **不许说"率显著变低"**；缺窗只许 `NOINFO`。
5. 上界**两口径都印**，`k=0` 与 `k>0` 走**不同公式**（`k=1` 时若误用 `k=0` 式会低报 2.79 pp）——**没有混用**。
6. **本读数只对「本装置（`Xvfb 1280x1024`，无 WM）＋ 本波配置」成立**，且**只覆盖现件 `shim`**；**不宣称**静默 SEGV 已清零。

---

## §10 主动披露 / `NOINFO` / 边界（逐条）

1. 🔴 **本轮我造成一处自伤（如实）**：批链 `plan` 末批 `S=275`＋`BS=25` ⇒ `S+BS=300` 越过 `pad` 表（0..298）⇒ `resume=299` 卡住，**误循环 34 次空批**（每次仅跑 1 趟对照腿 `A12r299C`，≈`1,734 s` 槽时）。**修法**：把 `pad` 表补到 `i=299` 并重启（可重入，从 `resume=299` 续跑，产出 `W300`）。**代价＝槽时**；**未污染腿读数**（对照腿 `*C` 不入分母；`runs.tsv` 中 34 条 `A12r299C` 噪声行由 `judge.py` 按 `tag` 末位 `C` 排除）。
2. 🔴 **`pad` 表 >175 的相位为线性延长**：在册 `pads175.txt` 只有 175 行；`i=175..299` 由同一线性趋势外推（`pad(174)=2807`，`pad(299)=4824`），**非在册原值**（披露，且前 175 行逐字取自在册）。
3. 🔴 **`[E3-REPLAY]` 未声明＝真事实（不是我读错）**：`win32_x11.c:344` 无条件 `fprintf`；在册 trim 集（`4270ab3da7a1d6d8`）**没有**该行 ⇒ 仓内产出端亲判 `undeclared=18`。**建议**（不在本件写域）：把 `[E3-REPLAY]` 补入在册 `silenthit-trim.tsv`（按 shim 具名台账，`trimmed=yes`，与 `[G147_WORKAREA]` 同族）。**本席未改在册件**，改用私有扩展集（`SILENTHIT_TRIM`）出数并**两口径并列**。
4. **在册口径的 `NOINFO` 不是绿**：300 腿分母 `0` ⇒ `BOUNDS=NOINFO reason=empty-denominator`；**不许**把"无分母"读成 `0/0`。
5. **托管件面未随现树刷新**：腿上 `PresentationFramework.dll`(`f34bc297d19778fd`) 取自底座 ≠ 仓 Release(`0b4b65f2c6c7ffd4`)；本读数**只覆盖现件 `shim`**（照在册装置口径）。
6. **有 WM 腿不跑**：用户现场 `xrdp＋xfwm4` 有 WM ⇒ 该腿**无检测力**，记 `NOINFO reason=no-detection-power`（沿用、无新证据）。
7. **`term`／`stop-signo11` 两支现场不可达**（`nogdb` 无 `gdb.txt`）⇒ 该格 `NOINFO`（`--replay` 可判，但那不是腿）。
8. **残余窄 `TOCTOU`（`TASK-0211`）**：`0/300` **不等于**该窗口绝迹（只给它的率一个上界）。
9. **两臂 `N` 不等**（主臂 `300`／成对臂 `60`，命中即停）⇒ 双臂率**不同 `N` 可比性弱**；不作强统计宣告（Fisher `p=0.167` 本就不显著）。
10. **`HEAD` 跑中前进**（`14f542…→044c755…`）⇒ 读数只绑现件 `.so` sha16。
11. **本趟未做**：`verify-all`／`close-wave`／任何 `dotnet` 构建／改在册件（越域）；`runs.tsv` 未改写、未删行（追加）。
12. **`pairstats48.py` 一处标签陈旧**（现取）：其 `ARITH` 行把 `ub95(0/175)` 标签印成 `0.993608%`（＝`ub95(0/300)`）——**该在册辅助脚本的行标签未随 `n` 更新**；本件**不引用**该行，只用其 Fisher/CI。

### `NOINFO`（具名，逐条）
- **`NOINFO reason=undeclared-instrumentation`**：现件代 300 腿（**在册 trim 集**），`undeclared=18/腿`（tag `[E3-REPLAY]`）。
- **`NOINFO reason=no-detection-power`**：有 WM 腿（不跑）。
- **`NOINFO reason=NOINFO-NO-WINDOW`**：基线率闸缺时间窗形态。
- **`NOINFO reason=empty-denominator`**：在册口径下 `BOUNDS`（分母 `0`）。
- **`NOINFO`**：`term`／`stop-signo11` 两支现场不可达。

---

## §11 交付冻结块（机器现算；结账用这一块）

```
现件代 .so          : 26da177686acb1f0（跑前=跑后）｜ pf(Release): 0b4b65f2c6c7ffd4（跑前=跑后）
主臂（app-N,:237无WM）: N=300  时间窗 2026-09-30T01:09:49..05:56:34+0800
   在册 trim 集      : 300/300 NOINFO（undeclared=18/腿, tag=[E3-REPLAY], gate=noinfo）⇒ 分母 0
   扩展 trim 集      : 0/300（alive=300 / rc=124 / branch=none / landed=8 / gate=ok）
   上界(k=0)         : 功效表 1-0.05^(1/300)=0.993608% ｜Wilson1s 0.893787% ｜CP-2s(0.025) 1.222097%
成对修前臂（app-P,:238无WM）: shim=abf6879c027c5e73  N=60（命中即停）  时间窗 2026-09-30T05:57:58..06:30:55+0800
   命中              : 1/60（H060: rc=139 RAW=43 TRIMMED=0 STACKOVF=0 branch=rc139 landed=7 dead=28s）
   上界(k=1)         : CP1s 7.663999% ｜Wilson1s 7.131488% ｜CP-2s 8.939905% ｜[错]k0式 4.870291%(低报2.79pp)
两臂可分性           : Fisher 单侧 p=0.166667 ｜Newcombe 95% CI [-0.198922%, +8.855130%]（含 0）
基线率闸             : ①带窗(在册2/175) FAIL/VOID-PREMISE ②带窗(成对1/140) FAIL/VOID-PREMISE ③缺窗 NOINFO rc=3
分母表(--denom)      : PASS rows=3 真件代=3 合池行=0
槽                   : 正常批15 + 误循环34空批；异常(TIMEOUT/NOINFO/MAXHOLD_KILL/WAITMEM)=0；槽内实占合计 19303s(≈5.36h)
台账 sha16           : runs.tsv 8da40f5afbf955b6（409 行）
                       legs-W.tsv 6cb61e9565649fcb ｜legs-W-den.tsv 6cb61e9565649fcb ｜legs-W-i.tsv 8404e8c91cee5720（在册口径）
                       legs-H.tsv 5f3e09132a4c21e7 ｜legs-H-den.tsv 5f3e09132a4c21e7
逐腿官方复核          : replay/W/rows.txt 82a5d0f4e67ae7ac（300 腿 HIT=0）｜replay/H/rows.txt 4d94f8e5e5df75e6（60 腿 HIT=1，H060）
件 sha16             : silenthit-trim-c2.tsv(私有扩展) f1f07d6ce14f2a74 ｜ criteria.md f0f4c7e7fe03c3f0 ｜ pads.tsv 8cd998a33f7eb912
在册件                : run-silenthit-legs.sh 64574cfe296dac19 ｜ silenthit-trim.tsv 4270ab3da7a1d6d8
                       silent-hit-v2-check.sh 9eccf056bf2d7417 ｜ baseline-rate-gate.sh 1bad58c07a8264e6
冻结证据              : ~/t204-captain/c2/frozen/H060/（整目录）＋ frozen/HIT-139.txt ＋ frozen/LAST-HIT
读取时刻              : 2026-09-30T06:31:59.605614629+0800（date '+%F %T.%N %z'）
```

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-segv-report.md | sha256sum | cut -c1-16`）= `d5728ff1a41e5ce0`
