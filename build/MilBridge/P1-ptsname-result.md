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

## 9 未做 / 边界

- **未**跑整趟门禁（`verify-all.sh` 全跑）；本件只跑相关已接线牙与判据件。
- **未**改任何判据件（§4 的处置原则移交下轮）；**未**立新号。
- **未**回退 PF 取 before 第二次读数（§6 的 `NOINFO` 因此保留）。
- **未**提交/推送（提交归队长）；本件与 `PtsCache.Linux.cs` 的改动仍在工作树。
- 腿证据在仓外 `~/p1-ptsname/legs-after{,-2}/`；若要在册，需由队长择一落进 `build/MilBridge/tests/PtsPagesProbe/evidence*/`（本件不擅自覆盖在册证据目录）。
