#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# provider-repro-check.sh —— 「同输入复现性」留痕牙（`B-18`；`t48`／W4b）
#
# 【要解决的缺口】`B-18` 现取：门禁会**构建** ⇒ `provider` 位（`WFREEZE_…key=provider probs=nine-vs-live,tier-vs-live`）
#   会位移，而**位移无机器留痕**（在册已知设计态 ⇒ **本牙不判那两行为红**）。本牙只做一件事：
#   **给定两个产物，报「两次 sha16 是否相同」并**点名两个值**（**不许静默**）。
#
# 【判据】`PROVIDER_REPRODUCIBLE=yes`（两值逐位相同）／`=no` + **两个值都上屏**（可见、**不判红**）。
#   ⚠️ **射程边界（如实写）**：本牙**不**判「构建是否确定」——它只把**读数**变可见；
#   「连跑两次真构建」的真腿**归重活波**（`t48` 记 `NOINFO(reason=真腿归重活波)`）。
#   产物缺席 ⇒ `PROVIDER_REPRODUCIBLE=NOINFO reason=artifact-absent path=…`（**不算绿**）。
# 【自述】已接线：`verify-all.sh` 步名 `PROVIDER-REPRO`；覆盖面已计入（`build/close-wave.sh` 的 `fp_inputs()`）。
# 【测试钩子】`--selftest`：自造两个夹具目录（同内容 ⇒ `yes`；不同内容 ⇒ `no` 且点名两值）。
# 用法：bash provider-repro-check.sh [--a PATH] [--b PATH] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail
SELF="${BASH_SOURCE[0]}"; SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="${PRC_ROOT:-$(cd -- "$SELF_DIR/../../.." && pwd)}"
A="build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll"
B="build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll"
RC_PASS=0; RC_NOINFO=3; RC_USAGE=4
usage(){ sed -n '2,16p' "$SELF" | sed 's/^# \{0,1\}//'; }
cmp_pair(){  # $1 $2 ⇒ 印判词；rc 0（yes/no 都不判红）/3（缺席）
  local a="$1" b="$2" ha hb
  [ -f "$ROOT/$a" ] || { echo "PROVIDER_REPRODUCIBLE=NOINFO reason=artifact-absent path=$a"; return $RC_NOINFO; }
  [ -f "$ROOT/$b" ] || { echo "PROVIDER_REPRODUCIBLE=NOINFO reason=artifact-absent path=$b"; return $RC_NOINFO; }
  ha="$(sha256sum "$ROOT/$a" | cut -c1-16)"; hb="$(sha256sum "$ROOT/$b" | cut -c1-16)"
  if [ "$ha" = "$hb" ]; then
    echo "PROVIDER_REPRODUCIBLE=yes a=$a b=$b sha16=$ha"
  else
    echo "PROVIDER_REPRODUCIBLE=no a=$a a_sha16=$ha b=$b b_sha16=$hb（两值逐位不同 ⇒ **上屏、不判红**；按在册设计态，本牙只保证「位移可见」）"
  fi
  return $RC_PASS
}
selftest(){
  local T np=0 nf=0 out; T="$(mktemp -d)"
  mkdir -p "$T/d1" "$T/d2" "$T/e1" "$T/e2"
  printf 'x' > "$T/d1/p.dll"; printf 'x' > "$T/d2/p.dll"
  printf 'x' > "$T/e1/p.dll"; printf 'y' > "$T/e2/p.dll"
  out="$(PRC_ROOT="$T" bash "$SELF" --a d1/p.dll --b d2/p.dll 2>&1)"; case "$out" in *PROVIDER_REPRODUCIBLE=yes*) np=$((np+1));; *) nf=$((nf+1));; esac
  out="$(PRC_ROOT="$T" bash "$SELF" --a e1/p.dll --b e2/p.dll 2>&1)"; case "$out" in *PROVIDER_REPRODUCIBLE=no*a_sha16=*b_sha16=*) np=$((np+1));; *) nf=$((nf+1));; esac
  rm -rf "$T"
  echo "PROVIDER_REPRO_SELFTEST=$([ "$nf" = 0 ] && echo PASS || echo FAIL) cases=$((np+nf)) pass=$np fail=$nf"
  [ "$nf" = 0 ] && return 0 || return 1
}
while [ $# -gt 0 ]; do
  case "$1" in
    --a) A="${2:-}"; shift 2 ;;
    --b) B="${2:-}"; shift 2 ;;
    --selftest) selftest; exit $? ;;
    -h|--help) usage; exit 0 ;;
    *) echo "PROVIDER_REPRODUCIBLE=NOINFO reason=arg-not-accepted $1" >&2; exit $RC_USAGE ;;
  esac
done
cmp_pair "$A" "$B"; exit $?
