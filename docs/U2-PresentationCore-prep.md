# PresentationCore 编译预研（M4 交付）

> 状态：**编译预研完成，尚未 0 错**。本轮目标是把「下一步必然踩的坑」清空：骨架已生成、剔除清单已定、shim 已补齐并探针验证、剩余阻塞已量化到文件与错误码。
> 上游全程只读（`upstream/wpf` 零写入）；本轮新增/修改文件见文末「交付物清单」。
> 实测环境：dotnet SDK 10.0.111 / net10.0 / Linux x64；所有数字均可按 §附录 的命令复现。

## 0. 一句话结论

生成阶段暴露的 6031 条错误里，**99% 不是 PresentationCore 自身的问题**：其中 290+ 条源于一处本工程范围的构建口径缺陷（`Microsoft.NETCore.App.Ref` 的 WindowsBase **门面程序集**压过了我们的真 WindowsBase.dll），另有 290 条源于本工程输出未按上游 IVT 要求公开签名；两者修掉后剩 500 条，再由 9 个「port-lib 默认 glob 误纳文件」与 8 个 OLE 栈文件（实测离线不可满足：私有包 `System.Private.Windows.Core` 在镜像上 **NU1101 不存在**）的剔除降到 376 条；M3 三个小项目的 DLL 落地后剩 **118 条**（唯一 114）。**唯一的成规模剩余阻塞是 DirectWriteForwarder（C++/CLI 项目，被 port-lib 丢弃）的 41 个托管类型（102 条错误）**，它同时解释了 9 条错误的 `GlyphOffset` 与 6 条 `Span` —— 这两个「凭空缺失」的类型经查是上游 C++/CLI 头文件 `private value struct` / `private ref struct` 定义、经 IVT 暴露给 PresentationCore 的。

**0 错预测：再 2–4 轮**（新建 DWriteForwarder 托管骨架 ≈2 轮，OLE 公开 API 路线决定 ≈1 轮，警告清零 ≈1 轮）；运行期另计。

---

## 1. `port-lib` 生成结果摘要（交付物 ①）

生成命令与结论：

```bash
python3 build/port-lib.py PresentationCore
# [PresentationCore] 源文件 1357（找回 214）/ 缺失 0 | 丢弃 PR 8(vcx 1) 私有 1 Target 0 Import 2
```

| 项 | 数值 | 说明 |
|---|---|---|
| 上游 csproj `<Compile Include>` 条目 | **1356** | `grep -c '<Compile Include'` = 1357，XML 解析 1356（差 1 条在 XML 注释里，非真实条目） |
| 解析成功（写入 csproj） | **1357** | 1356 解析命中 − 8 剔除 + SR.g.cs；另有 9 个 glob 误纳文件由补丁 C 摘掉（见下） |
| 按大小写不敏感精确路径找回 | **214** | 与扫描报告 §4.3 预估的 212 吻合（多 2 条为 `Shared//ms/internal/generated/*`） |
| **仍缺失** | **0** | 全部命中；另 9 个「不该在清单里」的文件见 §2.1 |
| 最终编译文件数（MSBuild 实算） | **1349** | `@(Compile)->Count()` |
| 丢弃 ProjectReference | 8（含 vcxproj 1） | → 本地引用重接 5 个 DLL |
| 丢弃私有 WinForms 引用 | 1 | `System.Private.Windows.Core`，离线不可补（§2.2） |
| 丢弃代码生成 Target | **0** | 上游产物均已 checked-in（`AvTraceMessages.cs` / `wgx_commands.cs` / `exports.cs`） |
| DefineConstants | `CORE_NATIVEMETHODS;PRESENTATION_CORE;COMMONDPS;WINDOWS_BASE_OR_PC` | SR 命名空间 `MS.Internal.PresentationCore` ✅ |

### 1.1 本地引用解析情况（含「当时未解析」的历史记录）

生成当刻（M3 尚未产出 DLL）port-lib 静默丢弃了 4 个 ProjectReference（它只打印计数，不打印未解析名字）：

| 上游 ProjectReference | 生成当刻 | 现在（M3 落地后重跑） |
|---|---|---|
| `WindowsBase.csproj` | ✅ 已解析 | ✅ `build/WindowsBase.Linux/bin/Debug/WindowsBase.dll` |
| `System.Xaml.csproj` | ✅ 已解析 | ✅ `build/System.Xaml.Linux/bin/Debug/System.Xaml.dll` |
| `System.Windows.Input.Manipulations.csproj` | ❌ 未解析（DLL 不存在） | ✅ `build/System.Windows.Input.Manipulations.Linux/bin/Debug/System.Windows.Input.Manipulations.dll` |
| `UIAutomation/UIAutomationTypes.csproj` | ❌ 未解析 | ✅ `build/UIAutomationTypes.Linux/bin/Debug/UIAutomationTypes.dll` |
| `UIAutomation/UIAutomationProvider.csproj` | ❌ 未解析 | ✅ `build/UIAutomationProvider.Linux/bin/Debug/UIAutomationProvider.dll` |
| `System.Windows.Primitives.csproj`（CsWin32 宿主） | ❌ 未解析 | ❌ **永不解析**：它是 CsWin32 代码生成宿主，Linux 上线用 `build/shims/WindowsWin32.Shim.cs` 替代（WindowsBase 先例），其 `AssemblyInfo.cs` 里的 `[assembly: CLSCompliant(false)]` 是 PresentationCore 37 条 CS3021 警告的根因（§5） |
| `DirectWriteForwarder.vcxproj`（C++/CLI） | ❌ 丢弃 | ❌ 必须新建托管等价工程（§5 阻塞 #1） |
| `ref/PresentationCore-ref.csproj` | 跳过（`-ref`） | 跳过 |

> 教训（供 port-lib 改进）：`unresolved_refs` 目前只存在于脚本内部变量，既不打印也不进 PORT-CHANGES.md；本轮是人工逐条对照上游 csproj 才定位到「Manipulations/UIAutomation* 未接」。建议 port-lib 把未解析 ProjectReference 名单写进 PORT-CHANGES.md。

### 1.2 生成物里「明显不该在清单里」的文件（实测 9 个）

port-lib 的 SDK 默认 glob 把上游**刻意不编**的 9 个文件加了进来，其中 `NativeMethodsMilCoreApi.cs` 一条就引发 30 条跨文件错误（§2.1）。这 9 个文件已由补丁 C 显式 `Compile Remove`。

### 1.3 生成物需要的三处补丁（`build/PresentationCore.Linux/reapply-patches.py` 可重放）

port-lib 会整份重写 csproj，故三处补丁必须可重放；已把补丁原文固化进 `reapply-patches.py`（幂等，重跑 port-lib 后执行一次即可）。

| 补丁 | 目的 | 实测影响 |
|---|---|---|
| **A** `WpfLinux_DropFrameworkWindowsBase` | 摘掉目标包注入的「无 HintPath」WindowsBase 引用项 | 错误 **6031 → 878**（−5153）：`Microsoft.NETCore.App.Ref/ref/net10.0/WindowsBase.dll` 是门面程序集（v4.0.0.0, PKT 31bf3856ad364e35），我们的真 DLL 是 0.0.0.0/无签名，`_HandlePackageFileConflicts` 按「版本高者胜」判定门面胜出，于是 `System.Windows`/`DependencyObject`/`Point`/`Dispatcher` 全部消失（CS0234/CS0246 级联） |
| **B** `PublicSign` + `NoWarn SYSLIB5005` | 用只含公钥的 `build/keys/WcpPublicKey.snk` 公开签名 | 错误 **878 → 500**（−378）：WindowsBase 的 `[InternalsVisibleTo("PresentationCore, PublicKey=<WCP>")]` 拒绝未签名程序集，实测 CS0281 ×290，并连带 CS0115（不能重写 internal 虚成员）CS0426（internal 嵌套类型不可见）。.NET Core 不校验强名称签名，故公开签名产物在 Linux 可用（上游 dotnet/wpf 在 Linux 构建也走公开签名） |
| **C** 9 条 `Compile Remove` | 摘掉 §1.2 的误纳文件 | 错误 **500 → 418**（−80），警告 **−37**（CS0436 `MS.Win32.NativeMethods` 冲突），**新增 0** |

**补丁 A/B 是本工程范围的坑，不只影响 PresentationCore**：任何引用我们的 `WindowsBase.dll` 的项目都会踩到（M3 三个项目的 csproj 里是同样的 `<Reference Include="WindowsBase">` 写法）。建议把 A 的目标搬进 `build/Directory.Upstream.props`（一处生效、且能扛住 port-lib 重跑），B 的签名属性搬进 port-lib 生成的 PropertyGroup。**本轮未改这两处共享文件**（文件所有权约束 + 避免与并行 agent 冲突）。

### 1.3.1 与并行 agent「程序集身份版本」方案的关系（重要，避免重复劳动/互相抵消）

本轮工作期间，另一个 agent 新建了 `build/shims/LinuxAssemblyIdentity.cs`：把自产 WPF 程序集的 `AssemblyVersion` 抬到 **4.0.0.1**，从而在冲突解析中赢过门面（4.0.0.0）。它与补丁 A 解决**同一个门面冲突**，但机制不同：

| 方案 | 编译期 | 运行期绑定 | 现状（14:20 实测） |
|---|---|---|---|
| 身份版本 4.0.0.1（`LinuxAssemblyIdentity.cs`） | 赢冲突解析（版本高者胜） | **同时修好**（host 绑 app-local 自产程序集） | 文件已在 `build/shims/`，但**尚未接入任何 `*.shims.txt`**；`build/WindowsBase.Linux/bin/Debug/WindowsBase.dll` 的 AssemblyVersion 实测仍是 **4.0.0.0**（方案未生效） |
| 补丁 A（本工程，摘掉框架 Reference 项） | 赢冲突解析（移除竞争者） | **不修**：探针实测运行期仍 `TypeLoadException`，`AssemblyResolve` 拦不住 | 已在 csproj 中，当前**是必需的** |

**结论**：两者不冲突（A 只摘「无 HintPath」的框架引用项，保留我们自己的）。身份版本方案落地后，补丁 A 变为冗余保险（可留可撤）；但**运行期那一条只能靠身份版本方案**，建议 PresentationCore 及后续所有 `*.Linux` 工程都带上该 shim。

### 1.4 port-lib 的三处口径缺口（未改 port-lib，按纪律用清单/补丁兜住）

1. `EnableDefaultCompileItems` 识别不到上游的 `EnableDefaultItems=false` → 误加 9 个文件（§1.2）。
2. **excludes 过滤发生在默认 glob 之前**，被 glob 加回来的文件不再经过 `build/excludes/<Name>.txt` 过滤 → 这 9 个文件**无法**用 excludes 清单剔除，只能用补丁 C 的显式 `Compile Remove`（与 `WindowsBase.Linux.csproj` 里 SplashScreen 的写法一致）。
3. `NoWarn` 是硬编码的，未搬运上游 csproj 自己的 `NoWarn`（PresentationCore 的 `SYSLIB5005` 因此丢了 13 条警告 → 由补丁 B 补回）。

---

## 2. 剔除清单与实测依据（交付物 ②）

文件：`build/excludes/PresentationCore.txt`（A 类 9 条 + B 类 8 条 = 17 条）；另有补丁 C 的 9 条 `Compile Remove`（同一批 A 类文件，机制所限必须写在 csproj 里）。

### 2.1 A 类：上游本来就没编的文件（9 个，port-lib 误纳）

**实测协议**：全量构建 → 逐文件统计错误归属 → 剔除该文件后重编 → 比较总错误数与「是否产生新错误」。

| 文件 | 该文件自身错误 | 代表错误（错误码 + 信息） | 上游依据 | 剔除效果 |
|---|---|---|---|---|
| `System/Windows/Media/NativeMethodsMilCoreApi.cs` | 0（但**引发 30 条**跨 14 文件） | `CS0426 类型"NativeMethods"中不存在类型名"RECT"` ×18、`PROCESS_DPI_AWARENESS` ×4、`POINT` ×3、`XFORM` ×2、`MOUSEMOVEPOINT` ×2、`MONITOR_DPI_TYPE` ×1（分布在 HwndTarget/HwndSource/HwndMouseInputProvider/DpiUtil*/PointUtil/SafeSecurityHelper/exports.cs/wgx_commands.cs…） | csproj:798 显式注释：`<!-- Empty and clashes with NativeMethods in WindowsBase, which we require ... -->` | 30 → 0 |
| `System/Windows/Media/printcontext.cs` | **16** | `CS0234 System.Printing` ×5 + `CS0246 PrintSystemEDocumentJob/JobTicket/XpsDocument` ×11 | csproj:817 `<!--Compile Include=... /-->` | 16 → 0 |
| `MS/internal/FontFace/CachedCompositeFamily.cs` | **9** | `CS0535/CS0539/CS0540`（`IFontFamily.Baseline/LineSpacing` 等）+ `CS0426 FamilyCollection.Cached*` | 不在 Compile 列表（旧缓存分层） | 9 → 0 |
| `MS/internal/FontCache/IPCCacheManager.cs` | **8** | `CS0246 Protocol` + `CS0234 Microsoft.Internal.*` | 不在 Compile 列表 | 8 → 0 |
| `MS/internal/FontCache/CachedFontFace.cs` | **4** | `CS0426 FamilyCollection.CachedFace` | 不在 Compile 列表 | 4 → 0 |
| `MS/internal/FontCache/CachedFontFamily.cs` | **4** | `CS0426 FamilyCollection.CachedFamily` | 不在 Compile 列表 | 4 → 0 |
| `MS/internal/FontCache/FontCacheLogic.cs` | **2** | `CS0234 Microsoft.Internal` + `CS0246` | 不在 Compile 列表 | 2 → 0 |
| `System/Windows/Media/Generated/ColorCollectionConverter.cs` | **1** | `CS1537 using 别名"SR"以前在此命名空间中出现过` | 不在 Compile 列表；与 `GlobalUsings.cs` 的 `global using SR=` 冲突 | 1 → 0 |
| `System/Windows/Media/GlyphCache.cs` | **1** | 同上 | 不在 Compile 列表 | 1 → 0 |

**合计实测：错误 484 → 404（−80），警告 −37，新增错误 0。**（80 = 45 条直接归属 + 30 条 A1 的跨文件级联 + 5 条二次级联；以 E0−E1 差值为准。）

### 2.2 B 类：OLE 剪贴板 / DragDrop 栈 8 文件 —— 结论：**剔除**

**实测依据（三条，均为数字）**

1. **依赖离线不可获得的私有程序集。** 8 个文件全部 `using System.Private.Windows.*`（WinForms 私有包）。实测 `PackageReference System.Private.Windows.Core` → **`NU1101 找不到包`**（镜像 huaweicloud 不存在该 ID）。这与 `System.Formats.Nrbf` 不同 —— 后者能用包补回来，前者不能。
2. **纳入编译的错误量（E1 实测，8 文件合计 50 条）**

| 文件 | 行数 | 纳入编译错误数 | 代表错误样例 |
|---|---|---|---|
| `System/Windows/dataobject.cs` | 655 | **26** | `CS0538 '显式接口声明中的"System.Com.IDataObject.Interface"不是接口'` ×9、`CS0246 IDataObjectInternal<,>` ×6、`CS0538 IDataObjectInternal<DataObject,IDataObject> 不是接口` ×5 |
| `System/Windows/Ole/WpfOleServices.cs` | 191 | **14** | `CS0246 FORMATETC/STGMEDIUM/IOleServices/IComVisibleDataObject`、`CS0234 Windows.Win32.System` ×3、`CS0538 IOleServices 不是接口` ×3 |
| `System/Windows/DataFormat.cs` | 40 | **4** | `CS0246 IDataFormat<>` ×2、`CS0538 IDataFormat<DataFormat> 不是接口` |
| `System/Windows/Ole/DataObjectAdapter.cs` | 47 | **2** | `CS0234 System.Private` + `CS0246 IDataObjectInternal` |
| `System/Windows/Nrbf/WpfNrbfSerializer.cs` | 52 | **2** | `CS0234 System.Private` + `CS0246 INrbfSerializer` |
| `System/Windows/DataFormats.cs` | 190 | **1** | `CS0234 命名空间"System"中不存在类型或命名空间名"Private"` |
| `System/Windows/clipboard.cs` | 503 | **1** | 同上 |
| `System/Windows/OleServicesContext.cs` | 202 | **0** | （剔除的连带项：`OleRegisterDragDrop` 依赖 IOleDropTarget） |
| **合计** | 1880 | **50** | |

> ⚠️ **误差口径警告（必须写进结论）**：`clipboard.cs` 只有 1 条错误不是「工作量小」，而是「**错误类型抑制级联**」——其宿主 `ClipboardCore<T>` 解析失败后整文件退化为错误类型。同理 `dataobject.cs` 的 9 条 `CS0538` 说明上游期待的是 CsWin32 的「结构体 + 内嵌 `Interface` 类型」形态。**因此"错误条数"不能用来估 OLE 栈的工作量，真实工作量是重建 4 个泛型宿主 + `IOleServices` + `PInvokeCore`（扫描报告估 500–1000 行），其形态无法离线复核。**

3. **剔除的代价可量化且很小**：错误 404 → 362（−50），**新增 8 条**（实为 12 条唯一错误，见下），全部是「公开 API 被挖掉」的可见代价：
   - `GlobalUsings.cs` 11 条 CS0234（4 个 global alias 失效：`System.Private.Windows.Ole` ×4 → `System.Windows.Ole` ×3 + `System.Windows.DataFormat` ×3 + `System.Windows.Nrbf` ×1）
   - `DragDrop.cs:560` 1 条 `CS0246 DataObject`

**恢复条件（二选一，均为路线级决定，不在 M4 范围）**
- ① **路线乙（推荐）**：按 X11 selection / Xdnd 语义重写 `DataObject` / `Clipboard` / `DataFormats` / `DataFormat` 四个公开类型（顺带消掉那 12 条），不再需要 OLE 私有宿主 —— OLE 协议在 Linux 上本来就要换。
- ② **路线甲**：联网取得 `System.Private.Windows.Core` 等价面或 CsWin32 真实生成，重建泛型宿主，并配 COM vtbl 保真测试（`WindowsWin32.Shim.cs` 追加段落已备好 FORMATETC/STGMEDIUM/TYMED/DVASPECT/CLIPBOARD_FORMAT/DV_E_TYMED 这些**可字节验证**的地基）。

### 2.3 C 类：扫描报告 §4.4 点名「毒点」但**实测不剔除**（记录在案，防后人误加）

| 文件 | 扫描报告建议 | **实测** | 结论 |
|---|---|---|---|
| `System/Windows/InterOp/D3DImage.cs`（957 行） | 「Linux 上建议整体空实现/剔除」 | 纳入编译 **0 条错误**（D3D11 互操作全走 `InteropDeviceBitmap_*` 声明 + DUCE 通道） | **不剔除**。剔除会挖掉公开类型 `D3DImage`；运行期降级是 M5 的事 |
| `System/Windows/Media/Imaging/BitmapSource.cs`（1961）/ `BitmapMetadata.cs`（1538）/ `UnsafeNativeMethodsMilCoreApi.cs`（1158，109 条 WIC P/Invoke） | 「WIC 栈需约 12 个 vtbl 槽 shim」 | 三者纳入编译 **0 条错误** —— 109 条 WIC P/Invoke 全以 `IntPtr/SafeMILHandle` 不透明句柄传递 | **不需要任何 shim**，与扫描报告预期相反 |
| `MS/Win32/UnsafeNativeMethodsPenimc.cs` / `UnsafeNativeMethodsTablet.cs` | 运行期功能降级 | **0 条错误** | 保留 |
| `MS/internal/TextFormatting/LineServices.cs` | 「编译无碍」 | **4 条**（`CS0246 GlyphOffset`） | 错误来自 DirectWriteForwarder 托管面缺失，**应由新的 DWriteForwarder 工程解决，不应剔除文件**（`GlyphRun`/`FormattedText` 是公开 API 必经路径） |
| `System/Windows/Nrbf/SerializationRecordExtensions.cs` | —（报告未列） | **0 条错误** | **不剔除**，避免过度剔除 |

---

## 3. shim 增量清单（交付物 ③）

### 3.1 追加段落内容（`build/shims/WindowsWin32.Shim.cs`，263 → 505 行）

追加段落按「可验证性」分两档，**刻意不写**无法离线复核的形状（详见该文件头部注释）。

| # | 类型 / 成员 | 命名空间 | 形态来源 | 字节宽度 / 值 |
|---|---|---|---|---|
| 1 | `HRESULT` 改为 `partial`（零 IL 变化） | `Windows.Win32.Foundation` | — | 4 字节 |
| 2 | `HRESULT.DV_E_TYMED` | 同上 | OLE2 规范 DV_E_* 连续块 0x80040064–0x8004006D | `0x80040069`（`Succeeded=false`） |
| 3 | `TYMED`（`[Flags] enum : uint`，8 个成员） | `Windows.Win32.System.Com` | BCL `ComTypes.TYMED` 交叉验证 | 基类型 4 字节 |
| 4 | `DVASPECT`（`enum : uint`，4 个成员） | 同上 | BCL `ComTypes.DVASPECT` | 4 字节 |
| 5 | `FORMATETC` | 同上 | 上游 in-tree 定义 + BCL 双口径 | **32 字节**（cfFormat@0 / ptd@8 / dwAspect@16 / lindex@20 / tymed@24） |
| 6 | `STGMEDIUM` + `_u` union + 3 个直通访问器 | 同上 | 上游 in-tree 定义 | **24 字节**（tymed@0 / u@8 / pUnkForRelease@16），union 8 字节 |
| 7 | `CLIPBOARD_FORMAT : ushort`（7 个成员） | `Windows.Win32.System.Ole` | 上游 `MS.Win32.NativeMethods.CF_*` 常量交叉验证 | 2 字节 |
| 8 | `PInvoke.SetEnhMetaFileBits(byte[])` | `Windows.Win32` | **按调用点推导**（`WpfOleServices.cs`）；Linux 恒返回空句柄 | — |
| 9 | `GdiHandleExtensions.CreateCompatibleBitmap(this HBITMAP, int, int)` | `Windows.Win32.Graphics.Gdi` | **按调用点推导**；Linux 恒返回 `HBITMAP.Null` | — |

**刻意不包含**：CsWin32 的 COM 接口组（`IDataObject` / `IAdviseSink` / `IEnumFORMATETC` / `IEnumSTATDATA` / `IManagedWrapper<T>`）。理由（实测）：① 上游这 8 个文件已按 §2.2 剔除，当前编译集需求量为 0；② 报错只给「形状名」不给形状 —— 实测 `CS0538 '显式接口声明中的 System.Com.IDataObject.Interface 不是接口'`，即上游要的是 CsWin32 的「结构体 + 内嵌 `Interface` 类型」形态，其 vtbl 槽序与 `IManagedWrapper<T>` 的 `unmanaged` 语义无法离线复核；凭记忆手写 20–25 个槽正是 SplashScreen 的失败模式。恢复条件同 §2.2 恢复条件 ②。

### 3.2 探针验证（`/tmp/m4/shimprobe`，不进仓库）

**探针结构**：`ShimProbe.csproj`（`<Compile Include="…/build/shims/WindowsWin32.Shim.cs">` 直接编译被测 shim 本体 + 公开签名 WCP 公钥 + 与 PresentationCore 同源的「摘门面 WindowsBase 引用」目标）+ `Program.cs` + `UpstreamOracle.cs`（逐字复制上游 in-tree FORMATETC/STGMEDIUM 定义做交叉验证）。

**运行结果：`PASS=65 FAIL=0`**（复现：`cd /tmp/m4/shimprobe && dotnet run`）

| 组 | 断言数 | 内容 | 口径（oracle） |
|---|---|---|---|
| [1] 句柄/标量宽度 | 14 | `nint`=8、`BOOL`/`HRESULT`=4、`HANDLE`/`HWND`/`HINSTANCE`/`HMENU`/`LRESULT`/`WPARAM`/`LPARAM`/`HDC`/`HBITMAP`/`HENHMETAFILE`=8、`BLENDFUNCTION`=4 | `sizeof` / `Marshal.SizeOf` |
| [2] BLENDFUNCTION + CF_* 常量 | 10 | 与**已编译产物 `WindowsBase.dll`** 的 `MS.Win32.NativeMethods.BLENDFUNCTION` 宽度与 4 个字段偏移逐项一致；`CF_TEXT/BITMAP/UNICODETEXT/ENHMETAFILE/HDROP` 常量与上游同值 | 反射加载 `build/WindowsBase.Linux/bin/Debug/WindowsBase.dll`（`Assembly.Load(byte[])`） |
| [3] FORMATETC | 8 | 32 字节；`sizeof` 与**上游 in-tree 定义**、**BCL `ComTypes.FORMATETC`** 三方一致；5 个字段偏移逐项一致 | 上游 `UIAutomation/…/UnsafeNativeMethods.cs:93` + BCL |
| [4] STGMEDIUM | 7 | 24 字节；与上游 in-tree 定义一致；`tymed@0 / u@8 / pUnkForRelease@16`；union=8；**并断言 BCL `ComTypes.STGMEDIUM` 因含 `object` 字段而非 blittable、不可作宽度口径** | 上游 `…UnsafeNativeMethods.cs:104` + BCL（负向断言） |
| [5] 枚举值 | 17 | `TYMED` 8 值 vs BCL；`DVASPECT` 4 值 vs BCL；`CLIPBOARD_FORMAT` 5 值 vs 上游常量；基类型 2 字节 | BCL `ComTypes` + 上游 `NativeMethods.CF_*` |
| [6] `DV_E_TYMED` 语义 | 4 | `== unchecked((int)0x80040069)`、`Failed=true`、`Succeeded=false`、`S_OK.Succeeded=true` | OLE2 规范（无 BCL oracle，已标注） |
| [7] 空句柄语义 | 4 | `SetEnhMetaFileBits` / `CreateCompatibleBitmap` 在 Linux 返回**空**句柄、`HBITMAP.Null.IsNull`、`HENHMETAFILE.Null.IsNull` | 反向断言：绝不伪造非空句柄 |
| [8] nint 往返 | 4 | `(nint)(HANDLE)0x1234 == 0x1234`、`BOOL.TRUE == 1`、`(bool)BOOL(2) == true` | 结构体 ↔ 原生指针互操作的最基本性质 |

**探针抓出的两个真问题（这就是探针的价值）**
1. 追加段落在 `namespace Windows.Win32.System.Com` 内写 `System.Runtime.InteropServices.StructLayout` 会被解析成 `Windows.Win32.System.Runtime.InteropServices…`（命名空间遮蔽，8 条 CS0234）→ 已改为 `global::System…`。
2. 探针**运行期**绑定不到我们的 `WindowsBase.dll`：同名程序集在运行期绑定到 `Microsoft.NETCore.App` 的门面（v4.0.0.0），`TypeLoadException` 且 `AssemblyResolve` 拦不住（编译期 HintPath 选得对，运行期选得不对）→ 改用 `Assembly.Load(byte[])` + 反射取 oracle。**这条对后续 samples/tests 直接相关：任何运行 WPF 托管层的程序都必须显式钉住本工程的 WindowsBase.dll。**

**回归验证**：shim 是 WindowsBase 共用的（`build/shims/WindowsBase.shims.txt` 列了它），追加后重编 WindowsBase → **0 错 0 警**（`已成功生成 / 0 个警告 / 0 个错误`），未破坏已绿的里程碑。

### 3.3 一个设计决定：PresentationCore **不**再单独编入 shim

实测：`WindowsBase.dll` **公开导出**了 shim 的全部类型（`Windows.Win32.Foundation.BOOL` / `Graphics.Gdi.HENHMETAFILE` / `System.Com.FORMATETC` 均为 public），PresentationCore 通过引用**传递解析**即可（当前唯一的 Windows.Win32 消费者 `MS/internal/SystemDrawingHelper.cs` 实测 0 错即是证明）。
故本轮**未**创建 `build/shims/PresentationCore.shims.txt`：再加一份会在两个程序集里各留一份同名 public 类型，下游（PresentationFramework）引用两者时得到 CS0433/CS0436。
**建议（M5/M6）**：把 shim 提升为独立程序集（如 `build/WindowsWin32.Shim.Linux` → `Windows.Win32.dll`），WindowsBase / PresentationCore / 后续项目统一引用它，消除「靠传递导出」的隐式耦合。

---

## 4. 逐包 / 逐 Target 处置对照（交付物 ④）

### 4.1 `PackageReference`（4 条，port-lib 全部解析成功）

| 上游包 | 版本变量 | 生成结果 | 实测 |
|---|---|---|---|
| `System.Configuration.ConfigurationManager` | `$(SystemConfigurationConfigurationManagerPackageVersion)` | 9.0.0 | ✅ 还原通过（本机缓存已有） |
| `System.Windows.Extensions` | `$(SystemWindowsExtensionsPackageVersion)` | 9.0.0 | ✅ |
| `$(SystemIOPackagingPackage)` → `System.IO.Packaging` | `$(SystemIOPackagingVersion)` | 9.0.0 | ✅（PKG_NAMES 映射生效） |
| **`System.Formats.Nrbf`** | `$(SystemFormatsNrbfVersion)` | 9.0.0（PKG_VERSIONS 回退值） | ✅ 可还原；但**实验性 API 诊断 SYSLIB5005 未随上游 NoWarn 搬运**，实测 13 条警告 → 补丁 B 补 `NoWarn`（已 0） |

### 4.2 私有 WinForms 引用 / CsWin32 / 代码生成

| 项 | 上游 | port-lib 处置 | 本轮实测结论 |
|---|---|---|---|
| `MicrosoftPrivateWinFormsReference`（`System.Private.Windows.Core`） | 1 条 | 丢弃 | **镜像 NU1101 无此包** → 消费它的 8 文件必须剔除（§2.2） |
| CsWin32（`System.Windows.Primitives` 宿主） | ProjectReference + winmd | ProjectReference 丢弃；类型由 `build/shims/WindowsWin32.Shim.cs` 提供 | 实测 Windows.Win32 缺口=**0**（唯一消费者靠 WindowsBase 传递解析）；但该项目的 `AssemblyInfo.cs` 里 `[assembly: CLSCompliant(false)]` 是 37 条 CS3021 的根因（§5） |
| `DirectWriteForwarder.vcxproj`（C++/CLI） | ProjectReference | 丢弃 | **最大剩余阻塞**：41 个托管类型缺失，≈103 条错误（§5） |
| SR 资源（`Resources/Strings.resx` 115 KB） | Arcade `GenerateCommonSRSource` | `gen-sr.py` → `SR.g.cs`（命名空间 `MS.Internal.PresentationCore`） | ✅ 生成成功、参与编译、0 错 |
| `GenerateSources` / `GenerateAvTrace` / `TransformAll` / `CreateGeneratedAssemblyInfo` | 4 个代码生成 Target | DROP_TARGETS 丢弃 | 前三个产物均 checked-in（`MS/Internal/Generated/AvTraceMessages.cs`、`Common/Graphics/Generated/wgx_commands.cs`、`exports.cs`、`wgx_exports.cs`）实测参与编译 0 错；**`CreateGeneratedAssemblyInfo` 的丢失产生副作用**：PresentationCore 上游的 `LibraryAssemblyInfo.cs`（含 `CLSCompliant` 等 assembly 特性）是 Arcade 生成的、且不在 csproj 的 Compile 列表里 → 37 条 CS3021（§5） |
| `mcg` / AvTrace 生成器 | 需运行 | 无需运行 | ✅ 产物已在树内，实测无需生成器 |
| 包 `EmbeddedResource`（Strings.resx / ColorProfiles.resx / CompositeFont） | 3 项 | port-lib 只搬运 `EmbeddedResource|Resource` 且**要求文件存在** | `Fonts/*.CompositeFont` 是通配符 `Resource`，port-lib 不复现 → **M5 需补**（影响字体回退表，编译不报错但资源缺失）。本轮实测编译产物含 `MS.Internal.ColorProfiles.resources`（见 obj/Debug） |

---

## 5. 剩余阻塞预测表（交付物 ⑤）

**当前实测基线（含全部补丁、剔除、shim、M3 DLL）：118 条错误 / 46 条警告（唯一错误 114）**

| # | 阻塞项 | 实测错误数 | 代表错误 | 性质与处置 | 预计轮次 | 依赖 |
|---|---|---|---|---|---|---|
| 1 | **DirectWriteForwarder 托管面缺失** | **102** | `CS0234 MS.Internal.Text.TextInterface.Font` ×13、`FontCollection` ×11、`FontFamily` ×9、`GlyphMetrics` ×11、`ItemProps` ×6、`Interfaces` ×2、`OpenTypeTableTag`/`IClassification`/`InformationalStringID` 各 1；`CS0246 IFontSource(Factory)` ×7、`FactoryType` ×3、`TextAnalyzer` ×3、`FontFileLoader` ×3、`FontFile`/`FontSimulations` 各 1、`DWriteFontFeature` ×5、**`GlyphOffset` ×9**；`CS0305 Span<T>` ×6；`CS0118/CS0535/CS0540` ×4（接口面连带） | 上游 `DirectWriteForwarder` 是 C++/CLI 工程，port-lib 丢弃；其托管面 = `CPP/DWriteWrapper/*.h` 中 **41 个类型**（`Font`/`FontCollection`/`FontFamily`/`FontFace`/`FontFile*`/`FontList`/`FontMetrics`/`ItemProps`/`Span`/`TextAnalyzer`/`TextItemizer`/`GlyphMetrics`/`GlyphOffset`/`DWrite*`/`IFontSource*`/`IClassification`…，`private` 语义经 IVT 暴露给 PresentationCore）。**好消息：形态在树内可查（3.5k 行 .h + 3.4k 行 .cpp），不是凭记忆**。处置：新建 `build/DirectWriteForwarder.Linux` 托管工程，类型/成员对着头文件落地，方法体委托 M1 Skia 文本栈（或先 `NotImplementedException`），并把 `MS.Internal.Span`（非泛型，`ref class`，`element`/`length`/ctor）与 `MS.Internal.Text.TextInterface.GlyphOffset`（`du`/`dv` int）一并提供 —— 这两个「凭空缺失」的类型就是它提供的 | **2 轮**（骨架 1 轮 + 迭代到 0 错 1 轮） | 无外部依赖（上游头文件在树内）；运行期实现依赖 M1 字体栈 |
| 2 | OLE 公开 API 被挖掉的级联 | **12** | `CS0234 System.Private.Windows.*` ×4、`System.Windows.Ole` ×3、`System.Windows.DataFormat` ×3、`System.Windows.Nrbf` ×1（均在 `GlobalUsings.cs`）、`CS0246 DataObject`（`DragDrop.cs:560`） | 需路线决定（§2.2 恢复条件 ①/②）。**注意**：这 12 条不能靠"stub 一下"收尾 —— `DataObject`/`Clipboard`/`DataFormats`/`DataFormat` 是 PresentationFramework 重度依赖的公开 API，stub 会把债务推到下一站 | 1 轮（若走「公开 API stub」可 0.5 轮，但会伪造 API）；走 X11 重写则 1–2 周（跨里程碑） | 路线决策（非技术依赖） |
| 3 | 警告清零（0 警门禁） | **46 条警告** | `CS3021` ×37（`'由于程序集没有 CLSCompliant 特性…'`，出现在 `DataObjectExtensions`/`TextDecorationCollection`/`CharacterMetricsDictionary` 等公开成员上）；`CS8500` ×9（`GlyphOffset` 为托管类型却取地址） | CS3021 根因：上游 PresentationCore 的 assembly 特性（含 `[assembly: CLSCompliant(false)]`）由 Arcade `CreateGeneratedAssemblyInfo` 生成 → port-lib DROP_TARGETS 丢弃，且上游目录里没有 checked-in 的 `LibraryAssemblyInfo.cs`（WindowsBase 有 → 所以 WindowsBase 0 警）。处置：为 PresentationCore 生成等价 assembly 特性文件（`CLSCompliant(false)` + `AssemblyVersion 4.0.0.0`，后者顺带修掉「我们 DLL 版本 0.0.0.0」这个隐患）。CS8500 ×9 会随阻塞 #1 消失 | **1 轮**（与 #1 并行） | 无 |
| 4 | 复合字体资源（`Fonts/*.CompositeFont`） | 0 错（静默缺失） | —（需运行期才暴露） | port-lib 不搬运通配符 `Resource`；M5 需补 `EmbeddedResource`/`Resource` 项 | 0.5 轮 | 无 |
| 5 | **曾预期阻塞但现在已解** | — | — | M3 三个小项目 DLL 已由并行 agent 落地，本工程重跑 port-lib 后**自动重接**（5 个本地引用全绿），原先 ≈330 条 UIAutomation/Manipulations 错误清零 | — | ✅ 无需等待 |

**总预测**：PresentationCore 达到「0 错」还差 **阻塞 #1 + #2**；达到「0 错 0 警」再加 **#3 + #4**。按当前实测节奏估算 **2–4 轮**（不含运行期语义替换：95 个 MIL 导出、消息泵、OLE/WIC 后端，仍为月级）。

**必须先等上游/并行产物的项**：M3 的 `System.Windows.Input.Manipulations.dll` / `UIAutomationTypes.dll` / `UIAutomationProvider.dll` —— **已就绪**（本轮实测已重接）。除此之外**没有**必须等待的外部依赖；阻塞 #1 是「上游 C++/CLI 工程的托管等价物」，可在本仓库内新建。

---

## 6. 给下一站的三条硬约束（实测得出）

1. **任何引用 `WindowsBase.dll` 的 csproj 都要补丁 A**（否则 WindowsBase 被框架门面遮蔽，6000 条级联错误，且症状是「`DependencyObject` 不存在」，极易误判为上游源码问题）。
2. **任何引用 `WindowsBase.dll` 内部类型的程序集都要补丁 B**（公开签名 WCP 公钥），否则 CS0281 ×290 起步。
3. **运行期**必须显式钉住本工程产物（`Assembly.Load(byte[])`/`AssemblyLoadContext` 或改名），否则框架门面会在运行期抢先绑定（探针实测 `TypeLoadException`）。

## 附录：复现命令

```bash
REPO=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"

# 1) 生成骨架（会覆盖 csproj，之后必须重放补丁）
cd $REPO && python3 build/port-lib.py PresentationCore
python3 build/PresentationCore.Linux/reapply-patches.py

# 2) 构建与错误统计（当前基线：118 错误 / 46 警告）
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -v:m -nologo

# 3) 剔除实验（复现 §2 的数字；WpfExp 开关已随 reapply-patches.py 一起移除，需临时加回
#    <Compile Remove> 项，见 build/excludes/PresentationCore.txt 的 A/B 类清单）
#    全量 6031 错（无补丁）→ +A 878 → +B 500 → +C 418 → 再剔 OLE 8 文件 376

# 4) shim 探针（65 条断言，含字节宽度与 oracle 交叉验证）
cd /tmp/m4/shimprobe && dotnet run --project ShimProbe.csproj

# 5) WindowsBase 回归（shim 共用，必须保持 0 错 0 警）
dotnet build $REPO/build/WindowsBase.Linux/WindowsBase.Linux.csproj -v:m -nologo
```

## 交付物清单（本轮新增 / 修改）

| 文件 | 动作 | 说明 |
|---|---|---|
| `build/PresentationCore.Linux/PresentationCore.Linux.csproj` | 新增（port-lib 生成 + 补丁 A/B/C） | 1358 条 Compile 条目 − 9 条 Remove = 1349 实际编译；5 条本地引用；4 条包引用 |
| `build/PresentationCore.Linux/reapply-patches.py` | 新增 | 三处补丁的**可重放出处**（幂等），port-lib 重跑后执行一次 |
| `build/PresentationCore.Linux/PORT-CHANGES.md` | 新增（自动） | port-lib 的改动清单 |
| `build/PresentationCore.Linux/SR.g.cs` | 新增（自动） | resx → SR，命名空间 `MS.Internal.PresentationCore` |
| `build/excludes/PresentationCore.txt` | 新增 | A 类 9 + B 类 8，逐条含实测错误数、代表错误、恢复条件 |
| `build/shims/WindowsWin32.Shim.cs` | 修改（263 → 505 行） | `HRESULT` 加 `partial`；追加 FORMATC/STGMEDIUM/TYMED/DVASPECT/CLIPBOARD_FORMAT/DV_E_TYMED/SetEnhMetaFileBits/CreateCompatibleBitmap |
| `build/keys/WcpPublicKey.snk` | 新增 | 从 WindowsBase.dll 的 IVT 串提取的 Microsoft WCP **公钥**（160 字节，非机密），公开签名用 |
| `docs/U2-PresentationCore-prep.md` | 新增 | 本文档 |
| `/tmp/m4/shimprobe/` | 新增（**不进仓库**） | 探针工程：`ShimProbe.csproj` / `Program.cs` / `UpstreamOracle.cs`，`PASS=65 FAIL=0` |

**上游零改动**：`upstream/wpf` 全程只读；本轮未触碰 `build/port-lib.py`、`build/Manipulations.Linux/`、`build/UIAutomation*.Linux/`、`src/`、`handoff.md`、`build/Directory.Upstream.props`（后者的改进建议见 §1.3）。

---

# 7. M4 收官：PresentationCore 已达 0 错 0 警

> 本节记录 M4 第二轮（主控裁决后）的最终状态与实测证据。上文 §0–§6 是预研阶段的记录，
> 其中的「阻塞 #1（102 错）/#2（12 错）/#3（46 警）」在本轮**全部清零**。

## 7.1 最终结果

| 项 | 值 |
|---|---|
| 构建命令 | `dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -v:m` |
| 结果 | **已成功生成 / 0 个警告 / 0 个错误** |
| 产物 | `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`，**3,629,056 字节** |
| 实际编译源文件 | 1348（port-lib 生成 1348；A 类 9 个误纳文件由 port-lib 排除，B 类 7 个 OLE 文件 + D 类 1 个模块初始化器按 excludes 剔除） |
| 本地引用 | WindowsBase / System.Xaml / System.Windows.Input.Manipulations / UIAutomationTypes / UIAutomationProvider / DirectWriteForwarder（6 条） |
| 包引用 | 4 条（System.Configuration.ConfigurationManager / System.Formats.Nrbf / System.IO.Packaging / System.Windows.Extensions，均 9.0.0） |

## 7.2 三块工作与实测证据

### (1) DirectWriteForwarder 托管骨架（102 错 → 0）

**根因**（M4 预研实测）：上游 DirectWriteForwarder 是 C++/CLI（`.vcxproj`），port-lib 对 .vcxproj 一律丢弃，
其**托管面 41 个类型**在 Linux 上整体缺失。报错里「凭空缺失」的 `MS.Internal.Span`（非泛型）与
`GlyphOffset` 正是它提供的 —— 这两个类型的定义分别在
`CPP/DWriteWrapper/ItemSpan.h`（`private ref struct Span sealed`）与 `GlyphOffset.h`
（`private value struct GlyphOffset`），经 `OtherAssemblyAttrs.cpp` 的 IVT 暴露给 PresentationCore。

**处置**：新建 `build/DirectWriteForwarder.Linux/`（4 个文件，1 个 csproj）：按上游树内
`CPP/DWriteWrapper/*.h`（3.5k 行，形态可查、非凭记忆）落地类型，语义三档：
- **[真实现]** 纯托管算术/枚举映射：`FontMetrics.Baseline`/`LineSpacing`（公式取自头文件）、
  `DWriteTypeConverter` 的 12 组托管↔原生枚举映射、`OpenTypeTableTag`/`DWriteFontFeatureTag`
  的 111 个字面值（**由脚本从头文件机械提取**）、`InternalFactory.IsLocalUri`、`ItemProps.CanShapeTogether`、`DWriteFontFeature`/`GlyphMetrics`/`GlyphOffset` 布局；
- **[数据]** `LocalizedStrings`（实现 `IDictionary<CultureInfo,string>`）、`Span`；
- **[PNSE]** 依赖 DWrite 原生对象的成员（`Font.GetFontFace`、`TextAnalyzer.GetGlyphs` … 共 50 余处）
  一律抛 `PlatformNotSupportedException`，消息指向 M1 Skia 文本栈，**不返回假数据**。

**实测支持**：
- DWriteForwarder.Linux 自身：**0 错 0 警**，产出 `DirectWriteForwarder.dll` 33,792 字节；
- 接入后 PresentationCore 的 102 条 DWrite 错误一次清零，警告同时 46 → 37（CS8500 ×9 随 `GlyphOffset` 落地消失，与预研预测一致）；
- 迭代中由编译器暴露并修正的 6 处形状偏差（全部按**上游 oracle**修正，非猜测）：
  `Itemize` 9→13 参、`GetGlyphs` 参数表、`GetGlyphPlacements` 末参 `out GlyphOffset[]`、
  `FontFile.Analyze` 第 4 参为 `int*`（调用点传 `&hr`）、`FontFileEnumerator` 三参构造
  （`IEnumerable<IFontSource>`）、`FontFace`/`FontFile` 必须实现 `IDisposable`
  （上游 C++/CLI 的 `~FontFace()`/`~FontFile()` 即 Dispose，`GlyphTypeface` 用 `using` 依赖它）；
  另补 3 个遗漏类型：`NativeWPFDLLLoader`（main.cpp）、`LocalizedErrorMsgs`、`TrueTypeSubsetter`（`MS.Internal`，public abstract sealed）。

### (2) OLE 公开 API 占位（12 错 → 0，主控裁决：最小诚实 stub）

新增 `build/shims/PresentationCore.OleApi.Stubs.cs`（单文件，经 `build/shims/PresentationCore.shims.txt` 自动编入）：
提供 `DataObject`（含 `IDataObject`/`ITypedDataObject`/`ComTypes.IDataObject` 三个接口的完整实现）、
`Clipboard`、`DataFormats`、`DataFormat` 四个公开类型 + `WpfOleServices`/`WpfNrbfSerializer` +
`System.Private.Windows.Ole` 四个泛型宿主（元数占位）。

**诚实性口径**（逐条落实主控要求）：
- 所有数据操作抛 `PlatformNotSupportedException`，消息固定：`Linux 侧剪贴板/DnD 需 X11 selection/Xdnd 实现，见 handoff U13`；
- **不返回空集合/默认值假装成功**；`DataObject` 的三个 `RoutedEvent` 字段是 `null` 占位（在文件头显式标注）；
- 唯一真实现部分是纯数据：`DataFormat.Name/Id`、`DataFormats` 的 23 个格式名常量
  —— 其字面量来自 WinForms `DataFormatNames`（**另一个仓库，离线无 oracle**），已在文件内显式标注「值未离线核实」；
- 恢复条件写进 `build/excludes/PresentationCore.txt` B 类注释（三条：X11 重写替换 / 私有宿主重建后替换 / 占位下线条件）。
- **实测口径修正**：`OleServicesContext.cs` 放回编译集（单独编译 0 错，且 `DragDrop.cs` 三处引用它）
  → B 类剔除从报告的 8 文件收敛为 **7 文件**（依据与数字见 excludes 文件 B 类头部）。

### (3) 46 条警告 → 0

| 警告 | 条数 | 根因（实测） | 处置 |
|---|---|---|---|
| `CS3021` | 37 | 上游 PresentationCore 的 assembly 特性（含 `[assembly: CLSCompliant(false)]`）由 Arcade `CreateGeneratedAssemblyInfo` 生成、**不在树内**，port-lib 丢弃该 Target；而源码里存在带 `[CLSCompliant(...)]` 的公开成员。对照证据：WindowsBase 树内有 checked-in 的 `LibraryAssemblyInfo.cs`（含同一特性）→ 0 警 | 新增 `build/shims/PresentationCore.AssemblyAttrs.cs`（1 行 `[assembly: CLSCompliant(false)]`，值对齐上游 `System.Windows.Primitives/AssemblyInfo.cs`；**不**声明 AssemblyVersion，避免与 `LinuxAssemblyIdentity.cs` 的 CS0579 冲突） |
| `CS8500` | 9 | `GlyphOffset` 曾是缺失类型 | 随 (1) 消失 |
| `CS8002` | 5+1 | 本工程按 IVT 要求公开签名后，被引用方（WindowsBase/System.Xaml/UIAutomation*/Manipulations，其它里程碑产出）仍未签名 | 在补丁 B 与 DWriteForwarder csproj 中各加一条带说明的 `NoWarn CS8002`；根治 = 全部 `*.Linux` 工程统一公开签名后删除抑制 |

## 7.3 复现命令（验收链，实测通过）

```bash
REPO=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"

# 主控指定链（逐字执行，实测 0 错 0 警）：
cd $REPO
python3 build/port-lib.py PresentationCore          # 源文件 1349（找回 214）/ 缺失 0
python3 build/PresentationCore.Linux/reapply-patches.py   # 注入补丁 B（PublicSign）+ D（DirectWriteForwarder 引用）
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -v:m
#   → 已成功生成 / 0 个警告 / 0 个错误

# 前置（首次或 DirectWriteForwarder 有改动时）：
dotnet build build/DirectWriteForwarder.Linux/DirectWriteForwarder.Linux.csproj -v:m
#   → 0 错 0 警，产出 bin/Debug/DirectWriteForwarder.dll
```

> `reapply-patches.py` 在**新基线**（主控已修 port-lib 的 4 处缺口）下仍是必需的，且保持幂等：
> A（门面遮蔽）/C（9 条误纳文件）已由主控根治 → 本脚本不再注入，仅保留防回退说明。

## 7.3.1 运行期可装载性：ModuleInitializer 必须剔除（本轮新发现，M6/M7 关键）

编译通过 ≠ 能加载。用 `/tmp/m4/oleprobe`（引用本工程产物、逐条调用公开 API）实测发现：

```
TypeInitializationException: The type initializer for '<Module>' threw an exception.
  -> DllNotFoundException: Unable to load shared library 'user32.dll' or one of its dependencies
```

根因：`PresentationCore/ModuleInitializer.cs` 的 `[ModuleInitializer]` 第一条就是
`IsProcessDpiAware()` → `[DllImport("user32.dll")] SetProcessDPIAware_Internal()`，
其后还有 `DWriteLoader.LoadDWrite()`（`NativeLibrary.Load("dwrite.dll")`）。
**只要触碰 PresentationCore 的任意类型，模块静态构造就抛异常** —— 即不处理它，
PresentationCore.dll 在 Linux 上根本用不了（编译期完全无感）。

处置：把 `ModuleInitializer.cs` 列入 `build/excludes/PresentationCore.txt` **D 类**（含证据与恢复条件）。
Linux 上它要做的三件事都无对象可做（Win32 DPI 概念、dwrite.dll 装载、上游本就是空实现的
`NativeWPFDLLLoader`），且该类型**全树无任何引用** → 剔除后 **0 新增错误 / 0 新增警告**（实测）。

> 为什么不用「ELF 形式的 user32.dll/dwrite.dll 占位」：伪造的 user32 会掩盖真实的 API 缺失，
> 与本项目「宁可抛异常也不假成功」的口径冲突（见 excludes D 类注释）。

## 7.3.2 OLE 占位口径的机械验证（`/tmp/m4/oleprobe`，PASS=11 FAIL=0）

| 断言组 | 断言数 | 结果 |
|---|---|---|
| 数据操作必须抛 `PlatformNotSupportedException` 且消息含 `handoff U13` | 7（`Clipboard.GetText/SetText/ContainsData/GetDataObject`、`new DataObject(...)`、`DataObject.GetData`、`DataFormats.GetDataFormat`） | 7/7 通过 |
| 纯数据真实现不抛 | 4（`DataFormats.Bitmap`="Bitmap"、`DataFormats.FileDrop`="FileDrop"、`DataFormat.Name/Id`） | 4/4 通过 |
| 程序集装载 | 3（WindowsBase/PresentationCore/DirectWriteForwarder 均为 **4.0.0.1** 且从 app-local 加载，未绑框架门面） | 3/3 通过 |

> 该探针同时验证了主控的「身份版本 4.0.0.1」修复在**运行期**生效：三个自产程序集全部解析到
> app-local 路径（`/tmp/m4/oleprobe/bin/Debug/net10.0/*.dll`）。

## 7.4 剩余缺口（M5 及以后）

| 缺口 | 性质 | 影响面 |
|---|---|---|
| DirectWriteForwarder 的 **[PNSE] 成员**（50 余处：字体面度量、字形索引、字形定位、子集化） | 运行期 | 任何文本渲染/度量路径都会抛 `PlatformNotSupportedException`；需接 M1 Skia 文本栈 |
| OLE 公开 API 占位（`DataObject`/`Clipboard`/…） | 运行期 | 剪贴板/DnD 不可用（handoff U13）；需 X11 selection/Xdnd 重写 |
| 46 → 0 警中含 6 条 `CS8002` 抑制 | 工程 | 待全部 `*.Linux` 工程统一公开签名后解除抑制 |
| 复合字体资源 `Fonts/*.CompositeFont`（port-lib 不搬运通配符 `Resource`） | 运行期 | 字体回退表缺失，编译期无感 |
| `ModuleInitializer.cs` 被剔除（D 类） | 运行期 | 少了 Windows-only 的 DPI 感知与原生预装载；Linux 无对应语义。若将来需要"早期失败"语义，请在宿主/测试里显式 `DWriteLoader.LoadDWrite()` |
| 95 个 MIL 导出 / 消息泵 / 子类化（预研 §3.4） | 运行期 | 呈现与窗口语义，月级 |

## 7.5 U13 条目文本（供 docs/unimplemented.md 合并）

> 以下文本按 `docs/unimplemented.md` 的登记口径撰写，可直接并入该文件（建议作为 §2.6 或独立小节）。

```markdown
### 2.6 托管侧剪贴板 / 拖放（U13 · PresentationCore）

**登记对象**：`System.Windows.Clipboard`、`System.Windows.DataObject`、`System.Windows.DataFormats`、
`System.Windows.DataFormat` 四个公开类型的 Linux 实现。

**当前状态**：**占位抛异常**（不是 `E_NOTIMPL`，是托管侧 `PlatformNotSupportedException`）。
占位文件：`build/shims/PresentationCore.OleApi.Stubs.cs`（经
`build/shims/PresentationCore.shims.txt` 编入 `build/PresentationCore.Linux`）。

**为什么是占位而不是实现**（两条实测依据，详见 `build/excludes/PresentationCore.txt` B 类）：
1. 上游实现依赖 WinForms 私有包 `System.Private.Windows.Core` 的泛型宿主
   （`Composition<,,>` / `ClipboardCore<T>` / `DragDropHelpers<,>` / `DataFormatsCore<T>`）；
   实测 `PackageReference System.Private.Windows.Core` → **NU1101**（可用镜像无此包）。
2. 该私有包的形态只存在于另一个仓库，按调用点手写 = 「能编译但语义错」
   （SplashScreen 先例，`build/excludes/WindowsBase.txt`）。

**行为口径（必须保持）**：所有成员抛
`PlatformNotSupportedException("…：Linux 侧剪贴板/DnD 需 X11 selection/Xdnd 实现，见 handoff U13…")`；
**不得返回空集合/默认值假装成功**。唯一真实现的部分是纯数据：
`DataFormat.Name/Id` 与 `DataFormats` 的 23 个格式名常量；后者的字面量来自 WinForms
`DataFormatNames`（离线无 oracle），已在源码内标注「值未离线核实」。

**机械校验建议**：仿 §2.0 的做法，在托管侧测试里断言四个类型的每个公开成员都抛
`PlatformNotSupportedException`（任何成员"静默返回"都应让测试失败）。

**恢复路线**（二选一）：
- ① **推荐**：按 X11 selection（`CLIPBOARD`/`PRIMARY`/`TARGETS`）与 Xdnd 协议重写这四个类型，
  并**替换**占位文件（从 `PresentationCore.shims.txt` 移除引用）；OLE 私有宿主不再需要。
- ② 取得 `System.Private.Windows.Core` 等价面（或 CsWin32 真实生成），重建泛型宿主，
  恢复被剔除的 7 个文件；需配 COM vtbl 保真测试（字节级地基见
  `build/shims/WindowsWin32.Shim.cs` 的 FORMATETC/STGMEDIUM/TYMED/DVASPECT/CLIPBOARD_FORMAT/DV_E_TYMED 段落）。
```

## 7.6 本轮新增 / 修改文件

| 文件 | 动作 | 说明 |
|---|---|---|
| `build/DirectWriteForwarder.Linux/DirectWriteForwarder.Linux.csproj` | 新增 | 托管等价工程（0 错 0 警，产出 DLL） |
| `build/DirectWriteForwarder.Linux/ManagedSurface.cs` | 新增 | 41 个托管类型 + 4 个委托 + `NativeWPFDLLLoader` + `TrueTypeSubsetter`（三档语义） |
| `build/DirectWriteForwarder.Linux/NativeMirrors.cs` | 新增 | `MS.Internal.Text.TextInterface.Native` 的接口/枚举/结构镜像（PresentationCore 的 `Native.X*` 引用要求） |
| `build/DirectWriteForwarder.Linux/AssemblyAttrs.cs` | 新增 | IVT 到 PresentationCore（公钥由脚本从上游 `OtherAssemblyAttrs.cpp` 提取） |
| `build/shims/PresentationCore.OleApi.Stubs.cs` | 新增 | OLE 公开 API 占位（PNSE，含 U13 消息） |
| `build/shims/PresentationCore.AssemblyAttrs.cs` | 新增 | `[assembly: CLSCompliant(false)]`（修 37 条 CS3021） |
| `build/shims/PresentationCore.shims.txt` | 新增 | 把上述两个文件编入 PresentationCore（port-lib 机制） |
| `build/PresentationCore.Linux/reapply-patches.py` | 改写 | 新基线下补丁 B（PublicSign，含 CS8002 抑制）+ D（DirectWriteForwarder 引用）；A/C 退役说明 |
| `build/excludes/PresentationCore.txt` | 修改 | B 类 8 → 7 文件（`OleServicesContext.cs` 放回，含实测依据）；新增 **D 类**（`ModuleInitializer.cs`，运行期装载所必需）；补占位文件的下线条件 |
| `docs/U2-PresentationCore-prep.md` | 修改 | 新增本节（M4 收官） |
| `build/shims/WindowsWin32.Shim.cs`、`build/keys/WcpPublicKey.snk` | 沿用上轮 | 见 §3 |
| `/tmp/m4/shimprobe/` | 沿用上轮 | shim 探针 `PASS=65 FAIL=0`（未进仓库） |
| `/tmp/m4/oleprobe/` | 新增（**不进仓库**） | OLE 占位口径 + 运行期装载探针 `PASS=11 FAIL=0` |

**回归**：`WindowsBase.Linux` 重编 **0 错 0 警**；`DirectWriteForwarder.Linux` **0 错 0 警**。
**上游零改动**（`upstream/wpf` 全程只读，已用 `find -newermt` 验证）。
