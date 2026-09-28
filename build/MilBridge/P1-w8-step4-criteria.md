# P1-W33 · W8 **第四步**预登记判据 —— 靶心 `CreateDocContext`（＋两条收尾同侪 `DestroyDocContext`／`TextPenaltyModule.Dispose` 是否必须同趟补）

> **本件是判据件（先写），不是实现件**：本件**不做**实现、**不构建**、**不跑腿**、**不占显示位**，供随后的**实现件**与**独立复核件**当契约用。
> **一切读数由我现取**（命令与输出原样贴出）；`P1-w8-step1/2/3-criteria.md` 只作**形制参照**，**结论一条不抄**；**未引任何既有报告当证据**（队长 `P1-ptsname-result.md` §8 裁定十二只作**任务来源**引用，其读数不承重）。
> **边界（硬）**：只读仓树；唯一写入 ＝ 本件；**未** `dotnet build`、**未**跑腿、**未**占显示位、**未**跑整趟门禁、**未** `git add/commit/push`；未改任何判据件／产品件／`docs/ROUTES.md`／`HANDOFF-NEXT.md`／`tools/**`／`src/**`。
> **读取时刻**：`ts=2026-09-29T02:33:45.762+0800`（起点）→ `2026-09-29T02:35:50.585+0800`（末取）。

---

## §0 快照与现取读数

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`a948b52`**（`docs(#81): t107 W8 进度盘点入账 —— 三本账/净进展/下三跳/里程碑面`） | `git log --oneline -1` |
| 工作树 | **5 个 `M` ＋ 8 个 `??`，全部属他人**（见 §7 原样清单） | `git status --porcelain` |
| 权威 `.so` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`a2de5ff2b667f33f`**（350776 B，mtime `02:22`） | `sha256sum` |
| 导出面 | `nm -D --defined-only … \| awk '{print $3}' \| grep -c .` ＝ **567** ＝ `wc -l src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **567**（`exports.txt` sha16 `1a6a415f28c6308d`） | `nm`／`wc -l`／`sha256sum` |
| PTS 桩件 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`80b5786aef1cc823`**，**1451** 行；在册名册 `k_pts_entries[]`（`:70-84`）现取 **13** 名 | `sha256sum`／`wc -l`／`sed` |
| 诚实缺口字面 | `grep -c 'return wpf_pts_gap("'` ＝ **6** 行，其中 1 行是注释（`:68`）⇒ **真 stub 字面 ＝ 5**：`CreateDocContext:252`／`DestroyDocContext:258`／`GetFloaterHandlerInfo:265`／`GetTableObjHandlerInfo:272`／`LoDisposePenaltyModule:648` | `grep -c`／`grep -n` |
| 缺口面 | `check-shim-coverage.py --tier mapped` ⇒ `扫描到 423 条`／`已有导出可用 : 308`／**`会 EntryPointNotFoundException : 115`**；**`[PresentationNative_cor3.dll] 96 条`**；**`CreateDocContext`／`DestroyDocContext` 在该面里命中都是 `0`** | 现跑（§2-C2） |
| 缺口三格 | `PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567` | 现跑（§2-C3） |
| 声明件 | `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（sha16 `e30fdadde58774e1`）的 `# PTSGAP-DECL: tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567 w66pre16=bf6b683d94549087` —— 与三格**逐位相符** | `sed` |
| **探针侧前沿** | `PTSGAP_FRONTIER before=LoCreateContext@3 after=LoDisposePenaltyModule@3 carrier_sha16=bf59ef38f5b8be55 carrier_mtime=2026-09-29 02:20:33.053874571 +0800 ts=2026-09-29T02:34:28.581280273 +0800`｜`PTSGAP_FRONTIER_STATE=NAMED frontier=LoDisposePenaltyModule（具名前沿成立）` | 同上 |
| **在册台账面**（`^PTS_GAP entry=`） | `app_g1.log:511 PTS_GAP entry=CreateDocContext seq=5 err=-10000 calls=1`｜`:512 PTS_GAP entry=LoDisposePenaltyModule seq=6 err=-10000 calls=1` | `grep -n` |
| **在册托管面**（`[PTS-UNAVAILABLE]`） | `:513` 与 `:967` **两行都是** `entry=LoDisposePenaltyModule err=-10000`；**`CreateDocContext` 在托管面出现 0 次** | `grep -n` |
| 在册证据 | `evidence/app_g1.log` ＝ **`bf59ef38f5b8be55`**（112757 B，mtime `02:20`；**已入索引且与 HEAD 同值**） | `sha256sum`／`git ls-files`／`git diff --stat` |
| 两页症状（在册腿） | `leg_23.env`（`f1fc16ac52965971`）：`LEG k=23 alive=yes app_rc=143 magenta=49923 colors=844 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=141323 ink=428491`｜`NAMED managed_unavail=1 err=-10000 native_gap=2 native_err=-10000`｜`DEV x_up=yes five_stable=yes shim=a2de5ff2b667f33f pf=6893d1d3fb1ee110`；`leg_24.env`（`1994c45ecc05901d`）：`magenta=54513 colors=852 ns=…FlowDocumentDemo ae=221857 ink=423833` | `cat`／`sha256sum` |
| 守卫 | `bash build/MilBridge/tools/pts-pages-guard.sh --legs <证据目录>` ⇒ `rc=0`；`PTS_G10_NAME=PASS observed=LoDisposePenaltyModule names=2 roster=13 domains=pts-declared`｜`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded` | 现跑 |

✅ **本趟同趟性现取 ＝ `yes`（内容口径）**：`so16=a2de5ff2b667f33f` ＝ `DEV … shim=a2de5ff2b667f33f` ＝ 现盘 `.so`。
⚠️ **但 `mtime` 面有一处必须如实记**：现盘 `.so`／`exports.txt` 的 `mtime` 是 `02:22`，而证据目录落盘在 `02:20` ⇒ **中间发生过一次重写事件**；判据只认**内容**（`sha16` 三处同值 ⇒ 同趟性成立），`mtime` 面如实登记、不当红。
⚠️ **仪器在动**：`build/MilBridge/tools/pts-gap-count-check.sh` 现盘 sha16 `920326e9242f5fdd`、mtime `2026-09-29 02:32:00`（`t106` 正在改它，`git status` 里是 `M`）⇒ 本件引用它的**输出字段名**，不引用它的实现；实现件/复核件取读数时**必须同趟记该件 sha16**。

---

## §1 ① 前置核查（本件必须给出结论）

### 1.1 上游签名与语义（原文，`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs`，sha16 `1a8575a18767a956`）

```
3090:        [DllImport(DllImport.PresentationNative)]
3091:        internal static extern int CreateDocContext(
3092:            [In] 
3093:            ref FSCONTEXTINFO fscontextinfo,    // IN:  pointer to context information
3094:            out IntPtr pfscontext);             // OUT: pointer to the FS context
3095:
3096:        [DllImport(DllImport.PresentationNative)]
3097:        internal static extern int DestroyDocContext(
3098:            IntPtr pfscontext);                 // IN:  pointer to the FS context
```
入参结构（同件 `:833-844`，原文）：
```
833:        internal struct FSCONTEXTINFO
834:        {
835:             internal uint version;                  // version number
836:             internal uint fsffi;                    // compatibility flags
837:             internal int drMinColumnBalancingStep;  // min step for col balancing algorithm
838:             internal int cInstalledObjects;         // number of installed objects
839:             internal IntPtr pInstalledObjects;      // array of installed objects
840:             internal IntPtr pfsclient;              // client data for this context
841:             internal IntPtr ptsPenaltyModule;       // Penalty module
842:             internal FSCBK fscbk;                   // FS client callbacks
843:             internal AssertFailed pfnAssertFailed;  // debugging callback
844:        }
```
返回值语义（同件 `:37-47`，原文）：
```
37:        internal static void IgnoreError(int fserr)
38:        {
39:        }
40:        internal static void Validate(int fserr)
41:        {
42:            if (fserr != fserrNone) { Error(fserr, null); }
43:        }
```
⇒ **`CreateDocContext` 的形状 ＝ (`ref 结构`, `out 句柄`) → `int`；`DestroyDocContext` ＝ (`句柄`) → `int`**；**两者都不是 `LsErr`，都是 PTS 的 `fserr`**（`fserrNone` ＝ 0；缺口值 ＝ `-10000`）。
⚠️ **声明形态（本件现取，直接决定 C10 的写法）**：`Pts.cs` 的 `DllImport` 行 **73** 条、**`EntryPoint` 出现 0 次** ⇒ **整个 PTS 面是"方法名约定"声明**（入口名 ＝ 方法名），`CreateDocContext` **没有**显式 `EntryPoint="CreateDocContext"` 字面。

### 1.2 托管调用点与失败后果（现取）

调用点（全仓 `grep -rn --include=*.cs` 只有这 3 处**调用**＋1 处注释）：
```
build/PresentationFramework.Linux/PtsCache.Linux.cs:416:  PTS.IgnoreError(PTS.DestroyDocContext(_contextPool[index].PtsHost.Context));
build/PresentationFramework.Linux/PtsCache.Linux.cs:488:  PTS.Validate(PTS.DestroyDocContext(_contextPool[index].PtsHost.Context));
build/PresentationFramework.Linux/PtsCache.Linux.cs:548:  PTS.Validate(PTS.CreateDocContext(ref _contextPool[index].ContextInfo, out context));
```
**返 `-10000` 时上层怎么走（逐跳，全部现取）**：
1. `:548` `PTS.Validate(-10000)` ⇒ **抛**（`:40-43`：`fserr != fserrNone ⇒ Error()` ⇒ 非 OOM/OOM 支走 `:73 throw new PtsException(SR.Format(SR.PTSError, fserr))`）。
2. 该抛出被 `:237 catch (Exception e)`（`AcquireContextCore` 内、`try` 从 `:229` 起）接住 ⇒ 走**毒池项清除**（`:259-275`：`created.TextPenaltyModule?.Dispose()`；`InstalledObjects` 非零则 `IgnoreError(DestroyInstalledObjectsInfo)`；`_contextPool.Remove(created)`）。
3. `:278 WpfLinuxPtsGap.IsPtsUnavailable(e, ptsCallsBefore)`（`:1274-1284`）：`PtsException` **不属** DllImport 三族，于是落到 `return NativeCalls() > nativeCallsBefore` —— 因为 `CreateDocContext` 的 stub 走了 `wpf_pts_gap()` ⇒ `g_pts_seq` 涨了 ⇒ **返回 true**。
4. `:280-281` ⇒ `_ptsUnavailable = WpfLinuxPtsGap.Describe(e); throw _ptsUnavailable;`（**具名能力闩**：以后每次布局直接在 `:202-210` 抛新实例、**不再进 native**）。
5. `Describe()`（`:1297-1317`）取 `entry = NativeEntryName()`（`:991-1023`），读不到再退回**异常文本**里的入口名（`:1304-1311`）。
6. 最终由 `build/PresentationFramework.Linux/FlowDocumentView.Linux.cs:113`（另有 `:168`／`:435`）的 `catch (PtsUnavailableException ptsGap)` 接住 ⇒ 打印 `[PTS-UNAVAILABLE]` 一行 ＋ 画**页级占位**（`WpfLinuxPtsGapTrace.Report`，`:1326-1340`）。该文件里**没有** `catch (Exception)`／`catch (PtsException)`（现取命中 0）⇒ **非 `PtsUnavailableException` 的异常不被这一层接住**。

### 1.3 两条收尾同侪的现状（**逐条现取**，这是本件第①问的核心）

| 同侪 | 上游声明／调用点 | 导出面（`nm`／`exports.txt`） | native 现状 | 调用点返回值被检查吗 |
|---|---|---|---|---|
| **`DestroyDocContext`** | `Pts.cs:3096-3098`；调用点 `PtsCache.Linux.cs:416`（`IgnoreError`）／`:488`（`Validate`） | **命中 1**／**命中 1** ⇒ **已导出** | **诚实缺口 stub**：`win32_pts.c:255-259` `(void)pfscontext; return wpf_pts_gap("DestroyDocContext");` ⇒ 返 `-10000`、不 deref | **一处查一处不查**：`:416` `IgnoreError` **空体**（`:37-39`，不抛）；`:488` `Validate` **抛** |
| **`TextPenaltyModule.Dispose`**（native 侧 ＝ `LoDisposePenaltyModule`） | `LineServices.cs:1575`；`TextPenaltyModule.cs:55-64` `Dispose(bool)` → `:59 UnsafeNativeMethods.LoDisposePenaltyModule(_ploPenaltyModule);`（**返回值被丢弃**）；`~TextPenaltyModule()`（`:39-42`）走 `Dispose(false)` | **命中 1**／**命中 1** ⇒ **已导出** | **诚实缺口 stub**：`win32_pts.c:645-649` ⇒ 返 `-10000`、不 deref、不 free | **否**（返回值被丢弃）⇒ 现形下**不会抛** |
| （附带，同族）`TextPenaltyModule` 的构造 | `TextPenaltyModule.cs:23-33`：`LoAcquirePenaltyModule` 非 `None` 即抛 | `LoAcquirePenaltyModule` = 真实现（`t97`） | — | 是（已实现，不再掐链） |

**中介调用点**（现取）：`PtsCache.Linux.cs:421` 与 `:493` 的 `_contextPool[index].TextPenaltyModule?.Dispose();`，两处**都**紧跟各自的 `DestroyDocContext` 之后（同件注释逐字：`PTS context must be destroyed first`）⇒ **次序约束 ＝ `DestroyDocContext` → `TextPenaltyModule.Dispose`**。

### 1.4 判断（**本判据写死**）

> **结论 1（同趟补 stub 的必要性）：`DestroyDocContext` 与 `LoDisposePenaltyModule` 都「已导出且已是诚实 stub」⇒ 按 `t97` 那次的教训所针对的机制（未导出 ⇒ 托管侧首次走到的释放路径撞 `EntryPointNotFoundException` ⇒ `rc=134`），本步 `NOINFO(不需要)`：本步**不需要**为它们同趟补导出/stub —— 它们已经在了。**
> **结论 2（但必须给出形态声明）：本步**确实**会第一次打开它们的**可达性**；因此两条同侪在本步一律按「**不许回退 ＋ 二选一声明**」判：`未升级（保持诚实 stub）` **或** `升级为真实现（须满足本判据 C5 的四件套）`，**声明与读数必须一致**（C5／C8 会机械对拍）。
> **结论 3（本步真正的新风险，必须点名）：`PTS.Validate(PTS.DestroyDocContext(...))`（`:488`）此前**结构性不可达**（每次 `CreatePTSContext` 都在 `:548` 抛 ⇒ 毒池项被移除 ⇒ 池里没有真上下文），本步之后**变成可达**。它的可达性有一个现成的门（`:479 if (cleanContextPool && _contextPool.Count > 4)`，注释逐字 `Leave at least 4 entries for future use.`）＋一个调度门（`:319-324` `_releaseQueue == null` 时 `BeginInvoke(DispatcherPriority.Background, OnPtsContextReleased)`）⇒ **可达不等价于已发生**。⇒ 本判据**不预判**它是否发生，而是要求实现件/腿证据**给出它到底发生了没有的机器证据**（见 C5③、C6、P11）。

**理由（逐条给现取证据位）**
1. **运行期定靶（台账口径，`F-1` 更正后）**：在册台账面现取 `:511 entry=CreateDocContext seq=5`、`:512 entry=LoDisposePenaltyModule seq=6` ⇒ 应用链上**第一个真的被撞到并如实失败的站 ＝ `CreateDocContext`**（`seq=5` 最小者）；`LoDisposePenaltyModule` 是**紧随其后的清理期**站（`seq=6`）。
2. **⚠️ 为什么不能拿托管 `entry=` 面定名（队长 `t105` 的 `F-1`，本件**独立复核**了机制）**：
   - 托管取数口 `NativeEntryName()`（`PtsCache.Linux.cs:991-1023`）第一路读报表 `last=`，第二路是 `:1009-1014` —— **`int cnt = PtsGapCountNative(); if (cnt > 0) { nm1 = GapEntryNameAt(cnt - 1, GapNameCap); }`**；
   - native 侧 `WpfLinuxWin32_PtsGapEntryName(idx, buf, cap)`（`win32_pts.c:752-768`）是 `for (i = 0; i < WPF_PTS_ENTRY_COUNT; i++) { if (g_pts_calls[i] <= 0) continue; if (seen == idx) … seen++; }` ⇒ **按 `k_pts_entries[]` 表序枚举"有缺口计数的入口"**，`idx = cnt-1` ＝ **表序最后一个**；
   - 现册表序里 `CreateDocContext` ＝ `idx 2`、`LoDisposePenaltyModule` ＝ `idx 12`（`:70-84` 逐行可数）⇒ **两个缺口同时存在时，该口返回 `LoDisposePenaltyModule`**；
   - **实测一致**：托管面两行（`:513`／`:967`）**都写 `LoDisposePenaltyModule`**，`CreateDocContext` **一次都没写**。
   ⇒ **结论：多缺口态下托管 `entry=` 面会指错人；"被撞入口／下一跳"只许按台账面（`^PTS_GAP entry=` 按 `seq=` 排序）定名。**
3. **`DestroyDocContext` 今天不影响功能路径**：`:416` 用 `IgnoreError`（空体）；`:488` 用 `Validate` 但受 `:479 Count > 4` 门控 ⇒ 现形下不掐链（这也是为什么现册把它列在**创建链之外**）。
4. **`LoDisposePenaltyModule` 今天不掐链**：返回值被丢弃（`TextPenaltyModule.cs:59`）⇒ 现形下它返 `-10000` **不会被任何托管断言看见**。
5. **`t97` 的教训不直接适用**：那次是"**提供句柄的入口变真** ＋ **对端入口未导出**"的组合 ⇒ 托管侧**首次**执行到 finalizer 释放路径时撞 `EntryPointNotFoundException`。本步对应组合是"**提供句柄的入口变真** ＋ **对端入口已导出（诚实 stub）**" ⇒ **缺符号这件事不存在**。

### 1.5 本步**会**第一次打开哪条托管侧路径？（**代码级点名**；不预判运行期会被撞的**入口名**）

| 现取证据位 | 现状（before，因 `:548` 必抛） | 补完靶心后（after 的**可达**形状） |
|---|---|---|
| `PtsCache.Linux.cs:548` `PTS.Validate(PTS.CreateDocContext(...))` | 抛 `PtsException` | **不抛** ⇒ 真返 `0` ＋ 真落 `out context` |
| `PtsCache.Linux.cs:550` `return context;` | **走不到** | **第一次执行** ⇒ 返回**真上下文句柄**（不再是"毒池项 + 闩"） |
| `PtsCache.Linux.cs:235` `_contextPool[index].PtsHost.Context = <真句柄>` | 抛在赋值**之前** | **第一次赋值成功** ⇒ 池项**留在池里**（不再走 `:259-275` 的清除） |
| `PtsCache.Linux.cs:296-299` `InUse = true; Owner = new WeakReference(...); return PtsHost` | 走不到 | **第一次执行** ⇒ 该池项**成为真在册项** |
| `PtsCache.Linux.cs:202-210` 具名能力闩 | 第二页起**直接抛闩**（不再进 native） | **不再立闩** ⇒ 每次布局**都会进 native**（这是"上界被打开"的同一件事） |
| **收尾面（新可达性）** `PtsCache.Linux.cs:407`／`:472` `ptsContext.Dispose()` | 池里没有真上下文 ⇒ 无对象可收 | **第一次有真对象可收** ⇒ 进上游 `PtsContext.cs:69` |
| 　　上游内部：`PtsContext.cs:81` `Enter()` → `:85` `PTS.Validate(PTS.FsDestroyPageBreakRecord(...))`；`:99` `Enter()` → `:103` `PTS.Validate(PTS.FsDestroyPage(...))` | 同上 | **循环体长度 ＝ `_pageBreakRecords.Count`／`_pages.Count`**：页/断行记录只在**成功创建之后**入册（`PtsContext.cs:281 OnPageCreated`）⇒ **本步预期为空循环**（属**代码级推理**，见 §6-N2） |
| **收尾面** `PtsCache.Linux.cs:416`（`IgnoreError`）／`:488`（`Validate`，`Count > 4` 门控）`PTS.DestroyDocContext(...)` | 不可达 | **可达**（`:488` 的分支受 `:479` 门控） |
| **收尾面** `PtsCache.Linux.cs:421`／`:493` `_contextPool[index].TextPenaltyModule?.Dispose()` | 不可达 | **可达**（`LoDisposePenaltyModule` 已导出 ⇒ 不会 ENFE） |
| **布局面（下游第一步，非本步靶心）** `PtsPage.cs:397` `PTS.FsCreatePageFinite(PtsContext.Context, …)` | `PtsContext.Context` getter 断言 `_context != Zero` ⇒ **不可达** | **第一次可达**。`Fs*` 族在缺口面里是 **66 条**（`tool=96` 的一部分）⇒ 这是**后续跳**的候选池，**不是本步的承诺** |

⇒ **本步的"下一跳"预期是"前沿从 `CreateDocContext` 移开"，而不是"两页真排版"**；具体移到**哪个入口名**，**本件不预判**（见 §6-N1），且**只许按台账口径定名**。

### 1.6 分界句／最小可辩护实现／算「假装成功」／非目标

> **分界句（沿用前三件，逐字）**：**`return 0`（`fserrNone`）本身不是证据**；证据是「这次调用在本进程内留下了**与该对象绑定**、**可被独立读取**的状态变化」。

- **`CreateDocContext` 的最小可辩护实现（本步四件套 ＋ 一条形状约束）**：
  1. **入参形状校验**：`fscontextinfo`（`ref` ⇒ 实参是地址）为 `NULL` ⇒ **拒绝**（返非 0、**一个字节都不读/不写**）；`pfscontext`（`out`）为 `NULL` ⇒ **拒绝**（不给"写空也算成功"）。
  2. **出参真落盘且与该次调用绑定**：`*pfscontext` 指向**本次真分配**的上下文对象；**不得**是进程级全局单例（两次调用的两个句柄必须**不同**，且各自等于自己对象的地址域）。
  3. **该对象真的**带走**了入参结构里的可判定量**：至少要有**与这次调用可绑定、可独立读回**的字段（例如"收到了哪个 `pfsclient`／`cInstalledObjects`／`ptsPenaltyModule`／结构魔数"中的**至少两项**，逐项可读回）⇒ 这叫"把 `FSCONTEXTINFO` **读进了对象**"，**不是**"看了它的地址就算"。
     ⚠️ **形状约束（本步特有）**：`fscontextinfo` 是 **`ref` 一个**托管结构**（`FSCONTEXTINFO`，`Pts.cs:833-844`）** ⇒ native 侧对它的读取必须**按已校验的指针 + 有界字段逐个读**（**不许**整块 `memcpy` 一个"我以为的布局"）。**理由（现取）**：`grep -rn 'ABI\|abi-layout' src/WpfGfx.Linux.Native/` 现取有 `src/WpfGfx.Linux.Native/bin/abi-layout` 一具**未入索引**的产物，而**结构布局的权威声明在本仓只有托管侧那一份**；整块拷贝＝把"未证实的布局"当成既定事实（`D-G136` 同族：自描述 ≠ 实现）。
  4. **计数 ＋ 可独立读取**：成功/被拒各一对计数；观测镜给出"刚才是**哪个**入参结构地址、落出了**什么**句柄"；**权威**始终是上下文对象本身，自检**逐字段对拍**两者。
- **算「假装成功」**：返 `0` 但 `*pfscontext` 仍为 `NULL`／是常量／是未与本次调用绑定的全局值；或入参为 `NULL`／毒值仍返 `0`；或"只 `return 0` 而对象状态一个字段都没变"。
- **非目标（明确不做）**：不实现 PTS 的**排版语义**（不断行、不建页、不填断行记录）；**不顺带**升级 `DestroyDocContext`／`GetFloaterHandlerInfo`／`GetTableObjHandlerInfo`（除非按 C5 二选一**明写声明**）；不碰 `Fs*` 族（66 条）；不承诺两页真排版；不改应用侧仪表（`entry=` 面）；**不**顺手改 `pts-gap-count-check.sh`（`t106` 的写域）。

---

## §2 ② 判据 C1–C10

> **通用**：每条 verify **必须捕获式取 `rc`**（`cmd >out 2>err; echo $?`）；**不许**从管道末段取 `$?`（`t50`／`t55` 踩过：管道尾的 `rc` 不是那把牙的 `rc`）。
> **通用反过读句**：任何"绿"都不许被读成"两页真排版"。
> 🔴 **本步对"缺口面"的写法（第二/三步教训写死在此）**：**不硬凑数字** —— `CreateDocContext` 现取**不在** `EntryPointNotFoundException` 面里（命中 `0`）⇒ **本步的正常形态就是"缺口面不变（96）"**；**任何变化都必须按实际补了几条/导出了几条逐条点名**，不许先写死数再去凑。同理，`impl`／`tool`／`ops` **若动，必须逐条归因**（`STUB` 字面数、`tool` 的 `PresentationNative` 条数）。
> 🔴 **本步对"定名"的写法（`F-1`）**：**凡"被撞入口／下一跳是谁"的判定，一律只判台账面**（`^PTS_GAP entry=` 按 `seq=` 排序）；**托管 `entry=` 面在多缺口态下会指错人，不作为定名依据**（只作"具名位移"的**粗证**）。

### C1 构建面：源码改动真进了 `.so`
- **objective**：本增量真被编译进 `libwpfwin32.so`。
- **acceptance**：`bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >out 2>err; echo $?` ⇒ `rc=0`；`exports.txt` 行数 **＝** `nm -D --defined-only … \| grep -c .`；`.so` 的 `sha16` **≠ before**（before ＝ `a2de5ff2b667f33f`）。
- **取哪个字段**：`src/WpfGfx.Linux.Native/bin/exports.txt` 行数；`libwpfwin32.so` 的 `sha16`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >/tmp/w8s4_c1.out 2>/tmp/w8s4_c1.err; echo "rc=$?"; a=$(nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -c .); b=$(wc -l < src/WpfGfx.Linux.Native/bin/exports.txt); echo "nm=$a exports=$b equal=$([ "$a" = "$b" ] && echo yes || echo NO)"
```
- **期望形状**：`rc=0` ∧ 两值**相等** ∧ 两值 **≥ 567**（**不得下降**；若新增自检/观测口而 >567，**允许**，但须逐名点名）。

### C2 缺口面：**按实际归因，不硬凑数字**
- **objective**：`EntryPointNotFoundException` 面如实记录（本步的正常形态是**不变**）。
- **acceptance**：`check-shim-coverage.py --tier mapped` 的 **`[PresentationNative_cor3.dll] N 条`** 成对给 before/after（before ＝ **96**）；**`CreateDocContext`／`DestroyDocContext` 两个候选在该面里的命中恒为 `0`**；若 `N` 变化，**必须点名**"哪一条入口名进了/出了该面"并给出它对应的 `return wpf_pts_gap("…")` 行或导出证据。
- **取哪个字段**：工具 stdout 的 `^  \[PresentationNative_cor3\.dll\] [0-9]+ 条` 行 ＋ 逐条明细行。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier mapped >/tmp/w8s4_c2.out 2>/tmp/w8s4_c2.err; echo "rc=$?"; grep -E '^  \[PresentationNative_cor3\.dll\] [0-9]+ 条' /tmp/w8s4_c2.out; grep -cE '^  PresentationNative_cor3\.dll  (CreateDocContext|DestroyDocContext) ' /tmp/w8s4_c2.out
```
- **期望形状**：`rc=0`；条数 **按实际归因**（纯行为补全 ⇒ **96→96**）；第二值 **＝ 0**。⇒ **本条的绿不构成"前进"证据。**（把它当"前进"就是本仓 `D-G138` 的 `LABEL_ONLY_DIFF` 同族。）

### C3 台账/前沿面：**前进的主证据**
- **objective**：靶心被补后，运行期的**前沿**真的离开 `CreateDocContext`。
- **acceptance**：`bash build/MilBridge/tools/pts-gap-count-check.sh >out 2>err; echo $?` ⇒ `rc=0`；三格 `tool/dead/artifact/ops/impl` 成对；`PTSGAP_FRONTIER` 的 **`after=` ≠ `CreateDocContext`**；`carrier_sha16=` 同趟给出且**等于**现取载体 `sha16`；`PTSGAP_FRONTIER_STATE` 行在位；**同趟记该工具件自身的 `sha16`**（`t106` 在改它）。
- **取哪个字段**：`PTSGAP=`（`tool/dead/artifact/ops/impl/so16/exports`）／`PTSGAP_FRONTIER`（`before=`／`after=`／`carrier_sha16=`／`carrier_mtime=`）／`PTSGAP_FRONTIER_STATE`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sha256sum build/MilBridge/tools/pts-gap-count-check.sh | cut -c1-16; bash build/MilBridge/tools/pts-gap-count-check.sh >/tmp/w8s4_c3.out 2>/tmp/w8s4_c3.err; echo "rc=$?"; grep -E '^(PTSGAP=|PTSGAP_FRONTIER |PTSGAP_FRONTIER_STATE=|PTSGAP_HISTORICAL=|PTSGAP_CITED=)' /tmp/w8s4_c3.out
```
- **期望形状**：`rc=0`；`so16=` ＝ 现盘 `.so`；**`after=` 的入口名 ≠ `CreateDocContext`**（**不预判**它是谁）。
  ⚠️ **必须同时给出的反过读**：`pts-gap-count-check.sh` 的 `after=` 是**探针进程脸**（它按 `g_pts_seen[]` ＋ `k_pts_call_order[]` 算），与**应用链台账脸**（`app_g1.log` 的 `^PTS_GAP entry=`）**不是同一个量**；本趟现取两者就**不一致**（探针脸 `after=LoDisposePenaltyModule@3`，台账脸第一个被撞的却是 `CreateDocContext seq=5`）⇒ **C3 判绿只准说"探针脸离开了"，"链上真的离开了"必须由 C4 的台账脸另行判**（这正是 `F-1` 的同一根因，不许再犯一次）。

### C4 **台账口径**的具名位移 ＋ 托管面只作粗证（`F-1` 硬条款）
- **objective**：应用侧**台账**跟着位移；且**定名依据只许台账**。
- **acceptance**：
  - ① **台账面**：`build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 的 `^PTS_GAP entry=` 行，按 `seq=` 升序原样给出；`CreateDocContext` 的**行数与 `g_pts_calls` 计数** **after < before**（before ＝ **1 行**、`calls=1`，`:511`；最理想为 **0 行**）；
  - ② **新出现的具名（若 `after` 的台账首名是新名）**，必须用**两种声明形态之一**回溯到真实声明（见 C10）；
  - ③ **托管面只作粗证**：`grep -n 'PTS-UNAVAILABLE'` 的行数/名字如实记录，并**明写**「该面在多缺口态下可能指错人（`PtsCache.Linux.cs:991-1014` ＋ `win32_pts.c:752-768`，`GapEntryNameAt(cnt-1)` 取表序末名），**不作为"被撞入口"的定名依据**」；`unknown` 计数 **不增**（before ＝ **0**）。
- **取哪个字段**：`app_g1.log` 的 `^PTS_GAP entry=` 行（`entry=`／`seq=`／`calls=`）＋ `^\[PTS-UNAVAILABLE\]` 行。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D/app_g1.log" | cut -c1-16; echo "--- 台账面（定名唯一依据，按 seq 升序）---"; grep -nE '^PTS_GAP entry=' "$D/app_g1.log" | sed -E 's/^([0-9]+):PTS_GAP entry=([A-Za-z0-9_]+) seq=([0-9]+).*/seq=\3 entry=\2  (log:\1)/' | sort -t= -k2 -n; echo "--- 托管面（只作粗证，不作定名）---"; grep -n 'PTS-UNAVAILABLE' "$D/app_g1.log"; echo "unknown=$(grep -o 'entry=unknown' "$D/app_g1.log" | grep -c .)"
```
- **期望形状**：台账面里 **`CreateDocContext` 不再出现（或出现次数下降）**；`seq` 序**原样给出**；`unknown` **不增**（0 保持 0）。
  🔴 **禁止写法**：把台账行与托管行混成一张直方图（现取的“1 `CreateDocContext` ＋ 3 `LoDisposePenaltyModule`”**就是**这种混读 —— 它是 **2 台账行 ＋ 2 托管行**的合成，**读不出**"运行期到底哪个站撞的"）。**混读即本条判红。**

### C5 释放同伴面：两条同侪**不得回退**，且**二选一声明**与读数一致
- **objective**：本步不得让释放路径变回"未导出"或"假成功"；并如实登记**新可达性**是否真的发生。
- **acceptance**：
  - ① `nm -D --defined-only … \| grep -cx 'DestroyDocContext'` ＝ **1** 且 `grep -cx 'LoDisposePenaltyModule'` ＝ **1**（**都不得为 0**）；
  - ② **二选一声明（逐条，写进载体）**：每一个同侪**要么**「未升级（保持诚实 stub、返非 0、走台账、不 deref）」**要么**「升级为真实现」；**若升级**，必须满足与靶心同形的四件套（对象/句柄身份校验 ＋ 与对象绑定的状态变化 ＋ 成败计数 ＋ 可独立读取的镜像 ＋ 能证伪的自检新格）；
  - ③ **新可达性的机器证据（本步特有）**：`app_g1.log` 与 `leg_*.env` 里给出
    - `DestroyDocContext` 的**台账行**（若同侪②声明"未升级"⇒ **它一旦被走到就必有行**；行数 0＝没走到，行数 ≥1＝走到了）**或** 升级后的**摧毁计数 ≥1**（镜像字段）；
    - `LoDisposePenaltyModule` 的**台账行数与 `calls=`**（before ＝ 1 行／`calls=1`，`:512`）如实成对；
    - **并给出它是"走到过"还是"没走到"的结论**（二值，不许含糊）。
- **取哪个字段**：`nm` 两个命中；`app_g1.log` 的两个具名台账行；载体里的二选一声明。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for n in DestroyDocContext LoDisposePenaltyModule; do printf "%s nm=%s\n" "$n" "$(nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -cx "$n")"; done; echo "--- 台账里的收尾站 ---"; grep -nE '^PTS_GAP entry=(DestroyDocContext|LoDisposePenaltyModule)' build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log; echo "--- 现盘 stub 字面 ---"; for n in CreateDocContext DestroyDocContext LoDisposePenaltyModule; do printf "%s=%s\n" "$n" "$(grep -c "return wpf_pts_gap(\"$n\")" src/WpfGfx.Linux.Native/src/win32_pts.c)"; done
```
- **期望形状**：两个 `nm` 命中 **都＝1**；第三段三个值与载体里的二选一声明**逐条一致**。
  ⚠️ **次序约束（现取）**：`:416`／`:488` 的 `DestroyDocContext` **必须早于** `:421`／`:493` 的 `TextPenaltyModule?.Dispose()`；若腿证据里出现**反序**，本条判红并点名（同件注释逐字 `PTS context must be destroyed first`）。

### C6 冷启腿两页面：**不劣化** ＋ 台账效应可见（`native_gap` 按实际归因）
- **objective**：本步不把两页推回"进程死"，且台账效应可读。
- **acceptance**：`leg_23.env`／`leg_24.env`：`LEG … alive=yes` ∧ `app_rc ∉ {134,139}` ∧ `magenta ≥ 20000`（守卫阈值，`pts-pages-guard.sh:75 MAGENTA_FLOOR` 缺省）；`DEV … shim=` ＝ 本趟 `.so`；守卫 `pts-pages-guard.sh --legs <dir>` ⇒ `rc=0`，`PTS_GUARD=` 与 `PTS_G10_NAME=` 在位；**`native_gap` 按实际归因**（见下）。
- **取哪个字段**：`leg_{23,24}.env` 的 `LEG`／`NAMED`／`DEV` 三行；守卫两行；`app_g1.log` 的台账行数。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; bash build/MilBridge/tools/pts-pages-guard.sh --legs "$D" >/tmp/w8s4_c6.out 2>/tmp/w8s4_c6.err; echo "rc=$?"; grep -E '^(PTS_GUARD|PTS_G10_NAME)=' /tmp/w8s4_c6.out; grep -hE '^(LEG|NAMED|DEV) ' "$D"/leg_23.env "$D"/leg_24.env; echo "gapline=$(grep -c '^PTS_GAP entry=' "$D/app_g1.log") truncated=$(grep -c 'PTS_GAP ledger=truncated' "$D/app_g1.log")"
```
- **期望形状**：`rc=0`；两腿 `alive=yes`；`app_rc ∉ {134,139}`；`shim=` ＝ 现盘 `.so`。
- 🔴 **`native_gap` 的写死口径（本步特有，防"为保数而假实现"）**：`native_gap` 是 `legs-to-env.py` 现取 **`len(re.findall(r"PTS_GAP entry=", app_g1.log))`**（＝**台账打印行数**），且 native 侧台账有**打印预算**（`win32_pts.c:120-129` 缺省 `64`，环境变量 `WPF_LINUX_PTS_DIAG`）⇒ 它是"**打印行数**"，不是"缺口条目数"，还会被 `PTS_GAP ledger=truncated` 截断。
  ⇒ **本步的正常形态是它可能由 `2` 变小**（靶心退出缺口路径 ⇒ 它的台账行消失）。**判法**：`native_gap` **由 2 变 1 判绿（但必须点名归因：`CreateDocContext` 的台账行消失）**；**若为保住 `native_gap=2` 而让靶心继续走 `wpf_pts_gap()` ⇒ 直接判红**（那就是"绿着漏"的假实现，C8 也会红）。

### C7 **同趟性**（本步**必查**，因为成对读数跨趟就是假对）
- **objective**：before/after 的所有面取自**同一趟**。
- **acceptance**：`pts-gap-count-check.sh` 的 `so16=` **＝** `leg_*.env` 的 `DEV … shim=` **＝** 现盘 `.so` 的 `sha16` 前 16（**三者逐位相同**），且 `pts-gap-count-check.sh` 的 `carrier_sha16=` **＝** `app_g1.log` 的实际 `sha16`；**并同趟记三件 `mtime`**（本件 §0 现取到 `.so`／`exports.txt` 的 `mtime` 晚于证据 `mtime` ⇒ 这是**已发生过一次**的"重写事件"，**内容同值故不判红**，但**必须登记**）。
- **取哪个字段**：上述五个值 ＋ 三件 `mtime`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; s=$(sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16); g=$(bash build/MilBridge/tools/pts-gap-count-check.sh | grep -o 'so16=[0-9a-f]*' | cut -d= -f2); l=$(grep -h '^DEV ' "$D"/leg_23.env | grep -o 'shim=[0-9a-f]*' | cut -d= -f2); c=$(bash build/MilBridge/tools/pts-gap-count-check.sh | grep -o 'carrier_sha16=[0-9a-f]*' | cut -d= -f2); a=$(sha256sum "$D/app_g1.log" | cut -c1-16); echo "so=$s gap_so16=$g leg_shim=$l carrier=$c app_g1=$a same=$([ "$s" = "$g" ] && [ "$g" = "$l" ] && [ "$c" = "$a" ] && echo yes || echo NO)"; stat -c '%y %n' src/WpfGfx.Linux.Native/bin/libwpfwin32.so src/WpfGfx.Linux.Native/bin/exports.txt "$D/app_g1.log"
```
- **期望形状**：`same=yes`。**before 现取是 yes（内容口径）**；after **必须**保持 yes；`mtime` 面如实登记（**只在内容不等时才判红**）。

### C8 stub 面：靶心**不再**走诚实缺口
- **objective**：`CreateDocContext` 从"缺口路径"消失（行为面机械证据，与 C2 的"缺口面可能不变"互补）。
- **acceptance**：`grep -c 'return wpf_pts_gap("CreateDocContext")' src/WpfGfx.Linux.Native/src/win32_pts.c` **before ＝ 1（`:252`）→ after ＝ 0**；**若同趟升级了 `DestroyDocContext`**，则对应串也 **1 → 0**（**升级它不是本步的必做项** ⇒ 若维持 stub，该计数保持 **1** 并**必须**在载体里二选一声明）；`LoDisposePenaltyModule` 现取 ＝ **1**（`:648`）。
- **取哪个字段**：该源件的三个字符串命中数；并同趟记该源件 `sha16`（before ＝ `80b5786aef1cc823`）。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sha256sum src/WpfGfx.Linux.Native/src/win32_pts.c | cut -c1-16; for n in CreateDocContext DestroyDocContext LoDisposePenaltyModule GetFloaterHandlerInfo GetTableObjHandlerInfo; do printf "%s=%s\n" "$n" "$(grep -c "return wpf_pts_gap(\"$n\")" src/WpfGfx.Linux.Native/src/win32_pts.c)"; done
```
- **期望形状**：`CreateDocContext=0`；`DestroyDocContext` ∈ {0（已升级）, 1（维持诚实 stub）}、`LoDisposePenaltyModule` ∈ {0, 1}，**都合法**，但**必须与 C5 的声明一致**（不一致 ⇒ 红并点名）。

### C9 对象/出参绑定面：`out` 句柄**真落盘**且与本次调用绑定（**不是常量、不是单例**）
- **objective**：`return 0` 之外有**与该次调用绑定**的状态变化。
- **acceptance**：对**两次**独立调用（同一进程内，两个不同的 `fscontextinfo` 实参）：
  - `rc=0`；
  - 两次落出的 `*pfscontext` **互不相等**，且**各自等于自己那个对象的地址域**（镜像逐字段对拍）；
  - `fscontextinfo = NULL` ⇒ **返非 0** 且 `*pfscontext` 被置 `NULL`（**不许**留残留）；`pfscontext = NULL` ⇒ **返非 0**、不崩；
  - 结构内被读回的可判定字段（§1.6-③ 的至少两项）与传入值**逐项相等**。
- **取哪个字段**：自检/探针输出的 `rc`／两个句柄值／对拍结果；镜像 vs 对象的逐字段比较。
- **verify**（由实现件在其自检/探针上跑；本件只给形状）：
```
# 由实现件填具体命令；必须捕获式 rc，且必须给「fresh 或已发生调用序 ＋ 依赖计数当时值 ＋ rc/diag」三格
# 形状：two_calls_rc=0/0  h1 != h2  two_calls_bind_ok=1  null_in_rc=<非0>  null_out_rc=<非0>  field_readback_ok=1
```
- **期望形状**：`two_calls_rc=0/0` ∧ `h1 != h2` ∧ 两个绑定判据都 =1 ∧ 两个 `NULL` 拒绝都非 0 ∧ 字段读回全等。
- 🔴 **本条判绿的"反过读"**：**两个句柄不同 只是必要条件**；只证明"不是同一个常量"，**不**证明"与这次调用的入参结构绑定"。绑定必须由**字段读回**那一格承担（这是 `t97`／`t103` 两次"出参真落盘"的同一口径）。

### C10 回溯面（**必须认两种声明形态**）
- **objective**：新具名能回溯到**真实声明**，而不是被写成常量。
- **acceptance**：对任何新具名 `N`，**以下任一条**命中即算回溯成立，并**逐条点名命中的形态与 `file:line`**：
  - **形态 ①（显式入口名）**：`upstream/wpf/**` 里有 `DllImport … EntryPoint="N"` 行（现取：`LineServices.cs` 这是**唯一**可能命中的树）；
  - **形态 ②（方法名约定）**：`upstream/wpf/**` 里有 `[DllImport(…)]` 且**紧随其后的声明行的方法名 ＝ `N`**、且该 `DllImport` 属性里**没有** `EntryPoint`（**现取硬事实**：`Pts.cs` 的 `DllImport` 行 **73** 条、`EntryPoint` 出现 **0** 次 ⇒ `CreateDocContext`（`Pts.cs:3090-3094`）**只能**靠形态 ② 回溯）。
  ⇒ **判法写死**：只认形态 ① 会**漏掉整个 PTS 面**（`F-2` 的机制就是它）⇒ **只认形态 ① 的写法判红**。
- **取哪个字段**：回溯命令的命中行 ＋ `file:line`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && echo "形态①EntryPoint字面:$(grep -rn 'EntryPoint *= *\"CreateDocContext\"' upstream/wpf --include=*.cs | grep -c .)"; echo "形态②方法名约定:"; grep -rn 'internal static extern int CreateDocContext' upstream/wpf --include=*.cs
```
- **期望形状**：形态① ＝ **0**（这是**事实**，不是缺陷）；形态② **命中 1**（`Pts.cs:3091`）。**任一具名两形态全不命中 ⇒ 判红并点名**（那才是"写死常量"）。

---

## §3 ③ 「假进度必红 P1–P11」（成对正反腿 ＋ 必红点）

> **总则（写死）**：**反腿未红、或红而不点名 ⇒ 该条判不成立**；**反腿必须在副本文档上跑**，`git status --porcelain` 不得出现被改的仓内件（副本一律落 `/tmp` 或仓外）。
> **点名的口径（本步按队长提醒写死）**：`reason=` **token** 与**字段名**，**二者之一命中即可算"点名"**（现取：`grep -rn 'reason=' build/MilBridge/tools/**` 里除 `ledger-nonzero-frontier-unchanged` 外多数 token **未被实现**）⇒ **不许**把"必红并点名"押在一个**尚未存在**的 token 上。**承重点是"红 ∧ 指出是谁/在哪一格"**。

| # | 假形式 | 正腿（必绿） | 反腿（**必红并点名**） | 必红点（断言字段） |
|---|---|---|---|---|
| **P1** | **只改计数/声明凑数字**（改 `pts-gap-decl.txt`／白名单） | 真实现 ⇒ C8 的 `CreateDocContext` 命中 ＝ **0** | 只改声明件 ⇒ 必红并点名"声明件 ≠ live" | `nm` 逐名命中 ∧ 声明件；不一致 ⇒ 红 |
| **P2** | **`return 0` 无副作用**（出参仍 NULL／未绑定） | 真实现 ⇒ 自检在"未实现/已实现"两态判词**不同** | 把该入口换成"清空 ＋ `return 0;`"的**副本** ⇒ 自检**必红**并点名（出参仍是毒值／绑定格） | 返 0 时 `*pfscontext` **仍为 NULL/未绑定** ⇒ 红 |
| **P3** | **假成功：`NULL`/毒入参也返回 0** | 真实现 ⇒ 对 `NULL` 入参**返回非 0** | 副本上让它对 `NULL` 也返回 0 ⇒ 必红并点名该入口的 `NULL` 分支 | 该入口对 `NULL` 的返回值与出参 ⇒ 红 |
| **P4** | **把具名面改成硬编码常量名**（改仪表） | 真实现 ⇒ C10 的具名可**回溯上游声明** | 副本上写死常量 ⇒ 必红并点名 | **两形态**（`EntryPoint=` 或方法名约定）全不命中 ∧ 该名出现 ⇒ 红 |
| **P5** | **跨趟拼读数** | 真实现 ⇒ C7 的 `same=yes` | 用**上一趟** `leg_*.env`（例如 `shim=461e5557bd7dd571` 那一趟）配本趟 `.so` ⇒ 必红并点名三值不等 | `so16=`／`DEV shim=`／现盘 `.so` 三值不等 ⇒ 红 |
| **P6** | **台账非零但前沿不动** | 真实现 ⇒ C3/C4 的 `after ≠ CreateDocContext` | 只让台账涨而前沿仍停在同名 ⇒ 必红并点名 `before == after` | `PTSGAP_FRONTIER` 的 `before == after == CreateDocContext` ∧ `native_gap>0` **不免除** ⇒ 红 |
| **P7** | **🔴 恒绿自检没有牙**（第二步／第三步暴露过） | 自检**能证伪**（P2/P3/§2-C9） | 把自检改成恒 `return 1;`（或恒 `diag=0`）⇒ **三档探针判词全同** ⇒ 必红并点名"三档同判词" | 正极/负极/边界三档的 `rc`／`diag` **完全相同** ⇒ 红 |
| **P8** | **🔴 观测镜把 64 位指针塞 `int` 域**（第二步实测的假红） | 指针量走**专用指针域**（现取 `win32_pts.c:473-492` 的 `WpfLinuxWin32_PtsJmpProbePtr` 与 `ptr0`／`ptr1`） | 把句柄写进 `int` 域再与真指针比 ⇒ 必红并点名"截断域" | 自检里"真指针 vs 镜里取回值"**恒不等** ⇒ 红 **且点名该域**；**若它变成"恒不等 ⇒ 假红"而无人识别，同样判该条不成立** |
| **P9** | **🔴 夹具自身漏牙**（`t103` 格 85 教训） | 夹具**先造出能让断言咬人的前置**（例如"只建不 acquire"的活对象） | 把夹具前置改回"两对象都已就绪"⇒ 坏实现**照样过**（净腿绿）⇒ 必红并点名"该格在净腿上无牙" | 同一坏实现：**带前置腿必红 ∧ 净腿必绿**（净腿也红 ⇒ 前置把两腿都污染，另判） |
| **P10** | **🔴 `F-1` 型误定名**（本步**新加**，队长明令） | 定名**只按台账面**（C4①）；托管面只作粗证 ＋ 显式声明其域缺陷 | 用**托管 `entry=` 面**（或混读直方图）给"被撞入口／下一跳"定名 ⇒ 必红并点名"定名源不是台账" | 定名依据字段不是 `^PTS_GAP entry=` ⇒ 红；**混读直方图（台账行 ＋ 托管行合成一张表）⇒ 红** |
| **P11** | **🔴 收尾同伴被第一次走到却无读数**（本步**新加**） | C5③ 给出"走到/没走到"的**二值结论** ＋ 机器证据（台账行或摧毁计数） | 靶心补完后**收尾面被走到**（例如 `DestroyDocContext` 台账行出现）而载体**既没声明、也没计数、也没台账行** ⇒ 必红并点名"新可达路径无读数" | `app_g1.log` 台账/计数面 ⊥ 载体的二选一声明 ⇒ 红 |

**P8 的"两向都要咬住"（沿用第三步的写法，逐字重申）**：要求「**同一对拍必须有牙**」—— 正腿（句柄走指针域）**必绿**，反腿（塞进 `int` 域）**必红并点名**；**反腿不红**（对拍恒绿）或**正腿恒红**（截断导致），两种都判该条**不成立**。

---

## §4 ④ 成对读数清单 R1–R11（before／after ＋ 每面「零回归」判法）

| # | 面 | 取哪个文件的哪个字段 | before（本件现取） | after 期望形状 | 零回归判法 |
|---|---|---|---|---|---|
| R1 | 导出面 | `exports.txt` 行数；`nm … \| grep -c .` | **567 / 567** | 两者**相等** ∧ **≥ 567** | 不相等 ⇒ 红；**下降** ⇒ 红 |
| R2 | 缺口面 | `check-shim-coverage.py` 的 `[PresentationNative_cor3.dll] N 条` | **96**（扫描 423／已有导出 308／会 ENFE 115） | **按实际归因**（纯行为补全 ⇒ 不变） | 变了 ⇒ **必须逐条点名**"哪一条进出"，否则红 |
| R3 | 三格 | `PTSGAP=` 的 `tool/dead/artifact/ops/impl` | **96/11/1/84/89** | 成对给出；`dead`／`artifact` **不变** | `artifact` 变大 ⇒ 逐条点名（账目漂移）；`impl` 动必须归因到 `STUB` 字面数 |
| R4 | 探针前沿 | `PTSGAP_FRONTIER` 的 `after=` | `after=LoDisposePenaltyModule@3` | **≠ `CreateDocContext`**（**不预判**是谁） | 同名 ⇒ P6 红。⚠️ 该脸是**探针进程脸**，**不得**当"链上真的离开" |
| R5 | **台账面（定名唯一依据）** | `app_g1.log` 的 `^PTS_GAP entry=`（`entry/seq/calls`） | `seq=5 CreateDocContext calls=1` ＋ `seq=6 LoDisposePenaltyModule calls=1`（**2 行**） | `CreateDocContext` **行数/计数下降**（最理想 0 行） | 行数不降 ⇒ 靶心没真离开缺口路径 ⇒ **红**（P6） |
| R6 | 托管 `entry=` 面 | `app_g1.log` 的 `^\[PTS-UNAVAILABLE\]` 行 | **2 行，都 `LoDisposePenaltyModule`**；`CreateDocContext` **0 次**；`unknown=0` | 如实记录；**不作定名依据**（`F-1`） | `unknown` 增 ⇒ **仪表退化（回归）**；**拿它定名** ⇒ P10 红 |
| R7 | 两页症状 | `leg_{23,24}.env` 的 `LEG`／`NAMED`／`DEV` | `alive=yes app_rc=143 magenta=49923/54513 colors=844/852 ae=141323/221857 ink=428491/423833`；`managed_unavail=1 err=-10000 native_gap=2 native_err=-10000`；`shim=a2de5ff2b667f33f pf=6893d1d3fb1ee110` | `alive=yes` ∧ `app_rc∉{134,139}` ∧ `magenta ≥ 20000` ∧ `shim=` ＝ 本趟 `.so`；`native_gap` **按实际归因**（允许 2→1） | `alive` 变／`app_rc∈{134,139}`／`magenta` 掉阈值／`shim` 不匹配 ⇒ **红**；为保 `native_gap=2` 而让靶心继续走 `wpf_pts_gap` ⇒ **红** |
| R8 | 同趟性 | `so16=`／`DEV shim=`／现盘 `.so`／`carrier_sha16=`／`app_g1.log` `sha16` ＋ 三件 `mtime` | **yes（内容口径）**：三处 `a2de5ff2b667f33f`；`carrier=bf59ef38f5b8be55` ＝ 载体；`mtime`：`.so`／`exports` `02:22` **晚于** 证据 `02:20`（**重写事件，内容未变**） | **仍是 yes**；`mtime` 如实登记 | 任一**内容**不等 ⇒ 红（P5） |
| R9 | stub 字面 | `win32_pts.c` 的五个 `return wpf_pts_gap("<名>")` 计数 ＋ 该件 `sha16` | `CreateDocContext=1`／`DestroyDocContext=1`／`GetFloaterHandlerInfo=1`／`GetTableObjHandlerInfo=1`／`LoDisposePenaltyModule=1`；源件 `80b5786aef1cc823` | `CreateDocContext=0`；其余三个创建链外的随声明；`DestroyDocContext`／`LoDisposePenaltyModule` ∈{0,1} 但**必须与 C5 声明一致** | 声明与计数不一致 ⇒ 红 |
| R10 | 声明件 | `pts-gap-decl.txt` 的 `# PTSGAP-DECL:` 行 | `tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567 w66pre16=bf6b683d94549087` | **随 live 同趟动**（该行是**现值位**，不是历史行） | 与 live 不等 ⇒ 牙必红；**不许**就地改历史行（裁定九） |
| R11 | 九位 | `docs/CURRENT-STATE.md` 的 `BASELINE-FROZEN gen=#80 sha16=b27ff6332f263495` ＋ 九位行 | 现取该行在位（**本件未逐位重算九位**） | **只有 `win32shim` 位**按声明位移 | 出现**未声明**位位移 ⇒ 红。⚠️ 现取 `docs/ROUTES.md` 处于 `M`（**他人车道在改**）⇒ 取九位前先记该件 `sha16` |

### 今天现取就是 `NO`／`NOINFO` 的面（**必须显式写出来，不许装绿**）

| 面 | 今天的读数 | 为什么是 `NO`／`NOINFO` |
|---|---|---|
| 「在册腿证据」与「现盘 `.so`」是否**同趟**（`mtime` 口径） | **`NO`**：证据 `02:20`，`.so`／`exports.txt` `02:22` | 中间有一次重写事件；**内容同值** ⇒ 判据按内容判绿，但 `mtime` 面**必须**登记为 `NO` |
| 补完之后**下一跳的名字** | **`NOINFO`** | 只能运行期取证；本件只读、且**禁止预判名字**（见 N1） |
| 补完之后**托管侧是否还会抛** `PtsException`／`PtsUnavailableException` | **`NOINFO`** | 需腿证据；本件硬边界禁止跑腿（见 N3） |
| `:488 Validate(DestroyDocContext)`／`:407 PtsContext.Dispose()` 的**实际可达性** | **`NOINFO`** | 需运行期证据（`_contextPool.Count` 与调度时序）；本件只能给**代码级门**（`:479 Count>4`、`:319-324 BeginInvoke`）（见 N2／N4） |

---

## §5 ⑤ 纪律第 `30` 条（在册）对本判据的硬约束

**在册确认（现取，本件自己取）**：`build/MilBridge/HANDOFF-NEXT.md` 有条块 —— 块头 `:611`（内容锚「dated 纪律追加 · 第 `30` 条（**进程内状态敏感仪器**的调用史约束）」，**行号仅本次有效**），口径句在 `:614`；**在位自检命令现跑**：`grep -c '进程新鲜[度]' build/MilBridge/HANDOFF-NEXT.md` ⇒ **`3`**（≥1，在位）。**口径句要点（`:614` 原文摘要）**：凡引用**进程内状态敏感**的仪器读数（自检／探针／计数器镜像／`live` 计数），必须**同趟**给出**三格**：① **进程新鲜度**（fresh 进程，或同进程 ＋ **已发生的关键调用序**）② **关键前置量**（该读数依赖的那些计数/`live` 的**当时值**）③ **判词**（`rc`／`diag`）。

**本判据的硬约束（写死）**
1. **凡引用自检/探针读数（C9 的两调用对拍、C5 的计数、P2/P3/P7/P8/P9 的自检对拍），同趟必须给三格**：① fresh **或** 已发生的关键调用序（**逐条列出**：建过几个 `CreateInstalledObjectsInfo`／LS 上下文／罚分模块、是否写过 `LoSetDoc`／`LoSetBreaking`、是否调过 `LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle`／`CreateDocContext`、是否销毁）② 该读数依赖的**当时值**（`io_live`／`loc_live`／`g_pts_pen_sets`／`g_pts_pen_rejected`／`g_pts_seq`／`calls`／`loc_creates`／`loc_destroys`／`doc_sets`／`doc_rejected` 等）③ `rc` ＋ `diag`。**缺任一格 ⇒ 该读数不许当证据。**
2. **正腿必须在 fresh 进程里跑**；带历史腿**必须独立进程**，历史**逐条可复现**。
3. **两种误导形态（写清，供实现件与复核件识别）**：
   - **带历史的红 ＝ 假红**：同一 `.so` 在 fresh 与带历史两种前置下**判词不同**，成因是**调用序**。**机制本件现取自源码**：`win32_pts.c:1208 int base = g_pts_loc_live_n;` ＋ `:1250`／`:1253`／`:1260`／`:1353`／`:1397`／`:1423` 那六处断言**已经是 `base` 相对**（`t102` 的修法在源码里逐行可见）⇒ **今天该族不会因"先建过活上下文"而红**；但**同族风险仍在**（任何新写的**绝对值**断言都会重新踩上）。⚠️ 我**未复算**任何一组 fresh vs 带历史的 `rc`/`diag` 数字（复算需跑探针，本件硬边界禁止）⇒ 凡要用数字，**实现件/复核件同趟自取**（见 §6-N1 同族写法）。
   - **fresh 的绿 ＝ 假绿**：fresh 只证"该前置下没红"，**不**证"与该对象绑定的状态真落了"。
4. **🔴 本步把「fresh 的绿 ＝ 假绿」升为**必要条款**（不是故事）**：第三步 `t103` 有**硬实证** —— 修 null 缺陷之前，**净腿 `rc=1 diag=0`（绿）而缺陷真实存在**，只有带历史腿 `diag=85` 把它暴露。⇒ **本步写死**：**凡以"净腿绿"为唯一证据的断言，实现件必须再给一条"能让该断言变红的前置/反腿"，否则该断言的绿不算证据**（对应 P9 的"净腿没牙"判红）。
5. **三格之外，本步再加一格（`F-1` 特有）**：凡涉及**定名**的读数，必须标明**取值源**（台账面／托管面／探针报表面**三选一，逐字写出**）。**不写源 ⇒ 该定名不许当证据**（对应 P10）。

---

## §6 ⑥ `NOINFO` 预期（**此刻必然拿不到**；逐条给"消掉需要什么"）

1. **补完靶心后"链上下一个被撞入口"的具体名字**：`NOINFO(reason=只能运行期逐步取证；本件只读、且契约禁止预判名字)`. **消掉需要**：实现件补完后跑一趟冷启腿，给出 `app_g1.log` 的 `^PTS_GAP entry=` 行（按 `seq` 升序）与 `entry=` 面，**并按 C4 只以台账面定名**。
2. **`_contextPool.Count` 在本装置的腿里会不会 >4（`PtsCache.Linux.cs:479` 门）**：`NOINFO(reason=本件只读，且该数是运行期池状态；代码级只能给出门的位置，给不出实际值)`. **消掉需要**：实现件加一格"池长度"读数（镜像/日志）或给出 `:488` 被走到的具名证据（台账行／计数器）。
3. **`FsDestroyPageBreakRecord`／`FsDestroyPage`（`PtsContext.cs:85/:103`）在收尾时是否真被调到**：`NOINFO(reason=取决于 `_pages`／`_pageBreakRecords` 是否非空，而那取决于 `FsCreatePageFinite` 是否成功 —— 该入口本步不动)`. **消掉需要**：运行期证据（台账/计数器/具名行），或"页集合为空"的机器可读读数。**本件只给代码级预期**（`PtsContext.cs:281 OnPageCreated` 只在页创建成功后入册 ⇒ 预期空循环），**不声称已证**。
4. **`PtsHost.Context` 的真实下游第一步落在哪个 `Fs*` 入口**：`NOINFO(reason=缺口面里 `Fs*` 有 66 条，本仓无规格；本件只读到 `PtsPage.cs:397 FsCreatePageFinite` 这一处调用点，不等于"第一个被撞的")`. **消掉需要**：腿证据里 `entry=`／台账的具名读数 ＋ 回溯声明位。
5. **`FSCONTEXTINFO` 的字段级读回是否真的可辩护**：`NOINFO(reason=本仓没有 native 侧的结构规格；字段的权威声明只有托管侧 `Pts.cs:833-844`，且现盘存在一具未入索引的 `src/WpfGfx.Linux.Native/bin/abi-layout` 产物（本件未读其内容，故不引其值）)`. **消掉需要**：实现件给出"逐字段读回对拍"的机器读数（C9 的 `field_readback_ok`），或给出结构布局的具名权威声明。
6. **`DestroyDocContext`／`LoDisposePenaltyModule` 是否本步就该升级**：`NOINFO(reason=取决于本步之后它们是否真的被走到与"走到了会不会掐链"（前者受 `Count>4` 门控、后者返回值被丢弃），二者都要运行期证据)`. **消掉需要**：C5③ 的二值结论 ＋ 台账/计数读数；**若为此升级，须给四件套读数**。
7. **`native_gap` 是否为**真**"缺口条目数"**：`NOINFO(reason=现取它是"台账打印行数"（`legs-to-env.py` 的 `len(findall("PTS_GAP entry="))`）且受打印预算（缺省 64）与 `ledger=truncated` 影响 ⇒ 它与"条目数"只在**未截断且每名只打一行**时相等；本件不主张它等价)`. **消掉需要**：一个直接读 `g_pts_calls[]` 的"缺口条目数"读数，或同趟给出 `truncated` 计数。
8. **自检新格（≥86）的调用路径**：`NOINFO(reason=仓内未现取到新格的调用点；本件只能给形状要求)`. **消掉需要**：实现件给出调用点（谁 `dlsym`／哪一步跑／打哪一行机读键）。
9. **`MAGENTA_FLOOR` 的权威值**：本件**现取到缺省** `MAGENTA_FLOOR="${PTS_GUARD_MAGENTA_FLOOR:-20000}"`（`pts-pages-guard.sh:75`），但**门禁实际注入值未取** ⇒ `NOINFO(reason=本件未跑整趟门禁、未取注入环境)`. **消掉需要**：跑腿者给出同趟的该变量现值。

---

## §7 ⑦ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-w8-step4-criteria.md`（新建；UTF-8；模式 **644**；**首记号不是 `# ⏪ `**；末行自带可复算自报口径）。
- **只读**：本件全部命令为 `grep`／`sed`／`awk`／`cat`／`nm`／`sha256sum`／`wc`／`stat`／`git log`／`git status`／`git ls-files`／`git diff --stat` ＋ 三个**纯读**件（`check-shim-coverage.py`／`pts-gap-count-check.sh`（`t106` 在改，只跑不写）／`pts-pages-guard.sh --legs`（判据端纯读））。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- **未改任何其它件**：`git status --porcelain` 原样 ——
```
 M build/MilBridge/HANDOFF-NEXT.md
 M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device.txt
 M build/MilBridge/tools/pts-gap-count-check.sh
 M docs/ROUTES.md
 M samples/WpfFeatureProbe/KNOWN-DEFECTS.md
?? build/MilBridge/P1-w8-step3-verify.md
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/arm_A/
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device/
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_post_g1.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/five_pre_g1.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/session.txt
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/shots/
?? src/tests/
```
  ⇒ 上述 **13 项全部为他人**（`t106` 的 `tools/**`、W8 实现件／`scribe` 的 `PtsCache.Linux.cs` 域、腿跑器与 `t105` 的载体）⇒ **本件是本次唯一新增件**。
- **未引既有报告当证据**：`P1-w8-step1/2/3-criteria.md` 只作**形制参照**；队长 `P1-ptsname-result.md` §8 裁定十二只作**任务来源**；`t105` 的 `F-1`／`F-2` 我只引**机制描述**，其**读数一条未抄**（机制我**自己**复算：读了 `PtsCache.Linux.cs:991-1023`／`:1012`、`win32_pts.c:752-768`、以及 `app_g1.log:511/512/513/967` 的现取行）。
- **末行自报口径当场可复算**：见末行。

---

### 结语（自包含）

- **① 前置核查（结论）**：靶心 `CreateDocContext` ＝ `Pts.cs:3090-3094`（`ref FSCONTEXTINFO` ＋ `out IntPtr` → `int`，**方法名约定**声明、无显式 `EntryPoint`）；调用点**唯一** ＝ `PtsCache.Linux.cs:548`；其 `-10000` 经 `PTS.Validate` 抛 → `:237` 接住 → 毒池项清除 → `IsPtsUnavailable`（`:1274-1284`，因台账涨而 true）→ 立闩 `:280` → `FlowDocumentView.Linux.cs:113` 画**页级占位**。**两条收尾同侪现取都是"已导出 ＋ 诚实 stub"**（`DestroyDocContext`：`nm`/`exports` 各 1、字面 `win32_pts.c:258`，调用点 `:416 IgnoreError`／`:488 Validate`；`LoDisposePenaltyModule`：各 1、字面 `:648`，调用点 `TextPenaltyModule.cs:59`、返回值被丢弃）⇒ **本步不需要同趟补 stub**（`t97` 那条 `rc=134` 的机制 ＝ "对端**未导出**"，本步不成立）；**但**必须二选一声明，且必须给"新可达的收尾面到底走到没走到"的读数。
- **② 诚实边界与首次打开的路径**：分界句 ＝ **`return 0` 本身不是证据**；证据是**与该对象绑定、可被独立读取**的状态变化。首次打开的托管侧路径**逐条点名**：`:550 → :235 → :296-299`（真上下文进池）、`:202-210` 闩不再立、收尾面 `:407`／`:472 → PtsContext.cs:69/:85/:103` 与 `:416`／`:488`／`:421`／`:493`，以及下游第一步候选 `PtsPage.cs:397 FsCreatePageFinite`（**非本步靶心**）。
- **③ 判据 C1–C10**：构建／缺口面（按实际归因）／探针前沿（**不得当"链上离开"**）／**台账口径定名（`F-1` 硬条款）**／释放同伴（二选一声明 ＋ 新可达性读数）／两页症状（`native_gap` 按实际归因）／同趟性（＋`mtime` 登记）／stub 面／**出参绑定面**／**回溯面（认两种声明形态）**。
- **④ 假进度必红 P1–P11**：含**恒绿自检没有牙**（P7）、**64 位指针塞 `int` 域**（P8，两向都要咬住）、**夹具自身漏牙**（P9，`t103` 格 85 教训）、**`F-1` 型误定名**（P10，本步新加）、**收尾面新可达却无读数**（P11，本步新加）。**反腿未红或红而不点名 ⇒ 该条判不成立**；反腿必须在**副本文档**上跑。
- **⑤ 纪律第 `30` 条**：凡引用自检/探针读数一律**三格 ＋ 调用序**；正腿必须 fresh、带历史腿独立进程；两种误导形态写清；**并把「fresh 的绿 ＝ 假绿」升为必要条款**（凡只靠净腿绿的断言，必须再给一条能让它变红的前置/反腿）。
- **⑥ `NOINFO` 9 条**，各带"消掉需要什么证据"；并在 §4 末尾显式列出**今天就是 `NO`／`NOINFO` 的四个面**。

### §7-bis 落盘期间的位移（**只增不改，如实追加**；`ts=2026-09-29T02:37:44.335506304+0800`）

- **HEAD 位移**（现取 `git log --oneline -4`）：`a948b52`（§0 记录值）→ **`cb30df0`**（`docs(#81): t105 W8 第三步复核载体 + 队长裁定十二补（判下一跳改用台账口径）`）→ **`49265cd`**（`fix(#81): t106 牙扫描形状收窄落地 —— 历史行不承担现值（与裁定九一致）+ 修 4 处 DQ-BACKTICK + 自修性能与去重`）。
- **`M` 面由 5 项收窄为 1 项**（现取 `git status --porcelain`，11 行）：只剩 `M build/PresentationFramework.Linux/PtsCache.Linux.cs`（`git diff --stat` ＝ `24 insertions(+), 2 deletions(-)`）—— 这是 **`scribe` 的 `F-1` 车道**（队长已明示派它改"取值口径"），**不是本件**；其余 4 项已被 `t106` 的提交带走，`?? build/MilBridge/P1-w8-step3-verify.md` 亦已入 `cb30df0`。
- ⇒ **§7 那张 `git status` 清单是"本件起点"（`02:33:45`）的原样记录**，不是"写完时"的清单；两张都保留（**只增不改**）。写完时的清单为：`M build/PresentationFramework.Linux/PtsCache.Linux.cs` ＋ `?? build/MilBridge/P1-w8-step4-criteria.md`（**本件**）＋ `?? evidence/arm_A/**`（7 项）＋ `?? src/tests/`。
- **判据所依赖的三件未动**（现取）：`libwpfwin32.so` ＝ **`a2de5ff2b667f33f`**、`exports.txt` ＝ **`1a6a415f28c6308d`**（567 行）、`win32_pts.c` ＝ **`80b5786aef1cc823`** ⇒ §0／§2 的现取读数**在写完时仍成立**。
- ⚠️ **但 `build/PresentationFramework.Linux/PtsCache.Linux.cs` 正在被另一车道改** ⇒ 本件引用的该件**行号**（`:548`／`:235`／`:237-284`／`:991-1023`／`:1012`／`:1274-1284`／`:1297-1317` 等）**仅本次有效**；实现件与复核件取数时**必须重取该件 `sha16` 与行号**，并以**内容锚**（函数名／注释句）为准。
`P1-W8-STEP4-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 7040687d9bbea1f0（口径＝末行之前的全文；末行＝本行）`

---

## ⏪ `t113` dated 追加 —— `t111` 余项的**判据/口径面关账**（`F-1` 补格 ＋ `O-1`/`O-2`/`O-3` 口径 ＋ `F-3` 同趟性）（读时 `2026-09-29T03:0x+0800`；上方原文**一字未删**，本段**只加行**）

### `F-1`（medium）`§1.6①` **补一格**：本入口**只承诺 `NULL` 拒绝**；非 `NULL` 指针的**可读性不可先验**

- **现取成对读数**（本席自造夹具、仓外、直调现盘 `.so` `a131ea4e6f5cc4f5`；两例各跑独立进程）：
  - **`NULL` 入参** ⇒ **干净拒绝**：`CreateDocContext(NULL, &out)` ⇒ `rc=-10000`、`*out` 被清成 `NULL`、`PtsDocCreates()` ＝ **0**、`PtsDocLive()` ＝ **0**、报表 `doc_rej=1`（**一个字节都不读**）。
  - **非 `NULL` 而不可读**（`libc.mmap` 一页 `PROT_NONE` 当 `fscontextinfo`）⇒ **进程段错误、`rc=139`**（夹具在调用前已印 `BEFORE_CALL PROT_NONE page=0x…`，**死在调用内**）。
- **机理（我自读现盘原文）**：`CreateDocContext` 在 `NULL` 检查之后**按偏移逐个读入参结构**（`b+0`＝`version`、`b+4`＝`fsffi`、`b+12`＝`cInstalledObjects`、`b+16`／`b+24`／`b+32` 三个指针**只当值取、不 deref**）⇒ **可读性**是它的**隐含前置**，`NULL` 只是"可读性最平凡的特例"。
- **与同族三个端口的**不对称**（我自读现盘原文）**：`LoSetDoc`／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle` 都是**先按指针身份在在册表里查**（`wpf_pts_loc_find(ploc)` 一类），**不 deref** 入参 ⇒ 它们对"非 `NULL` 但不可读"**安全**；`CreateDocContext` 是**唯一**把入参结构**读内容**的入口 ⇒ 这一格的不对称**来自职责差**（它要"带走入参里的可判定量"），**不是实现疏漏**。
- **本格口径（逐字，据此判）**：**本条判据只承诺「`NULL` 拒绝」**；**非 `NULL` 而不可读**这一格记 **`NOINFO(前置不可先验)`** ⇒ **不构成红**。两条理由：① 托管调用点**恒传 `ref FSCONTEXTINFO`** ⇒ 该形态**今日不可达**；② 要把它升成可判的**前置**，须由 native 侧**声明"入参可读"为契约**（或加句柄/长度校验）＝ **产品面改动** ⇒ **另派单**（本件**不**改 `src/**`）。
- ⚠️ **分寸（逐字）**：**不许**把它写成"必须修否则红"（把关口前移到**不可达**形态＝判据不诚实）；**也不许**静默抹掉（不对称已按上面逐条写清、并给出"升成契约"的路径）。

### `O-1`（观察）`PtsDocFieldAt` 的**下标语义**（我现取，直调现盘 `.so`）

- `WpfLinuxWin32_PtsDocFieldAt(idx, field)` 的 `field` **不是**"托管结构第 N 个字段"：现取 `field=0..6` ⇒ `0x11111111`／`0x22222222`／`0x7`／**`<入参结构地址>`**／`0x4444444444444444`／`0x5555555555555555`／`0x6666666666666666`。
- **逐格（我自读现盘原文的 `switch`）**：`0`＝`version`、`1`＝`fsffi`、`2`＝`cInstalledObjects`、**`3`＝`info_addr`（记下的"哪个入参结构地址"—— 记账槽，不是托管字段）**、`4`＝`pInstalledObjects`、`5`＝`pfsclient`、`6`＝`ptsPenaltyModule` ⇒ **托管结构字段序 ＝ `0,1,2` 然后跳一格到 `4,5,6`**（`field=3` 是**记账**，不是第四个字段）。
- **口径（逐字）**：凡引用该读口，**必须**按上面这张**映射表**读；**禁止**写成"第 N 个字段"。⚠️ 该读口是**位置读**（`idx` 是**当前**登记表里的位置）⇒ 与 `…PtsPenaltyModuleHandleAt` 同族，**不得跨销毁缓存 `idx`**（`t102` 已在册）。

### `O-2`（观察）报表 `doc_sets=` 与端口口径 —— **我现取不能复现"与端口不一致"，但**口径写死如下（并给出最可能成因）

- **我现取（两次成功 create 之后，同进程同表）**：`PORT creates=2 live=2 destroys=0`；**报表** ＝ `doc_live=2 doc_sets=2 doc_rej=0 doc_des=0 doc_desrej=0` ⇒ **`doc_sets=` ＝ `PtsDocCreates()` ＝ 2**（**一致**）。
- **字段映射（我自读现盘原文的 `snprintf` 实参表）**：格式串里 `doc_live=%d doc_sets=%d doc_rej=%d doc_des=%d doc_desrej=%d` 依次吃 **`g_pts_doc_live_n`／`g_pts_doc_sets_c`／`g_pts_doc_rejected_c`／`g_pts_doc_destroys`／`g_pts_doc_destroy_rej`** ⇒ **`doc_sets=` 就是 `CreateDocContext` 的成功数**（＝ 端口 `WpfLinuxWin32_PtsDocCreates()` 返回的同一个变量）。
- **口径（逐字，防读错）**：**`doc_sets=` ＝ `CreateDocContext` 成功数（＝ 端口 `PtsDocCreates()`）**；**`setdoc_sets=` 才是 `LoSetDoc` 成功数** —— 两者**同族不同名**，**只看报表的读者务必按字段名分辨**（这正是 `F-1` 族"量名与实际语义不符"的同类风险面）。
- **`t111` 的 `doc_sets=0` 本席**未复现** ⇒ 记 `NOINFO(复现失败)`**，最可能成因（**假设，未验证**）：复核者拿**另一个进程**（其夹具）的 `PtsDocCreates()` 去对**另一处**的报表读数，或报表读数取自 create**之前**的快照。
- **本席**不**改 `src/**`**：这一格**不需要**改（现取一致）；若后人仍要"把报表那一格与端口逐字段绑定"，那是**产品面**改动 ⇒ 另派单（并须同趟跟随 `nm`／`exports.txt`／`pts-gap-decl.txt`）。

### `O-3`（观察，与纪律第 `30` 条同一机制）观测镜环的**容量与覆盖序**（我现取）

- **现取（同进程、只用不同可读页当 `ploc`）**：连续 **6** 次 push 之后逐条探 —— **push#1／#2 ⇒ `rc=0`（已被驱逐）**、**push#3..#6 ⇒ `rc=1`（可检索）** ⇒ **环容量 ＝ 4**（我自读原文：`#define WPF_PTS_JMP_MAX 4`；`g_pts_jmp[4]`），**覆盖序 ＝ "最近 4 条"**（检索序：`idx=0` 最新、向前追）。另：同进程**先有 2 条**（两次 create）再 push 4 条 ⇒ 最早那 2 条**探不到** ✓。
- **口径（逐字）**：**凡用 `WpfLinuxWin32_PtsJmpProbe` 追链的判据，必须同时写明**①**环容量**（今天 ＝ 4）②**覆盖序假设**（只覆盖**最近 4 条**；更早条目**已被驱逐** ⇒ `rc=0` **不等于**"该调用没发生"）。**缺任一项 ⇒ 该读数不许当证据**（这与第 `30` 条"调用史敏感仪器必须给三格"是**同一机制的两个面**：30 条管**进程史**，本条管**环容量**）。
- **归属（逐字）**：本条**并入第 `30` 条族**（**不新立条号** —— 它约束的是同一类仪器同一类误读；`t110` 自报的"环满"（该入口由 stub 变真后链 push 从 3 条变 4 条、正好写满 4 格环）**正是本机制的第一个实例**）。

### `F-3`（low，如实记）同趟性**只在一条腿上成立** ⇒ **完整的同趟换代排在字体栈阻断解除之后**

- **我现取（在册腿）**：`leg_23.env` ⇒ `shim=a2de5ff2b667f33f pf=6893d1d3fb1ee110`（**上一代**）／`alive=yes app_rc=143`；`leg_24.env` ⇒ `shim=a131ea4e6f5cc4f5 pf=2988f5154ecacdd`（**本代**）／`alive=no app_rc=134`。
- ⇒ **`C7` 的"三者逐位相同"**今日**不成立**（两条腿**两轴都不同代**），且成因是 `leg_24` **崩在字体栈**（`C6` 的红面，与本步无因果）、`leg_23` **未跑完** ⇒ **本件不假装同趟**：在册写明「**完整的同趟换代排在字体栈阻断解除之后**」；在那之前，两页成对读数**只能**记作"**上代 vs 本代**"的对照（不得当"同趟成对"引用）。

`P1-W8-STEP4-CRITERIA dated 追加后自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ b7118b1e6901c7a5（口径＝末行不计入自身取值；原自证行 `7040687d9bbea1f0` 系**追加前**全文值，`t113` 原样保留）
---

## ⏪ `t118` dated 追加 —— **W8 新定靶口径（托管具名异常面）入册 ＋ `N2` 指针**（读时 `2026-09-29T03:4x–04:0x+0800`；上方原文**一字未删**，本段**只加行**）

- **定靶口径（逐字）**：下一跳的**域名面**改为 **托管具名异常面** `^\[HC-UNHANDLED\] #<n> EntryPointNotFoundException: Unable to find an entry point named '<入口名>' in shared library '<dll>'`；**域名册** ＝ 上游 `…/PtsHost/Pts.cs` 的 `DllImport` 声明名（现取 `DllImport` 行 **73** 条）。**下一跳** ＝ 该面按**入口名**计数后的**最高频未处理名**（**现取：`FsCreatePageBottomless` 1080 次**，其后 `FsCreatePageFinite` **1** 次）。
- **与"台账口径"**不是同一个量**（逐字）**：台账口径（`^PTS_GAP entry=` 按 `seq=` 排序）**今天 0 行且结构性失明** —— 名册 13 名里**一个 `Fs*` 都没有**、`Fs*` **一个都没导出** ⇒ 异常在 **CLR** 里抛、native 一行都进不去；⇒ **引用读数必须标注取的是哪一个口径**。
- **三条代价（随引用一起写）**：① 只给"名字＋次数"（无 `g_pts_calls`／`g_pts_seen`／`live` 面）；② 发射方是**第三方应用**的钩子（**不在本仓写域**）；③ **会混入任何 ENFE** ⇒ 归因**必须按入口名过滤**。
- **`N2` 指针**：本条对应的可执行判据 ＝ `P1-fontstack-fallback-criteria.md` 的 `t118` 段 `N2`（运行期 ENFE 必须留痕 ＋ 按入口名过滤）；其**守卫侧接线**另派单。
`P1-W8-STEP4-CRITERIA dated 追加后自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ b81ade4b7b809f2c（口径＝末行不计入自身取值；原自证行系**追加前**全文值，原样保留）
