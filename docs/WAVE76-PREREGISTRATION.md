# 波 `#76` 预登记（**合波**）—— `TASK-0732`（主件）＋ `TASK-0720` 残项 ＋ `TASK-0721` 纯文档面

`PREREG_WAVE=#76`｜`PREREG_LANE=W176A`（**唯一写者**）｜`CRITERIA_FIRST=yes`（判据**先写**，早于本文件与任何构件；判据全文见本文件 §3 与仓库版 `criteria` 稿）
**本波是合波**：三件**同一趟**落仓（一件不变更集 ⇒ **一次冻结**）。逐件判据见下 §1 与 §3。

## §1 本波要交什么（逐条可判否）

| 编号 | 件 | 判否条件 |
|---|---|---|
| `A1` | `TASK-0732` **主件**：新牙 `build/MilBridge/tools/boundary-decl-check.sh`（把"未接线／已弃用"**边界声明**做成**有机读读者**） | 牙内出现任何**具体**声明的 id／target／期望值 ⇒ 拒（谓词必须**从预登记语料读回**） |
| `A2` | 谓词的域＝**件路径身份**（`run_step` argv 路径归一 ＋ **包装件传递闭包**深度 ≤3） | 只按**令牌拼写**判 ⇒ 拒 |
| `A3` | 接线**新一步** `BOUNDARY-DECL`（**只此一件加步**） | 步数账不用**纪律 46 真不变量**（首行 `DECL` 步数 == `grep -c '^run_step "'`）⇒ 拒 |
| `A4` | `TASK-0720` 残项：① `win32_classification.c` 第 9 处替换（**仅注释**）② `C1` 取代声明 ③ 防漂移牙 `pts-gap-count-check.sh` 接进 `build/close-wave.sh` **冻前**（**不加步**） | 世代位 `.so` 实测变了却没显式声明 `allow_changed` ⇒ 拒；现算对账**有余量却判绿** ⇒ 拒 |
| `A5` | `TASK-0721` 纯文档面（**不加步、不加件**）：那条路线图行转 ✅ ＋ **真证据链**；逐字文本模块交主控落与推 | 主控五件（`KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv`）由本车道**直改** ⇒ 拒 |
| `A6` | 四处声明（首行 `DECL`／`STEP-NAMES`／口径句／本文件）**同趟**落 | 缺一处 ⇒ 拒 |
| `A7` | 覆盖面 ＋2（两件判据件，惯例「**读 ⇒ 进 `fp_inputs()`**」）⇒ `[42] --expect` **同趟**改 | 落仓后 `files-n-mismatch` ⇒ 拒 |
| `A8` | **不许让既有绿步变红**；现树若有边界声明**真不成立** ⇒ **停下报主控** | 用"放宽判据／删断言"换绿 ⇒ 拒 |

## §2 生效边界与射程（逐字）

- **`TASK-0732` 判的是**："**声明说的话与树上的形状是否一致**"，**不是**"这条声明在语义上该不该存在"，也**不是**"现件代静默 SEGV 已清零"（那是 `TASK-0726`／收口腿的职分）。
- **本牙对"接线"是保守的**：传递闭包**看不见靠变量间接的调用**（`bash "$DIR/x.sh"` 这种令牌不以路径形态出现）⇒ 可能漏判"已接线"；反之 `route=` 命中的**都是真路径**。
- **`COPY-CENSUS` 的外部部分只证**「语料**枚举出的**那些车道里，副本首行确实标了废」；**未枚举**的第三方副本不在射程内；车道被回收 ⇒ `evaporated`（**如实不变红** —— 声明讲的是**当时那次标记行为**）。
- **覆盖闭包的残余**：`key` 不在记录键集里的候选项只作 `bystander` **上屏**、**不进 `rc`**。
- **全量断言口径（`D-G140`）**：本牙的语料普查是**每次运行现取重扫**，读数**必带** `DECL_CORPUS files=<n> at=<时刻> digest=<sha16>`；**一次性扫描的结论只能当当时的读数**。

## §3 判据（落地前写死）

### 3.1 回归判定（本波不适用）
⚠️ **`#76` 是仪器／装置波**（把边界声明做成机读读者 ＋ 文档面与在册数补正）⇒ **不做任何回归判定**：本波**没有**任何"两臂对拍比出一个率"的主张 ⇒ 回归判定四要件（两臂同刻／成对归因臂／复现性／Fisher 双尾）对本波**不适用**。
⇒ 这一句声明的是「**如果**本波在别处声称做过回归判定，**那么**四件必须同时在位」，**是"这一刻不适用"的声明，不是"我已经做过"的声明**；判词三态在别处用 `PASS` ／ `FAIL` ／ `NOINFO`，`NOINFO` **既不算绿也不算红**。

`PREREG-NO-REGRESSION-DECISION: not-applicable-instrument-wave-76`

### 3.2 `0732` 牙的三态与阈值
`BOUNDARY_DECL=PASS⇒rc=0` ／ `FAIL⇒rc=1` ／ `NOINFO⇒rc=3`（**谓词的域取不到 ⇒ NOINFO，不许当绿**）／ `2=用法错`。
**判否**：`观测记录数 == 0`、`DECL-BOUNDARY-COUNT` 与观测数不符、被覆盖候选数 `== 0`、任一记录 `FAIL`、任一**缺口** ⇒ 一律非零（**宁可不判、不许假绿**）。

### 3.3 两极化（**每条都真跑**；构造与逐格期望见 §3.3.1，原始读数见波报的 `polarity.md`）
正极＝现树；反极 ①a 直调／①b 经 wrapper（拼写漂移不改判定）；反极 ② `target` 换成不存在的件名 ⇒ `NOINFO`（防"恒挂"）；反极 ③ 语料里加一条新声明而**不动牙** ⇒ `FAIL`（证通用性）；反极 ④ 删记录 ⇒ `record-count-mismatch`；反极 ⑤ 未覆盖声明 ⇒ `declaration-without-predicate`；反极 ⑥ 副本未标废 ⇒ `lane-unmarked`；反极 ⑦ 车道回收 ⇒ `evaporated`（**不变红**）；反极 ⑧ 零记录 ⇒ `FAIL`。

### 3.4 判否条件（本波）
任一极化腿**没有成对读数**（两条腿都绿／都红）⇒ 该腿作废，须重做或如实登记 `NOINFO`。

## §4 边界声明（**机器可判**；本波新落的两条记录）

<!-- 说明：以下两行是**记录**（`records`），不是散文。牙从**语料**里读回它们；
     `restates=` 用**内容锚**（`<文件>#<令牌>`）而不是行号 ⇒ 历史件插行不会让锚漂移。 -->

DECL-BOUNDARY-COUNT: 2
DECL-BOUNDARY-BYSTANDERS: expect=2

DECL-BOUNDARY: id=W68-UNWIRED-PRODUCER family=WIRING target=build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh expect=unwired-in-step key=producer restates=WAVE68-PREREGISTRATION.md#producer=UNWIRED-IN-STEP,WAVE73-PREREGISTRATION.md#producer=WIRED-ON-DEMAND

DECL-BOUNDARY: id=W68-LEGACY-COPIES family=COPY-CENSUS target=build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh n=7 enum-from=WAVE68-PREREGISTRATION.md#legacy-copies=DEPRECATED×7 key=legacy-copies restates=WAVE68-PREREGISTRATION.md#legacy-copies=DEPRECATED×7,WAVE73-PREREGISTRATION.md#legacy-copies=DEPRECATED×7

**旁观上限（`DECL-BOUNDARY-BYSTANDERS: expect=2`）**：语料里「**行首即声明位**」但**不属于任何记录键集**的令牌
（本波现读 **2** 条：`WAVE16-PREREGISTRATION.md:203 caliber=OK`／`WAVE46-PREREGISTRATION.md:38 detail=N`）
按（**语料路径 `LC_ALL=C` 排序 ＋ 行号升序**）的**前 `expect` 条**视为**已批准的合法旁观**；
**超出即红**（`rule=bystander-tree-grown`，逐条点名 `file/line/token`）。
⇒ 将来某一波**新写一条边界声明却不给谓词**，本步**当场红** —— 而不是"历史记录还在 ⇒ 照旧绿"。
缺此行 ⇒ `FAIL reason=bystander-expect-absent`（**空边必须响亮失败**）。

**⚠️ 绿的依赖（如实写清，不许被读成"历史语料下它也绿"）**：本步的 `PASS` **依赖本预登记件里的三行声明**
（`DECL-BOUNDARY-COUNT` ＋ `DECL-BOUNDARY-BYSTANDERS` ＋ 两条 `DECL-BOUNDARY:` 记录）。
**只有历史语料（未落本波预登记）时**：`records=0` ⇒ `FAIL reason=no-record-parsed`，而历史散文声明
（例如 `#68` 预登记里那条以 `producer=` 起头的 `UNWIRED-IN-STEP` 声明）一律现形为 `DECL_BYSTANDER`（**可见、不静默**）。

**这两条记录说的是什么**（散文，供人读；判据在上面几行）：
1. `W68-UNWIRED-PRODUCER` —— `#68` 写的「产出端**仍在车道目录**、`verify-all.sh` 里**没有任何一步调用它**」与 `#73` 改写的「产出端**已进仓**、但**仍没有一步调用它**」，都被求值成同一个**件路径**上的谓词：**该件不在 `verify-all` 的调用闭包里**。判据域是**路径身份**：`run_step` 的**步名字符串**怎么拼、路径写成什么形态、经不经包装件，都不影响判定。
2. `W68-LEGACY-COPIES` —— 「8 份同形产出端里 7 份已标废」被求值成：**取代者存在** ∧ **仓内同基名唯一** ∧ **语料枚举的项数 == 声明件数** ∧ **枚举出的每个车道里 ≥1 份副本首行点名取代者**。
3. **降级通道**：给不出可在真树上求值的谓词的声明，按 `D-G132` 口径句**降级为备注**并逐字标注 `UNVERIFIABLE-BY-TOOTH`（本波**无**降级件）。

## §5 落仓那刻的声明值（**断言相等**，不是常量）

<!-- W76-DECLARED: steps=47 coverage=204 -->
| 量 | 声明值（预计） | 落仓断言 |
|---|---|---|
| 步数（纪律 46 真不变量） | `47` | 首行 `DECL` 步数 == 现取 `grep -c '^run_step "'`；不符 ⇒ `rc=9` 回滚 |
| 覆盖面 `fp_inputs()` 实跑件数 | `204` | 实跑 `fp_inputs()` 现算 == `[42] --expect` 现值；不符 ⇒ `rc=9` 回滚 |
| `win32shim` 世代位 | 不变 | 重建后实测 `.so` sha16；若变 ⇒ **停下报主控**（本波不声明 `allow_changed` 含 `wsh`） |

⚠️ 前一波（`#75` 合波）会先把基点推到 `46` 步／覆盖面 `202` ⇒ 上表两值**落仓那刻一律重取**；`#75` 未落地 ⇒ **不许**照预计值落仓。

`LANDING_OWNER=W176A`｜`WRITER=W176A（唯一）`｜`R_TOUCHED=见落仓器读数`｜`DOC_FACE=交主控（本波不直改主控五件：`KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`FORK-AND-PUSH.md`／`defect-registry-declared.tsv`）`
