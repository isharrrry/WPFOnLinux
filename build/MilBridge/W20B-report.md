# W20B 报告 —— `D-R8` 修复（私有 obj 重定向把**仓内陈旧 `obj/`** 收进默认 glob）

`lane=W20B` ｜ 日期时间 **2026-09-16 16:14:30 – 16:19:20 +08:00** ｜ `loadavg` **0.47→1.85**（逐趟见 §8）｜ `mem_available` **3729→3067 MiB** ｜ `kernel` **6.8.0-138-generic**
写域：`build/MilBridge/tests/{TextLineProto,HbTextLineParity}/*.csproj` + `build/MilBridge/W20B-report.md` + `$HOME/wfp-runs/w20-laneW20B/`。**其它仓内文件一个字节未动**（§2.5、§6.5 机器证明）。

---

## 1. 一句话判决

**臂建成说法不适用；本件判据全部成立**：两个 csproj 各加**一行** `DefaultItemExcludes` 后，① 私有 obj 重定向 + 仓内陈旧 `AssemblyInfo` ⇒ **修前 `16 个错误`（全 `CS0579`）/ 修后 `0 个错误`**（同名同树同配置的两臂对照，唯一输入差就是那一行）；② **普通构建也是 `0 个错误`**（两极化不许弄坏一边）；③ **编译文件集合逐位未变**（`-getItem:Compile` 前后 `cmp` 相同，且私有两趟的清单与普通构建逐位相同、`obj/` 条目归零）；④ 现场临时件**已复原到 lane 起点字节**并机器证明；五臂门禁 **`generation=#19 tree_gen=same`**。
**顺带推翻两条**：(a) W19A 报告里那个**命令行注入 `excl.props` 的绕过手法在本 SDK 上根本不生效**（`CustomAfterMicrosoftCommonProps` 的注入点被**工程体**里的赋值覆盖，§3.3）；(b) `D-R8` 登记条把它归因成"缺 `EnableDefaultCompileItems=false`"——**归因偏了**：真正的机制是 `DefaultItemExcludes` **按生效的 `$(IntermediateOutputPath)` 表达**，与那条属性无关（§3.4）。

---

## 2. 复现（改任何文件之前）

### 2.1 私有 obj 重定向 ⇒ `16×CS0579`

```bash
export PATH="$HOME/.dotnet:$PATH"
S=$HOME/wfp-runs/w20-laneW20B
dotnet build -m:1 build/MilBridge/tests/TextLineProto/TextLineProto.csproj \
  -p:BaseOutputPath=$S/repro/bin/ -p:BaseIntermediateOutputPath=$S/repro/obj/
```
```
RC=1
error CS0579 行数 = 32        ← 两趟（Debug / Release）各 16
error CS 总行数  = 32        ← 全是 CS0579，无其它错误码
    0 个警告
    16 个错误               ← 单趟摘要（Debug）
已用时间 00:00:05.17
```
逐字错误样例（**注意报错文件是仓内那份，不是重定向后的那份**）：
```
…/build/MilBridge/tests/TextLineProto/obj/Release/TextLineProto.AssemblyInfo.cs(13,12): error CS0579: “System.Reflection.AssemblyCompanyAttribute”特性重复 [ …/TextLineProto.csproj]
…/build/MilBridge/tests/TextLineProto/obj/Debug/TextLineProto.AssemblyInfo.cs(19,12): error CS0579: “System.Reflection.AssemblyVersionAttribute”特性重复 [ …/TextLineProto.csproj]
```
**与 W19A 的读数逐条吻合**：它记的是 `16×CS0579`（单趟）/ `32×CS0579`（换修前 shim）⇒ 我这两趟数**同码同数**。`rc=1` 是**真实构建失败**，不是 `127`（没跑）也不是 `MSB1009`（路径错）。

### 2.2 普通（不重定向）构建是干净的

```bash
dotnet build -m:1 build/MilBridge/tests/TextLineProto/TextLineProto.csproj
```
```
RC=0    0 个错误    52 个警告（全是既有 CS0436 类型冲突噪声）    已用时间 00:00:03.39
```
⇒ 所以这不是"工程坏了"，是**只有私有 obj 手法才踩到**的陷阱（与预登记 §2 的影响面判断一致）。

### 2.3 根因证据（不是"读起来像"）：`DefaultItemExcludes` 的实际取值

```bash
dotnet msbuild …/TextLineProto.csproj -p:BaseOutputPath=$S/repro/bin/ -p:BaseIntermediateOutputPath=$S/repro/obj/ -getProperty:DefaultItemExcludes
⇒ ";/home/…/w20-laneW20B/repro/bin/Debug//**;/home/…/repro/obj/Debug//**;/home/…/repro/bin//**;/home/…/repro/obj//**;**/*.user;…"

dotnet msbuild …/TextLineProto.csproj -getProperty:DefaultItemExcludes           # 普通
⇒ ";/home/…/tests/TextLineProto/bin/Debug//**;/home/…/tests/TextLineProto/obj/Debug//**;…/tests/TextLineProto/bin//**;/home/…/tests/TextLineProto/obj//**;**/*.user;…"
```
**决定性的一句**：重定向后，取值里**只剩仓外那两条路径**，**仓内 `obj/` 整条消失** ⇒ 默认 glob（`Microsoft.NET.Sdk.DefaultItems.props:36` 的 `Compile Include="**/*.cs" Exclude="$(DefaultItemExcludes);…"`）就把仓内陈旧件收了进来。SDK 侧源头（本机 SDK `10.0.111`）：

```xml
<!-- ~/.dotnet/sdk/10.0.111/Sdks/Microsoft.NET.Sdk/targets/Microsoft.NET.DefaultOutputPaths.targets -->
126:    <DefaultItemExcludes>$(DefaultItemExcludes);$(OutputPath)/**</DefaultItemExcludes>
127:    <DefaultItemExcludes>$(DefaultItemExcludes);$(IntermediateOutputPath)/**</DefaultItemExcludes>
133:    <DefaultItemExcludes>$(DefaultItemExcludes);bin/**;obj/**</DefaultItemExcludes>   ← 只在 UseArtifactsOutput 分支有"不依赖指向"的写法
```
该文件由 `Microsoft.NET.Sdk.BeforeCommon.targets:57` `<Import … Condition="'$(UsingNETSdkDefaults)' == 'true'"/>` 拉进 **props 阶段**（预处理件 `logs/pp.xml` 里它落在 `Microsoft.Common.props` 展开区、**默认 glob 之前**）⇒ 它算出来的"排除哪两条"就是 glob 看到的那两条。

### 2.4 被 glob 收进来的到底是哪几个件（`-getItem:Compile`）

```bash
dotnet msbuild …/TextLineProto.csproj -p:BaseOutputPath=$S/repro/bin/ -p:BaseIntermediateOutputPath=$S/repro/obj/ -getItem:Compile | grep…
```
| | 重定向构建（修前） | 普通构建（修前） |
|---|---|---|
| `obj/` 相关条目 | **6 项**（见下） | **0 项** |
| 其中仓内陈旧件 | `obj/Debug/TextLineProto.AssemblyInfo.cs`、`obj/Release/TextLineProto.AssemblyInfo.cs`、`obj/{Debug,Release}/.NETCoreApp,Version=v10.0.AssemblyAttributes.cs` | — |
| `Program.cs` | 2 项（**入口没被剔**） | 2 项 |
| `build/shims/PresentationCore.HbTextLine.cs` | 在 | 在 |

**`CS0579` 的报错文件与 glob 收进的陈旧件逐一对应**（§2.1 的两条逐字错误就是其中两项）⇒ **根因不是假说，是现场**。

### 2.5 复现阶段现场指纹

| 件 | sha16 | 大小 | mtime |
|---|---|---|---|
| `pc`（`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`） | `f4a454c8fe69cdfe` | — | 门禁自报 `树·PC` |
| shim（`build/shims/PresentationCore.HbTextLine.cs`） | `fe1b7ed8fa3ed231` | 278692 | 2026-09-16 15:30:15 |
| `TextLineProto.csproj`（改前） | `7819ace799b735fd` | 2524 | 2026-09-10 20:01:25 |
| `HbTextLineParity.csproj`（改前） | `d45ed6e2621f89b8` | 3370 | 2026-09-11 16:33:57 |

---

## 3. 修法

### 3.1 落点：**每个 csproj 各一行**（不用共享 `.props`）——理由

预登记 §2 给了两个落点（每个 csproj / 一个共享 `.props`），我选**逐工程**：

1. **本件登记的正是这两个工程**；影响面"不限这两个"是**残余**，不是本件的射程。修 13 个未派单工程属于**射程外加宽**（预登记 §3「射程外逐位不动」）。
2. **并发安全**：`build/MilBridge/tests/` 下此刻有别的车道在动（我实测到 `PcLineOracle` 正在被跑：`dotnet PresentationCore.Tests.dll --pc-lines-oracle …`，`bin/Release` mtime 16:18:01）。在 `tests/` 放一个**对所有工程生效**的 `Directory.Build.props`，等于替并行车道的工程也改了构建求值 ⇒ 归因会被污染。**逐工程改是我能独占、能逐位证明的那一格**。
3. **可证明性**：一行、一个属性、一个落点，两极化对照的**唯一输入差**可以是这一行（§6.1 的 A/B 两臂就是这么做的）。

⚠️ **`D-R8` 登记的"影响面不限这两个工程"是成立的，我逐工程核过数**（§9.2）：`build/MilBridge/tests/*/*.csproj` 共 19 个，其中 13 个走默认 glob；这 13 个里 **7 个今天仍暴露**（仓内已有陈旧 `obj/*AssemblyInfo*.cs`，私有 obj 一用就中招），另有 4 个形态相同、只是今天还没有陈旧件。**建议下一波用共享 `.props` 一次收口**，理由与风险都写在 §9.2。

### 3.2 改动（两个文件、各一行）

```diff
--- a/build/MilBridge/tests/TextLineProto/TextLineProto.csproj
+++ b/build/MilBridge/tests/TextLineProto/TextLineProto.csproj
@@ -18,6 +18,14 @@
     <BaseIntermediateOutputPath>$(MSBuildThisFileDirectory)obj\</BaseIntermediateOutputPath>
+    <!-- ⭐ 纪律 33 的陷阱（`D-R8`）：SDK 只按 `$(OutputPath)`/`$(IntermediateOutputPath)` 这两个
+         **当前生效值**排除产物目录（`Microsoft.NET.DefaultOutputPaths.targets:126-127`）；
+         `-p:BaseOutputPath=…/-p:BaseIntermediateOutputPath=…` 一旦指到**仓外**，
+         **本工程目录下**的 `obj/` 就**不再**被排除 ⇒ 默认 glob 会把里面**陈旧**的
+         `*.AssemblyInfo.cs` 收进编译 ⇒ 与 SDK 新生成的那份撞成 `CS0579`（实测 `16×CS0579`）。
+         这里补一条**不依赖 `BaseIntermediateOutputPath` 指向哪里**的排除（与 SDK 自己在
+         `UseArtifactsOutput` 分支 `:133` 的写法同形）。 -->
+    <DefaultItemExcludes>$(DefaultItemExcludes);obj/**;bin/**</DefaultItemExcludes>
   </PropertyGroup>
```
`HbTextLineParity.csproj` 同一行、同一位置（其 `BaseIntermediateOutputPath` 在 `:26`）。**为什么写成 `obj/**;bin/**` 而不是 `$(MSBuildThisFileDirectory)obj/**`**：本工程用的是"相对工程目录"的 `BaseOutputPath/BaseIntermediateOutputPath`，glob 的相对根就是工程目录，短式与 SDK 自身写法（`:133`）同形、且**不写死绝对路径**（写死会在工程被复制/移动后静默失效）。**不改** `EnableDefaultCompileItems`（次选修法风险更大，且 W19A 实测它会连 `Program.cs` 一起剔掉 ⇒ `CS5001`）。

### 3.3 前后 sha16 + 大小 + mtime（含备份）

| 文件 | before sha16 / 字节 / mtime | after sha16 / 字节 / mtime | 备份（`$HOME/wfp-runs/w20-laneW20B/backup/`） |
|---|---|---|---|
| `tests/TextLineProto/TextLineProto.csproj` | `7819ace799b735fd` / 2524 / 2026-09-10 20:01:25.005013581 | **`60abebef17522b8c`** / **3321** / 2026-09-16 16:16:14.944847420 | `TextLineProto.csproj.before` = `7819ace799b735fd` |
| `tests/HbTextLineParity/HbTextLineParity.csproj` | `d45ed6e2621f89b8` / 3370 / 2026-09-11 16:33:57.181164016 | **`9817ae51e9b1322d`** / **4167** / 2026-09-16 16:16:17.244845851 | `HbTextLineParity.csproj.before` = `d45ed6e2621f89b8` |
| `tests/Directory.Build.targets`（**只备份、未改**） | `1324fcde93604349` / 1735 | 同（未改） | `Directory.Build.targets.before` = `1324fcde93604349` |

两文件 `xml.dom.minidom.parse` 均 OK（XML 良构）。

### 3.4 我推翻的两条（带反证）

**(a) W19A §4.2 的"绕过手法"不生效。** 它写：
> `dotnet msbuild … -p:CustomAfterMicrosoftCommonProps=$S/excl.props … -getItem:Compile | grep -c AssemblyInfo ⇒ 0` / `… grep -c "Program.cs" ⇒ 2`

我照抄（用**它自己的** `$HOME/wfp-runs/w19-laneW19A/excl.props` 原文，并把 `obj\**` 换成在 Linux 上真正匹配的 `obj/**`）实测：
```
-dotnet msbuild … -p:CustomAfterMicrosoftCommonProps=…/neutralize.props -getProperty:DefaultItemExcludes
⇒ ";**/*.user;**/*.*proj;**/*.sln;**/*.slnx;**/*.vssscc;**/.DS_Store;obj/**;bin/**;/home/…/after/bin/Debug//**;…"
                                                                        ↑ 我注入的值在第 4 位、**后面又被工程体追加了一份**
```
机制：注入点 `Microsoft.Common.props:113`（`<Import Project="$(CustomAfterMicrosoftCommonProps)" Condition="… Exists(…)"/>`）**在工程体之前**，而**工程体自己**的 `<DefaultItemExcludes>`（在这两个 csproj 里就是**我这次加的那一行所在的位置**）**在后面追加** ⇒ **注入会被工程体覆盖/合并，但注入本身不落空**。**注意这条是"注入方式无效"的结论，不是"注入被忽略"**——我第一次的 `neutralize.props` 之所以完全没生效，是因为它的 XML 注释里写了 `<`/`>`（**注释导致 XML 解析失败 ⇒ `Exists()` 真但导入报错被吞**），这是我自己的仪器缺陷，已在 §10 记档。
**要推翻的只有一句话**：W19A 用它当"绕过生效"的证明时，**该属性在本 SDK 上控制不到 glob**（我用它做反向反极性时实测 `0 error`，见 §6.1 说明）⇒ 那句 `grep -c AssemblyInfo ⇒ 0` **不能作为"注入生效"的证据**（真正的解释是：**它当时读的默认 glob 本来就没把仓内 `obj/` 收进来**——即它的读数与"注入无效"完全一致）。**(b) `D-R8` 登记条把根因归成"缺 `EnableDefaultCompileItems=false`"是偏的。** 反证：`CoverageProbe`（`EnableDefaultCompileItems=false`，`CoverageProbe.csproj:33`）**没有** `DefaultItemExcludes`，实测 `-getProperty:DefaultItemExcludes` 同样是"只有仓外两条"⇒ **它的干净不是靠那条属性，而是靠"不用 glob"**；反过来，`HbTextLineParity` **加了**我这一行之后**仍然是默认 glob**（`EnableDefaultCompileItems` 未设、仍为 `true`）却也干净了 ⇒ **决定因素是 `DefaultItemExcludes`，不是 `EnableDefaultCompileItems`**。登记条"候选判据"里的建议（补 `EnableDefaultCompileItems=false`）**方向不对**（预登记 §2 也已把它列为**风险更高的次选**）。

---

## 4. 「编译文件集合未变」的机器证明

方法：`-getItem:Compile` 取**生效** `Compile` 项的全路径清单，**前后 × 两工程 × {Debug,Release} × {普通, 私有重定向} = 16 份**，逐份 `cmp`。清单文件在 `$HOME/wfp-runs/w20-laneW20B/logs/items-{before,after}-*.txt`。

```
=== PROOF: after-priv is identical to after-plain (the correct set) ===
IDENTICAL  TextLineProto Debug / Release  (plain == priv)
IDENTICAL  HbTextLineParity Debug / Release  (plain == priv)

=== PROOF: after == before plain (no file lost/added) ===
IDENTICAL  TextLineProto Debug plain-before == plain-after
IDENTICAL  TextLineProto Release plain-before == plain-after
IDENTICAL  HbTextLineParity Debug plain-before == plain-after
IDENTICAL  HbTextLineParity Release plain-before == plain-after

=== residual obj/bin entries anywhere after fix === 0（8 份清单全 0）
```
修前的对照（这正是缺陷本身）：
```
$ diff items-before-HbTextLineParity-Debug-plain.txt items-before-HbTextLineParity-Debug-priv.txt
1a2,5
> …/tests/HbTextLineParity/obj/Debug/.NETCoreApp,Version=v10.0.AssemblyAttributes.cs
> …/tests/HbTextLineParity/obj/Debug/HbTextLineParity.AssemblyInfo.cs
> …/tests/HbTextLineParity/obj/Release/.NETCoreApp,Version=v10.0.AssemblyAttributes.cs
> …/tests/HbTextLineParity/obj/Release/HbTextLineParity.AssemblyInfo.cs
```
即：**修前私有两趟 = 正确集合 + 4 个陈旧件；修后 = 正确集合**，而**正确集合本身逐位未动**（每个工程只剩**入口 `Program.cs` + 真 shim 源 `build/shims/PresentationCore.HbTextLine.cs`** 两项）。

**第二重、与"文件集合"无关的旁证**：普通构建与私有构建的产物**同大小**（`MilBridge.TextLineProto.dll` 两趟均 **93184 B**，与 W19A 记的 93184 B 相同），`strings -a` 归一化后**元数据差 6 行**、**全部可归因**：唯一的 PDB 路径行（`<PRIV>/final/obj/Debug/…pdb` vs `<REPO>/…/obj/Debug/…pdb`）+ 一行编译器随机填充。

### 4.1 残余（登记，不在本件射程）

见 §9.2 的表：**7 个仍暴露**（`BboxProbe`／`CompositeFontProbe`／`ContractProbe`／`FamilyCoverageSelfTest`／`IcuBreakParity`／`LsProbe`／`T2eLineHeight`，均已存在陈旧 `obj/*AssemblyInfo*.cs`），另有 4 个形态相同、今天还没有陈旧件。**`PcLineOracle`／`StrictTierProbe` 因为设了 `EnableDefaultCompileItems=false` 反而与本缺陷无关**——我第一遍把它们误列进暴露组，是按 `-getItem` 的机制交叉表更正过来的（**更正，不是原始读数**）。

---

## 5. 四条判据（预登记 §2 的 ①②③ + 派单的 ④）

### ① 私有 obj 重定向 + 仓内陈旧 `AssemblyInfo` ⇒ 修前 `CS0579` / 修后 `0 error`

**两臂对照，唯一输入差 = 那一行**（同一棵树、同一 `Program.cs`、同一 shim、同一 `-c Debug`、同一 `-m:1`、同一个**故意陈旧**的仓内文件在场）：
```
A 臂（pre-fix csproj 的 scratch 副本，sha16 = 7819ace799b735fd，cmp 与 .before 逐字节相同）
  dotnet build -m:1 -c Debug …/_W20B-prefix-control.csproj \
    -p:BaseOutputPath=$S/polA/bin/ -p:BaseIntermediateOutputPath=$S/polA/obj/
  ⇒ RC=1   CS0579=32（两趟）  16 个错误
  逐字：…/tests/TextLineProto/obj/Release/.NETCoreApp,Version=v10.0.AssemblyAttributes.cs(4,12): error CS0579: “global::System.Runtime.Versioning.TargetFrameworkAttribute”特性重复 […]

B 臂（修后 csproj，就是仓内那个文件）
  同一命令、只换 csproj 名
  ⇒ RC=0   已成功生成。   0 个错误   （CS0579=0）
```
`diff .before/TextLineProto.csproj ↔ 现 TextLineProto.csproj` **恰为 §3.2 的那一行（+8 行注释）**。
**在同一棵树、同一个陈旧文件在场时，B 臂的私有构建里 `obj/` 条目 = 0**（§4）；**陈旧文件本身没有被删**（planted sha16 `897eddca6990c333` / 924 B，构建前后都在）。

**`HbTextLineParity` 侧**（它 `obj/Debug|Release` 各有一份**原有**陈旧 `AssemblyInfo`，全程在场、未被我替换）：
```
dotnet build -m:1 -c Debug …/HbTextLineParity.csproj -p:BaseOutputPath=$S/final-htp/bin/ -p:BaseIntermediateOutputPath=$S/final-htp/obj/
⇒ RC=0   0 个错误   （CS0579=0）
```

### ② 普通（不重定向）构建也必须 `0 error`

```
dotnet build -m:1 -c Debug build/MilBridge/tests/TextLineProto/TextLineProto.csproj
  ⇒ RC=0   0 个错误   52 个警告（既有 CS0436 噪声）
dotnet build -m:1 -c Debug build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj
  ⇒ RC=0   0 个错误
```
**陈旧文件在场时**的普通构建也是 `0 error`（`logs/plain-tlp-planted.txt` / `logs/plain-htp-planted.txt`）⇒ 修私有没弄坏普通。

### ③ 真实构建（纪律 33：`--check` 不算）

上面每一条都是 `dotnet build` 的**完整构建**（有 `已用时间` / `已成功生成` / 产物落盘），**没有任何一条用 `--check`**。产物证据：`$S/final/bin/Debug/MilBridge.TextLineProto.dll` = 93184 B、`$S/final-htp/bin/Debug/MilBridge.HbTextLineParity.dll` = 159232 B（与 W19A 记的 159232 B 相同）。

### ④ 临时件全部复原并证明（`cmp` + sha16）

| 临时件 | 处置 | 证明 |
|---|---|---|
| `tests/TextLineProto/obj/Debug/TextLineProto.AssemblyInfo.cs`（被**故意替换**） | 复原 | **`cmp` 与 lane 起点清单逐字节相同**；sha16 `98dfd352e51ee5ca` / **973 B** == 起点值 |
| `tests/TextLineProto/obj/Release/*AssemblyInfo.cs`、`tests/HbTextLineParity/obj/{Debug,Release}/*AssemblyInfo.cs` | **从未动过** | 四件清单 `cmp` 前后 identical（`logs/obj-assemblyinfo.{before,restored,final}.txt`） |
| `tests/TextLineProto/_W20B-prefix-control.csproj`（scratch 控制臂） | **已删** | `ls` ⇒ `没有那个文件或目录`；且它**从不在任何 `-getItem` 清单里**（普通清单全程 2 项） |
| 构建输出里的 `STALE-W20B-PLANT` 残留（`.dll`/`refint`） | 就地重建消掉 | `strings -a bin/Debug/MilBridge.TextLineProto.dll \| grep -c STALE-W20B-PLANT` ⇒ **0**；全工程 `grep -rl` ⇒ **空** |
| 任何 `.cs` 源里的残留 | 无 | `grep -rl --include=*.cs STALE-W20B-PLANT build/MilBridge/tests/` ⇒ **空** |

**⚠️ 我自己的纪律 16 违规（如实记）**：替换那个 `AssemblyInfo.cs` 之前，我**只记了它的 sha+字节，没有先 `cp -p` 备份**（派单要求"备份 before 编辑"。它不在我的写域里，但我为了判据①必须替换它）。**复原办法**是拿**同工程未被触碰的 `obj/Release/` 同名件**做模板（SDK 生成物、非时间戳字段），只把 `AssemblyConfigurationAttribute("Release")` 换成 `("Debug")` ⇒ **973 B / `98dfd352e51ee5ca`，与起点值逐字节相同**（不是"我猜它长这样"，是**sha16 对上起点记录**）。**若这一步对不上，我会把它报成"未复原"**——它对上了。

### ⑤ 五臂世代门禁（派单第 5 条）

```bash
bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs --outdir $HOME/wfp-runs/w20-laneW20B/gate
```
逐字（两趟都跑、两趟同句，第二趟在"复原完成 + 两工程各重建一次"之后）：
```
TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#19 tree_gen=same saved_shim=fe1b7ed8fa3ed231 gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2 outdir=/home/links-dev/wfp-runs/w20-laneW20B/gate2
GATE_REASON=all-as-registered     GATE_RC=0
```
**`tree_gen=same`** ⇒ 世代绑定的三项（`run.sh` `3e513e88a4fa4ec9` / `HbTextLineParity/Program.cs` `2e458928fc1577c2` / shim `fe1b7ed8fa3ed231`）**未动**，我改的 csproj **不在世代绑定内**（`tline-gate.sh:135-136` 只绑 `SH_RUN`/`SH_PARITY`）⇒ 与 `#20` 预登记 §0「不动世代绑定」的预期一致，**不需要重取五臂、不需要重钉登记表**。

---

## 6. 射程外完整性

| 禁改件 | sha16 | 状态 |
|---|---|---|
| `tests/HbTextLineParity/Program.cs`（世代绑定） | `2e458928fc1577c2` / 128190 / 2026-09-15 10:24:06 | **未动** |
| `build/MilBridge/run.sh`（世代绑定） | `3e513e88a4fa4ec9` / 16450 / 2026-09-15 16:53:13 | **未动** |
| `build/shims/PresentationCore.HbTextLine.cs`（世代绑定） | `fe1b7ed8fa3ed231` / 278692 / 2026-09-16 15:30:15 | **未动** |
| `build/MilBridge/known-red.json` | `3bf26e12f320dece` / 29546 / 2026-09-16 15:46:02 | **未动** |
| `build/MilBridge/tools/tline-gate.sh` | `b37a5c9f55ae71a4` / 40181 / 2026-09-15 16:44:01 | **未动** |
| `tests/PcLineOracle/**`（另一车道） | — | **未动**（`find -newermt` 只报它自己 `bin/Release` 16:18:01，源于**另一个车道正在跑**的 `dotnet …--pc-lines-oracle` 进程，PID 167514、16:18:04 起） |
| `docs/**` `samples/**` `tests/**` `verify-all.sh` `build/*.Linux/**` | — | **未动** |

**并发交底**：本趟期间另一车道在跑 `PcLineOracle`（`--leg b --tier lenient --known-red $HOME/wfp-runs/w17-laneW17B/…`）。我**没有**跑 `verify-all.sh`、**没有**重建任何 `build/*.Linux/**`；我的构建全部落 `$HOME/wfp-runs/w20-laneW20B/`（例外：判据②的两趟**普通**构建按定义写仓内 `tests/**/bin|obj`，那是判据要求的，且两工程 `bin/Debug` 里的产物已重建为正确身份）。

---

## 7. 修后预期（供别人复算）

同一条命令，修后必须复现：
1. **判据①**：私有 obj 重定向 + 仓内**任意**陈旧 `obj/**/*.AssemblyInfo.cs` ⇒ **`0 error`、`CS0579=0`**；且 `-getItem:Compile` 里 `obj/` 条目 **= 0**、`Program.cs` 与 `build/shims/PresentationCore.HbTextLine.cs` **各 1 项**。
2. **判据②**：普通构建 ⇒ `0 error`。
3. **判据④**：仓内 `obj/**/*AssemblyInfo*.cs` 四件 sha16 必须仍是 `98dfd352e51ee5ca` / `0eec45782bc70dec` / `f0f41453e973f406` / `790d3702fc64a096`（**谁再替换它做实验，必须留下 before 备份**——我这趟的教训）。
4. **门禁**：`TLINE_GATE=PASS … generation=#19 tree_gen=same …`。

**红向反例（改坏了会长什么样）**：若谁把 `obj/**;bin/**` 写成 `$(MSBuildThisFileDirectory)obj/**` 之外的形态而**只覆盖 `obj` 不覆盖 `bin`**，或误改成 `EnableDefaultCompileItems=false` 而漏列 `Program.cs` ⇒ 症状是 **`CS5001`（找不到入口点）**（W19A 实测过），而**不是** `CS0579`。

---

## 8. 读数表（纪律 32）

| # | 时刻（+08:00） | `loadavg` | `mem_available` | `lane` | `kernel` | `pc` sha16 | 备注 |
|---|---|---|---|---|---|---|---|
| 1 | 2026-09-16 16:14:30 | 0.47 0.23 0.60 | 3729 MiB | W20B | 6.8.0-138-generic | `f4a454c8fe69cdfe`（门禁自报） | 复现 `32×CS0579`（rc=1） |
| 2 | 2026-09-16 16:18:31 | 1.27 0.81 0.75 | 3201 MiB | W20B | 6.8.0-138-generic | 同上 | 判据①②收尾 + 门禁第 1 趟 |
| 3 | 2026-09-16 16:19:17 | 1.85 1.02 0.83 | 3067 MiB | W20B | 6.8.0-138-generic | 同上（`树·PC` 逐趟自报，两趟相同） | 复原完成 + 门禁第 2 趟 |

| 仪器/件 | sha16 | 大小 | mtime |
|---|---|---|---|
| 我的两趟日志（`$S/logs/`） | 见 §5 逐条命令与其截图式输出 | — | 16:14–16:19 |
| `TextLineProto.csproj`（改后） | `60abebef17522b8c` | 3321 | 2026-09-16 16:16:14.944847420 |
| `HbTextLineParity.csproj`（改后） | `9817ae51e9b1322d` | 4167 | 2026-09-16 16:16:17.244845851 |
| 私有产物 `MilBridge.TextLineProto.dll` | `6315b90bc09fdfa4` | 93184 | `$S/final/bin/Debug/` |
| 普通产物 `MilBridge.TextLineProto.dll` | — | 93184 | 仓内 `tests/TextLineProto/bin/Debug/` |
| 门禁输出目录 | `$HOME/wfp-runs/w20-laneW20B/gate`、`gate2` | — | 16:18 / 16:19 |

---

## 9. 未能建立 / 残余

### 9.1 未能建立（**not measurable / not established**）

1. **`$(DefaultItemExcludes)` 那条 SDK 规则相对"工程体"的精确求值位次**：我原以为它在工程体**之后**（预处理件里它落在 `Microsoft.Common.props` 展开区，而工程体 marker 在同文件的更高行号处），但现场**不支持**这个推断——加了那一行之后，**最终属性值里我的串出现在 SDK 那两条之前**，说明 SDK 的追加发生在更早的位置。**我没有把位次钉死**（`-getItem` 是独立求值趟、`-preprocess` 与 `-p:` 的交互我也没有穷尽）。**本件的因果链不依赖它**：靠的是 §2.4 的"glob 实际收进了哪几个件" + §5① 的 A/B 两臂（唯一输入差 = 那一行）。**记 here 是为了不让读者把"看起来在之后"当成"已证明在之后"**。
2. **"反向反极性"的注入法未能成功**：我试过 `-p:CustomAfterMicrosoftCommonProps=…` 把**只是我这一条**中和掉（属性值构造了至少三种形态），因 §3.4(a) 的追加顺序，**注入的值压不住工程体** ⇒ 该法**不成立**；我改用"**pre-fix csproj 的 scratch 副本**"做同名同参数对照（§5① 的 A 臂），这是**更强的对照**（连注释与行号都回到修前）。**W19A 记的那个 `excl.props` 手法，我测不到它控制到的证据**（§3.4a）。
3. **`bin/**` 那一半的独立两极化**：今天两个工程的仓内陈旧 `bin/` 里没有 `.cs`，默认 glob 也从不收 `.dll` ⇒ **`bin/**` 是防御性的一半，没有独立的红证**（不是"证明了不需要"，是"今天没法用读数把它和非 `bin` 形态分开"）。

### 9.2 残余（登记，交下一波）

机制交叉表（`tests/*/*.csproj` 共 19 个；`EDCI`=`EnableDefaultCompileItems` 有/无，`DIE`=`DefaultItemExcludes` 有/无，`stale`=仓内 `obj/**/*AssemblyInfo*.cs` 数）：

| 组 | 工程数 | 工程 |
|---|---|---|
| **本件已修**（`DIE` 有） | 2 | `TextLineProto`、`HbTextLineParity` |
| **仍暴露**（`EDCI` 无 = 走默认 glob，且仓内已有陈旧件） | **7** | `BboxProbe`(1)／`CompositeFontProbe`(1)／`ContractProbe`(1)／`FamilyCoverageSelfTest`(1)／`IcuBreakParity`(1)／`LsProbe`(1)／`T2eLineHeight`(1) |
| 形态暴露但今天没有陈旧件（今天不会红，一有陈旧件就会） | 4 | `ClosedLoop`、`HbSpike`、`ResolverGuardProbe`、`T2Repro`（各 0） |
| **不暴露**（`EDCI` 有 ⇒ 不用默认 glob ⇒ 与本缺陷无关，**含那些有陈旧件的**） | 6 | `CoverageProbe`(2)／`DirectBranchCheck`(1)／`InputTraceProbe`(1)／`MinMaxProbe`(1)／**`PcLineOracle`(1)**／**`StrictTierProbe`(1)** |

**给下一波的建议（不是本件结论）**：用 `build/MilBridge/tests/Directory.Build.props` 一次收口（`<DefaultItemExcludes>$(DefaultItemExcludes);obj/**;bin/**</DefaultItemExcludes>`），落点选它而不是逐工程的理由是"7 个已暴露 + 4 个同形态 + 将来新建的工程都覆盖"；**代价**是它会**改变 `tests/` 下所有工程的构建求值**（含世代绑定的 `HbTextLineParity`，虽然它不在指纹里）⇒ **必须在一个没有并行车道的趟里做**，并用本件的 §4 方法（16 份清单 `cmp`）逐工程证明"编译文件集合未变"。**注意**：`PcLineOracle` 之所以今天没中招，是因为它自己设了 `EnableDefaultCompileItems=false`（显式 `Compile` 清单）——**这是一个"碰巧"的保护，不是被看着的**（纪律 37④）：谁给它加一句默认 glob 或删掉那条属性，它就会立刻中招。

### 9.3 本人仪器缺陷（自记，纪律 37 同族）

1. **`neutralize.props` 的 XML 注释里写了 `<`/`>`** ⇒ 解析失败、导入被吞，而 `Exists()` 为真 ⇒ **我第一轮"反极性"读数（`RC=0`）是无效读数**，我差点把它当成"W20B 那条规则不必要"的证据。**判据**：注入式实验**必须先读回属性值证明注入生效**（我现在每次都读）。
2. **没先 `cp -p` 就替换了 `obj/Debug/TextLineProto.AssemblyInfo.cs`**（§5④ 已复原并证明）。
3. **第一次"pre-fix 控制臂"的对照不干净**：`Configuration=Release` 的构建配 `Debug` 的清单（`-c` 未传时默认 Release）。已用**显式 `-c Debug`**的两臂重做（§5①）。

---

## 10. 复现命令（一条条抄就能重算）

```bash
export PATH="$HOME/.dotnet:$PATH"; cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
S=$HOME/wfp-runs/w20-laneW20B; mkdir -p $S/logs

# 修前复现（把 csproj 换回 $S/backup/*.before 的副本即可）
dotnet build -m:1 -c Debug build/MilBridge/tests/TextLineProto/TextLineProto.csproj \
  -p:BaseOutputPath=$S/polA/bin/ -p:BaseIntermediateOutputPath=$S/polA/obj/     # ⇒ 16 个错误 / CS0579

# 根因
dotnet msbuild build/MilBridge/tests/TextLineProto/TextLineProto.csproj \
  -p:BaseOutputPath=$S/polB/bin/ -p:BaseIntermediateOutputPath=$S/polB/obj/ \
  -getProperty:DefaultItemExcludes -getItem:Compile                          # ⇒ 仓内 obj/ 出现在清单里

# 修后两极化
dotnet build -m:1 -c Debug build/MilBridge/tests/TextLineProto/TextLineProto.csproj \
  -p:BaseOutputPath=$S/polB/bin/ -p:BaseIntermediateOutputPath=$S/polB/obj/     # ⇒ 0 个错误
dotnet build -m:1 -c Debug build/MilBridge/tests/TextLineProto/TextLineProto.csproj   # ⇒ 0 个错误（普通）

# 门禁
bash build/MilBridge/tools/tline-gate.sh --logdir build/MilBridge/arm-logs --outdir $S/gate
```
