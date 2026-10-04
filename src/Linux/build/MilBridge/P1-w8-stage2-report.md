# P1-W8-STAGE2（`t143` · W63：W8 第二阶段翻册 —— 六条 `Fs*` 真实现 ＋ `FSCBK` 偏移表双路径闭合 ＋ 快照前置 落进 `docs/ROUTES.md` `§13`／`§15af`）

> **本件是翻册件，不是实现件**：写域只有 `docs/ROUTES.md`（`§13` 的 `TASK-0302` 子树 ＋ `§15af` 尾部）＋ 本件。**未碰** `build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1`、`build/MilBridge/tools/**`、`src/**`（`runner` 的 `t141` 在飞）、任何 `.cs`、两枚哨兵；**相位位未翻**；未 `git add/commit/push`；未构建／跑腿／占显示位／跑整趟门禁。
> **口径**：**只增不改**（§13 用「内容锚定位 ＋ 其后插入」，§15af 用「文件末尾追加」）；每条新增行带**读时戳**；载体一律用**内容锚／`sha256` 前 16 位**指认；凡引行号处均注「**仅本次有效**」。

## §1 收尾必交①：`docs/ROUTES.md` 改前/改后（**删行数 ＝ 0**）

| 面 | 值 |
|---|---|
| 改前 | `sha16=d551589682fe0b42`／**945** 行（写前像 `~/w281-scribe/t143/bak/ROUTES.md.pre-t143`，sha16 逐位相同；`stat -c %h` ＝ 1） |
| 改后 | `sha16=333c5857e9cabed7`／**962** 行 |
| `git diff --numstat HEAD -- docs/ROUTES.md` | **`17 0`** ⇒ **删除行数 ＝ 0**（`git diff -U0 … \| grep -c '^-[^-]'` ＝ **0**；删除行中含 `t143` 的 ＝ **0**） |
| 逐 hunk | ① `@@ -245,0 +246,11 @@`（§13 的 `TASK-0302` 子树内**插入 11 行**，锚＝含 `TASK-0302 [MVP] 🔴 PTS / 原生 LineServices` 那一行**之后**）② `@@ -945,0 +957,6 @@`（**文件末尾追加 6 行**，落在 `§15af` 尾部）⇒ 两 hunk 均**纯插入** |

## §2 收尾必交②：新增 17 行逐条清单（行号 ＋ 内容锚 ＋ 引用的载体与代际）

| 新行号（**仅本次有效**） | 内容锚（该行开头的判据词） | 引用的载体／代际 |
|---|---|---|
| 246 | `⏪ **dated 翻册（t143…）—— W8 第二阶段：六条 Fs* 真实现 ＋ FSCBK 偏移表双路径闭合 ＋ 快照前置立起**` | 本件 ＋ 下列各载体 |
| 247 | `· **六条 Fs* 入口真实现（逐条：ENFE 成对 ＋ legs 成对 ＋ 导出面 ＋ 载体）**` | — |
| 248 | `① FsCreatePageBottomless —— 该名 ENFE 1151 → 0 …` | `P1-fs-page-report.md`（`5b4ad22c7167bd9a`／287 行，读时 `13:19`） |
| 249 | `② FsQueryTrackDetails ＋ ③ FsCreatePageFinite —— ENFE 1101 → 0 与 1 → 0 …` | `P1-fs-track-report.md`（`46f86450ad3f27ba`／180 行）＋ 提交 `3797ff4`（`13:19:01`） |
| 250 | `④ FsQueryPageDetails ＋ ⑤ FsDestroyPage —— 回归已解 …` | `P1-fs-destroy-report.md`（`c5ef9d8092dca770`／199 行，`13:20`）＋ 复核 `P1-fs-query-verify.md`（`d86cc32ecd6b3055`／73 行，`13:16`） |
| 251 | `⑥ FsQueryTrackParaList —— ENFE 1085 → 0，但同趟 [HC-UNHANDLED] 1123 行 …` | `P1-fs-paralist-report.md`（`2b20766a6abe38c6`／163 行，`13:23`） |
| 252 | `· **六名今日现取（本席自算，2026-09-29T14:5x+0800）**` | 真腿日志（`log_sha16=84db0eb62d15e0b2`）＋ `bin/exports.txt`（六名各 1）＋ 声明件 |
| 253 | `· **FsQueryTrackParaList 的**结构性上界**（判词）**` | 同 ⑥ 载体 |
| 254 | `· **FSCBK 偏移表**双路径交叉闭合**（裁定三十三(a)）**` | `P1-fscbk-offsets-report.md`（`94ec8e09efd75e60`／205 行）＋ `P1-fscbk-slot-recon.md`（`1d1e46bb31a97aa8`／365 行） |
| 255 | `· **下一跳形状变了（判据 t140 现取）**` | `P1-drive-probe-criteria.md`（`09a09b557fd4551f`） |
| 256 | `· **相位翻转口径（不变，重申）**` | `P1-guard-n1-n3-tighten-report.md`（`a72f2594fdf81b14`）＋ `P1-realized-criteria-report.md`（`281b40613d6f1f34`） |
| 957 | `⏪ **dated 索引（t143…）—— 纪律 31/32 实例 ＋ 裁定三十三索引 ＋ 四条 PRECOND-* ＋ 相位口径**` | — |
| 958 | `· **纪律 31／32 族 … ① t137 的 line_is_hist() 锚族收紧 ② t138 的 sha16 换代并列**` | `P1-ptsgap-site-drift-report.md`（`6fce4f24a0248b64`／88 行）＋ 提交 `208ee11`；换代并列取自 `P1-fs-page-report.md`／`P1-fs-track-report.md`／`P1-w43-verify.md`／`P1-fs-paralist-report.md` |
| 959 | `· **裁定三十三（含两次 dated 附记）** ＋ 口径写死` | `P1-ptsname-result.md`（`18f965dea39092ac`）；`t137` 现取并列读法标 **`NOINFO(待裁)`** |
| 960 | `· **四条 PRECOND-* 索引**` | `P1-drive-probe-criteria.md`（`09a09b557fd4551f`）＋ `win32_pts.c`（`ce0a759491b3b2f0`／2722 行／`mtime 14:29:42`／`M +168/−6`） |
| 961 | `· **相位翻转口径（不变，重申）**` | 同 256 的两件 |
| 962 | `· **载体**：build/MilBridge/P1-w8-stage2-report.md（本席新建）` | 本件 |

## §3 六条 `Fs*` 的读数（**逐条标注引自哪一件 ＋ 取值时刻**；本席未复算运行期者亦明写）

| 入口 | `ENFE` 成对 | legs 成对 | 导出面 | 载体（sha16／行数／读时） |
|---|---|---|---|---|
| `FsCreatePageBottomless` | 该名 `1151 → 0`；全量 `1152 → 1` | `alive=yes app_rc=143`（该趟**引入** `app_rc=134` 回归 ⇒ 平台判 `failed`） | `exports 572 → 578`（+6、`comm -23` 空、`nm=exports=578`）；`.so a131ea4e6f5cc4f5 → d0fe7f836a3ef7c1` | `P1-fs-page-report.md`（`5b4ad22c7167bd9a`／287，`13:19`） |
| `FsQueryTrackDetails` | `1101 → 0`（全量 `1102 → 1085`） | 该趟 `alive=yes app_rc=143`（引其 §6.1 逐名表） | `exports 591`／`^Fs=5`／`nm=exports=591`；`.so e9b7def842982920` | `P1-fs-track-report.md`（`46f86450ad3f27ba`／180）＋ 提交 `3797ff4` |
| `FsCreatePageFinite` | `1 → 0`（同趟全量 `1102 → 1085`） | 同上 | 同上 | 同上 |
| `FsQueryPageDetails` | 该名 `0`（全量 `1102`，before 1152） | `alive=no app_rc=134 → alive=yes app_rc=143`；`failfast 4 → 0`／`unrec 2 → 0` | `exports 578 → 584`（+6、`^Fs 1 → 3`、`nm=exports=584`） | `P1-fs-destroy-report.md`（`c5ef9d8092dca770`／199，`13:20`）＋ 复核 `P1-fs-query-verify.md`（`d86cc32ecd6b3055`／73，`13:16`） |
| `FsDestroyPage` | 同上 | 同上 | 同上 | 同上 |
| `FsQueryTrackParaList` | 该名 `1085 → 0`；**同趟 `[HC-UNHANDLED]` 1123 行**（全为 `reason=paraclient-table-not-native`） | `alive=yes app_rc=143` | `exports 594`／`^Fs=6`／`nm=594=exports`；`.so a4bf2c47f8efb521` | `P1-fs-paralist-report.md`（`2b20766a6abe38c6`／163，`13:23`） |
| **六名今日现取（本席自算，`14:5x+0800`）** | 真腿日志 `entry point named` 行数 ＝ **0**（`log_sha16=84db0eb62d15e0b2`） | 两腿 `alive=yes app_rc=143`／`failfast=0`／`unrec=0`／`magenta=0` | `bin/exports.txt` 里**六名各命中 1**；`.so=5ddc9d63b5232f96`／`exports=594`（**该两值取自本席写前时刻；收工时 `PTSGAP` 现取已见 `.so=73cd9bacd610cbe8`／`exports=600`** ⇒ 在飞换代，见 §5） | 本席现取 |

**结构性上界判词（逐字）**：`FsQueryTrackParaList` **永不假成功**（缺 `pfsparaclient` 表时以 `reason=paraclient-table-not-native` 留痕并返回失败），但**「段落列表可用」在 native 侧结构性地做不到** —— `pfsparaclient` 的唯一合法来源是**托管回调** `pfnCreateParaclient`。

## §4 `FSCBK` 双路径闭合 ＋ 下一跳（判词摘，**引自**两载体）

- **双路径（互不依赖）**：**运行期实测**（`t133`，`P1-fscbk-offsets-report.md`／`94ec8e09efd75e60`）＋ **声明序全表**（`t138`，`P1-fscbk-slot-recon.md`／`1d1e46bb31a97aa8`）⇒ **8/8 逐项 `MATCH`**；`t138` 追加回执：**28 项逐量对照全 `MATCH`、零 `MISMATCH`**。`sizeof(FSCONTEXTINFO)=872`、`sizeof(FSCBK)=824=103×8`、`pfnCreateParaclient=+176`（实测指针 `0x0000716ba50d1158`）、**操作帧 ＝ 帧 B**、组基址 `0/256/504/568/592`。
- **第三条独立一致**：整窗指纹 `nulls=32 nonnull=71 pred_nulls=32 fingerprint=PASS`（**3 个真实 doc 上下文各 1 次**）；反腿 B（空槽块整体错位 `+8`）与 C（把一个预言为空槽填非 0）均 `FAIL` 且**不崩**；编译期 **13 条 `_Static_assert`**。
- **下一跳（`t140` 现取）**：`pfnGetNextSection`（+56）**恒不产活句柄**（托管实现无条件 `fSuccess=0`／`nmsNext=0`）⇒ **只能当对照腿**；`pfnGetMainTextSegment`（+80）**唯一有信息量**（懒创建 `ContainerParagraph` 后返真句柄）；**必修前置 `PRECOND-FSCBK-SNAPSHOT-IN-DOC`**（值拷贝 103×8 B 进 native doc 对象）；**未落前置前不许拿 `0`／伪值硬试**（`FailFast` 不可捕获）。

## §5 收尾必交③：同趟牙读数（**含在飞不可比者，如实记**）

| 牙 | 读数 |
|---|---|
| `defect-registry-check.sh`（两遍） | pass1／pass2 **均 `rc=0`**：`DEFREG=PASS declared=224 route_ids=224`；**`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`**（两遍一致） |
| `report-id-domain-check.sh` | `rc=0`；**`REPORTID=PASS files=267 ids=2208 declared=224`** |
| `pts-gap-count-check.sh --check` | `rc=1`；**`SITE-DRIFT` 命中数 ＝ 0**（本件新增 17 行**未引入**任何现值位候选 ✓）；红来自**在飞换代**的 `DRIFT so16 decl=5ddc9d63b5232f96 live=73cd9bacd610cbe8` 与 `DRIFT exports decl=594 live=600`（声明件 `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` **本件一字未改**，仍 `5ddc9d63b5232f96`／`594`）⇒ **本席不"对齐"**、只如实记；`PTSGAP_CITED=PASS refs=1 strict=1` |
| 覆盖面 | `docs/ROUTES.md` **不在覆盖面**（现取 `infp.sh list \| grep -c 'docs/ROUTES.md'` ＝ **0**）⇒ 本件**无 `cell=#1` 义务**，也**未**写 `HANDOFF-NEXT.md`（现取指纹 ＝ `69132dd2d3750fed9b42768e48b2f2ed2033ffd19375bb184bcf811f30547c0a`，其位移归在飞的 `t141` 等） |

## §6 收尾必交⑤：本席主动点名的 `NOINFO`（**没跑、没核、取不到**）

1. **`PRECOND-LIVE-SECTION-HANDLE` 的载体未定位** ⇒ 派单称「载体已在 `src/WpfGfx.Linux.Native/src/win32_pts.c:181`（行号**仅本次有效**）」，**本席现取复核不到**：该件里 `PRECOND-LIVE-SECTION-HANDLE` 命中 **0**、`LIVE-SECTION` 命中 **0**；`:181` 现取为 `static int g_pts_fscbk_snap_allzero = 0;`（属 **SNAPSHOT** 前置族）。该件现取 `sha16=ce0a759491b3b2f0`／2722 行／`mtime 2026-09-29T14:29:42`／相对 `HEAD` **`+168/−6`（`M`，未提交）** ⇒ 「是否已发生」记 **`NOINFO(载体未定位 ＋ t141 在飞)`**。
2. **`PRECOND-FSCBK-SNAPSHOT-IN-DOC` 运行期是否已生效** ＝ **`NOINFO(未复核)`**：本席只现取到 native 侧**已落一部分**（该名字在该件命中 **4**，含窗口常量与「不许静默 stub／假成功」的成败面）、**未提交**；**没有**跑腿／构建去验证其运行期行为（派单禁）。
3. **`line_is_hist()` 定位口径**（`裁定三十三 dated 附记 (b)` 与 `t137` 现取）**不一致** ⇒ 记 **`NOINFO(待裁)`**：本席只**并列两读法**（`t137` 现取：改前唯一一条 `SITE-DRIFT` 出自 `docs/ROUTES.md` 那行「实现口径数（树上写的是 87）」且**带 `so16` 键锚 ＋ dated**，改后由该锚解掉；同件另一行带**裸件名锚**者其值 ＝ 现盘 **81** ⇒ 本来不红），**不单方改判**。
4. **`FSCBK` 闭合的"第三条独立一致"本席未复算**：`nulls=32 nonnull=71 pred_nulls=32 fingerprint=PASS` 与 `8/8 MATCH`／`28 项 MATCH` 均**引自** §4 两载体（读时戳见表），**本席未重跑那两趟仪器**（派单禁跑腿／构建）。
5. **未核的载体**：`build/MilBridge/P1-native-para-model-report.md`、`P1-managed-handle-report.md`／`P1-managed-handle-criteria.md`、`P1-entry-naming-fix-report.md` 等本波相关件**本席未逐件通读**（只按需抽取引用点）⇒ 若其读数与本件 §3／§4 冲突，以**其本体**为准并请裁定。
6. **未跑**：整趟门禁、构建、跑腿、显示位、`--emit`、`git add/commit/push`；两枚哨兵与 `cell=#1` 一字未动。

## §7 边界与自证

- **写域**：`docs/ROUTES.md`（§13 ＋ §15af，纯插入 17 行）＋ 本件（新建）；仓外 `~/w281-scribe/t143/**`（写前像 `bak/ROUTES.md.pre-t143`、脚本、读数日志）。
- **不变量**：`git diff --numstat HEAD -- docs/ROUTES.md` ＝ **`17 0`**（§1）；新增行**未**触碰任何既有行；`src/**`、`tools/**`、`tests/**`、哨兵、`cell=#1` 一字未改（`git status` 只列 `docs/ROUTES.md` 与本件）。

**本件自证**：`head -n -1 build/MilBridge/P1-w8-stage2-report.md | sha256sum | cut -c1-16` ＝ 869d3e05556694d4（末行不计入自身）
