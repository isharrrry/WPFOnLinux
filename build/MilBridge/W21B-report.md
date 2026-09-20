# W21B 报告 —— `D-R8` 残项：把排除收敛到**一个**共享 `.props`，**实测**暴露集收口

```
lane=W21B        时间=2026-09-16 18:22:32 → 18:36 +08:00      nproc=3
loadavg=0.22 0.14 0.05（开工）→ 2.52 1.93 1.04（18:31）→ 2.10 2.08 1.32（18:35）
mem_available=3790164 kB（开工）→ 3360276 kB（18:31）→ 3530076 kB（18:35）
kernel=6.8.0-138-generic
冻结基线=#19   权威=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md 表头 f5d8a6f1cdf49635
本波预登记=docs/WAVE21-PREREGISTRATION.md  派单给的车道读的是 9d1e2dddda5b24e8
            实测：我开工时（18:22）读到的内容对应 sha16 9d1e2dddda5b24e8；
                  18:25:24 该文件被改成 127be0d931d97adf（新增 §1.6 档位预测 + §10 补遗）；
                  18:30:25 又被改成 5958cdb5b21010fb（30855 B）。
                  ⇒ 三次都逐字核过 **§2（P2）正文一字未变**，本件判据不受影响（§6.4）。
写域=build/MilBridge/W21B-report.md（本文件）＋ BuildHygiene.props（新，仓根）＋ 38 个 csproj ＋ $HOME/wfp-runs/w21-laneW21B/
硬约束遵守=**未跑任何 `dotnet build` / `dotnet run` / `dotnet restore`**；只跑求值式 `-getItem:` / `-getProperty:` / `-preprocess:`
```

---

## §0 一句话判决

**暴露集实测 = `33` 个工程（"还有 7 个"是错的）；已全部收口**：新增**一个**共享 props（仓根
`BuildHygiene.props`，唯一一份）＋在**实测暴露集**（扣掉 1 个按停条件挂起的）与 `build/MilBridge/tests/`
全子树上加**一行** `<Import>`，共改 **38 个 csproj**（其中 2 个是 `#20` 已修的那两个，本件把它们的
自带那一行**收掉**以完成"收敛"）。

**机器证明（全部求值级，逐字节）**：133 个工程前后各取一次 `-getItem:Compile` 清单 ⇒
**`plain` 清单 80/80 逐字节相同（`plain list MOVED = 0`）**；38 个编辑件的**"正确集合"逐位未变**、
而被 glob 收进来的仓内陈旧 `obj/**.cs` 条目 **78 → 0**（唯一例外是 §4.1 挂起的那个）。
**无位移**：`BRIDGE_SRC_FP=b6acdba4f01599d8`（与预登记 §5 的预测一致）、`pc=f4a454c8fe69cdfe` 未变。

**我推翻/修正的四条**：① 派单的暴露判据 **(a) 不是判别量**（33 个里有 **19** 个根本没设
`BaseOutputPath`/`BaseIntermediateOutputPath` 却照样暴露；反过来 (a)∧(b) 还**多收** 8 个并非暴露的工程）；
② **"还有 7 个"** 那个数是**只在 `build/MilBridge/tests/` 内部**成立的口径，全仓实测 **33**；
③ `#20` §9.1(1) 自报"未能把求值位次钉死"——本件用现场两极化把它钉死了（**与位次无关**）；
④ `#20` 在两个 csproj 注释里把机制只引注到 `DefaultOutputPaths.targets:126-127`，
**真正用 `$(BaseOutputPath)`/`$(BaseIntermediateOutputPath)` 的两条是
`Microsoft.NET.Sdk.DefaultItems.targets:35,37`**（两条都对，引注不全）。

---

## §1 步 1 —— 暴露集的**实测**枚举（派单 ①）

### 1.1 判定式（可复算，不靠"读起来像"）

一个工程在本趟判为**暴露** ⟺ 下面这条命令的输出里出现**工程目录下**的 `obj/` 或 `bin/` 条目：

```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet msbuild <proj> \
  -p:BaseOutputPath=$HOME/wfp-runs/w21-laneW21B/eval/bin/<n>/ \
  -p:BaseIntermediateOutputPath=$HOME/wfp-runs/w21-laneW21B/eval/obj/<n>/ \
  -getItem:Compile
```

* 全部 133 个 `*.csproj` 各跑 **2 趟**（`plain` = 无覆盖；`priv` = 上面的覆盖）＋ 1 趟读 `DefaultItemExcludes`，
  单趟 **399** 次求值、**前＋后两趟共 798 次**。**没有任何一次是构建**：`-getItem`/`-getProperty` 是求值趟，
  `$S/eval*/` 目录**从未被创建**（`find $S/eval* -type f | wc -l` ⇒ **0**），`obj/`+`bin/` 的**文件清单前后
  `diff` 为空**（§3.6）。
* `dotnet` 只在 `export PATH="$HOME/.dotnet:$PATH"` 之后可用（本机 `10.0.111`）；`rc=127` 没出现过。
* 判定：`canon.py` 把 JSON 里的 `Compile` 项按 `Identity\tFullPath` 排序输出；**"条目数"= FullPath 里含
  `/obj/` 或 `/bin/` 的行数**。
* 脚本：`$HOME/wfp-runs/w21-laneW21B/{enum.sh,canon.py,analyze.py,compare.py,rollout.py}`；原始输出在
  `$HOME/wfp-runs/w21-laneW21B/logs/enum-{before,after}/`（每工程 3 份 JSON＋逐工程表 `table.tsv`）。

### 1.2 全表结果

| 量 | 数 | 说明 |
|---|---|---|
| 仓内 `*.csproj` | **133** | `find . -name '*.csproj'`（含 `upstream/wpf/**`） |
| 求值成功（`rc=0`） | **80** | |
| 求值失败 `EVALFAIL(rc=1)` | **53** | **全部**在 `upstream/wpf/**`（要 Windows/Arcade SDK）⇒ 这 53 个是 **NOINFO**，不是"不暴露" |
| **(M) 实测暴露** | **33** | 下表逐工程 |
| （对照）默认 glob 生效的工程 | 57 | `EnableDefaultItems != false` ∧ `EnableDefaultCompileItems != false`（80 个可求值者中） |
| （对照）其中"今天有陈旧 `obj/**.cs`" | 35 | = **33 暴露** ＋ **2 已由 `#20` 护住**（`TextLineProto`/`HbTextLineParity`） |
| （对照）其中"今天没有陈旧 `obj/**.cs`" | 22 | 形态暴露（§4.3） |

**自洽性检查**：33 个暴露工程里，`priv 条目数 == 仓内 `obj/**/*.cs` 文件数`，**逐工程全等**（脚本输出
`CONSISTENCY CHECK: rows where priv_objbin_entries != stale_obj_cs: 0`）⇒ glob 收进来的**恰好就是那些陈旧件**，
没有多也没有少。**全部 80 个可求值工程的 `plain` 条目数 = 0**（`plain` 路径从不收产物目录 ⇒ 判定式不是恒真；
53 个求值失败的工程 `plain` 无读数，是 NOINFO）。

### 1.3 (M) = 33，逐工程证据

（"csproj 自设 `Base*`?" = 该工程的 csproj 里有没有自己设 `BaseOutputPath` **且** `BaseIntermediateOutputPath`；
写 **no** 的那些用 SDK 默认 `obj\`（`Microsoft.NET.DefaultOutputPaths.targets:113`，实测读回
`BaseIntermediateOutputPath = obj\`，见 §1.4 的正控）。**逐工程**的 csproj 行号 + 仓内 `obj/**.cs`
文件全路径清单在 `$HOME/wfp-runs/w21-laneW21B/logs/exposed-evidence.txt`。）

| # | 工程 | csproj 自设 `Base*`? | 仓内 `obj/**/*.cs` | plain 条目 | **priv 条目** |
|---|---|---|---|---|---|
| 1 | `build/DirectWrite.Linux/FallbackCriteria/FallbackCriteria.csproj` | **no** | 2 | 0 | **2** |
| 2 | `build/DirectWrite.Linux/FontEntryClosedLoop/DirectWrite.Linux.FontEntryClosedLoop.csproj` | yes | 2 | 0 | **2** |
| 3 | `build/DirectWrite.Linux/Probe/DirectWrite.Linux.Probe.csproj` | yes | 2 | 0 | **2** |
| 4 | `build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj` | **no** | 4 | 0 | **4** |
| 5 | `build/DirectWrite.Linux/SystemFontsProbe/DirectWrite.Linux.SystemFontsProbe.csproj` | yes | 2 | 0 | **2** |
| 6 | `build/DirectWrite.Linux/Tests/DirectWrite.Linux.Tests.csproj` | **no** | 2 | 0 | **2** |
| 7 | `build/DirectWrite.Linux/WicClosedLoop/DirectWrite.Linux.WicClosedLoop.csproj` | yes | 2 | 0 | **2** |
| 8 | `build/DirectWrite.Linux/WicSeamProbe/DirectWrite.Linux.WicSeamProbe.csproj` | yes | 2 | 0 | **2** |
| 9 | `build/DirectWrite.Linux/WicWriteClosedLoop/DirectWrite.Linux.WicWriteClosedLoop.csproj` | yes | 2 | 0 | **2** |
| 10 | `build/DirectWrite.Linux/WiringSmoke/DirectWrite.Linux.WiringSmoke.csproj` | yes | 2 | 0 | **2** |
| 11 | `build/MilBridge/spike/AotLib/AotLib.csproj` | **no** | 2 | 0 | **2** |
| 12 | `build/MilBridge/spike/SmokeTest/SmokeTest.csproj` | **no** | 2 | 0 | **2** |
| 13 | `build/MilBridge/tests/BboxProbe/BboxProbe.csproj` | yes | 2 | 0 | **2** |
| 14 | `build/MilBridge/tests/CompositeFontProbe/CompositeFontProbe.csproj` | yes | 2 | 0 | **2** |
| 15 | `build/MilBridge/tests/ContractProbe/ContractProbe.csproj` | yes | 2 | 0 | **2** |
| 16 | `build/MilBridge/tests/FamilyCoverageSelfTest/FamilyCoverageSelfTest.csproj` | yes | 2 | 0 | **2** |
| 17 | `build/MilBridge/tests/IcuBreakParity/IcuBreakParity.csproj` | yes | 2 | 0 | **2** |
| 18 | `build/MilBridge/tests/LsProbe/LsProbe.csproj` | yes | 2 | 0 | **2** |
| 19 | `build/MilBridge/tests/T2eLineHeight/T2eLineHeight.csproj` | yes | 2 | 0 | **2** |
| 20 | `build/wic-abi-reference/AbiProbe/AbiProbe.csproj` | **no** | 2 | 0 | **2** |
| 21 | `samples/HelloMil/HelloMil.csproj` | **no** | 2 | 0 | **2** |
| 22 | `samples/HelloWpf/HelloWpf.csproj` | **no** | 8 | 0 | **8** |
| 23 | `samples/WpfFeatureProbe/WpfFeatureProbe.csproj` | **no** | 4 | 0 | **4** |
| 24 | `samples/WpfTextDemo/WpfTextDemo.csproj` | **no** | 4 | 0 | **4** |
| 25 | `src/WpfGfx.Linux/WpfGfx.Linux.csproj` | **no** | 2 | 0 | **2** |
| 26 | `tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj` | **no** | 2 | 0 | **2** |
| 27 | `tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMil.Tests.csproj` | **no** | 2 | 0 | **2** |
| 28 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj` | **no** | 2 | 0 | **2** |
| 29 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj` | **no** | 2 | 0 | **2** |
| 30 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj` | **no** | 2 | 0 | **2** |
| 31 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/WpfGfx.Linux.Windowing.Tests.csproj` | **no** | 2 | 0 | **2** |
| 32 | `tests/parity/geometry/u14/U14.csproj` | **no** | 2 | 0 | **2** |
| 33 | `tools/GeometryOracle/GeometryOracle.csproj` | **no** | 2 | 0 | **2** |

子树分布：`build/**` **20**（`DirectWrite.Linux` 10、`MilBridge/spike` 2、`MilBridge/tests` 7、`wic-abi-reference` 1）
｜`tests/**` **7**（`WpfGfx.Linux.Tests` 6、`parity/geometry/u14` 1）｜`samples/**` **4**｜`tools/**` **1**｜`src/**` **1**。

### 1.4 与派单判据 (a)∧(b) 的对照（**这条判据不成立**）

派单写：暴露 ⟺ **(a)** 工程把 `BaseOutputPath`/`BaseIntermediateOutputPath` 设成工程目录下的路径 **且**
**(b)** 工程目录下确实存在含 `*.cs` 的 `obj/`。按字面套：

| | 数 | |
|---|---|---|
| (a)∧(b) 判出的集合 | **22** | |
| 与**实测**暴露集的交集 | **14** | |
| **(a)∧(b) 漏掉的真暴露工程** | **19** | ↓ 下表 |
| (a)∧(b) **多收**的工程 | **8** | 6 个 `EnableDefaultCompileItems=false`（`CoverageProbe`/`DirectBranchCheck`/`InputTraceProbe`/`MinMaxProbe`/`PcLineOracle`/`StrictTierProbe`）＋ **2 个 `#20` 已修的**（`TextLineProto`/`HbTextLineParity`） |

**漏掉的 19 个（(a) 为假却实测暴露）**：

| 工程 | 仓内 `obj/**/*.cs` | priv 条目 | csproj 里 `BaseOutputPath` | `BaseIntermediateOutputPath` |
|---|---|---|---|---|
| `build/DirectWrite.Linux/FallbackCriteria/FallbackCriteria.csproj` | 2 | **2** | 未设 | 未设 |
| `build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj` | 4 | **4** | 未设 | 未设 |
| `build/DirectWrite.Linux/Tests/DirectWrite.Linux.Tests.csproj` | 2 | **2** | 未设 | 未设 |
| `build/MilBridge/spike/AotLib/AotLib.csproj` | 2 | **2** | 未设 | 未设 |
| `build/MilBridge/spike/SmokeTest/SmokeTest.csproj` | 2 | **2** | 未设 | 未设 |
| `build/wic-abi-reference/AbiProbe/AbiProbe.csproj` | 2 | **2** | 未设 | 未设 |
| `samples/HelloMil/HelloMil.csproj` | 2 | **2** | 未设 | 未设 |
| `samples/HelloWpf/HelloWpf.csproj` | 8 | **8** | 未设 | 未设 |
| `samples/WpfFeatureProbe/WpfFeatureProbe.csproj` | 4 | **4** | 未设 | 未设 |
| `samples/WpfTextDemo/WpfTextDemo.csproj` | 4 | **4** | 未设 | 未设 |
| `src/WpfGfx.Linux/WpfGfx.Linux.csproj` | 2 | **2** | 未设 | 未设 |
| `tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj` | 2 | **2** | 未设 | 未设 |
| `tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMil.Tests.csproj` | 2 | **2** | 未设 | 未设 |
| `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj` | 2 | **2** | 未设 | 未设 |
| `tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj` | 2 | **2** | 未设 | 未设 |
| `tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj` | 2 | **2** | 未设 | 未设 |
| `tests/WpfGfx.Linux.Tests/Windowing.Tests/WpfGfx.Linux.Windowing.Tests.csproj` | 2 | **2** | 未设 | 未设 |
| `tests/parity/geometry/u14/U14.csproj` | 2 | **2** | 未设 | 未设 |
| `tools/GeometryOracle/GeometryOracle.csproj` | 2 | **2** | 未设 | 未设 |
| **小计** | | **19** | | |

**为什么 (a) 不是判别量**：`BaseOutputPath`/`BaseIntermediateOutputPath` 在 csproj 里**不设**时取 SDK 默认
`obj\`（**就在工程目录下**）。命令行 `-p:BaseIntermediateOutputPath=<仓外>` 把 `$(BaseIntermediateOutputPath)`
替成仓外值 —— 这与"工程自己把它设成工程目录下"**在机制上完全等价**：两条路都让"排除哪两条"从
`obj\` 变成 `<仓外>/…`。实测正控（`samples/HelloMil`，csproj 里两个属性**一个字都没有**）：

```
$ grep -n 'BaseOutputPath\|BaseIntermediateOutputPath' samples/HelloMil/HelloMil.csproj
  (无输出：一个都没有)
$ dotnet msbuild samples/HelloMil/HelloMil.csproj -getProperty:BaseIntermediateOutputPath
  obj\
$ dotnet msbuild samples/HelloMil/HelloMil.csproj -p:BaseIntermediateOutputPath=$S/eval2/obj/ -getItem:Compile | grep '"Identity"'
  "Identity": "obj/Debug/net10.0/.NETCoreApp,Version=v10.0.AssemblyAttributes.cs"      ← 仓内陈旧件被收进来了
  "Identity": "obj/Debug/net10.0/HelloMil.AssemblyInfo.cs"
```

**真正的判别量（实测交叉表得出）**：

| 判别量 | 说清什么 |
|---|---|
| ①**默认 `Compile` glob 生效** = `EnableDefaultItems != false` **且** `EnableDefaultCompileItems != false` | 不生效 ⇒ **结构上不可能**暴露（`CoverageProbe` 有 4 个陈旧件、`PcLineOracle` 有 2 个，实测 `priv=0`） |
| ②工程目录下**确实有** `obj/**/*.cs` | 决定"今天会不会红"（这些 `.cs` 是**任何一次普通构建**都会生成的 `AssemblyInfo`） |
| ③命令行把**中间目录**指到仓外 | 触发器；**只改 `BaseOutputPath` 不够**（§1.5） |

> ⚠️ **我自己的一处口径缺陷（记档）**：第一版分析我只用 `EnableDefaultCompileItems` 当①，于是
> `build/PresentationBuildTasks.Linux`（`stale=2`、`priv=0`）看起来像"反例"。现场复读找到原因：它的
> csproj:4 是 **`<EnableDefaultItems>false</EnableDefaultItems>`**（**另一个**开关，整组默认 glob 一起关掉）。
> 补上 `EnableDefaultItems` 之后口径自洽（§1.2 的 57/35/22 就是修正后的数）。

### 1.5 触发器**分离实验**：到底是哪个 `-p:` 造成的

在**本件唯一没修**的暴露工程（`src/WpfGfx.Linux`，仓内 2 个陈旧件）上做三变体：

```
variant 0  无覆盖                          ⇒ 70 个 Compile 项，obj/bin 条目 0
variant 1  ONLY -p:BaseIntermediateOutputPath=<仓外>  ⇒ obj/Debug/net10.0/.NETCoreApp,Version=v10.0.AssemblyAttributes.cs
                                                        obj/Debug/net10.0/WpfGfx.Linux.AssemblyInfo.cs      ← 2 条
variant 2  ONLY -p:BaseOutputPath=<仓外>              ⇒ obj/bin 条目 0
```
⇒ **暴露由"中间目录被改指向"单独触发**（`-p:BaseIntermediateOutputPath=…` **一条就够**）；
`BaseOutputPath` 那一半**不是** `obj` 泄漏的成因。这与 SDK 的四条排除一致：

```
Microsoft.NET.Sdk.DefaultItems.targets:35    <DefaultItemExcludes>$(DefaultItemExcludes);$(BaseOutputPath)/**</…>
Microsoft.NET.Sdk.DefaultItems.targets:37    <DefaultItemExcludes>$(DefaultItemExcludes);$(BaseIntermediateOutputPath)/**</…>
Microsoft.NET.DefaultOutputPaths.targets:126 <DefaultItemExcludes>$(DefaultItemExcludes);$(OutputPath)/**</…>
Microsoft.NET.DefaultOutputPaths.targets:127 <DefaultItemExcludes>$(DefaultItemExcludes);$(IntermediateOutputPath)/**</…>
```
（`#20` 的注释只引了 126-127；**35/37 才是直接用 `Base*` 的那两条**。这四条全是"当前生效值"的绝对路径，
所以中间目录一改指向，**四条同时失效**。）

### 1.6 计数器的正控 / 负控（纪律 25）

| 控制 | 读数 | 说明 |
|---|---|---|
| 正控①（判定式不恒真） | **80** 个可求值工程的 `plain` 条目数 **全 0** | 判定式在"正常情形"必须读 0，实测确实 0 |
| 正控②（两极化，逐工程） | 32 个工程 `priv 2/4/8 → 0` | 同一个文件、同一命令，**唯一输入差 = 那一行**（§3.4） |
| **负控**（判定式不只看"有没有陈旧件"） | `CoverageProbe`：仓内 **4** 个陈旧 `obj/**.cs` 在场，`priv` 条目 **0** | ⇒ 判定式读的是①（glob 是否生效），不是"目录里有没有陈旧件" |
| 确定性正控 | 同一工程同一命令跑两趟，JSON `cmp` **逐字节相同** | `cmp det1.json det2.json` ⇒ IDENTICAL |

---

## §2 步 2 —— 共享 `.props` 的**落点**与理由（派单 ②）

### 2.1 候选盘点（含两个**被否决**的落点，理由都是实测的）

| 落点 | 覆盖 | 否决/采纳理由 |
|---|---|---|
| **A. `build/MilBridge/tests/Directory.Build.props`**（`#20` §9.2 的建议） | 只覆盖 `tests/**` 的一部分 | **否决×2**：① 实测暴露集有 **20/33 在 `tests/` 之外**（`build/DirectWrite.Linux` 10、`samples` 4、`src` 1、`tools` 1、`tests/WpfGfx.Linux.Tests` 6 …）⇒ 覆盖不到一半；② 它会**自动导入进 `PcLineOracle`** —— 而**另一条车道此刻正在跑它**：实测 `build/MilBridge/tests/PcLineOracle/Program.cs` mtime **18:31:09**、`bin/Release/PresentationCore.Tests.dll` mtime **18:31:13**（我全程没构建过任何东西，这两条 mtime 只能来自并肩车道 = P1 落判据那一趟）。往那条构建的求值里塞新输入 = **污染归因**（`#20` §3.1 自己也写了这条理由）。 |
| **B. 仓库根 `Directory.Build.props`** | 除"有更近的 `Directory.Build.props` 的子树"外全仓 | **否决×2**：① 仓内**已有**两处更近的、会**截断**自动导入：`build/DirectWrite.Linux/Directory.Build.props`、`build/PresentationBuildTasks.Linux/Directory.Build.props`（MSBuild 取**最近**的一个）⇒ 放在仓根会**恰好漏掉 `build/DirectWrite.Linux`** 那 10 个暴露工程，而"补一个导入文件"就不再是"一个文件"；② 它会给本仓**约 120 个工程**（含正在被 P1 重建的 `build/PresentationCore.Linux` 等权威工程）各注入一个新的求值输入 —— 在我**无法构建验证**、且**并肩车道正在构建**的趟里，这是不能付的。 |
| **C. 仓根 `BuildHygiene.props`（**采纳**）＋ 逐工程一行显式 `<Import>`** | **恰好** = 实测暴露集（+ `build/MilBridge/tests/` 整个子树，见 §2.3） | 排除**文本只有一份**（收敛达成）；作用域 = 我**逐个证明过**的那 38 个；任何时候 `grep -rl BuildHygiene.props` 扫 `*.csproj` 就是**全部用户**（可审计）；对权威工程/并肩车道的仪器**零求值改动**。 |
| D. 在 `build/MilBridge/tests/` 建一个**不叫** `Directory.Build.props` 的文件 | 同 C | 与 C 同效，但路径离 `samples/`、`src/` 太远，语义上像"MilBridge tests 专用"⇒ 选 C（仓根）。 |

### 2.2 **指纹硬约束**（这决定了落点只能选 C，且决定了有一个工程不能修）

`build/bridge-src-fp.sh:42-46` —— `BRIDGE_SRC_FP` 的文件清单是：

```bash
find src/WpfGfx.Linux build/MilBridge \
    \( -name bin -o -name obj -o -name .artifacts \
       -o -path 'build/MilBridge/tests' -o -path 'build/MilBridge/alt-route-b' -o -path 'build/MilBridge/spike' \) -prune -o \
    -type f \( -name '*.cs' -o -name '*.csproj' -o -name '*.props' -o -name '*.targets' -o -name '*.resx' \) -print
```

⇒ **`*.csproj` / `*.props` 都在指纹里**。实测 `--list` 里就有
`f38feba94f6f788f  src/WpfGfx.Linux/WpfGfx.Linux.csproj` 与 `7db47d37b943f312  build/MilBridge/src/MilBridge.Linux/MilBridge.Linux.csproj`。
而预登记 **§5** 把 `BRIDGE_SRC_FP` 冻结为**不变**（`b6acdba4f01599d8`）、§7.1 又写"任何位移落在 §5 表外 ⇒ 触即停"。两条推论：

1. **共享 props 必须放在两个指纹根之外** ⇒ 仓根（实测：落完后 `BRIDGE_SRC_FP=b6acdba4f01599d8`，**未变**，§3.5）。
   （放在 `build/MilBridge/` 下会**直接改指纹** ⇒ 触发 §7.1 停条件。）
2. **`src/WpfGfx.Linux/WpfGfx.Linux.csproj` 不能动**（它自己在指纹里）⇒ 它是 33 个暴露工程里**唯一**
   被我**有意留下**的，按 §4.1 挂起给主控裁定。

### 2.3 文件内容 + sha16

`BuildHygiene.props`（仓根，**新增**，全仓唯一一份排除实现）：

```xml
<Project>
  <PropertyGroup>
    <DefaultItemExcludes>$(DefaultItemExcludes);obj/**;bin/**</DefaultItemExcludes>
  </PropertyGroup>
</Project>
```
（文件里有 60 行长注释：机制的四条 SDK 引注、为什么这一行在 `-getItem` 上生效、为什么不叫
`Directory.Build.props`、为什么不要加 `Exists()` 条件、以及指纹边界。）

| 件 | sha16 | 大小 | mtime |
|---|---|---|---|
| `BuildHygiene.props`（新） | **`c88fcccde138263b`** | 4510 B | 2026-09-16 18:28:23.446818868 +0800 |

**逐工程改动 = 在 `<Project …>` 元素之后插一行**（其余一字未动）：

```xml
  <Import Project="$([MSBuild]::GetPathOfFileAbove('BuildHygiene.props'))" />
```

三处刻意的选择：
1. **`GetPathOfFileAbove` 而不是相对路径** —— 38 个工程的深度各不相同（`build/MilBridge/spike/AotLib/` 到
   `tests/WpfGfx.Linux.Tests/Presentation.Tests/`），相对路径要逐个算深度、写错就是静默失效；这个函数
   与深度无关。**实测已解析到**（`-preprocess`）：`samples/WpfTextDemo` 的展开件里第 12–14 行就是
   `<Import Project="$([MSBuild]::GetPathOfFileAbove('BuildHygiene.props'))">` → `/…/wpf-linux/BuildHygiene.props`。
2. **不加 `Condition="Exists(…)"`** —— 文件找不到要**大声失败**（`MSB4024`），不要静默不受保护。
   *这条不是空谈*：我第一版 props 的注释里写了 `--`，MSBuild 直接
   `error MSB4024: 未能加载导入的项目文件…An XML comment cannot contain '--'` ⇒ **大声失败了**，
   我当场改掉（`#20` §9.3① 栽在同一个坑：XML 注释里的 `<`/`>`）。这正是"宁响不哑"的价值。
3. **38 个的构成**：`33`（实测暴露）− `1`（`src/WpfGfx.Linux`，按 §4.1 挂起）= `32`；`+ 4`（`build/MilBridge/tests/` 里
   今天无陈旧件的形态暴露件，预防性封：`ClosedLoop`/`HbSpike`/`ResolverGuardProbe`/`T2Repro`）；
   `+ 2`（`#20` 已修的两个，本件把它们的自带那一行**收掉**换成同一行 Import）⇒ **38**。
   明细与 before/after sha16：

| # | 工程 | before sha16 | after sha16 | before B | after B |
|---|---|---|---|---|---|
| 1 | `build/DirectWrite.Linux/FallbackCriteria/FallbackCriteria.csproj` | `35e4fa301f8aae7c` | **`e566405b5698e53a`** | 2532 | 2956 |
| 2 | `build/DirectWrite.Linux/FontEntryClosedLoop/DirectWrite.Linux.FontEntryClosedLoop.csproj` | `d5d9beaa8e75354b` | **`d94254348ae8db03`** | 3271 | 3695 |
| 3 | `build/DirectWrite.Linux/Probe/DirectWrite.Linux.Probe.csproj` | `03e05aa6a20c4f43` | **`e0d703376d7fd45e`** | 1973 | 2397 |
| 4 | `build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj` | `8daf86e83784446a` | **`7c674ac0059407cc`** | 2262 | 2686 |
| 5 | `build/DirectWrite.Linux/SystemFontsProbe/DirectWrite.Linux.SystemFontsProbe.csproj` | `10d3e4efb8cb6c3e` | **`1230ce4162779597`** | 3574 | 3998 |
| 6 | `build/DirectWrite.Linux/Tests/DirectWrite.Linux.Tests.csproj` | `7a880681fa1056c9` | **`244ed6aad02b25de`** | 4552 | 4976 |
| 7 | `build/DirectWrite.Linux/WicClosedLoop/DirectWrite.Linux.WicClosedLoop.csproj` | `46e0155f88ef2755` | **`8ee7dd3feb1a6df3`** | 3265 | 3689 |
| 8 | `build/DirectWrite.Linux/WicSeamProbe/DirectWrite.Linux.WicSeamProbe.csproj` | `b9c5ae0fb8ca431e` | **`41be9c3d96256bef`** | 881 | 1305 |
| 9 | `build/DirectWrite.Linux/WicWriteClosedLoop/DirectWrite.Linux.WicWriteClosedLoop.csproj` | `cc46fef28981fc77` | **`19fd9a1c6f9cbe35`** | 3270 | 3694 |
| 10 | `build/DirectWrite.Linux/WiringSmoke/DirectWrite.Linux.WiringSmoke.csproj` | `a7fc6872cfacdbc1` | **`f242ede737b37b13`** | 3923 | 4347 |
| 11 | `build/MilBridge/spike/AotLib/AotLib.csproj` | `d9a571400cd6506f` | **`cf2b90f68f100b07`** | 1256 | 1680 |
| 12 | `build/MilBridge/spike/SmokeTest/SmokeTest.csproj` | `00dd2b3903996c28` | **`f3a43c8c9fbef35c`** | 751 | 1175 |
| 13 | `build/MilBridge/tests/BboxProbe/BboxProbe.csproj` | `f6c244070c08aabc` | **`2379f34e6931ebe6`** | 825 | 1248 |
| 14 | `build/MilBridge/tests/ClosedLoop/ClosedLoop.csproj` | `21fa957ab1daf8df` | **`4774df3ecc2a4e4b`** | 1337 | 1761 |
| 15 | `build/MilBridge/tests/CompositeFontProbe/CompositeFontProbe.csproj` | `cbfc8160c2486448` | **`efce54ae8ed6624f`** | 2897 | 3321 |
| 16 | `build/MilBridge/tests/ContractProbe/ContractProbe.csproj` | `3413d20cdd4a63d3` | **`270a4d23c8e9b394`** | 1811 | 2235 |
| 17 | `build/MilBridge/tests/FamilyCoverageSelfTest/FamilyCoverageSelfTest.csproj` | `f17bb7db17e7fe5f` | **`a575b6a2adc7b8cb`** | 1756 | 2180 |
| 18 | `build/MilBridge/tests/HbSpike/HbSpike.csproj` | `ffbe4b2a7bba616e` | **`07a2fcc9cf0ecba9`** | 1770 | 2194 |
| 19 | `build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj` | `9817ae51e9b1322d` | **`39254abec84698d3`** | 4167 | 4591 |
| 20 | `build/MilBridge/tests/IcuBreakParity/IcuBreakParity.csproj` | `eb617bc808e0b048` | **`0cd720008d3ddf4f`** | 1933 | 2357 |
| 21 | `build/MilBridge/tests/LsProbe/LsProbe.csproj` | `d5281a8a83c94f89` | **`a62cd5acb8cde57a`** | 771 | 1195 |
| 22 | `build/MilBridge/tests/ResolverGuardProbe/ResolverGuardProbe.csproj` | `f303d8cfc0b638bd` | **`ece22ef0afc8b176`** | 2206 | 2630 |
| 23 | `build/MilBridge/tests/T2Repro/T2Repro.csproj` | `fa906d8c7208177a` | **`fd65cfe42abb4644`** | 1540 | 1964 |
| 24 | `build/MilBridge/tests/T2eLineHeight/T2eLineHeight.csproj` | `d841f107babcfb87` | **`580143e56045cfef`** | 2187 | 2611 |
| 25 | `build/MilBridge/tests/TextLineProto/TextLineProto.csproj` | `60abebef17522b8c` | **`6f4c044d2f984138`** | 3321 | 3745 |
| 26 | `build/wic-abi-reference/AbiProbe/AbiProbe.csproj` | `1b7b7f451d78ad88` | **`079941617a70ad5a`** | 501 | 925 |
| 27 | `samples/HelloMil/HelloMil.csproj` | `7c4e743c8cf0d08e` | **`8aafe53a0c6eed14`** | 2262 | 2686 |
| 28 | `samples/HelloWpf/HelloWpf.csproj` | `6fbeed9fc4a27119` | **`adf75e82d524ad36`** | 28001 | 28425 |
| 29 | `samples/WpfFeatureProbe/WpfFeatureProbe.csproj` | `d283fe7a2f08a3be` | **`6757356393a2dcc5`** | 12713 | 13137 |
| 30 | `samples/WpfTextDemo/WpfTextDemo.csproj` | `bfa6356c2837e0fa` | **`d944499407ce59ec`** | 12733 | 13157 |
| 31 | `tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj` | `d1089d1cad85567e` | **`04d9884234fc8c9c`** | 2259 | 2683 |
| 32 | `tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMil.Tests.csproj` | `5e733fe6fd599a8f` | **`354e8d1f636870d2`** | 2840 | 3264 |
| 33 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj` | `2ac4d1e10c852298` | **`9dc842183230b201`** | 6811 | 7235 |
| 34 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj` | `3d88a79bc054b6e7` | **`365f54dbe3c08723`** | 5255 | 5679 |
| 35 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj` | `e969fed4fc5c1923` | **`fa1abe39e5acf816`** | 2657 | 3081 |
| 36 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/WpfGfx.Linux.Windowing.Tests.csproj` | `35968911f658c9f0` | **`8bb5767bfde2339f`** | 2769 | 3193 |
| 37 | `tests/parity/geometry/u14/U14.csproj` | `99db2d18dce8ee6b` | **`1936ad70116cca57`** | 1076 | 1500 |
| 38 | `tools/GeometryOracle/GeometryOracle.csproj` | `1ff1e5bfc10c33c2` | **`42914ece1a1d74d4`** | 1000 | 1424 |
| | **38 个文件（37 由 rollout.py + BboxProbe 手改）** | | | | |

**收敛**（本件的"收敛"这个词的落点）：`TextLineProto.csproj` 与 `HbTextLineParity.csproj` 里 `#20` 加的那一行
`<DefaultItemExcludes>` **已删除**（连同它上面那段只引 126-127 的注释改写为指向共享 props + 引全 35/37），
理由：排除文本必须只有一份。**这是**有意收敛，**不是**删漏 —— 删前删后清单 `cmp` 逐字节相同（§3.3）。
此处用到派单的"除非你同时给出步 3 的逐字节清单证明"这一条许可。38 个文件的 `cp -p` 备份在
`$HOME/wfp-runs/w21-laneW21B/backup/*.csproj.before`（**38** 份，`sha16` 与 §2.3 表的 before 列逐条相同）。

---

## §3 步 3 —— 证明（派单 ③）

### 3.1 方法 + 确定性

* `canon.py`：把 `-getItem:Compile` 的 JSON 归一化成 `Identity\tFullPath` 排序行（`ModifiedTime` 等易变字段不入），
  再 `cmp` **逐字节**比较。**不看"有没有 error"**（`#20` 的教训）。
* 每个工程 4 份清单：`{before,after} × {plain, priv}`；**解析失败（无 JSON）= NOINFO**，`canon.py` 返回 `rc=2`，
  绝不把"求值失败"当成"空清单"（`compare.py` 把它记 `NOINFO`）。
* 确定性正控：同工程同命令两趟 JSON `cmp` 相同（§1.6）。

### 3.2 总表（133 个工程）

```
projects compared                      : 133
plain Compile list byte-identical      : 80      ← 80 = 全部求值成功的工程
plain list MOVED (must be 0)           : 0       ← 派单的停条件：未触发
still exposed after fix                : 1       ← src/WpfGfx.Linux（§4.1 有意挂起）
NOINFO (evaluation failed)             : 53      ← upstream/wpf/**（§4.5）
exposed before, clean after            : 32
```

⇒ **两条判据同时成立**：① "放完之后全仓没有任何工程的 `plain` 清单发生位移"（0 位移）；
② "实测暴露集里除 1 个挂起件外，`priv` 场景下的仓内产物条目全部归零"。

### 3.3 两个**世代相邻**工程的 `cmp` 证据（派单点名要求）

```
build__MilBridge__tests__TextLineProto__TextLineProto        plain  cmp: IDENTICAL  (2 entries)
build__MilBridge__tests__TextLineProto__TextLineProto        priv   cmp: IDENTICAL  (2 entries)
build__MilBridge__tests__HbTextLineParity__HbTextLineParity  plain  cmp: IDENTICAL  (2 entries)
build__MilBridge__tests__HbTextLineParity__HbTextLineParity  priv   cmp: IDENTICAL  (2 entries)
```
8 份清单文件只有 **2 个** sha16（每工程 1 个 ⇒ `plain==priv==before==after` 四者全同）：

| 工程的 4 份清单（before/after × plain/priv） | sha16 | 条目 |
|---|---|---|
| `TextLineProto` | `8c9bd6533211058e` | `Program.cs`、`../../../shims/PresentationCore.HbTextLine.cs` |
| `HbTextLineParity` | `9c7b5efaef23737c` | `Program.cs`、`$(MSBuildThisFileDirectory)../../../shims/PresentationCore.HbTextLine.cs` |

**结论**：这两个工程**删掉自带那一行、改走共享 props 之后**，编译文件集合**逐字节未变** ⇒ 派单的
"清单动了 ⇒ 停并报告"**未触发**。

### 3.4 逐工程两极化（38 个编辑件）

| 列 | 含义 |
|---|---|
| 判定 | `OK` = `plain` 未位移 且 `priv` 产物条目已归零；`*** STILL EXPOSED ***` = 仍暴露（§4.1） |
| plain 前后 | `True` = 该工程**普通场景**的 `Compile` 清单前后**逐字节相同** |
| priv 产物条目 | `before → after`：命令行把中间目录指到仓外时，被 glob 收进来的仓内 `obj`/`bin` 条目数 |
| 正确集合 | `True` = 去掉产物条目后的清单**逐位相同**（"该编的一个没少"） |

| 工程 | 判定 | plain 前后 | priv 产物条目 | 正确集合 |
|---|---|---|---|---|
| `build/DirectWrite.Linux/FallbackCriteria/FallbackCriteria.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/DirectWrite.Linux/FontEntryClosedLoop/DirectWrite.Linux.FontEntryClosedLoop.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/DirectWrite.Linux/Probe/DirectWrite.Linux.Probe.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj` | OK | `True` | **4 → 0** | `True` |
| `build/DirectWrite.Linux/SystemFontsProbe/DirectWrite.Linux.SystemFontsProbe.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/DirectWrite.Linux/Tests/DirectWrite.Linux.Tests.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/DirectWrite.Linux/WicClosedLoop/DirectWrite.Linux.WicClosedLoop.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/DirectWrite.Linux/WicSeamProbe/DirectWrite.Linux.WicSeamProbe.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/DirectWrite.Linux/WicWriteClosedLoop/DirectWrite.Linux.WicWriteClosedLoop.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/DirectWrite.Linux/WiringSmoke/DirectWrite.Linux.WiringSmoke.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/MilBridge/spike/AotLib/AotLib.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/MilBridge/spike/SmokeTest/SmokeTest.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/MilBridge/tests/BboxProbe/BboxProbe.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/MilBridge/tests/ClosedLoop/ClosedLoop.csproj` | OK | `True` | **0 → 0** | `True` |
| `build/MilBridge/tests/CompositeFontProbe/CompositeFontProbe.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/MilBridge/tests/ContractProbe/ContractProbe.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/MilBridge/tests/FamilyCoverageSelfTest/FamilyCoverageSelfTest.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/MilBridge/tests/HbSpike/HbSpike.csproj` | OK | `True` | **0 → 0** | `True` |
| `build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj` | OK | `True` | **0 → 0** | `True` |
| `build/MilBridge/tests/IcuBreakParity/IcuBreakParity.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/MilBridge/tests/LsProbe/LsProbe.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/MilBridge/tests/ResolverGuardProbe/ResolverGuardProbe.csproj` | OK | `True` | **0 → 0** | `True` |
| `build/MilBridge/tests/T2Repro/T2Repro.csproj` | OK | `True` | **0 → 0** | `True` |
| `build/MilBridge/tests/T2eLineHeight/T2eLineHeight.csproj` | OK | `True` | **2 → 0** | `True` |
| `build/MilBridge/tests/TextLineProto/TextLineProto.csproj` | OK | `True` | **0 → 0** | `True` |
| `build/wic-abi-reference/AbiProbe/AbiProbe.csproj` | OK | `True` | **2 → 0** | `True` |
| `samples/HelloMil/HelloMil.csproj` | OK | `True` | **2 → 0** | `True` |
| `samples/HelloWpf/HelloWpf.csproj` | OK | `True` | **8 → 0** | `True` |
| `samples/WpfFeatureProbe/WpfFeatureProbe.csproj` | OK | `True` | **4 → 0** | `True` |
| `samples/WpfTextDemo/WpfTextDemo.csproj` | OK | `True` | **4 → 0** | `True` |
| `src/WpfGfx.Linux/WpfGfx.Linux.csproj` | *** STILL EXPOSED *** | `True` | **2 → 2** | `True` |
| `tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj` | OK | `True` | **2 → 0** | `True` |
| `tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMil.Tests.csproj` | OK | `True` | **2 → 0** | `True` |
| `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj` | OK | `True` | **2 → 0** | `True` |
| `tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj` | OK | `True` | **2 → 0** | `True` |
| `tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj` | OK | `True` | **2 → 0** | `True` |
| `tests/WpfGfx.Linux.Tests/Windowing.Tests/WpfGfx.Linux.Windowing.Tests.csproj` | OK | `True` | **2 → 0** | `True` |
| `tests/parity/geometry/u14/U14.csproj` | OK | `True` | **2 → 0** | `True` |
| `tools/GeometryOracle/GeometryOracle.csproj` | OK | `True` | **2 → 0** | `True` |

**读法**：`priv_objbin` 那一列就是**两极化**（同一个文件、同一条命令，唯一输入差 = 那一行）；
`core_same=True` 说明**只**少了陈旧产物条目，**该编的一个没少**。
`ClosedLoop`/`HbSpike`/`ResolverGuardProbe`/`T2Repro` 是 `0->0`：它们**今天不暴露**（无陈旧件），本件是
**预防性**收口（`#20` §9.2 点名的"形态暴露但今天没有陈旧件"那一组，本件把它们连同 `tests/` 子树一起封掉）。

### 3.5 无位移（与预登记 §5 对照）

| 位 | 预登记 §5 预测 | 本件实测 | 判定 |
|---|---|---|---|
| `BRIDGE_SRC_FP` | **不变** `b6acdba4f01599d8` | `bash build/bridge-src-fp.sh` ⇒ **`BRIDGE_SRC_FP=b6acdba4f01599d8 BRIDGE_SRC_N=78`** | ✅ 对上（本件动的 38 个 csproj 与 1 个 props **都不在两个指纹根之下**） |
| `bridge` | 不变 | 未重发、未构建 ⇒ 无位移 | ✅（本件**不构建**） |
| `pc` | **变**（P1 的 shim 改动） | 开工 `f4a454c8fe69cdfe`（4,196,864 B，mtime 15:40:28）；18:35 仍 `f4a454c8fe69cdfe` | 本件**未动 `pc`**；它何时变是 P1 的事 |
| `inputs_fp` | **变**（覆盖 `build/shims/**/*.cs`） | 18:35 重算 `a2b74537427ecc4a…` | **不是我的位移**：18:31:48 **并肩车道改了 shim**（`fe1b7ed8fa3ed231` → `76089e1de586ac91`，283557 B）。`inputs_fp` 的覆盖面里**没有** `*.csproj`/`*.props`（`close-wave.sh:66-75` 只收脚本 + `build/shims/**.cs` + `src/WpfGfx.Linux/**.cs`）⇒ 本件的 38+1 个文件**不可能**动它。 |
| 五臂门禁 | P1 落地后**必然** `NOINFO/rc=2 tree_gen=advanced`（设计） | 见下（两个时点，逐字） | ✅ 与设计一致 |

**五臂门禁两个时点（逐字，`tline-gate.sh` 是只读读者：不跑 harness、不构建）**：

```
# 18:31:11（我的编辑全部落完之后、并肩车道改 shim 之前）
TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#19 tree_gen=same saved_shim=fe1b7ed8fa3ed231 gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2 outdir=/home/links-dev/wfp-runs/w21-laneW21B/gate
GATE_REASON=all-as-registered

# 18:35:xx（`build/shims/PresentationCore.HbTextLine.cs` 于 18:31:48 被并肩车道改动之后）
TLINE_GATE=NOINFO arms=5 red=1 green=0 noinfo_arm=4 registered=3 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#19 tree_gen=advanced saved_shim=76089e1de586ac91 gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2 outdir=/home/links-dev/wfp-runs/w21-laneW21B/gate2
GATE_REASON=noinfo-arms
```
⇒ **第一趟 `tree_gen=same`** 证明本件（38 csproj + 1 props）**没有动世代绑定的三项**（`run.sh 3e513e88a4fa4ec9`、
`HbTextLineParity/Program.cs 2e458928fc1577c2`、`shim fe1b7ed8fa3ed231`，`tline-gate.sh:135-137`）；
第二趟的 `advanced` **归因于 P1 的 shim 改动**（`saved_shim` 正是新 shim），是预登记 §5 明写的"设计，不是缺陷"。

### 3.6 "我没有写任何 `obj/`/`bin/`"的机器证明

| 证明 | 读数 |
|---|---|
| `obj/`+`bin/` 下的**文件清单**前后 `diff` | **空**（`tree-objbin-before.txt` vs `after.txt` 各 4436 行，`diff` 无输出） |
| 求值用的仓外目录是否被创建 | `find $S/eval* -type f \| wc -l` ⇒ **0**（目录本身都不存在） |
| 本趟改动落在磁盘上的路径 | `find . -newermt '18:22' -type f`（排除 `obj/bin/upstream`）⇒ 46 个，其中**我的** = 38 个 csproj ＋ `BuildHygiene.props` ＋（本报告）；其余是并肩车道的（`W21C-report.md` 18:28:50、`W21D-report.md` 18:28:37、`pc-line-step.sh` 18:26:33、`arm-logs/README.md` 18:25:29、`docs/WAVE21-PREREGISTRATION.md` 18:30:25、`PcLineOracle/Program.cs` 18:31:09、`shims/PresentationCore.HbTextLine.cs` 18:31:48） |
| 禁改件（逐条 sha16 未变） | `PcLineOracle/PcLineOracle.csproj` `b0bf270206fe9c09`（mtime 11:09:12，**且该目录下 `BuildHygiene` 零命中**）｜`run.sh` `3e513e88a4fa4ec9`｜`HbTextLineParity/Program.cs` `2e458928fc1577c2`｜`known-red.json` `3bf26e12f320dece`｜`tline-gate.sh` `b37a5c9f55ae71a4`｜`verify-all.sh`／`docs/**`／`samples/**`（除 4 个 csproj）／`tests/parity/**`（除 `geometry/u14`）**未动** |

---

## §4 我**没能**证明的部分（派单 ④，逐条 DEFERRED）

### 4.1 `src/WpfGfx.Linux/WpfGfx.Linux.csproj` —— **暴露但有意未修**（交主控裁定）

* 实测：仓内 2 个陈旧件（`obj/Debug/net10.0/{.NETCoreApp,Version=v10.0.AssemblyAttributes,WpfGfx.Linux.AssemblyInfo}.cs`），
  `priv 2 → 2`（**仍暴露**），`plain_same=True`。
* **不修的理由（硬）：** 它在 `BRIDGE_SRC_FP` 的覆盖面里（`bridge-src-fp.sh:45` 收 `src/WpfGfx.Linux/**/*.csproj`，
  实测 `--list` 里那一行是 `f38feba94f6f788f`），而预登记 §5 把 `BRIDGE_SRC_FP` 冻成**不变**、
  §7.1 写"表外位移 ⇒ 触即停" ⇒ 我改它一行就会把 `BRIDGE_SRC_FP` 顶掉、把 P1 的预测表顶破。
* **代价（实测）**：这个工程是本件 33 个暴露工程里**唯一**没被封住的；谁对它用私有 obj 手法（`-p:BaseIntermediateOutputPath=<仓外>`）
  仍会踩 `CS0579`。
* **建议**：在下一次**登记了 `BRIDGE_SRC_FP` 变化**的波里顺手加同一行 Import（改动 1 行，两极化/清单证明方法本件已给）。

### 4.2 `build/MilBridge/src/MilBridge.Linux/MilBridge.Linux.csproj` —— **形态暴露，未修**

同样在 `BRIDGE_SRC_FP` 里（`--list`: `7db47d37b943f312`）。今天 `stale=0` ⇒ **不暴露**（实测 `priv=0`），
但它在"默认 glob 生效"的 57 个工程里 ⇒ **一次普通构建就会长出 `obj/**.cs`，从此暴露**。**未修**，同上理由。

### 4.3 其余 18 个"形态暴露"工程 —— 今天不暴露，未修（登记）

（`stale=0` ⇒ 按派单的 (b) **不算暴露**；本件只预防性封了 `build/MilBridge/tests/` 那 4 个，其余保留不动，
理由：`tests/parity/**` 那 **17** 个是**真机记录器/冻结核对语料**的构件，本件不碰；`MilBridge.Linux` 见 §4.2。）

`build/MilBridge/src/MilBridge.Linux`｜`tests/parity/brushes/src/U1BrushOracle`｜`tests/parity/geometry/windows-harness/GeometryOracle.Win`｜
`tests/parity/systemfonts/src/U1SystemFontsOracle`｜`tests/parity/windows/{bidi/src/BidiOracle,font-fallback/src/FontFallback,layout-b34/src/LayoutOracle/LayoutOracle,modifier-close/src/ModifierClose,modifier-scope/src/ModifierScope,shaping/src/CjkOracle/CjkOracle,shaping/src/LayoutOracle/LayoutOracle,shaping/src/ShapingOracle,src/U1Parity,src/U1Recorder,tab-anchor/src/TabAnchorOracle,tab-rtl/src/TabRtlOracle,tab/src/TabOracle,tab-zero/src/TabZeroOracle}.csproj`

### 4.4 **真构建**的 `CS0579` 计数 —— **本件不许测**（NOINFO，不是"证明为 0"）

派单 §0 硬约束：本车道**完全不许** `dotnet build`/`run`/`restore` ⇒ 我**没有**取修后的 `0 error` 读数。
预登记 §2 也把"完整构建验证"明确推迟到 P1 落地后由主控在波尾做。
**我能给的替代（求值级，已实测）**：`-getItem:Compile` 里仓内 `obj/**/*.cs` 条目
**78 → 2**（余下那 2 条**全部**在 §4.1 那个未修工程里）；而 `#20` 已经实测过"这 78 条在场 ⇒ `CS0579`" 的那一半（`16×CS0579`）。
**我不知道、也不猜修后的 `CS0579` 精确条数**（陈旧件里只有**与 SDK 新生成那份重名**的
`Assembly*Attribute` 才会撞 ⇒ 条数不能从条目数推出来）。
**主控补测时的预期**：对 38 个已封工程各跑一次
`dotnet build -m:1 <proj> -p:BaseOutputPath=<仓外>/bin/ -p:BaseIntermediateOutputPath=<仓外>/obj/` ⇒
**`0 个错误`、`CS0579=0`**；`src/WpfGfx.Linux`（未封）仍应复现 `CS0579`（**这是一个可用的反极性对照**）。

### 4.5 `upstream/wpf/**` 的 53 个工程 —— **NOINFO**

`rc=1`（要 Windows/Arcade SDK）⇒ 求值不成立，**无法判定**暴露与否。
**侧面证据（静态，`find`）**：`upstream/wpf/**` 下**没有任何** `obj/**/*.cs`（全仓 `obj/**/*.cs` 的
60 个目录清单里没有一条在 `upstream/` 下）⇒ **今天**的暴露面为 0，但"结构上会不会暴露"**未测**。

### 4.6 `bin/**` 那一半**没有独立的两极化**

全仓 `bin/` 下没有任何 `*.cs`，默认 glob 也从不收 `*.dll` ⇒ **今天无法把 `bin/**` 与非 `bin` 形态分开测**。
`bin/**` 是**防御性的一半**（与 SDK 自己在 `DefaultOutputPaths.targets:133` 的写法同形），
**不是"证明了不需要"**，也**不是"证明了有效"**。

### 4.7 一处我**没有**独立验证的机制陈述

我**实测**了"属性写在工程体/顶部导入里都能被 glob 看到"（两极化，§3.4）；但**没有**独立验证 MSBuild
内部"先算完所有属性、再求值所有 Item"的分趟模型。本件**不依赖**那个模型：所有结论都建立在**两极化读数**上。
（`#20` §9.1(1) 把这件列成"未能建立"——本件把它**从"必要问题"降级为"不需要的问题"**：
位次不影响结论，因为两极化在两种位次上都成立。）

---

## §5 我推翻 / 修正了哪句话（派单 ⑤）

| # | 被推翻/修正的话 | 出处 | 反证（现场） |
|---|---|---|---|
| 1 | 暴露 ⟺ **(a)** 工程把 `Base*` 设成工程目录下路径 **且** (b) 有含 `*.cs` 的 `obj/` | W21B 派单 步1 | (a)∧(b) 判出 22 个，其中**只有 14** 个真暴露；**漏掉 19** 个真暴露工程（§1.4 表）。根因：**不设** `BaseIntermediateOutputPath` 时 SDK 默认就是 `obj\`（**工程目录下**）⇒ (a) 恒真，不是判别量。正控：`samples/HelloMil` 两个属性**一个都没写**，`-p:BaseIntermediateOutputPath=<仓外>` 后仍收进 2 条 |
| 2 | "还有 **7** 个"暴露工程 | W20B §9.2（它的口径是 `build/MilBridge/tests/*/*.csproj` 共 19 个） | 全仓实测 **33**。W20B 的 7 在**它的射程内（tests/）是对的**，但**不是全仓残项**：它没算 `build/DirectWrite.Linux`（10）、`build/MilBridge/spike`（2）、`build/wic-abi-reference`（1）、`samples`（4）、`src`（1）、`tests/WpfGfx.Linux.Tests`（6）、`tests/parity/geometry/u14`（1）、`tools`（1） |
| 3 | "`$(DefaultItemExcludes)` 那条 SDK 规则相对工程体的精确求值位次**未能钉死**" | W20B §9.1(1) | 本件不需要钉它：**位次不影响结论**。两种位次都实测成立（`#20` 的工程体一行 ∅→有效；本件把同一行搬到顶部 `<Import>` 里的 `.props` ⇒ 同样有效）。`-preprocess` 里两者都在 glob 之前（`BuildHygiene.props` 的赋值在展开件第 **75** 行、SDK 的 Compile glob 在第 **782** 行），但**决定性证据是两极化，不是行号** |
| 4 | 机制引注只到 `Microsoft.NET.DefaultOutputPaths.targets:126-127` | W20B §3.2 的两处 csproj 注释 | 直接用 `$(BaseOutputPath)`/`$(BaseIntermediateOutputPath)` 的是 **`Microsoft.NET.Sdk.DefaultItems.targets:35,37`**；126-127 用的是 `$(OutputPath)`/`$(IntermediateOutputPath)`。**四条共同作用**，缺一条就漏一类；我在收敛那两个 csproj 时把注释引全了 |
| 5 | "`-p:BaseOutputPath=…/-p:BaseIntermediateOutputPath=…` 一旦指到仓外 ⇒ `obj/` 不再被排除" | W20B §3.2 注释（把两者并列） | **只有中间目录那条是成因**：`-p:BaseIntermediateOutputPath=<仓外>` **单独**就复现（2 条陈旧件被收进）；`-p:BaseOutputPath=<仓外>` **单独**时 `obj/bin` 条目 **0**（§1.5 三变体） |
| 6 | 派单给的车道读的预登记 sha16 `9d1e2dddda5b24e8` | W21B 派单「当前冻结基线」段 | 该文件在我**开工后 3 分钟**被改（18:25:24 → `127be0d931d97adf`，18:30:25 → `5958cdb5b21010fb`）。**§2 正文逐字未变**，本件判据不受影响；但**引注已过期**（纪律 4 一族） |

---

## §6 未测清单（派单 ⑥）

1. **真构建读数**（`dotnet build` 的 `error CS` 计数、`SRC_STALE` 之类）—— 派单硬约束不许（§4.4）。
2. **`bin/**` 的独立两极化**（§4.6）。
3. **`upstream/wpf/**` 53 个工程的求值**（§4.5）。
4. **`src/WpfGfx.Linux/WpfGfx.Linux.csproj` 的修复**（§4.1，指纹冲突，交主控）。
5. **`build/MilBridge/src/MilBridge.Linux` 的修复**（§4.2，同上）。
6. **18 个形态暴露工程的预防性收口**（§4.3，含 16 个 `tests/parity/**` 记录器：本件**刻意不碰**）。
7. **本件对"应用门禁 / `verify-all`"的影响**：**本件不构建、不改产物**，且 `plain` 清单全仓 0 位移 ⇒
   预期**逐位不变**；但**未测**（不能跑）。
8. **MSBuild 内部分趟模型的独立验证**（§4.7）。
9. **其它车道在我这趟期间改动的那些件的读数**（`W21C/W21D` 报告、`pc-line-step.sh`、`PcLineOracle/Program.cs`、
   `shims/**.cs`、`docs/WAVE21-PREREGISTRATION.md`）—— 我只做**mtime/sha 归因**，不解释其内容。

---

## §7 读数表（纪律 32）

| # | 时刻（+08:00） | `loadavg` | `mem_available` | `lane` | `kernel` | `pc` sha16 | 备注 |
|---|---|---|---|---|---|---|---|
| 1 | 2026-09-16 18:22:32 | 0.22 0.14 0.05 | 3790164 kB | W21B | 6.8.0-138-generic | `f4a454c8fe69cdfe` | 开工：读预登记、盘落点、跑前趟枚举（133 工程） |
| 2 | 2026-09-16 18:31:31 | 2.52 1.93 1.04 | 3360276 kB | W21B | 6.8.0-138-generic | `f4a454c8fe69cdfe` | 38 个 csproj 已改完；五臂门禁第 1 趟 `tree_gen=same`；并肩车道正在构建 `PcLineOracle` |
| 3 | 2026-09-16 18:35:35 | 2.10 2.08 1.32 | 3530076 kB | W21B | 6.8.0-138-generic | `f4a454c8fe69cdfe` | 后趟枚举 + 逐工程 `cmp` 完成；`BRIDGE_SRC_FP` 未变；并肩车道 18:31:48 已改 shim |

| 仪器/件 | sha16 | 大小 | mtime |
|---|---|---|---|
| `BuildHygiene.props`（新，仓根） | `c88fcccde138263b` | 4510 | 2026-09-16 18:28:23.446818868 |
| `enum.sh` / `canon.py` / `analyze.py` / `compare.py` / `rollout.py` | 见 `$S/`（脚本，非仓内件） | — | 18:23–18:29 |
| 前/后趟原始读数（各 133×3 份 JSON + `table.tsv`） | — | — | `$S/logs/enum-{before,after}/` |
| 归一分钟表（before/after） | `$S/logs/compare.txt` | 6.0 KB | 18:34 |
| 38 份 `cp -p` 备份 | `$S/backup/*.csproj.before` | 38 份 | 18:28–18:30 |

---

## §8 复现命令（一条条抄就能重算）

```bash
export PATH="$HOME/.dotnet:$PATH"
export MSBUILDDISABLENODEREUSE=1 DOTNET_CLI_USE_MSBUILD_SERVER=0
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd $R
S=$HOME/wfp-runs/w21-laneW21B

# ① 全仓暴露集重算（求值，不构建）：33 个
bash $S/enum.sh repro                      # ⇒ $S/logs/enum-repro/table.tsv
python3 $S/analyze.py $S/logs/enum-repro/table.tsv | head -6    # ⇒ (M) measured exposed = 33

# ② 单个工程的两极化（以 BboxProbe 为例；把 csproj 换回 $S/backup/*.before 即修前）
dotnet msbuild build/MilBridge/tests/BboxProbe/BboxProbe.csproj \
  -p:BaseOutputPath=$S/x/bin/ -p:BaseIntermediateOutputPath=$S/x/obj/ -getItem:Compile \
  | grep '"Identity"'                      # 修前 ⇒ 含 2 条 obj/Release/*.cs；修后 ⇒ 只剩 Program.cs

# ③ 触发器分离（§1.5）
P=src/WpfGfx.Linux/WpfGfx.Linux.csproj
dotnet msbuild $P -p:BaseIntermediateOutputPath=$S/x/obj/ -getItem:Compile | grep '"Identity"' | grep obj/   # ⇒ 2 条
dotnet msbuild $P -p:BaseOutputPath=$S/x/bin/            -getItem:Compile | grep '"Identity"' | grep obj/   # ⇒ 0 条

# ④ 全仓逐字节证明（前后各跑一趟 enum，再归一对拍）：plain MOVED=0
python3 $S/compare.py $S/logs/enum-before $S/logs/enum-after $S/logs/edit-list.txt

# ⑤ 无位移
bash build/bridge-src-fp.sh                # ⇒ BRIDGE_SRC_FP=b6acdba4f01599d8 BRIDGE_SRC_N=78
sha256sum build/PresentationCore.Linux/bin/Debug/PresentationCore.dll | cut -c1-16   # ⇒ f4a454c8fe69cdfe
bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs --outdir $S/gate3   # 只读读者
```

---

## §9 交底：本趟的并发环境（不解释别人的内容，只记我看到的）

| 时刻 | 现场 | 与本件的关系 |
|---|---|---|
| 18:25:24 / 18:30:25 | `docs/WAVE21-PREREGISTRATION.md` 被改两次（`9d1e2dddda5b24e8` → `127be0d931d97adf` → `5958cdb5b21010fb`） | §2 正文逐字未变 ⇒ 判据不变；引注过期已记（§5#6） |
| 18:26:33 | `build/MilBridge/tools/pc-line-step.sh` 被改 | 与本件无关（不是我的写域，未读未改） |
| 18:28:37 / 18:28:50 | `build/MilBridge/W21D-report.md`、`W21C-report.md` 落盘 | 并肩车道在写报告 |
| **18:31:09 / 18:31:13** | `build/MilBridge/tests/PcLineOracle/Program.cs` 被改、其 `bin/Release/*.dll` 被重建 | **这是我不放 `tests/Directory.Build.props` 的直接现场依据**（§2.1-A） |
| **18:31:48** | `build/shims/PresentationCore.HbTextLine.cs` `fe1b7ed8fa3ed231` → **`76089e1de586ac91`**（278692 → 283557 B） | P1 落地 ⇒ `inputs_fp`/五臂 `tree_gen` 随之而变（**不是我的位移**） |
| 全程 | `pc` 未变（`f4a454c8fe69cdfe`）；我**一次构建都没跑** | 本件读数可归因 |
