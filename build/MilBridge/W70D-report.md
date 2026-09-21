# W70D · `TASK-0403` / `D-G71`：视觉级效果「静默丢弃」→「有台账、看得见」（**只做可见化**）

> 仓库根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（下文相对路径均相对 `$R`）。
> 本件**不实现效果渲染**（那是 R4 长线，明令不在本件范围）。本件只做一件事：
> 把「设置视觉级效果 → 没有人读 → 效果被丢掉」变成**一条可读的台账**。
> 报告 sha16：见 §8 末（先生成、后回填）。
> 私有工作目录：`$HOME/w70d/`（日志、备份、反极性脚本；仓内只新增报告与测试两个文件）。

---

## §2′ **裁定块（显眼处，读结论前先读这一格）**

> ### 🔴 本波**只**做「通道级具名台账」；**「进 `未画种类` / `NotDrawn`」那一支本波不做**（主控已登记为待办 `#50`）。
> ### ⚠️ 本件**会让 `wpfgfx_cor3.so` 变**（现 `79e45aed26487045`）：`src/WpfGfx.Linux/**` **进桥、不进 `pc`** ⇒ 收尾链重建桥时会出现**一个新值**，那是**本件**造成的，不是有人偷改。
> ### ⚠️ 但**本件的判据不依赖重建桥**：全部读数在托管单元测试里取到（§5/§6）；桥值变化是收尾链重建的**副产品**。可机器核对的"改动真的进桥了"的证据（收尾链重建后跑）：`strings -el <新 wpfgfx_cor3.so> | grep -c NOTIMPL-VISEFFECT` —— **此刻 = 0**（未重建），重建后**应当 ≥1**。

**为什么不做那一支（一句话）**：`未画种类 0` **不是**纯诊断计数器，它是**一条冻死的验收判据的输入**（`samples/WpfTextDemo` 判据②），而 `WpfTextDemo` 里正好有一个 `Border.Effect = DropShadowEffect`（必然发 `0x1d`）⇒ 记进 `NotDrawn` 会把该判据从绿顶到红，而那个基线文件本件**明令不许改**。
**⇒ 不要把本件读成"已把静默变红"**：本件是把静默变**可见**（有具名台账），**没有**动任何既有判据。

---

## §1 判定点（**判据先写、后动代码**）

### 1.1 判据（动代码**之前**写死；实现完成后逐条给读数）

| # | 判据 | 反极性（必须能红） | 读数 |
|---|---|---|---|
| ① | 一条 `MilCmdVisualSetEffect(0x1d)` 带**非空效果句柄**时，产生**一条可读台账**，字段**至少三样**：命令号 `0x1d` ＋ **该视觉的句柄** ＋ **效果句柄** | 注释掉台账调用点 ⇒ 条目数 `1 → 0` ⇒ 用例①红 | ✅ §6（`Expected: 1 / Actual: 0`） |
| ② | **零判据位移**：渲染行为逐字不变 —— `v.Visual.Effect` 照写、`未画种类`/`NotDrawn` **仍 0** | 见 §2（**本件动手前发现的判据冲突**） | ✅ §6 用例③ 实读 `未画种类=0` |
| ③ | **不许把"清空效果"误记成"效果被丢弃"**：`hEffect == Null` 的 `0x1d`（上游用它清除效果）不入账；非 `0x1d` 命令不入账 | 把 `Null` 也记进去 ⇒ 用例②红 | ✅ §6 用例② |
| ④ | 有界：逐条打印有上限、触顶**打一行汇总**（不静默截断），且**累计条数不被上限吃掉** | 上限写成"截断且不报" ⇒ 用例④红 | ✅ §6 用例④（40 条 ⇒ 打印 32＋1 行，累计仍 40） |

### 1.2 判定点（`文件:行`，**三跳**）

| 跳 | 位置 | 读数（本趟实查） |
|---|---|---|
| **① 唯一写入点** | `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs:173-192` 的 `case MilCmd.MilCmdVisualSetEffect:`（`v.Visual.Effect = se.HEffect;` 在 **`:178`**；改前是 `:177`） | `MilVisualNode.Effect` 全仓写点 = **1 处**；读它的只有单元测试 `tests/…/Commands.Tests/CommandRoundTripTests.cs:89` |
| **② 投影即丢** | `src/WpfGfx.Linux/Resources/VisualProjection.cs`（`Project(...)`） | 该文件 `grep -c Effect` = **0**；契约类型 `MilVisual`（`src/WpfGfx.Linux/Contracts/Interfaces.cs:53-79`）**没有 `Effect` 字段**（只有 `Handle/Offset/Transform/Opacity/Clip/Content/Children/WorldTransform/RenderOptions/AlphaMask`）⇒ 效果在**投影那一跳**就没了。该文件自己的注释就写着这一族风险：「⚠ 加字段**不会**编译报错，漏填只会静默默认值」 |
| **③ 消费点＝不存在** | `src/WpfGfx.Linux/Rendering/**` | 全目录 `grep -c "Visual\.Effect\|\.Effect\b"` = **0**（唯一 `Effect` 命中是 `SkiaEffect`/`SKPathEffect` 与**另一条路** `MilPushEffect(0x55)`） |

### 1.3 与上游的对应（"这条命令在真 WPF 里确实会被发"，逐字读 `upstream/`）

```
samples/WpfTextDemo/MainWindow.xaml:17-20      <Border.Effect><DropShadowEffect …/></Border.Effect>
samples/WpfFeatureProbe/FeatureBlocks.cs:522/526   shadow.Effect = new DropShadowEffect{…} / blur.Effect = new BlurEffect{…}
  ⇒ upstream/…/PresentationCore/System/Windows/UIElement.cs:2761-2785
        EffectProperty 注册 + OnEffectChanged ⇒ pushEffect() ⇒ base.VisualEffect = Effect
  ⇒ upstream/…/PresentationCore/System/Windows/Media/Visual.cs:1418-1450
        UpdateEffect(): effect != null ⇒ DUCE.CompositionNode.SetEffect(handle, hEffect, channel)
                        effect == null（且 isOnChannel）⇒ SetEffect(handle, Null)   ← **清效果**
  ⇒ upstream/…/WpfGfx/include/exports.cs:1877-1884
        command.Type = MILCMD.MilCmdVisualSetEffect（= 0x1d，见 include/Generated/wgx_command_types.h:53）
```

⇒ **任何**把 `Effect` 挂在 `UIElement`（`Border`/`Panel`/`TextBlock`…）上的 WPF 内容都会发 `0x1d`。本移植**收得下**（`S_OK`、不 abort）却**没有人消费**。

---

## §2 为什么**不能**走「进 `未画种类` / `NotDrawn`」那一支（**动手前**发现的判据冲突）

`D-G71` 登记原文给的是二选一：「要么消费它，要么像 `MilPushEffect` 一样进 `NotDrawn` 台账」。第二支最省事（`SkiaRenderBackend` 加一行 `Diagnostics.RecordNotDrawn(...)`），**但它会把一条冻死的判据打红**：

1. `samples/WpfTextDemo/MainWindow.xaml:17-20` 有一个 `Border.Effect = DropShadowEffect`；
2. §1.3 的上游链证明它**必然**发 `MilCmdVisualSetEffect(0x1d)`；
3. `WpfTextDemo` 的验收判据②就是 **`未画种类 0`**（`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh:21`；冻死值见 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`，**本件明令不许改**）；
4. ⇒ 把"视觉级效果"记进 `NotDrawn` ⇒ 该样例 `未画种类` 由 `0` 变 `≥1` ⇒ **应用门禁 `WPTD_GATE` 当场转红**（`acceptance` 掉一档）。

**记账口径（不许含糊）**：第 1、2 点是**逐字读源码得到的静态事实**（`文件:行` 已给）；**第 4 点是推导**——本件**没有跑应用**（不许跑 `integration-wave`/`close-wave`/`verify-all`，且槽由 W70A 优先），故：

```
NOINFO-1：WpfTextDemo 实跑时 0x1d 的**条数**、以及"若记进 NotDrawn，未画种类变成几" = **未取数**。
          复算命令（本件未执行）：WPF_LINUX_CMDLOG=1 WPF_LINUX_CMDLOG_ID=0x1d \
            bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh …  然后 grep -c 'id=0x1d' <mil.log>
```

⇒ **主控裁定（2026-09-21）**：本波走「通道级具名台账」；「进 `未画种类`」那一支 **本波不做**，登记待办 `#50`（要动就得先重冻 `WpfTextDemo` 判据②）。

> **纪律自证**：这一格是**在动代码之前**发现的（先读判据、再读实现），不是改完才发现。留在报告里也是给下一个人省一趟：
> 「把静默**变成红**」在本仓**有代价** —— `未画种类 0` 本身是一条**冻死的验收判据**的输入，不是纯诊断计数器。

---

## §3 修法逐处（三处，`before → after` sha16 现场算）

| # | 文件 | 改动 | before sha16 | after sha16 |
|---|---|---|---|---|
| ① | `src/WpfGfx.Linux/Resources/MilChannel.cs` | 新增台账：`VisualEffectIgnoredCommands`（计数）＋ `VisualEffectIgnoredByVisual`（视觉句柄 → 条数）＋ `VisualEffectIgnoredLines`（有界的行本体，进程内可枚举）＋ `NoteVisualEffectIgnored(...)` ＋ 行拼装 `DescribeVisualEffectIgnored(...)`（**唯一实现**，通道与测试读同一串）；逐条打印上限 `VisualEffectLogBudget=32` ＋ 触顶一行 | `4a79d7437fd428ba` | `24f3028f84426165` |
| ② | `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs` | `case MilCmd.MilCmdVisualSetEffect:`：**赋值之后**加一行 `if (!se.HEffect.IsNull) ch.NoteVisualEffectIgnored(se.Handle, se.HEffect);`（顺带把 `ReadFixed` 的结果提成局部变量 `se`，为了同时拿到 `Handle`） | `62203635d795f832` | `17f251a6d382dd42` |
| ③ | `tests/WpfGfx.Linux.Tests/Rendering.Tests/VisualEffectIgnoredLedgerTests.cs` | **新增**（4 条用例：①看得见且字段齐 ②`Null`/非 `0x1d` 不入账 ③零判据位移 ④有界且触顶会说话） | ——（新文件） | `ec853db920b0289a` |

**修法语义（三句话）**：① `0x1d` **带非空效果句柄** ⇒ 记一条台账（命令号＋视觉句柄＋效果句柄＋序号）；② `0x1d` **带空句柄**（上游的"清效果"）⇒ **不入账**；③ 渲染行为**一个字节都不动**（`v.Visual.Effect` 照写、不新增绘制、不碰 `未画种类`）。

**台账行形态**（实读，见 §6）：
```
NOTE [NOTIMPL-VISEFFECT] ch=1 id=0x1d MilCmdVisualSetEffect visual=0x00000001 effect=0x00000002 第 1 条 ⇒ **接受但不消费（视觉级效果不渲染；投影层与渲染层都没有消费者）**
```
- 输出汇与 D-G58 的 `[NOTIMPL-SHADER]` **同一本账**：`MilPresentation.Trace` ⇒ `WPF_LINUX_MIL_LOG=<path>` 指向的 `mil.log`（`WPF_LINUX_MIL_TRACE=1` 时同时进 stderr）＝ W62A 读 `0x1d` 的那个文件。
- 备份：`cp -p` 到 `$HOME/w70d/backup/{MilChannel.cs.orig,MilCommandDispatcher.cs.orig,MilCommandDispatcher.cs.fixed}`（三份都在，`*.orig` = 改前，`*.fixed` = 改后定稿＝反极性腿的还原源）。

**写域说明**：`Resources/MilChannel.cs` 不在派单首段列的 `{Commands,Rendering}/**` 里 —— 它是**主控中途裁定原文点名**的落点（"用 `MilChannel` 同族的 `NoteShaderStubAccepted` 形态（`Resources/MilChannel.cs:107`）新增 `NoteVisualEffectIgnored(...)`"）⇒ 有授权。`build/shims/**`、`build/PresentationCore.Linux/**`、四个路由件、`declared.tsv`、`ACCEPTANCE-BASELINE.md` **一律未碰**（§7 有清单）。

---

## §4 零回归：现状对照（改前 → 改后）

| 判据 | 改前 | 改后 | 结论 |
|---|---|---|---|
| `Commands.Tests` | `失败:0 通过:562 跳过:0 总计:562`（主控给的基线） | **`失败:0 通过:562 跳过:0 总计:562`** 逐字相同（§5 两套汇总格式各一份） | ✅ **零位移**（新增测试**故意**不放这个工程，就是为了让这个数逐字不动） |
| `Rendering.Tests` | `失败:0 通过:162 跳过:2 总计:164`（归档 `~/w58a-verify/verify-all-1.log`，**改前**的 verify-all 现场） | **`失败:0 通过:166 跳过:2 总计:168`** | ✅ **+4 全是本件新增**，跳过数**未变（2）** ⇒ `verify-all.sh:186-192` 的 `SKIP_CEIL_STATIC[Rendering.Tests]=2` 上限**未越**（这是 `#27` `D-G17` 的跳过上限断言） |
| `未画种类` / `NotDrawn` | 0 | **0**（§6 用例③ 实读，含"内容真画出来了"的对照） | ✅ 判据② 成立 |
| 既有单元测试 | —— | 全绿（两个工程各 1 趟 `-v q` 全量跑） | ✅ |

---

## §5 `dotnet test` 全绿读数（含总数）＋ 日志（"树状态＋命令＋汇总行"三样齐）

**A. `Commands.Tests`（要 `-v q` 那一套汇总格式；父代理曾把这份读成 193 B，实为 `/ 采在跑完之前 /`——进程当时在等槽 23 s）**

```
命令:  dotnet test tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj --nologo -v q
汇总:  已通过! - 失败:     0，通过:   562，已跳过:     0，总计:   562，持续时间: 756 ms - WpfGfx.Linux.Commands.Tests.dll (net10.0)
日志:  $HOME/w70d/03-commands-tests-green.log   623 B   sha16 82c3060ce0926264   mtime 12:33:22
★ 终态那一趟（**树状态＝下面那两个 sha16**，为消歧义在全部改动冻结后重跑）:
       $HOME/w70d/15-commands-tests-final.log   619 B   sha16 bd8bd6efee4759e7
       已通过! - 失败:     0，通过:   562，已跳过:     0，总计:   562，持续时间: 1 s - WpfGfx.Linux.Commands.Tests.dll (net10.0)
```
```
命令:  同上，但 -v n（另一套汇总格式，做交叉印证）
汇总:  测试运行成功。 / 测试总数: 562 / 通过数: 562 / 0 个警告 / 0 个错误
日志:  $HOME/w70d/05-commands-tests-explicit.log  93,245 B  sha16 1e02972f092525e7
树状态: MilChannel.cs 24f3028f84426165 ｜ MilCommandDispatcher.cs 17f251a6d382dd42（终态）
```

**B. `Rendering.Tests`（含本件 4 条新用例）**

```
命令:  dotnet test tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj --nologo -v q
汇总:  已通过! - 失败:     0，通过:   166，已跳过:     2，总计:   168，持续时间: 4 s - WpfGfx.Linux.Rendering.Tests.dll (net10.0)
日志:  $HOME/w70d/13-rendering-tests-final.log  384 B  sha16 479c823d6f3c977a   ← **终态**（树＝上面那两个 sha16）
       $HOME/w70d/02-rendering-tests-green.log  624 B  sha16 493e2e9fdb26020a   ← 同值（改 warning 后的一趟）
早先一趟 01 已作废（那条 `xUnit2013` 警告 ⇒ 我改了断言写法，报数只用 02/13）
```

**C. 全部包裹**（内存纪律）：
```
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 120 -- timeout 110 <dotnet …>
实读:  HEAVYSLOT=ACQUIRED waited=23s／0s ｜ HEAVYSLOT=MEMOK avail=2731MB／2552MB／2339MB／2529MB ｜ HEAVYSLOT=RELEASED rc=0
零 HEAVYSLOT=MAXHOLD_KILL、零 NOINFO low-memory ⇒ 以上每趟**都是读数**
```

---

## §6 两极化（**撤件必红 ∧ 还原必绿**，成对读数）

**撤件预报已按新纪律发给主控**（时刻＋哪一件＋从哪到哪＋目的），撤件/还原**在同一个脚本内闭合**：`$HOME/w70d/polarity2.sh`（仓内**零改动**、只动 `MilCommandDispatcher.cs` **一行**）。

```
脚本输出（原文摘，全份见 $HOME/w70d/14-polarity2-run.txt  sha16 f7a437ae2458d529 / 1533 B）：
POLARITY2_START at=2026-09-21 12:36:09   现场 dispatcher=17f251a6d382dd42 定稿副本=17f251a6d382dd42 dll=7d0b25d6032daae8
A_RESTORED_TOUCH rc=0 dll=9ff7f001dc429143  已通过! - 失败: 0，通过: 1，已跳过: 0，总计: 1
B_REVERSED      at=12:36:14 dispatcher=9e133977e9d34f3a 未注释调用点残留=0
   191:  //【W70D 反极性腿·临时撤件】if (!se.HEffect.IsNull) ch.NoteVisualEffectIgnored(se.Handle, se.HEffect);
B_REVERSED_TEST rc=1 dll=7d0b25d6032daae8  失败! - 失败: 1，通过: 0，已跳过: 0，总计: 1
   [FAIL] …VisualEffectIgnoredLedgerTests.set_effect_is_recorded_with_command_id_visual_and_effect_handles
     Assert.Equal() Failure: Values differ
     Expected: 1
     Actual:   0
C_RESTORED      at=12:36:19 dispatcher=17f251a6d382dd42 未注释调用点残留=1
C_RESTORED_TEST rc=0 dll=9ff7f001dc429143  已通过! - 失败: 0，通过: 1，已跳过: 0，总计: 1
D_FINAL_RENDERING rc=0 dll=9ff7f001dc429143 已通过! - 失败: 0，通过: 166，已跳过: 2，总计: 168
POLARITY2_END at=2026-09-21 12:36:32 dispatcher=17f251a6d382dd42
```

| 腿 | 树状态（`MilCommandDispatcher.cs`） | 被测 `WpfGfx.Linux.dll` sha16 | 读数 |
|---|---|---|---|
| A 还原态（`touch` 逼重建） | `17f251a6d382dd42` | `9ff7f001dc429143` | **绿** 1/0 |
| **B 撤件态** | `9e133977e9d34f3a`（调用点被注释，残留 0） | `7d0b25d6032daae8` | **红** 1 失败，`Expected: 1 / Actual: 0` ✅ 判据③ |
| C 还原态（`cp -p` ＋ `touch`） | `17f251a6d382dd42` | `9ff7f001dc429143` | **绿** 1/0 |
| D 还原态·全工程 | `17f251a6d382dd42` | `9ff7f001dc429143` | **绿** 166/0（跳过 2） |

**用例①②③④ 的实读（正极性，`-v q --filter … --logger console;verbosity=detailed`；`$HOME/w70d/04-newtests-detail.log` sha16 `00200f3f08f256b9`）**：
```
① 台账行: NOTE [NOTIMPL-VISEFFECT] ch=1 id=0x1d MilCmdVisualSetEffect visual=0x00000001 effect=0x00000002 第 1 条 ⇒ **接受但不消费（视觉级效果不渲染；投影层与渲染层都没有消费者）**
② Null 清效果 + SetTransform + SetAlpha 之后：台账 0；再来两条真效果 ⇒ 台账 2（逐视觉计数 = 2）
③ 中心像素=#D02020 未画种类=0 未画总数=0 摘要='' 台账=1        ← **判据②（零判据位移）的实读**
④ 40 条 ⇒ 累计 40、逐视觉 40、打印 32 明细＋1 行触顶；触顶行: …逐条打印已到上限 32 条…（本行**不是**说没有更多）
```

### 6.1 ⚠️ 本趟的**仪表自伤**（RP 纪律：如实入册，且它是"文件名不构成证据"的又一例）

反极性腿 **v1** 用 `cp -p` 还原 ⇒ **还原后源文件 mtime（12:30:47）旧于已编译 DLL（12:35:22）** ⇒ **MSBuild 增量判定不重建** ⇒ v1 的"还原腿"读到的其实是**撤件态的 DLL**：

```
V1 读数（**已改名，不再叫 final**）:
  $HOME/w70d/06-polarity-reversed-v1.log           sha16 236b296c41e6db7f   失败: 1/通过: 0（撤件腿，符合预期）
  $HOME/w70d/07-polarity-restored-v1-STALE-DLL.log sha16 e32f48763460f385   失败: 1/通过: 0  ← **假红**（陈旧 DLL，不是"还原没生效"）
  $HOME/w70d/08-rendering-tests-v1-STALE-DLL.log   sha16 03834773eef7bb75   失败: 4/通过: 162 ← **就是撤件态 DLL 的读数**（4 条新用例都依赖台账，故全红）
机器证: stat src/…/MilCommandDispatcher.cs = 12:30:47  <  stat tests/…/bin/Debug/net10.0/WpfGfx.Linux.dll = 12:35:22
```
⇒ **v2 的修法**：还原后 `touch` 逼重建，并把每一态的 `WpfGfx.Linux.dll` sha16 一并打出**作为"重建确实发生了"的机器证**（A/C/D 的 dll 同值 `9ff7f001dc429143`，B 的 dll 不同值 `7d0b25d6032daae8`）。
⇒ **可复用教训**：本仓强制 `cp -p` 备份/还原；但 `cp -p` **保留旧 mtime**，与 MSBuild 的增量判定**相冲** ⇒ **凡"还原后重跑"的腿，必须 `touch`（或用 `--no-incremental`）并在报告里给出 DLL 的 sha16**，否则会读到上一态的 DLL 而当成本态的读数。**v1 的三个文件名已全部改名**（`*-v1*`、`*-v1-STALE-DLL*`），不留在盘上误导人。

---

## §7 边界 / `NOINFO` / 未覆盖（逐条确切条件）

| # | 项 | 口径 |
|---|---|---|
| `NOINFO-1` | `WpfTextDemo` 实跑的 `0x1d` 条数与"记进 `NotDrawn` 后 `未画种类`" | **未取数**（不许跑 `verify-all`/`integration-wave`/`close-wave`；槽由 W70A 优先）⇒ §2 的第 4 点只算**推导**。复算命令已给（§2） |
| `NOINFO-2` | **应用侧**是否真能看到这条台账（`mil.log` 里的 `[NOTIMPL-VISEFFECT]`） | **本趟没跑应用** ⇒ 未取数。**确切条件**：`WPF_LINUX_MIL_LOG=<path>` 起 hc/WpfFeatureProbe ⇒ `grep -c 'NOTIMPL-VISEFFECT' <path>`。**仓内可证的部分已证**：行本体＝`MilChannel.VisualEffectIgnoredLines`，通道用的就是 `MilPresentation.Trace`（与 `[NOTIMPL-SHADER]` 同一汇），且同一串在测试里逐字断言 |
| `NOINFO-3` | 重建桥后的 `wpfgfx_cor3.so` 新值 | 本件**不重建桥**（不由我做）⇒ 无读数。现发布件 `79e45aed26487045`、`strings -el … \| grep -c NOTIMPL-VISEFFECT` = **0**（改动**尚未**进桥的机器证）；重建后应 ≥1 |
| `NOINFO-4` | `Release` 配置下的全量跑 | 本趟全部用**缺省 Debug**（与主控给的 `562` 基线同档）⇒ Release 未取数；`verify-all.sh:465-466` 用 `-c $SELFBUILT_CONFIG` 跑，属另一条链 |
| 边界① | **不是**"实现效果渲染" | 效果**仍然不渲染**（本件只说"看得见"）。真正的效果渲染＝R4 长线 |
| 边界② | 台账**不含**效果的资源类型名 | 三个必备字段＝命令号＋视觉句柄＋效果句柄（主控裁定）。想加 `resKind` 可仿 `MilVisualTransformDiag.DescribeRaw` |
| 边界③ | 触顶后的**应用侧**读数 | 逐条上限 32 是**每通道**实例计数（非进程静态）；多通道时会各记各的。应用侧触顶未取数（同 `NOINFO-2` 条件） |
| 未覆盖 | `0x1e/0x1f/0x20/0x23` 等其他"写了没人读"的字段 | **本件只做 `0x1d`**。`grep` 显示 `CacheMode`/`Clip`/`AlphaMask` 等在投影/渲染层**确有**消费者（`AlphaMask` 还是 `D-G47` 一带刚补的），故未列入；这是**本件范围**的边界，不是"已验证全绿" |

**写域自查（全程未碰）**：`build/shims/**`、`build/PresentationCore.Linux/**`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、`docs/CURRENT-STATE.md`、`handoff.md`、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`、`build/MilBridge/tools/defect-registry-declared.tsv`、`verify-all.sh`/`integration-wave.sh`/`close-wave.sh`。
**零 `pkill -f`**（全程未用；收尾无遗留进程：本趟只跑 `dotnet test`，全部自然退出）；仓内新增**两个文件**：本报告 ＋ `tests/…/Rendering.Tests/VisualEffectIgnoredLedgerTests.cs`；修改**两个文件**：§3 表里的 ①②。

---

## §8 复算命令逐条 ＋ 内存三值 ＋ 本报告 sha16

**复算（逐条照抄即可）**
```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd "$R"; export PATH="$HOME/.dotnet:$PATH"
# ① 判据（判据①）：
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 120 -- timeout 110 \
  dotnet test tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj \
  --nologo -v q --filter "FullyQualifiedName~VisualEffectIgnoredLedgerTests" --logger "console;verbosity=detailed"
# ② 零回归（判据②，须逐字 562）：
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 120 -- timeout 110 \
  dotnet test tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj --nologo -v q
# ③ 反极性（撤件必红 ∧ 还原必绿，含 touch 逼重建）：
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 120 -- timeout 115 bash $HOME/w70d/polarity2.sh
# ④ 静态面：
grep -rn "NoteVisualEffectIgnored" src/ | head   # 定义 1 处（MilChannel.cs:176）+ 调用 1 处（MilCommandDispatcher.cs:191）
grep -rn "\.Effect =" src/WpfGfx.Linux --include=*.cs | grep -v "Border.Effect"   # 唯一写点：MilCommandDispatcher.cs:178
grep -c "Visual\.Effect\|\.Effect\b" src/WpfGfx.Linux/Rendering/*.cs | awk -F: '{s+=$2} END{print "渲染层读视觉级 Effect 合计="s}'   # = 0
grep -c Effect src/WpfGfx.Linux/Resources/VisualProjection.cs   # 投影层 = 0（**裸图案**这里也是 0）
    # ⚠ 图案口径：渲染层那一行**必须**用 `Visual\.Effect\|\.Effect\b`；裸 `Effect` 会命中 `SkiaEffect`/`SKPathEffect`（那是另一条路）
strings -el build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so | grep -c NOTIMPL-VISEFFECT   # 重建前 = 0
```

**内存三值**（用户明确要求控内存）
```
free -m（开工时）: total 7923 / used 5444 / available 2142
槽内实测 avail : 2731MB（01/02）· 2552MB（03/04）· 2339MB（05）· 2529MB（重跑）· 1946MB（Commands 那趟）  全部 ≥ min-avail 1500
槽纪律           : 全部 dotnet 均包进 `~/heavy-slot.sh --min-avail 1500 --max-hold 120 -- timeout 110 …`；零 MAXHOLD_KILL；零 low-memory 作废趟
```

**本报告 sha16**：见**本文件最后一行**。口径（自指可闭合的唯一写法）：值 = **除最后一行外全文**的 sha256 前 16 位；复算
```bash
head -n -1 build/MilBridge/W70D-report.md | sha256sum | cut -c1-16
```
（⚠️ 直接 `sha256sum` 整文件会得到**另一个**值 —— 因为最后那一行装着这个值本身。本仓其他报告用"正文定稿时的旧值"，本次改用**可复算的闭式口径**，两者不要混读。）

---

## 结语（大白话，6 行）

1. 视觉级效果（`0x1d`）本移植**收得下**，但效果在**投影那一跳就丢了**（契约里连字段都没有），以前**一声不响**。
2. 现在每设一次就记一行具名台账：命令号 `0x1d` ＋ 哪个视觉 ＋ 哪个效果句柄，进 `mil.log`（和 D-G58 那本账同一处）。
3. **只做可见化**：渲染行为一个字没动，`未画种类` 仍是 0，`Commands.Tests` 仍是 `562/0`。
4. 我**没走**"记进 `未画种类`"那条路 —— 它会把 `WpfTextDemo` 一条**冻死的**验收判据从绿顶到红，这条链已写进 §2（第 4 点标了"推导、未跑应用"）。
5. 反极性按规矩做了：**撤掉那一行 ⇒ 用例当场红（Expected 1 / Actual 0）**，还原 ⇒ 回绿（含 DLL sha16 作重建证）。
6. 顺带抓到一条**仪表自伤**：`cp -p` 还原会因 mtime 旧而**不重建**，害我一度读到假红 —— 已写进 §6.1，后来的腿都加了 `touch`。

本报告 sha16（除本行外全文，复算见 §8）= 1b0d9a8d4723f7be
