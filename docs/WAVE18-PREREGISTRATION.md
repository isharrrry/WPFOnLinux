# WAVE18 预登记（`#18` 波）—— **给两个"产品侧无保护"的 DllImport 解析器安装点加守卫**（`D-R3`）

日期：2026-09-16（主控）。被 `#17` 冻结为基线：九位见 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#17` 表头（`02d29280936bbf6c`）。

## 0.0 ⚠️ 修订 **v2**（2026-09-16 15:1x，主控）—— 车道 V18A 的落地带出**四条**要改的东西

报告：`build/MilBridge/V18A-report.md`（**`51c2480e4fd912e8`**）。**v1 原文保留**（见 §1/§2），更正如下：

| # | v1/依据写的 | 实测是 | 处置（**已裁决**） |
|---|---|---|---|
| **F1** | 只读审计 R17C §3-C1：**外部安装者"只能输"**（⇒ 产品侧那两个点**丢不了竞态**，故 `D-R3` 只是"潜在"） | **被推翻**：`Assembly.LoadFrom(pc)` 之后**外国解析器装得上**（`FOREIGN_INSTALL=OK`）⇒ **模块初始化器不是加载期跑的** ⇒ **产品丢竞态是可达的**（V18A 的红证就走这条路径；R17C 那次"宿主输"是因为 `WicClosedLoop` 走 `typeof(BitmapImage)` 触发了产品侧先跑） | **`D-R3` 的严重性上调：从"潜在"改为"可达"**（`build/shims/Win32ShimResolver.cs` 是 `[ModuleInitializer]`，输掉 ⇒ **整个模块的每个类型全废**）。**这条要在 `CURRENT-STATE` 与 `KNOWN-DEFECTS` 里改定性** |
| **F2** | §1 V2 的判据 (b)："抢先者**映射别的名字** ⇒ 响亮且点名" | **在本机不可达且与 (a) 互斥**：`libX11.so.6` 是**系统可解析名**（`ldconfig -p` 证据）⇒ 对产品侧而言 (a)/(b) **可观察面完全相同** | **改口径（v2）**："**响亮 ⟺ 我们自己映射的名字解析不到**"。⇒ V2 的 (b) = **无害 + 具名诊断（不抛）**；真正有害的那类（**接了名字但指到不可加载的位置**）**会点名抛**（已实测）。(a) 的定义随之改为"抢先者的解析器**能让我们的名字解析成功**" |
| **F3** | §2 位移表**没收**这一条 | **新位移**：V1 的**无条件**自证会在**正常路径**上把 shim 提前 `dlopen`（`/proc/self/maps` **0 → 5**） | **裁决 = 收窄**：自证**只在"我们输了竞态"的分支里跑**。**理由（这条理由本身是判据）**：本项目的**内存类主判据是"段数 / Σ虚拟"**（`D-F1c` 线的口径）⇒ **无条件多一次 dlopen 就是往那套尺子里塞一个新映射**，而"数值判据推论不变"是**论证不是读数**。**收窄后 §2 加一行**："正常路径的 `/proc/self/maps` 段数必须与修前**逐位相同（0→0）**"，**不满足 ⇒ 收窄没生效 ⇒ 停** |
| **F4** | §5 先决条件没提波的**构建表** | `build/integration-wave.sh` 的 `ORDER` **不含 `WpfGfx.Linux`** ⇒ 改了 `src/WpfGfx.Linux/**` 之后，波会**重发桥（拿到修后代码）**，但 **Debug 可见位与各 app-local 副本仍是修前的** —— 而后者**正是应用门禁实际加载的那一份** ⇒ **读数会漏掉该改动**（与 `D-R7` 同族："生效了但没进波"） | **已由主控修（本波内）**：`build/integration-wave.sh` **`770419556b9597df`（38,072 B）→ `1172784c38fb8e31`（38,717 B）**，把 `src/WpfGfx.Linux/WpfGfx.Linux.csproj` 加为 `ORDER` 的**第一项**（它是**叶子工程**：csproj 无任何 `ProjectReference`、只用 SkiaSharp ⇒ 放最前，后面按 HintPath 取它的工程与桥的 AOT 发布都拿新件），并在注释里写清理由。**干跑已确认**：`close-wave.sh --dry-run` ⇒ **`桥重发=是`**（`现树 fp=99e71fcdf27aba77` ≠ `记录=0b7c5a54267064fc`），与 §2 的预测一致 |

**另记一条与 `D-R6` 一致的观察（V18A 自报）**：私有构建的 sha **只在同一 `obj` 路径下可复现**（`obj` 路径被嵌进产物）⇒ **跨车道对拍产物 sha 时要注意输出目录是否相同**（这正是 `D-R6` 的口径：可复现性只在"同一输出目录内"成立）。

## 0. 本波要达成什么

`NativeLibrary.SetDllImportResolver(assembly, resolver)` **对同一个程序集只能装一次**，第二次抛 `InvalidOperationException: A resolver is already set for the assembly.`。
测试侧的那次已经修掉（`#16` 收官夜，`D-R2` 定案：唯一安装点 + 容忍被抢先 + **用真 `[DllImport]` 自证**）。

**产品侧还剩两个**（只读审计车道 R17C 全仓枚举的结论，报告 `build/MilBridge/R17C-audit.md` **`d5062f8b95369574`**）：

| 件 | 位置 | 形态 | 编进哪里 | 输掉时的后果 |
|---|---|---|---|---|
| **V1** | `build/shims/Win32ShimResolver.cs:174` | **`[ModuleInitializer]`** | **WindowsBase ∖ PresentationCore ∖ UIAutomationTypes ∖ UIAutomationProvider** 四个程序集（已在构建产物里实测） | **整个模块的每个类型都废** |
| **V2** | `src/WpfGfx.Linux/Windowing/X11Native.cs:34` | **静态构造** | `WpfGfx.Linux`（并随 AOT 进桥） | `TypeInitializationException` 覆盖 WpfGfx.Linux 全部 X11/呈现路径 |

**今天它们活着，只靠"运行时在模块加载时先跑 module initializer"这一条被观察到一次的事实 —— 而那不是契约。**
**唯一的活碰撞**已实测：PresentationCore = 产品的 `[ModuleInitializer]` × `WicClosedLoop/Program.cs:123` 的自装 ⇒ **产品侧总是赢**，有案可查（`build/DirectWrite.Linux/REPORT.md:1021` 逐字 `RESOLVER_INSTALLED=False InvalidOperationException: A resolver is already set for the assembly.`）⇒ 那个宿主的 `WindowsCodecs.dll` 映射**是死代码**（其 `_resolverInstalled` 标志只写不读）。

**本波目标**：把两处改成"**输掉竞态时要么无害、要么响亮且点名原因**"：
- **无害** = 抢先者的解析器**映射同一批名字** ⇒ 我们不必再装，功能不受影响；
- **响亮** = 抢先者**不映射**我们的名字 ⇒ **当场失败并点名**（"本程序集的 X 解析不到：生效的解析器不是我们这一个"），而不是让深处某次 `DllNotFound` 背锅 —— **注意**：`[ModuleInitializer]`/静态构造里抛异常会让模块/类型被毒化，**但那与今天的失败模式同类，只是文案变清楚**；这就是本波要的口径（**判据只许变强，不许变弱**）。

## 1. 落地件与逐件判据

> **通用纪律**：① 每件落完**各自取一次读数**；② 凡改"会被编译进产物"的源 ⇒ **落地判据必须含 `dotnet build …` 的 `error CS = 0`**（纪律 33）；③ **射程外读数必须逐位不动**，动了且归因不到 ⇒ **停 + 回退**；④ **不许**用"放宽判据/吞掉异常"来达成"不红"。

### V1 · `build/shims/Win32ShimResolver.cs`（module initializer，四个程序集）
- **改什么**：装解析器时容忍"已被装过"（`catch (InvalidOperationException)`），**并紧跟一次自证** —— 用**真的 `[DllImport]`**（该 shim 已映射的名字之一，例如 `user32.dll` 上的某个导出）走一次，解析不到就**抛一条点名原因的异常**。
- **⚠️ 已吃过一次的坑（必须照抄口径）**：自证**不许**用 `NativeLibrary.TryLoad(name, assembly, …)` —— 那个 API 只用程序集定**搜索路径**、**不走** `DllImportResolver`（`#17` 实测踩到：它恒 false ⇒ 毒化类型 ⇒ 33 条用例全灭）。**必须用真 `[DllImport]`。**
- **判据**：① 正常路径下 `user32.dll` 等映射仍然可用（真 `[DllImport]` 调用成功）；② **抢先者映射同名** ⇒ 不抛、功能不变；③ **抢先者不映射** ⇒ 抛且**消息点名**"生效的解析器不是我们这一个"；④ **shim 文件缺失** ⇒ 仍然响亮失败（不许被守卫吞掉）。

### V2 · `src/WpfGfx.Linux/Windowing/X11Native.cs`（静态构造）
- 同 V1 的三条判据，但 **(a)/(b) 的定义按 §0.0 的 F2 更正**："响亮 ⟺ 我们自己映射的名字解析不到"（`libX11.so.6` 系统可解析 ⇒ 原 (a)/(b) 在本机互斥）。**注意它是桥的源** ⇒ 改它 **必然改 `BRIDGE_SRC_FP` ⇒ 必须重发桥**（见 §3；**干跑实测 `桥重发=是`**）。

### V3 · `WicClosedLoop` 的死映射（登记 / 或修，由车道给理由）
- 它的 `WindowsCodecs.dll` 映射**永远不生效**（产品侧先占槽）。**两条出路**：把它删掉并写明理由，或改成"**先让产品侧装，再只补产品侧没映射的名字**"。**本波要求：二选一并写清依据**；**不许**留着不写。

## 2. 预测位移（**先写死，落完照此验**）

| 量 | 预测 | 依据 |
|---|---|---|
| `bridge`（`wpfgfx_cor3.so`） | **会变**（必须重发） | `X11Native.cs` 在 `src/WpfGfx.Linux/**` ⇒ 属桥源；`BRIDGE_SRC_FP` 由 `build/bridge-src-fp.sh` 按该目录算 |
| **`BRIDGE_SRC_FP`** | **会变** | 同上 |
| `pc` | **会变** | `Win32ShimResolver.cs` 编进 PresentationCore |
| `windowsbase` | **会变** | 同一个文件也编进 WindowsBase（`#17` 表头里这一位一直是 `e6216fe961a2bfb9`，**本波第一次动它**） |
| 扩展可见位 `uiatypes`/`uiaprovider` | **会变** | 同一个文件编进那两个程序集 |
| `WpfGfx.Linux.dll`（非九位） | **会变** | `X11Native.cs` |
| `pf` | **会变**（环成员） | 既定 churn |
| `shim`（`PresentationCore.HbTextLine.cs`） | **不变** | 本波**不动**它 |
| `inputs_fp` | **会变** | `build/shims/**/*.cs` 与 `src/WpfGfx.Linux/**/*.cs` 都在该指纹覆盖面里 |
| **所有判据读数** | **逐位不变** | 解析器行为在正常路径下不变：应用门禁（`drawn/colors/frames/cross_ae/leftover_after`）、五臂日志、`tline` 六项、`verify-all`（10 步 / 871 通过）、`T1C_CENSUS_SUMMARY`（`runs=167`、`glyphs=1717`、`distinctpids=4`） |
| **正常路径的 `/proc/self/maps`（V1/V2 自证收窄后）** | **逐位不变（0 → 0，不许多出映射）** | §0.0 的 **F3**；**不满足 ⇒ 收窄没生效 ⇒ 停**（本项目的内存主判据是"段数/Σ虚拟"，见 `D-F1c`） |
| **五臂世代绑定** | **仍是 `#16`** | generation 只绑 `run.sh`/`Parity`/**`PresentationCore.HbTextLine.cs`**（**本波不动这一个**）⇒ 实测应 `tree_gen=same`、**无需重取臂、无需重钉登记表** |

## 3. 波形态（**本波与 `#17` 的关键差别：必须重发桥**）

`X11Native.cs` 一动 ⇒ `BRIDGE_SRC_FP` 变 ⇒ `close-wave.sh` 的决策会给出"**需要重发桥**"。
- **重发桥是有锁的、按 PID 止损的动作**：`build/publish-milbridge.sh`（`/tmp/bridge-republish.lock` 串行化）。
- **顺序**：`close-wave.sh`（它会自己判断并重发）→ 身份自检（桥源指纹两侧一致、生成物指纹 `state=ok`、应用器审计 `miss=0`）→ `verify-all` → 汇总。
- **红证（重发的必要条件）**：① 重发后 `BRIDGE_SRC_FP` 文件值 == 现树值；② 新 `.so` 里能 `grep -a` 到**本波新引入的字符串**（例如那条点名异常的文案片段）⇒ 证明确实编进去了；③ 旧 `.so` 与新 `.so` **sha 不同**且旧值有留档（可回退）。
- **回退**：桥回退 = 用留档的旧 `.so`（`$HOME/wfp-runs/` 下按 sha 存一份）+ 重跑门禁；**不许**只回退源而不重发（那会产出 `BRIDGE_SRC_STALE=yes` 的假绿面）。

## 4. 本波**不做**的
- **不动** `build/shims/PresentationCore.HbTextLine.cs`（⇒ 世代绑定不变、臂与登记表都不用动；`P4` 与严格档 indent 缺口留到 `#19`）。
- **不修** `D-F2`（另立专项，前置 = 把 `SegmentFaceUnresolved` 印出来）。
- **不碰** `D-E1`、`D-T4`、`D-T5`、`D-T2-c`（只登记）。
- **不接**任何新判据进 `verify-all.sh`（接线另议）。
- **不许**为了让门禁变绿而放宽任何口径（纪律 3）。

## 5. 先决条件
1. **静树**（无车道在跑、无应用在跑、无重发锁）。
2. **常驻 `Xvfb :97` 必须在**（跑门禁前 `DISPLAY=:97 xdpyinfo`；**不在就先起**，不许"只打印不拦人"—— `#17` 我在这上面踩过一次）。
3. 各车道写域先宣告（`docs/CURRENT-STATE.md` §7）。
4. 开工前**现场重读**所有 `:NNNN` 锚点（行号会漂）。

## 6. 收尾清单
1. V1/V2/V3 逐件落地 + 各自读数。
2. `close-wave.sh`（本波**含桥重发**）⇒ `native_rebuilt`/`bridge_republished` 逐字记录。
3. 五臂门禁（应仍 `generation=#16 tree_gen=same`）+ 两极化。
4. **应用门禁两趟**（第 2 趟设 `WPTD_BASELINE_OUT`；常驻 `:97`）⇒ 与 `#17` **逐位对照**。
5. `verify-all`（10 步）。
6. 等号读者（在新 `pc` 上应仍 `SHIM_SHA=no`）+ T17A 工具（并列留档）。
7. 重冻 `#18`：新九位 + 6 条 `BASELINE` 行 + `inputs_fp` + 仪器版本；`#17` 表头降历史块（原文逐字保留）。
8. 文档收尾：`docs/CURRENT-STATE.md` §1/§3/§7、`handoff.md` 波记录、`docs/WAVE18-PREREGISTRATION.md` 收官节、`KNOWN-DEFECTS.md`（`D-R3` 的关闭或残余）。

## 7. 本预登记自己的口径
- 凡引用"某读数 = 某值"，必须连 **件 sha + 仪器 sha + 判据口径 + artifact 名/字段名** 一起写（纪律 15/18/26）。
- **红检测只许加强、不许放宽**（纪律 3）；以"吞异常/放宽容忍"达成的"不红"**一律判为造假**。
- 缺数据 ⇒ **`NOINFO`**，不许报绿；非 0 退出码先分类（`127`/`MSB1009`/`rc=134` = 装置/命令问题，不是判据失败）。
- 与 `docs/WAVE17-PREREGISTRATION.md` 冲突时**以本文件为准**（它更晚）。

## 8. `#18` 收官（2026-09-16 15:2x，主控）

### 8.1 三件全部落地
V1（`build/shims/Win32ShimResolver.cs` **`0735327b6ca3ae4b`**）｜V2（`src/WpfGfx.Linux/Windowing/X11Native.cs` **`8ede4d8a13cb3a28`**）｜V3（`WicClosedLoop` 死映射**已删**，`f7c7fd61ef5c8ad8`）。三态 sha 链见 §0.0 与 `build/MilBridge/V18A-report.md` **`2d7809699ebf51d4`**（606 行）。

### 8.2 波（**含桥重发**）与九位
`close-wave.sh` `15:08:49 → 15:12:43`：**`native_rebuilt=0`、`bridge_republished=1`（rc=0）**、`verify_all=PASS`（10 步 0 失败 / 871 通过）、输入稳定 `da68a95174e2ec5ab9b141c554de5afd31b58dccb139b291ae6d25526c072217`。
**新九位**：`bridge d567c26f197ec1e3`（4,987,840 B）｜`pc 663114436443d2de`（4,196,864 B）｜`pf d8bfdc23f260ccd2`｜`windowsbase 1114a28ec5a03ab7`｜`provider 9aa0d744802aaa31`｜`win32shim 0098234982391bbf`｜`wic_shim 03b67fbcd7c385b6`｜`hbtextline bc04c05ab6d8d82a`（未动）｜`dwf 0ed422ef2dd46445`；`BRIDGE_SRC_FP=b6acdba4f01599d8`。**相对 `#17` 五位变**（`bridge`/`pc`/`windowsbase`/`dwf`/`pf`）。

### 8.3 预测 vs 实测（**§2 的位移表**）
| 预测 | 实测 | 判 |
|---|---|---|
| `bridge` / `BRIDGE_SRC_FP` 变（必须重发） | `d567c26f197ec1e3` / `b6acdba4f01599d8`；**重发 rc=0** | ✅ |
| `pc` 变 | `663114436443d2de` | ✅ |
| `windowsbase` 变 | `1114a28ec5a03ab7`（**这一位自 `#8` 以来第一次动**） | ✅ |
| `uiatypes`/`uiaprovider`/`WpfGfx.Linux.dll` 变（扩展可见位） | 见 `WPTD_ARTIFACTS_EXT`（扩展位不称冻结元组） | ✅（记档） |
| `pf` 变（环成员） | `d8bfdc23f260ccd2` | ✅ |
| `shim` **不变** | `bc04c05ab6d8d82a` | ✅ |
| **所有判据读数逐位不变** | 应用门禁两趟 6/6 `result=PASS`、`drawn=260/144`、`colors=3960/2828`、`frames=14/14`、`cross_ae=0`、`leftover_after=0` **与 `#17` 逐位相同**；`verify-all` 10 步 0 失败 / 871 通过 | ✅ |
| 五臂世代仍是 `#16` | `TLINE_GATE=PASS … generation=#16 tree_gen=same … drift=0 gone=0 unregistered=0` | ✅（**无需重取臂/重钉表**） |
| **正常路径 `/proc/self/maps` 逐位不变（收窄后）** | `libwpfwin32.so` **0→0**、`libX11` **0→0**（V2 收窄后 TOTAL 244→244） | ✅ |
| **（漏项，如实记）`dwf`** | **也变了**（`0ed422ef2dd46445`）—— 机制 = DWF 的 csproj 用 **HintPath 引用 `WindowsBase.dll`** ⇒ WB 字节变 ⇒ Roslyn 确定性输出把引用件字节纳入输入哈希 ⇒ 它跟着变（**与环成员同族**） | ⚠️ **预登记不完整，不是未归因位移** |

### 8.4 冻结点
`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`：置入 `#18` 表头（**`0d0f1134d34c5ef8`**，512 行；`#17` 降为历史块）。应用门禁两趟都在**常驻 `:97`**（runner 走"复用"分支；`:97` 由主控在波前用 `setsid` 重新起过）。**等号读者 `SHIM_SHA=no`**（`artifact=663114436443d2de`）、T17A 工具 `PASS`（**只证下界**，并列留档）。

### 8.5 本波**没能**收掉的（不许当绿）
① `D-R3` 的"真宿主里会不会走到"只证了**路径可达**，没证真宿主会走；② **AOT 镜像内 `X11Native` 静态构造是否执行、其 `Assembly` 身份**未测；③ **收窄的代价**：判据① 不再由守卫行使（`realcall` 直测到 `REAL_DLLIMPORT=OK`，但**① 的修前对照没测过**、**V2 的 ① 没测过**），判据④ 退回修前同款行为；④ 全仓 9 个安装点里**其余 7 个**只在只读审计里枚举过；⑤ `P4`（`HasOverflowed` 注释）与**严格档 indent 缺口**留到下一波（同批动 shim）；⑥ `D-T5`/`D-T4`/`D-T2-c` 只登记未修；⑦ 新判据仍未接进 `verify-all.sh`。

### 8.6 下一波候选
① **`P4` + 严格档 indent 缺口**（同批动 `PresentationCore.HbTextLine.cs` ⇒ 一次**重取五臂 + 重钉登记表**覆盖两件 —— 这是 `#17`/`#18` 都没付的那笔成本）；② `D-T5`/`D-T4` 的判据补录（后者需 Windows 重录真值）；③ `D-F2` 专项（前置 = 把从不打印的 `SegmentFaceUnresolved` 印出来）。
