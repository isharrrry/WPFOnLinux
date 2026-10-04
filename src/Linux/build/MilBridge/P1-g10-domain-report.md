# P1 G10 **域前提修正**（`t76`／`scribe`）—— `entry=` 可属**非 PTS 域**：按域分格 ＋ 两极化 ＋ 现树真读数

写者 `scribe`（attempt 2／`3a1107d8-8711-44e8-96d8-e9cc8abb1c52`）｜读时 `ts=2026-09-28T22:56Z–23:0x+0800`｜一切读数**现取自算**，每格带亚秒 `ts=`
写域（硬条款）：`build/MilBridge/tools/pts-pages-guard.sh`／本载体／`docs/ROUTES.md`／`build/MilBridge/tools/defect-registry-declared.tsv`（第 ⑥ 条成立时）／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（第 ⑥ 条成立时）；另按契约追写 `build/MilBridge/HANDOFF-NEXT.md` 的 **`cell=#1` 一行**（纪律 28）。

## §0 一句话
`entry=` 的**取值域**由**取值者**决定 —— native 台账零行时它取自**内层异常文本**（`PtsCache.Linux.cs` 的 `Describe()`）⇒ 取值域 ＝ **DllImport 入口名**、**不必属 PTS**。据此把 `g10_name_check()` 从「一律拿 PTS 在册表对拍」改成**按域分格**（★ 不放宽 `G10b`）：**① PTS 在册表命中 ⇒ 绿（PTS 域仍只在册表内取绿）｜② 未命中 ∧ 声明树 `upstream/wpf/**` 里对拍上该入口的 `DllImport` 声明 ⇒ 该格绿并点名声明位｜③ 两级都不命中 ⇒ 红并点名｜④ 声明树不在 ⇒ `NOINFO`（不算绿）**。

## §1 修了什么（逐处成对；判据件属**覆盖面内**件）
```
件：build/MilBridge/tools/pts-pages-guard.sh
改前 `ts=2026-09-28T21:54:55.099+0800`：sha16 `59bffc8e5b5a621a`（全 64 hex 见交件消息）／483 行／644／%h=1（备份 ~/w281-scribe/bak/pts-pages-guard.sh.pre-t76，cmp IDENTICAL）
改后 `ts=2026-09-28T22:58:02.792+0800`：sha16 **`b74d2be6f9093115`**／**572** 行／644／%h=1；`git diff --numstat` ＝ **`95 6`**
删行逐条（6 行，**全部是代码行**，prose/history 0 删）：`off=""`／`for nm in $names_all; do`／`*$'\n'"$nm"$'\n'*) ;;`／`*) off="$off$nm," ;;`／旧 `FAIL … off-roster=…（具名行不在在册名单内…）` 的 echo／旧 `PASS observed=… roster=…（形态判据…）` 的 echo
新增面：① `decl_hit()` ＋ `DECL_TREE`（声明树内容锚；`PTS_G10_DECL_TREE` 可覆盖）② 函数内新 ⏪ 判据文本（域前提修正）③ 件头 `G10c` 一行 ＋ 依据一行（**加行**）④ 分类＋四支判词（新字段 `domains=`／`decl=`，**既有字段一个不减**）⑤ `--selftest` 新增四例（G10c 三格两极化 ＋ 声明树缺席）
```

## §2 域判定口径（**机器可核、内容锚、写死在判据里**；不用猜、不用名字形状启发式）
- **一级（PTS 域的定义）**：名字 ∈ `k_pts_entries[]`。**内容锚**＝ `src/WpfGfx.Linux.Native/src/win32_pts.c` 里 `static const char *const k_pts_entries[] = {` 到紧随的首个 `};`（无行号、无字面名字；现取 **10** 名）。
- **二级（非 PTS 域）**：名字在**声明树**里能对拍上 —— 命令（判据内实现同形）：`grep -rn --include='*.cs' -E 'DllImport[^)]*EntryPoint[[:space:]]*=[[:space:]]*"<名>"' upstream/wpf` ⇒ 命中即取 **`file:line`** 作声明位。
  **现取实证**（`ts=2026-09-28T22:56:51.871+0800`）：`… "LoSetDoc"` ⇒ `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1470:[DllImport(DllImport.PresentationNative, EntryPoint="LoSetDoc")]`（**同一行**同时含 `DllImport` 与 `EntryPoint=`，这是我们的**内容锚**）；反向读数：`grep -rl 'LoSetDoc' src/WpfGfx.Linux.Native/src/` ⇒ **0 件**（native 侧根本没这个符号）；两枚假名（`LoNotARegisteredEntZZ`／`NoSuchDeclaredEntryZZ`）在该树的命中数各 ＝ **0**。
- **判序写死**：**先在册表、后声明树**（一名同时在两处 ⇒ 归 **PTS 域**，按 PTS 域办）。实测 `LoCreateContext` 两处都在（在册表 ∧ `upstream` 声明）⇒ 判 `domains=pts-declared`。
- **三态不减字段**：`PASS`／`FAIL`／`NOINFO` 全在，`frontier=`／`off-roster=`／`roster=`／`observed=`／`names=`／`form=`／`reason=` 一字未减；只**增** `domains=`／`decl=`。
  `--selftest`：写前 `PASS pass=30 fail=0` ⇒ 写后 **`PTS_GUARD_SELFTEST=PASS pass=37 fail=0`**（旧 30 例零退化）。

## §3 两极化（**仓外**夹具 `/tmp/t76-fx*`，跑完即删；四条原样）
```
腿a PTS 域**假名**（`TAB entry=LoNotARegisteredEntZZ`）rc=1 ts=22:57:56.149
  PTS_G10_NAME=FAIL frontier=LoNotARegisteredEntZZ off-roster=LoNotARegisteredEntZZ roster=10 domains=unattributable decl=none（域归因**失败**：该名**既不在 PTS 在册表、也无「DllImport…EntryPoint=」声明位** ⇒ 红并点名；声明树=…/upstream/wpf）
腿b 非 PTS 域**真名**（`TAB entry=LoSetDoc`）rc=0 ts=22:57:56.252
  PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=…/TextFormatting/LineServices.cs:1470（**域前提修正**：非 PTS 域判定为**该入口名在声明树里对拍上**（内容锚「DllImport … EntryPoint=<名>」，声明位见 decl 字段）⇒ 该格绿并将名字与声明位如实点名；**不**拿 PTS 在册表判它）
腿c 非 PTS 域**假名**（`TAB entry=NoSuchDeclaredEntryZZ`）rc=1 ts=22:57:56.327
  PTS_G10_NAME=FAIL frontier=NoSuchDeclaredEntryZZ off-roster=NoSuchDeclaredEntryZZ roster=10 domains=unattributable decl=none（…同上）
腿d 声明树**不在**（`PTS_G10_DECL_TREE=/tmp/t76-fx/no-such-tree`，名字用真名 `LoSetDoc`）**整步** rc=2 ts=22:57:56.3xx
  PTS_G10_NAME=NOINFO reason=decl-tree-absent tree=… frontier=LoSetDoc roster=10（非 PTS 域的声明树不在 ⇒ **判不了** ⇒ 永不当绿）
  （`--selftest` 内亦钉此四例：`G10c·PTS假名⇒必红`／`非PTS真名⇒不红＋声明位点名`／`非PTS假名⇒必红`／`声明树缺席⇒NOINFO rc=2`）
夹具清除：`fixture-removed-ok`（`/tmp/t76-fx`）
```
**「不放宽 `G10b`」的机器证**：腿 a（PTS 形状的假名）与腿 c（非 PTS 形状的假名）**都红且都点名**；PTS 域**唯一**绿门仍是 `k_pts_entries[]`（腿 b 之所以能绿，是因为它在**另一个域**里被**声明位**对拍上，而不是因为判据松了口）。

## §4 现树真读数（`--legs /home/links-dev/p1-ptsname/legs-after`；成对）
```
修前 ts=2026-09-28T22:56:31.699+0800  rc=1
  PTS_G10_NAME=FAIL frontier=LoSetDoc off-roster=LoSetDoc roster=10（具名行**不在在册名单**内 ⇒ 红并点名；名单源=…/src/WpfGfx.Linux.Native/src/win32_pts.c）
  PTS_GUARD=FAIL legs=2/2 fails=g10-name-off-roster(LoSetDoc),native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded
修后 ts=2026-09-28T22:58:09.341+0800  rc=1
  PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=…/TextFormatting/LineServices.cs:1470（…）
  PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded
```
- **域前提那条红已消**：`fails` 里 `g10-name-off-roster(LoSetDoc)` **消失**，判据行由 `FAIL` 变 `PASS` 并交出声明位。
- ⚠️ **修后仍 `rc=1`，如实红、不折叠**：剩余唯一红是 **`native-ledger-absent(PTS_GAP n=0)`** —— 这是**另一条**判据（degraded 期要求「native 亲自作证 ≥ 1 行 `PTS_GAP`」），而本轮两条腿的 `NAMED … native_gap=0`（`leg_23.env`／`leg_24.env` 现取）**本来就是 0**（`P1-ptsname-result.md` §3 亦记「不是新伤」）。**成因与本次域前提同源**（链在到达第一个 native 留痕站之前就被 LS 族 DllImport 掐断）⇒ **它属另一族、应由队长裁定**（本席**不**改相位、**不**放宽阈值）。
- 腿证据自证：`/home/links-dev/p1-ptsname/legs-after/leg_*.env` 的 `DEV … shim=2a5165700a8c8579 pf=8ef62d37e7c2ce2e`（与在册权威 `pf` 相符）。

## §5 已接线牙复跑 ＋ 不变量 ＋ 指纹位移（全部现取，原样）
```
ts=2026-09-28T22:58:21.420+0800  SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203 sh=114 py=89 diag=76 allow=0
ts=2026-09-28T22:58:21.4xx+0800  PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=114 sites=100 hit=0 low=10 diag=5 safe=85 runs=12
ts=2026-09-28T22:59:15.970+0800  HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none
ts=2026-09-28T23:00:15.462+0800  STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62（唯一 NOINFO＝`FrameProbe-frame rc=2` 约定）
ts=2026-09-28T22:58:21.4xx+0800  SSC=PASS lines=13 keys=13 cmp=IDENTICAL
不变量（写后现取）：`^run_step "` ＝ **62**｜coverage ＝ **234**｜`# VERIFYALL-STEPS-DECL: 62 gen=#81`｜`run_step "FP-MANIFEST-TEETH" … --expect 234` ⇒ **四条全部未变**
指纹位移：`inputs_fp` `0e64a80b99b483b15b009cf367c2f73152e604e2e632c3f145c977cbf2f852eb` → **`0581db21fe4cf1a292e5b54195932bd346fe79ef138807eb4bc34c20869553b2`**（判据件在覆盖面内 ⇒ 位移**预期**）
纪律 28 同趟：`HANDOFF-NEXT.md` 追写 **`cell=#1` 一行**（`ts=2026-09-28T22:59:11.999+0800`，值＝上面的新 `fp`；纯 `>>` 追加、`591 → 592` 行、`numstat 1 0`、644）⇒ `HANDOFF_MV` 由 `DIVERGED … #1:covered-file-changed-since-ts` 回 **`PASS mismatch=0`**
哨兵：**不需要重写**（本件**未**动哨兵）—— 哨兵第 2 行 `FP=` 载的是 **`BRIDGE_SRC_FP`**（现取 `d697b1e10ff48881` ＝ 基线件 `BRIDGE_SRC_FP` 现取值；**不是** `inputs_fp`），本件未动桥源 ⇒ 值不变；`SENTINEL-SPEC=PASS cmp=IDENTICAL`、两枚 `cmp IDENTICAL`
模式守恒（两口径成对）：本趟四件 `stat -c %a` 全 `644`；`git ls-files -s` 的已跟踪件全 `100644`（新载体待队长入库时定 `100644`）
```

## §6 立号 `D-G189` ＋ 同趟 `--emit`（第 ⑥ 条成立）
**判定：值得立号**（理由＝这是**判据面机制缺陷**、可复现、有**常驻红**后果、且与既有的 `D-G183`（扫描域**过宽**⇒假红）**互为对偶**（本条是**取值域过窄**））。
```
samples/WpfFeatureProbe/KNOWN-DEFECTS.md：`fa2b6f9d8cbf7b3e`／3858 行 → **`8cfc9315ded2a65a`／3870 行**（`numstat 12 0`，纯追加；新条目头现取 `### 🆕 **`D-G189`** …`）
build/MilBridge/tools/defect-registry-declared.tsv：`9b59cdfb0232b54d`／233 行 → **`5c459198c6b5258c`**／234 行（`numstat 3 2`：`# DECL-GEN` 与 `# DECL-ANCHORS`（`KD=fa2b6f9d8cbf7b3e`→`8cfc9315ded2a65a`）同趟刷新 ＋ 新 `ID\tD-G189\treq=KD\tpresent=KD`）
同趟命令：`bash build/MilBridge/tools/defect-registry-check.sh --emit > <tmp>` ＋ `chmod 644` ＋ `temp+rename`（**两次**：先 `ts=22:59:50`，最后一次在 `ROUTES` 之后 `ts=23:01:13`）
DEFREG 两遍（最后一次 emit 之后）：`rc=0`／`DEFREG=PASS declared=224 route_ids=224` ＋ `DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`（`ts=23:01:2x`）
REPORTID：`REPORTID=PASS files=230 ids=2188 declared=224 glob=build/MilBridge/*report*.md`（`ts=23:01:24.820`）
```
`D-G189` 逐字要点：**机理**＝判据对一个**观测面**的取值域作了**未声明的假设**（`entry=` 恒为 PTS 名），而真实取值域由取值者决定 ⇒ 域一扩张就把**合法状态**读成**常驻红**；**口径句（永久）**＝「判据引用一个观测量之前，必须把它『由谁产生、取值域是什么』写进判据件；**域是取值者决定的**，不是判据想当然的」；**修法**＝两级内容锚的域分格；**同族不合并**＝`D-G183`（对偶）∥`D-G142`∥`D-G184`。

## §7 翻册（`docs/ROUTES.md` §15af，dated 只增不改）＋ 队长追加三条
```
docs/ROUTES.md：`ccacfb1a72a05c74`／855 行 → **`bd5197bd7a39e97a`／862 行**（`numstat 7 0`；删行现取 **0**）
```
- **㈠ 在册计数冲突（本席现取自算，未照抄 `t75`）**：被更正句（内容锚）＝ `🆕 **在册数已现算（主控 2026-09-26，只读车道 W174A）**` 那条 bullet 的「**工具口径 100**（… 66 `Fs*`／19 `Lo*`／6 `Nl*`／4 文本／5 `*Wrapper`）」。**现取命令**：`python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier all` ⇒ `awk '$1=="PresentationNative_cor3.dll"{print $2}' | LC_ALL=C sort`。**现取读数**（`ts=2026-09-28T23:00:36.995+0800`）：**工具口径 99** ＝ 66 `Fs*` ＋ **18** `Lo*` ＋ 6 `Nl*` ＋ 4 文本 ＋ 5 `*Wrapper`；**工具 sha16 `b07cce3f2e7cf51a` 在册与现取逐位相同** ⇒ **旧读数**，非工具变更；位移只一处（`Lo* 19→18`），`LoCreateContext` **不在**现取缺口表内 ⇒ 与在册 `TASK-0302` 增量**方向一致**（**归因标注：方向推断，本席未复算旧树**）。**同族第二处**（逐字点名）：`§13` `TASK-0302` 行尾「…**工具口径 100**，`so16=6825dd7071387a46`、`exports=556`」⇒ 现取 `so16` **`2a5165700a8c8579`**、`nm -D --defined-only` ＝ **557** ⇒ 两值皆旧（`ts=23:00:47.607`）。
- **㈡ 门禁要读的具名读数尚在仓外**：判据默认读的在册证据件——**内容锚**＝ `verify-all.sh` 里 `run_step "PTS-PAGES" … --legs "$PTS_EVIDENCE_DIR"` 那一行的变量（默认目录 `build/MilBridge/tests/PtsPagesProbe/evidence/`，判据侧取其中的 `app_g1.log`）——现取 sha16 **`cb0a3e5510b07790`**、`entry=` 面仍是 **`unknown`×2** ⇒ **这一趟门禁仍读到 `UNNAMED`**；**在册证据未换代**（本件**未动**证据目录，换代另派单）。
- **㈢ W8 增量序列只作索引指向**：`LoSetDoc` → `LoSetBreaking` → `LoAcquirePenaltyModule`（已导出 ⇒ 不用补）→ `PTS.CreateDocContext`（台账**真非零**）；**全表 22 条在 `build/MilBridge/P1-ls-family-recon.md`**（`t75`，全文 sha16 `edb30a6fa7366547`）——本节**只指向、不复制**。

## §8 自伤（如实记）＋ 边界自证 ＋ `NOINFO`（具名）
- **本席本趟自己踩了 `D-G186` 族实例**：域归因的两条 `echo` 串里用了**反引号**（`` `DllImport…EntryPoint=` ``／`` `decl=` ``），在**双引号**内被命令替换 ⇒ `stderr` 出现 `… 行 220: DllImport…EntryPoint=: 未找到命令`、串里该段被吃掉（`rc` 仍 `1`／`0`，`bash -n` **看不见**）。**当场改掉**（反引号 → 「」／裸词）并复跑；`SHELL_QUOTE_TRAP=PASS traps=0` 与 `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0` 为改后读数。
- **边界自证**：本趟实写 **5 件** ＝ 写域 4 件（判据件／`ROUTES.md`／`KNOWN-DEFECTS.md`／`declared.tsv` 同趟 `--emit`）＋ 载体 1 件（本件）；另按**纪律 28 契约**追写 `HANDOFF-NEXT.md` 的 `cell=#1` **一行**。**未**改 `verify-all.sh`／`build/close-wave.sh`／`build/PresentationFramework.Linux/**`／`src/**`／`build/MilBridge/arm-logs/**`／两枚哨兵；**未**跑整趟门禁、**未**构建、**未**跑应用腿、**未**占显示位、**未** `git add/commit/push`。
- **`NOINFO`（具名，既不算绿也不算红）**：① **修后现树仍 `PTS_GUARD=FAIL`**（唯一红＝`native-ledger-absent(PTS_GAP n=0)`，属另一族，未处置）⇒ 本件**不声称**该步绿；② **门禁里 `PTS-PAGES` 的具名读数未到位**（在册证据 `entry=unknown`，见 §7㈡）；③ 本件**未**跑整趟门禁 ⇒ 端到端绿未验；④ 未复算旧树 ⇒ §7㈠ 的 `Lo* 19→18` 归因只是**方向推断**。
**本件自证**：`head -n -1 build/MilBridge/P1-g10-domain-report.md | sha256sum | cut -c1-16` ＝ `f8173b86e29da083`（本行系末行；上列各节即被哈希的全文）
