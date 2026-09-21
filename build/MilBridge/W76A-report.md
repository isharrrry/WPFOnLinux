# W76A 报告 —— 波 `#49` 收尾链与冻结（`TASK-9904`，含 `TASK-9903` 余项、`TASK-0802` 余项、`D-G77`／`D-G79` 的修法与取证）

> 车道 `W76A`（**重派**：上一条同名车道 `W71A` 在会话挂起时中途死掉、未交报告）。
> 任务书：`/home/links-dev/w71a/BRIEF.md`。仓库根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`。
> 本报告的所有数字都是**现场算的**（命令逐条给出）；不确定的一律写 `NOINFO`。

---

## ① 勘察结论：整波**从未跑过**，从 §6 收尾链**第 ② 步**接续

| 证据（现场读） | 读数 | 说明 |
|---|---|---|
| `build/wave-audit.log` 最后一条 | `2026-09-20T00:11:55 owner=w50a cmd=bash build/integration-wave.sh` | 那是 **`#48`** 的波；`#49` 的整波**一次都没跑** |
| `build/MilBridge/arm-logs/*.log` mtime | 五件全在 `9-20 00:17–00:21` | 五臂**未重取** |
| `bash build/MilBridge/tools/baseline-sha-check.sh` | `BASELINESHA=PASS live=540725342059b820`／`BASELINEGEN=PASS decl_gen=#48 file_newest_gen=#48`／`BASELINE_BYTES=593971` | 树仍停在 **`#48`** 冻结 |
| `known-red.json` `entries[1].expected_shape` | `count==95` | 零墨修法后的重钉**未做** |
| `~/w71a/` 目录 | **只有 `BRIEF.md`**（没有 `logs/`、没有报告） | 上一条车道**连第一步都没落地** |
| 三处世代位（开工实测） | `hbtextline 921ba9c65e9fb3be`／`pc 21e3e88a5090cd3b`／`win32shim c493639d15678803` | 波内车道（W70A 等）**已把修法落进树**，但**没有走波**（`pc` 是**定向重建**值） |

⇒ **判断：不是"跑到一半"，而是"改动已落地、波未开跑"** ⇒ 从 `docs/WAVE49-PREREGISTRATION.md` §6 的**第 ② 步**（`integration-wave`）接续，前面没有需要"接着跑"的半成品。
⚠️ **另有两处开工前就必须先补的"前件"**（预登记 §6 ① 与 `w27-freeze.py` 的表里都没有）：
1. `verify-all.sh` 的世代声明还是 `gen=#48` ⇒ 冻不住（冻结器断言头注释里有"**``#49`` 收官起 = 25 步**"）；
2. `~/w21-verify/w27-freeze.py` 的 `GENS` 表**没有 `'#49'` 项** ⇒ `assert gen in GENS` 直接崩。
这两件**都是主控写域**，本轮由本车道补（已在开工前告知主控并获确认独占）。

---

## ② 每步命令 ＋ 原始读数 ＋ `rc`

### 2.0 前件（本车道补，见 ① 的理由）

| 件 | 改前 → 改后（sha16） | 现场读数 |
|---|---|---|
| `verify-all.sh` | `bb416e92ab34ff64`（改后） | `VERIFYALL_SELF=PASS names=25 decl=25 gen=#49 dup=0 order=OK prose=OK prereg=PASS`（改前是 `gen=#48`）—— 只加"DECL 首行 ＋ 口径句"两处，**步数不动 = 25** |
| `~/w49-pre.sha` | 新建（9 行，sha16 `40c4bab047e25365`） | **不是活取的**：三处世代位在本车道开工前已被波内车道改过 ⇒ 按 **`#48` 冻结块**九位逐位重建（见 ③） |
| `~/w21-verify/w27-freeze.py` | 追加 `GENS['#49']` 一项 | `hb='921ba9c65e9fb3be'`（零墨修后的值）、`bs_fp='0a8f69b3c5fabd43'`（桥重发后现场）、`prev='#48'`、`allow_changed={bridge,pc,pf,windowsbase,win32shim,hbtextline}` |

### 2.1 第 ② 步 · 整波 `WAVE_OWNER=W76A bash build/integration-wave.sh`

```
WAVE_START=2026-09-21T15:31:40+08:00  memavail=2074MB
HEAVYSLOT=ACQUIRED waited=43s           ← 前面是 W77A 的 150 s 档
HEAVYSLOT=MEMOK avail=2415MB min_avail=1500MB
  ▶ 波责任人：W76A（记录于 build/wave-audit.log）
输入指纹（波前）：03506d351ef4a56767b775d53cbe22e203e573372adbf483942c30e4741e9d5e
APPLIER_AUDIT_SUMMARY appliers=26 ok=89 miss=0 red=0 rc=0
=== 集成波结束：失败步骤 0 ===
HEAVYSLOT=RELEASED rc=0 held=233s
WAVE_RC=0
```
* **`rc=0`**，`失败步骤 0`，耗时 **233 s**（短步，`--max-hold 300 -- timeout 280` ⇒ **照旧未放宽**）。
* ⚠️ 任务书**红字②**（"4 份原生 `.so` 副本落后于权威"）**由整波自己解决**：日志逐条 `REFRESH`（`abf6879c027c5e73 → c493639d15678803`，四份：`MilBridge/tests/CompositeFontProbe/bin/Release`／`MilBridge/tests/ContractProbe/bin/Release`／`DirectWrite.Linux/SystemFontsProbe/bin/Debug`／`samples/WpfFeatureProbe/bin/Release/net10.0`）⇒ **不需要手做**（也**没有**手做）。

### 2.2 第 ③ 步 · 桥按需重发 `bash build/publish-milbridge.sh`

```
PUBLISH_START fp_before=BRIDGE_SRC_FP=0a8f69b3c5fabd43 BRIDGE_SRC_N=78   ← 现树
                       记录=f10b4b297b2358e6                            ← 发布记录（不同 ⇒ 必须重发）
bridge 79e45aed26487045 → feef049e9d0e313a  (5,028,208 B)
fp_after=BRIDGE_SRC_FP=0a8f69b3c5fabd43（两侧一致）
HEAVYSLOT=RELEASED rc=0 held=23s
```
* **`rc=0`**、held **23 s**。`bridge` 位 `79e45aed26487045 → feef049e9d0e313a`（`TASK-0403` 的台账进 `MilChannel`/`MilCommandDispatcher` ⇒ 源指纹必变）。

### 2.3 第 ④ 步 · 重取五臂（**三轮**：第一轮作废，正式两趟）

| 趟 | 命令 | `rc` | held | 读数 |
|---|---|---|---|---|
| ① 第一轮（**作废**） | `ARMS_OUT=$HOME/w76a/arms …retake-arms-w23.sh` | 0 | 340 s | `:97` **不存在** ⇒ `textlineproto` **X-混淆**（见 ④ `D-G77`） |
| ② 修后·无 `:97`（自起） | 同上，`ARMS_OUT=$HOME/w76a/arms-self` | 0 | 329 s | `ARMS_DISPLAY=:97 source=self-started xvfb_pid=261466`；五臂 `XOpenDisplay` 计数 **0**；`textlineproto` 判词 **通过 4 / 失败 2** |
| ③ 修后·有 `:97`（复用） | 同上，`ARMS_OUT=$HOME/w76a/arms-reused` | 0 | 333 s | `ARMS_DISPLAY=:97 source=reused`；判词 **4 / 2**；**硬链接进 `arm-logs/` 的终态** |

**臂日志 sha16**（③ = 终态）：

| 臂 | `#48` 冻结值 | 第一轮（作废） | ②（自起） | ③（复用，**终态**） |
|---|---|---|---|---|
| `tline` | `960e28f59ee974e5` | `60f0f63d2b5ac8df` | `deb49fbf21fb3b3f` | **`2103f88183b17a6a`** |
| `tab-zero` | `9150c3a26a3cb789` | 同 | 同 | **`9150c3a26a3cb789`**（未变） |
| `tab-anchor` | `1c43a12dcaa5718a` | 同 | 同 | **`1c43a12dcaa5718a`**（未变） |
| `tab-rtl` | `92570318851ca7e8` | 同 | 同 | **`92570318851ca7e8`**（未变） |
| `textlineproto` | `4bceceeed570ba70` | `c1a5cf0a72bbd12d`（**假位移**） | `4bceceeed570ba70` | **`4bceceeed570ba70`**（回到冻结值） |

* ⚠️ `tline.log` ② 与 ③ 的 sha **不同**（`deb49fbf…` vs `2103f881…`）而 `textlineproto` 逐行相同 —— 这是 `#48` 已登记的事实：**`tline.log` 程序上不可复算**（耗时字段、**自指**的上一趟产物 sha、日期戳文件名、`mktemp` 路径）。本波按 **③**（复用 `:97`，与门禁同径）重钉，并把这条写进 `NOINFO`。

### 2.4 第 ⑤ 步 · 重钉 `repin-generation.py`

```
# 第一次（entry 重钉后）
REPIN_GENERATION=APPLIED
  generation.instr_run_sh = 711f39f468f61cc8
  generation.instr_program_cs = 149dd986a642fdfc
  generation.instr_shim = 921ba9c65e9fb3be      ← e89fed55fd8e32bc → 新
  generation.evidence_log_sha256 = 60f0f63d2b5ac8df
  entries[*].caliber 改动字段数 = 4
REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + 4 条 entries 的 caliber 全部一致）

# 第二次（X-混淆作废、正式两趟重取之后）
REPIN_GENERATION=APPLIED
  generation.evidence_log_sha256 = 2103f88183b17a6a
  entries[*].caliber 改动字段数 = 0
REPIN_GENERATION=PASS
```
* `known-red.json` 轨迹：`25c21ca0f33208ae`（改前，`entries[1]` 仍是 `count==95`）→ `a22648c79ca71801`（`entries[1]` 重钉为 `count==1242`）→ `e38300c235593d3b`（第一次 repin）→ **`00ad5e0c38379a13`**（第二次 repin）。
* **`entries[1]` 的重钉是"必做"，理由与现场读数**：`build/MilBridge/arm-logs/tline.log:149` 原文
  `[② Extent 余差清单] 共 1242 条（主对拍集 1202 + LH 组 40；容差 0.01 DIP）`
  —— 零墨修法**改变了墨迹盒（Extent）**，条数 `95 → 1242`；门禁的 `eval_shape` 逐字比 `expected_shape`，不改就 `registry-stale(drift)` ⇒ FAIL。

### 2.5 第 ⑥ 步 · 门禁 ×2（**修 `D-G79` 之后**）

| 趟 | 命令 | `rc` | 结果 |
|---|---|---|---|
| 第 1 趟（写 rows） | `WPTD_RUN_DIR=$HOME/w76a/gate-fix/e WPTD_BASELINE_OUT=$HOME/w76a/gate-fix/rows.txt bash tests/…/run-wpftextdemo.sh 60 --tier both`（槽内） | **0** | `WPTD_TIER=default rep=1/2/3 RESULT=PASS` ＋ `env rep=1/2/3 RESULT=PASS` ⇒ **6/6 PASS** |
| 第 2 趟 | 同上（`WPTD_RUN_DIR=…/f`，不写 rows） | **0** | **6/6 PASS** |

* 机读行：`/home/links-dev/w76a/gate-fix/rows.txt`（sha16 **`b26e038e893b386a`**）—— **6 行，`result=PASS` ×6**，每行含 `pc:56ee75ced8d6aece`／`pf:6375fabf89ac7fef`（= 冻结器要断言的终态）。
* 窗口认领读数：`窗口：0x200005（等到首绘信号约 0s）` —— **修前**同样是这句命令，读到的是 `0x200006` 且永不 `IsViewable`。

### 2.6 第 ⑦ 步 · 冻前 `verify-all`

〔见 ⑦ 小节：读数在冻结完成后回填〕

### 2.7 第 ⑧ 步 · 冻结 `w27-freeze.py`

〔见 ⑥ 小节〕

### 2.8 第 ⑨ 步 · 冻后 `verify-all` ×2

〔见 ⑦ 小节〕

---

## ③ 三处世代位新旧值 ＋ `inputs_fp` 新旧值

**九位**（`Release` 权威件；冻结那一刻现算）：

| 位 | `#48` 冻结值（= `PRE`） | 本波终态 | 位移原因 |
|---|---|---|---|
| `bridge` | `e3ea092010734f44` | `feef049e9d0e313a` | `TASK-0403` 台账进 `MilChannel`/`MilCommandDispatcher` ⇒ 源指纹变 ⇒ **按需重发**（波前 `79e45aed26487045` 是波内车道已重发的一次） |
| `pc` | `9465f9dce39e2dfc` | `56ee75ced8d6aece` | 零墨修法（被引件字节进 Roslyn 输入哈希 ⇒ 级联）＋整波重建 |
| `pf` | `1011da6390c3bf1e` | `6375fabf89ac7fef` | 同上（整波重建） |
| `windowsbase` | `79740e9ba7fbf9ca` | `2e4e46e539a72cd7` | 整波重建（波前就已由波内车道重建） |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | **未动** |
| `win32shim` | `abf6879c027c5e73` | `c493639d15678803` | `D-G72`/`TASK-0008`：`GetMonitorInfoW` 按 `cbSize` 写入（+ 波 58/59 的窗口尺寸钳制） |
| `wic_shim` | `56278c14b4ecd672` | `56278c14b4ecd672` | **未动** |
| `hbtextline` | `e89fed55fd8e32bc` | `921ba9c65e9fb3be` | `D-G57` 零墨修法（单段分支按**计划面**取字形 id） |
| `dwf` | `de2d555105b7d04b` | `de2d555105b7d04b` | **未动** |

⇒ **位移集合 = {`bridge`,`pc`,`pf`,`windowsbase`,`win32shim`,`hbtextline`}**（6 位；`GENS['#49']['allow_changed']` 逐字就是这 6 位，**表外位移 = 空**）。

⚠️⚠️ **必记一行（主控点名要求）**：`pc`/`pf` 的**整波重建值**与**定向重建值**不同 ——
零墨修法后只重建 `build/PresentationCore.Linux` 得到 `pc 21e3e88a5090cd3b`；**整波重建**得到 `pc 56ee75ced8d6aece`（`pf` 同理：定向 `1011da6390c3bf1e` → 整波 `6375fabf89ac7fef`）。
**同一个源、不同的构建范围/顺序会给出不同字节**（`D-G46` 族；`W70A` 已证"同命令连跑两次同值"⇒ 不是随机）⇒ **本波冻结取整波值**。**不许**把这两处读成漂移。

⚠️ **`PRE` 快照的口径（必写）**：`~/w49-pre.sha`（9 行、键=**路径**）**不是**"开工前活取"的 ——
本波三处世代位在**本车道开工之前**就被波内车道改过（`hbtextline` 12:32／`win32shim` 12:31／`pc` 12:33）⇒ 现场**已不存在**"改前值"⇒ 无法活取。
⇒ 按 **`#48` 冻结块**九位**逐位重建**（可复算：值就是 `#48` 冻结块里那九个数）。因此冻结器算出的 `changed` = **本波相对 `#48` 冻结点**的位移本身（与 `#46`/`#47`/`#48` 的"产品位移"一栏同形）。

⚠️ **`inputs_fp`**（照抄 `close-wave.sh` 的**真函数**，不复制函数体）：

| 时点 | 值 |
|---|---|
| `#48` 冻结值（`prev_infp`） | `cad0801cf1dff2fdf1600b803315d1c57b0d2afcc9ebf45e170f2b3885677da4` |
| 本波开工（重钉前、`known-red` 未动） | `991a7d38ac0212160f56b8eb60844a28379fe1f1e8de9b8a0952f5239a2ec731` |
| **本波终态（冻结那一刻现算）** | **`{INFP}`**（冻结器打印；上面两值只作对账） |

**可归因五件**（`fp_inputs()` 覆盖面现场点算 = **143 件**）：① `build/close-wave.sh` 的 `fp_inputs()` 新增 `src/WpfGfx.Linux.Native/**/*.{c,h}`（`B4`/`R-CSRC`）＋ 三件判据件（`C2`/`C4`：`sync-applocal.sh`／`check-applocal-sync.sh`／`applocal-expect.py`）；② `build/shims/PresentationCore.HbTextLine.cs`；③ `src/WpfGfx.Linux/{Resources/MilChannel.cs,Commands/MilCommandDispatcher.cs}`；④ `src/WpfGfx.Linux.Native/src/{win32_core.c,win32_internal.h,win32_x11.c}`；⑤ `build/MilBridge/known-red.json`（`entries[1]` 重钉 ＋ `repin-generation` 重钉世代/五臂）。
⚠️ **本波改的两件仪器都不在覆盖面里**（`sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh | grep -c 'retake-arms\|run-wpftextdemo'` = **0**）⇒ **改它们不动 `inputs_fp`**，`--why` 无需为此记账。

---

## ④ `D-G77`：重取五臂的"显示号没保证"（已修 ＋ 两极性）

**现场（第一轮重取，15:37:58–15:43:38）**：`build/MilBridge/tools/retake-arms-w23.sh` 第 4 步**硬写 `DISPLAY=:97`**，而当时 `ls /tmp/.X11-unix` 只有 `X0 X1 X36`（`Xvfb :97` **不存在**）。
成对证据：`textlineproto` 臂日志出现 **2 条** `XOpenDisplay(":97") 失败` ＋ `[WIN_DIAG] CreateWindowEx 失败` ＋ `[SHIM_DIAG] HwndWrapper 建窗失败`；`P4（new DrawingVisual().RenderOpen() 在纯 PC 下可用）` **PASS → FAIL**；`探针：通过 4 / 失败 2` → **`通过 3 / 失败 3`**；臂 sha `4bceceeed570ba70 → c1a5cf0a72bbd12d`（**假位移**）。另四臂 `XOpenDisplay` 计数 **0**（未混淆，但**这条洞对它们同样成立**）。
时序证据：臂重取窗口 `15:37:58–15:43:38` 全程 `:97` **DOWN**；`:97` 是门禁第一趟 `15:44:33` 自起时才有的。

**修法**（`build/MilBridge/tools/retake-arms-w23.sh`，`2546fee35078a993 → a160671709db61c2`）：
`:97` 不在 ⇒ **自起 Xvfb 并记 PID**（跑完按 PID 收回自己起的那个）；**起不来 ⇒ `exit 5` 大声失败**（绝不带着"没有 X"往下跑）。第 4 步那行**内容一字未动**（行号由 `:83` 移到 `:131`，主控已把 `KNOWN-DEFECTS.md` 的引用改到 `:131`）。

**两极性读数（修后件）**：

| 支 | 前置 | 读数 | 判据 |
|---|---|---|---|
| ① 无 `:97` | `kill` 常驻 `:97`（实测 `:97 DOWN`） | `ARMS_DISPLAY=:97 source=self-started xvfb_pid=261466`；五臂 `XOpenDisplay` 计数全 **0**；`textlineproto` 判词 **通过 4 / 失败 2**；`textlineproto` sha 回到 `4bceceeed570ba70`（= `#48` 冻结值） | ✅ 自起后**成功**且**不混淆** |
| ①b 无 `:97` ∧ Xvfb 不可用 | `ARMS_XVFB_BIN=/nonexistent/Xvfb` | `rc=5`；`ARMS_DISPLAY=FAIL reason=no-xvfb-bin display=:97 bin=/nonexistent/Xvfb` ＋ "拒跑" | ✅ **大声失败**（不是静默给假读数） |
| ② 有 `:97` | `setsid Xvfb :97`（PID 262347） | `ARMS_DISPLAY=:97 source=reused`；判词 **4 / 2**；**硬链接进 `arm-logs/` 的终态** | ✅ 照旧成功 |

**① 与 ② 的等价性**：`textlineproto.log` 两支**去时间戳后逐行 `diff` = 空** ⇒ "自起"与"复用"**同判**（不是两种读数）。

---

## ⑤ `D-G79`：应用门禁"按标题认领窗口"其实在按 **WM_CLASS** 认领（已修 ＋ 两极性）

**现场**：门禁 **两趟 ×2 = 12/12 假 FAIL**（`fail_reasons=("no-window")`、`capture=all-blank colors=0`、`exit=143`＝应用活着）。
第一趟是门禁自起 `Xvfb :97`（PID 101837）；按 `docs/WAVE18-PREREGISTRATION.md:86` 的纪律起**常驻** `Xvfb :97`（`setsid`，PID 183453）再跑第二遍 ⇒ **仍 6/6 FAIL** ⇒ 排除"X 不稳/偶发"。

**机制（最小复现，同一份件、同一 app-local 目录 `~/w76a/gate2-e`）**：`xwininfo -root -tree` 逐字（**xwininfo 给的次序 = `head -1` 的取值域**）：
```
0x200006 (has no name): ("HwndWrapper[WpfTextDemo;;94a965e1…]") 800x600 +0+0   ← head -1 取它：Map State: IsUnMapped，**永远不 map**
0x200005 "WpfTextDemo — text / binding / image / effect": (…) 938x938 +0+0      ← **真窗**：Map State: IsViewable
0x200004 "SystemResourceNotifyWindow" / 0x200003 "MediaContextNotificationWindow" / 0x200002 (has no name)  800x600
```
应用侧自报（`WPF_LINUX_CREATE_DIAG=1`）：
`[CREATE_DIAG] CREATE xid=0x200005 style=0x2cf0000` → `[CREATE_DIAG] CREATE xid=0x200006 style=0x0`（**在主窗之后、`ShowWindow` 之前**由**托管侧**新建；`XCreateSimpleWindow` 在 shim 里只有一处 `win32_x11.c:404`）→ `[SHOW_DIAG] ShowWindow hwnd=0x200005 a=5` → `[CREATE_DIAG] MAP xid=0x200005 … 938x938`。
⇒ X 里**新建窗口默认压在最上层** ⇒ 那个无名顶层窗排第一；而门禁那句 `grep -F 'WpfTextDemo'` 命中的是 **`WM_CLASS`**（本进程**每个**顶层窗都是 `HwndWrapper[WpfTextDemo;;<guid>]`）⇒ 5 个窗全成候选，`head -1` 取到的是**永远不 map** 的无名窗 ⇒ 60 s 超时判 `no-window`。
⇒ **产品侧没有回归**：真窗建/缩放/映射/呈现全正常（`[mil 8] X11 Resize → 938x938`、`committed=886`、`skia 指令 261 条`、`未画种类 0`）。
⇒ 对照 `#48`（W48A）那趟的 `windows-*.txt`：**唯一候选就是 `0x200005`** ⇒ **这条洞一直在，只是这一代被触发**。

**修法**（`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh`，`e657abba148a9bce → ddb79c4843c0aa3e`）：
`head -1` → **枚举全部候选**，取**第一个**「`WM_NAME` 以 `WpfTextDemo` 开头 ∧ 宽高 ≥64 ∧ `Map State: IsViewable`」者；候选日志同时印 `name=`。
⚠️ **修的过程中自己踩的一个坑（如实记，可复用）**：`xwininfo -id` 的输出**首行是空行**，`xwininfo: Window id: …` 在**第二行** ⇒ 我第一版写 `sed -n '1s/…/p'` **逐趟取到空串**（候选日志出现 `name=?` ⇒ 所有候选被拒 ⇒ **仍然 `no-window`**）。改成"逐行匹配、取第一条命中"后正常。**判据差异 = 只差这一处**（`3feab1cdac3318a7` → `ddb79c4843c0aa3e`）。

**正极性（修前/修后成对，同一棵树、同一份件）**：

| | 修前 | 修后 |
|---|---|---|
| 认领对象 | `head -1 = 0x200006`（无名、`IsUnMapped`、永远不 map） | `0x200005`（`name="WpfTextDemo — …"`、938x938、`IsViewable`） |
| 门禁读数 | `fail_reasons=("no-window")`，**12/12 FAIL** | `窗口：0x200005（等到首绘信号约 0s）`，**两趟各 6/6 PASS**（`rc=0`） |

**反极性（"真窗认不出来 ⇒ 必须仍 FAIL"）**：用一个**全程存活**的观察者把真窗的 `WM_NAME` 改名并持续 `unmap`（确定性：改名后标题永远不以 `WpfTextDemo` 开头）⇒
```
篡改条数 = 1        ← tamper 0x200005 "WpfTextDemo — text / binding / image / effect"
WPTD_TIER=default rep=1 RESULT=FAIL / rep=2 RESULT=FAIL / rep=3 RESULT=FAIL
❌ 没找到本应用的窗口（标题 WpfTextDemo 未出现）
候选行：0x200005 name=(has no name) 938x938 map=IsViewable   ← **可见，但标题不匹配 ⇒ 仍然被拒**
```
⇒ ✅ **判据没有放宽**：**不是**"任意候选可见即过"。
⚠️ 第一次反极性尝试**是空测**（观察者只活 79 s，而门禁真正起应用在 2–4 min 之后 ⇒ 篡改 0 条）—— 该趟读数**已作废**，上面是第一版修好后重跑的。

**残余边界（如实划，未纳入本修法）**：一个**别的进程**的**可见**窗口若标题也以 `WpfTextDemo` 开头，仍会被认领 —— 这与修前注释里"按标题认领"的**原意一致**，但**不是**"只认我自己的进程树"。
**同族未修的三处载体**（同一句 `… | grep -F 'WpfTextDemo' | grep -oE '0x…' | head -1`，**已登记未动**，等主控裁定）：
`build/MilBridge/tools/t1c-census.sh:248`（**census 现场同样被认错**：本波 census 读数 `SHOT frames=0 best_colors=0 best= win=0x200006`）／`run-wpftextdemo.sh:850`（`first-sight` 抢拍）／`run-wpfprobe.sh:412`。

---

## ⑥ 冻结（基线 sha16 ＋ 世代号）

〔回填〕

---

## ⑦ `verify-all`：冻前 1 趟 ＋ 冻后 2 趟

〔回填〕

---

## ⑧ 推送（`TASK-0802` 余项）

〔回填〕

---

## ⑨ `NOINFO` 清单

1. **`D-G79` 的"那个无名顶层窗（`0x200006`，`style=0x0`）是谁建的、能不能不建"** —— 按主控裁定**不在本波**（已记入 `D-G79` 的边界；冻结后另派车道）。**不要**为它分心。
2. **`tline.log` ②/③ 两趟 sha 不同**（`deb49fbf21fb3b3f` vs `2103f88183b17a6a`）而 `textlineproto` 逐行相同 —— `tline.log` **程序上不可复算**（`#48` 已证：耗时字段、自指的上一趟产物 sha、日期戳文件名、`mktemp` 路径）⇒ **不构成位移信号**；本波按 ③ 重钉。
3. **同族三处载体未修**（`t1c-census.sh:248`／`run-wpftextdemo.sh:850`／`run-wpfprobe.sh:412`）—— 只登记，未动（不在授权范围）。
4. **反极性第一版是空测**（已作废、已重跑），如实留档。
5. 〔回填：verify-all 里若有 `INCONCLUSIVE`／跳过项，逐条列出〕

---

## ⑩ 内存三值 ＋ 短步/长步纪律

* **短步照 300/280**：整波（held **233 s**，`waited=43s`）｜桥重发（held **23 s**，`waited=0s`）｜门禁每趟（held ≤600）。
* **两条原子长步放宽（主控已批准）**：重取五臂 `--min-avail 1500 --max-hold 1200 -- timeout 1150`（实际 held **340／329／333 s**）｜`verify-all` `--min-avail 1500 --max-hold 1500 -- timeout 1450`（实际 held 见 ⑦）。**理由**：这两步是**原子长步**，300 s 装不下（按 runbook 实测"重取五臂 ≈10 min／`verify-all` ≈15–23 min"）；**`--min-avail 1500`（内存闸门）未动**，放宽**只限这两步**（**未**当默认）。
* **排队（别人等了多久）**：`HEAVYSLOT=ACQUIRED waited=…` 实测 —— 整波 `43 s`（前面是 W77A 的 150 s 档）｜桥重发 `0 s`｜重取①`0 s`②`0 s`（**本车道 1200 s 的持有把 W77A 挡在外面**，这是长步放宽的代价，如实记）｜门禁第 1 趟 `30 s`｜冻前 `verify-all` 见 ⑦。
* **内存**：`MemAvailable` 现场三值（开工／中段／收工）〔回填〕。

---

## 附 · 本波由本车道**新建/改动**的文件（含路径与 sha16）

| 件 | 说明 |
|---|---|
| `verify-all.sh` | `gen=#48` → `#49`（DECL 首行 ＋ 口径句）；`bb416e92ab34ff64` |
| `~/w49-pre.sha` | 新建（9 行）；`40c4bab047e25365` |
| `~/w21-verify/w27-freeze.py` | 追加 `GENS['#49']` |
| `~/w21-verify/w49-record.txt` | 收尾记录三段（banner／frozen／record） |
| `build/MilBridge/tools/retake-arms-w23.sh` | `D-G77` 修法；`2546fee35078a993 → a160671709db61c2` |
| `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh` | `D-G79` 修法；`e657abba148a9bce → ddb79c4843c0aa3e` |
| `build/MilBridge/known-red.json` | `entries[1]` 95→1242 ＋ 世代/五臂重钉；`25c21ca0f33208ae → 00ad5e0c38379a13` |
| `build/MilBridge/W76A-report.md` | 本报告 |
| `~/w76a/**` | 全部原始日志与装置（`logs/`、`bin/`、`arms-*/`、`gate-fix/`、`neg2/`） |
