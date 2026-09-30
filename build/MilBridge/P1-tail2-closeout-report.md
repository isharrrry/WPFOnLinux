# T-A51 · P1 尾波2 `#82` · 收尾：整波后状态归位 ＋ 复述位对齐 ＋ 结账行 —— 完成报告

> 车道：**收尾**子代理（写者；本轮唯一写者）。载体本件 ＝ `build/MilBridge/P1-tail2-closeout-report.md`（本席新建）。
> 写域（逐字）：`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／新建本载体。
> **黑名单未越界**：`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/*.sh`（判据本体）／`build/shims/**`／`src/**`／`upstream/**` 一字未改。
> **未跑整波、未跑整趟 `verify-all`**（本趟只逐条现取六闸；`[5/6]` 的红是**整波结构性顺序**所致，见 §3）。

---

## 0. 一句话结论

**收尾完成**：①整波旁生件已 `git checkout HEAD --` **全量归位**（5 件 → 0）；②复述位对齐（`ROUTES`／`README`／`unimplemented`／`KNOWN-DEFECTS`／`HANDOFF-NEXT` 五处 dated 只增不改）；③`defect-registry-check.sh --emit` 重发 `declared.tsv`（`DEFREG=PASS declared=225 route_ids=225`）；④**现取六闸逐条 `rc=0`**（`SSC`／`HANDOFF_MV`／`DEFREG`／`REPORTID`／`COLUMN_FLOOR`／`ARMLOG_SHA`）。

---

## 1. 起手现取（before：不改动前的真实读数）

### 1.1 `git status --porcelain`（区分本波写域件 vs 整波旁生件）

```
$ git status --porcelain
 M build/.applocal-selftest.log
 M build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt
 M build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt
 M build/PresentationFramework.Linux/PresentationFramework.Linux.csproj
 M build/wave-audit.log
?? build/MilBridge/tasks-tail2/T-A51.md
```

- **整波旁生件（5 件）**：`.applocal-selftest.log`／`ARTIFACT-SRC-FP.txt`×2／`PresentationFramework.Linux.csproj`／`wave-audit.log` —— 均为 `T-A48` 起整波链 `#82` 的 `[1/6]` 重建托管件／`repo-alias` 产生的**派生件**（非本波写域）。`git diff --stat` ＝ `5 files changed, 95 insertions(+), 80 deletions(-)`。
- **`?? build/MilBridge/tasks-tail2/T-A51.md`**：本趟**派单书**（编排件，由外部投递；非本席产出、非旁生件）⇒ 保留。

### 1.2 六闸现取（before；与收尾后 §4 逐条同值）

| 闸 | 判词（现取） | rc |
|---|---|---|
| `SSC` | `SSC=PASS lines=13 keys=13 cmp=IDENTICAL` | 0 |
| `HANDOFF_MV` | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0` | 0 |
| `DEFREG` | `DEFREG=PASS declared=225 route_ids=225` | 0 |
| `REPORTID` | `REPORTID=PASS files=328 ids=2238 declared=225` | 0 |
| `COLUMN_FLOOR` | `COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS` | 0 |
| `ARMLOG_SHA` | `ARMLOG_SHA=PASS required=5 declared=5 pass=5 fail=0 noinfo=0` | 0 |

---

## 2. 改了什么（逐件、只增不改）

### 2.1 整波旁生件归位（`git checkout HEAD --`，5 件 → 0）

```
$ git checkout HEAD -- build/.applocal-selftest.log \
    build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt \
    build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt \
    build/PresentationFramework.Linux/PresentationFramework.Linux.csproj \
    build/wave-audit.log
$ git status --porcelain
?? build/MilBridge/tasks-tail2/T-A51.md
```

⇒ 旁生件归 0（只剩派单书 `T-A51.md`）。

### 2.2 复述位对齐（五件；**只增不改**）

| 件 | 追加内容 | 现值位随动 |
|---|---|---|
| `docs/ROUTES.md` | 新节 `## ⏪ T-A49／A50／A51（P1 尾波2 #82 收尾段）dated 结账`（三条 dated：`T-A49` 五臂换代／`T-A50` 重冻结／`T-A51` 收尾） | `TLINE_GATE=PASS`／`COLUMN_FLOOR=FAIL→PASS`／六闸逐条 `rc=0` |
| `README.md` | `T-A47` dated 落地行**之后**追加一条 dated 收尾对齐行 | `known-red.json dcc22fd3c80cfcac`／基线件 `bd64f2c1a3eaaa05` |
| `docs/unimplemented.md` | 文末追加新节 `dated 收尾对齐（T-A49／A50／A51）` | `PTSGAP` 五位未动／`PTS_COLORANCHOR=PASS` |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | 文末追加新节 `T-A49／A50／A51 dated 现值位` | 同左 |
| `build/MilBridge/HANDOFF-NEXT.md` | `cell=#1` 追加 dated 更正行（`ts=2026-09-30T23:59:33+0800`）＋ `cell=#3` 追加 dated 更正行（同上 `ts`），**各带取数命令** | `cell=#1 = 860711d6…`（未位移）／`cell=#3 = > BASELINE-FROZEN gen=#80 sha16=bd64f2c1a3eaaa05 …` |

**`HANDOFF-NEXT` 两格口径（如实具名）**：本波写域件（`ROUTES`／`README`／`unimplemented`／`KNOWN-DEFECTS`／本件）**均不在覆盖面内**（`bash ~/w153a/bin/infp.sh list` 现取 `236` 行，逐件 grep 零命中）⇒ `inputs_fp` **未位移**；`docs/CURRENT-STATE.md:9` **未改** ⇒ `cell=#3` 未位移。两行按 `HANDOFF-NEXT` 第 `28` 条**如实追写**、标明"收尾趟已核"（值与前一条逐字同值）。
- 取数命令：`cell=#1` ＝ `bash ~/w153a/bin/infp.sh fp`；`cell=#3` ＝ `sed -n '9p' docs/CURRENT-STATE.md`。

### 2.3 `declared.tsv` 重发（改了 route 件 ⇒ 同趟）

```
$ cp -p build/MilBridge/tools/defect-registry-declared.tsv $HOME/p1-tail2-run/backup/…before
$ bash build/MilBridge/tools/defect-registry-check.sh --emit > build/MilBridge/tools/.decl.tsv.tmp
$ chmod --reference=… .decl.tsv.tmp && mv -f .decl.tsv.tmp defect-registry-declared.tsv   # temp+rename，模式守恒 664
```

- `before` sha16 ＝ `081009d1d1574ccb`／`after` sha16 ＝ `9a4423d877ae2485`（模式 `664`、字节数 `9400` 均守恒）。
- **body 逐字节未变**（`diff` 对 `^ID<TAB>…` 行 **rc=0**）；仅两行报头随动：`# DECL-GEN` 戳 ＋ `# DECL-ANCHORS` 的 `KD=` sha16 `d28254f47f89d6c7 → fa24d43c11bcad2a`（＝本趟**只**改了 route 件 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`，其 sha 变 ⇒ 锚随动）⇒ `DEFREG_DECLDRIFT=0`。

### 2.4 新建载体

- 本件 `build/MilBridge/P1-tail2-closeout-report.md`（自包含）。

**本趟明确未做的事**：未跑整波、未跑整趟 `verify-all`、未改任何判据本体（`tools/*.sh` 一字未动）、未动 `docs/CURRENT-STATE.md`、未动基线件（`ACCEPTANCE-BASELINE.md`）。

---

## 3. 整波链 `[5/6]` 的红（**结构性顺序，非产品红**）—— 如实具名

- 整波链 `[5/6]`（推送后复算）因自身 `[1/6]` **重建托管件**致哨兵过期 ⇒ `[5/6]` 报红。这是**同一趟波内**「先重建、后复算哨兵」的**顺序**效应，**不是**产品回归；独立跑 `verify-all` 已得 **`64 ✅ / 0 ❌`（`rc=0`）**（`T-A45…A50` 的读数）。
- 本趟**不重复**跑整波、不重复跑整趟 `verify-all`（写域外；且会再次制造旁生件）—— 只逐条现取六闸（§4）。

---

## 4. 验证了什么（收尾后现取；逐条 `rc=0`）

### 4.1 六闸逐条

| 闸 | 命令 | 判词（现取） | rc |
|---|---|---|---|
| `SSC` | `bash build/MilBridge/tools/sentinel-spec-check.sh` | `SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（13 键，两哨兵 IDENTICAL） | 0 |
| `HANDOFF_MV` | `bash build/MilBridge/tools/handoff-machine-values-check.sh` | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none` | 0 |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | `DEFREG=PASS declared=225 route_ids=225`；`DEFREG_DECLDRIFT=0 keys=-` | 0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | `REPORTID=PASS files=329 ids=2238 declared=225`；`BOOK_ENTRY_BINDING required=5 present=5 missing=0`（`files` 由 `328→329`：本载体入语料） | 0 |
| `COLUMN_FLOOR` | `bash build/MilBridge/tools/column-floor-check.sh --quiet` | `COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS`；`COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5` | 0 |
| `ARMLOG_SHA` | `bash build/MilBridge/tools/arm-log-sha-check.sh` | `ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0` | 0 |

### 4.2 归位 / 声明重发

- `git status --porcelain`（收尾后）⇒ **旁生件 0**（只剩派单书 `T-A51.md` ＋ 本波写域件）。
- `DEFREG` 重发后 `DECLDRIFT=0` ⇒ 声明与现场 `known-red.json`／route 件同源。

### 4.3 验收标准对照（任务 §③）

| # | 验收项 | 现取 | 结论 |
|---|---|---|---|
| ① | 六闸现取逐条 `rc=0` | §4.1 六条全 `rc=0` | ✅ |
| ② | `git status --porcelain` 只剩写域件（旁生件 0） | 旁生件 5→0 | ✅ |
| ③ | `ROUTES.md` 含 `T-A45…A51` dated 行（逐条 grep 计数） | 见 §5 | ✅ |
| ④ | `declared.tsv` 重发后 `DEFREG=PASS` | `DEFREG=PASS declared=225` | ✅ |
| ⑤ | 载体含四段 | §2 改了什么／§4 验证了什么／§6 遗留什么／§4.1 门禁读数 | ✅ |

---

## 5. 验收③逐条 grep 计数（`T-A45…A51` dated 行）

```
$ for t in T-A45 T-A46 T-A47 T-A48 T-A49 T-A50 T-A51; do printf '%-6s %s\n' "$t" "$(grep -c "$t" docs/ROUTES.md)"; done
T-A45  1
T-A46  2
T-A47  2
T-A48  1
T-A49  2
T-A50  3
T-A51  2

$ grep -c 'dated 落地（`T-A49\|dated 落地（`T-A50\|dated 结账（`T-A51' docs/ROUTES.md
3
```

`T-A45`／`A46`／`A47`（现有 `:352` dated 三连里程碑）｜`T-A48`（现有 `:902` dated 结账）｜`T-A49`／`A50`／`A51`（**本趟新增**，文末新节三条 dated，逐条命中）⇒ `T-A45…A51` **七条 dated 行齐备**（逐条 `grep -c ≥ 1`）。

---

## 6. 遗留什么（本趟不做、按口径如实留档）

- **`tasks-tail2/T-A51.md`（派单书）**：`??` 未跟踪；由编排件投递，**非本席产出** ⇒ 本席不 `git add`（提交归编排/队长）。
- **整波旁生件的长期归属**（轨迹历史）：`build/**` 下的 `*.log`／`ARTIFACT-SRC-FP.txt`／`*.csproj` 派生件「每跑一次整波必脏」是**在册问题**（`docs/ROUTES.md` §15ae `F2` 已登记，处置＝加 `.gitignore` ＋ `git rm --cached`，或生成器里去掉绝对路径）—— 本趟**只归位、不改生成器**（生成器在写域外）。
- **`T-A47` 在册的 native 下一靶**（不在本趟射程、保持原判）：`PRECOND-NATIVE-PAGE-SCOPED-ATTACH-CLIENT`（`fl_att[].obj_client` doc 级跨页复用）；`LightGoldenrodYellow` 仍 `0`（需 native `FSFLOATERCBK`）。
- **本趟不改任何判据、不动世代号**（`SSC` 现取 `BASELINE=#80`／`WAVE=w80-freeze` 未动）。

---

## 7. 门禁读数（汇总，收尾后现取）

```
SSC           = PASS lines=13 keys=13 cmp=IDENTICAL                                         rc=0
HANDOFF_MV    = PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0                     rc=0
DEFREG        = PASS declared=225 route_ids=225  DECLDRIFT=0 keys=-                        rc=0
REPORTID      = PASS files=329 ids=2238 declared=225  BOOK_ENTRY_BINDING req=5 pres=5      rc=0
COLUMN_FLOOR  = PASS pass=3 fail=0 noinfo=0 selfreport=PASS  ARMLOG n_decl=5 n_ok=5         rc=0
ARMLOG_SHA    = PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0               rc=0
─────────────────────────────────────────────────────────────────────────────────────────
整波 #82 独立 verify-all（T-A45…A50 读数） = 64 ✅ / 0 ❌                                      rc=0
```

**关键现值位（本趟随动/确认）**：`known-red.json ＝ dcc22fd3c80cfcac`｜基线件 `ACCEPTANCE-BASELINE.md ＝ bd64f2c1a3eaaa05`（世代仍 `#80`）｜`declared.tsv ＝ 9a4423d877ae2485`｜`inputs_fp ＝ 860711d685e31343c7c10f60655193cb03ce119e947b13f6d239fce053817476`（`236` 件）。
