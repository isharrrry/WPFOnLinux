# 波 `#68` 预登记 —— `TASK-0722`（`D-G123` 口径修法：**判据端入仓**）

> **判据先写**：本文件在**任何落仓动作之前**写定并冻结（`CRITERIA_FIRST=yes`）。
> 本波落仓集（**逐件**）：`build/MilBridge/tools/silent-hit-v2-check.sh`（**新建**）｜`build/MilBridge/tools/silent-hit-v2-cases.tsv`（**新建**）｜`verify-all.sh`（**加一步 ＋ 四处声明同趟**）｜`build/close-wave.sh`（`fp_inputs()` 白名单 **＋2 行**，本波是**第三手**）｜本文件。
> ⚠️ 本波**不改任何产品件** ⇒ 九位 sha 逐位不动。

## §1 本波要交什么（逐条可判否）
| # | 交付 | 判否（不满足即**拒落**） |
|---|---|---|
| H1 | 判据端牙（新 `.sh` ＋ 新 `.tsv`） | `--selftest`／`--gate-selftest`／`--cases --expect 12` 任一非 0 ⇒ 拒落 |
| H2 | `verify-all.sh` 第 `[N]` 步 `SILENT-HIT-V2` | `bash -n` 非 0，或第 `[11]` 步（`verify-all-step-check.sh`）**不为 `PASS`** ⇒ 拒落 |
| H3 | 四处声明同趟 | `DECL` 首行／步名清单／头注释口径句／本文件 **缺一** ⇒ 拒落 |
| H4 | `fp_inputs()` 白名单 ＋2 行 | 覆盖面件数**不等于**基点 +2，或指纹**逐件归因不成对** ⇒ 拒落 |
| H5 | `UNWIRED` 两条声明 | 缺任一条 ⇒ 拒落（**不许把 `--cases` 的 `PASS` 读成"现件代已复现／已清零"**） |

## §2 判据（落地前写死）
### 2.1 判据本体（`SILENT_SEGV_HIT` 第一支的 v2 口径，**合取**）
```
SILENT_SEGV_HIT ⇔  APP_TEXT_BYTES_TRIMMED == 0
                ∧  STACKOVF == 0
                ∧  死于 SIGSEGV（SEGV_BRANCH ∈ {rc139, fate, term, stop-signo11}，**命中时必须印出是哪一支**）
```
两条**前置闸**（缺一即 `NOINFO`，不进分母）：① `UNDECLARED_TAG_LINES > 0 ⇒ NOINFO reason=undeclared-instrumentation`；② `phase == teardown`（收进程期死亡）**不计命中**。
**两个数都印**（`APP_TEXT_BYTES` 原始 ＋ `APP_TEXT_BYTES_TRIMMED` 剔除后）；**剔除集从文件读、行首锚定**（**禁**子串包含式剔除）。

### 2.2 三态与阈值（`rc` 口径）
`SILENTHIT=PASS` `rc=0`（台账每行判词与声明相符 ∧ 阳性对照至少一行真 HIT）｜`SILENTHIT=FAIL` `rc=1`（判词不符／阳性对照不成立／行数与 `--expect` 不符／产出端机读行缺字段或陈旧）｜`SILENTHIT=NOINFO` `rc=2`（台账缺文件／空表／**缺列**／非整数／**零行被检查**）｜用法错 `rc=3`。
⚠️ **零检查必须报红**：`examined == 0` **一律** `NOINFO rc=2`，**永不** `PASS`。⚠️ `NOINFO` 既不算绿也不算红；**不许**把"没有数"读成 `0`（产出端缺字段 ⇒ `FAIL`）。

### 2.3 两极化（正极必现／反极必不现；**每条都真跑**）
1. **判据本体**：`--selftest` 9 例 —— 三态齐备（`HIT/NOT-HIT/NOINFO`）∧ **退化实现（只看第一支）必须翻动 ≥1 格**（实测 `degenerate_flips=3`）。
2. **门槛与极性**：`--gate-selftest` 12 例 —— `--cases` 好表必 `PASS`／**无阳性对照行必 `FAIL`**／空表与缺列必 `NOINFO`／行数不符必 `FAIL`／产出端缺字段必 `FAIL`／无产出端必 `NOINFO`／`--polarity` 在位必 `PASS` ∧ **不在位与假牙各必 `FAIL`**。
3. **步数声明链**：在真拷贝树里**删掉那条 `run_step` 行而保留声明** ⇒ 第 `[11]` 步必须红（`count-mismatch`）；恢复 ⇒ 必须 `PASS`。
4. **变体真的在位**（`D-G128` 实例②）：屏上 `sha16` == 树里 `sha16` ⇒ `PASS`；把树里的 `sha16` 换成未变体值 ⇒ **必须 `FAIL` 点名 `VARIANT_INPLACE 不成立`**。

### 2.4 判否条件
- **判否-1（假牙）**：反极性腿**切断被注入物却不翻转** ⇒ 该腿读数作废（`D-G128`）。
- **判否-2（混比）**：`--denom` 出现**合池**行或真件代 ≥2 而缺率 ⇒ **整张率表作废**。
- **判否-3（恒真闸）**：喂一条**未声明**的具名插桩行，完备性闸**必须**非 0（恒 0 ⇒ 闸不成立）。
- **判否-4（读大）**：把 `--cases` 的 `PASS` 读成"现件代已复现／已清零" ⇒ 违规（见 §3 `UNWIRED`）。

### 2.5 回归判定（本波不适用）
⚠️ **本波（`#68`）不做任何回归判定** —— 本波是**判据装置**波（把一条**早已在册**的判据做成仓内牙），**没有**任何"两臂对照 ⇒ 比出一个率"的设计 ⇒ 本波**不适用**回归判定四要件。
⇒ 这一句是"**这一刻不适用**"的声明，**不是**"我已经做过"的声明；本波**未**声明任何判定结论。

### 2.6 生效边界与射程（逐字声明）
- **生效波**：`#68` 收官起，第 `[N]` 步 `SILENT-HIT-V2` 生效（`N` 由**现场现算**：`DECL` 首行给出，本文件的任何位置**不写死步数**）。
- **射程**：本步判的是"**判据装置还活着 ∧ 不许把不可判当零命中**"，**不是**"静默 SEGV 已消失"。**现件代的静默 SEGV 率**本波**不给**（需真腿，属 `TASK-0726`／收口腿）。

## §3 `UNWIRED` 两条（逐字；**必须**与 `DECL` 首行同趟落）
1. **`producer=UNWIRED-IN-STEP`**：产出端（起显示 ＋ 跑应用腿的**腿驱动**）**仍在车道目录**（8 份同形副本），`verify-all.sh` 里**没有任何一步调用它** —— 判据口径须限定到**代码形状**（`grep -cE '^[[:space:]]*run_step .*silenthit' verify-all.sh` **= 0**），**全文 `grep` 命中只作旁证**（`D-G119` 实例㉔）。⇒ **不许把 `--cases` 的 `PASS` 读成"现件代已复现／已清零"。**
2. **`legacy-copies=DEPRECATED×7`**：8 份同形产出端里 **7 份**（`w118a`／`wc06`／`wc07`／`wc08`／`wc11`／`w155a w65d109`／`w159a`）在唯一产出端落仓后标废（头一行 `DEPRECATED-BY=… (WAVE68)`）；`w128a/bin/one128.sh` **留作历史真命中的产出者证据**。⇒ **收编归 `TASK-0726`（排 `#69`）**。

`PREREG_WAVE=#68`｜`PREREG_TASK=TASK-0722`｜`CRITERIA_FIRST=yes`｜`LANDING_OWNER=主控（车道只交件，不落仓）`
