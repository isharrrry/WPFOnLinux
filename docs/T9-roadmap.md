# T9 端到端路线评估（主控预判，待后续验证）

> **关键认知校正**：前 8 个 T 的目标是 **"Linux 上有可工作的 WPF 渲染后端"**，**不是** "WPF 托管层能跨平台"。
> 这是两件不同的事，不能混淆。下面三选一，正是因为混淆会出现"为什么 HelloWpf 跑不起来，是不是前面都白做了"的错觉——**不是白做了**，是目标分层。

## 路线 A1 · 全量移植托管层（不推荐为 M1 目标）
**目标**：完整把 `PresentationFramework`(474k) + `PresentationCore`(273k) + `WindowsBase`(44k) + `System.Xaml`(32k) 等 118 万行 C# 编译到 Linux，替换所有 Win32 P/Invoke。

| 维度 | 评估 |
|---|---|
| 工作量 | **数周到数月**。WPF 托管层有 96+24+22+11 = 150+ 处 user32/gdi32/kernel32/dwmapi 的 P/Invoke，含 HWND/HBITMAP/HANDLE 等 Win32 特定类型渗透整个代码库。需大量 stub 或重新实现。 |
| 可行性 | 技术上可行（.NET 跨平台），但**工程量等价于 Avalonia 早期的全部工作**。 |
| 价值 | **对 M1 无价值**。M1 验证的是"我们的 Linux 渲染后端正确"，不需要 WPF 托管层跑起来。 |
| 风险 | 高——可能撞到 HwndSource 这种深度耦合 Win32 的设计。 |

## 路线 A2 · 最小基座移植（中期目标，不属于 M1）
**目标**：只搬 `PresentationCore` + `WindowsBase` 的最小子集（DependencyProperty、Dispatcher、MediaContext、视觉树、CompositionTarget、Freezable 等），够支撑简单 XAML 程序。

| 维度 | 评估 |
|---|---|
| 工作量 | **数周**。需要识别"HelloWpf 用到的最小类型集合"，并补 Windows-only API 的 stub。 |
| 可行性 | 可行，但需要专门的设计工作（"托管层抽象窗口"之类）。 |
| 价值 | **M2 候选**。为把真实 WPF 程序搬到 Linux 打基础。 |
| 风险 | 中——会暴露 HwndSource/HwndTarget 等的深度耦合。 |

## 路线 A3 · 演示优先（★ M1 真正终点，推荐）
**目标**：不动 WPF 托管层，自己写一个 **HelloMil** —— 直接用我们的 `WpfGfx.Linux` API（`MilResourceProvider` + `MilSolidColorBrush` + `MilRenderData` + `SkiaRenderBackend` + X11 `IPresentationTarget`），构造视觉树、渲染、开 X11 窗口显示，截屏验证。

| 维度 | 评估 |
|---|---|
| 工作量 | **小时级**。所有底层组件已就绪（X11 真窗口、T5+T6 已验证），只需写个调用层。 |
| 可行性 | **已验证**——X11 端到端在 `x11_present_capture.png` 里已经跑通。 |
| 价值 | **M1 终点**。证明"在 Linux 上，从我们的 API 到真实像素到真实窗口到截屏验证"完整链路通。 |
| 风险 | 低。**关键认知**：HelloMil ≠ HelloWpf。前者是"我们的后端能工作"，后者是"WPF 托管层能跨平台"。M1 是前者。 |

## 推荐：A3
- 它直接回答 M1 的核心问题（**"我们的 Linux 渲染后端能否真正产出可见结果"**），并产出可视证据（HelloMil 截屏）。
- A1/A2 是**另一个项目的范畴**——它们的目标是"WPF 跨平台"，那是 Avalonia 在做的事，价值有数亿/年的工程量。
- 我们当前工程的目标分层：
  - **M1**（当前）：Linux 上有 Skia 渲染后端 + X11 窗口 + 文本 + 测试体系 → **A3 完成即达成**
  - **M2**：可选——A2 路线，把最小 WPF 托管层搬到 Linux
  - **M3**（如需要）：A1 路线，全量跨平台

## 与本工程"完成度"的对应
看进度看板里的「完成度速览」——
```
Contracts  100%    ← A3 所需
Interop    100%    ← A3 所需
Commands    67%    ← A3 只需部分（够构造视觉树即可）
Rendering  100%    ← A3 所需 ✅
Windowing  100%    ← A3 所需 ✅
Text       100%    ← A3 所需 ✅
```
A3 已具备所有组件，**只是没人去把它们串起来跑一次**。
