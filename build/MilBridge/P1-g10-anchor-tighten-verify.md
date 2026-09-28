# P1-G10-ANCHOR-TIGHTEN-VERIFY —— `t82`（非 PTS 域归因锚收紧）**独立复核判词**

> 复核者 `verifier`（任务 `t84`）。**只读仓树**：未改 `t82` 的任何件、未跑整趟门禁、未构建、未跑腿、未占显示位、未 `git add/commit/push`；**唯一写入 ＝ 本件**（`build/MilBridge/P1-g10-anchor-tighten-verify.md`）。
> 夹具**全部由本席在仓外重建**（`~/wv88y/t84/**`，收尾删净；**未引**我 `t77` 的旧文件、**未引** `t82` 的输出当证据）。所有读数现取、带亚秒 `ts=`。

---

## §0 快照（现取）

| 项 | 现取值 | `ts=` |
|---|---|---|
| `HEAD` | **`b47cf09`**（`t78 在册证据换代入账`，`2026-09-28T23:10:00+08:00`） | `2026-09-28T23:20:24.471724020+08:00` |
| 判据件 | `build/MilBridge/tools/pts-pages-guard.sh` ＝ **`944e61f39f24631c`／660 行**（mtime `23:16:26.707368192`；索引 `100644`／工作树 `644`）；`HEAD` 版仍 `59bffc8e5b5a621a`（483 行，**未提交**） | 同上 |
| 改前像（仓外备份） | `~/w281-scribe/bak/pts-pages-guard.sh.pre-t82` ＝ **`b74d2be6f9093115`／572 行**（＝ `t82` 自称改前值，**逐位相同**）｜另有 `…pre-t82b` ＝ **`9b46dc9b3fbfda32`／643 行** | `23:20:49.629693366` |
| `t82` 载体 | `build/MilBridge/P1-g10-anchor-tighten-report.md` ＝ `687c97f888c87d7e`／132 行 | `23:22:12.249012582` |
| 在册面 | `KNOWN-DEFECTS.md` ＝ **`95224a4c310900e5`／3878 行**（KD 最大号 **189**）｜`declared.tsv` ＝ **`d689bba84c456766`／234 行** | `23:21:54.838769640` |
| `k_pts_entries[]` | 现存 **`12`** 名（`t78` 把 `LoSetDoc`／`LoSetBreaking` 写进在册表 ⇒ **10 → 12**） | `23:20:24.471724020` |
| `porcelain` | 8 行（**写域内存在未提交差异，归属未核**；口径＝只说明「工作树 vs `HEAD` 的差」，**不说明写者数**） | `23:22:12.249012582` |

**现锚（`decl_hit()` 逐字，现取）**：`awk` 四重合取 —— ① `C[i] ~ /^[[:space:]]*\[[[:space:]]*DllImport[[:space:]]*\(/`（**属性起始行**；先剥行/块注释，`inb` 跨行状态保持）② 属性块（最多拼到第 `i+5` 行或遇 `]`）内含 `EntryPoint[[:space:]]*=[[:space:]]*"<名>"` ③ 属性块之后 **≤3 个非空行**内命中 `extern` ④ 无命中 ⇒ `return 1`（⇒ `unattributable` ⇒ 红并点名）。

---

## ① 我原来的骗法被堵住了吗：**成立**（五腿全红且点名）

夹具**全部在仓外重建**（**不是**我 `t77` 那份），用 `PTS_G10_DECL_TREE=<我造的假树>`＋`--g10-name <腿>`，`ts=23:20:58.509014477`：

| 腿 | 假树内容（仓外） | `rc` | 判词行原样（截断） |
|---|---|---|---|
| **c1** | 只含一行**注释**：`// 注释里的假声明示例：DllImport(Whatever, EntryPoint="FakeZZ")` | **`1`** | `PTS_G10_NAME=FAIL frontier=FakeZZ off-roster=FakeZZ roster=12 domains=unattributable decl=none（域归因**失败**…` |
| **c2** | `//` 注释掉的**真形态**：`// [DllImport(… EntryPoint = "CommentedZZ")]` ＋ `// internal static extern int CommentedZZ();` | **`1`** | `FAIL … off-roster=CommentedZZ … domains=unattributable decl=none` |
| **c3** | **字符串字面量**含该子串：`string s = "[DllImport(x, EntryPoint = \"LiteralZZ\")] extern";` | **`1`** | `FAIL … off-roster=LiteralZZ … domains=unattributable` |
| **c4** | `/* … */` **块注释**包住整段声明 | **`1`** | `FAIL … off-roster=BlockZZ … domains=unattributable` |
| **c5** | **孤属性行**（属性后无 `extern`） | **`1`** | `FAIL … off-roster=OrphanZZ … domains=unattributable` |

⇒ 旧洞（一行注释即可判绿）**已闭合**，且点名字段（`off-roster=`／`domains=`／`decl=`）在场 ✓
**正控（真声明必须绿）**：属性跨三行的真形态（`[DllImport(…` ／`ExactSpelling = true,`／`EntryPoint = "SplitZZ")]` ＋ `extern`）⇒ **`rc=0`／`PASS … domains=dllimport-entry decl=…/Split.cs:1`** ✓

## ② 真声明没被漏：**成立**（差异原因已钉死）

- **声明位现取**：`upstream/wpf/…/TextFormatting/LineServices.cs:1470` ＝ `[DllImport(DllImport.PresentationNative, EntryPoint="LoSetDoc")]`，`:1471` ＝ `internal static extern LsErr LoSetDoc(` ⇒ **真声明在册** ✓
- **派单期望那一行**（我把名单源**钉到不含 `LoSetDoc` 的副本**，`roster=11`，其余不变）：`bash pts-pages-guard.sh --legs /home/links-dev/p1-ptsname/legs-after` ⇒ **`rc=1`**／**`PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=11 domains=dllimport-entry decl=/home/links-dev/netTest/GitProj/WPFOnLinux/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormattin…`** ✓ —— **正是派单要求的那一行**。
- **现盘直接跑**（名单源＝现盘 `win32_pts.c`，`roster=12`）：`rc=1`／`PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=12 domains=pts-declared（形态判据：具名行**在在册名单内**…）`／`PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded` ⇒ **判序「先在册表」使然**（`t78` 把 `LoSetDoc` 写进 `k_pts_entries[]`），**不是漏**；差异**只**来自名单源，我把这一格用「钉名单源」的实验隔离开了 ✓
- **非在册真名对照**（我自己跑）：腿 `entry=AdjustWindowRectEx` ⇒ `rc=0`／`PASS observed=AdjustWindowRectEx … domains=dllimport-entry decl=…/PresentationFramework/…` ✓
- **我自己的零漏扫描**（独立实现，现取 `ts=23:21:54.838769640`）：`grep` 命中 **68** 件 `.cs`｜**属性起始行 `1221`**｜属性块内含 `EntryPoint` 字面量 **`548`**｜**去重名 `452`**｜`extern` 出现在第 N 个非空行 ⇒ **`{1: 524, 2: 24}`**｜**超出 ≤3 窗口（或找不到 `extern`）的条数 ＝ `0`** ⇒ 与 `t82` 的三值（1221／548／452）**逐值相同**且**零漏** ✓

## ③ `G10b` 一格未放宽（红线）：**成立**

- **PTS 域真名**（在册表十二名之一 `CreateInstalledObjectsInfo`）⇒ **`rc=0`**／`PASS … domains=pts-declared` ✓
- **PTS 形状假名**（`CreateInstalledObjectsInfoZZ`）⇒ **`rc=1`**／`FAIL … off-roster=CreateInstalledObjectsInfoZZ … domains=unattributable decl=none` ⇒ **仍必红并点名** ✓
- **自测例数不降**：`bash pts-pages-guard.sh --selftest` ⇒ `rc=0`／**`PTS_GUARD_SELFTEST=PASS pass=40 fail=0`**（我 `t79` 核到的是 `pass=40`；`t82` 报的 40 一致；**未**低于 37）✓

## ④ 有没有把「收紧」做成「换一种能骗」：**1 处判红（`F-N1`）＋ 2 处漏检边界（`F-N2`／`F-N3`）**

| 腿 | 新路径（仓外夹具） | 现取读数 | 判 |
|---|---|---|---|
| **c6** | **`#if NEVER` 区内的「语法真声明」**（属性起始行＋`EntryPoint = "NeverDeclZZ"`＋`extern`）⇒ **不编译** | **`rc=0`／`PASS observed=NeverDeclZZ … domains=dllimport-entry decl=…/T6/a/Never.cs:2`** | **骗得过 ⇒ 判红（`F-N1`，medium）** |
| **c9** | `EntryPoint = nameof(NameofZZ)`（真声明但**非字面量**） | `rc=1`／`FAIL … off-roster=NameofZZ … domains=unattributable` | 漏检（`F-N2`，low） |
| **c7b** | 属性块与 `extern` 之间夹 **4 个非空行** | `rc=1`／`FAIL … off-roster=Gap5ZZ …` | 漏检（`F-N3`，low） |
| c8 | 属性**跨行**（真形态） | `rc=0`／`PASS … decl=…/Split.cs:1` | 正控成立（不算骗） |

**`F-N1` 的现树风险实测（我自己扫）**：`#if NEVER`／`#if false` 区内**含 `EntryPoint` 字面量的行 ＝ `0`**（同时含 `#if NEVER` 与 `DllImport` 的件只有 2 件：`…/MS/Internal/PtsHost/Pts.cs`、`…/Shared/MS/Win32/NativeMethodsOther.cs`）⇒ **当前无具名受害者**：该洞是**潜在**的，**不构成本刻假绿**。但本仓自己的词汇里就有「`#if NEVER` **死声明**」（`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` 明确定义 `dead ＝ 工具口径里属于 Pts.cs #if NEVER 死声明的条数`）⇒ 建议（**不代改**）：锚加一条「命中行不在 `#if NEVER`／`#if false` 区内」，或至少在口径句里把这条射程写明。
**`F-N2`／`F-N3` 的现树实测**：548 处属性块**全部**用**字符串字面量**、`extern` 距离分布 **{1: 524, 2: 24}** ⇒ 两条漏检**当前无实例**（射程边界，非现行漏）✓

## ⑤ 归属与不变量：**成立（附 `F-5` 一处少报点名）**

- **`D-G189` 并入、无虚假扩大**：第二面以 `⏪` 行**追加**于 `KNOWN-DEFECTS.md:3872`，**逐字**写「**本行由 `t82` 追加，不新立号**」；第一面 `:3860–:3870`（现象／机理／最小复现／修法／🔴 口径句／判据／责任归属／边界／同族）**原样在位**；**KD 最大号仍 `189`** ⇒ **未新立号** ✓
- **同趟三态**：`declared.tsv` ＝ `d689bba84c456766`／234 行（最大号 189）；`DEFREG` 两遍现跑均 **`PASS declared=224 route_ids=224`**（两值相等）＋ **`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`** ✓
- **四条不变量**：`^run_step "` ＝ **`62`**｜`--expect` ＝ **`234`**｜`# VERIFYALL-STEPS-DECL: 62 gen=#81`｜覆盖面 ＝ **`234`** ⇒ 全不变 ✓
- **两枚哨兵**：`cmp IDENTICAL`（`FP=d697b1e10ff48881` ＝ `BRIDGE_SRC_FP`，与 `inputs_fp` **同名不同物**）⇒ **本席判：不该重写哨兵**（写不写归队长）✓
- **`inputs_fp` 位移留痕**：现取 **`ec63b28dc68e6468f6c78dda573af9dc`**（`ts=23:21:54.838769640`）；**该值在册命中 `P1-g10-anchor-tighten-report.md` 与 `HANDOFF-NEXT.md`** ⇒ **位移已如实留痕** ✓（注：`evidence/**` 另有换代在飞，取值时刻已写明；判据件本身也在覆盖面内）
- **只增不改（逐条解释删除）**：改前像 `pre-t82`(572) → 现盘(660) 全量 ＝ **`9` 删 / `97` 增**：**4 删**全在 `decl_hit()`（旧实现体逐行：旧签名行／`local nm="$1" out`／旧 `grep -rn … DllImport[^)]*EntryPoint…` 一行／`printf … | cut -d: -f1,2`）＋ **5 删**在 `--selftest` 的**旧 `c26` 例**（其中 **1 行是被删的注释行** `# ㉖ …`，其余 4 行为该例的断言代码）⇒ **无其它 prose 删行** ✓
- **`F-5`（low，点名）**：`t82` 载体称「专项删行 ＝ **4 行**，全在 `decl_hit()` 内」——若按 **572→660 全量**口径读，则**少报 5 行**（那 5 行在 `--selftest`，疑因 `t78` 把 `LoSetDoc` 写进在册表而改写 `c26` 例）；另：`pre-t82`(572) 与 `pre-t82b`(643) **两个备份**说明其间还有一次 **572→643 的中间落盘（4 删/75 增）**，其作者**我未核（归属未核）**

## ⑥ 载体落地与边界自证

- 载体：`build/MilBridge/P1-g10-anchor-tighten-verify.md`（**新建**，UTF-8，**首记号 ＝ `# P1-G10-ANCHOR-TIGHTEN-VERIFY`，不是 `# ⏪ `**），mode **`644`**，**末行自带可复算自报口径 sha16**。
- **夹具收尾删净**：见 §结论末（我删除后复取 `find` 计数 ＝ 0）。
- 边界自证：本回合**唯一写入 ＝ 本件**（`porcelain` 本件行 `?? build/MilBridge/P1-g10-anchor-tighten-verify.md`）；未跑整趟门禁／未构建／未跑腿／未占显示位／未 `git add/commit/push`；`t82` 的件**一字未改**（判据件现取仍 `944e61f39f24631c`）✓

---

## `NOINFO`（具名，既不算绿也不算红）

1. `NOINFO(reason=未逐名复跑 452 名)`：我以**自己的扫描器**复算「属性行／含 `EntryPoint` 行／去重名／`extern` 距离」四个量（`1221/548/452/{1:524,2:24}`，零漏），但**未**把 452 名逐个喂给判据件各跑一遍（`t82` 称它做了）。
2. `NOINFO(reason=未核 572→643 中间落盘作者)`：见 `F-5`（归属未核）。
3. `NOINFO(reason=未跑整趟门禁)`：`verify-all` 未跑（一跑即构建）⇒ `PTS-PAGES` 在整波内的端到端表现未验。
4. `NOINFO(reason=未核其它判据件)`：本件只覆盖 `decl_hit()` 这一处锚；`pts-pages-guard.sh` 其余判据与别的牙未扫。
5. `NOINFO(reason=他车道在飞)`：`inputs_fp` 多次位移、`evidence/**` 换代、KD/`declared.tsv` 的其它写入**归属未核**，不计入本判词（KD/declared 只作现取值引用）。

## 推翻的话 ＋ 结论

- **判红（具名）**：**`F-N1`（medium）** —— 锚**只看语法形态、不问编译状态**：`#if NEVER`／`#if false` 区内的**死声明**可把任意名字判成 `dllimport-entry` **绿**（我重建夹具现取 `PASS observed=NeverDeclZZ … decl=…/Never.cs:2`）；**现树无具名受害者**（该区内 `EntryPoint` 字面量 ＝ 0）⇒ 潜在洞，建议加「不在 `#if NEVER`／`#if false` 区内」一条或在口径句写明射程。
- **点名（不翻主结论）**：**`F-N2`**（`EntryPoint = nameof(...)` 漏检）｜**`F-N3`**（`extern` 超过 ≤3 非空行窗口漏检）｜**`F-5`**（载体「删行 4」按全量口径少报 5 行；另有 572→643 中间落态作者未核）。三者**现树均无实例**。
- **逐条成立**：① 原骗法五腿全红且点名｜② 真声明零漏（`LineServices.cs:1470` ＋ 钉名单源复现期望行 ＋ `AdjustWindowRectEx` 正控 ＋ 我自己的 `1221/548/452/零漏` 扫描）｜③ `G10b` 未放宽（真名绿／形状假名红）＋ `--selftest pass=40 fail=0`｜④ 「换一种能骗」的其余路径（注释三态／字面量／块注释／孤属性／跨行属性）全部围住｜⑤ `D-G189` 并入不新立号（最大号 189）＋ `DEFREG` 两遍 224/224 ＋ `DECLDRIFT=0` ＋ 四条不变量不变 ＋ 哨兵 `cmp IDENTICAL` ＋ `inputs_fp` 已留痕 ＋ 删行逐条可解释。
- **结论**：复核项 ①–⑤ 逐条成立，附 **1 处 medium（`F-N1`，判红点名）＋ 3 处 low（`F-N2`／`F-N3`／`F-5`）＋ 5 条 `NOINFO`**；`t77` 的 `F1` 真缺陷**已闭合**。

P1-G10-ANCHOR-TIGHTEN-VERIFY: t84 attempt 1 | 判据件 944e61f39f24631c/660 行（改前像 b74d2be6f9093115/572，仓外备份逐位同）｜① 原骗法必红成立（c1 注释假声明／c2 注释掉的真形态／c3 字符串字面量／c4 块注释／c5 孤属性 ⇒ 全 rc=1 FAIL off-roster=… domains=unattributable decl=none；跨行真声明正控 rc=0 PASS decl=…/Split.cs:1）｜② 真声明零漏成立（LineServices.cs:1470 [DllImport(…EntryPoint="LoSetDoc")] ＋ :1471 extern；钉名单源副本 roster=11 复现 PASS … domains=dllimport-entry decl=…LineServices.cs:1470；现盘 roster=12 因 t78 写进在册表 ⇒ domains=pts-declared 判序使然；AdjustWindowRectEx 正控 PASS；我自扫 68 件/1221 属性行/548 含 EntryPoint/452 名/extern 距离 {1:524,2:24}/超出窗口 0）｜③ G10b 未放宽（真名 rc=0 pts-declared；形状假名 rc=1 FAIL unattributable）＋ selftest PASS pass=40 fail=0｜④ 新路径：F-N1 medium 判红（#if NEVER 死声明夹具 c6 ⇒ rc=0 PASS decl=…/Never.cs:2；现树该区内 EntryPoint 字面量 0 ⇒ 潜在无受害者）＋F-N2 low（nameof 漏检 c9 FAIL）＋F-N3 low（extern 隔 4 非空行 c7b FAIL）｜⑤ D-G189 第二面追加于 KD:3872 明写不新立号、KD 最大号 189；declared d689bba84c456766/234；DEFREG 两遍 PASS 224/224 ＋ DECLDRIFT=0；不变量 62/234/62 gen=#81/234；哨兵 cmp IDENTICAL（FP=d697b1e10ff48881）；inputs_fp ec63b28dc68e6468f6c78dda573af9dc 已在 P1-g10-anchor-tighten-report.md 与 HANDOFF-NEXT.md 留痕；删行 9=decl_hit 4 ＋ selftest 旧 c26 5（含 1 注释行）⇒ F-5 low 少报 5 行、572→643 中间落态作者未核｜夹具收尾删净｜HEAD b47cf09｜NOINFO 5 条
SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-g10-anchor-tighten-verify.md | sha256sum | cut -c1-16`）= `0a619d8549fcb888`
