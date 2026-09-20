# `W27C` 报告 —— `D-R8` 的回归牙（**只交付、不接线**）

> **一句话结论**：`D-R8`（`BuildHygiene.props` 的逐工程 `<Import>` 一旦掉了，**今天没有任何东西会红**）的回归牙已交付 =
> 新建 `build/MilBridge/tools/build-hygiene-import-check.sh`（**`2607d0ba856f169a`**，18,451 B，301 行，模式 `711`，与四位兄弟脚本逐位一致）。
> 三态 `PASS`/`FAIL`/`NOINFO`（`rc=0/1/2`）+ `--selftest` **9 例 9/9 通过（其中 6 例断言"必须红"、2 例断言"必须 `NOINFO`"）**；
> 现场正极性 `BHYGIENE_IMPORT=PASS … files=40 lines=40 list=40`（`rc=0`）。
> **"删掉整份 `BuildHygiene.props`"这种更彻底的坏法抓得住**（`FAIL reason=props-missing`，`rc=1`；连"删 props + 把那 40 行一起摘掉"的合并坏法也照样红）。
> **仓内零改动**（只新建那一个 `.sh`；`--selftest` 的沙箱在 `$HOME`/`mktemp -d`，实测自测前后 40 份 csproj + props 的聚合 sha 逐位相同）、**零 `dotnet`**、零 `pkill`。
> **接线由主控在波尾做**（锚文本见 §6；`verify-all.sh` 是 W27B 的写域，本件一字未动）。

| 交付物 | before | after |
|---|---|---|
| `build/MilBridge/tools/build-hygiene-import-check.sh` | **不存在**（现场 `ls` ⇒ 无此文件） | **`2607d0ba856f169a`**｜18,451 B｜2026-09-17 17:54:08 +0800｜301 行｜`711` |
| 仓内其它文件 | —— | **零改动**（见 §7） |

**lane=W27C**｜2026-09-17 17:47 → 17:56 +0800｜host `linksdev-VirtualBox`｜kernel `6.8.0-138-generic`｜`nproc=3`
`loadavg` 开工 `1.34 0.69 0.42` → 收工 `3.86 2.49 1.28`｜`MemAvailable` 3,517 MB（全程 > 3,400 MB，**本件无构建、无内存压力**）
**本件 `dotnet` 调用数 = 0**（收工时机器上有 3 个 `dotnet` 进程，**不是本车道起的** —— 本波另有多条车道并行，见 §7.3）｜`pkill` 调用数 = 0。

---

## §1 判据的"名单"从哪来（本件的设计核心）

### 1.1 两条路的评估

| 路 | 形态 | 优点 | 致命缺点 |
|---|---|---|---|
| **① golden 清单**（**采纳**） | 一份**独立于被测树**的"应有清单"，逐份点名比对 | **删掉一行时它告诉你是哪一份**；"多出一个没登记的用户"也能点名 | 需要维护（新增/退役工程时要改名单）⇒ 已写成**维护契约**（§9） |
| ② 由 `BuildHygiene.props` 的存在性 + 目录遍历推 | 现场扫出所有带 `<Import>` 的 csproj，数量对得上就算过 | 零维护 | **判据与坏件同步缩水**：删掉一行时它只看见"现在有 39 个"，**根本不知道少了谁** ⇒ 射程会悄悄缩到零而它仍是绿的 |

**为什么必须选 ①（本项目的既有判例）**：这正是 `D-R4` 的形态 —— "判据的射程随被测件变化悄悄缩到零，而它当时仍然是绿的"（`docs/CURRENT-STATE.md:372`）。
路 ② 是同一族的第 N 个实例，**不许再犯**。

**锚点（仓内既有做法，不是我发明的范式）**：`build/MilBridge/tools/applier-audit-expected.txt` 就是"**独立于被检脚本的清单**"，
它在文件头自己写着（现场原文）：

```
# 必须被 build/integration-wave.sh 的 APPLIERS_EXPLICIT 登记的应用器（**独立于那份脚本**）
…
# 维护：新增/退役应用器时**改这里**，而不是只改 wave —— 这样"被摘掉"才会红。
```

⇒ 本件照同一招办。

### 1.2 名单放在哪：**内嵌**（单文件交付）

预登记 §1 把本车道的独占写域定成 **"新建的那一个 `.sh`"** ⇒ 名单**内嵌在脚本里**（`golden_read()` 的 heredoc，40 行），
而不是另建一份 `.txt`。这样**交付物就是一个文件**，名单与判据同在、不可能只改一个漏改另一个。
同时保留 `BHYGIENE_GOLDEN=<file>` 覆盖口（供自测与将来外置）。

**名单的独立机器证**（不是我手抄的）：用 `python3` 从脚本里正则切出 heredoc 段落，与现场 `grep` 实测集 `diff` ⇒

```
LIST_LINES=40
IDENTICAL（40 行逐字节相同）
```

### 1.3 "删掉整份 `BuildHygiene.props`"能不能被抓住 —— **能**（实测）

这是本件被点名要求回答的问题。**三种"更彻底的坏法"全部实测被抓**：

| 坏法 | 读数 | 为什么抓得住 |
|---|---|---|
| **G 只删整份 `BuildHygiene.props`**（40 行 `<Import>` 还在） | `BHYGIENE_DRIFT=FAIL kind=PROPS-MISSING path=BuildHygiene.props` + `BHYGIENE_IMPORT=FAIL reason=props-missing`，`rc=1` | ②档判"实现件在不在"，**与 ③档无关** ⇒ 那 40 行 `grep` 照样是 40，但保护已不存在 |
| **G′ 删 props + 把那 40 行一起摘掉**（合并坏法，本件另测一档） | 同上 → `FAIL reason=props-missing`，`rc=1` | ②档**在 ③档之前**跑 ⇒ 先命中 |
| **H props 在、但排除那条被掏空**（`obj/**;bin/**` 被删） | `BHYGIENE_DRIFT=FAIL kind=PROPS-CONTENT-LOST … missing='obj/**;bin/**'`，`rc=1`（掏空后 props `sha16=5e7f39d7122989ef`） | ②档同时判**内容**（光有文件不够） |

⇒ **"删文件"和"掏空内容"这两条"绕过判据"的路都被堵死**。

---

## §2 口径：历史三个数 `38`/`40`/`42` 谁的错、错在哪

**先给结论（这是本件查清的一件事）**：

| 数 | 口径（现场命令） | 现读数 | 判定 |
|---|---|---|---|
| **38** | `#21` W21B **自己改过的 csproj 数**（36 暴露 + 2 已修） | 当时 38 | **当时对、今天陈旧**。它是一条**历史动作的计数**，不是"应有名单"。差 2 的差额**已逐条查清** |
| **40** | `grep -rl --include='*.csproj' -- 'BuildHygiene.props' .` | **40** | ✅ **对**（"命中文件数"） |
| **40** | 逐份 `grep -cF -- '<Import Project="$([MSBuild]::GetPathOfFileAbove('BuildHygiene.props'))" />'` 之和 | **40** | ✅ **对**（"规范 `Import` 行数"） |
| **42** | `grep -rn --include='*.csproj' -- 'BuildHygiene.props' . \| grep -c '<Import'` | 42 | 🔴 **错（口径污染）** —— 见下 |

### 2.1 `38 → 40` 的差额**已逐条查清**（不是"38 记错了"）

拿 `$HOME/wfp-runs/w21-laneW21B/backup/*.csproj.before`（**38 份**，那是 W21B 当年的备份）与现场 40 份做差集 ⇒
**现 40 有、W21B 38 无 = 恰好 2 份**：

```
build/MilBridge/tests/D5CbrProbe/D5CbrProbe.csproj     ← #25 波新增的仪器
build/MilBridge/tests/FrameProbe/FrameProbe.csproj     ← #24 波新增的仪器
```

（两处的 `<Import>` 也不在同一位：`D5CbrProbe.csproj:44`、`FrameProbe.csproj:27`，而不是通例的第 5 行 —— 与"后来新增"一致。）
⇒ **`38` 是 W21B 当年的动作计数，`40` 是现值；差额 = `#24`/`#25` 两份新仪器自愿接入。**
⇒ 文档里把 `38` 当**现值**引用（`docs/CURRENT-STATE.md:84`、`handoff.md:2726`、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:168`、`docs/WAVE21-PREREGISTRATION.md:440`、`build/MilBridge/W21B-report.md:14/24/235/293/342`）是**陈旧**，不是"当年算错"。

### 2.2 🔴 `42` 是**错的** —— 它是"口径污染"出来的数

**现场分解（机器证）**：

```
总提及行（grep -rn … 'BuildHygiene.props'）        = 82
  其中含 <Import 子串的行                          = 42   ← 主控记的"Import 行共 42 条"就是这个
  其中【规范 Import】行                            = 40   ← 真值
  其中【注释散文】行（不含 <Import）                = 40
⇒ 42 = 40(规范) + 2(散文里**也**带 `<Import` 子串)
```

**那 2 行是中文注释**（现场原文，逐字）：

```
build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj:38:  收口到仓根 `BuildHygiene.props`**（文件开头第 5 行的 `<Import>`；全仓唯一一份）。
build/MilBridge/tests/TextLineProto/TextLineProto.csproj:30:  收口到仓根 `BuildHygiene.props`**（文件开头第 5 行的 `<Import>`；全仓唯一一份）。
```

⇒ **`42` 把两行"解释这一行 `<Import>` 长什么样"的注释当成了 `Import` 本身**。
**正确的 `Import` 行数 = 40。**

> **更正请求**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:**1105**`（本件读取时该文件 `sha16=e2f12e760a6ffd19`、1155 行）
> 现有原文「…命中 40 个 csproj、而 `Import` 行共 **42** 条」**应更正为 40**，并写明口径。
> ⚠️ 该行号在下笔时是 1105：**本件开工时它是 1094**（`W27E` 等并肩车道正在改这份文件，17:54:41 还在动）⇒ **引用必须当趟现读**。

**三个口径的现场命令（本件脚本自己分别报，都不许并成一个数）**：

```bash
# ① 命中文件数
grep -rl --include='*.csproj' -- 'BuildHygiene.props' . | wc -l                       # 40
# ② 规范 Import 行数
grep -rn --include='*.csproj' -F -- '<Import Project="$([MSBuild]::GetPathOfFileAbove('"'"'BuildHygiene.props'"'"'))" />' . | wc -l   # 40
# ③ 任何提及行数（含注释散文 —— 就是 42 那条口径的母体）
grep -rn --include='*.csproj' -- 'BuildHygiene.props' . | wc -l                      # 82
```

### 2.3 `BuildHygiene.props` 自己的口径自述（现场原文）

`BuildHygiene.props:41`（`sha16=c88fcccde138263b`、4,510 B、64 行、mtime 2026-09-16 18:28:23 —— **本件未动**）：

```
  ⇒ 本件选择**显式导入**：作用域 = **恰好**实测暴露集（`grep -rl 'BuildHygiene.props'` 扫 `*.csproj` 即全部用户），
```

⇒ 它自称的口径 = **文件**口径（`grep -rl`），**不是行口径** —— 与 ①/②今天同值（40），**这纯属巧合**：
现场实测 **"提及但没接入"的 csproj = 0**、**"接入但没提及"的 = 0** ⇒ 两个口径今天重合。
**但只要将来有谁写一份"提到这个名字却没用它"的 csproj，两个口径就会分叉** ⇒ 本判据按**行**（②）判，文件口径只作诊断量打印。

⚠️ **另一个同名陷阱**（供后人避坑）：`BuildHygiene.props:47` 那一行"怎么用"的示例
（`<Import Project="$([MSBuild]::GetPathOfFileAbove('BuildHygiene.props'))" />`）
**在文件自己的注释块里**（第 1–57 行是 `<!-- … -->`）⇒ **不带 `--include='*.csproj'` 的 `grep` 会把 props 自己算成一个"用户"**
（实测：不带 `--include` 时 `grep -rlF` 命中 **44** = 40 csproj + 3 份报告 `.md` + props 自己）。
本判据**逐份读 csproj**，不依赖 `grep -rl` 的全文件口径 ⇒ 不受此坑影响。

---

## §3 核对器：抄了 `baseline-sha-check.sh`（`5836b8296b2e4245`）哪些设计（带行号）

| `baseline-sha-check.sh` 的落点 | 原件逐字/形态 | 本件的对应 |
|---|---|---|
| `:19` | `set -uo pipefail` | 同（**刻意不用 `set -e`**：本判据需要容忍 `grep` 的非零返回） |
| `:21-22` | `HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`；`R="$(cd "$HERE/../../.." && pwd)"` | 同（仓根定位，深度无关）；另存 `SELF`/`REAL_ROOT` 供 `--selftest` 递归调用与沙箱取样 |
| `:23-24` | `BASE="${BSC_BASE:-…}"`、`STATE="${BSC_STATE:-…}"`（**环境变量可覆盖**） | 同 → `ROOT="${BHYGIENE_ROOT:-$REAL_ROOT}"`、`BHYGIENE_GOLDEN` 覆盖口 |
| `:4-13` | 文件头把**三档判据**逐条写死（"缺该行 ⇒ `NOINFO`（文档没声明 ⇒ 无信息，不是'一致'）"） | 同 → 文件头"判据（四档）"+ 每档的**精确失败模式名** |
| `:14` | `# rc：**只有两项全 PASS 才 rc=0**；FAIL 与 NOINFO 都 rc=1` | **照抄语义、刻意改判**：`0=PASS / 1=FAIL / 2=NOINFO`（`NOINFO` 单列；理由与等价性写在文件头，见下） |
| `:30-31` | 缺文件 ⇒ `echo '…NOINFO reason=…-missing'; return 1` | 同 → `noinfo golden-missing` / `props-missing` |
| `:33` | `live="$(sha256sum "$base" \| cut -c1-16)"` | 同形态 → `sha16()` 辅助函数 |
| `:36-39` | 缺"机器声明行" ⇒ `NOINFO reason=no-declaration` | 同精神 → 缺名单 / 名单空 / **名单长度 ≠ `EXPECT_N`** ⇒ `NOINFO` |
| `:44-51` | 声明解不出 / 相等 / 不等 ⇒ 三态分派 | 同 → ①③④四档分派 |
| `:62-64` | 结论行是**机器可读 `KEY=VALUE`**（`BASELINESHA=… live=… decl=…`） | 同 → `BHYGIENE_IMPORT=PASS/FAIL/NOINFO reason=… files=… lines=… list=…` |
| `:79-80` | `if … 全 PASS; then return 0; fi; return 1` | 同 → `[ "$state" = PASS ] && return 0; return 1`（`NOINFO` 由早退的 `return 2`） |
| `:83-84` | `--selftest` ⇒ `T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT` | 同 |
| `:85-88` | `np`/`nf` 计数器 + `mk()` 造件 | 同 → `np`/`nf` + `mirror()`（**沙箱造法不同，见下**） |
| `:96-111` | `chk()`：跑子进程、抽状态、`printf 'SELFTEST case=%s expect=%s got=%s rc=%s => %s\n'`、计 `np`/`nf` | 同形态 → **多断言一项 `concl_lines`**（见下） |
| `:99-101` | ⚠️ 原件留档的真事故：**不取首行 ⇒ 声明缺失时会印两行同键 ⇒ 比较永远失败** | 本件**按构造只有一行** `^BHYGIENE_IMPORT=`，但仍**机器断言 `concl_lines==1`** ⇒ 防复发（每例实测 `concl_lines=1`） |
| `:113-119` | ⚠️ 原件留档：**扰动值必须严格 16 位**，否则只证出 `NOINFO` 没证出 `FAIL` | 同精神 → case F 专门区分"**名单不可用 ⇒ NOINFO**"与"**名单可用但树漂了 ⇒ FAIL**" |
| `:133-134` | `echo "BSC_SELFTEST=$([ "$nf" -eq 0 ] && echo PASS \|\| echo FAIL) cases=… pass=… fail=…"`；`[ "$nf" -eq 0 ] && exit 0 \|\| exit 1` | 同 → `BHYGIENE_SELFTEST=PASS cases=9 pass=9 fail=0` |

### 3.1 两处**刻意不同**（如实登记，不许读成"照抄"）

1. **`NOINFO` 单列 `rc=2`**（原件 `:14` 把 `FAIL`/`NOINFO` 都算 `rc=1`）。
   理由：`verify-all.sh:158-227` 的 `run_step` **非 0 即 `❌`** ⇒ 两种做法**都不会变绿**；
   单列只是**不让"算不出来"与"真漂了"混成一个数**（与 `frame-step.sh` 的 `rc=0/1/2` 惯例一致）。
2. **沙箱造法：最小镜像，不是整树 `cp -a`**（`KNOWN-DEFECTS.md:1107` 引的 W26G 草稿写的是 `cp -a`）。
   理由：本仓 **3.6 GB**，而"被测面" = 仓根 props + 40 份 csproj = **164,552 B**（实测）。
   判据本来就是**按文件逐份量**的 ⇒ 逐份 `cp -p` 走完**全部**代码路径，而**快三个数量级、且不碰仓内任何字节**。
   ⚠️ 用 `cp -p`（**复制**）而**不是硬链接**：沙箱里要重写这些文件，硬链接会把改写带回真件。

---

## §4 `--selftest`：9 例 9/9（**6 例断言"必须红"**、2 例断言"必须 `NOINFO`"、1 例正极性）

**现场输出（逐字）**：

```
SELFTEST case=A expect=PASS got=PASS concl_lines=1 rc=0 => yes
SELFTEST case=B expect=FAIL got=FAIL concl_lines=1 rc=1 => yes
SELFTEST case=C expect=FAIL got=FAIL concl_lines=1 rc=1 => yes
SELFTEST case=D expect=FAIL got=FAIL concl_lines=1 rc=1 => yes
SELFTEST case=E expect=NOINFO got=NOINFO concl_lines=1 rc=2 => yes
SELFTEST case=F expect=NOINFO got=NOINFO concl_lines=1 rc=2 => yes
SELFTEST case=G expect=FAIL got=FAIL concl_lines=1 rc=1 => yes
SELFTEST case=H expect=FAIL got=FAIL concl_lines=1 rc=1 => yes
SELFTEST case=I expect=FAIL got=FAIL concl_lines=1 rc=1 => yes
BHYGIENE_SELFTEST=PASS cases=9 pass=9 fail=0
```

### 4.1 逐例**机制**读数（不只证"状态对"，还证"**红的正是那一档**"）

留档：`$HOME/w27c/readings/polarity/manual.log`（逐例机制日志）、`$HOME/w27c/readings/polarity/list-from-script.txt`（python 独立切出的名单）。
沙箱用 `python3` 从脚本里切名单**独立重建**（不借脚本自己的自测机制），逐例扰动后跑**真件**：

| # | 扰动 | `rc` | **自报的失败模式（逐字）** |
|---|---|---|---|
| **A** | 干净镜像（正极性） | **0** | `BHYGIENE_IMPORT=PASS reason=ok files=40 lines=40 list=40 mention_files=40 mention_lines=82 disappeared=0 dup=0 unlisted=0 file_absent=0 expect_n=40 props=c88fcccde138263b` |
| **B** | 删掉某一份的**那一行** `Import` | **1** | `BHYGIENE_DRIFT=FAIL kind=DISAPPEARED path=build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj c=0（**这一行掉了 ⇒ 私有 obj 构建会大面积 CS0579**）` |
| **C** | 同一份里**重复插一行** | **1** | `BHYGIENE_DRIFT=FAIL kind=DUP path=…HbTextLineParity.csproj c=2（同一份工程里插了多行）`（`files=40 lines=41`） |
| **D** | 名单里的**工程文件整个不见** | **1** | `BHYGIENE_DRIFT=FAIL kind=FILE-ABSENT path=…HbTextLineParity.csproj（名单里的工程文件不在树上）` |
| **E** | **名单文件缺失** | **2** | `BHYGIENE_IMPORT=NOINFO reason=golden-missing source=…/nope.list` |
| **F** | **名单被截断**（40 → 39 行） | **2** | `BHYGIENE_IMPORT=NOINFO reason=golden-length-mismatch n=39 expect=40（名单被截断/被改 ⇒ 判据算不出，**不许当绿**）` |
| **G** | **删掉整份 `BuildHygiene.props`** | **1** | `BHYGIENE_DRIFT=FAIL kind=PROPS-MISSING path=BuildHygiene.props …` + `BHYGIENE_IMPORT=FAIL reason=props-missing props=BuildHygiene.props` |
| **H** | props 在、**排除那条被掏空** | **1** | `BHYGIENE_DRIFT=FAIL kind=PROPS-CONTENT-LOST path=BuildHygiene.props missing='obj/**;bin/**'（文件在、保护被掏空）`（掏空后 props `sha16=5e7f39d7122989ef`） |
| **I** | 树里**多一份带 `Import` 却不在名单里**的工程 | **1** | `BHYGIENE_DRIFT=FAIL kind=UNLISTED path=EXTRA-Unlisted.csproj c=1（现场有规范 Import，却不在名单里 ⇒ **多出来的用户也要点名**）`（`files=41 lines=41 list=40`） |
| **G′** | **删 props + 把那 40 行一起摘掉**（合并坏法，另测档） | **1** | `BHYGIENE_IMPORT=FAIL reason=props-missing props=BuildHygiene.props` ⇒ **也红** |

⇒ **每一例的红/`NOINFO` 都落在预定的那一档，且点名到具体文件** —— 不是"碰巧红了"。

### 4.2 `--selftest` 对仓内**零写入**的机器证

把"40 份 csproj + props"的**逐件 sha256 聚合**（`… | LC_ALL=C sort | sha256sum`）在**跑自测之前/之后**各算一次：

```
AGG_BEFORE=575073aaef13ed6c9954c25d6a8fff000a32d1d309473e7771141462feb5942d
（跑 --selftest，rc=0）
AGG_AFTER =575073aaef13ed6c9954c25d6a8fff000a32d1d309473e7771141462feb5942d
```

逐位相同 ⇒ 沙箱没渗回真件（所有复制/改写都发生在 `mktemp -d` 造出的 `$T/A`…`$T/I` 里；沙箱是 `cp -p` **副本**，不是硬链接）。

---

## §5 `run_step` 契约实测（这决定了结论行怎么印）

`verify-all.sh`（本件读取时 `sha16=ad705fa5b0cdb331`、510 行、`run_step` 调用 **14** 个）有两条 grep：

- **绿分支** `:208`：`grep -E '^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)' "$log" | head -8`
- **失败分支** `:217`：`grep -E "error [A-Z]+[0-9]+|Failed!|Failed [A-Za-z]|[A-Z][A-Z0-9_]*=(FAIL|NOINFO)" "$log" | head -12`

**本件的实测**：

| 契约 | 现场读数 |
|---|---|
| 绿：结论行**行首锚定**、值后接空格 | `BHYGIENE_IMPORT=PASS reason=ok …` ⇒ **命中 1 行**（`head -8` ⇒ 全部上屏） |
| 绿：那 5 行**口径行**会不会被误捞 | `BHYGIENE_USERS_FILES=40` 等**值不是 `PASS/FAIL/NOINFO`** ⇒ **不匹配**（这正是"口径行与结论行"要分开的原因） |
| 失败：逐条点名能否上屏 | 删 `FrameProbe` 那一行的日志 ⇒ 命中 **2 行**：`BHYGIENE_DRIFT=FAIL kind=DISAPPEARED path=…FrameProbe.csproj c=0 …` + `BHYGIENE_IMPORT=FAIL reason=drift files=39 lines=39 list=40 … disappeared=1 …` |
| `NOINFO`（`rc=2`） | `BHYGIENE_IMPORT=NOINFO reason=…` ⇒ 走失败分支、**变红而不是变绿**（`run_step` 非 0 即 `❌`）✅ |

> **一处本件自己纠正的设计缺陷（留档）**：第一版把逐条点名写成缩进的 `  DISAPPEARED …`，
> 那样**失败分支的 grep 一条都捞不到**、屏上只剩一行汇总数 ⇒ 诊断面丢信息。
> 已改成 `BHYGIENE_DRIFT=FAIL kind=… path=…`（**行首、`KEY=FAIL` 形态**）⇒ 逐条点名能上屏。

---

## §6 接线点（**只给锚文本，不接线** —— `verify-all.sh` 是 W27B 的写域）

**⛔ 本件**：`verify-all.sh` **一字未动**（该件在本件窗口内被 `W27B` 从 `f1dc01793a160c19` 改成 `ad705fa5b0cdb331`）。

**确切插入点（用锚文本，因为行号在动）**：紧接这一行**之后**、在汇总横幅之前：

```
echo
echo "[8] 臂日志 sha 核对（结构化登记 vs 现场硬链接件；#26 加）"
run_step "ARM-LOG-SHA" bash build/MilBridge/tools/arm-log-sha-check.sh
        ← ★ 插在这里（现件 :423-424 之后、:426 的空 `echo` 之前）
```

**要插的两行（逐字）**：

```bash
echo
echo "[9] 构建卫生（D-R8：BuildHygiene.props 的逐工程 Import；名单即判据）"
run_step "BUILD-HYGIENE" bash build/MilBridge/tools/build-hygiene-import-check.sh
```

**要点**：
1. **步名 `BUILD-HYGIENE` 故意 ASCII** —— 否则失败日志路径会被 `tr -c 'A-Za-z0-9' '_'` 打成一片下划线（`W24B` 的教训）。
2. **步数 `14 → 15`**（`run_step` 调用数）。要同步改的文档：`verify-all.sh:2-3` 的头注释、`:4` 的步数口径行、`docs/CURRENT-STATE.md` §2「四条自证命令」、`handoff.md`。
   ⚠️ `W27D` 的核对器也要接线 ⇒ **最终步数由主控定**（14 → 15 或 16），本件只给本步的锚点。
3. **本步 `rc` 归属**：`rc` **完全由四档判据决定**（0/1/2）；`NOINFO` 与 `FAIL` 在 `run_step` 里**都算失败**（设计如此：**"算不出来"不许当绿**）。
4. ⚠️ 锚点核对：本件读到 `verify-all.sh` 时它 **510 行 / 14 个 `run_step` / 末步 `[8] ARM-LOG-SHA`**；
   `W26G` 的草稿是按"13 步、末步 `[7] BASELINE-SHA`"写的 ⇒ **已过期**（`W27F` 也在重锚同一件事）。
5. ⚠️ **本步零 `dotnet`、零世代成本**：它只读文件 ⇒ **不进 `inputs_fp`**（`build/close-wave.sh:68-79` 的覆盖面里 `*.csproj`/`*.props` 命中 0），
   **也不被任何指纹保护**（`build/bridge-src-fp.sh:41-49` 的 `src_list()` 只收 `src/WpfGfx.Linux` 与 `build/MilBridge` 两个根下、
   **剪掉** `bin`/`obj`/`.artifacts`/`tests`/`alt-route-b`/`spike` 之后剩下的 `*.cs`/`*.csproj`/`*.props`/`*.targets`/`*.resx`；
   **`*.sh` 不在扩展名表里**，且新建件在 `build/MilBridge/tools/` ⇒ **两个条件都躲开了**）。

---

## §7 零位移机器证

### 7.1 九位 / `inputs_fp` / `GEN_KEYS`：开工 vs 收工**逐位相同**

用 `$HOME/w27c/readings/snapshot.sh`（**逐字照抄 `close-wave.sh:68-79` 的 `fp_inputs()`**，九位路径照抄 `close-wave.sh:181-190`）：

| 位/量 | BEFORE（17:49:15，loadavg 1.34） | AFTER（17:53:46，loadavg 3.44） | |
|---|---|---|---|
| `bridge` | `d567c26f197ec1e3` | `d567c26f197ec1e3` | ✅ |
| `pc` | `7374308a00c55572` | `7374308a00c55572` | ✅ |
| `pf` | `ebbe3bab855cdd55` | `ebbe3bab855cdd55` | ✅ |
| `windowsbase` | `1114a28ec5a03ab7` | `1114a28ec5a03ab7` | ✅ |
| `provider` | `9aa0d744802aaa31` | `9aa0d744802aaa31` | ✅ |
| `win32shim` | `0098234982391bbf` | `0098234982391bbf` | ✅ |
| `wic_shim` | `03b67fbcd7c385b6` | `03b67fbcd7c385b6` | ✅ |
| **`hbtextline_shim`** | **`e89fed55fd8e32bc`** | **`e89fed55fd8e32bc`** | ✅（停条件③未触发） |
| `dwf` | `0ed422ef2dd46445` | `0ed422ef2dd46445` | ✅ |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | `b6acdba4f01599d8` | ✅ |
| **`inputs_fp`** | `0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8` | **同值** | ✅（停条件②未触发） |
| **`GEN_KEYS`** | `id=#23 run_sh=3e513e88a4fa4ec9 program_cs=2e458928fc1577c2 shim=e89fed55fd8e32bc` | **同值** | ✅（停条件④未触发） |

**停条件核对（预登记 §5）**：① 九位任何一位变 ⇒ **未发生**（含 `pf`）；② `inputs_fp` 变 ⇒ **未发生**；③ shim 被碰 ⇒ **未发生**；④ `GEN_KEYS` 三项变 ⇒ **未发生**；⑥ 越写域 ⇒ **未发生**（只新建那一个 `.sh`）。**表外位移：无。**

### 7.2 仓内写动作：只有那一个新文件

`chmod` 之外**没有对任何既有文件做过写操作**；`--selftest` 的沙箱在 `mktemp -d`（§4.2 有聚合 sha 双证）。
**本件顺带留档一处自己的操作偏差（如实记）**：我一度把新文件 `chmod 755`，而**四位兄弟脚本全是 `711`**
（`baseline-sha-check.sh` / `frame-step.sh` / `arm-log-sha-check.sh` / `defect-registry-check.sh`）⇒ **已改回 `711`**，与四位逐位一致（内容 sha 未变：仍是 `2607d0ba856f169a`）。

### 7.3 ⚠️ 并肩车道的位移（**不是我的**，但影响引用）

在本件窗口（17:47–17:56）内，两条**别的**车道改了它们自己的写域：

| 文件 | 本件开工时 | 本件收工时 | 归属（按预登记 §1 写域表） |
|---|---|---|---|
| `build/MilBridge/known-red.json` | `bdc710a01b6a4712` | `b7a4ad0907f9d76b` | **W27A** 的独占写域 |
| `verify-all.sh` | `f1dc01793a160c19`（316 行） | `ad705fa5b0cdb331`（510 行） | **W27B** 的独占写域 |
| `build/MilBridge/tools/tline-gate.sh` | `59ce84346325eb21` | `59ce84346325eb21` | W27A 的写域；**内容未变**（其 mtime `17:48:32` 早于本件 BEFORE 快照 `17:49:15` ⇒ 与本件窗口无关） |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | （本件读到 `e2f12e760a6ffd19`，1155 行；**开工时 `BuildHygiene` 那段在 :1094，收工时在 :1105**） | 仍在动（17:55:03） | W27E / 主控 |
| `docs/CURRENT-STATE.md` | —— | 17:55:03 被写 | 主控写域 |

**另有一条要请主控核**（本件**未取到** before 值，只报现场 mtime 事实，**不作归因**）：
`build/MilBridge/arm-logs/tab-anchor.log` 的 mtime = **17:52:10**（落在本件窗口内，**不是本件所写** —— 本件全程只读文件、零写入）。
预登记 §2 明写"三支 `tab-*` 臂日志**不动**"、§5 停条件 7 又把"动 `arm_logs`"列为停条件 ⇒ **该件是否被改动、内容 sha 有没有变，请主控当趟核**
（本件没有它的 before 读数 ⇒ 记 `未取到`，**不推测**）。

⇒ **教训（与 W26G 同款）**：本报告里凡引**行号**处一律同时给**锚文本**与**当趟 sha16**；**引用前必须现读**。

---

## §8 我推翻了哪一句话

**推翻：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（现件 `:1105`）里那句「`Import` 行共 **42** 条」是错的 —— 真值 40。**

- **反证（现场机器证）**：`grep -rn --include='*.csproj' -- 'BuildHygiene.props' . | grep -c '<Import'` = **42**，
  但那 42 行里有 **2 行是中文注释**（`HbTextLineParity.csproj:38`、`TextLineProto.csproj:30`，**逐字见 §2.2**），
  它们**同时**含子串 `<Import` 与 `BuildHygiene.props`；**规范 `Import` 行只有 40**。
- **后果**：若照 42 去写判据（"总行数 == 42"），**今天就会红**（现场只有 40）⇒ 这条数必须在接线前更正。
- **同时确认（没有推翻）**：`38` 是 `#21` W21B 的**动作计数**（当时对、今天陈旧，差额 2 份已逐条点名）；`40` 是现值。
  ⇒ **`38`/`40`/`42` 三个数"不同口径"这句是对的；错的是把 `42` 当成"`Import` 行数"这个**口径标签**。

**另推翻（措辞层面，非判据）**：`KNOWN-DEFECTS.md:1107` 引的 W26G 草稿写"反极性 = 沙箱 `cp -a`"。
本件实测**不需要**整树 `cp -a`（3.6 GB）：最小镜像（164 KB）走完同样的代码路径，且**仓内零字节**（§3.1）。

---

## §9 边界与维护契约（**不许读宽**）

1. **本判据断言的是"机制"，不只是"结果"**：它要求这条保护是**通过 `BuildHygiene.props` + 逐工程一行 `<Import>`** 接的。
   若将来**换机制**（例如改用仓根 `Directory.Build.props`）⇒ **本步会红**。
   那是**预期的**（换机制是一件应当被看见的事）⇒ **必须同时改本件的内嵌名单与 `EXPECT_N`**，**不许**为了变绿而放宽判据。
2. **本判据不判"`CS0579` 真的会发生"**：`CS0579` 的端到端复现**要 `dotnet`**（`#20` 实测 `改前 rc=1/16 错全 CS0579`、`改后 rc=0/0 错`）。
   本件**零 `dotnet`** ⇒ **本步的绿只能读成"接线没掉"，不许读成"私有 obj 构建已经过验证"**。
   它与 `D-R8` 的"产品级红证"是**两笔账**（后者今天只在 `W20B-report.md` 的归档读数里）。
3. **本步不覆盖"`Import` 解析到哪一份"**：规范行是**逐字节**匹配（含 `GetPathOfFileAbove('BuildHygiene.props')`），
   **但**"某子树里放一份**同名**的 `BuildHygiene.props` 把 `GetPathOfFileAbove` 截胡"这种坏法**本判据不判**
   （该函数取"最近的"，而本判据只量文本）⇒ 这是**登记在册的边界，不是漏洞**。
   现场事实（本件已核，**不是推测**）：`find . -name 'BuildHygiene.props'` ⇒ **只有 1 份**，就在仓根 `./BuildHygiene.props` ⇒ **该边界今天无实例**。
   （若将来新增第二份，本步**不会红** —— 这是本判据已知的射程缺口，**不许读成"已覆盖"**。）
4. **名单维护义务**：新增/退役带此 `Import` 的工程 ⇒ **必须改本件的 heredoc 名单 + `EXPECT_N`**，否则本步红。
   `EXPECT_N` 的存在正是为了**让"名单被删几行"变成 `NOINFO` 而不是悄悄缩小射程**（case F）。
5. **`--no-x` 无关**：本步不依赖 X（纯文件读）⇒ 不受 `verify-all --no-x` 影响。
6. **步名折叠**：`run_step` 的回退重试只在 `MSB3021|MSB3027|...` 命中时发生 ⇒ 本步**不会**被重试（无 `dotnet`）⇒ 读数可复现。

---

## §10 `NOINFO` / 未测清单（**不许当绿**）

| 项 | 为什么没取到 | 本件改用了什么 |
|---|---|---|
| **`CS0579` 的端到端私有 obj 复现** | **零 `dotnet` 硬约束** | 引用 `#20` 的既有归档读数（**注明是引用，不是本件读数**）；本步只判"接线在不在" |
| **`BuildHygiene.props` 的份数 / 同名截胡实例**（§9.3） | —— | **本件已核**：`find . -name 'BuildHygiene.props'` ⇒ **1 份**（仓根）⇒ 该边界今天无实例 |
| **`verify-all.sh` 接线后的实际步数与全绿读数** | 该件是 W27B 写域、本件窗口内**正在被改** | 只给**锚文本**与步数**预测**（14 → 15，若 W27D 也接线则 16）；**实际读数 = 主控波尾取** |
| `known-red.json` 的 `generation.id` 在 `#27` 波尾是否推进 | 本件不接线、不是本件的判据 | 只报现值 `id=#23`（现场读），**不推测** |
| 本件与 `W27D`/`W27F` 的步号冲突 | 三条车道的接线点都指向同一段尾部 | 本件明确写"步号由主控定"，只钉**锚文本** |

---

## §11 交付与复现命令

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd "$R"
S=build/MilBridge/tools/build-hygiene-import-check.sh

sha256sum "$S" | cut -c1-16        # 2607d0ba856f169a
bash -n "$S"; echo "rc=$?"         # rc=0
bash "$S"; echo "rc=$?"            # BHYGIENE_IMPORT=PASS …（files=40 lines=40 list=40）rc=0
bash "$S" --selftest; echo "rc=$?" # BHYGIENE_SELFTEST=PASS cases=9 pass=9 fail=0  rc=0
```

**留档件**（全在 `$HOME/w27c/`，**仓外**）：
`readings/golden-40.txt`（现场实测名单）｜`readings/polarity/list-from-script.txt`（python 从脚本内独立切出的名单，与前者 `diff` IDENTICAL）
｜`readings/polarity/manual.log`（9+1 例逐例机制日志）｜`readings/zero-move.txt`（九位/`inputs_fp`/`GEN_KEYS` 的 BEFORE/AFTER 快照）
｜`readings/snapshot.sh`（零位移快照器）｜`readings/polarity/manual.sh`（逐例机制留档器）。

**本件的写域遵守情况**：新建 `build/MilBridge/tools/build-hygiene-import-check.sh` **一个文件**；
**未改**任何 csproj / `BuildHygiene.props` / `verify-all.sh` / `docs/**` / `handoff.md` / 任何基线文件 / `known-red.json` / `tline-gate.sh` / 臂日志。
**未跑** `frame-step.sh` / `verify-all.sh` / `pc-line-step.sh` / `close-wave.sh`（预登记 §6 明令）；`tline-gate.sh` **本件也未跑**（不需要）。
**未 `pkill`**；**未用 `pgrep -f`/`ps|grep` 下任何结论**（§7.3 只报现场文件 sha，不做出处归因之外的推断）。

**本件自记的一处纪律 55 踩坑（留档）**：我两次写成 `grep -rn -- 'PAT' --include='*.sh' .`，
`--` 之后的一切都是操作数 ⇒ `--include` 被当成文件名、**过滤器静默失效**，读数从 0 变成 51、从 40 变成 44。
正确写法 `grep -rn --include='*.sh' --include='*.py' -- 'PAT' .`（改正后：`BuildHygiene` 在 `.sh`/`.py` 里 **0 命中**，
并以 `baseline-sha-check` 作**阳性对照**证写法有效）。
