# wave23（`close-wave-190934`）最终轮读数 — **#10 冻结件上** — 2026-09-14 19:2x（T3）

**件（九位，独立 `sha256sum` 实读，与 `close-wave.sh` **自动更新**的哨兵逐位相符）**：
`bridge 759a322431f1e457`(fp `705ed5ccd0c498a1`) ｜ `pc 628e741681ecb048` ｜ `pf 967c79c18dbfaac2` ｜
`wb e6216fe961a2bfb9` ｜ `provider 71ba86c6495347fe` ｜ `win32shim 0098234982391bbf` ｜
`wic 03b67fbcd7c385b6` ｜ `hbtextline 7c2e0107a9c86180` ｜ `dwf 2f77dbdf5e7e2cd5`。

## 1｜门禁 → **#10 已冻**
`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`；default 3/3、env 3/3、`inconclusive=0`；`distinct_origin_y=12`；
**`runner exit=0`**；6 条 BASELINE 与本趟机读文件**逐字一致**；`leftover_after=0`×6；`REAPED_ORPHANS total=0`；
`BRIDGE_SRC_STALE=no basis=pub=705ed5ccd0c498a1 now=705ed5ccd0c498a1 so_file_match=yes`。
门禁读数与 #6–#9 **逐值相同**（default `drawn=260/colors=3962`、env `drawn=144/colors=2828`）。
**本波变化位（vs #9）**：`pc e75c7bd5→628e741681ecb048`（含 T1d Tab 填宽口径修法）、`pf 52e106e5→967c79c18dbfaac2`（环成员）、
`hbtextline 4044d84a→7c2e0107a9c86180`（源；`stale=no`，权威 PC mtime 晚于源）；**未变 6 位**（含 `win32shim` —— native 未重建，符合预期）。
**哨兵**：`/tmp/bridge-frozen.flag` 本波由 `close-wave.sh` **自动更新**（含 `DWF=` 位）✅ —— 上一轮我提的"哨兵未更新"已被自动化修掉。
**自产件一致性**：11 项**全部 `一致`**（含此前连续三波不一致的 `ReachFramework.dll`）⇒ 集成波已对齐 app-local 与权威产物。
**扩展可见位**：三处再次变化（`reachframework a224b0973be9d7e2`、`presentationui 2e9a2d7f62ef286d`、`systemprinting 249a66bb129f5259`），按口径登记于 #10 表头。

## 2｜★ `tline` 六项（带口径名）—— **"#9 那 23 行缺口"：已闭合 ✅**
| # | 口径名 | #10（本波） | #9（中间态） | 冻前基准 |
|---|---|---|---|---|
| ① | **记账结构全等**（四项：`Length+NewlineLength+TrailingWhitespaceLength+(WITW−W)`；子桶①硬断②空行③行尾空白） | **1286/1298**（③ 984/988） | 1263/1298（③963/988） | 1286/1298 ✓ |
| ② | **宽度分桶**（`0 / ≤0.34DIP / >0.34DIP`，三桶和==1298 机检 OK） | **167 / 1084 / 47** | 167 / 1061 / 70 | 167 / 1084 / 47 ✓ |
| ③ | **Extent 行级**（T2d） | **1260/1298** | 1250/1298 | 1260/1298 ✓ |
| ④ | **Extent 余差清单**（容差 0.01 DIP） | **58 条（主对拍 38 + LH 组 20）** | 68（48+20） | 58（38+20）✓ |
| ⑤ | **折叠明细**（真折叠 236 行；判定一致 1298/1298） | **218/236** | 214/236 | 218/236 ✓ |
| ⑥ | **行度量** Height / Baseline / Extent | **1298/1298、1298/1298、1260/1298** | …、1250/1298 | ✓ |
| ⑦ | **T2b A 组·断行位置** | **行级 972/972；用例级 213/213** | 同 | ✓ |
| ⑧ | **T2c Tab 口径** | **34 例，不一致 0 例** | 同 | ✓ |
| ⑨ | 结论行 / 不一致用例 | **通过 20 / 失败 2**；**17 例**（`A1_nbsp_zwsp 3 + F_lat_words 1 + F_nbsp_zwsp 8 + M_modifier 5`） | 38 例（多出 `A1_tabs 13 + B_tabs 3 + B_tabs_trim 1 + F_tabs 4`） | 17 例 ✓ |

> **★ 结论一句话**：**该缺口已闭合** —— `tline` 六项**逐项回到冻前基准**，四个 `*_tabs` 家族**从"不一致"变为"不一致 0"**
> （`#9` 的 21 例增量全部消失，家族表回到 `17 = 12 + M_modifier 5`）。**这是我在同一 harness 上的独立复取**，
> 与 T1d 声称的"离线 harness 上全部命中"**一致**；**另两条失败（`T2` 记账结构子桶 / `T3` 折叠明细）仍是已知未实现项**，harness 保留红。
> ⚠️ 我**没有**用 T1d 的结论替代读数：上表每个数字都是本趟实跑原文。
>
> ⚠️ **Tab 的覆盖面（并排说明，勿读成「Tab 全部正确」）**：本语料（`layout-b34`，`DefaultIncrementalTab=0`）上 **`T2c` 不一致 0**；**默认配置 + `Wrap`** 路径上**另在册 `D-T1`**（`tab-zero` arm 结构败 12 例、`LTR` 亦错；规则见 `build/MilBridge/T1d-tab-and-modifier.md` §3.6/§10.1；待 U1 的 `Indent`/锚点 arm 定义后由 T1d 落，独立波 ⇒ #11）。**`Tabs` 显式停靠位仍未实现**（如实登记）。

## 3｜RTL 三条（PC/shim 源都变 ⇒ 已重取；**与修法②那趟逐位相同**）
- **判据1｜位置与宽度**：RTL `[23,89] 宽67 墨251` ｜ LTR `[22,88] 宽67 墨260` ⇒ `Δright=1`、`Δw=0`、比 `0.97` ✅
- **判据2｜镜像**：`k=71`、`mean|Δ|=0.736`（CTM 预测轴 `71.75`）｜正序 `m=+1`、`1.958` ⇒ 镜像成立 ✅
- **判据3｜旁及**：块区 `x<600` 与修法②验收帧 **`AE=0`** ✅
- `registry=ok(count=11)`、端到端 `2==2`、stderr 0 B；**项7 census：`run#` 明细 50 行 / `PushTransform=` 50 行 / 全部 `无`** ✅

## 4｜`--only=text-dp-min`（零注入反证）
`WFP_TEXTDP t1='seed-文本' c1=0 sel='' line0='seed-文本'` → **`t2='A' c2=1 sel='A' line0='A'`** → t3/t4 同值；
`ok=1 skipped=10`、`WFP_GATE=PASS`（零注入：`KEY_DIAG=0`、`push=0`）。

## 5｜`--only=textbox-edit`（`POSTWRITE`+`PERLINE`+`INPUT_TRACE`+`MSGFLOW_TRACE`+`KEY_DIAG`）
- **T1c 工具**：`DP1_LEG state=closed rc=0 write_rows=4 reads_after_write=3 hit@L2078`；
  `DP1_LEG_WINDOW last_write=L2050 **first_inject=L1718**`；
  `DP1_LEG_WHY 写后读到的 DP 值 == 该读发生时的容器真值（'AB' @L2064）⇒ 该链当场闭合`
- **时序修复在位**：`WFP_LATE_SCHEDULED from=VerifyAll-complete after_ms=6000`
- **Ctrl 生效 ⇒ 替换语义**：`WFP_POSTWRITE-EVENT TextChanged #1 text='A' len=1` → `#2 text='AB' len=2`；
  `WFP_POSTWRITE t=12817 变更 text='AB' len=2 sel=2,0 changes=2`
- **PERLINE 逐行 tuple**：`HBLINE_LINE#` **13 行（全部 `eop=1`）**＋`HBLINE_LINEQ#` **23 行**（`cpFirst/cpLast/spans=1`）；
  例：`HBLINE_LINE#1 start=0 cpFirst=0 cpLast=8 len=8 nl=1 visible=7 hardBreak=0 eop=1 forced=0 keepState=0 modifier=0 runs=2 spans=0 text="seed-文本"`
- 块按 D-P1 既定口径记 **INCONCLUSIVE**（`ok=0 fail=0 inconclusive=1`），**不是 FAIL**。

## 6｜全块矩阵（11 块）＋ FAIL 归属（**本件重跑 + 双证据**）
`registry=ok(count=11)`、端到端 `11==11`、`blocks=11 ok=8 fail=3 inconclusive=0 skipped=0`、`colors=1309`。
**OK 八块**：`popup/anim/opacitymask/effects/controls/virtualize/text-rtl-pure/text-dp-min`（读数与 #8/#9 同）。
**FAIL 三块**：`textbox-edit`／`transforms`／`text-rtl` ⇒ **再次全部证伪为采样范围伪影**：
1. **帧穷举**（18 张整帧）：`#A855F7` 总 **0**（0/18）｜`#94A3B8` 总 **0**（0/18）｜`#F97316` 总 **288**（**18/18 帧都有**）；
2. **反证**（三块放最上面 `--only`）：`transforms OK(#EAB308=37842 #94A3B8=38080)`、`text-rtl OK(#A855F7=4942)`、
   `textbox-edit` 像素腿 `OK(#F97316=1625)` ⇒ **块可见即全绿**。
⇒ 与 **L20** 一致（第三次复现同一结论）：深部块用 `--only`；全量趟像素 FAIL 必须先帧穷举。

## 7｜`1400`（两个口径，**不混用**）
- **门禁口径**（#6–#9 那条链）：`#9`=144 → **本趟 +6 ⇒ 150**；**0 次发生**。
- **每次应用启动口径**：本波 **11 次启动**（门禁 6 + 探针 5：`rtl/dpmin/textbox/matrix10/matrix10-3blk`）
  ⇒ 累计 **163**（`#9` 轮后的 152 + 6 + 5）；**0 次发生**。
- 六趟全部 `leftover_after=0`、`1400=0`。

## 8｜run 目录索引
`~/wfp-runs/go-freeze10`（门禁=#10）｜`go-rtl-wave23`｜`go-dpmin-wave23`｜`go-textbox-wave23`｜
`go-matrix10`｜`go-matrix10-3blk`｜`tline-wave23.log`。
