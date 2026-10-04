# P1-W30 · 文档面更正报告（`t104`／`scribe`）—— `F-3` 历史数字恢复 ＋ dated 追加；`F-4` 判据 C2 前提 dated 更正

写者 `scribe`（`t104` attempt 1／`16e717c3-acd3-402f-a3fb-09f656c41448`）｜仓根 `/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`）｜读时 `2026-09-29T01:0x–01:1x+0800`
**一切读数现取自算**（`t98` 的复核只当线索）。本件**不构建、不跑腿、不占显示位、不跑整趟门禁**；**只动文档**，未碰任何产品件/工具/判据件/哨兵/证据。
**写域** ＝ `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（**唯一例外**：派单明许的"恢复一处历史数字"）＋ `build/MilBridge/P1-w8-step2-criteria.md`（dated 追加）＋ 本载体（新建）。`build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行**本件未写**（理由见 §2：本件三件**都不在覆盖面内**）。

## §0 一句话

两处文档面问题都按「**更正只许 dated 追加，不许就地改历史**」修掉：`F-3` 把 `t97` **就地改写**的那条历史行**整行恢复**为 `b7e38ab^` 原文（逐字节 `cmp` 通过），并在**同处**追加三行 dated 说明（现值另立出处）；`F-4` 给判据件 `C2` 的前提**追加** dated 更正（**0 删行**、任何 `acceptance` 实质未动），指向 `P1-ptsname-result.md` §8 **裁定八**。⚠️ **与派单描述不符处（如实记）**：`t97` 改的**不是一处**，而是**同一行三处**（`97→96`／`85→84`／`91→90`）——本席按同一例外条款**一并恢复**并给了字节级前后对照。

## §1 `F-3`（修毕）—— 历史数字恢复 ＋ dated 追加

**目标行（内容锚）** ＝ 本件里那行以 `- **🆕 在册数更正（2026-09-24 车道 W154A-PTS 只读盘点，主控落册）**` 起头的行（锚现取**唯一**：`grep -c` ＝ 1；读时落点 `:2257`，**仅本次有效**）。

**① 前像/后像逐件读数**

| 项 | 写前 | 写后 |
|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `0e9a090a791564e0`／**3878** 行 | **`7503253a3f46c509`／3881 行** |
| `git diff --numstat -- <该件>` | —— | **`4 1`**（4 加 ＝ 恢复后那一行 ＋ 3 行 dated 说明；**1 删 ＝ 被 `t97` 改写的那一行**） |
| 与写前备份整件 `diff` | —— | **共 5 行变化（`<` 1 ＋ `>` 4）** ⇒ 除目标行与其后 3 行说明外**一行未动** |
| 恢复行 vs `git show b7e38ab^:<该件>` 的同一行 | —— | **`cmp` 逐字节相同**（两串各 `1500` 字符） |

**② `t97` 到底改了什么（本席字节级对拍，`difflib` 逐段）**：`b7e38ab^` 的那一行与现文件同一行**长度同为 `1500`**，差异**恰三处、每处各 −1**：

```
OLD[92]  = "…工具口径 **97**（`python3 …"      → NEW[92]  = "…工具口径 **96**（…"
OLD[447] = "…误报）⇒ **可操作缺口 85**（55 `Fs*`…" → NEW[447] = "…**可操作缺口 84**（…"
OLD[518] = "…零引用**）；**实现口径 91**（88 ＋ …" → NEW[518] = "…**实现口径 90**（…"
```
`git show --stat b7e38ab -- samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现取 **`1 1`** ⇒ 该提交在此件只动了**这一行**（三处数字皆在行内）⇒ 本席的恢复**不越出这一行**。

**③ 为什么必须恢复（自洽性论证，全部现取）**：该历史行**自己引用**的件是 `libwpfwin32.so fc60c34d51fd9247`／**550 导出**（逐字在行内）；该世代在册声明件现取 ＝ `git show 9cea5cc:src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` ⇒ **`PTSGAP-DECL: tool=100 dead=11 artifact=1 ops=88 impl=97 so16=fc60c34d51fd9247 exports=550`**（`so16`／`exports` 与该行引用**逐位相符**）⇒ 行内 `97/85/91` 属**那一代**；而 `96/84/90` 是 `t97` 那代（`so16=461e5557bd7dd571`／`565 导出`）的数 ⇒ **就地改写让历史行与它引用的件不自洽**。

**④ dated 说明（同处追加，三行；落点＝该行**之后**）** 内容要点（逐字见件）：
- 恢复的事实与三处前后对照；`--stat` `1 1` 证明只此一行；
- 恢复原因（引用件世代 vs 现值世代）；
- **现值另立出处**：`bash build/MilBridge/tools/pts-gap-count-check.sh` 现取 **`PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=90 so16=461e5557bd7dd571 exports=565`**（＝ 在册 `pts-gap-decl.txt` 的 `PTSGAP-DECL:` 行**逐字段相等**）＋ `python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier mapped|all` 现取**都是 `[PresentationNative_cor3.dll] 96 条`**；**变更理由**＝`t97` 同趟补的 `LoDisposePenaltyModule` 由"未导出"变"已导出" ⇒ 三个计数**同幅各 −1**（`dead`／`artifact` 未动）；并写死「此后取现值看 `PTSGAP-DECL:`／`PTSGAP=`，**不要**回到本历史行取现值」。

## §2 `F-4`（修毕）—— 判据件 `C2` 前提 dated 更正（**只加行**，`acceptance` 实质未动）

| 项 | 写前 | 写后 |
|---|---|---|
| `build/MilBridge/P1-w8-step2-criteria.md` | `a6d514a6bb39a5e9`／**304** 行 | **`12795d5aefba55c1`／317 行** |
| `git diff --numstat` | —— | **`13 0`** ⇒ **零删行**；与写前备份 `diff` 的 `^<` 计数 ＝ **0** |
| 末行自报口径 | `427cc82e166f1a48`（**原样保留**） | 新末行 **`aec339dc96cbc148`**（`head -n -1 \| sha256sum \| cut -c1-16` **重算同值**） |

**更正内容（追加段，逐字见件）**：① **点名**那五处失准读数所在（`§0` 覆盖自检器行、`§0` 缺口三格行、`C2` acceptance、`C2` 期望形状、`R2`／`R3`、§6 那句「缺口面（本条判"不变"，`97 → 97`）」）—— **原文一字未删**；② **实测**：覆盖自检器现取 **96 条**（两档同值）、三格现取 `tool=96 ops=84 impl=90`（**同幅 −1**），`dead`/`artifact` 未动；③ **机理**：`C2` 的"不变"隐含"本增量只碰实现、不碰导出面"，而 `t97` **同趟必须补同伴入口**（不补 ⇒ `Finalize()` 抛在 `GC.RunFinalizers()` ⇒ `rc=134`）⇒ 该名**离开缺口面** ⇒ **`96 = 97 − 1`** 必然；④ **前进证据压在行为面**（台账行消失／前沿位移／`entry=` 换代 ⇒ 与"缺口面不变"无因果）⇒ 该格**由"必不变"降级为"允许 −1 且须逐条点名归因"**；⑤ **指向** `build/MilBridge/P1-ptsname-result.md` **§8 裁定八**（内容锚：`裁定八（承 t97 回执）—— 判据 §0「缺口面 97→97」被实测推翻，按「不硬凑」处置。`）⇒ 本件当契约用时 `C2` 按裁定八读；⑥ 声明本段**只作更正**：不追加、不撤销任何 acceptance（`C1`–`C8` 其余格与两极化要求一律不动）。

## §3 顺带两条：**只给索引**（本件不改 `src/**`／`tools/**`）

- **`F-5`（`t98` 点）**：`P1`／`P3`／`P4`／`P7` 写的 `reason` token 在工具面**无载体** —— 本席现算（`grep -rl <token> build/MilBridge/tools/`）四个 token **各 `0` 个文件**：`decl-vs-live-mismatch`／`entry-name-not-backtraceable`／`cross-run-pairing`／`symptom-column-not-derived` ⇒ **属实**。
- **`F-6`（`t98` 点）**：`WpfLinuxWin32_PtsPenaltyModuleHandleAt(idx)` 是**位置读** —— 本席现读原文（`src/WpfGfx.Linux.Native/src/win32_pts.c`，行号仅本次有效 `:608`）：`if (idx < 0 || idx >= g_pts_loc_live_n) return NULL; return g_pts_loc_live[idx]->penalty_module_handle;` ⇒ 它读的是**紧凑的** `g_pts_loc_live[]` ⇒ 销毁后**登记表换位** ⇒ **不得跨销毁缓存 `idx`** ⇒ **属实**。
- ⇒ 这两条的**口径句落笔已派 `t102`（runner，`src/**` 侧）**；本件**只在此给索引**（同趟也在 `P1-w8-step2-criteria.md` 的追加段末尾留了一条同向索引），**不重复落笔、不越域改件**。

## §4 不变量 / 指纹 / 已接线牙（现取）

```
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ｜ `VERIFYALL-STEPS-DECL: 62 gen=#81` ＝ 1 ｜ `--expect 234` ＝ 1 ⇒ 四条未变
覆盖面成员（本席现算）：`KNOWN-DEFECTS`／`P1-w8-step2-criteria`／`P1-docface-fix-report`／`HANDOFF-NEXT` **各 `0`**
   ⇒ **本件改动面不在覆盖面内** ⇒ 依派单纪律**不追写 `cell=#1`**（本件未写该行，`HANDOFF-NEXT.md` 现取 `sha16` ＝ `b9fca067a2daa898`（647 行，**非本席所改**））
指纹：`bash ~/w153a/bin/infp.sh fp` 三次现取 —— `797f97138675df1305bd06c1e0c5340367ece878a8956086e97f93ce395bf452`（`ts=01:09:36.842344087+0800`，**与当时末条 `cell=#1` 同值**）
      → `c62441ca6c5486366a8c2f0bfc06ee88dd4833ca4d0290cbd72be4302cf4d8d2`（`ts=01:10:01.589108369+0800`）
      → `c62441ca6c5486366a8c2f0bfc06ee88dd4833ca4d0290cbd72be4302cf4d8d2`（`ts=01:11:13.938653493+0800`，**又与新末条 `cell=#1` 同值**）。
      **位移归因（本席现算）**：覆盖面内自 `01:05` 起被改的件是 `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（mtime `01:07:00.111202839`）＋ `build/MilBridge/tests/PtsPagesProbe/evidence/**`
      （`device/xvfb.log 01:07:16`…`app_g1.log 01:07:43.593887487`、`five_post_g1.txt 01:07:43.919847571`、`shots/g1/*.png`）—— 都是**他者**在做 native 侧改动 ＋ **跑腿重产在册证据**（本件**不构建/不跑腿**，这三类件**零碰**）。
牙：REPORTID=PASS files=243 ids=2201 declared=224（本载体落盘前）｜DEFREG=PASS declared=224 route_ids=224
    **DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD** ⇒ 本件改了 `KNOWN-DEFECTS.md`（KD 的声明锚随之变）＋ route 面另有他者位移 ⇒ 该格要闭须由持有 `--emit`／`defect-registry-declared.tsv` 的写者同趟刷新（**本件写域不含它**）
    SENTINEL-SPEC 现取 **12 项 `SSC_VALUE=PASS`**（含 `PF=6893d1d3fb1ee110`／`WIN32SHIM=461e5557bd7dd571`）｜SHELL_QUOTE_TRAP=PASS traps=0 ｜ PIPEFAIL_SIGPIPE=PASS undeclared_hit=0
    STATIC-JAWS 现取 **`STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62`（0 HIT）**
```
§4.1 **`HANDOFF_MV` 的成对状态（如实记，不追写）**：`01:09:36` 那次现取 fp **恰等于**当时末条 `cell=#1` 的值（⇒ 那一刻 `PASS`）；`01:10:01` 再取已变（`c62441ca…`）⇒ `handoff-machine-values-check.sh` 现取 **`HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=7 manual=1 mismatch=1 reasons=,#1:covered-file-changed-since-ts`**；`01:11:13` 第三次现取 `c62441ca…` 时又与**新**末条 `cell=#1` 同值 ⇒ `HANDOFF_MV=PASS cells=9 equal=8 mismatch=0`；而紧接的 `static-jaws-check.sh` 那一趟也是 **`PASS`**（他者在两次读数之间追加了新的 `cell=#1` 登记）⇒ **这是"他者在动的靶"**：本席**只报取值时刻、不追写、不代登**（本件改动面亦不在覆盖面内 ⇒ 无登记义务）。

## §5 未做项 / `NOINFO` ＋ 边界自证

- **未做①（`--emit` 刷新 `declared.tsv`）**：`build/MilBridge/tools/**` 与 `defect-registry-declared.tsv` 均**不在本件写域** ⇒ 只点名 `DEFREG_DECLDRIFT=1 keys=KD`（`DEFREG` 本体仍 `PASS`）。
- **未做②（`F-5`/`F-6` 的口径句本体）**：已派 `t102`（`src/**` 侧）⇒ 本件**只给索引**（§3）。
- **未做③（"现值"的历史面完整回填）**：本席**不**把 `t97` 那代的三格数写回历史行（那会再次就地改历史）—— 历史行只描述 `fc60c34d51fd9247` 那一代，现值出处是 `pts-gap-decl.txt`／`PTSGAP=`（§1④）。
- **`NOINFO`（`t97` 的 `rc=134` 因果链）**：本件**未独立复跑**（禁构建/禁跑腿 ⇒ 只引 `t97` 载体 `build/MilBridge/P1-w8-step2-report.md` 与 native 现读注释）。
- **边界自证**：`git status --porcelain` 里属于**本席**的改动只有 ` M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、` M build/MilBridge/P1-w8-step2-criteria.md`、`?? build/MilBridge/P1-docface-fix-report.md`；`src/**`、`build/PresentationFramework.Linux/**`、`build/MilBridge/tools/**`、`verify-all.sh`／`close-wave.sh`／哨兵／`docs/ROUTES.md`／`tests/PtsPagesProbe/evidence/**`、任何判据件**零碰**；未构建／未跑腿／未占显示位／未跑整趟门禁／未 `git add|commit|push`。
- **备份面 ≡ 改动面（第 `29` 条）**：改动面 2 件（+1 新建无前像），备份面 `~/w281-scribe/bak/{KNOWN-DEFECTS.md,P1-w8-step2-criteria.md}.pre-t104`（写前逐件 `stat -c %h` ＝ **1** ＋ `cp -p`；`cmp` 与写前件逐件相同：`0e9a090a791564e0`／`a6d514a6bb39a5e9`）。
- **第 `30` 条**：本件**不引用任何进程内状态读数**（无自检／无探针／无 `live` 计数）⇒ 该条不产生引用义务；所引皆是**批式件读数**（判据件、`git`、覆盖自检器、`infp.sh`）。
- **只增不改自证（机器可算）**：`diff <写前备份> <现值> | grep -c '^<'` ⇒ `KNOWN-DEFECTS.md` 的 `1` 行**就是派单明许的那一处恢复**（且该行恢复后与 `b7e38ab^` **逐字节相同**，`cmp` 通过）；`P1-w8-step2-criteria.md` ＝ **0**。


---

## ⏪ `t104` 落盘后补记（同趟；只增不改）—— 并发碰撞的完整成对记录 ＋ 最终读数

- **`F-3` 的目标行被"两写者碰撞"覆盖过一次（如实记，全部现取）**：
  - 本席**第一次恢复**后写后像 ＝ `7503253a3f46c509`（该历史行**逐字节等于** `b7e38ab^`，`cmp` 通过）；
  - 随后本件 mtime 被推到 **`2026-09-29 01:10:42.036784786`**，本席复取发现该行**又**回到 `工具口径 **96**`／`可操作缺口 84`／`实现口径 90`（`git diff HEAD` 当时 `+3 -0` ⇒ 只有本席那三条说明、**零删行** ⇒ 该行被改回 `t97` 那代数字）＝ **本席的恢复被覆盖**；**归属**＝同批他者（其载体 `build/MilBridge/P1-selfcheck-hygiene-report.md` 现取自称做了「`KNOWN-DEFECTS.md` 的 `97/85/91 → 96/84/90`」）；
  - 本席**在同趟内做了第二次恢复**（仍以 `b7e38ab^` **逐字节**为恢复目标）⇒ 现取该行**再次**通过 `cmp`；该件现取 **`4f53a0c8add3e5a6`／3884 行／mode 644**（mtime `2026-09-29 01:12:16.072108528`），`git diff --numstat` ＝ **`7 1`**（1 删 ＝ 派单明许的那一处恢复；7 加 ＝ 恢复行 ＋ 两条 dated 说明共 6 行），相对写前备份的 `^<` 计数 ＝ **1**（**只有**那一处）。
  - **口径分歧已入册并请队长裁定**（写在件内第二条说明里）：历史行**只描述它引用的那一代**（`fc60c34d51fd9247`／550 导出）∴ 保持 `97/85/91` 才自洽；"改成现值"会让历史行与自身引用件不自洽（`t98` 的 `F-3` 立案理由）。**若再被覆盖，本席不再重试**（避免活锁），改由队长裁定后一次性落笔。
- **`F-4` 未受碰撞影响**：`build/MilBridge/P1-w8-step2-criteria.md` 现取 **`12795d5aefba55c1`／317 行／mode 644**（＝ 本席写后值，未被他人改动）；末行自报口径 `aec339dc96cbc148`（重算同值），原自证行 `427cc82e166f1a48` **原样保留**。
- **落盘后牙读数（现取）**：`REPORTID=PASS files=244 ids=2201 declared=224`（本载体 ＋1：243 → **244**）；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（`ts=01:11:29` 那次读数：fp ＝ `c62441ca…` ＝ 当时末条 `cell=#1` 值）；`DEFREG=PASS declared=224 route_ids=224` ＋ **`DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD`**（本件改了 KD 的声明锚 ⇒ 需持 `--emit` 权限者同趟刷新；`DEFREG` 本体仍绿）；`SSC_VALUE` 12 项全 PASS；`SHELL_QUOTE_TRAP=PASS`／`PIPEFAIL_SIGPIPE=PASS`；`STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62`（**0 HIT**）。
- **本席**未**写 `HANDOFF-NEXT.md` 的 `cell=#1` 行**：本件三件（KD／criteria／本载体）在覆盖面内**各 `0`** ⇒ 无"改覆盖面内件必须同趟登记"的义务；该件现取 **`b9fca067a2daa898`／647 行**（**非本席所改**：`cell=#1` 行由他者在其自己的位移后追加）。

**本件自证（末行 · `t104` 落盘后）**：`head -n -1 build/MilBridge/P1-docface-fix-report.md | sha256sum | cut -c1-16` ＝ d2479f8238dde99c（口径＝末行不计入自身取值；上一行 `610861e57d8e017e` 系**补记前**全文值，原样保留）
