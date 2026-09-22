# 波 `#50` —— 预登记（`TASK-0702` / `R-GATE`：把「连续点击/交互响应」从**仓外仪器**收编进仓并接进 `verify-all`）

> 本文件是**落地前写死**的预登记（纪律：**判据先写、读数后取**；改了判据必须在本文件里留痕，不许"事后对齐"）。
> 本文件由车道 **W84A** 建立（`TASK-0702` 的**重派**：上一条同名车道 W80A **未留下任何现场** ——
> `build/MilBridge/W80A-report.md` 不存在、`~/w80a` 空、`verify-all.sh` 里 `grep -c 'R_GATE\|r-gate' = 0`、
> 步数声明仍是 `25` ⇒ 本车道**从零开始**，没有半截改动要接）。
> ⚠️ **协调项（请主控核）**：本文件此前**不存在**（`#50` 尚无预登记件），而 `verify-all.sh` 的
> `gen` 声明链要求「本代预登记件 H1 里出现本代号」⇒ 不建它，第 `[11]` 步会以 `prereg-absent` 报 `NOINFO`（红）。
> 因此 W84A **同趟**建了本文件（只写 R-GATE 一节）。若 `#50` 的收尾另有总预登记件，请把本节并入、不要并行两份。

---

## §0 起点现场（可复算）

| 量 | 值 | 来源 |
|---|---|---|
| 冻结基线 | `#49`（`gen=#49`，`f1d340d66c7c6ba3`） | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| `verify-all` 步数声明 | `VERIFYALL_STEPS-DECL: 25 gen=#49` ⇒ 现场 `names=25 decl=25` | `bash build/MilBridge/tools/verify-all-step-check.sh` |
| 仓外仪器 | `$HOME/w47b-click.sh`（`7e86e3f105dc8778`，14,933 B，`#47` 车道 W47B 留） | `sha256sum` |
| 被测载体 | `samples/WpfFeatureProbe` 第 ⑬ 块 `clickprobe`（`#47` 已进仓：ListBox 3 项／TextBox／标准 ComboBox＋`POS` 自报坐标） | `samples/WpfFeatureProbe/FeatureBlocks.cs` |
| `verify-all` 里的 R-GATE | **零命中**（`grep -c 'R_GATE\|r-gate' = 0`） | 现场 |

## §1 判据来源：**继承 `#49` 预登记 §3 B3 的六格表**（不新造判据）

`docs/WAVE49-PREREGISTRATION.md` §3 B3 已把 `R-GATE` 的判据**逐格写死**。本车道**逐格照做**，
并把每格落成装置里的一次真实点击/键入（腿 id 见括号），**读数只取 `app.log` 的 `EVT` 行或 X 服务器读数**：

| 预登记格 | 正向（本车道腿 id） | 反极性（本车道腿 id） |
|---|---|---|
| ① 点 ListBox 项 ⇒ `EVT lst.selection=<被点项>` | 点 `lstitem1` ⇒ `lst.selection=1`（`L3_lst1`） | 点卡片右侧空白（控件之外）⇒ **控件级** `EVT` 新增 = 0（`L2_blank`） |
| ② 点 TextBox ⇒ `EVT tb.focus` ≥ 1 | `L4_tb` | 点**窗口外** ⇒ 无新控件级 `EVT`（`L1_outside`） |
| ③ 点后键入 3 字符 ⇒ `EVT tb.text=` 行数 ≥ 3 且长度单调增 | `L5_type` | **未点击就键入** ⇒ `tb.focus` 不增、`tb.text` 不增（`L0_type_nofocus`） |
| ④ 点 ComboBox ⇒ `EVT combo.opened` = 1 ＋ 弹窗窗口出现（`IsViewable`） | `L6_combo` | 下拉开着时点**下拉外**空白 ⇒ 不得出现 `combo.selection`（`L7_combo_blank`） |
| ⑤ 点弹窗 item[1] ⇒ `EVT combo.selection=1` ＋ `combo.closed` = 1 | `L8_comboitem1` | — |
| ⑥ **每次 mouse-up 之后 `cap=none`**（`D-G55` 的机器指纹） | 每次点击后把指针在**卡片内**挪 2 px，读该 `EVT move` 行的 `captured=null`（`L*` 全体） | 换回**修前件** `libwpfwin32.so e700c383ec1ecdc8` ⇒ 本格必须**红**（产品级反极性） |

**本车道另加的两条（不替代上面六格，写在明处）**：

- **⑦ 承重连续腿**（`SEQ_lst0` / `SEQ_tb` / `SEQ_combo`）：指针**在窗口内**连续点三下（ListBox → TextBox → ComboBox），
  每一下都必须出各自的 `EVT`。**为什么它承重**：`#47` W47B 实测「逐个点击（每步把指针停到窗口外）全绿，
  而连做全红」—— 前者顺带释放了鼠标捕获 ⇒ **只有连做才等于用户真实动作**。
  本车道的**每一次**点击都在窗口内完成（除 `L1_outside` 本身），即整趟都是连续交互。
- **⑧ 像素通道**（`PX`）：下拉打开时**测试色 `22D3EE`** 的像素数 > 0（关着时的读数一并记）。
  它挡的是「WPF 说开着、屏幕上什么都没有」那一族（`D-G53`）；`22D3EE` 只染 `ComboBoxItem` 容器。

## §2 装置与三态（**先写死**）

- **装置**：`build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh`（起**私有** Xvfb、私有 app 目录、
  `xdotool` 真实节奏 `mousedown`→停 150 ms→`mouseup`、按 PID 收尾）。**判据不在装置里**：
  装置只落**证据**（`evidence.txt` 的逐步 `appline_from/to` 行号区间 ＋ `app.log` 原文）。
- **裁决件**：`build/MilBridge/tools/r-gate-step.sh`（**判据唯一实现**，逐格读 `app.log` 的区间切片）。
  机读行：`R_GATE=PASS|FAIL|NOINFO`（`verify-all` 的绿/红分支都会把它捞上屏）。
- **三态**：`rc=0` `PASS`｜`rc=1` `FAIL`（逐格点名 `fails=C1,C7,…`）｜`rc=2` `NOINFO`（**算不出 ⇒ 既不算绿也不算红**）。
- **`NOINFO` 的档**（逐条）：装置自报非 `OK`／缺 X 工具（`Xvfb`/`xdotool`/`xwininfo`）／窗口没出来／
  取不到 `POS`／`MemAvailable` 低于门槛／应用**中途死**（`STATE clickprobe` 缺席）／`sabotage` 已设却仍 `PASS`。
- **反极性两条（本车道必跑）**：① **产品级**：只换回 `libwpfwin32.so e700c383ec1ecdc8`（`#46` 冻前件）
  ⇒ ⑥ 及连做格必须**红**；② **仪器级**：`R_GATE_SABOTAGE=windowmove`（点击目标被移走 ⇒ 坐标失效）
  ⇒ 必须 `FAIL`；若它仍 `PASS` ⇒ 判 **`FAIL reason=sabotage-not-caught`**（装置无判别力，不许当绿）。

## §3 接线方式（**与 `#49` 预登记 §3 B3 的差异，写在明处**）

`docs/WAVE49-PREREGISTRATION.md` §3 B3 写的接线方式是「**并进既有门禁步，步数保持 25**」；
本车道收到的任务书（较新，2026-09-22）要求「作为 `verify-all.sh` 的**新一步** ⇒ 四处声明 25→26 同趟改」。
**本车道按任务书执行**（新加第 `[26]` 步 `R-GATE`），并在此如实登记这处**任务书与旧预登记的分叉**，
请主控在 `#50` 收尾时以本文件为准（旧那半句已过时）。四处同趟 = `DECL` 首行 ＋ `STEP-NAMES` 清单 ＋ 口径句 ＋ 本文件 H1（`#50`）。

## §4 世代与 `inputs_fp`（先声明，免得冻后读成事故）

| 位 | 预期 | 理由 |
|---|---|---|
| 九位产品件（`bridge`/`pc`/`pf`/`windowsbase`/`provider`/`wic_shim`/`hbtextline`/`dwf`/`win32shim`） | **不变** | 本车道**不改产品件**，只加判据与接线（现场核过：本步跑前跑后逐位相同） |
| `verify-all.sh` | **变** | 加第 `[26]` 步 ＋ 声明块四处同趟 |
| `inputs_fp` | **实测核**（`#49` 预登记预测"必变"，但 `fp_inputs()` 的 `find` 覆盖面**不含仓根的 `verify-all.sh`**）⇒ 以现场读数为准，见 `W84A-report.md` §6 |
| `known-red.json` / 五臂 | **不变**（本车道不重钉、不重取） | 步数变 **不**动臂 |

**步数**：`25 → 26`（唯一新步 `R-GATE`）。
