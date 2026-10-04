#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# report-id-domain-check.sh —— 「**报告里写的缺陷编号必须已入册**」牙（`t19`／`D` 组③；`D-G129` 同族）
#
# 【它挡的是什么（`t18`→`t19` 现场）】
#   `D-G150`／`D-G151`（以及 `D-G166`）当年**只登记在 `docs/ROUTES.md`**，而注册器
#   `defect-registry-check.sh` 的 route 键集合是 `ALLKEYS='KD CS HO AB KRJ KRF KRP'`
#   ⇒ `--emit` 的 `declared=` **不含它们**、`DEFREG` 照旧 `PASS` ⇒ **报告里写着一批"没人管"的编号**。
#   ⇒ 本件在最外层补一条**单向包含**断言：**报告语料里出现的 `D-G<digits>` ⊆ declared 集**。
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）】
#   rc=0 `REPORTID=PASS`    语料非空 ∧ declared 集非空 ∧ 每一个报告里出现的 `D-G<digits>` 都在 declared 集里
#   rc=1 `REPORTID=FAIL`    逐条点名 `file:line:id`（**且同时打印 declared 里最接近的号供人核**）
#   rc=3 `REPORTID=NOINFO`  语料为空／declared 集取不到／`examined==0`（**零检查不许给 PASS**）
#
# 【第二条判据（**同趟加**）：编号「出现」∧「成条」绑成一条】`src/Linux/build/MilBridge/book-entry-required.tsv`
#   列出的编号必须 ① 在 declared 集里 ② 在缺陷册（route 键 `KD`）里有**条目形态**标题 ③ 册里至少出现一次；
#   任一不满足 ⇒ `REPORTID=FAIL` 并点名。⚠️ **不把「全集」判红**：册内其它 `req` 含 `KD` 而无条目形态的编号
#   逐条上屏 `BOOK_ENTRY_UNREQUIRED_MISSING`（**已登记的缺口，可见但不判红**）。
#   口径句：**"声明只能把『已知在册具名』的降成可见，不能把『未知』降成绿；反过来，也不许把『已知缺口』做成恒红。"**
#
# 【域（**逐字写死，免得被读成"全仓都管"**）】
#   · **语料** = `src/Linux/build/MilBridge/*report*.md`（可用 `--corpus-glob` 覆盖）；**不扫** `docs/`、`*.log`、
#     `gen/`、历史台账 —— 那些是**别的口径**（`ROUTES.md` 的登记由 `DEFREG` 自己管）。
#   · **编号形态** = `\bD-G[0-9]+\b` —— **只要数字段**（这正是本组要的形态）。
#     ⚠️ **如实划界**：带段后缀的号（`D-T2-b`／`D-G57-shim-singleface`）与合成/通配写法（`D-G10x`）**不在**本牙形态内
#     ⇒ 它们**不被本牙判**（现读语料里这类有 9 种：`D-C`／`D-G10x`／`D-G12-CH`／`D-G12-RED`／
#     `D-G57-shim-singleface`／`D-T2-a/b/d`／`D-Z9`）⇒ 属**射程缺口**，逐条上屏 `REPORTID_OUT_OF_SHAPE`。
#   · **declared 集** = `src/Linux/build/MilBridge/tools/defect-registry-declared.tsv` 的 `^ID<TAB><id>` 列
#     （**唯一权威**；`DEFREG` 自己就是照它判的）。
#
# 【本牙自己的接线状态（**必须字面写在件头**：判「件头自述 vs 接线」的对手牙会读它）】
#   **已接线**：`Guide.Linux/verify-all.sh` 的 `run_step "REPORT-ID-DOMAIN" …`（**本件不写步号** —— 以现场步序为准；
#   写死步号＝下一条会漂移的陈旧自述）。接线由 `t27` 落（`t19` 落地时受顺序约束：`t20` → `t19` → `t21`，
#   而覆盖面与 `[42] --expect` 在 `src/Linux/build/close-wave.sh`／`Guide.Linux/verify-all.sh`、属 `t20` 的写域 ⇒ 当时**先落件、后接线**）；
#   接线补丁与其历史逐字留在 `src/Linux/build/MilBridge/P0-teeth-close-report.md`。
#   ⚠️ 本条自述**必须与现场一致**（判「件头自述 vs 接线」的对手牙**两个方向都判**）：
#     自称"已接线"而 `^run_step` 零命中 ⇒ `rule=reverse-selfdesc-wired-but-not-wired` 红。
#
# 【测试钩子】`--selftest`：fixture 正极 ＋ 两条反极 ＋ 两条 NOINFO 边（零 `X`、零 `dotnet`、不依赖真仓）。
#   用法：bash report-id-domain-check.sh [--root DIR] [--decl PATH] [--corpus-glob GLOB] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="$(cd -- "$SELF_DIR/../../../../.." && pwd)"
DECL="$ROOT/src/Linux/build/MilBridge/tools/defect-registry-declared.tsv"
GLOB='src/Linux/build/MilBridge/*report*.md'
IDRE='D-G[0-9]+'
RC_PASS=0; RC_FAIL=1; RC_NOINFO=3; RC_USAGE=4
MODE="check"

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; DECL="$ROOT/src/Linux/build/MilBridge/tools/defect-registry-declared.tsv"; shift 2 ;;
    --decl) DECL="${2:-}"; shift 2 ;;
    --corpus-glob) GLOB="${2:-}"; shift 2 ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) echo "用法: report-id-domain-check.sh [--root DIR] [--decl PATH] [--corpus-glob GLOB] [--selftest]"; exit $RC_PASS ;;
    *) echo "REPORTID=FAIL reason=usage:unknown-arg $1"; exit $RC_USAGE ;;
  esac
done

run_check() {
  [ -r "$DECL" ] || { echo "REPORTID=NOINFO reason=decl-absent path=$DECL"; return $RC_NOINFO; }
  local declared; declared="$(awk -F'\t' '$1=="ID"{print $2}' "$DECL" 2>/dev/null | sort -u)"
  [ -n "$declared" ] || { echo "REPORTID=NOINFO reason=decl-empty path=$DECL"; return $RC_NOINFO; }
  local files=0 ids=0 bad='' outshape='' bind_noinfo=0
  local f
  # shellcheck disable=SC2086
  for f in $ROOT/$GLOB; do
    [ -f "$f" ] || continue
    files=$((files+1))
    local rel="${f#$ROOT/}"
    # 形状内：`D-G<digits>`
    while IFS=: read -r ln id; do
      [ -n "$id" ] || continue
      ids=$((ids+1))
      if ! grep -qxF "$id" <<< "$declared"; then
        bad="$bad
  $rel:$ln id=$id（**报告里写了、declared 集里没有** ⇒ 该号没入册）"
      fi
    done <<< "$(grep -noE "\b$IDRE\b" "$f" 2>/dev/null || true)"
    # 形状外（**如实上屏**，不判）：带段后缀／通配写法的 D-* 形态
    while IFS=: read -r ln id; do
      [ -n "$id" ] || continue
      # ⚠️ **不许**用 `case` 拿 `$IDRE` 当 glob 比（`+` 是字面量 ⇒ `D-G1` 会全部被判成"形状外"，本件首版现场）。
      if [[ "$id" =~ ^D-G[0-9]+$ ]]; then continue; fi
      outshape="$outshape $id"
    done <<< "$(grep -noE '\bD-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*\b' "$f" 2>/dev/null || true)"
  done
  if [ "$files" -eq 0 ]; then
    echo "REPORTID=NOINFO reason=empty-corpus glob=$GLOB（**零检查不许给 PASS**）"
    return $RC_NOINFO
  fi
  local oshape; oshape="$(printf '%s\n' $outshape | sort -u | tr '\n' ' ')"
  [ -n "$oshape" ] && echo "REPORTID_OUT_OF_SHAPE ids=$oshape（本牙形态只吃 \`$IDRE\` ⇒ 这些**不被本牙判**，如实划界）"
  # ── 第二条判据：`book-entry-required.tsv` 的编号必须「在册 ∧ 册内有条目」 ──────────────
  local book="$ROOT/src/Linux/samples/WpfFeatureProbe/KNOWN-DEFECTS.md" req_t="$ROOT/src/Linux/build/MilBridge/book-entry-required.tsv"
  local nreq=0 npres=0 rmiss='' other_missing=''
  if [ -r "$book" ] && [ -r "$req_t" ]; then
    while IFS=$'\t' read -r rid why; do
      case "$rid" in ''|'#'*|id) continue ;; esac
      nreq=$((nreq+1))
      local ok=1
      grep -qxF "$rid" <<< "$declared" || { ok=0; rmiss="$rmiss
  $rid rule=book-entry-not-declared（要求成条，但它不在 declared 集里）"; }
      # **条目形态**：`^#{2,4}.*` 且该行**含有该编号且其后不是数字**（`D-G1` 不会匹配到 `D-G10`）
      #   ⚠️ **不许**在双引号里写反引号去匹配"被反引号包着的编号"：`\\\`` 会被 bash 解析成**命令替换**、正则当场被吃坏（本件首版现场，`bash -n` 还照样过）。
      grep -qE "^#{2,4}.*(^|[^0-9A-Za-z-])$rid([^0-9]|$)" "$book" || { ok=0; rmiss="$rmiss
  $rid rule=book-entry-heading-missing（册里没有条目形态标题）"; }
      grep -qF "$rid" "$book" || { ok=0; rmiss="$rmiss
  $rid rule=book-entry-mention-missing（册里一次都没出现）"; }
      [ "$ok" = 1 ] && npres=$((npres+1))
    done < "$req_t"
    # 已登记缺口（**可见不判红**）：declared 里 `req` 含 KD 但册内无条目形态的编号
    local kdid; kdid="$(awk -F'\t' '$1=="ID" && $3 ~ /KD/{print $2}' "$DECL" 2>/dev/null | sort -u)"
    local i
    for i in $kdid; do
      grep -qE "^#{2,4}.*(^|[^0-9A-Za-z-])$i([^0-9]|$)" "$book" || { grep -qxF "$i" <(cut -f1 "$req_t" 2>/dev/null) || other_missing="$other_missing $i"; }
    done
    [ -n "$other_missing" ] && echo "BOOK_ENTRY_UNREQUIRED_MISSING n=$(printf '%s\n' $other_missing | grep -c .) ids=$(printf '%s\n' $other_missing | tr "\n" " ")（**已登记的缺口：可见、不判红**）"
    echo "BOOK_ENTRY_BINDING required=$nreq present=$npres missing=$(printf '%s\n' "$rmiss" | grep -c .)"
    if [ "$nreq" -eq 0 ]; then
      echo "BOOK_ENTRY_BINDING=NOINFO reason=required-list-empty（清单为空 ⇒ **不许用"清空清单"关掉这条判据**）"
      bind_noinfo=1
    fi
    [ -n "$rmiss" ] && { [ -n "$bad" ] || bad=X; bad="$bad$rmiss"; }
  else
    echo "BOOK_ENTRY_BINDING=NOINFO reason=book-or-required-list-absent book=$book list=$req_t（**算不出来 ⇒ 不许当绿**）"
    bind_noinfo=1
  fi
  if [ -n "$bad" ]; then
    printf 'REPORTID=FAIL%s\n' "$bad"
    echo "REPORTID_SCAN files=$files ids=$ids declared=$(printf '%s\n' "$declared" | wc -l) glob=$GLOB"
    return $RC_FAIL
  fi
  if [ "${bind_noinfo:-0}" = 1 ]; then
    echo "REPORTID=NOINFO reason=book-entry-binding-uncomputable（编号域本身过了，但绑定判据算不出来 ⇒ **不许当绿**）"
    echo "REPORTID_SCAN files=$files ids=$ids declared=$(printf '%s\n' "$declared" | wc -l) glob=$GLOB"
    return $RC_NOINFO
  fi
  echo "REPORTID=PASS files=$files ids=$ids declared=$(printf '%s\n' "$declared" | wc -l) glob=$GLOB"
  return $RC_PASS
}

selftest() {
  local T; T="$(mktemp -d "${TMPDIR:-/tmp}/ridst.XXXXXX")" || return $RC_NOINFO
  trap 'rm -rf "$T"' RETURN
  local npass=0 nfail=0 out rc
  arm() { if [ "$2" = "1" ]; then echo "SELFTEST $1 OK :: $3"; npass=$((npass+1)); else echo "SELFTEST $1 **FAIL** :: $3"; nfail=$((nfail+1)); fi; }
  mkdir -p "$T/src/Linux/build/MilBridge/tools"
  printf 'ID\tD-G1\treq=-\tpresent=-\nID\tD-G2\treq=-\tpresent=-\n' > "$T/src/Linux/build/MilBridge/tools/defect-registry-declared.tsv"
  mkdir -p "$T/src/Linux/samples/WpfFeatureProbe"
  printf '# 册\n### `D-G1`\n- fixture\n### `D-G2`\n- fixture\n' > "$T/src/Linux/samples/WpfFeatureProbe/KNOWN-DEFECTS.md"
  printf 'id\twhy\nD-G1\tfixture\n' > "$T/src/Linux/build/MilBridge/book-entry-required.tsv"
  # S1 正极：报告只写已入册的号 ⇒ PASS
  printf '# 报告\n见 `D-G1` 与 `D-G2`。\n' > "$T/src/Linux/build/MilBridge/W1-report.md"
  set +e; out="$(bash "$SELF" --root "$T" 2>&1)"; rc=$?; set -e
  arm S1 "$([ "$rc" = "0" ] && echo 1 || echo 0)" "只写已入册号 ⇒ PASS（rc=$rc）"
  # S2 反极：报告写了**未入册**的号 ⇒ FAIL 并点名 file:line:id
  printf '# 报告\n见 `D-G1` 与 `D-G999`。\n' > "$T/src/Linux/build/MilBridge/W2-report.md"
  set +e; out="$(bash "$SELF" --root "$T" 2>&1)"; rc=$?; set -e
  arm S2 "$([ "$rc" = "1" ] && grep -q 'W2-report.md:2 id=D-G999' <<< "$out" && echo 1 || echo 0)" "未入册号 ⇒ FAIL 并点名 file:line:id（rc=$rc）"
  rm -f "$T/src/Linux/build/MilBridge/W2-report.md"
  # S3 反极：declared 集缺失 ⇒ NOINFO（不算绿）
  set +e; out="$(bash "$SELF" --root "$T" --decl "$T/none" 2>&1)"; rc=$?; set -e
  arm S3 "$([ "$rc" = "3" ] && echo 1 || echo 0)" "declared 缺席 ⇒ NOINFO（rc=$rc）"
  # S4 NOINFO 边：语料为空 ⇒ NOINFO
  mv "$T/src/Linux/build/MilBridge/W1-report.md" "$T/W1-report.md"
  set +e; out="$(bash "$SELF" --root "$T" 2>&1)"; rc=$?; set -e
  arm S4 "$([ "$rc" = "3" ] && grep -q 'empty-corpus' <<< "$out" && echo 1 || echo 0)" "空语料 ⇒ NOINFO（零检查不许给 PASS，rc=$rc）"
  # S5 形状外如实上屏：带段后缀的号**不判**（射程缺口可见）
  printf '# 报告\n见 `D-G1` 与 `D-T2-b`。\n' > "$T/src/Linux/build/MilBridge/W3-report.md"
  set +e; out="$(bash "$SELF" --root "$T" 2>&1)"; rc=$?; set -e
  arm S5 "$([ "$rc" = "0" ] && grep -q 'REPORTID_OUT_OF_SHAPE' <<< "$out" && echo 1 || echo 0)" "形状外号 ⇒ PASS ＋ **上屏** REPORTID_OUT_OF_SHAPE（rc=$rc）"
  # S6 反极（**主控点名的那条腿**）：**把册内一条删掉**（declared 集里去掉 D-G1），
  #    而报告仍写着它 ⇒ 必红并**点名 D-G1**（这就是"删掉册内一条 ⇒ 必红"）。
  printf 'ID\tD-G2\treq=-\tpresent=-\n' > "$T/src/Linux/build/MilBridge/tools/defect-registry-declared.tsv"
  printf '# 报告\n见 `D-G1` 与 `D-G2`。\n' > "$T/src/Linux/build/MilBridge/W4-report.md"
  rm -f "$T/src/Linux/build/MilBridge/W3-report.md"
  set +e; out="$(bash "$SELF" --root "$T" 2>&1)"; rc=$?; set -e
  arm S6 "$([ "$rc" = "1" ] && grep -q 'W4-report.md:2 id=D-G1' <<< "$out" && echo 1 || echo 0)" "**册内删掉一条**（declared 去 D-G1）⇒ FAIL 并点名 D-G1（rc=$rc）"
  # S7 反极：`book-entry-required.tsv` 要求的编号**册里没有条目** ⇒ FAIL 并点名
  printf 'ID\tD-G1\treq=-\tpresent=-\nID\tD-G2\treq=-\tpresent=-\n' > "$T/src/Linux/build/MilBridge/tools/defect-registry-declared.tsv"
  printf '# 报告\n见 `D-G1` 与 `D-G2`。\n' > "$T/src/Linux/build/MilBridge/W4-report.md"
  mkdir -p "$T/src/Linux/samples/WpfFeatureProbe"
  printf '# 册\n### `D-G2`\n- fixture\n' > "$T/src/Linux/samples/WpfFeatureProbe/KNOWN-DEFECTS.md"
  printf 'id\twhy\nD-G1\tfixture(no-entry-in-book)\n' > "$T/src/Linux/build/MilBridge/book-entry-required.tsv"
  set +e; out="$(bash "$SELF" --root "$T" 2>&1)"; rc=$?; set -e
  arm S7 "$([ "$rc" = "1" ] && grep -q 'book-entry-heading-missing\|book-entry-mention-missing' <<< "$out" && echo 1 || echo 0)" "要求成条而册里没条目 ⇒ FAIL 并点名（rc=$rc）"
  echo "REPORTID_SELFTEST=$([ "$nfail" = 0 ] && echo PASS || echo FAIL) cases=$((npass+nfail)) pass=$npass fail=$nfail"
  [ "$nfail" = 0 ] && return $RC_PASS || return $RC_FAIL
}

if [ "$MODE" = "selftest" ]; then selftest; else run_check; fi
