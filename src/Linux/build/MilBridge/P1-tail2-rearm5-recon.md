# P1-tail2 · `T-A46` · 重取臂⑤（在册证据换代）＋ 相位关口评估 —— 测量/侦察件

> **本件 `T-A46`（测量/侦察子代理）交付**。**写域**：在册证据 `build/MilBridge/tests/PtsPagesProbe/evidence/**`（**换代**：逐件 `temp+rename`，旧余件删除）＋ 本载体。**未碰** `src/**`／生成器 `build/PresentationFramework.Linux/reapply-patches.py`／其重产的生成件／`verify-all.sh`／`build/shims/**`／`build/MilBridge/tools/**`（**只读跑**判据件）／`docs/**`／`upstream/**`；**未改相位**（本任务只评估）；未 `git add/commit/push`。
> **口径引用（不是证据）**：队长**裁定二十**／**裁定二十一**／**裁定三十五**／**裁定三十六**（均见 `build/MilBridge/P1-ptsname-result.md`，逐条内容锚：`裁定二十（承 t114 回执）`／`裁定二十一（承 t117 回执）`／`裁定三十五（承 t142 全面回执）`／`裁定三十六（承 t146 全面回执）`）；另**旁引**裁定三十八 (a)／三十九（帧面冻结令）。**它们的读数一条未抄** —— 本件所有读数**现取**（一趟腿 ＋ 守卫现跑）。前件 `T-A34` 载体（`P1-tail2-rearm4-recon.md`）／`T-A45` 载体（`P1-tail2-onscreen-impl-report.md`）**只作对照**，读数逐格由本件现取复算，**未抄**。
> **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。

---

## §0 结论速览（自包含）

1. **重取说明**：在**现 `.so 5b7d0ac101673900`**（现取，＝ 现 authority）＋ 现 PC 上跑**两页真腿**（`k=24`／`k=23`，A 臂，仓内 `run-pts-pages-legs.sh` `sha16=330a90f1f0ac28e4`），**照在册装置口径**（Xvfb＋`xfwm4 --compositor=off`、显示位 `:231` 由跑器「最小空闲」自取、私有 `W=~/w67-work/app`、`sync-applocal.sh --check drift=0`、重活槽 `--min-avail 2500 --max-hold 1800 --wait 3600`；`HEAVYSLOT=ACQUIRED/MEMOK/RELEASED held=34s`）。⇒ `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:231`。
2. ✅ **在册 `evidence/` 已换代**：**旧余件 13 件删除 ＋ 4 个空目录清除**；**新代 16 件逐件 `temp+rename` 装入**（旧/新 `sha16` 成对见 §2）。**唯一未换的字节**＝ `shots/g1/boot.png`（`b21eb530afd3c66c`，boot 帧在旧/新两代同值）。
3. 🔴 **官方判词（degraded 原样、在册目录）＝ `PTS_GUARD=FAIL`**（`rc=1`）：`fails=leg24-placeholder-missing,leg24-named-line,leg23-placeholder-missing,leg23-named-line,native-ledger-absent(PTS_GAP n=0)`（判词原文见 §3.1）。这 5 条**全是 `phase=degraded` 期**的止损绿条件（占位洋红 ＋ 具名行 ＋ native 台账）——**本增量(色锚落位)一条未消、也一条未新增**。
4. ✅ **`PTS_COLORANCHOR=PASS k=24 hits=2`**（现取逐色：`GhostWhite=22736`／**`Beige=910`**／**`DarkGreen=44`**／`LightGoldenrodYellow=0`；基线 `boot.png` 四色**全 0**）；`k=23` 记 `NOINFO reason=no-anchor-registered-for-k23`（**禁推广**）。⇒ T-A45 的色锚落位**在本趟独立重取上成立且帧面逐字节可复现**。
5. ⚠️ **相位评估 ＝ 不可翻（`PTS-PHASE-ASSESSMENT=NO-FLIP`）**：前置 `magenta=0` ✔ ｜**无具名降级行**：**窄口径** ✔、**广口径 ✘**（`[HC-UNHANDLED]=1`，`ArgumentException: Specified Visual is already a child…`）｜**真实排版＝色锚 PASS** ✔ ｜`N1` ✔ ｜`N3` ✔ ｜**`N4` ✘（未登记）** ⇒ 裁定二十一 ② 的「与 `N1–N4` 同趟落定」**未达成**（逐条见 §5）。**新事实（与 `T-A34` 不同）**：`realized` 副本现取 **`PTS_GUARD=PASS` `rc=0`** —— 即"翻相位"的后果**不再是当场红**；但按裁定三十五 (a)／(d)，`N4` 那条**未被独立支撑的登记通道**一旦随相位开启即会把空态帧洗成绿 ⇒ **仍判不可翻**（理由见 §5.3）。
6. **具名 `NOINFO` 八条**（见 §6.2），其中最要紧两条：`NOINFO-N4-POSITIVE-FP`（正身份载体未登记）／`NOINFO-PROBE-GATE-OFF`（本趟探针闸＝开，裁定三十六 (c)② 要求的"闸关代"读数**未取**）。

---

## §1 装置 · 代际 · 工具（现取）

| 项 | 本趟（`:231`） |
|---|---|
| 证据目录（在册） | `build/MilBridge/tests/PtsPagesProbe/evidence/` |
| 腿跑器 | 仓内 `run-pts-pages-legs.sh`（`sha16=330a90f1f0ac28e4`） |
| 会话件 | `session_inner.sh`（`sha16=f1a582d9ea9788c9`） |
| 判据件 | `pts-pages-guard.sh`（`sha16=962fec114b2d0692`） |
| `LEGS_TOOLS` 现取 | `runner_sha16=330a90f1f0ac28e4 session_sha16=f1a582d9ea9788c9 guard_sha16=962fec114b2d0692`（＝ `T-A45` 同批工具） |
| 显示位 | `DISPLAY_PICK display=:231 rule=lowest-free(base=:231 span=9) waited_ms=0`；`device.txt` ＝ `X_UP=yes display=:231` |
| 装置 | `Xvfb :231 1280x1024x24` ＋ `xfwm4 --compositor=off`；`DEVICE_REAP state=clean`（xvfb/xfwm 各一） |
| 槽 | `HEAVYSLOT=ACQUIRED waited=0s`／`HEAVYSLOT=MEMOK avail=24551MB min_avail=2500MB`／`HEAVYSLOT=RELEASED rc=0 held=34s` |
| 应用目录（仓外私有） | `~/w67-work/app`；`SYNC-APPLOCAL=PASS … drift=0`；`AUTHORITY: shim=5b7d0ac101673900 pf=b6d6575dbca4f714 ｜ APPDIR: shim=5b7d0ac101673900 pf=b6d6575dbca4f714` |
| 件守卫（前后） | `POSTSHIM: shim=5b7d0ac101673900 pf=b6d6575dbca4f714（== authority ⇒ 读数可归因）` |
| 腿/计数 | `LEGSCOUNT requested=2 obtained=2 refused=0 reasons=none display=:231 rc=0 session_rc=0 conv_rc=0` |

**代际四元组（现取）**：

| 趟 | 主链 `.so`（`shim16`） | `pf16` | 帧（`sha16`／字节） |
|---|---|---|---|
| **旧（换代前 `evidence/`）** | `5ddc9d63b5232f96` | `c52d9191feb5ba7c` | `boot=b21eb530afd3c66c`／`190413`；`k23=k24=last=ef3fd6765f18f51b`／`189716` |
| **新（换代后 `evidence/`）** | **`5b7d0ac101673900`** | **`b6d6575dbca4f714`** | `boot=b21eb530afd3c66c`／`190413`；**`k23=10d0b9d54e649c10`／`96957`，`k24=791696291d51470b`／`106449`，`last=10d0b9d54e649c10`／`96957`** |

> ⚠️ **跨代不可比（纪律 31/32）**："旧"（`5ddc9d63…`）／"新"（`5b7d0ac1…`）是**两代 `.so`** ＋ **两趟不同时刻**；下表"逐字段"只报**结果**，**不得**读成"可相减的同一条件"。
> ⚠️ **`FRAME_EMPTY_SET`（判据件件头唯一登记处，现取）** ＝ `{1a76488aa4a790b3, ef3fd6765f18f51b, b273ebecc332fc03}` ⇒ 新代 `k23`／`k24` **均 ∉ 集**。
> ⚠️ **探针闸状态（裁定三十六 (c)①）**：本趟在 **`WPF_PTS_DRIVE_PROBE` 缺省＝开**下取（`win32_pts.c` 现取：仅**显式** `"0"` 才关；缺省/空/其它皆开）—— 本趟日志现取 `[DRIVE-PROBE-ENTER]` **3** 行、`gate-off` **0** 行 ⇒ **闸＝开**。**跨闸状态不可比**；"闸关代"读数见 `NOINFO-PROBE-GATE-OFF`。

---

## §2 ① 在册证据**换代**（旧/新 `sha16` 成对 ＋ 逐件改名）

**手法（逐条可复核）**：跑器先产出到暂存目录（`~/tA46-work/stage/evidence`），**再逐件 `cp → <dst>.tA46tmp.<pid> → mv -f` 装入在册 `evidence/`**（＝ `temp+rename`，**无就地重写**）；随后删除"旧有今无"的余件、自底向上清空空目录。**所有写动作均在 `evidence/**` 内**。跑前旧代整棵已 `cp -a` 备份至仓外 `~/tA46-work/bak/evidence-old-20260930-200006/`。

### 2.1 逐件旧/新 `sha16` 成对（现取 `sha256sum | cut -c1-16`）

| 件（相对 `evidence/`） | 旧 `sha16` | 字节 | 新 `sha16` | 字节 | 换 |
|---|---|---|---|---|---|
| `app_g1.log` | `84db0eb62d15e0b2` | 551555 | `f051e8674b786533` | 277038 | ✔ |
| `arm_A/device.txt` | `6d2cf7572e7323b7` | 22 | `e7dcc3b1621a0030` | 22 | ✔ |
| `arm_A/leg_23.env` | `285913567aad8516` | 422 | `bd7e245843b94d9f` | 428 | ✔ |
| `arm_A/leg_24.env` | `f89dac2796faa25d` | 427 | `7cbb8f28d81f9e0a` | 429 | ✔ |
| `device.txt` | `6d2cf7572e7323b7` | 22 | `e7dcc3b1621a0030` | 22 | ✔ |
| `device/xfwm.log` | `8b2ffb25e89441d3` | 170 | `e3b0c44298fc1c14` | 0 | ✔ |
| `device/xvfb.log` | `e3b0c44298fc1c14` | 0 | `e3b0c44298fc1c14` | 0 | ✘（同值） |
| `five_post_g1.txt` | `66b62cd0ba779989` | 178 | `e762eac7afe5ef83` | 178 | ✔ |
| `five_pre_g1.txt` | `66b62cd0ba779989` | 178 | `e762eac7afe5ef83` | 178 | ✔ |
| `leg_23.env` | `285913567aad8516` | 422 | `bd7e245843b94d9f` | 428 | ✔ |
| `leg_24.env` | `f89dac2796faa25d` | 427 | `7cbb8f28d81f9e0a` | 429 | ✔ |
| `session.txt` | `f29093f89eda4f4f` | 2525 | `22d38b21e9cffcbc` | 2632 | ✔ |
| `shots/g1/boot.png` | `b21eb530afd3c66c` | 190413 | `b21eb530afd3c66c` | 190413 | ✘（同值，boot 帧） |
| `shots/g1/k23.png` | `ef3fd6765f18f51b` | 189716 | `10d0b9d54e649c10` | 96957 | ✔ |
| `shots/g1/k24.png` | `ef3fd6765f18f51b` | 189716 | `791696291d51470b` | 106449 | ✔ |
| `shots/g1/last.png` | `ef3fd6765f18f51b` | 189716 | `10d0b9d54e649c10` | 96957 | ✔ |

### 2.2 逐件改名（安装）与旧余件清除（现取）

```
新代装入 16 件（temp+rename；mode 现取：leg_*.env/device.txt/session.txt=664，*.log/*.png/device.txt=644/664 随源）：
  app_g1.log  arm_A/device.txt  arm_A/leg_23.env  arm_A/leg_24.env  device.txt
  device/xfwm.log  device/xvfb.log  five_post_g1.txt  five_pre_g1.txt
  leg_23.env  leg_24.env  session.txt
  shots/g1/boot.png  shots/g1/k23.png  shots/g1/k24.png  shots/g1/last.png

旧余件删除 13 件（旧有今无）：
  arm_A/app_g1.log（旧 `ed782d28a794cea5`）
  arm_A/arm_A/{device.txt,leg_23.env,leg_24.env}（旧 `6d2cf7572e7323b7`/`ae26bbfa7976c776`/`8d103daa32cf24d5`）
  arm_A/device/{xfwm.log,xvfb.log}（旧 `7438c1ffec6981f4`/`e3b0c44298fc1c14`）
  arm_A/five_{pre,post}_g1.txt（旧 `f030f4f19765135d`）
  arm_A/session.txt（旧 `45ec96090f4f2c95`）
  arm_A/shots/g1/{boot,k23,k24,last}.png（旧 `b21eb530afd3c66c`/`e2bc5d507e19a032`/`de9af3806fea7a5f`/`e2bc5d507e19a032`）

空目录清除 4 个：arm_A/device  arm_A/arm_A  arm_A/shots/g1  arm_A/shots
```

⇒ **换代后 `find evidence -type f` 恰好 ＝ 上表 16 件**（无余件、无空目录）；新代 `arm_A/` 只含跑器自产的 `device.txt`＋`leg_23.env`＋`leg_24.env`（旧代里那套**嵌套整树拷贝**余件一并清掉）。

⚠️ **一处侧效（如实披露，具名 `NOINFO`）**：本趟跑器先产出到暂存目录，故 `session.txt` 里的 `DISPLAY_LEASE=…` 行引用的路径是**暂存目录**（`…/tA46-work/stage/evidence/device/display-lease.txt`），**非**在册目录 —— 该 lease 件在跑器收尾时已被 `rm -f`、本就**悬空引用**（旧代同样悬空，引的是在册路径）；此路径**不被判据读取**（守卫只读 `leg_*.env`／`device.txt`／`app_g1.log`／`shots/g1/*.png`）。见 `NOINFO-STAGE-LEASE-PATH`。

---

## §3 ② 判词原文（现取）

### 3.1 官方命令（`degraded`，在册目录、仓内件原样，`rc=1`）

```
$ bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=12 roster=24 domains=pts-declared,dllimport-entry decl=/home/links-dev/netTest/GitProj/WPFOnLinux/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:3168（**域前提修正**：非 PTS 域判定为**该入口名在声明树里对拍上**（内容锚「DllImport … EntryPoint=<名>」，声明位见 decl 字段）⇒ 该格绿并将名字与声明位如实点名；**不**拿 PTS 在册表判它）
PTS_N1=INFO k=24 file=k24.png fr_sha=791696291d51470b in_empty_set=no fr_ae_boot=220019 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} phase=degraded（止损期不据此判红；相位翻转后本条生效 —— 口径见 t124 段）
PTS_N1=INFO k=23 file=k23.png fr_sha=10d0b9d54e649c10 in_empty_set=no fr_ae_boot=189862 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} phase=degraded（止损期不据此判红；相位翻转后本条生效 —— 口径见 t124 段）
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none（**阈值由本基线标定**：基线全 0 ⇒ 该计数能分开有该色/没该色；`LightGray` 不入集——它在空态帧里已有 44/51 px）
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=0 hits=2 min=200 base=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=degraded（该页**具名色成片出现** ⇒ 该页内容至少部分真绘出；⚠️ **只准读成这一件事**，不得替代 `N1`/`N3`）
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=degraded（`RichTextBoxDemo.xaml` 无具名色 ⇒ **本页无锚**；**严禁**用 k=24 的锚推广。⏪ `t145`：本支**只印具名 NOINFO 行、不折 `cannot`** —— 否则任何没有 k=24 帧的证据目录都会被整体读成不可判；**本面不给绿**这一点不变）
PTS_ENFE=INFO total=0 by_name=none allow=none non_allow=none phase=degraded log=build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log log_sha16=f051e8674b786533（止损期不据此判红；相位翻转后本条生效 —— 口径见 t122 段；**引用必须连 log ＋ log_sha16 一起引**，见 t136 F-2）
PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=degraded
```

⇒ **`PTS_GUARD=FAIL`（`rc=1`）**。**5 条 `fails` 逐条**：`leg24-placeholder-missing`／`leg24-named-line`／`leg23-placeholder-missing`／`leg23-named-line`＝**degraded 期的止损绿条件**（占位洋红 ≥20000 ＋ 具名 `err=-10000`）**本代已不成立**（现取 `magenta=0`、`err=-`）；`native-ledger-absent(PTS_GAP n=0)`＝`PTS_GAP` 台账**为空**（与 `T-A45`／`T-A34` 同形）。`diag=leg23-colors-out-of-band=636`（k23 `colors=636 < 800` 出带；k24 `colors=905` **在带内**）。

### 3.2 `realized` 副本（**只改相位位、仓内件一字未改**；`rc=0`）—— 本趟最要紧的一条

```
$ sed 's/^\(# PTS-DIRECTION: .*\)phase=degraded$/\1phase=realized/' build/MilBridge/tools/pts-pages-guard.sh > ~/tA46-work/guard-realized.sh
$ sha16: 副本=fdf0d401a3ba720d ｜ 原件=962fec114b2d0692
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=12 roster=24 domains=pts-declared,dllimport-entry decl=…/PtsHost/Pts.cs:3168
PTS_N1=NECESSARY k=24 … fr_sha=791696291d51470b in_empty_set=no fr_ae_boot=220019 criteria-satisfied=frame-identity,frame-displacement phase=realized
PTS_N1=NECESSARY k=23 … fr_sha=10d0b9d54e649c10 in_empty_set=no fr_ae_boot=189862 criteria-satisfied=frame-identity,frame-displacement phase=realized
PTS_N1_POS=phase=realized positive=differ(via=compare) n4=absent anchor_hits=0 differ=1 via=compare n4_unregistered=1 exception_proof= exception_applies=0（三源口径见 t136 段；「∉ 参照集」单独**不给绿**）
PTS_N1_GATE=PASS phase=realized positive=differ(via=compare) necessary=frame-identity,frame-displacement（正证据在场 ⇒ 必要件之上**重新**成立；这不改变既有四要件）
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=0 hits=2 min=200 base=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=realized
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=realized
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=…/evidence/app_g1.log log_sha16=f051e8674b786533
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=realized
```

> 🔴 **读法（写死）**：`realized` 副本现取 **`PTS_GUARD=PASS` `rc=0`、`fails=-`** —— **与 `T-A34` 的 realized 判词（唯一红 ＝ `leg24-color-anchor-absent`）不同**：色锚落位后那条红**已消**。**但**：`N1_GATE=PASS` 只说明"现取有一源正证据（两页帧 `differ`）"，`positive=differ` 且 **`n4=absent`／`n4_unregistered=1`／`anchor_hits=0`** ⇒ **不**等于"该页内容已由正身份登记背书"（这恰是裁定三十五 (a) 的射程）。
> ⚠️ **副本归属**：`realized` 判词取自**仓外副本** `~/tA46-work/guard-realized.sh`（`sha16=fdf0d401a3ba720d`；`sed` **只改相位位**）——与守卫自带 `--selftest` 造副本的形态相同；**在册判据件 `PTS-DIRECTION` 行一字未动**。

---

## §4 ③④ 色锚逐色 ＋ 帧面（现取）

### 4.1 `PTS_COLORANCHOR` 逐色（守卫现取 ＋ 本席只读 `PIL` 独立复算）

| 帧 | 腿 | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `hits(≥200px)` | `ncolors` |
|---|---|---|---|---|---|---|---|
| `boot.png` | 基线 | **0** | **0** | **0** | **0** | 0 | 386 |
| **`k24.png`** | 新 | **22736** | **910** | **44** | **0** | **2** | **905** |
| `k23.png` | 新 | 0 | 0 | 0 | 0 | 0 | 636 |

- 守卫现取：`PTS_COLORANCHOR=PASS k=24 … hits=2`；`PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`。
- 本席 `PIL` 复算（锚集 `GhostWhite=248,248,255`／`Beige=245,245,220`／`DarkGreen=0,100,0`／`LightGoldenrodYellow=250,250,210`，`LightGray` **不入集**）**逐格等于**守卫值。
- **只准读成**："该页（`k24`）具名色成片出现 ⇒ 该页内容**至少部分**真绘出"；**不得**替代 `N1`／`N3`，**不得**外推到 `k23`（裁定三十五 (b)）。
- **未达（如实）**：`LightGoldenrodYellow` 仍 **0 px**（它在 `<Floater>` 内 `<Table>` 的 `<TableRow Background=…>`，需 native `FSFLOATERCBK`，属下一增量；承 `T-A45` §6-1）。

### 4.2 帧面（帧 `sha16`／字节 ＋ `AE`）

| 帧 | `sha16` | 字节 |
|---|---|---|
| `boot.png` | `b21eb530afd3c66c` | 190413 |
| `k23.png` | `10d0b9d54e649c10` | 96957 |
| `k24.png` | `791696291d51470b` | 106449 |
| `last.png` | `10d0b9d54e649c10` | 96957 |

```
AE(boot,k24)=220019   AE(boot,k23)=189862   AE(k23,k24)=136297   （compare -metric AE，现取）
```
- **`N1` 要件①**（帧 `sha16` ∉ `FRAME_EMPTY_SET`）：`k23=10d0b9d5…`／`k24=79169629…` 均 **∉ 集** ⇒ 成立（**必要非充分**）。
- **`N1` 要件②**（`fr_ae_boot>0`）：`220019`／`189862 > 0` ⇒ 成立。
- **`N3`**（两页帧**真不同**）：`AE(k23,k24)=136297>0`、两 `fr_sha` 不等 ⇒ **绿**。
- **内容像素身份（承 `T-A34` 口径）**：占位棕色族（本席口径 `180≤r≤220 ∧ 125≤g≤170 ∧ 105≤b≤145`）在 `boot=121477`、`k23=0`、`k24=0` ⇒ **占位图在 `k23`／`k24` 上消失**。
- **`FRAME` 机读行（`leg_<k>.env` 现取原文）**：
```
FRAME k=24 fr_file=k24.png fr_sha=791696291d51470b fr_lsha=791696291d51470b fr_ae_boot=220019
FRAME k=23 fr_file=k23.png fr_sha=10d0b9d54e649c10 fr_lsha=10d0b9d54e649c10 fr_ae_boot=189862
```
- ⚠️ **帧面冻结令（旁引裁定三十八 (a)／三十九）**：`PRECOND-FRAME-DETERMINISM` 仍未满足（跨代不确定）⇒ 本件**不**据任一帧面读数**单向**下判；本趟**单样本**，**未**取同装置内变体分布（见 `NOINFO-FRAME-DETERMINISM`）。
- ⚠️ **探针闸**：本趟读数均在**闸开**状态取（见 §1）；跨闸不可比。

### 4.3 机读面（现取 `grep -c`，新 `app_g1.log` `sha16=f051e8674b786533`／`277038 B`／`2351` 行）

| 面 | 旧（换代前） | 新（换代后） |
|---|---|---|
| `[PTS-UNAVAILABLE]` | 0 | **0** |
| `[FS_PAGE_GAP]`／`^PTS_GAP entry=` | 0／0 | **0／0** |
| `[HC-UNHANDLED]` | （旧日志未逐面取） | **1** |
| `entry point named`（`ENFE`） | — | **0** |
| `EntryPointNotFoundException`／`FailFast`／`Unrecoverable` | — | **0／0／0** |
| `reason=no-text-line-model` | 0 | **0** |
| `[FSQTD]`／`[FSQLL]`／`[FSQSTD]`／`[FSQSPL]`／`[SUBENUM]` | — | **41／19／55／55／3** |
| `[CHAIN] ONS.FormatFinite`／`TPC.ParaBackground`／`FIG.ValidateVisual`／`SUBPAGE-CREATED` | — | **2／3／3／2** |

**残留 1 条 `[HC-UNHANDLED]` 实名（现取，`evidence/app_g1.log:1521`，本席独立复算）**：
```
[HC-UNHANDLED] #1 ArgumentException: Specified Visual is already a child of another Visual or the root of a CompositionTarget. ｜ 首帧 at System.Windows.Media.VisualCollection.Add(Visual visual)
```
⇒ 与 `T-A34` 的 `[HC-UNHANDLED]`（**曾是** `PtsException: Page formatting engine did not complete formatting operation … '-10000'`，`FsQueryTrackParaList` 拒驱）**不同名**：本代残留的是 **`ArgumentException`（视觉树重复挂子）**。两者都落"**具名未处理行**" ⇒ **广口径"无具名降级行"不成立**（归属/后果见 `NOINFO-HC-UNHANDLED`）。

---

## §5 ⑤ 相位关口评估 ＝ **不可翻**（`PTS-PHASE-ASSESSMENT=NO-FLIP`）

### 5.1 前置逐条（现取）

| # | 前置（本任务给定式） | 现取读数 | 判 |
|---|---|---|---|
| `P-1` | **`magenta=0`** | `leg23`／`leg24` 均 `magenta=0` | **成立**（⚠️ 该条**在空态帧上也曾成立**，单条不指向排版；裁定三十五 (c) 已把 `ink` 判禁用，`magenta` 仍续用但**不单独发绿**） |
| `P-2` | **无具名降级行**（**窄口径**＝`[PTS-UNAVAILABLE]`／`NAMED` 面） | `[PTS-UNAVAILABLE]=0`、`NAMED managed_unavail=0 err=- native_gap=0` | **成立**（窄口径） |
| `P-2′` | **无具名降级行**（**广口径**＝"页面未完成/未处理"的具名行） | `[HC-UNHANDLED] … ArgumentException …VisualCollection.Add` **1** 行 | **✘ 不成立** |
| `P-3` | **真实排版（色锚 PASS）** | `PTS_COLORANCHOR=PASS k=24 hits=2`（`Beige=910`／`DarkGreen=44`；基线全 0）**✔**；两页帧真不同 **✔**；帧 ∉ 空态集 **✔**；占位消失 `121477→0` **✔**；`k=23` 色锚 `NOINFO`（无锚） | **成立**（对 `k24`；`k23` 记 `NOINFO`，**禁推广**） |
| `P-4a` | **`N1` 同趟** | 必要件①②成立；`positive=differ(via=compare)` ⇒ `PTS_N1_GATE=PASS`；`n4=absent anchor_hits=0 differ=1 n4_unregistered=1` | **必要件成立**（正证据**单一**，仅 `differ`） |
| `P-4b` | **`N3` 同趟** | 两页帧不同、`AE(k23,k24)=136297>0` ⇒ **绿** | **成立** |
| `P-4c` | **`N4` 同趟** | `PTS_N4_POSITIVE_FP` **未登记**；`n4_unregistered=1`；无"该页专属期望指纹"载体 | **`NOINFO`**（裁定三十五 (a) 禁"登记即算"） |

### 5.2 逐条裁定依据（裁定二十／二十一／三十五／三十六）

- **裁定二十一 ②** ＝「**相位翻转的新硬前置 ＝ 与 `N1–N4` 同趟落定**」⇒ 现取 **`N4=NOINFO`**（`n4_unregistered=1`）⇒ **前置未落定**。另：该条「`leg23-AE=0` 不该消、该升为承重判据」⇒ 现取 `leg23 AE=136297≠0`（**已消**），此项**不再阻塞**（但 `k23` 仍无锚）。
- **裁定三十五 (a)** ＝ `N4` 登记**必须附独立可证伪读数**（否则 `N4-DECLARED-ONLY`、不给绿），并把「登记须带支撑读数」写进**相位翻转包**（否则相位一翻，该通道会把空态帧洗成绿）⇒ 本件**不**擅自登记；该加固**仍缺**。
- **裁定三十五 (b)** ＝ 色锚**缺席即红、成片即绿**；`k=23` 无锚记 `NOINFO`（禁推广）⇒ 现取 `k24 hits=2`（**绿**）、`k23 NOINFO`。
- **裁定三十五 (d)** ＝「**不准翻相位（今天）**；准许的下一步 ＝ (b) 色锚读数 ＋ (a) 登记加固，**两者都是判据面**」＋「**`N4` 变瓶颈的充要条件 ＝ 「两页帧不同 ∧ `N1` 必要件齐 ∧ `N3` 绿」而 `N4` 仍无登记**」⇒ **现取该充要条件已满足**（两页帧不同 ✔ ∧ `N1` 必要件齐 ✔ ∧ `N3` 绿 ✔ ∧ `N4` 无登记 ✔）⇒ **`N4` 是当前唯一剩余瓶颈**；(b) 色锚加固**已落成**（`PASS`）、(a) 登记加固**仍缺** ⇒ **翻转项仍禁**。
- **裁定三十六 (c)** ＝ ① 帧面读数**必须带探针闸状态**（本件已带，见 §1：闸＝开）；② `N1` 要件① 之成立**应在闸关闭的那一代上取**（本件**未**另跑"闸关"腿 ⇒ 见 `NOINFO-PROBE-GATE-OFF`）；③ **帧面绿永不单独支撑任何排版结论**（本件 `N1_GATE=PASS` 仅凭 `N1_POS` 的 `differ`，**不**据此判"真排版"）。
- **裁定二十** ＝「维持 `degraded`；翻转是**协同动作**（判据件写者**同趟**改相位位 ＋ 同步改那 10 条 degraded 正控期望 ＋ 独立复核），**一次做完**」⇒ 本件是**测量/侦察件**，**无权改相位**。
- **旁引裁定三十八 (a)／三十九（帧面冻结令）** ＝「帧内容类要件在 `PRECOND-FRAME-DETERMINISM` 取得读数前**不得单独支撑绿、也不得单独支撑红**」⇒ 本件**不**据任一帧面读数**单向**下判。

### 5.3 结论（可翻／不可翻 ＋ 后果）

⇒ **`PTS-PHASE-ASSESSMENT=NO-FLIP`（不可翻）**。依据二条**逐句**：
1. **硬前置未落定**：裁定二十一 ② 要求「与 `N1–N4` 同趟落定」，现取 `N4=NOINFO`（未登记、`n4_unregistered=1`）⇒ **该前置未达成**；裁定三十五 (a) 的登记加固**仍缺**。
2. **`N4` 现取已是唯一瓶颈**（裁定三十五 (d) 的充要条件现取满足）⇒ 按该条，**准许的下一步只剩 `N4` 登记加固**，翻转项仍禁；此时若翻，就会把一个**尚未被独立支撑的 `N4` 通道**随相位一起开启 —— 正是裁定三十五 (a) 写明要防的"**相位一翻，这条通道直接把空态帧洗成绿**"。
3. **新增旁证（如实记，不改结论）**：`realized` 副本现取 **`PTS_GUARD=PASS`**（`rc=0`）——即"翻相位"的后果**不再是当场红**（`T-A34` 时是）。**但这不构成"可翻"**：裁定二十一 ② 的硬前置是 `N1–N4` 同趟，而该前置**恰是防"判据放松"**的那一道闸；`realized` 变绿只说明"（该页部分内容真绘出后）degraded 期的止损绿条件与新相位不再相斥"，**不等于**"翻转前置已满足"。
4. **另一处独立否决**：**广口径"无具名降级行"仍不成立**（`[HC-UNHANDLED]=1`）⇒ 前置合取式**至少两项不齐**（`P-2′` 与 `P-4c`）。

**若日后 `N4` 登记加固落成（附独立可证伪读数，裁定三十五 (a)），"翻转包"应含（现列，供后人执行；本件不执行）**：① 判据件写者**同趟**把 `pts-pages-guard.sh:51` 的 `PTS-DIRECTION` 相位位 `degraded→realized`；② **同步**改该件自带 `--selftest` 里那 10 条 `degraded` 正控期望（现取 `PTS_GUARD_SELFTEST` 须复跑给 `pass/fail`）；③ 在册 `evidence/` 与本件的判词**同趟重取**并给 `PTS_GUARD` 成对；④ `N4` 正身份载体（两页各自、附守卫自算支撑读数）；⑤ `k=23` 活锚另立（**禁**用 `k24` 锚推广）；⑥ 独立复核。**本件不执行其中任何一项**。

---

## §6 ⑥ 具名 `NOINFO` ＋ 下一靶

### 6.1 下一靶（因判**不可翻**）

| # | 靶 | 现取依据 | 期望读数 |
|---|---|---|---|
| `NEXT-1`（**主靶**） | **为 `N4` 登记正身份（附独立可证伪读数）** | `PTS_N4_POSITIVE_FP` 未登记、`n4_unregistered=1`；裁定三十五 (a) 禁"登记即算"，(d) 判其为**唯一瓶颈** | 登记 ＋ 守卫自算支撑成片（`PTS_N4` 不再 `DECLARED-ONLY`） |
| `NEXT-2` | **消掉残留 1 条 `[HC-UNHANDLED]`（`ArgumentException …VisualCollection.Add`）** | `app_g1.log:1521`；广口径"无具名降级行"不成立 | `[HC-UNHANDLED]=0` |
| `NEXT-3` | **`k=24` 补齐第四具名色（`LightGoldenrodYellow`，现 0 px）＋ `k=23` 另立活锚** | `LightGoldenrodYellow=0`；`k23 NOINFO(no-anchor)` | 需 native `FSFLOATERCBK`（`GetFloaterHandlerInfo` 现为具名 GAP）；`k23` 另立活锚（**禁**推广） |
| `NEXT-4` | **帧面确定性 `PRECOND-FRAME-DETERMINISM`** | 旁引裁定三十九／四十 (a) 仍未满足；本趟单样本 | 按族级纪律取 ≥20 独立样本、逐趟记代际指纹 |

### 6.2 具名 `NOINFO` 清单

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-N4-POSITIVE-FP` | **`N4` 正身份载体** | `PTS_N4_POSITIVE_FP` 未登记（`n4_unregistered=1`）；裁定三十五 (a) | 两页各自绘出真内容后，由当趟实现件写者**同趟**登记**带独立可证伪支撑**的正身份 |
| `NOINFO-K23-ANCHOR` | **`k=23` 色锚** | 守卫现取 `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（`RichTextBoxDemo.xaml` 无具名色） | 为 `k=23` 另立"活锚"（**严禁**用 `k=24` 的锚推广） |
| `NOINFO-PROBE-GATE-OFF` | **"探针闸关闭"状态下的帧面读数** | 本趟探针缺省**开**（现取 `[DRIVE-PROBE-ENTER]=3`／`gate-off=0`；`win32_pts.c` 缺省开）；裁定三十六 (c)② 要求 `N1` 要件① 之成立**在闸关闭的那一代上取** | 以 `WPF_PTS_DRIVE_PROBE=0` 跑一趟反极性腿取帧面（**本任务未要求**） |
| `NOINFO-FRAME-DETERMINISM` | **帧面确定性** | 旁引裁定三十九／四十 (a)：`PRECOND-FRAME-DETERMINISM` 未满足；本趟**单样本**、未取同装置内变体分布 | 取 ≥20 独立样本 ＋ 批内代际守卫；或把判据重述为"变体集内的成员资格"并为其提供独立正证据 |
| `NOINFO-HC-UNHANDLED` | **残留 `ArgumentException（Visual 重复挂子）` 的归属与后果** | 现取为唯一残留 `[HC-UNHANDLED]`；本件**只测**、不实现 | 由实现件写者按裁定二十三 (c)① 铁律（诚实形态：失败必留痕）**同趟**落地 |
| `NOINFO-LIGHTGOLDENRODYELLOW` | **第四具名色 `LightGoldenrodYellow` 为何仍 0** | 它在 `<Floater>` 内 `<Table>` 的 `<TableRow Background=…>` ⇒ 需 native `FSFLOATERCBK`（`GetFloaterHandlerInfo` 现为具名 GAP，`FsCreateSubpageBottomless` 不在 `exports.txt`） | native 让 Floater 内容进布局（承 `T-A45` §6-1） |
| `NOINFO-CROSS-GEN` | **旧/新代的"同一条件相减"** | 两代 `.so` ＋ 两趟不同时刻 ⇒ 跨代不可比（纪律 31/32） | 不适用（本件只报"逐字段/逐字节同值/异值"这一**结果**） |
| `NOINFO-STAGE-LEASE-PATH` | **`session.txt` 的 `DISPLAY_LEASE` 行引用暂存目录路径（非在册路径）** | 本趟跑器先产出到暂存目录再逐件 `temp+rename` 装入在册 `evidence/`；该 lease 件收尾已被删、本就**悬空引用**（旧代同样悬空） | 不适用（该路径**不被判据读取**；属"暂存→装机"换代的**已知侧效**，如实披露） |

---

## §7 可复跑单行命令原文（现取）

```sh
cd /home/links-dev/netTest/GitProj/WPFOnLinux

# 代际/工具身份
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16                 # ⇒ 5b7d0ac101673900
sha256sum build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll | cut -c1-16   # ⇒ b6d6575dbca4f714

# 跑腿（重活槽；A 臂 k=24,23；先产到暂存目录）
bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- \
  bash build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh ~/tA46-work/stage/evidence
# ⇒ LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:231

# 逐件 temp+rename 装入在册 evidence/ ＋ 清旧余件（本件脚本，仓外）
bash ~/tA46-work/install-evidence.sh

# 官方判词（degraded，在册目录）
bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence   # rc=1
# realized 副本（只改相位位；不改仓内件）
bash ~/tA46-work/guard-official.sh                                                                 # 内含两跑

# 帧面
for f in boot k23 k24 last; do sha256sum build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/$f.png | cut -c1-16; done
compare -metric AE build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/k23.png \
                  build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/k24.png null:   # ⇒ 136297
```

---

## §8 边界 · 纪律 · 主动披露

1. **写域**：**只**动在册 `build/MilBridge/tests/PtsPagesProbe/evidence/**`（**换代**：16 件逐件 `temp+rename` 装入 ＋ 13 件旧余件删除 ＋ 4 空目录清除）＋ 本载体。**未碰** `src/**`／生成器／生成件／`verify-all.sh`／`build/shims/**`／`build/MilBridge/tools/**`（**只读跑**判据件）／`docs/**`／`upstream/**`；**未改相位**（`pts-pages-guard.sh` 的 `PTS-DIRECTION` 行一字未动，`realized` 判词取自**仓外副本** `sha16=fdf0d401a3ba720d`）；未 `git add/commit/push`。
2. **重活全走槽**：`~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`（`HEAVYSLOT=ACQUIRED/MEMOK/RELEASED rc=0 held=34s`）；进程只按 PID（跑器自收 `Xvfb`／`xfwm4`，`DEVICE_REAP state=clean`）；显示位只用空闲 `:23x`（本趟跑器自取 `:231`，`waited_ms=0`）；禁 `sleep` 轮询；**未跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`。
3. **方案数 ＝ 1**（A 臂一趟；`run-pts-pages-legs.sh` 缺省即 A 臂 `k=24,23`）；**未**跑 `--all-arms`、**未**跑反极性腿（`WPF_LINEVIS_ONSCREEN=0`／`WPF_PTS_DRIVE_PROBE=0`）。
4. **跑前备份（仓外）**：旧代整棵 `cp -a` 至 `~/tA46-work/bak/evidence-old-20260930-200006/`；旧/新逐件 `sha16` 清单落 `~/tA46-work/{old,new}-evidence.sha16.tsv`。
5. **换代的"唯一同值件"**：`shots/g1/boot.png`（`b21eb530afd3c66c`）与 `device/xvfb.log`（空件 `e3b0c44298fc1c14`）在旧/新两代**逐字节同值** —— 如实记，**不**当"已换"。
6. **行内变量不可靠（本席未踩，落脚本规避）**：承 `T-A34` §8-6 纪律，本件**凡带变量/判据的步骤一律落脚本再跑**（`~/tA46-work/*.sh`），不在 `Shell` 通道里写 `D=… && cmd "$D"` 形态。
7. **跨代不可比（纪律 31/32）**：§1／§2／§4 的"旧 vs 新"含**两代 `.so`** 与**两趟时刻** ⇒ 只报"逐字段/逐字节同值或异值"这一**结果**，**不做相减**（见 `NOINFO-CROSS-GEN`）。
8. **帧面冻结令 ＋ 探针闸状态**：本件**不**据任一帧面读数**单向**下判；`N1`／`N3`／`N4` 结论均带"不可归因"边界，并已带**探针闸状态**（本趟闸＝开）。
9. **"旧"读数的性质**：§2 的"旧"列取自**换代前的在册 `evidence/`**（`sha16` 由本席**换代前现取**并落 `old-evidence.sha16.tsv`）；性质＝**在册旧代的现核**，非本趟腿产物。
10. **本案不改相位、不新增登记编号、不改牙本体**；`[HC-UNHANDLED]`／`LightGoldenrodYellow`／`N4` 三条只测不实现（本件射程）。
11. **未做的（防被读宽）**：未跑闸关腿／无 WM 腿／反极性腿；未跑整趟 `verify-all`；未动任何牙本体；未新增任何 `D-G<digits>` 登记编号；未改 `docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`win32_classification.c`。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-rearm5-recon.md | sha256sum | cut -c1-16`）= ce5b76f2fb4196a9
