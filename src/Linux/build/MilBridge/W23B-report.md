# W23B · `D-T6-b`（**Option 1**）落地 + `D-F2` 接出口（`docs/WAVE23-PREREGISTRATION.md` §2 P2）

> lane=**W23B**｜2026-09-17 00:12 → 00:33 +0800｜kernel **6.8.0-138-generic**｜`nproc=3`｜`loadavg` 开工 `0.35 0.26 0.11`／收工 `2.18 2.36 2.20`｜`MemAvailable` 开工 **3,076 MB** / 最低 **2,804 MB**（pc 重建后实测）/ 收工 **3,518 MB**｜`SwapFree` 收工 1,063 MB。
> 纪律 32/35/40：仪器（`FrameProbe`/`PcLineOracle`）读数前后 sha16 见 §7.3；本波**没有**用 `pkill -f`（按 PID 查，我名下 0 残留进程）。
> 开工九位复算 **9/9 逐位 == `#21`**、`inputs_fp` 逐位一致（§7.1）。

---

## §0 一句话结论 + 两条必须先说的口径事

**`D-T6-b` 的修法（Option 1）与 `D-F2` 的出口都已落地并取到读数：帧族红从 133/421（宽松档）与 421/421（`--prefix 40`）降到 0，`GetTextBounds(cpFirst,1)` 读空从 104（宽松）/522（prefix40）降到 0，严格档全部结构化列逐字节未变、`PcLineOracle` 日志逐字节相同，`D-F2` 三个字段修前 0 处 / 修后出现。**
**⚠️ 但有一条预测未字面兑现，我按纪律上报而不是"顺手"改判据：四条腿的残留红都是 **3**（预测是 0）。机器证表明这 3 条**不是帧族**（见 §4），它们是 `#22` 已登记的"我方分行 ≠ 真机分行"结构族里的那 3 行；判定式**一个字节都没动**。**

### §0.1 `DISPLAY=:97` 实测 DOWN —— 已按主控裁决做成机器读数（不停）
开工时 `xdpyinfo -display :97` = **DOWN**（`/tmp/.X11-unix` 里只有 `X0/X1/X10`，都是宿主的）。本件全部读数是"托管文本排版对 JSON 语料"，**没有渲染面**。⇒ 我按"先证明 X 不是本仪器输入"的形式取了一条机器证（主控批准）：

| 命令（同一单例 `--case A-anchor/lat-a-t-b@w96@LTR@i0@default --tier strict`） | stdout sha16 | bytes | rc |
|---|---|---|---|
| `DISPLAY=:0` | `1636569dc511a63a` | 2786 | 0 |
| **`DISPLAY` 未设（本波常规口径）** | `672b1a397e686730` | 2786 | 0 |
| `DISPLAY=:97`（此时 DOWN） | `0b2b6d2baa958943` | 2786 | 0 |

三个 sha16 **不等**只是因为每次的 `FRAMEPROBE 时间=` 行不同；把该行剥掉后 **`cmp` 两两 `rc=0`（逐字节相同）**：
```
cmp(:0,UNSET)=0   cmp(UNSET,:97)=0   cmp(:0,:97)=0
```
⇒ **X（任何 display）不是本仪器（`FrameProbe`）的输入**；本波全部读数都在 `unset DISPLAY` 下取（脚本 `$HOME/w23b-run/run-legs.sh` 里显式 `unset DISPLAY`）。日志 `$HOME/w23b-run/xctrl/fp-single-{0,UNSET,97}.log`。

### §0.2 写域冲突：宽松档接线在**生成物**里 ⇒ 必须改 patcher（已按主控裁决执行）
`WpfLinuxLenientTextFallback`（宽松档）**不在 shim 里**，它在 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`，该文件头自述 **"由 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` 生成，不要手改"**，且 `build/integration-wave.sh:161` 每波重跑该脚本。⇒ 我**改生成器、不碰生成物的内容**，再用生成器重新生成。硬要求四条全部满足：

| 要求 | 读数 |
|---|---|
| ① patcher `--check` 修前/修后都 `rc=0`（现生成物 == 脚本产物） | 修前 `[检查] …内容已是最新`／`退出码 0`；修后同（`CHECK_RC=0`） |
| ② 注入**确实生效**（不是"登记了没生效"） | `bash build/check-appliers.sh` ⇒ `APPLIER_AUDIT applier=patch-presentationcore-textline-fallback tier=A ok=3 miss=0`、`APPLIER_AUDIT_SUMMARY appliers=22 ok=80 miss=0 red=0 rc=0` |
| ③ 不改 `applier-audit-expected.txt` | **未动**（审计 `miss=0 rc=0` ⇒ 无需改；如主控要改，本件不动） |
| ④ 纪律 38 红线 | 改动**活在 patcher 里**；重新跑一次 patcher 后 `--check` 仍 `rc=0`、注入行仍在（§1.2/§1.3） |
| 副产物（如实登记） | 跑 `check-appliers.sh` 会刷新 `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-textline-fallback.cpython-310.pyc`（该目录 09-10 起就存在）：`50ead2f135bc4797`／44,933 B／00:12:30。**不在 `inputs_fp` 覆盖面内**（该函数只取 `patch-*.py`） |

### §0.3 主控问的"红例"口径（实答）
`FrameProbe/Program.cs:495` `if (caseJudged > 0) { ++casesJudged; if (caseRed > 0) ++redCases; }` ⇒ **红例 = "至少 1 行被判红"的例数**；`casesLineCountDiff`（`:500`，"我方行数 ≠ 真值行数"）是**另一个独立计数器**，**不并入**红例。
⇒ 帧列修前宽松档 **红 133 行 / 红例 80**、`行数不等例=60`（60 例**不计入** 80）。`W22C-report.md` §2.1 的同一行也是 `红例=80`（其日志 `v2lenB.log` 与我的修前日志**逐字节相同**，见 §7.2）⇒ 主控上一条里的"88"确认是 `#21` 的 `Start` 列口径（138 行/88 例），与本帧列无关。

---

## §1 改动逐处（行号级）+ before/after sha16

### §1.1 `build/shims/PresentationCore.HbTextLine.cs`（**手写源**）

| 文件 | before sha16 / bytes / mtime | after sha16 / bytes / mtime |
|---|---|---|
| `build/shims/PresentationCore.HbTextLine.cs` | `76089e1de586ac91` / 283,557 B / 2026-09-16 18:31:48 | **`e89fed55fd8e32bc`** / **290,825 B** / 2026-09-17 00:12:06 |
| 备份 | `$HOME/w23b-backup/PresentationCore.HbTextLine.cs.before`（`cp -p`） | — |

**件 A（`D-T6-b`，Option 1）—— 逐处：**

| # | 新行号 | 改动 | 语义 |
|---|---|---|---|
| 1 | `:2649-2661` | **新增字段** `private readonly int _paragraphOrigin;`（+ 26 行文档，写清"为什么不得改 `_lineStart`"） | 段落原点（= 收集时的 `cpFirst`） |
| 2 | `:2759-2762` | 私有 ctor **尾随可选形参** `int paragraphOrigin = 0`（在 `paragraphIndentDip` 之后） | 缺省 0 ⇒ 既有调用点零改动 |
| 3 | `:2781-2783` | `_paragraphOrigin = paragraphOrigin;`（紧接 `_lineStart = lineStart;` 之后 —— **必须在下面两处播种之前**） | 赋值 |
| 4 | `:2852` | `starts.Add(lineStart + ch.CharStart)` → `starts.Add(_paragraphOrigin + lineStart + ch.CharStart)` | `_glyphRunCharStart` 播种进**绝对系** |
| 5 | `:2862` | 兜底 `new List<int> { lineStart }` → `{ _paragraphOrigin + lineStart }` | 同上（单 run 路径） |
| 6 | `:2887-2890` | `FormatLine` 形参尾部加 `int paragraphOrigin = 0` | 透传入口 |
| 7 | `:2949-2952` | 行构造点（ctor 的**唯一**调用点）末尾加 `paragraphOrigin` | 原点落进行对象 |
| 8 | `:3090-3093` | `int localFirst = firstTextSourceCharacterIndex - _lineStart;` → `- (_paragraphOrigin + _lineStart);` | **绝对消费者 1/4**：`GetTextBounds`（`localFirst<0 \|\| > _visibleLength ⇒ 空表` 的判据**一字未动**） |
| 9 | `:3670` | `_collapsedRange = CreateCollapsedRange(_lineStart + visibleLen, …)` → `_paragraphOrigin + _lineStart + visibleLen` | **绝对消费者 2/4**：`TextCollapsedRange.CharacterIndex`（段落系） |
| 10 | `:3729-3736` | `BuildCollapsedLine` 构造末尾加 `paragraphOrigin: _paragraphOrigin + _lineStart` | **绝对消费者 3/4**：折叠行透传（`#21` 曾漏折叠路径被拦下，这次没漏） |
| 11 | `:3788-3792` | `lineEnd = _paragraphOrigin + _lineStart + _visibleLength`；兜底 `startChar = (_paragraphOrigin + _lineStart)` | **绝对消费者 4/4**：`GetIndexedGlyphRuns` |
| 12 | `:3972-3978` | `FormatParagraph` 形参尾部加 `int paragraphOrigin = 0` | 透传入口 |
| 13 | `:4052-4053` | `FormatLine(… paragraphIndentDip, paragraphOrigin)` | 段内透传 |
| 14 | `:4662-4670` | 严格档 `HbTextFallback.TryFormatLine` → 工厂调用加 `paragraphOrigin: cpFirst` | **严格档接线**（`text` 由 `TryBuildPlan` 自 `cpFirst` 起收集 ⇒ 原点 = `cpFirst`） |

**件 B（`D-F2`）—— 逐处：**

| # | 新行号 | 改动 |
|---|---|---|
| 1 | `:1348-1355` | `SummaryFragment()` 的 **`PlanCalls == 0` 早退分支**：返回值尾部追加 `scanCapped=` / `segmentFaceUnresolved=` / `runFaceSlotMissing=`（**+4 行**，含口径注释：本分支**不**触发 `EnsureScan()` ⇒ 该值是"至今累计"的真值） |
| 2 | `:1387-1393` | 正常分支：**排在 `candidates=` 之后**追加同样三个字段（注释写明"必须在 `Count` getter 触发 `EnsureScan()` 之后读，否则是扫描前的旧值 = 假绿"） |
| 3 | `:1067` / `:1146` / `:1271` | **3 处注释伪证**（自称"诊断行报 `capped=`"）改成"出口 = `HB_TEXTLINE` 汇总行的 `scanCapped=`"，与实现一致 |

**未动（逐字节证，见 §2）**：`_lineStart` 的**语义与赋值**（`:2780` `_lineStart = lineStart;`）、三个**相对**消费者 `:3661`（`_text[_lineStart + …]`）、`:3694`（`_text.Substring(_lineStart, …)`）、`:3701`（`_plan.Sub(_lineStart, …)`）、`:3704`（`s.Start <= _lineStart`）。

### §1.2 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`（**生成器**，主控批准的写域扩展）

| 文件 | before sha16 / bytes / mtime | after sha16 / bytes / mtime |
|---|---|---|
| `patch-presentationcore-textline-fallback.py` | `daa1fe2a32d454cf` / 52,168 B / 2026-09-16 15:31:55 | **`00c2179b87fc0509`** / 54,344 B / 2026-09-17 00:12:27 |
| 备份 | `$HOME/w23b-backup/patch-presentationcore-textline-fallback.py.before` | — |

改动 3 处（**只改注入块与牙齿，不手改生成物**）：
1. **注入块**（宽松兜底站点 1）：`indentDip: indentDip, paragraphIndentDip: paragraphIndentDip);` → 追加 `paragraphOrigin: cpFirst);`（+8 行注释说明"本档每次重起段、只交回 `lines[0]` ⇒ 修前帧恒 0"）。
2. **needle 同步**：`REQUIRED_IN_OUTPUT` 的 `"…paragraphIndentDip: paragraphIndentDip);"` → `"…paragraphIndentDip: paragraphIndentDip,"`，并**新增** needle `("W23-B：宽松兜底把**段落原点**透给工厂（= cpFirst；缺它则帧恒 0）", "paragraphOrigin: cpFirst);")`。
3. **计数牙齿**：新增 `n_para_origin = _count(out, "paragraphOrigin: cpFirst")`，要求 **== 1**，否则 `return 1`（打印 `[失败] W23-B 段落原点接线计数不对…`）。**这正是 `#17`"登记了但没生效"那一族的机器化**。
4. `HEADER` 补一句（生成物头部如实登记本改动）。

### §1.3 生成物（**由 patcher 重新生成，非手改**）

| 文件 | before sha16 / bytes / mtime | after sha16 / bytes / mtime |
|---|---|---|
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | `799e0366b312ec65` / 55,223 B / 2026-09-16 15:31:51 | **`fef2cfb47f882a82`** / 56,380 B / 2026-09-17 00:12:27 |
| 备份 | `$HOME/w23b-backup/TextFormatterImp.Linux.cs.before` | — |

重生成日志（原样）：
```
[断言] P2/W19-B 接线：透传 indent=1 para=1；来源（原始 DIP）= 2/2（严格档 + 宽松档）✅
[断言] W23-B 段落原点：宽松兜底透传 `paragraphOrigin: cpFirst` = 1（要求 1）✅
[断言] 大括号平衡 {=116 }=116；上游 776 行 → 生成物 1172 行（+396 行，全是判断与注释）
[生成] build/PresentationCore.Linux/TextFormatterImp.Linux.cs：已从上游重生成（2 处 D3 修改）
[接线] csproj 已就位（幂等，不改）；生成物 Include=True；TEXTLINE_SHIM_DIRECT=True
=== 退出码 0 ===
```
生成物 `diff`（before→after）**只有两个 hunk**：头部注释 3 行 + 宽松档调用 9 行（**没有别的东西漂**）。
**纪律 38 红线实测**（再跑一次 patcher）：`before rerun: fef2cfb47f882a82` → `APPLY_RC=0`、日志 `[生成] …内容已是最新（未重写）` → `after rerun: fef2cfb47f882a82`（**逐字节不变**）、`--check CHECK_RC=0`，注入行仍在生成物 `:268`：
```
268:                            paragraphOrigin: cpFirst);
```
日志 `$HOME/w23b-run/patcher-rerun.log`／`patcher-recheck.log`。

### §1.4 重建 `pc`（本波唯一的重构建）

```
MemAvailable before build = 3491800 kB
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -c Debug -m:1 --nologo -v q
BUILD_RC=0 elapsed=32s      # 0 个警告 / 0 个错误
新 pc = 7b47a7b3d69ad62f   4197376 B  2026-09-17 00:13:09
```
| 件 | before | after |
|---|---|---|
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `e7cabff9417ed380` / 4,196,864 B | **`7b47a7b3d69ad62f`** / **4,197,376 B** |
| 备份 | `$HOME/w23b-backup/PresentationCore.dll.before` | — |

探针目录里的**私有副本**（`FrameProbe/bin/Release/`、`PcLineOracle/bin/Release/`）用 `cp -f` 同步到新权威件（两处 aftersha16 都 = `7b47a7b3d69ad62f`，且探针自己在日志里印"本机副本 / 权威路径"两个 sha，见 §3 头部）。

---

## §2 折叠相关 4 处**逐字节未变**的证据（停条件 §6.4）

同一份文本行在 before/after 里各取一次，`grep` 出来 `cmp`：

| 处（before 行号） | after 行号 | `cmp` |
|---|---|---|
| `:3612` `char.IsWhiteSpace(_text[_lineStart + visibleLen - 1 - prefixTrailingWs])` | `:3661` | **IDENTICAL** |
| `:3645` `string prefix = _text.Substring(_lineStart, visibleLen);` | `:3694` | **IDENTICAL** |
| `:3652` `cp = _plan.Sub(_lineStart, _lineStart + visibleLen);` | `:3701` | **IDENTICAL** |
| `:3655` `if (s.Start <= _lineStart && _lineStart < s.End) { lead = s; break; }` | `:3704` | **IDENTICAL** |
| `:2744` `_lineStart = lineStart;`（**赋值**） | `:2780` | **IDENTICAL** |

**⚠️ 主控点的那个陷阱已避开**：`:3612` 与 `_collapsedRange` 的 `:3619-3622` 在**同一个方法**里相隔 ~9 行 —— 我改的是后者（`:3670`，**加**原点）、前者**逐字节未变**（上面的 `cmp`）。`diff` 里该方法的唯一变化就是 `_collapsedRange` 那一行 + `BuildCollapsedLine` 的透传新增。

---

## §3 五组读数（预测 vs 实测）

### §3.1 ① `FrameProbe` 四条腿（主判据）—— **分母口径 = `script==latin` 的 288 例 / 421 行**（纪律 39）

命令形态（语料**绝对路径**、`unset DISPLAY`、`DOTNET_gcServer=0`）：
```
dotnet build/MilBridge/tests/FrameProbe/bin/Release/PresentationCore.Tests.dll \
  --corpus /abs/.../tests/parity/windows/tab-anchor/out/tab-anchor-raw.json <腿开关>
# 腿开关 = --tier lenient ｜ --tier strict ｜ --tier strict --fresh-source ｜ --tier strict --prefix 40
```
日志：修前 `$HOME/w23b-run/pre/frameprobe-*.log`｜修后 `$HOME/w23b-run/post/frameprobe-*.log`。

| 腿 | 修前实测 | **预测（预登记 §2.3）** | **修后实测** | 判定 |
|---|---|---|---|---|
| 宽松档 | 红行 **133** / 绿 288（红例 80） | 133 → **0** | **红行 3** / 绿 418（红例 3） | ⚠️ **未字面兑现**（差 3，见 §4） |
| 严格档 | 红行 **3**（帧红 0） | 帧仍 421/421 正确、**3 条结构红不变** | **红行 3（同上，逐字节相同）** | ✅ **兑现**（停条件 §6.3 未触发） |
| 严格档 + `--fresh-source` | 红行 **133** | 133 → **0** | **红行 3** | ⚠️ 同上（差 3） |
| 严格档 + `--prefix 40` | 红行 **421**（帧红 421） | 421 → **0**（**本修法正极性核心**） | **红行 3**（帧红 **0/421**） | ⚠️ 差 3；**帧族已全绿**（见 §4 的机器证） |

日志 sha16（16 位）：

| 腿 | 修前 | 修后 |
|---|---|---|
| 宽松档 | `083327db3ad5ebaf`（86,218 B） | `f71021955f2ed2e6`（91 行） |
| 严格档 | `8d38d06e1d75a73f`（16,376 B） | `37a8af16cf393f8c`（91 行） |
| 严格档+`--fresh-source` | `acd7ed678d1b5427`（86,077 B） | `c86f714108d1afc6` |
| 严格档+`--prefix 40` | `d1fd431aaebab595`（93,331 B） | `f74c7b1112fb6fcd`（794 行） |

**"消费者看得见"的读数**（`GetTextBounds(cpFirst,1)` 读到空的行）：宽松档 **104 → 0**；`--prefix 40` **522 → 0**；严格档 **0 → 0**；`--fresh-source` **104 → 0**。
**`--prefix 40` 修后的第一例原样**（`A-anchor/lat-a-t-b@w96@LTR@i0@default` 行#0/1/2）：
```
修前: 真机读法(cpFirst=40,1)=**空** 我方帧(扫描)=0  我方帧(_lineStart)=0 真值帧=40 判=红
修后: 真机读法(cpFirst=40,1)=非空 我方帧(扫描)=40 我方帧(_lineStart)=0 真值帧=40 判=绿
修前: 真机读法(cpFirst=41,1)=**空** 我方帧(扫描)=1  我方帧(_lineStart)=1 真值帧=41 判=红
修后: 真机读法(cpFirst=41,1)=非空 我方帧(扫描)=41 我方帧(_lineStart)=1 真值帧=41 判=绿
```
⇒ **origin 加在帧上、`_lineStart` 一字未动**（同一行同时显示 `扫描=41` 与 `_lineStart=1`，这正是 Option 1 的形状）。

### §3.2 ② `GetTextBounds` 的"空表 vs 真机夹取" —— **NOINFO**（不实现就不宣称）

臂内"越界读法现场"行，修前修后**逐字相同**：
```
FRAMEPROBE 越界读法现场 探了=288 例，其中 GetTextBounds(-1,1) 与 (+7) **都返回空表**的=288
（真机在 FullTextLine.cs:1493-1499 **夹取**，不返回空表）
```
⇒ 修前/修后**都**是 `288/288` 例返回**空表**：本件**没有**实现"夹取"，`shim:3094-3095` 的空表判据**按主控要求没有并入本修法**。⇒ **"夹取对齐"= NOINFO**（真机侧只有源码锚点，无运行期仪器），**不许**把"帧对了"读成"夹取也对了"。

### §3.3 ③ 零射程机器证（按列对比；脚本 `$HOME/w23b-run/colcmp.py`）

- **严格档腿：修前/修后日志逐字节相同**（只差 `时间=` 行与两行 `被测件 … sha16`）：
```
diff (剥掉"时间="行) 只剩 2 行 → 都是 pc sha：e7cabff9417ed380 → 7b47a7b3d69ad62f
CASE 3/3 逐列相同；LINECOUNT 60/60；汇总 1/1；仪器自证 1/1；层级来源 1/1；严格档计数 1/1；宽松档计数 1/1；口径 1/1
```
- **宽松档腿**：`LINECOUNT 60/60 逐列相同`（**分行结构没变**）、`口径`/`层级来源`(288/0/0)/`严格档计数`/`宽松档计数` 全同；**变的只有**：`红行/绿行/红例`、`LINE`/`RED` 集合（133→3）、`仪器自证` 的两个列（见下）。
- **`--prefix 40` 腿**：`CASE` 记录里**只有 `红行` 一列变了**（288 例全是 421→…），其余列逐字相同。
- **`PcLineOracle`：修前/修后日志 `cmp` 逐字节相同**（`db37ce865e8b91b1`，1,480 行，**连时间戳都没有**）⇒ Start 列族与其余全部列**零射程**：
```
PCLINE START 腿=汇总(B) 红=0 绿=421 判定行=421 NOINFO=0 红例=0 Start-only红例=0 未比真值行=0 未登记失败=67 其中点名Start列=0 最大Δ=0.000000 @-
PCLINE_EXIT rc=1（未登记失败 67 / 红 190 / 绿 98 / 不可比 148）
```
- **⚠️ 且这证明了 `#21` 的口径**："origin ≠ 0 时 `GetTextBounds(cpFirst,1)` 读到空"这条**只影响帧/读法族**，`Start` 列与其它成员**一个字节没动**。

### §3.4 ④ `D-F2` 两极化

| 读数 | 修前 | 修后 |
|---|---|---|
| 运行时 `HB_TEXTLINE` 串（`WPF_LINUX_TEXTLINE_DUMP`，单例 strict） | 三个字段 `grep -c` = **0 / 0 / 0** | **各 2 处**；原样：`candidates=371(扫描1次) scanCapped=0 segmentFaceUnresolved=0 runFaceSlotMissing=0` |
| 二进制级（`pc` 里 UTF-16 用户串出现次数） | `scanCapped=0 segmentFaceUnresolved=0 runFaceSlotMissing=0`（对照串 `candidates=` = 1） | **`scanCapped=2 segmentFaceUnresolved=1 runFaceSlotMissing=1`** |
| 计数牙齿 | — | `[断言] W23-B 段落原点…`；patcher 对 `paragraphOrigin: cpFirst` 计数 = **1** |

### §3.5 ⑤ 位移自证（预登记 §5）

| 位 | `#21` | 本波实测 | 预测 | 判定 |
|---|---|---|---|---|
| `hbtextline` | `76089e1de586ac91` | **`e89fed55fd8e32bc`**（290,825 B） | 变 | ✅ |
| `pc` | `e7cabff9417ed380` | **`7b47a7b3d69ad62f`**（4,197,376 B） | 变 | ✅ |
| `bridge` | `d567c26f197ec1e3` | 未变 | 不变 | ✅ |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | 未变 | 不变 | ✅ |
| `windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` | §7.1 | **均未变** | 不变 | ✅ |
| `pf` | `2fb1a896f8277647` | **未变**（本车道射程外；预测"变"由波尾重编引起） | 变 | ⏳ 不在射程 |
| `inputs_fp` | `a2b74537…e78e0` | **`6146f3641b87a5a7d74e182ab9ca3f6f72299377bbfce2993843cb56ccbca0ca`** | 变 | ✅ **两个原因**：① `build/shims/**/*.cs`（`76089e1de586ac91`→`e89fed55fd8e32bc`）② `src/WpfGfx.Linux.Native/tools/patch-*.py`（`daa1fe2a32d454cf`→`00c2179b87fc0509`）——两个子组的 sha 都确实变了 |
| 五臂门禁 | `PASS generation=#21 tree_gen=same` | 未跑（主控的活）；预测"先 advanced ⇒ 重钉后 PASS" | — | 交主控 |

**§5 表外位移：无。**

---

## §4 ⚠️ 残留红：**3 条**（预测 0；逐例点名 + 机器证它不是帧族）

四条腿的残留红**都是同样这 3 条**（`id` / 行# / 我方帧 / 真值帧）：

| # | `id` | 行# | 我方帧 | 真值帧 | 我方 cpFirst |
|---|---|---|---|---|---|
| 1 | `B-indent/lead-tab-b-t-c@w40@LTR@i24@tab0` | 1 | 1（prefix40 下 41） | 2（42） | 1（41） |
| 2 | `B-indent-extra/lead-tab-b-t-c@w40@LTR@i0p24@tab0` | 1 | 1（41） | 2（42） | 1（41） |
| 3 | `B-indent-extra/lead-tab-b-t-c@w40@LTR@i24nl@tab0` | 1 | 1（41） | 2（42） | 1（41） |

**机器证（`--tier strict --prefix 40 --json`，**全量 421 行**，不抽样；文件 `$HOME/w23b-run/post/prefix40-json.json`）**：
```
rows = 421
{'aligned': 418, 'misaligned': 3, 'frame==cpFirst': 421, 'green': 418, 'red': 3,
 'misaligned_and_red': 3}
行对齐(cpFirst==truth)且帧错的行 = 0        ← **帧族红 = 0/418**
hostReadOk=False 的行 = 0                    ← 修前 522
```
⇒ 修后**不变式 = `帧 ≡ cpFirst`（421/421 成立）**，而红 ⟺ **`我方 cpFirst ≠ 真机 startChar`** ⟺ **我方分行 ≠ 真机分行**（我们的第 1 行从 cp 1 起、真机第 1 行从 cp 2 起 ⇒ 臂把两个"不同的行"配成一对，帧自然不等）。
这 3 条正是 `#22` 已登记的两条结构事实的同一族：`W22C-report.md` §2.4/§8「**60 例（全 `@tab0`）我方分行多于真机**（多 101 行）」+「`cpFirst vs 真值 startChar` 不一致 **3** 行」，且**这三条在 `--tier strict` 的修前日志里就是那 3 条结构红**（帧恒 1、真值 2，逐字相同）。
⇒ **归因：与本修法无关的既有结构族；本修法的正极性（origin）在 418/418 对齐行上全绿。**
⇒ **我没有登记、没有压绿、没有改判据**（`FrameProbe/Program.cs` sha16 仍 `c6a66724ad56760a`）。**请主控裁决**：这 3 条要么进登记表（口径建议写"结构族，非帧族"），要么留给"分行对齐"那条线（`#22` 的纪律 45 草案）。

---

## §5 我推翻 / 修正了哪句话

1. **`--prefix 40` 的"421 → 0"这个预测本身是错的**（不是修法错）：预登记 §2.3 把该腿当作"纯帧红"，但该腿的 421 红里**一直混着 3 条结构红**（`#22` 修前严格档那 3 条，在 `--prefix 40` 下同样存在，只是被 421 全红淹没了）。⇒ 修后真值应为 **421 → 3**，其中**帧族 421 → 0**。**这条是我用全量 JSON 反算出来的**（§4），不是从日志表面读的。
2. **"宽松档 133 → 0"同样差 3**，理由同上（133 里含 3 条结构红；严格档修前 133 帧红里那 3 条是"帧恰好等于 cpFirst"所以没红，宽松档修前帧恒 0 所以它们红了）。**预测口径应写成"帧族红 → 0"**，否则每一格都会少算这 3 条。
3. **`_paragraphOrigin` 必须由"收集那一次调用"的 `cpFirst` 决定，不能由"请求那一行"的 `cpFirst` 决定**：严格档 `ParaCache` 命中时返回的是**收集时构造的行对象**（携带当时的 origin），所以 `paragraphOrigin: cpFirst` 只在**冷收集**调用上写值 —— 这也解释了为什么严格档腿修前/修后**逐字节相同**（这些行都是 origin=0 的段落里收集的）。**若有人把 origin 改成"每次调用都用当前 cpFirst 重新赋值"，严格档会在缓存命中时双重计数。**
4. **（顺带、非本件写域）`build/MilBridge/tests/TextLineProto/bin/Debug/PresentationCore.dll` 是 `#19` 的旧件 `f4a454c8fe69cdfe`**，不是当前权威件。我用它取 `D-F2` 的"早退分支"读数时**发现并弃用**（读到的 `HB_TEXTLINE` 行由旧 pc 产生 ⇒ 不可归因）。⇒ 交给主控 / W23C 的 applocal-sync 检查器（"探针 bin 里有过期 pc 副本"正是 `D-A2` 那一族）。
5. **主控上一条里的"W22C 报 133 行/88 例"确认是串了两列**（§0.3）：`W22C-report.md` §2.1 原文与日志都是 **`红行=133 红例=80`**；88 属 `#21` 的 `Start` 列（138 行/88 例）。

---

## §6 `NOINFO` 清单（缺数据就说缺，不许当绿）

1. **`GetTextBounds` 的"夹取"对照**：本件不实现 ⇒ 无修后读数；只有真机源码锚点（`FullTextLine.cs:1493-1501` + `CreateDegenerateBounds :1443-1453`）与"我方 288/288 仍返回空表"（§3.2）。**未测**。
2. **`D-F2` 早退分支（`PlanCalls == 0`）的运行期读数**：本机**没有**能以当前 pc 到达该分支的仪器 —— 该分支要"构造过行（`EnsureDumpInstalled` 才会装退出钩子）**且** `PlanCalls == 0`"，而**所有** `try` 路径（严格档/宽松档）都经 `FormatParagraph` ⇒ `NotePlan` 已 +1；唯一绕开它的既有探针是 `TextLineProto`（用单 run 便捷 ctor），但**它的 bin 里 pc 是 `#19` 旧件**（§5.4）⇒ 读到的不是当前件，**弃用**。⇒ 该分支的出口是**静态**证（代码 + `pc` 里 `scanCapped` 出现 2 次：正常分支 1 + 早退分支 1；§3.4）。**可被主控的应用门禁（空 `TextBlock` 那类）顺手行使**。
3. **`D-F2` 三个计数器的"非零极性"**：本机字体目录扫描得 `candidates=371`，远小于 `MaxScanFaces=4096` ⇒ **无法在不改产品件的前提下逼出 `scanCapped≠0`**；`segmentFaceUnresolved`/`runFaceSlotMissing` 同（未构造出触发条件）。⇒ 本件只证"**出口接通**（presence）"，**不证"计数会动"**。
4. **折叠行（`BuildCollapsedLine`）在 origin≠0 下的真值**：语料**没有覆盖**（`#21`/`#22` 同款登记）；本件只做了**透传**与"折叠 4 处逐字节未变"（§2），**没有**修后几何读数。
5. **`GetIndexedGlyphRuns` / `GetTextCollapsedRanges` 的修后真值**：`W22C` §4 已标 NOINFO，本件同样**未取**（本语的判据不含这两列；本件只保证它们进绝对系）。
6. **RTL 半边**：语料 `latin` 288 例**全 LTR**；RTL 33 行全在 `C-rtl-indent`（Hebrew，被覆盖闸跳过）⇒ 本修法在 RTL 上**未行使**。
7. **应用门禁（`TrimText` 省略号路径）**：主控的活；预登记 §5.1 的命名候选指向 `GetTextCollapsedRanges`/`_collapsedRange`（**本件动了 `_collapsedRange` 的 `CharacterIndex` 一列**）⇒ **若门禁读数变化，首选归因就是这条**。本件**未跑**门禁。

---

## §7 读数表与环境

### §7.1 开工/收工九位 + 指纹

| 位 | `#21`（开工复算，9/9 一致） | 收工 | 判定 |
|---|---|---|---|
| `bridge` | `d567c26f197ec1e3`（4,987,840 B） | `d567c26f197ec1e3` | 未变 ✅ |
| `pc` | `e7cabff9417ed380`（4,196,864 B） | **`7b47a7b3d69ad62f`**（4,197,376 B） | 变 ✅ |
| `pf` | `2fb1a896f8277647` | `2fb1a896f8277647` | 未变（表外？**不是** —— §5 说"由波尾重编引起、不在车道射程内"） |
| `windowsbase` | `1114a28ec5a03ab7` | `1114a28ec5a03ab7` | 未变 ✅ |
| `provider` | `9aa0d744802aaa31` | `9aa0d744802aaa31` | 未变 ✅ |
| `win32shim` | `0098234982391bbf` | `0098234982391bbf` | 未变 ✅ |
| `wic_shim` | `03b67fbcd7c385b6` | `03b67fbcd7c385b6` | 未变 ✅ |
| `hbtextline` | `76089e1de586ac91`（283,557 B） | **`e89fed55fd8e32bc`**（290,825 B） | 变 ✅ |
| `dwf` | `0ed422ef2dd46445` | `0ed422ef2dd46445` | 未变 ✅ |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | `b6acdba4f01599d8` | 未变 ✅ |
| `inputs_fp` | `a2b74537…e78e0` | `6146f364…ca0ca` | 变 ✅（两原因，§3.5） |
| `known-red.json` | `2fdc02931c2af796` | `2fdc02931c2af796` | **未动**（主控的件） |

### §7.2 仪器自证（纪律 35/40）

| 仪器 | sha16（前后都记） |
|---|---|
| `FrameProbe/Program.cs` | `c6a66724ad56760a`（37,216 B）—— **未动** |
| `FrameProbe/bin/Release/PresentationCore.Tests.dll` | `6b65924a52a59d89`（26,624 B）—— **未动** |
| `PcLineOracle/Program.cs` | `a787a9db23c3302c`（113,209 B）—— **未动** |
| `PcLineOracle/bin/Release/PresentationCore.Tests.dll` | `7c3211e96b219b01`（59,392 B）—— **未动** |
| `PcLineOracle/known-red.txt` | `89324f1f643167e5`（17,501 B）—— **未动** |
| 语料 `tab-anchor-raw.json` | `88559d670f1bb955`（1,196,289 B）—— **未动** |

**"我的修前读数 == W22C 的读数"**：剥掉 `时间=` 行后 `cmp` 逐字节相同：
`pre/frameprobe-lenient.log` ↔ `$HOME/w22c-laneW22C/run/v2lenB.log` → **`CMP_RC=0`**（都是 86,218 B）；严格档腿同理 **`CMP_RC=0`**。

### §7.3 环境与资源（纪律 32/§7）

| 项 | 值 |
|---|---|
| lane | **W23B** |
| 时间 | 2026-09-17 **00:12:06 → 00:33** +0800（关键读数 00:12–00:28） |
| kernel | `6.8.0-138-generic`；`nproc=3` |
| `loadavg` | 开工 `0.35 0.26 0.11`｜**收工 `2.18 2.36 2.20`** |
| `MemAvailable` | **开工 3,076 MB**（23:55 实测）｜**最低 2,804 MB**（`pc` 重建后 00:13:09 实测 2,872,284 kB）｜**收工 3,518 MB**（00:28:04：3,602,480 kB） |
| `SwapFree` | 开工 1,057 MB → 收工 1,063 MB |
| 构建纪律 | 全部 `dotnet … -m:1` + `DOTNET_gcServer=0`；**唯一**重构建 = `pc`（32 s，峰值后 2,804 MB ≥ 1,200 MB 门槛，未触发等待）；**未**跑 `-sln`、**未**跑 `verify-all`、**未**并发两个重构建 |
| 我名下的残留进程 | **0**（`ps` 逐 PID 核；`pkill -f` 全程未用） |
| ⚠️ 别家在跑 | 00:25 起有**另一条车道**的 `FrameProbe --leg b --tier lenient`（PID 339398/339401，cwd = `FrameProbe/bin/Release`，**不是我的**，未打扰）。**注意**：该进程用的是我在 00:13 `cp -f` 换过的**新 pc** ⇒ 若那是别人的修前读数，需要重取 |

### §7.4 我写/改的车西清单

| 路径 | 性质 |
|---|---|
| `build/shims/PresentationCore.HbTextLine.cs` | 改（`76089e1de586ac91` → `e89fed55fd8e32bc`） |
| `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` | 改（`daa1fe2a32d454cf` → `00c2179b87fc0509`）—— **主控批准的写域扩展** |
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | **由 patcher 重新生成**（`799e0366b312ec65` → `fef2cfb47f882a82`），非手改 |
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | 重建（`e7cabff9417ed380` → `7b47a7b3d69ad62f`） |
| `build/MilBridge/W23B-report.md` | 新建（本文件） |
| `$HOME/w23b-backup/*.before` | 备份（5 份：shim / patcher / 生成物 / pc / 两个探针副本） |
| `$HOME/w23b-run/**` | 读数、脚本（`run-legs.sh`、`colcmp.py`）、日志 |
| **未碰** | `known-red.json`、`tline-gate.sh`、`verify-all.sh`、`arm-logs/**`、`PcLineOracle/**`、`CoverageProbe/**`、`build/DirectWrite.Linux/wic-shim/**`、`applier-audit-expected.txt`、`docs/**`、`samples/**`、`tests/**` |

---

## §8 给主控的三条请求

1. **裁决残留 3 条**（§4）：它们是 `@tab0` 结构族（`cpFirst≠truth`），本修法在 418/418 对齐行上全绿。要么进登记表（口径："结构族/分行不等，**非帧族**"），要么明确留给分行对齐那条线。**我没有自行登记。**
2. **重钉 `known-red.json` → `#23` 时**，`FrameProbe` 的帧列**不在**五臂门禁里（`tline-gate.sh` 不读它）⇒ 帧列本身仍需主控决定是否纳入自动判据（`#22`/`#21` 都提过这条缺口）。
3. **应用门禁**（主控两趟）：本件动了 `_collapsedRange.CharacterIndex`（省略号路径）⇒ 若 `drawn/colors/frames` 有位移，**首选归因 = `TrimText` 的 `CharacterEllipsis`**（预登记 §5.1）；`PcLineOracle` 与严格档腿已证**逐字节零射程**，所以门禁若变，几乎只可能是这条。
