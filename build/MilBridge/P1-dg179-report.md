# P1-W1 收口报告 —— `D-G179` 补成正式条目（**只登记、不实现修法**）＋ 两极化真跑 ＋ 同趟重发 `declared.tsv`

`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜基点 `HEAD=88ab841`（开工时 `porcelain=0`）｜写者 `scribe`（`t6`）
判据件（先写）＝ `build/MilBridge/P1-dg179-criteria.md`（`6f10658432b7a995…`，落盘 `15:44:08`；本件判据即照它执行）
本件写入方式 ＝ **temp ＋ `rename`**｜本件读取时刻见末行。

---

## §0 结论速览

**四条腿全部真跑、结论全部成立**：正极（真树）`DEFREG=PASS`（两遍）＋ `REPORTID=PASS`，且 `D-G179` **已从 `BOOK_ENTRY_UNREQUIRED_MISSING` 名单消失**（`n=16 → 15`，逐号细判命中 `0`）；三条反极各自**真红并点名**。

| 腿 | 构造 | 原始机读结论 | rc |
|---|---|---|---|
| **正极**（真树） | 条目落册 ＋ 同趟重发 | `DEFREG=PASS declared=215 route_ids=215` ∧ `DECLDRIFT=0 keys=-`（两遍）｜`REPORTID=PASS files=190 ids=1957 declared=215`；名单 `n=15`（无 `D-G179`） | `0` |
| **反极 A**（沙箱） | 要求清单副本要求本号成条 ∧ 册内**删**其条目 | `REPORTID=FAIL` ＋ 点名 `D-G179 rule=book-entry-heading-missing`；`BOOK_ENTRY_BINDING required=6 present=5 missing=1` | `1` |
| **反极 A2**（沙箱） | 同上但**不**要求成条 | `BOOK_ENTRY_UNREQUIRED_MISSING n=16 … D-G179 …`（**可见列名、不判红**）｜`REPORTID=PASS` | `0` |
| **反极 B**（沙箱） | **手工**把 `req` 加宽到命中 `0` 的 `HO` | `DEFREG=FAIL reason=declared-id-missing-in-route` ＋ 点名 `D-G179 req=HO MISSING-IN=HO` | `1` |
| **追加腿 C**（沙箱，我加） | **陈旧表**（`req=KD`）＋ 把该号在 `KD` 的提及整体删除 | `DEFREG=FAIL` ＋ 点名 `D-G179 req=KD MISSING-IN=KD`（`DECLDRIFT=1 keys=KD`） | `1` |

⇒ 腿 C 把「恒真」的**射程**钉死为**「同趟 `--emit` 生成的那张表」**：陈旧表上规则③**真的会红**（这一句已如实写进册条目的「边界」段）。

---

## §1 改前原文引用（**一字不删**）＋ 我新增的条目逐字

### 1.1 改前：本册里 `D-G179` 的**唯一**提及（内容锚＝`D-G180` 条目的「编号边界（防误读）」句）

`sed -n '3679p' samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现取（**读时 `15:43:53`，仅本次有效**）：

> - **编号边界（防误读）**：**`D-G179` 已由队长保留**给另一条发现（`defect-registry-check.sh` 的 `req` 列在**自动路径上恒真**：`emit_decl()` 的 `req` 就是 `{KD,CS,HO,AB}` 里的**出现集**、又被校验侧拿去判"每个 route 文件各至少出现一次" ⇒ **同一趟既生成又据以判**），**不是漏号**；本件按配号用 **`D-G180`**。

**形态读数（落册前）**：条目形态标题 `grep -cE '^#{2,4}.*(^|[^0-9A-Za-z-])D-G179([^0-9]|$)'` ＝ **`0`**｜`grep -c 'D-G179'` ＝ **`1`** ⇒ 「**提及即声明、成条无**」。
**该行原文一字未删**：`git diff -- samples/WpfFeatureProbe/KNOWN-DEFECTS.md | grep -c '^-[^-]'` ＝ **`0`**。

### 1.2 新增块逐字（追加在册末，`18` 行；唯一新增内容）

```
## P1-W1 登记批（2026-09-28；**一条入册**：把「提及即声明、册内无条目」的候选补成**正式条目** —— **只登记、不实现修法**；读数全部现取）

### 🆕 **`D-G179`** —— **声明表的 `req` 列在「自动路径」上恒真**：`req` 由**出现集**生成、又被校验侧拿去判「每个 route 文件各至少出现一次」⇒ **规则③结构上不可能红**（**登记面缺陷，不是产品缺陷**；读时 `2026-09-28T15:43:53+0800`）

- **现象（在册读点，逐字）**：`build/MilBridge/HANDOFF-NEXT.md` §下一波未闭项 第 `12` 条逐字：「**`D-G179` 候选：声明表 `req` 列在**自动路径**上恒真**」；本号原先**只在本册 `D-G180` 条目的「编号边界（防误读）」一句里被具名** ⇒ 落册前**条目形态标题计数 ＝ `0`**、`grep -c 'D-G179'` ＝ `1` ⇒ 即**「提及即声明」**（`--emit` 的 `declared` 集 ＝ route 件里**出现过的编号并集**）。
- **根因（机械，可复算）**：`defect-registry-check.sh` 现取 `c2d0773e5561a9d1` —— `emit_decl()` 里 `req` ＝ 该编号在 `{KD,CS,HO,AB}` 四件里的**出现集**；`run_check()` 的规则③正是拿**同一张表**的 `req` 去核「声明的每一个键、现场都至少出现一次」⇒ **生成 `req` 的那个集合与据以判红的那个集合是同一份数据** ⇒ 自动路径上**恒真**。
- **证据（件 ＋ 字段 ＋ 读数 ＋ 时刻）**：
  ① 声明表现取（`:110`）＝ `ID` ＋ TAB ＋ `D-G179` ＋ TAB ＋ `req=KD` ＋ TAB ＋ `present=KD` ⇒ **`req` 只有 `KD` 一个键**；本号在 `docs/CURRENT-STATE.md`／`handoff.md`／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 三件各命中 `0`。
  ② **在册两极化**（`build/MilBridge/VFinal-verify-report.md` §8；沙箱 `~/w31x/dg179/`、真树只读；`t15` 现取 `2026-09-28T12:56:56–12:57:15`）：**正侧**＝`KD` 副本里对一条既有编号（原 `req=AB`、`KD` 命中 `0`；**其号见 `HANDOFF-NEXT.md` 第 `12` 条与 `VFinal-verify-report.md` §8**，本条目**刻意不复录其号**——理由见下「口径句」）**只写一句提及** ⇒ `--emit` 后该行自动变 `req=KD,AB present=KD,AB`、同趟 `DEFREG=PASS declared=215 route_ids=215`（`rc=0`）；**反侧**＝把副本表里同一条编号的 `req`／`present` **手工加宽**到 `HO`（该件命中 `0`）⇒ `DEFREG=FAIL reason=declared-id-missing-in-route` ＋ **逐条点名**该号 `req=HO MISSING-IN=HO`（`rc=1`）。
  ③ 同族但判词不同的两条腿（同 §8）：`req` **收窄**成子集 ⇒ `DEFREG=PASS`（**欠报不可见**）；`req` 塞**非 route 键** ⇒ `DEFREG=NOINFO reason=decl-unparsable`（`rc=2`，**三态未坏**）。
  ④ **本册侧的侧证**：`D-G180` 条目末句逐字「**`D-G179` 已由队长保留**给另一条发现（`defect-registry-check.sh` 的 `req` 列在**自动路径上恒真**…）**不是漏号**；本件按配号用 **`D-G180`**」。
  ⑤ **牙的处置（已登记的缺口）**：`report-id-domain-check.sh` 落册前现取把本号列在 `BOOK_ENTRY_UNREQUIRED_MISSING`（**可见、不判红**；`n=16`，名单逐字含本号）⇒ 本条目落地即销掉这一格「提及即有、成条无」的缺口。
- **判据（机器，三条并列）**：① 同趟 `--emit` 之后 `DEFREG=PASS declared=215 route_ids=215` **三态不变**；② **手工**把 `req` 加宽到**命中 `0`** 的 route 件 ⇒ **必须 `FAIL` 并点名**该号与该键；③ 若 `book-entry-required.tsv` 要求本号成条 ⇒ 册内**必须**有 `^#{2,4}` 的条目形态标题（缺 ⇒ `FAIL` 点名 `rule=book-entry-heading-missing`）。
- **两极化（本波真跑；沙箱不动真树被判件）**：**正极**＝本条目落册 ＋ 同趟重发 ⇒ `DEFREG=PASS`（两遍）｜**反极**＝① 要求清单副本要求本号成条、而册内删其条目 ⇒ `REPORTID=FAIL` **点名**；② 手工加宽 `req` 到命中 `0` 的键 ⇒ `DEFREG=FAIL` **点名**。
- 🔴 **口径句（永久）**：**「凡『声明的键集合』与『据以判红的出现集合』取自同一份数据，这条判据在自动路径上就是恒真的 —— 要它真的会红，必须存在一个**不由同趟生成**的输入（手册加宽／陈旧表／要求集与出现集分离）。」** 同族口径：**「在本册里『提一句』就是『声明一次』」** ⇒ 本条目**刻意不复录任何非必要编号**（只提 `D-G179`／`D-G180`，两者的 `req` 已含 `KD`）⇒ 本趟 `--emit` 的**数据行逐字节不变**。
- **候选修法（本波只登记、不实现）**：① 把 `req` 改成**要求集** —— 由人手声明「要求它出现在哪些 route 件」，与 `present` 的**出现集分离**；② 校验侧改判「**出现集之外的空集**」—— 例如只允许声明「已知在册具名」的编号，其余一律进可见缺口，规则③**不再拿出现集自证**。
- **边界（如实划界）**：① **恒真的射程 ＝ 同趟 `--emit` 生成的那张表**；**陈旧表不在此列** —— 若某号只在某 route 件里出现过、而该提及事后被删，则表里 `req=KD` 而现场命中 `0` ⇒ **规则③会真红**（本波反极腿**实测**，读数见 `build/MilBridge/P1-dg179-report.md`）；② 本波**只登记、不改校验器语义**（`defect-registry-check.sh` 一字未动）；③ 本号**不是产品缺陷**：`D-G180` 是产品面登记，`D-G179` 是**登记面（工具语义）**缺陷，两者**不合并**。
```

**「刻意不复录其号」的理由（一条纪律）**：`--emit` 的 `req` 就是「**在 route 件里出现过**」⇒ 在册里写下一个号，就等于**替它起草声明**。本波只登记 `D-G179`，故**不复录**那条沙箱试验用的既有编号（它在 `HANDOFF-NEXT.md` 第 `12` 条与 `VFinal-verify-report.md` §8 里**已具名**，读者可自取；本条只引其**读数**）。⇒ 机器后果见 §2。

---

## §2 同趟重发 `declared.tsv`（**编辑全部在 `--emit` 之前**）＋「数据行不变」的机器证

**顺序**：册编辑（`rename` `15:44:51`）→ `--emit`（`15:44:51`）→ 此后**未再动** `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（其后全部为只读复算）。

**先预览后落地**（落册**前**就用 `DRC_KD=<临时册>` 预览 `--emit`）：预览结果与旧表**只有 `# DECL-ANCHORS` 一行不同** ⇒ 落地后重发，`diff` 现取**只 `1,2c1,2`**（`# DECL-GEN` ＋ `# DECL-ANCHORS` 的 `KD=`），**`224` 行数据行逐字节不变**：

```
< # DECL-GEN = (--emit) 2026-09-28 14:29:00 +0800
> # DECL-GEN = (--emit) 2026-09-28 15:44:51 +0800
< # DECL-ANCHORS = KD=2152460b7e412352 CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49 KRJ=6351a46296d17b28 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
> # DECL-ANCHORS = KD=fa1715f3edefb7eb CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49 KRJ=6351a46296d17b28 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
```

- `KD` 锚现取 `fa1715f3edefb7eb` ＝ 册现取 `sha256sum` 前 16（**逐位相同** ⇒ 锚与现场一致）；`grep -n 'D-G179' declared.tsv` ⇒ **`:110  ID<TAB>D-G179<TAB>req=KD<TAB>present=KD`（行号/字段一字未变）**。
- `declared.tsv` `sha256` 前 16：`e242e3fbc5f76d77` → **`2f9f55f41cf57622`**。

---

## §3 两极化**原始机读行**（逐字照抄）

**正极（真树，两遍独立进程）**：
```
DEFREG_DECL=n=215 route_ids=215 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
DEFREG=PASS declared=215 route_ids=215（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）      rc=0
（第 2 遍逐字相同，rc=0）
REPORTID=PASS files=190 ids=1957 declared=215 glob=build/MilBridge/*report*.md
BOOK_ENTRY_UNREQUIRED_MISSING n=15 ids=D-E1 D-F1b-ABSENT D-G D-G1 D-G156 D-G159 D-G161 D-G165 D-G33 D-G5 D-G6 D-O1 D-R2 D-R4 D-T1 （**已登记的缺口：可见、不判红**）
BOOK_ENTRY_BINDING required=5 present=5 missing=0
```
**去留（现取，不许假设）**：`D-G179` **已消失** —— 名单 `n` 由 `16` 变 `15`、`grep -c 'BOOK_ENTRY_UNREQUIRED_MISSING.*D-G179'` ＝ **`0`**；**且该行仍在上屏**（非"整行消失"）⇒ 按判据 §3-2 不触发 `NOINFO`。

**反极 A（沙箱 `~/w281-scribe/sbx/A`：要求清单副本要求本号成条 ∧ 册内删其条目）**：
```
BOOK_ENTRY_BINDING required=6 present=5 missing=1
REPORTID=FAIL
  D-G179 rule=book-entry-heading-missing（册里没有条目形态标题）
REPORTID_SCAN files=1 ids=1 declared=215 glob=build/MilBridge/*report*.md      rc=1
```
**反极 A2（同沙箱，不要求成条）**：
```
BOOK_ENTRY_UNREQUIRED_MISSING n=16 ids=D-E1 D-F1b-ABSENT D-G D-G1 D-G156 D-G159 D-G161 D-G165 D-G179 D-G33 D-G5 D-G6 D-O1 D-R2 D-R4 D-T1 （**已登记的缺口：可见、不判红**）
REPORTID=PASS files=1 ids=1 declared=215 glob=build/MilBridge/*report*.md      rc=0
```
**反极 B（沙箱：手工把 `req` 加宽到命中 `0` 的 `HO`）**：
```
DEFREG_DECLMETA=n=1 declared-present-not-matching-live（诊断，**不判红**）:
  D-G179 present-claims=HO BUT-not-live live=KD
DEFREG=FAIL reason=declared-id-missing-in-route
  D-G179 req=HO MISSING-IN=HO route=/home/links-dev/netTest/GitProj/WPFOnLinux/handoff.md      rc=1
```
**追加腿 C（沙箱：陈旧表 `req=KD` ＋ 提及整体删除 ⇒ 现场命中 `0`）**：
```
DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD
  D-G179 present-claims=KD BUT-not-live live=
DEFREG=FAIL reason=declared-id-missing-in-route
  D-G179 req=KD MISSING-IN=KD route=/home/links-dev/w281-scribe/sbx/C/KNOWN-DEFECTS.md      rc=1
```
> 反极 A/B/C 三腿**全部真红并逐条点名**（不是"静默"）；A2 腿是**红的前一档**（可见列名、不判红）⇒ 两档分开报，不混。

---

## §4 两遍 `DEFREG` ＋ `REPORTID` 不退化（契约 `Verify` 原样）

```
cd $N && bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | tail -1
  ⇒ DEFREG=PASS declared=215 route_ids=215（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
cd $N && bash build/MilBridge/tools/report-id-domain-check.sh 2>&1 | tail -2
  ⇒ BOOK_ENTRY_BINDING required=5 present=5 missing=0
  ⇒ REPORTID=PASS files=190 ids=1957 declared=215 glob=build/MilBridge/*report*.md
```
`files=190`／`ids=1957`／`declared=215` **与开工现取逐格相同** ⇒ **未退化**（判据件与报告件都不吃 `*report*.md` 语料：判据件名是 `*-criteria.md`）。

---

## §5 边界与 `NOINFO`

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | 反极腿的 `req` 加宽到 `CS`（而非 `HO`） | 未跑（`NOINFO`，不判） | 本号在 `CS` 同样命中 `0`；`HO` 腿已真跑并点名 ⇒ 不重复造第三档 |
| N2 | `book-entry-required.tsv` 是否**应**把本号列为必需 | **不判**（属队长/下一波） | 本波写域不含该件；只在**沙箱副本**里做过 A 腿构造 |
| N3 | 两个候选修法**本身**的判据 | **不判**（本波只登记） | 派单明确「只登记，不实现修法」；实现须另立波次并自带两极化 |
| N4 | 「提及即声明」是否也影响 `present=` | 已查（非 `NOINFO`） | `present` 与 `req` 同源（同 `ID2LINE`）⇒ 一并变；`DECLMETA` 只诊断、**不判红**（腿 B 原始行可见） |
| N5 | 本波是否动过校验器 | **零** | `defect-registry-check.sh` 现取 `c2d0773e5561a9d1` ＝ 在册值（未改一字） |

---

## §6 越域自证（`porcelain` 逐行点名）

```
 M build/MilBridge/tools/defect-registry-declared.tsv            ← 契约 inScope（同趟重发）
 M samples/WpfFeatureProbe/KNOWN-DEFECTS.md                      ← 契约 inScope（只增 18 行／删 0）
?? build/MilBridge/P1-dg179-criteria.md                          ← 契约允许新建（先写的判据）
?? build/MilBridge/P1-task0201-criteria.md                       ← **不是我所写**（见下）
```
**⚠️ 并发观察（如实报、未触碰）**：开工时 `porcelain` ＝ **空**；会话中途出现未跟踪件 `build/MilBridge/P1-task0201-criteria.md`（`mtime 2026-09-28 15:45:23`／`15224 B`，首行 `# P1-task0201-criteria —— TASK-0201（静默 rc=139＋0 字节日志）现件代复测`）⇒ **另一条写者正在同树工作**。本席**未读写改**它；它对 `DEFREG`／`REPORTID` **无影响**（既非 route 件、也不匹配 `*report*.md` 语料）——`REPORTID files=190` 与开工逐格相同即为机器证。
**未** `git add`／`commit`／`push`；`HEAD` 仍 `88ab841`；暂存区 `0` 行、`stash` `0` 条；临时件（`*.t6tmp`）残留 `0`。
`git diff --numstat`：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` **`18 0`**（删 0）｜`declared.tsv` `2 2`（唯二两行＝`# DECL-GEN`／`# DECL-ANCHORS`）。
**只增不改的独立机器证**：落账器按「旧行**按序子序列**」判定 —— 旧 `3680` 行 → 新 `3698` 行，**未按序复现的旧行数 ＝ `0`**。

---

## §7 自报（写入方式 temp ＋ `rename`）

- 册现取：`3698` 行／`fa1715f3edefb7eb…`（写前 `3680` 行／`2152460b7e412352…`）
- `declared.tsv` 现取：`2f9f55f41cf57622…`（写前 `e242e3fbc5f76d77…`）
- 本件内出现的 `D-G` 编号：`D-G179`／`D-G180`／`D-G152`（**三者现取均在 `declared` 集内**）⇒ `report-id-domain-check.sh` 含本件现取 **`REPORTID=PASS`**。
- 本件整件全量 `sha256` **无法自报**（含末行 ⇒ 自指）⇒ 见交回队长的消息；**自报口径**（末行之前的全文，`head -n -1`）见末行。
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ **`1a17cd6b8489e16d`**（整 64 hex 见交回队长的消息）／本件 `wc -l` ＝ **`170` 行**（含本行；**不含本行 `169` 行**）／末次现取时刻 ＝ `2026-09-28T15:46:13+0800`／写入方式 ＝ **temp ＋ `rename`**／同趟自证（**本行写入之前**现取）：`bash build/MilBridge/tools/report-id-domain-check.sh` ⇒ `REPORTID=PASS files=191 ids=2012 declared=215` `rc=0`（**语料含本件**）。
- ⏪ **dated 更正 · F1（`224` 的量名与数不符）（`t12`，读时 `2026-09-28T15:59:43+0800`；上引原文**一字未删**）**：**改前原文（逐字引）**：「…`diff` 现取**只 `1,2c1,2`**（`# DECL-GEN` ＋ `# DECL-ANCHORS` 的 `KD=`），**`224` 行数据行逐字节不变**」—— **量名与数不符**：`224` 是**全文行数**（含注释），**数据行另有其数**。**我现取自算（三条命令 ↔ 三个数）**：**数据行 ＝ `grep -c '^ID' build/MilBridge/tools/defect-registry-declared.tsv` ⇒ `215`**｜**注释行 ＝ `grep -c '^#' <同件>` ⇒ `9`**｜**全文 ＝ `wc -l < 同件` ⇒ `224`** ⇒ **`215` ＋ `9` ＝ `224`**（与牙自吐的 `DEFREG_DECL=n=215` 同值）。**「数据行逐字节不变」这半句本身成立**：我现算 `diff <(grep '^ID' ~/w281-scribe/bak/declared.tsv.pre-t6) <(grep '^ID' build/MilBridge/tools/defect-registry-declared.tsv)` ⇒ **差集 `0` 行**（同一条命令下**注释锚行**差集 `4` 行 ⇒ 变的只有 `# DECL-GEN`／`# DECL-ANCHORS`）。⇒ **此后写法**：「**全文 `224` 行（`215` 数据行 ＋ `9` 注释行）之中，`215` 行数据行逐字节不变**」。
- ⏪ **dated 更正 · F2（「报告件不吃 `*report*.md` 语料」被推翻）（`t12`，读时 `2026-09-28T15:59:43+0800`；上引括注**原文一字未删**）**：**改前原文（逐字引）**：「`files=190`／`ids=1957`／`declared=215` **与开工现取逐格相同** ⇒ **未退化**（判据件与报告件都不吃 `*report*.md` 语料：判据件名是 `*-criteria.md`）」—— **该括注****只对判据件成立****：**报告件确实吃该语料**。**我现取的成对读数（沙箱 `~/w281-scribe/sbx-t12`；箱内语料 ＝ 本件 ＋ 另一件在册报告，均 `cp` 只读复制）**：**删件前** ＝ `REPORTID=PASS files=2 ids=57 declared=215`｜**只去掉本件后** ＝ `REPORTID=PASS files=1 ids=2 declared=215` ⇒ **本件贡献恰 `+1` 文件／`+55` ids** ⇒ **本件在语料内**。**「未退化」这一****结论****仍成立** —— 真因是**那一刻本件还没落盘**（所以读数仍是 `190`／`1957`），**不是**「不吃语料」；而**判据件确实不吃**（`P1-dg179-criteria.md` 的件名不匹配 `*report*.md`）⇒ **该括注两半对错各一**。
- ⏪ **dated 口径说明 · F3（「落盘／`rename` 时刻」与件 `mtime` 的关系；两个口径不互斥）（`t12`，读时 `2026-09-28T15:59:43+0800`）**：**① 内容写盘 `mtime`** ＝ 临时件被**写**那一刻；**② `rename`（发布）时刻** ＝ `mv` 那一刻 —— 机制 ＝ **`mv` 保留 `mtime`、只更新 `ctime`**。**我现取自证（可复现）**：在 `~/w281-scribe/f3/` 写盘后 `stat -c '%y %z'` ⇒ `mtime=ctime=2026-09-28 15:59:23.365083693 +0800`；**隔 `2` 秒**再 `mv` ⇒ `mtime=``2026-09-28 15:59:23.365083693`**（**未变**）／`ctime=``2026-09-28 15:59:25.367085051`** ⇒ **同一件上两个口径同时成立**。**我 `stat -c '%y %z'` 现取的纳秒值**：**本件** ＝ `mtime=ctime=2026-09-28 15:46:17.823568909 +0800`（末次动作是 `>>` 追加、不是 `mv` ⇒ 两值同刻）｜**判据件** ＝ `mtime=2026-09-28 15:44:06.153013319`／`ctime=2026-09-28 15:44:08.416004191` ⇒ **本件自述的「落盘 `15:44:08`」逐字等于其 `ctime` 的秒 ⇒ 该自述的口径 ＝ `rename` 时刻、不是 `mtime`**。⇒ **此后写时刻一律标明口径**（「内容写盘 `mtime`」／「`rename` 时刻」）；`cp -p` 备份件**保留 `mtime`** ⇒ 是历史 `mtime` 的唯一回溯源。
- ⏪ **dated 口径说明（**非新条目**；属上面三条追加自身的性质）（`t12`，读时 `2026-09-28T15:59:43+0800`）**：本件原来的**末行是自报行**（自报口径 ＝「该行之前的全文」＝ `head -n -1 <本件>`）；上面三条**落在该行之后** ⇒ **该自报行的口径与值都不受影响**（我现算 `head -n 169 build/MilBridge/P1-dg179-report.md | sha256sum | cut -c1-16` ⇒ **`1a17cd6b8489e16d`**，与其自报**逐位相同**）⇒ **此后重算「整件」指纹必须写明是新口径**（追加后整件值见交件消息），**不得**把 `head -n -1` 的新结果读成「自报行错了」。
