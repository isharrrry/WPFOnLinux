# 架构（architecture）

[English](architecture.md) | **中文** | [Español](architecture.es.md)

> 本文属于 **docs.Linux** —— 回 [移植侧文档总线](../README.zh-CN.md)（[English](../README.md) · [Español](../README.es.md)）。
> 逐工程落点见 [`../upstream/layout.zh-CN.md`](../upstream/layout.zh-CN.md)；覆盖层构成见 [`../upstream/linux-overlay.zh-CN.md`](../upstream/linux-overlay.zh-CN.md)。
> **深版**（含"为什么用替换式而不是 fork 式"、DPI/字体/资源管线/主题栈）见 [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md)（原始 / Windows 侧，中文单语）。

---

## 1. 30 秒版

```
upstream/wpf/**                 只读上游源（**不改**；唯一构建输入）
      │  build/port-lib.py       （剔除 Windows-only 源 + 纳入生成的 *.Linux.cs；**整体重写** csproj）
      ▼
build/<工程>.Linux/*.csproj  ──构建──▶  六个托管程序集
      │  应用器重放（src/WpfGfx.Linux.Native/tools/patch-*.py：补丁式接线，幂等 + --check + 锚点数断言）
      ▼
原生三件：libwpfwin32.so（Win32/GDI/OEM/GDI+ 面；能真做的真做，做不到的**如实失败**）
          libwpfwic.so  （WIC → Skia 解码桥）
          wpfgfx_cor3.so（AOT 的 milcore：渲染核心）
```

## 2. 四层

| 层 | 是什么 | 在哪 |
|---|---|---|
| **① 移植生成** | 把上游 csproj 变成 Linux 可编译 csproj（切 Arcade 继承、展开 `$(Wpf*Dir)`、剔除清单、资源管线、签名/身份） | `build/port-lib.py`、`build/port-pbt.sh`、`build/excludes/*.txt`、`build/Directory.Upstream.props` |
| **② 托管移植面** | 六个自产程序集（`pc` / `pf` / `windowsbase` / `system.xaml` / `dwf` / `provider`）＋ 各工程 `*.Linux.cs` 覆盖实现 | `build/<工程>.Linux/**`、`build/shims/**`、`src/WpfGfx.Linux/**` |
| **③ 原生 shim（C）** | Win32 / 消息 / GDI / OEM / GDI+ 面 ＋ WIC 桥 ＋ AOT milcore | `src/WpfGfx.Linux.Native/src/**`、`build/DirectWrite.Linux/**`、`build/MilBridge/**` |
| **④ 判据与门禁** | `verify-all.sh` 64 步 ＋ 107 件牙 ＋ 五臂对拍 ＋ 冻结基线 ＋ 缺陷登记 | `verify-all.sh`、`build/MilBridge/tools/**`、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`、`build/MilBridge/known-red.json` |

## 3. 数据流（一次渲染）

1. 应用（XAML）→ `PresentationFramework` → `PresentationCore` → **MIL 命令流**。
2. MIL 命令流进 `wpfgfx_cor3.so`（AOT milcore）：`src/WpfGfx.Linux/Commands/**` 解码/分发，`Resources/` 管资源与视觉树。
3. 绘制指令经 `Rendering/` 落到 Skia；字形由 `src/WpfGfx.Linux/Text/**` ＋ `build/shims/PresentationCore.HbTextLine.cs`（HarfBuzz 文本行）承担。
4. 窗口/消息/输入走 `src/WpfGfx.Linux.Native/src/win32_{core,msg,x11}.c` ↔ `src/WpfGfx.Linux/Windowing/**`（X11 呈现目标）。
5. 结果由 X11 合成上屏；验收侧用 `verify-all.sh`／样本 runner 真开窗、真截屏、真数色。

## 4. 权威物与"被看着的判据"

- **九位产物**：九个权威件的 sha16 逐位记在冻结块里；它们**不进 git** ⇒ 干净克隆必须重建。
- **冻结基线**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 是唯一权威；整份 sha **只由** `docs/CURRENT-STATE.md:9` 一行机器声明（现读 `gen=#82`）。
- **五臂对拍**：`tline`／`tab-*`／`textlineproto`，与 Windows 真值逐行比。
- **已知红**：`build/MilBridge/known-red.json` ＋ 声明表；红必须**登记过**。
- **"看仪器的仪器"**：门禁里包含引号陷阱、`pipefail` SIGPIPE 普查、覆盖面自检、根级条目允许清单等 —— 判据件自己也被看着。

## 5. 设计取舍（一句话各一条）

- **替换式而非 fork 式**：Windows 原生栈（`WpfGfx` 等）不做源码级条件编译，而是整个换成 Linux 实现 ⇒ 上游树保持干净、可 diff。
- **重写而非就地改**：csproj 是**生成物**，接线走应用器 ⇒ "改了但没生效"这类事故可以被审计咬住。
- **旁挂而非混放**：Linux 面在 `src/**`、`build/shims/**`、`build/*.Linux/**`，上游在 `upstream/wpf/**` ⇒ 用户按目录后缀选平台。
- **能真做的真做，做不到的如实失败** ⇒ 不许用谎话换绿屏。

---

[English](architecture.md) | **中文** | [Español](architecture.es.md) · [移植侧文档总线](../README.zh-CN.md) · [Linux 覆盖层](../upstream/linux-overlay.zh-CN.md) · [贡献](contributing.zh-CN.md)
