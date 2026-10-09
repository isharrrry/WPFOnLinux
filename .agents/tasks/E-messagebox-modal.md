# 任务 E：让 `MessageBox.Show` 真正弹出模态窗口并阻塞

## ① 任务目标

**现状（已定位，直接采信）**：`System.Windows.MessageBox.Show(...)` 在自产栈上**不弹窗、不阻塞**。调用链：
```
MessageBox.Show → MessageBox.cs:414
   MessageBoxResult result = Win32ToMessageBoxResult(UnsafeNativeMethods.MessageBox(new HandleRef(null, owner), messageBoxText, caption, style));
→ P/Invoke user32!MessageBox → shim src/WpfGfx.Linux.Native/src/win32_misc.c:538 MessageBoxW
   （注释自认：「模态对话框：X11 上没有，而且**绝不能阻塞**（headless 会死锁）… 写 stderr 并把内容当作
     「用户按了确定」返回 —— 这是刻意的降级」）
```
**目标**：让 `MessageBox.Show(...)` 在桌面上**弹出真正的模态窗口**，并在用户响应前**阻塞**（与 Windows 行为一致）。

### 已核实的机制（照抄即可）

- 该仓改上游源文件的方式是**生成式补丁**（幂等、带 `--check`）：
  样板 `src/WpfGfx.Linux.Native/tools/patch-presentationframework-window-minmax-notify.py`：
  - 读上游文件 → 插入/替换 → 写 `src/Microsoft.DotNet.Wpf.Linux/src/PresentationFramework/<Name>.Linux.cs`；
  - 接线：在 `…/PresentationFramework/PresentationFramework.Linux.csproj` 里
    `<Compile Remove="$(UpstreamWpfRoot)<上游相对路径>" />` + `<Compile Include="…/<Name>.Linux.cs" />`（插在 `Sdk.targets` 锚点前，用 MARKER 幂等）。
- 上游文件：`src/Microsoft.DotNet.Wpf/src/PresentationFramework/System/Windows/MessageBox.cs`（808 行；`Show` 核心在 `:414`；`Win32ToMessageBoxResult` 在同文件）。
- 自产 WPF 的 `Window`/`ShowDialog` 可用（任务 C 已验证主界面能开窗、能绘制、能响应输入）。
- 包：`WpfLinux.Sdk`，源 `$WpfLinuxRepoRoot/src/Linux/build/third-party/pkg/WpfLinux.Sdk.csproj`，产物 `pkg/out/`。改 `PresentationFramework` 后必须**重打包**（版本写死 1.0.0 ⇒ 清 `~/.nuget/packages/wpflinux.sdk`）。
- `$WpfLinuxRepoRoot=/home/links-dev/netTest/GitProj/WPFOnLinux`。

## ② 做法（指定路线，允许按实测调整并说明）

1. 新增 `src/WpfGfx.Linux.Native/tools/patch-presentationframework-messagebox.py`（样式照抄 window-minmax-notify 那份）：
   - 由上游 `MessageBox.cs` 生成 `MessageBox.Linux.cs`；
   - 把 `:414` 的 `UnsafeNativeMethods.MessageBox(...)` 改为调用自产实现（如 `System.Windows.WpfLinuxMessageBox.Show(owner, text, caption, style)`）；
   - **保持返回值语义**（返回 Win32 码交给现有 `Win32ToMessageBoxResult`，或等价改造）；
   - 幂等接线到 `PresentationFramework.Linux.csproj`。
2. 新增自产实现 `WpfLinuxMessageBox`（放 `src/Microsoft.DotNet.Wpf.Linux/src/PresentationFramework/WpfLinuxMessageBox.Linux.cs`，并接线进 csproj）：
   - 用自产 `Window` + `TextBlock`/`StackPanel` + 按钮行构建；
   - **`ShowDialog()` 阻塞**；
   - 支持 `MessageBoxButton` 全枚举与 `MessageBoxImage`（图标可用文本/简单图形，**不要求与 Windows 像素一致**）；
   - 支持 `defaultResult` 与 Enter/Esc；
   - 返回值与 Win32 码一致：`IDOK=1 / IDCANCEL=2 / IDABORT=3 / IDRETRY=4 / IDIGNORE=5 / IDYES=6 / IDNO=7 / IDTRYAGAIN=10 / IDCONTINUE=11`。
3. **非交互/无 DISPLAY 场景必须保持"降级不阻塞"**（写 stderr、返回默认值），避免 headless 死锁。这是硬要求。

## ③ 验收标准（可计算）

1. **弹窗**：最小工程（或复用 `ICDStudioSdkProbe`）调用 `MessageBox.Show("测试正文","测试标题",MessageBoxButton.OK)` ⇒ 出现窗口：截图 + OCR 能读出"测试正文"/"测试标题"（给 PNG 路径与 OCR 原文）。
2. **阻塞（硬判据）**：调用前打印 `BEFORE msgbox`、调用后打印 `AFTER msgbox`。**未点击时日志只有 `BEFORE`**；点击后 `AFTER` 才出现。给出**两段日志原文**。
3. **返回值**：`MessageBoxButton.YesNo` 点 Yes → `MessageBoxResult.Yes`；点 No → `No`（给日志原文）。
4. **不回归**：ICDStudio 主界面仍上屏（重跑任务 C 的验证：root 约 2243 色、`XamlParseException=0`）。
5. **重打包可复现**：给出 nupkg 新 sha256 与清缓存复跑命令。

## ④ 失败报告格式

- 每种方案 + 命令原文 + 原始输出片段；当前怀疑原因；上报即停止。

## ⑤ 完成报告格式

- 验收证据（可复跑命令 + 原始读数）；验收项 → 证据映射；未覆盖项如实列明。
- **主动披露**：与 Windows 行为的差异（图标、按钮文案、模态归属、键盘行为等）逐条列出。
- 自包含结论。

## ⑥ 环境

- `export PATH="$HOME/.dotnet:$PATH"`；Xvfb(:9x)+xfwm4+xdotool+xwininfo+import/identify 齐全；`rapidocr_onnxruntime` 已装（`python3 /tmp/ocr.py <png>`）。
- 驱动对话框的老坑：`xdotool mousemove` 与 `click` **必须分开**并留延迟（合并会让 release 被判 out-of-range）。
- `api.nuget.org` 不可达。
