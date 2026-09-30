# `P1-tail2` · `T-A41` · 托管 `FlowDocumentView` 视口驱动（`HOSTED-FSVIEW-VIEWPORT-DRIVE`）＋ native 只读判别器 `D0` —— 实现报告（**判决：驱动已落 ∧ 前提被 `D0` 证伪 ∧ 判据 ② 未达**）

- **读时**：`2026-09-30T18:5x–19:0x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=140265d48f7c6e993e25ce370f9d35147339138d`（现取，**未换代**）。
- **改前件备份（仓外 `~/tA41-work/bak/`，`cp -p` 取在**任何写之前**）**：`win32_pts.c.bak`（**`1d8e3cac55cc473e`**）／`libwpfwin32.so.bak`（**`606dad49ae7b34a1`**）／`exports.txt.bak`（`860a3abe4a64f1c5`，683 行）／`pts-gap-decl.txt.bak`（`9e11af5fc8901ca3`）／`reapply-patches.py.bak`（`0f9aec35f8e61582`）／`FlowDocumentView.Linux.cs.bak`（`ecb0263b200c18dc`）／`PresentationFramework.Linux.csproj.bak`（`e22a7457dc4a8010`）／`PresentationFramework.dll.bak`（`1757d610a687777c`）＋ 六个复述位件。
- **只改**：`build/PresentationFramework.Linux/reapply-patches.py`（生成器 edits ＋ 落盘改 `temp+rename`）／由它重产的 `build/PresentationFramework.Linux/FlowDocumentView.Linux.cs`（生成件）／`src/WpfGfx.Linux.Native/src/win32_pts.c`（**只读**判别器 `D0`）／**随动** `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`so16` 重锚）／**复述位**（`README.md`／`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`）／**新建**证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2h/`（6 腿）／本载体。
- **黑名单遵守**：未动 `build/*.Linux/**` 的**其它**生成件（`PtsCache.Linux.cs` 被生成器同趟重写 ⇒ **已按其 `HEAD` 字节还原**，见 §5.3）／未动 `build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）；**未跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`；未改相位；未 `git add/commit/push`。
- **重活**：**3 趟构建**（native×1、托管×2）＋ **2 趟跑器**（共 **6 条腿**），全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=ACQUIRED/MEMOK/RELEASED` 可见；托管两趟 `held=30s`／`26s`）；进程只按 PID；显示位 `:231`（装置自取；**本席六腿逐趟 `DEVICE_REAP state=clean`** ⇒ 本席无残留显示位/进程）；禁 `sleep` 轮询；写前 `cp -p` 备份；模式守恒。⚠️ 如实记：`/tmp/.X11-unix` 现取 ＝ **`X0`／`X1`／`X10`** —— `X10` ＋ 一个 `xfwm4`（pid `398855`，起于 `2026-09-29 23:32`）**非本席产物**（时间早于本浪 20 小时；本席腿全在 `:231`）且**不在本浪写域** ⇒ **只报不动**（纪律 3：进程只按 PID 收）。
- **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm`／`grep -c`／只读 `python3`＋`PIL` 解 PNG／`bash build/MilBridge/tools/{pts-pages-guard,pts-gap-count-check,defect-registry-check,report-id-domain-check}.sh`）；`P1-tail2-visual-recon.md`（`T-A40`）／`P1-tail2-subgeom-impl-report.md`（`T-A39`）／`P1-tail2-attachcontent-impl-report.md`（`T-A37`）**只作对照**，其读数**一条未抄**。

---

## §0 结论速览（自包含）

1. ✅ **两件都落了**：① **native 只读判别器 `D0`**（`[FSQVP]`，`win32_pts.c`，**零行为变化**：只多一条具名 stderr 行，不动任何出参／不做导出）—— 判「页轨枚举**经由哪条支**（`arrange`／`visual`／`viewport`／`unknown`）」；② **托管侧视口驱动**（生成件 `FlowDocumentView.Linux.cs`，由生成器 `reapply-patches.py` 的 E7／E8 落）＋ 只读台账 `[FSVIEW]`；`WPF_FSVIEW_VIEWPORT_DRIVE=0` ⇒ **逐字回上游入参**（反极性腿可在**同一产物**上撤掉驱动点）。
2. 🔴 **`A40` 的核心判定被 `D0` 证伪**：`A40 §3` 断言「断点 ＝ **视口支整条未发生**」（预测 `via=viewport` ＝ 0）。**现取（6 腿）**：`via=viewport` ＝ **78／83／83／166／170／171 次（≠ 0）**、`via=arrange` ＝ 78／83／83／166／170／171、`via=visual` ＝ 81／86／86／169／173／174、`via=unknown` ＝ 2 ⇒ **视口支一直在跑**（`PtsHelper.UpdateViewportTrack` 被走到；宿主段 `TextParaClient.UpdateViewport` 每轮恰 1 次）。判别器**不是常绿**：三标签**可对账**（`Σvia = [FSPARALIST-FILL] − 1`，差 1 ＝ 应用被 `SIGTERM` 收时**未收口的末轮**）且**自洽性反例 ZERO**（`via=arrange` 必带 `figobj=1`、`via=visual` 必 `fsqll=1 ∧ figobj=0`、`via=viewport` 必 `att=1 ∧ figobj=0 ∧ fsqll=0`）。
3. 🔴 **驱动在本页上成空转（如实，且这是判据 ② 未达的直接原因）**：`[FSVIEW]` 现取 `ArrangeOverride` **确被调用**（2 次：`doc=1 suspend=0 scroll=1`），`viewport=(0,0,638.4,366.72)` DIP、`DocumentPage.Size=39.81x39.17` DIP（**页盒远小于可见视口**）、`visbounds=empty`（本移植 `VisualTreeHelper.GetDescendantBounds` 取不到）⇒ **`handed == viewport`**（驱动**一个字节都没改**）。⇒ **驱动腿与反极性腿（`=0`）除 `drive=` 一个字段外逐格相同**，本页**分辨不出**驱动（如实记，见 §4）。
4. 🔴 **判据 ② 未达**：`[FSQLL] cLines=1` **6 腿恒 0**；`k=24` 帧 `1487caf78fd88886`／`colors=724`／`GhostWhite=29637 px` 与改前（`T-A36`／`T-A37`／`T-A39` 在册）**逐字节相同**，`Beige`／`DarkGreen`／`LightGoldenrodYellow` **仍 0 px** ⇒ `PTS_COLORANCHOR=FAIL hits=1 expect_min=200 expect_hits=2`（guard 判词逐字见 §3）。
5. ✅ **本趟把真断点定住了（可算、可复核）**：`TextParaClient.cs` 的 `IntersectsWithRectOnV`（内容锚：`return ((_rect.v) <= (rect.v + rect.dv)) && ((_rect.v + _rect.dv) >= rect.v);`）**只看 v 维**；内容段 `_rect.v/dv` 由 `PtsHelper.ArrangeParaList(rcTrackContent = 子轨 fsrc, dvrUsed)` 定（`PtsHelper.cs:169-177`），而子页坐标里 `viewport.v` 被 `FigureParaClient.UpdateViewport` 的 `viewport.v - ContentRect.v` 平移（`FigureParaClient.cs:137-143`），`ContentRect.v` 由本侧**声明的**附属对象盒（`FsQueryAttachedObjectList` 的 `fsrc.v=20000` 文本 dpi）派生 ⇒ **要开该门须让视口伸到 ≈`20000` 文本 dpi ≈ `6400` DIP**（＝当前可见高的 **17×**）⇒ 属 **native 几何**，而 `A40 §5.1` **明禁**本浪改几何（"不得为让 `[FSQLL]` 出现而改几何／`fsupdinf`／`fUpdateInfoForLinesPresent`"）⇒ **该靶在本浪内结构性不可达**。
6. ✅ **症状门无回归 ＋ 帧面成对**：6 腿 `alive=yes app_rc=143 failfast=0 unrec=0 magenta=0 colors=724 ink=480000 ns=…FlowDocumentDemo`、`[HC-UNHANDLED]=1`（**未涨**）、`boot.png=b21eb530afd3c66c`（四色全 0、`LightGray` 不入集）；`k24`／`k23` 帧 6 腿**同值**（`1487caf78fd88886`／`10d0b9d54e649c10`）、`fr_ae_boot=220546`／`189862` 逐格相同。
7. ✅ **门禁（④）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **683**（逐名 `diff` 零差异，**无导出增删**）；`PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=dd9865c38e18ed81 exports=683`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0，`DECLDRIFT_KEYS=KD` ⇒ 见 §6）；`REPORTID=PASS files=321 declared=225`（rc=0；件数 `320 → 321` ＝ 本载体；⚠️ **`ids` 是"报告件集合上的派生量"且本载体自己就在该集合里 ⇒ 本席不写死它**（写死必漂，`D-G125` 同族）：现取命令与输出见 §6）；生成器**幂等**（连跑两次生成件 `sha16` 相同：`7b32ca403752c703`）。

---

## §1 改动（逐处）

### 1.1 native `D0`（`win32_pts.c`，**只读**；`numstat 69 0`，纯增）
- **状态机**（置于 `g_pts_qpd_prev_page` 之后）：`wpf_pts_qvp_begin()/end(why)` ＋ `g_pts_qvp_{arrange,visual,viewport,unknown}` 四个计数；**轮** ＝ 一次**页轨枚举**成功（`FsQueryTrackParaList` 的**页轨**支，`*cParaDesc = cParas` 之后）起，到**下一次页轨枚举**或**下一次 `FsQueryPageDetails` 成功**为止；`end()` 按**下游签名**贴**唯一**标签并打印一行：
  ```
  [FSQVP] via=arrange|visual|viewport|unknown round=N page=0x… closed_by=next-qpd|next-page-track-enum
          fsqll=… att=… figobj=… n_arrange=… n_visual=… n_viewport=… n_unknown=…
          NOINFO=viewport-branch-callsite(inference:adjacent-events+page-query-state)
  ```
- **三处**签名置位（各 ＋1 行，均在**成功路径**）：`FsQueryLineListSingle` 成功 ⇒ `fsqll`；`FsQueryAttachedObjectList` 成功 ⇒ `att`；`FsQueryFigureObjectDetails` 成功 ⇒ `figobj`。
- **为何不是直读（写死在代码注释里）**：`BaseParaClient.UpdateViewport` 是**托管内部虚方法、无 P/Invoke**，`exports.txt` 里 `updateviewport` 命中 **0** ⇒ native **直读不到调用者**；三支的 native 面（`FsQueryTrackDetails`×1 ＋ `FsQueryTrackParaList`×1）**逐字节相同** ⇒ 本判别器是**具名推断**（行尾 `NOINFO=` 已标注），其**反极性**靠"三标签可对账 ＋ 自洽性反例 ZERO"承担（§4.2）。
- **零行为变化**：不动 `cParas`／`rg[]`／任何出参；不新增导出；成功率／症状门逐格不变（§2）。

### 1.2 托管视口驱动 ＋ 只读台账（**生成器 E7／E8** ⇒ 生成件）
- `FlowDocumentView.Linux.cs`（生成件，**不直改**；`reapply-patches.py` 的 `FDV_E7_*`／`FDV_E8_*`）：
  - `ArrangeOverride` 里把**唯一**交给 formatter 的入参换名：
    `Rect fsviewViewport = WpfLinuxFsViewDrive.Effective(viewport, safeArrangeSize, _formatter, _pageVisual);`
    ⇒ `WpfLinuxFsViewDrive.Report(…)` ⇒ `try { _formatter.Arrange(safeArrangeSize, fsviewViewport); } catch (System.Exception e) { ReportException(...); throw; }`（**`throw;` 保留栈** ⇒ 只多一行留痕，不改异常行为）。
  - `WpfLinuxFsViewDrive`（文件尾，命名空间内新类）：`Enabled`（`WPF_FSVIEW_VIEWPORT_DRIVE`，**缺省开**、只有显式 `"0"` 关；取一次缓存）／`Effective`（关 ⇒ **原样返回上游 `viewport`**；开 ⇒ `可见区 ∪ Rect(0,0,arrangeSize) ∪ Rect(0,0,DocumentPage.Size) ∪ GetDescendantBounds(_pageVisual)`，空/非有限 ⇒ 用后三者）／`VisualBounds`（读不到 ⇒ `Rect.Empty`，**绝不当 0/当整页**）／`Report`（`[FSVIEW]` 行）／`ReportException`。
- **落盘原子化（`P8` 同类纪律）**：生成器新增 `_write_atomic()`，`FlowDocumentView.Linux.cs`／`PtsCache.Linux.cs`／`csproj` **全部**改走 `temp + fsync + os.replace`。
- **驱动**只动**这一个入参**：**不**碰 native 几何、**不**改 `fsupdinf`／`fUpdateInfoForLinesPresent`、**不**删／**不**放宽任何 `Invariant.Assert`。

### 1.3 逐件 sha16 ＋ `numstat`（现取）
| 件 | 改前 | 改后 | `numstat` |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `1d8e3cac55cc473e` | **`af6d534194bccd76`** | `69 0` |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（构建生成件） | `606dad49ae7b34a1` | **`dd9865c38e18ed81`**（449248 B） | —— |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（构建生成件） | 683 行 | **683 行**（`cmp` 未变） | —— |
| `build/PresentationFramework.Linux/reapply-patches.py` | `0f9aec35f8e61582` | **`9a9a523f79823228`** | `241 5` |
| `build/PresentationFramework.Linux/FlowDocumentView.Linux.cs`（生成件） | `ecb0263b200c18dc` | **`7b32ca403752c703`** | `196 3` |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `1757d610a687777c` | **`52cf1b0012667dd0`** | —— |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `9e11af5fc8901ca3` | （`so16=` 重锚） | `1 1` |

**构建（现取）**：`bash build-shim.sh --symbols` ⇒ `NATIVE_RC=0`（既有 `-W*` 警告与本增量无关；本增量**不新增**警告）｜`dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -c Release -m:1` ⇒ **0 警告 0 错误**（`00:00:29.83`）｜`sync-applocal.sh` ⇒ `PASS … drift=0`（六腿逐腿 `POSTSHIM == authority`）。

---

## §2 成对读数（**同一装置 `:231`／同批工具**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`；A 臂 `clicks=[24,23]`）

| 腿 | 驱动 | `.so` | `pf` | 证据目录 |
|---|---|---|---|---|
| `base`（**方案 1**） | **off** | `dd9865c38e18ed81` | `4f5304aaee3e25e1` | `…/evidence-tail2h/base/` |
| `drv1`／`drv2`（**方案 1**，两独立样本） | on | 同 | 同 | `…/drv1/`／`…/drv2/` |
| `base2`（**方案 2**，反极性腿） | **off** | 同 | **`52cf1b0012667dd0`** | `…/base2/` |
| `drv3`／`drv4`（**方案 2**，两独立样本） | on | 同 | 同 | `…/drv3/`／`…/drv4/` |

### 2.1 `D0`（`[FSQVP]`）＋ `[FSVIEW]` ＋ 内容段行查询（**逐腿现取**）
| 量 | `base` | `drv1` | `drv2` | `base2` | `drv3` | `drv4` |
|---|---|---|---|---|---|---|
| `via=arrange` | 170 | 171 | 166 | 78 | 83 | 83 |
| `via=visual` | 173 | 174 | 169 | 81 | 86 | 86 |
| **`via=viewport`** | **170** | **171** | **166** | **78** | **83** | **83** |
| `via=unknown` | 2 | 2 | 2 | 2 | 2 | 2 |
| `Σvia` vs `[FSPARALIST-FILL]` | 515 / 516 | 518 / 519 | 503 / 504 | 239 / 240 | 254 / 255 | 254 / 255 |
| **自洽性反例** | **0** | **0** | **0** | **0** | **0** | **0** |
| `[FSQLL] cLines=1`（**内容段**） | **0** | **0** | **0** | **0** | **0** | **0** |
| 内容段 `[FSQTD] cLines=1` | 340 | 342 | 332 | 156 | 166 | 166 |
| `[FSPARALIST-FILL-SP]` | 340 | 342 | 332 | 156 | 166 | 166 |
| `[FSQLL]` 直方图 | `8×342,6×342,2×1` | `8×344,6×344,2×1` | `8×334,6×334,2×1` | `8×158,6×158,2×1` | `8×168,6×168,2×1` | 同 `drv3` |
| `app_g1.log` `sha16` | `cee542a18166911a` | `a37ddc50b6e58aa4` | `e2e9adf7b626a07a` | `ac210a6af5d76bf8` | `0c1dcd56a4547c53` | `eb987b6aaa7be158` |

**`[FSVIEW]` 逐字样本（`drv3`，两行全给）**：
```
[FSVIEW] site=ArrangeOverride doc=1 suspend=0 scroll=1 drive=on arrange=638.4x366.72 viewport=0,0,638.4,366.72 handed=0,0,638.4,366.72 page=39.81x39.17 visbounds=empty NOINFO=fsview-window(managed-side-readonly-ledger)
[FSVIEW] site=ArrangeOverride doc=1 suspend=0 scroll=1 drive=on arrange=394.56x283.2 viewport=0,0,394.56,283.2 handed=0,0,394.56,283.2 page=12.56x1.92 visbounds=empty NOINFO=fsview-window(managed-side-readonly-ledger)
```
⇒ **`handed == viewport`**（两趟 arrange 都是）⇒ **驱动零效果**；`ArrangeOverride` **确被布局系统调到**（`A40 §6` 的 `NOINFO-FSVIEW-ARRANGE-TRIGGER` **消掉**：2 次进场、`doc=1 suspend=0 scroll=1`）。
⚠️ **计数不可当"稳定量"**：同一产物上 `base2`(78) 与 `drv3/drv4`(83) 差 5 次、`base`(170) 与 `base2`(78) 差 92 次 ⇒ **逐趟时长/点击节拍不同**（本件**不作减法**，也不把次数当"机制"证据）；**唯一稳定读数是"≠ 0"**。

### 2.2 症状门 ＋ 帧面（逐腿现取）
| 腿 | `alive` | `app_rc` | `failfast` | `unrec` | `magenta` | `colors`(k24) | `ink` | `ns`(k24) | `[HC-UNHANDLED]` | `k24` `fr_sha` | `fr_ae_boot` | `k23` `fr_sha` |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `base` | yes | 143 | 0 | 0 | 0 | 724 | 480000 | `…FlowDocumentDemo` | 1 | `1487caf78fd88886` | 220546 | `10d0b9d54e649c10` |
| `drv1` | yes | 143 | 0 | 0 | 0 | 724 | 480000 | 同 | 1 | `1487caf78fd88886` | 220546 | `10d0b9d54e649c10` |
| `drv2` | yes | 143 | 0 | 0 | 0 | 724 | 480000 | 同 | 1 | `1487caf78fd88886` | 220546 | `10d0b9d54e649c10` |
| `base2` | yes | 143 | 0 | 0 | 0 | 724 | 480000 | 同 | 1 | `1487caf78fd88886` | 220546 | `10d0b9d54e649c10` |
| `drv3` | yes | 143 | 0 | 0 | 0 | 724 | 480000 | 同 | 1 | `1487caf78fd88886` | 220546 | `10d0b9d54e649c10` |
| `drv4` | yes | 143 | 0 | 0 | 0 | 724 | 480000 | 同 | 1 | `1487caf78fd88886` | 220546 | `10d0b9d54e649c10` |

`boot.png` **6 腿同值** `b21eb530afd3c66c`（`colors=386`）。⇒ **6 腿逐格相同**（含驱动开/关两态）⇒ **零行为回归**，且**驱动在本页零像素效果**。

### 2.3 帧面四色锚（本席自算，只读 PNG；`PTS_COLORANCHOR` 的锚集：`GhostWhite=248,248,255`／`Beige=245,245,220`／`DarkGreen=0,100,0`／`LightGoldenrodYellow=250,250,210`，`LightGray` **不入集**）
| 帧 | 腿 | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `hits(≥200px)` | `ncolors` | `sha16` |
|---|---|---|---|---|---|---|---|---|
| `boot`（活锚基线） | 6 腿同 | **0** | **0** | **0** | **0** | 0 | 386 | `b21eb530afd3c66c` |
| **`k24`** | `base`/`base2`/`drv1..4` | **29637** | **0** | **0** | **0** | **1** | 724 | **`1487caf78fd88886`** |
| `k23` | 同上 | 0 | 0 | 0 | 0 | 0 | 636 | `10d0b9d54e649c10` |

`k24`／`k23` 帧 `sha16` **与改前（`T-A36`／`T-A37`／`T-A39` 在册同值）逐字节相同** ⇒ 本增量**零像素**。⚠️ **不得把空白读成绿**：`GhostWhite` 是 `Figure`/`Floater` 的 **`Background`**（`DrawBackgroundAndBorder` 所绘），**不是**"内容真绘出"；三内容色全 `0`。

---

## §3 验收逐条（对 `T-A41` ③；**逐条带反极性**）

| # | 判据 | 现取 | 判 |
|---|---|---|---|
| **①** | `A40 ④` 的 `D0–D3` 逐条 ＋ 反极性 | 见下 | **`D0` 成立且证伪前提；`D1` 未达；`D2`／`D3`（成对部分）成立** |
| **②** | **关键**：`k24` 四具名色各 ≥200px；视口链接现取（链到达 0→>0） | 四色 `29637/0/0/0`（`hits=1`）；`via=viewport` **78–171（≠0，且**基线就**≠0）**；`[FSQLL] cLines=1` **恒 0** | ❌ **未达**（四色）／⚠️ **"0→>0" 不成立**（本来就不是 0）
| **③** | 帧面成对（`sha16`／`AE`；不得把空白读成绿） | §2.2／§2.3（6 腿同值；`boot` 四色全 0；两独立样本 `k24` 同值） | ✅（**成对成立**；但"`k24` **必须变**"未成立 ⇒ 如实记） |
| **④** | 生成器重产 == 现盘（幂等）；`nm==exports`；`PTSGAP=PASS`；`DEFREG`／`REPORTID` rc=0 | 幂等 ✓（连跑两次生成件 `7b32ca403752c703`）；`nm==exports==683`（逐名零差异）；`PTSGAP=PASS`；`DEFREG=PASS`／`REPORTID=PASS`（各 rc=0） | ✅ |
| **⑤** | 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）成对 | §2.2（6 腿逐格同） | ✅ |

- **`D0`（分流/诊断）**：判据要求「`via=viewport` ≥ 1（且 `[FSQLL] cLines=1` **首次**出现）」＋「**若 `via=viewport` 仍为 0 ⇒ 本件断点判定证伪**」。**现取**：`via=viewport` **≠ 0（6 腿全非零）** ⇒ **`A40` 的断点判定被证伪**；而 `[FSQLL] cLines=1` **仍 0** ⇒ 真断点在**该支之内**（`:3371` 门，§0.5）。
  **反极性（必红腿）**：① **假判别器必红** —— 若 `via=viewport` 无条件打印，则 `via=arrange` 计数会塌成 0 而 `figobj` 事件仍在 ⇒ **自洽性检查当场点名**（本件现取 6 腿**反例 ZERO**，即该检查在真判别器上**不空转**；检查口径：`via=arrange ∧ figobj=0`／`via=visual ∧ ¬(fsqll=1 ∧ figobj=0)`／`via=viewport ∧ ¬(att=1 ∧ figobj=0 ∧ fsqll=0)` 三类任一即计数＋1）。② **撤驱动** ⇒ 见 §4。
- **`D1`（余 3 具名色各 ≥200px）**：❌ **未达**（`hits=1`）。**反极性**：驱动态与撤回态**同值**（`hits=1`）⇒ 「驱动一动色就齐」**不成立**；且 `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（**严禁**把 `k=24` 的锚推广到 `k=23`）。
- **`D2`（baseline 仍全 0／活锚）**：✅ `boot.png` 四色 **6 腿全 0**、`LightGray=44`（**不入集**）。
- **`D3`（帧面成对 ＋ 不得把空白读成绿 ＋ 失败必留痕）**：✅ **成对**（两独立样本 `k24` 同值；`k24≠k23`；差异分量**不涉及内容区**——**本增量零像素**）；`[HC-UNHANDLED]` **恰 1**（未涨）；`[FSVIEW]`／`[FSQVP]` 使「`ArrangeOverride` 有没有被调」与「页轨枚举经由哪条支」**首次可直读**；反极性腿与驱动态**逐格可辨**（`drive=on|off` 字段 ＋ 缺省不设时 `=on`）。⚠️ **未成立的部分**：`A40` 要求「`k24` 帧 `sha16` **必须变**」——**没变**（如实记；因为驱动零效果）。

**`guard` 判词逐字（现取，`drv3`／`base2` 相同）**：
```
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=29637 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=1 expect_min=200 expect_hits=2 baseline=… phase=degraded reason=declared-color-anchor-absent
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=degraded
PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),leg24-color-anchor-absent(hits=1<2,…),native-ledger-absent(PTS_GAP n=0) … direction=in-file phase=degraded
```
（`PTS_GUARD=FAIL` 的六项**全部为改前既有状态**，`guard-degraded.txt` 逐字落证据目录；本增量**不新增**任何一项。）

---

## §4 反极性（**同一 `.so` ＋ 同一跑器 ＋ 同一装置**，只差**一个 env**：`WPF_FSVIEW_VIEWPORT_DRIVE`）

| 判据 | 驱动 on（`drv1..4`） | **显式 `=0`（`base`／`base2`）** | 改前（`T-A39` 现场） |
|---|---|---|---|
| `[FSVIEW] drive=` | `on` | **`off`** | ——（无此面） |
| `handed` | `0,0,638.4,366.72` | **同值** | —— |
| `via=viewport` | 83–171 | **78–170**（**≠ 0**） | 未测（`NOINFO`） |
| `[FSQLL] cLines=1` | 0 | 0 | 0 |
| `k24` 帧／`colors`／`hits` | `1487caf78fd88886`／724／1 | **同** | **同** |
| 症状门 | 逐格同 | **逐格同** | 逐格同 |

🔴 **如实披露（本件的反极性**不是**"驱动有效"那种）**：因为 §0.3 的**驱动零效果**（`handed == viewport`），**本页上"撤驱动"这一极是退化的** —— 两态除了 `drive=` 字段**逐格相同**。⇒ **本件不能声称"撤掉驱动 ⇒ `via=viewport` 回 0"**（它本来就不是 0）。**能成立的反极性只有两条**：① **判别器自身的状态相关性**（三标签分布 ＋ 自洽反例 ZERO，§3 `D0`）；② **`WPF_FSVIEW_VIEWPORT_DRIVE=0` 确实把驱动点整个摘掉**（`handed` 由 `Effective()` 直返上游 `viewport`；证据＝`drive=off` 行 ＋ 逐格同值，**零假值**）。
**最便宜的真反极性腿（本件只登记、不跑）**：把 content 段的**子页轨几何**（native `FsQuerySubtrackDetails` 的 `fsrc.v`）临时改成覆盖任意有限视口 ⇒ `via=viewport` **不变**而 `[FSQLL] cLines=1` **必变**（⇒ 判"门被求值"；`T-A39` 的仪器 B 只改了 **v 的一半**且**未改 `dvrUsed` 之外的 u**，本件据此怀疑其仪器 B **未真正驱动到门**，列为 `NOINFO`，**不据此推翻 `T-A39` 的读数**）。

---

## §5 边界 · `NOINFO` · 主动披露

1. **`NOINFO`（逐条给"消掉需要什么"）**：
   - `NOINFO-VIEWPORT-BRANCH-CALLSITE`（承 `A40`）—— **本轮具名消掉一半**：`via=` 面已落地、三标签分布＋自洽性可现取；**仍未消**的是"**同轮内谁调了它**"的**逐次**归属（native 只见下游签名）。**消掉需要**：托管侧只读调用计数（`PtsHelper` 三支各打一条具名行 ⇒ 要改 `upstream/**` 或加 `.Linux.cs` 替身，**本浪写域外**）。
   - `NOINFO-FSVIEW-ARRANGE-TRIGGER`（承 `A40`）—— ✅ **已消**（`[FSVIEW]` 直读：2 次进场、`doc=1 suspend=0 scroll=1`）。
   - `NOINFO-DRIVE-EFFECT-UNPROVEN`（**本件新读出**）：驱动"是否**能**改视口"在本页**证不出**（`handed == viewport`）；且 **`VisualTreeHelper.GetDescendantBounds` 在本移植返回 `Rect.Empty`**（`visbounds=empty` 6 腿）⇒ 该项**取不到**（**不是 0、不是整页**）。**消掉需要**：一个"页盒 > 可见区"的页面/窗口（或把该项换成有源的量）。
   - `NOINFO-CONTENT-VIEWPORT-VALUES`（承 `T-A38`/`A39`）—— **仍未消**：门的两个操作数（`_rect.v/dv` 与 `viewport.v/dv`）无托管侧直读；本件只给**算得的**必要条件（视口须伸到 ≈`6400` DIP）。
   - `NOINFO-FSQLL-CALLER-DISCRIMINATION`／`NOINFO-SUBPAGE-GEOMETRY-SEMANTICS`／`NOINFO-attached-object-geometry-layout`／`NOINFO-subtrack-para-geometry`：**逐字承** `T-A37`/`A38`/`A39`，本件**未消**。
   - `NOINFO-`**旧仪器 B 是否真生效**（`T-A39` 的 gate-probe）：本件**未复算**那两代 `.so`（在册证据已够用）；**不据此下任何结论**。
2. **本增量的射程（写死，防被读宽）**：本增量交付的是 **① 一个只读判别器（消掉"视口支有没有跑"这一问）＋ ② 一个托管侧视口驱动点（可开可关）＋ ③ 一次对 `A40` 靶的证伪与真断点定位**。它**不是**"排版打通"、**不是**"内容真绘出"、**不是**"色锚转绿"；`[HC-UNHANDLED]=1` 的残留（`FsQueryTrackParaList` 的 `drive-handles-released(page-destroyed)` 诚实拒绝）**未动**。
3. 🔴 **黑名单边界的如实披露（两处生成器副作用，均已复原）**：
   - 跑 `reapply-patches.py` 会**重排** `PresentationFramework.Linux.csproj` 里**其它车道**注入的补丁块（生成器把 `BEGIN..END` 块摘掉再插回，而**他者**的块落在该区间内）⇒ 现盘 `csproj` 相对备份**内容集合完全相同**（`sort` 后 `diff` **零差异**，1562 行）但**顺序变化**。⇒ 本席**已把 `csproj` 按备份逐字节还原**（`cmp` 通过；`git status` 不再显示它）。
   - 生成器同趟重写 `build/PresentationFramework.Linux/PtsCache.Linux.cs`（**非本浪写域**）；因本席曾把生成件头模板的措辞改宽再**撤回**，该件现已**回到 `HEAD` 字节**（`git diff` 零差异）。
4. **方案数 ＝ 2 ＋ 1 条反极性腿**（在 `T-A41` ② "最多 3 种方案" 内）：**方案 1** ＝ `D0` ＋「视口 ∪ 整页」驱动；**方案 2** ＝ 再加「∪ 已实现视觉子树范围」（`visbounds` 现取 `empty` ⇒ 仍为零效果）。⇒ 按 ② 的"**失败即如实报停止（允许判合法终点）**"收口：**判据 ② 未达**，且**`A40` 指认的靶被证伪** ⇒ 本件的合法产出是**具名的下一靶**（§0.5）＋**可复算的 6 腿成对基线**＋**两件只读面（`[FSQVP]`／`[FSVIEW]`）**。
5. **未做的（防被读宽）**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；**未**新增任何 `D-G<digits>` 登记编号；未跑 `--all-arms`；**未改** `docs/unimplemented.md` 与 `src/WpfGfx.Linux.Native/src/win32_classification.c` —— **理由有机器证**：本趟**移动的字段只有 `so16`**（`tool/dead/artifact/ops/impl/exports` **逐格未动**），而这两件**不持"现值位"格**（`pts-gap-count-check.sh` 现取**无 `SITE-DRIFT`**，只印 `SITE-HISTORICAL-ONLY samples/WpfFeatureProbe/KNOWN-DEFECTS.md … hist=…` ＋ `PTSGAP_HISTORICAL=n=2（自引旧代工件的**历史行**命中数：**不参与现值判定**）` ⇒ 现值位**已在** `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` 的 `PTSGAP-DECL:` 行被本席更新）；且 `win32_classification.c:52` 的「可操作 64／实现口径 67」与现取 `ops=64 impl=67` **逐数相符**（改它还会改 `.so` 的 `sha16` ⇒ **不必**）。**⇒ 这两件的"复述位现值位"结论 ＝ `NOINFO(reason=no-current-value-cell-moved)`，不是"漏改"。**
6. **跨代／跨装置不可比（纪律 31/32）**：§2 的"改前"列取自 `T-A36`/`T-A37`/`T-A39` 的**在册**证据（**同 `.so` 代** `606dad49ae7b34a1`）⇒ 只报**结果**（帧同值等），**不做减法**承重；六腿**同一装置**（`:231`）＋**同批工具**（§2 三个 `sha16`）。
7. **侧效（如实披露，未进仓）**：`~/tA41-work/`（`bak/` 改前件 ＋ `build-all.sh`／`scheme2.sh`／`legs.sh`／`summ.py`／`frames.py`）；仓内应用安装**一字未动**（`sync-applocal.sh --check … drift=0` 逐腿现取）。

---

## §6 落盘后复跑（现取；`④` 的成对读数）
- `bash build/MilBridge/tools/defect-registry-check.sh` ⇒ **`DEFREG=PASS declared=225 route_ids=225`**（rc=0）＋ **`DEFREG_DECLDRIFT_KEYS=KD`** —— 🔴 **这是"改了 route 件"的**预期后果**（本趟改了 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的现值位行）⇒ 按纪律 15／`D-G131`：**`build/MilBridge/tools/defect-registry-declared.tsv` 必须由主控同趟重发**（本席**不**改声明表：它不在本浪写域，且本增量**未新增/未删除任何编号**——`declared=225` 不变；`ids` **不写死**（见下条：它是报告件集合上的派生量、本载体自己就在集合里））。
- `bash build/MilBridge/tools/report-id-domain-check.sh` ⇒ **`REPORTID=PASS files=321 declared=225`**（rc=0；落盘前 **`files=320`** ⇒ 本载体 ＋1 件。⚠️ **`ids` 不写死**：它是"报告件集合上的派生量"、而**本载体自己就在该集合里** ⇒ 任何一次改字都会动它（现取一次是 `2232`，再改字必再漂）⇒ 本席只给**命令**与 `PASS`／`files`／`declared` 三格，并声明：本载体引用的编号**全部在册**（同趟 `DEFREG=PASS` 复核，`declared=225` 未变）。）。
- `bash build/MilBridge/tools/pts-gap-count-check.sh` ⇒ **`PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=dd9865c38e18ed81 exports=683`**（rc=0）。
- `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | wc -l` ＝ **683** ＝ `wc -l bin/exports.txt` ＝ **683**（逐名 `diff` **零差异**）。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-fsview-impl-report.md | sha256sum | cut -c1-16`）= c8657849cc6db5fb
