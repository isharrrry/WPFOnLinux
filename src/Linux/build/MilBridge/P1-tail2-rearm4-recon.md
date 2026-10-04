# P1-tail2 · `T-A34` · 重取臂④ ＋ 相位翻转评估 —— 两页是否真出内容／相位能否翻（测量/侦察件）

> **本件 `T-A34`（测量/侦察子代理）交付**。**写域**：新建新鲜证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2d/`（**新建，未覆盖在册 `evidence/` 与他代 `evidence-tail2*/`**；第二独立样本落其**子目录** `evidence-tail2d/sample2/`）＋ 本载体。**未碰** `src/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`／在册与他代证据目录；**未改相位**（本任务只评估）；未 `git add/commit/push`。私有工作区 `W=/home/links-dev/tA34-work`（**仓外**，应用目录 `$W/app` 由 `sync-applocal.sh` 灌成权威五件）。
> **口径引用（不是证据）**：队长**裁定二十**（`P1-ptsname-result.md`，内容锚「裁定二十（承 `t114` 回执）」）／**裁定二十一**（同件，「裁定二十一（承 `t117` 回执）」）／**裁定三十五**（同件，「裁定三十五（承 `t142` 全面回执）」）／**裁定三十六**（同件，「裁定三十六（承 `t146` 全面回执）」）作口径；另**旁引**裁定三十八 (a)（撤销三十六 (b) 常开）／三十九（帧面冻结线）。**它们的读数一条未抄** —— 本件所有读数**现取**（两趟腿 ＋ 守卫现跑）。`T-A33` 载体（`P1-tail2-backfill-impl-report.md`）**只作对照**，其读数逐格由本件现取复算，**未抄**。
> **行号纪律**：本件行号**仅本次有效**；引件一律给内容锚。

---

## §0 结论速览（自包含）

1. **重取说明**：在**现 `.so` `04f6d354b0a71888`**（现取，＝ `T-A33` 落地值）上跑**两页真腿**（`k=24`／`k=23`，A 臂，`run-pts-pages-legs.sh`，私有 `W=/home/links-dev/tA34-work`）：**主样本**（换输出目录 `evidence-tail2d/`、显式显示位 `:235`）＋ **第二独立样本**（子目录 `sample2/`、显示位 `:236`）。两趟各 `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`。
2. ✅ **独立复现 `T-A33` 的核心新事实（换目录、换显示位）**：占位调色板像素 **121477 → 0**（本席口径，见 §4）；内容区（`x>240`）像素差 **0 → 203949**（`k24`）／**0 → 174476**（`k23`）；两页帧 `sha16` **分离**（`k23=10d0b9d54e649c10`、`k24=fa7df9222ebb199f`）；`colors 383 → 636/654`。**且两独立样本（`:235`／`:236`）帧面逐格相同**（含 `sha16`）⇒ 该帧面**同装置同代际内可复现**。
3. ⚠️ **但"内容区出像素" ≠ "该页模板内容真绘出"**（这是本件最要紧的负向发现）：`k=24` 的**色锚四具名色**（`GhostWhite`／`Beige`／`DarkGreen`／`LightGoldenrodYellow`）**实算全 0**（`hits=0`）⇒ 守卫判 `PTS_COLORANCHOR=FAIL … reason=declared-color-anchor-absent`；**内容锚** `neptune` 命中 **0**。内容区绘出的是**白底 `(255,255,255)` ＋ 灰/深灰文字 ＋ 蓝 `(50,108,243)`**，**不含**该页模板的具名色 ⇒ 按裁定三十五 (b) 的色锚口径：**"该页没绘出内容"**。
4. **相位评估 ＝ 不可翻**（`PTS-PHASE-ASSESSMENT=NO-FLIP`；判词＋逐条依据见 §5）。现取 `realized` 副本判词：`PTS_GUARD=FAIL … fails=leg24-color-anchor-absent(hits=0<2,…) … phase=realized` ⇒ **翻相位＝当场红**（红来自色锚缺席），且"翻"的**语义**（"宣布两页真排版成立"）**与现取事实相反**。
5. **前置逐条**（现取）：`magenta=0` ✔ ｜**无具名降级行**：窄口径 ✔（`[PTS-UNAVAILABLE]=0`／`NAMED err=-`）、**广口径 ✘**（`[HC-UNHANDLED]=1`，`PtsException … did not complete formatting … '-10000'`）｜**真实排版**：像素/帧分离 ✔、**色锚 ✘**、内容锚 ✘（**＝不完整**）｜`N1` 必要件 ✔（正证据仅 `differ`）｜`N3` 绿（两页帧不同）｜**`N4` 未登记 `NOINFO`**。
6. **下一靶（本件判不可翻 ⇒ 给下一靶）**：主靶 ＝ 让 `k24`／`k23` **绘出该页模板的具名色内容**（色锚 ≥2 色、各 `≥200px`）⇒ 色锚转 `PASS`；次靶 ＝ 消掉残留 **1** 条 `[HC-UNHANDLED]`（`FsQueryTrackParaList` 的 `drive-handles-released` 诚实拒绝）；并需为 `N4` 登记正身份（附独立支撑）。

---

## §1 装置 · 代际 · 口径（现取）

| 项 | 主样本（`:235`） | 第二独立样本（`:236`） |
|---|---|---|
| 证据目录 | `build/MilBridge/tests/PtsPagesProbe/evidence-tail2d/` | `…/evidence-tail2d/sample2/` |
| 装置 | `Xvfb :235 1280x1024x24` ＋ `xfwm4 --compositor=off` | `Xvfb :236 1280x1024x24` ＋ `xfwm4 --compositor=off` |
| WM 自证（现取） | `device.txt` ＝ `X_UP=yes display=:235` | `device.txt` ＝ `X_UP=yes display=:236` |
| 腿跑器 | 仓内 `run-pts-pages-legs.sh`（`sha16=330a90f1f0ac28e4`） | 同 |
| 会话件 | `session_inner.sh`（`sha16=f1a582d9ea9788c9`） | 同 |
| 判据件 | `pts-pages-guard.sh`（`sha16=962fec114b2d0692`） | 同 |
| 腿/计数 | `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:235` | `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:236` |
| 显示位规则 | `caller-fixed(PTS_GUARD_DISPLAY)` | 同 |
| 槽 | `~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`（`HEAVYSLOT=ACQUIRED`／`RELEASED rc=0`，`held=33s`） | 同（`held=35s`） |
| 探针闸（裁定三十六 (c)） | **`WPF_PTS_DRIVE_PROBE` 缺省＝开**（`win32_pts.c:1077/1081-1083` 现取：仅显式 `"0"` 才关）⇒ **本趟帧面读数均为"探针开"状态** | 同 |

**代际四元组（现取）**：

| 趟 | 主链 `.so`（`shim16`） | `pf16` | `app_g1.log`（`sha16`／字节） | 帧（`sha16`／字节） |
|---|---|---|---|---|
| **旧（在册 `evidence/`）** | `5ddc9d63b5232f96` | `c52d9191feb5ba7c` | —（本席未重算旧日志） | `boot=b21eb530afd3c66c`／`190413`；`k23=k24=last=ef3fd6765f18f51b`／`189716` |
| **上一代（`evidence-tail2c/`，回填前）** | `e09c8d739c179966` | `1757d610a687777c` | `ad64b4f88dc6fc73` | `boot=b21eb530afd3c66c`／`190413`；`k23=k24=last=ef3fd6765f18f51b`／`189716` |
| **新·主样本（`evidence-tail2d/`）** | **`04f6d354b0a71888`** | `1757d610a687777c` | `7d4afe71281ac17d`／`8972955` | `boot=b21eb530afd3c66c`／`190413`；**`k23=10d0b9d54e649c10`／`96957`，`k24=fa7df9222ebb199f`／`130624`** |
| **新·第二样本（`evidence-tail2d/sample2/`）** | **`04f6d354b0a71888`** | `1757d610a687777c` | `0b47badd29bb917d`／`6637963` | `boot=b21eb530afd3c66c`；**`k23=10d0b9d54e649c10`，`k24=fa7df9222ebb199f`**（**与主样本逐格相同**） |

> ⚠️ **跨代不可比（纪律 31/32）**："旧"（`5ddc9d63…`）／"上一代"（`e09c8d73…`）／"新"（`04f6d354…`）是**三代 `.so`** ＋ **三趟不同时刻**；下表"逐字段相同"只报**结果相同**，**不得**读成"可相减的同一条件"。`FRAME_EMPTY_SET`（判据件件头唯一登记处，现取）＝ `{1a76488aa4a790b3, ef3fd6765f18f51b, b273ebecc332fc03}`。
> ⚠️ **导出面（现取）**：`nm -D --defined-only` 行数 **677** == `bin/exports.txt` 行数 **677**。
> ⚠️ **`realized` 副本的归属**：本件 `realized` 判词取自**仓外副本** `/home/links-dev/tA34-work/guard-realized.sh`（`sha16=fdf0d401a3ba720d`；`sed` 只改相位位，**不改仓内件**）—— 与守卫自带 `--selftest` 造副本的形态相同。

---

## §2 ① 两页新旧**成对**读数表（含内容像素身份判定）

`LEG`／`FAILLINE`／`FRAME` 行取 `leg_<k>.env`；`ENFE`／`failfast`／`[HC-UNHANDLED]` 取现算（命令见 §7）。

| 字段 | 旧（在册 `evidence/`）`k23`／`k24` | 上一代（`evidence-tail2c/`）`k23`／`k24` | 新（`evidence-tail2d/`）`k23`／`k24` | 判（旧 vs 新） |
|---|---|---|---|---|
| `alive` | `yes`／`yes` | `yes`／`yes` | `yes`／`yes` | **不变** |
| `app_rc` | `143`／`143` | `143`／`143` | `143`／`143` | **不变** |
| `magenta` | `0`／`0` | `0`／`0` | `0`／`0` | **不变** |
| `colors` | `383`／`383` | `383`／`383` | **`636`／`654`** | **增（内容像素进场）** |
| `ink` | `480000`／`480000` | `480000`／`480000` | `480000`／`480000` | **不变**（裁定三十五 (c) 入册禁用：恒真量） |
| `ns` | `…RichTextBoxDemo`／`…FlowDocumentDemo` | 同 | 同 | **不变** |
| `ae` | `0`／`15386` | `0`／`15386` | **`125234`／`219340`** | **增** |
| `fr_sha` | `ef3fd6765f18f51b`／同 | `ef3fd6765f18f51b`／同 | **`10d0b9d54e649c10`／`fa7df9222ebb199f`** | **分离** |
| `fr_ae_boot` | `15386`／`15386` | `15386`／`15386` | **`189862`／`219340`** | **增** |
| `failfast`／`unrec` | `0`／`0` | `0`／`0` | `0`／`0` | **不变** |
| `NAMED err` | `-` | `-` | `-` | **不变** |
| `native_gap` | `0` | `0` | `0` | **不变** |
| `ENFE_TOTAL`（`entry point named`） | `0` | `0` | `0` | **不变（归零保持）** |
| `[HC-UNHANDLED]` 行数 | `1117` | `427` | **`1`** | **大降** |
| `reason=no-text-line-model` | `0` | `0` | **`0`** | **不变（保持归零）** |
| `[FSQTD]` 行数 | `0` | `0` | **`6104`** | **首次出现（回填生效）** |
| `[FSQLL]` 行数 | `0` | `0` | **`1528`** | **首次出现** |
| `[FORMATLINE-LINE]` | `—` | `42` | `42` | **不变** |
| `[FSQSTD]` 行数 | `0` | `909` | `6111` | **增** |
| `[FSQSPL]` 行数 | `0` | `535` | `6111` | **增** |
| `[SUBENUM]` 行数 | `0` | `3` | `3` | **不变** |

**`leg_<k>.env` 成对原文（现取）**：

```
旧（在册 evidence/leg_23.env）        新（evidence-tail2d/leg_23.env）
LEG k=23 alive=yes app_rc=143 magenta=0 colors=383  ←→  colors=636  ae=0←→125234
FRAME k=23 fr_sha=ef3fd6765f18f51b fr_ae_boot=15386  ←→  fr_sha=10d0b9d54e649c10 fr_ae_boot=189862
DEV … shim=5ddc9d63b5232f96 pf=c52d9191feb5ba7c     ←→  shim=04f6d354b0a71888 pf=1757d610a687777c（唯一差异＝换代）
（k=24 同形：colors 383→654、ae 15386→219340、fr_sha ef3fd676…→fa7df922…、fr_ae_boot 15386→219340、ns=…FlowDocumentDemo）
```

**🔴 内容像素身份判定（本件核心，逐条现取）**：

| # | 判据 | 现取读数 | 判 |
|---|---|---|---|
| `I-1` | **帧身份 ∉ 空态参照集** | `k23=10d0b9d54e649c10`、`k24=fa7df9222ebb199f` 均 ∉ `{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03}` | **成立**（必要非充分） |
| `I-2` | **两页帧真不同**（`N3`） | `AE(k23,k24)=125234>0`（`compare` 实测；两样本同） | **成立** |
| `I-3` | **占位图消失** | 占位调色板像素 `121477 → 0`（`k24`／`k23`；本席口径见 §4；`boot` 仍 `121477`） | **成立** |
| `I-4` | **内容区有像素** | `AE(boot,k24)` 的 `x>240` 分量 `203949`、`AE(boot,k23)` 的 `x>240` 分量 `174476`（与 `T-A33` 报值**逐值相同**） | **成立** |
| `I-5` | **`k=24` 色锚（裁定三十五 (b)）** | `GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0` ⇒ `hits=0` | **✘ 不成立（该页没绘出内容）** |
| `I-6` | **内容锚** | `[Nn]eptune` 在 `app_g1.log` 命中 **0** | **✘ 不成立** |
| `I-7` | **内容区实际画的是什么** | `k24` 直方图顶列：`(0,0,0)=830720`／`(255,255,255)=354350`／`(238,238,238)=39130`／**`(50,108,243)=14372`（蓝）**／灰阶族；**四具名色一个都不在** ⇒ 画的是**白底＋灰/深灰文字＋蓝元素** | 记录 |

⇒ **判**：**内容区确有新渲染像素（"非空态"在 `I-1..I-4` 意义上成立）**，但**不含该页模板的具名色内容**（`I-5`／`I-6` 缺席）⇒ 按裁定三十五 (b) 的色锚口径，**"该页没绘出内容"**。**不得**把 `I-1..I-4` 单独读成"该页内容真绘出"（裁定二十一 ②／裁定三十六 (c)：帧面类要件必要非充分、永不单独发绿）。

---

## §3 ② 机读面现取（`no-text-line-model`／`[HC-UNHANDLED]`／`[FSQTD]`／`[FORMATLINE]`／`[FSQSTD]`／`[FSQSPL]`／`[SUBENUM]`）

**逐面行数（现取 `grep -c`）**：

| 面 | 旧 `evidence/` | 上一代 `evidence-tail2c/` | 新·主样本 `evidence-tail2d/` | 新·第二样本 `sample2/` |
|---|---|---|---|---|
| `reason=no-text-line-model` | `0` | `0` | `0` | `0` |
| `[HC-UNHANDLED]` | `1117` | `427` | **`1`** | `1` |
| `PtsException … '-10000'` | `1117` | `—` | **`1`** | `1` |
| `entry point named`（ENFE） | `0` | `0` | `0` | `0` |
| `EntryPointNotFoundException` | `0` | `0` | `0` | `0` |
| `[FSQTD]` | `0` | `0` | **`6104`** | `4484` |
| `[FSQTD] rc=0` | `0` | `0` | **`6104`** | `4484` |
| `[FSQLL]` | `0` | `0` | **`1528`** | `1123` |
| `[FORMATLINE]` | `0` | `0` | `10` | `—`（本席未单取） |
| `[FORMATLINE-LINE]` | `—` | `42` | `42` | `42` |
| `[FSQSTD]` | `0` | `909` | `6111` | `4491` |
| `[FSQSTD] rc=0` | `0` | `—` | `6111` | `4491` |
| `[FSQSPL]` | `0` | `535` | `6111` | `4491` |
| `[FSQSPL] rc=0` | `0` | `—` | `6111` | `4491` |
| `[SUBENUM]` | `0` | `3` | `3` | `3` |
| `^PTS_GAP entry=`（`native_gap`） | `0` | `0` | `0` | `0` |

**残留 `[HC-UNHANDLED]` 的实名（现取，`evidence-tail2d/app_g1.log:41548-41549`，**本席独立复算**）**：

```
[FS_PAGE_GAP] rc=-10000 reason=drive-handles-released(page-destroyed) entry=FsQueryTrackParaList ctx=0x623feb161b50 track=0x623fe648d0a8 cParas=1 owned=1 ok=1527 gap=1 cur_tid=123327196927808 win_tid=123327196927808
[HC-UNHANDLED] #1 PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'. ｜ 首帧 at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.Error(Int32 fserr, PtsContext ptsContext)
```
⇒ **这 1 条是 `T-A17` 的诚实拒绝**（页销毁后拒驱；**非**本次回填缺口），但它是**"页面未完成格式化"的具名行** ⇒ 落在下文 `P-2′`（广口径"无具名降级行"）里。

**逐字样本（新·主样本）**：

```
[FSQTD] rc=0 reason=ok entry=FsQueryTextDetails ctx=… parah=0x623fec595f44 calls=1 ok=1 gap=0 nomodel=0 fsktd=1 cLines=8 dcpFirst=0 dcpLim=956 fl_ok=1 out=WRITTEN bytes=112 src=ledger:fl_line[](pfnFormatLine+fsflres-end)
[FSQLL] rc=0 reason=ok entry=FsQueryLineListSingle ctx=… parah=0x623fec595f44 cLines=8 calls=1 ok=1 gap=0 nomodel=0 fl_ok=1 out=WRITTEN bytes=576 src=ledger:fl_line[]←pfnFormatLine
[SUBENUM] where=FsCreatePageBottomless container=0x3 first=0x4 cparas=3 ok=1 rc136=0 rc144=0 child_max=32 v=ENUM-OK calls=1 ok_n=1 gap=0 window=in
[SUBENUM] where=FsCreatePageFinite   … calls=2 ok_n=2 gap=0 window=in
[SUBENUM] where=FsCreatePageBottomless … cparas=1 … calls=3 ok_n=3 gap=0 window=in
```

⇒ **判**：`T-A33` 的回填面**真实生效**（`[FSQTD]`／`[FSQLL]` 首次出现且 `rc=0 out=WRITTEN`；`no-text-line-model` 保持 0；`[HC-UNHANDLED]` `1117→1`；ENFE 保持 0）；但**下游仍有 1 条具名未完成行**（`FsQueryTrackParaList`）⇒ **广口径"无具名降级行"不成立**。

---

## §4 ③ 帧面（三帧 `sha256`、`AE`、`FRAME` 机读行、像素身份）

**帧 `sha256` 前 16 位 ＋ 字节（现取 `sha256sum`／`stat`）**：

| 帧 | 旧（在册） | 上一代（`tail2c`） | 新·主样本（`:235`） | 新·第二样本（`:236`） |
|---|---|---|---|---|
| `boot.png` | `b21eb530afd3c66c`／`190413` | `b21eb530afd3c66c`／`190413` | `b21eb530afd3c66c`／`190413` | `b21eb530afd3c66c`／`190413` |
| `k23.png` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | **`10d0b9d54e649c10`／`96957`** | **同** |
| `k24.png` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | **`fa7df9222ebb199f`／`130624`** | **同** |
| `last.png` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | **`10d0b9d54e649c10`／`96957`** | **同** |

⇒ **两独立样本（`:235`／`:236`）四帧逐格相同** ⇒ 帧面在该代际、该装置下**可复现**（这对"内容真出像素"是硬证据）。

**`AE`（`compare -metric AE`；`N1`／`N3` 口径）**：

| 比较 | 旧 | 上一代 | 新·主样本 |
|---|---|---|---|
| `AE(boot,k24)` | `15386` | `15386` | **`219340`** |
| `AE(boot,k23)` | `15386` | `15386` | **`189862`** |
| **`AE(k23,k24)`**（`N3` 要件②） | **`0`** | **`0`** | **`125234`** |
| `AE(k23,k24)` 的 `x>240` 分量 | — | — | `113426` |
| `AE(boot,k24)` 的 `x>240` 分量 | — | — | **`203949`**（＝`T-A33` 报值，逐值相同） |
| `AE(boot,k23)` 的 `x>240` 分量 | — | — | **`174476`**（＝`T-A33` 报值，逐值相同） |

**占位图判据（本席口径，与 `T-A33` 的 `under_construction.gif` 调色板**不同源**、**同方向**）**：以"旧 `k24` 里棕色族（`180≤r≤220 ∧ 125≤g≤170 ∧ 105≤b≤145`，命中 **23** 色）"为占位调色板：

```
OLD k24 占位像素=121477  OLD k23=121477  OLD boot=121477
NEW k24 占位像素=0       NEW k23=0       NEW boot=121477
```
⇒ **占位图在 `k24`／`k23` 上消失（`121477→0`）**，`boot` 仍有（首屏/占位态）。（`T-A33` 报 `129792→0`；两者**调色板定义不同** ⇒ **数值不可直接比**，**方向一致**。）

**`FRAME` 机读行（`leg_<k>.env` 第五段原文）**：

```
新·主样本（evidence-tail2d/）:
FRAME k=23 fr_file=k23.png fr_sha=10d0b9d54e649c10 fr_lsha=10d0b9d54e649c10 fr_ae_boot=189862
FRAME k=24 fr_file=k24.png fr_sha=fa7df9222ebb199f fr_lsha=fa7df9222ebb199f fr_ae_boot=219340

新·第二样本（evidence-tail2d/sample2/）:  ← 与主样本**逐字相同**
FRAME k=23 fr_file=k23.png fr_sha=10d0b9d54e649c10 fr_lsha=10d0b9d54e649c10 fr_ae_boot=189862
FRAME k=24 fr_file=k24.png fr_sha=fa7df9222ebb199f fr_lsha=fa7df9222ebb199f fr_ae_boot=219340
```

**`shotstat`（与 `leg_*.env` 的 `colors`／`magenta`／`ink` **逐格相等** ⇒ 截图同趟自证成立）**：`boot colors=386 magenta=0 ink=480000`；`k23 colors=636`；`k24 colors=654`（`magenta=0`／`ink=480000`）。

**内容区实际配色（现取，`PIL` 只读）**：`NEW k24` 顶列 `(0,0,0)=830720`／`(255,255,255)=354350`／`(238,238,238)=39130`／`(50,108,243)=14372`／灰阶族；`OLD k24` 顶列含棕色族 `(193,138,117)=17280…`。⇒ **新帧把占位棕色族整片换成白底＋灰/深灰文字＋蓝元素**。

**`N1`／`N3`／`N4` 现取判**：
- **`N1` 要件①**（`fr_sha` ∉ `FRAME_EMPTY_SET`）：`k23=10d0b9d54e649c10`、`k24=fa7df9222ebb199f` 均 **∉** 集 ⇒ **成立**。
- **`N1` 要件②**（`fr_ae_boot>0`）：`189862`／`219340 > 0` ⇒ **成立**。
- **`N3`**（两页帧必须不同）：`AE(k23,k24)=125234>0`、两 `fr_sha` 不等 ⇒ **绿**（不红）。
- **`N4`**（内容正身份）：`PTS_N4_POSITIVE_FP` **未登记** ⇒ `NOINFO(no-registered-positive-identity)`；正证据三源现取 **`positive=differ(via=compare)`**（仅"两页帧真不同"这一源在场；`n4` 缺席、`anchor_hits=0`）。
- ⚠️ **探针闸状态（裁定三十六 (c)）**：本件帧面均在 **`WPF_PTS_DRIVE_PROBE` 缺省＝开** 状态下取 ⇒ **跨闸状态不可比**；本件**未**另跑"闸关"腿（见 `NOINFO-7`）。

---

## §5 ④ 相位评估 ＝ **不可翻**（`PTS-PHASE-ASSESSMENT=NO-FLIP`）

### 5.1 现取判词原文

**A. `degraded` 相（仓内判据件原样，`--legs evidence-tail2d`；`rc=1`）**：

```
PTS_G10_NAME=PASS form=unnamed reason=frontier-unnamed（应用侧无具名 entry= ⇒ 本判据按形态通过；名字归因由 pts-gap-count-check.sh 承担）
PTS_N1=INFO k=24 file=k24.png fr_sha=fa7df9222ebb199f in_empty_set=no fr_ae_boot=219340 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} phase=degraded（止损期不据此判红；相位翻转后本条生效）
PTS_N1=INFO k=23 file=k23.png fr_sha=10d0b9d54e649c10 in_empty_set=no fr_ae_boot=189862 set={…} phase=degraded
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none（阈值由本基线标定）
  COLOR-ANCHOR-ABSENT k=24 expect>=200px&hits>=2 measured=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 baseline(boot.png)=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=degraded（FlowDocumentDemo 的具名色应有而未现 ⇒ 该页没绘出内容）
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 expect_min=200 expect_hits=2 baseline=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=degraded reason=declared-color-anchor-absent
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=degraded（RichTextBoxDemo.xaml 无具名色 ⇒ 本页无锚；严禁用 k=24 的锚推广）
PTS_ENFE=INFO total=0 by_name=none allow=none non_allow=none phase=degraded log=…/evidence-tail2d/app_g1.log log_sha16=7d4afe71281ac17d
PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),leg24-color-anchor-absent(hits=0<2,scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=654,leg23-colors-out-of-band=636 direction=in-file phase=degraded
```
（全文见 `evidence-tail2d/guard-degraded.txt`。）

**B. `realized` 副本（`sed 's/…phase=degraded/…phase=realized/'`；**只改相位位、不改仓内件**；`rc=1`）** —— **本趟最要紧的一条**：

```
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=7 roster=24 domains=pts-declared,dllimport-entry decl=…/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:3755
PTS_N1=NECESSARY k=24 file=k24.png fr_sha=fa7df9222ebb199f in_empty_set=no fr_ae_boot=219340 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criteria-satisfied=frame-identity,frame-displacement phase=realized
PTS_N1=NECESSARY k=23 file=k23.png fr_sha=10d0b9d54e649c10 in_empty_set=no fr_ae_boot=189862 set={…} criteria-satisfied=frame-identity,frame-displacement phase=realized
PTS_N1_POS=phase=realized positive=differ(via=compare) n4=absent anchor_hits=0 differ=1 via=compare n4_unregistered=1 exception_proof= exception_applies=0
PTS_N1_GATE=PASS phase=realized positive=differ(via=compare) necessary=frame-identity,frame-displacement（正证据在场 ⇒ 必要件之上重新成立）
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 expect_min=200 expect_hits=2 baseline=… phase=realized reason=declared-color-anchor-absent
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=realized
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=…/evidence-tail2d/app_g1.log log_sha16=7d4afe71281ac17d
PTS_GUARD=FAIL legs=2/2 fails=leg24-color-anchor-absent(hits=0<2,scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0) cannot=- diag=leg24-colors-out-of-band=654,leg23-colors-out-of-band=636 direction=in-file phase=realized
```
（全文见 `evidence-tail2d/guard-realized.txt`；`sample2` 同形，见 `evidence-tail2d/sample2/guard-realized.txt`。）

> 🔴 **读法（写死）**：`realized` 副本**仍 `PTS_GUARD=FAIL`**，**唯一红 ＝ `leg24-color-anchor-absent`**。⇒ **今天翻相位＝当场红**。`N1_GATE=PASS` 只说明"现取有一源正证据（两页帧不同）"，**不**等于"该页内容真绘出"（`PTS_COLORANCHOR=FAIL` 恰好说反面）。

### 5.2 逐条前置依据（前置 ＝ `magenta=0 ∧ 无具名降级行 ∧ 真排版` ＋ `N1`／`N3`／`N4` 同趟）

| # | 前置 | 现取读数（新·主样本） | 判 |
|---|---|---|---|
| `P-1` | **`magenta=0`** | `leg23`／`leg24` 均 `magenta=0` | **成立**（但见 `P-3`：该条**在空态页上也成立**，本身不指向排版） |
| `P-2` | **无具名降级行**（**判据窄口径**＝`[PTS-UNAVAILABLE] site=…`） | `[PTS-UNAVAILABLE]=0`、`NAMED managed_unavail=0 err=- native_gap=0` | **成立**（窄口径） |
| `P-2′` | **无具名降级行**（**更广口径**＝"页面未完成格式化"的具名行） | `[HC-UNHANDLED] … did not complete formatting operation … '-10000'` **1** 行（`FsQueryTrackParaList` 诚实拒绝） | **✘ 不成立**（**仍有具名未完成行**）⇒ `P-2` 的成立**只对窄口径** |
| `P-3` | **真排版** | （a）两页帧**真不同**（`AE(k23,k24)=125234>0`）**✔**；（b）**`k=24` 色锚 `hits=0`** ⇒ **✘**（基线 `boot` 四色实算全 0 ⇒ 活锚，缺席即红）；（c）内容锚 `neptune` 命中 `0` ⇒ **✘**；（d）帧身份 ∉ 空态参照集 **✔**；（e）占位消失 `121477→0` **✔**；（f）`ink=480000` 是裁定三十五 (c) **入册禁用**的恒真量 | **不完整**（像素/帧分离✔、**具名色/内容锚 ✘**） |
| `P-4a` | **`N1` 同趟** | 必要件①②**成立**；正证据仅 `differ`（`n4` 未登记／`anchor_hits=0`）⇒ `realized` 判 `PTS_N1_GATE=PASS`（因 `differ`） | **必要件成立**（正证据单一） |
| `P-4b` | **`N3` 同趟** | 两页帧不同、`AE=125234>0` ⇒ **绿** | **成立** |
| `P-4c` | **`N4` 同趟** | `PTS_N4_POSITIVE_FP` **未登记**；无"该页专属期望指纹"载体 | **`NOINFO`**（裁定三十五 (a) 禁"登记即算"） |

### 5.3 逐条裁定依据（裁定二十／二十一／三十五／三十六）

- **裁定二十一 ②** ＝「**相位翻转的新硬前置 ＝ 与 `N1–N4` 同趟落定**」⇒ 现取 `N4=NOINFO` ⇒ **前置未落定**。另：「`leg23-AE=0` 不该消、该升为承重判据」⇒ 现取 `leg23-AE=125234≠0`（**已消**），此项**不再阻塞**（但 `k=23` 仍无锚）。
- **裁定三十五 (d)** ＝「**不准翻相位（今天）**；准许的下一步 ＝ 色锚读数（`C-A`）＋ 登记加固，两者都是**判据面**」⇒ 现取 `C-A`（色锚）**已落成且今天必红**（`k=24 hits=0`）、`N4` 登记**仍缺**（`n4_unregistered=1`）⇒ **两个准许项未完成，翻转项仍禁**。
- **裁定三十五 (a)** ＝ `N4` 登记**必须附独立可证伪读数**（否则 `N4-DECLARED-ONLY`、不给绿）⇒ 本件**不**擅自登记（见 `NOINFO-1`）。
- **裁定三十五 (b)** ＝ 色锚**缺席即红、成片即绿**；`k=23` 无锚记 `NOINFO`（禁推广）⇒ 现取 `k24 hits=0`（**红**）、`k23 NOINFO`。
- **裁定三十六 (c)** ＝ 三条口径照旧：① **帧面读数必须带探针闸状态**（本件已带，见 §1／§4）；② `N1` 要件① 之成立**应在闸关闭的那一代上取**（本件未另跑"闸关"腿 ⇒ 见 `NOINFO-7`）；③ **帧面绿永不单独支撑排版结论**（现取 `N1_GATE=PASS` 仅凭 `differ`，**不**据此判"真排版"）。
- **裁定二十** ＝「维持 `degraded`；翻转是**协同动作**（判据件写者**同趟**改相位位 ＋ 同步改那 10 条 degraded 正控期望 ＋ 独立复核），**一次做完**」⇒ 本件是**测量/侦察件**，**无权改相位**（且改了即与事实相反）。
- **旁引裁定三十八 (a)／三十九（冻结令）** ＝「帧内容类要件在 `PRECOND-FRAME-DETERMINISM` 取得读数前**不得单独支撑绿、也不得单独支撑红**」⇒ 本件**不**据任一帧面读数**单向**下判。

⇒ **`PTS-PHASE-ASSESSMENT=NO-FLIP`**：现取 `realized` 副本现跑 `PTS_GUARD=FAIL`、`rc=1`（**唯一红 ＝ 色锚缺席**）；且"翻相位"的**语义**＝"宣布两页真排版成立"，**与现取事实相反**（色锚说"该页没绘出内容"）；**翻的后果＝当场红**。

### 5.4 反腿／反证（"该红必红"与"不该绿"）

1. **`realized` 副本 ≠ 绿**：现取均 `PTS_GUARD=FAIL`、`rc=1` ⇒ 裁定二十一 ② 警告的"翻相位会让守卫 `PASS`（判据放松）"路径**本代已被色锚堵死**（红来自 `leg24-color-anchor-absent`）。
2. **两独立样本成对**：同一 `.so`、同装置、**换显示位（`:235`／`:236`）** ⇒ 帧面与判词**逐格相同** ⇒ **内容像素真实且可复现**（不是单样本偶然），但**仍不"真排版"**（色锚无命中）。
3. **跨代反证**：上一代 `ef3fd6765f18f51b`（两页同值）→ 本代 `10d0b9d5…`≠`fa7df922…`（两页分离）⇒ **本增量确实改了帧面**（与 `T-A18` 的"计数前进 ≠ 帧面位移"不同：**本趟帧面真位移了**）；但"帧面位移"**不**等于"该页模板内容绘出"（色锚缺席）⇒ 印证裁定三十六 (c)③。

---

## §6 ⑤ 下一靶（因判**不可翻**）＋ 具名 `NOINFO`

### 6.1 🔴 下一靶

| # | 靶 | 现取依据 | 期望读数 |
|---|---|---|---|
| `NEXT-1`（**主靶**） | **让 `k24`（`FlowDocumentDemo`）绘出该页模板的具名色内容** | 色锚四具名色实算全 0（`hits=0`）；内容区实画白底/灰/蓝，**不含**模板色 | `k24` 色锚 ≥2 色、各 `≥200px` ⇒ `PTS_COLORANCHOR=PASS`；`k23` 另立活锚（**禁**用 `k24` 推广） |
| `NEXT-2`（次靶） | **消掉残留 1 条 `[HC-UNHANDLED]`** | `FsQueryTrackParaList` 的 `drive-handles-released(page-destroyed)`（`app_g1.log:41548`）⇒ 广口径"无具名降级行"不成立 | `[HC-UNHANDLED]=0` |
| `NEXT-3` | **为 `N4` 登记正身份（附独立可证伪读数）** | `PTS_N4_POSITIVE_FP` 未登记（如实照 `n4_unregistered=1`） | 登记 ＋ 支撑成片（裁定三十五 (a)） |

> 机制线索（**只记不判**）：`NEXT-1` 的现取现象是"内容区绘出白底＋灰/深灰文字＋蓝元素，而模板具名背景色（`GhostWhite` 等）未现" ⇒ 可能是**样式/背景色未随内容层应用**；本件**只测量**、不实现、不判"谁该补"（见 `NOINFO-8`）。

### 6.2 具名 `NOINFO` 清单

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-1` | **`N4` 正身份载体** | `PTS_N4_POSITIVE_FP` 未登记；裁定三十五 (a) 禁"登记即算" | 两页**首次各自绘出真内容**后，由当趟实现件写者同趟登记**带独立可证伪支撑**的正身份 |
| `NOINFO-2` | **帧面确定性 `PRECOND-FRAME-DETERMINISM`** | 旁引裁定三十九记仍未满足；本趟仅得"同装置两显示位（`:235`／`:236`）逐格相同"＋"跨代帧面位移"，**未**取同装置内变体分布 | 按裁定四十 (a) 族级纪律取 ≥20 独立样本、逐趟记代际指纹、批内代际守卫 |
| `NOINFO-3` | **`k=23` 色锚** | 守卫现取 `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（`RichTextBoxDemo.xaml` 无具名色） | 为 `k=23` 另立"活锚"（**严禁**用 `k=24` 的锚推广） |
| `NOINFO-4` | **内容区绘出白底而非模板具名色的机制** | 现取：`k24` 四具名色全 0、内容区顶列为白/灰/蓝 | 由实现件写者按"样式/背景色随内容层应用"方向现取判（本件**只测**） |
| `NOINFO-5` | **旧／上一代 vs 新代的"同一条件相减"** | 三代 `.so` ＋ 三趟不同时刻 ⇒ 跨代不可比（纪律 31/32） | 不适用（本件只报"逐字段相同／逐字节相同"这一**结果**） |
| `NOINFO-6` | **下游拒绝面（`FsQueryTrackParaList … drive-handles-released`）的归属与后果** | 现取为唯一残留 `[HC-UNHANDLED]`；本件**只测**、不实现 | 由实现件写者按裁定二十三 (c)① 铁律（诚实形态：失败必留痕）同趟落地 |
| `NOINFO-7` | **"探针闸关闭"状态下的帧面读数** | 现取探针缺省**开**；裁定三十六 (c)② 要求 `N1` 要件① 之成立**在闸关闭的那一代上取** ⇒ 本件**未**另跑"闸关"腿 | 以 `WPF_PTS_DRIVE_PROBE=0` 跑一趟反极性腿取帧面（**本任务未要求**） |
| `NOINFO-8` | **回填面对"排版"的可观察边界** | 现取 `[FSQTD]`／`[FSQLL]` 首现、`[HC-UNHANDLED]` `1117→1`、帧面**真位移**，但**色锚/内容锚缺席** ⇒ "出像素 ≠ 该页内容绘出" | 待 `NEXT-1`（色锚 `PASS`）落地 |

---

## §7 可复跑单行命令原文（现取）

```sh
# 代际 / 导出面
cd /home/links-dev/netTest/GitProj/WPFOnLinux
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16      # ⇒ 04f6d354b0a71888
nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | grep -c .   # ⇒ 677
wc -l < src/WpfGfx.Linux.Native/bin/exports.txt                        # ⇒ 677

# 跑腿（重活槽；私有 W=/home/links-dev/tA34-work；主样本 :235）
bash /home/links-dev/tA34-work/legs-slot.sh      $PWD/build/MilBridge/tests/PtsPagesProbe/evidence-tail2d          # A 臂 k=24,23
# 第二独立样本 :236
bash /home/links-dev/tA34-work/legs2-slot.sh     $PWD/build/MilBridge/tests/PtsPagesProbe/evidence-tail2d/sample2

# 帧面
D=build/MilBridge/tests/PtsPagesProbe
bash /home/links-dev/tA34-work/frames.sh          # sha16/bytes/AE，两代对照
compare -metric AE $D/evidence-tail2d/shots/g1/k23.png $D/evidence-tail2d/shots/g1/k24.png null:   # ⇒ 125234
python3 /home/links-dev/tA34-work/px.py           # 直方图 + 内容区 x>240 分解
python3 /home/links-dev/tA34-work/placeholder.py  # 占位调色板 OLD→NEW

# 面现取
bash /home/links-dev/tA34-work/faces.sh           # 机读面 NEW vs OLD
bash /home/links-dev/tA34-work/faces3.sh          # 上一代（tail2c）机读面 + 帧

# 判词（仓内件原样）
bash build/MilBridge/tools/pts-pages-guard.sh --legs $PWD/$D/evidence-tail2d          # rc=1（degraded）
# realized 副本（只改相位位；不改仓内件）
sed 's/^\(# PTS-DIRECTION: .*\)phase=degraded$/\1phase=realized/' build/MilBridge/tools/pts-pages-guard.sh > /home/links-dev/tA34-work/guard-realized.sh
PTS_G10_ROSTER_SRC=$PWD/src/WpfGfx.Linux.Native/src/win32_pts.c PTS_G10_DECL_TREE=$PWD/upstream/wpf \
  bash /home/links-dev/tA34-work/guard-realized.sh --legs $PWD/$D/evidence-tail2d        # rc=1（realized；fails=leg24-color-anchor-absent）
```

---

## §8 边界 · 纪律 · 主动披露

1. **写域**：仅一个新证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2d/`（**新建**；第二样本落其**子目录** `sample2/`）＋ 本载体。**未覆盖**在册 `evidence/` 与他代 `evidence-tail2*/`；**未碰** `src/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`。证据目录内除腿产物外另落：`runner-stdout.log`（腿跑器/Runner 同趟 stdout 副本，含 `LEGS_TOOLS` 工具身份）与 `guard-{degraded,realized}.txt`（判词全文），均为本趟现取、供复核。
2. **私有工作区（仓外）**：`/home/links-dev/tA34-work/`（`app/`＝权威五件、`logs/`、跑腿与汇总脚本）。`app/` 由 `cp -a ~/w67-work/app` 装配 ＋ `sync-applocal.sh` 灌成权威五件（现取 `SYNC-APPLOCAL=PASS … drift=0`）；**仓内应用安装一字未动**。
3. **不改相位**：本件**未**改 `pts-pages-guard.sh` 的 `PTS-DIRECTION` 行；`realized` 判词取自**仓外副本**（`/home/links-dev/tA34-work/guard-realized.sh`，`sha16=fdf0d401a3ba720d`，`sed` 只改相位位）—— 与守卫自带 `--selftest` 造副本的形态相同。
4. **重活全走槽**：`~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID（腿跑器自收 `Xvfb`／`xfwm4`，`DEVICE_REAP state=clean`）；显示位只用空闲 `:23x`（本趟显式 `:235`／`:236`）；未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`。
5. **一次装置未就绪的重试（如实披露）**：首跑 `evidence-tail2d` 因私有 `app/` 尚未装配 ⇒ `device=NOINFO reason=app-stale … runner-rc=2`（**0 样本**，非读数）；随即 `cp -a` 装配 `app/` 后重跑（`LEGS_RUNNER=PASS`）—— **该失败趟不计入读数**。方案数**仍为 1 种**（A 臂；第二趟是**同一方案的第二独立样本**，非另一方案）。
6. **行内变量不可靠 → 立纪律（本席踩到）**：NL 侧的 `Shell` 通道里 `D=… && cmd "$D"` 形态**不可靠**（实测 `$D` 展开为空、`ls $D` 列出的是 cwd）⇒ 本件**凡带变量/括号的命令一律落脚本再跑**（`bash …/*.sh`）。记一处，供后人避坑（与「读法本身引入失真」族同源）。
7. **跨代不可比（纪律 31/32）**：§2／§3／§4 的"旧 vs 上一代 vs 新"含**三代 `.so`** 与**三趟时刻** ⇒ 只报"逐字段相同／逐字节相同"这一结果，**不做相减**（见 `NOINFO-5`）。
8. **帧面冻结令（旁引裁定三十八 (a)／三十九）＋ 探针闸状态（裁定三十六 (c)）**：本件**不**据任一帧面读数**单向**下判；`N1`／`N3`／`N4` 的结论均带"不可归因"边界，并已带**探针闸状态**（本趟探头开）。本件**未**新增判据、仅测量与评估。
9. **"旧"读数的性质**：§2／§3／§4 的"旧"列取自**在册 `evidence/`**、"上一代"列取自**在册他代 `evidence-tail2c/`** —— 性质＝**在册证据的现核**（本席同趟未重取那两代腿），**非同趟绿**；"新"列＝本席**同趟新取**。
10. **占位判据口径解耦**：§4 的占位像素计数用**本席自定棕色族**（`180≤r≤220 ∧ 125≤g≤170 ∧ 105≤b≤145`），与 `T-A33` 的 `under_construction.gif` 调色板**不同源** ⇒ **数值（`121477` vs `T-A33` 的 `129792`）不可直接比**，只报**方向**（`→0`）。
11. **未做的（防被读宽）**：未跑反极性腿（`WPF_PTS_FL_DRIVE=0`）—— 那属 `T-A33` 的实现复核面，本件只做"重取/评估"；未跑无 WM 腿；未跑整趟 `verify-all`；未改任何牙本体；未新增任何 `D-G<digits>` 登记编号。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-rearm4-recon.md | sha256sum | cut -c1-16`）= 6d1c2569f78351da
