# W130A 报告 —— `TASK-0203` 终报读数落册 ＋ 收口（`🟡 → ✅`）＋ `D-G106`／`D-G107`／`D-G109` 三条交叉引用 ＋ 推一笔

- **车道**：`W130A`｜**任务**：纯文本编辑 ＋ 一次推送｜**零** `dotnet`／**零**构建／**零**门禁／**零**应用／**不占槽**
- **判据先写**：`~/w130a/criteria-TASK-0203.md` sha16 **`833429ffb9c84d44`**（FULL `833429ffb9c84d44d74363172e751710278ca97f89f6aa30751db23e181b1a45`），**早于本件任何写入/推送**
- ⚠️ **车道 id 撞名（如实记）**：`~/w130a/criteria.md`（**上一批同名车道**，对象 = `TASK-0109` 的 `wpf_x11_has_ewmh_wm()` 残留边界，写定 `2026-09-23 10:11:44`，`18591 B`）**与本批无关**；为**不覆盖别人的判据件**，本批另起文件名 `criteria-TASK-0203.md`，**原 `criteria.md` 一字未动**（现场 `stat` 仍 `10:19`）。
- **开工快照（写判据时现取）**：`AB=27293fb5ab91b778`（`gen=#52`）｜远端 head = **`4b2d7c3a6935bf4184d6c1d5578d77b358423f7e`**（＝克隆 `HEAD` ＝ `origin/feat-Linux`）
- **全部读数现场现算**（`sha256sum | cut -c1-16`／`wc`／`python3` 现算），**无手抄哈希**

---

## ① `TASK-0203` 收口段（逐字）

**改前 → 改后（状态位；判词文字一字未动）**

| 位置 | 改前 | 改后 |
|---|---|---|
| `docs/ROUTES.md:200`（§13 任务树，**活状态行**） | `│   ├─ TASK-0203 [Next] 🟡 **精度目标达成、…**` | `│   ├─ TASK-0203 [Next] ✅ **精度目标达成、…**` ＋ **行尾追加**收口限定 |
| `docs/ROUTES.md:336`（§14 波 `#50` `[Next]` 清单，**活状态行**） | ``- `TASK-0203` [Next] 🟡 **静默 `139` 长跑 —— 已办，但只到 🟡（车道 W98A，`` | ``- `TASK-0203` [Next] ✅ **静默 `139` 长跑 —— 已办并收口**〔原文"已办，但只到 🟡"是**当时读数**…〕**（车道 W98A，`` |

**§13 行尾追加（逐字）**：
> ｜〔**2026-09-23 收口：状态位 🟡 → ✅**（车道 W130A 落册）—— 这里的 ✅ **只指"测量交付完成"**（机制 ＋ 具名判定点 ＋ 两个同址样本 ＋ 上界 `3.55%` 均已拿到，终报读数见下方新增两行与 **§15p**）；**产品侧未修 ⇒ `D-G109` 仍红**、处置 = **`TASK-0209`**〕

**§13 行下新增两条子行（逐字）** —— 即 `docs/ROUTES.md:204`／`:205`：
> `│   │   ├─ 🆕 **终报收口（2026-09-23；读数出自车道 W128A 终表、车道 W130A 落册时现场复核；报告 `build/MilBridge/W128A-report.md` FULL `789d01e5f8959b0b70ffda770e8c02dac653661e48af5510f7e5a5d6ca485878`／`head -n -2` sha16 `d014ebd90d45840e`／352 行／37,548 B）**：主臂 **`175/175` 全部有效（剔除 0、作废 0）** ＋ 对照臂 **8 趟**（`K0C…K7C` 全 `124/alive/落地 8`，逐批阳性对照成立 ⇒ **零作废**）⇒ 结局 = **`134`×173 ＋ 静默 SEGV×2**；**命中 2 趟**：`W071`／`W077` 崩点 **`PC` 逐位同址 `0x7fff740dcdf3` = `wpf_queue_push+259`**（偏移 `0x11df3`，逐字 `mov 0x38(%rax),%rax`）＋ 两趟 `stacklast.raw`／`maps.txt`／`perf.map` **同刻齐全**（mtime delta `0.0`）＋ 整目录冻结 `~/w128a/frozen/{W071,W077}`（`stacklast.raw` = `9ff31a24fa90f56e`／`9cd325be4e5381b0`）｜判词 = **`异源`**（崩在 **`.NET Finalizer`（`tid=6`）**／**浅栈 `7,088 B`**／**无重复环 `R1=R2=False`**／**应用输出 0 字节**）＋ **判定点 = `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82`**（约 `:79` `while (p->next) p = p->next;`）；`siaddr=0x0` 记 `NOINFO`、**判词不依赖它**｜**上界（新口径）**：本批 **`2/175 ⇒ 95% 单侧上界 3.55%`**（点估计 **`1.14%`**）｜与 `W98A` 同件同腿合并 **`3/235 ⇒ 3.27%`**｜本装置全部 **`2/236 ⇒ 2.64%`**｜**再压的代价（未自行开跑）**：`≤1.0%` 需 **299／473 趟**、`≤0.5%` 需 **598／947 趟（≈5.3／8.4 槽小时）** ⇒ **主控裁定：不投**（机制与判定点已拿到、上界已足够；要投由用户拍板）｜**槽**：批内实占 `5,880 s`、**让路 `4,778 s`（≈80 min，全给 `#52` 收尾链）**、批间一律释放槽，`low-memory`／`MAXHOLD_KILL`／`TIMEOUT` 各 **0**`
>
> `│   │   └─ ⚠️ **收口口径（逐字，须与 `D-G109` 同读）**：**`TASK-0203` 的"✅" = 测量交付已完成**（`139` 族**不再 `NOINFO`**：归因落到"**异源 ＋ 具名判定点**"）；**产品侧修复另立 `TASK-0209`（已由 W129A 立）⇒ `D-G109` 仍红、不许当"已修"**。**口径句（逐字）**：…（见 §③）…**`D-G98` 的适用范围照旧：只指 `134` 族的几何/尺寸约束那条线，不含静默 SEGV**（两者**异源**）。**交叉引用（不新号）**：`D-G106`／`D-G107`／`D-G109`／`D-G96``

**§14 行内追加（逐字，紧接状态位之后）**：
> 〔原文"已办，但只到 🟡"是**当时读数**；**2026-09-23 转 ✅**（车道 W130A 落册）= **测量交付完成**：`139` 族归因已由 `NOINFO` 推到"**异源 ＋ 具名判定点**"、上界 **`2/175 ⇒ 3.55%`**；**产品侧未修 ⇒ `D-G109` 仍红**、处置 = **`TASK-0209`**，终报读数见 **§15p**〕

**新节 `docs/ROUTES.md:667` 起 = `## §15p`（本批新增，10 条 bullet，逐字在册）**：收口行｜终报读数行｜上界＋再压代价行｜口径句行｜三条交叉引用行｜`TASK-0209` 指针行｜边界口径行｜`DEFREG` 行｜推送行。
**取代声明（写进 §15p，历史行一字未动）**：§15 行、§15n 第 ② 条（"状态位保持 🟡、不许转 ✅"）、§15o 末条（"状态位仍 🟡"）里的**状态读数**被本批取代；那三处**原文未改**，只在 §15p 声明取代关系（**不覆盖历史读数**）。

**为什么 ✅ 不是"放宽判据"**：`TASK-0203` 的验收对象是"**静默 `139` 的测量**"（判据 = 该族**可复现 ＋ 可归因 ＋ 带上界**），三格**全部拿到**（`175/175` 有效、2 命中同址、上界 `3.55% ≤ 5%`）；**产品缺陷本体未修**，故同处写死"`D-G109` 仍红、处置 = `TASK-0209`"。**没有任何一格由红改绿**。

---

## ② 三条交叉引用追加（逐字；**全部"追加 bullet、原判词一字未动"**，**不开新号**）

**文件**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（**+4 行**；`2824 → 2828` 行）

1. **`D-G106` 段末追加（`:2784`，逐字）**：
> `- 🔁 **该判词要件由车道 W128A 独立复现**（报告 FULL `789d01e5f8959b0b70ffda770e8c02dac653661e48af5510f7e5a5d6ca485878`／`head -n -2` sha16 `d014ebd90d45840e`／352 行／37,548 B；**车道 W130A 现场现算**），实例 = **`W071`／`W077` 两趟**（`~/w128a/runs.tsv` 这两行同时 `ext_kill_suspect=yes` ∧ `family=other` ⇒ **旧口径把两趟真命中同时判成"假可疑"并剔出分母**）；**代价 = 旧口径漏判 2 ＋ 误剔 2**（`~/w128a` 183 趟：旧口径 **0 命中** → 新口径 **2**）；**`~/w118a` 71 趟与 `~/w98a` 128 趟重扫零影响**（`L1B024` 两代口径都命中）。⚠️ 本条**原文一字未动**。`

2. **`D-G107` 段末追加（`:2792`，逐字）**：
> `- 🔁 **该判词要件由车道 W128A 独立复现**（报告 FULL `789d01e5f8959b0b70ffda770e8c02dac653661e48af5510f7e5a5d6ca485878`；**车道 W130A 现场现算**），实例 = **`W071`／`W077` 两趟** —— 这两趟崩在 **`.NET Finalizer`（`tid=6`，**名含空格**）** ⇒ 按 `thread=(\S+)` 解析**整行不匹配** ⇒ 一度被判成"**没有 deep 停止点**" ⇒ **误判 `NOINFO`**（W128A 的 8,192 B 浅栈全量倒出另证调用链 = `HwndWrapper::Finalize()` → `System.GC::RunFinalizers()` → `IL_STUB_PInvoke(…WindowMessage…)` → `PostMessageW+0xc7` → `wpf_queue_push+0x103`）；**旧口径漏判 2 ＋ 误剔 2**；**`~/w118a` 71 趟与 `~/w98a` 128 趟重扫零影响**。⚠️ 本条**原文一字未动**。`

3. **`D-G109` 段内追加两条（`:2825`／`:2826`，逐字）**：
> `- 🔁 **终报补（2026-09-23；读数出自车道 W128A 的终表、车道 W130A 落册时现场复核；报告 `build/MilBridge/W128A-report.md` FULL `789d01e5…`／`head -n -2` sha16 `d014ebd90d45840e`／352 行／37,548 B）**：**`175/175` 主臂趟全部有效（剔除 0、作废 0）** ＋ **对照臂 8 趟**（`K0C…K7C` 全 `124/alive/落地 8`，逐批阳性对照成立 ⇒ 零作废）⇒ 结局 = **`134`×173 ＋ 静默 SEGV×2**；**命中 2 趟、两样本同址**（`W071`／`W077`：`PC` 逐位 `0x7fff740dcdf3` = `wpf_queue_push+259`，`tid=6`、`depth=7,088 B` 逐位相同，`frozen/*/stacklast.raw` = `9ff31a24fa90f56e`／`9cd325be4e5381b0`）；**95% 单侧上界 = `2/175 ⇒ 3.55%`**（点估计 `1.14%`）｜与 `W98A` 同件同腿合并 **`3/235 ⇒ 3.27%`**｜本装置全部 **`2/236 ⇒ 2.64%`** ⇒ 上面那句"最终计数与 95% 单侧上界本件 `NOINFO`"**已由本行取代**；**可复算入口 = `~/w128a/{runs.tsv,frozen/{W071,W077}}`**。⚠️ 本号**已有的 `SILENT_SEGV_HIT` 三条件口径句一字未动、逐字照用**（本批**不重写**）；⚠️ 上面"同一件两个值"那条（`pad` `903` vs `1129`）**照旧两个都给**。`
>
> `- 🔁 **状态位更新（2026-09-23 车道 W130A）**：上面 `- **处置（产品侧未修 ⇒ 本号仍红）**` 里的"`TASK-0203` 的状态位**仍 🟡**"是**当时读数**；`TASK-0203` 现由 **🟡 转 ✅**，且该 ✅ **只指"测量交付完成"**（机制 ＋ 具名判定点 ＋ 两个同址样本 ＋ 上界已拿到）—— **本号仍红**、**产品侧未修**、处置仍在 **`TASK-0209`**。（该行**一字未动**，仅本行声明取代关系。）`

**关于 `TASK-0209`**：**未重复立号**（已由 W129A 立于 `§15o`）；只在 `§15p` 追加一行指针（"终报读数见 `TASK-0203` 行（`2/175 ⇒ 3.55%`、两样本同址）"），**未改它的状态位**（仍 🔴）。
**关于"新号"**：W128A 交的两条仪器缺陷**已被既有 `D-G106`／`D-G107` 覆盖**（射程逐字比对：前者 = `ARM=gdb` 下 `APP_RC` 不是应用 rc ⇒ 假可疑把真命中踢出分母；后者 = `thread=(\S+)` 读不出多词线程名）⇒ **一条新号都没开**、**未走 `--emit` 加声明行**。

---

## ③ 口径句（逐字）

**`SILENT_SEGV_HIT ⇔ 应用输出 == 0 B（剔 `timeout:` 行）∧ STACKOVF == 0 ∧ 死于 SIGSEGV（`RC==139` ∨ `APP_FATE` 含 SIGSEGV ∨ `gdb.txt` 含 "Program terminated with signal SIGSEGV" ∨ `gdb.txt` 存在 `W118A-STOP-N`(N≥1) 且 `signo=11`）`** —— **最后一支抗收尾截断**。

- **落在两处**：① `docs/ROUTES.md:205`（`TASK-0203` 行下）② `docs/ROUTES.md` `§15p` 的"收口口径句"行。
- ⚠️ **同句早已逐字在册于 `D-G109`**（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2818`，**W129A 写的**，仅反引号排版略异：`（剔掉 `timeout:` 那行）`／`**`STACKOVF == 0`**`）⇒ 本批**只引用、不重写**（避免"同一口径两处措辞分叉"）。**该原行一字未动**（现场核：`:2818` 全文仍在）。

---

## ④ `DEFREG` 两条机读行（现场跑**两遍**，逐字相同，`rc=0/0`）

```
DEFREG_DECL=n=145 route_ids=145 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=145 route_ids=145（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
rc=0        （第 1 遍）
rc=0        （第 2 遍；两遍输出 cmp IDENTICAL）
```
- 工具 = `build/MilBridge/tools/defect-registry-check.sh`（**只读**；本批**未改**它）。
- **`--emit` 重生成** `build/MilBridge/tools/defect-registry-declared.tsv`：`ID` 行**逐一 diff = 0 行**（`declared` `145 → 145`，**零幻影声明**）；实际变化只有 `# DECL-GEN`（时间戳）与 `# DECL-ANCHORS`（`KD` 因本批改册而变）两行 ⇒ 文件 `423bff22079d04ea → c8d59c5b8dc36ef1`。
- **未碰** `CS`／`HO`／`AB`（`737c78e3a7e5a3a5`／`e4dc264200b421d0`／`27293fb5ab91b778`，改前＝改后）。
- ⚠️ **`DECL-ANCHORS` 里 `KRJ=f108775906eac9aa` 是 `$R` 的现场值**，而**克隆/远端** `build/MilBridge/known-red.json` 仍是 **`d4e0080df6ec497c`**（＝远端 `HEAD` blob 现算，**波 `#53` 在办、本件不许碰**）⇒ 在**远端**跑同一牙时那条**非门禁诊断行**会读成 **`DEFREG_DECLDRIFT=1`**（唯一漂移项 = `KRJ`），`#53` 推该件后**自愈**。**本件如实点名，不隐藏**；若上级要求"发布态自洽"，处置 = 用 `DRC_KRJ=<克隆件>` 重生成一次（一条命令），代价是 `$R` 本地读成 `DECLDRIFT=1`（**本节按任务书口径取"现场现取"**，故选了 `$R` 现场值）。

---

## ⑤ 推送＋`BYTECHECK`＋件对账

- **起点**：`HEAD = origin/feat-Linux = ls-remote origin HEAD =` **`4b2d7c3a6935bf4184d6c1d5578d77b358423f7e`**（三者一致，开工现取）
- **逐径 `git add`（无 `-A`、无 `--force`）**：仅 4 条路径 —— `docs/ROUTES.md`｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`｜`build/MilBridge/tools/defect-registry-declared.tsv`｜`build/MilBridge/W130A-report.md`
- **件对账（改了几件 ↔ 推了几件）**：`$R` 改动件 = **4**（报告为新建）；克隆 `git status --porcelain` 推送前 = **4 条**（3 `M` ＋ 1 `??`→`A`）；`git commit` 后 `git show --stat` 件清单 = **逐件等于**上面 4 条路径（**无第 5 件**）。⚠️ 特别核过：`verify-all.sh`／`docs/WAVE53-PREREGISTRATION.md`／`src/**`（`#53` 在办）／`known-red.json` **一件都没进本笔**。
- **推送**：`git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`（**refspec 陷阱**）→ `git push origin feat-Linux` → **重新 `fetch`** ＋ 与 `git ls-remote origin HEAD` **交叉核**；`ls-remote --symref origin HEAD` 仍 `refs/heads/feat-Linux`。

| 项 | 值 |
|---|---|
| 推送前 head | **`4b2d7c3a6935bf4184d6c1d5578d77b358423f7e`** |
| 推送后 head | 见下方 **RECORD-补** |
| `BYTECHECK` | 见下方 **RECORD-补**（判据 = **远端 blob == 克隆工作树**，逐件 `git cat-file -p HEAD:<path> | sha256sum`） |
| 件对账 | 改 **4** ↔ 推 **4**（第 2 笔只含报告自身，见 RECORD-补） |

**改前/改后 sha16（`$R` ＝ 克隆，逐件相同；`BYTECHECK` 判据）**

| 件 | 改前 | 改后 | 行数 |
|---|---|---|---|
| `docs/ROUTES.md` | `3712b63a52875344` | **`caa09cbdd105e564`** | `663 → 677`（**+14**：树 `+3`、§15p `+12`；`wc -l` 复核无吞行） |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `9e22f5f695af6365` | **`58d9056f497799ba`** | `2824 → 2828`（**+4**） |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `423bff22079d04ea` | **`c8d59c5b8dc36ef1`** | `154` 行（`ID` 行 `145` 不变） |
| `build/MilBridge/W130A-report.md` | —（新建） | 见 **RECORD-补** | — |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**未碰**） | `27293fb5ab91b778` | `27293fb5ab91b778` | — |
| `docs/CURRENT-STATE.md`（**未碰**） | `737c78e3a7e5a3a5` | `737c78e3a7e5a3a5` | — |

**`fp_inputs` 影响 = 零（机械证，双向）**：本批改的 4 件**一件都不在覆盖面**——现场核 `close-wave.sh` 的 `fp_inputs()` 可执行体 = **4 条 `find` ＋ 1 个 21 件显式名单**，逐字 grep `ROUTES.md|KNOWN-DEFECTS.md|defect-registry-declared.tsv|W130A-report.md` ⇒ **0 命中**（`grep rc=1`）；**成对实测**：把本批 3 件拷进克隆**前后**，复刻的 `fp_inputs` 指纹**逐位相同** = **`84fd55d384e93203317d22601cec854d518e69c8f026006231302a2cfbc93366`**（＝ `#52` 冻结值）。⇒ **本笔对 `inputs_fp` 零影响**。（`$R` 现值 `5ac1e5349c7d1dec…` **≠** 冻结值，差异**全部**来自 `#53` 在办的 `src/**` 三件与 `known-red.json`，**与本批无关**。）

---

## ⑥ `$R` 与远端（克隆 `HEAD` blob）不同的件（单列；**本地领先 = 波 `#53` 在办**）

| 件 | `$R` | 克隆/远端 | 归属 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `9fa20864404ab01b` | `11142fbef049eb66` | **`#53` 在办（本地领先）** |
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `a9cc8762908b417a` | `3117923a7c899e05` | **`#53` 在办** |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `4e1880e6054635ff` | `e4f2de8d038e4780` | **`#53` 在办** |
| `verify-all.sh` | `32ddbe487235cc38` | `0cdd12547a634b37` | **`#53` 在办**（任务书点名"`mtime 12:10`、千万别 add/改"） |
| `docs/WAVE53-PREREGISTRATION.md` | `b5ecd5433a57af47` | **远端不存在**（`$R` 独有） | **`#53` 在办** |
| `build/MilBridge/known-red.json` | `f108775906eac9aa` | `d4e0080df6ec497c` | **`#53` 在办**（⇒ §④ 的 `DECLDRIFT` 提示项） |

⇒ **本批一件未推、一件未改**（上面 6 件在克隆里 `git status` 全干净；本笔 `git show --stat` 不含它们）。
**另单列（`$R` 独有、未跟踪、未推）**：`build/MilBridge/W118A-report.md`、`build/MilBridge/W128A-report.md`（`W128A-report.md` 是本批交叉引用的**证据源**，**只在 `$R`、不在远端**）⇒ **本件按写域不推**（任务书写域只有 4 件），**如实点名待上级裁定**：远端读者目前**拿不到** `789d01e5…` 那份报告本体。

---

## ⑦ `NOINFO` / 未做（既不算绿也不算红）

1. **`--emit` 的 `KRJ` 锚**：选题见 §④ —— **远端会读 `DECLDRIFT=1`（非门禁诊断行）**，本件**不掩盖**；"发布态自洽"是否要走 `DRC_KRJ` 覆盖重生成一次 ⇒ **待上级裁定**（一条命令，双向代价已写明）。
2. **`W130A-report.md` 自身 sha16／推送后 head／`BYTECHECK`** 只能写在 **RECORD-补**（自指：把值写进文件会改变它）—— 与 `W128A` 报告 §⑯ 同一条既有口径。
3. **`W128A-report.md` 未推**（见 §⑥）⇒ 远端读者**拿不到**该证据源本体；`~/w128a/**`（台账 `runs.tsv` 184 行、`frozen/{W071,W077}`、`pinned` 原件）**只在宿主本地**。
4. **未跑**：任何牙的 `--selftest`（`defect-registry-check.sh --emit` **不在**此列 —— 它是任务书要求的重生成动作）、任何构建／门禁／应用、`verify-all.sh`（`#53` 在办）。
5. **未改**：`TASK-0209` 状态位（仍 🔴，处置不在本批）；`D-G109` 的"**上游写坏者**"仍 `NOINFO`（那是 `TASK-0209` 的活）；§15／§15n／§15o 的**历史状态读数**（**一字未动**，只在 `§15p` 声明取代）。
6. **车道 id 撞名**（`~/w130a/criteria.md` 属上一批同名车道）⇒ 本批判据另名；**未删未改**别人的件。
7. **`TASK-0201` 行（`:198`）的"状态 🟡 与判词一字未改"**：本批**未动**它（它引的 `TASK-0203` 上界 `4.87%` 是 `W98A` 的读数，本批新增的是 `W128A` 的 `3.55%`，两者口径不同、都已并列在册）⇒ 若上级要同步该行，属**另一笔**（本批不越写域）。

---

## ⑧ 大白话小结（≤6 行）

1. `TASK-0203` **收口了**：树行与 `#50` 清单行**两处状态位 🟡 → ✅**，判词一字没改，只追加"✅ = 测量交付完成"这个限定。
2. 说清"✅ 的是什么"：`139` 那只静默崩溃**抓到了、能归因了**（两个样本崩在**同一地址** `.NET Finalizer` 线程里 `wpf_queue_push+259`），发生率上界 **3.55% ≤ 5%**，**175 趟一趟没作废**。
3. 说清"✅ 不是的"：**产品代码没修**，缺陷 `D-G109` **还是红的**，修它另有一条 `TASK-0209`。
4. 三条交叉引用**全落**：`D-G106`／`D-G107` 各加一行实例（正是那两趟真命中被旧口径漏判 2、误剔 2），`D-G109` 加终报补；**一个新编号都没开**。
5. `DEFREG=PASS declared=145 route_ids=145`、`DECLDRIFT=0`，连跑两遍一样；**零幻影声明**；我改的 4 件**不进门禁指纹**（拷贝前后 `inputs_fp` 逐位相同）。
6. 唯一要盯的：`--emit` 把 `$R` 现场值 `KRJ=f108775906eac9aa` 写进了声明表，而远端还是 `d4e0080df6ec497c`（`#53` 在办）⇒ **远端那条诊断行会读成 1**，等 `#53` 推了就自愈。

---

## RECORD-补（推送后补记；本节写入时 §⑤ 的 head/`BYTECHECK` 已是实测值）

- **第 1 笔（本批正文，4 件）**：`4b2d7c3a6935bf4184d6c1d5578d77b358423f7e` → **`fb235d444c580fe8eaa586112e1445e42d0e6fdf`**
  - `git show --stat HEAD` 逐字：`4 files changed, 170 insertions(+), 5 deletions(-)`（`build/MilBridge/W130A-report.md` 147 ＋／`build/MilBridge/tools/defect-registry-declared.tsv` 4（2＋2−）／`docs/ROUTES.md` 20（17＋3−）／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 4 ＋）⇒ **件清单 = 本批 4 件，无第 5 件**。
- **推送后三方一致（重新 `fetch` 后现取）**：`git rev-parse HEAD` = `git rev-parse refs/remotes/origin/feat-Linux` = `git ls-remote origin HEAD` = **`fb235d444c580fe8eaa586112e1445e42d0e6fdf`**；`git ls-remote --symref origin HEAD` 仍 **`ref: refs/heads/feat-Linux`**。
- **`BYTECHECK`（判据 = 远端 blob == 克隆工作树，逐件 `git cat-file -p HEAD:<path> | sha256sum` 现算）**：**`BYTECHECK ok=4 mismatch=0 nobody=0`**
  - `docs/ROUTES.md` `caa09cbdd105e564` ｜ `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `58d9056f497799ba` ｜ `build/MilBridge/tools/defect-registry-declared.tsv` `c8d59c5b8dc36ef1` ｜ `build/MilBridge/W130A-report.md` `45d1ec3b4504ce4c`（= 第 1 笔里那份；本节改了报告本体 ⇒ 第 2 笔为**报告 RECORD-补**、其 head 落在交件消息里，与 `W100A`/`W127A` 同法）。
- **冻结物复核（推送前后各一次，逐位未变）**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = `27293fb5ab91b778`｜`docs/CURRENT-STATE.md` = `737c78e3a7e5a3a5`（`:9` 机器行 = `gen=#52`）｜`handoff.md` = `e4dc264200b421d0`。
- **`$R` 与远端不同的件**：§⑥ 那 6 件（`#53` 在办）**推送前后都未进任何一笔**（克隆 `git status` 干净后可复核）。
- **`DEFREG` 推送后复跑一遍**（同一现场）：`DEFREG=PASS declared=145 route_ids=145`｜`DEFREG_DECLDRIFT=0`｜`rc=0`。

（口径：`head -n -2 <本文件> | sha256sum | cut -c1-16` = 下一行的值，即"正文含本行"的字节；本文件末两行 = 本行 ＋ sha16 行）
本报告 sha16 = `38ce22bec6639c68`
