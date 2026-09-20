# W52A —— D-G58 首个 E_NOTIMPL 命令 / D-G57 零墨根因（只读取证）

> 车道 `W52A`｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜**只读取证**：仓内**唯一写入 = 本报告**（新建）；
> 其余全部产物在 `$HOME/w52a/**`。**未改**任何既有仓内文件（`verify-all.sh` / `build/integration-wave.sh` / `build/close-wave.sh` /
> `docs/**` / `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` / 五件 / 基线 一律未碰）；**未跑** `integration-wave` / `verify-all` / `close-wave` / 冻结；
> **未** `pkill -f`、**未** `pgrep -x dotnet`（只按自己起的 PID 收）。

---

## §0 本趟环境（含报告自身 sha16）

| 项 | 读数 |
|---|---|
| 时间 | 2026-09-20 09:26 → 11:00 +0800｜kernel `6.8.0-138-generic`｜`nproc=3` |
| `MemAvailable` | 起点 **2003 MB**（09:26）／终点 **2550 MB**（11:00）—— 全程 > 1500 MB，未触发等待 |
| 私有 display | **`:131`**（自起 `Xvfb :131 -screen 0 1400x1050x24`，按 PID 收；已占用号 `:0 :1 :10 :97` 未碰） |
| 私有应用目录 | `/home/links-dev/w52a/app`（`cp -a` 自 `/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，113 MB / 71 项） |
| 同步器 | `bash build/MilBridge/tools/sync-applocal.sh /home/links-dev/w52a/app` ⇒ 逐字 `SYNC-APPLOCAL=PASS target=/home/links-dev/w52a/app items=5 ok=5 synced=0 created=0 drift=0 noauth=0 same=0 rc=0`；manifest `.applocal-sync.tsv` sha16 **`6143dde0b897cfb2`**（5 行） |
| `dotnet` | `/home/links-dev/.dotnet/dotnet` **10.0.111**（`export PATH="$HOME/.dotnet:$PATH"`；未 export 时 rc=127 的坑本趟未踩） |

**应用目录五件 sha16（开工 / 收工各算一次，逐位相同 ⇒ 冻结件 `#48`，无陈旧件伪装）**

| 件 | 开工 | 收工 | `#48` 冻结值 |
|---|---|---|---|
| `libwpfwin32.so` | `abf6879c027c5e73` | `abf6879c027c5e73` | ✅ 同 |
| `wpfgfx_cor3.so` | `e3ea092010734f44` | `e3ea092010734f44` | ✅ 同 |
| `PresentationCore.dll` | `9465f9dce39e2dfc` | `9465f9dce39e2dfc` | ✅ 同 |
| `PresentationFramework.dll` | `1011da6390c3bf1e` | `1011da6390c3bf1e` | ✅ 同 |
| `WindowsBase.dll` | `79740e9ba7fbf9ca` | `79740e9ba7fbf9ca` | ✅ 同 |

（三趟跑各自印了 `ART_BEFORE/ART_AFTER`，见 `$HOME/w52a/out-dg58-r1/READING.txt`、`out-dg58-r2-wl/READING.txt`、`out-dg57/READING.txt`。）

**原始证据留档（sha16 / 字节）**

| 件 | sha16 | B |
|---|---|---|
| `$HOME/w52a/out-dg58-r1/READING.txt` | `ba6714c59c171495` | 3,315 |
| `$HOME/w52a/out-dg58-r1/mil.log`（桥诊断汇） | `92dfb08da7a4f9ff` | 906,294 |
| `$HOME/w52a/out-dg58-r1/app.log` | `2dd63afff025a802` | 199,149 |
| `$HOME/w52a/out-dg58-r2-wl/READING.txt` | `4a049d3edf60b38e` | 3,333 |
| `$HOME/w52a/out-dg58-r2-wl/app.log` | `8869a49192ee6468` | 164,760 |
| `$HOME/w52a/out-dg58-r2-wl/mil.log` | `38e8ec659f8cbb08` | 568,891 |
| `$HOME/w52a/out-dg57/READING.txt` | `9d22bb32beafa22e` | 1,381 |
| `$HOME/w52a/out-dg57/root.png`（全屏帧） | `4fa8c4c921caeb47` | 188,461 |

**装置**（全在 `$HOME/w52a/`，仓外）：`dg58.sh`（D-G58 相位）、`dg57.sh`（D-G57 像素相位）、`geoq.py`（从应用自报 `[GEO]` 块取坐标，逐字复制自 `$HOME/w51b/geoq.py`）。

**本趟窗口内被改动的仓内件（不是我 —— mtime 证据，如实归属）**：`build/close-wave.sh` **09:30:47**、`build/integration-wave.sh` **10:27:54** 落在我的窗口（09:26→11:02）内，**我没有写过这两个件**（我的脚本只读仓：`sync-applocal.sh`）；而**五件冻结产物 ＋ `KNOWN-DEFECTS.md`(01:25) ＋ `docs/CURRENT-STATE.md`(01:25) ＋ `known-red.json`(00:24)** 的 mtime **全部早于 09:23** ⇒ 本轮读数**没有踩到别人的写入**（`git` 在本机 PATH 里不存在，故给 mtime 证据而非 `git status`）。

**报告自身 sha16**（**口径写死**：本文件有**两处**自报指纹（本节 ＋ 文件最后一行）⇒ 复算时先把这两处换回占位符、再取 `head -n -1`（= 正文，不含最后一行指纹行）：

```bash
sed 's/REPORT_SELF_SHA16=[0-9a-f]\{16\}/REPORT_SELF_SHA16=__SELF__/g' build/MilBridge/W52A-report.md \
  | head -n -1 | sha256sum | cut -c1-16
```
本行即字面值（已按上面这条命令复算通过）：`REPORT_SELF_SHA16=8387bde7f9a3fdae`

---

## §1 `D-G58` 读数：首个返回 `E_NOTIMPL` 的命令

### 1.1 一句话

**首个失败命令 = `id=0x6c`（`MilCmdPixelShader`）**，出现在「工具」页第 3 项 `Effects` 加载时**同一批 243 条待提交命令**的第 **#55** 条
（`len=240`、`handle=0x000004a4`）；`Commit()` 返回 **`hr=0x80004001`（`E_NOTIMPL`）**，上游 `HRESULT.Check` 把它翻成
`NotImplementedException` ⇒ 进程 abort，页面永不出现。**同一批里还有 7 条 `0x70 MilCmdShaderEffect`**（见 §1.4），
两条都是 HandyControl 那六个 `ShaderEffect` 子类（`ColorComplementEffect`/`GrayScaleEffect`/`ColorMatrixEffect`/…）走的路。

### 1.2 现场逐字读数（r1 趟，`mil.log` 行号可复算）

```
8832:[preflight] 通道 2 待提交 #0:    id=0x1b (MilCmdVisualSetOffset) len=24 handle=0x0000009f 在资源表里=True
 ...
8886:[preflight] 通道 2 待提交 #54:   id=0x6d (MilCmdImplicitInputBrush) len=28 handle=0x000004a3 在资源表里=True
8887:[preflight] 通道 2 待提交 #55:   id=0x6c (MilCmdPixelShader) len=240 handle=0x000004a4 在资源表里=True   ← 首个 E_NOTIMPL
8888:[preflight] 通道 2 待提交 #56:   id=0x70 (MilCmdShaderEffect) len=92  handle=0x000004a2 在资源表里=True
8889:[preflight] 通道 2 待提交 #57:   id=0x1d (MilCmdVisualSetEffect) len=12 handle=0x000004a5 在资源表里=True
 ...
9074:[preflight] 通道 2 待提交 #242:  id=0x26 (MilCmdVisualInsertChildAt) len=16 handle=0x00000503 在资源表里=True
9075:[commit] ★E_HANDLE#2 channel.Commit() 失败 hr=0x80004001（通道 2）；待提交命令见上面的预检
```

| 判别量 | 读数 | 出处 |
|---|---|---|
| 该批命令条数 | **243**（`#0`..`#242`，一个 `Commit()` 的待提交表） | `mil.log:8832-9074` |
| 首个 notImpl 命令 | **`#55` / `0x6c` / `MilCmdPixelShader` / `len=240` / `handle=0x4a4`** | `mil.log:8887` |
| 批内 notImpl 命令总数 | **12** = `0x6c`×**5**（#55/#63/#78/#94/#97）＋ `0x70`×**7**（#56/#64/#71/#79/#86/#95/#98） | `mil.log:8887-8930` |
| 失败的 `hr` | **`0x80004001`**（`HResult.E_NOTIMPL`） | `mil.log:9075` |
| 是否落到 `#3`（呈现失败） | 否：`★E_HANDLE#3` 全趟 **0** 条 | `grep -c '★E_HANDLE#3' mil.log` = 0 |
| 进程 | `item[2] alive=no unhandled=1`（`Unhandled exception` 1 行） | `out-dg58-r1/READING.txt` |

**异常栈逐字（`out-dg58-r1/app.log`）**——与本仓 `KNOWN-DEFECTS.md:2108-2122` 记的一致，补上了**仓内行号**：

```
Unhandled exception. System.NotImplementedException: The method or operation is not implemented.
   at System.Windows.Media.Composition.DUCE.Channel.Commit() in upstream/.../Common/Graphics/exports.cs:line 376
   at System.Windows.Media.MediaContext.CommitChannel() in upstream/.../PresentationCore/System/Windows/Media/MediaContext.cs:line 2151
   at System.Windows.Media.MediaContext.Render(ICompositionTarget) in .../MediaContext.cs:line 2075
   at System.Windows.Media.MediaContext.RenderMessageHandlerCore(Object) in .../MediaContext.cs:line 1853
   at System.Windows.Media.MediaContext.AnimatedRenderMessageHandler(Object) in .../MediaContext.cs:line 1735
```
`exports.cs:376` 逐字 = `HRESULT.Check(UnsafeNativeMethods.MilConnection_CommitChannel(_hChannel));`（**这就是把 `E_NOTIMPL` 变成异常的那一行**）。

### 1.3 为什么能断定「第一个」是 `#55`（而不是"红了就算"）

`MilChannel.Commit()`（`src/WpfGfx.Linux/Resources/MilChannel.cs:241`）逐条 `Dispatch`，**只保留第一个失败 HRESULT**
（`:257 if (HResult.Failed(one) && hr == HResult.S_OK) hr = one;`），并把每条 `E_NOTIMPL` 记进 `NotImplRegistry`（`AccountDispatchResult`，`:266`）。
派发顺序 = `_commandLengths` 顺序 = 预检打印的 `#0,#1,…` 顺序 ⇒ 只要"#0..#54 里没有会返回 `E_NOTIMPL` 的命令"，
首个失败就必然是 `#55`。该前提我用**静态穷举**钉死：

* 会返回 `E_NOTIMPL` 的出口只有三处：`MilCommandDispatcher.cs:38`（`IsNotImplemented` 集合）、`:43`（未知命令字，`FixedSize < 0`）、`:1370`（`DispatchCore` 的 `default:`）。
* 机器核算（脚本见 §6.E）：`FixedSize` 条目 **110** 条，`DispatchCore` 显式 `case` **111** 条，**差集 = ∅**（`MilCmdInvalid` 反向多 1）
  ⇒ 第二处**今天取不到**；`s_notImpl` = **7** 条（`MilCommandLayout.cs:211-223`）⇒ 全仓只有这 **7** 个 id 会返回 `E_NOTIMPL`。
* 该批 `#0..#54` 的 id 里，**这 7 个一个都没出现**：全趟 `id=0x17 / 0x3b / 0x3c / 0xa / 0xb` 命中 **0**，`0x6c/0x70` 的**首次出现就是 `#55`**。

### 1.4 该命令由哪段托管代码发出

| 命令 | 发送点（上游，行号现场读取） | 入口 |
|---|---|---|
| `0x6c MilCmdPixelShader` | `upstream/.../PresentationCore/System/Windows/Media/Effects/PixelShader.cs:171 ManualUpdateResource(...)` → `:180 DUCE.MILCMD_PIXELSHADER data; :181 data.Type = MILCMD.MilCmdPixelShader; :190 channel.BeginCommand(...)` | `…/Media/Effects/Generated/PixelShader.cs:140 internal override void UpdateResource(...)` |
| `0x70 MilCmdShaderEffect` | `…/Media/Effects/ShaderEffect.cs:545 ManualUpdateResource(...)` → `:559 DUCE.MILCMD_SHADEREFFECT data; :560 data.Type = MILCMD.MilCmdShaderEffect; :588 channel.BeginCommand(...)` | `…/Media/Effects/Generated/ShaderEffect.cs:162 internal override void UpdateResource(...)` |

**触发链（与异常栈对齐）**：`EffectsDemo.xaml` 的 `Loaded` 触发器起 `StoryboardLoaded`（`D-G56` 修后才真的起得来）+
页面里的六个 `hc:*Effect`（`ShaderEffect` 子类）⇒ 渲染 pass 里这些资源第一次上通道 ⇒ `UpdateResource` → `ManualUpdateResource`
⇒ `BeginCommand/EndCommand`（`[CMD]` 台账 12 条 `EndCommand`）⇒ `MediaContext.CommitChannel()`（`MediaContext.cs:2151 Channel.Commit();`）
⇒ 桥 `MilChannel.Commit()` 逐条派发 ⇒ `#55` 返回 `E_NOTIMPL` ⇒ `exports.cs:376` 抛异常。

页面侧静态证据（仓外，逐字）：`/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Tools/EffectsDemo.xaml`
用了 `<hc:ColorComplementEffect/>`、`<hc:GrayScaleEffect/>`、`<hc:ColorMatrixEffect .../>`，而
`/home/links-dev/hc-linux/src/Shared/HandyControl_Shared/Media/Effects/EffectBase.cs:7 public abstract class EffectBase : ShaderEffect`、
`ColorComplementEffect.cs` 的 `new PixelShader { UriSource = …ColorComplementEffect.ps }`
⇒ **一个 `PixelShader` + 一个 `ShaderEffect`，与台账里 5+7 的成对形状逐条吻合**。

### 1.5 桥/原生侧**为什么没实现**（缺哪一个 case / 入口，文件:行）

| # | 位置（现场读取） | 事实 |
|---|---|---|
| ① | `src/WpfGfx.Linux/Commands/MilCommandLayout.cs:211-223` `s_notImpl` | **`MilCmdPixelShader`（`:216`）与 `MilCmdShaderEffect`（`:217`）被登记为"永久不做"** |
| ② | `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs:38` | `if (MilCommandLayout.IsNotImplemented(cmd)) return HResult.E_NOTIMPL;` ⇒ **在 `DispatchCore`（`:69` 的 `switch`）之前就短路了** |
| ③ | `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs:69-1371`（`DispatchCore`） | **今天根本没有 `case MilCmd.MilCmdPixelShader:` / `case MilCmd.MilCmdShaderEffect:`**（静态核对 `case` 名集 ∩ notImpl = ∅）⇒ 就算放行也会落到 `:1370 default: return HResult.E_NOTIMPL;` |
| ④ | `src/WpfGfx.Linux/Resources/MilResourceTable.cs:244-246` `default:` | `TYPE_PIXELSHADER`(33)/`TYPE_SHADEREFFECT`(38)（`Contracts/MilResourceType.cs:41`/`:46`）**没有 case** ⇒ 建成 `MilOpaqueResource`（不失败，但也没有实现） |
| ⑤ | `build/MilBridge/src/**`、`src/WpfGfx.Linux.Native/src/**` | **`grep -rIl 'ShaderEffect\|PixelShader'` = 0 件** ⇒ 桥/原生侧**没有任何 shader 渲染入口** |
| ⑥ | `docs/unimplemented.md:184-185`（另一处 `:222-223`） | 记 0x6c/0x70 为 **"C 类（永久划掉）… 需 D3D 编译与执行环境"** |

### 1.6 成对读数（证明"台账确实开着，不是没开所以没报"）

同一趟 r1、同一进程、同一仪器，只换"点了哪一项"：

| 相位 | mil.log 区间 | 该段 notImpl 候选命令数 | 进程 |
|---|---|---|---|
| 启动（含窗口创建） | `1..4441` | **0** | alive |
| 点「工具」页签 | `4446..7152` | **0** | alive |
| item[0] `HatchBrushGenerator` | `7154..7428` | **0** | alive |
| item[1] `MorphingAnimation` | `7433..8332` | **0** | alive |
| **item[2] `Effects`** | `8352..9075` | **12**（5×0x6c + 7×0x70） | **dead（unhandled=1）** |

仪器活性自证（同趟）：`[preflight]` **1903** 行、`[CMD]` **400** 行（无白名单时的 400 行预算，启动期即烧满 ⇒ 本轮另开白名单趟）、
通道计数快照 **54** 条。⇒ 前四段"0 条"是**真 0**，不是"仪器没开"。

**白名单趟（r2，第二台互不相干的仪器）**：`WPF_LINUX_CMDLOG_ID=0x6c,0x70` ⇒ 命令层台账**只**吐出这 12 条，
id / `len` / `handle` 与 r1 的预检**逐条相同**、顺序相同；且起点 `T0` 时 `[CMD]` = **0** 行（白名单生效的阳性证明）。

```
out-dg58-r2-wl/app.log:1490 [CMD] ch=2 EndCommand id=0x6c handle=0x000004a4 len=240 extra=220 appended=220
out-dg58-r2-wl/app.log:1491 [CMD] ch=2 EndCommand id=0x70 handle=0x000004a2 len=92  extra=12  appended=12
 ...
out-dg58-r2-wl/app.log:1502 [CMD] ch=2 派发        id=0x6c handle=0x000004a4 len=240
out-dg58-r2-wl/app.log:1513 [CMD] ch=2 派发        id=0x70 handle=0x0000049a len=110
```

### 1.7 最小复现命令行（逐字，可直接粘贴；只写进 `$HOME`，不碰仓）

见 §6.A（`dg58.sh` 三条命令 + 相位）。**关键 env 五条**：
`WPF_LINUX_MIL_LOG=<file>`（= `MilPresentation.DiagnosticSinkEnabled`，`src/WpfGfx.Linux/Interop/MilPresentation.cs:116`）、
`WPF_LINUX_MIL_TRACE=1`、`WPF_LINUX_CMDLOG=1`、`WPF_LINUX_PREFLIGHT_BUDGET=200000`、
（复核趟）`WPF_LINUX_CMDLOG_ID=0x6c,0x70`。

---

## §2 `D-G57` 读数：页签行/按钮零墨

### 2.1 像素级（同一脚本、同一阈值；区域 = 应用自报 `[GEO]` 矩形）

| 区域（屏幕坐标） | `%k` 唯一色数 | `stddev` | 众数色 | 判读 |
|---|---|---|---|---|
| **页签行** `228x27+318+318`（三个 TabItem） | **1** | **0.00 %** | `#FFFFFF` | **纯色、零墨** |
| **选中页签（工具）整块** `74x27+473+318` | **1** | **0.00 %** | `#FFFFFF` | **连"选中态下划线"也没有**（见 2.3） |
| 选中态下划线带 `74x4+473+341` | **1** | **0.00 %** | `#FFFFFF` | 模板里 `BorderThickness="0,0,0,2"` 那条线**一像素都没画** |
| **「实用示例」按钮** `203x27+328+284` | **8** | 0.15 % | `#EEEEEE` | 按钮自己的背景画了，**Content 没画** |
| **搜索框** `176x27+328+358`（`len=0`） | 19 | 2.71 % | `#FFFFFF` | **只有右侧放大镜图标，Placeholder 文字没有**（本轮新读数，1:1 已人眼复核） |
| **导航项**（对照）`203x27+328+391` | **69** | **10.47 %** | `#FFFFFF` | **有墨**：1:1 放大后逐字可读「画刷（Brush）」+ 图标 |
| 同法负对照 `203x27+318+538` | 128 | 12.27 % | `#FFFFFF` | ⚠️ **如实更正**：这一格我本想取"空白带"，实测有色 ⇒ 那里其实是**另一个导航项**（列表是连续的）。它作为**"裁剪脚本确实读得到墨"的阳性对照**成立，作为"空白"不成立 |

**页签行逐行墨量**（`tabrow.png` 的 27 行逐行统计非众数色像素）：**27 行全部为 0**，整块 6156/6156 像素全是 `#FFFFFF`。
⇒ **这不是"字是白的"能解释的巧合**（白字会在 `#FFFFFF` 上留下反锯齿残差），而是**该矩形内没有任何绘制**。

**与 W47A 的交叉一致**：本趟四个区域的 `%k/stddev` 与 `build/MilBridge/W47A-report.md` §5（`#46` 上量的）**逐位相同**
（1/0.00%、8/0.15%、19/2.71%、69/10.47%）⇒ 现象**确定性**，且**没有被 `#48` 的 `D-G55`/`D-G56` 修复改变**。

坐标来源（诚实说明）：`dg57.sh` 那趟**没开** `HC_INPUT_DIAG` ⇒ 该趟 `app.log` 里没有 `[GEO]` 块（脚本对应小节留空）；
本报告用的矩形取自 **r1 趟的活体 `[GEO]`**（同冻结件、同窗口 `id=2097156 X=300 Y=225 800x600`）：
`[GEO] TabItem#- scr=318,318 wh=74x27 … hdr=HandyControlDemo.Data.DemoInfoModel`（×3，选中项 `sel=True`）、
`[GEO] SearchBar#- scr=328,358 wh=176x27 … len=0`、`[GEO] Button#- scr=328,284 wh=203x27`、`[GEO] item[0] ListBoxItem scr=328,391 wh=203x27 nm=HatchBrushGenerator`。

### 2.2 「命中」与「语义」都是通的（不是命中问题 —— 与 W47A 同结论，本趟独立复现）

r1 趟点最右页签 `(510,331)` ⇒ 之后 `[GEO]` 里 `ListBox#ListBoxDemo` 的项变成
`item[0] nm=HatchBrushGenerator / item[1] nm=MorphingAnimation / item[2] nm=Effects`（样式页是 31 项）
⇒ **点得中、真的换了页**；TabItem 行仍是 `vis=True htv=True`。⇒ `D-G57` **不是命中/可见性问题**。

### 2.3 量的证据：**不是"零宽被裁剪"，也不是"文本为空串"**

* `TabItemStyle`（`/home/links-dev/hc-linux/src/Shared/HandyControl_Shared/Themes/Styles/Base/TabControlBaseStyle.xaml:3`）
  设 `Padding="{StaticResource DefaultControlPadding}"`，而 `Themes/Basic/Sizes.xaml:7` 逐字 = `<Thickness x:Key="DefaultControlPadding">10,5</Thickness>`；
  模板里 `mainBorder BorderThickness="0"` ⇒ **TabItem 宽度 = 2×10 + header 内容宽度**。
* 实测三个 TabItem 都是 **74 px** 宽 ⇒ **header 内容的 `DesiredSize.Width` ≈ 54 px ≠ 0**
  （WPF `TabPanel` 对同一行的页签**取等宽**，54 = 三者里的最大值）。
* ⇒ **空串会给出 0 px 宽的内容、`ActualWidth=0` 的裁剪会给出 0 px 宽的内容** ⇒ 两条都被排除。
* 内容的 54 px 与"英文标题 `Controls` @ FontSize≈12.5"同量级（同趟实测导航项「画刷」两个 CJK 字 ≈ 25 px ⇒ 单字 ≈ 12.5 px）；
  这一点只作参考，**不据此下结论**。

### 2.4 四格矩阵（同**一个** XAML 文件里的四处 `{ex:Lang}` ⇒ 差异是**可定位**的）

文件：`/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Main/LeftMainContent.xaml`（仓外只读）

| # | 行 | 目标属性 | `Key` 形态 | 宿主 | 墨 |
|---|---|---|---|---|---|
| 1 | `:17` | `TextBlock.Text` | `{Binding Title}` | `TabControl.ItemTemplate`（DataTemplate） | **零墨**（整块纯色） |
| 2 | `:13` | `Button.Content` | `{x:Static langs:LangKeys.PracticalDemos}`（**string**） | 直接 | **无字**（8 色 ≈ 纯背景） |
| 3 | `:34` | `hc:InfoElement.Placeholder`（附加 DP） | `{x:Static langs:LangKeys.PlsEnterKey}`（**string**） | `hc:SearchBar` | **无字**（19 色 = 仅图标） |
| 4 | `:37` | `HighlightTextBlock.SourceText` | `{Binding Name}` | `ListBox.ItemTemplate` | **有字**（69 色，人眼逐字「画刷」） |

四处都走同一个标记扩展 `HandyControlDemo.Tools.Extension.LangExtension`
（`Tools/Extension/LangExtension.cs:1-11`，`Source = LangProvider.Instance`；基类
`HandyControl_Shared/Tools/Extension/LangExtension.cs`）。基类 `ProvideValue` 的两条分支（逐字读过）：

* **string 分支**（第 2/3 格走这里）：`case string key:` ⇒
  `BindingOperations.SetBinding(targetObject, targetProperty, CreateLangBinding(key))` **然后** `return binding.ProvideValue(serviceProvider);`
  —— `CreateLangBinding` = `new Binding(key){ Source = Source, Mode = OneWay, UpdateSourceTrigger = Explicit }`。
  两条 key 都**确实存在**：`LangProvider.cs:1041 public string PracticalDemos => Lang.PracticalDemos;`、
  `:1026 public string PlsEnterKey => Lang.PlsEnterKey;`（`LangKeys.cs` 侧
  `:2205 public static string PracticalDemos = nameof(PracticalDemos);` ⇒ `{x:Static}` 得到的是**键名串**，不是译文）⇒ **键不是问题**。
* **Binding 分支**（第 4 格、第 1 格走这里）：`case Binding keyBinding when targetObject is FrameworkElement element:`
  ⇒ 若 `element.DataContext != null` 立即 `SetLangBinding(...)`；**若为 `null` ⇒ 只登记 `DataContextChanged` 然后 `break`，
  函数落到末尾 `return string.Empty;`**（`ProvideValue` 最后一个 `return string.Empty;`）。

⇒ **第 1 格（页签）与第 4 格（导航）走同一个分支、同一个扩展，结果却一个零墨一个有字**；
差异只能落在"该元素在 `ProvideValue` 时刻的 `DataContext` 是否为 null ＋ 之后 `DataContextChanged` 是否真的到达**这个**元素"
（页签 header 由 `TabItem` 的 `ContentPresenter ContentSource="Header"` 承载，导航项由 `ListBoxItem` 承载）。

### 2.5 根因（**收窄 + 一格 `NOINFO`**）

**已确证（硬读数）**：
1. `D-G57` 在冻结 `#48` 上**仍然存在、确定性复现**（与 `#46` 逐位相同的四区读数）。
2. 它在**页签行**上的形态比"字没画"更宽：**选中页签自己的 2 px 下划线（`mainBorder` 的 `BorderThickness=0,0,0,2`）也没有落屏**
   ⇒ 该矩形内**零绘制**，不是"字被画成了白色/透明"（那会留下反锯齿残差）。
3. **不是**命中问题（§2.2）、**不是**零宽裁剪、**不是**空串（§2.3）。
4. 受影响的**同一份 XAML 里的三处 `{ex:Lang}`**（页签 header / Button.Content / SearchBar.Placeholder）与**一处正常**的
   `{ex:Lang}`（导航项）共处一模一样的父容器（同一个 `Border`，含 `Effect="{StaticResource EffectShadow4}"`）
   ⇒ **不是"整块面板没画"**（同一面板里导航项有字、按钮背景有像素）。

**`NOINFO` 的那一格（差哪一步）**：我**没能**把"零绘制"劈成下面两个候选之一：
* **(a) 画刷**：`TextElement.Foreground`/`BorderBrush` 在这个 header 子树里解析成了 `#FFFFFF`（页签行背景正好也是 `#FFFFFF`）；
* **(b) 绘制**：header 子树（`hc:SimplePanel` + `ContentPresenter(ContentSource="Header")` + DataTemplate 内容）的绘制指令根本没进 mil 通道。
**差的一步**：读进程内状态——该子树每个子件的 `IsVisible` / `ActualWidth` / `TextBlock.Text` / `TextElement.Foreground`。
本轮**没有**这一步的能力：hc 仪器（仓外 `App.xaml.cs`）只转储 `TabItem/ButtonBase/TextBox/…` 的**几何**（`wh/vis/htv/hdr`），
**不转储 `Foreground`、不转储 header 子树的子件**；而本车道的写域只有这份报告（不许改仓内件、也不宜改仓外仪器）。
⇒ 按本仓规矩：**该格记 `NOINFO`，不许当绿、也不许当红**；§5 给出"一次跑就能劈开"的最小探法。

---

## §3 两极化对照表（做了什么、看到什么／**未做对照**的如实标注）

| # | 对照 | 正极 | 负极 | 结论 |
|---|---|---|---|---|
| 1 | **`D-G58` 同趟同仪器，只换点哪一项** | item[0]=`HatchBrushGenerator`、item[1]=`MorphingAnimation` ⇒ notImpl 候选 **0**、`alive=yes`、`unhandled=0` | item[2]=`Effects` ⇒ notImpl **12**、`alive=no`、`unhandled=1` | 现象**只在**走到 `ShaderEffect` 的那一页出现，且**同趟**成立 ⇒ 归因唯一 |
| 2 | **两台互不相干的仪器** | r1：预检台账（`MilChannel.PreflightPendingCommands`）给出 `#55/#56/…` | r2：命令层台账（`[CMD] EndCommand/派发`，白名单 `0x6c,0x70`）给出**同样 12 条、同 id、同 len、同 handle、同顺序** | 读数**跨仪器一致** ⇒ 不是单一仪器的假象 |
| 3 | **`D-G57` 同脚本同阈值的四区对照** | 导航项 69 色 / 10.47 %（且人眼可读） | 页签行 1 色 / 0.00 %、按钮 8 色 / 0.15 %、搜索框 19 色 / 2.71 % | **同一套取数与阈值**下，"有字"与"零墨"分得开 |
| 4 | **`D-G57` 与历史世代对照（跨车道、非我本趟所测）** | `#46`（W47A 报告 §5）：1 / 8 / 19 / 69 | `#48`（本趟）：1 / 8 / 19 / 69 | 现象**未被 `D-G55`/`D-G56` 修复改变**（读数逐位相同） |
| 5 | ⚠️ **未做对照**：`D-G57` 的"翻极性" | — | — | **我没有做**"换掉某个候选因（如把 header 模板/画刷换掉、或换回旧件）⇒ 墨回来"的实验 ⇒ (§2.5) 的两个候选**都不能被判为因** |
| 6 | ⚠️ **未做对照**：`D-G58` 的"修后消失" | — | — | 我**没有**改任何代码/件 ⇒ "把 0x6c/0x70 放行后 Effects 页能加载"**是推断（§5 方案），不是读数** |

---

## §4 排除清单与边界

**`D-G58`（已确证，无 `NOINFO`）**
* 已排除："诊断汇没开所以没报"（§1.6 的三条活性自证 + 白名单趟）；"失败来自 `E_HANDLE`/`E_INVALIDARG`"（`hr` 逐字 `0x80004001`）；
  "`#55` 之前另有失败命令"（`E_NOTIMPL` 集合今天只有 7 个 id，静态穷举 + 全趟 grep 双重排除）；
  "另一条提交路径（`WgxConnection_SameThreadPresent` / 收尾 flush / `MilSyncFlush`）没打印"（`Commit()` 是**唯一汇聚点**，
  预检已下沉到 `MilChannel.cs:247`，`W48D` 的 `D-G54` 修过这条）。
* 边界：只覆盖**这一条**触发路径（hc「工具」页 #2）。其它页/别的 app 可能撞上 `s_notImpl` 的另外 5 条（`0x0a/0x0b/0x3b/0x3c/0x17`）—— 本趟**未测**。

**`D-G57`（收窄到 §2.5，最后一格 `NOINFO`）**
* 已排除：命中/可见性（§2.2）；零宽裁剪（§2.3）；空串（§2.3）；"整块面板没画"（同面板导航项有字，§2.4）；
  "只有页签有问题"（按钮 Content、SearchBar Placeholder **同样**无字 ⇒ 是**一类**现象）。
* 未查 / 未取到（如实）：
  1. header 子树子件的 `IsVisible` / `ActualWidth` / `Text` / `Foreground` —— **未取到**（无进程内插桩，见 §2.5）；
  2. `dg57.sh` 那趟**未开** `WPF_LINUX_MIL_LOG` ⇒ 没有"页签区域的绘制指令"读数；且**预检台账不带几何**，无法按屏幕区域归因 ⇒ 即便开也答不了 (b)；
  3. 第 1 格（页签）在 `ProvideValue` 时刻的 `DataContext` 是 null 还是非 null ⇒ **未取到**；
  4. `LangExtension` 基类里 `break` 之后 `return string.Empty` 的**实际是否发生** ⇒ **未取到**（同 3，需插桩）。
* 边界：本报告对 `D-G57` 的结论**只到**"零绘制 + 不是那三条 + 同类现象覆盖三处 `{ex:Lang}`"；**没有**指认任何"本仓某文件:行"，
  因为候选 (a)(b) 分属"画刷解析"与"绘制路径"，**在没有 §5 那一步之前点名就是猜**。

**写域自证**：本趟仓内只新建 `build/MilBridge/W52A-report.md`；`$HOME/w52a/**` 下新增 `dg58.sh`/`dg57.sh`/`geoq.py`/`app/`/`out-*`；
应用目录五件 sha16 开工=收工（§0）；**未**跑 `integration-wave`/`verify-all`/`close-wave`/`frame-step`/`pc-line-step`；**未** `pkill`。

---

## §5 下一步最小修法（**只写方案，未改任何代码**）

### 5.1 `D-G58`：两级

* **止血（推荐先做，风险小、可判据化）**：让这两条命令**不再把整页打死**——
  ① `MilCommandLayout.cs:211-223` 的 `s_notImpl` 里**移出** `MilCmdPixelShader`（`:216`）与 `MilCmdShaderEffect`（`:217`）；
  ② `MilCommandDispatcher.DispatchCore`（`MilCommandDispatcher.cs:69`）**新增两个 `case`**：
  `MilCmdPixelShader` ⇒ 收下 `PixelShaderBytecodeSize` 尾部字节、返回 `S_OK`（**不执行**）；
  `MilCmdShaderEffect` ⇒ 记录参数与 `hPixelShader`、返回 `S_OK`，渲染上按**恒等效果**处理（不改变像素）；
  ③ 若要让资源表不再是占位：`MilResourceTable.cs:244-246` 之前加 `TYPE_PIXELSHADER`（33）/`TYPE_SHADEREFFECT`（38）两条 case。
  **预期效果**（**推断，未实测**）：`Effects` 页能加载（六张图不变形、无滤镜），`D-G58` 从"进程 abort"降级为"效果不生效"，
  `W51B` 报告里那条"`D-G56` 撤登记判据③ 第 3 格 `NOINFO`"即可转成读数。
  **代价**：动 `src/WpfGfx.Linux/Commands/**` + `Resources/**` ⇒ `pc` 重建（`WpfGfx.Linux` 是九位之一？按 `#48` 的口径需现场核）⇒ **必须发波**：重取五臂 + 重钉 `known-red.json` + 门禁 ×2。
* **真修（大）**：在桥侧实现 `ShaderEffect`。两条路：(i) 把 `ps_2_0/ps_3_0` 字节码交给 Skia `SkRuntimeEffect`（需 D3D 字节码→SkSL 的转译，工作量大）；
  (ii) 只支持 `ShaderRenderMode` 里的"软件着色"退化路径（`PixelShader.cs:186 CompileSoftwareShader` 那位）。
  **建议**：先做止血 + 把"未实现的 shader 效果"记进台账（**不静默**），真修另立波。

### 5.2 `D-G57`：先加**一格探测**，再谈修

* **第一步（劈开 §2.5 的 (a)/(b)，一次跑即可）**：给页签行加一段**只读探针**（hc 仪器侧，仓外；或在 `HC_GEO_EVERY` 的 `GeoWalk` 里加一个 `HC_PROBE_HEADER=1` 分支），
  对 `TabControl` 的每个 `TabItem` 打印：`ContentPresenter` 子件数、每个子件的 `GetType().Name / IsVisible / ActualWidth / ActualHeight`、
  若是 `TextBlock` 再打 `Text.Length` 与 `TextElement.Foreground`（`SolidColorBrush.Color`）。
  * 若子件 `IsVisible=True`、`ActualWidth>0`、`Foreground=非白` ⇒ **(b) 绘制/呈现路径**（去看 `hc:SimplePanel` 与 header `ContentPresenter` 的绘制）；
  * 若 `Foreground=#FFFFFFFF` ⇒ **(a) 画刷解析**（去看该 `{DynamicResource PrimaryTextBrush}` 在 TabItem 模板里的解析）。
* **第二步（若判成 (a)）**：`TabItemStyle` 的 `ContentPresenter` 用 `{DynamicResource PrimaryTextBrush}`，选中态触发器换成 `{DynamicResource PrimaryBrush}`
  —— 两个不同的画刷都出问题才解释得了"整行 1 色"，所以**大概率不是 (a)**；先看第一步读数再定。
* **不建议**为了"看着有字"而在 hc 侧绕开（例如把页签改 `HeaderTemplate` 硬写 `Text`）——那会把根因藏起来。

---

## §6 复算命令（逐条可粘贴）

### A. `D-G58` 主相位（r1：全量台账）
```bash
export PATH="$HOME/.dotnet:$PATH"; export DOTNET_gcServer=0
mkdir -p $HOME/w52a && cp -a /home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0 $HOME/w52a/app   # 已存在则跳过
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
bash build/MilBridge/tools/sync-applocal.sh $HOME/w52a/app          # 期望 SYNC-APPLOCAL=PASS items=5 ok=5
bash $HOME/w52a/dg58.sh r1                                          # ~50 s（自起 Xvfb :131 + 点页签 + 点 item[0..2]）
```

### B. `D-G58` 复核相位（r2：命令层台账白名单）
```bash
bash $HOME/w52a/dg58.sh r2-wl '0x6c,0x70'
```

### C. `D-G58` 结论行（读 r1 落盘证据）
```bash
cd $HOME/w52a/out-dg58-r1
grep -an 'id=0x6c \|id=0x70 ' mil.log | head -3        # 首个 = 8887:[preflight] … #55: id=0x6c (MilCmdPixelShader) len=240 handle=0x000004a4
grep -an '★E_HANDLE#2' mil.log                          # 9075:[commit] ★E_HANDLE#2 channel.Commit() 失败 hr=0x80004001（通道 2）
grep -an '^\[preflight\]' mil.log | grep -a '待提交 #0:' | tail -1   # 8832 = 该批起点（#0..#242 共 243 条）
grep -a -A5 '^Unhandled exception' app.log | head -6    # 栈顶 exports.cs:376 ← MediaContext.cs:2151
grep -aoE 'id=0x(6c|70|17|3b|3c|a|b) \(MilCmd' mil.log | sort | uniq -c   # 5 个 0x6c + 7 个 0x70，其余 0
```

### D. `D-G58` 复核趟结论行
```bash
cd $HOME/w52a/out-dg58-r2-wl
grep -an '^\[CMD\]' app.log | grep -a '0x6c\|0x70' | head -14     # 12 条 EndCommand/派发（1490-1513）
grep -an '^\[preflight\].*待提交 #5[0-9]' mil.log                 # 6107 起：#55 id=0x6c / #56 id=0x70 …
```

### E. 「会返回 `E_NOTIMPL` 的 id 集合 = 7 条」的静态穷举
```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
python3 - <<'EOF'
import re
L=open('src/WpfGfx.Linux/Commands/MilCommandLayout.cs',encoding='utf-8').read().splitlines()
fs=set(); i=[k for k,l in enumerate(L) if 'public static int FixedSize' in l][0]
while i<len(L):
    m=re.match(r'\s*MilCmd\.(\w+) =>',L[i])
    if m: fs.add(m.group(1))
    if re.match(r'\s*_ =>',L[i]): break
    i+=1
j=[k for k,l in enumerate(L) if 's_notImpl = new HashSet' in l][0]; ni=set()
while j<len(L):
    m=re.match(r'\s*MilCmd\.(\w+),',L[j])
    if m: ni.add(m.group(1))
    if '};' in L[j]: break
    j+=1
cases=set(re.findall(r'case MilCmd\.(\w+):',open('src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs',encoding='utf-8').read()))
print('FixedSize=',len(fs),'case=',len(cases),'差集(落 default E_NOTIMPL)=',sorted(fs-cases),'notImpl=',sorted(ni))
EOF
```

### F. `D-G57` 像素相位
```bash
export PATH="$HOME/.dotnet:$PATH"
bash $HOME/w52a/dg57.sh                       # ~45 s；写 $HOME/w52a/out-dg57/{root.png,tabrow.png,button.png,searchbar.png,navitem.png,READING.txt}
```

### G. `D-G57` 结论行（含选中页签与下划线那两格）
```bash
cd $HOME/w52a/out-dg57
convert root.png +repage -crop 228x27+318+318 +repage /tmp/t.png && identify -format '%k %[fx:standard_deviation]\n' /tmp/t.png   # 1 0
convert root.png +repage -crop 74x27+473+318  +repage /tmp/s.png && identify -format '%k %[fx:standard_deviation]\n' /tmp/s.png   # 1 0（选中页签整块）
convert root.png +repage -crop 74x4+473+341   +repage /tmp/u.png && identify -format '%k %[fx:standard_deviation]\n' /tmp/u.png   # 1 0（选中态下划线带）
convert root.png +repage -crop 203x27+328+391 +repage /tmp/n.png && identify -format '%k %[fx:standard_deviation]\n' /tmp/n.png   # 69 0.1047（导航项对照）
convert root.png +repage -crop 176x27+328+358 +repage /tmp/q.png && identify -format '%k %[fx:standard_deviation]\n' /tmp/q.png   # 19 0.0271（搜索框：无 Placeholder 文字）
convert /tmp/n.png -filter point -resize 400% /tmp/n_x4.png       # 人眼复核「画刷」
```

### H. 静态引用（本报告引到的每一处，现场读过）
```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
sed -n '36,45p;1365,1372p' src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs
sed -n '211,223p' src/WpfGfx.Linux/Commands/MilCommandLayout.cs
sed -n '241,263p;266,278p' src/WpfGfx.Linux/Resources/MilChannel.cs
sed -n '176p;184p' src/WpfGfx.Linux/Contracts/MilCmd.cs
sed -n '41p;46p' src/WpfGfx.Linux/Contracts/MilResourceType.cs
sed -n '244,247p' src/WpfGfx.Linux/Resources/MilResourceTable.cs
sed -n '170,172p' upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/Effects/PixelShader.cs
sed -n '543,546p' upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/Effects/ShaderEffect.cs
sed -n '374,378p' upstream/wpf/src/Microsoft.DotNet.Wpf/src/Common/Graphics/exports.cs
sed -n '2149,2152p' upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/MediaContext.cs
sed -n '184,186p' docs/unimplemented.md
sed -n '1,14p;53,56p'  /home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Main/LeftMainContent.xaml
sed -n '1,11p'         /home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/Tools/Extension/LangExtension.cs
sed -n '55,100p'       /home/links-dev/hc-linux/src/Shared/HandyControl_Shared/Tools/Extension/LangExtension.cs
sed -n '1,15p'         /home/links-dev/hc-linux/src/Shared/HandyControl_Shared/Themes/Styles/Base/TabControlBaseStyle.xaml
sed -n '5,7p'          /home/links-dev/hc-linux/src/Shared/HandyControl_Shared/Themes/Basic/Sizes.xaml
sed -n '105,107p'      /home/links-dev/hc-linux/src/Shared/HandyControl_Shared/Themes/Styles/TabControl.xaml
sed -n '59,61p'        /home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/Resources/Themes/Styles/Style.xaml
```

---

## §7 结论速览（≤12 行）

1. **`D-G58` 已确证根因**：首个（也是唯一失败原因）返回 `E_NOTIMPL` 的命令 = **`0x6c MilCmdPixelShader`**，
   在「工具」页 #2 `Effects` 加载那次 `Commit()` 的 **243 条批**里排 **#55**（`len=240`、`handle=0x4a4`）；同批另有 7 条 `0x70 MilCmdShaderEffect`。
2. `hr=0x80004001` ⇒ `exports.cs:376` 的 `HRESULT.Check` 抛 `NotImplementedException` ⇒ abort；`MediaContext.cs:2151 Channel.Commit();` 是栈上判定点。
3. 发送点：`PixelShader.cs:171/180-191`（`Generated/PixelShader.cs:140` 入口）、`ShaderEffect.cs:545/559-589`（`Generated/ShaderEffect.cs:162` 入口）。
4. 桥侧缺的**就是** `MilCommandLayout.cs:211-223` 里那两条登记（`:216`/`:217`）+ `MilCommandDispatcher.cs:38` 的短路 + `DispatchCore` 里**不存在**的两个 `case`（`:69`…`:1370 default`）；资源表 `MilResourceTable.cs:244` 也缺两个 `TYPE_*` case。
5. **桥/原生侧 0 命中**（`build/MilBridge/src`、`src/WpfGfx.Linux.Native/src` 里 `ShaderEffect|PixelShader` 一件都没有）= 没有渲染入口。
6. 成对读数：同趟 `#0/#1` 两页 notImpl **0** 且存活；`#2` notImpl **12** 且死。白名单趟用**另一台仪器**给出同样 12 条。
7. **`D-G57` 不是"字没画"，是"整块没画"**：选中页签连模板里那条 2 px 下划线都没有 ⇒ 该矩形**零绘制**（27 行逐行非众数像素全 0）。
8. 页签 74 px = `Padding 10,5`（`Sizes.xaml:7`）×2 + **内容 54 px** ⇒ **排除**"空串"与"ActualWidth=0 被裁剪"；
   同面板导航项有字（69 色）⇒ **排除**"整块面板没画"。
9. 受影响的**三处 `{ex:Lang}`**（页签 `TextBlock.Text`／`Button.Content`／`SearchBar.Placeholder`）与**正常的一处**（`HighlightTextBlock.SourceText`）同一文件；
   key 两条都确实存在（`LangProvider.cs:1041`/`:1026`）⇒ **键不是问题**。
10. **最后一格 `NOINFO`**：候选 =（a）该子树画刷解析成白 /（b）该子树绘制指令未进通道；**差一步 = 进程内读子件 `IsVisible/ActualWidth/Text/Foreground`**（§5.2 的最小探法）。
11. 所有读数挂在冻结 `#48` 五件上（开工=收工逐位相同）；本趟**未改仓内任何既有文件**。
12. 未做的事（如实）：`D-G57` 的翻极性实验**未做**；`D-G58` 的"放行后不 abort"**未实测**（§5.1 是方案）。

REPORT_SELF_SHA16=8387bde7f9a3fdae
