#!/usr/bin/env bash
# path-map-covers-old-paths-check.sh —— 扫全仓旧路径前缀，逐个断言在 PATH-MAP.md 有映射（结构上游化·合并波）
# 判据：源码/配置面出现的每个「旧前缀 token」都必须在 docs.Linux/evidence/PATH-MAP.md 里出现（映射表承担旧路径）。
#   · 射程：git 跟踪的 *.sh *.py *.cs *.csproj *.props *.targets *.json *.tsv *.sln *.yml *.yaml（排除 upstream/obj/bin/.artifacts）
#   · 排除：断言面清单件（内容一字不改 ⇒ 其旧路径由 PATH-MAP 承担）＋ PATH-MAP.md 自身
#   · 旧前缀 token：`src/Linux/build/` `src/Linux/tests/` `src/Linux/samples/` `src/Linux/tools/` `wpf-linux.sln` `verify-all.sh`（词边界，且未被 src/Linux 前缀覆盖）
# rc：0=PASS ｜ 1=FAIL（点名未映射 token） ｜ 2=NOINFO（映射表缺席/算不出）
set -uo pipefail
SELF="${BASH_SOURCE[0]}"; SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="${PMC_OP_ROOT:-$(cd -- "$SELF_DIR/../../../../.." && pwd)}"
MAP_REL='docs.Linux/evidence/PATH-MAP.md'
[ -d "$ROOT" ] || { echo "PATHMAP=NOINFO reason=root-absent root=$ROOT"; exit 2; }
cd "$ROOT" || { echo "PATHMAP=NOINFO reason=cd-failed"; exit 2; }
[ -s "$MAP_REL" ] || { echo "PATHMAP=NOINFO reason=map-absent path=$MAP_REL"; exit 2; }

# 断言面清单（内容一字不改 ⇒ 不扫；其旧路径由本表承担）
ASSERT='docs/WAVE66-PREREGISTRATION.md|docs/PORT-SPEC.md|docs/INDEX.md|src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md|handoff.md|docs/ROUTES.md'
ASSERT_LIST="$(printf '%s\n' "$ASSERT" | tr '|' '\n')"

TOKENS='src/Linux/build/ src/Linux/tests/ src/Linux/samples/ src/Linux/tools/ wpf-linux.sln verify-all.sh'
map_text="$(cat "$MAP_REL")"
missing=0; found=0
declare -A SEEN=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  rel="${f#./}"
  case "$rel" in upstream/*|*/obj/*|*/bin/*|*/.artifacts/*|docs.Linux/evidence/PATH-MAP.md) continue ;; esac
  grep -qxF -- "$rel" <<< "$ASSERT_LIST" && continue
  # 该行里出现的旧 token（词边界、且未被 src/Linux 前缀覆盖）
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    SEEN["$tok"]=1
    if ! grep -qF -- "$tok" "$MAP_REL"; then
      echo "PATHMAP_HIT token=$tok file=$rel"
      missing=$((missing + 1))
    fi
  done < <(grep -noE '(^|[^A-Za-z0-9_./-])(build|tests|samples|tools)/|(^|[^A-Za-z0-9_./-])wpf-linux\.sln|(^|[^A-Za-z0-9_./-])verify-all\.sh' "$f" 2>/dev/null \
             | sed -E 's/^[0-9]+://; s/^[^A-Za-z0-9_]*//' | sed -E 's#^verify-all\.sh$#verify-all.sh#; s#^wpf-linux\.sln$#wpf-linux.sln#' | LC_ALL=C sort -u)
done < <(git ls-files -- '*.sh' '*.py' '*.cs' '*.csproj' '*.props' '*.targets' '*.json' '*.tsv' '*.sln' '*.yml' '*.yaml' 2>/dev/null)

echo "PATHMAP_CAND=${#SEEN[@]}"
if [ "$missing" -gt 0 ]; then
  echo "PATHMAP=FAIL unmapped=$missing（逐条 PATHMAP_HIT 见上；补进 $MAP_REL）"
  exit 1
fi
echo "PATHMAP=PASS unmapped=0 map=$MAP_REL"
exit 0
