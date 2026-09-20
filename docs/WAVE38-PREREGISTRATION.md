# `#38` 预登记（**写在任何改动之前**）

> ⚠️ 时序：本件在任何代码/工程改动**之前**落盘（`#36` 那次补写的教训见 `docs/WAVE34-PREREGISTRATION.md` §3w；
> 本仓现在**有牙**了 —— `verify-all` 第 `[11]` 步的 `prereg=` 判据会要求**本代**在某个
> `docs/WAVE*-PREREGISTRATION.md` 的标题行里出现）。
> 基线：`#37`（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`，整份 sha16 只由 `docs/CURRENT-STATE.md` 的机器行声明）。

---

## 1. 目标：把 `D-G45` 的接线**打通或如实关闭**

**缺口回顾**（`D-G45`，`#36` 登记）：官方 `System.Windows.Extensions` 包在非 Windows 上把
`System.Xaml.Permissions.XamlAccessLevel`（以及 `SoundPlayer`/`SystemSounds`）实现成**必抛**
`PlatformNotSupportedException` 的桩；而 `XamlReader.LoadBaml` 只要程序集里生成了
`GeneratedInternalTypeHelper` 就**必然**调 `XamlAccessLevel.AssemblyAccessTo` ⇒ **正常构建的第三方
WPF 程序集一装 BAML 就崩**（`#34` 实测：HandyControl 示例工程）。
替身（`build/System.Windows.Extensions.Linux/`）与应用器（`patch-swe-linux.py`，7 个工程）都已写好，
`#36` 接线后 `PresentationFramework` 报 **11 条 `CS0012`**（`类型"XamlAccessLevel"在未引用的程序集中定义`）⇒ 回退。

## 2. 假设（**先写死，再验**）

| # | 假设 | 怎么证伪 |
|---|---|---|
| **H1** | `CS0012` 的根因是**混合身份**：应用器换了 csproj，但 `obj/project.assets.json` **没随隐式 restore 更新**（`#36` 没验过这一条）⇒ 一部分工程按**包**的签名身份编译、一部分按**替身**（未签名）⇒ 谁都不认谁 | 先复现 `CS0012`；**删掉受影响工程的 `obj/`** 再全量重建 ⇒ 若 **0 错** ⇒ H1 成立 |
| **H2** | 若 H1 不成立（清 `obj` 后仍有身份错），则根因在**签名**：包是签名的、替身没签名，`System.Xaml` 按包身份绑定 | 看残留错误点名的**程序集身份**（名字/版本/PKT）落在谁身上；必要时逐工程读 `AssemblyRef` |
| **H3** | 替身**本身**可用（`XamlAccessLevel` 不抛、`SoundPlayer` 不抛）——`#34` 只在"应用能起来"这一档验过，**没验过**它在 BAML 路径上真的被调用 | 用 §3 的 B4 用例正负两趟 |

## 3. 判据（写死；读数之后再改就算事故）

| 编号 | 判据 | 通过条件 |
|---|---|---|
| **B1** | 全量构建 | 4 个产品件 ＋ 3 个样本 **0 error**；`PresentationFramework` 不再有 `CS0012` |
| **B2** | 身份一致 | 用 `patch-swe-linux.py --check` 复核 **7/7 已接线**；且**没有任何** `obj`/`bin` 里残留"按包身份编译"的中间件（判据 = 清 `obj` 重建后仍 0 错） |
| **B3** | 运行期真装上 | 替身 `System.Windows.Extensions.dll` **出现在应用输出目录**（`bin/`）里，且 `sha16` == 替身工程产物 |
| **B4** | **在册红用例真的转绿**（最关键） | 新落一个**最小**用例：XAML 里引用**internal 类型** ⇒ PBT 生成 `GeneratedInternalTypeHelper` ⇒ 装 BAML 时走 `XamlAccessLevel`。**负极性**（把替身换回包）该用例**必须崩**（逐字 `PlatformNotSupportedException`）：证明它不是恒绿 |
| **B5** | 既有验收不回退 | `verify-all` **25 步全绿**；应用门禁 6/6 `result=PASS`；第三方形态步 `THIRDPARTY=PASS` |

## 4. 边界（明说）

- 本波**不碰** `upstream/wpf/**`；**不动**九位里除"因接线而必然重编"之外的东西（预计 `pc`/`pf`/`windowsbase`/样本会重编 ⇒ 按代声明 `allow_changed`）。
- **不许**用"给替身签名/伪造 PKT"这类手法绕过身份问题（那是在**假装**自己是 Microsoft 的程序集）。
  若 H2 成立且无法在不伪造身份的前提下解决 ⇒ **如实关闭 `D-G45`**（写明"要解决必须伪造程序集身份，本工程不做"），
  并把可用的**降级路径**（部署期用替身覆盖包件 / 只对不含 `GeneratedInternalTypeHelper` 的程序集有效）写进文档。
- 可逆性：动手前把 7 个 csproj 备份到 `$HOME/w38-backup/`；失败即**原样恢复**并重建。

## 5. 复现命令

```bash
# 备份 → 接线 → 复现 → 清 obj → 重建 → 复核
cp -a <7 个 csproj> $HOME/w38-backup/
python3 src/WpfGfx.Linux.Native/tools/patch-swe-linux.py --check      # 0/7（未接线）
python3 src/WpfGfx.Linux.Native/tools/patch-swe-linux.py             # 7/7
rm -rf build/{System.Xaml,WindowsBase,PresentationCore,PresentationFramework}.Linux/obj \
       samples/{HelloWpf,WpfFeatureProbe,WpfTextDemo}/obj
WAVE_OWNER=主控 bash build/integration-wave.sh
bash verify-all.sh
```

---

## 6. 结果（**已做**；判据与预登记 §3 逐条对应）

| 判据 | 结果 |
|---|---|
| **B1 全量构建** | **7 个九个位工程 + 4 个样本全部 0 error**（含 `PresentationFramework` —— `#36` 那 11 条 `CS0012` 与 7 条 `CS1061/CS1503` **全消**） |
| **B2 身份一致** | `patch-swe-linux.py --check` **7/7**；清 `obj` 重建后仍 **0 错**；`integration-wave.sh` **rc=0 / 失败步骤 0**（应用器审计 `appliers=24 ok=83 miss=0 red=0`） |
| **B3 运行期真装上** | 替身 `System.Windows.Extensions.dll` **出现在每个应用输出目录**，`sha16` = 替身工程产物（`#38` 时 = `65803affbc7e8e8d`；签名的替身在波内重建后又变） |
| **B4 在册红用例转绿** | 见下（**正反两趟都跑了**） |
| **B5 既有验收不回退** | 收尾链见 §7（门禁 ×2 ＋ `verify-all` 25 步） |

### 两条真根因（`#36` 的失败**不是**"替身不可用"，而是这两条）

1. **应用器的 HintPath 写死了 `bin/Release/`**，而 `integration-wave.sh` 把替身建在 **Debug**（波自己的配置）
   ⇒ 引用**落空** ⇒ RAR 回落到**官方包**（它还在 assets 里）⇒ 编出来的 `System.Xaml.dll` 带着
   **包的签名身份** `PublicKeyToken=cc7b13ffcd2ddd51` ⇒ `PresentationFramework` 报
   `CS0012: 类型"XamlAccessLevel"在未引用的程序集中定义`。
   修法：HintPath 改 `bin/$(Configuration)/`（**跟随消费方配置**）。
2. **`System.Security.Permissions 9.0.0` 传递依赖 `System.Windows.Extensions 9.0.0`**
   ⇒ 把直接包引用**整条删掉**也没用 —— restore 仍把包拉回来（实测 `project.assets.json` 里 SWE 命中 **14 处**），
   RAR 于是按**包**解析（签名身份）。修法：留一个**排除 `compile;runtime` 资产**的**占位包引用**。
   ⚠️ `#36` 只试过 `ExcludeAssets="runtime"` —— **编译资产还在**，所以包照样赢；那条否证**不适用于本形态**
   （同族教训：**"试过一个变体失败"不等于"这条路不通"**——必须把变体写清楚）。

**顺带答了 `#36` 未验的那一问**：删/改 `PackageReference` 后，`obj/project.assets.json`
**会**随隐式 restore 更新（`PC`/`PF` 的 assets 里 SWE 命中 **0**）——但 `System.Xaml`/`WindowsBase`
**不会自动清掉传递依赖**的那一份（那正是根因 ②）。

### 替身公开面必须"按上游真的用到哪些成员"补齐（**两个**包内类型家族）

- `SoundPlayer`：`#36` 只写了最小面 ⇒ 接线后 PF 报 7 条 `CS1061/CS1503`，逐条来自
  `SoundPlayerAction.cs`（`Dispose` / `IsLoadCompleted` / `LoadCompleted` / `Stream` / `new SoundPlayer(Stream)` / `LoadAsync` / `Play`）。
  ⚠️ `IsLoadCompleted` **必须在 `LoadAsync()` 后为 true**：上游紧接着一句 `Debug.Assert(m_player.IsLoadCompleted)`，
  而权威件是 **Debug** 构建 ⇒ 断言**是活的**。
- `X509Certificate2UI` + `X509SelectionFlag`：**也在官方包里**（`WindowsBase` 的
  `PackageDigitalSignatureManager.PromptForSigningCertificate` 用它）⇒ 排除包资产后必须由替身补上。
  口径：证书选择**是真对话框**，Linux 上没有等价物 ⇒ **如实抛 `PlatformNotSupportedException`**（不是谎话）。
- ⚠️ 还踩了一次**命名空间**：X509 那两个类型我一开始插进了 `namespace System.Media` 里 ⇒ 4 条 `CS0103`；
  必须放在 `namespace System.Security.Cryptography.X509Certificates`。

### B4 的**两极化**（本波最关键的一组读数；devices 在仓内）

探针 = `samples/ThirdPartyMini` 里加一个 **internal** 控件（`InternalBadge : ContentControl`）并在 XAML 里引用它
⇒ PBT 给该程序集生成 `GeneratedInternalTypeHelper`（**实测生成物里命中 1 次**）⇒
`XamlReader.LoadBaml` **必然**走 `XamlAccessLevel.AssemblyAccessTo`：

| 档 | 读数 |
|---|---|
| **正极性**（替身接线） | `THIRDPARTY=PASS frames=28 max_colors=1642 min_colors=800`、`THIRDPARTY_IMAGE=PASS 96x96 format=Bgra32`、`rc=0` |
| **反极性**（把配方临时换回官方包） | `THIRDPARTY=FAIL frames=0 reason=app-exit=134`、`rc=1`，异常逐字：`System.PlatformNotSupportedException: System.Windows.Extensions types are not supported on this platform.` |

⇒ **"官方包在非 Windows 上必抛、替身不抛"这件事第一次有了仓内两极化判据**（此前只有仓外 HandyControl 的口头证据）。

### ⚠️ 顺带撞出一条**新缺陷**（第三方 demo 仍然起不来，但**与 SWE 无关**）

用真实第三方应用（`/home/links-dev/hc-linux` 的 HandyControl demo）复验时：库 + demo **0 error**，
但运行期死在 **`Assertion Failed: DependencyProperties can only be set on DependencyObjects`**
（`MS.Internal.Helper.CheckCanReceiveMarkupExtension` ← `BindingBase.ProvideValue` ← `TemplateContent` 解析模板）。
**反极性对照**：把配方换回官方包再跑，**同一个 assert**（而**不是** `PlatformNotSupportedException`）
⇒ ① 这条 assert **不是** SWE 接线造成的；② 该 demo 的程序集里**没有** `GeneratedInternalTypeHelper`
（实测 `grep -c` = 0）⇒ 它今天**走不到** SWE 那条路 ⇒ 它不能当 B4 的 device（B4 才改用仓内的 internal 类型探针）。
根因方向：**Debug 权威件 + 上游 `Invariant.Assert` 未条件化** —— 正是"权威件切 Release"（待办 ③）要治的那一族。
已登记 `D-G47`。
