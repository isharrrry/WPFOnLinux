# P1-segvrate2-recon —— `TASK-0201`／`TASK-0212` **率重取**（现件 `5f9ed647c68197ae` ＋ 可比时间窗，`SILENT_SEGV_HIT` 逐字口径）

> **车道**：`tB21`（测量子代理）。任务：`build/MilBridge/tasks-tail2/T-B21.md`。
> **一句话**：现件 `win32shim=5f9ed647c68197ae` 在**无 WM 腿**上跑满 **`N=175`**，`SILENT_SEGV_HIT` 命中 **`k=0`** ⇒ **95% 单侧上界 `1.697278%`**（功效表口径 `1−0.05^(1/N)`；Clopper–Pearson 单侧 `k=0` 逐位同）；**同装置只换件的成对修前臂**（`abf6879c027c5e73`）`175` 腿**全为 `134-stackovf` 崩溃、静默 SEGV 命中 `0`** ⇒ **检测力自证 `NOINFO`（本趟未捕获真命中）**；基线率闸现取**三组带窗皆 `FAIL reason=VOID-PREMISE`**（缺窗 `NOINFO reason=NOINFO-NO-WINDOW`）⇒ **只推进读数，不宣称「静默 SEGV 已清零」**（残余窄 `TOCTOU`＝`TASK-0211` 另计）。
> **读取时刻**：主臂 `2026-10-03T12:45:55–15:18:50+0800`｜修前臂 `15:18:52–16:58:42+0800`｜核算 `17:05:xx+0800`。
> **自报 sha16**：见末行 `SELF-SHA16`（口径 ＝ `head -n -1 … | sha256sum | cut -c1-16`）。
> ⚠️ **本件内一切行号仅对本次写入时刻有效**；引用一律以**内容锚**为准（纪律 31）。

---

## §0 结论摘要（先给结论，证据在下）

| 格 | 读数（现取） |
|---|---|
| **现件 `.so`（win32shim）** | **`5f9ed647c68197ae`**（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`，`567456 B`；**跑前＝跑后**） |
| 现件 `pf`（Release） | **`1e9c3dbfea2f6634`**（`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`；跑前＝跑后） |
| **主臂**（现件，`N=175`，`:237` 无 WM） | **`0/175`**（`SILENT_SEGV_HIT`）；`alive=175`／`rc=124`／`branch=none`／`landed=8×175`／`TRIM_GATE=ok×175` |
| **主臂上界**（`k=0`） | 功效表口径 `1−0.05^(1/N)` ＝ **`1.697278%`**｜Wilson 单侧 95% ＝ `1.522487%`｜`α=0.025` 双侧 CP ＝ `2.085870%`｜校准：`k=0` 的 CP 单侧**逐位同** `1.697278%` |
| **成对修前臂**（`abf6879c027c5e73`，`N=175`，`:238` 无 WM） | **静默 SEGV 命中 `0/175`**；**`134-stackovf=175`**（全崩溃，非静默 SEGV） |
| **检测力自证** | **`NOINFO`**：修前臂**未捕获真 `SILENT_SEGV_HIT`** ⇒ 本趟不能据此自证"静默 SEGV 检测力"；但**装置可分件**（现件 `0/175` 崩溃 vs 修前件 `175/175` 崩溃） |
| 基线率闸 | 带窗（在册 `2/175`）⇒ `FAIL reason=VOID-PREMISE`；带窗（成对 `1/140`）⇒ 同；带窗（成对 `1/77`）⇒ 同；**缺窗 ⇒ `NOINFO reason=NOINFO-NO-WINDOW`（rc=3）** |
| 反例对照（证闸非恒判） | `22/27 ⇒ PASS/0/PASS`（`required_n=43`）｜`12/12 ⇒ PASS/0/PASS`（`required_n=21`）｜`7/28 ⇒ FAIL/1/DRIFT` |
| 槽 | 正常批 **14**（主臂 `A1..A7` ＋ 修前臂 `B1..B7`）；`HEAVYSLOT=TIMEOUT/NOINFO/MAXHOLD_KILL/WAITMEM` **各 0**；`CHAIN_ABORTED=none`／`CHAIN_STOP=none` |
| 装置入口（在册件） | `run-silenthit-legs.sh 64574cfe296dac19`｜`silenthit-trim.tsv 8f93be10a5ca57f5`｜`silent-hit-v2-check.sh 9eccf056bf2d7417`｜`baseline-rate-gate.sh 1bad58c07a8264e6` |

---

## §1 ① 判据逐字（件:行）＋ 腿数/N/时间窗 ＋ `TASK-0212` 判据③现取形态

### 1.1 `SILENT_SEGV_HIT` 逐字判别式（**三条形态并列，均现取**）

- **散文形态（口径句，逐字；出处 `docs/ROUTES.md` 现取 `:232` 行内）**：
  > `SILENT_SEGV_HIT ⇔ APP_TEXT_BYTES_TRIMMED==0 ∧ STACKOVF==0 ∧ SEGV_BRANCH!=none`
- **产出端自述（逐字；`build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh` 现取 `:7`）**：
  > `它判 SILENT_SEGV_HIT ⇔ APP_TEXT_BYTES_TRIMMED == 0 ∧ STACKOVF == 0 ∧ 死于 SIGSEGV`
- **实现本体（唯一；`build/MilBridge/tools/silent-hit-v2-check.sh` 现取 `judge()`）**：
  - 前置闸（现取 `:89`–`:92`）：`und != 0 ⇒ NOINFO(undeclared-instrumentation)`；`ph == "teardown" ⇒ NOINFO(teardown-death-not-a-hit)`。
  - 三支合取（现取 `:95`）：`c1 = (trimmed == 0); c2 = (so == 0); c3 = (br in BRANCHES)`。
  - 四支白名单（现取 `:48`）：`BRANCHES = ("rc139", "fate", "term", "stop-signo11")`。
  - 现场 `nogdb` 形态可达的两支＝`rc139`／`fate`；`term`／`stop-signo11` **现场不可达**（`run-silenthit-legs.sh` 射程句 `:41`）⇒ 那两格 `NOINFO`。

### 1.2 腿数 / `N` / 时间窗（**现取**）

| 臂 | 件代 | `N`（入分母） | 命中 | 时间窗（`D-G118` 带窗，首腿 … 末腿 `ts_end`） |
|---|---|---|---|---|
| 主臂 | `5f9ed647c68197ae` | **175** | **0** | `2026-10-03T12:47:36..2026-10-03T15:18:50+0800, display=:237（无 WM）` |
| 成对修前臂 | `abf6879c027c5e73` | **175** | **0**（静默 SEGV） | `2026-10-03T15:20:14..2026-10-03T16:58:42+0800, display=:238（无 WM）` |

- **`N` 的定法（先写、跑前的功效口径）**：主档 `≤2.26%` ⇒ `≥131 腿`（在册锚 `P0-mvp-segv-report.md §4②`）。本趟取 **`N=175`**（`≥131` ⇒ 达标；且与在册车道 `t44`／`t7` 的**同 `N`** 可比 ⇒ 只宣称"同 `N` ＋ 同装置形"，不宣称跨代可比）。
- **功效表（本席自算，可复算）**：`N=131 ⇒ 2.260869%`｜`N=149 ⇒ 1.990482%`｜**`N=175 ⇒ 1.697278%`**｜`N=299 ⇒ 0.996915%`（皆 `k=0` 支）。

### 1.3 `TASK-0212` 判据③（**基线率闸非 `VOID-PREMISE`**，须带时间窗）**现取形态**

- 判据③原文（出处＝侦察件 `build/MilBridge/P1-tail2-segv-recon.md` §5.1 判据 5 ／ `T-C2` `criteria.md` §3 判据 5）：
  > **正极**：现件代 `k=0` ⇒ 95% 单侧上界 `= 1−0.05^(1/N) ≤` 目标门；**证伪**：出现 ≥1 命中即翻（走 `k>0` 支）。
  > **判据③（基线率闸）**：必须喂**带窗** `R/N@窗+display`；两组现取都 `VOID-PREMISE` ⇒ 若**不带可比时间窗**，**不许**在报告里写"改善／率变低"。
- **判据③现取形态（本趟，见 §5）**：**三组带窗现取（在册 `2/175`／成对 `1/140`／成对 `1/77`）皆 `BASELINERATE=FAIL reason=VOID-PREMISE`**；**缺窗**形态 ⇒ `NOINFO reason=NOINFO-NO-WINDOW rc=3`；**本趟现取窗自身**（`0/175@本趟窗`）⇒ `NOINFO reason=caliber-disagreement rc=3`。

---

## §2 装置与件位（**现件代指纹，跑前／跑后各一次**）

| 件 | 路径 | 现取 sha16 |
|---|---|---|
| **现件 `.so`** | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **`5f9ed647c68197ae`**（跑前 `12:45`／跑后 `17:05` **同值**；`567456 B`） |
| **现件 `pf`** | `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | **`1e9c3dbfea2f6634`**（跑前／跑后同值） |
| 主臂腿文件 `app-N/libwpfwin32.so` | `~/tb21-work/app-N` | `5f9ed647c68197ae`（**逐腿 `shim_check` 175/175 同值**） |
| 修前件（在册红臂本体） | `~/w128a/app-P/libwpfwin32.so` | `abf6879c027c5e73`（`299040 B`） |
| 成对臂腿文件 `app-P/libwpfwin32.so` | `~/tb21-work/app-P` | `abf6879c027c5e73`（**逐腿 `shim_check` 175/175 同值**） |
| 装置底座 | `~/w128a/app-A`（94 件） | `HandyControlDemo.dll=1ac5e587cda3fb20` |

- **单变量断言（逐件清单差，机械）**：`app-N` vs 底座 ＝ **1 件**（只有 `libwpfwin32.so`，`diff_n=2` 行＝size＋sha 一行两版）｜`app-P` vs 底座 ＝ **1 件**｜`INTERARM_DIFF_N=2`（同行两版）⇒ **两臂只差那一件**；两臂各 **94 件**、**零硬链接**（`links_of_shim=1`／`hardlinked_files=0`）。
- **装置**：`Xvfb :237`／`:238`，`-screen 0 1280x1024x24`，**无 WM**（逐腿 `xprop -root _NET_SUPPORTING_WM_CHECK` ⇒ `no such atom on any window.` **175/175 ＋ 175/175**）；配方 ＝ 照在册 `one-leg.sh` 9 击腿（`nogdb`／`TO=50`／`click`）；相位旋钮 `pad` 表 ＝ 在册 `pads175.txt` 前 175 点（`pads.tsv` 现取 `8cd998a33f7eb912`，与 `T-C2` **逐位同**）。
- 🔴 **托管件面（如实记）**：腿上实际跑的 `PresentationFramework.dll`(`PF_CHECK`) 取自**底座** `~/w128a/app-A` ＝ **`f34bc297d19778fd`** ≠ 仓 Release `pf` `1e9c3dbfea2f6634`。照在册装置口径（**只换 `shim`**）⇒ **本读数只覆盖「现件 `libwpfwin32.so`（shim）」**，不覆盖现树全部产物（同 `t7` §12③ 边界）。
- **世代**：`git HEAD` ＝ `06df07605e84accf1a24e485318dbf41addf2260`（分支 `feat-Linux`）⇒ **本读数与 `HEAD` 无关，只与现件 `.so` 的 sha16 绑定**（`D-G104` 同族）。

---

## §3 主臂读数（现件 `5f9ed647c68197ae`，`N=175`，`:237` 无 WM）

**第二实现（独立复算，`~/tb21-work/bin/judge.py`）**

```
== 第二实现（独立复算）pfx=W ==
LEGS_TOTAL=175  IN_DENOM=175  VOID=0  HITS=0
VOID_WHY={}
FAMILY={'alive': 175}
BRANCH={'none': 175}
RC={124: 175}
LANDED={8: 175}
TRIM_GATE={'ok': 175}  SHIM={'5f9ed647c68197ae': 175}  WM={'_NET_SUPPORTING_WM_CHECK:_no_such_atom_on_any_window.': 175}
PAIRS(raw,trimmed)={(5929, 0): 173, (6249, 0): 2}
POINT k=0 n=175 point=0.000000%
```

**仓内唯一产出端（`--replay` 逐腿亲判；对 `W001` 逐字）**：

```
TRIM_GATE=ok rows=24 trimmed_needles=8 file=…/silenthit-trim.tsv sha16=8f93be10a5ca57f5
LEG tag=W001 arm=replay rc=124 APP_TEXT_BYTES=5929 APP_TEXT_BYTES_TRIMMED=0 TRIM_GATE=ok STACKOVF=0 SEGV_BRANCH=none FAMILY=alive phase=nav undeclared=0 LEG_SHA16=replay HIT=no
```
**仓内牙（`--legs-from`，唯一实现）**：`SILENTHIT_LEGS rows=175 hits=0`／`SILENTHIT=PASS` rc=0。
⇒ **两实现逐腿一致（第二实现 `HITS=0` ↔ 仓内牙 `hits=0`）**。

| 格 | 值（现取） |
|---|---|
| 腿数（按 `tag` 去重后） | **175**（`W001..W175`，无缺、无重复） |
| 入分母／作废／跳过 | **175／0／0** |
| `FAMILY`／`RC`／`SEGV_BRANCH` | `alive=175`／`124=175`／`none=175`（现场可达两支 `rc139`／`fate` **零命中**；`term`／`stop-signo11` 现场不可达） |
| `(APP_TEXT_BYTES, TRIMMED)` | `(5929, 0)×173 ＋ (6249, 0)×2`（`W…` 两腿多 320 B，剔后仍 `0`） |
| `wm_check`／`shim_check`／`OOM` | `no such atom…`×175／`5f9ed647c68197ae`×175／`0`×175 |
| **`SILENT_SEGV_HIT`** | **`0/175`** |
| 时间窗（`D-G118` 带窗） | `0/175 @ 2026-10-03T12:47:36..2026-10-03T15:18:50+0800, display=:237（无 WM）` |

---

## §4 上界（**含算式与代入值**；`k=0` 支）

| 口径 | 公式 / 代入 | `0/175` |
|---|---|---|
| **功效表（在册）** | `ub(0/N) = 1 − 0.05^(1/N)` ＝ `1 − 0.05^(1/175)` | **`1.697278%`** |
| 校准 | Clopper–Pearson 单侧 95%（`k=0`）＝ `1 − 0.05^(1/N)` | `1.697278%`（**逐位同**） |
| 闸口径 Wilson 单侧 95% | Wilson score，`z=1.6448536` | `1.522487%` |
| `α=0.025` 双侧（并列，`D-G104`） | Clopper–Pearson | `2.085870%` |
| 点估计 | `k/N` | `0.000000%` |

**在册锚对照（本席自算）**：`N=131 ⇒ 2.260869%`（在册 `≥131 腿`＝2.26% ✓）｜`N=149 ⇒ 1.990482%`｜**`N=175 ⇒ 1.697278%`**（在册 `t44`／`t7` 同值 ✓）｜`N=299 ⇒ 0.996915%`（在册 `≥299 腿`＝1.00% ✓）。
**断言**：① `k=0` 与 `k>0` 走**不同公式**（本趟两臂**皆 `k=0`**，故都走 `k=0` 支）；② 每处上界同印**公式名 ＋ `k` ＋ `N`**；③ **没有**把 `k=0` 式用在含命中的样本上（本趟两臂命中皆 `0`）。
**⚠️ 未达 1% 门（如实）**：本趟取到 `N=175 ⇒ 1.697278%`，**未**跨过在册 `0.996915%`（1%）门（该门需 `N=299`，本趟未跑）。

---

## §5 成对修前臂（`abf6879c027c5e73`，`N=175`，`:238` 无 WM）—— **检测力自证：`NOINFO`**

- **构造**：`app-P` ＝ 底座 `~/w128a/app-A` 的逐字节副本 **＋ 只换** `libwpfwin32.so`（`abf6879c027c5e73`）⇒ 与 `app-N` **只差 1 件**。
- **分母**（`D-G94`）：有效 `175`／作废 `0`／跳过 `0`；`FAMILY = 134-stackovf×175`；`RC = 134×175`；`landed = 8×174 ＋ 7×1`；`TRIM_GATE=ok 175/175`、`undeclared=0`。
- **`SILENT_SEGV_HIT` 命中**：**`0/175`**（**全部为 `134-stackovf` 栈溢出崩溃，`SEGV_BRANCH=none`，非静默 SEGV**）。
  ```
  == 第二实现（独立复算）pfx=H ==
  LEGS_TOTAL=175  IN_DENOM=175  VOID=0  HITS=0
  FAMILY={'134-stackovf': 175}
  BRANCH={'none': 175}   RC={134: 175}   LANDED={8: 174, 7: 1}
  TRIM_GATE={'ok': 175}  SHIM={'abf6879c027c5e73': 175}
  ```
  仓内牙：`SILENTHIT_LEGS rows=175 hits=0`（`H001..H175` 皆 `NOT-HIT`）。
- 🔴 **检测力自证 `NOINFO`（如实划界）**：在设计里，修前臂**必须出 ≥1 真静默 SEGV 命中**，否则"现件零命中"读成绿＝**装置无检测力**。本趟修前臂**未捕获任何真命中**（全为栈溢出），故**该自证不成立 ⇒ `NOINFO`（具名 `reason=no-detected-hit-in-pair-arm`）**。
- **但**：同装置、只换一件，**现件 `0/175` 崩溃 vs 修前件 `175/175` 崩溃** ⇒ 装置**能区分两件**（这是"崩溃率"层面的分件证据，**不是**"静默 SEGV 检测力"的证据；两者**不许混读**）。
- **与在册 `T-C2` 的差异（如实记）**：`T-C2`（`N=60`，命中即停）修前臂曾出 **`1/60`** 静默 SEGV（`H060`：`rc=139`＋剔后 `0 B`）；本趟 `N=175` **零静默 SEGV**、全为 `134-stackovf`。**同装置件位（`pads.tsv 8cd998a33f7eb912`、`PF=f34bc297d19778fd`、修前 `shim` 皆同）**，唯一显著差异＝**在册 trim 集已换代**（`T-C2` 时 `4270ab3da7a1d6d8` → 现取 `8f93be10a5ca57f5`）。⇒ **本趟不主张"该命中已消失"**，只报"本趟未观测到"（命中具概率性，且属 `TOCTOU` 族）。

---

## §6 基线率闸 `BASELINERATE`（现取判词原文 ＋ `reason=`）

```
① 在册同装置 gdb 臂基线（带窗）vs 本趟现件臂
   --registered '2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185' --observed 0/175 --gate 0.035537 --effect 0.011429
   ⇒ BASELINERATE=FAIL  BASELINERATE_RC=1
     BASELINERATE_REASON=VOID-PREMISE ① ci_upper(0.0152) < gate(0.0355);以② observed(0.0000) < effect(0.0114) ⇒ 该效应在现世界不可发生
     registered=2/175  window=2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185  observed=0/175
     ci_upper=0.0152  ci_upper_2s=0.0215  cp_upper=0.0170  fisher_p=0.4986
     registered_in_observed_ci=1  gate_closed=1  effect_impossible=1  caliber_disagreement=0
② 成对修前臂基线（带窗）vs 本趟现件臂
   --registered '1/140@2026-09-28T18:39:39..2026-09-28T20:11:55+display=:238' --observed 0/175 --gate 0.033435 --effect 0.007143
   ⇒ BASELINERATE=FAIL  VOID-PREMISE（ci_upper(0.0152) < gate(0.0334)；observed(0.0000) < effect(0.0071)）  fisher_p=0.4444  rc=1
③ 成对修前臂基线 1/77（带窗）vs 本趟现件臂
   --registered '1/77@2026-09-28T06:39:59..2026-09-28T07:28:48+display=:186' --observed 0/175 --gate 0.060131 --effect 0.012987
   ⇒ BASELINERATE=FAIL  VOID-PREMISE（ci_upper(0.0152) < gate(0.0601)；observed(0.0000) < effect(0.0130)）  rc=1
④ 缺时间窗（降级形态）
   --registered '2/175' --observed 0/175 --gate 0.035537 --effect 0.011429
   ⇒ BASELINERATE=NOINFO  BASELINERATE_REASON=NOINFO-NO-WINDOW 在册速率缺**时间窗**（形态须为 R/N@时间窗）⇒ 不许用它定 N（D-G118）  BASELINERATE_RC=3
⑤ 本趟现取窗自我对照（现件臂自身窗 vs observed 0/175）
   --registered '0/175@2026-10-03T12:47:36..2026-10-03T15:18:50+display=:237' --observed 0/175 --gate 0.016973 --effect 0.000000
   ⇒ BASELINERATE=NOINFO  BASELINERATE_REASON=NOINFO-CALIBER-DISAGREEMENT 口径之争先于结论：单侧 ci_upper=0.0152（closed）与双侧 ci_upper_2s=0.0215（open）对闸 gate=0.0170 结论不同 ⇒ reason=caliber-disagreement  rc=3
```
**三条硬结论**：① 闸在**带窗**与**缺窗**两形态下结论不同（`FAIL/VOID-PREMISE` vs `NOINFO`）⇒ 缺窗只许 `NOINFO`；② 即便换成**同装置成对基线**（`1/140`／`1/77`），闸仍判 `VOID-PREMISE`（`registered_in_observed_ci=1`：在册速率**落在**观测 CI 内）⇒ **不得据此宣称改善／率变低**；③ **口径之争先于结论**（`⑤` 现场）：当 `--gate` 落在单侧与双侧界之间时闸**响亮 `NOINFO`**，不许挑对我方有利的一界下 `PASS`/`FAIL`。

---

## §7 ④ 反例对照（**证闸非恒判 `VOID-PREMISE`**；现取）

**① `--cases` 走仓内在册台账（`build/MilBridge/tools/baseline-rate-registered.tsv`，现取 `b4f646b28369813e`）**

```
CASE basereg-task0201-gdbarm-windowed  got=FAIL/1/VOID-PREMISE      want=FAIL/1/VOID-PREMISE      OK
CASE basereg-task0201-gdbarm-nowindow  got=NOINFO/3/NOINFO-NO-WINDOW want=NOINFO/3/NOINFO-NO-WINDOW OK
CASE basereg-task0201-pairarm-140      got=FAIL/1/VOID-PREMISE      want=FAIL/1/VOID-PREMISE      OK
CASE basereg-task0201-pairarm-77       got=FAIL/1/VOID-PREMISE      want=FAIL/1/VOID-PREMISE      OK
CASE basereg-ctr-22of27                got=PASS/0/PASS              want=PASS/0/PASS              OK   ← 反例对照①
CASE basereg-ctr-12of12                got=PASS/0/PASS              want=PASS/0/PASS              OK   ← 反例对照②
CASE basereg-ctr-7of28-drift           got=FAIL/1/DRIFT             want=FAIL/1/DRIFT             OK
BASELINERATE_CASES=7 passed=7 failed=0
BASELINERATE=PASS   BASELINERATE_RC=0
```
⇒ **反例对照 ≥2 条（`22/27 ⇒ PASS`、`12/12 ⇒ PASS`）证明闸不是恒判 `VOID-PREMISE`**；并给可继续的 `required_n`。

**② `--selftest`（两极化，确定性合成夹具）**：`BASELINERATE_SELFTEST=PASS`；`SELFTEST_ANTI_POLARITY bad_ledger_rc=1`（把期望改错 ⇒ 必红）；`SELFTEST_COUNTEREXAMPLE name=e-counterexample-22-of-27 required_n=43`／`name=f-counterexample-12-of-12 required_n=21`；`SELFTEST_DG121_CASES_rc=0`。

---

## §8 ⑤ 具名 `NOINFO`（逐条）

- **`NOINFO reason=no-detected-hit-in-pair-arm`**：成对修前臂 `N=175` **未捕获真 `SILENT_SEGV_HIT`**（全为 `134-stackovf`）⇒ **检测力自证不成立**（§5）。
- **`NOINFO reason=NOINFO-NO-WINDOW`**：基线率闸**缺时间窗**形态（`rc=3`，不是绿、也不许当 `0`）。
- **`NOINFO reason=caliber-disagreement`**：本趟现取窗自对照，单侧/双侧对闸结论不同（口径之争先于结论）。
- **`NOINFO reason=no-detection-power`**：**有 WM 腿不跑** —— 用户现场 `xrdp＋xfwm4` 有 WM ⇒ 该腿**无检测力**（沿用、无新证据）。
- **`NOINFO`**：`term`／`stop-signo11` 两支**现场不可达**（`nogdb` 无 `gdb.txt`；`--replay` 可判，但那不是腿）。

---

## §9 复述位现值位（**逐件现取，供后人核对**）

| 处（内容锚） | 现值 |
|---|---|
| `docs/CURRENT-STATE.md:9` | `> BASELINE-FROZEN gen=#81 sha16=7cd1bc5c37a74e8d file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| `docs/ROUTES.md`（`TASK-0212` 行块，现取 `:246` 起） | `TASK-0212 [Next] 🟡 静默 rc=139 现件代功效重取`（sha16 `22da364c7ced56b7`／1169 行） |
| 现件 `.so`（`win32shim`） | `5f9ed647c68197ae`（`567456 B`） |
| 现件 `pf`（Release） | `1e9c3dbfea2f6634` |
| 哨兵 `/tmp/bridge-frozen.flag` | `WIN32SHIM=5f9ed647c68197ae`／`PF=1e9c3dbfea2f6634`／`WAVE=w81-freeze`／`BASELINE=#81`（**与现件一致**） |
| `build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh` | `64574cfe296dac19` |
| `build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv` | `8f93be10a5ca57f5`（**已含 `[E3-REPLAY]` 剔针**；`T-C2` 时 `4270ab3da7a1d6d8`） |
| `build/MilBridge/tools/silent-hit-v2-check.sh` | `9eccf056bf2d7417` |
| `build/MilBridge/tools/baseline-rate-gate.sh` | `1bad58c07a8264e6` |
| `build/MilBridge/tools/baseline-rate-registered.tsv` | `b4f646b28369813e` |
| `build/MilBridge/tools/baseline-rate-cases.tsv` | `1a2df056f5677344` |
| `~/tb21-work/pads.tsv`（相位表） | `8cd998a33f7eb912`（与 `T-C2` 逐位同） |
| 本趟台账 `~/tb21-work/runs.tsv` | `aea62692e7bd2d55`（364 腿 ＋ 表头） |
| 本趟腿表 `legs-W-den.tsv`／`legs-H-den.tsv` | `5abf209d3dc75544`／`8890af4b6d9df9b5` |
| 本趟私臂 `app-N`／`app-P` `shim` | `5f9ed647c68197ae`／`abf6879c027c5e73` |
| 底座 `~/w128a/app-A` | 94 件；`HandyControlDemo.dll=1ac5e587cda3fb20` |

- 🔴 **在册速率台账未随动（如实）**：`baseline-rate-registered.tsv` **本趟未改**（现取 `b4f646b28369813e`）。理由：本趟现取窗（`0/175@2026-10-03…:237`）与在册各行**分属不同件代／不同窗**，混入会破坏该件"在册历史速率"的纯度；本趟现取窗**已在 §3 逐字给出**，闸用**现成接口**逐行现取时可取用。

---

## §10 自包含结论（≤8 行）

1. **现件 `5f9ed647c68197ae` 在无 WM 腿上跑满 `N=175`，`SILENT_SEGV_HIT` `0/175`** ⇒ 95% 单侧上界 **`1.697278%`**（功效表口径；Wilson 单侧 `1.522487%`；`α=0.025` 双侧 `2.085870%`）；**未**跨过在册 1% 门（需 `N=299`）。
2. **成对修前臂 `abf6879c027c5e73`（同装置、只换一件，`N=175`）静默 SEGV 命中 `0`**（全 `134-stackovf`）⇒ **检测力自证 `NOINFO`**；但现件 `0/175` 崩溃 vs 修前件 `175/175` 崩溃 ⇒ 装置**可分件**（非同级证据）。
3. **基线率闸三组带窗皆 `FAIL reason=VOID-PREMISE`**（`registered_in_observed_ci=1`：在册速率落在观测 CI 内）；缺窗 `NOINFO-NO-WINDOW`；现取窗自对照 `NOINFO/caliber-disagreement`；**反例对照 `22/27`／`12/12` 皆 `PASS`** ⇒ 闸**非恒判**。
4. **前提失效（`VOID-PREMISE`）** ⇒ **不得据此宣称"率显著变低／静默 SEGV 已清零"**（残余窄 `TOCTOU`＝`TASK-0211` 另计）。
5. **上界两口径都印**（`k=0` 与 `k>0` 走不同公式）；本趟两臂**皆 `k=0`**，**未混用**。
6. **本读数只对「本装置（`Xvfb 1280x1024`，无 WM）＋ 本波配置」成立**，且**只覆盖现件 `shim`**（托管件面未随现树刷新）。

---

## §11 边界（逐条声明）

1. **只对本装置形成立**：`Xvfb 1280x1024x24`、**无 WM**、`nogdb`、`TO=50`、`app face` 钉在 `1ac5e587cda3fb20` ⇒ **不外推**到用户现场（`xrdp` ＋ `xfwm4`）。
2. **唯一自变量 ＝ `libwpfwin32.so`**；托管件面未随现树刷新 ⇒ 本读数**只**是"现件 shim"的读数。
3. `0/175` **≠** 残余窄 `TOCTOU`（`TASK-0211`）已绝迹（只给它的率一个上界）。
4. **不做强统计宣告**：两臂 `SILENT_SEGV_HIT` 皆 `0` ⇒ **无率差可算**（本趟不引用任何"率差 CI"当作改善证据）。
5. **`pad` 表**：本趟 `i=0..174` 逐字取自在册 `pads175.txt`（`N=175 ≤ 175`，**未外推**）。
6. **本趟未做**：`verify-all`／`close-wave`／任何 `dotnet` 构建／改在册件（除本载体外 `$R` 零写入）；`runs.tsv` 未改写、未删行。

---

## §12 复跑命令（逐条可重放；`L=~/tb21-work`，`R=仓根`）

```bash
L=~/tb21-work; R=/home/links-dev/netTest/GitProj/WPFOnLinux
# 件位
sha256sum $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16            # 5f9ed647c68197ae
sha256sum $R/build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll | cut -c1-16  # 1e9c3dbfea2f6634
sha256sum $L/app-N/libwpfwin32.so $L/app-P/libwpfwin32.so | cut -c1-16          # 5f9ed647c68197ae / abf6879c027c5e73
# 两实现逐腿对拍（第二实现）
python3 $L/bin/judge.py $L/runs.tsv $L/run $R/build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv W --out $L/legs-W.tsv --out2 $L/legs-W-den.tsv   # 0/175
python3 $L/bin/judge.py $L/runs.tsv $L/run $R/build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv H --out $L/legs-H.tsv --out2 $L/legs-H-den.tsv   # 0/175（全 134-stackovf）
# 仓内唯一产出端（--replay，零进程）
DISPLAY=:237 WPF_PROBE_TAG=W001 WPF_PROBE_RUNDIR=$L/replay/W001 bash $R/build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh --replay $L/run/W001
# 仓内牙（判据端）
bash $R/build/MilBridge/tools/silent-hit-v2-check.sh --legs-from $L/legs-W-den.tsv   # rows=175 hits=0
bash $R/build/MilBridge/tools/silent-hit-v2-check.sh --legs-from $L/legs-H-den.tsv   # rows=175 hits=0
# 上界复算
python3 -c 'print((1-0.05**(1/175))*100)'                                            # 1.697278…
# 基线率闸（三组带窗 ＋ 缺窗 ＋ 自窗）
bash $R/build/MilBridge/tools/baseline-rate-gate.sh --registered '2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185' --observed 0/175 --gate 0.035537 --effect 0.011429
bash $R/build/MilBridge/tools/baseline-rate-gate.sh --registered '1/140@2026-09-28T18:39:39..2026-09-28T20:11:55+display=:238' --observed 0/175 --gate 0.033435 --effect 0.007143
bash $R/build/MilBridge/tools/baseline-rate-gate.sh --registered '2/175' --observed 0/175 --gate 0.035537 --effect 0.011429   # NOINFO rc=3
# 反例对照 ＋ 两极化自检
bash $R/build/MilBridge/tools/baseline-rate-gate.sh --cases $R/build/MilBridge/tools/baseline-rate-registered.tsv   # 7/7 PASS
bash $R/build/MilBridge/tools/baseline-rate-gate.sh --selftest
```

---

## §13 主动披露

1. 🔴 **本趟检测力自证失败（如实，非掩饰）**：`T-C2` 修前臂曾在 `N=60` 出 `1/60` 静默 SEGV；本趟 `N=175` **零静默 SEGV**（全 `134-stackovf`）。**差异唯一显著处＝在册 trim 集换代**（`4270ab3da7a1d6d8 → 8f93be10a5ca57f5`），其余装置件位（`pads`／`PF`／`shim`）逐位同。⇒ 记 `NOINFO`，**不**把"未观测到"读成"已消失"。
2. **`0/175` 的上界未跨 1% 门**：本趟主档取在册 `≥131 腿`口径（`N=175 ⇒ 1.697278%`），**未**跑 `N=299`（1% 门）。
3. **托管件面未随现树刷新**：腿上 `PresentationFramework.dll`(`f34bc297d19778fd`) 取自底座 ≠ 仓 Release(`1e9c3dbfea2f6634`)；本读数**只覆盖现件 `shim`**。
4. **在册速率台账未随动**：见 §9 末条（理由已具名）。
5. **进程/显示纪律**：显示位只用 `:237`／`:238`（无 WM 逐腿自证）；进程只按 PID（本趟未用 `pkill`／`pgrep -f`）；重活一律走槽（`--min-avail 2500 --max-hold 1800 --wait 3600`）；本趟**未**触停手线（`CHAIN_ABORTED=none`／`CHAIN_STOP=none`）。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-segvrate2-recon.md | sha256sum | cut -c1-16`）= `f465b26f807f5cb4`
