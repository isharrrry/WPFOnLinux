# `t22` 独立复验报告 —— `#79` 四组成对读数 ＋ `provider` 归因更正 ＋ 两域差异分类器

> **车道** `t22`（成员 `pts`）｜`attempt_id 70918678-a8bb-43b6-be4e-185be9416cb3`
> **对象** `t21`（`waveman`）的交付：`TASK-0752`／`0753`／`0754`／`0755` 四组成对读数 ＋
> `build/MilBridge/P0-w78-report.md` 的 `provider` dated 更正 ＋ `~/w79c/bin/diffclass.sh`／`diffclass-findings.md`。
> **立场**：不复述它的结论 —— 每条腿**自己现取**；每个 `sha16` **自己 `sha256sum`**；每处「两极化成立」**自己判判据域有没有被放宽**。
> **纪律**：本任务**未跑应用、未构建、未起显示**、未改任何被测件；零 `pkill`／`pgrep -f`；唯一写入 = 本文件。
> **资源闸（现取）**：`df avail_kb=99892788`｜`available_mb=8883`｜`swap_free_mb=1434`（均高于闸值 512 MB／2000 MB）。
> 我的复算沙箱 `~/w302-pts/t22/`（20 件，含两份输入的**冻结副本**与 6 份自造反极性夹具）。

---

## 0. 判词

**`verdict = needs_revision`**（9 条 findings，其中 4 条 high）。

- **被验的四组读数本身与 `provider` 更正的四项读数，我逐条现取后全部成立**（§2、§4、§6）——包括 `0752` 的 `absent` 臂语义、`179=242−63` 的算术闭合（我还给出更强的**双等式**）、`0753` 的 `NOINFO` 如实性、`0755` 我**自己重跑**得同值、`provider` 四项逐字同值。
- **判 `needs_revision` 的四条硬理由**：
  1. 🔴 **任务书点名的硬要求未满足**：分类器**自身缺反极性腿** —— 它的 `LABEL` 分支**结构上不可达**，`envclass-and-classifier.md` 声称的「腿② 纯路径 ⇒ `LABEL=1 READING=0`」**用交付件跑不出来**（§3.2 F1）。
  2. 🔴 **分类器有空域假绿**：正则零命中（`lines_A=0 lines_B=0`）⇒ 打印「**该域内：归一化后零差异**」；且交付的 `diffclass-reports-domain2.txt`（`lines_A=2 lines_B=2`）**用交付输入复现不出来**（§3.3 F2）。
  3. 🔴 **分类器过宽，且"归一化吃掉真读数"已用成对实验机器证明**：白名单键上的**数值读数**会被吃掉（§3.4 F3）。
  4. 🔴 **`X-CENSUS` 的 `NOINFO` 不成立且是手写判词**：以冻后两趟为真值是 **`X_CENSUS=PASS`**；`reason=pre-chain-baseline-absent` **不在任何仪器词表里**，且它的"处方"（链首补快照）**早已实现**；该句**已落仓**两份文档（§5 F4）。

---

## 1. 现取读数台账（每条：`artifact + field + sha16`）

| # | artifact | field | 现取值 | 我的命令 |
|---|---|---|---|---|
| 1 | `~/w79c/arms/baseold/bin/libwpfwin32.so` | `sha16`／`nm -D` | `fc60c34d51fd9247`／**550**（547 T＋3 B）／`shappbar=0`／`warea=0`／331936 B | `sha256sum`＋`nm -D --defined-only` |
| 2 | `~/w79c/arms/absent/bin/libwpfwin32.so` | 同上 | **`8857b251e74851d2`／553（550 T＋3 B）／`shappbar=0`／`warea=3`**／336528 B | 同上 |
| 3 | `~/w79c/arms/ret0/bin/libwpfwin32.so` | 同上 | `efb087b5c7c33eb2`／**551**（548 T＋3 B）／**`shappbar=1`**／`warea=0`／336096 B | 同上 |
| 4 | `$N/src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（活树权威件） | 同上 | **`e8127a3d7128d417`／554（551 T＋3 B）／`shappbar=1`／`warea=3`**／336592 B | 同上 |
| 5 | `~/w181a/w7x/bin/leg.sh`（**原件**） | `sha16`／`absent` 臂指向 | **`8a7229b963b9370d`**；`:20 absent) SHIM="$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so";;` = **活树已装符号件** | `sha256sum`＋`grep -n` |
| 6 | `~/w79c/bin/leg79c.sh`（修正副本） | `absent` 臂指向 | `~/w79c/arms/absent/bin/libwpfwin32.so`（`shappbar=0`） | `sed -n` |
| 7 | 输入 A = `/tmp/n.w78-post1-20260927-110835.log` | `sha16`／行数 | **`55c2a2b144a095ec`**＝`~/w79c/base.log`／91 行（全为 `· 自报口径`） | `sha256sum` |
| 8 | 输入 B = `/tmp/n.w78-post2-20260927-112348.log` | `sha16`／行数 | **`791c0d73bd0d606e`**＝`/tmp/d2.log`＝`/tmp/r2.txt`／91 行 | `sha256sum` |
| 9 | `~/w79c/bin/diffclass.sh` | `sha16` | **`ea992901e7d7e48f`**（1894 B）；我的冻结副本 `~/w302-pts/t22/diffclass-frozen.sh` 与之 `cmp` **IDENTICAL** | `cp -f`＋`sha256sum`＋`cmp` |
| 9b | `~/w79c/bin/normpath.sh`（**收紧版，未被 `diffclass.sh` 使用**） | `sha16` | **`88278218d455f9ad`** | `sha256sum` |
| 9c | `~/w79c/bin/leg79c.sh` | `sha16` | **`993e17408f9bd612`** | `sha256sum` |
| 10 | `build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll` | `sha16` | **`a00895e8158189b9`**／104448 B | `sha256sum` |
| 11 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:66`（`#78` 块九位行） | `provider` 格 | **`609192a419d125f2`**（与同块 6 条机读行**唯一不一致位**） | `sed -n '66p'` |
| 12 | 同块 `:74-79`（`BASELINE tier=`） | 6 条／`provider` | **6 条**，每条 `provider:a00895e8158189b9` | `grep -n '^BASELINE tier='` |
| 13 | `/tmp/bridge-frozen.flag` | `PROVIDER=` | `a00895e8158189b9`；原报告 §? 另载「两哨兵 … `PROVIDER=a00895e8158189b9` … 两处 `cmp` 逐字节相同」 | `grep -m1` |
| 14 | `build/MilBridge/P0-w78-report.md` | `sha16`／B／行 | **`71b264bf4c827137`／54894／377**（t21 声称 `948b1f495e6701e1`／34236／228 ⇒ **已变**） | `sha256sum`／`wc` |
| 15 | 同件 HEAD 版 / 备份件 | `sha16` | HEAD blob = **`4fbf9fee0bfbcc0f`**／25100 B = `~/w79c/backup-P0-w78-report.121709.md` **逐位相同** | `git show HEAD:…` |
| 16 | `build/MilBridge/HANDOFF-NEXT.md` | `sha16` | **`1a04bf8d78c4156e`** ✓ 与 t21 声称相同 | `sha256sum` |
| 17 | `build/MilBridge/tools/proto-attribution-{check.sh,cases.tsv}` | `sha16` | `62e46ff230f5c2cc`／`ebb775d21b225939` | `sha256sum` |

---

## 2. `TASK-0752`（三臂）——**成对性成立，但一条归因误导**

### 2.1 实际命令与臂来源件（现取复核）

- 实际命令（`~/w79c/bin/leg79c.sh:42` 逐字）：`bash ~/w79c/bin/leg79c.sh <tag> <arm> 30 <DIAG>`；`WDISP=:232`。
  每条腿的臂件路径与 `sha16` **由装置自己写进** `legs/<tag>/meta.txt`（`SHIM_SRC=`／`SRC16=`／`INSTALLED16=`／`MATCH=yes`），我逐件现算核对 ⇒ 与 §1 的 1–3 行**逐位一致**。
- ✅ **`absent` 臂语义（`#78` 点名的反转风险）—— 本副本上不成立、原件上成立**：
  - 原件 `~/w181a/w7x/bin/leg.sh:20` 的 `absent` 指向 **`$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so`** = 活树**已装符号件**（现取 `e8127a3d7128d417`／`shappbar=1`）⇒ **语义反转确认**，且原件 `sha16 8a7229b963b9370d`、mtime `09-26 22:18`（**早于** t21 会话）⇒「原件未动」成立。
  - 修正副本指向 `arms/absent/…`（`8857b251e74851d2`／**`shappbar=0`**／`symbols_n=553`）⇒ **是"未装该符号"件，不是旧路径、也不是已装符号件** ✓。
- **导出面自洽（我加的一条交叉核对）**：`550 ＋ 3(warea) ＋ 1(shappbar) = 554` = 活树权威件现取符号数，且 `T` 计数 `547＋3＋1 = 551` 与 `nm` 逐位吻合 ⇒ 三臂＋活件是**同一构建谱系**的四个点，不是四个不相干的件。

### 2.2 `242` / `179` / `63` 的算术闭合（**我自己现算，给出比原文更强的双等式**）

```
C79-baseold-diag1 总字节 = 3808 ；其中 EntryPointNotFoundException 行 = 242 B（含 LF）
C79-ret0-diag1    总字节 = 3629 ；其中 [APPBAR_DIAG] 行          =  63 B（含 LF）
3808 − 242 = 3566     3629 − 63 = 3566     ⇒ 两侧「共同诊断体」**字节数相等**
3808 − 3629 = 179 = 242 − 63               ✔
```
- `[APPBAR_DIAG]` 行逐字（`C79-ret0-diag1/appbar.line`）：`[APPBAR_DIAG] msg=4 cbSize_in=0 rc_work=0,0 1280x1024 return=0`，`stat -c%s` = **63** ✓
- `242` 同时是 `baseold-diag0` 的**总字节**（`stat -c%s app.both` = 242）与 `baseold-diag1` 里那条 EPNF 行的字节数 ⇒ 两处一致（我分别 `stat`＋`split('\n')` 量得）。
- ⚠️ **归因有误（F5）**：`report-additions.md:22` 写「与旧件恒差 **+115**（件身份：553 vs 550 symbols）」。我用 `difflib` 对该两文件做**逐字节**对比，+115 是**一整行**：
  `+ [G147_WORKAREA] source=fallback-screen GetMonitorInfo mon=0,0,1280,1024 work=0,0,1280,1024 prop_present=0 prop_n=0`，该行 **114 B ＋ LF = 115 B** ⇒ 差值来自 **D-G147 的诊断行**，不是"符号计数差 3"本身。
  **成因**：`absent` 臂比 `baseold` 多带 **3 个 `wpf_x11_workarea_{src,prop,declare}` 导出** ⇒ 它**不是** `baseold` 的单变量对（差 3 个符号）；**唯一干净的单变量对是 `baseold ↔ ret0`（只差 `SHAppBarMessage` 1 个）**，而这正是 `TASK-0747` 两极化要的那一对 ✓。

### 2.3 机读面缺陷（F6）

`leg79c.sh:70` `g(){ grep -ac "$1" "$OUT/app.both" 2>/dev/null || echo 0; }`
⇒ 零命中时 `grep -c` 打 `0` **且** `|| echo 0` 再打一个 `0` ⇒ 命令替换得**两行**，`result.env` 被撕裂，例如：
```
HC_UNHANDLED_N=0
0 ENTRYPOINT_NOTFOUND_N=1 STACKOVF=0
```
**不影响本次 `BYTES` 读数**（来自 `stat -c%s`），但**机读面已污染**：任何逐行解析 `result.env` 的下游都会误读。

---

## 3. 两域差异分类器（🔴 本节是本趟判 `needs_revision` 的主因）

### 3.1 两个域的正则（逐字现取）与它们**真的用同一份输入吗**

| 域 | 正则（逐字） | 在**交付输入**上的行数 | t21 报告的行数 |
|---|---|---|---|
| ① | `^ *· 自报口径` | `lines_A=91 lines_B=91` ✓ | 91／91 ✓ |
| ② | `步骤通过\|结论：` | **`lines_A=0 lines_B=0`** | 2／2 ❌ |

⇒ **两域没有用同一份输入**：域① 用的是 `~/w79c/base.log`（A）＋ `/tmp/d2.log`（B）**的 `· 自报口径` 抽取件**；域② 用的是**全量日志**，而**那两份全量日志不在 `~/w79c/`、也不在 `/tmp`**（现取：91 行的抽取件里 `步骤通过|结论：` 命中 **0**）。⇒ **`diffclass-reports-domain2.txt` 用交付件不可复现**（F2）。

### 3.2 我自己造的**正极性腿**（任务书硬要求）—— 我跑的是**交付件本身**

夹具都从**真日志**派生，逐条 `diff` 先证明"只改了一处"：

| 腿 | 改什么 | 我实跑读数 | 判定 |
|---|---|---|---|
| **R（读数）** | `base.log` 里 `judged_min=615` → `616`（`GATE_COLUMN` 行） | `lines_A=91 lines_B=91 NORMALIZED_DIFF_LINES=2` ⇒ **`环境/标签类=0 读数类=1`**，逐条点名 `GATE_COLUMN` 并给出两侧值 | ✅ **有判别力** |
| **L（纯路径）** | `base.log` 里 `outdir=…tline-gate-20260927-111025` → `…-999999` | `NORMALIZED_DIFF_LINES=0` ⇒ 打印「**该域内：归一化后零差异**」后 **exit 0** | ❌ **`LABEL=1` 不产生** |

⇒ **F1（high）**：`envclass-and-classifier.md` 的「腿② 负极性：真日志只改一处纯路径 `outdir=…-111025 → …-999999` ⇒ **`LABEL=1 READING=0`** ✔」**用交付件复现不出来**。机制（读代码即可证）：
- `diffclass.sh:7-11` 先对**整个文件**做归一化，`:14` 再 `diff`；两条被 `diff` 报为 `<`/`>` 的行**按定义不相等** ⇒ `:24` 的 `LA[i] = LB[i]` 分支（LABEL）**结构上不可达**（除按位置错配的偶合）；
- 归一化后差异为 0 时 `:16` 直接 `exit 0`，**根本不进分类**。
⇒ `diffclass-findings.md` 的「标签类 **5 对**」同样**不是交付件产出的**（它来自一个**未交付的两阶段**过程：先只归一化时间戳得 9 对，再归一化路径）。**该 5 对的名称我确认为正确**（我逐对读了两侧原文：`TLINE_GATE`／`COLUMN_FLOOR_SELFREPORT`／`FRAMEPRESENCE`／`THIRDPARTY_BUILD`／`THIRDPARTY_IMAGE` 五对只差路径），**但"交付的分类器有判别力"这句话没有机器证据支撑** —— 而这正是本趟硬要求要的东西。

### 3.3 空域假绿（**F2, high**）

```
bash diffclass-frozen.sh A B 'ZZZ_NO_SUCH_TOKEN'
⇒ DOMAIN_RE=ZZZ_NO_SUCH_TOKEN  lines_A=0 lines_B=0  NORMALIZED_DIFF_LINES=0
   ⇒ 该域内：归一化后**零差异**
```
⇒ **正则零命中被读成"零差异=通过"**。这违反本仓成文纪律「解析任一侧为空 ⇒ 不许静默判等」（纪律 27），也是「假绿」的**标准形态**：把域写错（或域内一条都抽不到）不会有任何红。

### 3.4 分类器**过宽**：我用成对实验把它变成机器事实（**F3, high**）

| 夹具（都从真日志派生） | 唯一差异 | 实跑读数 | 期望 |
|---|---|---|---|
| `L3e/L3f`：A 行尾加 `file=97`，B 行尾加 `file=96` | **只有** `file=` 下的**数值 97↔96** | `NORMALIZED_DIFF_LINES=0` ⇒ **「零差异」** ❌ | 必须判读数类 |
| `L3g/L3h`（对照）：同值放**非白名单键** `n97=97`／`n97=96` | 只有该数值 | `NORMALIZED_DIFF_LINES=2` ⇒ **`读数类=1`** 并点名 ✅ | 判读数类 |

⇒ `diffclass.sh:9` 的 `(outdir|dir|log|path|file|SNAPSHOT)=[^ |]*` **不要求值以 `/` 开头** ⇒ **白名单键上的任何数值都会被当成路径吃掉**。这正是任务书点名的"路径型正则把读数当路径吃掉"。
⚠️ **但必须如实说清**：在**这两份真日志的实际语料**上，白名单键的值**全部真是路径**（`outdir=/…`／`dir=/…`／`log=/…`／`path=/…`，另一条 `DISK_HEADROOM` 的 `paths=2` 不匹配 `path=`）⇒ 本次四对读数**没有被吃掉**（我逐一核过，见 §3.5）。所以这是**潜在**通道，不是本次的既成错判；但**收紧版规则已经写好却没被用**：`~/w79c/bin/normpath.sh` 用的正是 `\b(outdir|…)=(/[^ |]*)`（要求值以 `/` 开头）并**删掉了** `-<6 位数字>` 规则 —— **`diffclass.sh` 里用的仍是旧宽松规则**（`:9` 与 `:11` 两处）。

### 3.5 它报的四对读数，我逐对独立复核（**成立**）

| 对 | A（`55c2a2b144a095ec`） | B（`791c0d73bd0d606e`） | 该行其余字段 |
|---|---|---|---|
| `THIRDPARTY` | `frames=42 … dir=/home/links-dev/w37-tpm-112218` | `frames=43 … dir=/…-113650` | 其余逐字相同 |
| `DISK_HEADROOM` | `avail_gb=97 avail_kb=101822300` | `avail_gb=96 avail_kb=100996644` | 其余逐字相同 |
| `R_GATE` | `mem_mb=5778` | `mem_mb=5492` | 其余逐字相同（含 `win32shim=e8127a3d7128d417`） |
| `ALIAS` | `wall_s=5.46` | `wall_s=5.61` | 其余逐字相同 |

- 我用 `diff` 现取得 **18 行原始差异 ⇒ 9 对**，与 `diffclass-findings.md` 的「91 行 vs 91 行、18 行 ⇒ 9 对」**一致** ✓；四对读数与五对路径**逐对核过** ✓。
- **判据域有没有被放宽？** —— 域①的**四对读数全部不参与任何判据**这一结论我**独立复核成立**：两趟的判词行（域②）在**同样的两趟**里是「51 ❌ 0」——但见 F2：域②用的是**另外两份未交付的输入**，所以「域② 零差异」这句话**我无法用交付证据证实**（我只能在交付输入上得 `lines=0` ⇒ 见 F2）。
- 另需点明的口径（不是缺陷，但引用时必须带）：`PROTO_ATTR_GATE=PASS` 的 18 行里 **`noinfo=13`** ⇒ 「PASS」**不等于**「18/18 有判据」。

---

## 4. `TASK-0753`／`0755` —— 两极化成立，`NOINFO` 如实

| 项 | 我的现取 | 判定 |
|---|---|---|
| **0753 首趟** | `~/w79c/logs/0753.driver.log`：三腿全 `G147=NOINFO reason=no-x` ＋ `LEG=… rc=3`，且 `XPROP_...=xprop: unable to open display ':238'` ⇒ **原因与现象一致** | ✅ **如实 NOINFO，未被读成绿**；且**可判**（不是"不可判"）：起因是装置没起显示位，**同趟**自起 `Xvfb :238` 后即得 PASS/FAIL |
| **0753 二趟** | `logs/0753b.log` 自报 `ARM_POS=… sha16=e8127a3d7128d417 shappbar=1`／`ARM_NEG=… sha16=fc60c34d51fd9247 shappbar=0`；正向三腿 `G147=PASS`；反向三腿 `G147=FAIL` —— 我逐腿读落盘件：`…_absent.txt`=`no-declared-source(silent-identity)`、`…_set.txt`=`rcWork!=_NET_WORKAREA`、`…_malformed.txt`=`no-declared-source(silent-identity)` | ✅ 两极化成立；臂来源件与 `sha16` 我**独立 `sha256sum` 复核** ✓ |
| **0753 判据域（如实）** | 反向三腿里 **2/3 腿**的失败原因是**"源不存在"**（`no-declared-source`），只有 `set` 腿是**"值不对"** ⇒ 反极臂与正极臂**不是同一机制的镜像**（缺特征 vs 算错值）。这是**正向的设计**（"缺就该红"），但引用时**不许**读成"反极证明判据能抓错值"——只有 `set` 那一腿能那样读 | ⚠️ 观察项（非缺陷，须随读数一起写） |
| **0755** | 我**自己重跑**：`bash build/MilBridge/tools/proto-attribution-check.sh --cases … --expect 18` ⇒ `PROTO_ATTR_GATE=PASS examined=18 mismatch=0 bad_expect=0 posctl=2/2 cut_and_pair=1`；`PROTO_ATTR_ROSTER … ident_absent=18`；逐行 `sock_id=present`；`N-NOPAIR` 行 `sym_call=none SYM_ONLY=never-sufficient` | ✅ 与 t21 声称**逐字同值**（我的 roster 带 `at=2026-09-27T13:33:08+08:00` ⇒ 是**我这趟**的读数） |

---

## 5. `TASK-0754`（显示号租借 ＋ `X-CENSUS`）—— 一处**不成立**的判词

### 5.1 `X-CENSUS` 的**真值**（以冻后两趟为准，逐字）

```
/tmp/n.w78-post1-20260927-110835.log  sha16=55c2a2b144a095ec
  · 自报口径 X_CENSUS_COUNTS base_live=0 now_live=1 base_socks=2 now_socks=3 own=:99 preexisting_dead_sock=2 new_orphan_sock=0 leaks=0
  · 自报口径 X_CENSUS=PASS leaks=0 new_orphan_sock=0 base_live=0 now_live=1 base_socks=2 now_socks=3
/tmp/n.w78-post2-20260927-112348.log  sha16=791c0d73bd0d606e
  · 自报口径 X_CENSUS=PASS leaks=0 new_orphan_sock=0 base_live=0 now_live=1 base_socks=2 now_socks=3
```
⇒ **两趟逐字相同、都是 `PASS`**（不是 `NOINFO`）。

### 5.2 🔴 **F4（high）**：`P0-w78-report.md:200` 的 `NOINFO` 三处不成立

原文（现取逐字）：
> **`X-CENSUS`**：冻后两趟现取 `X_CENSUS=PASS …` ＋ `X_CENSUS_SNAPSHOT=PASS path=/tmp/w75-xcensus.mcYHsf …`；**链前基线仍缺 ⇒ `NOINFO reason=pre-chain-baseline-absent`**（要变可判＝`verify-all` 链首补一次快照）。

1. **自相矛盾**：`X_CENSUS=PASS` 这个判词**本身就是"有基线且对上了"的产物** —— `verify-all.sh:468-473` 逐字：
   `# ── 【#75 TASK-0739 修法②：**链前基线**（本趟任何显示位被起**之前**取）】──` ＋ `X_CENSUS_BASE="$(mktemp /tmp/w75-xcensus.XXXXXX)"` ＋ `xvfb-census-check.sh --snapshot "$X_CENSUS_BASE"`；`:1183` 的步 `run_step "X-CENSUS" … --baseline "${X_CENSUS_BASE:-/dev/null}"`。
   ⇒ **本趟 verify-all 的链前快照早已在位**（`X_CENSUS_SNAPSHOT=PASS path=/tmp/w75-xcensus.mcYHsf` 就是它）。
2. **`reason` 串不在仪器词表里**：`xvfb-census-check.sh` 只产 `:95 NOINFO reason=baseline-absent` 与 `:97 NOINFO reason=baseline-format-unknown`；
   `grep -rln 'pre-chain-baseline-absent'` 全盘命中 **3 件**：`~/w79c/report-additions.md`、`build/MilBridge/P0-w78-report.md`、`build/MilBridge/HANDOFF-NEXT.md` —— **全是散文件**。⇒ 这是**手写判词冒充仪器判词**。
3. **它给的处方已经实现**（「要变可判＝`verify-all` 链首补一次快照」）⇒ 读者照它去"补"会白做。
   **真实缺口**（我核实后仍存在，且**是另一件事**）：**跨整条 close-wave 链**的基线没有 —— `grep -c 'snapshot' build/close-wave.sh` = **0**。

**方向是保守的**（把 PASS 说成 NOINFO，不是把 NOINFO 说成绿），但该句**已落仓两份文档**，且会让"跨链基线"这条真缺口被一个假缺口掩盖。

### 5.3 它同趟报的两处仪器缺陷（我逐条现取核实，**成立**）

| 它说 | 我现取 | 判定 |
|---|---|---|
| `display-lease.sh:413` stderr 现 `local: 只能在函数中使用` | `:413` 逐字 = `        local cur_owner`，且它所处的 `for … do` 体内**没有函数边界**（上一处 `fi` 结束的是 `if`，不是函数）；该行**在函数外** | ✅ 成立 |
| `reason=pool-exhausted` 用于"整池在白名单外" | `:446/:448` `fail "pool-exhausted" …`（池用尽）与 `:372/:381` `noinfo "pool-out-of-whitelist" …`（池外号）是**两条不同的路** ⇒ 报告所说"应更准确写作 `pool-out-of-whitelist`"的**改写方向与代码不符**：`pool-exhausted` 是**该路的正名**；真正需要的是**确认它没有被用在池外场景** | ⚠️ **部分不成立**（措辞指错）：应为"两条 reason 不许混用"，而不是"前者应改名为后者" |
| `DISPLAY_LEASE_GATE=PASS static=3/3 dynamic=11/11 examined=14 dev_sha16=b12fc3c0fd3d352f` | 我未重跑该闸（它要起私有显示位 ⇒ 属重活，本趟按纪律未占槽）⇒ 该行**只作成对证据存在性核对**（`~/w79c/report-additions.md` §9.3 有逐行读数） | ⚠️ **`NOINFO`（不可判）**：见 §7 第 3 条 |

---

## 6. `provider` 归因更正 —— **四项读数逐条同值；但 §8 的"根因"与现件不符**

### 6.1 四项读数（独立重算，全部同值）

| # | 读数 | 主控给 / t21 给 | **我现算** | 一致？ |
|---|---|---|---|---|
| 1 | 权威件 `sha16` | `a00895e8158189b9` | **`a00895e8158189b9`**（104448 B） | ✅ |
| 2 | `build/` 下同名副本份数 | 58 | **58** | ✅ |
| 3 | 其中同此值份数 | 45 | **45**（其余：`df619a05ca0d10c9`×4／`9aa0d744802aaa31`×4／`2d5f72721ab4ac95`×2／`1d095db667206b9e`×2／…） | ✅ |
| 4 | `609192a419d125f2` 在现树 `*.dll`/`*.so` 命中 | 0 | **0** | ✅ |

**我另加的两条独立交叉核对**：
- **同块 6 条机读行**：`#78` 块（`:7`–`:79`）内 `^BASELINE tier=` = **6 条**（`:74-79`），**每条**都写 `provider:a00895e8158189b9` ✓（「不是 7 条」也对）。
- **逐位对账（九位行 vs 同块机读行）**：`bridge`／`pc`／`pf`／`win32shim`／`wic_shim`／`hbtextline` **六位一致**；**唯一不一致位 = `provider`**（九位行 `609192a419d125f2` vs 机读行 `a00895e8158189b9`）⇒ 更正**精确指向唯一错位** ✓。哨兵侧：`/tmp/bridge-frozen.flag` 现取 `PROVIDER=a00895e8158189b9`，且原报告载两哨兵 `PROVIDER=a00895e8158189b9` ×「两处 `cmp` 逐字节相同」✓。
- **原文一字未改（`git diff` 现取证明只增不改）**：
  `git show HEAD:build/MilBridge/P0-w78-report.md` = **25100 B／`4fbf9fee0bfbcc0f`**，与 `~/w79c/backup-P0-w78-report.121709.md` **逐位相同**（`sha256sum` 全值比对）；
  `git diff --numstat` = **`234  0`**（**0 删**）；`git diff -U0 | grep -c '^-[^-]'` = **0**，`'^+[^+]'` = 190。
  ⇒ ✅ **"只增不改"成立**（且对"t21 那一笔"也成立：合并集无删除 ⇒ 任何子集无删除）。

### 6.2 🔴 **F8（medium）**：§8 的"根因"句与现件不符

原文（`report-additions.md` §8 逐字）：
> **根因**：`GENS` 核验键表**不含 `provider`** ⇒ 冻结器从未核过这位（`D-G149` 同族）。

现取 `~/w21-verify/w27-freeze.py`：
- `:1210-1220` `_FORM_NINE = { … 'provider': '`provider` `([0-9a-f]{16})`', … }` —— **含 `provider`**（九位**九键全在**）；
- `:1222-1225` `_TIER_KEY` 把机读行键映到九位键，**含 `'provider': 'provider'`**；
- `:1229-1258` `check_block_values()` 对 `_FORM_NINE` **逐键**与现取值比对，出 `VALUE-MISMATCH key=… 块内=… 现取=…`；机读行出 `TIER-VALUE-MISMATCH`；并有 `LIVE-MISSING …（现取字典里没有这个键 ⇒ 判据无从成立，不许当绿）`；
- `:1207-1209` 表头注释逐字：该表由 **`TASK-0745` 落地／`D-G166`**（**2026-09-27**）建立，比的是「**本文件自己现算的 `now`**」；
- 同件 `:234-235` 已注明：**`#78` 九位行的 `provider`/`wic_shim` 两格是模板写死的字面量、`provider` 那格已证错 ⇒ 取哨兵/机读行的现取值**（`:238 prev_provider='a00895e8158189b9'`）。

⇒ 「根因 = 键表不含 `provider`」作为**现状陈述不成立**（键表**现在含**它，且会逐值核）；该句没有区分「**`#78` 冻结当时**（00:36）核验表尚未覆盖」这个**时间点事实**，也没有记「**缺口已由 `TASK-0745`／`D-G166` 补上**」——**读者会以为缺口还在**。两条都属于"取证时没有复核被引用件的现状"。

### 6.3 落仓 `sha16` 已失效（**F9, low**）

t21 声称落仓值 `sha16 948b1f495e6701e1`／34236 B／228 行；**我现取 `71b264bf4c827137`／54894 B／377 行**（mtime `09-27 13:32`）⇒ **落地之后又有追加**（不是 t21 那一笔；`git diff` 仍是 `+234/−0`，即**合并后仍只增不改**）。⇒ 落仓读数必须标 **dated ＋ 现取可复算**，或注明"本值在后续追加后失效"。

---

## 7. 我**没能**判的（`NOINFO`，逐条给原因——不许当绿）

1. **`0754` 的 `DISPLAY_LEASE_GATE=PASS static=3/3 dynamic=11/11 examined=14`** —— **不可判（本趟）**：该闸要起私有显示位夹具（重活），本趟纪律未占槽；我只核到「成对读数在 `~/w79c/report-additions.md` §9.3 有成文原样 ＋ 装置件存在」。
2. **域②（`步骤通过|结论：`）的"零差异"** —— **不可判**：交付输入上该域命中 **0 行**（见 F2），其**真输入未交付**。
3. **`0752` 里 `ret0` 臂的语义（"返回 0 的 stub"）是否算"真实现"** —— **不可判**：`[APPBAR_DIAG]` 行只给 `msg=4 cbSize_in=0 rc_work=0,0 1280x1024 return=0`；`cbSize_in=0` 本身可疑，但**这一格要与真实现臂对照才有意义**，而三臂里没有"真实现"臂（活件 `e8127a3d7128d417` 只在 `0753` 里当正极件用）⇒ 该格 `NOINFO`。
4. **`0754` 的两处仪器缺陷的"改法"是否完整** —— **部分不可判**：`pool-exhausted` 那条我判定"改写方向与代码不符"（§5.3），但**"是否有池外场景误用**"需要跑该闸的动态档才能定 ⇒ `NOINFO`。
5. **`X_CENSUS_SNAPSHOT=PASS path=/tmp/w75-xcensus.mcYHsf`** 这份快照文件**已不在**（`/tmp` 已被后续运行覆盖），故无法核"快照当时的内容"⇒ 只核到**两趟日志里的判词**（= 真值）。

---

## 8. 落仓面自证

- 本任务的**唯一写入件** = 本文件 `build/MilBridge/t22-report.md`。
- 未改被测件：`P0-w78-report.md`／`appbar-startup-ledger.tsv`／`verify-all.sh`／`close-wave.sh`／`samples/**`／`src/**`／`docs/**` 一字未动（`git status --porcelain` 属我名下**只**本文件）。
- 分类器与装置件**只读**：我跑的是 `~/w302-pts/t22/diffclass-frozen.sh`（`cp -f` 的冻结副本）与 `~/w302-pts/t22/` 里的夹具副本；`~/w79c/**` 与 `/tmp` 原物**只读**（并把 `/tmp/dc_*.txt`、`/tmp/d2.log` 在做任何重跑**之前**复制留档 —— 因为 `diffclass.sh` 用的是**固定共享 `/tmp/dc_*.txt`**，重跑会覆盖它们，见 F7）。
