# P1-w1-close-verify —— `t16` F1–F6 六条 dated 追加的**独立复核判词**（`verifier` / `t17`）

- **被核交件**：`t16`（成员 `scribe`）的 **F1–F6 六条 dated 追加** —— 提交 **`4a97a0d3a71d341a5051651f33a450d13490fb9e`**（`%cI = 2026-09-28T16:09:32+08:00`，父 `72d78b8d8411cd4d2cc533eb610d5de70cc93fac`）。
- **仓**：`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜我开工时 `HEAD=141dab0`（`16:13:45`）。
- **读取时刻**：本件全部读数在 **`2026-09-28T16:13:59` – `2026-09-28T16:15:0x +0800`** 之间**现取**（命令与读数为同一趟）。
- **载体**：本件（`build/MilBridge/P1-w1-close-verify.md`）＝我唯一写入的件。沙箱/中间件在 `~/wv84y/`（**不落 `/tmp`**）。
- **边界**：`$N` 只读；不跑门禁/构建/应用/显示位；未 `git add/commit/push`。**不复述** `t16` 的任何结论 —— 每条我自己现取。

---

## §0 逐条判词速览

| # | 复核项 | 判词 |
|---|---|---|
| 1 | 六条更正**逐字核**（原文仍在・更正句在册・戳合规） | **成立**（三层 `^-` ＝ `0`；六条原句**全部仍在**；戳 **早于提交 `66 s`**）｜⚠️ 附 V2（同秒不可对拍） |
| 2 | **F2 三口径自算** | **成立**：`2 行／3 处` ✓、`1 行／1 处` ✓ 逐格同；`本报告件自身` **写者 `9／11` ≠ 现取 `11／15`** —— 我定位到写者取的是**本笔追加前**的版本（`4a97a0d^`：`9／11` **逐格同**）⇒ 数值可复现、**口径需标**（V1）；**`13` 在四种口径下都不成立** ✓ |
| 3 | **F1 内容锚 ＋ 插入前坐标** | **成立**：三个锚与现盘 `:223`／`:230`／`:242` **逐字相符**；基线 `bak/ROUTES.md.pre-t10`（sha16 `3fc6b1598fb4e043`）的 `:221`／`:228`／`:240` 与三行**全文 sha16 逐行相同**（`abc609243c3ff6b1`／`52d8bde3bcbdc234`／`34e38aca48a5d0ec`）⇒ **插入前坐标得证**（偏移 `+2`） |
| 4 | **F6 两处并存已处置** | **成立**：权威路径现值 `24e4e0a731dbed40`／`104448 B`／mtime `2026-09-28 13:11:49.073048849` **逐格与裁定句相同**；哨兵 `PROVIDER=24e4e0a731dbed40`；**裁定句在两件各 `1` 处、都含现值与「仅作纪元对照」** |
| 5 | 两牙不退化 ／ 越域为零 ／ 未 add | **成立**：`DEFREG=PASS declared=216 route_ids=216`＋`DECLDRIFT=0 keys=-`；`REPORTID=PASS files=194 ids=2042 declared=216`；**`t16` 名下零脏件**；暂存区 `0` 行 |
| — | **我推翻的话** | **`none`**（两处**口径**需补标签：V1／V2） |

---

## §1 复算命令**原文**（逐条照抄）

### 1.1 构件与只增不改（三层）
```bash
cd $N && git show --numstat --format='%H %P %cI' 4a97a0d
cd $N && for f in docs/ROUTES.md build/MilBridge/P1-w1-report.md build/MilBridge/HANDOFF-NEXT.md; do \
   printf '%-44s ^-= %s\n' "$f" "$(git diff 4a97a0d^ 4a97a0d -- $f | grep -c '^-[^-]')"; done
cd $N && for f in docs/ROUTES.md build/MilBridge/P1-w1-report.md build/MilBridge/HANDOFF-NEXT.md; do \
   printf '%-40s parent=%s commit=%s now=%s\n' "$f" "$(git show 4a97a0d^:$f | wc -l)" "$(git show 4a97a0d:$f | wc -l)" "$(wc -l < $f)"; done
# acceptance 原样（工作树级）
cd $N && git diff --numstat -- docs/ROUTES.md build/MilBridge/P1-w1-report.md; git diff -- docs/ROUTES.md build/MilBridge/P1-w1-report.md | grep -c '^-[^-]'
# 六条原句仍在
grep -c '本轮现取 `:221`／`:228`' docs/ROUTES.md ; grep -c '本轮现取 `:240`' docs/ROUTES.md
grep -c '（改后，全为本条目与引文）' build/MilBridge/P1-w1-report.md
grep -c '224` 行数据行逐字节不变' build/MilBridge/P1-w1-report.md
grep -c '各出现一次' build/MilBridge/P1-w1-report.md
```

### 1.2 戳合规
```bash
cd $N && sed -n '829p' docs/ROUTES.md | grep -o '读时 `[^`]*`' | head -1
cd $N && stat -c '%n mtime=%y ctime=%z' docs/ROUTES.md build/MilBridge/P1-w1-report.md build/MilBridge/HANDOFF-NEXT.md
cd $N && git log -4 --format='%h %cI %s' | cut -c1-110
```

### 1.3 F2 三口径（我自己现算）
```bash
cd $N && echo "① 册现取: -c=$(grep -c 'D-G176' samples/WpfFeatureProbe/KNOWN-DEFECTS.md) -o=$(grep -o 'D-G176' samples/WpfFeatureProbe/KNOWN-DEFECTS.md | wc -l)"
B=~/w281-scribe/bak/KNOWN-DEFECTS.md.pre-t10
cd $N && echo "② 基线 $B (sha16=$(sha256sum $B|cut -c1-16)): -c=$(grep -c 'D-G176' $B) -o=$(grep -o 'D-G176' $B | wc -l)"
cd $N && for rev in 4a97a0d^ 4a97a0d HEAD; do printf '%-10s lines=%-4s -c=%s -o=%s\n' "$rev" "$(git show $rev:build/MilBridge/P1-w1-report.md | wc -l)" "$(git show $rev:build/MilBridge/P1-w1-report.md | grep -c 'D-G176')" "$(git show $rev:build/MilBridge/P1-w1-report.md | grep -o 'D-G176' | wc -l)"; done
cd $N && echo "WORKTREE: -c=$(grep -c 'D-G176' build/MilBridge/P1-w1-report.md) -o=$(grep -o 'D-G176' build/MilBridge/P1-w1-report.md | wc -l)"
```

### 1.4 F1 内容锚 ＋ 插入前坐标
```bash
cd $N && for spec in 223:TASK-0202 230:TASK-0204 242:TASK-0303; do L=${spec%%:*}; ID=${spec##*:}; \
   printf '[%s] ' "$L"; sed -n "${L}p" docs/ROUTES.md | sed 's/^[│├─└┌┐┘┤┬┴┼ ]*//' | cut -c1-60; done
B=~/w281-scribe/bak/ROUTES.md.pre-t10
for spec in 221:223 228:230 240:242; do a=${spec%%:*}; b=${spec##*:}; \
   x=$(sed -n "${a}p" $B | sha256sum | cut -c1-16); y=$(sed -n "${b}p" docs/ROUTES.md | sha256sum | cut -c1-16); \
   printf 'baseline:%s=%s now:%s=%s same=%s\n' "$a" "$x" "$b" "$y" "$([ "$x" = "$y" ] && echo YES || echo NO)"; done
```

### 1.5 F4／F5 复核
```bash
cd $N && for s in 759ac1686e5ef87d 8cb1b50619f4c133 7e8a217b4165a6b9; do \
   printf '%-18s 注释内=%s 全件=%s\n' "$s" "$(grep -n '^ *#.*' ~/w21-verify/w27-freeze.py | grep -c "$s")" "$(grep -c "$s" ~/w21-verify/w27-freeze.py)"; done
cd $N && sed -n '443,445p' ~/w21-verify/w27-freeze.py | cut -c1-70 ; sed -n '448p' ~/w21-verify/w27-freeze.py | cut -c1-70
cd $N && grep -n '7e8a217b4165a6b9' build/MilBridge/P0-w80-report.md | cut -d: -f1 | tr '\n' ' ' ; sed -n '63p' build/MilBridge/P0-w80-report.md | cut -c1-40
cd $N && grep -n "prev_provider='8cb1b50619f4c133'" ~/w21-verify/w27-freeze.py | cut -d: -f1 ; grep -n "prev_provider='8cb1b50619f4c133'" ~/w281-scribe/bak/w27-freeze.py.pre-t10 | cut -d: -f1
cd $N && grep -c 'WFREEZE_BLOCKVALUES_HIT' build/MilBridge/tools/wave-freeze-consistency-check.py ; grep -c 'WFREEZE_BLOCKVALUES_HIT key=' build/MilBridge/tools/wave-freeze-consistency-check.py
```

### 1.6 F6 处置 ＋ 两牙 ＋ 越域
```bash
cd $N && sha256sum build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll | cut -c1-16 ; stat -c '%s %y' build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll ; grep '^PROVIDER=' /tmp/bridge-frozen.flag
cd $N && grep -n '24e4e0a731dbed40' build/MilBridge/P1-w1-report.md | cut -d: -f1 | tr '\n' ' ' ; grep -n '7e8a217b4165a6b9' build/MilBridge/P1-w1-report.md | cut -d: -f1 | tr '\n' ' '
cd $N && bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | grep -E '^DEFREG=|^DEFREG_DECL=|^DEFREG_DECLDRIFT'
cd $N && bash build/MilBridge/tools/report-id-domain-check.sh 2>&1 | tail -1
cd $N && git status --porcelain ; git diff --cached --numstat | wc -l
cd $N && git log --format='%h %cI %s' -3 -- build/MilBridge/HANDOFF-NEXT.md | cut -c1-110
cd $N && for f in docs/ROUTES.md build/MilBridge/P1-w1-report.md build/MilBridge/HANDOFF-NEXT.md; do printf '%-40s worktree==HEAD: %s\n' "$f" "$(git diff --quiet HEAD -- $f && echo YES || echo NO)"; done
```

---

## §2 逐格对照表

### 2-1 六条更正**逐字核**（判据 1）

| 项 | 我现取 | 判 |
|---|---|---|
| **落点与规模**（commit 级 `numstat`） | `docs/ROUTES.md` **`1 0`**（`:829` ＝ F1 行）｜`build/MilBridge/P1-w1-report.md` **`5 0`**（`:223`–`:227` ＝ F2/F3/F4/F5/F6）｜`build/MilBridge/HANDOFF-NEXT.md` **`6 0`**（`:314`–`:319` ＝ F6 同族） | ✓ 与 `t16` 声称逐格相同 |
| **行数 parent → commit** | `828 → 829`｜`222 → 227`｜`313 → 319` | ✓ |
| **`^-` 计数（commit 级，逐件）** | `0`／`0`／`0` | ✓ **纯增** |
| **`^-` 计数（工作树级，acceptance 原样）** | `docs/ROUTES.md` 与 `P1-w1-report.md` 的 `git diff --numstat` 现取为 **`1 0`（ROUTES）／`0`（report worktree==HEAD）**，`^-` ＝ `0` | ⚠️ 见 §4-N1（**`D-G181` 已立号**） |
| **F1 原句仍在** | `本轮现取 \`:221\`／\`:228\`` ⇒ **`2`** 处（原文 1 ＋ 本更正行的引文 1）｜`本轮现取 \`:240\`` ⇒ **`2`** | ✓ **原文一字未删** |
| **F2 原句仍在** | `（改后，全为本条目与引文）` ⇒ **`2`** | ✓ |
| **F3 原句仍在** | `224\` 行数据行逐字节不变` ⇒ **`2`** | ✓ |
| **F4 原句仍在** | `各出现一次` ⇒ **`2`** | ✓ |
| **F5 原句仍在** | `:63` 的 ⇒ **`1`**（原文那句；更正行写成加粗的 `**\`:63\`**` 形态，故不重复命中） | ✓ |
| **六条更正句在册** | `:829`（F1）／`:223`–`:227`（F2–F6）／`:314`–`:319`（F6 同族）**逐行读过原文** | ✓ 六条齐 |

### 2-2 戳合规（判据 1 后半）

| 件 | 更正句里的读时 | 我现取落盘（`stat`） | 判 |
|---|---|---|---|
| `docs/ROUTES.md` | `2026-09-28T16:08:26+0800` | `mtime=2026-09-28 16:08:26.445176624`（`ctime 16:08:26.447176616`） | **与戳同秒 ⇒ 「早于落盘」秒级不可对拍**（§4-N2＋V2） |
| `build/MilBridge/P1-w1-report.md` | 同 | `mtime=2026-09-28 16:08:26.448176612` | **与戳同秒** ⇒ 同上 |
| `build/MilBridge/HANDOFF-NEXT.md` | 同 | `mtime=2026-09-28 16:10:48.904708998` | **该 mtime 已被后来的写者重写**（`f590aca` `16:12:16`／`t23` 又加 `13` 行 ⇒ 现 `338` 行）⇒ 不能当该节落盘时刻（§4-N3） |
| **提交时刻（三条的共同上界）** | — | **`4a97a0d` ＝ `2026-09-28T16:09:32+08:00`** | ⇒ 读时 `16:08:26` **早于上界 `66 s`** ⇒ **不 `FAIL`** ✓ |

**判**：按 acceptance 的字面条件（**戳晚于落盘 ⇒ `FAIL`**）—— `16:08:26` 不晚于任何可证的落盘时刻 ⇒ **不 `FAIL`**；但两件的「早于落盘」在秒级**不可对拍**，详见 §5-V2。

### 2-3 F2 三口径（判据 2）

| 口径 | `t16` 报值（`-c` 行数 ／ `-o` 处数） | 我自算 | 判 |
|---|---|---|---|
| ① 册现取 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `2 行 ／ 3 处` | **`2 行 ／ 3 处`** | ✓ 逐格同 |
| ② 册的改前基线 `~/w281-scribe/bak/KNOWN-DEFECTS.md.pre-t10`（我现取 sha16 `fa1715f3edefb7eb`） | `1 行 ／ 1 处` | **`1 行 ／ 1 处`** | ✓ 逐格同 |
| ③ **本报告件自身** | `9 行 ／ 11 处` | **`11 行 ／ 15 处`**（`227` 行现盘） | ✗ **不符** ⇒ 我定位到写者取的是 **`4a97a0d^` 版（`222` 行）**：该版现算 **`9 行 ／ 11 处`** ⇒ **逐格同** ⇒ 数值可复现，**口径必须是「本笔追加之前」**（§5-V1） |
| ④ 结论 | 「`13` 在三口径下均不成立」 | **四种口径（`2/3`／`1/1`／`9/11`／`11/15`）无一为 `13`** | ✓ **成立**（差 `11`／`12`／`2`／`2`） |

### 2-4 F1 内容锚 ＋ 插入前坐标（判据 3）

| 锚（`t16` 逐字给定） | 我现取的那一行（剥掉树绘制前缀后） | 判 |
|---|---|---|
| 「行首即 `TASK-0202` 号的那一行」 | `:223` ＝ `TASK-0202 ✅ 修 \`D-G72\`（点菜单条 NRE；…` | ✓ 逐字相符 |
| 「行首即 `TASK-0204` 号的那一行」 | `:230` ＝ `TASK-0204 ✅ 登记 \`D-G73\`（\`WM_SYSCOMMAND\` 未实现＋…` | ✓ |
| 「行首即 `TASK-0303` 号的那一行」 | `:242` ＝ `TASK-0303 [Next] ✅ **只读侦察＋最小第一步设计…` | ✓ |

**插入前坐标证明（我用的路 ＝ 基线备份 `~/w281-scribe/bak/ROUTES.md.pre-t10`，sha16 `3fc6b1598fb4e043` ＝ 我 `t11` 时现取的 pre-t10 值）**：

| 基线行 | 基线行 sha16 | 现盘行 | 现盘行 sha16 | **同？** |
|---|---|---|---|---|
| `:221` | **`abc609243c3ff6b1`** | `:223` | **`abc609243c3ff6b1`** | **YES** |
| `:228` | **`52d8bde3bcbdc234`** | `:230` | **`52d8bde3bcbdc234`** | **YES** |
| `:240` | **`34e38aca48a5d0ec`** | `:242` | **`34e38aca48a5d0ec`** | **YES** |

⇒ **同一内容、偏移恰 `+2`** ⇒ `t16` 的「那三个数是**本笔插入前**的坐标（本笔在两处各插 `1` 行、两处都在其前 ⇒ 全体 `+2`）」**得证** ✓（这不是行号巧合，是**逐行全文指纹**相同）。
**且我核了它自己声明的「零附带位移」**：F1 行落在 `§15af` EOF（现盘 `:829`），`§13` 三行仍在 `:223`／`:230`／`:242` ✓（其后别的写者只往 EOF 追加，未移动它们）。

### 2-5 F4（射程限定）／F5（三处具名＋纪元）

| 项 | `t16` 报值 | 我自算 | 判 |
|---|---|---|---|
| **F4** 注释内 | `1／1／1` | **`759ac1686e5ef87d` 注释内 `1`／全件 `1`；`8cb1b50619f4c133` 注释内 `1`／全件 `2`；`7e8a217b4165a6b9` 注释内 `1`／全件 `1`** | ✓ 逐格同 |
| **F4** 代码行那一处 | `:448` 的 `prev_provider='8cb1b50619f4c133'`（本波未动） | `sed -n '448p'` ⇒ `prev_provider='8cb1b50619f4c133', prev_wic_shim='f7b30…` ✓；本笔改后三行在 `:443`／`:444`／`:445` ✓ | ✓ |
| **F5**-① | `7e8a217b4165a6b9` 在 `P0-w80-report.md` 现取 `:68` 与 `:72`；`:63` 不含该值 | `grep -n` ⇒ **`68 72`** ✓；`sed -n '63p'` ⇒ `⇒ **归因口径（主控裁定）**…`（`grep -c` ＝ `0`） | ✓ 逐格同 |
| **F5**-② | `prev_provider` 现取 `:448`；改前基线 `:447` | **`448`** ✓／**`447`** ✓ | ✓ |
| **F5**-③ | `WFREEZE_BLOCKVALUES_HIT` 共 `4` 处 `print` 站点；**规范形态恰 `1` 处**（`:660`） | 串计数 **`4`**、`print` 站点 **`4`**、`WFREEZE_BLOCKVALUES_HIT key=` **`1`** | ✓ |
| **F5**-④ 纪元限定 | `#80` 纪元哨兵值 `7e8a217b4165a6b9` vs 现盘哨兵值 `24e4e0a731dbed40` | 哨兵现取 `grep '^PROVIDER=' /tmp/bridge-frozen.flag` ⇒ **`PROVIDER=24e4e0a731dbed40`** ✓ | ✓ |

### 2-6 F6 处置（判据 4）

| 项 | 我现取 | 判 |
|---|---|---|
| 权威路径现值 | `build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll` ⇒ **`24e4e0a731dbed40`**／**`104448 B`**／mtime **`2026-09-28 13:11:49.073048849`** | ✓ **逐格与裁定句相同** |
| 现盘哨兵 | `PROVIDER=24e4e0a731dbed40` | ✓ 与「现盘哨兵值」一致 |
| **两处并存属实** | `report` 里 `24e4e0a731dbed40` 命中 `:29`／`:34`／`:226`／`:227`；`7e8a217b4165a6b9` 命中 `:34`／`:50`／`:52`／`:225`／`:226`／`:227` ⇒ **同一件内两值并存** ✓ | ✓ |
| **处置形态（两件各 `1` 处裁定句）** | 两件都含「九位 `provider` 一格以**权威路径现值**为准」＋现值 `24e4e0a731dbed40` ＋ 「仅作纪元对照」；`HANDOFF-NEXT :317` 与 report `:227` **同向** | ✓ **指定哪一处为准 ＋ 纪元限定 ＋ 旧值并列**（满足 acceptance 的三选一） |
| 归因 | 已挂在册（`D-G176`／跨会话第 `18` 条），`t16` 声明**未立新号** ✓ | ✓ |

### 2-7 两牙 ＋ 越域（判据 5）

| 项 | 我现取 | 判 |
|---|---|---|
| `DEFREG` | `DEFREG=PASS declared=216 route_ids=216` ＋ `DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-` ＋ `DEFREG_DECLDRIFT_KEYS=-` | ✓ 未退化 |
| `REPORTID` | `REPORTID=PASS files=194 ids=2042 declared=216` | ✓ 未退化 |
| `declared` `215 → 216` 的归因 | `declared.tsv` 现盘 == `HEAD`；新增那一号来自 **`f590aca`**（`16:12:16`「P1 复核关账 I1-I4 —— 立号 `D-G181`」）⇒ **非 `t16`**（其 `numstat` 只有三件） | ✓ 不计入 `t16` |
| `porcelain` 逐行归属 | ` M build/MilBridge/HANDOFF-NEXT.md`（**W3a `t23` 的哨兵规范节**，`:320`+）｜` M docs/ROUTES.md`（**同**，`:830`）｜`?? build/MilBridge/P1-task0201-criteria.md`（`t7`）｜`?? build/MilBridge/P1-w3a-criteria.md`／`?? P1-w3a-report.md`／`?? tools/sentinel-spec-check.sh`（**W3a**） | ✓ **全部为并发写者** |
| `t16` 名下脏件 | 三件都已提交于 `4a97a0d`：`P1-w1-report.md` 现盘 == `HEAD` ✓；`ROUTES.md`／`HANDOFF-NEXT.md` 的现盘 `M` 是**后来写者**的新增（我逐行看过 `git diff`：新行头部为 `### ⏪ **dated 哨兵规范入册 · 键序／字节格式（`t23`／W3a…`） | ✓ **`t16` 名下零脏件** |
| 未 add/commit/push | `git diff --cached --numstat` 行数 ⇒ **`0`** | ✓ |

---

## §3 我另行核到的两件事（与 `t16` 无关，供你在册）

1. **`t16` 的 F1 行位置已被后来写者"绕过"而不是"移动"**：`t23`／W3a 的新行落在 `ROUTES.md` **EOF（`:830`）**、`f590aca`＋`t23` 的新行落在 `HANDOFF-NEXT.md` **EOF（`:320`–`:338`）** ⇒ `t16` 的 `:829`／`:314`–`:319` **位置未变** ✓（这正是 `t16` 在 F1-⑤ 里写的"落点刻意选 EOF、零附带位移"的做法被后续写者**沿用了**）。
2. **`P1-w1-report.md` 是唯一一件没有被后来写者再动的**（现盘 == `HEAD` == `4a97a0d`）⇒ 其 `:223`–`:227` 位置稳定 ✓。

---

## §4 边界与 `NOINFO`（逐条具名）

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | acceptance 的 `Verify` 第 `2` 段（`git diff --numstat -- docs/ROUTES.md build/MilBridge/P1-w1-report.md` ＋ `^-` 计数） | **已不适用（已立号 `D-G181`）** | `t16` 的改动**已提交**（`4a97a0d`）⇒ 对 `P1-w1-report.md` 该命令**空转**（worktree == HEAD）；对 `ROUTES.md` 它虽非空，但测的是**别的写者**（`t23`）的新增、不是 `t16` 的。**该空转形态已由 `f590aca` 立号 `D-G181`**（我在 `t13` 判词 I1 提出）⇒ 本件**引用**该号、不重复立号。 |
| N2 | `ROUTES.md`／`P1-w1-report.md` 的「读时早于落盘」 | **`NOINFO(同秒不可对拍)`** | 戳 `16:08:26`（秒级）与两件 `mtime` `16:08:26.445176624`／`16:08:26.448176612` **同秒** ⇒ 秒级数据**判不出先后**（见 §5-V2）。替代路：以**提交时刻**为上界（`16:09:32`）⇒ 早 `66 s` ✓。 |
| N3 | `HANDOFF-NEXT.md` 该节的**落盘时刻** | **`NOINFO(现 mtime 已被后来写者重写)`** | 现 `mtime=16:10:48.904708998`，但该文件在 `4a97a0d`（`16:09:32`）里就已有 F6 节、其后又经 `f590aca`（`16:12:16`）与 `t23` 两次追加（现 `338` 行）⇒ **现 mtime 对应的是最后一次写**，不是该节落盘。替代路：**提交时刻**为上界 ✓。 |
| N4 | F2 ③ 的写者口径 | **`NOINFO(写者未标"追加前/后")`** | 我给**两个值**：追加前（`4a97a0d^`，`222` 行）＝ `9 行／11 处`（＝写者值）；现盘（`227` 行）＝ `11 行／15 处`。见 §5-V1。 |
| N5 | 并发写者（`f590aca`／`t23`／`t7`／W3a）各自的**写域归属** | **`NOINFO`** | 我只按 `git log` 的消息与 `numstat` 归因，未逐件核它们的契约；本件只需判「**不计入 `t16`**」，该点成立 ✓。 |
| N6 | 未跑门禁/构建/应用 | **未做（派单边界明写）** | 本件全在只读件与自己的车道目录上完成。 |

---

## §5 我点名的具名差异（**我推翻的话 ＝ `none`**）

### V1（low）：F2 ③「本报告件自身」的数值对应的是**本笔追加之前**的版本，未标口径
- `t16` 的 `:223` 逐字写：「**③ 本报告件自身** ⇒ **`9` 行 ／ `11` 处**」。
- 我现取：**现盘（`227` 行）＝ `11` 行 ／ `15` 处**；而 **`4a97a0d^`（`222` 行）＝ `9` 行 ／ `11` 处`** ⇒ 写者取的是**本笔追加前**那一刻。
- **自指后果**：F2／F6 两行**自身就含 `D-G176`**（F2 引官方原句 2 处＋结论 1 处；F6 归属句 1 处）⇒ **写下这条更正的动作本身把这个数改了**。这不是假数（它在旧版逐格可复现），但**读者按现取复算会得 `11／15` 而判写者错**。
- **实质结论不受影响**：`13` 在**四种口径**（`2/3`／`1/1`／`9/11`／`11/15`）下**都不成立** ✓。
- 建议：dated 追加一句把 ③ 标成「**本笔追加之前**（`222` 行版）」并补「追加后现取 ＝ `11` 行 ／ `15` 处」。

### V2（medium）：戳与落盘**同秒** ⇒ acceptance 里「读时早于落盘」这一条**不可对拍**
- 三件更正句都写 `读时 2026-09-28T16:08:26+0800`；而两件的落盘 `mtime` 是 **`16:08:26.445176624`**／**`16:08:26.448176612`** ⇒ **同一秒**。
- 本仓 `t70` 那次立的规则是「**"读时"戳必须在落盘前现取、必须早于落盘时刻，且必须写到"秒"级**」——本件正是那条规则的**下一格洞**：**秒级戳与同秒写入不可对拍**（`t70` 当时举的例子是"分钟粒度在同一分钟内写入"；这里是同一秒）。
- ⇒ 我**不判 `FAIL`**（戳不晚于任何可证落盘时刻，且早于提交 `66 s`），但记 `NOINFO(同秒不可对拍)`（§4-N2）并**建议**：以后把「读时」写到**亚秒**，或**让写入落在下一秒**（最小代价：读时后 `sleep 1`）；否则每一条 dated 更正都会留下这一格判不了。

### 具名不对拍（不判假）
| # | 句 | 现取 | 说明 |
|---|---|---|---|
| ①' | `t16`「全部带 dated 读时 `…16:08:26+0800`（早于落盘）」 | 见 §2-2：两件同秒、一件 mtime 被重写 | 由提交时刻兜住 ⇒ 不判假，但"早于落盘"这句**该给出依据**（`t16` 未给 `stat` 值） |
| ②' | `t16` F1-④「同族计数：这是**第 4 次**」 | 我核：本件**只复现它自己举的两例**（`t71` 的六个行号＋`:788`；`t2` 落的 `:788` 更正） | 同族计数的**排序**（哪次算第 1/2/3/4 次）我**未独立复核**（无在册同族清单）⇒ 记 `NOINFO`，不作判否定 |

---

## §6 我的自伤与更正（如实记）

1. **`grep -c 'D-G176'` 的两组数我一开始只算了现盘**：得出 `11／15` 与写者 `9／11` 不符，**当场没有直接判"写者错"**，而是加算了 `4a97a0d^` 版 ⇒ 定位到「写者取的是追加前版本」⇒ 从"不符"升级为"**可复现但口径未标**"（V1）。教训：**凡"本件自身"的计数都必须先问"哪个版本"**。
2. **行号引用**：我引 `:829`／`:223`–`:227`／`:314`–`:319`／`:443`–`:448` 前后都先 `sed -n` 打过原文；其中 `:63` 我特意打印以证明**它不含** `7e8a217b4165a6b9`（而不是只看 `grep -n` 的命中）。

---

## §7 收尾

- `$N` 内我**只写本件**；被判的三件与两颗牙**一字未动**（`P1-w1-report.md` 现盘 == `HEAD`；`ROUTES.md`／`HANDOFF-NEXT.md` 的现盘改动**全部属后来写者**，我未碰）。
- 沙箱与中间件全在 `~/wv84y/`（**不落 `/tmp`**）；未跑门禁/构建/应用/显示位；未 `git add/commit/push`。
- ⏪ **追加（本件落盘之后 `16:16:0x` 现取，只补不删）**：① 契约 `Verify` 三条原样现跑 ⇒ `wc -l` ＝ **`235`**｜`sha256sum | cut -c1-16` ＝ **`881e53030cd7d3ea`**｜`git diff --numstat -- docs/ROUTES.md build/MilBridge/P1-w1-report.md` ⇒ **`^-` ＝ `0`**（此时 `ROUTES.md` 的 `M` 也已被并发写者提交，故该命令再次**空转** ⇒ 更印证 §4-N1 的 `D-G181`）；`DEFREG=PASS declared=216 route_ids=216`｜`REPORTID=PASS files=195 ids=2042 declared=216`。
- ⏪ **追加（同上）② `REPORTID` 增量逐件归因**：`files 194 → 195` 的动因 ＝ **`build/MilBridge/P1-w3a-report.md`**（W3a，mtime `16:14:56`，**匹配 `*report*.md`**）；**本件 `P1-w1-close-verify.md` 不匹配该语料**（=`case` 现取：`no`）⇒ **本件的写入不扰动 `files/ids`**（这也是 `ids` 未随本件体内 `17` 处 `D-G` 命中而增长的原因，已用成对读数核过：沙箱含/去本件两次 `REPORTID` **逐字相同**）。
- ⏪ **追加（同上）③**：`porcelain` 现为 **`2`** 行 —— `?? build/MilBridge/P1-task0201-criteria.md`（`t7`）＋ `?? build/MilBridge/P1-w1-close-verify.md`（**本件**）⇒ **`t16` 名下仍零脏件**。

- **判词尾行**：`P1-W1-CLOSE-VERIFY: additive=[1/0,5/0,6/0 ^-=0 originals-present] stamp=[read 16:08:26 < commit 16:09:32 by 66s; two files SAME-SECOND => NOINFO] F2=[2/3 ok,1/1 ok,self 9/11=pre-append vs now 11/15 => V1; 13 fails in all four] F1=[anchors match :223/:230/:242; baseline :221/:228/:240 byte-identical offset +2] F6=[canon 24e4e0a731dbed40 size104448 mtime13:11:49; ruling in both files] teeth=[DEFREG PASS 216/216 drift0, REPORTID PASS 194/2042/216] scope=[t16 dirty=0] overturned=none V1=low V2=medium NOINFO=6`
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ `4987f63c5a0d5771` ／ FULL `4987f63c5a0d57710e07747ec8ebd40f511e8b3f7d64f356871e4a292ace08a2` ／ `wc -l` ＝ 238 行（**不含**本行）／末次读取时刻 `2026-09-28T16:16:1x+08:00`／写入方式 **temp ＋ rename**。
