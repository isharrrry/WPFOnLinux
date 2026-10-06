# 任务：收尾 —— 让 `close-wave [5c/6]` 在**重建之后**仍四档 PASS ＋ 修外部冻结器 `NINE` 表

> 现状：`feat-Linux = 57840fbe9`，工作区干净，`verify-all` **66✅/0❌（连跑两趟皆同）**，
> `THIRDPARTY=PASS max_colors=1644`，八颗关键牙全绿。
> **唯一剩下的具名残余** = `close-wave [5c/6]` 的 `nineauth`/`blockvalues` 在**跑过一轮重建后**转红。
> 先读：`docs.Linux/evidence/STRUCTURE-UPSTREAM-WAVE-REPORT.md` §4、
> `src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py` 件头（四档口径）、
> `src/Linux/build/MilBridge/blockvalues-shift.tsv` 件头，以及 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 里 `D-G176③` / `D-G92` 的登记条。

---

## ① 目标（可计算）

```bash
# 先制造"重建之后"的语境（这一步是判据的一部分，别省）
cd /home/links-dev/netTest/GitProj/WPFOnLinux
WAVE_OWNER=$(whoami) bash src/Linux/build/close-wave.sh        # 或至少跑它的 [1/6] 重建段
python3 src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py --root . --template auto \
  | grep -E '^WFREEZE_(ROOTDEFAULT|DECL|NINEAUTH|BLOCKVALUES|CONSISTENCY)='
# 期望：WFREEZE_CONSISTENCY=PASS（四档全 PASS），且在"重建之后"仍成立
```
并且：`bash Guide.Linux/verify-all.sh` 仍 **66 ✅ / 0 ❌**；空帧不许回归（`THIRDPARTY` 仍 `PASS max_colors≥800`）。

## ② 两条候选处置（**先取证、再二选一或组合；不许凭感觉**）

- **(a) 判据口径**：把**环成员**（`PF⇄ReachFramework` 互引 ⇒ **无字节不动点**；`ARTIFACT-SRC-FP.txt` 件头有自述）
  从"逐位相等"改为"**只核 `block9↔tier` 相等；`live` 逐条上屏但**不判**"。
  依据：工具里**已有同类机制**（`WFREEZE_BLOCKVALUES_TIER_NA keys=windowsbase,hbtextline,dwf（机读行按设计只覆盖 7 键 ⇒ 只由九位行授权，不判）`）
  ⇒ 这是**沿用既有设计**，不是新开口子。
- **(b) 程序口径**：`close-wave` 在"已 `[1/6]` 重建"的语境下**跳过 `[5c/6]`**（或把 `[5c/6]` 挪到重建之前）。
  ⚠️ 这条路**更弱**（等于不判），若选它必须在报告里写清"免读宽"。

**硬要求（两条都适用）**：
1. **逐条上屏、不许静默**（放行必须可见）；
2. **反极性必须真跑**：人为把 `pf` 的 `block9` 与 `tier` 改成**不相等** ⇒ **必红并点名**（写进该牙的 `--selftest` 或既有反极腿）；
3. **不许**用环境开关把整档关掉、**不许**把 `NOINFO` 当绿、**不许**改 `--expect` 之类来凑。

## ③ 顺带修（小的两件）

4. **外部冻结器 `NINE` 表**：`~/w21-verify/w27-freeze.py:1615`（`NINE`）**仍写旧落点** ⇒ 落位后跑不起来。
   **先备份**（`cp -p ~/w21-verify/w27-freeze.py ~/w21-verify/w27-freeze.py.bak-pre-nine`），把 `NINE` 的九条路径改成**现落点**
   （权威路径表以 `src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py` 的 `NINE_PATHS` 为准），
   并自证：该脚本的**只读档**（如 `--help` 或 `--template auto` 相关路径）在新落点下能取到件。
5. `~/w21-verify/w83/{logs,bin}` 为空 ⇒ 按 `#82` 的形状补齐**最小**链条件（`bin/w83-chain.sh` 之类，照 `w82/bin/w82-chain.sh`），
   或如实说明为何不需要（二选一，写进报告）。

## ④ 边界

- **允许**：改 `src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py`（含其自检）、
  `src/Linux/build/close-wave.sh`（若走 (b)）、`src/Linux/build/MilBridge/blockvalues-shift.tsv`、
  `src/Linux/build/MilBridge/HANDOFF-NEXT.md`（追加更正行）、`~/w21-verify/**`（外部冻结链）。
- **禁止**：改任何**产品件**（`src/Microsoft.DotNet.Wpf*/**`、`src/WpfGfx.Linux.Native/**` 的源码逻辑）、改落点、
  削弱**其它**判据、把空帧洗绿。**不许**为了绿而删/跳过某档以外的判据。
- 改判据 ⇒ **必须同趟**：`wave-freeze-consistency-check.py` 在 `close-wave.sh` 的 `fp_inputs()` 覆盖面内 ⇒ `inputs_fp` 必移 ⇒ 追加 `HANDOFF-NEXT.md` 的 `cell=#1/#2/#3` 更正行；若动 `verify-all.sh` 步面则四处声明同趟。

## ⑤ 硬停

(a)(b) 各试 2～3 种仍不能让"重建之后四档 PASS" ∧ "`verify-all` 66/0" ∧ "空帧无回归"三者**同时**成立 ⇒ **停手**：
- 保持仓库处于当前可用态（`verify-all` 66/0、能渲染）；
- 输出：每档成对读数、你选 (a) 还是 (b) 及依据、以及**为什么做不到**；
- **不许**留下半改状态（`git status` 必须干净，或把未提交改动逐条列清并说明）。

## ⑥ 报告

- ① 的三条读数（`[5c/6]` 四档原文、`verify-all` 步骤数、`THIRDPARTY` 行）。
- 选 (a) 还是 (b)：改动清单 ＋ **反极性实测**（改坏 `pf` 的 `block9/tier` ⇒ 红的原文）。
- ③4/③5 的读数（外部冻结器只读档在新落点能否取到件）。
- `git log --oneline -3`、`git status --short`、`inputs_fp` 前后值、九位前后值。
- 结论：**达成** 或 **未达 ＋ 具名残余**。
