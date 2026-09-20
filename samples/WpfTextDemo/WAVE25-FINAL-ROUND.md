# **#13 验收复取报告**（T3 独立复取）— 波 `close-wave-102523`

> 口径：**只跑我车道的件**（`samples/**` + 我自己的 runner/工具 + `:97`），**未冻基线、未开波、未动任何源**。
> `ACCEPTANCE-BASELINE.md` **我未动**；`#13` 表头由主控 2026-09-15 **10:33:40** 冻结，本报告写成时实读 **sha16 `e4d3ab40204c2809`**（mtime `10:33:59`）——**注意**：10:33 之前它是 `28e783084a3aa676`（`#12` 版），引用冻文件 sha 必须带时刻（纪律 24）。
> **所有读数都带四元组**：`(被测件 sha, 仪器 sha, 判据口径, artifact 名 + 字段名)`；**不跨波比绝对值**。

## 0｜仪器版本与四元组（跑前 10:34:32 → 跑后 10:49:15，逐条实读）

| 件（全路径） | 跑前 | 跑后 | 说明 |
|---|---|---|---|
| `build/MilBridge/tests/**HbTextLineParity**/Program.cs`（`tline` 仪器） | **`2e458928fc1577c2`** | **同**（不变 ✓） | `#13` 仪器版（主控裁决） |
| `build/MilBridge/tests/HbTextLineParity/bin/Release/MilBridge.HbTextLineParity.dll` | **`044fb81961f75013`** | **同**（A/B 两腿之间不变 ✓） | 直跑两腿共用这一份 |
| `build/MilBridge/tests/**CoverageProbe**/Program.cs`（oracle 仪器） | **`0046ed20d832a7ef`** | **同** ✓ | 跑后 **10:49:03 已变 `6c531b6ee0f8277c`** ⇒ **后续动作，不在本次读数内** |
| `build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll` | `6c9bf847854dca0f` | 同 ✓ | 构建+运行同一条命令（纪律 23） |
| `build/shims/PresentationCore.HbTextLine.cs` | **`fde9e511e8443cf2`** | **同** ✓ | 跑后 **10:48:27 已变 `6d0eeedc0168f419`**（T1d `D-F1` 落地）⇒ **`hbtextline` 位此后才变**，表头元组不受影响 |
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `d7a848dfeedcf29b` | 同 ✓（未重建） | — |
| 门禁 runner / 探针 runner | `5dfb2635b87bb351` / `92ce79c1dc1a257f` | 同 ✓ | — |

环境：`up 12:41`、门禁时 `loadavg=0.67`、`tline` 时 0.53–0.82、探针 0.74–1.92（**外部 `wpf2web` 已歇**；峰值 9.95 是波内重建，未在取数窗口）；`:97` 跑前不可达、跑后不可达（**无残留**）；门禁 12 次 `leftover_after=0`。

## 1｜`tline` 出货趟（腿A，B 列）—— **与主控给的 B 列预期逐位相符**

| 口径名 | 读数（artifact：`build/MilBridge/tests/HbTextLineParity` 控制台行） |
|---|---|
| 记账结构全等 | **`1298/1298`（不等 0 行：①硬断 286/286 ②空行 68/68 ③行尾空白 988/988）** |
| 宽度分桶 | **`0=168 / ≤0.34DIP=1096 / >0.34DIP=34`**（三桶和==1298 机检 OK）；最大差 **`6.716667 @ A1_nbsp_zwsp_w120`**（**#12 的 `282.219333 @ M_modifier_winf` 已消失**） |
| 折叠明细全等 | **`219→225/236`**（折后宽度最大差 `144.816000 → 9.680667 @ F_nbsp_zwsp_w80 行#0`） |
| 不一致用例 | **`14 → 10`** = `F_lat_words 1` + `F_nbsp_zwsp 8` + **`M_modifier 1`（=`M_modifier_w120 行#0 折叠明细不符`）** |
| 折叠不符条数 | **`17 → 11`**；记账不一致 `14 → 10` |
| `T2d` 行级 Extent / 余差 | **`1260 → 1259`** / **`58 → 59`（主 39 + LH 20；容差 0.01 DIP）** —— 主控已裁定**登记**（非回归） |
| `T2b` A 组 | `972/972`；`213/213`（**不动**） |
| `T2c` Tab | 保留红（口径不变） |
| `T2-iso` | ✅ `各和 34 == 总数 34`；与本腿上一趟 artifact（`t2d-width-diff.txt sha16=E47C801E7D95C0AA`）**逐族一位未动** |
| 判据汇总 | **通过 21 / 失败 3**：`T2`❌、`T3`❌（明细 225/236）、`T3b`❌（① 判别式红 `1/236` **真违反**，与 #12 同值） |

**幅度（同一批读数）**：`M_modifier_winf 行#0` 我们宽 **`439.1360 → 156.9280`**（真值 `156.9167`，差 **`282.2193 → 0.0113`**）；族内 `>0.34` 红数 **`7 → 0`**。

### 1.1 件 2·A/B（同 DLL 只切 `T1B_MODIFIER_META`）—— **差异 100% 落在 `M_modifier`**
- 腿B（`T1B_MODIFIER_META=0`，不传）：记账 **`1292/1298`**（不等 6）、分桶 **`168/1089/41`**、折叠 **`219/236`**、不一致 **`14`**、折叠不符 **`17`**、余差 **`58`**（与 **#12 逐位相同** ⇒ 旧路径未被动过）。
- 腿B 的隔离矩阵：`before`(=腿A artifact) `M_modifier=0` → `after` `M_modifier=7`，**`逐族 diff：M_modifier 0→7（允许）`，其它族一位未动** ✓。
- **我自己按 artifact 逐行 diff（A→B）**：

| artifact | 差异行 | 归属 |
|---|---|---|
| `gen/tline-detail-full.txt` | **27** | **全部 `M_modifier_*`** |
| `gen/t2d-extent-mismatches.txt` | **7** | **全部 `M_modifier_*`** |
| `gen/t2d-width-diff.txt` | **20** = 14 数据行（`-`7/`+`7，**全 `M_modifier_*`**）+ 6 行（`-`3/`+`3）该文件**自身汇总头**（`# 族×>0.34 红数`／`# 隔离矩阵`／`# 合计`，按定义随腿变） | **数据行里非 `M_modifier` 差异 = 0** ✓ |

⇒ 判据「**差异必须 100% 落在携带 modifier metadata 的用例上**」**成立**（`t2d-width` 那 6 行是**口径**问题：它们是自述表头，不是用例数据 —— 报告里必须写明，否则会被误读成"非 M_modifier 也动了"）。

## 2｜oracle 四档 + 两支阳性对照 + `D-T1`

| 档 | 判据行（artifact：控制台） | rc |
|---|---|---|
| 臂 A `--modifier-check` | `MODCHK 合计 用例=5 行=7｜行宽≤0.34 7/7｜len 7/7｜ws 7/7｜**Extent 0/7**｜lbNull 7/7`、`行失败 0/7` | **0** ✓ |
| 臂 B 门禁 `--modifier-rule-check <oracle>` | `MODRULE 用例=53（无可核 lineBreaks 的 0）行=170｜判据吻合 170/170（不符 0）` | **0** ✓ |
| 臂 B 排版档 `--modifier-armB` | `MODB 退出码=1（用例失败 18/18）`（各族 `0/n`） | 1 —— **登记不可比**（Arial 缺失），**不判缺陷** |
| `--tab-oracle` | `cases=114 pass=57 fail=0 跳过=57 最大逐字差=0.0053 @no-tab@w40@LTR i=6` | **0** ✓（rc 修已生效） |
| `D-T1` `--tab-lines-oracle --known-red` | `cases=86 判定过=85 **结构败=1** 不可比=0；Q3 clamp 28/28`＋`KNOWN-RED notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1（已登记，不改退出码）`、`未登记失败 0` | **0** ✓ |
| `D-T1` **不给表** | `UNREGISTERED notab-control…`、`未给 --known-red ⇒ 任何失败都算未登记` | **1** ✓（语义保持） |

**阳性对照（纪律 21：先证 rc 会非零）——两支都是我自己做的**：
1. `MODRULE`：翻 `/tmp/modrule-poscontrol.json`（`A-scope-line0/scope-line0@w80@LTR@i0` `lineBreaks[0]` `True→False`；sha16 `6fcf9fb7fab95039`）⇒ **`判据吻合 169/170（不符 1）`、rc=1、逐行点名** ✓；还原 ⇒ `170/170`、rc=0 ✓。
2. `--tab-oracle`：扰 `/tmp/taboracle-poscontrol.json`（`no-tab@w40@LTR` 的 `width 78.72→83.72`）⇒ **`fail=1`、rc=1、点名该例** ✓；还原 ⇒ `fail=0`、rc=0 ✓。

## 3｜门禁（我独立重跑；主控那趟已 PASS，两趟同值）

- `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`；`WPTD_TIER_SUMMARY=default/env passed=3/3 failed=0 inconclusive=0`（**6 条 `RESULT=PASS`**、`exit=143`、`leftover_after=0`、`max_concurrent_apps=1`）；
- `WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10 runs=167`；
- **九位**：`bridge 759a322431f1e457`(bytes 4950352)｜**`pc d7a848dfeedcf29b`**｜**`pf e36447bed6b29e8f`**｜`wb e6216fe961a2bfb9`｜`provider 71ba86c6495347fe`｜`win32shim 0098234982391bbf`｜`wic 03b67fbcd7c385b6`｜**`hbtextline fde9e511e8443cf2 stale=no basis=auth src_mtime=1789438795 pc_compare_mtime=1789439185`**｜`dwf 2f77dbdf5e7e2cd5`；
- `WPTD_ARTIFACTS_EXT`：`reachframework 062c465f3c2cb310`｜`systemxaml d6ea4ffe6a5d4737`｜`presentationui 8b688faa4d62c5df`｜`pfclassic 55f981c3261309ea`｜`systemprinting cec723f6cf41a574`｜`uiatypes 2ac8d37b7cdc5afd`｜`uiaprovider 352ccd757a2f2fb0`｜`manipulations c264f0ec86fad755`｜`libskia a02cd03f1ebcbb97 match=yes`；
- `WPTD_BRIDGE_SRC_STALE=no basis=pub=705ed5ccd0c498a1 now=705ed5ccd0c498a1 so_file_match=yes`（**非 `NOINFO`** ✓）；`bridge_publish_sha == app-local` ✓；
- 桥契约 `ok(0 且无条款表)`；判据⑤ 裁剪帧 vs `xwd -id` 直抓 **AE=0**、⑤b 几何自证 ✅、⑥ 真滚动 AE=141605 ✅。

## 4｜应用级（全块矩阵 + 单块反证 + L20）

- **全块矩阵**：`WFP_SUMMARY blocks=11 ok=8 fail=3 inconclusive=0 skipped=0 frames_good=14/14`、`WFP_BLOCK_REGISTRY=ok(count=11，与样例注册表逐名一致)`、端到端 `11==11`、`WFP_SRC_STALE=none`；
- **单块反证（把块放最上面）**：`transforms` ✅ `OK(#EAB308=37842 #94A3B8=38948)`｜`text-rtl` ✅ `OK(#A855F7=4942)`｜`text-rtl-pure` ✅｜`text-dp-min` ✅ `WFP_TEXTDP t4='A' c4=1 sel='A' line0='A'`｜`textbox-edit` 像素腿 ✅ `OK(#F97316=1625)` ＋ 键入腿(像素) ✅ `947→153`；
- **L20 帧穷举（18 帧整帧，`/tmp/wfp-run-106678`）**：`#A855F7`(text-rtl) **0（0/18）**｜`#94A3B8`(transforms/Clip) **0（0/18）**｜`#F97316`(textbox-edit) **288（18/18 帧都有）** ⇒ **与 #12 逐位相同** ⇒ **采样范围伪影**（深部块在 938 px 视口之外／坐标口径不同），**不是缺陷**（**连续第 6 次复现**）。

## 5｜`textbox-edit` 输入注入腿 —— **口径更正：证据在应用日志，不在 runner 日志**

runner 日志判 INCONCLUSIVE（`changes=0`）**不等于**注入腿没走。**应用原始日志**（`/tmp/wfp-run-137605/probe-only.log`，已按纪律备份 `~/wfp-runs/applog13/`，sha16 **`9f14785bf678ff89`**，2281 行）：

| 条件 | 读数 |
|---|---|
| ① `key_diag_lines` | **41**（>0 ✓） |
| ② `INPUT_TRACE` / `W5 写入口｜W4a SetValueCommon` | **1226 行 / 28 行**（>0 ✓；**runner 日志两者皆 0 ⇒ 它不转发应用 trace**） |
| ③ DP1 链 | **`DP1_LEG state=closed rc=0 write_rows=4 reads_after_write=3`**；`CHAIN Q5c/Q6b/Q7a/Q7b = 3/3/3/2`；`WHY 写后读到的 DP 值 == 该读发生时的容器真值（'AB'）⇒ 当场闭合` |
| ③ `changes` | **`WFP_POSTWRITE t=11047 变更 text='AB' len=2 sel=2,0 changes=2`**；`TextChanged #1 text='A'` → `#2 text='AB'`（**Ctrl 生效 ⇒ 替换语义**）；`HBLINE_LINE#` **13 行全 `eop=1`**、`HBLINE_LINEQ#` 23 行 |

⇒ **与 #12 同型（`closed`/`3-3-3-2`/`changes=2`/13+23 行），非回归。** runner 的 `changes=0` 取自应用**注入前**的自报快照（`[feat]` 行在 t≈3.8 s，而注入发生在 `WFP_LATE_SCHEDULED … after_ms=6000` 之后、写入在 t≈11.0 s）⇒ 属**取样窗口早于注入**。
> 给主控的裁定建议（不属我车道）：`textbox-edit` 块的 `changes` 判据应改读**应用日志末条写后读数**（或把 `WFP_POSTWRITE` 转发进 runner 日志），否则该块**恒** INCONCLUSIVE。

## 6｜RTL 三条判据（口径照 `rtl-after-fix2-20260913.json`；crop `470x400+0+0`、墨迹=底色欧氏距离>40、行 `y[209,220]`(RTL) vs `y[230,241]`(LTR)）

- **判据1（位置/宽度）绿**：`Δright = 89−88 = 1`（≤2）｜`Δw = 0`（≤3）｜墨迹比 `251/260 = 0.97`（∈[0.9,1.1]）；
  **且与验收帧逐位相同**：RTL `[23,89] 宽67 墨251`、LTR `[22,88] 宽67 墨260`、`ar_RTL [21,99] 79 356`、`heNum_RTL [23,121] 99 385`、`arNum_RTL [21,93] 73 262` —— **五行全同**；
- **判据2（镜像）绿**：列窗 `x∈[20,92]`（73 列）下 **镜像最优 `k=71`、`mean|Δ|=0.736`**（CTM 预测 `111.75−x ⇒ k=71.75`，±1 列内 ✓）｜**正序最优 `m=+1`、`1.958`**｜**分离度 2.7×** —— 与验收帧**逐位相同**；
- **判据3（无旁及）绿（版本内确定性口径）**：本趟两帧 `b-only-1` vs `b-only-2` **全 crop AE=0**、**纯 RTL 区 y205-320 AE=0**。
  （跨趟 AE 对 `go-fix2` 验收帧**刻意不做判据**：那是跨波比较且 bridge/PF 都变过 ⇒ 只作定性，见 `#instrument_notes ⑤`。）

## 7｜`1400`（两口径，**不混用**）与既有红

- **门禁口径**：`#12`=162 → **本趟 +6 ⇒ 168**；**每次启动口径**：`#12` 后 185 → **+6（门禁）+8（探针）⇒ 199**。**两口径命中均 0 次**（grep `Win32Exception (1400)` / `CreateWindowEx.*1400`）。
- **`APPSYNC` 既存红**（照 #11 措辞）：`samples/HelloWpf/bin/Release/net10.0/DirectWrite.Linux.Provider.dll` **MISSING**（`计数：OK=41 MISMATCH=0 MISSING=1 NO-AUTHORITY=18`）⇒ **仪器首次抓到 · 既存 · 非本波引入**（走修不走改口径）。

## 8｜⚠️ 本趟发现的两条"仪器侧"事项（**我不判缺陷，报主控定**）

1. **`tline` 的 `T2` ❌ 真因 ≠ 它的判据文字**（artifact：`build/MilBridge/tests/HbTextLineParity/Program.cs` 行 1028-1030）：
   `coreOk = … && **widthDeltaLarge == 0** && aCases > 0 && aCasesOk == aCases`，而**判据行文字**只写「记账结构全等（①硬断 ②空行 ③行尾空白）」。
   本趟记账实际是 **`1298/1298`（不等 0）全绿**，❌ 完全由 `widthDeltaLarge = 34`（=已登记的 `A1_nbsp_zwsp 21 + B_nbsp_zwsp 4 + B_nbsp_zwsp_trim 1 + F_nbsp_zwsp 8`）造成 ⇒ **label 与接线不一致**（#12 里记账也不全等 ⇒ 巧合掩盖）。
   ⇒ 建议：判据文字写明"含分桶 >0.34 == 0"，或把 `widthDeltaLarge` 拆出独立判据行。
2. **臂 A 的 `Extent 0/7`**：`--modifier-check` 报 `行#0 期望 ext=18.00 ｜ 实得 ext=17.48`（差 −0.52 > 容差 0.34）⇒ 0/7；
   而**同一字段**（`HbTextLine.Extent` vs 真值 `lines[].ext`，同容差 0.34）在 `tline` 的 `gen/t2d-extent-mismatches.txt` 里是 **`我们=18.0800`（差 +0.08）** ⇒ **两个 harness 对"我们的 Extent"给出不同值 ⇒ 必是调用配置差**（`--modifier-check` 传 `HbRunProperties(tf, em, null)` + `defaultIncrementalTab: 0.0`；`tline` 侧的配置需 T1d/T1b2 确认）。
   **不进 rc**（`行失败 0/7`），且该族 Extent 余差**不传腿同类偏差已在**（`leg-B` 里 `M_modifier_w80/w120 行#1` 差 −3.68）⇒ **非本波引入**；**我不判缺陷**，列"待口径对齐"。

## 9｜必写注记
① **仪器版本分界**：本报告全部读数属 `tline` 仪器 **`2e458928fc1577c2`** + 探针 **`0046ed20d832a7ef`** + shim **`fde9e511e8443cf2`** + PC **`d7a848dfeedcf29b`**；**跑后 shim（10:48:27 ⇒ `6d0eeedc0168f419`）与探针（10:49:03 ⇒ `6c531b6ee0f8277c`）都已变**，属**后续动作**，**不得与本报告读数混用**。
② **`Extent +1`（`1260→1259`／余差 `58→59`）已由主控裁定登记**（`M_modifier` 两行离开、三行进入、总绝对误差 `7.36→0.24`），本报告按"已登记"记，**不是回归**。
③ **`D-T1` 回归保持 `13 → 1`**（判定过 85、第 13 例点名保留）；本趟**未出现 `0/86`**。
