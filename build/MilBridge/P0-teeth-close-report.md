# P0-teeth-close-report —— 关五处同族残留（`t19`：包件源旧路径牙 ＋ roster 扩面 ＋ 在册九位对拍 ＋ 登记≠入册 ＋ 两处硬化）

> **一句话**：五组**都落了件并各带两极化**；**A**/**D** 组各新增一条牙（selftest 8/8 与 5/5），**B**/**C/F** 组把既有牙（`wave-freeze-consistency-check.py`）从**固定 22 条 roster** 扩成**派生式 roster（168 条派生式 / 35 个根站点）**并**新增第四档 `WFREEZE_BLOCKVALUES`**（九位行 ∧ `BASELINE tier=` 行 ∧ **现取** 三方对拍；selftest 13/13）；**E** 组把"判定不是 `cwd` 的函数"变成**有读数的臂**（两个 `cwd` 下判词行逐字相同）。
> ⚠️ **两件必须让主控先知道**：① **档② `WFREEZE_DECL` 今天在真树上是红的**（`docs/WAVE78-PREREGISTRATION.md:30` 声明 3 键 vs `GENS['#78']` 实为 6 键）—— **先于我存在**、不是我引入的，但会挡下一次冻结；② **`t20` 正在并发落地**（本报告读数窗口内 `close-wave.sh`／`verify-all.sh` 已被改、覆盖面 `217 → 219`）⇒ 按派单硬约束**我一个字都没动这两件**，接线补丁以文本给出、等 `t20` 落完再一次性算准。

---

## §0 快照与「读数窗口」声明（**这决定你能怎么用本报告的读数**）

| 项 | 值 |
|---|---|
| 时刻 | `2026-09-27T11:52:54+08:00`（所有读数在同一分钟内现取） |
| `HEAD` | `993eb5d522495d50d3d15b1f2bb1826111352832`（`#78` 已推送态，`t19` **未提交**） |
| `porcelain` | **9**（不为 0！见下） |
| `inputs_fp` | 本件现算 **`55e3f855…`**（**不可与冻结值比**，见下） |
| 覆盖面 | `~/w153a/bin/infp.sh list \| wc -l` = **217**（`t20` 落完为 **219**，`[42] --expect 217 → 219`） |
| 资源 | `df` 可用 100,759,896 KB（46%）｜`available ≈ 5.7 GB`｜`SwapFree ≈ 1.14 GB`（均高于派单硬闸；本件**未起重活/未占槽**） |

**⚠️ 并发落地窗口（`D-G130`／`D-G114` 同族，必须显形）**：本件读数期间**另一条车道（`t20` `migrator`）正在落仓** —— 现取证据：`git status --porcelain` 在窗口内由 **3 行变 9 行**，其中 ` M build/close-wave.sh`（`+2` 行）与 ` M verify-all.sh`（`1` 行，即 `--expect 217 → 219`）**不是我的写域**，另有两件新牙 `build/MilBridge/tools/root-entries-allowlist-check.sh`／`wiring-closure-check.sh` 落地；`?? build/MilBridge/V78-verify-report.md` 亦非本件所出。
⇒ **结论**：① 本报告里**凡与"树的全量状态"有关的读数**（`inputs_fp`／覆盖面件数／roster 条数）**只对该窗口成立**，**不可**当冻结依据；② 我**唯一**能干净归因的位移是**背靠背只差本件**的那一对（见 §C-3）。
**⚠️ 窗口关闭后的复测（`2026-09-27T11:56`）**：`t20` 的那些改动**现已不在工作树里** —— `git diff build/close-wave.sh` 与 `git diff verify-all.sh` **均为空**，`verify-all.sh` 的 `[42] --expect` **回到 `217`**，`git status --porcelain` 只剩**本件**的改动（另有别家新件 `build/MilBridge/V78-verify-report.md`／`docs/WAVE79-PREREGISTRATION.md`）。⇒ **本报告的接线补丁按现取 `217 + 6`（＝`223`）给**，但**仍须在真正落地那一刻一次现取算准**。**这一格本身是 `D-G163` 同族的现场**：**并发窗口内的全量读数不可当基线**。

---

## §A 组 —— 包件源「旧路径默认值」牙（**新件**；`D-G137`／`D-G151` 同族）

**新件**：`build/MilBridge/tools/pkg-src-retiredpath-check.sh`（`a420426eea307eff`）＋ **声明式出处清单** `build/MilBridge/retired-path-provenance.tsv`（`10d62946231cc809`）。

**两个射程面（**先写死**，逐字见件头）**
- **面① `--paths-file <F>`（落地前）**：吃**即将入仓的件**清单（落仓器／`close-wave.sh` 落地前段喂进来）⇒ **任一处 `code` 命中 ⇒ 必红且**不认任何豁免（连 `code-evidence-source` 也不认）。
- **面② `--staged`／`--tree`（落地后兜底）**：`code` 命中 ⇒ 红；若该件被声明为 `code-evidence-source` ⇒ **逐条上屏放行**（**必须**带 `registered=<已入册编号>`，否则 `declaration-unregistered` 红）。
- **牙不依赖仓外状态**（主控点名）：本件**从不自己去找** `~/w18?a/**`／`~/w19?a/**`；面①的输入**只**来自调用者显式给的清单。

**两极化（`--selftest`，**真子进程**跑本件自己的三个形态；8/8）**
```
SELFTEST S1 OK  干净包源件 ⇒ PASS（rc=0）
SELFTEST S2 OK  带旧路径默认值的包源件 ⇒ FAIL 并点名 file:line（rc=1）
SELFTEST S3 OK  未声明的注释引用 ⇒ FAIL（rc=1）
SELFTEST S4 OK  已声明的注释引用 ⇒ PASS ＋ 逐条上屏（rc=0）
SELFTEST S5 OK  命中数超声明上限 ⇒ FAIL（provenance-tree-grown，rc=1）
SELFTEST S6 OK  --staged 在**非 git 目录**下 ⇒ 响亮 rc=3（不假装绿）
SELFTEST S7 OK  空清单 ⇒ NOINFO（**零检查不许给 PASS**，rc=3）
SELFTEST S8 OK  清单缺席 ⇒ NOINFO（rc=3）
RETIREDPATH_SELFTEST=PASS cases=8 pass=8 fail=0
```
**真树读数（`--tree`，1.1 s）**：`RETIREDPATH=PASS mode=tree files=226 hits=3 code=0 declared=3 self_skip=1`
- **新增发现（不在 `t18` 的清单里）**：仓内**还有 3 处**旧路径默认值 —— `build/MilBridge/tools/t1b-ls-selftest.c:21`、`build/DirectWrite.Linux/wic-shim/probe_decode.c:29`、`build/DirectWrite.Linux/wic-shim/probe_shim.c:34`（逐字皆为 `argc > N ? argv[N] : "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/…"`）。
- **处置（**不自作主张**）**：三件都是**某份在册读数的出处件**（`T1b-report.md`／`W78A-report.md`／`build/DirectWrite.Linux/REPORT.md` §14）⇒ **改源＝改证据**；故声明为 `code-evidence-source` 并挂 **`registered=D-G151`**（"保留集件因路径退役而静默失能" —— 无参运行时**静默找不到 .so**，与该条判词同形），**逐条上屏**。正解＝**单独一波**改源＋重建＋重跑绊线（见 §推翻 第 3 条）。
- **自跳过（**不是豁免**）**：探测器必然自带 needle（件内 `RETIRED_NEEDLE` 赋值 ＋ `--selftest` 夹具）⇒ `RETIREDPATH_SELF_SKIP` **上屏**且**不影响判词**。

---

## §B 组 —— roster 从「固定 22 条」扩到「派生式 roster ＋ 总数断言」

**改件**：`build/MilBridge/tools/wave-freeze-consistency-check.py`（`f038a9b9655bc5ad` → **`c682492a85e146bf`**）｜**新件**：`build/MilBridge/wfreeze-root-sites.tsv`（`--emit-roster` 生成）。

**谓词（**逐字**）**：`dirname` ∧（`${BASH_SOURCE[0]}` ∨ `abspath(__file__)`），域 = `build/`＋`tests/`＋`src/` 下的 `*.sh`／`*.py`（仓根**顶层**非递归也扫 ⇒ `verify-all.sh` 在内），排除 `bin|obj|.artifacts|gen|__pycache__|upstream`。

**判据（**先写死**）**：扫描集与声明表 **集合相等**（`derived-total` 与逐条 `state`）∧ **凡解析到仓根的站点逐个真跑判值必须 == 仓根** ∧ `t17` 那 22 条**原 roster 保留为子集断言且判值仍须为仓根** ∧ 消费点判据照旧 ∧ **`cwd` 两极化** 照旧。

**现读（`t20` 落地后重发 roster 的值）**：
```
WFREEZE_ROOTDEFAULT=PASS exprs=168 files=136 ok=35 bad=0 root_n=35 benign=133
                      consume=5 consume_ok=5 t17=22 t17_lost=0 t17_val_bad=0 cwd_dep=0
```
- **`t18` 报的"12 条不在 roster 的根变量站点"** 已全部进域并被逐个判值：现读 `root_n=35`（`t18` 现取 `root_ok=34`，口径差已如实并列），其中含 `verify-all.sh:196`／`build/close-wave.sh:31`／`build/integration-wave.sh:15`／`build/MilBridge/tools/frame-step.sh:60`／`hidden-only-step.sh:158`／`pc-line-step.sh:33`／`product-entry-step.sh:44` 等。
- **roster 内容被钉住 ⇒ 任何新增/删除/改状态 ⇒ 红**。**这条当场咬到人**：`t20` 落地时我的牙立刻报 `derived-total-mismatch live=168 declared=167`（新增的正是**我自己的 `--selftest` 夹具**里那行 `dirname "${BASH_SOURCE[0]}"`）⇒ 重发 `--emit-roster` 后即 PASS；两次重发**载荷逐字节相同**（`STABLE`）。
- **两极化读数（真跑）**：`S2` 把 `analyze-layout-b34.py` 砍一层 ⇒ **FAIL 并点名该件**；**`S2b` 把 `close-wave.sh`（`t17` roster 之外）多一层 ⇒ FAIL 并点名**（这正是"12 条无牙"那一格的机器证）；`S2c` 声明表缺失 ⇒ **NOINFO**（空边响亮失败）。
- **如实划界**：① **只对"解析到仓根"的站点判值**；`benign=133` 只钉集合与状态（不钉值）⇒ "少一层但仍解析到某个子目录"的 benign→benign 漂移**本档抓不到**；② 过滤掉的 20 个 `err` 站点（如 `run.sh:32`）**不判值**，只钉状态。

---

## §C/F 组 —— 第四档 `WFREEZE_BLOCKVALUES`（九位行 ∧ 机读行 ∧ **现取** 三方对拍；`D-G166`）

**改件**：同 §B 那一件（`t17` 建的三档 → **四档**）｜**新件**：`build/MilBridge/blockvalues-shift.tsv`（**具名位移声明**，`a701618990601294`）。

### C-1 现读（三方对拍，逐键）
```
WFREEZE_BLOCKVALUES_HIT key=provider probs=nine-vs-live,block-selfcontradiction
                       block9=609192a419d125f2 tier=a00895e8158189b9 live=a00895e8158189b9
WFREEZE_BLOCKVALUES_TIER_NA keys=windowsbase,hbtextline,dwf（机读行**按设计**只覆盖 7 键）
WFREEZE_BLOCKVALUES=PASS gen=#78 keys=9 declared_shifts=1 bad=0 noinfo=0 cfg=Release
```
⇒ **九键里恰好只有 `provider` 一条不一致**（另八键三源逐位相同），且它是**两种形态同时成立**：`nine-vs-live`（块内值 ≠ 现取）＋ `block-selfcontradiction`（**同块**九位行 ≠ 同块机读行）—— 这正是 `D-G149` 的**第二代复发**。

### C-2 证据（**本件独立复算，两条口径都给**；口径来自主控补全，读数是我自己算的）
| 口径 | 读数（现取） |
|---|---|
| 甲（`build/`） | 同名件 `DirectWrite.Linux.Provider.dll` **58** 份，**45** 份 = `a00895e8158189b9`；`609192a419d125f2` 命中 **0** |
| 乙（全仓，排除 `.git/`） | **68** 份（`build/` 58 ＋ `samples/`、`tests/` 10）；值分布 `a00895e8158189b9`×55／`df619a05ca0d10c9`×4／`9aa0d744802aaa31`×4／`2d5f72721ab4ac95`×2／`1d095db667206b9e`×2／`1f9511a7ef395bfe`×1；`609192a419d125f2` 命中 **0** |
| 有界全量（`build/`＋`samples/` 全部 `*.dll`／`*.so`） | **1,569** 件 / **2,850.9 MB** / **13.5 s** / 318 个不同 sha16 ⇒ `609192a419d125f2` = **0**，`a00895e8158189b9` = **1** |
| 两哨兵 | `/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag` `cmp` 逐字节同（主控读；本件**未复算这一格** ⇒ 见 `NOINFO` 第 4 条） |

⇒ **结论句（逐字，采纳主控口径）**：「`#78` 冻结块九位行写的 `provider` 值，现取**在仓内任何 `*.dll`／`*.so` 上都不对应**（有界扫描命中 0）；而权威件与同块 `BASELINE tier=` 机读行、两哨兵一致为 `a00895e8158189b9`。」

### C-3 `inputs_fp` 的干净归因（**背靠背只差本件**）
窗口内另一条车道在写树 ⇒ 全量 `inputs_fp` **不可归因**。但下面这一对是**同窗口、只差本件内容**的背靠背读数（`wave-freeze-consistency-check.py` 在覆盖面内）：
```
pre-t19 版（f038a9b9655bc5ad）⇒ inputs_fp = 294bb3d420228dbc4235823ebf91caf3bf7ba188727a7c05070a804b6d9f5386
本件     （c682492a85e146bf）⇒ inputs_fp = 0b86fd5e930c06d24250766aab54b2c8a3df56948a7e9b309bd22c13f6f393f2
```
⇒ **改这一件必然移动 `inputs_fp`**（预期、已披露；`t19` 未提交，冻结口径由波内收尾链重取）。

**分工（**互补、不代偿**，主控要求逐字写清）**：主控的 `fmt` 扩展（`~/wcaptain-0745/fmt-ext/w27-freeze.fmt-ext.py`，`fe479b88a852e482 → 3f1260bbc9213002`，`+4` 键 `PRV/PRV_PREV/WIC/WIC_PREV`，排练 `REHEARSE=PASS`：`A_KEYS=27 ADDED=4 SHARED_EQUAL=True`／`B_TEMPLATES=49 IDENTICAL=49 CHANGED=0`／`C_NEG` 真红）解决的是「**能不能用占位符**」；本档解决的是「**写死了本应现取的值**」——**两件互补、不代偿**；而本档与既有三档（`ROOTDEFAULT`／`DECL`／`NINEAUTH`）**也互不代偿**（② 管预登记↔`GENS` 的配置字段、③ 管两条路径彼此相等、① 管派生式解析到哪，**三者都不看"块里的值 vs 现值"**）。

### C-4 具名声明（**不是把牙关掉**）
`build/MilBridge/blockvalues-shift.tsv` 现读 **1 行**：`provider / 609192a419d125f2 / a00895e8158189b9 / a00895e8158189b9 / D-G166`。
- **三格都必须与现场逐位相同**才认（`live=` **被钉住** ⇒ 现取值**再漂一次仍然红**）；`registered=` 必须是**已入册**编号（牙会去 `defect-registry-declared.tsv` 里核，不认就 `kind=declaration-unregistered` 红）。
- **已声明的键照旧逐条上屏** `WFREEZE_BLOCKVALUES_SHIFT`（现读 1 条）⇒ **可见地放行**，不是静默。
- **模板面（只读、可选）**：`--template <path>` 会咬"记录模板里的裸 16 位 hex 字面量"（`S9` 真红并点名行）；**不给 `--template` ⇒ `skipped(no-template-given)`，不进总体状态、不算绿`**。**`~/w186a/w78/w78freeze/w78-record.txt` 是原件证据，本件只读引用、一个字节未动**（新代模板归 `t23`／`waveman`）。

### C-5 两极化（`--selftest`，13/13）
```
S1 OK 干净镜像 ⇒ 档① PASS … S2 OK 少一层 ⇒ FAIL 并点名 … S2b OK close-wave.sh（roster 之外）多一层 ⇒ FAIL 并点名
S2c OK 无声明表 ⇒ NOINFO … S3 OK 声明 `{pf}/True` vs GENS ⇒ FAIL … S4 OK 权威路径分叉 ⇒ FAIL … S5 OK 两条一致 ⇒ PASS
S6 OK 九位行 == 机读行 == 现取 ⇒ 档④ PASS   S6s OK 九位行写上一代值 ⇒ FAIL 并点名   S6s OK 块内两源矛盾 ⇒ FAIL
S9 OK 模板裸 hex ⇒ 模板面 FAIL 并点名行
S10 OK 两个 cwd（`/` 与 `<仓>/build`）下档① 判词行**逐字相同**（判定不是 cwd 的函数）
S11 OK 相对 root ⇒ 档① NOINFO/FAIL（不许当绿）
WFREEZE_CONSISTENCY_SELFTEST=PASS cases=13 pass=13 fail=0
```
**四档总判现读**：`WFREEZE_CONSISTENCY=FAIL rootdefault=PASS decl=FAIL nineauth=PASS blockvalues=PASS` —— **`decl=FAIL` 是真红且先于本件存在**（见 §推翻 第 1 条）。

---

## §D 组 —— 「登记 ≠ 入册」：四号入册 ＋ 报告编号域牙

**改件**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`80170ab55b983751` → **`77890c8cadf5ddbb`**，**只追加**一段 `t19` 入册批）｜`build/MilBridge/tools/defect-registry-declared.tsv`（`95c80adb49ffc02c` → **`247c27c27161fd48`**，`--emit` 重发）｜**新件**：`build/MilBridge/tools/report-id-domain-check.sh`（`8067982bd91772fc`）。

- **① 原号保留**：`D-G149`／`D-G150`／`D-G151`／`D-G166` 一号未回收（`D-G156…D-G165` 已用）。
- **② 同趟进 declared 且被路由件引用**（现取）：`DEFREG=PASS declared=**201** route_ids=201`、`DEFREG_DECLDRIFT=0`（改前 `declared=198`）；`--emit` 后**逐号**：
  `D-G149 req=AB → **KD,AB**`（新增 KD）｜`D-G150 **req=KD**`（新）｜`D-G151 **req=KD**`（新）｜`D-G166 **req=KD**`（新）。
  ⇒ **`KD` ＝路由件**（缺陷册）⇒ 正是"被某个路由件引用"这一条；`D-G149` 的 KD 锚 `80170ab55b983751 → 77890c8cadf5ddbb`、`AB` 锚未动（`d60b414d5e99cf72`）。
- **②b 🆕 `D-G147` 入册（主控同趟追加；`t9` finding #2 归本组）**：
  - **缺口现取**：`grep -c D-G147` = **`docs/ROUTES.md` 3 处** ／ **declared tsv 1 处** ／ **缺陷册 `KNOWN-DEFECTS.md` = 0** ⇒ **"编号在路由件里出现"≠"册里有条目"**。缓解（如实）：`ROUTES.md:775` 已逐字声明「本批未登记（等落地配号）」⇒ 属**声明过的缺口**。
  - **同趟处置**：① 册内**新增 `D-G147` 条目**（在册出处只引用不重写 ＋ 缺口 ＋ 处置 ＋ 口径句）；② `req` 由 **`AB`** 扩到 **`AB,KD`**（现取 `ID\tD-G147\treq=KD,AB\tpresent=KD,AB`）。
  - **机读证据（同趟现取）**：`grep -c D-G147` **两件各 ≥1**（KD=**3**、declared tsv=**1**，另 ROUTES=3）∧ **`DEFREG=PASS declared=201 route_ids=201`** ∧ **`DECLDRIFT=0`**。
- **③b 🆕 绑定判据（"出现"∧"成条"绑成一条）**：`build/MilBridge/book-entry-required.tsv` 列出的编号必须 ① 在 declared 集 ② 册里有**条目形态**标题 ③ 册里至少出现一次。现读 **`BOOK_ENTRY_BINDING required=5 present=5 missing=0`**（`D-G147`／`D-G149`／`D-G150`／`D-G151`／`D-G166`）。
  - **不把"全集"判红**（否则会把已知缺口做成恒红）：册内其它 `req` 含 `KD` 而无条目形态的编号**逐条上屏** —— 现读 **`BOOK_ENTRY_UNREQUIRED_MISSING n=13 ids=D-E1 D-F1b-ABSENT D-G D-G1 D-G156 D-G165 D-G33 D-G5 D-G6 D-O1 D-R2 D-R4 D-T1`**（**已登记的缺口：可见、不判红**；`D-G` 是家族 scaffold）。
  - **空边响亮**：要求清单缺席 **或** 清单为空 ⇒ `BOOK_ENTRY_BINDING=NOINFO` ⇒ **整体 `REPORTID=NOINFO`**（不许用"清空清单"关掉这条判据）。
  - **⚠️ 本牙当场咬到了我自己的报告（如实留档，且这正是它该有的行为）**：我在报告里**引用了 `--selftest` 夹具里的假号字面量** ⇒ 真树那次 `REPORTID=FAIL` 点名 `P0-teeth-close-report.md:<line> id=<假号>`。⇒ 处置：**引用假号时不写数字字面量**（改成"形如 `D-G` ＋ 三位数字"）。**教训：语料含"报告"的牙，会把作者自己的引用也当输入。**

- **③ 新牙「报告编号 ⊆ declared」**：`build/MilBridge/tools/report-id-domain-check.sh`，语料 = `build/MilBridge/*report*.md`（**域逐字写死**，不扫 `docs/`），形态 = `\bD-G[0-9]+\b`，declared 集取 `defect-registry-declared.tsv`。
  - **两极化（`--selftest` 7/7）**：`S1` 只写已入册号 ⇒ PASS｜`S2` 报告里写**未入册的假号** ⇒ FAIL 并点名 `file:line:id`｜`S3` declared 缺席 ⇒ NOINFO｜`S4` 空语料 ⇒ NOINFO（**零检查不许给 PASS**）｜`S5` 形状外号 ⇒ PASS ＋ **上屏** `REPORTID_OUT_OF_SHAPE`｜**🆕 `S6` 把册内一条删掉（declared 去掉某号）而报告仍写着它 ⇒ FAIL 并点名该号**（**主控点名的反极性腿**）｜**🆕 `S7` `book-entry-required.tsv` 要求成条而册里没有条目 ⇒ FAIL 并点名**。旧版描述（保留）：`S1` 只写已入册号 ⇒ PASS：`S1` 只写已入册号 ⇒ PASS｜**`S2` 在报告里写一个**未入册的假号**（形如 `D-G` ＋ 三位数字，见 `--selftest` 的 S2 判词）⇒ FAIL 并点名 `W2-report.md:2 id=<该假号>`**｜`S3` declared 缺席 ⇒ NOINFO｜`S4` 空语料 ⇒ NOINFO（**零检查不许给 PASS**）｜`S5` 形状外号 ⇒ PASS ＋ **上屏** `REPORTID_OUT_OF_SHAPE`。
  - **真树现读**：`REPORTID=PASS files=175 ids=1766 declared=201`。
  - **如实划界**：本牙形态**只吃数字段**；语料里另有 **43 种**带段后缀／通配的 `D-*` 写法（`D-C`／`D-G10x`／`D-G12-CH`／`D-G57-shim-singleface`／`D-T2-a/b/d`／`D-Z9` …）**不被本牙判**，逐条上屏为 `REPORTID_OUT_OF_SHAPE`（与 `D-G150` 同族的"射程缺口必须显形"）。

---

## §E 组 —— 两处硬化（逐条给读数）

**E①（`cwd` 依赖）**：原先 `.sh` 支路**不 `cd`**，且 `--root` 只经 `realpath` 归一 ⇒ **判定可能取决于调用者 `cwd`**（`D-G130` 同族）。硬化三件（都进文件本体）：① 每次求值都走**显式 `cwd=`** 的 `subprocess`（不再继承进程 `cwd`）；② 仓根**必须**是绝对路径，否则 `root-not-absolute` 直接红；③ **根站点在第二个 `cwd` 下再求一次**，两次不等 ⇒ `WFREEZE_CWD_DEP` 红。**读数**：`cwd_dep=0`（现读 35 个根站点全过）；臂 `S10` **两个 `cwd`（`/` 与 `<仓>/build`）下档① 判词行逐字相同**（`WFREEZE_ROOTDEFAULT=PASS exprs=168 files=136 ok=35 bad=0 …`）——**"判定不是 `cwd` 的函数"这句话现在有读数，不只是件头声明**。
**E②（`checked=` 口径）**：冻结器里有**两个**核函数 ⇒ 同一个 `checked=` 字样两个读数。已在**件头逐字写明**（并只做**只读引用**，不改主控写域的 `~/w21-verify/`）：
- `check_prev_values`（**生产线**：`~/w21-verify/w27-freeze.py:1223`，在 `:1299`／`:1336` 打印）⇒ `checked=` = **`prev_*` 键数**（`#78` 收尾链现读 `keys=7 checked=7 skipped=0`）；
- `check_record_forms`（**退回在归档里**：`~/w21-verify/versions/w27-freeze.py.w77e-0745-installed-f9fb7bcac0353a61:1229`；活件现读 `check_record_forms=0`）⇒ 同一块同表曾给 `checked=2`。
⇒ 引用 `checked=` **必须**同时写函数名（或写"生产线＝`check_prev_values`"）。**`NOINFO`**：`check_record_forms` 的**逐例读数**我**没跑**（它在归档件里，A2 臂的主控读数我只引用）。

---

## §推翻 / 打折扣的话（**含两条请你裁**）

1. **🔴 主控请裁：档② `WFREEZE_DECL` 今天在真树上就是红的（**先于本件**）**。
   现读：`WFREEZE_DECL=FAIL gen=#78 allow_changed_decl=pf,provider,win32shim allow_changed_gens=dwf,pc,pf,provider,win32shim,windowsbase`。
   源头现取：`docs/WAVE78-PREREGISTRATION.md:30` 逐字 `WFREEZE-DECL: gen=#78 allow_changed=pf,win32shim,provider pf_required=False`（`git log -p` 显示该行由 `192f54e` 写入），而 `~/w21-verify/w27-freeze.py:232` 的 `GENS['#78'].allow_changed` = **6 键**（注释逐字写"三格进 `allow_changed` 并逐位归因"）。⇒ **同一件事在两处分叉**，**这正是档②存在的理由**，而它今天**没有任何人处理**。
   **我为什么不自己改**：`docs/WAVE78-PREREGISTRATION.md` 是**已冻结波**的记录件，改它属"记录更正"，本仓惯例是**主控落 dated 更正**（`D-G149` 的先例："不改冻结块，落 dated 更正"）。⇒ **两选一**：**(A)** 在该行旁落一条 dated 更正（原行一字不动）；**(B)** 把 `GENS['#78'].allow_changed` 收回 3 键（**会与 #78 实际位移冲突** ⇒ 我不建议）。**在裁之前，`close-wave.sh [5c/6]` 会在下一次冻结处红。**
2. **A 组"清干净"再打一次折扣**：`t18` 说仓外还有 4 处；**仓内还有 3 处**（§A，逐行现取）—— 加上主控已手修 2 件，**"旧路径一族"今天共 5 处未清**（仓外 2 证据类 ＋ 仓内 3 证据源类），全部**在册可见**（仓外 2 件按主控裁定属证据类未动；仓内 3 件挂 `D-G151`）。
3. **我推翻了 `t18` 的一句"眼不见为净"的隐含假设**：`t18` 把"仓内可执行件"当成"已被牙看着"。实测：`--tree` 一次扫出 **226 件**里 3 处 `code` 命中，而当时的任何牙都不会响 ⇒ **"牙存在"≠"这一类被看着"**（`D-G132` 同族）。
4. **我推翻自己一条**：`--tree` 首版**每行起一个 `grep -qF`** ⇒ 在真仓上 **>60 s 被超时杀掉**；改成 bash `case` 通配后 **1.1 s**。**性能也是判据的一部分**（跑不动的牙 ＝ 没有牙）。
5. **我推翻自己第二条**：`REPORTID` 的"形状外"判定首版用 `case "$id" in "$IDRE")` —— `+` 在 glob 里是字面量 ⇒ **全部 1,766 条都被判成"形状外"**（假读数）；改 `[[ =~ ]]` 后只剩真正的 43 种形状外写法。⇒ "计数类读数必须声明它数的是什么集合"（`D-G146`）在**我自己身上**又犯了一次。

---

## §牙的射程上限（**主控要求具名登记；本波不做修法**）：`decl-checks-newest-gen-only`

**现象（`t19` 现读，机制逐字）**：档② `sec_decl()` 把**全部** `docs/WAVE*-PREREGISTRATION.md` 里的 `WFREEZE-DECL:` 行收齐，取 **`gen` 数字最大**的那一代去比 `GENS[gen]` ⇒ **只核最新声明世代**。⇒ **历史世代的「预登记 ↔ 实际位移」落差从此不可见** —— `#78` 那条落差（预登记 3 键 vs `GENS['#78']` 6 键）**今天完全靠人眼才被看见**（`t19` 跑了才发现；`t20` 的 `t9` 复验又独立顶出一次）。

**⚠️ 这不是"改错了"，是射程声明**。主控已落 **dated 更正**（`docs/WAVE78-PREREGISTRATION.md` §2-追，**原文那行一字未动**；更正行用令牌 **`WFREEZE-DECL-CORRECTION(dated):`** ⇒ **不进那个解析器的收集集**，复跑确认档②仍只认 `#79`）。**权威声明 = `GENS['#78']`，`GENS` 不收回、不追改**；三位位移（`pc`／`windowsbase`／`dwf`）逐键归因 = `D-G92` 同族**路径承载体**（`#76` 九位是从旧树拷来的、`#78` 是真重建 ⇒ 托管件里嵌的 `pdb` 绝对路径变、**字节大小逐位同**）⇒ **只在整波跑完后才可观测**。

**现读（判据域现取，`t19` 复算）**：
```
WFREEZE_DECL=NOINFO reason=gens-has-no-entry gen=#79（声明了本代、冻结器里没有 ⇒ 算不出来）
```
（`GENS['#79']` 由波内冻结器在冻结前写 ⇒ 届时自然转正。）

**两个候选修法（**本波不做**，交下一趟／文档收口）**：
1. **只读全代扫描面**（`--all-gens`）：把**历史世代**的落差**列出来但不进总体状态** ⇒ **可见性 ↑ 而不制造永久红**（不会把"已知历史落差"做成恒红，符合 `D-G132` 的口径句）。
2. **要求每个世代在冻结块内自带与 `GENS` 逐字段一致的位移声明** ⇒ 那样牙**核块就够了**（把"两处维护"收敛成"一处"；与 `D-G166` 的"记录里的值必须是现取值的函数"同向）。

**同族**：`D-G166`（记录里的值可以是写死的字面量）｜`D-G145`（记录件缺机读形态 ⇒ 下一代核不动）｜本条讲**核只覆盖最新世代 ⇒ 历史落差无读者**。

## §口径更正（**主控自报的两处错；`t19` 落册，教训逐字**）

1. 🔴 **「同块 7 条 `BASELINE tier=` 行」是错的 ⇒ 实为 6 条**（`rep=1/2/3` × `tier=default` ＋ `rep=1/2/3` × `tier=env`）。**本件现取自数**（用自己的抽取域：`^BASELINE tier=` 按 `tier=`/`rep=` 分组）⇒ **6/代**（我在 7..200 行区间数出 18 ＝ **3 代 × 6** —— 正好是"没用自己的域去数"的反面教材）。**口径教训（逐字采纳）**：**"凡是『有几条/几个』，必须用判据自己的抽取域现取去数；不许把另一处的同名数字串过来。"** 该更正已同步进 `KNOWN-DEFECTS.md` 的 `D-G149` 段（**只加不改**）。
2. ✅ **`609192a419d125f2` 不许说成"上一代值"**：`#77` 块九位行那一格是 **`1f9511a7ef395bfe`**；`609192a419d125f2` 是**模板写死那一刻的现取值**（`t17` 的 F6「副本刷成权威」之后），`#78` 整波重建 `provider` 之后才成为 `a00895e8158189b9`。⇒ `D-G149` 标题里那句"写成上一代值"**只描述 `#77` 那一代**；`#78` 这一代是**"模板里的陈旧现取值"** —— **同因不同形，不许混说**（已同步进册）。

## §分工：冻结器的 `check_block_values()` ↔ 本件第四档（**互补、不代偿**）

| | 冻结器（主控写域） | 本件（`t19`） |
|---|---|---|
| 件 | `~/w21-verify/w27-freeze.py`：`fe479b88a852e482` → **`b7912a4a75d36c18`**（档案 `versions/w27-freeze.py.w79-land-fe479b88a852e482`；`temp+rename`；五探针各 `hit=1`；装后拿活件重跑排练 `REHEARSE_BLOCKVALUES=PASS arms=13 pass=13`） | `build/MilBridge/tools/wave-freeze-consistency-check.py` 第四档 `WFREEZE_BLOCKVALUES` |
| **拦的时刻** | **冻结那一刻**（在**即将写盘的那份文本**上跑 `check_block_values()`，不等即**拒冻**并同时打印两值） | **`build/close-wave.sh [5c/6]` 冻前**（口径＝**在册件 ↔ 现场**） |
| 覆盖 | 九位行 ∧ `BASELINE tier=` 机读行 ∧ `BRIDGE_SRC_FP`／`inputs_fp` 两行 ∧ 现取值 | 九位行 ∧ 机读行 ∧ **现取 sha16**（含 `TIER_NA` 如实划界）＋ **模板裸 hex 面**（`--template`）＋ **具名位移声明**（`blockvalues-shift.tsv`，`live=` 被钉住） |
| 关系 | **两条都要**：冻结器在"写盘前"守、本件在"冻前"守 ⇒ **任一单独都不够**（本件现读 `declared_shifts=1` 且**逐条上屏**；冻结器那道会拒冻**未声明**的漂移）。**互不代偿**；冻结器的 `_PREV_SRC`／`_TIER_MAP`／`check_prev_values`（「与上一代一致」）**一字未动**（本件只读引用）。 |
| 装后对账 | 现读 `WFREEZE_DECL` 仍取 `GENS['#78']`（`allow_changed` **6 键**）、`check_record_forms` **仍 = 0**（回退态）⇒ **`E②` 的口径说明照旧成立**。 |

## §接线裁决（**选 (甲)；但 (甲) 与 (乙) 此刻都不可执行 —— 阻塞证据逐条**）

**主控追加要求**：两件新牙被 `WIRING_CLOSURE` 的 A 方向点名（`undeclared=2`）⇒ 必须 **(甲) 接线** 或 **(乙) 在册声明**，**不许静默留着**。**本件选择 (甲)**（理由与主控同：**没接线的牙＝没有读者**，与 D 组"编号要有读者"同构）。

**⚠️ 但 (甲) 与 (乙) 现在都执行不了，原因是**顺序依赖 ＋ 缺依赖件**，逐条给机读证据（`2026-09-27T11:5x` 现取）**：

| 检查 | 现读 | 含义 |
|---|---|---|
| `grep -c '^run_step "' verify-all.sh` | **51** | `t20`（`migrator`）**未落地**（预登记断言它落完是 **53**） |
| `grep -n 'FP-MANIFEST-TEETH" .*--expect' verify-all.sh` | **`--expect 217`** | 同上（预登记断言落完是 **219**） |
| `bash ~/w153a/bin/infp.sh list \| wc -l` | **217** | 覆盖面未变 |
| `grep -m1 'VERIFYALL-STEPS-DECL' verify-all.sh` | **`51 gen=#78`** | `DECL` 首行仍 `#78`（主控的 `#79` 预登记已落，但 `DECL` 未动） |
| `ls build/MilBridge/tools/wiring-closure-check.sh` | **不存在** | **(乙) 的在册表连载体都还不存在** —— 「替它写声明」＝**凭空猜路径与列序** ⇒ 合出来的东西它的牙**读不到**，那是**假缓解**（主控原话："替在跑件写声明＝把没接线洗成绿"，我认） |
| `git diff build/close-wave.sh verify-all.sh` | **空**（窗口关闭后复测） | 并发窗口内的改动**已被撤回** ⇒ 此刻动这两件**正好会撞上** `t20` 的下一次落地 |

⇒ **本件的处置**：① **不预置** `verify-all.sh`／`build/close-wave.sh`（派单硬约束"等 `t20` 落完再动"＋并发窗口证据）；② 把 **(甲) 的补丁固化在下面 §接线（逐字）**，并在补丁里写死**以 `t20` 落地后的现取值一次算准**（步数 `53 + 2 = 55`、覆盖面 `219 + 6 = 225`、`[42] --expect 219 → 225`、四处声明同趟改：`DECL` 首行／头注释口径句／`STEP-NAMES`／`docs/WAVE79-PREREGISTRATION.md` 的对应断言行 —— **后者是主控件，改它须主控点头**）；③ **报主控**：请二选一 —— **(i)** `t20` 落地后把"接线"这一步派回本车道（补丁已就绪），或 **(ii)** 由 `t20` 在它的落地里一体带上我这两行（则四处声明由它那一趟统一改）。**在 (i)/(ii) 之一发生之前，`#79` 的门禁会因这两件红色。**

**（二·4）C 组 ↔ D 组的分工（**互补、不代偿**，逐字）**：**C 组**（`WFREEZE_BLOCKVALUES`）守的是"**冻结记录里的值 vs 现取值**"（记录→现场的**横向**对拍，域＝九位行／机读行／`sha256sum`）；**D 组**（`report-id-domain-check.sh` ＋ `book-entry-required.tsv`）守的是"**编号有没有入册、有没有成条、有没有读者**"（登记→册→报告的**纵向**闭合）。**两者域不相交、互不能代偿**：C 组全绿也证明不了"报告里的号都入册"，D 组全绿也证明不了"块里的 `provider` 对得上现取"。

## §接线（**等 `t20` 落完再动**；补丁逐字给出）

派单硬约束：波 `#79` 落仓顺序 = `t20` → **`t19`（本件）** → `t21`；`verify-all.sh`／`build/close-wave.sh` 是 `t20` 写域 ⇒ 本件**只落件、不接线**，两件新牙现读 **`UNWIRED`**（件头已逐字声明）⇒ **按本仓铁律，接线前不许算绿**。

**落地后要做三件（一次算准，不许分段累加）**
1. **覆盖面** `build/close-wave.sh` 的 `fp_inputs()` 白名单 **+6 行**：`build/MilBridge/tools/pkg-src-retiredpath-check.sh`／`build/MilBridge/tools/report-id-domain-check.sh`／`build/MilBridge/wfreeze-root-sites.tsv`／`build/MilBridge/blockvalues-shift.tsv`／`build/MilBridge/retired-path-provenance.tsv`／`build/MilBridge/book-entry-required.tsv`（**读 ⇒ 进名单**：**四张** tsv 都是牙的**输入**）。`wave-freeze-consistency-check.py` **已在名单内**（本件已使它移动 `inputs_fp`，见 §C-3）。
2. **`verify-all.sh` 第 `[42]` 步 `--expect`**：以 **`t20` 落地后的现取件数**为基数 **+6**（现读 `t20` 落地中 = `219` ⇒ 预期 `225`；**必须一次现取算准**，不许 217+2+6 那样分段累加）。
3. **接线两处**（`build/close-wave.sh` 的**冻前段**，与既有 `[5c/6]` 并列；`[5c/6]` 那条**一字不改**）：
   ```bash
   say ""; say "──── [5d/6] 旧路径默认值（A 组：包件源/落地件）"
   run "[5d/6] pkg-src-retiredpath-check.sh" bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --staged --tree
   say ""; say "──── [5e/6] 报告编号域（D 组：报告里的 D-G<digits> ⊆ declared）"
   run "[5e/6] report-id-domain-check.sh" bash build/MilBridge/tools/report-id-domain-check.sh
   ```
   ⚠️ **接地前必须先跑一次 `--tree`**：它现读 `PASS`（3 处已声明）—— **若 `t20`/`t21` 的落地件又带进旧路径，这里会红**，那正是要的效果。
   ⚠️ **`--staged` 的语义**：`git diff --cached` 的清单 ⇒ **落仓器必须先 `git add` 再调本牙**（或在 `close-wave.sh` 里先 `git add -n` 取清单）；否则面②只覆盖"已经在树里"的件。

---

## §`NOINFO` / 我没能证明的部分（逐条）

1. **本件未提交、未推送**（派单未给推送指令；`t19` 的写域是仓内件，**推送面归波内收尾链**）。
2. **`inputs_fp` 的全量归因不可做**：窗口内 `t20` 正在写树 ⇒ 只能给**背靠背只差本件**的那一对（§C-3）；**冻结口径不可用本值**。
3. **`t20` 落地后的覆盖面/roster 终值未取**：现读 `219`／`168` 只是**该刻**；`--expect` 必须落地后一次现取。
4. **两哨兵那一格我没复算**（`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag` 的 `PROVIDER=a00895e8158189b9`）—— 主控给的是他的读数，本件**只引用**。
5. **`D-G151` 的完整现场未取得**（只核到 `docs/ROUTES.md:734` 那一句）⇒ KD 条目里**只引用、不补造**机制与读数。
6. **`check_record_forms` 的逐例读数未跑**（归档件；`E②` 只做件头口径写明 ＋ 引用主控读数）。
7. **`--tree` 面不覆盖**：① 仓内**非源码类**件（`.md`／`.txt`／`.log`／`.json`／二进制）里的旧路径**按设计不判**（那是历史事实）；② **仓外件**在没被喂进 `--paths-file` 时**看不见**（"牙不依赖仓外状态"的代价，已逐字划界）。
8. **`WFREEZE_ROOTDEFAULT` 对 "benign" 站点不判值**（`benign=133` 只钉集合与状态）⇒ "少一层但仍在子目录内"的漂移**本档抓不到**（原 `t17` roster 覆盖的那 22 条仍判值）。
9. **`REPORTID` 只吃 `D-G<digits>`**：43 种带段后缀／通配的写法**不被判**（已上屏为射程缺口）。
10. **本件未跑** `verify-all.sh`／`close-wave.sh`（**不许跑**：`t20` 正在落地，跑门禁会把两条车道的读数混在一起 —— `D-G108` 同族）。

---

## §`t27` 收尾（**接线 ＋ 内容锚 ＋ 全账**；本段取代上面 §接线裁决 里的"待执行"状态，**上面那节一字未改**）

### 1) 四处声明同趟（**全部现取**，一步不加）
```
run_step 计数          = 55                （`grep -c '^run_step "'`，t20 落地后基数 53 ⇒ +2）
DECL 首行              = 55 gen=#79        （`# VERIFYALL-STEPS-DECL: 55 gen=#79`
                                              +`t27` 加两步：`RETIRED-PATH`／`REPORT-ID-DOMAIN`；
                                              ⏪ 既有 `53 gen=#79` 那两行**一字未动**，只在其上方加新行）
头注释口径句           = 55 步              （新行 `**`#79` 收官起 = 55 步**` 插在既有 `53 步` 行之前，旧行未动）
`STEP-NAMES`           = +`RETIRED-PATH` +`REPORT-ID-DOMAIN`
`VERIFYALL_SELF`       = PASS names=55 decl=55 gen=#79 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=52b4d0a7e687328d
```

### 2) 覆盖面与 `[42] --expect`（**按落地后现取一次算准，不许分段累加**）
```
fp_inputs() 白名单 +6 行：pkg-src-retiredpath-check.sh／report-id-domain-check.sh／
                          retired-path-provenance.tsv／book-entry-required.tsv／
                          wfreeze-root-sites.tsv／blockvalues-shift.tsv
覆盖面现取（`infp.sh list | wc -l`）= 225      ⇒ `[42] --expect 219 → 225`（**同趟**）
[42] 步实跑 = FP_MANIFEST_TEETH=PASS reason=ok files_n=225 files_n_uniq=225 declared_expect=225
```

### 3) 🔴 roster 改**内容锚**（本仓教训「内容锚、禁行号」；`t20` 的落地已证明行号锚会假红）
- 锚从 `(rel, 行号, var)` 改成 **`(rel, var, linehash16, idx)`**（`linehash` = 该行 `strip()` 后 sha256 前 16）；行号**只作诊断列、不进判据**。
- **旧形态（行号锚）遇到即响亮 `NOINFO reason=roster-legacy-lineanchor`**（不许静默按新域去读旧表）。
- 重发后现读：`WFREEZE_ROOTDEFAULT=PASS exprs=168 files=136 ok=35 bad=0 root_n=35 benign=133 consume=5 consume_ok=5 t17=22 t17_lost=0 t17_val_bad=0 cwd_dep=0 **anchor=content**` —— 目标读数 `ok=35 bad=0 t17=22 t17_lost=0 cwd_dep=0` **全部达成**（`t20` 造成的 `bad=3` 归零）。
- **两极化（新增两条真跑臂，`--selftest` 由 13 → 15）**：
  - **`S12`（正极，正是本次的病）**：把 `verify-all.sh`／`build/close-wave.sh`／`analyze-layout-b34.py` 三个站点**各整体下移 5／3／7 行**（纯插注释）⇒ **档① 仍 PASS** —— **行号漂移不再判红**。
  - **`S13`（反极）**：把某个站点的**那一行内容改掉**（多一层 `dirname`）⇒ 内容锚 key 变 ⇒ **FAIL 并点名该件**（必须重发 roster）。
  - 既有 `S2`／`S2b`（改根层数 ⇒ FAIL 并点名，含 `t17` roster 之外那件）与 `S2c`（无表 ⇒ NOINFO）照旧真跑。
- `t17` 那 22 条的**子集断言改按 `(rel, var)` 匹配**（不再用行号）＋ 原语义"必须解析到仓根"照旧 ⇒ 现读 `t17=22 t17_lost=0 t17_val_bad=0`。

### 4) `WIRING_CLOSURE` A 方向转绿 ＋ **两条反极性腿**（⚠️ 第 2 条是我据实报的**不符**）
```
真树现读：WIRING_CLOSURE=PASS steps=55 jaws_n=52 undeclared=0 reasonless=0 fails=0 rc=0
```
- **腿①（有效，采纳的形态）**：把 `run_step "RETIRED-PATH" …` **整行删掉 ＋ 把该件名在 `verify-all.sh` 里的每一处提及也删掉** ⇒ `WIRING_CLOSURE=FAIL steps=54 … undeclared=1` **并点名** `file=build/MilBridge/tools/pkg-src-retiredpath-check.sh（带 --selftest 却既没接线、也不在声明册里）`，`rc=1` ✓（两极化成立）。
- **腿②（主控点名的形态：只把那行注释掉）⇒ ❌ 不红**：`WIRING_CLOSURE=PASS steps=54 undeclared=0 fails=0 rc=0` —— **因为该件名仍以"散文提及"出现在同一文件里**（我加的注释块就提到它）。⇒ **`wiring-closure-check.sh` 的 A 方向把"文件名在 `verify-all.sh` 里出现过"当成了"已接线"** ⇒ 这是本仓明令禁的 **`D-G132`／`D-G134` 同族形态（"门被提及打开"）**：**一条注释就能让 A 方向放行**。它自己的 NOTE 写着"排除注释行"，**实测与之不符**（本条的读数即证）。
  - **归属**：**该件是 `t20` 的写域（本件 out-of-scope）⇒ 只报不改**；建议修法：A 方向改判 `^[[:space:]]*run_step[[:space:]]+"…"[[:space:]]+bash[[:space:]]+<件>` 的**代码形态命中**（并把"注释/散文提及"单列诊断行），否则"接线闭合性"可以被散文满足。
  - 两条腿都在**真树上真跑**，跑完已 `cp -p` 还原并**逐位核 sha16 相等**（`52b4d0a7e687328d`）。

### 5) 四档现读（验收口径）
```
WFREEZE_ROOTDEFAULT=PASS  exprs=168 files=136 ok=35 bad=0 t17=22 t17_lost=0 cwd_dep=0 anchor=content
WFREEZE_DECL       =NOINFO reason=gens-has-no-entry gen=#79   ← **不是本件的账**（`GENS['#79']` 由 t23 在冻结前写）
WFREEZE_NINEAUTH   =PASS  pairs=1 ok=1 bad=0
WFREEZE_BLOCKVALUES=PASS  gen=#78 keys=9 declared_shifts=1 bad=0 noinfo=0   ← 唯一不一致键 provider 仍具名声明（D-G166，live= 钉住）
WFREEZE_CONSISTENCY=NOINFO（**无 FAIL**）⇒ 满足「除 decl=NOINFO 外其余三档 PASS」
牙自测：WFREEZE_CONSISTENCY_SELFTEST=PASS cases=15 pass=15 fail=0
```

### 6) 总账（`t19` 五组 ＋ 本件；**`artifact + field + sha16`**）
| 组 | 落点（artifact） | 现读 sha16 | 牙／两极化腿 |
|---|---|---|---|
| A 组（包件源/旧路径默认值） | `build/MilBridge/tools/pkg-src-retiredpath-check.sh` | `a420426eea307eff` | `--selftest` **8/8**；真树 `RETIREDPATH=PASS mode=tree files=228 hits=3 code=0 declared=3 self_skip=1` |
| A 组 声明清单 | `build/MilBridge/retired-path-provenance.tsv` | `10d62946231cc809` | 3 条 `code-evidence-source`（挂 `D-G151`）逐条上屏 |
| B 组（roster 扩面）＋ C/F 组（第四档）＋ E①② | `build/MilBridge/tools/wave-freeze-consistency-check.py` | `09c5588680f018cd` | `--selftest` **15/15**；真树四档 `PASS/PASS/NOINFO/PASS` |
| B 组 roster（**内容锚**） | `build/MilBridge/wfreeze-root-sites.tsv` | `e178e2bfed132a2a` | `anchor=content`；`S12`（下移仍 PASS）／`S13`（改内容必红） |
| C/F 组分位移声明 | `build/MilBridge/blockvalues-shift.tsv` | `a701618990601294` | `declared_shifts=1`（`provider`，`live=` 钉住，`registered=D-G166`） |
| D 组（报告编号域） | `build/MilBridge/tools/report-id-domain-check.sh` | `8067982bd91772fc` | `--selftest` **7/7**；真树 `REPORTID=PASS files=176 ids=1819 declared=201` ＋ `BOOK_ENTRY_BINDING required=5 present=5 missing=0` |
| D 组 绑定清单 | `build/MilBridge/book-entry-required.tsv` | `a2a1eb9bf2a63f00` | `required=5／present=5／missing=0`；`S6`（册内删一条必红）／`S7`（无条目必红） |
| D 组 入册批 | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `77890c8cadf5ddbb` | `D-G147/149/150/151/166` 条目 ＋ `req=KD,…` |
| D 组 声明表 | `build/MilBridge/tools/defect-registry-declared.tsv` | `247c27c27161fd48` | `DEFREG=PASS declared=201`、`DECLDRIFT=0` |
| **本件 接线** | `verify-all.sh` | **`52b4d0a7e687328d`** | `run_step=55`／`DECL 55 gen=#79`／口径句 55／`STEP-NAMES` +2／`VERIFYALL_SELF=PASS` |
| **本件 覆盖面** | `build/close-wave.sh` | **`fcb56d02e66d7b89`** | `fp_inputs()` +6；覆盖面 225 ⇒ `[42] --expect 225`（实跑 `files_n=225`） |
| 本件 外部依赖牙（`t20`，非本件写域） | `build/MilBridge/tools/root-entries-allowlist-check.sh`／`wiring-closure-check.sh` | `0983051ab8212bc2`／`178055f40d3a1cf0` | `--selftest` **10/10**／**11/11**；`WIRING_CLOSURE=PASS`／`ROOT_ALLOW=PASS` |

## §append-only 更正：`wiring-closure-check.sh: 行 471: 1: 未找到命令` 判为 **`NOT_REPRODUCIBLE`**（并发窗口读到半写文件）

**原话留档（`t19` 当时上报给主控，一字未删）**：「另报一处（不是我的件，我没改它）：跑 `build/MilBridge/tools/wiring-closure-check.sh` 时它**自己**吐了一行 `build/MilBridge/tools/wiring-closure-check.sh: 行 471: 1: 未找到命令`（一个未引用/未转义的 `$1` 形态被当命令执行）⇒ 该件的 A/B 判词可能被这一行污染（现读 `fails=2`），请 `t20`/你核是不是它的自伤。」

**主控复现（现取，`t19` 照录；**我复核不了那一行，因为它已不可复现**）**：
```
wc -l build/MilBridge/tools/wiring-closure-check.sh  ⇒ 471（末行就是 exit $?）
bash  …wiring-closure-check.sh            ⇒ 无 stderr，rc=1，判定行 WIRING_CLOSURE=FAIL … fails=2 rc=1
bash  …wiring-closure-check.sh --selftest ⇒ rc=0
bash  …wiring-closure-check.sh 1          ⇒ rc=2，WIRING_CLOSURE=NOINFO reason=bad-arg arg=1（:120-129 的参数分支正常）
（另：`sh …` 跑会 `set: Illegal option -o pipefail` —— 那是**用法**问题（本件是 bash 脚本），不是缺陷）
```
**时间线（同刻现取 mtime）**：`verify-all.sh`／`build/close-wave.sh` **11:58:03** 落、`wiring-closure-check.sh` **11:59:50** 落 —— 而 `t19` 看到那一行时，正是它**还在被写**的窗口里。

⇒ **判词（采纳主控）**：`NOT_REPRODUCIBLE`；**最可能成因 = 并发窗口读到半写文件**（bash 读到一行尚不完整的文本 ⇒ 把 `1` 当命令执行），**不是**落地件里有未转义的 `$1`（现版 `$1` 用法在 `:120-129` 是**正确引用**的）。

**归属**：挂 **`D-G158` 同族（并发/同名多趟窗口）**，**不当新缺陷立号**。

**本仓据此立的硬规则（主控 §三，全波通用，本件照办）**：**落仓一律 `temp + rename`（原子替换），禁就地改写** —— 就地 `>` 写会让任何并发读者（牙、别的车道、门禁）读到半写文本，产出**假异常/假判词**。**本件自本条起，对 `P0-teeth-close-report.md` 的所有写入一律 `temp + rename`**（本段本身就是这么落的）。

## §附录（`t27` 落仓的**不一致窗口**入账 —— 主控要求；与 `migrator` 的写穿窗口同形）

### 1) 窗口（起止 `mtime`，微秒级；**现取**）
```
build/close-wave.sh   mtime = ctime = 2026-09-27 12:03:04.502770534 +0800   inode=4983744  （覆盖面 219 → 225）
verify-all.sh         mtime = 2026-09-27 12:03:19.915014099 +0800          inode=4983585  （--expect 219→225 ＋ DECL 53→55 ＋ 口径句 ＋ STEP-NAMES）
两件 pre-t27 备份（= `t20` 落地态）：close-wave.sh mtime 11:58:03.040855761 ／ verify-all.sh mtime 11:58:03.130815004
⇒ **窗口 = 12:03:04.502770534 → 12:03:19.915014099 = 15.412 s**（与主控现取一致）
```
⚠️ `verify-all.sh` 的 `ctime=12:04:01.356300207` **晚于** `mtime`：那是本件后面两条反极性腿的 `cp -p` 还原留下的（`cp -p` 保 `mtime`、更新 `ctime`）——见 §3 的自我披露。

### 2) 窗口内的「危险读数」清单（并发读者在这 15.412 s 里可能取到**混合态**）
| 量 | 窗口前 | **窗口内（混合态）** | 窗口后 | 后果 |
|---|---|---|---|---|
| `infp.sh list \| wc -l`（覆盖面） | 219 | **225**（12:03:04 起） | 225 | 读者看到"覆盖面貌似已扩" |
| `[42] --expect`（写死在 `verify-all.sh`） | 219 | **219**（直到 12:03:19） | 225 | **两者不符 ⇒ 假 FAIL** |
| `FP_MANIFEST_TEETH` | PASS | **`FAIL reason=files-n-mismatch files_n=225 expect=219 delta=6`**（**本件已复现**，见 §4） | PASS | `t16` 读到的就是这一格 ⇒ 判了假 FAIL |
| `grep -c '^run_step "'` | 53 | **53**（12:03:19 才变 55） | 55 | 与 `DECL`／口径句**自洽**（都是 53）⇒ 这一步自己不看覆盖面，**不报假红**，但**数不是最终值** |
| `VERIFYALL_SELF` | PASS names=53 | **PASS names=53 decl=53**（自洽） | PASS names=55 | 自洽 ⇒ 不报红；读者若把它与 `infp list_n` 对照会得出"53 步 / 225 件"这种**不存在的组合** |
| 两件新牙的 `run_step` 行 | 无 | **无**（12:03:19 才出现） | 有 | 窗口内 `WIRING_CLOSURE=FAIL … undeclared=2`（＝ `t20` 报告里的那条，**不是新问题**） |
| `inputs_fp` | `cefb47c7…`（`t20` 态） | **第三值**（`close-wave.sh` 自身在覆盖面内 ⇒ 它一改就动） | 本件后值 | **窗口内取值不可复算＝`NOINFO`**（与 `t20` 写穿窗口同形） |
⇒ **一句话**：窗口内**"覆盖面已 225、`--expect` 仍 219"** 是唯一会**主动报红**的组合（`delta=6`），其余格要么自洽、要么只呈现"尚未到期"的旧值。

### 3) 🔴 自我披露：我在 `t27` 里**还制造了第二个窗口**（≈41.4 s），且**违反了"禁就地改写"**
为做 `WIRING_CLOSURE` 的反极性腿，我对 `verify-all.sh` 做了**两次就地改写 ＋ 两次 `cp -p` 还原**（`12:03:19.9 → 12:04:01.356`，≈**41.4 s**）：
```
① 12:03:19.9  os.replace 落仓（temp+rename，**合规**）
② ~12:03:5x   就地改写：把 `run_step "RETIRED-PATH" …` 注释掉（腿②）→ 跑牙 → `cp -p` 还原
③ ~12:04:0x   就地改写：整行删掉 ＋ 删掉该件名全部提及（腿①）→ 跑牙 → `cp -p` 还原（12:04:01.356，**终值**）
```
- **危害**：这 41.4 s 里任何并发读者可能读到**半写**或**故意改坏**的 `verify-all.sh`（正是主控立的硬规则要防的 `D-G158` 同族形态）。**我没有在那一瞬观察到的假读数**，但**窗口客观存在**。
- **终值可证**：还原后 `sha256` 与落仓态**逐位相等**（`52b4d0a7e687328d`，两腿各核一次；`git status` 稳定、两腿的牙读数已按要求记录）。
- **教训（写死，供全波）**：**反极性腿不许在真树上就地改被读件** —— 应 ① 在**副本树**上跑（牙支持 `--root`／`--file` 时），或 ② 至少要 `temp+rename`（保持"禁就地改写"），且**两腿之间不留半写窗口**。**本件违反的是 ②**，如实入账。
- **本件已照办的部分**：**所有落仓写入**（`build/close-wave.sh`／`verify-all.sh`／`wfreeze-root-sites.tsv`／本报告）**全部走 `os.replace`（temp+rename）**；`.tmp` 兄弟件现取**均不存在**（`ls` 两者皆"没有那个文件或目录"）。

### 3b) 🔁 规则对齐（**append-only；上面 §3 的原话一字未改**）—— 主控已把"反极性腿"的形态**定死**
**定死的规则（主控，全波通用，与"禁就地改写"并列）**：**反极性腿不许在真树上改「被读件」**（判据：该件是否在 `fp_inputs()` 覆盖面内、或被别的牙/门禁读）。是则**必须**在**副本树**上跑；工具**没有** `--root`／`--file` 这类旋钮 ⇒ **那是工具的缺陷**（给它加一个，或把该腿降级为 `NOINFO reason=no-copy-tree-knob`）；**"跑完就还原"不算合规**。
⇒ 所以 §3 里我写的"**或至少 `temp+rename`**"这半句**已被取代**（原话保留，只在此声明取代关系）。
**现取复核（本件现场，证这条规则可执行）**：`build/MilBridge/tools/wiring-closure-check.sh` **本来就带这两颗旋钮** ——
```
:67  用法：bash wiring-closure-check.sh [--root DIR] [--verify-all PATH] [--inventory] [--selftest] [--debug-tmp]
:121 --root) ROOT="${2:-}"; shift 2 ;;
:122 --root=*) ROOT="${1#*=}"; shift ;;
:404 SBX="$(mktemp -d …)"                                   ← 它自己的 --selftest 就建沙箱副本树
:430 bash "$SELF" --root "$d" --verify-all "$d/verify-all.sh" "$@"   ← 且以副本树跑自己
:446 chk "N9-verify-all 缺席" 3 'WIRING_CLOSURE=NOINFO' bash "$SELF" --root "$SBX/p1" --verify-all "$SBX/absent-verify-all.sh"
```
⇒ **本件的腿①／腿②本可（也本应）在副本树上跑**（`--root <副本> --verify-all <副本>/verify-all.sh`），**"没有旋钮"这一条借口在本件不成立**；这是**执行侧的判据没改到位**，不是工具缺口。
**责任分摊（主控裁定，逐字）**：指令方（主控给的腿①原话"把刚接的那行注释掉"把执行者推向真树）＋ 执行时未改判（本件）**两者叠加**；**本件做对的两件**：① **自己顶出来**（不是等别人发现）；② **终值可证**（还原后 `sha256` 与落仓态逐位相等 `52b4d0a7e687328d`）。
**本波之后的标准顺序（主控采纳本件 §4 的建议，写死）**：落地时**先 `--expect`／`DECL`／`STEP-NAMES`，后覆盖面**。
**下一趟具名未闭项（主控收下，不塞本波）**：`[42]` 的**窗口容忍判据**（差值可归因于本次改动量 ⇒ `NOINFO reason=expect-coverage-window delta=+N`，既不出假红也不出假绿）。

### 4) 顺序声明（**二选一，本件选的这一个 ＋ 复现读数**）
**本件实际顺序 = 先 `build/close-wave.sh`（覆盖面 219→225，12:03:04）→ 后 `verify-all.sh`（`--expect`→225 等，12:03:19）。**
⇒ 窗口留给并发读者的是 **`files_n − expect = 225 − 219 = +6`**（**本件已复现**，等价于把 `[42]` 的常数按窗口值喂进去）：
```
$ bash build/MilBridge/tools/fp-manifest-step.sh --expect 219     # ← 复现窗口内的那一半状态
FP_MANIFEST_TEETH=FAIL reason=files-n-mismatch files_n=225 expect=219 delta=6（件数对不上 ⇒ 有真名被吞或有异物混入；**形状可以完全合法**，只有这一格看得见）
FP_MANIFEST_STEP_RC=1 names_n=225 expect=219 tooth_sha16=be19edddf7f02797
```
- **符号口径现取**：该牙的 `delta = files_n − expect`（**正号**）；反向顺序会留 `delta = −6`。
- **两个方向各读成什么**：`delta=+6` 那一格的消息文本是"**有真名被吞或有异物混入**"（读者最可能读成"清单里混进了 6 件**异物**"＝污染方向）；反向（先 `--expect` 后覆盖面）会留 `delta=−6`，读成"**声明常数领先于现取件数**"＝**尚未兑现的声明**（本仓对"声明先写、事实后到"有既定语汇）。
- **推荐口径（本件事后判断）**：**先 `--expect`／`DECL`／`STEP-NAMES`，后覆盖面** ⇒ 窗口里是"**声明 > 事实**"＝中间态语汇；本件选的顺序（覆盖面先行）留的是"**事实 > 声明**"＝**未声明的件**，**更易被读成污染**。⇒ **本件的顺序不是最优，如实记账**。
- **但更要紧的是：这只是"选一个较不难看的方向"，结构上没解决问题** —— 覆盖面在 `build/close-wave.sh`、`--expect` 在 `verify-all.sh`，**两件文件物理上做不到同一次原子替换**；而 `--expect` 又**必须**是独立写死的常数（本仓刻意保留的"另一把尺"，不许改成从 `close-wave.sh` 现读——那会让它与覆盖面**同源**、失去独立性）。
  ⇒ **建议（本波不做，交下一趟／文档收口）**：给 `[42]` 加一条**窗口容忍判据**：`files_n` 与 `declared_expect` 不等时，若**同趟**能证明"`--expect` 的声明来源与本趟现取同源且差值为本次改动量"，则印 `FP_MANIFEST_TEETH=NOINFO reason=expect-coverage-window delta=+N`（**既不出假红、也不出假绿**，且把方向留成读数）；或更彻底：把"覆盖率常数"与"覆盖面名单"放进**同一件**的**同一个原子替换**里（代价：失去"两把尺"的独立性，需主控裁定——**本件不建议**）。

### 5) 零写/原子证（逐件）
| 件 | 写入方式 | 证据 | 边界（不许读过头） |
|---|---|---|---|
| `build/close-wave.sh` | `os.replace(tmp, path)`（temp+rename） | `inode=4983744`；`mtime == ctime == 12:03:04.502770534`（rename 同时更新两者 ⇒ 与 temp+rename 相容）；`.tmp` **不存在**；pre-t27 备份 `inode=5409167`（另一 inode） | 单次事后 `stat` **不能回溯证明**当时是原子替换；能证的是**机制（落仓器代码用 `os.replace`）＋ 无 `.tmp` 残留 ＋ 与备份不同 inode** |
| `verify-all.sh` | 同上（落仓时）；⚠️ 之后两次反极性腿**就地改写**（§3 已披露） | `inode=4983585`；`mtime=12:03:19.915014099` ≠ `ctime=12:04:01.356300207`（后者＝最后一次 `cp -p` 还原） | 见 §3：那 41.4 s 的窗口**确实存在**，本表不掩盖它 |
| `build/MilBridge/wfreeze-root-sites.tsv` | 同上 | 现读 `e178e2bfed132a2a`；`.tmp` 不存在 | 同上 |
| 本报告 | 同上（每次追加都走 `os.replace`） | 现读 `a0a6e52b8c0549b3`（自报口径 `head -n -1`） | 同上 |

## §`t31` 修 `t19`/`t27` 落地件的两条下游红（`t28` 点名、主控已复现；**不是 `migrator` 的件**）

**读取时刻**：全部读数取自 `2026-09-27 12:1x`（落仓 `12:13:44.46…`；`inputs_fp` AFTER 打戳 `12:14:10`）。

### 1) `SELFDESC_WIRING`：两条**件头自述与现场接线相反** ⇒ 按现场改正
```
改前 2026-09-27 ~12:12   SELFDESC_WIRING=FAIL examined=65 wired=44 unwired=21 undeclared=50 fails=2
                          SELFDESC_FAIL file=…/pkg-src-retiredpath-check.sh  rule=forward-selfdesc-notwired-but-wired
                          SELFDESC_FAIL file=…/report-id-domain-check.sh     rule=forward-selfdesc-notwired-but-wired
改后 2026-09-27 ~12:14   SELFDESC_WIRING=PASS examined=65 wired=44 unwired=21 undeclared=50 fails=0  run_step=55
                          （`selfdesc_notwired=5 → 3`／`selfdesc_wired=10 → 12`）
```
- **改法**：两件件头里那段「本牙自己的接线状态」按**现场**重写为 **`已接线`** ＋ 写明**步名**（`run_step "RETIRED-PATH" … --tree`／`run_step "REPORT-ID-DOMAIN" …`）但**不写步号**（本仓既有约定：写死步号＝下一条会漂移的陈旧自述）；**禁用字样已清空**（`grep '未接线\|不进 verify-all'` 两件**均 0 命中**）。
- **反方向也成立（真跑，**副本树**上做，见 §3 腿 C）**：自称 `已接线` ∧ `^run_step` 零命中 ⇒ `rule=reverse-selfdesc-wired-but-not-wired` 红 —— 不是"把字面翻过来"了事。

### 2) `SHELL_QUOTE_TRAP`：八条 `DQ-BACKTICK` → **0**
```
改前 ~12:12   SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=8 files=195 sh=106 py=89 diag=76 allow=0
改后 ~12:14   SHELL_QUOTE_TRAP=PASS reason=ok          traps=0 files=195 sh=106 py=89 diag=76 allow=0
```
- **① `pkg-src-retiredpath-check.sh:275` ＝ 真 bug（已修）**：双引号里的反引号被 bash 当**命令替换**执行 ⇒ 真跑该件吐 **stderr 263 B**（`行 275: --paths-file／--staged／--tree: 未找到命令` ×3）并把提示里的 flag 名换成空。
  **修法＝转义**（`` \` ``）：现读 `rc=4 stdout=92 **stderr=0**`，提示逐字为
  ``RETIREDPATH=FAIL reason=usage:no-mode（`--paths-file`／`--staged`／`--tree` 三选一）``（三个 flag 名**现在能看见**）。
- **② `wiring-closure-check.sh:296` ＝ 有意的命令替换（已改写）**：``distinct=`printf … | grep -c .`` ⇒ **`distinct=$(printf … | grep -c .)`**。
  **为什么选 `$(…)` 而不是加豁免标记**：① **功能逐字等价**；② 牙的 `allow=` **保持 0** —— 本仓口径「标记＝签字」，加一条豁免就得**永久维护一个签字项**，而这里**没有需要签字的东西**（形态问题，改写即可）；③ 改动面最小（**只动那一行**，见 §4）。

### 3) 两极化：**三条腿全部在副本树上做**（本波第二条硬规则；牙自带 `--root`／`--verify-all`）
```
副本树 = mktemp -d /tmp/t31-copytree.XXXXXX（含 verify-all.sh 副本 ＋ 两件牙副本；用完即 rm -rf）
腿A（正极，现件头 ＋ 真 verify-all 副本）  ⇒ SELFDESC_WIRING=PASS examined=2 wired=2 undeclared=0 fails=0
腿B（注入"未接线"字样到副本件头）          ⇒ SELFDESC_FAIL file=…/report-id-domain-check.sh rule=forward-selfdesc-notwired-but-wired
                                              SELFDESC_WIRING=FAIL fails=1
腿C（从副本 verify-all.sh 删掉 REPORT-ID-DOMAIN 那行，件头仍写"已接线"）
                                            ⇒ SELFDESC_FAIL file=…/report-id-domain-check.sh rule=reverse-selfdesc-wired-but-not-wired
                                              SELFDESC_WIRING=FAIL examined=2 wired=1 unwired=1 fails=1
```
**真树未被这些腿碰过**（腿后现取：`report-id-domain-check.sh` = `e1ed9a71200a20a9`、`verify-all.sh` = `52b4d0a7e687328d` 均为落仓态）。

### 4) 跨车道授权声明（逐字，`wiring-closure-check.sh` 属 `t20`/`t28` 写域）
**本件只改了那一行**（`:296` 的反引号 → `$(…)`），**件头与其余任何一处一字未动**。证据（与 `~/w196a/backup/wiring-closure-check.sh.pre-t31` 逐行 `diff`）：
```
296c296
<   echo "WIRING_CLOSURE_NOTE … （distinct=`printf '%s\n' "${!seen_tok[@]}" | grep -c . || true`）"
---
>   echo "WIRING_CLOSURE_NOTE … （distinct=$(printf '%s\n' "${!seen_tok[@]}" | grep -c . || true)）"
```
⇒ **`diff` 输出恰一行**（`296c296`），无第二处改动。改后真树回归现取：`WIRING_CLOSURE=PASS steps=55 jaws_n=52 undeclared=0 reasonless=0 fails=0 rc=0`。

### 5) `artifact + field + sha16`（改前 → 改后）＋ 原子替换证
| 件 | 改前 sha16 | **改后 sha16** | inode | `mtime == ctime` |
|---|---|---|---|---|
| `build/MilBridge/tools/pkg-src-retiredpath-check.sh` | `a420426eea307eff` | **`d54a5a14c1934bac`** | 4984054 | ✓ `12:13:44.460192192` |
| `build/MilBridge/tools/report-id-domain-check.sh` | `8067982bd91772fc` | **`e1ed9a71200a20a9`** | 4983682 | ✓ `12:13:44.462192230` |
| `build/MilBridge/tools/wiring-closure-check.sh` | `178055f40d3a1cf0` | **`1f6ffd939a0b95fa`** | 4984055 | ✓ `12:13:44.463192249` |
- 三件**全部 `os.replace`（temp+rename）**；`mtime == ctime` 与 temp+rename 相容；`.tmp` 兄弟件现取**均不存在**。
- **边界（如实）**：**inode 改前值未取**（事后不可得）⇒ 满足合同要求的是**「前后两读」＝ sha16 三对**，不是 inode 对。

### 6) `inputs_fp` 移前/移后（三件都在覆盖面内 ⇒ **本件改动**使它再移一次）
```
移前 2026-09-27（本次落仓之前那一轮；**未打戳** ⇒ 只声明区间 ≤ 12:13:44.46，不冒充精确时刻）
     inputs_fp = 9f6b71e575a20e44ad1ac831c064cb90c1cc2701df601be682d1d1803f4d48d4
移后 2026-09-27T12:14:10+08:00
     inputs_fp = 301cc0bd667893c88ecd2fdfc95badb16ff2756db5e274c37ae4f6474dbd169e
```
⇒ **两值不同＝预期的位移**（改了三件覆盖面成员）；**冻结口径以波内收尾链现取为准**，本表只作移前/移后留档。

### 7) 牙一条都没改松（**改前/改后**逐条）
| 牙 | `--selftest` 改前 | `--selftest` 改后 |
|---|---|---|
| `pkg-src-retiredpath-check.sh` | `RETIREDPATH_SELFTEST=PASS cases=8 pass=8 fail=0` | **同**（8/8） |
| `report-id-domain-check.sh` | `REPORTID_SELFTEST=PASS cases=7 pass=7 fail=0` | **同**（7/7） |
| `wiring-closure-check.sh` | `WIRING_CLOSURE_SELFTEST=PASS cases=11 pass=11 fail=0` | **同**（11/11） |
| `selfdescription-wiring-check.sh` | `SELFDESC_SELFTEST=PASS total=8 pass=8 fail=0` | **同**（8/8，含 `SL1` 正向必红／`SL2` 反向必红两条臂） |
| `shell-quote-trap-check.sh` | `ST_ATTEST=PASS … sha16=39a2e2cdf1948675` | **同**（自测期间本件未变 ⇒ 读数可归因） |
**不动 `verify-all.sh`／`close-wave.sh`**：现取 `run_step=55`、`VERIFYALL_SELF=PASS names=55 decl=55 gen=#79 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=52b4d0a7e687328d` —— **与改前逐字相同**。
**两件牙的真树行为仍绿**：`RETIREDPATH=PASS mode=tree files=228 hits=3 code=0 declared=3 self_skip=1`；`REPORTID=PASS files=176 ids=1826 declared=202` ＋ `BOOK_ENTRY_BINDING required=5 present=5 missing=0`。

## §复算命令（逐条可重放；`R=/home/links-dev/netTest/GitProj/WPFOnLinux`）

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
# B/C/E：四档 ＋ 自测
python3 build/MilBridge/tools/wave-freeze-consistency-check.py --root "$PWD"
python3 build/MilBridge/tools/wave-freeze-consistency-check.py --selftest          # 13/13
python3 build/MilBridge/tools/wave-freeze-consistency-check.py --emit-roster build/MilBridge/wfreeze-root-sites.tsv
python3 build/MilBridge/tools/wave-freeze-consistency-check.py --template ~/w186a/w78/w78freeze/w78-record.txt   # 模板面（只读引用）
# A：包件源/落地件
bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --selftest                  # 8/8
bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree                      # PASS（3 处已声明）
# D：报告编号域 ＋ 注册器
bash build/MilBridge/tools/report-id-domain-check.sh --selftest                     # 5/5
bash build/MilBridge/tools/report-id-domain-check.sh                                # PASS
bash build/MilBridge/tools/defect-registry-check.sh | tail -3                       # DEFREG=PASS declared=201
bash build/MilBridge/tools/defect-registry-check.sh --emit > /tmp/d.tsv             # 重发（temp+rename）
# C-2 证据（两条口径 ＋ 有界全量）
find build -name 'DirectWrite.Linux.Provider.dll' | while read f; do sha256sum "$f"|cut -c1-16; done | sort | uniq -c | sort -rn
find . -path ./.git -prune -o -name 'DirectWrite.Linux.Provider.dll' -print | wc -l
find build samples \( -name '*.dll' -o -name '*.so' \) -print0 | xargs -0 sha256sum | cut -c1-16 | sort -u | grep -c '^609192a419d125f2$'
```
SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P0-teeth-close-report.md | sha256sum | cut -c1-16`）= `c7ec141bdaf0e6e4`；整份 sha16 因自指不写在文内（合同 `Verify` 那条现取）
