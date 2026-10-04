# `P1-tail2` · `T-A47` · 消"相位翻最后一阻"＝残留 `[HC-UNHANDLED]=1` —— 实现报告（**判决：缺省路径 `[HC-UNHANDLED]=0`；两极化两条（各回各自的红）；`PTS_COLORANCHOR` 仍 `PASS hits=2` 且帧逐字节未变；`nm==exports`／`PTSGAP=PASS`／`DEFREG`／`REPORTID` 各 `rc=0`**）

- **读时**：`2026-09-30T20:0x–20:2x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=cab2816`（＝ `T-A46` 那笔；**未换代**）。
- **改前件备份（仓外 `~/tA47-work/bak/`，`cp -p`，取在**任何写之前**）**：`reapply-patches.py`（`3e745f179cf63913`）／`WpfLinuxChainProbe.Linux.cs`／`PtsHelper.Linux.cs`（`pre-t47` 三件；`sha16` 与写前逐件 `cmp` 相同）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**两处收窄**）／其登记面 `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（只改 `so16` 锚 ＋ dated 追注）／`build/PresentationFramework.Linux/reapply-patches.py`（**生成器**，`P8`）⇒ 由其**重产**的生成件 `PtsHelper.Linux.cs`（`temp+os.replace`，生成器自己写）／复述位现值位（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）／**新建载体** 本件。
- **黑名单遵守**：未动 `build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）；**未跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`；未改相位；未 `git add/commit/push`。
- **重活**：**5 趟匣构建**（4 趟托管 ＋ 1 趟 native，各 `3–26 s`）＋ **6 趟跑器**（共 **12 条腿**；全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`，逐趟 `HEAVYSLOT=ACQUIRED/MEMOK/RELEASED`，`held=21/33/34/36/36s`）；进程只按 PID；显示位 `:231`（装置自取；逐趟 `DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p` 备份；模式守恒。
- **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`grep`／`wc`／只读 `python3`＋生成器）；`T-A46` 载体（`P1-tail2-rearm5-recon.md`）**只作对照**，其读数一条未抄。

---

## §0 结论速览（自包含）

1. ✅ **判据 ①（残留成对）**：缺省路径 **`[HC-UNHANDLED] 1 → 0`**（改前＝在册 `evidence/app_g1.log` 的 `ArgumentException: Specified Visual is already a child of another Visual or the root of a CompositionTarget.`／首帧 `System.Windows.Media.VisualCollection.Add(Visual)`）。
2. ✅ **判据 ②（不回归）**：`PTS_COLORANCHOR=PASS k=24 hits=2`（`GhostWhite=22736`／`Beige=910`／`DarkGreen=44`／`LightGoldenrodYellow=0`；基线 `boot.png` 四色**全 0**）；帧 `k24=791696291d51470b`、`k23=10d0b9d54e649c10`、`boot=b21eb530afd3c66c`（**逐字节未变**）；`AE(boot,k24)=220019`、`AE(boot,k23)=189862`、`AE(k23,k24)=136297`（未变）。
3. ✅ **判据 ③（门禁四件）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **683**（逐名 `diff` 零差异）｜`PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=1dbea9026dd7d3d7 exports=683`（`rc=0`）｜`DEFREG=PASS declared=225 route_ids=225`（`rc=0`）｜`REPORTID=PASS`（`rc=0`）。
4. ✅ **判据 ④（症状门成对）**：四条腿逐格同 —— `alive=yes app_rc=143 failfast=0 magenta=0 colors=905 ink=480000 ns=…FlowDocumentDemo`；`NAMED managed_unavail=0 err=- native_gap=0`。
5. ✅ **两极化（各回各自的红，同一 `.so 1dbea9026dd7d3d7`／同一 `pf 189e3704cbf4f031`／同一装置 `:231`／同批工具，只差一个 env）**：
   - `WPF_FLOAT_REPARENT=0` ⇒ `[HC-UNHANDLED]=1` **`ArgumentException`**（改前那条**逐字回**）；
   - `WPF_PTS_QTP_LIVE_NARROW=0` ⇒ `[HC-UNHANDLED]=1` **`PtsException … '-10000'`**（具名 `[FS_PAGE_GAP] rc=-10000 reason=drive-handles-released(page-destroyed) entry=FsQueryTrackParaList` 回）。
6. 🔴 **断点（身份级，现取）**：抛出点 ＝ `PtsHelper.UpdateFloatingElementVisuals` 的 `visualChildren.Add(paraVisual)`（**该树内唯一**"非新建视觉"的 `.Add`）。**同一 `FigureParaClient` 实例**先被页 `0x…bab0` 的浮层收纳，随后页 `0x…a960` 的浮层再 `.Add` 同一 `Visual`（其父仍是页 `0x…bab0` 的 `ContainerVisual`）⇒ 抛。见 §1。
7. 🔴 **根因在 native 侧（如实点名，不改）**：附属对象台账 `win32_pts.c: fl_att[].obj_client` 是 **doc 级、跨页复用**；上游 WPF 不会出现"一个 `BaseParaClient` 同时活在两页 `FloatingElementList`"这一形态（页销毁 ⇒ `Dispose()` ⇒ `RemoveFloatingParaClient`）⇒ 具名下一靶 `PRECOND-NATIVE-PAGE-SCOPED-ATTACH-CLIENT`。见 §5。
8. ⚠️ **如实披露（防被读宽）**：拒因收窄后**分页器把整个文档走完**（`[QPD] page=` **去重 280 页**；改前因中途抛异常 → `DocPage` 只走到 ~7 页）⇒ 仪器日志 `11.4 MB`。**帧面逐字节未变**、单腿耗时同量级（`held=36s`）⇒ 判为"**不再中途止**"，**不是**回环。

---

## §1 ① 断点：定位到"句"（现取）

### 1.1 抛出点：本树内**唯一**"非新建视觉"的 `.Add`

| 面 | 现取 |
|---|---|
| 残留原文 | `[HC-UNHANDLED] #1 ArgumentException: Specified Visual is already a child of another Visual or the root of a CompositionTarget. ｜ 首帧 at System.Windows.Media.VisualCollection.Add(Visual visual)` |
| 上游判据 | `VisualCollection.cs`：`Add`／`Insert` **都**在 `visual._parent != null \|\| visual.IsRootElement` 时抛 `SR.VisualCollection_VisualHasParent`（**首帧**因此能区分二者：本件是 `Add`） |
| 全树 `.Add` 枚举（只读 `grep`） | 本移植 PTS 树里**只有** `PtsHelper.cs:90 UpdateFloatingElementVisuals` 的 `visualChildren.Add(paraVisual)` 加的是**既有视觉**；其余 `.Add` 全是 `new ContainerVisual()`／`new SectionVisual()`／`CreateLineVisual(...)` |
| 验证（诊断腿） | 加"逐 `Add` 身份探针"后现取**恰 1 条**异常，且**紧邻**该探针行 |

**诊断腿（`~/tA47-work/diag1`，仓外；诊断件已随本体回退）逐字**：
```
[T47-DIAG] FLOATING-ADD idx=0/2 visual=28099101 parent=ContainerVisual#51565323 host=17425743 client=FigureParaClient#61434729
[T47-DIAG] FIRSTCHANCE#1 System.ArgumentException ||| … Specified Visual is already a child …
   at System.Windows.Media.VisualCollection.Add(Visual visual)
```
⇒ **身份级**：`client=FigureParaClient#61434729`（**同一个实例**）的 `Visual`（`28099101`）**父已是** `ContainerVisual#51565323`，而当前要加进的宿主是**另一个** `ContainerVisual#17425743`。

### 1.2 两个宿主是**两页**（不是同一页的重建）

| 面 | 现取（同一趟腿内） |
|---|---|
| 第一次落位 | `host=51565323`（＝页 `0x…bab0` 的浮层容器；`[QPD] … page=0x…bab0 … vis_built=0`） |
| 失败的那次 | `host=17425743`（＝**另一个** `PtsPage` 对象 `0x…a960` 的浮层容器；`[QPD] … page=0x…a960`） |
| 同一客户端 | 两次 `client=FigureParaClient#61434729`（**同值**） |

⇒ 同一路：`TextParaClient.OnArrange` 对每个附属对象调 `((FigureParaClient)paraClient).ArrangeFigure(rect, _rect, fswdir, _pageContext)` ⇒ `BaseParaClient.Arrange` 里 `_pageContext = CurrentArrangeContext.PageContext` ⇒ `FigureParaClient.OnArrange` 里 `_pageContext.AddFloatingParaClient(this)`（**每页各加一次**，`PageContext` 逐页新建）⇒ 该客户端同时出现在**两页**的 `FloatingElementList` 里；`UpdateFloatingElementVisuals` 先把它加进页 B 的浮层，再加进页 C 的浮层 ⇒ 撞。

---

## §2 修法（两处；逐处可复核）

### 2.1 托管侧（**必须走生成器**，`P8`）：`PtsHelper.UpdateFloatingElementVisuals` 补"浮层视觉的换父"

- **落点**：`build/PresentationFramework.Linux/reapply-patches.py` 的 `CHAIN_FILES` 中 `MS/Internal/PtsHost/PtsHelper.cs → PtsHelper.Linux.cs` 条目**新增一对** needle/repl（生成时打印 `[OK] 生成 …/PtsHelper.Linux.cs（5 处改动，needle 全部命中）`）。
- **逐字（生成件现取）**：
```csharp
                    if(visualIndex == visualChildren.Count)
                    {
                        // ── `T-A47`（`FLOAT-REPARENT`）：**浮层视觉的换父** ────────────────────────
                        //  见生成器内该块的说明；`WPF_FLOAT_REPARENT=0` ⇒ 逐字回上游（反极性腿）。
                        if (WpfLinuxChainProbe.EnvOn("WPF_FLOAT_REPARENT"))
                        {
                            Visual t47Parent = VisualTreeHelper.GetParent(paraVisual) as Visual;
                            if (t47Parent != null)
                            {
                                ContainerVisual t47Cv = t47Parent as ContainerVisual;
                                Invariant.Assert(t47Cv != null, "parent should always derives from ContainerVisual");
                                t47Cv.Children.Remove(paraVisual);
                                WpfLinuxChainProbe.Hit("PH.FloatingReparent", "idx=" + index
                                    + " from=" + t47Parent.GetType().Name + " to=" + visual.GetType().Name);
                            }
                        }
                        visualChildren.Add(paraVisual);
                    }
```
- **为什么这是"改写法的同形先例"而不是新发明**：**上游自己**在同一文件的 `UpdateParaListVisuals` 的 `fskupdNew` 支里**就**先 `VisualTreeHelper.GetParent(paraClient.Visual)`／`parent.Children.Remove(...)`（含**同款** `Invariant.Assert(parent != null, "parent should always derives from ContainerVisual")`）再 `Insert` —— 本块把**同一个惯用法**补到浮层支上（上游浮层支**假定**"不会换父"）。
- **不是把失败吞掉**：旧父**若非** `ContainerVisual` ⇒ 与上游一样**响亮断言**；且视觉是**搬到**"当前正在构建的那一层"（旧页随即 `FsDestroyPage`，见 §2.2 的现取序）。
- **零假值**：`WPF_FLOAT_REPARENT=0` ⇒ **整块不发生**（逐字回上游）。

### 2.2 native 侧：`drive-handles-released(page-destroyed)` 两处拒因**收窄**

两处落点（`grep` 现取：`drive_handles_live` 的**全部**使用点 ＝ 声明 ＋ 置 1 ＋ 置 0 ＋ **这两处**）：

```c
/* ⏪ `T-A47`（`QTP-LIVE-NARROW`）：页销毁后**仍可服务**的充要条件 —— 见填充支里那条拒因的收窄说明 */
static int wpf_pts_qtp_live_narrow(void)   /* 缺省 1；WPF_PTS_QTP_LIVE_NARROW=0 ⇒ 回改前（反极性腿） */
```
| 入口 | 改前 | 改后 |
|---|---|---|
| `FsQueryTrackParaList`（填充支） | `else if (LIVE_GUARD && !dp->drive_handles_live) reason = "drive-handles-released(page-destroyed)";` | `… && !(wpf_pts_qtp_live_narrow() && dp->fsp_pl_cur)` |
| `FsQuerySubtrackParaList` | `else if (LIVE_GUARD && !dp->drive_handles_live) reason = "…";` | `… && !(wpf_pts_qtp_live_narrow() && obj->child_clients_made >= cParas)` |

- **为什么拒因**过宽**（逐条，源件内容锚）**：那条理由（`T-A17` 原文）是"**再调 `+176 CreateParaclient` 必撞 `PtsContext.HandleToObject` 的 `Invariant.Assert`**（**不可捕获 `FailFast`**）" —— 它**只对"要发 `+176`"成立**。而**窗外**（查询期）这两支**本来就不发 `+176`**：`FsQueryTrackParaList` 的 ③ 换代要求 `wpf_pts_qtp_create_safe(dp)`（`in_win`）、④ 造新一代要求 `!dp->fsp_pl_cur`；`FsQuerySubtrackParaList` 的 `+176` 循环**只跑 `i ∈ [child_clients_made, cParas)`**。⇒ **手上已有客户端（`fsp_pl_cur`／`child_clients[]` 已造满）时，本次填充一个托管句柄都不碰** ⇒ 拒填 = **过宽**。
- **"单向闩"现取**：`drive_handles_live` 只在 `FsDestroyPage` 置 0、只在 `wpf_pts_drive_probe` 置 1；而后者**每 doc 只跑一次**（`drive_done`；本趟 `[DRIVE-PROBE-SKIP] reason=doc-already-driven skips=1/2/3` 现取） ⇒ **一旦该 doc 销毁过任一页，此后一律拒填**。
- **收窄后仍是真值**：出参照旧 `pfsparaclient` ＝ 真客户端句柄、`pfspara` ＝ 本侧自有子轨对象字段地址、`cParaDesc` ＝ `cParas`；**其它任何拒因**（`no-legal-nmp-in-this-run`／`fill-budget-exhausted`／`para-claim-failed`／`no-layout-content-model` …）**逐字不变**（`Fix3` 趟 `[FSPARALIST-FILL] reason≠ok` ＝ **0** 条、`[FS_PAGE_GAP]` ＝ **0** 条）。

### 2.3 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `build/PresentationFramework.Linux/reapply-patches.py` | `3e745f179cf63913` | **`b6a3a24137a77ddf`** |
| `…/PtsHelper.Linux.cs`（生成件） | `pre-t47` | **`79d0ef20d3859811`** |
| `…/WpfLinuxChainProbe.Linux.cs`（生成件，**逐字节未变**） | —— | `856d68514ff328d5` |
| `…/bin/Release/PresentationFramework.dll` | `b6d6575dbca4f714`（6,144,512 B） | **`189e3704cbf4f031`** |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `826c896ebe77e917` | **`4cff4a6d44934757`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `5b7d0ac101673900` | **`1dbea9026dd7d3d7`**（449,336 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `860a3abe4a64f1c5` | **`860a3abe4a64f1c5`（未变；导出面一字未动）** |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | —— | **`4b53c5ca52d6d690`**（**只加尾注**；重编后 `.so` **逐字节同值** ⇒ 该改动对产物零影响，现取实证） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | —— | `so16` 锚 `5b7d0ac101673900→1dbea9026dd7d3d7` ＋ dated 追注 |

---

## §3 ②③ 成对读数（**同一装置 `:231`／同批工具**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`；A 臂 `clicks=[24,23]`；证据全在仓外 `~/tA47-work/*`）

| 腿 | env（相对缺省） | 证据目录 | `pf`／`.so` |
|---|---|---|---|
| **`fix3`（缺省＝本件产物）** | —— | `~/tA47-work/fix3/` | `189e3704cbf4f031`／`1dbea9026dd7d3d7` |
| `pol3`（反极①：拒因不收窄） | `WPF_PTS_QTP_LIVE_NARROW=0` | `~/tA47-work/pol3/` | 同 |
| `pol4`（反极②：换父不发生） | `WPF_FLOAT_REPARENT=0 WPF_PTS_QTP_LIVE_NARROW=0` | `~/tA47-work/pol4/` | 同 |
| （过程腿，链条用） | `fix1`／`pol1`／`fix2`／`pol2` | `~/tA47-work/*` | 同上或 `8d846e…`（诊断件） |

### 3.1 残留计数（逐字，`grep -c '^\[HC-UNHANDLED\]'`）

| 腿 | `[HC-UNHANDLED]` | 那条的实名 |
|---|---|---|
| 改前（**在册** `evidence/app_g1.log` `f051e8674b786533`） | **1** | `ArgumentException: Specified Visual is already a child …` |
| **`fix3`（缺省）** | **0** | —— |
| `pol3`（`…LIVE_NARROW=0`） | **1** | `PtsException … '-10000'`（＋具名 `[FS_PAGE_GAP] … entry=FsQueryTrackParaList`） |
| `pol4`（两条 env 均 `0`） | **1** | `ArgumentException: Specified Visual is already a child …` |

### 3.2 官方判词（现取，`pts-pages-guard.sh --legs <腿目录>`；`fix3` 逐字）

```
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=12 roster=24 domains=pts-declared,dllimport-entry decl=…/PtsHost/Pts.cs:3168
PTS_N1=INFO k=24 file=k24.png fr_sha=791696291d51470b in_empty_set=no fr_ae_boot=220019 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} phase=degraded
PTS_N1=INFO k=23 file=k23.png fr_sha=10d0b9d54e649c10 in_empty_set=no fr_ae_boot=189862 set={…} phase=degraded
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=0 hits=2 min=200 base=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=degraded
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=degraded
PTS_ENFE=INFO total=0 by_name=none allow=none non_allow=none phase=degraded log=…/fix3/app_g1.log log_sha16=1b3371f01dcc1b7f
PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=degraded
```
- **`PTS_GUARD=FAIL` 的 5 条 `fails` 与改前（`T-A46` 在册判词）逐字同** ⇒ **本增量一条未新增、一条未消**（那 5 条是 `phase=degraded` 期的止损绿条件 ＋ 空的 `PTS_GAP` 台账，属既存状态；**不在本件射程**）。
- `PTS_COLORANCHOR`／`PTS_N1`／`PTS_G10_NAME` **三面逐字与改前同**。

### 3.3 帧面（现取，`leg_*.env` ＋ 只看 PNG）

| 腿 | `k24` `fr_sha` | `k23` `fr_sha` | `boot` `fr_sha` | `AE(boot,k24)` |
|---|---|---|---|---|
| 改前（在册） | `791696291d51470b` | `10d0b9d54e649c10` | `b21eb530afd3c66c` | `220019` |
| **`fix3`** | **`791696291d51470b`** | `10d0b9d54e649c10` | `b21eb530afd3c66c` | `220019` |
| `pol3`／`pol4` | 同 | 同 | 同 | 同 |

⇒ **四腿三帧逐字节同值**（`R` 同装置、同 `.so`、同 `.pf` ⇒ 只差 env）。

### 3.4 症状门（现取，四条腿逐格同）

```
LEG k=24 alive=yes app_rc=143 magenta=0 colors=905 ns=HandyControlDemo.UserControl.FlowDocumentDemo ae=220019 ink=480000
NAMED managed_unavail=0 err=- native_gap=0 native_err=-
FIVE_STABLE_G1=YES   DEVICE_REAP state=clean
```

### 3.5 ③ 门禁四件（现取）

```
NM=683 EXPORTS=683                      （逐名 diff 零差异 ＝ 0 行）
PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=1dbea9026dd7d3d7 exports=683   （rc=0）
DEFREG=PASS declared=225 route_ids=225                                                     （rc=0）
  ⚠️ 同趟 **`DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD`** —— 本件**改了 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`**（route 件 `KD`）而**未**同趟 `--emit`；`--emit` 的目标件 `build/MilBridge/tools/defect-registry-declared.tsv` **在本件黑名单内** ⇒ **本件不跑**，如实点名 **`DEFREG_DECLDRIFT keys=KD` 待队长处置**（`DEFREG` 本体仍 `PASS`／`rc=0`）。
REPORTID=PASS files=325 ids=2233 declared=225 glob=build/MilBridge/*report*.md              （rc=0；**含本载体**）
HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 reasons=none                            （本件 `cell=#1` 已同趟追写）
```

---

## §4 ④ 两极化（该红必红）

| 判据 | 缺省（`fix3`） | 反极①（`WPF_PTS_QTP_LIVE_NARROW=0`） | 反极②（`WPF_FLOAT_REPARENT=0`） |
|---|---|---|---|
| `[HC-UNHANDLED]` | **0** | **1**（`PtsException '-10000'`） | **1**（`ArgumentException …already a child`） |
| 具名降级行 | `[FS_PAGE_GAP]` 0 条 | `[FS_PAGE_GAP] rc=-10000 reason=drive-handles-released(page-destroyed) entry=FsQueryTrackParaList` **1 条** | 无 `[FS_PAGE_GAP]`（异常在托管侧抛） |
| `PH.FloatingReparent` | `552` | `6` | **`0`** |
| `PTS_COLORANCHOR`／帧／症状门 | 见 §3 | 逐格同 | 逐格同 |

⇒ **两条反极各回各自的"红"**：反极① 证"**拒因不收窄 ⇒ 那条 `PtsException` 必回**"；反极② 证"**不换父 ⇒ 那条 `ArgumentException` 必回**"。

---

## §5 根因（native 侧）· 下一靶 · 具名 `NOINFO`

1. **根因（现取，身份级）**：`win32_pts.c` 的附属对象台账 `fl_att[].obj_client` 是 **doc 级**（挂在 subtrack 对象上、跨页复用；`+176` 只在**格式窗**内造、本侧**从不**对它发 `+192`）⇒ 同一 `BaseParaClient` 会被**两个页上下文**各 `AddFloatingParaClient` 一次。而 `BaseParaClient` 只有**一个** `_pageContext` 字段（每次 `Arrange` 被覆写）／**一个** `_visual`（惰性 `new ParagraphVisual()`）⇒ "一个客户端活在两页"这一形态**必然**把同一个 `Visual` 交给两个浮层。上游靠"页销毁 ⇒ `Dispose()` ⇒ `RemoveFloatingParaClient`"避免它。
2. **具名下一靶**：`PRECOND-NATIVE-PAGE-SCOPED-ATTACH-CLIENT`（"附属对象客户端按**页代**隔离"）—— 本波**不做**（射程外；且它要动 `fl_att` 的生命周期与 `+192` 回收纪律）。
3. **`NOINFO`（逐条给"消掉需要什么"）**：
   - `NOINFO-HC-UNHANDLED-STACK`：**托管全栈**。发射方是仓外第三方 demo（`DispatcherUnhandledException` → **只记首帧**），且本席加的首次异常探针（`AppDomain.FirstChanceException`）在该运行时上**也只拿到首帧**（`ex.ToString()` 在首异常时刻**未带完整栈**）。⇒ 本件的"抛出点"由**全树 `.Add` 枚举 ＋ 逐 `Add` 身份探针**两路夹出，**不是**栈直读。**消掉需要**：把发射方改成记 `ex.ToString()`（**不在本仓写域**），或本侧自加"托管帧探针"（即在每个 `.Add` 前落点，本件诊断趟用过、已回退）。
   - `NOINFO-PAGES-280`：**为何是 280 页**。拒因收窄后 `[QPD] page=` 去重 280 ⇒ 分页器把 Neptune 文档走完；**未**独立核对"280"是不是该文档的正确页数（`NOINFO`；本件只报"不再中途止"这一**结果**）。
   - `NOINFO-REPARENT-PINGPONG`：**换父是否会在两页间来回搬**。现取（`fix3`）`PH.FloatingReparent=552` 且**无**第二次异常、帧逐字节不变 ⇒ 本趟**没有**可观测的坏后果；但"同一视觉在页 B／页 C 间被反复搬"的**渲染面后果**未单独取证。**消掉需要**：页级客户端隔离（第 2 条）后复取。
   - `NOINFO-REGISTER-EVIDENCE`：**在册证据未换代**。`build/MilBridge/tests/PtsPagesProbe/evidence/` **不在本波写域** ⇒ 其 `[HC-UNHANDLED]=1` 仍是**上代**读数；本件的"改后=0"取自仓外腿目录。**消掉需要**：照 `T-A46` 体例**换代在册证据**（另一趟）。
   - `NOINFO-GUARD-5FAILS`：`PTS_GUARD` 的 5 条 `fails`（占位洋红 ×2／具名行 ×2／`PTS_GAP` 台账空）**不是**本件引入，也**不在本件射程**（它们是 `degraded` 期止损条件 ＋ 空台账）—— 本件**一条未新增、一条未消**。

---

## §6 边界 · 纪律 · 主动披露

1. **写域自证**：`git status --porcelain` 现取只有本件列出的 **10** 件（`src/WpfGfx.Linux.Native/src/win32_pts.c`／`…/src/win32_classification.c`／`…/tools/pts-gap-decl.txt`／`build/PresentationFramework.Linux/reapply-patches.py`／`…/PtsHelper.Linux.cs`／`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`）＋ **本载体** ＋ **先于本件**的 `?? build/MilBridge/tasks-tail2/T-A47.md`。**未动** `build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`upstream/**`／在册 `evidence/**`／相位位；未 `git add/commit/push`。
1b. **一处副作用（如实点名，待队长处置）**：本件改了**route 件** `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（键 `KD`）⇒ `DEFREG_DECLDRIFT=1 keys=KD`。`--emit` 会写 `build/MilBridge/tools/defect-registry-declared.tsv`，该路径**在本件黑名单内** ⇒ **本件不跑**；`DEFREG` 本体仍 `PASS`／`rc=0`（**未新增/未删除任何 `D-G<digits>`**，本件新节只写现值位）。
1c. **第 `29` 条（备份面 ≡ 改动面）自证**：**改动面 ＝ 10 件**（§6-1 逐件）；**备份面 ＝ 10 件** —— 落在仓外 `~/tA47-work/bak/`：写前 `cp -p` 三件（`reapply-patches.py`／`PtsHelper.Linux.cs`／`WpfLinuxChainProbe.Linux.cs`，`pre-t47`）＋ 其余 7 件以 **`git show HEAD:<path>`** 取回前像（现取逐件 `cmp` 与 `HEAD` **相同** ⇒ 前像无污染）。⚠️ 其中 `WpfLinuxChainProbe.Linux.cs` 是**诊断趟的备份**（该件诊断件已回退，**最终内容未变** ⇒ **不在** `git status` 里）—— 如实记为"**多备 1 件**"（备份面 ⊃ 改动面，不是漏备）。逐件前像 `sha16`（现取）：`README.md 2f702e4ec0d8ba69`｜`docs/ROUTES.md 036855f572877c9d`｜`docs/unimplemented.md 217fc0ccf527bc43`｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md 9323a6ed7df9bb39`｜`build/MilBridge/HANDOFF-NEXT.md 63bb1b029cb94915`｜`src/…/win32_classification.c 63252b0cf439c5c1`｜`src/…/win32_pts.c 826c896ebe77e917`｜`…/tools/pts-gap-decl.txt 995009570c490baa`｜`…/reapply-patches.py 3e745f179cf63913`｜`…/PtsHelper.Linux.cs 1f72e29e7c1389d9`。**新建件（本载体）无前像**（如实记）。
2. **`P8` 纪律**：托管侧改动**只**落生成器；`PtsHelper.Linux.cs` 由生成器 `temp+os.replace` 重产（**未直改生成件**）；生成器现取 `[OK] … PtsHelper.Linux.cs（5 处改动，needle 全部命中）`。
3. **`win32_classification.c` 的"零影响"自证**：只加尾注 ⇒ **重编后 `.so` `sha16` 逐字节同值**（`1dbea9026dd7d3d7`）⇒ 该改动**不进产物**（现取实证）。
4. **重活全走槽**：5 趟构建 ＋ 6 趟跑器全在 `~/heavy-slot.sh` 内（`HEAVYSLOT=ACQUIRED/MEMOK/RELEASED`）；进程只按 PID；显示位 `:231`（`waited_ms=0`）；**未跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`。
5. **夹具/过程件全在仓外**：`~/tA47-work/**`（`bak/`／`diag1`／`fix1..3`／`pol1..4`／`*.sh`）；仓内**零过程件**。
6. **跨趟不可比（纪律 31/32）**：`fix3`／`pol3`／`pol4` **同装置／同 `.so`／同 `.pf`／同批工具** ⇒ 只差 env；与**在册证据**（`T-A46` 那代）**跨趟**比较**只报结果**（`[HC-UNHANDLED] 1→0`），**不做减法承重**。
7. **未做的（防被读宽）**：未跑 `--all-arms`（只跑 A 臂 `24,23`）；未跑 `WPF_PTS_DRIVE_PROBE=0`／`WPF_LINEVIS_ONSCREEN=0` 等既有反极性腿（本件只跑本增量的两条 env）；未判相位；未动任何牙本体；未新增 `D-G<digits>`。
8. **`复述位现值位` 随动面**：`docs/ROUTES.md`（新增 `T-A47` dated 落地节）／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`（`cell=#1`）／`src/WpfGfx.Linux.Native/src/win32_classification.c`／登记面 `tools/pts-gap-decl.txt`（`so16` 锚 ＋ dated 追注）—— **只增不改**（现值位数字随动除外）⇒ `PTSGAP=PASS`／`DEFREG_DECLDRIFT=0`。
9. **`HANDOFF-NEXT.md` 的 `cell=#1`**：本趟覆盖面内被改的件 ＝ `src/WpfGfx.Linux.Native/src/win32_pts.c` ＋ `tools/pts-gap-decl.txt` ＋ `src/win32_classification.c`（`bash ~/w153a/bin/infp.sh list` 现取命中）⇒ `inputs_fp` **必然位移** ⇒ 按纪律 28 **同趟**纯 `>>` 追写 `cell=#1`（登记值 ＝ 位移后现值）。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-hcres-impl-report.md | sha256sum | cut -c1-16`）= 900252815b1b6727
