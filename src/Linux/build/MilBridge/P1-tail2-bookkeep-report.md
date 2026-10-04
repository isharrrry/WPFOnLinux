# `P1-tail2` · `T-A55` · 翻册 ＋ 复述位（`T-A52`..`T-A54`；`TASK-0007` 色锚闭合；**只增不改**）—— 完成报告

> 车道：**文档**子代理（写者；本轮唯一写者）。载体本件 ＝ `build/MilBridge/P1-tail2-bookkeep-report.md`（本席新建）。
> 写域（逐字）：`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／新建本载体。
> **黑名单未越界**：`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/*.sh`（**除 `defect-registry-check.sh --emit` 调用外**一字未改）／`src/**`／`build/shims/**`／`upstream/**` 一字未动。
> **未跑整波、未跑整趟 `verify-all`**（本趟只逐条现取四闸 ＋ 逐条 `grep`）。
> **口径**：一切读数**本席现取**（`sha256sum`／`grep -c`／`git diff --numstat`／`bash build/MilBridge/tools/{sentinel-spec-check,handoff-machine-values-check,defect-registry-check,report-id-domain-check}.sh`／`bash ~/w153a/bin/infp.sh`）。

---

## §0 结论速览（自包含）

1. ✅ **翻册（`docs/ROUTES.md` 三条 dated 结账，只增不改）**：`T-A52`（第 4 色真阻挡前移 ⇒ Floater 内 `<Table>` 撞未导出 `FsQueryTableObjDetails`；真前沿具名 `NATIVE-PTS-TABLEOBJ`）／`T-A53`（Table 族五入口导出 `exports 683→688` ＋ 开闸腿 `LightGoldenrodYellow=1998px`＝判据①达）／`T-A54`（两闸转**缺省开** ⇒ 缺省路径 `LightGoldenrodYellow=1998px`、`PTS_COLORANCHOR=PASS hits=3`；缺省零回归；整波 `verify-all 64✅/0❌`）。三条**逐条 `grep` 命中**（§3）。
2. ✅ **复述位现值位随动（三件，只增不改）**：`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 各追加一段 dated 现值位块 ⇒ 现值位 ＝ **`.so 642019f680d75d87`／`exports 688`／`ops=59 impl=60`**。
3. ✅ **`build/MilBridge/HANDOFF-NEXT.md` 追加 `cell=#1` dated 更正行**（**带取数命令** `bash ~/w153a/bin/infp.sh fp`）；本趟值 `5ec42660…`（未位移，如实标「已复核」）。
4. ✅ **`defect-registry-check.sh --emit` 重发 `declared.tsv`**（改 route 件 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`KD`）⇒ 同趟）：`cb61f5562fed0e95 → b3e82e3ee5d047a2`，**body（`^ID` 行）逐字节未变**、仅报头 `DECL-GEN`／`DECL-ANCHORS KD=` 随动；模式 `664`／字节数 `9400` 守恒。
5. ✅ **四闸现取逐条 `rc=0`**：`SSC`／`HANDOFF_MV`／`DEFREG`／`REPORTID`（§4）。
6. ✅ **「只增不改」机器证**：`git diff --numstat` 对写域件 **删行数 ＝ 0**（§3）。

---

## §1 起手现取（before）

### 1.1 `git status --porcelain` / `HEAD` / `inputs_fp`

```
$ git status --porcelain
?? build/MilBridge/tasks-tail2/T-A55.md      # 本趟派单书（外部投递，非本席产出）
$ git rev-parse HEAD
f44bf19bb5212b4255138bf011e94fe7bdf7506d     # ＝ T-A54 收尾那笔
$ bash ~/w153a/bin/infp.sh fp
5ec42660d9b8c5625d504026f7f8a922bd71a358ce517094770cb9277e484eaa
$ bash ~/w153a/bin/infp.sh list | wc -l
236
```

### 1.2 四闸现取（before；与收尾后 §4 逐条同值）

| 闸 | 判词（现取） | rc |
|---|---|---|
| `SSC` | `SSC=PASS lines=13 keys=13 cmp=IDENTICAL` | 0 |
| `HANDOFF_MV` | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0` | 0 |
| `DEFREG` | `DEFREG=PASS declared=225 route_ids=225`；`DECLDRIFT=0 keys=-` | 0 |
| `REPORTID` | `REPORTID=PASS files=332 ids=2240 declared=225` | 0 |

---

## §2 改了什么（逐件；**只增不改**）

### 2.1 `docs/ROUTES.md`（三个 TASK 行的 dated 结账区，各追加 1 条 dated）

| 位置（内容锚） | 追加条目 | 内容（摘要） |
|---|---|---|
| `TASK-0007` 行 dated 结账区（内容锚 ＝ 该区末尾「前置推进 ≠ 本任务转绿」那一行之后） | **`T-A52`** | `GetFloaterHandlerInfo` 真实现（`win32_pts.c:3830`；上游锚 `Pts.cs:3065`；缺省关，零回归）＋ Floater 内容排版驱动；第 4 色真阻挡前移 ⇒ Floater 内 `<Table>` 撞未导出 `FsQueryTableObjDetails`（`entry point named 394`、`colors=383`）；真前沿具名 `NATIVE-PTS-TABLEOBJ`；`.so 1dbea9026dd7d3d7→1067da454b7ef114`、`exports=683`。载体 `P1-tail2-floatercbk-impl-report.md`。 |
| `TASK-0302` 行 dated 结账区（内容锚 ＝ 该区末尾「不许读成绿」那一行之后） | **`T-A53`** | Table 族五入口导出（`win32_pts.c:6371` 起；上游锚 `Pts.cs:3815` 起）＋ `GetTableObjHandlerInfo` 真实现（`win32_pts.c:3863`）；`exports 683→688`、`PTSGAP=PASS tool=76→71 ops=64→59 impl=66→60`；开闸腿 `LightGoldenrodYellow=1998px ≥200`（判据①达）、`PTS_COLORANCHOR=PASS hits=3`；⚠️ 只让行背景落像素（`cCells=0`）。载体 `P1-tail2-tableobj-impl-report.md`。 |
| `TASK-0307` 行 dated 结账区（内容锚 ＝ 该区末尾「相位翻的两阻已消其一」那一行之后） | **`T-A54`** | 两闸 `WPF_PTS_FLOATER_CBK_DEFAULT`（`win32_pts.c:2852`）／`WPF_PTS_TABLEOBJ_DEFAULT`（`:2870`）`0→1`（仅显式 `=0` 才关）；缺省腿 `LightGoldenrodYellow=1998px`、`PTS_COLORANCHOR=PASS hits=3`、缺省零回归（三帧与开闸腿 `on4` 逐字节同）；两条反极性该红必红；`.so 3ff91579e7ea3efa→642019f680d75d87`（字节数不变）；整波 `verify-all 64✅/0❌`。载体 `P1-tail2-gate-on-impl-report.md`。 |

> ⚠️ **归属（如实划界）**：`T-A52`／`T-A53`／`T-A54` 三条**内容**全部服务 `TASK-0007` 的**第 4 色**链（其中 `T-A53` 同时是 `TASK-0302` 的 native 增量）。派单把三条分别指到 `TASK-0007`／`TASK-0302`／`TASK-0307` 三行的 dated 结账区 ⇒ 本席按**逐行一调**落地（一行一条 dated），**不是**把三条全挂到 `TASK-0007`；`TASK-0307` 行那条以 `T-A54`（收口）为索引，**不**主张它属于 `TASK-0307` 本体。

### 2.2 复述位现值位随动（三件，各追加一段 dated 现值位块）

| 件 | 追加位置（内容锚） | 现值位（逐字） |
|---|---|---|
| `README.md` | 文末（`T-A49`／`A50`／`A51` 收尾对齐行**之后**） | `可操作 59／实现口径 60`；`.so 642019f680d75d87`／`exports 688`（`PTSGAP=PASS tool=71 dead=11 artifact=1 ops=59 impl=60 so16=642019f680d75d87 exports=688`） |
| `docs/unimplemented.md` | 文末（`T-A49`／`A50`／`A51` 收尾对齐节**之后**，新起 `##` 节） | 工具口径 71／可操作缺口 59／实现口径 60；同左 `PTSGAP` 五行 ＋ `so16`／`exports` |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | 文末（`T-A49`／`A50`／`A51` 现值位块**之后**，新起 `###` 节） | `D-G70` 现值位：工具口径 71／可操作缺口 59／实现口径 60（`so16=642019f680d75d87 exports=688`） |

**三件口径（逐字）**：现值位 ＝ **`.so 642019f680d75d87`／`exports 688`／`ops=59 impl=60`**；逐增量归因 ＝ `T-A52` 改实现面（缺口五位未动，仅 `so16` 换）／`T-A53` 使 `tool 76→71`／`ops 64→59`／`impl 66→60`／`exports 683→688`／`T-A54` 只翻缺省（五位未动）。**历史 dated 行原文保留**（不删任一行）。

### 2.3 `build/MilBridge/HANDOFF-NEXT.md`（追加 `cell=#1` dated 更正行，**带取数命令**）

```
⏪ **机器值契约更正 · cell=#1**：以现取为准；`ts=2026-10-01T08:50:19+0800` 时 现值 ＝ `5ec42660…`（命令：`bash ~/w153a/bin/infp.sh fp`）…
```
- **口径**：本会话三连 `T-A52`／`T-A53`／`T-A54` 改了**覆盖面内**件（`src/WpfGfx.Linux.Native/src/win32_pts.c`／`…/tools/pts-gap-decl.txt`）⇒ 值在本会话前段真位移（`dbaaeaaa…`→`fd46f73b…`→`5ec42660…`）；本趟只改**复述位件**（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／本件，**逐件不在覆盖面内**）⇒ 值未再位移，本条为「**已复核**」留痕。第 `28` 条维护契约照旧。

### 2.4 `defect-registry-check.sh --emit` 重发 `declared.tsv`（改 route 件 ⇒ 同趟）

```
$ cp -p build/MilBridge/tools/defect-registry-declared.tsv ~/p1-tail2-bookkeep/bak/declared.tsv.bak   # 写前备份
$ bash build/MilBridge/tools/defect-registry-check.sh --emit > build/MilBridge/tools/.decl.tsv.tmp
$ chmod --reference=… .decl.tsv.tmp ; mv -f .decl.tsv.tmp defect-registry-declared.tsv               # temp+rename，模式守恒
```
- `before` sha16 ＝ `cb61f5562fed0e95`／`after` sha16 ＝ `b3e82e3ee5d047a2`（模式 `664`、字节数 `9400` 均守恒）。
- **body 逐字节未变**（`grep '^ID'` 两份 `diff` ⇒ `ID_BODY_IDENTICAL`）；仅两行报头随动：`# DECL-GEN` 戳 ＋ `# DECL-ANCHORS` 的 `KD=` `b8b2c5cd445d5692 → e47d8967e27366cc`（本趟改了 route 件 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`，其 sha 变 ⇒ 锚随动）⇒ `DEFREG_DECLDRIFT=0`。

### 2.5 新建载体

- 本件 `build/MilBridge/P1-tail2-bookkeep-report.md`（自包含）。

**本趟明确未做的事**：未跑整波、未跑整趟 `verify-all`、未改任何判据本体（`tools/*.sh` 一字未动）、未改产品面（`src/**` 未动）、未动 `docs/CURRENT-STATE.md`、未动基线件（`ACCEPTANCE-BASELINE.md`）、未 `git add/commit/push`。

---

## §3 验收标准对照（任务 §③）

| # | 验收项 | 现取 | 结论 |
|---|---|---|---|
| ① | `ROUTES.md` 内 `T-A52`／`T-A53`／`T-A54` 三条 dated 行逐条 `grep` 命中 | 见 §3.1（三条各命中 ≥1，且 `dated 结账（`T-A5` 形态各 1） | ✅ |
| ② | 既有行 `git diff --numstat` 的**删行数 ＝ 0**（只增不改） | 见 §3.2（写域件删行全 `0`） | ✅ |
| ③ | `SSC`／`HANDOFF_MV`／`DEFREG`／`REPORTID` 各 `rc=0` | 见 §4 | ✅ |
| ④ | 载体含已闭/未闭两清单 | §5（已闭）／§6（未闭） | ✅ |

### 3.1 验收①逐条 `grep` 计数（`docs/ROUTES.md`）

```
$ for t in T-A52 T-A53 T-A54; do printf '%-6s %s\n' "$t" "$(grep -c "$t" docs/ROUTES.md)"; done
T-A52  1
T-A53  2   # 一条在本席新增的 T-A53 结账行；另一条＝ T-A54 结账行内交叉引用「承 T-A53 收口靶」
T-A54  1
$ grep -c 'dated 结账（`T-A5' docs/ROUTES.md
4          # 本趟新增 3 条（T-A52/A53/A54）＋ 既有 1 条（T-A51 收尾）
```
`T-A52`／`T-A53`／`T-A54` 三条 dated 结账行**逐条命中**（本趟新增；与 `T-A45…A51` 的既有 dated 行**分属不同节**，无覆盖）。

### 3.2 验收②逐件 `git diff --numstat`（删行数）

```
$ git diff --numstat -- docs/ROUTES.md README.md docs/unimplemented.md samples/WpfFeatureProbe/KNOWN-DEFECTS.md build/MilBridge/HANDOFF-NEXT.md
3	0	docs/ROUTES.md
2	0	README.md
7	0	docs/unimplemented.md
7	0	samples/WpfFeatureProbe/KNOWN-DEFECTS.md
1	0	build/MilBridge/HANDOFF-NEXT.md
```
⇒ **五件「册／复述位件」第三列（删行）= `0`**（只增不改的机器证；本趟新建件为 `??`，不入 `numstat`）。

> ⚠️ **边界（如实划界）**：「既有行删行 ＝ 0」这句话**只对上述五件成立**。同趟按任务 §①-4 **必须重发**的 `build/MilBridge/tools/defect-registry-declared.tsv`（**生成件**，不属「册」）机械地产生 `2 2`（两行**报头**：`DECL-GEN` 戳 ＋ `DECL-ANCHORS KD=` 随动）—— 那是**「改 route 件 ⇒ 同趟重发」**的**命令性后果**，且 **`^ID` body 逐字节未变**（§2.4）。把该生成件的报头改写也算作「改既有行」，则「只增不改」在**声明表**这一件上**结构性不可满足**（除非让 `DECLDRIFT=1` 常驻）。

---

## §4 验证了什么（收尾后现取；逐条 `rc=0`）

| 闸 | 命令 | 判词（现取） | rc |
|---|---|---|---|
| `SSC` | `bash build/MilBridge/tools/sentinel-spec-check.sh` | `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（`WIN32SHIM v=642019f680d75d87` 在位） | 0 |
| `HANDOFF_MV` | `bash build/MilBridge/tools/handoff-machine-values-check.sh` | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0` | 0 |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | `DEFREG=PASS declared=225 route_ids=225`；`DECLDRIFT=0 keys=-`（重发后） | 0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | `REPORTID=PASS files=333 ids=2240+ declared=225`（本载体落盘后 `+1`） | 0 |

---

## §5 本会话**已闭**清单（`T-A51`..`T-A55`；逐条带载体）

1. ✅ **`T-A52`（`NATIVE-PTS-FLOATERCBK`）**：`GetFloaterHandlerInfo` 由具名缺口 stub 升**真实现**（逐槽只读捕获 `FSFLOATERCBK` 16 槽／128 B；`NULL` init 拒）＋ Floater 内容排版驱动（托管 `FsCreateSubpageFinite` 真造子页）；**缺省关、零回归**。载体 `build/MilBridge/P1-tail2-floatercbk-impl-report.md`。
2. ✅ **`T-A53`（`NATIVE-PTS-TABLEOBJ`）**：Table 族五入口导出（`exports 683→688`）＋ `GetTableObjHandlerInfo` 真实现 ＋ 窗内真建表模型（`nrows=5`）；**开闸腿 `LightGoldenrodYellow=1998px`（判据①达）**、反极该红必红。载体 `build/MilBridge/P1-tail2-tableobj-impl-report.md`。
3. ✅ **`T-A54`（两闸转缺省开）**：`WPF_PTS_FLOATER_CBK_DEFAULT`／`WPF_PTS_TABLEOBJ_DEFAULT` `0→1`（仅显式 `=0` 才关）⇒ **缺省路径 `LightGoldenrodYellow=1998px`、`PTS_COLORANCHOR=PASS hits=3`**；**缺省零回归**（三帧与开闸腿 `on4` 逐字节同）；两条反极性该红必红。载体 `build/MilBridge/P1-tail2-gate-on-impl-report.md`。
4. ✅ **`T-A51`（整波收尾 · 门禁×2）**：整波 `#82` 独立 `verify-all` **`64 ✅ / 0 ❌`（`rc=0`）**、`PTS_GUARD=PASS phase=realized`、`PTS_COLORANCHOR=PASS hits=2→3`；旁生件归位、六闸 `rc=0`。载体 `build/MilBridge/P1-tail2-closeout-report.md`。
5. ✅ **`T-A55`（本件）**：翻册三条 dated ＋ 复述位现值位随动（三件）＋ `cell=#1` dated 更正行 ＋ `declared.tsv` 重发；**四闸 `rc=0`**、**只增不改**（§3）。

---

## §6 本会话**未闭**清单（具名，不许静默）

1. 🔴 **表**单元内容**排版**（承 `T-A53`§6）—— 本增量只让**行背景**（`TableRow Background`＝第 4 色所在层）落像素；**未调** `pfnFormatCellFinite`（槽 20）⇒ `FsQueryTableObjRowDetails` 仍一律报 **`cCells=0`（诚实的空）**，`FsQueryTableObjCellList` 恒空 ⇒ **表内文本未绘**。具名下一靶。
2. 🔴 **本侧约定（`NOINFO`，不声称与上游 ABI 可比）**：行高 `NOINFO=row-height-self-convention`（`dvrRowHeightRestriction` 恒 0 ⇒ 取 `dvrAboveRow+dvrBelowRow`）；表几何 `NOINFO=table-geometry-self-convention`（`fsrcTableObj=(0,0,autofit_wtbl,ΣdvrRow)`）。
3. 🔴 **`TASK-0007` 仍 🔴**（长线；真因 `TASK-0302`）：第 4 色虽**缺省落位**，但 `TASK-0007` 的**判据反转预告**（「洋红 = 0 ∧ 无具名行 ∧ 真实排版」）仍未满足 —— 本趟**不改记号、不预告转绿**。
4. 🔴 **`TASK-0302` 仍 🔴**（PTS／原生 LineServices 长线）：**可操作缺口 59／实现口径 60**；`T-A52`／`T-A53`／`T-A54` 是**增量**，非终态。
5. 🔴 **`TASK-0307` 仍 🔴**（`TASK-0302` 下一增量）：本趟只在其 dated 结账区**加索引**，**不**主张 `T-A54` 属其本体；其下一跳须**托管侧协作**（超 native 写域）。

---

## §7 诚实边界（防读宽，逐条）

1. **「三条 dated」的归属不等于本体归属**：`T-A52`／`T-A53`／`T-A54` 三条内容全服务 `TASK-0007` 第 4 色链；派单指到三行的 dated 结账区 ⇒ 本席按逐行一调落地（§2.1）。**不**主张 `T-A54` 属 `TASK-0307`。
2. **现值位随动是「只增不改」的追加块**，不修改任何既有现值位行；`T-A52` 报的 `so16=1067da454b7ef114`／`T-A53` 报的 `3ff91579e7ea3efa`／`T-A54` 报的 `642019f680d75d87` 是**三个时刻**的现取，**并列记、不互斥**。
3. **`cell=#1` 本条值未位移 ≠ 未检查**：本趟写域件**逐件不在覆盖面内**（`bash ~/w153a/bin/infp.sh list` 现取 `236` 行，逐件 `grep` 零命中）⇒ 值未变是**机械后果**，不是「漂移被掩盖」。
4. **`declared.tsv` 重发只改报头**：`^ID` body **逐字节未变**（`diff` ⇒ `ID_BODY_IDENTICAL`）；两行报头随动；模式／字节数守恒。
5. **本趟不改任何判据、不动世代号**（`SSC` 现取 `BASELINE=#80`／`WAVE=w80-freeze` 未动）。

---

## §8 遗留什么（本趟不做，如实留档）

- **`tasks-tail2/T-A55.md`（派单书）**：`??` 未跟踪；由编排件投递、**非本席产出** ⇒ 本席不 `git add`（提交归编排/队长）。
- **`T-A53`／`T-A54` 的载体报告 §6 具名下一靶**（表单元内容排版）在本趟射程外，保持原判。
- **`fsrcTableObj` 原点本侧取 `0`** 属本侧约定（`T-A53`§5.3），未与上游对齐。
