# P1-W107 · `t198`：重修 `t194` —— **描述符字段求真值（甲）＋ 到达见证旋钮路（乙）**

> **本件 `t198`（runner）交付**。判据＝`build/MilBridge/P1-lm-consume-witness-criteria.md`（`t196`）**§5.2 六条合取**；`t195` 判词（`needs_revision`）三条 findings；队长 `t198` 派单（含 `W-1..W-4`）。
> **写域**：`src/WpfGfx.Linux.Native/**` ＋ 本载体。**未碰** `build/PresentationFramework.Linux/**`／`upstream/**`／`csproj`／`docs/**`／两枚哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`；未 `git add/commit/push`。
> 读取时刻 **2026-09-29T23:04:19+08:00**；件 sha16：`win32_pts.c`＝**`57a80e0bb51d17ea`**（4529 行）｜主链 `.so`＝**`352855f8dfbf8dc7`**／`exports.txt` 669 行｜上游 `PtsHelper.cs`＝`f2ed9552e983fed1`。行号「仅本次有效」。

## §0 结论摘要（**先给判词**）
1. **`(甲)` 成立且**（描述符 `+36/+60` 有真值、值**只**来自本侧段账 `LM-1`）：`desc_dvr_used=16 desc_dvr_top_space=0 desc_dv=16 desc_src=LM1-SEGMENT-LEDGER`，`arith_descriptor_ok=1` —— 本侧**就是** `PtsHelper.cs:177` 所读那个数组的填写者（判别器见 §8）。
2. **`(乙)` 只走到"换代"没走到"回收"**：`WPF_PTS_FSP_PL_GEN=1` 让**换代**在第 2 次填充真发生（读数 `fills=2 … gen=2`），但 `consumes++` 是**下一次调用**才做的**延迟回收**事件 ⇒ **到达半需要第 3 次填充**；本夹具每进程只给 **2** 次填充（12 腿一致），其后即既有 `app_rc=134`。
3. ⇒ **`S-2a` 第 4 条维持 `NOINFO`／降级见证**，`S-2a` **维持 7/8**（**不得**写成 8/8）。具名前置见 §10。
4. **两条必红反腿成立**（§5）：`NOARR`（`fill=0`）**且现在打具名缺省行**；`DVR_NODVR`（**描述符**层算术 `dv=0`）必红 —— 后者正是 `t195` `F-NODVR-WRONG-TARGET` 的修正（射程＝`:177` 的操作数）。
5. **主链零影响**：`.so` 重建前后 `352855f8dfbf8dc7`（`MAIN_BYTE_IDENTICAL=yes`）／`exports` 同值。
6. 🔴 **`W-1` 的前提不成立（驳回，附现取判别器）** ⇒ **`PRECOND-PARADESC-SOURCE-MISSING` 只在 `subtrack` 路成立，在 `track` 路不成立**；故 `(甲)` **未回退**（回退是一键操作，见 §8.4）。

## §1 `(甲)` 作者性**逐字段**声明（写死）
| 字段 | 偏移 | 值 | 由谁算 | 从哪个操作数来 | 写点（现取） |
|---|---|---|---|---|---|
| `dvr_used` | **+36** | `16` | **本侧**（M1 `M2` 段账） | `:1544 const int seg_h = 16;`（注释自陈「本侧段高（作者：本侧；由本侧页几何尺度定）」） | 段账入册 `:1568 wpf_pts_lm1_led_add(seg_h, top_sp, fits);` → 描述符写点 **`:3790 rg[i].dvr_used = … le->dvr_used;`** |
| `dvr_top_space` | **+60** | `0` | **本侧**（同一段账） | `:1545 const int top_sp = 0;` | 同上 → **`:3791 rg[i].dvr_top_space = … le->dvr_top_space;`** |
- **两条通路同源**：同一对操作数既走**出参**（`:1550 *out_dvr_used = seg_h;` → 托管 `ContainerParagraph`）也走**段账**（`:1568` → **描述符** → 宿主 `PtsHelper.cs:177`）。
- 🔴 **不填常数凑 `dv>0`**：描述符写点**只读** `g_pts_lm1_led[]`；`led_n < cParas` 时**不写**并具名 `desc_src=NOINFO(lm1-ledger-short:led_n<cParas)`（本次 12 腿均未触发该降级，`led_n=1 ≥ cParas=1`）。
- **值本身的能力界**：`16` 是**本侧建模段高**，不是宿主算出的真实版式 ⇒ 本见证只主张「**通路与操作数身份**」，**不**主张版式正确（§9 限制句）。

## §2 现取复算 `t195` 三条 findings（**本席自算**）
| # | 结论 | 现取依据 |
|---|---|---|
| `F-ARITH-WRONG-OPERAND`(high) | **成立**（改前代） | 改前件 `~/t123-runner/bak/win32_pts.c.pre-t198`（sha16 `27b023609512f74f`）：`grep -c 'rg\[i\]\.dvr_used\|rg\[i\]\.dvr_top_space'` **＝0**；同一份件填充面只有三行写点 `:3713/:3714/:3715`（`pfspara`／`pfsparaclient`／`nmp`）⇒ 宿主实得 `0−0=0`。现代同 grep **＝4**（`:3788/:3789` 写法 ＋ 读数引用） |
| `F-NODVR-WRONG-TARGET`(medium) | **成立**（改前代） | 改前 `:1553 const int dvr_u = WPF_PTS_FSP_PL_LMWIT_NODVR ? 0 : seg_h;` 只把**出参**打 0，射程不含描述符 ⇒ 已加**描述符面**反腿 `WPF_PTS_FSP_PL_DVR_NODVR`（`:3788/:3789`） |
| `F-LIMIT-STILL-MISSING`(low) | **成立**（改前代） | 改前「描述符层恒 `0−0`」⇒ 与 `dvrUsed=0` 的宿主行为**不可区分**；本件已把它写成 §9 的**在册限制句**（并注明现代它**已不是 0**，限制改锚在"建模值 ≠ 版式真值"） |

## §3 `S-2a` 八条逐条对账（**第 4 条判词类型不同**）
| # | 合取 | 本件后状态 | 依据（现取代 `app-wit3.log`） | 粒度 |
|---|---|---|---|---|
| 1 | `rc=0 ∧ calls>0` | ✅ | `[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=1 n=1 …`×2；`[LMM2] … calls=1` | 单次调用 |
| 2 | `cParas≠0` 且＝本侧驱动计数 | ✅ | `[LMM2] cParas=1(seg-ledger)`／`[FSPARALIST-FILL] cParas=1 n=1` | 单段 |
| 3 | `dvrUsed>0 ∧ ≥dvrTopSpace` | ✅ | `[LMM2] dvrUsed=16 dvrTopSpace=0 … I2_dvr_ge_top=1` | 单段 |
| **4** | **宿主侧消费证据** | 🔴 **`NOINFO`／降级见证** | 算术半（**描述符层**）✅：`desc_dvr_used=16 desc_dvr_top_space=0 desc_dv=16 desc_src=LM1-SEGMENT-LEDGER arith_descriptor_ok=1`；**到达半 ❌**：`consumes=0 resolve_ok=0 arrival_ok=0` | — |
| 5 | `kstop` 与放得下自洽 | ✅ | `fits=1 kstop=0` | 单次调用 |
| 6 | `brkOut` 与续排自洽 | ✅ | `brkOut=(nil)`（未续排） | 单次调用 |
| 7 | `bbox` 非空且与 `fsrc` 自洽 | ✅ | `bbox_def=1 bbox_dv=16 I4_bbox_selfcons=1` | 单段 |
| 8 | ≥2 样本同判＋纪律 33 格 | ✅（**口径收窄**，见 §9） | 同配置 `GEN=1` 四条腿（`wit1/wit2/wit3/noarr3`）**读数行逐字一致**；评分行条件式 | 读数行 |
⇒ **`S-2a` ＝ 7/8**。**第 4 条与其余 7 条的判词类型不同**：1／2／3／5／6／7 是"**单次调用内可直读的量**"；第 8 是"**读数行一致性**"；**第 4 条**是"**跨调用生命周期的到达事件** ∧ **算术**"的**合取**，其到达半在本腿**不可达** ⇒ 只能给**降级见证**。

## §4 腿矩阵与读数（12 腿／6 副本构建／2 次主链重建；同代 `.so` 见 §7）
| 腿 | 配置（旋钮**入册**） | 产物 | `fill` | `gen`/`quota` | `desc_dv` | 到达(`consumes`) | 判 |
|---|---|---|---|---|---|---|---|
| `wit1` | `GEN=1 declared=1` | `e4442341e4605609` | 2 | 2／1 | **16** ✅ | **0** ❌ | 不绿 |
| `wit2` | 同（独立样本：异 PID／异显示位） | 同 | 2 | 2／1 | 16 ✅ | 0 ❌ | 不绿 |
| `wit3` | 同（3 趟导航 `24 23 24`） | `2b0c509879689a08` | 2 | 2／1 | 16 ✅ | 0 ❌ | 不绿 |
| `ctlgen2` | `GEN=2 declared=1` | `e4442341e4605609` | 2 | **1**／2 | 16 ✅ | 0 ❌ | 不绿（**填成功但未回收**） |
| `ctl3` | `GEN=2 declared=1`（3 趟导航） | `2b0c509879689a08` | 2 | **1**／2 | 16 ✅ | 0 ❌ | 不绿（同形） |
| `undecl`／`undecl3` | **旋钮未声明** `declared=0 ⇒ knob=32` | `e4442341e4605609`／`2b0c509879689a08` | 2 | 1／2 | 16 ✅ | 0 ❌ | **不绿**（配置未入册禁判绿） |
| `noarr`／`noarr3` | `NOARR` 反腿 `GEN=1` | `56c05208c230279f`／`19f6eb49b8c88dde` | **0** | — | **未写**(`-1`) | `NOINFO(reason=lmwit-noarr-reverse-leg…)` | **红** ✅ |
| `dvrnod`／`dvrnod3` | `DVR_NODVR` 反腿 `GEN=1` | `c936bbfe6e6b773b`／`5144531b48546f9b` | 2 | 2／1 | **0** ❌ | 0 | **红** ✅ |
| `resize1` | `GEN=1` ＋ 改窗尺寸 | `2b0c509879689a08` | 2 | 2／1 | 16 ✅ | 0 ❌ | `NOINFO(resize-win-not-found)` |
- **必打读数行**（`t196` §6 / `t195` W-2①）：每次成功填充无条件打 `[LMWIT-ARRIVAL] port=counting-entry fills=%d consumes=%d resolve_ok=%d gen=%d quota=%d gen_size_knob=%d declared=%d led_n=%d desc_…`；**未填充腿**打具名缺省行 `consumes=NOINFO(reason=<具名>)` ⇒ **「没取到」与「真发生 0 次」形态可区分**（`noarr3` 逐字：`fills=0 consumes=NOINFO(reason=lmwit-noarr-reverse-leg(不填列表 ⇒ 到达见证恒 0)) … v=NOINFO(no-fill-in-this-leg)`）。
- **静默阈值已删**：`t194` 的 `if (consumes + resolve_ok >= 2)` 门（旧 `:3604`）**已移除**，回收一到**必打** `[LMWIT] part=arrival …`。
- 12 腿 `app_rc` 全为 **134**（**既有** abort，与本件改动无关：`noarr3`（填 0 次）同样 134 ⇒ 134 不以"是否填充"为条件）；崩溃栈在日志尾部（`app-wit3.log` 869 行，两条填充行在 648／655，其后为栈）。

## §5 三条必红反腿（逐字）
1. **`fill=0` 不得判绿** ⇒ `noarr3`：`fill=0`、`[FS_PAGE_GAP] rc=-10000 reason=lmwit-noarr-reverse-leg(不填列表 ⇒ 到达见证恒 0) …`、到达行 `v=NOINFO(no-fill-in-this-leg)` ⇒ **红成立** ✅
2. **旋钮值未声明不得判绿** ⇒ `undecl3`：`gen_size_knob=32 declared=0`，到达 0 ⇒ `joint=NOT-GREEN` ⇒ **红成立** ✅
3. **描述符层算术反腿（`t195` 修正）** ⇒ `dvrnod3`：`desc_dvr_used=0 desc_dv=0 desc_src=LM1-LEDGER(zeroed-by-DVR_NODVR-reverse-leg) arith_descriptor_ok=0` ⇒ **红成立** ✅（射程**就是** `:177` 的两个操作数）
4. **`t196` Q4 对照腿**：`gen_size=2` 且 `fill=2` ⇒ `gen` **仍为 1**、`consumes=0`（`ctl3`／`ctlgen2`）⇒ **未回收**；若该腿变绿即暴露增点被挪 ⇒ 本件**未**变绿，与 `GEN=1` 腿（`gen=2`）形成**同填充数、异配置**的成对读数 ⇒ 旋钮**真在动换代**而不是绕开见证。

## §6 旋钮与配置入册（纪律 33 格）
- 旋钮＝`WPF_PTS_FSP_PL_GEN`（在册，声明 `:1385-1392` 段；缺省 32，`<1 ⇒ 1`）；本件每条读数行**自带** `gen_size_knob=<值>` ＋ `declared=<0|1>`（新 helper `:1519 wpf_pts_fsp_pl_gen_declared()`，现取自 `getenv` 是否非空）。
- ⇒ **跨配置不可相减**这条现在**由行内字段机械保证**（`declared=0` 的读数不得与 `declared=1` 的相减/相加）。
- **换代可观测**：`GEN=1` 腿 `fills=2` 时 `gen=2`（换代真发生）；`GEN=2` 腿同 `fills=2` 时 `gen=1`（未换代）。

## §7 `.so` 换代前后 sha16 与导出计数
| 件 | 开工 | 收尾 | 说明 |
|---|---|---|---|
| `src/win32_pts.c` | `27b023609512f74f` | **`57a80e0bb51d17ea`**／4529 行 | 全部改动在 `#if` 内（`DVR`／`DVR_NODVR` 缺省 0） |
| `bin/libwpfwin32.so` | `352855f8dfbf8dc7` | **`352855f8dfbf8dc7`** | 两次重建（`run.sh`／`run3.sh`）均 `MAIN_BYTE_IDENTICAL=yes` |
| `bin/exports.txt` | 669 行 | **669 行** | 不变（**无**新增/消失） |
| 主链导出计数（本席口径 `nm -D \| grep -c ' T '`） | 666 | **666** | 口径写明：此为**本席 grep 口径**，与 `exports.txt` 669 行**口径不同**（不互相替代） |
| 副本产物（6 枚） | — | `e4442341e4605609`／`56c05208c230279f`／`c936bbfe6e6b773b`（run1）＋`2b0c509879689a08`／`19f6eb49b8c88dde`／`5144531b48546f9b`（run3） | 副本专用；`nm -D` 口径 672 |
| 新增只读导出（**仅副本**） | — | `WpfLinuxWin32_PtsLm1LedN/Push/Short` | 均在 `#if WPF_PTS_FSP_PL_DVR` 内 ⇒ 主链不导出 |

## §8 `W-1` 复核：**驳回**（附可机器判别的分叉点）
### 8.1 现取链（`upstream/…/PtsHost/PtsHelper.cs`，sha16 `f2ed9552e983fed1`）
```
:117  internal static void ArrangeTrack(
:133      PTS.FSPARADESCRIPTION[] arrayParaDesc;
:134      ParaListFromTrack(ptsContext, trackDesc.pfstrack, ref trackDetails, out arrayParaDesc);
:137      ArrangeParaList(ptsContext, trackDesc.fsrc, arrayParaDesc, fswdirTrack);
:145  internal static void ArrangeParaList(
:174      int dvrTopSpace = arrayParaDesc[index].dvrTopSpace;
:177      rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;
:604  internal static unsafe void ParaListFromTrack( … )
:614      PTS.Validate(PTS.FsQueryTrackParaList(ptsContext.Context, track, trackDetails.cParas, rgParaDesc, out paraCount));
```
⇒ `:174-180` 读的数组＝**`:134` 的 out 参数**，经 `:137` 传进 `ArrangeParaList`；它的**唯一填写者**是 `:614 FsQueryTrackParaList` —— **本侧已实现且本腿真被调**（`[FSPARALIST-FILL] entry=FsQueryTrackParaList … reason=ok`）。
### 8.2 `:633` 属**另一个**函数、**另一个**数组
```
:623  internal static unsafe void ParaListFromSubtrack( … )
:629      arrayParaDesc = new PTS.FSPARADESCRIPTION [subtrackDetails.cParas];
:633      PTS.Validate(PTS.FsQuerySubtrackParaList(ptsContext.Context, subtrack, subtrackDetails.cParas, rgParaDesc, out paraCount));
```
`ArrangeParaList` 共有**两个**调用点（现取 `grep -rn`）：`PtsHelper.cs:137`（**track 路**，数组来自 `:614`＝我方）与 `ContainerParaClient.cs:72`（**subtrack 路**，数组来自 `ContainerParaClient.cs:70 ParaListFromSubtrack`＝`:633`＝未实现）。`t195` 的"唯一填写者＝`:633`"只对**subtrack 路**成立。
### 8.3 判词
- **`track` 路**：`:174-180` **可达**（本腿 12 次 `reason=ok` 填充即该入口被真调；`ArrangeTrack:130` 用 `trackDetails.cParas != 0` 门槛、`:137` 无条件进 `ArrangeParaList`，且 `:617 Assert(trackDetails.cParas == paraCount)` 在我方 `*cParaDesc = cParas` 下成立 ⇒ 数组长度 ≥1 ⇒ 循环体至少跑一次）。**该推论是"现取源码＋在册读数"的逻辑链，不是直读宿主**（§9 限制句②）。
- ⇒ **`PRECOND-PARADESC-SOURCE-MISSING` 收窄为**：`scope=subtrack-path(ContainerParaClient.cs:70→:72)`；**不覆盖** `track-path(PtsHelper.cs:134→:137)`。
- ⇒ 故 `(甲)` **不回退**；若队长仍裁"必须回退"，一键即回（§8.4），回退后 `S-2a` 仍 7/8、第 4 条仍 `NOINFO`（不会因回退而更绿）。
### 8.4 回退口（备用，未执行）
`cp -f ~/t123-runner/bak/win32_pts.c.pre-t198 src/WpfGfx.Linux.Native/src/win32_pts.c`（备份件 sha16 `27b023609512f74f`，与开工代一致）。

## §9 限制句（**写死**；`W-4` 口径已收窄）
1. 「本见证**粒度＝单次调用 ＋ 计数口**」；**不得**据此宣布整页/跨页排版成功；
2. 「`:174-180` 被执行」是**逻辑链**（现取源码 ＋ `reason=ok` 填充），**不是直读宿主局部**；
3. 「到达量（`consumes`）＝ `+192` **回收**事件，其前置是"客户端被创建"，**不等于** `:174-180` 被走到」⇒ 两个口径**分开写**，**不得**用"回收被走到"冒充"宿主读到了 `rcPara.dv`"；
4. 「描述符里的 `16` 是**本侧建模段高**，非宿主算出的真实版式」⇒ 算术成立**只**证通路与操作数身份；
5. `W-4`：「两样本一致」一律限定为「**读数行**逐字一致」（`t194` 的"整腿逐字一致"**已撤回**：整腿自崩溃栈起即分叉）。

## §10 具名前置 · `NOINFO` · 合法终点
- 🔴 **`PRECOND-ARRIVAL-WITNESS-NEEDS-LONG-LEG`（维持，且现取收窄）**：到达半要求"**第 3 次**填充"——`GEN=1` 时第 2 次填充已**换代**（`gen=2`），而 `consumes++` 是**下一次调用**的**延迟回收**（`:3625` 段），本夹具每进程只有 **2** 次填充（3 趟导航 `24 23 24` 与改尺寸**都没**增加调用），其后即既有 `app_rc=134`。
- **`NOINFO(resize-win-not-found)`**：`xdotool search --name HandyControlDemo` 返回空（`resize1` 腿）⇒ 改尺寸**未实施**；**不**据此判"不可能"。
- **`NOINFO-134-CAUSE`（维持）**：本件**不**替 `t196` 判 134 成因（且本件未留该栈的分析），只记"12 腿全 134、`noarr` 腿填 0 次亦 134"这一事实面。
- **合法终点**：**没有**把 `NOINFO` 写成绿，**没有**把"换代被走到"写成"宿主读到了 `dv`"，**没有**用常数凑 `dv>0`。

## §11 自曝（本席自己的失误，均已拦下/记账）
1. **首版跑脚本笔误** `$DVRND`（未定义）⇒ `set -u` 下重活 **8 秒即退**、**腿一条未跑**（日志 `hs.log`；`HEAVYSLOT=RELEASED rc=1`）⇒ 修正后 `run.sh` 重跑；broken 版留档 `run.sh.broken31`。
2. **`t194` 的静默阈值**根治前，`wit1/wit2` 的到达半在旧代码里属"没打印" ⇒ 本件**先**补必打行**再**取读数（本件所有到达读数都来自**必打行**）。
3. 本件的**算术半**可绿而**到达半**不可绿，两者**不混写**为"第 4 条绿"。

---

## §12 dated 线索（追加 · **只增不改**；上一行自证原文保留在上方）
- **下一阶段可达性线索**：`t194` 载体称其主链腿曾 `fill=1056/1044`（**照引，本席未独立复算**）。**本席现取复核**（本机 `~/t123-runner/logs/t160/`）：该车道**只有** `app-aba.log`（`fill=1`）与 `app-selfrec.log`（`fill=2`），**未见** 1056 规模样本 ⇒ 该数字**未能在此复核**，其出处需队长/`t160` 载体指路。
- **给下一件的可执行建议**（**不在本件写域内**）：到达半只差"第 **3** 次填充"。两条候选：① **换成大文档的导航条目**（同探针门，令每进程 `fill≥3`）——成本低、不动码；② **夹具层加一次 `ArrangeTrack` 级重排触发**（如窗口改尺寸，本件因 `xdotool` 窗口名未命中而未实施）。
- **禁**：为凑第 3 次填充而**自调本入口**（那会让"到达"变成自证，属"绕开见证"，`t199` 正在盯的形态）。
`P1-LM-CONSUME3 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 699184dd3eed173f（⏪ §12 追加后重算；**上一条自证＝`681cdbea6add7d72`**，其行文已被本行取代并在 §12 说明）`

---

## ⏪ `t207`（A-3）dated 改词 · 「描述符字段**求真值**」⇒ 「**本侧模型值**（常量 `seg_h=16`／`top_sp=0`）＋**零判别力**」（读时 `2026-09-29T23:25:21+0800`；**只增不改**、删行数 0）

**来源**：`t206` 裁决（照引，同上）
**被更正的原文**（本件内，**一字未删**；**本席现取**行号「仅本次有效」）：`:1`（件题；**本席现取**该词在本件**命中 1 处**）。
- **改词（逐字）**：所称"**求真值**"应读作「**本侧模型值**」——即**常量** `seg_h=16`／`top_sp=0`（**本侧自己写出的量**），**不是**从引擎/宿主侧读回来的真值。
- **明写零判别力**：`seg_h=16`／`top_sp=0` 是**常量** ⇒ **零判别力**（不能区分任何状态）；**不得**据此改判成"有判别力"、也**不得**把它当作 `rcPara.dv` 的观测量。
- **优先规则**：本条与本件"求真值"字样冲突时**以本条为准**；原句一字未删。
⚠️ 与 `win32_pts.c` 相关注释的关系：**只引用、不改字**（`src/**` 不在本件写域）。

`P1-LM-CONSUME3-REPORT 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 76cc976ee96ee7f2`（⏪ `t207` 追加后重算；**上面历史自证行原文保留**）
