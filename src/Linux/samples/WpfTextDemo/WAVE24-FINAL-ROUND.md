# wave24（`close-wave-203111`）最终轮读数 — **#12 件上** — 2026-09-14 22:0x–22:1x（T3）

**件（九位，独立 `sha256sum` 实读；与 `close-wave.sh` 之后重建的哨兵逐位相符）**：
```
bridge 759a322431f1e457 ｜ pc 293f99525f5af4f2 ｜ pf 11791727d682e119 ｜ windowsbase e6216fe961a2bfb9
provider 71ba86c6495347fe ｜ win32shim 0098234982391bbf ｜ wic 03b67fbcd7c385b6
hbtextline 3081d088cda0431c ｜ dwf 2f77dbdf5e7e2cd5
```
- 与 `#11` 相比：**变 3 位**（`pc`/`pf`/`hbtextline`）；**未变 6 位**（`bridge`、`win32shim`、`wb`、`provider`、`wic`、`dwf`）—— 与"本波内容 = T1d 机制一（`IsTrailingWhitespace` 排除 `U+00A0`）"一致 ✓
- `BRIDGE_SRC_FP = 705ed5ccd0c498a1`（发布记录 == 现树重算 ✓）
- `hbtextline_shim_stale = no`（`hbtextline_stale_basis=auth`；`hbtextline_src_mtime=1789388836` < `pc_compare_mtime=1789389124`）

## 0｜纪律 23/24：仪器 sha（**跑前 / 跑后**）+ 静树记录
| 读数 | 仪器（**全路径**，⚠️ 两个同名 `Program.cs`） | 跑前 sha | 跑后 sha | 判定 |
|---|---|---|---|---|
| `tline` | `build/MilBridge/tests/**HbTextLineParity**/Program.cs` | `6652f310591cb8bc` | `6652f310591cb8bc` | 一致 ⇒ **有效** |
| `tab-zero`+`--known-red`、`--tab-oracle` | `build/MilBridge/tests/**CoverageProbe**/Program.cs` | `cc61299d6dc72277` | `cc61299d6dc72277` | 一致 ⇒ **有效** |
- **artifact 争夺检查（跑前）**：`pgrep -af 'run.sh tline'` 为空 ⇒ 无第二个写者 ✓（T1b2 已停手；今晚曾发生过一次抢 `gen/*`）。
- **环境**：`uptime 19 min`、`loadavg=6.72 6.64 4.08`（峰值 `8.24`）；外部负载已用 `ps` 核实 = **`wpf2web` 工程的构建**（`tools/locked.sh build fork-runtime/…`、`…HandyControl_Linux.csproj`，PID 26227/38985）⇒ **与本仓无关**；**读数未见异常**，无需归因外部负载。

## 1｜门禁（本车道独立跑的 `~/wfp-runs/go-freeze12c`）
```
WPTD_GATE=PASS acceptance=2/2 line_advance=PASS          ｜ runner exit=0
WPTD_TIER_SUMMARY=default passed=3/3 failed=0 inconclusive=0 ｜ =env passed=3/3 failed=0 inconclusive=0
WPTD_SUMMARY=PASS tiers_passed=2/2 ｜ WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10 runs=167
WPTD_BRIDGE_SRC_STALE=no basis=pub=705ed5ccd0c498a1 now=705ed5ccd0c498a1 so_file_match=yes
桥契约 ✅ ok(0 且无条款表；尾部=）  累计帧数 = 3)
判据⑤ 交叉校验：裁剪帧 vs `xwd -id` 直抓 AE=0（同刻两法互证，0=完全一致）
判据⑥ 取样：before=第一趟最佳（色数 3962）、after=第二趟最佳（色数 3761）
        ｜滚动前/后最佳帧逐像素差：AE=141605（>0 ⇒ 画面确实变了）      ← default 档
        ｜（env 档同口径：before 色数 2828 / after 2445、AE=135468）
```
- **6/6 条 `BASELINE … result=PASS`**；`leftover_after=0`×6；自产件一致性 **11 项全绿**。
- 与主控那趟（`go-freeze12b`）**逐项一致**（含 `exit=0`、判据⑤⑥ 同值）⇒ 两趟互为独立复取。

## 2｜`tline` 六项（带口径名）—— 定版仪器 `6652f310591cb8bc`
| # | 口径名（harness 原文） | 本趟实测 | 与 `#11`（`#12` 表头那版仪器）对比 |
|---|---|---|---|
| ① | **记账结构全等**（`Length+NewlineLength+TrailingWhitespaceLength+(WITW−W)`） | **1292/1298（不等 6）** | `#11` 1286/1298（不等 12）⇒ **变好 6 行** |
| ② | **宽度分桶**（`0 / ≤0.34DIP / >0.34DIP`，三桶和==1298 机检 OK） | **0=168 / ≤0.34=1089 / >0.34=41** | `#11` 167/1084/47 ⇒ `>0.34` **47 → 41** |
| ③ | **Extent 行级**（T2d） | **1260/1298** | 同（不动） |
| ④ | **折叠明细**（真折叠 236 行；判定一致 1298/1298） | **219/236**（不符 **17** 条） | `#11` 218/236（**仪器版本不同**，见 §6①） |
| ⑤ | **`T2b` A 组·断行位置** | **行级 972/972；用例级 213/213** | 同（不动） |
| ⑥ | **`T2c` Tab** | **34 可比例，不一致 0** | 同（不动） |
| ⑦ | **行度量** Height / Baseline / Extent | **1298/1298、1298/1298、1260/1298** | 同 |
| ⑧ | **Extent 余差清单** | **58 条（主对拍 38 + LH 组 20）** | 同（不变式） |
| ⑨ | 结论行 / 不一致用例 | **通过 21 / 失败 3**；**14 例**（`F_lat_words 1 + F_nbsp_zwsp 8 + M_modifier 5`） | `#11` 17 例（含 `A1_nbsp_zwsp 3`） |
逐字附注：`[完整明细] …（101 行；含 3 段：折叠 17 / Extent 58 / 记账 14）`

**★ 自洽性证据（本波机制一的直接体现）**：`#11` 的三个不一致家族里 **`A1_nbsp_zwsp`（3 例）在本趟消失**，家族表只剩 `F_lat_words 1 + F_nbsp_zwsp 8 + M_modifier 5` ⇒ 与"`IsTrailingWhitespace` **排除 `U+00A0`**"这条修法**方向一致**（NBSP 不再被算作行尾空白）。
⚠️ 主控口径：`折叠`/`T3 明细`/`T3b`/通过数**不与 `#11` 直接比绝对值**（仪器版本变了）。

## 3｜`tab-zero` + `--known-red`（`CoverageProbe/Program.cs = cc61299d6dc72277`）
```
rc=0
TAB_LINES 合计 cases=86 判定过=85 结构败=1 不可比(缺字形)=0 其中 bidi 重排例=24；Q3 clamp 铺满整行 28/28；…
TAB_LINES FAILCASE notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1
TAB_LINES KNOWN-RED notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1（已登记，不改退出码）
```
⇒ **`D-T1` 判据保持 `13 → 1`**：**射程内 12 例 ⇒ 0**、**第 13 例点名保留**（`KNOWN-RED` 已登记）；
⇒ **不是 `0/86`**（"收货闸门"未触发）；`--known-red` 语义按主控口径生效（**未给表 ⇒ 任何失败都算未登记 ⇒ `rc=1`**；`rc=2` = 喂错臂 JSON）。

### 3.1 `--tab-oracle`（默认档）—— **内容全绿，但 `rc` 构造性不可判**
```
TAB_ORACLE: cases=114 pass=57 fail=0  跳过(bidi 依赖，纯拉丁+RTL 段落)=57  无 GetTextBounds 的字符=0
             最大逐字差=0.0053 @no-tab@w40@LTR i=6 …
rc=1                      ← 但 pass=57 / fail=0
```
**根因（读码，`RunTabOracle` 末行）**：`return pass == total ? 0 : 1;`，而 **`total = 114` 含 57 例"按设计跳过"** ⇒ `57 != 114` ⇒ **恒 `rc=1`**。
⇒ **该档 `rc` 不可用作判据**（与 `--tab-lines-oracle` 改前"恒 `rc=0`"同族、**方向相反**）。判据一律以 **`TAB_ORACLE:` 判据行**为准。
**主控裁定（2026-09-14）**：登记为**仪器缺陷**，修法派 **T1d**（`total` 改为可判例数或 `fail == 0 ⇒ 0`，并加**阳性对照**：真失败 ⇒ 非零）；**本车道不改**。

## 4｜应用级读数（本波件）
- **RTL 三条**（`--only=text-rtl-pure,text-rtl` + census/VISTRANS）：
  **判据1**｜RTL `[23,89] 宽67 墨251` ｜ LTR `[22,88] 宽67 墨260` ⇒ `Δright=1`、`Δw=0`、墨迹比 `0.97` ✅
  **判据2**｜镜像最优 `k=71`、`mean|Δ|=0.736`（CTM 预测轴 `71.75`）｜正序最优 `m=+1`、`1.958` ✅
  **判据3**｜块区 `x<600` 与修法②验收帧 **`AE=0`** ✅ ｜ 项7：`run#` 明细 **25 行 / `PushTransform=` 25 行 / 全部「无」**（本趟只 2 块 ⇒ run# 数随之减少，口径正常）
- **`--only=text-dp-min`**（零注入反证）：`t1='seed-文本' c1=0 sel=''` → **`t2='A' c2=1 sel='A' line0='A'`** → t3/t4 同值；`WFP_GATE=PASS`、`ok=1 skipped=10`。
- **`--only=textbox-edit`**（`POSTWRITE`+`PERLINE`+`INPUT_TRACE`+`MSGFLOW_TRACE`+`KEY_DIAG`）：
  `DP1_LEG state=closed rc=0 write_rows=4 reads_after_write=3 hit@L2113`｜`DP1_LEG_CHAIN Q5c/Q6b/Q7a/Q7b = 3/3/3/2`｜
  `DP1_LEG_WHY 写后读到的 DP 值 == 该读发生时的容器真值（'AB' @L2099）⇒ 该链当场闭合`；
  `WFP_LATE_SCHEDULED from=VerifyAll-complete after_ms=6000`；
  **Ctrl 生效 ⇒ 替换语义**：`WFP_POSTWRITE-EVENT TextChanged #1 text='A' len=1` → `#2 text='AB' len=2`；写后 `WFP_POSTWRITE t=15133 变更 text='AB' len=2 sel=2,0 changes=2`；
  `PERLINE`：`HBLINE_LINE#` **13 行（全 `eop=1`）** ＋ `HBLINE_LINEQ#` **23 行**（`cpFirst/cpLast/spans=1`）。
  块按既定口径记 **INCONCLUSIVE**（`ok=0 fail=0 inconclusive=1`），**不是 FAIL**。
- **全块矩阵（11 块）**：`WFP_BLOCK_REGISTRY=ok(count=11，与样例注册表逐名一致)`、端到端 `11==11`、`blocks=11 ok=8 fail=3 inconclusive=0 skipped=0`、`colors=1309`。
  OK 八块：`popup/anim/opacitymask/effects/controls/virtualize/text-rtl-pure/text-dp-min`；
  **FAIL 三块（`textbox-edit`/`transforms`/`text-rtl`）—— 第五次证伪为采样范围伪影**：
  1. **帧穷举**（18 张整帧）：`#A855F7`(text-rtl) 总 **0**（0/18 帧）｜`#94A3B8`(transforms/Clip) 总 **0**（0/18）｜`#F97316`(textbox-edit) 总 **288**（**18/18 帧都有**）；
  2. **反证**（三块放最上面 `--only`）：`transforms OK(#EAB308=37842 #94A3B8=38080)`、`text-rtl OK(#A855F7=4942)`、`textbox-edit` 像素腿 `OK(#F97316=1625)` ⇒ **块可见即全绿**。
  ⇒ 与 **L20** 结论一致（连续第 5 次复现）：**深部块用 `--only` 当仪器；全量趟像素 FAIL 必须先帧穷举再定性**。
- **`1400`（两口径，不混用）**：**门禁口径** `#11`=156 → 本趟 **+6 ⇒ 162**；**每次启动口径** `#11` 后 174 → 本波 11 次启动（门禁 6 + 探针 5：`rtl/dpmin/textbox/matrix12/matrix12-3blk`）⇒ **185**。**两口径均 0 次发生**；本波各趟 `leftover_after=0`。

## 5｜`WPTD_ARTIFACTS_EXT`（逐字）+ `#11 → #12` 变化
```
WPTD_ARTIFACTS_EXT reachframework_sha=9cfb4233adce6e46 reachframework_role=visible-not-frozen systemxaml_sha=d6ea4ffe6a5d4737 systemxaml_role=visible-not-frozen presentationui_sha=f7aac7dcae14018a pfclassic_sha=55f981c3261309ea systemprinting_sha=650ac4d30f259d9c uiatypes_sha=2ac8d37b7cdc5afd uiaprovider_sha=352ccd757a2f2fb0 manipulations_sha=c264f0ec86fad755 libskia_sha=a02cd03f1ebcbb97 libskia_nuget_2_88_9_match=yes(nuget-2.88.9-linux-x64) ｜ 口径=扩展位变化**不自动作废基线**，但必须在下一版表头记录；reachframework/systemxaml 是**可见位、不进冻结元组**（每波都在动 ⇒ 噪声大于信息；若变了**且**门禁读数有差异则升级进元组）
```
**变化 3 处**（按口径登记）：`reachframework 96c9e238… → 9cfb4233adce6e46`、`presentationui 7af071d6… → f7aac7dcae14018a`、`systemprinting 3997e46a… → 650ac4d30f259d9c`。

## 6｜⚠️ 必写的三条注记
① **仪器版本分界（读数必须连着版本读）**
 - `#12` **表头**的 `tline` 读数取自 **裸断言版** `HbTextLineParity/Program.cs = 0d45032b20cfbfee`（`折叠 23` 条里含 **5 条假红**：裸断言 `cr.Width>=0` 过宽，**真机自己 430 条里就有 7 条负宽度**）；
 - **本轮**读数取自 **判别式版**（`ours<0 ⇒ truth<0`）`6e077361…` → **定版 `6652f310591cb8bc`** ⇒ **`折叠明细 219/236`（不符 17）是本版的正确期望**；
 - `记账 1292/1298`、分桶 `168/1089/41`、`Extent 1260` **两版相同**。
② **环境**：**22:0x 机器重启**过（`/tmp` 被清空 ⇒ #11 期的 `/tmp` 备份已不在；哨兵由主控据 `close-wave-203111/close-wave-summary.txt` 重建）；**外部 `wpf2web` 构建**使 `loadavg` 达 **6.7–8.2**（`ps` 已核实为**外部工程**）——**与本仓无关，且实测未扰动本仓数字**。
③ **退出码不可判（本波登记）**：本仓**两个 tab 档的 rc 今天都不可信、且方向相反** ——
   `--tab-lines-oracle` **改前恒 `rc=0`**；**改后"不给表 ⇒ 恒 `rc=1`"（这是有意的语义）**；`--tab-oracle` **恒 `rc=1`（构造性，见 §3.1）**。
   ⇒ **判据一律以判据行**（`TAB_ORACLE: cases=… pass=… fail=…` / `TAB_LINES 合计 … 结构败=N` + `KNOWN-RED` / `FAILCASE`）**为准，不看 rc**；修法已派 T1d（含阳性对照）。

## 7｜run 目录索引
`~/wfp-runs/go-freeze12c`（门禁）｜`go-rtl-wave25`｜`go-dpmin-wave25`｜`go-textbox-wave25`｜`go-matrix12`｜
`go-matrix12-3blk`｜`tline-wave12.log`（`tline`）。主控那趟门禁在 `~/wfp-runs/go-freeze12b`（`/tmp/gate12b.stdout.log`）。
