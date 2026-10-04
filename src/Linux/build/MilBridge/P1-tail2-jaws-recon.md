# P1 尾波 2 · 两颗新牙侦察（`SJC-FIELD-ID` 弱版 ＋ 静默阈值禁令 `R-7`）

> **只读侦察件**（`T-D0`）：除本件外**未改任何仓内文件**、未构建、未跑腿、未占显示位、未起进程、未 `git add/commit/push`。
> 所有读数**现取现算**；行号一律标「**仅本次有效**」，同时给**内容锚**（件:锚）。
> **读取时刻**：`ts=2026-09-30T00:27:51+08:00`；分支 `feat-Linux`。
> **本件现取四数（口径写死）**：`grep -c '^run_step "' verify-all.sh` ＝ **62**｜`fp_inputs()` 覆盖面件数 ＝ **234**｜第 `[42]` 步 `--expect` ＝ **234**｜首行 `DECL` ＝ **`# VERIFYALL-STEPS-DECL: 62 gen=#81`**。
> **未跑** `static-jaws-check.sh`（边界条款）；**未跑** 整趟 `verify-all`。
> **上游出处**：`TASK-0756`（`SJC-FIELD-ID` 弱版）／`TASK-0757`（静默阈值禁令）＝ `docs/ROUTES.md` 现取 `:406`／`:410`；反例 `t194` 与草案在 `build/MilBridge/P1-field-identity-report.md`（`t197`）与 `build/MilBridge/P1-HANDOFF-20260929.md §12`（`R-2`／`R-7`）。

---

## §1 落点与接线点表（逐条：目标件 ＋ 现取定位 ＋ 改动形态）

### 1.1 两颗新牙（**新建件**，写域 `build/MilBridge/tools/**`）

| 牙 | 建议件名（新） | 现取状态 | 判据（草案，逐字见 §4） |
|---|---|---|---|
| `TASK-0756` `SJC-FIELD-ID` 弱版 | `build/MilBridge/tools/sjc-field-id-check.sh` | **不存在**（`ls build/MilBridge/tools/ \| grep -iE 'sjc\|field-id'` ＝ 0 命中） | 判「证据行是否**同给**「结构偏移 ＋ 写点」两要素」 |
| `TASK-0757` 静默阈值禁令（`R-7`） | `build/MilBridge/tools/silent-threshold-ban-check.sh` | **不存在**（`grep -iE 'thresh\|silent-thr'` ＝ 0 命中） | `grep -cE '(if\|&&).*>[[:space:]]*[0-9]+.*fprintf'` 命中即红；缺省行 token 统一 `no-leg` 形制 |

> ⚠️ 件名为**建议**（`docs/ROUTES.md:409`／`:413` 只写「写域 `build/MilBridge/tools/**`（新牙）＋ `verify-all` 步＋`close-wave` 覆盖面」），最终命名由实现件定；本件的接线点表按**件路径身份**给锚，命名变更不改变接线形态。

### 1.2 接线点（**逐条现取位置**；行号仅本次有效）

| # | 接线点 | 件（现取路径） | 现取定位（行号 仅本次有效 ＋ 内容锚） | 改动形态 |
|---|---|---|---|---|
| ① | `run_step` 表 | `verify-all.sh`（**仓根**） | `:1234`＝最后一条 `run_step`（内容锚 `run_step "STATIC-JAWS"`）；其后 `:1235`＝`# W168A-0724-END` | **追加 2 行** `run_step "<步名A>" bash build/MilBridge/tools/sjc-field-id-check.sh` / `run_step "<步名B>" bash build/MilBridge/tools/silent-threshold-ban-check.sh`（**落在末步之后、`# W168A…-END` 之前**；**步号不写死**） |
| ② | 首行 `DECL` | `verify-all.sh` | `:73`（内容锚 `# VERIFYALL-STEPS-DECL: 62 gen=#81`；`sed -n … \| head -1` 取**第一条**） | 新追加一条（**行首**）`# VERIFYALL-STEPS-DECL: 64 gen=#NN   ← …`（`62 → 64`；**既有史实行只追加、不改动**，纪律 61 同族） |
| ③ | 头注释**口径句** | `verify-all.sh` | 头部注释区（内容锚 `#   **`#81` 收官起 = 62 步**`；**动态取**＝文件里含「收官起 = N 步」的注释块） | **追加一行** `#   **`#NN` 收官起 = 64 步**（…同趟 +2 步…）`（插在**写前现取的头部口径区之内**） |
| ④ | `STEP-NAMES` | `verify-all.sh` | `:126`（内容锚 `# VERIFYALL-STEP-NAMES:`；行**以 `STATIC-JAWS` 结尾、无尾随换行**） | 尾部追加 ` \| <步名A> \| <步名B>`（62 → **64** 项） |
| ⑤ | `fp_inputs()` 覆盖面白名单 | `build/close-wave.sh` | 白名单尾＝`:396`（内容锚 `            build/MilBridge/tools/static-jaws-check.sh`）；紧随 `:397`＝`    } \| LC_ALL=C sort \| xargs sha256sum \| sha256sum \| cut -d' ' -f1` | **追加 2 行**（两颗牙的**件路径身份**，不用 glob）—— **必须在 `:397` 的 `}` 闭合之前**；**新增行须留在 `\` 续行参数表内**（注释只能放**语句之前**） |
| ⑥ | 第 `[42]` 步 `--expect` | `verify-all.sh` | `:1201`（内容锚 `run_step "FP-MANIFEST-TEETH" bash build/MilBridge/tools/fp-manifest-step.sh --expect 234`） | `--expect 234 → 236`（**声明常数**；覆盖面变 ⇒ **同趟**改） |
| ⑦ | 预登记 | `docs/WAVE<NN>-PREREGISTRATION.md` | 最新＝`docs/WAVE81-PREREGISTRATION.md`；`PREREG4` 硬形态行＝`PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-only-wave-81` | **新建/追加**本波预登记（含四处声明的逐字记录 ＋ §3.1 回归判定段） |
| ⑧ | `HANDOFF-MV` 9 格（`cell=#1`／`#2`／`#5`） | `build/MilBridge/HANDOFF-NEXT.md` | 现取「机器值契约更正」块（`t48`／W4b，读时 `2026-09-28T17:49:01.698+0800`）：`cell=#1`＝`inputs_fp`（命令 `bash ~/w153a/bin/infp.sh fp`）｜`cell=#2`＝覆盖面件数（命令 `… infp.sh list \| wc -l`，现值 `233`）｜`cell=#5`＝`grep -c '^run_step "' verify-all.sh`（现值 `61`） | **同趟追写** `机器值契约更正 · cell=#1`（新 `inputs_fp` ＋ `ts=`）＋ `cell=#2`（件数）＋ `cell=#5`（`run_step` 数）—— **维护契约逐字见 §5** |

**现取读数（本件跑的命令，可复跑）**

- 步数：`grep -c '^run_step "' verify-all.sh` ⇒ **62**
- 覆盖面件数（现取活清单）：`sed -n '/^fp_inputs()/,/^}$/p' build/close-wave.sh | sed 's#^    } | LC_ALL=C sort.*#    } | LC_ALL=C sort -u | wc -l#' > /tmp/fp2.sh; printf 'fp_inputs\n' >> /tmp/fp2.sh; bash /tmp/fp2.sh` ⇒ **234**
- `--expect`：`grep -n 'run_step "FP-MANIFEST-TEETH"' verify-all.sh` ⇒ `:1201 … --expect 234` ⇒ **234**（与上一条**相等**，故 `FP_MANIFEST_TEETH` 现取应为 `PASS`）

> ⚠️ **口径**：`--expect N` 是**步本体里手写的显式常数**，`verify-all.sh` **不在**覆盖面 ⇒ 该常数与生产路径无关，但**必须与 `fp_inputs()` 现取件数相等**（不等 ⇒ `FAIL reason=files-n-mismatch`，方向安全）。

---

## §2 `SJC-FIELD-ID` 弱版（判「证据行是否同给『结构偏移 ＋ 写点』两要素」）

### 2.0 判据出处（现取原文）

- `build/MilBridge/P1-field-identity-report.md:58`（§4 草案，逐行原文）：
  `> **草案 SJC-FIELD-ID**：**凡把某字段作为证据引用，必须先给「**结构偏移 ＋ 写点**」两要素**，且写点必须落在**该结构的写入面**上。两要素缺一 ⇒ 该证据**作废**；写点与偏移**对不上** ⇒ **判红**（`reason=field-identity-mismatch`）。`
- `build/MilBridge/P1-HANDOFF-20260929.md:112-115`（`R-2`，逐行原文）：
  `**R-2 凡引字段作证据，先给「偏移＋写点」对账**（`t197` 立牙草案）` ／ `- 错法：`t194` 标 `dvr_used@+36` 却引 `win32_pts.c:1550/:1554`（子轨出参）⇒ 证据无效。` ／ `- 正确：证据行必须同时给**结构偏移**与**本侧写点**，且写点落在该结构写入面。` ／ `- 机器判据：静态牙 **`SJC-FIELD-ID`** 弱版（判"证据行是否同给两要素"）**本波即可接线**；强版需 `field-write-registry.tsv`（本波 `NOINFO`）。`
- `build/MilBridge/P1-field-identity-report.md:61`（**三要素 token 形态**，逐行原文）：
  `- **能否落成已接线牙？** **可以做，但有前置**。需要的机械面是**统一 token**：证据行须同时出现 `field=<名>`、`off=<结构偏移>`、`write=<文件:行>`（例 `field=pfspara off=+8 write=win32_pts.c:3713`）。本波已有 `off_pfspara=8`／`off16=16`／`idx0_`／`slotN_` 等**部分**形态。`

### 2.1 正面样本（**逐行原文**，同给两要素；≥2）

- **P-1** `build/MilBridge/P1-field-identity-report.md:14`（§1 表 `+8` 行）：
  `| **+8** | `void *` | **`pfspara`** | ✅ **`:3713 rg[i].pfspara = (void *)para_val;`** | ❌ | ✅ 上游 `PtsHelper.cs:179 paraClient.Arrange(arrayParaDesc[index].pfspara, …)` |`
  ⇒ **偏移 token** `+8` ＋ **写点 token** `:3713`（同行）＋ 字节读回（§4 正例补「`bytes0_32` 第 9–16 字节」）。
- **P-2** `build/MilBridge/P1-field-identity-report.md:15`（§1 表 `+16` 行）：
  `| **+16** | `void *` | **`pfsparaclient`** | ✅ **`:3714 rg[i].pfsparaclient = (void *)dp->fsp_pl_cur;`** | ❌ | ✅ `PtsHelper.cs:158`（`HandleToObject(...) as BaseParaClient`，同段现取） |`
- **P-3**（§4 正例，散文形态）`build/MilBridge/P1-field-identity-report.md:59`：
  `- **正例（现取可核）**：`t181` 的 `pfspara` 证据 —— 偏移 `+8`（`:1101 _Static_assert`）＋ 写点 `:3713 rg[i].pfspara = …` ＋ 字节级读回（`bytes0_32` 第 9–16 字节）⇒ 三要素自洽。`

### 2.2 反面样本（**逐行原文**，两要素**不全**或**对不上**；≥2）

- **N-1** `build/MilBridge/P1-HANDOFF-20260929.md:44`（§6 方法学，逐行原文节选）：
  `1. **字段身份对账**：凡引字段当证据，必须先给「**结构偏移 ＋ 写点**」两要素，并与本侧写点对得上；对不上即判红。**反例就在本波**：`t194` 标 `dvr_used@+36` 却引 `:1550/:1554` 的子轨出参 ⇒ 证据无效（`t197` 已把它做成静态牙草案 **`SJC-FIELD-ID`**：弱版现在就能接线，强版需 `field-write-registry.tsv`，本波记 `NOINFO`）。`
  ⇒ 该行**同时**含偏移 `+36` 与写点 `:1550/:1554` ⇒ **弱版会判「两要素齐」＝假绿**（真错在「写点**不在该结构写入面**」，弱版**判不了**）——**这是弱版的头号边界**。
- **N-2** `build/MilBridge/P1-HANDOFF-20260929.md:113`（`R-2` 错法行）：
  `- 错法：`t194` 标 `dvr_used@+36` 却引 `win32_pts.c:1550/:1554`（子轨出参）⇒ 证据无效。`（同 N-1 形态）
- **N-3** `build/MilBridge/P1-HANDOFF-20260929.md:108`（`R-1` 错法行）：
  `- 错法：反腿①（`NODVR`）只把**子轨出参**置 0，而判据引用的是**描述符字段** `dvr_used@+36` ⇒ "必红"成立但**射程写错**，不否证目标路径。`
  ⇒ 只给偏移 `+36`、**不写点** ⇒ 弱版判「缺一要素 ⇒ 作废」（本条是**真反面**）。
- **边缘样本（`KNOWN-DEFECTS.md` 侧，供实现件定射程）** `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:669`：
  `- **它读的是编译后的 DLL 的托管堆**（不是源）。`NEW` token = `_boxOriginX`/`boxOriginX`（`D-O1` 引入，各在 `#Strings` 里**恰好出现一次**，文件偏移 `0x2b694c`/`0x2b694d`），在 `~/t1d-backups/` 的 **23 份有效旧 shim 版本中全部缺失**。`
  ⇒ 给了**字段名 ＋ 文件偏移**（`0x…`，非**结构偏移**）＋ 出现次数，**无写点**；属「**形态相近但两要素口径不同**」——**已知 `KNOWN-DEFECTS.md` 里无合格的「结构偏移 ＋ 写点」正样本**（该册是缺陷登记，不是字段身份表）。

> **射程如实划界**：合格正样本**只在** `build/MilBridge/P1-field-identity-report.md`（`t197` 的字段身份表）；`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现取**无**「结构偏移 ＋ 写点」同行样本。**现取证**（`grep -nE '\+[0-9]+.*:[0-9]{3,}' samples/WpfFeatureProbe/KNOWN-DEFECTS.md`）：命中的是**非结构偏移**形态 —— `:796` 的 `Δ=+96.000000 / +14.707031`（像素差）、`:2924` 的 `+0x11df3`（**符号地址偏移**）／`tcache_entry{next@+0, key@+8}`（**分配器内部偏移**）等 ⇒ **都不是「结构字段偏移 ＋ 本侧写点」**。⇒ 弱版**首版射程建议限定在 `build/MilBridge/**/*.md`**，`KNOWN-DEFECTS.md` 记 `NOINFO(无合格正样本/口径不同)`。

### 2.3 弱版**正则口径草案**（可判、可复跑）

**两要素 token（同一「证据单元」内须**同时**命中）**

- **偏移要素**：`(?:^|[^0-9A-Za-z_])[+]?[0-9]+(?:B)?\b`（放宽形态＝`+36`／`+8`／`off=+8`／`off=8`／`off36`）；**强形态**（推荐首版）：`(?:^|[^0-9A-Za-z_])\+[0-9]+\b`
- **写点要素**：`[A-Za-z0-9_./-]+\.(?:c|h|cs|py|sh):[0-9]+`（`file.ext:line`）**或**裸行号形态 `(?:^|[^0-9])[:@][0-9]{3,}\b`（如 `:3713`／`:1550`）；**强形态**（推荐首版）：`(?:[A-Za-z0-9_./-]+\.(?:c|h|cs|py|sh):[0-9]+|:[0-9]{3,})`

**逐行判定（首版，弱版）**

```
偏移命中 ∧ 写点命中  ⇒  两要素齐  ⇒  PASS（该证据行合规）
否则                ⇒  缺一要素  ⇒  FAIL（reason=missing-element，逐行点名 file:line）
```

> ⚠️ **首版只做「同给两要素」的合取**，**不做「对得上」**——后者需 `field-write-registry.tsv`（结构/字段/偏移/写点）作机器读者，`t197` 已判本波 `NOINFO(需字段→写点注册表)`。

### 2.4 已知假阳／假阴风险（如实登记）

| 类别 | 形态 | 影响 | 缓解 |
|---|---|---|---|
| **假阳（弱版固有）** | 反面样本 N-1／N-2：同行 `dvr_used@+36` ＋ `:1550/:1554` ⇒ 弱版判「齐」 | **判不出「写点不在该结构写入面」** ⇒ `t194` 式错法在弱版下**假绿** | **明写弱版射程**；强版（`field-write-registry.tsv`）留后续；判词须带「**粒度＝是否同给两要素，未判对得上**」 |
| **假阴（形态漏命中）** | 偏移写作 `offset=36`（无 `+`）／写点写作 `L3713`／`line 3713`／`行 3713` | 合规行被判「缺一要素」 | 首版**先现取同类行定形态**；命中 0 必须**带射程**（扫了哪些件/多少行），禁把「没扫到」当「不存在」（`L21`） |
| **假阴（跨行）** | 偏移在一行、写点在下一行（表格/换行排版） | 逐行判会漏 | 首版声明**逐行**；跨行形态记 `NOINFO(跨行单元未判)` |
| **自指污染**（`D-G130` 同族） | 牙自身／预登记件里含「定义句」，会**同时**出现 `+36` 与 `:1550/:1554` | 定义句对自己**假绿** | 证据面**声明式豁免**（豁免逐行给 `why`，超上限即红）；**射程件清单**写在件头 |
| **空集当通过**（`L25`） | 受检行数 `=0` ⇒ 恒 `PASS` | 假绿 | **防空过守卫**：受检行数 `=0` ⇒ 只许 `NOINFO`，**不许** `PASS`（条数随 `PASS` 同屏） |

---

## §3 静默阈值禁令（`R-7`）

### 3.0 判据出处（现取原文）

- `build/MilBridge/P1-HANDOFF-20260929.md:137-140`（`R-7`，逐行原文）：
  `**R-7 读数类行禁静默阈值**（`t196`／`t199` 两次咬，**恒真断言族第五例候选**）` ／
  `- 错法：只在 `consumes>0` 时打印 ⇒ 输出**看上去就是 0**，与"真 0 次"**不可区分**（把"没取到"印成"没发生"）。` ／
  `- 正确：要么**必打**、要么打**具名缺省行**（`consumes=NOINFO(reason=no-arrival-leg)`）；阈值一律删。` ／
  `- 机器判据：`grep -cE '(if|&&).*>[[:space:]]*[0-9]+.*fprintf'` ⇒ 命中即红；缺省行 token 必须**统一**（本波已把 `no-arrival-leg` 作废、统一为 `no-leg` 形制）。`
- `docs/ROUTES.md:411`（`TASK-0757` 判据，逐行原文）：
  `│   │   ├─ 目标：`grep -cE '(if|&&).*>[[:space:]]*[0-9]+.*fprintf'` 命中即红；缺省行 token 统一为 `no-leg` 形制。`

### 3.1 现取命中行（**逐行点名**）

**机器判据现取**：`grep -rnE '(if|&&).*>[[:space:]]*[0-9]+.*fprintf' .`（排除 `obj|bin|.artifacts|upstream|.git`）⇒ **写入本载体之前**全仓 **5 行命中**：**仓内 C 源码 3 行**（`wic_proxy.c`，下表）＋ `.agent-teams/wpf-linux-mvp-tail/team.json` **1 行** ＋ `.agent-teams/wpf-linux-mvp-tail/inbox/captain.jsonl` **1 行**（团队消息台账的**转义文本**，**非代码面**）。
**⚠️ 自指现取（必读）**：本载体写入后，因 §3.0／§3.1／§4.2-D2 **逐字引用**了判据行，**本载体自身**再增 **4 行**命中（`grep -cE '(if|&&).*>[[:space:]]*[0-9]+.*fprintf' build/MilBridge/P1-tail2-jaws-recon.md` ⇒ **4**）⇒ 全仓总数 **`5 → 9`**（逐件：`wic_proxy.c`=3／本载体=4／`team.json`=1／`captain.jsonl`=1）。⇒ **牙的射程必须排除「引用判据行的证据/预登记件」**（`D-G130` 自指污染同族）；否则**写一份合规的侦察件就会把自己判红**。

| # | 现取定位（行号 仅本次有效） | 命中行**原文**（逐行） |
|---|---|---|
| 1 | `build/DirectWrite.Linux/wic-shim/wic_proxy.c:1104` | `    if (getenv("WPF_LINUX_WIC_TRACE") && g_trace_budget-- > 0) fprintf(stderr, "WIC_TRACE CREATE_BITMAP_FROM_MEMORY h=%lld %ux%u stride=%u\n", (long long)h, width, height, cbStride);` |
| 2 | `build/DirectWrite.Linux/wic-shim/wic_proxy.c:1304` | `    if (getenv("WPF_LINUX_WIC_TRACE") && g_trace_budget-- > 0) fprintf(stderr, "WIC_TRACE GET_SIZE h=%lld -> %dx%d (foreign=%d)\n", (long long)(intptr_t)source, s->width, s->height, s->is_foreign);` |
| 3 | `build/DirectWrite.Linux/wic-shim/wic_proxy.c:1359` | `    if (getenv("WPF_LINUX_WIC_TRACE") && g_trace_budget-- > 0) fprintf(stderr, "WIC_TRACE COPY_PIXELS h=%lld %dx%d foreign=%d prc=%s\n", (long long)(intptr_t)source, o->width, o->height, o->is_foreign, prc_txt);` |

**🔴 关键观察（给实现件）**：这三条的阈值形态是 **`g_trace_budget-- > 0`**（**有界 trace 预算**型限流：预算耗尽即静默），**不是**读数类判别式的一个实数闸（`if (consumes > 0)`）。⇒ **直接套用 `R-7` 正则会对这三条假红** ⇒ 首版须给**声明式白名单**（逐条给 `why`＋上限），或把判据**收窄到「阈值右值非「预算递减」形态」**。**白名单与豁免的裁决权不在本只读件**，如实登记待主裁。

### 3.2 缺省行 token 统一形制（`no-leg`）现取样例

**统一目标 token（逐字）**：`consumes=NOINFO(reason=no-leg)`（`no-arrival-leg` 已**作废**）

| 现取定位（行号 仅本次有效） | 现取行原文（逐行） | 角色 |
|---|---|---|
| `build/MilBridge/P1-lm-consume-witness-criteria.md:106` | `- ✅ **正例**：`[FSPARALIST-FILL] … consumes=%d resolve_ok=%d` **无条件打印**，未取到则打 `consumes=NOINFO(reason=no-leg)` ⇒ 读的人能区分"计数为 0（真发生了 0 次）"与"没读（没取到）"。` | **目标形制（合规正例）** |
| `build/MilBridge/P1-lm-consume-close2-report.md:24` | `- **`F-3`（token 统一）**：**统一为既存 `no-leg`**（理由：以既有 token 为准 ⇒ 少改、可与既有正例逐字对拍；`no-arrival-leg` 是本席 `t200` 新造）⇒ 三件里 `consumes=NOINFO(reason=no-arrival-leg)` 的写法**作废**（**不在原处改字**，以新段为准），此后一律写 **`consumes=NOINFO(reason=no-leg)`**。` | **统一裁定逐字** |
| `build/MilBridge/P1-host-consume-route-criteria.md:229` | `- **旧写作废**：本文件 `t200` 段里 `consumes=NOINFO(reason=no-arrival-leg)` 的写法**作废**（**不在原处改字**，以此行为准）；此后缺省行一律写 **`consumes=NOINFO(reason=no-leg)`**。` | **旧写作废（就地否定）** |
| 旁证（**另一 token 族**，供实现件定射程） | `build/MilBridge/P1-lm-consume3-verify.md:112` 现取：`t198` §4:56 的具名缺省行里 token ＝ `lmwit-noarr-reverse-leg`，与 `no-leg`／`no-arrival-leg` **仍未统一**（同文件亦点名） | **未统一残留** |

> **口径**：`no-leg` 是**将来实现的机器可读命名**（`P8` 族的「具名」靠它）⇒ 同一「具名缺省行」出现**多个 token** ⇒ 实现者/复核者各执一词。首版牙**该判「token 是否为 `no-leg`」**，命中 `no-arrival-leg`／`lmwit-noarr-reverse-leg` 等 `no-*arr*leg*` 变体 ⇒ 红或 `NOINFO`（**需主裁定红/警告**）。

---

## §4 两牙的**判据预登记草案**（各 ≥3 条可证伪 ＋ 反极性）

> 供实现件照抄；每条**可证伪**（给出「喂什么 ⇒ 必红／必绿）＋ **反极性**（正极夹具 / 反极夹具）。

### 4.1 `SJC-FIELD-ID` 弱版（`build/MilBridge/tools/sjc-field-id-check.sh`）

- **C1（正极）**：喂**合规证据行**（偏移 `+N` ＋ 写点 `file:line` 同行，例 `:3713 rg[i].pfspara = …`）⇒ `SJC_FIELD_ID=PASS`。**反极性**：无。
- **C2（反极·缺一要素）**：喂**只给偏移**（如 `dvr_used@+36`，无写点）或**只给写点**的行 ⇒ **必红**，`reason=missing-element`，**逐行点名 `file:line`**。**反极性**：把该行补全两要素 ⇒ 同一夹具翻绿。
- **C3（射程／防空过）**：受检行数 `=0` ⇒ **只许 `NOINFO`**，**不许 `PASS`**；命中计数必须随 `PASS` 同屏（`L25`）。**反极性**：喂 1 行合规 ⇒ `examined=1` 且 `PASS`。
- **C4（自指豁免）**：定义句 / 预登记件若被纳入证据面 ⇒ **声明式豁免**（逐行给 `why`，超上限即红）；豁免条数 > 上限 ⇒ 红。**反极性**：删豁免 ⇒ 该定义行**必红**（证明豁免是「被看着」而非「恰好没坏」）。
- **C5（弱版边界，明写不判）**：**不判**「写点是否落在该结构写入面」（弱版固有假阳，`t194` 式行仍假绿）⇒ 判词须带**粒度**「仅判同给两要素」。**反极性**：喂 `t194` 式「齐但错面」行 ⇒ 弱版仍 `PASS`（**这是设计、非缺陷**，须与强版区分）。

### 4.2 静默阈值禁令（`build/MilBridge/tools/silent-threshold-ban-check.sh`）

- **D1（正极）**：喂**合规读取行**（无条件打，或具名缺省行 `consumes=NOINFO(reason=no-leg)`）⇒ `SILENT_THRESHOLD=PASS`。**反极性**：无。
- **D2（反极·静默阈值）**：喂**静默阈值样本**（如 `if (consumes > 0) fprintf(stderr, …)`；夹具可**自造**，`mktemp -d`，**不依赖活件**）⇒ **必红**，`reason=silent-threshold`，**逐行点名 `file:line`**。**反极性**：把 `> 0` 去掉（无条件打）⇒ 同一夹具翻绿。
- **D3（缺省行 token 统一）**：缺省行 token 须为 **`no-leg`**；命中 `no-arrival-leg`／`lmwit-noarr-reverse-leg` 等变体 ⇒ 红或 `NOINFO`（**待主裁**）。**反极性**：喂 `reason=no-leg` 正例 ⇒ 绿；喂 `reason=no-arrival-leg` ⇒ 红/`NOINFO`。
- **D4（射程／防空过）**：扫 0 件或 0 行 ⇒ **只许 `NOINFO`＋具名射程**（扫了哪些件/多少行），**不许 `PASS`**（`L21`／`L25`）。**反极性**：喂已知命中样本 ⇒ `examined≥1` 且 `FAIL`。
- **D5（白名单／豁免）**：`wic_proxy.c` 三行（§3.1）若走**声明式白名单** ⇒ 逐条给 `why`＋上限，**超上限即红**；「预算递减型」与「读数判别型」须**分开判**（否则 `R-7` 会误伤有界 trace）。**反极性**：加一条未声明的静默阈值 ⇒ **必红**。

---

## §5 同趟接线成本清单（改 `verify-all.sh`／`close-wave.sh` ⇒ 同趟连带面）

| # | 连带面 | 现取现值 | 本波（+2 步／+2 件）目标值 | 漏改后果 |
|---|---|---|---|---|
| 1 | `verify-all.sh` `^run_step "` 条数 | **62** | **64** | `VERIFYALL_SELF` 现场 ≠ 首行 `DECL`／`STEP-NAMES` ⇒ **红** |
| 2 | 首行 `# VERIFYALL-STEPS-DECL:` | `62 gen=#81` | `64 gen=#NN` | 三处声明分叉 ⇒ `FAIL`（缺声明 ⇒ `NOINFO rc=2`） |
| 3 | 头注释口径句（`#NN` 收官起 = N 步） | `… = 62 步` | `… = 64 步` | 与现场条数分叉 ⇒ `FAIL` |
| 4 | `# VERIFYALL-STEP-NAMES:` 项数 | **62** | **64**（尾部追加两步名） | 步名清单 ⇔ 现场抽取 ⇒ **红** |
| 5 | `close-wave.sh` `fp_inputs()` 覆盖面 | **234** | **236**（`+2` 行，件路径身份） | `inputs_fp` **必移**（设计性变更，须排在 `IN_FP_0` 采样之前） |
| 6 | 第 `[42]` 步 `FP-MANIFEST-TEETH --expect` | **234** | **236** | 漏改 ⇒ `FAIL reason=files-n-mismatch delta=-2`（**方向安全**） |
| 7 | 预登记 | `docs/WAVE81-PREREGISTRATION.md` | 新建/追加 `docs/WAVE<NN>-PREREGISTRATION.md` | `PREREG-FOUR-REQ`／边界声明读者看不到本波 |
| 8 | **`HANDOFF-MV` `cell=#1`（＋`#2`／`#5`）** | `inputs_fp`／件数 `233`／`run_step` `61`（`t48` 块，`2026-09-28T17:49`） | **同趟追写**更正行（新 `inputs_fp`＋`ts=`；件数；`run_step` 数） | `HANDOFF_MV` 与现取不符 ⇒ `DIVERGED reason=cell-mismatch` |

**维护契约逐字（`build/MilBridge/tools/handoff-machine-values-check.sh` 件头 `t57` 口径句②，现取原文）**：
`「**改了覆盖面内任一件 ⇒ 必须同趟追写 `cell=#1` 的 `ts=` 更正行**；改了**任一 route 件** ⇒ 追写 `cell=#4`…」`

> **⇒ 本波动 `close-wave.sh`（覆盖面内件）＋ 两新牙（入覆盖面）⇒ 必须同趟追写 `HANDOFF-MV cell=#1` 的 `ts=` 更正行**（并连带 `cell=#2` 件数、`cell=#5` `run_step` 数，见上表 #2/#5 同格）。

**四面声明（同趟改，缺一即非绿）**：① 首行 `DECL`；② 头注释口径句；③ `STEP-NAMES`；④ 预登记件（`PREREG4` 硬形态行 `PREREG-NO-REGRESSION-DECISION: …`）——**既有史实行只追加、不改动**（纪律 61 同族）。

---

## §6 边界 · 待裁项 · 引用纪律

- **只读**：本件未改 `verify-all.sh`／`close-wave.sh`／`KNOWN-DEFECTS.md` 及任何仓内件（唯写本载体）；未跑 `static-jaws-check.sh`；未跑整趟 `verify-all`。
- **待主裁（4 条）**：① `wic_proxy.c` 三条 `R-7` 命中是否入**声明式白名单**（有界 trace 预算 vs 读数判别）；② 缺省行 token 变体（`no-arrival-leg`／`lmwit-noarr-reverse-leg`）判**红**还是 **`NOINFO`**；③ `SJC-FIELD-ID` 弱版首版射程（建议限定 `build/MilBridge/**/*.md`，`KNOWN-DEFECTS.md` 记 `NOINFO`）；④ **两牙射程是否排除「引用判据行的证据/预登记件」**（§3.1 自指现取：本载体自身被命中 **4** 行 ⇒ 不排除则「写一份合规侦察件＝把自己判红」）。
- **未独立复算**：`t197`／`t198`／`t200` 等车道读数均**引自其载体**；本件**自算**的只有 §1 的四数（`62`／`234`／`234`／`DECL`）、§2 的正/反样本整行现取、§3 的 `grep -rnE` 命中与 token 行现取。
- **纪律**：`L21`（计数=0 必须先有正对照）／`L25`（空集当通过是假绿）／`D-G130`（锚不定域 ⇒ 行首锚）／`R-2`／`R-7`。
