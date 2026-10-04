# W170A · 波 `#72` 报告 —— 「**冻结器与抽取器锚在语义上**」（`TASK-0730` ＋ `TASK-0731`）

- 车道 = **W170A**（`#72` 唯一写者，波次串行）｜`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是 git 仓**）
- 判据文件 = `~/w170a/criteria.md`（`a557c1f048c10928`，写定 `2026-09-25T22:13:13+08:00`，**早于任何改动**）
- 预登记 = `docs/WAVE72-PREREGISTRATION.md`（落地 `f5b5a86aa61b3248` → 冻后追加 §3 诚实边界后 **`eb08b74def32d9b2`**）
- **本波零产品改动**：动的是**仪器**（仓内一件 ＋ 仓外一件 ＋ 声明块）。
- 冻结 = `2026-09-25 23:50:05`｜基线 **`cc814b708c141ae8` → `2eb64610f65a0d07`**｜`FREEZE_RC=0`

## §1 判定点（引行号前先打印该行）

- **`TASK-0731`**：`build/MilBridge/tools/column-floor-check.sh` 的 `extract_newest_block()`（改前 `:156-158`），
  **改前逐字**（件 sha16 `2be59234f7266e0f`）：
  `awk 'BEGIN{seen=0;p=0} /RE-FROZEN #/{ if(seen==1) exit; if(/^# RE-FROZEN /){seen=1;p=1} } p' "$1"`
  ⇒ **出口条件无锚**：块内正文只要出现那串字样，就**提前截断**，把紧随其后的 `# COLUMN-FLOOR`／
  `# COLUMN-CORPUS`／`# ARM-LOG-SHA` 声明行全排除 ⇒ `COLUMN_FLOOR=NOINFO`（**病因错**）。
- **`TASK-0730`**：`~/w21-verify/w27-freeze.py`（**仓外**）里 `GENS[gen]['prev_*']` **从来没人核过** ——
  表项写什么就冻什么。现场（波 `#67`）`prev_pf` 被填成**本波整波现值**，靠主控在冻结前**手工**拦下。

### 1.1 病灶现场（真仓真件的机械证）
- 现取自证：`^# ⏪ ` **45** 行**全部**是降级块头；`^# (RE-FROZEN #|⏪ )` = **51**（冻结后 **52**）= 块数；
  第二机制（**剥掉 Markdown 行内代码跨度**后按"行首 `# ` 且含 `RE-FROZEN` ＋ 井号＋世代号"匹配）亦 **51**，两法**逐行同集合**。
- **只把出口锚写成"未降级那一种"会让抽块跑到 EOF**（实测）：真件 **57 行 → 3573 行**（文件 4073 行）⇒ 出口锚必须**同时**认降级块头。本机 `awk` = **mawk**（非 gawk）⇒ 模式里不用多字节字符类。
- **真仓真件里的病灶实例**：基线件 `#52` 块（`L1564..L1764`，201 行）正文 `blkL123` **真含**那串字样 ⇒ 旧锚抽 **122** 行、新锚抽 **201** 行。

## §2 改了什么（逐件 before → after，现算）

| 件 | before | after | 说明 |
|---|---|---|---|
| `build/MilBridge/tools/column-floor-check.sh`（**覆盖面内**） | `2be59234f7266e0f`（52,716 B） | **`e997d316515e4128`**（65,548 B） | 出口锚锚行首 ＋ `block_span()`／`hdr_form_counts()` 两个**只读**助手 ＋ 第 ② 段两道**响亮**守卫 ＋ `--selftest` **+8 例**（既有 **26 例逐字未改**）＋ 一处 `$HOME/w` 注释清理（`D-G137` 硬条件；`grep -c "$HOME/w"` 现取 **0**） |
| `verify-all.sh`（**四处声明** ①②③；**不动步数**） | `d5829ded84c7adb3`（149,949 B） | **`66da0964f462bb7c`**（151,834 B） | 首位插 `# VERIFYALL-STEPS-DECL: 42 gen=#72` ＋ 追加 `#72` 口径句（`**\`#72\` 收官起 = 42 步**`）；`STEP-NAMES` **一字不改**；现取 `^run_step "` = **42**；自检牙 `VERIFYALL_SELF=PASS names=42 decl=42 gen=#72 dup=0 order=OK prose=OK prereg=PASS` |
| `docs/WAVE72-PREREGISTRATION.md`（新建 → 冻后追加 §3） | — | `f5b5a86aa61b3248` → **`eb08b74def32d9b2`**（8,951 B） | 预登记；`PREREG4=NA rc=0`；冻后**只追加** §3 诚实边界（原文一字未删） |
| `~/w21-verify/w27-freeze.py`（**仓外，如实标注：不进覆盖面**） | `c22cfb93c43d23fa`（104,070 B） | **`dfe84694c6cf7a25`**（117,707 B） | `check_prev_values()` ＋ **生产调用点** ＋ `--prev-check-only` 排练模式 ＋ **冻前自留备份** ＋ `PREV-IS-WAVE-PRODUCT` 响亮拒冻 ＋ `GENS['#72']`。**两级步骤**：`56e54035c6e1df1b`（冻结那一刻用的版本）→ `dfe84694c6cf7a25`（**冻后补齐生产调用点**，见 §5） |
| `~/w21-verify/versions/` | — | `w27-freeze.py.w72-56e54035c6e1df1b`（**冻结那一刻**）／`w27-freeze.py.w72b-dfe84694c6cf7a25`（接线后）／`w27-freeze.py.w72-frozen`（同前者留档）／`w72-patch-{w27,w27b,cfc2}.py` | 前像 `~/w21-verify/w27-freeze.py.bak-w72` = `c22cfb93c43d23fa` |
| `~/w21-verify/w72-record.txt`（记录模板） | — | `f628658190428a9a` | 占位符 19 处**全在 `fmt` 表内**；段标记 1/1/1；FROZEN 段 `COLUMN-FLOOR` 2／`COLUMN-CORPUS` 1／`ARM-LOG-SHA` 5；`^# RE-FROZEN ` 命中 **1**、BANNER **0** |
| `~/w170a/w72/w72-pre.sha` | — | 9 行 | 与 `#71` 冻结块九位行 **9/9 逐位相符**（现算） |

### 2.1 `TASK-0730` 的 `prev_*` 家族与**逐条来源**（输入来源声明，纪律 36）
| key | 来源（基线件 `^# RE-FROZEN #<prev>` 块内） | 命中数要求 |
|---|---|---|
| `prev` | `docs/CURRENT-STATE.md` 的 `> BASELINE-FROZEN gen=` 机器行（**既有断言保留**） | 1 |
| `prev_pf`／`prev_pc`／`prev_wb`／`prev_wsh`／`prev_dwf` | 块内**唯一**那条 `^# **九位（Release 权威件）**` 行里 `` `名` `<16hex>` `` | 各 ==1 |
| `prev_bsfp` | 块内 `` `BRIDGE_SRC_FP` = `<16hex>` `` | ==1 |
| `prev_infp` | 块内 `` `inputs_fp` = `<64hex>` `` | ==1 |

- **交叉核**：`BASELINE tier=` 机读行 `config=` 里同名键（`pf`／`pc`／`win32shim`）必须**逐位相符**（现跑三键 `agree=yes`）。
- **为什么"命中数恰为 1"是承重**：`pf` 在块内出现**两次**（九位行 ＋ 「相对上一代冻结值」行）⇒ 静默取第一个/最后一个都可能取到**上一代的**值（正是 `#67` 那类错值的来源）。命中 ≠ 1 ⇒ 拒冻。
- **范围边界**：只对**待冻代的上一代块**生效（现取 52 块里只有 `#71`／`#69`／`#68`／`#67` 形态 8/8 全可抽）⇒ 更老代**响亮拒冻**，**不**降级成静默放行。

## §3 判据与两极化（**全部真跑**；原始读数 `~/w170a/logs/FINAL-tool-readings.txt`、`logs/w72b-prodlegs.log`）

### 3.1 `TASK-0731` 三条（＋一条）极化成对读数
| 腿 | 旧件（`2be59234f7266e0f`） | 新件（`e997d316515e4128`） |
|---|---|---|
| **(a1) 真仓真件** `#52` 块（正文真含该字样） | 抽 **122** 行 | 抽 **201** 行 ✓ |
| **(a2) 合成档**（字样插在 `# COLUMN-FLOOR` **之前**，落在**真基线副本**上） | `COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line` rc=**2** | **`COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus` rc=0** ✓ |
| **(b) 正常档** | rc=0 | rc=0；**整份 stdout 与机读行逐字节相同**；块首 `# RE-FROZEN …`／块尾 `BASELINE tier=env rep=3 …`／行数 **57** == 独立现算边界 ✓ |
| **(c) 无块** | `NOINFO` rc=2 | `NOINFO` rc=2（删全部未降级块头 ⇒ `reason=baseline-has-no-RE-FROZEN-block`）⇒ **无块不是 `PASS`** ✓ |
| **(e) 出口锚的域** | **`COLUMN_FLOOR=PASS` rc=0（静默的假读数！）** | **`NOINFO reason=block-end-not-found` rc=2**；只换"下一块"块头 ⇒ `NOINFO reason=block-header-form-mismatch form_mismatch=yes` rc=2 ✓ |

- `--selftest`：旧 `cases=26 pass=26 fail=0` rc=0；新 **`cases=34 pass=34 fail=0` rc=0**；**既有 26 例逐行逐字不变**（`diff` 空）；新增 `C0731a/b/c/e/f/g/h` **8 例**全 `yes`。
- ⚠️ **(e) 档的如实划界**：主控原话预期 `block-end-not-found`；实测只有"**除当前块外每一条块头**都换成第三种装饰"才走到那一支 ——
  只换"下一块"时出口锚会在**更下面仍可识别的旧块头**处收住（块变**过长**）⇒ 先响的是**另一种**守卫 `block-header-form-mismatch`。
  **两条守卫都响、都给 `NOINFO rc=2`，都不给 `PASS`**；两档都做进 `--selftest`，读数如实并排。

### 3.2 `TASK-0730`：`--prev-check-only` 排练（**基线件沙箱副本 ＋ 真表项**）
| 腿 | 读数 |
|---|---|
| **正极**（填对） | `PREVCHECK=PASS gen=#72 keys=7` rc=**0**；7 个来源**命中数全 1**；`prev_pf`/`prev_pc`/`prev_wsh` 三键 `agree=yes` |
| **反极 ①** `prev_pf` = `#67` 事故里那个错值 `cbd1884faeb4837e` | `REFUSE MISMATCH key=prev_pf 表项=cbd1884faeb4837e 基线块=e9fe77a43f950f2c` rc=**2** |
| **反极 ②** `prev_infp` 填上一代值 | `REFUSE MISMATCH key=prev_infp` rc=2 |
| **反极 ③** `prev_wsh` 填更早的值 | `REFUSE MISMATCH key=prev_wsh` rc=2 |
| **更老代**（`#71`；其上一代块缺 `inputs_fp` 形态） | `REFUSE baseline-has-no-RE-FROZEN-#70-block` rc=2 |
| **命中数 ≠ 1**（九位行复制两遍） | `REFUSE 九位行命中 2 条` ＋ 5 键 `HITS!=1` rc=2 ⇒ **不许静默取第一** |
| **无块尾**（所有块头换第三种装饰） | `REFUSE block-end-not-found(prev=#71)` rc=2 |
- **基线件零字节改动**：以上**每一档**跑完现算副本 sha16 仍 = `cc814b708c141ae8`（跑前同值）。

### 3.3 **生产入口**两腿（主控附加硬条件：不许只走 `--prev-check-only`）
桩 = **桩日志 ＋ 桩门禁行 ＋ 基线件沙箱副本**（`--baseline` 测试钩子）。原始读数 `~/w170a/logs/w72b-prodlegs.log`：
- **B 腿（表项填对）**：打印 `⟦PREVCHECK⟧ gen=#72 prev=#71 baseline=… sha16=cc814b708c141ae8` ⇒
  **`PREVCHECK=PASS gen=#72 keys=7 base=cc814b708c141ae8`** ⇒ 执行**继续**到下一个守卫（既有树世代断言按预期报"树上 #72 ≠ prev #71"）⇒ 沙箱副本 sha16 **逐位未变**。
- **A 腿（`prev_pf` 填成 `#67` 事故那个错值）**：`PREVCHECK=REFUSE MISMATCH key=prev_pf 表项=cbd1884faeb4837e 基线块=e9fe77a43f950f2c` ∧
  `PREVCHECK=REFUSE TIER-DISAGREE key=prev_pf tier=e9fe77a43f950f2c 表项=cbd1884faeb4837e` ∧ **`rc=2`**，
  **未写任何文件**，副本 sha16 跑前跑后 **`cc814b708c141ae8` 逐位未变**。
- ⚠️ **桩仓口径（如实，不放大）**：冻结器的**仓库根 `R` 是编译期常量**、没做成可覆盖 ⇒ **没有造"整棵桩仓"**。
  这里端到端的是「**生产入口 ＋ 真实检查函数 ＋ 真实基线形态**」；**不等于**"整仓端到端排练"。

## §4 关键读数表（链条）
- **整波**：`close-wave.sh --skip-verify-all` 槽内 `rc=0 held=199s`｜`[0/6]` `APP_PROBE_GUARD=PASS faces=3 face3=cap cap=1 examined=142 hits=0 undecidable=0`｜`[2/6]`/`[3/6]` 跳过（native／桥源未变）｜`[4/6]` 身份四项全 ✅（`APPSYNC`／生成物指纹 `state=ok`／应用器审计 `miss=0`／**输入稳定性 波前==波后 == `999791b4…39a891`**）。
- **应用级门禁 ×2**（`run-wpftextdemo.sh 45`，显示 `:236`）：两趟各 `rc=0 rows=6` ∧ **6/6 `result=PASS`** ∧ `WPTD_SUMMARY=PASS tiers_passed=2/2` ∧ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS` ∧ `WPTD_BRIDGE_SRC_STALE=no` ∧ **`GATE_LINES_IDENTICAL=yes`**。
- **verify-all**：**声明落地前**三趟（`gate1`/`gate2`/`pre`）各 `42 ✅/0 ❌`（其 `VERIFYALL_SELF` 行**已作废**，见 §6）；
  **声明落地后**两趟（`gate2`/`pre`）各 **`步骤通过 42 ❌ 失败 0` ∧ `结论：✅ 全部通过`** ∧ `VERIFYALL_SELF=PASS … gen=#72` ∧ **`COLUMN_FLOOR=PASS`**；`pre` 那一趟就是**冻结用的日志**。
- **守卫逐格（全过）**：格1 全绿｜格2 `[11] prereg=PASS`／**`[7] BASELINESHA=PASS live=cc814b708c141ae8`**／`[17] undeclared_hit=0`／`[40] BAK_COMPLETENESS=PASS n_wired=0`／`[41] ALIAS=PASS aliased_unallowed=0`／`[42] FP_MANIFEST_TEETH=PASS files_n=192 declared_expect=192`／`[12] coverage_n=192 missing_n=0`（**现算** 192）／`[38] PTS_GUARD=PASS`／`[8] COLUMN_FLOOR=PASS`｜格3 模板 19 处占位符**全在 fmt 表内**、段标记 1/1/1、FROZEN 段 `^# RE-FROZEN ` **1**、BANNER **0**、冻前残留占位符 0。
- **格3′ 本波两条新判据的在场读数**：① 整波自印 **`波前输入指纹 = 999791b4…39a891` == 落地前写死的预测 `J0`** ⇒ **兑现**；② 落仓件 `--selftest` **`PASS cases=34`** ∧ `ST_ATTEST=PASS sha16=e997d316515e4128` ∧ 新增 `C0731*` **8 例**。
- **冻结**：`FREEZE_RC=0`｜`世代交叉断言通过：树上 #71 == GENS[#72][prev]`｜**冻结器自留备份** `B.pre-freeze.#72.bak`（sha16 `cc814b708c141ae8`，`nlink=1`，**逐字节 == 写前现场基线**）｜`基线已重冻为 #72；整份 sha16 = 2eb64610f65a0d07`。
- **格4（冻后）**：`BASELINEGEN=PASS decl_gen=#72 file_newest_gen=#72`｜`ARMLOG_SHA=PASS required=5 declared=5 pass=5`｜`COLUMN_FLOOR=PASS base=2eb64610f65a0d07`（两个声明类检查器**冻前红 ⇒ 冻后绿**）｜`^# RE-FROZEN #72` **1** ∧ 残留占位符 **0**｜块 `L9..L55`（47 行）含 `COLUMN-FLOOR` **2**／`COLUMN-CORPUS` **1**／`ARM-LOG-SHA` **5**／`BASELINE tier=` **6** 行｜**手工备份 == 冻结器自留备份**（`cc814b708c141ae8`）⇒ `TASK-0730` 新加那一步**在生产路径上真跑了**。
- **九位（新块九位行逐字）**：`bridge 4e25e4b27d4d5ae1`（5028208 B）／`pc 722e0ab8205b7c3f`／**`pf 147aac2dbbc6a0d8`**（6123520 B）／`windowsbase 2e4e46e539a72cd7`／`provider 1f9511a7ef395bfe`／`win32shim fc60c34d51fd9247`／`wic_shim f7b3026c8c019be2`／`hbtextline 921ba9c65e9fb3be`／`dwf ce3469f49efcbcfa` ⇒ **只有环成员 `pf` 位移**（`e9fe77a43f950f2c → 147aac2dbbc6a0d8`，同尺寸）。
- **账**：首行 `DECL` = **42** == 现取 `grep -c '^run_step "'` = **42**（纪律 46）；**不加步**；覆盖面 **192 → 192**（不加不减行）；`inputs_fp` **`5b922044…` → `999791b4…39a891`**，**逐件归因仅 1 件**（`column-floor-check.sh` 在覆盖面内；`verify-all.sh` **不在** ⇒ 落它**不动指纹**，实测）。
- **冻后链**：verify-all ×2（`00:0x`／`00:21`）各 **`步骤通过 42 ❌ 失败 0` ∧ `结论：✅ 全部通过`** ∧ **`BASELINESHA=PASS live=2eb64610f65a0d07`** ∧ `coverage_n=192` ∧ `declared_expect=192` ∧ `COLUMN_FLOOR=PASS base=2eb64610f65a0d07` ∧ **两趟关键判词行（归一化 `wall_s=`）逐字相同 `GATE_LINES_IDENTICAL=yes`**；`DEFECT-REGISTRY ✅` ∧ **`DEFREG=PASS declared=173 route_ids=173`**（主控重发的 `declared.tsv 8adc1748e7af1632`，`AB=2eb64610f65a0d07`／`CS=0a5d5f06251407e0`）∧ 无 `DECLDRIFT` 红。

## §5 我没做到的 / 如实边界（逐条）
1. ⚠️ **本波这次冻结发生在"生产调用点接线之前"** —— 冻结那一刻跑的是**既有**树世代交叉断言；`check_prev_values()` 当时**只在排练模式里被调**。冻后已补齐生产调用点（`56e54035c6e1df1b → dfe84694c6cf7a25`）并给 §3.3 的决定性两腿。⇒ **新路径的「首次真冻」将是 `#73`**（`#73` 放行条件之一 = 生产路径必须打印 `PREVCHECK=PASS`）。**本次冻结用到的 7 个 `prev_*` 值确实核过**（同一函数、同一基线、来源命中数全 1、错值档全 `REFUSE`）——**核过的是"值"，缺的是"生产路径自动执行"这一跳**；冻结产物**不受影响**（该检查只读，且在同一基线上判过 PASS）。此边界**同趟写进了预登记 §3**。
2. **`#67` 的原始现场件未留存** ⇒ 「复现 `#67` 原样」= **`NOINFO`**；本波复现的是**同类形态**（真仓真件 `#52` 块 ＋ 合成档）。**不许**把合成档写成"复现原样"。
3. **出口锚是"形态白名单"**：域名自证只能保证"第三种形态**出现了会被点名**"，**不能证明它不存在**。现取 51/51（冻后 52）两法同集合是**当刻**读数。
4. **桩仓口径**：见 §3.3 末 —— **没有造整棵桩仓**（`R` 是编译期常量）。
5. **`prev_*` 自动核只对"待冻代的上一代块"生效** ⇒ **未观察到**更老代被重冻的情形 —— 那是"**没观察到**"，**不是**"证不存在"。
6. 未跑五臂重取、未做冻结以外的世代判定（属收尾链，主控另派）。

## §6 自伤 / 作废趟（如实留档）
1. **漏接生产调用点**（上 §5-①）：**本波最有价值的自捉** —— 冻结**已成功**、产物正确，但 `TASK-0730` 的**承重那一跳**当时没接上；主控据此**不认它办完**，我已补齐 ＋ 补两腿读数。
2. **补丁里 `\uXXXX` 转义码猜错**（`\u29d6` ≠ `⏪` U+23EA）⇒ `--selftest` 新增档的 fixture **没造出来**，而该档当时**照样报 `NOINFO rc=2` ⇒ 假绿**！当场改成"按**形状**找降级块头 ＋ 断言 fixture 非空 ＋ **点名病因**"，并补"两侧计数都必须 `>0`"的断言。
3. **STOP 守卫生效（主控已记为"守卫有效性"正面证据）**：冻结驱动器第一次把 `--selftest` 的判词读成 `tail -1`（末行是 `ST_ATTEST=PASS`）⇒ `STOP：cfc-selftest-not-pass` ⇒ **基线件纹丝未动**（现算仍 `cc814b708c141ae8`、`CURRENT-STATE` 仍 `gen=#71`、无备份件）—— 与设计一致；改正后第二趟 `FREEZE_RC=0`。
4. **口径缺口（我自捉）**：`VERIFYALL_SELF` 起初报 `gen=#71` —— 按**四处声明**惯例必须为 `#72` 补 `# VERIFYALL-STEPS-DECL` ＋ 口径句 ⇒ 已补落（`verify-all.sh → 66da0964f462bb7c`）；**声明落地前那三趟 verify-all 的 `VERIFYALL_SELF` 行已作废**，冻前重跑两趟。
5. **沙箱里 `--selftest` 跑不动**：根因是**工具既有**的 `--selftest` 包装层在参数 `while` 循环里已 `shift` 过 ⇒ `"$@"` 已空、`--root` **传不进内层**（**非本波引入**）⇒ 沙箱改用 `CFC_ROOT`。
6. **探路阶段我自己第一次数块数错**（把"含该字样的任意行"当块头 ⇒ "0 块有正文命中"）；**两次 `--root`／`0/0` 假绿** ⇒ 已写成断言（两侧计数 `>0` ＋ 必须点名 `reason=`）。
7. 未用 `pkill`／`pgrep -f`；查存活一律 `ps -o pid= -p <PIDs>`（**不加 `-e`**）；私有显示只用 `:236`；重活全走 `~/heavy-slot.sh`。

## §7 大白话小结（≤6 行）
1. 本波修的是**两件仪器**，产品件一字节没动。
2. 冻结器以前**从不核对**"跟上一代比"的基准值（`#67` 就栽在这，靠人手工拦下）；现在它**自动**把每个 `prev_*` 从基线块里取回来逐位比，**对不上就拒冻**、且**基线半个字节都不动** —— 沙箱里三个错值档全被挡住，副本 sha16 一次没变。**但这次冻结发生在"接线之前"**（请见 §5-①）：值核过、那一跳没跑，**首次真冻在 `#73`**。
3. 抽取器的老毛病是"**块还没完就以为完了**"：正文里出现那串字样就在那里截断，把后面的声明行全丢掉，还报**错病名**。现在出口条件也锚在行首。
4. 顺手加了两道**响亮**守卫：**块尾找不到就 `NOINFO`**、**块头换了装饰也点数得出来、点不上就 `NOINFO`**。老件在"换装饰"那档给的是 **`PASS`（静默假读数）**，新件给 `NOINFO`。
5. 真件上**零位移**：新旧整份输出逐字节相同，`--selftest` 26 例逐字没变（只多 8 例）；整波九位**只有环成员 `pf`** 动。
6. 落地前写死的 `inputs_fp` 预测，整波自印**逐位相符**。

LANE=W170A TASK=TASK-0730,TASK-0731 R_TOUCHED=build/MilBridge/tools/column-floor-check.sh,verify-all.sh,docs/WAVE72-PREREGISTRATION.md DONE=yes NOINFO=6
