# 车道 `W25A` 报告 —— `D-T5-R` 修法（"全隐形段落" `hiddenonly` 仍 abort）

- **lane = W25A**｜日期时间：**2026-09-17 12:23 → 13:00 +0800**｜`kernel 6.8.0-138-generic`｜`nproc=3`
- `loadavg`：开工 **0.49 / 0.26 / 0.21**｜峰值 **12.49**（12:37:08，本车道构建 + 另一车道）｜收工 **3.80 / 2.90 / 3.33**
- `MemAvailable`：开工 **3,567 MB**｜最低 **2,283 MB**（收工实测）｜收工 **2,283 MB**；`SwapFree` 759 → 593 MB
- 采样信封（主控采样器 `$HOME/w25-mem.log`，74 有效样本 12:23:37→13:00:10）：最低 `MemAvailable` **2,381 MB**、最低 `SwapFree` **537 MB**
- **零 `pkill`**、**零 `pgrep -f` 下结论**｜收工 `ps -eo args | grep -c '^dotnet'` = **0**

---

## §0 结论摘要（先结论，证据在后）

| # | 结论 | 置信 |
|---|---|---|
| 1 | **`D-T5-R` 已修好**：`hiddenonly` 四格（`strict`/`lenient` × 带 catch/`--nocatch`）全部 **`rc=0` ∧ `A1/A2/A3` 全 `PASS`**（修前：`rc=1`/`RED-EXC-LS` 与 `rc=134`）。 | **proven（实测）** |
| 2 | 修法**只在应用器**：`patch-presentationcore-textline-fallback.py`（`536f58b338a2369d`→`64cac206bf10635f`）⇒ 生成物 `a6f1b678ce87a8a2`→`a433f38aaabe43b4` ⇒ `pc 476994e35d31a7e1`→**`7374308a00c55572`**。**`hbtextline` 一个字节未动 = `e89fed55fd8e32bc`** ⇒ **零世代成本成立**（停条件 1 未触发）。 | **proven** |
| 3 | **机制**：修前 `lastFail="没有 run properties"`（生成物 `:243-248`）；修后该串消失、`lastFail="-"`，且**新计数器 `relaxedParaDefaults` 由 0 → 1** ⇒ 兜底分支**真的执行了**（不是"接了线没生效"）。 | **proven（实测）** |
| 4 | **三级反极性全部拿到**：① 牙级假修 ⇒ 应用器 `rc=1` 且**生成物没写盘**；② 返空串假修 ⇒ **`A3` 红**（`RED-LENGTH` `Σ可见长=2 期望=3`）；③ 半接线假修 ⇒ **仍红**（`RED-EXC-LS`/`134`，`relaxedParaDefaults=0`），且**计数牙齿 `n_default_src` 当场把它抓成 `0 ≠ 2`**。 | **proven（实测）** |
| 5 | **回退证**：`cp -p` 复原应用器 ⇒ 生成物逐字节回到 `a6f1b678ce87a8a2` ⇒ `pc` **`cmp` 逐字节回到 `476994e35d31a7e1`**（与 `#24` 留档 `IDENTICAL`）；再恢复真修态 ⇒ 回到 `7374308a00c55572`（往返闭合）。 | **proven** |
| 6 | **位移**：九位中**只有 `pc` 变**，其余八位**逐位未变**（`hbtextline` 见上）；`inputs_fp` `a8703419…`→`0b8b6559…`（**唯一变化组 = G1 `patch-*.py`**）。**§2 位移表外位移：无。** | **proven** |
| 7 | **零射程**：12 组阳性对照/已绿用例（`control`/`mod0`/`eos1`/`mod1`/`hidden1`/`hiddenmid` × 两档）**归一化后逐字节相同**（汇总 sha16 `a06e28003c107cba` == `a06e28003c107cba`）；`PcLineOracle` 修前/修后 1,480 行**只差 2 行**（都是新增诊断字段）；`frame-step.sh` **`FRAME_STEP=PASS`**、`帧红=0`、`结构红=3`（与 `#24` 同值）。 | **proven** |
| 8 | ⚠️ **判别力边界**：`A1/A2/A3` 对"占位字符是否**真零宽**"**零判别力**；冻结语料**不含全隐形段落** ⇒ **"能否转绿"可测、"转绿是否对"本仓不可测**（需 `D-T7` 真机重录）。**本车道的绿 ≠ 隐形语义已正确。** | **proven（读码 + 读数）** |
| 9 | 我**推翻**了侦察报告 `d-t5r-plan.md` 附 A5 的一句话（具名实参位置）与 `W25A` 派单里"`--selftest` 先跑一次"之外的两处口径 ⇒ 见 §8。 | **proven** |

---

## §1 我的写域清单 + 每条改动的 before/after sha16

| 件 | 路径 | before sha16 | after sha16 | B before → after |
|---|---|---|---|---|
| **应用器**（写域） | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` | **`536f58b338a2369d`** | **`64cac206bf10635f`** | 61,044 → 75,340 |
| **生成物**（应用器产物） | `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | **`a6f1b678ce87a8a2`** | **`a433f38aaabe43b4`** | 60,034 → 65,892 |
| **`pc`**（重建） | `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | **`476994e35d31a7e1`** | **`7374308a00c55572`** | 4,197,376 → 4,197,888 |
| **`inputs_fp`** | — | `a87034194a66f7d18a9903a06337ad839cae8dba2669736abbec9cd8f6dee793` | `0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8` | — |

**未改（`hbtextline` 必须未变）**：`build/shims/PresentationCore.HbTextLine.cs` = **`e89fed55fd8e32bc`**（290,825 B，mtime 00:12:06）—— 本波**一个字节都没碰**。

**未改的「仪器」**：`build/MilBridge/tests/D5CbrProbe/Program.cs` = **`92694cf0c9c5d392`**（38,405 B，与 `#24` 同值）。
⚠️ **如实登记**：本车道**没有**改探针源码；但探针**被重建过**（它 `HintPath` 引 `pc`、`Private=true`）⇒ `bin/Release/PresentationCore.Tests.dll` 的 sha16 由 `117582b2a40d30c0` 变为 **`2f40abf161e758b2`**，原因是其内嵌的 `pc` 副本跟着换成了 `7374308a00c55572`（`Program.cs` 未变 ⇒ **不是仪器改动**）。

**备份**（`cp -p` 全份，纪律 16）：`$HOME/w25a-backups/` —— `patch-presentationcore-textline-fallback.py`（`#24` 原值）、`AP.FINAL.bak`（本波终态）、`TextFormatterImp.Linux.cs.before`、`PresentationCore.dll`（`#24` 原值）、`Program.cs`，以及三处反极性/假修中间态留档（`ap.halfwire.bak`/`ap.fake2.bak`/`ap.good.bak`、`gen.halfwire*.bak`）。读数全部在 `$HOME/w25a-run/`。

---

## §2 机制证：为什么修后不再是那条 `lastFail`

### 2.1 失败点（修前，行号级）

生成物 `a6f1b678ce87a8a2` 的 `CollectLenient` 段末：

```
:243           if (props == null)
:244           {
:245               DiagBeforeReturn("没有 run properties");
:246               s_lastFail = "没有 run properties";
:247               return false;
:248           }
```

⇒ `:287` `if (!CollectLenient(...)) { ++s_failed; return null; }` ⇒ 宽松兜底返 null ⇒ 生成物 `:668-678` 落 `new TextMetrics.FullTextLine(...)` = LineServices ⇒ Linux 上 `LoCreateContext` 不存在 ⇒ **`EntryPointNotFoundException` ⇒ 进程级 abort(134)**。

**归因**：全隐形段落（`[TextHidden L=3]@0`）里 `props` 的**两个**唯一来源（`:176-179` 正文 run / `:183-186` EOL run）都拿不到非 null —— `TextHidden.Properties => null`（`TextHidden.cs:62-65`，`sealed`）、`TextEndOfParagraph(1)` → `TextEndOfLine(length,null)`（`TextEndOfLine.cs:29/49/76-79`）。

### 2.2 修法（行号级）

**改动 1 —— 兜底形参**（生成物 `:173`，application `:304` 段内）：

```csharp
        private static bool CollectLenient(TextSource src, int cpFirst,
                                           out string text, out TextRunProperties props,
                                           out int modifierOpenIndex, out int modifierCloseIndex,
                                           TextRunProperties paragraphDefault = null)   // ★D-T5-R
```

**改动 2 —— 兜底语句**（生成物 **`:259-267`**，**唯一**落点）：

```csharp
            text = sb.ToString();
            ...
            if (props == null && paragraphDefault != null)
            {
                props = paragraphDefault;
                ++s_paraDefaults;
                Diag("段落里**一个 props 来源都没有**（全隐形段落）⇒ 取段落默认属性兜底"
                     + "（已计数 relaxedParaDefaults=" + s_paraDefaults + "）");
            }
            if (text.Length == 0)          // ← "空段落"失败点
```

**为什么是这一处**：它在**两个**失败点（空段落分支的 `props == null` 与段末的 `props == null`）**上游** ⇒ 一行覆盖两处；又在两处 `props = run.Properties` **下游** ⇒ **不触碰** run 自身 props 的优先级（⇒ `hidden1`/`hiddenmid`/`eos1` 逐位不变，§5 已实测）。

**改动 3/4 —— 两个调用者 + 两个站点**（生成物 `:322`/`:377` 形参、`:330`/`:386` 转发、`:710`/`:817` 实参）：

| 站点 | 生成物行 | 形态 |
|---|---|---|
| 宽松档站点 1 | `:694-710` | `paragraphDefault: paragraphProperties.DefaultTextRunProperties` 加在 `indentDip:`/`paragraphIndentDip:` 之后 |
| min/max 站点 2 | `:815-817` | 同上，**加在 `out lenientMin, out lenientMax` 之后**（见 §8 推翻） |

**兜底来源合法性**：`paragraphProperties.DefaultTextRunProperties` 是上游正式成员（`TextParagraphProperties.cs:63`），其**非 null + `Typeface` 非 null** 由生成物 `:901-905` 的 `ArgumentNullException.ThrowIfNull` 一族**机器强制** ⇒ 恰好满足 `ResolveFont` 需要的两样（`:258` `props.Typeface`、`:268` 文件存在）。仓内先例 `build/PresentationFramework.Linux/TextBlock.Linux.cs:2856`。

### 2.3 实测（机制证）

| 观测 | 修前（`pc 476994e35d31a7e1`） | 修后（`pc 7374308a00c55572`） |
|---|---|---|
| `lastFail`（宽松档） | **`"没有 run properties"`** | **`"-"`**（该串消失） |
| `relaxedHandled/relaxedFailed` | `0 / 1` | **`1 / 0`** |
| `relaxedParaDefaults`（本波新计数器） | 字段不存在 | **`1`**（≈ 兜底真的被取用） |
| `relaxedInvisibleRuns`/`lastInvisible` | `1` / `"TextHidden x3"` | `1` / `"TextHidden x3"`（**未变** ⇒ `D-T5` 主路未受影响） |
| `control`/`mod0`/`eos1`/`mod1`/`hidden1`/`hiddenmid` 的 `relaxedParaDefaults` | — | **全 `0`** ⇒ **新分支在这 12 组上一次都没执行** |

---

## §3 生成物差异 + 重生成机制

### 3.1 差异规模

```
$ diff -u $HOME/w25a-backups/TextFormatterImp.Linux.cs.before build/PresentationCore.Linux/TextFormatterImp.Linux.cs
  +72 行 / −9 行（净 +63 行；其中约 50 行是注释）
```

关键 hunk **3 处**（只贴关键）：

```diff
@@ CollectLenient 段末 @@
             text = sb.ToString();
+            if (props == null && paragraphDefault != null)
+            {
+                props = paragraphDefault;
+                ++s_paraDefaults;
+                Diag("段落里**一个 props 来源都没有**（全隐形段落）⇒ 取段落默认属性兜底" ...);
+            }
             if (text.Length == 0)

@@ 宽松兜底站点 1（TryFormatLine 调用）@@
                     indentDip: paragraphProperties.Indent,
                     paragraphIndentDip: paragraphProperties.ParagraphIndent,
+                    // @@D-T5R-SITE@@ 段落默认 run properties 兜底（D-T5-R；标识本站点，供本脚本计数牙齿定位）
+                    ... 注释 9 行 ...
+                    paragraphDefault: paragraphProperties.DefaultTextRunProperties
                     ) as TextLine;

@@ min/max 站点 2 @@
             if (WpfLinuxLenientTextFallback.TryMinMaxParagraphWidth(textSource, textSource.PixelsPerDip,
+                    out lenientMin, out lenientMax,
+                    paragraphDefault: paragraphProperties.DefaultTextRunProperties))
```

（第 1 处 hunk 亦含：新计数器 `s_paraDefaults` 声明、`Diagnostics` 新增 `relaxedParaDefaults=`、两个调用者 `TryFormatLine`/`TryMinMaxParagraphWidth` 的形参 + 转发实参 —— 见 §2.2 表。）

### 3.2 重生成机制（确切命令与出口读数）

本仓既有机制 = `build/integration-wave.sh:313-317`：对 `APPLIERS_ALL` 里每个应用器跑 **无参** `python3 <applier>.py`（`:161` 显式表内含 `patch-presentationcore-textline-fallback`）。定向重生成 = 直接跑那一条，**不必跑整波**：

```
$ python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py
[生成] build/PresentationCore.Linux/TextFormatterImp.Linux.cs：已从上游重生成（2 处 D3 修改）
[接线] csproj 已就位（幂等，不改）；生成物 Include=True；TEXTLINE_SHIM_DIRECT=True
=== 退出码 0 ===
```

**重建 `pc`**（§7 纪律：`-m:1` + `DOTNET_gcServer=0`、构建前查 `MemAvailable > 1200 MB`）：

```
$ DOTNET_gcServer=0 dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -c Debug -m:1 --nologo -v q
    0 个警告
    0 个错误
已用时间 00:00:28.15 ~ 00:00:54（多次重建，最长 68.9 s）
```

⚠️ **实测坑（如实登记）**：`dotnet build` 对"文件内容变了但 mtime 未变"的情形**会跳过编译**（我在回退/恢复往返中撞到过一次：`pc` sha 没变而生成物已换）。⇒ **信任 `pc` sha 之前必须确认它真的变了**；本次所有关键读数都记了读数前后的 `pc` sha 且相等。

### 3.3 应用器审计（`miss` 必须为 0）

```
$ bash build/check-appliers.sh --with-check
APPLIER_AUDIT applier=patch-presentationcore-textline-fallback ... miss=0 selfcheck_rc=0
APPLIER_AUDIT_SUMMARY appliers=22 ok=102 miss=0 red=0 rc=0
```

⇒ **`miss=0`、`red=0`、`rc=0`**（修后重跑两次，同值）。`applier-audit-expected.txt` 未改（应用器名已在清单内）。

**牙齿条数解释**（要求"断言条数要能解释"）：

| 类别 | 修前 | 修后 | 说明 |
|---|---|---|---|
| `REQUIRED_IN_OUTPUT` 条数 | 30 | **34** | **+4**（本波新增 4 条正向 needle）；其中 `needle=None` 的**计数式占位** 1 条不变 ⇒ 实际字符串断言 29 → **33** |
| 负断言（`for bad, why in`） | 3 组 | **3 + 1 组** | 新增 1 组**双条**：两个站点的"旧 5 实参形态"各 1 条（半接线指纹） |
| 计数牙齿 | 5 组 | **6 组** | 新增 `n_default_forward/n_default_src/n_fallback == 2/2/1` |
| **D-T5-R 计数牙齿 `n_default_src`** | — | **要求 2** | 口径 = `CountLenient` 兜底形参的两个**来源**站点（宽松档站点1 + min/max 站点2）；**半接线 ⇒ 0 ⇒ 当场报红**（§6.3 实测） |
| 顺序牙齿 | 1 组（`D-T5`） | **2 组** | 新增 `D-T5-R` 顺序：收集循环 < `text = sb.ToString();` < 兜底（防"兜底跑到采集之前"把 run 自身 props 静默改写） |
| `--check` 断言行总数 | 12 | **16** | `[断言]` 行计数 |

**两处 needle 尾巴的同步（必需，且被牙齿当场抓到）**：加兜底实参后，两条既有正向 needle 的**收尾串**不再匹配 —— `P2`（`:700` 一带，收在 `double paragraphIndentDip = 0)`）与 `W19-B`（收在 `\n) as TextLine;`）。⇒ 只改**尾巴**（`P2` 改收在 `,`；`W19-B` 改用**站点标识行** `@@D-T5R-SITE@@`），**标识串本体逐字未动** ⇒ 两条牙齿的**射程一个字节都没变**。计数牙齿 `_INDENT_ARGS` 同样改用站点标识行（计数仍 **2**）。

---

## §4 探针矩阵（四格）—— 修前 vs 修后

**装置自证先跑**（证明"abort 与 null"可分辨）：

```
$ dotnet .../PresentationCore.Tests.dll --selftest abort ; echo rc=$?   →  rc=134  （核心已转储）
$ dotnet .../PresentationCore.Tests.dll --selftest null  ; echo rc=$?   →  rc=1，打 D5CBR VERDICT case=selftest verdict=RED-NULL
```

**命令形态**（`--collapsible` 是**必须**的，否则落 `SimpleTextLine` 快路径被当 Ghost 处理而**读成 GREEN**）：

```
D=build/MilBridge/tests/D5CbrProbe/bin/Release
unset DISPLAY
dotnet $D/PresentationCore.Tests.dll --case hiddenonly --tier <strict|lenient> --collapsible [--nocatch] \
       --marker <标记文件>
```

### 4.1 `hiddenonly` 四格

| 腿 | 修前 `rc` | 修前判定 | 修后 `rc` | 修后判定 |
|---|---|---|---|---|
| `strict`（catch） | **1** | `RED-EXC-LS`，`A1/A2/A3` **全 FAIL**（`Σ=0` 期望 `3`），`异常=EntryPointNotFoundException: … 'LoCreateContext'` | **0** | **`GREEN`**，`A1/A2/A3` **全 PASS**（`Σ=3` 期望 `3`），`行数=1` |
| `strict --nocatch` | **134** | 标记停在 `T1 before FormatLine#1 index=0 cpLength=3`，stderr `Unhandled exception … LoCreateContext` | **0** | **`GREEN`**，标记收尾 `T3 done verdict=GREEN rc=0` |
| `lenient`（catch） | **1** | 同上（`GetTextRun次=2`） | **0** | **`GREEN`** |
| `lenient --nocatch` | **134** | 同 `strict --nocatch` | **0** | **`GREEN`** |

**修后四格逐格读数（`pc` 读数前后均为 `7374308a00c55572`）**：

```
D5CBR DIAGafter  lenient{relaxedCalls=1 relaxedHandled=1 relaxedFailed=0 relaxedSkippedRuns=1
  relaxedBlankParagraphs=0 relaxedInvisibleRuns=1 relaxedParaDefaults=1
  lastSkip="TextHidden x1" lastSkippedRange="[0,3) TextHidden"
  lastInvisible="TextHidden x3" lastFail="-"}
D5CBR ASSERT case=hiddenonly tier=strict A1非null=PASS A2无LoCreateContext=PASS A3长度一致=PASS（Σ(Length−NewlineLength)=3 期望=3）
D5CBR VERDICT case=hiddenonly tier=strict verdict=GREEN 行数=1 Σlen=4 Σnl=1 Σ可见长=3 期望=3 GetTextRun次=3 #1=4/nl1 异常=-
D5CBR_EXIT=0
```

（`lenient` 两格与 `strict` 逐字相同，只有 `GetTextRun次` 由 `3` 变 `2` —— 严格档多探一次源。`Σlen=4`/`Σnl=1` 是"3 个 U+200B + 1 个段落换行"的正确账。）

### 4.2 阳性对照 / 已绿用例（**不许动**）

| 用例 | 修前 | 修后 | 归一化逐字节 |
|---|---|---|---|
| `control`（阳性对照） | `rc=0 GREEN` `Σ=4/4` | `rc=0 GREEN` `Σ=4/4` | **IDENTICAL**（两档） |
| `mod0` | `rc=0 GREEN` `Σ=4/4` | `rc=0 GREEN` `Σ=4/4` | **IDENTICAL**（两档） |
| `eos1` | `rc=0 GREEN` `Σ=5/5` | `rc=0 GREEN` `Σ=5/5` | **IDENTICAL**（两档） |
| `mod1` | `rc=0 GREEN` `Σ=5/5` | `rc=0 GREEN` `Σ=5/5` | **IDENTICAL**（两档） |
| `hidden1` | `rc=0 GREEN` `Σ=5/5` | `rc=0 GREEN` `Σ=5/5` | **IDENTICAL**（两档） |
| `hiddenmid` | `rc=0 GREEN` `Σ=5/5` | `rc=0 GREEN` `Σ=5/5` | **IDENTICAL**（两档） |

**零射程口径**：12 组日志**剥去 `pid=` 与新诊断字段 `relaxedParaDefaults=`** 后逐字节相同，聚合 sha16 **`a06e28003c107cba`（修前）== `a06e28003c107cba`（修后）**。差异**只**来自新增诊断字段（+1 字段/行），**无任何判据行/判词/计数变化**。⇒ 停条件 3 **未触发**。

**更强的零射程证据（本波额外取）**：`PcLineOracle --leg b --tier strict` 修前/修后各 1,480 行，
`diff` **只有 2 行**（`PCLINE LEG=B 宽松档计数`/`正控` 两行各多一个 `relaxedParaDefaults=0`），
**判据行聚合 sha16 `573de10e62159227` == `573de10e62159227`**，汇总行逐字相同：
`PCLINE START 腿=汇总(B) 红=0 绿=421 判定行=421 NOINFO=0 红例=0 Start-only红例=0 未比真值行=0 未登记失败=67 其中点名Start列=0 最大Δ=0.000000 @-`（`rc=1` 由 `未登记失败=67` 造成，**修前同值**）。
⇒ **该行 `relaxedCalls=0`** 正是"新分支在冻结语料上一次都不执行"的运行期证明（288 例 latin 段落里每个 run 都是 `TextCharacters` ⇒ `:183` 第一次迭代就把 `props` 立起来）。
**`frame-step.sh`（FrameProbe 三腿）**：`FRAME_STEP=PASS`、三腿 `判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 自洽=1`（**与 `#24` 逐位同值**）。

---

## §5 三级反极性

### 5.1 ① 牙级假修（只改代码、不改 needle）⇒ 应用器必须拒写

操作：从应用器里**删掉兜底语句**（只删代码，`REQUIRED_IN_OUTPUT` 的 4 条新 needle **原样保留**）。

```
before: ap=64cac206bf10635f gen=a433f38aaabe43b4
$ python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py ; echo rc=$?
[失败] 生成物缺少结构断言：D-T5-R 正向：段落默认 props 兜底语句在位（'if (props == null && paragraphDefault != null)'）
=== 退出码 1 ===
rc=1
after : ap=19b795476547e18f gen=a433f38aaabe43b4      ← **生成物 sha 未变 = 没写盘**
```

✅ **判定**：`rc=1` ∧ 生成物**逐字节未变**（写盘在 `:915-917`，`generate()` 在**内存里**先查 needle，不符即 `return 1`）。
（复原 ⇒ `ap` 回到 **`64cac206bf10635f`**，`--check rc=0`。）

### 5.2 ② 返空串假修 ⇒ `A3` 必红

操作：只把 Ghost 占位 `return new string(GhostChar, run.Length);` 改成 `return string.Empty;`（**兜底与接线全部保留**），并把那条正向 needle 临时改到假修形态（否则应用器拒写）。

新 `pc` = **`c64feb4e6b31085d`**，四格读数（`rc` 全 `1`）：

```
D5CBR DIAGafter  lenient{... relaxedBlankParagraphs=2 relaxedParaDefaults=2 ... lastFail="-"}
D5CBR ASSERT case=hiddenonly tier=strict A1非null=PASS A2无LoCreateContext=PASS A3长度一致=FAIL（Σ(Length−NewlineLength)=2 期望=3）
D5CBR VERDICT case=hiddenonly tier=strict verdict=RED-LENGTH 行数=2 Σlen=4 Σnl=2 Σ可见长=2 期望=3 GetTextRun次=5 #1=2/nl1 #2=2/nl1 异常=-
D5CBR_EXIT=1
```

✅ **判定**：**"修好"（`A1/A2` 绿、不交回 LS、不 abort）与"修得对"（`A3` 码元账守恒）是两件事** —— 本假修让产品不再 abort（`A1/A2` PASS）却把长度账做坏，`A3` **当场变红** ⇒ **`A3` 在该路径上有判别力**。
（复原 ⇒ `ap` 回到 `64cac206bf10635f`、生成物回到 `a433f38aaabe43b4`、`pc` 回到 `7374308a00c55572`，`hiddenonly` 又绿。）

### 5.3 ③ 半接线假修（只加形参、调用点不传）⇒ 必须仍红 + 计数牙齿抓到

**第一步：只做半接线代码改动（needle 一律不动）** ⇒ 计数牙齿**当场报红**：

```
[失败] D-T5-R 计数牙齿：兜底透传 `paragraphDefault: paragraphDefault)` = 2（要求 2 = 两个转发点）、
       来源 `paragraphDefault: paragraphProperties.DefaultTextRunProperties` = 0（要求 2 = 宽松档站点1 + min/max 站点2）、
       兜底语句 = 1（要求 1）—— **半接线**（只加形参、调用点不传）会让 `paragraphDefault` 恒 null，行为与修前**逐位相同**却看不出来
rc=1
```

**第二步：咬穿牙齿**（把 `n_default_src` 期望临时改成 `0`）令应用器写盘（否则拿不到端到端读数 —— 这正是"牙齿是唯一防线"的证明）；再把 `paragraphDefault` 的两处实参**直接从生成物里去掉**（含站点标识注释与悬垂逗号，保证语法合法），得到"半接线"成品：

```
半接线生成物 = e44eb59d4d6a5244     半接线 pc = 59164a96bd3d1c8d
D5CBR DIAGafter  lenient{... relaxedHandled=0 relaxedFailed=1 relaxedParaDefaults=0 ... lastFail="没有 run properties"}
D5CBR ASSERT case=hiddenonly tier=strict A1非null=FAIL A2无LoCreateContext=FAIL A3长度一致=FAIL（Σ(Length−NewlineLength)=0 期望=3）
D5CBR VERDICT case=hiddenonly tier=strict verdict=RED-EXC-LS ... 异常=EntryPointNotFoundException: … 'LoCreateContext' …
```

| 腿 | 半接线 `rc` |
|---|---|
| `strict` | **1**（`RED-EXC-LS`） |
| `strict --nocatch` | **134** |
| `lenient` | **1**（`RED-EXC-LS`） |
| `lenient --nocatch` | **134** |

✅ **判定**：半接线**与修前逐位相同**（`lastFail="没有 run properties"`、`relaxedParaDefaults=0`、`RED-EXC-LS`/`134`）⇒ **"接线了但没生效"不会静默变绿**；而计数牙齿 `n_default_src` 在**代码阶段**（尚未写盘、尚未编译）就已报红 ⇒ 它是这条假修的**第一道也是唯一一道**防线（`#17` 那族事故的机器化）。

### 5.4 反极性成对读数汇总

| 形态 | 支撑件 | `hiddenonly` | 对称性 |
|---|---|---|---|
| **真修**（本波终态） | `ap 64cac206bf10635f` / `gen a433f38aaabe43b4` / `pc 7374308a00c55572` | **`rc=0 GREEN` `A1/A2/A3` 全 PASS** | — |
| ① 牙级假修 | 拒写（`gen` 未变） | — | **修好⇒绿 / 改坏⇒拒写** ✅ |
| ② 返空串假修 | `pc c64feb4e6b31085d` | **`rc=1 RED-LENGTH`**（`A1/A2` PASS、`A3` FAIL） | **修好⇒`A3` PASS / 改坏⇒`A3` FAIL** ✅ |
| ③ 半接线假修 | `gen e44eb59d4d6a5244` / `pc 59164a96bd3d1c8d` | **`rc=1 RED-EXC-LS`**（`--nocatch` ⇒ `134`） | **真修⇒绿 / 半接线⇒仍红** ✅ |
| **回退态**（`#24` 原应用器） | `ap 536f58b338a2369d` / `gen a6f1b678ce87a8a2` / `pc 476994e35d31a7e1` | **`rc=1 RED-EXC-LS`**（`--nocatch` ⇒ `134`） | **改好⇒绿 / 复原⇒又红** ✅ |

---

## §6 回退证（`cmp` + sha 双证）

干净重做一遍（全部现场算，`$HOME/w25a-run/rollback.log`）：

```
[S0] 真修态：ap=64cac206bf10635f gen=a433f38aaabe43b4 pc=7374308a00c55572
[S1] 复原 #24 原应用器（cp -p 全份备份）
     ap=536f58b338a2369d（期望 536f58b338a2369d）
     重生成后 gen=a6f1b678ce87a8a2（期望 a6f1b678ce87a8a2）
     重建后 pc=476994e35d31a7e1（期望 476994e35d31a7e1）
     cmp vs #24 留档：IDENTICAL
[S2] 恢复真修态
     ap=64cac206bf10635f（期望 64cac206bf10635f）
     重生成后 gen=a433f38aaabe43b4（期望 a433f38aaabe43b4）
     重建后 pc=7374308a00c55572（期望 7374308a00c55572）
     hbtextline=e89fed55fd8e32bc（必须 e89fed55fd8e32bc）
```

✅ `pc` **逐字节回到 `476994e35d31a7e1`**（`sha256sum` + `cmp …IDENTICAL` 双证），往返闭合。
⚠️ **如实登记**：往返过程中撞到一次"`dotnet build` 内容变但 mtime 未变 ⇒ 跳过编译"（§3.2），当时 `pc` sha 未变而生成物已换 ⇒ 我**不采信**那一次读数，重做了整条 [S0]→[S2]。上表是**重做后**的读数。

---

## §7 位移复核

| 位 | 权威路径（`build/close-wave.sh:179-188`） | `#24` 值 | 本波值 | 判定 |
|---|---|---|---|---|
| `bridge` | `.artifacts/publish/…/wpfgfx_cor3.so` | `d567c26f197ec1e3` | `d567c26f197ec1e3` | **未变** ✅ |
| **`pc`** | `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `476994e35d31a7e1` | **`7374308a00c55572`** | **已变（预测内）** 🔺 |
| `pf` | `build/PresentationFramework.Linux/bin/Debug/PresentationFramework.dll` | `9b173a4a871336f8` | `9b173a4a871336f8` | **未变** ✅ |
| `windowsbase` | `build/WindowsBase.Linux/bin/Debug/WindowsBase.dll` | `1114a28ec5a03ab7` | `1114a28ec5a03ab7` | **未变** ✅ |
| `provider` | `build/DirectWrite.Linux/Provider/bin/Debug/DirectWrite.Linux.Provider.dll` | `9aa0d744802aaa31` | `9aa0d744802aaa31` | **未变** ✅ |
| `win32shim` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `0098234982391bbf` | `0098234982391bbf` | **未变** ✅ |
| `wic_shim` | `build/DirectWrite.Linux/wic-shim/libwpfwic.so` | `03b67fbcd7c385b6` | `03b67fbcd7c385b6` | **未变** ✅ |
| **`hbtextline`** | `build/shims/PresentationCore.HbTextLine.cs` | `e89fed55fd8e32bc` | **`e89fed55fd8e32bc`** | **未变** ✅（**停条件 1 未触发**） |
| `dwf` | `build/DirectWriteForwarder.Linux/bin/Debug/DirectWriteForwarder.dll` | `0ed422ef2dd46445` | `0ed422ef2dd46445` | **未变** ✅ |
| `inputs_fp` | — | `a8703419…cd8f6dee793` | **`0b8b6559…63eba2d8`** | **已变（预测内）** 🔺 |

- **`inputs_fp` 变化的唯一原因 = G1 组（`patch-*.py`）**：本波只改了其中 1 份（`patch-presentationcore-textline-fallback.py` `536f58b338a2369d`→`64cac206bf10635f`），其余 21 份 `patch-*.py` 与该函数的 G2（`build/shims/**/*.cs`）、G3（`src/WpfGfx.Linux/**/*.cs`）**未动**（算法照抄 `build/close-wave.sh:68-79` 的 `fp_inputs()`；我另算过 G2/G3 两侧，`hbtextline` 未变即 G2 未变）。
- **世代绑定三项**（`tline-gate.sh:135-137` 的 `run.sh`/`HbTextLineParity/Program.cs`/shim）**全未变** ⇒ **禁止重取五臂、禁止重钉 `known-red.json`**（`GEN_KEYS` 不含 `pc`）。
- **§2 位移表外位移：无。**

**⚠️ 我**没有**跑的（主控波尾动作，纪律 5）**：`bash build/close-wave.sh`、`verify-all.sh`、应用门禁（6 条 `BASELINE` 行）。
⇒ `ACCEPTANCE-BASELINE.md` 的 6 条 `BASELINE … config=pc:` 需要主控按 `7374308a00c55572` 重取；`APPSYNC`（`check-applocal-sync.sh`）必须在 `pc` 定型后重读；`BASELINE-SHA` 必须随重冻更新。**这四件不在我的写域与射程内。**

---

## §8 我推翻 / 更正的说法（含自己的错，如实登记）

1. **推翻 `~/w25-recon/d-t5r-plan.md` 附 A5 的一句**（原文："⚠️ 该签名的后两个参数是 `out` ⇒ 具名实参需写在 `out lenientMin, out lenientMax` **之前**"）。
   **实测：反了。** C# 规则是"**具名实参之后不许再跟位置实参**" —— 写在 `out` **之前** ⇒ **`CS8323 命名参数"paragraphDefault"的使用位置不当，但后跟一个未命名参数`**（真编一次抓到，`build/PresentationCore.Linux/TextFormatterImp.Linux.cs(814,21)`）。⇒ 最终形态写成 **`out lenientMin, out lenientMax, paragraphDefault: …`**（在 `out` **之后**）。应用器里的注释已按实测改正并留档。
2. **我自己的错，留档**：应用器 `P2` 正向 needle 写"`…double paragraphIndentDip = 0)`" —— 我在 `paragraphIndentDip` 之后加形参后，该 needle 的 `)` 尾巴不再匹配 ⇒ `--check` **当场报红**。**这是牙齿按设计工作**，我改的是**尾巴**（改收在 `,`），**标识串逐字未动**。
3. **我自己的错，留档**：`W19-B` 正向 needle 与计数牙齿 `_INDENT_ARGS` 都用"缩进实参对 + `) as TextLine;`"这条尾巴。我先后**两次**改错：
   - v1 把尾巴换成"兜底实参 + `) as TextLine;`" ⇒ 报 `缩进实参对收尾 = 1（要求 2）`。**真因**：宽松兜底**站点 2** 从来不以 `) as TextLine;` 收尾（它收在 `out lenientMax))`）⇒ 那条尾巴**只**属于 `REPL_1`（严格档）+ `REPLACEMENT_4`（宽松档站点 1）**两处**。
   - v2 我给 `REPLACEMENT_4` 的 `paragraphIndentDip` **误加了一个逗号**（`REPL_1` 那处没有）⇒ 同一串在两处不再同形。**已在模型里回退该逗号**。
   ⇒ 最终口径：**两处 needle 改用站点标识行 `@@D-T5R-SITE@@`**（比"缩进实参对尾部"**精确得多**：它**唯一**标识本站点、不受实参增删影响）；计数牙齿 `_INDENT_ARGS` 同样改用标识行，**计数仍要求 2** ⇒ **射程未缩**。**三次错都当场被 `--check` 抓住，这条`牙齿真的能红`本身是一条正面读数。**
4. **我自己的错，留档**：计数牙齿里 `paragraphDefault: paragraphDefault)` 的期望值我第一版写 **1**，实测 **2**（它在**两个转发点**各出现一次：`TryFormatLine`→`CollectLenient`、`TryMinMaxParagraphWidth`→`CollectLenient`）⇒ `--check` 当场报红。口径改 **2**。
5. **口径更正（不是推翻，但必须写）**：派单说"③ 半接线假修 ⇒ **必须仍红**" —— 实测**成立**，但**前提是先把牙齿咬穿**（把 `n_default_src` 期望临时改成 `0`）才拿得到端到端读数；**牙齿本身在代码阶段就拦下了它**。⇒ 这条反极性的**真正载荷在牙齿上**，端到端读数只是补强。**报告按此口径写，未把它读成"牙齿无用"。**
6. **一条"未按派单字面执行"的如实说明（NOINFO 性质）**：派单说"④ **补一条计数牙齿** `n_default_src == 2`（仿应用器 `:764-773` 既有计数风格），**证明它能抓到这个假修**" —— 我**做成了应用器侧牙齿**（`REQUIRE_IN_OUTPUT` 计数），**没有**改探针 `Program.cs`。理由：探针 `A1/A2/A3` **从不读** `WpfLinuxLenientTextFallback.Diagnostics` 的任何字段做判据（只把它打进 `DIAGafter` 行），把一个**产品内部计数**升成探针判据会**扩大仪器射程**，超出"只在需要补计数牙齿时才动探针"的授权。**派单里"补一条计数牙齿"我按应用器侧实现并证明有效**（§5.3 第一步）；若主控要求"探针侧也要有一条硬判据"，那是**另一件（判据接线）工作**，本波未做 ⇒ 标 `NOINFO`。

---

## §9 判别力边界（**必须写，不许省略**）

| 项 | 在 `hiddenonly` 路径上的判别力 | 依据 |
|---|---|---|
| `A1` 非 null | **有**（修前 `lines=0` ⇒ FAIL；修后 `lines=1` ⇒ PASS） | `Program.cs:301` |
| `A2` 无 `LoCreateContext` | **有**（修前 `excMsg` 含该串 ⇒ FAIL；修后 `"-"` ⇒ PASS） | `Program.cs:295-297`/`:302` |
| `A3` `Σ(Length−NewlineLength)==CpLength` | **有**（② 假修实测 `2 ≠ 3` ⇒ `RED-LENGTH`） | `Program.cs:299`/`:303` |
| **"占位字符是否真零宽"** | **❌ 零判别力** | 探针**从不读** `line.Width` 或**任何几何**（`Program.cs:264-277` 只取 `Length`/`NewlineLength`）；判词只由 `A1/A2/A3` 决定（`:295-304`） |
| **"转绿是否对"（断点/几何与真机一致）** | **❌ 本仓不可测** | 任何冻结语料（`tab-anchor` 436 例）**不含全隐形段落**（本波实测：`PcLineOracle` 该腿 `relaxedCalls=0`）⇒ **无真值可比** |

⇒ **本车道的绿只能读成"不再 abort ∧ 码元账守恒"，不能读成"隐形语义已正确"。**
**已登记偏差（沿用 `W24A` §⑦.1，本波未消除）**：占位取 `U+200B ZWSP`，而 UAX#14 里 ZWSP **可断**、真机 Ghost run **不产生断点** ⇒ 我方会在"原本必然 abort 的段落"上**多出断点**。这一半的真值**只能靠真机重录**（即 `D-T7`）。

---

## §10 `NOINFO` 清单（不许当绿）

| # | 项 | 状态 / 卡点 |
|---|---|---|
| 1 | **严格档 shim 的兜底**（`HbTextFallback.TryFormatLine`，生成物 `:663-682`） | **本波未接线，且不许接**：shim 的形参表（`PresentationCore.HbTextLine.cs:4634-4636`）**没有** `TextRunProperties` 形参，接它 = **动 shim** = 付世代成本（违反本波硬约束 2）。**对目标用例无影响**（已证）：`hiddenonly` 在严格档先因 `:4575` `Bail(ref BailRunType, "run 类型 TextHidden 不支持")` 返 null，再**往下走宽松兜底**（生成物 `:686-710`）⇒ 宽松档一修好，`hiddenonly` 就绿（实测四格全绿）。**残余风险**：若将来出现"严格档能收但拿不到 props"的输入，那条路仍会返 null ⇒ 交回 LS ⇒ abort。**今天无此类输入的实测样本。** |
| 2 | **`GetTextBounds` 夹取**（真机 `CreateDegenerateBounds()` 语义） | 本件**未实现、未测** —— 不能把"帧对了"读成"夹取也对了"（沿用 `W23B` 的登记）。 |
| 3 | **真宿主（`TextBlock`/`<Run>`）可达性** | **未测**（沿用 `W24A`：整段皆隐在真宿主的可达性同句）。本波只证**探针构造态**可修。 |
| 4 | **`TryMinMaxParagraphWidth` 站点的端到端读数** | **未单独取**：探针 `D5CbrProbe` 只走 `FormatLine`；本波对该站点只做了**机器证**（接线来源计数 = 2、编译通过、`--check rc=0`）。⇒ "min/max 站点在半接线时也会红"是**由同一 `CollectLenient` 共享失败点推得**，**不是**该站点的独立读数。 |
| 5 | **探针侧的"兜底生效"硬判据** | 见 §8 第 6 条：本波只把 `relaxedParaDefaults` 做成**可读字段**（出现在 `DIAGafter` 行，我按人读），**没有**把它变成 `A4`。⇒ **"接线了但没生效"在探针侧仍无自动红**（只有应用器侧牙齿）。 |
| 6 | **6 条 `BASELINE … config=pc:` / `APPSYNC` / `BASELINE-SHA` / `verify-all` 第 [5][6][7] 步** | **未跑**（纪律 5：主控波尾动作）。其中 [6] 我用 `frame-step.sh`（同一装置、同一判据）代跑并 `PASS`，[5] 我用 `PcLineOracle` 直接 A/B 代跑并证零判据位移；`BASELINE … config=pc:` 与 `APPSYNC` **本波完全未取**。 |
| 7 | **`dotnet build` 增量判定的可靠性** | §3.2 实测撞到一次"内容变 mtime 未变 ⇒ 跳过编译"。本波所有关键 `pc` 读数都记了读数前后 sha 且相等；但**"生成物与 `pc` 是否同步"没有等号读者**（沿用 `d-t5r-plan.md` §7 第 3 条）⇒ 只能靠 `applier --check`（本波 `rc=0` 两次）。 |

---

## §11 对主控的四条提请注意

1. **`pc` 已定型 = `7374308a00c55572`**（4,197,888 B）。波尾重冻需要重取：`ACCEPTANCE-BASELINE.md` 6 条 `BASELINE … config=pc:`、`BASELINE-SHA`、`APPSYNC`（`pc` 一重建，那 12 份"已转绿"又会 stale —— 沿用 `#24` ⚠️⑨ 的口径，**必须在 `pc` 定型之后再读**）。`inputs_fp = 0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8`（**现场脚本算的**，未手抄 —— 纪律 49）。
2. **世代成本 = 零**：`hbtextline` 未变 ⇒ **不重取五臂、不重钉登记表 `generation`**。本波 `TLINE_GATE` 我**没跑**（属主控），但机制成立（`GEN_KEYS` 不含 `pc`）。
3. **`D-T7` 建议按原计划排**：本波只把"能不能转绿"修好了；"**转绿是否对**"（Ghost 占位零宽 / ZWSP 断点偏差）**仍然只能靠真机重录**（§9）。**不要把本车道的绿读成 `D-T7` 已解决。**
4. **`D-T5-R` 今天仍红不到任何门**：`verify-all.sh` 与 `build/MilBridge/tools/*.sh` 里 `D5CbrProbe|hiddenonly` 命中仍为 **0**（沿用 `d-t5r-plan.md` §5.1）⇒ 如果要让它变成**有牙的门**，需要新写一个 step（照 `frame-step.sh`/`pc-line-step.sh` 的形态）。**那是另一件工作，本波未做。**

---

## 附 A. 本报告引用的 artifact 一览（全部现场 `sha256sum`）

| artifact | sha16 | 备注 |
|---|---|---|
| `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` | **`64cac206bf10635f`**（本波终态）／`536f58b338a2369d`（`#24` 原值） | 写域 |
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | **`a433f38aaabe43b4`**／`a6f1b678ce87a8a2` | 应用器产物 |
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | **`7374308a00c55572`**／`476994e35d31a7e1` | 本波新 `pc` |
| `build/shims/PresentationCore.HbTextLine.cs` | **`e89fed55fd8e32bc`**（290,825 B） | **未变** |
| `build/MilBridge/tests/D5CbrProbe/Program.cs` | `92694cf0c9c5d392` | **未变** |
| `build/MilBridge/tests/D5CbrProbe/bin/Release/PresentationCore.Tests.dll` | `2f40abf161e758b2`（修前 `117582b2a40d30c0`） | **重建引起**，非源码改动 |
| `build/MilBridge/tests/PcLineOracle/bin/Release/PresentationCore.Tests.dll` | — | 用于 §4.2 零射程 A/B（未改其源码） |
| `build/MilBridge/tools/frame-step.sh` | — | 跑出 `FRAME_STEP=PASS` |
| 假修② 制品 | `gen e6a081d74dee09fd` / `pc c64feb4e6b31085d` | 反极性② |
| 半接线③ 制品 | `gen e44eb59d4d6a5244` / `pc 59164a96bd3d1c8d` | 反极性③ |
| 牙级① 读数 | `gen` 未写盘（`a433f38aaabe43b4` 保持） | 反极性① |

## 附 B. 读数存放

- 修前：`$HOME/w25a-run/pre/`（四格 + 12 组对照 + `ALL-ASSERT.txt`）
- 修后：`$HOME/w25a-run/post/`、`$HOME/w25a-run/final/`
- 反极性：`$HOME/w25a-run/half/`（③）、`$HOME/w25a-run/fake2/`（②）
- 零射程：`$HOME/w25a-run/oracle/{pre,post}.txt`
- 回退证：`$HOME/w25a-run/rollback.log`
- 备份：`$HOME/w25a-backups/`
