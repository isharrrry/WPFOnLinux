# ⚠️ 本目录是**逐字节历史快照**，不是可编译源

## ㈠ 快照身份 = **内容 sha256 = 版本号**
- `PresentationCore.HbTextLine.ebccdb1e.cs` 的**自身 sha256 = `ebccdb1ee65e6f76…`**
  ⇒ **文件名里的 `ebccdb1e` 就是它的内容 sha**，也正是当日读数里登记的被测件 sha
  （`samples/WpfFeatureProbe/rtl-baseline-20260913.json`：`hbtextline_shim_sha=ebccdb1ee65e6f76`）。
- 复核命令：`sha256sum build/MilBridge/tests/CoverageProbe/refs/PresentationCore.HbTextLine.ebccdb1e.cs`
- ⇒ 它里面的数字（例如"仍真欠账的 **6** 个"）**在那份 shim 上是真话**。

## ㈡ 真源是 `build/shims/`，不是这里
真源 = **`build/shims/PresentationCore.HbTextLine.cs`**（`build/MilBridge/run.sh` 里写死
`SHIM="$MB/../shims/PresentationCore.HbTextLine.cs"`）。要读"当前实现/当前欠账数"，**去那里读**。

## ㈢ 两条禁令
1. **不许修改本目录任何 `.cs` 的内容** —— 改它 = **篡改一份字节自证的历史记录**
   （数字会与它自己声明的版本号 `ebccdb1e…` 自相矛盾）。
2. **不许把本目录的 `.cs` 当编译源** —— `CoverageProbe.csproj` 只编 `$(HbShimSrc)` + `Program.cs`
   （`EnableDefaultCompileItems=false`）；全仓 `grep` 对 `refs/` 在 `*.sh|*.py|*.csproj|*.cs` 里 **0 命中**。

> 主控 2026-09-15 裁定：**快照内容一个字都不许改**；本 README 是**新增文件**，未触碰任何快照。
