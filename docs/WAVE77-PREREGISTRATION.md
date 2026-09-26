# 波 `#77` 预登记（**四件合波**）—— `TASK-0740` ＋ `TASK-0742` ＋ `TASK-0744` ＋ `TASK-0745`

> 本件是**落地件**（落仓后为 `$R/docs/WAVE77-PREREGISTRATION.md`，标题行含 `#77` ⇒
> `verify-all-step-check.sh` 与本仓预登记批次门禁 `--glob 'docs/WAVE*-PREREGISTRATION.md'` 都能看到它）。
> 本波 = **仪器波 · 零产品改动**：只加三颗**判据牙** ＋ 一份**冻结器补丁**（仓外，主控写域）。

## §1 本波要交什么（逐条可判否）

1. **`TASK-0740`** —— 新牙 `build/MilBridge/tools/wiring-coverage-check.sh`（新步 `WIRING-COVERAGE`）：
   判「**接线件集合 ⊆ 覆盖面集合**」。判否：接线集里**任一件**不在 `fp_inputs()` 活清单里 ⇒ 非零。
2. **`TASK-0742`** —— 新牙 `build/MilBridge/tools/parser-guard-check.sh` ＋ 其**唯一机读声明**
   `build/MilBridge/tools/parser-guard-decl.txt`（新步 `PARSER-GUARD`）：判「**解析器不许把
   『解析不出』静默中性化** ∧ **继承环境的取数器必须校验并逐字打印**」。判否：射程内出现
   **危害形态**且无成文豁免 ⇒ 非零；守卫**拒合法值**或**畸形值不被拒** ⇒ 非零。
3. **`TASK-0744`** —— 新牙 `build/MilBridge/tools/proto-attribution-check.sh` ＋ 确定性语料
   `build/MilBridge/tools/proto-attribution-cases.tsv`（新步 `PROTO-ATTR`）：判「**谁写了这条请求**」
   （wire 台账 ＋ `popcount(mask)` 自洽 ＋ **fd 的 socket 身份必随行** ＋ 服务器侧 `Δ≤50 ms` 成对事件），
   三态 `ATTRIBUTED`／`NOT_ATTRIBUTED`／`NOINFO`。判否：阳性对照缺失 ⇒ 非零；语料行数与声明常数不符 ⇒ 非零。
4. **`TASK-0745`** —— **仓外冻结器** `~/w21-verify/w27-freeze.py` 的**补丁**（**主控写域**，本波只交补丁
   与排练读数，**不碰冻结器**）：写记录**前**逐键自检「本代记录带齐下一代所需的全部机读形态」，
   任一键命中 0 ⇒ **拒冻**。判否：坏形态档若不拒冻 ⇒ 非零。

## §2 生效边界与射程（逐字）

- **射程**：`$R` **仓内**文件。仓外车道件（含 `$R` 之外的取数器）**不在射程** —— 车道目录会被回收，
  仓内牙守不住它们。凡引用仓外现场处，一律写明"**仓外，不在射程**"。
- **不做产品改动**：`src/**`、`build/shims/**`、native 源、`tests/WpfGfx.Linux.Tests/**` 一字节未动
  ⇒ 九位**不应有产品位移**（`pf` 是环成员，整波重建必变、同尺寸）。
- **本波不做任何回归判定** ⇒ 走**机读行形态**（见 §3.1）。

## §3 判据（落地前写死）

### 3.1 回归判定（本波不适用）

`PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-wave-77`

（本波是判据/装置卫生波，**不含**任何"修前/修后"产品对比 ⇒ 四要件对本波不适用；本行是**硬形态**
声明 ⇒ 不得带 `residual=` 令牌。）

### 3.2 三颗牙的三态与阈值（先写死）

| 牙 | 机读行 | 三态 | `NOINFO` 的触发（**算不出 ≠ 绿**） |
|---|---|---|---|
| `wiring-coverage-check.sh` | `WIRING_COVERAGE=PASS\|FAIL\|NOINFO` | `rc 0/1/3` | `verify-all.sh` 不可读；`^run_step "` **零行**；接线集**抽成空集**（抽取器失明）；覆盖面活清单取不到或**零行** |
| `parser-guard-check.sh` | `PARSER_GUARD=PASS\|FAIL\|NOINFO` | `rc 0/1/3` | 声明件缺席／表头不认（无 `SCANROOT`）；扫描集为空 |
| `proto-attribution-check.sh` | `PROTO_ATTR=ATTRIBUTED\|NOT_ATTRIBUTED\|NOINFO` | 三态；`rc 0/1/3` 由语料对账决定 | **fd 的 socket 身份缺失**／`head` 解不全／`chain` 全在 `libX11`/`libxcb`/`xwrap` 层／无触发物 |

**共同硬规矩**：`examined == 0` **一律 `NOINFO`**（纪律 5：零检查必须响亮）；`NOINFO` **既不算绿也不算红**。

### 3.3 两极化（**每条都真跑**；原始读数见 `~/w180a/w77/polarity.md`）

1. **`0740`**：正极 ＝ 现树（接线集逐件入名单）⇒ `PASS missing_n=0`；
   反极 ＝ ①**沙箱注入一条"已接线但未入名单"的 `run_step` 指名** ⇒ 必 `FAIL rule=wired-but-uncovered` 并**点名该件**；
   ①另加**通用性**臂（换一个从没出现过的件名 ⇒ 照样红，证**非硬编码**）；①四条空边 ⇒ `NOINFO`。
2. **`0742`**：正极 ＝ 现树（`env` 面 4 处逐处裁定 ＋ `parser` 面 0 处）⇒ `PASS`；
   反极 ＝ ②现场**未列入射程表** ⇒ 必红（`rule=unnamed-site`）；②裁定 `HARMFUL` 且无豁免 ⇒ 必红；
   ②豁免**无理由**／**超上限** ⇒ 必红；②**守卫拒合法值** ⇒ 必红；另加**通用性**臂（注入新件的新闻现场 ⇒ 必红）。
3. **`0744`**：正极 ＝ 语料里 `role=POSCTL` 的行真判 `ATTRIBUTED`（**阳性对照是门槛**，缺 ⇒ `FAIL reason=untriggerable`）；
   反极 ＝ ① `XWRAP_CUT_PROTO` **线上等长替换**成 `NoOperation` 的那一档 ⇒ `NOT_ATTRIBUTED`（应用确实想发 ⇒
   意图被证，但服务器侧**不再**出现屏尺寸 `ConfigureNotify` 且末态不变）；
   ②`sock_id` 缺失 ⇒ `NOINFO`；②**只在符号级台账里"没有 CALL"** ⇒ **永不算 `NOT_ATTRIBUTED`**（`D-G144`）。
4. **`0745`**：正极 ＝ 好记录（7 条机读形态齐）⇒ 自检通过；反极 ＝ **复现 `#73` 那次事故的形态**
   （`inputs_fp` 写成**位移句**而非机读行）⇒ **拒冻**且**基线件零字节改动**；另加"形态出现两次"档 ⇒ 拒冻。

### 3.4 判否条件（本波）

任一牙出现下列情况 ⇒ **停手报主控**，不得自行放宽判据：
① 现树**该绿而不绿**（`0740` 现读 `missing_n>0` 而本波未同趟扩面；`0742` 射程内出现未裁定的危害形态）；
② 反极臂**没红**（判据是装饰）；③ 任何 `NOINFO` 被当成绿写进报告；
④ 三颗新牙落地后，**既有牙** `SELFDESC-WIRING`／`LANE-PATH`／`BOUNDARY-DECL`／`X-CENSUS` **任一转红**。

## §4 显式范围决定（**逐字写明，不是顺手加的行**）

### 4.1 `fp_inputs()` **显式扩面 ＋1**（主控 `2026-09-26` 裁定：**收编**，与 `#74` 裁 (B) 同形）

**现场（本波现取、可复算）**：把 `verify-all.sh` **全部 `run_step "` 行**里引用的**仓内判据/产出件**
路径抽成集合（ERE `(build|src|samples|docs|tests)/…\.(sh|py|tsv|json|txt)`），与**覆盖面活清单**
（`fp-manifest-step.sh` 同一码路径现取）取差集 ⇒ **恰好 1 件未被保护**：

`tests/WpfGfx.Linux.Tests/Commands.Tests/tools/verify-cmd-layout.py`

它是 `verify-all.sh` 里一条 `run_step` 的**判据件**（`python3 tests/…/verify-cmd-layout.py`），
依成文惯例「**读 ⇒ 进 `fp_inputs()`**」，且**查不到成文排除理由** ⇒ **本波收编它**（覆盖面 ＋1）。
**为什么不做成"具名排除 ＋ 理由"**：那等于**把"没人看着的缺口"制度化**。
**收口判据**：本牙在真树上**复跑**得「接线集 ⊆ 覆盖面」且 **`missing_n == 0`**（**不是**"我加了一行"）。
⚠️ **射程不因收编而放宽**：`.csproj`／`.sln`／`.props` **不进**接线集（那是**构建目标**，按成文惯例
不进 `fp_inputs()`）⇒ 把它们判红就是**射程过宽**（会恒红）。

### 4.2 `TASK-0742` 的**形态集故意保守**（一次**形态收窄**，如实登记）

初版 `parser` 形态含一条很宽的 `or 0\)`。**现读实测：它在现仓命中 4 处，全是表格单元格默认值**
（把一个可选列缺省成 0），**不是**解析失败回退 ⇒ 那 4 处会被**误判红**。⇒ 本波**删掉该形态**，
只留"解析失败即回退成中性**数值/坐标**"的形态。**理由**：泛红的判据会被读成"世界如此"（与
`#74` 的"假读数"同族）。**收窄后现读 `parser` 面 = 0 处** ⇒ 判据由**动态面（守卫自证）** ＋
**射程表逐处裁定**共同承载，**不靠**"零命中"本身。

### 4.3 `0742` 射程内实例的**逐条裁定**（不许含糊）

| 现场 | 裁定 | 理由（逐字） |
|---|---|---|
| `frame-presence-check.sh:136` `WPTD_DISPLAY:-:97` | **`BENIGN`** | 该值**不被当读数比较**，只作**目标选择**，且下一行立刻 `xdpyinfo -display` **用即校验**（不可用 ⇒ `FRAMEPRESENCE=NOINFO reason=X不可用` ＋ `exit 2`，**响亮**）⇒ **不构成假负**（假负＝**静默**中性化）。**残余如实**：无**格式**白名单 ⇒ `WPTD_DISPLAY=0` 会走到 `Xvfb 0`（＝`:0`）⇒ 属 **X-CENSUS／`D-G139` 族**（越界起显示位），**越出本波射程**，已单列。 |
| `t1c-census.sh:45` `WPTD_DISPLAY:-:98` | **`BENIGN`** | 同上；且 `:200` 已**逐字打印** `DISPLAY=$DISPLAY_NUM` ⇒ "必须校验并逐字打印"这条**满足打印那一半**。该件**不是** `run_step` 件（不在生产门禁里）。 |
| `geom-revert-beat-check.sh:98` `GEOMBEAT_LIVE_DIR` | **`BENIGN`** | 是**目录名**，不是判据参数（不在声明件的 `PARAM` 名字集里）⇒ 形状命中、语义不同。 |
| `baseline-sha-check.sh:62` `BASELINESHA_DECL` | **`BENIGN`** | 是**标签/出处说明**，不参与任何比较。 |
| **仓外** `D-G143` 原始案发地（一件车道取数器） | **不在射程** | 射程①（**仓外**）＋ 其归档读数已被"同件同参重算"证伪（归档 `EVT_PUSH_BACK` = 0／重算 = 1）。⇒ 本波**不**声称"该缺陷已在仓外被修"，只声称"**仓内无此形态** ∧ **形态本身有牙**"。 |

## §5 落仓那刻的声明值（**断言相等**，不是常量）

| 声明 | 值 | 来源 |
|---|---|---|
| 步数 | 现读 **47** ＋ **3** ⇒ **50** | `grep -c '^run_step "' verify-all.sh` **落仓那刻现取** |
| 覆盖面 | 现读 **205** ＋ **6**（本波 5 件 ＋ `TASK-0740` 收编 1 件）⇒ **211** | `fp_inputs()` **同码路径**现取（`fp-manifest-step.sh`） |
| 第 `[42]` 步 `--expect` | **205 → 211**（**同趟**改） | 漏改 ⇒ `FAIL reason=files-n-mismatch`，**方向安全** |
| `inputs_fp` | **必移**（5 新件 ＋ 1 收编件 ＋ `close-wave.sh` 自含） | 整波自印 ＋ 独立复算互证 |

**断言**：`新 DECL 首行步数 == 现取 grep -c '^run_step "'`、`fp_inputs()` 实跑件数 == `--expect 现值`。
⚠️ **两处数必须逐位相等**；不等 ⇒ **停手报主控**（不许"差不多"）。

## §6 硬前置（缺一即停手报主控）

1. **写者闸**：`#77` 必须是**唯一写者**（`#76` 已冻结/闭环，且无链在跑）。
2. **冻结器补丁不落仓**（它是**主控写域**）：本波只交补丁文件 ＋ 排练读数。
3. 三颗新牙 `%h == 1`；件内 `grep -c "$HOME/w"` == **0**（`D-G137`）；临时件一律 `mktemp -d` ＋ `trap`。
4. 新件**件头禁字**：不得出现那两个会被 `SELFDESC_WIRING` 判 `rule=forward` 的字样。
5. 既有牙同趟自洽：`SELFDESC-WIRING`／`LANE-PATH`／`BOUNDARY-DECL`／`X-CENSUS` 落地后**复跑**，`fails=0`。

## §7 落地后追加（**同趟**：主控 `2026-09-26` 追加要求 ＋ 事实核对）

### 7.1 新牙同趟折叠进既有 `[9] BUILD-HYGIENE`（**不动步数**）
**判据（先写死）**：仓根**不许**出现 `Directory.Build.props` ∧ `Directory.Build.targets`；
判定**同时**取两条来源：① `test -e`（工作树上有没有）；② `git ls-files --error-unmatch`（**被跟踪** ⇒ 即便此刻被删，上游合并也会带回）。任一为真 ⇒ `FAIL` ＋ 逐条点名路径与**来源**。
机读行：`BHYGIENE_ROOTPROPS=<PASS|FAIL|NA> exists= tracked= git= src=test-e,git-ls-files paths=… root=…`，并接进 `BHYGIENE_IMPORT=` 汇总行（`rootprops=`／`rootprops_exists=`／`rootprops_tracked=`／`rootprops_git=`）。
**为什么折叠而不新开步**：本波契约把 `grep -c '^run_step "'` 钉在 **`50`**（`47 → 50`，三个新步）⇒ 新开步会变 `51` 与契约冲突；`[9]` 正是"构建卫生"的家（先例 `TASK-0728` 折叠进 `[12]`）。
**两极化**：正极 = 干净真树 ⇒ `rootprops=PASS exists=0 tracked=0 git=present`；反极①**真树**把上游原件（`git show origin/main:Directory.Build.props`，`3a43d0988773baec`）放回仓根 ⇒ `BHYGIENE_DRIFT=FAIL kind=ROOT-PROPS-PRESENT path=Directory.Build.props` ＋ `rc=1`，**还原后**回到 `PASS`（`git status --porcelain` 前后同为 31）；反极②自测 `case Z1/Z2`（`.props`／`.targets` 各一档）；反极③自测 `case Z3`（**真 `git init` ＋ `git add` ＋ 再 `rm`** ⇒ 工作树没有、但**被跟踪** ⇒ 必红 —— 这一例是"只判文件不存在"与"同时判来源"的分水岭，没有它②就是死代码）。正极④自测 `case Z4`（`git init` 过但零跟踪 ⇒ 不红 ∧ `git=present`）。`--selftest` **29/29 PASS**。
**如实边界**：②只在 `$ROOT` **本身是 git 仓根**时才算得出 ⇒ 否则印 `git=NA` 且**不计入 `PASS`**（镜像/桩树里不存在"上游合并带回来"这条向量）。

### 7.2 旧路径重指向（21 件／23 处）
判据 = 仓内 `*.sh`／`*.py`（排除 `upstream/`）里 `wpf-linux-20260906` 的**命中数 == 0**；逐处断言"替换命中数恰 1"，改动前逐件 `cp -p` 备份并断言"备份 sha16 == 覆盖前现读 sha16"（`D-G126`）。**改完必须过 `LANE-PATH`／`SELFDESC-WIRING`／`REPO-ALIAS` 三牙**（三牙现读全 `PASS`）。

### 7.3 `TASK-0720` 残项现取核对
契约要求核对「第 9 处文本 `win32_classification.c:52` 留在 `#77`」＋「防漂移牙排进 `#77`」两条加注 —— **现取：`docs/ROUTES.md` 里两条加注均已不存在** ⇒ 如实记「该加注已过期」，两件都在 `#76` 办完（提交 `9cea5cc`）；实证见 §7.4。

### 7.4 `PTSGAP` 由 `FAIL` 转 `PASS`（`t4` 现场三修 ＋ 措辞对齐）
`PTSGAP=FAIL`（两处 `SITE-NOHIT build/MilBridge/HANDOFF-NEXT.md ops|impl`）的根因 = 该件写「**88 可操作／97 实现口径**」而抽取式要「**可操作 N／**」⇒ **在册数今天没有一条过闸的守卫**。修法四条同趟：① `R` 由仓根现推；② 读数行打 `root=`；③ `close-wave.sh` 显式传 `R="$ROOT"`；④ 措辞对齐。**收口读数**：`PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=97 so16=fc60c34d51fd9247 exports=550 root=/home/links-dev/netTest/GitProj/WPFOnLinux`；`--selftest 7/7 PASS`。

### 7.5 ⚠️ 落仓后发现并同趟修掉的两处（**自伤/更正节**，如实）

**(a) `TASK-0744` 的接线漏了 `--cases`**：包内 `landing.sh` 的 `RUNSTEP_LINES` 把该步写成不带参数的形态，而工具**要求** `--cases <语料.tsv>` ⇒ 门禁里 `PROTO_ATTR=NOINFO reason=usage:--cases-needs-file cases=0 … rc=3`（**该步根本没在判**）。修法：`--cases build/MilBridge/tools/proto-attribution-cases.tsv --expect 18`（与既有 `SILENT-HIT-V2 … --cases … --expect 12` 同形）⇒ 直跑 `PROTO_ATTR_GATE=PASS examined=18 mismatch=0 bad_expect=0 posctl=2/2` ∧ `PROTO_ATTR=ATTRIBUTED … rc=0`。
⇒ **`W180A` 复核结论的射程更正**：「已复核 12/12」**只**覆盖被落仓器点名的两颗牙（`W77_TOOTH_WIRING`／`W77_TOOTH_PARSER`）；第三颗在 `polarity.md` 里是**带 `--cases` 手跑**的，**不是门禁形态**。
⇒ **口径句**：**"落仓器的收口断言只验它自己点名的牙 ⇒ 没被点名的那颗牙在真门禁里可以是 `NOINFO`（`rc=3`）而整链只差一格红；凡新增一步，收口断言必须**逐一**把该波**每一颗**新牙按『门禁同形』跑一遍（不是按手跑形态）。"**（主控已把「交付 ⊆ 接线」＋「接线 ⟹ 真判」两条排进 `#78`。）

**(b) 迁移级：仓根 `.editorconfig` 使树根本建不起来**（详见 `build/MilBridge/P0-w77-report.md` §4b／§4c）。移出（`git rm`）后整波 `失败步骤 0`；原件存 `~/w-p0mig/quarantine-editorconfig/`（`bf84100e2afbd3d2`，含逐字节回退指令）。

### 7.6 本波**变更集逐笔**（一条都不省；与 `inputs_fp`／九位／位移三张表一致）
1. `W180A` 包四件：`TASK-0740`／`0742`／`0744`／`0745`（6 新件 ＋ 三新步 ＋ 两新声明/语料件）。
2. **21 处旧路径重指向**（23 个文本点，21 件）。
3. `TASK-0720` 残项现取核对（**结论：加注已过期**，两件在 `#76` 已办）＋ `pts-gap-count-check.sh` 三修（`R` 现推／读数行 `root=`／`close-wave.sh` 显式传 `R=`）＋ `HANDOFF-NEXT.md` 措辞对齐 ⇒ `PTSGAP` `FAIL → PASS`。
4. **`.editorconfig` 移出**（结构性去重，主控追认）。
5. **`PROTO-ATTR` 接线修正**（`--cases … --expect 18`；主控裁定"不是放宽判据"）。
6. `TASK-0745` **补丁重锚**（`E1+E2`；冻结器**逻辑一字节未落**）。
7. `t1` 的两笔提交（`7027be06…` ＋ `fd9a9a18…`）**随本波推送带走**。
8. 主控同趟追加：仓根 `Directory.Build.props`/`.targets` 缺席牙（**折叠进 `[9]`，不动步数**）。
9. 新发现 `BOUNDARY_DECL` 分类器缺陷（修）＋ **九位路径承载体**（不修、按归因声明）。

### 7.7 冻结器配置的**机读声明行**（`t17` 追加；`wave-freeze-consistency-check.py` 档②的读者）

本行必须与 `GENS['#77']` **逐字段相等**（`allow_changed` 集合、`pf_required` 布尔）。

```
WFREEZE-DECL: gen=#77 allow_changed=pc,pf,windowsbase,provider,dwf pf_required=False
```

---

## §8 `t17` 修复记账（2026-09-26；**原文一字未动保留，本节为 dated 追加**）

> 来源：`t6` 独立复验（`build/MilBridge/V77-verify-report.md`）判 `failed` —— 主链读数全过，但两条验收 FAIL、七句现场被推翻/打折扣。
> 本节逐条关账；**冻结块本身（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）一个字都没改**（本仓：冻结件不可加时效注）。

### 8.1 F1 —— **`#77` 引入的真回归：5 件 `dirname` 层数少一层**（已修 ＋ 已做成常态牙）
**现象**：`#77` 的 21 件重指向里有 5 件的派生式解析到 **`<仓>/build`** 而不是仓根；用改前的旧值拼则存在 ⇒ **真回归**。
**修法（逐件 before → after sha16；真跑，不是看源码）**：

| 件 | 行 | before | after |
|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/frames-gen.py` | 33 | `0b114c92b0d24a59` | `87d8cd0dfcf3a665` |
| `build/MilBridge/tools/analyze-layout-b34.py` | 12 | `010fd091effc89d9` | `c783ff683ebaea2e` |
| `build/MilBridge/tools/extract-layout-b34.py` | 13 | `ea66f3f260b90cdc` | `59b563eb57b62cee` |
| `build/MilBridge/tools/t1c-inputtrace-verify.py` | 32 | `0d3542bb0233f261` | `5cec72436bfb0ac8` |
| `build/MilBridge/tests/W81AWindowProbe/w81a-a0-analyze.py` | 28 | `86923276bf646553` | `317da8dc21cedf5e` |

**证明方式（真跑）**：把 **22 条替换表达式**逐条在**真实自指路径**下求值（`.py` 注入 `__file__`、`.sh` 注入 `${BASH_SOURCE[0]}` 后交 `bash`），断言「解析结果 == 仓根物理路径」；对 5 个声明了**消费点**的件再加断言「结果 + 后缀**存在**」。
- 修前：`REPOINT_ROSTER exprs=22 ok=17 bad=5 consume=5 consume_ok=5`（rc=1）
- 修后：`REPOINT_ROSTER exprs=22 ok=22 bad=0 consume=5 consume_ok=5`（rc=0）
- 原始读数：`~/w186a/w77rep/logs/f1-before.txt`／`f1-after.txt`；驱动器 `~/w186a/w77rep/bin/repoint_roster_eval.py`。

**射程缺口处置（二选一，本波选「纳入门禁」）**：这 5 件**既不在 `verify-all` 接线、也不在 `fp_inputs()` 覆盖面** ⇒ 原门禁**看不见**。本波**不**停在"具名声明为离线仪器"，而是**把这三件（含本档）做成真牙**：
新件 `build/MilBridge/tools/wave-freeze-consistency-check.py` 档① `WFREEZE_ROOTDEFAULT`（roster 22 条，逐条真跑）＋ 接进 `build/close-wave.sh` 的 **`[5c/6]`**（冻前，`FAIL` ⇒ `run()` 当场 `exit` ⇒ 汇总与两哨兵都不落）＋ 纳入 `fp_inputs()` 覆盖面（**211 → 212**，`[42] --expect` **同趟**改）。
**代价（如实）**：覆盖面 ＋1 ⇒ `inputs_fp` 位移为 `99db4fb592aba8f7dc53263d9914fa7c47c3f542207c35736ade1cddc08b6709`；且本牙**只覆盖 roster 里的 22 条**——新出现的"从自指路径推仓根"的件**不在射程**，除非同时进 roster（**这条边界写在这里，不许被读成"全仓派生式都被看住了"**）。

### 8.2 F2 —— 受版控**派生件**入笔（16 件；根因不是 churn）
`#77` 推送后 `porcelain` 现取 15 件（`t6` 跑完第三趟后 16 件）。**根因**：这些件 **HEAD 内容里带的是旧路径**（最后提交 9/20、9/22、P0），整波重建把它们写成新路径 ⇒ **每跑一次整波必脏**。
本波按径 `git add` 入笔并逐件点名（**不许**用 `git restore` 丢件来凑 `porcelain=0`）：`build/*/SR.g.cs`×8／`build/*/ARTIFACT-SRC-FP.txt`×3／`build/WindowsBase.Linux/PORT-CHANGES.md`／`build/.applocal-selftest.log`／`build/wave-audit.log`／`tests/parity/linux/parity-results.json`。
**声明**：全部是**构建/日志派生物、非逻辑变更**。
**待办（长期归属，主控定）**：`tracked 派生件`要么加进 `.gitignore` 并 `git rm --cached`，要么在生成器里**去掉绝对路径**（现在是"路径承载体" ⇒ 跨树/跨跑必变）。

### 8.3 F3 —— 冻结块九位行的 `provider` 是**上一代值**（**只记不改**）
`#77` 冻结块的**九位行**写 `provider` `1f9511a7ef395bfe`（＝`#76` 值），而同块**位移行**与**全部** `BASELINE tier=` 机读行写现值 `4041df9a704abfed` ⇒ 同块两个授权来源互相矛盾。
**根因（可复算）**：记录模板 `~/w185a/w77/w77freeze/w77-record.txt:29` 把 `provider`（与 `wic_shim`）写成了**字面量**（同行其它位是占位符）；`wic_shim` 恰好没动才没露馅。且冻结器**三道核全盲**：`_PREV_SRC` 7 键（`prev_bsfp/prev_dwf/prev_infp/prev_pc/prev_pf/prev_wb/prev_wsh`）与 `_TIER_MAP` 5 位**都不含 `provider`**。
**处置**：**不改冻结块**（冻结件不可加时效注）；本更正落在本件 ＋ `docs/ROUTES.md §15ae` ＋ `build/MilBridge/HANDOFF-NEXT.md §4`。
**待办（给主控的冻结器补丁设计，`~/w21-verify/**` 是主控写域，本波不碰）**：
1. `_PREV_SRC` 增两键：`'prev_provider': ('九位行:provider', '`provider` `([0-9a-f]{16})`', True)`、`'prev_wic': ('九位行:wic_shim', '`wic_shim` `([0-9a-f]{16})`', True)`；`_TIER_MAP` 增 `'prev_provider': 'provider'`、`'prev_wic': 'wic_shim'`；
2. `GENS[gen]` 相应增 `prev_provider`／`prev_wic`（否则 `skipped=` 会**响亮**点名，不静默）；
3. **记录模板禁用字面量**：渲染前断言「本代块里每一个九位值都等于 `now[...]`」（可现场复算）——即把"模板里写死"这件事本身做成会红的判据。

### 8.4 F4 —— 「两趟 post **唯一**原始差异是 `wall_s`」不成立（更正为 24 行标签类）
现取：两趟 `post1`／`post2` 各 129 行判词域，**归一化后差异 0 行**；**归一化前原始差异 24 行**，逐类点名：① 路径类（`/home/links-dev/*`、`/tmp/*`）；② 跑次戳/时间戳；③ 环境余量（`avail_kb`／`mem_mb`）；④ 耗时（`wall_s`／`held`）。
⇒ 按 `D-G138` 口径更正为：**「读数域差异 0；标签/环境类差异 24 行」**——"判词行逐字相同"这句**成立**，错的只是**"唯一"这个量词**。

### 8.5 F5 —— 预登记文本与 `GENS` 配置不一致（已加**机读声明行**＋牙）
FROZEN ⑩/⑥ 写 `allow_changed={'pf'}` ＋ `pf_required=True`；`GENS['#77']` 实为 `allow_changed={pc,pf,windowsbase,provider,dwf}` ＋ `pf_required=False`（**本节 §7.7 已落实为机读行**）：
```
WFREEZE-DECL: gen=#77 allow_changed=pc,pf,windowsbase,provider,dwf pf_required=False
```
⇒ 由 `wave-freeze-consistency-check.py` **档② `WFREEZE_DECL`** 读回并与冻结器 `GENS`（AST 只读抽取）**逐字段比较**，不符 ⇒ `FAIL` 并点名字段；取不到任一侧 ⇒ `NOINFO`（**不算绿**）。现读：`WFREEZE_DECL=PASS gen=#77 allow_changed_decl=dwf,pc,pf,provider,windowsbase allow_changed_gens=dwf,pc,pf,provider,windowsbase pf_required_decl=False pf_required_gens=False`。

### 8.6 F6 —— `app-local` 的两条「权威」路径之间**没有牙**（新登记 + 规约判定 + 牙）
**现场**：`DirectWrite.Linux.Provider.dll` 有两个都自称权威的路径；`t6` 重建了后者 ⇒ 前者立刻陈旧，`app-local` 当场 `STALE=52 / UNEXPECTED-DIFF=6 / DIVERGENT=1`，**而九位/哨兵走前者** ⇒ 谁重建其一都会让两侧分叉（`D-G130` 族：判据输入取自瞬时派生状态），且 `verify-all` 里**根本没有** app-local 这一步（无 `run_step`）⇒ 门禁看不见。
**规约权威判定 = `build/DirectWrite.Linux/Provider/bin/<CFG>/DirectWrite.Linux.Provider.dll`（后者）**，三条依据：① 它是**该工程自己的产出目录**；② **冻结器的 `NINE`** 用它（`w27-freeze.py` 现读）；③ `applocal-expect.py`／`check-applocal-sync.sh` 的 `ITEMS` 用它。⇒ 前者是**副本**，必须与权威相等。
**处置**：把副本刷成权威（`4041df9a704abfed` → `609192a419d125f2`；旧件留档 `~/w186a/w77rep/backup/f6/`），并落牙 **档③ `WFREEZE_NINEAUTH`**（声明对：provider 两条 ＋ `WindowsBase` 的 Release/Debug 两条）⇒ 分叉即 `FAIL` 并逐条点名两条路径与各自 sha16。**不许**只写"下趟整波自愈"。
**⚠️ 随之发生的九位位移（如实）**：权威 `provider` 由 `4041df9a704abfed` 变为 `609192a419d125f2` ⇒ **在册九位的 `provider` 与现场不再相同**（冻结点之后的重建位移；非本修复的语义变化）。

### 8.7 F7 —— `TASK-0745` 的**语义返工设计 ＋ 两极化证据**（只交设计与证据；不碰 `~/w21-verify/**`）
见 `build/MilBridge/P0-w77-repair-report.md` §F7（含「现行器为何 `bad=7`」的逐键分解、正确期望语义、以及"有位移的真实世代必须 `bad=[]`"的两极化读数）。

### 8.8 保留集件与覆盖面（同趟）
`~/w153a/bin/infp.sh:18` 原**硬编码**旧路径；`t7` 于 `22:12:07` 撤除旧路径符号链接后它返 `NOINFO reason=extract-empty`（**唯一**读者就是这一行）。本波按契约「保留集件只许加覆盖点」改为**可覆盖** `R="${INFP_R:-/home/links-dev/netTest/GitProj/WPFOnLinux}"`（**判据/管线/输出形态一字节未改**；等价性：撤链接前同一时刻官方工具与 `~/w-infp-at.sh $N` 同值 `b67560f2…`／`211`）。
覆盖面 **211 → 212**（＋本波新牙），`[42] --expect` 同趟改；现读 `fp=99db4fb592aba8f7dc53263d9914fa7c47c3f542207c35736ade1cddc08b6709`／`list=212`（`infp.sh` 与 `~/w-infp-at.sh` **同值**）。
