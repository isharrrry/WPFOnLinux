# 波 `#48` · 车道 `W51A` 报告 —— 冻结件（`gen=#48`）上的**冻后 `verify-all` 两趟**

> **任务**：`#48` 已冻结（`BASELINE-FROZEN gen=#48 sha16=540725342059b820`）⇒ 在冻结件上**跑两趟 `verify-all`、如实报读数**。
> **仓库根**：`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（全程绝对路径）。
> **本报告的性质**：**读数记账**。凡"我以为"的地方一律写成 `NOINFO` 或"假说"，**绝不与"已测"混写**。
> **环境**（每趟都记，纪律 32）：`lane=W51A`｜`host=linksdev-VirtualBox`｜`kernel=6.8.0-138-generic`｜`nproc=3`。
> **写域**：**只新增本文件**；scratch 全在 `$HOME/w51a/**`。仓内零改动（§5.1 有 `find -newermt` 实测）。
> **纪律**：SDK 走 `export PATH="$HOME/.dotnet:$PATH"`；`dotnet -m:1`、`DOTNET_gcServer=0`；**零 `pkill -f`**；两趟**严格串行**；每趟跑前"另一个重活为空且持续 60 s ＋ `MemAvailable≥1500 MB`"由脚本硬门控。

---

## 0 一句话结论

**两趟都 `rc=0`、`步骤通过 25 ❌ 失败 0`（失败步名**为空**）、`用例通过 871 跳过 2`；冻前唯一红 `COLUMN-FLOOR` 两趟都绿。**
两趟**不是逐字相同**，**唯一实质差异**是**别的车道的缺陷登记**在**第一趟窗口内**落地（`DEFREG` 的 `declared` `96→97`）——两趟各自读到一个**自洽**版本、**都绿** ⇒ **两趟读数都可归因**（§7.1 有完整证据链）。
**另有一条对派单书前提的收窄**：`[0]` 只从 `pgrep -a Xvfb` 取候选，**低号"活"显示（`:0`/`:1`/`:10`）根本不进候选**；本机 `D-G59` **没有触发**，但它的触发条件比派单书写得更窄（§6）。

---

## 1 我做了什么（可复算的入口）

```
mkdir -p $HOME/w51a
bash $HOME/w51a/run-w51a.sh 1     # → rc=0, 846 s
bash $HOME/w51a/run-w51a.sh 2     # → rc=0, 847 s
```

`run-w51a.sh`（`$HOME/w51a/run-w51a.sh`，sha16 `b32b150ed63610cc`，3331 B，mtime `2026-09-20 00:52:38`）做四件事，**全部只写 `$HOME/w51a/`**：

1. **pre-flight 快照**（loadavg / `MemAvailable` / `/tmp/.X11-unix/` / `pgrep -a Xvfb` / 重活进程 / `verify-all.sh` 的 sha16+mtime / 冻结声明）；
2. **静默门控**：`pgrep -af 'verify-all|run-wpftextdemo|integration-wave|retake-arms'` 为空**且**`MemAvailable≥1500 MB` ⇒ 再 `sleep 60` **复核第二次**，仍满足才放行；否则等 30 s 重试（≤40 次，超限 `exit 8`）；
3. `bash verify-all.sh > post-freeze-<N>.log 2>&1`，记 `rc` 与起止时刻；
4. **post-flight**：复算 `verify-all.sh` 的 sha16 —— **跨趟变了就打印"本趟读数不可归因"**（这是 `W49A` 第二趟那次事故的牙）。

---

## 2 冻结点独立复核（两趟之前，现场算）

| 项 | 现场读数 | 判据 |
|---|---|---|
| `docs/CURRENT-STATE.md:9` | `> BASELINE-FROZEN gen=#48 sha16=540725342059b820 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | 逐字 |
| `sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `540725342059b820` | **与声明逐位相同**（我自己算的，不是抄的） |
| 上述两文件 mtime | 均 `2026-09-20 00:51:46` | `CURRENT-STATE.md` sha16 `67fe204995e82f41`（370,200 B）｜`ACCEPTANCE-BASELINE.md` 593,971 B |
| 当前 `# RE-FROZEN` 块 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:7` = `# RE-FROZEN #48 —— ✅ **当前冻结基线**` | **最新块在文件顶部**（`#47` 在 `:113`、`#46` 在 `:198`） |
| 被检对象 `verify-all.sh` | sha16 `5ee3ad984ee7412d`，79,389 B，mtime `2026-09-20 00:19:02` | **两趟前后四次复算全部同值**（§3） |

> ⚠️ **顺带纠正一条易踩的口径**：`verify-all.sh` 的头部 `# VERIFYALL-STEPS-DECL: 25 gen=#48`（`:44`）**不是**冻结那一刻才写的 —— 该文件 mtime 是 `00:19:02`，而**冻前那趟（`00:45`）用的就是同一份**（见 §5 表里它的 `vfile_sha16=5ee3ad984ee7412d` 与我这趟**逐字相同**）⇒ 冻前那趟的 `BASELINEGEN` 读到的 `decl_gen=#47` 是**另一件仪器**（冻结标记件）的值，不是 `verify-all.sh` 的声明。两件仪器读两个东西，**不能互相引用**。

---

## 3 两趟读数

| | **第一趟** | **第二趟** |
|---|---|---|
| 起 | `2026-09-20 00:53:39+0800` | `2026-09-20 01:08:47+0800` |
| 止 | `2026-09-20 01:07:45+0800` | `2026-09-20 01:22:54+0800` |
| **`rc`** | **`0`** | **`0`** |
| `elapsed`（脚本自算） | **846 s** | **847 s** |
| 步骤 | **`步骤通过 25  ❌ 失败 0`** | **`步骤通过 25  ❌ 失败 0`** |
| **失败步名** | **（空）** | **（空）** |
| 用例 | `用例通过 871  跳过 2` | `用例通过 871  跳过 2` |
| 结论行 | `结论：✅ 全部通过` | `结论：✅ 全部通过` |
| 跑前 `loadavg` | `0.76 0.54 0.86` | `0.64 1.22 1.16` |
| 跑前 `MemAvailable` | `2670 MB` | `2598 MB` |
| 跑后 `loadavg` | `0.69 1.24 1.17` | `0.68 0.91 1.02` |
| 跑后 `MemAvailable` | `2328 MB` | `2454 MB` |
| 静默门控 | `QUIET_OK attempt=1 mem=2671->2665MB` | `QUIET_OK attempt=1 mem=2598->2769MB` |
| **`verify-all.sh` sha16 跑前→跑后** | `5ee3ad984ee7412d` → `5ee3ad984ee7412d` | `5ee3ad984ee7412d` → `5ee3ad984ee7412d` |
| **漂移判词** | **`DRIFT=NO`（可归因）** | **`DRIFT=NO`（可归因）** |
| 日志 sha16 / 大小 | `75b2dcd65471d79e` / 9,334 B | `665b7b0766959095` / 9,334 B |

`pc`（权威件）**两趟各三处自报**（`FRAME_STEP_LEGS`／`HIDDEN_ONLY_STEP`／`PRODUCT_ENTRY_STEP`）**全部** `9465f9dce39e2dfc`（共 6 处，`grep -o 'pc=[0-9a-f]\{16\}'` 逐趟 3 行、`sort -u` 单值）。

**两趟差异全清单（16 行，逐行给出，不隐藏）** —— `diff post-freeze-1.log post-freeze-2.log`：

| 类别 | 第一趟 → 第二趟 | 是否实质 |
|---|---|---|
| 抬头时刻 | `00:53:39` → `01:08:47` | 否（时间戳） |
| `TLINE_GATE` 行 | **逐字相同**，仅 `outdir=…tline-gate-20260920-005532` → `…-011038` | 否（临时目录名） |
| **`DEFREG` 行** | **`declared=96 route_ids=96` → `declared=97 route_ids=97`** | **是**（§7.1） |
| `COLUMN_FLOOR_SELFREPORT` | `gate=747c078dbf040862` **同值**，仅 `outdir=/tmp/column-floor.UFVyJF` → `.jXEVIg` | 否（`mktemp` 名） |
| `FRAMEPRESENCE` | `frames=80 max_colors=4113` **同值**，`magenta_frames=37` → `39` | 否（**抓帧抖动**，见 §7.3） |
| `THIRDPARTY` | `frames=43 max_colors=1642 min_colors=800` **同值**，仅 `dir=…w37-tpm-010713` → `…-012222` | 否（临时目录名） |

> **刻意不"两趟逐字相同"当口径**（本仓 `docs/WAVE46-CLOSEOUT-RUNBOOK.md` §12 已立此规矩，派单书也点了）：`FRAMEPRESENCE`/`THIRDPARTY` 的帧数有抓帧抖动，两趟**都 PASS**。**我用的口径是"§4 那 8 条机器行两趟逐字相同 ＋ `rc`/步数/失败步名相同"。**

---

## 4 关键原文（两趟逐字，⚠️ 均带 `· 自报口径 ` 前缀的绿行；失败时该前缀会消失，见 §5）

```
[0] Xvfb（目标 :99）
  ✅ 复用已运行的 Xvfb（实测 display :97，注意不是 :99）
  DISPLAY=:97（已用 xdpyinfo 验证可连）
  X_STATE=available（判据：xdpyinfo 对 DISPLAY=:97 成功 ⇒ available）

COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=25c21ca0f33208ae base=540725342059b820 corpus=0cebc0afd5142fbf
COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无
COLUMN_FLOOR_CORPUS=PASS file=…/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json live=0cebc0afd5142fbf decl=0cebc0afd5142fbf
ARMLOG_SHA=PASS shape=flat logdir=…/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
BASELINESHA=PASS live=540725342059b820 decl=540725342059b820
BASELINEGEN=PASS decl_gen=#48 file_newest_gen=#48
VERIFYALL_SELF=PASS names=25 decl=25 gen=#48 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=5ee3ad984ee7412d
SKIP_GUARD=PASS x_state=available x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none
```

**机器核对**：上列 8 条（除 `DEFREG` 那条不在此列）**两趟逐字相同** —— 我用 `grep -m1 -o '<KEY>.*'` 逐键对拍，输出无差别。
另两条也应记录（两趟同值）：`BASELINEDUP=PASS n=0`；`COLUMN_FLOOR_SELFREPORT=PASS gate=747c078dbf040862`（`gate=` 值两趟**逐位相同** —— 这是本趟最强的可复现性证据之一）。

---

## 5 与冻前那趟的对照

**基准**：`$HOME/w50a/06-verify-all-pre.log`（8,664 B，mtime `2026-09-20 00:45`，冻前、`gen=#47`）。

| 项 | 冻前（`#47`，`00:45`） | **冻后第一趟** | **冻后第二趟** |
|---|---|---|---|
| `rc` | `1` | **`0`** | **`0`** |
| 步骤 | `步骤通过 24  ❌ 失败 1` | **`25 / 0`** | **`25 / 0`** |
| **失败步名** | **`COLUMN-FLOOR`** | **（空）** | **（空）** |
| 结论行 | `结论：❌ 失败项：COLUMN-FLOOR` | `结论：✅ 全部通过` | `结论：✅ 全部通过` |
| `BASELINESHA` | `PASS live=9b9e3cb7bcb8280b decl=9b9e3cb7bcb8280b` | `PASS live=540725342059b820 decl=540725342059b820` | 同左 |
| `BASELINEGEN` | `PASS decl_gen=#47 file_newest_gen=#47` | `PASS decl_gen=#48 file_newest_gen=#48` | 同左 |
| `ARMLOG_SHA` | **`PASS … pass=5 fail=0 noinfo=0`** | `PASS … pass=5 fail=0` | 同左 |
| **`COLUMN_FLOOR_ARMLOG`** | **`FAIL n_decl=5 n_ok=4 bad= tline`** | **`PASS n_decl=5 n_ok=5 bad=无`** | 同左 |
| `COLUMN_FLOOR` | **`FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=25c21ca0f33208ae base=9b9e3cb7bcb8280b corpus=0cebc0afd5142fbf`** | **`PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=25c21ca0f33208ae base=540725342059b820 corpus=0cebc0afd5142fbf`** | 同左 |
| `VERIFYALL_SELF` | `PASS … gen=#48 … vfile_sha16=5ee3ad984ee7412d` | 同左（**逐字相同**） | 同左 |
| `SKIP_GUARD` | `PASS x_state=available … total_skipped=2` | 同左 | 同左 |

### 5.1 唯一那颗红是**哪一颗牙**、以及它为什么转绿（根因，带行号）

派单书 §④ 明确点名"**`ARM-LOG-SHA` 与 `COLUMN-FLOOR(ARMLOG)` 不是同一颗牙**" —— **实测完全支持**：冻前 `ARMLOG_SHA` 就已经是 `PASS pass=5 fail=0`，唯一红的是 `COLUMN_FLOOR_ARMLOG=FAIL … bad= tline`。

**根因 = 冻结块里的 `# ARM-LOG-SHA arm=tline` 那一行**（`column-floor-check.sh:341-379` 的第 ⑤ 档：**冻结块声明 ⇔ `known-red.json` 的 `generation.arm_logs`**，比的是前 16 位）：

| 件 | 值 | 现场证据 |
|---|---|---|
| 现盘 `build/MilBridge/arm-logs/tline.log` | `960e28f59ee974e5` | `sha256sum` 现场算；mtime `2026-09-20 00:17:57`，`links=2` |
| `known-red.json` 的 `generation.arm_logs.tline` | `960e28f59ee974e5`（64 位全值） | `known-red.json` sha16 `25c21ca0f33208ae`，61,815 B，mtime **`00:24:34`**（**冻前就没再动过**） |
| **`#47` 冻结块声明**（`ACCEPTANCE-BASELINE.md:916`） | **`57d752a3981a9b91`** | ⇒ **MISMATCH** ⇒ 冻前 `bad= tline` |
| **`#48` 冻结块声明**（`ACCEPTANCE-BASELINE.md:62`） | **`960e28f59ee974e5`** | ⇒ **MATCH** ⇒ 冻后 `n_ok=5 bad=无` |

该行的注释自陈了这件事（`ACCEPTANCE-BASELINE.md:62` 逐字）：`← **重取后**的现场值（主控按 sha256sum build/MilBridge/arm-logs/tline.log 改写；重取前为 3a6eca716ada5bdb）`。
⇒ **这不是"产品件变了"，是"冻结块把重取后的臂日志 sha 补齐了"**。臂日志本身是 `W50A` 在 `00:15:39–00:21:17` 重取的那五份（`$HOME/w50a/03-retake-arms.log`：`tline rc=1 / tab-zero rc=1 / tab-anchor rc=0 / tab-rtl rc=0 / textlineproto rc=0`，五份 `ln -f` 硬链接、`links=2`）。
⚠️ **注意 `tline rc=1` 不是"臂失败"**：门禁口径下 `tline` 是**在册红**臂（`TLINE_GATE=… red=2 green=3 registered=4 unlocated=1 … unregistered=0`）——这种非零退出码属**期望值**，不得据此判红（本仓纪律：`127`＝没跑成、`MSB1009`＝路径错、**在册红臂 rc≠0＝设计**）。

---

## 6 `[0]` 选了哪个显示 ＋ `D-G59` 本机现场

| 项 | 读数 |
|---|---|
| **`[0]` 选的显示号** | **`:97`**（两趟相同：`✅ 复用已运行的 Xvfb（实测 display :97，注意不是 :99）`） |
| 目标号 `DISPLAY_NUM` | `:99`（`verify-all.sh:136`），且 **`:99` 实测连不上**（`xdpyinfo` 失败） |
| `X_STATE` | **`available`**（两趟） |
| `SKIP_GUARD` | **`PASS`**（两趟），`x_suite_skipped=0`、`total_skipped=2` |
| 两趟的 X 相关用例 | **零静默跳过**（`Windowing/HelloMil/ManagedLayer/Presentation` 各套件 `跳过 0`） |

### 6.1 `D-G59` **本机没有触发** —— 而且触发条件比派单书写的**更窄**（一处前提收窄）

派单书说：「若机器上残留低号**死**显示（如别人私有 Xvfb 的 `:64`/`:66`），`[0]` 会选中它」。**本机实测：低号显示确实存在、而且全是"活的"，但它们一个都进不了候选**：

`/tmp/.X11-unix/` 现场四个 socket，`ss -xlp` 落主（**这是"谁在用"的判据，不是我的推测**）：

| 显示 | 落主（`ss -xlp`） | PID | 可连（`xdpyinfo`） | 是否 `pgrep -a Xvfb` 候选 |
|---|---|---|---|---|
| `:0` | `Xwayland` | 2252 | **是** | **否** |
| `:1` | `gnome-shell` | 1215 | **是** | **否** |
| `:10` | `/usr/lib/xorg/Xorg :10 -auth .Xauthority -config xrdp/xorg.conf` | 1751220 | **是** | **否** |
| `:97` | **`Xvfb :97 -screen 0 1280x1024x24`** | **68922** | **是** | **是（唯一）** |

**候选抽取流水线（逐字取自 `verify-all.sh:371`，我现场跑了一遍）**：

```
$ pgrep -a Xvfb 2>/dev/null | grep -oE ' :[0-9]+' | tr -d ' :' | sort -u
97
$ # 逐个 xdpyinfo：candidate :97 -> chosen (connectable)
```

⇒ **只有一个候选，`sort -u` 无歧义，`:97` 可连 ⇒ 被选中**。两条结论：

1. **收窄**：`[0]` 的候选来源是 **`pgrep -a Xvfb`（进程名）**，**不是 socket 目录**。`Xwayland`/`gnome-shell`/`Xorg` **进程名都不叫 `Xvfb`** ⇒ 无论它们占着多低的号、是死是活，**都进不了候选**。派单书里"低号**死**显示"这一形态（`W49A` 第二趟撞到的 `:66`）**确实是** `D-G59` 的触发形态（那台是别人私有 **`Xvfb`**），但**"残留 socket"本身不构成触发** —— 触发条件应写成「**机器上出现了一个号更小的 `Xvfb` 进程（无论死活）**」。
2. **残留风险仍在**：若真出现号 < 97 的 `Xvfb`（哪怕是死的），`sort -u` 会取字符串序最小者、**且选定后不复核**（`[0]` 判词里"已用 xdpyinfo 验证可连"用的是 `chosen` 那一刻的结果，但 `chosen` 一旦被选就不再回头验）⇒ `D-G59` **活着**。本趟**没有**这个条件，所以**两趟都不受它影响**。

**我做的处置：零处置 —— 一个 socket、一个进程都没删。** 理由：`:0`/`:1`/`:10` 全是**别人正在用的活会话**（`Xwayland`/`gnome-shell`/`xrdp` 的 `Xorg`），派单书明确要求"只清你自己或无属主的 socket/进程、别碰别人在用的"；而它们**本来就不是** `D-G59` 的触发物（见上）。`W51B` 的独立报告为此提供了旁证（`build/MilBridge/W51B-report.md` 逐字）：`私有 display :33（按 PID 收，未碰 :97/:66/:64/:37/:38/:39/:35/:36）`。

---

## 7 异常与并发披露

### 7.1 ⚠️ **第一趟窗口内有别的车道在写仓**（**四条**，已完整归因，**未撕裂读数**）

⚠️ **先交代一处我自己的仪器缺陷（自我更正）**：我第一次扫用的是**路径清单** `find build/ docs/ src/ samples/ verify-all.sh …`，**漏了仓库根** ⇒ **漏掉了根目录下的 `handoff.md`**（它是 `DEFREG` 的 route 件之一，见下 `HO=`）。改用 `find .`（全树、只排除我这趟测试自己生成的产物）后是**四条**。⇒ 下面给的是**改对之后**的读数。

`find . -newermt '2026-09-20 00:53:39' ! -newermt '2026-09-20 01:07:50' -type f`（排除 `*/obj/*`、`*/bin/*`、`*/.artifacts/*`，并排除 `tests/artifacts|parity/linux/diff|parity/linux/actual|Windowing.Tests/artifacts` 与 `parity-results.json` —— **最后这几类是"我这趟 `verify-all` 的测试产物"**）命中**四条**：

| 时刻 | 件 | 大小 | 说明 |
|---|---|---|---|
| `01:05:04` | `build/MilBridge/W51B-report.md` | 29,084 B | 另一车道的报告（**无仪器读它**） |
| `01:05:33` | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | 359,563 B | **`DEFREG` 的 route 件**（tsv 的 `KD=`） |
| `01:05:33` | `handoff.md` | 1,082,833 B | **`DEFREG` 的 route 件**（tsv 的 `HO=`，sha16 `e4dc264200b421d0`） |
| `01:05:46` | `build/MilBridge/tools/defect-registry-declared.tsv` | 5,114 B | **`DEFREG` 的声明件本身** |

**后三条正好是第 `[10]` 步 `DEFECT-REGISTRY` 的输入（两个 route 件 ＋ 声明件）** ⇒ 必须交代。证据链：

1. **不是我的**：我两趟**没有写任何仓内文件**（§7.2 是我的足迹自检）；`W51B` 自己的报告 §8 也写明"本车道仓内只新增本报告一个文件"，并把 `KNOWN-DEFECTS.md`/`tsv` 归给**别的车道**。
2. **不是工具写的**：`defect-registry-check.sh` 对 tsv 只有**读**（`:58` 定义 `DECL`；`:311`/`:321` 只算 sha）；它的写全是 `$T/…`（`:289-298`）⇒ tsv **不是**第 `[10]` 步自己生成的。
3. **它是"生成物"且自洽**：`tsv:1` 逐字 `# DECL-GEN = (--emit) 2026-09-20 01:05:46 +0800`；`tsv:2` 的 `DECL-ANCHORS` 我逐项复算**全部与现场件相同** —— `KD=698bfc6452ea8520`（= 现盘 `KNOWN-DEFECTS.md`）、`HO=e4dc264200b421d0`（= 现盘 `handoff.md`）、`CS=67fe204995e82f41`（= `docs/CURRENT-STATE.md`，即**冻结那一刻**）、`AB=540725342059b820`（= **`#48` 冻结基线**）、`KRJ=25c21ca0f33208ae`（= `known-red.json`）、`KRF=ab09235afd949bc2`（= `known-red-frame-structural.md`）⇒ **这是一次"登记（缺陷册 ＋ handoff 同秒改写）＋ 声明重生成"，且落在冻结基线上**。
4. **登记了什么**：`KNOWN-DEFECTS.md` 该次改动处新增了 `### D-G59`（`:2123`，`verify-all.sh` 选 X 显示用字符串序最小 ⇒ 可能选中别人遗留的死显示）、`### D-G60`（`:2129`）、`### D-G61`（`:2145`，**仪器缺陷**：`HC_INPUT_DIAG=1` ＋ `[GEO]` 转储时点下拉项静默 SIGSEGV —— 与 `W51B` §6 的发现同源）。三者都标了「**新**」。
5. **读数没有被撕裂（关键）**：
   - 第一趟 `DEFREG=PASS declared=96 route_ids=96`；第二趟 `DEFREG=PASS declared=97 route_ids=97`；**两趟都 PASS**。
   - 冻结前那趟（`00:45`）也是 `declared=96 route_ids=96`。
   - `KNOWN-DEFECTS.md`/`handoff.md` 改于 `01:05:33`、tsv 重生成于 `01:05:46` ⇒ 中间有 **13 s** 是"route 件已变、声明未跟"的**不一致窗口**，此时跑 `DEFREG` **应当红**。**第一趟跑出的是 `96`（自洽的旧版）⇒ 它读的是 `01:05:46` 之前的版本，没有落进那 13 s**。
   - ⇒ **两趟各读到一个自洽版本，都绿**；差异**可完整归因**（不是"不知哪里来的抖动"）。**这正是 `W49A` 第二趟的反面**：那次 `verify-all.sh` **本体**被改写（读过的东西在两个时刻不是同一份且无从对齐）⇒ 不可归因；这次被改的是**被检数据**（缺陷册/route/登记表），**门禁本体 `verify-all.sh` 四次复算同值**，且**两版各自自洽、都绿**。
   - ⚠️ **诚实边界**：我**没有**保留 `01:05:46` 之前的 tsv 副本 ⇒ "**96→97 到底是哪一个编号**"我**测不出**（只知 `KNOWN-DEFECTS.md` 那一次新增了 `D-G59`/`D-G60`/`D-G61` 三条、而声明数**净增 1**）⇒ 写成 **`NOINFO`**，不猜。

### 7.2 我的仓内足迹自检（证明 §7.1 那四条不是我的）

```
$ find . -newermt '2026-09-20 00:52:00' -type f -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/.artifacts/*'
  （排除 tests/artifacts、tests/parity/linux/{diff,actual}、Windowing.Tests/artifacts、parity-results.json = 我这趟 verify-all 的测试产物）
  ./build/MilBridge/tools/defect-registry-declared.tsv     01:05:46
  ./build/MilBridge/W51B-report.md                         01:05:04
  ./samples/WpfFeatureProbe/KNOWN-DEFECTS.md               01:05:33
  ./handoff.md                                             01:05:33
  ./build/MilBridge/W51A-report.md                         01:24:06   ← **本报告 = 我唯一新增的仓内文件**
$ find $R -newermt '2026-09-20 00:52:00' -type f -newer build/MilBridge/W50A-report.md -name 'W51A*'   # 同上
```

（`00:51:14 W50A-report.md`、`00:51:46 ACCEPTANCE-BASELINE.md`/`CURRENT-STATE.md` 两条也在窗口外沿，但它们是**我开工前**的冻结动作，列在 §2。）

**第二趟窗口**（`01:08:47 → 01:22:54`）同一条**全树** `find`（同样排除我这趟的测试产物）：**零命中** ⇒ 第二趟是一趟**静树**读数。

### 7.3 抓帧抖动（**已知、非新异常、两趟都 PASS**）

`FRAMEPRESENCE magenta_frames=37`（第一趟）→ `39`（第二趟）——**同一份件、同一条命令**。这正是本仓已立的规矩所预期的抖动（`docs/WAVE46-CLOSEOUT-RUNBOOK.md` §12）⇒ **不当作判据、不当作异常**；两趟 `FRAMEPRESENCE=PASS`（判据是 `min_colors=200` 那一档，两趟都是 `max_colors=4113`）。

### 7.4 一条 `NOINFO`（**两趟都在、冻前也在**，不并入 `rc`）

`VERIFYALL_SELF=PASS … dynamic_trace=NOINFO vfile_sha16=5ee3ad984ee7412d` —— `dynamic_trace` 是 `NOINFO` 但整步判 `PASS`、`rc=0`。它**冻前那趟就是 `NOINFO`**（`$HOME/w50a/06-verify-all-pre.log:66` **逐字相同**）⇒ **不是本波引入、不是本趟引入**。⚠️ 按本仓规矩「`NOINFO` 不许当绿」，我**不**把它读成"动态轨迹已验证"；它只说明**该子项没有检定**、且**设计上不并入 `rc`**（`column-floor-check.sh:64-70` 记录了同族的聚合口径理由）。**这一条我没有独立复核它的成因** ⇒ 属**未测**。

---

## 8 不能测的 / 明确 `NOINFO`

1. **`96→97` 的归因**：无 `01:05:46` 前的 tsv 副本 ⇒ **哪一个编号是新增的，测不出**（§7.1 第 5 条末）。只知净增 1、且 `KNOWN-DEFECTS.md` 同次新增 `D-G59`/`D-G60`/`D-G61` 三条。
2. **本趟**不证**任何一颗牙会红**：我**没有**跑任何反极性/回退（那不在本车道射程内）。⇒ 本报告只证「**冻结件上两趟全绿且可归因**」，**不证**「这些牙有判别力」。**这是射程边界，不是"已证绿"。**
3. **`dynamic_trace=NOINFO` 的成因**：未测（§7.4）。
4. **`unlocated=1`**：门禁行 `TLINE_GATE=PASS … registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK` —— `unlocated=1` 是**在册且未定位**的臂，两趟**同值**、门禁判 `PASS`。我**没有**去核它是哪一支（本车道只做"跑两趟、如实报"）⇒ 列在此处以免读者把它读成"5 臂全定位"。
5. **`.xwd`**：本趟**没有产生任何 `.xwd`**（`find $HOME/w51a -name '*.xwd' | wc -l` = **0**）⇒ 派单书的"跑完删 `.xwd`"这一条**无物可删**；`$HOME/w51a/` 收工 **52 KB**。

---

## 9 读数表（谁跑的、什么时候、机器什么状态 —— 纪律 32）

**`lane=W51A`｜`host=linksdev-VirtualBox`｜`kernel=6.8.0-138-generic`｜`nproc=3`**

| 项 | 第一趟 | 第二趟 |
|---|---|---|
| 日期时刻（起 / 止） | `2026-09-20 00:53:39 / 01:07:45 +0800` | `2026-09-20 01:08:47 / 01:22:54 +0800` |
| `loadavg`（起 / 止） | `0.76 0.54 0.86 / 0.69 1.24 1.17` | `0.64 1.22 1.16 / 0.68 0.91 1.02` |
| `MemAvailable`（起 / 止） | `2670 / 2328 MB` | `2598 / 2454 MB` |
| 命令 | `bash $HOME/w51a/run-w51a.sh 1` | `bash $HOME/w51a/run-w51a.sh 2` |
| `rc` / `elapsed` | `0` / `846 s` | `0` / `847 s` |
| 日志（路径 / sha16 / 大小） | `$HOME/w51a/post-freeze-1.log` / `75b2dcd65471d79e` / 9,334 B | `$HOME/w51a/post-freeze-2.log` / `665b7b0766959095` / 9,334 B |
| 跑前快照 | `$HOME/w51a/pre-1.log` / `bdb85e7c755fb2e6` | `$HOME/w51a/pre-2.log` / `c806593ed586b9ff` |
| 跑后元数据 | `$HOME/w51a/postmeta-1.log` / `e1886ae6f324fa3c` | `$HOME/w51a/postmeta-2.log` / `33d5a99b1cc87c5e` |
| **被检件 `verify-all.sh`** | `5ee3ad984ee7412d`（79,389 B，mtime `00:19:02`）**跑前=跑后** | 同值，**跑前=跑后** |
| 语料 `tab-anchor-oracle.json` | `0cebc0afd5142fbf`（门禁自报 live=decl） | 同值 |
| 冻结基线 | `540725342059b820`（门禁自报 `live=decl`） | 同值 |
| 登记表 `known-red.json` | `25c21ca0f33208ae`（`COLUMN_FLOOR` 行的 `reg=`） | 同值 |
| 权威件 `pc` | `9465f9dce39e2dfc` | `9465f9dce39e2dfc` |
| 显示 | `DISPLAY=:97`，`X_STATE=available` | 同值 |
| 私有 scratch | `$HOME/w51a/**`（收工 52 KB，零 `.xwd`） | 同值 |

---

## 10 给主控的一句话交接

**`#48` 冻后两趟 `verify-all` 都 `rc=0`、`25 ✅ / 0 ❌`（失败步名空）、`871 通过 / 2 跳过`，两趟都可归因**；冻前唯一红 `COLUMN-FLOOR` 已转绿，**转绿的是 `COLUMN_FLOOR_ARMLOG` 这颗牙**（根因 = `#48` 冻结块把 `# ARM-LOG-SHA arm=tline` 从 `57d752a3981a9b91` 重钉到 `960e28f59ee974e5`，与登记表对齐），**`ARM-LOG-SHA` 冻前冻后都是 `PASS`**；`[0]` 两趟都选 `:97`、`D-G59` **本机未触发**（触发条件是"号更小的 **`Xvfb`** 进程"，低号 socket 本身不算）；**第一趟窗口内有别车道在写 `KNOWN-DEFECTS.md` ＋ `handoff.md`（两个 route 件）＋ 重生成 `defect-registry-declared.tsv`（`DEFREG` `96→97`，两趟各读一个自洽版本、都绿；第二趟窗口是静树）**。
