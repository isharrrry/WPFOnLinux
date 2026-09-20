# W24D 报告 —— `D-G8` 修法（`scan()` 的 rc 被丢弃）+ `D-A2` 残余设计（`wpfgfx_cor3.so`）

lane = **W24D**｜2026-09-17 09:30:53 → 09:47 +0800｜kernel 6.8.0-138-generic｜`nproc=3`｜`MemAvailable` 3,404,548 → ~3.6 GB
**硬约束遵守**：全程**零 `dotnet`**（build/run/restore/msbuild 都没有）、**零 `verify-all`**、**未 `pkill -f`**；只读文件 + `grep` + `sha256sum` + `find` + `python3` + 跑**我改的那个检查器**（含 `--selftest`）。
**写域**：只写本报告 + 只改 `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`（改前 `cp -p` 备份到 `$HOME/w24d-lane/backup/`）。临时件全在 `$HOME/w24d-lane/`。
**纪律 49（不许手抄哈希）**：本报告所有 sha16 都是脚本现场算的，没有一个是手抄的。

## 0 · 现场基线复算（脚本算，不手抄）

| 位 | 现场读数 | `#23` 冻结基线 | 一致? |
|---|---|---|---|
| `pc` | `7b47a7b3d69ad62f`（`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`，4,197,376 B） | `7b47a7b3d69ad62f` | ✅ |
| `hbtextline` shim | `e89fed55fd8e32bc`（`build/shims/PresentationCore.HbTextLine.cs`） | `e89fed55fd8e32bc` | ✅ |
| `bridge`（= publish 的 `wpfgfx_cor3.so`） | `d567c26f197ec1e3`（4,987,840 B） | `d567c26f197ec1e3` | ✅ |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8`（记录文件里读出的） | `b6acdba4f01599d8` | ✅ |

`pc` 在**每一趟读数前后各取一次**（纪律 35）：09:33:12/09:33:26 = `7b47a7b3d69ad62f`／09:38:20/09:38:31 = `7b47a7b3d69ad62f` ⇒ **本件读数期间 `pc` 没变过**，无"两次读数配两个 pc"的歧义。
本波另有两条车道在跑构建（09:31 实测两个 `dotnet` 进程：`FrameProbe` 与 `PresentationCore.Tests`），它们的写域是 `build/MilBridge/tests/{FrameProbe,CoverageProbe}/**` 与 `build/MilBridge/tools/frame-step.sh`（`find -newermt` 实测）——**与我改的文件无交集**。

---

# 件 1 · `D-G8`：`scan()` 的 `rc` 被丢弃

## ① `scanrc` 的复核（行号 + `grep -c`）

```
$ grep -n "scanrc" build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh     # 改前
654:scan; scanrc=$?
$ grep -c scanrc build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh      # 改前
1
```

**结构性说明（为什么这一定是洞、不是"冗余赋值"）**：脚本的退出码**不是** `scan` 的 rc，而是**从五个计数器重新算出来的**：

* `scan()` 内部 `rc=1` 的位置（改前）：`:212`（权威件缺失）、`:270`（UNEXPECTED）、`:285`/`:289`（STALE/NEWER-DIFF）、`:328`（MISSING）、`:362`（DIVERGENT）、`:370`（RETIRED）；`rc=3` 在 `:302`（期望集合算不出来）。
* 文件尾 `:704` 的判定只看 `CNT_MISMATCH / CNT_RETIRED / CNT_DIVERGENT / CNT_MISSING / CNT_UNEXPECTED`。
* ⇒ **"权威件整份不见"（`:212`）是唯一一条"只置 rc、一个计数器都不动"的失败路径**（`MISSING` 数的是**期望副本**缺席，不是权威缺席；`UNEXPECTED` 只在 `EXPECT_OK=1 && is_managed && !in_expect` 时计）⇒ 五个计数器可以全为 0 ⇒ `APPSYNC=PASS` + `exit 0`。

**这条不是纸面推断，下面是实测（"骗人"复现，与②的改动无关）**：

* 私有沙箱（`$HOME/w24d-lane/polar/`，`AUTH_ROOT`=沙箱权威根，六件权威各一份**真件的副本**，`SCAN_ROOTS`=沙箱宿主目录，宿主里一个全绿副本）。
* **改前脚本**（`$HOME/w24d-lane/prefix-sim/check-applocal-sync.sh` = 备份的 `013df358c0bed2a3`，旁边放一份 `applocal-expect.py`）+ 把沙箱里 `ReachFramework.dll` 的权威**移走**：

```
计数：OK=2  MISMATCH=0 … UNEXPECTED=0[DECL-GAP-EQ=0 DECL-GAP-DIFF=0]  DIVERGENT=0 …
APPSYNC=PASS（所有副本与权威件一致）
rc = 0
（上一行输出里确实有 `⚠ 权威件缺失：…/ReachFramework.dll` —— 印了，但**退出码不认**）
```

⇒ **权威整份不见 ⇒ 仍然 `APPSYNC=PASS` + `rc=0`**：`D-G8` 不是一个"更保守会更红"的担忧，是一条**已经能发生的假绿**。
（为什么 `ReachFramework.dll`：该沙箱里它**没有任何副本** ⇒ 权威消失后**一个计数器都不会动** —— 这正是要证明的那一点。日志 `polar-P2-pre-missing.log` sha16 `448f2a0bd5e3fba2`。）

**影响面（顺带查到的，两处，都不许夸大）**：

1. `sync-applocal-authority.sh:72` 消费了 `chk_rc`（`out="$(AUTH_ROOT=… SCAN_ROOTS=… bash "$CHECK" 2>&1)"; chk_rc=$?`），但**只打印**（`:155` `校验器：刷新前 exit=…`），它的 `fail` 只来自**自己的刷新动作**（`:97`/`:98`/`:103`/`:110`/`:133`）⇒ 修复前那条假绿在该脚本里同样是假绿。
2. 但**真件路径上它的咬合力有限**：对"有副本可比"的件，权威消失会让那些副本转 `MISMATCH`（EXPECT 变 `<missing>`）⇒ 顺带红。**只有在"本件没有任何 ⑥ 行"或"扫描根被收窄"时才真正静默**。逐件普查（`03-after-real.log`，脚本算）：

| 件 | 副本判定行分类计数 | ⑥ 真判行数 | 权威整份不见会被计数器看见? |
|---|---|---|---|
| `libwpfwic.so` | OK=3 | 3 | 会 |
| `libwpfwin32.so` | OK=4 | 4 | 会 |
| `DirectWrite.Linux.Provider.dll` | NO-AUTHORITY=20, OK=22, SKIP(obj)=2, SKIP(ref)=1, SKIP(stub)=2 | 22 | 会 |
| `WpfGfx.Linux.dll` | NO-AUTHORITY=5, OK=8, SKIP(obj)=3, SKIP(ref)=1, STALE=1, UNEXPECTED-EQ=1 | 9 | 会 |
| `ReachFramework.dll` | NO-AUTHORITY=1, OK=8, SKIP(obj)=1, SKIP(stub)=2 | 8 | 会 |
| `PresentationCore.dll` | NO-AUTHORITY=13, OK=18, SKIP(obj)=1, SKIP(stub)=2 | 18 | 会 |
| `libole32.dll.so`（退役别名） | OK=1 | 1 | 会 |

⇒ **今天全仓树上每一件都至少有一份 ⑥ 副本**，所以"权威消失"在**全仓扫描**里会顺带红；真正的静默面是**收窄扫描根**（`--selftest` 沙箱、`sync-applocal-authority.sh` 自带的 `SCAN_ROOTS`、任何 ROI 局部扫描）——`sync-applocal-authority.sh:59` 的默认根里**连 `$REPO/tools` 都没有**（W23C 补的那一条没同步过去，**另一件欠账**，见 §⑧）。这条更正很重要：`D-G8` 的价值**不是**"今天全仓都在骗人"，而是"**门禁的退出码不是它自己以为的那个函数**"。

## ② 改动逐处 + before/after sha16

| | 文件 | 大小 | sha16 |
|---|---|---|---|
| before（= W23C 版，`#23` 现场） | `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | 62,955 B / 710 行 | `013df358c0bed2a3` |
| **after（最终版）** | 同上 | 71,502 B / 778 行 | **`fc4c249851fa1d71`** |

> **纪律 35 自曝（版本与读数的对应）**：中途有过一版 `c11578a5a1ede01d`（内容只差**两行注释**里对"改前行号"的标注）。**本条报告里的全部读数都是在最终版 `fc4c249851fa1d71` 上重取的一遍**；重取后沙箱三趟（P3/P4/P5）与 farm 三趟（F1/F2/F3）的日志 sha16 **与上一版逐位相同**（`ea596c0964f82507` / `d69bdb4991545385` / `ea596c0964f82507` / `2907e42a09e067fa` / `50171a94594469f7` / `2907e42a09e067fa`）⇒ 注释版差异**零行为影响**（这也是"输出是判据"的一个副证）。
> `--selftest` 的日志 sha16 **每次跑都不同**（`2ebb2f83a29d2120` → `1514893a69abdc95`）：因为自检 O 的 PASS 行里会打印 `mktemp -d` 生成的**每趟不同的沙箱路径**——这是我在报告里显式登记的"日志不可逐字节复现"的一处（其余日志都可复现）。

`cp -p` 备份：`$HOME/w24d-lane/backup/check-applocal-sync.sh.before`（sha16 `013df358c0bed2a3`，与 before 逐位相同）。
`diff` 总量：**+76 行 / −8 行**；**8 行删除全部是"被就地改写的既有行"**（文件头口径 2 行、selftest 清单 1 行、`:212` 1 行、E 的判定条件 2 行、计数格 1 行、最终 `APPSYNC=` 行 1 行）——没有任何一行被"顺手删掉"。

逐处（改后行号）：

| # | 位置 | 改法 | 为什么 |
|---|---|---|---|
| 1 | 文件头 `:31-35`（判定口径） | 新增第 11 类 **`AUTH-MISSING`**；总判定式补上它，并补一句"`scan()` 内部 rc≠0 而计数器全 0 ⇒ 也 MISMATCH" | 口径必须与代码同趟改；否则下一个人读文件头会以为"权威缺失"仍是提示 |
| 2 | 文件头 selftest 清单 `:77-80` | E 补"沙箱六件权威俱全（`AUTH-MISSING=0`）"；新增 O 一行 | 自检清单 = 可信性声明，必须自洽 |
| 3 | `:122-131`（计数器声明区） | 新增 `CNT_AUTHMISS=0`（含来历注释） | 让这类失败**具名**（可点数、可点数对账），不是只留一句 rc |
| 4 | `:226`（原 `:212`） | `[ -f "$exp" ] \|\| { CNT_AUTHMISS=…; rc=1; printf '    AUTH-MISSING  %-76s ⚠ 权威件缺失：%s …' …; }` | **保留**原来的 `⚠ 权威件缺失：` 字样（既有文档/别的车道可能 grep 它），前面加**可点数标签**；`rc=1` 原样保留 |
| 5 | `:715` 后 | 新增一行 `printf 'scan() 内部 rc=%s（本值现在**参与**最终判定…）'` | 让"被消费"这件事**在输出里可见**（否则读者无法判断这趟退出码是哪条路来的） |
| 6 | 计数格（`:720`） | 末尾追加 `  AUTH-MISSING=$CNT_AUTHMISS` | 与既有 `UNEXPECTED=…[DECL-GAP-EQ=…]` 一样：**只追加、不改既有字段位置**（既有 grep/`awk` 消费者不受影响） |
| 7 | 最终判定（`:768-773`） | ① `AUTH-MISSING` 进 MISMATCH 条件并把 `AUTH-MISSING=$CNT_AUTHMISS` 印进 `APPSYNC=MISMATCH(…)`；② **新增一条 `elif [ "$scanrc" != 0 ]`** 兜底：`rc≠0` 而具名计数器全 0 ⇒ `APPSYNC=MISMATCH` + `exit 1` | ①是具名的那一类；②是**结构性**收口：将来再有人写一条"只置 rc 的失败路径"，也不可能被吞掉 |
| 8 | `:482-512`（自检 E） | 沙箱 `authB` 里补上 `ReachFramework.dll` 与 `PresentationCore.dll` 的权威（两份真件副本），并在 E 的判定里加 **两趟都必须 `AUTH-MISSING=0`** | **必须同趟改**：E 的 `AUTH_ROOT` 是沙箱，六件权威原来只有 4 件 ⇒ 一旦 rc 被消费，E 会**立刻假红**；同时"绿"的含义变强了（不是靠"权威缺少"换来的绿） |
| 9 | `:669-709`（新增自检 **O**） | `D-G8` 的永久反极性（三趟，见 ③） | 让"权威整份不见 ⇒ rc≠0"**永久可复算**，而不是只留在本报告里 |

**一个字都没动的**（防"放宽变瞎"）：`NO-AUTHORITY`（④）/ `LIB-COPY`（⑤）/ `SKIP(obj)`（③）/ `SKIP(stub)`（②）/ `SKIP(ref)`（①）五个既有分支的**条件文字与顺序**、`CNT_OK/MISMATCH/STALE/NEWER/NOAUTH/SKIPOBJ/SKIPSTUB/SKIPREF/MISSING/UNEXPECTED/DECLGAP_*/DIVERGENT/RETIRED` 十四个既有计数器、`RETIRED` 表、`is_release_path/is_debug_auth/is_managed/is_obj/is_stub/is_host_dir/is_refdir` 七个谓词、`--list-items` 模式、`show_registry()`（W23C 的 13 份在册红段落，**只读只打印**）。
**另一件没动的**：`build/MilBridge/known-red.json`（sha16 `e623d2b17d948e3b`，mtime 2026-09-17 00:38:33，早于我开工的 09:30）——那是五臂门禁的登记表，与本检查器不是同一份。
**空权威 ≠ 缺权威**（关键区分）：`wpfgfx_cor3.so` 的权威串**按设计为空**（`:116` 显式"不覆盖"）⇒ `[ -z "$exp" ] && continue`（`:225`）在 `AUTH-MISSING` **之前**⇒ 它**不会**假红。实测：真实全仓树 `AUTH-MISSING=0`。

## ③ 两极化实测（四组、11 趟留档：P1–P5 沙箱 5 趟 ＋ F1–F3 farm 3 趟 ＋ R0/R0′/R1 真仓 3 趟；另有自检 O 内 3 趟与件 2 的 6 趟私有预演）

**先说一条如实声明（这是我与任务书默认预期不同的地方）**：任务书写"删权威 ⇒ rc≠0；恢复 ⇒ rc=0"。但**真实全仓树的基线 rc 本来就是 1**（`MISMATCH=1`（`tools/…/WpfGfx.Linux.dll` STALE）+ `UNEXPECTED=1`（`FallbackCriteria/bin/Debug/WpfGfx.Linux.dll`，`DECL-GAP-EQ`）+ `DIVERGENT=1`），**0↔1 的位移在真件上不可观测**；而且移走一份**真件**权威会与另两条在跑的构建争用（`HintPath` 拷贝的源消失可能直接打红别人的构建）⇒ **我故意没有移真件**，改用三种**命令形态相同**的等价实测（私有沙箱／私有权威副本＋**真实扫描根**／真实全仓树读数）。这条按纪律如实登记，见 §⑧ 未测清单。

### 第一组：私有沙箱（改前 vs 改后，**同一输入、同一命令形态**）—— 这是 0↔1 的唯一干净证据

沙箱：`$HOME/w24d-lane/polar/auth`（六件权威，各为真件的副本）+ `$HOME/w24d-lane/polar/host`（`App/bin/Debug` 宿主 + `HintPath` 解析源 + 一个全绿副本）。
命令形态（五趟逐字相同，只换被跑的那份脚本）：`SCAN_ROOTS=<host> HINTPATH_ROOTS=<host> AUTH_ROOT=<auth> bash <脚本>`。

| 极 | 脚本 | 权威状态 | rc | 计数格（关键位） | 判定行 | 日志 sha16 |
|---|---|---|---|---|---|---|
| P1 | **改前** `013df358c0bed2a3` | 六件俱全 | 0 | 全 0 | `APPSYNC=PASS` | `cfbda6fe671650f6` |
| P2 | **改前** | `ReachFramework.dll` 权威**移走** | **0** | 全 0 | `APPSYNC=PASS` ⚠️ → **洞** | `448f2a0bd5e3fba2` |
| P3 | **改后** `fc4c249851fa1d71` | 六件俱全 | 0 | `AUTH-MISSING=0` | `APPSYNC=PASS` | `ea596c0964f82507` |
| P4 | **改后** | 同一件权威**移走** | **1** | `AUTH-MISSING=1`，**其余计数器与 P3 逐字相同** | `APPSYNC=MISMATCH(… AUTH-MISSING=1 …)` | `d69bdb4991545385` |
| P5 | **改后** | `cp -p` 整份还原（mtime 逐位保持：`2026-09-17 09:37:09.743954552 +0800`、sha16 `27a776477031860c`） | 0 | `AUTH-MISSING=0` | `APPSYNC=PASS` | `ea596c0964f82507` |

* **P3 vs P5：全文 `cmp` 逐字节相同** ⇒ 还原是精确的（不是"看起来一样"）。
* **先说一处我自己的口径位移（如实登记）**：P1/P2 跑的是 `$HOME/w24d-lane/prefix-sim/` 里的旧脚本副本，那个目录**没有** `known-red-PC-copies.md` ⇒ 旧脚本那两趟**没有"在册红"段落**；P3–P5 跑的是真脚本 ⇒ 多 17 行（沙箱 `REPO` 下那 13 条路径不存在 ⇒ 全报"缺件"）。⇒ 逐字比较必须**剔掉该段落**（下面所有 diff 数字都已剔）。
* **P1 vs P3（剔段落后）**：只剩 **2 处真位移** —— 新增的 `scan() 内部 rc=0` 行、计数格尾部新增字段；另 1 行是 `applocal-expect.py` 的**路径字样**（旧脚本副本住另一个目录，纯排版）。**没有任何既有判据行变化。**
* **P2 vs P4（剔段落后）**：5 处 —— ① `⚠ 权威件缺失：…` 那行前面**多了可点数标签**（同一行改写）；② 新增 `scan() 内部 rc=1` 行；③ 计数格尾部字段；④ `APPSYNC=PASS` → `APPSYNC=MISMATCH(… AUTH-MISSING=1 …)`；⑤ 上面那条 python 路径排版。**判据行（每一项的 `OK/STALE/…/DIVERGENT/MISSING` 行）一处没动。**
* **"红只来自新信号"有永久断言**：自检 O 里的 `oCnt()` 把 `AUTH-MISSING=[0-9]*` 剔掉后，要求 P3/P4 那一对沙箱的计数格**逐字相同**（实测 PASS）。
* P2 的 `APPSYNC=PASS` 与 P4 的 `APPSYNC=MISMATCH` 是**同一沙箱、同一状态、同一命令形态**，唯一差别是脚本版本 ⇒ `D-G8` 的存在与修复**都被实测**。

### 第二组：私有权威副本 + **真实全部扫描根**（`farm`）

`AUTH_ROOT=$HOME/w24d-lane/farm`（六件权威的真件副本，路径结构与仓库一致）；`SCAN_ROOTS=$R/build:$R/tests:$R/samples:$R/src:$R/tools`（**真实的五个根** ⇒ 枚举到的是**真仓的副本**）；`HINTPATH_ROOTS=$R`。

| 极 | 权威状态 | rc | `AUTH-MISSING` | 其它计数 | 日志 sha16 |
|---|---|---|---|---|---|
| F1 | 六件俱全 | 1 | 0 | `MISMATCH=1`(STALE=1) `UNEXPECTED=2` `DIVERGENT=1` `OK=54` `LIB-COPY=8` | `2907e42a09e067fa` |
| F2 | farm 的 `libwpfwic.so` 移走 | 1 | **1** | `MISMATCH 1→4`（**真仓那 3 份 `libwpfwic.so` 副本**转 `NEWER-DIFF`）、`OK 54→51` | `50171a94594469f7` |
| F3 | `cp -p` 还原 | 1 | 0 | 与 F1 **逐字节相同**（`cmp`） | `2907e42a09e067fa` |

**如实标注 F1 的口径位移**（这条很重要，别当"真仓读数"用）：`AUTH_ROOT` 换成 farm 后 `REPO` 也变了 ⇒ **期望模型/解析源集合由 farm 算**（farm 里没有 `.csproj`）⇒ `LIB-COPY 0→8`、`UNEXPECTED 1→2`、`OK 63→54`。但 **F1↔F2 的差**是干净的：扫描根、副本、`HINTPATH_ROOTS` 全是真的，**唯一的变量就是那一份权威在不在**。
⇒ 结论：**真仓的副本确实会因"权威整份不见"而拿到新信号 + 顺带转红**（3 份 `libwpfwic.so`）。

### 第三组：真实全仓树（改前 / 改后各一趟）

| 极 | 命令 | rc | 现场 | 日志 sha16 |
|---|---|---|---|---|
| R0（**改前**，相对路径调用） | `bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | 1 | `OK=63 MISMATCH=1(STALE=1) MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=1 NO-AUTHORITY=39 LIB-COPY=0 SKIP(obj)=7 SKIP(stub)=6 SKIP(ref)=10 RETIRED=0` | `98e5192bacb1b6bf`（13.56 s / 14,412 kB） |
| **R0′（改前脚本副本 + 与 R1 同一命令形态/同一 AUTH_ROOT/SCAN_ROOTS/HINTPATH_ROOTS）** | `AUTH_ROOT=$R SCAN_ROOTS=<真实五根> HINTPATH_ROOTS=$R bash <旧脚本绝对路径>` | 1 | 与 R1 **逐位相同的计数格**（除新增字段） | `aa1b52004ebe116a` |
| R1（**改后**） | 同上形态（绝对路径 + 显式三根） | 1 | 同上 **+ `AUTH-MISSING=0`** | `03d489718c1ee17a`（10.83 s / 14,056 kB） |

**R0′ vs R1（同一时刻、同一仓库状态、同一命令形态、只差脚本版本；剔掉"在册红"段落†、并把 `applocal-expect.py` 的路径字样归一化）**：`diff` = **5 行 / 3 处**，全部是我新加的东西 —— ① 新增 `scan() 内部 rc=1` 行；② 计数格尾部 `AUTH-MISSING=0`；③ `APPSYNC=` 行尾部 `AUTH-MISSING=0`。**每一项的判据行、每一个既有计数器逐位相同**（`OK=63`、`MISMATCH=1(STALE=1)`、`MISSING=0`、`UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]`、`DIVERGENT=1`、`NO-AUTHORITY=39`、`LIB-COPY=0`、`SKIP(obj/stub/ref)=7/6/10`、`RETIRED=0`）⇒ **真仓上零位移、零新红**、`rc` 仍 1。
† R0′ 跑的是旧脚本副本（住在 `$HOME/w24d-lane/prefix-sim/`，那里没有登记文件）⇒ 它没有"在册红"段落；归一化说明见 ③-第一组的同类说明。

> **一处外部变动（如实登记，不是我的改动）**：09:33→09:42 之间**另一条车道**改了 `build/MilBridge/tools/frame-step.sh`，使"看不见的拷贝点"从 **只读 29 处 → 31 处**并多印 2 行（`[只读] …frame-step.sh:72/73`）。这也是我为什么要**在同一时刻重取一趟改前脚本**（R0′）来做逐行比较——否则会把"别人的改动"读成"我的位移"。

### 第四组：`--selftest` 里的永久反极性（自检 O）

`:669-709`。三趟同形态：`oRun(){ SCAN_ROOTS=$tmp/hostO HINTPATH_ROOTS=$tmp/hostO AUTH_ROOT=$tmp/authO "$0"; }`
① 六件权威俱全 ⇒ `rc=0`/`PASS`/`AUTH-MISSING=0`；② `mv` 走 `authO/…/ReachFramework.dll` ⇒ `rc≠0`/`AUTH-MISSING=1`/点名行含 `权威件缺失`/`APPSYNC=MISMATCH`，且 **`oCnt()`（剔掉新字段后的计数格）与①逐字相同**；③ `cp -p` 还原 ⇒ `rc=0`/`PASS`/`AUTH-MISSING=0`。
实测输出（`02-selftest-after.log`）：

```
SELFTEST_O=PASS（权威俱全 exit=0 绿；移走一份权威 exit=1 红[AUTH-MISSING=1]；cp -p 还原 exit=0 绿；判定计数器两趟逐字相同 ⇒ 红只来自该新信号）
    AUTH-MISSING  ReachFramework.dll  ⚠ 权威件缺失：/tmp/tmp.…/authO/build/ReachFramework.Linux/bin/Debug/ReachFramework.dll ⇒ …
```

## ④ `--selftest` 的完整读数（rc + 项数 + PASS/FAIL）

| | rc | 项数 | PASS | FAIL | 日志 sha16 |
|---|---|---|---|---|---|
| 改前 | **0** | **16** | A,B,C,D,E,F,G,H,I,J,K,L,L2,N,M,M2 | 0 | `115bae2c8bed598b`（73.57 s / 14,540 kB） |
| **改后** | **0** | **17** | 同上 **+ O** | **0** | `1514893a69abdc95`（58.75 s / 14,544 kB；⚠ 本日志含每趟不同的 `mktemp -d` 路径 ⇒ **不可逐字节复现**，其余日志都可复现） |

**项数 16→17 的逐条说明**：新增 **O**（`D-G8` 的永久反极性）；其余 16 项**一项没删、一项没放宽**，其中 **E 被同趟加固**（沙箱六件权威 + 两趟断言 `AUTH-MISSING=0`）——若不改 E，"消费 rc"会让 E 因为沙箱**本来就没有** `ReachFramework`/`PC` 权威而**立刻假红**，这正是任务书要求"两件必须一起改"的原因（实测：改前 E 的沙箱只造了 4 件权威）。
`--list-items`（只读模式）也应声复核：基线 `rc=0`、末行 `ITEMS_SYNC=YES（两张权威表的件名与权威路径逐项一致）`（`04-list-items.log` sha16 `fae4ec5a9d38f729`；同一版连跑两次同 sha16 ⇒ 该模式输出稳定）。

## ⑤ 13 份在册红是否照旧（逐条点数）

**登记表一个字没动**：`build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md` sha16 `e5946a8a7ce1cfe0`（= W23C 交付时同值），mtime `2026-09-16 23:58:19`（早于我开工）⇒ **13 条条目、处置列、日期列全部照旧**。
**现场状态**（脚本算；R0 与 R1 的「在册红」段落 **逐条相同**，唯一差别是 `APPSYNC=` 行尾部新增字段）：

```
13 条在册条目：**仍红 1** ｜ 已转绿 12（见上，应从表里删）｜ 缺件 0
```

| 类别 | 条数 | 内容 |
|---|---|---|
| `[在册红]`（仍红） | **1** | `tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll` 现 `16baacfccfcf1df0` vs 现权威 `c400ab1638e0c3d2`（`STALE`；W23C 那条 `tools/` 漏扫暴露的） |
| `[在册红·已转绿]` | **12** | 12 份 `PresentationCore.dll` 副本（登记时 `23567d420f0dbbaa`/`c0763fc10173e7ff`/`9adac6b8d8e285c3`/`f4a454c8fe69cdfe`/`95a669cc510337d1`/`f31822ce4a3e510d`），现全为 `7b47a7b3d69ad62f` = 现权威 |

**必须如实说清的一点**：`#23` 之前"13 份全红"的读数**今天不再成立** —— `pc` 在 `#23` 重生为 `7b47a7b3d69ad62f` 后，那 12 份副本已经收敛到新权威（W23C 的 3.6/刷新那条路走通了）。
**这不是我改动造成的**：`AUTH-MISSING` 段落与 13 条**在 R0（改前，09:33）就已经是"仍红 1 / 已转绿 12"**；R0↔R1 的在册红段落 `diff` 只有 1 行（`APPSYNC=` 尾部字段）⇒ **逐条点名、逐条状态完全照旧**。
`known-red.json`（五臂门禁的登记表）**一个字节未碰**（sha16 `e623d2b17d948e3b`）。

---

# 件 2 · `D-A2` 残余："两份 `wpfgfx_cor3.so` 一起换旧仍静默" —— **只出设计（未落地）**

## ⑥-1 现场（脚本算）

| 副本 | sha16 | 大小 | mtime |
|---|---|---|---|
| `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` | `d567c26f197ec1e3` | 4,987,840 | 2026-09-16 15:10:32 |
| `build/MilBridge/.artifacts/bin/MilBridge.Linux/release_linux-x64/native/wpfgfx_cor3.so` | `d567c26f197ec1e3` | 4,987,840 | 2026-09-16 15:10:32 |

全仓**只有这 2 份**（`find . -name 'wpfgfx_cor3.so' -not -path './.git/*'` ⇒ 2 命中）。
`ITEMS:109`（改后 `:116`）权威串**为空** ⇒ `:225` `[ -z "$exp" ] && { echo note; continue; }` **早退** ⇒ **逐份判据 0 行**；唯一的网是"跨副本一致性"分组（`:350-381`）：两份同 sha ⇒ `CONSISTENT`（静默），两份不同 sha ⇒ `DIVERGENT` + `rc=1`。

## ⑥-2 2×2 实测矩阵（私有拷贝预演，**未落地**；旧桥用真件 `$HOME/wfp-runs/w18-pre/wpfgfx_cor3.caf7baf9e67719aa.so`，sha16 `caf7baf9e67719aa`，4,983,696 B）

`AUTH_ROOT`=`SCAN_ROOTS`= 私有 `farm`（含两份 `.so` 的真件副本 + 六件权威副本），脚本用**我的私有拷贝**（`today` = 现 ITEMS；`planA` = 把 `wpfgfx_cor3.so` 的权威改成 publish 输出，即 `#22` 指的那条）。

| 场景 | 今天（权威串为空） | 方案 A（权威 = publish 输出，**非 Debug**） |
|---|---|---|
| 两份都新 | `rc=0`／`CONSISTENT d567…`（`so2-A1.log` `167efedd2658f32e`） | `rc=0`／新增 2 行 ⑥ 判据（`OK` 行：权威件本身 + native 副本；`OK=6→8`）（`so2-B1.log` `a21318efc5abeec9`） |
| **只** 一份旧（native 换旧） | `rc=1`／`DIVERGENT=1`（`so2-A3.log` `c191da6a4033f4cb`）——**今天已经红** | `rc=1`／`MISMATCH=1(NEWER-DIFF=1)` **+** `DIVERGENT=1`（`so2-B2.log` `6bc015b46c63c235`） |
| **两份一起** 换旧 | `rc=0`／`CONSISTENT caf7…`／`APPSYNC=PASS`（`so2-A2.log` `30037bceaf3a642f`）——**洞** | `rc=0`／`OK=8`／`APPSYNC=PASS`（`so2-B3.log` `7076216d22645a27`）——**仍然洞** |

> 这六趟都是在**最终版脚本**上重取的（`today`/`planA` 都是**私有拷贝，未落地**）。`A1/A2/B1/B3` 的日志 sha16 与上一版**逐位相同**；`A3/B2` 变了（`e65b73b836bea8fb`→`c191da6a4033f4cb`、`e82c267c7f35d4ad`→`6bc015b46c63c235`）——原因是这两趟的日志里**会打印副本 mtime 与"不早于权威 N 秒"**，两趟造桩时刻不同 ⇒ 分类读数逐位相同（`A3`：`OK=6`/`DIVERGENT=1`；`B2`：`OK=7`/`MISMATCH=1(NEWER-DIFF=1)`/`DIVERGENT=1`）。

**⇒ 我推翻 `#22`/W22D 的那句预测**（`build/MilBridge/W22D-report.md:169`、`docs/WAVE24-PREREGISTRATION.md §4.2`）："给 `wpfgfx_cor3.so` 配**非 Debug 权威** ⇒ 两份一起换旧**必须红（NEWER-DIFF）**"——**实测不成立**（`so2-B3.log`：`rc=0`、`APPSYNC=PASS`）。
**机制（结构性，不是调参问题）**：ITEMS 的权威语义是"**某个文件的内容就是真值**"，而被指的那个文件**正是这两份副本之一**（全仓只有 2 份）⇒ "两份一起换旧"= **把权威一起换掉** ⇒ 任何"副本 vs 权威"的比法都恒绿。除非权威是**第三份**东西。
**方案 A 的真实增量（如实缩小）**：今天 **0 条新红**、**0 个新覆盖场景**；它只把"互比"升级为"**逐份点名**（`EXPECT`/`ACTUAL` 两列）"，并把那份 native 副本从"互比的旁证"变成"有真值的判定对象"。**它不是残留洞的修法。**
（`#22` 的另一半是对的：权威改成非 Debug 后，`release_linux-x64/` 路径下的副本**不再被 ④ 豁免**，确实掉进 ⑥ 被真判——实测 `B1` 的 ⑥ 判据行 `6→8`。）

## ⑥-3 最小判据（我的方案 B：**把已经存在的绝对锚接进 APPSYNC 这一层**）

**关键发现（比 `#22`/`#23` 的表述更准）**：`wpfgfx_cor3.so` 的**绝对锚早就存在**，只是**没被校验器读**：

```
build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt
    BRIDGE_SRC_FP=b6acdba4f01599d8 BRIDGE_SRC_N=78
    BRIDGE_SO_SHA256=d567c26f197ec1e3a326e1353ae164bdcd51c5de627fa097cc5d026e4c3115c9   ← 绝对锚
    PUBLISHED_AT=2026-09-16T15:10:32+08:00
    IMPLEMENTATION=build/bridge-src-fp.sh（唯一实现；门禁 runner 必须调它，不许内联重写）
```

* **谁写**：`build/publish-milbridge.sh:81`（`echo "BRIDGE_SO_SHA256=$(sha256sum "$PUB/wpfgfx_cor3.so" | awk '{print $1}')"`）。
* **谁已在读**：`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh:119-129` 的 `bridge_so_file_match()`（读同一字段、与**部署件**比，缺文件/无字段 ⇒ `NOINFO`），并在 `:724` 打出"发布后被换过件"。
* ⇒ **残留洞的本质是"锚没接进这一层"**，不是"没有锚"。**不许新造锚**（新造锚 = 第三个真值来源 = 又一个会漂的数字）。

**最小改法（草案，未落地）**：
1. `ITEMS:116`：`wpfgfx_cor3.so` 的权威串从**空**改成 `<publish 目录>/bridge-src-fp.txt`（**指向记录文件本身**）。
   * 为什么指向记录文件而不是 `.so`：① 记录文件**不是**那两份副本之一 ⇒ 才可能堵住"两份一起换"；② 它落在 `*/release_linux-x64/*`（**不含 `/bin/Debug/`**）⇒ `is_debug_auth` 为假 ⇒ **④ 豁免自然失效**，副本按 ⑥ 被真判（与 `#22` 的意图同向）；③ 它的 **mtime = 发布时间**，正好给 `STALE`/`NEWER-DIFF` 一个**有语义的**分界（早于记录 ⇒ "发布后没刷新"；不早于记录 ⇒ "发布后被换过件"）。
2. `sha()`（`:118`）加一个分支：当参数是"记录文件"时，返回从它里面解析出的 `BRIDGE_SO_SHA256` 前 16 位（`sed -n 's/.*BRIDGE_SO_SHA256=\([0-9a-f]\{16\}\).*/\1/p' | head -1`），**解析不出 ⇒ `<missing>`**（不许降级成绿）。
3. `auth_sha_of()`（`:210`）走同一条取值路（否则 `UNEXPECTED` 分支会拿**记录文件自己的 sha** 去比 ⇒ 未声明副本恒 `DIFF`；那是"更红"但**不准**，必须一起改）。
4. 新增自检 **P**：① 两份副本与记录一致 ⇒ `rc=0`；② **两份一起**换成旧桥 ⇒ 必须红（2 份 `STALE`/`NEWER-DIFF`，点名 `EXPECT`/`ACTUAL`）；③ 记录里 `BRIDGE_SO_SHA256` 被抹掉/文件缺失 ⇒ **`NOINFO`（点名叫出来，不许当绿）**；④ 记录**没变**、只换一份 ⇒ 红（与今天 `DIVERGENT` 同向，双重网）。
   代码量：**判定侧 ~5 行**（`ITEMS` 1 行 + `sha()` 3 行 + `auth_sha_of` 1 行）＋ **自检 P ~30 行**（含三趟沙箱）。

**反极性（怎么造出"必须红"的输入）**：
* **强的那一极（本设计的唯一增量）**：把**两份 `wpfgfx_cor3.so` 同时**换成分旧件（`caf7baf9e67719aa`，仓外留档件，`cp -p` 造桩即可）—— 记录文件不动 ⇒ 两份副本都 ≠ 记录里的 sha ⇒ **必须红**（实测：这一极在"今天"与"方案 A"下都是 `rc=0`/`PASS`）。
* 弱的那一极（只换一份）今天已红，接线后仍红（双重网，不算增量）。
* **接线后今天会新增多少红**：两份副本的现 sha = `d567c26f197ec1e3` **= 记录里的值** ⇒ **0 条新红**（§⑥-2 B1 已实测"0 条"）。

**会不会与 13 份在册红冲突**：**不会**。① 不同件（那是 `PresentationCore.dll`×12 + `WpfGfx.Linux.dll`×1；本件是 `wpfgfx_cor3.so`）；② 不同表（那是**书面登记** `known-red-PC-copies.md`，本判据的红进**计数器**，与 `known-red.json`（五臂门禁表）无关）；③ **今天 0 条新红**，所以也不会"叠加出一片红"。

**待裁决口径（必须由主控裁，不许我私自定）**：
* **记录陈旧**时算不算红？记录里的 `BRIDGE_SRC_FP=b6acdba4f01599d8` 与现源重算不一致 ⇒ 意味着"发布的 .so 不是当前源编的"（源级陈旧，`close-wave.sh` 与应用门禁已经在管）⇒ 建议：**校验器只提示 `BRIDGE-REC-STALE=1`、不据此红**，避免同一次事故被两个门重复计数；但 `BRIDGE_SO_SHA256` 与副本不一致**必须红**（那是产物级、且只有这一层看得见）。
* 记录文件缺失 ⇒ `NOINFO`（点名），**不许**当绿——与文件头 `:335` 已写下的"缺 manifest 报 NOINFO"目标形态一致。

**排期建议：单独一趟（`#25`），与件 1 分开**（预登记 §4.2 自己写着「与 §4.1 同趟改会更省，但要注意『一次只让一个东西动』」——我按后者办，理由见下）。理由：① 同一份文件 ⇒ "一次只让一个东西动"；② 上面那条"记录陈旧算不算红"要主控裁决；③ 改动虽小但要新增一条自检 + 两趟留档 + 与 `sync-applocal-authority.sh` 的"只读判据"口径对齐（该脚本读的是**行首标签**，新类不新增行首标签、只改 `EXPECT/ACTUAL` 的来源 ⇒ 兼容，但**必须实测一次**）。

---

> **纪律 35 附注**：预登记 `docs/WAVE24-PREREGISTRATION.md` 在我开工时读到的是 sha16 `1ac169d78d569220`，收工复核**仍是** `1ac169d78d569220`（mtime 09:30:06，早于我 09:30:53 开工）⇒ **本件工作期间预登记没有漂移**，§4.2 引文可核。

# ⑦ 我推翻 / 更正的陈述（逐条，带实测）

1. **`#22`/W22D 的 `wpfgfx_cor3.so` 预测**（`W22D-report.md:169`、`WAVE24 §4.2`）："配非 Debug 权威 ⇒ 两份一起换旧**必须红（NEWER-DIFF）**" ⇒ **推翻**。实测 `so2-B3.log`：`rc=0`、`APPSYNC=PASS`、两份都 `OK`。原因是结构性的（**权威是那两份之一**），不是参数没调对。方案 A 的真实增量 = **0 条新红、0 个新覆盖场景**。
2. **`ITEMS:116`（改前 `:109`；`#22` 版是 `:103`）注释"无跨波稳定的期望 sha"** ⇒ **部分更正**：**期望 sha 的记录是存在的**（`bridge-src-fp.txt` 的 `BRIDGE_SO_SHA256`，由 `publish-milbridge.sh:81` 每波写入），缺的是**校验器不读它**。残留洞 = "锚没接进这一层"。
3. **任务书默认的"删权威 ⇒ rc≠0；恢复 ⇒ rc=0"**：**在真实全仓树上不可观测**（现场基线 rc 本来就是 1，见 §0/§③-3），而且移真件有干扰在跑构建的风险 ⇒ **真件未移**，改用"私有沙箱（改前/改后同输入）+ 私有权威副本×真实扫描根 + 真仓改前/改后两趟"三条等价实测。这是**与任务书的一处如实偏离**，理由与替代证据都写在 §③。
4. **W23C 的"接线后立刻 13 份红"与今天现场**：**现场已变**——12 份 `PresentationCore.dll` 副本已随 `pc` 重生（`7b47a7b3d69ad62f`）转绿，13 条里**仍红只剩 1 条**（`tools/GeometryOracle/.../WpfGfx.Linux.dll`）。**发生在改前**（R0 就是这样），与本改动无关。
5. **`D-G8` 的影响面（收紧）**：不是"今天全仓都在骗人"——**全仓树上每一件都至少有一份 ⑥ 副本**（§① 普查表）⇒ 权威消失会顺带红。真正静默的是**收窄扫描根**的场景，其中一个是**真在跑的消费者**：`sync-applocal-authority.sh:59` 自带 `SCAN_ROOTS`（**且不含 `$REPO/tools`**），而它 `:72` 拿到的 `chk_rc` **只打印**（`:155`）、不据它退出 ⇒ 修复前那趟假绿在该脚本里也是假绿。**顺带登记的欠账**：那个脚本的默认扫描根没跟上 W23C 的 `$REPO/tools`（`#25` 可选一并收）。

# ⑧ NOINFO / 未测清单（不许猜）

* **真件上的"移走权威"未做**（理由见 §⑦.3）。替代证据 = P1–P5 ＋ F1–F3 ＋ R0/R0′/R1（全部留档、sha16 在表里）。
* **并发干扰不可排除**：本波另两条车道在跑 `dotnet`（09:31 实测两个进程，写域 = `build/MilBridge/tests/{FrameProbe,CoverageProbe}/**`、`build/MilBridge/tools/frame-step.sh`）。证据是"无漂移"：`pc` 每趟前后逐位未变；`diff R0′ R1` 只有那 3 处（且全部是我新加的输出字段）。但"完全无并发影响"**不可证** ⇒ 登记为 NOINFO。
* **件 2 未落地**：所有 `wpfgfx_cor3.so` 读数来自私有 `farm` + 脚本私有拷贝；`planA` 只是**预演**，仓内 `ITEMS` 未动（`--list-items` 复核仍打印 `wpfgfx_cor3.so：（无权威）`）。
* **件 2 的记录陈旧口径未裁决**（§⑥-3 待裁决项）；`auth_sha_of` 同步改动的副作用**未实测**（只在设计里指出）。
* **我自己的仪器事故（如实登记）**：第一次重取「改前」真仓读数时**没显式给 `AUTH_ROOT`**，而旧脚本副本按 `dirname $0/../../..` 把 `REPO` 算成了 `/home` ⇒ 那趟扫的是 `/home`（**只读，未写任何文件**），读数作废（`权威根：/home`、`期望副本=101`、`MISSING=6` 都是 `/home` 口径的产物）；补上显式 `AUTH_ROOT=$R SCAN_ROOTS=<真实五根> HINTPATH_ROOTS=$R` 后才得到 R0′ ⇒ **凡引用「真仓读数」都以显式三根的那几趟为准**。
* **未做**：`sync-applocal-authority.sh` 的 `--apply` 两趟（它会**写副本**，不在我的写域/本件范围）；`--selftest` 之外的 `AUTH_ROOT` 变体组合；`Right/Center/Justify` 等与本件无关的口径。
* `wpfgfx_cor3.so.dbg` / `wpfgfx_cor3.dll` **不在 `ITEMS` 里**（名字不匹配）⇒ 本件与件 2 都**不动**它们（登记为"未覆盖"，不是"已覆盖"）。

# 复现（三步，全只读）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 1) 真实全仓读数（改后应：AUTH-MISSING=0、rc=1、13 条在册红 仍红1/已转绿12）
bash $R/build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh ; echo rc=$?
# 2) 自检（应：rc=0、17 项全 PASS、0 FAIL）
bash $R/build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest ; echo rc=$?
# 3) 两张权威表一致性（应：ITEMS_SYNC=YES、rc=0）
bash $R/build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --list-items ; echo rc=$?
```

**本件交付物**：① 本报告；② `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`（`013df358c0bed2a3` → `fc4c249851fa1d71`）。**没有第三件**（`known-red.json` / `known-red-PC-copies.md` / `applocal-expect.py` 全未动）。
