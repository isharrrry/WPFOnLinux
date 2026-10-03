# `P1-rgate-regress` 报告 —— `R-GATE` 产品回归（`resize ⇒ DUCE.Channel.Commit` `COMException 0x80004005`）：定位 ＋ 修（`T-B23`）

**车道**：`T-B23`（本轮唯一写者）｜**重活全部走 `~/heavy-slot.sh --min-avail 2500`**｜**进程只按 PID**｜**显示位只用空闲 `:23x`／装置自己的 `:88`**｜**未 `git add`／`commit`／`push`**｜**`upstream/**` 一字未改**

**结论一句话**：`R-GATE` 的红**不是** `#82` 里任何一笔代码改动的语义回归，而是 **AOT 桥（`wpfgfx_cor3.so`）找不到自己的 Skia 原生依赖 `libSkiaSharp.so`** —— 该件在"整目录拷贝装配"出来的应用目录里**只以 `runtimes/linux-x64/native/` 形态存在**，而桥的解析器只看"与 .so 同目录"。历史绿是靠 `samples/WpfFeatureProbe/bin/<cfg>/net10.0/` 里**手工留下的陈旧 `.so` 副本**撑着的（`git` 忽略的构建产物），`#82` 波一次全量重建把它们清掉 ⇒ 第一帧 `WM_SIZE` 就 `abort`。**修**：给桥的 SkiaSharp 解析器**补上"应用局部 `runtimes/<rid>/native/`"一档**（在 `src/WpfGfx.Linux/**` 内，`src/WpfGfx.Linux/Interop/MilNative.Misc.cs` ＋192 行）。**`R_GATE` 现取 `PASS crit=13/13`；撤修 ⇒ 复现崩溃**（成对）。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| ① 复现 | ✅ **三处可复现**：`R_GATE=NOINFO reason=device-window-absent`（应用 `SIGABRT`，核心已转储）；`app.log` 逐字见 §1 |
| ② 二分归因 | ⛔ **推翻派单假设**（`T-B18` 的 `MILRenderTargetBitmapGetBitmap` 那一路**根本不被走到**）：崩溃与 `#82` 的代码**语义**无关，是**构建产物被清**（见 §2／§3） |
| ③ 修（件:行） | `src/WpfGfx.Linux/Interop/MilNative.Misc.cs:1182` 起 `internal static unsafe class MilBridgeSkiaResolver`（＋`192` 行，**只追加**，既有行零改动） |
| ④ 可证 | ✅ 修后 `R_GATE=PASS crit=13/13`；**撤修 ⇒ 复现**（`NOINFO window-absent`，核心已转储）—— 成对读数见 §5.1／§5.2 |
| ⑤ 门禁 | ✅ `nm==exports`（846/846）／`PTSGAP=PASS`／`PTS_GUARD=PASS`＋`PTS_COLORANCHOR hits=3`／`DEFREG=PASS`／`REPORTID=PASS`／`FP-MANIFEST-TEETH=PASS(237/237)`／`HANDOFF_MV=PASS`／`STATICJAWS=PASS(34)`／`SSC=PASS`；`WpfGfx.Linux` 六个测试工程 **0 失败**；`FRAMEPRESENCE=PASS` |
| ⑥ 写域 | `src/WpfGfx.Linux/**`（唯一产品件）＋ `build/MilBridge/HANDOFF-NEXT.md`（复述位现值位）＋ **本载体**。黑名单件（`upstream/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`build/third-party/**`）**一字未改** |

---

## §1 复现（`verify-all` 同款装置：`build/MilBridge/tools/r-gate-step.sh`）

命令（**装置自装配，不传 `--appdir`**）：

```
bash build/MilBridge/tools/r-gate-step.sh --keep
```

三处同形读数（`bridge=e88f82233f53d1ea` ＝ `#82` 现件，`pc=83c71acfb20f26d7`）：

```
R_GATE_DEVICE=NOINFO reason=window-absent pid=<pid> alive=no
run-r-gate-legs.sh: 第 169 行： <pid> 已中止 （核心已转储） ( cd "$APP" && exec env WPF_WIN32_MSG_TRACE=1 dotnet "$PROBE_DLL" --only=clickprobe --late-ms=3000 > "$APPLOG" 2>&1 )
R_GATE=NOINFO reason=device-window-absent detail=EVID device=NOINFO reason=window-absent pid=<pid> alive=no
```

- 证据目录（`--keep`）：`/tmp/r-gate-step.tEJldV0u/`（本轮首复现，`18:04:53`）／`/tmp/r-gate-step.DGUEAWvE/`（`T-B22` 留，`18:01:37`，与本轮逐字同）。
- **崩溃原文（`app.log` 逐字）**：

```
[msg] hwnd=0x200005 … msg=0x0005 WM_SIZE                  wp=0x0 lp=0x3aa03aa
Unhandled exception. System.Runtime.InteropServices.COMException (0x80004005): Unexpected HRESULT has been returned from a call to a COM component.
   at MS.Internal.HRESULT.Check(Int32 hr) … Common/Graphics/wgx_render.cs:line 975
   at System.Windows.Media.Composition.DUCE.Channel.Commit() … Common/Graphics/exports.cs:line 376
   at System.Windows.Media.MediaContext.CommitChannel() … MediaContext.cs:line 2151
   at System.Windows.Media.MediaContext.Render(…) … MediaContext.cs:line 2075
   at System.Windows.Media.MediaContext.RenderMessageHandlerCore(…) … MediaContext.cs:line 1853
   at System.Windows.Media.MediaContext.Resize(…) … MediaContext.cs:line 1694
   at System.Windows.Interop.HwndTarget.OnResize() … build/PresentationCore.Linux/HwndTarget.Linux.cs:line 1618
```

⇒ 与派单描述**逐字相符**：`WM_SIZE ⇒ HwndTarget.OnResize ⇒ MediaContext.Resize ⇒ RenderMessageHandlerCore ⇒ Render ⇒ CommitChannel ⇒ DUCE.Channel.Commit ⇒ COMException 0x80004005 ⇒ abort`。

---

## §2 定位（**判据**：桥自带诊断 `WPF_LINUX_MIL_LOG`）

把装置里那条**完全相同的**启动命令（同 `app dir`、同 `DISPLAY`）加 `WPF_LINUX_MIL_LOG` 重跑（只读，不改被测件），`mil.log` 把 `E_FAIL` 的来源钉到了**一处**：

```
NOTE 创建字形渲染器失败：DllNotFoundException: DllNotFound_Linux, libSkiaSharp,
/home/links-dev/.dotnet/libSkiaSharp.so: cannot open shared object file: No such file or directory
/home/links-dev/.dotnet/liblibSkiaSharp.so: cannot open shared object file: No such file or directory
NOTE WgxConnection_SameThreadPresent: 渲染失败：TypeInitializationException: TypeInitialization_Type_NoTypeAvailable
[commit] ★E_HANDLE#3 PresentChannel 失败 hr=0x80004005（通道 2）
```

**因果链（现取）**：`libSkiaSharp.so` 加载失败 ⇒ SkiaSharp 类型初始化抛 ⇒ `RenderChannel` 抛（`MilPresentation.cs:1165` 的 `catch` 返回 `E_FAIL`）⇒ `MilNative.MilConnection_CommitChannel` 的 `★E_HANDLE#3` 分支返回 `0x80004005` ⇒ 上游 `HRESULT.Check` 抛未捕获异常 ⇒ 进程 `abort`。

**为什么找不到**：`wpfgfx_cor3.so` 是 **NativeAOT 共享库** —— 它内部的 `AppContext.BaseDirectory` **不是**宿主应用目录（实测 `~/.dotnet`）；`build/MilBridge/src/MilBridge.Linux/NativeSearchPath.cs` 的候选只有"与 .so 同目录／dladdr 自定位／`AppContext.BaseDirectory`／`LD_LIBRARY_PATH`"。而**装置装配出来的应用目录**是"探针产物整目录 `cp -r` ＋ `sync-applocal.sh` 五件"，`libSkiaSharp.so` **只**在 `runtimes/linux-x64/native/`（现取：`ls app/` 无顶层 `libSkiaSharp.so`；`app/runtimes/linux-x64/native/libSkiaSharp.so` 在位）。

**成对反证（同一个应用目录，只补一件）**：把 `libSkiaSharp.so` **放到 `wpfgfx_cor3.so` 同目录**再跑同一装置 ⇒

```
R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 …
```

⇒ **`E_FAIL` 的唯一缺件就是它**（不是 `T-B18` 的 foreign source，也不是任何渲染语义）。

---

## §3 二分：**哪一处"改动"引入**（含**推翻**派单两条假设）

### 3.1 ❌ 派单假设一（`T-B18` 的 `MILRenderTargetBitmapGetBitmap` ＋ `Alias` ＋ `RegisterForeignSource`）：**不成立**

- `mil.log` 里**一条** RTB/WIC 登记行都没有（`grep -c MilRenderTargetBitmap` = 0）；崩溃点在**主窗口第一帧**的 `WM_SIZE`，`RenderTargetBitmap` 那一路**根本不被走到**。
- 更强的一条：**把 `libSkiaSharp.so` 补上之后，现树（含 `T-B18`／`T-B19` 全部改动）`R_GATE=PASS 13/13`** ⇒ `#82` 的产品代码**没有**语义回归。

### 3.2 ❌ 派单假设二（T-B11/12/15/16 的 env 闸）：**不成立**

`clickprobe` 应用**不建流文档**；四道闸（`WPF_PTS_FLOAT_AVOID`／`WPF_PAGEPAGE_REDRIVE`／`WPF_PAGEVIEW_ONSCREEN`／`WpfLinuxPresentationUITheme`）的射程是 `PresentationFramework` 的页/文档路径 ⇒ 与主窗口首帧无关。旁证（同车道早先留档）：空档／`WPF_PAGEPAGE_REDRIVE`／`WPF_PTS_FLOAT_AVOID0` 三档 `/tmp/rg-*.log` 读数**逐字相同**（都 `NOINFO window-absent`）。

### 3.3 ✅ 真因：**`#82` 波的构建输出清理**把"应用目录赖以工作的那份 `libSkiaSharp.so`"清掉了

- **历史绿的机制**（**现取、成对**）：`R-GATE` 装置的默认装配是 `cp -r "$PROBE_SRC"/. "$APP"/` ＋ `sync-applocal.sh`（**五件里没有 `libSkiaSharp.so`，也没有 `libwpfwic.so`**）。⇒ 装置的应用目录里能有这两件，**只可能**来自 `$PROBE_SRC` ＝ `samples/WpfFeatureProbe/bin/<cfg>/net10.0` 里的**顶层副本**。
- **证据 A（历史读数）**：本仓在册的 `R-GATE` 证据里 `EVID art … wic=<sha>`（如 `wic=56278c14b4ecd672`）—— `libwpfwic.so` **同样**只可能来自那份顶层副本；`device.log` 里 `appdir_src=<自装配>` ⇒ 确系装置默认装配，不是 `--appdir`。
- **证据 B（幸存副本）**：`~/w62a/negrepo/samples/WpfFeatureProbe/bin/Release/net10.0/`（09-20 建的整仓副本）**顶层**同时有 `libSkiaSharp.so`（9,244,960 B）／`libwpfwic.so`／`libwpfwin32.so`／`wpfgfx_cor3.so`；`~/w87a/rgate1/app`（09-22）与 `~/w90a/rgate-*`（09-22）的应用目录同样四件齐 —— 都是 `cp -r PROBE_SRC/.` 的产物。
- **证据 C（现状）**：本轮现取 `EVID art … wic=MISSING`；`samples/*/bin/**` 下**顶层 `.so` ＝ 0 件**（`find samples -maxdepth 4 -name '*.so' -path '*/bin/*' | grep -v runtimes` ⇒ 0）。
- **结论**：被清掉的是 **`git` 忽略的构建产物**（`samples/WpfFeatureProbe/bin/**` 属 `.gitignore:19 **/bin/`）⇒ **无法按 commit 归因**（`git log -S"libSkiaSharp.so"` 与 `--diff-filter=D` 在 `#81` 之后都没有任何"拷贝/删除 `.so`"的改动）。时间窗：**09-22 之后、10-03 17:23 之前**（`#82` 波内），与该波记录的"**L2 回退后全量重建**"（`af685cf41`）在时间上重合。**如实记：这是"构建产物被清"，不是"产品代码被改"。**

> **一句话**：`#81` 那趟 `R_GATE=PASS` 是**被一份未受保护的手工副本撑着的绿**；副本一被清，`R_GATE` 就暴露了"桥在应用局部布局里找不到自己的 Skia"这条**真实产品脆性**。修它，才是把绿重建成**不依赖手工副本**的绿。

---

## §4 修（件:行）

| 件 | 位置 | 改动 |
|---|---|---|
| `src/WpfGfx.Linux/Interop/MilNative.Misc.cs` | `:1182` 起（文件尾，`MilExternalHandleBridge` 之后） | **只追加** `internal static unsafe class MilBridgeSkiaResolver`（**＋192 行，0 删改**；现件 `sha16=1b7b75f5ae2d8b71`） |

**它做什么**：给 AOT 桥里 **SkiaSharp 程序集**装一个 `DllImportResolver`，候选按序：`MILBRIDGE_SKIA_SO`（env）→ **本 .so 目录**（`dladdr` 自定位）→ 宿主注入目录（`MilExternalHandleBridge.SearchDirectory`）→ `AppContext.BaseDirectory` → `LD_LIBRARY_PATH`；**每一档都同时试"直接同名"与 `runtimes/<rid>/native/`（← 本修法新增的唯一一档）**。全部落空 ⇒ **返回 `0`**（交回默认探测，报完整路径错误的错）——**不伪造成功、不吞异常**。

**为什么它与既有的 `MilBridge.NativeSearchPath` 不冲突（实测，不是推断）**：`SetDllImportResolver` **按程序集、只能装一次**。用一个一次性的 `[ModuleInitializer]` 探针实测：**`WpfGfx.Linux` 的模块初始化先跑**（它是被依赖方）⇒ 由本件接管，MilBridge 那次 `SetDllImportResolver` 抛 `InvalidOperationException` 并被**它自己既有**的 `catch` 吞掉（它本来的设计就是"已有解析器就让位"）。⇒ 本件的候选集**覆盖** MilBridge 原本覆盖的每一档，**只多** `runtimes/<rid>/native/`。全部候选落空时行为与"该文件不存在"逐字一致（返回 `0`）。

**为什么是"文件尾追加"而不是"新建一件"**：`build/close-wave.sh` 的 `fp_inputs()` 用 `find src/WpfGfx.Linux -type f -name '*.cs'` 收件 ⇒ **新建 `.cs` 会让覆盖面 `237 → 238`**，而第 `[42]` 步 `FP-MANIFEST-TEETH` 的 `--expect` 是 `verify-all.sh` 里的**显式常数**（本任务**黑名单**）⇒ 新建件会把一个**绿**门禁**打红**。追进既有件 ⇒ 件数不变（现取 `FP_MANIFEST_TEETH=PASS files_n=237 declared_expect=237`）。

---

## §5 可证（成对，全部现取）

### 5.1 修后：`R_GATE=PASS`

```
用 bash build/MilBridge/tools/r-gate-step.sh --keep（装置自装配，不传 --appdir）
bridge=7152f9ac119e1bb0（＝本修法发布件）
R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 win32shim=5f9ed647c68197ae pc=83c71acfb20f26d7 src=device
```
- 证据目录：`/tmp/r-gate-step.O7LVtH85/`（终态趟）／`/tmp/r-gate-step.5h6Hp8LL/`（`18:29:32`）／`/tmp/r-gate-step.2lhfYum4/`（`18:27:36`），三趟**同 `bridge` sha、同 13/13**；`app.log` 里 `Unhandled exception` **0 条**。
- 逐格：`c01…c13` **全 PASS**（含 `c06` 的 `captured=null` 8 下、`c11` 承重连做三下、`c13` 像素 `19449`）；`px_open=19449／px_closed=577` 与在册基线**逐位相同**。
- 桥自报（只读复核）：`字形渲染器已挂上：目录=/usr/share/fonts 请求字族=DejaVu Sans … 实际面=DejaVu Sans 候选文件=299`（修前此处是 `DllNotFoundException`）。

### 5.2 反极性（**撤修 ⇒ 复现**）

```
cp -p（副本先行）⇒ git checkout -- src/WpfGfx.Linux/Interop/MilNative.Misc.cs ⇒ bash build/publish-milbridge.sh
bridge=70ba954a7cd99aac（撤修件）
R_GATE_DEVICE=NOINFO reason=window-absent pid=824733 alive=no    ← 核心已转储
R_GATE=NOINFO reason=device-window-absent detail=… window-absent pid=824733 alive=no
```
- 证据目录：`/tmp/r-gate-step.3gkWKaI0/`（`18:28:08`，`Misc.cs` 版撤修）与 `/tmp/r-gate-step.agL7VM2Z/`（`18:18:56`，早先"新建件"版撤修）——**两版都复现**。
- 复原用 `cp -p` 会把 `mtime` 带回**旧值** ⇒ 增量构建**不重编**（踩到一次：重发布后 `.so` 仍是撤修件）⇒ 必须 `touch` 源件再发布（现取已含该步；`70ba954a7cd99aac ≠ 7152f9ac119e1bb0` 是"真重编"的直接判据）。

### 5.3 门禁不回归（现取）

| 门 / 命令 | 修后读数 |
|---|---|
| `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| wc -l` vs `wc -l < …/exports.txt` | `846` vs `846` ✅（本修法**不新增任何 native 导出**：`SelfProbe` 无 `EntryPoint`） |
| `bash build/MilBridge/tools/pts-gap-count-check.sh` | `PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5f9ed647c68197ae exports=846` |
| `bash build/MilBridge/tools/pts-pages-guard.sh --legs …` | `PTS_GUARD=PASS legs=2/2`；`PTS_COLORANCHOR=PASS k=24 … hits=3` |
| `bash build/MilBridge/tools/defect-registry-check.sh` | `DEFREG=PASS declared=225 route_ids=225` |
| `bash build/MilBridge/tools/report-id-domain-check.sh` | `REPORTID=PASS files=370 ids=2266 declared=225`（`370` 含**本载体**） |
| `bash build/MilBridge/tools/fp-manifest-step.sh --expect 237` | `FP_MANIFEST_TEETH=PASS files_n=237 declared_expect=237` |
| `bash build/MilBridge/tools/r-gate-step.sh --selftest` | `R_GATE_SELFTEST=PASS cases=27 pass=27 fail=0 crit_total=13`｜`ST_ATTEST=PASS` |
| `bash build/MilBridge/tools/handoff-machine-values-check.sh`（`HANDOFF-NEXT` 复述位同趟追写后） | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0` |
| `bash build/MilBridge/tools/static-jaws-check.sh` | `STATICJAWS=PASS n=34 excluded=30 noinfo=1 n_total=64` |
| `bash build/MilBridge/tools/sentinel-spec-check.sh` | `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（宿主哨兵已按新 `SHA=7152f9ac119e1bb0`／`FP=75c7883cc3145dc8` 刷新，`mtime 18:40:06`；见 §6.1） |
| `dotnet test -c Release tests/WpfGfx.Linux.Tests/{Commands,Rendering,Windowing,HelloMil,ManagedLayer,Presentation}.Tests` | **六工程全过、0 失败**（`562/166/26/18/50/1`） |
| `bash build/MilBridge/tools/frame-presence-check.sh --app-args=--late-content --seconds=40 --magenta` | `FRAMEPRESENCE=PASS frames=80 max_colors=4113 magenta_frames=31`（应用起重器真渲染 ⇒ 本修法**不改变渲染**） |

**`tab1/tab2/tab3` 帧面**：本修法**只换 Skia 的查找路径，不换 Skia 本身**（`libSkiaSharp.so` 内容一致：`9,244,960 B`，`build/DirectWrite.Linux/wic-shim/` 与 NuGet `2.88.9` 同源）⇒ 帧面**按构造不变**。⚠️ **但 hc demo（`tab1/2/3` 的产出端）在仓外（黑名单），本轮未重跑** ⇒ 这一条**如实记 `NOINFO`**，不作断言（旁证：`FRAMEPRESENCE=PASS` ＋ `PTS_COLORANCHOR hits=3` 两处应用级读数均未回退）。

---

## §6 `NOINFO`／边界（**逐条，不冒充绿**）

1. **`SENTINEL-SPEC`（`SSC`）：本修法发布后一度 `FAIL`，随即被"收尾/冻结"侧刷新为 `PASS`（如实记全过程）**。`bridge` 现件 sha 由 `e88f82233f53d1ea → 7152f9ac119e1bb0` ⇒ 宿主侧"桥冻结标记"（`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`，**不在仓内**）当时仍是旧值 ⇒ `SSC_VALUE=FAIL key=SHA got=e88f82233f53d1ea want=7152f9ac119e1bb0`（＋`key=FP`）。**`18:40:06`** 这两枚哨兵被按新值刷新（`SHA=7152f9ac119e1bb0`／`FP=75c7883cc3145dc8`，两枚 `cmp IDENTICAL`）⇒ 现取 `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`。⚠️ **口径**：哨兵是**宿主状态**、**不在本任务写域**（本趟**未**动它）——刷新动作发生在**别的写者/收尾趟**；本件只如实记"改桥源码 ⇒ 该标记必然失配 ⇒ 需刷新"这条机制。
2. **`tab1/tab2/tab3` 帧面未重跑**：产出端在仓外 hc 工程（黑名单），见 §5.3 末段；给的是"按构造不变"＋两处应用级旁证，**不作"已复核"断言**。
3. **一条"重发布 ≠ 逐字节复现"的现场观察（值得记）**：`#82` 现件 `bridge=e88f82233f53d1ea`，而**用同一份 `HEAD` 源**在本机重发布得到 `70ba954a7cd99aac`（撤修版）／`7152f9ac119e1bb0`（修版）；**同源两次发布逐字节相同**（本趟内可复现），但与 `e88f8223` **不同**。⇒ "AOT 发布逐字节可复现"这条在册前提，**跨时间/环境这一维**本趟**未复证**（**不是**本次修法引入；已具名，供后续车道核）。
4. **`APPSYNC=MISMATCH` 未变**：`BRIDGE-ANCHOR=0`（`wpfgfx_cor3.so` 的副本**全部**等于发布记录）⇒ 与本修法无关的历史债，如实记。
5. **`FP-MANIFEST-TEETH`／`ROOT-ENTRIES`**：`T-B22` 点名的两处红已由主控提交（`3393c7390`：`--expect 236→237` ＋ ROOT 允许清单）修好；本修法**刻意不新建件**以**不再动** `--expect`（见 §4 末段）。

---

## §7 写域与边界（逐件对账）

| 件 | 面 | before → after | 说明 |
|---|---|---|---|
| `src/WpfGfx.Linux/Interop/MilNative.Misc.cs` | 产品（桥） | `＋192 / 0` 行；`sha16 → 1b7b75f5ae2d8b71` | **唯一产品改动**（文件尾追加解析器类） |
| `build/MilBridge/HANDOFF-NEXT.md` | 复述位现值位 | `＋1` 行 | `机器值契约更正 · cell=#1／#2／#3`（`inputs_fp → fd9b4064ed0f85329e9491c05c9f4c581c601b8875bf8a8eebc603d845034742`；**覆盖面件数仍 `237`**）—— 否则 `HANDOFF_MV` 因"覆盖面内件在 `ts` 之后变过"判红 |
| `build/MilBridge/.artifacts/publish/…/wpfgfx_cor3.so` | 产物 | `e88f82233f53d1ea → 7152f9ac119e1bb0`（`5,065,344 → 5,077,776 B`） | 由 `build/publish-milbridge.sh` 重建（**未改该脚本**） |
| `build/MilBridge/P1-rgate-regress-report.md` | 报告（新建） | — | **本件** |

**黑名单件**（`upstream/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`build/third-party/**`／仓外 hc 工程）：**一字未改**。`git status --porcelain` 的产品面只有上面那一件改动 ＋ 未跟踪的派单件/本载体。

**未提交**：本趟**未** `git add`／`commit`／`push`（按纪律，提交请主控决定）。

**进程与显示位**：装置自起私有 `Xvfb :88` 并按 PID 收；本报告里所有手工复核用 `:231..:236`（本机空闲档），`Xvfb` 由 `kill -TERM <PID>` 收净；`--keep` 的证据目录留在 `/tmp/r-gate-step.*`（受 `r-gate-step.sh` 的 `TTL=180min` 自清理约束、**有界**）。

---

## SELF（自指口径）

本文件自指纹口径：`head -n -1 | sha256sum | cut -c1-16`（末行即本行，逐次重算）。
