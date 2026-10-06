# 任务：把冻结世代对齐到 **#85**（补齐"号值面"，不碰产品件）

> 现状（主控现读）：`docs/CURRENT-STATE.md:9` = `gen=#84 sha16=d530038a13ca9251`；两枚哨兵 = `WAVE=w84-freeze`／`BASELINE=#84`；
> 而 **`GENS['#85']` 已存在**、O4 的记录段已在仓内 `docs.Linux/evidence/freeze/w85-record.txt`（**内含未填的占位 `date=2026-10-06Txx:xx+08:00`**）。
> ⇒ 编号面分叉：**声明说 #84、记录说 #85**。本任务把两边**对齐到 #85**。
> 先读：`docs/PORT-SPEC.md §5`、`docs.Linux/evidence/O1-O4-O6-REPORT.md`、`docs.Linux/evidence/STRUCTURE-UPSTREAM-WAVE-REPORT.md §5`。

---

## ① 要做的事（顺序不可反）

1. **确认九位未变**：先现取九位（`python3 src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py` 的 `NINE` 口径／
   `~/w153a/bin/infp.sh` 等现成读端），与 `ACCEPTANCE-BASELINE.md` 现块里的九值**逐位对照**；有差 ⇒ **停下报告**（那说明该走完整重冻，不是编号对齐）。
2. **补 `ACCEPTANCE-BASELINE.md` 的 `# RE-FROZEN #85` 块**：照上一代（`#84`）块的**形状**逐字来
   （含五条 `# ARM-LOG-SHA`、`# COLUMN-FLOOR`／`# COLUMN-CORPUS`；`#84` 降历史、**原文不删**）。
   内容写清本代**没有产品位移**（本代是"工具/结构面"改动：O1/O2/O4 ＋ 提交号载体根治）＋ 九位未变的事实。
3. **算新 sha16** ⇒ 写 `docs/CURRENT-STATE.md:9`：`gen=#85 sha16=<新值> file=src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`。
   ⚠️ **顺序**：先追加块、再算 sha16、再写行（否则 sha 对不上）。
4. **填实 `docs.Linux/evidence/freeze/w85-record.txt` 的占位**：`date=`／`display=` 用**现取真值**；
   `{NSTEP}`/`{NCASE}`/`{NSKIP}`/`{GEN}`/`{PREV}`/`{WSH*}` 一类占位**全部换真值**；`===FROZEN===` 段给本代九位 ＋ `BASELINE=#85` ＋ `BASELINE_SHA16=<新值>`。
   （口径：**记录里不许留占位符**。）
5. **两枚哨兵**：用写端（`src/Linux/build/MilBridge/tools/wave-push.sh`，**写盘档**）重发 ⇒ `WAVE=w85-freeze`／`BASELINE=#85`／`BASELINE_SHA16=<新值>`，并 `cmp` 自证两枚 `IDENTICAL`。
6. **`GENS['#85']` 复核**：`TXT` 指向**仓内**记录段（O4 已改）；`PREV` 应为 `'#84'`；`allow_changed`／`pf_required`／`green` 等字段与 `#84` 的**形状**一致且与现状**逐字段相符**（`WFREEZE_DECL` 会与预登记逐字段对拍 ⇒ 两边必须一致）。
7. **提交**（**本代只此一笔**，且**放最后**）——提交之后**不要再跑会重建的命令**。

## ② 验收（可计算）

| # | 判据 |
|---|---|
| A | `sed -n '9p' docs/CURRENT-STATE.md` 的 `gen=#85` 且 `sha16` **==** `sha256sum src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md \| cut -c1-16` |
| B | 两枚哨兵 `cmp IDENTICAL`，且 `WAVE=w85-freeze`／`BASELINE=#85`／`BASELINE_SHA16` == A 的值 |
| C | `w85-record.txt` **零占位符**（`grep -c 'xx:xx\|{NSTEP}\|{NCASE}\|{GEN}\|{PREV}'` == 0） |
| D | `[5c/6]`：`WFREEZE_CONSISTENCY=PASS`（四档，含 `NINESYNC`／`TEMPLATE_AUTO path=仓内`） |
| E | `bash Guide.Linux/verify-all.sh` **×2** 各 **67 ✅ / 0 ❌** |
| F | `THIRDPARTY=PASS max_colors ≥ 800`；十颗关键牙 rc=0；`git status --short` 干净 |

## ③ 边界

- **允许**：`docs/CURRENT-STATE.md`（**只动第 9 行 ＋ 必要的 dated 追加**）、`src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**只追加，不删不改历史**）、
  `docs.Linux/evidence/freeze/w85-record.txt`、`~/w21-verify/w85/**`、写端产出的两枚哨兵、`HANDOFF-NEXT.md`（如需更正行）。
- **禁止**：改任何**产品件**、改落点、削弱判据、把 `NOINFO` 当绿、为对齐而**删/改历史块**、
  在提交之后再跑重建类命令（会引入位移）。
- 若九位**确有**位移 ⇒ **停手报告**（那要走整波重冻，不是本任务）。

## ④ 报告

- 九位逐位对照（现取 vs `#84` 块的声明值）——**逐位给值**。
- 新 `CURRENT-STATE.md:9` 原文 ＋ `sha256sum` 现取。
- 两枚哨兵原文 ＋ `cmp` 结果。
- `w85-record.txt` 的 `===FROZEN===` 段原文 ＋ 占位符计数（应为 0）。
- `[5c/6]` 四档原文；`verify-all` **逐趟**步骤数；`THIRDPARTY` 行。
- `git log --oneline -3` ＋ `git status --short`；`inputs_fp` 前后值。
- 结论：**号值已对齐 #85** 或 **未达 ＋ 具名原因**。
