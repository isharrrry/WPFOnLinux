#!/usr/bin/env bash
# T1b · **一条命令取 Extent 余差明细**（主控 2026-09-11 裁定 B）
# ============================================================================
#  用法：bash build/MilBridge/tools/t2d-extent-detail.sh [shim路径]
#    默认 shim 路径 = build/shims/PresentationCore.HbTextLine.cs（**真源**）
#    要临时用别的版本（例如 staging 副本）就显式传路径 —— **sha 会打进读数**
#  产物：build/MilBridge/gen/t2d-extent-mismatches.txt（全量明细，含被测 shim sha）
#  判据（脚本自证有牙）：明细条数必须 == 该版本下 `Extent` 不一致的行数；
#    在"Extent 恒等于 Height"的版本上（如 v7），应列出**全部**可比行（1298）——
#    这正是脚本"能把该形态抓出来"的证明。
#  ⚠️ 不跑应用、不起 Xvfb、不重建 PC；`-m:1`、**无 --no-build**。
set -uo pipefail
ROOT=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"
SHIM="${1:-$ROOT/build/shims/PresentationCore.HbTextLine.cs}"
[ -f "$SHIM" ] || { echo "[失败] 找不到 shim：$SHIM"; exit 3; }
SHA=$(sha256sum "$SHIM" | cut -d' ' -f1)
echo "== T2d · Extent 余差明细 =="
echo "被测 shim = $SHIM"
echo "           sha256=$SHA  ($(wc -l < "$SHIM") 行, $(date -r "$SHIM" +%F\ %T))"
echo "-- 编译 --"
cd "$ROOT"
if ! dotnet build build/MilBridge/tests/HbTextLineParity -c Release -m:1 --nologo -p:HbShimSrc="$SHIM" 2>&1 | tail -3; then
  echo "[失败] 编译失败 ⇒ 后续读数作废（按纪律：build 有 error 就不看读数）"; exit 4
fi
echo "-- 运行（**无 --no-build**）--"
cd build/MilBridge/tests/HbTextLineParity/bin/Release
T1B_SHIM_PATH="$SHIM" dotnet MilBridge.HbTextLineParity.dll > /tmp/t2d-extent-run.txt 2>&1
RC=$?
grep -E "行级一致|LineHeight>0 的用例|逐例一致|一致 @0.34|Extent 余差清单" /tmp/t2d-extent-run.txt | head -8
F="$ROOT/build/MilBridge/gen/t2d-extent-mismatches.txt"
N=$([ -f "$F" ] && grep -c "^LH_\|^A1_\|^A3_\|^F_\|^B_\|^M_" "$F" || echo 0)
echo
echo "明细文件 = $F"
echo "明细条数 = $N（文件头含被测 shim sha256）"
echo "harness 退出码 = $RC（非 0 = 含登记红，正常）"
head -8 "$F" 2>/dev/null
echo "T2D_EXTENT_SUMMARY shim_sha=$SHA details=$N harness_rc=$RC"
