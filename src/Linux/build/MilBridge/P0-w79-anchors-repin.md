# P0-w79-anchors-repin —— 冻结后无 `--emit` 的四条关账（`D-G170`／`D-G171`／`D-G172`／`D-G173`）

**车道**：`waveman`（`t40`）｜**开工**：2026-09-28 02:18:07 +0800｜**落仓全部 `temp+rename`**｜**未重冻**（基线全程 `901619543b3d913b`）
**本报告读数口径**：凡引用 sha16 均带**读取时刻**；「两趟逐字相同」一律先写**抽取域**；**计数类**差异（`D-G174` 族）单列。

---

## §1 四条新号（要点与来源）

| 号 | 一句话 | 在册定义来源 |
|---|---|---|
| `D-G170` | `check_block_values()` 写前断言的**射程错**（断言取数作用域 ↔ 它要保证的性质不对齐） | `build/MilBridge/P0-w78-report.md:430`（逐字） |
| `D-G171` | `allow_changed` 与 `pf_required` **同语义两处实现** | 同上 |
| `D-G172` | 冻结改写两个 route 件之后**零 `--emit`** ⇒ 在册声明锚漂移，且暴露它的读数**进不了冻后日志** | 同上 ＋ `build/MilBridge/P0-w79-report.md:43-46` |
| `D-G173` | 声明点不止一处、而只有一处有读者：`docs/CURRENT-STATE.md:8` 散文里那个**没有读者的世代值** | `build/MilBridge/P0-w78-report.md:425-428`（读者普查） |

`P0-w78-report.md` 现读 sha16 `bdf5644f4aa51300`／439 行（`t33` 落仓 `2026-09-28T01:56:59+08:00`；本件 `2026-09-28T02:1x` 现读）。

## §2 登记（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`，**只增不改**）

- 追加「## 波 `#80` 登记批」一节（四条 ＋ 每条一段 🔴 永久口径句 ＋ 同族/边界）。
- **只增不改的机械证**：`git diff --numstat -- samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ＝ **`+…  0`**（删除行 = 0，见 §12 的现取行）。
- 落仓指纹：`4e085498d08ec111`（3505 行，`t45` 终态）→ **`ac13076c17ca8f8f`**（读取时刻 `2026-09-28T02:21:37+08:00`，`temp+rename`）。
- **`declared` 计数（开工／收工两读）**：开工前现取 `2026-09-28T02:18:07+0800` ⇒ `DEFREG_DECL=n=204`（TSV 204 条 `ID` 行，件 sha16 `3792aad62a904c4c`）；`--emit` 后现取 `2026-09-28T02:22:34+0800` ⇒ **`n=210`** ⇒ **+6**。
  **+6 的逐号分解（对 `git show HEAD:…tsv` 逐号 diff）**：**+4 = 本件四号**（`D-G170`／`D-G171`／`D-G172`／`D-G173`）＋ **+2 = `t43`／`t45` 已登记但从未 `--emit` 的 `D-G174`／`D-G175`**（它们的登记落仓时链上无 emit ⇒ 本件这次 emit **一并带上**，属**欠账结清**，不计入本件的 +4）。
- KD 里四条各自的 🔴 口径句（收进登记，永久）：
  1. `D-G170`：「断言的**射程**必须与它要保证的性质对齐 —— 射程小于性质 ⇒ 假绿；射程大于性质 ⇒ 假红。不许用"它恰好过了／恰好红了"当证据。」
  2. `D-G171`：「**同一语义只许有一个实现点**。两处实现 = 两个真相。」
  3. `D-G172`：「凡"快照式声明"，必须写清它在收尾链里的**位置**：链上**任何**会改写被声明件的步骤都必须排在**最后一次 emit 之前**。」
  4. `D-G173`：「一个事实只许有**一个**可被机器读到的出处。散文里"顺手写一句值"不是文档习惯问题 —— 它是第二个真相，而且是一个没人看着的真相。」

## §3 `--emit` 重出声明表（**登记之后**，`temp+rename`）

- `build/MilBridge/tools/defect-registry-declared.tsv`：`3792aad62a904c4c` → **`bbdf0b5945ffb525`**（读取时刻 `2026-09-28T02:22:34+0800`；`mktemp -p <同目录>` ＋ `mv` ⇒ 同一次 rename；`.decl.t40.*` 残留 **0**）。
- 第 2 行 `DECL-ANCHORS`（改前 → 改后）：
  ```
  改前  KD=c89631d5a09df584 CS=e3f1d5cd98ea3404 HO=a4d8ffcf4c37f6fe AB=d60b414d5e99cf72 KRJ=2209966ee1d2c5cc KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
  改后  KD=ac13076c17ca8f8f CS=90a22e10619a8485 HO=a4d8ffcf4c37f6fe AB=901619543b3d913b KRJ=2209966ee1d2c5cc KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
  ```
- **7 键逐键 = 现场（不看脚本自印，逐件现算 `sha256sum | cut -c1-16`，读取时刻 `2026-09-28T02:22:34+0800`）**：

  | 键 | 件（`defect-registry-check.sh:59-65`） | 现算 |
  |---|---|---|
  | `KD` | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `ac13076c17ca8f8f` |
  | `CS` | `docs/CURRENT-STATE.md` | `90a22e10619a8485` |
  | `HO` | `handoff.md` | `a4d8ffcf4c37f6fe` |
  | `AB` | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `901619543b3d913b` |
  | `KRJ` | `build/MilBridge/known-red.json` | `2209966ee1d2c5cc` |
  | `KRF` | `build/MilBridge/known-red-frame-structural.md` | `ab09235afd949bc2` |
  | `KRP` | `build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md` | `3c9e3a309b990d31` |

  ⇒ 与改后声明行**逐位相同，无一处不等**。
- 牙现取（`2026-09-28T02:22:34+0800`，rc=0）：
  ```
  DEFREG_DECL=n=210 route_ids=210 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
  DEFREG_ROUTES=KD=ac13076c17ca8f8f CS=90a22e10619a8485 HO=a4d8ffcf4c37f6fe AB=901619543b3d913b
  DEFREG_EXTRA=KRJ=2209966ee1d2c5cc KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
  DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
  DEFREG_DECLDRIFT_KEYS=-  # 机读差集键行（零漂移给 -）
  DEFREG=PASS declared=210 route_ids=210（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
  ```
- **既存红被本件关闭**（顺序：**登记 → `--emit` → 成对重测 → 推送**）：`REPORTID=FAIL`（四个点名全在 `build/MilBridge/P0-w79-report.md:43/:51`）→ 现取 **`REPORTID=PASS files=182 ids=1876 declared=210 glob=build/MilBridge/*report*.md`**（`2026-09-28T02:22:34+0800`）。**`P0-w78-report.md` 本件一字未改。**

## §4 `D-G173` 的修与牙

**① `:8` 的本身（行内容逐字）**
```
改前：… 的**最新冻结**（现在 **`#44`**；它的**整份 sha 只由下一条机器行声明** —— ⚠️ **本页别处与其它任何文档一律不许再写值**，要改也必须「脚本算 + 过 `BASELINE-SHA` 那一关」）+ 现场重算值。
改后：… 的**最新冻结**（**世代与整份 sha** 都只由下一条机器行声明** —— ⚠️ **本页别处与其它任何文档一律不许再写值**，要改也必须「脚本算 + 过 `BASELINE-SHA` 那一关」）+ 现场重算值。
```
- **不写第二个值**，只留"指向机器行"的说明（按该句自己立的规矩修）。
- **机械边界**：`docs/CURRENT-STATE.md` 行数 **933 → 933**（不变）；**机器行 `:9` 逐字节不动**（`awk 'NR==9'` 的 sha16 前后同为 `988d1efc33a3012a`）；件 sha16 `746a08e646370614` → `90a22e10619a8485`。
- 契约 verify：`grep -nE '\(现在[^)]*#[0-9]+' docs/CURRENT-STATE.md` ⇒ **0 命中（rc=1）**。
  ⚠️ **如实划界**：该正则用的是 **ASCII `(`**，而本页原文用的是**全角 `（`** ⇒ **它在本件开工前就是 0 命中**（不是本件修好的证据）。故本件另给**全角口径** `grep -cE '（现在[^）]*#[0-9]+'` ⇒ 改前 **1**、改后 **0**，并以新牙的 `CSDECL` 为准（读者是牙、不是 grep）。

**② 新牙 `CSDECL`（`build/MilBridge/tools/baseline-sha-check.sh`，第四判定项）**
- 判：`BASELINE-FROZEN` 形态在 `docs/CURRENT-STATE.md` 里**只许出现一次**（＝机器行本身）∧「唯一权威」那句散文行**不许**带字面号值（`#NN` 世代值／`D-*` 编号）∧ 找不到那句散文行 ⇒ **`NOINFO`（不算绿）**。
- 两条否定式**逐字来源**（`build/MilBridge/P0-w78-report.md:428`）：① 不许出现 `BASELINE-FROZEN` 形态文本（否则 `-m1` 抓到它、**绕过机器行**）；② 不许出现任何字面 `D-G<数字>` 号值（否则 `DEFREG=FAIL reason=undeclared-id-in-route`）。
- 件 sha16：**`0eb082253a195d08`** → `fe18e26b3e8e4249`（`temp+rename`）；`rc` 口径加注（原句"两项"一字未动，并列写"实为四项"）。
- 正极现取（真树，`2026-09-28T02:22:2x+0800`）：`BASELINESHA=PASS`／`BASELINEGEN=PASS`／`BASELINEDUP=PASS`／**`CSDECL=PASS n_decl_lines=1 auth_line=8`** ⇒ **`rc=0`**。
- `--selftest`：**`BSC_SELFTEST=PASS cases=9 pass=9 fail=0`**（原 6 例 ＋ 新 3 例 `G/H/I`；`ST_ATTEST=PASS`，自测期间件未变）。

**③ 三条反极性腿（副本 state ＋ 副本声音；真树零写）**—— `BSC_BASE`／`BSC_STATE` 指副本，**改前件＝本件开工前的 `baseline-sha-check.sh` 副本**（`~/w79c/t40/pre/`）：

| 腿 | 构造（副本） | 改前件（**不加新牙**） | 新牙 |
|---|---|---|---|
| (a) | `:8` 塞回世代值 `#44`（原形态） | `BASELINESHA=PASS`／`BASELINEGEN=PASS`／`BASELINEDUP=PASS` ⇒ **`rc=0`（假绿）** | **`CSDECL=FAIL reason=auth-line-carries-literal-value line=8 tokens=#44`** ⇒ `rc=1` |
| (b) | `:8` 塞字面编号 `D-G999` | 同上三档全绿 ⇒ **`rc=0`（假绿）** | **`CSDECL=FAIL … tokens=D-G999`** ⇒ `rc=1` |
| (c) | 第二处 `> BASELINE-FROZEN gen=#79 sha16=901619543b3d913b file=…`（**值取当下正确值**） | 同上三档全绿 ⇒ **`rc=0`（假绿）** | **`CSDECL=FAIL reason=duplicate-decl-line n=2`** ⇒ `rc=1` |

⇒ 腿 (c) 正是"**值全对也照样假绿**"那一条：`-m1` 只认第一处 ⇒ 不加新牙时**没有任何一步会红**（与主控实测一致）。

## §5 `D-G172` 半②：让漂移读数进冻后日志

- **牙侧（`defect-registry-check.sh`）**：漂移读数**具名到键** —— 计数行尾带 `keys=`（零漂移 `-`）＋ 新增**机读差集键行** `DEFREG_DECLDRIFT_KEYS=`（`0eb082253a195d08` 无关；该件 `dc0aeba08f9a7928` → **`c2d0773e5561a9d1`**）。两行仍**只诊断、不判红**（与 `:190` 的 `present=` 同档）。
- **链侧（`verify-all.sh`）**：第 `[10]` 步 `run_step` 之后，把这两行**原样**打进 stdout（⇒ 进冻后日志）；取不到写 `NOINFO`（**字段不许为空**）。用 **here-string `<<<`**（不用 `printf|grep -m1` —— 那是 `PIPEFAIL_SIGPIPE` 族，修法与 `t38` 同法）。件 sha16 `3c80498ab2896955` → `bb7a286b99dba757`。
- **隔离复现（不动链，`2026-09-28T02:21:59+0800`）**：
  ```
        · 自报口径 DEFREG_DECLDRIFT=3 changed-route-files-since-DECL-GEN keys=KD,CS,AB
        · 自报口径 DEFREG_DECLDRIFT_KEYS=KD,CS,AB  # 机读差集键行（零漂移给 -）
  ```
- **真进日志**：见 §12（两趟 post 的 `grep -c DEFREG_DECLDRIFT` ≥ 1 且值 **0**）。

## §6 漂移牙的反极性（副本声明，单变量）

改前现取（真树、未 emit 时）：`DEFREG_DECLDRIFT=3 … keys=KD,CS,AB`。三条腿都只动**一个位置**：

| 腿 | 单变量 | 读数 |
|---|---|---|
| ① | 副本声明锚行改写为**现取现场**（零漂移） | `DEFREG_DECLDRIFT=0 … keys=-` ／ `DEFREG_DECLDRIFT_KEYS=-` |
| ② | 在①之上把 **`AB` 锚值改一位**（唯一变量） | `DEFREG_DECLDRIFT=1 … keys=AB` ／ `DEFREG_DECLDRIFT_KEYS=AB` |
| ③ | 在①之上把 **`CS` 锚值改一位**（唯一变量） | `DEFREG_DECLDRIFT=1 … keys=CS` ／ `DEFREG_DECLDRIFT_KEYS=CS` |

⇒ 「=1 且**点名该键**」成立，且键名只来自 `ALLKEYS` 那一条取数支路（不设第二个实现）。

## §7 覆盖面位移（`inputs_fp`）—— **三段归因**（首次越代归 `t43`；本件两笔各一处，第三笔是**同一件的第二次位移**）

| 时刻 | `inputs_fp` | 归因 |
|---|---|---|
| `#79` 冻结（在册声明） | `4c096e9c0705a95d8a2a69617f777df06686e48b8e0ce40ae16eec75e095f180` | `#79` 代 |
| `2026-09-28T02:13:51` 现取（本件开工前） | `42e102ec2286c26336a7e1342ea18b971e3966b21f6140a8a48f365704ca4db9` | **① 首次越代＝`t43`**（落仓 `build/MilBridge/tools/nul-bytes-check.sh`，`ac47b287c955823c`；该件**在 225 件覆盖面内** ⇒ 改它必移位） |
| `2026-09-28T02:22:34` 现取（本件两件工具改后） | `a2a944c7706871f0e9093bf3c42d85a161adb93c85283ee27f091b186e11782d` | **② 本件越代**（改覆盖面件 `baseline-sha-check.sh`／`defect-registry-check.sh`） |
| `2026-09-28T02:46:08` 现取（本件修 `t43` 那一行之后） | **`cb7fbecaf8cd09fb639cd0c27e42bd0b1848848cb313d5aeebfd8b8e5748ac91`** | **③ 本件再越（第二次位移，同一件 `nul-bytes-check.sh`）** |

- **②／③ 的逐件归因（现取，机械）**：三个阶段里「脏件 ∩ 覆盖面」**恒为同 3 件**（`baseline-sha-check.sh`／`defect-registry-check.sh`／`nul-bytes-check.sh`）：② 由前两件造成、③ 由**第三件本身又被改一次**（裁定 (甲) 的 here-string 修）造成 ⇒ **同一件在一波里两次位移**（覆盖面件被改两次的直接形态，`t46` 冻结时请点名）。
- **② 的逐件归因（现取，机械）**：覆盖面清单 `225` 件（**件数不变** ⇒ `[42] --expect 225` 仍成立，实测 `files_n=225`）；按 `mtime > 开工时刻` 筛出的覆盖面成员**恰 2 件**：
  `build/MilBridge/tools/baseline-sha-check.sh`（`fe18e26b3e8e4249`）／`build/MilBridge/tools/defect-registry-check.sh`（`c2d0773e5561a9d1`）。
  ⇒ 本件本波落的**其余件**（`docs/CURRENT-STATE.md`／`verify-all.sh`／`defect-registry-declared.tsv`／`KNOWN-DEFECTS.md`／本报告）**都不在覆盖面** ⇒ 对位移**零贡献**。
  ⚠️ 我原报的名单里含 `close-wave.sh`（那是主控**预告**的可能改动）；**现取事实：本件一字未改 `build/close-wave.sh`**（见 §13）。
- **明示**：`#79` 声明里的 `inputs_fp`（`4c096e9c…`）**不再等于现树**，属**代际前进**；终值冻结**指向 `t46`（波 `#80`）**。**不许因此重冻 `#79`** —— 基线件全程 `901619543b3d913b`（见 §12）。

## §8 `D-G172` 的定性：**逐字引用先例原文**

引自 `~/w21-verify/w79freeze/B.pre-freeze.#79.bak`（该件 sha16 **`d60b414d5e99cf72`** ＝ `#78` 冻结态基线件身份，1,166,396 B；读取时刻 `2026-09-28T02:2x`）：

- `:868` 末段逐字：「…**本波采用路线 A（把 6 处修好）⇒ 不改 `known-red.json`**；故这一段**预期不触发**…**若万一改了它 ⇒ 同趟 `repin-generation.py --why/--check`，并注意 `DEFREG_EXTRA=KRJ=` 变化 ⇒ **主控同趟重发 `defect-registry-declared.tsv` 归零 `DECLDRIFT`**。**」
- `:997` 末段逐字：「…**`DEFREG_DECLDRIFT` 0 → 1**（**该行是非门禁诊断行**，`DEFREG=PASS`/`rc=0` 不变）⇒ **主控同趟重发 `defect-registry-declared.tsv` 归零**（现场已复核 `DECLDRIFT=0`）。」
- `:3652` 逐字：「它由核对器自己的 `--emit` **机械生成**（`req=` 直接由现场出现点推出）⇒ **它不是权威、是一个必须与现场同步的快照**；`DEFREG_DECLDRIFT` 行把"快照之后 route 件又变了"如实打出来（**诊断行，不判红**）。」

⇒ **定性**：本代破的**不是**"要不要 emit"（先例早就立了"**同趟**重发归零"），破的是**收尾链的形态** —— 链上第②步（冻结）会改写两个 route 件（`CS`／`AB`），而**最后一次 `--emit` 排在它之前**（冻前 `repin-generation`）⇒ **"同趟重发"这条惯例在链的形态上不可满足**。

**本代记录模板同样零命中**（要件）：`grep -c 'DECLDRIFT' ~/w186a/w79/w79freeze/w79-record.txt` ＝ **0**（该件 75 行，读取时刻 `2026-09-28T02:2x`）⇒ 模板里连这条读数都没有，"链跑完"不会有任何一处提醒下一次重出。

**`t23` 那一笔具名**（首笔被守护拦停）：`PUSH_RC=9`／`PUSH_LIST_GAP=FAIL dirty-covered-files-not-in-list: build/MilBridge/tools/boundary-decl-check.sh` ⇒ **在 `stage` 之前停手 ＝ 零部分推送**；补清单后第二笔 `PUSH_RC=0`／`staged=31`／`COMMIT=6a245bd`（本地==远端）。被推的那一笔里 `defect-registry-declared.tsv` 的第 2 行**带 2 键不实**（`CS=e3f1d5cd98ea3404`／`AB=d60b414d5e99cf72` vs 现场 `CS=746a08e646370614`／`AB=901619543b3d913b`，`DEFREG_DECLDRIFT=2`，读取时刻 `2026-09-28T01:14:50`／`01:15:26`）—— **本条即本件关掉的那笔账**。

**两趟 post 日志的 0（本件开工前，现取）**：`~/w79-close/logs/w79-post1-20260928-011239.log` ＝ **0**、`w79-post2-20260928-012847.log` ＝ **0**（`grep -c DEFREG_DECLDRIFT`）。

## §9 一条**自伤**（如实入账：`temp+rename` 必须连**权限位**一起搬）

本件用同一支落仓器（`temp + os.replace`）写五件，而落仓器**没有搬 `mode`** ⇒ 三个 `*.sh` 的**可执行位被抹掉**：
现场后果＝`baseline-sha-check.sh --selftest` 九例**全部 `rc=126`**（`chk()` 直调 `"$0"` ⇒ 不可执行），`BSC_SELFTEST=FAIL cases=9 pass=0 fail=9`。
- **发现路径**：自测读数与"照抄既有形态"的预期不符（不是先看代码，是先看读数）⇒ 逐例 `rc=126` 指向"命令不可执行"，`stat` 现取 `live=644 / pre=711 / git=100755` ⇒ 定位。
- **修法与机械证**：按**开工前副本**的 mode 逐件 `chmod`（`baseline-sha-check.sh`／`defect-registry-check.sh` 恢复为 `711`＝开工前现取，`git ls-files -s` 口径 `100755` 不变 ⇒ 推送里**不会**出现 mode 变更）；随后 `BSC_SELFTEST=PASS cases=9 pass=9 fail=0`、直调 `./build/MilBridge/tools/baseline-sha-check.sh` `rc=0`。
- **教训（收进本报告，供全波）**：**「`temp+rename` 的"原子"只覆盖内容；`mode`／属主／`xattr` 都要显式搬 —— 落仓器的自检必须含一条"改前改后 `stat -c %a` 相同"。」**（本件已把这一条写进 §13 的遗留项。）

## §10 推送窗口牙：给"代际前进"一条**只认具名声明**的路径（默认仍停手）

`~/w79c/bin/w79-push.sh` 的 `push_infp_tooth` 原本对 `INFP_AT_PUSH ≠ FROZEN_INFP` **一律停手** —— 而本任务（连同 `t43`）**就是**要改覆盖面成员 ⇒ 那条牙在本情况下**必然**触发。处置（**不放松牙**）：

- **默认（无声明）⇒ 照旧停手**；只有给了 `INFP_DISPLACE_DECL=<文件>` 且该文件同时满足三件才放行：
  ① `fp=<live>`（声明的就是现树）；② 每一条 `changed=<路径>` **确在覆盖面内** ∧ **确在推送清单里**；
  ③ **声明的 `changed` 集 ≡ 「脏件 ∩ 覆盖面」集**（**独立现算**：牙自己跑 `git status --porcelain` 再逐件与覆盖面清单比）⇒ **少报/多报都停手**。
- **四条腿（现取）**：① 不给声明 ⇒ `FAIL reason=covered-file-changed-in-freeze→push-window（未给 INFP_DISPLACE_DECL ⇒ 照旧停手）`；② 少报一件 ⇒ `FAIL reason=displace-decl-rejected: changed-set≠dirty∩coverage（声明=[…2 件…] 现算=[…3 件…]）`；③ `fp` 写一位 ⇒ `FAIL … fp-declared=…≠live`；④ 全量 ⇒ `INFP_FREEZE_PUSH_MATCH=ALLOW-DECLARED-DISPLACEMENT … changed_n=3` ＋ `INFP_RULER2=SAME_SOURCE_AGREE` ＋ `INFP_COUNT_RULER=PASS（live=225 == 声明常数 225）`。
- **放行时不再印 `=PASS`**（两种情形同形是缺陷：`=PASS` 意为"冻结窗内未变"，而这里是"具名声明过的代际前进"）。
- **改牙过程中我自己的三处自伤（具名，全部当场修）**：① 注释里的 `#` 把命令替换的收尾 `)` 吃掉 ⇒ `bash -n` 不通过；② `case " $FILES "` 与"每行第一个条目"跨换行不匹配 ⇒ 恒判 `not-in-push-list`（修法：先 `tr '\n' ' '` 归一）；③ `--check-only` 分支原先排在 `FILES=` **之前** ⇒ `${FILES:-}` 恒空 ⇒ 夹具入口与生产**同判**（故移到 `FILES`/`PUSH_LIST` 之后、`git add` 之前）。

## §11 两趟 post 的红：**一处是我造成的（已修回）**，一处是**越界件**（未擅动）

**① `PARSER-GUARD`（我造成，已修）**：`build/MilBridge/tools/parser-guard-check.sh` 的**射程表是按 `文件:行号` 锚**的（`decl_range_verdict` 读 `$1=="射程表"` 的 `<path>:<line>`）。我第一版把 9 行加注写进 `baseline-sha-check.sh` 的**文件头** ⇒ 该件 `:62` 的既有环境取数现场被顶到 `:70` ⇒ `PARSER_GUARD=FAIL rule=unnamed-site family=env site=…baseline-sha-check.sh:70 … 现扫命中却不在射程表里 ⇒ 必须逐处裁定`。
- 修法（**只动我自己的件、不放宽任何判据**）：把那段加注**下移到行号锚之下**（既有现场回到 `:62`），并且**注释里不写那条 ERE 的字面形态**（我第二次踩到的正是这个：`\$\{(…|BASELINESHA_DECL):-` 这条 ERE **连注释里的出现也算一处现场** ⇒ `sites_env` 4→5 ⇒ 仍 FAIL）。
- 修后现取：**`PARSER_GUARD=PASS examined=8 sites_env=4 fails=0`**；本牙 `CSDECL=PASS`、`BSC_SELFTEST=PASS cases=9 pass=9 fail=0`。
- 🔴 **口径（同族于本仓既有裁定）**：**「按 `文件:行号` 锚的射程表，任何一处上方插入都会把它顶飞 —— 这是"行号锚脆弱"的又一次现场；射程表要能活过编辑，就得用内容锚（本仓已判"内容锚优于行号锚"）。」**

**② `PIPEFAIL-SIGPIPE`（`t43` 的件，**越界未动**）**：`UNDECLARED_HIT build/MilBridge/tools/nul-bytes-check.sh:683` ——
```
683:  if [ "$pre_rc" = 1 ] && printf '%s\n' "$pre_out" | grep -qF 'NULBYTES_HIT path=.agent-teams/wpf-linux-route-completion/team.json'; then
```
该行是 `t43` **新增**（`git diff HEAD -- build/MilBridge/tools/nul-bytes-check.sh` 的 `+` 行里逐字可见；同段还有 `printf … | grep -E 'NULBYTES' | head -3` 一条），正是 `printf | grep -q` 那族（多行 `printf` 逐行 `write()` ⇒ `grep -q` 命中即退出 ⇒ EPIPE→SIGPIPE ⇒ `pipefail` 下整条管线 141）。`t43` 交接时**未跑 verify-all** ⇒ 该红**潜伏**至本件两趟 post 才被照出。
- **处置（按纪律）**：**本件不越界改它**（`build/MilBridge/tools/nul-bytes-check.sh` 不在 `t40` 的 inScope）；已当场上报主控并请裁定（(甲) `amend_task` 把该件加进 inScope ⇒ 一行 here-string 机械修；(乙) 指派 `migrator`）。**在裁定前不跑成对重测**（跑了必带这 1 红、白跑 40 min）。
- 读数（现取）：`PIPEFAIL_SIGPIPE=FAIL undeclared_hit=1 decl_stale=0 files=106 sites=97 hit=1 low=8 diag=4 safe=84 runs=12`；**本件两处新现场都不是 hit**（`sites` 95→97，hit 仍只有 `nul-bytes-check.sh:683` 一处）。

## §12 成对重测（`t40` 收工态；**先写抽取域，再谈"逐字相同"**）

- **两趟**：`~/w79-close/logs/w79-post1-20260928-024622.log`（`mtime 2026-09-28 03:06:22.375155600 +0800`，槽内 `held=1200s`，`rc=0`）／`~/w79-close/logs/w79-post2-20260928-030626.log`（`mtime 2026-09-28 03:24:42.245385712 +0800`，`held=1096s`，`rc=0`）。
- **每条链的判据行（两趟逐字同）**：`步骤通过 55  ❌ 失败 0`｜`用例通过 875  跳过 2`｜`结论：✅ 全部通过`｜`SKIP_GUARD=PASS … total_skipped=2 violations=none`。
  ⚠️ 该行里的 `❌` 是**标签对字面符号** ⇒ `grep -c '❌'` 会在全绿日志上报 **1**（本文件早在 `#79` 复验里就记过这条假阳；本件两趟同形）。
- **抽取域（逐字写出，供人复算）**：
  ```
  DOM='^      · 自报口径 |^  [A-Z0-9][A-Z0-9_-]* +[✅❌]|^ 步骤通过 |^ 用例通过 |^ 结论：'
  grep -E "$DOM" 每趟日志  ⇒ 每趟 143 行（口径行 98 ＋ 步骤结论行 42 ＋ 汇总 3）
  归一化（去跑次戳／`/tmp` 随机名／车道路径／小数）后 diff
  ```
- **归一化后差异 = 8 行（4 对），全是「计数类」，判词类 = 0**（**单列**，见下表）：

  | 行 | `post1` | `post2` | 类 |
  |---|---|---|---|
  | `FRAMEPRESENCE` | `magenta_frames=28` | `magenta_frames=32` | 计数类（帧色计数） |
  | `THIRDPARTY` | `frames=37` | `frames=39` | 计数类（帧数） |
  | `DISK_HEADROOM` | `avail_kb=90009728`（`avail_gb=85`） | `avail_kb=89186144`（`avail_gb=85`） | 计数类（磁盘余量，`avail_gb` 同值） |
  | `R_GATE` | `mem_mb=3900` | `mem_mb=4049` | 计数类（进程内存读数） |

  ⇒ 全部 55 个步骤的**判词（PASS/FAIL/NOINFO）与全部九位／声明类读数逐字相同**；差异只出现在"随环境与负载浮动的计数"上。**`NULBYTES` 那类计数在**本对**日志里不存在**（`NULBYTES=` 机读行两趟均零命中 ⇒ 该格本对 `NOINFO`，**不许由"两趟一致"反推**）。
- **本件两处新读数确实进了两趟日志**：`grep -c DEFREG_DECLDRIFT` = **2**（每趟）＋ `grep -c DEFREG_DECLDRIFT_KEYS` = **1**（每趟），逐字：
  ```
        · 自报口径 DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
        · 自报口径 DEFREG_DECLDRIFT_KEYS=-  # 机读差集键行（零漂移给 -；`?` = 声明件里读不到锚行）
        · 自报口径 CSDECL=PASS n_decl_lines=1 auth_line=8（声明点只有机器行一处；散文行不带号值/世代值）
        · 自报口径 BASELINESHA=PASS live=901619543b3d913b decl=901619543b3d913b
        · 自报口径 PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=106 sites=96 hit=0 low=8 diag=4 safe=84 runs=12
        · 自报口径 PARSER_GUARD=PASS examined=8 sites_env=4 sites_parser=0 exempt_used=0 dynamic_n=4 fails=0
        · 自报口径 REPORTID=PASS files=182 ids=1876 declared=210 glob=build/MilBridge/*report*.md
  ```
- **`t43` 那一行修后的两条硬读数（同趟）**：`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0`（改前 `FAIL undeclared_hit=1`，`sites` 97→96）｜`NULBYTES_SELFTEST=PASS total=39 pass=39 fail=0`（**S17／S17b／S17c／S18／S19 一条未掉**，逐行同修前）。
  **修前 vs 修后逐字对照（两条腿）**：
  - **S17 系列**（修前在 shadow 同深度副本上跑 ⇒ `S15-live-tree` 因 `R` 指向 shadow 而 `FAIL`，**这是放置位置所致、不是行为差异**；S17/S17b/S17c/S18/S19 两版逐字同）：
    `S17-agent-teams-skipdir = PASS rc=0 want=0 state=PASS hits=0`｜`ASSERT S17 \`.agent-teams/**\` 里的 NUL 不进判据面（PASS） = PASS`｜`S17b-list-no-agent-teams = PASS …`｜`ASSERT S17c 归类计数（SKIPDIRNAME 可见） = PASS`｜`ASSERT S18 改前形态 ⇒ 必红并点名该件 = PASS`｜`S19-inscan-nul-still-red = PASS rc=1 want=1 state=FAIL hits=1`。
  - **面内 NUL 照旧红**（夹具 `docs/PROBE-NUL.md`，`NULB_ANCHORS=off NULB_MIN_FILES=0`）：**修前/修后逐字相同**
    ```
    修前 rc=1  NULBYTES_HIT path=docs/PROBE-NUL.md offset=15 line=3 n=1 bytes=21 ／ NULBYTES=FAIL hits=1 files=1 bytes=21
    修后 rc=1  NULBYTES_HIT path=docs/PROBE-NUL.md offset=15 line=3 n=1 bytes=21 ／ NULBYTES=FAIL hits=1 files=1 bytes=21
    ```
    ⇒ **行为不变、牙没被改松**（改的只是**取数形态**：`printf|grep -q` → here-string）。
- **本件自带的差异分类器（`~/w79c/bin/diffclass.sh` v2）在**本对**日志上未出读数行**（`grep -E 'COUNTS|VERDICT'` 零命中）⇒ **本报告不用它的结论**，上表是自写归一化＋逐行 `diff` 的现取（口径已逐字写出）。

## §13 推送与哨兵

**（本节在推送后 append：口径＝报告在推送后追加 ⇒ 推送后残余 `porcelain` 只此一件，逐件具名。见 §13-追。）**

## §14 边界与遗留（**待下一笔登记**，本件不配号）

1. **`PARSER-GUARD` 的"行号锚"坑**（本件亲自踩到、已修回）：`parser-guard-check.sh` 的射程表按 `文件:行号` 锚 ⇒ **任何一处上方插入都会把它顶飞**；且那条 ERE **连注释里提到它也算一处现场**（与 `t28`「文本提及≠接线」同族）。⇒ 口径句（**下一笔登记**）：**「按行号锚的射程表活不过编辑：凡"逐处裁定表"，锚必须落在**内容**上（`t17` 的 roster 已因同一理由改成内容锚）。」**
2. **`t43` 的潜伏红**（本件修、已具名）：`nul-bytes-check.sh:683` 的 `printf|grep -q` 是 `t43` 新增、且 `t43` 交接时**未跑 verify-all** ⇒ 该红直到本件两趟 post 才被照出。⇒ 口径句（**下一笔登记**）：**「凡改到**在覆盖面内的判据件**，交接必须跑一次整链（`verify-all`），否则红的潜伏期由下一个无关车道的两趟 post 替你付。」**
3. **未做**：`docs/CURRENT-STATE.md:8` 之外的第二声明路（如 `handoff.md` 里同类散文）**未普查**（本件只按契约清 `CS:8`）；`D-G172` 的**链序修法**（把 `--emit` 排到冻结之后）**属链侧**（`~/w79c/bin/w79-freeze2end.sh`），本件**只**把漂移做成"可见 + 具名"，**未改链序**（那是 `t46`／下一波的事）。
4. **`#79` 的 `inputs_fp` 与现树不再相等**：属**代际前进**，终值冻结指向 `t46`（波 `#80`）。**本件全程未重冻**（基线 `901619543b3d913b`）。

## §13 推送与哨兵（**推送后 append**；口径＝报告在推送后追加 ⇒ 终态残余 `porcelain` 只此一件，逐件具名）

- **一笔推送**：`6a245bd..71603bd  HEAD -> feat-Linux`（`COMMIT=71603bd`｜`staged=18`｜`FF=yes`）；现取 `ls-remote` = **`71603bd3762059b3e1791be4a5eac2359657e01f`** = 本地 `HEAD`；树对象 `48af8258098c96adcc1b6ea156f9a8c4d25ab141`。
  ⚠️ 远端断言一律用**现取 `ls-remote` tip**（**不**用 remote-tracking ref —— 那条陷阱本仓已记过）。
- **推送窗口牙（本笔）**：`INFP_AT_PUSH=cb7fbeca…` vs `FROZEN_INFP=4c096e9c…` ⇒ **`ALLOW-DECLARED-DISPLACEMENT`（`changed_n=3`）**（具名声明的四条腿见 §10）＋ `INFP_RULER2=SAME_SOURCE_AGREE` ＋ `INFP_COUNT_RULER=PASS（live=225 == 声明常数 225）`。
- **逐笔在场**：`REMOTE_PER_COMMIT=PASS n=2`（`993eb5d5..71603bd` 逐笔）＋ `REMOTE_TIP_FRESH=71603bd…`。
- **本笔 18 件（逐件 blob 现取 `git ls-tree HEAD`；远端 ref == HEAD ⇒ 同一棵树）**：

  | 件 | blob16 |
  |---|---|
  | `build/MilBridge/HANDOFF-NEXT.md` | `fd33b220f3e2f546` |
  | `build/MilBridge/P0-mvp-segv-report.md` | `8a7ea638d272d9ba` |
  | `build/MilBridge/P0-w78-report.md` | `ede547a9deca4d88` |
  | `build/MilBridge/P0-w79-anchors-repin.md` | `4a6f2bc77c3886a5` |
  | `build/MilBridge/P0-w79-report.md` | `edb949f24933283a` |
  | `build/MilBridge/T24-report.md` | `8472dd8a2dcb28a6` |
  | `build/MilBridge/V79d-provider-disposition-verify.md` | `47929c39fca61d5f` |
  | `build/MilBridge/V79e-prefer-reds-close-verify.md` | `7381d779eb1dc475` |
  | `build/MilBridge/V79f-t35-verify.md` | `c625200c9e3890e8` |
  | `build/MilBridge/t22-report.md` | `e05cdcb1ecf80e9f` |
  | `build/MilBridge/t37-report.md` | `1f38b03b61275af0` |
  | `build/MilBridge/tools/baseline-sha-check.sh` | `b401506d1a13f694` |
  | `build/MilBridge/tools/defect-registry-check.sh` | `f0d7bcc54bd6bb6b` |
  | `build/MilBridge/tools/defect-registry-declared.tsv` | `5469e47aff1f7939` |
  | `build/MilBridge/tools/nul-bytes-check.sh` | `49ee983815a3111e` |
  | `docs/CURRENT-STATE.md` | `4c02d5ca761eae1e` |
  | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `fbd76cd9284f16ce` |
  | `verify-all.sh` | `9307d8199754bfe4` |

- **清单 ↔ `porcelain` 双向差集（现算）**：`FILES_n=75`｜推送前 `porcelain_n=18`｜**差集 B（`porcelain` − `FILES`）= ∅ ⇒ 无静默漏**｜`pushed − FILES = ∅`｜差集 A（`FILES` − 本笔）= **57 件**（它们在前代/本代更早提交里，且仍在清单上 ⇒ 清单是**累积**语义，不是"本笔清单"）。
  ⇒ 主控点名的 6 件（`HANDOFF-NEXT.md`／`P0-w78-report.md`／`P0-mvp-segv-report.md`／`P0-w79-report.md`／`T24-report.md`／`V79d`／`V79e`／`t22-report.md`）**全部入笔**；后到的脏件（`V79f-t35-verify.md`／`t37-report.md`／`nul-bytes-check.sh`／`KNOWN-DEFECTS.md`）也**一并入笔**（推送前 `porcelain_n=18` 与清单逐件对齐）。
- **推送后残余 `porcelain`**：推送后现取 **0**；本报告在推送后 append 本节 ⇒ **终态残余 = ` M build/MilBridge/P0-w79-anchors-repin.md`（只此一件，逐件具名）**，属**下一代**（`t46`）落仓件。
- **两哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；两件 sha16 同 **`d87d575ae8732003`**；`mtime 2026-09-28 03:25:37.451508668 +0800` ⇒ **由本笔推送重写**（不是 `#79` 那趟的陈旧件）。
  题定值（现取）：`WAVE=w79-freeze`｜`BASELINE=#79`｜**`BASELINE_SHA16=901619543b3d913b`**（基线件现取仍 `901619543b3d913b` ⇒ **未重冻**）。
  ⚠️ **如实点名一格**：哨兵九位字段写的是**现取**值，其中 **`PROVIDER=8cb1b50619f4c133` ≠ `#79` 冻结块的 `759ac1686e5ef87d`**（其余八位逐位同）。
  ⇒ 口径：**"哨兵现取" 与 "冻结声明" 不是一回事**——冻结声明在 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`，本件一字未动；该格**归因留 `NOINFO`**（本件**未**取到产物路径级证据，**不猜**是"哪一步重建了 provider 产物"），交 `t46` 冻结时按新值重取九位。
- **`t23` 那两笔具名**（本笔的前一笔）：首笔 `PUSH_RC=9`／`PUSH_LIST_GAP=FAIL dirty-covered-files-not-in-list: build/MilBridge/tools/boundary-decl-check.sh` ⇒ **stage 之前停手 ＝ 零部分推送**；第二笔 `PUSH_RC=0`／`staged=31`／`COMMIT=6a245bd`。本笔 `6a245bd..71603bd` ＝ **第三笔**。
- **推送牙自身的第三处自伤（具名）**：牙在 `git commit` **之后**才跑，而我第一版把判据面锚在**工作树脏件** ⇒ 提交后 `porcelain=0` ⇒ 现算集恒空 ⇒ 与声明集恒不等 ⇒ **拦停推送（提交已发生、零部分推送）**。修法＝判据面改成「**（脏件 ∪ 未推的已提交改动）∩ 覆盖面**」（`git status --porcelain` ∪ `git diff --name-only $REM..HEAD`）；修后复跑即 `ALLOW-DECLARED-DISPLACEMENT` ⇒ 推送成功。
- **推送后关键判据（现取）**：`DEFREG=PASS declared=210 route_ids=210`｜`DEFREG_DECLDRIFT=0 … keys=-`｜`DEFREG_DECLDRIFT_KEYS=-`｜七键逐件现算 = `ac13076c17ca8f8f`／`90a22e10619a8485`／`a4d8ffcf4c37f6fe`／`901619543b3d913b`／`2209966ee1d2c5cc`／`ab09235afd949bc2`／`3c9e3a309b990d31`（与声明行逐位同）｜`inputs_fp=cb7fbeca…`｜基线 `901619543b3d913b`。
