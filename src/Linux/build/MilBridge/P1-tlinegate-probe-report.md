# P1-tlinegate-probe-report —— 修已接线现红：`GATE_PROBE=FAIL reason=probe-sha-mismatch`（`t67`）

> **车道** `runner`／**任务** `t67`（attempt 1）。**写域** ＝ `build/MilBridge/arm-logs/`／`build/MilBridge/tests/CoverageProbe/`（**只重建、不改源码**）／本件。
> **一句话**：按 `t20` 给的三步修法**自己复现并留痕** —— ①用当前源码**重建探针**（`Program.cs` 一字未动，`c78ed88fc1fd34f4` 前后同值）②**重取三支臂日志**并按**硬链接**放回 `arm-logs/`（旧日志**留档**、逐件给 `sha16` 与去向）③复跑 ⇒ **`GATE_PROBE=PASS state=READINGS-OK`（三支臂全 PASS）**、**`TLINE_GATE=PASS arms=5 red=2 green=3 …`（rc=0）**，**不再出现 `FAIL(probe)` 行**。
> **读取时刻**：全部读数现取于 `2026-09-28T20:52:47–20:57:21 +08:00`，逐格带亚秒 `ts=`。

---

## §1 修前 → 修后（**两行原样输出**，成对）

**修前（`ts=2026-09-28T20:52:47.058917618 +0800`）**：
```
FAIL(probe)      tab-oracle-zero   :: 日志自报探针 sha=a6d0352b86467111 ≠ 现场 build/MilBridge/tests/CoverageProbe/Program.cs=c78ed88fc1fd34f4 ⇒ **日志出自另一版探针**
FAIL(probe)      tab-oracle-anchor :: （同上，逐字）
FAIL(probe)      tab-oracle-rtl    :: （同上，逐字）
TLINE_GATE=FAIL arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=921ba9c65e9fb3be gate=747c078dbf040862
GATE_PROBE=FAIL state=REGRESSED tab-oracle-anchor 自报=a6d0352b86467111 现场=build/MilBridge/tests/CoverageProbe/Program.cs ⇒ FAIL; …
```

**修后（`ts=2026-09-28T20:56:58.969402347 +0800`）**：
```
TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=921ba9c65e9fb3be gate=747c078dbf040862 judge=t1b3-tline-gate/7
GATE_PROBE=PASS state=READINGS-OK tab-oracle-anchor 自报=c78ed88fc1fd34f4 现场=build/MilBridge/tests/CoverageProbe/Program.cs ⇒ PASS; tab-oracle-rtl 自报=c78ed88fc1fd34f4 现场=… ⇒ PASS; tab-oracle-zero 自报=c78ed88fc1fd34f4 现场=… ⇒ PASS
```
**`rc` 成对**：修前单步 `rc=1` → 修后 **`rc=0`**；**`FAIL(probe)` 行数 3 → 0**；`arms=5 red=2 green=3` **未变**（那 2 个 red 是**在册登记红**，不是本次故障）。

---

## §2 探针身份（逐份成对：日志自报 vs 现场源码）

| 日志 | 自报探针 `sha256`（前 16） | 现场 `Program.cs` 现取 | 判 |
|---|---|---|---|
| `tab-zero.log` | `c78ed88fc1fd34f4` | `c78ed88fc1fd34f4` | **一致** |
| `tab-anchor.log` | `c78ed88fc1fd34f4` | `c78ed88fc1fd34f4` | **一致** |
| `tab-rtl.log` | `c78ed88fc1fd34f4` | `c78ed88fc1fd34f4` | **一致** |
| （修前）三份 | `a6d0352b86467111` | `c78ed88fc1fd34f4` | **不一致（红因）** |

**探针产物成对**：`bin/Release/PresentationCore.Tests.dll` `7d8ebb1e987a3b4b`（`mtime 2026-09-28 10:31:13.742133042`）→ **`25c17f4905c9352a`**（`mtime 2026-09-28 20:53:48.336063878`）；**源码 `Program.cs` 前后同值 `c78ed88fc1fd34f4`（未改一个字节）** ⇒ **重建不需要改源码**（契约前置条件满足，未触发"停下报告"）。

---

## §3 硬链接放回（三证：同 inode ／ `find` 可见 ／ `mtime ≥ 被测件`）

```
$ ls -li build/MilBridge/arm-logs/tab-zero.log build/MilBridge/arm-logs/tab-anchor.log build/MilBridge/arm-logs/tab-rtl.log
5772439 -rw-r--r-- 2 links-dev links-dev  19182  9月 28 20:54 build/MilBridge/arm-logs/tab-zero.log
5772441 -rw-r--r-- 2 links-dev links-dev 118027  9月 28 20:56 build/MilBridge/arm-logs/tab-anchor.log
5772443 -rw-r--r-- 2 links-dev links-dev  17418  9月 28 20:56 build/MilBridge/arm-logs/tab-rtl.log
$ ls -li ~/t67-runner/newlogs/*.log        # ← 车道侧源件（同 inode ⇒ 硬链接，不是拷贝）
5772441 … /home/links-dev/t67-runner/newlogs/tab-anchor.log
5772443 … /home/links-dev/t67-runner/newlogs/tab-rtl.log
5772439 … /home/links-dev/t67-runner/newlogs/tab-zero.log
```
| 证 | 读数 |
|---|---|
| **同一 inode** | `tab-zero 5772439`／`tab-anchor 5772441`／`tab-rtl 5772443` —— arm-logs 侧与车道侧**逐件同值**，`links=2` ⇒ **硬链接**（**不是拷贝、也不是符号链接**：拷贝会顶 mtime ⇒ 架空弱配对判据；符号链接会被 `find -maxdepth 1 -type f` 漏掉） |
| **`find` 可见** | `find build/MilBridge/arm-logs -maxdepth 1 -type f -name 'tab-*.log' \| wc -l` ＝ **3** |
| **`mtime ≥ 被测件`** | 被测件（重建后的探针产物）`mtime=1790600028`；三份日志 `1790600060`／`1790600207`／`1790600212` ⇒ **逐件 ≥** |
| **模式守恒（两口径）** | `stat -c %a` ＝ `644` ×3 ／ `git ls-files -s` ＝ `100644` ×3 ⇒ **逐件一致** |

**旧日志去向（**不许静默丢弃**；逐件 `sha16` ＋ 去向）**：
| 件 | 旧 `sha16` | 旧 `mtime` | 去向 |
|---|---|---|---|
| `tab-zero.log` | `9150c3a26a3cb789` | `2026-09-28 10:31:50.999692866` | `~/t67-runner/artifacts/tab-zero.log.old-9150c3a26a3cb789`（现取 sha16 逐位相符） |
| `tab-anchor.log` | `1c43a12dcaa5718a` | `2026-09-28 10:34:12.749051374` | `~/t67-runner/artifacts/tab-anchor.log.old-1c43a12dcaa5718a`（相符） |
| `tab-rtl.log` | `92570318851ca7e8` | `2026-09-28 10:34:18.005901850` | `~/t67-runner/artifacts/tab-rtl.log.old-92570318851ca7e8`（相符） |
（车道侧另有本轮新件的独立副本 `~/t67-runner/artifacts/<arm>.log`，`sha16` 与 arm-logs 侧同值。）

---

## §4 重取日志 vs 在册旧日志：**逐份差异（不许当噪声）**

| 臂 | 新 `sha16` | 旧 `sha16` | `cmp` | **差异逐条** | 归因 |
|---|---|---|---|---|---|
| `tab-zero` | `b5239c4e5b95fa56` | `9150c3a26a3cb789` | **DIFF** | **只有第 1 行**：`TAB_LINES_PROBE sha256=a6d0352b… → c78ed88f…`（其余 `TAB_LINES` 行**逐字节相同**；文件大小同为 `19,182 B`） | 探针换代（`B-3①` 去死根）⇒ **自报行必变**；测量行为**未变** |
| `tab-anchor` | `2e62d68ed5edd5e7` | `1c43a12dcaa5718a` | **DIFF** | 同上：**只有第 1 行**自报 sha 变（`118,027 B` **同大小**） | 同上 |
| `tab-rtl` | `70feb4b5d4ab80f7` | `92570318851ca7e8` | **DIFF** | 同上：**只有第 1 行**自报 sha 变（`17,418 B` **同大小**） | 同上 |
**逐份复核命令（可重放）**：`diff <(grep -a '^TAB_LINES' <旧留档>) <(grep -a '^TAB_LINES' build/MilBridge/arm-logs/<臂>.log)` ⇒ **三份都只输出自报那一行** ⇒ **除"探针身份"外，三支臂的读数与修前逐字节相同**（＝**确定性**，且**证明 `B-3①` 的改动对这三支臂的测量行为零影响** —— 与 `t20` 的静态判断（该路径不消费 `Root`）**一致**）。

---

## §5 资源纪律（走槽 ＋ 后台；显示位独占；批末释放）

| 项 | 读数 |
|---|---|
| 槽（本批一次获取；`dotnet build` ＋ 三支臂同批） | `HEAVYSLOT=ACQUIRED waited=0s`（`--min-avail 2500 --max-hold 1800 --wait 1800`）→ **`RELEASED rc=0`** |
| 跑前现取（`ts=2026-09-28T20:52:58.239842909`） | `free -m`：`total=11471 used=4863 free=224 buff/cache=6383` **`available=6298`**；`df -Pk ~`：`72701320 KB` 可用（≫5 GB）；批内头行：`avail_mb=5760 swapfree_mb=1408 df_kb=72700828` |
| 异常 | `HEAVYSLOT=TIMEOUT`／`NOINFO low-memory`／`MAXHOLD_KILL` **各 0** |
| 显示位 | **本任务未起任何显示位**（`dotnet build` 与三支臂探针**都不需要 X**；探针自足、不起应用）⇒ "显示位独占"**平凡满足**；收尾复扫 `/proc` 无 `Xvfb :23x` 残留 |
| 进程 | 只按 PID；未用 `pkill`／`killall`／`pgrep -f` |

---

## §6 不越域自证

- **`src/**` 一字未动**：`Program.cs` `c78ed88fc1fd34f4`（前后同值）；`git status --porcelain` 里 `src/**` 的 `M` 条目**全部**是 `t63` 那一趟的（`win32_pts.c`／`win32_classification.c`／`pts-gap-decl.txt`），**本席本趟对其零写入**。
- **`build/*.Linux/**` 一字未动**：`CoverageProbe.csproj` 用具名 `HintPath`＋`Private=true` 引产品件（**拷贝，不重建**）⇒ 九位逐位复核：`wpfgfx_cor3.so=4e25e4b27d4d5ae1 / pc=5b6cfda3e12b84fc / pf=b9a4f3a0e48e688d / windowsbase=9e860cbeecb352e1 / provider=7e8a217b4165a6b9 / win32shim=2a5165700a8c8579 / wic_shim=f7b3026c8c019be2 / hbtextline=921ba9c65e9fb3be / dwf=c83be96f18759edc` ⇒ 与 `t63` 交件时**逐位相同**（含 `win32shim`）。
- **本席本趟写入的件（只有 4 类）**：`build/MilBridge/arm-logs/tab-{zero,anchor,rtl}.log`（硬链接换代）＋ `build/MilBridge/tests/CoverageProbe/bin|obj/**`（构建产物）＋ 本报告。`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`declared.tsv`／`verify-all.sh`／`close-wave.sh`／两枚哨兵：**本趟未写**（porcelain 里的 `M` 是 `t63`／别的车道的）。
- **未跑整趟门禁**：只跑了**该步的单步命令** `tline-gate.sh --logdir build/MilBridge/arm-logs`（`t20` 给的复跑方式；纯读、不写 `$R`）。
- ⚠️ **同刻有别的写者在动仓（如实记）**：porcelain 现取显示 `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` 与 `run-pts-pages-legs.sh` 为 `M`（`D-G188` 的 `t68`／scribe 正在改），另有 `?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/{device/,session.txt}` —— **均非本席写入**。

---

## §7 足迹成对（`inputs_fp`／覆盖面）

| 格 | 值 | 归因 |
|---|---|---|
| `inputs_fp` | `37b6131378bccb68`（`t63` 收口时） → **`0a4fd053d0a95b9e`**（`ts=2026-09-28T20:57:2x`） | ⚠️ **不是本席引起**：本席本趟写入的件**逐件 `inFP=0`**（`arm-logs/tab-*.log` ×3、`CoverageProbe/Program.cs`、探针产物 —— 现取 `grep -cF` 全 0）；位移来自**同期别的写者**改了**覆盖面内**的 `PtsPagesProbe/session_inner.sh`／`run-pts-pages-legs.sh`（porcelain 现取可见）⇒ **`HANDOFF-MV` 的 `cell=#1` 需由那一趟按第 `28` 条追写**（本席 `t67` 写域不含 `HANDOFF-NEXT.md`） |
| 覆盖面件数 | **234**（未变） | `--expect 234` 不动 |

---

## §8 `NOINFO`／未做／边界

1. **未跑整趟门禁**（契约第 7 条允许范围内）：只跑该步单步命令；`TLINE_GATE=PASS` 是**该步单步**读数，**不等于**整趟门禁绿。
2. **`arms=5 red=2`**：那两个 red 是**在册登记红**（`registered=4`／`unlocated=1`），**与本故障无关**；本任务**不**借此改登记表（不在写域）。
3. **旧日志留档在车道**（`~/t67-runner/artifacts/**`），**未**留在仓内为 `.old-*` 副本 ⇒ 若后人要仓内可复现"换代前的自报 sha"，需从车道取（去向已给 §3）。
4. **本席未复核** `t20` 报告的历史读数在其各自写入时刻是否为真（只作对照；本件全部读数**自取自算**）。

---

## §9 我推翻了哪句话

1. **`t20` 的判词"把新日志换进去照样 `FAIL`"** —— 成立，但**只对"不重建探针"成立**：本件证明**重建后**换日志即**真绿**（自报 sha 与现场源码一致）⇒ **修法的关键顺序是"先重建、后重取"**，缺任一步都仍是红。
2. **"三支臂日志换代后读数会变"这个隐含担心** —— **证伪**：三份日志除**自报那一行**外与旧日志**逐字节相同**（同大小、`diff` 只出 1 行）⇒ 探针换代**只改身份、不改测量行为**（与 `t20` 的静态判断一致）。
3. **"硬链接只是为了省空间"这个读法** —— 更正：`arm-logs` 用硬链接是**判据需要**（文件 mtime 必须 `≥` 被测件；拷贝会把 mtime 顶到当下 ⇒ 架空弱配对判据），本件把它做成**三证机读**（同 inode／`find` 可见／mtime ≥）。

---

## §10 交件清单（每格带亚秒 `ts=`）

```
修前门禁      ts=2026-09-28T20:52:47.058917618 +0800  GATE_PROBE=FAIL state=REGRESSED reason=probe-sha-mismatch  TLINE_GATE=FAIL  rc=1
跑前资源      ts=2026-09-28T20:52:58.239842909 +0800  available=6298MB  df_kb=72701320
批头          ts=2026-09-28T20:53:45.843829117 +0800  repo_HEAD=c0e381e6eeac5d406512d68442addc09f8b2d54e  avail_mb=5760 swapfree_mb=1408
重建探针      ts=2026-09-28T20:53:48.336063878 +0800  BUILD_RC=0；dll 7d8ebb1e987a3b4b → 25c17f4905c9352a；Program.cs c78ed88fc1fd34f4（未动）
重取三支臂    ts=2026-09-28T20:54:20.678260650 / 20:56:47.033120031 / 20:56:52.324150254
              tab-zero   rc=1 19,182 B  b5239c4e5b95fa56  自报 c78ed88fc1fd34f4
              tab-anchor rc=0 118,027 B 2e62d68ed5edd5e7  自报 c78ed88fc1fd34f4
              tab-rtl    rc=0 17,418 B  70feb4b5d4ab80f7  自报 c78ed88fc1fd34f4
硬链接放回    arm-logs inode 5772439 / 5772441 / 5772443（与车道源件同 inode，links=2）mode 644（git 100644）mtime ≥ 被测件
修后门禁      ts=2026-09-28T20:56:58.969402347 +0800  GATE_PROBE=PASS state=READINGS-OK  TLINE_GATE=PASS arms=5 red=2 green=3  rc=0
足迹          ts=2026-09-28T20:57:21.319876742 +0800  inputs_fp=0a4fd053d0a95b9e（非本席引起，§7）覆盖面=234（未变）
槽            HEAVYSLOT=ACQUIRED waited=0s（min-avail 2500 / max-hold 1800 / wait 1800）→ RELEASED rc=0；异常 0
```

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tlinegate-probe-report.md | sha256sum | cut -c1-16`）= `49f46e36701749ad`
