# 证据件读者清点表（`_PHASE0-READERS-INVENTORY.md`）

> **状态：阶段 0 定稿。** 本件逐件列出候选移动件的**读取端**（哪个脚本/工具在读它），并给出
> "移动它要改哪几处 ＋ 是否要动 `inputs_fp`／`[42] --expect`／`close-wave.sh` 覆盖面"，
> 供**阶段 2（证据件归位）**直接用。产物本体、下一阶段的输入。
>
> 边界：本件是**清点**，**未搬任何件**；所有既有 `docs/*.md`、`handoff.md`、`ROUTES.md` **一个字节未动**。

---

## §0 清点方法（照 `TASK-阶段0.md` §④）

两种口径各扫一遍，扫描根 = `verify-all.sh build tests samples tools .github`（**排除** `upstream/`）：

```bash
# 口径①「文件名」：basename 作固定串扫
# 口径②「仓内路径」：docs/xxx 相对路径 + 绝对路径各扫一遍
grep -rlF "<basename 或 仓内路径>" verify-all.sh build tests samples tools .github | grep -v '^upstream/'
```

判"机读" vs "非机读"的规矩（本仓"读 ⇒ 进 `fp_inputs()`"同族纪律的延伸）：
- **机读**：脚本对**生产路径**做 `cat/grep/sed/sha256sum/glob/File.Exists`，其结论进门禁判词。
- **非机读**：注释（`#` / `//` / `///` / `<!--`）、散文报告（`*.md`）、自测**夹具**（临时沙箱里造同名件）、
  JSON 的说明字段（`known-red.json` 的 `"why"` 文本）。
- **basename 口径的已知陷阱**：`README.md`、`CURRENT-STATE.md` 等**同名件**会被误归。例如
  `docs/history/README.md` 在口径①下"命中" `pts-gap-count-check.sh` 的 `one README.md`，实读的是**根 `README.md`**。
  逐件结论以**口径②（仓内路径）**为准。

---

## §1 摘要（读数）

| 类别 | 件数 | 判读 |
|---|---|---|
| 候选件总数 | **84** | = 顶层 `docs/WAVE*.md` 67 ＋ `docs/history/**` 4 ＋ `docs/m7c-*.png` 2 ＋ 其它 `docs/*.md` 10 ＋ `handoff.md` 1 |
| **高风险（有脚本/工具机读端）** | **6** | `handoff.md`、`docs/CURRENT-STATE.md`、`docs/ROUTES.md`、`docs/unimplemented.md`、`docs/PORT-SPEC.md`、`docs/INDEX.md`（＋ 63 件 `WAVE*-PREREGISTRATION.md` 属**全域 glob 机读**） |
| **中风险（全域 glob，非逐件点名）** | **63** | 顶层 `WAVE*-PREREGISTRATION.md`（被 4 处 `docs/WAVE*-PREREGISTRATION.md` glob 扫到） |
| **低风险（零机读，仅散文/报告）** | **17** | `docs/history/**`（4）、`docs/m7c-*.png`（2）、`docs/ARCHITECTURE.md`、`docs/UPSTREAM-PROVENANCE.md`、`docs/THIRD-PARTY-APPS.md`、`docs/WIN-INTEROP.md`、`docs/PREREG-TEMPLATE.md`、4 件非 glob `WAVE*.md`（`WAVE15-RUNBOOK`／`WAVE46-PERTARGET-PRESENT-DESIGN`／`WAVE77-PREREGISTRATION-FRAGMENT-TASK0744-FU`／`WAVE78-PREREGISTRATION-FRAGMENT-TASK0739-3`） |
| **`inputs_fp`／`[42] --expect`／`close-wave.sh` 覆盖面受影响件** | **0** | 见 §2.5：`close-wave.sh` 的 `fp_inputs()` **不含任何 `docs/**` 或 `handoff.md`** |

---

## §2 真读取端登记（机读）

### §2.1 `[G4]` —— `docs/WAVE*-PREREGISTRATION.md` **全域 glob 读取端**（适用于 63 件）

| 端 | 位置 | 机制 |
|---|---|---|
| G4-① | `verify-all.sh:1131` | 步 `PREREG-FOUR-REQ`：`prereg-four-requirements-check.sh --gate --glob 'docs/WAVE*-PREREGISTRATION.md'` —— **逐件**判"四要件" |
| G4-② | `build/MilBridge/tools/boundary-decl-check.sh:312` | 步 `BOUNDARY-DECL` 牙：`CORPUS_PATHS=("docs/WAVE*-PREREGISTRATION.md")` —— 从语料**读回**边界声明与谓词参数（`:85` 亦为默认语料声明） |
| G4-③ | `build/MilBridge/tools/verify-all-step-check.sh:214` | 步 `VERIFYALL-SELF`：`ls -1 <root>/docs/WAVE*-PREREGISTRATION.md` —— 扫标题行找本代号 `gen` |
| G4-④ | `build/MilBridge/tools/wave-freeze-consistency-check.py:401` | `glob.glob(os.path.join(root,'docs','WAVE*-PREREGISTRATION.md'))` |

> 另有 `prereg-four-requirements-check.sh:437,448`（**自测**里对自身 glob）、`wiring-coverage-check.sh:267`（**自测**夹具文本），非生产路径。

**移动任一 glob 域件的改动面**：同趟改 **G4-①…④** 四处范式路径（`docs/` → 新目录）。**不动** `inputs_fp`／`[42]`／`close-wave` 覆盖面（§2.5）。

### §2.2 `handoff.md`（仓根哨兵 —— **最重**）

| 端 | 位置 | 机制 |
|---|---|---|
| H-① **仓根哨兵**（~18 个源文件、~20 处） | `build/DirectWrite.Linux/{FontEntryClosedLoop/Program.cs:148, Tests/TestLayout.cs:115,120, WicClosedLoop/Program.cs:540, WicWriteClosedLoop/Program.cs:308}`；`build/MilBridge/tests/{ContractProbe/Program.cs:248, TextLineProto/Program.cs:390, HbSpike/HbSpike.cs:378}`；`tests/WpfGfx.Linux.Tests/Commands.Tests/tools/verify-cmd-layout.py:20`；`tests/WpfGfx.Linux.Tests/Commands.Tests/{GeometryOracleTests.cs:137, MilExportTests.cs:108, GoldenBinaryReplayTests.cs:74}`；`tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/{CwicWrapperBitmapTests.cs:46, DP1ReproTests.cs:96, M7cInputPathTests.cs:48,452, M7cMilStreamTests.cs:53, MilWicQueryInterfaceTests.cs:50}`；`tests/WpfGfx.Linux.Tests/Rendering.Tests/RepoLayout.cs:39,54`；`tests/WpfGfx.Linux.Tests/Windowing.Tests/TestLayout.cs:66` | `File.Exists(Path.Combine(dir, "handoff.md"))` **向上找仓库根**（哨兵）。⚠️ 移动 `handoff.md` 出根 ⇒ 这些工具/测试的**仓库根解析全部失败** |
| H-② DEFREG 读内容 | `build/MilBridge/tools/defect-registry-check.sh:64`（步 `DEFECT-REGISTRY`）：`HO="${DRC_HO:-$R/handoff.md}"` | 读 `handoff.md` 的 **88 个编号行**（`DEFREG` 引用） |
| H-③ 根条目白名单 | `build/MilBridge/tools/root-entries-allowlist-check.sh:101`（步 `ROOT-ENTRIES`）：白名单声明 `handoff.md	移植面：逐波技术账` | 根条目**必须存在**，移动后白名单须改 |
| H-④ 自测夹具 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/t2b-test.sh:34`（`: > /tmp/t2b-build/handoff.md`） | 造夹具根，非生产读 |

> ⚠️ **名近实异**：步 `HANDOFF-MV`（`build/MilBridge/tools/handoff-machine-values-check.sh`）读的是
> **`build/MilBridge/HANDOFF-NEXT.md`**（`:73` 取 `$f`），**不是** `handoff.md`。别混。

### §2.3 `docs/CURRENT-STATE.md`（冻结基线唯一权威声明点）

| 端 | 位置 | 机制 |
|---|---|---|
| C-① | `build/MilBridge/tools/baseline-sha-check.sh:24`（步 `BASELINE-SHA`）：`STATE="${BSC_STATE:-$R/docs/CURRENT-STATE.md}"` | 读**冻结基线机器行**（`BASELINE-FROZEN gen=#82 sha16=05c5e521c3b14ace`） |
| C-② | `build/MilBridge/tools/defect-registry-check.sh:63`（步 `DEFECT-REGISTRY`）：`CS="${DRC_CS:-$R/docs/CURRENT-STATE.md}"` | route 键 `CS` |
| C-③ | `build/MilBridge/tools/sentinel-spec-check.sh:28`（步 `SENTINEL-SPEC`）：`CS="${SSC_CS:-$R/docs/CURRENT-STATE.md}"` | 哨兵规范 |
| C-④ | `build/MilBridge/tools/wave-push.sh:28`（步 `WAVE-PUSH`）：`CS="${WPW_CS:-$R/docs/CURRENT-STATE.md}"` | 推送面 |

> 非机读：`nul-bytes-check.sh:696,698`（自测夹具 `$T7/docs/CURRENT-STATE.md`）、`uia-door-check.sh:9`／`sync-applocal.sh:44`／`retake-arms-w23.sh:18`（皆注释）。
> ⚠️ **不是**任务清单里 `docs/CURRENT-STATE.md:9` 基线行 —— 移动本件**直接牵动 4 个门禁步**。

### §2.4 其余单件机读端

| 件 | 端 | 位置 |
|---|---|---|
| `docs/ROUTES.md` | 机读（现值锚点） | `build/MilBridge/tools/pts-gap-count-check.sh:428-433`（`one docs/ROUTES.md '工具口径…'/'可操作…'/'实现口径…'`，`$SITES` 默认 = 仓根 ⇒ 读**生产件**）、`:451`（`grep -nE '可操作\|实现口径' "$SITES/docs/ROUTES.md"`） |
| `docs/unimplemented.md` | 机读（现值锚点） | `build/MilBridge/tools/pts-gap-count-check.sh:443-444`（`one docs/unimplemented.md …`）、`:451` |
| `docs/PORT-SPEC.md` | 机读（只读引用 sha16） | `build/MilBridge/tools/hygiene-tooth.sh:148`（孪生件登记表 `HYG_TWINS_ML`：仓内件 `docs/PORT-SPEC.md` ↔ 夹具 `$HOME/w62a/negrepo/…` 对拍 sha16） |
| `docs/INDEX.md` | 机读（只读引用 sha16） | `build/MilBridge/tools/hygiene-tooth.sh:149`（孪生件登记表，同上） |
| `docs/WAVE66-PREREGISTRATION.md` | 机读（**具体路径**，非用 glob） | `build/MilBridge/tools/pts-gap-count-check.sh:163`（`sha256sum "$SITES/docs/WAVE66-PREREGISTRATION.md"`）、`:187`／`:263`（`cp -a` 到夹具，注释写明"W66 锚取自 `$SITES` ⇒ 夹具须同备，否则 live 不可读 ⇒ 假红"） |

### §2.5 `inputs_fp`／`[42] --expect`／`close-wave.sh` 覆盖面 —— 逐项裁定

- **`close-wave.sh` 的 `fp_inputs()` 覆盖面**（`build/close-wave.sh:70-…`）只 `find`：
  `src/WpfGfx.Linux.Native/tools/**`（`patch-*.py`）、`build/**`（`port-lib.py`／`integration-wave.sh`／`close-wave.sh`）、
  `build/shims/**/*.cs`、`src/WpfGfx.Linux/**/*.cs`、`src/WpfGfx.Linux.Native/**/*.{c,h}`。
  ⇒ **不含任何 `docs/**`、不含 `handoff.md`**。
- **`[42]` 步 `FP-MANIFEST-TEETH`**（`verify-all.sh:1204`）`--expect 237` 的**件数来源 = `fp_inputs()` 的清单行数**
  （`fp-manifest-step.sh` 明写"唯一权威清单来源是 `close-wave.sh` 的 `fp_inputs()`"）。
  ⇒ 移动任何候选件 **不动 `--expect`**。
- **结论**：**84 件中，0 件的移动会动 `inputs_fp`／`[42] --expect`／`close-wave.sh` 覆盖面。**
  （现有头注口径：`#82` 收官后 `--expect 234→236`／工作区现读 `237`，皆与 `docs/` 无关。）

---

## §3 逐件清点表（84 行）

- 「机读端」列：`[G4]` = §2.1 四端（**该件被全域 glob 扫到**）；具体行号 = 单件点名机读；`NOINFO` = **未见脚本/工具读取端**（任务 §② 上限内如实写，不猜）。
- 「移动改动面」列：`[G4]` 域件统一 = **同趟改 G4-①…④**；单件给具体处数；`—` = 无（零机读）。

### §3.A 单件文档 ＋ `handoff.md`（11 件）

| # | 件 | 机读读取端 | 移动改动面 | 散文引用（点名，非机读） |
|---|---|---|---|---|
| A1 | `handoff.md` | **H-① 仓根哨兵（~18 源文件/~20 处）＋ H-② `defect-registry-check.sh:64` ＋ H-③ `root-entries-allowlist-check.sh:101`** | 改 H-① 全部哨兵 ＋ H-② ＋ H-③（⇒ 判定"移动代价 ≫ 收益"，见 §4） | build/MilBridge/HANDOFF-NEXT.md、P1-*/W*-report.md（57 份）、samples/*/ACCEPTANCE-BASELINE.md |
| A2 | `docs/CURRENT-STATE.md` | **C-① `baseline-sha-check.sh:24` ＋ C-② `defect-registry-check.sh:63` ＋ C-③ `sentinel-spec-check.sh:28` ＋ C-④ `wave-push.sh:28`** | 改 C-①…④ 四处 ＋ 触碰唯一冻结基线声明点 | build/MilBridge/HANDOFF-NEXT.md、TAPPS-blind-half-report.md、73 份 W*-report.md |
| A3 | `docs/ROUTES.md` | **`pts-gap-count-check.sh:428-433,451`**（现值锚点） | 改 pts 脚本 6 处锚点行 ＋ `:451` 遍历项 | build/MilBridge/HANDOFF-NEXT.md、P0-*/P1-*/W*-report.md（258 份） |
| A4 | `docs/unimplemented.md` | **`pts-gap-count-check.sh:443-444,451`**（现值锚点） | 改 pts 脚本 2 处锚点行 ＋ `:451` 遍历项 | build/MilBridge/HANDOFF-NEXT.md 等 83 份 |
| A5 | `docs/PORT-SPEC.md` | **`hygiene-tooth.sh:148`**（孪生件登记表，读 sha16） | 改 `HYG_TWINS_ML` 该行（或作废该对拍） | build/MilBridge/W117A~W154A-report.md、samples/* |
| A6 | `docs/INDEX.md` | **`hygiene-tooth.sh:149`**（孪生件登记表，读 sha16） | 改 `HYG_TWINS_ML` 该行 | build/MilBridge/W117A~W123A-report.md、samples/* |
| A7 | `docs/ARCHITECTURE.md` | **NOINFO**（`verify-all.sh:637` 仅注释引用 `docs/ARCHITECTURE.md:347`） | — | build/MilBridge/W123A-report.md、samples/WpfTextDemo/ACCEPTANCE-BASELINE.md |
| A8 | `docs/UPSTREAM-PROVENANCE.md` | **NOINFO** | — | build/MilBridge/W123A-report.md、W138A-report.md |
| A9 | `docs/THIRD-PARTY-APPS.md` | **NOINFO**（`samples/ThirdPartyMini/ThirdPartyMini.csproj:9` 仅注释） | — | build/MilBridge/W123A-report.md、samples/* |
| A10 | `docs/WIN-INTEROP.md` | **NOINFO**（`build/third-party/{WpfLinux.props:26, WindowsDesktop.App.Linux.props:13, windowsdesktop-app-linux-framework.sh}` 皆注释） | — | build/MilBridge/P1-wininteropL{1,3}-impl-report.md、tasks-tail2/T-B{2,6}.md |
| A11 | `docs/PREREG-TEMPLATE.md` | **NOINFO**（`backup-completeness-gate.sh:224,228,292,302` 全在**自测沙箱**造件；`verify-all.sh` 仅注释） | — | build/MilBridge/W{115,117,120,122,131}A-report.md、W65-report.md、samples/* |

### §3.B 顶层 `WAVE*.md`（67 件）

> `[G4]` = §2.1 四端全域 glob（**63 件**适用）；4 件**不匹配** `docs/WAVE*-PREREGISTRATION.md` 的单独标注。

| # | 件 | 机读读取端 | 移动改动面 | 散文引用（点名） |
|---|---|---|---|---|
| B01 | WAVE15-PREREGISTRATION.md | [G4] | 改 G4-①…④ | build/MilBridge/T1b3-tline-gate-report.md、W123A-report.md、samples/* |
| B02 | WAVE15-RUNBOOK.md | **NOINFO**（不匹配 glob；仅散文） | — | build/MilBridge/W123A-report.md |
| B03 | WAVE16-PREREGISTRATION.md | [G4] | 改 G4-①…④ | T17A/TDT2/V79e/W123A-report.md |
| B04 | WAVE17-PREREGISTRATION.md | [G4]（另 `build/MilBridge/tests/{MinMaxProbe,PcLineOracle}/*` 仅注释） | 改 G4-①…④ | R17A/R17B/W17A~D/W123A-report.md |
| B05 | WAVE18-PREREGISTRATION.md | [G4] | 改 G4-①…④ | V18A/W22A/W76A/W123A-report.md |
| B06 | WAVE19-PREREGISTRATION.md | [G4]（另 `build/shims/PresentationCore.HbTextLine.cs:4737` 仅注释） | 改 G4-①…④ | W19B/W123A-report.md |
| B07 | WAVE20-PREREGISTRATION.md | [G4]（另 `StrictTierProbe/Program.cs` 仅注释） | 改 G4-①…④ | W20A/W21D/W123A-report.md |
| B08 | WAVE21-PREREGISTRATION.md | [G4]（另 `pc-line-step.sh:5` 仅注释） | 改 G4-①…④ | W21A~D/W27C/W123A-report.md |
| B09 | WAVE22-PREREGISTRATION.md | [G4]（另 `FrameProbe.csproj:4` 仅注释） | 改 G4-①…④ | W22A~D/W123A-report.md |
| B10 | WAVE23-PREREGISTRATION.md | [G4] | 改 G4-①…④ | build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md、W23B~D/W123A-report.md |
| B11 | WAVE24-PREREGISTRATION.md | [G4]（另 `frame-step.sh:5` 仅注释） | 改 G4-①…④ | wic-shim/known-red-PC-copies.md、W24B/W24D/W26B/W123A-report.md |
| B12 | WAVE25-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W25B/W25C/W123A-report.md、known-red-frame-structural.md |
| B13 | WAVE26-PREREGISTRATION.md | [G4]（另 `arm-log-sha-check.sh:59` 仅注释） | 改 G4-①…④ | W26C/W26D/W123A-report.md |
| B14 | WAVE27-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W27A/W123A-report.md |
| B15 | WAVE28-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W123A-report.md、samples/* |
| B16 | WAVE29-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W123A-report.md、samples/* |
| B17 | WAVE30-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W123A-report.md、samples/* |
| B18 | WAVE31-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W123A-report.md |
| B19 | WAVE33-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W123A-report.md、samples/* |
| B20 | WAVE34-PREREGISTRATION.md | [G4]（另 `frame-presence-check.sh:4` 仅注释） | 改 G4-①…④ | W123A-report.md、samples/* |
| B21 | WAVE37-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W123A-report.md、samples/* |
| B22 | WAVE38-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W123A-report.md |
| B23 | WAVE39-PREREGISTRATION.md | [G4]（另 `build/SelfBuiltConfig.props:24` 仅注释） | 改 G4-①…④ | W123A-report.md |
| B24 | WAVE41-PREREGISTRATION.md | [G4]（另 `boundary-decl-check.sh` **自测夹具**） | 改 G4-①…④ | W123A-report.md |
| B25 | WAVE42-PREREGISTRATION.md | [G4]（另 `boundary-decl-check.sh` **自测夹具**） | 改 G4-①…④ | W123A-report.md |
| B26 | WAVE43-PREREGISTRATION.md | [G4]（另 `tabgap-display-polarity.sh:18` 仅注释） | 改 G4-①…④ | W123A-report.md、samples/WpfFeatureProbe/KNOWN-DEFECTS.md |
| B27 | WAVE44-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W123A-report.md、samples/* |
| B28 | WAVE46-PERTARGET-PRESENT-DESIGN.md | **NOINFO**（不匹配 glob；仅散文） | — | W123A-report.md、W46G-report.md、samples/* |
| B29 | WAVE46-PREREGISTRATION.md | [G4] | 改 G4-①…④ | P1-e3-replay*/V79e/W46G/W123A-report.md、samples/* |
| B30 | WAVE47-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W48A/W49A/W123A-report.md、samples/* |
| B31 | WAVE48-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W49A/W50A/W123A-report.md、samples/* |
| B32 | WAVE49-PREREGISTRATION.md | [G4]（另 `r-gate-step.sh:17`／`WpfLinux.props:26`／`close-wave.sh:201` 皆注释） | 改 G4-①…④ | build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md、W53A~W100A-report.md、samples/* |
| B33 | WAVE50-PREREGISTRATION.md | [G4]（另 `r-gate-step.sh:17`／`run-r-gate-legs.sh:15` 皆注释） | 改 G4-①…④ | W84A/W87A-report.md、samples/* |
| B34 | WAVE51-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W97A~W109A-report.md |
| B35 | WAVE52-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W114A~W127A-report.md、samples/* |
| B36 | WAVE53-PREREGISTRATION.md | [G4]（另 `known-red.json:184` 为数据 `why` 文本） | 改 G4-①…④ | W130A/W133A/WC01-report.md、samples/* |
| B37 | WAVE54-PREREGISTRATION.md | [G4]（另 `known-red.json:188` 数据；`prereg-four-requirements-check.sh:372` 自测夹具） | 改 G4-①…④ | W140A-report.md、samples/* |
| B38 | WAVE55-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W141A-report.md、samples/* |
| B39 | WAVE56-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W143A-report.md、samples/* |
| B40 | WAVE57-PREREGISTRATION.md | [G4]（射程守卫：`prereg-four-requirements-check.sh:76` `REQ_EFFECTIVE_WAVE=58` 使 `<#58` 走 SKIP） | 改 G4-①…④ | samples/* |
| B41 | WAVE58-PREREGISTRATION.md | [G4] | 改 G4-①…④ | samples/* |
| B42 | WAVE59-PREREGISTRATION.md | [G4]（另 `prereg-four-requirements-check.sh:219`／`verify-all.sh` 皆注释） | 改 G4-①…④ | W151A-report.md、samples/* |
| B43 | WAVE60-PREREGISTRATION.md | [G4] | 改 G4-①…④ | samples/* |
| B44 | WAVE61-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W153A-report.md、samples/* |
| B45 | WAVE62-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W154A-report.md、samples/* |
| B46 | WAVE63-PREREGISTRATION.md | [G4]（`verify-all.sh` 注释） | 改 G4-①…④ | W152A-report.md、samples/* |
| B47 | WAVE64-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W64-report.md、samples/* |
| B48 | WAVE65-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W65-report.md、samples/* |
| B49 | WAVE66-PREREGISTRATION.md | **[G4] ＋ 具体路径机读：`pts-gap-count-check.sh:163`（sha256sum）、`:187`／`:263`（cp）** | 改 G4-①…④ **＋ `pts-gap-count-check.sh:163,187,263`** | P1-tail2-*/P1-ptsgap-*/W66-report.md（17 份）、samples/* |
| B50 | WAVE67-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W67-report.md、samples/* |
| B51 | WAVE68-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W68-report.md、samples/* |
| B52 | WAVE69-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W69-report.md、samples/* |
| B53 | WAVE70-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W70-report.md、samples/* |
| B54 | WAVE71-PREREGISTRATION.md | [G4]（`verify-all.sh` 注释） | 改 G4-①…④ | W71-report.md、samples/* |
| B55 | WAVE72-PREREGISTRATION.md | [G4]（另 `prereg-four-requirements-check.sh:130` 提及） | 改 G4-①…④ | W72/W74-report.md、samples/* |
| B56 | WAVE73-PREREGISTRATION.md | [G4] | 改 G4-①…④ | W73-report.md、samples/* |
| B57 | WAVE74-PREREGISTRATION.md | [G4]（`close-wave.sh:293` 仅注释） | 改 G4-①…④ | W74-report.md、samples/* |
| B58 | WAVE75-PREREGISTRATION.md | [G4] | 改 G4-①…④ | samples/* |
| B59 | WAVE76-PREREGISTRATION.md | [G4] | 改 G4-①…④ | samples/* |
| B60 | WAVE77-PREREGISTRATION-FRAGMENT-TASK0744-FU.md | **NOINFO**（不匹配 glob；仅散文） | — | P0-w78-report.md、samples/* |
| B61 | WAVE77-PREREGISTRATION.md | [G4] | 改 G4-①…④ | HANDOFF-NEXT.md、P0-w77*/V77b/VPts-report.md、samples/* |
| B62 | WAVE78-PREREGISTRATION-FRAGMENT-TASK0739-3.md | **NOINFO**（不匹配 glob；仅散文） | — | P0-w78-report.md、samples/* |
| B63 | WAVE78-PREREGISTRATION.md | [G4] | 改 G4-①…④ | P0-teeth-close/P0-w78-report.md、samples/* |
| B64 | WAVE79-PREREGISTRATION.md | [G4] | 改 G4-①…④ | P0-teeth-close-report.md、samples/WpfFeatureProbe/KNOWN-DEFECTS.md |
| B65 | WAVE80-PREREGISTRATION.md | [G4] | 改 G4-①…④ | HANDOFF-NEXT.md、P0-w80/VFinal-report.md |
| B66 | WAVE81-PREREGISTRATION.md | [G4]（`handoff-machine-values-check.sh:16`／`verify-all.sh` 皆注释） | 改 G4-①…④ | HANDOFF-NEXT.md、P1-*（15 份）、samples/* |
| B67 | WAVE82-PREREGISTRATION.md | [G4]（`verify-all.sh` 注释） | 改 G4-①…④ | P1-freeze82b-report.md、samples/* |

### §3.C `docs/history/**` ＋ `docs/m7c-*.png`（6 件）

| # | 件 | 机读读取端 | 移动改动面 | 散文引用（点名） |
|---|---|---|---|---|
| C1 | `docs/history/README.md` | **NOINFO**（口径①的"脚本读者"是 **basename 误归**：`pts-gap-count-check.sh:437` 的 `one README.md` 实读**根 `README.md`**；`grep -rn 'docs/history'` 零脚本命中） | — | build/DirectWrite.Linux/REPORT.md、build/MilBridge/HANDOFF-NEXT.md 等（116 份，皆 basename 误归） |
| C2 | `docs/history/U2-resource-pipeline-audit.md` | **NOINFO** | — | build/MilBridge/W123A-report.md |
| C3 | `docs/history/WAVE32-PREREGISTRATION.md` | **NOINFO**（不在 `docs/WAVE*` glob 内） | — | build/MilBridge/W123A-report.md |
| C4 | `docs/history/WAVE45-PREREGISTRATION.md` | **NOINFO**（`samples/WpfFeatureProbe/FeatureBlocks.cs` 仅注释） | — | build/MilBridge/W123A-report.md |
| C5 | `docs/m7c-accept.png` | **NOINFO** | — | build/MilBridge/W123A-report.md |
| C6 | `docs/m7c-accept-zero-probe.png` | **NOINFO** | — | build/MilBridge/W123A-report.md |

> 另：`docs/history/README.md` 的"脚本读者"名单（含 `arm-log-sha-check.sh`／`frame-step.sh`／`retake-arms-w21.sh` 等）
> 全部是口径①的 basename 误归（它们引用的是**其它** `README.md`／`CURRENT-STATE.md`，非 `docs/history/` 下件）。

---

## §4 裁定：证据件走"**移动**"还是"**索引折中**"

**裁定：走"索引折中"（物理件留原位，在 `docs.Linux/evidence/README.md` 做导航 ＋ 按 §4.3 加"历史证据"横幅）。**
阶段 2 据此**降级为索引页折中**（`UPSTREAM-ALIGN-PLAN.md` §5「阶段 2」的 ⚠️ 分支）。

**依据（引用清点表具体行）**：

1. **高风险 6 件的移动代价 ≫ 收益**（`UPSTREAM-ALIGN-PLAN.md` §6.8"代价过高则降级为索引折中"）：
   - `handoff.md`（§3.A1）：移动要同趟改 **H-① 约 18 个源文件/~20 处的仓根哨兵 ＋ H-② DEFREG ＋ H-③ 根白名单**，
     且"仓根哨兵"是本仓众多测试/工具的**通用定位惯例**，改动面横跨 `build/`、`tests/`、`samples/` 三个域；
   - `docs/CURRENT-STATE.md`（§3.A2）：唯一冻结基线声明点，**4 个门禁步**（`BASELINE-SHA`／`DEFECT-REGISTRY`／
     `SENTINEL-SPEC`／`WAVE-PUSH`）机读，移动即触碰红线（§3.3 基线）；
   - `docs/ROUTES.md`／`docs/unimplemented.md`（§3.A3/A4）：`pts-gap-count-check.sh` 以**现值锚点**机读
     （ROUTES 6 处、unimplemented 2 处），移动要逐个改锚点 —— 属"判据改自己"族，须整波并反极化。
2. **中风险 63 件的"移动收益"仅是目录美观，代价是牵动 40+ 件冻结证据的路径身份**：
   `TASK-阶段0.md` §①「为什么重要」点名 `docs/INDEX.md §4` 明令"**刻意不做大搬家**"；
   `UPSTREAM-ALIGN-PLAN.md` §3.8、§6.8 亦把"移动被冻结机器读取的件"列为**成败点**。
   `[G4]` 四处虽只改范式路径，但一旦改，**历史报告里逐字引用的 `docs/WAVE…md:NN` 行号锚**（如 §3.B49 的
   `P1-tail2-*` 17 份引用 `WAVE66-PREREGISTRATION.md`）即全部指向失效路径。
3. **"移动"唯一明显的净收益件只有低风险 17 件**（§3.B02/B28/B60/B62 ＋ §3.C1-C6 ＋ §3.A7-A11），
   它们**零机读**、只在散文里被引用 —— 但**量少（17 件）且分散**，单独成波不值当；留原位对门禁**零影响**。
4. **折中的安全性**：索引折中**一个字节都不动被读取件** ⇒ `[G4]`、`H-*`、`C-*`、pts 锚点、孪生件对拍
   **全部保持绿**；`inputs_fp`／`[42] --expect`／`close-wave` 覆盖面本就**不受影响**（§2.5）。

**若未来仍要改判"移动"**：前置条件 = 先清 §2.1-§2.4 全部机读端，且按 §4.3 的"防误读微调"（每件顶加横幅、
散文段折叠、**不改名**）作**一整波**做，`verify-all.sh` ×2 复跑 `64 ✅ / 0 ❌`。

---

## §5 主动披露（与方案不符 / 方案没预见到的读取端）

1. **`handoff.md` 被当作"仓根哨兵"**（§2.2 H-①）——方案（`UPSTREAM-ALIGN-PLAN.md` §6.8）只把它当
   "被 `DEFREG` 读的机器件"，**未预见**它同时是 ~18 个测试/工具的**仓库根定位锚**。移动代价远高于方案估计。
2. **`docs/WAVE66-PREREGISTRATION.md` 有"具体路径"真读端**（§2.4）——方案假设 `WAVE*` 一律"全域 glob"，
   实测该件另被 `pts-gap-count-check.sh` 以**硬路径** `sha256sum`/`cp`（`:163,187,263`）。
3. **`docs/PORT-SPEC.md`／`docs/INDEX.md` 被"孪生件登记表"机读**（§2.4，`hygiene-tooth.sh:148-149`）——
   方案未列此读取端；它读的是**只读 sha16 引用**（对拍仓外夹具）。
4. **basename 口径会产生"同名声明的误归"**（§0、§3.C1）——`README.md`／`CURRENT-STATE.md` 等同名件的
   "脚本读者"须以**仓内路径口径**复核，否则会高估风险（例：`docs/history/README.md` 实际零机读）。
5. **`build/MilBridge/tools/handoff-machine-values-check.sh` 名近实异**（§2.2 注）：读的是
   `build/MilBridge/HANDOFF-NEXT.md`，与候选件 `handoff.md` **无关**。
6. **4 件 `WAVE*.md` 不匹配 `WAVE*-PREREGISTRATION.md` glob**（§3.B02/B28/B60/B62）——它们是
   `-RUNBOOK`／`-…-DESIGN`／`-PREREGISTRATION-FRAGMENT-…` 命名，落在**全域 glob 之外**，零机读。
