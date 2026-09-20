#!/usr/bin/env bash
# 用途：**波内检查 `ARTIFACT-SRC-FP` 的两极化**（`#15` RUNBOOK §2.1 的机械化版本）。
#
# 背景（为什么需要它）：
#   `build/artifact-src-fp.py` 现在会在 PC 的 FP 文件里写**逐文件行** `file=<sha16>  <相对路径>`。
#   本波（`#15`）改了 `build/shims/PresentationCore.HbTextLine.cs` ⇒ 那条 `file=` 行**必须变**（正极性），
#   而**其余 `file=` 行必须逐位不变**（负极性）；`fp=`/`n=`/`peer_fp=`/`peer_n=`/`peer=` 允许变
#   （peer 段按构造收录"本仓内被引产物"，环成员 PF/Reach 每波必变）。
#
# 用法：
#   bash build/check-fp-polarity.sh                      # 只报"FP 文件里的 shim 行 vs 现树 shim"是否一致
#   bash build/check-fp-polarity.sh <波前FP存档>          # 额外做"除 shim 行外 file= 行逐位不变"的负极性断言
#
# 退出码：0=PASS ｜ 1=FAIL（正/负极性不成立）｜ 2=NOINFO（读不到件 ⇒ **不许当绿**）
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FP_FILE="build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt"
SHIM="build/shims/PresentationCore.HbTextLine.cs"
PREV="${1:-}"

say() { printf '%s\n' "$*"; }
hi16() { sha256sum "$1" | cut -c1-16; }

# ── 读件（缺件一律 NOINFO）─────────────────────────────────────────────
[ -f "$FP_FILE" ] || { say "FP_POLARITY=NOINFO reason=缺 FP 文件（$FP_FILE）"; exit 2; }
[ -f "$SHIM" ]    || { say "FP_POLARITY=NOINFO reason=缺 shim（$SHIM）"; exit 2; }

SHIM16="$(hi16 "$SHIM")"
FP_ROW="$(grep -a -m1 -E "^file=[0-9a-f]{16}  build/shims/PresentationCore\.HbTextLine\.cs$" "$FP_FILE" || true)"
FP_SHIM16="$(printf '%s' "$FP_ROW" | sed -n 's/^file=\([0-9a-f]\{16\}\).*/\1/p')"
FP_SUM="$(grep -a -m1 -E '^fp=' "$FP_FILE" | cut -d= -f2)"
FP_PEER="$(grep -a -m1 -E '^peer_fp=' "$FP_FILE" | cut -d= -f2)"

say "FP_FILE=$FP_FILE  bytes=$(stat -c%s "$FP_FILE")  mtime=$(stat -c%y "$FP_FILE" | cut -c1-19)"
say "shim16(现树)=$SHIM16   shim16(FP 文件里的 file= 行)=${FP_SHIM16:-<无该行>}   fp=$FP_SUM peer_fp=$FP_PEER"

if [ -z "$FP_SHIM16" ]; then
    say "FP_POLARITY=NOINFO reason=FP 文件里没有 'file=…  build/shims/PresentationCore.HbTextLine.cs' 行（旧格式或未 --write）⇒ 不许当绿"
    exit 2
fi

rc=0
if [ "$FP_SHIM16" = "$SHIM16" ]; then
    say "  ✅ 正极性：FP 文件里的 shim 行 == 现树 shim（$SHIM16）"
else
    say "  ⚠️ FP 文件的 shim 行与现树不一致：文件=$FP_SHIM16 / 现树=$SHIM16"
    say '     ⇒ 若这是**波前**读到的，属「FP 文件陈旧」（波里 --write 后会一致）；**波后仍不一致 = 正极性不成立**'
    REASON="fp-file-stale"
    rc=1
fi

# ── 负极性（给了波前存档才做）──────────────────────────────────────────
if [ -n "$PREV" ]; then
    [ -f "$PREV" ] || { say "FP_POLARITY=NOINFO reason=缺波前存档（$PREV）"; exit 2; }
    changed="$(diff <(grep -a '^file=' "$PREV" | sort) <(grep -a '^file=' "$FP_FILE" | sort) || true)"
    other="$(printf '%s\n' "$changed" | grep -E '^[<>] file=' | grep -v 'build/shims/PresentationCore\.HbTextLine\.cs$' || true)"
    if [ -z "$other" ]; then
        say "  ✅ 负极性：除 shim 那一行外，其余 file= 行逐位不变"
    else
        say "  ❌ 负极性不成立：除 shim 行外还有 file= 行变了 ——"
        printf '%s\n' "$other" | sed 's/^/     /' | head -20
        rc=1
    fi
fi

if [ "$rc" -eq 0 ]; then say "FP_POLARITY=PASS"; else say "FP_POLARITY=FAIL"; fi
exit "$rc"
