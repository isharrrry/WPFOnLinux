# P1-FS-QUERY-VERIFY（`t126` 独立复核 · W48「`FsQueryPageDetails` ＋ `FsDestroyPage`」· `t123` in-flight 补充的件）

> **本席只读仓树、只写本件。** 复核对象（队长已更正，**不等 `t125`**）＝ **`build/MilBridge/P1-fs-destroy-report.md`**（**`d736949f3f9a3cd3`**／198 行，本席现取）＋ 其产品改动。**审查面 ＝ 提交 `38541c1`**（`fix(#81): t123 补充落地 …`，`2026-09-29T13:11:56+08:00`）：`git show 38541c1:src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`15223e6919af0422`**｜`.so` **`e08167eef3c4a14e`**｜`exports.txt` **584** 行｜声明件 `# PTSGAP-DECL: … so16=e08167eef3c4a14e exports=584`。`t123` 原载体 `P1-fs-page-report.md`（`f497fc1f0a62dce5`）本席现取**未动** ✓。
> ⚠️ **在飞漂移（本席窗口内现取，必须写清取数代际）**：本席开工时工作树的 `win32_pts.c` 已非审查面 —— 现取 **`f72fcf94d1ad245e`**（`M`，mtime `13:14:17`）、`.so` 已重建为 **`bbd249a656725b51`**、`exports.txt` **591** 行；`~/t123-runner/bak/win32_pts.c.pre-t127` 现取在位 ⇒ **另一写者（`t127`）在飞**。⇒ 本件**凡"审查面"读数均按 `git show 38541c1:` 复算**；凡"现盘"读数**逐处标注取自哪一代**。另：`rc = 89` 只出现在**漂移后**的工作树（见 ④）。
> **仪器**：`git show/diff/status`（只读）＋ `nm`／`sha256sum`／`grep`／一次性 `python3`（SRCS 差集）＋ 判据端**纯读** `pts-pages-guard.sh --legs`／`pts-gap-count-check.sh`。**零构建、零跑腿、零显示位、零整趟门禁、零 git 写**；夹具全在 `~/wv88y/`（仅一份 guard 输出），收尾删净。

---

## §A 正面结论：**回归真解决 ＝ 成立**

| 面 | 本席现取读数 | 判 |
|---|---|---|
| 两条入口真导出 | `nm -D --defined-only … \| grep -cx`：`FsQueryPageDetails` ＝ **1**、`FsDestroyPage` ＝ **1**（`exports.txt` 同名命中各 **1**）；`nm` 行数 ＝ `exports.txt` 行数 ＝ **584**（审查面） | ✓ |
| 该两名的 **ENFE** | 审查面 `app_g1.log`（`2e564c4ce28a46a9`）里 `FsQueryPageDetails`／`FsDestroyPage`／`FsCreatePageBottomless` **各 0 次**；`entry point named '…'` 全量 ＝ **1102**（`FsQueryTrackDetails` 1101 ＋ `FsCreatePageFinite` 1）；判据端现取 `PTS_ENFE=INFO total=1102 by_name=FsQueryTrackDetails:1101,FsCreatePageFinite:1, allow=none`（与本席自算**逐位相符**） | ✓ 三名归零 |
| 两腿存活 | **审查代**（`38541c1` 版 evidence）：`k=23 alive=yes app_rc=143 magenta=0 colors=383 ae=0 ink=480000 ns=…RichTextBoxDemo`／`k=24 alive=yes app_rc=143 magenta=0 colors=383 ae=15386 ink=480000 ns=…FlowDocumentDemo`，两腿 `DEV shim=a131ea4e6f5cc4f5`（＝当时现盘 `.so`）；**现盘**（漂移后）两腿同值但 `shim` 已换 | ✓ `yes/143` |
| `failfast`／`unrec` 回落 | **审查代**两腿 `leg_*.env` 与 `session.txt` 现取 **`failfast=0`／`unrec=0`**（各 2 处）；**崩溃代**日志 `~/t123-runner/bak/run-app_g1.log` 本席自算 **`FailFast` 出现 4 次／`Unrecoverable` 2 次**（同件另有 `Page does not exist.` ×2）⇒ **4/2 → 0/0** ✓（口径 ＝ 该两串在 `app_g1.log` 的出现次数，与车道 `FAILLINE … src=app_g1.log:FailFast\|Unrecoverable` 同源） | ✓ |
| 死亡→存活的**保留**对照 | ⚠️ **仓库历史里 `alive=no app_rc=134` 那一行属于 `710ba37`（＝`t110` 的字体栈崩），不是本次回归**；本次回归的「账面无红而真腿 abort」**只**在车道日志里（崩溃栈 `Environment.FailFast ← Invariant.FailFast ← PtsContext.OnDestroyPage ← PtsPage.DestroyPage`）。⇒ 「`alive` 字段对」我**取不到**（记 `NOINFO`），但「进程真死过」由崩溃栈与 `Unrecoverable system error.` 现取**成立** | ✓（一半字段 `NOINFO`） |

## §B 红面结论：**红面成立，且被复核件没有松口**

- **判据端仍红（本席自跑）**：`pts-pages-guard.sh --legs <在册证据>` ⇒ **`rc=1`**，`PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0 direction=in-file phase=degraded`；`PTS_ENFE=INFO … phase=degraded（止损期不据此判红；相位翻转后本条生效）`。⇒ 红面**来自相位位与形态不匹配**，不是本步实现缺陷。
- **`N3`（两页帧逐字节相同 ⇒ 红）本席独立复算**：`sha256sum evidence/shots/g1/k23.png` ＝ `sha256sum …/k24.png` ＝ **`ef3fd6765f18f51b`**（`boot.png` ＝ `b21eb530afd3c66c`）⇒ 帧**逐字节相同**、去重计数 ＝ 1 ⇒ 按 `N3` **红** ✓（被复核件 §3.3 明记 ❌、**未**因任何"去重=2"发绿 —— 本席现取：件内 `:111` 逐字写"按 `N3` 判红、明记 ❌"）。
- **`C6`／`C8`／`ENFE` 三条未折绿**：件内 `:112` 写「帧身份满足、对'两页之别'**零区分力** ⇒ **不给 C6 绿**」；`:113` 写「`C8` 正身份**无载体 ⇒ `NOINFO`**，**不折绿**」；`:157` 写「『两页真排版』**不成立**（帧去重＝1、`ENFE_TOTAL=1102`）⇒ 本步的绿**只准**读成『这两条入口不再缺且行为可读 ＋ 回归已解』」⇒ **四条上零松口** ✓（本席按其文字与自取读数逐条对拍：均与读数一致）。

## ① 回归是否真解决（逐条，读数见 §A）

**成立**（两条入口真导出且 `nm=exports=584`；两名 `ENFE=0`；两腿 `alive=yes app_rc=143`；`failfast/unrec` `4/2→0/0`）。**唯一保留**：「`alive=no/app_rc=134` 字段对」无保留载体（仓库历史那行属 `t110` 代）⇒ 该一半 `NOINFO`，但"真腿死过"由崩溃栈现取成立。

## ② 因果链纠正 ＝ **成立**（⇒ **队长先前的推断被推翻**）

**本席自取的源码逐环**（`upstream/.../PtsHost/PtsPage.cs`／`PtsContext.cs`，只读）：`CreateBottomlessPage()` 第一句 `OnBeforeFormatPage(false, false);` → `OnBeforeFormatPage(…)` 内 `if (!incremental && !IsEmpty) { DestroyPage(); }` → `PtsContext.OnDestroyPage` 内**两道断言** `Invariant.Assert(_pages != null, …)` ∧ **`Invariant.Assert(_pages.Contains(ptsPage), "Page does not exist.")`**，其后才是 `PTS.Validate(PTS.FsDestroyPage(_ptsHost.Context, ptsPage))` → 注册点 `if (!incremental) { PtsContext.OnPageCreated(_ptsPage); }` → `FsQueryPageDetails` 在 `PtsPage.cs` 的调用点 **6 处**（`:503`／`:553`／`:826`／`:870`／`:996`／`:1195`，其中 `GetRect()`／`GetBoundingBox()` 各一处）。

**两条佐证本席独立复核，均成立**：
1. 崩溃日志 `~/t123-runner/bak/run-app_g1.log` 里 **`FsCreatePageBottomless` 命中 0**（⇒ 那条 create 已不报缺符号；同件 `entry point named '…'` 全量＝**1**，正是 **`FsQueryPageDetails`**）；
2. 崩溃栈现取 `:575-584` ⇒ `Unrecoverable system error.: Page does not exist.` ×2 ＋ `Environment.FailFast ← Invariant.FailFast ← **PtsContext.OnDestroyPage(IntPtr, Boolean)** ← **PtsPage.DestroyPage()**`；**该日志里 `FsDestroyPage` 命中 0** ⇒ **这次 abort 根本没走到 `FsDestroyPage`**。

⇒ ⇒ ⇒ **链条成立：`OnAfterFormatPage → FsQueryPageDetails` 缺符号使 `OnPageCreated` 永不执行 ⇒ `_ptsPage` 非零却不在 `_pages` ⇒ 下一趟撞 `OnDestroyPage` 的 `_pages.Contains` 断言 ⇒ `Environment.FailFast`**。**明写：队长先前「只补 `FsQueryPageDetails` ⇒ 仍会撞 `FsDestroyPage` 缺符号」的推断，被本趟现取推翻**（该 abort 里 `FsDestroyPage` 零命中；两条仍**必须**同趟补，但**理由**应改写为"`FsQueryPageDetails` 是解开注册的钥匙、`FsDestroyPage` 是紧接其后要撞的一条"）。**本席未给出第三条链**——上述链与现取不矛盾，且证据足以定名。

## ③ 它报的两条诚实红是否该保持 ＝ **该保持，且未松口**

两页帧**逐字节相同**（本席自算双侧 `ef3fd6765f18f51b`）⇒ `N3` **红**；`C6` 帧身份**零区分力** ⇒ **不给绿**；`C8` 正身份 **`NOINFO`** ⇒ **不折绿**；`ENFE_TOTAL` 现取 **1102**（另有 `FsQueryTrackDetails` 1101）⇒ **绿只准读成"这些入口不再缺且行为可读 ＋ 回归已解"**。四条**均按上表逐字在位** ✓。

## ④ 铁律与不变量（本席自算）

| 项 | 现取 | 判 |
|---|---|---|
| `SRCS` 完整性 | `build-shim.sh:34` 的 `SRCS=(…)` 解析出 **10** 条；`src/*.c` 实际 **10** 个；**漏登记 0、列了但不存在 0**（差集双向为空） | ✓ `10=10` 差集 0 |
| 格号（铁律：只增不改） | **审查面**：`git show 38541c1:…win32_pts.c` vs `38541c1^` ⇒ `rc = <数>` **集合**：被删 **0**、新增 **仅 `88`**；**序列**去掉 `88` 后与旧版**逐项相同**（92 项，`SEQUENCE_IDENTICAL`） | ✓（⚠️ **漂移后**的工作树又出现 `rc = 89`，属 `t127` 在飞，不计入本件） |
| 导出逐名 | 声明的 6 名**逐名在册**且 `nm=1`／`exports=1`：`FsQueryPageDetails`／`FsDestroyPage`／`WpfLinuxWin32_PtsFsQueryPageOk`／`…PtsFsQueryPageGap`／`…PtsFsDestroyPageOk`／`…PtsFsDestroyPageGap`；**无消失**（`comm -23` 空）；**git 级增量**：`38541c1^` 的 `PTSGAP-DECL exports=578` → `38541c1` 的 `exports=584` ⇒ **+6** ✓ | ✓ |
| `nm` 与 `exports.txt` 行数相等 | 审查面 **584 = 584** | ✓ |
| 四不变量 | 覆盖面 `infp.sh list` ＝ **234** ✓；`inputs_fp` 现取（`ts=13:14:22.168379476`）＝ `2ff5cab8c52f4932b94bfef369f6613b56b6e5d169ba60744b67201f48f20ea0`，而 `HANDOFF-NEXT.md` 末条 `cell=#1` 登记值（`ts=13:10:50.323666648`）＝ `54aebf1d…` ⇒ **不一致**；`handoff-machine-values-check.sh` 现取 **`HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=7 manual=1 mismatch=1 reasons=,#1:covered-file-changed-since-ts`**（`in-repo=54aebf1d…`／`live=5626cac1…`） | ⚠️ **不一致（DIVERGED）**，成因＝**在飞写者**在 `13:14:17` 改了覆盖面内的 `win32_pts.c`（本席零写） |
| 两哨兵 | `cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；字段 `WIN32SHIM=e08167eef3c4a14e`（**＝审查面 `.so`** ✓）、`PF=2988f5154ecac5dd`、`SHA=941e69902d82ef02`、`PC=02f158868aa99df4`、`WB=9e860cbeecb352e1`、`WAVE=w80-freeze`、`BASELINE=#80`（`BASELINE_SHA16=b27ff6332f263495`） | ✓（针对**审查面**；漂移后现盘 `.so bbd249a6…` 与之不同——队长所述"哨兵已重写"我按本件实际键位核对，**未见 `WPW=`／`so=` 两键**，见 `F-3`） |

## Findings（不改被复核件；要改的以「夹具＋读数」给出）

- **`F-1`（low）被复核载体的末行自证仍是字面 `PLACEHOLDER`**：`build/MilBridge/P1-fs-destroy-report.md:198` 现取 ＝ `` `P1-FS-DESTROY-REPORT 自证（…）＝ PLACEHOLDER（口径＝末行之前的全文；末行＝本行）` `` —— **未替换成现算值**。本席按同一口径自算 ＝ **`cf6f381b985b0d33`**（与队长引用的"末行自报口径"一致）。**修法**：把该行填成现算值（一字不改其余）。
- **`F-2`（low）件内指针落空 ＋ HMVC 今天不是 PASS**：件内 `§7` 写「`handoff-machine-values-check.sh` 读数**见 §8 末**」，而 **§8 里没有该读数**（本席现取 `grep HANDOFF_MV|HMVC` 在件内 **0 命中**）；且该牙**今天现取 `DIVERGED`（`mismatch=1`, `cell=#1`）** ⇒ 该格的"四不变量全绿"读法**不成立**（成因＝在飞漂移，见 ④）。
- **`F-3`（low，取数代际）现盘已漂到另一代，凡"现盘"字样必须标代**：本席窗口内 `.so` 由 `e08167eef3c4a14e`／584 变为 **`bbd249a656725b51`／591**（`win32_pts.c f72fcf94d1ad245e`，且新增 `rc = 89`；`win32_pts.c.pre-t127` 备份在位）；队长消息里的 `WPW=PASS sha16=f71df705d868d80a` 与 `so=e08167eef3c4a14e` 两个 token **在 `~/wfp-runs/bridge-frozen.flag` 里不存在**（本席 `grep -rl f71df705d868d80a` 在 `~/wfp-runs/`／`build/`／`docs/` **0 命中**）⇒ 若指另一件请点名（该 token `NOINFO`）。
- **`F-4`（low，moving target）被复核件引用的两个"前置值"本席取不到**：① `ENFE_TOTAL before＝1152`（本席现取：`38541c1^` 版证据日志 ＝ **1081**（`FsCreatePageBottomless` 1080 ＋ `FsCreatePageFinite` 1）；崩溃日志 ＝ **1**）⇒ 1152 应属更早代；② `PTSGAP` 的「**唯一**残留 `SITE-DRIFT docs/ROUTES.md impl`」：本席**当时**（漂移前审查面）未能复现该唯一性，**今天**跑 `pts-gap-count-check.sh` 得 **4 条 DRIFT**（`tool decl=93 live=91`／`ops 81→79`／`impl 84→82`／`so16 e08167ee…→bbd249a6…`）＋ `PTSGAP=FAIL`，成因＝在飞换代 ⇒ 该"唯一性"**今天不可复算**（`NOINFO`，非判红）。
- **`O-1`（观察）`t123` 的"账面绿而真腿死"本席独立复现其**形态**：`710ba37`（`t110` 代）的在册 `leg_24` 是 `alive=no app_rc=134`，而**同一代的 `38541c1^` 版**在册 `leg_24` 已是 `alive=yes app_rc=143` —— 本次回归的死亡那一趟**从未进过在册证据**（只在车道日志里）⇒ 判读时**必须**同时读车道日志/崩溃栈，别只看 `leg_*.env`。

## `NOINFO`（不折绿、不折红）

1. **`alive=no`／`app_rc=134` 的字段对**（本次回归）：无保留载体（仓库历史那行属 `t110` 代）⇒ 本席只以崩溃栈证明"真死过"。
2. **`ENFE_TOTAL before＝1152`**（`F-4①`）与 **`PTSGAP` 唯一残留的可复现性**（`F-4②`）：均为 moving target。
3. **`WPW=PASS`／`so=` 两 token**（`F-3`）：不在哨兵件内，车队消息所指载体未定位。
4. **它的反腿 `P2`／`P4`／`P4b`／`P9`**（`FAIL=3`／`3`／`27` 与自检幂等）：需其**副本＋构建** ⇒ 本件禁构建，未跑；本席只给"真实现的拒绝面/留痕面在位"这一侧（崩溃日志 `FS_PAGE_GAP` 计数属其载体，**未引**）。
5. **「两页真排版」**：帧去重＝1、`ENFE_TOTAL=1102` ⇒ **不成立**（与被复核件同结论）。
6. **整趟门禁／显示位／跑腿面**：本任务禁 ⇒ 未跑。

---

SELF-SHA16 （口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 94c82753a18cbcaa
