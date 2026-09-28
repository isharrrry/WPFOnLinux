# P1-w2-heavy-legs-report —— `t14`（W2）两条遗留重活腿的**补跑读数**（`B-3②` ＋ `B-9`）

> **车道** `runner`／**任务** `t20`（attempt 1）。**判据先写**：`build/MilBridge/P1-w2-heavy-criteria.md`（`4de8b8239a7bbb3b`；跑前落盘，跑后未改）。
> **一句话**：**`B-9` 两条腿拿到了真读数并**两个方向都成立**（真 `Xvfb` 占用 ⇒ `rc=3` 拒跑，原文逐字在 §4；空号 ⇒ `DISPLAY_LEASE=free`）**；**`B-3②` 三支臂真跑成功**（20:20:57–20:29:09，槽 `waited=0s`），三份日志与在册臂日志**逐字节相同**（`cmp IDENTICAL`×3）⇒ 在册那条 `NOINFO(heavy-slot 被占)` 的**直接成因消失**；但**「死根面判活/死」这一格仍判不出** ⇒ 具名 `NOINFO`（§3），且顺带查出**一条现红**：五臂门禁 `[4]` 步现在 **`FAIL`（`GATE_REASON=probe-sha-mismatch`）**——因为三支臂日志（10:34）与探针二进制（10:31）都是 `Program.cs` **16:03 改动之前**那一代，而 `t14` 当时因槽被占**没能重取** ⇒ **与 `B-3②` 的 `NOINFO` 是同一根因**（§3④）。
> **读取时刻**：`2026-09-28T20:20–20:32 +08:00`；**交付冻结值**见 §11。**自报 sha16** 见末行。

---

## §0 结论摘要

| 项 | 读数（现取） |
|---|---|
| `B-3②` 三支臂（正极，`WPF_PROBE_COVERAGE_ROOT=$N`） | `tab-zero` **rc=1**（未登记失败 1）｜`tab-anchor` **rc=0**｜`tab-rtl` **rc=0**；三份日志与在册 **`cmp IDENTICAL`** |
| `B-3②` 缺根反极（env 不设） | **rc=0 ＋ 与正极逐字节同一份日志** ⇒ 现跑的**二进制里没有 env 守卫**（原因见 §3③：二进制早于源码） |
| `B-3②` 根敏感性（env 指向不存在的目录） | **rc=0 ＋ 与正极逐字节同一份日志** ⇒ **该判别器在本 artifact 上失效** |
| 三支臂日志的路径签名 | **零签名**（`wpf-linux-20260906` = 0 命中；现树绝对路径 = 0 命中，×3）⇒ 在册「臂日志零签名」**结构性成立**（§3②） |
| **五臂门禁 `[4]` 步现取** | **`TLINE_GATE=FAIL … GATE_PROBE=FAIL state=REGRESSED GATE_REASON=probe-sha-mismatch`，rc=1**（自报 `a6d0352b86467111` ≠ 现场 `Program.cs=c78ed88fc1fd34f4`，三支臂全中，§3④） |
| `B-9` 反极（真占用 `:236`） | **rc=3**；stderr 原文 `DISPLAY_OCCUPIED=:236 sock=/tmp/.X11-unix/X236 ⇒ 拒跑（号已被占；请用 W67_DISPLAY=<空闲号> 或先按 PID 收净）`；**未起应用**（`app_started=none`） |
| `B-9` 正极（空号 `:235`） | **rc=0**；stderr 原文 `DISPLAY_LEASE=free display=:235 sock=/tmp/.X11-unix/X235`；**无** `OCCUPIED` 行；未起应用（`W67_WORK` 为空目录） |
| 装置 | 两枚显示位都是私有 `:2xx`、几何 **`1280x1024x24`**；`Xvfb` 由我起、**按 PID 收**（`TEARDOWN pid=367229 resid=[none]`）⇒ 全机 `/proc` 现取**零 `Xvfb :23x` 残留** |
| 槽 | 3 次获取：`run-legs` `waited=0s held=492s`｜`run-b9`(第 2 次) `held=4s`｜`run-b9`(第 3 次) `held=14s` ⇒ **实占合计 510 s**；`TIMEOUT`／`NOINFO low-memory`／`MAXHOLD_KILL` **各 0**；**让路 0 s** |
| 件位 | 跑前＝跑后：`session_inner.sh a70aeb1d988ebc9e`｜`CoverageProbe/Program.cs c78ed88fc1fd34f4`｜`PresentationCore.Tests.dll 7d8ebb1e987a3b4b`｜`pkg-src-retiredpath-check.sh e0ab7bd668ffa8a1`｜三支语料同值 |

---

## §1 判据（先写，引用 ＋ 本件新增的两条结构事实）

- 判据件：`build/MilBridge/P1-w2-heavy-criteria.md`（`4de8b8239a7bbb3b`）。分母口径：`B-3②` ＝ 5 腿（3 正极 ＋ 1 缺根反极 ＋ 1 根敏感性）；`B-9` ＝ 2 腿（占用反极 ＋ 空号正极）。`NOINFO` 既不算绿也不算红；`HEAVYSLOT` 异常一律不入分母并点名。
- **跑前现取的两条结构事实**（写进了判据，是本件判词的支点）：
  1. `build/MilBridge/tests/CoverageProbe/Program.cs:141` ⇒ `--tab-lines-oracle` **提前 `return`**，**永不**走到 `:158` 那个会打印 `Root + "/build/fonts/NotoSans-Regular.ttf"` 的自检块 ⇒ **三支臂日志结构上不可能带根路径签名**。
  2. `:88` ⇒ `Root` 是**静态字段 ＋ `?? throw`** ⇒ env 不设时应在 `Main` 之前**响亮失败**（这是"缺根反极腿"的判据来源）。
- 在册入口：`build/MilBridge/arm-logs/README.md:15`–`:17`（`cd build/MilBridge/tests/CoverageProbe/bin/Release && dotnet PresentationCore.Tests.dll --tab-lines-oracle <corpus>`）；`B-9`：`W67_DISPLAY=<号> bash build/MilBridge/tests/PtsPagesProbe/session_inner.sh <tag> A:1`。

---

## §2 `B-3②` 逐腿机读读数（现取；台账 `~/t20-runner/legs-fixed.tsv` `64f1f04eb27c1fd6`）

| 腿 | 臂 | root | `rc` | 探针自报（sha16） | `START` 汇总 | `OVERFLOWED` 汇总 | `合计` | 未登记/FAILCASE | 字节 | vs 在册 |
|---|---|---|---|---|---|---|---|---|---|---|
| `L1` | `tab-zero` | `$N` | **1** | `a6d0352b86467111` | （该臂无此列） | `红=0 绿=0 判定行=0 NOINFO=138` | `cases=86 判定过=85 结构败=1` | `1/1` | 19,182 | **IDENTICAL** |
| `L2` | `tab-anchor` | `$N` | **0** | `a6d0352b86467111` | `红=0 绿=615 判定行=615 NOINFO=0` | `红=0 绿=421 判定行=421 NOINFO=194 真值True=22` | `cases=436 判定过=288 结构败=0 不可比(缺字形)=148` | `0/0` | 118,027 | **IDENTICAL** |
| `L3` | `tab-rtl` | `$N` | **0** | `a6d0352b86467111` | （该臂无此列） | `红=0 绿=0 判定行=0 NOINFO=163` | `cases=84 判定过=8 结构败=0 不可比(缺字形)=76` | `0/0` | 17,418 | **IDENTICAL** |
| `L4` | `tab-anchor` | **不设** | **0** | `a6d0352b86467111` | 同 L2 | 同 L2 | 同 L2 | `0/0` | 118,027 | **与 L2 逐字节 IDENTICAL** |
| `L5` | `tab-anchor` | `~/t20-runner/root-none`（**不存在**） | **0** | `a6d0352b86467111` | 同 L2 | 同 L2 | 同 L2 | `0/0` | 118,027 | **与 L2 逐字节 IDENTICAL** |

**逐字（两处）**：
- `L1` 的唯一未登记失败：`TAB_LINES UNREGISTERED notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1` ⇒ 末行 `TAB_LINES 退出码=1（未登记失败 1 / 失败共 1 / 登记表 <未给>）`（**与在册 tab-zero 逐字相同**）。
- `L2` 末行：`TAB_LINES 退出码=0（未登记失败 0 / 失败共 0 / 登记表 <未给>）`。
- **路径签名统计（辅助读数）**：三支臂日志里 `wpf-linux-20260906` 命中 **0**、现树绝对路径命中 **0** ⇒ **零签名**（与 §1 事实 1 的预测**逐条吻合**）。

**⇒ 第一半结论**：在册那条 `NOINFO(reason=heavy-slot 被占，三支臂未跑)` 的**直接成因已消除** —— 槽在跑前现取 `SLOT=FREE`、`HEAVYSLOT=ACQUIRED waited=0s`，三支臂**真跑**并产出**可复算的机读读数**，且**与在册臂日志逐字节相同**（三份都是 `cmp IDENTICAL`）⇒ 三支臂是**确定性**的，`t14` 当时缺的只是"槽"。

---

## §3 `B-3②` 的第二半：「死根面判活/死」＝ **`NOINFO`（具名，四条原因）**

**② 取证口选错了（方法学更正，非缺陷）**：在册的判法是「臂日志里**有**目标路径签名 ⇒ `used`；无 ⇒ 面死」。现取证明：`--tab-lines-oracle` **提前 return**（`:141`），而唯一打印 `Root + "/build/fonts/…"` 的自检块在另一方法（`:158`）⇒ **三支臂的日志永不带该签名**（本趟实测零签名 ×3）⇒ **这条判法在这三支臂上永远判不出结论**（不是"面死"，是"判法够不着"）。⇒ 建议改用**根敏感性**或**重建后重取**（见下）。

**③ 判别器在现 artifact 上失效（本件现取）**：现跑的**二进制**自报探针 sha＝`a6d0352b86467111`（= B-3① **之前**那一份 `Program.cs`），而**现源码**＝`c78ed88fc1fd34f4`（mtime `16:03:11`），`bin/Release/PresentationCore.Tests.dll` mtime `10:31:13` ⇒ **二进制早于源码**。后果（逐字节可核）：`L4`（env 不设）与 `L5`（env 指向不存在目录）**都与 `L2` 逐字节相同** ⇒ 现 artifact **根本不读** `WPF_PROBE_COVERAGE_ROOT` ⇒ 这两条腿**只能证明"env 未被消费"，不能判"硬编码根是否被消费"**。
**源码级旁证（只读，算不得运行读数）**：`:141` 提前 return ＋ 全件唯一 `Root` 使用点在 `:158`（另一方法）＋ 该路径的字体是**硬编码** `/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf` ⇒ 三支臂**不消费** `Root` ⇒ 「面＝死」**作为源码结论成立**，但**不许当绿**。

**④ 🔴 本件最重要的发现：五臂门禁 `[4]` 步现在红，且与 `B-3②` 的 `NOINFO` 同根因**
只读复跑（`bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs`，**不改任何件**）：
```
FAIL(probe)  tab-oracle-zero   :: 日志自报探针 sha=a6d0352b86467111 ≠ 现场 build/MilBridge/tests/CoverageProbe/Program.cs=c78ed88fc1fd34f4 ⇒ **日志出自另一版探针**
FAIL(probe)  tab-oracle-anchor :: （同上，逐字）
FAIL(probe)  tab-oracle-rtl    :: （同上，逐字）
TLINE_GATE=FAIL arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same gate=747c078dbf040862
GATE_PROBE=FAIL state=REGRESSED …   GATE_REASON=probe-sha-mismatch      rc=1
```
- **根因（机械、可复算）**：`Program.cs` 在 **`16:03:11`** 被 `B-3①` 改过（去退役根字面量）；而三支臂日志（`10:31:50`／`10:34:12`／`10:34:18`）与探针二进制（`10:31:13`）**都是改前那一代**，`t14` 因**槽被占**没能重取 ⇒ **日志自报 ≠ 现源码** ⇒ 门禁按它自己的规则（`tline-gate.sh:1140-1146`「抽出但 ≠ 现场 ⇒ FAIL：日志出自另一版探针」＋ `known-red.json` `generation.probes.arms` 三支臂都指向该件）判 **FAIL**。
- **不是我引起的**：我**没有**改臂日志（仓内 `arm-logs/*` 一字未动）；我**自己新跑的三份日志与在册逐字节相同**，自报的也是同一个旧 sha ⇒ **换我的日志进 register 也照样 FAIL**（红来自"源码动了、日志没重取"，与日志是哪一份无关）。
- **修法（本件 out of scope，交回队长排期）**：① 用**当前源码**重建探针（`dotnet build -c Release build/MilBridge/tests/CoverageProbe`）② 重取三支臂日志并**硬链接**进 `build/MilBridge/arm-logs/`（保持 `find -maxdepth 1 -type f` 可见 ＋ mtime ≥ 被测件）③ 重跑门禁确认 `GATE_PROBE=PASS`。**本件不许构建、不写登记表、不动 `arm-logs/`** ⇒ 只报不修。

**⇒ 判词（`B-3②`）**：`三支臂读数＝已拿到（真跑、逐字节复现）`｜**`死根面＝NOINFO reason=probe-artifact-stale-vs-source（判法够不着 ＋ 判别器失效 ⇒ 既不算绿也不算红）`**｜**并报出一条现红（门禁 `probe-sha-mismatch`）**。

---

## §4 `B-9` 逐腿机读读数（台账 `~/t20-runner/legs-b9c.tsv` `d0ae3f1976d31139`）

| 腿 | 显示 | `rc` | stderr 原文（**逐字**） | 起应用？ | 装置 |
|---|---|---|---|---|---|
| **`L6t-occ`**（反极 · 真占用） | `:236`（**我起的** `Xvfb`，pid `367229`） | **3** | `DISPLAY_OCCUPIED=:236 sock=/tmp/.X11-unix/X236 ⇒ 拒跑（号已被占；请用 W67_DISPLAY=<空闲号> 或先按 PID 收净）` | **none**（`app_started=none`） | `xdpyinfo` ⇒ `1280x1024`；`[ -S /tmp/.X11-unix/X236 ]` = yes |
| **`L7t-free`**（正极 · 空号） | `:235`（无 socket） | **0** | `DISPLAY_LEASE=free display=:235 sock=/tmp/.X11-unix/X235`（**无** `OCCUPIED` 行） | none（`W67_WORK` 为空目录 ⇒ 未起应用） | `[ -S /tmp/.X11-unix/X235 ]` = no |

- **两个方向都成立**：占用 ⇒ **拒跑（rc=3、响铃到 stderr、不带病起应用）**；空号 ⇒ **放行**。这与 `t14` §5 的**沙箱 `X11` 目录**注入版**逐字同**（同一行文本、同一 `rc=3`）⇒ **"沙箱注入 ≡ 真显示位占用"**（`t14` 的沙箱腿**不是**近似假设，而是等价读数）。
- **收尾（按 PID，禁 `pkill`/`pgrep -f`）**：`TEARDOWN pid=367229 resid=[none]`；现取全机 `/proc/*/cmdline` 里 `Xvfb :23` **零命中**；`:235` 全程无 socket。

**前两次尝试（作废，具名）**：`L6-occ`／`L7-free`（批内，`20:28:55–20:29:09`）与 `L6r-occ`／`L7r-free`（`20:30:19–20:30:23`）**四次调用全部 `rc=127`**，stderr 逐字：
```
bash: /home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/tests/PtsPagesProbe/session_inner.sh: 没有那个文件或目录
```
⇒ **`ENOENT`：被测件在那些时刻不可见**（**不是**文件被改：同一路径在 `20:29:50` 手跑成功、`20:31` 复取仍在，sha16 `a70aeb1d988ebc9e` 与 mtime `16:05` **前后不变**）⇒ 记 **`VOID reason=artifact-transiently-invisible`**（另有写者在动仓；**不改判据**）。第 3 次改为**先断言在位 ＋ 瞬时 ENOENT 有界重试（≤3）** ⇒ 一次成功（`B9_HEAD3 … sess_exists=yes sha16=a70aeb1d988ebc9e bytes=8612`）。**修法建议**：跑重型腿前一律加"件在位"前置断言（本件即此做法）。

---

## §5 分母／作废／跳过（`D-G94` 口径）

| 腿集 | 腿数 | 入分母 | 作废（点名） | 跳过 |
|---|---|---|---|---|
| `B-3②` | 5 | **5** | 0 | 0 |
| `B-9` | 2（第 3 次） | **2** | 前两次尝试共 4 次调用（`L6/L7/L6r/L7r`）＝`rc=127 ENOENT` ⇒ **作废**（不入分母，已具名） | 0 |
| 装置对照 | — | — | — | — |

- `HEAVYSLOT=TIMEOUT`／`NOINFO low-memory`／`MAXHOLD_KILL` **各 0** ⇒ 无一条腿是被槽/内存闸拒的。
- `B-3②` 的 `L1` 的 `rc=1` **不是作废**：它是该臂**自己的判词**（`未登记失败 1`，与在册逐字同）⇒ **入分母**，且**不许**当成"腿失败"。

---

## §6 槽读数与让路时长（逐次，现取自动账）

| 获取 | 命令 | `waited` | `held` | 异常 |
|---|---|---|---|---|
| 1 | `run-legs.sh`（`B-3②` 5 腿 ＋ 第 1 次 `B-9` 2 腿） | `0s`（`avail=7993MB`） | **`492s`** | 无 |
| 2 | `run-b9.sh`（第 2 次，作废） | `0s`（`avail=6875MB`） | `4s` | 无 |
| 3 | `run-b9.sh`（第 3 次，成功） | `0s`（`avail=7048MB`） | `14s` | 无 |

- **实占合计 `510 s`（≈8.5 min）**；**让路 `0 s`**（没让路、也没让别人等）；**批间释放**（每次 `RELEASED`）；**无空持**。
- 资源头（写进日志头，逐次现取）：`avail_mb` `7993→6875→7048`；`swapfree_mb` `1407→1408→1408`；`df_kb` `72,716,836→72,713,192→…`（≫5 GB）；停手线**一次未触**。

---

## §7 件位 sha16（**跑前／跑后各一次**）

| 件 | 跑前 | 跑后 | 判 |
|---|---|---|---|
| `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` | `a70aeb1d988ebc9e` | `a70aeb1d988ebc9e` | **不变** |
| `build/MilBridge/tests/CoverageProbe/Program.cs` | `c78ed88fc1fd34f4` | `c78ed88fc1fd34f4` | **不变** |
| `…/CoverageProbe/bin/Release/PresentationCore.Tests.dll` | `7d8ebb1e987a3b4b` | `7d8ebb1e987a3b4b` | **不变** |
| `build/MilBridge/tools/pkg-src-retiredpath-check.sh` | `e0ab7bd668ffa8a1` | `e0ab7bd668ffa8a1` | **不变** |
| 三支语料（`tab-zero`／`tab-anchor`／`tab-rtl`） | `256007ce706c7d3f`／`0cebc0afd5142fbf`／`a01934a73b7d5655` | 同值 | **不变** |
| `build/MilBridge/tools/tline-gate.sh` | `747c078dbf040862` | 同值 | **不变**（**只读**复跑，未改） |
| `build/MilBridge/arm-logs/{tab-zero,tab-anchor,tab-rtl}.log` | `10:31–10:34` 那一代 | **一字未动** | **不变**（本件只读） |

- **零越域**：`git status --porcelain` 现取**只有**本席两件新建（`?? build/MilBridge/P1-w2-heavy-criteria.md`，报告本件同族）⇒ **未改任何仓内既有件**；未 `git add/commit/push`；未跑 `verify-all`／未构建。

---

## §8 `NOINFO`／作废逐条具名

1. **`B-3②`「死根面判活/死」** ⇒ **`NOINFO reason=probe-artifact-stale-vs-source`**：判法够不着（`:141` 提前 return ⇒ 零签名）＋ 判别器失效（二进制自报 `a6d0352b…` ≠ 现源码 `c78ed88f…` ⇒ env 不被读）＋ 修它要构建（**本件不许**）。
2. **`B-3②`「缺根 ⇒ 响亮失败」** ⇒ **`NOINFO reason=artifact-stale-vs-source`**：该二进制**没有** env 守卫（`L4` 与 `L2` 逐字节同），因此这条腿的**目标物不在场**（源码里有、二进制里没有）。
3. **`B-9` 第 1／2 次尝试** ⇒ **`VOID reason=artifact-transiently-invisible`**（`rc=127` ＋ `ENOENT` 原文；文件前后同在、sha/mtime 不变）⇒ 不入分母。
4. **`B-3②` 「有 WM」「用户现场」** 等**与本件无关**：不适用（未跑、不外推）。
5. **未做**：重建探针／重取 register 臂日志／跑 `verify-all`／改 `known-red.json` 或 `arm-logs/`（**全在写域外**）。

---

## §9 我推翻了 `t14` 哪句话

1. **`t14` §1 判据③ 的判法** ——「**`CoverageProbe` 死根面**需三支臂真跑并断言**臂日志有目标路径签名**」：**判法本身够不着**（`:141` 提前 return ⇒ 三支臂日志**结构性**零签名，本趟实测 0/0 ×3）⇒ 按这条判法，即使把三支臂跑到天荒地老也**只能**得到 `NOINFO`。**正确判法**应是**根敏感性**（或先重建探针再重取）——**本件给出的正是这个更正**。
2. **`t14` §5「`B-9` 真 `:237` 被真 `Xvfb` 占用腿＝`NOINFO`」** ⇒ **消除**：真显示位版**跑成**（§4），且与 `t14` 的**沙箱注入版逐字同**（同一行、同一 `rc=3`）⇒ 沙箱注入腿**等价于**真占用腿（不是近似）。
3. **`t14` §7「槽被占是唯一障碍」** ⇒ **不完整**：槽空之后暴露出**两个新障碍**（三支臂的**判法够不着** ＋ **探针二进制早于源码**），而且后者已经把门禁 `[4]` 步**判红**（§3④）⇒ 「`NOINFO`」当时掩盖了一条**现红**。
4. **`t14` 对 `CoverageProbe` 那句"`used`（三支臂宿主）＋ 常量本身 `unused`"** ⇒ **只能算源码级判断**：现 artifact 下**无法**验证（§3③），而**三支臂路径不消费 `Root`**这一条**有源码级固定证据**（`:141` return／`:158` 是另一方法／字体硬编码）——**我把它降级为"源码结论，非运行读数"**。

---

## §10 自伤（如实，两条）

1. **🔴 我的批件落到了仓根（已修）**：我在 `cd ~/t20-runner && nohup … &` 里把 `&` 作用在**整条 `cd && …`** 上 ⇒ `cd` 只发生在**子壳**里，随后的 `echo $! > batch.pid` 在**调用者 cwd ＝ 仓根**执行 ⇒ 生成 `/home/links-dev/netTest/GitProj/WPFOnLinux/batch.pid`（内容 `264360`），被 `t62` 新立的 `static-jaws-check.sh` 在 `ROOT-ENTRIES` 上**抓成红**（`ROOT_ALLOW_HIT entry=batch.pid source=worktree rule=not-in-allowlist`）。
   **处置（不改白名单）**：把它**移出仓根**到 `~/t20-runner/batch-outer.pid`（内容一字未改；现取 `kill -0 264360` ⇒ **已退出**，批已收工）⇒ 仓根零残留；**复跑牙**：`STATICJAWS=PASS n=31 excluded=31 noinfo=1 n_total=62`（现取）⇒ 该红**已消除**。**口径**：跑批临时件一律**落仓外车道目录**（本件其余进程件均如此）。
2. **`B-9` 首版批脚本没有重试**：两次 `ENOENT` 窗口把 4 次调用直接判成 `rc=127` ⇒ 白花 `4 s` 槽时并多出 2 份作废台账行；第 3 版加**在位前置断言 ＋ 有界重试**后一次成功。**教训**：动仓期间跑腿必须"先断言件在位"。

---

## §11 交付冻结块（机器现算）

```
HEAD（批开跑）＝ 89c7feda9a64c638f02e4fb92dc3e1c53c99874b ｜（报收工时）9cb0858a80b5d60be11c7ed30f933faf8e44bb9e（另有车道在推进）
B-3②（5 腿）：L1 tab-zero rc=1 ｜ L2 tab-anchor rc=0 ｜ L3 tab-rtl rc=0 ｜ L4(noroot) rc=0 ｜ L5(rootnone) rc=0
              三支臂 vs 在册臂日志：cmp IDENTICAL ×3（19182／118027／17418 B 逐字节同）
              签名统计：wpf-linux-20260906 = 0 命中；现树绝对路径 = 0 命中（×3）
              探针自报 = a6d0352b86467111（三支臂日志 ×3 ＋ 本趟 ×5）≠ 现源码 c78ed88fc1fd34f4
B-9（2 腿）：L6t-occ rc=3（DISPLAY_OCCUPIED 原文见 §4）｜L7t-free rc=0（DISPLAY_LEASE=free）
              作废：L6/L7/L6r/L7r 四次调用 rc=127 ENOENT（原文见 §4）
门禁现取：TLINE_GATE=FAIL … GATE_PROBE=FAIL state=REGRESSED GATE_REASON=probe-sha-mismatch（rc=1）
槽：3 次获取，waited=0s ×3，held=492+4+14=510 s；TIMEOUT/NOINFO/MAXHOLD_KILL 各 0
台账 sha16：legs-fixed.tsv 64f1f04eb27c1fd6 ｜legs-b9c.tsv d0ae3f1976d31139 ｜legs-b9.tsv fed4787a991c77e1
            logs/final.txt 180fd8dff4f2f374 ｜logs/batch.log（BATCH_HEAD…BATCH_END 全程）｜logs/b9.log
判据件：build/MilBridge/P1-w2-heavy-criteria.md 4de8b8239a7bbb3b
读取时刻：2026-09-28T20:32:15.757165241 +0800（date '+%F %T.%N %z'）
```

---

## §12 小结（≤6 行）

1. **`B-9` 补齐了**：真 `Xvfb :236` 占用 ⇒ `rc=3` 拒跑（原文在 §4）；空号 `:235` ⇒ `DISPLAY_LEASE=free`；两显示位按 PID 收净。
2. **`B-3②` 三支臂真跑了**（槽 `waited=0s`），三份日志与在册**逐字节相同** ⇒ 在册那条 `NOINFO(heavy-slot 被占)` 的**直接成因消失**。
3. **但「死根面」仍判不出** ⇒ 具名 `NOINFO`：判法够不着（日志结构性零签名）＋ 判别器失效（二进制早于源码，env 不被读）。
4. **顺带查出一条现红**：门禁 `[4]` 步 `GATE_PROBE=FAIL／GATE_REASON=probe-sha-mismatch` —— 三支臂日志/二进制是 `Program.cs` **16:03 改动前**那一代，`t14` 因槽被占没重取 ⇒ **与 `B-3②` 的 `NOINFO` 同根因**；修法＝重建探针＋重取日志（**重活、需槽，交回队长**）。
5. **两处如实自伤**：我误落的仓根 `batch.pid`（已移出、`STATICJAWS` 复跑 `PASS`）；`B-9` 首版无重试被 `ENOENT` 窗口白吃 4 次调用（第 3 版加在位断言后成功）。
6. 全程零越域（仓内只新增本席两件）、零残留进程、槽 `SLOT=FREE`。

**⏪ dated 追加（`2026-09-28T20:33+08:00`）：足迹读数（现取）** —— 本席两件**都不在** `fp_inputs()` 覆盖面：`infp.sh list` 现取 **234** 行，`grep -cF` 命中 `P1-w2-heavy-criteria.md` = **0**、`P1-w2-heavy-legs-report.md` = **0**；`infp.sh fp` 连算两遍同为 **`fe923e2ece011537`**（本席**零影响** ⇒ 不动 `inputs_fp`，故 `--expect`／`verify-all.sh` 未被牵动）；判据件 `build/MilBridge/P1-w2-heavy-criteria.md` = **`4de8b8239a7bbb3b`**（跑前落盘、跑后未改）。仓内 `git status --porcelain` 现取**只有**这两行 `??`。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-w2-heavy-legs-report.md | sha256sum | cut -c1-16`）= `06f7e0501f4a7f8f`
