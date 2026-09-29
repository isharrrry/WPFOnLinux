# P1-W45 · `N2` 守卫接线（收紧）＋ `N4` 正身份三选一（取（甲））＋ 空态参照集重登记与归属建议（`t122`／`scribe`）

写者 `scribe`（`t122` attempt 1／`b3460882-3da5-42b7-86c5-ac730cbc3bb6`）｜仓根 `/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`）｜读时 `2026-09-29T04:1x–04:3x+0800`
**一切读数现取自算**（`t119` 的复核只当材料）。本件**判据/守卫/文档面**：**未**跑整趟门禁、**未**构建、**未**跑腿、**未**占显示位、**未** `git add/commit/push`；夹具**全部仓外**、**用完删**。
**写域** ＝ `build/MilBridge/tools/pts-pages-guard.sh`（**覆盖面内** ⇒ 同趟 `cell=#1`）＋ `build/MilBridge/P1-realized-criteria-report.md`（dated 追加）＋ `docs/ROUTES.md §15af`（一行）＋ `build/MilBridge/HANDOFF-NEXT.md`（`cell=#1` 一行）＋ 本载体（新建）。**未**动 `src/**`／生成件／`build/MilBridge/tests/PtsPagesProbe/**`（装置本体）／`verify-all.sh`／`close-wave.sh`／哨兵／`samples/**`。

## §0 一句话

`N2` 已在守卫里**接线**（**方向＝收紧**）：`realized` 期 `ENFE_TOTAL>0` 且不在 allowlist ⇒ **红并点名**（名＋计数）；`degraded` 期只印 `PTS_ENFE=INFO`（**degraded 判词与修前逐字相同**）；日志缺 ⇒ `NOINFO`（绝不当绿）。⇒ 相位翻转的硬前置**可判化**：**`ENFE_TOTAL=0`（或全在 allowlist）才许翻**；今天 `ENFE_TOTAL=1152` ∧ allowlist 空 ⇒ **翻即红**。`N4` 取**（甲）**（登记「待补」＋条件与责任人）；（乙）因"今天没有该页专属结构面读数"被列为**未来候选（乙′）**；（丙）的 `NOINFO` 纪律保留。**空态参照集已重登记**为 `{1a76488aa4a790b3}`（旧值作废）并给出**归属建议（守卫写者为唯一登记人）**。

## §1 `N2` 接线（主项；落点 `build/MilBridge/tools/pts-pages-guard.sh`）

**改动（只增不减）**：`judge_legs` 在台账要件之后新增 **ENFE 面** ——
- **口径（逐字）**：`ENFE_TOTAL` ＝ `<证据目录>/app_g1.log` 里 **`entry point named '<名>'`** 的**行数**；**来源＝应用日志**，与 `[HC-UNHANDLED]` 行**同源**（现取：二者均 **1152**，逐行一一对应）；`ENFE_BY_NAME` ＝ 按**入口名**直方图。
- **allowlist**：`PTS_ENFE_ALLOWLIST`（逗号分隔入口名；**默认空**＝一个都不许）；判词打印 `allow=` 与 `non_allow=`；红行**点名每一个** non_allow 名。
- **判据**：**`realized` 期**：`ENFE_TOTAL>0` ∧ `non_allow` 非空 ⇒ **红**（`fails+=enfe-unhandled(total=…,non_allow=…)`）＋ 行尾 `reason=enfe-present-after-phase-realized`；**`degraded` 期**：只印 `PTS_ENFE=INFO …`（**不据此判红**，止损期绿语义＝占位还在）；**日志缺** ⇒ `PTS_ENFE=NOINFO` ＋ `cannot+=`（**绝不当绿**）。
- **未改**：任何既有要件、三态语义、阈值（`MAGENTA_FLOOR`）、`colors` 带、`AE` 诊断 —— **一律不动**。

**成对读数（真证据副本，仓外夹具；`ts≈04:1x`）**

```
(degraded，同一份真证据) 修前 PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000)
                         修后 PTS_GUARD=FAIL legs=2/2 fails=（**逐字相同**） ＋ 新增 PTS_ENFE=INFO（degraded 期不据此判红）
(realized 副本) (a) 有 ENFE      ⇒ PTS_ENFE=FAIL total=1152 by_name=FsCreatePageBottomless:1151,FsCreatePageFinite:1, non_allow=FsCreatePageBottomless,FsCreatePageFinite
                                  ⇒ PTS_GUARD=FAIL fails=enfe-unhandled(total=1152,non_allow=…)  **红并点名** ✓
(realized 副本) (b) **只剥掉** log 里的 ENFE 行（其余逐字相同） ⇒ PTS_ENFE=PASS total=0 ⇒ **PTS_GUARD=PASS fails=-**
                                  ⇒ 两腿唯一差别就是那批 ENFE 行 ⇒ **该规则是 verdict 翻转的唯一原因**（既有效、又不误红）✓
(realized 副本) (c) allowlist＝这两个名 ⇒ PTS_ENFE=PASS total=1152 allow=FsCreatePageBottomless,FsCreatePageFinite non_allow=none ⇒ PTS_GUARD=PASS **逐名可核** ✓
(realized 副本) (d) 删掉 app 日志 ⇒ PTS_ENFE=NOINFO reason=enfe-log-absent(…) ⇒ PTS_GUARD=NOINFO cannot=enfe-log-absent（**绝不当绿**）✓
```
**自测（同趟）**：`--selftest` ⇒ `PASS pass=40 fail=0` ⇒ **`PASS pass=46 fail=0`**（新增 6 条断言：`c32` realized·ENFE>0 必红 ＋ 点名(名＋计数)／`c33` allowlist 全列 ⇒ 不红 ＋ 逐名可核／`c34` degraded ⇒ 只印 INFO／`c35` 日志缺 ⇒ NOINFO）。

## §2 `N4` 正身份：**取（甲）**（附两条被否项的理由）

- **现取事实**：两页帧 `sha256` **逐字节相同**（`k23`＝`k24`＝`last`＝`1a76488aa4a790b3`，各 189716 B）、`boot`＝`b21eb530afd3c66c`；日志里 `neptune` 命中 **0**；渲染循环每次布局抛 `FsCreatePageBottomless` ⇒ **今天没有任何"已知良好渲染"的样本**。
- **取（甲）登记「待补」**：**条件**＝`FsCreatePageBottomless`（及其后 `FsCreatePageFinite`）真落地、两页**首次各自绘出**（可判标志：`ENFE_TOTAL=0` **且** `k23.png` 与 `k24.png` 的 `sha256` **不相等**）；**责任人**＝**当趟实现件的写者**同趟登记该页专属期望指纹（落点＝`P1-realized-criteria-report.md` 的 dated 段），**独立复核者**在下一件复算其可复现性。**代价（如实）**：在此之前 `N4` 正身份恒 `NOINFO` ⇒ **`N4` 未闭是相位翻转的未闭项**。
- **（乙）为何不取**：要有"该页专属结构面读数"（`neptune` 命中数／tab 数／`Figure/Floater/Table` 计数）就得先有**页面内可枚举的结构量**，而那需要 **UI 侧仪器**（本仓今天没有），且**今天两页帧相同 ⇒ 连"两页有各自结构"都尚未发生** ⇒ 写成判据即"永不可能绿"（本仓禁）。⇒ 记为**未来候选（乙′）**：真绘出后**优先**用结构面做正身份（比帧指纹更稳、对像素抖动不敏感）。
- **（丙）为何不单取**：`t118` 已定该格 `NOINFO(无正身份载体)`、不许折绿 ⇒ **纪律保留**；本件不止于"留问号"，按（甲）补上**条件与责任人**。

## §3 空态参照集：**重登记**（本趟换版）＋ **归属建议**

- **重登记（逐字）**：**现行参照集 ＝ `{1a76488aa4a790b3}`** —— 来源 `build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{k23,k24,last}.png`（三帧同值，各 189716 B），取值时刻 `2026-09-29T04:1x+0800`；**`boot.png`（`b21eb530afd3c66c`）不入集**（启动帧 ≠ 回退画面）。**旧值 `{ef3fd6765f18f51b}`（`t118` 登记）作废** —— 画面已换版 ⇒ 分辨力曾一度失效（只增不改：原句保留，以本段为准）。
- **归属建议（建议＋理由）**：**守卫的写者（`build/MilBridge/tools/**` 属主）为唯一登记人**；**触发条件**＝① **相位翻转包执行时必查**；② `evidence/shots/g1/{k23,k24,last}.png` 三帧 `sha256` 与登记值**不等**时（含装置重跑换代）。
  **理由**：① 该集合的**唯一消费者是守卫**（`N1` 接线落在守卫里）⇒ 消费方持值，读到对不上即可当场红/请求重登记，不必跨件追；② 相位翻转包本身也由守卫写者执行 ⇒ 触发点①与执行人重合；③ 装置侧只需**把三帧 `sha256` 打出来**（**今天腿 env 没有帧 sha 格 ⇒ 装置侧缺口，另派单**），避免登记人自己去翻图。
- **可跑检测（单行，交给任何发现者）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k23.png "$D"/shots/g1/k24.png "$D"/shots/g1/last.png | awk '{print substr($1,1,16)}' | LC_ALL=C sort -u
```
⇒ 与登记值 `1a76488aa4a790b3` **不等 ⇒ 触发重登记**。

## §4 不变量 / 指纹 / 牙（现取；读数亦见 §5）

```
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ｜ `62 gen=#81` ＝ 1 ｜ `--expect 234` ＝ 1 ⇒ 四条未变
卫士回归：`--selftest` ＝ **PASS pass=46 fail=0**（改前 40/0）；`--legs <仓外真证据副本>` 的 **degraded** 判词与改前**逐字相同**（新增 INFO 行）
指纹：改覆盖面内件（守卫）⇒ 同趟现取 fp 并纯追加 `cell=#1` 一行（登记后 `HANDOFF_MV` 应回 PASS）
牙：REPORTID／DEFREG／SENTINEL-SPEC／QUOTE-TRAP／PIPEFAIL-SIGPIPE／STATIC-JAWS 读数见 §5（同趟现取）
```

## §5 落盘后读数（同趟；**读数入载体**）

```
（由本节的落盘后复算填写；见文件末段的 t122 补记格）
```

## §6 未做项 / `NOINFO` ＋ 边界自证

- **`NOINFO①`（装置侧帧 sha 格）**：腿 env 今天**没有**帧 `sha256` 格 ⇒ 参照集登记人无法从 env 直接对拍（只能翻图）⇒ **装置侧缺口**（`tests/PtsPagesProbe/**` 非本件写域）⇒ 另派单。
- **`NOINFO②`（`N1` 接线的守卫化）**：本件只把 `N2` 接进守卫；`N1`（帧身份 ∉ 参照集）**尚未接线**（需要装置先给帧 sha 格）⇒ 记为下一步。
- **`NOINFO③`（`N4` 正身份）**：见 §2（条件未满足 ⇒ `NOINFO`，是翻转未闭项）。
- **`NOINFO④`（真腿）**：本件**未跑腿**（派单禁）⇒ 上述成对读数全部来自**仓外真证据副本 ＋ 守卫副本（realized）**，**没有**一整趟新腿的端到端读数。
- **边界自证**：`git status --porcelain` 里属于**本席**的改动只有上面那 5 类件；`src/**`／生成件／`build/MilBridge/tests/PtsPagesProbe/**`（装置本体）／`verify-all.sh`／`close-wave.sh`／哨兵／`samples/**` **零碰**；未构建／未跑腿／未占显示位／未跑整趟门禁／未 `git add|commit|push`；**夹具全在仓外**（`/tmp/t122-x`），**收尾删净**。
- **第 `29` 条**：改动面 2 件（守卫 ＋ 判据件）＋ 1 新建 ＋ ROUTES 一行 ≡ 备份面（写前 `stat -c %h` ＝ 1 ＋ `cp -p`）。
- **第 `30` 条**：本件读数**全是批式件读数**（`grep -c`／`sha256sum`／守卫判词）⇒ 不含"进程内状态敏感仪器"引用。
## §7 落盘后补记（同趟；只增不改）—— 牙读数与指纹（**载体自带读数**）

```
REPORTID=PASS files=254 ids=2202 declared=224（本载体计入）
DEFREG=PASS declared=224 route_ids=224 ｜ ⚠️ DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD（**他者面**：须持 --emit 权限者同趟刷新）
SENTINEL-SPEC rc=0 ⇒ SSC=PASS（与队长记的"哨兵不缺位"一致；本件未动 .so/pf ⇒ 无换代）
SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203 ｜ PIPEFAIL_SIGPIPE=PASS undeclared_hit=0
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ⇒ 未变
卫士回归：`--selftest` ＝ PASS pass=46 fail=0（改前 40/0）；degraded 判词与改前逐字相同（新增 PTS_ENFE=INFO 行）
指纹与 cell=#1（**成对记录，不追写**）：
  本席现取 fp ＝ 52ceb60e4a3852fcd2223064f1900ebb6604cb29d7cec54f9a1d013be5e34138（ts=2026-09-29T11:32:08.512903957+0800）
  ⇒ 按纪律**纯追加** cell=#1 一行（HANDOFF-NEXT.md 655→656 行；本件改的是覆盖面内件 tools/pts-pages-guard.sh：e9688aaa11a1b9f4→7d5d659371befdac）
  ⇒ 登记后立刻复算 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（**收紧前它是 DIVERGED，符合预期**）
  ⚠️ 随后 **11:33:24** 覆盖件 `src/WpfGfx.Linux.Native/src/win32_pts.c` **被另一写者改动** ⇒ fp 移到 dd48c4b9db70174f837b779eedddde4fa632b8f541ebe5ba3b786dfa85b6d654（本席 11:33:38 现取）
     ⇒ `HANDOFF_MV=DIVERGED reason=#1:covered-file-changed-since-ts`、`STATICJAWS=FAIL fails=1`（唯一 HIT ＝ `HANDOFF-MV`）
     ⇒ **位移归该写者**（本席零碰 src/**）；按纪律**不再追写**（队长已明示本波收口统一对齐）。
```
**本件自证（落盘后）**：`head -n -1 build/MilBridge/P1-guard-enfe-n2-report.md | sha256sum | cut -c1-16` ＝ 9026f3d94919ccc4（末行不计入自身；上一行 1d1f352c564d119a 系**补记前**全文值，原样保留）
