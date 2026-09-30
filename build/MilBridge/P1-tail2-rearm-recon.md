# P1-tail2 · `T-A10` · 重取臂 ＋ 相位评估（`TASK-0007`／E5 关口）—— 测量/侦察件

> **本件 `T-A10`（测量/侦察子代理）交付**。**写域**：新建新鲜证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2/` 与 `…/evidence-tail2-nowm/`（**均新建，未覆盖在册 `evidence/`**）＋ 本载体。**未碰** `src/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`／在册 `evidence/`；**未改相位**（本任务只评估）；未 `git add/commit/push`。
> **口径引用（不是证据）**：队长**裁定二十**（`P1-ptsname-result.md:157`）／**裁定二十一**（`:163`）／**裁定三十五**（`:271`）／**裁定三十六**（`:286`）作口径；另**旁引**裁定三十八～四十四（帧面确定性冻结线，见 §6）。**它们的读数一条未抄** —— 本件所有读数**现取**（腿跑器同趟新取；守卫现跑）。
> **行号纪律**：本件行号**仅本次有效**；引件一律给内容锚。

---

## §0 结论速览（自包含）

1. **重取说明**：在**新 `.so` `33c3bb7e8365835d`**（`T-A9` 产物）上跑**两页真腿**（`k=23`／`k=24`，A 臂，`run-pts-pages-legs.sh`，私有 `W=/home/links-dev/tA10-work`，私有 display `:231`）：**有 WM 腿**（在册口径，`Xvfb 1280x1024` ＋ `xfwm4`）落 `evidence-tail2/`；**无 WM 腿**（私有补丁副本，**不改仓内件**）落 `evidence-tail2-nowm/`。两条腿各 `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`。
2. **两页是否真排版 ＝ 否**（现取）：两腿 `alive=yes`／`app_rc=143`／`magenta=0`／`colors=383`／`ink=480000`／`failfast=0`／`unrec=0`；`ENFE_TOTAL=0`（`entry point named` 零行）；但 **`k23`＝`k24`＝`last` 三帧逐字节相同**（`sha16=ef3fd6765f18f51b`，各 `189716` B）⇒ **`N3` 红**（两页帧相同）；`k=24` 色锚 `hits=0`（基线全 0 标定）⇒ **`N4`／`C-A` 红**；旁证：`[HC-UNHANDLED] … did not complete formatting operation … '-10000'` **1217** 行、`[FSQSTD] rc=-10000` **1217** 行。
3. **`T-A9` 三级链驱动的面现取**：新 `.so` 上缺省路径**确实驱链** —— `[FSPARALIST-FILL] rc=0` **1217** 行（`h0=0x5`／`src=managed-176`）／`[FSPARALIST-PARA]` 1217／`[FSPARALIST-CONSUME]` 37；**但**下游 `[FSQSTD] rc=-10000 reason=no-layout-content-model` 如实拒绝、`out=UNWRITTEN bytes=0` ⇒ **缺口面位移、页仍没绘出内容**（"计数下降 ≠ 能力前进"）。
4. **相位评估 ＝ 不可翻**（判词＋逐条依据见 §5／§6）。现取 `realized` 副本判词（**只改相位位、不改仓内件**）：有 WM 腿 `PTS_GUARD=FAIL … fails=leg24-n1-frame-unestablished(frame-identity(…)) , leg23-n1-frame-unestablished(…), leg24-color-anchor-absent(…)`；无 WM 腿 `PTS_GUARD=FAIL … fails=n1-only-necessary-condition-no-positive-evidence(…),leg24-color-anchor-absent(…)`。⇒ **翻相位＝当场红，不是翻绿**，且翻的**语义**（"宣布两页真排版成立"）**与事实相反**。
5. **本趟现取到一个"帧身份假绿通道"的实例（很有价值）**：同一新 `.so`、同装置，**换"有 WM／无 WM"这一装置差**即把两页帧从 `ef3fd6765f18f51b`（**∈ 空态参照集**）换成 `9ddd25ab947d0efb`（**∉ 集**），而**两页仍是空态页**（`magenta=0`／`colors=383`／色锚 `hits=0`／两帧仍相同）⇒ **"`fr_sha` ∉ 参照集"可纯由装置差达成**，这正是裁定三十九 (c) 点名的"第三条假绿通道"的一条**具体实现路径**。

---

## §1 装置 · 代际 · 口径（现取）

| 项 | 有 WM 腿（在册口径） | 无 WM 腿（私补丁副本） |
|---|---|---|
| 证据目录 | `build/MilBridge/tests/PtsPagesProbe/evidence-tail2/` | `build/MilBridge/tests/PtsPagesProbe/evidence-tail2-nowm/` |
| 装置 | `Xvfb :231 1280x1024x24` ＋ `xfwm4 --compositor=off` | `Xvfb :231 1280x1024x24`，**不启 WM** |
| WM 自证（现取） | （在册口径；装置件 `device.txt` = `X_UP=yes display=:231`） | `WM_PRESENT=_NET_SUPPORTING_WM_CHECK:  no such atom on any window.`（`runner-stdout.log` 现取） |
| 腿跑器 | 仓内 `run-pts-pages-legs.sh`（`sha16=330a90f1f0ac28e4`） | 私有副本（`sha16=4056e97b2e591a88`；**仅删 `xfwm4` 启动块＋加 `WM_PRESENT` 自证行**，其余逐字节同源） |
| 会话件 | `session_inner.sh`（`sha16=f1a582d9ea9788c9`） | 同（symlink 同源） |
| 判据件 | `pts-pages-guard.sh`（`sha16=962fec114b2d0692`） | 同 |
| 腿/计数 | `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:231` | 同 |
| 显示位规则 | `lowest-free(base=:231 span=9)`（`DISPLAY_PICK`） | 同 |
| 槽 | `~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`（`HEAVYSLOT=ACQUIRED`／`RELEASED rc=0`） | 同（`held=34s`） |

**代际三元组（现取）**：

| 趟 | 主链 `.so`（`shim16`） | `pf16` | `app_g1.log`（`sha16`／字节） | 帧（`sha16`／字节） |
|---|---|---|---|---|
| **旧（在册 `evidence/`）** | `5ddc9d63b5232f96` | `c52d9191feb5ba7c` | `84db0eb62d15e0b2`／`551555` | `boot=b21eb530afd3c66c`／`190413`；`k23=k24=last=ef3fd6765f18f51b`／`189716` |
| **新·有 WM** | `33c3bb7e8365835d` | `1757d610a687777c` | `5533298d4dc75eab`／`1581344` | `boot=b21eb530afd3c66c`／`190413`；`k23=k24=last=ef3fd6765f18f51b`／`189716` |
| **新·无 WM** | `33c3bb7e8365835d` | `1757d610a687777c` | `37c495c2d32b1c76`／`1198242` | `boot=b8b881d85afcf38d`／`191698`；`k23=k24=last=9ddd25ab947d0efb`／`190932` |

> ⚠️ **跨代不可比（纪律 31/32）**：上表"旧"与"新"是**两代 `.so`**（`T-A9` 换代）＋ **两趟不同时刻**；下表的"逐字相同"是**结果相同**，**不得**读成"可相减的同一条件"。`FRAME_EMPTY_SET`（判据件件头唯一登记处，现取）＝ `{1a76488aa4a790b3, ef3fd6765f18f51b, b273ebecc332fc03}`。`T-A9` 的"改前"代（`.so a1403ea71c2bf487`）是**又一代**，与本表"旧"不是同一枚，本件**不做三方相减**。

---

## §2 ① 两页新旧**成对**读数表（`magenta`／`colors`／`ink`／`ENFE`／`failfast`／`alive`／`app_rc`）

`LEG`／`FAILLINE`／`FRAME` 行取 `leg_<k>.env`；`ENFE`／`failfast`／`HC-UNHANDLED` 取现算（命令见 §7）。

| 字段 | 旧（在册 `evidence/`）`k23`／`k24` | 新·有 WM `k23`／`k24` | 新·无 WM `k23`／`k24` | 判（旧 vs 新·有WM） |
|---|---|---|---|---|
| `alive` | `yes`／`yes` | `yes`／`yes` | `yes`／`yes` | **不变** |
| `app_rc` | `143`／`143` | `143`／`143` | `143`／`143` | **不变** |
| `magenta` | `0`／`0` | `0`／`0` | `0`／`0` | **不变** |
| `colors` | `383`／`383` | `383`／`383` | `383`／`383` | **不变** |
| `ink` | `480000`／`480000` | `480000`／`480000` | `480000`／`480000` | **不变** |
| `ns` | `…RichTextBoxDemo`／`…FlowDocumentDemo` | 同 | 同 | **不变** |
| `ae` | `0`／`15386` | `0`／`15386` | `0`／`15386` | **不变** |
| `failfast`／`unrec` | `0`／`0` | `0`／`0` | `0`／`0` | **不变** |
| `ENFE_TOTAL`（`entry point named`） | `0` | `0` | `0` | **不变** |
| `[HC-UNHANDLED]` 行数 | `1117` | `1217` | `1217` | **变（同族，行数随运行）** |
| `[PTS-UNAVAILABLE]` 行数 | `0` | `0` | `0` | **不变** |
| `PTS_GAP entry=` 行数（`native_gap`） | `0`／`0` | `0`／`0` | `0`／`0` | **不变** |
| `[FSQSTD]` 行数 | `0` | **`1217`** | `1217` | **变（`T-A9` 驱链的现取）** |
| `[FSPARALIST-*]` 行数 | `0` | **`2476`** | `2476` | **变（`T-A9` 驱链的现取）** |

**`leg_<k>.env` 成对原文（有 WM，新旧）**：

```
旧（在册 evidence/leg_23.env）     新（evidence-tail2/leg_23.env）
LEG k=23 alive=yes app_rc=143 magenta=0 colors=383 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=0 ink=480000   （逐字相同）
NAMED managed_unavail=0 err=- native_gap=0 native_err=-                                                              （逐字相同）
DEV x_up=yes five_stable=yes shim=5ddc9d63b5232f96 pf=c52d9191feb5ba7c   ←→  shim=33c3bb7e8365835d pf=1757d610a687777c   （**唯一差异＝换代**）
FAILLINE k=23 failfast=0 unrec=0 src=app_g1.log:FailFast|Unrecoverable                                                （逐字相同）
FRAME k=23 fr_file=k23.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386                            （逐字相同）
```
（`k=24` 同形，`ns=…FlowDocumentDemo`、`ae=15386`。）

**`FSPARALIST` 细目（新·有 WM，现取）**：`FSPARALIST-PARA 1217`／`FSPARALIST-FILL 1217`／`FSPARALIST-CONSUME 37`／`FSPARALIST-PARA-IN 3`／`FSPARALIST-SUB-SELFTEST 1`／`FSPARALIST-SLOT3 1`。`FILL` 原文（首行）：

```
[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=1 n=1 h0=0x5 src=managed-176 run=site=probe-in win=in gen=1 quad=1 hold=0 off16=16 bytes0_32=00 00 00 00 00 00 00 00 14 65 fd 32 73 62 00 00 05 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00  ok=1 gap=0
```
`FSQSTD` 原文（首行）：
```
[FSQSTD] rc=-10000 reason=no-layout-content-model entry=FsQuerySubtrackDetails ctx=0x6273325cd160 psub=0x627332fd6514 calls=1 ok=0 gap=1 null=0 unclaim=0 unformatted=1 out=UNWRITTEN bytes=0
```
`[HC-UNHANDLED]` 原文（首行，**两趟同族、逐字同**）：
```
[HC-UNHANDLED] #1 PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'. ｜ 首帧 at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.Error(Int32 fserr, PtsContext ptsContext)
```
⇒ **判**：`T-A9` 让缺省路径驱链、`[FSPARALIST-*]`／`[FSQSTD]` 面**从零变成有**，**但症状门逐字段不变**（`magenta`／`colors`／`ink`／`alive`／`app_rc`／`failfast`／`unrec`／`ns`／`ae`／`PTS-UNAVAILABLE`／`PTS_GAP`／`ENFE` 全同）⇒ **`T-A9` 未推进"两页真排版"**。

---

## §3 ② 帧面（三帧 `sha256`、`AE`、`FRAME` 机读行）

**帧 `sha256` 前 16 位 ＋ 字节（现取 `sha256sum`／`stat`）**：

| 帧 | 旧（在册） | 新·有 WM | 新·无 WM |
|---|---|---|---|
| `boot.png` | `b21eb530afd3c66c`／`190413` | `b21eb530afd3c66c`／`190413` | `b8b881d85afcf38d`／`191698` |
| `k23.png` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | `9ddd25ab947d0efb`／`190932` |
| `k24.png` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | `9ddd25ab947d0efb`／`190932` |
| `last.png` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | `9ddd25ab947d0efb`／`190932` |

**`AE`（`compare -metric AE`；`N1`／`N3` 口径）**：

| 比较 | 旧 | 新·有 WM | 新·无 WM |
|---|---|---|---|
| `AE(boot,k23)` | `15386` | `15386` | `15386` |
| `AE(boot,k24)` | `15386` | `15386` | `15386` |
| **`AE(k23,k24)`**（`N3` 要件②） | **`0`** | **`0`** | **`0`** |
| `AE(新·有WM k24, 新·无WM k24)` | — | — | **`712401`**（**装置差**，见 §0-5） |

**`FRAME` 机读行（`leg_<k>.env` 第五段原文，照 `N1`／`N4` 口径）**：

```
旧（在册 evidence/）:
FRAME k=23 fr_file=k23.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386
FRAME k=24 fr_file=k24.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386

新·有 WM（evidence-tail2/）:  ← 两条与"旧"**逐字相同**
FRAME k=23 fr_file=k23.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386
FRAME k=24 fr_file=k24.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386

新·无 WM（evidence-tail2-nowm/）:
FRAME k=23 fr_file=k23.png fr_sha=9ddd25ab947d0efb fr_lsha=9ddd25ab947d0efb fr_ae_boot=15386
FRAME k=24 fr_file=k24.png fr_sha=9ddd25ab947d0efb fr_lsha=9ddd25ab947d0efb fr_ae_boot=15386
```

`shotstat`（与 `leg_*.env` 的 `colors`／`magenta`／`ink` **逐格相等** ⇒ 截图同趟自证成立）：

```
新·有 WM:  boot colors=386 magenta=0 ink=480000 ｜ k23=k24=last colors=383 magenta=0 ink=480000
新·无 WM:  boot colors=386 magenta=0 ink=480000 ｜ k23=k24=last colors=383 magenta=0 ink=480000
```

**`N1`／`N3`／`N4` 现取判**：
- **`N1` 要件①**（`fr_sha` ∉ `FRAME_EMPTY_SET`）：有 WM 腿 `ef3fd6765f18f51b` **∈ 集** ⇒ **不成立**；无 WM 腿 `9ddd25ab947d0efb` **∉ 集** ⇒ 成立（**但这是装置差，见 §0-5**）。
- **`N1` 要件②**（`fr_ae_boot>0`）：两腿 `15386>0` ⇒ 成立。
- **`N3`**（两页帧必须不同／`AE(k23,k24)>0`）：**三趟全 `AE=0`、两页帧逐字节相同** ⇒ **红**（且按裁定三十九 (b)，该红**同样不可归因**于"两页同貌 vs 恰好同变体"）。
- **`N4`**（内容正身份）：`PTS_N4_POSITIVE_FP` **未登记** ⇒ `NOINFO(no-registered-positive-identity)`；内容锚 `neptune` 命中 **0**（新旧皆 0）；色锚 `k=24` `hits=0`。

---

## §4 ③ `pts-pages-guard.sh` 现取判词原文

**A. `degraded` 相（仓内判据件原样，`--legs evidence-tail2`；`rc=1`）** —— 与在册 `evidence/` 判词**逐字相同**：

```
PTS_G10_NAME=PASS observed=FsQueryTrackParaList names=4 roster=20 domains=pts-declared（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）
PTS_N1=INFO k=24 file=k24.png fr_sha=ef3fd6765f18f51b in_empty_set=yes fr_ae_boot=15386 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} phase=degraded（止损期不据此判红；相位翻转后本条生效 —— 口径见 t124 段）
PTS_N1=INFO k=23 file=k23.png fr_sha=ef3fd6765f18f51b in_empty_set=yes fr_ae_boot=15386 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} phase=degraded（止损期不据此判红；相位翻转后本条生效 —— 口径见 t124 段）
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none（**阈值由本基线标定**：基线全 0 ⇒ 该计数能分开有该色/没该色；`LightGray` 不入集——它在空态帧里已有 44/51 px）
  COLOR-ANCHOR-ABSENT k=24 expect>=200px&hits>=2 measured=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 baseline(boot.png)=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=degraded（`FlowDocumentDemo` 的具名色**应有而未现** ⇒ 该页**没绘出内容**）
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 expect_min=200 expect_hits=2 baseline=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=degraded reason=declared-color-anchor-absent
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=degraded（`RichTextBoxDemo.xaml` 无具名色 ⇒ **本页无锚**；**严禁**用 k=24 的锚推广。⏪ `t145`：本支**只印具名 NOINFO 行、不折 `cannot`** —— 否则任何没有 k=24 帧的证据目录都会被整体读成不可判；**本面不给绿**这一点不变）
PTS_ENFE=INFO total=0 by_name=none allow=none non_allow=none phase=degraded log=build/MilBridge/tests/PtsPagesProbe/evidence-tail2/app_g1.log log_sha16=5533298d4dc75eab（止损期不据此判红；相位翻转后本条生效 —— 口径见 t122 段；**引用必须连 log ＋ log_sha16 一起引**，见 t136 F-2）
PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),leg24-color-anchor-absent(hits=0<2,scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=degraded
```
（在册 `evidence/` 的同趟判词：**除 `log_sha16=84db0eb62d15e0b2` 与 `G10 … names=1`** 外**逐字相同**，`PTS_GUARD=` 判词行**一字不差**。全文见 `evidence-tail2/guard-degraded.txt`。）

**B. `realized` 副本（`sed 's/…phase=degraded/…phase=realized/'`；**只改相位位、不改仓内件**；`--legs evidence-tail2`；`rc=1`）**：

```
PTS_N1=FAIL k=24 file=k24.png fr_sha=ef3fd6765f18f51b in_empty_set=yes fr_ae_boot=15386 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criterion=frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03}) phase=realized reason=frame-identity-not-established
PTS_N1=FAIL k=23 file=k23.png fr_sha=ef3fd6765f18f51b in_empty_set=yes fr_ae_boot=15386 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criterion=frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03}) phase=realized reason=frame-identity-not-established
PTS_N1_POS=phase=realized positive=none n4=absent anchor_hits=0 differ=0 via=compare n4_unregistered=1 exception_proof= exception_applies=0（三源口径见 t136 段；「∉ 参照集」单独**不给绿**）
PTS_N1_GATE=NOINFO phase=realized reason=necessary-not-satisfied(nec23=no,nec24=no) sha23=ef3fd6765f18f51b sha24=ef3fd6765f18f51b
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 expect_min=200 expect_hits=2 baseline=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=realized reason=declared-color-anchor-absent
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=build/MilBridge/tests/PtsPagesProbe/evidence-tail2/app_g1.log log_sha16=5533298d4dc75eab
PTS_GUARD=FAIL legs=2/2 fails=leg24-n1-frame-unestablished(frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03})),leg23-n1-frame-unestablished(frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03})),leg24-color-anchor-absent(hits=0<2,scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0) cannot=n1-gate(necessary-not-satisfied=nec23:no,nec24:no) diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=realized
```
（在册 `evidence/` 的 `realized` 副本判词**与上面逐字相同**（仅 `log_sha16`／`G10 names` 差）；全文见 `evidence-tail2/guard-realized.txt`。**关键**：`ENFE=PASS total=0` ⇒ 翻相位的红**不来自** ENFE，而来自 **`N1` 帧身份 ＋ 色锚**。）

**C. 无 WM 腿（`realized` 副本，`--legs evidence-tail2-nowm`；`rc=1`）** —— **本趟最要紧的一条**：

```
PTS_N1=NECESSARY k=24 file=k24.png fr_sha=9ddd25ab947d0efb in_empty_set=no fr_ae_boot=15386 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criteria-satisfied=frame-identity,frame-displacement phase=realized（⏪ t136：**必要非充分** …）
PTS_N1=NECESSARY k=23 file=k23.png fr_sha=9ddd25ab947d0efb in_empty_set=no fr_ae_boot=15386 set={…} criteria-satisfied=frame-identity,frame-displacement phase=realized
PTS_N1_POS=phase=realized positive=none n4=absent anchor_hits=0 differ=0 via=compare n4_unregistered=1 exception_proof= exception_applies=0（三源口径见 t136 段；「∉ 参照集」单独**不给绿**）
  N1-ONLY-NECESSARY positive=none n4=absent anchor_hits=0 differ=0 reason=only-necessary-condition-no-positive-evidence（realized 期**两腿必要件都成立**、**只有必要条件、缺正证据** ⇒ 不许给排版绿）
PTS_N1_GATE=FAIL phase=realized positive=none sha23=9ddd25ab947d0efb sha24=9ddd25ab947d0efb nec23=yes nec24=yes reason=only-necessary-condition-no-positive-evidence
PTS_GUARD=FAIL legs=2/2 fails=n1-only-necessary-condition-no-positive-evidence(sha23=9ddd25ab947d0efb,sha24=9ddd25ab947d0efb,anchor=0,n4=absent),leg24-color-anchor-absent(hits=0<2,scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=realized
```
⇒ **无 WM 腿把 `N1` 要件①凑成了"成立"（`in_empty_set=no`），`t136`／`t145` 的正证据闸把它就地堵住**（`N1_GATE=FAIL reason=only-necessary-condition-no-positive-evidence`）—— 这正是 §0-5 现取到的假绿通道**被拦下**的读数。

---

## §5 ④ 相位结论 ＝ **不可翻**

### 5.1 判词

> **`PTS-PHASE-ASSESSMENT=NO-FLIP`**（现取 `realized` 副本两趟均 `PTS_GUARD=FAIL`、`rc=1`；且"翻相位"的**语义**＝"宣布两页真排版成立"，与现取事实相反）。

### 5.2 逐条前置依据（前置 ＝ `magenta=0 ∧ 无具名降级行 ∧ 真排版` ＋ `N1`／`N3`／`N4` 同趟）

| # | 前置 | 现取读数（新·有 WM，主口径） | 判 |
|---|---|---|---|
| `P-1` | **`magenta=0`** | `leg23`／`leg24` 均 `magenta=0` | **成立**（但见 `P-2`／`P-3`：这一条**在空态页上也成立**，本身不指向排版） |
| `P-2` | **无具名降级行**（**判据口径**＝`[PTS-UNAVAILABLE] site=…`） | `[PTS-UNAVAILABLE]=0`、`NAMED managed_unavail=0 err=- native_gap=0` | **成立**（窄口径） |
| `P-2′` | **无具名降级行**（**更广口径**＝"页面未完成格式化"的具名行） | `[HC-UNHANDLED] … Page formatting engine did not complete formatting operation … '-10000'` **1217** 行；`[FSQSTD] rc=-10000 reason=no-layout-content-model` **1217** 行 | **不成立**（**有具名未完成行**）⇒ **`P-2` 的成立只对窄口径** |
| `P-3` | **真排版** | （a）`k23=k24=last` **逐字节相同**（`ef3fd6765f18f51b`）⇒ `AE(k23,k24)=0`；（b）`k=24` 色锚 `hits=0`（基线 `boot` 四色实算全 0 ⇒ 活锚，缺席即红）；（c）内容锚 `neptune` 命中 `0`；（d）帧身份 **∈** 空态参照集；（e）`ink=480000` 是裁定三十五 (c) **入册禁用**的恒真量 | **不成立** |
| `P-4a` | **`N1` 同趟** | 要件①（`fr_sha` ∉ 参照集）**不成立**（`∈` 集）⇒ `realized` 判 `PTS_N1=FAIL … reason=frame-identity-not-established`；正证据三源 `positive=none`（`n4` 未登记／`anchor_hits=0`／`differ=0`） | **不成立**（红） |
| `P-4b` | **`N3` 同趟** | 两页帧相同、`AE=0` ⇒ 红；且按裁定三十九 (b) 该红**不可归因**（帧面不定性） | **不成立**（红） |
| `P-4c` | **`N4` 同趟** | `PTS_N4_POSITIVE_FP` **未登记**；无"该页专属期望指纹"载体 | **`NOINFO`**（无正身份载体；裁定三十五 (a) 另禁"登记即算"） |

### 5.3 两条"跨相位"的硬前置也都不满足（旁引，作为加强）

- **裁定二十一 ②** ＝「**相位翻转的新硬前置 ＝ 与 `N1–N4` 同趟落定**」⇒ 现取 `N1` 红、`N3` 红、`N4` `NOINFO` ⇒ **前置未落定**。
- **裁定三十九 (a)／(c)（冻结令）** ＝「`fr_sha`／帧内容类要件（`N1①`／`N3`／`N4`／守卫 `in_empty_set` 面）在 `PRECOND-FRAME-DETERMINISM` 取得读数前**不得单独支撑绿、也不得单独支撑红**」；裁定四十二 (b) 记「该前置**仍未满足**、冻结令**维持**」⇒ **相位翻转的三个前置全部落在冻结射程内**。本趟现取**再添一条实例**（§0-5：换 WM 即换帧身份 ⇒ `N1①` 可被**装置差**凑成"成立"）⇒ **不得**据本节任一帧面读数**单向**（只援引绿或只援引红）下判。

### 5.4 反腿／反证（"该红必红"与"不该绿"）

1. **`realized` 副本 ≠ 绿**：两趟（有 WM／无 WM）现取均 `PTS_GUARD=FAIL`、`rc=1` ⇒ **裁定二十一 ② 当年警告的"翻相位会让守卫 `PASS`（判据放松）"这一路径，在本守卫（`962fec114b2d0692`）上已被 `t136`／`t145` 堵死**（红来自 `N1` 帧身份 ＋ 色锚，**不来自** ENFE —— `ENFE=PASS total=0`）。
2. **有 WM／无 WM 成对**：同一 `.so`、同一装置号，**单变量 ＝ WM 有无** ⇒ 帧身份 `∈集`→`∉集`，而两页**仍未排版** ⇒ **证明"`fr_sha` ∉ 参照集"是必要非充分**（该红／该绿都不单独成立）。

---

## §6 ⑤ 具名 `NOINFO` 清单

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-1` | **`N4` 正身份载体** | `PTS_N4_POSITIVE_FP` 未登记；无"该页专属期望指纹"；裁定三十五 (a) 禁"登记即算" | 两页**首次各自绘出内容**后，由当趟实现件写者同趟登记**带独立可证伪支撑**的正身份（裁定三十五 (a)）；本件**不**擅自登记 |
| `NOINFO-2` | **帧面确定性 `PRECOND-FRAME-DETERMINISM`** | 裁定四十二 (b) 记仍未满足；本趟仅得"装置差"（有/无 WM）对照，**未**取同装置内变体分布 | 按裁定四十 (a) 族级纪律取 ≥20 独立样本、逐趟记代际指纹、批内代际守卫 |
| `NOINFO-3` | **`k=23` 色锚** | 守卫现取 `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（`RichTextBoxDemo.xaml` 无具名色） | 为 `k=23` 另立"活锚"（**严禁**用 `k=24` 的锚推广） |
| `NOINFO-4` | **`T-A9` 驱链对"排版"的可观察变化** | 现取 `[FSPARALIST-*]`／`[FSQSTD]` 面从零变有，但症状门＋帧面全不变 ⇒ "计数下降 ≠ 能力前进" | 待 `FsQuerySubtrack*` 等下游真落地、且帧面出现真内容 |
| `NOINFO-5` | **旧 `.so` 上的 `[FSQSTD]`／`[FSPARALIST-*]` 等价读数** | 旧 `.so`（`5ddc9d63b5232f96`）不驱链 ⇒ 该两面零行；**不能反推**"旧代若驱链会怎样" | 在旧代 `.so` 上重跑（**本任务不要求、且跨代不可比**） |
| `NOINFO-6` | **旧／新两趟"同一条件相减"** | 两代 `.so` ＋ 两趟不同时刻 ⇒ 跨代不可比（纪律 31/32） | 不适用（本件只报"逐字相同"这一**结果**） |
| `NOINFO-7` | **无 WM 腿的"在册口径"归属** | 该腿用**私有补丁副本**（`sha16=4056e97b2e591a88` ≠ 在册 runner `330a90f1f0ac28e4`）⇒ 只作**装置差**证据 | 若要把"无 WM"立为在册口径 ⇒ 须由装置件写者正式落成 runner 的一支（**本任务不改 `tools/**`／装置件**） |

---

## §7 可复跑单行命令原文（现取）

```sh
# 代际
cd /home/links-dev/netTest/GitProj/WPFOnLinux
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16                      # ⇒ 33c3bb7e8365835d
sha256sum build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll | cut -c1-16   # ⇒ 1757d610a687777c

# 跑腿（重活槽；私有 W；A 臂 k=24,23）
bash /home/links-dev/tA10-work/legs-slot.sh /home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/tests/PtsPagesProbe/evidence-tail2
bash /home/links-dev/tA10-work/legs-nowm-slot.sh /home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/tests/PtsPagesProbe/evidence-tail2-nowm

# 帧面
D=build/MilBridge/tests/PtsPagesProbe
sha256sum $D/evidence-tail2/shots/g1/{boot,k23,k24,last}.png
compare -metric AE $D/evidence-tail2/shots/g1/k23.png $D/evidence-tail2/shots/g1/k24.png null:   # ⇒ 0
compare -metric AE $D/evidence-tail2/shots/g1/boot.png $D/evidence-tail2/shots/g1/k24.png null:  # ⇒ 15386

# 面现取（旧 vs 新）
for d in $D/evidence $D/evidence-tail2; do
  printf '%s ' "$d"
  grep -c 'PTS-UNAVAILABLE' $d/app_g1.log
  grep -c '\[HC-UNHANDLED\]' $d/app_g1.log
  grep -c 'PTS_GAP entry=' $d/app_g1.log
  grep -c '\[FSQSTD\]' $d/app_g1.log
  grep -c 'FSPARALIST' $d/app_g1.log
  grep -c 'entry point named' $d/app_g1.log
done

# 判词
bash build/MilBridge/tools/pts-pages-guard.sh --legs $D/evidence-tail2
# realized 副本（只改相位位；不改仓内件）
sed 's/^\(# PTS-DIRECTION: .*\)phase=degraded$/\1phase=realized/' build/MilBridge/tools/pts-pages-guard.sh > /home/links-dev/tA10-work/guard-realized.sh
PTS_G10_ROSTER_SRC=$PWD/src/WpfGfx.Linux.Native/src/win32_pts.c PTS_G10_DECL_TREE=$PWD/upstream/wpf \
  bash /home/links-dev/tA10-work/guard-realized.sh --legs $D/evidence-tail2
```

---

## §8 边界 · 纪律 · 主动披露

1. **写域**：仅两个**新建**新鲜证据目录（`evidence-tail2/`、`evidence-tail2-nowm/`）＋ 本载体。**未覆盖**在册 `evidence/`；**未碰** `src/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`；`git status --porcelain` 现取仅两处新 `??`（两新目录）＋ 一处在册既有 untracked（`evidence/arm_A/app_g1.log`，**先于本件存在**）。
2. **不改相位**：本件**未**改 `pts-pages-guard.sh` 的 `PTS-DIRECTION` 行；`realized` 判词取自**仓外副本**（`/home/links-dev/tA10-work/guard-realized.sh`，`sed` 只改相位位）—— 与守卫自带 `--selftest` 造副本的形态相同。
3. **无 WM 腿的装置件**：为造"无 WM"这一支，本件在**仓外私有目录**（`/home/links-dev/tA10-work/probe-nomw/`）用**补丁副本**（**仅删 `xfwm4` 启动块 ＋ 加 `WM_PRESENT` 自证行**）；**仓内装置件一字未动**。该腿的 runner `sha16` 与在册不同 ⇒ 已在 `NOINFO-7` 如实划界。
4. **重活全走槽**：`~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID（腿跑器自收 `Xvfb`／`xfwm4`，`DEVICE_REAP state=clean`）；显示位只用空闲 `:23x`（`lowest-free(base=:231 span=9)`）；未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`。
5. **跨代不可比（纪律 31/32）**：§2 的"旧 vs 新"含**两代 `.so`** 与**两趟时刻** ⇒ 只报"逐字相同"这一结果，**不做相减**（见 `NOINFO-6`）。
6. **帧面冻结令（旁引裁定三十九／四十二）**：本件**不**据任一帧面读数**单向**下判；`N1`／`N3`／`N4` 的结论均带"不可归因"边界。本件**未**新增判据、仅测量与评估。
7. **`[FSQSTD]`／`[FSPARALIST-*]` 属 `T-A9` 的现取面**（非本件引入）：本件只**读**它们；其"缺口计数下降 ≠ 能力前进"按 `pts-gap-count-check.sh` 件头第 ① 条读。
8. **旧（在册）读数的性质**：§2／§3 的"旧"列取自**在册 `evidence/`**（`shim=5ddc9d63b5232f96`）—— 性质＝**在册证据的现核**（本席同趟未重取旧代腿），**非同趟绿**；"新"列＝本席**同趟新取**。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-rearm-recon.md | sha256sum | cut -c1-16`）= `0e82d531591014d1`
