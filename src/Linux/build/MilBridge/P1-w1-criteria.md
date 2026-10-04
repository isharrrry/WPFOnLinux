# P1-W1 文档口径批判据（**先写，后取读数**）—— `scribe` / `t10`

`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜基点 `HEAD=88ab841`｜本件读时 `2026-09-28T1?:??+08:00`（见 §7 现取）
侦察件＝`build/MilBridge/P1-tail-scout.md`（`493808af2699c40a`／569 行，**已现取读过 W1 行与六个小节**）

## 0 写域（超出即停手报队长）
**改**：`docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`（同趟 `--emit`）｜**仓外附项**：`~/w21-verify/w27-freeze.py`（**仅注释**）。
**新建**：`build/MilBridge/P1-w1-criteria.md`／`build/MilBridge/P1-w1-report.md`。

## 1 六条各自「判什么」（判据先写死）
| 条 | 判什么 | 成立（绿） | 不成立 |
|---|---|---|---|
| **B-1** | 册内 `D-G176` 的**条目形态标题 ≥1** ∧ 该编号在 `declared` 集 ∧ 册内至少出现一次；且 scout 要求的三条子结论**逐条在册可现取** | 三条合取全真 ＋ 三条子结论各有现取锚 | 任一条缺 ⇒ 点名缺哪一条 |
| **B-5** | `~/w21-verify/w27-freeze.py` 注释里每个 `sha16` **能在 `P0-w80-report.md` §6/§10 里逐字找到** ∧ **同一值不在注释里重复出现** ∧ **本件逻辑零改动** | 三条全真 ＋ `py_compile` 过 | 任一条不真 ⇒ 逐条点名 |
| **B-11** | `HANDOFF-NEXT` §1–§6（＋ §7 命令块）的**每个机器值**都有①内容锚②**一行现取生成命令**③现取值④牙草案 | 每格四件齐 ∧ 我现跑生成命令得的值 == 我写进件里的值 | 任一格缺件 ⇒ 点名该格 |
| **B-13** | 在册文本写明「哨兵 `FP` ＝ `BRIDGE_SRC_FP` ≠ `inputs_fp`」＋**定义链内容锚**＋**两个现取值** | 口径句 ∧ 定义链锚 ∧ 两值现取相符 | 缺一 ⇒ 不成立 |
| **B-16** | 在册写明 `TASK-0303` 行的引用是**前缀口径**：`head -568` 的 sha16 == 行内值 ∧ **整件** sha16 ≠ 行内值 | 两读数逐位相符 ∧ 件内出现「前缀」口径词 | 整件值恰好相等（则"前缀"提法不可判）⇒ `NOINFO` |
| **B-17** | 在册写明两种口径**各具名**（tree-form `79` ＝ 带 `[kind]` `77` ＋ 不带 `2`）＋ 记号取法句 | 我用自写抽取器**独立复算**两种口径逐格相符 | 复算不符 ⇒ 按现取写并点名侦察值 |

## 2 分母与口径（先写死）
- **tree-form**：`§13` 区内（`## §13 ` 头 → 下一个 `## §` 头之前），剥掉树绘制前缀（`│├└─` 与空白）后**以 `TASK-\d{4}` 起头**的行。
- **带 `[kind]`**：上述行中**紧跟 `TASK-\d{4}` 出现 `\s*\[[A-Za-z]+\]`** 者。
- **记号取法**：**取标签后那一个记号**（`✅🟡🔴⚪`）—— 与 `§13` 已落的 dated 规则一致（本波只**写明**，不改规则）。
- **覆盖面**：`~/w153a/bin/infp.sh list | wc -l`（尺子 A）＝ **两把尺子互证**（尺子 B ＝ `~/w-p0mig/bin/infp-n.sh list`）。
- **`inputs_fp`**：`~/w153a/bin/infp.sh fp`（**不是**哨兵 `FP`）。
- **DEFREG 三态**：`PASS rc=0`／`FAIL rc=1`／`NOINFO`。

## 3 `NOINFO` 条件（具名；不许当绿）
1. **B-11 的「脚本现取生成／会红的牙」落地**：新牙件（`build/MilBridge/tools/handoff-machine-values-check.sh`）＋`build/close-wave.sh` 的 `fp_inputs()` ＋`verify-all.sh` 的 `[42] --expect` **三处都不在本波写域** ⇒ 本波只落**生成命令契约 ＋ 牙草案 ＋ 代价与位置**；自动化落地转 W4（scout 已如此分波）。`NOINFO(reason=落地件不在本波写域)`。
2. **B-1 的「`#79` 块 `759ac1686e5ef87d` 对应哪一个物理时刻」**：历史时刻↔产物对应关系现取不可判（侦察 §5-7 同结论）⇒ 只登记四处**现取值**，不判时刻归属。
3. 若某条的目标件里**已存在**该口径（无待办事）⇒ 如实记「已成立、本波零动作」，不当红。

## 4 越域判据
`git status --porcelain` 必须只出现：`M` 上述 4 件（其中 `declared.tsv` 必为 `2/2`）＋ `??` 我的两件；**任何第 5 件被改即停手**。
`~/w21-verify/w27-freeze.py` 的**逻辑零改动**证明：改前/改后 `python3 -m py_compile` 均过 ∧ **只有注释两行**发生变化（逐字节 diff 只在该两行）。

## 5 只增不改
除 B-5（注释行，属"文本更正"，须逐字给改前/改后）外，其余五条一律 **dated 追加**；
`git diff | grep -c '^-[^-]'` **允许为 0**；若 >0 必须逐行点名并给理由。

## 6 同趟性
凡 `KD` 被改 ⇒ 编辑**全部在 `--emit` 之前**完成，之后不许再动 `KD`；随后 `--emit` 重发 ＋ **两遍** `DEFREG` ＋ `REPORTID`（增量逐件归因）。

## 7 收口
报告 `build/MilBridge/P1-w1-report.md`：六条各自「改前原文引用 ＋ 新增/改后逐字」＋ 两遍 `DEFREG` 原始行 ＋ 入口/出口 `inputs_fp`／覆盖面 ＋ 自报 sha16 ＋ 读取时刻。
