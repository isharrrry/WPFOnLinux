# `P1-tail2` · `T-A75` · 翻册 ＋ 复述位（本会话 `T-A61..A74`；**只增不改**）—— 完成报告

> 车道：**文档**子代理（写者；本轮唯一写者）。载体本件 ＝ `build/MilBridge/P1-tail2-bookkeep2-report.md`（本席新建）。
> 写域（逐字）：`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／新建本载体。
> **黑名单未越界**：`build/MilBridge/tools/*.sh`（**除 `defect-registry-check.sh --emit` 调用外**一字未改）／`verify-all.sh`／`build/close-wave.sh`／`src/**`／`build/shims/**`／`upstream/**` **一字未动**。
> **未跑整波、未跑整趟 `verify-all`**（本趟只逐条现取四闸 ＋ 逐条 `grep`）。
> **口径**：一切读数**本席现取**（`sha256sum`／`grep -c`／`git diff --numstat`／`bash build/MilBridge/tools/{sentinel-spec-check,handoff-machine-values-check,defect-registry-check,report-id-domain-check,pts-gap-count-check}.sh`／`bash ~/w153a/bin/infp.sh`）。**读时 `2026-10-02T09:08:09+0800`**（各条另注）。

---

## §0 结论速览（自包含）

1. ✅ **翻册（`docs/ROUTES.md` 五行 dated 入册，只增不改）**：`TASK-0302`（`T-A61`／`A62`／`A65`／`A66`／`A67`／`A74`）／`TASK-0307`（`T-A63` 观测面＋来源承重；`W` 复核 `T-A74`：`C2` 的 `plsrun` 半结构性不存在）／`TASK-0201`（`T-A60`／`A64`）／`TASK-0212`（`T-A60`／`A64`）／`TASK-9908`（`T-A58`／`A59`）—— 五条**逐条 `grep` 命中**（§3.1）。
2. ✅ **复述位现值位随动（三件 ＋ README，只增不改）**：`README.md` §0（六点更正）／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 各追加一段 dated 现值位块 ⇒ 现值位 ＝ **`.so df27801beb222f05`／`exports 846`／`ops 42`／`baseline #81`**。
3. ✅ **`build/MilBridge/HANDOFF-NEXT.md` 追加 `cell=#1` dated 更正行**（**带取数命令** `bash ~/w153a/bin/infp.sh fp`）；本趟值 `0d9ab995…`（未位移，如实标「已复核」）。
4. ✅ **`defect-registry-check.sh --emit` 重发 `declared.tsv`**（改 route 件 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`KD`）⇒ 同趟）：`cf3ba6d83c98bc2f → 5f4f935936acdd61`，**body（`^ID` 行，225 条）逐字节未变**、仅两行报头（`# DECL-GEN` 戳 ＋ `# DECL-ANCHORS` 的 `KD=`）随动；模式 `664`／行数 `235` 守恒。
5. ✅ **四闸现取逐条 `rc=0`**：`SSC`／`HANDOFF_MV`／`DEFREG`／`REPORTID`（§4）。
6. ✅ **「只增不改」机器证**：`git diff --numstat` 对册/复述位件 **删行数 ＝ 0**（§3.2）。
7. ✅ **`docs/CURRENT-STATE.md:9` 无需改**：现取 `BASELINE-FROZEN gen=#81 sha16=7cd1bc5c37a74e8d file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**已是 `#81`**，与派单期望相符 ⇒ 本趟**未动该件**）。

---

## §1 起手现取（before）

```
$ git rev-parse HEAD
faf729a052fd4749f939087a32b1a045911d787c     # ＝ T-A74 收尾后
$ git status --porcelain
?? build/MilBridge/tasks-tail2/T-A75.md      # 本趟派单书（外部投递，非本席产出）
$ sed -n '9p' docs/CURRENT-STATE.md
> BASELINE-FROZEN gen=#81 sha16=7cd1bc5c37a74e8d file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
$ wc -l < src/WpfGfx.Linux.Native/bin/exports.txt
846
$ sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16
df27801beb222f05
$ bash ~/w153a/bin/infp.sh fp
0d9ab99598b58ad8e3f666a440e22b356e08b3b8fc02c9b6ae12a2f2ca526098
$ bash ~/w153a/bin/infp.sh list | wc -l
236
```

- **在册声明行（现取，`tools/pts-gap-decl.txt`）**：`# PTSGAP-DECL: tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846 w66pre16=bf6b683d94549087`。
- **`pts-gap-count-check.sh` 现算对账**：`LIVE tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846`（＝声明值逐字段相等）；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`。
- **覆盖面自证**：本趟写域件**逐件不在覆盖面内**（`bash ~/w153a/bin/infp.sh list` 现取 236 行，逐件 `grep` 零命中）⇒ `inputs_fp` **机械零影响**。

---

## §2 改了什么（逐件；**只增不改**）

### 2.1 `docs/ROUTES.md`（五个 TASK 行各追加 1 条 dated 行；**位置 ＝ 该行 dated 区末尾，子项之前**）

| 位置（内容锚） | 追加条目 | 内容（摘要） |
|---|---|---|
| `TASK-0302` 行 dated 区末（＝ `T-A53` 结账行之后） | **`T-A61`／`A62`／`A65`／`A66`／`A67`／`A74` 合册** | ① `T-A61`（`Fs*` 首批 8 条 ⇒ `ops 58→50`／`exports 689→701`）｜② `T-A62`（`Lo*`/`Nl*` 3 条 ＋ 同族唯一 stub 升格 ⇒ `ops 50→47`／`stubs 1→0`／`exports 701→718`）｜③ `T-A65`（分级 甲5/乙20/丙6/丁16）｜④ `T-A66`（甲类 5 条 ⇒ `ops 47→42`／`exports 718→727`）｜⑤ `T-A67`（丁类 16 ＝ `Lo*` 12 ＋ 文本分析 4）｜⑥ `T-A74`（`W` 5 满足＋2 不满足 ⇒ 丁类 **可诚实实施者 0**）。现值位 `ops=42`／`exports 846`／`stubs 0`。 |
| `TASK-0307` 行 dated 区末（＝ `T-A74` 结账行之后） | **`T-A63` ＋ `W` 复核 `T-A74` 合册** | ① `T-A63`（`[FSQSPL-CONSUME]` `id=ok` 20,378/20,378 ＋ 反腿 `WPF_PTS_QSPL_PROV=0` ⇒ `PTS_GUARD=FAIL`／`hits=0` ⇒ **来源承重**）｜② `W` 复核：`C2` 的 `plsrun` 半**结构性不存在**（绕过 LS 造型、本侧非作者）⇒ `C2` 整条不成立。 |
| `TASK-0201` 行 dated 区末（＝ `t101` 索引行之后） | **`T-A60` ＋ `T-A64` 合册** | ① `T-A60`（在册速率带真窗 ⇒ 闸可判定 `BASELINERATE=FAIL reason=VOID-PREMISE`，如实 FAIL＋②点名；数据源件 `baseline-rate-registered.tsv b4f646b28369813e`／反例 3 条／阈值零改动）｜② `T-A64`（`wpf_queue_push` 的 `tail` 零解引用修：夹具 `tail=0x102` 反腿 `rc=139`／正腿 `rc=0`）。 |
| `TASK-0212` 行 dated 区末（＝ `T-C2` 结账行之后） | **`T-A60` ＋ `T-A64` 合册** | 承 `TASK-0201` 同两条；⚠️ 本补件的**率未重取**（`0/300 ⇒ 0.993608%` 私有扩展口径**一字未动**）。 |
| `TASK-9908` 行 dated 区末（＝ `T-A59` 之后、`dated E5 尝试` 行之后） | **`T-A58` ＋ `T-A59` 合册** | ① `T-A58`（基线件 `bd64f2c1a3eaaa05 → 7cd1bc5c37a74e8d`；`#80→#81`；`verify-all 64✅/0❌ ×2`；六闸 rc=0）｜② `T-A59`（在册证据换代 ⇒ `PTS_COLORANCHOR=PASS k=24 hits=3`；`app_g1.log 0265aeaaac945c1d → d2b15abb935344d7`）。 |

> ⚠️ **归属（如实划界）**：`docs/ROUTES.md` 已由各实现车道各自落过 `T-A63`／`T-A68..A74` 的**详细结账行**（本席**只增**一条**合册索引行**、**不**复制其读数、**不**改其一字）；本趟新增的 dated 行**只**对 `T-A61`／`A62`／`A65`／`A66`／`A67`／`A60`／`A64`／`A58`／`A59` 提供册面结账，并对已被各车道翻过的 `T-A63`／`T-A74` 提供**合册索引**。

### 2.2 复述位现值位随动（三件，各追加一段 dated 现值位块）

| 件 | 追加位置（内容锚） | 现值位（逐字） |
|---|---|---|
| `README.md` | §0 文末（`T-A56`／`A57`／`A58` 现值位块**之后**） | 六点更正：① 「必死 `rc=134`／洋红占位」**已不成立**（`phase=realized`／`magenta=0`／`[HC-UNHANDLED]=0`）；② `TASK-0302` 现值 `ops=42`（`exports 846`／`stubs 0`）；③ 静默 `rc=139` 产品侧已修（`T-A64`）；④ `TASK-0301` 反极性腿**已办**（之前的波次，W161A／`D-G129`）；⑤ `DEFREG declared=225`；⑥ `BASELINE-FROZEN gen=#81`。 |
| `docs/unimplemented.md` | 文末（`T-A52`／`A53`／`A54` 现值位块**之后**，新起 `##` 节） | `.so df27801beb222f05`／`exports 846`／`ops 42`／`stubs 0`／`baseline #81`；逐批随动（`T-A61`／`A62`／`A65`／`A66`／`T-A67`／`T-A74`／`T-A68..A73`）。 |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | 文末（`T-A52`／`A53`／`A54` 现值位块**之后**，新起 `###` 节） | `D-G70` 现值位：`.so df27801beb222f05`／`exports 846`／`ops 42`／`stubs 0`／`baseline #81`；`D-G190` 仍在册。 |

**三件口径（逐字）**：现值位 ＝ **`.so df27801beb222f05`／`exports 846`／`ops 42`／`baseline #81`**；**历史 dated 行原文保留**（不删任一行）。

### 2.3 `build/MilBridge/HANDOFF-NEXT.md`（追加 `cell=#1` dated 更正行，**带取数命令**）

```
⏪ **机器值契约更正 · cell=#1**：以现取为准；`ts=2026-10-02T09:08:09+0800` 时 现值 ＝ `0d9ab99598b58ad8e3f666a440e22b356e08b3b8fc02c9b6ae12a2f2ca526098`（命令：`bash ~/w153a/bin/infp.sh fp`）（**`T-A75` 收尾趟（本会话 `T-A58..A74` 入册）**：本趟只改**复述位件**（逐件**不在覆盖面内**）⇒ 值**未位移**、本条为**已复核**留痕；覆盖面现取 `236`）。**维护契约见第 `28` 条**。
```
- **口径**：本趟改的件（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／本件）**逐件不在覆盖面内** ⇒ `inputs_fp` 未再位移，本条为「**已复核**」留痕。第 `28` 条维护契约照旧。

### 2.4 `defect-registry-check.sh --emit` 重发 `declared.tsv`（改 route 件 ⇒ 同趟）

```
$ cp -p build/MilBridge/tools/defect-registry-declared.tsv ~/p1-tail2-bookkeep2/bak/declared.tsv.bak   # 写前备份
$ bash build/MilBridge/tools/defect-registry-check.sh --emit > build/MilBridge/tools/.decl.tsv.tmp
$ chmod --reference=… .decl.tsv.tmp ; mv -f .decl.tsv.tmp defect-registry-declared.tsv                   # temp+rename，模式守恒
```
- `before` sha16 ＝ `cf3ba6d83c98bc2f`／`after` sha16 ＝ `5f4f935936acdd61`（模式 `664`、行数 `235` 均守恒）。
- **body 逐字节未变**（`grep '^ID'` 两份 `diff` ⇒ `ID_BODY_IDENTICAL`，**225 条**）；仅两行报头随动：`# DECL-GEN = (--emit) 2026-10-02 00:25:49 +0800 → 2026-10-02 09:08:57 +0800` ＋ `# DECL-ANCHORS` 的 **`KD=a6d4fe9737b62ed0 → 83c7f33e2d1c61f6`**（本趟改了 route 件 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`，其 sha 变 ⇒ 锚随动；`CS`／`HO`／`AB`／`KRJ`／`KRF`／`KRP` **未变**）⇒ `DEFREG_DECLDRIFT=0`。

### 2.5 新建载体

- 本件 `build/MilBridge/P1-tail2-bookkeep2-report.md`（自包含）。

**本趟明确未做的事**：未跑整波、未跑整趟 `verify-all`、未改任何判据本体（`tools/*.sh` 一字未动）、未改产品面（`src/**` 未动）、未动 `docs/CURRENT-STATE.md`（已 `#81` ⇒ 无需改）、未动基线件（`ACCEPTANCE-BASELINE.md`）、未动 `docs/ROUTES.md` 的 `T-A63`／`T-A68..A74` 既有结账行、未 `git add/commit/push`。

---

## §3 验收标准对照（任务 §③）

| # | 验收项 | 现取 | 结论 |
|---|---|---|---|
| ① | 各 dated 行逐条 `grep` 命中 | 见 §3.1（`T-A61`／`A62`／`A65`／`A66`／`A67`／`A74`／`A63`／`A60`／`A64`／`A58`／`A59` 全部 ≥1 命中） | ✅ |
| ② | 册/复述位件 `git diff --numstat` 的**删行数 ＝ 0**（`declared.tsv` 报头随动除外，须具名） | 见 §3.2（五件删行全 `0`；`declared.tsv` `2 2` ＝ **报头两行随动**、具名） | ✅ |
| ③ | `SSC`／`HANDOFF_MV`／`DEFREG`／`REPORTID` 各 `rc=0` | 见 §4 | ✅ |
| ④ | 载体含「写入项 → 证据」映射 | §2（逐件表）＋ §4（逐闸） | ✅ |

### 3.1 验收①逐条 `grep` 计数（`docs/ROUTES.md` 现取）

```
$ for t in T-A61 T-A62 T-A65 T-A66 T-A67 T-A74 T-A63 T-A60 T-A64 T-A58 T-A59; do printf '%-6s %s\n' "$t" "$(grep -c "$t" docs/ROUTES.md)"; done
T-A61  2   # 本席新增合册行（TASK-0302）＋ TASK-0720 行既有引用
T-A62  2
T-A65  1   # 本席新增合册行
T-A66  4
T-A67  8
T-A74  3
T-A63  2   # 本席新增合册行（TASK-0307）＋ 既有 T-A63 结账行
T-A60  2   # 本席新增合册行（TASK-0201／0212）
T-A64  2
T-A58  2   # 本席新增合册行（TASK-9908）
T-A59  1
$ grep -c 'dated 翻册（`T-A75`' docs/ROUTES.md
5
```
⇒ 本席新增的 **5** 条 dated 行（`T-A75` 标识）**逐条在位**；被点名的 11 个会话号**全部命中**。

### 3.2 验收②逐件 `git diff --numstat`（删行数）

```
$ git diff --numstat -- docs/ROUTES.md README.md docs/unimplemented.md samples/WpfFeatureProbe/KNOWN-DEFECTS.md build/MilBridge/HANDOFF-NEXT.md build/MilBridge/tools/defect-registry-declared.tsv
2	0	README.md
1	0	build/MilBridge/HANDOFF-NEXT.md
2	2	build/MilBridge/tools/defect-registry-declared.tsv
5	0	docs/ROUTES.md
8	0	docs/unimplemented.md
9	0	samples/WpfFeatureProbe/KNOWN-DEFECTS.md
```
⇒ **五件「册/复述位件」第三列（删行）= `0`**（只增不改的机器证；本趟新建件为 `??`，不入 `numstat`）。

> ⚠️ **边界（如实划界，具名）**：`build/MilBridge/tools/defect-registry-declared.tsv` 机械地产生 `2 2` —— 那是**「改 route 件 ⇒ 同趟 `--emit`」**的**命令性后果**，且 **`^ID` body（225 条）逐字节未变**、变的是**两行报头**（`# DECL-GEN` 戳 ＋ `# DECL-ANCHORS` 的 `KD=`；§2.4）。把该生成件的报头改写也算作「改既有行」，则「只增不改」在**声明表**这一件上**结构性不可满足**（除非让 `DECLDRIFT=1` 常驻）。

---

## §4 验证了什么（收尾后现取；逐条 `rc=0`）

| 闸 | 命令 | 判词（现取） | rc |
|---|---|---|---|
| `SSC` | `bash build/MilBridge/tools/sentinel-spec-check.sh` | `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（`WIN32SHIM v=df27801beb222f05`／`BASELINE=#81`／`BASELINE_SHA16=7cd1bc5c37a74e8d` 在位） | 0 |
| `HANDOFF_MV` | `bash build/MilBridge/tools/handoff-machine-values-check.sh` | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none` | 0 |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | `DEFREG=PASS declared=225 route_ids=225`；`DEFREG_DECLDRIFT=0 keys=-`（重发后） | 0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | `REPORTID=PASS files=350 ids=2263 declared=225`（本载体落盘后 `files +1`） | 0 |
| `PTSGAP`（附） | `bash build/MilBridge/tools/pts-gap-count-check.sh` | `PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846` | 0 |

**「写入项 → 证据」映射（验收④）**：

| 写入项 | 证据（现取） |
|---|---|
| `docs/ROUTES.md` `TASK-0302` dated 翻册行 | §3.1 `T-A61..A74` 命中 ＋ §3.2 numstat `5 0` |
| `docs/ROUTES.md` `TASK-0307` dated 翻册行 | §3.1 `T-A63`／`T-A74` 命中 |
| `docs/ROUTES.md` `TASK-0201` dated 翻册行 | §3.1 `T-A60`／`T-A64` 命中 |
| `docs/ROUTES.md` `TASK-0212` dated 翻册行 | §3.1 `T-A60`／`T-A64` 命中 |
| `docs/ROUTES.md` `TASK-9908` dated 翻册行 | §3.1 `T-A58`／`T-A59` 命中 |
| `README.md` §0 dated 更正行 | `grep -c 'T-A75' README.md` ≥1（§2.2）；numstat `2 0` |
| `docs/unimplemented.md` 现值位块 | numstat `8 0`；含 `.so df27801beb222f05`／`exports 846`／`ops 42`／`baseline #81` |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现值位块 | numstat `9 0`；含同现值位 |
| `build/MilBridge/HANDOFF-NEXT.md` cell=#1 行 | `HANDOFF_MV=PASS`（§4）；numstat `1 0` |
| `build/MilBridge/tools/defect-registry-declared.tsv` 重发 | `DEFREG=PASS`／`DECLDRIFT=0`；`ID_BODY_IDENTICAL`（§2.4） |

---

## §5 本会话**已闭**清单（`T-A58`..`T-A74`；逐条带载体）

1. ✅ **`T-A58`（`TASK-9908` 重冻 `#81`）**：基线件 `bd64f2c1a3eaaa05 → 7cd1bc5c37a74e8d`（`1,238,130 B`；`#80→#81`）；`verify-all 64✅/0❌ ×2`；六闸 rc=0。载体 `build/MilBridge/P1-tail2-freeze81-report.md`。
2. ✅ **`T-A59`（在册证据换代）**：`evidence/**` 换代 ⇒ `PTS_COLORANCHOR=PASS k=24 hits=3`（旧 `hits=2`）。载体 `build/MilBridge/P1-tail2-evidence81-recon.md`。
3. ✅ **`T-A60`（基线率闸 = 可比时间窗）**：闸由 `NOINFO-NO-WINDOW` 转**可判定**（`BASELINERATE=FAIL reason=VOID-PREMISE`）；阈值/判据零改动。载体 `build/MilBridge/P1-tail2-baserate-impl-report.md`。
4. ✅ **`T-A61`（`Fs*` 首批 8 条）／`T-A62`（`Lo*`/`Nl*` 3 条 ＋ stub 升格）／`T-A66`（甲类 5 条）／`T-A65`（分级）／`T-A67`（丁类侦察）／`T-A74`（`W` 复核 ＋ 丁类裁决）**：`TASK-0302` 增量；丁类 **可诚实实施者 0**。载体 `build/MilBridge/P1-tail2-{gapbatch1,gapbatch2,gapgrade-recon,gapbatch3,dingrecon,dingimpl}*.md`。
5. ✅ **`T-A63`（观测面＋来源承重）**：载体 `build/MilBridge/P1-tail2-lsprov-impl-report.md`。
6. ✅ **`T-A64`（产品侧 `wpf_queue_push` 零解引用修）**：载体 `build/MilBridge/P1-tail2-segvres-impl-report.md`。
7. ✅ **`T-A68..A73`（`W` 合取逐条落地，`exports 727→846`）**：已在 `docs/ROUTES.md` `TASK-0307` 行各有结账行（本席只作合册索引）。
8. ✅ **`T-A75`（本件）**：翻册五行 ＋ 复述位三件 ＋ `cell=#1` 更正行 ＋ `declared.tsv` 重发；**四闸 `rc=0`**、**只增不改**（§3）。

---

## §6 本会话**未闭**清单（具名，不许静默）

1. 🔴 **`TASK-0007` 仍 🔴**（长线；真因 `TASK-0302`）：第 4 色虽**缺省落位**（`hits=3`），但判据反转预告（「洋红 = 0 ∧ 无具名行 ∧ 真实排版」）仍未满足 —— 本趟**不改记号、不预告转绿**。
2. 🔴 **`TASK-0302` 仍 🔴**（PTS／原生 LineServices 长线）：**`ops=42`／`impl=42`／`stubs 0`**；`T-A61`／`A62`／`A66` 是**增量**（且各批 8＋4＋5 条**在现产品路径未被调用**），非终态；`T-A67`／`A74` 判丁类 16 条**可诚实实施者 0**（`W` ⊉ 真前置 ＋ LS 链已被 shim 替换）。
3. 🔴 **`TASK-0307` 仍 🔴**（`TASK-0302` 下一增量）：`C2` 的 `plsrun` 半**结构性不存在**、`C4` 须"内容层那一波"新立；本趟只作合册索引。
4. 🔴 **静默 `rc=139` ∕ `TASK-0211`**：`T-A64` 修掉 `D-G109` 同根因另一半（确定性静默 SEGV），但**率未重取**（具名 `NOINFO`）、**不宣称清零**；残余窄 `TOCTOU`（`TASK-0211`）**另计**。
5. 🔴 **`D-G190`**（`WpfLinuxWin32_PumpOnce` 写越界 ⇒ fortify `abort()`）**仍在册**（修法未做）。
6. ⚠️ **`[E3-REPLAY]` 未补入在册 `silenthit-trim.tsv`**（`T-A60` 载体 §7 具名待办；动覆盖面内件 ⇒ 需同趟追写 `cell=#1`）—— 越本件写域，**另派**。

---

## §7 诚实边界（防读宽，逐条）

1. **本趟不改任何产品面／判据件**：`src/**`／`build/shims/**`／`tools/*.sh`（除 `--emit` 调用外）**一字未动**；`docs/CURRENT-STATE.md`／基线件**一字未动**。
2. **本趟的新增 dated 行是「合册索引」**，不替代各实现车道各自的**详细结账行**（`T-A63`／`T-A68..A74` 的细节仍以各载体为准）。
3. **`cell=#1` 本条值未位移 ≠ 未检查**：本趟写域件**逐件不在覆盖面内**（现取 `infp.sh list` 236 行、逐件 `grep` 零命中）⇒ 值未变是**机械后果**，不是「漂移被掩盖」。
4. **`declared.tsv` 重发只改报头**：`^ID` body（225 条）逐字节未变；两行报头随动；模式／行数守恒。
5. **「必死 `rc=134` 已不成立」是引在册读数**（承 `T-A33` 起回填链 ＋ `T-A45..A57` 色锚链），本趟**未独立复跑**两页腿（如实标注为**引他人载体**）。

---

## §8 遗留什么（本趟不做，如实留档）

- **`tasks-tail2/T-A75.md`（派单书）**：`??` 未跟踪；由编排件投递、**非本席产出** ⇒ 本席不 `git add`（提交归编排/队长）。
- **`[E3-REPLAY]` 补入 `silenthit-trim.tsv`**（§6-6）在本趟射程外，保持原判。
- **`D-G190` 修法**（§6-5）在本趟射程外，保持原判。
