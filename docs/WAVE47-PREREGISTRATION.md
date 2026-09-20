# 波 `#47` —— 修 **`D-G55`**：`SetCapture/ReleaseCapture` 不派发 `WM_CAPTURECHANGED` ⇒ `Mouse.Captured` 恒不复位（"点过一次之后点不动"）

> **性质**：产品波，只动 **`win32shim`**（`src/WpfGfx.Linux.Native/src/{win32_core.c,win32_internal.h}`）。
> **用户报告**："hc 能跑，但界面里点击没反应，包括输入框和列表项。"

## §1 判定点与修法
- 上游：`MouseDevice.cs:386-394` 清捕获状态只认 `RawMouseAction.CancelCapture`；唯一来源 = `HwndMouseInputProvider` 的 `WM_CAPTURECHANGED`（`:719-735`）。
- 我方：`win32_core.c` 的 `SetCapture`/`ReleaseCapture` 只清软状态、**不派发任何消息**（`WM_CAPTURECHANGED` 全仓 0 命中）。
- 修法：`SetCapture` 易主时向失去捕获者派发（`lParam`=新捕获窗口）；`ReleaseCapture` 向旧窗口派发（`lParam=0`）；`win32_internal.h` 加 `0x0215`。

## §2 判据（**落地前写死**）
- **仓内**（`samples/WpfFeatureProbe` 第 ⑬ 块 `clickprobe`＋`$HOME/w47b-click.sh`）：**连做**序列下
  `tb.focus ≥ 1`、`tb.text` 增长、`combo.opened ≥ 1`、`combo.selection=1`、`combo.closed ≥ 1`、`lst.selection` 出现。
  **修前**：`tb.focus=0`、`combo.opened=0`（红）。**反极性**：`EVT … captured=<控件>` 必须在抬起后不再钉住。
- **仓外 hc**：`NativeTextBoxDemo`（idx 9）点 TextBox ⇒ 焦点；**随后**点别处（如导航或列表项）仍要有反应（修前被吞）。
- **九位预测**：只有 `win32shim` 必变；`pc`/`pf` 可能因整波重建变字节（非确定构建）；`bridge` 源未动、AOT 可复现（预期不变）。
- **反证条件**：若连做序列仍 `captured` 钉住 ⇒ 修法无效，停并撤回结论。

## §3 收尾（同 `#46` 流程）
整波重建 → 重取臂 → 重钉 → 闸门 ×2 → 冻前 `verify-all`（声明类红可接受）→ 重冻 `#47` → 冻后 ×2。

## §4 前置处置与现场（主控/车道 W48A·W48C 读数）
- **声明表**：`D-G55` 入册 ⇒ `DEFREG=PASS declared=91 route_ids=91`（原先 `FAIL undeclared-id-in-route`；该牙非声明类 ⇒ 不处置会让冻前 `verify-all` 多一红并让冻结器 `:283` 崩）。
- **副本同步（W1 同族）**：`libwpfwin32.so` 4 份落后件已同步到新权威 `abf6879c027c5e73` ⇒ 去重 **1 个值 / 计数 5**；桥副本 **4/4 `e3ea092010734f44`**（本波桥源未动）。
- **九位现状**：只有 `win32shim e700c383ec1ecdc8 → abf6879c027c5e73` 变；其余八位 = `#46` 冻结值。
- **两条新欠账**：`R-CSRC`（shim C 源不在 `fp_inputs()` 覆盖面 ⇒ 改它不动 `inputs_fp`）、`R-GATE`（登记的 `clickprobe:!22D3EE` 是负向式 ⇒ 门禁不证明"点击有反应"）⇒ 均写入 `KNOWN-DEFECTS.md`。
- **记录文件待补两格（只有主控能填）**：① `w47-record.txt` 里 `# ARM-LOG-SHA arm=tline sha16=…` 必须**重取臂之后**按现场改写（否则 `column-floor-check.sh` 第⑤档 MISMATCH ⇒ 冻结器末尾两断言崩）；② `BANNER` 的 `run_dir`/门禁行文件按闸门实跑结果填。

## §5 车道 W47A 的 hc 侧取证（口径更正 + 两条新缺陷）
- ⚠️ **它的"五类点击全通"是在"指针中途离开窗口"的口径下取的**（点一个目标前先移动到它）⇒ **正好释放捕获** ⇒ **看不见 `D-G55`**（与 W47B 自报的第一条自伤同族）。⇒ 该结论**不推翻 `D-G55`**；hc 上的决定性读数由**连做**口径给（车道 W48B）。
- **`D-G56`（新，我方 applier 自伤，**比"点不动"更严重**）**：类属性块与类声明之间被插桩横幅打断（`DependencyObject.Linux.cs:51-52 → :53-63 横幅 → :614 class`；`FrameworkElement.Linux.cs:100-102 → :110`）⇒ `[NS] ATTRCOUNT DependencyObject=0` ⇒ `NameScope` 挂不上 ⇒ 带 `Storyboard.TargetName` 的页面一加载**未处理异常 + core dump**。修法＝锚上移＋防复发判据（`attrCount≥2`），动 `windowsbase`/`pf` ⇒ **排进 `#48`**。
- **`D-G57`（新）**：页签标题/「实用示例」按钮**文字零墨**（`colors=1, stddev=0%` vs 导航项 `69/10.47%`），但**可命中** ⇒ 用户观感"导航是死的"；根因 `NOINFO` ⇒ 与 `D-G56` 同波排。
- **顺带推翻两条旧推断**（如实记）：① `xstate_to_mk` 无条件置位 MK ⇒ `ButtonState` 恒 Pressed **不成立**（上游按**消息身份**定 `ButtonState`；实测抬起那刻 `state=Released`）；② "导航列表滚不到第 19 项"是**仪器预算假象**（`[STATE]` 硬编码 90 次后静默停表 ⇒ 已由 W47A 改成 `HC_DUMP_MAX`）。
- **我的旧仪器也是假信号**（W47A 核出）：`[POLL]` 的 `_hcinLastOpen` 被 **36 个 ComboBox 共用** ⇒ 5 s 打 1294 条"open 变了"是**仪器假象**（算术互证 ≈1250），不是产品在闪。

## §6 W48B 的 hc 两极化（**用户现象已被完整解释**）
同一 hc app、只换 shim：修前第一次点导航就让**导航 ListBox 捕获且永不释放** ⇒ 导航以外的点击全被吞（`TextBox focus=0`、`DropDownOpened=0`、页面 ListBox `SelectionChanged=0`）；
修后 `cap=none` 为主、TextBox 聚焦并打字 `len 4→7`、下拉打开（弹窗 `0x200008 413x274`）并**点项选中**（`sel=1/9`）、页面 ListBox `sel=7/20`。
**排除"点太快"**（按压 600 ms 无效）＋**二进制级复核**（修前 `SetCapture/ReleaseCapture` 无 `$0x215`，修后有 `call wpf_dispatch_to_window@plt`）⇒ `D-G55` 是**唯一**原因。

## §7 W48A 的三条发现（入册）
1. **并发撞车**（两个 `retake-arms` 同时写同一 `$HOME/w48a/arms/*.log`）：脚本自印的 arm sha 表在并跑下**不可钉**——最后一个写者退出前就会打印（机器证据：文件 mtime `23:11:39/23:11:48` **晚于**该链自印的 `=== done 23:11:38 ===`）。**稳态值以静默后复读为准**（W48A 在 `23:12:08`/`23:12:33` 两遍逐位相同）。
   ⇒ **纪律**：同一目录同一时刻只允许一个重活；`retake-arms-w23.sh` 的"报 sha"步骤应改到**最后一个写者之后**（或加 `flock`）。
2. **推翻 runbook §3 的机制**（结论仍命中）：本波整波重建后 **`pc` 逐位未变**（`043eff4b1d8ecd7d`，重建可复现），**而 `tline` 仍变** —— 逐行 diff 只有 **4 处、全是运行相关字段**：耗时、**上一趟自产 artifact（`gen/t2d-width-diff.txt`）的 sha16（自指）**、带日期戳的输出文件名、`mktemp` 路径；第 6 行 `[applocal] PresentationCore.dll：已与权威一致（043eff4b1d8ecd7d）` **两代相同**。
   ⇒ **`tline.log` 程序上不可复算**，"tline 变了"**不是产品位移信号**（建议下一波把这 4 类字段排除出证据指纹面，或改成"只比对非运行字段"）。
3. **债复发（W1 同族、这次是 shim 那一半）**：`integration-wave.sh` **不覆盖** `libwpfwin32.so` 的 app-local 副本（只有 `close-wave.sh [2/6]` 管）⇒ 走"直调整波"路线**每波必然复发**。
   ⚠️ **状态更正（主控 23:2x 现场复读）**：现树 `libwpfwin32.so` **5/5 全等 `abf6879c027c5e73`**、`wpfgfx_cor3.so` **4/4 全等 `e3ea092010734f44`** ⇒ W48A 报的"4 份停在 `e700c383`"**此刻不复现**（时序差：它读的时刻早于我 22:5x 的手工同步，或读到的是 `integration-wave` 3.6 步的中间态）。**两个时刻都留档**，不作断言。

## §8 ✅ 冻结完成（`#47`）
```
python3 /home/links-dev/w21-verify/w27-freeze.py $HOME/w48a/06-verify-all-pre.log $HOME/w48a/gate-rows.txt '#47'
⇒ 基线已重冻为 #47；整份 sha16 = 9b9e3cb7bcb8280b（553,550 B）
   BASELINESHA=PASS live=9b9e3cb7bcb8280b ｜ BASELINEGEN=PASS decl_gen=#47 file_newest_gen=#47
   位移 = ['win32shim']（**唯一**；`pc`/`pf` 重编但**逐位未变**——本波整波重建可复现，与 W48A §4.2 一致）
   ARMLOG_SHA=PASS required=5 pass=5 ｜ COLUMN_FLOOR=PASS selfreport=PASS reg=00a75a87ec5ed0d6
   inputs_fp = 8a8661b926e47489b9840736992209d3977ab10429e42dcdcbe9df1a5a0ddeaf
   ⚠️ **更正（车道 W49A 核出）**：上面这行原是照抄冻结器输出的**通用文案**，与盘上日志不符 ——
   冻前那趟（`$HOME/w48a/06-verify-all-pre.log`，`a09909bb3a76224f`）里 **`BASELINESHA=PASS`／`ARMLOG_SHA=PASS` 各 1 命中**，
   真正冻前红→冻后绿的是 **`COLUMN_FLOOR_ARMLOG`**（`bad= tline` → `bad=无`）⇒ 与 runbook §12 纠正②一致。
```
- 冻前 `verify-all`（`$HOME/w48a/06-verify-all-pre.log` `a09909bb3a76224f`）= **`24 ✅ / 1 ❌`**，唯一失败 `COLUMN-FLOOR`（声明类）✓
- 门禁行文件 `$HOME/w48a/gate-rows.txt` = **6 行 / 6 PASS**（`f52631e520251bd3`，`config` 含 `win32shim:abf6879c027c5e73`）
- 重钉：`known-red.json 1fa4c4540fe1b69f(402) → 00a75a87ec5ed0d6(406)`；`REPIN_GENERATION=PASS`；`caliber 改动 0`
- 记录 `$HOME/w21-verify/w47-record.txt` → `cef2dddc41cba8e3`（补了 `BANNER` 的 run_dir 与门禁显示号两格）
- **待**：冻后 `verify-all` ×2（车道 W49A）

## §9 `#47` 冻后两趟的如实记账（车道 W49A）
| 趟 | rc | real | 步骤 | 用例 | 日志 sha16 | 有效？ |
|---|---|---|---|---|---|---|
| run1 | **0** | 880 s | **25 ✅ / 0 ❌** | 871 通过 / 2 跳过 | `eba8fb22d1d8dda8` | ✅ **有效**（六项牙全 PASS：`BASELINESHA`/`BASELINEGEN`/`ARMLOG_SHA`/`VERIFYALL_SELF`/`COLUMN_FLOOR_ARMLOG`/`COLUMN_FLOOR`） |
| run2 | 1 | 1206 s | 25 ✅ / 1 ❌（**虚高**） | 769 / 23 | `a7139fdc6d87fb0d` | ❌ **不可归因**（两条独立事故） |

**事故①（工具缺陷，已登记 `D-G59`）**：run2 的 `[0]` 步选中了**别人遗留的临时 X 显示 `:66`**（run1 是 `:97`），该显示在 `[2]` 前已死 ⇒ `XOpenDisplay` NULL ⇒ **47 例 X 用例静默变跳过**（`SKIP_GUARD=FAIL`，该牙**正确**红了）＋ 端到端硬红 `ManagedLayer.Tests`。根因：`verify-all.sh:366-373` 用 `pgrep -a Xvfb | sort -u` 取**字符串序最小**（`66` < `97`）且**选定后整趟不复核**。
**事故②（主控纪律违规，如实记）**：run2 执行期间（23:53:14）**我**改了 `verify-all.sh`（`gen=#47→#48`）⇒ 该趟日志自相矛盾（`:76 BASELINEGEN=#47` vs `:93 VERIFYALL_SELF gen=#48`）、步 `[6]` 被执行两次、"通过 25"是重复计数、stderr 有 `行 517: 帧红=0: 未找到命令`（bash 边读边改的指纹）。
⇒ **纪律**：**任何判定输入（`verify-all.sh`、`known-red.json`、`arm-logs/**`、`*.tsv`）在验证运行期间一律不许改**；本波我违了，读数按"作废"处理。
**⇒ `#47` 的冻后只有 1 趟有效**；第 2 趟因 `#48` 已改九位（`windowsbase`/`pf`）**无法在同一棵树上重取** ⇒ 登记为**与"冻后 ×2"规则的偏离**（不粉饰、不重算）。
