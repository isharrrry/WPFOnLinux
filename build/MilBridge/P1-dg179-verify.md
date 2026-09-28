# P1-dg179-verify —— `t6`（`D-G179` 入册）**独立复核判词**（`verifier` / `t8`）

- **被核交件**：`t6`（成员 `scribe`）的 `D-G179` 入册 ＋ 同趟 `--emit` 重发 `declared.tsv`。
- **仓**：`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜**基点** `HEAD=88ab841414b6b5e27ec257315179596ab5294633`（`2026-09-28T14:30:17+08:00`）。
- **读取时刻**：本件全部读数在 **`2026-09-28T15:46:53` – `2026-09-28T15:49:31 +0800`** 之间**现取**（命令与读数为同一趟）。
- **载体**：本件（`build/MilBridge/P1-dg179-verify.md`）。**我唯一写入的件**。
- **沙箱**：`~/wv80y/sb*`（`cp -a` 副本、`%h==1`、**不落 `/tmp`**）；`$N` 只读；不跑门禁/构建/应用；不 `git add/commit/push`。
- **禁则遵守**：**不复述** `t6` 的结论 —— 每条腿我自己重跑、每个数我自己现取。

---

## §0 逐条判词速览

| # | 复核项 | 判词 |
|---|---|---|
| 1 | 构件对账（只改 `inScope` 件） | **成立**（无越域；并发写者具名，**不归 `t6`**） |
| 2 | 条目本体（体例／引用真实性／修法未写成已做） | **成立**（三项各给判据，引用**逐条现取核实**） |
| 3 | 两极化**自己重跑**（删条目必点名／加宽 `req` 必点名／正常态必绿） | **成立**（三腿 ＋ 我的**对照腿** ＋ **追加腿 C** 全部复现，`rc` 与点名逐字相同；**无侧为空**） |
| 4 | `BOOK_ENTRY_UNREQUIRED_MISSING` 名单前后逐项对拍 | **成立**（`n=16 → 15`，**差集恰 `{D-G179}`**，其余 15 项逐字相同） |
| 5 | 校验器未被改（两遍 sha16 ＋ 门禁件未动） | **成立**（两遍**逐位相同**；`verify-all.sh`／`close-wave.sh`／`docs/ROUTES.md` 未动） |
| 6 | `REPORTID` 不退化 ＋ `files`/`ids` 增**逐件可归因** | **成立**（增量为 **`+1 文件 / +55 ids`**，**100% 归因于 `t6` 自己的报告件**；机器证见 §2-6） |
| 7 | `declared.tsv` 同趟性（改件在 `--emit` 之前；表除 `DECL-GEN` 外逐字节相同） | **成立**（**内容锚证明**：`DECL-ANCHORS` 的 `KD=` ＝ **新册** sha16 ⇒ `--emit` 确实读到改后的册） |
| — | **我推翻的话** | **2 句**（§5-①②）＋ 1 句 low 具名（§5-③） |

**总判：`t6` 的交件在实体层全部成立。** 我推翻的 2 句都在 `t6` 自己的**报告文本**里（计数标签 ／ 语料归属理由），**不动册条目、不动表、不动牙**。

---

## §1 复算命令**原文**（逐条照抄）

### 1.1 构件对账
```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git rev-parse HEAD && git status --porcelain && git diff --numstat && git diff --cached --numstat
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git diff build/MilBridge/tools/defect-registry-declared.tsv
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git diff -U1 samples/WpfFeatureProbe/KNOWN-DEFECTS.md
```

### 1.2 条目本体
```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sed -n '3684,3698p' samples/WpfFeatureProbe/KNOWN-DEFECTS.md
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git show HEAD:samples/WpfFeatureProbe/KNOWN-DEFECTS.md | sha256sum | cut -c1-16
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git show HEAD:samples/WpfFeatureProbe/KNOWN-DEFECTS.md | grep -c 'D-G179'
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git show HEAD:samples/WpfFeatureProbe/KNOWN-DEFECTS.md | grep -cE '^#{2,4}[^\n]*D-G179'
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for f in samples/WpfFeatureProbe/KNOWN-DEFECTS.md docs/CURRENT-STATE.md handoff.md samples/WpfTextDemo/ACCEPTANCE-BASELINE.md; do printf '%-52s n=%s\n' "$f" "$(grep -c 'D-G179' "$f")"; done
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sed -n '279p' build/MilBridge/HANDOFF-NEXT.md
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sed -n '154,200p' build/MilBridge/VFinal-verify-report.md
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sed -n '3679p' samples/WpfFeatureProbe/KNOWN-DEFECTS.md
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sed -n '110p' build/MilBridge/tools/defect-registry-declared.tsv
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sed -n '3666,3679p' samples/WpfFeatureProbe/KNOWN-DEFECTS.md | grep -nE '^- '
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sed -n '3684,3698p' samples/WpfFeatureProbe/KNOWN-DEFECTS.md | grep -nE '^- '
```

### 1.3 两极化（**沙箱构造**：`cp -a` 真树件 → `~/wv80y/sb*`；牙**本身**用真树件，只换被判输入）
```bash
# 建箱（%h 断言 1，无硬链接）
cp -a $N/samples/WpfFeatureProbe/KNOWN-DEFECTS.md  ~/wv80y/sb/samples/WpfFeatureProbe/
cp -a $N/docs/CURRENT-STATE.md ~/wv80y/sb/docs/ ; cp -a $N/handoff.md ~/wv80y/sb/
cp -a $N/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md ~/wv80y/sb/samples/WpfTextDemo/
cp -a $N/build/MilBridge/{known-red.json,known-red-frame-structural.md,book-entry-required.tsv} ~/wv80y/sb/build/MilBridge/
cp -a $N/build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md ~/wv80y/sb/build/DirectWrite.Linux/wic-shim/
cp -a $N/build/MilBridge/tools/defect-registry-declared.tsv ~/wv80y/sb/build/MilBridge/tools/
cp -a $N/build/MilBridge/*report*.md ~/wv80y/sb/build/MilBridge/

# 腿 L0（真树，正极）／腿 L1（沙箱，等价性对照）
bash $N/build/MilBridge/tools/defect-registry-check.sh
bash ~/wv80y/drc.sh ~/wv80y/sb          # = 真树牙 + DRC_* 指向沙箱副本（牙未改一字）

# 腿 L2（删条目 ∧ 要求成条）＋ L2-control（同箱、只把那一行放回）
grep -v '^### 🆕 \*\*`D-G179`\*\*' sb2/samples/.../KNOWN-DEFECTS.md > t && mv t sb2/.../KNOWN-DEFECTS.md
printf 'D-G179\tP1-W1 反极腿：要求成条\n'  >> sb2/build/MilBridge/book-entry-required.tsv
bash $N/build/MilBridge/tools/report-id-domain-check.sh --root ~/wv80y/sb2

# 腿 L3（A2：不要求成条 ⇒ 名单档）—— 用 HEAD 版册复现"落册前"
git show HEAD:samples/WpfFeatureProbe/KNOWN-DEFECTS.md > sb3/samples/WpfFeatureProbe/KNOWN-DEFECTS.md
bash $N/build/MilBridge/tools/report-id-domain-check.sh --root ~/wv80y/sb3

# 腿 L4（手工把 req 加宽到命中 0 的 HO）
sed -i 's/^ID\tD-G179\treq=KD\tpresent=KD$/ID\tD-G179\treq=KD,HO\tpresent=KD/' sb4/build/MilBridge/tools/defect-registry-declared.tsv
bash ~/wv80y/drc.sh ~/wv80y/sb4

# 腿 L5（追加 C：陈旧表 req=KD ＋ 删光 KD 里该号全部提及）
grep -v 'D-G179' sb5/samples/.../KNOWN-DEFECTS.md > t && mv t sb5/.../KNOWN-DEFECTS.md
bash ~/wv80y/drc.sh ~/wv80y/sb5

# 腿 L6（队长口径 3）：只写一句提及 D-G152 ⇒ --emit 是否自动加宽 req
printf '\n只提一句 `D-G152`…\n' >> sb6/samples/.../KNOWN-DEFECTS.md
bash $N/build/MilBridge/tools/defect-registry-check.sh --emit > sb6/emitted.tsv   # DRC_* 指向 sb6
grep -P '^ID\tD-G152\t' sb6/emitted.tsv

# 腿 L7（归因）：从箱里去掉 t6 的报告件再跑 ⇒ 增量归因
rm -f sb7/build/MilBridge/P1-dg179-report.md && bash $N/build/MilBridge/tools/report-id-domain-check.sh --root ~/wv80y/sb7
```

### 1.4 校验器未改（两遍）＋同趟性
```bash
cd $N && sha256sum build/MilBridge/tools/defect-registry-check.sh build/MilBridge/tools/report-id-domain-check.sh verify-all.sh build/close-wave.sh docs/ROUTES.md | cut -c1-16,66-
cd $N && git status --porcelain -- build/MilBridge/tools/defect-registry-check.sh build/MilBridge/tools/report-id-domain-check.sh verify-all.sh build/close-wave.sh docs/ROUTES.md
cd $N && stat -c '%n mtime=%y' samples/WpfFeatureProbe/KNOWN-DEFECTS.md build/MilBridge/tools/defect-registry-declared.tsv build/MilBridge/P1-dg179-criteria.md
cd $N && sed -n '1,2p' build/MilBridge/tools/defect-registry-declared.tsv
```

---

## §2 逐格对照表（左＝我自算，右＝`t6` 声称；**"现取"列＝我在上列时刻的读数**）

### 2-1 构件对账（判据 1）

`git status --porcelain`（`15:46:53` 现取，共 5 行；`15:49:31` 起变为 6 行，见 §2-7）：
```
 M build/MilBridge/tools/defect-registry-declared.tsv
 M samples/WpfFeatureProbe/KNOWN-DEFECTS.md
?? build/MilBridge/P1-dg179-criteria.md
?? build/MilBridge/P1-dg179-report.md
?? build/MilBridge/P1-task0201-criteria.md
```
| 件 | 归属 | 判 |
|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `t6`｜`numstat = 18 0`（＋18／删 0） | **契约 inScope** ✓ |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `t6`｜`numstat = 2 2` | **契约 inScope** ✓ |
| `build/MilBridge/P1-dg179-criteria.md`／`P1-dg179-report.md` | `t6` **新建**（`??`） | 它自己的两件 ✓ |
| `build/MilBridge/P1-task0201-criteria.md` | **不是 `t6`**（首行自述「车道 `runner`／任务 `t7`」，mtime `15:45:23`） | **不归 `t6`**（队长已裁定并行授权） |
| `build/MilBridge/P1-tail-scout.md`（`15:48:33` 出现） | **不是 `t6`**（首行「P1 尾盘侦察…只读侦察＋判据先写」；mtime 晚于 `t6` 交件） | **不归 `t6`**｜归属 `NOINFO`（§7-N2） |

⇒ **无越域**：`t6` 只动了 `inScope` 两件 ＋ 新建自己的两件。`modified` 集合中**没有** `verify-all.sh`／`close-wave.sh`／`docs/ROUTES.md`／`HANDOFF-NEXT.md`／`src/**`／任何牙。

### 2-2 条目本体（判据 2）

| 检查项 | 我现取 | `t6` 声称 | 判 |
|---|---|---|---|
| 册行数 | `3698` | `3680 → 3698` | ✓ |
| 册 sha16（改后） | `fa1715f3edefb7eb` | `fa1715f3edefb7eb` | ✓ |
| 册 sha16（改前＝`HEAD` blob） | `2152460b7e412352` | `2152460b7e412352` | ✓ |
| 落册前 `grep -c 'D-G179'` | **1** | `1` | ✓ |
| 落册前条目形态标题计数 | **0** | `0` | ✓ |
| 条目位置 | `## P1-W1 登记批` `:3682` ＋ `### 🆕 **\`D-G179\`**` `:3684`，正文 `:3686–:3698` | 同 | ✓ |
| `D-G179` 分布 | `KD=7`／`CS=0`／`HO=0`／`AB=0` | 「CS／HO／AB 三件各命中 `0`」 | ✓ |
| 表行 `:110` | `ID⟶D-G179⟶req=KD⟶present=KD`（TAB 分隔，`cat -A` 核过） | 「行号/字段一字未变」 | ✓ |

**① 体例一致性 —— 我用的判据（写死）**：与**同册最近的两条既有条目** `D-G180`（`:3666`）与 `D-G179` 的**上一批** `D-G177`（`:3607`）对拍，比两件事：**(a) 标题形态** `^#{2,4}` ＋ `🆕 **\`D-Gxxx\`** —— **…**：…`；**(b) 段式标签的逐字形态**。
- **(a)** `grep -nE '^#{2,4}.*D-G1[0-9][0-9]'` 现取：`D-G174/175/170/171/172/173/176/177/178/180/179` **十一条全同形**（`### 🆕 **\`D-ID\`** —— **…**：…`）⇒ ✓。
- **(b)** 段式对拍（顶层 bullet 逐字）：

| 段 | `D-G179` | `D-G180` | 结论 |
|---|---|---|---|
| 现象 | `- **现象（在册读点，逐字）**：` | `- **现象（在册读点，逐字）**：` | **逐字同** ✓ |
| 根因 | `- **根因（机械，可复算）**：` | `- **根因**：` | 同族（附加括注）✓ |
| 证据 | `- **证据（件 ＋ 字段 ＋ 读数 ＋ 时刻）**：` | `- **证据（件 ＋ 字段 ＋ sha16 ＋ 时刻；…）**：` | 同形 ✓ |
| 判据 | `- **判据（机器，三条并列）**：` | `- **判据（机器，三条并列）**：` | **逐字同** ✓ |
| 两极化 | `- **两极化（本波真跑；沙箱不动真树被判件）**：` | `- **两极化（先例＝…）**：` | 同形 ✓ |
| 口径句 | `- 🔴 **口径句（永久）**：` | `- 🔴 **口径句（永久）**：` | **逐字同** ✓ |
| 边界 | `- **边界（如实划界）**：` | `- **边界**：` | 同族 ✓ |
| 追加段 | `- **候选修法（本波只登记、不实现）**：` | `- **编号边界（防误读）**：`（＋`- **同族但判词不同（不许合并）**：`） | 均属本册既有段式 ✓ |

⇒ **体例一致成立**（八段齐：现象／根因／证据①–⑤／判据三条／两极化／🔴 口径句／候选修法①②／边界，与 `t6` 自述相符）。

**② 引用真实性 —— 每条我自己现取核对**：

| 条目里的引用 | 我现取的原文／读数 | 判 |
|---|---|---|
| 「`HANDOFF-NEXT.md` §下一波未闭项 第 `12` 条逐字：「**`D-G179` 候选：声明表 `req` 列在**自动路径**上恒真**」」 | `sed -n '279p' build/MilBridge/HANDOFF-NEXT.md` 现取（节标题 `## §下一波未闭项` 在 `:254`，该条编号 `12.`）＝ `12. **`D-G179` 候选：声明表 `req` 列在**自动路径**上恒真（…）**` ⇒ **逐字相符** | ✓ |
| 证据② 的在册两极化读数为 `D-G152`：正侧「`req=KD,AB present=KD,AB`」／反侧「`DEFREG=FAIL reason=declared-id-missing-in-route` ＋ 点名 `… req=HO MISSING-IN=HO`」 | `build/MilBridge/VFinal-verify-report.md` `:154` 起 §8 表格现取：① 行「该行自动变 `ID D-G152 req=KD,AB present=KD,AB`」；② 行「`DEFREG=FAIL reason=declared-id-missing-in-route`（**`rc=1`**）＋ 逐条点名 `D-G152 req=HO MISSING-IN=HO route=…/handoff.md`」⇒ **逐字相符** | ✓ |
| 证据③「`req` 收窄成子集 ⇒ `DEFREG=PASS`；`req` 塞**非 route 键** ⇒ `DEFREG=NOINFO reason=decl-unparsable`（`rc=2`）」 | 同 §8 表格第 ③④ 行现取：③「`DEFREG=PASS declared=215 route_ids=215`（`rc=0`）」／④「`DEFREG=NOINFO reason=decl-unparsable`（**`rc=2`**）」⇒ **逐字相符** | ✓ |
| 证据② 引的编号来源「其号见 `HANDOFF-NEXT.md` 第 `12` 条与 `VFinal-verify-report.md` §8」 | 两条在册件**都逐字写着 `D-G152`** ✓（且我自算：`D-G152` 的 `req=AB`／`KD 命中 0`／`CS 命中 0`／`HO 命中 0`／`AB 命中 3`） | ✓ |
| 证据④ `D-G180` 条目末句逐字 | `sed -n '3679p'` 现取＝「**`D-G179` 已由队长保留**给另一条发现（`defect-registry-check.sh` 的 `req` 列在**自动路径上恒真**：…）…本件按配号用 **`D-G180`**」⇒ **逐字相符** | ✓ |
| 证据① 表行 `:110` | 见 §2-2 表 ✓ | ✓ |
| 证据⑤「`report-id-domain-check.sh` 落册前现取把本号列在 `BOOK_ENTRY_UNREQUIRED_MISSING`（`n=16`，名单逐字含本号）」 | **我自己重跑**（§3 腿 L3）：`n=16 ids=… D-G161 D-G165 **D-G179** D-G33 …` ⇒ **逐字相符** | ✓ |

⇒ **引用只引在册证据、且逐条可复现** ✓。

**③ 修法未写成已做**：条目把两个候选修法放在 `- **候选修法（本波只登记、不实现）**：` 下，且 `- **边界（如实划界）**：② 本波**只登记、不改校验器语义**（`defect-registry-check.sh` 一字未动）`。**我自己核对**：`defect-registry-check.sh` sha16 开工 `c2d0773e5561a9d1` ＝ 收工 `c2d0773e5561a9d1`（§2-5）⇒ **未改一字** ✓；条目**未**声称任何修法已落地 ✓。

### 2-3 两极化自己重跑（判据 3；**原始机读行摘录**）

| 腿 | 构造（我做的） | 我现取的原始判词行 | `rc` | 与 `t6` 声称 |
|---|---|---|---|---|
| **L0 正极（真树）** | 不动（真册＋真表） | `DEFREG=PASS declared=215 route_ids=215（…）`／`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-` | `0` | 一致 ✓ |
| **L1 沙箱等价性** | 沙箱副本（内容与真树 `cmp` 一致）＋ 真树牙 ＋ `DRC_*` | 同 L0 末两行**逐字相同** | `0` | —（我的对照，证明沙箱不失真） |
| **L2 反极 A** | 副本册**删掉**条目标题行（`D-G179` 提及 `7 → 6`）∧ 副本要求清单**追加** `D-G179` | `BOOK_ENTRY_BINDING required=6 present=5 missing=1` ＋ `REPORTID=FAIL` ＋ `  D-G179 rule=book-entry-heading-missing（册里没有条目形态标题）` | `1` | **逐字一致** ✓ |
| **L2-control（成对对照）** | **同一个箱**、只把那一行**放回** | `BOOK_ENTRY_BINDING required=6 present=6 missing=0` ＋ `REPORTID=PASS files=191 ids=2012 declared=215` | `0` | **成对成立**：唯一变量＝那一行 |
| **L3 反极 A2** | 用 `HEAD` 版册（落册前，`2152460b7e412352`，提及 `1`）＋ **不**要求成条 | `BOOK_ENTRY_UNREQUIRED_MISSING n=16 ids=… D-G165 **D-G179** D-G33 …`（**可见列名、不判红**）＋ `REPORTID=PASS` | `0` | **逐字一致**（§4 逐项对拍） |
| **L4 反极 B** | 手工把 `D-G179` 的 `req` 加宽到 `KD,HO`（`HO` 命中 `0`） | `DEFREG=FAIL reason=declared-id-missing-in-route` ＋ `  D-G179 req=HO MISSING-IN=HO route=…/wv80y/sb4/handoff.md`（另有 `DEFREG_DECLMETA` 诊断行，**不判红**） | `1` | **逐字一致** ✓ |
| **L5 追加腿 C** | 陈旧表（`req=KD` 不动）＋ 把 `KD` 里该号提及**删光**（`7 → 0`） | `DEFREG_DECLDRIFT=1 … keys=KD` ＋ `DEFREG_DECLDRIFT_KEYS=KD` ＋ `DEFREG=FAIL reason=declared-id-missing-in-route` ＋ `  D-G179 req=KD MISSING-IN=KD route=…/wv80y/sb5/samples/…/KNOWN-DEFECTS.md` | `1` | **逐字一致** ✓ ⇒ 条目「边界①『陈旧表不在此列、会真红』」**实测成立** |
| **L6（队长口径 3）** | 副本册里对 `D-G152` **只写一句提及**（不加标题、不入要求清单）⇒ `--emit` | `emit rc=0`；该行 **`ID⟶D-G152⟶req=AB`**（原）→ **`ID⟶D-G152⟶req=KD,AB⟶present=KD,AB`**；`--emit` 输出与真表 diff **只 `72c72` 一行**；把重发的表当输入再判 ⇒ `DEFREG=PASS declared=215 route_ids=215` | `0` | **证实** `t6` 的设计理由（见下） |

**「任一侧为空必须响亮失败」**：上表每一腿都**有非空机读判词行 ＋ 明确 `rc`**，且 L2／L2-control 与 L1／L4／L5 构成**成对读数**；**没有**任何一腿是"静默判等"。

**L6 的结论（队长口径 3 的裁定）**：`t6` 的设计理由 —— **「在册写下一个号就等于替它起草声明」—— 我独立证实，不是证伪**：
- 只写**一句提及**（非标题、不入要求清单）⇒ `--emit` 后该行 `req` **自动从 `AB` 加宽到 `KD,AB`**（`present` 同步加宽）；
- 加宽后的表上规则③**仍然 PASS**（因为 `req` 就是出现集）⇒ 这正是条目所说「恒真」；
- ⇒ 条目**刻意不复录 `D-G152`** 是**正确**的防御（若复录，`D-G152` 的 `req` 会当场变成 `KD,AB`，本波就会**顺手改掉另一条的声明**，属越域）；且我核过：`KD` 里 `D-G152` 命中 **0** ⇒ 本波 `--emit` 的 `req` 未变、**表数据行零变化**（§2-7）。

### 2-4 名单前后逐项对拍（判据 4）

| | `n` | 名单（逐字） |
|---|---|---|
| **落册前**（我用 `HEAD` 版册在沙箱现跑） | **16** | `D-E1 D-F1b-ABSENT D-G D-G1 D-G156 D-G159 D-G161 D-G165 **D-G179** D-G33 D-G5 D-G6 D-O1 D-R2 D-R4 D-T1` |
| **现取（真树）** | **15** | `D-E1 D-F1b-ABSENT D-G D-G1 D-G156 D-G159 D-G161 D-G165 D-G33 D-G5 D-G6 D-O1 D-R2 D-R4 D-T1` |

- **差集** ＝ **恰好 `{D-G179}`**（集合差 `前−后` 与 `后−前` 分别为 `{D-G179}` 与 `{}`）；**其余 15 项逐字、逐序相同**。
- ⇒ `t6` 的「`n=16 → 15`，`D-G179` 已消失（逐号细判命中 `0`）」**成立**，且**不是只换了个数**（`D-G125` 方向我已按逐项比排除）。

### 2-5 校验器未被改（判据 5；**两遍现取**）

| 件 | 开工 `15:46:53` | 收工 `15:49:31` | `git` | 判 |
|---|---|---|---|---|
| `build/MilBridge/tools/defect-registry-check.sh` | `c2d0773e5561a9d1` | `c2d0773e5561a9d1` | 未列入 `porcelain` | **逐位相同** ✓ |
| `build/MilBridge/tools/report-id-domain-check.sh` | `e1ed9a71200a20a9` | `e1ed9a71200a20a9` | 未列入 | **逐位相同** ✓ |
| `verify-all.sh` | `600274f130cfe913` | `600274f130cfe913` | 未列入 | **未动** ✓ |
| `build/close-wave.sh` | `f9a2ee3ee35baff8` | `f9a2ee3ee35baff8` | 未列入 | **未动** ✓ |
| `docs/ROUTES.md` | `3fc6b1598fb4e043` | `3fc6b1598fb4e043` | 未列入 | **未动** ✓ |

且条目自己引的牙值 `c2d0773e5561a9d1` **与我开工现取逐位相同** ⇒ 引值不是陈旧值 ✓。

### 2-6 `REPORTID` 不退化 ＋ 逐件可归因（判据 6）

| 语料 | `files` | `ids` | `declared` |
|---|---|---|---|
| **现取（真树，含 `t6` 的报告件）** | **191** | **2012** | **215** |
| **沙箱去掉 `t6` 的报告件后**（腿 L7） | **190** | **1957** | **215** |
| **增量** | **+1** | **+55** | 0 |

- 归因**逐件可核**：`build/MilBridge/*report*.md` 现取 **191** 个；其中**未跟踪**的只有 **1** 个 ＝ `build/MilBridge/P1-dg179-report.md`（`t6` 自己的报告件）；该件体内 `D-G\d+` 命中 **55** 处 ⇒ **`ids` 增量 `2012 − 1957 = 55` 与它逐格相符**。
- ⇒ `files +1`／`ids +55` **100% 归因于 `t6` 自己的报告件**；`declared=215` **未变** ⇒ **未退化** ✓。
- `t6` 报告里写的 `files=190 ids=1957` 是它**报告件落盘之前**的读数（那时该件还不存在）⇒ **与我的 190/1957 一致**，**不算不一致**（我另有机器证）。
- 队长口径 2 已核：`P1-task0201-criteria.md`／`P1-tail-scout.md` **不匹配** `*report*.md`（`case` 逐件判过）⇒ **不进语料**，故不产生增量。

### 2-7 `declared.tsv` 同趟性（判据 7）

- **次序（用内容锚判，不靠钟）**：`# DECL-ANCHORS` 的 `KD=` 现取 ＝ **`fa1715f3edefb7eb`** ＝ **改后册**的 sha16（不是 `HEAD` 的 `2152460b7e412352`）⇒ **`--emit` 读到的确实是改后的册** ⇒ 「改件在 `--emit` 之前」**机器证成立**（钟面上也都对得上：册 `mtime 15:44:34.595902646` ＜ 表 `mtime 15:44:51.954839295`；`# DECL-GEN = 15:44:51`）。
- **表 diff**：`git diff` 现取**只 `1,2c1,2`**（`# DECL-GEN` ＋ `# DECL-ANCHORS` 的 `KD=`，其余七键逐字不变）⇒ **数据行 0 行差异**。
- sha256：`e242e3fbc5f76d77…` → `2f9f55f41cf57622938bcee45df77c3c501f4bd5995aef760237aa9993237539`。
- `D-G179` 行（`:110`）＝ `ID⟶D-G179⟶req=KD⟶present=KD` ⇒ **行号/字段未变** ✓。
- ⚠️ **计数标签更正（见 §5-①）**：`t6` 报告写「`224` 行数据行逐字节不变」；现取 **`wc -l = 224`／注释行 `9`／数据行 `215`** ⇒ `224` 是**全文行数**，**数据行是 `215`**（与 `DEFREG_DECL=n=215` 相符）。**"数据行逐字节不变"这个断言本身成立**。

---

## §3 我**推翻**的话

### ① 「**`224` 行数据行**逐字节不变」—— **推翻（计数标签错）**
- 出处：`build/MilBridge/P1-dg179-report.md:66` 逐字「…`diff` 现取**只 `1,2c1,2`**（`# DECL-GEN` ＋ `# DECL-ANCHORS` 的 `KD=`），**`224` 行数据行逐字节不变**」。
- 现取：`wc -l build/MilBridge/tools/defect-registry-declared.tsv` ＝ **224**；`grep -c '^#'` ＝ **9**；`grep -vc '^#'` ＝ **215**；牙自己吐 `DEFREG_DECL=n=215` ⇒ **数据行 `215`**，`224` 是**含 9 行注释的全文行数**。
- **实质结论（数据行逐字节不变）我复算＝成立**（数据行 diff `0` 行）；错的是**数**。属 `D-G125` 同族（"件与表都对、错的可能只是消息"）。

### ② 「（判据件与报告件**都不吃** `*report*.md` 语料：判据件名是 `*-criteria.md`）」—— **推翻**
- 出处：`build/MilBridge/P1-dg179-report.md:133` 逐字「`files=190`／`ids=1957`／`declared=215` **与开工现取逐格相同** ⇒ **未退化**（判据件与报告件都不吃 `*report*.md` 语料：判据件名是 `*-criteria.md`）。」
- **证伪**：**报告件确实吃**该语料。机器证（腿 L7）：同一个沙箱，**只**去掉 `build/MilBridge/P1-dg179-report.md` ⇒ `REPORTID` 从 `files=191 ids=2012` 变为 **`files=190 ids=1957`**；且该件体内 `D-G\d+` 命中**恰 55** ＝ `ids` 增量。**括注只对判据件成立**。
- **实质结论（`未退化`）成立** —— 真正的原因是**那一刻报告件还没落盘**（所以读数还是 190/1957），**不是**"不吃语料"。

### ③ 「判据件…落盘 `15:44:08`」—— **具名（不判假）**
- 出处：`build/MilBridge/P1-dg179-report.md:4` 逐字「判据件（先写）＝ `build/MilBridge/P1-dg179-criteria.md`（`6f10658432b7a995…`，落盘 `15:44:08`…）」。
- 现取：该件 `mtime = 2026-09-28 15:44:06.153013319 +0800`，sha256 `6f10658432b7a995…` **与所引逐位相同**。
- ⇒ **内容/指纹对得上**，只有**秒级自述与 mtime 差 ≈ 2 s**。我**不判它假**（"落盘"可能指写完那一刻之外的另一次动作），但**不可对拍** ⇒ 记为具名差异（低）。（另：报告 `:64` 把册编辑的 `rename` 记成 `15:44:51`，而册 `mtime = 15:44:34.595902646` —— 二者**可同时成立**（temp 写于 `:34`、`mv` 保 mtime、`rename` 于 `:51`），故此处**只具名不对拍、不判假**。）

---

## §4 边界与 `NOINFO`（逐条具名）

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | `t6` 是否曾在**它自己的车道目录**里留过夹具 | `NOINFO` | 本件写域与审计范围限 `$N`；`$N` 外的车道路径不在我的核对面（且不属于交付面）。 |
| N2 | `build/MilBridge/P1-tail-scout.md`（`15:48:33`，80503 B）的**归属** | `NOINFO` | 首行自述「P1 尾盘侦察…唯一写入仓内的件就是本件」但**未署任务号**；它**不匹配** `*report*.md`（不进 `REPORTID` 语料）⇒ **不归 `t6`**、也**不影响**本件任一读数。 |
| N3 | 条目证据②/③所引 `VFinal-verify-report.md` §8 的**沙箱读数本身** | 已核（非 `NOINFO`） | 我逐字核了 §8 表格四行；但**未在 `~/w31x/dg179/` 复跑 `t15` 那趟**（那不是本件被判对象）⇒ 我用自己的 L6 腿**独立证了**同一机理。 |
| N4 | 条目「候选修法①②」**实现后**是否真的更好 | **不判** | 派单明确"只登记、不实现"；实现须另立波次并自带两极化。 |
| N5 | `book-entry-required.tsv` **是否应**把 `D-G179` 列为必需 | **不判** | 属队长/下一波；我只在沙箱副本上做了 L2 构造，未碰真件。 |
| N6 | `REPORTID` 的 `files/ids` **后续**漂移 | `NOINFO` | 有并行写者（`t7` 等）会继续推高；本件只把 **`t6` 那一格**按 §2-6 归因，**不把后来者算到 `t6` 头上**。 |
| N7 | `REPORTID=FAILX` 里的尾字母 `X` | 已核（非缺陷） | 我的 L2 腿复现 `REPORTID=FAILX`：这是牙的既有占位行为（`[ -n "$bad" ] \|\| bad=X`，随后拼上 `rmiss`）⇒ **牙未改、非 `t6` 引入**，如实记。 |
| N8 | 本波是否跑过门禁/构建 | **未跑（不需要）** | 派单边界明写不跑；本件四条腿全在沙箱与只读件上完成。 |

---

## §5 我的自伤与更正（如实记）

1. **`set -e` 吃掉了一条腿**：L2 那趟我用了 `set -e`，牙 `rc=1` ⇒ 脚本在**打印完判词后**整体退出，**紧随的 L2-control 对照腿没跑**。我**当场发现并单独重跑**了对照腿（`required=6 present=6 missing=0`／`REPORTID=PASS`），**成对读数没有缺口**。教训：反极腿必须**显式收 `rc`**（我随后各腿都改成 `rc=${PIPESTATUS[0]}` 或独立跑）。
2. **行数口径**：`wc -l` 与"数据行"不是一回事（本件 §3-① 的发现本身就来自这条）；我引 `:NNN` 一律先 `sed -n` 打原文（`3684–3698`／`3679`／`279`／`154–200`／`110` 都打过）。

---

## §6 收尾

- `$N` 内我**只写本件**；`docs/ROUTES.md`／`verify-all.sh`／`build/close-wave.sh`／被判的册与表与两颗牙**一字未动**（§2-5 ＋ `git status --porcelain -- <五件>` 为空）。
- 沙箱全部在 `~/wv80y/`（`%h==1`、无硬链接、未落 `/tmp`）。
- **判词尾行**：`P1-DG179-VERIFY: verdicts=[PASS,PASS,PASS,PASS,PASS,PASS,PASS] legs=[L0,L1,L2,L2ctl,L3,L4,L5,L6,L7] overturned=2 named=1 NOINFO=8 jaw=c2d0773e5561a9d1 rided=e1ed9a71200a20a9 book=fa1715f3edefb7eb tsv=2f9f55f41cf57622 list=16->15 delta={D-G179} reportid=191/2012(+1/+55 all-t6)`
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ `38c0a3ea89cc8d11` ／ FULL `38c0a3ea89cc8d11f15c86f8c7fa3383dd52216c29c4b7203221011d271d45f1` ／ `wc -l` ＝ 282 行（**不含**本行）／末次读取时刻 `2026-09-28T15:49:31+08:00`／写入方式 **temp ＋ rename**。
