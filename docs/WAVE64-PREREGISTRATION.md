# 波 `#64` 预登记（**判据装置批**：把「基线率闸」做成仓内牙 · `TASK-0717`）

> 车道 **W157A**｜基线 `gen=#63 sha16=4ee96c043b472c11`／919,687 B｜本波**零产品改动**（只动判据装置与覆盖面）
> 判据先写件：`~/w157a/criteria.md`（`89ac288b87f13384`，391 行）｜方法页：`~/w157a/baseline-rate-gate.md`（`c4839dc9e8876bcf`／口径 `57915081ffdbacf8`）
> 报告：`build/MilBridge/W157A-report.md`

## §1 本波是什么

两件一次冻（牙 ＋ 它的台账），另接线两处：

| 件 | 任务 | 入口件 | 修前 → 修后 |
|---|---|---|---|
| ① | `D-G118` 的牙：**基线率闸** | `build/MilBridge/tools/baseline-rate-gate.sh` | **新建** → `31cf77abc6a882e3` |
| ② | 该牙的**台账**（11 行确定性用例） | `build/MilBridge/tools/baseline-rate-cases.tsv` | **新建** → `8d71171d475a63dc` |
| 接线 | 第 `[37]` 步 ＋ 四处声明 | `verify-all.sh` | `2819b5990e74cc80` → **见 §4** |
| 覆盖面 | `fp_inputs()` 加两行 | `build/close-wave.sh` | `9ee0c2488d25f6f6` → **见 §4** |

## §2 判据（**先写**，逐字）

### 2.1 口径句（`D-G118`，入册）

> **"条件同一性必须包含『世界的时间稳定性』；凡登记速率都必须带**时间窗**，
> 且用于定 `N` 之前必须在**同窗现取**一道基线率闸 —— 对不上就 `VOID-PREMISE`，
> 不许拿历史速率凑功效。"**

**为什么需要它（现场）**：`TASK-0111` 的 `N=40` 是由历史速率 `0.889 → 0.589` 反推的；而三批**世界逐位相同**
（`BRIDGE`／`SHIM`／动作坐标 `M1@(400,15)`→`R2@(1206,15)`／红签名全同）、**只有时间变了**：
`09-23 17:25 :221` = `12/12 = 100%` → `09-24 09:47–10:48` = `7/28 = 25.0%`（Fisher 双尾 `9.02e-06`；Wilson 上界 `< 0.70`）
⇒ 基线率**不是常数** ⇒ 由它反推的 `N` 不成立 ⇒ 该批**注定无功效**（已判 `VOID-PREMISE`、40 腿未跑）。

### 2.2 三态判据（牙的机读行）

```
BASELINERATE=PASS      ⟸ 历史速率**落在**新样本 CI 内 ∧ ci_upper ≥ gate ∧ observed ≥ effect ⇒ 可继续，并给 required_n=
BASELINERATE=FAIL      ⟸ 闸判失败；**必报「历史速率落在新样本 CI 之外」**（DRIFT）或 VOID-PREMISE 具名
BASELINERATE=NOINFO    ⟸ 缺时间窗／空样本／n 非正／r 越界／口径争议／参数不可解析 ⇒ **响亮失败**（禁静默判等）
BASELINERATE_RC        = PASS:0 ｜ FAIL:1 ｜ NOINFO:3
```
**字段行（逐项）**：`registered=<R>/<n>@<时间窗>`／`window=`／`observed=`／`observed_rate=`／`ci_upper=`／
`ci_upper_2s=`／`ci_lower_2s=`／`cp_upper=`／`fisher_p=`／`registered_in_observed_ci=`／`gate=`／`effect=`／
`required_n=`／`required_n_power=`／`voidpremise=`／`voidpremise_reason=`／`gate_closed=`／`effect_impossible=`／
`caliber_disagreement=`／`gate_verdict_1s=`／`gate_verdict_2s=`。

### 2.3 `VOID-PREMISE` 的**两条并列**条件

- ① `ci_upper < gate` —— 先写的闸门被**排除**（不是"没观测到"）。
- ② `observed < effect` —— 要排除的效应量**在现世界不可发生**（连重算 `N` 都无意义）。
- **两条同时成立就并列打出**，**不取其一**。

### 2.4 🆕 **口径之争先于结论**（加严，非放宽）

- **主判据** = Wilson **单侧** 95% 上界（`ci_upper=`）；**诊断列** = 双侧（`ci_upper_2s=`／`ci_lower_2s=`）＋ Clopper–Pearson 单侧（`cp_upper=`）。
- **当两个口径在闸比较上结论不同**（`ci_upper_1s < gate ≤ ci_upper_2s`，或反向的边界情形）
  ⇒ 判词**必须** `NOINFO` ＋ 具名 `reason=caliber-disagreement`，**禁止**用"对我方有利的那一界"下 `PASS`／`FAIL`。
- **理由**：本会话已有一整族"**选口径／挑仪表**"的现场（`D-G98` 的"一格定罪"、`D-G118` 的"拿历史速率凑功效"、
  `#63` 派单里把结果侧算进体制）⇒ **口径之争先于结论，必须显形**。

### 2.5 「不做回归判定」声明（`TASK-0709` 的适用性）

PREREG-NO-REGRESSION-DECISION:

**本波不做任何回归判定**（`N/A`）：本波只落**判据装置**（一牙一账）与接线，**无被试件、无对照臂、无两臂比较**
⇒ 回归判定四要件对本波**不适用**（`N/A`）。本件**不含**任何判定工件机读判词行、**不含**回归判定台账文件名
（⚠️ 本件**刻意不逐字复现**那两个"证据串"：该牙的"有证据"检测是**全文子串匹配** ⇒ 逐字提到会被判成"有证据"而走 `FAIL`，
**假红方向**。这是**已登记的射程边界**，`#60`／`#63` 预登记同样踩过）。

## §3 两极化与反极性（**先证判据会失败**）

**台账 11 行**（`--cases` 形态；**全部确定性合成**，不依赖任何现场腿读数）：

| 行 | 用例 | 期望 |
|---|---|---|
| 1 | `DG118-task0111-live-drift`（**本缺陷真实现场**，冻结常量） | `FAIL/1/DRIFT` |
| 2 | ⓐ 同窗自洽 | `PASS/0/PASS` |
| 3 | ⓑ 样本掉出 CI | `FAIL/1/DRIFT`（**点名**） |
| 4 | ⓒ `observed < effect` | `FAIL/1/VOID-PREMISE` |
| 5 | ⓓ 空样本 | `NOINFO/3/NOINFO-EMPTY-SAMPLE` |
| 6 | ⓓ′ 缺时间窗 | `NOINFO/3/NOINFO-NO-WINDOW` |
| 7 | ⓓ″ `n` 非正 | `NOINFO/3/NOINFO-N-NONPOS` |
| 8 | ⓓ‴ `r` 越界 | `NOINFO/3/NOINFO-R-RANGE` |
| 9 | 反例 ① `22/27` | `PASS/0/PASS`（`required_n=43`） |
| 10 | 反例 ② `12/12` | `PASS/0/PASS`（`required_n=21`） |
| 11 | 🆕 口径打架（闸取在两界之间） | `NOINFO/3/caliber-disagreement` |

- **反例 ①②** 证明闸**不是**恒判 `VOID-PREMISE`（`D-G89`：判据必须能失败，也必须能不失败）。
- `--selftest`（夹具在 **`$HOME` 沙箱**）另含**反极性**：把某行 declared 期望改错 ⇒ 必须 `rc≠0`（证明"比对"真在比）。
- **算程自证**：与 `W157A` 的独立算程**逐位对账**（`observed 0.2500`／`cp_upper 0.4187`／`fisher_p 1.848e-06`／
  双侧 `[0.1268,0.4336]` 全同）；并**逐位复现**仓内在册四个 `REQUIRED_N_ALT` 值（`7/0.8224`、`37/0.8010`、`41/0.8019`、`131/0.8041`）。

## §4 覆盖面与九位（**成对记账**）

- **覆盖面 `159 → 161`**（`fp_inputs()` 加两行：牙 ＋ 台账）。**先例**：回归判定牙**与它的台账**成对在名单里（现场 `list` 命中 2 行）。
- **三处作用**：① 牙入名单 ② 台账入名单 ③ `close-wave.sh` **自含**于覆盖面而被改。
- **成对归因**：落地前后各取一次指纹；**交叉表**按"哪个件处于已打补丁状态"命名（逐件置换 ＋ 全组合）；
  **全部退回 ＋ 删两行 ⇒ 逐位 == `prev_infp`**（`7836c5fa17cd454893f9a4101fe2210181217f035c306122cbbed259293a772f`）；
  替换/撤销类脚本**一律断言 `hits`**（`hits` 断言曾缺过一次、吃过假"无位移"）。
- **九位**：本波**零产品改动** ⇒ 只允许 **`pf` 同尺寸位移**；出现第二处位移 ⇒ **停手报主控**。

## §5 射程边界（**逐条**）

1. 本步判的是「**在册速率还能不能用来定 `N`**」—— **不**重判任何回归结论（不替代四要件）。
2. 本步跑 `--cases`（**确定性合成**）⇒ **不会随被测世界漂移而红/绿**；**判据步不许随被测世界漂移而红/绿**。
3. 「漂移的**成因**」（系统负载／时间 vs 别的东西）**本波不判** ⇒ `NOINFO`（要专门设计的负载对照批）。
4. 本牙给的是**先写闸的机器化**，**不**自动决定任何波的趟数；`N` 一律由现取基线率重算。
5. **不许**为让闸成立而：放宽红定义／换更红的世界／动 `START_MAX` 之类的闸／事后改趟数或功效。

## §6 本波**不做**的事

- 不改任何产品件（`src/**`、`samples/**` 的冻结件一律不动）。
- 不为 `TASK-0111` 再跑任何腿（该件已归档为"不可判 ＋ 已知无产品价值"）。
- 不碰 `docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/HANDOFF-NEXT.md`（主控写域）。
