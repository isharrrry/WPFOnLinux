#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# push-marker-write.sh —— 推送标记**写入端**（`B-15` 案乙：标记搬进仓内；`t48`／W4b）
#
# 【为什么】`B-15` 现取：仓内**零读者**看 `.done` 标记（`grep -rIl '\.done' src/Linux/build/MilBridge/tools
#   Guide.Linux/verify-all.sh src/Linux/build/close-wave.sh` ＝ 0），而链侧标记由**仓外**件写（`~/w14a/W80_*.done` 等）。
#   本件＝仓内唯一的**写入端**：把三字段标记写成**固定行序**的纯文本。
#
# 【口径（写死）】标记**恰好三行**：`push_rc=` ／ `stop_line=` ／ `remote=`。
#   · **取不到 ⇒ 写 `none(<reason>)`** —— 该形态**允许、上屏、不判红**（显式声明「取不到」）；
#   · **空值（`key=`）⇒ 一律红**（`MARKER=FAIL reason=empty-field`）；
#   · 写盘走 `temp + 同设备 rename`（原子），**不覆盖**已有文件以外的任何路径面。
# 【自述】**未被 `run_step` 直接调用**（生产端，不是步）：本件＝仓内**写入端**，由判据端
#   `src/Linux/build/MilBridge/tools/push-marker-check.sh`（`Guide.Linux/verify-all.sh` 步名 `PUSH-MARKER`）的**集成腿**驱动；
#   覆盖面已计入（`src/Linux/build/close-wave.sh` 的 `fp_inputs()`，现取件数 233）。
# 用法：bash push-marker-write.sh --out FILE [--push-rc V] [--stop-line V] [--remote V]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail
SELF="${BASH_SOURCE[0]}"; SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
OUT=""; PUSH_RC="none(reason=not-run)"; STOP_LINE="none(reason=not-run)"; REMOTE="none(reason=not-run)"
RC_USAGE=4
usage(){ sed -n '2,17p' "$SELF" | sed 's/^# \{0,1\}//'; }
emit(){ printf 'push_rc=%s\nstop_line=%s\nremote=%s\n' "$1" "$2" "$3"; }
write_marker(){
  local f="$1" a="$2" b="$3" c="$4" v
  [ -n "$a" ] || { echo "MARKER=FAIL reason=empty-field field=push_rc" >&2; return 1; }
  [ -n "$b" ] || { echo "MARKER=FAIL reason=empty-field field=stop_line" >&2; return 1; }
  [ -n "$c" ] || { echo "MARKER=FAIL reason=empty-field field=remote" >&2; return 1; }
  local T; T="$(mktemp "${f}.t48.XXXXXX")"
  emit "$a" "$b" "$c" > "$T"
  local n; n="$(wc -l < "$T")"
  if [ "$n" != 3 ]; then echo "MARKER=FAIL reason=lines!=3 got=$n" >&2; rm -f "$T"; return 1; fi
  v="$(sed -n 's/^push_rc=//p' "$T")"; [ -n "$v" ] || { echo "MARKER=FAIL reason=empty-field field=push_rc" >&2; rm -f "$T"; return 1; }
  v="$(sed -n 's/^stop_line=//p' "$T")"; [ -n "$v" ] || { echo "MARKER=FAIL reason=empty-field field=stop_line" >&2; rm -f "$T"; return 1; }
  v="$(sed -n 's/^remote=//p' "$T")"; [ -n "$v" ] || { echo "MARKER=FAIL reason=empty-field field=remote" >&2; rm -f "$T"; return 1; }
  mv -f -- "$T" "$f"
  echo "MARKER=PASS file=$f fields=3 push_rc=$a stop_line=$b remote=$c"
}
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="${2:-}"; shift 2 ;;
    --push-rc) PUSH_RC="${2:-}"; shift 2 ;;
    --stop-line) STOP_LINE="${2:-}"; shift 2 ;;
    --remote) REMOTE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "MARKER=FAIL reason=usage:unknown-arg $1" >&2; exit $RC_USAGE ;;
  esac
done
[ -n "$OUT" ] || { usage; exit $RC_USAGE; }
write_marker "$OUT" "$PUSH_RC" "$STOP_LINE" "$REMOTE"; exit $?
