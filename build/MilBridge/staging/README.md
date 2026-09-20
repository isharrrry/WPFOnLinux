# ⚠️ 本目录是**历史快照/暂存副本**，不是可编译源

## ㈠ 快照身份 = **内容 sha256 = 版本号**
- `PresentationCore.HbTextLine.cs` 的**自身 sha256 = `c580f2df9362de55…`**
  （**注意：这个值与文件名无关** —— 本目录没有把版本号写进文件名，所以只能靠 sha 认身份）。
- 复核命令：`sha256sum build/MilBridge/staging/PresentationCore.HbTextLine.cs`
- ⇒ 它里面的数字只对**它自己那一版**成立。

## ㈡ 真源是 `build/shims/`，不是这里
真源 = **`build/shims/PresentationCore.HbTextLine.cs`**（`build/MilBridge/run.sh` 里写死
`SHIM="$MB/../shims/PresentationCore.HbTextLine.cs"`）。
⚠️ `handoff.md:1349` 曾写"本目录那份 = **全部拉丁回归读数的地基**" —— **该说法与现场冲突**：
全仓 `grep` 对 `MilBridge/staging` 在 `*.sh|*.py|*.csproj|*.cs` 里 **0 命中**，没有任何脚本/工程编译它；
真正被 `HbTextLineParity` / `T2e` / `TextLineProto` 编译的是 `build/shims/…`（经 `-p:HbShimSrc=`）。

## ㈢ 两条禁令
1. **不许修改本目录任何 `.cs` 的内容**（理由同 ㈠：会与它自己的内容 sha 自相矛盾）。
2. **不许把它当编译源**（没有脚本引用它；真源见 ㈡）。

> 主控 2026-09-15 裁定：**快照内容一个字都不许改**；本 README 是**新增文件**，未触碰任何快照。
