#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# wave-push.sh —— **仓内哨兵写入端**（`t24`／W3b 搬仓件；**只搬「哨兵写入那一小段」**）
#
# 【为什么存在（`B-14`）】哨兵原先只由**仓外**仪器 `~/w79c/bin/w79-push.sh`（**`5015004b0f0d917e`**）
#   尾部 `install -m 644` 两行写出 ⇒ **仓内既无写者也无读者**（`grep -rln 'BASELINE_SHA16' --include='*.sh' --include='*.py' .` 现取 **0 命中**）；
#   清一次车道目录 ⇒ 哨兵成孤儿。本件把**写入那一小段**搬进仓（**不含任何推送逻辑** —— 那部分不搬）。
#
# 【规范】严格按 `build/MilBridge/HANDOFF-NEXT.md` 纪律区「dated 哨兵规范入册 · 键序／字节格式」7 条：
#   **13 行／固定键序**（SHA FP PC PF WB WIN32SHIM HBTL WIC PROVIDER DWF WAVE BASELINE BASELINE_SHA16）、
#   行尾单个 `\n`、无空行、无 CR；**任何取值失败 ⇒ 写 `none(<reason>)` 并以非零退出（响亮失败）**。
#   键值口径：九键走 `wave-freeze-consistency-check.py` 的 `NINE_PATHS`（**`CFG=Release`**；`provider` 走**工程产出目录**、**禁副本**）；
#             `FP` 走 `bash build/bridge-src-fp.sh`（**不是** `inputs_fp`）；`WAVE`／`BASELINE`／`BASELINE_SHA16` 由 `docs/CURRENT-STATE.md:9` 派生。
#
# 【用法】`bash wave-push.sh --dry-run`（只打印 13 行到 stdout、**不写盘**）｜`bash wave-push.sh`（写两枚哨兵 ＋ 自证 `cmp`）
# 【不接线】本件**未被 `close-wave.sh`／`verify-all.sh` 调用**（接线归 W4）。
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
R="$(cd -- "$SELF_DIR/../../.." && pwd)"
CFG="${WPW_CFG:-Release}"
CS="${WPW_CS:-$R/docs/CURRENT-STATE.md}"
S_A="${WPW_S1:-/tmp/bridge-frozen.flag}"
S_B="${WPW_S2:-$HOME/wfp-runs/bridge-frozen.flag}"
MODE="${1:---write}"
rc=0

apath() { case "$1" in
  SHA) echo "$R/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so";;
  PC) echo "$R/build/PresentationCore.Linux/bin/$CFG/PresentationCore.dll";;
  PF) echo "$R/build/PresentationFramework.Linux/bin/$CFG/PresentationFramework.dll";;
  WB) echo "$R/build/WindowsBase.Linux/bin/$CFG/WindowsBase.dll";;
  PROVIDER) echo "$R/build/DirectWrite.Linux/Provider/bin/$CFG/DirectWrite.Linux.Provider.dll";;
  WIN32SHIM) echo "$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so";;
  WIC) echo "$R/build/DirectWrite.Linux/wic-shim/libwpfwic.so";;
  HBTL) echo "$R/build/shims/PresentationCore.HbTextLine.cs";;
  DWF) echo "$R/build/DirectWriteForwarder.Linux/bin/$CFG/DirectWriteForwarder.dll";;
  *) return 1;; esac; }

sha16_or_none() {  # $1=key  ⇒ 值（取不到 ⇒ none(<reason>) 且 rc=1）
  local k="$1" p v
  p="$(apath "$k")" || { rc=1; printf 'none(no-such-key)'; return; }
  if [ ! -f "$p" ]; then rc=1; printf 'none(authority-absent:%s)' "$(basename "$p")"; return; fi
  v="$(sha256sum "$p" | cut -c1-16)"; printf '%s' "$v"; }

FP_VAL="$(bash "$R/build/bridge-src-fp.sh" 2>/dev/null | sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p')"
[ -n "$FP_VAL" ] || { FP_VAL='none(bridge-src-fp-failed)'; rc=1; }
CSLN="$(grep -m1 'BASELINE-FROZEN' "$CS" 2>/dev/null)"
GEN="$(printf '%s\n' "$CSLN" | sed -n 's/.*gen=#\([0-9][0-9]*\).*/\1/p')"
CSSHA="$(printf '%s\n' "$CSLN" | sed -n 's/.*sha16=\([0-9a-f]*\).*/\1/p')"
if [ -z "$GEN" ] || [ -z "$CSSHA" ]; then GEN='none(cs-line-absent)'; CSSHA='none(cs-line-absent)'; rc=1; fi

emit() {
  printf 'SHA=%s\n'          "$(sha16_or_none SHA)"
  printf 'FP=%s\n'           "$FP_VAL"
  printf 'PC=%s\n'           "$(sha16_or_none PC)"
  printf 'PF=%s\n'           "$(sha16_or_none PF)"
  printf 'WB=%s\n'           "$(sha16_or_none WB)"
  printf 'WIN32SHIM=%s\n'    "$(sha16_or_none WIN32SHIM)"
  printf 'HBTL=%s\n'         "$(sha16_or_none HBTL)"
  printf 'WIC=%s\n'          "$(sha16_or_none WIC)"
  printf 'PROVIDER=%s\n'     "$(sha16_or_none PROVIDER)"
  printf 'DWF=%s\n'          "$(sha16_or_none DWF)"
  printf 'WAVE=%s\n'         "$( [ "$GEN" = 'none(cs-line-absent)' ] && echo 'none(cs-line-absent)' || echo "w${GEN}-freeze" )"
  printf 'BASELINE=%s\n'     "$( [ "$GEN" = 'none(cs-line-absent)' ] && echo 'none(cs-line-absent)' || echo "#${GEN}" )"
  printf 'BASELINE_SHA16=%s\n' "$CSSHA"
}

case "$MODE" in
  --dry-run)
    emit
    [ "$rc" -eq 0 ] || { echo "WPW=FAIL reason=value-unavailable（见 none(...)）" >&2; exit 1; }
    echo "WPW=DRYRUN lines=13 keys=13" >&2 ;;
  --write|'')
    T="$(mktemp)"; trap 'rm -f "${T:-}"' EXIT
    emit > "$T"
    if [ "$(wc -l < "$T")" -ne 13 ]; then echo "WPW=FAIL reason=lines!=13 got=$(wc -l < "$T")" >&2; exit 1; fi
    if grep -q 'none(' "$T"; then echo "WPW=FAIL reason=value-unavailable（哨兵**不许**落 none(...)）" >&2; exit 1; fi
    install -m 644 "$T" "$S_A"
    mkdir -p "$(dirname "$S_B")"; install -m 644 "$T" "$S_B"
    if cmp -s "$S_A" "$S_B"; then echo "WPW=PASS sentinels=2 cmp=IDENTICAL lines=13 keys=13 a=$S_A b=$S_B"; exit 0
    else echo "WPW=FAIL reason=sentinels-differ a=$S_A b=$S_B" >&2; exit 1; fi ;;
  *) echo "用法: $0 [--dry-run|--write]" >&2; exit 2 ;;
esac
