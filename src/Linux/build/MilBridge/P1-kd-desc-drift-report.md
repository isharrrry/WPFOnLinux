# P1-KD-DESC-DRIFT（`t134` · W56：`KNOWN-DEFECTS.md` 描述行三数字错位的 dated 更正 ＋ `src/tests/**` 错位证据出仓 ＋ 同趟 `--emit` 消 `DECLDRIFT`）

> **本席（scribe）只做三件**：① 在 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G70` 段内**追加**一条 dated 更正行（**只增不改**：`t104` 的历史陈述行与其上的历史行**一字未动**）；② 把错位证据整目录 `src/tests/**` **移出仓**（`mv`，保留可回溯，**不 `rm`**）并在 `docs/ROUTES.md §15af` 追一条 dated 索引行；③ 同趟 `--emit`（**temp ＋ rename**）重装 `build/MilBridge/tools/defect-registry-declared.tsv` 并复跑 `DEFREG`。**不碰任何产品件、不碰 `src/WpfGfx.Linux.Native/**`（`runner` 在 `t133` 里改它）、不 `git add/commit/push`。**

## §1 ① `KNOWN-DEFECTS.md` 描述行三数字错位：更正内容与算式（全部本席现取）

**错位事实**（内容锚：描述行 ＝ 以 `dated 并发事件 ＋ 二次恢复（`t104`／scribe，读时 2026-09-29T01:12+0800` 起头那一行；历史行 ＝ 以 `在册数更正（2026-09-24 车道 W154A-PTS 只读盘点` 起头那一行）：

| 取值面 | 工具口径 | 可操作缺口 | 实现口径 | 判定 |
|---|---|---|---|---|
| **`:2257` 历史行**（现盘，**本席未改**） | `97` | `85` | `91` | ＝ `t104` 恢复态 ✓（与自引件 `libwpfwin32.so fc60c34d51fd9247`／`550 导出` 自洽） |
| **描述行 · 工作树版**（现盘 `:2258`） | `90` | `84` | `87` | ✗（头位错） |
| **描述行 · `HEAD` 版**（`git show HEAD:<本件>` 同一条） | `96` | `84` | `87` | ✗（尾位错） |
| **应有值（本席复算）** | **`96`** | **`84`** | **`90`** | 逐项 ＝ 历史行值 − 1 |

**算式与出处（逐条点名）**：`t104` 自己那条恢复行（同段内，本席现取 `:2261`）**逐字**写「改动**恰三处、每处各 −1** ＝ **工具口径 `97 → 96`**、**可操作缺口 `85 → 84`**、**实现口径 `91 → 90`**（`git show --stat b7e38ab -- <本件>` 现取 `1 1` ⇒ 该提交只动了这一行）」；而历史行现盘三个数字 ＝ `97／85／91` ⇒ 逐项 −1 即 **`96／84／90`** ✓（本席复算：`97−1=96`、`85−1=84`、`91−1=90`）。⇒ **两版都不等于应有值，且错的位不同**（工作树错头位 `90≠96`、`HEAD` 错尾位 `87≠90`；中位 `84` 两版都对）。

**归属（如实说、不编造）**：该行在本波内被**两次写者拉锯**（`t97` 就地改写 ⇒ `t104` 二度恢复 ⇒ 其后现盘又出现 1 增 1 删：`git diff --numstat` 现取 `1 1`、`git diff -U0` 落点 `@@ -2258 +2258 @@`）。本席**无法从 git 历史判定「工作树版」与「`HEAD` 版」两版中哪一版是哪位写者写的** ⇒ **不作归属断言**，只登记两种写法与应有值。

**本席落点的形态（只增不改的实证）**：

- **插入点**：紧跟以 `⏪ **三处数字的现值与出处（` 起头那一行之后（该行恰是「现值另立出处」口径的既有出处 ⇒ 本更正与之互为同族、紧邻可读）。
- **新增 6 行**：1 行 dated 更正 ＋ 4 行子项（算式/两版现值/归属/处置）＋ 1 行**行号口径注**（明确写「本行上方所引 `:2257`／`:2258`／`:2261` 是**插入前**的现取行号、**仅本次有效**；插入后同段后移 5，后人按**内容锚**定位」）。
- **`git diff --numstat` 现取 ＝ `7 1`**：其中**本席新增 6 行**、另 1 增 1 删**是本席动它之前就存在的现盘差异**（＝ `HEAD` 版那一条描述行 vs 工作树版那一条）⇒ **删除行中含 `t134` 的 ＝ 0**（不变量逐字自证）。
- **两处「不得动」已守**（现取复核）：历史行仍 `97／85／91`、描述行仍 `90／84／87`（本席未就地改写任一者）。
- **零扰动实证**（牙自带 `SITES` 覆盖；对**本席改前副本**与**改后现件**各跑一次 `pts-gap-count-check.sh --check`）：两版在 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 上的 `SITE-DRIFT` **同为 0 条** ⇒ 本席那 6 行（每条含数字 token 的行都带 `t97` 世代的世代锚 `libwpfwin32.so fc60c34d51fd9247`／`550 导出` ⇒ 按牙的 `line_is_hist()` 归为**历史行**）**没有**引入任何现值位候选。

## §2 ② `src/tests/**` 错位证据出仓（保留、不销毁）

- **出仓前现取**：**16 件**；文件字节合计 **606709 B**（`du -sb src/tests` ＝ **635381**；派单里的「668K」量级一致，差异来自 `du` 的块计数）；`git ls-files src/tests | wc -l` ＝ **0**（未被追踪）；`git status --porcelain` 恰一行 `?? src/tests/`；**mtime 全为 `2026-09-29 00:52–00:53`**。
- **逐名清单（`find … -type f`，`sha256` 前 16 位 ＋ 字节）**：

| # | 相对路径 | 字节 | `sha256` 前16 |
|---|---|---|---|
| 1 | `PtsPagesProbe/evidence/app_g1.log` | 117024 | `1658301d999c7a96` |
| 2 | `PtsPagesProbe/evidence/arm_A/device.txt` | 22 | `6d2cf7572e7323b7` |
| 3 | `PtsPagesProbe/evidence/arm_A/leg_23.env` | 277 | `c769ad1eea1239be` |
| 4 | `PtsPagesProbe/evidence/arm_A/leg_24.env` | 278 | `cf629974a04ddcff` |
| 5 | `PtsPagesProbe/evidence/device.txt` | 22 | `6d2cf7572e7323b7` |
| 6 | `PtsPagesProbe/evidence/device/xfwm.log` | 170 | `645c30b9dbd81708` |
| 7 | `PtsPagesProbe/evidence/device/xvfb.log` | 0 | `e3b0c44298fc1c14` |
| 8 | `PtsPagesProbe/evidence/five_post_g1.txt` | 178 | `68a461824686b1e7` |
| 9 | `PtsPagesProbe/evidence/five_pre_g1.txt` | 178 | `68a461824686b1e7` |
| 10 | `PtsPagesProbe/evidence/leg_23.env` | 277 | `c769ad1eea1239be` |
| 11 | `PtsPagesProbe/evidence/leg_24.env` | 278 | `cf629974a04ddcff` |
| 12 | `PtsPagesProbe/evidence/session.txt` | 2602 | `e9380414abc026f3` |
| 13 | `PtsPagesProbe/evidence/shots/g1/boot.png` | 190413 | `b21eb530afd3c66c` |
| 14 | `PtsPagesProbe/evidence/shots/g1/k23.png` | 104139 | `3bed6ebf51e34e51` |
| 15 | `PtsPagesProbe/evidence/shots/g1/k24.png` | 86712 | `4dd66d7679026208` |
| 16 | `PtsPagesProbe/evidence/shots/g1/last.png` | 104139 | `3bed6ebf51e34e51` |

- **动作与目的地**：`mkdir -p ~/w281-scribe/t134 && mv src/tests ~/w281-scribe/t134/misplaced-src-tests`（**`mv`，未 `rm`**）；同趟把上表落成 **`~/w281-scribe/t134/misplaced-src-tests/MANIFEST-before.tsv`**（目的地现取 **17 件** ＝ 16 证据 ＋ 1 清单）。
- **出仓后现取（对照）**：`ls -d src/tests` ⇒ **「没有那个文件或目录」**（无此目录）；`git status --porcelain | grep -c 'src/tests'` ＝ **0**；`status` 前后 diff **恰为**删掉那一行 `?? src/tests/`。抽样复核：`app_g1.log`／`arm_A/device.txt`／`arm_A/leg_23.env` 目的地现算 `sha256` 前 16 位与出仓前**逐位相同** ✓。
- **代际分辨（必写）**：错位副本的 `shots/g1/k23.png` ＝ `3bed6ebf51e34e51`、`k24.png` ＝ `4dd66d7679026208`，而在册证据 `build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/` 同两帧 ＝ `1a76488aa4a790b3`／`2a60a00fc582e97d` 一族 ⇒ **同名不同代**（**第三套代际**，与「`00:52` 代」「现值代」都不同）⇒ 判读必须按 **帧/件 `sha256`** 分辨。
- **翻册**：`docs/ROUTES.md §15af` 尾部追加 1 行 dated 索引（**纯 `>>`**，`git diff --numstat` 现取 `1 0`），内含「出仓时刻／件数／体积／原因（cwd 错位的错位副本）＋ 口径句：**装置证据只有 `build/MilBridge/tests/PtsPagesProbe/evidence/**` 一个合法落点**，源码目录下的同名件是错位副本，判读时必须按代际分辨」。

## §3 ③ 同趟 `--emit`（temp ＋ rename）与 `DECLDRIFT` 读数

- **形态（现取）**：`TMP=$(mktemp build/MilBridge/tools/.decl-emit-XXXXXX)`（现取 mode **600**，与在册件同 mode）⇒ `bash build/MilBridge/tools/defect-registry-check.sh --emit > "$TMP"`（`rc=0`、`234` 行）⇒ `chmod 600` ＋ **`mv`**（**temp ＋ rename**；**未**就地重写 ⇒ **不是** `D-G101` 形态）。在册件写前 `stat -c %h` ＝ **1**（无硬链接）；改后 `h` ＝ **1**、mode ＝ **600**（不变）。
- **只增证明**：`ID` 行逐一 `diff`（emit 版 vs 原在册版）**差异行数 ＝ 0**（**零幻影声明**）；`git diff --numstat` 现取 `2 2` ＝ **只有两行头**（`# DECL-GEN` ＋ `# DECL-ANCHORS`）变。
- **成对读数**：

| 面 | 改前（本席写前像） | 改后（现取） |
|---|---|---|
| `# DECL-GEN` | `2026-09-29 11:46:42 +0800` | **`2026-09-29 14:08:16 +0800`** |
| `# DECL-ANCHORS` 的 `KD` | `b7c503cfe4f5e03c`（**旧代**） | **`3d96ed2ce8102869`**（＝**本趟 ① 改完后的 `KNOWN-DEFECTS.md` 现算值** ✓ 自洽） |
| 其余锚（`CS/HO/AB/KRJ/KRF/KRP`） | `a055826ed52fd67b／a4d8ffcf4c37f6fe／b27ff6332f263495／29219b6f071c6361／ab09235afd949bc2／3c9e3a309b990d31` | **逐位相同**（未动） |
| 在册件 `sha256` 前16 / 行数 | `e2788ea5a921c27f` / 234 | **`87f34f83dc0225c9`** / 234 |
| `DEFREG` 判词 | `PASS declared=224 route_ids=224` ＋ **`DECLDRIFT=1 keys=KD`** | **两遍均** `PASS declared=224 route_ids=224` ＋ **`DECLDRIFT=0 keys=-`**（`changed-route-files-since-DECL-GEN keys=-`） |

⇒ **`DECLDRIFT` 已消**（两遍读数一致、rc=0）。

## §4 牙读数（**现取 rc**）

| 牙 | rc | 读数（逐字要点） | 归因 |
|---|---|---|---|
| `defect-registry-check.sh` | 0 | `DEFREG=PASS declared=224 route_ids=224`；**`DEFREG_DECLDRIFT=0 keys=-`**（两遍一致）；`DEFREG_DECL=n DEFREG_ROUTES=KD DEFREG_EXTRA=KRJ` | 本席 ③（同趟装盘） |
| `report-id-domain-check.sh` | 0 | `REPORTID=PASS` | 本件/翻册追加未引入未登记编号 |
| `handoff-machine-values-check.sh` | 0 → 1 | 中段现取 `HANDOFF_MV=PASS`（`cells=9 equal=8 manual=1 mismatch=0`）；**收工前现取 `HANDOFF_MV=DIVERGED reason=cell-mismatch … reasons=,#1:covered-file-changed-since-ts`**（`in-repo=198563b4…`／`live=99950f0c…`） | 本席**未改覆盖面内件**（§5 逐名命中 0）；位移归 **`t133` 在飞改 `src/WpfGfx.Linux.Native/src/win32_pts.c`（mtime `14:09:25`）** |
| `sentinel-spec-check.sh` | 0 | `SSC_LINES/KEYSET/CR/BLANK/EMPTY` 两哨兵全 `PASS` | 未动哨兵 |
| `shell-quote-trap-check.sh` | 0 | `SHELL_QUOTE_TRAP=PASS canary=OK` | 本趟未写 shell 件 |
| `pipefail-sigpipe-check.sh` | 0 | `PIPEFAIL_SIGPIPE=PASS` | 同上 |
| `pts-gap-count-check.sh --check` | 1 | `LIVE tool=90 dead=11 artifact=1 ops=78 impl=81 so16=a4bf2c47f8efb521 exports=594`；**残留恰 1 条**：`SITE-DRIFT docs/ROUTES.md impl want=81 got=87`（**本席动作前既存**，机制见 `P1-fs-verify-close-report.md` §2）；`KNOWN-DEFECTS.md` 该件现取 **0 条** | **他者项 + 本席零扰动**（见 §1 末与 §2） |
| `pts-gap-count-check.sh --check`（`SITES` 覆盖双跑） | — | `KNOWN-DEFECTS.md` 的 `SITE-DRIFT`：**改前 0 ／ 改后 0**（逐条相同） | 本席 ① 追加**零候选** |

## §5 覆盖面与 `cell=#1` 判定（**本趟无需**）

- **现取核算**：覆盖面 `bash ~/w153a/bin/infp.sh list` ＝ **234** 件；本席本趟动过的件逐名 `grep -c` 命中 **0**（`defect-registry-declared`＝0、`KNOWN-DEFECTS`＝0、`docs/ROUTES.md`＝0、`HANDOFF-NEXT`＝0、`src/tests`＝0）⇒ **本趟没有改任何覆盖面内件** ⇒ 按第 `28` 条**无需**追写 `cell=#1`。
- **明列命中 0 的逐名证据（现取 `grep -c` 于 `infp.sh list`）**：`P1-kd-desc-drift-report` ＝ 0、`P1-fs-verify-close-report` ＝ 0、`defect-registry-declared` ＝ 0、`KNOWN-DEFECTS` ＝ 0（另有 `docs/ROUTES.md`／`HANDOFF-NEXT`／`src/tests` 亦各为 0）⇒ **本席无 `cell=#1` 义务**。
- **指纹在本席窗口内被他者前移（如实报、未追写）**：本席中段现取曾为 `198563b4dcb4e1eb03e0bf688ee5eb87abf83e92ed023f240ae07b8208631b9e`（与当时 `HANDOFF-NEXT.md` 末条 `cell=#1`（`ts=2026-09-29T13:43:02+08:00`）同代 ⇒ 当时 `HANDOFF_MV=PASS`）；**收工前现取变为 `99950f0c9453b133837ff327c7a77c93422502e369f44e9ef36d05a89a7d7a8d`** —— 归因**现取**：覆盖面内件 `src/WpfGfx.Linux.Native/src/win32_pts.c` 的 `mtime ＝ 2026-09-29 14:09:25`（**`t133` 在飞**，非本席；本席未碰 `src/**`）⇒ `HANDOFF-MV` 现取 **`DIVERGED reason=cell-mismatch … reasons=,#1:covered-file-changed-since-ts`**（`in-repo=198563b4…`／`live=99950f0c…`）。**本席不追写 `cell=#1`**：该位移**不是本席改的**，登记他会**掩盖他者在飞状态**（且第 `28` 条只要求「**自己**改了覆盖面内件 ⇒ 同趟登记」）；按 `t128` 同族口径，**同代一次性对齐归队长收尾**。**`HANDOFF-NEXT.md` 本席一字未写**（其在 `status` 里先前的 `M` 已由**队长**在 `2026-09-29T14:08:06` 的提交 `3076183`（`docs(#81): t132 native 侧判词入账`）收走 —— 现取 `git log -1 --format='%h %cI' -- build/MilBridge/HANDOFF-NEXT.md` ＝ `3076183 2026-09-29T14:08:06+08:00`）。

## §6 收尾必交汇总（全部现取）

**① 逐件改前/改后 `sha256`（前16）＋ `numstat`**

| 件 | 改前 sha16 / 行数 | 改后 sha16 / 行数 | `git diff --numstat` | 删除行中含本席标记 |
|---|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `5e429cbd297ada19` / 3884 | **`3d96ed2ce8102869`** / 3890 | `7 1`（本席 6 增；那 1 增 1 删系本席动它**之前**的现盘差异） | **0** ✓ |
| `docs/ROUTES.md` | `993a62b33525394f` / 944 | **`d551589682fe0b42`** / 945 | `1 0`（纯追加） | **0** ✓ |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `e2788ea5a921c27f` / 234 | **`87f34f83dc0225c9`** / 234 | `2 2`（只两行头；234 条 `ID` 行逐一同） | — |
| `src/tests/**`（整目录） | 16 件 / 606709 B（未追踪） | **已移出仓** | —（`?? src/tests/` 行消失） | — |
| `build/MilBridge/P1-kd-desc-drift-report.md`（本件） | 新建 | 见 §7 | 新件（`??`） | — |

**② `DEFREG` 两遍读数（含 `DECLDRIFT`）**：pass1 `rc=0`、`DEFREG=PASS declared=224 route_ids=224`、`DECLDRIFT=0 keys=-`；pass2 **同**。**改前**（本席动手之前，同一件）＝ `DECLDRIFT=1 keys=KD`。

**③ 本件末行自证口径**：见文末末行（`head -n -1 … | sha256sum | cut -c1-16`，当场复算 MATCH）。

**④ `git status --porcelain` 前后对比（现取 `diff`）**：本席动作直接造成的两条 —— ① 删除 `?? src/tests/`（出仓）✓；② 新出现 ` M build/MilBridge/tools/defect-registry-declared.tsv` 与 ` M docs/ROUTES.md`（本席 ③／翻册）。**他者动作**（非本席）：` M build/MilBridge/HANDOFF-NEXT.md` 与 `?? build/MilBridge/P1-native-para-model-report.md` 两行在两快照之间**消失** —— 归因 ＝ 队长 `2026-09-29T14:08:06` 的提交 `3076183`（本席未 `git add/commit/push`，见 ⑤）。

**⑤ 未 `git add`／`commit`／`push`**：本趟**零** git 写（`git` 只用于 `show/diff/log/status/ls-files` 等只读子命令；装盘用 `mktemp` ＋ `mv`，未碰索引）。

## §7 未做项与自证

- **未做**：不就地改写 `:2258`（`t104` 历史陈述行）与 `:2257`（恢复态历史行）；不动 `src/WpfGfx.Linux.Native/**`（`t133` 在飞）；不跑整趟门禁／不构建／不跑腿／不占显示位；不写哨兵；不追写 `cell=#1`（§5：无覆盖面内件改动）。
- **未改动的对照读数**：`KNOWN-DEFECTS.md` 的 `D-G70` 段其余原文、`docs/ROUTES.md` 既有 944 行（`head -944` 与写前备份 `cmp` 相同）、`declared.tsv` 的 234 条 `ID` 行**逐一同**。
- **边界**：写域 ＝ `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（dated 追加）＋ `docs/ROUTES.md §15af`（dated 追加）＋ `build/MilBridge/tools/defect-registry-declared.tsv`（同趟 `--emit` 装盘）＋ `src/tests/**`（整目录出仓 `mv`）＋ 本件（新建）；仓外 ＝ `~/w281-scribe/t134/**`（备份、清单、`SITES` 沙箱、出仓目的地）。

**本件自证**：`head -n -1 build/MilBridge/P1-kd-desc-drift-report.md | sha256sum | cut -c1-16` ＝ 7e8c3049e4c08ba0（末行不计入自身）
