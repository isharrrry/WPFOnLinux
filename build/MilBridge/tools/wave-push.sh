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
# ⏪ **dated 修（`t35`，读时 2026-09-28T16:42:53.604+0800；`t30` §V-2）**：**只对两条规范路径**（`/tmp/bridge-frozen.flag`／`$HOME/wfp-runs/bridge-frozen.flag`）**自动建父目录**；
#   **其它任何路径**必须显式 `WPW_MKDIR_OK=1`，否则 `WPW=FAIL reason=strange-target-path … hint=set WPW_MKDIR_OK=1`（**拒跑并点名**）——
#   陌生路径下静默建树会把哨兵写进**没人读的地方**而生产仍旧 ⇒ **假绿方向**（`D-G181`／`D-G182` 同族）。

# 【不接线】本件**未被 `close-wave.sh`／`verify-all.sh` 调用**（接线归 W4）。
# ⏪ **dated 更正（`t48`／W4b，读时 2026-09-28T17:47:04.418+0800）**：**已接线**：`verify-all.sh` 步名 `WAVE-PUSH`（`run_step "WAVE-PUSH" bash build/MilBridge/tools/wave-push.sh --dry-run`）＋ **覆盖面已计入**（`build/close-wave.sh` 的 `fp_inputs()`；现取件数 **233**）⇒ 上一行的「【不接线】」**自此过期**（**原句一字未删**，以本行为准）。
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
    echo "WPW=DRYRUN lines=13 keys=13" ;;   # ⏪ `t54`：设计上屏行由 stderr 改 stdout（该件真跑 stderr 须归零；无仓内消费者）
  --write|'')
    T="$(mktemp)"; trap 'rm -f "${T:-}" "${T:-}".bakA "${T:-}".bakB "${T:-}".errA "${T:-}".errB "${T:-}".derr' EXIT
    emit > "$T"
    if [ "$(wc -l < "$T")" -ne 13 ]; then echo "WPW=FAIL reason=lines!=13 got=$(wc -l < "$T")" >&2; exit 1; fi
    if grep -q 'none(' "$T"; then echo "WPW=FAIL reason=value-unavailable（哨兵**不许**落 none(...)）" >&2; exit 1; fi
    # ⏪ dated 加固（`t29`，读时 2026-09-28T16:28:37.377+0800；`t22` §V2）：① **写前目录闸**（两枚父目录缺 ⇒ 先建；建不动／不可写／
    #   目标不是普通件 ⇒ **明确拒跑并点名**，**禁止隐式部分写**）；② 任一 `install` 失败 ⇒ **判词第一行点名真因**
    #   （哪一枚／哪一步／哪条命令／`stderr` 首行）＋ **回滚**，保证两枚都不留半成品。
    #   测试钩子（只在显式设置时生效）：`WPW_TEST_FORCE_FAIL=write-B` ⇒ 在第 `2` 枚上强制失败，用于证明**回滚真跑**。
    DA="$(dirname -- "$S_A")"; DB="$(dirname -- "$S_B")"
    # ⏪ dated 修（`t35`，读时 2026-09-28T16:42:53.604+0800；`t30` §V-2 队长裁定）：**只对两条规范路径**自动建父目录；
    #   **其它任何路径**必须**显式** `WPW_MKDIR_OK=1` 才允许建 —— 否则 **拒跑并点名**
    #   （`WPW_S1` 打错一处会静默建出陌生目录树、把哨兵写进没人读的地方，而生产仍旧 ⇒ **假绿方向**）。
    mkdir_ok=0; [ "${WPW_MKDIR_OK:-}" = "1" ] && mkdir_ok=1
    ensure_dir() {   # $1=哨兵名(A|B) $2=哨兵路径 $3=父目录 $4=是否规范路径(1/0)
      [ -d "$3" ] && return 0
      if [ "$4" = 1 ] || [ "$mkdir_ok" = 1 ]; then
        if ! mkdir -p "$3" 2>"$T".derr; then
          echo "WPW=FAIL reason=target-dir-unusable step=preflight dir=$3 cmd=\"mkdir -p $3\" stderr=$(head -n 1 "$T".derr)"; exit 1
        fi
        [ "$4" = 0 ] && echo "WPW_MKDIR_OK sentinel=$1 path=$2 dir=$3（**陌生路径显式放行**：WPW_MKDIR_OK=1 ⇒ 上屏，不静默）"
      else
        echo "WPW=FAIL reason=strange-target-path sentinel=$1 path=$2 dir=$3 hint=set WPW_MKDIR_OK=1（**陌生路径不许静默建树**：哨兵会写进没人读的地方 ⇒ 假绿方向）"; exit 1
      fi
      return 0
    }
    canon_a=0; [ "$S_A" = "/tmp/bridge-frozen.flag" ] && canon_a=1
    canon_b=0; [ "$S_B" = "$HOME/wfp-runs/bridge-frozen.flag" ] && canon_b=1
    ensure_dir A "$S_A" "$DA" "$canon_a"
    ensure_dir B "$S_B" "$DB" "$canon_b"
    for d in "$DA" "$DB"; do
      if [ ! -w "$d" ]; then
        echo "WPW=FAIL reason=target-dir-unwritable step=preflight dir=$d cmd=\"test -w $d\""; exit 1
      fi
    done
    for p in "$S_A" "$S_B"; do
      if [ -e "$p" ] && [ ! -f "$p" ]; then
        echo "WPW=FAIL reason=target-not-a-regular-file step=preflight path=$p（"install" 对目录会静默拷进去 ⇒ 必须先拒）"; exit 1
      fi
    done
    [ -f "$S_A" ] && cp -p "$S_A" "$T".bakA
    [ -f "$S_B" ] && cp -p "$S_B" "$T".bakB
    pre_A="$([ -f "$S_A" ] && sha256sum "$S_A" | cut -c1-16 || echo absent)"
    pre_B="$([ -f "$S_B" ] && sha256sum "$S_B" | cut -c1-16 || echo absent)"
    now_of() { [ -f "$1" ] && sha256sum "$1" | cut -c1-16 || echo absent; }
    rollback() {
      [ -f "$T".bakA ] && install -m 644 "$T".bakA "$S_A"
      [ -f "$T".bakB ] && install -m 644 "$T".bakB "$S_B"
      echo "WPW_ROLLBACK why=$1 A=$S_A pre=$pre_A now=$(now_of "$S_A") | B=$S_B pre=$pre_B now=$(now_of "$S_B")"
    }
    if ! install -m 644 "$T" "$S_A" 2>"$T".errA; then
      echo "WPW=FAIL reason=install-failed step=write-A sentinel=A path=$S_A cmd=\"install -m 644 <tmp> $S_A\" stderr=$(head -n 1 "$T".errA)"
      rollback write-A; echo "WPW=FAIL partial=none（A 未写入、B 尚未动）"; exit 1
    fi
    if [ "${WPW_TEST_FORCE_FAIL:-}" = "write-B" ] || ! install -m 644 "$T" "$S_B" 2>"$T".errB; then
      echo "WPW=FAIL reason=install-failed step=write-B sentinel=B path=$S_B cmd=\"install -m 644 <tmp> $S_B\" stderr=$(head -n 1 "${T}".errB 2>/dev/null || echo forced-by-test-hook)"
      rollback write-B; echo "WPW=FAIL partial=none（A 已回滚到 pre）"; exit 1
    fi
    if cmp -s "$S_A" "$S_B"; then echo "WPW=PASS sentinels=2 cmp=IDENTICAL lines=13 keys=13 a=$S_A b=$S_B sha16=$(sha256sum "$S_A" | cut -c1-16)"; exit 0
    else
      echo "WPW=FAIL reason=sentinels-differ a=$S_A b=$S_B sha16_a=$(now_of "$S_A") sha16_b=$(now_of "$S_B")（**两枚都写成功**才可能走到这里 ⇒ 不是部分写）"
      exit 1; fi ;;
  *) echo "用法: $0 [--dry-run|--write]" >&2; exit 2 ;;
esac
