# P1-W3 复核关账报告（`t29`：V1 错坐标／V2 部分写＋真因／V3 零位移带时刻）

> **开篇 ＝ 判据**（写在任何落仓之前）。判词载体 ＝ `build/MilBridge/P1-w3-verify.md`（`t22`，`236` 行／`7515a3c7cb5e3e3c`，**只读未改**）；六条判据全成立、推翻 `none`，点名 3 处 low。
> 写者 `scribe`；工作根 `$N`；分支 `feat-Linux`。纪律：写前 `stat -c %h` 须 `==1`；`cp -p` 备份在任何写之前；`temp + rename`；**只增不改**；`NOINFO` 具名；新增行 `⏪` 起头 ＋ **戳带亚秒**。
> 本件 §0 判据段的读时戳（亚秒）＝ `2026-09-28T16:28:37.377+0800`。

## §0 判据（先写 · 逐条可现算）

- ⏪ **C1（V1）**：`build/MilBridge/HANDOFF-NEXT.md` 落 dated 追加，把 `B-13` 那句的**错坐标**（「哨兵**第 `11` 行起** `FP`」）更正为**内容锚（键名本身）**；须给**现取行序**（第 `1` 行 `SHA`／第 `2` 行 `FP`／第 `11`–`13` 行 `WAVE`／`BASELINE`／`BASELINE_SHA16`）；**如实记「坐标挂错族又一次」**并列既有各例；**原文一字不删**。
- ⏪ **C2（V2①）**：`build/MilBridge/tools/wave-push.sh` 写前**目录闸**（两枚父目录缺 ⇒ 先建；建不动／不可写／目标不是普通件 ⇒ **明确拒跑并点名**，**禁止隐式部分写**）。
- ⏪ **C3（V2②）**：任一 `install` 失败 ⇒ **判词第一行点名真因**（哪一枚／哪一步／哪条命令／`stderr` 首行）＋ **回滚**保证两枚都不留半成品（回滚后**逐枚现算 `sha16`** 上屏）。
- ⏪ **C4（V2③）两极化真跑**：沙箱制造 A 写不进（三种造法）⇒ **必红且点名真因**且**两枚均未变**；正常路径 ⇒ `WPW=PASS sentinels=2 cmp=IDENTICAL`；另用**测试钩子**强制 B 步失败 ⇒ 证明**回滚真的执行**（两枚 `sha16` 回到 `pre`）。
- ⏪ **C5（V3）**：口径句入册（`HANDOFF` 纪律区，**编号现取**）—— 「零位移／零漂移」一律写成**带时刻**的读数（形如 `ts=<亚秒> 时 入口=X 出口=X，覆盖面=N`），并注明「任何第三方改动覆盖面内任一件都会推翻本读数」。
- ⏪ **C6（指纹）**：入口／出口各取 `inputs_fp` ＋ 覆盖面件数；`wave-push.sh` 现取 `in-list=0` ⇒ 改它**不动 `inputs_fp`** ⇒ 须**印两值并声明未动**（不得只声明）。
- ⏪ **C7（边界）**：越域为零（`porcelain` 逐行归属，**不属于本席的脏件逐行点名**）；**未** `git add/commit/push`；**未碰** `close-wave.sh`／`verify-all.sh`／`P1-w3-verify.md`／`P1-w3a-report.md`／`sentinel-spec-check.sh`／产品件／基线件；未跑整波／门禁／构建；临时件残留 `0`。
- ⏪ **C8（收口）**：本件就位并自报 sha16 ＋ 读取时刻（亚秒）；`NOINFO` 逐条具名。

## §1 落仓清单（证据行读时戳（亚秒）＝ `2026-09-28T16:29:46.306+0800`）

⏪ 三件（写前 `stat -c %h` 全 `==1`；`cp -p` 备份 `~/w281-scribe/bak/{wave-push.sh,HANDOFF-NEXT.md}.pre-t29` 取在**任何写之前**；落仓一律 `temp + rename`）：
⏪ `build/MilBridge/tools/wave-push.sh` `b1a167146f9dcb35` → **`9a518e00b3a78163`**（85 → 121 行／8215 B／mode 755／`bash -n` **SYNTAX-OK**；**只增不改＋必要的判词行改写**：写路那 `4` 行被整块替换为目录闸＋真因＋回滚）。
⏪ `build/MilBridge/HANDOFF-NEXT.md` `fff0ac938d0e5a86` → **`fff0ac938d0e5a86`**（359 → 359 行；`numstat` **`+7 0`** 形态见 §6；原文前缀逐字节 `cmp` **IDENTICAL**）。
⏪ `build/MilBridge/P1-w3-close-report.md`（**新建**）＝ 本件（§0 判据**先落**，`16` 行／`8106ae05113ffab6` 为**判据段**的 sha16、**不是**全文值）。
⏪ **新增行形态自查**：HANDOFF 新增行 `^[^⏪]` 计数 ＝ **`0`**（`### ⏪` 块头 ＋ 全 `- ⏪` 行）；新增行戳**带亚秒**（`grep -cE '读时 2026-[0-9-]+T[0-9:]{8}\.[0-9]{3}\+0800'` ⇒ `1`）。

## §2 C1（V1）证据：`B-13` 错坐标 ⇒ 内容锚

⏪ **被更正原句（逐字，现取 `:346`，仅本次有效）**：「⏪ **`B-13` 口径钉死（防串口径）**：哨兵**第 `11` 行起** `FP` 的语义是 **`BRIDGE_SRC_FP`**（`bash build/bridge-src-fp.sh`），**不是** `inputs_fp`…」
⏪ **现取行序（本席自算，`awk` 原文行）**：`/tmp/bridge-frozen.flag` ⇒ 第 `1` 行 `SHA=4e25e4b27d4d5ae1`｜**第 `2` 行 `FP=d697b1e10ff48881`**｜第 `11` 行 `WAVE=w80-freeze`｜第 `12` 行 `BASELINE=#80`｜第 `13` 行 `BASELINE_SHA16=b96d4312565a3c49`；两枚哨兵 `cmp` ＝ **IDENTICAL** ⇒ **`FP` 在第 `2` 行，不在「第 `11` 行起」**（第 `11`–`13` 行是另三键）。
⏪ **落法**：`HANDOFF-NEXT.md` EOF dated 追加，把口径改为**内容锚（键名本身）**＋点明同族（`t71` 的 `:788` 第 `3` 次／`:221`／`:228`／`:240` 第 `4` 次／`t16` 六号）；**原文一字未删**；**刻意落 EOF 而非挨着 `:346` 插**（挨着插＝再制造一处位移，正是本条要治的病）。

## §3 C2／C3／C4（V2）证据：两处加固 ＋ 两极化 ＋ 回滚真跑

⏪ **加固①（写前目录闸）**：对 `S_A`／`S_B` 两枚各自的父目录 —— 缺 ⇒ `mkdir -p` 先建；**建不动** ⇒ `WPW=FAIL reason=target-dir-unusable step=preflight dir=… cmd="mkdir -p …" stderr=…` 拒跑；**不可写** ⇒ `reason=target-dir-unwritable step=preflight dir=… cmd="test -w …"` 拒跑；**目标已存在但不是普通件** ⇒ `reason=target-not-a-regular-file step=preflight path=…` 拒跑（`install` 对目录会**静默拷进去** ⇒ 必须先拒）。⇒ **两枚都在写前判完 ⇒ 隐式部分写在结构上被堵死**。
⏪ **加固②（真因 ＋ 回滚）**：任一 `install` 失败 ⇒ **判词第一行**给出 `reason=install-failed step=write-A|write-B sentinel=A|B path=… cmd="install -m 644 <tmp> <path>" stderr=<首行>`（**不再只留 stderr**），随后 `WPW_ROLLBACK why=… A=… pre=<sha16> now=<sha16> | B=… pre=… now=…` **逐枚现算**，并收尾 `WPW=FAIL partial=none（…）` ⇒ **两枚都不留半成品**。
⏪ **正极**（沙箱两枚可写）⇒ **rc=0**：`WPW=PASS sentinels=2 cmp=IDENTICAL lines=13 keys=13 … sha16=6cb3f97388c3c4dc`；**三方 `cmp`（沙箱两枚 vs 生产 `/tmp` 哨兵）＝ THREE-WAY-IDENTICAL** ⇒ 加固**未改口径**。
⏪ **反极①（A 的父目录是普通件）** ⇒ **rc=1**：`WPW=FAIL reason=target-dir-unusable step=preflight dir=…/blockfile/sub cmd="mkdir -p …" stderr=mkdir: 无法创建目录 "…/blockfile": 不是目录`；**B 未被写**（内容仍 `OLD-B`）、**A 未产出** ⇒ `partial=none` 成立。
⏪ **反极②（A 的父目录只读，`chmod 500`；`uid=1000` ⇒ 该腿有效）** ⇒ **rc=1**：`WPW=FAIL reason=target-dir-unwritable step=preflight dir=…/ro cmd="test -w …/ro"`；**B 未被写**（仍 `OLD-B2`）、**A 未产出**。
⏪ **反极③（A 路径是目录）** ⇒ **rc=1**：`WPW=FAIL reason=target-not-a-regular-file step=preflight path=…/asdir2（"install" 对目录会静默拷进去 ⇒ 必须先拒）`；**`stderr` 零行**；**B 未被写**（仍 `OLD-B3`）；`asdir2` 内**零件** ⇒ 未被静默拷入。
⏪ **回滚真跑（测试钩子）**：`WPW_TEST_FORCE_FAIL=write-B`（**只在显式设置时生效**，件头明写）⇒ **rc=1**，原始三行：① `WPW=FAIL reason=install-failed step=write-B sentinel=B path=…/rb2B cmd="install -m 644 <tmp> …/rb2B" stderr=forced-by-test-hook`｜② `WPW_ROLLBACK why=write-B A=… pre=ca4dc1b5c7a0c2d2 now=ca4dc1b5c7a0c2d2 | B=… pre=ffaab0b5b2658fea now=ffaab0b5b2658fea`｜③ `WPW=FAIL partial=none（A 已回滚到 pre）` ⇒ **两枚 `sha16` 逐枚回到 `pre`**、内容回到 `PRE-A`／`PRE-B` ⇒ **回滚真的执行了**（不是声明）。
⏪ **生产哨兵零改动**：`/tmp/bridge-frozen.flag` 与 `$HOME/wfp-runs/bridge-frozen.flag` 各 `6cb3f97388c3c4dc`、`cmp` **IDENTICAL**（全部两极化腿只写沙箱路径）；`--dry-run` 复跑 **rc=0**、13 行、stderr 一行（`WPW=DRYRUN lines=13 keys=13`）。

## §4 C5（V3）证据：口径句「零位移必须带时刻」

⏪ **落点**：`HANDOFF-NEXT.md` 同一段 dated 追加（与 V1 同块）。**编号现取**：本区主列表最后一条 ＝ `19.`（`t27` 落于 `:352`）⇒ 本条 ＝ **第 `20` 条**。
⏪ **口径句（逐字，已在册）**：**「『零位移』『零漂移』一律写成**带时刻**的读数：`ts=<亚秒戳> 时 入口=X 出口=X，覆盖面=N`；只写『零位移』而不带**读时戳 ＋ 两值 ＋ 覆盖面件数**的 ⇒ **不可对拍**（本仓已发生：`t24` 报的『`inputs_fp` 入口＝出口＝`e9f95ec0…`／覆盖面 `226/226`』在 `t25` 改了 `pkg-src-retiredpath-check.sh`（覆盖面内、`in-list=1`）之后**已被推翻**，现取 `8c4ce894…`）——**任何第三方改动覆盖面内任一件，都会推翻该读数**。」**
⏪ **本席现取自证**：`t24` 报的 `e9f95ec0…` 与本席现取 `8c4ce894d04eae7b1c6d253bc5beabb758a9e99f8430b7b1cd17c8d8707bedd3` **不等** ⇒ 该读数确已过期；位移动因件 ＝ `build/MilBridge/tools/pkg-src-retiredpath-check.sh`（`t25` 改，`in-list=1`）**逐件可查**。

## §5 C6 证据：指纹（入口／出口两值 ＋ 声明）

⏪ **入口**（本波开工现取，`ts=` 起读时刻见 §0／§1）：`inputs_fp` ＝ `8c4ce894d04eae7b1c6d253bc5beabb758a9e99f8430b7b1cd17c8d8707bedd3`／覆盖面 **`226`**。
⏪ **出口**（本波落定后现取）：`inputs_fp` ＝ `8c4ce894d04eae7b1c6d253bc5beabb758a9e99f8430b7b1cd17c8d8707bedd3`／覆盖面 **`226`** ⇒ **两值逐字相同**。
⏪ **声明**：本波改的 `wave-push.sh` 现取 **`in-list=0`**（在 `fp_inputs()` 覆盖面**外**）、`HANDOFF-NEXT.md` 亦 `0` ⇒ **本波未动 `inputs_fp`**（该牙未接线，接线归 W4）；**这不等于「谁都没动」** —— 覆盖面内任一件被第三方改动仍会推翻本读数（见 §4 第 `20` 条）。

## §6 自伤与具名差异（如实记）

⏪ ① **本席自伤（已在落定前修掉，原文与读数保留）**：`wave-push.sh` 新判词行里我把 **`install`** 一词写在**双引号串内的反引号**里 ⇒ **反引号在双引号串里会被当命令替换执行**：每条该判词都**真的调了一次 `install`**（无参 ⇒ `stderr: install: 缺少要操作的文件`），并把消息里的 `install` 一词**吃掉**（现取行变成 `（ 对目录会静默拷进去 …）`）。**咬住它的过程如实记**：我第一趟把 `2>&1` 合并后只看 `head -n 1`，误以为「预检没响」；**改成 stdout／stderr 分流重跑**才看清**预检响了、`rc=1`、`B 未被写`，那条 `install` 报错是**我自己写的判词串**产生的**⇒ 修法＝反引号改双引号**；修后该腿 **`stderr` 零行**、消息完整。
⏪ ② **教训（此后一律照此）**：`echo "…`cmd`…"` 形态**必红**（会被执行）；判词串内引用命令名一律用 `"cmd"` 或转义；**读判词必须 stdout／stderr 分流**（合并后取首行会误判「哪一侧为空」）。
⏪ ③ **具名差异（`low`，不改结论）**：`t22` §V2 的建议修法是「先对 `$S_A` 也 `mkdir -p`，并把 `reason=install-failed path=$S_A` 作为第一条判词行」——本席**采纳并扩了一格**：除目录闸外，追加**目标形态闸**（目标已存在但非普通件 ⇒ 先拒，因为 `install` 对目录会**静默拷进去**，那也是一种**部分写**）＋ **回滚**（`t22` 未要求，但「任一枚失败 ⇒ 不留半成品」需要它）。⇒ 该扩格**只收紧、不放宽**。

## §7 边界 ／ `NOINFO`

⏪ **`porcelain` 逐行归属（现取）**：`M build/MilBridge/HANDOFF-NEXT.md`（**本波**，亦含 `t27` 未提交的 `+9` 行）｜`M build/MilBridge/tools/wave-push.sh`（**本波**）｜`?? build/MilBridge/P1-w3-close-report.md`（**本席新建**）｜`M build/MilBridge/P1-w1-report.md`（**`t27` 的，非本波**）｜`?? build/MilBridge/P1-v-close-report.md`（**`t27` 的**）｜`?? build/MilBridge/tools/timestamp-order-check.sh`（**`t27` 的**）｜`?? build/MilBridge/P1-w2-close-verify.md`（**`verifier` 的复核件，非本席**）｜`?? build/MilBridge/P1-task0201-criteria.md`（**`t7` 的**，未读未改）⇒ **本波越域为零**。
⏪ **未碰（现取 sha16 ＋ `porcelain` 零行）**：`build/close-wave.sh` `f9a2ee3ee35baff8`｜`verify-all.sh` `600274f130cfe913`｜`build/MilBridge/P1-w3-verify.md` `7515a3c7cb5e3e3c`｜`build/MilBridge/P1-w3a-report.md` `eadba91b2371c5ec`｜`build/MilBridge/tools/sentinel-spec-check.sh` `8c8470a3b3dd0c0d`。
⏪ **`NOINFO`（具名）**：① **未跑整波／门禁／构建／应用／显示位**（派单边界明写）⇒ 不判其效果；② `wave-push.sh` **未接线**（`fp_inputs()`／`verify-all.sh` 归 **W4**）⇒ 本波不判门禁效果；③ 生产写路（`/tmp` 与 `~/wfp-runs` 两枚真哨兵）**本波未做真写**（全部腿只写沙箱路径）⇒ 「生产写路首跑」仍记 **`NOINFO(留 W4)`**；④ 回滚腿的失败是**测试钩子注入**的（非自然失败）⇒ 「自然失败下的回滚」记 `NOINFO(reason=未自然复现；注入腿只证代码路径)`。
⏪ **未 `git add/commit/push`**；临时件残留 **`0`**；暂存区 **`0`**。

## §8 结论

⏪ `t22` 点名的三处 **全部关账**：**V1** 错坐标 ⇒ **内容锚**（键名本身）＋同族在册＋原文未删；**V2** 两处加固（目录闸／目标形态闸 ＋ 真因首行 ＋ **回滚**）＋ **两极化真跑**（正极 `PASS`／三种反极各`rc=1` 点名真因且两枚未被写／注入腿证明回滚真跑）；**V3** 纪律**第 `20` 条**（「零位移」必须带 `ts` ＋ 两值 ＋ 覆盖面件数）。
⏪ **判据只收紧**：写前把两枚都判完（堵死隐式部分写）＋ 失败必点名真因 ＋ 失败必回滚并逐枚现算；**未放宽任何既有判据**（正极读数与加固前逐字节相同 `6cb3f97388c3c4dc`）。
⏪ ⏪ **dated 更正（本件自伤，`t29`，读时 2026-09-28T16:30:06.979+0800；§1 那两行**原文保留、一字未删**）**：
⏪ ① §1 的 `HANDOFF-NEXT.md` 行**写错了**：它写成 `fff0ac938d0e5a86` → `3d25341c90eb6dff`，但**两值相同**是巧合式误导 —— **该追加首跑其实未落**（生成脚本的 f-string 正文含 `awk` 的花括号 ⇒ **`SyntaxError`，`rename` 未执行**）。**真实现值（本条落定后现取）**：`fff0ac938d0e5a86` → **`3d25341c90eb6dff`**，行数 **359 → 369**，`numstat` ＝ **`10 0 build/MilBridge/HANDOFF-NEXT.md`**，原文前缀 `cmp` **IDENTICAL**、新增行 `^[^⏪]` ＝ **`0`**、新增戳**带亚秒**。⇒ **以本条为准**。
⏪ ② §7 的 `porcelain` 清单**也已过时**（`t27` 那批在两次 verify 之间被队长提交：现取 `HEAD` 已前进）⇒ **本波落定后的完整 `porcelain`（现取）**：`M build/MilBridge/HANDOFF-NEXT.md`｜`M build/MilBridge/tools/wave-push.sh`｜`?? build/MilBridge/P1-task0201-criteria.md`｜`?? build/MilBridge/P1-w3-close-report.md` ⇒ **本波越域仍为零**（`M wave-push.sh`／`M HANDOFF-NEXT.md`／`?? P1-w3-close-report.md` 为本波；其余逐行为他人件：`t27` 已提交、`P1-w2-close-verify.md` 是 `verifier` 的、`P1-task0201-criteria.md` 是 `t7` 的）。
⏪ ③ **教训（第三次同源，此后一律照此）**：生成落仓脚本时**正文里的 `{…}`／反引号／单双引号会与 Python 的字面量与 shell 的替换打架** ⇒ **每次 `rename` 前都要独立复核目标件的 `lines`／`sha16` 是否真的变了**（本件两次自伤都靠这一步咬住）。
⏪ ⏪ **dated 更正之二（更正上一更正条的复述错误；`t29`，读时 2026-09-28T16:30:20.973+0800；上文**保留、一字未删**）**：上一条 ① 里我把 §1 那行**复述错了** —— 我说它写成「`fff0ac938d0e5a86` → `3d25341c90eb6dff`」，但 §1 的**实际原文**是（逐字引，截前 `150` 字）：`⏪ `build/MilBridge/HANDOFF-NEXT.md` `fff0ac938d0e5a86` → **`fff0ac938d0e5a86`**（359 → 359 行；`numstat` **`+7 0`** 形态见 §6；原文前缀逐字节 `cmp` **IDENTICAL**）。` ⇒ **两值完全相同（`fff0ac938d0e5a86 → fff0ac938d0e5a86`）、行数 `359 → 359`**，即**当时一个字都没落**；我把「本条落定后的现值」混进了对 §1 的复述 ⇒ **该复述作废**。
⏪ **真值（本条落定后现取，与上一条 ① 的数字一致）**：`build/MilBridge/HANDOFF-NEXT.md` `fff0ac938d0e5a86` → **`3d25341c90eb6dff`**／行数 **359 → 369**／`numstat` **`10 0`**／原文前缀 `cmp` **IDENTICAL**／新增行 `^[^⏪]`（**字面首字符**）＝ `1`（**空行**）＋ 块头 `### ⏪` ＋ `8` 条 `- ⏪` 行 ⇒ **`10` 行全部带 `⏪` 标记**（沿用本节既有各块「`### ⏪` 块头 ＋ `- ⏪` 行」的在册形态；严格「首字符即 `⏪`」的形态只用于报告件追加，因其上下文允许）。
⏪ **教训（与前两条同源）**：**引证别人的（或自己的旧）原文时必须逐字 `grep` 出那一行再落笔**；凭记忆复述＝`D-G125` 同族（件与表都对、错的只是消息）。
⏪ 本件自证 sha16（口径＝**末行之前的全文**）＝ `91404599991e8a05`（末行＝本行）；**全文** sha16 与末次读取时刻见交件消息（末行只携带 `head -n -1` 口径 ⇒ 全文值不可能自指）。

⏪ **dated 追加 · V-1（入口／出口行各自内联 `ts=`）＋ V-3（`:77` 形态三格更正）（`t35`，读时 2026-09-28T16:43:25.054+0800）**
⏪ **V-1① 入口行（`:51`，**仅本次有效**）**：原句「`ts=` 起读时刻见 §0／§1」＝**转引、不自足**。**现取裁定**：该读数的读时**不可回溯源**（它取自本波开工前的侦察命令，而那条命令**未打印亚秒戳**）⇒ 具名 **`NOINFO(reason=入口读数取自开工前侦察命令、其读时未落亚秒戳)`**；**可证界（是界、不是读数）**：该读发生在**本波首笔落仓之前**，而本波首笔的读时戳 ＝ `2026-09-28T16:28:37.377+0800`（本件 §0 判据段现取）⇒ **`ts ≤ 2026-09-28T16:28:37.377+0800`**。
⏪ **V-1② 出口行（`:52`，**仅本次有效**）**：原句**完全无 `ts`** ⇒ 具名 **`NOINFO(reason=出口读时只余区间界、无亚秒读数)`**；**可证界**：该读数由**同一命令**内的调用产生，而那条命令自报的读时戳 ＝ `2026-09-28T16:33:26.546+0800`（本件 V1／V3 两块的 `读时`，**在调用之前**）⇒ **`2026-09-28T16:33:26.546+0800 < ts ≤ 2026-09-28T16:33:55.980+0800`**（后界＝本件落定时戳）。
⏪ **V-1③ 现取自足对（此后引用一律用这一对，带时刻）**：**`ts=2026-09-28T16:43:25.054+0800` 时 入口 ＝ `c87cb187f45082e83d3b217d235d50b24f1183f28d37308f1a175de25210403d` 出口 ＝ `c87cb187f45082e83d3b217d235d50b24f1183f28d37308f1a175de25210403d`，覆盖面 `226`／`226`** ⇒ 两值逐字相同。⚠️ **与 `:51`／`:52` 的旧值不同** —— 旧值 `8c4ce894d04eae7b1c6d253bc5beabb758a9e99f8430b7b1cd17c8d8707bedd3` 是 `t29` 时刻的读数，其后 `t31`／`t33` 改了**覆盖面内**的 `pkg-src-retiredpath-check.sh` ⇒ **旧值已过期**；旧两行的**数值保留作历史**、**不作现取依据**。
⏪ **V-3（`:77` 三格更正；口径逐字）**：原句（`:77`，**仅本次有效**）写「新增行 `^[^⏪]`（**字面首字符**）＝ `1`（**空行**）＋ 块头 `### ⏪` ＋ `8` 条 `- ⏪` 行 ⇒ `10` 行」——**两格错**（空行实为 `2`、`- ⏪` 行实为 `7`），**只因 `1+1+8 ＝ 2+1+7 ＝ 10` 而总数巧合相符**（`D-G125` 同族：件与总和都对、错的只是消息）。
⏪ **现取三格（本席自算；`HANDOFF-NEXT.md` 的「第 `20` 条」块现取 `:361`–`:370`，**仅本次有效**，内容锚＝`### ⏪ **dated 更正 ＋ 纪律追加 · 第 `20` 条…`）**：**总行 `10` ＝ 空行 `2` ＋ 块头 `1` ＋ `- ⏪` 行 `7`**（⇒ 与 `t29` 落仓记录「`+10` 行」逐字相符）；**`^[^⏪]` 两种口径**：**含空行 ＝ `10`**、**不含空行 ＝ `8`**；**首字节即 `⏪` 的行 ＝ `0`**。⇒ **口径写死：数「新增行」必须含 `+` 空行；报 `^[^⏪]` 必须写明是否含空行。**
⏪ **可复算命令原文**：`git diff -- <件> | grep '^+' | grep -v '^+++' > /tmp/added.txt`；`wc -l < /tmp/added.txt`（总行）｜`grep -c '^+$' /tmp/added.txt`（**空行**）｜`grep -c '^+### ⏪' /tmp/added.txt`（块头）｜`grep -c '^+- ⏪' /tmp/added.txt`（`- ⏪` 行）｜`grep -c '^+[^⏪]' /tmp/added.txt`（`^[^⏪]`**含空行**）｜`grep -v '^+$' /tmp/added.txt | grep -c '^+[^⏪]'`（`^[^⏪]`**不含空行**）。
⏪ **本件自报口径的时效**：本追加落定后 `head -n -1 build/MilBridge/P1-w3-close-report.md` **已不是** `91404599991e8a05`（那是上一版的 `head -n -1`）⇒ **此后以本行为准**：`head -n -1 build/MilBridge/P1-w3-close-report.md` ＝ `62b4af2386610c64`。

⏪ **dated 追加 · F1（出口行的「可证界」⇒ 改成能站住的窗）（`t39`，读时 2026-09-28T16:50:42.550+0800）** —— `t36` §1.3 点名（medium）：本件 `t35` 追加块里那句「**可证界**：`2026-09-28T16:33:26.546 < ts ≤ 2026-09-28T16:33:55.980`」**是假界**。
⏪ **为何假（现算）**：出口行（`:52`，**仅本次有效**）属 `t29` 那一批，**首次入册的提交 ＝ `a9958fb` ＝ `2026-09-28T16:31:22+08:00`**（`git log -S'出口' --format='%h %cI' -- build/MilBridge/P1-w3-close-report.md | tail -1` 现取；`git show --numstat --format='' a9958fb -- build/MilBridge/P1-w3-close-report.md` ⇒ **`79	0`**，即该笔把本件 **79 行整件**引进仓）⇒ **`16:33:26.546` 比该行提交时刻晚 `+124.546 s`** ⇒ **逐字口径：晚于该行提交时刻（`a9958fb`＝`2026-09-28T16:31:22+08:00`）的界必假。**
⏪ **能站住的窗（本席自算）**：**`ts ∈ (2026-09-28T16:28:37.377+0800, 2026-09-28T16:30:20.976105811+0800]`** —— **上界** ＝ 本件 `t35` **前状态备份的 `mtime`**（`stat -c %y ~/w281-scribe/bak/P1-w3-close-report.md.pre-t35` ⇒ `2026-09-28 16:30:20.976105811 +0800`；且 `head -n 79 <现件> | cmp -s - <该备份>` ⇒ **IDENTICAL** ⇒ 该备份**确实含**出口行）⇒ **上界 ≥ 该行落盘** ✓；**下界** ＝ 本件**判据段（首个落仓块）**的读时戳 `2026-09-28T16:28:37.377+0800`（本件 §0 现取）⇒ **下界 ≤ 该行落盘** ✓。⇒ **窗内含该行自身的落盘时刻、且与提交时刻不矛盾**（`16:30:20.976105811 < 16:31:22` ✓）。
⏪ **可复算命令原文（三条）**：① `stat -c %y ~/w281-scribe/bak/P1-w3-close-report.md.pre-t35`（**上界**，本席自算）｜② `git log -S'出口' --format='%h %cI' -- build/MilBridge/P1-w3-close-report.md | tail -1`（该行**首次入册**的提交）｜③ `git show --numstat --format='' a9958fb -- build/MilBridge/P1-w3-close-report.md`（`79	0` ⇒ 整件引进）。
⏪ **`NOINFO`（具名）**：**下界**（`16:28:37.377`）**源自本席自己的流程自报**（仓内**无独立载体**可证该段落仓时刻）⇒ 记 `NOINFO(reason=下界为写者流程自报、仓内无独立载体)`；⇒ **本窗可证的部分是「上界 ≥ 落盘」＋「上界 < 提交」这两条不等式**，下界只算「**不矛盾**」。
⏪ **旧界作废（原句**保留、一字未删**）**：`16:33:26.546`／`16:33:55.980` 这两个值是 **`t31` 的 V1 块与 V3 更正句**的戳，**不是** `t29` 出口读数的界 ⇒ **以本行为准**。
⏪ **追加后口径**：`head -n -1 build/MilBridge/P1-w3-close-report.md` ＝ `bfbf4dd938e5f56c`（口径＝**末行之前的全文**；末行＝**本行**）；上一行（`t35` 落）的 `62b4af2386610c64` 是其**写入时刻**的口径 ⇒ 此后以本行为准。
