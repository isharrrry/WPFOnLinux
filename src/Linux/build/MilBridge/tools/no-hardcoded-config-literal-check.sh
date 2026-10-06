#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# no-hardcoded-config-literal-check.sh —— 「**禁止未登记的 `bin/Debug` 字面量**」防回归牙
#   （`TASK-O1-O4-O6` §O2）
#
# 【它挡的是什么】本仓权威配置是 `WpfLinuxSelfBuiltConfiguration`（唯一声明 =
#   `src/Linux/build/SelfBuiltConfig.props`；现读 **Release**；唯一 shell 读取器 =
#   `src/Linux/build/selfbuilt-config.sh`）。源码面里**写死 `bin/Debug`** 的消费点会
#   在切配置后静默读**错件**（`R4`/`R5` 为它修过 ~29 处）—— 这正是本仓老族
#   「同一语义多处 ⇒ 必然分叉」。本牙把"新写的 `bin/Debug` 消费点"钉住：**命中且未登记 ⇒ 红**。
#
# 【扫描面（写死）】`src/Linux` ＋ `src/Microsoft.DotNet.Wpf.Linux` ＋ `Guide.Linux` 下的
#   `*.sh *.py *.csproj *.props *.targets`；排除 `obj/ bin/ .artifacts/ upstream/ __pycache__/ .git/`。
# 【注释处理】`sh/py` 的整行 `#` 注释、XML（csproj/props/targets）的 `<!-- … -->` 块 —— **不算命中**
#   （"注释/文档里的 `bin/Debug` 可留"）。只判**代码行**。
# 【豁免（声明式）】`src/Linux/build/MilBridge/hardcoded-config-exempt.tsv`，列：
#   `file<TAB>anchor16<TAB>class<TAB>why<TAB>registered`；`anchor16` = 该行 `strip()` 后的 sha256 前 16
#   （**内容锚、禁行号** —— 行号漂移不红，行内容被改 ⇒ 红，必须重发豁免行）。
#   `registered` 必须是**已入册**缺陷号（`src/Linux/build/MilBridge/tools/defect-registry-declared.tsv`），
#   或在册族号（`D-G92` 等）；空 ⇒ 该豁免行不成立。
# 【三态】`rc=0 NOHARDCODEDCFG=PASS`｜`rc=1 NOHARDCODEDCFG=FAIL`（逐条点名）｜
#   `rc=2 NOHARDCODEDCFG=NOINFO`（扫描面为空/无豁免件/取不到 ⇒ **不算绿**）。
#   ⚠️ `NOINFO` **绝不等于绿**。
#
# 【用法】`bash no-hardcoded-config-literal-check.sh [--root DIR] [--exempt PATH] [--list] [--selftest]`
#   `--list`：只列命中（`file<TAB>anchor16<TAB>line`）后退出 —— 用于**重发豁免表**。
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="${NHCL_ROOT:-$(cd "$HERE/../../../../.." && pwd)}"
EXEMPT="${NHCL_EXEMPT:-$R/src/Linux/build/MilBridge/hardcoded-config-exempt.tsv}"
REG="$R/src/Linux/build/MilBridge/tools/defect-registry-declared.tsv"
LIST=0; SELFTEST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root)     R="$2"; shift 2 ;;
    --root=*)   R="${1#*=}"; shift ;;
    --exempt)   EXEMPT="$2"; shift 2 ;;
    --exempt=*) EXEMPT="${1#*=}"; shift ;;
    --list)     LIST=1; shift ;;
    --selftest) SELFTEST=1; shift ;;
    -h|--help)  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "NOHARDCODEDCFG=NOINFO reason=bad-usage arg=$1" >&2; exit 2 ;;
  esac
done

# ── 扫描面（先写死；域 = 三根 × 五扩展名）──────────────────────────────────────
ROOTS=("src/Linux" "src/Microsoft.DotNet.Wpf.Linux" "Guide.Linux")
EXTS=('sh' 'py' 'csproj' 'props' 'targets')
SELF_REL="src/Linux/build/MilBridge/tools/no-hardcoded-config-literal-check.sh"

# 扫描：把命中打成 `file<TAB>anchor16<TAB>line` 行。XML 的 `<!--` 块用 awk 现态处理。
scan_hits() {
  local f abs rel ext
  # 收集候选文件（`find` 排除构建/上游目录）
  while IFS= read -r f; do
    rel="${f#$R/}"
    case "$rel" in "$SELF_REL") continue ;; esac
    ext="${f##*.}"
    # 逐行：XML 走 awk 块态；sh/py 走行首注释判定
    if [ "$ext" = "csproj" ] || [ "$ext" = "props" ] || [ "$ext" = "targets" ]; then
      awk -v F="$rel" '
        { line=$0
          if (inc) { if (index(line,"-->")>0) inc=0; next }
          if (index(line,"<!--")>0 && index(line,"-->")<=0) { inc=1; next }
          if (index(line,"<!--")>0) next
          if (index(line,"bin/Debug")>0) print F "\t" line }
      ' "$f"
    else
      awk -v F="$rel" -v EXT="$ext" '
        { line=$0
          if (EXT=="sh" || EXT=="py") { s=line; sub(/^[ \t]+/,"",s); if (substr(s,1,1)=="#") next }
          if (index(line,"bin/Debug")>0) print F "\t" line }
      ' "$f"
    fi
  done < <(find "${ROOTS[@]/#/$R/}" -type f \( -name '*.sh' -o -name '*.py' -o -name '*.csproj' -o -name '*.props' -o -name '*.targets' \) \
             -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/.artifacts/*' -not -path '*/upstream/*' -not -path '*/__pycache__/*' -not -path '*/.git/*' 2>/dev/null | LC_ALL=C sort)
}

anchor16() { printf '%s' "$1" | sha256sum | cut -c1-16; }

# 豁免表：每行 `…file<TAB>anchor16<TAB>class<TAB>registered<TAB>why` ⇒ 打 `file<TAB>anchor<TAB>registered`。
load_exempt() {
  [ -f "$EXEMPT" ] || return 1
  awk -F'\t' '!/^#/ && NF>=4 && $1!="file"{print $1"\t"$2"\t"$4}' "$EXEMPT"
}
decl_ids() {
  [ -f "$REG" ] || return 0
  awk -F'\t' '$1=="ID"{print $2}' "$REG"
}

hits="$(scan_hits)"
n_hits="$(printf '%s\n' "$hits" | grep -c . || true)"
n_files="$(printf '%s\n' "$hits" | grep . | cut -f1 | sort -u | grep -c . || true)"

if [ "$LIST" = 1 ]; then
  while IFS=$'\t' read -r file line; do
    [ -n "$file" ] || continue
    printf '%s\t%s\t%s\n' "$file" "$(anchor16 "$line")" "$line"
  done <<< "$hits"
  exit 0
fi

if [ -z "$hits" ]; then
  echo "NOHARDCODEDCFG=NOINFO reason=scan-empty（扫描面没扫到任何命中 ⇒ 算不出来，**不算绿**；要么树真干净、要么扫描面坏了）"
  exit 2
fi
ex="$(load_exempt)" || { echo "NOHARDCODEDCFG=NOINFO reason=exempt-absent path=$EXEMPT（没有豁免表 ⇒ 判不了 ⇒ **不算绿**）"; exit 2; }
declare -A EX=() IDS=()
while IFS=$'\t' read -r ef ea er; do [ -n "$ef" ] && EX["$ef|$ea"]="$er"; done <<< "$ex"
while IFS= read -r id; do [ -n "$id" ] && IDS["$id"]=1; done < <(decl_ids)

fail=0; ok=0; unreg=0
while IFS=$'\t' read -r file line; do
  [ -n "$file" ] || continue
  a="$(anchor16 "$line")"
  reg="${EX["$file|$a"]:-}"
  if [ -n "$reg" ]; then
    if [ -n "${IDS["$reg"]:-}" ]; then ok=$((ok+1)); continue; fi
    # 豁免行挂了一个**未入册**的编号 ⇒ 该豁免不成立 ⇒ 命中照旧红（点名）
    unreg=$((unreg+1)); fail=$((fail+1))
    printf 'NOHARDCODEDCFG_HIT file=%s anchor=%s registered=%s（豁免行挂的编号**不在已入册域**`defect-registry-declared.tsv` ⇒ 豁免不成立）\n' "$file" "$a" "$reg"
    continue
  fi
  fail=$((fail+1))
  printf 'NOHARDCODEDCFG_HIT file=%s anchor=%s line=%s（代码行里的 `bin/Debug` 未登记：真消费点请改走唯一声明 `$SELFBUILT_CONFIG`／`WpfLinuxSelfBuiltConfiguration`；确属刻意跨配置/夹具请在豁免表登记 why＋在册号）\n' \
    "$file" "$a" "$(printf '%s' "$line" | cut -c1-120)"
done <<< "$hits"

if [ "$fail" -eq 0 ]; then
  echo "NOHARDCODEDCFG=PASS hits=$n_hits files=$n_files exempt=$ok unknown=0（代码行里没有未登记的 bin/Debug 字面量）"
  exit 0
fi
echo "NOHARDCODEDCFG=FAIL hits=$n_hits files=$n_files exempt=$ok unknown=$fail unregistered-exempt=$unreg（逐条点名在上；未登记 ⇒ 必红）"
exit 1
