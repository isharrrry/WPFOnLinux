# P1-w7-frontier-verify —— `t69` 复核（`§15af` 补强行 ＋ `§13` 判定条 ＋「台账何时非零」关键问）**独立判词**

> 复核者 `verifier`（任务 `t69` 的复核面；本席唯一写入 ＝ 本件）。**一切现取自算**；**未改 `docs/ROUTES.md`**、未改任何他件、未跑腿、未构建。
> 口径：`porcelain` **只说明「工作树 vs `HEAD` 的差」，不说明写者数**；引用 `app_g1.log` 一律带 `ts=` 并声明工作树态/提交态。所有读数带亚秒 `ts=`。

---

## §0 快照（现取）

| 项 | 现取值 | `ts=` |
|---|---|---|
| `HEAD` | **`5d6850b`**（`docs(#81): t69 §15af 补强 —— W7 结论落到 §15af（进度口径条…）`，`2026-09-28T21:50:55+08:00`） | `2026-09-28T21:51:19.101233279+08:00` |
| `HEAD` 笔 `numstat` | **`1 0 docs/ROUTES.md`** ＋ `100 0 build/MilBridge/P1-w7-close-report.md`（新建） | 同上 |
| `docs/ROUTES.md` | 现/`HEAD` ＝ **`2f611466dc4fee22`**｜`HEAD^` ＝ **`ce19680de862e7fc`**｜行数 `851 → 852`（`+1`） | 同上 |
| `app_g1.log` | **`cb0a3e5510b07790`**／`1137` 行；**两态一致**（对它的 `git diff` ＝ **0** 行）⇒ 本件引用可作**提交态＝工作树态** | `21:48:41.122710418` |
| `porcelain` | 8 行（**写域内存在未提交差异，归属未核**） | `21:51:19.101233279` |

---

## §1 复核① —— `runner` 那行（`§15af` 补强）：**成立，附两处「射程未写全」**

- **纯插入**：`numstat 1 0`；删除行数 **`0`**（我以 `git diff \| grep -cE '^-[^-]'` 现取）｜插入点 hunk ＝ `@@ -823,6 +823,7 @@`（落在 `§15af` 区）⇒ **`§13` 未被碰**（`§13` 段落更靠前，且零删除 ⇒ 结构上不可能被改）✓
- **并存不打架**：新增行为**单行**（`4674` 字节）、行首即 `- ⏪`，且自述「上面各条原文一字未删」⇒ 与上文各 dated 行**并存**（无改写）✓
- **glyph 计数两态同值**（我以 `git show HEAD^:docs/ROUTES.md` ＋ 现盘各数一遍）：`✅ 308`／`🟡 72`／`🔴 81`／`⚪ 39` —— **两态逐格相同** ✓（队长的 `✅308/🟡72/🔴81` 成立；另 `⚪39` 亦同值）
- **两个 `Lo*` 口径我复算逐值同**：`^Lo[A-Z]` ＝ **`17`**｜`^Lo` ＝ **`18`**（多出 `LocbkGetObjectHandlerInfo`，`Lo` 后是小写 `c`）｜`^Fs` ＝ **`66`** ⇒ 行内写法**正确** ✓
- **三值/两锚我现取复算**：`so16` ＝ **`2a5165700a8c8579`** ✓｜`exports` 行数 ＝ **`557`** ✓｜`tool/ops/impl` 现取（跑计数牙，捕获式）＝ **`99/87/93`**（`PTSGAP=PASS tool=99 dead=11 artifact=1 ops=87 impl=93 so16=2a5165700a8c8579 exports=557`）✓
- **须点名的两处（不是「假」，是「射程未写全」）**：
  1. **`F1`（low）**：行内「端口层 `grep` 现取**无任何 `Lo*` 的 `DllImport`**」**只在 `build/**`＋`src/**` 面成立**；六个 `Lo*` 的 `DllImport` **声明在 `upstream/wpf/**`**（`…/TextFormatting/LineServices.cs:1464` 起，形如 `[DllImport(DllImport.PresentationNative, EntryPoint="LoSetBreaking")]`），而该树**正是本仓 managed 源树**（`git ls-files 'upstream/**/*.cs'` ＝ `4188` 件 vs `src/**/*.cs` ＝ `70` 件；判据端牙 `check-shim-coverage.py:37` 写死 `UP=ROOT/upstream/wpf`）⇒ 应写成「**端口层（`build/**`＋`src/**`）无声明；声明在 `upstream` 派生 managed 树**」。
  2. **`F2`（low）**：行内「门禁步 `PTS-PAGES` 只读 `leg_*.env` 的列、不读 `entry=` ⇒ 其绿对前沿位移零证据力」——**结论成立**（该件 `g10_name_check()` 只报形态、**不进 `rc`**），但「**不读** `entry=`」**不完整**：同一件 `pts-pages-guard.sh` 的 `g10_name_check()` **确实读** `app_g1.log` 的 `entry=`（现取 `:110–127`，`grep -o 'entry=[A-Za-z0-9_]*'`），无名时打 `PTS_G10_NAME=NOINFO reason=frontier-unnamed`。⇒ 精确写法：「**默认腿**（`leg_*.env`）不读 `entry=`；另有一条**不进 `rc`** 的形态对拍**读** `entry=` ⇒ 其绿仍**零证据力**」。

## §2 复核② —— 队长 `§13` 那条（`docs/ROUTES.md:245`，`2731` 字节）：**七块中 5 块成立、2 块须纠正**

| 块 | 判 | 现取证据 |
|---|---|---|
| ① 能力前进 | **成立（after 侧）／`NOINFO`（before 侧）** | after 侧我逐值复现：`tool/ops/impl=99/87/93`｜`so16=2a5165700a8c8579`｜`exports=557` ✓；`entry=LoCreateContext 3→0` 见判据端牙现取 `PTSGAP_FRONTIER before=LoCreateContext@3 after=unknown@2` ✓。**before 侧**（`556`／`100/88/95`／`6825dd7071387a46`）**无仓内载体**（`bin/*` 为 gitignored、`exports.txt` 不入 git）⇒ `NOINFO(reason=before 侧无仓内可复算载体)` |
| ② `entry=unknown ×2` | **成立** | `grep -o 'entry=[A-Za-z0-9_]*' app_g1.log \| sort \| uniq -c` ⇒ **`2 entry=unknown`**；逐字两行 `:511`／`:965` ＝ `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=unknown err=-10000 action=page-placeholder（已画出页级占位；进程继续）` ✓ |
| ③ 机制 | **不成立（过宽，须改写）** | 见 §3：「未命中任何 **shim 入口**」应为「未命中任何**缺口 stub**」；「解析期 ⇒ **结构性无名**」应改为「解析期的 DllImport 三族异常**自带入口名**，端口层只读台账 ⇒ 名字被丢弃」 |
| ④ 候选池真、此刻不可达 | **成立（条数）／射程须补（同 `F1`）** | `^Lo[A-Z]=17`／`^Lo=18`／`^Fs=66` 我复算逐值同 ✓；「无任何 `Lo*` 的 `DllImport`」见 `F1` |
| ⑤ 要变成具名还缺什么 | **过强（须改写）** | 「否则台账无行、**前沿永远无名**」不成立：`Describe()`（`PtsCache.Linux.cs:1030`）只读台账，而**异常自带入口名** ⇒ **取数一格**即可具名（见 §4） |
| ⑥ 口径（防读反） | **成立（附 `F2`）** | 「`impl` 是缺口计数 ⇒ 真进步让它下降」✓（现取 `impl=93`，自 `95` 沿 `94→93`）；「进度判据是具名前沿跳数」✓；「门禁绿零证据力」✓（附 `F2` 精确化） |
| ⑦ `NOINFO` | **成立** | 「不声称两页可用」「不可具名 ≠ 无缺口」两条与本席现取一致（两页仍洋红占位，见件外证据面） |

## §3 复核③ —— 队长点名的关键问：**台账在什么条件下才会非零？**：**能指出那一步 ⇒ 判 (甲)**

**机制（我现取复算，逐条给锚）**

1. `g_pts_seq` **只在 `wpf_pts_gap()` 内递增**：`src/WpfGfx.Linux.Native/src/win32_pts.c:144`（`int seq = ++g_pts_seq;`）；而 `wpf_pts_gap()` 的**全部调用点** ＝ `:226`／`:232`／`:239`／`:246`／`:325`／`:332`，即**六个 gap stub**：`CreateDocContext`／`DestroyDocContext`／`GetFloaterHandlerInfo`／`GetTableObjHandlerInfo`／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle`。
2. `WpfLinuxWin32_PtsGapCalls()`（`:348`）返回 `g_pts_seq`；`WpfLinuxWin32_PtsGapReport()`（`:373`）**从计数器**（`g_pts_calls[]`／`g_pts_seq`）汇总 `entries=/calls=/first=/last=` ⇒ **与 stderr 打印预算无关**（预算只挡打印、不挡记账）。
3. 两条导出自 **`62c7a7b`（`sync(#50)`）即在册**（`git log -S` 现取）⇒ 本次 `unknown` **不是「旧 shim 读不到台账」**。
4. **真实现入口不留痕**：`LoCreateContext`（`:284`）／`LoDestroyContext`（`:304`）**不调** `wpf_pts_gap` ⇒ 「进没进 native」**不能**由台账判断；台账只证「**有没有命中缺口 stub**」。
5. `err=-10000` 亦非证词：`NativeError()`（`PtsCache.Linux.cs:987–997`）读不到 `err=` 时**回退常量** `A1_STUB_ERR = -10000`（`:1028`）。

**「哪一步有行」＝ 可指认**：本链（`PtsCache.AcquireContextCore` → `CreatePTSContext`）现取调用序（`build/PresentationFramework.Linux/PtsCache.Linux.cs`）：
`:519 InitInstalledObjectsInfo`（其内 `:726 PTS.CreateInstalledObjectsInfo`，**已导出**）→ `:523 InitGenericInfo`（**纯回调注册，无 native 调用**）→ `:526/:527 InitFloaterObjInfo／InitTableObjInfo`（同，纯回调）→ `:532 new TextFormatterContext()`（**只调 `LoCreateContext`**，`upstream/…/TextFormatterContext.cs:113`；六者的调用点在 `:257/:288/:314/:336/:354/:374` 等**后续格式化方法**，不在 ctor 内）→ **`:548 PTS.Validate(PTS.CreateDocContext(…))` ＝ 本链上第一个会留痕的 gap stub**（`win32_pts.c:226`，`exports.txt`＝`1`）。
⇒ **答案**：**当且仅当调用到上面六个 stub 之一，台账才有行；本链上最先的那一步 ＝ `:548 CreateDocContext`** ⇒ 按队长判据「能指出某一步有行 ⇒ 翻 (甲)」⇒ **判 (甲)**。
⇒ **但本次证据显示该步未到达**（台账零行 ⇒ 六个 stub 全未命中）⇒ **本次前沿 ＝ `:548` 上游的某个 DllImport-解析失败**（`IsPtsUnavailable` 闭集，`PtsCache.Linux.cs:1015`），其名字**在异常里**；`:507–548` 窗口内会留痕的只有 `:548` 一处，而 `:519`（已导出）与 `:532`（只调真实现）都不留痕 ⇒ **失败点落在它们之前或它们自身**（含装置面 `DllNotFoundException`／`BadImageFormatException` 两支）。

## §4 结论：**(甲) 可具名（条件式）** ＋ 推荐形态

1. **答是非题**：**可具名**。排除「native 亲口作证」支后，闭集只剩 **DllImport 三族** ⇒ 即「某个被 managed 声明的 `PresentationNative` 入口在本 shim 里不存在」（或 shim 装载面），而**这类异常自带入口名** ⇒ `unknown` 是**取数缺口**、不是结构性无名。
2. **推荐形态（首选，最小、不新增「假成功」面）**：先在 `Describe()`（`PtsCache.Linux.cs:1030`）／`[HC-UNHANDLED]` 那一行**加一格取数**（异常类型 ＋ DllImport 三族的入口名），**重跑一趟 `g1`** ⇒ `entry=` 面即从 `unknown` 变具名。
3. **若按 `P03` 补 stub**：本链上**第一个会留痕的站**是 `CreateDocContext`（`:548`）——但它是**已导出**的 stub ⇒ 补它**只让台账有行、不改变缺口计数**；真正推进能力应取「**缺口清单（99）∩ 该链**」，顺序按 §3 的调用序，**不是**六选一（六者在本链失败窗口**之后**）。
4. **对 `§13`③／⑤ 与 `§15af` 行的处置建议（我不改件，只点名）**：把③改写为「未命中任何**缺口 stub**」（并把 `err=-10000` 标为常量回退）；把⑤改写为「**可具名：先取异常携带的入口名（一格取数），再决定是否补 stub**」，并附 `F1`／`F2` 的射程补语。

---

## `NOINFO`（具名，既不算绿也不算红）

1. `NOINFO(reason=未取得运行期异常名)`：**具体是哪个入口**我无运行期观测（本任务不跑腿/不构建）⇒ 只给**候选窗口**（§3 末）＋取数方案。
2. `NOINFO(reason=before 侧无仓内载体)`：`§13`① 的 `before` 值（`556`／`100/88/95`／`6825dd7071387a46`）无 git 可复算载体（`bin/**` gitignored）。
3. `NOINFO(reason=未逐支排除装置面)`：`DllNotFoundException`／`BadImageFormatException` 两支未逐支排除。
4. `NOINFO(reason=未跑整趟门禁／未重跑腿)`：本件只做静态现取 ＋ 两条牙的捕获式复跑。
5. `NOINFO(reason=他车道在飞)`：`porcelain` 8 行含 `t73`／`t74` 在飞件（**归属未核**），本件未引用其读数。

## 推翻的话 ＋ 结论

- **推翻**（具名）：`§13`③ 的「未命中任何 **shim 入口**」与「解析期 ⇒ **结构性无名**」两句（应分别改为「未命中任何**缺口 stub**」与「名字在异常里、只是没取」）；`§13`⑤ 的「前沿**永远无名**」（过强）；`§15af` 行两处射程（`F1`：`Lo*` 声明在 `upstream` 派生 managed 树；`F2`：`PTS-PAGES` 另有一条**读 `entry=` 但不进 `rc`** 的 `G10` 形态对拍）。
- **不推翻**：`§15af` 行的 `numstat 1 0`／`§13` 未碰／glyph 两态同值／`^Lo[A-Z]=17`·`^Lo=18`·`^Fs=66`／`so16`·`exports`·`tool/ops/impl` 三值／「与上文 dated 行并存」／「门禁绿零证据力」／两条 `NOINFO`。
- **结论**：复核① **成立**（附 `F1`／`F2` 两处 low）｜复核② **七块中 5 块成立、2 块（③⑤）须改写**｜复核③ **可指出「走到 `:548 CreateDocContext` 台账必有行」⇒ 判 (甲) 可具名（条件式）**，实现形态 ＝ **先补一格取数**（重跑 `g1` 即具名），补 stub 则第一个留痕站 ＝ `CreateDocContext`（已导出，不改缺口计数）。


⏪ **dated 追加（落定后复取；`ts=`写作时刻（现取 `date`）＝ `2026-09-28T21:52:56.269563933+08:00`）**：① 本件 §0／§1 的 `porcelain` 与 `ROUTES.md sha16` 是**当时刻**读数（`porcelain` 8 行／`ROUTES.md 2f611466dc4fee22`）；**落定后复取已位移** —— `docs/ROUTES.md` 现取 **`13f85f9d4f99ca06`**（≠ 上述）、`porcelain` 13 行 ⇒ **写域内存在未提交差异，归属未核**（`t74`／`t73` 在飞）；**本席唯一写入 ＝ 本件**，`docs/ROUTES.md` **我一个字节也未写**（队长明令不得写它）。② 结论（`(甲) 可具名（条件式）` 与两处 low `F1`／`F2`）**不受该位移影响**：判据全部基于 §3 的源码锚（`PtsCache.Linux.cs:519/:523/:526/:527/:532/:548`、`win32_pts.c:144/:226/…/:373`、`TextFormatterContext.cs:113`／`:257…`）与 `app_g1.log` 的两态一致读数。③ **本席自伤第 `1` 处（零损伤）**：本件由写作工具建出时模式 `600`，落定前已 `chmod 644`。④ 正文（§0–§结论）**一字未改、删行 `0`**。
P1-W7-FRONTIER-VERIFY: t69 复核｜① `§15af` 补强行 成立（numstat 1 0／§13 零删除未碰／glyph 两态同 ✅308·🟡72·🔴81·⚪39／^Lo[A-Z]=17·^Lo=18·^Fs=66 复算逐值同／so16 2a5165700a8c8579·exports 557·tool/ops/impl 99/87/93 现取同／与上文 dated 行并存）＋ low 2（F1 Lo* 声明在 upstream 派生 managed 树 LineServices.cs:1464，端口层 build/**+src/** 无声明；F2 PTS-PAGES 另有 g10_name_check 读 entry= 但只报形态不进 rc）｜② §13 条（:245，2731 字节）七块：5 成立、③⑤ 过宽须改写（③「未命中任何 shim 入口」应作「未命中任何缺口 stub」；err=-10000 是 NativeError 常量回退 PtsCache.Linux.cs:991/:1028）｜③ 台账非零条件 ＝ 六个 gap stub 之一被调（win32_pts.c:144 递增，调用点 :226/:232/:239/:246/:325/:332；PtsGapReport :373 从计数器汇总；两导出自 62c7a7b 在册）⇒ 本链第一步 ＝ PTS.CreateDocContext（PtsCache.Linux.cs:548）⇒ 判 (甲) 可具名（条件式）：本次未到达该步（台账零行）⇒ 前沿在 :548 上游的 DllImport 解析失败（闭集 PtsCache.Linux.cs:1015），名字在异常里，一格取数（Describe() :1030）＋重跑 g1 即具名｜调用序锚 :519(CreateInstalledObjectsInfo :726 已导出)→:523/:526/:527(纯回调)→:532(new TextFormatterContext 只调 LoCreateContext, upstream :113)→:548(gap stub)｜六者调用点在 :257/:288/:314/:336/:354/:374（失败窗口之后）｜app_g1.log cb0a3e5510b07790/1137 两态一致 @ts=21:48:41.122710418｜HEAD 5d6850b｜porcelain 8 行（归属未核）｜NOINFO 5 条
