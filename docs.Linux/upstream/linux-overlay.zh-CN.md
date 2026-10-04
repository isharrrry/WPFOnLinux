# Linux 覆盖层（我们把上游的哪一半"另写了一份"）

[English](linux-overlay.md) | **中文** | [Español](linux-overlay.es.md)

> 本文属于 **docs.Linux** —— 回 [移植侧文档总线](../README.zh-CN.md)（[English](../README.md) · [Español](../README.es.md)）。
> 对照表见同目录 [`layout.zh-CN.md`](layout.zh-CN.md)（21 个上游工程逐行）。

**一句话**：上游 `dotnet/wpf` 一棵树在仓里有**两个位置** —— `upstream/wpf/**`（**只读源**，构建的输入）
与**覆盖层**（本仓新增的那一半）。覆盖层不是"改上游"，而是"**旁挂**"：
上游源**一个字节不动**，我们新增的件落在 `src/**`、`build/shims/**`、`build/*.Linux/**` 与应用器里。

---

## 1. 覆盖层的四块

1. **托管移植码** —— `src/WpfGfx.Linux/**`
   `WpfGfx.Linux.csproj`（叶子工程，放在重建序最前）+ 七个功能目录：
   `Commands/`（MIL 命令解码/分发/布局）、`Contracts/`（`MilCmd`/`MilDrawCommand`/`MilPrimitives` 等）、
   `Interop/`（`Duce`/`HResult`/`MilEnums`）、`Rendering/`（绘制指令普查、字形运行普查、路径几何解析）、
   `Resources/`（`MilChannel`/`MilResourceTable`/`MilVisualNode`）、`Text/`（`GlyphRunLayout`/`GlyphRunPainter`/字体集）、
   `Windowing/`（`X11Display`/`X11PresentationTarget`/`WindowEvent`/`X11Native`）。
2. **原生 shim（C）＋ 应用器** —— `src/WpfGfx.Linux.Native/**`
   `src/win32_*.c`（`win32_core`／`win32_msg`／`win32_x11`／`win32_gdiplus`／`win32_oem`／`win32_pts`／`win32_exports`／`win32_unicode_tables`／`win32_classification`）、
   `include/`、`build-shim.sh`（构 `libwpfwin32.so` 并出 `exports.txt`）、
   `tools/patch-*.py`（**应用器**：把接线补丁式写进生成物，幂等 + `--check` + 锚点数断言）与 `tools/wire-*.py`（预应用器）。
3. **工程级 shim 与生成件** —— `build/shims/**`（`*.Shim.cs` ＋ 每工程一份 `<工程>.shims.txt` 清单，清单 → csproj 这一步由 `port-lib.py` 干）、
   `build/<工程>.Linux/*.Linux.cs`（各工程的 Linux 覆盖实现，例如 `HwndSource.Linux.cs`／`FlowDocumentView.Linux.cs`／`Dispatcher.Linux.cs`）、
   `build/<工程>.Linux/ARTIFACT-SRC-FP.txt` 与 `PORT-CHANGES.md`。
4. **构建侧设施** —— `build/port-lib.py`（**整体重写** csproj）、`build/integration-wave.sh`（移植＋构建唯一入口）、
   `build/excludes/*.txt`（实测过的剔除清单）、`build/*.props`（`Directory.Upstream.props` 切断 Arcade 继承；`SelfBuiltConfig.props` 是 Release 的唯一声明）、
   `build/DirectWrite.Linux/**`（DirectWrite/WIC 桥、`wic-shim/`、`Provider/` 与探针）、`build/third-party/**`（第三方接入配方 `WpfLinux.props`）、`build/MilBridge/**`（AOT milcore 桥 ＋ 五臂 ＋ 门禁与冻结工具）。

## 2. 原生三件：上游那一半的"替换实现"

- `libwpfwin32.so` —— Win32 / 消息 / GDI / OEM / GDI+ 面的 shim（**口径**：能真做的真做，做不到的**如实失败**，不假装成功）。
- `libwpfwic.so` —— WIC → Skia 解码桥（源在 `build/DirectWrite.Linux/wic-shim/`，含 `wic_proxy.c` 与探针）。
- `wpfgfx_cor3.so` —— **AOT 的 milcore**（渲染核心；上游侧对应的是 `WpfGfx/` 的 VC++ 原生实现）。

三者都**不进 git**（`src/WpfGfx.Linux.Native/bin/` 被 `.gitignore` 忽略）⇒ 干净克隆**必须重建**：
`bash src/WpfGfx.Linux.Native/build-shim.sh` · `bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh` · `bash build/MilBridge/run.sh build`。

## 3. 三条硬边界（覆盖层不许越线）

- **不许改上游源**：`upstream/wpf/**` 是**只读**；改它会让"上游字节可复算"这条证据作废（指纹口径见 [`docs/UPSTREAM-PROVENANCE.md`](../../docs/UPSTREAM-PROVENANCE.md)）。
- **不许手改生成物**：`build/*.Linux/*.csproj` 是 `port-lib.py` 的产物，手改会在下一次重生成时**被抹掉且不报错** ⇒ 接线只能落在**应用器**。
- **不许静默降级**：做不到的必须**具名**（返回错误码 / 留只读台账），在册缺陷册与门禁都按这个口径判。

## 4. 命名与"下一步"（对齐上游这件事的现状）

- **命名规则**（评审口径，冻结件 [`../design/_PHASE0-NAMING-CONVENTION.md`](../design/_PHASE0-NAMING-CONVENTION.md)）：
  全仓每类东西成对 —— `X`（原始 / Windows 侧）＋ `X.Linux`（linux 侧）；文档 `docs` / `docs.Linux`，
  源码（目标形态）`src/Microsoft.DotNet.Wpf` / `src/Microsoft.DotNet.Wpf.Linux`，脚本 `Guide` / `Guide.Linux`。
  **用户只需认一个目录后缀选平台**，不必在每层目录里挑文件。
- **已定的路线**是"**A ＋ C**"：A ＝ 先把**映射层**写清（本页与 [`layout.zh-CN.md`](layout.zh-CN.md) 就是 A 的产物），
  C ＝ 将来把 Windows 源搬进 `src/Microsoft.DotNet.Wpf/**`（**编译用**）、`upstream/wpf/**` 保留为**字节校验副本**或换成"逐件清单"。
  施工分阶段与验收见 [`docs/UPSTREAM-ALIGN-PLAN.md`](../../docs/UPSTREAM-ALIGN-PLAN.md)（**提案**；本页不代其宣布落地）。
- ⚠️ **别把"映射"读成"已搬"**：今天物理布局仍是"`upstream/wpf/**` 只读源 ＋ `build/*.Linux/**` 生成工程"，
  `src/` 下**只有**移植新增件（`WpfGfx.Linux`、`WpfGfx.Linux.Native`）。

---

[English](linux-overlay.md) | **中文** | [Español](linux-overlay.es.md) · [移植侧文档总线](../README.zh-CN.md) · [上游布局对照](layout.zh-CN.md)
