# `#39` 预登记（**写在任何改动之前**）

> 时序：本件在改动之前落盘（`#37` 立了牙：`verify-all` 第 `[11]` 步的 `prereg=` 判据要求**本代**出现在某个
> `docs/WAVE*-PREREGISTRATION.md` 的标题行里）。基线 = `#38`（`1818921b5d0d33c7`，见 `docs/CURRENT-STATE.md` 机器行）。

---

## 1. 目标与动机

**目标**：把**权威件从 Debug 切到 Release**（`#37`/`#38` 记的待办 ③）。

**动机是一个真实、可复现的用例**（`D-G47`）：
真实第三方应用（仓外 HandyControl demo）用**当前的 Debug 权威件**跑，会被一句断言直接终止：

```
Process terminated.
Assertion Failed
DependencyProperties can only be set on DependencyObjects
   at MS.Internal.Helper.CheckCanReceiveMarkupExtension(...)
   … at System.Windows.TemplateContent.ParseXaml()
```

**该断言的出处已定位**：`upstream/.../PresentationFramework/MS/Internal/Helper.cs:591`
`Debug.Assert(targetDependencyObject != null, "DependencyProperties can only be set on DependencyObjects");`
—— 而 `Debug.Assert` 带 **`[Conditional("DEBUG")]`** ⇒ **Release 构建会把它整个编译掉**。
⇒ 切 Release **正是**这条缺陷的修法（并且是可证伪的：见 §3 的 S5/S6）。

## 2. 侦察读数（**已做**，都是零风险操作：只写 `bin/Release`，不碰已冻结的 Debug 位）

| 项 | 读数 |
|---|---|
| **Release 能不能编** | `System.Windows.Extensions.Linux`／`System.Xaml.Linux`／`WindowsBase.Linux`／`PresentationCore.Linux`／`PresentationFramework.Linux` **逐个 `-c Release` 全部 0 错** ⇒ 链本身可编，**这不是"改不回来"的问题** |
| **要改多少处** | `bin/Debug` 在 `build/`、`src/`、`tests/`、`verify-all.sh` 的 `*.sh`/`*.py` 里共 **198 处 / 20 个文件** |
| **关键点（权威件消费侧）** | `build/MilBridge/tools/frame-step.sh:72` 的 `AUTH_PC="$ROOT/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll"`；`tests/…/run-wpftextdemo.sh:315/511/528/537`（app-local 同步与 Provider）；`samples/*` 用 `$(WpfLinuxSelfBuiltConfiguration)`（默认 **Debug**） |
| **产物差异** | 同一份源：Release PF **6,119,424 B** vs Debug **7,122,432 B**（差 ≈ 1 MB 的断言/调试面） |
| ⚠️ **切 Release 治不了什么** | 我们移植里的 **`Invariant.Assert` 在 Release 下仍然 `Environment.FailFast`**（`build/WindowsBase.Linux/Invariant.Linux.cs:217`；同文件 `:203` 的 [补丁 N] 注释就是为"`Debug.Fail` 在 Release 被编译掉、原文会丢"而加的）⇒ **Release 只治 `Debug.Assert` 一族**，`Invariant.Assert` 的致命性**留给单独裁定**（见 §5 边界） |

## 3. 判据（写死；读数之后再改就算事故）

| 编号 | 判据 | 通过条件 |
|---|---|---|
| **S1** | Release 全链可编 | 九个位工程 + 4 个样本 `-c Release` **全 0 error**（含 `bridge` 的 AOT 发布） |
| **S2** | **配置只许有一处声明** | 权威件配置由**一个**变量/常量决定（今天：脚本里 198 处字面量 + 样本 `$(WpfLinuxSelfBuiltConfiguration)`）；改完**不许**再出现"某个脚本自己写死 Debug" |
| **S3** | 权威件真的是 Release | `frame-step.sh` 的 `AUTH_PC` 指向 Release pc；`file`/尺寸与 §2 的 Release 读数一致；`verify-all` 自报里能看到配置 |
| **S4** | 既有验收不回退 | `verify-all` **25 步全绿**；应用门禁两档 × 3 rep **6/6 `result=PASS`**；窗口内色数 **≥ Debug 档**（`default ≥ 3960`、`env ≥ 2828`）；`THIRDPARTY=PASS`（第三方形态步） |
| **S5** | **`D-G47` 的用例越过那句断言**（本波的核心产品判据） | 用**Release 自产件**重建 HandyControl 库 + demo（仓外）并运行 ⇒ **不再**出现 `Assertion Failed: DependencyProperties can only be set on DependencyObjects`；无论随后撞上什么（另一条断言/真缺陷）**如实记录** |
| **S6** | **S5 的反极性** | 同一套代码、用**Debug 自产件**跑 ⇒ **必须**复现该断言（`rc=134`）⇒ 证明 S5 不是"碰巧" |

⚠️ **S5 与既有 `verify-all` 的关系**：HandyControl 在**仓外**，所以 S5 是**产品证据**、**不是仓内判据**。
仓内判据仍然只有 `verify-all` 的 25 步（S4）。**不许**把 S5 写成"仓内绿"。

## 4. 分阶段计划（每阶段都要能独立判定成败）

1. **阶段 1（声明单一化）**：找出"权威件配置"的**唯一来源**（建议放 `build/Directory.Upstream.props`：
   `WpfLinuxSelfBuiltConfiguration` 与脚本用的同名环境变量对齐），把脚本里的字面量改成从这一处取。
   **先只改这一处 + 少量关键点（`AUTH_PC`、app-local 同步、样本）**，不改无关工具。
2. **阶段 2（权威件切换）**：`integration-wave.sh` 以 Release 重建九个位；`publish-milbridge.sh`/AOT 走 Release；
   `shell`/`python` 工具读同一个声明。
3. **阶段 3（消费侧清扫）**：198 处逐处判定"该跟声明走"还是"本来就该 Debug"（**不许 `sed` 全替**）；
   测试工程（`tests/**`）的 HintPath 同趟。
4. **阶段 4（收尾）**：应用门禁 ×2 → `verify-all`（静默窗口）→ 冻结 `#39` → 冻后 `verify-all` ×2；
   并用 S5/S6 在**仓外**取一组产品读数写进记录。

## 5. 边界（明说，不许沉默扩权）

- **本波不改 `Invariant.Assert` 的致命性**（Release 下仍 `FailFast`）。若 S5 之后撞上的是 `Invariant.Assert`，
  **如实登记**并**另立一项**（改动它 = 改产品行为，要有自己的预登记与反极性）。
- **不许**为了换绿而放宽任何判据；**不许**把 S5 当仓内判据。
- **不碰** `upstream/wpf/**`；`GEN_KEYS` 三项（`instr_shim`/`instr_run_sh`/`instr_program_cs`）**不许**动
  ⇒ 五臂按纪律**不重取**（若 `check` 说必须重取，如实照做并记录）。
- 九位**预计全部位移**（配置变了）⇒ 冻结时 `allow_changed` 声明**九位**，并逐位如实记录。

## 6. 复现命令

```bash
# 侦察（已完成，可复算）
for p in System.Windows.Extensions.Linux System.Xaml.Linux WindowsBase.Linux PresentationCore.Linux PresentationFramework.Linux; do
  dotnet build build/$p/$p.csproj -c Release -m:1 --nologo -v q; echo "$p rc=$?"; done

# 要改多少处
grep -rn "bin/Debug" --include="*.sh" --include="*.py" build src tests verify-all.sh | wc -l

# 断言出处
grep -rn "DependencyProperties can only be set on DependencyObjects" upstream/wpf/src --include=*.cs

# 收尾（顺序见 docs/WAVE33-PREREGISTRATION.md §6）
WAVE_OWNER=$(whoami) bash build/integration-wave.sh
WPTD_RUN_DIR=$HOME/w39-gate-b WPTD_BASELINE_OUT=$HOME/w39-gate-rows.txt bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both --no-build
bash verify-all.sh
python3 $HOME/w21-verify/w27-freeze.py <verify-all-log> <gate-rows> '#39'
```

---

## 7. 阶段 1 结果（**已落地**；改值仍在阶段 2，尚未动）

**落了什么**（值**仍是 `Debug`** ⇒ 与 `#38` 冻结态**行为等价**，这正是阶段 1 的判据）：

| 件 | 内容 |
|---|---|
| `build/SelfBuiltConfig.props`（新） | **唯一声明处**：`<WpfLinuxSelfBuiltConfiguration>Debug</…>`（附"为什么必须有这一处"的实测依据） |
| `build/Directory.Upstream.props` ＋ 仓根 `BuildHygiene.props` | 两条 import 图**各 import 它一次**（`build/*.Linux/*.csproj` 与全部样本）⇒ MSBuild 侧只有一个来源 |
| `build/selfbuilt-config.sh`（新） | **唯一 shell 读取器**；`--check` 两颗牙：① 声明恰好 1 条且取值合法 ② **shell 值 == MSBuild 值**（在两条图各取一个代表工程上求值）；缺件/解析不出/求值失败 ⇒ **`NOINFO`（rc=2）** |
| 同上 `--debt` / `--debt-check` | 阶段 3 的**棘轮**：统计还写死 `bin/Debug` 的处数，**上限是脚本里的字面常量、只许减少**（与 `CAND_MIN` 同族：不做成可覆盖的环境变量） |
| 三处**关键消费点**接线 | `build/MilBridge/tools/frame-step.sh`（`AUTH_PC`）｜`tests/…/run-wpftextdemo.sh`（样本 bin ＋ 自产件一致性扫描 ＋ Provider）｜`build/close-wave.sh`（九位读数 10 处）—— 共 14 处改走声明 |

**读数**：

- `bash build/selfbuilt-config.sh --check` ⇒ `SELFCONFIG_DECL=PASS n=1`、`SELFCONFIG_MSBUILD_自产件图=PASS`、
  `SELFCONFIG_MSBUILD_样本图=PASS`、`SELFCONFIG_CHECK=PASS`。
- **反极性（同源证明）**：把声明那**一行**改成 `Release` ⇒ shell 与**两条** MSBuild 图**同时**读到 `Release`
  （三边一起动）；改回 `Debug` ⇒ 三边一起回。（这就是"只许有一处"的机器证。）
- 欠账：侦察时 **198** 处写死 `bin/Debug` ⇒ 接完关键消费点后 **186** 处；`--debt-check` 棘轮生效。

### ⚠️ 本阶段两次**自伤**（都已修，都值得记）

1. **变量名撞进判据的清理域**（门禁当场抓红）：第一版变量叫 **`WPF_LINUX_SELF_CONFIG`**，
   而**应用门禁的默认档就是"清空全部 `WPF_LINUX_*`/`HLWPF_*` 字体 env"** ⇒ 那一档里它被 `unset`
   ⇒ 应用路径塌成 `bin//net10.0` ⇒ 应用 **`exit=127`（command not found）**、`default` 档三 rep 全红
   （而 `env` 档照常 2828 色 ⇒ 症状是"只有主档死"）。改名 **`SELFBUILT_CONFIG`**（清理域之外）后两档恢复。
   ⇒ **纪律**：新增工具变量必须避开判据的清理域（同族先例：诊断变量用 `WPFGFX_ROOTDIAG` 而不是 `WPF_LINUX_*`）。
2. **棘轮被自己顶红**：`--debt` 的统计 grep **自己的模式串里也有 `bin/Debug`** ⇒ 把 186 顶成 192 ⇒
   `SELFCONFIG_DEBT_CHECK=FAIL live=192 > max=186`。修法 = 计数时**排除本文件**
   （同族教训：**"写下那句话的动作本身会改变证据"**）。

### 还没做（阶段 2/3，**本波未做**）

- **改值**（`Debug → Release`）：必须等阶段 2（`integration-wave.sh` 以 Release 重建九个位 ＋ bridge AOT）与
  阶段 3（186 处逐处判定，**不许 sed 全替**）同趟，否则会出现"权威件 Release、仪器读 Debug"的混合态 ——
  那正是本仓反复登记的那一族（**同一语义多处 ⇒ 必然分叉**）。
- 九个位在 Release 下的**五臂是否需重取**：按 `GEN_KEYS` 判定（本阶段未动 `GEN_KEYS`）。

---

## 8. 阶段 2/3 **准备完成**（接线全绿；**值仍未翻**，翻值前留档）

⚠️ 本节写于**翻值之前**。此时唯一声明仍是 `Debug` ⇒ 全树行为与 `#39` 冻结态等价（下面每一步都只改"从哪取配置"，不改配置本身）。

| 类别 | 改了什么 | 站点数 |
|---|---|---|
| **生成器** | `build/port-lib.py`：① 新增 `_declared_config()`，`find_built_dll()` **按声明**找构建物（原先 `hits[-1]` = **由字典序**决定引用指向哪个配置）；② `relocatable()` 把仓库内路径 `bin/Debug|Release/` 重定位成 **`bin/$(Configuration)/`** | 2 处逻辑 |
| **波构建** | `build/integration-wave.sh`：构建命令加 **`-c "$SELFBUILT_CONFIG"`**（原先吃 `dotnet build` 的默认 Debug） | 1 处 |
| **验收构建/测试** | `verify-all.sh`：2 处 `dotnet build` ＋ **6 处 `dotnet test`** 全部 `-c "$SELFBUILT_CONFIG"` | 8 处 |
| **验收各步工具** | `frame-step.sh`／`pc-line-step.sh`／`hidden-only-step.sh`／`product-entry-step.sh`／`tline-gate.sh` 的 `AUTH_PC` | 5 处 |
| **应用门禁与样本 runner** | `run-wpftextdemo.sh`（样本 bin／两处一致性扫描／Provider／**样本构建**／`AUTH_PC`／扩展位）、`run-hellowpf.sh`、`run-wpfprobe.sh` | 16 处 |
| **第三方形态 runner** | `samples/ThirdPartyMini/run-thirdparty-mini.sh`（产物路径 ＋ 自身构建配置） | 2 处 |
| **桥（AOT）输入** | `build/MilBridge/run.sh` 的 4 个权威件对（原先写死 Debug ⇒ 会**静默**用陈旧件） | 4 处 |
| **五臂重取** | `retake-arms-w23.sh` 的 pc 读数 | 1 处 |
| **应用侧副本一致性（表驱动）** | `check-applocal-sync.sh` 的 **`ITEMS` 权威表**（原先 94 处写死、每行理由还写着"Debug 权威"）＋ `applocal-expect.py` 的 4 处权威路径（新增读同一份声明） | 4 ＋ 4 处 |
| **探针工程（14 个，48 处引用）** | 全部改成 `bin/$(WpfLinuxSelfBuiltConfiguration)/`；其中 8 个已 import `BuildHygiene.props`（声明由它传递进来，**不再重复 import**，避免 `MSB4011`），其余 6 个显式 import 同一份声明 | 48 处 ＋ 14 import |
| **测试工程** | `ManagedLayer.Tests.csproj` 的 7 处引用 → `$(Configuration)`（其余测试工程走 `ProjectReference`，天然跟随） | 7 处 |

**棘轮读数**：写死 `bin/Debug` 的 `.sh`/`.py` 处数 **198（侦察）→ 167**（棘轮上限已随之收紧到 167；剩余主要是不参与验收的开发期工具与散文/夹具）。

### 翻值前必须先做的两件事（都还没做）

1. **Release 全量可编性**：九个位里已验 5 个（替身／`System.Xaml`／`WindowsBase`／`PC`／`PF`）；还需
   `DirectWriteForwarder`／`UIAutomationTypes`／`UIAutomationProvider`／`PF.Classic`／`System.Printing`／
   `ReachFramework`／`PresentationUI`／`Input.Manipulations`／`CycleStub×3`／`WpfGfx.Linux` ＋ **AOT 桥**。
   任一编不过 ⇒ **不翻值**，如实登记。
2. **回退路径已内建**：翻值 = 改 `build/SelfBuiltConfig.props` **一行**；不对就改回那一行（这正是阶段 1 要买的东西）。

### 翻值后预期（写死，便于事后对账）

- 九个位**全部位移**（配置变了）⇒ 冻结 `#40` 时 `allow_changed` 声明九位；
- **五臂**：`GEN_KEYS` 未变、但 `pc` 的 **IL 会变**（Release 去掉断言/优化）⇒ 若 `verify-all` 第 `[4]`/`[6]` 步读数漂移，
  **按纪律重取三支 `tab-*` 臂**并重钉 `known-red.json`（不许拿"惯例"当理由跳过）；
- 应用门禁窗口内色数**不得下降**（S4：`default ≥ 3960`、`env ≥ 2828`）；
- **`D-G47` 的产品读数**（S5/S6）：用 Release 自产件重建 HandyControl 库 ＋ demo ⇒ **不再**出现
  `Assertion Failed: DependencyProperties can only be set on DependencyObjects`；用 Debug 件则**必须**复现。

---

## 9. `#40`：阶段 2/3 **落地**（Release 切换；本波冻结的那一代）

`#39` 只做了阶段 1（把配置收敛到唯一声明，值仍 Debug）。**`#40` 是同一件事的落地代**：

| 项 | 读数 |
|---|---|
| 翻值 | 唯一声明 `Debug → Release`；两条 import 图同时求值到 `Release`（`selfbuilt-config.sh --check` PASS） |
| 全量可编性 | **16 个自产件工程逐个 `-c Release` 全 0 错**（先做，任一失败即"不翻值"） |
| 波重建 | `integration-wave.sh` **rc=0 / 0 失败步骤**（`appliers=24 ok=83 miss=0`） |
| 五臂 | **重取**（`GEN_KEYS` 两处变动：`run.sh` 与 `HbTextLineParity/Program.cs` 的权威路径改读声明）⇒ `TLINE_GATE=PASS … unregistered=0 caliber=OK tree_gen=same` |
| 世代重钉 | 新增可复用工具 `build/MilBridge/tools/repin-generation.py`（`--check` 一颗牙）：**四类地方同趟**（generation 三项 ＋ arm_logs 五臂 ＋ evidence_log_sha256 ＋ `entries[*].caliber`）——漏最后一类会报 `registry-generation-inconsistent` 并点名无辜条目 |
| 门禁 | 两趟 **rc=0**、机读行 **6/6 `result=PASS`**（`default` / `env` 各 3 rep） |
| `verify-all` | **24 通过 / 1 失败**；唯一失败 = `COLUMN-FLOOR`（**声明类**：冻结块仍是上一代的 `tline` ⇒ 冻后必转绿） |
| 产品两极化（E） | `D-G47`：hc 同代码用 **Release** 件 ⇒ `assert_hits=0`、`rc=124`（活着）、`max_colors=373`；用 **Debug** 件 ⇒ `assert_hits=1`、`rc=134` ⇒ **断言两极化成立**（⚠️ Release 档 373 色 ≠ `#34` 的 1275 色 ⇒ 渲染完整度另立待办） |
| 同趟落的两件 | `#41` F：GDI+ 图像族真解码（探针 14/14 ＋ 撒谎 shim 反极性）；`#42` G：`D-T4` 定位读数 ⇒ **推翻其一半措辞** ＋ 新登记 `D-G48`（兜底接不住 ⇒ 落到不存在的原生 LS ⇒ 崩） |
