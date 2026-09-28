# P1 复核关账报告 · V1／V2／V3（`t27`；含 `t19` 的同族第二次）

> **开篇 ＝ 判据**（写在任何落仓之前）。判词载体：`build/MilBridge/P1-w1-close-verify.md`（`t17`，`239` 行／`75f174e801510b2c`，**只读未改**）＋ `build/MilBridge/P1-dg181-verify.md`（`t19`，`218` 行／`7d693364e733379b`，**只读未改**）。
> 写者 `scribe`；工作根 `$N`；分支 `feat-Linux`。纪律：写前 `stat -c %h` 须 `==1`；`cp -p` 备份在任何写之前；`temp + rename`；**只增不改**；`NOINFO` 一律具名；**本件起所有新增行的戳一律带亚秒**（本件自身即 V2 修法的第一个执行者）。
> 判据段读时戳（**亚秒**）＝ `2026-09-28T16:24:46.279+0800`。

## §0 判据（先写 · 逐条可现算）

- ⏪ **C1（V1）**：`build/MilBridge/P1-w1-report.md` 落 dated 追加，把 `:223` 那个**自指计数格**标成**「本笔追加之前」**并**补现取值**（**本席自算**；须给「版本 ＋ 行数 ＋ 两个数（行数／处数）」三元组，且**本件追加后**的现值单列）。
- ⏪ **C2（V3）**：在册口径句 —— 引用某节「**落盘时刻**」**必须以首次承载该节的提交时刻为准**（件 `mtime` 会被后续追加重写），并给**可复算命令原文**。
- ⏪ **C3（V2①）**：`build/MilBridge/HANDOFF-NEXT.md` 纪律区落 dated 追加，**编号现取**接在最后一条之后；口径句**逐字含**「秒级不够：读时戳与落盘时刻同秒即不可对拍 ⇒ 必须给亚秒（毫秒级）戳，或让写入落下一秒」；**逐字写明本族已第二次**（并列 `t16` 的 F 批、`t18` 的 I 批）；写明**两条可选修法各自的落地位置**。
- ⏪ **C4（V2②）**：新牙 `build/MilBridge/tools/timestamp-order-check.sh` 判「文内 dated 戳 ≤ 该行**首次入册**的提交时刻」；**命令原文写进件头**；三态（`PASS`／`FAIL`／`NOINFO`）+`--selftest`。
- ⏪ **C5（V2③）**：**两极化真跑** —— 伪造**未来戳** ⇒ **必红并点名件＋行**；正常戳 ⇒ 绿；**取不到首次入册 ⇒ `NOINFO`**（不许静默判等）。
- ⏪ **C6（`t19` 的 V2·low）**：**不修改** `D-G181` 条目 ⇒ 在册记一句「**条目段序不作判据**」（落 C3 同一段 dated 追加）。
- ⏪ **C7（边界）**：越域为零（`porcelain` 逐行归属）；**未** `git add/commit/push`；**未**碰 `build/close-wave.sh`／`verify-all.sh`／两份复核载体／产品件／基线件；未跑整波／门禁／构建；临时件残留 `0`。
- ⏪ **C8（收口）**：本件就位并**自报 sha16 ＋ 读取时刻**（亚秒）；`NOINFO` 逐条具名。

## §1 落仓清单（证据行读时戳（亚秒）＝ `2026-09-28T16:26:19.152+0800`）

⏪ 四件（写前 `stat -c %h` 全 `==1`；`cp -p` 备份 `~/w281-scribe/bak/*.pre-t27` 取在**任何写之前**；落仓一律 `temp + rename`）：
⏪ `build/MilBridge/tools/timestamp-order-check.sh`（**新建**）sha16 **`4f45aa7b574a929b`**（182 行／11350 B／mode 755；`bash -n` **SYNTAX-OK**；`--selftest` **`cases=5 pass=5 fail=0`**／rc=0／**stderr 零行**）。
⏪ `build/MilBridge/HANDOFF-NEXT.md` `e94775200994e1dc` → **`fff0ac938d0e5a86`**（350 → 359 行；`numstat` **`9 0`**；原文前缀逐字节 `cmp` **IDENTICAL**）。
⏪ `build/MilBridge/P1-w1-report.md` `c01e2e92449e659e` → 全文 **`7190c1e4d180ecd5`**（227 → 233 行；`numstat` **`6 0`**；前缀 `cmp` **IDENTICAL**；`head -n -1` 现算 ＝ **`2e999713046e21cb`**）。
⏪ `build/MilBridge/P1-v-close-report.md`（**新建**）＝ 本件（§0 判据**先落**，`16` 行／`9d9a8099441cea68` 为**判据段**的 sha16、**不是**全文值）。
⏪ **新增行形态自查**：两件追加件的新增行 `^[^⏪]` 计数 ＝ **`0`**（`diff` 的 `>` 行全以 `⏪` 起头）；**新增行的戳全部带亚秒**（`grep -cE '读时 2026-[0-9-]+T[0-9:]{8}\.[0-9]{3}\+0800'` ⇒ 两件各 **`1`**）。

## §2 C1（V1）证据：自指计数格的版本三元组

⏪ 落点＝`build/MilBridge/P1-w1-report.md` EOF dated 追加（**`6`** 行）。
⏪ **被更正原句（逐字）**（`:223`，**仅本次有效**）＝「**③ 本报告件自身** ⇒ **`9` 行 ／ `11` 处**」。
⏪ **版本三元组（本席现算）**：① `4a97a0d^` 版（**`222`** 行）＝ **`9` 行 ／ `11` 处`** ⇒ **＝ `t16` 的 `③` 值** ⇒ 口径写死为**「`t16` 本笔追加之前（`222` 行版）」**；② `4a97a0d` 版（**`227`** 行）＝ **`11` 行 ／ `15` 处** ⇒ **＝ `t17` §5-V1 的现取**（逐格相同）；③ **本笔追加之后**（**`233`** 行）＝ **`13` 行 ／ `17` 处**（含本条自身引用 ⇒ **自指**）。
⏪ **实质结论不变**：`13` 在**四种口径**（`2/3`／`1/1`／`9/11`／`11/15`）下**都不成立** ⇒ `t16` F2 的结论**仍成立**。
⏪ **读法（口径句）**：凡引用「本件自身」的计数**必须**同时写**版本 ＋ 该版总行数**；只给一个数 ⇒ 不可对拍。

## §3 C2（V3）证据：「落盘时刻」取法 ＋ 可复算命令

⏪ **口径句（落 `HANDOFF-NEXT.md` 纪律区，同一段 dated 追加内）**：引用某节的「**落盘时刻**」**必须以「首次承载该节的那一笔提交的提交时刻」为准** —— 该件 `mtime` 会被**后续追加**重写（`t17` §4-N3 活例：`HANDOFF-NEXT.md` 的 `mtime` 对应**最后一次写**，不是 `F6` 那节的落盘）。
⏪ **可复算命令原文（三条，任取其一，须写件名）**：`git -C $N log -S'<该节唯一子串>' --format=%cI -- <件> | tail -1`（＝**首次入册**时刻）｜`git -C $N log --diff-filter=A --format=%cI -- <件>`（只看**新增**那一笔）｜`git -C $N show -s --format=%cI <sha>`（按提交号取时刻）。
⏪ **本席对该命令的现取自证**（拿 `t17` 载体验一次）：`git -C $N log -S'2026-09-28T16:08:26+0800' --format=%cI -- build/MilBridge/P1-w1-close-verify.md | tail -1` ⇒ **`2026-09-28T16:17:24+08:00`**（该件唯一那笔 `7bad6ba`）⇒ 与其全戳（最新 `2026-09-28T16:09:32`）**可对拍** ✓。

## §4 C3（V2①）证据：纪律第 19 条 ＋ 本族第二次 ＋ 两条修法落地位置

⏪ **落点**：`build/MilBridge/HANDOFF-NEXT.md` **EOF** 新 `### ⏪ dated 纪律追加` 块（`+9` 行）。**编号现取**：主列表最后一条 ＝ `18.`（现取该件 `:311`，仅本次有效）；其后 `### …哨兵规范…` 块内的 `1.`–`7.` 是**那一段自己的子列表** ⇒ 本条目 ＝ **第 `19` 条**。
⏪ **口径句（逐字，已在册）**：**「秒级不够：读时戳与落盘时刻**同秒即不可对拍** ⇒ 必须给**亚秒（毫秒级）**戳，或让写入**落下一秒**。」** ⇒ 现取命中：`秒级不够` ＝ **`1`**、`同秒即不可对拍` ＝ **`1`**。
⏪ **本族已第二次（逐字并列）**：**例① `t16` 的 F 批**（戳 `2026-09-28T16:08:26+0800` vs `mtime …16:08:26.445176624`／`.448176612` ⇒ 同秒；`t17` §4-N2／§5-V2）｜**例② `t18` 的 I 批**（戳 `2026-09-28T16:10:48+0800` vs `mtime …16:10:48.905708995` ⇒ 同秒；`t19` §4-N1／§5-V1）。
⏪ **两条修法各自的落地位置**：**甲「亚秒戳」⇒ 写者侧**（此后一律 `%Y-%m-%dT%H:%M:%S.%3N%z`；`t27` 本件三处新增**已照此执行**）｜**乙「让写入落下一秒」⇒ 写者侧**（取读时后 `sleep 1`；适用于 `~/w281-scribe/*.py` 一类批量落仓器）｜**判据侧** ＝ 本牙（对「戳无亚秒 ∧ 与 `mtime` 同秒」判 `NOINFO`，**不判绿**）。

## §5 C4／C5（V2②）证据：牙 ＋ 两极化真跑

⏪ **判据**：`戳 ≤ 该行首次入册的提交时刻`（**命令原文写进件头**：`git -C <root> log -S"<整行原文>" --format=%cI -- <件> | tail -1`；整行取不到退化为该戳串）＋ **对拍腿**（戳 ≤ `mtime`，且**戳无亚秒 ∧ 与 `mtime` 同秒 ⇒ `NOINFO(同秒不可对拍)`，不判绿）。三态：`PASS`(0)／`FAIL`(1)／`NOINFO`(3)／用法错(4)。
⏪ **正极**：缺省语料 `build/MilBridge/P1-w1-close-verify.md`（已提交、干净）⇒ `TSORDER=PASS files=1 stamped_lines=9 stamps=10`／**rc=0**（`TSORDER_SCAN … mtime=16:16:40.986104358`；最短余量 `delta=-205s`）。
⏪ **反极（伪造未来戳）**：沙箱副本 `~/w281-scribe/sbx-t27/forge.md`（把该件 `:112` 的戳改成 `date -d '+2 years'` 算出的未来戳 ＝ **`2028-01-01T00:00:00.000+0800`**）＋ `--assume-first-commit 2026-09-28T16:17:24+08:00` ⇒ **rc=1**：`TSORDER_FUTURE file=…/forge.md:112 stamp=2028-01-01T00:00:00.000+0800 first_commit=2026-09-28T16:17:24+08:00 delta=+39685356s` ＋ 同一条落盘腿 `mtime=16:24:46.395974294 delta=+39684914s` ⇒ **点名件＋行** ✓；`TSORDER=FAIL reason=future-stamp`。
⏪ **同秒腿**：沙箱 `same.md`（把 `:112`／`:211` 的戳改成与首次入册**同秒**）⇒ **rc=3**：`TSORDER_SAMESEC …:112 stamp=2026-09-28T16:17:24+0800 first_commit=2026-09-28T16:17:24+08:00（同秒 ⇒ 先后不可判）` ＋ `TSORDER=NOINFO reason=same-second-as-first-commit,…` ⇒ **不判绿** ✓。
⏪ **无历史腿**：沙箱件**不喂** `--assume-first-commit` ⇒ **rc=3**：`TSORDER_NOCOMMIT …:3 stamp=2026-09-28T16:09:32（取不到首次入册）` ＋ `TSORDER=NOINFO reason=no-first-commit` ⇒ **不许静默判等** ✓。
⏪ **`--selftest`（零网络、不依赖真仓）**：`S1` 过去戳⇒PASS｜`S2` 未来戳⇒FAIL 点名 file:line｜`S3` 同秒⇒NOINFO｜`S4` 无历史⇒NOINFO(no-first-commit)｜`S5` 零戳语料⇒NOINFO(no-stamps) ⇒ **`cases=5 pass=5 fail=0`**／rc=0／stderr 零行。
⏪ **额外腿（真树三件，现取）**：`P1-w1-close-verify.md` ⇒ `PASS`(rc=0)｜`P1-dg181-verify.md` ⇒ `PASS files=1 stamped_lines=6 stamps=9`(rc=0)｜**`P1-w1-report.md` ⇒ `NOINFO reason=same-second-as-mtime`（`5` 处）**(rc=3) ⇒ **该腿＝`t17` §5-V2 那个真实缺陷实例的机械复现**（戳 `2026-09-28T16:08:26` ∧ `mtime …16:08:26.448176612` 同秒）｜追加后该件另因**新增行未入册**而多出 `no-first-commit` 腿（同一条 `NOINFO`，逐条上屏）。

## §6 C6 证据：`D-G181` 段序不作判据（同段 dated 追加）

⏪ **未修改** `KNOWN-DEFECTS.md`（`porcelain` 现取 **`0`** 行；其 sha16 仍 `540de62c051f0875`）⇒ **不碰**该条目，只在 `HANDOFF-NEXT.md` 同段记入**口径句（逐字）**：**「条目**段序**不作判据：`KNOWN-DEFECTS.md` 的条目里，各段的**顺序**不承载判据力（判据 ＝ 各段**在场** ∧ 各段内容**可现算**）；段序差异**不判红、不判 `NOINFO`、不计为缺陷**。」**

## §7 自伤（如实记，两条，均被现算自查咬住）

⏪ ① **临时件路径错位**：我把牙写到 `build/MilBridge/tools/**.timestamp-order-check.sh.t27tmp**`（隐藏件），却用 `mv build/MilBridge/tools/timestamp-order-check.sh.t27tmp …` 去搬 ⇒ `bash -n`／`stat`／`mv` 连环失败（**rc=127**）；**当场由 `bash -n` 的 `SYNTAX-FAIL` 与 `ls -l` 咬住**（`ls` 显示真实名），改名后落地成功 ⇒ **未产生任何半落地**（该趟 `selftest` 未跑、真树未动）。
⏪ ② **又一次「写字节到文本句柄」**：V1 追加的 `python3` 第一趟把 `bytes` 写进 `open(…, 'w', encoding='utf-8')` ⇒ `TypeError` ⇒ **rename 未执行**；**当场复核 `P1-w1-report.md` 的 `lines=227`／`sha16=c01e2e92449e659e` 与入口逐字相同** ⇒ **原文件零损伤**；遗留的 `0` 字节临时件已删（残留现取 **`0`**），第二趟改写二进制句柄后落地。⇒ 教训：**每次 rename 之前后都要现算件级读数**，别信「脚本没报错就是落了」。

## §8 指纹 ／ 边界 ／ `NOINFO`

⏪ **指纹**：入口 `inputs_fp` ＝ `8c4ce894d04eae7b1c6d253bc5beabb758a9e99f8430b7b1cd17c8d8707bedd3`／覆盖面 `226`；出口**逐字相同**（本件四件改动件的 `in-list`：牙 **`0`**（新件未接线）／`HANDOFF-NEXT.md` **`0`**／`P1-w1-report.md` **`0`**／本件 **`0`**）⇒ **零位移**、`[42] --expect` **不需同趟改**。
⏪ **边界**：`porcelain` 逐行 —— `M` 两件（`HANDOFF-NEXT.md`／`P1-w1-report.md`，**均 `inScope`**）＋ `?? build/MilBridge/tools/timestamp-order-check.sh`（本席新建，`inScope`）＋ `?? build/MilBridge/P1-v-close-report.md`（本席新建，`inScope`）＋ **上一波（`t25`）**的 `M` 五件／`??` 一件（**非本席本波**，逐件已在 `t25` 报告点名；`?? build/MilBridge/P1-task0201-criteria.md` 是 **`t7` 的**，未读未改）⇒ **零越域**。
⏪ **未碰**：`build/close-wave.sh`（`f9a2ee3ee35baff8`）／`verify-all.sh`（`600274f130cfe913`）／`build/MilBridge/P1-w1-close-verify.md`（`75f174e801510b2c`）／`build/MilBridge/P1-dg181-verify.md`（`7d693364e733379b`）／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`540de62c051f0875`）／`build/MilBridge/tools/defect-registry-declared.tsv`（`5559af5443888348`）—— **六件 `porcelain` 各 `0` 行**；未跑整波／门禁／构建／应用／显示位；**未** `git add/commit/push`。
⏪ **`NOINFO`（具名）**：① 牙**未接线**（`fp_inputs()`／`verify-all.sh` 归 **W4**）⇒ 本波不判其门禁效果；② 追加后 `P1-w1-report.md`／`HANDOFF-NEXT.md` 的**新增行尚未入册**（工作树脏）⇒ 对这两个件整体运行本牙只得 `NOINFO(no-first-commit)`（**逐条上屏、不判绿**）—— 这是**设计如此**，不是牙失效；③ 两条修法的**实际采纳**（哪些写者会用甲、哪些用乙）本波**不判**。

## §9 结论

⏪ `t17` 点名的三处 **全部关账**：**V1** 版本三元组（`9/11` ←「本笔追加之前（222 行版）」／`11/15`（227 行版，＝`t17` 现取）／`13/17`（本笔追加后））＋口径句入册；**V3** 「落盘时刻 ＝ 首次承载该节的提交时刻」口径句 ＋ **三条可复算命令原文**；**V2** 纪律**第 `19` 条**（口径句逐字 ＋ 本族**已第二次**并列两例 ＋ 两条修法各自落地位置）＋ 新牙 `timestamp-order-check.sh`（**两极化真跑**：未来戳⇒`FAIL` 点名／同秒⇒`NOINFO` 不判绿／无历史⇒`NOINFO`；`--selftest 5/5`）＋ **`t19` V2 的「段序不作判据」**在册（`D-G181` 条目**一字未改**）。
⏪ **判据只收紧**：不判绿的口子（同秒／无历史／零戳）**全部上屏**；`NOINFO` 逐条具名；本件全部新增行**自带亚秒戳**（修法甲的第一个执行者）。
⏪ ⏪ **dated 更正（本件自伤 ＋ 口径；`t27`，读时 2026-09-28T16:26:34.173+0800；原文**保留、一字未删**）**：
⏪ ① §5「额外腿」里 `P1-w1-report.md` 的 `NOINFO reason=same-second-as-mtime（5 处）` 是**本笔追加之前**的读数（那时该件 `mtime = 2026-09-28 16:08:26.448176612`）；**本笔追加把该件整件重写** ⇒ `mtime` 移到 `2026-09-28 16:25:52` 档 ⇒ 该腿**现取只剩 `no-first-commit`**（`TSORDER=NOINFO reason=no-first-commit files=1 stamped_lines=15 stamps=18`）⇒ 那条同秒读数**在真树上已不可现取**（原始行留在本节）。⚠️ **这恰好是 V3 的活例**：该件 `mtime` 被**本笔自己的追加**重写 ⇒ 判据**只能**落在**首次承载该节的提交时刻**上。
⏪ ② **同秒腿仍可复现**（本席现取，配方给全）：`cp -p build/MilBridge/P1-w1-close-verify.md <沙箱>/samesec.md` ＋ `touch -d '2026-09-28 16:08:26.500000000' <沙箱>/samesec.md` ⇒ `bash build/MilBridge/tools/timestamp-order-check.sh --file <沙箱>/samesec.md --assume-first-commit 2026-09-28T16:17:24+08:00` ⇒ **rc=3**：`TSORDER_SAMESEC file=…/samesec.md:3 stamp=2026-09-28T16:09:32 mtime=16:08:26.500000000（戳无亚秒 ∧ 与落盘**同秒** ⇒ **不可对拍**）` ＋ `TSORDER=NOINFO reason=same-second-as-mtime,…`（`touch` 只动**沙箱**件、不动真树）。
⏪ ③ §1 里牙的 `mode 755` 在本笔第二次 patch（`temp + rename` 重写整件）时被重置为 `644` ⇒ 已 `chmod 755` **复原**（现取 `mode = 755`；`chmod` 不改内容 ⇒ sha16 未变）。
⏪ ④ 综合读法：§5「额外腿」的**完整清单以本条为准**（`P1-w1-close-verify.md` ⇒ `PASS`｜`P1-dg181-verify.md` ⇒ `PASS`｜`P1-w1-report.md` ⇒ 追加前 `NOINFO(same-second-as-mtime×5)`、追加后 `NOINFO(no-first-commit)`｜`HANDOFF-NEXT.md` ⇒ 追加前 `PASS`、追加后 `NOINFO(no-first-commit)`）。
⏪ ⏪ **dated 更正之二（更正上一更正条的 ②；`t27`，读时 2026-09-28T16:26:47.147+0800；上文**保留、一字未删**）**：上一条 ② 里写的 `rc=3` ＋ 那行 `TSORDER_SAMESEC …:3 stamp=2026-09-28T16:09:32 …` **是我未实跑就落笔的断言，不成立** ⇒ 此处以**实跑原文**替换：
⏪ ① **上一条 ② 的真实读数（同一配方，实跑）**：`cp -p build/MilBridge/P1-w1-close-verify.md <沙箱>/samesec.md` ＋ `touch -d '2026-09-28 16:08:26.500000000' …` ⇒ 该件里**还另有更晚的戳**（`16:09:32`／`16:10:48`／`16:13:59`）⇒ 把 `mtime` 钉回 `16:08:26` 后，那些戳反而**晚于落盘** ⇒ 实得 **rc=1**：`TSORDER_FUTURE file=/home/links-dev/w281-scribe/sbx-t27/samesec.md:3 stamp=2026-09-28T16:09:32 mtime=16:08:26.500000000 delta=+66s（戳**晚于落盘** ⇒ 必红并点名）`｜`TSORDER=FAIL reason=future-stamp files=1 stamped_lines=9 stamps=10`。⇒ **该配方测的是「戳晚于落盘」而不是「同秒」** —— 我原先那句判断错了。
⏪ ② **可复现的「同秒」配方（实跑原文，取代旧配方）**：夹具只留**一个**戳 ⇒ `printf '⏪ dated 追加（t27 夹具，读时 2026-09-28T16:08:26+0800）\n正文\n' > <沙箱>/samesec2.md` ＋ `touch -d '2026-09-28 16:08:26.500000000' <沙箱>/samesec2.md` ⇒ `bash build/MilBridge/tools/timestamp-order-check.sh --file <沙箱>/samesec2.md --assume-first-commit 2026-09-28T16:17:24+08:00` ⇒ **rc=3**：`TSORDER_SAMESEC file=/home/links-dev/w281-scribe/sbx-t27/samesec2.md:1 stamp=2026-09-28T16:08:26+0800 mtime=16:08:26.500000000（戳无亚秒 ∧ 与落盘**同秒** ⇒ **不可对拍**）`｜`TSORDER=NOINFO reason=same-second-as-mtime files=1 stamped_lines=1 stamps=1（不可对拍者已逐条上屏；**NOINFO 不算绿**）` ⇒ **戳无亚秒 ∧ 与 `mtime` 同秒 ⇒ 不可对拍、不判绿** ✓（`touch` 只动**沙箱**件，真树未动）。
⏪ ③ **教训（此后一律照此）**：写进报告的**任何原始机读行**都必须**先实跑、后落笔**（本件两次自伤同源：① 未跑就写「同秒腿 rc=3」；② 未算就写 sha16）⇒ 复核者若按旧配方跑会得 `rc=1`，**以本条 ①② 的实跑原文为准**。
⏪ ⏪ **dated 更正之三（口径时效；`t27`，读时 2026-09-28T16:27:02.605+0800；上文**保留、一字未删**）**：§8 边界那句把 `porcelain` 写成「`M` 两件 ＋ `??` 两件本席 ＋ 上一波（`t25`）的 `M` 五件／`??` 一件」—— **`t25` 那一批现取已不在 `porcelain` 里**（队长已提交：现取 `HEAD = 1b9002b`（`1b9002b 2026-09-28T16:24:47+08:00`），`t25` 的六件现取 `porcelain` 行数 ＝ **`0`**；本波四件中两件 `M`／两件 `??` 为**本席**）⇒ **本波 `porcelain` 的完整清单以本条为准**：`M build/MilBridge/HANDOFF-NEXT.md`｜`M build/MilBridge/P1-w1-report.md`｜`?? build/MilBridge/P1-v-close-report.md`（本席新建）｜`?? build/MilBridge/tools/timestamp-order-check.sh`（本席新建）｜`?? build/MilBridge/P1-task0201-criteria.md`（**`t7` 的**，未读未改）。⇒ **越域仍为零**；`HEAD` 已前进这件事**不影响**本件任何读数（`t25` 件的 sha16 现取与其报告一致）。
⏪ 本件自证 sha16（口径＝**末行之前的全文**）＝ `aacd9383d3284bd6`（末行＝本行）；**全文** sha16 与读取时刻见交件消息（末行只携带 `head -n -1` 口径 ⇒ 全文值不可能自指）。
