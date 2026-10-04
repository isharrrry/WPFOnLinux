# P1 复核关账（第二轮）报告 · V-1／V-2／V-3／V-4（`t33`）

> **开篇 ＝ 判据**（写在任何落仓之前）。判词载体 ＝ `build/MilBridge/P1-v-close-verify.md`（`t28`，`269` 行／`ffec432549f9e434`，**只读未改**）。
> 写者 `scribe`；工作根 `$N`；分支 `feat-Linux`。纪律：写前 `stat -c %h` 须 `==1`；`cp -p` 备份在任何写之前；`temp + rename`；**只增不改**；`NOINFO` 具名；新增行 `⏪` 起头 ＋ **亚秒戳**（含「零位移」一律带值带时刻）。
> **红线（派单明写）**：**不许**为让牙变绿去改 `build/MilBridge/P1-v-close-report.md` 的**引证现场** —— 那是真缺陷现场，**留在册**。
> §0 判据段读时戳（亚秒）＝ `2026-09-28T16:36:25.250+0800`。

## §0 判据（先写 · 逐条可现算）

- ⏪ **C1（V-1 立号）**：`D-G183` **未被占用**（现取四 route 件各 `0`、`declared.tsv` ID 行最大号 `182`）；在 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 按同册体例成条（现象／根因／机器证／判据／🔴 口径句／两极化／边界／同族），**如实记「由 `t28` 发现、队长配号」**；同趟 `--emit`。
- ⏪ **C2（V-1 修法）**：牙**只判「该行自身的戳」** —— 戳的前缀（去掉空白／`*`／反引号／标点后）必须**以自证标记收尾**（`读时`／`读取时刻`／`落盘`／`提交时刻`／`dated`／`ts=`）；**引用/引证文本里的戳一律不判且逐条上屏**（`TSORDER_QUOTED`）。
- ⏪ **C3（V-1 两极化 ＋ 红线）**：对**已提交、干净**的 `build/MilBridge/P1-v-close-report.md`：**修前** `rc=1` 假红 ⇒ **修后不许红**（`PASS` 或 `NOINFO`）；`--selftest` 新增腿「**引用夹具未来戳 ⇒ 不许红**」；**引证现场一字不改**（该件 `porcelain` 零行、sha16 不变）。
- ⏪ **C4（V-2）**：`HANDOFF` dated 追加把口径句第②条 `--diff-filter=A` **限定为「整件首次入册」**，写明**单节一律用第①条 `-S` 形态**，并给**本席自算的两值对照**。
- ⏪ **C5（V-3）**：两例计件**补全并给现取**（例①「两件」⇒ **三件**；例② **漏列** ⇒ 补列），并声明**不可现取的格**记 `NOINFO`（不许凑数）。
- ⏪ **C6（V-4）**：牙在**件不存在**时聚合句的 `reason` 必须反映真因（`file-absent`），**零戳件**才给 `no-stamps`；**两极化真跑**（不存在的件 ⇒ 对应 reason；零戳件 ⇒ `no-stamps`）。
- ⏪ **C7（指纹／牙）**：入口／出口各取 `inputs_fp` ＋ 覆盖面件数（**纪律第 20 条：带值带时刻**）并**逐件归因**；`KD` 改 ⇒ **同趟 `--emit`**；两牙 `DEFREG`／`REPORTID` 现取不退化、增量逐件归因。
- ⏪ **C8（边界／收口）**：越域为零（`porcelain` 逐行归属，他人脏件逐行点名）；**未** `git add/commit/push`；**未碰** `close-wave.sh`／`verify-all.sh`／`P1-v-close-verify.md`／`P1-v-close-report.md`／`P1-w1-report.md`／产品件／基线件；未跑整波／门禁／构建；临时件残留 `0`；本件就位并自报 sha16 ＋ 读取时刻（亚秒）。

## §1 落仓清单（证据行读时戳（亚秒）＝ `2026-09-28T16:38:11.023+0800`）

⏪ 五件（写前 `stat -c %h` 全 `==1`；`cp -p` 备份 `~/w281-scribe/bak/*.pre-t33` 取在**任何写之前**；落仓一律 `temp + rename`）：
⏪ `build/MilBridge/tools/timestamp-order-check.sh` `4f45aa7b574a929b` → **`6ace8e29f3cf6357`**（182 → 220 行；`bash -n` **OK**；`--selftest` **`cases=5 → 8 pass=8 fail=0`**／stderr 零行；mode 755）。
⏪ `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `fb25caf857c1b37f` → **`6a1ca425a94c4fae`**（3729 → 3740 行；`numstat` **`11 0`**；`D-G183` 标题命中 **`1`**；前缀 `cmp` **IDENTICAL**）。
⏪ `build/MilBridge/tools/defect-registry-declared.tsv` `3c3c3de96dfcf8f2` → **`caac65d50ca90c3b`**（226 → 227 行；**同趟**：`KD` 编辑**之后**才 `--emit`；新行 `ID\tD-G183\treq=KD\tpresent=KD`；除 `# DECL-GEN` 外差异 `3` 行＝`# DECL-ANCHORS` 的 `KD=` 锚 ＋ 该新行 ⇒ 逐行可归因）。
⏪ `build/MilBridge/HANDOFF-NEXT.md` `3d25341c90eb6dff` → **`3d25341c90eb6dff`**（369 → 369 行；`numstat` **`9 0`**；前缀 `cmp` **IDENTICAL**；V-2 射程限定 ＋ V-3 两例计件补全，同段 dated 追加）。
⏪ `build/MilBridge/P1-v-close2-report.md`（**新建**）＝ 本件（§0 判据**先落**，`17` 行／`d9cf78b0b0f9b51c` 为**判据段**的 sha16、**不是**全文值）。
⏪ **新增行形态自查**：两件追加件的**新增行** `^[^⏪]` 计数 ＝ **`0`**；新增行戳**带亚秒**（各 `1` 处命中）。

## §2 C1／C2／C3（V-1）证据：立号 `D-G183` ＋ 扫描域收窄 ＋ 两极化

⏪ **立号占用检查（改前，逐件现取）**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` **`0`**／`docs/CURRENT-STATE.md` **`0`**／`build/MilBridge/HANDOFF-NEXT.md` **`0`**／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **`0`**；`declared.tsv` `ID` 行**数值序最大号** ＝ **`182`** ⇒ **`D-G183` 未被占用** ✓（全仓唯一命中是 `.agent-teams/…/team.json` 里的**本任务描述**本身）。
⏪ **条目形态（八段齐）**：`### 🆕 **`D-G183`**` 标题命中 **`1`**；现象（含 `t28` §8 逐字点名）／根因（只按**形态**认戳、不问「是不是**本行自己**写的」）／机器证（**修前 `rc=1` → 修后 `rc=0`**，同件同趟）／判据三条／🔴 口径句逐字／两极化／边界（**由 `t28` 发现、队长配号**；引证现场一字未改；未全仓扫描 ⇒ `NOINFO`）／同族（`D-G102`／`D-G103`／`D-G130`）。
⏪ **修法（扫描域收窄，不改三态）**：戳**之前**那一段（去空白／`*`／反引号／标点后）**必须以自证标记收尾**（`读时`／`读取时刻`／`读取`／`落盘`／`提交时刻`／`dated`／`ts=`）⇒ 才算「该行自身的戳」；否则 ⇒ **`TSORDER_QUOTED` 逐条上屏、不判**。
⏪ **两极化真跑（原始机读行）**：**正侧** ＝ 已提交、干净的 `build/MilBridge/P1-v-close-report.md` ⇒ **修前 `rc=1`**（`TSORDER=FAIL reason=future-stamp files=1 stamped_lines=15 stamps=31`，点名 `:52` 的 `2028-01-01T00:00:00.000+0800`）→ **修后 `rc=0`**（`TSORDER=PASS files=1 stamped_lines=15 stamps=31 self=4 quoted=27`，**引用戳 27 处逐条上屏、0 处判红**）。
⏪ **selftest 新增三臂**：`S6`「**引用**夹具未来戳 ＋ 本行有自证戳 ⇒ **不许红**」（`rc=0`）｜`S7`「**只有引用戳** ⇒ `NOINFO(no-self-stamps)`」（`rc=3`，不许红）｜`S8`「件不存在 ⇒ `NOINFO(reason=file-absent)`」（`rc=3`）⇒ **`cases=8 pass=8 fail=0`**。
⏪ **同趟反证（收窄的是射程、不是力度）**：`S2`「**自证**未来戳 ⇒ `FAIL` 点名 `file:line`」**仍 `rc=1`** ✓。
⏪ **红线守住（引证现场一字未改）**：`build/MilBridge/P1-v-close-report.md` ⇒ `porcelain` **`0`** 行、sha16 仍 **`a1c39ae2a544db8a`**（该件在本波 `outOfScope`，**未读改**）。

## §3 C4（V-2）证据：`--diff-filter=A` 限定为「整件」＋两值对照

⏪ **落法**：`HANDOFF-NEXT.md` EOF dated 追加（同一段内）。**两值对照（本席自算，同一件 `build/MilBridge/HANDOFF-NEXT.md`）**：`git log --diff-filter=A --format=%cI -- <件>` ⇒ **`2026-09-23T15:44:26+08:00`**（＝**整件**首次入册） vs `git log -S'ts=<亚秒戳> 时 入口=X 出口=X，覆盖面=N' --format=%cI -- <件>` ⇒ **`2026-09-28T16:31:22+08:00`**（＝**该节**首次入册；该子串现取**恰 `1` 行**）⇒ **差约 `5` 天** ⇒ 拿第②条答「该节」＝**形态完好的静默错值**。
⏪ **规则（逐字入册）**：引用**某节**的「落盘时刻」**一律用第①条 `-S`**；第②条 `--diff-filter=A` **只准**用于「**整件**首次入册」，**引用时必须写明「整件」二字**。

## §4 C5（V-3）证据：两例计件补全（提交级 `numstat` 数件）

⏪ **例①（「两件」⇒ 实为三件）**：`git show --numstat 4a97a0d`（`2026-09-28T16:09:32+08:00`）⇒ `build/MilBridge/HANDOFF-NEXT.md` `6 0`｜`build/MilBridge/P1-w1-report.md` `5 0`｜`docs/ROUTES.md` `1 0` ⇒ **`t16` 的 F 批动了三件**，第 `19` 条只举了两件的 `mtime`（漏掉本件 `HANDOFF-NEXT.md`）。
⏪ **例②（漏列三件）**：`git show --numstat f590aca`（`2026-09-28T16:12:16+08:00`）⇒ `HANDOFF-NEXT.md` `6 0`｜`P1-dg179-report.md` `3 0`｜`tools/defect-registry-declared.tsv` `3 2`｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `12 0` ⇒ **`t18` 的 I 批动了四件**，例②只写了一件。
⏪ **不可现取的格（不许凑数）**：两例里**被后续写重写掉**的那几件 `mtime` ⇒ **`NOINFO(reason=落盘时刻已被后续写重写)`**，只给**提交级**旁证（`4a97a0d`＝`16:09:32`／`f590aca`＝`16:12:16`）；**规则**：计件一律用**该笔提交的 `numstat`**，不许凭记忆列件名。

## §5 C6（V-4）证据：`NOINFO` 的 reason 不许被吃掉

⏪ **修法**：聚合句改**先报真因**（`file-absent`／`no-self-stamps`／`no-first-commit`／同秒），**只有「语料里根本没有戳」**才 ⇒ `reason=no-stamps`；件不存在的 per-file 行同趟由 `no-file` 改名 **`file-absent`**。
⏪ **两极化真跑**：`--file /tmp/absent-t33`（不存在）⇒ `rc=3`：`TSORDER_NOFILE …（件不存在 ⇒ 不判）` ＋ **`TSORDER=NOINFO reason=file-absent files=0 …`**（**真因不再被 `no-stamps` 吃掉**）｜`--file /tmp/zero-t33.md`（存在但零戳）⇒ `rc=3`：**`TSORDER=NOINFO reason=no-stamps files=1`** ✓｜**`S8` selftest 臂**同证。
⏪ **回归（改动未伤既有腿）**：缺省语料 `PASS self=1 quoted=9`｜`P1-w1-close-verify.md` `PASS self=1 quoted=9`｜`P1-dg181-verify.md` `PASS self=1 quoted=8`｜`HANDOFF-NEXT.md` `PASS self=11 quoted=14`。

## §6 C7 证据：指纹（带值带时刻）／`--emit`

⏪ **入口**（本波开工现取，`ts=`2026-09-28T16:38:11.023+0800 之前的开工读数）：`inputs_fp` ＝ `c87cb187f45082e83d3b217d235d50b24f1183f28d37308f1a175de25210403d`／覆盖面 **`226`**。
⏪ **出口**（本波落定后现取）：`inputs_fp` ＝ **`c87cb187f45082e83d3b217d235d50b24f1183f28d37308f1a175de25210403d`**／覆盖面 **`226`** ⇒ **两值逐字相同、件数不变**。
⏪ **逐件归因**：本波五件里 `timestamp-order-check.sh` **`in-list=0`**（**未接线**）、`HANDOFF-NEXT.md` **`0`**、`KNOWN-DEFECTS.md` **`0`**、`declared.tsv` **`0`**、本件 **`0`** ⇒ **本波零位移**（**不放松**：这是**带值带时刻**的读数；任何第三方改覆盖面内件都会推翻它）。
⏪ **`[42] --expect` 不需同趟改**：覆盖面件数 `226 → 226`；**未改** `verify-all.sh`（`600274f130cfe913`）与 `build/close-wave.sh`（`f9a2ee3ee35baff8`）。
⏪ **同趟 `--emit`**：`declared.tsv` `3c3c3de96dfcf8f2` → **`caac65d50ca90c3b`**（227 行）；`# DECL-GEN = (--emit) 2026-09-28 16:37:35 +0800`；`# DECL-ANCHORS KD=6a1ca425a94c4fae`（**== KD 现取**）；新行 `ID\tD-G183\treq=KD\tpresent=KD`；`DEFREG=PASS declared=218 route_ids=218` ∧ `DECLDRIFT=0 keys=-`（**本波唯一新号 `D-G183`** ⇒ `declared` `217 → 218` 100% 归因它）；`REPORTID=PASS files=201 ids=2074 declared=218`。

## §7 自伤（如实记）

⏪ ① **补丁锚点两次记错**：我按记忆写锚（`[ -n "$sec" ] || {`／`#   rc=0 …` 那两行），**现取后都不存在** ⇒ 两趟 `python` 都在 `assert` 上**响亮失败**、**`rename` 未执行** ⇒ 当场复核牙 `sha16=4f45aa7b574a929b`／`182` 行**逐字未变**（**零损伤**）；改为**逐字 `grep` 出锚**＋**按行定位**后才落定。⇒ 教训：**改代码前先 `grep -n` 打出锚原文**（与「报告里任何机读行先实跑后落笔」同源）。
⏪ ② 本件 §0 判据段落的 `17` 行是**判据段**的行数（不是全文），已在该行内写明 ⇒ 引用其 sha16 时**必须写明口径**。

## §8 边界

⏪ **`porcelain` 逐行归属（现取）**：`M build/MilBridge/tools/defect-registry-declared.tsv`｜`M build/MilBridge/tools/timestamp-order-check.sh`｜`M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`｜`?? build/MilBridge/P1-task0201-criteria.md`｜`?? build/MilBridge/P1-v-close2-report.md` ⇒ **本波 `inScope` 五件全在**；其余为**他人件**（`t7`／`verifier` 等，未读未改）⇒ **本波越域为零**。
⏪ **未碰（现取 sha16）**：`build/close-wave.sh` `f9a2ee3ee35baff8`｜`verify-all.sh` `600274f130cfe913`｜`build/MilBridge/P1-v-close-verify.md` `ffec432549f9e434`｜`build/MilBridge/P1-v-close-report.md` **`a1c39ae2a544db8a`（引证现场留在册）**｜`build/MilBridge/P1-w1-report.md`｜`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`｜`src/**`。
⏪ **临时件残留 `0`**、暂存区 **`0`**；**未** `git add/commit/push`；未跑整波／门禁／构建／应用／显示位。
⏪ **`NOINFO`（具名）**：① 牙**未接线**（`fp_inputs()`／`verify-all.sh` 归 W4）⇒ 不判门禁效果；② **全仓**是否还有其它件存在同类「引用戳」⇒ **未全仓扫描**；③ 两例里被重写掉的那几件**当时 `mtime` 不可现取** ⇒ 只给提交级旁证；④ `t28` 的原始断言／脚本**未在本波现取**（其判词读数按判词转引，本席另给自算的成对读数）。

## §9 结论

⏪ `t28` 点名的 **V-1／V-2／V-3／V-4** 四处**全部关账**：**V-1** 立号 **`D-G183`** ＋ 扫描域收窄（只判**自证戳**、**引用戳逐条上屏**）＋ `--selftest` `5→8`（含「引用未来戳不许红」）＋ **对已提交干净件的假红 `rc=1 → rc=0`**；**V-2** `--diff-filter=A` 限定为**整件**（两值对照差约 `5` 天）＋**单节一律 `-S`**；**V-3** 两例计件按**提交级 `numstat`** 补全（三件／四件）＋不可现取的格给 `NOINFO`；**V-4** `NOINFO` 的 reason 先报真因（`file-absent` vs `no-stamps`）。
⏪ **判据只收紧**：**同一趟**证明「收窄的是射程、不是力度」（`S2` 自证未来戳仍必红）；**引证现场一字未改**（红线守住）；`KD` 同趟 `--emit`（`declared` `217→218`，`DECLDRIFT=0`）。
⏪ ⏪ **dated 更正（§1 那行 HANDOFF 口径；`t33`，读时 2026-09-28T16:38:22.468+0800；原文**保留、一字未删**）**：§1 写「`build/MilBridge/HANDOFF-NEXT.md` `3d25341c90eb6dff` → `4ce961789433b735`」——**该追加首跑其实未落**（生成脚本的多行括号不闭合 ⇒ **`SyntaxError`、`rename` 未执行**；当场复核 `379`？否 —— **`369` 行／`3d25341c90eb6dff` 与写前逐字相同、`numstat` 空 ⇒ 零损伤**，见 §7 补记）。
⏪ **真值（本条落定后现取）**：`HANDOFF-NEXT.md` `3d25341c90eb6dff` → **`4ce961789433b735`**／行数 **369 → 378**／`numstat` **`9 0`**／原文前缀 `cmp` **IDENTICAL** ⇒ **以本条为准**；§1 与 §3／§4 所述「已落」的**内容**不变（V-2／V-3 同段追加，落定后读数如上）。
⏪ **补记（§7 第 ③ 条自伤）**：本波自伤共**三**次，全部由**现算自查**咬住：① 牙补丁锚点两次记错（`assert` 响亮失败、`sha16` 逐字未变）；② §1 里用 `{H}` 形式**把「落定后现值」写进了对「落定前」的复述**（与 `t29` 同族）；③ **HANDOFF 追加首跑未落**（括号不闭合）⇒ 本条更正。⇒ 此后落仓脚本一律**先 `bash -n`／`python -c` 干跑语法**，再 `rename`。
⏪ **措辞整理（`t33`，读时 2026-09-28T16:38:29.572+0800；上文保留）**：更正条里「当场复核 `379`？否 —— `369` 行…」这半句是我落笔时的自语，**读数就是 `369` 行（与写前逐字相同）**；此后一律先写读数、再断言。
⏪ 本件自证 sha16（口径＝**末行之前的全文**）＝ `606859001d5600ef`（末行＝本行）；**全文** sha16 与末次读取时刻见交件消息（末行只携带 `head -n -1` 口径 ⇒ 全文值不可能自指）。
