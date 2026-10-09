# 任务 C：让 ICDStudio 主界面"工作区 + Ribbon"真正上屏（补自产栈兼容能力）

## ① 任务目标

**现象（主控已实测，直接采信，无需重复）**：
- 用包化接入的 `ICDStudioSdkProbe` 在 Xvfb+xfwm4 上能跑到**主界面**：窗口 `ICD Studio-[管理员]Admin` 1280x1024 出现，整屏截图 **631 色**（非全黑）。
- **但主界面内容区是空的**：OCR 只读出标题 `ICDStudio-[管理员jAdmin`，读不出工作区/菜单/树/文档区任何文字。
- 运行日志有**未处理异常**（原始堆栈，逐字）：
  ```
  [wpfwin32] MessageBox(降级，不阻塞): [[UI]未预料异常！] System.Windows.Markup.XamlParseException: Provide value on 'System.Windows.Baml2006.TypeConverterMarkupExtension' threw an exception.
   ---> System.Runtime.InteropServices.COMException (0x80004005): Unexpected HRESULT has been returned from a call to a COM component.
     at MS.Internal.HRESULT.Check(Int32 hr)
     at System.Windows.Media.Imaging.BitmapDecoder.SetupDecoderFromUriOrStream(...)
     at System.Windows.Media.Imaging.BitmapDecoder.CreateFromUriOrStream(...)
     at System.Windows.Media.Imaging.BitmapFrame.CreateFromUriOrStream(...)
     at System.Windows.Media.ImageSourceConverter.ConvertFrom(...)
     at MS.Internal.Xaml.Runtime.ClrObjectRuntime.CallProvideValue(...)
     at System.Windows.FrameworkTemplate.LoadTemplateXaml(...)
     at System.Windows.FrameworkTemplate.LoadOptimizedTemplateContent(...)
     at System.Windows.StyleHelper.ApplyTemplateContent(...)
     at System.Windows.FrameworkElement.ApplyTemplate()
     at System.Windows.FrameworkElement.MeasureCore(Size availableSize)
     ...
     at System.Windows.ContextLayoutManager.UpdateLayout()
     at System.Windows.Media.MediaContext.InvokeOnRenderCallback.DoWork()
  ```
  ⇒ 这是**控件模板里一个 `<Image Source="…"/>` 的位图解码失败**，异常让整棵模板可视子树建不起来 ⇒ 工作区/按钮不上屏。
  **注意**：这**不是**先前报告里怀疑的 AvalonDock `HwndHost`/`SetRootVisual` 问题（`BringWindowToTop` 已在 `src/WpfGfx.Linux.Native/src/win32_core.c:1539` 补上）。当前阻塞点更靠前：**图片解码**。

**本任务目标**：**定位那张失败的图片并修好解码路径**，使 ICDStudio 主界面内容真正上屏。

**验收的最终目标（判据见 §③）**：主界面工作区（AvalonDock 工作空间树 + 文档区）与顶部 Ribbon 按钮能画出来——**用 OCR 能读回预期控件文字**为准。

### 已在事实与线索

- 自产栈仓根 `$(WpfLinuxRepoRoot)=/home/links-dev/netTest/GitProj/WPFOnLinux`。
- 相关源码：
  - 解码调用链上游：`$WpfLinuxRepoRoot/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/Imaging/BitmapDecoder.cs:999`（`SetupDecoderFromUriOrStream`）
  - WIC 代理实现（自产）：`$WpfLinuxRepoRoot/src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/wic-shim/wic_proxy.c`（130 KB）
  - WIC shim 构建脚本：同目录 `build-wic-shim.sh`；产物 `libwpfwic.so`
  - 该目录下已有诊断工具：`probe_decode`（+`probe_decode.c`）、`frames-check.sh`、`fixtures-jfif.jpg` 等，**优先复用**
- **主控的诊断脚手架（可直接复用/改造）**：
  - `/tmp/cdiag.sh`：部署 + 起 Xvfb(:97)+xfwm4 + 跑 + 截 root
  - `/tmp/cdiag2.sh` / `/tmp/cdiag3.sh`：驱动（OCR 定位并点「继续试用」→ 等主窗体 → 截图）
  - `/tmp/ocr.py`：`python3 /tmp/ocr.py <png>` 输出每段文字的"中心坐标 + 置信度 + 文本"（`rapidocr_onnxruntime` 已装）
  - 驱动要点（踩过的坑）：`xdotool mousemove` 与 `click` **必须分开**并留延迟（合并会让 release 被判 `out-of-range`，按钮不响应）；授权对话框「继续试用」在 root 坐标约 `(386,432)`。
- 已知既有边界（来自该仓既有报告）：WIC 解码"**只读族真做、写族/流式如实失败**"；PNG/JPEG 的只读解码应已支持。所以**先搞清楚失败的到底是哪种图片、哪条路径**，不要预设。

## ② 边界条款

- **允许修改/新增**：`$WpfLinuxRepoRoot/src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/wic-shim/**`、`$WpfLinuxRepoRoot/src/WpfGfx.Linux.Native/**`、以及为定位所需在 `$WpfLinuxRepoRoot` 下的**新增**诊断件。
- **禁止改动**：`RT/Links-*` 的**业务源码**与既有 wrapper/`*.Sdk.csproj`（它们是验证对象，不是修改对象）。若确需改 `RT` 下文件，改动 ≤1 处且 ≤1 行，并在报告"有意差异记账"里列出。
- **不做**：不改 `WindowsBase/PresentationCore/PresentationFramework` 的**语义**（除非定位证明必须）；不改构建体系。
- 同一问题最多试 **2~3 种**方案；仍失败则如实上报（"确认失败"是合法终点）。

## ③ 验收标准（只写可计算判据）

**必达**
1. **定位证据**：给出失败图片的确切身份（URI / 文件名 / 所属程序集或模板）+ 失败原因（如"格式 X 未实现""路径 Y 解析错"），并给出**最小复现命令**（例如 `probe_decode <该图片>` 的原始输出）。
2. **修复后主界面内容上屏**：主窗体截图（`xwd -root` 或窗口截图）的 OCR **能读出工作区/菜单的预期文字**（至少 3 个来自业务界面的词，如菜单项名、树节点名）。报告里给出 OCR 原始输出。
3. **异常消失**：修复后运行日志中 `XamlParseException` / `BitmapDecoder` 相关异常计数 = 0（给出 `grep -c` 读数）。

**不回归**
4. 登录界面仍能出现（截图存在且色数 ≥100）。
5. `ICDStudioSdkProbe` 仍能编译（0 错误）并启动（存活 ≥10s）。

## ④ 失败报告格式

- 每种已尝试方案：命令原文 + 原始输出片段（引用原文，不得转述）。
- 当前怀疑原因；若结论是"自产栈能力缺口 X，修它需 Y（超出本任务）"，写明并停止。
- 上报即停止，等待决策；禁止伪造通过。

## ⑤ 完成报告格式

- 验收证据：判据 1/2/3 的可复跑命令 + 原始输出（含 OCR 原始文本、`grep -c` 读数）。
- 验收项 → 证据映射：逐条对应，未覆盖项如实列明。
- 差异记账：对 `RT/**` 的任何改动（`文件:行` / 原 / 新 / 原因）。
- **主动披露**：规格与事实不符、修完仍缺什么、下一个阻塞点是什么（如果有）。
- 自包含结论：背景、改了什么、验证了什么、遗留什么。

## ⑥ 工具与环境

- `export PATH="$HOME/.dotnet:$PATH"`；Xvfb/xfwm4/xdotool/xwininfo/import/identify 齐全；`rapidocr_onnxruntime` 已装。
- 头部提示：先做**定位**（哪个图片、哪条路径、为什么 E_FAIL），再动手修。**定位不明的修改一律视为猜测**，请避免。
