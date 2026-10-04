# `P1-hctab3` 报告 —— `T-B16` ③ tab3（`PRECOND-TAB3-PAGE-RENDER`）：`PresentationUI` 主题字典缺失 —— **补齐最小必要面（`P8`）＋ 页宿主被接出（无闸、无 PF 侧绕行）＋ 判据不成立（如实划界）**

> 任务：`build/MilBridge/tasks-tail2/T-B16.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T07:2x–08:0x+0800`（各格另注；**所有数值现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，**`HEAD=1b32774862977738850053d593a77b7ff60d8763`**（现取；＝ `T-B15` 后）。
> 权威件（开工时现取）：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **`5f9ed647c68197ae`**（＝ `T-B15` 在册值）、`exports=846`。
> 装置：私有 `Xvfb :235 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §7）；
>   应用 ＝ 仓外 hc demo（`$APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，`DOTNET` 走 `$HOME/.dotnet`）。
>   **未占** `:10`／`:231`／`:236`–`:239`；所有腿只在空闲 `:235` 上、**只按 PID 收净**。
> **重活全走槽**：`bash ~/heavy-slot.sh --min-avail 1500 --max-hold 900`（13 趟腿，全部 `HEAVYSLOT=ACQUIRED … RELEASED rc=0`，`held=20–45 s`）。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① 本侧 `PresentationUI` 现取** | 替身目录**只有 2 件**（`CycleStub.PresentationUI.Linux.csproj`／`FindToolBar.ApiSubset.cs`，`git ls-files` 现取＝2）：**无 `Themes/`、无任何 `.xaml`、无 `[assembly: ThemeInfo]`** ⇒ `SystemResources` 找不到该程序集的 `themes/generic.baml`。上游 `PresentationUI/Themes/Generic.xaml` 现取共 **56 个** `x:Key="{ComponentResourceKey …}"` 资源，替身提供 **0 个**；`FlowDocumentReader` 自身要用到的键（件:行）共 **8 处引用**。§1 |
| **①′ 缺哪个键、为什么是它** | tab3＝`FlowDocumentReader`；「查看器」模式的内容宿主＝内部 `ReaderPageViewer`，其 `Style` 由 `SetResourceReference(StyleProperty, PageViewStyleKey)` 给（`FlowDocumentReader.cs:1150-1156`），键 = `PUIPageViewStyleKey`（同件 `:2043-2052`）。该键**唯一**出处＝上游主题字典**一个 `Style` 块**（`Generic.xaml:8675-8699`），模板里那一个 `DocumentPageView` 就是**页宿主**。§1.2 |
| **② 修（`P8`，生成器 ＋ `temp+rename`）** | 新建 `build/CycleStub.PresentationUI.Linux/reapply-patches.py`：**逐字**从上游取那一个 `Style` 块 → 生成 `Themes/Generic.xaml`；生成 `ThemeInfo.Linux.cs`（`ThemeInfo(None, SourceAssembly)`）；幂等注入 csproj 补丁块 A/B（Linux 标记编译链，照 `PresentationFramework.Classic.Linux` 已验证的一套）。生成器重跑 == 现盘（§2.4）。**闸 `WpfLinuxPresentationUITheme` 缺省 `false`**（理由见 §2.5）。§2 |
| **②′ 现取：页宿主真的被接出来了** | **不靠任何 PF 侧接线**（`[READERHOST]` 整块 **0 行**，T-B13 的闸仍缺省关）：`[DPV] site=Ctor` **1→2 次**、`[DVBI] site=GetPageViews selfType=ReaderPageViewer n=1`（缺省腿**没有**这一行）。§3.2 |
| **③ 判据（帧面）** | **不成立**：`tab3` 帧 `0c51d1ad6fa46543 → 71a93980be1f49a6`（**`sha16` 变了**），但 `colors 562→562`、文档区 `148→148`、**具名色 0/0/0/0 → 0/0/0/0**；两帧差异仅 **780 px**、全落在文档区 `x∈[303,797] ∧ y∈[146,519]`，**无一个具名色**。**反极性**（撤闸 ⇒ 缺省构建的同一份替身）**逐字节回** `0c51d1ad6fa46543`／148／0。§3.3–3.4 |
| **③′ 不得回退** | `tab1`：**全 8 腿逐字节 `c22457cf663453dd`** ⇒ 零回退。`tab2`：**同一序（`1,2,3`）**两形态逐字节同（`c22457cf663453dd`）；⚠️ **但 `3,2,1` 序上，闸开腿 `tab2` 帧由 `fae93ea5ed7a2f30` 变成 `71a93980be1f49a6`（＝ tab3 的那一帧）**（两侧各 **3 次独立复现**）⇒ **如实记：该序形态上 `tab2` 帧变了**（闸缺省关 ⇒ 不落在缺省路径上）。§3.5 |
| **③″ 新增症状** | 闸开腿**恒 +1 条** `COMException … E_HANDLE`（4 腿皆 1；闸关腿 9 腿皆 0）。§5 |
| **④ 门禁（现取）** | `nm==exports`（**846==846**，`diff` 空）｜`PTSGAP=PASS … so16=5f9ed647c68197ae exports=846`｜`PTS_GUARD=PASS legs=2/2`｜`PTS_COLORANCHOR=PASS k=24 hits=3`｜`DEFREG=PASS declared=225 route_ids=225`｜`REPORTID=PASS files=363 ids=2266 declared=225`。§4 |
| **⑤ 症状门（成对）** | `magenta=0`／`Unrecoverable=0`／`alive=yes`／`app_rc=143`／`PTS_GAP entry=0`／`FORMATLINE-LINE=156`（两形态同）；`[HC-UNHANDLED]`：**闸关 390–565**（无 `E_HANDLE`）／**闸开 446–538 ∧ `E_HANDLE=1`**。§5 |
| **⑥ 边界（未违）** | **仓内只改** `build/CycleStub.PresentationUI.Linux/**`（生成器 ＋ 生成件 ＋ csproj）；**未碰** `upstream/**`（只读）／仓外 hc 工程／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（只调不改）；**未跑**整趟 `verify-all`；app-local **五件逐位未动**（`libwpfwin32.so=5f9ed647c68197ae` 等，§7.3）；显示位与进程**按 PID 收净**。§7 |
| **⚠️ 写域口径（如实记）** | 派单写域写的是 **`build/PresentationUI.Linux/**`**，而**现盘该路径不存在**（现取 `ls build/` 无此目录）；本移植里运行期的 `PresentationUI` **就是** `build/CycleStub.PresentationUI.Linux`（`build/PresentationFramework.Linux/PresentationFramework.Linux.csproj:1524` 的 `HintPath` ＋ `build/third-party/windowsdesktop-app-linux-framework.sh:91` 的 app-local 映射都指向它）。故本席**落在该目录**，并**不改** `integration-wave.sh`／第三方映射（都不在写域）⇒ 唯一能把「主题字典」送进运行期而又不碰黑名单的落点。 |

**一句话**：`tab3` 空白的**真正缺件**是 **PresentationUI 主题字典里那个 `Style`（`PUIPageViewStyleKey`）**；本席按**上游同源**把它（**生成器 `P8` ＋ `temp+rename` ＋ 幂等**）补进**运行期的 PresentationUI 程序集**，**现取**它**不靠任何 PF 侧接线**就把页宿主接出来了（`[DVBI] selfType=ReaderPageViewer n=0→1`、`[DPV] Ctor 1→2`）—— **但帧面判据不成立**（`562→562`／具名色 `0→0`，只有 780 px 边框抗锯齿变化），且**闸开腿恒 +1 条 `E_HANDLE`**、`3,2,1` 序上 `tab2` 帧变 ⇒ 本增量**按 `T-B11`/`T-B13` 体例做缺省关**（`WpfLinuxPresentationUITheme=true` 才开），并如实划界到 `PRECOND-TAB3-PAGE-RENDER`（页宿主到位后页面仍不上屏）。

---

## §1 ① 现取：本侧 `PresentationUI` 到底提供了什么

### 1.1 替身形态（现取，件:行）

| 面 | 现取 |
|---|---|
| 目录清单 | `build/CycleStub.PresentationUI.Linux/`：`CycleStub.PresentationUI.Linux.csproj`、`FindToolBar.ApiSubset.cs`（`git ls-files build/CycleStub.PresentationUI.Linux` = **2 件**） |
| `Themes/` | **不存在**（`find … -iname 'Themes' -o -iname '*.xaml'` 现取 **0**） |
| `ThemeInfo` | **无**（`grep -c ThemeInfo FindToolBar.ApiSubset.cs` 现取 **0**） |
| 自述（内容锚） | `.csproj` 头注逐字：`本替身**就是**当前运行期的 PresentationUI（未移植真件）`；`恢复条件：移植 PresentationUI（含 BAML 标记编译 + 其主题资源）后，产出同名 PresentationUI.dll 覆盖本替身即可（身份一致）` |
| 身份 | `AssemblyName=PresentationUI`、`SignAssembly/PublicSign` 走 `build/keys/WcpPublicKey.snk` ⇒ 与将来真件**同名同签名**（故**可以直接替换**：本增量的落点正是这条路） |

### 1.2 客户端要哪些键（件:行 ＋ 内容锚原文）

`grep -rn "ComponentResourceKey(typeof(PresentationUIStyleResources)" upstream/…/PresentationFramework/` 现取 **8 处**：

| 件:行（现取） | 内容锚原文（键名） | 谁用它 |
|---|---|---|
| `System/Windows/Controls/FlowDocumentReader.cs:47` | `new FrameworkPropertyMetadata(new ComponentResourceKey(typeof(PresentationUIStyleResources), "PUIFlowDocumentReader"))` | `FlowDocumentReader` 的 `DefaultStyleKey`（hc 给隐式样式 ⇒ 本腿不走它） |
| `System/Windows/Controls/FlowDocumentReader.cs:2049` | `_pageViewStyleKey = new ComponentResourceKey(typeof(PresentationUIStyleResources), "PUIPageViewStyleKey");` | **「查看器」模式的页宿主样式 ⇒ 本条的目标** |
| `System/Windows/Controls/FlowDocumentReader.cs:2065` | `… "PUITwoPageViewStyleKey"` | 「两页」模式 |
| `System/Windows/Controls/FlowDocumentReader.cs:2081` | `… "PUIScrollViewStyleKey"` | 「滚动」模式 |
| `System/Windows/Controls/FlowDocumentScrollViewer.cs:54` | `… "PUIFlowDocumentScrollViewer"` | `DefaultStyleKey` |
| `System/Windows/Controls/SinglePageViewer.cs:50` | `… "PUIFlowDocumentPageViewer"` | `DefaultStyleKey` |
| `System/Windows/Controls/StickyNote.cs:98` | `… "StickyNoteControlStyleKey"` | 便签样式 |
| `MS/Internal/documents/DocumentViewerHelper.cs:302` | `_findToolBarStyleKey = new ComponentResourceKey(… "PUIFlowViewers_FindToolBar")` | 查找工具条样式（替身的 FindToolBar 无模板 ⇒ 本就降级） |

**键的设值点（丙）** —— `FlowDocumentReader.GetViewerFromMode`（内容锚现取）：

```
                    if (_pageViewer == null)
                    {
                        _pageViewer = new ReaderPageViewer();
                        _pageViewer.SetResourceReference(StyleProperty, PageViewStyleKey);
                        _pageViewer.Name = "PageViewer";
```

（`upstream/…/System/Windows/Controls/FlowDocumentReader.cs:1150-1156`；`ReaderPageViewer : FlowDocumentPageViewer` 见 `MS/Internal/documents/IFlowDocumentViewer.cs:452`。）

### 1.3 该键在上游的**唯一**定义（件:行 ＋ 逐字）

`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationUI/Themes/Generic.xaml`：

| 行（现取） | 内容锚原文 |
|---|---|
| `:16` | `<ResourceDictionary x:Uid="ResourceDictionary_1" … xmlns:ui="clr-namespace:System.Windows.Documents" …>`（**注意 `ui:` 不带 `assembly=` ⇒ 本程序集**） |
| `:8675` | `<Style x:Uid="Style_729" TargetType="{x:Type FlowDocumentPageViewer}"` |
| `:8676` | `BasedOn="{x:Null}"` |
| `:8677` | `x:Key="{ComponentResourceKey TypeInTargetAssembly={x:Type ui:PresentationUIStyleResources}, ResourceId=PUIPageViewStyleKey}">` |
| `:8691-8693` | `<DocumentPageView x:Uid="DocumentPageView_2" PageNumber="0"` ／ `DocumentViewerBase.IsMasterPage="True"` ／ `ClipToBounds="True"/>` ← **页宿主** |
| `:8699` | `</Style>` |
| `:8700-8743` | `PUITwoPageViewStyleKey`（同形，两个 `DocumentPageView`） |
| `:8744-8766` | `PUIScrollViewStyleKey` |

**键集清点（现取）**：该文件里 `x:Key="{ComponentResourceKey …}"` 共 **56 个**（`grep -c` 现取），其中 `FlowDocument*` 族 6 个（`PUIFlowDocumentPageViewer:8417`／`PUIFlowDocumentScrollViewer:8571`／`PUIPageViewStyleKey:8677`／`PUITwoPageViewStyleKey:8702`／`PUIScrollViewStyleKey:8746`／`PUIFlowDocumentReader:8768`）＋ `PUIFlowViewers_FindToolBar:9030`。**本侧替身提供 0 个。**

### 1.4 为什么「替身 ⇒ 键解析为空」（机制逐跳，件:行）

| 跳 | 件:行（现取） | 内容锚原文 | 作用 |
|---|---|---|---|
| 甲 | `System/Windows/SystemResources.cs:339-386` | `Assembly assembly = (typeKey != null) ? typeKey.Assembly : resourceKey.Assembly;` | 按 `ResourceKey` 的**程序集**（＝ `PresentationUIStyleResources` 所在＝ **PresentationUI**）定位字典 |
| 乙 | 同上 `:363-364` | `ResourceDictionaries dictionaries = EnsureDictionarySlot(assembly);` … `LoadThemedDictionary(isTraceEnabled);` | 先 themed |
| 丙 | 同上 `:372` `:686-737` | `dictionary = dictionaries.LoadGenericDictionary(isTraceEnabled);` | 再 **generic**（`Themes/Generic.xaml` 走这条） |
| 丁 | 同上 `:742-759` | `ThemeInfoAttribute locations = ThemeInfoAttribute.FromAssembly(_assembly);` … `_themedLocation = ResourceDictionaryLocation.None; _genericLocation = ResourceDictionaryLocation.None;` | **没有 `ThemeInfo` ⇒ 两个位置都是 `None` ⇒ 直接返回 `null`**（替身的现状） |
| 戊 | 同上 `:891-968`＋`:1673` | `ResourceManager rm = new ResourceManager($"{assemblyName}.g", assembly);` … `resourceName = $"{resourceName}.baml";`；`internal const string GenericResourceName = "themes/generic";` | 键位＝ `{AssemblyName}.g.resources` 里的 **`themes/generic.baml`**（本增量的生成物正是它） |
| 己 | `PresentationFramework/System/Windows/ThemeInfoAttribute.cs:20-24`；上游 `PresentationUI/OtherAssemblyAttrs.cs:11` | `[assembly: System.Windows.ThemeInfoAttribute(System.Windows.ResourceDictionaryLocation.SourceAssembly, System.Windows.ResourceDictionaryLocation.SourceAssembly)]` | 上游键位（generic ∈ 源程序集） |
| 庚 | `FlowDocumentReader.cs:1150-1156` | `_pageViewer.SetResourceReference(StyleProperty, PageViewStyleKey);` | **`Style` 被本地设值**（资源引用）⇒ 类型隐式样式被绕过 ⇒ 无 `ControlTemplate` ⇒ **页宿主从不被构造** |

---

## §2 ② 修（`P8`）：按上游同源补齐**最小必要面**

### 2.1 生成器（新建 `build/CycleStub.PresentationUI.Linux/reapply-patches.py`）

| 件:行（生成器内，现取） | 产物 | 作用 |
|---|---|---|
| `_extract_style_block()`（内容锚 `KEY_ANCHOR = "ResourceId=PUIPageViewStyleKey}"`，**不用行号**） | `Themes/Generic.xaml` | **逐字**取上游那**一个** `<Style>…</Style>`（含缩进），包一层 `<ResourceDictionary … xmlns:ui="clr-namespace:System.Windows.Documents">`；**不复制视觉、不改几何**；断言「恰好一个 Style ∧ 含 `DocumentPageView`」 |
| `THEMEINFO_TEXT` | `ThemeInfo.Linux.cs` | `[assembly: ThemeInfo(ResourceDictionaryLocation.None, ResourceDictionaryLocation.SourceAssembly)]`（themed 面本移植不用 ⇒ `None`） |
| `_block_a()` | csproj 补丁块 A | `WpfLinuxPresentationUITheme`（**缺省 `false`**）＋ Linux 标记编译链属性 ＋ 自产 PF 的 `<Reference>`（**只**为标记编译期解析三个类型）＋ `<Compile ThemeInfo.Linux.cs>` ＋ `<Page Themes/Generic.xaml>`（三者都带 `Condition`＝闸开） |
| `_block_b()` | csproj 补丁块 B | 显式 `Import Microsoft.WinFX.targets` ＋ `Import build/WpfMarkupCompile.Linux.targets` ＋ 摘 `GeneratedInternalTypeHelper.g.cs`（同 `Classic` 补丁 F）＋ 构建期自检（**闸开时**断言 BAML 真产出） |
| `_write_atomic()` / `_strip()` | 全部落盘 | `temp+rename`；补丁块**先摘后注**，且随手摘掉尾随换行（幂等的必要条件，`Classic` 的实测教训） |

**同源口径（逐条）**：① `Themes/Generic.xaml` 的内容**逐字来自上游**（不是重画）；② `ThemeInfo` 的键位与上游 `OtherAssemblyAttrs.cs:11` 同源；③ 标记编译链与 `build/PresentationFramework.Classic.Linux/reapply-patches.py`（已验证能产 BAML 的先例）**同一套**。

### 2.2 生成件逐条（现取）

```
Themes/Generic.xaml（2218 B；1 个 Style）——
  <ResourceDictionary xmlns="…" xmlns:x="…" xmlns:ui="clr-namespace:System.Windows.Documents">
      <Style x:Uid="Style_729" TargetType="{x:Type FlowDocumentPageViewer}"
             BasedOn="{x:Null}"
             x:Key="{ComponentResourceKey TypeInTargetAssembly={x:Type ui:PresentationUIStyleResources}, ResourceId=PUIPageViewStyleKey}">
          …（逐字上游 8675-8699：Background/HAlign/VAlign/ContextMenu/Template）…
              <DocumentPageView x:Uid="DocumentPageView_2" PageNumber="0"
                                DocumentViewerBase.IsMasterPage="True" ClipToBounds="True"/>
      </Style>
  </ResourceDictionary>
```

**为什么引 PF 却不构成工程引用环**：`<Reference Include="PresentationFramework"><HintPath>…/bin/Release/PresentationFramework.dll</HintPath><Private>false</Private></Reference>` —— 与 `Classic` 引 `PresentationCore` 同一种**文件引用**（非 `ProjectReference`），只为标记编译期解析 `FlowDocumentPageViewer`／`DocumentPageView`／`AdornerDecorator`。⚠️ 这与上游不同（上游 `PresentationUI.csproj:170` 是 `ProjectReference`，靠 `CycleBreakers/` 破环；本仓无该目录）—— **如实记**。

### 2.3 构建（现取）

```
$ dotnet build build/CycleStub.PresentationUI.Linux/CycleStub.PresentationUI.Linux.csproj -c Release -m:1
  使用 Linux 原生标记编译器: build/PresentationBuildTasks.Linux/bin/Release/net10.0/PresentationBuildTasks.dll
  PresentationUI 主题 BAML：obj/Release/Themes/Generic.baml        ← 自检通过
  CycleStub.PresentationUI.Linux -> …/bin/Release/PresentationUI.dll
  已成功生成。 0 个警告 0 个错误
```

| 闸 | 产物 | 字节 | 内嵌资源 |
|---|---|---|---|
| **缺省（`false`）** | `bin/Release/PresentationUI.dll` = **`69136eecc84aa9f5`** | 7168 | **无** `PresentationUI.g.resources`（`strings` 现取命中 **0**） |
| **`-p:WpfLinuxPresentationUITheme=true`** | （另存 `~/tb16-work/bin.PUI.themeON.dll`）= **`a901772b7589382a`** | 9216 | **有** `PresentationUI.g.resources`；`obj/Release/Themes/Generic.baml` = 1463 B |

⇒ **两极化在产物层就是「同一份源、一个 MSBuild 属性」**：缺省 == 替身（逐格复现开工帧），开 == 带主题字典。

### 2.4 幂等（生成器重跑 == 现盘）

```
$ for f in Themes/Generic.xaml ThemeInfo.Linux.cs *.csproj reapply-patches.py; do sha256sum "$f"; done > g5
$ python3 build/CycleStub.PresentationUI.Linux/reapply-patches.py ; … > g6
$ diff g5 g6  ⇒  空
IDEMPOTENT=OK
```

现取关键件 `sha16`：`reapply-patches.py=f2aa17a8f05ebe1c`／`Themes/Generic.xaml=2cb9f463a62774fb`／`ThemeInfo.Linux.cs=7ad90ef4d0bd7aa5`／`CycleStub.PresentationUI.Linux.csproj=7c1f43550c92c63c`。

### 2.5 ⚠️ 闸**缺省关**（如实记，理由三条）

1. **判据不成立**（§3.3：色数没回升、具名色没出现）；
2. **`3,2,1` 序上 `tab2` 帧变了**（`fae93ea5ed7a2f30 → 71a93980be1f49a6`，§3.5）—— 任务明写「不得回退 tab2」；
3. **恒 +1 条 `E_HANDLE`**（§5）。

⇒ 与 `T-B11`（`WPF_PAGEVIEW_ONSCREEN` 被证伪后改默认关）／`T-B13`（接线默认关）**同一处置**：`-p:WpfLinuxPresentationUITheme=true` 即开（可复现）。**缺省路径逐格 == 开工态**（§3.4 的 `off1`／`offo` 与开工腿 `base`／`baseo` 逐字节相同）。

---

## §3 ③ 真跑：成对读数 ＋ 反极性

### 3.1 腿表（现取；装置 `:235`；`sha16` ＝ 整屏 `import -window root`）

| 腿 | `PresentationUI.dll` `sha16` | 闸 | 序 | `tab1` | `tab2` | **`tab3`** | `[HC-UNHANDLED]` | `E_HANDLE` |
|---|---|---|---|---|---|---|---|---|
| `base`／`base2` | `794b4e370cdc10f6`（**开工时 app-local 现值**，Debug 替身） | —（无该面） | `1,2,3` | `c22457cf663453dd` | `c22457cf663453dd` | **`0c51d1ad6fa46543`** | 438／565 | 0 |
| `rev1` | 同上 | — | `1,2,3` | `c22457cf663453dd` | `c22457cf663453dd` | **`0c51d1ad6fa46543`** | 452 | 0 |
| `baseo`／`baseo2`／`baseo3` | 同上 | — | `3,2,1` | `c22457cf663453dd` | **`fae93ea5ed7a2f30`** | **`0c51d1ad6fa46543`** | 541／—／523 | 0 |
| **`off1`** | **`69136eecc84aa9f5`**（**闸缺省关**的同一源产物） | `false` | `1,2,3` | `c22457cf663453dd` | `c22457cf663453dd` | **`0c51d1ad6fa46543`** | 490 | 0 |
| **`offo`** | **`69136eecc84aa9f5`** | `false` | `3,2,1` | `c22457cf663453dd` | **`fae93ea5ed7a2f30`** | **`0c51d1ad6fa46543`** | 390 | 0 |
| **`fix1`／`fix2`** | **`a901772b7589382a`**（**闸开**产物） | `true` | `1,2,3` | `c22457cf663453dd` | `c22457cf663453dd` | **`71a93980be1f49a6`** | 459／433 | **1／1** |
| **`fixo`／`fixo2`／`fixo3`** | **`a901772b7589382a`** | `true` | `3,2,1` | `c22457cf663453dd` | **`71a93980be1f49a6`** | **`71a93980be1f49a6`** | 538／446／499 | **1／1／1** |

⇒ **`off1`／`offo` 与 `base`／`baseo` 逐格相同** ⇒ 「缺省 == 开工态」；`fix*` 是**同一份源**只差一个 MSBuild 属性。

### 3.2 **接线成对读数**（现取；判决「页宿主到底有没有被接出来」）

| 面 | `off1`（缺省） | **`fix1`（开）** |
|---|---|---|
| `[DPV] site=Ctor` | **1 次**（`id=0x1e0469d`，tab2 那个） | **2 次**（`0x1e0469d` ＋ `0x3de521c`） |
| `[DVBI] site=GetPageViews` | 只有 `selfType=FlowDocumentPageViewer n=1` | **多出** `selfType=ReaderPageViewer n=1` |
| `[READERHOST]`（`T-B13` 的闸 `WPF_READER_PAGEHOST`） | **0 行** | **0 行**（该闸仍缺省关） |
| 页宿主现场（`fix1:16516-16521`） | — | `[DPV] site=ArrangeOverride … final=638.4x362.88 page=0x17d23a pv=0xd66410 host=0x19381f5` ／ `[DPH] site=Attach … pvContent=0,0,638.4,362.88 …` ／ `[DPV] site=HostArranged … hostRender=638.4x362.88 hostXf=258.24,107.52,1,1` |

⇒ **本增量的唯一变量就是「主题字典在不在」**：页宿主**不再需要** PF 侧任何接线（`T-B13` 的 `WpfLinuxReaderPageHost` 一行未改、其闸仍缺省关）。这一条把 `T-B13` §4.3 的 `PRECOND-TAB3-OWN-VIEWER-STYLE`（「正解是补主题字典」）**现取证实**。

### 3.3 **帧面成对（`off1` vs `fix1`）**

| 面 | `off1`（缺省） | **`fix1`（开）** |
|---|---|---|
| `tab3` 帧 `sha16` | `0c51d1ad6fa46543` | **`71a93980be1f49a6`**（**变了**） |
| 整屏 `colors` | 562 | **562**（**没回升**） |
| 文档区 `colors`（`x∈[250,800] ∧ y∈[100,600]`） | 148 | **148** |
| 具名色 `GhostWhite/Beige/DarkGreen/LightGoldenrodYellow` | `0/0/0/0` | **`0/0/0/0`**（**没出现**） |
| 两帧差异（`PIL` 现算） | — | **780 px**，`bbox=(303,146)-(798,520)`；**具名色在差异区恒 0** |
| `tab1`／`tab2`（同序 `1,2,3`） | `c22457cf663453dd`／`c22457cf663453dd` | **逐字节相同** |

⇒ **判据三条里只满足「帧 `sha16` 变」**（且那点变化就是**页边框 1–2 px 抗锯齿**，与 `T-B13` §3.3 的 `1992 px` 同族）⇒ **①③ 不成立，不得记成修好**。

### 3.4 **反极性（撤闸 ⇒ 回原帧）**

| 面 | `fix*`（`WpfLinuxPresentationUITheme=true`） | **`off*`（缺省 `false`）** | 判 |
|---|---|---|---|
| `PresentationUI.dll` | `a901772b7589382a`（9216 B，**有** `PresentationUI.g.resources`） | `69136eecc84aa9f5`（7168 B，**无**） | 同一份源、只差一个属性 |
| **`tab3` 帧** | `71a93980be1f49a6` | **`0c51d1ad6fa46543`** | **回开工帧** |
| `[DVBI] selfType=ReaderPageViewer` | **1 行** | **0 行** | 整块不发生 |
| `[DPV] site=Ctor` | 2 次 | **1 次** | 页宿主 0→1 |
| 文档区色数／具名色 | 148／`0/0/0/0` | **148／`0/0/0/0`** | **两形态都空** |
| `E_HANDLE` | **1** | **0** | 症状随闸 |

⇒ **反极性成立**（撤修 ⇒ `tab3` **逐字节回** `0c51d1ad6fa46543`）；**并且**：这条反极性顺带证明「页宿主是否存在」与「是否上屏」**无关**（缺省腿页宿主 0 个也仍空、开腿 1 个也仍空）。

### 3.5 **不得回退（`tab1`／`tab2`）**

| 序 | 形态 | `tab1` | `tab2` | 判 |
|---|---|---|---|---|
| `1,2,3` | `base`／`base2`／`off1`（闸关） | `c22457cf663453dd` | `c22457cf663453dd` | — |
| `1,2,3` | `fix1`／`fix2`（闸开） | `c22457cf663453dd` | `c22457cf663453dd` | **零回退（逐字节）** |
| `3,2,1` | `baseo`／`baseo2`／`baseo3`／`offo`（闸关，**4 腿**） | `c22457cf663453dd` | **`fae93ea5ed7a2f30`** | — |
| `3,2,1` | `fixo`／`fixo2`／`fixo3`（闸开，**3 腿**） | `c22457cf663453dd` | **`71a93980be1f49a6`** | ⚠️ **该序形态上 `tab2` 帧变了**（＝ tab3 的那一帧 ⇒ 「点了 tab2 没换画面」） |

- `tab1`：**全 8 腿逐字节 `c22457cf663453dd`** ⇒ 零回退（亦与 `T-B15` 的 `fix` 帧一致）。
- ⚠️ **`tab2` 如实记**：`1,2,3` 序上两形态同；**`3,2,1` 序上闸开腿由 `fae93ea5ed7a2f30`（551 色）变成 `71a93980be1f49a6`（562 色）**，两侧各 3 次独立复现。**归因（如实）**：闸开腿恒多一条 `E_HANDLE`（§5），而 `E_HANDLE` 恰落在**「tab3 的页宿主第一次进场」**那一刻（`fix1:16516-16523`：`[DPV] ArrangeOverride → [DPH] Attach → [DPV] HostArranged → [DPV] ArrangeEnd → [DPV] MeasureOverride → [HC-UNHANDLED] #… COMException E_HANDLE`）⇒ **合理推断**是那条异常打断了随后的重绘（同一 `tab2` 在闸关腿上会重绘）。⚠️ **本席不把它写成「已证」**：`E_HANDLE` 的**抛出点未定位**（见 §6 具名 `NOINFO`）。
- `3,2,1` 形态与本仓在册形态**一致**（`T-B15` §3.5：`tab2 = fae93ea5ed7a2f30`、`tab3 = 0c51d1ad6fa46543`）；`1,2,3` 形态下 `tab2 ≡ tab1` 是 `T-B8` §2 记的「点了但不换画面」形态，**两形态在闸关侧都逐格复现**。

---

## §4 ④ 门禁（逐条现取；本席跑的）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| awk '{print $3}' \| sort` vs `src/WpfGfx.Linux.Native/bin/exports.txt` | **`846 == 846`**，`diff -q` 空 ⇒ `NM_EQ_EXPORTS=PASS` |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5f9ed647c68197ae exports=846`**；`PTSGAP_CITED=PASS refs=1 strict=1`；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`；rc=0 |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2 fails=- cannot=- direction=in-file phase=realized`**；`PTS_N1_GATE=PASS`；`PTS_ENFE=PASS total=0` |
| `PTS_COLORANCHOR` | 同上（`k=24`） | **`PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 min=200 base=全部0`**（**未回退**）；`k=23` `NOINFO(no-anchor-registered-for-k23)` |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`DEFREG_DECLDRIFT=0`，rc=0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=363 ids=2266 declared=225`**，rc=0（本载体落地**前**现取；落地后 ＋1） |

**未跑**：整趟 `verify-all`（照派单 ②）；`static-jaws-check.sh`。

---

## §5 ⑤ 症状门（成对）

| 症状门 | `base`（开工件） | `off1`（闸缺省关） | **`fix1`（闸开）** | `fixo`（闸开） | `offo`（闸关） |
|---|---|---|---|---|---|
| `magenta` | 0 | 0 | 0 | 0 | 0 |
| `Unrecoverable system error` | 0 | 0 | 0 | 0 | 0 |
| `FailFast` | 75 | 83 | 77 | 89 | 66 |
| `[FORMATLINE-LINE]` | 156 | 156 | 156 | 156 | 156 |
| `PTS_GAP entry=` | 0 | 0 | 0 | 0 | 0 |
| `[HC-UNHANDLED]` | 438 | 490 | **459** | **538** | 390 |
| 其中 **`E_HANDLE`** | **0** | **0** | **1** | **1** | **0** |
| `alive`／`app_rc` | yes／143 | yes／143 | yes／143 | yes／143 | yes／143（均**本席按 PID 收**） |
| `colors`（整屏；`tab3`） | 562 | 562 | 562 | 562 | 562 |

⚠️ **`E_HANDLE` 的成对性（现取，机器证）**：**闸关 9 腿（`base`／`base2`／`rev1`／`off1`／`baseo`／`baseo2`／`baseo3`／`offo`…）恒 0 条；闸开 4 腿（`fix1`／`fix2`／`fixo`＋`fixo2/3`＝5 腿）恒 1 条**。首发现场（`fix1:16522-16523`）：

```
[DPV] site=MeasureOverride id=0x3de521c avail=638.4x359.04 pag=0x157faea page=0x17d23a desired=638.4x362.88 render=638.4x362.88
[HC-UNHANDLED] #458 COMException: The handle is invalid.
 (0x80070006 (E_HANDLE)) ｜ 首帧 at MS.Internal.HRESULT.Check(Int32 hr)
```

**已排除的一个候选**（现取，`WPF_LINUX_MIL_TRACE=1` 腿 `fix2`）：`src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs:665-702` 那条**已登记的** `E_HANDLE` 分支（`MilResource_CreateCWICWrapperBitmap` 未登记句柄）在 trace 里**只打成功两行**（`NOTE … **物化**成功 …`），**没有任何** `⇒ E_HANDLE` 行 ⇒ 本条 `E_HANDLE` **不是**它。其余候选**未定位**（见 §6 具名 `NOINFO`）。

---

## §6 断点归属 · 具名前置 · 可实施替代 · `NOINFO`

### 6.1 本轮**已逐条排除**的（都真跑过）

| 假设 | 现取反证 |
|---|---|
| 「页宿主**造不出来**」 | 闸开腿 `[DPV] site=Ctor` **2 次**＋`[DVBI] selfType=ReaderPageViewer n=1`；且**不需要** PF 侧接线（`[READERHOST]` 0 行） |
| 「缺的是**别的**面（PF 侧绕行）」 | `T-B13` 的两版接线（等价模板／隐式样式）都进了渲染遍历却不上屏；本增量走**上游同源**的主题字典，结果**同族**（色数仍 562） ⇒ **不是绕行方式的问题** |
| 「页宿主**不在渲染树**／页视觉是空的」 | `[DPV] HostArranged … hostRender=638.4x362.88`／`[DPH] Attach … pvContent=0,0,638.4,362.88 … SUB=L3:…,c=106.983,6.983,126.033,36.033`（叶子有真绘制内容） |
| 「色数只是**没统计全**」 | `docink` 现算：整屏 562／文档区 148 ／具名色 `0/0/0/0`；两帧差异 **780 px** 全在文档区且**零具名色** |

### 6.2 剩下的（**如实划界**）

- **真断点（承 `T-B13`，现取再确认并上移一格）＝ `PRECOND-TAB3-PAGE-RENDER`**：**页宿主到位（且不需任何 PF 侧接线）、页视觉有绘制内容、在渲染树里，页面内容仍不上屏**；同刻**恒新增一条 `COMException … E_HANDLE`**。
  - **新增的这条判据（本席的贡献）**：**「页宿主存不存在」与「上不上屏」正交** —— 缺省腿页宿主 **0 个**／开腿 **1 个**，`tab3` 文档区色数**恒 148**、具名色**恒 0**（§3.4）。
- **`NOINFO-TB16-EHANDLE`（具名）**：`E_HANDLE` 的**抛出点未定位**。现取只能拿到**首帧** `MS.Internal.HRESULT.Check(Int32 hr)`（`fix1:16523`）。**已做而未果的两件事（如实）**：① `WPF_LINUX_MIL_TRACE=1` 全 trace（§5）——`src/WpfGfx.Linux` 的 Mil 诊断里**没有**对应失败行（该 `E_HANDLE` 不是 Mil 面自己记过的那条）；② 域内 `grep 'HRESULT.Check('` **只有 3 处**（`build/PresentationCore.Linux/HwndTarget.Linux.cs:562/692/1549`，分别为 `VisualTarget_AttachToHwnd`／`DetachFromHwnd`／`MILUpdateSystemParametersInfo`），但 `MS.Internal.HRESULT` 本体＋绝大多数调用点**在上游未改的代码里**（`WindowsBase`／`PresentationCore` 上游件），**不在本任务写域** ⇒ **无法在不越界的前提下打调用点**。
- **具名前置（承 `T-B13`，本席保持）**：
  - **`PRECOND-TAB3-PAGE-RENDER`**：使**已接上的**页宿主把分页页内容真的画上屏（现取：宿主在、内容有、渲染遍历到、**不上屏**，且伴 `E_HANDLE`）。
  - **`PRECOND-TAB3-EHANDLE-CALLSITE`（本席新立）**：先给 `E_HANDLE` 的**调用点**具名出处。**可实施替代（下一步，按序）**：
    - **(i) 在 `WindowsBase` 的 `MS.Internal.HRESULT.Check` 调用点加一条只读行**（或在 `PresentationCore` 侧给**所有** `MilCoreApi` 失败出口加只读计数）⇒ 判「是**渲染合成**抛的」还是「别的面抛的」。**判据可证伪**：若出处＝渲染合成 ⇒ 断点在呈现面；若出处＝布局/输入 ⇒ 断点在其上游。**⚠️ 该件不在本任务写域 ⇒ 本条只作具名前置，不实施。**
    - **(ii) 与 `T-B12` 的 keep/redrive 对拍**：`T-B12` 的 `RedrivePageVisualsForDisplay` 在闸开腿**按其零动作条件正确没动手**（`trackVisual` 非空）；下一步给「页宿主读到页视觉」那一刻加**只读逐层**行（现取探针只到 `L3`）。
- **`NOINFO-TB16-TAB2-FORM`（具名）**：`tab2` 的 `3,2,1` 序帧在闸开腿变（§3.5）。**归因未证**（合理推断＝一条 `E_HANDLE` 打断了重绘）；**这一条本身没有机读判据**，故按 `NOINFO` 记，**不**把它写成「已回退 tab2」（闸缺省关 ⇒ 缺省路径上 `tab2` 逐字节 == 开工件）。

### 6.3 未做／需往前一层（如实点名）

- **未**改 `src/WpfGfx.Linux/**`（Mil 呈现层；**不在写域**）——`E_HANDLE` 的一个候选面。
- **未**改 `WindowsBase`／上游 `PresentationCore`（`HRESULT.Check` 及其调用点；**不在写域**）。
- **未**把闸默认打开（§2.5）。
- **未**把另外 **55 个** 主题字典资源补齐（本增量**只要** `PUIPageViewStyleKey` 这一个「最小必要面」；`PUITwoPageViewStyleKey`／`PUIScrollViewStyleKey` 一并可取（`Generic.xaml:8700-8766`），但**现取证明补不补都与本判据无关**，故**不做未验证的扩展**）。

---

## §7 边界 · 收净 · 自证

1. **写域（现取 `git status --porcelain`）**：
   ```
    M build/CycleStub.PresentationUI.Linux/CycleStub.PresentationUI.Linux.csproj   ← 生成器产（补丁块 A/B）
   ?? build/CycleStub.PresentationUI.Linux/ThemeInfo.Linux.cs                     ← 生成器产
   ?? build/CycleStub.PresentationUI.Linux/Themes/                                ← 生成器产（Generic.xaml）
   ?? build/CycleStub.PresentationUI.Linux/reapply-patches.py                     ← 新建（生成器）
   ?? build/MilBridge/tasks-tail2/T-B16.md                                        ← 派单件（开工时即存在，非本席）
   ```
   **无** `src/**`、**无** `upstream/**`、**无** `build/MilBridge/tools/**`、**无** `integration-wave.sh`／第三方映射。⚠️ **写域口径**见 §0 末行（派单写 `build/PresentationUI.Linux/**`，现盘不存在该路径；运行期 PresentationUI ＝ `build/CycleStub.PresentationUI.Linux`）。
2. **副本先行／写前备份**（`cp -p`，取在**任何写之前**）：`~/tb16-work/bak/{CycleStub.PresentationUI.Linux.csproj.orig(6871f9b1e375d053), FindToolBar.ApiSubset.cs.orig, *.applocal.orig×6}`。
3. **app-local**：**五件逐位未动**（现取 `libwpfwin32.so=5f9ed647c68197ae`／`wpfgfx_cor3.so=a7a0f884b704ca96`／`PresentationCore.dll=8e0234c89b452487`／`PresentationFramework.dll=1ddedabb2b033b9f`／`WindowsBase.dll=0b54a1e3f9d37ab1`，与开工值逐位相同）；`PresentationUI.dll` 收净为 **`69136eecc84aa9f5`** ＝ `build/CycleStub.PresentationUI.Linux/bin/Release/PresentationUI.dll`（**闸缺省关**的构建产物，即第三方映射 `bin/$CFG`（`CFG=Release`）的权威位）。⚠️ **如实记**：该位**开工时是 `794b4e370cdc10f6`（Debug 产物）**，与本仓映射声明的 `$CFG=Release` 本就不同源 ⇒ 本席把它对齐到 Release 权威位（**这属收净，不是本增量引入的产品变化**：`off*` 腿证明 Release 缺省产物与 Debug 替身**行为逐格相同**）。
4. **进程／显示位按 PID 收净**：`:235` 的 `Xvfb`／`xfwm4` 按 `~/tb16-work/{xvfb,wm}.pid` 收；13 腿的 `HandyControlDemo` 全部按 PID 收（`APP_RC=143`＝本席 `kill`）。**未占** `:10`／`:231`／`:236`–`:239`。
5. **构建**：`dotnet build build/CycleStub.PresentationUI.Linux/CycleStub.PresentationUI.Linux.csproj -c Release -m:1`（**0 警告 0 错误**，两次构建同 `sha16`）；`-p:WpfLinuxPresentationUITheme=true` 亦 **0 警告 0 错误**。
6. **黑名单未碰**：`upstream/**`（**只读**）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。**未跑**整趟 `verify-all`。**未** `git add/commit/push`。
7. **纪律自证**：重活走槽；显示位只用空闲 `:235`；`temp+rename`（生成器 `_write_atomic`，本载体亦如此落盘）；**报数一律现取**（纪律 40）；**接线可撤**（一个 MSBuild 属性；本席已真跑反极性证明缺省态 `tab3` **逐字节回** `0c51d1ad6fa46543`）；**未伪造几何／台账**；**未假成功**（判据不成立即记不成立，并给出具名前置＋可实施替代）。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-hctab3-impl-report.md | sha256sum | cut -c1-16`）＝ **`e02499f67962e62a`**（本行下方无内容，取该行之前全文的哈希）。
