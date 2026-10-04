# `P1-wicrtb` 报告 —— `T-B18` ①`E_HANDLE` 逐跳现取 ＋ ②**真修**（MIL 侧让 RTB 位图句柄答 `IID_IWICBitmapSource` ＋ 补 `WIC` proxy 派发面）＋ ③**症状归零且反极性成立**，但**帧面判据不成立**（页仍不上屏）

> 任务：`build/MilBridge/tasks-tail2/T-B18.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T09:3x–09:5x+0800`（各格另注；**所有数值现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，**`HEAD=0ece7ccd0c5528766b64f91dd68bebb118747498`**（现取；＝ `T-B17` 收口后）。
> **开工件（现取，本席实测）**：`libwpfwin32.so=5f9ed647c68197ae`｜**`wpfgfx_cor3.so=a7a0f884b704ca96`**｜`PresentationCore.dll=eb3f61e282265518`｜
> `PresentationFramework.dll=c7732cc5b97a78ea`｜`WindowsBase.dll=05bdde9b5527bfde`｜`PresentationUI.dll=69136eecc84aa9f5`（＝**闸缺省关**的 Release 替身）。
> **本轮产物**：**`wpfgfx_cor3.so=3faac21668b4b921`**（5,036,400 B；旧 5,028,208 B）＝ `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so`（`BRIDGE_SRC_FP=0377f7ff05017fd1 BRIDGE_SRC_N=78`）。
> 装置：私有 `Xvfb :239 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §7.4）；
>   应用 ＝ 仓外 hc demo（`$APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，`DOTNET` 走 `$HOME/.dotnet`）。
> **重活全走槽**：`bash ~/heavy-slot.sh --min-avail 1500 --max-hold …`（本席 **8 趟腿**，全部 `HEAVYSLOT=ACQUIRED … RELEASED rc=0`）。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**；`upstream/**` 与**生成件**行号**分别标注**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① `E_HANDLE` 成因（逐跳现取）** | 抛点 `MS.Internal.HRESULT.Check`；调用点 `BitmapSource.set_WicSourceHandle` 里那句 `MILUnknown.QueryInterface(value, IID_IWICBitmapSource, out wicSource)`（`BitmapSource.cs:584`）；触发 `RenderTargetBitmap.FinalizeCreation()`（`:256` 的 `WicSourceHandle = bitmapSource;`）；本侧落点 **`src/WpfGfx.Linux/Interop/MilNative.Misc.cs`（`MILQueryInterface`）→ `MilExternalHandleBridge.QueryInterface`**。**句子柄**＝ `MILRenderTargetBitmapGetBitmap`（`src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs`）里 `MilPixelBufferTable.RegisterBorrowed(target.Bitmap, "RenderTargetBitmap")` 下发的**像素缓冲令牌**。**走法**：设备对象表查不到 → 后缓冲别名表查不到 → 外部句柄桥 `IsOwnedByWic=false` ⇒ **原样退回 `E_HANDLE`**（＝该令牌不在 MIL 任何一张"可作位图源"的账上）。**别的 QI 成功例**＝`MILSwDoubleBufferedBitmapCreate` 把后缓冲令牌 `MilBackBufferSourceTable.Alias` 到一个 `WicBitmapSource` 设备对象（**:277-281**）⇒ **唯一可照搬的成功例**。§1 |
| **② 修（`P8`／可撤）** | **照搬那套体例，落到 RTB**：`MILRenderTargetBitmapGetBitmap` 首次发句柄时 ① 登记 `WicBitmapSource` 设备对象（负载 `MilRenderTargetView`，**不拥有**）＋ `MilBackBufferSourceTable.Alias`；② `MilExternalHandleBridge.RegisterForeignSource`（把位图像素**借给** shim ⇒ `IWICBitmapSource_GetSize/GetPixelFormat/GetResolution` 能在 proxy 层派发）。清理在 `MilRenderTargetState.Dispose`（先注销外来源→摘别名→摘句柄→释放位图）。**无 env 闸、缺省生效**（真修）；**反极性 ＝ 换回开工件 `.so`**。§2 |
| **③ 判据（症状面）** | **`E_HANDLE` 归零：成立**（旧 `.so` 4/4 腿 `=1`；新 `.so` 4/4 腿 `=0`；同 env 同序**唯一差别**就是 `.so`）。**直读**：`WIC_TRACE FOREIGN_SOURCE_REGISTER ext=0x2000003c 638x362 … borrows=1` ＋ `[mil 142] NOTE … 已登记为 WIC **外来源**`，且 `E_INVALIDARG=0`（`UpdateCachedSettings` 里三个只读 proxy **无失败**）。§3.1–3.2 |
| **③′ 判据（帧面）：不成立** | `tab3` 帧的"变"**与 `.so` 解耦**：`offT_order`（旧 `.so`）与 `fixT_order`（新 `.so`）三张帧**逐字节相同**（`c22457cf`／`71a93980`／`71a93980`），**只差 `E_HANDLE`**；且 `tab3` 的**内容区色数 `148→148`、具名色 `0/0/0/0→0/0/0/0`**（`doc=(250,100,800,600)`），与修复前**逐字节同**。`fixT tab3` 与 `offT tab3` 的差异全在**左侧导航区**（`x∈[28,239]`），非文档区。⇒ **`E_HANDLE` 不是"上屏阻断者"**（承 `T-B17` §7.1 的证伪，本轮**再确认**），**`PRECOND-TAB3-PAGE-RENDER` 仍在**。§3.3–3.5 |
| **③″ 抖动具名** | 同 `(产物, env, 序)` 的帧**不是纯函数**：`tab1=c22457cf` ⇔ `tab3=71a93980`；`tab1=d7126edb` ⇔ `tab3=6f3d3ad1`（两种成对变体）。⇒ **只采同腿/同序对照**，不跨趟比 `sha16` 绝对值（＝`T-B17` 的 `NOINFO-TB17-DEMO-VARIANCE`）。§3.4 |
| **④ 门禁（现取）** | `NM_EQ_EXPORTS=PASS`（**846==846**，`diff -q` 空）｜`PTSGAP=PASS … so16=5f9ed647c68197ae exports=846`｜`PTS_GUARD=PASS legs=2/2`｜`PTS_COLORANCHOR=PASS k=24 … hits=3`｜`DEFREG=PASS declared=225 route_ids=225`｜`REPORTID=PASS files=365 ids=2266 declared=225`。另跑 `ManagedLayer.Tests`：**失败 0／通过 50／跳过 26**。§4 |
| **⑤ 症状门（成对）** | `magenta=0`／`Unrecoverable=0`／`PTS_GAP entry=0`／`FORMATLINE-LINE=156`／`alive=yes`／`app_rc=143`（各腿同；**按 PID 收**）；`[HC-UNHANDLED]`：旧 `.so` **465–563** ∧ `E_HANDLE=1`；新 `.so` **408–590** ∧ `E_HANDLE=0`。§5 |
| **⑥ 边界（未违）** | 仓内**只改** `src/WpfGfx.Linux/Interop/**`（两件）；**未碰** `upstream/**`（只读）／仓外 hc 工程／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（只调不改）；**未跑**整趟 `verify-all`；app-local **六件与仓内权威件逐件一致**；显示位与进程**按 PID 收净**。**方案数 = 1**（≤3）。§7 |

**一句话**：`PRECOND-WIC-RTB` 本轮**落地为真修** —— 照 `WriteableBitmap` 后缓冲那套"别名 ＋ shim 外来源"体例，让 `RenderTargetBitmap` 的位图句柄**能被 QI 成 `IWICBitmapSource`**，且 `UpdateCachedSettings()` 的三个只读 proxy **全部成功**；`E_HANDLE` 由 **1→0**（反极性：换回开工件 `.so` ⇒ 回 `1`）。**但帧面判据不成立**：换 `.so` **一字不改帧**（三序两趟逐字节同），`tab3` 内容区仍 `148`／具名色仍 `0` ⇒ 真断点仍是 **`PRECOND-TAB3-PAGE-RENDER`（宿主已接出并 Arrange，但没有渲染趟把页排上屏）**。本轮**如实划界，不假成功**。

---

## §1 ① 现取：`MILQueryInterface` 对 RTB 位图句柄**为什么答 `E_HANDLE`**

### 1.1 本轮现取栈（`offT_probe` 腿：开工件 `.so` ＋ `WPF_EHANDLE_PROBE=1`；`app.log` **原文**）

```
[EHANDLE] #3 msg=The handle is invalid.
 (0x80070006 (E_HANDLE))
[EHANDLE]   at MS.Internal.HRESULT.Check(Int32 hr)
[EHANDLE]   at System.Windows.Media.Imaging.BitmapSource.set_WicSourceHandle(BitmapSourceSafeMILHandle value)
[EHANDLE]   at System.Windows.Media.Imaging.RenderTargetBitmap.FinalizeCreation()
[EHANDLE]   at System.Windows.Media.Imaging.RenderTargetBitmap..ctor(Int32 pixelWidth, Int32 pixelHeight, Double dpiX, Double dpiY, PixelFormat pixelFormat)
[EHANDLE]   at System.Windows.Controls.Primitives.DocumentPageView.DuplicatePageVisual()
[HC-UNHANDLED] #476 COMException: The handle is invalid.
 (0x80070006 (E_HANDLE)) ｜ 首帧 at MS.Internal.HRESULT.Check(Int32 hr)
```

> 比 `T-B17` §2.2 更完整：本轮捕到 `DocumentPageView.DuplicatePageVisual()` 一层（`T-B17` 那趟只到 `FinalizeCreation`）。`#1`／`#2` 与 `T-B17` 同形（`#1` 只有抛点一帧）——**如实记**。

### 1.2 逐跳（件:行 ＋ 内容锚原文）

| 跳 | 件:行（现取） | 内容锚原文 | 说明 |
|---|---|---|---|
| 甲 | `upstream/…/PresentationCore/…/Imaging/BitmapSource.cs:584` | `HRESULT.Check(UnsafeNativeMethods.MILUnknown.QueryInterface(`<br>`    value, ref _uuidWicBitmapSource, out wicSource));` | **调用点**（`WicSourceHandle` 的 **setter**，属性定义同件 `:563`）；`_uuidWicBitmapSource = MILGuidData.IID_IWICBitmapSource` |
| 乙 | `upstream/…/Imaging/RenderTargetBitmap.cs:256` | `WicSourceHandle = bitmapSource;` | 由 `FinalizeCreation()`（`:227`）执行；`:247` `MILRenderTargetBitmap.GetBitmap(renderTargetBitmap, out bitmapSource)` 即**句柄的产出点** |
| 丙 | `upstream/…/Controls/Primitives/DocumentPageView.cs:961` | `RenderTargetBitmap renderTargetBitmap = new RenderTargetBitmap((int)pageVisualRect.Width, (int)pageVisualRect.Height, 96.0, 96.0, PixelFormats.Pbgra32);` | `RTB` 在这里造；触发链 `SinglePageViewer.cs:1000 pageViews[index].DuplicateVisual()` → `DocumentPageView.cs:626 DuplicateVisual()` → `:942 DuplicatePageVisual()` |
| 丁 | `src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs`（`MILRenderTargetBitmapGetBitmap`） | `target.BitmapHandle = MilPixelBufferTable.RegisterBorrowed(`<br>`    target.Bitmap, "RenderTargetBitmap");` | **该句柄是谁造的**：`MilPixelBufferTable` 的**借用**条目（只发句柄、不接管位图），是"像素缓冲令牌" |
| 戊 | `src/WpfGfx.Linux/Interop/MilNative.Misc.cs`（`MILQueryInterface`） | ① `MilDeviceObject obj = MilDeviceObjectTable.Resolve(resolved);`<br>② `IntPtr dev = MilBackBufferSourceTable.ResolveDevice(pIUnknown);`<br>③ `return MilExternalHandleBridge.QueryInterface(pIUnknown, ref guid, out ppvObject);` | **`IID_IWICBitmapSource` 请求走到哪一步**：① RTB 令牌**不在设备对象表**、② **不在后缓冲别名表**、③ 外部桥 `IsOwnedByWic(...)` **返 false**（不是 WIC shim 的句柄）⇒ `MilExternalHandleBridge.QueryInterface` 首行 `return HResult.E_HANDLE;`。**这一句就是 `E_HANDLE` 的产地** |

### 1.3 现取：**别的 QI 成功例（可照搬）**

**唯一成功例 ＝ `WriteableBitmap` 后缓冲**：`MILSwDoubleBufferedBitmapCreate`（`src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs`）在创建设备对象后做了两件事——

```
MilDeviceObject backObj = MilDeviceObjectTable.Register(
    MilDeviceObjectKind.WicBitmapSource,
    new MilBackBufferView(state, state.BackBufferHandle),
    $"swdbb back buffer {width}x{height}");
MilBackBufferSourceTable.Alias(state.BackBufferHandle, backObj.Handle);
```

于是**同一个** `MILQueryInterface` 对它答 `S_OK`（走 ① 分支：`guid == IID_IWICBitmapSource && obj.Kind == MilDeviceObjectKind.WicBitmapSource`，见 `MilNative.Misc.cs` 的 `bool wicOk = …`）＋ `AddRef`／`Release` 与主对象**共用同一张账**。
RTB 缺的正是这两步 —— 句柄只登记在 `MilPixelBufferTable` 里，**没有**任何"可作位图源"的设备对象认领它。

### 1.4 现取：**光放行 QI 还不够**（本次修的第二个半件）

`BitmapSource.set_WicSourceHandle` 在 QI 成功后**紧接着** `UpdateCachedSettings()`（`BitmapSource.cs:590`），后者调
`PixelFormat.GetPixelFormat(_wicSource)`（`PixelFormat.cs:503-509` → `WICBitmapSource.GetPixelFormat`）与
`WICBitmapSource.GetSize`／`GetResolution`。这三个 P/Invoke 的 `DllImport` 落在 **WIC shim**
（`upstream/…/UnsafeNativeMethodsMilCoreApi.cs:399-421`，`DllImport.WindowsCodecs`）——**不是** MIL 的账。
⇒ 若只让 QI 成功而不把 RTB 句柄登记成 shim 的**外来源**，下一步会换成 `E_INVALIDARG`（`as_source` 表查不到）。
本轮的修**两件一起做**（§2）。

---

## §2 ② 修：RTB 位图句柄＝可 QI 的 `WicBitmapSource` ＋ shim 派发面（`P8`／可撤）

### 2.1 落点（件:行；**只改 `src/WpfGfx.Linux/Interop/**` 两件**）

| 件 | 改动 | 内容锚 |
|---|---|---|
| `src/WpfGfx.Linux/Interop/MilHandleTables.cs` | **新增** `MilRenderTargetView : IMilNonOwningPayload`（RTB 位图句柄的设备对象**视图负载**：指向 `MilRenderTargetState`、**不拥有**） | 类头注释含「`RenderTargetBitmap.FinalizeCreation`（`RenderTargetBitmap.cs:256`）把 `GetBitmap` 的产物赋给 `WicSourceHandle`…」 |
| `src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs` | ① `MILRenderTargetBitmapGetBitmap`：首次发句柄时**登记别名 ＋ 外来源**；② 新增 `WicGuidForPixelFormat`／`IsOpaquePixelFormat` 两个 helper；③ `MilRenderTargetState`：加 `WicSourceDeviceHandle` 字段，`Dispose` 里**注销外来源 → 摘别名 → 摘句柄**（顺序同 `MilDoubleBufferedState.Dispose`） | 见下 |

**核体（`MILRenderTargetBitmapGetBitmap` 新增段，**与后缓冲那套逐条同形**）：**

```
MilDeviceObject wicObj = MilDeviceObjectTable.Register(
    MilDeviceObjectKind.WicBitmapSource,
    new MilRenderTargetView(target, target.BitmapHandle),
    $"rtb bitmap {target.Width}x{target.Height}");
MilBackBufferSourceTable.Alias(target.BitmapHandle, wicObj.Handle);

Guid foreignFormat = WicGuidForPixelFormat(target.PixelFormat);
bool isOpaque = IsOpaquePixelFormat(target.PixelFormat);
IntPtr pixels = target.Bitmap.GetPixels();
uint rowBytes = (uint)target.Bitmap.RowBytes;
int regHr = MilExternalHandleBridge.RegisterForeignSource(
    target.BitmapHandle, ref foreignFormat, (uint)target.Width, (uint)target.Height,
    isOpaque, pixels, rowBytes);
```

**为什么"照搬"而不是"新造一条"**：`MilBackBufferSourceTable` 的类注释已把语义写死为"**MIL 自己下发的像素缓冲令牌 → 一个可作位图源的设备对象**"（不区分后缓冲／渲染目标）；`MILQueryInterface` 的 ① 分支也只认这个表。再开一张表会让"哪些令牌可作位图源"出现**两个真相**。

**`pixelFormat → WIC GUID` 的映射不是猜的**：WIC 的像素格式 GUID 只有**最后一个字节**承载格式号，基础 `{6fddc324-4e03-4bfe-b185-3d7776 8dc9 00}`（＝ `MilPixelFormats.DontCare`）；上游 `PixelFormat.GetPixelFormat(Guid)`（`PixelFormat.cs:517-523`）正是按 `guidBytes[15]` 反查 ⇒ **两个方向互为证据**。

### 2.2 幂等与可撤

- **可撤（反极性）**：本增量**无 env 闸、缺省生效**（真修）。反极性用**换回开工件 `.so`（`a7a0f884b704ca96`）**实现 —— 比"加一个闸"更贴近"撤修 ⇒ 回 `E_HANDLE`"的口径（§3.5 实测成立）。
- **`P8`（生成器幂等）**：本轮**未改任何生成器**（改的是 `src/**` 手写件），故 `reapply-patches.py` 幂等性不受影响（`T-B17` §3 已证 `IDEMPOTENT=OK`，本轮未触碰）。
- **副本先行**：`cp -p` 取在**任何写之前**（§7.2）。

---

## §3 ③ 真跑：成对读数 ＋ 反极性 ＋ **帧面否证**

### 3.1 腿表（现取；装置 `:239`；`sha16` ＝ 整屏 `import -window root`）

**共同环境**：`PresentationFramework.dll=c7732cc5b97a78ea`、`PresentationUI.dll=a901772b7589382a`（＝`T-B16` 的 `-p:WpfLinuxPresentationUITheme=true` 产物，`T-B17` 具名；**主题开**，`E_HANDLE` 只在此形态出现）。**`.so` 与 env 是唯一变量。**

| 腿 | `wpfgfx_cor3.so` | env | 序 | `tab1` | `tab2` | `tab3` | `E_HANDLE`（`0x80070006 (E_HANDLE)`） |
|---|---|---|---|---|---|---|---|
| `offT_tabs` | `a7a0f884`（开工件） | — | `1,2,3` | `d7126edb` | `d7126edb` | `6f3d3ad1` | **1** |
| **`offT_tabs2`** | `a7a0f884` | — | `1,2,3` | `c22457cf` | `c22457cf` | `71a93980` | **1** |
| `offT_probe` | `a7a0f884` | `WPF_EHANDLE_PROBE=1` | `1,2,3` | `d7126edb` | `d7126edb` | `6f3d3ad1` | **4**（probe 记账口径，见 §3.6） |
| **`fixT_tabs`** | `3faac216`（本轮） | — | `1,2,3` | `c22457cf` | `c22457cf` | `71a93980` | **0** |
| `fixT_tabs2` | `3faac216` | — | `1,2,3` | `c22457cf` | `c22457cf` | `71a93980` | **0** |
| `fixT_trace` | `3faac216` | `WPF_LINUX_MIL_TRACE=1`＋`WPF_LINUX_WIC_TRACE=1` | `1,2,3` | `d7126edb` | `d7126edb` | `6f3d3ad1` | **0** |
| **`fixT_order`** | `3faac216` | — | `3,2,1` | `o1=c22457cf` | `o2=71a93980` | `o3=71a93980` | **0** |
| **`offT_order`** | `a7a0f884` | — | `3,2,1` | `o1=c22457cf` | `o2=71a93980` | `o3=71a93980` | **1** |
| `wicFixTabs`（**主题关**对照） | `3faac216` | —（`PUI=69136ee`） | `1,2,3` | `c22457cf` | `c22457cf` | `0c51d1ad` | **0** |

### 3.2 **症状成对（唯一差别 ＝ `.so`）** ⇒ `E_HANDLE` **归零**

| 面 | 旧 `.so`（`a7a0f884`） | 新 `.so`（`3faac216`） | 判 |
|---|---|---|---|
| `E_HANDLE`（`1,2,3` 序，2 趟） | **1**／**1** | **0**／**0** | **归零** |
| `E_HANDLE`（`3,2,1` 序，1 趟） | **1** | **0** | **归零** |
| `E_HANDLE`（trace 趟） | — | **0** | — |
| `[HC-UNHANDLED] … COMException` | **1** | **0** | **同步归零** |

**直读（`fixT_trace`，`app.log` 原文；证明 QI 成功 ＋ WIC 面真存在）：**

```
WIC_TRACE FOREIGN_SOURCE_REGISTER ext=0x2000003c 638x362 opaque=0 pixels=0x5fa8713aa950 rowBytes=2552 borrows=1
[mil  142] NOTE MILRenderTargetBitmapGetBitmap: 位图 0x2000003c 已登记为 WIC **外来源**（638x362 format=6fddc324-4e03-4bfe-b185-3d77768dc910 isOpaque=0；借用像素=0x5fa8713aa950 rowBytes=2552（**注销前必须有效**）；记账未变（引用计数仍全在 MilDeviceObjectTable））
WIC_TRACE FOREIGN_SOURCE_UNREGISTER ext=0x2000003c borrows=0
```

- `638x362` ＝ 页视觉尺寸（与 `T-B17` §7.2 的 `hostRender=638.4x362.88` 同量级）；
- `E_INVALIDARG=0`、`0x80070057=0`（**同一趟**）⇒ `UpdateCachedSettings()` 的三个只读 proxy **全部成功**（§1.4 的第二半件也被证到）；**若只放行 QI**，这里会立刻出现 `E_INVALIDARG`；
- `FOREIGN_SOURCE_UNREGISTER … borrows=0` ⇒ `MilRenderTargetState.Dispose` 的拆除顺序**真的跑了**（登记／注销配平）。

### 3.3 **帧面：判据不成立**（`doc=(250,100,800,600)`）

| 腿 | `tab3` `sha16` | `tab3` 整屏 `colors` | `tab3` 文档区 `doc_colors` | `tab3` 具名色（`GhostWhite`/`Beige`/`DarkGreen`/`LightGoldenrodYellow`） |
|---|---|---|---|---|
| 旧 `.so`（`offT_tabs2`／`offT_order`） | `71a93980` | 562 | **148** | **0/0/0/0** |
| 新 `.so`（`fixT_tabs`／`fixT_tabs2`／`fixT_order`） | `71a93980` | 562 | **148** | **0/0/0/0** |

⇒ **`tab3` 内容区色数 `148→148`、具名色 `0/0/0/0→0/0/0/0`，与修复前逐字节同**。任务判据的三项（"色数回升／具名色出现／帧 `sha16` 变"）里**前两项明确不成立**；第三项见 §3.4（**不是修复引起**）。

### 3.4 **`tab3` 帧的"变"是运行抖动，不是修复**（本轮关键否证）

**(a) 同序、同 env，只差 `.so` 的两趟，三张帧逐字节相同：**

```
offT_order（旧 .so）：o1_t6=c22457cf663453dd  o2_t6=71a93980be1f49a6  o3_t6=71a93980be1f49a6  EHANDLE=1
fixT_order（新 .so）：o1_t6=c22457cf663453dd  o2_t6=71a93980be1f49a6  o3_t6=71a93980be1f49a6  EHANDLE=0
```

**(b) `1,2,3` 序亦然：**

```
offT_tabs2（旧 .so）：tab1=c22457cf  tab2=c22457cf  tab3=71a93980  EHANDLE=1
fixT_tabs （新 .so）：tab1=c22457cf  tab2=c22457cf  tab3=71a93980  EHANDLE=0
```

**(c) 而 `.so` 不变、只是换一趟，`tab3` 就换了**（`fixT_trace` 用**同一个新 `.so`** 得到 `6f3d3ad1`；`offT_tabs` 用**同一个旧 `.so`** 也得到 `6f3d3ad1`）：

| 对应关系（现取，三种成对变体） | `tab1` | `tab3` |
|---|---|---|
| 变体 A | `c22457cf` | `71a93980` |
| 变体 B | `d7126edb` | `6f3d3ad1` |

⇒ **`sha16` 的变化与 `.so` 完全解耦**（旧 `.so` 能得 `71a93980`，新 `.so` 能得 `6f3d3ad1`）。**该"变"属 `NOINFO`，不得记成修复的帧面证据。**

### 3.5 **反极性（撤修 ⇒ 回 `E_HANDLE`）：成立**

`offT_tabs2`／`offT_order`（换回开工件 `.so=a7a0f884b704ca96`）⇒ `E_HANDLE` 回 **1**、`[HC-UNHANDLED] … COMException` 回 **1**，且**帧与修复腿逐字节同**（§3.4）。⇒ 撤/加修**只改 `E_HANDLE`，不改帧**。

### 3.6 `tab3` 与"上一 tab 帧"的形态（自检，防 `T-B17` §4.3 那类误读）

- `fixT tab3 vs fixT tab1`：`BBOX (268,90,783,538)`（**文档区**）⇒ `tab3` 帧**不是** `tab1` 帧的复制（**未**退化成"上一 tab"）。与 `T-B17` 的 `RTB_FALLBACK` 降级形态（`tab3=tab1`）**不同**。
- `fixT_trace tab3 vs offT_tabs tab3`：`BBOX (28,169,240,564)`、`COL_RANGE 28..239` ⇒ 两腿 `tab3` 的差异**全落在左侧导航区**（`x∈[28,239]`），**不在文档区**。⇒ "文档区没变"这一读数**是稳的**。
- `offT_probe` 的 `E_HANDLE=4`（而非 1）：`WPF_EHANDLE_PROBE=1` 会**给每条首次异常记账**，`[EHANDLE]` 计数里 `E_HANDLE` 字样出现 4 次（`#1…#3` 是三条 `[EHANDLE] #n` 头 ＋ 一条 `[HC-UNHANDLED]` 行）。**如实记**：`E_HANDLE` 的**权威成对读数**取自 `grep '0x80070006 (E_HANDLE)'` 的缺省腿（§3.1），probe 腿只用于**取栈**。

---

## §4 ④ 门禁（逐条现取；本席跑的）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| awk '{print $3}' \| sort` vs `src/WpfGfx.Linux.Native/bin/exports.txt` | **`846 == 846`**，`diff -q` 空 ⇒ `NM_EQ_EXPORTS=PASS` |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5f9ed647c68197ae exports=846`**；`PTSGAP_CITED=PASS refs=1 strict=1`；rc=0 |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2 fails=- cannot=- direction=in-file phase=realized`**；`PTS_N1_GATE=PASS`；`PTS_ENFE=PASS total=0` |
| `PTS_COLORANCHOR` | 同上（`k=24`） | **`PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 min=200 base=全部0`**（**未回退**）；`k=23` `NOINFO(no-anchor-registered-for-k23)` |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`DEFREG_DECLDRIFT=0`，rc=0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=365 ids=2266 declared=225`**，rc=0（本载体落地**前**现取；落地后 ＋1） |
| （额外）测试 | `dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/…`（含 `MilWicQueryInterfaceTests`） | **失败 0／通过 50／跳过 26／总计 76** |

**未跑**：整趟 `verify-all`（照派单 ②）；`static-jaws-check.sh`。

---

## §5 ⑤ 症状门（成对）

| 症状门 | 旧 `.so`（`a7a0f884`，主题开） | 新 `.so`（`3faac216`，主题开） | 主题**关**（新 `.so`） |
|---|---|---|---|
| `magenta` | 0 | 0 | 0 |
| `Unrecoverable system error` | 0 | 0 | 0 |
| `PTS_GAP entry=` | 0 | 0 | 0 |
| `[FORMATLINE-LINE]` | 156 | 156 | 156 |
| `FailFast` | 78／86／94 | 68／88／98 | 70 |
| `[HC-UNHANDLED]` | **465／515／563** | **408／529／581／590** | 409 |
| 其中 **`COMException`＋`0x80070006 (E_HANDLE)`** | **1**（4 腿 4/4） | **0**（4 腿 4/4） | **0**（本来无） |
| `alive`／`app_rc` | yes／143 | yes／143 | yes／143（均**本席按 PID 收**） |
| `colors`（整屏；`tab3`） | 570／562 | 562／570 | 562 |

---

## §6 断点归属 · 具名前置 · 可实施替代 · `NOINFO`

### 6.1 本轮**已逐条排除/确认**（都真跑过）

| 假设 | 现取反证 |
|---|---|
| 「`E_HANDLE` 是"RTB 位图句柄不可 QI"」 | **成立并已修**：§1.2 戊 ＋ §3.2 直读（登记＋proxy 无失败） |
| 「`E_HANDLE` 是"页画不出来"的直接原因」（`T-B16` §5 的推断） | **再次证伪**：换 `.so` **一字不改帧**（§3.4），`E_HANDLE` 归零**不同时**带来色数回升/具名色（§3.3） |
| 「修复会让 `tab3` 退化成上一 tab 帧」 | `fixT tab3 vs fixT tab1` 差异在**文档区**（§3.6）⇒ **未**退化（与 `T-B17` 的降级形态不同） |
| 「`E_HANDLE` 归零会连带改变别处可见重绘」 | `tab3` 与 `tab1` 的差异**全在导航区** `x∈[28,239]`（§3.6）；文档区逐字节同 |

### 6.2 `PRECOND-WIC-RTB`：**本轮已解除**（真修）

- **原状**：本移植**没有 WIC 离屏渲染目标** ⇒ `MILUnknown.QueryInterface(rtbToken, IID_IWICBitmapSource)` 答 `E_HANDLE`。
- **现取**：`MILRenderTargetBitmapGetBitmap` 的令牌经 `MilBackBufferSourceTable.Alias` 到 `WicBitmapSource` 设备对象 ⇒ QI 答 `S_OK`（`MILQueryInterface` ① 分支）；且该令牌被登记为 shim 外来源 ⇒ `GetSize/GetPixelFormat/GetResolution` 三个只读 proxy 成功（`E_INVALIDARG=0`）。
- **反极性**：换回开工件 `.so` ⇒ 回 `E_HANDLE=1`。

### 6.3 **`PRECOND-TAB3-PAGE-RENDER`：仍在**（承 `T-B17`，本轮**收窄并加固**）

- **现取**：`E_HANDLE` 已消（4/4 腿 `=0`），但 `tab3` 内容区 `doc_colors=148`、具名色 `0/0/0/0`，与修复前逐字节同；且**同序两趟帧逐字节同、仅 `E_HANDLE` 不同**（§3.4(a)(b)）。
- **归因**：宿主已接出、已 `Arrange`、渲染树可达（`T-B17` §1.2）、托管子树有绘制（`T-B17` §1.3）—— **但读者页区域没有渲染趟被排**。`E_HANDLE` 那条异常**不是**排帧的**唯一**触发者（本轮证明：把它消掉，帧不变）。
- **可实施替代（下一步，按序）**：照 `T-B17` §7.2 的 **(i)**：在本移植的**失效汇聚点**（`MediaContext` → `HwndTarget.Linux.cs` → `MilConnection_CommitChannel`）给"某子树失效但**没有排帧**"加**只读**读数。**判据可证伪**：失效请求在、排帧不在 ⇒ 断点在**排帧调度**；失效请求本身没发 ⇒ 断点在 `DocumentPageView`/`ReaderPageViewer` 的**失效源**。

### 6.4 `NOINFO`（具名）

- **`NOINFO-TB18-FRAME-DECOUPLE`**：`tab3` 帧的 `sha16` 在 `(产物, env, 序)` 相同下**不唯一**（变体 A `c22457cf/71a93980`、变体 B `d7126edb/6f3d3ad1`），且**与 `.so` 解耦**。⇒ **本增量的帧面判据只采"同序两趟逐字节同"这一形态**（§3.4），**不**把"帧变"记成修复证据（＝`T-B17` 的 `NOINFO-TB17-DEMO-VARIANCE`）。
- **`NOINFO-TB17-EHANDLE#1-STACK`（承接）**：`WPF_EHANDLE_PROBE` 的 `#1/#2` 仍只捕到抛点一帧（`#3` 才给到 `DuplicatePageVisual`）；未做进一步归因。
- **`NOINFO-TB16-TAB2-FORM`（承接，本席未解）**：`tab2` 的开工形态（主题**关** `3,2,1` 序）本轮未改；`[HC-UNHANDLED]` 与 `FailFast` 在**主题开**下逐腿波动（`465–590`／`68–98`），**与本增量的 `.so` 无单调关系** ⇒ 如实划界，不归因。

---

## §7 边界 · 收净 · 自证

1. **写域（现取 `git status --porcelain`）**：
   ```
    M src/WpfGfx.Linux/Interop/MilHandleTables.cs      ← 改动件（新增 MilRenderTargetView）
    M src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs  ← 改动件（GetBitmap 登记 ＋ Dispose 清理 ＋ helper）
   ?? build/MilBridge/tasks-tail2/T-B18.md             ← 任务件（开工前就在，未跟踪）
   ```
   **无** `upstream/**`、**无** `build/**` 其它件（publish 产物落 `.artifacts`，不在跟踪面）、**无** `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`。
2. **副本先行／写前备份**（`cp -p`，取在**任何写之前**）：`~/tb18-work/bak/{MilHandleTables.cs.orig=083b02d09956d42c, MilNative.Offscreen.cs.orig=21221bf12e176e69}`。另存**开工件 `.so`** 用于反极性：`~/tb18-work/bak/wpfgfx_cor3.so.orig=a7a0f884b704ca96`。
3. **`src` 改动件 `sha16`（现取）**：`MilNative.Offscreen.cs=2e9a4c13fc8ffe0e`｜`MilHandleTables.cs=324d96103dfbf60b`。
4. **app-local（现取，收净后）＝ 仓内权威件**：
   `libwpfwin32.so=5f9ed647c68197ae`（未动）｜**`wpfgfx_cor3.so=3faac21668b4b921`**（＝本轮 publish 产物）｜`PresentationCore.dll=eb3f61e282265518`（未动）｜`PresentationFramework.dll=c7732cc5b97a78ea`（未动）｜`WindowsBase.dll=05bdde9b5527bfde`（未动）｜`PresentationUI.dll=69136eecc84aa9f5`（收净回缺省关位）。
   腿内覆盖由 `leg.sh` 的 `trap` 在腿末**还原**为仓内权威位（每腿末 `RESTORED so=3faac216… pui=69136ee… pf=c7732cc5…`）。
5. **进程／显示位按 PID 收净**：`:239` 的 `Xvfb(3595746)`／`xfwm4 --compositor=off(3595754)` 已按 PID 收；现取 `ps` **无任何 `Xvfb`／`HandyControlDemo`**、`/tmp/.X11-unix/X239` 已消失（余 `X0`／`X1`／`X11` 非本席）。8 趟腿的 `HandyControlDemo` 全部按 PID 收（`APP_RC=143`＝本席 `kill`）。另有一个 `xfwm4(2617727)` **不是本席**（10-02 起，开工前已在），**未动**。
6. **构建**：`dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj -c Release`（**0 警告 0 错误**）→ `bash build/publish-milbridge.sh`（AOT publish，`held≈20 s`，产物 `3faac21668b4b921`）。
7. **黑名单未碰**：`upstream/**`（**只读**）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。**未跑**整趟 `verify-all`。**未** `git add/commit/push`。
8. **纪律自证**：重活走槽（8 趟，全部 `ACQUIRED…RELEASED rc=0`）；显示位只用空闲 `:239`；**接线可撤**（反极性＝换回开工件 `.so`）；**仪器不扰动**（trace 腿与缺省腿帧逐字节同）；**报数一律现取**（纪律 40）；**未伪造几何／台账**；**未假成功**（帧面判据不成立即记不成立，并给具名前置 ＋ 可实施替代）；**方案数 = 1（≤3）**；**`tests/**` 不在本任务写域 ⇒ 未新增单测**（如实划界），只**跑**既有 `ManagedLayer.Tests` 确认零回归。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-wicrtb-impl-report.md | sha256sum | cut -c1-16`）＝ **`97ed27f2b25feeb4`**（本行下方无内容，取该行之前全文的哈希）。
