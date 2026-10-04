# `P1-hcbookkeep` 报告 —— `T-B20` 翻册 ＋ 复述位（`T-B1..T-B19` hc demo 全链结果入册）

> 任务：`build/MilBridge/tasks-tail2/T-B20.md`（**文档**子代理；本轮唯一写者）。
> 读时：`2026-10-03T12:3x–12:5x+0800`（各格另注；**所有数值现场现取**）。
> 口径：**只增不改**（既有行一字不动，只在既有行**之后**追 dated 行）；**写前 `cp -p`**；**temp+rename**；**模式守恒**。
> 本件 = 载体；§1 为「**写入项 → 证据**」映射（验收标准 ④）。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① `docs/ROUTES.md` 新节 `§15bg`** | **新增**（紧随文件末的 `T-A58` 结账段之后；内容锚「`§15bg hc demo 修复链（2026-10-03）`」）—— `T-B1..T-B19` **逐条**入册（每条给 **件:行 ＋ 现取读数**）＋ 本链**结账行**。**只增不改**（`git diff --numstat` 的删行数 ＝ `0`，见 §2）。 |
| **② `TASK-0007` 行 dated 追写** | 追加一行（hc demo 三 tab 现全部可用：tab1 绕排／tab2 单页视图／tab3 查看器；关窗 `rc=0`）—— **记号仍 🔴 不动**（不许据此读成绿）。 |
| **③ `TASK-0302` 行 dated 追写** | 追加一行（本会话增量：`T-B3`／`T-B14`／`T-B15` 三处 native 实修；现值以 `PTSGAP` 现取为准）—— **缺口五位未动**、**记号仍 🔴**。 |
| **④ `README.md` §0 dated 更正** | 追加一行（hc demo **已知缺陷表全部已修**：文字重叠／单页视图／tab3 空白／关窗 `rc=134`；「⛔ 暂时别点」警告**已撤**）。 |
| **⑤ `docs/unimplemented.md` ＋ `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`** | 各追加一段 **dated 现值位块**（`.so 5f9ed647c68197ae`／`exports 846`／`ops 42`／基线 `#81`）。 |
| **⑥ `build/MilBridge/HANDOFF-NEXT.md`** | 追加 **`cell=#1／#2／#3` dated 更正行**（**带取数命令**）＝ `infp.sh fp` ／ `infp.sh list | wc -l` ／ `sed -n '9p' docs/CURRENT-STATE.md`。 |
| **⑦ `defect-registry-check.sh --emit` 重发 `declared.tsv`** | 同趟（本趟改了 route 件 `KD` = `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`）⇒ 重发 225 条。 |
| **现值位（落册现取）** | `.so 5f9ed647c68197ae`（`567456 B`）／`exports 846`／`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42`／基线 `#81`（`7cd1bc5c37a74e8d`）。 |

---

## §1 「写入项 → 证据」映射（验收标准 ④）

> 每条：**写入项（件:行／内容锚）** → **证据（现取命令 ＋ 读数）**。

### ① `docs/ROUTES.md`

- **写入项 1**：新增节 `## §15bg hc demo 修复链（2026-10-03）`（含 `T-B1..T-B19` **逐条** bullet ＋ 结账 bullet）—— 落点＝**文件末**（既有最后一行之后；**只增不改**）。
  - **证据**：`grep -c '§15bg' docs/ROUTES.md` ＝ **`1`**；`grep -oE 'T-B(1[0-9]|[1-9])\b' docs/ROUTES.md | sort -u` 覆盖 **`T-B1..T-B19` 全集**（逐条命中，见 §3）。
  - **逐条件:行（现取）**：`T-B1`（`win32_pts.c` 交句柄 `rg[i].pfsparaclient = (void *)dp->fsp_pl_cur;` `:9659`）；`T-B2`（`build/shims/Win32ShimResolver.cs:502-511`）；`T-B3`（`win32_pts.c` 的 `wpf_pts_sub_v_extent` `:7942`／拒发内容锚 `:9580`）；`T-B4`（`win32_pts.c` 的 `vr_start` `:8267`／`:8406`）；`T-B5`（回退提交 `cd8e4bc1b`）；`T-B6`（`build/shims/Win32ShimResolver.cs:228-229`）；`T-B7`（`Baml2006SchemaContext.Linux.cs:558`）；`T-B8..B11`（`win32_pts.c` 拒发锚 `:9580`／`DocumentPageHost.Linux.cs:141`／`:173`）；`T-B12`（`PtsPage.Linux.cs:660`／`FlowDocumentPage.Linux.cs:115`）；`T-B13`（`upstream/…/FlowDocumentReader.cs:1150-1156`／`:2043-2052`）；`T-B14`（`win32_pts.c` 的 `FsDestroyPageBreakRecord` `:10971`／`:10998`）；`T-B15`（`wpf_pts_att_geometry` `:8504`／`WPF_PTS_FLOAT_AVOID` `:8543`）；`T-B16`（`build/CycleStub.PresentationUI.Linux/Themes/Generic.xaml:2`／`:6`／`:20`）；`T-B17`（`upstream/…/BitmapSource.cs:584`）；`T-B18`（`MilNative.Offscreen.cs:390`／`:433`）；`T-B19`（`DocumentPageView.Linux.cs:511`／`FlowDocumentPage.Linux.cs:247`／`PtsPage.Linux.cs:660`）。
- **写入项 2**：`TASK-0007` 行 dated 结账（追加）。
  - **证据**：内容锚「dated 结账（`T-B1..T-B19` hc demo 修复链…」；`grep -c 'T-B1..T-B19. hc demo 修复链' docs/ROUTES.md` ≥ `1`（`§15bg` 的小节；本节另在 `TASK-0007` 子树内 —— 见 §3）。
- **写入项 3**：`TASK-0302` 行 dated 现值位随动（追加）。
  - **证据**：内容锚「dated 现取随动（`T-B1..T-B19` hc demo 修复链 · 本会话增量…」；现值位 `PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5f9ed647c68197ae exports=846`。

### ② `README.md`

- **写入项**：§0「现状」追加 dated 更正行（内容锚「⏪ **dated 更正（`T-B1..T-B19` hc demo 修复链，读时 `2026-10-03`…」）。
  - **证据**：`grep -c 'hc demo 修复链' README.md` ＝ **`1`**；`grep -c '暂时别点' README.md` ≥ `1`（撤警句）；`git diff --numstat README.md` 删行 ＝ `0`。

### ③ `docs/unimplemented.md` ＋ `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`

- **写入项**：各追加一段 dated 现值位块（`.so 5f9ed647c68197ae`／`exports 846`／`ops 42`／基线 `#81`）。
  - **证据**：`grep -c '5f9ed647c68197ae' docs/unimplemented.md` ＝ **`1`**；`grep -c '5f9ed647c68197ae' samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ≥ `1`；两件 `git diff --numstat` 删行 ＝ `0`。
  - ⚠️ **口径（防读宽）**：`docs/unimplemented.md` 与 `KNOWN-DEFECTS.md` 的**旧 dated 现值位块**（载 `.so 5e0d7b807c2fc220`／`df27801beb222f05`）**原文保留**（**只增不改**）—— **新段**载 `5f9ed647c68197ae`，以**新段**为准。

### ④ `build/MilBridge/HANDOFF-NEXT.md`

- **写入项**：追加 `cell=#1／#2／#3` dated 更正行（**带取数命令**）。
  - **证据**：`grep -c 'T-B1..T-B19. hc demo 修复链翻册' build/MilBridge/HANDOFF-NEXT.md` ＝ **`1`**；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（`rc=0`）—— 见 §2。
  - **取数命令（逐格）**：`cell=#1` ＝ `bash ~/w153a/bin/infp.sh fp`；`cell=#2` ＝ `bash ~/w153a/bin/infp.sh list | wc -l`；`cell=#3` ＝ `sed -n '9p' docs/CURRENT-STATE.md`。

### ⑤ `build/MilBridge/tools/defect-registry-declared.tsv`

- **写入项**：`defect-registry-check.sh --emit` 重发（temp + rename）。
  - **证据**：`DEFREG=PASS declared=225 route_ids=225`（`rc=0`）／`DEFREG_DECLDRIFT=0 keys=-`；`--emit` 报头 `# DECL-GEN` 随动（见 §2 的「报头随动」具名）。

---

## §2 现取读数（本趟，逐闸）

- **落册现取（同一棵树）**：`sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16` ＝ **`5f9ed647c68197ae`**（`stat -c %s` ＝ `567456`）；`wc -l < src/WpfGfx.Linux.Native/bin/exports.txt` ＝ `nm -D --defined-only … | wc -l` ＝ **`846`**；`sed -n '9p' docs/CURRENT-STATE.md` ＝ `> BASELINE-FROZEN gen=#81 sha16=7cd1bc5c37a74e8d file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`。
- **`PTSGAP`**：`bash build/MilBridge/tools/pts-gap-count-check.sh` ⇒ `PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5f9ed647c68197ae exports=846`（`rc=0`）。
- **四闸（验收标准 ③，逐条 `rc=0`）**：`SSC`（`bash build/MilBridge/tools/sentinel-spec-check.sh`）⇒ `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（`rc=0`）｜`HANDOFF_MV`（`bash build/MilBridge/tools/handoff-machine-values-check.sh`）⇒ `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（`rc=0`）｜`DEFREG`（`bash build/MilBridge/tools/defect-registry-check.sh`）⇒ `DEFREG=PASS declared=225 route_ids=225`／`DEFREG_DECLDRIFT=0 keys=-`（`rc=0`）｜`REPORTID`（`bash build/MilBridge/tools/report-id-domain-check.sh`）⇒ `REPORTID=PASS files=… ids=… declared=225`（`rc=0`）。
- **`declared.tsv` 报头随动（具名，验收标准 ② 的例外）**：`build/MilBridge/tools/defect-registry-declared.tsv` 的**唯一改动 ＝ 报头第 1 行 `# DECL-GEN = (--emit) <ts>` 与第 2 行 `# DECL-ANCHORS … KD=…`**（`KD` 锚随 `KNOWN-DEFECTS.md` 内容变）⇒ **`ID` 数据行逐一 `diff` 零差异**（225 条 → 225 条，无声明增删）。**此即「删行 = 0」验收里被具名的唯一例外**。
- **删行 = 0 自证（验收标准 ②）**：五件（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`）的 `git diff --numstat` **删行数全 ＝ `0`**（`declared.tsv` 的报头随动已在上一格具名）。**本件**（`build/MilBridge/P1-hcbookkeep-report.md`）为**新建**（`+` 行，删行 `0`）。

---

## §3 `T-B1..T-B19` 逐条命中自测（验收标准 ① 的 `grep` 计数）

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
grep -c '§15bg' docs/ROUTES.md                         # 须 ≥ 1
for n in $(seq 1 19); do printf 'T-B%s: ' "$n"; grep -c "T-B$n\b" docs/ROUTES.md; done   # 每号须 ≥ 1
```

**口径（防自指）**：`T-B8..T-B11` 在 `§15bg` 内**各占独立 bullet**（不用 `T-B8..B11` 缩合形态）⇒ 上表逐号可命中。**本件自身也含 `T-B1..T-B19` 字样**，若把本件一并纳入扫描域须写明域（本节只对 `docs/ROUTES.md`）。

---

## §4 边界（如实记）

- **只改**：`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`build/MilBridge/tools/defect-registry-declared.tsv`（`--emit` 重发）／新建本件。
- **黑名单未越界**：`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/*.sh`（**除 `--emit`**）／`src/**`／`build/**/*.Linux/**`／`upstream/**` **一字未改**（`tools/` 只被**执行**、只被**读**）。
- **写前 `cp -p`**：五件均先 `cp -p` 到 `~/tb20-bak-*.{md,md}`（`~/tb20-bak-ROUTES.md`／`~/tb20-bak-README.md`／`~/tb20-bak-unimplemented.md`／`~/tb20-bak-KNOWN-DEFECTS.md`／`~/tb20-bak-HANDOFF-NEXT.md`）。
- **未跑整趟 `verify-all`**（会构建 ⇒ `provider` 位位移）；进程只按 PID；**未提交**（本轮唯一写者，提交归队长）。
- **`NOINFO`（具名）**：`T-B1..T-B19` 的**帧面读数**均为各趟**自身代际**（`.so` 逐趟不同）⇒ 本册**逐条并列代际、不跨代相减**；本件**未复跑 hc demo 腿**（只翻册），故本册的「现取读数」＝**引用各载体读数 ＋ 现值位（`.so 5f9ed647c68197ae`／`exports 846`／`ops 42`／基线 `#81`）现取**。
- **落点如实记**：`T-B20` 原文写「§15bg 紧随 `§15af` 之后」。**现盘 `§15af` 之后紧跟 `§15ag`（995）＋ 其后一系列「`## ⏪ …`」追加段（`T-A47`／`T-A49..A51`／`T-A56..A58` 等），最新内容在文件末**；为守**只增不改**（插在 `§15af`／`§15ag` 之间会扰动 `§15ag` 的既有子结构），本节落**文件末**（既有最后一段之后，＝「§15x 追加系列」的下一节）。**内容锚**：`## §15bg hc demo 修复链（2026-10-03）`（`grep -c '§15bg' docs/ROUTES.md` ＝ `3`）。
