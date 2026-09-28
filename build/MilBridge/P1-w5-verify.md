# P1-W5-VERIFY —— `t49`（W5／`B-12` 修法）**独立复核判词**

- **载体** ＝ 本件（`verifier`；任务 `t51`／attempt `1`；沙箱 `~/wv88y/t51/`，`%h==1`、非 `/tmp`）。
- **被复核** ＝ `scribe` 的 `t49`；**提交 `df5b6d1`**（`2026-09-28T18:04:24+08:00`，`--numstat` 现取：`build/MilBridge/P1-w5-report.md 22 0`／`build/MilBridge/tools/defect-registry-check.sh **16 3**`／`build/MilBridge/tools/defect-registry-declared.tsv **2 1**`；父提交 `3aaaa3e`）。
- **纪律**：一切**自己现取、自己造夹具、自己重建修前对照**，**未复述** `t49` 的报告或交件消息、**未引**我上一件输出当证据；`NOINFO` 既不算绿也不算红；**戳带亚秒**。

---

## §0 快照（读时 `2026-09-28T18:04:19.999089009+08:00` → `18:06:31.921839202+08:00`）

| 项 | 现取 |
|---|---|
| `HEAD` | **`df5b6d1`**（`18:04:24`，＝被复核那笔） |
| `porcelain`（逐行） | `?? build/MilBridge/P1-task0201-criteria.md`（**`t7` 既存**）｜`?? build/MilBridge/P1-w4b-verify.md`（**他车道 t50 载体**）⇒ **无本波遗留、无做坏的声明表** |
| `build/MilBridge/tools/defect-registry-check.sh` | `428` 行／**`243e1879dcc78ee9`**／索引 `100755`／工作树 `755`／mtime `17:59:26` |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `228` 行／**`3e6865661c0c4a8e`**／索引 `100644`／工作树 `644`／mtime `18:01:35` |
| `build/MilBridge/P1-w5-report.md` | `22` 行／`bcbbb81b8640ee14`／末行自证 `6026f71af013b717`（**我复算一致**） |
| **修前判据件**（我自取） | `git show df5b6d1^:…` ⇒ **415** 行／**`c2d0773e5561a9d1`**（＝该笔的父版本，逐字节复取一致） |

---

## §1 判词① —— 修法**真的改了语义**（生成 ⇄ 据以判 不再同源）：**成立**

### 1.1 「生成」侧（现取逐字，`emit_decl()`）

- `for k in KD CS HO AB; do [ -n "${ID2LINE["$k:$id"]:-}" ] && req="$req${req:+,}$k"; done`（引 `req` 生成行）；`pres` 行为 `for k in $ALLKEYS; do …`。
- **`ID2LINE` 的来源**（关键）：`load_maps()` 逐键 `key_path()` 打开**现场 route 件**（`KD`＝`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`CS`＝`docs/CURRENT-STATE.md`／`HO`＝`handoff.md`／`AB`＝`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`，可经 `DRC_*` 覆盖）逐行 `grep -noE "$TOKRE"` 建 `ID2LINE["key:id"]=首现行号`、`IDS_BY_KEY["key"]` ⇒ **这是现读取数，不是声明表的副本**。
- ⇒ `--emit` 落出来的 `req` ＝**发射那一刻的现场出现集**；`--emit` 的**帮助文本**（引 `口径句（t49／B-12 修法）：req ＝ 要求集`那一行）把它**定义为要求集**。

### 1.2 「据以判」侧（现取逐字，`run_check()`）

- **③（原有）**：对**声明表里**每个号的 `req` 逐键要求现场命中，否则 `missing` ⇒ 判词行 `$id req=$k MISSING-IN=$k route=$p`（引 `MISSING-IN=` 那一行）。
- **③′（本笔新增）**：`for k in KD CS HO AB; do case ",$req," in *",$k,"*) continue ;; esac; [ -n "${ID2LINE["$k:$id"]:-}" ] || continue; extra=…` ⇒ 判词行 `$id extra-in=$k route=$(key_path "$k") req=$req first-seen=$k:${ID2LINE["$k:$id"]}`（引 `extra-in=` 那一行），并在判定序列里排在 ④ 之前：`[ -n "$extra" ] && { printf 'DEFREG=FAIL reason=declared-id-extra-in-route%s\n' "$extra"; return 1; }`。
- **为什么不再同源**：③ 的**输入**是**声明表的 `req`**（文件里的数据），③′ 的**输入**是**现场 `ID2LINE`**（扫描得到的出现集）⇒ 两条合取 ⇒ **`req` ≡ 现场 route 出现集**（＝「出现集减去 `req` 必须为空」）。修前只有 ③ ⇒ 手工把 `req` **收窄**只是**从被判集里删键**（欠报不可见）；现在**多一亦必红** ⇒ **同源被打破**（判词侧不再只信声明表）。⇒ **选的是契约的「② 校验侧改判出现集之外的空集」**，不是「① 把 `req` 重新定义成册内文本要求集」。

### 1.3 判词①：**成立**。

---

## §2 判词② —— **两极我自己造夹具重跑**（含我自己重建的**修前对照**）：**成立**

**夹具（全在我车道 `mktemp -d` 内，仓内零残留；`DRC_DECL`＋`DRC_KD/CS/HO/AB/KRJ/KRF/KRP` 七路显式覆盖到仓内真件）**：
- `decl-control.tsv` ＝ 现盘声明表**副本**；
- `decl-wide.tsv` ＝ 把 `D-G179` 的 `req=KD` **加宽**成 `KD,AB`（**`D-G179` 在 `AB` 现取命中 `0`**；`present` 同步加 `AB`，以免先触发「`req ⊄ present`」那条而测错腿）；
- `decl-narrow.tsv` ＝ 把 `D-A1` 的 `req=KD,CS,HO,AB` **收窄**成 `KD`（**`D-A1` 现取命中 KD `6`／CS `11`／HO `15`／AB `15`**；`present` 保持超集）。

| 腿 | 修前版 `c2d0773e5561a9d1`（`df5b6d1^`） | 修后版 `243e1879dcc78ee9`（现盘） |
|---|---|---|
| **控制**（未改声明表） | `rc=0`｜`DEFREG=PASS declared=218 route_ids=218（…；无未声明编号）` | `rc=0`｜`DEFREG=PASS declared=218 route_ids=218（… ∧ **现场 route 出现集未超出 req**；无未声明编号）` |
| **加宽**（`D-G179 req=KD,AB`） | `rc=1`｜`DEFREG=FAIL reason=declared-id-missing-in-route`｜`  D-G179 req=AB MISSING-IN=AB route=…/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `rc=1`｜**同型、同号同键点名** |
| **收窄**（`D-A1 req=KD`） | **`rc=0`｜`DEFREG=PASS declared=218 route_ids=218（…；无未声明编号）` ⇒ 静默绿（`B-12` 的洞本身）** | **`rc=1`｜`DEFREG=FAIL reason=declared-id-extra-in-route`**｜`  D-A1 extra-in=CS route=…/docs/CURRENT-STATE.md req=KD first-seen=CS:193`｜`  D-A1 extra-in=HO … first-seen=HO:161`｜`  D-A1 extra-in=AB … first-seen=AB:3878` |

- ⇒ **加宽必红且点名（号＋键）** ✔；**收窄不再静默**（红＋逐键点名）✔；**「洞真的闭合」的唯一机器证我复算出来了** —— 同一份收窄夹具、**唯一变量＝判据件版本**，修前 `rc=0 PASS`、修后 `rc=1 FAIL` ✔。
- 夹具残留：`build/MilBridge/tools/*.tsv.t49tmp` 与我自己的夹具**均不在仓内**（仓内 `tools/*.tsv` 现取仅 7 个既有台账件；`porcelain` 见 §0）✔。

### 2.1 判词②：**成立**。

---

## §3 判词③ —— 三态自洽 ＋ `--emit` 同趟性：**成立**

- **缺省现跑两遍**（`18:05:54.874332548`／`18:06:0x`）：两遍均 `rc=0`｜`DEFREG=PASS **declared=218 route_ids=218**`（**两值相等**；`declared` 数值只作为现取原始行引用，见 §4）｜`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`｜（旁注行）`DEFREG_EXTRA=KRJ=… KRF=… KRP=…`。
- **`--emit` 同趟性**（`ts=2026-09-28T18:05:54.874332548+0800`）：`--emit` ⇒ `rc=0`／**228 行**／`dcf130b360d1d1e7`；与仓内表（228 行／`3e6865661c0c4a8e`）**剔除 `# DECL-GEN` 行后 `diff` ＝ `0` 行** ⇒ **内容逐字节同趟**（唯一差异是生成时刻）；仓内 `# DECL-GEN = (--emit) 2026-09-28 18:01:35 +0800` **＝该件 `mtime 18:01:35`**（同一秒）⇒ 是**真落文件**、不是声明。

### 3.1 判词③：**成立**。

---

## §4 判词④ —— `--emit` 真落文件 ＋「**未写死** `declared` 数值」：**成立**

- 落文件证据同 §3（`DECL-GEN` 与 `mtime` 同秒；`--emit` 输出与现盘表**除 `DECL-GEN` 外逐字节相同**）。
- **「未写死」我按原始行逐处判**：报告里 `declared=<数字>` 形态命中 **`2`** 处 —— `:11`（**修前对照的原始输出行**，逐字引 `DEFREG=PASS declared=218 route_ids=218（…`）与 `:14`（**成对读数的原始尾三行**，句首自带 `ts=2026-09-28T17:56:53.743+0800`）；两处**都是引用机读原始行**、且报告 `:3` 的 §0 判据**明写**「**不在件内写死 `declared=` 的数值**」；报告里以「**两值相等**」作主张的写法命中 **`2`** 处 ⇒ **判定：不是写死，是引用原始行**（若把原始行也算写死，那「成对读数」这条就自相矛盾 ⇒ 我不能这么判）。**另**：本判词与后续引用一律写「**两值相等 ＋ 现取**」，本件内不落任何 `declared=<数字>` 的主张句。

### 4.1 判词④：**成立**。

---

## §5 判词⑤ —— 未越域：**成立**

- **登记面两件**（现取 vs `HEAD` vs `porcelain`）：`docs/ROUTES.md` **`26841d6ed6fe8085`**（`HEAD` 同值、`porcelain` `0` 行）｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` **`6a1ca425a94c4fae`**（同值、`0` 行）⇒ **一字未改** ✔
- **另加核**：`docs/CURRENT-STATE.md` **`13077b52c938f8af`**（同值、`0` 行）｜`verify-all.sh` **`742175bffd5a175d`**（同值、`0` 行）｜`build/close-wave.sh` **`69c39feabe148c62`**（同值、`0` 行）⇒ **一字未改** ✔
- **`porcelain` 逐行点名**（§0）：仅 `t7` 既存未跟踪件 ＋ 他车道 `P1-w4b-verify.md` ⇒ **本波零余留**；仓内**没有**做坏的声明表（`tools/*.tsv` 现取只有既有 7 件；我的三份夹具都在 `~/wv88y/t51/fix/`）。

### 5.1 判词⑤：**成立**。

---

## §6 判词⑥ —— 判定来源**唯一性**：**成立**

- **口径句落点（同一件，两处内容锚；段序不作判据）**：件 `build/MilBridge/tools/defect-registry-check.sh`
  - **头注释规则清单**：锚 `③′ 现场 route 出现集**超出** req（现场有、而 req 没写）` ⇒ 下一行即「⏪ 口径句（`B-12` 修法／`t49`）：**③ 与 ③′ 合起来 ⇒ `req` ≡ 现场 route 出现集**（`req` ＝ **要求集**）」；
  - **`--emit` 帮助块**：锚 `口径句（t49／B-12 修法）：req ＝ 要求集 —— ③ 缺一必红，③′ **多一亦必红**` ⇒ **同一句由发射端 `printf` 写出**，因此 `defect-registry-declared.tsv` 里那一行（锚 `口径句（t49／B-12 修法）`）是**生成的**，不是手抄的第二份 ⇒ **判定来源唯一** ✔
- **可现算**：该句的谓词（③ ∧ ③′ ⇒ `req` ≡ 现场出现集）就是两条规则的**合取**；我 §2 的三腿夹具**正是这次现算**（控制绿／加宽红／收窄红），且规则文本与实现**逐条对应**：③ 规则 `声明里 req=K1,K2 的编号…一次都没出现` ↔ 实现行 `MISSING-IN=$k`；③′ 规则 `现场 route 出现集超出 req` ↔ 实现行 `extra-in=$k … req=$req first-seen=…`。

### 6.1 判词⑥：**成立**。

---

## §7 追加复核面（队长补充）—— **模式保全**：**成立（`t49` 无回退）＋ 三处历史位移如实记（归 `t48`／`t54`）**

**两口径**（`git ls-files -s` ＝索引；`stat -c %a` ＝工作树），读时 `18:04:57.556495101+08:00`：

| 件 | 索引 | 工作树 | 判定 |
|---|---|---|---|
| `build/MilBridge/tools/defect-registry-check.sh`（**本笔改的**） | `100755` | `755` | **无回退**（两口径都保住了）✔ |
| `build/MilBridge/tools/defect-registry-declared.tsv`（本笔重发） | `100644` | `644` | 正确（数据件）✔ |
| `build/MilBridge/P1-w5-report.md`（本笔新建） | `100644` | `644` | 正确 ✔ |
| `sentinel-spec-check.sh`／`wave-push.sh`／`timestamp-order-check.sh`（`W4a` 三牙） | **`100644`** | **`644`** | **情形③（索引与工作树都丢）** ⇒ **`t48` 那笔的账、归 `t54`**（队长已明示），本件只给现取值 |

- **位移那一笔我自查出来了**（`git ls-tree <rev> -- <件>` 逐笔现取）：三件的**最后一次 `100755`** 分别是 `sentinel-spec-check.sh` ⇒ `1a04da6`｜`wave-push.sh` ⇒ `0e561eb`｜`timestamp-order-check.sh` ⇒ `5b4772b`；而三件在 **`3aaaa3e`**（＝`docs(#81): W4b 合波…`，`17:55:01`，即 `t48` 那笔）**同为 `100644`** ⇒ **位移 100% 归因 `t48` 的合波提交**，与本笔（`t49`）无关 ✔
- **新牙（`W4b`）现取值（观察，不判红）**：`handoff-machine-values-check.sh`／`push-marker-write.sh`／`push-marker-check.sh`／`provider-repro-check.sh` 均 `100644`／`644` —— 它们是**新建件**（无「回退」可言），且仓内调用形态是 `bash <件>` ⇒ 功能面无碍；但与同目录既有牙（如本判据件 `755`）**不统一**，列入观察。

### 7.1 判词⑦：**成立**（`t49` 模式无回退；三处历史位移归 `t48`／`t54`）。

---

## §8 `t49` 的自伤如实性与 `REPORTID`：**成立**

- **我自己现跑** `bash build/MilBridge/tools/report-id-domain-check.sh` ⇒ **`REPORTID=PASS files=210 ids=2091 declared=218`**（`ts=2026-09-28T18:05:54.874332548+0800`）⇒ 「暂定号」那笔**已回绿** ✔
- **自伤记录在载体内逐处可见**（我逐行现取，未引其结论）：`:17` 模式位移根因（`open(tmp)+os.replace` 按 umask 落 `644`）｜`:18` 两条零损伤自伤（补丁锚点写错 ⇒ 断言中止；命令行反引号）｜`:21` **dated 追加**记「第 `7` 处自伤（同族第 `2` 次）」并给出 `REPORTID=FAIL` 当场读数与处置 ⇒ **如实入册** ✔（本判词不要求它无自伤，只核其**如实**）。
- **`req=-` 支的 `NOINFO` 我复核**：`^ID…req=-\t` 数据行现取 **`0`**、件内 `req=-` 字样仅 **`1`** 处（头注释）⇒ 该 `NOINFO(reason=本树无数据行)` **成立** ✔

### 8.1 判词⑧：**成立**。

---

## §9 `NOINFO`（具名，既不算绿也不算红）

1. `NOINFO(reason=重建不出未在册世界)`：`t49` 当时所用**夹具文件**与其临时目录**不在仓内**（已清）⇒ 我只能**自造等价夹具**重跑；本判词的成对对照用的是**我自己的**夹具与**我自取的**修前判据件（`df5b6d1^`）。
2. `NOINFO(reason=本树无数据行)`：`req=-` 支（0 数据行）只由代码路径保证（与 `t49` 的具名一致，我独立复算为 `0` 行）。
3. `NOINFO(reason=未跑整趟门禁)`：跑 `verify-all` 会构建并动九位 ⇒ 本件只跑 `--emit`／缺省现跑／夹具三腿。
4. `NOINFO(reason=未审计其它「既生成又据以判」结构)`：本件只核 `req` 这一格（其余同族结构是否还有 ⇒ 未判）。
5. `NOINFO(reason=他车道在飞)`：`?? build/MilBridge/P1-w4b-verify.md`（`t50` 载体）与 `?? build/MilBridge/P1-task0201-criteria.md`（`t7`）**不计入**本判词。

---

## §10 判词表 ＋「推翻的话」

| # | 复核项 | 判词 | 关键证据（我现取） |
|---|---|---|---|
| ① | 修法真的改了语义（不再同源） | **成立** | 生成侧 `ID2LINE`＋`load_maps()` 读**现场件**；判定侧 ③（声明表 `req`→现场）**∧** ③′（现场 `ID2LINE`→声明表 `req`）⇒ `req` ≡ 现场出现集；实现行 `MISSING-IN=`／`extra-in=… req=$req first-seen=…` |
| ② | 两极夹具（我自己造）＋ 修前对照（我自己重建） | **成立** | 控制 `PASS`（两版）｜加宽 `FAIL`＋点名 `D-G179 req=AB MISSING-IN=AB`（两版）｜**收窄：修前 `rc=0 DEFREG=PASS`（静默绿）／修后 `rc=1 FAIL reason=declared-id-extra-in-route`＋`D-A1 extra-in=CS/HO/AB`** |
| ③ | 三态自洽 ＋ `--emit` 同趟 | **成立** | 两遍 `DEFREG=PASS declared=218 route_ids=218`（两值相等）＋`DECLDRIFT=0 keys=-`；`--emit` 与现盘表**除 `DECL-GEN` 外 `diff`＝0**；`DECL-GEN` 与 `mtime` 同秒 `18:01:35` |
| ④ | `--emit` 真落文件 ＋ 未写死数值 | **成立** | 同上；报告两处 `declared=<数字>` **均为机读原始行引用**（`:14` 自带 `ts=`）、主张写法用「两值相等」 |
| ⑤ | 未越域 | **成立** | `ROUTES 26841d6ed6fe8085`／`KD 6a1ca425a94c4fae`／`CURRENT-STATE 13077b52c938f8af`／`verify-all 742175bffd5a175d`／`close-wave 69c39feabe148c62` **全等于 `HEAD`、`porcelain` 各 0 行**；仓内无做坏声明表 |
| ⑥ | 判定来源唯一性（口径句落点／可现算） | **成立** | 同件两处内容锚（头注释 ③′ 句／`--emit` 帮助块）；表内那份是**发射端生成**；谓词＝③∧③′（我三腿即其现算） |
| ⑦ | 模式保全（队长追加） | **成立**（`t49` 无回退；三处位移归 `t48`／`t54`） | 判据件 索引 `100755`／工作树 `755`；`W4a` 三牙 索引与工作树皆 `644`（情形③、位移笔 `3aaaa3e`）；`W4b` 四新牙 `644`（观察） |
| ⑧ | 自伤如实 ＋ `REPORTID` 回绿 | **成立** | `REPORTID=PASS files=210 ids=2091`；载体 `:17`／`:18`／`:21`（dated 追加）三处自伤在册；`req=-` 数据行 `0` |

- **推翻 `t49` 的话**：**没有**（修法语义、两极、三态、同趟、未越域、口径句唯一性、模式无回退、自伤如实，我逐条独立复现成立）。**未成立/未核**：无。
- **结论**：**`verdict = pass`**（六项判词 ＋ 两条追加面全部成立）。
- **本件自报**：全文 `sha16` 只在交件消息里给；末行只携带 `head -n -1` 口径值（第 `24` 条口径）。

⏪ **dated 追加（本席落定后复取；`ts=2026-09-28T18:07:07.621782729+08:00`）**：本件 §0／§5 的 `porcelain` 读数是**当时刻**读数；**落定后复取已位移**（他车道在飞）：` M build/MilBridge/HANDOFF-NEXT.md`／` M build/MilBridge/P1-w4b-report.md`／` M build/MilBridge/tools/handoff-machine-values-check.sh`／`M  build/MilBridge/tools/sentinel-spec-check.sh`（**已暂存**）／`M  build/MilBridge/tools/timestamp-order-check.sh`（**已暂存**）／`MM build/MilBridge/tools/wave-push.sh`（**暂存＋工作树双改**） ⇒ 均**不属本笔**（本席本回合唯一写＝本件）；**本判词 §5 断言的越域五件我同刻复取仍全部 `== HEAD`**（`ROUTES 26841d6ed6fe8085`／`KD 6a1ca425a94c4fae`／`CURRENT-STATE 13077b52c938f8af`／`verify-all 742175bffd5a175d`／`close-wave 69c39feabe148c62`，`porcelain` 各 `0` 行）⇒ **判词不受位移影响**；另：本件自身模式已由 `600` 改为 `644`（与本波报表件一致，**sha16 未变**）。


⏪ **dated 追加（形态重排记录；`ts=2026-09-28T18:09:32.000000000+08:00` 附近现取）**：本件 §10 `:152` 原句「末行只携带 `head -n -1` 口径值」指的是**机读末行**。我落定后曾把 dated 追加排在机读末行**之后**，使末行变成 dated 行 ⇒ 已**就位重排**（dated 行移到机读末行**之前**），**正文一字未改、删行 `0`**。历史读数（本席记录，仅供对照，**以现取 `sha256sum` 为准**）：重排前全文 `a727b6ea00de6b25`／`156` 行；重排后（本条追加前）全文 `97395eb67091cb4e`／`156` 行；本条追加后的现值见交件消息的现取读数。

⏪ **dated 更正（治本件上一条 dated 的 `ts=` 笔误）**：上一条我写的 `ts=2026-09-28T18:09:32.000000000+08:00` 是**笔误的未来戳**，**判为无效**；该次写盘的**真实时刻（本条追加前现取 `stat -c "%y" build/MilBridge/P1-w5-verify.md`）逐字 ＝ `2026-09-28 18:08:49.834553017 +0800`**。**口径**：本件凡 dated 行的 `ts`，一律**以现取 `stat -c "%y" <本件>` 为准**（本条自身追加后的 `mtime` 见交件消息的现取读数）。本件正文其余部分（§0–§10）**一字未改**。

⏪ **dated 追加（`ts=`写作时刻（现取 `date`）＝ `2026-09-28T18:11:31.147276831%:o`；**裁决权威时刻 ＝ 本件末次写盘 `mtime`，见交件消息的现取读数）**：**本件 §2 的「修前对照」必须显式注入全量 `DRC_*` 才能重跑** —— 这是我本次复核踩到的**方法陷阱**，现取原文为证：旧判据件（``df5b6d1^`` 版，`c2d0773e5561a9d1`／415 行）在 `:55–:56` 用**自身脚本位置**推仓根（`HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`／`R="$(cd "$HERE/../../.." && pwd)"`）⇒ 该件被拷到我的车道 `~/wv88y/t51/` 后，缺省腿会把 `R` 解析成 `$HOME`，当场读数变为 `DEFREG=NOINFO reason=no-declaration decl-file-missing`／`KD=MISSING CS=MISSING HO=MISSING AB=MISSING route_ids=0` ⇒ **假红**（若照此读到 `FAIL` 便是我自己的夹具错，不是被判件的问题）。⇒ **正确重跑式（我采用）**：`env DRC_DECL=<夹具> DRC_KD/CS/HO/AB/KRJ/KRF/KRP=<仓内绝对路径> bash <判据件>`（旧件 `:58–:65` 与现件 `:347–:353` 同族支持这 8 个覆盖）。

**成对六腿复跑（本条追加前现跑，`ts=2026-09-28T18:10:21`／`18:10:53`，夹具＝我自己造的 `~/wv88y/t51/fix/decl-{control,wide,narrow}.tsv`，与现盘表逐行 `diff` 只有那一行极性改动）**：① `control`（＝现盘表原样）：**修前 `rc=0 DEFREG=PASS`／修后 `rc=0 DEFREG=PASS`**；② `wide`（`:101` 行 `D-G179 req=KD` → `req=KD,AB`）：**修前 `rc=1 FAIL reason=declared-id-missing-in-route`**（点名 `D-G179 req=AB MISSING-IN=AB route=…/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）／**修后 `rc=1` 同一 `reason` 同一行**；③ `narrow`（`:1` 行 `D-A1 req=KD,CS,HO,AB` → `req=KD`，`present=KD,CS,HO,AB` 不动）：**修前 `rc=0` 且**全件零 `FAIL` 行 ＝ 静默绿（洞在）**／**修后 `rc=1 FAIL reason=declared-id-extra-in-route`**（点名 `D-A1 extra-in=CS … req=KD first-seen=CS:193`／`extra-in=HO`／`extra-in=AB`）。⇒ **§2 判词② 与全件 `verdict=pass` 结论不变、且判据只收紧**：本次以「显式全量 `DRC_*`」重取，收窄腿的**修前静默绿／修后必红点名**成对复现逐字一致；**新增口径**（本条）：**凡引旧判据件（`df5b6d1^` 那版）当对照，必须显式注入全量 `DRC_*` 或把该件放回仓内原路径，否则其缺省腿读数是夹具错造成的假红／假 `NOINFO`，不得作为判词证据**。本件 §0–§10 与 §9 的 `NOINFO` 清单**一字未改**；本件此前两条 dated 行照旧在册。

⏪ **dated 更正（治本条之上一条的 `ts=` 畸形字面；自伤如实记账）**：上一条我写的格式串 `date '+%Y-%m-%dT%H:%M:%S.%N%:o'` 里 **`%:o` 不是合法格式**（`date` 把 `%:o` 原样吐出）⇒ 该行现取 `ts` 字面 ＝ `2026-09-28T18:11:31.147276831%:o`，**判为无效戳**。**本件自伤第 `4` 处**（前 `3` 处：① 建件时 `600` 后改 `644`；② 把 dated 追加排在机读末行之后又重排；③ 上一条 `ts` 写成未来刻 `18:09:32`）。**正确戳**（现取 `date '+%Y-%m-%dT%H:%M:%S.%N%:z'`，本条写作时刻）＝ `2026-09-28T18:11:40.513740220+08:00`；**权威时刻**仍 ＝ 本件末次写盘 `mtime`（见交件消息现取读数）。**自检口径（新增，只收紧）**：写 `ts` 前必须先把格式串在命令里跑一遍并核 `[0-9]{4}-…\.[0-9]{9}\+08:00`；本件凡 `ts` 一律以现取 `stat -c "%y" <本件>` 为准。
P1-W5-VERIFY: t51 attempt 1 | verdict=pass | 判词①-⑧ 全部成立｜推翻 none｜新增/未核 0 | 语义分离：生成侧 ID2LINE←现场件扫描；判定侧 ③(声明 req→现场) ∧ ③′(现场 ID2LINE→声明 req) ⇒ req ≡ 现场出现集（选②校验侧改判）| 自造夹具三腿：控制 PASS 两版／加宽 FAIL 点名 D-G179 req=AB MISSING-IN=AB 两版／收窄 修前 rc=0 DEFREG=PASS（静默绿）→ 修后 rc=1 FAIL reason=declared-id-extra-in-route 点名 D-A1 extra-in=CS/HO/AB | 判据件 243e1879dcc78ee9/428 行 索引100755 工作树755 | 声明表 3e6865661c0c4a8e/228 行 非注释行 diff=0 注释行 diff=3 | DEFREG=PASS declared=218 route_ids=218（两值相等）+ DECLDRIFT=0 keys=- 两遍同值 | --emit 228 行 dcf130b360d1d1e7 与现盘除 DECL-GEN 外 diff=0 | DECL-GEN 18:01:35 == mtime 18:01:35 | ROUTES 26841d6ed6fe8085 KD 6a1ca425a94c4fae CURRENT-STATE 13077b52c938f8af verify-all 742175bffd5a175d close-wave 69c39feabe148c62 全=HEAD porcelain 0 | REPORTID=PASS files=210 ids=2091 | 模式：t49 无回退；W4a 三牙 644/644 情形③ 位移笔 3aaaa3e 归 t54 | HEAD df5b6d1
