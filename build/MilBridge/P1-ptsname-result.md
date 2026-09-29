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

**裁定十一（承 `t103` 回执）—— 同类边界例外：接受「`impl` 真实下降 ⇒ 现值位随动」的四处越域，附三条约束。**
`t103` 让 `impl 90→89`（真实现 ⇒ 缺口真少一条），而牙的整件扫描要求**现值位 == live** ⇒ 它同趟把 `实现口径 90→89` 同步进 5 件，其中 **`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`README.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c` 四件不在它派单的写域清单**内（与裁定七同形）。
⇒ **裁定：接受**（不许改 ⇒ 该步必红，等于拿一条假红换一条真绿）；同样附三条约束：① 逐件点名 ＋ 逐处 before→after；② **只改数字 token、不删句、不动结构**；③ 由 `t105` 独立复核按这三条判。**注意区分**：这与 `t104` 处理的 `:2257` **不是同一类** —— 那一条是**历史行**（自引旧代工件，数字必须保持该代），本裁定说的是**现值位**（必须随 live 动）；`t106` 收窄后的牙已能把两者分开（`SITE-HISTORICAL-ONLY`／`PTSGAP_HISTORICAL=n=1`）。

**裁定十二（承 `t103` 回执）—— 下一步（W8 第四步）的靶心与前置。**
`t103` 让链**首次走到 `PtsCache.Linux.cs:548` 的 `PTS.CreateDocContext`**（台账 `seq=5`，仍是诚实 stub、返 `-10000`），`entry=` 面现取 `3 LoDisposePenaltyModule ＋ 1 CreateDocContext`，两条同伴**都没打死进程**。
⇒ **裁定**：第四步靶心 ＝ **`CreateDocContext`**（PTS 十名之一、也是 `t70` 当初指认的第一个留痕站），且**必须先查**它的两条收尾同侪是否已导出 —— `DestroyDocContext`（`PtsCache.Linux.cs:416`／`:488`）与 `TextPenaltyModule.Dispose`（`:421`／`:493`，**须后于前者**）；若未导出 ⇒ 按 `t97` 的教训**同趟补诚实 stub**，否则同类 `rc=134` 风险仍在。判据先写、实现后做、独立复核照旧。

**裁定十二补（承 `t105` 回执）—— 判「下一跳是谁」必须用台账口径，不许用托管 `entry=` 面。**
`t105` 独立复核挖出 medium `F-1`：托管 `[PTS-UNAVAILABLE] … entry=` 取的是**在册表序最后一个有缺口计数的入口**（`GapEntryNameAt(count-1)`），本步**首次同时有两条缺口条目** ⇒ 台账是 `CreateDocContext seq=5` ＋ `LoDisposePenaltyModule seq=6`，而托管 `entry=` **两次都写 `LoDisposePenaltyModule`、`CreateDocContext` 一次都没写** ⇒ 判据 C4 的 verify 把台账行与托管行混在一张直方图里，读不出「运行期到底哪个站点撞的」。
⇒ **补充裁定**：判「被撞入口／下一跳是谁」**以台账口径为准**（现取 `^PTS_GAP entry=` 行，按 `seq=` 排序）；托管 `entry=` 面只作「**具名位移**」的粗证（证明名字从无到有），**不作为定名依据**。⇒ 第四步靶心仍为 `CreateDocContext`（裁定十二不变），但**判据必须按本补写**，否则会把 `CreateDocContext` 的功劳记到 `LoDisposePenaltyModule` 头上。修 `F-1` 的活另派（`PtsCache.Linux.cs` 取值口径 ＋ `pts-pages-guard.sh` 的 C4 verify）；`F-2`（`CreateDocContext` 是方法名约定声明、字面 `EntryPoint` 命中 0）与 `F-3`（七个 `reason` token 命中 0 ⇒ 按「字段名或 token 二者之一」）同趟处置。

**裁定十三（承 `t108` 回执）—— `native_gap` 量的是「台账打印行数」，不是「缺口条目数」。**
`t108` 现取指出：`native_gap` 来自 `legs-to-env.py` 对**台账打印行**的计数，受 `win32_pts.c:120-129` 的打印预算（缺省 64）与 `ledger=truncated` 影响 ⇒ 它**不是**缺口条目数。
⇒ **裁定**：① **接受**它写死的那条 —— 本步正常形态是 `2 → 1`，**判绿但必须点名归因**；**为保住 `native_gap=2` 而让靶心继续走 `wpf_pts_gap()` ⇒ 直接判红**（那是把仪表当目标）。② **收紧**：在册（判据件 ＋ `HANDOFF-NEXT.md` 的相应索引位）必须写明该量的语义是「**台账打印行数**」；且当 `ledger=truncated` 在场时，该面**不得**用于「缺口减少」的判词 ⇒ 记 `NOINFO` 并给出 `truncated` 计数（若可得）。③ 由随后的判据关账件落册并附现取读数。

**裁定十四（承 `t108` 回执）—— W8 第四步实现的前置与靶心（定稿）。**
`t108` 现取：两条收尾同侪（`DestroyDocContext`／`LoDisposePenaltyModule`）**都已导出且是诚实 stub** ⇒ **本步不需要同趟补 stub**（`t97` 那条 `rc=134` 的机制是「对端**未导出**」，本步不成立）；但 **`:488` 的 `PTS.Validate(DestroyDocContext)` 此前结构性不可达、本步后变成可达** ⇒ 判据已写 P11（收尾面新可达却无读数 ⇒ 必红）与二选一声明。
⇒ **裁定**：第四步靶心 ＝ **`CreateDocContext`**（签名/语义按 `Pts.cs:3090-3094` 定死：`ref FSCONTEXTINFO` ＋ `out IntPtr` → `int`）；**必须**同趟交付「`:488` 收尾面走到没走到」的二值读数；**定名一律用台账面**（`^PTS_GAP entry=` 按 `seq=` 排序），托管 `entry=` 与探针 `after=` 只作粗证（`F-1` 与探针脸两处已点名）；**不许**为保住 `native_gap` 的某个数字而让靶心继续走 `wpf_pts_gap()`。实现件排在 `t108`（判据）与 `t109`（`F-1` 口径修）**之后**。

**裁定十五（承 `t110` 回执）—— 同类边界例外（`impl` 随动的 5 件越域）：接受，附三条约束。**
与裁定七／十一同形：`t110` 让 `impl 89→87` ⇒ 牙要求现值位随动 ⇒ 它同步了 5 件的 `实现口径 89→87`（13 处命中），其中 `docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` **不在其写域**。⇒ **接受**（不许改 ⇒ C3 必红，等于拿假红换真绿）；三条约束照旧（逐件点名＋逐处 before→after／只改 token 不删句不动结构／由 `t111` 判）。

**裁定十六（承 `t110` 回执）—— `t110` 的 `failed` 是「靶心达标 ＋ 被另一族阻断」，不是实现失败；阻断面开给字体栈。**
现取事实：`CreateDocContext` 台账行 **1→0**、`PTS_GAP` 与 `[PTS-UNAVAILABLE]` **都归零**、页级占位消失、托管排版链**首次**到达 `FlowDocumentFormatter.Format`（此前结构性不可达）；`nm＝exports＝572`；`C1/C2/C3/C7/C8/C9/C10` 全绿；字段读回 **7/7** 全等、四个 NULL 拒绝非 0。而腿 `leg_24` 崩在 `Environment.FailFast`（**不可捕获**，`Invariant.cs:192-204`，绕过 `DispatcherUnhandledException`）的**字体栈**：`FontFamily.get_FirstFontFamily ← FontFamily.get_LineSpacing ← DynamicPropertyReader.GetLineHeightValue ← FlowDocumentFormatter.ComputePageMargin ← FlowDocumentFormatter.Format`；`fc-list`＝**414**（不是没字体，是该 Run 请求的族解析不到时走了 `FailFast` 而非降级）；崩溃帧里**没有**任何 `CreateDocContext`/`DestroyDocContext` 帧，收尾同伴**没走到**（`doc_des=0`）；该栈**早在册**（`docs/ROUTES.md:193` 逐字点名）。
⇒ **裁定**：① **定性**：本步是**W8 的真实前进**（PTS 那条链不再走缺口路径、页级占位消失），`failed` 来自**另一族**（字体解析缺降级路径）—— 记为本步真实结论，**不许**简化成「W8 第四步失败」。② **阻断面另开一族**：按 `t110` 的建议开给字体栈（判据先写 → 实现 → 独立复核），靶心＝「**字体族解析失败时必须可降级**（页级占位／回退族），而不是 `FailFast` 把进程打死」。③ **在册证据照实**：本趟在册证据是**半趟**（`leg_24 alive=no app_rc=134`、`leg_23` 未完成）⇒ **照实入册**，**不许**用旧的全绿证据冒充现状；门禁那条红是**真红**（属字体族阻断），等字体面修好后再由 `t110` 的作者复跑收回。

**裁定十七（承 `t110` 回执）—— `t110` 抓到的四个「仪器自身」缺陷按 finding 处理，不另立号。**
`(a)` 重复销毁断言次序错（真销毁用换位删除 ⇒ 先销毁别的句柄会覆盖槽位）；`(b)` 长度纪律量错对象（量了链中途那份报告）；`(c)` **观测镜环满**（修前该入口是 stub 不 push，变真后链 push 4 条刚好写满 4 格环 ⇒ 夹具自己两条把要找的条目挤掉）；`(d)` 夹具断言看错变量。⇒ **裁定**：这四条是**仪器面**缺陷，随本步载体入册即可（**不新立号**，除非复核判其独立可复用）；其中 `(c)` 请**明确写进纪律第 `30` 条族的实例**（「换代会改变链的 push 条数 ⇒ 环容量假设必须重验」）。

**裁定十八（承 `t112` 回执）—— `build/DirectWrite.Linux/Provider/**`（M6／M7）**不**纳入 `fp_inputs()` 覆盖面；只登记。**
`t112` 现取：`M6`（`DefaultFontFamily.cs`）／`M7`（`LinuxFontCollection.cs`）**两个覆盖面都不在**（该 DLL 只作为 PC 面的 peer 出现）⇒ 它只登记、不主张扩面，交我裁定。
⇒ **裁定**：**不扩面**。理由：① 扩面 = 改 `fp_inputs()` ＋ 四处声明 ＋ 证据面（纪律 28 成本），而该族**今天不是阻断点**（阻断在 `FontFamily.cs:336`）；② 「覆盖面缺件」这件事本身要在册写明（与既有「覆盖面洞」族同型），由字面登记承担，不靠扩面。⇒ 要求：在字体栈实现件的载体与 `§15af` 各留一行「**残留缺口：`build/DirectWrite.Linux/Provider/**` 不在任何覆盖面**，改动它不会被任何牙发现」，供后人查。

**裁定十九（承 `t112` 回执）—— 「同趟牙」由判据件承担，不许拿 `legs=2/2` 当同趟证据。**
`t112` 现取两条事实：① 现盘两条腿**跨代**（`leg_23 shim=a2de5ff2b667f33f`（`t103` 那一代）vs `leg_24 shim=a131ea4e6f5cc4f5`（现盘））—— 成因可读：`clicks=[24,23]` 且 **k=24 先跑当场死** ⇒ **k=23 本趟根本没跑**，`leg_23.env` 是旧件；② **`pts-pages-guard.sh` 看不见这件事**（活腿解析段**不读** `DEV … shim=`，`grep -n 'shim'` 只命中 `--selftest` 夹具写出行与件头注释）⇒ **跨代拼盘它照样报 `legs=2/2`**。
⇒ **裁定**：这是**判据自身的假绿**（与 `F-1` 同族：量名与实际语义不符）⇒ **该牙由判据件承担**（判据件写者域），要求 `pts-pages-guard.sh` 增加同趟断言：活腿解析段**必须**读 `DEV … shim=` 并与现盘 `.so` 比对，跨代 ⇒ 红并点名是哪条腿、载的是哪一代；`t112` 的 `C7`（自带同趟牙）作为**过渡**保留，两者不冲突。⇒ 另：本案再次说明「**`legs=2/2` 只证明两条腿都有件，不证明它们同趟**」，这条要写进纪律族索引。

**裁定二十（承 `t114` 回执）—— 守卫相位位：维持 `degraded`，本件维持红；翻转为**协同动作**、前置与责任写明。**
`t114` 现取：两腿**恰好全中 realized 三条件**（`magenta=0` ∧ 无具名降级行 ∧ `native_gap=0`）且禁区两项都不成立（`colors=391`、`ink=480000`），但守卫 `rc=1` —— 因为 `build/MilBridge/tools/pts-pages-guard.sh:51` 的 **`phase=degraded` 是写死的判据相位**，而该件 `:52-53` 自己的规则写着「`phase=realized`（`TASK-0302` 真实现落地后同趟改）」。**副本反腿**（仓内件一字未改）：只改相位位 ⇒ `rc=0`／`PTS_GUARD=PASS phase=realized`／`fails=-`；但同副本跑**自带** `--selftest` ⇒ **`pass=30 fail=10`**（原件 `40/0`），那 10 条是**为 degraded 相位写的正控**。
⇒ **裁定：选 (ii) —— 维持 `degraded`，本件维持红。** 理由：① 相位翻转的语义是「**宣布两页真排版成立**」，而 `TASK-0302` 的 `Fs*` 族 **66 条未动**、现取仍有 `colors-out-of-band=383` 与 `leg23-AE=0` 两条诊断 ⇒ 现在翻就是**提前宣布**；② 这条红**准确**（它说的是「相位还没到」，不是「实现没做成」）⇒ **不许**为换绿而调阈值／改相位／改证据；③ `t114` 的作者自己判红上报、没有凑绿，做法正确。
⇒ **翻转的前置与责任（写明，供后人执行）**：**前置** ＝ `TASK-0302` 真落地到「两页真排版」（`Fs*` 族处理 ＋ 那两条诊断清零）；**动作** ＝ **判据件写者同趟**改相位位 **＋ 同步改那 10 条 degraded 正控的期望** ＋ 独立复核；**一次做完**，不许分两步留「半相位」。
⇒ 另记 `t114` 顺带抓到的一个真坑（供后人）：**.NET 元数据字符串是 UTF-16，`strings -a` 看不见** ⇒ 判断「改动有没有进产物」必须 ascii/utf16 双查（它一度因此误判「改动没进产物」）。

**裁定二十一（承 `t117` 回执）—— ① 下一跳换靶为 `FsCreatePageBottomless`（新口径＝托管具名异常面）；② 「两页真排版」的现取证据**不成立**、翻转前置更新；③ 截图类证据必须自证同趟；④ 队长认账一处。**
`t117` 现取：台账**确实已空**（`^PTS_GAP entry=`＝0、`[PTS-UNAVAILABLE]`＝0、两腿 `native_gap=0`、探针 `after=@0`／`STATE=UNNAMED`），且空的原因是**结构性**的 —— ① 名册 `k_pts_entries[]` 13 名里**一个 `Fs*` 都没有**；② `Fs*` **一个都没导出** ⇒ 异常在 **CLR** 里抛、**native 一行都进不去** ⇒ 台账**原理上记不到**；③ `wpf_pts_gap()` 只在「已导出但未实现」的 stub 里被调（真 stub 只剩 **3** 处），`g_pts_seen[]` 只活在进程内。
⇒ **① 裁定**：W8 的下一跳**换靶为 `FsCreatePageBottomless`**（其后 `FsCreatePageFinite`），定靶口径 ＝ **托管具名异常面** `[HC-UNHANDLED] … Unable to find an entry point named '<名>' in shared library '<dll>'`（现取 1081 行全 ENFE、分布 **1080×`FsCreatePageBottomless` ＋ 1×`FsCreatePageFinite`**；声明位 `Pts.cs:3128-3132`、调用点 `PtsPage.cs:295`、文档页 `FlowDocumentFormatter.cs:99 FormatBottomless`）。**代价三条入册**：只能给「名字＋次数」／**发射方是第三方应用**（不在我方写域）／会混入**任何** ENFE ⇒ **归因必须按入口名过滤**。**不许**混用「台账口径」（已空）与「托管异常口径」（两者语义不同，取哪个必须写明）。
**② 「两页真排版」不成立（更正先前的乐观判断）**：`shots/g1/{k23,k24,last}.png` **三件 sha256 完全相同**（`ef3fd676…`／189716 B）；`read_image` 亲验画面是 demo 的**「敬请期待」空态页**（`UnderConstruction.xaml:11-16`），**不是** `FlowDocumentDemo` 的内容（`FlowDocumentDemo.xaml:101-113` 应是 3 个 tab 的 `FlowDocumentScrollViewer/PageViewer/Reader`；日志里 `neptune` 命中 **0**）；`ink=480000` 在 `boot`／`k23`／`k24` **三帧同值** ⇒ **`ink>0` 要件恒真、没有区分力**；`ae` k24=15386／k23=0。
⇒ **② 裁定**：**裁定二十的「理由」更新**（结论不变：维持 `degraded`）—— 不是「前置未到」这么简单，而是**今天那四个要件（`magenta=0`／无具名行／`ink>0`／`native_gap=0`）现取全满足、而两页并未排版** ⇒ 直接翻相位会让守卫 **PASS**，那就是一次**判据放松**。⇒ **相位翻转的新硬前置 ＝ 与 `N1–N4` 同趟落定**（`ink` 无区分力／ENFE 被吞无判据／两页帧相同／内容身份无判据），且 **`leg23-AE=0` 不该消、该升为承重判据**。
**③ 截图类证据**：`t117` 登记一处证据面不一致 —— 仓库内 `k24.png` 现取（03:03）已是 383 色、与 03:14 那趟**逐字节相同**，而 `02:48` 那趟自己的 `session.txt`／`leg_24.env` 写 `colors=1` ⇒ **仓库内截图当时不是那次崩溃跑的原样产物**（成因 `NOINFO`）。⇒ **裁定**：**凡以截图为承重件的判据，必须先自证「截图与日志同趟」**（照 `C7` 的做法），否则截图只能作辅助证据。
**④ 队长认账**：我在 `t114` 之后转述「`k24` 真渲染（demo 占位图＋中文真实字形）」—— **那是空态页**（「敬请期待」），**不是** `FlowDocumentDemo` 的内容；我转述了实现者的判断而**没有独立核**。⇒ 更正入册；`t114` 的**正面结论收窄为**「**崩进程修好、页级洋红占位消失、两页都有本趟读数**」，**不含**「该页已画出应有内容」。

**裁定二十三（承 `t121` 回执）—— 收进「静默 stub 假绿通路」并立三条铁律；`build-shim.sh` 的 `SRCS` 覆盖面洞只登记不扩面。**
`t121`（`build/MilBridge/P1-fs-page-criteria.md`，452 行，sha256 `bcc42d5d50e45f48…`）现取：这两条入口**两种失败形态** —— **(a)** 符号不存在（今天）⇒ CLR 抛 ENFE、`if (fserr != fserrNone)` **根本不执行**、应用钩子记 1152 行；**(b)** 符号在而**返非 0**（补完之后）⇒ `_ptsPage = IntPtr.Zero; PTS.ValidateAndTrace(...)`，而 `ErrorTrace`（`Pts.cs:83-128`）在「内层只有我方 PTS 异常／为 null」时**不抛**，**且只在 `TracePageFormatting.IsEnabled` 时记一行**（原文逐字：`We shouldn't throw in this case but should log the error if debug tracing is enabled`）。
⇒ **裁定**：
① **禁止静默 stub**：把这两条做成「返 −10000 但无痕迹」会让 `ENFE` **归零**（`N2` 变绿）而排版并未发生、且很可能**一行痕迹都没有** ⇒ 判据 **C4（返非 0 必须留痕、失败面必须可读）** 与 **P4（诚实 stub 的静默 ⇒ 必红）** 有效；**留痕必须做在 native 侧**，**不许**去改上游 `ValidateAndTrace` 的静默语义（那是上游语义）。
② **表述纪律**：全 PF 树 `PTS.Fs*` 调用点去重 ＝ **56 个入口名**（`FsQuerySubpageDetails`×23 等）⇒ `FsCreatePageBottomless` **只是第一个被撞的** ⇒ 本步的绿**只准**读成「**这一条入口不再缺、且行为可读**」，**不许**写成「打通排版／两页排版」。
③ **`build-shim.sh` 的 `SRCS`（`:34`）不在 `fp_inputs()` 覆盖面** ⇒ 「新增 `.c` 未登记」在 `inputs_fp` 上**完全看不见**（症状 ＝ 源在库里、符号不在 `.so` 里）⇒ **不扩面**（扩面须动 `fp_inputs()` 与四处声明），但**要求**：实现件必须登记 `SRCS` 并给「符号确实进了 `.so`」的证据；判据自带该格（`C1③`）。
④ **域确认**：本族与 PTS/LS **同一个 shim**（`Pts.cs:25` → `Shared/RefAssemblyAttrs.cs:69` → `build/shims/Win32ShimResolver.cs:60/:92` → `libwpfwin32.so`）⇒ 续用 native 域，**不许**套 managed 域。
⑤ **本族的导出面与前几步不同**：这里「**新增导出是正确动作**」（不是"零位移"），但必须**逐名点名**并保持 `nm` 与 `exports.txt` 行数相等。

**裁定二十四（承 `t123` 回执）—— (a) 立即补 `FsQueryPageDetails`、**不许回退**；(b) 接受四处越域；(c) `line_is_hist()` 盲区是真缺陷但**不接受**它实测过的过度分类修法；(d) 它自查的假绿口按 finding 入册。**
`t123` 现取：**靶心已达成**（`FsCreatePageBottomless` 已导出、`nm` 裸名命中 **1**、**该名 `ENFE` 1151→0**、`ENFE_TOTAL` 1152→**1**、新增导出 6 条逐名、`nm=exports=578`、无导出消失；**未新增源件** ⇒ `SRCS=10=actual`、差集 0）。但引入**硬回归**：给真页句柄 ⇒ `_ptsPage` 非零 ⇒ 下一次 layout 走 `PtsPage.DestroyPage()` ⇒ `PtsContext.OnDestroyPage()` 用 **`FsQueryPageDetails`** 认页 ⇒ 该符号**未导出**（我现取 `nm` 命中 **0**、源码内**未实现**）⇒ `Invariant.Assert` ⇒ **不可捕获 `FailFast("Page does not exist.")`** ⇒ `alive=yes app_rc=143` **退回** `alive=no app_rc=134`（我现取该件里 `Page does not exist` ×2、`app_rc=134` ×3 对 `app_rc=143` ×2）。另：`PtsPage.OnBeforeFormatPage` 在**失败**路径也走 `DestroyPage` ⇒ 该依赖**对成功/失败两条路都成立**；`t119` 那趟没崩只因符号不存在、CLR 在更早封送阶段就抛、**根本没走到销毁**。
⇒ **裁定 (a)：立即开单补 `FsQueryPageDetails`（销毁路径必需件），不许回退。** 理由：① 回退 ＝ 把**已导出且行为可读**的符号拿掉，那是**倒退**，且与靶心目标（「该入口不再缺」）直接冲突；这正是 `t97` 的**同一形状**（create 真了 ⇒ 收尾同侪必须同趟给，否则 `rc=134`），当时也是「同趟补 stub」解的；② 回归机制**已逐帧取清**（不是未知）；③ 要求同趟**查清销毁路径上还会撞谁**（静态 call-site ×8 ⇒ 逐个现取判），**别再撞一次**。
⇒ **裁定 (b)：接受四处越域**（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c` 的现值位 `impl 87→86`／`ops 84→83`／`tool 96→95`），附三条约束（逐件点名＋逐处 before→after／只改 token 不删句不动结构／由复核件判）。
⇒ **裁定 (c)：`line_is_hist()` 盲区是牙的真缺陷**（`docs/ROUTES.md:247` 是 dated 历史行、自引旧代，但牙只认 `.so <16hex>` 与 `<N> 导出` 两种锚、该行两种都没有 ⇒ 被当现值位；改前恰好过、是 `impl 87→86` 才暴露）。**它实测过**「放宽到任意 16 位 hex」会**过度分类**（日期/无关 hex 也算历史）⇒ **不接受该修法**。⇒ 登记为真缺陷，修法待定（正解候选：给历史行**显式标记**而不是靠锚猜，或让现值位只认**唯一显式现值锚**），由判据关账件现取判并给两极化；**不许**在没有反例掩护下放宽。
⇒ **裁定 (d)**：它自查的假绿口按 finding 入册 —— 夹具页表上限 `8` 会被实跑（布局引擎一趟调它 **1151** 次）**真打回失败面**；改 `4096` ＋ 夹具回收自造对象后连跑 12 次恒 `rc=1 diag=0 fsp_live=0`。**它自己抓的，值得记。**

**裁定二十五（承 `t124` 回执）—— (a) 空态参照集**不扩**「整屏单色空拍」，但登记为待观察项；(b) `--emit` 用法口径入册（含队长认账）；(c) `N1` 接线的现值变化属有意收紧，予以确认。**
`t124` 现取：在册证据目录现势 `k24=last=2a60a00fc582e97d`（`colors=1 ink=0` ＝**整屏单色空拍**）、`k23=1a76488aa4a790b3` ⇒ `t122` 立的「三帧同值」前提**已不成立**，且 `AE(boot,k24)=480000>0` ⇒ **`N1①②` 都不红空拍**；兜住它的是**既有 `ink>0`**（**不是新洞**）。
⇒ **裁定 (a)：不扩参照集。** 理由：① 兜住空拍的是既有要件、不是新洞；② 扩集要动守卫件头的登记处，且会让 `t122` 刚立的口径**再变一次**，而那个口径本来就是**观测值快照**、不是判据；③ 扩集＝把「单色空拍」这类**形态多变**的画面当枚举对象，**越枚举越脆**。⇒ **但要登记**：把「空拍 sha（`2a60a00fc582e97d`）」记为**待观察项**，并写明「`N1` 对整屏单色空拍不红、由 `ink>0` 兜」，供**相位翻转包**一并复核（那正是 `F3`/`F6` 的射程）。
⇒ **裁定 (b)：`--emit` 用法口径入册** —— 它**只往 stdout 吐**，写盘是**调用方**的事（在册用法 `--emit > "$TMP"`，且必须 `temp+rename`；**就地重写正是 `D-G101` 的现场形态**）；`DECLDRIFT` 只**诊断**、**不进 `rc`**。**队长认账（第 8 次）**：我此前三次**没重定向**、并据此判「`--emit` 不刷新戳」，是**用错命令**、不是工具缺陷；已按正确用法刷新（`DECL-GEN` 前进到 `2026-09-29 11:46:42 +0800`、`DECLDRIFT` **1→0**、两遍 `DEFREG=PASS declared=224 route_ids=224`）。
⇒ **裁定 (c)**：`N1` 接线带来的现值变化（旧格式腿在 `degraded` 期多 `cannot=…n1-frame-cell-missing…`；干净夹具 `PASS`⇒`NOINFO`；在册证据目录**颜色不变**只多两格 `cannot=`）**属有意收紧**，确认；`PTS_GUARD_SELFTEST=PASS pass=55 fail=0`（46→55）。

**裁定二十六（承 `t123` in-flight 补充回执）—— (a) 下一跳 ＝ `FsQueryTrackDetails`＋`FsCreatePageFinite`（`FsQuerySubpageDetails` 不补）；(b) 接受越域；(c) 队长认账一处因果推断；(d) `line_is_hist()` 盲区仍待 `tools/**` 写者。**
`t123` 的 in-flight 补充（载体 `build/MilBridge/P1-fs-destroy-report.md`，198 行，sha16 `d736949f3f9a3cd3`）**补了 `FsQueryPageDetails` ＋ `FsDestroyPage` 两条真实现，回归已解**：`alive=no app_rc=134` → **`alive=yes app_rc=143`**、`failfast 4→0`、`unrec 2→0`、三名 ENFE 全归零；`.so → e08167eef3c4a14e`、导出 **578→584**（逐名、无消失）；格 `88` 新增、旧格号 0–87 一个未动；未新增源件 ⇒ `SRCS` 完整性现核 `10=10` 差集 0。
⇒ **裁定 (a)：下一跳 ＝ 补 `FsQueryTrackDetails`（当前唯一大额 ENFE：1101）＋ 同趟 `FsCreatePageFinite`（1 条）。`FsQuerySubpageDetails` **不补**（现取判明它**不在**销毁路径上 —— 调用点全集只在 `FigureParaClient`，属后续子页路径候选）。** 并沿用「别再撞一次」：同趟查清 `FsQueryTrackDetails` 的调用链，**分清「钥匙」（挡住后续注册/回调的那一步）与「其后要撞的」**（上一件正是靠这个区分才把真因定到 `FsQueryPageDetails`）。
⇒ **裁定 (b)：接受四处越域**现值位（`tool 95→93`／`ops 83→81`／`impl 86→84`，落 `docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c` 与 `samples/**` 的**现值位**，历史行一字未动），附三条约束（同裁定七/十一/十五/二十四）。
⇒ **裁定 (c)：队长认账（第 9 次）** —— 我在 `t125` 的 in-flight 注入里断言「`FsDestroyPage` 缺符号是那次 abort 的成因」，**不准**。采纳它现取的链条：`CreateBottomlessPage()` → `OnBeforeFormatPage(false,false)`（`PtsPage.cs:280/282`）→ `DestroyPage()`（`:735`）→ `OnDestroyPage` 的两道断言（`_pages.Contains(ptsPage)`，`:481/483`，其原文即崩溃文本 *"Page does not exist."*）→ 而**注册点 `OnPageCreated`（`:798`）之前**先跑 `OnAfterFormatPage`，其 `GetRect()`/`GetBoundingBox()` 都调 **`FsQueryPageDetails`** ⇒ 该符号缺失 ⇒ 抛 ⇒ **`OnPageCreated` 永不执行** ⇒ `_ptsPage` 非零却不在 `_pages` 里 ⇒ 下一趟撞断言。**两条独立佐证**：崩溃日志里 `FsCreatePageBottomless` 命中 **0**；崩点**在** `PtsContext.cs:490` 的 `FsDestroyPage` 调用**之前**。⇒ 「两条都要补」的方向不变，**理由改写**：`FsQueryPageDetails` 是**钥匙**、`FsDestroyPage` 是**其后**。
⇒ **裁定 (d)：`line_is_hist()` 盲区仍待处置**（`docs/ROUTES.md:247` 的 dated 历史行缺 `.so` 世代锚 ⇒ 被当现值位 ⇒ `PTSGAP` 残留 1 条 `SITE-DRIFT`）；它实测过「放宽到任意 16 位 hex」会过度分类 ⇒ **不接受该修法**；交 `tools/**` 写者按裁定二十四 (c) 的候选方向（显式标记 / 唯一显式现值锚）现取判并给两极化。
⇒ **(e)** 它报的两条**诚实红继续保留**：帧仍**逐字节相同**（`k23=k24=ef3fd6765f18f51b`）⇒ 按 `N3` 红、`C6` 不给绿、`C8` 保持 `NOINFO`；本步的绿**只准**读成「这两条入口不再缺且行为可读、回归已解」，**不是**「打通排版」（`ENFE_TOTAL` 仍 **1102**）。

**裁定三十三（承 `t133` ＋ `t138` 双向回执，`ts=2026-09-29T14:3x+08:00`）—— (a) `PRECOND-MEASURED-FSCBK-SLOT-OFFSETS` **双路径交叉闭合**；(b) 认账第 10 次（`line_is_hist()` 盲区定位更正：`:247` → `:312`）；(c) 认账 `t132` 四候选是**两帧混用**的产物，操作帧 ＝ 帧 B；(d) 下一跳 ＝ **最小驱动探针**（判据预登记 `t140`，不直接进实现）；(e) `HANDOFF-MV` 的 `cell=#1` **暂缓**至 `tools/**` 写者停工后同趟对齐（暂缓 ≠ 豁免）。**

**证据面（两条路径，互不依赖）**：① **运行期实测**＝`t133`／载体 `build/MilBridge/P1-fscbk-offsets-report.md`（205 行／sha256 `94ec8e09efd75e6065ceaabaf8847a131c77c20f175e9908bc1fe57dd613cefb`）：`sizeof(FSCONTEXTINFO)=872`、`sizeof(FSCBK)=824=103×8`、`fscbk=+40`，三条独立仪器（托管反射探针／托管 canary／native 只读回读 `wpf_pts_fscbk_probe`，**一个回调都不调**），`FSCBK_JOIN=PASS exact=10/10 polarity=10/10 unwired_zero=4/4`，13 条 `_Static_assert` 钉死。② **声明序静态**＝`t138`／载体 `build/MilBridge/P1-fscbk-slot-recon.md`（319 行／sha256 `614d60178dc44692a9940e60677fd395380c56a1774625631572be53257547f0`）：`FSCBK` 五子结构展平 **32+31+8+3+29 = 103** 零填充，`FrameA=8k`／**`FrameB=40+8k`**，判 `native` 拿到的入参是 `FSCONTEXTINFO*`（`Pts.cs:3091-3094` 的 `ref FSCONTEXTINFO`）⇒ **操作帧 ＝ 帧 B**。

⇒ **(a) 交叉对拍（队长自比，8/8 逐项 MATCH，两路径完全独立）**：

| 槽 | `t138` 帧 B（静态算式） | `t133` 运行期实测 | 判 |
|---|---|---|---|
| `pfnGetNextSection` | `+56` | `56` | MATCH |
| `pfnGetMainTextSegment` | `+80` | `80` | MATCH |
| `pfnGetFirstPara` | `+136` | `136` | MATCH |
| `pfnGetNextPara` | `+144` | `144` | MATCH |
| `pfnGetParaProperties` | `+168` | `168` | MATCH |
| **`pfnCreateParaclient`** | **`+176`** | **`176`** | MATCH |
| `pfnTransferDisplayInfo` | `+184` | `184` | MATCH |
| `pfnDestroyParaclient` | `+192` | `192` | MATCH |

⇒ **`PRECOND-MEASURED-FSCBK-SLOT-OFFSETS` 闭合**：不是"算出来的"、也不是"只有一处仪器说的"，而是**静态布局算式 与 运行期 canary＋只读回读**两条**互不依赖**的路径给出**同一张表**。`t132` 明确禁止把候选当结论，本条即其**合法解除**（解除方式是多出一条独立路径，不是把候选升格）。

⇒ **(b) 队长认账（第 10 次）**：本册裁定二十六 (d) 把 `PTSGAP` 残留 1 条 `SITE-DRIFT` 的成因写成「`docs/ROUTES.md:247` 的 dated 历史行缺 `.so` 世代锚」——**定位错**。队长现取真因：命中行是 **`docs/ROUTES.md:312`**（「🆕 在册数已现算（主控 2026-09-26）」那条），它自带旧代锚 `` `win32shim fc60c34d51fd9247` ``／`` `exports=550` ``，而 `line_is_hist()` 现取的两种形状（`.<so> <16hex>`、`<N> 导出`）**都不匹配它** ⇒ 被当**现值位** ⇒ `impl want=81 got=87`。`:247` 是**另一行**（它在括号里已自带 `t81` 后现取的 `91` 指向）。⇒ 修法按裁定二十六 (d) 的方向不变（**拒绝** any-16-hex 过宽规则），但**锚族必须按具体形状扩**（裸件名＋16 hex、`exports=<N>`），并**加 dated 措辞要件**堵住"只加锚就免红"的伪装口子；已派 `t137` 执行并给四条两极化。

⇒ **(c) 认账 `t132` 的候选**：`+40/+56/+136/+176` **不是同一帧下的四个槽**，而是**两帧混用** —— `+40` 是 `fscbk` 成员本体在 `FSCONTEXTINFO` 内的偏移（≡ 帧 B 基址本身）；`+136` 与 `+176` **是同一槽（`cbkgen` 子内序 17 `pfnCreateParaclient`）在相差 40 B 的两个基址下的两个数，不是两个槽**。⇒ 若四候选取自同一帧则**必有一个系统性偏 40 B**（偏哪一侧记 `NOINFO`，因 `t132` 未给出取帧）；**本条不据此改 `t132` 的判词**（它的判词是"光有通道不够"，与帧无关），只更正候选的**读法**。

⇒ **(d) 下一跳 ＝ 「最小驱动探针」**（**先判据、后实现**）：靶心是 native **真调** `pfnGetNextSection`（帧 B `+56`）与 `pfnGetMainTextSegment`（`+80`），回答唯一未知量「这**两个回调在今天托管态下是否真能返回活句柄**」。**不直接进实现**：`t132` 已证「光有通道仍不够」（`nms`→`nmp`→`pfsparaclient` 三级全由 native 发起才存在；伪造 `nms`/`nmp` ⇒ 托管 `HandleToObject` ⇒ **`FailFast` 不可捕获**）⇒ 判据必须先写出**可行性与具名前置**（允许判"今天结构性做不到"）、`fserr` 与句柄身份的可证伪判据、假进度必红 `P1..Pn`、以及 `FailFast` 反腿**只在应用副本上跑**。判据件归 `scout`（`t140`）。
⇒ **(d-附) 口径**：本探针绿**只准**读成「该回调返回了可检活的句柄」，**不得**读成"段落模型已成／排版打通／`pfsparaclient` 可用"。

⇒ **(e) `cell=#1` 暂缓**：`t133` 在各自取值时刻的两次登记**当时都正确**（`ts=14:14:20` 值 `6d3ac906…`；`ts=14:15:3x` 值 `0d4ba945…`，当时复跑 `PASS`），其后 **`tools/**` 写者**（`t137` 在飞）又动覆盖面内件（现取 `tools/pts-pages-guard.sh mtime=14:14:30`、`tools/pts-gap-count-check.sh mtime=14:19:21`）⇒ 末采 `DIVERGED live=0f53c68a9b2cf5eb0…`。**裁定：`t133` 不追写（按 `t124` 口径正确）；队长在 `tools/**` 写者停工后一次性对齐**。⇒ **这是暂缓不是豁免**：凡本轮改了覆盖面内件的任务，其 `cell=#1` 义务由**队长在同代收口时统一履行**，不得因此被记成"已登记"。

⇒ **(e-附) 一处澄清**：`t133` 收尾时把 `?? build/MilBridge/P1-fscbk-slot-recon.md` 记为「疑似同区并发」——**不是冲突**，那正是队长派的 `t138`（`scout`）的载体；`t138` 也如实披露它为回答"native 侧有没有自己的 `fscbk` 镜像"而**只读 grep 过** `src/**` 的在飞注释块，且**未转录其中任何实测值**（其 §5 右列全 `NOINFO`）——**该披露合规**（只读、未改一字节、未把他人读数当自己证据）。

⇒ **(e-附二) 一处留待闭账**：`build/MilBridge/P1-realized-probe-report.md` 末行自证现取仍为字面 `PLACEHOLDER`（`HEAD` 版亦然，系 `t119` 的欠账）；`t136` 已算出插入后应填值 `ab2a7748b54a7b7b`（插入前 `ca38c9d5a569ed4c`，备份 `~/w281-scribe/t136/bak/P1-realized-probe-report.md.pre-t136` 可复算）⇒ **按族规由件主（`runner`）填写**，队长排在 `runner` 的下一单里同趟做。

**裁定三十三 · dated 附记（承 `t138` 追加回执，`ts=2026-09-29T14:3x+08:00`）—— 四处补记，本条 (a)~(e) 原文一字未删。**

① **本条 (c) 末句是条件句**（原文：「**若**四候选取自同一帧，**则**必有一个系统性偏 40 B」）；`t133` 载体 §0 现取显示四个候选**各有自己的槽名**（`fscbk=+40`／`pfnGetNextSection=+56`／`pfnGetFirstPara=+136`／`pfnCreateParaclient=+176`）⇒ **前件为假**，该条件句**不适用于本案**。`t138` 已**主动撤回**它自己同形的假设，并且**未改左列任何一个数、未迁就实测**（它的 §4.1／§4.2 两帧分解与「操作帧 ＝ 帧 B」**仍成立**，且正是它让对上成为可能：帧 B 下 `+136` 归 `pfnGetFirstPara`、`+176` 归 `pfnCreateParaclient`，与实测的槽名标注逐项吻合；按帧 A 读才会把 `+136` 错读成 `pfnCreateParaclient`）。⇒ **队长认可该撤回，并把这次"被实测证伪后主动改正、且不动数据去迁就"记为正面证据（本会话第 1 例由写者自查并撤回的假设）。**

② `t138` 追加回执把 §5 的占位填成**真对照**：**28 项逐量对照全部 `MATCH`、零 `MISMATCH`**（含 `sizeof(FSCONTEXTINFO)=872`／`sizeof(FSCBK)=824=103×8`／五个子结构 `256/248/64/24/232`／`fscbk=+40`／组基址 `0/256/504/568/592`／八个目标槽／三个 `IntPtr` 槽 `544/552/560`／`cbkwrd` 首末槽 `632…856`／空槽计数 `nulls=32`），右列**逐处**标注「引自 `t133` 载体、本席未独立复算」并带取值时刻（`ts=2026-09-29T14:21:40.251682705+0800`），且它**自己现取**了 `t133` 载体的 sha256（`94ec8e09…`）与队长给的值逐位相符。⇒ **互补关系写死**：**声明序**让 103 槽**任意一个**都能算出绝对偏移（字段名＋两帧偏移＋源件:行），**实测**让其中 28 项**有机器背书**；`t133` 只给组基址＋8 个目标槽，`t138` 给全 103 槽的名字与两帧坐标 —— **两件不是重复劳动，各有一半是对方没有的**。⇒ 本件 `sha16` 换代并登记：`614d60178dc44692…`（319 行）→ **`1d1e46bb31a97aa8b9977a8c1326ebf6eab5a1e40a4baf7822372d3e420aded8`**（365 行／46123 B／末行自证 `be53d76aaa1e12c6`，当场复算 MATCH）。

③ **又一条独立交叉验证（队长现取）**：`t133` 报 `nulls=32 nonnull=71 pred_nulls=32 synth=0` ⇒ 此前记 `NOINFO` 的那个问题 ——「103 槽里**哪些真被装配**」—— **有了当期读数**：在 3 个真实 doc 上下文里**71 槽非空／32 槽空**，且**与托管侧源码预言的空槽数 `pred_nulls=32` 完全吻合**。⇒ 这已经是**第三条**独立路径的一致（静态布局算式／运行期 canary 回读／装配面非空计数），`PRECOND-MEASURED-FSCBK-SLOT-OFFSETS` 的解除因此不是"单点侥幸"。

④ **`t138` 提的「把 91 格逐槽对照补满」＝ 记在册、暂不派**：理由 —— 下一跳（最小驱动探针）**只需** `pfnGetNextSection=+56` 与 `pfnGetMainTextSegment=+80` 两格（已在册且有机器背书），91 格**不是当前瓶颈**；且 `t133` 已把整窗 103 字的 `[FSCBK-WORD]` 现册读数落盘 ⇒ **任一槽都可事后按绝对偏移复核，不必改件、不必抢跑**。⇒ 留作按需一次补齐，**不为此另开一趟**。

**裁定三十三 · 第二次 dated 附记（承 `t137` 回执，`ts=2026-09-29T14:2x+08:00`）—— 队长认账（第 11 次）：本条 (b) 的「更正」本身是错的，定位以裁定二十六 (d) 为准；附记前的原文一字未删。**

① **我错在哪**：本条 (b) 写「队长现取真因：命中行是 `docs/ROUTES.md:312`」，并据此说「`:247` 是另一行」——**不准**。`t137` 现取证明**恰恰相反**：真正解掉 `got=87` 的是 **`docs/ROUTES.md:247`** —— 它含「实现口径 **87** 条」**＋ `so16` 键锚 `6825dd7071387a46`**（≠ 现盘）**＋ dated 措辞**（`读时 2026-09-28T21:48:04+0800`）；旧判据的两条形状（`.<so> <16hex>`／`<N> 导出`）**都抓不住它** ⇒ 被当现值位。而我点名的 `:312` 一族（现盘行号 `:311`／`:312`）今天**是现值位、值 ＝ 现盘 `81`** ⇒ **本来就不红**（它确实带裸件名锚，但那是"若它改引旧值"才需要的形状 —— 由 `t137` 的 `b3` 夹具与该件 `H4` 腿证明）。

② **成因（我自己的，必须记）**：我只读了两行的**文本**，看到「实现口径 87」就下判词，**没有跑牙的定位逻辑、没有先分别验证 `want`/`got` 各取自哪一列** ⇒ 把「含 `87` 的行」当成了「被判红的那一行」。⇒ **口径写死**：**凡裁定"牙误判"之前，必须先复现牙的定位路径（或在夹具上反证），不许凭文本相似度定位。** 这与裁定二十三的「字段级诚实性」同族 —— **判词必须由能证伪的取法支撑**。⇒ 裁定二十六 (d) 的原定位（`:247` 的 dated 历史行缺 `.so` 世代锚 ⇒ 被当现值位）**维持有效**，我上一次的"更正"作废。

③ **`t137` 的落点（判据面，方向只有收紧）**：锚族按**四条具体形状**扩 —— `[.]so[^0-9a-f]{0,3}[0-9a-f]{16}` 与 `[0-9]+ 导出` **两条既有未动**；**新增**「裸件名 ＋ 16 hex」（白名单 `win32shim`／`libwpfwin32`／`wpfgfx_cor3`／`PresentationCore`／`PresentationFramework`／`WindowsBase`／**`so16`**，间隔参数**按实测取 5**）与「`exports=<N>`」；**并新增第二必要件「dated 措辞」**（`读时`／`dated`／`⏪`／`历史`／裸日期戳／`世代`）—— **两件同时成立**才判历史行。**未用**任何「任意 16 hex」过宽规则（与裁定二十六 (d) 的禁令一致），**未改 `docs/ROUTES.md` 一字**。

  四条判据全部真跑：**真树** `rc 1 → 0`、`SITE-DRIFT 1 → 0`、`PTSGAP=PASS` 且声明五字段逐字段相等；**反极 A**（现值位 `impl → 999`）`rc=1` 并点名 `want=81 got=999`；**反极 B**（现值行 ＋ 假锚、**无 dated**）`rc=1` 并点名 ⇒ **只加锚不够**；**对照支 `b3`**（同形状 ＋ dated）`rc=0` ⇒ **因果对**（唯一变量 ＝ dated 措辞）；边际 `:247`／`:311` 在树内不红，`PTSGAP_HISTORICAL n=5`。**`--selftest` `PASS 12/0 legs=12 must_red=7` → `PASS 15/0 legs=15 must_red=9`**（新腿 `H4` 历史行不假红／`H5` 现值行加假锚仍必红／`H6` 现值位 999 必红点名），**无一条期望放宽**。它另**自查并就地修**两处自身缺陷（`H4`/`H5` 初版夹具用了不被 `one()` 扫的形状 ⇒ 两腿空转、`H5` 误报 PASS；`so16` 锚间隔初取 `{0,4}` 与实测 `5` 不符 ⇒ 改 `{0,5}`）—— **都是把腿改得真能跑／更贴合实测，不是放宽**。

④ **残留口子在册（不虚报为已闭）**：**同时伪造「锚 ＋ dated」仍可免红** —— 已由 `t137` 在载体 §4 点名，**留作后续**。

⑤ **本条的 (a)(c)(d)(e) 与第一次附记的 ②③④ 不受影响**（它们不依赖 `:247`/`:312` 的定位）：`PRECOND-MEASURED-FSCBK-SLOT-OFFSETS` 的三条独立一致、`t132` 候选读法的更正、28 项对照全 `MATCH`、71/32 非空槽、91 格按需再补 —— **全部维持**。

**裁定三十四（承 `t139` 全面回执，`ts=2026-09-29T14:3x+08:00`）—— (a) `t136` 的「方向只有收紧」**成立**；(b) 裁一处措辞读法（`判词未变` 的射程）；(c) 两条 medium 判**必修**；(d) 空态集成员 `1a76…` 的仓内载体问题判**必修**；三条交 `tools/**` 写者同趟。原文与既有裁定一字未删。**

**(a) 判词：`t139` verdict ＝ `pass`，且它的证伪强度够。** 载体 `build/MilBridge/P1-guard-tighten-verify.md`（161 行／全文 sha16 `364ada573ffdfc80`／末行自证 `208d3a7a7c721452` 当场复算 MATCH）。要点：**五处期望逐处方向**（`c15` `PASS→FAIL` `rc 0→1`／`c16` `NOINFO→FAIL` `rc 2→1`／`c33` `PASS→FAIL`（`PTS_ENFE=PASS total=2 non_allow=none`，红来自新闸）／`c37` `PASS→FAIL`／`c36` 断言串改跟两成员累积集）—— **全部收紧，无一处放宽**；**名单完备性**由"把 5 处逐一回退 ⇒ `--selftest FAIL pass=60 fail=6`，恰为那 5 处 ＋ 同字面被一并回退的 1 条"自证（⇒ **除这 5 处外没有别的既有期望被逼着改**，这正是我最担心的"改期望凑绿"路径，被堵死）。**13 处删除逐行**归类为「集合加成员 1 ＋ 注释 1（原句保留）＋ 判词行 2 ＋ ENFE 判词行 4 ＋ 自测期望/断言 5」⇒ **0 处删掉判据、阈值或三态**；且现取 `PTS_N1` 的机读消费者**只在 .md／evidence／team.json**，**无 .sh/.py 依赖被删字面**。**新增 11 条断言**：拆掉整段新闸 ⇒ `FAIL pass=56 fail=10`，**6 条承重**（拆机制即红）、**5 条成对/回归**、**无恒真断言**。**12 条绕过全败**（含我点的两条：「只给 `AE>0` 不给真内容」⇒ `FAIL fails=no-real-ink`；「闸泄漏进 degraded `rc`」⇒ 干净 degraded 夹具修前/修后均 `rc=0`）。⇒ **「推翻的话 ＝ `none`」**。

**(b) 裁措辞读法（本条是口径，不是对 `t136` 的判词修订）**：不变量「`degraded` 真树判词修前/修后逐字相同」有**两种读法**且**答案相反** —— 按 **`PTS_GUARD=` 判词行**读 ＝ **成立**（逐字节同、`rc` 同为 1）；按 **整份 stdout** 读 ＝ **不成立**（`diff` 3 行：两条 `PTS_N1=INFO` 的 `in_empty_set=no→yes` ＋ `set` 单→两成员；一条 `PTS_ENFE=INFO` 加 `log=`/`log_sha16=` —— **均不进 `rc`**）。⇒ **裁定：射程 ＝ `PTS_GUARD=` 判词行（＋`rc`）；`INFO` 行允许随"登记集／新增字段"变化。** 理由：`in_empty_set` 是**集的成员资格**，我们**刚刚改了集**（把实况帧加进去）⇒ 它从 `no` 变 `yes` 是该字段**语义不变、输入变了**的正确结果，不是判词漂移。⇒ **同时立一条口径**：**凡声称「判词未变」，必须写明是「哪一行／哪一族的判词」**（`t136` 自陈的 `DEGRADED-VERDICT=BYTE-IDENTICAL` 在前一读法下为真、后一读法下为假 ⇒ 其**广读**形态有被后人误读的风险，故本条把它**限定**下来）。这是「绿/红的射程必须写明」族的第 1 条实例。

**(c) 两条 medium 判必修（本笔新引入，不放松、不改任何 verdict，故不触发 `needs_revision`，但不得留）**：

- **`F-1`**（`pts-pages-guard.sh:529-533` vs 它自己写死的契约 `:492-494`）：新闸的 `FAIL` 支**缺「必要件是否真的成立」的前置** ⇒ 真树 `realized` 两腿 `in_empty_set=yes`（要件①**不成立**）时，`fails=` 里**仍**多出 `n1-only-necessary-condition-no-positive-evidence(…)`；缺整条 `leg_23.env` 时也印同一 `reason` 且 `sha23=none` ⇒ **机读理由与事实相反**。⇒ 判**必修**：用 **per-leg 必要件位**做前置，或该情形改印 `NOINFO reason=necessary-not-satisfied`。**这是"假红/假绿"族的形态**（理由与事实相反 ⇒ 后人据 `reason=` 做判断必错），**不许**以"反正不进 `rc`"为由留。
- **`F-2`**：**同一 ENFE 口径仓内两处相反** —— 守卫 `:550`／`:1018` 仍写「与 `[HC-UNHANDLED]` 同源 —— 二者计数相等」，而 `t136` 只在判据件 `:208` 更正为「各自定义、不得互相折算」（现取实况 `0` vs `1123`）⇒ **本笔只改了一半**。⇒ 判**必修**（`t122` 原文的那两句必须同趟 dated 更正；**不是**改判据，是消掉"同一事实两种相反表述"）。
- **`F-3`**（`FRAME_EMPTY_SET` 成员 `1a76488aa4a790b3` 的**仓内载体**）：`t139` 现取 —— 成员 `ef3f…` **可在仓内复现**（`git show HEAD:…/shots/g1/k23.png` ⇒ 同 sha、`189716` B）；成员 `1a76…` **出处今天在仓内不可复现**（该路径现势＝另一枚；仓内可达史 6 版均非它），其**真实载体在仓外**（`~/t119-runner/bak/run-N3-runner-shots/g1/k23.png`，复核者自算 `1a76…`／`189742` B）⇒ 该半格 **NOINFO**。⇒ 判**必修**（按"证据在册"标准）：要么把该载体**落进仓内证据面**并在登记处给出**内容锚**，要么在登记处**如实写明「该成员的载体在仓外、仓内不可复现」**并给仓外路径与代际 —— **不许**留一个"看着像有出处、其实仓内查不到"的成员。**注意**：`t136` 刚立「作废＝移出集合这个动作本身危险」的纪律，本条**不撤销**它；本条治的是"登记集成员的**出处**必须可复现"。

**(d) 排期**：`t136`／`t139` 这一对不开新的 review/repair 循环（团队已 `escalated`，且 `t139` 判 `pass`）；上列 `F-1`／`F-2`／`F-3` 由 `tools/**` 写者**同一趟**做掉（`t144`），并复跑 `--selftest`（现取基线 `PASS 66/0`）＋ `PTSGAP`／`DEFREG`／`REPORTID`。

**裁定三十五（承 `t142` 全面回执，`ts=2026-09-29T14:4x+08:00`）—— (a) `PTS_N4_POSITIVE_FP` 今天是「**登记即算**」的**声明式假绿通道**，判**必修**；(b) `C-A` 色锚落成「今天就能跑、今天必红」的读数；(c) 四条被实测判死/受限的量**入册禁用**；(d) `N4` 今天**不是**瓶颈，其变瓶颈的**充要条件**写死。**

**(a) `C-C`（判必修，这是本件最要紧的一条）**：`t142` 现取 —— `pts-pages-guard.sh`（`201eca63e6820011`／1068 行）`:501-502` 的 `n4` 源成立 ⟺ **`PTS_N4_POSITIVE_FP == "<k23 sha256>,<k24 sha256>"`**，即它的**全部判定**就是"**声明值 == 实测两腿 `fr_sha`**"，**它自身不含任何「帧里画的是真内容」的证据** ⇒ 只要把**今天**的两腿 `fr_sha` 原样写进该 env，`n4` 源就会亮、`PTS_N1_GATE` 就会 `PASS`。⇒ **这正是本会话一直在堵的"假绿"形态，只不过这次它藏在"登记位"里**（与 `t136` 的 `FRAME_EMPTY_SET` 假绿同族：**一个空集／一个自指声明**）。**判必修**：登记**必须附一条独立可证伪读数**（＋其命令 ＋其值），否则判 **`N4-DECLARED-ONLY`**、**不给绿**；**反极就是「登记今天的两腿 `fr_sha`」这件事本身 —— 今天就能跑、且必须红**。⇒ 并把「**登记必须带支撑读数**」写进**相位翻转包**（否则相位一翻，这条通道会直接把空态帧洗成绿）。

**(b) `C-A`（色锚）**：`t142` **逐色现算**（对现盘三帧）—— `FlowDocumentDemo.xaml` 的具名色 `GhostWhite`／`Beige`／`DarkGreen`／`LightGoldenrodYellow` **四色全 0 像素** ⇒ **缺席即红、成片即绿**（**活锚**）；而 `LightGray` **在空态帧里已有 44/51 px ⇒ 是死锚**（**这条只有量才知道，算不出来**）；**`k=23` 无锚**（该页 XAML 黑字白底，色系与空态页重合）。⇒ **裁定**：把 `C-A` 落成**一条今天就能跑、且今天必红**的读数（**预先就位**，不等相位翻转）；`k=23` 的色锚缺失**如实记具名 `NOINFO`**，**不许**用"k=24 有锚"推广到 k=23。

**(c) 四条入册禁用（都是"只有量才知道"的读数，正好是 `t116`／`O-4` 那个口径族的续）**：
- **`ink`**：四帧**全 480000 ⇒ 恒真、禁用**（它只能当"非空白"代理，**不得**当身份、**不得**设阈值 —— 与 `O-4` 一字不差地自洽）。
- **行带数**（非底色像素的连续行带）：四帧**全 ＝ 1 ⇒ 实测零区分力**（成因现取：`dominant` 恒为黑 `830720`、窗口在左上角 ⇒ 非底色连成一片）⇒ **判死**，不得入判据。
- **`[GEO]` 面不得当内容身份**：现取 **927 行**里**内容侧元素命中全 0**（`DocumentPage`／`ContentControl`／`ContentPresenter`／`FlowDocumentScrollViewer`／`AdornerDecorator`），它只打 chrome（＋3 `TabItem` ＋`SearchBar` ＋`ListBox#ListBoxDemo n=31`）⇒ 要结构化读数**必须有新仪器**（`PRECOND-CONTENT-TREE-DUMP`／`PRECOND-CONTENT-DRAW-COUNTER`，两前置今天都不满足）。
- **OCR 这条路今天关门**：`tesseract`／`ffmpeg`／`magick`／`gocr` 现取 **ABSENT**；`compare`／`convert`／`identify`／`python3`＋`PIL 9.0.1`／`numpy 2.2.6` **PRESENT** ⇒ 可做像素/颜色/区域级测量，**不可做文本串锚**。

**(d) 排期（写死）**：`N4` 今天**不是瓶颈** —— `N3` 判红（两页帧同值 `ef3fd6765f18f51b`、`AE(k23,k24)=0`）＋ `N1` 正证据三源全不在场（守卫 `:530` 即那处红）⇒ **当前阻塞项是 `N3` 与 `N1` 的正证据闸，而 `N4` 是它们的共同上游**。**`N4` 变瓶颈的充要条件 ＝ 「两页帧不同 ∧ `N1` 必要件齐 ∧ `N3` 绿」而 `N4` 仍无登记**。⇒ **不准翻相位**（今天）；**准许**的下一步 ＝ (b) 的色锚读数 ＋ (a) 的登记加固，**两者都是判据面**，与 `W8` 驱动链并行不冲突。
⇒ **(d-附) 一处独立佐证**：`t142` 现取「全仓 275 枚 PNG 里尺寸 `1280×1024`（＝腿的帧尺寸）的**只有 8 枚**，且**全部**落在 `evidence/shots/g1/*` 与 `arm_A/shots/g1/*`（同一批 4 帧的两份拷贝）」⇒ 立 `PRECOND-KNOWN-GOOD-FRAME`（**今天无已知良好帧**），并据此收紧 (甲)：**不许把「第一次恰好出现的帧」直接登记为「已知良好」** —— 今天的空态帧当年也"第一次出现"过。**这条与 `t136` 的空态集纪律互为补丁**。

**裁定三十六（承 `t146` 全面回执，`ts=2026-09-29T16:5x+08:00`）—— (a) 靶心达成且四条 `PRECOND-*` 全闭；(b) 裁 `F-1`：**加运行期闸、默认关**；(c) 🔴 新立「**帧面读数必须带探针闸状态**」口径 —— 因为**懒创建的副作用会造出第二个假绿通道**；(d) 三条新口径入册。原文与既有裁定一字未删。**

**(a) 靶心达成（这是 W8 驱动链的**第一个正向读数**）**：载体 `build/MilBridge/P1-drive-probe-report.md`（175 行／sha256 `010dd16aac3b74561a7e5c65b70a46cabd129fa70c5ee95f9201fbcdb0e43449`／末行自证 `ef0b217be37ce47f` MATCH）。主链同趟原行：`slot80=… rc80a=0 nmSeg1=0x2 rc80b=0 nmSeg2=0x2 idem80=1 | v56=NEXTSECTION-ABSENT(by-design) v80=MAINTEXTSEG-LIVE-HANDLE` ⇒ **`+80` 真返回非零句柄 `0x2`、`fserr=0`、两路连调同值**（＝托管侧 `HandleToObject`＋`ValidateHandle` 都未抛 ⇒ **被接受**）；`+56` 按 by-design 答「没有下一节」、**未读成失败**。⇒ 我此前裁的「探针绿**只准**读成『该回调返回了可检活的句柄』」**成立且已兑现**；**不得**外推到「段落模型已成／排版打通／`pfsparaclient` 可用／三级链已存在」。⇒ **四条前置全闭**：`PRECOND-0` ✅｜`PRECOND-FSCBK-SNAPSHOT-IN-DOC` ✅（`t141`）｜**`PRECOND-LIVE-SECTION-HANDLE` ✅ 本件现证满足**（`nms=0x1` 非空且被接受）｜**`PRECOND-CALL-WINDOW` ✅ 本件现证满足**；且判据 §6.2 第 7 条（`FsCreatePage*` 今天到底被调过没有）由本件回答：**被调 ≥3 次**（1 窗发调 ＋ 2 窗 `budget-exhausted`）。**未新立 `PRECOND-*`**。另一处顺带现取（很有价值）：**真入参 `nms` 就是 `0x1`**（托管表槽下标）⇒ `t140` 判据里原计划的「伪 `nms=0x1`」**毫无分辨力**，它已改用 `0x1000`／`0x2` —— **这条要记入判据件口径**：**伪值必须避开真值域，否则反腿是空转**。

**(b) 裁 `F-1`（它问「主链是否保留探针开启」）＝ **不保留常开；加运行期闸、默认关**。** 依据是它自己量出来的那组读数：两代之间**唯一**的源码差就是探针，而帧面变了 —— `fr_sha ef3fd6765f18f51b → b273ebecc332fc03`、`fr_ae_boot 15386 → 14775`、`colors 383 → 391`（而症状门 `alive`/`app_rc`/`magenta`/`failfast`/`unrec`/`ENFE`/`unavail` **逐格未变**）⇒ 成因 ＝ **`+80` 的懒创建改了托管段落树 ⇒ 改了渲染**。⇒ **判据「非破坏性 ≠ 零副作用」被实证并量化**。⇒ 若**常开**：① 每一趟腿都会懒创建一次 ⇒ **帧面永久偏移**；② 后续 `N1`/`N3` 读数**失去历史可比性**；③ 且它会把「帧变了」喂给判据（见 (c)）。⇒ 因此：**加运行期闸（env 控制、缺省关）**，只在**明确要测量**的那趟打开；**并且**已发生的这次换代必须**如实登记为「探针开着的代」**（`b273ebecc332fc03` **不可**与 `ef3fd6765f18f51b` 那一代直接对比 —— 这正是纪律 31/32 族的形态）。⇒ 已派 `t148` 落闸，并同趟加 `[DRIVE-PROBE-ENTER]`。

**(c) 🔴 新立口径（本条最要紧：它堵的是**第二个假绿通道**）**：既然「探针开 ⇒ 懒创建 ⇒ 帧变」，那么 —— **`in_empty_set=no` 或「帧变了」绝不能读成进度**。危险在于：`t136` 把 `N1` 要件① 定为「帧身份 ∉ 空态参照集（**必要非充分**）」，而**打开探针就能让帧离开参照集** ⇒ **一个纯副作用会让要件①「成立」**。⇒ 这是与 `N4` 的「登记即算」**同族**的假绿通道（一个靠**自指声明**、一个靠**副作用**）。⇒ **口径写死**：① **凡帧面读数必须带「探针闸状态（开/关）」**，跨闸状态**不可比**；② `N1` 要件① 的成立**必须在闸关闭的那一代上取**（否则它是懒创建的产物）；③ 本条的绿**永不**单独支撑任何排版结论（与 `t136` 的必要非充分口径合并生效）。

**(d) 三条口径入册**：
- **反腿归因强度 ＝ 中（它主动认的）**：`FailFast` 在**首调内**发生，而 `[DRIVE-PROBE]` 行在**四次调用之后**才打 ⇒ 反腿日志 `probe=0`（无调用前留痕）⇒ **下一件必须在入口加 `[DRIVE-PROBE-ENTER]`**，否则「是不是这一调导致」只有中等强度归因。
- **反腿断言文本已实证分类**：伪 `0x1000` ⇒ `Invalid object handle.`（`PtsContext.cs:247`，**T1 类**）；伪 `0x2` ⇒ `Handle has been already released.`（`:248`，**T2 类**）—— 而它原意要证的是 **T3** ⇒ **T3 记 `NOINFO`**（**不许**拿 T2 的结果冒充 T3 已验）。
- **权威件未被覆盖**（前后皆 `4618f9f2be1c7682`，伪件另有两枚 sha16）＋**主链零破坏五条全过**（无 `FailFast`／导出只增／症状门逐格相同／未增 `[FS_PAGE_GAP]` 原因／只读快照）⇒ 副本口径执行到位。

**裁定三十七（承 `t147` 回执，`ts=2026-09-29T17:0x+08:00`）—— (a) 采纳成因判定：那 22 处**不是形态洁癖，而是真的吃掉了判词文本**；(b) 立纪律条两条（拼装形制 ＋ 改判词先跑本牙）；(c) 认可其三条守恒证明的形制并升为通用要件；(d) 一处遗留升格为口径：**自测绿 ≠ 判词完好**。原文与既有裁定一字未删。**

**(a) 性质升格（这是本条最要紧的一点）**：`t147` 现取证明 —— 22 处 `DQ-BACKTICK` **不是**"源码不好看"，而是**运行期真的执行了命令替换**：改前那份输出里 bash 报 `…: 行 632: LightGray: 未找到命令` ×5 行，**判词文本被吃掉**。⇒ 也就是说 **`t145` 当时交出的守卫，在走到那些 `echo` 分支时会吐出被吃坏的判词** —— 这是**功能缺陷**（判词可读性/可复核性被破坏），不是风格问题。⇒ 队长据此把它从"牙红"升格为**"判词保真"缺陷**（与裁定二十三「字段级诚实性」、裁定三十六 (c)「帧面读数」同族：**凡给人看的判词，必须是它声称的那段文字**）。

**(b) 立纪律条两条（`t147` 的建议，队长采纳）**：
- **纪律条（判词保真）**：**凡 `tools/**` 里的判词模板，一律经单引号变量拼装**（形如 `BT='`'` 后用 `${BT}…${BT}`），**禁止**把 markdown 式反引号直接塞进双引号 `echo`；**禁止**用 `eval`（`t106` 已立）。
- **纪律条（改判词即跑本牙）**：**凡改动 `tools/**` 的判词文本，同趟必须先跑 `shell-quote-trap-check.sh`**。理由：本族已复发 **3 次**（`t106` 立形制、`t136` 中招并审计、`t145` 又引入 22 处）⇒ **只靠"下次小心"挡不住**。
- ⇒ **正式落册**（`docs/ROUTES.md §15af` 纪律族索引 ＋ `HANDOFF-NEXT.md` 索引块）**排下一波**：本裁定先把两条纪律的**全文口径固定**，落册只是搬运、不改变口径。

**(c) 三条守恒证明的形制升为通用要件（以后同类修复照此办）**：`t147` 用了三条**互相独立**的证明 —— ① **静态**：`printf '%s' "${BT}" | xxd` ＝ `60`（反引号字节）＋ 逐行 word-diff **只含**该替换 ⇒ 判词内容零改动；② **经验**：同一路径轮换跑 `pre`／`post`／`mut`（同一输入）⇒ `pre vs post` DIFFERS（11 行 ＝ 5 行 bash 错误噪声 ＋ 6 行被吃的判词文本）、`post vs mut` DIFFERS、而 **`pre vs mut`（把 bash 报的行号归一后）＝ IDENTICAL** ⇒ **差异完全由「陷阱形态」造成，与"我改了输出"无关**；③ **判词行 `cmp` ＝ IDENTICAL**（按裁定三十四 (b) 的射程读）。⇒ 这条**"用 mut 作桥梁、把 pre/post 的差归因到形态而非内容"** 的办法很漂亮，**升为通用要件**：凡修复改变源码形态的件，必须给出**能把它与"内容改动"分开**的证明。

**(d) 遗留升格为口径 —— `t147` 主动认的**：`t145` 当时自测 **`PASS 80/0`**（它的基线也自取正确），却**没抓到**这 22 处 ⇒ 因为那些 `echo` 分支**只在特定路径才走到**（未执行分支）。⇒ **口径写死：自测绿 ≠ 判词完好**；凡新增/改动判词行，除自测外**必须**至少 (i) 实跑触达该分支，或 (ii) 给出静态审计（引用形态扫描）—— 这与「净腿不崩 ＝ 假绿」同族（**未触达的绿不是绿**）。⇒ 本会话该族**可点名的 2 例**：① `t58` 漏 `PIPEFAIL-SIGPIPE`（由队长的**临时 pan-check** 抓到，它自己那趟没抓到）；② **本条**（`t145` 自测 `80/0`，而判词在未执行分支上被吃）。**其余同类事例本席不再凭记忆列举**（按"引必可核"的规矩，宁可少写）。

**(e) 件态**：守卫 `265b9d6b72853749`/1301 ⇒ **`a37f8330a593c3ae`/1304**（`numstat 8 5`）；载体 `build/MilBridge/P1-quote-trap-fix-report.md`（67 行／sha16 `3536cbcfeaf5931f`／末行自证 `386b7dd58e87d3af` MATCH）。牙终态：`shell-quote-trap-check.sh` **`rc=0 traps=0`**、`--selftest PASS 80/0`、`REPORTID=PASS files=272`、`DEFREG=PASS`＋`DECLDRIFT=0`。夹具全在仓外（仓内 `zz-`／`t147` 命中 0）。

**裁定三十八（承 `t148` 全面回执，`ts=2026-09-29T17:1x+08:00`）—— (a) 队长认账（第 12 次）：裁定三十六 (b) 的**落笔前提被推翻**；(b) 立口径「**机制级断言必须 ≥2 个独立样本**」；(c) `t146` 的帧面读数**必须带离群注记**；(d) `t148` 的 T3 安全试错模式**升为通用工具**；(e) 开一条"帧面确定性"归因线。原文与既有裁定一字未删。**

**(a) 认账（第 12 次）：我在裁定三十六 (b) 把"帧变 ＝ `+80` 懒创建副作用"当成了**机制**，并据此立了 (c) 的口径 —— 而 `t148` 用五样本表把它推翻**：`t141`（引入前）／`legs-off`×2／`legs-on` **四个样本逐格相同**（`fr_sha ef3fd6765f18f51b`、`fr_ae_boot 15386`、`colors 383`），**只有 `t146` 那趟不同**（`b273ebecc332fc03 / 14775 / 391`）⇒ `t146` 是**离群**，"探针开 ⇒ 帧变"**未被证实**。

⇒ **成因（我自己的，必须记）**：`t146` 只给了**一个样本**（1 窗 4 调），我**没有要求第二个样本**就把它升格为"机制"并写进裁定。⇒ **这是本会话第三次**同族错误（前两次：① `line_is_hist` 盲区凭文本相似度定位（裁定三十三第二次附记）；② `t132` 候选读法未复现定位路径）—— 共同形态是「**用一次观测去支撑一个机制级结论**」。⇒ **口径写死（本条最要紧的产出）**：

> **凡"机制级"断言（X 引起 Y／X 必然导致 Y），必须 ≥2 个独立样本支撑；单样本只能记「观测」，且必须显式标注"样本数 ＝ 1，不得当机制"。**

**(b) 但 (c)「跨闸／跨代不可比」的口径**仍然立**（只是它的**理由**要改）：它**不再是**因为"探针开会让帧变"，而是因为 ① 帧面读数跨**代际**本就不可直接相减（纪律 31/32）；② 探针闸状态是**读数的一部分上下文**，不写就可能被后人误当作同一条件。⇒ 我把它**降格为"读数上下文必须完整"**，**不**再声称它是一条"假绿通道"。**假绿通道的清单里，本条撤销**（现役两条仍是：`N4` 的「登记即算」（`t145` 已堵）、以及 (b) 新立的"单样本当机制"）。

**(c) `t146` 帧面读数的引用纪律**：`t148` 建议"后续凡引用 `t146` 的帧面读数，请带上『该趟离群、成因未定』一句" —— **队长采纳并写死**。`t146` 的**其余**读数（`+80` 返回 `0x2`、`idem`、反腿、导出面、`PRECOND-*` 闭合）**不受影响**，它们与帧面离群无关。

**(d) `t148` 的 T3 安全试错模式 —— 升为通用工具（本会话最实用的新方法）**：用**真**句柄先调一个槽造出 **live 的错类型句柄**（`[DRIVE-PROBE-T3] stage=create-live-wrong-type rc80=0 seg=0x2`），再把它喂给别的槽 ⇒ 得到 **`rc=-100002`（`tserrCallbackException`）且**可捕获**（`app_rc=124`／`unrec=0`／`failfast=0`，进程活着）**。⇒ 意义：**存在一类"把错误喂进去但不崩"的探路手段**（对比伪值 `0x1000`／`0x2` ⇒ `FailFast` **不可捕获**）。⇒ **口径**：**凡"试错槽"必须优先走 T3 式路径**；用伪值必须**先把真值域现取出来**（`t146` 现取真 `nms` **就是 `0x1`** ⇒ 它原计划的伪 `0x1` 是空转）。⇒ 三类反腿现已**按类点名**：**T1** `Invalid object handle.`（`PtsContext.cs:247`）／**T2** `Handle has been already released.`（`:248`）／**T3** `-100002` 可捕获。

**(e) 开一条"帧面确定性"归因线（`t150`）**：`t148` 已把离群成因记 `NOINFO` 并正确指出两个候选 —— **调用强度**（`t146` 是 4 调）vs **那一代代码**（`4618f9f2be1c7682`）。⇒ 队长据 (b) 的新口径开三组臂实验（闸关／1 调／4 调，**各 ≥3 样本**），判别式**先写死再跑**。**为什么值得做**：若帧面本身在**同等条件下**不确定，则 `N1`／`N3` 的一切帧面读数都**不可信**（判据可信性的前提）；若确定，则 `t146` 那趟就只是一个已定性的历史噪声。**注意**：本线**不是** W8 驱动链的关键路径（`+80` 已通），它是**判据可信性**线。

**(f) 件态**：`win32_pts.c 4d9d7dad41274b31 → 4ced3a697b3bcabc`（`61 15`）｜`.so 4618f9f2be1c7682 → 980a00d41320227e`｜`exports 609 → 610`（**＋1** `WpfLinuxWin32_PtsDriveProbeGate`，**无导出消失**）｜`^Fs=6`｜症状门三趟逐格同一｜`PTSGAP=PASS`／`REPORTID=PASS files=273`。载体 `build/MilBridge/P1-drive-probe-gate-report.md`（117 行／sha256 `da0436c69988946dea6d9a6a041b780190a38923f4584099ae6e7c7611cb9638`／末行自证 `8eebbf7bd0e6fdef` MATCH）。它另点 **7 条具名 `NOINFO`**，其中一条**必须记进账**：**闸只加在两处调用点、未普查全库**（⇒ 不能声称"探针在所有路径上都被闸住"）。

**裁定三十九（承 `t150` 全面回执，`ts=2026-09-29T17:2x+08:00`）—— (a) 立 `PRECOND-FRAME-DETERMINISM` 并据此**冻结 `fr_sha` 类要件的判词产出**；(b) 🔴「不可归因」是**双向**的（`N3` 的红也要标记）；(c) 开 `t152` 定位第三成因的**形状**（不要求机制）；(d) 装置件"静默少样本"修法归 `scribe`（`t153`）；(e) 三条现役假绿通道清单更新。原文与既有裁定一字未删。**

**(a) 立 `PRECOND-FRAME-DETERMINISM`（`t150` 已拟，队长照准并**加强为冻结令**）**：`t150` 九样本（同代 `1eb2ab9aa211f4ac`）证明**帧面在本代不可复现** —— 决定性样本是**臂 A-3：探针零调用（`probe=0 enter=0 gate-off=3`）下帧面照样变成 `b273ebecc332fc03/391/14775`**；而**臂 C 用满强度（`N=4`、12 次调用）却 3/3 都是基准帧** ⇒ **两个候选（调用强度／那一代代码）都被否掉，存在第三个与探针完全无关的成因**（机制与概率记 `NOINFO`）。变体计数 `ef3fd676…` ×6／`b273ebec…` ×3，成对变化（`colors 383→391`、`ae_boot 15386→14775`），**症状门 9/9 全同**。

⇒ **冻结令（本条的实际约束力）**：凡以**具体 `fr_sha`／帧内容**为**要件**的判据 —— `N1①`（`fr_sha ∉ 空态集`）／`N3`（`AE(k23,k24)>0`、去重 `=2`）／`N4`（`PTS_N4_POSITIVE_FP` 指纹登记）／守卫的 `in_empty_set` 面 —— **在 `PRECOND-FRAME-DETERMINISM` 取得读数之前**：① 其判词**必须**带 `frame-determinism=NOINFO`；② 该要件**不得单独支撑绿**（本已在 `t136` 立）；③ **也不得单独支撑红**（见 (b)）；④ 引用这些读数的人必须同时给出**采样次数与变体分布**。

**(b) 🔴「不可归因」是**双向**的（本会话第一次明确，也是本条最有价值的一句）**：`N3` 今天**判红**（两页帧同值、`AE(k23,k24)=0`）。但既然帧面本身会**在同一条件下**随机落在两个变体上，**这个红同样是不可归因的** —— "两页同帧"既可能是"两页确实同貌"，也可能是"**两页恰好都采样到同一变体**"。⇒ **口径**：**凡因帧面不定性而不可归因的判据，其绿与红必须同样标记**（`UNRELIABLE`）；**只标绿不标红 ＝ 用不确定性单向地为自己留后路**，这是不可接受的。⇒ 具体到 `t119`／`t120` 的 `N3` 结论：**结论本身仍成立**（当时那两帧逐字节相同是事实），但**它的判据效力现在降为 `NOINFO(帧面不定性)`**，**不得**被后续任何件当作"`N3` 已判红、故可以做/不可以做某事"的依据，**必须**在帧面确定性有读数后**重取**。

**(c) 相位翻转的三个前置因此全部不可用（本条加强既有裁定）**：`N1`（要件①依赖帧身份）／`N3`（依赖两帧比较）／`N4`（依赖帧指纹登记）**三者全部**落在被冻结的射程内 ⇒ **「今天不得翻相位」由"`N3` 红"的**弱理由**升级为"三个前置**全部不可用**"的**强理由**。**相位位一行不动。**

**(d) 两条排期（都不阻挡主线）**：
- **`t152`（`runner`）**：定位第三成因的**形状**（**不是机制**）—— 采纳 `t150` 自己的方法建议：**≥20 个独立样本**、**每样本独占显示号**、**次序随机化**、逐趟记环境与负载、**被拒/被跳样本数计入输出**、**跨代并列不相减**（纪律 31/32）；判别式**先写死再跑**；机制若仍不可定 ⇒ **如实 `NOINFO`**。**为什么值得**：帧面不定性会**腐蚀一切帧面判据**（它是判据可信性的根）。
- **`t153`（`scribe`）**：装置件修法 —— `run-pts-pages-legs.sh` 的**"静默少样本"**：① 跑前确认号空闲（有界等待，超时具名）；② 每趟独占/轮换号；③ 🔴 **被拒/被跳样本数必须计入输出**（核心是**"没拿到"与"拿到了但是坏的"在输出上可分**）。既有列（`CLICK`／`FAILLINE`／`FRAME`／`PHASE`）**形状一字不动**。
- ⚠️ **两条线的顺序**：`t152` **用 `t150` 已验证的手工换号**（`t150` 自己就是这么做满 9/9 的）⇒ **不依赖 `t153`**；`t153` 是**根治**、`t152` 是**取证**，两者不冲突。

**(e) 现役假绿通道清单（更新，三条）**：① **`N4` 的「登记即算」**（`t145` 已堵：登记须附守卫自算的独立读数，否则 `N4-DECLARED-ONLY` 不给绿）；② **「单样本当机制」**（`t148` 立口径、裁定三十八）；③ 🔴 **「帧面不可复现 ⇒ `fr_sha` 类要件不可归因」**（本条立）—— 第三条**最隐蔽**：它**不需要任何人动作**（前两条都需要有人写错或写少，第三条是**仪器本身的随机性**）。⇒ 三条的共同形态：**判据的"输入"本身不可靠**（自指声明／样本不足／仪器随机），**而判据照常给出判决**。

**(f) 一处装置陷阱入册（`t150` 上报的 medium）**：「上一趟**自己**起的 Xvfb 未即时收净」被判 `device=NOINFO reason=display-occupied` 而**拒跑**，且**失败呈"静默少样本"形态** ⇒ 首轮 9 样本**只 1 个**拿到读数。⇒ 这是**「未触达/未计数」族的第 3 例**（前两例见裁定三十七 (d)）⇒ 该族**已有 3 例**，证据足以把它从"个案"升级为**族级纪律**：**凡"样本/触发被拒"，必须在输出里可数与可分。**

**裁定四十（承 `t152` 中途报备，`ts=2026-09-29T17:3x+08:00`）—— (a) 立**族级纪律**「多趟采样件：逐趟记代际指纹 ＋ 批内代际守卫」；(b) 编排裁定：`t155` 先行、`t152` 等冻结令、**不许预测代际值**；(c) 认可 `t152` 的处置并把它的两条形状线索入册（**只作并列**）；(d) 「跑中被打断」是「未触达/未计数」族的**第 4 例**。原文与既有裁定一字未删。**

**(a) 新立族级纪律（本会话第 4 条族级纪律，前三条：判词保真／未触达的绿不是绿／不可归因须双向）**：

> **凡多趟采样件**（跑腿、批次、统计、任何"取 N 个样本"的取证）**必须**：① **逐趟现取并写入该趟的代际指纹**（至少 `auth_so16`／`auth_pf16`）；② 批内设**代际守卫** —— 批启动取 `GEN_REF`，任何一趟现取代际 ≠ 批基准 ⇒ 该趟记 `verdict=VOID generation-changed` ＋ **立刻停批** ＋ 落 `generation_void.txt`；③ **禁止跨代拼表**（纪律 31/32 在"跑批"这一面上的形态）。

**为什么值得立成纪律**：这次暴露的形态是 —— **"跑中被打断"在外观上恰好就是"样本数变少"**，与"静默少样本"是同一条假进度面；而**跨代拼成的"24 样本概率"** 会是**看起来最像结论、其实最不可信**的那种读数（它把两个世界的数字平均了）。⇒ 纪律的落点不是"下次小心"，而是**把守卫写进采样器**（`t152` 已经这么做：逐趟写指纹 ＋ `GEN_REF` 守卫 ＋ 立刻停批 ⇒ **队长要求"约定"落成"机制"**，此为其范本）。

**(b) 编排裁定（跨车道写者冲突的处置）**：冲突源＝`scribe` 的 `t155`（`P4` 收尾，须在 `build/PresentationFramework.Linux/PtsCache.Linux.cs` 加**只读打印** ⇒ **必然重建托管件** ⇒ 换代），它是 `t152`（测帧面）的**硬伤**（帧面读数必须带代际）。裁定：
- **不让 `t155` 收手**（它短、且是 `P4` 的收尾件）；
- **`t152` 暂停跑批**，等 `t155` 交件；其间它把 cohort-1 归档、被拒台账、序表凭证**现取报队长**（不必等）；
- `t155` 交件后**队长现取确认权威件稳定**（`.cs` mtime 不再前进 ＋ 无 `VBCSCompiler`／腿在跑）⇒ **队长把确切的 `auth_so16`／`auth_pf16` 发给 `t152`**，它用**同一张已先写死的序表**跑满**单代 24 趟**；
- 🔴 **不许预测代际值**（队长现取过一次候选值 `auth_pf16=0b4b65f2c6c7ffd4`／`auth_so16=db3c9d5c857ff376`（`ts=17:30:36`，`.cs` 已 6.7 分钟未变），但**因 `t155` 的腿正在跑**（`ps`：`VBCSCompiler`≈318s／`Xvfb :230`／`dotnet`）而**暂不发冻结令** —— 同时跑腿会抬高负载、**污染 `t152` 的 D3（负载相关性）那一格**）。⇒ 口径：**冻结值必须现取于"写者已停 ＋ 无腿在跑"的时刻**。

**(c) 认可 `t152` 的处置（三样凭证 ＋ 两条形状线索）**：
- `cohort1_pf_c52d9191feb5ba7c/`＝**147 件**全量归档，清单 `cohort1_inventory.txt`（148 行／sha16 `08a78cdffa3c037d`，**花名册哈希** `18cb86bc5f4efc2c` —— 口径＝按相对路径排序、每行「相对路径＋文件 sha16」再取 sha256 前 16）；`refusals_batchB_appstale.txt` **10 行**／`3c45646326f3648d`；`schedule.txt` **25 行**／`aaa122b3dc0ef52b`（＝"序表先写死"的凭证）；`cohort1_analysis.txt` 66 行／`7a33d6c3948631a0`（含 Wilson 区间）。⇒ **全部登记**。
- 🔴 **形状线索一（只作并列，主表须在冻结代复验）**：**`boot.png` 8/8 全同**（`b21eb530afd3c66c`／colors `386`），而**变体只出现在 `k23`／`k24` 面** ⇒ 变体**不是"整体渲染随机"**，它与 `k23`/`k24` 那一支相关。⇒ 这条**收窄了成因的射程**（对将来定性第三个成因有用）。
- 🔴 **形状线索二（只作并列）**：**F 臂（全部同号 `:237`）5 趟里两变体都出现**（β,α,β,α,α）⇒ **同一显示号不能决定变体** ⇒ 判别式 **D1 在 cohort-1 上已证伪**。
- 症状门 8/8 全绿；闸状态逐趟在册（闸关 6 趟 `enter=0/goff=3`，闸开 2 趟 `enter=1/probe=1/budget=2`）。

**(d) 「跑中被打断」＝「未触达/未计数」族的第 4 例**：前 3 例见裁定三十七 (d) 与三十九 (f)。⇒ 该族**已有 4 例**，全部形态一致：**"没拿到"与"拿到了但是坏的"在输出上不可分**，于是上位判据在样本不足时照常下结论。⇒ 本条与 (a) 的族级纪律配套：**(a) 治"跑中被打断"，(裁定三十七 (d)／三十九 (f)) 治"拒绝/未触发"**，两者的共同解都是**把计数与代际写进输出**。

**裁定四十一（承 `t155` 上报 + `t152` 自查回执，`ts=2026-09-29T17:4x+08:00`）—— (a) 两条装置缺陷入册并判**必修**（排期在 `t152` 批之后）；(b) `t152` 的处置是**前提修正**而非绕过，认可；(c) 立一条编排口径：「**批跑到一半不换工具**」。原文与既有裁定一字未删。**

**(a) `D-1`／`D-2`（`t155` 只报未改、在它写域外；队长判必修）**：
- **`D-1`（真缺陷，会让腿静默走向失败）**：`run-pts-pages-legs.sh` 把 Xvfb 起在**它分配的号**（`DISPLAY_PICK display=:231`），而 `session_inner.sh` 的 `$D` 取自 **`W67_DISPLAY`（缺省 `:237`）** ⇒ **应用被喂 `:237`、`XOpenDisplay` 失败 ⇒ `APP_RC=134`、`obtained=0 refused=2`**。⇒ **两个入口的显示号没有联动**，装置"分配了号"却"没把号交给应用"。⇒ 修法方向：**号必须从分配点单向下传**（或让 `session_inner.sh` 的 `$D` 与分配结果同源），且**被拒要保持在计数里**（`t153` 的 `LEGSCOUNT` 已做到，这条**不是**它的功劳被抵消）。
- **`D-2`（误判通道）**：`occupied_by()` 按 `/proc/*/cmdline` **字面**扫显示号 ⇒ **任何第三方 `bash -c` 的命令行里出现 `:23x` 就会被判"该号被占"**。`t155` 实测撞到的 `occupant_pid=3795376` 竟是 **`~/t123-runner/logs/t152` 侧的 `bash -c`**（**不是 X server**）⇒ **两个写者互相误判过**。⇒ 修法方向：把"占用者"判据收紧到**真的是 X server**（如 `Xvfb` 进程 ＋ 其 `-display`／socket 归属，或读 `/tmp/.X11-unix/X<n>` 的存在与持有者），**而不是**命令行字面。
- ⇒ **排期**：**必须等 `t152` 的 24 趟批结束之后**再动装置件（见 (c)）；届时派装置写者，两极化照 `t153` 的形制（**被拒必点名可数**）。

**(b) `t152` 的处置 —— 是「前提修正」，不是「绕过」，队长认可**：它把**同一个号同时喂给两个入口**（`run_batch.py:141-142` 逐趟 `env["PTS_GUARD_DISPLAY"]=disp` **且** `env["W67_DISPLAY"]=disp`，逐趟联动）⇒ **从根上消掉 `D-1` 的分叉可能**（不是"把错误藏起来"，而是**把两个入口的前提对齐**）。现取证据（`20/20` 趟）：`DISPLAY_PICK … rule=caller-fixed(PTS_GUARD_DISPLAY)`、每趟 `obtained=2 refused=0`、`app_rc=143`（＝它发 SIGTERM 的正常形态，**非** `134`）；`grep -nE 'DISPLAY_WAIT|display-not-free|occupant_pid|APP_RC=134|refused=[1-9]' cohortP.out` **零命中**。⇒ **它能绕就绕、并把绕法与前提写清**，这正是我要的。附加收获：它用过的号覆盖 `:231/:233/:234/:235/:236/:237/:238` **全部拿到满样本** ⇒ **顺带证伪"变体由某个特定号决定"**。它也如实报了 `D-2` 对它的**外力风险**（它自己命令行里无显示号 ⇒ 无自伤面；且它的跑前自查**更严**：要求 cmdline **同时**含 `Xvfb` **且**含该号，并排除 `$$` 与祖先链）⇒ **它的自查不误报，但拦不住装置侧误判**（目前零发生）。

**(c) 新立编排口径：「批跑到一半不换工具」**：凡**多趟采样批在跑**期间，**该批所用到的任何工具／装置件都不得被任何人修改** —— 否则批内样本**非同工具**，与"跨代拼表"同性质的**混杂**（纪律 31/32 的工具面形态）。⇒ 因此队长**主动压住**装置写者（`D-1`／`D-2` 的修复件**排到批后**），并**拒绝**了 `t152` "为我派装置写者"的建议（它自己指出"修 `D-1`/`D-2` 请放在我批结束之后，否则会把我的 24 趟变成非同工具的混杂批" —— **这个判断正确，队长照准**）。⇒ 与 (a) 的代际守卫**配对**：**代际守卫治"件换代"，本条治"工具换代"**，两者共同保证「同批可比」。

**(d) 一处口径固化**：`D-1` 暴露的形态是「**装置分配了一个资源，却没把资源交给消费者**」—— 与"静默少样本"不同，它**会让消费者走向失败**（`APP_RC=134`）；⇒ 口径：**凡装置分配资源（显示号／槽位／目录），必须把"分配结果"单向下传给消费者，且消费者用的是同一来源**（`t152` 的双变量联动即为范本）。

**裁定四十二（承 `t152` 主表，`ts=2026-09-29T17:4x+08:00`）—— (a) 主表结论入册；(b) 🔴 `PRECOND-FRAME-DETERMINISM` **仍未满足**，冻结令**维持**；(c) 🔴 第三条假绿通道**有了具体实现路径**（β 不在集里）⇒ 判**并入 β**（`t157`）；(d) 第三成因的射程被收窄；(e) 认可它的自限。原文与既有裁定一字未删。**

**(a) `t152` 主表（`build/MilBridge/P1-frame-determinism2-report.md` 247 行／末行自证 `0f0819a68e617710` MATCH；主表逐行与 `rows_0*.json` **脚本对拍**一致）**：
- **单代 24 样本、零被拒零作废**：`auth_so16=db3c9d5c857ff376`／`auth_pf16=0b4b65f2c6c7ffd4` **逐趟现取、24/24 单值、零 `VOID`**；序表 `aaa122b3dc0ef52b` **跑前写死未重排**；墙钟 `17:31:48–17:43:40`。
- **两个变体**：α `ef3fd6765f18f51b`／`383`／`15386`＝**17/24＝0.708**（Wilson95 `[0.508,0.851]`）；β `b273ebecc332fc03`／`391`／`14775`＝**7/24＝0.292**（`[0.149,0.492]`）；**未见第三个**（该面上不可见 ⇒ **不反推"只有两个"**）。
- **四项相关性全判"无关"（每条都有现取支撑）**：**显示号**（F 臂**全同号 `:237`** n=8 里两变体都出；`:237` 共 11 趟 β4:α7）｜**次序·时间**（序列 `BABABBABAAAAAAAAABAAAAAB`，无单调划分点、区间重叠 22/24；**游程检验 z=0.04／p≈0.97**）｜**负载**（两组分布重叠，且 **`other_legs_n=0`×24** ⇒ 负载格**没被别人的腿弄脏**）｜**探针**（G 臂闸开 n=4：α,β,α,β）。
- **两条新形状**：**变体在"每趟实例"内被固定**（`k23=k24=last` **24/24**，两次点击间隔 ~30 s）；**`boot` 面恒定**（24/24 单值 `b21eb530afd3c66c`／`386`）⇒ **变体只出现在 `k23`/`k24` 那一面**。
- **跨代只并列**：`t150`（`1eb2ab9aa211f4ac`）6α:3β｜cohort-1（`c52d9191feb5ba7c`）5α:3β、`boot` 8/8 同｜主表（`0b4b65f2c6c7ffd4`）17α:7β、`boot` 24/24 同 ⇒ **两个变体串在两代"同名同形"**（sha 与 `colors`／`ae` 成对差**逐位相同**）⇒ **非某一代引入**（**不合并统计**）。
- **零行为改动**：`nm=620` 逐名未变、`^Fs=6`、症状门 **24/24 单元素**、闸关 20 趟 `probe=0`（`enter=0`／`gate-off=3`）**与 `t150` 臂 A 逐格同**、**本件 `numstat` 为空**（产品件 sha16 逐件与跑前相同）。

**(b) 🔴 裁定：`PRECOND-FRAME-DETERMINISM` **仍未满足**；裁定三十九的冻结令**维持****。理由：该前置要求的是"**同条件同帧**"，而实测是"**同条件两个变体**"（且与已测的四个变量**全都无关**）⇒ 帧面**不是确定的**。⇒ 因此：① `N1①`／`N3`／`N4`／`in_empty_set` **继续冻结**（判词须带 `frame-determinism=NOINFO`）；② **不得**因为"现在知道只有两个变体、概率也量了"就解除 —— **知道分布 ≠ 确定**：不知道该趟会落在哪个变体，**仍然无法把单趟的 `fr_sha` 当作该趟的"身份"**。⇒ 解除条件（写清，免得后人误判）：**要么**找到并控制那个未知变量（使其单值化），**要么**把判据**重新表述为"变体集内的成员资格"**并**为集合本身提供独立正证据**（后者须走 `t136` 的"必要非充分 + 正证据闸"口径）。

**(c) 🔴 第三条假绿通道**有了具体实现路径**（从"抽象警告"变成"现成读数"）**：现取 `FRAME_EMPTY_SET = {1a76488aa4a790b3, ef3fd6765f18f51b}` —— **β `b273ebecc332fc03` 不在集里**，⇒ **落在 β 的趟会让 `in_empty_set=no` ⇒ `N1` 要件①「帧身份 ∉ 空态参照集」"成立"**，**而 β 同样是空态画面**（它与 α 只差 `colors 383→391`、`ae 15386→14775`）。⇒ **这印证了裁定三十九第 (c) 条**（我当时只把它写成"采样恰好落在另一变体就可能成立、不需要任何人动作"的警告，今天它有了**概率读数和具体指纹**）。⇒ **裁定：把 β 并入** `FRAME_EMPTY_SET`（三成员累积集），已派 `t157`（含**因果对**判据：把 β 移出 ⇒ 夹具**回假绿**，证明这次并入真的堵住了那条路）。**这不解除 (b) 的冻结** —— 它只是**把参照集补全**，让"要件①"不再因变体而假绿（`t136` 的"必要非充分"与 `t145` 的"登记须附独立支撑"两条**同时**继续生效）。

**(d) 第三成因的射程被收窄（有用的负结论）**：既然变体**只在 `k23`/`k24` 面**出现、`boot` 面恒定，且与**显示号／次序·时间／负载／探针**四项全无关 ⇒ 决定变体的是一个**帧面之外的未知变量**（`t152` 的具名 `NOINFO` 六条之首）。⇒ 这排除了"环境噪声／调度抖动／别的腿在跑"这一整类解释，把将来的定位工作**收窄到"渲染路径本身在两次点击之间的状态"**。

**(e) 认可它的自限**：① 它把"前 8 趟更易出 β"（Fisher `p=0.0207`）明确标为**切点事后选 ⇒ 不作结论**，要坐实须**预登记**另件 —— **正确**（这正是"事后选切点"的经典陷阱，与裁定三十八的"单样本当机制"同族）；② n=24 的频次精度限制如实记为 low；③ 它主动指出"修 `D-1`/`D-2` 要放在批后"（见裁定四十一 (c)）。

**裁定四十三（承 `t156` 回执，`ts=2026-09-29T17:5x+08:00`）—— (a) **三级链 native 侧全通**；(b) 我点名的两个风险都堵住了；(c) 采纳"装置台账逐趟打印装置件 sha16/mtime"的建议；(d) `D-1` 现形—修复的时序归因清晰；(e) 三条红入册；(f) `t129`/`t131` 的两条「结构性做不到」**被解锁**，下一跳判据已派。原文与既有裁定一字未删。**

**(a) 第三跳结论入册（W8 驱动链第三跳打通）**：载体 `build/MilBridge/P1-drive-probe3-report.md`（**226 行**／末行自证 `8a1740c697c2c2e4` MATCH／full sha16 前 32 位 `8324d45a3015d75a08ec637145f5c160`；**载体读数与原始日志逐格对拍 31 项全中**）。**五格证据串**（S1／S2 两独立样本、同闸开、**判词与值逐格相同**）：`nmp176=0x3 pfsclient=0x1 out_pre_h1=(nil) rc176a=0 h1=0x4 rc176b=0 h2=0x5 h2_ne_h1=1 rc192a=0 rc192b=0 skip192=0 ctx_live=1 v176=PARACLIENT-NEW-PER-CALL(h1,h2) v192=BOTH-RECYCLED` ⇒ **①—④ 全中**；**⑤ 活条目数 ＝ `NOINFO`**（载体明写**不得**用"腿没崩"代替 —— 这条自限我认可并保留）。**P3 成对**：`out_pre_h1=(nil)` → `h1=0x4` 同趟成立 ⇒ **非 native 自造值**。**窗内外成对 ＝ `WINDOW-INSENSITIVE(有据)`**（与代码级预判一致 ⇒ **不判红**，这正是 `t154` 判据要求的处置）；**T3 换料闭合**（真 `sect` ⇒ `+176` `-100002` 可捕获；真 `nmSeg1` ⇒ `+192` `-100002` ⇒ 判别器"对非法值必红"自证）；**`+200` 按 P9 禁用**并留负面对照（`rc200_null == rc200_hand` ⇒ 无判别力）。**逐件**：`win32_pts.c 8089fdfea1ac6f23 → 6d967d8843bd902b`（`247 0` **纯增**）｜`.so db3c9d5c857ff376 → 99093641234bcb81`｜`exports 620 → 640`（**逐名零消失、＋20 名**）｜`PTSGAP=PASS`。

**(b) 我点名的两个风险都堵住了（逐条对应 `t154` 判据的更正）**：① **非幂等** —— 两次各非零且**互不相同**（`h1=0x4`／`h2=0x5`），且**两次都被 `+192` 接受回收**；**未**把 `h1≠h2` 读成失败（P8 立住）。② **T3 必须换料** —— 没有拿 `nms`（`ContainerParagraph`，**对 `+176` 是"对类型"**）当错类型反腿，而是改用真 `sect`（`Section`）⇒ `PRECOND-WRONG-TYPE-LIVE-HANDLE` **现证闭合**。

**(c) 采纳一条建议（要派件）**：它建议「**装置台账逐趟打印装置件自身 sha16/mtime**，让"同一批内工具一致"可被**机器核**」—— 依据是它自己那趟"装置版本跳变"是**人工 `grep` 才发现的**。⇒ **队长采纳**：这与**代际指纹守卫同形**（一个记"件换代"、一个记"工具换代"，见裁定四十一 (c)），应把它**从建议落成装置输出的新增行**（新增行，既有列形状不动）。⇒ 排给装置写者（`scribe`，它手上的 `t157` 落定后）。

**(d) `D-1` 现形—修复的时序归因（清晰，认可）**：`t156` 跑腿期间（P 腿 `17:50:07`，**旧装置**）撞上 `D-1`（装置自选 `:231` 而消费端仍 `:237` ⇒ `XOpenDisplay(":237")` 失败 ⇒ **`APP_RC=134`**、`LEGSCOUNT obtained=0 refused=2 reasons=converter-rc=1,no-leg-env=1` —— **计数可见，`t153` 的修复生效**）；随后 `t157`（`mtime 17:51:03`／sha16 `fb469f205b88e444`）把它修成 `W67_DISPLAY` **单向下传** ＋`occupied_by()` 按 **socket 真持有者／`is_x_server`** 判占用。⇒ 它的 **S1／S2 落在修后版本**（`rule=caller-fixed(W67_DISPLAY)`），**P 腿只是装置面读数、不参与样本统计** ⇒ **归因正确**。⇒ **但这条同时印证裁定四十一 (c)**：`t157` 在飞期间改了装置件 ⇒ `t156` 的 P 腿与 S1/S2 **确实不同工具** —— 它把这个事实**查出来并排除**，正是"批中不换工具"要防的形态被**计数与归因**兜住了。

**(e) 三条红入册（它自报，我照录）**：① **⑤格"活条目数"仍 `NOINFO`**（需托管侧或原生侧 `CreateHandle` 计数件，medium）；② **"窗外"归类仍属代码结构推断**（需窗口状态读数，medium）；③ 🔴 **`WPF_PTS_DRIVE_PROBE3_CTXDEAD`（在已销毁 context 上调 `+176` 的**不可捕获 `FailFast`**）在本应用生命周期内不可达** —— 四趟 `DestroyDocContext` 现取全 **0**（应用被 SIGTERM 收）⇒ 要打它需**另开一件用"能优雅退出"的路径**（medium）。⇒ **口径（它自己写的，我照准）**：**不得把"打不出来"当"通路不存在"** —— 这条与"未触达的绿不是绿"是同一枚硬币的两面。

**(f) 下一跳：`t129`／`t131` 的两条「结构性做不到」被解锁**：`t129` 当年判「`FsQueryTrackParaList` 的**段落列表可用**在 native 侧**结构性地做不到**」，理由是 `pfsparaclient` 的**唯一合法来源是托管回调**；`t131` 当年判「让 `ParaListFromTrack` 拿到**真**段落客户端句柄**不能在本件写域内被诚实满足**」，理由是三段前置未落。**现在三段全落**（`t132` 说三级**全由 native 发起才存在**）⇒ 这两条判词的**前提已变**，**下一跳＝把 `pfsparaclient` 接进段落列表**。⇒ 已派 `t158`（`scout`，**先判据**），并把我判定的**四个核心设计问题**写进派单：① **生命周期**（`+192` 回收后句柄是否即失效？`pfsparaclient` 是**托管表索引** ⇒ native **跨调用持有**是否合法？是否属 `t141` 那类「只在调用期内有效」——**两种情形给两套判据**）；② **窗**（`+136`／`+176` 已证 `WINDOW-INSENSITIVE`，但 `FsQueryTrackParaList` 是**另一个调用点**，`t151` 正是**用它当"窗外"反腿** ⇒ 填它出参是否必须在窗内）；③ **回收责任方**（产出与回收都只能由托管 ⇒ native 长期持有则**谁在何时回收**，否则**泄漏活条目**）；④ **绿的正确读法**（只准读成「native 能把一个**由托管产出且在持有期内有效**的句柄交给列表消费者」，**不得**读成"段落模型已成／排版打通／`TASK-0007` 可绿"）。

**裁定四十四（承 `t157` 回执，`ts=2026-09-29T18:0x+08:00`）—— (a) 🔴 **第三条假绿通道「已实证发生」**（不是理论风险）；(b) 修法到位且新腿有牙；(c) `D-1`／`D-2` 已修并四极化；(d) 裁两处（腿时间重叠＝无碍；`arm_A/**` 维持不提交但须登记来源）。原文与既有裁定一字未删。**

**(a) 🔴 本会话第一条「假绿已经发生过」的实证（这是本轮最重的读数）**：`t157` 现取 `build/MilBridge/P1-frame-determinism2-report.md`（247 行／sha16 `7bc694c16ecd0167`／末行自证重算 `0f0819a68e617710` 相符）的**主表 `:102`／`:104`／`:106` 三行 β 样本判词原文 ＝ **`全绿`**。⇒ 也就是说：**在 β 并入 `FRAME_EMPTY_SET` 之前，落到 β 的那 7 趟里被守卫读到的趟，`N1` 要件①真的判了绿** —— 而 β 是**空态画面**（与 α 只差 `colors 383→391`、`ae 15386→14775`）。⇒ **三条假绿通道的现状因此分成三类**：① `N4` 的「登记即算」（`t145` 堵住时**未发生** ⇒ 属"堵在门口"）；② 「单样本当机制」（`t148` 立口径时**已发生**过一次 —— `t146` 那趟离群被当机制，`t150` 推翻）；③ **「帧面不可复现 ⇒ `fr_sha` 要件不可归因」（本条）＝ 已经发生、且留下了 7 趟 β 里的绿判词**。⇒ **口径**：凡"假绿通道"的登记，**必须区分"堵住时未发生"与"已发生"** —— 後者要**回头点出受影响的读数**（本条即点了 `:102/:104/:106`），不能只记"已修好"。

**(b) 修法到位（逐条我有现取支撑）**：三成员 `FRAME_EMPTY_SET = {1a76488aa4a790b3, ef3fd6765f18f51b, b273ebecc332fc03}`；**逐枚出处**（`1a76…`＝仓外 `~/t119-runner/bak/run-N3-runner-shots/g1/k23.png`，189742 B；`ef3f…`＝`evidence/shots/g1/k23.png`，189716 B；**β `b273…`＝主表那三行判词**）。判据四条：(a) 三成员**逐枚** ⇒ `in_empty_set=yes` ⇒ `PTS_N1=FAIL` ⇒ **点名** `criterion=frame-identity(sha16=…∈{三个})` ⇒ `PTS_GUARD=FAIL` rc=1（β 那枚同样点到名）；(b) 集外值 ⇒ `PTS_N1_GATE=FAIL reason=only-necessary-condition-no-positive-evidence`（**不单独发绿**，`t136` 口径未松）；(c) 🔴 **因果对**：把 β 移出集合后跑**同一** β 夹具 ⇒ 回 `in_empty_set=no` ＋ `criteria-satisfied=frame-identity`（**假绿归因面复现**）—— 这一条是"**证明这次并入真的堵住了那条路**"的证据；`degraded` 期成对 `yes→no`；(d) `--selftest` **改前 `PASS 80/0`（它自己现取，非转述）→ 改后 `PASS 82/0`**（新增 β 极性腿 ＋ 期望串改为从**唯一登记处**现取），**把 β 移出的变体 ⇒ `FAIL 81/1`**，唯一红格＝那条新腿 ⇒ **新腿有牙**。⇒ 真树 `degraded` 判词改前/改后 `cmp` **完全相同**，整份输出仅 **4 行**差异（`set={}` 两成员→三成员）⇒ **本件不改今天的判词颜色，收紧的是"归因面"与"相位翻转后的必红"**（与裁定三十九 (b)「不可归因须双向」配套）。

**(c) `D-1`／`D-2` 已修（装置件，四极化齐）**：
- **`D-1`**：分配结果**单向下传**（`export W67_DISPLAY=$DISPLAY_NUM` ＋ 新增 `DISPLAY_HANDOFF` 行；`W67_DISPLAY` 亦可作 caller-fixed 入口）；会话端新增**具名拒跑** `DISPLAY_MISMATCH`／`LEASE_REJECT reason=allocated-display-not-passed-through`（rc=3）；调用方未给号 ⇒ `DISPLAY_ADOPT from=lease`。⇒ 这正是我在裁定四十一 (d) 固化的口径「**装置分配资源必须把分配结果单向下传给消费者**」的落地。
- **`D-2`**：占用判据由"命令行**字面**扫号"收紧为 **X server 进程（`comm`/`exe` 白名单）＋ 其 display 归属**；新增 `DISPLAY_STALE_SOCKET … action=reclaim`。**并具名作废**了一条更"聪明"的路：**inode 反查** —— 实测 `stat -c %i /tmp/.X11-unix/X239` ＝ `4212990`，而活 `Xvfb` 的 fd 反链是 `socket:[28854481]`（**sockfs inode ≠ 文件 inode**）⇒ 该路**恒查不到**，故弃用且**不静默**。⇒ 这条"**把自己否掉的路也写清楚**"的做法值得记名（前人踩过：`t139` 的 `C-6` 族）。
- **四极化（读数绑当趟字节）**：正极连续两趟 `requested=2 obtained=2 refused=0`＋`PASS`｜反极 真 `Xvfb :239` ⇒ `DISPLAY_WAIT timeout occupant_pid=…` ＋ `device=NOINFO reason=display-not-free` ＋ `refused=2` ＋ `FAIL rc=2`｜**`D-2` 因果对** 非 X server 的壳带 `:239`（`comm=bash`）⇒ **不判占用、直接 PASS**｜**解除占用** ⇒ 同一条命令回正极。⇒ **既有列形状一字未动、`LEGSCOUNT` 语义未退**。

**(d) 裁两处它请我裁的观察**：
1. **它在夹具跑动期间看到"一趟真腿在飞"**（`Xvfb :231` ＋ `dotnet HandyControlDemo.dll`，`DISPLAY=:231` **与 Xvfb 同号**）⇒ 它问"若那是 `t152` 的批，是否与装置改动同趟无碍"。**裁定：那不是 `t152`**（`t152` 已于 `17:43:40` 交件），时间窗落在 **`t156`（第三跳）** 的腿内 ⇒ 与裁定四十三 (d) 的时序一致：`t156` 的 **P 腿（`17:50:07`，旧装置）**与 **S1/S2（`t157` 修后）**不同工具，而 `t156` **已把 P 腿排除出样本统计** ⇒ **无碍**。⇒ 附带一条**有价值的实证**：那趟真腿的 `DISPLAY` 与 `Xvfb` **同号** ⇒ **`D-1` 的"下传"在真腿侧面也被证到了**（不只是夹具）。⇒ 口径：**"批中不换工具"这条口径的首次真实案例出现的当天，就被 `LEGSCOUNT` 计数与写者的归因兜住了** —— 这正是它该有的样子。
2. **仓内 `evidence/arm_A/{app_g1.log, device.txt, leg_23.env, leg_24.env}` 四个未跟踪件的归属**（mtime `09-28 20:57` 与 `09-29 14:12`，**均早于本件**；非它写的）⇒ **裁定：维持裁定六（`arm_A/**` 未跟踪、不提交）**；但**要求登记来源**——`t157` 不得因此被记成"越域"，同时**不能让它烂在 `??` 里无人认领**（那会让每个写者的 `porcelain` 带着噪声，`t134` 的 `src/tests/` 就是这么来的）。⇒ 排给装置/证据面写者**一次性登记**（写清 mtime、来源跑腿、为何不提交），与 `src/tests/` 那次出仓同一族处置。

**(e) 一条口径固化**：`FRAME_EMPTY_SET` 的**每个成员都必须带"它是哪一代／哪一趟的实测"**（本次 β 的出处直接锚到**主表三行判词**，是范本）；**只有指纹不能进出处的登记集**，等于给未来的自己留一个查不到的洞（与裁定四十 (a)、`t144` 的 `F-3` 同族）。

**裁定四十五（承 `t158` 判据件，`ts=2026-09-29T18:1x+08:00`）—— (a) 四问判词入册；(b) 🔴 新缺口「**索引复用 ⇒ 静默错对象**」 ⇒ 采纳「`resolve=wrong-object` **一票红**」；(c) 立一条方法论「**凡"能拦"的断言，必须问它在什么条件下拦不住**」；(d) 禁用件清单入册；(e) 下一跳实现已派。原文与既有裁定一字未删。**

**(a) 四问判词（`build/MilBridge/P1-paralist-wire-criteria.md` 289 行／full sha256 `dfe64c004a914a930566e5e891169f5afc89022f5f8ba1c6a7b665d2f07b19b9`／末行自证 `2e7c9d4613e7d658`；其四问与红榜/禁用件/哨兵表/零假值铁律/六条 `PRECOND-*` 全部入册）**：
1. **持有期 ＝ 托管对象生存期，不是调用窗口**：链 `BaseParaClient.cs:21`（`: UnmanagedHandle`）→ `UnmanagedHandle.cs:28`（构造器 `CreateHandle(this)`）→ `UnmanagedHandle.cs:38`（`Dispose()` 内 `ReleaseHandle`，**全仓唯一调用点**）→ `PtsHost.cs:785`（`DestroyParaclient` 内 `paraClient.Dispose()`）⇒ **native `+192` 即回收触发者** ⇒ `Case I` 成立、可跨调用持有；`Case II`（调用期有效）**判红**。⇒ 这条把「与 `t141` 那类 use-after-return 的分野」讲清了：`t141` 的入参是**调用方栈上的字段地址**（只在调用期有效），而 `pfsparaclient` 是**托管表的活条目索引**（生存期由托管 `Dispose` 决定）。⚠️ 另记：**消费者含"查询帧"**（`ColumnResult.cs:151-165/:228-242` → `FlowDocumentPage.cs:529/:564`；其 `:410-445` 内**未见** `SetDocumentFormatContext`），与 `FormatFinite`（`:51/:199`）**不是同一帧**。
2. **窗口非必要非充分** ⇒ 必须落**两腿实验**（W-1 窗内／W-2 窗外，用 `t151` 的 OOW 腿），**单腿只能 `NOINFO`**（诚实边界：仅局部观察 `:410-445`，未证全链）。
3. **回收责任 ＝ 托管 `Dispose()`，触发点 `+192`；本入口不许自回收、不许"返回前回收"**（否则判 **P4**）。可证伪判据：**R-1 单次性**（第二次 ⇒ `ReleaseHandle:211` Assert ⇒ **`FailFast` 不可捕获**）／**R-2 不晚于上下文销毁**（`:209` Assert ＋ `StructuralCache.cs:181` 在册注释）／**R-3 与那一次 `+176` 绑定**／**R-4 ⇒ `PRECOND-NO-HANDLE-ACCOUNTING`／`NOINFO`**。⇒ 🔴 **严禁用 `rc=0` 冒充"回收正确"**。
4. **绿 ＝ 7 条合取**（`rc=0`；`n>=1 ∧ n==cParas`；`src=managed-176`；`resolve=ok ∧ h0 与同 run 的 `+176` 同值`；`wrong-object`／`failfast`／`-100002`／`-10000` **各 0 次**；**≥2 独立样本一致**；**每条带纪律 30 三格 ＋ 探针闸状态**）；读数行逐字入册（`[FSPARALIST-FILL]`／`[FSPARALIST-CONSUME] i= h= resolve=… type=`）。

**(b) 🔴 新缺口「索引复用 ⇒ **静默错对象**」（`t158` 现取、未见既有件；队长采纳其处置建议）**：机制 —— 活槽判据 `IsHandle() = Obj != null && Index == 0`（`PtsContext.cs:645-648`）；而 `ReleaseHandle:212-214` 把索引**压回自由链**、`CreateHandle` **复用之** ⇒ **已释放但尚未被复用**时 `:248` 的 Assert（`FailFast`）**拦得住**；**已被复用**时 `IsHandle()` 为**真** ⇒ `HandleToObject` 返回**另一个对象**、且 `as BaseParaClient` **成功** ⇒ **不报错、不崩、拿错对象继续排版**。⇒ 这是 **P4（use-after-recycle）** 的机制依据。⇒ **裁定采纳判据件的建议**：**`resolve=wrong-object` 单列为一票红**；**消费者行必须打印「身份 ＋ resolve 类别」**（不许只打"非零/成功"）。

**(c) 立一条方法论口径（本条的价值超出本跳）**：该缺口的形态是「**拦得住一半**」—— 同一个断言，在**未被复用**时红、在**已被复用**时**静默放行**。⇒ **口径**：**凡"能拦"的断言（Assert／校验／身份检查），必须同时回答"它在什么条件下拦不住"**；只写"它能拦"＝**记了一半**。⇒ 同族（本会话已 3 例）：`t136` 的「必需非充分」（要件成立 ≠ 结论成立）、`t145` 的「登记即算」（有登记 ≠ 有支撑）、本条（**断言在场 ≠ 断言有效**）。

**(d) 禁用件清单入册（判据件重申，队长照准）**：**`+200`**（不读字段的 stub ⇒ 恒定绿 ⇒ 用它判接受＝假绿）／**`+56`**（by-design 恒绿 ⇒ 对"能否拿到活句柄"零信息量）／**`fsbbox`／`dvrTopSpace`**（真排版前一律 `NOINFO`）／**今日已满足的网症格与死锚**。⇒ 另记 `FSPARADESCRIPTION.pfsparaclient` 的计算偏移 `+16`（`fsupdinf 8B` ＋ `pfspara 8B`）**只许实测**（计算值仅作预期），实测后须 `_Static_assert` 钉死（照 `t127` 前例）。

**(e) 下一跳实现已派 `t160`（`runner`）**：把 `pfsparaclient` 接进 `FsQueryTrackParaList` 的段落列表 —— 判据（7 条合取 ＋ `resolve=wrong-object` 一票红 ＋ 两腿窗实验 ＋ R-1~R-4 回收判据 ＋ 红榜 `P1–P10` ＋ T3 哨兵表 ＋ 零假值铁律）**全部照 `t158`**。🔴 口径照旧：本件绿**只准**读成「native 能把一个**由托管产出、且在持有期内有效**的段落客户端句柄交给列表消费者，且**消费者解析到的是同一个对象**」；**不得**读成"段落模型已成／排版打通／三级链已存在／两页能排版／`TASK-0007` 可绿"。

**裁定四十六（承 `t159` 回执，`ts=2026-09-29T18:2x+08:00`）—— (a) 两节入册；(b) 🔴 **裁 `arm_A` 三件：提交**（裁定六**部分修订**，依据新事实）；(c) 立一条口径「凡"不提交"类裁定必须带它是否被门禁读的现取判据」；(d) 记两条观察；(e) 记名一处严格性做法。原文与既有裁定一字未删（**修订只针对被门禁引用的那三件**）。**

**(a) `t159` 两节（逐件 sha16 我有现取对拍）**：
- **装置台账（"工具换代"机读行）**：runner 侧新增 `LEGS_TOOLS runner_sha16=… session_sha16=… guard_sha16=… mtime_max=<ISO> mtime_max_epoch=<epoch>`，位置＝`AUTHORITY:` 之后、**前置之前** ⇒ **拒跑趟也带**；会话侧新增 `SESSION_TOOLS …`（runner 经 `W67_RUNNER_SHA16` 下传，缺则 `none`）。口径＝取**当趟实际被执行的那份**。
  - **(a) 正极**：连续两趟该行**逐字节相同**；**(b) 🔴 因果对**：**改桩 ⇒ 同行 `session_sha16` 变**、**改 runner 副本 ⇒ `runner_sha16` 变**（其余不变）⇒ **"工具换代"被机器抓住**（这正是裁定四十三 (c) 采纳该建议时缺的那个读数）。
  - **(c) 既有列逐列计数改前/改后全相等**；`evidence/arm_A/leg_{23,24}.env` **逐字节相同** ⇒ 新行**不扰动转换器**。⇒ 与**代际指纹守卫**配对成立：**一个记"件换代"、一个记"工具换代"**，合起来才让"同批可比"**机器可核**。
- **`arm_A` 归属登记（取甲）**：**现取确认**——`build/close-wave.sh` 的输入表**逐字**列有 `evidence/arm_A/device.txt`（`:348`）／`leg_23.env`（`:349`）／`leg_24.env`（`:350`），逐件命中 `1`；`arm_A/app_g1.log` 命中 **0**；**与 `arm-logs` 不是同一面**（`P1-refreeze-report.md:21` 逐字 `ARMLOG_SHA=PASS shape=flat logdir=…/build/MilBridge/arm-logs`）。登记行已**只增不改**落到 `docs/ROUTES.md` §15af（四件路径＋mtime＋size＋sha16＋来源判定＋裁定六＋门禁读面逐字引用）。**具名 `NOINFO`**：**具体跑腿编号／写者判不出**（无 PID 血缘、件内无 `ts`）⇒ 只登记"同刻同形"，**不冒充归属**。

**(b) 🔴 裁定：`arm_A` 三件**提交**（依据新事实，**部分修订**裁定六）**。理由（我另做了现取复核，与它并行独立）：`close-wave.sh` 输入表在 `:348–:350` **逐字**引用那三件（**只列路径、不带 sha16**）；现取三件 `device.txt=6d2cf7572e7323b7`／`leg_23.env=285913567aad8516`／`leg_24.env=f89dac2796faa25d`（mtime 全 `2026-09-29 14:12:12`），`git check-ignore` **未被忽略**。⇒ **未跟踪 ＋ 被门禁输入表引用 ⇒ 别人 `clone` 后该输入面缺件、与现树不一致 ⇒ 整趟门禁必红（假红）**。⇒ 相比之下"留噪声"是**小害**、"别人 clone 后假红"是**大害**。⇒ 只提交**被引用那三件**（`app_g1.log` 命中 0 ⇒ **仍不提交**）；`arm_A/**` 的其余部分维持裁定六。**已由队长执行提交**（`25941dd`）。

**(c) 立一条口径**：**凡"不提交／允许未跟踪"类的裁定，必须带上"它是否被门禁或牙读"的现取判据**。理由是本次的教训：裁定六当年立"`arm_A/**` 未跟踪不提交"时**只看它是跑腿产物、没查门禁输入表**；而在"噪声"与"别人 clone 后假红"之间选错边，代价差得很远。⇒ 与本会话既有族（裁定三十七 (f) 的"自引入噪声"、`t134` 的 `src/tests/` 出仓）**同族，但判据不同**：**噪声看"谁在用"，未跟踪看"谁在读"**。

**(d) 两条观察入册**：① **仓外只复制 runner（不带伴生脚本）会让 `legs-to-env.py` 静默失败** —— 依据是它第一版夹具实测 `LEGS_TO_ENV_FAIL rc=2`，而**手工在仓根跑同一份则 `rc=0`**（成因现取：`TOENV="$SELF_DIR/legs-to-env.py"`，**无 env 旋钮**）⇒ **口径：夹具必须带 kit**（`t157` 的 `D-1` 修法方向「分配结果单向下传」同族的另一个面 —— 这里缺的是"**依赖也能被找到**"）。② 它自己的**仓外夹具**踩过一次 `DQ-BACKTICK`，而**仓内两件装置件命中 `0`**（改后现取）⇒ 说明"判词保真"纪律（裁定三十七 (a)(b)）**管住了仓内**，仓外仍要靠自觉。

**(e) 记名一处严格性做法**：它取"改前像"的办法**不是"另抄一份"**，而是**按已知行区间逐行删回并校验 sha16 ＝ `t157` 交件值**（`RECONSTRUCT=MATCH`：runner `e6eb370def6b4b8e`／session `390927970cd8839f`）⇒ 这避免了"抄错版本"这一整类混杂，**值得作为"取改前像"的通用做法记名**（与裁定三十七 (c) 的三条守恒证明同族）。

**裁定四十七（承 `t160` 回执，`ts=2026-09-29T18:3x+08:00`）—— (a) 段落列表接线七条合取全中；(b) 两腿实验如实（W-2 含 712 条 `-10000` ⇒ **不判绿**，它没缩窄判据）；(c) 🔴 **ABA 反腿的决定性证明**：**`rc` 无法区分对象身份** ⇒ **身份类判据不得依赖 `rc`**；(d) 🔴 **下一跳靶心 ＝ `FsQuerySubtrackDetails`**（本跳的绿**推进一格、暴露下一格**）；(e) 两条前置成立／四条不成立；(f) 认可其过程自陈。原文与既有裁定一字未删。**

**(a) `t160` 结论入册**：载体 `build/MilBridge/P1-paralist-wire-report.md`（**174 行**／末行自证 `b7ce3e86e3545091` MATCH；同代 `so16=ca97eacb8bb123f1`／`exports=651`、逐名**零消失**＋11 名）。
- **七条合取（W-1 两独立样本）**：L1 **1085/1085**、L2 **1113/1113** 填；全 `rc=0`、`cParas=1 n=1`、`src=managed-176`；`resolve=ok` **各 33**；**`wrong-object`／`failfast`／`rc=-10000`／`rc=-100002` 各 0**；`h0=0x5` ＝ 同 run `[DRIVE-PROBE3] keep=0x5 keeprc=0`（**同值**）；两样本判词与逐格值相同。
- **`+16` 三形态实测齐**（照裁定四十五 (d)「只许实测」）：**6 条 `_Static_assert`**（`pfsparaclient==16`／`pfspara==8`／`nmp==24`／`sizeof==64`／`FSUPDATEINFO==8`／`FSBBOX==20`）＋ **字节级读回**（`off16=16`、`+16..+23=h0`、`+24..+31=nmp=0x3`）＋ **消费者行为**（`ParaListFromTrack` 在 `rc=0` 后继续跑、按自己的布局读该区、零新异常类）。
- **回收 ＋ 反腿**：R-1 每 `h` 恰一次 `+192`（33 次全 `rc=0`）｜R-2 全在 context 在册期｜R-3 每代由本 run `+176` 现造、`h0`＝`keep`｜**R-4 ⇒ `NOINFO` ＋ 具名 `PRECOND-NO-HANDLE-ACCOUNTING`**（**不拿 `rc=0` 冒充回收正确** —— 判据 ③ 的要求守住了）。**`SELFRECYCLE` 反腿**（返回前回收）⇒ 消费者侧 `Unrecoverable system error.: Handle has been already released.` ×2、`failfast=1`、**`app_rc=134`** ⇒ **P4 现证必红**。

**(b) 两腿实验如实（它没缩窄判据 —— 这点我特别记名）**：**W-1 窗内**（`site=probe-in win=in`）⇒ **整体绿**；**W-2 窗外**（`site=probe-out win=out`、`h0=0x4`）⇒ 填充 403/403 **全绿**，**但该腿含 712 条 `rc=-10000`（`reason=no-out-of-window-client-yet`）⇒ 按判据第 5 条不判绿**。⇒ 两腿都跑到并被解析成功 ⇒ **「窗口无关」有据**；而"要它整体绿需先写死回退源或预热"这句它**写进了载体而不是当场放宽判据** ✓ 这正是本会话一贯要求的形态。

**(c) 🔴 ABA 反腿的决定性证明（本条是 `t158` 那个缺口的实证，价值最高）**：`resolve=wrong-object type=resolved-as-other-object via=aba-leg rc=0 released_between=1 stale=0x5 fresh=0x5 same_value=1 rc_release=0 rc_recreate=0` ⇒ **回收后重建、句柄值相同（`0x5`）、`+192` 仍返 0** ⇒ **`rc` 完全无法区分对象身份** ⇒ **一票红只能靠"来源证据"判**。⇒ 已落**独立计数口** `WpfLinuxWin32_PtsFsParaListResolveWrong`。⇒ **立口径**：**凡"身份"类判据（"是同一个对象""是哪一个对象"），一律不得依赖 `rc`／返回值形状，必须依赖可独立读取的身份证据**；并要求**身份证据与来源证据成对**（"它从哪来"＋"它现在是谁"）。⇒ 这条与裁定二十七（**字段级诚实性**）、裁定四十五 (c)（**"能拦"必须答"何时拦不住"**）构成同一族的第三条。

**(d) 🔴 下一跳靶心 ＝ `FsQuerySubtrackDetails`**：ENFE 计数 **1085／1113／403 条，全部同名 `FsQuerySubtrackDetails`**，且**与本腿的填充数逐值相等**。⇒ 含义：**本跳的绿把托管路径推进了一格，于是暴露了下一个缺失入口** —— 这是**真实增量**（不是"绿了却无事可做"）。⇒ 已派 `t161`（`scout`，**先判据**），并要求它照 `t129` 体例**先判「钥匙 vs 其后」**、把托管侧消费者位（`FlowDocumentPage.cs:547`／`ContainerParaClient.cs:289`）逐字引出。

**(e) 前置与 `NOINFO` 入册**：**成立**两条 —— `PRECOND-NO-MANAGED-SIDE-WRITER`（"同一对象"的**最终判据在托管消费者**，而 `.cs` 不在它写域 ⇒ **本跳只能证到"被接受 ＋ 身份与 `+176` 同值"**，口径照此收窄）、`PRECOND-NO-HANDLE-ACCOUNTING`（R-4）；**不成立**四条（带现取证据）。⇒ **口径照它写的**：绿**只准**读成「native 能把一个**由托管产出、持有期内有效**的段落客户端句柄交给列表的消费者，且消费者**解析到的是同一个对象**」；**不得**读成"段落模型已成／排版打通／三级链已存在／两页能排版／`TASK-0007` 可绿"。

**(f) 认可其过程自陈**：本件**先实现后落载体**（**偏离**"先落最小载体"这条派单硬约束），它**在载体 §11 如实记录**、且**判据一条没放松**。⇒ **裁定：不判 `needs_revision`** —— 理由：该约束的目的是"防止容量耗尽后无载体"，而**实际结果是没有无载体**；**如实记偏差 ＞ 假装没发生**，这条自陈本身是有价值的（与裁定三十七 (d) 的族同调：**记录比完美更重要**）。但**口径重申**：下次仍须**先落最小载体**。

**裁定四十八（承 `t161` 判据件，`ts=2026-09-29T18:4x+08:00`）—— (a) 三项判词入册；(b) 🔴 队长认账（第 13 次）：**哨兵口径被它更正**（数值也无判别力 ⇒ 「反常」必须由对照定义）；(c) 🔴 **`cParas=0` 是会改变控制流的语义断言** ⇒ **P8 恒绿陷阱**；(d) 已派 `t162`（`(a)`）＋ `t163`（`FSIMETHODS` 侦察）；(e) 一条保留。原文与既有裁定一字未删。**

**(a) `t161` 三项判词（`build/MilBridge/P1-subtrack-criteria.md` 326 行／full sha256 `01b00c39ad6f1e8494bac8295b6098c6d21f0f63d95e5daa31ef0bcf21024f67`／末行自证 `7dcd11d7f0afa065`）**：
1. **判「钥匙」（不是"其后"）**：八步链全现取 —— `PtsHelper.cs:179 paraClient.Arrange(arrayParaDesc[i].pfspara,…)` → `BaseParaClient.cs:65 _paraHandle=pfspara` → `FlowDocumentPage.cs:547`（`t160` 点位）→ `:549 GetTextContentRange()` → **`ContainerParaClient.cs:271 FsQuerySubtrackDetails`（该 body 里 Assert 之后**第一个实招**）** → `:278` 以 `cParas` 门控 → `:283 ParaListFromSubtrack` → `PtsHelper.cs:633 FsQuerySubtrackParaList` → `ContainerParaClient.cs:289`（`t160` 第二位）→ `:294` 递归。**三条独立指示**：控制流次序并门控 `:289`／`:271` 与 `:283` 是**成对入口**（与 `Pts.cs:3690-3700` 的 track 面对构，本格是**头**）／`t160` 的 ENFE 与填充数 **1:1**。
2. 🔴 **native 现状 ＝ 符号不存在**（`src/WpfGfx.Linux.Native/src/*.c` **0 命中**），**既非 `#if NEVER` 也非 stub** ⇒ 失败发生在**封送阶段**（ENFE），`PTS.Validate` **根本不执行** ⇒ **「`rc=-10000` 的缺席」与「ENFE 归零」都不构成任何证据**。⇒ **口径（重要）**：**`N2` 面（缺符号）≠ 内容面（行为对不对）** —— 符号补上只说明"能进去了"，**不说明进去以后对**。
3. **诚实边界判词：只靠上一跳的产出不够** ⇒ **真正下一跳是一对**：本入口实参只可能是 `_paraHandle`，其唯一来源是 `FSPARADESCRIPTION.pfspara`（链同上）；而**现取** `win32_pts.c:2957-2964` 的填充体 `memset` 后**只写 `pfsparaclient` 与 `nmp` ⇒ `pfspara` 恒 0**（与 `t160` §:90「`pfspara` 留 0」**同代互证**）⇒ **即使把符号补上，真腿收到的 `pSubTrack` 仍是 `NULL`，诚实实现只能拒绝**。⇒ `(a)` 让 `pfspara` 成为本侧**可认领的真对象**（台账／持有期／销毁口径）＋ `(b)` 本入口对 `(a)` 作答；其中 `cParas` 必须＝托管真值，**唯一诚实来源是回调面** —— 而**回调面已经在手**：`FSIMETHODS`（**17 槽**，`Pts.cs:1204-1223`）由托管在 `PtsCache.cs:600-603` 填好、经 `CreateInstalledObjectsInfo` 交给 native，native **现取原样存于 `win32_pts.c:469`（`t->subtrack_methods`，一个字节都不 deref）**。⚠️ 但表里**没有** "get para count" 槽 ⇒ **选槽本身是新设计缺口**（已写成合法终点 `PRECOND-NO-CPARAS-SOURCE`）。

**(b) 🔴 队长认账（第 13 次）：我给的那条哨兵口径被它更正，而且它是对的**。我在派单里写的红榜口径含「**值命中 `0x1..0x5` 即作废**」（意图是"防伪值"）。它**另证数值也无判别力**：句柄**就是托管表下标**（`PtsCache.Linux.cs:523 InitGenericInfo(ptsHost, (IntPtr)(index+1),…)`），且 `PtsHost.cs:414/:596` 证明该族"名"参数**就是托管句柄** ⇒ **小整数 `0x1..0x5` 是"真值形态"，不是可疑特征**。⇒ 正确口径 ＝ **「与**同 run** 产出行同值对上」**（`[DRIVE-PROBE3] keep=`／`[FSPARALIST-FILL] h0=`）。⇒ **立口径**：**"反常"必须由对照（同 run 的产出行）定义，不能由"看起来奇怪"定义**。⇒ 这与 `t142` 的「`LightGray` 是**死锚**（空态帧里已有 44/51 px，**只有量才知道**）」**同族**：**凭直觉设的特征值往往是真值形态**；而我的错法比它更糟 —— 我把它写成了**判废条件**（会让真值被判作废 ⇒ **假红**）。⇒ 我此前已立「假绿须双向」（裁定三十九 (b)），本条是**假红**方向的同族实例：**判据写错方向，一样是判据不诚实**。

**(c) 🔴 `cParas=0` 不是安全缺省，而是会改变控制流的语义断言（立为 P8 恒绿陷阱）**：`t161` 现取 `ContainerParaClient.cs:278 if (cParas==0 || (_isFirstChunk && _isLastChunk))` ⇒ **返回 0 会走叶子分支、不再递归** ⇒ **能让 `rc=0` 好看却静默丢掉整棵嵌套内容**。⇒ 本会话真腿**已证存在嵌套关系** ⇒ **`cParas=0` 直接判红**（不许当"没数据"）。⇒ **立口径**：**凡"缺省值"会改变控制流，它就不是缺省，而是断言** —— 这类"看起来安全"的缺省正是假绿的常见来源（同族：`t145` 的「登记即算」、`t136` 的「必要非充分」）。⇒ 已写进 `t162` 的反腿要求：**`pfspara` 的"非零"不等于"可用"**。

**(d) 已派两件**：`t162`（`runner`，做 `(a)`：`pfspara` 可认领真对象 —— 台账／持有期／销毁口径／不许自造／P8 必红／并要求**回归** `t160` 的七条合取与 6 条 `_Static_assert`）；`t163`（`scout`，`FSIMETHODS` **17 槽逐槽可用性侦察**，为 `cParas` 找源，**判不出即落 `PRECOND-NO-CPARAS-SOURCE`**）。

**(e) 一条保留（防后人误读）**：`FSIMETHODS` 那张表 native **只存不 deref** ⇒ 这是「**未使用**」，**不是**「不可用」（与裁定四十三 (e)「不得把'打不出来'当'通路不存在'」同族）。

**裁定四十九（承 `t163` 侦察，`ts=2026-09-29T18:5x+08:00`）—— (a) 三条判词入册，其中第②条**修正了 `t161` 的核心结论**；(b) 🔴 立红榜 **P9「把"回调面没源"偷换成"没有源"从而提前收工」**；(c) **下一跳改判**到引擎侧子轨造型入口（**一个入口兼解 `t161` 的 (a)(b)**）；(d) 三处表层陷阱 ＋ 一条"伪指针"入册；(e) 记名一次**在飞碰撞的自我披露**。原文与既有裁定一字未删（**对 `t161` 的修正是"射程更正"，不是判它错**）。**

**(a) `t163` 三条判词（`build/MilBridge/P1-fsimethods-recon.md` 238 行／full sha256 `c26b675ecc5d05a47c3852da3f7d99e3e81259ebb9d97bcd3c1bec357bbca0d2`／末行自证 `9105d8ff204e7b3b`）**：
1. **回调面确实无源**：`FSIMETHODS` 17 槽（定义 `Pts.cs:1204-1223`；装配位 `PtsCache.cs:603-619`；native `win32_pts.c:103/:484` **整表原样存、17 槽零调用**）里**没有一槽**能给"子轨数／段落数" —— 唯二的计数出参是 **12 槽 `nlines`**（**文本行数**，`:2804`）与 **13 槽 `nftn`**（**脚注数**，`:2810`），**量种不同** ⇒ 拿去当 `cParas` 就是**捏造**（`PtsHelper.cs:636` 的 `Assert(cParas == paraCount)` **会当场炸**）。
2. 🔴 **但诚实源在引擎侧（本件最有价值的修正）**：**`cParas` 不需要任何回调槽**。`FSPARADESCRIPTION.pfspara` **语义上就是子轨对象** —— `FsFormatSubtrackFinite` 的该出参在声明里名字叫 **`ppfsSubtrack`**（`Pts.cs:3318`／`:3337` 注释原文「ptr to the subtrack」），由**宿主槽 3（`ObjFormatParaFinite`）**的回调链填写（`ContainerParagraph.cs:526` `…, out fsfmtr, out pfspara, …`），而 `BaseParaClient.cs:65 _paraHandle = pfspara` ⇒ **`FsQuerySubtrackDetails(ctx, _paraHandle, …)` 的形参名 `pSubTrack` 是对的**。⇒ **「一次成功造型 ＝ 一个段落」⇒ 引擎数自己驱动的调用次数即得 `cParas`**。⇒ 这套形状**本仓已落地过**：`FsQueryTrackDetails` ＋ `wpf_pts_fsp.c_paras`（`:292` 字段注释「按对象给，非全局常量」／`:348` 记账／`:2697` **轨句柄＝本对象内该字段的地址**／`:2794` 指针值比较不 deref／`:2816-2817` 按对象答数／`:3286-3290` 反腿「改一个对象只有它变」）。
3. **对 `t161` 的射程更正**：`t161` 写的「`cParas` 的**唯一**诚实来源是回调面」应**修正**为「**回调面无源**（该判定成立）＋ **诚实源在引擎侧**（该路径存在）」⇒ **`PRECOND-NO-CPARAS-SOURCE` 不成立**，只保留为**局部结论**；**严禁**拿它宣称"`cParas` 做不到"。⇒ **真正的阻塞**是：托管侧子轨引擎面 **16 条 `Fs*Subtrack*` 一条都没实现**（含 `FsFormatSubtrackFinite`／`Bottomless`、`FsQuerySubtrackDetails`、`FsQuerySubtrackParaList` 等），而 native **真实现**的 `Fs*` 只有 **6 条**（`:318/:2679/:2714/:2806/:2840/:2894`）。

**(b) 🔴 立红榜 `P9`（判据不诚实的新形态，本条最通用）**：**把"回调面没源"偷换成"没有源"从而提前收工**。⇒ 形态：把**一个局部否定**当成**全局否定** —— 在一面（回调面）查无所得，就断言"这件事做不到"，于是**不必再查第二面**（引擎侧）**就合法收工**。⇒ **口径**：**凡否定性结论（"无源／不可达／做不到"），必须写明它的射程 —— 是"哪一面没源"还是"没有源"**；射程未写明的否定结论**不得**作为排期依据。⇒ 同族（本会话已 4 例）：裁定三十八（**单样本当机制**：一次观测当机制）、四十 (a)（**跨代拼表**：两个世界平均成一个）、四十六 (c)（**不提交类裁定须带"谁在读"的判据**）、本条（**局部否定当全局否定**）。⇒ 四例的共同形态：**结论的射程没写清，于是它被用在射程之外**。

**(c) 下一跳改判（靶心 ＝ 引擎侧子轨造型入口）**：`FsFormatSubtrackFinite`／`Bottomless` **一个入口同时解 `t161` 的 `(a)` 与 `(b)`** —— 它既是 **`pfspara` 的产生处**（(a)），又是 **`cParas` 的记账点**（(b)）。⇒ 它给的**最小可证伪三步**（已转给 `t162` 执行）：
- **E1（先测后用）**：native 侧加 `FSIMETHODS` **镜像 ＋ `_Static_assert`**（照 `win32_pts.c:933-938` 体例）**实测槽序偏移** —— 🔴 **槽序今天只能按托管声明推断 ⇒ 具名 `NOINFO-FSIMETHODS-ABI`，先测后用**（与 `t132`「候选只能算、禁当结论」同族）。
- **E2**：驱动一次**槽 3**，**先把 out 参数投毒**，断言 `rc=0` ＋ `pfspara` **被改写** ＋ **身份可认领**（指针 ＝ **本侧对象字段地址**）＋ **只增一条**。
- **E3**：反腿一对 —— **`NULL`** 与**栈地址"看似真实则伪"**均须**被拒且留痕**。

**(d) 三处表层陷阱 ＋ 一条"伪指针"（入册，防后人重踩）**：**14 槽自陈未实现**（`:2933 Debug.Fail`／`:2935 fserrNotImplemented`）／**15 槽空装配且两表不对称**（`PtsCache.cs:617 = IntPtr.Zero`，而 subpage 表 `:622-637` **没有该行** ⇒ **不能用"槽指针是否为 0"判有无实现**）／**16 槽是恒绿桩**（`:2943 Debug.Assert(false)` ＋ `:2944` 空 FSBBOX ＋ `:2945 return PTS.fserrNone` ⇒ 与 `+200`／`+56` **同族，禁用**）。⇒ 另：**`pfssobjc` 是伪指针**（`PtsHost.cs:93 _objectContextOffset = 10`、`:2652`、subpage `:2967 +11`，注释自陈「not really created by our PTS host」）⇒ **不可作身份键**（**由 `idobj` 导出、可碰撞**）—— 这与裁定四十七 (c)「身份类判据不得依赖 `rc`」合起来构成"**身份判据的三条禁令**"：**不靠 `rc`、不靠数值形态、不靠可碰撞的伪指针**。⇒ 并记：**"`subtrack_methods` 非空"不能当"回调面可用"**（**存下 ≠ 能用**）。

**(e) 记名一次「在飞碰撞的自我披露」**：`t163` 侦察期间 `win32_pts.c` 被 `t162` 改动（它 18:14:27 读 `c90a78af8bc9499c`，18:15:33 已是 `58c7725b32598728`，mtime 18:15:26）⇒ 它**逐条带代际、并声明"行号只在该代有效"**，且**主动指出**新代 `:3017 rg[i].pfspara = (void *)para_val;` 意味着「`t161` §4(a) 正在被别人做」⇒ **请队长计入排期，避免两人做同一格**。⇒ **这正是我要的形态**：在飞碰撞**自己披露**而不是等队长发现（与裁定四十四 (d) 的"腿时间重叠"同族）；本条已据此把 `t162` 的靶心对准**引擎侧产物来源**（见 (c)），**不是**另开一件重做。

**(f) 过程自陈（记名）**：它初稿有 **4 处行号/代际错误**（`PtsHost.cs` 两处 `HandleToObject` `:2701/:2703` → `:2695/:2697`；14 槽 stub `:2931-2932` → `:2933/:2935`；16 槽 return `:2946` → `:2945`；`SubtrackDestroyContext` `:2655` → `:2654`；`_Static_assert` 块旧代 `:905-920` → 新代 `:933-938`），**全部按现取自行更正**。⇒ 与裁定四十七 (f) 同调：**如实记偏差 ＞ 假装没发生**。

**裁定五十（承 `t162` 回执，`ts=2026-09-29T19:0x+08:00`）—— (a) `(a)` 落地且 `t160` 回归未退化；(b) E1 落地形态正确（**把"没驱动"如实印出来**）；(c) 🔴 **E2 打不出来** ⇒ `PRECOND-NO-ENGINE-FORMAT-FRAME` ⇒ 已派轻量侦察 `t164`；(d) 🔴 采纳其纪律「**判别器必须与被判别物的族匹配**」；(e) 🔴 其第二条自陈升为口径「**未定的归因不得被当成"已排除该原因"**」；(f) 记名它本轮做到了"先落最小载体"。原文与既有裁定一字未删。**

**(a) `t162` 的 `(a)` 落地（载体 `build/MilBridge/P1-pfspara-report.md` 155 行／末行自证 `e311486fee8fdb2e`；同代 `so16=291ef08a33f9b6e4`／`exports=665`、逐名**零消失**＋14 名）**：`pfspara` **不再复用 `nmp` 占位**，改为**本侧自有子轨对象**（句柄 ＝ **本对象内字段地址** —— 承本仓 `FsQueryTrackDetails` 范式）：
- **台账**（`seq`／`live`／`created`／`destroyed` ＋ 6 个读数口）｜**持有期**（跨调用复用，现取 `reused=685／703`，填报后不销毁）｜**销毁口径**（唯一销毁点接在 `DestroyDocContext`；**自检直接读数** `[FSPARALIST-SUB-SELFTEST] mask=0x1f`：`new_claimable`／`null_rejected`／`stack_rejected`／`destroyed_unclaimable`／`live_restored` **全 1**）｜**身份可认领** ＝ 指针等值于某**在册**对象的字段地址（判据 §5.4 落成**可判**形态）。
- **成对证据**：`pre=(nil)` → `psub=非零`（两个不同值）；`same_value=1`、`off_pfspara=8`；**字节读回** `+8..+15` ＝ 该地址、`+16=0x5`、`+24=0x3`。⇒ **下游接受 ＝ `NOINFO(acceptor-is-(b))`**，现取 `acc=-12345`（**未调用，不冒充**）—— 这条自限正确（接受者在 `(b)`）。
- **`t160` 回归（两样本、同代）：未退化** —— `fill=1100／1123`、`consume=33／34` 全 `resolve=ok`、`entry=FsQueryTrackParaList` 的 `rc=-10000`／`rc=-100002` **各 0**、`h0==keep==0x5`、`off16=16`、症状门 `alive=yes app_rc=143 magenta=0 failfast=0 unrec=0`；**`t160` 的 6 条断言原样在册**。
- **`P8`（`cParas=0` 恒绿陷阱）已落**：接口面**逐趟打 `formatted=0`**（**明告 `(b)` 不得据 `cParas==0` 走叶子分支**）；**两条副本反腿都红** —— `MADEUP`（`psub=(nil)`）与 `WRONGTYPE`（`psub=<栈地址>`）均 `claim=0`、逐字 `v=CLAIM-REJECTED`、**无任何 FILL 行**。

**(b) E1 的落地形态正确（值得记名）**：`FSIMETHODS` 17 槽**镜像 ＋ 4 条断言**（`sizeof==17×8`／槽1@0／**槽3@16**／槽13@96／槽17@128）；现取 `[FSPARALIST-SLOT3] methods=… present=1 slot3_offset=16 **drive=SKIP** reason=need-real-format-frame(…) **abi=NOINFO-FSIMETHODS-ABI deref=none**`。⇒ **它把"没有驱动"与"ABI 未定"都如实印在读数里**，没有假装驱动过 —— 这正是"**先测后用**"应有的形态（与 `t132`「候选只能算、禁当结论」同族）。

**(c) 🔴 E2 打不出来（如实具名，不硬做）**：**本侧没有真造型帧** —— `pfssobjc` 已被 `t163` 判为**伪指针**、`pfsgeom`／`pfsbrkrec` **本侧都没有**；要驱动就得**自造输入**，而那是判据 §7.3 **零假值明禁**的 ⇒ 具名 **`NOINFO ＋ PRECOND-NO-ENGINE-FORMAT-FRAME`**。⇒ **已派 `t164`（`scout`）做它建议的轻量侦察**：「真造型帧（geometry／break record／object context）**在本波能否合法获得**」；**得** ⇒ 接 E2；**不得** ⇒ 把 `(b)` 的 `cParas` 源**改判**。⇒ 并已在派单里写死：**不许**为了"看起来有下一步"而把"自造输入"包装成合法路径；且**不得**把"`pfssobjc` 是伪指针"推广成"所有 object context 都不可用"（红榜 `P9`）。

**(d) 🔴 采纳它建议的纪律：「判别器必须与被判别物的族匹配」**：它**如实自陈**曾拿 `+168 GetParaProperties` 当 `pfspara` 的接受者 —— 而 `+168` 吃的是**托管句柄**、它给的是 **native 指针** ⇒ 撞 `HandleToObject` 的 Assert ⇒ **`Unrecoverable system error.: Invalid object handle.` ＋ `app_rc=134`**，并指出「**正是 §7.3／P7 要拦的形态**」。⇒ **立为纪律**：**判别器必须与"被判别物的族"匹配** —— 族按 `t163` 的现取分类为 **`H` 托管句柄／`E` 引擎自有对象／`P` 伪指针／`S` 结构指针／`I` 整数**；**跨族判别必撞 Assert**。⇒ 同族（本会话）：`t156` 的 **`+200` 恒定绿陷阱**（不读字段的 stub）／`t161` 的「**数值无判别力**」／本条（**族不匹配**）—— 三者共同形态：**判别器看起来能判，其实判的不是那件事**。

**(e) 🔴 其第二条自陈升为口径（本条最通用）**：两条反腿在给出预期 `CLAIM-REJECTED` **之后**另有**同一条** `FailFast`（managed 栈顶 `PtsHelper.ArrangeParaList → PtsContext.HandleToObject`，`app_rc=134`），而该腿**同时** `[FS_PAGE_GAP]=0` 与 `[FSPARALIST-FILL]=0` ⇒ **它未能把这条 `FailFast` 与"拒填"路径严格分开** ⇒ 归因记 **`NOINFO(未定)`**、主链两样本未受影响、列 finding，**并明确写死「解释前『本入口已可安全拒填』不得入册」**。⇒ **立口径**：**归因未定 ⇒ 结论必须降级；不得把"未定"当成"已排除该原因"**（例如"没看到它导致 FILL"不等于"它不是 FILL 的原因"）。⇒ 这是「**不可归因须双向**」（裁定三十九 (b)）的**第三条**：第一条治**标绿不标红**、第二条治**只标红不标绿**、本条治**把"未定"读成"无"**。

**(f) 记名**：它本轮**做到"先落最小载体再实现"**（先落 51 行、预登记 D1–D6、自证 `8cee877d6ba4ef53`，再原地追加）⇒ 上轮那次偏离（裁定四十七 (f)）**已纠正**。⇒ 与 (b)(c)(e) 合起来看：**这一件的形态正是本会话一直在要求的** —— 能做的做扎实、做不到的具名、做错的自陈、没驱动的如实印。

**裁定五十一（承 `t164` 侦察，`ts=2026-09-29T18:4x+08:00`）—— (a) 三条准入路径入册；(b) 🔴 新立**族级铁律**「准入 ＝ 本侧是该值的作者」；(c) 🔴 **裁「副本驱动 ＝ 合法」**（四条前置全落）＋ `PRECOND-NO-ENGINE-FORMAT-FRAME` **改判**为 `PRECOND-NO-ENGINE-DRIVER`；(d) 记一条**新格子**（断页记录的**内容诚实性**）；(e) 记它**守住红线**与**纠正我的跨代读数**。原文与既有裁定一字未删。**

**(a) 三条准入路径（`t164` 现取；件 `build/MilBridge/P1-format-frame-recon.md` 241 行／末行自证 `9440f52aaecb1304`；开工与收尾两次现取 `win32_pts.c` 均 `6ac4272b031edbbc` ⇒ 引用未跳代）**：**总判词 ＝「得」**（三条都有），**但"得"不是瓶颈 —— 真正缺的是「驱动者」**。
- **`pfsgeom`**：它是**宿主回调的 IN 参数**（`Pts.cs:2716`／`:2741`／`:2763`／`:2782`；`PtsHost.cs:2670` 等）⇒ **由调用者＝引擎填 ⇒ 引擎就是作者**；托管侧只做中转、**从不解引用**（`PtsHost.cs:2705` → `ContainerParagraph.cs:789` → 原样交回**引擎自己的** `FsFormatSubtrackFinite`，`Pts.cs:3318`）。⚠️ 仓内 `FSGEOMETRY` **0 命中** ⇒ 形状**只能自定**（具名 `NOINFO-FSGEOMETRY-LAYOUT`）；native 全代只有 `:1318` 一条诊断串提到它。⇒ **得（有条件：须声明作者性）**。
- **断页记录（三级）**：**页级本侧已产出** —— `win32_pts.c:3058 *ppfsBRPageOut = (void *)&p->c_paras;`（**本对象内字段地址、可身份认领**；失败先清空 `:3037`；入参 `Pts.cs:3112`／出参 `:3116`）；**段落级 `pfsobjbrk` 契约允许 `NULL`**（`Pts.cs:2711` 原文「use if !NULL」）；**subtrack 级** `:3320`／`:3337`。⇒ **得**，且**第一调可用 `NULL`** —— 🔴 **NULL 是契约取值，不是伪造**（这条必须写进判据，免得把合法 `NULL` 当"缺件"）。
- **`pfssobjc`**：**唯一**产生处 ＝ **`FSIMETHODS` 槽 1**（`Pts.cs:2699`；`PtsHost.cs:2644-2654` 只算 `idobj+10`、**入参一个都不读**）⇒ **引擎调槽 1 即合法获得**（`idobj`／`ffi` 由引擎自选）。⇒ **红线守住**：它**没有**把裁定四十九里的「`pfssobjc` 是伪指针」推广成「所有 object context 不可用」（红榜 `P9`）—— 该判定讲的是"**不由本侧分配、语义不透明**"，而 `PtsHost.cs:91-93` 自陈「not really created by our PTS host, it is good enough for now」是**宿主的契约设计**。⇒ **这条遵守得干净，记名**。

**(b) 🔴 新立族级铁律（本会话第 5 条；前四条：判词保真／未触达的绿不是绿／不可归因须双向／多趟采样件逐趟记代际）**：

> **准入 ＝ 本侧是该值的作者**：一个值可以进入读数与判据，**当且仅当**本侧（native）**是该值的作者** —— 即它由本侧作为"引擎"产生（自有对象／本对象内字段地址／本侧驱动的调用计数）。**引擎自己的**矩形／几何／格式化标志／`idobj`／页对象／断页记录 ⇒ **合法**；**声称外部对象存在**、或**把别的量的数**（`nlines`／`nftn`）当本条的 ⇒ **伪造**。

⇒ 这条把 `t161`／`t162` 的"零假值铁律"**从"不许造假值"精确化为"作者性"**：问题的关键**不是值的来源看起来像不像**，而是**本侧有没有资格声称它是它**。⇒ 与 (a) 的三条路径正好构成一个可判分的三分：**引擎作者（合法）／契约 NULL（合法）／别的量的数（伪造）**。

**(c) 🔴 队长裁定：「副本驱动 ＝ 合法」**（`t164` 请我裁的那一处）。**依据**：① 本会话 **T3 反腿**（`t148`／`t156`）与 **`SELFRECYCLE` 反腿**（`t160`）**都是在副本上跑**的；② 判据 §7.3 禁的是"**把伪造当真实**"，**不是**"不许在副本上做实验" —— 副本读数**明确标注"副本专用"即不产出假读数**；③ `t164` 自己已给出**与既有先例同形**的形式（`#if WPF_PTS_FSP_PL_SELFRECYCLE`，**绝不进主链产物**）。⇒ **批准**，但要求**四条前置全落**（见 `t165` 派单）：① **副本专用、绝不进主链产物**（给"主链 `.so` 逐名不变／症状门逐格不变"的成对证据）；② **作者性逐项声明**（`pfsgeom`／`fsrcToFill`／`ffi`／`idobj`／`fswdir`／`fEmptyOk`／`fSuppressTopSpace`／`fskclearIn` —— **不能声明作者性的不许用**）；③ **投毒 ＋ 四条断言**（`cParas` 语义**现取判定**，按 `t154` 教训不沿用前跳）；④ **反腿一对**（`NULL`／栈地址"看似真实则伪"均须被拒且留痕）。
⇒ **同时改判前置**：`PRECOND-NO-ENGINE-FORMAT-FRAME` 的**现状句成立**（本侧确无真造型帧实物），但其**推论句「要驱动就得自造输入 ⇒ 违反零假值」不成立**（三样都有合法路径）⇒ 改判为 **`PRECOND-NO-ENGINE-DRIVER`**：现取 6 条真实现（`:324`／`:3031`／`:2679`／`:2714`／`:2806`／`:2894`）里**没有任何造型驱动入口**，**主链上没有调用者会走进槽 3**。⇒ 这是"**改判而非硬做**"的又一实例（与裁定四十九 (a) 的"射程更正"同族）。

**(d) 一条新格子（`t164` 主动提出的观察）**：本侧**页级断页记录目前是"字段地址别名"**（`&p->c_paras`），**不承载"断页状态"内容** ⇒ 一旦要驱动真造型，**断页记录的"内容诚实性"就成为新格子**：**"地址非零"不得冒充"内容正确"**。⇒ 已写进 `t165` 的要求（**如实记它今天是什么**）。⇒ 这与 `t129` 的「`FsQueryTrackParaList` 结构性上界」同族：**入口存在 ≠ 内容正确**。

**(e) 两处记名**：① **它守住了红线**（不把局部否定推广成全局否定 —— 红榜 `P9` 立竿见影）；② **它纠正了我的一处跨代读数**：我在 `t164` 派单里引的「`[GEO]` 927 行」是**另一代/另一腿**的读数（它现取 `evidence/arm_A/app_g1.log` 的 `[GEO]` 为 **1012 行**、文件 1285 行），它明确标注「**引自任务书，本席未独立复算**」并**不做跨代比较**（具名 `GEO-LINE-COUNT`）⇒ **处理得当**；顺带它判明 `[GEO]` 面是**应用侧 UI 自动化面**（只含 XAML 元素的 `scr/wh/en/vis/htv`、**无任何 PTS/线服务对象**）⇒ **不能当造型帧入口**（这是**有用的否定**：省掉了后人再试一遍）。

**裁定五十二（承 `t165` 回执，`ts=2026-09-29T19:2x+08:00`）—— (a) 四条前置全落（副本专用做到**逐字节不变**）；(b) `PRECOND-NO-ENGINE-DRIVER` **成立**并加强为两条现取；(c) 🔴 新立口径「**数据可值化、可调用体不可**」；(d) 🔴 其两处自伤升为 **红榜 `P10`**「**下负面结论前必须先证明被检物送到了检查点**」；(e)(f) 两处记名。原文与既有裁定一字未删。**

**(a) `t165` 四条前置全落（载体 `build/MilBridge/P1-engine-drive-report.md` 157 行／末行自证 `091ef2cb3d5bc35f`；`REPORTID=PASS files=284`）**：
- **① 副本专用做到了最强形态**：**主链 `.so` 重建前后逐字节不变**（`pre=post=291ef08a33f9b6e4`、**`MAIN_BYTE_IDENTICAL=yes`**）、`exports.txt` 665 行不变、`^Fs=6` 不变；主链回归腿 `LEGS_RUNNER=PASS obtained=2 refused=0`、`fill=1117`、**`[FSPARALIST-EDRIVE]` 行 ＝ 0**、`failfast=0`、症状门全绿 ⇒ **驱动格全部在 `#if WPF_PTS_FSP_PL_ENGINE_DRIVE` 内、缺省 0**。⇒ **这比我在派单里要的"`nm` 逐名不变"更强**（那是"导出面"层，这是"字节"层）⇒ **升为后续"副本专用"的默认要求**。
- **② 作者性逐项表（跑前写死 ＋ 实际用值对照）**：`idobj`／`ffi`／自定 `geom`／`fsrcToFill`／`fswdir`／`fEmptyOk`／`fSuppressTopSpace`／`fskclearIn`／`iArea`／`fBreakInside` 逐项 **`I`／`E`（本侧即作者，依据页几何 768×576）**；`nmp`／`pfsparaclient` **`H`**（本 run 托管产出 `0x3`／`0x5`，族检查**通过**）；**`pfsobjbrk=NULL` ＝ 契约取值**（`Pts.cs:2711`）；**不能完全声明作者性的（`pfscbkobj`／`pfsgeom`／`pftnrej`）只做实验**（具名两个 `NOINFO`）。⇒ 这正是裁定五十一 (b) 那条铁律的**逐项落地**。
- **③ 投毒 ＋ 四断言**：投毒在册（`pfssobjc`／`pfspara=0xA5A5…`、`fsbbox` 全 `0xA5`、`fsfmtr`／`dvrUsed`／`dvrTopSpace`／`breakpos=-0x5A5A`）；**A–D 全记 `NOINFO`** —— 驱动格**通过族检查并发出调用**（逐字 `where=FsCreatePageBottomless methods=0x7ffd… fam_nmp=H fam_client=H`）后 **`SIGSEGV`**（`app_rc=139`、`edrive=1`、`fill=0`）⇒ **调用未返回**。⇒ **它把"发出去了但没返回"与"没发出去"分得清清楚楚**（这正是本条 (d) 的口径）。
- **④ 断页记录内容诚实性（裁定五十一 (d) 的那个新格子）**：**别名**（`&p->c_paras`）、**不承载断页状态内容**；逐趟打 **`brk_content=alias(not content)`** ⇒ **没有让"地址非零"冒充"内容正确"** ✓
- **⑤ 反腿一对（＋族匹配）**：① `NULL` ⇒ `FAMILY-REFUSED reason=nmp-not-H (nil)(fam=N) client=0x5(fam=H) calls=0`；② **栈地址** ⇒ `nmp=0x77069e7d3740(fam=X) client=0x5(fam=H) calls=0` ⇒ **两腿都拒发且留痕**、`app_rc=143` 未崩。⇒ 族定义 `H/E/P/S/I/N` 与"**先分类再喂、非 `H` 一律拒**"在册 —— 这是裁定五十 (d)「判别器须与族匹配」的**正向落地**。

**(b) `PRECOND-NO-ENGINE-DRIVER` 成立，并被它加强为两条现取（排期依据）**：
1. 🔴 **`FSIMETHODS` 槽表只能"原样存、不许 deref"** —— 在**副本**上把表里槽 1 的指针**当本地函数指针调用**，进程即在**首个回调处 `SIGSEGV`**（`app_rc=139`）。⇒ **这不是"帧"的问题，是"表的合法可得形态"问题**。
2. **引擎侧真正的造型驱动入口在本波不存在**（native 6 条真实现里没有会调槽 3 的路径）。
⇒ 要真做 E2，须先有**「表的合法可得形态」**（与 `fscbk` 同形的**值拷贝快照**通道，**或**托管侧把槽指针以**可调用句柄**形式下发）**或**引擎侧驱动入口 —— **两条都是新前置** ⇒ 已派 `t166`（`scout`）做**轻量侦察**：「`FSIMETHODS` 合法可得形态可行性」，并要求它**分开两个成因**（**槽序错位** vs **不可调用**）—— 因为 `t163` 已给具名 `NOINFO-FSIMETHODS-ABI`，**不能把"喂错了"读成"不可用"**。

**(c) 🔴 新立口径（本条价值超出本跳）：`fscbk` 的方子不能照搬 —— 「数据可值化，可调用体不可」**。`t141` 的 `PRECOND-FSCBK-SNAPSHOT-IN-DOC` 之所以成立，是因为 `fscbk` 是**数据**（**值拷贝 103 字**即可持有，`equal=103/103` 已证）；而 `FSIMETHODS` 是**函数指针表** ⇒ **"值拷贝"能不能让它可以被调用，是另一件事**（`t165` 的 `SIGSEGV` 正是这条边界的一次实测）。⇒ **口径**：**跨调用持有的对象分两类 —— 数据（值化即可）与可调用体（值化 ≠ 可调用）**；后者**必须**先判"它的**合法可得形态**是什么"（快照？句柄？原表 pointer 是否本来就是可调用的？），**不得**沿用数据类的方子。⇒ 这与 `t146` 的「`+80` 是懒创建（有副作用）」同族：**"能持有"不等于"能安全使用"**。

**(d) 🔴 其两处自伤升为红榜 `P10`（它自己给的教训，我认为值得单列）**：它的**客户端来源首版取 `fsp_pl_cur`**（探针时刻未赋值 ⇒ 三腿被 `client-not-H` 拒）、**族集合首版漏 `fsp_pl_src_in/out`**（`keep=0x5` 被误判族 `X`）⇒ **两条误判本身也是真读数，但它们一度让"驱动未发出"看起来像"驱动不可行"**。⇒ **立红榜 `P10`**：**凡下负面结论（不可行／打不出来／做不到）的每一格，必须先证明"被检物真的被送到了检查点"** —— 本例的可判形态就是 **`calls=0` 与 `calls>0` 必须分开**（`calls=0` 只说明"没发出去"，**只有** `calls>0` 才谈得上"调用失败"）。⇒ 与红榜 `P9`（**局部否定当全局否定**）**同族但更深一层**：`P9` 是**射程没写清**，`P10` 是**连否定的前提都没达成**。

**(e) 记名**：它本轮**做到"先落最小载体"**（53 行、自证 `d62136e510102617`，再实现）；**且它主动把两处自伤报出来**（不是被我查出来的）—— 这两处自伤如果没报，本件的结论会被读成"E2 不可行"，而实际是"**它那版分类写错、驱动没发出去**"。⇒ **如实报自伤，在这里直接改变了下游排期**（否则我会去改判 `(b)` 而不是去侦察"表的形态"）。

**(f) 一处口径落到实处**：`cParas` 的**现取判定** —— 本侧对象字段 ＋ 逐趟 `formatted=0` ⇒ **未造型占位，不得读成"0 个孩子"**。⇒ 裁定四十八 (c) 立的 **`P8` 恒绿陷阱**在此有了**正向执行**：**没有"0 个孩子"这个读数，只有"还没造型"**。

**裁定五十三（承 `t166` 侦察，`ts=2026-09-29T19:3x+08:00`）—— (a) 核心答案入册（**use-after-return**，本仓早已写成纪律）；(b) 🔴 **队长认账（第 14 次）：裁定五十二 (c) 的口径被推翻并收窄**；(c) 两成因分开（D1→D2→D3 顺序写死）；(d)(e)(f) 三处判定入册；(g)(h) 两类记名。原文与既有裁定一字未删（**修订只针对 (c) 那一句**）。**

**(a) `t166` 的核心答案（`build/MilBridge/P1-fsimethods-abi-recon.md` 208 行／full sha256 `62283f54aae6f9676498816bc3096b08ed635ae2ca875e9b429c38e6eb56f269`／末行自证 `35041d7b492824b0`；开工与收尾两次现取 `win32_pts.c` 均 `e41df5d4c77610ac` ⇒ 未跳代）**：
**`t165` 的 `SIGSEGV` 主因 ＝ 跨调用持有封送地址（use-after-return），且静态即可判** —— **存储窗 ＝ `CreateInstalledObjectsInfo`**（`win32_pts.c:478-499`，存储句 `:490`；托管在建池期调 `PtsCache.cs:433`→`:640`）；**使用窗 ＝ `wpf_pts_drive_probe`**（`:1397` 起、E2 驱动点 `:1653`），而该探针由 **`FsCreatePageBottomless:350`**／**`FsCreatePageFinite:3178`** 调用 ⇒ **两个不同的 P/Invoke**，中间隔着**建池 → 建 doc → 建页** ⇒ 解引用的是**早随那次调用结束的封送缓冲**（**读通常不崩，跳到垃圾地址就崩** —— 与 `t165` 的"`edrive=1`／`fill=0`／首个回调处崩／`app_rc=139`"形态一致）。⇒ 🔴 **本仓自己早已把这条写成纪律**：`win32_pts.c:120-131`（`t141` 块）原文「**为什么必须"值拷贝"而不能存指针** …① 入参是**托管对象字段的地址** … CLR **只保证封送期间该地址有效，返回后可能搬移** ⇒ 跨调用持有它就是 **use-after-return**」。⇒ 也就是说：**`t141` 立过的那条纪律，在 `FSIMETHODS` 上被 `t165` 用一次 `SIGSEGV` 又证了一遍**。

**(b) 🔴 队长认账（第 14 次）：裁定五十二 (c) 的口径被推翻并**收窄****。我当时立的是「**数据可值化，可调用体不可**」—— 从"`t165` 那一种用法崩了"归纳出"**可调用体不能值化**"。`t166` 现取证明这是**过度概括**：`FSIMETHODS` **就是可调用体**（`subtrack_methods` ＝ 封送期内的 **17×8 B 可调用函数指针数组之基址**），而**在窗内值化完全可行**；`FSCBK` 与 `FSIMETHODS` 的**唯一差异**（`FSCBK` 是 `FSCONTEXTINFO` 的**结构成员**〔`Pts.cs:842`，`+40`〕vs `FSIMETHODS` 是**独立 `ref` 形参**〔`Pts.cs:3079`〕）**不改变封送机制** ⇒ **"照 `fscbk` 的方子办"成立**（`wpf_pts_fscbk_snapshot:655` 内 `:667 memcpy(…, info+40, 824)`，由 `:1712`（在 `CreateDocContext:1689` 内）触发，此后**只读自己的副本**）。⇒ **正确口径**：**问题不在"数据 vs 可调用体"，而在"是否在窗内值化"** —— **凡跨调用持有的东西（数据或可调用体），都必须"在它自己的窗内值化"**。⇒ 🔴 **而我的错法恰恰是我自己刚立的两条红榜的形态**：**`P9`（局部否定当全局否定）** —— 一次读数的崩溃被我推广成"可调用体不可值化"；**`P10`（下负面结论前没确证"被检物真的被送到了检查点"）** —— `t165` 的 `calls` 当时**并未来得及确证 `>0`**（它自己的两处自伤让驱动**根本没发出去**）就已被我拿来当"不可行"的依据。⇒ **记名**：**这是本会话第一次"队长踩自己刚立的红榜"** —— 我把它记下来，因为它证明**红榜真的在约束人（包括队长）**；同时也说明 `t165` 那次"自伤未报就会误导排期"（裁定五十二 (e)）的判断是对的，只不过**被误导的是我**。

**(c) 两成因分开（`D1` → `D2` → `D3`，**顺序写死**，队长照准并已派 `t167`）**：`t166` 明确指出 **`SIGSEGV` 的次因（槽序/ABI 错位）尚未排除**，且**悬垂与槽序错位都会给出 `SIGSEGV`** ⇒ **单凭 `t165` 那条读数无法区分**（这正是 `P10` 的正面用法）。三条判别**免费/低成本**：
- **`D1`（先行，最重要）**：在 **`CreateInstalledObjectsInfo` 的窗内**把 **17 字值拷贝**下来并打印；**同 run 在驱动点用同一悬垂指针读 17 字**，**逐字比对** ⇒ **不同 ＝ use-after-return 确证**（**归因到此结束，不必再谈槽序**）；相同 ⇒ 才轮到 `D2` 谈槽序。⚠️ **`17×8 ＝ 136 B` 是计算值、只许实测**（照 `t127`／`t160` 前例，实测后 `_Static_assert` 钉死）；并**照抄 `FSCBK` 的三态 ＋ 具名 gap 行**判据面（`:143-145`／`:646-654`）。
- **`D2`（指纹）**：托管装配在**第 15 槽**显式置 `IntPtr.Zero`（`PtsCache.cs:617`，`t163` 现取的**唯一未装配槽**），其余 16 槽非空 ⇒ **在 `D1` 确认有效的副本上，零位必须恰为 `index 15`**，否则 **槽序错位确证**（这是 `NOINFO-FSIMETHODS-ABI` 的正确解除方式）。
- **`D3`**：**只有 `D1`＋`D2` 都过才谈"调用"**。

**(d) 表形态判定入册**：`subtrack_methods` ＝ **封送期内的 17×8 B 可调用函数指针数组之基址**（`Pts.cs:3076-3082` 是 `[In] ref FSIMETHODS` ⇒ native 收到的就是**结构基址**，槽 `+0..+128`；实参是池字段地址 `PtsCache.cs:433`／`:640`／`:789-790`）。⇒ **不是间接层，也不是"不可调用"** —— `t165` 崩的是**持有方式**，不是**表本身**。

**(e) GC 存活判定入册**：持有位 ＝ **池字段**（`PtsCache.cs:789-790`）；**全仓无** `GCHandle`／`GetFunctionPointerForDelegate`／`AllocHGlobal`（`grep` **0 命中**）⇒ **不需要 `GCHandle`**；thunk 由**被持有的委托**保活（**判定**，须 `D3` 复核）。

**(f) 值化的两种形态**：① **值拷贝快照 ＝ 得**，但**必须且只能在 `CreateInstalledObjectsInfo` 的调用期内**做（与 `FSCBK` 不同：`ref` 指针本身就是基址，**不需要成员偏移**）；② **句柄化下发 ＝ 不必要且今天无机制**（`[In] ref` 只给值、无 `GCHandle`/`AllocHGlobal`）⇒ 具名 **`NOINFO-HANDLE-DOWN`**（要做属**新托管改动**）。

**(g) 一类值得记名的写法：把"判定"与"实测"分开并写明升级路径**。它的四条具名 `NOINFO` 里，**两条是判定、两条是未知**：`FSIMETHODS-ABI`（沿用 `t163`）／`MARSHAL-ATTR`（现取 `[In]` **只标在第一个 `ref`** 上、第二个未标 ⇒ 是否回写／是否不同缓冲**无仓内依据**，**只记不判**）；`BUFFER-LIFETIME`（"缓冲返回后失效"的依据是**本仓自己 `:120-131` 的三条理由 ＋ 窗/用分离的现取**，**不是 CLR 实测** ⇒ **标"判定"，由 `D1` 升级为实测**）；`THUNK-LIVENESS`（同为判定，**由 `D3` 升级**）。⇒ **口径**：**推断性结论必须标"判定"并写明"由哪一步升级为实测"** —— 与裁定四十三 (e)（"不得把'打不出来'当'通路不存在'"）、五十二 (d)（`P10`）共同构成同族的第三面。

**(h) 两处记名**：① **它守住了 `P9`**：**没有**把「`t165` 那一种用法崩了」推广成「表不可得」，而是把「只能原样存不许 deref」**主动收窄**为「**该缓冲只在调用期内有效**」，并给出"同族先例（`t133` 的 `FSCBK_JOIN=PASS exact=10/10` ＋ `+56`/`+80`/`+136`/`+176` 三跳成功调用）⇒ **窗内可读、可拷、可调**"的判断。② **它吸收了 `t165` 的教训**：**每条负面结论都附前置**（`calls>0` 才谈"调用失败"；`D1` 先于 `D2`；**有效副本上才谈可调用性**）。③ **自陈**：初稿把**使用窗**误判为 `DestroyInstalledObjectsInfo`（实为 `wpf_pts_drive_probe`），已按 `awk` 逐行归属**现取**更正；并修正两处压写/笔误 —— 且它自己指出「**这条自陈本身也是"送检物必须先真到检查点"的一个本地实例**」。

**裁定五十四（承 `t167` 回执，`ts=2026-09-29T19:4x+08:00`）—— (a) `D1` 确证 use-after-return（`t165` 归因**闭合**）；(b) 裁**槽号一律 1-based 双口径**；(c) 🔴 裁**"有效副本"的定义**（它把两件事混了 ⇒ `D2` 本可作结论却记了 `NOINFO`）；(d) 🔴 补第三条口径：**`D3` 的调用源必须是值化副本**；(e)(f)(g) 三处前置/口径更新入册；(h)(i) 一处口径 ＋ 两处记名。原文与既有裁定一字未删。**

**(a) `D1` 确证（`t165` 的归因闭合）**：载体 `build/MilBridge/P1-fsimethods-snapshot-report.md`（106 行／末行自证 `fb9b49544bc353c3`；`REPORTID=PASS files=285`）。
- **窗内值化**（唯一合法时机 ＝ `CreateInstalledObjectsInfo` 调用期内）：`[FSPARAMETH-SNAP] addr=… words=17 bytes=136 **state=VALUE nonzero=16** zero_index_win=14 w0=0x7cc08d65a910 … w15=0x7cc08d65aa60`；
- **驱动点用同一悬垂指针读回**：`[FSPARAMETH-READBACK] **same=0 first_diff=0** win0=0x7cc08d65a910 **now0=0x100000002** … now15=0x7cc08d… **v=USE-AFTER-RETURN-CONFIRMED**`（第二处读回 `now0=(nil)`）⇒ **首字即不同、该内存已被复用**；
- **两独立样本**（`addr` 不同）判词**逐字一致**；**三态面照抄 `FSCBK`**（`state=VALUE`；`NONE`／`ALLZERO` 与具名 `[FSPARAMETH-SNAP-GAP]` 机制在册；本腿 `gap=0`）。
⇒ **`t165` 的 `SIGSEGV` 主因 ＝ 跨调用持有封送缓冲地址；槽序未谈** —— 这正是 `t166` 判据要的收口，**它没有多走一步**。

**(b) 裁槽号口径（它请我裁的那一句）：一律 1-based 叙述，且**凡打印槽号必须双口径****。理由：`Pts.cs` 的字段序与 `PtsCache.cs:617`（未装配槽）的叙述都是 **1-based**；而 `t167` 的打印是 0-based ⇒ `zero_index_win=14`（0-based）＝ **第 15 槽**（1-based）。⇒ **口径写死**：以后打印用 `idx0=<n> slotN=<n+1>` 双给，**判据里的槽号一律 1-based**。

**(c) 🔴 裁「有效副本」的定义（本条最要紧，它把一个可判的记成了 `NOINFO`）**：`t167` 把 `d1_same=0` 读成"**副本无效**"，于是把 `D2` 记成 `NOINFO(槽序未取得有效载体)`。**队长裁定：这个理解把两件事混了** ——
- `D1` 的 `same=0` **正是"确证悬垂"的预期结果**（`t166` 判据原文：**不同 ⇒ use-after-return 确证**）；它**不是**"副本无效"的证据，恰恰是"**原始缓冲失效**"的证据；
- 而 `D2` 所需的"**有效副本**" ＝ **窗内值化成功的那份拷贝**，其有效性由 `[FSPARAMETH-SNAP] **state=VALUE** nonzero=16` 直接证；
⇒ 因此 **`zero_index_win=14`（0-based）恰恰是"在有效副本上取的窗内读数"** ⇒ **可以作结论**（不是 `NOINFO`）。⇒ 而它的**内容**是：**有效副本上零位恰一处、位于 1-based 第 15 槽** ⇒ **与 `PtsCache.cs:617` 的未装配槽吻合** ⇒ **槽序指纹支持"槽序正确（未错位）"**。⇒ 已派 `t168` **据本裁定重判 `D2`**（吻合/错位两向都要逐格依据）。

**(d) 🔴 补第三条口径（我在它的读数上发现的，本件最有价值的推论）：`D3` 的调用源必须是"值化后的副本"**。`D1` 证的是「**封送缓冲**跨调用失效」；而**值拷贝出来的那 17 个指针值**指向的是 **thunk**，`t166` 已判"**thunk 由被持有的委托保活**（全仓无 `GCHandle`/`GetFunctionPointerForDelegate`/`AllocHGlobal`）" ⇒ **副本里的函数指针本身可能仍然有效**。⇒ 也就是说：**`t165` 崩在"用悬垂指针"，而不是"表不可调用"**；**`FSCBK` 方子的完整形态是"窗内值化 → 此后只用自己的副本"**（`t141` 的 `fscbk` 正是如此：`:667 memcpy` 后只读 `wpf_pts_snap_word`）⇒ **`D3` 应当用副本去调槽 3**（**不是**悬垂指针、**不是**原始缓冲）。⇒ 已写进 `t168` 派单，并要求把 `THUNK-LIVENESS`（`t166` 标的"判定"）**由 `D3` 升级为读数**。

**(e) 前置更新入册**：🔴 **`NOINFO-BUFFER-LIFETIME` 已由"判定"升级为"读数"**（窗内 `VALUE` vs 驱动点 `same=0`）—— 这正是 `t166` 立的"**推断性结论必须标'判定'并写明由哪一步升级**"的**升级路径被走通**（记名）。其余：`NOINFO-FSIMETHODS-ABI` **未解除**（解除条件未满足）；`THUNK-LIVENESS` **仍未复核**（`t168` 消化）。

**(f) `PRECOND-NO-ENGINE-DRIVER` 的**成因改写**（采纳）**：它**未动前置本身**，只把成因从 `t165` 的"表不可 deref"改写为「**缓冲跨调用失效（use-after-return）**」。⇒ **归因更准确、前置仍成立** ⇒ 这正是"**改判成因而不动结论**"的正确做法（与裁定四十九 (a) 的"射程更正"同族）。

**(g) `P10` 落到实处**：`gate=SKIP`、`edrive=0` ⇒ **`calls=0`**，并**明确与 `calls>0` 分开报** ⇒ **本件不产出任何调用成功/失败判词**。⇒ 红榜 `P10`（**下负面结论前必须先证明被检物真的被送到了检查点**）在此有了**正向执行**：`D3-NOT-ATTEMPTED` ≠ "`D3` 失败"。

**(h) 一处口径（由本例提炼，值得通用化）**：**"守前置"与"误解前置"是两件事**。它**守着判据的前置不抢跑**（这点做得对，记名），但它**把前置的定义理解偏了**（把"原始缓冲失效"当成"副本无效"）⇒ 后果是**把一个本可作结论的读数记成了 `NOINFO`**。⇒ **口径**：**过度的诚实也是一种失真** —— `NOINFO` 只该给"**真的取不到**"或"**真的判不了**"，**不该**给"**前置被理解错**"；后者要**回头把前置的定义写清楚**（本裁定 (c) 就是这件事）。

**(i) 两处记名与小项入册**：① **它守住判据前置不抢跑**（`D2` 记 `NOINFO`、`D3` 记 `NOT-ATTEMPTED`，**没有硬凑**）—— 这是**对的**，只是定义要按 (c) 澄清。② **自陈**：**预登记（§A）在跑腿前定下、但与被载体一并落盘** ⇒ **未另落独立"最小载体"文件**（与 `t160` 同类偏离，已记）⇒ **我认可"如实记"**，**口径重申**下次先落。③ **两条小项入册**：**三态中的 `NONE`／`ALLZERO` 与 `gap` 行机制在册但本腿未触发**（需夹具或注入开关才能现取 —— `t168` 若能触发就给读数，不能就具名 `NOINFO`）；**`136 B` 已三断言 ＋ 运行期逐趟实测**（`words=17 bytes=136`，照 `t127`／`t160` 前例闭合）。

**裁定五十五（承 `t168` 回执，`ts=2026-09-29T20:0x+08:00`）—— (a) `D2` 重判 ＝ `SLOT-ORDER-OK`（**我裁的口径直接解锁了一个结论**）；(b) 🔴 `THUNK-LIVENESS` **升为读数**（副本可调用 ⇒ 裁定五十三 (b) 的收窄被完全验证）；(c) 槽 3 **真被调用**但 E2 仍未成立，阻塞点定位为 **`PRECOND-NATIVE-FORMAT-ENTRY-MISSING`**（`PRECOND-NO-ENGINE-DRIVER` **解除**）；(d) **副本驱动不是无条件安全**；(e) 三态闭环；(f) 记名。原文与既有裁定一字未删。**

**(a) `D2` 重判 ＝ `SLOT-ORDER-OK`（我的口径裁定直接解锁了一个结论）**：载体 `build/MilBridge/P1-fsimethods-drive-report.md`（107 行／末行自证 `a6d7a4bc641f3e80`；`REPORTID=PASS files=286`；两独立样本**逐字一致**）：`[FSPARAMETH-D2] copy_state=VALUE valid_copy=1 zero_cnt_win=1 **idx0_zero=14** **slotN_zero=15** expect_slotN=15 calib=both **nonzero_win=16** d1_same=0 **v=SLOT-ORDER-OK**`。逐格依据：副本有效（`state=VALUE ∧ nonzero=16`）｜零位**恰一处**｜零位 ＝ **1-based 第 15 槽**（`Pts.cs` 字段序第 15 个 ＝ `pfnGetFootnoteInfoWord`）｜其余 16 槽非空 ⇒ **槽序指纹支持"未错位"，`NOINFO-FSIMETHODS-ABI` 的槽序部分据此解除**（**仅"槽的语义映射"仍 `NOINFO`**）。⇒ **记名**：这是「**把前置定义写清**」**直接产出结论**的实例 —— 同一个读数，在定义含混时是 `NOINFO`、在定义澄清后是 `SLOT-ORDER-OK`。⇒ **口径**（与裁定五十四 (h) 配对）：**`NOINFO` 是"取不到"，不是"定义没写清"**；凡遇 `NOINFO`，第一件事是问**"是取不到，还是我没定义清楚"**。

**(b) 🔴 `THUNK-LIVENESS` 由"判定"升为"读数"（本件最能定性的一条）**：**槽 1 调用成功** —— `rc=0 **sobjc=0x1b63** pre=0xa5a5… rewritten=1 **idobj=7001** ffi=0x1 v=OBJCTX-PRODUCED`，而 **`0x1b63` ＝ 7011 ＝ `idobj(7001) + _objectContextOffset(10)`**，与托管公式**逐值吻合**（双跑一致：第二次 `sobjc=0x1b64`／`idobj=7002`）。⇒ **副本里的 thunk 指针确实可调用** ⇒ **`t165` 崩的确实是"持有方式"，不是"表不可调用"** ⇒ **我裁定五十三 (b) 的收窄（"问题在是否在窗内值化"）被完全验证**。⇒ 这条的价值在于：它同时**证伪了 `t165` 那一次崩溃所能支持的最强结论**（"表不可用"），而**支撑了 `FSCBK` 方子的完整形态**（**窗内值化 → 此后只用自己的副本**）。

**(c) 槽 3 **真被调用**，但 E2 仍未成立；阻塞点定位（排期依据）**：门 `gate=PASS（D2 ok；src=methods_snap）` ⇒ **`calls=1`（首驱动点）／`calls=2`（第二驱动点）**，与另两条副本腿的 `calls=0` **分开报**（红榜 `P10` 的正向执行）。**槽 3**：`rc=-100002 … pfspara=(nil) rewritten=1 claim=0 v=CALLBACK-ERR`，`asserts A_rc0=0 B_rewritten=1 C_claimable=0 D_one_new_entry=0 **v=E2-ASSERTS-PARTIAL**` ⇒ **被真正调用、但未产出可认领的 `pfspara`**。⇒ 它归因并立新前置：**`PRECOND-NATIVE-FORMAT-ENTRY-MISSING`** —— 托管槽 3 链（`SubtrackFormatParaFinite` → `ContainerParagraph.FormatParaFinite`）**回头要调 native 造型入口 `FsFormatSubtrackFinite` 一族**，**本波未实现** ⇒ 异常被 `catch` 成 `-100002`；⇒ **`(b)` 的 `cParas` 与 `pfspara` 在实现该入口前都拿不到**。⇒ **`PRECOND-NO-ENGINE-DRIVER` 已解除**。⚠️ **队长在此加一条约束（已写进 `t169`）**：**`-100002` 是"被 catch 的异常"，其具体异常类型仍是 `NOINFO`** ⇒ **不得**把"缺这个入口"当作**已验的因果**；下一件要**先侦察该族的入参契约与最小可行子集**，把这条因果**做出来**再谈推进。

**(d) 🔴 副本驱动**不是无条件安全**（它如实记，我采纳为约束）**：**第二驱动点之后 `FailFast`**（`app_rc=134`、`failfast=1 unrec=2`），而**主链两腿 `failfast=0`**。⇒ 这**加强了"副本专用"的必要性**（不是放宽）：⇒ **口径**：**副本的意义不是"安全地做实验"，而是"把不安全的部分限制在可丢弃的产物里"** —— 它崩了，**主链仍然是干净的字节**（`MAIN_BYTE_IDENTICAL=yes`）。⇒ 这也解释了为什么 `t165`／`t168` 都把"**主链逐字节不变**"当作**默认要求**而不是加分项。

**(e) 三态闭环（`t167` 的"未触发"被本件闭掉）**：新增两个**编译期注入开关（缺省 0）**⇒ **`NONE` 现取**（`snap=0 gap=2` ＋ 具名 `[FSPARAMETH-SNAP-GAP] rc=-10000 reason=null-methods … state=NONE`）／**`ALLZERO` 现取**（`nonzero=0 zero_cnt=17`）／**`VALUE`**（`nonzero=16 zero_cnt=1 slotN=15`）⇒ **三态判词互不相同** ✓。⇒ 这与 `t141` 的 `FSCBK` 三态面**同形齐备** ⇒ **"未触发"不是"不存在"**（与裁定四十三 (e) 同族）。

**(f) 记名**：① **它做到"先落最小载体"**（21 行、预登记 `R1–R9`、自证 `3fba3dd9066134b7`，再实现）⇒ **未重复 `t167` 的偏离**；② 实现期一处语法自伤（中文字符串内未转义引号）**当场修**，未影响读数；③ 它把 `PRECOND-NO-ENGINE-DRIVER` 的处理做成"**解除 + 立新前置 + 归因现取**"三步，**没有把旧前置含糊地留着**，也没有**借新前置掩盖旧读数**。

**裁定五十六（承 `t169` 回执，`ts=2026-09-29T20:1x+08:00`）—— (a) 族边界／入参契约入册：**E2 链上唯一缺的只有 `FsFormatSubtrackFinite`**；(b) 最小可行子集 `M1`「诚实无进展」及其 6 条必备形态；(c) 🔴 **`M1` 的假绿风险**（`rc=0` ⇒ 宿主继续走 ⇒ **"崩"变"静默空排"**）⇒ 判据面**必须分列两判词**；(d) 🔴 **它给的"免费判别"采纳**（`CallbackException` 已持有异常对象）；(e) 三条"不可当作者"入参入册；(f) 三处记名。原文与既有裁定一字未删。**

**(a) 族边界与入参契约（`build/MilBridge/P1-fsformatsubtrack-recon.md` 230 行／full sha256 `f610e8fd71e570d2acf7251a986217421ed90a4bed2a61b36e4a31ab2ac72d53`／末行自证 `b7b10d873d559c65`）**：
- **16 名 `Fs*Subtrack*` native 全未实现**；其中**造型类只有 3 条** —— `FsFormatSubtrackFinite`（`Pts.cs:3318`；调用点 `ContainerParagraph.cs:526-531`）／`Bottomless`（`:3344`；`:664-668`）／`UpdateBottomlessSubtrack`（`:3367`；`:788-792`）⇒ 🔴 **E2（槽 3）链上唯一缺的只有 `FsFormatSubtrackFinite`**。
- **能当作者 10 项**（`pfsContext`／`pfsGeom`／`fsRectToFill`／布尔枚举等）；**入站给的、不可当作者 3 项** ＝ `fsnmSegment`（**＝ `this.Handle`**）／`pfsFtnRej`／`pfsMcsClientIn`，而 native 家族码 `'H'` 今天**只认两个具体值**（`win32_pts.c:1457`）⇒ **引擎侧无能力校验托管句柄**（具名 `NOINFO-HANDLE-VERIFY-AT-ENGINE`）。
- **`pfspara` 定位 ＝ 是**：`ppfsSubtrack`（`Pts.cs:3335`）与 `FSPARADESCRIPTION.pfspara`（`win32_pts.c:3496`）**同种对象** ⇒ **不需新对象种类**（`t162` 的自有对象可直接用）。
- **断页记录不要求承载内容**（首调可 `NULL`、`:596` 只做零比较）⇒ **仅跨页续排才变硬要求** —— 这**回应了**裁定五十一 (d) 立的那个"内容诚实性"新格子：**本波不在那个格子上**（**首次造型**不要求内容），**但跨页续排会**。

**(b) 最小可行子集 `M1`「诚实无进展」的 6 条必备形态**（判据 ③，逐条入册）：**只做 `FsFormatSubtrackFinite`**；🔴 **`fsfmtr.kstop` 必须非 0**（`fmtrGoalReached = 0`，`Pts.cs:1123`）；**`ppfsMcsClientOut` 必须 0**（`:558` 会 `HandleToObject`）；`dvrUsed=0`；bbox 平空；`pTopSpace=0`（`:540`）；`brSubtrackOut=0`；**留痕具名**。⇒ 判据 **S-1 七条合取**（≥2 样本同判）⇒ 判词**只写「契约占位成立（honest no-progress）」**；**S-2（真造型）维持 `NOINFO`**。

**(c) 🔴 `M1` 的假绿风险（本件最要紧的约束，已写进 `t173`）**：`t169` 指出 —— **`rc=0` 会让宿主继续走**（`SetChunkInfo`／margin collapsing／`dvrUsed` 入几何）⇒ **可能把"崩"变成"静默空排"**，**而"静默空排"在外观上就是"跑通了"**。⇒ **口径**：**判据面必须把「无进展」与「排版成功」分列两条判词**（`S-1` ／ `S-2`），**且 `M1` 只许待在副本**；`S-2` **维持 `NOINFO`**（**本件不产出任何"排版成功"的判词**）。⇒ 这是 **`P8`（缺省值会改变控制流）族**的又一形态：**"宿主继续走"本身不等于"这段排好了"** —— 与 `t145` 的「登记即算」、`t136` 的「必要非充分」同族：**一个动作发生了，不等于它的目的达成了**。

**(d) 🔴 采纳它给的"免费判别"（本条把 `-100002` 从 `NOINFO` 变成可判）**：它现取 **`PtsContext.cs:405` 的 `CallbackException` 已经持有那个异常对象** ⇒ **下一件只需把它打印出来**（`GetType().FullName`）：若为 **`EntryPointNotFoundException`** ⇒ **`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 的假设升为读数**；**若为其它类型 ⇒ 该假设被推翻，必须改判**。⇒ 这正是它守 `P10` 的方式（**先证明/否证"被检物真的被送到了检查点"**），**且成本极低** ⇒ 已写进 `t173` 作为**第一优先**步骤。⇒ 记名：**这条为整个 `E2` 线省掉的不是时间，而是"基于未验因果的整轮排期"**。

**(e) 三条"不可当作者"的入参**（入册，防后人重踩）：`fsnmSegment`（**＝ `this.Handle`**）／`pfsFtnRej`／`pfsMcsClientIn` ⇒ **入站给的，不许自己造**；且**引擎侧无能力校验托管句柄**（家族码 `'H'` 只认两个具体值）⇒ **如实记"未校验"，不许假装校验过**（这条与裁定三十六的「探针绿只准读到字面意思」同族）。

**(f) 三处记名**：① **它如实区分了"结果丢"与"回执丢"** —— 载体是 **attempt 1** 产出的，attempt 1 的**完成更新因漏传 `attempt_id` 被拒**；attempt 2 **未重做侦察、只做复核**（件完整性 ＋ 自证 MATCH ＋ 关键引用当代重现）⇒ **既没有假装重跑了一遍，也没有把"回执失败"报成"工作失败"**。② **它主动核了世代漂移**：`win32_pts.c` 本 attempt 现取仍 `6d6f753105224f78`（与写作时同）⇒ **全部行号引用继续有效** —— 并同时报出 `HEAD` 已由 `1e29ffd` 移到 `c7f496c`（纯 docs 裁定、未动被引件）⇒ **"引用有效性"与"HEAD 变化"两件事分开核**，这正是本会话反复强调的"行号只在本次有效"的正确处置。③ **它自陈了一条工具纪律**：attempt 1 首读 `:526-531` 时用 `cut` **截列**，**截掉了行尾 `, iArea,`**，一度误读成"实参与声明错位"⇒ 已改正，并写下「**跨行实参表必须整行取（`awk` 行级），不许截列**」。⇒ **记名**：这条与我此前的"`grep -c` 返回 1 破坏 `&&` 链"、"`rc` 从管道尾读"同族 —— **都是"读法本身引入的失真"**；本会话该族已有 3 例，**值得作为一类纪律留档**。

**裁定五十七（承 `t171` ＋ `t172` 回执，`ts=2026-09-29T19:1x+08:00`）—— (a) `t171` 翻册入册 ＋ 其"锚区间前置断言"记名；(b) 🔴 `PRECOND-NO-HANDLE-ACCOUNTING` **在 native 自有族内可解除**（**带射程**）；(c) 🔴 立口径「**解除须带射程**」—— 与红榜 `P9` 镜像；(d) `P8` **第一次被完整落实**；(e) 采纳一条判据面建议。原文与既有裁定一字未删。**

**(a) `t171`（`scribe`）W8 第三阶段翻册**：`docs/ROUTES.md` `8065dcd86dd19c25`(979 行) → **`feff0fd943caa9a7`**(1003 行)，**`numstat 24 0`、删行数 0**（两 hunk 均纯 `a`：`189a190,205`／`979a996,1003`）。**`§13` 16 行**（**位置正确**：`TASK-0302` 子树内、`t143` 翻册块之后、`t71` 收尾行之前）—— 驱动链三级全通／`nmp` 托管侧身份／段落列表接线／`t161`+`t162`+`t163`／`t164`→`t168`（`D1` use-after-return、`D2=SLOT-ORDER-OK`、`THUNK-LIVENESS` 升读数、槽 3 真调用但 `-100002`、唯一硬阻塞 `PRECOND-NATIVE-FORMAT-ENTRY-MISSING`）／**三条假绿通道**（含"帧面不可复现"**已实证发生**）。**`§15af` 8 行**（EOF）：**五条族级纪律** ＋ **红榜 `P9`／`P10`** ＋ 口决（`P8`、`t166` 修订 `t165`、"`NOINFO` 是取不到不是定义没写清"、副本口径、**身份判据三条禁令**）＋ **相位口径**（`N1`／`N3`／`N4` 三格不可用 ⇒ 今天不得翻）。载体 `build/MilBridge/P1-w8-stage3-report.md`（97 行／`438f5c2a4395618b`／末行自证 `0620c42b7b4fb3c1` MATCH）。⇒ **记名（一条值得硬化的做法）**：它**第一遍落盘时锚选错**（首次匹配的 `t71` 收尾行落在 **`TASK-0007`** 子树）⇒ 它**从备份逐字还原**后改锚，且改法是「**先定位 `TASK-0302` 行、再取其后第一条 `t71` 行，并前置断言"锚区间含 `t143` 翻册块"**」⇒ 终态删行数仍 0。⇒ **口径**：**内容锚必须带"锚区间前置断言"** —— 只写"这个串唯一命中"是不够的（它唯一命中的**位置**也可能在错的子树里）；**"只增不改"类的安全性来自"我能断言我插对了地方"，不来自"我没删东西"**。⇒ 这条与裁定五十四 (h)（"`NOINFO` 是取不到，不是定义没写清"）同族：**都是把"看起来对"换成"能断言对"**。

**(b) `t172`（`runner`）活条目数只读口：`PRECOND-NO-HANDLE-ACCOUNTING` 在 native 自有族内可解除**：载体 `build/MilBridge/P1-handle-count-report.md`（88 行／末行自证 `3862c1b4165ba872` MATCH；`REPORTID=PASS files=287`）。**解除依据（四条全成对）**：
- **只读口存在且独立于 `rc`**：`[HCOUNTLEDGER]` **全部取自台账本体、无一处引用任何 `rc`**（`t158` R-4 原文照守；**未用"腿没崩"代替**）；
- 🔴 **成对可证伪**：腿 A（只建不回收）`live 0→3 delta=+3=n` **vs** 腿 B（建后回收）`live 3→0 delta=-3` ⇒ `pair=distinct live_A_after=3 ≠ live_B_after=0 distinct=1 v=PAIR-DISTINCT-AND-SELF-CONSISTENT` ⇒ **计数口真的在数、不是报常量**；
- **三式自洽**：`3=4−1`、`0=4−4`（两腿 `eq_live_eq_created_minus_destroyed=1`）；
- **两独立样本逐字相同**（裁定三十八）。
成品面：`win32_pts.c 6d6f753105224f78 → 1b642b1a906eb12f`（`59 3`）｜`.so → 352855f8dfbf8dc7`｜`exports 665 → **669**`（**逐名零消失**，新增 4 名 `PtsHandleLiveCount`／`CreatedCount`／`DestroyedCount`／`ReadingState`）｜`nm=669=exports 行数`、`^Fs=6`｜症状门逐格同。

**(c) 🔴 立口径「**解除须带射程**」（它与它给的射程声明是范本，本条最通用）**：它请求解除 `PRECOND-NO-HANDLE-ACCOUNTING` 时**主动声明了射程**：**只覆盖 native 自有台账**（`t162` 的 subtrack 对象族 —— `pfspara` 的值就是该族对象的字段地址 ⇒ 对 `pfspara` 面同样可外读）；**托管侧 `PtsContext._unmanagedHandles` 自由链仍无只读口** ⇒ 若某件要的是「**托管表**的活条目数」（`+176`／`+192` 的真实账），**那部分仍 `NOINFO`**；并**写死一句**「**`t158` R-4 的"回收正确性"判词不得引用本口当"托管表已正确回收"**」。⇒ **口径**：**凡解除一个前置（或宣布一个能力可用），必须同时声明"射程"** —— **哪一部分解除、哪一部分仍 `NOINFO`**，并**点名哪些判词不得引用它**。⇒ 这与红榜 **`P9`（局部否定当全局否定）严格镜像**：`P9` 治"**把局部否定当全局否定**"，本条治"**把局部肯定当全局肯定**" ⇒ **两条合起来 ＝ "射程对称"**（否定与肯定都必须带射程）。⇒ 这是本会话该族**第一次出现"正面结论的射程"**，值得单列。

**(d) `P8` 第一次被完整落实（记名）**：它的端口**未初始化时返 `-1`（不是 `0`）** ＋ `state=NO-READING`；初始化后返真值 ＋ `state=READING` ⇒ **"没取到"与"真的 0"判词不同**，且**它自己把它列为 `v=NO-READING-DISTINCT-FROM-ZERO`**。⇒ 这正是裁定四十八 (c) 立 `P8`（"缺省值会改变控制流 ⇒ 它不是缺省而是断言"）时想要的东西 —— **从"反过读"到"正向实现"隔了九条裁定**，记名。

**(e) 采纳一条判据面建议**：端口形态为 `int` 且未初始化返 `-1` ⇒ **后续件复用该口必须先读 `PtsHandleReadingState`**（否则会把 `-1` 当"活条目数是负数"或把 `NO-READING` 当 `0`）⇒ **写进后续任何引用该口的判据**。另记：两腿夹具**跑在真台账上** ⇒ 会抬高进程级 `created`／`destroyed`（行内已打 `n` 与 before／after 便于扣除）—— **如实记，不当作污染**。

**裁定五十八（承 `t173` 回执 ＋ 一次 dsh 重启，`ts=2026-09-29T19:2x+08:00`）—— (a) 🔴 **队长认账（第 15 次）**：我把"打印异常类型"判为"成本极低"，**漏了"谁有权打印"**；(b) 🔴 它自找的**"成对消去法"更硬** ⇒ 立口径；(c) `M1` 六形态全中、`S-1` 成立、**`S-2` 维持 `NOINFO`**；(d) **`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 可解除**，硬阻塞转为 **`PRECOND-NO-LAYOUT-MODEL`**；(e) 判词**粒度**的射程声明记名；(f) 一次 dsh 重启与我的处置。原文与既有裁定一字未删。**

**(a) 🔴 队长认账（第 15 次）：我把"直接读数"的成本判错了 —— 漏了"谁有权执行"**。我在 `t173` 派单里写「**免费判别**（成本极低）：`PtsContext.cs:405` 的 `CallbackException` 已经持有那个异常对象 ⇒ **本件只需把它打印出来**」。`t173` 现取证明**这一步它做不了**：**现有日志里 `CallbackException` 命中 0**，要打 `GetType().FullName` **需要托管侧 `.cs` 加一行只读打印**，而 `.cs` **不在 runner 写域** ⇒ 它**具名 `NOINFO(需托管侧打印)` ＋ `PRECOND-NO-MANAGED-SIDE-WRITER`，没有用别的证据冒充**（红榜 `P10` 守住）。⇒ **我的错法**：我从"**技术上只差一行打印**"直接推出"**这一步成本极低**"，**没核"这一行由谁写、在不在该件的写域"**。⇒ **口径**：**凡建议一条"低成本路径"，必须同时核对"执行权在谁手上"** —— **可及性（谁有权做）与可行性（技术上能不能做）是两件事**；只报可行性 ＝ 把一件跨写域的活包装成"顺手就能做"，**被派的人只能拒绝或越域**。⇒ 与裁定四十一 (d)（「装置分配资源必须把分配结果下传给消费者」）同族：**都是"能力/资源的可及性本身就是前置"**。

**(b) 🔴 它自找的解法更硬 —— 立口径「直接读数不可得时，用"只差一个变量的成对实验"代替」**：它没有停在 `NOINFO` 上，而是做了**行为判别**：**同一个副本、只差 `M1` 这一个变量** —— 腿 Y（无 `M1`）`phase=slot3 rc=**-100002**`×1；腿 X／X2（有 `M1`）`rc=**0**`×1，且 `[FSFORMATSUBT]` 行证明**本侧入口真被调用**（`nmSegment=0x3`、`geom=…`）⇒ **`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 由假设升为读数，假设未被推翻**。⇒ **口径**：**当"直接读数"不可得（缺仪器／缺写域）时，"同条件只差一个变量的成对实验"是等价且往往更硬的证据** —— 因为它**同时**证明了"变量被送到检查点"（`calls`／`[FSFORMATSUBT]` 行）与"结果随之改变"。⇒ 这是红榜 **`P10`（下负面结论前必须先证明被检物真的被送到了检查点）的正向解法**：`P10` 说的是"别急着下结论"，本条给的是"**那该怎么下**"。

**(c) `M1` 六条必备形态全中（两独立样本逐字一致）**：`kstop=1`（**非 0** —— 防"零填充被读成这段排完了"）｜`mcOut=(nil)`｜`dvrUsed=0`｜`bbox=flat`｜`topSpace=0`｜`brkOut=(nil)`｜＋具名留痕 **`v=HONEST-NO-PROGRESS calls=1`**。⇒ **判词分列成立**：**`S-1`「契约占位成立」＝ 成立**（六形态＋留痕＋≥2 样本同判＋`calls=1` 非"未发出"）；**`S-2`「真造型」＝ 维持 `NOINFO`**（`ppfsSubtrack=(nil)` **不得**读成排版成功）。

**(d) 前置状态改判（排期依据）**：**`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 可解除**（就"缺入口"这一因果而言）；**`PRECOND-NO-LAYOUT-MODEL` 成立**（**无排版模型 ⇒ `S-2` 只能 `NOINFO`**）；`NOINFO-HANDLE-VERIFY-AT-ENGINE` 成立；`PRECOND-NO-MANAGED-SIDE-WRITER` 成立。⇒ **当前硬阻塞从"缺 native 入口"变成"缺排版模型"** —— 这是本波**第二次换阻塞点**（第一次是 `PRECOND-NO-ENGINE-DRIVER` 解除）。

**(e) 判词"粒度"上的射程声明（记名，与裁定五十七 (c) 配对）**：它写死一句 —— ⚠️ **腿级诚实**：三条腿最终都 `app_rc=134 failfast=1`（发生在 `M1` 调用**之后**，与仍缺符号的 `FsQuerySubtrackDetails` 消费者路径同趟）⇒ **`S-1` 是"单次调用"级判词、不是整腿绿**，**两个方向都不许拿它读**。⇒ **口径**：裁定五十七 (c) 说"**解除须带射程**"，本条把它推进到**判词粒度** —— **"绿"必须带它成立的粒度**（单次调用／单趟／整腿／整批），**因为同一条腿里可以同时有"这一调对了"与"更后面崩了"**。⇒ 这与 "未触达的绿不是绿"（裁定三十七 (d)）互为两面：**一个治"没走到"，一个治"走到了但只走到一半"**。

**(f) 一次 `dsh` 重启与我的处置（如实记）**：我在派 `P1-W94`（补 `CallbackException` 类型读数）时，**平台把 `dsh` 服务重启了一次**（现取：进程 PID 由 `4155818` → **`16813`**、RSS 1.28 GB、运行仅 383s；今日 `FATAL ERROR: Reached heap limit` 累计 **6 行**、重启 **8 次**）⇒ **该次 `create_task` 的回执没落盘**（`The tool call was interrupted after it was recorded, but no result was durably recorded`）。⇒ **我的处置**：**不盲目重发**（重发会造出重复件 —— `t134`/`t135` 那次已经踩过），改用**新的轻量核查**：① `~/dsh-stall-check.sh`（落点 mtime ＋ 重活进程 ＋ dsh RSS ＋ heap 上限 ＋ 2h OOM 计数，**输出几十字节**，取代原先每次 ≈100 KB 的整份状态）；② 定点看**载体是否落盘**（`?P1-cbk-exc-type-report.md`）、`git status` 是否动 `PtsContext.cs`；③ 两者都无迹象 ⇒ **直接问 `scribe` 一句二选一**（「已收到 W94」／「未收到任何新任务」），**完全避开大输出**。⇒ 顺带核到一条好消息：**`t170` 的载体 `P1-fsimethods-verify.md` 已在 `19:16:50` 落盘**（`verifier` 的复核在做，**不是 stall**）。

**裁定五十九（承 `t170` 独立复核，`ts=2026-09-29T19:3x+08:00`）—— (a) 🔴 `F-1`（high，方向＝**放宽**）判**必修**：`t168` 的「槽序已解除」是**越权解除**；(b) 立口径「**解除越权**」（与「解除须带射程」配对）；(c) 采纳其"逐槽语义指纹"缺口；(d) 🔴 它**证实了我对 `idobj+10` 的怀疑**，并给了正确粒度；(e) 🔴 厘清 `F-3` 的"点名错"**不等于 `t173` 白做**；(f) 记名。原文与既有裁定一字未删。**

**(a) 独立复核的结论（`build/MilBridge/P1-fsimethods-verify.md` 152 行／全文 sha16 `8aa9a184c9069d9b`／末行自证 `21ea356bacc7faca` MATCH）**：**七项判词 ＝ ①部分成立｜②🔴不充分｜③如述不成立（实质分开成立）｜④成立｜⑤部分成立｜⑥成立｜⑦成立且判据可复现**。它**读数面没有推翻任何一条**，**推翻的是两条说法**（②与③）—— 这正是独立复核该干的活。

**(a-2) 🔴 `F-1`（high，方向＝**放宽**）：`t168` 的「`NOINFO-FSIMETHODS-ABI` 的"槽序"部分已解除」是**越权解除****：判据件 `:122` **只写单向判据**（「**否则**错位确证」），**从没写"吻合即解除"**；判据件 `:68` 更明确记该 `NOINFO`「**今天仍成立**」；而 `t167` 载体 `:97` 引的「判据**明写**：解除需 `D1` 有效 ＋ `D2` 吻合」在判据件**全文 `解除` 0 命中**（**无出处**）。⇒ **判必修**（已派 `t176`）：① **dated 只增不改**地把"槽序未错位"**收窄**为它给的准确形态 **`SLOT-ORDER-OK(第 1、3 槽有语义指纹；其余 15 槽仅"非空 ＋ 零位一致")`**；② **`NOINFO-FSIMETHODS-ABI` 恢复记「未解除」**，并**按槽登记"已验／未验"**；③ **不改任何读数、不删任何原文**。

**(b) 🔴 立口径「解除越权」（与「解除须带射程」配对，两条合起来才完整）**：裁定五十七 (c) 立的是**解除须带射程**（哪部分解除、哪部分仍 `NOINFO`）；本条治的是**更前一步**：**解除本身要有授权** —— **判据里必须写了"在什么条件下可解除"，解除才成立**；**判据只写了单向判据（"否则算错"）时，"吻合"不构成解除的依据**。⇒ 两条合起来：**一个"解除"要同时满足**：① **判据有授权**（写了可解除的条件）＋ ② **射程明确**（解除了哪一部分）。⇒ 这是本会话"**结论的射程/权限**"族的**第四面**（前四面：`P9` 局部否定当全局否定、裁定五十七 (c) 解除须带射程、五十八 (e) 判词粒度、本条 **解除越权**）⇒ 该族已足够大，**值得作为一类纪律**：**凡"状态变更"（解除前置／宣布可用／翻相位），必须写清「授权出处 ＋ 射程」两栏**。

**(c) 采纳其"逐槽语义指纹"缺口（`t170` 的正面产出）**：它指出 `t168` 的 `D2` 检查**结构上对 ABI 语义盲** —— 零位所据的 17 字是 `memcpy(t->methods_snap, addr, 136)`（钉版 `win32_pts.c:536`）把**托管传入的入参原样拷来**，零位又由 native 按**自己拷贝的字节偏移**统计 ⇒ **"只要托管有唯一 NULL 落在第 15 字段，无论 native 假设什么槽序，印出来都是 `slotN=15`"** ⇒ 它**能排除**"拷贝整体位移 k／截断／取错结构"，**不能排除** 16 个非零槽的**任意置换**、非零槽指向别的函数、ABI 语义错位。⇒ **缺口 ＝ 逐槽语义指纹，而今天 17 槽里只有 2 槽有**（第 1 槽：差值 ＝ subtrack 族常量 **+10**，与 subpage 支的 **+11** **可区分族**；**第 3 槽**：它**新找到的名级指纹** —— 崩溃栈 `PtsHost.SubtrackFormatParaFinite(...)` ← `PTS.FsCreatePageFinite(...)`，出处 `app-snapdrive.log:1000-1012`）。⇒ **这正是我在 `t170` 派单里点名要它挑的那条，它挑对了并给出了替代口径**。

**(d) 🔴 它证实了我对 `idobj+10` 的怀疑，并给出了正确粒度**：我在派单里问「`idobj+10` 是**恒定偏移**，那么"吻合"能不能被**任意** `idobj` 满足」⇒ 它答：**能** —— **等式对任意 `idobj` 恒成立 ⇒ 单看它证明不了"可调用"（我的怀疑成立）**。**但它同时指出这个等式不是恒真断言**：`sobjc` 是**被调方写的 out 参**（`:1494` 置毒、`:1498` 传 `&sobjc`），**native 全件无一处算 `idobj+10`**（`:1496` 只算 `7000+g_pts_sub_seq`），且 **offset 0 若指向非 `CreateContext` 槽 ⇒ `rewritten=0 v=OBJCTX-NOT-PRODUCED` 会当场变红** ⇒ **正确读法 ＝「某个具体托管实现真的被执行」在「第 1 槽」成立、在「整表」不成立**。⇒ 它还**补出了我和 `t168` 都没用的第二数据点**（`sobjc=0x1b64 … idobj=7002` ⇒ 7012＝7002+10 ✓），并用 `:2652 SubtrackCreateContext` **+10** vs `:2967 SubpageCreateContext` **+1（⇒+11）** 把观察值**指到 subtrack 族**，且**快照源正是 `CreateInstalledObjectsInfo` 第一个入参 `fssubtrackparamethods`** ⇒ **族与实现互证**。⇒ **口径**：**"数值吻合"类证据必须问"它在多大范围内恒成立"** —— 恒成立的等式只支持**"某个实现被走到了"**，不支持**"整表可用"**。

**(e) 🔴 厘清 `F-3` 的"点名错"（**不等于 `t173` 白做**，这条必须写进更正件）**：它现取 `drive-report:70` 点名 **`FsFormatSubtrackFinite`**，而**日志点名的是 `FsQuerySubtrackDetails`**（`[HC-UNHANDLED] #1/#2`，`app-snapdrive.log:842/848`；前者在驱动腿日志 **0 命中**、后者在 `t168` 代际 native 侧无实现）⇒ **`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 类型对、点名错**。⚠️ **但两者是两条不同的缺口**：`t173` 的**行为判别**已证**有 `M1` ⇒ 槽 3 `rc=0`**（⇒ `FsFormatSubtrackFinite` **确实是槽 3 链上缺的那一个**），而 `FsQuerySubtrackDetails` 是**消费者路径（`[HC-UNHANDLED]`）缺的那一个** ⇒ **各归各的用途**，`t173` 的工作**没有白做**。⇒ 已写进 `t176` 的更正要求。

**(f) 记名（它把这套纪律用在自己身上）**：它做了**防混淆复核**（`P9`／`P10` 用在自己身上）：比对是**同一表内**「**副本 vs 该表现读**」（钉版 `:573`／`:576`）⇒ **重快照同时更新两者**，所以**不会把"副本陈旧"误读成"内存复用"**。⇒ 这是本会话第一次有成员**主动声明"我的比较方法本身可能引入哪类假象"**。另：它**补报世界状态**（`bin/libwpfwin32.so` `291ef08a33f9b6e4`→`352855f8dfbf8dc7`、exports 665→669；`win32_pts.c` 已换成 `t173` 在飞的工作树版）并**钉版**（引 `t168` 代码必须用 `git show 1e29ffd:` ⇒ `6d6f753105224f78`／319005 B／4210 行）⇒ **在飞代际的正确处置**。

**裁定六十（基础设施运维批，`ts=2026-09-29T19:4x+08:00`）—— (a) `dsh` 堆上限 `7168 → 12288` 已改并生效；(b) 🔴 立口径「**"状态落盘"与"派单送达"是两件事**」；(c) 重启后的固定 checklist 落盘。原文与既有裁定一字未删。**

**(a) `dsh` 堆上限已调大（本会话"工具调用被掐"的根治动作之一）**：用户改大了设备配置（内存 **11.4 GB → 27.5 GB**、`nproc` **3 → 7**）后要求调堆。现取与处置：
- **改前** `/etc/systemd/system/dsh.service` `11:Environment=NODE_OPTIONS=--max-old-space-size=7168`（sha256 `d8ef2b60…`）；
- **改后** `--max-old-space-size=**12288**`（12 GB，sha256 `694f87f0…`），备份 `/etc/systemd/system/dsh.service.bak-heap-20260929-193036`；`systemd-analyze verify` 通过；`daemon-reload` 完成；
- **用户要求 `systemctl restart`** ⇒ 由队长排定 20 秒后执行（**因为队长自己就跑在 `dsh` 里** ⇒ 立刻重启会把这次对话一起掐掉；延迟到回复发得出去再重启）；**重启后现取**：`MainPID=4017`、`ActiveEnterTimestamp=19:32:15`、`NODE_OPTIONS=…12288`（**进程层与配置层都是新值**）⇒ `~/dsh-heap-watch.sh` 读 **`heap_limit=12288MB rss/limit=8.7%`**（重启前同一脚本读 **107%**）。
- **选 12 GB 的理由**：现取物理内存 27.5 GB ⇒ 45% ≈ 12.7 GB；要给跑腿留足（`dotnet build` ＋ `Xvfb` 一次吃几 GB）；而**堆不是越大越好**（堆越大 ⇒ GC 停顿越长、malloc 碎片让 RSS 更高）⇒ 口径：**上限设到物理内存 ~45%，不追高**。
- **两条安全待办（队长已提醒、未处置）**：① `systemctl show` 会把单元文件里的 **`DEEPSEEK_API_KEY=sk-a047…`（明文）** 打进输出 ⇒ 本会话记录里已出现，**建议轮换**；② 用户提供的 `sudo` 密码出现在会话记录中，**建议更换**。（队长**未**把密码或 key 写进任何文件、未进 git；命令走 stdin 传递。）

**(b) 🔴 立口径：「状态落盘」与「派单送达」是两件事**。本次重启暴露：`.agent-teams/**` 落盘 ⇒ **任务定义不丢**；但**成员侧收到的派单会丢** —— 实测 `scribe` 两次明确回执「**未收到任何新任务**」／「**丢了/不在了**」（`t174`→`t175`→`t177` 两次补发），而它的**会话本身是活的**（探测消息回执 `delivered via wake`）。⇒ **口径**：**"任务在册"不等于"成员已收到"**；⇒ **重启后的第一件事必须包含"逐件核对 pending/在飞任务是否真被成员持有"**，不能假设落盘＝送达。⇒ 处置方式：**内容一致的补发**（并在 subject 里标明"补发"，便于后人看出这是重投而非新工作）。⇒ 同族（本会话已 3 次）：`t134`/`t135`（中断的建单其实成功、队长重发造成重复件）、`t174`→`t175`、`t175`→`t177` —— 前一次是"**以为丢了其实没丢**"，后两次是"**以为在跑其实丢了**"，**两个方向都由"先核实、不盲重发/不盲等待"覆盖**。

**(c) 重启后的固定 checklist（已落盘 `~/wpf-linux-resume.md`，46 行）**：① `bash ~/dsh-stall-check.sh`（落点 mtime ＋ 重活进程 ＋ dsh RSS ＋ heap 上限 ＋ 2h OOM 计数，**输出几十字节**）；② `bash ~/dsh-heap-watch.sh`（核新上限是否生效 —— `heap_limit` 应为 `12288`）；③ `grep max-old-space-size /etc/systemd/system/dsh.service`（防配置回滚）；④ **逐件核对队列**（见 (b)）；⑤ 核仓库同步（`HEAD` vs `git ls-remote`、`portcelain` 是否干净）。⇒ 另记：**本会话"工具调用被掐 / 子代理静默停住"的主因已坐实** —— 今日 `dsh` 因 **V8 堆满** 被 systemd 重启 **11 次**（`FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory`），而**进程一死，正在跑的 turn 与工具调用就静默消失**（既不返回结果也不返回错误）⇒ 这解释了本会话反复出现的 `.agent-teams status` 无变化、落点 mtime 长时间不动、载体未落盘而**无任何报错**的形态。

## 9 未做 / 边界

- **未**跑整趟门禁（`verify-all.sh` 全跑）；本件只跑相关已接线牙与判据件。
- **未**改任何判据件（§4 的处置原则移交下轮）；**未**立新号。
- **未**回退 PF 取 before 第二次读数（§6 的 `NOINFO` 因此保留）。
- **未**提交/推送（提交归队长）；本件与 `PtsCache.Linux.cs` 的改动仍在工作树。
- 腿证据在仓外 `~/p1-ptsname/legs-after{,-2}/`；若要在册，需由队长择一落进 `build/MilBridge/tests/PtsPagesProbe/evidence*/`（本件不擅自覆盖在册证据目录）。
