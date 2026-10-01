# `P1-tail2-evidence81-recon` —— 在册证据换代（`PtsPagesProbe/evidence`）· 测量趟（`T-A59`）

**车道**：`T-A59`（测量子代理）｜**写域**：`build/MilBridge/tests/PtsPagesProbe/evidence/**`（换代）＋本载体｜**装置**：私有 `display :231`（Xvfb ＋ xfwm4，`-screen 0 1280x1024x24`）｜**重活全走** `~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`｜**进程只按 PID**（`DEVICE_REAP state=clean`）｜**全程 `temp+rename`**｜**未 `git add`／`commit`／`push`**
**结论一句话**：在**现件**（`shim=d406f243cdc2c402`／`pf=1c6c58df6d757f3f`，`sync-applocal --check drift=0`、`POSTSHIM == authority`）上跑两页真腿，`temp+rename` 换代在册 `evidence/` ⇒ 判据 **`PTS_GUARD=PASS … phase=realized`**、**`PTS_COLORANCHOR=PASS k=24 … hits=3`**（旧在册停在 `T-A52` 之前 ⇒ `hits=2`）；`SSC=PASS … BASELINE=#81` **无回退**。

---

## §0 一句话与必须交代的边界

- 现取（`T-A58` 披露③）：门禁 `[38]` 读的**在册证据**停在 `T-A52` 之前 ⇒ `PTS_COLORANCHOR=PASS k=24 hits=2`（旧帧四色中仅 `Beige`／`DarkGreen` ≥200px）。
- 现件（`.so d406f243cdc2c402`／表单元闸缺省开）⇒ 第 4 色 `LightGoldenrodYellow` 已落 ⇒ 本趟换代后 **`hits=3`**（`GhostWhite`／`Beige`／`DarkGreen`／`LightGoldenrodYellow` 中 3 色 ≥200px）。
- **只写**：`build/MilBridge/tests/PtsPagesProbe/evidence/**`（换代）＋本载体。**未改** `src/**`／生成器／`verify-all.sh`／`build/MilBridge/tools/**`／`docs/**`／基线件。临时目录与旧目录**均已清到底**（`evidence.__*`／`.stage-a59` 残留 **0**）。

---

## §1 ① 旧／新 `sha16` 成对（**逐件**）

- **旧值** ＝ `git show HEAD:<路径>` 现算（换代前 `git status` 对 `evidence/` **clean ⇒ 在册件 ≡ `HEAD`**，故 `HEAD` 值即换代前现值）。
- **新值** ＝ 换代后工作树现算。
- 读时（本趟）＝ `2026-10-01T13:5x+0800`。

| 件（`evidence/…`） | 旧 `sha16`（`HEAD`） | 新 `sha16`（现取） | 变？ |
|---|---|---|---|
| `session.txt` | `0047070a7377b044` | `7d80251e6c8ef817` | ✔ |
| `app_g1.log` | `0265aeaaac945c1d`（11306007 B） | `d2b15abb935344d7`（29319572 B） | ✔ |
| `leg_23.env` | `ed64f5c3500cf026` | `442f989e1bf098ae` | ✔ |
| `leg_24.env` | `89e6c5e81043a711` | `344e123e9ad626a7` | ✔ |
| `arm_A/leg_23.env` | `ed64f5c3500cf026` | `442f989e1bf098ae` | ✔ |
| `arm_A/leg_24.env` | `89e6c5e81043a711` | `344e123e9ad626a7` | ✔ |
| `five_pre_g1.txt` | `3f16a2f6152eb43f` | `7bd4c08f882daa08` | ✔ |
| `five_post_g1.txt` | `3f16a2f6152eb43f` | `7bd4c08f882daa08` | ✔ |
| `shots/g1/k24.png` | `791696291d51470b`（106449 B） | `0bdb2dfd05952bc9`（114194 B） | ✔ |
| `shots/g1/k23.png` | `10d0b9d54e649c10`（96957 B） | `10d0b9d54e649c10`（96957 B） | ＝（同值，如实） |
| `shots/g1/last.png` | `10d0b9d54e649c10` | `10d0b9d54e649c10` | ＝（同值，如实） |
| `shots/g1/boot.png` | `b21eb530afd3c66c`（190413 B） | `b21eb530afd3c66c` | ＝（同值，如实） |
| `device.txt` | `e7dcc3b1621a0030`（`X_UP=yes display=:231`） | `e7dcc3b1621a0030` | ＝（同值，如实） |
| `arm_A/device.txt` | `e7dcc3b1621a0030` | `e7dcc3b1621a0030` | ＝（同值，如实） |
| `device/xvfb.log` | `e3b0c44298fc1c14`（0 B） | `e3b0c44298fc1c14`（0 B） | ＝（空件） |
| `device/xfwm.log` | `e3b0c44298fc1c14`（0 B） | `e3b0c44298fc1c14`（0 B） | ＝（空件） |

**换代面（现取）**：`git status --porcelain -- evidence` ⇒ **9 个 ` M`**（`k23.png`／`last.png`／两 `device.txt`／两 `device/*.log` 逐字节未变 ⇒ 不计入 ` M`）。

**五件同趟自证（新）**：`five_pre_g1.txt` ≡ `five_post_g1.txt`（两件同为 `7bd4c08f882daa08`）：
```
libwpfwin32.so=d406f243cdc2c402  wpfgfx_cor3.so=941e69902d82ef02  PresentationCore.dll=ba162811e97e4484
PresentationFramework.dll=1c6c58df6d757f3f  WindowsBase.dll=7f1c38f90e916718
```
**跑腿同趟硬闸（我趟原始日志现取）**：`AUTHORITY: shim=d406f243cdc2c402 pf=1c6c58df6d757f3f ｜ APPDIR: shim=d406f243cdc2c402 pf=1c6c58df6d757f3f` → `POSTSHIM: shim=d406f243cdc2c402 pf=1c6c58df6d757f3f（== authority ⇒ 读数可归因）`；`LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:231`。

---

## §2 ② `PTS_GUARD` 判词原文（现取）

命令：`bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence`　⇒　**`rc=0`**

```
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=20 roster=24 domains=pts-declared,dllimport-entry decl=/home/links-dev/netTest/GitProj/WPFOnLinux/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:3262（**域前提修正**：非 PTS 域判定为**该入口名在声明树里对拍上**（内容锚「DllImport … EntryPoint=<名>」，声明位见 decl 字段）⇒ 该格绿并将名字与声明位如实点名；**不**拿 PTS 在册表判它）
PTS_N1=NECESSARY k=24 file=k24.png fr_sha=0bdb2dfd05952bc9 in_empty_set=no fr_ae_boot=220019 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criteria-satisfied=frame-identity,frame-displacement phase=realized
PTS_N1=NECESSARY k=23 file=k23.png fr_sha=10d0b9d54e649c10 in_empty_set=no fr_ae_boot=189862 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criteria-satisfied=frame-identity,frame-displacement phase=realized
PTS_N1_POS=phase=realized positive=differ(via=compare) n4=10d0b9d54e649c10,791696291d51470b anchor_hits=0 differ=1 via=compare n4_unregistered=1 exception_proof= exception_applies=0
PTS_N1_GATE=PASS phase=realized positive=differ(via=compare) necessary=frame-identity,frame-displacement
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 min=200 base=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=realized
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=realized
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log log_sha16=d2b15abb935344d7
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg24-colors-out-of-band=1220,leg23-colors-out-of-band=636 direction=in-file phase=realized
```

（上文 `PTS_N1`／`PTS_COLORANCHOR` 三行为**判词原文节选**；长句后缀与 `t136`／`t145` 口径句照原样，未删改。）

---

## §3 ③ `PTS_COLORANCHOR` 逐色现取（`hits`）

`k=24`（`FlowDocumentDemo`，锚色集 `GhostWhite`／`Beige`／`DarkGreen`／`LightGoldenrodYellow`；阈值 `min=200`，基线帧 `boot.png` 四色**实算全 0** ⇒ 该计数可判别）：

| 色 | 定值 RGB | 现取 px（新） | ≥200？ | 旧在册 `HEAD`（`T-A52` 前） |
|---|---|---|---|---|
| `GhostWhite` | `248,248,255` | **9794** | ✔ | `22736`（≥200） |
| `Beige` | `245,245,220` | **910** | ✔ | `910`（≥200） |
| `DarkGreen` | `0,100,0` | **44** | ✖（<200，如实） | `44`（<200） |
| `LightGoldenrodYellow` | `250,250,210` | **5830** | ✔ | **`0`** |

（旧在册 `k24` 逐色由 `git show HEAD:…/shots/g1/k24.png` 现算：`sha16=791696291d51470b` ⇒ `GhostWhite=22736／Beige=910／DarkGreen=44／LightGoldenrodYellow=0`。）

⇒ `hits=3`（**旧在册 `hits=2`**：`GhostWhite`＋`Beige`；`LightGoldenrodYellow` 由 `0 → 5830` 为 **`T-A52` 后新落**、`GhostWhite` `22736 → 9794` 随帧换代变化）。判词：`PTS_COLORANCHOR=PASS k=24 … hits=3 min=200 … phase=realized`。
（`k=23` 无登记锚 ⇒ 具名 `NOINFO`，见 §6；**严禁**用 `k=24` 的锚推广。）

---

## §4 ④ 帧面（帧 `sha16`／`AE`）

| 腿 | `fr_file` | `fr_sha`（帧 `sha256` 前16） | `ae`（点击前后像素差） | `fr_ae_boot`（相对 `boot`） | `colors` | `ink` |
|---|---|---|---|---|---|---|
| `k=24` | `k24.png` | `0bdb2dfd05952bc9` | `220019` | `220019` | 1220 | 480000 |
| `k=23` | `k23.png` | `10d0b9d54e649c10` | `136292` | `189862` | 636 | 480000 |
| 基线 | `boot.png` | `b21eb530afd3c66c` | — | — | 386 | 480000 |

- 两腿 `fr_sha` **不等** ⇒ `N1` 正证据闸 `differ(via=compare)` 在场（`k24`／`k23` 帧**真不同**）。
- 两腿 `fr_sha` 均 **∉ `FRAME_EMPTY_SET`**（`{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03}`）、`fr_ae_boot>0` ⇒ `N1=NECESSARY`（**必要非充分**，由 `differ` 正证据补足）。
- `N4` 登记值 `10d0b9d54e649c10,791696291d51470b` 与本趟 `k23,k24` **不逐位相同** ⇒ `n4_unregistered=1`（**如实**：本趟不靠 `n4`，靠 `differ`）。
- 症状面（`leg_*.env` 现取）：两腿 `alive=yes`／`app_rc=143`（`∉{134,139}`）／`magenta=0`／`ns` 命中期望／`five_stable=yes`／`native_gap=0`。

---

## §5 ⑤ `SSC` 现取（`BASELINE=#81` 不得回退）

命令：`bash build/MilBridge/tools/sentinel-spec-check.sh`　⇒　**`rc=0`**

```
SSC=PASS lines=13 keys=13 cmp=IDENTICAL
SSC_VALUE=PASS key=BASELINE v=#81
SSC_VALUE=PASS key=BASELINE_SHA16 v=7cd1bc5c37a74e8d
SSC_VALUE=PASS key=WAVE v=w81-freeze
SSC_VALUE=PASS key=WIN32SHIM v=d406f243cdc2c402
SSC_VALUE=PASS key=PF v=1c6c58df6d757f3f
```
⇒ `BASELINE=#81` **在位**、两枚哨兵 `cmp=IDENTICAL` ⇒ **无回退**（本趟只写 `evidence/**`＋本载体，未触哨兵／基线件）。

---

## §6 ⑥ 具名 `NOINFO`（现取）

- `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=realized` —— `RichTextBoxDemo.xaml` 无具名色 ⇒ `k=23` **本页无锚**（**严禁**用 `k=24` 的锚推广；本支只印具名行、**不折 `cannot`**，本面不给绿这点不变）。
- 本趟判词中 `PTS_GUARD=PASS` 行的 `cannot=-` ⇒ **除上条具名 `NOINFO` 外无其它不可判项**（`k=24` 色锚面 `PASS`，`k=23` 无锚由设计给具名 `NOINFO`）。

---

## §7 装置与纪律自证（boundary）

- **装置口径**：腿跑器 `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`（A 臂，两条腿 `clicks=[24,23]`）；`sync-applocal.sh --check ~/w67-work/app` ⇒ `drift=0 noauth=0`；前置 `device=memok`；`X_UP=yes display=:231`；`DISPLAY_PICK display=:231 rule=lowest-free(base=:231 span=9)`（**只用空闲 `:23x`**）；`DEVICE_REAP state=clean who=xvfb/xfwm`（**只按 PID**）。
- **`temp+rename`（本趟如实两步）**：
  - 方案①：`OUTDIR=evidence.__new_T-A59`（basename 为临时名）跑成 ⇒ `PTS_GUARD=PASS hits=3`；**但** `session.txt` 的 `DISPLAY_LEASE … lease=` 会记临时 basename ⇒ 与在册口径路径形状不符，**弃用**。
  - 方案②（**采用**）：`cd …/PtsPagesProbe/.stage-a59 && … run-pts-pages-legs.sh evidence`（`OUTDIR` basename == `evidence`）⇒ `SESS_LOGDIR=…/w67-work/logs/evidence`、`lease=evidence/device/display-lease.txt`，路径形状与既有在册口径一致；`PTS_GUARD=PASS hits=3`。
  - **换代**：`mv evidence evidence.__o2` → `mv .stage-a59/evidence evidence` → `rm -rf evidence.__o2 .stage-a59`（**残留 0**：`evidence.__*`／`.stage-a59` 均不存在）。
- **重活**：两趟均走 `~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`（`HEAVYSLOT=ACQUIRED waited=0s`／`MEMOK avail≈24.5 GB`／`RELEASED rc=0`）。
- **资源（现取）**：`MemAvailable=24529 MB`；`df -Pk /` 余量 `49392416 kB`（≈47 GB）。
- **残留**：无 `:23x` X socket（`/tmp/.X11-unix` 无 `X23*`）；`ps` 无本趟 `Xvfb`／`xfwm4`／`HandyControlDemo` 残留（在场 `xfwm4 398855` 为**既有他者**，非本趟起）。
- **`evidence/**` 逐字节未提交**（`git status` 9 个 ` M`，**未 `git add`／`commit`／`push`**）。
- **未跑整趟 `verify-all`**（纪律禁）；**未改** `src/**`／生成器／`verify-all.sh`／`build/MilBridge/tools/**`／`docs/**`／基线件。

---

## §8 未做项与原因（如实）

1. 本件为**测量**趟：**未改**任何产品件、判据件、生成器、基线件；唯一写入 ＝ `evidence/**`（换代）＋本载体。
2. 门禁 `[38]` 的真读（`verify-all` 整趟）**未跑**（任务禁）；本件以**同一命令**（`pts-pages-guard.sh --legs evidence`）现取判词，即为门禁该步会读到的读数。
3. `k=23` **无锚**为设计（`RichTextBoxDemo.xaml` 无具名色）⇒ 只有具名 `NOINFO`，**未**为凑 `hits` 而给它造锚。
4. `HEAD` 与在册件的对应关系（换代前 `evidence/` 相对 `HEAD` clean）**现取核实**，故 §1 旧值取 `HEAD` 现算。
