#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# silent-threshold-ban-check.sh —— 「**读数类行禁静默阈值**」牙（`R-7`；`TASK-0757`；`T-D2` 落）
#
# 【它挡的是什么（`t196`／`t199` 两次咬；恒真断言族第五例候选）】
#   只在 `consumes > 0` 时才打印 ⇒ 输出**看上去就是 0**，与「真 0 次」**不可区分**
#   （把「没取到」印成「没发生」）。正确形态：**要么必打**、**要么打具名缺省行**
#   （`consumes=NOINFO(reason=no-leg)`）；**阈值一律删**。
#
# 【机器判据（`R-7` 逐字；本件的**唯一**字样来源）】
#   `(if|&&).*>[[:space:]]*[0-9]+.*fprintf` 命中即红（逐行点名 `文件:行`）。
#   ⇒ 三态：`PASS=rc0`／`FAIL=rc1`／`NOINFO=rc2`（算不出，**不许当绿**）／`4`=用法错。
#
# 【射程（**队长 `T-D2` 裁决 (a)，逐字照办**）】**只扫源码**：
#   `*.c`／`*.h`／`*.sh`／`*.py`（`--dir` 现取 glob；默认整棵仓树，排除
#   `.git`／`obj`／`bin`／`.artifacts`／`upstream`／`__pycache__`／`TestResults`）。
#   🔴 **不扫 `*.md`** —— 一举消掉两处假红：① 载体/侦察件的**自指**（侦察件自报「全仓 5→9 行命中」）；
#   ② `src/Linux/build/MilBridge/*.md` 里**引用判据行**的证据件被误判。**判词里永远带 `files=`／`lines=`**。
#   ⚠️ **本件自身也在射程内**（它是 `.sh`）：`R-7` 的字样在本件里只以**正则常量**形态出现，而该常量串
#      **不命中自己**（`>` 之后紧跟 `[`，不是数字）⇒ 本件不会自红；**将来谁在本件里写进「字面样例」
#      ⇒ 本件当场自红 —— 这是设计**（自指污染在这里成了护栏，不是洞）。
#
# 【具名豁免（声明式；**必上屏、不静默**；**超上限即红**）】—— 队长裁决 (b)
#   `src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/wic-shim/wic_proxy.c` **3 处** `g_trace_budget-- > 0`：
#   形态是**有界 trace 预算**型限流（预算耗尽即静默），**不是**「读数判别式」的实数闸（`if (consumes > 0)`）
#   ⇒ 直接套 `R-7` 正则会**假红**这三处 ⇒ 纳入**具名豁免清单**（`件路径|行锚|为什么`），上限 `cap=3`
#   （**上限＝现读处数** ⇒ 树长大／新加一处同类站点 ⇒ **当场红**，与 `repo-alias-allow.tsv` 同口径）。
#   上屏形制：`SILENT_THRESHOLD_ALLOW n=<处数> cap=<上限> sites=<件>×<处数>`（＋每条 `…_SITE` 明细）。
#
# 【缺省行 token 统一（`no-leg`）—— **待主裁，本件只报数、不进 `rc`**】
#   `R-7` 还写着「缺省行 token 必须统一为 `no-leg` 形制」，而现仓仍有**变体残留**（「`no*arr*leg*` 带中缀」
#   那一族）。⚠️ 本件**不逐字复写**那些变体（写了就自扫自指）；「命中变体 ⇒ **红**还是 **警告**」**侦察件列为待主裁**
#   ⇒ 本件**不判**，只印 `SILENT_THRESHOLD_TOKEN_SCAN hits=… sites=… decision=deferred`（**可见，不冒充红**）。
#
# 【自述】已接线：`Guide.Linux/verify-all.sh` 步名 `SILENT-THRESHOLD`；覆盖面已计入（`src/Linux/build/close-wave.sh` 的 `fp_inputs()`）。
# 【用法】bash silent-threshold-ban-check.sh [--root DIR] [--dir DIR] [--file F] [--allow F] [--allow-cap N] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="${STB_ROOT:-$(cd -- "$SELF_DIR/../../../../.." && pwd)}"
DIR="${STB_DIR:-}"
ONE_FILE="${STB_FILE:-}"
ALLOW_FILE="${STB_ALLOW:-}"
ALLOW_CAP="${STB_ALLOW_CAP:-3}"
RC_PASS=0; RC_FAIL=1; RC_NOINFO=2; RC_USAGE=4
W=""
say() { printf '%s\n' "$*"; }

# ── 判据字样（**唯一来源**）：① 静默阈值禁令；② 缺省行 token 的变体族（**只报数**，见件头）
BAN_ERE='(if|&&).*>[[:space:]]*[0-9]+.*fprintf'
TOK_ERE='[A-Za-z0-9_-]*noarr[A-Za-z0-9_-]*leg[A-Za-z0-9_-]*'

# ── 内置豁免清单（`件相对路径|行锚|为什么`；`#` 起头为注释）────────────────────────
allow_builtin() {
  cat <<'ALLOW'
src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/wic-shim/wic_proxy.c|g_trace_budget-- > 0|有界 trace 预算型限流（预算耗尽即静默）—— 不是「读数判别式」的实数闸，R-7 要挡的是后者
ALLOW
}

rel_of() {
  local p
  p="$(realpath -m --relative-to="$ROOT" "$1" 2>/dev/null || printf '%s' "$1")"
  printf '%s' "$p"
}

collect_files() {
  if [ -n "$ONE_FILE" ]; then
    [ -f "$ONE_FILE" ] && printf '%s\n' "$ONE_FILE"
    return 0
  fi
  find "$DIR" \
    \( -name .git -o -name obj -o -name bin -o -name .artifacts -o -name upstream \
       -o -name __pycache__ -o -name TestResults \) -prune \
    -o -type f \( -name '*.c' -o -name '*.h' -o -name '*.sh' -o -name '*.py' \) -print
}

is_allow() {  # $1=rel件 $2=行内容 $3=行号 ⇒ 命中则**印明细**并返回 0
  local rel="$1" line="$2" ln="$3" r a w
  while IFS='|' read -r r a w; do
    [ -n "${r:-}" ] || continue
    case "$r" in '#'*) continue ;; esac
    [ "$r" = "$rel" ] || continue
    case "$line" in
      *"$a"*) say "SILENT_THRESHOLD_ALLOW_SITE file=$rel:$ln anchor=$a why=$w"; return 0 ;;
    esac
  done < "$W/allow.tsv"
  return 1
}

run_check() {
  W="$(mktemp -d)"; trap 'rm -rf "$W"' RETURN
  if [ -n "$ALLOW_FILE" ]; then
    [ -r "$ALLOW_FILE" ] || { say "SILENT_THRESHOLD=NOINFO reason=allow-file-unreadable path=$ALLOW_FILE"; return $RC_NOINFO; }
    cp -p "$ALLOW_FILE" "$W/allow.tsv"
  else
    allow_builtin > "$W/allow.tsv"
  fi
  local n_allow_rows; n_allow_rows="$(grep -c . "$W/allow.tsv" || true)"
  collect_files > "$W/files.txt" || true
  local n_files; n_files="$(grep -c . "$W/files.txt" || true)"
  if [ "$n_files" = 0 ]; then
    say "SILENT_THRESHOLD=NOINFO reason=no-source-in-scope dir=$DIR ext=c,h,sh,py"
    return $RC_NOINFO
  fi

  local lines=0 hits=0 allow=0 f rel hl ln content nl
  local -A allow_sites=()
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="$(rel_of "$f")"
    nl="$(wc -l < "$f" 2>/dev/null || printf '0')"; nl="${nl:-0}"
    lines=$(( lines + nl ))
    grep -nE "$BAN_ERE" "$f" > "$W/h.txt" 2>/dev/null || true
    while IFS= read -r hl; do
      [ -n "$hl" ] || continue
      ln="${hl%%:*}"; content="${hl#*:}"
      if is_allow "$rel" "$content" "$ln"; then
        allow=$((allow+1)); allow_sites["$rel"]=$(( ${allow_sites["$rel"]:-0} + 1 )); continue
      fi
      hits=$((hits+1))
      say "SILENT_THRESHOLD_HIT file=$rel:$ln reason=silent-threshold snippet=$content"
    done < "$W/h.txt"
  done < "$W/files.txt"

  # ── 缺省行 token 变体：**只报数**（待主裁；不进 rc）──────────────────────────────
  : > "$W/tok.txt"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="$(rel_of "$f")"
    { grep -nE "$TOK_ERE" "$f" 2>/dev/null || true; } | sed "s#^#$rel:#" >> "$W/tok.txt"
  done < "$W/files.txt"
  local n_tok; n_tok="$(grep -c . "$W/tok.txt" || true)"

  local sites='' k
  if [ "${#allow_sites[@]}" -gt 0 ]; then
    for k in "${!allow_sites[@]}"; do sites="$sites $k×${allow_sites[$k]}"; done
  else
    sites=' -（0 处）'
  fi
  say "SILENT_THRESHOLD_ALLOW n=$allow cap=$ALLOW_CAP sites=$sites"
  say "SILENT_THRESHOLD_ALLOW_ROWS rows=$n_allow_rows cap=$ALLOW_CAP（豁免是**闭集**：件路径＋行内容锚；上限＝现读处数 ⇒ 树长大也红）"
  say "SILENT_THRESHOLD_TOKEN_SCAN hits=$n_tok decision=deferred（目标 token 统一为 no-leg；变体的「红/警告」待主裁；本件只报数、不进 rc）"
  if [ "$n_tok" -gt 0 ]; then
    head -5 "$W/tok.txt" > "$W/tok5.txt" 2>/dev/null || true
    while IFS= read -r t; do say "SILENT_THRESHOLD_TOKEN_SITE $t"; done < "$W/tok5.txt"
  fi
  say "SILENT_THRESHOLD_SCOPE dir=$DIR ext=c,h,sh,py files=$n_files lines=$lines md=not-scanned(裁决 a)"

  if [ "$lines" = 0 ]; then
    say "SILENT_THRESHOLD=NOINFO reason=no-line-scanned files=$n_files dir=$DIR（空集不许当 PASS）"
    return $RC_NOINFO
  fi
  if [ "$allow" -gt "$ALLOW_CAP" ]; then
    say "SILENT_THRESHOLD=FAIL reason=allow-cap-exceeded files=$n_files lines=$lines hits=$hits allow=$allow cap=$ALLOW_CAP"
    return $RC_FAIL
  fi
  if [ "$hits" -gt 0 ]; then
    say "SILENT_THRESHOLD=FAIL files=$n_files lines=$lines hits=$hits allow=$allow cap=$ALLOW_CAP reason=silent-threshold"
    return $RC_FAIL
  fi
  say "SILENT_THRESHOLD=PASS files=$n_files lines=$lines hits=0 allow=$allow cap=$ALLOW_CAP（射程＝源码 *.c/*.h/*.sh/*.py；*.md 不扫）"
  return $RC_PASS
}

# ─────────────────────────── 两极化自测（零 `X`、零 `dotnet`、不依赖真仓） ───────────────────────────
selftest() {
  local T np=0 nf=0 tot=0 out rc
  T="$(mktemp -d)"; trap 'rm -rf "$T"' RETURN
  mkdir -p "$T/emptydir"
  # 正极：合规读取行（无条件打 ＋ 具名缺省行）
  {
    printf '%s\n' 'void f(void) { fprintf(stderr, "consumes=%d\n", n); }'
    printf '%s\n' 'if (n == 0) fprintf(stderr, "consumes=NOINFO(reason=no-leg)\n");'
  } > "$T/ok.c"
  # 反极（静默阈值）：**运行时拼**（不把字面样例写进本件源码）
  printf 'if (consumes > %s) fprintf(stderr, "consumes=%%d\\n", consumes);\n' '0' > "$T/bad.c"
  # 豁免夹具：三处「有界 trace 预算」形态（与真件同形，**自造**）
  : > "$T/wic_proxy.c"
  local i
  for i in 1 2 3; do
    printf 'if (getenv("X") && g_trace_budget-- > %s) fprintf(stderr, "T%s\\n");\n' '0' "$i" >> "$T/wic_proxy.c"
  done
  printf '%s\n' 'wic_proxy.c|g_trace_budget-- > 0|夹具：有界 trace 预算（非读数判别式）' > "$T/allow-1.tsv"
  printf '%s\n' '# 空清单（同一行不在豁免里 ⇒ 必须翻红）' > "$T/allow-0.tsv"
  # 上限腿：四处同类站点 vs cap=3
  : > "$T/wic_cap.c"
  for i in 1 2 3 4; do
    printf 'if (getenv("X") && g_trace_budget-- > %s) fprintf(stderr, "C%s\\n");\n' '0' "$i" >> "$T/wic_cap.c"
  done
  printf '%s\n' 'wic_cap.c|g_trace_budget-- > 0|夹具：上限腿' > "$T/allow-cap.tsv"
  # 空边：目录里没有源码件
  printf '%s\n' 'not a source file' > "$T/emptydir/readme.txt"

  run() {  # run <名> <期望rc> <必须出现> <必须不出现> <argv…>
    local nm="$1" want="$2" must="$3" mustnot="$4"; shift 4
    local o; o="$(bash "$SELF" "$@" 2>&1)"; rc=$?
    tot=$((tot+1))
    local ok=1
    [ "$rc" = "$want" ] || ok=0
    case "$o" in *"$must"*) ;; *) ok=0 ;; esac
    if [ -n "$mustnot" ]; then case "$o" in *"$mustnot"*) ok=0 ;; esac; fi
    if [ "$ok" = 1 ]; then np=$((np+1)); else nf=$((nf+1)); fi
    printf 'SILENT_THRESHOLD_SELFTEST_CASE case=%s want_rc=%s got_rc=%s must=%s => %s\n' \
      "$nm" "$want" "$rc" "$must" "$([ "$ok" = 1 ] && echo OK || echo FAIL)"
  }

  run D1-positive-fixture 0 'SILENT_THRESHOLD=PASS files=1 lines=2 hits=0' '' --root "$T" --file "$T/ok.c"
  run D2-negative-silent-threshold 1 'SILENT_THRESHOLD_HIT file=bad.c:1 reason=silent-threshold' '' --root "$T" --file "$T/bad.c"
  run D2b-negative-verdict 1 'SILENT_THRESHOLD=FAIL files=1 lines=1 hits=1 allow=0 cap=3 reason=silent-threshold' '' --root "$T" --file "$T/bad.c"
  run D3-allow-in-place 0 'SILENT_THRESHOLD=PASS files=1 lines=3 hits=0 allow=3 cap=3' '' --root "$T" --file "$T/wic_proxy.c" --allow "$T/allow-1.tsv"
  run D3b-allow-onscreen 0 'SILENT_THRESHOLD_ALLOW n=3 cap=3 sites= wic_proxy.c×3' '' --root "$T" --file "$T/wic_proxy.c" --allow "$T/allow-1.tsv"
  run D4-allow-removed-must-red 1 'SILENT_THRESHOLD_HIT file=wic_proxy.c:1 reason=silent-threshold' '' --root "$T" --file "$T/wic_proxy.c" --allow "$T/allow-0.tsv"
  run D5-allow-cap-exceeded 1 'SILENT_THRESHOLD=FAIL reason=allow-cap-exceeded' '' --root "$T" --file "$T/wic_cap.c" --allow "$T/allow-cap.tsv" --allow-cap 3
  run D6-no-source-in-scope 2 'SILENT_THRESHOLD=NOINFO reason=no-source-in-scope' '' --root "$T" --dir "$T/emptydir"

  say "SILENT_THRESHOLD_SELFTEST=$([ "$nf" = 0 ] && echo PASS || echo FAIL) cases=$tot pass=$np fail=$nf"
  [ "$nf" = 0 ] && return $RC_PASS || return $RC_FAIL
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root)      ROOT="${2:-}"; shift 2 ;;
    --dir)       DIR="${2:-}"; shift 2 ;;
    --file)      ONE_FILE="${2:-}"; shift 2 ;;
    --allow)     ALLOW_FILE="${2:-}"; shift 2 ;;
    --allow-cap) ALLOW_CAP="${2:-3}"; shift 2 ;;
    --selftest)  selftest; exit $? ;;
    -h|--help)   sed -n '2,50p' "$SELF" | sed 's/^# \{0,1\}//'; exit $RC_PASS ;;
    *) say "SILENT_THRESHOLD=NOINFO reason=arg-not-accepted arg=$1" >&2; exit $RC_USAGE ;;
  esac
done
[ -n "$DIR" ] || DIR="$ROOT"
run_check; exit $?
