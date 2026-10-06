#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# verify-all-steps-generated-check.sh —— 「`verify-all.sh` 步表**由 tsv 生成**」的**防手改牙**
#   （`TASK-口径与生成式步表` ②）
#
# 【它挡的是什么】`Guide.Linux/verify-all.sh` 里被哨兵夹住的 `^run_step "` 行**由
#   `src/Linux/build/MilBridge/verify-all-steps.tsv` 经 `tools/gen-verify-all-steps.py --write` 生成**
#   ⇒ 谁**手改**了某一步（改命令／删一步／加一步而没重生成）都必须被抓住。
#
# 【判据（唯一实现在 `tools/gen-verify-all-steps.py --check`；本件是**薄包装**，不另写第二实现）】
#   ① 块内 `^run_step "` 行序列 ⇔ tsv 生成的行序列（多/少/改了哪一步 ⇒ 逐条点名）；
#   ② `# VERIFYALL-STEPS-DECL` 的 `N` ⇔ tsv 行数；
#   ③ `# VERIFYALL-STEP-NAMES` 的名字序列 ⇔ tsv 的 `name` 序列。
#
# 【三态（借用 `gen-verify-all-steps.py` 的 rc）】`0` ⇒ `VSTEPS=PASS`／`1` ⇒ `VSTEPS=FAIL`（逐条点名）／
#   `3` ⇒ `VSTEPS=NOINFO`（哨兵缺失/tsv 畸形等 ⇒ **算不出来 ≠ 绿**）。`NOINFO` 在门禁里同样是 ❌。
#
# 【用法】bash src/Linux/build/MilBridge/tools/verify-all-steps-generated-check.sh [--va PATH] [--tsv PATH]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
ROOT="$(cd "$(dirname "$SELF")/../../../../.." && pwd)"

exec python3 "$ROOT/src/Linux/build/MilBridge/tools/gen-verify-all-steps.py" --check "$@"
