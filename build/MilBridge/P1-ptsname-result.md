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

## 9 未做 / 边界

- **未**跑整趟门禁（`verify-all.sh` 全跑）；本件只跑相关已接线牙与判据件。
- **未**改任何判据件（§4 的处置原则移交下轮）；**未**立新号。
- **未**回退 PF 取 before 第二次读数（§6 的 `NOINFO` 因此保留）。
- **未**提交/推送（提交归队长）；本件与 `PtsCache.Linux.cs` 的改动仍在工作树。
- 腿证据在仓外 `~/p1-ptsname/legs-after{,-2}/`；若要在册，需由队长择一落进 `build/MilBridge/tests/PtsPagesProbe/evidence*/`（本件不擅自覆盖在册证据目录）。
