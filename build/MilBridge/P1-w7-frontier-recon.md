# P1-w7-frontier-recon —— `TASK-0302`「下一站」此刻**能不能具名**：只读侦察 ＋ 判词

> 复核者 `verifier`（任务 `t70`，attempt 1）。**只读**：未改任何他件、未跑腿、未构建、未起显示位；本席唯一写入 ＝ 本件。
> 本件同时是 `t70` 的判词载体（队长 ④ 要求的 (甲)／(乙) 结论在此给出）。全部读数现取、带亚秒 `ts=`。
> **口径（本席自收，队长已采纳）**：`porcelain` **只说明「工作树 vs `HEAD` 的差」，不说明写者数** ⇒ 本件凡提未提交差异，一律写「**写域内存在未提交差异，归属未核**」＋逐行点名，**不据此推断并发写者**。

---

## §0 快照（现取）

| 项 | 现取值 | `ts=` |
|---|---|---|
| `HEAD` | **`7586791`**（`2026-09-28T21:22:40+08:00`） | `2026-09-28T21:48:06.502900498+08:00` |
| 失败现场 | `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` ＝ `sha16` **`cb0a3e5510b07790`**／`1137` 行；**两态一致**（`git diff --stat` 对它是 **0 行**）⇒ **本次引用可作「提交态 ＝ 工作树态」** | `21:48:41.122710418` |
| `porcelain` | 10 行（**写域内存在未提交差异，归属未核**；含 `t73`／`t74` 在飞件） | `21:49:14.514725051` |
| 判据端牙 | `src/WpfGfx.Linux.Native/tools/check-shim-coverage.py`（现取可跑，`rc=0`） | `21:48:06.502900498` |
| 关键源 | `build/PresentationFramework.Linux/PtsCache.Linux.cs`｜`upstream/wpf/…/TextFormatterContext.cs`｜`upstream/wpf/…/LineServices.cs`｜`src/WpfGfx.Linux.Native/src/win32_pts.c` | 同上 |

---

## §1 ① 候选池（我复算；命令原文 ＋ 读数）

```
python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier all     # rc=0
```

- `PresentationNative_cor3.dll` 缺口 **`99` 行**（族分解：`^Fs` **`66`**｜`^Lo` **`18`**｜其余 **`15`**）。
- **`^Lo` 族：`18` 行／`18` 个唯一名**（现取逐条）：`LoAcquireBreakRecord`／`LoCloneBreakRecord`／`LoCreateBreaks`／`LoCreateLine`／`LoCreateParaBreakingSession`／`LoDisplayLine`／`LoDisposeBreakRecord`／`LoDisposeLine`／`LoDisposeParaBreakingSession`／`LoDisposePenaltyModule`／`LoEnumLine`／`LoQueryLineCpPpoint`／`LoQueryLinePointPcp`／`LoRelievePenaltyResource`／`LoSetBreaking`／`LoSetDoc`／`LoSetTabs`／**`LocbkGetObjectHandlerInfo`**。
  ⇒ **队长读数 `17` 与我的 `18` 的差 ＝ `LocbkGetObjectHandlerInfo`**（它是**回调族** `Locbk*`，不是 `Lo` 动词）：按「`^Lo`」计 **`18`**；按「`Lo` 动词族（排除 `Locbk*`）」计 **`17`** ⇒ **两个口径都对，须并列写明**（我上一轮报 `16` 是漏计，现更正为 `18/17` 两口径）。
- **`Fs*` 族 `66` 行／`66` 名** ✓（与队长一致）。
- **六个候选**（`LoSetBreaking`／`LoCreateLine`／`LoCreateBreaks`／`LoCreateParaBreakingSession`／`LoSetDoc`／`LoSetTabs`）在缺口清单里**各命中 `1` 行** ⇒ 它们是 **`^Lo` 18 条的子集（6/18）**。
- **与「六名小表」的关系（须写清）**：六者**不是**「上游参考名」—— 它们在 **`upstream/wpf/**`** 里有**真实声明与调用点**（见 §2），而 `upstream/wpf` 正是**本仓的 managed 源树**（`git ls-files 'upstream/**/*.cs'` ＝ `4188` 件 vs `src/**/*.cs` ＝ `70` 件；且判据端牙自己在 `:37` 写死 `UP = ROOT/upstream/wpf`）⇒ **六者是真·可调用候选**；我上一轮「端口层零调用点 ⇒ 不在真实调用路径上」的说法**只在 `build/**`＋`src/**` 面成立**，**作为全局结论过宽**，现更正。

## §2 ② 调用序三格表（步 → 件:行 anchor → 端口层是否有 `DllImport`／台账端）

| # | 步（执行序） | 件:行 anchor（现取） | 端口层是否有 `DllImport`／台账端 |
|---|---|---|---|
| 1 | `PTS.CreateInstalledObjectsInfo`（上下文创建第 1 步的 native 调用） | 调用 `build/PresentationFramework.Linux/PtsCache.Linux.cs:726`（在 `InitInstalledObjectsInfo` 内，`:686` 起）；声明 `upstream/…/PtsHost/Pts.cs:3077` | **有**（`exports.txt` 命中 `1`；`win32_pts.c` 内定义）⇒ **已实现、非缺口** |
| 2 | `InitGenericInfo`（字段/断言，无 native 调用） | `PtsCache.Linux.cs:561` | —（无 native 步） |
| 3 | `InitFloaterObjInfo`／`InitTableObjInfo`（回调注册，无 native 调用） | `:734`／`:759` | —（无 native 步） |
| 4 | **`PTS.CreateDocContext`**（本链上**第一个 gap stub**） | `PtsCache.Linux.cs:548` | **有**且是 stub：`win32_pts.c:226` `return wpf_pts_gap("CreateDocContext")`；`exports.txt` 命中 `1` ⇒ **若到达 ⇒ 台账必有行** |
| 5 | `TextFormatterContext` 的 line-services 族（**六个候选在此层**） | 调用点 `upstream/…/textformatting/TextFormatterContext.cs`：`:113` `LoCreateContext` → **`:257` `LoSetBreaking`** → `:288` `LoCreateLine` → `:314` `LoCreateBreaks` → `:336` `LoCreateParaBreakingSession` → `:354` `LoSetDoc` → `:374` `LoSetTabs`；声明 `upstream/…/TextFormatting/LineServices.cs:1464`（`[DllImport(DllImport.PresentationNative, EntryPoint="LoSetBreaking")]`）等 | **本链上端口层无 `DllImport`**（声明在上表 `upstream` 树，`build/**`／`src/**` 命中 `0`）；`exports.txt` **六者各 `0`** ⇒ 一旦被调用**必抛 `EntryPointNotFoundException`** |

**端口层在册链（判断「第 4 步之前是否会到 native」的依据）**：`PtsCache.AcquireContextCore`（`:194`）⇒ `CreatePTSContext`（`:507`）⇒ 第 1–4 步；链的注释锚（`FlowDocumentView.Linux.cs`）＝ `BottomlessFormatter → FlowDocumentFormatter..ctor → FlowDocumentPage..ctor → StructuralCache.Section → PtsContext..ctor → PtsCache.AcquireContext`。

## §3 ③ 判别问题：**该链这一次到底有没有进 native？** —— **改写为可判形态**

**先立机制（现取源码锚）**

- `win32_pts.c:144`：`int seq = ++g_pts_seq;` **只在 `wpf_pts_gap()` 内**；而 `wpf_pts_gap()` 的**全部**调用点 ＝ `:226`／`:232`／`:239`／`:246`／`:325`／`:332`，即**六个 gap stub**（`CreateDocContext`／`DestroyDocContext`／`GetFloaterHandlerInfo`／`GetTableObjHandlerInfo`／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle`）。
  ⇒ `WpfLinuxWin32_PtsGapCalls()`（`:348` `return g_pts_seq;`）报的是**缺口 stub 命中数**，**不是「任何 native 入口调用数」**；**两个真实现**（`LoCreateContext` `:284`／`LoDestroyContext` `:304`）**不递增它**。
- `WpfLinuxWin32_PtsGapReport()`（`:373`）**从计数器**（`g_pts_calls[]`／`g_pts_seq`）汇总 `first=`／`last=`／`entries=` ⇒ **与 stderr 的打印预算无关**（预算只挡打印，不挡记账）。
- 该两条导出**早在 `62c7a7b`（`sync(#50)`）即在册**（现取 `git log -S`），而本次证据用的是 `shim=2a5165700a8c8579`（`evidence/arm_A/leg_23.env` 现取）⇒ **不是「旧 shim 读不到台账」**那一支。
- `PtsCache.Linux.cs:987–997` `NativeError()`：读不到 `err=` 时**回退常量** `A1_STUB_ERR＝-10000`（`:1028`）⇒ **`app_g1.log` 里的 `err=-10000` 不是「native 亲口说 -10000」的证据**。

**成对证据**

| 面 | 现取读数 |
|---|---|
| `app_g1.log` 的 `entry=` 面 | `grep -o 'entry=[A-Za-z0-9_]*' … \| sort \| uniq -c` ⇒ **`2 entry=unknown`**；逐字 `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=unknown err=-10000 action=page-placeholder（已画出页级占位；进程继续）`（`:511`／`:965`） |
| shim 台账面 | `grep -c 'PTS_GAP'` ＝ **`0`**｜`grep -c 'calls='` ＝ **`0`** ⇒ 进程内**零缺口 stub 命中** |
| 机制面 | `IsPtsUnavailable`（`PtsCache.Linux.cs:1015`）闭集 ＝ `EntryPointNotFoundException` ∨ `DllNotFoundException` ∨ `BadImageFormatException` ∨ `NativeCalls() > before`；`Describe()`（`:1030`）`Entry` **只**取自台账 |

**答**：
1. **「没进 native」这句不能由 `unknown` 推出**：`unknown` 只等价于「**零缺口 stub 命中**」（进没进 native 取决于是否调了**真实现**入口 —— 那两个**不留痕**）。
2. **但可以推出更强的一句**：本链**第一个** gap stub 是 `CreateDocContext`（第 4 步，`:548`，导出且在册）——**它没有留行** ⇒ **本次失败发生在第 4 步之前**（第 1–3 步或更早的池/构造阶段）。
3. ⇒ **第 5 步的六个 `Lo*` 位于失败点下游** ⇒ **它们不可能是本次「下一站」**（这一条是对 `t63` 六名候选表的**机制级否定**，不是「字母序/猜」的问题）。
4. 排除「native 亲口作证」支后，闭集只剩 **DllImport 三族** ⇒ 即「**某个被 managed 声明的 `PresentationNative` 入口在本 shim 里不存在**」（99 条缺口里的某一条，在 `CreatePTSContext` 之前/之中被解析）—— 而**这类异常自带入口名**（`EntryPointNotFoundException` 的消息里就有名字），端口层只是**没取**（`Describe()` 只读台账）⇒ **`unknown` 是取数缺口，不是结构性无名**。

## §4 ④ 结论：**(甲) 可具名（条件式）** —— 并给出取数方案与候选池

**答是非题**：**能具名**（(甲)）。但「怎么具名」必须换轨：

1. **具名的正确来源 ＝ 异常本身**，不是缺口清单里的猜测：`EntryPointNotFoundException` 携带入口名（`Describe()` 现只读台账 ⇒ 名字被丢弃）。
2. **推荐形态（首选，最小且不新增「假成功」面）**：在 `Describe()`／`[HC-UNHANDLED]` 那一行**加一格取数** —— 打印 `e.GetType().Name` ＋ （若是 DllImport 三族）把入口名落进 `Entry`／日志；随后**重跑一趟 `g1`**，`entry=` 面即从 `unknown` 变具名。**先取数、后补 stub** —— 取数一步就能具名，且不会引入任何新的「返回 0 的假成功」面。
3. **若确要按 `P03` 补具名 stub**，候选池应当是「**该链在失败点上游／同段的 native 入口**」，即 §2 的 1–4 步（`CreateInstalledObjectsInfo`(`:726`，已导出/已实现)｜`GetFloaterHandlerInfo`／`GetTableObjHandlerInfo`（导出，stub）｜`CreateDocContext`(`:548`，导出，stub））＋ **99 条缺口表中出现在该链上的条目**；**不是**六者（它们在失败点下游）。
4. **`NOINFO(reason=未取得运行期异常名)`**：**具体是哪一个入口**，我**没有运行期证据**（本任务明令不跑腿、不构建）⇒ 本件给的是「由调用序 ＋ 未导出事实 ＋ 空台账推出的**候选序与其排除规则**」，**不是观测量**；要把它变成观测值，就只需第 2 条那一行取数 ＋ 重跑一趟。

---

## `NOINFO`（具名，既不算绿也不算红）

1. `NOINFO(reason=未取得运行期异常名)`：见 §4.4。
2. `NOINFO(reason=未跑腿／未构建／未起显示位)`：本件全部结论来自**静态**现取（源码/台账/判据端牙/证据件），**无运行期复现**。
3. `NOINFO(reason=未核 shim 装载面)`：`DllNotFoundException`／`BadImageFormatException` 两支（属**装置面**，不是能力缺口）我**未逐支排除**；本件只排除「native 亲口作证」支，并指出其余三支都在 `IsPtsUnavailable` 的闭集里。
4. `NOINFO(reason=他车道在飞)`：`porcelain` 10 行里有 `t73`／`t74` 的在飞件（**归属未核**）；本件未引用它们的读数。

## 推翻的话 ＋ 结论

- **推翻 `t63` 六名候选框架**：六者（`LoSetBreaking`／`LoCreateLine`／`LoCreateBreaks`／`LoCreateParaBreakingSession`／`LoSetDoc`／`LoSetTabs`）**位于本次失败点的下游**（本链第一个 gap stub `CreateDocContext` 都没留行） ⇒ 无论从哪个方向挑，**都不可能**是本趟的「下一站」。
- **推翻 `t63`／队长两处对 `unknown` 的读法**：「未命中任何 **shim 入口**」应改为「未命中任何**缺口 stub**」（真实现入口不留痕）；「解析期 ⇒ 结构性无名」应改为「解析期 ⇒ **名字在异常里、只是没取**」。
- **更正本席上一轮的两处措辞**：① `^Lo` 族条数 `16/17` ⇒ 现取 **`18`（`^Lo`）／`17`（动词族，排除 `Locbk*`）**；② 「六者不在真实调用路径上」⇒ 应写「在 `build/**`＋`src/**` 面无调用点；其**声明与调用点在 `upstream/wpf/**`**（判据端牙写死扫这棵树）⇒ 是**真候选**，但与本次失败点无因果关系（下游）」。
- **结论**：**`(甲) 可具名`（条件式）** —— 前沿此刻**可以具名**，前提是补一格**取数**（异常入口名），补完重跑 `g1` 即成；而**六选一的框架作废**。W7 若要在册一句话，建议写成：**「前沿可具名，但须先取异常携带的入口名；六个 `Lo*` 候选位于失败点下游，不构成本趟前沿。」**

P1-W7-FRONTIER-RECON: t70 attempt 1 | 结论=(甲)可具名（条件式：需补取数一格，取异常携带的入口名）｜六选一框架作废（六者在失败点下游）｜候选池：PresentationNative_cor3.dll 缺口 99＝^Fs 66 ＋ ^Lo 18（动词族 17，差 LocbkGetObjectHandlerInfo）＋其余 15；六候选各 1 行｜判别：entry=unknown ⟺ 零缺口 stub 命中（g_pts_seq 只在 wpf_pts_gap() 内 ++：win32_pts.c:144；调用点 :226/:232/:239/:246/:325/:332）＋台账两导出自 62c7a7b 即在册（非读不到）＋app_g1.log PTS_GAP 0 行/calls= 0 行；err=-10000 是常量回退（PtsCache.Linux.cs:991 回退 A1_STUB_ERR=-10000 @:1028）｜本链第一个 gap stub ＝ PTS.CreateDocContext（PtsCache.Linux.cs:548，win32_pts.c:226，exports=1）未留行 ⇒ 失败在其上游 ⇒ 第 5 步六者不可能｜推荐形态：先补 Describe()/[HC-UNHANDLED] 的异常类型＋入口名取数，再决定是否按 P03 补 stub；补 stub 的候选池＝§2 步 1–4 ＋ 99 条缺口表中该链条目｜app_g1.log sha16 cb0a3e5510b07790/1137 行（两态一致，git diff 0 行）@ts=21:48:41.122710418｜HEAD 7586791｜porcelain 10 行（归属未核）｜NOINFO 4 条
