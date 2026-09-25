#!/usr/bin/env bash
# W156A w67guard 槽内脚本：多臂 × 多点点击，逐腿落机读行。
#   用法: session_inner.sh <tag> <arm:clicks> [<arm:clicks> ...]
#         臂 ∈ {A, B, C}：A=正常树（现权威五件）｜B=修前成对件（必红 rc=134）｜C=只撤画占位（必红 洋红 0）
#   ⚠️ 必须在 heavy-slot.sh 之内跑。
set -uo pipefail
# ⚠️【落仓参数化（纪律 34）】原值 `W=` **某外来车道工作目录的硬编码路径**（字面不复写，
#   否则纪律 34 的 `grep -E '$HOME/w1[0-9]+a'` 会把**注释本身**算成残留 —— 本器实测踩过）。
#   现在：`W67_WORK` 可覆盖；默认落在**仓外私有暂存**（`$HOME/w67-work`）——
#   **绝不**默认写进 `$R`（证据目录只放 `leg_*.env`／`device.txt` 这类小件）。
#   ⚠️ `BIN` **不能**指向 `$W/bin`（那是外来车道的布局）：它要用 `navclick.py`／`shotstat.py`，
#     而这两件**随装置一起落仓**在**装置自己的目录**里 ⇒ `BIN` = 本脚本所在目录（自足，无外来依赖）。
W="${W67_WORK:-$HOME/w67-work}"; DLLS="$W/dlls"; APPDIR="$W/app"
SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN="${W67_BIN:-$SELF_DIR}"
TAG="${1:?tag}"; shift
[ $# -gt 0 ] || { echo "need >=1 group" >&2; exit 2; }
D="${W67_DISPLAY:-:237}"
export PATH="$HOME/.dotnet:$PATH"; export DOTNET_gcServer=0
OUT="$W/logs/$TAG"; SHOTS="$OUT/shots"; mkdir -p "$OUT" "$SHOTS"

expect_of() { case "$1" in
  0) echo BrushDemo;; 9) echo NativeTextBoxDemo;; 10) echo NativeComboBoxDemo;;
  16) echo NativeTabControlDemo;; 23) echo RichTextBoxDemo;; 24) echo FlowDocumentDemo;;
  *) echo '';; esac; }

five() { for f in libwpfwin32.so wpfgfx_cor3.so PresentationCore.dll PresentationFramework.dll WindowsBase.dll; do
          printf '%s=%s\n' "$f" "$(sha256sum "$APPDIR/$f" | cut -c1-16)"; done; }

cnt() { # cnt <正则> <文件> —— 返回**单个 token** 的命中条数（杜绝 `grep -c || echo 0` 在零命中时输出两行）
  local n; n="$(grep -c -E "$1" "$2" 2>/dev/null || true)"
  n="${n//[$'\n\r']/}"; printf '%s' "${n:-0}"; }
firstline() { local f="$1" pat="$2" out rc
  out="$(grep -n -m1 -E "$pat" "$f" 2>/dev/null)"; rc=$?
  case "$rc" in 0) printf '%s' "${out%%:*}";; 1) printf '%s' '-';;
    *) printf 'READER-ERR(rc=%s)' "$rc";; esac; }
firstline_re() { local f="$1" pat="$2" out rc
  out="$(grep -m1 -E "$pat" "$f" 2>/dev/null)"; rc=$?
  [ "$rc" -le 1 ] || { printf 'READER-ERR(rc=%s)' "$rc"; return; }
  printf '%s' "${out:0:220}"; }
# 承重：托管侧具名行里的 err= 必须非零（防 FAKEOK 伪造 err=0）
unavail_err() { grep -o -m1 'PTS-UNAVAILABLE.*err=[-0-9]*' "$1" 2>/dev/null | grep -o 'err=[-0-9]*' | head -1; }

gi=0
for GROUP in "$@"; do
  gi=$((gi+1))
  ARM="${GROUP%%:*}"; KS="${GROUP#*:}"
  SHIM="$DLLS/$ARM.libwpfwin32.so"; PF="$DLLS/$ARM.PresentationFramework.dll"
  [ -f "$SHIM" ] || { echo "G$gi MISSING-SHIM $SHIM"; continue; }
  [ -f "$PF" ]   || { echo "G$gi MISSING-PF $PF"; continue; }
  cp -a "$SHIM" "$APPDIR/libwpfwin32.so"; cp -a "$PF" "$APPDIR/PresentationFramework.dll"
  GLOG="$OUT/app_g$gi.log"; GSHOTS="$SHOTS/g$gi"; mkdir -p "$GSHOTS"
  echo "=============== GROUP $gi arm=$ARM clicks=[$KS] $(date '+%T') ==============="
  echo "shim_sha16=$(sha256sum "$SHIM" | cut -c1-16) pf_sha16=$(sha256sum "$PF" | cut -c1-16)"
  five > "$OUT/five_pre_g$gi.txt"; echo "five_pre: $(tr '\n' ' ' < "$OUT/five_pre_g$gi.txt")"
  echo "mem_avail_kB_start=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)"
  cd "$APPDIR" || exit 2
  ( exec timeout "${W67_TMO:-200}" env DISPLAY="$D" HC_NO_SPLASH=1 HC_INPUT_DIAG=1 HC_GEO_EVERY=1 \
      HC_DUMP_MAX=100000 dotnet HandyControlDemo.dll ) > "$GLOG" 2>&1 &
  APP=$!
  echo "app_pid=$APP timeout=${W67_TMO:-200}s"
  sleep 8
  echo "boot_log_bytes=$(stat -c%s "$GLOG" 2>/dev/null || echo 0)"
  import -display "$D" -window root "$GSHOTS/boot.png" 2>/dev/null
  cp -f "$GSHOTS/boot.png" "$GSHOTS/last.png"
  python3 "$BIN/shotstat.py" "$GSHOTS/boot.png" | sed 's/^/  boot  /'
  echo "boot_alive=$(kill -0 "$APP" 2>/dev/null && echo yes || echo no)"
  for k in $(echo "$KS" | tr ',' ' '); do
    echo "--- G$gi click $k  $(date '+%T') ---"
    EXP="$(expect_of "$k")"
    timeout 200 python3 "$BIN/navclick.py" --log "$GLOG" --pid "$APP" --display "$D" \
        --out "$GSHOTS" --item "$k" --expect "$EXP" || echo "  navclick_rc=$?"
    alive=$(kill -0 "$APP" 2>/dev/null && echo yes || echo no)
    import -display "$D" -window root "$GSHOTS/k$k.png" 2>/dev/null
    python3 "$BIN/shotstat.py" "$GSHOTS/k$k.png" | sed "s/^/  /"
    AE=$(python3 - "$GSHOTS/last.png" "$GSHOTS/k$k.png" <<'PY'
import subprocess, sys
r = subprocess.run(['compare','-metric','AE',sys.argv[1],sys.argv[2],'null:'],capture_output=True,text=True)
o = ((r.stderr or '') + (r.stdout or '')).strip().split()
print(o[0] if o else 'NA')
PY
)
    cp -f "$GSHOTS/k$k.png" "$GSHOTS/last.png"
    printf 'CLICK k=%s alive=%s expect=%s AE=%s pts_unavail=%s pts_gap=%s guard=%s fatal=%s unh=%s ns_last=%s\n' \
      "$k" "$alive" "$EXP" "$AE" \
      "$(cnt "PTS-UNAVAILABLE" "$GLOG")" \
      "$(cnt "PTS_GAP" "$GLOG")" \
      "$(cnt "\[HC-UNHANDLED\]" "$GLOG")" \
      "$(cnt "Unrecoverable system error" "$GLOG")" \
      "$(cnt "Unhandled exception" "$GLOG")" \
      "$(grep -o '\[NS\] loaded [^ ]*' "$GLOG" 2>/dev/null | tail -1 | awk '{print $3}')"
    n1="$(firstline "$GLOG" "EntryPointNotFoundException: Unable to find an entry point named 'CreateInstalledObjectsInfo'")"
    n2="$(firstline "$GLOG" "PTS_GAP entry=")"
    n3="$(firstline "$GLOG" "\[PTS-UNAVAILABLE\] site=")"
    n4="$(firstline "$GLOG" "Unrecoverable system error")"
    printf 'PHASE k=%s c1_ep=%s c2_pts_gap=%s c3_pts_unavail=%s c4_unrecoverable=%s managed_err=%s native_err=%s\n' \
      "$k" "$n1" "$n2" "$n3" "$n4" \
      "$(grep -o -m1 'PTS-UNAVAILABLE.*err=[-0-9]*' "$GLOG" 2>/dev/null | grep -o 'err=[-0-9]*' | head -1)" \
      "$(grep -o -m1 'PTS_GAP entry=[^ ]* .*err=[-0-9]*' "$GLOG" 2>/dev/null | grep -o 'err=[-0-9]*' | head -1)"
    echo "  c3_text: $(firstline_re "$GLOG" "\[PTS-UNAVAILABLE\] site=")"
    [ "$alive" = no ] && break
    sleep 0.4
  done
  alive=$(kill -0 "$APP" 2>/dev/null && echo yes || echo no)
  echo "alive_after_seq=$alive"
  if [ "$alive" = yes ]; then sleep 1; kill "$APP" 2>/dev/null; fi
  wait "$APP"; rc=$?
  echo "APP_RC=$rc"; echo "$rc" > "$OUT/rc_g$gi.txt"
  echo "rc_reading: $(case $rc in 124) echo 'TIMEOUT(仪器收的)';;
    137) echo 'OOM';;
    139) echo 'SILENT-SIGSEGV';;
    134) echo 'ABORT(D-G70 族)';;
    143) echo 'SIGTERM(仪器收的)';;
    0) echo 'NORMAL-EXIT';; *) echo 'OTHER';; esac)"
  echo "log_bytes=$(stat -c%s "$GLOG")"
  five > "$OUT/five_post_g$gi.txt"
  if cmp -s "$OUT/five_pre_g$gi.txt" "$OUT/five_post_g$gi.txt"; then echo "FIVE_STABLE_G$gi=YES"; else
    echo "FIVE_STABLE_G$gi=NO ⇒ 本组读数作废"; diff "$OUT/five_pre_g$gi.txt" "$OUT/five_post_g$gi.txt"; fi
  sleep 2
done
echo "ALL_GROUPS_DONE $(date '+%T')"
exit 0
