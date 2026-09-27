# 波 `#79` 预登记（**仪器波 · 零产品改动**）：`TASK-0750` ＋ `TASK-0751` ＋ `TASK-0752`／`0753`／`0754`／`0755` ＋ `#78` 九位行 `provider` 的处置

> 本件由**主控**在落地**之前**落仓（`#77` 的教训：`gen=#79` 一进 `DECL` 而预登记缺席 ⇒ `VERIFYALL_SELF=NOINFO reason=prereg-absent`，**那是红**，不许当"文档欠账"放过）。
> 落仓那刻**现取**（以下数字是**断言**，不是常量）：`run_step` **51 → 53**（加 `ROOT-ENTRIES-ALLOWLIST` ＋ `WIRING-CLOSURE` 两步）／覆盖面 **217 → 219**（两颗新牙进 `fp_inputs()`）／`[42] --expect` **同趟 219**。
> **本波零产品改动** ⇒ 九位里只有 **`pf`（环成员，`D-G92`）** 必动；其余八位**逐位不该动**。

## §1 四要件

### 1.1 断言（可判否）
1. **`TASK-0750`（根级条目白名单牙）**：新牙 `build/MilBridge/tools/root-entries-allowlist-check.sh`；判据 = 声明**根级允许清单**（从 `#76` 冻结树根条目现取 ＋ 移植面 ＋ fork 治理件）⇒ 断言「`git ls-files` 根级条目 ⊆ 清单」**∧**「工作树根级条目 ⊆ 清单」，超限**逐条点名**并印**判定路径与来源**（`git ls-files` vs `test -e` 两来源**分别**打印）；接线放在 `IN_FP_0` **之前**。
   **判否**：放回 `.editorconfig`／`Directory.Build.props`／`NuGet.config` 任一 ⇒ 不红；或清单件缺席时给出 `PASS`（应为 `NOINFO`）。
2. **`TASK-0751`（接线闭合性 ＋ 真判词牙）**：新牙 `build/MilBridge/tools/wiring-closure-check.sh`，**两方向**。**A**「交付的牙集合 ⊆ `run_step` 接线集合」（未接线且不在册 ⇒ 红并点名该件）；**B**「每个 `^run_step` 的牙必须给**真判词**」（`NOINFO reason=usage:…`／`cases=0`／`no-cases`／`no-manifest` 这类"接上了却没判" ⇒ 红并点名该步；**合法 `NOINFO`**（如 `disk-headroom`）放行**且不误报**）。
   与 `TASK-0740`（接线件 ⊆ 覆盖面）**互补、不代偿**，报告里须逐字写清两条各守哪一格。
3. **`TASK-0752`（`TASK-0747` 的 `−242` 成对读数）**：三臂 —— 旧件（`fc60c34d51fd9247`）／**本波新造的未装符号件**（`8857b251e74851d2`，`shappbar=0`）／`ret0`（`efb087b5c7c33eb2`，`shappbar=1`），各跑 `DIAG=0/1`。
   **判否**：旧件**不再**逐位复现在册值（`242`／`3808`）；或 `DIAG=1 − DIAG=0` 的 `179 = 242 − 63` 不成立；或 `absent` 臂指向**已装符号**件／**已退役旧路径**（＝臂语义反转）。
4. **`TASK-0753`／`0754`／`0755`**：`D-G147` 的**成对读数重取**（工作区事实来源 ↔ `ABM_GETTASKBARPOS` 消费者对账）；显示号**租借**两极化（「起过 ⇒ 收尾后该号无进程」／「没起过 ⇒ 一个都不杀」）＋ `X-CENSUS` 链前基线；`0744-FU` 的**真腿**（`sock=` 随行打印 ＋ 「符号级 hook 恒瞎」复证）。**每条都要成对**（正极 ∧ 反极各一条真读数），跑不成 ⇒ `NOINFO` ＋ **具名结构性原因**，**不许**用单极读数充当。

### 1.2 判定口径（先写死）
各包 `criteria.md` 为准；三态一律 `PASS`／`FAIL`／`NOINFO`；**`NOINFO` 不算绿**；`examined == 0` ⇒ 一律 `NOINFO`。
**冻后两趟的差异域口径（本波新增，`D-G138` 现场形态第二次出现）**：报告必须**先写抽取域、再写差异**；两域各给数 ——
- 域① `^ *· 自报口径 ` 行；域② 判词行（`步骤通过`／`结论：`）；
- 归一化时间戳后按**机器分类器**分「**读数类**」与「**标签/环境类**」；
- 合格线 = **除具名「环境类读数」清单逐条列出的量外，读数类差异必须为 0**；出现清单**之外**的读数类差异 ⇒ **红**并点名字段与两侧值；
- 分类器**自己**须有**反极性两条腿**（人为改一处真读数 ⇒ 判读数类；只改一处纯路径 ⇒ 判标签类），否则"把一切都归一化掉"就是假绿。

### 1.3 输入来源声明（纪律 36）
`verify-all.sh`／`build/close-wave.sh`／两颗新牙／`build/MilBridge/tools/wave-freeze-consistency-check.py` 的**落地那刻现取 `sha16`**；覆盖面由 `fp_inputs()` 同码路径现取（**不许分段累加**）；九位由 `sha256sum` 现算；`GENS['#79']` 的 `prev_*` 一律取 `#78` **冻后值**。
⚠️ **`prev_provider`／`prev_wic_shim` 不许照抄 `#78` 块九位行**（见 §3-①）：取**现取真值** `a00895e8158189b9`／`f7b3026c8c019be2`。

### 1.4 回归判定（本波**不做**产品回归对比 ⇒ 走机读行形态，纪律 45）
```
PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-wave-79
```

## §2 位移声明（**先写**）
**零产品改动** ⇒ 只有 `pf`（**环成员**，整波重建必变、**同尺寸**）应动；`bridge`／`pc`／`windowsbase`／`provider`／`win32shim`／`wic_shim`／`hbtextline`／`dwf` 八位**逐位不该动**。
**表外位移 ⇒ 停手报主控**；若某位确实动了，**先逐位点名归因**（例如"路径承载体"族 `D-G92`）再决定是否进 `allow_changed` —— **不许静默扩大允许集**。
冻结器配置的**机读声明行**（由 `build/MilBridge/tools/wave-freeze-consistency-check.py` 档② 逐字段核）：
```
WFREEZE-DECL: gen=#79 allow_changed=pc,pf,windowsbase,provider,dwf pf_required=True
```

## §3 本波如实记账（三条，落地前写死）

### ① `#78` 冻结块九位行 `provider` 陈旧 —— **块不改**，处置 = 更正 ＋ 下一代写对 ＋ 牙
`t9`（`verifier`）独立复现 + 主控只读审计（两条独立通道同结论）：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:66` 的**九位行**写 `provider = 609192a419d125f2`，而同块 **6 条** `BASELINE tier=` 机读行、**两份哨兵**、权威件现取都是 `a00895e8158189b9`；那个值在现树 `*.dll`／`*.so` 有界扫描**命中 0**。
根因：记录模板 `~/w186a/w78/w78freeze/w78-record.txt:67` 把 `provider`／`wic_shim` 写成**硬编码字面量**（同行其余七位是占位符），而改前的冻结器 `fmt` 字典**没有这两个键** ⇒ `fill()` 只抓「用了没定义的」，**抓不到「写死了本应现取的」**；`_PREV_SRC` 的 7 个键也不含 `provider`／`wic_shim`／`bridge`／`hbtextline` ⇒ 这四个键**从来没有被任何一道核读过**。
**主控裁定**：**不改 `#78` 块**（其 `sha16 = d60b414d5e99cf72` 被两趟冻后日志的 `baseline_sha16`、`docs/CURRENT-STATE.md:9`、两份哨兵的 `BASELINE_SHA16` 四条链引用；「一份变更集只许一次冻结」）。⇒ **在 `#79` 冻结之前，远端在册件里带着这条已知错的 `provider`**（已登记 `D-G166` ＋ 本预登记与 `P0-w78-report.md` 的 dated 更正）。
⇒ 本波必须**同时**满足：**`#79` 的九位行逐键 == 落地那刻现取值**（冻结器新增硬断言 `check_block_values()` 在**写盘前那份文本**上对拍，不等 ⇒ 拒冻 `rc=2` 并同时打印两值）＋ 新代模板 `w79-record.txt` 用 `{PRV}`／`{WIC}` 占位符 ＋ 「表中出现而表外无映射」的 tier 键必红。

### ② `D-G147` 「三处一致」不成立（`t9` finding #2）
`defect-registry-declared.tsv` 与 `docs/ROUTES.md` 有它，但**缺陷册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 里 `grep -c D-G147` = 0**（`ROUTES.md` 已声明"等落地配号" ⇒ 声明过的缺口）。⇒ 本波**配号入册**并把 `req` 从 `AB` 扩到 **`AB`＋`KD`**，并给那条「编号 ⊆ declared」的牙加**反极性腿**（删册内一条 ⇒ 必红并点名）。

### ③ 主控写域：冻结器已落（**不在任何成员写域**）
`~/w21-verify/w27-freeze.py`：`fe479b88a852e482` → **`b7912a4a75d36c18`**（档案 `~/w21-verify/versions/w27-freeze.py.w79-land-fe479b88a852e482`，`sha16 == 覆盖前现读`、`temp+rename`、五探针各 `hit=1`；装后用活件重跑排练 `REHEARSE_BLOCKVALUES=PASS arms=13 pass=13`）。内容 = `fmt` 补 `PRV`／`PRV_PREV`／`WIC`／`WIC_PREV` 四键 ＋ 写盘前硬断言 `check_block_values()`（**九位行 ∧ `BASELINE tier=` 行 ∧ `BRIDGE_SRC_FP`／`inputs_fp` 两行** vs **现取值**）；`_PREV_SRC`／`_TIER_MAP`／`check_prev_values`（「与上一代一致」）**一字未动**。
`#77` 那份 E1/E2 补丁（`check_record_forms` 拿**本代块**比 `G['prev_*']`）**不采用**：实测它会拒掉任何真有位移的合法世代（假红门）。

## §4 落仓那刻的声明值（**断言相等**，不是常量）
| 声明 | 值 | 来源 |
|---|---|---|
| 步数 | 现读 **53**（51 ＋ `ROOT-ENTRIES-ALLOWLIST` ＋ `WIRING-CLOSURE`） | `grep -c '^run_step "'` |
| 覆盖面 | 现读 **219**（217 ＋ 本波 2 件） | `~/w153a/bin/infp.sh list \| wc -l` |
| `[42] --expect` | **219**（同趟；**落仓后现取一次算准**） | 现取 |
| `inputs_fp` | **必移**（两颗新牙进覆盖面 ＋ `close-wave.sh`／`verify-all.sh` 改内容） | 整波自印 ＋ 独立复算互证 |
| 冻结器 | `b7912a4a75d36c18` | 现取 |

## §5 判据（落地前写死）

### 5.1 回归判定（本波不适用）

`PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-wave-79`

（本波 = **仪器/装置 ＋ 登记 ＋ 成对读数**合波，**零产品改动**、**不含**任何"修前/修后"产品对比 ⇒ 四要件对本波不适用；本行是**硬形态**声明 ⇒ 不得带 `residual=` 令牌。**本波不做任何回归判定**。）

### 5.2 四要件逐条落位（判定器口径）
① **断言**（§1.1 四件，可判否）｜② **判据**（§1.2：各包 `criteria.md` ＋ 三态 `PASS/FAIL/NOINFO`，`NOINFO` 不算绿 ＋ 差异域两分类口径）｜③ **输入来源**（§1.3，纪律 36）｜④ **回归判定**（§5.1 ⇒ `NA`：非 `PASS` 亦非违规）。
**三态词表**：`REGRESSION`／`NOINFO`（皆见本节）；判据件路径 `build/MilBridge/tools/regression-decision.py`（**本波不调用它** —— 不适用）。


### §2-追 dated 更正（2026-09-27 主控落册；**上面那行已按实测改**，原文逐字留档如下）

> 原机读行（**逐字留档**，已被上面那行取代）：`WFREEZE-DECL: gen=#79 allow_changed=pf pf_required=True`

**为什么改**：`#79` 整波的**整波重建**实测使九位里的**五位**位移 —— `pc`／`pf`／`windowsbase`／`provider`／`dwf`（`bridge`／`win32shim`／`wic_shim`／`hbtextline` **逐位未动**）。
**逐键归因（现取）**：五件的**字节数与嵌的 `*.pdb` 绝对路径都与 `#78` 冻结值相同**（`3601408`／`6123520`／`1111552`／`104448`／`39936`），**只有内容变**（例：`pf` 仍嵌 `/home/links-dev/netTest/GitProj/WPFOnLinux/build/PresentationFramework.Linux/obj/Release/PresentationFramework.pdb`）⇒ 机制＝**重建时 PDB 调试目录被重生成** ⇒ 与 `D-G92` 同族，但**不是**"路径承载体（跨树）"那一支；`mtime` 落在 `2026-09-27 13:36–14:22`（＝本波整波重建窗口）。
**预登记的预想（`pf` 单键）不成立** —— 与 `#78` 那次"预想 3 键 vs 实际 6 键"（见 `docs/WAVE78-PREREGISTRATION.md` §2-追）**同一形态**：**预想阶段拿不到的量，落地后必须按实测逐键声明，不许静默扩集**。
逐键声明落在 `build/MilBridge/blockvalues-shift.tsv`（`live=` 钉住 ⇒ 再漂一次仍红）。
