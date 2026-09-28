#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# push-marker-check.sh —— 推送标记**判据端**（`B-15` 的牙；`t48`／W4b）
#
# 【判据（三档，逐档可判真假；`none(<reason>)` 与空值**必须分开**）】
#   · `key=<非空>`（含 `none(<reason>)`）⇒ **放行**（`none(...)` 是**显式**「取不到」声明，上屏不判红）
#   · `key=`（值为空）⇒ **红** `rule=empty-value field=…`
#   · **整行缺失** ⇒ **红** `rule=missing-field field=…`
#     （口径选择：缺行**与空值同类**——两者都让「标记携带判词」这件事不成立；`none(...)` 才是合法逃生口。
#      ⚠️ 该选择是**收紧**，不是放宽：仓外历史标记现取**缺行 6 处** ⇒ 真腿在门禁内**不跑**，见下。）
# 【三态】rc=0 `PUSHMARKER=PASS …`｜rc=1 `PUSHMARKER=FAIL`（逐枚/逐字段点名）｜rc=3 `=NOINFO`（无标记可检）
# 【射程边界（如实写）】
#   ① **默认 = 集成腿**：在 `mktemp -d` 里跑**写入端**产一枚标记并逐字段核（真跑写入端），再跑**两条反极腿**
#      （空值夹具 ⇒ 必红；缺行夹具 ⇒ 必红）⇒ 每次运行都真判真假，**不依赖仓外状态**。
#   ② `--dir DIR` ＝ 扫**真实标记**（`*.done`）：逐枚按三档判；`--dir` 给了而目录里没有标记 ⇒ `NOINFO`
#      （**不许**把「没有标记」读成「没有违规」）。
#   ③ 仓外 `~/w14a`／`~/w21-verify` 的历史标记**不入门禁**（非本波写域、且现取本就缺行）⇒ 真腿**另排**，
#      本波只给现取读数（报告里记 `NOINFO(reason=仓外历史标记、非本波写域)`）。
# 【自述】已接线：`verify-all.sh` 步名 `PUSH-MARKER`；覆盖面已计入（`build/close-wave.sh` 的 `fp_inputs()`）。
# 【测试钩子】`--selftest`：四例（写入端真跑正极／写入端空值反极／空值夹具反极／缺行夹具反极）。
# 用法：bash push-marker-check.sh [--dir DIR]... [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail
SELF="${BASH_SOURCE[0]}"; SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="${PMC_ROOT:-$(cd -- "$SELF_DIR/../../.." && pwd)}"
WRITER="$ROOT/build/MilBridge/tools/push-marker-write.sh"
FIELDS=(push_rc stop_line remote)
RC_PASS=0; RC_FAIL=1; RC_NOINFO=3; RC_USAGE=4
usage(){ sed -n '2,22p' "$SELF" | sed 's/^# \{0,1\}//'; }

judge_marker(){  # $1=件 ⇒ 印逐字段行；rc 0/1
  local f="$1" k v bad=0
  [ -r "$f" ] || { echo "PUSHMARKER_HIT file=$f rule=unreadable"; return 1; }
  for k in "${FIELDS[@]}"; do
    if ! grep -q "^$k=" "$f"; then
      echo "PUSHMARKER_HIT file=$f field=$k rule=missing-field"; bad=1; continue
    fi
    v="$(sed -n "s/^$k=//p" "$f" | head -1)"
    if [ -z "$v" ]; then echo "PUSHMARKER_HIT file=$f field=$k rule=empty-value"; bad=1
    else echo "PUSHMARKER_FIELD file=$f field=$k value=$v"; fi
  done
  return $bad
}
integration(){
  local T="$1" ok=0 antipole1=0 antipole2=0 out rc1 rc2 named1 named2
  out="$(bash "$WRITER" --out "$T/m.done" 2>&1)" || { echo "PUSHMARKER_HIT rule=writer-failed out=$out"; return 1; }
  case "$out" in *MARKER=PASS*fields=3*) ok=1 ;; esac
  judge_marker "$T/m.done" >/dev/null || return 1
  # 反极①：空值夹具 ⇒ 必红且点名 field=push_rc
  printf 'push_rc=\nstop_line=none(reason=x)\nremote=none(reason=x)\n' > "$T/empty.done"
  out="$(judge_marker "$T/empty.done" 2>&1)"; rc1=$?
  case "$out" in *field=push_rc*rule=empty-value*) named1=1 ;; *) named1=0 ;; esac
  [ "$rc1" -ne 0 ] && [ "$named1" = 1 ] && antipole1=1
  # 反极②：缺行夹具 ⇒ 必红且点名 field=stop_line
  printf 'push_rc=none(reason=x)\nremote=none(reason=x)\n' > "$T/missing.done"
  out="$(judge_marker "$T/missing.done" 2>&1)"; rc2=$?
  case "$out" in *field=stop_line*rule=missing-field*) named2=1 ;; *) named2=0 ;; esac
  [ "$rc2" -ne 0 ] && [ "$named2" = 1 ] && antipole2=1
  echo "PUSHMARKER_ANTIPOLE empty-value=$([ "$antipole1" = 1 ] && echo red-named || echo NOT-red) missing-field=$([ "$antipole2" = 1 ] && echo red-named || echo NOT-red)"
  [ "$ok" = 1 ] && [ "$antipole1" = 1 ] && [ "$antipole2" = 1 ] || return 1
  return 0
}
scan_dir(){
  local d="$1" f n=0 bad=0
  [ -d "$d" ] || { echo "PUSHMARKER_HIT dir=$d rule=dir-absent"; return 1; }
  for f in "$d"/*.done; do [ -f "$f" ] || continue; n=$((n+1)); judge_marker "$f" >/dev/null 2>&1 || { bad=$((bad+1)); judge_marker "$f" 2>&1 | grep HIT; }; done
  if [ "$n" = 0 ]; then echo "PUSHMARKER=NOINFO reason=no-markers dir=$d"; return $RC_NOINFO; fi
  echo "PUSHMARKER_DIR dir=$d markers=$n bad=$bad"
  [ "$bad" = 0 ] || return 1
  return 0
}
selftest(){
  local T np=0 nf=0 out; T="$(mktemp -d)"
  if bash "$WRITER" --out "$T/w.done" --push-rc 0 --stop-line "#1" --remote abc >/dev/null 2>&1 && [ "$(wc -l < "$T/w.done")" = 3 ]; then np=$((np+1)); else nf=$((nf+1)); fi
  if bash "$WRITER" --out "$T/w2.done" --push-rc "" >/dev/null 2>&1; then nf=$((nf+1)); else np=$((np+1)); fi
  printf 'push_rc=\nstop_line=a\nremote=b\n' > "$T/e.done"
  judge_marker "$T/e.done" >/dev/null 2>&1; [ "$?" -ne 0 ] && np=$((np+1)) || nf=$((nf+1))
  printf 'push_rc=a\nremote=b\n' > "$T/m.done"
  judge_marker "$T/m.done" >/dev/null 2>&1; [ "$?" -ne 0 ] && np=$((np+1)) || nf=$((nf+1))
  rm -rf "$T"
  echo "PUSHMARKER_SELFTEST=$([ "$nf" = 0 ] && echo PASS || echo FAIL) cases=$((np+nf)) pass=$np fail=$nf"
  [ "$nf" = 0 ] && return 0 || return 1
}
DIRS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIRS+=("${2:-}"); shift 2 ;;
    --selftest) selftest; exit $? ;;
    -h|--help) usage; exit 0 ;;
    *) echo "PUSHMARKER=FAIL reason=arg-not-accepted $1" >&2; exit $RC_USAGE ;;
  esac
done
if [ "${#DIRS[@]}" -gt 0 ]; then
  n=0; rc=0
  for d in "${DIRS[@]}"; do out="$(scan_dir "$d")"; r=$?; echo "$out"; [ "$r" = 0 ] || rc=$r; done
  exit $rc
fi
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
if integration "$T"; then
  echo "PUSHMARKER=PASS mode=integration fields=3 antipole-empty-value=red antipole-missing-field=red writer=$WRITER"
  exit $RC_PASS
fi
echo "PUSHMARKER=FAIL mode=integration writer=$WRITER"
exit $RC_FAIL
