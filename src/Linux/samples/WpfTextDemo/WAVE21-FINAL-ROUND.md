# wave21-final 最终轮读数（**#8 冻结件上**）— 2026-09-14 10:0x（T3）

**件**：与 `ACCEPTANCE-BASELINE.md` 的 **#8** 同（哨兵 `WAVE=wave21-final`）：
`bridge 759a322431f1e457`(fp 705ed5ccd0c498a1) ｜ `pc 6be29475b6aeb34e` ｜ `pf 50da85138a7bc3e8` ｜
`wb e6216fe961a2bfb9` ｜ `win32shim 91baee84270f2322` ｜ `hbtextline e1bc947afc248b32` ｜
`provider 71ba86c6495347fe` ｜ `wic 03b67fbcd7c385b6`。八位均**独立 `sha256sum` 实读**并逐位相符。

## 1｜门禁（→ 冻 #8）
`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`，runner **exit=0**；default 3/3、env 3/3、`inconclusive=0`；
`distinct_origin_y=12`；`BRIDGE_SRC_STALE=no basis=pub=705ed5ccd0c498a1 now=705ed5ccd0c498a1 so_file_match=yes`；
`leftover_after=0`×6、`REAPED_ORPHANS total=0`；default `drawn=260/colors=3962`、env `drawn=144/colors=2828`（与 #6/#7 同值）。

## 2｜`tline` 六项（**逐项与上一趟相同**）
```
exact=73 diff=0 cases=73
行级 972/972；用例级 213/213
行 1286/1298；① 286/286；② 68/68；③ 984/988；宽度超差 47      ← 已登记未实现项
Height 1298/1298、Baseline 1298/1298、Extent 1260/1298；最大差 0.0013 / 0.0007
判定 1298/1298；明细 218/236；空参抛 253/253；空参返回 this 1045/1045   ← 已登记未实现项
通过 20 / 失败 2
```
测量对象被钉住（harness 自报）：`DirectWriteForwarder 879f0020→2f77dbdf5e7e2cd5`、`PC ebf4cf87→6be29475`、`WB 8c073fab→e6216fe9` 均已同步为权威件。

## 3｜RTL 三条（**全绿，且与修法②那趟逐位相同**）
- 判据1：RTL `[23,89] 宽67 墨251` ｜ LTR `[22,88] 宽67 墨260` ⇒ **Δright=1、Δw=0、墨迹比 0.97** ✅
- 判据2：镜像 `k=71`、`mean|Δ|=0.736`；正序最优 `m=+1`、`1.958` ⇒ **镜像成立** ✅
- 判据3：块区 `x<600` 与修法②验收帧 **`AE=0`** ✅
- 本趟 `WFP_SUMMARY blocks=11 ok=2 fail=0 inconclusive=0 skipped=9`、`WFP_GATE=PASS`、stderr 0 B。

### 2.1 ⚠️ `tline` 数字的**口径分裂**（主控 2026-09-14 指出；下一轮报数必须带口径名）
同一趟里"看起来都在说同一件事"的三个数字**其实是三个不同口径**，本轮实读的**原文**如下（引自 `~/wfp-runs/tline-wave21final.log`）：
```
[对拍面] 可逐位比用例 315（file 字体 + Ideal 模式 + 非 RTL）；其余 299 例只统计不给结论
[逐行记账·结构] Length+NewlineLength+TrailingWhitespaceLength+(WITW−W) ⇒ 全等 1286 / 1298
[宽度绝对值] 0（逐位等）167 行；≤0.34 DIP（= 1 个 ideal unit）1084 行；>0.34 DIP 47 行；最大差 282.219333 DIP（在 M_modifier_winf）
行级一致：Height 1298/1298、Baseline 1298/1298、Extent 1260/1298；最大差 Height=0.0013、Baseline=0.0007
[② Extent 余差清单] 共 58 条（主对拍集 38 + LH 组 20；容差 0.01 DIP）
❌ T2 真机口径逐行**记账结构**全等（①硬断 ②空行 ③行尾空白） :: 行 1286/1298；① 286/286；② 68/68；③ 984/988；宽度超差 47
```
**三个口径（我的读法，已标明来源行）**
| 口径名 | 数字 | 分母/含义 | 来源行 |
|---|---|---|---|
| **记账结构全等** | `1286/1298` | 行级：`Length + NewlineLength + TrailingWhitespaceLength + (WITW−W)` 四项全等 ⇒ **不等 12 行** | `[逐行记账·结构]` |
| **宽度绝对值分桶**（**另一个桶，不是"结构不等"**） | `>0.34 DIP = 47 行` | 行宽与真机之差 > 1 个 ideal unit 的行数（`0（逐位等）167` / `≤0.34 DIP 1084`） | `[宽度绝对值]` |
| **Extent 余差清单** | `58 条`（主对拍 38 + LH 组 20，容差 0.01 DIP） | T2d 的 **Extent** 行级余差**清单条数**，与上面两个都不同 | `[② Extent 余差清单]` |
| （附）行度量 | `Height 1298/1298、Baseline 1298/1298、Extent 1260/1298` | T2d 三度量的行级一致数 | `行级一致：…` |
**⚠️ 最容易被误读的一处**：那句 ❌ 汇总**把两个不同桶粘在一行** —— "行 1286/1298"（结构）**与**"宽度超差 47"（宽度桶）**不是同一口径的补集**（`1298−12` 是结构；`47` 属于宽度桶）。所以**不能**把 `1286` 和 `47` 相加/相减去推"实际错多少行"。
**测点时序（可能是"10 行之差"的来源，供 T1b 并排定义时验证）**：本趟的 `refresh_applocal` 在 **L7–L11** 把 app-local 副本同步为权威件
（`PC ebf4cf87→6be29475`、`WB 8c073fab→e6216fe9`、`DWF 879f0020→2f77dbdf`），而 T2 的记账/宽度测量在 **L62–L63** ⇒
**我这一趟是在"同步之后"测的**。若另一趟是在同步之前（或副本本来就陈旧）测的，行级结果可能就差那几行。

## 4｜项 7：census 裁栈的应用级旁证
`[GLYPH_CENSUS] run#` 明细 **50 行**、`PushTransform=` **50 行**、**全部报 `无`**：
```
CTM=[1.0417,0.0000,0.0000,1.0417,21.875,21.875]  PushTransform=无
CTM=[-1.0417,0.0000,0.0000,1.0417,591.125,40.594] PushTransform=无
```
⇒ 与"修法② 之后 RTL run 不再 push 水平反转"**自洽**（该报 `无` 的报 `无`，不再是陈旧句柄）。
（门禁应用 `WpfTextDemo` 的 census 只打汇总 ⇒ 这一位取不到自门禁趟。）

## 5｜`--only=text-dp-min`（零注入，DP 腿反证）
```
WFP_TEXTDP t1='seed-文本' c1=0 sel='' line0='seed-文本'
WFP_TEXTDP t2='A' c2=1 sel='A' line0='A'      ← 与主控预告逐字相同
WFP_TEXTDP t3='A' c3=1 sel='A' line0='A'
WFP_TEXTDP t4='A' c4=1 sel='A' line0='A'
```
`KEY_DIAG=0`、`push WM_CHAR=0`（**确认零注入**）；`WFP_SUMMARY blocks=11 ok=1 skipped=10`、`WFP_GATE=PASS`。

## 6｜`--only=textbox-edit`（`WFP_POSTWRITE=1` + `PERLINE=1` + `INPUT_TRACE` + `MSGFLOW_TRACE` + `KEY_DIAG`）
- **T1c 判据工具（注入锚点这次有值）**：
```
DP1_LEG state=closed rc=0 write_rows=4 reads_after_write=3 object=TextBox# dp=432 hit@L2086
DP1_LEG_CHAIN Q5c Changed 已 raise=3 Q6b 即将 OnTextChanged=3 Q7a TextBox.OnTextContainerChanged 入口=3 Q7b 已 SetCurrentDeferredValue=2
DP1_LEG_WHY 写后读到的 DP 值 == 该读发生时的容器真值（'AB' @L2072）⇒ 该链当场闭合
DP1_LEG_WINDOW last_write=L2058 **first_inject=L1744**
```
- **时序修复**：`WFP_LATE_SCHEDULED from=VerifyAll-complete after_ms=6000` ✅
- **写后读数（注入前心跳 → 注入后变更）**：
```
WFP_POSTWRITE t=13700 心跳 text='seed-文本' len=7 sel=0,7 changes=0
WFP_POSTWRITE-EVENT TextChanged #1 text='A' len=1
WFP_POSTWRITE-EVENT TextChanged #2 text='AB' len=2
WFP_POSTWRITE t=14068 变更 text='AB' len=2 sel=2,0 changes=2
```
  ⇒ **`Ctrl+A` 生效的可观测后果 = 替换语义**（首字符后 `len=1`，不是 `len=8 "Aseed-文本"`）；与主控已定案的口径一致（**正常预期，非异常**）。
- **`PERLINE=1`（handoff:403 兑现）**：`HBLINE_LINE#` **12 行**（全部 `eop=1`、`spans=0`）+ `HBLINE_LINEQ#` **22 行**（`spans=1`）：
```
HBLINE_LINE#1 start=0 cpFirst=0 cpLast=8 len=8 nl=1 visible=7 hardBreak=0 eop=1 forced=0 keepState=0 modifier=0 runs=2 spans=0 text="seed-文本"
HBLINE_LINE#2 start=0 cpFirst=0 cpLast=12 len=12 nl=1 visible=11 hardBreak=0 eop=1 forced=0 keepState=0 modifier=0 runs=1 spans=0 text="功能块台账（屏上副本）"
HBLINE_LINE#3 start=0 cpFirst=0 cpLast=9 len=9 nl=1 visible=8 hardBreak=0 eop=1 forced=0 keepState=0 modifier=0 runs=3 spans=0 text="(等待各块自报)"
HBLINE_LINEQ#1 cpFirst=0 cpLast=8 spans=1     ← 该行被问过 GetTextRunSpans（22 条同形）
```

## 7｜`1400` 计数（口径 = **门禁趟 × 6**，与 #6/#7 那条链一致）
`#7`=**120** → 候选A `go-freeze8` **+6=126** → 候选B `go-freeze8b` **+6=132** → **本最终趟 +6 ⇒ 138**；
**全程 1400 发生 0 次**（候选两趟、本最终趟、以及本波 **6 次**单块探针启动均 0 次）。
（若改用"每次应用启动都算"的口径 ⇒ 138+6=144；**两个口径不混用**，本条沿用 #6/#7 的门禁口径。）

## 8｜本轮 run 目录索引
`~/wfp-runs/go-freeze8c`（门禁=#8）｜`go-rtl-wave21final`（RTL+PushTransform）｜
`go-textdpmin-wave21final`（DP 反证）｜`go-textbox-wave21final`（写后读数+PERLINE+工具）｜
`tline-wave21final.log`（tline）｜候选件见 `BASELINE-CANDIDATE-8-prepatch.md`。
