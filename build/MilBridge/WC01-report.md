# WC01 报告 —— 补推两份证据报告 ＋ 记档远程 `DECLDRIFT=1`(`KRJ`) 口径句 ＋ `TASK-0201` 上界读数更新 ＋ 推一笔

> **一句话**：把此前只在 `$R` 的**两份证据本体**（`W128A-report.md`／`W118A-report.md`）经**占位符门**（逐件 **0 命中**、两法交叉核）推上远端；在 `docs/ROUTES.md` **追加**新节 **§15q**（远程 `DECLDRIFT=1` 唯一漂移项 = `KRJ` 的**口径句**）与 **§14 `TASK-0201` 行下的上界读数更新行**（**原判词一字未动**）；**推一笔** → head `9241f9f8…` → **`4c3a513c48acb17ffd293e3df50efb8f8a2d81ff`**，`BYTECHECK ok=3 mismatch=0 nobody=0`。

- **车道**：**WC01**（**新会话级前缀**；目录 `~/wc01/` —— 本件起主控车道**不再**用 `wNNNa` 命名，因为**两个会话在各自编号、已发生过撞名**，例：`~/w130a/criteria.md` 属**上一批同名车道**、对象是 `TASK-0109`）。
- **纯文本编辑 ＋ 推送**：零 `dotnet`／零构建／零门禁／零应用／**不占槽**（`HEAVYSLOT` 一行都没有 —— 本件**未申请过槽**）。
- **判据先写**：`~/wc01/criteria.md` **sha16 `52eb793a68e9af20`**（写在**任何写入之前**；本报告全部读数按该判据取）。
- **`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`**（**不是 git 仓库**）；克隆 = `~/netTest/GitProj/WPFOnLinux`（`origin` = 用户 fork、分支 `feat-Linux`）。
- **现状（开工现场现取，非照抄任务书）**：冻结 `#52 = 27293fb5ab91b778`｜`docs/CURRENT-STATE.md:9` 逐字 `> BASELINE-FROZEN gen=#52 sha16=27293fb5ab91b778 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`｜`DEFREG=PASS declared=145 route_ids=145`／`DECLDRIFT=0`（**本地**）｜远端 head 开工 = **`9241f9f82beb2b21a5e7b37cde064d8dd5a21ead`**。
- ⚠️ **另一会话正在本仓跑 `#53`**（现场活进程：`heavy-slot.sh --max-hold 1500 … ~/w133a/bin/verify-pre.sh`（pid `764092`／`764093`）＋ `timeout 1450 bash verify-all.sh`（pid `800114`／`800115`，开工时已跑 `01:18`））⇒ `verify-all.sh`／`docs/WAVE53-PREREGISTRATION.md`／`known-red.json`／`src/**` **一件都未 add／未改**。

---

## §① 两份证据报告的**占位符门**读数（逐件两法交叉核）

**判据**（`criteria.md` §1，**硬门**）：`grep -n -F -e <三连尖括号> -e <双 at> <件>` 命中 **0 行** ⇒ 可推；**≥1 行** ⇒ 不许推、逐条列出并在报告里写"为防推半成品而不推"。
⚠️ **本报告正文自身也过同一道门**：此处的两个模式以**描述式**写法给出（`<三连尖括号>` = `U+003C`×3；`<双 at>` = `U+0040`×2），**不写字面量** —— 因为**写了字面量的正文自己会被下一次占位符扫描误判**（本件第一版就踩过：现算命中 **3 行**／`U+003C`×3 计 **4** 次、`U+0040`×2 计 **2** 次 ⇒ 改写为描述式后**逐件归零**）。

| 件 | `grep` 命中行数 | python 独立复算（两模式各自 `bytes.count()`） | 判定 |
|---|---|---|---|
| `build/MilBridge/W128A-report.md` | **0**（无任何命中行可列） | **0 / 0** | ✅ **推** |
| `build/MilBridge/W118A-report.md` | **0**（无任何命中行可列） | **0 / 0** | ✅ **推** |

- **命中行逐条**：**无** —— 两件**都是 0 命中**，故**没有**任何一件因占位符被拦（"为防推半成品而不推"这一条**本次未触发**）。
- ⚠️ **`grep -c` 的退出码不是读数**（命中 0 时 `rc=1` 是"无命中"、不是失败）⇒ 本件以**打印出的行数**为读数，并用 **python `bytes.count()`**（第二种工具）复算同一量（`D-G104` 精神：计数类读数必须第二种工具复算）—— 两法读数**一致**。
- **身份判据**（期望值**现场现算**、不手抄）：

| 件 | 判据 | 期望（任务书给定） | 现场现算 | 一致 |
|---|---|---|---|---|
| `W128A-report.md` | FULL `sha256sum` | `789d01e5f8959b0b70ffda770e8c02dac653661e48af5510f7e5a5d6ca485878` | **`789d01e5f8959b0b70ffda770e8c02dac653661e48af5510f7e5a5d6ca485878`** | ✅ |
| `W118A-report.md` | `head -n -2 <件> \| sha256sum \| cut -c1-16` | `a22eb8a7881e01ba` | **`a22eb8a7881e01ba`** | ✅ |

- 尺寸／行数（现场 `wc -l -c`）：`W128A-report.md` = **352 行／37,548 B**（与任务书给定**一致**）｜`W118A-report.md` = **431 行／43,052 B**（FULL sha256 现场 = `77cd063b2234643eb4b84c65ac340624fe54de4034b605f273520c3249feaae3`）。
- **补充事实（与 §15o 的旧读数对照）**：§15o 末条曾记 `W128A-report.md` 现算 sha16 **`34cbdff1b5d1bebd`**、且 §⑮／§⑯ 仍是**未填值占位标记**（`TABLES`／`SELFSHA` 两处、各由三连尖括号包裹）**占位符**（"该报告**仍在写**"）。**本件现场复核**：该件现已**写完**（sha16 变 `789d01e5f8959b0b`、占位符 **0**、352 行）⇒ **§15o 那条是当时读数，本批不重复登记、只在此并列可读**（**§15o 原文一字未动**）。

## §② 推送件清单 ＋ 推送前/后 head ＋ `BYTECHECK`

**推送纪律（今天刚出 `D-G108` 事故）**：**逐径 `git add <file>`**、**绝不 `-A`／`--force`**；**推前逐件对账**。

**本批件清单（改了几件 ↔ 推了几件：3 ↔ 3）**：

| # | 件 | 类型 | 现场 sha16 | 行数变化 |
|---|---|---|---|---|
| 1 | `build/MilBridge/W128A-report.md` | **新建**（`$R` → 克隆） | `789d01e5f8959b0b` | ＋352（新件） |
| 2 | `build/MilBridge/W118A-report.md` | **新建**（`$R` → 克隆） | `77cd063b2234643e` | ＋431（新件） |
| 3 | `docs/ROUTES.md` | **修改（纯追加）** | `94bea50bd8bac16f` | `677 → 685`（**＋8／−0**） |

- **推前对账（机械证）**：`git status --porcelain` **恰好 3 行** —— ` M docs/ROUTES.md` ＋ `?? build/MilBridge/W118A-report.md` ＋ `?? build/MilBridge/W128A-report.md`；`git diff --cached --name-only | wc -l` = **3**；`git diff --cached --stat` = **`3 files changed, 791 insertions(+)`**（**0 deletions** —— 与 §③ 的"只追加"判据一致）；暂存后 `git status --porcelain | grep -v '^M \|^A '` **空**（无残余脏件）⇒ **多一件即停手**这一条**未触发**。
- **未 add 的件（如实点名，全部 `#53` 在办／波内派生）**：见 §④ 九行清单 —— `verify-all.sh`／`known-red.json`／`src/WpfGfx.Linux.Native/src/{win32_core.c,win32_internal.h,win32_x11.c}`／`build/wave-audit.log`／`build/MilBridge/arm-logs/tline.log`／`build/MilBridge/gen/t2d-family-{baseline,matrix}.txt`。

**head 变化（本件两笔；第 2 笔 —— 即本报告自身 —— 的推送后读数见文末 `§②-补`）**：

| 刻 | head | 读数来源 |
|---|---|---|
| **推前**（开工现场现取） | **`9241f9f82beb2b21a5e7b37cde064d8dd5a21ead`** | `git rev-parse HEAD` ＝ `origin/feat-Linux` ＝ `git ls-remote origin HEAD`（**三者一致**，与任务书给定**一致**） |
| **第 1 笔后** | **`4c3a513c48acb17ffd293e3df50efb8f8a2d81ff`** | `9241f9f..4c3a513  feat-Linux -> feat-Linux`（远端**接受**） |

- **push 后重新 `fetch` ＋ 与 `ls-remote` 交叉核**（**不是**取 push 前的 ref —— W107A 踩过"假 MISMATCH"）：`fetch` 后 `HEAD = origin/feat-Linux = ls-remote = 4c3a513c48acb17ffd293e3df50efb8f8a2d81ff` ⇒ **`THREE_WAY=CONSISTENT`**；`git ls-remote --symref origin HEAD` 逐字 = `ref: refs/heads/feat-Linux	HEAD` ⇒ **`symref` 仍 `feat-Linux`** ✅。
- **`BYTECHECK`（判据 = 远端 blob == 克隆工作树）**：

```
  ok       build/MilBridge/W128A-report.md 789d01e5f8959b0b
  ok       build/MilBridge/W118A-report.md 77cd063b2234643e
  ok       docs/ROUTES.md                 94bea50bd8bac16f
BYTECHECK ok=3 mismatch=0 nobody=0
```

- **`$R` 与远端逐件字节一致性**（本笔三件）：`sha256sum $R/<件>` 与 `sha256sum 克隆/<件>` **逐件 MATCH**（`789d01e5f8959b0b`／`77cd063b2234643e`／`94bea50bd8bac16f`）⇒ **`$R` ＝ 克隆 ＝ 远端 blob** 三方同值。

## §③ 两条记档逐字 ＋ `wc -l` 复核

### ③-1 远程 `DECLDRIFT=1`（唯一漂移项 `KRJ`）口径句 —— **落在新节 `§15q`**（文件末尾、`§15p` 之后；**未改任何既有行**）

- **落点判据（机械证）**：`grep -c '§15q'` 改前 **0** → 改后 **1**；`grep -c 'DECLDRIFT=1'` 改前 **1** → 改后 **2**（新增的正是本条）；`wc -l` **677 → 685**。
- **逐字（新增 bullet 原文，`§15q` 第 1 条）**：

> ⚠️ **远程此刻 `DECLDRIFT=1`，唯一漂移项 = `KRJ`**（`known-red.json`：`$R` 侧 = 车道 `#53` 的在办值 `f108775906eac9aa`，克隆/远端 = `d4e0080df6ec497c`）。**成因** = W130A 按"现场现取"重新生成声明表 ⇒ 锚跟了 `$R`。**裁定：保持现状、不为了"远程自洽"在本地重生成** —— 那会把**本地**读成 1、可能给 `#53` 的冻前 `verify-all` 添一处**非声明类红**；`#53` 推该件后**自愈**。**这不是"放宽判据"**，是"谁在动谁的锚"。（本条为**车道 WC01 记档**；同一事实的**当时读数**见上 §15p 末第二条，那行**一字未动**。）

- **该句的事实底座（现场现取，两法同值）**：`$R/build/MilBridge/known-red.json` sha16 = **`f108775906eac9aa`**（git blob sha1¹⁶ = `1cc8148eadcbe144`）；克隆/远端同一件 sha16 = **`d4e0080df6ec497c`**（git blob sha1¹⁶ = `db891239d05d4242`）⇒ 漂移项**只有 `KRJ` 这一格**。
- ⚠️ **不重生成声明表**：本批**不开新号** ⇒ **零 `--emit`**；`build/MilBridge/tools/defect-registry-declared.tsv` 改前改后 sha16 **同为 `c8d59c5b8dc36ef1`**（`$R` 与克隆两处同值）⇒ **一个字节未动**。
- ⚠️ **与既有 §15p 末第二条的关系**：那条是 **W130A 落册的"当时读数"**（原文**一字未动**）；本件在 `§15q` **追加记档**并在括注里**显式声明**这一取代/并列关系，**不删不改**任何历史行。

### ③-2 `TASK-0201` 上界读数更新 —— **落在 §14 清单 `TASK-0201` 行下**（**追加一行，原行一字未动**）

- **锚定说明（如实）**：全仓 `TASK-0201` **有两处**行 —— `docs/ROUTES.md:196`（**§13 树行**，`│   ├─ TASK-0201 [MVP] 🟡 …`）与 `:312`（**§14 清单行**，`- \`TASK-0201\` 🟡 …`）。**本件追加在 §14 清单行（`:312`）正下方**（改成 `  - ` 两级缩进子行，与册内既有"追加行"体例一致，见 `:290–:303`／`:337–:344` 的同形写法）；**§13 树行未动**（树形行内插子行会破坏 `│ ├─` 结构，且该行是**汇总位**、不是读数位）。
- **判据（机械证）**：`grep -c -x -F -- '- \`TASK-0201\` 🟡 静默 \`rc=139\`＋0 字节：15 趟零命中（上界≈20%）'` 改前 **1** → 改后 **1**（**原行逐字仍在、一字未改**）；`grep -c -F 'TASK-0201 [MVP] 🟡 静默'`（§13 树行）改前 **1** → 改后 **1**（**未动**）；新增行行号 = **`313`**。
- **逐字（新增行原文）**：

> `TASK-0201` 读数更新（W130A 批＋WC01 批）：该行的"上界"读数已被 `TASK-0203` 的终报取代 ⇒ 静默 SEGV 族 **`2/175 ⇒ 95% 单侧 3.55%`**（点估计 `1.14%`；与 W98A `1/60=1.7%` 同量级；同件同腿合并 `3/235 ⇒ 3.27%`；本装置全部 `2/236 ⇒ 2.64%`）；**产品侧仍红** ⇒ `D-G109`／`TASK-0209`。

### ③-3 `wc -l` 复核（**不许吞行**）

```
改前  wc -l docs/ROUTES.md  = 677     sha16 = caa09cbdd105e564
改后  wc -l docs/ROUTES.md  = 685     sha16 = 94bea50bd8bac16f
差 = +8 = (§14 追加子行 1) + (§15q 空行 1 + 节标题 1 + 空行 1 + bullet 4) = 1 + 7 ✓
```

- **逐行清点（`diff -u` 对照克隆里的旧版）**：`+` 非空行 **6** ＋ `+` 空行 **2** = **8**；`-` 非空行 **0**、`-` 空行 **0** ⇒ **纯追加**（`git diff --cached --stat` 亦为 `791 insertions(+)`、**0 deletions**）✅。

## §④ `$R ↔ 远端` 不同件清单（**应为 `#53` 在办件**）

**方法**：对克隆 `HEAD` 索引里 **15,266** 件逐件，用 git 内部表示 `sha1(b"blob <len>\0" + content)` 现算 `$R` 磁盘件的 **git blob sha1** 与远端 blob 逐件比（脚本 `~/wc01/compare-R-remote.py`；**推送后**跑的终值）。⚠️ 表中是 **git blob sha1¹⁶**（**不是** sha256）—— 两种哈希**不可混读**（`D-G104`"同一件两个值"教训：口径必须写死）。
⚠️ 另注：克隆 `HEAD` 里**没有**的件（= 只在 `$R` 存在的件）**不在此表**；`$R` 缺 7,366 件克隆 `HEAD` 件（`$R` 是**部分工作树**，`upstream/**`／多数 `tests/**`／根 `*.cmd` 等）⇒ **`MISS` 不是差异、是"`$R` 根本没这份"**，本表**不列** `MISS`。

**推送后 `DIFF_COUNT=9`**（推送前 = **10**，含本件的 `docs/ROUTES.md`；推送后该件已一致 ⇒ **减 1**）：

| # | 件 | 远端 blob | `$R` blob | `$R` 字节 | `$R` mtime | 归属 |
|---|---|---|---|---|---|---|
| 1 | `verify-all.sh` | `65e3466bf59d9de6` | `a58de2055f7aedde` | 95,096 | **12:10:02** | **`#53` 在办**（任务书点名） |
| 2 | `build/MilBridge/known-red.json` | `db891239d05d4242` | `1cc8148eadcbe144` | 70,468 | **12:48:50** | **`#53` 在办**（重钉产物；`KRJ` 漂移项本体） |
| 3 | `src/WpfGfx.Linux.Native/src/win32_core.c` | `28ce3e0e244042f4` | `9ed36275c15d0d50` | 125,693 | **11:49:23** | **`#53`**（W131A 在办 native 源） |
| 4 | `src/WpfGfx.Linux.Native/src/win32_internal.h` | `f29393081d71053f` | `bf0739233034bc1a` | 35,365 | **11:49:23** | **`#53`**（同上） |
| 5 | `src/WpfGfx.Linux.Native/src/win32_x11.c` | `823e617d71f13dca` | `60d4293cf336bb53` | 114,187 | **11:49:23** | **`#53`**（同上） |
| 6 | `build/wave-audit.log` | `cd0b6243952f538f` | `2d0457b55773821d` | 71,224 | **12:25:58** | `#53` **波内派生件**（非手工编辑） |
| 7 | `build/MilBridge/arm-logs/tline.log` | `f3bc7bba9944886c` | `db7cd819ba89f0cb` | 23,483 | **12:45:18** | `#53` **波内派生件** |
| 8 | `build/MilBridge/gen/t2d-family-baseline.txt` | `10994a2295493088` | `7ef13df94078ac67` | 486 | **12:43:17** | `#53` **波内派生件** |
| 9 | `build/MilBridge/gen/t2d-family-matrix.txt` | `64ea694947acc8af` | `8b15b49da3a677be` | 703 | **12:45:16** | `#53` **波内派生件** |

- **结论**：**9/9 全部归属 `#53` 的在办／波内活动**，**无一件来源不明** ⇒ `criteria.md` §7 的"停手条款"（"若差异件**不是** `#53` 在办件 ⇒ 停手报主控"）**未触发**；**未出现新的发布完整性事件**（`D-G108` 同族）。
- ⚠️ **归属的证据强度如实分级**：第 **1–5** 行 = **任务书点名 ＋ 任务书给定的 sha16 底座**（`#53` 在办件）⇒ **强**；第 **6–9** 行 = **推断**（依据 = ① mtime 全落在 `#53` 活动窗 `12:09:58–12:48:50` 内；② 现场有 `~/w133a/bin/verify-pre.sh`（经 `heavy-slot`）与 `verify-all.sh` **正在跑**；③ 四件都是波链**自动派生**的日志／生成件）—— 我**没有**它们的**写者署名**（无锁、无握手）⇒ **这 4 行的归属是推断、不是逐字证据**，如实标注。**边界**：本件**未 add** 这 9 件中任何一件（§② 已列）。
- **`$R ↔ 远端` 的"件数"有两个口径**（`D-G104`：两个值都给）：**① 差异件 = 9**（上表；推送后）／**② `$R` 缺件 = 7,366**（`$R` 的部分工作树性质，**不是差异**）。

## §⑤ `DEFREG` 两条机读行（**本地**，现场连跑两遍）

```
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=145 route_ids=145（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）   rc=0
```

- **两遍 `cmp` = IDENTICAL**、`rc=0/0`（日志 `~/wc01/defreg-1.txt`／`defreg-2.txt`）。
- **与改前一致**：本批**不开新号** ⇒ `declared=145 route_ids=145` **未变**（任务书给定的 `145` **现场复现**）；`DECLDRIFT=0`（**本地**口径 —— 与 §③-1 的"**远程**口径读到 1"**不是矛盾**，两者是**不同设备上的同一格**）。
- ⚠️ **未碰** `CS`／`HO`／`AB` 三个 route 文件；**未跑** `--emit`；冻结物现场复核 **未动**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` sha16 **`27293fb5ab91b778`**（`$R` 与克隆**同值**）、`docs/CURRENT-STATE.md:9` 仍 `gen=#52`（`$R` 与克隆同值、整件 sha16 `737c78e3a7e5a3a5`）。
- **`inputs_fp` 影响 = 零**（机械证）：`build/close-wave.sh` 的 `fp_inputs()` 全部 `find` 的 `-name` 模式集合现取 = **`patch-*.py`｜`port-lib.py`｜`integration-wave.sh`｜`close-wave.sh`｜`*.cs`｜`*.c`｜`*.h`**（另 `known-red.json` **只出现在注释里**、不是覆盖模式）⇒ **没有任何 `.md` 模式**，且覆盖根只有 `src/WpfGfx.Linux*`／`build`（`maxdepth 1` 生效）／`build/shims` ⇒ 本批三件（`docs/ROUTES.md`、`build/MilBridge/W128A-report.md`、`build/MilBridge/W118A-report.md`）**逐件 0 命中** ⇒ **本笔对 `inputs_fp` 零影响**（未运行波链、未计算 `inputs_fp` 值 ⇒ 该值本件 `NOINFO`，结论只依赖上面的模式集合）。

## §⑥ `NOINFO`／未做（如实）

1. **`#53` 波内派生 4 件（§④ 第 6–9 行）的写者归属 = 推断**，**`NOINFO` 级证据**（无署名／无锁／无握手）—— 只给了 mtime ＋ 活性窗口 ＋ 派生性质的间接依据。
2. **未跑任何牙的 `--selftest`**（本批是纯文本编辑 ＋ 推送；`DEFREG` 机读两遍已按交付要求跑，其余牙**一个都没跑**）。
3. **未计算 `inputs_fp` 现值**（要跑 `close-wave.sh` 外壳 ⇒ 属"跑门禁"，**本件不许**）⇒ §⑤ 的零影响结论**只由覆盖面模式集合推出**，不给指纹值（**不手抄、不推测**）。
4. ⚠️ **`$R` 的 `#53` 正在跑 `verify-all.sh`**（pid `800115`）—— 本件改 `docs/ROUTES.md`（`13:20:54`）时它**已在跑**（起动约 `13:20:29`）。**边界**：`docs/ROUTES.md` 是 `DEFREG` 牙的**被读件**；本件改动**只追加既有编号的读数、未新增任何 `D-G*` 声明号** ⇒ `DEFREG` 现场两遍 **PASS（`145/145`）**、**不应**给 `#53` 的冻前 `verify-all` 添红；但**我无法证明**它那一趟读的是我改前还是改后的字节（**该趟的内部时序 `NOINFO`**）—— 如实留痕，**本件不干预**（不动它、不读它的日志、不碰它的件）。
5. **两份报告里引用的 `~/w128a/**`／`~/w118a/**` 原始台账未复核**（只读域外，且**判词一字未动**）：本件的职责是**搬证据本体上远端**（此前远端没有这两份报告），**不重开它们的结论**。
6. **`W118A-report.md` 的权限位**：`$R` 原件是 `-rw-------`（600），转推时置 **644**（内容**逐字节相同**、sha256 不变）⇒ git 只记可执行位、**权限位不影响 blob**；此差异**如实留痕**，未改 `$R` 原件权限。
7. 未跑构建／门禁／应用；未占槽；**零 `pkill`／`killall`／`pgrep -f`**（`D-G103` 族纪律全程遵守 —— 本件一条都没用过）。

## §⑦ ≤5 行大白话小结

1. 两份证据报告（`W128A`＝抓静默 SEGV 的那份、`W118A`＝那 41 趟长跑那份）**此前只在本地 `$R`，远端没有**；本件先查占位符（**两件都 0 命中**，`grep` ＋ `python` 两法互证）再**推上去**了。
2. 顺手把两件事**追加**记进 `docs/ROUTES.md`：①远程那格 `DECLDRIFT=1` **只因为 `known-red.json` 是别家在办**，**故意不在本地重生成**（重生成会把本地读成 1、还可能给别家的冻前检查添红），等别家推了**自己就好了**；②老的 `TASK-0201` 那行"上界≈20%"已被终报的 **`2/175 ⇒ 3.55%`** 取代 —— **原行一个字没动**，新读数写在它正下方。
3. 推送**只有 3 件、全逐径 `git add`**（今天 `git add -A` 刚出过事故）：报告 2 件 ＋ `ROUTES.md`（`677→685` 行，**纯追加、0 删除**）。
4. head 从 `9241f9f8…` 到 **`4c3a513c…`**，`HEAD`／远端分支／`ls-remote` **三者一致**、`symref` 仍 `feat-Linux`，**`BYTECHECK ok=3 mismatch=0 nobody=0`**。
5. `$R` 与远端现在**差 9 件，全部是别家 `#53` 的在办件或它跑波生成的日志**（其中 4 件的归属只是**推断**、已如实标注）；冻结基线（`#52`）与本地 `DEFREG`（`145/145`、漂移 0）**都没动**。

---

## §②-补 推送后读数（**RECORD-补**；本笔 ＝ 第 **3** 笔，**仅本报告自身**）

**三笔总账**：

| 笔 | 件 | 件数 | head 前 → 后 | `BYTECHECK` |
|---|---|---|---|---|
| 第 1 笔 | `W128A-report.md`／`W118A-report.md`／`docs/ROUTES.md` | 3 | `9241f9f82beb2b21a5e7b37cde064d8dd5a21ead` → **`4c3a513c48acb17ffd293e3df50efb8f8a2d81ff`** | **`ok=3 mismatch=0 nobody=0`** |
| 第 2 笔 | `build/MilBridge/WC01-report.md`（本报告第 1 版） | 1 | `4c3a513c48acb17ffd293e3df50efb8f8a2d81ff` → **`6428396e1b43157796397a03da954dac784b8998`** | **`ok=1 mismatch=0 nobody=0`** |
| 第 3 笔（**本补笔**） | `build/MilBridge/WC01-report.md`（追加本节） | 1 | `6428396e1b43157796397a03da954dac784b8998` → **`NOINFO`**（见下"自指"条） | **`NOINFO`**（同因） |

- **第 1／2 笔的推送后复核（逐笔现场现取）**：两笔**各自**在 push **之后**重新 `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`，再与 `git ls-remote origin HEAD` **交叉核** ⇒ 两笔都 **`THREE_WAY=CONSISTENT`**（`HEAD` ＝ `origin/feat-Linux` ＝ `ls-remote`）；`git ls-remote --symref origin HEAD` 逐字 `ref: refs/heads/feat-Linux	HEAD` ⇒ **`symref` 仍 `feat-Linux`** ✅。
- **`BYTECHECK` 判据**（＝**远端 blob == 克隆工作树**）：第 1 笔 3 件逐件 `git cat-file blob HEAD:<件> | sha256sum` vs 克隆磁盘件 **全 MATCH**（`789d01e5f8959b0b`／`77cd063b2234643e`／`94bea50bd8bac16f`）；第 2 笔 1 件同法 **MATCH**（`0c50fe11d0be7892`）。两笔 `nobody=0`（无"远端没有该路径"的件）。
- **第 2 笔 blob 的可复核入口**：`git cat-file blob 6428396e1b43157796397a03da954dac784b8998:build/MilBridge/WC01-report.md | sha256sum | cut -c1-16` ⇒ 应得 **`0c50fe11d0be7892`**（＝第 2 笔推上去的那一版本报告）。
- ⚠️ **第 3 笔（本补笔）的 head 与 `BYTECHECK` = `NOINFO`，原因是"自指"、不是没做**：本补笔的提交**就是本文件所在的提交** ⇒ 把它的 head 写进本文件**在逻辑上不可能**（写完又要再提交，无穷后退）。**记账方式**：该 head 逐字落 **`~/wc01/STATUS.md`**（**仓外**、**无自指**）＋ 本件交付回复逐字给出；**未用任何推测值顶替**、**未手抄任何哈希**。⚠️ 同理，本节里"件数 = 1"这一格由 `git diff --cached --name-only` 的**推前**读数支撑（现取 = `1`）。
- **占位符门对本报告自身复跑（同一硬门，两法）**：`grep -n -F -e <三连尖括号> -e <双 at>` 命中 **0 行**；python `bytes.count()` 现算 **`U+003C`×3 = 0 ∧ `U+0040`×2 = 0** ⇒ **0/0 通过**（**第一版命中 3 行**的自伤已在 §① 如实留档、并已改写为描述式）。
- **本报告自 sha16 口径（消自指，逐字）**：本文件**末行**给出的值 = `head -n -1 <本件> | sha256sum | cut -c1-16`（即"**不含末行**的全文"的 sha16）—— 任何人可现场复算；⚠️ **本节的 sha16 不引用"含末行"的全文件值**（那会自指）。

本报告 sha16 = `3211add9fb90f37d`
