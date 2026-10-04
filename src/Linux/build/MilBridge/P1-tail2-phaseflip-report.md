# `P1-tail2` · `T-A48` · **相位翻转包**（裁定二十／二十一②／三十五(a)）—— 实现/判据报告（**判决：相位位 `degraded→realized` 已同趟落定；`PTS_GUARD=PASS rc=0`；反极必回 `FAIL rc=1`；`--selftest` `82/0`；门禁四件全绿**）

- **读时**：`2026-09-30T20:2x–20:4x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=fbd7631`（**起点与落盘时同值**）。
- **承**：`T-A45`（色锚上屏）／`T-A46`（在册证据换代＋相位关口评估＝`NO-FLIP`）／`T-A47`（消残留 `[HC-UNHANDLED]=1` ⇒ 缺省 `0`）。
- **写域（逐件）**：`build/MilBridge/tools/pts-pages-guard.sh`（相位位 ＋ `red-when=` 口径文字 ＋ `--selftest` 正控夹具/期望/`_dg` 副本 ＋ `N4` 登记位）／在册 `build/MilBridge/tests/PtsPagesProbe/evidence/**`（**换代**：16 件逐件 `temp+rename`，其中 8 件字节变、8 件同值）／复述位现值位（`docs/ROUTES.md` §15 条目 ② 加 dated 结账行 ＋ `build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 追写行）／**新建载体**本件。
- **黑名单遵守**：未动 `verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`；**未跑**整趟 `verify-all`（只按需跑单牙）；未改阈值（`MAGENTA_FLOOR`／`COLOR_ANCHOR_MIN` 一字未动）、未删判据（`degraded` 支**保留**）；未 `git add/commit/push`。
- **重活**：**1 趟跑器**（2 条腿，`bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`，`HEAVYSLOT=ACQUIRED/MEMOK/RELEASED rc=0 held=34s`；显示位 `:231` 装置自取；`DEVICE_REAP state=clean`；进程只按 PID；禁 `sleep` 轮询）。写前 `cp -p` 备份；`temp+rename` 装机；模式守恒。
- **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。**口径**：一切读数**本席现取**；`T-A45/A46/A47` 载体**只作对照**。

---

## §0 结论速览（自包含）

1. ✅ **① 前置逐条现取 —— 全部满足**（逐条见 §1）：`magenta=0` ｜**无具名降级行**（`[HC-UNHANDLED]=0` ∧ `[PTS-UNAVAILABLE]=0` ∧ `NAMED err=-` ∧ `native_gap=0` ∧ `ENFE=0`）｜**真实排版（色锚 `PASS k=24 hits=2`）**｜`N1` ✔｜`N3` ✔（两页帧不同、`AE=136297>0`）｜`N4` ✔（**登记 ＋ 支撑读数**）。
2. ✅ **② 证据换代**：在现权威 `.so 1dbea9026dd7d3d7`／`pf 189e3704cbf4f031` ＋ 现 PC 上重取两页真腿（`LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:231`），在册 `evidence/**` 16 件逐件 `temp+rename` 装入；旧/新 `sha16` 成对见 §2（**8 件变、8 件同值**：帧面与装置四件同值）。
3. ✅ **③ 翻转包三件**（§3）：**(a)** `build/MilBridge/tools/pts-pages-guard.sh` 的相位位 `degraded→realized`（＋同趟重写 `red-when=` 口径文字）；**(b)** 同步改 `--selftest` 的 `degraded` 正控（`good()` 夹具换代 ＋ 期望/副本同趟）；**(c)** 落 `N4` 正身份**登记位**（附**守卫自算**色锚支撑 `2 colors>=200`）。
4. ✅ **④ 复核 —— 判词绿**：**`PTS_GUARD=PASS legs=2/2 fails=- cannot=- direction=in-file phase=realized`（`rc=0`）** ＋ `PTS_COLORANCHOR=PASS k=24 hits=2` ＋ `PTS_N1_GATE=PASS positive=n4(support=color-anchor:2colors>=200),differ(via=compare)`（§4.1）。
5. ✅ **④ 反极 —— 必回 `FAIL`**：**只**把相位位回退为 `degraded`（同一件、`sed` 一处、仓外副本 `sha16=1230364b67a88020`）⇒ `PTS_GUARD=FAIL rc=1`（5 条 `degraded` 期止损条件逐条点名，§4.2）。**两极成对**。
6. ✅ **自测有牙**：`--selftest` **`PTS_GUARD_SELFTEST=PASS pass=82 fail=0`**（**改前＝`82/0`、改后＝`82/0`** ⇒ 例数**未降**、零断言被删，§3.2）。
7. ✅ **⑤ 门禁四件**：`nm==exports==683`（逐名 `diff` 零行）｜`PTSGAP=PASS … so16=1dbea9026dd7d3d7 exports=683`（`rc=0`）｜`DEFREG=PASS declared=225 route_ids=225`（`rc=0`；`DECLDRIFT=0`）｜`REPORTID=PASS`（`rc=0`）。另 `HANDOFF_MV=PASS`（`cell=#1` 同趟追写）／`STATICJAWS=PASS`（该两处**改前**因本增量而红 ⇒ 已消）。
8. ✅ **⑥ 症状门成对**：两腿逐格同（`alive=yes app_rc=143 magenta=0 colors=905/636 ink=480000 ns=…`／`NAMED managed_unavail=0 err=- native_gap=0`）；**唯一位移 ＝ `DEV shim/pf` 的换代**（§4.4）。
9. ⚠️ **具名边界（如实）**：`k=23` 色锚 `NOINFO`（无锚，**禁推广**）；`anchor` 源（`neptune`）**现取命中 0**（"两页真排版"的正证据**靠 `n4` ＋ `differ` 两源**，不靠日志串）；`[HC-UNHANDLED]=0` 是**缺省路径**读数（`T-A47` 的两条反极腿仍各回各自的"红"，本件未复跑）。逐条见 §5。

---

## §1 ① 前置逐条现取（满足/不满足）

**载体 ＝ 新代在册 `build/MilBridge/tests/PtsPagesProbe/evidence/`**（跑器口径：`run-pts-pages-legs.sh sha16=330a90f1f0ac28e4`／`session_inner.sh sha16=f1a582d9ea9788c9`／A 臂 `clicks=[24,23]`）。

| # | 前置（任务给定式） | 现取读数 | 判 |
|---|---|---|---|
| `P-1` | **`magenta=0`** | `leg_24 magenta=0`／`leg_23 magenta=0` | **成立** |
| `P-2` | **无具名降级行** | `NAMED managed_unavail=0 err=- native_gap=0 native_err=-`（两腿）；`[HC-UNHANDLED]` **0** 行；`[PTS-UNAVAILABLE]` **0**；`entry point named`（`ENFE`）**0**；`^PTS_GAP entry=` **0** | **成立**（**广口径亦成立**） |
| `P-3` | **真实排版（色锚 PASS）** | `PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=0 hits=2 min=200`；基线 `boot.png` **四色全 0** | **成立**（对 `k24`；`k23` 记 `NOINFO`，**禁推广**） |
| `P-4a` | **`N1` 同趟** | `k24 fr_sha=791696291d51470b`／`k23 fr_sha=10d0b9d54e649c10`，**均 ∉ `FRAME_EMPTY_SET`**＝`{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03}`；`fr_ae_boot=220019/189862 > 0` | **成立**（**必要非充分**，由正证据闸补强） |
| `P-4b` | **`N3` 同趟** | 两腿 `fr_sha` **不等**；`AE(k23,k24)=136297 > 0`（`compare -metric AE` 现取） | **成立** |
| `P-4c` | **`N4` 同趟** | **登记**＝`PTS_N4_POSITIVE_FP=10d0b9d54e649c10,791696291d51470b`（本件落，见 §3.3）；**支撑读数**＝守卫**自己现算**色锚 `2 colors>=200`（`Beige=910`／`DarkGreen=44`） | **成立**（登记 ∧ 独立可证伪支撑**同时**在位） |

**只读面（现取 `grep -c`，新 `app_g1.log`＝`0265aeaaac945c1d`／`11306007 B`／`58232` 行）**：

| 面 | 值 | 面 | 值 |
|---|---|---|---|
| `[HC-UNHANDLED]` | **0** | `[PTS-UNAVAILABLE]` | **0** |
| `[FS_PAGE_GAP]` | **0** | `^PTS_GAP entry=` | **0** |
| `entry point named`（`ENFE`） | **0** | `[Nn]eptune`（`anchor` 源） | **0** |

> 🔴 **前置结论 ＝ 满足**（六条全成立）。承 `T-A46` 的 `NO-FLIP`：当时两项不齐（`P-2′` 广口径不成立＝`[HC-UNHANDLED]=1`；`P-4c`＝`N4` 未登记）。**本趟两项都已消**：`[HC-UNHANDLED] 1→0`（`T-A47` 的两处收窄 ＋ 换父）与 `N4` **登记＋支撑**（本件落）。

---

## §2 ② 在册证据**换代**（旧/新 `sha16` 成对）

**手法**：跑器先产到暂存目录（`~/tA48-work/stage/evidence`），**再逐件 `cp -p → <dst>.tA48tmp.<pid> → mv -f` 装入在册 `evidence/`**（`temp+rename`，**无就地重写**）；跑前旧代整棵 `cp -a` 备份至仓外 `~/tA48-work/bak/evidence-old-20260930-203116/`。装入后 `find evidence -type f` **恰 16 件**（无余件、无空目录）。

**代际四元组（现取）**：

| 趟 | 主链 `.so`（`shim16`） | `pf16` |
|---|---|---|
| **旧（换代前）** | `5b7d0ac101673900` | `b6d6575dbca4f714` |
| **新（换代后）** | **`1dbea9026dd7d3d7`** | **`189e3704cbf4f031`** |

逐件旧/新 `sha16`（`sha256sum | cut -c1-16` 现取）：

| 件（相对 `evidence/`） | 旧 `sha16` | 字节 | 新 `sha16` | 字节 | 换 |
|---|---|---|---|---|---|
| `app_g1.log` | `f051e8674b786533` | 277038 | `0265aeaaac945c1d` | 11306007 | ✔ |
| `arm_A/leg_23.env` | `bd7e245843b94d9f` | 428 | `ed64f5c3500cf026` | 428 | ✔ |
| `arm_A/leg_24.env` | `7cbb8f28d81f9e0a` | 429 | `89e6c5e81043a711` | 429 | ✔ |
| `five_post_g1.txt` | `e762eac7afe5ef83` | 178 | `3f16a2f6152eb43f` | 178 | ✔ |
| `five_pre_g1.txt` | `e762eac7afe5ef83` | 178 | `3f16a2f6152eb43f` | 178 | ✔ |
| `leg_23.env` | `bd7e245843b94d9f` | 428 | `ed64f5c3500cf026` | 428 | ✔ |
| `leg_24.env` | `7cbb8f28d81f9e0a` | 429 | `89e6c5e81043a711` | 429 | ✔ |
| `session.txt` | `22d38b21e9cffcbc` | 2632 | `0047070a7377b044` | 2634 | ✔ |
| `arm_A/device.txt` | `e7dcc3b1621a0030` | 22 | （同值） | 22 | ✘ |
| `device.txt` | `e7dcc3b1621a0030` | 22 | （同值） | 22 | ✘ |
| `device/xfwm.log`／`device/xvfb.log` | `e3b0c44298fc1c14` | 0 | （同值，空件） | 0 | ✘ |
| `shots/g1/boot.png` | `b21eb530afd3c66c` | 190413 | （同值） | 190413 | ✘ |
| `shots/g1/k23.png` | `10d0b9d54e649c10` | 96957 | （同值） | 96957 | ✘ |
| `shots/g1/k24.png` | `791696291d51470b` | 106449 | （同值） | 106449 | ✘ |
| `shots/g1/last.png` | `10d0b9d54e649c10` | 96957 | （同值） | 96957 | ✘ |

**逐处位移内容（只在 `DEV`／`five_*` 两处，逐字）**：

```
leg_24/23.env  第 3 行：DEV … shim=5b7d0ac101673900 pf=b6d6575dbca4f714
                 ⇒     DEV … shim=1dbea9026dd7d3d7 pf=189e3704cbf4f031
five_{pre,post}_g1.txt  第 1/4 行：libwpfwin32.so=… ／ PresentationFramework.dll=…
                 ⇒ 换代为 1dbea9026dd7d3d7 ／ 189e3704cbf4f031
```

> ⚠️ **一处如实披露**：`app_g1.log` **从 277 KB 涨到 11.3 MB**（`T-A47` 的拒因收窄 ⇒ 分页器把文档走完，§`T-A47`「不再中途止」）—— 这是**现权威缺省路径的真实产物**，本件不做裁剪（裁了就不是同一趟读数）。它只被守卫 `grep` 读（`ENFE`／`anchor`），不影响判词。
> ⚠️ **帧面两代逐字节同值**（`boot/k23/k24/last` 四枚 `sha256` 全同）—— `T-A47` 改的是**日志面**（消 `ArgumentException`）与**拒因**，**不改画面像素** ⇒ 与 `T-A45/A46` 的帧面自洽。

---

## §3 ③ 翻转包（**一次做完**）

### 3.1 相位位 ＋ 口径文字（判据件：`build/MilBridge/tools/pts-pages-guard.sh`）

- **件换代**：`962fec114b2d0692`（1346 行）⇒ **`ead59d60ccfc95b0`**（1377 行）。
- **(a) 唯一机读声明行**（同趟只改这一位为相位开关）：
```
- # PTS-DIRECTION: absent="magenta=0" present-floor=20000 red-when="magenta=0 AND no-named-line AND native_gap=0" source=TASK-0741 phase=degraded
+ # PTS-DIRECTION: absent="magenta=0" present-floor=20000 red-when="magenta>0 OR named-line-present OR native_gap>0" source=TASK-0741 phase=realized
```
- **(b) 口径文字同趟重写**（`D-G142`：口径**在件自身**；`t12` 段那段反转说明**未删**，只加 `⏪ T-A48` dated 行说明相位已翻）：`absent=`／`present-floor=`（**定义／阈值**）**一字未改**（`present-floor` 仍 == 编译常量 `MAGENTA_FLOOR`，`direction_gate()` 照校验）；`red-when=` 由 degraded 缺失语义改写为 **realized 红条件**。
- **(c) `MAGENTA_FLOOR="${PTS_GUARD_MAGENTA_FLOOR:-20000}"` 与 `COLOR_ANCHOR_MIN=200` 等阈值一字未动**；`degraded` 支**保留不删**（legacy ＋ 反极性腿用）。`direction_gate()`（解析＋校验「取不到就响亮失败」）**未动**。

### 3.2 同步改 `--selftest` 的 `degraded` 正控（**夹具 ＋ 期望 ＋ 副本**；`c1–c13` 逐条）

**为什么必须同趟**：`judge_legs` 读**件内相位**；相位一翻，`degraded` 期那些正控（占位洋红 ≥ `20000`／具名 `err=-10000`／`native_gap≥1`）**逐条反向**。**逐条处置（改造点，判据/阈值零改）**：

| 例 | 旧（`degraded` 期） | 新（`realized` 期） | 处置 |
|---|---|---|---|
| **`good()` 夹具** | `magenta=54454/49864 ∧ err=-10000 ∧ native_gap=1` | **`realized` 现权威**：`magenta=0 ∧ err=- ∧ native_gap=0 ∧ ink=480000 ∧ 两腿不同 fr_sha` | **夹具换代**（`c1/c2/c6/c8/c9/c10/c11/c12/c13/c21/c22/c23/c25/c26/c27/c29/c30/c31` 共同基） |
| `c1` 全好 | 期望 `PASS`（54454/49864） | 期望 **`PASS`**（现权威 `0/0`） | 期望**不变**（因夹具同趟换代 ⇒ 仍是正控） |
| `c2` `rc=134/alive=no` | `FAIL` | `FAIL` | 不变（活/死两期都红） |
| `c3` | 「假修：`magenta=0`」`FAIL` | 「具名行仍在 ∧ 台账非零」`FAIL` | 注释改写（**期望不变**） |
| `c4` | 「洋红 `19999`<门槛」`FAIL` | 「占位仍在 `19999`」`FAIL` | 注释改写（**期望不变**） |
| `c5` | 「洋红 `=20000`（边界必过）」**`PASS`** | 「占位仍在 `20000`」**`FAIL`** | **期望反向**（`PASS→FAIL`） |
| `c6` | 点错对象 `NOINFO` | 点错对象 `NOINFO` | **夹具换 realized 形态**（保 `NOINFO` 语义） |
| `c7` | 「无具名行」`FAIL` | 「占位仍在 ∧ 无具名行」`FAIL` | 注释改写（**期望不变**） |
| `c8` | native `err=0` `PASS+DIAG` | 同（`native_err=0`）`PASS+DIAG` | **夹具换 realized 形态**（保 `PASS` 语义） |
| `c9`／`c10` | `NOINFO` | `NOINFO` | 不变（装置自证／空目录） |
| `c11` | 件被换 `NOINFO` | 件被换 `NOINFO` | **夹具换 realized 形态**（保 `NOINFO` 语义） |
| `c12`／`c13` | `FAIL`／`direction=in-file` | 同 | 不变 |

- **`c20` 相位位反极性**：造「相位位缺失」副本的 `sed` 锚 `phase=degraded` **改 `phase=realized`**（判据一字未动）⇒ `PTS_DIRECTION=FAIL` ＋ 判词必红**仍成立**。
- **`degraded` 支覆盖搬进 `_dg`**：同趟新增 **`_dg`（`degraded` 副本，`realized→degraded` 反向 `sed`）**；两条「`degraded` 期」腿（`c34` 的 `PTS_ENFE=INFO`／`N1` 的 `PTS_N1=INFO`）由 `bash "$0"` **改指 `_dg`** ⇒ **`degraded` 支仍被两极化跑到**（`_rz` 因相位已翻＝恒等副本，保留不改）。
- **`--selftest` 判词**：**改前 `PASS pass=82 fail=0`** ⇒ **改后 `PASS pass=82 fail=0`**（**例数未降、零断言被删**；`PTS_GUARD_SELFTEST` 现取见 §4.3）。

### 3.3 `N4` 正身份**登记位**（附**支撑读数**；裁定三十五(a)）

- **落点**：判据件 `build/MilBridge/tools/pts-pages-guard.sh` 的**唯一登记处**（与 `FRAME_EMPTY_SET`／`COLOR_ANCHOR_*` 同处），逐字：
```
: "${PTS_N4_POSITIVE_FP:=10d0b9d54e649c10,791696291d51470b}"
```
- **登记来源（本趟现取，可复跑）**：在册 `evidence/shots/g1/{k23,k24}.png` 的帧 `sha16`（`k23=10d0b9d54e649c10`／`k24=791696291d51470b`）。
- **独立可证伪支撑（写死，承 `t145`）**：守卫**自己现算**的色锚读数 —— `color_px_scan` 在 `k=24` 帧上 `>=COLOR_ANCHOR_MIN(200)` 的色数 **`>=2``**（现取 `Beige=910`／`DarkGreen=44`）⇒ `n4` 源点亮为 `positive=n4(support=color-anchor:2colors>=200)`。
- **零假绿（两条自证）**：① **只登记、无支撑** ⇒ `N4-DECLARED-ONLY`、**不给绿**（折 `cannot`；`--selftest` 的 `t145·(a)`／`(b)` 两腿仍红/仍绿成对）；② **帧面换代** ⇒ 本值 ≠ 实测两腿 `fr_sha` ⇒ `n4` **自动不计**（`n4_unregistered=1`）、退回 `differ`／`anchor` 两源 ⇒ **绝不假绿**。
- **env 可覆盖**（`PTS_N4_POSITIVE_FP` 非空即用其值）⇒ 反极性腿／合成夹具靠**取值**两极化；**未设**「把现帧写进登记位即绿」的路子（支撑要件照旧）。

---

## §4 ④ 复核（判词／反极／自测／门禁／症状门）

### 4.1 官方判词（在册目录、仓内件原样，**`rc=0`**）

```
$ bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=12 roster=24 domains=pts-declared,dllimport-entry decl=…/PtsHost/Pts.cs:3168
PTS_N1=NECESSARY k=24 file=k24.png fr_sha=791696291d51470b in_empty_set=no fr_ae_boot=220019 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criteria-satisfied=frame-identity,frame-displacement phase=realized
PTS_N1=NECESSARY k=23 file=k23.png fr_sha=10d0b9d54e649c10 in_empty_set=no fr_ae_boot=189862 set={…} phase=realized
PTS_N1_POS=phase=realized positive=n4(support=color-anchor:2colors>=200),differ(via=compare) n4=10d0b9d54e649c10,791696291d51470b anchor_hits=0 differ=1 via=compare n4_unregistered=0 exception_proof= exception_applies=0
PTS_N1_GATE=PASS phase=realized positive=n4(support=color-anchor:2colors>=200),differ(via=compare) necessary=frame-identity,frame-displacement
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=0 hits=2 min=200 base=… phase=realized
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=realized
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=…/evidence/app_g1.log log_sha16=0265aeaaac945c1d
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=realized      ← rc=0
```

⇒ **`PTS_GUARD=PASS` ＋ `PTS_COLORANCHOR=PASS k=24 hits=2`**（两个要求同时成立）。`diag=leg23-colors-out-of-band=636` **只在诊断列、不进 `rc`**（`k23 colors=636 < 800` 出带；`k24 colors=905` 在带内）。

### 4.2 反极（**相位位回退 ⇒ 必回 `FAIL`**）

```
$ sed 's/^\(# PTS-DIRECTION: .*\)phase=realized$/\1phase=degraded/' build/MilBridge/tools/pts-pages-guard.sh > ~/tA48-work/guard-reverse-degraded.sh
  副本 sha16 = 1230364b67a88020（本件 962fec114b2d0692 → ead59d60ccfc95b0；副本只差相位位一字）
$ bash ~/tA48-work/guard-reverse-degraded.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence
PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=degraded
   ⇒ rc=1
```

⇒ **两极成对**：**realized（本件）`PASS rc=0` ⇔ degraded（回退）`FAIL rc=1`**（同一证据、同一装置、同一批工具，只差相位位）。这正是 `t12` 的「反转必须成对」——**旧口径下**同一条证据必红。

### 4.3 自测（`--selftest`，无 X、无应用、秒级）

```
$ bash build/MilBridge/tools/pts-pages-guard.sh --selftest
PTS_GUARD_SELFTEST=PASS pass=82 fail=0     （改前同值：pass=82 fail=0）
```

### 4.4 症状门成对 ＋ 帧面（同一 `.so 1dbea9026dd7d3d7`／同一装置 `:231`／同批工具）

| 腿 | `LEG`（旧＝换代前） | `LEG`（新＝换代后） |
|---|---|---|
| `k=24` | `alive=yes app_rc=143 magenta=0 colors=905 ns=…FlowDocumentDemo ae=220019 ink=480000` | **逐格同** |
| `k=23` | `alive=yes app_rc=143 magenta=0 colors=636 ns=…RichTextBoxDemo ae=136297 ink=480000` | **逐格同** |
| `NAMED` | `managed_unavail=0 err=- native_gap=0 native_err=-` | **同** |
| `DEV` | `… shim=5b7d0ac101673900 pf=b6d6575dbca4f714` | **`shim=1dbea9026dd7d3d7 pf=189e3704cbf4f031`（唯一位移）** |

**帧面**：`boot=b21eb530afd3c66c`／`k23=last=10d0b9d54e649c10`／`k24=791696291d51470b`（旧/新**逐字节同值**）；`AE(boot,k24)=220019`／`AE(boot,k23)=189862`／`AE(k23,k24)=136297`。

### 4.5 ⑤ 门禁四件（现取）

```
NM=683 EXPORTS=683                （逐名 diff 零行）
PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=1dbea9026dd7d3d7 exports=683 root=…   （rc=0）
DEFREG=PASS declared=225 route_ids=225                                                          （rc=0；DECLDRIFT=0 keys=-）
REPORTID=PASS files=325 ids=2233 declared=225 glob=build/MilBridge/*report*.md                   （rc=0；含本载体）
HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none                  （cell=#1 同趟追写后）
STATICJAWS=PASS n=34 excluded=30 noinfo=2 n_total=64                                             （cell=#1 未追写时 rc=1 ⇒ 已消）
```

### 4.6 相位位自身的反极性（自测内，未动）

`phase` 位截断 ⇒ `PTS_DIRECTION=FAIL reason=phase-missing-or-invalid` ＋ 判词必红（`c20`）；`PTS-DIRECTION` 行整行删除 ⇒ `PTS_DIRECTION=FAIL reason=directive-absent` ＋ `PTS_GUARD=FAIL fails=direction(missing)`（`c14`）。**两条仍在**（口径自证，`D-G142`）。

---

## §5 具名边界 · `NOINFO` · 未做项（**防被读宽**）

| # | 项 | 现状（现取） | 消掉需要 |
|---|---|---|---|
| `NOINFO-K23-ANCHOR` | `k=23` 色锚 | `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（`RichTextBoxDemo.xaml` 无具名色） | 为 `k=23` 另立**活锚**（**严禁**用 `k24` 的锚推广） |
| `NOINFO-ANCHOR-LOG` | `anchor` 源（内容锚） | `[Nn]eptune` 在新 `app_g1.log` 命中 **0** ⇒ `anchor_hits=0` | 日志侧出现该串（**本件不据此发绿**：正证据靠 `n4` ＋ `differ`） |
| `NOINFO-LIGHTGOLDENRODYELLOW` | 第四具名色 | `LightGoldenrodYellow=0 px`（它在 `<Floater>` 内 `<Table>` 的 `<TableRow Background=…>`，需 native `FSFLOATERCBK`） | native 让 Floater 内容进布局 |
| `NOINFO-HC-UNHANDLED-POLARITY` | `T-A47` 的两条反极腿 | 本件**未复跑**（`WPF_PTS_QTP_LIVE_NARROW=0`／`WPF_FLOAT_REPARENT=0` ⇒ 各回各自的红） | 另派单（**不在本件射程**） |
| `NOINFO-FRAME-DETERMINISM` | 帧面确定性 | 旁引裁定三十八(a)／三十九：`PRECOND-FRAME-DETERMINISM` 仍未满足；本趟**单样本** | 取 ≥20 独立样本 ＋ 批内代际守卫 |
| `NOINFO-PROBE-GATE-OFF` | 「探针闸关闭」代 | 本趟在 `WPF_PTS_DRIVE_PROBE` **缺省＝开**下取 | 以 `=0` 跑一趟反极性腿取帧面 |
| `NOINFO-PAGES-280` | `app_g1.log` 为何 11.3 MB | `T-A47` 的拒因收窄后分页器走完文档（`[QPD]` 去重 280 页）；本件只报"日志面换代"这一**结果** | 独立核对 280 是否为该文档正确页数 |

**未做（防被读宽）**：未跑整趟 `verify-all`；未跑 `--all-arms`（只跑 A 臂 `24,23`）；未跑其它既有反极腿；未动任何**阈值**；未删任何**判据**；未新增 `D-G<digits>` 登记编号；未改 `verify-all.sh`（其 `DECL` 口径句与本件相位位的"同趟跟"**不在本件写域**，见 §6-6）。

---

## §6 边界 · 纪律 · 主动披露

1. **写域自证**（`git status --porcelain` 现取）——本件列出的**件**恰为：`build/MilBridge/tools/pts-pages-guard.sh`（`M`）／在册 `build/MilBridge/tests/PtsPagesProbe/evidence/**`（`M` 8 件：`app_g1.log`／`arm_A/leg_2{3,4}.env`／`five_{pre,post}_g1.txt`／`leg_2{3,4}.env`／`session.txt`）／`docs/ROUTES.md`（`M`）／`build/MilBridge/HANDOFF-NEXT.md`（`M`）／**新建载体**本件 ＋ **先于本件**的 `?? build/MilBridge/tasks-tail2/T-A48.md`。**未动** `verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`／`src/**`／生成器／生成件；未 `git add/commit/push`。
2. **第 `29` 条（备份面 ≡ 改动面）自证**：**改动面** ＝ 上列 4 类；**备份面（仓外 `~/tA48-work/bak/`）** ＝ ① 判据件前像 `pts-pages-guard.sh.pre-tA48`（`962fec114b2d0692`，写前 `cp -p`）＋ ② 旧代在册 `evidence-old-20260930-203116/`（整棵 `cp -a`，16 件）；`docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md` 的前像以 `git show HEAD:<path>` 可取回（**只增不改**：ROUTES 加 dated 行、HANDOFF 追写 `cell=#1`）。**新建件（本载体）无前像**（如实记）。
3. **`P8`／模式守恒**：`guard` 模式（`stat -c %a`）与装机前后一致；`evidence` 逐件 `cp -p` 保源模式后 `mv`。
4. **重活全走槽**：仅 1 趟跑器（`~/heavy-slot.sh`；`HEAVYSLOT=ACQUIRED/MEMOK/RELEASED rc=0 held=34s`）；进程只按 PID（跑器自收 `Xvfb`／`xfwm4`，`DEVICE_REAP state=clean`）；显示位只用空闲 `:23x`（本趟跑器自取 `:231`，`waited_ms=0`）；禁 `sleep` 轮询（槽／跑器自带的有界等待除外）；**未跑**整趟 `verify-all`。
5. **方案数 ＝ 1**（A 臂一趟）；过程件／夹具全在仓外 `~/tA48-work/**`（`bak/`／`stage/`／`*.sh`），**仓内零过程件**。
6. **一处待队长处置（如实点名）**：`verify-all.sh` 第 `[38]` 步 `PTS-PAGES` 的 `DECL` 口径句（历史写 `phase=degraded` 与绿条件）**未随本件同趟改** —— 该件**在本件黑名单内** ⇒ **本件不跑不写**；但 **`PTS-PAGES` 步本体跑的是 `pts-pages-guard.sh --legs <evidence>`**（现取 `verify-all.sh` 该步调用行），⇒ 本件落地后**该步会读到 `PTS_GUARD=PASS`（`phase=realized`）**，其 `DECL` 口径句的"逐字对拍"须由 **`verify-all.sh` 的写者**在下一趟对齐。
7. **跨代不可比（纪律 31/32）**：§2 的"旧 vs 新"含**两代 `.so`**（`5b7d0ac101673900` vs `1dbea9026dd7d3d7`）与**两趟时刻** ⇒ 只报"逐字段/逐字节同值或异值"这一**结果**，**不做相减**。
8. **`N4` 登记的射程（明写）**：本件登记的**正身份指纹**只覆盖**当前帧面**（`k23/k24` 两枚 `sha16`）；它**不**冒充"整页排版正确"，**不**替代 `N1`／`N3`（`t136`／`t145` 口径不变）。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-phaseflip-report.md | sha256sum | cut -c1-16`）= 7d8f1d57237faaf9
