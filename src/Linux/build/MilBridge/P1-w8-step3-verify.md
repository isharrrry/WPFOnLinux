# P1-W8-STEP3-VERIFY（`t105` 独立复核 · W8 第三步「`LoGetPenaltyModuleInternalHandle` 真实现」· `t103` 的件）

> **本席只读仓树、只写本件。** 对拍标准 ＝ **先写好的判据件** `build/MilBridge/P1-w8-step3-criteria.md`（**`14e1035cea86bcff`**／326 行，本席现取；其自证行 `d36092342d71b0e1` 未复算）。
> **复核对象** ＝ **入账面** `28b04be`（`feat(#81): t103 W8 第三步落地 …`，`2026-09-29T02:30:41+08:00`；`HEAD`）；上一代 ＝ `03d12ac`。`t103` 载体 ＝ `build/MilBridge/P1-w8-step3-report.md` `f4886b7487c9fc30`。
> **本席现取（`ts=2026-09-29 02:32:03.905437620 +0800`）**：`win32_pts.c` **`80b5786aef1cc823`**｜`libwpfwin32.so` **`a2de5ff2b667f33f`**（**仓内＋部署件同值**）｜`exports.txt` `1a6a415f28c6308d`／**567** 行｜托管件 `6fecbab40f639616`／`6893d1d3fb1ee110`（未随本件动）｜在册 `evidence/app_g1.log` `bf59ef38f5b8be55`｜`session.txt` `64bb907153599856`｜`leg_23.env` `f1fc16ac52965971`／`leg_24.env` `1994c45ecc05901d`｜判据工具 `pts-pages-guard.sh` `944e61f39f24631c`／`pts-gap-count-check.sh` `920326e9242f5fdd`。**A/B 的"before"极**：上一代 `.so` **`4e999451e9ab137e`**（＝在册 `DEV shim` 的上一代值，我自 `HEAD^→HEAD` 的 `git diff` 现取）。
> **仪器全部本席自造、仓外、零构建**：`python3`＋`ctypes` 直读现盘 `.so`（含 `mmap(PROT_NONE)` 反 deref 夹具、投毒出参、多上下文绑定对拍）；判据侧只跑**纯读**自检器（`pts-gap-count-check.sh`／`check-shim-coverage.py`／`pts-pages-guard.sh --legs`），**反腿一律在仓外副本文档上跑**。

---

## ① 诚实性：真按**模块句柄**绑定 ＋ 出参真落盘 ＋ **构造不出「假装成功」**（**成立**）

**第二实现（`ctypes` 直读现盘 `.so`）现取**：

| 面 | 读数 |
|---|---|
| 两上下文两模块 | `c1=0x5c2b07f8a8d0-c1` 偏移 `+0x40` 处得模块句柄 `h1=0x…a8d0`；`c2` 同理 `h2=0x…3da0`（两值相异） |
| **出参真落盘** | 先投毒 `out=0x91/0x92` ⇒ `GET(h1)`/`GET(h2)` 后 `out=0x…a8e0`／`0x…3db0`（**毒值被覆写**）；两者**相异** |
| **与对象绑定** | `out − h = +0x10`（同一结构内 internal 字段固定偏移），`h − ploc = +0x40` ⇒ 两开关都**按对象**、非全局单例 |
| **独立读取面**（不经出参） | `WpfLinuxWin32_PtsPenaltyInternalHandleAt(0)/(1)` ＝ `0x…a8e0`／`0x…3db0` ＝ 两个出参（`True/True`；交换序 `False`）；且 `…ModuleHandleAt(0)/(1)` ＝ `h1`／`h2` |
| **镜像对拍** | `PtsJmpProbe("LoGetPenaltyModuleInternalHandle", h1, …)` ⇒ `rc=1`、`addr_ok=1`；`PtsJmpProbePtr(...)` ⇒ `rc=1`、`ptr0 == internal`、`ptr1 == h1` |
| 计数与调用序吻合 | `PtsPenaltyInternalGets() = 2`、`PtsPenaltyModuleAcquisitions() = 2` ＝ 我的 2 次 acquire ＋ 2 次 GET（**自检不再扰动**，见 ⑤） |
| 拒绝面（全 `-10000` 且**清空出参**、且不 deref） | **`NULL` 模块句柄** ⇒ `-10000`（这正是 `t103` 自报的实测缺陷 (b) 的修法落点）｜未知 `0xdeadbeef` ⇒ 同｜**把一个 `ploc` 当模块句柄传入** ⇒ 同｜`internalHandle=NULL` ⇒ `-10000`（不"写空也算成功"）｜**`mmap(PROT_NONE)` 页当句柄** ⇒ `-10000` 且进程存活｜**销毁上下文后的旧句柄** ⇒ `-10000` |
| 「假装成功」 | **构造不出**：代码面 `rc=0` 只出现在"身份校验通过 ⇒ 写 `c->penalty_internal_handle` ⇒ 记镜像 ⇒ `*internalHandle = …`"链末；行为面每次 `rc=0` 都同时满足 **出参非 NULL ∧ 与独立读口相等 ∧ 与镜像 `ptr0` 相等**；`NULL`／伪造／跨类句柄一律走拒绝支并**清空出参** |
| 如实划界 | internal handle ＝**该对象另一字段自身的地址**（自指），**不是**真的 LineServices 内部句柄；判据 §1.4 把"内部算法"列为非目标、§6-N4 把下游语义列为 `NOINFO` ⇒ 本席按判据口径判"最小可辩护"成立，**不**据此说两页真排版 |

## ② 判据 `C1`–`C8` 逐条自算

- **`C1`（成立）**：`nm -D --defined-only | grep -c .` ＝ **567** ＝ `exports.txt` 行数 **567**（相等 ∧ ≥565）；`.so` `sha16 a2de5ff2b667f33f` ≠ before `4e999451e9ab137e`。**新增符号逐名点名**（vs `t103` 前代 `.so` 备份 `libwpfwin32.so.pre-t103` 的逐个 `diff`）：**`WpfLinuxWin32_PtsPenaltyInternalGets`**、**`WpfLinuxWin32_PtsPenaltyInternalHandleAt`**；**消失的符号 0 个**。
- **`C2`（成立，按判据写死的"按实际归因"口径）**：`python3 …/check-shim-coverage.py --tier mapped` ⇒ `rc=0`、**`[PresentationNative_cor3.dll] 96 条`（＝ before，不变）**；两个候选入口（`LoGetPenaltyModuleInternalHandle`／`LoDisposePenaltyModule`）在该缺口面命中 **0** ⇒ 本步**不动缺口面**（纯行为补全）⇒ **`96→96` 是正常形态**，本席**不**为凑数字做任何事。
- **`C3`（成立，主证据）**：`pts-gap-count-check.sh` 现取 `rc=0`：
  `PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567 root=…`；
  `PTSGAP_FRONTIER before=LoCreateContext@3 **after=LoDisposePenaltyModule@3** carrier_sha16=bf59ef38f5b8be55 carrier_mtime=2026-09-29 02:20:33.053874571 +0800 ts=2026-09-29 02:31:12.588146584 +0800` ⇒ **`after ≠ LoGetPenaltyModuleInternalHandle`** ✓；`PTSGAP_FRONTIER_STATE=NAMED frontier=LoDisposePenaltyModule`；`PTSGAP_CITED=PASS refs=1 strict=1`。**三格成对**：`tool/ops` 不变（`96/84`）、`impl 90→89`（`t103` 归因为 `STUB` 计数 6→5；本席只记读数，账目自洽性以工具输出为准）、`dead=11`／`artifact=1` 未动。工具另印 `PTSGAP_HISTORICAL=n=1`（自引旧代工件的历史行，不参与现值判定）。
- **`C4`（成立；**但我要点出两处口径**）**：现取原样的 `entry=` 直方图（判据 verify 的口径）＝ **`1 entry=CreateDocContext` ＋ `3 entry=LoDisposePenaltyModule`**，`entry=unknown` ＝ **0**（不增）；主跳 `LoGetPenaltyModuleInternalHandle` **3 → 0**（本席现取的直方图里**完全不出现**）✓。**本席把它拆成两个面**（判据的 verify 把二者混在一起）：
  - **台账面**（`^PTS_GAP entry=…`）：`1 CreateDocContext` ＋ `1 LoDisposePenaltyModule`；
  - **托管自报面**（`[PTS-UNAVAILABLE] … entry=`）：**`2 LoDisposePenaltyModule`**，**`CreateDocContext` 一次都没出现**。
  **回溯**：`CreateDocContext` 的**显式** `EntryPoint = "CreateDocContext"` 在上游命中 **0** —— 它是**按方法名约定**声明的（`upstream/…/PresentationFramework/MS/Internal/PtsHost/Pts.cs:3091` `internal static extern int CreateDocContext(`，其上为 `[DllImport(DllImport.PresentationNative)]` 无 `EntryPoint`）⇒ 判据 C4 的**字面** grep（`grep -n 'EntryPoint *= *"<名>"'`）**会判它不可回溯**，而按"方法名即入口名"的约定它**确实可回溯** ⇒ 记为 `F-2`（low，判据机制面）；`LoDisposePenaltyModule` 的显式声明在 `LineServices.cs:1575` ✓。
- **`C5`（成立）**：`nm … | grep -cx 'LoDisposePenaltyModule'` ＝ **1**（未回退）；`app_g1.log` 台账行在位：`511:PTS_GAP entry=CreateDocContext seq=5 err=-10000 calls=1`、`512:PTS_GAP entry=LoDisposePenaltyModule seq=6 err=-10000 calls=1`（**清理期**、晚于主跳站）。**二选一声明（本席自取）**：它**维持诚实 stub**（未升级）—— 我的 `ctypes` 现取 `LoDisposePenaltyModule(h)` ＝ **`-10000`**，重复释放／未知句柄／`NULL` **全 `-10000`**、不 deref、进程存活 ⇒ 与"不升级"的声明一致 ✓。
- **`C6`（成立）**：`leg_23` `alive=yes app_rc=143 magenta=49923 colors=844 ae=141323 ink=428491`／`leg_24` `alive=yes app_rc=143 magenta=54513 colors=852 ae=221857 ink=423833`；两腿 `NAMED … native_gap=2 native_err=-10000`（**≥ before 的 2**）；`DEV … shim=a2de5ff2b667f33f`（＝本趟 `.so`）；守卫现取 `rc=0`＋`PTS_G10_NAME=PASS observed=LoDisposePenaltyModule names=2 roster=13 domains=pts-declared`＋`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- phase=degraded`。**`app_rc=143`，不是 134** ⇒ 本步**没有**打死进程。
- **`C7`（成立）**：四值现取同趟 —— 现盘 `.so` ＝`a2de5ff2b667f33f` ＝ `gap so16=` ＝ 在册 `DEV shim=`；`carrier_sha16=bf59ef38f5b8be55` ＝ `app_g1.log` 实际 `sha16` ⇒ **`same=yes`**。
- **`C8`（成立）**：`return wpf_pts_gap("LoGetPenaltyModuleInternalHandle")` 命中 **0**；`return wpf_pts_gap("LoDisposePenaltyModule")` 命中 **1**（维持 stub，与 C5 声明一致）。

## ③ 假进度必红 `P1`–`P8`

| # | 我的夹具（**仓外副本文档**） | 读数 | 判 |
|---|---|---|---|
| **P1** | 副本把声明件 `tool=96` 改 `97`，`DECL=<副本>` 跑同一纯读自检器 | 反腿 ⇒ **`DRIFT tool decl=97 live=96`** ＋ `PTSGAP=FAIL …` ＋ **`rc=1`**；正腿（真声明件）⇒ `PTSGAP=PASS`／`rc=0` | **成立**（红＋点名；token 是 `DRIFT <字段>=… live=…`，与判据写的 `reason=decl-vs-live-mismatch` 不同 ⇒ `F-3`） |
| **P2** | 需**重编译**"清空＋`return 0`"的副本 | 未跑（禁构建）。正腿侧：真实现对成功路径给出参非 NULL＋与读口/镜像相等（① 表） | **`NOINFO`**（反腿需构建；且判据要求的 `reason=internal-handle-null-after-none` 在仪器里**无载体**） |
| **P3** | 需**重编译**"对 `NULL` 也返 0"的副本 | 正腿侧：现取 **`NULL` ⇒ `-10000` 且出参清空**（`t103` 自报的缺陷 (b) 已修，我复验） | **`NOINFO`**（同上；`reason=null-handle-accepted` 无载体） |
| **P4** | 判据要求的 `reason=entry-name-not-backtraceable` **无载体** | 正腿侧：两个具名可回溯（`LineServices.cs:1575`／`Pts.cs:3091` 方法名约定；见 `F-2`） | **`NOINFO`**（无检测器） |
| **P5** | 同（`reason=cross-run-pairing` 无载体） | 正腿侧：四值同趟 `same=yes`（② C7）；跨趟反例＝上一代 `DEV shim=4e999451e9ab137e` 配现盘 `.so` ⇒ 三值不等，按判据文字即红 | **`NOINFO`**（无检测器；手工判定可给） |
| **P6** | 我自造 **stuck 载体**（`entry=LoGetPenaltyModuleInternalHandle`）＋ `PTSGAP_FR_BEFORE_NAME=LoGetPenaltyModuleInternalHandle`＋`PTSGAP_FR_BASELINE_IMPL=999` | 反腿 ⇒ `PTSGAP_FRONTIER before=…@3 after=…@2` ＋ **`FAKE-PROGRESS impl=89 < 基线 999 而前沿仍是 LoGetPenaltyModuleInternalHandle ⇒ …（假进度） reason=ledger-nonzero-frontier-unchanged`** ＋ `PTSGAP=FAIL` ＋ **`rc=1`**；正腿 ⇒ `PTSGAP=PASS`／`rc=0` | **成立**（红 ＋ 点名 ＋ token 逐字在位） |
| **P7** | 需**重编译**"自检恒 `return 1`"的副本，并跑正/负/边界三档 | 未跑（禁构建）。可得：真实现自检在**多前置下**均为 `1/0`（⑤ 三格）⇒ 我**不能**从这三档判"有牙"；`reason=selfcheck-no-teeth` **无载体** | **`NOINFO`**（反腿需构建；**按判据写死口径不得声称成立**） |
| **P8** | 需**重编译**"把 internal handle 塞进 `int` 域"的副本 | **正腿侧我现取**：`PtsJmpProbe` 的 `int` 域 `a0..a3` **全为 0**（**没有**被塞指针），而 `PtsJmpProbePtr` 的 `ptr0 == internal`、`ptr1 == 入参句柄` ⇒ 真实现走的是**指针专用域** ✓ ⇒ "截断 ⇒ 恒不等 ⇒ 假红"的形态在**真实现**上不出现；但**反腿（塞 `int` ⇒ 必红并点名）需要重编译** ⇒ 该条**不成立/`NOINFO`** | **正腿 ✓／反腿 `NOINFO`**（`reason=pointer-truncated-in-int-field` 无载体） |

## ④ `R9` 释放相位面（**部分 `NOINFO`**）

- **现取（在册运行期读数，我的 `grep`）**：台账 `PTS_GAP entry=LoDisposePenaltyModule seq=6 err=-10000 calls=1`（**在 `CreateDocContext seq=5` 之后**，即**清理期**）；托管自报面 `entry=LoDisposePenaltyModule` **2 次**；`entry=` 面**没有**它在功能路径上早于主跳出现的证据（主跳名在该面 0 次）。
- **来源（终结器 vs 显式 `Dispose`）**：判据 §1.2 说 `:542 GC.SuppressFinalize` 若执行，来源会从终结器变为显式 `Dispose`。**现取证据里没有可直接判定来源的机器可读面**（台账只给 `entry/seq/calls`；判据 §6-N5 自己也把它列为 `NOINFO`）⇒ **本席判 `NOINFO`**，只如实记"`seq=6` 在清理期、`calls=1`、`err=-10000`"。**不按静态推断写来源。**
- **我另取的相位性质**（`ctypes`）：`LoDisposePenaltyModule` 是**空操作 stub**（不释放、不改对象状态）⇒ **`dispose(h)` 之后 `GET(h)` 仍返回 `rc=0` 与真 internal handle**（观测 `O-1`：若将来把它升级为真释放，`GET` 必须同步加"已释放"校验，否则会给悬垂句柄）。

## ⑤ 纪律第 `30` 条：三格、fresh 规矩、两种误导形态

**本席自取的三个前置（同一 `.so`、各自独立进程）**：

| 前置（第①格） | 依赖计数当时值（第②格） | 判词（第③格） |
|---|---|---|
| **fresh**（未建任何上下文） | `loc_live=0 loc_creates=0 calls=0 acq=0 igets=0` | `selfcheck=1 diag=0` |
| 建 **1 个活上下文**（未 acquire） | `loc_live=1 loc_creates=1 calls=0 acq=0 igets=0` | `selfcheck=1 diag=0` |
| 建上下文 ＋ `LoAcquirePenaltyModule` ＋ `LoGetPenaltyModuleInternalHandle` | `loc_live=1 loc_creates=1 calls=2 acq=1 igets=1` | `selfcheck=1 diag=0` |

- **两种误导形态**：载体写了（带历史的红＝假红；fresh 的绿＝假绿，需权威对象↔镜像逐字段对拍）✓。**但本席要如实点名**：`t102` 把带历史那条**假红修掉**之后，本判据 §5 里"带历史的红"这一形态在**现盘上已不再可复现**（我三档全 `1/0`）⇒ 该形态现在是**历史例证**，不是现成可演示的例子（`O-2`）。**fresh 的绿＝假绿**这一形态仍有实证（`t103` 自报的缺陷 (b) 就是"净腿绿而缺陷真实存在"，本席复验 `NULL` 现已被拒 ⇒ 该假绿已消除）。
- **`F-1`/`F-2`（我 `t98` 提的两条）在现盘已被修好（我独立复验）**：连续 `PtsGapSelfCheck()` 后 `acq 0→0`、`igets 0→0`（自检**不再扰动**两个计数面）；带历史（1 个活上下文）自检后 `loc_live` **恒为 1**（**不再泄漏**、判词 `1/0` 而非 `0/25`）⇒ `t102` 的两条修法在行为面成立。
- **fresh 规矩**：正腿我在 fresh 进程跑 ✓；带历史腿各自独立进程、历史逐条列出 ✓。

## ⑥ 零回归

成对取法：`git diff HEAD^ HEAD -- evidence/leg_23.env evidence/leg_24.env`（before ＝ 上一代在册腿，after ＝ 现盘）。

| 面 | k=23 | k=24 |
|---|---|---|
| `alive` / `app_rc` | `yes→yes` / **`143→143`（∉{134,139}）** | 同 |
| `magenta` / `ink` | `49592→49923` / `428765→428491` | `54182→54513` / `424107→423833` |
| `colors` / `ns` / `ae` | `844→844` / 逐字同 / `141985→141323` | `851→852` / 逐字同 / `221246→221857` |
| `native_gap` / `native_err` | `2→2` / `-10000` | `2→2` / `-10000` |
| `DEV shim` / `pf` | `4e999451e9ab137e→a2de5ff2b667f33f`（＝现盘 `.so` ✓） / `6893d1d3fb1ee110`（＝现盘托管件 ✓） | 同 |

- **`unh=0`**：在册 `session.txt`（`64bb907153599856`）现取 **`2 unh=0`**、`CLICK k=24 AE=221857 pts_gap=2 guard=1 fatal=0 unh=0`／`CLICK k=23 AE=141323 … unh=0`、**`APP_RC=143`**、`shim_sha16=a2de5ff2b667f33f`／`pf_sha16=6893d1d3fb1ee110`（同一趟）。
- 判：**零回归成立**（两页 `alive`／`app_rc`／`ns`／`native_gap` 稳；`magenta`±331、`ink` 微动＝重拍抖动）；**`app_rc=134` 的第二步同族形态本步未出现**。

## ⑦ 不变量 / 指纹 / 哨兵 / `D-G189`

- **覆盖面**：`infp.sh list` 现取 **234** 条（含 `evidence/app_g1.log`（第 `9` 行）／`build/MilBridge/tools/pts-gap-count-check.sh`（第 `74` 行）／`src/…/win32_pts.c`（第 `129` 行）⇒ 这三件**都在覆盖面内**）。
- **`inputs_fp`**：`ts=2026-09-29 02:32:03.905437620 +0800` ⇒ **`b59779a389683b86c1cde70f9a3c797f4728fc7228983fe4747ced5717eb35cb`**；`HANDOFF-NEXT.md` 末条 `cell=#1`（`ts=2026-09-29T02:23:23.079928989+0800`）登记现值 **`40a2b4a899dbfbe3d5f8c0e2d62101b9e…`** ⇒ **不一致**。**归因（我自己定位）**：`02:23:23` 之后 `t103`／`t104` 写了**三件覆盖面内件**（在册 `app_g1.log` 换代 `02:20`、`tools/pts-gap-count-check.sh` 被改、`win32_pts.c` 换代 `02:22`）⇒ 指纹必然移动；**本席零写**（`porcelain` 现取仅 `M` 他人在飞 4 件：`tools/pts-gap-count-check.sh`／`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`evidence/arm_A/device.txt`）。
- **两哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；字段现取 **`WIN32SHIM=a2de5ff2b667f33f`（＝现盘 `.so` ✓）**、**`PF=6893d1d3fb1ee110`（＝现盘托管件 ✓）**、`WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b27ff6332f263495`（未变）⇒ `.so` 换代后哨兵**已同趟更新**、**不该重写**（R8：**只有 `win32shim` 位移动**，且该位移在 `pts-gap-decl.txt` 的 `so16=` 里**有声明**）。
- **九位**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:66` 的九位行是 **#79 期历史行**（`win32shim 6825dd7071387a46` 等），`porcelain` 无该件 ⇒ 本波**未**改它；现盘九位以哨兵为准（见上）⇒ **无未声明位移动**。
- **`D-G189`**：注册表现取 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`feadeeec014f06de`，`M`＝`t103`／`t104` 在飞）里 `D-G189` 出现 **3** 次 ＝ `git show HEAD:` 版 **3** 次 ⇒ **未被虚假扩大**。

## Findings（不改 `t103` 任何件；要改的以「夹具＋读数」给出）

- **`F-1`（medium）托管自报 `entry=` 的**口径**会在多缺口态下**指错人**（本步首次可观测）**：`NativeEntryName()` 取的是**在册表序最后一个有缺口计数**的入口名（`GapEntryNameAt(count-1)`，`t90` 之后的既定口径），不是"这次失败站点的入口"。现取：台账**同时**有 `CreateDocContext seq=5` 与 `LoDisposePenaltyModule seq=6`，而托管面 `[PTS-UNAVAILABLE] … entry=` **两次都写 `LoDisposePenaltyModule`**、**一次都没写 `CreateDocContext`**；判据 C4 的 verify（直方图把台账行与托管行**混在一起**）因此给出 `1 CreateDocContext ＋ 3 LoDisposePenaltyModule`，**读不出"这条是运行期哪个站点撞的"**。⇒ 判据侧要"哪条入口被撞"必须**分开读台账**（`^PTS_GAP entry=`）；托管 `entry=` 只可当"具名位移"的粗证。**夹具**：`grep -o '\[PTS-UNAVAILABLE\][^"]*entry=[A-Za-z0-9_]*' app_g1.log | grep -o 'entry=…' | sort | uniq -c` 与 `grep -o '^PTS_GAP entry=…' | sort | uniq -c` 分开跑（我贴的两条读数即此）。
- **`F-2`（low）判据 C4 的"可回溯"机制只认显式 `EntryPoint=`**：`CreateDocContext` 在上游**没有** `EntryPoint = "CreateDocContext"`（`grep -rn` 命中 **0**），它是按**方法名约定**声明的（`Pts.cs:3091`＋其上 `[DllImport(DllImport.PresentationNative)]`）⇒ 判据的字面 grep 会把一个**合法可回溯**的名字判成不可回溯。修法（判据件）：回溯判据补一支"`[DllImport(...)]` ＋ 同名 `extern` 方法"的形态。
- **`F-3`（low）`P1`–`P8` 的 token 多数无载体**：现取 `build/MilBridge/tools/**` 里 `decl-vs-live-mismatch`／`internal-handle-null-after-none`／`null-handle-accepted`／`entry-name-not-backtraceable`／`cross-run-pairing`／`selfcheck-no-teeth`／`pointer-truncated-in-int-field` **命中全为 0**（只有 `ledger-nonzero-frontier-unchanged` 在册）；`P1` 实际红是 `DRIFT <字段>=… live=…`。⇒ 按 §3 总则的**字面**口径，P2–P5／P7／P8 的"必红并点名"**今天拿不到**；其中 P2／P3／P7／P8 **还需重编译**（禁构建）。
- **`O-1`（观察）stub `LoDisposePenaltyModule` 之后 `GET` 仍成功**：现取 `dispose(h) ⇒ -10000`（空操作），随后 `GET(h) ⇒ rc=0` + 真 internal handle。今天无害（no-op），但**若将来升级为真释放**，`GET` 必须加"已释放"校验，否则会返回悬垂句柄。
- **`O-2`（观察）§5 的一种误导形态在现盘已不可演示**：`t102` 修掉带历史假红后，三档前置都是 `1/0`⇒ 判据 §5 用来教学的"带历史的红"只剩**历史实例**；建议判据件 dated 追加一句"该形态已随 `F-1` 修法消失，现存的对照是 P2/P3 的未实现/已实现两态"。
- **`O-3`（观察）`R9` 的来源判定无机器可读面**：台账只给 `entry/seq/calls`，判不出"终结器 vs 显式 `Dispose`"（与判据 §6-N5 同结论）。

## `NOINFO`（不折绿、不折红）

1. **`P2`／`P3`／`P7`／`P8` 的反腿**：需重编译副本 ⇒ **禁构建**未跑（正腿侧读数已在 ③ 给出）。
2. **`P4`／`P5` 的检测器**：对应 `reason` token 无载体（`F-3`）⇒ 只能手工判定。
3. **`R9` 的调用来源**（终结器 vs 显式 `Dispose`）：现取证据无该机器可读面（`O-3`）。
4. **`CreateDocContext` 抛出的 `PtsException` 落在哪一层被接住**（判据 §6-N3）：运行期证据只到 `entry=`／台账面；接住层未现取（本席不按静态推断写）。
5. **`penaltyModuleInternalHandle` 的下游语义**（判据 §6-N4）：仓内无 LS 规格。
6. **"两页真排版"**（判据 §6-N8）：本步只补一个入口；本件**不**把任何绿读成排版成功。
7. **整趟门禁 / 真实显示面 / 跑腿面**：本任务禁跑整趟门禁、禁占显示位、禁跑腿 ⇒ 未跑。

---

SELF-SHA16 （口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 024a6a907faf69c7
