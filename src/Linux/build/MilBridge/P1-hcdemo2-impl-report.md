# P1-hcdemo2-impl 报告 —— hc demo「`XamlParseException` ⇒ UI 未建起」定位并修 —— 实现

> 任务：`build/MilBridge/tasks-tail2/T-B7.md`（实现子代理；本轮唯一写者）。
> 读时：2026-10-03T00:1x–00:31+08:00（各格另注）。口径：**本文所有数字都是现场读数**；命令与输出逐条给出，可复算。
> 装置：`Xvfb :23x -screen 0 1280x1024x24` ＋ `xfwm4` ＋ `run-hc.sh --no-sync` ＋ **`xdotool windowmap`**（＝ 复刻主控 `/tmp/hcv6.sh` 的取证口径，见 §3.1）。
> ⚠️ 本机 `DISPLAY` 空；本报告所有腿都用**自起自收**的 `:23x`（用完按 PID 收净，见 §6.4）。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① 内层异常原文** | 5 条 `[HC-UNHANDLED] XamlParseException` 的**最内层** = **`System.NotImplementedException: The method or operation is not implemented.`**（无参、无信息）；它被 `System.Xaml.XamlObjectWriterException` ＋ `System.Windows.Markup.XamlParseException` **套了两层**（§1.2） |
| **① 关键栈帧** | `Baml2006SchemaContext.ResolveBamlType` ← `GetXamlType(Int16)` ← **`GetPropertyDeclaringType(Int16)`** ← `Baml2006Reader.GetStaticExtensionValue` ← `Process_PropertyWithExtension` ← `ResourceDictionary.CreateObject` ← **`DeferredThemeResourceReference.GetValue`** |
| **② 第一处断点（件:行）** | **`build/PresentationFramework.Linux/Baml2006SchemaContext.Linux.cs:558`**（上游 `upstream/wpf/…/Baml2006/Baml2006SchemaContext.cs:558`）＝ `ResolveBamlType` 里 `throw new NotImplementedException();` —— 上游原文：<br>`541 private XamlType ResolveBamlType(BamlType bamlType, Int16 typeId)` … `558 throw new NotImplementedException();` |
| **② 归因（本移植缺哪个面）** | **主题资源字典面**：`PresentationFramework.Classic` 主题件的**身份不匹配**（app-local 里是一枚 **`Version=10.0.0.0`** 的陈旧件，而栈内其余件全是 **`4.0.0.1`**）⇒ 主题 BAML 里的类型记录（`Microsoft.Windows.Themes.ClassicBorderDecorator`，宿主件 `PresentationFramework.Classic, Version=10.0.0.0`）解析不出来。**不是** `StaticResource` 解析器 / 控件模板 / `PresentationUI` 的错（详见 §2.2）。 |
| **③ 修** | ① **帧面修（操作件）**：用 HEAD 源重建 `PresentationFramework.Classic`（→ `4.0.0.1`）并回填 app-local；② **端口加固（`P8` 生成器）**：给上述断点加**具名出口** `[BAML-TYPE-UNRESOLVED]`（仍抛 `NotImplementedException`，只补类型名/宿主件） |
| **③ 帧面成对（同一装置）** | `colors` **`181 → 386`**；`[HC-UNHANDLED]` **`5 → 0`**；主窗 `Map State` **`IsUnMapped → IsViewable`**（§3） |
| **④ 反极性（撤修 ⇒ 回 `181`）** | 把陈旧件放回 ⇒ **`colors=181` ∧ `unhandled=5` ∧ 具名行 `[BAML-TYPE-UNRESOLVED] type='Microsoft.Windows.Themes.ClassicBorderDecorator' … Version=10.0.0.0`**（§3.4） |
| **⑤ 门禁** | `HANDOFF_MV=PASS cells=9`／`DEFREG=PASS declared=225 route_ids=225`／`REPORTID=PASS files=354 ids=2265`／`PTSGAP=PASS`，**四者 `rc=0`**；`SSC` `rc=0`（其 `PF` 格因**本次重建**与仓外哨兵不一致，见 §4.5）；`integration-wave` **未跑**（`NOINFO`，主控独占动作，见 §4.6） |

**一句话**：UI 没建起的**最内层原因**不是 XAML/静态资源解析，而是 **app-local 的主题件 `PresentationFramework.Classic.dll` 是一枚 `Version=10.0.0.0` 的 L2 波残留**——栈内其余件在一次"L2 回退 + 全量重建"后都回到 `4.0.0.1`，唯独**主题件不在重建/同步清单里**，于是它的 BAML 类型记录绑不回任何真件，`ResolveBamlType` 返回 `null` ⇒ 上游那句**无参** `NotImplementedException` ⇒ 主题字典建不起来 ⇒ 5 条 `[HC-UNHANDLED]`。修法两件：**回填正确的主题件**（帧面 `181→386`、异常 `5→0`）＋**让这个断点以后会自己报出类型名**。

---

## §1 ① 取全栈（手段 ＋ 内层原文 ＋ 关键栈帧）

### §1.1 手段（**只读**，不动仓、不动 hc 工程）

`[HC-UNHANDLED]` 守护（`~/hc-linux/.../Shared/HandyControlDemo_Shared/App.xaml.cs:68-79`）只印 `ex.Message` ＋ `ex.StackTrace.Split('\n')[0]`，而 `ex` 是**最外层** `XamlParseException`（`XamlReader.WrapException` 会把内层 XamlParseException 原样抛出，`upstream/…/Markup/XamlReader.cs:512-546`）⇒ 内层不可见。
取全栈用 **`DOTNET_STARTUP_HOOKS`**（.NET 标准起动钩子，**进程外、零仓改动**）：

```csharp
// ~/tb7-work/hook/Hook.cs（只读探针，非仓内件）
public static class StartupHook {
  public static void Initialize() {
    AppDomain.CurrentDomain.FirstChanceException += (s,e) => {   // 首次机会异常：最内层可见
      var n = e.Exception.GetType().Name;
      if (n.Contains("Xaml")||n.Contains("Resource")||n.Contains("Markup")||n.Contains("StaticResource"))
        Console.Error.WriteLine("[FCE] " + e.Exception.ToString() + "\n[FCE-END]");
    };
  }
}
```

复算命令（等价于 `run-hc.sh` 去掉 `DOTNET_STARTUP_HOOKS` 之外的零改动）：

```bash
cd /home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0
DOTNET_STARTUP_HOOKS=$HOME/tb7-work/hook/bin/Release/net10.0/Hook.dll DISPLAY=:23x \
  timeout 60 dotnet HandyControlDemo.dll > /tmp/tb7-fce.log 2>&1
grep -m1 -A40 '^\[FCE\] System.Xaml.XamlObjectWriterException' /tmp/tb7-fce.log
```

### §1.2 内层原文（现取，落盘 `~/tb7-work/fce.log`）

5 条 `[HC-UNHANDLED]` 的**外形**（＝主控现场 `/tmp/hc-run-172132.log` 逐字）：

```
[HC-UNHANDLED] #1 XamlParseException: Provide value on 'System.Windows.Markup.StaticResourceHolder' threw an exception.
[HC-UNHANDLED] #2 XamlParseException: Initialization of 'System.Windows.Controls.TextBlock' threw an exception.
[HC-UNHANDLED] #3 XamlParseException: 'Initialization of 'System.Windows.Controls.Primitives.ToggleButton' threw an exception.' Line number '18' and line position '56'.
[HC-UNHANDLED] #4 XamlParseException: Initialization of 'System.Windows.Controls.Primitives.ResizeGrip' threw an exception.
[HC-UNHANDLED] #5 XamlParseException: Initialization of 'System.Windows.Controls.ScrollViewer' threw an exception.
```

**最内层异常（3 条独立栈里 `--->` 的终点同一枚）**：

```
System.Xaml.XamlObjectWriterException: Provide value on 'System.Windows.Markup.StaticResourceHolder' threw an exception.
 ---> System.NotImplementedException: The method or operation is not implemented.
   at System.Windows.Baml2006.Baml2006SchemaContext.ResolveBamlType(BamlType bamlType, Int16 typeId)
   at System.Windows.Baml2006.Baml2006SchemaContext.GetXamlType(Int16 typeId)
   at System.Windows.Baml2006.Baml2006SchemaContext.GetPropertyDeclaringType(Int16 propertyId)
   at System.Windows.Baml2006.Baml2006Reader.GetStaticExtensionValue(Int16 valueId, Type& memberType, Object& providedValue)
   at System.Windows.Baml2006.Baml2006Reader.Process_PropertyWithExtension()
   at System.Windows.Baml2006.Baml2006Reader.Process_OneBamlRecord()
   at System.Windows.Baml2006.Baml2006Reader.ReadObject(KeyRecord record)
   at System.Windows.ResourceDictionary.CreateObject(KeyRecord key)
   at System.Windows.ResourceDictionary.OnGettingValue(Object key, Object& value, Boolean& canCache)
   at System.Windows.ResourceDictionary.OnGettingValuePrivate(Object key, Object& value, Boolean& canCache)
   at System.Windows.ResourceDictionary.GetValueWithoutLock(Object key, Boolean& canCache)
   at System.Windows.ResourceDictionary.GetValue(Object key, Boolean& canCache)
   at System.Windows.DeferredThemeResourceReference.GetValue(BaseValueSourceInternal valueSource)
   at System.Windows.StaticResourceExtension.TryProvideValueImpl(…)
   at System.Windows.StaticResourceExtension.ProvideValue(IServiceProvider serviceProvider)
   at MS.Internal.Xaml.Runtime.ClrObjectRuntime.CallProvideValue(MarkupExtension me, IServiceProvider serviceProvider)
   --- End of inner exception stack trace ---
```

> ⚠️ **关键一跳**：栈上是 `SystemResources.LookupResourceInDictionary` → **`DeferredThemeResourceReference`** ⇒ 这是**主题资源字典**（themed dictionary）的延迟值，**不是** App 的 `{StaticResource}`。`GetStaticExtensionValue → GetPropertyDeclaringType → GetXamlType` 说明：正在解析的 BAML 里一条**属性**的**声明类型**解析不出来。

### §1.3 「内层异常没有名字」——这正是本任务要取的东西，问题也在这里

上游抛的是 **`throw new NotImplementedException();`（无参）** ⇒ 消息恒为 `"The method or operation is not implemented."`，**没有类型名、没有宿主程序集**；再被 `InitializationGuard` / `ProvideValue` **套三层** ⇒ 现场只剩 5 句不可读的 `XamlParseException`。**§3.3 的端口加固**就是把这个洞补上（`[BAML-TYPE-UNRESOLVED]`）。

---

## §2 ② 第一处断点与归因

### §2.1 第一处断点（件:行 ＋ 原文）

- 生成件（**本次修的目标件**）：`build/PresentationFramework.Linux/Baml2006SchemaContext.Linux.cs:558`
- 上游原样：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/System/Windows/Markup/Baml2006/Baml2006SchemaContext.cs`

```csharp
// :541  private XamlType ResolveBamlType(BamlType bamlType, Int16 typeId)
// :543      Type type = ResolveBamlTypeToType(bamlType);
// :544      if (type != null) { … return xType; }
// :558      throw new NotImplementedException();          ← 第一处断点
```

即：`ResolveBamlTypeToType`（`:526-539`，内部 `ResolveAssembly(bamlAssembly)` ＋ `assembly.GetType(bamlType.Name, false)`）返回 **`null`** ⇒ 落到 `:558`。

### §2.2 归因（本移植缺哪个面）

**缺的面 = 主题资源字典的"身份正确的那一枚件"**：`PresentationFramework.Classic`（`Version` 必须与 PF 一致）。逐条机械证：

```bash
# ① 栈内"五件"全是 4.0.0.1，唯独主题件是 10.0.0.0（用 AssemblyName.GetAssemblyName 逐件现取）
$ dotnet ~/tb7-work/verprobe/bin/Release/net10.0/verprobe.dll <appdir>/{PresentationFramework,PresentationCore,WindowsBase,System.Xaml}.dll
PresentationFramework.dll | PresentationFramework, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35
PresentationCore.dll   | PresentationCore,   Version=4.0.0.1, …
WindowsBase.dll        | WindowsBase,        Version=4.0.0.1, …
System.Xaml.dll        | System.Xaml,        Version=4.0.0.1, …
$ dotnet … verprobe.dll <appdir>/PresentationFramework.Classic.dll
PresentationFramework.Classic.dll | PresentationFramework.Classic, Version=10.0.0.0, …    ← 唯一一枚 10.0.0.0
```

- 这不是"某控件模板缺失"，也不是 `StaticResource` 解析器坏了 —— 栈上 `StaticResourceExtension.ProvideValue` **走到了**、`ResourceDictionary.CreateObject` **走到了**，**栽在 BAML 的类型解析**。
- 也不是 `PresentationUI` 的错：app-local `PresentationUI.dll` 现取 `4.0.0.1`（与栈一致）；`CycleStub.PresentationUI` 的 `PresentationUIStyleResources` 在册在位。
- **为什么会这样（可复算的世代链）**：`WIN-INTEROP §7.5 L2` 把身份抬到 `10.0.0.0`（`f7fce37`）⇒ 回退（`cd8e4bc`）⇒ "全量重建恢复"（`af685cf`）。重建把栈内件都拉回 `4.0.0.1`，**但主题件 `PresentationFramework.Classic` 不在任何构建/同步清单里**：
  ```bash
  $ grep -rln "PresentationFramework.Classic" build/*.sh build/MilBridge/tools/*.sh build/*.py   # 零命中
  $ ls build/PresentationFramework.Classic.Linux/bin/Release/   # 本次开工时为空（没被任何链重建）
  ```
  ⇒ app-local 里那枚 `10.0.0.0` 主题件（sha16 `9b5a2ab7189ca728`，mtime `10月2 14:13`，即 L2 波当时产的）**一直没被顶掉**。而 `run-hc.sh` 只同步**五件**（`sync-applocal.sh:ITEMS` 不含主题件）⇒ 它**永远**不会被修好。

### §2.3 为什么"版本不一致"会变成不可读的崩溃（机制，一步一证）

1. `SystemResources.LoadExternalAssembly`（`build/PresentationFramework.Linux/SystemResources.Linux.cs:778-825`）按 PF 的身份拼全名 `Assembly.Load("PresentationFramework.Classic, Version=4.0.0.1, PublicKeyToken=31bf…")`（`:804`）；
2. **.NET Core 的 `Assembly.Load` 对非框架程序集不强制版本** ⇒ 它**照单收下磁盘上那枚 `10.0.0.0`**（**不**抛 `FileNotFoundException`）。⚠️ 这正是主题件生成器自我契约要防的那一格（`build/PresentationFramework.Classic.Linux/reapply-patches.py` §E：「主题程序集必须能被 `Assembly.Load(…Version=<PF 的版本>…)` 命中，否则 … 会 `FileNotFoundException` 被静默吞掉」）——**在 .NET FX 上版本是强制的，在 .NET Core 上这条契约失效**；
3. 该件的 BAML 里类型记录写的是 `PresentationFramework.Classic, Version=10.0.0.0`，`assembly.GetType("Microsoft.Windows.Themes.ClassicBorderDecorator", false)`（类型**在件里确实存在**，`strings` 现取 4 命中）因**依赖绑定失败**返回 `null`；
4. ⇒ `ResolveBamlType` 抛**无参** `NotImplementedException` ⇒ 主题字典建不起来 ⇒ 5 条 `[HC-UNHANDLED]`。

> 「类型在件里存在、`GetType` 仍返回 `null`」这一格由 §3.3 的具名出口**直接读出来**（不靠推断）：`type='Microsoft.Windows.Themes.ClassicBorderDecorator' assemblyId=0 assembly='PresentationFramework.Classic, Version=10.0.0.0, …'`。

---

## §3 ③ 修 ＋ 帧面成对 ＋ 反极性

### §3.1 取证口径（复刻主控 `/tmp/hcv6.sh`；两极化都用**同一条**装置）

```bash
Xvfb :23D -screen 0 1280x1024x24 &   xfwm4 --display :23D &
DISPLAY=:23D bash ~/run-hc.sh --no-sync &     # 真 app-local（**不是**副本）
sleep 25 ; WID=$(xdotool search --name HandyControl | tail -1)
xdotool windowmap $WID                          # ← 主控口径：WPF 不 Show 时强映射，才能截到那 181 色
import -window root shot.png ; identify -format '%k' shot.png
```

> ⚠️ 口径对拍（**为什么量到 5 条而不是 3 条**）：不带 `windowmap` 时窗口 `IsUnMapped`，只出 **3** 条 `XamlParseException`；**`windowmap` 之后** WPF 继续处理消息，再补 **#4 `ResizeGrip` / #5 `ScrollViewer`** ⇒ **正好 5 条**，与主控现场一致。

### §3.2 帧面成对（真 app-local，逐格现取）

| 腿 | `sha16(PresentationFramework.Classic.dll)` | 版本 | `colors` | `[HC-UNHANDLED]` | 主窗 `Map State` | 截图 |
|---|---|---|---|---|---|---|
| **改前**（`real_before`, `:238`） | `9b5a2ab7189ca728` | `10.0.0.0` | **181** | **5** | `IsUnMapped` →(强映射) | `~/tb7-work/real_before/root.png` |
| **改后**（`real_after`, `:239`） | `77f3771872636b13` | `4.0.0.1` | **386** | **0** | `IsViewable` | `~/tb7-work/real_after/root.png` |

- 日志：`/tmp/hc-run-002709.log`（改前，5 条）↔ `/tmp/hc-run-002757.log`（改后，0 条）；副本 `~/tb7-work/{real_before,real_after}/app.log`（sha16 `5ffe4c6c3f952270` ↔ `122cdddf4a1e1292`）。
- **两独立样本逐格相同（现取）**：`real_after`（`:239`，`/tmp/hc-run-002757.log`）与 `real_after2`（`:241`，`/tmp/hc-run-003140.log`）⇒ `colors=386`／`unhandled=0`／`map=IsViewable` 全同，且两张 `root.png` 的 sha16 **逐字节相同** `b21eb530afd3c66c` ⇒ 帧面**确定性**。
- **"会话前"锚（可复算）**：主控 10月2 10:39 的已知良好帧 `/tmp/hcacc-shot1.png` 现取 **`colors=386`**，且**主色直方图逐项相同**（`#000000`/`#FFFFFF 203900`/`#EEEEEE 108382`/`#C18A75 17280`…）⇒ **改后帧 = 会话前良好帧的同一形态**。
- ⚠️ **如实划界（任务里的 `1275`）**：本机**取不到**任何 `colors=1275` 的截图或日志——现取搜法：`find /tmp ~/t204-captain -name '*.png' | while read f; do identify -format '%k' "$f"; done` **无 1275**；两份 `bridge-frozen.flag` 也只在十六进制串里"含 1275"（非读数）。**可复算的会话前良好值 = `386`**（`hcacc-shot1.png`）。这一格如实报 `NOINFO(reason=1275 无可复算载体)`。

### §3.3 修（两件，都是"外科手术式"）

**(甲) 帧面修（操作件，本任务的主要修法）**：用 HEAD 源重建主题件 ⇒ 回填 app-local。

```bash
# ① 重建（HEAD 源；本次实测 3.8 s，0 警 0 错）
bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- \
  timeout 1700 dotnet build build/PresentationFramework.Classic.Linux/PresentationFramework.Classic.Linux.csproj -c Release -m:1 --nologo
#    → build/PresentationFramework.Classic.Linux/bin/Release/PresentationFramework.Classic.dll
#      sha16=77f3771872636b13   AssemblyName=PresentationFramework.Classic, Version=4.0.0.1, PublicKeyToken=31bf3856ad364e35
# ② 回填 app-local（**写前 cp -p**；旧件已存 ~/tb7-work/applocal-Classic-STALE-10.0.0.0.dll.bak, sha16 9b5a2ab7189ca728）
cp -f build/PresentationFramework.Classic.Linux/bin/Release/PresentationFramework.Classic.dll \
      /home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0/
```

**(乙) 端口加固（`P8`：生成件走生成器）**：把 §2.1 那个断点做成**具名出口**。
- 改**生成器** `build/PresentationFramework.Linux/reapply-patches.py`（`CHAIN_FILES` ＋ `PATCH_C` 各 +1 条），由它产出**新生成件**
  `build/PresentationFramework.Linux/Baml2006SchemaContext.Linux.cs`（sha16 `651568e88e93d82b`），并在 csproj 里 `Compile Remove` 上游件 ＋ `Compile Include` 生成件。
- 改动**只补信息，不改语义**：仍抛 `NotImplementedException`（调用方逐字不动），但带上 **类型名 / 程序集 id / 程序集名**，并打一条**只读**诊断行：

```csharp
// build/PresentationFramework.Linux/Baml2006SchemaContext.Linux.cs:578-590（生成物，1 处 needle 改动）
string _wpfBamlAsm = null;
try { _wpfBamlAsm = GetAssemblyName(bamlType.AssemblyId); } catch (System.Exception) { _wpfBamlAsm = null; }
System.Console.Error.WriteLine(
    "[BAML-TYPE-UNRESOLVED] type='" + bamlType.Name + "'"
    + " assemblyId=" + bamlType.AssemblyId
    + " assembly='" + (_wpfBamlAsm ?? "<unknown>") + "'"
    + " —— 该类型在其 BAML 记录的宿主程序集里 GetType 取不到"
    + "（常见因：宿主件**版本/身份**与 BAML 记录不一致，或该类型未编入本移植）");
System.Console.Error.Flush();
throw new NotImplementedException(
    "BAML type not resolvable: '" + bamlType.Name + "'"
    + " (assemblyId=" + bamlType.AssemblyId + ", assembly='" + (_wpfBamlAsm ?? "<unknown>") + "')");
```

- 生成器幂等（现取）：连跑两次 ⇒ `Baml2006SchemaContext.Linux.cs` 与 csproj 的 sha16 **逐位不变**（`651568e88e93d82b`／`8f8ee3fd6138a5b9`）；needle 命中数不符即**报错退出**（不静默产出未打补丁的副本）。
- PF 重建：`48daaeb326c4aa8b`（6,160,896 B，`0 警 0 错`；`strings -el` 现取含 `[BAML-TYPE-UNRESOLVED]` ×1）。

> ⚠️ 这**不是"零假值"式的沉默降级**：它不吞异常、不改解析结果、不碰任何 `Invariant.Assert`；它做的正是本仓那条纪律「**失败不许静默**」。真正的修法是 (甲)；(乙) 是把"下一次同类失败"从**不可读**变成**一行点名**。

### §3.4 反极性（撤修 ⇒ 回 `181`）

把陈旧件放回（`cp -f ~/tb7-work/applocal-Classic-STALE-10.0.0.0.dll.bak <appdir>/`，sha16 回 `9b5a2ab7189ca728`），同一装置跑（`real_polarity`, `:240`）：

```
RESULT colors=181 unhandled=5 map_before=IsUnMapped map_after=IsViewable
[BAML-TYPE-UNRESOLVED] type='Microsoft.Windows.Themes.ClassicBorderDecorator' assemblyId=0
  assembly='PresentationFramework.Classic, Version=10.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35'
  —— 该类型在其 BAML 记录的宿主程序集里 GetType 取不到（常见因：宿主件**版本/身份**与 BAML 记录不一致，…）
```

⇒ **逐格回改前**（`181`／`5`／`IsUnMapped`），且 (乙) 的具名行**点名到了具体类型与宿主版本**。反极后已把正确件**再回填**（app-local 终态：Classic `77f3771872636b13` ＋ PF `48daaeb326c4aa8b`）。

---

## §4 ④ 门禁读数（逐条现取）

| 牙 | 命令 | 读数 |
|---|---|---|
| `HANDOFF_MV` | `bash build/MilBridge/tools/handoff-machine-values-check.sh` | **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`**，`rc=0` |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`rc=0` |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=354 ids=2265 declared=225`**，`rc=0` |
| `PTS_GAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42`**，`rc=0` |
| `SSC` | `bash build/MilBridge/tools/sentinel-spec-check.sh` | `rc=0`；**但 `SSC_VALUE=FAIL key=PF`**（见 §4.5） |
| `integration-wave` | — | **`NOINFO`（未跑）**（见 §4.6） |

### §4.5 `SSC` 的 `PF` 格为什么红（**本次重建的预期后果**，非回归）

```
SSC_VALUE=FAIL key=PF got=f9dc7b25feb17f16 want=48daaeb326c4aa8b path=…/bin/Release/PresentationFramework.dll
```

- 仓外哨兵（`/tmp/bridge-frozen.flag` ＝ `~/wfp-runs/bridge-frozen.flag`，`cmp IDENTICAL`）里写的是**冻结时点**的 `PF=f9dc7b25feb17f16`；本任务按 `P8` 改了 PF 源 ⇒ 重建后现盘 `PF=48daaeb326c4aa8b`。**任何改 PF 源的波都必然触发这一格**，重冻（写哨兵）是**波（主控）动作**、哨兵在**仓外**，本席不动。
- 其余 12 格 `SSC_VALUE=PASS`（`SHA`/`PC`/`WB`/`PROVIDER`/`WIN32SHIM`/`WIC`/`HBTL`/`DWF`/`FP`/`BASELINE`/`BASELINE_SHA16`/`WAVE`）＋ `SSC_KEYSET/CR/BLANK/EMPTY/CMP` 全 `PASS`。

### §4.6 `integration-wave`：`NOINFO(reason=主控独占动作，未授权)`

`build/integration-wave.sh` 件头是**结构约束**：**必须 `WAVE_OWNER=<名字>` 才运行**，否则直接退出并写 `build/wave-audit.log`；文中逐字「**波是主控独占动作**」。本席**未**跑它，故「`integration-wave` 失败步骤 0」这一格**本报告不给读数**（`NOINFO`，**不当绿**）。要收口，请在授权窗口由主控跑一趟（它会**同趟刷新哨兵** ⇒ §4.5 的 `PF` 格随之转绿）。

### §4.7 未动的相关件（说明"不回归"）

- `inputs_fp` **不受影响**：`build/close-wave.sh:210-213` 现取逐字把 `build/PresentationFramework.Linux/reapply-patches.py` 与 PF 的 `*.Linux.cs` 生成件登记为**不在 `fp_inputs()` 覆盖面内**的残留缺口 ⇒ 本波改它们**不动 `inputs_fp`**、不动 `FP-MANIFEST-TEETH`。
- `ARTIFACT-SRC-FP.txt`（PF/PC/WB）**保持 HEAD 原样**（`git checkout --` 复原）。理由：`python3 build/artifact-src-fp.py --check` 现取显示 PC/WB **本来就已经 `state=stale`（peer 漂移）**、PF **本来就已经 `state=noinfo`（缺 `ReachFramework` 被引产物）** ⇒ 刷新它们会把**与本次修无关**的存量漂移一并写进 diff（非外科手术式）；按惯例这一刷新是 `integration-wave [3.5]` 的动作（同上，主控独占）。

---

## §5 改动清单（逐件 ＋ `sha16` ＋ 复算命令）

| 件 | 性质 | 改前 | 改后 | 复算 |
|---|---|---|---|---|
| `build/PresentationFramework.Linux/reapply-patches.py` | 生成器（`P8`） | `18d8c6e8a1f66a46`（HEAD） | **`6ed1d80f1af1df8c`** | `git diff build/PresentationFramework.Linux/reapply-patches.py`（`CHAIN_FILES`/`PATCH_C` 各 +1 条） |
| `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` | 生成器产出 | `5b05e4fe2556f794`（HEAD） | **`8f8ee3fd6138a5b9`** | `python3 build/PresentationFramework.Linux/reapply-patches.py`（幂等，见 §3.3） |
| `build/PresentationFramework.Linux/Baml2006SchemaContext.Linux.cs` | **新建生成件** | — | **`651568e88e93d82b`** | 同上（由上游 `…/Baml2006SchemaContext.cs` ＋1 处 needle 改写） |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | 重建产物（**产品件**） | `f9dc7b25feb17f16` | **`48daaeb326c4aa8b`** | `dotnet build … -c Release`（0 警 0 错） |
| `build/PresentationFramework.Classic.Linux/bin/Release/PresentationFramework.Classic.dll` | 重建产物（主题件） | （bin 空） | **`77f3771872636b13`** | `dotnet build …Classic… -c Release` |
| `build/MilBridge/P1-hcdemo2-impl-report.md` | 载体（本文件） | — | — | — |

**app-local 回填（仓外 app 目录，两件；不是"改工程"，是"回填产物"）**：

```bash
APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0
# ① 五件（含新 PF）走仓内同步器
bash build/MilBridge/tools/sync-applocal.sh -q "$APP"      # → SYNC-APPLOCAL=PASS … PF f9dc7b25feb17f16→48daaeb326c4aa8b
# ② 主题件（**不在五件里**）手工回填
cp -f build/PresentationFramework.Classic.Linux/bin/Release/PresentationFramework.Classic.dll "$APP"/
# 回滚（撤修）：只需把旧件放回
#   cp -f ~/tb7-work/applocal-Classic-STALE-10.0.0.0.dll.bak "$APP"/PresentationFramework.Classic.dll
```

`git status`（现取，仅列本席产物；`?? build/MilBridge/tasks-tail2/T-B7.md` 是主控派单件，非本席所建）：

```
 M build/PresentationFramework.Linux/PresentationFramework.Linux.csproj
 M build/PresentationFramework.Linux/reapply-patches.py
?? build/PresentationFramework.Linux/Baml2006SchemaContext.Linux.cs
?? build/MilBridge/P1-hcdemo2-impl-report.md
?? build/MilBridge/tasks-tail2/T-B7.md
```

---

## §6 具名 `NOINFO` / 边界 / 具名前置

1. **`NOINFO(reason=1275 无可复算载体)`**：任务里的"会话前 `colors=1275`"本机**取不到任何载体**（现取扫遍 `/tmp`、`~/t204-captain` 下 `*.png` 无 1275；日志里的"1275"是十六进制串片段）。**可复算的会话前良好值 = `386`**（主控 `10月2 10:39` 的 `/tmp/hcacc-shot1.png`，与改后帧同色数同直方图）。本报告不替 1275 编来源。
2. **`NOINFO(reason=integration-wave 未跑)`**：主控独占动作（`WAVE_OWNER` 闸），未授权 ⇒ 该格不给读数（§4.6）。
3. **具名前置（真正的"系统性缺口"，**本席写域外**，如实划界）**：
   - **(a) 构建清单不含主题件**：`grep -rln "PresentationFramework.Classic" build/*.sh build/MilBridge/tools/*.sh build/*.py` **零命中** ⇒ `af685cf` 的"全量重建"**必然漏掉主题件**。**前置**：把 `PresentationFramework.Classic` 纳入整波重建序（落地位置＝`build/integration-wave.sh`，**不在本任务写域**）。
   - **(b) 同步集不含主题件**：`sync-applocal.sh:ITEMS` 只有**五件**（`libwpfwin32.so`/`wpfgfx_cor3.so`/`PC`/`PF`/`WB`）⇒ 即使主题件重建了，`run-hc.sh` **也不会**把它推到 app-local。**前置**：把主题件（及 `PresentationUI`/`System.Xaml` 等非五件）纳入同步集或在同步器里加一条"主题件 drift 即报"（落地位置＝`build/MilBridge/tools/sync-applocal.sh`，**黑名单件**）。
   - **(c) 身份契约在 .NET Core 上失效**：`PresentationFramework.Classic` 生成器 §E 的自我契约（"版本不命中 ⇒ `FileNotFoundException` 被吞"）**在 .NET Core 不成立**（版本不强制 ⇒ **静默收下错件**）。**前置（可选加固）**：在 `SystemResources.Linux.cs:778-825` 的 `LoadExternalAssembly` 里**回读 `AssemblyName` 并与请求身份比对**，不符即**具名拒绝**（`[THEME-IDENTITY-MISMATCH]` ＋ 当作未找到）。本席**未做**此项 —— 它会**改变失败形态**（从"5 条不可读异常 ＋ 181 色残 UI"变成"具名降级 ＋ 82 色无主题 UI"，**色数反而下降**），属**独立增量**，留裁。
4. **进程/显示收净**：本次所有 `Xvfb :231/:232/:238/:239/:240` 与其 `xfwm4` **已按 PID 收净**（现取 `ps` 零残留；`/tmp/.X11-unix/` 只剩 `X0/X1/X11`，即主控会话）。`~/tb7-work/` 只留证据（日志/截图/探针/备份件），**不在仓内**。
5. **副本先行/写前 `cp -p`（本席遵守）**：app-local 旧主题件 → `~/tb7-work/applocal-Classic-STALE-10.0.0.0.dll.bak`（`9b5a2ab7189ca728`）；csproj/reapply-patches → `~/tb7-work/{csproj,reapply-patches.py}.bak`（均在**任何写之前**取）。
