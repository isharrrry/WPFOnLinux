# W99A 报告 —— **登记 `D-G91`／`D-G92` ＋ 地图 `TASK-9905`/`9906` 收口 ＋ 第二笔文档推送**

> 车道 **W99A** ｜ 2026-09-22 **17:4x → 18:0x +0800** ｜ kernel 6.8.0-138-generic
> 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**本机 `R` 不是 git 仓库**）
> fork 克隆 `C=/home/links-dev/netTest/GitProj/WPFOnLinux` ｜ 开工 head **`608d0a170f07fa577d150d4a81a12776de57fd59`**（`=` `origin/feat-Linux`，与任务书一致）
> **零 `dotnet`／零构建／零应用／零重活槽**（本车道只做纯文本编辑 ＋ 一次 `git push`）。原始材料只读：`build/MilBridge/W95A-report.md`（`dc11db1bbb7b8c33`）§6.3、`build/MilBridge/W94A-report.md`（`9357566278d1cf7b`）§3.1–§3.3/§7.1、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#50` 冻结块。
> 判据**先写**：开工先落三条 —— ①新号必须**连续取**（现场核末号）；②`DEFREG=PASS`／`DECLDRIFT=0`／`rc=0` **跑两遍**；③`inputs_fp` 必须**逐位不变**（否则说明我碰了覆盖面）。
> **未碰**（逐条点名）：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`1f4189c1257737a9`，全程**逐位未变**）｜`docs/CURRENT-STATE.md:9` 机器行｜`handoff.md`｜`verify-all.sh`｜`build/close-wave.sh`｜`build/MilBridge/tools/r-gate-step.sh`｜`build/MilBridge/known-red.json`｜`known-red-PC-copies.md`／`known-red-PFWB-copies.md`｜任何产品件（`src/**`／`build/shims/**`／`build/*.Linux/**`）｜`~/w98a/**`｜`~/w97a/**`｜`build/MilBridge/tools/nul-bytes-check.sh`。

---

## §0 结论摘要（先看这五条）

1. **两个新号都取了**：**`D-G91`**（装置缺陷 · 假绿族：刷新器默认根漏 `$REPO/tools`）＋ **`D-G92`**（仪器/身份缺陷：`pf` 那一格**不是构建身份**）。现场末号 = `D-G90` ⇒ **连续取 `D-G91`／`D-G92`**，两号都被核实**未被占用**。
2. **`D-G92` 走新号的理由已写成机械证**：册里 `构建身份`／`TimeDateStamp`／`确定性` 的唯一命中 = **`D-G46`**（`#37` F4 探针，量的口径是"**隔离重编**"，其**推论①** 还写着"PF 的构建**是**确定性的"）⇒ 那是**另一个实验**、且**结论方向相反**。我**两条都保留**：**新增 `D-G92`** ＋ 在 `D-G46` 里加一条 **dated 追记**（**原文一字未动**）交叉引用并如实写明"整波口径下收窄"。
3. **门禁全绿**：`DEFREG=PASS declared=128 route_ids=128`、`DEFREG_DECLDRIFT=0`、`rc=0`（**连跑两遍逐字相同**）。`AB` 侧 `sha16=1f4189c1257737a9` **一字未动**。
4. **`fp_inputs` 零影响（机械证）**：真调用 `fp_inputs()`（覆盖面 **147 件**）开工 = 收工 = **`ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48`**（**== `#50` 冻结值**）；本件编辑的 3 件在覆盖面里**命中全 0**。
5. **推送成功**：`608d0a1..a3464a6 feat-Linux -> feat-Linux`（**一笔快进**，3 件）；`BYTECHECK ok=10 mismatch=0 nobody=0`；`ls-remote --symref origin HEAD` 仍 `ref: refs/heads/feat-Linux`。

---

## §1 两个新号的编号与判词（**逐字**，即写进 `KNOWN-DEFECTS.md` 的原文）

### ① `D-G91`（**装置缺陷 · 假绿族**）—— 落点 `KNOWN-DEFECTS.md:2421`

> ### `D-G91`（**装置缺陷 · 假绿族**）：`sync-applocal-authority.sh` 的默认 `SCAN_ROOTS` **漏了 `$REPO/tools`**，而它自己的校验器**含**它 ⇒ 用默认参数**永远刷不到**那一份 `STALE`，还会打出 **`STALE=0` 的假绿**

要点（逐字取 W95A 报告 §6.3，**未加戏**）：

| 项 | 逐字 |
|---|---|
| 刷新器默认根 | `build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh` **`:59`**：`SCAN_ROOTS="${SCAN_ROOTS:-$REPO/build:$REPO/tests:$REPO/samples:$REPO/src}"` ⇒ **不含 `$REPO/tools`**（该件 `b56a85afd70c2321`） |
| 校验器默认根 | `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` **`:169`**：`…:$REPO/samples:$REPO/src:$REPO/tools"` ⇒ **含 `tools`**（该件 `97d547551846fd13`） |
| 那件自己怎么承诺 | `sync-applocal-authority.sh:28` 注释逐字"`SCAN_ROOTS`（冒号分隔，**默认与校验器一致**）" ⇒ **注释与代码不符** |
| 漏掉的是哪一份 | 全仓**唯一** `STALE` = `tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll`（`16baacfccfcf1df0`；`build/MilBridge/W22D-report.md` 早已点名它"**连枚举都没枚举到**"） |
| **成对读数** | **`09b`（默认参数 ＋ `--apply`）= `refreshed=0` ＋ `STALE=0`（＝假绿）** vs **`09a`（同刻、校验器全文口径）= `STALE=1`**；**`09c`（按该件自己文档的承诺显式传 `SCAN_ROOTS=…:tools`）= 刷到 ⇒ `STALE=1 → 0`** |
| 处置 | **本波只登记、未修**（W95A 不在其写域；主控当时指示"小改别扩大"⇒ **当时未新增编号**，本件补号）。落地建议三条（默认同源／不设默认／把"本次实际用了哪些根"**打在输出里**）已逐字写进条目。⚠️ 它的 `--apply` **不写回那件仪器本身**。 |
| 边界 / `NOINFO` | 未做**修法**两极化（未改那件仪器）；`tools/` 之外是否还有同类根差**未逐条枚举**（已知差**只有** `tools` 这一处，`diff` 两个默认串得出）；"全仓还有几处同类两套根"**未盘**。 |

### ② `D-G92`（**仪器/身份缺陷**）—— 落点 `KNOWN-DEFECTS.md:2444`

> ### `D-G92`（**仪器/身份缺陷**）：**`pf` 那一格不是构建身份** —— 四趟**逐字相同**的整波重建给出**四个不同 sha**

要点（逐字取 W94A 报告 §3.1–§3.3 ／ `#50` 冻结块）：

- **四趟成对读数**（同源、同命令、命令**四趟逐字相同**，耗时 221/196/195/193 s，四趟都"失败步骤 0"）：
  `881c56e26808269f`（第 1 趟）／`decd920092287b03`（1b）／`581c864a7f2ad36c`（1c）／**`f34bc297d19778fd`**（1d，最终整波态）。
- **源指纹看不见它**：`ARTIFACT_SRC_FP proj=PresentationFramework fp=5b38ea7420b26377 n=1362` **四趟逐位相同**；四趟 `inputs_fp` **波前==波后**都 = `f7e054ad91c07aed74c533b7a7dfa7adf6ef2d4a5aed51859fe1bbe772c6af5b` ⇒ **树在每趟内静止**（排除编辑竞态）。
- **不是"构建本身随机"**：`Deterministic=true`／`PathMap=""`／`DebugType=portable`；**隔离 `-t:Rebuild` 连跑两次同值**（`decd920092287b03` ×2）；csproj 每波末态可复现；`R` 非 git 仓库。
- **72 字节差异簇**：同尺寸 **6,123,008 B**、`cmp -l | wc -l` = **72**（PE `TimeDateStamp` 4 B ＋ MVID 16 B ＋ 调试目录 4＋16＋32 B）；两个 `TimeDateStamp` 都 ≥ `0x80000000` ⇒ **不是随机时间戳**，是**编译内容本身不同**。
- **口径结论**：`#49` 起"冻结取整波值"这条口径**对 `pf` 没有牙** ⇒ `pf` 只作"**冻结那一刻硬盘上是这个**"的现场值，**不许当漂移／回归判据**（**已按主控裁定**逐字写进 `#50` 冻结块）。
- **交叉引用**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`1f4189c1257737a9`）的 `#50` 冻结块 = **权威落点**；**本件一字未改冻结块**（改了要重冻）。
- **复算配方**：① 两趟 `dotnet build … -p:UseSharedCompilation=false -v:diag` **抓 `csc` 命令行**逐字 `diff`；② 给 `build/artifact-src-fp.py` **扩覆盖面到 `-getItem:Compile`**。⚠️ 两件都是重活；`artifact-src-fp.py --selftest` **会写真树** ⇒ 零-`dotnet`／并发车道禁跑。
- `NOINFO`：**真凶未抓到**（已排除四条假设，漂移落在**指纹覆盖面之外**的某个编译输入上）；同件 `dwf` 无源位移也 `NOINFO`（其值四趟稳定 ⇒ 可用）。

### ③ 为什么 `D-G92` 走了"新号"而不是"只并进 `D-G46`"（**这是本件最该被复核的一处判断**）

任务书给的逃生口是"**若该件已有编号 ⇒ 不新增，只在既有条里加 bullet**"。我**先按那个流程搜了**（`pf`／`构建身份`／`TimeDateStamp`／`确定性`）：

```
$ grep -n -E '构建身份|TimeDateStamp|确定性|ARTIFACT_SRC_FP' samples/WpfFeatureProbe/KNOWN-DEFECTS.md
1506: ### 🆕 `D-G46`：**九位封条分不清「可复现构建」与「某次构建的身份位」**（`#37` F4 探针实测，**未修**）
1517: | ③ 与 `#36` 冻结值比 | 冻结 `pf` = `dbb0a450e09e76a3` | **≠**；逐字节差 = **72 B / 5 段**（PE `TimeDateStamp`、MVID、Debug Directory 的 PDB GUID/校验和）… |
1519: - **推论**：① PF 的构建**是确定性的**（三次独立干净重编同一个字节序列）⇒ 历次"`pf` 每波都变"**不是**构建随机性；
```

**唯一命中 = `D-G46`**，它记的是"**九位封条分不清「可复现构建」与「某次构建的身份位」**"这个**缺口**，量法是**隔离重编**（读数表 ①②：同源重编 ×2／干净重编**逐字节相同**）。而 `D-G92` 量的是**整波重建**，结果**相反**（四个 sha）。两条的**实验不同、结论方向相反** ⇒ 若只往 `D-G46` 里加 bullet，会把一条**与它自己推论①相冲突**的读数塞进同一条目而不点明冲突。**处置（两条都做、加法）**：

- **新增 `D-G92`**（把新事实具名）；
- **在 `D-G46` 里加一条 dated 追记**（`KNOWN-DEFECTS.md:1529`，**原文一字未动**），逐字写明：*"本条上面**推论①**…已被 **`D-G92`**…**在「整波重建」这个口径下收窄** —— PF 单独/干净重编确定 ≠ 整波重建确定。两条**都保留**…**不许**拿后一条去覆盖前一条的读数。"*

⇒ 若主控裁定"应当只并进 `D-G46`、撤回 `D-G92`"，那是**一次单点回退**（删 `D-G92` 节 ＋ `--emit` 重生成 ＋ 改题名一行），**尚未做**。

---

## §2 改了哪几件（before → after，**sha256sum 现场算**）

| 件 | before sha16 | after sha16 | 行数 | 动作 |
|---|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `368b293d4ef7f1cb` | **`5dc11e2e87073a39`** | 2414 → **2458** | 新增 `D-G91`（`:2421`）＋ `D-G92`（`:2444`）＋ `D-G46` dated 追记（`:1529`）＋ 分节标题扩写（`:2180`） |
| `docs/ROUTES.md` | `9ee84087206fc1a3` | **`32df06d0f36cd7c9`** | 355 → **367** | `TASK-9905` → ✅（`:325`，含子条 `:326`/`:328` 共 3 行）｜`TASK-9906` → ✅（`:329`，含子条 `:330`）｜新增 **§15**（`:361`–`:367`） |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `53fb33701da1c395` | **`0f5fb2d6b8ab0234`** | 135 | `--emit` **机械重生成**（`ID` 行 **126 → 128**；`D-G91`/`D-G92` = `req=KD present=KD`） |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `1f4189c1257737a9` | `1f4189c1257737a9` | 2172 | **未动（逐位相同）** — 冻结基线 |
| `docs/CURRENT-STATE.md` | `1ff381a9be8c3c7a` | `1ff381a9be8c3c7a` | — | **未动**（`:9` 机器行 `gen=#50 sha16=1f4189c1257737a9` 原样） |
| `handoff.md` | `e4dc264200b421d0` | `e4dc264200b421d0` | — | **未动** |

**"只做加法"的机械证**：`--emit` 输出与改前**逐行 `diff`** ⇒ 只有 **＋2 行**（两行 `ID`）、**0 删、0 改**；`KNOWN-DEFECTS.md` 的既有 `D-G71`…`D-G90` 十七条**判词一字未动**（只在本文件末尾追加两节 ＋ 在 `D-G46` 内追加一条 dated 追记）；**没有任何红被改成绿**。
⚠️ **`req` 的现场发现（顺带核实，如实记）**：`D-G88`/`D-G89`/`D-G90` 在**冻结块里**已被 W95A 逐字提到（`ACCEPTANCE-BASELINE.md:10/13/15/32/33/137/190`）⇒ `--emit` 现在给它们的是 **`req=KD,AB`**（不是 W96A 当时写的"只 KD"）。**这是冻结块的既有内容决定的，不是我改的**；我**未动** `AB` 一个字节，所以本次两行新号的 `req=KD` **不含 AB**。

---

## §3 `DEFREG` 两条机读行（**现场连跑两遍，逐字相同**，`rc=0 / 0`）

```
DEFREG_DECL=n=128 route_ids=128 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=5dc11e2e87073a39 CS=1ff381a9be8c3c7a HO=e4dc264200b421d0 AB=1f4189c1257737a9
DEFREG_EXTRA=KRJ=8a0c0f221e35f42b KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=128 route_ids=128（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
```
* 命令：`bash build/MilBridge/tools/defect-registry-check.sh`（两趟），`rc1=0`／`rc2=0`。
* 改前基线：`declared=126 route_ids=126`（`--emit` 后 `DECLDRIFT` 回 `0`）。
* `DEFREG_ROUTES` 里的 `CS/HO/AB` 三位与**本件开工时逐位相同**（`1ff381a9be8c3c7a`／`e4dc264200b421d0`／`1f4189c1257737a9`）⇒ **三个 route 文件我一个都没碰**（另两位 `KRJ/KRF/KRP` 同）。
* **判据未削弱**：我没有把任何 `req` 降级、也没有把 `undeclared-id-in-route` 放宽；两条新号之所以能过，是因为 `--emit` **按现场**给出 `req=KD` 且它们**真的在 KD 里**。

---

## §4 地图（`docs/ROUTES.md`）改动逐字

### 4.1 `TASK-9905` → `[Next] ✅`（`:325`，含两条子条 `:326`/`:328`）

> - `TASK-9905` [Next] ✅ **已办（`#50` 收尾链闭合；步骤 1–4 车道 W94A，步骤 5–9 车道 W95A，报告 `build/MilBridge/{W94A,W95A}-report.md` `9357566278d1cf7b`／`dc11db1bbb7b8c33`）** —— 速览：门禁 **×2 各 `rc=0`、机读 `6/6 result=PASS`** ｜**冻前 `verify-all` 恰 1 处声明类红**（`COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline` ＋ `SELFREPORT=PASS`；形态逐字命中冻结器 `_is_declaration_class()`）｜**冻结 `#50` = `1f4189c1257737a9`（644,091 B）**｜**冻后 `verify-all` ×2 = `26 ✅ / 0 ❌`、`rc=0`（全绿）**｜**推送** `7feca487…→608d0a170f07fa57`（**69 件逐字节 `ok=69 mismatch=0 nobody=0`**）｜`inputs_fp` `9f2199b2…→f3fb5db8…→`**`ee543f44b1090c74…`**（两步都可逐条归因）｜五臂 `tline 22/2`（两条既有 ❌ 与 `#49` 逐字相同）等逐臂判词、`known-red.json` 重钉（`--check` `FAIL n=2`→`REPIN_GENERATION=PASS`）、`VERIFYALL_SELF=PASS names=26 gen=#50` 见报告。
>   - `TASK-9905` ⚠️ **途中修掉一处判据脆弱性（`D-G42` 族，主控裁定"修、不许声明掉"）**：`printf '%s' "$V" | grep -q PAT` 在 `set -o pipefail` 下，**载荷一大**（生产者吃到 SIGPIPE）就把"**命中**"读成 `rc≠0` ⇒ **假 FAIL**。现场共 **9 处**（`build/MilBridge/tools/r-gate-step.sh` **8 处**＋`build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh:255` **1 处**；`c11` 正是**承载 `D-G55`** 的那一格 ⇒ 证据一超 **64 KiB 就假红**）。**判据文本一字未动，只换喂法**（`grep -q PAT <<<"$V"`）。
>     - 两极化（本缺陷的真证明）：私有副本把 `c11` 载荷撑到 ≈250 KB ⇒ **旧写法 `R_GATE=FAIL crit=12/13`（假红）／新写法 `PASS crit=13/13`**；**阴性对照不放松**（真缺 `seq-combo` 时两版都 `FAIL`）；修后 `R_GATE=PASS crit=13/13`、自测 21/21。
>   - `TASK-9905` ⚠️ **`pf` 那一格不是构建身份** —— 见 `D-G92`（四趟逐字相同的整波重建给出四个不同 `pf` sha）。

### 4.2 `TASK-9906` → `[Next] ✅`（`:329`，含子条 `:330`）

> - `TASK-9906` [Next] ✅ **已办（车道 W95A，报告 §6）** —— `app-local` 副本刷新：**仓内** `STALE=0`／`DIVERGENT=0`（刷 1 份；`UNEXPECTED=6[DECL-GAP-EQ=6]` 是**在册声明类缺口** ⇒ **不许当绿**）｜**仓外** hc 应用目录 `SYNC-APPLOCAL=PASS target=…/HandyControlDemo_Net_GE45/bin/Debug/net10.0 items=5 ok=2 synced=3 drift=0`（每件**拷后回读 sha16 断言**==权威、具名 `mv` 原子改名）｜两本登记册按其自己的口径**删 50 留 1**（现场 **51 条：仍红 1／已转绿 50**，与任务书写的 8/30 不同 —— 整波重建＋波尾刷新已把那 8 条刷绿；保留的那 1 条 = `build/PresentationFramework.Classic.Linux/bin/Debug/PresentationCore.dll` `9465f9dce39e2dfc`，**在册红不许当绿**）。
>   - `TASK-9906` ⚠️ **同趟抓出一条只报未修的仪器缺口 = `D-G91`**（刷新器默认 `SCAN_ROOTS` **漏 `$REPO/tools`** ⇒ **刷不到**那份唯一 `STALE`，还会打出 **`STALE=0` 的假绿**；本波按该件自己文档的承诺**显式补根**才刷到 `STALE=1→0`）。**未修**（不在 W95A 写域）⇒ 落地拆新号。

### 4.3 新增 §15（`:361`–`:367`，**五行一条**）

> ## §15 `#50` 冻结块与冻后新登记（**一行一条**；2026-09-22 车道 W99A 补）
>
> - **`#50` 已冻结并推送**：基线 = **`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` `1f4189c1257737a9`**（**644,091 B**）｜`docs/CURRENT-STATE.md:9` 机器行 `gen=#49→#50`｜远端 `origin/feat-Linux` head = **`608d0a170f07fa57`**（`ls-remote --symref origin HEAD` 仍 `ref: refs/heads/feat-Linux`）。
> - ⚠️ **`#50` 冻结块里的 `pf` 不是构建身份**（见 **`D-G92`**）：冻结块逐字写着"同源、同命令、逐字相同的整波重建**可给出不同字节**"⇒ `pf` 那一格**只作"冻结那一刻硬盘上是这个"的现场值**，**不许**被后人当**漂移／回归判据**（真凶留 `NOINFO`，复算配方见 `D-G92`）。**本件未改冻结块一字**（改了要重冻）。
> - 🆕 **`D-G91`（装置缺陷 · 假绿族）**：`sync-applocal-authority.sh:59` 默认 `SCAN_ROOTS` **漏 `$REPO/tools`**，而校验器 `check-applocal-sync.sh:169` **含**它 ⇒ ① 默认参数**永远刷不到**那份唯一 `STALE`；② 更危险：**它自己用收窄根打出 `STALE=0` 的假绿**。成对读数：`09b`（默认）`refreshed=0/STALE=0` vs `09a`（同刻全文口径）`STALE=1`；显式补根 `09c` 才刷到（`STALE=1→0`）。**只登记未修** ⇒ 落地拆新号（`#51` 候选）。
> - 🆕 **`D-G92`（仪器/身份缺陷）**：**`pf` 不是构建身份** —— 四趟**逐字相同**的整波重建给四个 sha（`881c56e26808269f`／`decd920092287b03`／`581c864a7f2ad36c`／`f34bc297d19778fd`），而 `ARTIFACT_SRC_FP proj=PresentationFramework fp=5b38ea7420b26377 n=1362` **四趟逐位相同**、隔离 `-t:Rebuild` 连跑两次同值；72 字节差异全在 PE `TimeDateStamp`＋MVID＋调试目录。**已按主控裁定写进冻结块** ⇒ 本条只把它在缺陷册里具名；**与既有 `D-G46` 并存**（`D-G46` 记"封条分不清可复现构建 vs 身份位"这个缺口，本条把它"PF 单独重编确定"的推论**在整波口径下收窄**）。
> - **`fp_inputs` 零影响**（本件机械证）：覆盖面 **147 件**（真调用 `fp_inputs()`，`f7e054ad…` 同批），本件编辑的 3 件（`KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`defect-registry-declared.tsv`）**命中全 0** ⇒ 指纹开工=收工=**`ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48`**（== `#50` 冻结值，**逐位相同**）。

### 4.4 复核：三行仍在（`grep -c`）

| 行 | `docs/ROUTES.md` 命中数 |
|---|---|
| `TASK-0108` | **3** |
| `TASK-0703` | **3** |
| `TASK-9907` | **1** |

⚠️ **一处与任务书不符的现场（如实记）**：`TASK-9905`／`TASK-9906` **本来就没有 §13 树行**（它们是 §14"波 `#50` 的 `[Next]` 清单"里的条目，与 `TASK-0108`/`0703`/`9907` 同类）⇒ 我只改了 §14 那两行（＋ 新增 §15），**没有**新增树行。**理由**与 W96A 那次相反：这次任务书**没有**假设它们有树行，且 §14 就是"本波新建任务"的既定落点。

---

## §5 本笔推送：件清单 ＋ `BYTECHECK` ＋ 推送前后 head

### 5.1 差异集口径（**不用自列白名单**）

* 口径 = **克隆侧 `git ls-files`（15229 件）∩ 现盘逐件 `git hash-object`**：开工时 **`SAME=7864 ｜ CHANGED=0 ｜ MISSING_ON_DISK=7365`**（`MISSING_ON_DISK` 大是因为 `R` 是**部分检出**，正常）⇒ **开工时盘与远端逐字节一致 ⇒ 本笔要推的只有我自己改的件**。
* **现盘"未纳入克隆"的候选**（`find` 逐件 vs `git ls-files`）：**6 件**，逐条点名并**全部排除**：
  * `build/MilBridge/gen/tline-ledger-lines-20260921-{1224,1231,1540,1623,1629}.txt`（**5 件**）—— **早于 `#49` 冻结**的老件，W95A 已按同一条排除（**非本波**）；
  * `build/MilBridge/tools/nul-bytes-check.sh`（28,405 B、`17:46`）—— **🔴 不是我的件**：这是**并发车道 W97A**（`TASK-9907`）**正在写**的新工具，任务书明令"**别碰**"⇒ **未 `add`、未推**（由 W97A 自己按纪律推）。
* ⇒ **本笔实推 = 3 件**（下条清单），**逐径 `git add --`**、**无 `git add -A`**、**无 `--force`**、**未碰默认分支**。

### 5.2 本笔推送的件清单（3 件，逐件 sha16）

| # | 路径 | sha16 |
|---|---|---|
| 1 | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `5dc11e2e87073a39` |
| 2 | `docs/ROUTES.md` | `32df06d0f36cd7c9` |
| 3 | `build/MilBridge/tools/defect-registry-declared.tsv` | `0f5fb2d6b8ab0234` |

**"W93A/W94A/W95A/W96A 报告是否尚未推"的现场答案**：**四份都已推完**（它们属 W95A 那 69 件；`git cat-file blob origin/feat-Linux:<path>` 与现盘**逐字节相同**，见下 `BYTECHECK`）⇒ **本笔没有补推任何报告**，只有上面 3 件。

### 5.3 推送结果

```
$ git -C ~/netTest/GitProj/WPFOnLinux push origin feat-Linux
   608d0a1..a3464a6  feat-Linux -> feat-Linux          （3 files changed, …）
```

| 项 | 值 |
|---|---|
| **推送前 head** | `608d0a170f07fa577d150d4a81a12776de57fd59`（= `origin/feat-Linux`，我开工时与之一致） |
| **推送后 head** | **`a3464a6fdba3bc9ff3b971c20bc1185ad85b3f23`** |
| 提交信息首行 | `docs(#50): 登记 D-G91/D-G92 ＋ 地图 9905/9906 收口` |
| 默认分支 | `git ls-remote --symref origin HEAD` = **`ref: refs/heads/feat-Linux`**（**未改**） |
| 提交前工作树 | `git status --porcelain` = **空**（干净，无夹带） |

### 5.4 `BYTECHECK`（**远端 blob == 现盘**）

⚠️ **先显式 `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`**（这个克隆的 fetch refspec **只跟 `main`**；不显式 fetch 会比到**推送前**的旧 ref）⇒ 实测 `608d0a1..a3464a6 feat-Linux -> origin/feat-Linux`，随后：

```
BYTECHECK ok=10 mismatch=0 nobody=0
```
清单（10 件，计数器在**主 shell** 里累加、**没有**用 `… | tee` —— 避免 `#49` 那次"计数器被关进子 shell"的坑）：

| 件 | 归类 |
|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **本笔改动** |
| `docs/ROUTES.md` | **本笔改动** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | **本笔改动** |
| `build/MilBridge/W93A-report.md` | 已推（复核） |
| `build/MilBridge/W94A-report.md` | 已推（复核） |
| `build/MilBridge/W95A-report.md` | 已推（复核） |
| `build/MilBridge/W96A-report.md` | 已推（复核） |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | **冻结基线**（`1f4189c1257737a9`，逐字节相同 ⇒ 证明我没碰） |
| `docs/CURRENT-STATE.md` | 未动（复核） |
| `handoff.md` | 未动（复核） |

`mismatch=0`（不一致清单为空）、`nobody=0`（无缺 blob）。

### 5.5 本报告自身的推送（**自指，如实说明**）

本报告是**紧随其后的第二笔**（**只动 `build/MilBridge/W99A-report.md` 一个文件**）。**本行所在的这一版**无法自述"包含这一行的那一笔"的 sha（自指）⇒ **不写一个会立刻作废的数**；该 head 记在 `~/w99a/STATUS.md` 末条。第三笔（同样只动本报告，补 §7.4）的 head 也记在那里。两笔都遵守同一纪律：逐径 `git add --`、无 `--force`、不碰默认分支。

---

## §6 `fp_inputs` 影响判断（**零影响**，给机械证）

* **覆盖面怎么点算的（可复算）**：把 `build/close-wave.sh` 的 `fp_inputs()` 函数体**原样抽出**成 `~/w99a/fp_inputs.fn`（`sed -n '/^fp_inputs()/,/^}/p'`）再 `source` 后调用 —— **不是**手写复刻。
  * 指纹（真调用，开工与收工各一次，**在 `R` 根目录下跑**）：**`ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48`（== `#50` 冻结值，逐位相同）**，两次同值。
  * 覆盖面件数：**147**（与 `#50` 冻结块写的"覆盖面 147 件"一致）。
  ⚠️ **一个实测坑（顺手记，免得后人踩）**：该函数用的是**相对路径**（`build/…`／`src/…`）⇒ **必须在 `R` 根目录下调用**；我在 `$HOME` 下调过一次，得到的是**空输入的 sha**（`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`）—— 那是**假读数**，已作废、不入任何结论。
* **我编辑的件是否在覆盖面内**：把覆盖面列表导出后 `grep -cxF` 逐件点算 ⇒ **命中全 0**：

| 本件编辑/新建的件 | 在覆盖面里的命中数 |
|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **0** |
| `docs/ROUTES.md` | **0** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | **0** |
| `build/MilBridge/W99A-report.md`（本报告，新建） | **0** |
| （另有 `docs/CURRENT-STATE.md`／`handoff.md`／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`／四份车道报告，供对照） | 各 **0** |

⇒ **登记动作不动 `inputs_fp`**（与 W95A §2.5、W96A 同一结论），**无需重钉、无需重冻**。

---

## §7 `NOINFO` / 未做清单（逐条如实）

1. **`D-G91` 未做"修法两极化"** —— 本件**不改那件仪器**（不在写域），所以"把 `:59` 默认值改成与校验器同源之后，默认参数下的 `STALE` 真能刷到"这一条**没有读数**。`NOINFO`。
2. **`D-G91` 的"是否还有别的根差"未盘** —— 只核了 `:59` vs `:169` 两个默认串的 `diff`（差**只有** `tools` 一处）；"全仓还有几处同类两套根集合"**未逐条枚举**。
3. **`D-G92` 的真凶未抓** —— 已有四条排除（工程确定性开关／PF 单独构建／csproj 内容／源指纹能看见），**漂移落在指纹覆盖面之外**；**没有**跑任何整波/定向重建（重活，且本件禁跑）。复算配方已写进条目。
4. **`D-G92` 是否该"并入 `D-G46` 而不新增号"** = **我的判断，不是读数**（依据见 §1③）。若主控裁定相反，回退是一处单点改动。
5. **未跑任何门禁/构建**（任务书禁跑 `verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／任何构建）⇒ 本件的两条 `DEFREG` 读数**只证明登记自洽**，**不证明**冻结基线仍绿（那由 `#50` 的冻后 ×2 负责，已在册）。
6. **未改 `handoff.md`／`docs/CURRENT-STATE.md`**：任务书允许"只许加 `#50` 已冻的摘要行"，我判断**不加更好**——① `:9` 机器行是冻结器写的、我一个字都不该碰；② `handoff.md` 是**逐波追加**的档案，加一行"摘要"会引入一处**无人要求的新叙述**，而 §15 已经把这件事记在地图里。⇒ **如实记为"我选择不做"，不是"做不到"**。
7. **未做全仓 `_NET_SUPPORTING_WM_CHECK` 盘点**（那是 `TASK-0703` 的写域，W96A 已把它列为未做项，本件同样未做）。
8. **`D-G88`/`D-G89`/`D-G90` 的 `req=KD,AB`** 我**只核实现场**（`--emit` 的产物）与**成因**（冻结块正文已有它们），**没有**改 `AB`、也**没有**为它们改 `req`。

---

## §8 大白话小结（6 行）

1. **两条新发现都登记了**：`D-G91`（刷新器默认少扫一个目录 ⇒ 会自己打出"全绿"的假读数）和 `D-G92`（`pf` 那一个哈希**不是**"这份源码编出来的身份"，同样的整波重建跑四趟给四个值）。
2. **`D-G92` 为什么不并进老条目 `D-G46`**：老条目量的口径是"单独重编"、还写着"PF 是确定的"；新发现量的口径是"整波重建"、结论**相反** ⇒ 硬塞进一条会把矛盾藏起来。所以我**新开号**，同时给 `D-G46` 加了一句"追记"指向它，**老条目一个字没删**。
3. **冻结的基线文件没被碰**（`ACCEPTANCE-BASELINE.md` 逐字节还是 `1f4189c1257737a9`），`CURRENT-STATE.md` 的机器行也没碰。
4. **门禁两条都绿**：`DEFREG=PASS declared=128 route_ids=128`、`DECLDRIFT=0`，跑两遍一样。
5. **地图收口了**：`TASK-9905`／`TASK-9906` 都改成 ✅（并把 `#50` 的冻结值、冻前那一处声明类红、`pf` 不是构建身份这件事写进去），另加了一节 §15。
6. **推上去了**：`608d0a1 → a3464a6`，3 件，逐字节核对 `ok=10 mismatch=0 nobody=0`；并发车道 W97A 正在写的新工具（`nul-bytes-check.sh`）**我没碰也没推**。
