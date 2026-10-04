# W21D —— `#21` 的 **P4**：只读盘点，产出「下一波可直接执行」的条目表

```
lane=W21D            时间=2026-09-16 18:22 → 18:5x +0800
loadavg=0.24 0.15 0.06（开工）        mem_available=3737212 kB
kernel=6.8.0-138-generic              nproc=3
冻结基线=#19   权威=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md 表头 f5d8a6f1cdf49635
本波预登记=docs/WAVE21-PREREGISTRATION.md 9d1e2dddda5b24e8
写域=build/MilBridge/W21D-report.md（本文件，唯一写入）
硬约束=纯静态阅读 + sha256sum + python3 分析；**未跑任何 dotnet 命令**
```

---

## §0 一句话结论

**盘了 12 个条目（六列到齐）+ 2 条本报告新增的前置/延伸（`F′` 计数器普查、`§3.1` 最小接线方案），外加 `§6` 的 4 条文档更正。**
最重要的三条：

1. **「PC 契约层」在冻树上没有任何自动判据** —— `#19` 的实质（严格档 indent 接线）的**全部红/绿证据只活在报告文字里**。`verify-all.sh` 第 10 步跑的门禁 `ARMS=(tline tab-oracle-zero tab-oracle-anchor tab-oracle-rtl textlineproto)`（`build/MilBridge/tools/tline-gate.sh:91`）**不含 `PcLineOracle`**，而那五支臂**全部直调 `HbTextLineFactory.FormatParagraph`**、根本不经 PC 的 `TextFormatter`。⇒ 它下一次退化**不会有任何东西变红**。
   **补一层更准的说法（主控在本次盘点期间独立查到、我照录）**：三支 tab 臂的宿主 `CoverageProbe/Program.cs` **连 `lineStartOffsetsDip`/`.Start` 一个引用都没有**（预登记 `§10.3` 第 1 项逐字）⇒ **语料里一直躺着 615 个真值，而门禁从来没看过它**；**"在门的射程内、只是不看那个字段"比"不在门里"更准确**（这一格是**我的缺口**，见 §6.5）。
   **处置已被主控拍定**（预登记 `§10.3` 第 2 项）：先落判据 ⇒ 接线按 **本报告的"最小接线方案"**（§3.1）在波尾评估 ⇒ 若不接线，**必须在 `CURRENT-STATE.md` 写明"该判据当前不在冻树回路内"**。桥件 `build/MilBridge/tools/pc-line-step.sh`（`3f8d26ab077d2ec1`）已于 `18:26:33` 写出，**尚未接进 `verify-all.sh`**。
2. **`D-F2` 的「第一步」比登记里写的更值钱**：缺出口的计数器不是 1 个而是**至少 3 个**（`SegmentFaceUnresolved` / `RunFaceSlotMissing` / `ScanCapped`），`SummaryFragment()`（`shim:1344-1379`）里一个都没有；其中 `ScanCapped` 的注释还**自称**「诊断行报 `capped=`」，而 **`capped=` 全仓 0 个打印点**（`grep -rn 'capped=' build/ src/ samples/ tests/ --include=*.cs --include=*.py --include=*.sh` 的**全部**命中 = 4 行：`shim:1067`/`:1146`/`:1271` 三行**注释** + `check-applocal-sync.sh:164` 里那个 `INVIS_CAPPED` 变量的**赋值行**（不是打印行）⇒ **真 0**）。
3. **三处文档陈述与现场不符**（见 §6，逐条带原始证据）—— 两处是**引用漂移**（行号过期），一处的**自述能力是假的**。

**建议下一波先做三件**（理由见 §5）：**① `D-F2` 第一步（3 个计数器出口，+4 行、零语义）② `D-A2` 间接依赖副本（最安静的盲区，+3 行表项）③ `D-R3`(iii) 判据① 的修前对照（唯一一条"判据本身没被验过"）**。

---

## §1 本次盘点的边界（先说清"我没测什么"）

| 事项 | 状态 |
|---|---|
| 纯静态阅读（`read`/`grep`/`sha256sum`/`python3`） | ✅ 全部结论的出处都是**盘上文件 + 行号 + 原文** |
| `dotnet build` / `dotnet run` / `dotnet restore` / `dotnet test` / `dotnet msbuild` | ❌ **一次都没跑**（预登记 §0 的硬约束：`nproc=3`，`dotnet` 全让给 P1 车道 W21A） |
| 任何仓库既有文件的修改 | ❌ 零。本报告是本次唯一写入 |
| `pkill -f` | ❌ 未使用 |
| 需要**运行期读数**才能定的格子（如 `D-T5` 异常是否传到应用层） | **如实标为 `未测`**，不推测（纪律 22） |
| 「红多少」这类量 | 只引用**已在册的实测数**并注明出处；**我没有新取任何读数** ⇒ 凡我引用的量都写清是"谁的、哪一版、哪个 artifact" |

---

## §2 `verify-all.sh` 的现状：**10 步**，逐步在跑什么

权威件 `verify-all.sh` = **`a68823631e8f8919`**（9,847 B、mtime `2026-09-15 16:44:49`）。
盘上冻结日志 `$HOME/wfp-runs/w19-pre/verify-all-19.out`（1,254 B、mtime `2026-09-16 15:47`）逐字给出 **`步骤通过 10 ❌ 失败 0` / `用例通过 871 跳过 2` / `结论：✅ 全部通过`**。

| # | 段 | `run_step` 的实例 | 实测（`#19` 冻结日志） |
|---|---|---|---|
| — | `[0] Xvfb` | 不是 `run_step`（直接内联，含 `xdpyinfo` 连通性判据，`verify-all.sh:116`） | `✅ 复用已运行的 Xvfb（实测 display :97，注意不是 :99）` |
| 1 | `[1]` 构建 | `主工程 WpfGfx.Linux`（`:151`） | ✅（无 `Total:` 行 ⇒ 不计用例） |
| 2 | `[1]` 构建 | `wpf-linux.sln`（`:152`） | ✅ |
| 3 | `[2]` 测试 | `Commands.Tests`（`:159`） | ✅ 通过 **562** 跳过 0 合计 562 |
| 4 | `[2]` 测试 | `Rendering.Tests`（`:160`） | ✅ 通过 **162** 跳过 **2** 合计 164 |
| 5 | `[2]` 测试 | `Windowing.Tests`（`:161`） | ✅ 通过 **44** |
| 6 | `[2]` 测试 | `HelloMil.Tests`（`:162`） | ✅ 通过 **19** |
| 7 | `[2]` 测试 | `ManagedLayer.Tests`（`:165`） | ✅ 通过 **76** |
| 8 | `[2]` 测试 | `Presentation.Tests`（`:167`） | ✅ 通过 **8** |
| 9 | `[3]` 线格校验 | `verify-cmd-layout.py`（`:174`） | ✅（无 `Total:` ⇒ 不计用例） |
| 10 | `[4]` 在册红门禁 | `tline-gate（五臂）`（`:193`；`ARM_LOGS=build/MilBridge/arm-logs`） | ✅ |

**871 的对账（我按冻结日志逐个相加，纪律 25 的"计数要有出处"）**：`562 + 162 + 44 + 19 + 76 + 8 = 871` ✓；**2** 跳过全部来自 `Rendering.Tests`。

**第 10 步在跑什么（`tline-gate.sh` `b37a5c9f55ae71a4`）**：五支臂，`ARMS=(tline tab-oracle-zero tab-oracle-anchor tab-oracle-rtl textlineproto)`（`:91`），日志目录 `build/MilBridge/arm-logs/`（**硬链接**，`links=2` 逐条实测）。
- **世代绑定只绑三项**：`GEN_KEYS = ("instr_run_sh", "instr_program_cs", "instr_shim")`（`tline-gate.sh:234`）⇒ `build/MilBridge/run.sh` + `HbTextLineParity/Program.cs` + `build/shims/PresentationCore.HbTextLine.cs`。
- **不绑**：`CoverageProbe/Program.cs`（三支 tab 臂的**真正仪器**）、`PcLineOracle/Program.cs`、`StrictTierProbe`、`known-red.txt`、任何 oracle JSON。
- 门禁对**范围外**的 `ContractProbe` 段做了**诚实披露**（`:433`：`【范围外·诚实披露】… **未登记在本门禁射程**，本门禁不据此判绿也不据此判红`）—— 范式正确，但它**只披露不判**。

---

## §3 判据接线缺口：**哪些已存在的判据在 `verify-all` 之外**

判据分三层落地：`verify-all.sh`（冻树，跑 10 步）、`close-wave.sh`（波，跑 6 段）、**只在车道里跑过**（第三层，**没有任何自动入口**）。

| 判据 / 仪器 | 件（sha16） | `verify-all` | `close-wave` | 后果 |
|---|---|---|---|---|
| `tline-gate.sh`（五臂） | `b37a5c9f55ae71a4` | ✅ 第 10 步 | — | 唯一进了冻树的文本判据 |
| `check-applocal-sync.sh`（app-local 同步） | `aad23482f84bdf44` | ❌ | ✅ `[4/6]`（**非 PASS 只告警、不中止**，`close-wave.sh:159-160`） | 波内可见、**冻树不可见** |
| `check-appliers.sh`（应用器审计） | — | ❌ | ✅ `[4/6]`（非 0 **中止**，`:162-163`） | 同上 |
| `artifact-src-fp.py --check` | tool `687ff7da…` | ❌ | ✅ `[4/6]`（非 0 中止，`:156-157`） | 同上 |
| `bridge-src-fp.sh` 两侧一致 | — | ❌ | ✅ `[4/6]`（`:151-154`） | 同上 |
| **`ShimShaReader`（等号读者）** | `0ef57677afef9f6d` | ❌ | ❌ | **只在 W17C/`#19` 车道里跑过**。它抓到了 `#17` 第一趟波**静默抹掉 P1**（纪律 38 的现场）—— 而它今天不在任何自动入口里 |
| **`shim-in-artifact.sh`（T17A）** | `e2e1a42b5f0e5b45` | ❌ | ❌ | 同上（`KNOWN-DEFECTS.md` 自己写"**未接线**是主控的决定"） |
| **`PcLineOracle`（PC 契约臂，`--tier strict\|lenient`）** | 臂 `19f9e7e78e9bb5c7` | ❌ | ❌ | **`#19` 的实质件的全部红/绿证据在这里，而它不在冻树上** |
| **`MinMaxProbe`**（`D-T2`/P3 的判据臂） | `cfcf464457163280` | ❌ | ❌ | `#17` P3 的翻转结论只在报告里 |
| **`StrictTierProbe`**（W20A 的 `D-T6` 定性仪器） | `d628ce429240b37c` | ❌ | ❌ | `D-T6` 的 `ARM/DEVICE` 定性只在 `W20A-report.md` 里 |
| **`check-fp-polarity.sh`（`ARTIFACT-SRC-FP` 两极化）** | `f91d12bed2494889` | ❌ | ❌ | 它自称是"`#15` RUNBOOK §2.1 的机械化版本" ⇒ **人工步骤被机械化了，但机械化的产物没进任何门** |
| `check-applocal-sync.sh --selftest`（仪器自检 A–M2） | 同件 | ❌ | ❌ | 自检存在且能红，但**没人定期跑它** |
| `eval-df1-criteria.py`（判据层） | `fc808896f23390f4` | ❌ | ❌ | `L25`（空集当通过）的被修者，本身也只在车道里跑 |
| `mem-sampler.sh --selfcheck` / `seg-sampler.py` | `09e5bab7c3d246f6` / `9934771b1bff861b` | ❌ | ❌ | `D-F1c` 的内存主判据仪器 |

**⇒ 缺口的一句话形态**：**冻树（`verify-all`）只跑"应用级 + 单元测试 + 五臂门禁"；凡是"文本契约/身份/内存"这一族判据，全部只在车道里活着**。这正是 `L26`（"判据存在但没人跑"）的**第二个实例**，只不过这次不是"一条判据"，而是**一整层**。

### §3.1 最小接线方案（**不改任何既有判据的口径**）

**接哪一步**：`verify-all.sh` 的 `[4]` 段**之后**新增 `[5]` 段（步数 `10 → 11`，**必须像 `#16` 接第 10 步那样在表头记口径变化**），只放三条命令，全部是**只读读者**、全部遵守本项目的三态 `0/1/2` = `PASS/FAIL/NOINFO`：

```bash
# [5] 身份与契约读者（三条，都只读；任一 rc=2 也算失败）
run_step "shim 等号读者"   dotnet build/MilBridge/tests/ShimShaReader/... --root "$ROOT"   # rc 0=no 1=yes 2=NOINFO
run_step "FP 两极化"       bash build/check-fp-polarity.sh
run_step "PcLineOracle"    dotnet .../PcLineOracle.dll --tier strict --known-red .../known-red.txt
```

**接线前必须补的三件（缺一不可，否则接线本身会造假绿）**：
1. **`PcLineOracle` 的 `--tier strict` 腿修后 `rc` 仍是 1**（`ACCEPTANCE-BASELINE.md` §⑪②逐字：「**不许拿整腿 rc 读成「B 没修好」**，也**不许**拿「整腿绿」当目标」）⇒ **不许**直接把 `rc` 当门禁结论。必须先做成一**条**臂在门禁里（`ARMS` 加第六项），并**逐桶 + 按失配词**读（`@tab0` 族 = 已登记的表达限制；`D-T6` 族 = `ARM/DEVICE` 已定性）。
2. **世代绑定必须扩到"每臂的仪器 sha 表"**（纪律 34 的登记改进方向原文："把探针 sha（或「每臂的仪器 sha 表」）纳入 generation"）。否则接线后会重演纪律 34：**改 `PcLineOracle/Program.cs`（`19f9e7e78e9bb5c7`）不让任何东西变红，而读数整批变**。这一条是**接线的前提**，不是可选项。
3. **层级来源自证**（`ACCEPTANCE-BASELINE.md` §④ B 段：严格档接手 **270** 例 / 宽松档 **0** 例）必须**机器读**，不许只打给人看 —— 否则"严格档腿"有一天会悄悄退化成宽松档腿而全绿。

**加了以后哪一步会先红（可证伪的预测）**：
- **`tline-gate（五臂）` 会先红**，且**逐字形态**是 `arms=` 计数与登记表不一致：`known-red.json`（`3bf26e12f320dece`、`generation.id=#19`、`entries=4`）里**没有**任何 `arm: "pc-line-oracle"` 条目，而门禁的判据是「该臂存在的失败必须在册」（`:595`/`:630`）⇒ 新臂带进任何红 ⇒ `unregistered>0` ⇒ `GATE_REASON=unregistered-failure` + **`rc=1`**。**这正是接线应有的第一反应**（"新判据接进来的那一刻必须先红一次"）。
- 若第 6 条臂接上后**不红**，那说明**新臂零判别力** ⇒ 按纪律 3 停并重做臂（这是判据的敌人）。
- **`shim 等号读者` 在冻树上应恒 `rc=0`**（`#19` 实测 `SHIM_SHA=no`）；它对**波**敏感、对**冻树**不敏感 ⇒ 它买的是"**下一趟波静默抹掉某件**"时的告警（`D-R5` 的现场），**这一类红只有接线之后才会出现**。§6.3 会给出一个它今天能红的形态。

---

## §4 条目表（**六列**：① 现场锚点 ② 判据草案 ③ 反极性 ④ 是否动 `build/shims/**` = 世代价 ⑤ 阻塞项 ⑥ 价值排序）

> **"世代价"口径（我实测核过，不是转述）**：门禁绑的是**三项**（`tline-gate.sh:234`）⇒ **只有改 `build/shims/PresentationCore.HbTextLine.cs` 才付"五臂重取 + `known-red.json` 重钉"**。改 `build/shims/**` 的**其它**文件（如 `Win32ShimResolver.cs`）**不触发门禁世代失配**（`SH_SHIM` 只绑那一个文件，`tline-gate.sh:137`），但它会改 `inputs_fp`（`close-wave.sh:76` 收 `build/shims/*.cs`）与 `ARTIFACT-SRC-FP` 的逐文件行 ⇒ **必须重发/重建 + 重冻**。
> ⇒ 下表的"世代价"列写**三档**：`无`（不动 shim/产物）｜`shim-其它`（动 shim 别的文件 ⇒ 重冻，**不**重钉门禁）｜`shim-HbTextLine`（**付五臂重取 + 重钉**）。

### A. `D-T5` —— `Length ≥ 1` 的 `TextModifier` / `TextEndOfSegment` 段落整条交回 LS ⇒ `LoCreateContext`

| 列 | 内容 |
|---|---|
| **① 现场锚点** | **上游（真因的根）**：`upstream/wpf/…/textformatting/TextModifier.cs:20` `public abstract class TextModifier : TextRun` → `:25` `public sealed override CharacterBufferReference CharacterBufferReference` → `:27` `get { return new CharacterBufferReference(); }`（**默认构造 = 空 buffer**）；`TextEndOfSegment.cs:28` `ArgumentOutOfRangeException.ThrowIfNegativeOrZero(length)` ⇒ **`TextEndOfSegment.Length ≥ 1`（构造期强制）**。<br>**我方（生成物）**：`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:81` `private static string ExtractRun(TextRun run)` → `:85` `MS.Internal.CharacterBuffer buf = cbr.CharacterBuffer;` → **`:86` `if (buf == null) return null;`** ⇒ **`:145`**（`DiagBeforeReturn("CharacterBuffer 取不到…")` 后）**`:146` `return false`**（`CollectLenient` 失败）；`CollectLenient` 形参表 **`:102-103`** 只有 `out int modifierOpenIndex, out int modifierCloseIndex`（**没有 `modifierScopeEnd`**，这是 `D-T2-c` 的同一个前置）。<br>**shim 侧（它的"那一半"已按零长修法绕过）**：`shim:2825` 形参 `int modifierScopeEnd = -1, …`、`shim:2852-2853` 的半开跨度算法、`shim:3867` 的同一组形参、**`shim:3913` / `:3941` 的透传**。<br>**PC 严格档调用点**：`:565-583`（`HbTextFallback.TryFormatLine`，`#19` 已补 `indentDip`/`paragraphIndentDip`，但**没有**默认停靠位 —— 见 B 条）。 |
| **② 判据草案** | **取数位置**：必须在**新臂**里造一个"真 `TextModifier`（`Length ≥ 1`）+ 配对 `TextEndOfSegment(1)`"的 `TextSource` 子类，走 PC `TextFormatter.Create()+FormatLine`（现成仪器 = `build/MilBridge/tests/PcLineOracle/Program.cs`，`--tier strict\|lenient` 两条腿 + 层级来源自证；`StrictTierProbe` 亦可）。<br>**期望值来源**：**今天没有真机语料** —— `tests/parity/windows/modifier-scope/`（53 例）的真值只覆盖 `TextLineBreak` 的 null/非 null 与停靠位三条，且 `KNOWN-DEFECTS.md` 原登记已写「`TextModifier.Length` 不参与任何计算（本 arm 里恒为 1）」；**b34 语料 0 处 `TextEndOfSegment`**（`KNOWN-DEFECTS.md` §② 逐字）。⇒ **本条的期望值只能来自"上游语义 + 我方不得交回 LS"这条自明契约**："交回 LS 在 Linux 上 = abort"（生成物 `:88` 注释逐字：`Linux 上没有 LS ⇒ 那等于 abort`）。<br>**判据形态（可判红、不需要新真值）**：① **不交回**：该段落在**两档**下都必须交出 `TextLine`（`relaxedHandled ≥ 1` / 严格档 `Handled ≥ 1`）；② **不强杀**：进程不得出现 `EntryPointNotFoundException: LoCreateContext`；③ 交回行的 `Length` 与段落文本长度一致。 |
| **③ 反极性（现状必须红）** | **已在册的实测**（`KNOWN-DEFECTS.md` §④ 逐字）：`Length=1` 的 `TextModifier` ⇒ `relaxedFailed=1 relaxedHandled=0`、`GetTextRun` 只调 1 次、随后交回 LineServices ⇒ **`EntryPointNotFoundException: LoCreateContext`**。⇒ **红在"能否交出行"这一格，红到底（0 行）**。**纪律 21 的形态**：这个红今天**只存在于报告里**（`build/MilBridge/W17D-report.md` §9.1）—— **没有任何臂在跑它**。 |
| **④ 世代价** | **`shim-HbTextLine`（若走"改 shim"这条路）+ 一次波**；<br>**但很可能不必付** —— 见 ⑥ 的两条可行修法：**(甲) 只改生成物**（`ExtractRun` 对 `TextModifier` 特判：`run is TextModifier ⇒ 用一个合成字符顶替`）⇒ **`build/PresentationCore.Linux/**` 是生成物，只付"波 + 重冻"，不付门禁重钉**（`TextFormatterImp.Linux.cs` **不在** `GEN_KEYS` 三项里）；**(乙) 改 `build/shims/**`** 的工厂侧 ⇒ 付世代成本。 |
| **⑤ 阻塞项** | **必须先测"异常会不会传到应用层"**（`KNOWN-DEFECTS.md` 逐字把它列为"**未测（不许当已知）**"）。**若传到应用层 ⇒ 这是崩溃级产品缺陷 ⇒ 优先级立刻升到第一位**；若不传（被 PC 的 try/catch 吞掉、退化成"该段落根本没有行"）⇒ 是**静默错值**级。⇒ **本条的判据草案第 ① 步就是"先测这一步"，不许跳过**。<br>**另需**：上游 `pf`/`pc` 对 `TextEndOfSegment` 的**正常用法**会不会命中（`KNOWN-DEFECTS.md` 同处列为未测）—— 这决定"真实应用会不会撞上"，而它**只能静态枚举调用点**（可做，未做）。 |
| **⑥ 价值排序** | **第 4 位（但如果 ⑤ 的第一条测出"传到应用层"⇒ 立刻升第 1）**。<br>**为什么值钱**：① 它是**真产品缺陷**（不是仪器缺口），且**在 Linux 上表现为 abort 或错值**；② 它是 `#17` P3 的**红证为什么改用零长 modifier**的唯一原因 —— 也就是说**`#13` 起的三层透传在真 modifier 上一次都没被验证过**（`KNOWN-DEFECTS.md` 逐字：「TDT2 §2.5 那张 worked-example 表**按字面是死的**」）；③ 真实应用的 `TextSource` 会这么写。<br>**为什么不是第一**：修法面（生成物 vs shim）与真值面都有未知，成本高于 A 表前两条。 |

### B. `D-T4` —— `DefaultIncrementalTab` 未在 PC 路径携带

| 列 | 内容 |
|---|---|
| **① 现场锚点** | **PC 接线点缺参数**：`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:229-231` 的 `internal static TextLine TryFormatLine(TextSource textSource, int cpFirst, double paragraphWidth, double pixelsPerDip, bool alwaysCollapsible, double lineHeight, double indentDip = 0, double paragraphIndentDip = 0)` ⇒ **没有 `DefaultIncrementalTab`**；`:565-583` 的严格档调用点、`:596+` 的宽松档调用点**都不传**。<br>**shim 有槽、但两条入口都拿不到**：`shim:2824` `double indentDip = 0, double defaultIncrementalTab = double.NaN`（工厂）；`:2831` `double tabInterval = double.IsNaN(defaultIncrementalTab) ? 4.0 * emSize : defaultIncrementalTab;` ⇒ **NaN ⇒ 恒 `4×em`**；`shim:3852` `double defaultIncrementalTab = double.NaN`（**严格档 `TryFormatLine` 的形参表里也没有它**，形参表见 `shim:4522-4524`：只有 `indentDip`/`paragraphIndentDip`）；`:643` / `:1745` 另两处同一个 `4.0 * emSize` 兜底。<br>**上游的对照（说明它不是"我们发明的"）**：`upstream/…/TextFormatterImp.cs:467-468` 对 `paragraphProperties.DefaultIncrementalTab` 做区间校验；`upstream/…/TextParagraphProperties.cs:111` `public virtual double DefaultIncrementalTab`。<br>**真值缺口的位置**：`tests/parity/windows/layout-b34/src/LayoutOracle/TextModel.cs:167` `public override double DefaultIncrementalTab => 0;`；`tests/parity/windows/tab-anchor/analyze.py:160`/`:193-194` 按 `incrementalTabArm` 分两臂（`DefaultIncrementalTab=0` vs `=default`）。<br>**本臂"表达不出来"的登记**：`build/MilBridge/tests/PcLineOracle/known-red.txt`（`89324f1f643167e5`，17,501 B）头部逐字：「`@…@tab0` 臂 共 **136** 条 … `PC` 的宽松接线点 … **没有这个形参**」；实测该文件里 `@tab0` 字样的行数 = **137**（含 1 行说明行）。 |
| **② 判据草案** | **取数位置**：`PcLineOracle --tier strict` 腿上的 `@…@default` 与 `@…@tab0` 两族**必须分开报**（今天它们在同一个 `判定红/绿` 桶里 ⇒ 这是 `#19` E1 之所以"目标写错"的同一个病）。<br>**期望值来源**：**今天的真机 oracle 里没有这一格** —— `@tab0` 是**Windows 记宿主自己写死 0** 的行为（`LayoutOracle/TextModel.cs:167`），而 `@default` 臂记的是框架默认 `4×em`。⇒ **判据只能分两半**：<br> **(i) 今天就可达的一半（不需要重录）**：`@default` 族必须落在 `4×em` 网格上；`@tab0` 族是**已登记的表达限制**、**不计红**。这一半今天**已经绿**（`#19`：`@default` 臂零缩进对照 `52/52` 逐位不确定…实为"逐位不动"）。<br> **(ii) 需要重录的一半（本条的真正内容）**：让宿主能表达**非 0 的 `DefaultIncrementalTab`（尤其"显式 0"与"任意第三值如 `48`"）** ⇒ 判据 = 停靠网格间距 == 宿主给的值（`< 0.34 DIP` 口径用同族既有容差）。 |
| **③ 反极性（现状必须红）** | **红在 (ii) 那一半上，而且红是"构造性"的**：PC 形参表里**根本没有这个槽** ⇒ 宿主给任何值都到不了工厂 ⇒ 若造一条"`DefaultIncrementalTab = 48`、其余与 `@default` 相同"的用例，**我方读数会逐位等于 `@default` 臂**（网格仍是 96）。**红量级 = 整个 tab 网格间距（`4×emSize` vs 宿主值）**，非小数容差问题。<br>⚠️ **今天这个红必须"造"出来才有** —— 现有 436 例里**没有**任何一例携带"非 0 且非默认的 `DefaultIncrementalTab`"（`analyze.py:160` 只分了两臂）⇒ **反极性今天不可达**（见 ⑤）。 |
| **④ 世代价** | **`shim-HbTextLine`（要付五臂重取 + 重钉）** —— 若走 (乙)；<br>**走 (甲) 只改生成物**（给 `TryFormatLine` 加槽 + 把 `settings.Pap.DefaultIncrementalTab` 透到两个调用点）则**只付"波 + 重冻"**（`TextFormatterImp.Linux.cs` 不在 `GEN_KEYS`）。**但 (甲) 也要求 shim 的严格档入口有槽** —— `shim:4522-4524` 的严格档 `TryFormatLine` **今天没有** ⇒ **严格档那一半必然要动 shim** ⇒ **实际是 (甲)+(乙) 混合 ⇒ 世代价付**。<br>**轻量出路**：本件只在**宽松档**落地（宽松档工厂 `:2824` **已有** `defaultIncrementalTab` 槽）⇒ 不动 shim ⇒ **世代价 = `无`（只动生成物与臂）**。 |
| **⑤ 阻塞项** | **`必须真机重录才有真值`**（预登记 §4 逐字要求点明，我照办）：<br> **(a)** 在 `tests/parity/windows/tab-anchor/src/Program.cs` 的宿主里加一族**非 0 非默认**的 `DefaultIncrementalTab`（现成入口 `:423-478` 一带已录 `FormatMinMaxParagraphWidth`，`analyze.py:160` 已有分臂框架）⇒ 需要**一台 Windows 机 + 重录**；<br> **(b)** 在拿到 (a) 之前，**不许**用"`4×em` 应该对"或"`48` 应该对齐到 48"当判据 —— 那是**推测值**（纪律 22 明令）。 |
| **⑥ 价值排序** | **第 6 位**。<br>**为什么值钱**：它是**唯一一条"仪器侧与产品侧同时缺"的条目** —— 补上它**同时**买到"臂能表达 tab 网格"与"PC 契约面完整"；它也是 `PcLineOracle` 那 136 条登记红（占已登记族 100%）的**根治**。<br>**为什么排在后面**：**唯一阻塞项是"需要 Windows 真机重录"** —— 在本机做不出反极性、也做不出判据 ⇒ 是一个**外部依赖**，不是本机能推进的。**建议：本波只做"把 PC 侧的槽和透传先落上（(甲)+(乙)）+ 在 `PcLineOracle` 里把 `@default`/`@tab0` 两族彻底分桶"**，真值那一半**排到有 Windows 机的那一波**。 |

### C. `D-T2-c` —— 两个宽度探针共用一把**已知错**的尺子（缺 `modifierScopeEnd`）

| 列 | 内容 |
|---|---|
| **① 现场锚点** | **两个探针（现状：参数已对等，但都错在同一处）**：`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:277` `out double minWidth, out double maxWidth`；`:303-308` **max 探针** `FormatParagraph(…, out c1, modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2)`；`:320-323` **min 探针** 同样只传 `modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2` ⇒ **两处都不传 `modifierScopeEnd`** ⇒ 取默认 **−1**。<br>**"−1 = 到段末"被 shim 自己标注为实测错**：`shim:3854-3858` 逐字（`⚠️ 本件只补这一处的参数对等：max 那条 modifierScopeEnd = -1（"到段末"）是**已知错**的跨度（shim :3854-3858 自述）` —— 这句同时在生成物 `:316-317` 里）。<br>**为什么今天不能改**：`CollectLenient` 的形参表 **`:102-103`** 只 `out` 两个位置 ⇒ **收不到覆盖终点**（`modifierScopeEnd` 无处可来）⇒ 改它 = **编一个值**（纪律 22）。<br>**参考实现（说明"终点"是可得的信息）**：`shim:1732` `int kh = (modifierScopeEnd < 0 ? len : Math.Min(modifierScopeEnd - start, len));`、`shim:2852-2853` 同一形态。 |
| **② 判据草案** | **前置（写死，先做）**：给 `CollectLenient` 加 `out int modifierScopeEnd`，在**配对 `TextEndOfSegment` run 的起点**处记录（现成代码位 = 生成物 `:156-158`，`modifierCloseIndex = cp - cpFirst` 的同一行旁边；**注意半开区间口径**：`scopeEnd = closeIndex`（不含），与 `shim:1732` 的 `Math.Min(modifierScopeEnd - start, …)` 一致 —— **口径必须与 shim 逐字对齐，否则会引入一个新的 off-by-one**）。<br>**取数位置**：`build/MilBridge/tests/MinMaxProbe/**`（`#17` P3 的判据臂，`cfcf464457163280`）—— 它已有"构造例 + `rel=gt/eq`"的两极化形态（`#17` 实测 `min=22.652344 max=0.000000 rel=gt → min=0 max=0 rel=eq`）。<br>**期望值来源**：**上游同一份 `PrepareFormatSettings`**（`upstream/…/TextFormatterImp.cs:204-220` 对比 `:295-315`，`KNOWN-DEFECTS.md` §`D-T2` 更正条已引）⇒ 判据是"**min 与 max 必须用同一把尺子**"，**不需要新真值**（这是契约级判据，不是真值级）。<br>**判据**：给一条"**覆盖区在段中结束**"（`open < scopeEnd < 段末`）的构造段落，两个探针都必须用**同一个真实 `scopeEnd`**；且 `min ≤ max` 恒成立。 |
| **③ 反极性（现状必须红）** | **红在"覆盖区在段中结束"这一类构造上，且红是可算的**：传 `-1`（到段末）时 `${shim:1732}$` 把**段末之后的所有字符也算进零宽跨度** ⇒ max 探针会**低估** `maxWidth`（跨度越大、越多的字符被判成零宽）⇒ 期望形态是 **`max` 比真值小**、而 min 探针因同一把尺子也偏 ⇒ **`min > max` 或两者同时偏小**。<br>**红多少（我算不出、也不许编）**：`KNOWN-DEFECTS.md` 逐字写「**量级是"预测"，不是"实测"**」⇒ **本报告不给出数值**，只给"**必须用一条覆盖区在段中结束的构造例+一段覆盖到段末的构造例做对拍；两者读数若逐位相同 ⇒ 判据零判别力**"这条可判形态。<br>⚠️ **一个必须写清的边界**：**在"覆盖到段末"的语料上，`-1` 与真值恰好相同** ⇒ 判据**必须**用"段中结束"的用例，否则**恒绿**。 |
| **④ 世代价** | **`无`（前置 + 判据都可只改生成物与臂）** —— `CollectLenient` 在 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（生成物，**不在 `GEN_KEYS`**）；`MinMaxProbe` 是臂。<br>⚠️ **例外**：若"终点"只能从 shim 侧拿到（我今天静态看不出必须如此），则升为 `shim-HbTextLine`。 |
| **⑤ 阻塞项** | **需先定"终点"的**语义口径**并写进代码注释**：`closeIndex = cp - cpFirst`（close run 的**起点**）已在生成物 `:157-158` 与 `KNOWN-DEFECTS.md` 里被定义为"唯一稳的定义"；`scopeEnd` 与它的关系（相等？还是 `+1`？）**必须在落地前现场重读 `shim:1732` 与 `shim:2852-2853` 定死** —— 引注前现场重读 = 纪律 4。<br>**无需真机重录**（契约级判据）。 |
| **⑥ 价值排序** | **第 5 位**。<br>**为什么值钱**：它把 `#17` P3 买的"**同一把尺子**"从"参数对等"推进到"**参数正确**"；而且它是**唯一一条"两个探针同时读同一个量、却同时错"的条目** ⇒ 修它**同时**改善 `minWidth` 与 `maxWidth` 两条链。<br>**为什么不是前三**：今天**没有任何臂消费 `minWidth`**（`KNOWN-DEFECTS.md` 逐字：13 个臂宿主 **0 命中**、30 份 oracle JSON 全都没有 min/max 输出字段）⇒ **修了之后，短期内仍然没有消费者** ⇒ 收益要等"有臂消费 minWidth"才兑现。**它的真实价值是"把一条已知错的尺子从判据里拿掉"，是防御性的**。 |

### D. `D-R3` 残项 —— 逐条拆成可执行条目

> `#18` 给两处 `SetDllImportResolver` 安装点加了守卫（V1 `build/shims/Win32ShimResolver.cs` 的 `[ModuleInitializer]`、V2 `src/WpfGfx.Linux/Windowing/X11Native.cs` 的静态构造），并按**段数口径收窄**了"无条件自证"。
> **收窄的代价已如实登记**（`KNOWN-DEFECTS.md` §⑩ 残项逐字）：①"真宿主里会不会走到"没测；② AOT 镜像内 `X11Native` 静态构造是否会被执行、其 `Assembly` 身份未测；③ **判据① 不再由守卫行使**（改用 `realcall` 直测，但**① 的修前对照没测过**、**V2 的 ① 没测过**），判据④ 退回修前同款行为。

#### D-1 `D-R3` 残项 (i)：真机可达性（外部安装者抢先）

| 列 | 内容 |
|---|---|
| **① 现场锚点** | 探针 = `build/MilBridge/tests/ResolverGuardProbe/`（目录存在，mtime `2026-09-16 14:51`）；被测 = `build/shims/Win32ShimResolver.cs`（`0735327b6ca3ae4b`）、`src/WpfGfx.Linux/Windowing/X11Native.cs`（`8ede4d8a13cb3a28`）；报告 = `build/MilBridge/V18A-report.md`（`2d7809699ebf51d4`）。已知红证形态（`KNOWN-DEFECTS.md` §⑩ 逐字）：**`FOREIGN_INSTALL=OK`**、**(a)** `NO_THROW` + `ResolverConflict=True` + `SelfCheckShimVersion=1`、**(b)** `… user32.dll 解析不到 —— 当前生效的解析器不是我们这一个…`。 |
| **② 判据草案** | **取数位置**：**在一个"真宿主"里**（候选 = `samples/HelloWpf`、应用门禁 runner 装的 `samples/WpfTextDemo`、或 `WicClosedLoop`）**在加载 PC 之前**装一个外国解析器，然后照常跑；观测面 = `ResolverConflict` 诊断钩子（`V18A` 已挂上）+ **首个真 `[DllImport]` 处的失败文案** + 进程是否 `TypeInitializationException`。<br>**期望值来源**：`#18` 两极化已实测的**同形读数**（本机、`Assembly.LoadFrom(pc)` 场景）⇒ 真宿主上的期望是**同一形态**，不是新真值。 |
| **③ 反极性（现状必须红）** | **这一条的反极性是"必须不出现"**：真宿主上**不得**出现 `TypeInitializationException` / 整模块死。⇒ **判据的红 = "真宿主里出现整模块/整类型死"**。<br>**"必须红"的那一半 = "红证本身能红"**：造一个"外国解析器不映射我们的名字"的真宿主 ⇒ **必须响亮且点名**（这是 `#18` 已在探针里拿到、但**没在真宿主里拿过**的那一格）。<br>⚠️ **今天这一条完全没有读数** ⇒ 现状是 **`NOINFO`，不是绿**。 |
| **④ 世代价** | **`无`**（只加探针/宿主侧仪器，不改产品件）。 |
| **⑤ 阻塞项** | 需要"能在真宿主进程里抢先装解析器"的注入点：**这不是单元测试能做到的**（`ModuleInitializer` 在真宿主里由 CLR 在模块加载期跑，`#18` 已实测「`Assembly.LoadFrom(pc)` 之后外国解析器装得上」⇒ **模块初始化器不是加载期跑的**）。候选 = 在 `samples/HelloWpf/Program.cs` 顶部加一段**只在特定 env 下生效**的自证代码 —— **但那会改 `samples/**`**（T3 写域）⇒ **需先与主控/T3 对齐写域**。<br>**另一个可行面（不动 `samples/**`）**：`build/DirectWrite.Linux/WicClosedLoop/Program.cs`（我们的宿主，`#18` V3 动过它）⇒ **在那里做外军抢先，代价小**。 |
| **⑥ 价值排序** | **第 7 位**。<br>**为什么值钱**：`KNOWN-DEFECTS.md` 把严重性从"潜在"上调为"**可达**"（`FOREIGN_INSTALL=OK`），而"**可达的那部分**"恰恰是**没测的那部分**（探针证的是**路径可达**，不是**真宿主会走到**）。<br>**为什么排后**：`#18` 的守卫已把"整模块死"变成"响亮失败"⇒ **最坏后果已经从"死"降级为"响"** ⇒ 紧迫性下降。 |

#### D-2 `D-R3` 残项 (ii)：AOT/单文件镜像下 `X11Native` 的静态构造

| 列 | 内容 |
|---|---|
| **① 现场锚点** | `src/WpfGfx.Linux/Windowing/X11Native.cs`（**当前 `8ede4d8a13cb3a28`**，`#18` V2 的守卫已落）；它**是桥源** ⇒ `BRIDGE_SRC_FP`（当前 `b6acdba4f01599d8`）与九位里的 `bridge`（`d567c26f197ec1e3`，4,987,840 B）都由它决定。AOT 镜像 = `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so`。 |
| **② 判据草案** | **取数位置**：在**已发布的 AOT 镜像**里问三个问题 —— **(a)** `X11Native` 的静态构造**是否被执行**（在镜像里放一个只写诊断的副作用，跑一次看有没有）；**(b)** 执行时 `Assembly.GetExecutingAssembly()` 的**身份**是什么（AOT 会让 `Assembly` 身份与托管编译期不同）；**(c)** 守卫在 AOT 下的**分支走向**是否与 JIT 一致。<br>**期望值来源**：`#18` 在 **JIT 宿主**下拿到的两极化读数（`libX11.so.6` **0→0**、V2 TOTAL **244→244**）⇒ AOT 下的期望是**同一形态**（段数 0→0）。 |
| **③ 反极性（现状必须红）** | **今天零读数** ⇒ `NOINFO`。<br>**"会红"的形态可写死**：若 AOT 下静态构造**不执行** ⇒ 守卫**形同不存在**（这是"保卫失踪"型红）；若执行但 `Assembly` 身份变 ⇒ 自证分支可能**走进错支**（这是"自证说谎"型红）。**两者都必须能被一条读数区分** —— 这就是判据的内容。 |
| **④ 世代价** | **`无`**（只读数；**若要修**则 = `shim-其它` + **重发桥** + 重冻 —— 桥在九位里）。 |
| **⑤ 阻塞项** | 需要一次**桥发布**（`build/publish-milbridge.sh`）+ 一次 AOT 镜像内的运行 ⇒ **要 `dotnet`/发布权重**，本车道（只读）不可做。**另**：`#18` 的段数口径有 ±2 抖动（`KNOWN-DEFECTS.md` 逐字"机器断言下在**针数**上（TOTAL 有 ±2 抖动）"）⇒ 判据**不许**用"TOTAL 相等"当唯一信号，要用**针数**（该文件逐字口径）。 |
| **⑥ 价值排序** | **第 8 位**。<br>**为什么值钱**：它是**唯一一条"守卫可能在 AOT 下完全不生效"的条目** —— 而项目里 `bridge` 就是 AOT 产物、且是九位之一。<br>**为什么排后**：**今天没有任何证据说 AOT 下真会坏**（纯未知）⇒ 与"已知能红的盲区"（`D-A2`）比，优先级低。 |

#### D-3 `D-R3` 残项 (iii)：判据① 的修前对照从未测过 ← **本条是残项里唯一"根本没有判据盯着"的**

| 列 | 内容 |
|---|---|
| **① 现场锚点** | `KNOWN-DEFECTS.md` §⑩ 残项逐字：**「收窄的代价」：判据① 不再由守卫行使（`realcall` 直测 `REAL_DLLIMPORT=OK`，但**① 的修前对照没测过**、**V2 的 ① 没测过**），判据④ 退回修前同款行为**」。<br>**判据①的原文**（`docs/CURRENT-STATE.md` §0 横幅逐字）：`判据① 存活/退出码：alive=1 exit=143 ✅` —— 注意**那是应用门禁的判据①**；`D-R3` 的判据①见 `V18A-report.md`（`2d7809699ebf51d4`）与 `KNOWN-DEFECTS.md` §⑩。 |
| **② 判据草案** | **取数位置**：`realcall` 直测的**同一台仪器**（`ResolverGuardProbe`）在**修前件**上跑一遍。<br>**怎么拿到修前件**：`build/shims/Win32ShimResolver.cs` **有留档**（`#18` 报告 `2d7809699ebf51d4` §产出，以及 `$HOME/wfp-runs/w18-pre/` 一带的 `*.before`）⇒ **修前对照是可复现的**（不需要重编产品，探针按 env 指到备份件即可）。<br>**期望值来源**：`#18` 的**修后**读数（`REAL_DLLIMPORT=OK`）⇒ 修前应在**至少一格上不同**（否则"修了什么"没有读数支撑）。 |
| **③ 反极性（现状必须红）** | **红在"这条判据今天不存在"这一事实本身**，而**不是**在某个数值上：<br> **现状 = 判据① 由 `realcall` 直测行使，而 `realcall` 的**修前对照从未跑过** ⇒ 我们**不知道**它变红了意味着什么**（可能它**修前也是 OK** ⇒ 它**恒绿** ⇒ 按纪律 3/21，**它是一条不会变红的判据**）。<br>**这是本报告认定"会静默漂"的第 2 个风险面**（第 1 个是 §0 结论 1 的严格档腿）。 |
| **④ 世代价** | **`无`**（只跑探针 + 引留档件）。 |
| **⑤ 阻塞项** | 需确认 `$HOME/wfp-runs/w18-pre/` 的**备份件还在**（本机 `$HOME` 曾被整盘清过一次 —— `docs/CURRENT-STATE.md` §6 逐字提到该教训）⇒ **若备份不在，修前对照就永久不可得**（除非重建修前 shim 并重编产品 ⇒ 世代价）。**⇒ 这一条有一个"越早做越便宜"的性质**。 |
| **⑥ 价值排序** | **第 3 位**（我建议下一波就做）。<br>**为什么值钱**：① 它是**唯一一条"判据本身从未被验过"**的残项 ⇒ 属于纪律 3「仪器必须能变红」的**直接欠账**；② 成本极低（跑一条命令 + 引一份备份）；③ **它有保质期**（备份在 `$HOME` 上，历史上被清过一次）。<br>**"现在根本没有判据盯着"的判定**：**是的** —— 判据① 的**修前对照**这一格**没有任何判据**；而且它是**判断"判据① 是否恒绿"的唯一手段**，所以它缺失时**整条判据① 都不可信**。 |

### E. `D-F1c`①c —— 1CJK `.ttc` = **3 段** vs 目标 **1–2**

| 列 | 内容 |
|---|---|
| **① 现场锚点** | **判据与复取配方写死处**：`build/DirectWrite.Linux/evidence/mem-D-F1c/INDEX.md`（**`bc8ec2f78aa99530`**）：`:25` 采样器 = `build/DirectWrite.Linux/FallbackCriteria/mem-sampler.sh`（**`09e5bab7c3d246f6`**，`--selfcheck` 必须 PASS 才可用）；`:27-28` 复取配方（`WPF_LINUX_FONT_DIR=$HOME/wfp-runs/fontdir-1` + `--mode=null --para=b34` + `maps`/`smaps` 快照）+ **主判据 = 段数 12 → 1–2 与这些段的 Σ虚拟**。<br>**段数读取器**：`build/DirectWrite.Linux/FallbackCriteria/seg-sampler.py`（**`9934771b1bff861b`**）+ `seg-instrument.sh`；判据层 `eval-df1-criteria.py`（**`fc808896f23390f4`**）。<br>**读数（波后，`#15` 阶段）**：`docs/CURRENT-STATE.md` §4 `D-F1c`① 波后复取行逐字：「**①c ✗ 未达成**：1CJK 该 `.ttc` = **3 段 / Σ虚拟 55.8 MB**（目标 1–2）⇒ **差 1 段**，归因 = **shim 侧**（常驻 2 段 = provider 共享 `SKData` + Skia 内部各 1；**瞬时 1 段**在 shim 回退扫描期，用窗口 9 的 `--mode=nofb` 对照可证该段消失）」+ 「`①c` 的原目标 "13 → 1–2" 是**波前**口径（窗口 8 实测 13 段），波后是 **13 → 3**」。<br>**"哪一段归谁"的判据工具**：`--mode=nofb`（`KNOWN-DEFECTS.md` 逐字：反极性对照 ⇒ `LINE_W=9.6000 CR_W=−3.0560 GID=0 ADV=9.6000`）。 |
| **② 判据草案** | **取数位置**：`seg-sampler.py` 对 `$HOME/wfp-runs/fontdir-1` 档（1CJK）跑 `--mode=null --para=b34`，读**该 `.ttc` 的段数 + Σ虚拟**。<br>**判据（今天已写死，我照录）**：**该 `.ttc` 段数 ∈ {1,2}**；**反极性对照必须同时跑 `--mode=nofb`**（证明"瞬时那 1 段"确实来自 shim 的扫描期）。<br>**期望值来源**：**不是真值、是设计目标**（`INDEX.md` 与 §4 都写"1–2 段"）—— 目标来自"**每被加载文件 ≈1 段映射**"这条设计口径（`D-F1c`①b 已达成的形态：系统档 **29 段 / 24 个被加载文件 = 1.2 段/文件**）。 |
| **③ 反极性（现状必须红）** | **已是红的、且有精确数**：**3 段 vs 目标 ≤2**（差 **1 段**）；**不是猜测值**，是 `#15` 阶段的实测（`docs/CURRENT-STATE.md` §4 `D-F1c`① 波后复取行）。<br>**红在哪**：**该 `.ttc` 的段数这一格**（不是 RSS、不是峰值）—— 判据口径逐字是「**段数 / Σ虚拟为主判据，RSS 只作旁证**」。 |
| **④ 世代价** | **`shim-HbTextLine` ⇒ 付五臂重取 + 重钉**。<br>**依据**：归因逐字 = 「**shim 侧**（常驻 2 段…）」⇒ 要动的是 `build/shims/PresentationCore.HbTextLine.cs` 的面/blob 生命周期 ⇒ **命中门禁三项之一**。 |
| **⑤ 阻塞项** | **① 需要 sample-runs 面**：`mem-sampler.sh`/`seg-sampler.py` 要跑真进程（本车道只读 ⇒ 不可做）；<br> **② "差的那 1 段是常驻还是瞬时"必须先确认** —— 今天两条读数（常驻 2 + 瞬时 1 = 3）**都没有在我这一版树上复取过**：`3 段` 是 `#15` 阶段的读数（件 `b5118424dc977aef`），而现树 shim 是 `fe1b7ed8fa3ed231`（`#19`，**已改过**）。⇒ **落地前必须先复取一次**，否则会把"旧代的数"当"现状"（纪律 15/26）。<br> **③ 目标"1–2"本身是设计口径而非真值** ⇒ 判据里必须写明它**不是真机真值**（避免后人误引）。 |
| **⑥ 价值排序** | **第 10 位**。<br>**为什么值钱**：它是**内存线的唯一残留格**，且判据、仪器、配方**都齐**（`INDEX.md` 把复取配方与主判据写死了）⇒ 是**最"可以立刻干"的一条**。<br>**为什么排后**：① 差 **1 段**（不是 10 倍级）；② `①a`（≤300 MB）与 `①b`（1.2 段/文件）**已达成** ⇒ 用户可见的内存问题已解决，剩下的 1 段是**精细度**；③ 要付**世代成本**（这是本项目最贵的一笔）。 |

### F. `D-F2` —— 第一步：把**从未打印过**的 `HbFallbackDiag.SegmentFaceUnresolved` 打出来

| 列 | 内容 |
|---|---|
| **① 现场锚点** | **定义**：`build/shims/PresentationCore.HbTextLine.cs:1275` `internal static long SegmentFaceUnresolved;` → `:1276` `internal static void NoteSegmentFaceUnresolved() => …Interlocked.Increment(ref SegmentFaceUnresolved);`（**唯一自增点 = `:3831`**，`BuildSegmentFacesFromPlan` 里 `if (g == null) HbFallbackDiag.NoteSegmentFaceUnresolved();     // D-F1b/P2`）。<br>**为什么从未打印**：`HbFallbackDiag.SummaryFragment()` = **`shim:1344-1379`** —— 我逐行核对过它的**全部** `Append`：`multifont/plan/runs/runGt1/cpUncovered/coverageProbe/liveBlobs/sharedBlob*/foreignBlobDestroys/blobsOutstanding/residentCount/releaseCalls/segmentFaceResolveCalls/coverageCacheHit/fallbackApplied/fallbackFailed/fallbackUnrenderable/fromRunFaces/fromSystemScan/segments/chunkedLines/faceResolve/candidates` ⇒ **`SegmentFaceUnresolved` 不在其中**（`DetailFragment()` = `:1382-1401` 也没有）。<br>**全仓命中数 = 3**（`grep -rn SegmentFaceUnresolved`：`:1275` / `:1276` / `:3831`）—— 与 `KNOWN-DEFECTS.md` 逐字一致（「全仓 3 处、零打印」）。<br>**出口的真实位置（做这一步要落的地方）**：`shim:2216` `sb.Append(' ').Append(HbTextFallback.SummaryFragment());` 与 `shim:4382` / `:4396`（`+ " " + HbFallbackDiag.SummaryFragment();`）/ **`:4587`** `sb2.Append("\n  计数器：").Append(SummaryFragment());`。<br>**本条的"为什么值钱"依据（登记原文）**：`KNOWN-DEFECTS.md` §② 逐字：「**量爆炸半径的计数器 `HbFallbackDiag.SegmentFaceUnresolved`（`shim:1275`，在 `:3823` 自增）从来没有任何打印点**（全仓 3 处、零打印）⇒ **写不出位移预测**，与"逐件先写死预测"的纪律冲突」；**专项第一步（写死）**：「把 `SegmentFaceUnresolved` **印进 `SummaryFragment()`**（shim 1 行、无语义变化）⇒ 先拿"今天有多少面解析不出来"的读数，**再**谈修」。 |
| **② 判据草案** | **取数位置**：跑现有任一**会走 `BuildSegmentFacesFromPlan` 的臂**（`PcLineOracle` 两腿 / `CoverageProbe` 的 oracle 腿 / `tline`），读诊断汇总行里的新字段。<br>**期望值来源**：**没有真值** —— 这一步买的是**读数本身**（"今天有多少面解析不出来"）。判据形态 = **三态**：`>0` ⇒ 回退第二条路**今天就在开**（`FaceSlot = -1` 已被消费：`shim:665` `SegmentIndex = seg.FaceSlot`）；`==0` ⇒ 这条路今天没开（**且必须配一条正控**证明"0 不是没跑到"：`PlanCalls>0`）。<br>**⚠️ 纪律 25/27 的形态**：`SummaryFragment()` 在 `PlanCalls == 0` 时**已经**返回 `"multifont=未使用(plan=0) 覆盖/回退各项=**无信息**"`（`shim:1346-1347`）⇒ 新字段**必须落在这个"无信息"分支之外**，否则会产出"0 当绿"。 |
| **③ 反极性（现状必须红）** | **红在"这条计数器的出口不存在"**：今天任何日志里**都不可能**出现这个数 ⇒ 判据**恒 `NOINFO`**。<br>**"能变红"的实现**：加出口之后，**用 `D-F2` 的已知触发面**（`new GlyphTypeface(new Uri("file://…"))` 对 `build/fonts/**` 的纯 TTF **必抛 `FileFormatException`** —— `KNOWN-DEFECTS.md` §`D-F2` 逐字）造一条读数 ⇒ 该计数器**必须 > 0**。这就是**这条新出口的两极化**（今天无出口 ⇒ 0/NOINFO；接线后 ⇒ >0）。 |
| **④ 世代价** | **`shim-HbTextLine` ⇒ 付五臂重取 + 重钉**（改的是 `PresentationCore.HbTextLine.cs`）。<br>⚠️ **这是本条唯一的坏消息**：即使"只加一行打印、零语义"，按纪律 31 的现场（**只加一段帮助注释就**把门禁打成 `NOINFO/rc=2`**），**它照样换世代**。⇒ **必须与"下一波要动的 shim 件"合并成同一波**，否则白付一次。 |
| **⑤ 阻塞项** | **无真值依赖、无 Windows 依赖** ⇒ **本表里唯一一条"今天就能做、且做完立刻有读数"的**。唯一要求 = **按纪律 24/16 留档**（改前 `cp -p` 备份 + before/after sha16）。 |
| **⑥ 价值排序** | **第 1 位**（我建议下一波第一件）。<br>**为什么值钱**：① **成本最低、读数最直接**（一行打印换一条从未有过的数）；② 它是**两条独立登记项的共同前置**：`D-F2` 自己的修法（"先拿读数再谈修"）、以及 `D-F1b` 的"一族多名面"边界（`KNOWN-DEFECTS.md` §`D-F1b` 逐字把它登记为"**已登记、未验**"）；③ **它买的是"能不能写位移预测"这个能力**本身 —— 本项目里"写不出预测 ⇒ 不能落件"是硬纪律。<br>**注意**：因为**要付世代成本**，它应当**不是单独一波，而是"下一次动 shim 那一波的首件"**（与 `D-T5`(乙)/`D-T4`(乙)/`D-F1c`①c 同波）。 |

#### F′ `D-F2` 的**发现延伸（本报告新增，非登记）**：缺出口的计数器是**至少 3 个**，不是 1 个

我在核 `SegmentFaceUnresolved` 的出口时**逐条扫了 `HbFallbackDiag` 的全部 `static long` 计数器**，另外两个**同样是"只自增、无出口"**：

| 计数器 | 定义 | 唯一自增点 | 出口 | 现场证据 |
|---|---|---|---|---|
| `SegmentFaceUnresolved` | `shim:1275-1276` | `:3831` | **无** | 全仓 3 处（`:1275/:1276/:3831`） |
| `RunFaceSlotMissing` | `shim:1278-1279` | **`:2782`**（`else if (plan != null) HbFallbackDiag.NoteRunFaceSlotMissing();   // D-F1b/P1c：有计划却拿不到面槽 ⇒ 记数`） | **无**（`SummaryFragment` 里没有） | 全仓 **3** 处（`:1278`/`:1279`/`:2782`），零打印 |
| `ScanCapped` | `shim:1272-1273` | **`:1147`**（`if (list.Count >= MaxScanFaces) { HbFallbackDiag.NoteScanCapped(); break; }`） | **无** | 全仓 4 处，零打印 |

**其中 `ScanCapped` 还带一条"自称能力是假的"**：它的**三处**注释（`:1067`、`:1146`、`:1271`）逐字写「**可观测**；超限 ⇒ `NoteScanCapped` + **诊断行 `capped=`**」/「**可观测**：超限记数并在诊断里报 `capped=`」/「**可观测**；诊断行报 `capped=`」，而 **`capped=` 在 `build/ src/ samples/ tests/` 里的全部命中 = 4 行**（命令：`grep -rn 'capped=' build/ src/ samples/ tests/ --include=*.cs --include=*.py --include=*.sh`）：
- `shim:1067` / `shim:1146` / `shim:1271` —— **三行注释**；
- `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh:164` —— 一行**变量赋值**（`INVIS_CAPPED="${i#invisible_capped=}"`），**不是打印行**。
⇒ **`capped=` 的真 0 成立**（我用的是**精确子串** `capped=`，它**不会**匹配 `invisible_capped=` —— `invisible_` 是前缀，`grep` 做的是子串匹配，所以 `invisible_capped=` 那几行需要**显式排除**才能看清：排除后剩下的正是上面这 4 行）。
**正对照（纪律 25 要求）**：同形 pattern **`invisible_capped=` 存在且非 0**（`applocal-expect.py:485` 的 `#SUMMARY|…|invisible_capped=%d…` 打印它、`check-applocal-sync.sh:590` 解析它、`:596` 在 `SELFTEST_M2=PASS` 行里回显它）⇒ **那是真的"有出口"的计数器，属于另一个仪器**；`capped=` 的 0 **不是"仪器瞎"，是真 0**。另有 `internal static string LastScanInfo = "-";`（`shim:1072`，**唯一赋值点 `:1153`**）**也从不打印**。

**⇒ 对 A 表的修正（我建议 §5 把它与 F 条合并成一件）**：`D-F2` 的第一步应当是「**把 3 个计数器一起接出出口**」（`SummaryFragment()` 里加 3 个 `Append`，约 3–4 行），而不是只接 1 个。**成本几乎相同，买到的读数多两倍**，而且 `RunFaceSlotMissing` 正是 `D-F1b` 那条"面槽拿不到"的直接量尺。

### G. `D-A1` / `D-A2` / `D-A3` —— 三条副本类缺陷，**各自的检查器覆盖面**（这是本节的核心）

> `D-A1` 已经**加固落地**：`UNEXPECTED` **不改名**、按"内容 vs 权威"显式二分 ⇒ `UNEXPECTED=N[DECL-GAP-EQ=n DECL-GAP-DIFF=m]`（`check-applocal-sync.sh:36-49` 逐字；实现见 `:254-258`）；**两个子类都仍在 `UNEXPECTED` 总数里、都仍然红**（`docs/CURRENT-STATE.md` §4 裁决行逐字：「① 铁律是"**红检测只许加强、不许放宽**"…③ **合法变绿的路子不是消音、是声明**」）。
> **现状读数**（`docs/CURRENT-STATE.md` §4 `D-A1` 行逐字）：`APPSYNC=MISMATCH`、`OK=45 MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=0 NO-AUTHORITY=20 LIB-COPY=0 SKIP(obj)=6 SKIP(stub)=4 SKIP(ref)=10 RETIRED=0`、**`rc=1`**。

#### G-1 `D-A1` —— 未声明的传递依赖副本（**已被点名、仍然红**）

| 列 | 内容 |
|---|---|
| **① 现场锚点** | 被点名件 = `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll`（内容 == 权威 `0c597fb6ec1eec70`）；成因 = `build/DirectWrite.Linux/FallbackCriteria/FallbackCriteria.csproj` **只有三条 `HintPath`（PC/WB/DWF）、没有 `WpfGfx.Linux`**（`KNOWN-DEFECTS.md` §`D-A1` 逐字）。判据实现 = `check-applocal-sync.sh`（**`aad23482f84bdf44`**）+ `applocal-expect.py`（**`6eafbea14e7ea41e`**）。 |
| **② 判据草案** | **已有判据（不新建）**：① 声明之后该副本必须判 `OK`；② **撤掉声明 ⇒ 必须回到 `UNEXPECTED-EQ` 红**（`docs/CURRENT-STATE.md` §4 裁决行逐字：「否则说明"声明"这条路是假的」）。<br>**取数位置**：`bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`（`close-wave.sh:159` 已在跑）。 |
| **③ 反极性** | **已经是红的**（`UNEXPECTED=1[DECL-GAP-EQ=1]`、`rc=1`），且**两个方向都实测过**（`KNOWN-DEFECTS.md` §`D-A1` 加固条逐字：塞内容不同的副本 ⇒ `UNEXPECTED-DIFF` + `DIVERGENT=1` + `rc=1`；还原 ⇒ `UNEXPECTED-EQ` + `rc=1`）。 |
| **④ 世代价** | **`无`**（改 `FallbackCriteria.csproj` 的声明 ⇒ 只动一个测试宿主的引用图；**但它会让该目录多出/改变一份副本** ⇒ 波内 `REFRESH`/`APPSYNC` 口径要跟着看）。 |
| **⑤ 阻塞项** | **无**。 |
| **⑥ 价值排序** | **第 11 位**（**已经"看得见、红着、有名字"** ⇒ 剩下的只是"何时把它声明掉"这个决定，不是"缺判据"）。<br>**为什么仍需登记在下一波**：它是**唯一一条"红着但合法变绿的路只有一条（声明）"**的条目 ⇒ 拖得越久，越容易有人走"消音"那条路（裁决行已经把这条路堵死，但堵住 ≠ 走完）。 |

#### G-2 `D-A2` —— `ITEMS` 只覆盖 **5–6 个件** ⇒ **"存在但未被判定的副本"是一个没有任何判据的洞**

| 列 | 内容 |
|---|---|
| **① 现场锚点** | **权威表（逐字抄自 `build/DirectWrite.Linux/wic-shim/applocal-expect.py:42-48`）**：`ITEMS` = `libwpfwic.so`、`libwpfwin32.so`、`DirectWrite.Linux.Provider.dll`、`WpfGfx.Linux.dll`、`ReachFramework.dll`、以及 **`wpfgfx_cor3.so` 但权威串为空 `""`（注释逐字 `# 无单一权威 ⇒ 不覆盖`）** ⇒ **实际被判定的是 5 个件**。<br>**实测后果**（`KNOWN-DEFECTS.md` §`D-A2` 逐字）：① `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/` 里 **17 个 DLL 只有 2 个被判定**；② 对检查器自己的输出 `grep -c PresentationCore.dll` = **0**；③ **全部 `.so` 副本（含已发布的桥 `wpfgfx_cor3.so`）`EXPECT=UNKNOWN`、根本没有权威可比 ⇒ 不可能变红**；④ `.artifacts/**` 与 runner 的 `$OUT` **不在 `SCAN_ROOTS` 里**。<br>**`SCAN_ROOTS` 的原文**：`check-applocal-sync.sh:93` `SCAN_ROOTS="${SCAN_ROOTS:-$REPO/build:$REPO/tests:$REPO/samples:$REPO/src}"` ⇒ **`.artifacts/**` 确实不在**（发布目录 = 桥的唯一真身，而它扫不到）。 |
| **② 判据草案** | **三条（我照录 §4 判据并把它具体化到可执行）**：<br> **(a) `ITEMS` 扩到"会被加载的托管件"** —— 最小集合 = `PresentationCore.dll`、`WindowsBase.dll`、`DirectWriteForwarder.dll`、`WpfGfx.Linux.dll`（已在）、以及 `pf`。**判据 = 删掉任一被判目录里的该件 ⇒ 必须红**（今天**连计数都不动**）。<br> **(b) `.so` 要有独立判据**：`wpfgfx_cor3.so` 的权威 = `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so`（**九位里的 `bridge`**，`d567c26f197ec1e3`）⇒ 给它一个真权威，而不是 `EXPECT=UNKNOWN`。<br> **(c) `SCAN_ROOTS` 至少覆盖 `.artifacts/**` 与 runner 的 `$OUT`**（或**显式**印发"这些目录不参与判定以及为什么"—— 纪律 37 要求"未覆盖清单必须印出来"）。 |
| **③ 反极性（现状必须红）** | **本条的"红"是一种特殊形态：`NOINFO`（纪律 37）** —— 「**未被判定的副本不是绿的副本**——"检查器什么都没说"是一条**读数为 0 的证据**」。<br>**可实测的红证（`KNOWN-DEFECTS.md` 已给阴性实验）**：往宿主目录里放一份**与权威等值**的 `libwpfwic.so` ⇒ `OK`、`UNEXPECTED=0`、**`rc=0`** ⇒ **证明"多一份副本"这件事本身在今天的模型里是静默的**。<br>**接线后必须能红的形态**：往任一**新增**被判定的目录里放一份**内容不同**的副本 ⇒ **必红**。 |
| **④ 世代价** | **`无`**（改 `applocal-expect.py` 的表 + `check-applocal-sync.sh` 的 `SCAN_ROOTS` 默认值 ⇒ 都是检查器，不碰产品件、不碰 shim）。<br>⚠️ **但它会改 `close-wave.sh:159` 那一步的行为** ⇒ **该步骤今天"非 PASS 只告警、不中止"**（`close-wave.sh:160`）⇒ 扩表之后**第一次跑很可能立刻 `rc=1`**（因为原来"看不见的件"现在会被判）。⇒ **扩表必须与"把这一步从告警升级为中止"分开决定**，否则会一次改动混进两种位移。 |
| **⑤ 阻塞项** | **`ITEMS` 与 `applocal-expect.py` 是两张表、必须同步**（两处注释逐字互相点名：「与 `check-applocal-sync.sh` 的 `ITEMS` 保持一致；改一处要同步另一处 —— 由 check 的 `--list-items` 校验」）⇒ 落地时必须**两侧同改**，并用 `--list-items` 证同步。<br>**另**：`check-applocal-sync.sh --selftest`（`:370+`，自检 A–M2）存在且能红 ⇒ **扩表后必须重跑自检**，否则是"改了仪器没校准"。 |
| **⑥ 价值排序** | **并列第 1（我建议下一波就做，与 F 条同波或紧邻）**。<br>**为什么值钱**：① 它是**本表里"最安静"的一条** —— **一份陈旧产物贴在探针旁边、没有任何判据看得见它**（`KNOWN-DEFECTS.md` 逐字：「这正是纪律 23「你以为你在量 A、其实你在量 B」的家族」）；② 成本极低（**加表项**）；③ 它命中的是纪律 37 的原话：「**"检查器没说话"是一种"读数为零"，不是"绿"**」；④ **它有一个"明天就会咬人"的形态** —— `D-R6` 已证 `pc` 的 sha **依赖构建路径** ⇒ 各宿主目录里那份 `PresentationCore.dll` **必然**会陈旧，而**今天没有人看着它们**。<br>**为什么与 F 条并列而非更高**：F 条买的是"能不能做预测"（阻塞其它件的能力），G-2 买的是"一个已知盲区"（不阻塞别的件）。 |

#### G-3 `D-A3` —— 拷贝点**枚举器**自身漏报（**20 个点只印 18 个**）

| 列 | 内容 |
|---|---|
| **① 现场锚点** | `KNOWN-DEFECTS.md` §`D-A3` 逐字：**20 个拷贝点里 17 个只读点判为无害、3 个写点全是真的洞** —— 它们今天"看着安静"**只因为副本恰好 sha 相同**（`libwpfwin32.so` **4/4** 份、`libwpfwic.so` **3/3** 份），**删掉或改旧都不会红**，其中**两处还用 `2>/dev/null \|\| true` 把失败吞掉**。<br>**枚举器自己的三个盲区（车道自曝，我核过其中两条）**：① **只印 18 个**（2 个只读点在统计里被静默丢掉）；② **只扫 `build/**/*.sh`** ⇒ 漏 **2 个 MSBuild `<Copy>` 目标** + **2 处桥保存/恢复**（`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh:179` / `:191`）；③ **只匹配字面文件名** ⇒ 漏 **13 处变量间接写入**，含 **`build/MilBridge/run.sh:210`**（`refresh_applocal`）与 **`build/close-wave.sh:130`**。<br>**我现场核对的两条（它们在盘上确实存在）**：`build/close-wave.sh:130` 逐字 = `cp -f "$NATIVE_AUTH" "$c"`（在 `while IFS= read -r c; do … done < <(find . -name 'libwpfwin32.so' …)` 循环里）；`build/MilBridge/run.sh:210` 在 `refresh_applocal` 一带（该函数名由 `docs/CURRENT-STATE.md` §4 两行逐字点名）。<br>**"枚举器"本体**：`applocal-expect.py`（`6eafbea14e7ea41e`）的 `invisible_*` 计数族（`:485` 的 `#SUMMARY|…|invisible_copysites=…|invisible_write=…|invisible_read=…|invisible_capped=…|invisible_ext_write=…|invisible_ext_read=…|invisible_indirect_write=…`）。 |
| **② 判据草案** | **判据（§4 逐字 + 我的具体化）**：写点必须**逐点**有"**该点产出什么 / 权威 sha 是多少 / 删掉或改旧能不能红**"三栏；**能吞掉失败的点必须报出来**（`2>/dev/null \|\| true` 这类写法**本身就是读数**）。<br>**可执行的形态**：给 `invisible_indirect_write`（那个**已经存在**的计数器）配一条**两极化实验**：把某个**漏报写点**的输出文件**改名**（不改内容）⇒ 枚举器**必须点名它**；今天**静默**。 |
| **③ 反极性（现状必须红）** | **红在"漏报的写点被注入一次 sha 变化后仍然静默"**。（§4 判据逐字：「**两极牙**：在任一漏报点注入一次 sha 变化 ⇒ 枚举器**必须点名它**（今天**静默**）」。）<br>**⚠️ 我没法在本车道独立验证"今天静默"**（要跑枚举器 + 改文件）⇒ **如实标注：这一格是引用 `TAPPS-blind-half-report.md`（`9071d4bcf39918b8`）的读数，未由我复取**。 |
| **④ 世代价** | **`无`**（检查器侧）。 |
| **⑤ 阻塞项** | **需要一个"注入一次 sha 变化"的沙盒**（本车道只读 ⇒ 不可做）；且**必须与 `D-A2` 的扩表分开做**（否则"枚举器漏报"与"表覆盖不足"两种位移混在一趟里 ⇒ 归因作废，纪律 20/41）。 |
| **⑥ 价值排序** | **并列第 1（但它与 G-2 是同一族的两个半边，建议同波、分两趟取数）**。<br>**为什么值钱**：它与 G-2 一起构成**完整的盲区闭环** —— **G-2 是"漏看的件"，G-3 是"漏看的写点"**；两个都补上，"**没有判据看着的产物**"这一类才会被关掉。而且 §4 已给出**最刺眼的一句**：「**"看不见的拷贝点"检测器自己也有洞**（它只报 3 个写点）」。<br>**为什么不是单独第 1**：它的**红证需要注入**，比 G-2 的"加表项 + 删件红"难一步。 |

### H. `D-E1` —— 为什么「不许顺手修」（我把它写成**判据 + 三条不可分离的理由**）

| 列 | 内容 |
|---|---|
| **① 现场锚点** | **上游（我方逐字编入，零应用器）**：`build/PresentationCore.Linux/PresentationCore.Linux.csproj:543` `<Compile Include="$(UpstreamWpfRoot)src/…/PresentationCore/System/Windows/Media/GlyphRun.cs" />`；`upstream/…/Media/GlyphRun.cs:1384` `if (CoreCompatibilityPreferences.GetIncludeAllInkInBoundingBox())` → **`:1389`** `double inflation = Math.Min(_renderingEmSize / 7.0, 1.0);` → `:1390` `bounds.Inflate(inflation, inflation);`；`:1392-1400` **else 支**（`Display` 模式 ⇒ `Inflate(1.0, 1.0)`，注释逐字 `user opted out of the fix - this is the 4.0 code`）。<br>**开关的默认值（我实测核过，文献里没写）**：`upstream/…/CoreCompatibilityPreferences.cs:95` `private static bool _includeAllInkInBoundingBox = true;` ⇒ **Linux 上默认走 Inflate 支**；`:115-120` `GetIncludeAllInkInBoundingBox()` 会先 `Seal()`（⇒ 一旦有人读过它，**之后 `set` 会抛 `InvalidOperationException`** —— 这是个"顺序敏感"的细节，做判据时要知道）。<br>**我方不做**：`build/shims/PresentationCore.HbTextLine.cs` 的 **`grep -n Inflate` = 0 命中**（同一 pattern 的正对照 = 上游那份 `:1390`）；自述在 **`shim:3342`**（逐字 `⭐ 真机语义 = **本行墨迹的黑色高度**（ink box height），**不是行高**。`）。<br>**"零应用器"的正对照**：`grep -n 'GlyphRun' src/WpfGfx.Linux.Native/tools/patch-*.py` = **0 命中**，而 `TextFormatterImp` 命中 1 个文件 ⇒ **不是"没扫到"，是"确实没有锚点"**。<br>**在册的量（引用，未由我复取）**：实测 **1252/1544 行**满足「真值 = 我们的控制框并集高 + **2.0000 DIP**」（`docs/CURRENT-STATE.md` §4 `D-E1` 行逐字）。 |
| **② 判据草案** | **§4 已给（我照录并补可执行细节）**：造 `em = 7/14/21/28` 的用例 ⇒ 偏置应为 `2·min(em/7, 1)`（em≤7 ⇒ **随 em 线性** `2·em/7`；em≥7 ⇒ **恒 2.0 封顶**）。<br>**取数位置**：`tline` 的 `Extent` 明细（`gen/tline-detail-full.txt` 一族）或 `CoverageProbe --inkdiag`（`KNOWN-DEFECTS.md` 逐字：`Program.cs … :285-345` 逐 run 打 `inkBox/Top/Bottom/h`、`face=<路径>#<下标>`、`glyphIds`、`tsb/bsb`）。<br>**期望值来源**：**上游公式本身**（`GlyphRun.cs:1389`）⇒ 这是**契约级判据，不需要 Windows 真机重录**（比 `D-T4` 便宜得多）。 |
| **③ 反极性（现状必须红）** | **§4 逐字**：「反极性 = 现状必给出 **0**（不打平）」。<br>**可判形态**：同一段落、只改 `em`，我方 `Extent` **逐位不变**（偏置恒 0），而按公式应差 `2·min(em/7,1)` ⇒ **`em=7` 与 `em=14` 两例的偏置差 = 1.0 DIP**（可判、不是小数）。<br>**⚠️ 但红证今天不可直接取** —— 见 ⑤。 |
| **④ 世代价** | **如果真修：`shim-HbTextLine`（若在 shim 侧加 Inflate）或"改上游的编译输入"（若给 `GlyphRun.cs` 加应用器）⇒ 两者都要付一次波；前者还付门禁重钉。**<br>**本报告的建议：`无`（本波不做）。** |
| **⑤ 阻塞项 + 「为什么不许顺手修」（三条，**必须一起读**）** | **(1) 它会一次性冲掉一整代归因。** `Extent` 余差 **95 条**（`known-red.json` 里**已登记成在册红**：`{"arm":"tline","case_id":"T2d-Extent余差","field":"Extent余差条数","expected_shape":"count==95"}`）**全部**建在"我方不做 Inflate"这个前提上；一改 ⇒ **95 条同时位移** ⇒ `#16` 那一整轮的 `+36` 归因（`PLUS36-NARROW.md`）**与 `#19` 的 tline 复现读数全部作废**。<br> **(2) 它的"我方值"本身是别的缺陷的产物** —— `docs/CURRENT-STATE.md` §4 的归因精化条逐字：「**T1d 的自我更正**…准确表述 = **"我没改并集的代码，但我改了并集的输入"**」⇒ 先修 `D-E1` 会让"并集的输入"（哪些 run/面/字形存在，正被 `D-F1`/`D-F1b`/`D-F2` 改动）与"并集的算法"**同时变** ⇒ **两族齐变 ⇒ 归因作废**（`D-T2` 的预登记纪律逐字："同一读数两族齐变 ⇒ 该结论作废"）。<br> **(3) 它是"系统性偏置"，最容易被当成判定口径问题而被顺手改掉** —— 修它必须**先**有一条"能把它与 `D-F1`/`D-F1b` 分开取数"的臂（今天是 `tline` 的 Extent 明细，混着 `+CJK`/`tab` 两族）。<br> **(4) 一个今天还没被登记的细节**：`upstream/…/CoreCompatibilityPreferences.cs:115-120` 的 `Seal()` ⇒ **判据若先把 `_includeAllInkInBoundingBox` 读一遍，之后任何 `set` 都会抛** ⇒ 想用"把开关设 false 做反极性"这条路的人**会踩到一个 `InvalidOperationException`**（该异常**不等于判据失败**，是装置顺序问题）。 |
| **⑥ 价值排序** | **第 9 位（明确"本波与下一波都不做"）**。<br>**理由**：它是**唯一一条"修了会让在册红表与一整轮归因同时失效"的条目** ⇒ 属于"**必须先有隔离臂，再有修法**"的典型。**建议**：本表只为它保留**判据草案**（②）与**前置**（"造一条只动 `em`、不动 run/面集合的臂"），**修法排到 `D-F1`/`D-F1b`/`D-F2` 全部落定之后**。 |

---

## §5 建议下一波先做哪三件（给理由）

### 🥇 第 1 件：把 `HbFallbackDiag` 的 **3 个"只自增、无出口"计数器**接出出口（`D-F2` 第一步 + 本报告的 F′ 延伸）

- **它买的不是"一个数"，是"能不能写位移预测"这个能力** —— `KNOWN-DEFECTS.md` §② 逐字把缺这个读数列为"**与「逐件先写死预测」的纪律冲突**"⇒ 这是**阻塞别的件**的前置。
- **成本极低**：`SummaryFragment()`（`shim:1344-1379`）里加 3 个 `Append` ≈ **3–4 行、零语义**。
- **为什么必须是"下一波"而不是"随手"**：**它要付世代成本**（改 `PresentationCore.HbTextLine.cs` ⇒ 五臂重取 + `known-red.json` 重钉，纪律 31/34）。⇒ **应作为"下一次动 shim 的那一波"的首件**，与 `D-T5`(乙)/`D-T4`(乙)/`D-F1c`①c 同波摊薄那笔成本。
- **顺带修掉一条假自述**：`ScanCapped` 的注释自称"诊断行报 `capped=`"而全仓无出口 ⇒ **接线后注释才成真**（否则就是 `L25` 同族：**判据把缺陷写成了预期**）。

### 🥈 第 2 件：补 `D-A2` 的**间接依赖副本盲区**（`ITEMS` 扩表 + `.so` 真权威 + `SCAN_ROOTS` 覆盖）

- **它是本表里"最安静"的洞**：`FallbackCriteria/bin/Debug/` 里 **17 个 DLL 只有 2 个被判定**、检查器输出里 `grep -c PresentationCore.dll` = **0**；**一份陈旧产物贴在探针旁边，没有任何判据看得见它**。
- **成本极低**：加表项 + 给 `wpfgfx_cor3.so` 一个真权威（= 九位里的 `bridge`）+ 扩 `SCAN_ROOTS`；**世代价 `无`**。
- **它有一条"明天就会咬人"的机制**：`D-R6` 已实测 **`pc` 的 sha 依赖构建路径**（同源、三个不同输出目录 ⇒ 三个不同 sha）⇒ 各宿主目录里那份 `PresentationCore.dll` **必然**会陈旧，而**今天没有任何判据看着它**。这正是纪律 37 的原话现场（"检查器没说话 = 读数为零，不是绿"）。
- **必须的分步（否则归因作废）**：**扩表 / 升级为中止 / `D-A3` 的枚举器红证** 三件事**分开取数**；`ITEMS` 两侧（`check-applocal-sync.sh` 与 `applocal-expect.py`）必须**同改**并用 `--list-items` 证同步；改完**重跑 `--selftest`**。

### 🥉 第 3 件：`D-R3` 残项 (iii) —— **判据① 的修前对照**（唯一一条"判据本身从未被验过"）

- **它是唯一一条会静默漂的"判据层"欠账**：`KNOWN-DEFECTS.md` §⑩ 逐字「判据① 不再由守卫行使（`realcall` 直测 `REAL_DLLIMPORT=OK`，但**① 的修前对照没测过**）」⇒ 我们**不知道它变红了意味着什么** —— 可能它**修前也 OK** ⇒ **恒绿** ⇒ 按纪律 3/21，**它不算判据**。
- **成本极低 + 有保质期**：修前件在 `$HOME/wfp-runs/w18-pre/` 一带（`*.before` 命名，`#18` 报告 §产出）；而本机 `$HOME` **曾被整盘清过一次**（`docs/CURRENT-STATE.md` §6 逐字提到该教训）⇒ **越晚做越可能永久失去修前对照**（届时只能重建修前件 ⇒ 付一次波 + 世代价）。
- **它顺手回答一个更宽的问题**：`#18` 那次"**按段数口径收窄自证**"的代价**到底买到了什么** —— 收窄前/后各跑一次 `realcall`，就能把"判据① 换手"这件事**变成一条读数**，而不是一句登记。

### 未入选但排在第 4–5 位的两件（说明为什么）

- **`D-T5`（真 modifier 段落交回 LS）**：**产品缺陷里最"真"的一条**，但它的第一格是"**异常会不会传到应用层**"（`KNOWN-DEFECTS.md` 逐字列为未测）—— 那是**一条读数**，不是一件工程。**建议**：下一波**只取这一条读数**（一次性、廉价），**若传到应用层 ⇒ 立刻升为第 1 件**（崩溃级）。
- **`#19` 严格档腿接线（§3.1）**：**结论上最值钱**（它把"`#19` 的实质"从文字变成判据），但它的**前置是"世代绑定扩到每臂仪器 sha 表"**（纪律 34 的登记改进方向）⇒ 那是**改门禁本身**，权属与风险都大 ⇒ **建议由主控单独排一波**，而不是塞进 P1/P2/P3/P4 的任何一件里。

---

## §6 我推翻 / 更正的文档陈述（**逐条带原始证据**）

> 纪律：文档过期是**发现**，不是小事。以下三条**都不是我的推测**，是盘上文件逐行读出来的。

### §6.1 `docs/CURRENT-STATE.md` §4 的 `D-E1` 行：**两处行号已过期**（内容成立，锚点不成立）

- **原文逐字**（§4 `D-E1` 行）：「上游 `upstream/…/Media/GlyphRun.cs:**1378-1386**` 逐字 `double inflation = Math.Min(_renderingEmSize / 7.0, 1.0); bounds.Inflate(inflation, inflation);`」＋「**我方 shim 不做**（`shim:**3286**` 逐字自述"真机语义 = **本行墨迹的黑色高度**（ink box height），**不是行高**"）」。
- **现场**：`grep -n 'double inflation = Math.Min' upstream/…/GlyphRun.cs` ⇒ **`:1389`**（条件在 `:1384`，`bounds.Inflate` 在 `:1390`）⇒ 原引的 `:1378-1386` 是**注释段**，不是那两行代码。
  `sed -n '3286p' build/shims/PresentationCore.HbTextLine.cs` ⇒ **`internal string LineDumpTuple(int seq)`**；那句 `⭐ 真机语义 = …` 已在 **`:3342`**。
- **性质**：**引用漂移**（纪律 4 的现场：行号随版本位移 ⇒ 引用前现场重读）。**结论本身没有被推翻**（我方 shim `grep -n Inflate` = 0 命中，实测）。
- **附带**：我另外**补上了一个文献里没有的关键事实** —— `CoreCompatibilityPreferences.cs:95` `private static bool _includeAllInkInBoundingBox = true;` ⇒ **Linux 上默认走 Inflate 支**（没有这个默认值，`D-E1` 的"系统偏置"预测就悬空）。

### §6.2 `KNOWN-DEFECTS.md`（`#16` T17A 节 + `ScanCapped` 两处注释）：**「可观测…诊断行报 `capped=`」这句自述是假的**

- **原文逐字**（`shim:1067`）：`/// <summary>D-F1c/B4：扫描面数上限（可观测；超限 ⇒ NoteScanCapped() + 诊断行 capped=）。</summary>`；（`shim:1271`）：`/// D-F1c/B4：扫描因触上限而截断的次数（可观测；诊断行报 capped=）。`
- **现场**：`grep -rn 'capped=' build/ src/ samples/ tests/ --include=*.cs --include=*.py --include=*.sh` ⇒ **全部命中 = 4 行**（三行 `shim` 注释 + 一行变量赋值，逐条见上）；`ScanCapped` 全仓 **4 处** = 声明（`:1272`）、自增器（`:1273`）、自增调用（`:1147`）、以及 `:1067` 的注释 ⇒ **零打印点**。`SummaryFragment()`（`:1344-1379`）逐个 `Append` 核过，**没有它**。
- **正对照（纪律 25 要求）**：同形 pattern `invisible_capped=` **存在且非 0**，但它属于**另一个仪器**（`build/DirectWrite.Linux/wic-shim/applocal-expect.py:485` 的 `#SUMMARY|…|invisible_capped=…`）⇒ **不能拿它当 `capped=` 的对照**；`capped=` 的 0 是**真 0**。
- **性质**：**能力自述为假**（与 `L25` 同族：**把缺陷写成预期**）。
- **同一族的第二个（§6.2b）**：`RunFaceSlotMissing`（`:1278-1279`，自增点 `:2782`，注释逐字「**不许静默**」）与 `SegmentFaceUnresolved`（`:1275-1276`，自增点 `:3831`，注释逐字「**不许静默**」）**同样零打印点** ⇒ **三条"不许静默"的计数器，全部静默**。

### §6.3 `ACCEPTANCE-BASELINE.md` 表头 §⑩ 记的仪器 sha 与现场不符（**不是文档错，是"仪器在冻结后又被改了"**）

- **表头逐字**（`f5d8a6f1cdf49635` §⑩）：「`build/MilBridge/tests/PcLineOracle/Program.cs` **`a46e5e046583f69a`**（加 `--tier auto|strict|lenient` + 档位感知正控 + 逐例层级归因）」。
- **现场**：`sha256sum build/MilBridge/tests/PcLineOracle/Program.cs | cut -c1-16` ⇒ **`19f9e7e78e9bb5c7`**（90,087 B、mtime **2026-09-16 16:24:47**）⇒ **≠ `a46e5e046583f69a`**。
- **机制（可复算）**：`W20A` 车道在同一文件上加了 `D-T6` 的**守卫**（`--guard off|label|enforce` + `--guard-conv abs|line`，见 `KNOWN-DEFECTS.md` 的 `D-T6` 定性条逐字：「**守卫已落（臂侧）**…⚠️ **照 sha 比对臂输出的旧配方请加 `--guard off`**」）⇒ **仪器在 `#19` 冻结之后被改过**。
- **性质**：**不是"表头写错了"**，而是**纪律 35 的又一个现场**（"读数之后仪器变了"⇒ 作废的是**配对**，不是读数）。⇒ **正确的写法**：引用 `#19` 的臂读数时**必须写"仪器 = `a46e5e046583f69a`（`#19` 冻结时）"**，而**重跑今天的臂会得到不同的输出**。
- **⚠️ 一条真实的后果（我建议登记）**：`PcLineOracle/Program.cs` **不在门的世代绑定三项里**（`GEN_KEYS`，`tline-gate.sh:234`）⇒ **W20A 改它没有触发任何东西变红** —— 这正是纪律 34 的**第 N 个实例**（"改仪器却不动世代绑定是一个真空档"）。**它今天比 `#16` 时更紧迫**，因为现在有**两个**探针（`CoverageProbe`、`PcLineOracle`）+ 一个 `StrictTierProbe` 都在这个真空档里。

### §6.4 一条**新的**（不是更正，是"文档里不存在"）：`StrictTierProbe` 未进任何冻结文档

- **现场**：`build/MilBridge/tests/StrictTierProbe/`（`Program.cs` **`d628ce429240b37c`**、23,557 B、mtime `2026-09-16 16:19:24`；`StrictTierProbe.csproj` 3,476 B、`16:18`）。
- **它的自述**（`Program.cs:1-3` 逐字）：`// W20A · **D-T6 定性探针**（docs/WAVE20-PREREGISTRATION.md §1 的「决定性实验」仪器）`；`:16` 逐字 `// 它**不**判分、**不**写任何判据表：定性结论由 PcLineOracle 的守卫与 W20A-report.md 给。`
- **缺口**：它**不在** `ACCEPTANCE-BASELINE.md` §⑩ 的仪器版本清单里、**不在** `verify-all.sh`、**不在** `tline-gate.sh`、**不在** `known-red.json`。⇒ **`D-T6` 的 `ARM/DEVICE` 定性（`W20A-report.md` `3a51800d36bb7007`，41,129 B、`16:32:25`）目前无法被冻树复算** —— 它依赖的仪器**没有版本来源**。

---

### §6.5 ⚠️ **本次盘点期间（18:20→18:28）有四份件被别的车道改动** —— 如实记，并说明它对本报告的哪些句子有影响

我按纪律 32/15 在**收官时重算**参与本报告的每一份件的 sha16（而不是收盘时用开工时的数），结果如下 —— **四份都动了**：

| 件 | 我读到的（本次盘点中） | 收官重算（`18:27–18:28`） | 影响 |
|---|---|---|---|
| `docs/WAVE21-PREREGISTRATION.md` | `9d1e2dddda5b24e8`（14,390 B、`18:22:03`） | **`127be0d931d97adf`**（20,376 B、**`18:25:24`**） | **新增 `§10 预登记补遗`（`§10.1`–`§10.4`）** ⇒ **我的 §2/§3 结论被主控独立查到同一处**（见下） |
| `build/MilBridge/tests/PcLineOracle/Program.cs` | `19f9e7e78e9bb5c7`（90,087 B、`16:24:47`） | **`2de164b93a2c29fa`**（102,378 B、**`18:27:43`**） | **同一份臂仪器在一个小时内改了两次**（16:24:47 是 W20A 的守卫；18:27:43 是 `#21` P1 落新判据列）⇒ §6.3 的"仪器漂移"结论**被加强**，不是被削弱 |
| `build/MilBridge/tools/pc-line-step.sh` | **不存在** | **`3f8d26ab077d2ec1`**（4,085 B、**`18:26:33`**） | 主控新写的"桥"（把 PC 侧行对拍接进 `verify-all`）⇒ **它是对本报告 §3.1 的正面回应**；**但截至收官它仍未接进 `verify-all.sh`**（我收官前重跑 `grep -n 'pc-line-step\|PcLineOracle' verify-all.sh build/MilBridge/tools/tline-gate.sh` ⇒ **0 命中**，退出码 1） |
| `build/MilBridge/arm-logs/README.md` | （我没有引用它） | **`7de8a8cb069be60a`**（7,282 B、`18:25:29`） | 预登记新增的 **`§10.4` 正登记它有一处"软链/硬链"自相矛盾的文档债务**（`README.md:24` 说软链，而同文件 `:3-8`/`:60-64` 明令 `ln -f` 硬链） |

**这三个新事实里有一条**对**本报告的结论有实质影响**（我如实写出，**不偷偷改结论让人以为我原来就说对了**）：

> **预登记 `§10.3` 第 2 项** = 主控在 `18:25:24` **独立查到了与我 §0 结论 1 / §3 完全同一处的结构性缺口**，逐字：
> 「**新判据不在冻树回路里**：`PcLineOracle` 自述"本臂不是五臂门禁成员、不进 `verify-all`"（`Program.cs:463`），而五臂门禁是**只读读者**（不跑 harness）⇒ 只把比较加进 `PcLineOracle` 的话，**`verify-all` 仍然量不到它**。⇒ 本波**先落判据**（保证有判别力），**接线**按 **W21D 的"最小接线方案"** 在波尾评估；若本波不接线，**必须在 `CURRENT-STATE.md` 明确写"该判据当前不在冻树回路内"**（不许让它看起来像已守）。」

⇒ **对本人结论的三点处置**：
1. **"缺口存在"这一结论不变**，且现在**有两份独立发现**（我的 §3 + 主控 `§10.3`）⇒ 更强。
2. **它的处置也不同了**：主控已经**拍了处置顺序**（"先落判据 ⇒ 接线在波尾评估 ⇒ 若不接线必须显式登记为『不在冻树回路内』"），并且**已经写了桥**（`pc-line-step.sh`）⇒ **我的 §3.1 从"建议"变成"已被采纳并在执行"**。§3.1 里那条"接线后哪一步会先红"的**可证伪预测仍然有效**（未接线前不会红）。
3. **我的 §3.1 第 2 条前置（世代绑定扩到"每臂仪器 sha 表"）现在更硬**：`PcLineOracle/Program.cs` **一小时改了两次**（`a46e5e046583f69a` → `19f9e7e78e9bb5c7` → `2de164b93a2c29fa`），而这三次**一次都没有触发任何东西变红**（`GEN_KEYS` 三项里没有它）⇒ **"改仪器不重取"这条真空档在这个波里已经发生了三次**。
4. **`§10.3` 第 1 项还补了我没查到的一格**（我如实标注为**我的缺口**）：三支 tab 臂的宿主 `CoverageProbe/Program.cs` **一个 `lineStartOffsetsDip` / `.Start` 引用都没有** ⇒ 语料里**一直躺着 615 个真值，而门禁从来没看过它** —— 这是 `D-T6-c` 能长期存活的**结构性原因**。**我的 §3 只写到"这些臂在 `verify-all` 之外"，没写到"它们在门的射程内、只是不看那个字段"** —— 后者更准、更值钱。

**一条元教训（与本项目文化一致，留档）**：我在开工时按纪律 32 记了 `loadavg`/`mem_available`/`kernel`，但**只在开工时**记了件 sha；收官重算才发现**四份件在 30 分钟内全动过**。⇒ **"读数表"必须在收官时重算一遍**，否则它记的是"我以为的现场"，不是"我量过的现场"（纪律 15/24 的又一次现场）。

---

## §7 读数表（纪律 32：谁跑的、哪一份件、什么时候 —— **件 sha 一律以收官重算为准**）

| 项 | 值 |
|---|---|
| `lane` | **W21D** |
| 日期时间 | `2026-09-16 18:22:49 +0800`（开工实读）→ **`18:28:12`（收官重算件 sha）** |
| `loadavg` | **0.24 0.15 0.06**（`/proc/loadavg`，1/5/15 分钟） |
| `mem_available` | **3737212 kB**（`/proc/meminfo`） |
| `kernel` | **6.8.0-138-generic** |
| `nproc` | 3（预登记 §0 硬约束） |
| 冻结基线 | `#19`，`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **`f5d8a6f1cdf49635`**（173,415 B、mtime `2026-09-16 15:55:50`） |
| `docs/WAVE21-PREREGISTRATION.md` | **`9d1e2dddda5b24e8`**（14,390 B、`18:22:03`）—— ⚠️ **我在 18:22 读的就是这一版；18:25:24 它被主控改成 `127be0d931d97adf`（20,376 B，新增 §10 补遗）** ⇒ 见 §6.5 |
| `docs/CURRENT-STATE.md` | **`a0463319bf6bad70`**（203,397 B、`16:35:23`） |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **`f1351506adf4dbc7`**（135,081 B、`16:35:42`） |
| `verify-all.sh` | **`a68823631e8f8919`**（9,847 B、`2026-09-15 16:44:49`） |
| 冻树 `verify-all` 日志 | `$HOME/wfp-runs/w19-pre/verify-all-19.out`（1,254 B、`15:47`）⇒ `步骤通过 10 / 失败 0 / 用例通过 871 / 跳过 2` |
| `build/shims/PresentationCore.HbTextLine.cs` | **`fe1b7ed8fa3ed231`**（278,692 B、`2026-09-16 15:30:15`） |
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（生成物） | **`799e0366b312ec65`**（55,223 B、`15:31:51`） |
| `build/MilBridge/tests/PcLineOracle/Program.cs` | **`19f9e7e78e9bb5c7`**（90,087 B、`16:24:47`）**≠ 表头 §⑩ 记的 `a46e5e046583f69a`**（见 §6.3）；**且在本次盘点期间又被改成 `2de164b93a2c29fa`（102,378 B、`18:27:43`）⇒ 见 §6.5** |
| `build/MilBridge/tools/pc-line-step.sh`（**新件，本报告盘点期间出现**） | **`3f8d26ab077d2ec1`**（4,085 B、`18:26:33`）—— 主控写的"把 PC 侧行对拍接进 `verify-all` 的桥"，**尚未接进 `verify-all.sh`**（`grep -n 'pc-line-step\|PcLineOracle' verify-all.sh` 仍 **0 命中**）⇒ 见 §6.5 |
| `build/MilBridge/arm-logs/README.md` | **`7de8a8cb069be60a`**（7,282 B、`18:25:29`）—— 被改过（原 `6924605fab87660e`；**预登记 §10.4 已登记它为文档债务**，见 §6.5） |
| `build/MilBridge/tests/PcLineOracle/known-red.txt` | **`89324f1f643167e5`**（17,501 B、`12:00:16`） |
| `build/MilBridge/tests/StrictTierProbe/Program.cs` | **`d628ce429240b37c`**（23,557 B、`16:19:24`） |
| `build/MilBridge/tests/CoverageProbe/Program.cs` | **`a8727a5bed6bf049`**（108,127 B、`2026-09-15 17:24:40`） |
| `build/MilBridge/tools/tline-gate.sh` | **`b37a5c9f55ae71a4`**（40,181 B、`2026-09-15 16:44:01`） |
| `build/MilBridge/known-red.json` | **`3bf26e12f320dece`**（29,546 B、`15:46:02`；`generation.id=#19`、`entries=4`、`instr_shim=fe1b7ed8…`、`instr_run_sh=3e513e88…`、`instr_program_cs=2e458928…`、`instr_pc=f4a454c8fe69cdfe`） |
| `build/DirectWrite.Linux/wic-shim/applocal-expect.py` | **`6eafbea14e7ea41e`**（27,314 B、`2026-09-15 18:49:02`） |
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | **`aad23482f84bdf44`**（55,520 B、`18:49:36`） |
| `build/DirectWrite.Linux/FallbackCriteria/mem-sampler.sh` | **`09e5bab7c3d246f6`**（9,850 B、`2026-09-15 12:32:17`） |
| `build/DirectWrite.Linux/FallbackCriteria/seg-sampler.py` | **`9934771b1bff861b`**（13,522 B、`16:40:47`） |
| `build/DirectWrite.Linux/FallbackCriteria/eval-df1-criteria.py` | **`fc808896f23390f4`**（31,870 B、`12:16:46`） |
| `build/DirectWrite.Linux/evidence/mem-D-F1c/INDEX.md` | **`bc8ec2f78aa99530`**（`D-F1c` 主判据与复取配方写死处） |
| `build/check-fp-polarity.sh` | **`f91d12bed2494889`**（3,732 B、`2026-09-15 12:51:38`） |
| `build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt` | **`dcafc3e38afeab26`**；内含 **35** 行 `file=`，其中 `file=fe1b7ed8fa3ed231  build/shims/PresentationCore.HbTextLine.cs` ⇒ **逐文件行已落地**（`ARTIFACT-SRC-FP` 缺逐文件行那条登记**已修**） |
| `build/MilBridge/W20A-report.md` / `W20B-report.md` | **`3a51800d36bb7007`**（41,129 B、`16:32:25`）/**`ff9e599897f9c90a`**（30,425 B、`16:20:32`） |
| 本报告 | `build/MilBridge/W21D-report.md`（sha16 见最终回复） |
| **跑了什么** | 只读：`read` / `grep` / `sha256sum` / `stat` / `python3 -c`（读 JSON、做算术）。**零 `dotnet`、零构建、零运行期读数** |
| **改了仓库里的什么** | **只有本文件**（`build/MilBridge/W21D-report.md`，新建）。既有文件零改动 |

---

## §8 我**没能**建立的（不许当绿）

| 项 | 为什么没建立 | 要什么才能建立 |
|---|---|---|
| `D-T5` 的异常**会不会传到应用层** | 需要跑宿主（本车道禁 `dotnet`） | 一条 `PcLineOracle`/新探针上的读数（**廉价、建议下一波先取**） |
| 上游 `pf`/`pc` 对 `TextEndOfSegment` 的**正常用法**会不会命中 | 只做了 `grep`（`TextModifier.cs`/`TextEndOfSegment.cs` 的定义侧），**没有静态枚举全仓 `new TextEndOfSegment(` / 派生 `TextModifier` 的调用点**（时间/范围取舍） | 一次全仓枚举（可做，未做 —— 我如实标出，**没做就是没做**） |
| `D-F1c`①c 的"3 段" | 那是 `#15` 阶段（件 `b5118424dc977aef`）的读数；现树 shim 是 `fe1b7ed8fa3ed231`⇒ **未在当代树上复取** | `seg-sampler.py` + `mem-sampler.sh`（要跑进程） |
| `D-A3` 的"今天静默" | 需要注入 sha 变化（改文件）⇒ 超出只读边界 | 一个沙盒 + 一次注入实验 |
| `D-R3`(i)(ii) 的任何读数 | 需要真宿主 / AOT 镜像运行 | 见 §4 D-1/D-2 的 ⑤ |
| `D-E1` 的 1252/1544 这条量 | 我**引用了** `docs/CURRENT-STATE.md` §4 的读数，**没有复取** | `tline` 的 Extent 明细（要跑 harness） |
| "`#19` 的严格档腿现在还是不是那些数" | 臂已被 W20A 改过（§6.3）⇒ **旧输出不可复现**；且要跑臂 | `--guard off` 重跑（要跑进程） |
| `verify-all.sh` 的"10 步"在**接线后**会变成几步 | 接线是主控的决定；我只给最小方案 | 主控决定 + 一次冻树实测 |

---

## §9 复算本报告的关键一行（"你说的是真的吗"）

```bash
# 1) 冻结件与仪器身份
sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md docs/WAVE21-PREREGISTRATION.md \
          docs/CURRENT-STATE.md verify-all.sh build/MilBridge/tools/tline-gate.sh \
          build/MilBridge/known-red.json build/shims/PresentationCore.HbTextLine.cs \
          build/MilBridge/tests/PcLineOracle/Program.cs | cut -c1-16

# 2) §0 结论 1：严格档腿不在冻树上（ARMS 五项里没有 PcLineOracle）
grep -n 'ARMS=(' build/MilBridge/tools/tline-gate.sh            # → :91
grep -n 'GEN_KEYS' build/MilBridge/tools/tline-gate.sh          # → :234（只绑三项）

# 3) §6.1：D-E1 的两处锚点已漂
grep -n 'double inflation = Math.Min' upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/GlyphRun.cs   # → 1389
grep -n 'private static bool _includeAllInkInBoundingBox' upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/CoreCompatibilityPreferences.cs  # → 95 = true
sed -n '3342p' build/shims/PresentationCore.HbTextLine.cs        # → ⭐ 真机语义 = 本行墨迹的黑色高度
grep -c 'Inflate' build/shims/PresentationCore.HbTextLine.cs     # → 0（我方不做）

# 4) §6.2 / F′：三个"不许静默"的计数器全部静默（正对照见括号）
grep -rn 'SegmentFaceUnresolved' build/shims/PresentationCore.HbTextLine.cs    # → 3 处，零打印
grep -rn 'RunFaceSlotMissing'    build/shims/PresentationCore.HbTextLine.cs    # → 4 处，零打印
grep -rn 'capped=' build/ src/ samples/ tests/ --include=*.cs --include=*.py --include=*.sh  # → 4 行：3 行 shim 注释 + 1 行变量赋值（**真 0 个打印点**）
grep -rn 'invisible_capped=' build/                                            # → 非 0（别处的正对照：applocal-expect.py:485 / check-applocal-sync.sh:590,:596）

# 5) §6.3：表头记的臂 sha 与现场不同
sha256sum build/MilBridge/tests/PcLineOracle/Program.cs | cut -c1-16   # → 19f9e7e78e9bb5c7
grep -n 'PcLineOracle/Program.cs' samples/WpfTextDemo/ACCEPTANCE-BASELINE.md  # → a46e5e046583f69a（#19 冻结时）

# 6) §4-G-2：ITEMS 只有 5 个有效件 + 桥无权威
sed -n '42,48p' build/DirectWrite.Linux/wic-shim/applocal-expect.py            # → wpfgfx_cor3.so 的权威串是 ""
grep -n 'SCAN_ROOTS=' build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh  # → :93（.artifacts 不在）
```
