# P1-W2 关账（第二轮）报告 · V1／V2／V3（`t31`）

> **开篇 ＝ 判据**（写在任何落仓之前）。判词载体 ＝ `build/MilBridge/P1-w2-close-verify.md`（`t26`，`245` 行／`b723ae2b2e9a1eab`，**只读未改**）。
> 写者 `scribe`；工作根 `$N`；分支 `feat-Linux`。纪律：写前 `stat -c %h` 须 `==1`；`cp -p` 备份在任何写之前；`temp + rename`；**只增不改**；`NOINFO` 具名；新增行 `⏪` 起头 ＋ **亚秒戳**。
> §0 判据段读时戳（亚秒）＝ `2026-09-28T16:32:32.687+0800`。

## §0 判据（先写 · 逐条可现算）

- ⏪ **C1（V1）**：`build/MilBridge/P1-w2-report.md` 落 dated 追加，给 15 件表**第 `11` 行**那格标注口径（＝`t14` **交付态**值；**同一笔提交的 W2 修法已把它改掉**，现值另给），与第 `15` 行已声明的自指口径**写法对齐**；原文一字不删。
- ⏪ **C2（V2①）**：`pkg-src-retiredpath-check.sh` 的**判词文本**改成**不被自身判据命中**的形态（`path-field-empty` 一族），**同一件内一致**；给出可现算的不变量（`grep -c 'path='` 恰 `1` ＝ 发射端字段）。
- ⏪ **C3（V2②）**：在 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 **`D-G103` 族**条**内**加**实例注**（**并入、不新号**；如实记「由 `t26` 发现、队长裁定并入」）；`KD` 编辑**批量在 `--emit` 之前**，随后同趟 `--emit` 重发 `declared.tsv`。
- ⏪ **C4（V2③）**：**两极化真跑** —— 断言器（**剥括注／反引号后**判字段）⇒ 正常态「空 `path=` 字段数 ＝ `0`」；沙箱制造**真·空字段** ⇒ **必红**。
- ⏪ **C5（V3）**：`build/MilBridge/P1-tail-scout.md` 的 W3 更正段：行号括注「**仅本次有效**」或**在册声明以内容锚为准、行号仅旁注**。
- ⏪ **C6（指纹）**：牙**在 `fp_inputs()` 覆盖面内**（`in-list=1`）⇒ 入口／出口各取 `inputs_fp` ＋ 覆盖面件数并**逐件归因**；核 `[42] --expect` 是否需同趟改（**本件不改** `verify-all.sh`）。
- ⏪ **C7（边界）**：越域为零（`porcelain` 逐行归属，他人脏件逐行点名）；**未** `git add/commit/push`；**未碰** `close-wave.sh`／`verify-all.sh`／`P1-w2-close-verify.md`／`HANDOFF-NEXT.md`／产品件／基线件；未跑整波／门禁／构建；临时件残留 `0`。
- ⏪ **C8（收口）**：本件就位并自报 sha16 ＋ 读取时刻（亚秒）；`NOINFO` 与**具名不对拍**逐条写。

## §1 落仓清单（证据行读时戳（亚秒）＝ `2026-09-28T16:33:56.031+0800`）

⏪ 六件（写前 `stat -c %h` 全 `==1`；`cp -p` 备份 `~/w281-scribe/bak/*.pre-t31` 取在**任何写之前**；落仓一律 `temp + rename`）：
⏪ `build/MilBridge/tools/pkg-src-retiredpath-check.sh` `231ae30326a4fb31` → **`3bd03726089bf949`**（312 → 317 行；措辞修：反引号形态 `4` 处／裸串 `2` 处／回退判词引述 `1` 处；`bash -n` **OK**；`--selftest` **`cases=11 pass=11 fail=0`**）。
⏪ `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `540de62c051f0875` → **`fb25caf857c1b37f`**（3722 → 3729 行；`numstat` **`7 0`**；实例注落点在 `D-G104` 标题之前 ⇒ **`D-G104` 标题行号 `2806 → 2813`（+`7`）**）。
⏪ `build/MilBridge/tools/defect-registry-declared.tsv` `5559af5443888348` → **`3c3c3de96dfcf8f2`**（226 → 226 行；**同趟**：`KD` 编辑**之后**才 `--emit`；除 `# DECL-GEN` 外差异 `2` 行 ＝ `# DECL-ANCHORS` 的 `KD=` 锚，逐行可归因）。
⏪ `build/MilBridge/P1-w2-report.md` `f934e6c8972cfc68` → 全文 **`d566492516b858f3`**（158 → 164 行；`numstat` **`6 0`**；前缀 `cmp` **IDENTICAL**；新自证 `head -n -1` ＝ `c731f344172400bd`）。
⏪ `build/MilBridge/P1-tail-scout.md` `acc7872f7dad220e` → 全文 **`b3ca6362d2b398bb`**（575 → 583 行；`numstat` **`8 0`** ＝ V3 `5` 行 ＋ 更正 `3` 行；前缀 `cmp` **IDENTICAL**；新自证 `head -n -1` ＝ `fb1e396e98771b41` **已被更正条重算**，见 §4）。
⏪ `build/MilBridge/P1-w2-close2-report.md`（**新建**）＝ 本件（§0 判据**先落**，`16` 行／`bdc020fb842c050f` 为**判据段**的 sha16、**不是**全文值）。
⏪ **新增行形态自查**：两件追加件的**新增行** `^[^⏪]` 计数 ＝ **`0`**；新增行戳**带亚秒**（各 `1` 处命中）。

## §2 C1（V1）证据：表内第 `11` 行补口径

⏪ **被点名原句（逐字，`t26` §3-V1）**：「W1 表**第 `11` 行**是 `t14` 交付态，而**同一笔提交**已把该件改成 `231ae30326a4fb31` ⇒ 逐件『现取对拍』有 **1 格未声明的**不符」。
⏪ **落法**：`build/MilBridge/P1-w2-report.md` EOF dated 追加（**`6`** 行）：**第 `11` 行 ＝ `60009734108344bd` 写死为「`t14` 交付态值」**（与本块「与 §3 表逐位相同」一致），**现值另给** `231ae30326a4fb31`（`312` 行，＝ 同笔提交的 W2 修法 B-4 之后）⇒ **此后以现取为准**。
⏪ **与第 `15` 行写法对齐（两格同构）**：第 `15` 行本已声明自指口径（`head -n -1`／全文两组值 ＋ 时刻）；本笔把第 `11` 行补成同构的「**表内值 ＝ 某交付态**」＋「**现值另给**」⇒ `t26` 点名的「`1` 格未声明口径」**归零**。
⏪ **实质不变**：15 格**一字未动**（表内值仍与原表逐位相同，只是**加了口径注**）⇒ `t26` 的「与 `t15` §3 全 15 格逐位相同」结论**不受影响**。

## §3 C2／C3／C4（V2）证据：判词文本去自匹配 ＋ 并入 `D-G103` 族 ＋ 两极化

⏪ **① 措辞修（同一件内一致）**：`pkg-src-retiredpath-check.sh` 里指「`path` 字段为空」处一律改 **`path-field-empty`**（反引号形态 `4` 处／`echo` 串内裸写 `2` 处）；回退判词引述改为 **`corpus-unreadable mode=$MODE`** ＋ `path-field=` 说法。
⏪ **② 可现算不变量（修前／修后成对）**：修前件 `231ae30326a4fb31` ⇒ 「字段名+等号」出现 **`8`** 处（剥括注／反引号后 **`1`** 处 ＝ 发射端）；**修后件 `3bd03726089bf949`** ⇒ 全件 **`1`** 处（**只剩发射端**）、**判词文本（`echo` 串）`0`** 处 ⇒ 判据：`EQ='='; grep -c "path$EQ" <件>` ⇒ **恰 `1`**。
⏪ **③ `D-G103` 族实例注（并入、不新号）**：`KNOWN-DEFECTS.md` 条族**末**（`### `D-G104`` 之前）插入 `- ⏪` 实例注 `7` 行 ⇒ `grep -c 'D-G103'` **`12` → `14`**、`D-G104` 标题 `2806 → 2813`；注内**如实记**「**由 `t26` 发现、队长裁定并入、不新号**」＋现象／根因／机器证／判据三条／🔴 口径句／两极化／边界。
⏪ **④ 两极化（本席真跑，原始读数；断言器在沙箱 `~/w281-scribe/sbx-t31/assert-path-empty.sh`）**：**正极**（修后件）⇒ `crude_hits=1`、`stripped_empty_field_lines=0`、**`PATHEMPTY=PASS`（rc=0）**｜**反极**（沙箱注入**真·空字段**探针）⇒ `PATH_EMPTY_FIELD 320:echo "…reason=probe path="`、`stripped_empty_field_lines=1`、**`PATHEMPTY=FAIL … n=1`（rc=1）** 且**点名行**｜**对照②（只写在括注里的同形字样）** ⇒ 剥后 **`0`** ⇒ **`PASS`**（证明「**必须先剥**」：不剥就假红）｜**对照①（修前件）** ⇒ `crude_hits=8`、剥后 `0` ⇒ **修前若按 crude 数就是假红**。
⏪ **⑤ 三态不退化（真树）**：`bash pkg-src-retiredpath-check.sh --tree` ⇒ `RETIREDPATH=PASS mode=tree files=568 hits=3 code=0 declared=3 self_skip=1`（rc=0）；**缺目录腿** ⇒ `rc=1 RETIREDPATH=FAIL reason=tree-dir-missing dirs=tests,src root=…（射程面三目录必须齐；**不许**降成 NOINFO、**不许**path-field-empty）`，且**该判词输出里 `path=` 命中 `0`** ⇒ 自匹配已消除。

## §4 C5（V3）证据：行号仅旁注 ＋ 一处自伤更正

⏪ **落法**：`build/MilBridge/P1-tail-scout.md` W3 更正段追加 **`5`** 行，把规则上升到**段级**并写死：**「本段及其后续一切引用，一律以内容锚为准；行号（含 `:254`／`:517`）仅作『仅本次有效』旁注，不得作为判据。」**（段内 `①` 行原本已带行号括注「仅本次有效」⇒ 本笔补的是**段级规则**。）
⏪ **现取核对（本席自算）**：**§4 表锚**（行首 `| **W2** |` 的那一行）⇒ **恰 `1` 行** ✓；**正文锚**（结构锚＝`### W2 ·` 小节里「入口（原文照抄）」那一条的第 `2` 项）⇒ 结构锚唯一 ✓；但**仅按其中那串路径子串 grep** ⇒ **`2` 行**（权威正文行 ＋ **本更正段自己的引文**＝**自指**）。
⏪ ⚠️ **自伤与更正（原文保留）**：V3 那行我原写「…（含 `豁免通道 ＝ …`）现取**恰 `1` 行**」—— **后半错**（子串锚 `2` 行）⇒ 同趟追加 `⏪ dated 更正` `3` 行写死 **「结构锚唯一、子串锚不唯一」**（`D-G130` 同族：锚不定域 ⇒ 复算可指向两行）。⇒ **以更正条为准**。

## §5 C6 证据：指纹（牙在覆盖面内 ⇒ 必移，逐件归因）

⏪ **入口**（本波开工现取）：`inputs_fp` ＝ `8c4ce894d04eae7b1c6d253bc5beabb758a9e99f8430b7b1cd17c8d8707bedd3`／覆盖面 **`226`**。
⏪ **出口**（本波落定后现取）：`inputs_fp` ＝ **`c87cb187f45082e83d3b217d235d50b24f1183f28d37308f1a175de25210403d`**／覆盖面 **`226`**（**件数不变**：牙本就在覆盖面内 ⇒ 只换值）。
⏪ **逐件归因（现取 `infp.sh list` 逐件 `in-list`）**：`build/MilBridge/tools/pkg-src-retiredpath-check.sh` **`1`**（**唯一动因**，在 `fp_inputs()` 内）；`P1-w2-report.md` **`0`**／`P1-tail-scout.md` **`0`**／`KNOWN-DEFECTS.md` **`0`**／`declared.tsv` **`0`**／本件 **`0`** ⇒ **位移 100% 归因该牙**。
⏪ **`[42] --expect` 不需同趟改**：覆盖面件数 `226 → 226`；实跑独立步 ⇒ `FP_MANIFEST_STEP_RC=0 names_n=226 expect=226`。**本件未改** `verify-all.sh`（`600274f130cfe913`）与 `build/close-wave.sh`（`f9a2ee3ee35baff8`）。

## §6 两牙 ／ 具名不对拍 ／ `NOINFO`

⏪ **两牙现算**：`DEFREG=PASS declared=217 route_ids=217` ∧ `DECLDRIFT=0 keys=-`；`REPORTID=PASS files=200 ids=2062 declared=217`（`declared` **未变** ⇒ 本波**未新增 `D-G` 号**，实例注走**并入**；`files/ids` 增量归因本件新建 ＋ 并发写者的 `*report*.md`）。
⏪ ⚠️ **具名不对拍（`low`，写给复核者）**：派单说 `t26` 载体「点名 3 处（均 low）」，但**该载体 §3 只有 `### V1`／`### V2` 两节**（现取 `:202`／`:208`），**全文无 `### V3`**；且其 §0 那行写「（**三处**口径/器材需补：V1／V2，见 §3）」——**说三处、只列两处**，**判词尾行**亦只记 `V1=low V2=low`。⇒ **本席仍按契约落 V3**（scout 行号旁注），但**V3 的出处是队长派单、不是载体 §3**，如实记；若复核者要在载体里找 V3 会**找不到**。
⏪ **`NOINFO`（具名）**：① 本波**未跑整波／门禁／构建／应用／显示位** ⇒ 不判其效果；② `KD` 实例注是**判词文本面**的实例 ⇒ **判据装置缺陷**，不判产品影响（产品面收益**未测** ⇒ `NOINFO`）；③ 断言的**全仓其它件**是否也存在同类自匹配（本件只核 `pkg-src-retiredpath-check.sh`）⇒ `NOINFO(reason=未全仓扫描)`；④ `t26` 第一版断言器的**原始脚本**未在本波现取（只有其判词里的数 `4`）⇒ 该数**按其判词转引**并另给本席现取的修前 `8`（口径差：`t26` 读时件更短）。

## §7 边界

⏪ **`porcelain` 逐行归属（现取）**：`M build/MilBridge/P1-tail-scout.md`｜`M build/MilBridge/P1-w2-report.md`｜`M build/MilBridge/tools/defect-registry-declared.tsv`｜`M build/MilBridge/tools/pkg-src-retiredpath-check.sh`｜`M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`｜`?? build/MilBridge/P1-task0201-criteria.md`｜`?? build/MilBridge/P1-v-close-verify.md`｜`?? build/MilBridge/P1-w2-close2-report.md` ⇒ 本波 `inScope` 三件为 `M tools/pkg-src-retiredpath-check.sh`／`M KNOWN-DEFECTS.md`／`M declared.tsv`／`M P1-w2-report.md`／`M P1-tail-scout.md`／`?? P1-w2-close2-report.md`；其余为**他人件**：`M HANDOFF-NEXT.md`／`M tools/wave-push.sh`／`?? P1-w3-close-report.md`（**`t29`（本席上一波）未提交的**）／`?? P1-task0201-criteria.md`（**`t7` 的**，未读未改）。
⏪ **未碰（现取 sha16 ＋ `porcelain` 零行）**：`build/close-wave.sh` `f9a2ee3ee35baff8`｜`verify-all.sh` `600274f130cfe913`｜`build/MilBridge/P1-w2-close-verify.md` `b723ae2b2e9a1eab`｜`build/MilBridge/HANDOFF-NEXT.md`（**不在本波 `inScope`** ⇒ 未改；其在 `porcelain` 里是 `t29` 的未提交改动）｜`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`｜`src/**`。
⏪ **临时件残留 `0`**、暂存区 **`0`**；**未** `git add/commit/push`。

## §8 自伤（如实记，三条）

⏪ ① **f-string 撞 `${PATHSFILE:-none}`**：KD 实例注首跑用 f-string，正文含 `${…}` ⇒ **`NameError`**、`rename` 未执行 ⇒ 当场复核 `KD lines=3722`／`numstat` 空（**逐字未变、零损伤**）；改普通字符串拼接后落定。⇒ 与 `t27`／`t29` 的自伤**同源**（正文里的 `{}`／反引号／引号与生成器语法打架）。
⏪ ② **我自己写的注释又把 `path=` 塞回去了**：补的件头不变量说明里写了 `grep -c 'path='` 与 `` `path=` 后紧跟 `` 两处字面 ⇒ 修后自检 `grep -c 'path='` 得 **`3`（不是 `1`）** ⇒ **被本波自己的不变量咬住**，改为 **`EQ='='; grep -c "path$EQ"`** 形态（文件内不再出现该字面）后复算 **`1`** ✓。
⏪ ③ **V3 里的锚唯一性断言写错**（见 §4）⇒ 同趟 `⏪ dated 更正` 保留原文并列真值。

## §9 结论

⏪ `t26` 点名的 **V1／V2** 两处 ＋ 派单的 **V3** 一处**全部关账**：**V1** 第 `11` 行口径补齐（与第 `15` 行同构）｜**V2** 判词文本去自匹配（不变量 `grep -c` 恰 `1`／判词文本 `0`）＋ `D-G103` 族实例注（**并入不新号**，`D-G103` `12→14`）＋ 两极化（注入真·空字段 ⇒ 必红点名；括注同形 ⇒ 不判红）｜**V3** 段级规则「**行号仅旁注、以内容锚为准**」。
⏪ **判据只收紧**：修前 **`8`** 处字面 ⇒ 修后 **`1`**（唯一发射端）；断言器**必须剥括注再判字段**（写进 `D-G103` 族口径句）；三态与 `rc` 语义**未改**（`--selftest 11/11`、真树 `--tree PASS`）。
⏪ **现取真值补登（`ts=`2026-09-28T16:34:03.517+0800）**：`build/MilBridge/P1-tail-scout.md` ⇒ 全文 **`b3ca6362d2b398bb`**／**`head -n -1` ＝ `69fb6d20a7eea121`**（583 行）｜`build/MilBridge/P1-w2-report.md` ⇒ 全文 **`d566492516b858f3`**／**`head -n -1` ＝ `c731f344172400bd`**（164 行）⇒ 此后引用这两件**以本条为准**（§1／§4 里 `fb1e396e98771b41` 是 scout **更正条之前**的中途值，已被本行取代）。
⏪ ⏪ **dated 更正（§7 口径时效；`t31`，读时 2026-09-28T16:34:24.654+0800；原文**保留、一字未删**）**：§7 那条 `porcelain` 归属行**已过时** —— 现取 `HEAD = a9958fb 2026-09-28T16:31:22+08:00`（队长在两次 verify 之间**提交了 `t29` 的件**）⇒ `M HANDOFF-NEXT.md`／`M tools/wave-push.sh`／`?? P1-w3-close-report.md` **已不在 `porcelain` 里**，另新增 `?? build/MilBridge/P1-v-close-verify.md`（**`verifier` 的复核件**）。
⏪ **`porcelain` 逐行归属（本条现取，此后以本条为准）**：`M build/MilBridge/P1-tail-scout.md`｜`M build/MilBridge/P1-w2-report.md`｜`M build/MilBridge/tools/defect-registry-declared.tsv`｜`M build/MilBridge/tools/pkg-src-retiredpath-check.sh`｜`M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`｜`?? build/MilBridge/P1-task0201-criteria.md`｜`?? build/MilBridge/P1-v-close-verify.md`｜`?? build/MilBridge/P1-w2-close2-report.md` ⇒ **本波 `inScope` 五件全在**（`M P1-tail-scout.md`／`M P1-w2-report.md`／`M tools/defect-registry-declared.tsv`／`M tools/pkg-src-retiredpath-check.sh`／`M KNOWN-DEFECTS.md`）＋ 本席新建 `?? P1-w2-close2-report.md`；其余 `??` 两行是**他人件**（`P1-v-close-verify.md` ＝ `verifier`、`P1-task0201-criteria.md` ＝ `t7`，均未读未改）⇒ **本波越域仍为零**。
⏪ **牙最终形态补登**：`build/MilBridge/tools/pkg-src-retiredpath-check.sh` ⇒ **`3bd03726089bf949`**（317 行；`numstat` `12 7`）｜`grep -c 'path='` ＝ **`1`**（唯一发射端）｜判词文本 `0`｜`--selftest cases=11 pass=11 fail=0`｜真树 `--tree` `PASS files=568 code=0`。
⏪ 本件自证 sha16（口径＝**末行之前的全文**）＝ `8b93f42cd5dde7ff`（末行＝本行）；**全文** sha16 与末次读取时刻见交件消息（末行只携带 `head -n -1` 口径 ⇒ 全文值不可能自指）。
