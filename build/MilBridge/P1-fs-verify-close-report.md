# P1-FS-VERIFY-CLOSE（`t128` · W50：`t126` 余项关账 —— `F-4` 取数代际口径 ＋ `F-3` 收尾待办 ＋ `F-1`/`F-2` 协作记录）

> **射程（队长 `t128` 中途收窄；本席照办并如实记）**：`build/MilBridge/P1-fs-destroy-report.md` 的**内容改动权在件主 runner**（该件首行 `# P1-W47 · 销毁路径两条同伴实现（…）`、台账落 `~/t123-runner/**`、已由队长提交 `38541c1`）⇒ 本席**一字未动**该件：写前像 ＝ **`d736949f3f9a3cd3`／198 行／mtime `2026-09-29 13:10:50.249117055 +0800`**，本席收工逐位相同（`sha256sum | cut -c1-16` 现取仍 `d736949f3f9a3cd3`）⇒ **无字节可回退**（本席从未写它）。本件只做三件：① `F-4` 两个前置值的**取数代际**口径（落本件）；② `F-3` 收尾**待办登记**（不执行）；③ `docs/ROUTES.md §15af` 里给 `F-1`／`F-2` 各一行**协作记录**（件主 ＝ runner）。
> **仪器**：`git show/log/rev-list`（只读）＋ `sha256sum`／`grep`／`cmp`／`wc`＋已接线牙（`handoff-machine-values-check.sh`／`pts-gap-count-check.sh --check`／`sentinel-spec-check.sh`／`static-jaws-check.sh`／`report-id-domain-check.sh`／`defect-registry-check.sh`／`shell-quote-trap-check.sh`／`pipefail-sigpipe-check.sh`）＋ `infp.sh`。**零构建、零跑腿、零显示位、零整趟门禁、零 git 写、零改 `src/**`／`tools/**`／`tests/**`／件主载体**。

## §1 `F-4①`：`ENFE_TOTAL` 的**代际表**（口径 ＝ 某一份日志里 `entry point named '<名>'` 的**行数**）

| 读数 | 属于哪一代 | 本席现取 | 取数命令（同源） |
|---|---|---|---|
| **1152** | 被复核件 `§3.1` 的 `before`（`t119`／`t122` 那一代） | **载体不可达 ⇒ `NOINFO`**：仓内该路径**历史 6 版**无 1152（`057d08a`＝**1081**、`710ba37`＝0、`28b04be`＝0、`f1aedbe`＝0、`e528f53`＝0、`4d87912`＝0）；仓外 12 件无 1152（`~/w67-work/logs/evidence/app_g1.log`＝**1085**、其余 `legs*` 全 0、`~/t123-runner/bak/run-app_g1.log`＝**1**） | `git rev-list -n 6 38541c1 -- <日志>` 逐版 `git show <rev>:… \| grep -c "entry point named '"`；仓外 `grep -c` 同串 |
| **1081** | **审查面**（`38541c1`）**及其父**（`38541c1^`） | **两版同值 1081**（＝`FsCreatePageBottomless` 1080 ＋ `FsCreatePageFinite` 1，与复核者 `t126` 一致） | 同上 |
| **1102** | 被复核件 `§3.1` 的 `after`（审查面那趟**真腿**日志） | 复核者 `t126` 现取；**本席未复算其载体**（不在本席读写域的必要面）⇒ 本件**只引不复算**（如实标注） | 复核者载体 `P1-fs-query-verify.md` §A |
| **1085** | **本席收工时刻的工作树现值证据日志**（`mtime 13:16:56`） | 现取 1085 | `grep -c "entry point named '" build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` |
| **1** | **崩溃代**（车道 `~/t123-runner/bak/run-app_g1.log`，`mtime 11:36:37`） | 现取 1（同件 `FailFast` ＝ 4） | `grep -c` 同串 |

**口径句（逐字，防后人当恒真）**：`ENFE before` **不是恒真量**，它是「**某一代**日志里 `entry point named '<名>'` 的**行数**」⇒ 引用**必须**带**载体路径 ＋ `ts` ＋ 代际**（件 `sha256` 或 `.so` 世代）；**同一文件名在不同代之间被复写**（本席现取：`~/w67-work/logs/*/app_g1.log` 的同名车道件今为 1085／0，历史 1152 那一代**已被覆盖**）⇒ **跨代相减无意义**；代差可达 3 个数量级（**1 ↔ 1152**）。**今天可复算的是 1085（工作树现值日志）**；`1152` 记 **`NOINFO(载体被覆盖/不可达)`**。

## §2 `F-4②`：`PTSGAP` 残留**条数**的时刻性（同口径：`LIVE` 五值与各 route 件**现值位**之差）

| 时刻 / 来源 | 现取读数 |
|---|---|
| `t123` 落盘（`13:10`，被复核件 `§6`） | `SITE-DRIFT docs/ROUTES.md impl want=84 got=87`（件内写「**唯一残留**」） |
| 复核者 `t126` 窗口（`13:2x`，漂移后） | **4 条**：`tool 93→91`／`ops 81→79`／`impl 84→82`／`so16 e08167ee…→bbd249a6…` |
| **本席 `t128` 第一次现取**（`13:1x`，`rc=1`） | **1 条**：`SITE-DRIFT docs/ROUTES.md impl want=82 got=87`；`PTSGAP=FAIL tool=91 dead=11 artifact=1 ops=79 impl=82 so16=e9b7def842982920 exports=591` |
| **本席 `t128` 第二次现取**（`13:2x`，同一棵树、相隔数分钟） | **18 条**：`docs/ROUTES.md` ×9（`tool want=90 got=91`×2／`ops want=78 got=79`×3／`impl want=81 got=82`×3／`impl want=81 got=87`×1）＋ `KNOWN-DEFECTS.md tool`／`README.md ops,impl`／`HANDOFF-NEXT.md ops,impl`／`win32_classification.c ops,impl`／`unimplemented.md tool,ops`；`LIVE tool=90 dead=11 artifact=1 ops=78 impl=81 so16=a4bf2c47f8efb521 exports=594`（＝`t127` 又落一代） |

**口径句（逐字）**：残留**条数**＝`LIVE` 与各 route 件现值位之差的**时刻函数** ⇒ 在飞换代期**同一棵树的不同时刻给出 1／4／1** ⇒ 「**唯一**残留」只对**它被写下那一刻**成立，**不是**该面的稳定属性。**机制（现取，逐字）**：`docs/ROUTES.md:247` 那行含「实现口径 87 条」，而牙的历史行判别 `line_is_hist()` **只认两种世代锚**（`.<…>so <16hex>` 与 `<N> 导出`）⇒ 该行被判**现值位** ⇒ `impl` 位报 `want=82 got=87`。**本席未改牙、未改该行**（两者都在本席写域外）。**本席本趟对 `docs/ROUTES.md` 的追加经成对实证「零扰动」**：用牙自己的 `SITES` 环境覆盖（该覆盖是牙内部就有的支路，现取 `SITES=${SITES:-$R}`）对**同一份件的 pre-append 副本**与**post-append 现件**各跑一次 ⇒ `docs/ROUTES.md` 的 `SITE-DRIFT` 命中**两边同为 9 条、逐条逐字相同**，且检查器自己的**六条模式**在两份件上的命中数**逐条相同**（`2/1/1/1/3/1`）⇒ 本席那 9 行**没有**引入任何现值位候选（`1 → 18` 的增量**全**来自 `LIVE` 在他者换代中前移）。**本席 `t124` 对 `docs/ROUTES.md` 的追加亦与之无关**（现取：`grep -c '实现口径' ~/w281-scribe/t124/append-routes.md` ＝ **0**）。

## §3 `F-3` 收尾待办（**只登记、不执行**）

- **待办（逐字）**：`t127` 落定后，在**同一代**上**一次性**重取对齐三件：① `bash ~/w153a/bin/infp.sh fp` ⇒ `build/MilBridge/HANDOFF-NEXT.md` EOF 纯 `>>` 追写 `cell=#1`；② `inputs_fp`；③ 两旗标件的 `WIN32SHIM`（本席现取该件共 13 键）。**归口 ＝ 队长收尾动作**（本件不执行）。
- **为什么现在不该对齐（现取证据：同一窗口内三重漂移）**：① 复核者窗口 `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ `f72fcf94d1ad245e`；② 本席窗口同件 ＝ **`8a901c31c7343549`**、`.so` ＝ **`e9b7def842982920`**、`exports.txt` ＝ **591**（`mtime 13:2x`）；③ `HANDOFF-MV` 在本席窗口内**先 `DIVERGED` 后 `PASS`**：本席**第一次**现取（窗口前段）＝ `HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=7 manual=1 mismatch=1 reasons=,#1:covered-file-changed-since-ts`（`in-repo=54aebf1d…`／`live=8119466d…`），随后 `build/MilBridge/HANDOFF-NEXT.md` 里出现**他者**追写的 `cell=#1`（`ts=2026-09-29T13:17:47.019447828+0800`，现值 `8119466d130b805f36846e2be5d466a9809f6e31d0e0425e7bb36d968b5c9619`），本席**第二次**现取 ⇒ `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`。⇒ **在飞漂移此刻仍在继续**（`13:10:50` 登记 `54aebf1d` ⇒ `13:14:17` 源件被改 ⇒ `13:17:47` 又被登记 `8119466d`），**现在对齐 ⇒ 下一分钟即再断**（`cell=#1` 会立刻报 `covered-file-changed-since-ts`）。⇒ 本席**只登记不执行**，并把两次读数与三个时标如实存证。
- **一个可核锚（供收尾人）**：判「漂移是否已停」的现成读数 ＝ `bash build/MilBridge/tools/handoff-machine-values-check.sh`（`HANDOFF_MV=PASS` ⇒ 登记值与现场同代）＋ `bash ~/w153a/bin/infp.sh fp` **连取两次**（两值相同 ⇒ 该窗口内无覆盖面内写者）。**本席未执行对齐**。**加一重（本席收工前现取）**：`13:22:29.286831104+0800` 他者**又**追写一条 `cell=#1`（现值 `198563b4dcb4e1eb…`）；本席在该条**之前**跑牙读 `DIVERGED`、在该条**之后**再跑读 **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`** ⇒ 同一窗口内该格 **`DIVERGED → PASS → DIVERGED → PASS` 往复**；同时现盘 `.so` 已到 **`a4bf2c47f8efb521`／`exports` 594**（较本席上一次 `e9b7def842982920`／591 又一代）、`win32_pts.c e4a091395a6cf63c`。⇒ 「现在不该对齐」的举证再加一重。

## §4 `F-1`／`F-2` 协作记录（**件主 ＝ runner**；本席未代改其件）

- **`F-1`**：件主待办 ＝ 把 `build/MilBridge/P1-fs-destroy-report.md:198` 的**字面 `PLACEHOLDER`** 填成真值。本席**独立现算**（同口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ **`cf6f381b985b0d33`** ⇒ 与复核者 `t126` 自算值**逐位相同** ✓（两方独立、同口径）。**注意口径边界**：该值只在**「`:198` 是末行」**的版式下成立；**若任何人在其后追加内容**，正确填值随版式而变（本席未追加、该件现仍 198 行／`d736949f3f9a3cd3`）。
- **`F-2`**：件主待办 ＝ 件内 `§7` 的机读行写「`handoff-machine-values-check.sh` 读数**见 §8 末**」，而**该读数在件内不存在**（本席现取：`grep -c 'HANDOFF-MV\|HANDOFF_MV'` 于该件 ＝ **0**；`§8` 标题 ＝ 边界遵守自证）＋ **该牙今天不是 `PASS`**（本席窗口内先 `DIVERGED`、他者登记后 `PASS`，见 §3）⇒ 「四不变量全绿」的**读法不成立**，须由件主按 `dated` 更正（原文一字不删）。**本席给件主的两条现成读数**（免它再跑）：`HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=7 manual=1 mismatch=1 reasons=,#1:covered-file-changed-since-ts`（`in-repo=54aebf1d7c96d10513b4e609272f50a16dc577c291004cfa8fe40802dc44e96f`／`live=8119466d130b805f36846e2be5d466a9809f6e31d0e0425e7bb36d968b5c9619`，本席第一次现取）与 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（本席第二次现取，`13:17:47` 登记之后）。
- **件主已落地（本席窗口内现取，`13:20:09`）**：`P1-fs-destroy-report.md` 由 **198 行／`d736949f3f9a3cd3`** 变为 **199 行／`c5ef9d8092dca770`** —— ① 末行 `PLACEHOLDER` 已填成 **`e0f529e5c35297c7`**（`grep -c PLACEHOLDER` 现取 ＝ **0**）；② `§7` 落空指针旁**新增一条 `dated` 更正行**（原行原文一字未删；`git diff --numstat` 现取 `2 1`）。**本席独立复核**（同口径 `head -n -1 | sha256sum | cut -c1-16`）＝ **`e0f529e5c35297c7`** ⇒ 与件主自填值**逐位相同** ✓。⚠️ **本席先前手算的 `cf6f381b985b0d33` 只在「`:198` 是末行」的版式下成立**；件主插入更正行后版式已变、正确值随之变 ⇒ 这正是 `F-4` 族「读数随代际/版式而变」的又一实例（**不是**任一方算错）。
- **协作记录已入翻册**：`docs/ROUTES.md §15af` 的 `t128` 索引块给 `F-1`／`F-2` 各一行「**由件主 runner 处理**」，避免出现「没人认领」的空档。

## §5 牙读数（**现取 rc**；仓根 `feat-Linux`）

| 牙 | rc | 读数（逐字要点） | 归因 |
|---|---|---|---|
| `handoff-machine-values-check.sh` | 1 → 0 | 第一次：`HANDOFF_MV=DIVERGED … mismatch=1 reasons=,#1:covered-file-changed-since-ts`；第二次（他者 `13:17:47` 登记后）：`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none` | **在飞写者改覆盖面内件**（本席零写覆盖面内件） |
| `pts-gap-count-check.sh --check` | 1 | 第一次：`PTSGAP=FAIL`；DRIFT **1**（`SITE-DRIFT docs/ROUTES.md impl want=82 got=87`；`LIVE tool=91 ops=79 impl=82 so16=e9b7def842982920 exports=591`）。第二次（数分钟后、他者又落一代）：DRIFT **18**（`docs/ROUTES.md` ×9 ＋ 另 5 件共 9；`LIVE tool=90 ops=78 impl=81 so16=a4bf2c47f8efb521 exports=594`）。**另有成对实证**：用 `SITES` 覆盖跑 pre/post 两版 `docs/ROUTES.md` ⇒ 该件 DRIFT **同为 9 条、逐条相同** ⇒ 本席追加零扰动 | **他者项**（在飞换代；机制与举证见 §2） |
| `sentinel-spec-check.sh` | 0 | `SSC_LINES/KEYSET/CR/BLANK/EMPTY` 两哨兵全 `PASS`；`SSC_VALUE=PASS key=SHA/PC/PF/WB/…`（13 键逐键在位） | 未动哨兵 |
| `static-jaws-check.sh` | 0 | `STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62` | 本趟未改覆盖面内件 ⇒ 无 `HANDOFF-MV` HIT |
| `report-id-domain-check.sh` | 0 | `REPORTID=PASS` | 本件与翻册追加未引入未登记编号 |
| `defect-registry-check.sh` | 0 | `DEFREG=PASS`；`DEFREG_DECLDRIFT=1 keys=KD`（**只诊断、不判红**，成因＝route 件改后未装盘，口径见 `t124` 段） | 他者项 |
| `shell-quote-trap-check.sh` | 0 | `SHELL_QUOTE_TRAP=PASS canary=OK` | 本趟未写 shell 件 |
| `pipefail-sigpipe-check.sh` | 0 | `PIPEFAIL_SIGPIPE=PASS` | 同上 |
| `pts-gap-count-check.sh --selftest` | （未跑） | — | 本趟未改牙；省机时（不作绿） |

## §6 哨兵与「命令输出 vs 哨兵内容」（现取）

- **两旗标件**：`cmp -s /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；13 键现取含 **`WIN32SHIM=e08167eef3c4a14e`**（＝**审查面 `38541c1` 那一代**的 `.so`）。
- **与现盘不一致（如实报、未自写）**：本席窗口现盘 `.so` ＝ **`e9b7def842982920`**（`t127` 在飞换代）⇒ 哨兵**陈旧**；**写哨兵是队长的动作**，本席未动。
- **`WPW=PASS sha16=f71df705d868d80a`**：现取 `~/wfp-runs/bridge-frozen.flag` **无 `WPW` 键**（`grep -c '^WPW='` ＝ **0**）；该串在全仓现取**只命中复核者载体** `build/MilBridge/P1-fs-query-verify.md`（属**引述**）⇒ **按「（哨兵重写）命令的输出行」归类，不是哨兵字段内容**。

## §7 边界与不变量自证

- **写域（收窄后）**：`build/MilBridge/P1-fs-verify-close-report.md`（本件新建）＋ `docs/ROUTES.md §15af`（dated 追加）。**未改**：`build/MilBridge/P1-fs-destroy-report.md`（**件主写域**；写前像 `d736949f3f9a3cd3`／198 行，本席收工逐位相同）、`src/**`（`t127` 在动）、`build/MilBridge/tools/**`、`build/MilBridge/tests/PtsPagesProbe/**`、`build/PresentationCore.Linux/**`／`build/WindowsBase.Linux/**`、判据件、`verify-all.sh`／`close-wave.sh`／哨兵、`samples/**`。
- **无 `cell=#1`（已现取核算）**：覆盖面 `infp.sh list` ＝ **234** 件；本席候选四件（`P1-fs-destroy-report.md`／`P1-fs-verify-close-report.md`／`docs/ROUTES.md`／`HANDOFF-NEXT.md`）命中 **0** ⇒ 本趟**不改覆盖面内件** ⇒ 按第 `28` 条**无需**追写 `cell=#1`（`HANDOFF-NEXT.md` 本席一字未写：现取 662 行、其末条 `cell=#1` 系**他者** `13:17:47` 所写）。
- **未做项与原因**：① `F-1` 填空／`F-2` 件内更正 ⇒ **件主写域**（队长收窄射程），本席只给现算值与现取读数；② `F-3` 对齐 ⇒ **在飞漂移会立刻再断**（§3 三时标举证），归口队长收尾；③ `pts-gap-count --selftest` 未跑（本趟未改牙）；④ 整趟门禁／构建／跑腿／显示位／`git add|commit|push` ⇒ 派单禁。
- **`docs/ROUTES.md` 的 diff 归因（同窗口有他者并行写，必须分清）**：本席只做**纯追加 11 行**（`t128` 索引块 9 行 ＋ 追记 2 行；现取：文件末尾即本席那两段追记）。`git diff --numstat` 现取 = `19 8`，其中**其余 15 增 8 删属他者**（内容为**现值位数同步**：`TASK-0302`／`TASK-0720`／「在册数已现算」／`§13` 四类行里的数字），**删除行中含本席标记 `t128` 的 ＝ 0**（不变量逐字自证）。**零扰动实证（决定性）**：把本席那 11 行从现件尾部去掉后**再跑牙** ⇒ `docs/ROUTES.md` 的 `SITE-DRIFT` 集合**逐条不变**（两版同为 **1** 条：`impl want=81 got=87`）⇒ 本席追加**没有**引入任何现值位候选。
- **不变量**：本趟**零**改代码/判据/哨兵/生成件；「只增不改」在翻册侧由 `git diff --numstat` 与「删除行数 ＝ 0」现取自证（本件 §5 与 §7 的现取读数 ＋ `git diff --numstat docs/ROUTES.md` ＝ `9 0`、`git diff -U0 … | grep -c '^-[^-]'` ＝ **0**）。

**本件自证**：`head -n -1 build/MilBridge/P1-fs-verify-close-report.md | sha256sum | cut -c1-16` ＝ e7567a2796ebbc5c（末行不计入自身）
