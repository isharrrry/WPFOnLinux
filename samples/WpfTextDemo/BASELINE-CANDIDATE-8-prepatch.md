# BASELINE **候选件**（`#8` 之前的两趟）—— **不是基线，不要当基线用**

- **裁定**：主控 2026-09-14 明确 **"不要用这两趟冻 #8"** —— 波 19/20 期间 M7b 的 native 修饰键修法
  **两次不完整**（① 左右专有位 `0xA2` vs WPF 通用 `VK_CONTROL 0x11` ⇒ 反相；② **整批抽干** ⇒
  处理 `a↓` 的 `WM_KEYDOWN` 时实时表已被 `Ctrl↑` 清掉），第三次补丁（**逐消息修饰键快照**）尚未构建。
  ⇒ 这两趟只作 **"快照补丁之前"的对照数据**；**当前有效基线仍是 `ACCEPTANCE-BASELINE.md` 里的 `#7`**。
- **为什么仍然留档**：主控原话"上一趟的读数我会留作补丁前对照，不浪费"；且两趟的**门禁判据全绿**
  （候选件本身没有发现缺陷），只是**件还没定**。

## 候选 A：`~/wfp-runs/go-freeze8`（native 补丁①之后、快照补丁之前）
```
WPTD_ARTIFACTS bridge_sha=759a322431f1e457 bridge_bytes=4950352 pc_sha=ebf4cf872c76e4a1 pf_sha=3136f66563f858cd provider_sha=71ba86c6495347fe win32shim_sha=b2301ee237e72e5c wic_shim_sha=03b67fbcd7c385b6 hbtextline_shim_sha=e1bc947afc248b32 hbtextline_shim_stale=no hbtextline_stale_basis=auth hbtextline_src_mtime=1789348685 pc_compare_mtime=1789349183 windowsbase_sha=8c073fab0da88169
WPTD_BRIDGE_SRC_STALE=no basis=pub=705ed5ccd0c498a1 now=705ed5ccd0c498a1 so_file_match=yes
WPTD_TIER_SUMMARY=default passed=3/3 failed=0 inconclusive=0 ｜ WPTD_TIER_SUMMARY=env passed=3/3 failed=0 inconclusive=0
WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10 runs=167 ｜ WPTD_SUMMARY=PASS tiers_passed=2/2
WPTD_GATE=PASS acceptance=2/2 line_advance=PASS（runner exit=0）
```
- 八位与当时哨兵（`WAVE=wave19`）逐位相符；`drawn` default=260 / env=144，`colors` 3962 / 2828（与 #6/#7 同值）。
- ⚠️ 该趟的 census **只打汇总**（`T1C_CENSUS_SUMMARY`），`GLYPH_CENSUS run#` / `CTM=` / `PushTransform=` **各 0 行**
  ⇒ 主控要的"`PushTransform=` 旁证"**不在这趟**，改从 probe 应用（`--app-env=WPF_LINUX_GLYPH_CENSUS=1`）那趟取。
- ⚠️ 该趟的 `ReachFramework.dll` bin↔权威 不一致对为 `9ad071feff03` vs `f608cbc9d7b0`（与 #7 那对不同）⇒ 集成波仍在动它。

## 候选 B：`~/wfp-runs/go-freeze8b`（native 补丁① 的最终 sha `e41048f8786d6bc8`）
```
WPTD_ARTIFACTS bridge_sha=759a322431f1e457 bridge_bytes=4950352 pc_sha=ebf4cf872c76e4a1 pf_sha=3136f66563f858cd provider_sha=71ba86c6495347fe win32shim_sha=e41048f8786d6bc8 wic_shim_sha=03b67fbcd7c385b6 hbtextline_shim_sha=e1bc947afc248b32 hbtextline_shim_stale=no hbtextline_stale_basis=auth hbtextline_src_mtime=1789348685 pc_compare_mtime=1789349183 windowsbase_sha=8c073fab0da88169
WPTD_BRIDGE_SRC_STALE=no basis=pub=705ed5ccd0c498a1 now=705ed5ccd0c498a1 so_file_match=yes
WPTD_TIER_SUMMARY=default passed=3/3 failed=0 inconclusive=0 ｜ WPTD_TIER_SUMMARY=env passed=3/3 failed=0 inconclusive=0
WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10 runs=167 ｜ WPTD_SUMMARY=PASS tiers_passed=2/2
WPTD_GATE=PASS acceptance=2/2 line_advance=PASS（runner exit=0）
```
- 八位与当时哨兵（`WAVE=wave20-native`）逐位相符；门禁读数与候选 A **逐值相同**
  ⇒ **native 修饰键这一位（`b2301ee2…` → `e41048f8…`）对门禁判据零影响**（这一点本身是有用的读数）。
- 与本轮其它读数（`tline` / RTL / `text-dp-min` / `textbox-edit`）的关系见 §"本轮对照集"。

## 本轮（候选 B 的件上）对照集 —— 供"快照补丁之后"逐项对比
| # | 项 | 位置 |
|---|---|---|
| 1 | `tline` 六项 | `~/wfp-runs/tline-wave20prepatch.log`（件 = 候选 B，`pc=ebf4cf87…`） |
| 2 | RTL 三条 | `~/wfp-runs/go-rtl-wave20prepatch/` |
| 3 | `--only=textbox-edit`（**`Ctrl+A` 已生效**、写后读数已在） | `~/wfp-runs/go-textbox-wave21/`、`~/wfp-runs/go-textbox-wave21b/` |
| 4 | `--only=text-dp-min`（零注入，DP 腿反证） | `~/wfp-runs/go-textdpmin-wave21c/` |
| 5 | `WFP_POSTWRITE` / `PERLINE` 逐行 tuple | 同 3 |

### 本轮实读结果（2026-09-14 09:4x–09:5x）
- **`tline` 六项：与上一趟（`tline-wave19`）逐项相同** —— `exact=73 diff=0`；`行级 972/972；用例级 213/213`；
  `行 1286/1298；①286/286 ②68/68 ③984/988；宽度超差 47`；`Height 1298/1298、Baseline 1298/1298、Extent 1260/1298`；
  `判定 1298/1298；明细 218/236`；`通过 20 / 失败 2`（两条 ❌ 是**已登记未实现项**，harness 明确"保留红"）。
- **RTL 三条：全绿且与修法②那趟逐位相同** —— 判据1 `Δright=1 / Δw=0 / 墨迹比 0.97`；
  判据2 镜像 `k=71`、`mean|Δ|=0.736`（正序最优 `1.958`）；判据3 块区 `x<600` 与修法②验收帧 **`AE=0`**。
- **项 7（T2b census 裁栈）在 `--only=text-rtl-*` 那趟得到正向证据**：`[GLYPH_CENSUS] run#` 明细 **50 行，`PushTransform=` 50 行，全部报 `无`**
  —— 与"修法② 之后 RTL run 不再 push 水平反转"**自洽**（该报 `无` 的地方报 `无`，不再是陈旧句柄）。
  注：门禁应用（`WpfTextDemo`）的 census 只打汇总（`run#`/`CTM=`/`PushTransform=` 各 0 行）⇒ 这一位**取不到自门禁趟**。
- **`--only=text-dp-min`（零注入）反证复现**：`WFP_TEXTDP t1='seed-文本' c1=0 sel='' line0='seed-文本'` →
  **`t2='A' c2=1 sel='A' line0='A'`** → `t3/t4` 同值；`[feat] text-dp-min OK`；本趟 `KEY_DIAG=0`、`push WM_CHAR=0`（确认零注入）。
- **`--only=textbox-edit`（本波 native = `39d343c801f12d0c`）**：
  - `WFP_LATE_SCHEDULED from=VerifyAll-complete after_ms=6000` ⇒ **时序修复生效**；
  - **写后读数存在且晚于注入**：首个按键 `KEY_DIAG` 在 **L540**，写后读数 `WFP_POSTWRITE t=13803 变更 text='AB' len=2 sel=2,0 changes=2` 在 **L636**；
    另有 `WFP_POSTWRITE-EVENT TextChanged #1 text='A' len=1` / `#2 text='AB' len=2`；
  - ⇒ **`Ctrl+A` 已生效**：注入语义从"插入"变**"替换"**（首字符后 `len=1`，不是 `len=8`）；
  - **T1c 判据工具**：`DP1_LEG state=closed rc=0 write_rows=4 reads_after_write=3 … hit@L2068`、
    `DP1_LEG_CHAIN Q5c Changed 已 raise=3 Q6b 即将 OnTextChanged=3 Q7a TextBox.OnTextContainerChanged 入口=3 Q7b 已 SetCurrentDeferredValue=2`、
    `DP1_LEG_WHY 写后读到的 DP 值 == 该读发生时的容器真值（'AB' @L2054）⇒ 该链当场闭合`
    （`first_inject=无` 是因为那一趟没开 `WPF_LINUX_KEY_DIAG=1`，工具的注入锚点取不到；写后读数本身在注入之后）。
  - `PERLINE=1`：`HBLINE_LINE#` **12 行**，形如
    `HBLINE_LINE#1 start=0 cpFirst=0 cpLast=8 len=8 nl=1 visible=7 hardBreak=0 **eop=1** forced=0 keepState=0 modifier=0 runs=2 spans=0 text="seed-文本"`
    （**eop=1 ⇒ EOP 分支确实走到** = 兑现 handoff:403）；`HBLINE_LINEQ#` **22 行** `cpFirst/cpLast/spans=1`
    ⇒ 回答"**哪一行被问过 `GetTextRunSpans`**"。
- **1400 计数**：`#7` 累计 120 → `go-freeze8` **+6 = 126** → `go-freeze8b` **+6 = 132**；两趟均 **0 次 1400**
  （另本轮 3 趟单块探针 = 3 次启动，亦 0 次）。

### 本轮顺手修的两处**我自己的 runner 缺陷**（"仪器看不见对象"族）
1. **块表漏块**：`run-wpfprobe.sh` 的 `BLOCKS` 只有 10 个名字，而样例实际注册 **11 块**（漏 `text-dp-min`）
   ⇒ `--only=text-dp-min` 时 10 块全被记 `skipped`、该块判定**根本没进汇总**；
   更危险的是**全量趟**：那块真 FAIL 也不会被看见。已补进 `BLOCKS`（现 `blocks=11`）。
2. **补块后立刻炸**：`行 729: input_leg: 未绑定的变量` —— `input_leg/near/norect/neg/spec` 原来只在
   "**有期望规格**"的分支里初始化 ⇒ **没配期望的块**走到键入腿就 `set -u` 崩。已在**循环头无条件给默认值**。
   （两条都是"表/默认值与实际对象漂移"⇒ 与 L12、桥契约那次同源。）


> 说明：本文件**只登记事实**；两趟候选件的原始证据在各自 `~/wfp-runs/go-freeze8{,b}/**` 与 `*.stdout.log`，
> 表头与判定原文**未做任何改写**。
