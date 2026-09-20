# 波 `#48` —— 修 **`D-G56`**（我方 applier 把类属性块与类声明打断 ⇒ `NameScope` 挂不上 ⇒ BAML 页加载即 abort）；`D-G57`（页签/按钮文字零墨）**本波只取证、未修**

> **性质**：产品波。改动落在 **`windowsbase`**（`DependencyObject` 生成件）与 **`pf`**（`FrameworkElement` 生成件）⇒ 由两个 applier 的**插入锚**决定。
> ⚠️ **位移口径勘误（车道 W50B 核出）**：W48D 的"单件重建"只动了 2 位，但**整波重建后实测 3 位**（`windowsbase`/`pc`/`pf`）——
> `windowsbase` 元数据变 ⇒ 被引件字节进 Roslyn 输入哈希 ⇒ `pc` ⇒ `pf`（机制由 `build/artifact-src-fp.py --check` 的判据原文坐实）。
> 本波**只修 `D-G56`**；`D-G57`（文字零墨）根因 `NOINFO` ⇒ **未修、延后**（下面 §2 第 5 条已如此约定，但 DECL 文案一度写成"另修"，已改）。
> **来源**：车道 W47A 的 hc 取证（`build/MilBridge/W47A-report.md` `68bfb1301c67d485`）＋ `KNOWN-DEFECTS.md` 的 `D-G56`/`D-G57`。

## §1 判定点（代码级，已闭合）
- 插桩横幅被插在**类属性块与类声明之间**，属性因此挂到插桩类上：
  - `build/WindowsBase.Linux/DependencyObject.Linux.cs:51-52`（含 `[NameScopeProperty("NameScope", typeof(NameScope))]`）→ `:53-63` 横幅 → `:64 internal static class WpfLinuxDpValueTrace` → `:614 public class DependencyObject`；
    规则 `src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py:832`（锚 `:628` = 类声明行，**插在锚行之前**）。
  - 同族第二例：`build/PresentationFramework.Linux/FrameworkElement.Linux.cs:100-102`（`StyleTypedProperty`/`XmlLangProperty`/`UsableDuringInitialization`）← `patch-presentationframework-mirror-trace.py:283`（锚 `:252`）。
- 证据：`[NS] ATTRCOUNT DependencyObject=0`（源里 2 条属性全跑到插桩类身上）；`scope=null upHits=none FindName(PathDemo)=null`；而 `dpField=True dpOwner=NameScope attachableMember=NameScope`（链其余环节都好）；名字**确实进了 BAML**（`GeometryAnimationDemo.g.cs:64/:103`）。

## §2 判据（**落地前写死**）
1. 生成件里 `DependencyObject` 的属性**紧贴类声明**（给 `sed -n` 原文行）；
2. hc 应用（私有 app 目录＋私有 display）：`[NS] ATTRCOUNT DependencyObject ≥ 2`、`[NS] WINDOW … scope=` **非 null**、`FindName(ControlMain)` **非 null**；
3. **反极性**：点「工具」页签 → 点第 2 项 `MorphingAnimation` ⇒ **进程活着**（修前：`Unhandled exception … 'PathDemo' name cannot be found in the name scope of …` ⇒ core dump）；
4. **防复发**：applier 自带断言「属性行与类声明之间不得出现插入横幅」＋`attrCount(DependencyObject) ≥ 2`，且**能两极化证明它会红**；
5. `D-G57`（页签/按钮文字零墨）：根因 `NOINFO` ⇒ 本波**未修（延后）**（先取证，定不出根因就留待下一波）。

## §3 九位与 inputs_fp 预测
- 预期变：`windowsbase`（必）、`pf`（必）；`pc` 可能（引用了被改的生成件 ⇒ 重编即变字节）。
- `bridge`：源未动、AOT 可复现（`#47` 已证"重发前后逐位相同"）⇒ **预期不变**。
- `inputs_fp`：**必变** —— ① 两个 applier（`patch-*.py`）在覆盖面内；② 重钉 `known-red.json`（也在覆盖面内）。
- 反证条件：修后 `attrCount` 仍 0、或 `[NS] scope` 仍 null、或该页仍 abort ⇒ 修法无效，停并撤回结论。

## §4 收尾（同 `#46`/`#47` 流程）
整波重建 → 重取臂 → 重钉 → 闸门 ×2 → 冻前 `verify-all`（声明类红可接受）→ 重冻 `#48` → 冻后 ×2。
**同趟件**：`verify-all.sh` 的 `gen=#48`（插在 `#47` 之上）＋口径句；冻结器 `GENS['#48']`；本文件标题。

## §5 W50A 中途读数（步 1–2）与两条新登记
- 步 1 `publish-milbridge.sh` **rc=0**（10 s）⇒ 产物 `e3ea092010734f44` **逐位未变**；步 2 `WAVE_OWNER=w50a integration-wave.sh` **rc=0**（129 s）⇒ `失败步骤 0`、`APPLIER_AUDIT appliers=25 ok=86 miss=0 red=0`。
- **生成件复核 ✅**：`DependencyObject.Linux.cs = 2985c671c57c7775`、`FrameworkElement.Linux.cs = 3af06981155e89aa`（**与 W48D 逐位相同**）⇒ **新锚确实被整波调用**（排掉"applier 注册了但没生效"那一族风险）；独立读件确认 `:613 [NameScopeProperty]` 紧贴 `:614 public class DependencyObject`、PF `:303-305` 紧贴 `:306`。
- **九位三位变**：`windowsbase 84a2826c→79740e9b`、`pc 043eff4b→9465f9dc`、`pf bd73f9e2→1011da63`；其余六位未变 ⇒ 与 `allow_changed={'windowsbase','pc','pf'}` **逐字吻合**。机制由 `build/artifact-src-fp.py --check` 的判据原文坐实（被引件字节进 Roslyn 输入哈希 ⇒ 级联）。
- **新登记 `D-G60`**（`ARTIFACT_SRC_FP` 身份记录**出生即陈旧**：`integration-wave.sh` 段 `3.5`（`:456-461` 写记录）排在段 `3.6`（`:463-475` 刷新 app-local）之前 ⇒ 记录被自己后面的段改脏；mtime 差 9 s；20 条 peer 只 1 条 CHANGED）⇒ 本波**不改**（判定输入），下一波按"挪段序或重跑 `--write`"处置。
- **`D-G59` 的更硬证据**：劫持的 `:66` 来自某车道的私有 Xvfb（`$HOME/w48d/run.sh:12` 默认 `:64`；其 xvfb.log mtime 23:48:21/23:48:53，w49a 那趟起于 23:48:55，差 2 s；`w48d-run/AFTER/app.log:808` 留着 `XIO … on X server ":66"`）；`verify-all.sh:370-371` 的 `sort -u` 字符串序让低号胜。

## §6 声明与实际的偏差（如实记，车道 W50B 核出）
1. **位移口径**：`#48` 实际动 **3 位**（`windowsbase`/`pc`/`pf`），不是 2 位 ⇒ `GENS['#48']['allow_changed']` 含 `pc` **是对的**；本文件与 `verify-all.sh` 的 DECL 文案已按 3 位改。
2. **`D-G57` 本波未修**（`grep` 全仓 W48\* 报告 0 命中），而 DECL 与预登记标题曾写"另修 `D-G57`" ⇒ **声明超出实际改动**，已改文案并登记为延后项。

## §7 主控自纠两处（W50B 核出后的处置）
1. **`verify-all.sh` 的 DECL/口径句**：原写"另修 `D-G57`"＋"只动两位" ⇒ 已改为**"整波后实测动三位 `windowsbase`/`pc`/`pf`"**＋**"`D-G57` 本波只取证、未修"**；`vfile_sha16 50e8fb979a979921 → 5ee3ad984ee7412d`（`VERIFYALL_SELF=PASS gen=#48` 复跑确认）。记录 `w48-record.txt` 里引用的旧 sha 已同步。
2. **预登记标题**同样去掉"＋ `D-G57`"的完成式表述（改为"本波只取证、未修"）。
> 教训（已进 runbook §14）：`gen=` 行与标题里列出的"本波修了什么"**必须与落地件逐条对得上**；单件重建那一刻的位移**不等于**整波后的位移。

## §8 ✅ 冻后两趟（`#48` 完全闭合，车道 W51A `24e562b723757b52`）
| 趟 | rc | 步骤 | 用例 | 耗时 | 日志 sha16 |
|---|---|---|---|---|---|
| run1 | **0** | **25 ✅ / 0 ❌**（失败步名**空**） | 871 / 2 | 846 s | `75b2dcd65471d79e` |
| run2 | **0** | **25 ✅ / 0 ❌**（失败步名**空**） | 871 / 2 | 847 s | `665b7b0766959095` |

- `COLUMN_FLOOR=PASS … reg=25c21ca0f33208ae base=540725342059b820`（两趟逐字相同）｜`COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无`｜`ARMLOG_SHA=PASS 5/5`｜`BASELINESHA/BASELINEGEN/VERIFYALL_SELF` 全 PASS。
- `[0]` 显示号 **`:97`**（两趟），`X_STATE=available`、`SKIP_GUARD=PASS`（零静默跳过）⇒ **本机未触发 `D-G59`**。
- **红→绿的根因定位到行**：冻结块把 `ACCEPTANCE-BASELINE.md:62` 的 `# ARM-LOG-SHA arm=tline` 从 `57d752a3981a9b91` 重钉到 **`960e28f59ee974e5`**（与 `known-red.json` 一致）；`ACCEPTANCE-BASELINE.md:916` 是旧的 `#47` 值 = 冻前 `bad= tline` 的来源 ⇒ 与 §7/runbook §12-2 一致。
- **两趟非逐字相同的完整归因**：run1 窗口内**我**改了 `KNOWN-DEFECTS.md`/`handoff.md` ＋ 重生成声明表（第 `[10]` 步的 route/声明件）⇒ `declared 96→97`（两趟都 PASS、两版各自自洽）⇒ 已作为**第二处纪律事故**入册（见 `KNOWN-DEFECTS.md`）。
- **射程边界（车道自陈）**：本报告只证"冻结件上两趟全绿且可归因"，**不证任何牙有判别力**（未跑反极性/回退）。
