#!/usr/bin/env bash
# no-internal-symlink-check.sh —— 断言「落点下无指向仓内的软链接」（结构上游化·合并波）
# 判据：遍历仓内全部软链接（排除 .git）；凡目标解析后落在本仓内 ⇒ FAIL 并逐条点名。
# rc：0=PASS ｜ 1=FAIL ｜ 2=NOINFO（根不存在/算不出）
set -uo pipefail
SELF="${BASH_SOURCE[0]}"; SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="${NIS_ROOT:-$(cd -- "$SELF_DIR/../../../../.." && pwd)}"
[ -d "$ROOT" ] || { echo "NO_INTERNAL_SYMLINK=NOINFO reason=root-absent root=$ROOT"; exit 2; }
cd "$ROOT" || { echo "NO_INTERNAL_SYMLINK=NOINFO reason=cd-failed"; exit 2; }
hits=0; scanned=0
while IFS= read -r -d '' l; do
  scanned=$((scanned + 1))
  tgt="$(readlink -- "$l" 2>/dev/null)" || continue
  case "$tgt" in
    /*) abs="$tgt" ;;
    *)  abs="$(cd -- "$(dirname -- "$l")" 2>/dev/null && pwd)/$tgt" ;;
  esac
  abs="$(realpath -m -- "$abs" 2>/dev/null || printf '%s' "$abs")"
  case "$abs" in
    "$ROOT"|"$ROOT"/*) echo "NIS_HIT link=${l#./} -> $tgt"; hits=$((hits + 1)) ;;
  esac
done < <(find . -path ./.git -prune -o -type l -print0 2>/dev/null)
echo "NO_INTERNAL_SYMLINK=$([ "$hits" -eq 0 ] && echo PASS || echo FAIL) internal_links=$hits scanned=$scanned root=$ROOT"
[ "$hits" -eq 0 ]
