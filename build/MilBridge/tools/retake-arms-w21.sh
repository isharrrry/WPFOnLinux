#!/usr/bin/env bash
# 主控 · 波 `#21` 五臂重取（世代成本 —— shim 变了就必须重取）。
# 依据：`build/MilBridge/arm-logs/README.md` 的"新世代怎么重绿"。
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"   # 波 `#77` 旧路径重指向：由仓根现推
cd "$ROOT" || exit 2
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

OUT="$HOME/wfp-runs/arms21"
mkdir -p "$OUT"
echo "=== arms re-take $(date '+%F %T') loadavg=$(cut -d' ' -f1-3 /proc/loadavg) ==="
echo "shim      = $(sha256sum build/shims/PresentationCore.HbTextLine.cs | cut -c1-16)"
echo "pc        = $(sha256sum build/PresentationCore.Linux/bin/Debug/PresentationCore.dll | cut -c1-16)"
echo "run.sh    = $(sha256sum build/MilBridge/run.sh | cut -c1-16)"
echo "Parity.cs = $(sha256sum build/MilBridge/tests/HbTextLineParity/Program.cs | cut -c1-16)"

say() { echo "--- $* ---"; }

# ---- 1) CoverageProbe（三支 tab 臂的宿主；它的 csproj 把真 shim 源编进去）----
say "rebuild CoverageProbe -c Release"
dotnet build build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj -c Release -m:1 --nologo -v q \
    > "$OUT/build-coverage.log" 2>&1
echo "CoverageProbe build rc=$?"

# ---- 2) 臂 1/5：tline（强配对；自带构建 HbTextLineParity + DirectBranchCheck）----
say "arm 1/5 tline"
timeout 3600 bash build/MilBridge/run.sh tline > "$OUT/tline.log" 2>&1
echo "tline rc=$?"

# ---- 3) 臂 2-4/5：三支 tab oracle ----
for arm in tab-zero tab-anchor tab-rtl; do
    say "arm $arm"
    ( cd build/MilBridge/tests/CoverageProbe/bin/Release && \
      timeout 3600 dotnet PresentationCore.Tests.dll \
        --tab-lines-oracle "$ROOT/tests/parity/windows/$arm/out/$arm-oracle.json" ) \
      > "$OUT/$arm.log" 2>&1
    echo "$arm rc=$?"
done

# ---- 4) 臂 5/5：textlineproto（**必须**有 DISPLAY，否则 ContractProbe 段缺 X 假红）----
say "arm 5/5 textlineproto"
DISPLAY=:97 timeout 3600 bash build/MilBridge/run.sh textline > "$OUT/textlineproto.log" 2>&1
echo "textlineproto rc=$?"

# ---- 5) 硬链接进 arm-logs（**绝不 cp**（顶 mtime ⇒ 架空弱配对判据）／**绝不 ln -s**（find -type f 漏掉））----
say "hard-link into arm-logs"
for pair in "tline:tline" "tab-zero:tab-zero" "tab-anchor:tab-anchor" "tab-rtl:tab-rtl" "textlineproto:textlineproto"; do
    src="${pair%%:*}"; dst="${pair##*:}"
    if [ -s "$OUT/$src.log" ]; then
        ln -f "$OUT/$src.log" "build/MilBridge/arm-logs/$dst.log" \
            && echo "ln -f $src.log -> arm-logs/$dst.log  (links=$(stat -c %h "build/MilBridge/arm-logs/$dst.log"))"
    else
        echo "!! $OUT/$src.log 为空 ⇒ **不覆盖** arm-logs/$dst.log（保留旧世代读数，门禁会给 STALE/NOINFO，好过静默换空日志）"
    fi
done

# ---- 6) 报每个臂日志的 sha16 + 自报身份行（供重钉登记表）----
say "arm log shas"
for f in tline tab-zero tab-anchor tab-rtl textlineproto; do
    p="build/MilBridge/arm-logs/$f.log"
    [ -f "$p" ] && printf '%-16s %s  %s\n' "$f" "$(sha256sum "$p" | cut -c1-16)" "$(stat -c %y "$p" | cut -c1-19)"
done
echo "=== done $(date '+%F %T') ==="
