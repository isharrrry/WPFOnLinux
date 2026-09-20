# W22D 报告 —— 只读盘点三件（`D-A2` 副本普查 / `D-T5` 异常是否到应用层 / `D-F2` 三计数器精确改法）

> **lane=W22D**｜**2026-09-16 19:41 → 19:5x +0800**｜`loadavg` **4.03 3.07 1.59**（开工 `3.39 0.98 0.47`；本波另有两条车道在构建）｜`MemAvailable` **3,283,436 kB**（开工 3,519,436 kB）｜`kernel 6.8.0-138-generic`｜`nproc=3`。
> **硬约束遵守**：**全程零 `dotnet`**（build/run/restore/msbuild 一次都没跑）；**仓库内既有文件零改动**（只写了本报告 `build/MilBridge/W22D-report.md`）；临时脚本/输出全在 `$HOME/w22d-scratch/`；**没有 `pkill -f`**。
> **写了什么**：本文件（一个）。**读了什么**：见 §4 的"仪器与读数表"（每件都连 sha16）。
> **本波基线**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 表头 **`0d048e6e8808c4e7`**（= `#21`，现场复算一致）；`hbtextline 76089e1de586ac91`、`pc e7cabff9417ed380`、`pf 2fb1a896f8277647`、`bridge d567c26f197ec1e3`。

---

## 0. 三件结论（先行）

| 件 | 一句话结论 | 关键数字 |
|---|---|---|
| **1 `D-A2`** | **`PresentationCore.dll` 有 33 份副本，其中 32 份非权威副本的判据数 = 0**（连 sha 都不打印）；**其中 17 份今天已经是旧世代**。另有 **2 份 `wpfgfx_cor3.so`** 在"件"里但**权威为空** ⇒ 逐份不判（只有互比）。**我把"接线之后会红多少"实测出来了：模拟接线 ⇒ 立刻 17 份红**（不是"白拿"，也不是"一片红"）。 | **34 份"连 sha 都没有任何判据盯"（32 PC + 2 so）**；扩展口径（含分支豁免）= **49 份** |
| **2 `D-T5`** | **会传到应用层。** 从 `LoCreateContext` 到 `WpfTextDemo` 进程**没有任何一层 catch**（逐层给 file:line + 该层的 try/finally 形态），并且**在册实测就是进程级 `exit=134`**。⇒ **按派单规则：升为下一波第 1。** **外加一条新发现**：这一族**比在册描述更宽** —— `TextHidden`（`Length ≥ 1`，CBR 同样是默认空 buffer）机制完全相同，而**上游 `pf` 自己在每个内联元素边缘就产它**。 | 3 层无 catch + 1 层（Dispatcher）默认重抛；`nm -D libwpfwin32.so` 里 `LoCreateContext` = **0**（正对照 `GetWindowLongPtrWrapper` = 1） |
| **3 `D-F2`** | 在册三句话**逐字为真**（三个计数器只自增、`SummaryFragment()` 一个都没有、`capped=` 零打印点）；**精确改法 = `SummaryFragment()` 里 +3 行**（含一个"必须放在 `candidates=` **之后**"的顺序陷阱）。**不改任何门禁判据行**（门禁完全不读 `HB_TEXTLINE`），但**改 shim = 付世代成本**。 | `+3` 行（最小）／`+4` 行（含 `plan=0` 早退分支的诚实版） |

---

# 件 1 · `D-A2`：有多少副本"陈旧也不会红"

## 1.1 我用的仪器（都读过、都记 sha16）

| 仪器 | sha16 | 我做了什么 |
|---|---|---|
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | **`aad23482f84bdf44`** | **跑了**（脚本头部逐字自述"只打印 + 校验；**绝不改写任何目录**"）；输出 `$HOME/w22d-scratch/appsync.out`（170 行），tail 逐字 `APPSYNC=MISMATCH … APPSYNC_RC=1` |
| `build/DirectWrite.Linux/wic-shim/applocal-expect.py` | **`6eafbea14e7ea41e`** | **跑了**（`python3 … "$PWD"`，rc=0）；输出 `$HOME/w22d-scratch/expect.out` |
| `build/shims/PresentationCore.HbTextLine.cs` | **`76089e1de586ac91`** | 读；`nm -D` 查 `libwpfwin32.so` 导出（件 2） |
| 我的普查脚本 / 模拟脚本 | `table.py`（临时，未记 sha）｜`$HOME/w22d-scratch/expect-pc.py` **`faa01dd7a5e713cc`** | 后者是 `applocal-expect.py` 的**私有拷贝**（只加一行 PC 项），**仓内文件一个字节未动** |

**两条机制（照主控 `#21` 的更正写，不抄错机制）**：
- ① `PresentationCore.dll` **根本不在 `ITEMS`**（`:97-104` 是 **6** 项：`libwpfwic.so`／`libwpfwin32.so`／`DirectWrite.Linux.Provider.dll`／`WpfGfx.Linux.dll`／`ReachFramework.dll`／**`wpfgfx_cor3.so`（权威为空）**）；
- ② `wpfgfx_cor3.so` 的权威串**是空的**且**显式写明不覆盖**（`:103`），逐份判定在 `:205` `[ -z "$exp" ] && { echo "    $note"; continue; }` **早退**。
- （`SCAN_ROOTS`（`:93`）**包含** `$REPO/build` ⇒ `.artifacts/**` **在扫描范围内**。上一波"不含 `.artifacts`"的说法是错的，我已按正确机制写。）

## 1.2 分支语义（把"没有判据"说到具体分支）

| 分支 | 行 | 条件 | 后果 |
|---|---|---|---|
| `ITEMS` 外 | `:201` | 件不在 `ITEMS` | **逐件循环根本不为它执行 ⇒ 一份都不扫、sha 不打印、不计数**（不是"判绿"） |
| 权威空 | `:205` | `ITEMS` 里但权威串为空 | 打印一行说明后 `continue` ⇒ **逐份一条都不判**；仅进"跨副本一致性"分组 |
| ① 引用程序集 | `:217` | `*/obj/*/ref/*`｜`*/obj/*/refint/*` | `SKIP(ref)`（不判；每件一行汇总"引用程序集 N 份"） |
| ② 循环桩 | `:220` | 路径含 `CycleStub.*`／`CycleStub` | `SKIP(stub)`（**按路径豁免**，不看内容） |
| ③ obj 中间件 | `:227` | 路径含 `/obj/` | `SKIP(obj)`：**逐条打印 sha**，但**不判** |
| ④ 跨配置 | `:235` | `is_release_path` **且** **权威是 Debug** | `NO-AUTHORITY`（判不了、**不算不一致**、`exit 0`） |
| ⑤ 库输出 | `:243` | 托管件 ∧ 目录无 `*.runtimeconfig.json` ∧ 目录不被 HintPath 引用 | `LIB-COPY`（不是加载源，不判） |
| ⑥ 同类加载源 | `:250-286` | 否则 | `OK`／`STALE`／`NEWER-DIFF`（判）；`:262` 另判 `UNEXPECTED-EQ/DIFF`（红） |

## 1.3 表 A：`PresentationCore.dll` —— **33 份**（权威 = `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` = **`e7cabff9417ed380`**，4,196,864 B）

> **"有没有判据盯它"这一列 33 行全相同，我先写一次**：**无** —— 点名 = *`check-applocal-sync.sh:97-104` 的 `ITEMS` 不含该件 ⇒ `:201` 的逐件循环不为它执行*；**并且** `applocal-expect.py:42-48` 的 `ITEMS`（6 项，同一组）也不含它 ⇒ **删掉任何一份连 `MISSING` 都不会报**（`#16` TAPPS 实测过这一点，我今天复核：模拟输出 `#EXPECT` 里 `PresentationCore.dll` 条目数 = **0**）。

| # | 副本路径（`$R/` 之后） | sha16 | sha 相同? | 有没有判据盯它 |
|---|---|---|---|---|
| 1 | `build/CycleStub.PresentationFramework.Linux/bin/Debug/PresentationCore.dll` | `e7cabff9417ed380` | **相同** | **无**（且将来若接线，会被 `:220` 的**路径**豁免判成 `SKIP(stub)` —— 而它的**内容就是权威件**） |
| 2 | `build/CycleStub.PresentationUI.Linux/bin/Debug/PresentationCore.dll` | `e7cabff9417ed380` | **相同** | **无**（同上，路径豁免） |
| 3 | `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/PresentationCore.dll` | `c0763fc10173e7ff` | **不同**（`#16` 世代） | **无** |
| 4 | `build/DirectWrite.Linux/FontEntryClosedLoop/bin/Debug/PresentationCore.dll` | `23567d420f0dbbaa` | **不同** | **无** |
| 5 | `build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/PresentationCore.dll` | `23567d420f0dbbaa` | **不同** | **无** |
| 6 | `build/DirectWrite.Linux/WicClosedLoop/bin/Debug/PresentationCore.dll` | `23567d420f0dbbaa` | **不同** | **无** |
| 7 | `build/DirectWrite.Linux/WicWriteClosedLoop/bin/Debug/PresentationCore.dll` | `23567d420f0dbbaa` | **不同** | **无** |
| 8 | `build/DirectWrite.Linux/WiringSmoke/bin/Debug/PresentationCore.dll` | `23567d420f0dbbaa` | **不同** | **无** |
| 9 | `build/MilBridge/tests/CompositeFontProbe/bin/Release/PresentationCore.dll` | `684424fea3a0812a` | **不同** | **无** |
| 10 | `build/MilBridge/tests/ContractProbe/bin/Release/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 11 | `build/MilBridge/tests/CoverageProbe/bin/Debug/PresentationCore.dll` | `9adac6b8d8e285c3` | **不同**（`#14` 世代） | **无** |
| 12 | `build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 13 | `build/MilBridge/tests/DirectBranchCheck/bin/Release/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 14 | `build/MilBridge/tests/FrameProbe/bin/Release/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 15 | `build/MilBridge/tests/HbTextLineParity/bin/Debug/PresentationCore.dll` | `f4a454c8fe69cdfe` | **不同**（`#19` 世代） | **无** |
| 16 | `build/MilBridge/tests/HbTextLineParity/bin/Release/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 17 | `build/MilBridge/tests/MinMaxProbe/bin/Release/PresentationCore.dll` | `14086882b1509dcd` | **不同**（`#17` 世代） | **无** |
| 18 | `build/MilBridge/tests/PcLineOracle/bin/Release/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 19 | `build/MilBridge/tests/StrictTierProbe/bin/Release/PresentationCore.dll` | `f4a454c8fe69cdfe` | **不同** | **无** |
| 20 | `build/MilBridge/tests/T2eLineHeight/bin/Release/PresentationCore.dll` | `684424fea3a0812a` | **不同** | **无** |
| 21 | `build/MilBridge/tests/TextLineProto/bin/Debug/PresentationCore.dll` | `f4a454c8fe69cdfe` | **不同** | **无** |
| 22 | `build/MilBridge/tests/TextLineProto/bin/Release/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 23 | `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `e7cabff9417ed380` | —— **这就是权威件本身** | **无**（也不需要） |
| 24 | `build/PresentationCore.Linux/obj/Debug/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无**（接线后会走 `:227` `SKIP(obj)`，**只打印不判**） |
| 25 | `build/PresentationFramework.Classic.Linux/bin/Debug/PresentationCore.dll` | `95a669cc510337d1` | **不同**（4,068,864 B，**另一份 PC 构建**，非"旧版同一件"） | **无** |
| 26 | `build/PresentationFramework.Linux/bin/Debug/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 27 | `build/ReachFramework.Linux/bin/Debug/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 28 | `build/System.Printing.Linux/bin/Debug/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 29 | `samples/HelloWpf/bin/Debug/net10.0/PresentationCore.dll` | `f31822ce4a3e510d` | **不同** | **无** |
| 30 | `samples/HelloWpf/bin/Release/net10.0/PresentationCore.dll` | `9adac6b8d8e285c3` | **不同** | **无** |
| 31 | `samples/WpfFeatureProbe/bin/Debug/net10.0/PresentationCore.dll` | `9adac6b8d8e285c3` | **不同** | **无** |
| 32 | `samples/WpfTextDemo/bin/Debug/net10.0/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |
| 33 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/bin/Debug/net10.0/PresentationCore.dll` | `e7cabff9417ed380` | 相同 | **无** |

**汇总**：33 份 = 1 份权威 + **15 份内容相同** + **17 份内容不同**（**8 个不同的旧世代**：`23567d420f0dbbaa`×5、`9adac6b8d8e285c3`×3、`f4a454c8fe69cdfe`×3、`684424fea3a0812a`×2、`c0763fc10173e7ff`×1、`14086882b1509dcd`×1、`95a669cc510337d1`×1、`f31822ce4a3e510d`×1）。

> **⚠️ 快照口径（纪律 23 的现场）**：本表是 **2026-09-16 19:44＋0800 的一次快照**。收官时我复核写入域，发现**另一条车道在我普查期间正在重建 `build/MilBridge/tests/FrameProbe/obj|bin`**（`obj/Release/*` 一批文件在 12 分钟窗口内被写过）⇒ **表 A 第 14 行（`FrameProbe/bin/Release`）那一格是时间敏感的**（它当时 == 权威；重建后可能变，也可能不变）。**其余 32 行的目录在我的窗口内没有写入迹象**。凡要引用本表，先按 §1.1 的两条命令现场重算。

## 1.4 表 B：`wpfgfx_cor3.so` —— **2 份**（`ITEMS:103` 权威串**为空**）

| 副本路径 | sha16 | 权威件 | sha 相同? | 有没有判据盯它 |
|---|---|---|---|---|
| `build/MilBridge/.artifacts/bin/MilBridge.Linux/release_linux-x64/native/wpfgfx_cor3.so` | `d567c26f197ec1e3` | **无**（`:103` 显式"不覆盖"） | n/a | **逐份判据 = 无**（`:205` 早退）；**但有互比**：`--- 跨副本一致性` 分组把它算进 Release 组，实测 `CONSISTENT wpfgfx_cor3.so [Release] 2 份副本同 sha d567c26f197ec1e3` ⇒ **两份若不同 sha ⇒ `DIVERGENT` + `rc=1`（会红）** |
| `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` | `d567c26f197ec1e3` | 同上 | n/a | 同上 |

**残留洞（精确写法）**：**两份一起换成同一份旧桥 ⇒ 仍然绿**（互比没有绝对锚）。绝对锚在**源侧**：`BRIDGE_SRC_FP`（`bridge-src-fp.sh`，覆盖 `src/WpfGfx.Linux/**` + `build/MilBridge/**`）+ 应用门禁的 `BRIDGE_SRC_STALE=no … so_file_match=yes`（`run-wpftextdemo.sh:711-715` 逐字："`BRIDGE_SRC_STALE=yes` 的含义 = 部署的 `.so` 不是当前源编出来的"）。
⇒ **因此我在 §1.7 更正 `KNOWN-DEFECTS.md` 的一句话**（"不可能变红"只说对一半）。

## 1.5 表 C：`WpfGfx.Linux.dll` —— **24 份**（权威 = `src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll` = **`c400ab1638e0c3d2`**）

| 副本路径 | sha16 | 权威 | 相同? | 有没有判据盯它（点名分支） |
|---|---|---|---|---|
| `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | `c400ab1638e0c3d2` | 相同 | **有**：`:262` ⇒ `UNEXPECTED-EQ`（**红**，= `D-A1` 那一份；实测 `UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]`） |
| `build/MilBridge/.artifacts/bin/MilBridge.Linux/release/WpfGfx.Linux.dll` | `4b2de9e927418b6e` | 同上 | **不同** | **无**：`:235` ④ `NO-AUTHORITY`（权威是 Debug；**判不了、不算不一致、exit 0**） |
| `build/MilBridge/.artifacts/bin/MilBridge.Linux/release_linux-x64/WpfGfx.Linux.dll` | `d87ba8a6530f0984` | 同上 | **不同** | **无**：④ `NO-AUTHORITY` |
| `build/MilBridge/.artifacts/bin/WpfGfx.Linux/release/WpfGfx.Linux.dll` | `d87ba8a6530f0984` | 同上 | **不同** | **无**：④ `NO-AUTHORITY` |
| `build/MilBridge/.artifacts-rb/bin/ProbeB/release/WpfGfx.Linux.dll` | `d41a89530a8a25d3` | 同上 | **不同** | **无**：④ `NO-AUTHORITY` |
| `build/MilBridge/.artifacts-rb/bin/WpfGfx.Linux/release/WpfGfx.Linux.dll` | `d41a89530a8a25d3` | 同上 | **不同** | **无**：④ `NO-AUTHORITY` |
| `build/MilBridge/.artifacts/obj/WpfGfx.Linux/release/WpfGfx.Linux.dll` | `d87ba8a6530f0984` | 同上 | **不同** | **无**：`:227` ③ `SKIP(obj)`（**逐条打印 sha，不判**） |
| `build/MilBridge/.artifacts-rb/obj/WpfGfx.Linux/release/WpfGfx.Linux.dll` | `d41a89530a8a25d3` | 同上 | **不同** | **无**：③ `SKIP(obj)` |
| `src/WpfGfx.Linux/obj/Debug/net10.0/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | 同上 | 相同 | **无**：③ `SKIP(obj)` |
| `.artifacts/obj/WpfGfx.Linux/release/ref/WpfGfx.Linux.dll` | `90a742289e8d5be7` | 同上 | **不同** | **无**：`:217` ① `SKIP(ref)` |
| `.artifacts/obj/WpfGfx.Linux/release/refint/WpfGfx.Linux.dll` | `90a742289e8d5be7` | 同上 | **不同** | **无**：① `SKIP(ref)` |
| `.artifacts-rb/obj/WpfGfx.Linux/release/ref/WpfGfx.Linux.dll` | `8d1c5a91cdd7686f` | 同上 | **不同** | **无**：① `SKIP(ref)` |
| `.artifacts-rb/obj/WpfGfx.Linux/release/refint/WpfGfx.Linux.dll` | `8d1c5a91cdd7686f` | 同上 | **不同** | **无**：① `SKIP(ref)` |
| `src/WpfGfx.Linux/obj/Debug/net10.0/ref/WpfGfx.Linux.dll` | `2136929f44784b6a` | 同上 | **不同** | **无**：① `SKIP(ref)` |
| `src/WpfGfx.Linux/obj/Debug/net10.0/refint/WpfGfx.Linux.dll` | `2136929f44784b6a` | 同上 | **不同** | **无**：① `SKIP(ref)` |
| `samples/HelloMil/bin/Debug/net10.0/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | 同上 | 相同 | **有**：⑥ `OK` |
| `src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | —— | 权威本身 | **有**：⓪ `OK（这就是权威件本身）` |
| `tests/…/Commands.Tests/bin/Debug/net10.0/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | 同上 | 相同 | **有**：⑥ `OK` |
| `tests/…/HelloMil.Tests/bin/Debug/net10.0/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | 同上 | 相同 | **有**：⑥ `OK` |
| `tests/…/ManagedLayer.Tests/bin/Debug/net10.0/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | 同上 | 相同 | **有**：⑥ `OK` |
| `tests/…/Presentation.Tests/bin/Debug/net10.0/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | 同上 | 相同 | **有**：⑥ `OK` |
| `tests/…/Rendering.Tests/bin/Debug/net10.0/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | 同上 | 相同 | **有**：⑥ `OK` |
| `tests/…/Windowing.Tests/bin/Debug/net10.0/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | 同上 | 相同 | **有**：⑥ `OK` |
| **`tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll`** | **`16baacfccfcf1df0`** | 同上 | **不同** | **无 —— 而且连枚举都没枚举到**：`tools/` **不在 `SCAN_ROOTS`**（`:93` = `$REPO/build:$REPO/tests:$REPO/samples:$REPO/src`）⇒ `find` 到不了它。**该目录是启动宿主**（`GeometryOracle.runtimeconfig.json` 在场）⇒ 若接线它本会走 ⑥ |

**汇总**：24 份 = **8 份被判 OK（含权威本身）** + **1 份红（`UNEXPECTED-EQ`，= `D-A1`）** + **15 份"在 ITEMS 里但被分支豁免"**（`NO-AUTHORITY` 5 + `SKIP(obj)` 3 + `SKIP(ref)` 6 + **漏扫 1**）。这 15 份里 **14 份今天 sha ≠ 权威**。

## 1.6 特别回答（派单点名问的两条）

**(a) `obj/` 里的副本 —— `is_obj()` 会跳过它吗？**
- **会跳（不判），但至少会打印 sha**：`:227` `is_obj()` ⇒ `CNT_SKIPOBJ++` + 逐条 `SKIP(obj) … （中间件，不是加载源；与权威一致/不同）`。
- **但注意 `PC` 与其它件的差别**：`PC` 连这个"打印"都没有（它不在 `ITEMS`）。实测：`PC` 的 obj 副本只有 1 份（`build/PresentationCore.Linux/obj/Debug/`，sha == 权威）；`WpfGfx.Linux.dll` 的 obj 副本 3 份（全部 sha ≠ 权威，其中 2 份在有 `.artifacts-rb` 里）。
- 分支优先级也实测过：`*/obj/*/ref/*` 与 `refint`（①）**先于** ③ 与 ④ ⇒ `.artifacts/obj/.../release/ref/` 这类"既在 obj、又在 release"的副本落 **`SKIP(ref)`**，不落 `NO-AUTHORITY`。

**(b) `release*` 路径的副本（`is_release_path()`）？**
- `is_release_path()`（`:122`，大小写不敏感、含 `*/release_*/*`）**命中**，但**④ 还要求权威是 Debug 路径**（`:235` `is_release_path "$f" && is_debug_auth "$exp"`）。⇒ **只有"权威是 Debug"时它才被豁免成 `NO-AUTHORITY`**。
- 实测后果：`WpfGfx.Linux.dll` 的 5 份 release 副本（`.artifacts/**`、`.artifacts-rb/**`）全部**因这一条而被判"判不了"**；`WpfGfx.Linux.dll [Release] …` 在那 5 份里**没有任何一组 ≥2 行**（③④ 先于互比分组的过滤）⇒ 连互比都没有。
- ⇒ **反过来是一条最小修法**：给某个件配一个**非 Debug**（release）权威，它的 release 副本就会掉到 ⑥ 被**真判**（见 §1.8 判据草案第三条）。

## 1.7 一行结论（派单要求）

> **当前有 34 份副本处于"陈旧也不会红"的状态（口径 α：`PresentationCore.dll` 的 32 份非权威副本 + `wpfgfx_cor3.so` 的 2 份）—— 这一口径下连 sha 都不会被打印；若把"被分支豁免（打印了 sha 但不判）"也算进来（口径 β），总数是 49 份（+ `WpfGfx.Linux.dll` 15 份）。其中 PC 的 17 份、WpfGfx 的 14 份今天就已经与权威不同。**

## 1.8 判据草案（带反极性）—— 三条最小接线

**草案 ①（主）：把 `PresentationCore.dll` 加进两张 ITEMS 表。**
- 落点：`check-applocal-sync.sh:97-104` 的 `ITEMS` **＋** `applocal-expect.py:42-48` 的 `ITEMS`（**两处都要**：前者管逐份判定，后者管 `MISSING`/`UNEXPECTED` 的期望集合）。权威 = `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`。
- **反极性 = 实测（不是声明）**：我用**私有拷贝**（`$HOME/w22d-scratch/expect-pc.py`，只加那一行）把"接线后的期望模型"跑了出来 ⇒ **期望条目 55 → 86 条，其中 PC 30 条**。与现场 33 份逐份对拍（并按判定分支顺序修正）：
  - **立刻变红 = 17 份**，**全部是 `STALE`/`NEWER-DIFF`**（PC 那一批旧世代副本，见 1.3 表中 17 行）；
  - **12 份 `OK`**（+ 权威自身 1 份）；
  - **2 份会被 `SKIP(stub)` 路径豁免**（`build/CycleStub.*` 那两份 —— 内容 == 权威，属"恰好没坏"）；
  - **1 份会被 `SKIP(obj)`**（`build/PresentationCore.Linux/obj/Debug/`）；
  - **0 份 `MISSING`**（30 条期望全部在场）。
  ⇒ **这就是这条判据的牙齿，而且它是"今天就红"的**：不是"接了也永远绿"。
- **必须同时做的两件事（否则会被噪声淹没）**：① 按 `D-A1` 的裁决走"**声明**"路（把那 17 条一份份声明出来或刷新，而不是放宽分支）；② 桥/PC 的 `UNEXPECTED-EQ`-类仍按 `#16` 裁决**保持红**。
- **第二极性（回归牙）**：把 `samples/WpfTextDemo/bin/Debug/net10.0/PresentationCore.dll` 换成任一旧 sha（现成的旧件就在 `build/MilBridge/tests/TextLineProto/bin/Debug/PresentationCore.dll` = `f4a454c8fe69cdfe`）⇒ 必须**新增**一条红且**点名该路径**；用 `cp -p` 还原（并核对 sha16）⇒ 必须回到 `OK`。

**草案 ②（补漏扫）：`SCAN_ROOTS` 补 `$REPO/tools`。**
- 反极性：`tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll` 今天是 `16baacfccfcf1df0`（≠ 权威 `c400ab1638e0c3d2`）而**全仓零读数**。补 `tools` 后**必须点名它**（该目录有 `runtimeconfig.json` ⇒ 走 ⑥ ⇒ 期望模型里没有它 ⇒ `UNEXPECTED-DIFF`，或若被声明则 `STALE/NEWER-DIFF`）。**今天静默 = 这条判据的反极性现场**。

**草案 ③（可选，给 `.so` 一个非 Debug 权威）：`wpfgfx_cor3.so` 的权威指向 `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so`。**
- 因为 ④ 要求"权威是 Debug"才豁免 ⇒ 权威改成 release 路径后，`.artifacts/bin/.../native/` 那份会掉进 ⑥ **被逐份判**。
- **反极性（必须写清两种）**：把 `.artifacts/bin/.../native/` 那份换成旧桥（旧件留档 `$HOME/wfp-runs/w18-pre/wpfgfx_cor3.caf7baf9e67719aa.so`）⇒ **今天已经会红**（互比 `DIVERGENT`）；**"两份一起换旧"今天静默** ⇒ 接线后必须红（`NEWER-DIFF`）。**但**：真正的绝对锚仍是**源侧指纹**（`BRIDGE_SRC_FP` + `so_file_match`）⇒ 这条判据的增量是"产物级"，不是"源级"。

## 1.9 我推翻 / 更正的文档陈述（件 1）

1. **`KNOWN-DEFECTS.md:643`（`D-A2`）"`.artifacts/**` 与 runner 的 `$OUT` **不在 `SCAN_ROOTS` 里**"** —— **错**（主控 `#21` 已更正，我复核并采纳：`:93` 含 `$REPO/build`）。**我补一条主控没点名的**：真正漏扫的是 **`$REPO/tools`**（不在四个根里）⇒ `tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll`（`16baacfccfcf1df0`，288,768 B，**是启动宿主**）**连枚举都没枚举到**。
2. **`KNOWN-DEFECTS.md:642`"全部 `.so` 副本（含已发布的桥 `wpfgfx_cor3.so`）`EXPECT=UNKNOWN`、根本没有权威可比 ⇒ **不可能变红**"** —— **只说对一半**。准确的写法：**没有绝对权威可比 ⇒ 不可能因"内容陈旧"而红**；**但它在"跨副本一致性"分组里**（实测 `CONSISTENT wpfgfx_cor3.so [Release] 2 份副本同 sha d567c26f197ec1e3`）⇒ **两份不一致会 `DIVERGENT` + `rc=1`，那是红**。（残留洞只剩"两份一起旧"。）
3. **`KNOWN-DEFECTS.md:637-638`"`ITEMS` 只含：Provider／WpfGfx／ReachFramework／libwpfwin32／libwpfwic"（5 项）** —— **与现场不符**：`:97-104` 是 **6** 项（第 6 项 = 权威为空的 `wpfgfx_cor3.so`）。**不是小事**：第 6 项恰恰是"有件无权威"这条**独立机制**的载体，漏掉它就会把 ② 当成 ① 的附属。
4. **`#16` TAPPS 的"删掉探针目录里那份 `PresentationCore.dll` ⇒ 计数纹丝不动"** —— **我复核为真**（今天仍为真：模拟模型的 `#EXPECT` 里 PC 条目 = 0）。**但补一句边界**：那是因为 PC **根本不在 `ITEMS`**，不是因为"删除检测器有洞"。

---

# 件 2 · `D-T5`：异常会不会传到应用层？

## 2.1 先给"触发—传播"链的**完整**静态追踪（每层给 file:line 与"有无 catch"）

| # | 层 | 锚点（现场逐字核对） | 有无 catch | 行为 |
|---|---|---|---|---|
| 0 | 触发（`Length ≥ 1` 的非 `TextCharacters` run） | `CollectLenient`（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:101`）：`:146` `s = ExtractRun(run)` → `ExtractRun`（`:81-91`）：`:83` `if (run == null \|\| run.Length <= 0) return string.Empty;`、`:85-86` `CharacterBuffer buf = cbr.CharacterBuffer; if (buf == null) return null;` ⇒ `:149-153` `DiagBeforeReturn(...) ; return false;` | —— | 宽松档**返回 false**（`Length == 0` 的 modifier 例外：走 `:83` 得空串 ⇒ 能过，这正是 `#17` P3 改用零长 modifier 的原因） |
| 1 | 严格档（shim） | `build/shims/PresentationCore.HbTextLine.cs:4487` `TryCollect`：`:4500-4511` 只接 `TextCharacters`；`:4512` `if (run is TextEndOfLine) break;`；`:4513` `Bail(ref BailRunType, "run 类型 … 不支持")` | **有**（`:4580` `try { … } catch (Exception e) { … return null; }` at `:4644`） | 非 `TextCharacters`/非 `TextEndOfLine` ⇒ **bail ⇒ 返回 null**（异常被**吞成 null**，不外传） |
| 2 | 宽松档（PC） | 同上（`TryFormatLine` `:235-272`，`catch` `:266-272` ⇒ `return null`） | **有** | 同上：**返回 null** |
| 3 | **LS 回退（回退链的终点）** | 生成物 **`:615-625`**：`if (textLine == null) { textLine = new TextMetrics.FullTextLine(settings, firstCharIndex, lineLength, RealToIdealFloor(paragraphWidth), LineFlags.None) as TextLine; }` | **无**（这一层是裸构造，**全函数只有 `FormatSettings` 与返回，无 try**） | 构造 `FullTextLine` ⇒ `TextFormatterContext.cs:113` `UnsafeNativeMethods.LoCreateContext(...)` ⇒ `LineServices.cs:1407` `[DllImport(DllImport.PresentationNative, EntryPoint="LoCreateContext")]` |
| 4 | 原生符号解析 | `build/shims/Win32ShimResolver.cs:91` 的 `MappedLibraries` 含 `"PresentationNative_cor3.dll"`（注释 `:77-87` 逐字说明它是"第 1 步清单逼出来的第四个"）⇒ 解析到 **`libwpfwin32.so`**；**实测该 .so 没有这个符号**：`nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| grep -c LoCreateContext` = **0**（正对照 `GetWindowLongPtrWrapper` = **1**，`nm` 总导出 **472**） | —— | **`EntryPointNotFoundException`**（`W17D-report.md` 的原始读数逐字：`Unable to find an entry point named 'LoCreateContext' in shared library 'PresentationNative_cor3.dll'.`） |
| 5 | min/max 入口**同形** | 生成物 **`:706-713`**：`TextMetrics.FullTextLine line = new TextMetrics.FullTextLine(settings, firstCharIndex, 0, 0, (LineFlags.KeepState \| LineFlags.MinMax));` | **无** | `FormatMinMaxParagraphWidth` 走**同一条** LS 回退 ⇒ `D-T5` 在两个入口都成立（W17D 的实测就是走 `MINMAX CASE mod1`） |
| 6 | `FormatLineInternal` → `FormatLine`（PC 公开面） | 生成物 `:473`（`RecreateLine` → `:512` `FormatLineInternal`）；`:512-630` 全函数**无 catch** | **无** | 异常原样上抛 |
| 7 | `Line.Format`（pf 的桥） | `upstream/wpf/src/…/PresentationFramework/MS/Internal/Text/Line.cs:83` `_line = _owner.TextFormatter.FormatLine(this, dcp, width, lineProperties, textLineBreak, textRunCache);`（该文件 `grep -c catch` = **0**） | **无** | 上抛 |
| 8 | `TextBlock.MeasureOverride` | **生成物** `build/PresentationFramework.Linux/TextBlock.Linux.cs:1247-1253`（`bool exceptionThrown = true; try {` …）、`:1282` `line.Format(...)`、`:1337` `exceptionThrown = false;`、**`:1338-1350` `finally { … if(exceptionThrown){ _textBlockCache._textRunCache = null; ClearLineMetrics(); } }`**（`grep -n catch` 该文件 = **0 命中**） | **有 try / 无 catch**（只做清理） | **上抛**（这正是 T1c 当年抓到的栈：`LoCreateContext ← FullTextLine ← TextFormatterImp.Linux.cs:483 ← FormatLine:353 ← TextBlock.MeasureOverride:1271`） |
| 9 | 布局引擎 | `upstream/wpf/src/…/PresentationCore/System/Windows/LayoutManager.cs:164` `UpdateLayout()`；`:407-411` `gotException = false; } finally { … if(gotException) {…} }` | **有 try / 无 catch** | 上抛 |
| 10 | 渲染消息 | `upstream/wpf/src/…/PresentationCore/System/Windows/Media/MediaContext.cs:1702-1711` `RenderMessageHandler` → `:1759` `RenderMessageHandlerCore(...)`；**该文件 `grep -c catch` = 0** | **无** | 上抛到 Dispatcher |
| 11 | Dispatcher（最后一层） | `upstream/wpf/src/…/WindowsBase/System/Windows/Threading/Dispatcher.cs:2700` `bool requestCatch = HasUnhandledExceptionHandler;`、`:2746-2753` `if (UnhandledException != null) { … UnhandledException(this, _unhandledExceptionEventArgs); … }`、`:2758` `return false; // caller should rethrow` | **只在"有人订阅了 `UnhandledException`"时才 catch** | `WpfTextDemo` **没有订阅**（`grep -rn "UnhandledException" samples/WpfTextDemo/**` = **0 命中**；样例里的 3 个 `try` 分别在 `MainWindow.xaml.cs:282`（ItemsSource 选中）/`:329`（`BitmapSource.Create`）/`:384`（`BitmapImage` 载文件），**都不在文本布局路径上**）⇒ **重抛** ⇒ 进程级未处理异常 |
| 12 | 进程 | **在册实测**：`build/MilBridge/T1b-report.md:500-506` 表格逐字 —— WpfTextDemo：`LoCreateContext` **27 查找 ⇒ MISS**、"**走到 LS 且崩**：`exit=134`、`blocker=lineservices:LoCreateContext`"（同表 HelloWpf 全 0 ⇒ 该装置是**阳性对照有效的**） | —— | **`exit=134`**（.NET 在 Linux 上未处理异常 = abort） |

## 2.2 裁定

> **会传到应用层。**
> ① **机制上是"逐层无 catch"**：第 3/5 层（LS 回退）是**裸构造**，第 6/7/8/9/10 层全部是 **try/finally（清理）而非 try/catch**，唯一有能力拦的 Dispatcher **默认重抛**，而 `WpfTextDemo` 没订阅（0 命中）。② **实测上已经在册**：`T1b` 的活窗口读数就是**应用进程 `exit=134` + `blocker=lineservices:LoCreateContext`**，且同装置上 HelloWpf 零查找（"没抓到"与"没发生"可区分）。
> ⇒ **按派单规则：`D-T5` 升为下一波第 1。**
> **升的理由写准**（免得被读成"今天有红"）：**今天冻树里没有任何东西在产生它**（见 2.4），所以这不是"活的红"；升到第 1 是因为它的**失败模式是进程级 abort**（不是错值），而且**真实应用的常规写法就会命中**（见 2.3）。

## 2.3 新发现：这一族**比在册描述更宽**（`TextHidden` 同机制，且**上游 pf 自己就在产**）

- **在册写的两族**：`D-T5`（`KNOWN-DEFECTS.md:700-704`）= `Length ≥ 1` 的 `TextModifier` / `TextEndOfSegment`。
- **机制**是"该 run 的 `CharacterBufferReference` 是**默认构造** ⇒ `CharacterBuffer == null`"。我在上游逐类核过（`grep "override CharacterBufferReference"`）：

| run 类型 | CBR | 我方能否过 | 谁产它 |
|---|---|---|---|
| `TextCharacters` | `_characterBufferReference`（真 buffer） | ✅ | 上游 `SimpleLine.cs:53`、`ComplexLine` 文本段 |
| `TextEndOfLine`（含 `TextEndOfParagraph`） | 默认空 | ⭕ 走 `break`（不算失败） | `SimpleLine.cs:57`（`TextEndOfParagraph`）、`ComplexLine.cs:386`（`LineBreak`） |
| `TextModifier`（抽象；`TextSpanModifier` 实现 `Length`） | 默认空（`TextModifier.cs:25-28`） | ❌ **`Length ≥ 1` 时** | **上游 pf 自己**：`ComplexLine.cs:424/433/449`、`LineBase.cs:198/207/223`（`new TextSpanModifier(_elementEdgeCharacterLength, …)`，**长度恒 = 1**） |
| `TextEndOfSegment` | 默认空（`:42-45`），ctor `:29-33` 强制 `≥ 1` | ❌ | **上游 pf 自己**：`ComplexLine.cs:491/503`、`LineBase.cs:269/281`（内联元素有 `TextDecorations`（如 `<Underline>`/`<Hyperlink>`）或自身 `FlowDirection` 与父不同时） |
| **`TextHidden`** | **默认空（`TextHidden.cs:44-47`）**，ctor 强制 `≥ 1` | ❌ **在册未写** | **上游 pf 自己**：`ComplexLine.cs:404/477/499`、`LineBase.cs:219` —— **每一个内联元素边缘**（无 `TextDecorations`、`FlowDirection` 与父相同时走这支）⇒ 即 `<TextBlock><Run>…</Run></TextBlock>`、`<Bold>`、`<Span>`… 都会产 |
| `TextEmbeddedObject` / `TextShapeableSymbols` | 在自家文件里**没有** `CharacterBufferReference` 覆写（客户端实现） | **NOINFO**（静态不可判） | 客户端 |

- **后果（静态、可复算）**：`TextBlock.CreateLine`（生成物 `TextBlock.Linux.cs:2852-2860`，上游 `TextBlock.cs:2839-2848` 同构）：
  ```
  2855:  if (_complexContent == null)
  2856:      line = new SimpleLine(this, Text, lineProperties.DefaultTextRunProperties);
  2857:  else
  2858:      line = new ComplexLine(this);
  ```
  ⇒ **`TextBlock Text="…"`（简单内容）走 `SimpleLine`，而 `SimpleLine.GetTextRun` 只产 `TextCharacters`（`SimpleLine.cs:53`）与 `TextEndOfParagraph`（`:60`）⇒ 永远不触发**；**一旦内容模型变成 `TextContainer`（内联元素 / Text OM）⇒ `ComplexLine` ⇒ 每个内联元素边缘一个 `TextHidden(1)` ⇒ 命中本族**。
- **⇒ 这把在册的"可能测不出来但真实存在"变成了"上游常规写法就会命中"**：`<Underline>` / `<Hyperlink>`（`TextSpanModifier(1)` 或 `TextEndOfSegment(1)`）、`<Run>`/`<Bold>`/`<Span>`（`TextHidden(1)`）。**这个方向值得单独取一条读数**（见 2.5）。

## 2.4 今天冻树里的可达性（**实测：0**）—— 这是"升级"真正的边界

| 载体 | 结论 | 证据 |
|---|---|---|
| `samples/WpfTextDemo`（应用门禁的宿主） | **不含任何内联元素、不含 `TextBox`** ⇒ 全部走 `SimpleLine` | `grep -rn "Inlines\|<Run\|<Span\|<Bold\|<Italic\|Underline\|Hyperlink\|TextDecorations" samples/WpfTextDemo/` = **0 命中**；`grep -n "TextBox\|RichTextBox" samples/WpfTextDemo/MainWindow.xaml` = **0 命中**；`TextBlock` 全部用 `Text="…"` 属性 |
| `samples/WpfFeatureProbe` | 同样 **0 命中**（`<Run>/<Bold>/…` 与 `Inlines` 全 0）；RTL 块也是 `Text = "…"`（`FeatureBlocks.cs:871`） | 同上 grep（`samples/` 全目录 0 命中；命中的都是 `bin/` 里的二进制，非源） |
| ⇒ | **本波冻结树里 `D-T5` 没有任何自动红/绿，也没有任何应用会命中它** | 与 `W21D` §A③ 的"这个红今天只存在于报告里"一致 |

## 2.5 最小判据草案（可判红、不需要新真值）+ 反极性

**判据（两步，第一步先做）**：
1. **取"家族宽度"读数（零成本、零语义）**：在 `SummaryFragment()`（件 3 的同一处）或一个新的诊断口打出**按 run 类型分类的"跳过的 run"**（今天 `CollectLenient` 已有 `s_skippedRuns/s_lastSkip`（生成物 `:172-177`），但没有按类型分桶；且它**只在"跳过"时计数**，而 `TextHidden` 是**收集失败**（不是跳过）—— 所以需要新增一个 `unsupportedTypes` 直方图）。**这同时是件 3 的 +3 行的同族动作 ⇒ 应与 `D-F2` 合并一趟**。
2. **判据本体（新臂，`build/MilBridge/tests/PcLineOracle/**` 是现成仪器）**：造一个 `TextSource` 子类，其 `GetTextRun` 在第 1 段返回 `TextCharacters("abc")`，在段中插入 `new TextEndOfSegment(1)`（**并另造一条 `TextHidden(1)` 变体**）⇒ 断言：
   - ① **不交回**：`TextFormatter.FormatLine(...)` 必须**返回非 null `TextLine`**（两条腿：`--tier strict|lenient`），且 `HbTextFallback`/`WpfLinuxLenientTextFallback` 的**层级来源自证**必须显示"谁接手的"；
   - ② **不强杀**：进程不得出现 `EntryPointNotFoundException: LoCreateContext`（今天**必抛**）；
   - ③ 交回行的 `Length` 与段落文本长度一致。
- **反极性（现状必须红）**：**已在册实测**（`W17D-report.md` §：`MINMAX CASE mod1 EXCEPTION EntryPointNotFoundException: … 'LoCreateContext' …`；`relaxedFailed=1 relaxedHandled=0`、`GetTextRun` 只被调 **1** 次）。⇒ 红在"能否交出行"这一格，**红到底（0 行）**，且**红的是异常而不是错值**。
- **第二极性（防作弊，必须给）**：把 `ExtractRun` 的 `buf == null ⇒ return null` 改成"返回一个合成字符"（即假装修好）⇒ 判据 ① 会变绿但 ③（`Length` 一致）**必须仍红**，否则说明判据只是"有没有抛异常"，会被"吞成空白段"骗过去。

## 2.6 顺带核对在册描述（派单要求）

- **`D-T5`（`KNOWN-DEFECTS.md:700-704`）**：**与现场相符**（`ExtractRun`（`:81-91`）→ `CharacterBuffer==null ⇒ null` → `CollectLenient`（`:149-152`）`return false`；`TextModifier.CharacterBufferReference` 是 `sealed override … new CharacterBufferReference()`；`TextEndOfSegment` ctor 强制 `≥1`）。**行号逐条复核**：`:81-91` ✓、`:149-152` ✓、`KNOW-DEFECTS` 引的 `shim:3810` 一带今天漂到 `:3895-3960`（`BuildSegmentFacesFromPlan` 自 `:3872`）= **行号漂移，结论不变**。⇒ **唯一需要更正的是"家族欠宽"**（§2.3 的 `TextHidden`）。
- **`D-T4`（`KNOWN-DEFECTS.md:695-698`）**：**与现场相符**。复核三处：① 生成物里 `defaultIncrementalTab`/`incrementalTab` **0 命中**（PC 两个调用点 `:254-258`（宽松）与 `:565-587`（严格）都没有这个实参）；② shim 侧 `FormatParagraph` 确实有该形参且在 `:643`/`:1745`/`:2852` 用 `double.IsNaN(tabInterval) ? 4.0 * emSize : tabInterval` ⇒ **默认配置恒取 4×em**；③ `TextParagraphProperties.DefaultIncrementalTab` 是**真 API**（臂里在覆写：`FrameProbe/Program.cs:107`、`StrictTierProbe/Program.cs:94`、`PcLineOracle/Program.cs:166`）。⇒ **描述无需更正**。

## 2.7 未测 / 不声称（NOINFO）

- **运行期从未测过 `D-T5`**：**本件是纯静态追踪 + 在册读数引证**，**我没有跑任何应用/臂**（硬约束：零 `dotnet`）。⇒ "传到应用层"这条的**运行期**证据来自 `T1b` 的**另一族触发**（RTL/空段落 bail），**不是** `D-T5` 本人的触发。**不许**把"同一层没有 catch"读成"D-T5 已实测 abort"：**机制相同、实例不同**。
- **`TextBox` 路径是否产本族 run**：`TextBox` 的 `TextContainer` 里若**没有内联元素**，则没有元素边缘字符 ⇒ 不产 `TextHidden`/`TextSpanModifier`；**我没有实测**（`WpfTextDemo` 没有 TextBox，FeatureProbe 的 TextBox 块用的是纯文本）。⇒ **NOINFO**，不许写成"TextBox 安全"或"TextBox 会崩"。
- **`TextEmbeddedObject`/`TextShapeableSymbols`**（客户端实现的 run 类型）在其 CBR 上**静态不可判** ⇒ **NOINFO**。
- 我**没有**核对 `D-T5` 在**真机 Windows** 上是什么行为（那需要重录），也没有核对 `pf`/`pc` 上游对 `TextEndOfSegment` 的**正常用法**会不会命中（`KNOWN-DEFECTS` 把它列为未测）——**我只能证明上游 pf 会产**（`ComplexLine`/`LineBase` 那 8 处构造点），**不能证明"某个具体的 WPF 控件在某个具体 XAML 下一定走到"**。

---

# 件 3 · `D-F2`：三个"只写不读"计数器的精确改法

## 3.1 逐条核实（派单要求"① 逐条核实上面每一句"）

| 在册/派单的句子 | 我的复核 | 证据（行号级，现场逐字） |
|---|---|---|
| `SegmentFaceUnresolved`（`:1275`）**只被自增、从不被读** | **真** | 声明 `:1275` `internal static long SegmentFaceUnresolved;`｜`：1276` `… => Interlocked.Increment(ref SegmentFaceUnresolved);`｜**唯一调用点** `:3881` `if (g == null) HbFallbackDiag.NoteSegmentFaceUnresolved();`｜**全仓（除 upstream）该标识符的命中 = 这 3 处**（`grep -rn` 无第 4 处）⇒ **零读点** |
| `RunFaceSlotMissing`（`:1278`）**只被自增、从不被读**（注释逐字"不许静默"） | **真** | `:1278` `internal static long RunFaceSlotMissing;`｜`:1279` `… NoteRunFaceSlotMissing() => …`｜唯一调用点 `:2803` `else if (plan != null) HbFallbackDiag.NoteRunFaceSlotMissing();`｜`:1277` 注释逐字 `/// <summary>D-F1b/P1c：plan != null 却拿不到 run 面槽的次数 —— 不许静默。</summary>` ⇒ **"不许静默"的东西正在静默** |
| `ScanCapped`（`:1272`）、注释自称"诊断行报 `capped=`"却**零打印点** | **真** | `:1272` 声明（上方 `:1271` 注释逐字 `诊断行报 capped=`）、`:1273` setter、唯一调用点 `:1147` `if (list.Count >= MaxScanFaces) { HbFallbackDiag.NoteScanCapped(); break; }`；`:1067` 另一处注释 `超限 ⇒ NoteScanCapped + 诊断行 capped=`；**全仓 `capped=` 命中 = 3 处、全是注释**（`shim:1067`/`:1146`/`:1271`）⇒ **零打印点** |
| `SummaryFragment()`（`:1344-1379`）里**一个都没有** | **真** | 我把 `:1344-1379` 逐行读完：它读的是 `PlanCalls/RunsCollected/RunGt1Paragraphs/CpUncovered/CoverageProbe/HbShaper.LiveBlobs/…/HbFaceCache.*/SegmentFaceResolveCalls/CoverageCacheHit/FallbackApplied/FallbackFailed/FallbackUnrenderable/FallbackFromRunFaces/FallbackFromSystemScan/SegmentsBuilt/ChunkedLines/FaceResolve*/HbFontCandidates.Count` —— **`ScanCapped`/`SegmentFaceUnresolved`/`RunFaceSlotMissing` 三个名字一次都没出现** |
| **正对照**：`applocal-expect.py:485` 的 `invisible_capped=` 是非 0 且**真的在打印** | **真（我实测）** | `applocal-expect.py:485` 的 `#SUMMARY` 里逐字含 `invisible_capped=%d`；我这一趟的实读：`#SUMMARY\|refdirs=16\|expect=55\|projects=80\|unknown=1\|unresolved_hintpath=0\|invisible_copysites=20\|invisible_write=3\|invisible_read=17\|**invisible_capped=2**\|invisible_ext_write=4\|…` ⇒ **非 0 且真在 stdout 上**（与 `check-applocal-sync.sh:164` 的消费端对得上）⇒ 这是"**真 0**"而不是"**仪器瞎**" |
| **同族的第二个正对照（我补的，比上面那条更强）** | **真** | 同一个类里**紧邻声明**的兄弟计数器 `SegmentFaceResolveCalls`（`:1269-1270`）**是被打印的**（`SummaryFragment():1366` `sb.Append(" segmentFaceResolveCalls=")`）⇒ "在这个类、这个函数里打印计数器"的能力**存在且在工作**，`SegmentFaceUnresolved` 的缺席是**具体的遗漏**，不是"这一类都不打印" |
| **派单的一句边界更正（我按更严的字面核）** | **在册那句字面不成立** | `docs/CURRENT-STATE.md:306`（**`D-G4` 行**；`KNOWN-DEFECTS.md` 里**没有** `D-G4` 条目 —— 这也是"在册项分散在两份文档里"的一个现场）写"全仓（除 upstream）`capped=` 的命中**全是注释、零打印点**"。**用词边界**：若按 `capped=` 直接匹配，`invisible_capped=`（`applocal-expect.py:29/485`、`check-applocal-sync.sh:164/590/596/598`）也会命中，而那些**是真打印点**。⇒ 准确写法：**"`[^_]capped=`（不带 `invisible_` 前缀的那个词）的命中全是注释、零打印点"**。**这不是吹毛求疵**：本项目的纪律 25 就是"计数的口径也要正对照"，而这条正是"同一个子串两种含义"的现场 |

## 3.2 精确改法（行号级）

**最小版（`+3` 行，零语义）** —— 在 `SummaryFragment()` 的 `:1377` 之后（`)` 与 `return sb.ToString();`（`:1378`）之间）插入三行：

```csharp
            // D-F2/D-G4：三个"只写不读"的计数器接出口（只加字段、零几何/零语义）
            //   ⚠️ 顺序：必须放在上面 `candidates=` 那一行**之后** —— 那一行的
            //      `HbFontCandidates.Count` getter 会触发 `EnsureScan()`（`EnsureScan` 内
            //      的 `:1147` 就是 `ScanCapped` 的唯一自增点）⇒ 放在它之前会**漏掉本次扫描**。
            sb.Append(" scanCapped=").Append(ScanCapped);
            sb.Append(" segmentFaceUnresolved=").Append(SegmentFaceUnresolved);
            sb.Append(" runFaceSlotMissing=").Append(RunFaceSlotMissing);
```

- **字段名**：直接沿用声明名（`scanCapped` / `segmentFaceUnresolved` / `runFaceSlotMissing`，驼峰），与既有 `segmentFaceResolveCalls`（`:1366`）保持同一命名风格 —— 门禁/文档若以后要 grep，**不要**用注释里那个从未存在的 `capped=`（那正是这次要消灭的伪证）；**要么**按 `D-G5`/纪律 43 的做法**把注释改成现算读数**、**要么**把注释改成指向新字段名（推荐后者：`:1067`/`:1146`/`:1271` 三处注释必须一起改，否则"注释自称 `capped=`"这条伪证会**继续存在**）。
- **`+4` 行（诚实版，推荐）**：`SummaryFragment()` 的第一句早退还了一个**恒定字符串**（`:1346-1347` `if (PlanCalls == 0) return "multifont=未使用(plan=0) 覆盖/回退各项=**无信息**（不是 0：…）";`）。**这里有一个真实的漏法**：`ScanCapped` 的自增点在 `EnsureScan()`（`:1100-1150`），而 `EnsureScan` 也会被 `HbFontCandidates.Count` 触发；若某进程**从未走过 plan 路径**但**扫过字体**（或恰好扫到上限），`PlanCalls == 0` 会让这三个新字段**一个都不打印** —— 那就等于把 `ScanCapped` 又按回了"静默"。⇒ 诚实版：把早退分支改成
  `return "multifont=未使用(plan=0) 覆盖/回退各项=**无信息**（不是 0：本进程还没走过 run 感知路径） scanCapped=" + ScanCapped;`
  （即：**"无信息"必须只覆盖真的无信息的那些项，而不是把同一族里已有值的项一起吞掉**；与该项目"算不出 ⇒ NOINFO，但**看得见的要打印**"的口径一致。）
  **注意**：`SegmentFaceUnresolved`/`RunFaceSlotMissing` 的自增点（`:3881`/`:2803`）都在 plan 路径内 ⇒ 早退分支里它们**恒为 0**，所以只需带 `scanCapped` 一个。

**行数与代价**：`+3`（最小）/`+4`（诚实版）；**要改的注释 3 处**（`:1067`/`:1146`/`:1271`）—— 若只加代码不改注释，则"注释自称 `capped=`"这条伪证**留着**。

## 3.3 它会不会改变任何判据行？（**不会 —— 这是机器核过的**）

| 消费者 | 会不会受影响 | 证据 |
|---|---|---|
| **在册红门禁 `tline-gate.sh`**（= `verify-all` 第 10 步） | **不会**（0 引用） | `grep -n "HB_TEXTLINE\|SummaryFragment\|multifont=" build/MilBridge/tools/tline-gate.sh` = **0 命中** ⇒ 门禁取的是各臂的**判据状态行**（`结构=`/`位置=`/`FAILCASE`/`TAB_LINES`），不是 shim 的诊断串 |
| **`verify-all.sh` / `pc-line-step.sh`（第 11 步）** | **不会** | 同上（第 11 步走 `PcLineOracle` 的 `PCLINE` 判据列） |
| `run-wpfprobe.sh:511-515` | **不会**（它是 `grep -a 'HB_TEXTLINE' "$log" \| tail -1` 取**整行**打印） | 追加字段只让这一行更长 |
| `t1b-d3-acceptance.sh:74-76`（判据 4） | **不会**（它同样是取整行 + 人工读） | 同上 |
| **但有一条真实的连带**：`tline` 臂日志的 **sha** 会变 | **会** | 今天 `known-red.json` 的 `generation.evidence_log_sha256 = de605bf708dcdb5a`（`build/MilBridge/arm-logs/tline.log`）⇒ 日志字节一变，这个值就过期 |
| **世代成本** | **要付** | `build/shims/PresentationCore.HbTextLine.cs` 是门禁世代绑定三项之一（`tline-gate.sh:137` 的 `SH_SHIM`；`known-red.json.generation.instr_shim = 76089e1de586ac91…`）⇒ 改它 ⇒ **五臂重取 + `known-red.json` 重钉（含每条 `entries[*].caliber.instr_shim`）+ 两极化重做**（`CURRENT-STATE.md` 顶部逐字警告）。⇒ **与 `D-T6-b` 合并只付一笔**（主控 `#21` 预登记 §3.5 已写同样的建议） |

**⇒ 一句话**：**"+3 行"对判据行是零影响（门禁不读这个串），代价全在"改 shim ⇒ 换世代"这一笔上，与 `D-T6-b` 合并是本波该做的账。**

---

# 4. 仪器与读数表（纪律 15/18/32/35）

| 项 | 值 |
|---|---|
| lane / 身份 | **W22D**（本报告是本车道唯一写出的文件） |
| 时间 | 开工 2026-09-16 **19:41:06 +0800**；收官 **19:5x +0800**（`date` 逐段记录） |
| `loadavg` | 开工 **3.39 0.98 0.47** → 收官 **4.03 3.07 1.59**（本波另有两条车道在构建）｜`nproc=3` |
| `MemAvailable` | 开工 **3,519,436 kB** → 收官 **3,283,436 kB** |
| `kernel` | **6.8.0-138-generic** |
| 基线（权威表头） | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **`0d048e6e8808c4e7`**（= `#21`） |
| 相关件 sha16 | `hbtextline 76089e1de586ac91`（283,557 B）｜`pc e7cabff9417ed380`（4,196,864 B）｜`pf 2fb1a896f8277647`｜`bridge d567c26f197ec1e3`｜`WpfGfx.Linux.dll c400ab1638e0c3d2`（358,912 B） |
| 读数仪器 | `check-applocal-sync.sh` **`aad23482f84bdf44`**（跑了，`APPSYNC=MISMATCH … APPSYNC_RC=1`，`OK=45 MISMATCH=0 MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=0 NO-AUTHORITY=24 LIB-COPY=0 SKIP(obj)=6 SKIP(stub)=4 SKIP(ref)=10 RETIRED=0`）｜`applocal-expect.py` **`6eafbea14e7ea41e`**（跑了，rc=0） |
| 静态读的件 | `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` **`799e0366b312ec65`**｜`build/PresentationFramework.Linux/TextBlock.Linux.cs` **`6067276d0fc3a8da`**｜`build/MilBridge/known-red.json`（`generation.id=#21`，`instr_shim 76089e1de586ac91…`）｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` **`f5eb141e36adfc56`**｜`docs/CURRENT-STATE.md` **`ed55d620bbf575b6`**｜`docs/WAVE22-PREREGISTRATION.md` **`e6339689a41f2bfc`** |
| 私有模拟件（**仓外**） | `$HOME/w22d-scratch/expect-pc.py` **`faa01dd7a5e713cc`**（= `applocal-expect.py` 的拷贝 + 1 行 PC 项）；输出 `expect-pc.out`（86 条期望）；`table.out`（普查） |
| 只读性自证 | 本报告是**唯一**写入；所有普查/模拟都读仓内文件、写 `$HOME/w22d-scratch/`；**没有跑任何 `dotnet`**；`check-applocal-sync.sh` 头部自述"绝不改写任何目录"（且其输出逐字 `本脚本**不改写任何目录**`） |
| 报告自身 | `build/MilBridge/W22D-report.md` sha16 见最终回复（写盘后 `sha256sum` 打印） |

# 5. 未做清单（如实）

1. **没跑任何应用/臂/测试**（硬约束：零 `dotnet`）⇒ 件 2 的"传到应用层"是**静态追踪 + 在册读数引证**，本波**没有**为 `D-T5` 取新的运行期读数。
2. **没执行判据草案的接线**（`ITEMS`/`SCAN_ROOTS`/`applocal-expect.py` 都不许改）：§1.8 的"接线后 17 份红"是**私有拷贝的模拟**，不是把检查器改完再跑的真读数（但模拟脚本与真脚本只差**一行**，可复算）。
3. **没给 `D-F2` 的三行改动取编译证据**（要 `dotnet`）⇒ `error CS = 0` 一格**空白**（纪律 33：不许把"我读起来能编过"当编译过）。三行只引用**已存在**的静态字段与 `StringBuilder.Append(long)`，无新 API。
4. **没核对** `TextBox`/`TextEmbeddedObject` 路径是否产本族 run（§2.7）。
5. **没有再扫一遍 `.artifacts-rb/` 的历史**（它是哪一波的废弃树没查）—— 只报"它在扫描范围内、被判 `NO-AUTHORITY`/`SKIP(obj)`"。
