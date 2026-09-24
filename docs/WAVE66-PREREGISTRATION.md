# 波 `#66` 预登记（**`TASK-0720` 落仓**：A3 口径更正 ＋ 11 条 `#if NEVER` 死声明名单落册 ＋ 批 2a 三条 `LsErr` 诚实失败 ＋ `Nl*` 有意降级声明牙 ＋ `fp_inputs()` +1 行）

```
DECL: 37 gen=#66
```

> **时序声明（逐字，不许读成"先写"）**：本件与 `#66` 的落地**同趟**产出（标题行含 `#66` 是
> `verify-all-step-check.sh`（第 `[11]` 步）的硬要求：`^#+ .*#66`）。**判据本身先于落地读数**（见 §1 的
> sha16 链）；**本节不冒充"本件早于落地"**。

## §0 本波**不做任何回归判定**（机读）

```
PREREG-NO-REGRESSION-DECISION: 本波不调用回归判定牙、不产生判定台账、不据此改判任何一步。
```

## §1 判据（落地前写死；sha16 均为现场算）

**本波不做任何回归判定**（机读：`PREREG-NO-REGRESSION-DECISION:`）—— 本波不调用回归判定牙、不产生判定台账、不据此改判任何一步。
⚠️ **本声明必须在「判据」节内**：`prereg-four-requirements-check.sh` 的 `extract_section()` 只读**第一个标题含「判据」的节** ⇒ 把它写在 `§0`（节外）会被判 `state=fail missing=7`，冻前 `verify-all` 当场 **`36 ✅ / 1 ❌`**（本波现场第一例；见 `build/MilBridge/W66-report.md`）。

| 判据 | 取值口径 | 判否条件 |
|---|---|---|
| `C1` A3 注释改词 | 单行、行数不变 ∧ 同行保留「111 条」∧ 含 `TOOL-UNSOUND` ∧ 含 `可操作 91`／`实现口径 97` | 行数变 ⇒ 回滚 |
| `C2` 11 名死声明落册 | 落册名集合 **==** `check-numbers.py` 现算 `DEAD` 集合（成员表先取） | 缺任一 ⇒ 报主控 |
| `C3` 三条 `LsErr` 诚实失败 | 导出 `547 → 550` ∧ 三条各 `ret == -10000` ∧ 出参置 `NULL` ∧ `WpfLinuxWin32_PtsGapSelfCheck() == 1` | `exports ≠ 550` ⇒ 回滚 |
| `C3-j` **自检牙齿**（`D-G128` 实例①） | 删掉某入口的出参清零 ⇒ `SELFCHECK` **必须 = 0**；`P03`＋`P03X` **同趟** | 删了仍 = 1 ⇒ 判该断言**无牙** |
| `C4` `Nl*` 声明牙 | 仓内件 `--selftest` `4/4` ∧ live `PASS`（**三态：`NOINFO` 不算通过**） | `--selftest` 非 `4/4` ⇒ 不许落仓 |
| `C5` 覆盖面 +1 | `fp_inputs()` 成员表出现新牙（现算成员表，不引历史常数） | 成员表 0 命中 ⇒ 不许落仓 |

## §2 落地件（逐字节可复原；写前逐件断言 `stat -c %h == 1`，不满足**拒写**）

| 件 | 内容 |
|---|---|
| `P01` | `src/WpfGfx.Linux.Native/src/win32_classification.c` 注释口径更正（单行、保行数） |
| `P02` | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 11 条 `#if NEVER` 死声明名单落册（**由主控落行**） |
| `P03`＋`P03X` | `src/WpfGfx.Linux.Native/src/win32_pts.c` 三条诚实失败 ＋ 自检牙齿修订（**必须同趟**） |
| `P04` | **新建** `build/MilBridge/tools/nl-intent-check.sh` |
| `P05` | `build/close-wave.sh` 白名单 +1 行（覆盖面 162 → 163） |

## §3 预期位移（落仓后**现算**，不抄推算）

覆盖面 **162 → 163** ∧ `inputs_fp` 位移（成对归因：**只多这一行**）；九位**不应动**（本波零产品改动）；
`verify-all.sh` **不在覆盖面** ⇒ 两条声明不动指纹。

## §4 边界

本波**不接线** `nl-intent-check.sh`（`UNWIRED`；接线归 `[Next] TASK-0724`）；
`P02` 的落行与 `declared.tsv` 重发由主控执行。
