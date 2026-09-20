# W27B 报告 —— 治 **`D-G17`**：`total_skipped` 从"无声"变"可见且有界"

- **lane=W27B** ｜ 开工 `2026-09-17 17:47:40 +0800` ／ 收工 `2026-09-17 17:5x +0800`
- `kernel 6.8.0-138-generic`｜`loadavg 0.57 → 3.48`｜`MemAvailable 3,156,392 → 3,600,024 kB`
- **零 `dotnet`**（含"会自行构建的步骤脚本"一律没跑 —— 见 §5.0 的机器证）｜未 `pkill`｜未动他人写域
- 唯一交付件：`verify-all.sh`（**只有本车道能写**）

---

## §1 一行结论

**治好了，且不是靠"跳过即失败"**：`verify-all.sh` 现在 ① 每步把**跳过清单（套件级计数 ＋ 声明来源 ＋ 本步上限）**打到屏上、② 末尾按**声明上限表**断言、③ 结论区逐字写明射程。
**反极性成对实测 7 档**：`X 可用却被跳过` ⇒ `SKIP_GUARD=FAIL rc=1`（改前同一输入**报"✅ 全部通过" + rc=0**，`D-G17` 的假绿**当场复现**）；`--no-x`/无 X ⇒ `SKIP_GUARD=REDUCED rc=0`（**不误伤**，但屏上有清单、结论区有射程）；**真绿一趟零误报**（抽掉本波新增行后 pre/post **逐字节相同**）。
**改法只加不删**：`comm -23 <(sort 改前) <(sort 改后)` = **0 行**；`bash -n` rc=0；`run_step` 仍 **14**。

---

## §2 测绘（全部现场读过；行号 = **改前** `verify-all.sh` `f1dc01793a160c19`／21,309 B／320 行）

### 2.1 `total_skipped` 的**全部**读写点（`grep -n 'total_skipped\|total_passed'`）

| 行 | 原文 | 性质 |
|---|---|---|
| `:84` | `read -r p s t <<< "$(parse_counts "$log")"` | 读（从日志抽三数） |
| `:85` | `printf '  %-28s %s  通过 %-4s 跳过 %-3s 合计 %s\n' "$name" "✅" "$p" "$s" "$t"` | **唯一的"可见点"**：只印一个数字 |
| `:86` | `total_passed=$((total_passed + p))` | 写 |
| `:87` | `total_skipped=$((total_skipped + s))` | 写 |
| `:135` | `total_skipped=0` | 初始化 |
| `:313` | `echo " 用例通过 $total_passed  跳过 $total_skipped"` | 读（末尾汇总） |
| `:314` | `if [ $fail -eq 0 ]; then` | ⚠️ **总判据 —— 只看 `fail`，`total_skipped` 一次都没进** |

⇒ **`total_skipped` 全程"只被打印、从不断言"**（`D-G17` 原文的现场描述**逐字成立**）。

### 2.2 `parse_counts()`（改前 `:48-58` 注释 ＋ `:51-58` 正文）

```bash
# 解析 "Passed!  - Failed:     0, Passed:   321, Skipped:     0, Total:   321"
# 与中文 locale 的 "已通过! - 失败:     0，通过:   321，已跳过:     0，总计:   321"
# 输出 "passed skipped total"
parse_counts() {
  local log="$1"
  local p s t
  p="$(grep -oE '(通过|Passed):[[:space:]]*[0-9]+' "$log" | tail -1 | grep -oE '[0-9]+$')"
  s="$(grep -oE '(已跳过|Skipped):[[:space:]]*[0-9]+' "$log" | tail -1 | grep -oE '[0-9]+$')"
  t="$(grep -oE '(总计|Total):[[:space:]]*[0-9]+' "$log" | tail -1 | grep -oE '[0-9]+$')"
  echo "${p:-0} ${s:-0} ${t:-0}"
}
```
⇒ 它抽的是**每套件一个总数**（`tail -1`）⇒ **逐例名字不在里面**（这也是 `D-G17` 只暴露一个数字的机制面）。

### 2.3 `X11FactAttribute` 的 Skip 机制（**发现期**）

- 承载件 `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs`（259 行）`:69-76`：
  ```csharp
  public sealed class X11FactAttribute : FactAttribute
  {
      public X11FactAttribute()
      {
          if (!X11Probe.Available)
              Skip = X11Probe.SkipReason;
      }
  }
  ```
- 判据源 `:34-37` `public static bool Available => Probe.Value.Available;`、`:44-61` `ProbeCore()`：`DISPLAY` 空白 ⇒ `(false, "环境变量 DISPLAY 未设置")`；`XOpenDisplay` 返回 0 ⇒ `(false, …)`。
- 同族还有三处**独立的**同名特性：`Windowing.Tests/X11Guard.cs:86-90`（另有 `:99-103` 的 `X11TheoryAttribute`）、`Presentation.Tests/X11Guard.cs:64-68`、`HelloMil.Tests/HelloMilProbe.cs:62-66`（`HelloMilX11FactAttribute`）。

### 2.4 `--no-x` 的处理点（改前）

- `:14` `#   ./verify-all.sh --no-x     # 不启动 Xvfb（Windowing/HelloMil 会缺 DISPLAY 而跳过部分用例）`
- `:41-42` `USE_X=1` ／ `[ "${1:-}" = "--no-x" ] && USE_X=0`
- `:147-148` `if [ $USE_X -eq 0 ]; then` ／ `echo "  --no-x：跳过 Xvfb"`
- `:204-205`（ManagedLayer 那一行上面的注释）`# 无 X server 时 8 条 [X11Fact] 在发现期跳过，不会红`
  ⚠️ **这行注释本身已经过期**：现场实测 `[X11Fact]` 在 `ManagedLayer.Tests` 里有 **26 处**（出处见 §3.2 表），不是 8 —— 属 `D-G17` 同族的"数字漂了没人知道"。**我按纪律 46 没擅自动注释**（那是主控写域的文档？——不，它在我的写域内，但改它**不属本件判据**，且改了会让"只加不删"的机器证失效；登记在 §8.3）。

⇒ **结论**：`--no-x` 或任何没有 X 的机器上，依赖 X 的用例在**发现期**变成 `Skip`，`fail` 不增、`total_skipped` 无人断言 ⇒ **整趟仍报「结论：✅ 全部通过」**。**`D-G17` 成立，且是本工程最忌讳的"静默变绿"。**

---

## §3 改法（**只加不删**）

### 3.1 加了五块（全部是**新行**；既有行一字未改）

| # | 落点（改后行号） | 内容 | 为什么落这里 |
|---|---|---|---|
| ① | `:48-143`（插在 `failed_items=()` 与 `parse_counts` 之间） | **声明上限表** `SKIP_CEIL_STATIC/`SKIP_CEIL_CORPUS`/`SKIP_CEIL_X` ＋ `SKIP_SRC`（逐套件来源清单）＋ `SKIP_OBS` ＋ **`skip_ceiling()`（上限公式的唯一实现）** ＋ `skip_manifest()` | 表要先于 `run_step` 定义（`:191` 调用它） |
| ② | `:181-191`（`run_step` 绿分支内、累加 `total_skipped` 之后；代码行 = `:190-191`） | `SKIP_OBS["$name"]="$s"` ＋ `skip_manifest "$name" "$s" "$log"` | **只有这里同时拿得到"本步跳过数"与"本步日志"**（日志在 `:131` 一带被 `rm -f`） |
| ③ | `:291-301`（`[0]` 段之后、`[1] 构建` 之前；代码行 = `:297-301`） | `X_STATE=unavailable` ＋ `xdpyinfo` 判定 ＋ 回显 `X_STATE=…` | 上限表里"依赖 X"那一列**是否计入**取决于它；判定必须在任何 `run_step` 之前 |
| ④ | `:430-491`（末尾汇总与 `if [ $fail -eq 0 ]` 之间；代码行自 `:441` 起，`:492` = 既有 `if [ $fail -eq 0 ]`） | 逐套件上限断言 → `SKIP_GUARD` ＋ `fail++` ＋ `failed_items+=(SKIP-GUARD)`；再印两行机器行 | ⚠️ **必须在 `:492` 的 `if [ $fail -eq 0 ]` 之前**，否则"越界"进不了结论 |
| ⑤ | `:497-508`（既有结论 `fi`（`:496`）之后、收尾 `====`（`:509`）之前） | 射程行（`REDUCED` / `FAIL` 两种） | 既有那句 `结论：…` **一字未动** ⇒ 射程只能另起一行、且要紧贴它 |

### 3.2 声明上限表的值与理由（**这是本件的"上限"**）

| 套件 | 静态 | 语料/产物 | **依赖 X** | 出处（逐条现场读过；用例数口径） |
|---|---|---|---|---|
| `Commands.Tests` | 0 | **2** | 0 | `Commands.Tests/GeometryOracleTests.cs:35`（`GeometryOracleFactAttribute`，缺 `tests/parity/geometry/windows-results.json`）＋ `GoldenBinaryReplayTests.cs:28`（`GoldenStreamFactAttribute`，缺 `tests/U1-golden/*.stream`） |
| `Rendering.Tests` | **2** | **25** | 0 | 静态：`DrawingBrushTests.cs:201`（`[Fact(Skip=…)]` 空壳用例）＋ `TileFlipTruthTests.cs:240`（`[Theory(Skip=…)]` T2b 登记缺口）；语料：`ParityTests.cs:42` 的 `[ParityFact]` ×25（`ParityData.Available`） |
| `Windowing.Tests` | 0 | 0 | **18** | `[X11Fact]` ×9（`X11WindowTests`×4 ＋ `X11PresentationTargetTests`×4 ＋ `X11RealInputEventTests`×1）＋ `[X11Theory]` ×4（`:102/137/167/202`，`[InlineData]` 逐行 2+3+2+2 = 9） |
| `HelloMil.Tests` | 0 | 0 | **1** | `HelloMilTests.cs:563` 的 `[HelloMilX11Fact]` |
| `ManagedLayer.Tests` | 0 | **1** | **26** | X：`[X11Fact]` ×26（`DP1ReproTests`×15 ＋ `DispatcherPumpTests`×5 ＋ `M7cRealAttachmentTests`×3 ＋ `ManagedWindowTests`×2 ＋ `LinuxEnvironmentDiagnosticsTests`×1）；语料：`M7cInputPathTests.cs:476` 的 `[PatchOFact]`（生成物比 dll 新时跳过） |
| `Presentation.Tests` | 0 | 0 | **7** | `[X11Fact]` ×7（`M7cChainTests`×2 ＋ `X11WindowWrapTests`×5） |

**判据（改后 `:441-491` 的实现）**：
```
上限(套件) = 静态 + 语料 + (X_STATE == available ? 0 : 依赖X)
本步跳过数 > 上限  ⇒  SKIP_GUARD=FAIL、fail++、failed_items+=(SKIP-GUARD)  ⇒ rc=1
```
**上限值的三条定值理由（缺一不可，否则会误伤或没牙）**：
1. **静态 2（Rendering）用"归档实测"钉**，不是我自己数的：`~/wfp-runs` 里 **5 趟互不相同的实测**全都是 `Rendering.Tests … 跳过 2`（`verify-all-24.out`／`w25-verify13b.out`／`w26-verify14.out`／`w26-verify14b.out`／`w26-verify14c.out`）⇒ 真绿一趟**恰好等于**上限、**不误报**。
   （⚠️ 我原先按源码"逐 `[Theory]` 的 `[InlineData]` 行数"静态数出的是 **4**，与 5 趟实测的 **2** 不符 ⇒ **以实测为准**、并把静态来源写成两个 `Skip=` 站点。这两个数的差是 xunit 对 `Skip=` 的 `[Theory]` 如何计入"已跳过"的口径问题，**本趟不可测**（零 `dotnet`），登记在 §8.2。）
2. **依赖 X 那一列只在 `X_STATE=unavailable` 时计入** ⇒ `--no-x`／无 X 机器**不会因跳过而红**（预登记 §4：不许误伤）；而 **X 明明可用却跳过** ⇒ 上限只剩"静态＋语料" ⇒ **立刻红**（这正是假绿的现场）。
3. **语料列是"已声明的降级"**（缺真值/缺产物时跳过是既有设计）⇒ 计入上限 ⇒ **可见但不判红**（`[ParityFact]`/`[GeometryOracleFact]`/`[GoldenStreamFact]`/`[PatchOFact]` 都属这一列）；**任何声明外的来源**（新写的 `Skip=`、新自建 `FactAttribute`、被摘掉的用例…）必然越过上限 ⇒ **红**。

### 3.3 "只加不删"的机器证

```
$ comm -23 <(sort ~/w27b-backups/verify-all.sh.pre) <(sort verify-all.sh) | wc -l
0                       # ← 改前独有的行 = 0（既有行一字未删、未改）
$ comm -13 <(sort ~/w27b-backups/verify-all.sh.pre) <(sort verify-all.sh) | wc -l
190                     # 新增行
$ bash -n verify-all.sh; echo rc=$?
rc=0
$ grep -c '^run_step ' verify-all.sh
14                      # run_step 计数不变（预登记要求：应仍 14）
$ wc -l < ~/w27b-backups/verify-all.sh.pre ; wc -l < verify-all.sh
320 ; 510
```
（`comm` 按**行内容**比较 ⇒ 任何被改写过的既有行都会以"删除＋新增"成对出现；`0` 即证明**没有一处既有行被动过**。）

| 件 | 改前 | 改后 |
|---|---|---|
| `verify-all.sh` | `f1dc01793a160c19`（21,309 B／320 行／mtime `2026-09-17 15:22:51`） | **`ad705fa5b0cdb331`**（36,273 B／510 行／mtime `2026-09-17 17:53:00`） |
| 备份 | `~/w27b-backups/verify-all.sh.pre`（`cp -p`，sha16 与改前**逐位相同**） | — |

---

## §4 反极性（**成对、实测**）—— 沙箱：真脚本 ＋ 影子 `dotnet`

### 4.0 装置与"零真 `dotnet`"的机器证

- 沙箱 `~/w27b-run/`：`shim/bin/{dotnet,bash,python3,xdpyinfo,Xvfb}` ＝ **替身**；`fakehome/.dotnet/dotnet` 也是替身。
- 脚本自己 `export PATH="$HOME/.dotnet:$PATH"`（改后 `:32`）⇒ 把 `HOME` 指到 `fakehome` ⇒ **它自己把替身放到了 PATH 最前**。
  ```
  $ env HOME=$SB/fakehome PATH=$SB/shim/bin:/usr/bin:/bin /bin/bash -c 'export PATH="$HOME/.dotnet:$PATH"; command -v dotnet'
  /home/links-dev/w27b-run/fakehome/.dotnet/dotnet
  ```
- **两趟都跑真件**：`pre` = 备份件（`f1dc01793a160c19`）、`post` = 仓内现件（`ad705fa5b0cdb331`）；驱动器 `~/w27b-run/drive.sh`。
- 每次替身调用都记账 ⇒ `~/w27b-run/logs/*.calls` 里**只有**替身记账行（`argv: dotnet test …` / `argv: bash build/MilBridge/tools/frame-step.sh` …）⇒ **真 SDK、真探针（`pc-line-step.sh`/`frame-step.sh`/`tline-gate.sh`）一个都没执行**（纪律 51 细化）。
- 旁证：沙箱跑完后**仓内 20 分钟内被改动的文件只有 `verify-all.sh` 自己**（`find … -newermt … -type f`）⇒ 无副作用。
- ⚠️ `pre` 件是从备份目录直接跑的 ⇒ 它的 `ROOT` = 备份目录（无害：它**每一个**步骤命令都被替身接管；比较时 `根目录:` 那一行已按"唯一环境差"剔除，见 §4.3）。

### 4.1 七档矩阵（合成输入 = 各套件 `已跳过:N`；`x=` 那一列 = 装置判定出的 `X_STATE`）

| 档 | 输入（跳过的套件） | `X_STATE` | **pre（改前）** | **post（改后）** | 期望 |
|---|---|---|---|---|---|
| **C1-green** | 只有 `Rendering=2`（= 5 趟归档的真实形态） | `available` | `rc=0` ✅ | `rc=0`，`SKIP_GUARD=PASS` | 真绿**不许误报** ✅ |
| **C2-x-required-but-skipped** | `Rendering=2 + Windowing=18 + HelloMil=1 + ManagedLayer=26 + Presentation=7`（= **X 可用却整批跳过**，共 54） | `available` | **`rc=0`、`结论：✅ 全部通过`** ← **`D-G17` 假绿当场复现** | **`rc=1`**、`SKIP_GUARD=FAIL`、`reason=x-required-but-skipped`、4 个套件逐条点名 | 必须红 ✅ |
| **C3-no-x** | 同 C2 的 54 例（= `--no-x`／无 X 的**正常**形态） | `unavailable` | `rc=0`（跳过只在数字里） | **`rc=0`**、`SKIP_GUARD=REDUCED`、清单全打印、结论区有射程 | **不许误伤** ✅ |
| **C4-undeclared-skip** | `Commands=3`（> 上限 2；模拟"新加了一个 `Skip`"） | `available` | `rc=0`（**无声**） | **`rc=1`**、`SKIP_GUARD=FAIL`、`reason=undeclared-source` | 必须红 ✅ |
| **C5-corpus-declared** | `Commands=2 + Rendering=27 + ManagedLayer=1`（= 语料类**全部**用满上限） | `available` | `rc=0` | `rc=0`、`SKIP_GUARD=PASS`（30 例**全部可见**） | 声明内的降级**不判红** ✅ |
| **C6-zero-skips** | 全 0 | `available` | `rc=0` | `rc=0`、`D-G17 跳过汇总：无跳过` | 零误报 ✅ |
| **C7-corpus-over** | `Rendering=28`（> 上限 27） | `available` | `rc=0` | **`rc=1`**、`reason=undeclared-source` | 必须红 ✅ |

### 4.2 逐字屏输出对照（关键两行）

**① 假绿现场（C2，同一份合成输入、同一个 `X_STATE=available`）**
```
--- 改前 pre  ---                                   --- 改后 post ---
 步骤通过 14  ❌ 失败 0                                步骤通过 14  ❌ 失败 0
 用例通过 871  跳过 54                                用例通过 871  跳过 54
 结论：✅ 全部通过                                   ⚠️ 跳过越界（= 静默关牙，判据不当绿）： HelloMil.Tests(跳过 1 > 上限 0：X 可用却被跳过) ManagedLayer.Tests(跳过 26 > 上限 1：X 可用却被跳过) Presentation.Tests(跳过 7 > 上限 0：X 可用却被跳过) Windowing.Tests(跳过 18 > 上限 0：X 可用却被跳过)
 VERIFY_ALL_RC=0                                    D-G17 跳过汇总（实测/上限；上限 = 静态＋语料＋X_STATE=available 的 X 项）：HelloMil.Tests=1/0 ManagedLayer.Tests=26/1 Presentation.Tests=7/0 Rendering.Tests=2/27 Windowing.Tests=18/0
                                                    SKIP_GUARD=FAIL x_state=available x_suite_skipped=52 x_suite_units=4 x_suite_corpus_max=1 total_skipped=54 violations= … reason=x-required-but-skipped
                                                    结论：❌ 失败项：SKIP-GUARD
                                                    射程：❌ 跳过**越过声明上限**（静默关牙；reason=x-required-but-skipped）： …
                                                    VERIFY_ALL_RC=1
```
**② `--no-x` 当场（C3）**：`rc=0`（不误伤），但屏上多了**跳过清单**（`[2]` 段每套件一段：`↳ 跳过清单 ManagedLayer.Tests：26 例 ｜本步上限 = 27 例（静态 0 ＋ 语料 1 ＋ X 项 26，X_STATE=unavailable）` ＋ `声明来源：[X11Fact]×26（DP1ReproTests×15 + …）`），以及结论区的射程：
```
 SKIP_GUARD=REDUCED x_state=unavailable x_suite_skipped=52 x_suite_units=4 x_suite_corpus_max=1 total_skipped=54 violations=none reason=none
 结论：✅ 全部通过
 射程：⚠️ **缩减** —— 依赖 X 的套件本趟共跳过 52 例（4 个套件）。
       口径（不许把第三读成第一）：这是**套件级**计数，log 在 `-v q` 下不含逐例名 ⇒
       其中**至多 1 例**可能是语料/产物类（如 `[PatchOFact]`）而非 X 类，本趟**不可逐例区分**。
       这些用例的判据**没有被行使**（上面那个 ✅ 只覆盖已行使的判据）；清单见上方「跳过清单」与「D-G17 跳过汇总」。
```
（**`REDUCED` 而不是 `NOINFO` 的理由**写进了文件注释 `:47-52`：三态是**判据**的词汇，`REDUCED` 是**射程**的注解 —— 它**不进 `fail`**（把 `--no-x` 做成失败就是预登记禁止的"误伤"），但**必须**出现在结论区；它**不冒充绿**：那句 `结论：✅ 全部通过` 的字面从未被解释成"全部判据都行使了"。）

### 4.3 **绿的时候不许误报**（机器证）

把**本波新增的全部行**（固定模式表）＋ `根目录:` 那一行剔掉后，逐档 `cmp`：

```
C1-green:                IDENTICAL（0 行不同）
C3-no-x:                 IDENTICAL（0 行不同）
C5-corpus-declared:      IDENTICAL（0 行不同）
C6-zero-skips:           IDENTICAL（0 行不同）
C2/C4/C7（新判据**故意**点火的那三档）: 只差 2 行 —— `结论：✅ 全部通过` → `结论：❌ 失败项：SKIP-GUARD`、`VERIFY_ALL_RC=0` → `1`
```
⇒ **凡新判据不点火的档，"既有逐项结果"（14 步的 ✅/计数、6 个套件的 通过/跳过/合计）逐字节未变**（脚本 `~/w27b-run/logs/unchanged-proof.txt`）。
⚠️ **口径**：预登记此处写"11 个既有用例的逐例结果不许变"—— 现件在 `-v q` 下**只报套件级计数**（`parse_counts` 的 `tail -1`），所以我能给的最细粒度就是**逐套件计数 ＋ 14 步逐项结果**（= 上面那 4 档 IDENTICAL）。"11 个"指哪一批**本件未查清**，登记在 §8.3。

---

## §5 与既有改动共存

1. **`[7]`/`[8]` 的自报口径回显仍在**：回显那一行**逐字未改**（改后 `:208` `grep -E '^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)' "$log" | head -8 | sed 's/^/      · 自报口径 /'`），且"改前独有行 = 0"是它的机器证。
   沙箱里同一条路径仍印出 5 行（`post-C1-green.out`）：`· 自报口径 FAKE_STEP=PASS step=tline-gate.sh …`／`pc-line-step.sh`／`frame-step.sh`／`baseline-sha-check.sh`／`arm-log-sha-check.sh`。
   ⚠️ **口径**：沙箱里的自报行是**替身**打的（`FAKE_STEP=`）⇒ 它证的只是"**回显通道**没坏"；`[7]`/`[8]` 的**真读数**必须由主控波尾的 `verify-all` 端到端行使（`#26` 归档 `~/wfp-runs/w26-verify14c.out` 里有改前的真读数）。
2. **步数不变**：`grep -c '^run_step '` = **14**（改前 14 ⇒ 改后 14）。
3. **`run_step` 的判据语义零改动**：绿分支新增的两行只写 `SKIP_OBS` 与打印；`rc`/`pass`/`fail`/`failed_items` 的既有语义一律未动（新判词**另起一行**、只在末尾那一处 `fail++`）。
4. 未动：`build/MilBridge/tools/tline-gate.sh`、`build/MilBridge/known-red.json`、`build/MilBridge/tools/frame-step.sh`、`docs/**`、`handoff.md`、基线文件、任何产品件、任何 `tests/**`、任何臂日志（`sha256sum` 现场复核见 §6.1）。

---

## §6 读数表

### 6.1 环境与件

| 项 | 值 |
|---|---|
| lane | `W27B` |
| 时间 | 开工 `2026-09-17 17:47:40 +0800`；改件落盘 `17:53:00`；矩阵跑完 `17:53:0x`；报告 `17:5x` |
| `kernel` | `6.8.0-138-generic` |
| `loadavg` | 开工 `0.57 0.31 0.28`；收工 `3.48 2.22 1.12` |
| `MemAvailable` | 开工 `3,156,392 kB`；收工 `3,600,024 kB` |
| `verify-all.sh` 改前 | `f1dc01793a160c19`／21,309 B／320 行／`2026-09-17 15:22:51` |
| `verify-all.sh` 改后 | **`ad705fa5b0cdb331`**／36,273 B／510 行／`2026-09-17 17:53:00` |
| 备份 | `~/w27b-backups/verify-all.sh.pre` = `f1dc01793a160c19`（`cp -p`，sha16 逐位相同） |
| 沙箱 | `~/w27b-run/{drive.sh,shim/,fakehome/,out/,logs/}`（14 份输出 ＋ 14 份调用记账） |
| 真 `dotnet` 进程 | **0**（一次都没起）；`~/w27b-run/logs/*.calls` = 14 份逐调用记账，全是替身 |

### 6.2 现场复核（我**没碰**的件，现场算的 sha16）

| 件 | 现场 sha16 | 说明 |
|---|---|---|
| `build/MilBridge/tools/frame-step.sh` | `a8800cd897606cf7` | 与 `#26` 收官值相同 ⇒ **无人动过**（本波 W26B 有改动，已核） |
| `build/MilBridge/tools/tline-gate.sh` | `59ce84346325eb21` | ⚠️ **W27A 的写域**：此值是我读取时刻的现场值，**同波车道正在改它** ⇒ 引用前须当趟现算（纪律 58） |
| `build/MilBridge/known-red.json` | `b7a4ad0907f9d76b` | ⚠️ 同上（W27A 写域） |
| `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs` | `e393137a8309d4b8` | **本件只读、未触碰**（`X11FactAttribute` 的 Skip 机制出处） |
| `verify-all.sh`（本件交付） | `ad705fa5b0cdb331` | 改后 |
| `build/MilBridge/W27B-report.md`（本报告） | **见交付消息**（自指：把 sha 写进本行会立刻改变它 ⇒ 写死的值必然是"写入前"的旧值，故此处不留假值；现算 `sha256sum build/MilBridge/W27B-report.md \| cut -c1-16`） | 纪律 58：本报告与它引用的件都带 sha |

---

## §7 口径与"不许把第三读成第一"

| 结论 | 状态 |
|---|---|
| `total_skipped` 从"零断言"变成"有上限断言、越界进 `fail`" | **proven**（§3.1/§3.2 的代码 ＋ §4.1 的成对读数） |
| 跳过从"一个数字"变成"每套件清单 ＋ 声明来源 ＋ 本步上限" | **proven**（§4.2 ②逐字屏输出） |
| X 可用却被跳过 ⇒ 红 | **proven**（C2：pre rc=0 → post rc=1） |
| `--no-x`／无 X 的跳过 ⇒ **不**判红但**必须**可见 | **proven**（C3：rc=0 ＋ 清单 ＋ 射程行） |
| 真绿不误报 | **proven**（C1/C5/C6 ＋ §4.3 的 IDENTICAL） |
| 上限值在**真树上**正确（不误红） | **not measurable（本趟）**：零 `dotnet` ⇒ 我只有**归档实测**（`Rendering=2`）与**源码清点**两条路；`--no-x` 的真读数**本趟拿不到**（要真跑测试）⇒ 上限的"依赖 X"那一列是**源码清点的上界**，**波尾 `verify-all` 一旦真红/真绿都必须回看 §3.2** |
| `-v q` 日志里的逐例跳过名 | **not measurable**：`parse_counts` 只取套件级计数；`dotnet test -v q` 的屏上**没有**逐例名（`skip_manifest` 里有明确兜底行"要看逐例名，需提 verbosity —— 属仪器变更，本波不做"） |
| 语料类与 X 类在**同一套件内**的逐例归属 | **not measurable**（套件级计数）⇒ 屏上给的是**上界**（`x_suite_corpus_max`），并逐字写明"不可逐例区分" |

---

## §8 不可测 / 遗留（登记给主控）

1. **`--no-x` 的真读数本趟未取**（零 `dotnet`）⇒ §3.2 的"依赖 X"列是**源码清点的上界**。若波尾真跑 `--no-x` 出现 `SKIP_GUARD=FAIL`，请先看屏上那行 `…(跳过 N > 上限 M：X 可用却被跳过 / 声明表里没有这个来源)` —— **先判"是 X 真的可用（`X_STATE=available`）"还是"我清点的上界少了"**，再改表（**改表 = 加严/放松判据面，须登记**）。
2. **`Rendering.Tests` 静态跳过"源码数 4 vs 实测 2"**未查清（xunit 对 `[Theory(Skip=)]` 如何计入"已跳过"的口径）。我**按实测 2 钉上限**（5 趟归档一致）；若哪天有人把它改成 4，会**红**（`Rendering.Tests(跳过 4 > 上限 27?)`——不会：上限 27 已含语料 25 ⇒ 4 仍在限内，属**可见不改判**）。⇒ 本条**不影响**任何判定，只是口径未定。
3. **两处文档已过期（我不许改）**：`docs/CURRENT-STATE.md:11` 与 `:51` 把 `verify-all.sh` 的现件写成 `f1dc01793a160c19`（本次改动前值）⇒ 应补 `→ ad705fa5b0cdb331（#27 W27B：D-G17 跳过清单＋上限断言）`；另 `verify-all.sh:204-205` 那句注释"8 条 `[X11Fact]`"现场实为 **26** 条（在同一文件、我的写域内，但改它会让"只加不删"的机器证失效 ⇒ 我未动；建议主控在接线 W27C/W27D 那一趟一并改）。
4. **`11 个既有用例`**（预登记 §4 ⑤的措辞）本件**未查清**指哪一批；我给出的最强形态是"逐套件计数 ＋ 14 步逐项结果"（§4.3）。
5. **未接线**：本件只交 `verify-all.sh`；主控波尾若再接 W27C/W27D 的核对器，步数会变（15/16）—— 那一步**不属本件**，且我的新增块**不依赖步数**（它按"报过 `Total:` 的套件名"收集，不按步序）。
