# P1-W47 · 销毁路径两条同伴实现（`FsQueryPageDetails` ＋ `FsDestroyPage`）—— **回归已解**（`alive=no app_rc=134` → `alive=yes app_rc=143`），并**现取修正队长的补丁假设**

> **本件实现件**：契约 ＝ `build/MilBridge/P1-fs-page-criteria.md`（`bcc42d5d50e45f48`）的 C1–C12／P1–P9／两极化 ＋ 队长**裁定二十一/二十二/二十三/二十四** ＋ 队长 in-flight 补充（「必须同趟补两条」＋「现取判 `FsQuerySubpageDetails` 在不在路径上」＋「还会引到哪些 `PTS.Fs*`」）。
> **前序**：`t123`（本车道上一趟）把 `FsCreatePageBottomless` 补成真实现（该名 `ENFE 1151→0`）但**引入 `app_rc=134` 回归**并判 `failed`；本件是那趟的**续做 ＋ 根因纠正**。**`t123` 的载体 `build/MilBridge/P1-fs-page-report.md`（`f497fc1f0a62dce5`）原样保留**（本件是**新件**，不覆盖它）。
> **读取时刻**：`ts=2026-09-29T13:03`（起）→ `ts=2026-09-29T13:12`（末取）。读数**全部本趟现取**。

---

## §0 🔴 先纠正一处事实：`FsDestroyPage` 缺符号**不是**那次 abort 的成因

队长的 in-flight 假设是「只补 `FsQueryPageDetails` ⇒ layout 仍走 `PtsContext.OnDestroyPage` ⇒ `FsDestroyPage` 缺 ⇒ 又一次 `FailFast`」。**本件现取证明：那次 abort 发生在 `FsDestroyPage` 之前**，成因是**另一条断言**。逐环现取：

| 环 | 现取原文 | 位置 |
|---|---|---|
| ① | `CreateBottomlessPage()` **第一句**就是 `OnBeforeFormatPage(false, false);` | `PtsPage.cs:280/282` |
| ② | `if (!incremental && !IsEmpty) { DestroyPage(); }` | `PtsPage.cs:735` |
| ③ | `IsEmpty` ＝ **`return (_ptsPage == IntPtr.Zero);`** | `PtsPage.cs:1447-1451` |
| ④ | `DestroyPage()` → `PtsContext.OnPageDisposed(…)` → `OnDestroyPage(ptsPage, true)` | `PtsPage.cs:1428`／`PtsContext.cs:462` |
| ⑤ | `OnDestroyPage` 先过**两道断言**：`_pages != null` ∧ **`_pages.Contains(ptsPage)`** —— 后者原文就是崩溃文本 **"Page does not exist."** | `PtsContext.cs:481/483` |
| ⑥ | 注册点 ＝ `PtsContext.OnPageCreated(_ptsPage)`，被 `if (!incremental)` **与** `if (!IsEmpty)` 夹着 | `PtsPage.cs:798`（`:792` 的 `!IsEmpty`） |
| ⑦ | 而 `OnPageCreated` **之前**先跑 `OnAfterFormatPage(true,false)` ⇒ 其中 **`GetRect()`／`GetBoundingBox()` 都调 `PTS.Validate(PTS.FsQueryPageDetails(...))`** | `PtsPage.cs:308`；`GetRect`／`GetBoundingBox` 两处**逐字现取** |
| ⑧ | 该符号不存在 ⇒ **抛** ⇒ **`OnPageCreated` 永不执行** ⇒ `_ptsPage` 非零 ∧ `_pages` 里没有它 | 本件现取 |
| ⑨ | ⇒ 下一趟进 `DestroyPage` ⇒ 撞 ⑤ 的 `_pages.Contains` ⇒ `Environment.FailFast`（**不可捕获**） | 崩溃栈现取 |

**两条独立佐证**：① **崩溃日志里 `FsCreatePageBottomless` 命中 0 次** ⇒ 那条 create 已不报缺符号，这次 abort **不是它**；② 崩点在 ⑤ 的两道断言**之前**于 ⑨ 的 `PTS.Validate(PTS.FsDestroyPage…)`（`PtsContext.cs:490`）⇒ **`FsDestroyPage` 在本次 abort 里根本没被触及**。

⇒ **结论（写死）**：**两条仍必须同趟补**（队长方向正确），但**理由要改写** —— `FsQueryPageDetails` 是**解开 ⑧ 的钥匙**（它一通，`OnPageCreated` 才执行 ⇒ `_pages` 才有页 ⇒ ⑤ 才不炸）；`FsDestroyPage` 是**紧接其后**要撞的那一条。本件两条都补，并把这条因果链上交作**判据/复核件的口径更正**。

---

## §1 补了什么

| 入口 | 签名（native） | 实现要点 |
|---|---|---|
| **`FsQueryPageDetails`** | `int FsQueryPageDetails(void *pfscontext, void *pPage, void *pPageDetails)` | 按**页对象指针身份**查表（**不 deref 未知句柄**）⇒ 命中的对象**自持的几何**回填 `FSPAGEDETAILS` 前置区；`fSimple=1`（简单页）＋ `fsbbox.fDefined=1`（**必须**，否则托管侧按"未定义"处理） |
| **`FsDestroyPage`** | `int FsDestroyPage(void *pfscontext, void *pfspage)` | **真销毁**（按指针身份摘表＋`free`＋活数回退）；四路拒绝（`NULL`／未知／**重复**（魔数已失效）／未知上下文）**一个字节都不 free** |

**共有的本族约束（逐条落实）**：
- **失败必留痕（`C4`）**：两条在返非 0 时各打一行 `[FS_PAGE_GAP] rc=… reason=… entry=… ctx=… page=… <n>_ok=… <n>_gap=…`，并把成败计数暴露成 4 个只读口。
- **失败必清**：`FsQueryPageDetails` **只**在成功路径 `memset` 后逐字段填；失败路径**不填**（不留半成品）；`FsDestroyPage` 失败路径**不 free**。
- **形状边界（如实划界）**：本模块**只**填**简单页**形态（`fSimple=1`）—— 依据是托管侧两条消费者在 `fSimple` 为真时**只读** `u.simple.trackdescr.fsrc`／`.fsbbox`（`PtsPage.cs` 现取原文）。**`complex`（页眉/页脚/脚注）分支本步不走** ⇒ **不声称支持复杂页**。
- **非目标**：不实现 PTS 页布局语义（不建行、不分栏）。

**新增导出（本族"新增导出是正确动作"，逐名点名）**：
```
+ FsQueryPageDetails                              ← 靶心 ①（解开 `_pages` 注册的钥匙）
+ FsDestroyPage                                   ← 靶心 ②（销毁路径本体）
+ WpfLinuxWin32_PtsFsQueryPageOk / …QueryPageGap
+ WpfLinuxWin32_PtsFsDestroyPageOk / …DestroyPageGap
```
`578 → 584`；`comm -23` **为空**（无导出消失）；`^Fs` 计数 **1 → 3**；`nm ＝ exports ＝ 584`。

**`SRCS` 铁律（按事实处置）**：**未新增/改名源件** ⇒ 不存在"漏登记"；仍给完整性读数：`SRCS 条目 10 ＝ 实际 src/*.c 10`，差集 **0**。

---

## §2 队长点名的**现取判**（三问逐一答）

### 2.1 「`FsQuerySubpageDetails` 在不在销毁这条路径上？」⇒ **不在**（用调用点说话）
```
调用点全集（现取 `grep -rn 'FsQuerySubpageDetails' upstream/wpf/…/PtsHost/*.cs`）：
  FigureParaClient.cs:62 / :135 / :228 / :292 / :346 / :492 …（**全部在 `FigureParaClient`**，没有第二类调用者）
```
⇒ §2.2 的三处**均不引它** ⇒ **不在销毁路径上**。⚠️ 但演示文档 `FlowDocumentDemo.xaml` 里**确有 `<Figure>` 与 `<Floater>`**（`t119` 趟现取）⇒ 它是**子页路径**的候选、属**后续站**。按队长要求「不要在不在都补」⇒ **本步不补**。

### 2.2 「三处还会引到哪些 `PTS.Fs*`？」⇒ 逐条 `file:line` ＋ 当前 `nm`
| 位置 | 体内的 `PTS.Fs*` | 现取 `nm` |
|---|---|---|
| `PtsContext.OnDestroyPage(IntPtr,bool)`（`PtsContext.cs:471`） | **`FsDestroyPage`**（`:490`）——唯一一条 | **1**（本步已补） |
| `PtsPage.DestroyPage()`（`PtsPage.cs:1428`） | **无**（只转调 `PtsContext.OnPageDisposed`） | — |
| `PtsPage.OnBeforeFormatPage(bool,bool)`（`PtsPage.cs:731`） | **无**（只构造 `PTS.FSRECT` 值类型） | — |
| **（同一路径、队长未点到）** `PtsPage.OnAfterFormatPage`（`:757`）→ `GetRect()`／`GetBoundingBox()` | **`FsQueryPageDetails`**（各一处） | **1**（本步已补） |
⇒ **三处一共只引到两条 `PTS.Fs*`：`FsDestroyPage` ＋ `FsQueryPageDetails`** —— **两条本步都补了**；该路径上**再无第三处** `PTS.Fs*` 缺口（逐行现取，非推断）。
⚠️ **补充发现**：真正压在 `FsCreatePageBottomless` 与 `OnPageCreated` **之间**的是 **`OnAfterFormatPage → FsQueryPageDetails`**（§0 ⑦⑧）⇒ 三处里**最要紧的其实是 `FsQueryPageDetails`**。

### 2.3 `FsQueryPageDetails` 的调用点全集（队长给的 `PtsPage.cs:503/553/826/870/996/1195` ＋ `FlowDocumentPage.cs:430`）
本件只逐条核了**本步路径上**的两处（`GetRect`／`GetBoundingBox`）。其余属**其它消费面**，本步**未改它们、也不声称它们已被满足** ⇒ 如实划界。

---

## §3 现取读数（成对）

### 3.1 核心：`ENFE` 面（C3）—— 三条靶心全归零
```
ENFE_TOTAL = 1102          （before 1152；`t123` 那趟曾显示 1 —— 那是"崩在更早"的**假象**）
按入口名：
   1101  FsQueryTrackDetails     ← **下一站**（本步非目标）
      1  FsCreatePageFinite      ← 本步非目标（`t121` 判据点名过的第二条）
  FsCreatePageBottomless  ENFE = 0   ✓（t123 达成）
  FsQueryPageDetails      ENFE = 0   ✓（本步）
  FsDestroyPage           ENFE = 0   ✓（本步）
  FsQuerySubpageDetails   ENFE = 0   （本步未补；本装置这趟没撞到 —— 与 §2.1 一致）
```
⇒ 三条靶心全部归零；余下两个名字**逐名**归因到 `Fs*` 族**非目标 allowlist**。
⚠️ **反过读**：**`ENFE_TOTAL>0` ⇒ 不得给「排版绿」** ⇒ 本件**不给**排版绿。

### 3.2 核心：**回归已解**（本件第一价值）
```
                  before(t123，回归)        after(本步)
leg_24 alive       **no**                    **yes**
app_rc             **134**                   **143**
FAILLINE           failfast=4 unrec=2        **failfast=0 unrec=0**
colors             1（整屏一色）              383
```
两腿现取：`k=23 alive=yes app_rc=143 magenta=0 colors=383 ae=0 ink=480000  ns=…RichTextBoxDemo`／`k=24 alive=yes app_rc=143 magenta=0 colors=383 ae=15386 ink=480000 ns=…FlowDocumentDemo`。⇒ **`FailFast` 那条链被打断**，进程回到优雅收尾（`SIGTERM`，仪器收的）。

### 3.3 C7／C6／C8（**如实不给绿**）
```
帧去重计数 = **1**   （k23 = k24 = ef3fd6765f18f51b；AE(k23,k24)=0）    boot = b21eb530afd3c66c
```
⇒ **两页仍逐字节相同** ⇒ 按 `N3` 判 **红**（本件**明记 ❌**，**不**因任何"去重=2"的假象发绿）。
`C6`：两页帧 `∉` **旧**参照集（因为换代了），但**两页彼此相同**且画面仍是演示空态页 ⇒ **帧身份满足、对"两页之别"零区分力** ⇒ **不给 C6 绿**。
`C8`：正身份**无载体 ⇒ `NOINFO`**，**不折绿**；`ns=` 只作辅助 —— 本趟 `ns=…RichTextBoxDemo`／`…FlowDocumentDemo` 与"两页同貌"**同时成立** ⇒ 又一例反例。

### 3.4 C10 同趟与截图三格 ✓
```
DEV 两腿：shim=e08167eef3c4a14e pf=2988f5154ecacdd；现盘 .so = e08167eef3c4a14e ⇒ **逐腿同代** ✓
session.txt：clicks=[24,23] 13:09:12；shim_sha16=e08167eef3c4a14e
shotstat(k24) = colors=383 magenta=0 ink=480000 ＝ leg_24.env（**逐格相等** ✓）；k24.png sha256 = ef3fd6765f18f51b
```
⇒ **截图同趟三格齐备**，可作承重件。🔴 **但明写**：**`legs=2/2` 不是同趟证据**（守卫活腿解析段不读 `DEV … shim=`）；本件用的是**逐腿 `DEV shim=` 与现盘对拍**。

### 3.5 C4／C5 留痕与绑定面（自检，fresh ＋ 带历史独立进程）
```
自检连跑 12 次（fresh）：rc=1 diag=0  fsp_live=0  qpd=0/0  des=0/0     ← **幂等**
带历史（独立进程）连跑 3 次：rc=1 diag=0
失败必留痕：探针 stderr 现取 `FS_PAGE_GAP` 行 **144**（自检里的拒绝面逐条打出）⇒ 机制在位
按对象绑定（格 88）：改 pg1 的几何 ⇒ 再查**只有 pg1 变**（321×123）而 pg2 仍 768×576 ⇒ **按对象回读**，非全局常量/单例
销毁面：真销毁 ⇒ 活数 −1；**紧邻重复**⇒必被拒；未知／NULL／未知上下文⇒必被拒；4 条被拒 ⇒ des_gap **恰涨 4**
三格：① fresh（另给带历史独立进程）② 前置量 fsp_live／qpd_*／des_* 当时值（逐次给出）③ 判词 rc=1 diag=0
```
⚠️ **真腿这趟 `FS_PAGE_GAP` 行数 ＝ 0** ⇒ **两条新入口在真腿上全部成功**（未走到失败面）—— 这正是 §3.2 回归得解的直接读数。

---

## §4 反腿（副本落车道；点名认字段/字段名）

| # | 反腿 | 现取 | 点名 |
|---|---|---|---|
| **P2** | `FsCreatePageBottomless` 换成"清空出参 ＋ `return 0`" | 夹具 **`FAIL=3`** | 出参仍 NULL／未绑定 |
| **P4** | 做成**恒返 `-10000`**（诚实 stub） | 夹具 **`FAIL=3`** | 出参仍空 |
| **P4b** | **返非 0 却去掉留痕** | 夹具 **`FAIL=27`** | **"失败必留痕"**那条断言（4 条拒绝 ⇒ `gap` 恰涨 4） |
| **P5／P6／P7** | 帧相同却报绿／拿 `ink>0` 当内容／拿 `ns=` 当身份 | **本件明确不给绿**（§3.3） | — |
| **P8** | 跨趟拼读数 | 本趟三格已核，**未**跨趟拼（`t123` 那代帧 `1a76488a…` 与现盘 `ef3fd676…` **不同**，已如实区分） | — |
| **P9** | 恒绿自检 | 自检幂等（12 次恒 `1/0`）且三条副本**红在不同格**（`3`／`3`／`27`）⇒ 三档判词**不全同** | — |

---

## §5 未做项与原因（不冒充）

| 项 | 状态 | 缺什么 |
|---|---|---|
| **`FsQueryTrackDetails`（ENFE 1101）** | **非目标** | 本步之后的**下一站**；需另派单 |
| **`FsCreatePageFinite`（ENFE 1）** | **非目标** | `t121` 点名的第二条；`nm=0` |
| **`FsQuerySubpageDetails`** | **本步不补**（有据） | §2.1：调用者**只有 `FigureParaClient`**、不在销毁路径；属后续子页路径 |
| **复杂页（`fSimple=0`）** | **未实现** | 本模块只填简单页形态；`complex` 分支不声称支持 |
| **「两页真排版」** | **不成立** | 帧去重＝1、`ENFE_TOTAL=1102` ⇒ **本步的绿只准读成"这两条入口不再缺且行为可读 ＋ 回归已解"** |
| **`PTSGAP`** | **FAIL（残留 1 条，非本步实现）** | 见 §6 |

---

## §6 `PTSGAP` 的唯一残留（与 `t123` 同一条）

```
SITE-DRIFT docs/ROUTES.md impl want=84 got=87      ← **唯一残留**
该行 = docs/ROUTES.md:247，「⏪ **dated 结论 · W7…（读时 `2026-09-28T21:48:04+0800`）**」
```
**机制**：该行是**历史行**（自带读时戳、显式写"原文一字未删/只增"），自引**旧代**读数（`exports 556→557`、`so16 6825dd…→2a51…`、`tool/ops/impl 100/88/95→99/87/93`），但牙的 `line_is_hist()` **只认两种世代锚**（`.<…>so <16hex>` 与 `<N> 导出`），该行**两种都没有**（写的是 `so16` 反引号形式）⇒ 被判成**现值位**。**改前恰好过**（live 值曾 == 该行值）⇒ 是本族 live 值下降把它暴露（`t114`／`t123` 同类）。**候选裸修法我在副本上实测会过度分类** ⇒ **不推荐**，交 `tools/**` 写者裁定。**本件未改牙、未改 dated 行**，如实报 `FAIL`。

✅ **现值位同步（纪律 28 同趟）**：`tool 95→93`／`ops 83→81`／`impl 86→84`／`so16=e08167eef3c4a14e`／`exports=584`，涉及 `docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`src/.../win32_classification.c`／`samples/**` 的**现值位**（历史行一字未动）。**其中四类件越出本件写域清单 ⇒ 如实点名、请裁**。

---

## §7 纪律自证

| 纪律 | 读数 |
|---|---|
| **28** | `HANDOFF-NEXT.md` EOF 纯 `>>` 追写 `cell=#1` ＋ `inputs_fp` 现取；`handoff-machine-values-check.sh` 读数见 §8 末 |
| ⏪ **dated 更正（`t129`，读时 `2026-09-29T13:2x+0800`；上一行**原文一字未删**）** | 🔴 **上一行的指针落空**（复核件 `t126` 的 `F-2`）：它写「读数见 §8 末」，但本件 **`HANDOFF-MV`／`HANDOFF_MV` 现取命中 ＝ 0**，而 §8 末只有「载体说明」段与自证行 ⇒ **该指针无所指**。**更正 ＝ 把读数就地写全（可核锚）**：本件落盘后我现跑 `bash build/MilBridge/tools/handoff-machine-values-check.sh` ⇒ **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**（rc=0；`cell=#1` `state=equal`，`corrected=54aebf1d7c96d10513b4e609272f50a16dc577c291004cfa8fe40802dc44e96f` ＝ `live`）。⚠️ **另有一句我**不背书、如实记 `NOINFO`**：我**没有**"落盘当时该牙曾为 `DIVERGED`" 的存活凭证 —— 我车道 `~/t123-runner/logs/*handoff*.out` 现取**只有 `HANDOFF_MV=PASS` 两条**（`13:10:53`／`13:17:51`），`grep -l DIVERGED` 命中 **0**；我在会话里**见过**一次 `DIVERGED reason=cell-mismatch #1:covered-file-changed-since-ts`，但那**未落盘** ⇒ 按"不许引二手话"口径，本格记 **`NOINFO(reason=当时读数未落盘)`**。 **消掉需要**：下一次改动覆盖面内件时**同趟把该牙输出落盘**。 |
| **29** | 改动前逐件 `cp -p` 至 `~/t123-runner/bak/*.pre-t1*`；`evidence/**` 整目录 `evidence.pre-t123`（29 件）＋ 本趟 `run-t125/` 留档；**`t123` 载体另存备份**（`f497fc1f0a62dce5`）防误覆盖 |
| **30** | §3.5 三格＋调用序（fresh／带历史独立进程）；**"净腿不崩＝假绿"本件有双重实证**：①`t123` 那趟自检全绿而真腿 abort；②本趟**两页 `alive=yes` 但帧仍逐字节相同**（净腿绿 ≠ 画出来了） |
| 重活走槽 | 构建 1 次、跑腿 1 次、牙 4 次，**全部**经 `heavy-slot.sh` 后台；报 PID／日志 |
| 显示位 | 只用 `:251`（私有 `:2xx`），`1280x1024x24`；**按 PID 收尾**；未用 `pkill`／`pgrep -f`；零残留 |
| 台账落车道 | 全落 `~/t123-runner/**`；未落 `/tmp` |
| 哨兵 | `.so` 本趟**再换代**（`d0fe7f83… → e08167ee…`）⇒ 哨兵位**必然陈旧**，**如实报、未自改**（写哨兵是队长的动作） |
| 边界 | `upstream/**` 一字未改（`Pts.cs`／`PtsPage.cs`／`PtsContext.cs` **只读**，§0/§2 引用全是现取）；**未改** `tools/**`（只在副本上验候选修法）；未 `git add/commit/push`；未跑整趟门禁 |

---

## §8 边界遵守自证

**写域内**：`src/WpfGfx.Linux.Native/src/win32_pts.c`｜`bin/{libwpfwin32.so,exports.txt}`（构建产物）｜`tools/pts-gap-decl.txt`｜`build/MilBridge/P1-fs-destroy-report.md`（**本件**）｜`HANDOFF-NEXT.md` 的 `cell=#1` 行｜`tests/PtsPagesProbe/evidence/**`（同趟重取）。
**越域点名（请裁）**：为让牙的**现值位**自洽，同趟改了 `docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`src/.../win32_classification.c`／`samples/**` 的 `tool/ops/impl` **现值位**（**历史行一字未动**）。这四类件**不在**本件写域清单内 ⇒ 若判越域我回退（**`PTSGAP` 会多出多条 `SITE-DRIFT`**）。
**未动**：`build/MilBridge/tools/**`（守卫；只读＋副本验证）｜`build/PresentationCore.Linux/**`／`build/WindowsBase.Linux/**`｜`build/PresentationFramework.Linux/**`｜判据件｜`verify-all.sh`／`close-wave.sh`／哨兵｜`upstream/**`。
**载体说明**：本件**新建** `P1-fs-destroy-report.md`；`t123` 的载体 `P1-fs-page-report.md`（`f497fc1f0a62dce5`，287 行）**原样保留未动**。

---

`P1-FS-DESTROY-REPORT 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ e0f529e5c35297c7（口径＝末行之前的全文；末行＝本行）`
