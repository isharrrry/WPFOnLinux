# P1-W2 复核关账报告（`t25` · W1／W2／W3 三条 low 收口）

> **本件开篇 ＝ 判据**（写在任何落仓之前）：判据行先落、证据行后补，一律 `⏪` 起头 ＋ dated 读时。
> 判词载体 ＝ `build/MilBridge/P1-w2-verify.md`（`246c513c4c429b9d`／325 行，**只读、未改**）。写者 `scribe`；工作根 `$N`；分支 `feat-Linux`。
> 纪律：写前 `stat -c %h` 须 `==1`；`cp -p` 备份在任何写之前；落仓一律 `temp + rename`；**只增不改**；`NOINFO` 一律具名。

## §0 判据（先写 · 逐条可现算）

- ⏪ **C1（W1）**：`build/MilBridge/P1-w2-report.md` 上落 dated 追加，列出**15 件**（13 改 ＋ 2 新建）**改后 sha16 全表**；值由**本席现取自算**（**不照抄** `t15` §3）⇒ 与 `t15` §3 表**逐位对拍**并给结论；若不同 ⇒ **点名并给两读数**。追加后须给该报告**新口径** `head -n -1` 值（原自报 `e37f0270a525e815` 是**追加前**口径，原文保留）。
- ⏪ **C2（W2·号）**：`D-G182` **未被占用**（改前 `grep -c` 在三件 route 件上命中 `0`）；`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 按**同册体例**（`### 🆕` ＋ 现象／根因／机器证／判据／🔴 口径句／两极化／边界／同族）成条，并**如实记「由 `t15` 发现、队长配号」**。
- ⏪ **C3（W2·修）**：`pkg-src-retiredpath-check.sh` 在 `tree` 面**任一目录缺席** ⇒ `rc=1` 且**点名缺哪个**（`reason=tree-dir-missing dirs=…`）；**不许** `NOINFO`、**不许**空 `path=`；三目录齐 ⇒ 判定路径与改前**一致**；`paths` 面语义不变（清单缺席仍 `NOINFO rc=3`）。
- ⏪ **C4（W2·两极）**：**真跑**三条腿 —— ① 沙箱**只建 `build/`** ⇒ **必红并点名 `tests`／`src`**；② 三目录齐 ＋ 语料含针 ⇒ 照常 `FAIL` 点名件:行；③ 三目录齐 ＋ 语料干净 ⇒ `PASS`；`--selftest` 全绿且 `cases` 只增不减。
- ⏪ **C5（同趟 `--emit`）**：`defect-registry-declared.tsv` 在 **`KD` 编辑之后同趟**重发；除 `# DECL-GEN` 行外与现场**逐字节可比**（`cmp` 只差那一行）；`declared` 恰 `+1`。
- ⏪ **C6（指纹位移逐件归因）**：入口／出口各取 `inputs_fp` 与覆盖面件数；**逐件**归因位移（`in-list` 逐个现取），并核 `[42]` 的 `--expect` 是否需同趟改（**本件不改** `verify-all.sh`／`close-wave.sh`）。
- ⏪ **C7（W3）**：`P1-tail-scout.md` 上落 dated 追加 —— ① 点名**同件两处打架**（正文 vs §4 分波表）并给**两处原文**；② 声明**以正文那句为准**；③ 如实记**责任链 ＝ 侦察 §4 → 队长 → 被 `t14` 如实顶回**（`t14` 已点名、处置正确）。
- ⏪ **C8（边界）**：越域为零（`porcelain` 逐行归属）；**未** `git add/commit/push`；未跑整波／门禁／构建／应用／显示位；临时件残留 `0`；`NOINFO` 具名。

## §1 落仓清单（`t25`，证据行 dated 读时 2026-09-28T16:22:03+0800）

⏪ 六件（写前 `stat -c %h` 全 `==1`；`cp -p` 备份 `~/w281-scribe/bak/*.pre-t25` 取在**任何写之前**；落仓一律 `temp + rename`）：
⏪ `build/MilBridge/tools/pkg-src-retiredpath-check.sh`　`60009734108344bd` → **`231ae30326a4fb31`**（279 → 312 行；`bash -n` **SYNTAX-OK**；`numstat` **`34 1`**：`1` 删＝被替换的那一行判词）
⏪ `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`　`242d8322b7a38ede` → **`540de62c051f0875`**（3711 → 3722 行；`numstat` **`11 0`**；`^-[^-]` = **0**）
⏪ `build/MilBridge/tools/defect-registry-declared.tsv`　`d9db8ed740145643` → **`5559af5443888348`**（225 → 226 行；`numstat` **`3 2`**：`2` 删＝机械重生成的两行头）
⏪ `build/MilBridge/P1-w2-report.md`　`80e1583d2680b382` → 全文现取见 §2（136 → 158 行；`numstat` **`22 0`**）
⏪ `build/MilBridge/P1-tail-scout.md`　`493808af2699c40a` → 全文现取见 §6（569 → 575 行；`numstat` **`6 0`**）
⏪ `build/MilBridge/P1-w2-close-report.md`（**新建**）＝ 本件；判据段先落（`16` 行／`c4a89891de786e63` 为**判据段**的 sha16，**不是**全文值）
⏪ **只增不改自证（跨三件三法）**：`P1-w2-report.md`／`P1-tail-scout.md`／`KNOWN-DEFECTS.md` **删行 `0`** 且**原文前缀逐字节 `cmp` = IDENTICAL**（`head -n <改前行数>` vs 备份）；牙与 `declared.tsv` 的删行**逐行可归因**于修法与机械重生成（见上），**文档面零删行**。

## §2 C1（W1）证据：15 件改后 sha16 全表

⏪ 落点＝`build/MilBridge/P1-w2-report.md` EOF dated 追加（**22** 行，末行携带**自身口径**）。
⏪ **本席现取自算**（**未照抄** `t15` §3）15 格 ⇒ 与 `t15` §3 表**逐位相同、无一格不同**：`b36728870f822a23`／`2001427e88b7f709`／`c78ed88fc1fd34f4`／`b6d00269cf6f6aad`／`52f0ab739aaacf3b`／`f536e535d6903227`／`a23b7476833da140`／`ca6f1bea560f2326`／`1f719638830afdde`／`a70aeb1d988ebc9e`／`60009734108344bd`／`7074a774739efaf2`／`19496f3615ccb45a`／`ceecddcccda8521f`／`80e1583d2680b382`。
⏪ `inFP` 现取：第 `10`–`13` 件 `=1`，其余 `=0`（与 `t14`／`t15` 的「4 件动因」逐件一致）。
⏪ **载体两格复算**：`P1-w2-criteria.md` `ceecddcccda8521f`（相同）；`P1-w2-report.md` **追加前** `head -n -1` `e37f0270a525e815`／`136` 行（相同）。
⏪ **追加后口径**：`P1-w2-report.md` `head -n -1` ＝ **`44f578c12a64431b`**（现算，末行＝携带该值那行 ⇒ 自洽）；**全文**＝ **`6b7d1a12f4e8e1b6`**（截 16 位，见 §7 现算行）。⇒ 引用其 sha16**必须写明时刻**。

## §3 C2／C5 证据：立号 `D-G182` ＋ 同趟 `--emit`

⏪ **立号占用检查（改前，逐件现取）**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` **`0`**／`docs/CURRENT-STATE.md` **`0`**／`build/MilBridge/HANDOFF-NEXT.md` **`0`**／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **`0`**；`declared.tsv` `ID` 行**数值序最大号** ＝ **`181`** ⇒ **`D-G182` 未被占用** ✓（全仓唯一命中是 `.agent-teams/…/team.json` 里的**本任务描述**本身）。
⏪ **条目形态**：`^### 🆕 **\`D-G182\`**` 命中 **`1`**；八段齐（现象／根因／机器证三条／判据三条／🔴 口径句逐字／两极化／边界／同族不合并）；**边界①如实记「由 `t15` 发现、队长配号」**。
⏪ **机器证（三条，全部我现取自算）**：① **反侧（改前件）** 只建 `build/` 的沙箱 ⇒ `rc=3`：`RETIREDPATH=NOINFO reason=no-paths-file path=`（**必红腿没被判**）｜② **正侧（改后件）同一沙箱** ⇒ `rc=1`：`RETIREDPATH=FAIL reason=tree-dir-missing dirs=tests,src root=…`｜③ **空 `path=` 面**：改后判词输出**零** `no-paths-file` 命中、**零**空 `path=`（现取 `0`／`0`）。
⏪ **同趟 `--emit`**：`KD` 编辑**之后**执行；表 `225 → 226` 行、`# DECL-GEN` 由 `16:10:49` → **`16:21:20 +0800`**、`# DECL-ANCHORS` 的 `KD=` 由 `242d8322b7a38ede` → **`540de62c051f0875`**（**== KD 现取 sha16**）、新数据行 `ID\tD-G182\treq=KD\tpresent=KD`。
⏪ ⚠️ **具名不对拍（`low`，不改结论；写给复核者）**：派给复核者的「`--emit` 与现场**除 `# DECL-GEN` 外**逐字节相同（`cmp`）」**同趟改了 `KD` 时不成立**：`KD` 变了 ⇒ `# DECL-ANCHORS` 的 `KD=` 锚**必须**同趟跟随，且**必须**多出那一条 `ID` 行 ⇒ 现取差异 **`3` 行**（`DECL-GEN` 时间戳／`DECL-ANCHORS` 的 `KD=` 锚／新增 `ID` 行），**逐行可归因**。同趟性的**正确不变量**是：`KD=` 锚 **==** `KD` 现取 sha16 ∧ 该新号**有** `ID` 行 ∧ `DECLDRIFT=0`。
⏪ **两牙现算**：`DEFREG=PASS declared=217 route_ids=217` ∧ `DECLDRIFT=0 keys=-`；`REPORTID=PASS files=197 ids=2047 declared=217`（`declared` `+1` **100% 归因 `D-G182`**）。

## §4 C3／C4 证据：修法 ＋ 两极化真跑

⏪ **修法（三处，逐处 `grep -c` 断言命中 `1` 后才替换）**：① `run_check()` 加**目录闸**（`tree` 面先检 `build`／`tests`／`src` 三目录，缺则 `rc=1` ＋ `reason=tree-dir-missing dirs=<缺哪些>` ＋ 点名 `root=`）；② 回退 `NOINFO` 的 reason 由 `no-paths-file` 改为 `corpus-unreadable mode=$MODE path=${PATHSFILE:-none}`（**此后不再有空 `path=`**）；③ 件头 rc 表补一行 ＋ 件头 dated 修说明（读时 `2026-09-28T16:20:02+0800`）。
⏪ **`--selftest`**：`RETIREDPATH_SELFTEST=PASS cases=11 pass=11 fail=0`／`rc=0`／**stderr 零行**；`S9`（`tree` 只建 `build/` ⇒ `FAIL` 点名 `tests,src`）／`S10`（三目录齐 ＋ 含针 `.cs` ⇒ `FAIL` 点名 `build/Foo.cs:2`）／`S11`（三目录齐 ＋ 干净 ⇒ `PASS`）三条**新增**，`cases` `8 → 11` **只增不减**。
⏪ **沙箱真跑三条腿**（`~/w281-scribe/sbx-t25`，非 `/tmp`）：① **只建 `build/`** ⇒ `rc=1`：`RETIREDPATH=FAIL reason=tree-dir-missing dirs=tests,src …`｜② **三目录齐 ＋ 语料含针** ⇒ `rc=1`：`RETIREDPATH=FAIL` ＋ `build/Foo.cs:2 kind=code rule=code-retired-path` ＋ `RETIREDPATH_SCAN mode=tree files=1 hits=1 code=1`｜③ **三目录齐 ＋ 干净** ⇒ `rc=0`：`RETIREDPATH=PASS mode=tree files=1 hits=0 code=0`。
⏪ **缺目录三种缺法**（复核者要求）：只缺 `build`／只缺 `tests`／只缺 `src` ⇒ 各 `rc=1` 且分别点名 `dirs=build`／`dirs=tests`／`dirs=src`。
⏪ **判定主路径未变（真树）**：`RETIREDPATH=PASS mode=tree files=567 hits=3 code=0 declared=3 self_skip=1`／`rc=0`（`files` 是**点读数**、随并发写者增长：`t14` 读时 `565`，本席现取 `567` ⇒ **不判不一致**，同 `t15` §4-N6 口径）。

## §5 C6 证据：指纹位移逐件归因

⏪ 入口 `inputs_fp` ＝ `e9f95ec005715b3a7bff1a7bca4b525fafad98068e7a389ad8b9b91b8a9dc5a3`／覆盖面 **`226`**；出口 ＝ **`8c4ce894d04eae7b1c6d253bc5beabb758a9e99f8430b7b1cd17c8d8707bedd3`**／覆盖面 **`226`** ⇒ **件数不变、指纹必移**。
⏪ **逐件归因（现取 `infp.sh list` 逐件 `in-list`）**：`pkg-src-retiredpath-check.sh` **`1`**（**唯一动因**）｜`P1-w2-report.md` **`0`**｜`P1-tail-scout.md` **`0`**｜`KNOWN-DEFECTS.md` **`0`**｜`declared.tsv` **`0`**｜本件 **`0`** ⇒ 位移 **100% 归因于该牙**（表内旧值 `60009734108344bd…` → 新值 `231ae30326a4fb31…`）。
⏪ **`[42]` 是否需同趟改 ⇒ 否**：覆盖面件数 `226 → 226`（件数不变，只换值）⇒ `verify-all.sh` 的 `--expect` **不需**同趟改；实跑独立步 `fp-manifest-step.sh --expect 226` ⇒ `FP_MANIFEST_TEETH=PASS reason=ok files_n=226 declared_expect=226`／`FP_MANIFEST_STEP_RC=0`（**无 `files-n-mismatch`**）。**本件未改** `verify-all.sh`（`600274f130cfe913`）与 `build/close-wave.sh`（`f9a2ee3ee35baff8`）—— 两件 `porcelain` **零行**。

## §6 C7 证据：侦察件路径更正 ＋ 两处打架 ＋ 责任链

⏪ 落点＝`build/MilBridge/P1-tail-scout.md` EOF dated 追加（**6** 行；`numstat` **`6 0`**、原文前缀 `cmp` **IDENTICAL**）。
⏪ **同件两处打架（队长追加，已证实且更精确）**：**正文**（`### W2 ·` 小节「入口（原文照抄）」第 `2` 项）写 **正确**路径 `build/MilBridge/retired-path-provenance.tsv`；**§4 分波表**（行首 `| **W2** |` 那一行）的「改仓件」栏写 **错误**路径 `build/MilBridge/tools/retired-path-provenance.tsv`。（现取行号 `:254`／`:517`，**仅本次有效**。）
⏪ **真件现取**：`build/MilBridge/retired-path-provenance.tsv` **存在**（`2200 B`／mtime `2026-09-27 11:51:43`／sha16 **`10d62946231cc809`**）；`build/MilBridge/tools/` 下 **ABSENT**。⇒ 裁定 **以正文那句为准**。
⏪ **责任链（如实记）**：侦察 **§4 分波表**写错 ⇒ **队长据此路径写进 `t14` 契约的 `inScope`** ⇒ 被 **`t14` 如实顶回**（其报告点名该路径不存在）⇒ 本席同趟在册更正。⇒ **`t14` 处置正确、不计其错**。

## §7 自伤 ／ `NOINFO` ／ 边界

⏪ ⚠️ **本席自伤（如实记，且是复核者点的那个坑的镜像）**：首跑 `--emit` 我用 `EM="$(bash … --emit)"` **捕获 stdout** ⇒ `emit_decl()` 是**打到 stdout、不落盘**的 ⇒ 表**根本没重发**（`# DECL-GEN` 时间戳未变、`D-G182` 行缺席）；**是现算 `diff` 咬住的，不是流程自觉咬住的**。改正＝`> "$D.t25tmp"` ＋ `temp+rename`，复算 `225 → 226` 行、`DECL-GEN` 更新、新行在场。⇒ **「我跑了 `--emit`」≠「表已重发」**；此后一律以 `DECL-GEN` 时间戳 ＋ 新行在场 ＋ `DECLDRIFT=0` 三条现算为准。
⏪ **`NOINFO`（具名）**：① `files=567` 与 `t14` 读时的 `565` 差 `2` ⇒ **点读数随并发写者增长**，本席**未**逐件归因到具体新件（`NOINFO(reason=点读数旁证不足)`），**不影响任何判据**；② **真显示位／应用／构建／整波** 一律**未跑**（派单边界明写）⇒ 不判。
⏪ **边界**：`porcelain` 逐行归属 —— `M` 五件**全部 `inScope`**（`P1-w2-report.md`／`P1-tail-scout.md`／`pkg-src-retiredpath-check.sh`／`KNOWN-DEFECTS.md`／`declared.tsv`）＋ `?? build/MilBridge/P1-w2-close-report.md`（**本席新建**，`inScope`）＋ `?? build/MilBridge/P1-task0201-criteria.md`（**`t7` 的**，未读未改）⇒ **零越域**；临时件残留 **`0`**；暂存区 **`0`**；**未** `git add/commit/push`。**未动** `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/P1-w2-verify.md`（`246c513c4c429b9d` 现取未变）／产品件／基线件。

## §8 结论

⏪ `t15` 点名的三处 `low` **全部关账**：**W1** 15 件改后 sha16 全表（本席自算、与 `t15` §3 逐位相同）｜**W2** 立号 **`D-G182`** 成条 ＋ 牙的目录闸修法 ＋ 两极化真跑（`cases=11 pass=11`）＋ 同趟 `--emit`（`declared` `216 → 217`）｜**W3** 侦察件两处打架点名 ＋ 以正文为准 ＋ 责任链在册。
⏪ **判据未放宽**：`--selftest` 例数 `8 → 11`（只增）；三态语义不变（`NOINFO` 仍不判绿）；`NOINFO` 一律具名；文档面零删行。
⏪ ⏪ **dated 更正（本件自伤，`t25`，读时 2026-09-28T16:22:13+0800；§2 原句**原文保留、一字未删**）**：§2 末行把 `P1-w2-report.md` 的**全文** sha16 写成 `6b7d1a12f4e8e1b6` —— **该值是我写错的自造值、不是任何现取读数**（**无对应现算行**）。**正确值（本件落定时刻现算）＝ `f934e6c8972cfc68`**；同句里 `head -n -1` ＝ `44f578c12a64431b` **成立**。
⏪ 同刻现算旁证：`P1-tail-scout.md` 全文 ＝ `acc7872f7dad220e`／`head -n -1` ＝ `e84ff5e42910f57c`；本件全文见交件消息（末行只携带**自身 `head -n -1`** 口径 ⇒ 全文值不可能自指）。
⏪ **教训（此后一律照此）**：报告里任何 sha16 **先现算、后落笔**；写「见 §X」之前先确认该行**存在**（本件 §7 并**没有**那类现算行 ⇒ 那句指引本身也是错的）。
⏪ 本件自证 sha16（口径＝**末行之前的全文**）＝ `d37c3625e6e2a21c`（末行＝本行）
