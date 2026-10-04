# W48D —— 修 `D-G56`（applier 把插桩横幅插进「属性块 ↔ 类声明」之间 ⇒ 属性挂错类 ⇒ BAML 页面 `NameScope` 挂不上根 ⇒ 点页签即 abort）

> 车道 `W48D`｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜**先等 `#47` 冻结**，再见血。
> **结论：修好了，且是产品级验证（aдversarial：反极性 + 关掉仪器两条腿）**。
> 位移**只有两位**：`windowsbase`、`pf`（`pc` 未重建 ⇒ 未变）。

---

## §0 一句话

两个 applier 的「插桩类本体」插入锚原本是**类声明行**，而 `EDITS` 的语义是「把文本拼在锚行**前面**」⇒ 横幅正好落在
**属性块与类声明之间** ⇒ `[NameScopeProperty]`/`[TypeDescriptionProvider]`/`[StyleTypedProperty]`/`[XmlLangProperty]`/
`[UsableDuringInitialization]` 归属**变成插桩类** ⇒ `DependencyObject` 属性数 **0**、`FrameworkElement` 三条也丢 ⇒
BAML 页面 `NameScope` 挂不到根 ⇒ `Storyboard.TargetName` 解析失败 ⇒ 进程 abort。
**修法 = 把锚上移到该类型自己的 doc 注释首两行**（`--prove` 证明仍是**纯插入**），并给两个 applier 各加**两条独立防复发判据**（跟 `--check` 一起跑）。

---

## §1 冻结标记：等到了（先等后动）

| 项 | 读数 |
|---|---|
| 起始现场 | `BASELINEGEN=PASS decl_gen=#46 file_newest_gen=#46`（23:03:04） |
| **出现时刻** | **2026-09-19 23:34:05**（第 **32** 次轮询） |
| 依据行（命令输出） | `BASELINESHA=PASS live=9b9e3cb7bcb8280b decl=9b9e3cb7bcb8280b` ／ **`BASELINEGEN=PASS decl_gen=#47 file_newest_gen=#47`** ／ `BASELINE_BYTES=553550` ／ `BASELINEDUP=PASS n=0`（`bash build/MilBridge/tools/baseline-sha-check.sh`，rc=0） |
| 依据行（文档） | `docs/CURRENT-STATE.md:9` 逐字：`> BASELINE-FROZEN gen=#47 sha16=9b9e3cb7bcb8280b file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| 等待期纪律 | 每 60 s 查一次（`$HOME/w48d-wait47.sh`，上限 60 次）；**等待期间零写仓、零重建、零 `dotnet`**，只做只读检查（读 applier/生成件/上游/`fp_inputs()` 口径）。轮询窗口内实测到 `#47` 收尾链在飞：`build/MilBridge/arm-logs/*.log` 23:07 被重取、`known-red.json` 变动、`FrameProbe`/`PcLineOracle` 各跑了一趟（23:25-23:33）。 |
| 超时 | 未触发（32 < 60）。 |

---

## §2 applier 改动逐处（`文件:行` ＋ before/after sha16 ＋ **为什么这么选锚**）

### 2.0 件 sha16（现场算）

| 件 | before | after | 行数 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py` | `1bff235f3d389788` | **`5203f958c234882f`** | 1144 → 1214 |
| `src/WpfGfx.Linux.Native/tools/patch-presentationframework-mirror-trace.py` | `a4e6599a8f0a9e75` | **`1b9852b037da70f1`** | 549 → 621 |

备份：`$HOME/w48d-backup/`（7 件：两个 applier ＋ 三个生成件 ＋ 两个 csproj，`cp -p` 原样）。

### 2.1 `patch-windowsbase-dpvalue-trace.py`（4 处）

**① `:55` 新增 `import re`**（判据要用正则；原先只 import `argparse/hashlib/os/sys`）。

**② `:631-644` 新增锚常量 `WB_TYPE_HEAD_ANCHOR`**（`:631-642` 是 12 行注释；原 `WB_CLASS_ANCHOR`（`:629`）**一字未动**，就地保留 —— 判据②还要用它）：
```
:643  WB_TYPE_HEAD_ANCHOR = ('    /// <summary>\n'
:644                         '    ///     DependencyObject is an object that participates in the property dependency system\n')
```
上游实测出现 **1** 次（`upstream/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/System/Windows/DependencyObject.cs`；同文件里 `    /// <summary>$` 有 55 处 ⇒ 必须连第二行一起锚，只锚 `<summary>` 会命中 55 次、被 `_build()` 的「要求 1」判死）。
带 15 行注释写清「为什么换锚」与「为什么不选追加到文件末尾」（见下 §2.3）。

**③ `:848-849` 改 W0 那条 edit 的锚**：
```
:848      ("W0 插桩类本体（**插在 doc 注释之前** ⇒ 属性块＋类声明保持紧贴，`D-G56`）",
:849       WB_TYPE_HEAD_ANCHOR, TRACE_CLASS + WB_TYPE_HEAD_ANCHOR),
```

**④ `:938-940`（两个正则 ＋ `WB_ATTR_MIN`）＋ `:943-968` 判据实现 `guard_wb()`（判据① 在 `:947-955`、判据② 在 `:956-967`）；`:1100-1109` 在 `_build()` 里接线**（紧跟 45 条 `REQUIRED` 结构断言之后 ⇒ `--check` 一定跑到）。

### 2.2 `patch-presentationframework-mirror-trace.py`（4 处）

**① `:36` 新增 `import re`**。
**② `:255-264` 新增 `FE_TYPE_HEAD_ANCHOR`**（`:255-262` 是 8 行注释；原 `FE_CLASS_ANCHOR`（`:253`）保留）：
```
:263  FE_TYPE_HEAD_ANCHOR = ('    /// <summary>\n'
:264                         '    ///     The base object for the Frameworks\n')
```
上游实测出现 **1** 次（`…/PresentationFramework/System/Windows/FrameworkElement.cs`）。
**③ `:295-296` 改 M0 那条 edit 的锚**。
**④ `:357-358`（两个正则）＋ `:360-364`（`TYPE_ATTR_FLOOR`）＋ `:366-395` `guard_relapse()`（判据① 在 `:370-379`、判据② 在 `:380-395`）；`:485-494` 在 `_build_one()` 里接线**（逐生成件跑 ⇒ `FrameworkElement.Linux.cs` 与 `TextBlock.Linux.cs` 都过）。

### 2.3 **为什么把锚上移到 doc 注释之前**（而不是「追加到文件末尾 ＋ 前向声明」）

任务是两选一，我选**上移锚**，三条理由：

1. **改动面最小、且零语义改动**：插入点从「类声明行前」挪到「类型 doc 注释首行前」，**插入的文本一个字节没变**，
   只是落点早了 27 行（WB）/ 11 行（PF）。`--prove` 仍能机械证明「摘掉插桩 ⇒ 与上游**逐字节相同**」（§3.4）。
2. **追加到末尾会破坏两处调用点**：`TRACE_CLASS` 声明在 `namespace System.Windows` **内**，而调用点是
   `WpfLinuxDpValueTrace.W1GetValue(this, dp)`（**非全限定**，WB 批）与 `System.Windows.WpfLinuxMirrorTrace.M6OnRender(this)`
   （**全限定**，PF 的 `TextBlock.Linux.cs` 那一路）。挪出 namespace 就得改调用点或新增别名 ——
   那等于**再造一处"同一个名字的第二份声明"**（本仓反复登记的那一族坑）。
3. **「属性块 ＋ 类声明」在源码顺序上紧贴，且 doc 注释也一起紧贴**：上游原本就是
   「doc 注释 → 属性块 → 类声明」三段连排；把插桩类插在**整段之前**，三段**逐字保持上游形状**（§5 判据①原文），
   而不是「只把属性迁走、doc 注释仍被横幅分尸」。⚠️ 本仓**另外三处**同族插入（`Dispatcher.Linux.cs:30-42`、
   `TextEditorTyping.Linux.cs:34-45`、`TextContainer.Linux.cs:112-129`）**只分尸了 `///`/`//` 注释、没分尸属性行**
   ⇒ **没有功能后果**（我做了 48 个生成件的全树普查，见 §7 R-W48D-3），本波按「只修有功能后果的两处」处理。

---

## §3 防复发判据（逐条 ＋ **如何两极化证明它能红**）

### 3.1 判据定义（两个 applier 各两条，**互相独立**）

| # | applier | 判据 | 定义 | 修前 | 修后 |
|---|---|---|---|---|---|
| ① | WB `guard_wb` `:947-955` | **属性行与类声明之间不得出现插入横幅** | 文件名级：**任何**一行匹配 `^\s*\[[^\]]*\]\s*$` 的属性行，其**下一个非空行**都不许匹配 `^\s*//\s*(T1c\b|=+\s*$)` | **红**（`:52 [NameScopeProperty…]` 的下一非空行是 `:53 // =====`） | 绿（0 命中） |
| ② | WB `guard_wb` `:956-967` | **`DependencyObject` 的紧贴属性行 ≥ 2** | 类级：自 `    public class DependencyObject : DispatcherObject` 向上数**连续**属性行条数 | **0** ⇒ **红** | **2** ⇒ 绿 |
| ① | PF `guard_relapse` `:370-379` | 同 ①（文件级） | 同上 | **红**（`FrameworkElement.Linux.cs:103 [UsableDuringInitialization(true)]` 的下一非空行是 `:104 // =====`） | 绿 |
| ② | PF `guard_relapse` `:380-395` | 该生成件里**被插类的类型**其紧贴属性行 ≥ 下限（`TYPE_ATTR_FLOOR` `:360-364`：FE=3；`TextBlock.Linux.cs` = `None`＝本件不插类） | 同 WB ② | **0** ⇒ **红** | **3** ⇒ 绿 |

**为什么两条都要（不是重复）**：① 抓的是「**任何人**（不限于本批锚点）又把横幅插进某个属性块中间」——**形状**判据；
② 抓的是「**本类型的属性真的回到了类身上**」——**内容**判据。伪造/退化方式不同 ⇒ 单靠一条有盲区
（例：把横幅插到 doc 注释之前、却顺手把属性行搬走 ⇒ ① 绿而 ② 红）。

### 3.2 两极化证明（**实测**，脚本 `$HOME/w48d-tools/polarity.py`，只读、不写仓）

负极 = `$HOME/w48d-backup/` 里的**修前生成件快照**；正极 = 用**修后 applier** 在内存里现算的生成物（`_build()` / `_build_all()`）。
**同一份判据代码、同一函数、只换输入**：

```
WB   NEG(修前落盘件): fails=2 紧贴属性行=0
   * 判据① 属性行与类声明之间出现插入横幅：生成件 :52 '[System.Windows.Markup.NameScopeProperty("NameSc' ⇒ 下一非空行 :53 是 '// ============================='
   * 判据② `DependencyObject` 的紧贴属性行 = 0 < 2（属性块被顶走了？）
WB   POS(修后现算件): fails=0 紧贴属性行=2
PF FrameworkElement.Linux.cs NEG: fails=2 紧贴属性行=0
   * 判据① …：FrameworkElement.Linux.cs :103 '[UsableDuringInitialization(true)]' ⇒ 下一非空行 :104 是 '// ============================='
   * 判据② … 的 `FrameworkElement` 紧贴属性行 = 0 < 3（属性块被顶走了？）
PF FrameworkElement.Linux.cs POS: fails=0 紧贴属性行=3
PF TextBlock.Linux.cs         NEG: fails=0   POS: fails=0      ← 阴性对照（本件不插类 ⇒ 判据②不适用、判据① 0 命中）
```
⇒ **四条判据每条都实测过「能红」与「能绿」**；`TextBlock.Linux.cs` 那两行是**阴性对照**（证明判据不是恒红）。

### 3.3 判据跟随 `--check`（不是"写了不跑"）

| 命令 | 期望 | 实测 |
|---|---|---|
| `patch-windowsbase-dpvalue-trace.py --check`（生成件**过时**时） | rc=1 | **rc=1**，末行 `[检查] 生成物过时（需要重新生成）⇒ rc=1`；同时打出 `[断言] `D-G56` 防复发判据：① …✓；② DependencyObject 紧贴属性行 = 2（要求 ≥ 2）✓` ⇒ **判据确实在 `--check` 路径里** |
| `patch-presentationframework-mirror-trace.py --check`（过时） | rc=1 | **rc=1**，`[检查] 生成物过时（需要重新生成）：FrameworkElement.Linux.cs ⇒ rc=1` |
| 重新生成后 `--check`（两件） | rc=0 | **WB rc=0 / PF rc=0** |
| `bash build/check-appliers.sh` | `miss=0 red=0` | **`APPLIER_AUDIT_SUMMARY appliers=25 ok=86 miss=0 red=0 rc=0`** |
| `bash build/check-appliers.sh --with-check` | `miss=0 red=0` | **`APPLIER_AUDIT_SUMMARY appliers=25 ok=111 miss=0 red=0 rc=0`** |

### 3.4 「只插入」机械证明（`--prove`，rc 均为 0）

```
[① 只插入] 取自 落盘生成物 build/WindowsBase.Linux/DependencyObject.Linux.cs
[① 只插入] 逆序回代后与上游**逐字节相同** ✓ sha256=edeb712d0bc7b433…（== 上游 edeb712d0bc7b433…）   WB_PROVE rc=0
[① 只插入] FrameworkElement.Linux.cs：… 逐字节相同 ✓ sha256=ea0b294cbad69b3d…（== 上游 ea0b294cbad69b3d…）
[① 只插入] TextBlock.Linux.cs：… 逐字节相同 ✓ sha256=27203a206ec3bbf0…（== 上游 27203a206ec3bbf0…）   PF_PROVE rc=0
```
⇒ 换锚**没有**顺手改上游一个字节（把插桩全摘掉就还原成上游）。

---

## §4 重建（`dotnet -m:1` / `DOTNET_gcServer=0` / `SELFBUILT_CONFIG=Release`）

| 工程 | 命令 | rc | 用时 | 产物 before → after | 字节 |
|---|---|---|---|---|---|
| `build/WindowsBase.Linux` | `dotnet build … /WindowsBase.Linux.csproj -c Release -m:1 --nologo -v q` | **0**（0 警告 0 错误） | 13.7 s | `84a2826c471e60ea` → **`79740e9ba7fbf9ca`** | 1111552 → 1111552 |
| `build/PresentationFramework.Linux` | 同上（PF csproj） | **0**（0 警告 0 错误） | 55.5 s | `366e9486536bc291` → **`bd73f9e2376d67ac`** | 6119424 → 6119424 |

**生成件 before → after**：

| 生成件 | before | after | 字节 |
|---|---|---|---|
| `build/WindowsBase.Linux/DependencyObject.Linux.cs` | `cdd5867fc742ffee` | **`2985c671c57c7775`** | 184597（不变） |
| `build/PresentationFramework.Linux/FrameworkElement.Linux.cs` | `61a5f1e45e6017fb` | **`3af06981155e89aa`** | 292005（不变） |
| `build/PresentationFramework.Linux/TextBlock.Linux.cs` | `6067276d0fc3a8da` | `6067276d0fc3a8da`（**未重写**，两路都没插类） | 180552 |

**资源纪律**：`MemAvailable` 建前 2465/2281 MB、建后 2271/1545 MB（全程 > 1500）；`nproc=3`；构建前先等别的车道那趟
`PcLineOracle` 跑完（`pgrep -a dotnet` 连查 16 次 × 30 s，第 16 次 `active_runners=0`）；**零 `pkill`**、未取别人 PID。

### 4.1 九位现算（口径 = `build/close-wave.sh` 的 `[6/6]` 汇总块 ＋ `fp_inputs()`；脚本 `$HOME/w48d-tools/nine.sh`）

**先验证了"我这把尺子准不准"**：把它跑在**改动之前**的树上，得 `inputs_fp=8a8661b926e47489b9840736992209d3977ab10429e42dcdcbe9df1a5a0ddeaf`，
与 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 里 `#47` 冻块逐字声明的 `8a8661b926…ddeaf` **逐位相同** ⇒ 尺子可信，再量。

| 位 | `#47` 冻结值 | **W48D 后** | 变？ |
|---|---|---|---|
| `bridge` | `e3ea092010734f44` | `e3ea092010734f44`（5019968 B） | 未变 |
| `pc` | `043eff4b1d8ecd7d` | `043eff4b1d8ecd7d`（3601408 B） | 未变（**未重建**） |
| **`pf`** | `366e9486536bc291` | **`bd73f9e2376d67ac`**（6119424 B） | **变** |
| **`windowsbase`** | `84a2826c471e60ea` | **`79740e9ba7fbf9ca`**（1111552 B） | **变** |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | 未变 |
| `win32shim` | `abf6879c027c5e73` | `abf6879c027c5e73` | 未变 |
| `wic_shim` | `56278c14b4ecd672` | `56278c14b4ecd672` | 未变 |
| `hbtextline` | `e89fed55fd8e32bc` | `e89fed55fd8e32bc` | 未变 |
| `dwf` | `de2d555105b7d04b` | `de2d555105b7d04b` | 未变 |

* `inputs_fp`：`8a8661b926e47489b9840736992209d3977ab10429e42dcdcbe9df1a5a0ddeaf` → **`b983d9bee6c36b5e88dd1a3587d8724c3680479e521cb5c1531c0fc1b868c9bf`**。
  **可归因**：`fp_inputs()` 的 `find src/WpfGfx.Linux.Native/tools build \( -maxdepth 2 -name 'patch-*.py' … \)` 那一支
  **点名包含我改的两个 applier**（`close-wave.sh:179-187` 的覆盖面）⇒ 改它们**必然**移动 `inputs_fp`（设计使然）。
* **位移恰好 = 我改的两处**：`windowsbase`／`pf` 就是两个 applier 各自产出生成件的那个工程。**没有表外位移**：
  `bridge` 源未动且 AOT 可复现 ⇒ 未变；`provider`/`win32shim`/`wic_shim`/`hbtextline`/`dwf` 未碰。
* ⚠️ **`pc` 未重建**（任务口径：PC 不引用被改的这两个生成件 ⇒ 非「必要」）。副作用一条，如实报：
  `build/PresentationCore.Linux/bin/Release/WindowsBase.dll` 副本仍是**旧** `84a2826c471e60ea`
  （WB/PF 两侧已自动刷新为 `79740e9b`）。**没有任何脚本/判据件把它当权威读**，两条现场读数：
  `grep -rn --include=*.sh --include=*.py --include=*.cs -- 'PresentationCore.Linux/bin/[A-Za-z]*/WindowsBase' build/ src/` = **0 命中**；
  去掉 `--include` 的**全类型** grep 有 6 命中，逐条归因 = **我自己这份报告 3 行** ＋ `build/PresentationCore.Linux/obj/{Release,Debug}/…csproj.FileListAbsolute.txt`（MSBuild 的产物清单，不是读者）。
  ⇒ **不构成判据**；主控整波重建（`integration-wave.sh`）时会自动刷新。

---

## §5 三条判据的读数原文（含**反极性**的 `alive`／异常行对比）

装置：私有 app 目录 ＋ 私有 Xvfb（`:64`/`:66`）＋ **每趟现场 `sha256sum`**；
**A/B 只差两个件**（同一份 hc 应用、同一份 shim/bridge/pc）：

| 件 | BEFORE（`#47` 冻结件）| AFTER（本波重建件）|
|---|---|---|
| `PresentationCore.dll` | `043eff4b1d8ecd7d` | `043eff4b1d8ecd7d`（相同）|
| **`PresentationFramework.dll`** | `366e9486536bc291` | **`bd73f9e2376d67ac`** |
| **`WindowsBase.dll`** | `84a2826c471e60ea` | **`79740e9ba7fbf9ca`** |
| `System.Xaml.dll` | `53a526ba16578bf6` | 相同 |
| `libwpfwin32.so`（`#47` 新权威）| `abf6879c027c5e73` | 相同 |
| `wpfgfx_cor3.so` | `e3ea092010734f44` | 相同 |
| `HandyControlDemo.dll` | `833630857e2fbc5d` | 相同 |

### 判据① 生成件里「属性块 ＋ 类声明」紧贴（`sed -n` 原文）

`build/WindowsBase.Linux/DependencyObject.Linux.cs`（插桩类现落在 **:35**，实体 35–583，然后 doc 注释 585 起）：
```
 584
 585      /// <summary>
 586      ///     DependencyObject is an object that participates in the property dependency system
 587      /// </summary>
 …（doc 注释延续，与上游 :12-38 逐字相同）…
 609      /// </remarks>
 610      /// This attribute allows designers looking at metadata through TypeDescriptor to see dependency properties
 611      /// and attached properties.
 612      [System.ComponentModel.TypeDescriptionProvider(typeof(MS.Internal.ComponentModel.DependencyObjectProvider))]
 613      [System.Windows.Markup.NameScopeProperty("NameScope", typeof(System.Windows.NameScope))]
 614      public class DependencyObject : DispatcherObject
```
（上游对照 `upstream/…/WindowsBase/System/Windows/DependencyObject.cs:39-41` 是同一形状：属性 39/40、类声明 41。修前是
`:51-52 属性 → :53-63 横幅 → :64 插桩类 → :614 类声明`。）

`build/PresentationFramework.Linux/FrameworkElement.Linux.cs`（插桩类落在 **:101**、实体止于 306 之前）：
```
 302      /// </remarks>
 303      [StyleTypedProperty(Property = "FocusVisualStyle", StyleTargetType = typeof(Control))]
 304      [XmlLangProperty("Language")]
 305      [UsableDuringInitialization(true)]
 306      public partial class FrameworkElement : UIElement, IFrameworkInputElement, ISupportInitialize, IHaveResources, IQueryAmbient
```

### 判据② 运行期读数（`HC_INPUT_DIAG=1`，应用自报）

| 读数行 | **BEFORE**（`$HOME/w48d-run/BEFORE/app.log`） | **AFTER**（`$HOME/w48d-run/AFTER/app.log`） |
|---|---|---|
| `[NS] ATTRCOUNT` | `DependencyObject=0 FrameworkElement=1 Control=0 TextBlock=2` | **`DependencyObject=2 FrameworkElement=4 Control=0 TextBlock=2`** |
| `[NS] ASSM …` | `attrCount=0 nameScopeHits=none nonInherit=False` | **`attrCount=2 nameScopeHits= HIT:System.Xaml nonInherit=True`** |
| `[NS] CHAIN` | `attrOnDependencyObject=False attrOnRootType=False dpField=True dpNull=False dpOwner=NameScope dpName=NameScope attachableMember=NameScope` | **`attrOnDependencyObject=True attrOnRootType=True`** ＋ 其余逐字相同 |
| `[NS] WINDOW` | `HandyControlDemo.MainWindow scope=null FindName(ControlMain)=null` | **`… scope=NameScope FindName(ControlMain)=ContentControl`** |
| `[NS] loaded …GeometryAnimationDemo` | `scope=null isINS=False contentScope=null upHits=none FindName(PathDemo)=null` | **`scope=NameScope … upHits= UP0=GeometryAnimationDemo FindName(PathDemo)=Path`** |

⇒ 判据② 三条（`ATTRCOUNT ≥ 2` ∧ `scope` 非 null ∧ `FindName(ControlMain)` 非 null）**逐条成立**（修前逐条不成立）。
注意 `dpField/dpOwner/attachableMember` 修前修后**都对** —— 与 W47A 的判定点吻合：断链**只在属性归属那一格**。

### 判据③ **反极性**：点「工具」页签 → 点第 2 项 `MorphingAnimation`，进程必须活着

同一驱动（`$HOME/w48d/run.sh`，`W48D_PHASE=Q6`；坐标全来自应用自报的 `[GEO]`，页签取屏幕 x 最大者 = 「工具」）：

**BEFORE**（`$HOME/w48d-run/BEFORE/`，sha16 见 §5 表）：
```
── [tools#1-MorphingAnimation] 点 ListBox#ListBoxDemo 的项 #1 @(429 435) mode=hold150
   before: focus=SearchBar … LB(ListBoxDemo sel=0/3)
   !!! APP DIED
   !! Unhandled exception. System.InvalidOperationException: 'PathDemo' name cannot be found in the name scope of 'HandyControlDemo.UserControl.GeometryAnimationDemo'.
   !!    at …Storyboard.ResolveTargetName(…) …/Storyboard.cs:line 276
   !!    at …BeginStoryboard.Invoke(…)     …/BeginStoryboard.cs:line 197
   !!    at System.Windows.FrameworkElement.OnLoaded(…)  build/PresentationFramework.Linux/FrameworkElement.Linux.cs:5989
   alive=no
```
**AFTER**（`$HOME/w48d-run/AFTER/`）：
```
── [tools#1-MorphingAnimation] 点 ListBox#ListBoxDemo 的项 #1 @(429 435) mode=hold150
   before: focus=SearchBar … LB(ListBoxDemo sel=0/3)
   after : focus=ListBoxItem TB(- len=0,caret=0,focus=False) TG(off) LB(ListBoxDemo sel=1/3)
   | [KEY_DIAG] BTN type=Press   … state=0x0   time=89751202 xy=129,210
   | EV LB.SelectionChanged ListBox#ListBoxDemo sel=1/3 added=1
   | [KEY_DIAG] BTN type=Release … state=0x100 time=89751360 xy=129,210
   alive=yes
   [NS] loaded HandyControlDemo.UserControl.GeometryAnimationDemo scope=NameScope … FindName(PathDemo)=Path
```
⇒ **判据③ 成立**（修前 `alive=no` ＋ `name cannot be found`；修后 `alive=yes`、零异常、名字解析成功）。

### 判据③的**第二条腿**：把 hc 侧仪器整个关掉，仍是同一结论（**产品级**）

⚠️ 这一腿是必须的 —— 因为开仪器时我撞到了**仪器自己**的崩溃（见 §6），必须先证明那不是产品。
脚本 `$HOME/w48d-tools/tools3-nodiag.sh`：**不设 `HC_INPUT_DIAG`**（`=hc_input_diag '<unset>'`）、
坐标用上一趟应用自报的 `[GEO]` 复放（布局确定：同一份件、同一窗口几何 `800x600+300+225`），
并对每步做 `xwd`/`compare` 帧差（证明确实换了页）：

```
BEFORE ARTS pc=043eff4b1d8ecd7d pf=366e9486536bc291 wb=84a2826c471e60ea shim=abf6879c027c5e73 bridge=e3ea092010734f44
BEFORE step=t0 点「工具」页签 (510,331)        alive=yes AE(s0,s1)=238109
BEFORE step=tools#0(HatchBrushGenerator) alive=yes AE(s1,s2)=6541
BEFORE step=tools#1(MorphingAnimation)   alive=no  AE(s2,s3)=480000
BEFORE   Unhandled exception. System.InvalidOperationException: 'PathDemo' name cannot be found in the name scope of 'HandyControlDemo.UserControl.GeometryAnimationDemo'.
BEFORE FINAL alive=no unhandled_lines=1

AFTER  ARTS pc=043eff4b1d8ecd7d pf=bd73f9e2376d67ac wb=79740e9ba7fbf9ca shim=abf6879c027c5e73 bridge=e3ea092010734f44
AFTER  step=t0 点「工具」页签 (510,331)        alive=yes AE(s0,s1)=238109
AFTER  step=tools#0(HatchBrushGenerator) alive=yes AE(s1,s2)=6541
AFTER  step=tools#1(MorphingAnimation)   alive=yes AE(s2,s3)=39765     ← **判据③，产品级、无仪器**
AFTER  step=tools#2(Effects)             alive=no  AE(s3,s4)=480000
AFTER    Unhandled exception. System.NotImplementedException … at System.Windows.Media.MediaContext.CommitChannel() MediaContext.cs:line 2151
```
⇒ ① **`D-G56` 的产品级反极性成立**：关掉仪器后，修前在 `tools#1` 死、修后**活着**；
② 顺带暴露**第三条无关缺陷**（`tools#2`），见 §7 R-W48D-2；
③ `AE(s0,s1)=238109` / `AE(s1,s2)=6541` 两趟**逐位相同**（BEFORE≡AFTER）⇒ 两条腿的点击确实落在同一处、同一个页面上。

---

## §6 我自己踩的仪器自伤（如实，两条）

**自伤①（我的驱动脚本 → 一次**作废**的读数）**：给 `Q6c` 相位（Tools 页 3 项逐项点）写脚本时**漏了 `geoblock`**，
于是 `lastgeo.txt` 不存在 ⇒ `tab3` 为空 ⇒ `[ -s ]` 判假 ⇒ **页签那一下根本没点**。而脚本照样往下跑、
照样打印 `alive=yes`，读到的其实是**「样式」页**（`LB(sel=0/31)`）的头 3 项 —— 与 Tools 页无关。
**处置**：该趟（`$HOME/w48d-run/AFTER-TOOLS3/`，1056 行）**整份作废、不当作判据**；修好（加 `geoblock` ＋ 行内注释留痕）后重跑。
**教训与 §5 判据③的教训同源**：`alive=yes` 这种读数**不告诉你"点到哪儿了"** ⇒ 必须与"页面确实换了"（`AE`／`[NS] loaded …GeometryAnimationDemo`）**成对**读。

**自伤②（不是我的代码，但**是我这趟撞出来的**，且会误导后来人）**：hc 侧只读仪器 `App.xaml.cs:284` 的 `Describe()`
在**向上走命中链**时对 `e.OriginalSource` 调 `System.Windows.Media.VisualTreeHelper.GetParent(cur)`；
而 `OriginalSource` 可以是 `System.Windows.Documents.Run`（`FrameworkContentElement`）⇒ 上游按**设计**抛
`InvalidOperationException: '…Run' is not a Visual or Visual3D.`（`VisualTreeHelper.cs:124` → `VisualTreeUtils.AsNonNullVisual`）
⇒ 挂在 `UIElement.MouseUpEvent` 的**类处理器**里、无人接 ⇒ **未处理异常 ⇒ 进程死**。
**归属**：这是**仪器缺陷**，**不是产品缺陷**，也**不是我的改动引起的** —— 三条证据：
① 只在 `HC_INPUT_DIAG=1` 时才装那个 handler，关掉仪器后 `tools#0` 完好（§5 第二条腿，两趟 `alive=yes`、`AE=6541`）；
② 栈顶落在 `HandyControlDemo.App.Describe`（hc 侧、仓外件），不在产品里；
③ 抛的是**上游自己**的 `VisualTreeHelper` 契约（`upstream/…/Media/VisualTreeHelper.cs:116-128` 调 `AsNonNullVisual`）。
**为什么"现在才出现"**：修前点 Tools 页会在第 1 项就死于 `D-G56`，这条**一直被更早的崩溃盖住** ⇒ §5 第二条腿（关仪器）是把它与产品分开的**唯一**办法。
**我没有修它**：文件 `/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/App.xaml.cs` **不在本车道写域**
（只许改 applier 与其生成件）。**建议修法一句**：`Describe()` 的向上循环里把 `GetParent` 包进 `try/catch`
（或在进入循环前判 `cur is Visual`，非 Visual 时改走 `ContentOperations.GetParent`/`LogicalTreeHelper` 那一支） —— 纯仪器改动、零产品影响。
另：`W47A-report.md` 的 §8 自伤清单里**没有**记这条（`grep -n 'Run\|is not a Visual' build/MilBridge/W47A-report.md` = 0 命中）⇒ 属**新登记**。

**自伤③（我自己落下的仓内副产物，如实记）**：为了语法自检跑了
`python3 -m py_compile src/WpfGfx.Linux.Native/tools/patch-{windowsbase-dpvalue,presentationframework-mirror}-trace.py`
⇒ 在**已有的** `src/WpfGfx.Linux.Native/tools/__pycache__/`（该目录先前就有 20+ 份 `.pyc`，最早 00:14）里新增/更新了对应的两个 `.pyc`。
**为什么无害**：`close-wave.sh` 的 `fp_inputs()` 覆盖面的模式是 `-name 'patch-*.py'`，**不匹配 `.pyc`**
（`ARTIFACT-SRC-FP` 同口径）⇒ **不动 `inputs_fp`**；且它们是纯字节码缓存、任何导入都会重建。**处置：保留不删**
（删掉反而会动一个先前就存在的目录里我无法确定是否原本存在的那两份）。

**本轮我在仓内的全部足迹**（`find … -newermt '2026-09-19 23:34' | grep -v obj/bin`，逐条）：
`build/MilBridge/W48D-report.md`、`build/WindowsBase.Linux/DependencyObject.Linux.cs`、`build/PresentationFramework.Linux/FrameworkElement.Linux.cs`、
`src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py`、`…/patch-presentationframework-mirror-trace.py`、
`…/__pycache__/{上述两件}.cpython-310.pyc`。
**写域外零触碰的机器证据**：`verify-all.sh`(22:49)、`build/close-wave.sh`(11:03)、`build/integration-wave.sh`(20:11)、
`build/MilBridge/known-red.json`(23:11)、`build/MilBridge/arm-logs/*`(23:07–23:11) 的 mtime **全部早于 23:34**（=`#47` 收尾动作，不是我）；
`find samples -newermt '2026-09-19 23:34' -type f | grep -v '/obj/\|/bin/'` = **空**。
（其余 >23:34 的件如 `docs/WAVE4[78]-PREREGISTRATION.md`、`handoff.md`、`build/MilBridge/W48A-report.md`、`tests/artifacts/rendering/*.png` 是**别的车道**的。）

---

## §7 `NOINFO` 与附带发现（逐条，**不许当绿**）

* **R-W48D-1（`NOINFO`）`D-G56` 撤登记判据③的「3 项逐项点」，只完成 2/3**：
  `HatchBrushGenerator`（#0）与 `MorphingAnimation`（#1）**实测通过**（产品级、无仪器，`alive=yes`）；
  `Effects`（#2）**取不到判据** —— 它死于**另一条**缺陷（R-W48D-2），与 `NameScope` 无关。
  ⇒ 若主控要按 `W47A-report.md:261` 的判据③「3 项逐项点一遍」**整条撤登记**，则第 3 项那格**只能是 `NOINFO`**，
  **不能读成绿**（但也**不是** `D-G56` 复发：异常类型、栈、判定点全不同）。
* **R-W48D-2（新缺陷，未修，建议登记 `D-G58`）**：Tools 页第 3 项 `Effects`（`EffectsDemo.xaml` 带
  `Loaded` ＋ `Storyboard.TargetName`，与 `D-G56` 同形）⇒
  `Unhandled exception System.NotImplementedException: The method or operation is not implemented.`
  栈顶 `System.Windows.Media.MediaContext.CommitChannel()` ← `…/upstream/…/Media/MediaContext.cs:2151` 的 **`Channel.Commit();`**。
  **判定点（已定位到行，但"哪条 MilCmd"= `NOINFO`）**：抛出的 `NotImplementedException` **不是**任何 C# 里的
  `throw new NotImplementedException()`（`grep -rn 'NotImplementedException' build/*.Linux/ build/shims/ src/WpfGfx.Linux/` 只命中两处**注释**：
  `src/WpfGfx.Linux/Interop/MilNative.NotificationWindow.cs:14` 与 `Interop/MilNative.cs:405`，两处都在解释
  「native 返回一次失败 ⇒ PresentationCore 的 `HRESULT.Check` 就抛 `NotImplementedException`」）；
  而 `MilChannel.Commit()`（`src/WpfGfx.Linux/Resources/MilChannel.cs:241-263`）**返回批里第一个失败的 HRESULT**，
  并把 `E_NOTIMPL` 逐条记进 `NotImplRegistry`/`NotImplCommands`（`:266-274`）。
  ⇒ **决策点 = 批里哪一条 `MilCmd` 返回了 `E_NOTIMPL`**；取该读数需要桥的诊断汇
  （`MilPresentation.DiagnosticSinkEnabled`，`:247` 那道预检门）—— **本趟未取到 ⇒ `NOINFO`**（读到命令号即可精确定位、并可能直接对照 `NotImplRegistry` 的既有台账）。
  **机制假说（标为假说）**：修前该页的 `Storyboard` 因名字域为 null **根本没起来**；修后它**真的开始播动画** ⇒
  第一次走到「动画帧提交」这条渲染路径 ⇒ 撞上产品尚未实现的命令。**未做**"只回退名字域、其余不动"的对照实验。
* **R-W48D-3（44 行普查，`NOINFO` 之外的顺带结论）**：我把「横幅夹在属性行与类型声明之间」这个**形状**在
  **`build/*.Linux/*.cs` 全 48 个生成件**上机器扫了一遍（脚本见 §3.2 同族逻辑）⇒ **命中恰好 2 处**，就是本波修的两处；
  另有 **3 处同族但只分尸注释、不分尸属性**（`PresentationFramework.Linux/TextContainer.Linux.cs:112-129`、
  `PresentationFramework.Linux/TextEditorTyping.Linux.cs:34-45`、`WindowsBase.Linux/Dispatcher.Linux.cs:30-42`）
  ⇒ 判据① 对它们是**绿的**（属性块没被碰），本波**不动**、仅登记。
* **R-W48D-4（`NOINFO`，不是我这一格但会挡住波尾）**：`python3 build/artifact-src-fp.py --check` 现在 **rc=2**：
  `proj=WindowsBase … state=stale note=kind=src`、`proj=PresentationFramework … state=stale note=kind=src`
  （`proj=PresentationCore … state=ok`）。**这不是"源改了没重建"** —— 我**确实**重建了，而是那份**记录文件**
  （`build/<Proj>.Linux/ARTIFACT-SRC-FP.txt`，记录里仍是旧值 `file=cdd5867fc742ffee build/WindowsBase.Linux/DependencyObject.Linux.cs`、
  `file=1bff235f3d389788 src/…/patch-windowsbase-dpvalue-trace.py`）**由波脚本写**：唯一写者是 `build/integration-wave.sh:457-458` 的
  `python3 build/artifact-src-fp.py --write`，而**本车道被明令禁止跑 `integration-wave`** ⇒ **我没有写它**。
  `verify-all.sh` **不读**该指纹（`grep -n 'artifact-src-fp' verify-all.sh` = 0 命中）；只有 `build/close-wave.sh:306`
  的 `[4/6]` 会读 ⇒ **主控整波重建时它会自动收敛为 ok**（刷新记录即可，无需改判据）。
* **R-W48D-5**：`build/PresentationCore.Linux/bin/Release/WindowsBase.dll` 是**陈旧副本**（`84a2826c471e60ea`，权威已 `79740e9b`）。
  见 §4.1 脚注的两条现场 grep：**没有任何脚本/判据件把它当权威**（`--include='*.sh|*.py|*.cs'` = 0 命中；全类型 6 命中全部是
  MSBuild 产物清单 `obj/**/*.FileListAbsolute.txt` 与本报告自身），不构成判据；整波重建会刷新。
* **未取到的读数（逐条点名，不许当绿）**：① `Effects` 页那条 `E_NOTIMPL` 的**具体 `MilCmd`**（R-W48D-2）；
  ② 修后冻结**未做**（按纪律由主控发波：重建 → 重取五臂 → 重钉 → 门禁 ×2 → `verify-all` → 冻 `#48`）；
  ③ **未跑** `verify-all.sh`/`integration-wave.sh`/`close-wave.sh`（任务禁止）；
  ④ `[UsableDuringInitialization]`/`[XmlLangProperty]`/`[StyleTypedProperty]` **各自的行为后果未逐条测**
  （只证了「属性回到了类身上」这件事本身；与 `W47A-report.md:285` 同一条边界）。

---

## §8 交付物与一句话交接

* 报告：本文件（`build/MilBridge/W48D-report.md`）。
* 改动：两个 applier（§2，各 4 处）＋ 由它们重生成的 2 个生成件（§4）。
* **九位只动两位**：`windowsbase 84a2826c471e60ea → 79740e9ba7fbf9ca`、`pf 366e9486536bc291 → bd73f9e2376d67ac`；
  `bridge` 与其余六位**逐位未变**；`inputs_fp` 变（两个 applier 在覆盖面里，**设计使然**）。
* **建议下一步（一句话）**：主控发 `#48` 波 —— 整波重建（会顺带刷新 `ARTIFACT-SRC-FP` 与 PC 的陈旧副本）
  → 重取五臂 → 重钉 → 门禁 ×2 → `verify-all` → 冻 `#48`；并把 R-W48D-2（`Effects` 页 `E_NOTIMPL`）与
  §6 自伤②（hc 侧 `Describe()` 的 `Run` 崩溃，纯仪器）各登记一条。
