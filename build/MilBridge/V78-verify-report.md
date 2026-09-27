# `V78-verify-report.md` —— 波 `#78` 的独立复验（车道 `verifier` / `t9`）

- 对象：`N=/home/links-dev/netTest/GitProj/WPFOnLinux`，`HEAD=993eb5d522495d50d3d15b1f2bb1826111352832`（== 远端 `refs/heads/feat-Linux`）
- 判据：**先写**于 `~/w28x/criteria.md`｜方法：**每条承重读数我自己现算**；两极化一律换**我私有的**件/显示/应用副本（`$N` 只读，除本报告 1 件）
- 区间：2026-09-27 11:41 → 12:0x｜资源现取：`df -Pk /` 第 4 列 = `100995096 KB`；`MemAvailable` = `5692 MB`；`Swap free` = `1164 MB`

---

## 0. 结论一句话

**产品那条核心声称我独立复现了**：`SHAppBarMessage` 不装 ⇒ 启动期异常**重现且恰好 +242 B**（我的私有反事实件 ＋ 原始件两条独立构造都给出同一 242 B），装回 ⇒ 异常消失；`D-G147` 的工作区语义与显示号租借我都自己跑了两极化。
**但两句话被现场推翻／打折扣**：① `#78` 冻结块**九位行的 `provider` 是上一代值**（与同块 6 条 `BASELINE tier=`、双哨兵、现读**全都矛盾**）——`D-G149` 的**第三次复发**；② 导出数「550 → 551」不成立（现读 **554**，多出的 3 条是 `D-G147` 的工作区出处导出）；另有三条登记/口径层的缺口（§8）。
**判：`failed`**（findings 见 §8；主链与产品修法本身是好的）。

---

## 1. 九位 / 步数 / 覆盖面 / `--expect`（现取逐位）

```
cd $N && for f in <九条权威路径>; do sha256sum "$f" | cut -c1-16; done
```

| 位 | 现取（11:41） | `#78` **九位行**（:66） | `#78` **tier 机读行**（:74） | `#77` 值 | 判定 |
|---|---|---|---|---|---|
| `bridge` | `4e25e4b27d4d5ae1` | 同 | 同 | 同 | 未动 ✓ |
| `pc` | `f9d6cd3e9647a20e` | 同 | 同 | `53fd7fffcdb30243` | 位移（环成员）✓ |
| `pf` | `8190809cc16426e2` | 同 | 同 | `4fcd2ca021c39064` | 位移（**必须动**）✓ |
| `windowsbase` | `ff04a83e07e0def9` | 同 | 同 | `07c89f1872c1a3c1` | 位移 ✓ |
| **`provider`** | **`a00895e8158189b9`** | **`609192a419d125f2`** | **`a00895e8158189b9`** | `1f9511a7ef395bfe`→t17 修复后 `609192a419d125f2` | 🔴 **九位行陈旧** |
| `win32shim` | `e8127a3d7128d417` | 同 | 同 | `fc60c34d51fd9247` | 位移（**产品改动**，**必须动**）✓ |
| `wic_shim` | `f7b3026c8c019be2` | 同 | 同 | 同 | 未动 ✓ |
| `hbtextline` | `921ba9c65e9fb3be` | 同 | 同 | 同 | 未动 ✓ |
| `dwf` | `9a8975db981cee8f` | 同 | 同 | `b07f801556e1a511` | 位移 ✓ |

- 位移 **6 位**（`pc/pf/windowsbase/provider/win32shim/dwf`）＝ 冻结器 `GENS['#78']['allow_changed']`（现取：`{'pf','windowsbase','provider','pc','win32shim','dwf'}`）**逐位相同** ⇒ **无表外位移** ✓；`win32shim` 与 `pf` 都动 ✓。
- 🔴 `provider` 的**两个授权来源互相矛盾**（九位行 vs 6 条 tier 行）——**且双哨兵站在 tier 行一边**：`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag` 都写 `PROVIDER=a00895e8158189b9`（`cmp IDENTICAL`、`%h=1`）。
- 步数四处一致：`grep -c '^run_step "'` = **51**；首行 `# VERIFYALL-STEPS-DECL: 51 gen=#78`；`VERIFYALL-STEP-NAMES` = **51** 名；冻后日志真跑步名 51。控制腿：`grep -c '^run_step'`（少引号）= 52。
- 覆盖面：`infp.sh fp` = `a3bded5d3c3e384cc8621e3da5401ccc99e8d16f2e4be11577463034c77ceb94`（11:41 现取，**与冻结块逐字相同**）；`list|wc -l` = **217**；`[42]` 行 = `--expect 217`（`verify-all.sh:1175`）；冻结块声明「覆盖面 212 → 217」一致 ✓。
- 五臂日志 `# ARM-LOG-SHA`：`tline 59a203de30d745a8` 等 5 条与现算逐位相同；`COLUMN-CORPUS 0cebc0afd5142fbf` ✓；`BRIDGE_SRC_FP d697b1e10ff48881` ✓。

---

## 2. `TASK-0747` 两极化（**我自己跑**，不是复述）

仪器：私有一份应用树 `~/w28x/pair/A`（从 `~/w181a/w7x/app/A` `cp -a`，113 MB）；私有显示 `:233`（我自己起、**按 PID 收**）；**唯一自变量 = `libwpfwin32.so` 一件**。

| 腿 | 件（我现取 sha16） | 构造方式 | stderr 字节 | `EntryPointNotFoundException` 行数 | `[APPBAR_DIAG]` |
|---|---|---|---|---|---|
| A 落仓件 | `e8127a3d7128d417` | `$N` 权威件原样 | **115** | 0 | 0 |
| **B 我的反事实** | `d0c49783ebf76b44` | **我自己**对 A 做**等长单字节改名**（`SHAppBarMessage`→`SHAppBarMessagX`，2 处；`nm -D` 现取该名 0 次） | **357** | **1** | 0 |
| C 原始件 | `fc60c34d51fd9247` | 归档未装符号件（`~/w181a/w7x/native/base/…`，= `#77` 九位值） | **242** | **1** | 0 |
| D 落仓件＋diag | 同 A | `WPF_LINUX_APPBAR_DIAG=1` | 3744 | 0 | 1 |
| E 我的反事实＋diag | 同 B | 同上 | 3923 | 1 | 0 |
| F 原始件＋diag | 同 C | 同上 | 3808 | 1 | 0 |

- **判据①（核心）**：`B − A = 357 − 115 = `**`+242`** ✓ **恰 242**；`E − D = +179 = 242 − 63` ⇒ **63 B 正是那行 `[APPBAR_DIAG]`**（与台账 `3808→3629, 差 179 = 242−63` 的算术**同构**）✓。
- **判据②（"其余 diag 逐字节相同"）**：`cmp A B` ⇒ **在第 115 字节后 EOF**，即 **A 的 115 B 是 B 的前缀**，其后**整段**就是那 242 B 的异常行 ⇒ 除该段外**逐字节相同** ✓。
- **判据③（不是被别的东西吞掉）**：那 242 B 的**内容**现取为
  `[HC-UNHANDLED] #1 EntryPointNotFoundException: Unable to find an entry point named 'SHAppBarMessage' in shared library 'shell32.dll'. ｜ 首帧 at HandyControl.Tools.Interop.InteropMethods.SHAppBarMessage(Int32 dwMessage, APPBARDATA& pData)`
  ⇒ 异常**被打印**（`DispatcherUnhandledException` 的处理器**确实会打印**），装符号臂里**同一处理器一行都不打** ⇒ "异常消失"不是"异常照旧发生但没人打印" ✓。
- **判据④（其余消息返 0 ＋ `E_NOTIMPL`）——我用真实调用证伪**：自写探针 `~/w28x/probe.c`（`dlopen` ＋ `dlsym`），现取读数：
  ```
  CALL msg=ABM_GETTASKBARPOS(4) ret=0 last_error=120 rc=0,0,1280,1024 …
  CALL msg=ABM_QUERYPOS  (2) ret=0 last_error=120 rc_untouched=1
  CALL msg=ABM_SETSTATE  (10) ret=0 last_error=120 rc_untouched=1
  CALL msg=ABM_NEW       (0)  ret=0 last_error=120 rc_untouched=1
  VERDICT=NON_ABM_ZERO_PLUS_E_NOTIMPL
  ```
  （`120` = `ERROR_CALL_NOT_IMPLEMENTED`；探针同时证明**符号真的可解析、真的被调到**，不只是注释。）对照片：我的反事实件与原始件都 `SYMBOL_ABSENT`。
- **`ABM_GETTASKBARPOS` 取值来源**：`src/WpfGfx.Linux.Native/src/win32_oem.c` 的 `SHAppBarMessage()` 里 `wpf_x11_workarea(&x,&y,&w,&h)` 现取调用点 ✓（`wpf_x11_workarea` 在 `win32_x11.c:1616`）。

---

## 3. `D-G147` 两极化（**我自己起显示、自己设 EWMH 属性**）

仪器：私有 `Xvfb :239`（我起、我按 PID 收）＋自写 `~/w28x/holdprop.c`（设属性并**保持连接**——见 §7 的仪器注）＋上节的探针。**五档现取**：

| 档 | 根属性 | `ABM_GETTASKBARPOS` 的 `rc` | `wpf_x11_workarea_src()` | `prop_present/prop_n` |
|---|---|---|---|---|
| ① 裸 Xvfb（无 WM、无属性） | — | `0,0,1280,1024` | `fallback-screen` | `0 / 0` |
| ② `_NET_WORKAREA=0,0,1280,968` | 在场 | **`0,0,1280,968`** | **`net-workarea`** | `1 / 4` |
| ③ 畸形 `n=2`（只有两格） | 在场但畸形 | `0,0,1280,1024` | **`fallback-malformed`** | `1 / 2` |
| ④ 多桌面 `n=8`（当前桌面 0） | 在场 | `0,0,1280,900`（第 0 格） | `net-workarea` | `1 / 8` |
| ⑤ ④＋`_NET_CURRENT_DESKTOP=1` | 在场 | **`10,20,1210,900`（第 1 格）** | `net-workarea` | `1 / 8` |

⇒ **"工作区 ≠ 整屏"是真做到的**（档②），**"多桌面选格"是真做到的**（档⑤），**"畸形"有自己的响亮来源名**（档③ `fallback-malformed`，不静默等于"量到整屏"）✓。
**"工作区近似"的诚实注释在位**：`win32_oem.c` 里逐字写着「⚠️ 这是**工作区的近似**，**不是**任务栏矩形 —— Linux 上查询不到任务栏几何，本函数**不去编一个**」，同段还写明**为什么 `ABM_GETTASKBARPOS` 返 0**（返 TRUE 会把最大化尺寸从工作区改成整屏，"那是另一件事的修法"）⇒ **没有把近似写成真值** ✓。

---

## 4. 显示号租借（**我自己起显示、自己租、自己收**）

```
bash build/MilBridge/tools/display-lease.sh acquire --pool 230:239 --lane t9verifier --job w28x-b
 → DISPLAY_LEASE=ACQUIRED display=:230 prior_absent=1 exclusive_now=1 holder_pid=2825420 … socket_absent=1
```
| 腿 | 我的动作 | 现取读数 | 判定 |
|---|---|---|---|
| ① 我起 `Xvfb :230`（**持有租约**） | `verify` | `DISPLAY_LEASE=FAIL reason=not-my-lease … my_pid=…` | 不是我的租约 ⇒ 老实拒（**不静默换号**）✓ |
| ② 同上 | `reap` | `DISPLAY_LEASE=NOINFO reason=socket-or-server-owned display=:230 occupants=2（不回收）`，**我的 Xvfb 仍活** | ✓ 不回收活着的 |
| ③ 我另起 `:231`（**没有租约**） | `reap` | 只 `examined=1`（那条租约）；**`:231` 的 Xvfb 仍活** | ✓ **"没起过时一个都不杀"** |
| ④ 我按 PID 杀掉两个 Xvfb 后 | `reap` | `DISPLAY_LEASE=REAPED display=:230 pid=2825420 lstart_match=1`；`REAP=OK examined=1 reaped=1 noinfo=0` | ✓ 收尾后**无残留进程**（`ps` 现取无 `Xvfb`，无 `HandyControlDemo`） |
- 反模式杀（`D-G103` 族）：源码现取**只按 PID**（`/proc/<pid>` ＋ `ps -o pid= -p`）且**自带禁用声明**（"**禁** `pgrep -f`／`pkill -f`"）；我的实跑里 `reap` 没有任何"按模式"的痕迹（`:231` 未被动）✓。

---

## 5. 导出数（**口径显式声明**）＋ `0744-FU`

```
在册口径 pts-gap-count-check.sh:144  EXPORTS=$(wc -l < "$N/bin/exports.txt")   → 554
nm -D --defined-only | wc -l                                                   → 554   （551 T ＋ 3 B）
nm -D --defined-only | awk '$2=="T"' | wc -l                                   → 551   （另一口径：只要 T）
nm -D | wc -l                                                                  → 646   （含未定义 U）
grep -n SHAppBarMessage src/WpfGfx.Linux.Native/bin/exports.txt                → 421:SHAppBarMessage
PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=97 so16=e8127a3d7128d417 exports=554
```
- **在册口径与 `--defined-only` 逐值相符（554 == 554）** ✓，且 `exports.txt`（生成件）**同趟重生成**（含 `SHAppBarMessage`）✓。
- 🔴 **"550 → 551"被现场推翻**：现读 **554**。波前件（`~/w181a/w7x/native/base/bin/libwpfwin32.so` = `fc60c34d51fd9247`，＝ `#77` 九位值）现取 **550 / 547 T / 642** ⇒ 本波 **+4**，逐名差集现取为：
  `SHAppBarMessage`（`TASK-0747`）＋ **`wpf_x11_workarea_src`／`wpf_x11_workarea_prop`／`wpf_x11_workarea_declare`**（`D-G147` 的工作区出处三元）——**都落在本波声明的改件**（`win32_oem.c`／`win32_x11.c`／`win32_core.c`／`win32_misc.c`／`win32_internal.h`）里。
- `TASK-0744-FU`：`--cases` ⇒ `PROTO_ATTR_GATE=PASS examined=18 mismatch=0 posctl=2/2 cut_and_pair=1`，新格现取 `PROTO_ATTR_IDENT cases=18 sock_present=0 sock_absent=18 sock_malformed=0`（语料自身无身份）；**真腿**（仓内归档腿 `build/MilBridge/geom-corpus/W134A-A1-OLD-6`）⇒ `verdict=NOINFO reason=sock-id-absent ident=absent`（rc=3）⇒ **FU 的新装置未能回溯旧台账**（旧腿里没有身份数据）——与 `#77` 的射程边界同一条，**不是本波引入**。

---

## 6. 冻后两趟 `verify-all`、推送、哨兵、`porcelain`

| 趟 | 日志 | rc | 步骤 | 用例 | 判词域 |
|---|---|---|---|---|---|
| post1 | `~/w185a/w77/logs/w78-post1-20260927-110835.log` | 0 | **51 ✅ / 0 ❌** | 875 通过 / 2 跳过 | 133 行 |
| post2 | `~/w185a/w77/logs/w78-post2-20260927-112348.log` | 0 | **51 ✅ / 0 ❌** | 875 / 2 | 133 行 |

- mtime：post1 `11:23:48`、post2 `11:38:21`，**都晚于冻结时刻 `09:55:11`**（`~/w21-verify/w78-POST.done` 0 B、mtime `09:55:11`）✓。
- 判词域比：原始差异 **24** 行；归一化（路径/tmpdir/时间戳/`avail*`/`mem_mb`/`wall_s`/`held`）后**仍有 1 对差异**：
  `THIRDPARTY=PASS frames=42 …` ↔ `THIRDPARTY=PASS frames=43 …`（**活第三方应用的帧计数**；同行的判据字段 `max_colors=1642`／`min_colors=800` 与 PASS 结论**不变**）⇒ **"判词行逐字一致"应读作"除活应用帧计数外逐字一致"**。
- 🔎 **`~/w21-verify/w78-record.txt` 不存在**；`#78` 的记录模板实际在 `~/w186a/w78/w78freeze/w78-record.txt`（＝冻结器 `GENS['#78']['TXT']`，26884 B，mtime 09-27 00:05）；它的九位行把 `provider` 写成**字面量 `609192a419d125f2`**（其余位是 `{PC}`/`{PF}`/… 占位符）⇒ **F1 的根因**。
- 推送：本地 `HEAD=993eb5d…` == 远端 `refs/heads/feat-Linux`（同 sha）✓；本波 5 笔（`3c302ce`／`192f54e`／`3b5af06`／`f4c93e5`／`993eb5d`）**逐件核 52 个变更路径**：**50 件 `HEAD:` blob == 工作树**，**2 件 DIFF** = `build/MilBridge/tools/defect-registry-declared.tsv`（mtime 11:47）与 `build/MilBridge/tools/wave-freeze-consistency-check.py`（mtime 11:48）——**都是别的车道在我复验期间的未提交改动**（见 §7-③）。
- 哨兵：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ `IDENTICAL`、两份 `%h=1` ✓（内容与现读九位一致，**但 `provider` 是 `a00895e8158189b9`，即与九位行不一致**）。
- `porcelain`：11:41 现取 **0**；11:5x 现取 **6**（全部是别的车道的在飞件，§7-③）。

---

## 7. 现场注记（不是波的红，但会污染读数）

1. **"pool-exhausted" 的理由串**：`display-lease.sh` 的白名单是 `POOL_RE='^:?23[0-9]$'`（现取:46）。我试 `--pool 240:245` 与 `--pool 250:255` ⇒ 两次 `DISPLAY_LEASE=FAIL reason=pool-exhausted`，而真实原因是**整池都在白名单之外**（`--display :99` 那条路径才会打更准确的 `pool-out-of-whitelist`）⇒ **理由串误导**（方向安全：响亮失败，不静默换号）。
2. **Xvfb 的 atom 生命周期（我的仪器坑，留档）**：用 `xprop -set`／`XChangeDisplay` 后**立刻退出**的客户端设 `_NET_WORKAREA`，根属性会**随该客户端断连而消失**（另一客户端读到空；探针读回 `prop_present=0`）⇒ 我前两轮 D-G147 极性读数**作废**，改用自写"设属性并保持连接"的 `holdprop` 才拿到档②④⑤。**这不是产品问题**（真 WM 常驻）。
3. **`inputs_fp` 在我复验期间位移**：11:41 现取 `a3bded5d…`（== 冻结值，`porcelain=0`）；11:5x 现取 `55e3f855…`、`porcelain=6`。逐件定位：`build/MilBridge/tools/{defect-registry-declared.tsv,wave-freeze-consistency-check.py}`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（mtime 11:47–11:48）＋ 3 个新件（`pkg-src-retiredpath-check.sh`／`wfreeze-root-sites.tsv`／`blockvalues-shift.tsv`，11:45–11:50）——**是别的车道在改树**（看起来正是 `t18` 残留那条的后续）。⇒ **`INFP_AT_PUSH == FROZEN_INFP` 在"我复验那一刻"只能读成"曾经成立"**，本报告把两个时刻都写下来。

---

## 8. 我推翻／打折扣的话 ＋ 判据缺口（findings）

1. 🔴 **`#78` 冻结块九位行的 `provider` 是上一代值**（`609192a419d125f2`）：与**同块 6 条 `BASELINE tier=`**、**双哨兵**、**现读**（`a00895e8158189b9`）**三处都矛盾**；根因＝记录模板 `~/w186a/w78/w78freeze/w78-record.txt` 把 `provider`（与 `wic_shim`）写成**字面量** ⇒ 这是 `t6`/`t17` 记的 `D-G149` 的**第三次复发**（`t17` 只写了设计与待办，冻结器与模板都未落）。
2. 🔴 **导出数「550 → 551」不成立**：现读 **554**（在册口径 == `--defined-only`：554 == 554），**+4** = `SHAppBarMessage` ＋ 3 条 `D-G147` 出处导出（逐名给出）。在册口径**内部自洽** ✓，但主控的预期数**少算了 3 条**。
3. ⚠️ **"D-G147 在 ROUTES／缺陷册／declared.tsv 三处一致"不成立**：`declared.tsv:76 ID D-G147 req=AB present=AB` ✓、`ROUTES.md:731/766/775` ✓，但**缺陷册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 里没有 `D-G147`**（册内是 `D-G140–G146`、`D-G149–G151`、`D-G156/G165/G166`）⇒ 三处不一致。**缓解事实**：`ROUTES.md:775` 自己写着「**本批未登记（等落地配号）**：`D-G147`＋`TASK-0748`…」⇒ 是**声明过的缺口**，不是静默遗漏；且注册器对它的要求只是 `req=AB`（已满足）。**DEFREG 现取**：`DEFREG=PASS declared=201 route_ids=201`、`DEFREG_DECLDRIFT=0`（注意：`declared` 11:47 被别的车道重发过，冻结时的读数见其报告）。
4. ⚠️ **"两趟判词行逐字一致"要打折扣**：归一化后仍差 **1 对**（`THIRDPARTY frames=42↔43`，活应用帧计数；判据字段与结论不变）⇒ 严谨表述是"**除活应用帧计数外**逐字一致"。
5. ⚠️ **`~/w21-verify/w78-record.txt` 不存在**（验收给的路径）；记录模板实际在 `~/w186a/w78/w78freeze/w78-record.txt`。
6. ⚠️ **`porcelain=0` 是 11:41 的读数**：11:5x 已是 6（**别的车道**在飞），逐件核 52 件里差异恰为那 2 件 ⇒ 本波自身入笔是干净的。

**边界与 `NOINFO`**：① 0744-FU 的**真腿 `ATTRIBUTED` 仍不可达**（旧台账无身份；我只能复跑归档腿 ⇒ `NOINFO`）；② 本件**未跑** `verify-all`（无重活，避免动派生件；两趟由日志逐趟复算）；③ `upstream/wpf/`、`build/MilBridge/HANDOFF-NEXT.md`、`docs/CURRENT-STATE.md` 在派单声明的边界外（未判）；④ 我**没有**验证 `~/w21-verify/**` 的写入轨迹（主控写域，只读）；⑤ 显示号租借的**并发**语义（两个租借者同时抢同一号）我**没有**做并发两极化（只做了单进程 acquire/verify/reap）；⑥ `D-CH`/`KRJ`/`KRF`/`KRP` 三条锚（`DEFREG_EXTRA`）未逐条复算。

---

## 9. 复算命令索引

```
# 九位 / 步数 / 覆盖面
cd $N && for f in <九条>; do sha256sum "$f"|cut -c1-16; done ; grep -c '^run_step "' verify-all.sh
bash ~/w153a/bin/infp.sh fp ; bash ~/w153a/bin/infp.sh list | wc -l ; grep -n -- '--expect 217' verify-all.sh
# 0747 两极化（我私有）
bash ~/w28x/task0747-pair.sh            # A/B/C/D/E/F 六腿 ＋ 差值 ＋ cmp（读数 ~/w28x/logs-pair.txt）
gcc -o ~/w28x/probe ~/w28x/probe.c -ldl && ~/w28x/probe $N/src/WpfGfx.Linux.Native/bin/libwpfwin32.so
# D-G147 五档
gcc -o ~/w28x/holdprop ~/w28x/holdprop.c -lX11 ; Xvfb :239 … ; DISPLAY=:239 ~/w28x/holdprop :239 _NET_WORKAREA "0,0,1280,968" 12 &
# 显示号租借
bash build/MilBridge/tools/display-lease.sh acquire --pool 230:239 --lane t9verifier --job w28x-b ; … reap
# 导出数（三口径）
wc -l < $N/src/WpfGfx.Linux.Native/bin/exports.txt ; nm -D --defined-only … | wc -l ; nm -D --defined-only … | awk '$2=="T"' | wc -l ; nm -D … | wc -l
# 两趟日志
diff <(grep -E '…' w78-post1.log) <(grep -E '…' w78-post2.log) | grep -c '^[<>]'    # 24（归一化后 2）
# 推送逐件 ＋ 哨兵
git rev-parse HEAD ; git ls-remote origin refs/heads/feat-Linux ; for p in $(git diff --name-status 3c302ce~1..HEAD | awk '{print $NF}'); do … done
cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag
```

`V78VERIFY=DONE verdict=FAIL(见 §8-①②) nine=8/9+provider陈旧 steps=51/51/51/51 coverage=217(fp=a3bded5d,11:41) pair0747=+242恰(我自造反事实+原始件双构造) export=554(exports.txt==defined-only;T=551;nm -D=646) d_g147=5档可区分 lease=ACQUIRED/REAPED且无残留 post=51✅/0❌×2(判词域除frames外逐字同) push=50/52SAME(2件为别的车道在飞) sentinel=IDENTICAL porcelain=11:41时0/11:5x时6 noinfo=6`

`SELF_SHA16=bdb92a6453e83e4f`（**口径 = 去掉本行**：`head -n -1 build/MilBridge/V78-verify-report.md | sha256sum | cut -c1-16`；自指件只报这一个口径）
