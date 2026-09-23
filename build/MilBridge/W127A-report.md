# W127A 报告 —— `#52` 冻结**之后**落一批登记（含修正两条落后状态）＋ 推一笔

**一句话**：等到 `gen=#52`（`10:49:50` 冻结、`10:53:17` 首次采到）且 W126A 链路进程全退出后，落 **3 件**改动（`KNOWN-DEFECTS.md` ／ `docs/ROUTES.md` ／ `defect-registry-declared.tsv`）＋ 本报告，`DEFREG` 两遍 **`PASS declared=143 route_ids=143` ／ `DECLDRIFT=0` ／ `rc=0`**；`TASK-0707` **🔴→✅**、`TASK-0203` **保持 🟡 ＋ 封口裁定**、新开 **`D-G103`…`D-G107`**（五个号，末号现场核）。**全程零 `dotnet`／零构建／零门禁／零应用／不占槽。**

**判据先写**：`~/w127a/criteria.md`（开工 `fe206972cb80d461`；主控裁定"bound 放长"后追加 §2b ⇒ **`af68d92cd4cc0f99`**，**只延长 bound、判据一个字未改**）。

---

## ① 握手读数（先写后跑；每次轮询一行入 `~/w127a/STATUS.md`）

**判据（开工前写死，逐字见 `criteria.md` §1）**：动册/地图/声明表的充要条件 = **S1** `docs/CURRENT-STATE.md:9` 含 `gen=#52` ∧ **S2** `ACCEPTANCE-BASELINE.md` sha16 位移 ∧ **S3** `w126a`／`verify-all`／`heavy-slot` 活进程全退出（**第一判据是活进程/机器行，不是别人的 `STATUS.md`**）。轮询间隔 120 s。

**读数（共 55 行，两次 bound）**：

| 段 | 时刻 | `gen` | AB sha16 | 说明 |
|---|---|---|---|---|
| 第 1 段 `#01–#22` | 09:58:52 → 10:41:00 | `#51` | `38e67e834430d75c` | 全 `#51` ⇒ **10:43:00 按判据记 `TIMEOUT`**（**零写入**，未碰任何仓内件） |
| 第 2 段 `#01–#04` | 10:43:16 → 10:49:17 | `#51` | `38e67e834430d75c` | 仍在等 |
| 第 2 段 `#05` | **10:51:17** | **`#52`** | **`27293fb5ab91b778`** | **首次采到冻结信号**（冻结时刻 = AB `mtime` **10:49:50**） |
| 第 2 段 `#05–#32` | 10:51:17 → 11:45:27 | `#52` | `27293fb5ab91b778` | `live` 由 W126A 的冻后 `verify-all` ×2 撑着，**不为 0 ⇒ 不动手** |

- **放行动作**：`11:45:32` 见冻后 ×2 都 `27/27`（`POST2_OUTER_RC=0`），复算 S1/S2 并从 `/proc/*/cmdline` 确认 **`w126a`／`verify-all` 进程 = 0** ⇒ `11:46:1x` 开始落批。
- **第 1 段超时是真实的**（不是我没等）：W126A 的**第一次冻前 `verify-all` 出 2 处红**（`Windowing.Tests` **非声明类** ＋ `COLUMN-FLOOR` 声明类），它按纪律**停手报主控**、落几何守卫后**重跑整趟** ⇒ 冻结顺延。**主控据此把 bound 从 45 min 放到 ≈12:30**（`criteria.md` §2b）。
- ⚠️ **一处自伤留痕（同 `D-G103` 族）**：我第一版的等待循环用 **`grep -q 'FREEZE_OK\|FREEZE_TIMEOUT'`** 判"轮询器结束" —— 而**轮询行里本来就含这两个字面量**（`live=` 字段把探活者的整条命令行抄了进去）⇒ **假阳性、循环提前跳出**。**修法** = 改判**行首标记** `^- \[.*\] \*\*FROZEN-SIGNAL`（改后 `0` 命中，与"还没结束"一致）。**教训**：**"日志里出现过那个串" ≠ "那件事发生过"**。
- ⚠️ **第二处自伤（已写进 `D-G103` 第三实例）**：收工时我用 `for p in /proc/*; do … case *w127a/poll.sh* ⇒ kill $pid` —— **该循环自己的命令行含被搜的字面量** ⇒ **把自己 SIGTERM 了**（跟在 `kill 202517` 之后，后续命令没跑）。⇒ **身份判据必须用进程自身属性（PID／`/proc/<pid>/exe`），不许用"我的命令行里有没有那个串"**。

---

## ② `TASK-0707`：改前/改后逐字 ＋ `wc -l` 复核

**改法 = 行锚定**（只改状态位那一段，`docs/ROUTES.md:464`）：

- **改前（`:464` 头 60 字符逐字）**：``- `TASK-0707` [Next] 🔴 **把"硬链接/同 inode 共享"并进装置卫生牙**``
- **改后**：``- `TASK-0707` [Next] ✅ **把"硬链接/同 inode 共享"并进装置卫生牙**``

**并在该行子块末尾追加 4 行收口 bullet**（`ROUTES.md:471–474`；**上面 W122A 的登记一字未动**，`🚧 正在由车道 W119A 实现` 那行**照旧留着**，只在其后追加）：

1. ✅ `TASK-0707` 收口（车道 W127A）—— 状态位 **🔴 → ✅**；
2. 牙与三格：`build/MilBridge/tools/hygiene-tooth.sh`（**`dc1e79a23dbb7eb2`**，**1626 行**，`--selftest` **67/67**）的第四类 = 硬链接/同 inode 共享已在件内落地（`HYGIENE_INODE=` 分项；`--selftest` 含 **`S16a`**（真硬链接 × 原地写 ⇒ 必红）／**`S16b`**（改 temp ＋ `rename` ⇒ 回绿且仍打印 `links>1`）／**`S16c`**（形态抽不出 ⇒ `NOINFO`））⇒ ①列 `links>1` ②列跨区同 inode 对 ③三态，**三条格全部落地**；
3. 收口读数（主控现场复核）：`HYGIENE_INODE=PASS multilink=0 cross_region=0`；**断链总账** = `1421`（登记件）＋ `6`（产品 DLL）＋ `4588`（`bin/obj`）= **`6015`**，再加 **`6417`**（`upstream/` 声明残留、无写者）= **`12432`** ＝ 开工时原始跨区共享数；
4. ⚠️ **口径句**：牙的 `multilink` **只覆盖它自己的 `HYG_SKIPDIRS`**（含 `obj bin upstream __pycache__`）⇒ **牙的 `0` ≠ 全树干净**；三个数 **`1388`／`1421`／`12432`** 是**三种口径**，差 **33** 全在 **`__pycache__/`**。

**三样齐（现场复核，非引用）**：件名 `hygiene-tooth.sh` ＋ 字段 `HYGIENE_INODE=… multilink=0 cross_region=0`（主控现场）＋ sha16 **`dc1e79a23dbb7eb2`**（我现场算）；`S16a/b/c` 三条**我在件内逐字读到**（`:1563` 注释、`:1570/:1575/:1580` 三例）。⚠️ 我**没跑** `--selftest`（跑它等于跑牙 ⇒ 本车道"零门禁"边界）；`67/67` 引自主控。

**`wc -l` 复核（防吞行）**：`docs/ROUTES.md` **616 → 648**（＋32：4 行 0707 收口 ＋ 28 行 §15n），`wc -l` 与逐段行号一致，**无吞行**。

---

## ③ `TASK-0203` 追加段逐字（状态位**保持 🟡**）

落在 `docs/ROUTES.md` **§15n 的第一条 🟡 bullet**（六条 ＋ 2026-09-23 追加）：

- ① **追加批 41 趟**（`134`×**40** ＋ 1 趟异常）**`139` = 0**；**阳性对照 4/4 成立** ⇒ **整批不作废**（`POSCTRL_CONTROL_ALIVE=2/2`、`POSCTRL_PREFIX_134=40/40`）。
- ② **唯一被外部打断的趟点名剔除**（**`G20301`**：`APP_RC=0`／`app.err` **0 B**／只一个良性停点 `si_addr=0x0`／**死在 10 s、只落地 2 击**，而产品崩**必须**走到第 **7–8** 击之后）⇒ 分母 **41→40**。
- ③ **上界重算**：本批 **`0/40` ⇒ 95% 单侧上界 `7.28%`**；本装置合并 **`0/61` ⇒ `4.86%`**；与 `W98A` **同件同腿**合并 **`1/121 ≈ 0.83%`**（**`W98A` 的 `1/60 = 1.7%` 本批未复现**）。
- ④ **归因仍 `NOINFO`**；`134` 侧已闭到栈底，**但那是 `134` 的机制、不是 `139` 的**。
- ⑤ **主控裁定：就此封口、不再投 ≈175 趟 ≈1.7 槽小时**（要投由用户拍板）。
- ⑥ 出处三样齐：报告终值 **`a22eb8a7881e01ba`**（`build/MilBridge/W118A-report.md`，口径 `head -n -2 | sha256sum | cut -c1-16`；**FULL = `77cd063b2234643e`**，431 行）＋ 判据 **`110b44e10788287d`**（`~/w118a/criteria.md`，先写后跑）＋ 机读台账行。
- 🔁 **2026-09-23 追加（车道 W128A 中途交数）**：`139` 族归因**从 `NOINFO` 推进到"异源 ＋ 具名判定点"** —— ① 线程 **`.NET Finalizer`（`tid=6`）** vs `134` 恒 `tid=1`；② 栈深 **`7,088 B`** vs **`8,388,672 B`**；③ **无环**（`R1_CYCLE=False`／`R2_SAMESET=False`；`134` 族 12/12 全 True）；④ **应用输出 0 字节**；判定点 = `PC wpf_queue_push+259`（`libwpfwin32.so+0x11df3`）`mov 0x38(%rax),%rax`，回溯 `PostMessageW` ⇒ `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82` 的非法队列自愈分支约 `:79`。⚠️ **状态仍 🟡（处置未做）**；⚠️ **`D-G98` 适用范围据此写明"只指 `134` 族那条线、不含静默 SEGV"**；⚠️ **W128A 批次仍在跑**（写成时 `1/75 ≈ 1.3%`）；**建议独立开号**（本件**未**开，主控另派）。

**同步追加进册**：`D-G98` 段内新增"归因落地"bullet（含上述四条读数 ＋ 反汇编级判定点 ＋ 适用范围限定 ＋ `1/75` 进度），**原判词一字未动**。

---

## ④ 新号判词（**新开 5 个连续号** `D-G103`…`D-G107`；末号现场核 = `D-G102` 已有、`D-G103` 册内 0 命中）

**走"新号"而非"并入"的理由（逐条）**：① 主控点名要求"**并入还是新号由你现场定并写理由**"；② 号族上，这些形态**册内既无同号也无同判词**——`pgrep`／`pkill` 那条**只有教训表 `L14` 行**（**非 `D-*` 号**，且表格装不下"自杀 ＋ 毁证据"这一层）；`stat -c '\t'`／`awk` 钳位／"只验可达性不验几何"／"假可疑"／"`\S+` 解析多词字段"**册内零命中**；③ **能并的两条我并没开新号**（见下"并入既有"）；④ 全部**交叉引用**同族号并**明确写"不许合并"**。

| 号 | 一句话判词 | 要件（形态／后果／正确姿势） | 危险方向 |
|---|---|---|---|
| **`D-G103`** | `pkill -f '<模式>'` **也匹配发出者自己那条命令行** ⇒ **自杀** ⇒ 损失清单永远拿不到；**同一模式顺手杀掉别人的批次** | 实例 W124A 的 `pkill -f 'HandyControlDemo.dll'` 命中 W118A 在跑的装置；**代价 = 别人批次 1 趟损失 ＋ 无法自证损失范围**；**正确姿势 = 只按 PID `kill`、探活读 `/proc/*/cmdline`，任何 `pkill`/`killall`/`pgrep -f` 都不许出现（含诊断命令）**；**自救实测** = 四格自证字段 12 趟全 `SUSPECT=no` | 毁证据 ＋ 污染别人分母 |
| **`D-G104`** | **读数器自己的输出语义被读错且不报警** | ① `stat -c '…\t…'` 打的是**字面反斜杠 t** ⇒ 列错位 ⇒ 比对**空转**（W123A 重算后结论未变，**但空转不构成证据**）；② `awk` 求和**静默 int32 钳位** `2147483647`（2³¹−1）vs 真值 `4387006694`（4.09 GiB，Python 复算）⇒ 低估一半以上；**口径 = 凡"总和／分布／逐字段比对"必须第二种工具复算**；**第三条 = 同一件两种口径两个 sha16 时必须两行都给**（先例 `W123A-report.md` 的 `abd86b0bbdabfc9d` vs 主控转来 `02cda62724d4d702`） | 空转当证据／低估 |
| **`D-G105`** | **复用外部 X 时只验"连得上"、不验"几何对不对"** | 挑中 W128A 的 `:185 -screen 0 1024x768x24`（仓内要 `1280x1024`）⇒ `Windowing.Tests` 整套件**假红**（用例 831 vs `#51` 875，差 44）；**代价 = 一行 2 处红把冻结挡下 30+ min**；**修法** = 两处复用点加几何守卫（三态 `X-REUSE=reused\|skipped-geom-mismatch\|self-started`），件 `verify-all.sh` `1fb43fc4522c8784 → 0cdd12547a634b37` | **假红**（装置问题读成产品回归） |
| **`D-G106`** | **"假可疑"把真命中踢出分母** | `ARM=gdb` 下"命中即停 = 看 `APP_RC=139`"**不可达**（gdb 在场时 `APP_RC` 是 gdb 的 rc）⇒ 同趟出现 `FAMILY=other` ＋ `APP_RC=0` ＋ **假** `EXTERNAL_KILL_SUSPECT=yes`；**正确口径 = `APP_FATE` 含 `SIGSEGV` ∧ `APP_TEXT_BYTES=0`**；与 `D-G103` 共用纪律：**凡"外部打断"判定必须给出"应用自己的结局"这一格，拿不到 ⇒ `NOINFO`** | **样本损失 ＋ 上界算错** |
| **`D-G107`** | **解析器对多词字段整行不匹配 ⇒ 非主线程的趟被静默降级** | STOP 行正则 **`thread=(\S+)`** 只吃一个单词 ⇒ **`.NET Finalizer`**（含空格）**整行不匹配** ⇒ 该趟被判"没有 deep 停止点" ⇒ **一律误判 `NOINFO`**；**口径 = 分隔符按字段真实取值集合定义，不许用 `\S+` 赌"没有空格"**，且每趟须自证"我解析到了那个字段" | **漏判命中** |

**"能并进既有条就并"的两条（我选并入、未开新号，理由逐字）**：
- **方法学：判断"某车道是否在动" = 活进程第一、`STATUS.md` 第二** —— 本会话已有**两条**车道 `STATUS.md` 滞后（W120A／W123A）⇒ 并入 `§15n` 的方法学条（册内 `D-G93` 已是同族编号，**再开号只会把同一根因拆散**）。
- **方法学：探活者不得进被数集合 ＋ 不许 `pkill` 族** —— 同为 `D-G93` 族，并入同上一条（并交叉引用 `D-G103`）。

**（另记）环境级事实**：`uptime -s` = **`2026-09-23 09:45:54`** ⇒ **宿主当天重启过一次**；`w126a` 09:32→09:58 的"静默挂死"**就是这次重启**（不是运行时故障）；⇒ 口径句已写进 `§15n`：**"进程没了 ∧ 日志断在半路 ∧ `STATUS.md` 停在某一秒"三件同时出现 ⇒ 先查启动时刻**。⚠️ 对 09-22 那几条车道的归因，本件**如实写"未定"**（证据不足）。

---

## ⑤ 其余各条改动逐字

| 文件 | 改动 | 行数 |
|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | ① `D-G98` 段内追加 **2 个 bullet 组**（W118A 的 `139`/`134` 侧读数 ＋ W128A 的"归因落地"）；② 新增 **5 条 `### D-G10x`**；③ 段头补记（**只加不改**）：`＋ `#51` 冻后第二笔登记（`D-G103`…`D-G107`，2026-09-23，车道 W127A）` | **2742 → 2790**（＋48） |
| `docs/ROUTES.md` | ① `TASK-0707` 状态位 🔴→✅ ＋ 4 行收口 bullet；② **新增 `§15n`**（冻结握手／0707／0203 六条＋W128A 追加／5 条新号／方法学四条／`DEFREG` 两行／推送指针） | **616 → 648**（＋32） |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `--emit` 重生成（**我自己造的漂移自己收**） | 138 → **143** 条 |

**`D-G98` 追加的两个 bullet 组（逐字要点）**：
- **W118A**：`139` 侧 **41 趟 0 命中**（有效 `N=40`，本装置合并 **0/61**）；`134` 侧**机制闭到栈底**（**19 趟**全判 `managed stack overflow`；`si_addr` 比栈底低 **`-4…-216` B**、`rsp` 落栈底 **`0…-208` B** ⇒ `EXH` 19/19；**12 趟**独立重建同一条 **21 帧回声环**、轮数 **2,937–2,987** ↔ 应用自打 **62,094 ÷ 21 ≈ 2,957**，偏差 ≤1.0%）；**它推翻自己两条判据**（`E5`「原生撞点 ⇒ 必是 `139`」被 **59/59** 推翻；「`rsp` 出映射 ⇒ 必静默」被推翻 ⇒ **分类器容忍度实测下界 = 216 B**）。
- **W128A**：`139` 族**归因落地＝异源**＋具名判定点（见 §③）。

**未碰（逐件核实 links=1 ＋ sha16 未变）**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**`27293fb5ab91b778`**，`#52` 冻结件）、`docs/CURRENT-STATE.md`（`:9` 机器行 `gen=#52` 原样）、`handoff.md`（`e4dc264200b421d0`）、`build/MilBridge/known-red.json`（`d4e0080df6ec497c`）、`verify-all.sh`（`0cdd12547a634b37`）、任何既有牙、任何产品件。

---

## ⑥ `DEFREG` 两条机读行（**现场跑两遍，逐字节 IDENTICAL，`rc=0`/`0`**）

```
DEFREG_DECL=n=143 route_ids=143 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=2f63679f3dcf20c7 CS=737c78e3a7e5a3a5 HO=e4dc264200b421d0 AB=27293fb5ab91b778
DEFREG_EXTRA=KRJ=d4e0080df6ec497c KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=143 route_ids=143（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
rc=0
```

- **两条要点行**：**`DEFREG=PASS declared=143 route_ids=143`** ｜ **`DEFREG_DECLDRIFT=0`**（改前 = `138` ⇒ **本批 ＋5**）。
- **幻影号自检（引用前先确认存在）**：新声明表 **143 条**全部逐条落在 KD／CS／HO／AB 之一；`--emit` 输出里 `req=KD` 的有 **141** 条（另 2 条 `D-F3`／`D-G34` 是**既有的**、只声明在 `CS,HO,AB` ⇒ **不是我造的幻影**，旧表里同形）。
- **两遍差异**：`cmp` **逐字节相同**；期间**未**跑任何构建/门禁。
- `--emit` 生效方式留痕：该脚本 **`--emit` 只把新表打到 stdout**（`defect-registry-check.sh:403`），**不直接落盘** ⇒ 我 `> 临时件` → 逐条核 **0 幻影** → **temp ＋ `os.replace`** 落盘（**不用原地截断写**，避 `D-G101`）。

---

## ⑦ 推送前后 head ＋ `BYTECHECK` ＋ 件对账

- **推送前**：`fork HEAD = 37def7e480ea33fbd965195588410a7ee68b6434`（= W126A 的 `chore(#52)` 笔；其 `git status --porcelain` **空**、本地 = remote-tracking = `ls-remote` 三者一致）。
- **推送**：逐径 `git add`（**无 `-A`／无 `--force`**）→ `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`（**refspec 显式**）→ `git push origin feat-Linux` → **重新 `fetch` ＋ 与 `ls-remote origin HEAD` 交叉核** → `--symref` 仍 `feat-Linux`。
- **件对账（`git status --porcelain` 逐件核，防"漏推声明表"）**：**本笔恰好 4 件** = `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ／ `docs/ROUTES.md` ／ `build/MilBridge/tools/defect-registry-declared.tsv` ／ `build/MilBridge/W127A-report.md`（新建）；**无夹带**（`git status` 与"改了几件"逐件对上）。
- **`BYTECHECK`**：见文末 `===RECORD===`（本报告的末两行是**推送后**补写的读数行 ＋ sha16 行，故正文读数在推送当时有效）。

**件 sha16（改前 → 改后；`links` 全 `1`）**

| 件 | 改前 | 改后 |
|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `eed45d278bff3a37` | **`2f63679f3dcf20c7`** |
| `docs/ROUTES.md` | `ea5deb2891b38160` | **`5d615a54f1d46807`** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `989a88caa8751597` | **`b784a0a7ff2fd784`** |
| `build/MilBridge/W127A-report.md` | —（新建） | 见 `===RECORD===` |

---

## ⑧ `fp_inputs` 影响（机械证）

- **开工（`#51` 冻结期）现值** = **`84fd55d384e93203317d22601cec854d518e69c8f026006231302a2cfbc93366`**（W126A 现场算，我复核其口径）。
- **本件落批后现算（两遍相同）** = **`f0e2b3e8c058cdf017031360a2cc292ffd6ab7b91b4a8ae47c100c3877522bd7`**（口径 = 从 `build/close-wave.sh` 抽 `fp_inputs()` 函数体到 `/tmp` 跑，**不跑波、不重建**）。
- **机械证（我造的差 = 0）**：覆盖面成员是**显式名单**（`close-wave.sh:146+` 逐件列名），我把**本件改的每一件**拿去比：`KNOWN-DEFECTS.md`／`ROUTES.md`／`defect-registry-declared.tsv`／`CURRENT-STATE.md`／`handoff.md` —— **名单里一件都不在**（`grep` 于 `:130–215` 段 **0 命中**）。⇒ **本笔纯文档改动对 `inputs_fp` 零影响**（这条与"改 `verify-all.sh` 也不在覆盖面"同形：`:142` 逐字"实测它本来就不在覆盖面"）。
- ⚠️ **但现状值确实变了，如实点名是谁**：**车道 W131A**（`TASK-0109` 产品修法；`~/w131a/criteria.md` 判据 **10:56** 先写）在 **11:49:23** 改了 `src/WpfGfx.Linux.Native/src/{win32_core.c → a9cc8762908b417a, win32_x11.c → 9fa20864404ab01b, win32_internal.h → 4e1880e6054635ff}` 并**重建**，⇒ `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 由冻结的 **`bd037229be8db4f6`（327,256 B）** 变成 **`a6365183fa6d26b9`（327,512 B）**。这**不是**本件造成的，也**不是**我改的文件。

---

## ⑨ `NOINFO`／未做

1. **未跑任何门禁/牙的自检**：`hygiene-tooth.sh --selftest 67/67` **引自主控**（我现场只**读件**核到 `S16a/b/c` 与 sha16 — 跑自检等于跑牙，本车道边界是"零门禁/零构建/零应用"）。
2. **`TASK-0203` 的 `139` 本体归因**：本件只登记"异源 ＋ 具名判定点"；**那条静默 SEGV 我没开号**（主控说另派车道落）⇒ 编号那一格 `NOINFO`。
3. **W128A 的最终计数与上界**：写成时 `1/75 ≈ 1.3%`，**批次仍在跑** ⇒ 那一格 `NOINFO`（已写进册与地图）。
4. **`D-G105` 的"第二次冻前 `verify-all` 步骤级终值"**：本件只取到**套件级**（`Windowing.Tests ✅ 44`）与第二次冻前那趟的 `26 通过/1 失败`；**整趟总账**属 W126A 的交付 ⇒ 参它的报告。
5. **"全仓还有几处"三格未逐处枚举**：`pkill` 族形态（`D-G103`）／`stat -c '\t'` 与 `awk` 大数求和（`D-G104`）／"只验可达性不验规格"（`D-G105`）／"用 `APP_RC` 冒充被调试进程退出码"（`D-G106`）／`\S+` 解析含空格字段（`D-G107`）—— **各只核了现场那一两处** ⇒ 每一格的射程 `NOINFO`（**已逐条写明**）。
6. **未做**：未改任何判据件/产品件/牙；未把任何红写成绿；未放宽任何判据；未 `pkill`／`killall`／`pgrep -f`（**唯一次收进程是 `kill <pid>`，且那次因"命令行自匹配"把自己也收了 —— 已如实登记为 `D-G103` 第三实例**）。

---

## ⑩ 大白话小结（6 行）

1. **等到冻结才动手**：`gen=#52` 是 10:49:50 冻的，我 10:51 采到、11:46 才落笔（那之前 W126A 的冻后验证还在跑）。
2. 中间**白等了 45 分钟**：它第一次冻前检查出了 2 处红（其中一处是"复用了别人 1024x768 的 X"造成的**假红**），修补后重跑才冻成。
3. **没等到就不写**——那段时间我**一个字节都没动仓内件**（改册会让门禁那一步当场红）。
4. 落批内容：`TASK-0707` 改 **✅**、`TASK-0203` **保持 🟡 但封口**（并写清 `139` 现在算"异源"）、新开 **5 个号**（`pkill` 自杀式误杀／读数器语义读错／X 复用不验几何／假可疑踢样本／多词字段解析失败）。
5. `DEFREG` **两遍一模一样、全过**（143 条，比改前多 5），推送**四件、无夹带**、推后三方 head 一致。
6. ⚠️ **要提醒你一件事**：我落批期间**另一条车道 W131A** 正在改 native 源并重建 ⇒ **产品件已不等于 `#52` 冻结值**（`win32shim` `bd037229be8db4f6` → `a6365183fa6d26b9`）。**这不是我这笔造成的**，但 `#52` 的冻结对"产品位"**已经开始过期**，请据此决定要不要再冻一代。

---

===RECORD===
（推送前 head = `37def7e480ea33fbd965195588410a7ee68b6434`；本行以下为推送后补写的机读读数）
- **推送前 head** = `37def7e480ea33fbd965195588410a7ee68b6434`（W126A 冻结笔）
- **推送尝试（我这一笔）**：`11:56` 逐径 `git add` 四件 → `git status --porcelain` **恰四件**（无夹带）→ `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux` → `git commit` ⇒ **`无文件要提交，干净的工作区`**（见下"托管变更"）
- 🔴 **托管变更（如实记，不是我的笔）**：车道 **W126A** 在 `11:5x` 用 **`git add -A` 形态**把**我当时已 `cp` 进 fork 的四件**一并收进了**它自己的**第 2 笔报告提交 —— commit = **`4d125f8f102fee4ffcf5b61584cb03c57c8768d2`**（`docs(#52): W126A 报告 v2 …`；其 `--stat` 里同时含 `W126A-report.md` 与我那四件）⇒ **我的四件是被别人的笔带上去的**（**不是**我漏推、也**不是**我用了 `-A`）。⇒ 我随即**按远端 head 反查逐件 blob**：四件与 `$R` **逐字节相同**（`SAME ×4`）⇒ **内容无误**。
- **`--symref`**：仍 `feat-Linux`（`git ls-remote --symref origin HEAD` ⇒ `ref: refs/heads/feat-Linux`）
- **`BYTECHECK`（远端口径，逐件 blob vs `$R` 现件，sha256 全 64 位）**：**`BYTECHECK ok=4 mismatch=0 nobody=0`** —— `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`2f63679f3dcf20c7`）｜`docs/ROUTES.md`（`5d615a54f1d46807`）｜`build/MilBridge/tools/defect-registry-declared.tsv`（`b784a0a7ff2fd784`）｜`build/MilBridge/W127A-report.md`（本件）
- **远端自洽复核（在 `4d125f8` 上直接取 blob 重算）**：声明表 `DECL-ANCHORS` 的 `KD=2f63679f3dcf20c7` 与**该笔自己的** `KNOWN-DEFECTS.md` sha16 **逐位相同** ⇒ **远端不会读成 `DECLDRIFT=1`**（这一格正是先前车道踩过的坑）；`^ID` 行 **143** 条。
- **`$R` 侧复核（同步后）**：`DEFREG=PASS declared=143 route_ids=143`｜`DEFREG_DECLDRIFT=0`｜**两遍 `cmp` 逐字节 IDENTICAL、`rc=0`/`0`**。
- **推送后 head**：`37def7e480ea33fbd965195588410a7ee68b6434` → **`4d125f8f102fee4ffcf5b61584cb03c57c8768d2`**；`git rev-parse HEAD` = `refs/remotes/origin/feat-Linux` = `git ls-remote origin refs/heads/feat-Linux` **三者一致**。


### RECORD-补（落批后我现场发现的一处**未登记产品位移**，如实记；本段不推翻上面任何读数）

- **发现**：`git log` 显示 `37def7e`（提交信息 = `chore(#52): 收尾链 W126A 步骤①-⑩ —— 冻结 #52`，**11:49:37**）**其 diff 里含**
  `src/WpfGfx.Linux.Native/src/{win32_core.c,win32_x11.c,win32_internal.h}`（`+183/-5`）—— 而这三个件**当时正被车道 W131A 改**（源件 `mtime` = **11:49:23**，早该 commit **14 秒**）。
- **实际值**：远端 head 上 `win32_core.c` = **`a9cc8762908b417a`**、`win32_x11.c` = **`9fa20864404ab01b`**；而 `#52` 冻结块**逐字宣称**的是 **`3117923a7c899e05`** ／ **`11142fbef049eb66`**。现场 `$R` 侧 `libwpfwin32.so` = **`a6365183fa6d26b9`（327,512 B）**，冻结块宣称 **`bd037229be8db4f6`（327,256 B）**。⇒ **产品位与"宣称冻结的产品位"不是同一个**。
- **责任边界（机械证）**：`~/w131a/` 里**零 `git`／`git push` 痕迹**（`grep -rln` 五类关键词 ⇒ 无命中），且 **W131A 自己的 `LANDING-CHECKLIST.md` §0 闸门尚未勾选**（它按主控裁定**要等 `POST_ALL_DONE` 才落**）⇒ **不是 W131A 推的**；**我这一笔只 add 了 4 件**（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／本报告）⇒ **也不是我夹带的**。落在谁的笔里：**`37def7e`（W126A 的收尾链笔）**。
- **后果（供主控裁定，我**不**自行处置）**：远端现在**同时**存在"`gen=#52` 冻结声明（`win32shim=bd037229be8db4f6`、源 `3117923a…/11142fbe…`）"与"W131A 未登记的产品改动（源 `a9cc8762…/9fa20864…`、件 `a6365183…`）"，且**后者没有 commit message、没有 `KNOWN-DEFECTS` 登记、没有报告**。⇒ 三种可能处置（**由主控选**）：① 视为"`#52` 之后的第一笔产品改动"，**补登记 ＋ 让 W131A 按其清单继续**；② 若认为不该进远端 ⇒ **在 W131A 完成前不动**（它的 `apply-fix.py` 有锚点断言，重放安全），**另开一代冻结**；③ 逐字核对"`bd037229…` 是否曾经真实存在于现场"（**我拿不到**：该件**不在 git 里** ⇒ 无法从历史复原 ⇒ **这一格如实 `NOINFO`**）。
- **与本件的关系**：本件四件**纯文档**（`KNOWN-DEFECTS.md`／`ROUTES.md`／声明表／本报告），**与产品位无关**；本件的 `DEFREG` 读数、`TASK-0707`／`TASK-0203`／`D-G103…D-G107` 的判词**不受此位移影响**。

## §⑪ 发布完整性事件（**主控裁定：按"还原发布态"处置**；2026-09-23 车道 W127A 收尾）

### ① 现象（远端与冻结块不符，逐件值）

`#52` 冻结块（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:46–47`、`:57`，**文字一字未动**）逐字宣称：

| 件 | 冻结块宣称 | 远端 `37def7e..3faedc3` 实际 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `3117923a7c899e05` | **`a9cc8762908b417a`** |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `11142fbef049eb66` | **`9fa20864404ab01b`** |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | （冻结块未单独列；`#51` 值 `e4f2de8d038e4780`） | **`4e1880e6054635ff`** |
| `win32shim`（`libwpfwin32.so`） | `bd037229be8db4f6`（327,256 B） | **`a6365183fa6d26b9`**（327,512 B；**该件不在 git 里** ⇒ 只能取现场值） |

### ② 机制 = `git add -A` 把当时克隆里**所有脏件**扫进同一笔

**两条取证命令的原始清单**（逐件）：

```
$ git show --stat 37def7e
 .../wic-shim/sync-applocal-authority.sh            |  50 +++-
 build/MilBridge/arm-logs/tline.log                 |   8 +-
 build/MilBridge/gen/t2d-family-baseline.txt        |   2 +-
 build/MilBridge/gen/t2d-family-matrix.txt          |   2 +-
 build/MilBridge/known-red.json                     |  12 +-
 build/MilBridge/tools/repin-generation.py          |  30 ++-
 build/wave-audit.log                               |   3 +
 docs/CURRENT-STATE.md                              |   2 +-
 docs/WAVE52-PREREGISTRATION.md                     |  35 +++
 samples/WpfTextDemo/ACCEPTANCE-BASELINE.md         | 260 +++++++++++++++++++--
 src/WpfGfx.Linux.Native/src/win32_core.c           |  60 ++++-
 src/WpfGfx.Linux.Native/src/win32_internal.h       |   6 +-
 src/WpfGfx.Linux.Native/src/win32_x11.c            | 122 +++++++++-
 .../Presentation.Tests/run-wpfprobe.sh             |  11 +-
 .../Presentation.Tests/run-wpftextdemo.sh          |  10 +-
 verify-all.sh                                      |  64 ++++-
 16 files changed, 623 insertions(+), 54 deletions(-)

$ git show --stat 4d125f8
 build/MilBridge/W126A-report.md                    |  10 +-
 build/MilBridge/W127A-report.md                    | 169 +++++++++++++++++++++
 build/MilBridge/tools/defect-registry-declared.tsv |  17 ++-
 docs/ROUTES.md                                     |  34 ++++++-
 samples/WpfFeatureProbe/KNOWN-DEFECTS.md           |  50 +++++-
 5 files changed, 271 insertions(+), 9 deletions(-)
$ git show --stat 4d125f8 -- src/
（空 —— **未碰 `src/`**）
$ git show --stat 37def7e -- src/
 src/WpfGfx.Linux.Native/src/win32_core.c     |  60 ++++++++-
 src/WpfGfx.Linux.Native/src/win32_internal.h |   6 +-
 src/WpfGfx.Linux.Native/src/win32_x11.c      | 122 ++++++++++++++++++++++++++-
 3 files changed, 183 insertions(+), 5 deletions(-)
```

- ⇒ **① 三件 native 源确实是在 `37def7e` 被改的**（且 `src/` 下**只有**这三件）；**② `4d125f8` 确是 `git add -A` 形态** —— 它的 5 件清单**恰好等于当时克隆里除"W126A 自己的报告"以外的全部脏件**，其中 **`W127A-report.md`／`ROUTES.md`／`KNOWN-DEFECTS.md`／声明表就是本车道那 4 件**（这正是"我这 4 件为何由 W126A 的第 2 笔带上远端"的原因）。
- **时间线（14 秒）**：W131A 改源件 `mtime = 11:49:23` → `37def7e` 提交于 **11:49:37** ⇒ 那一笔把 W131A 的**在办**树扫进了"冻结 `#52`"这一笔。
- ⚠️ **边界（机械证）**：`~/w131a/` 内 **零 `git`／`git push` 痕迹**（五类关键词 `grep -rln` 无命中），且它自己的 `LANDING-CHECKLIST.md` §0 闸门**尚未勾选**（按主控裁定它**要等 `POST_ALL_DONE`** 才落）⇒ **不是 W131A 推的**；本车道那一笔**只 add 了 4 件** ⇒ **也不是本车道夹带的**。

### ③ 处置（还原 ＋ 该笔）—— 含**一处必须更正的指令**

⚠️ **主控第 2 步给的 `git checkout 37def7e^ -- <三件>` 不能执行**（本件**停手并复核**后才动手）：`37def7e^` 的值 = **`e0cbc965772d06c1`／`6477af56fdcfdf20`／`e4f2de8d038e4780`**，即 **`#51` 的态**，**既不等于冻结块声明值，也会把 `#52` 的产品侧改动（`D-G100`）一起回退掉**。⇒ 按"**还原到 `#52` 冻结态**"的字面目标，正确源头是 **W131A 的开工备份**（`~/w131a/backup/{win32_core.c,x11,internal.h}.orig`；值 = `3117923a7c899e05`／`11142fbef049eb66`／`e4f2de8d038e4780`，**与冻结块声明逐位相同** —— 本件**从 AB 冻结块正则现取声明值**再比对，**不手打**；三件全 `MATCH`）。
- ⚠️ **本件自记一处操作小错**：第一版对照脚本里我把 `x11` 的期望值**手打成 `11142febf049eb66`**（多一个 `e`）⇒ 打出一次假 `MISMATCH`；**随即改为"从冻结块现取"**并重跑 ⇒ `MATCH`。留档理由 = **"不许手抄哈希"**这条纪律是我自己写在 `criteria.md` 里的。
- **另核：W131A 是否还改了别的件** —— `git show --stat 37def7e -- src/` 只有那三件；`37def7e^` 的另外 13 件属 W126A 自己的收尾链（未动，本件不碰）。
- **提交**：`1890b007985709b079112e167f455bbe91f8da58`（`revert(#52): 还原被 git add -A 夹带进 37def7e 的 W131A 在办 native 源至 #52 冻结态…`；**逐径 `git add` 三件、无 `-A`**）。

### ④ 口径句

> **在克隆里一律逐径 `git add`；`git add -A` 会把别的车道的在办件夹带进发布。**

### ⑤ `$R` 未动、W131A 的工作未受影响

- 本件**只改克隆**（`~/netTest/GitProj/WPFOnLinux`）；`$R` 的 `src/**` **一个字节都没写**（`$R` 侧仍是 W131A 的值 —— 见下 `BYTECHECK` 的"`$R`=不同(本地领先,预期)"那一列）。
- `ACCEPTANCE-BASELINE.md` = **`27293fb5ab91b778`**（克隆 HEAD 与 `$R` 两侧**同值**）、`docs/CURRENT-STATE.md:9` = **`gen=#52`**（两侧同值）⇒ **未被任何人动**。
- **`BYTECHECK`（还原笔）**：判据 = **远端 blob == 克隆工作树**；**`ok=3 mismatch=0 nobody=0`**；`$R` 单列并**明确预期不同**（W131A 领先）：`core`/`x11`/`internal.h` 三件**全部**"远端==克隆 ✔ ｜ `$R`=不同"。
- **推送后 head**：`3faedc3f4e9f0a0697783abb48425eedc1d302f0` → **`1890b007985709b079112e167f455bbe91f8da58`**；`HEAD = remote-tracking = ls-remote` **三者一致**；`--symref` 仍 `feat-Linux`。
- **`TASK-0109` 归属**：属 **`#53`**，将随其预登记与收尾链正式落地（本件**不**替它登记）。

（末两行 = 本行 ＋ sha16 行；口径 `head -n -2 <本文件> | sha256sum | cut -c1-16`）
本报告 sha16 = `7f1a05372a0ae215`
