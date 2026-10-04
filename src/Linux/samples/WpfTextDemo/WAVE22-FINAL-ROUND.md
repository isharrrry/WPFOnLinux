# 统一波（wave22）最终轮读数 — **#9 冻结件上** — 2026-09-14 18:5x（T3）

**件（九位，均独立 `sha256sum` 实读，与主控给的逐位相符）**：
`bridge 759a322431f1e457`(fp `705ed5ccd0c498a1`) ｜ `pc e75c7bd5f465ede6` ｜ `pf 52e106e5f46a0dbb` ｜
`wb e6216fe961a2bfb9` ｜ `provider 71ba86c6495347fe` ｜ `win32shim 0098234982391bbf` ｜
`wic 03b67fbcd7c385b6` ｜ `hbtextline 4044d84a66539c42` ｜ `dwf 2f77dbdf5e7e2cd5`。

> ⚠️ **哨兵未更新**：`/tmp/bridge-frozen.flag` 仍是 `wave21-final` 的旧值（`PC=6be29475… / WIN32SHIM=91baee84… / HBTL=e1bc947a…`）。
> 本版以**主控消息 + 实读**为准；**建议下波起把哨兵一起更新**（否则拿哨兵冻结的人会拿错 —— 正是哨兵要解决的问题）。

## 1｜门禁 → **#9 已冻**（`ACCEPTANCE-BASELINE.md`）
`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`；default 3/3、env 3/3、`inconclusive=0`；`distinct_origin_y=12`；
`runner exit=0`；6 条 BASELINE 与本趟机读文件**逐字一致**；`leftover_after=0`×6；`REAPED_ORPHANS total=0`。
门禁读数与 #6–#8 **逐值相同**（default `drawn=260/colors=3962`、env `drawn=144/colors=2828`）。
`BRIDGE_SRC_STALE=no basis=pub=705ed5ccd0c498a1 now=705ed5ccd0c498a1 so_file_match=yes`。
**九位变化（vs #8）**：变 4 位（`pc`、`pf`、`win32shim`、`hbtextline`）；未变 5 位（`bridge`、`wb`、`provider`、`wic`、`dwf`）。
**扩展可见位（本波起机读；按口径登记变化）**：`reachframework ede1f364…→f23de9b2408d9e8c`、`presentationui bf20bd9e…→7d074c76…`、
`systemprinting 17beaac6…→0f79aaea…`；**`ReachFramework` 的自产件一致性检查本波首次变为 `一致 f23de9b2408d`**（此前连续三波不一致）。

## 2｜`tline` 六项（**每个数字带口径名**；与 #8 的差**全部落在新增 Tab 家族**）
| # | 口径名（harness 原文） | #9 实读 | #8 实读 | Δ |
|---|---|---|---|---|
| ① | **记账结构全等**（`Length+NewlineLength+TrailingWhitespaceLength+(WITW−W)`；子桶 ①硬断 ②空行 ③行尾空白） | **1263/1298（不等 35 行；①286/286 ②68/68 ③963/988）** | 1286/1298（不等 12；③984/988） | **−23** |
| ② | **宽度分桶**（`0 / ≤0.34DIP / >0.34DIP`；三桶和==1298 机检 OK） | **0=167 / ≤0.34=1061 / >0.34=70** | 167 / 1084 / **47** | **>0.34 桶 +23** |
| ③ | **Extent 行级**（T2d） | **1250/1298** | 1260/1298 | **−10** |
| ④ | **Extent 余差清单**（容差 0.01 DIP） | **68 条（主对拍 48 + LH 组 20）** | 58 条（38 + 20） | **+10** |
| ⑤ | **折叠明细**（真折叠 236 行） | **214/236**（判定一致 1298/1298） | 218/236 | **−4** |
| ⑥ | **行度量** Height / Baseline / Extent | **1298/1298、1298/1298、1250/1298** | 同 | 0 / 0 / −10 |
| ⑦ | （结论行）不一致用例 | **38 例** | 17 例 | **+21** |

**差异归属（家族级，可复算）**：
```
#9: 38 = A1_tabs 13 + B_tabs 3 + B_tabs_trim 1 + F_tabs 4（=21，新增家族）
        + A1_nbsp_zwsp 3 + F_lat_words 1 + F_nbsp_zwsp 8（=12，与 #8 逐项相同）
        + M_modifier 5（与 #8 相同）
#8: 17 = 12（同上三家族） + M_modifier 5
```
⇒ **增量 21 例全部落在 `*_tabs` 四个家族**，其余家族**逐项不变**。这与主控口径（**件版本 + `layout-b34` 配置对齐
`defaultIncrementalTab: 0`** ⇒ 这批 Tab 用例**从"不参与判定"变为"参与并暴露差异"**）一致；也与 T1b 报告里那句
"`defaultIncrementalTab: 0` 之后仍不一致 21 例（同 shim `4044d84a…`；不一致全在这四个家族，无一例在其它家族）"**互相印证**。
⇒ **不是回归**（没有任何旧家族的通过项变红），也**不是全绿**：Tab 这批是**新暴露的差异面**（`Tabs` 显式停靠位未做）。
**T1b 同时把口径名写进了 harness 输出**（`[口径·记账结构] …`、`[口径·宽度分桶] …（三桶和==1298 机检：OK）`）—— 这一点正是上一轮要求的"每个数字带口径名"。

## 3｜RTL 三条（PC/shim 都变了 ⇒ 已重取；**与修法②那趟逐位相同**）
- **判据1｜位置与宽度**：RTL `[23,89] 宽67 墨251` ｜ LTR `[22,88] 宽67 墨260` ⇒ `Δright=1`、`Δw=0`、墨迹比 `0.97` ✅
- **判据2｜镜像**：最优 `k=71`、`mean|Δ|=0.736`（CTM 预测轴 `71.75`）｜正序最优 `m=+1`、`1.958` ⇒ 镜像成立 ✅
- **判据3｜旁及**：块区 `x<600` 与修法②验收帧 **`AE=0`** ✅
- 本趟 `blocks=11 ok=2 skipped=9`、`registry=ok(count=11)`、`端到端 2==2`、stderr 0 B。
- **项7（census 裁栈）**：`[GLYPH_CENSUS] run#` 明细 **50 行 / `PushTransform=` 50 行 / 全部 `无`** ✅

## 4｜`--only=text-dp-min`（零注入反证）
```
WFP_TEXTDP t1='seed-文本' c1=0 sel='' line0='seed-文本'
WFP_TEXTDP t2='A' c2=1 sel='A' line0='A'   ← 与预告逐字相同
WFP_TEXTDP t3/t4 同值
```
`KEY_DIAG=0`、`push=0`（零注入确认）；`blocks=11 ok=1 skipped=10`、`WFP_GATE=PASS`。

## 5｜`--only=textbox-edit`（`POSTWRITE`+`PERLINE`+`INPUT_TRACE`+`MSGFLOW_TRACE`+`KEY_DIAG`）
- **T1c 工具**：`DP1_LEG state=closed rc=0 write_rows=4 reads_after_write=3 object=TextBox# dp=432 hit@L2003`；
  `DP1_LEG_CHAIN Q5c Changed 已 raise=3 Q6b 即将 OnTextChanged=3 Q7a TextBox.OnTextContainerChanged 入口=3 Q7b 已 SetCurrentDeferredValue=2`；
  `DP1_LEG_WHY 写后读到的 DP 值 == 该读发生时的容器真值（'AB' @L1989）⇒ 该链当场闭合`；
  `DP1_LEG_WINDOW last_write=L1975 **first_inject=L1611**`（锚点有值 ✅）
- **时序修复在位**：`WFP_LATE_SCHEDULED from=VerifyAll-complete after_ms=6000`
- **`Ctrl` 修饰键真的生效了**（本波 `乙` + 队列语义）：写后读数给出**替换语义**
```
WFP_POSTWRITE t=10435 心跳 text='seed-文本' len=7 sel=0,7 changes=0
WFP_POSTWRITE-EVENT TextChanged #1 text='A' len=1
WFP_POSTWRITE-EVENT TextChanged #2 text='AB' len=2
WFP_POSTWRITE t=11040 变更 text='AB' len=2 sel=2,0 changes=2
```
  （首字符后即 `len=1` ⇒ **替换**，不是插入 ⇒ 与主控预期一致）
- 块按 D-P1 既定口径记 **INCONCLUSIVE**（`blocks=11 ok=0 fail=0 inconclusive=1 skipped=10`），**不是 FAIL**。

## 6｜全块矩阵（11 块）与 3 个 FAIL 的归属（沿用 L20 反证法，**在#9 件上重跑，未转抄**）
`WFP_BLOCK_REGISTRY=ok(count=11)`、`端到端 11==11`、`blocks=11 ok=8 fail=3 inconclusive=0 skipped=0`、`colors=1309`。
逐块：`popup/anim/opacitymask/effects/controls/virtualize/text-rtl-pure/text-dp-min` = **OK**（读数与 #8 同）；
`textbox-edit`／`transforms`／`text-rtl` = **FAIL → 全部证伪为采样范围伪影**：
1. **帧穷举**（18 张整帧）：`#A855F7`(text-rtl) 总 **0**（0/18 帧）｜`#94A3B8`(transforms/Clip) 总 **0**（0/18）｜
   `#F97316`(textbox-edit) 总 **288**（**18/18 帧都有**）⇒ 前两色从未进帧（卡片在视口之下），第三个色在、**不在那个框里**；
2. **反证**（三块放最上面重跑 `--only`）：`transforms OK(#EAB308=37842 #94A3B8=38080)`、`text-rtl OK(#A855F7=4942)`、
   `textbox-edit` 像素腿 `OK(#F97316=1582)` ⇒ **块可见即全绿**。
⇒ 结论与 L20 一致：`--only` 是深部块的正确仪器；全量趟像素 FAIL 必须先做帧穷举再定性。

## 7｜`1400` 计数（两个口径，**不混用**）
- **门禁口径**（#6–#8 沿用的那条链）：`#8`=138 → **本趟 +6 ⇒ 144**；**本波 0 次发生**。
- **每次应用启动口径**：本波共 **11 次启动**（门禁 6 + 探针 5：`rtl/dpmin/textbox/matrix9/matrix9-3blk`）
  ⇒ 在 #8 之后累计 **152**（=147+5）；**0 次发生**。
- 六趟全部 `leftover_after=0`。

## 8｜run 目录索引
`~/wfp-runs/go-freeze9`（门禁=#9）｜`go-rtl-wave22`｜`go-dpmin-wave22`｜`go-textbox-wave22`｜
`go-matrix9`｜`go-matrix9-3blk`｜`tline-wave22.log`（tline）。
