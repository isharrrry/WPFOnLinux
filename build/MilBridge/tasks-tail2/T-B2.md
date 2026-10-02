# 任务 T-B2 · `WIN-INTEROP.md` §7.5 的 **L1 路线①**：Linux 版 `Microsoft.WindowsDesktop.App` shared framework —— 实现

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。照 `/home/links-dev/netTest/GitProj/WIN-INTEROP.md` **§7.5 建议（L1）** 与 **§7.2 路线①**：打造 **Linux 版 `Microsoft.WindowsDesktop.App` shared framework 目录**，使**源码重编产物**可 `dotnet YourApp.dll`（`runtimeconfig` **不必改**）：

```
<dotnet root>/shared/Microsoft.WindowsDesktop.App/<与官方对齐的 10.0.0.x>/
    ├── 自产 12 件（PresentationFramework / PresentationCore / WindowsBase / System.Xaml / …，逐件点名）
    ├── Microsoft.WindowsDesktop.App.deps.json        ← 自造（仿 Microsoft.NETCore.App 的形态）
    ├── Microsoft.WindowsDesktop.App.runtimeconfig.json
    └── 原生件落点（libwpfwin32.so / libwpfwic.so / wpfgfx_cor3.so / libSkiaSharp.so）
```

**必做**（§7.6 的前置验证，逐条给现取）：① host 对框架目录的**清单要求**（`deps.json` 最小内容；版本号须**与官方对齐**，见 §7.2 末）；② `.so` 在**框架目录**里能否被现有 resolver 搜到（`Win32ShimResolver.cs:520-537`／`MilCoreDllImportResolver.cs:101-151`）；③ 若不够 ⇒ 只**加搜索路径**（不许改语义）。

**硬边界**：永不假成功/零假值；**不许**改 `upstream/**`；`P8`；副本先行；写前 `cp -p`；**先在沙箱副本上演练**（别直接写真实 dotnet root 的**不可回滚**改法）；两极化（撤掉框架目录 ⇒ 必回原始报错 `No frameworks were found`）。

## ② 边界条款
- 只改：`build/third-party/**`（新脚本／props）／`docs/**`（记录）／仓外 `<dotnet root>/shared/Microsoft.WindowsDesktop.App/**`（**新增**，须可整目录回滚）／新建载体 `build/MilBridge/P1-wininteropL1-impl-report.md`。
- 黑名单：`upstream/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`src/**`。
- 重活走槽；进程只按 PID；禁 sleep 轮询；temp+rename；模式守恒。

## ③ 验收标准（可计算）
- ① 前置三项逐条现取（件:行／实测）；② **端到端**：一个**源码重编**的 WPF 应用（用 `samples/WpfTextDemo` 或 §7.1 的 `/tmp/wincompat/exp1`）在**未改 runtimeconfig** 下 `dotnet <app>.dll` **跑起来**（给命令＋输出＋rc）；③ **反极性**：撤框架目录 ⇒ 原始报错原文复现；④ 12 件 ＋ 4 原生件逐件在位（`sha16`）；⑤ 给出**一条命令**的安装／卸载脚本（可回滚）；⑥ 具名 `NOINFO`（真 Windows 端到端本机不可得须记）。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有。
