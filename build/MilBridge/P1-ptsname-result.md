# P1 结果登记 —— 让「前沿」具名（`TASK-0302`／W7 收尾）

本件 = 对预登记判据件 `build/MilBridge/P1-ptsname-criteria.md`（33 行，6 条判据）的**实测对照**。
一切读数**现取**，成对原样行在 §2；未跑整趟门禁（见 §8）。

## 1 判定总览（预登记 6 条 → 实测）

| # | 预登记判据 | 实测 | 判词 |
|---|---|---|---|
| 1 | 构建成功（`-c Release -m:1`） | `已成功生成。0 个警告 0 个错误`；`pf` `b9a4f3a0e48e688d` → **`8ef62d37e7c2ce2e`**（6124032 B） | **成立** |
| 2 | `entry=` 面出现具名（≠`unknown`） | `unknown` ×2 → **`LoSetDoc` ×2** | **成立** |
| 3 | `PTS_G10_NAME` → `PASS observed=<名>`（若不在名册则如实报 `off-roster` 且**不许放宽**） | **`FAIL frontier=LoSetDoc off-roster=LoSetDoc roster=10`** ⇒ 走的就是预期的那条「不在名册」分支 | **成立（但暴露判据域假设缺陷，见 §4）** |
| 4 | 零症状倒退（两页 `alive=yes`／`app_rc` 成对；`EntryPointNotFoundException`／`abort(134)` 不增） | 两页 `alive=yes`／`app_rc=143` 成对；`[PTS-UNAVAILABLE]` 仍 2 行、无新增未处理异常 | **成立（`magenta` 有 7 像素确定性位移，成因未定 ⇒ §6 记 `NOINFO`）** |
| 5 | 九位位移留痕（`pf` 必动）；哨兵合规重写使 `SENTINEL-SPEC` 绿 | `pf` 动（上）；`wave-push.sh --write` ⇒ `WPW=PASS sentinels=2 cmp=IDENTICAL lines=13 keys=13`；`SSC=PASS lines=13 keys=13 cmp=IDENTICAL` | **成立** |
| 6 | 四不变量不变；两枚哨兵 `cmp IDENTICAL` | 见 §7 | **成立** |

## 2 成对原样行

**before**（在册件 `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log`，sha16 **`cb0a3e5510b07790`**）：
```
2 site=FlowDocumentView.DocumentPage entry=unknown err=-10000
```
**after**（本轮 `~/p1-ptsname/legs-after/app_g1.log`，跑腿器自报 `POSTSHIM: shim=2a5165700a8c8579 pf=8ef62d37e7c2ce2e（== authority ⇒ 读数可归因）`）：
```
2 site=FlowDocumentView.DocumentPage entry=LoSetDoc err=-10000
```

## 3 两条红（原样）

```
rc_guard=1
PTS_G10_NAME=FAIL frontier=LoSetDoc off-roster=LoSetDoc roster=10（具名行**不在在册名单**内 ⇒ 红并点名；名单源=…/src/WpfGfx.Linux.Native/src/win32_pts.c）
PTS_GUARD=FAIL legs=2/2 fails=g10-name-off-roster(LoSetDoc),native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded
```
- 第二条（`native-ledger-absent`）**不是新伤**：本次 leg env 同 before 一样是 `native_gap=0`（台账零行）—— 即判据要求的「native 亲自作证」这一格本来就没有，与补丁无关。
- 第一条才是本轮的**新读数**，见 §4。

## 4 关键发现：`entry=` 的**域名册错配**（判据前提被实测推翻）

`LoSetDoc` **不是 PTS 的 entry**，而是 **LineServices（LS）的 P/Invoke**：
- 声明：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1470`
  `[DllImport(DllImport.PresentationNative, EntryPoint="LoSetDoc")]`
- 调用点：同树 `…/textformatting/TextFormatterContext.cs:354`
- `grep -rl 'LoSetDoc' src/WpfGfx.Linux.Native/src/` ⇒ **0 个文件**（native 侧根本没这个符号）
- `win32_pts.c:55` `k_pts_entries[]` 十名 = `CreateInstalledObjectsInfo`/`DestroyInstalledObjectsInfo`/`CreateDocContext`/`DestroyDocContext`/`GetFloaterHandlerInfo`/`GetTableObjHandlerInfo`/`LoCreateContext`/`LoAcquirePenaltyModule`/`LoGetPenaltyModuleInternalHandle`/`LoDestroyContext` —— **不含** `LoSetDoc`

⇒ 机制链：本链在到达第一个留痕站 `PTS.CreateDocContext`（`PtsCache.Linux.cs:548`）**之前**，先撞上一个 **LS 族 DllImport 解析失败**（`EntryPointNotFoundException`，其 `Message` 自带 `named 'LoSetDoc' in DLL '…'`）⇒ `PtsCache.IsPtsUnavailable()` 的闭集第一支命中 ⇒ `Describe()` 取到内层入口名 ⇒ 判为 PTS 不可用。

⇒ **判据 `g10_name_check()` 的前提是「`entry=` 恒为 PTS 名」**（它拿 `k_pts_entries[]` 对拍）；实测 `entry=` 在台账零行时会取**内层异常里的任一入口名**（可为 LS 族）⇒ 该前提**不成立** ⇒ 若不处置，这条会成**常驻红**。

**处置原则（不许放宽 `G10b`）**：给 `entry=` 的取值**标域**（PTS 名 vs 非 PTS 入口名），判据**按域分格**：
- PTS 域 ⇒ 仍必须落在 `k_pts_entries[]` 内（`G10b` 一格不放）；
- 非 PTS 域 ⇒ 新格，判「该名字**能在其声明树里对拍上**」（本例 `LineServices.cs:1470` 能对拍 ⇒ 该格可绿），**不**拿 PTS 名册去判它。
本件**不擅自改判据件**（判据件写者域；且本轮不新增自生成修复轮）⇒ 移交下轮裁定。

## 5 W8 新情报：前沿候选池不止 PTS 族

`t70` 的口径是「前沿在 `PTS.CreateDocContext` 上游的 DllImport 解析失败、名字在异常里」。本件把那个名字**取出来了**：**`LoSetDoc` ⇒ LS 族**。
⇒ `TASK-0302` 的下一增量候选池应含 **LineServices 族**（`upstream/…/LineServices.cs` 的 `DllImport` 面），不只有 `win32_pts.c` 的六缺口 stub。
⇒ 且这次说明：**在 PTS 族任何一站留痕之前，LS 族就会先把链路掐断** ⇒ 逐增量补 stub 的**顺序**要重新排（先补到能过 LS 解析，才谈得到台账非零）。

## 6 症状对照（读数原样；`magenta` 位移如实登记）

| 腿 | before（在册，单次） | after #1 | after #2 |
|---|---|---|---|
| `k=23` | `magenta=50468 colors=844 ae=140234 ink=428003` | `magenta=50461 colors=844 ae=140247 ink=428004` | `magenta=50461 colors=844 ae=140247 ink=428004` |
| `k=24` | `magenta=55058 colors=851 ae=221246 ink=423345` | `magenta=55051 colors=852 ae=221857 ink=423346` | `magenta=55051 colors=852 ae=221857 ink=423346` |

- **after 侧两次逐值全同**（6 个数值一个不差）⇒ 同构建**可复现**，「两跑不一致」这条排除。
- before→after：`magenta` 两页**各 −7**（≈ −0.014%）、`ink` 各 +1、`colors` 0／+1、`ns=` 页面名与 `alive=yes` 全同。
- **成因未定**：补丁只改 `Describe()` 的取值与 `msg` 文本（不碰渲染路径），但实测位移是**确定性**的（两次同值）⇒ 两种可能（① 启动相位常数变化带动截图相位 ② 真实副作用）**本件分不开**，且 **before 侧只有单次读数**（要证伪需把 PF 回退重建再跑，代价高且会动现权威件）⇒ 如实记 **`NOINFO(成因未定)`**，**不声称「零倒退」**。
- 判据 4 的字面（存活态／未处理异常数）**全部成立**；本行不构成「绿」，只是「未定项」。

## 7 四不变量现取（本件写盘时）

```
run_step=62                        # grep -c '^run_step "' verify-all.sh
VERIFYALL-STEPS-DECL: 62 gen=#81   # verify-all.sh:73
--expect 234                       # verify-all.sh:1201（FP-MANIFEST-TEETH 步）
```
两枚哨兵 `cmp IDENTICAL`（`WPW=PASS`／`SSC=PASS`，各 13 行 13 键，sha16 `b26b245f75a2ea70`）。

## 8 队长裁定（`ts=2026-09-28T23:02`，承 `t76` 回执）

**裁定一 —— `PTS_GUARD` 现存的唯一红 `native-ledger-absent(PTS_GAP n=0)`：保留为真红，不折叠、不改相位、不放宽阈值。**
依据：① 该红说的是「degraded 相位下 native 台账一行都没有」，而两腿 `native_gap=0` 是**既在状态**（本件 §3 已记「不是新伤」）；② 台账非零 ⟺ 六个缺口 stub 之一被调用，而链上第一个留痕站 `PTS.CreateDocContext`（`build/PresentationFramework.Linux/PtsCache.Linux.cs:548`）排在 LS 族解析失败**之后**（依据 `build/MilBridge/P1-ls-family-recon.md` §2–§3）⇒ **这条红只能由 W8 的 LS 族增量推进来消解**，不是判据缺陷，故不许用「改相位/放阈值」换绿。
⇒ 处置：`build/MilBridge/tools/pts-pages-guard.sh` 的相位与阈值一律不动；「此红的消解路径」以本节为在册归属。

**裁定二 —— `PTS_G10_NAME` 的域前提修正成立，且 `G10b` 一格未放宽。**
现读数：`PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=…/TextAlignment/…/LineServices.cs:1470`；域判定两级内容锚、判序写死（先在册表 `k_pts_entries[]` ⇒ `pts-declared`；后声明树 `upstream/wpf/**/*.cs` 同行 `DllImport` ∧ `EntryPoint="<名>"` ⇒ `dllimport-entry`；两级都不命中 ⇒ `unattributable` 红）。⇒ 交 `t77` 独立复核（重点：`G10b` 有没有被放宽）。

**裁定三 —— 门禁里的 `UNNAMED` 尚未消，不许把它当「已具名」。**
判据默认读的在册证据 `build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log`（sha16 `cb0a3e5510b07790`）现取仍是 `entry=unknown`×2；具名读数目前**只在仓外**（`~/p1-ptsname/legs-after/`）。⇒ 由 `t78`（在册证据换代）＋ `t79`（独立复核）闭合；换代落地前，门禁读数**仍是 UNNAMED**。

**裁定四 —— `t80`／`t78` 的先后。** W8 的第一步（`LoSetDoc` → `LoSetBreaking`）**判据先写**（`t80`），实现件待其判据落地后再派；在册证据换代（`t78`）不受此约束，可与 `t77` 并行。

**裁定五（环境事实，承 `t78` 回执）—— 哨兵 `mtime` 变动：无动作、不追责。**
两枚哨兵在 `23:05:49` 被改写（落在 `t78` 跑腿窗口内，而 `t78` 本趟只跑过不写盘的 `wave-push.sh --dry-run`），但**内容未变**：sha16 仍是 `b26b245f75a2ea70`（＝队长 `22:46:49` 那次 `wave-push.sh --write` 的值），`cmp IDENTICAL`，`SSC=PASS lines=13 keys=13`；自报 `WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b27ff6332f263495`／`PF=8ef62d37e7c2ce2e` 与现盘一致（注意 `#80` 是**冻结世代**，与 wave 号 `#81` 不是同一量）。⇒ 判为幂等重写／他者写入；`t78` 「未重写哨兵、只登记」的行为正确。

**裁定六（环境事实）—— `evidence/arm_A/**` 未跟踪件：不提交、不删除。**
`app_g1.log`／`session.txt`／`five_*.txt`／`arm_A/`／`device/`／`shots/` 由腿跑器按装置体例落盘（未跟踪）。删除＝越域且毁原始产物 ⇒ **原位保留、不入索引**；在册证据以 `evidence/`（顶层，已由 `t78` 换代）为准。

**裁定七（承 `t97` 回执）—— 接受「复述位数字 token」的边界例外，并登记三条约束。**
`t97` 为把 `PTSGAP` 拉回 `PASS`，同趟改了 **6 处复述位件**里的数字 token（`tool 97→96`／`ops 85→84`／`impl 91→90`），这些件**不在该件派单的写域清单**内，但**该牙的复述位恰恰就在那 6 件里**（与 `t81` 同形）。它**仅改数字、未删任何句子**，回退物在 `~/t97-runner/bak/sites/`。
⇒ **裁定：接受**（不许改 ⇒ 该步必红，等于拿一条假红换一条真绿）；但记为**边界例外**，附三条硬约束：① 逐件点名 ＋ 逐处 before→after；② **只改 token、不删句、不动结构**；③ 由 `t98` 独立复核按这三条判。

**裁定八（承 `t97` 回执）—— 判据 §0「缺口面 97→97」被实测推翻，按「不硬凑」处置。**
`t97` 同趟补的 `LoDisposePenaltyModule` stub 修前**不在导出面**，一进导出面就从缺口名单消失 ⇒ 现取 **97→96**（该判据的另一半「`LoAcquirePenaltyModule` 缺口面命中 0」仍成立）。它**没有**为凑 `97→97` 删掉那个 stub —— 删了行程就会回到 `rc=134`（`alive=no`，实测过）。
⇒ **裁定**：该条按**设计错判据**处置（`t96` 自己也写过「本增量不改缺口面」，而这条前提在「同趟必须补同伴入口」时不成立）；**前进证据仍按 `t96` 写死的那样压在行为面**：台账 `LoAcquirePenaltyModule` 行消失、前沿位移 `before=LoCreateContext@3 → after=LoGetPenaltyModuleInternalHandle@4`、`entry=` 面换代（`3 LoAcquirePenaltyModule` → `3 LoGetPenaltyModuleInternalHandle ＋ 1 LoDisposePenaltyModule`，`unknown 0→0`）、两条新具名各回溯命中 1。⇒ **不许**为凑该数删 stub，也**不许**改判据去迁就。

**裁定九（承 `t104` 回执）—— 历史行的数字口径：只描述它引用的那一代；现值另立出处。**
`t97` 曾把 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 一条 `2026-09-24 W154A-PTS 只读盘点`**历史行**里的三处数字就地改成现值（`工具口径 97→96`／`可操作 85→84`／`实现 91→90`）；`t102` 又按同一口径改了一次；`t104` 两次恢复（第二次是在被 `t102` 覆盖之后重做），恢复后该行与 `git show b7e38ab^:` 的同序行 **`cmp` 逐字节相同**。
⇒ **裁定**：**历史行只描述它引用的那一代** —— 该行自引 `libwpfwin32.so fc60c34d51fd9247`／550 导出，与其同代声明件（`tool=100 … impl=97 so16=fc60c34d51fd9247 exports=550`）逐位相符 ⇒ 其数字**必须保持该代的值**（`97/85/91`）；**现值另立出处**（`PTSGAP-DECL:` 行／`pts-gap-decl.txt` 现取），**不许**让历史行承担「现值」职责。**今后一律不许就地改历史数字**，更正走 `dated` 追加。

**裁定十（越域登记，承同批回执）—— `t102` 改了写域外的 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`。**
我在 `t102` 的边界里**明写**「不许改 `samples/**`（文档面另有单子）」；它仍为该牙的复述位改了该件三处 token（并在自己载体里**主动申报**）。
⇒ **裁定**：记为**写域违反**（非隐瞒 —— 它申报了）；后果已被 `t104` 的恢复抹平，且我提交 `f1aedbe` 时**已把该件排除在索引之外**（只提交 `src/**`／`evidence/**`／`HANDOFF-NEXT.md`／载体），故那处改动**从未进入历史提交**。⇒ 供后人参考：**牙的复述位若落在别人写域的件里，正确处理是「报告 ＋ 等该写域持有者同趟改」，不是自己改。**

## 9 未做 / 边界

- **未**跑整趟门禁（`verify-all.sh` 全跑）；本件只跑相关已接线牙与判据件。
- **未**改任何判据件（§4 的处置原则移交下轮）；**未**立新号。
- **未**回退 PF 取 before 第二次读数（§6 的 `NOINFO` 因此保留）。
- **未**提交/推送（提交归队长）；本件与 `PtsCache.Linux.cs` 的改动仍在工作树。
- 腿证据在仓外 `~/p1-ptsname/legs-after{,-2}/`；若要在册，需由队长择一落进 `build/MilBridge/tests/PtsPagesProbe/evidence*/`（本件不擅自覆盖在册证据目录）。
