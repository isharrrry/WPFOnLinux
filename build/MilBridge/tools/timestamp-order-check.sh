#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# timestamp-order-check.sh —— 「文内 dated 戳 ≤ 该行**首次入册**的提交时刻」牙
#   （`t27`／V2 收口；归族 `D-G176`（跨会话第 `18` 条）；**本波不接线** —— 接线归 W4）
⏪ **dated 更正（`t48`／W4b，读时 2026-09-28T17:47:04.418+0800）**：**已接线**：`verify-all.sh` 步名 `TS-ORDER`（`run_step "TS-ORDER" bash build/MilBridge/tools/timestamp-order-check.sh`）＋ **覆盖面已计入**（`build/close-wave.sh` 的 `fp_inputs()`；现取件数 **233**）⇒ 上一行的「接线归 W4」**自此过期**（**原句一字未删**，以本行为准）。
#
# 【它挡的是什么】本仓 dated 追加纪律要求「读时戳必须早于落盘」。`t70` 立的是**秒级**规则；
#   本仓**已第二次**撞上它的下一格洞：**秒级戳与落盘落在同一秒 ⇒ 先后不可判**
#   （**例①** `t16` 的 F 批：戳 `16:08:26+0800` vs 两件 `mtime 16:08:26.445176624`／`.448176612`；
#   **例②** `t18` 的 I 批：戳 `16:10:48+0800` vs `mtime 16:10:48.905708995`）。
#   ⇒ 本牙把这一族变成机读判据，两条腿：
#     ① **上界腿**：戳 ≤ 该行**首次入册**那一刻（**提交时刻 ＝ 落盘的可证上界**）；
#     ② **对拍腿**：戳 ≤ 该件**落盘 `mtime`**；且**必须能分辨先后** —— 戳无亚秒且与 `mtime` **同秒** ⇒ 不可对拍。
#
# 【命令原文（「首次入册」怎么取 · 可复算）】
#   键 ＝ 该行**整行原文**（唯一子串；整行取不到再退化为该行里那个戳字符串）：
#     git -C <root> log -S"<整行原文>" --format=%cI -- <件> | tail -1     # 最早那笔 ＝ 首次入册
#   等价替代（只看新增）：git -C <root> log --diff-filter=A --format=%cI -- <件>
#   按提交号取时刻：     git -C <root> show -s --format=%cI <sha>
#   ⚠️ 取不到任何提交 ＝ 该行**尚未入册**（工作树脏／新件）⇒ **`NOINFO`**（不许静默判等）。
#
# ⏪ **dated 修（`t33`，读时 2026-09-28T16:37:08.696+0800；`D-G183`（由 `t28` 发现、队长配号）＋`V-4`）**：
#   ① **扫描域收窄**：只判「**该行自身的戳**」—— 戳前那一段（去空白／`*`／反引号／标点后）**必须以自证标记收尾**
#      （`读时`／`读取时刻`／`读取`／`落盘`／`提交时刻`／`dated`／`ts=`）；**引用/引证文本里的戳**（如引夹具的未来戳）
#      一律**不判**且**逐条上屏**（`TSORDER_QUOTED`）⇒ 修前对 `build/MilBridge/P1-v-close-report.md:52`（**已提交、干净**）
#      的那处**假红** `rc=1` 不复现；**红线**：该件的**引证现场一字不改**（真缺陷现场留在册）。
#   ② **`NOINFO` 的 reason 不许被吃掉**（`V-4`）：件不存在 ⇒ `file-absent`；只有引用戳 ⇒ `no-self-stamps`；
#      **只有「语料里根本没有戳」**才 ⇒ `no-stamps`。
#
# 【判据（先写死；三态；`NOINFO` 不算绿）】
#   rc=0 `TSORDER=PASS`    语料非空 ∧ 每一条**自证戳**都能对拍且不晚于首次入册（引用戳**不判**、只上屏）
#   rc=1 `TSORDER=FAIL`    存在**戳晚于首次入册**或**晚于 `mtime`** 的行 ⇒ **逐行点名**（件＋行＋两时刻＋差）
#   rc=3 `TSORDER=NOINFO`  算不出：无戳语料／该行未入册／**同秒不可对拍**／件不存在／语料为空
#   rc=4                   用法错
#
# 【口径（永久）】「**秒级不够**：读时戳与落盘时刻**同秒即不可对拍** ⇒ 必须给**亚秒（毫秒级）**戳，
#   或让写入**落下一秒**。」⇒ 本牙对「戳无亚秒 ∧ 与 `mtime` 同秒」一律 `NOINFO(同秒不可对拍)`，**不判绿**。
#
# 【测试钩子】`--selftest`（自带 fixture，零网络、不依赖真仓状态）；
#   `--assume-first-commit <ISO>` 在**没有提交历史**时显式喂入「首次入册时刻」（夹具／沙箱用；
#   真树判据一律走 `git log -S` —— 该钩子只换输入、**不换判据**）。
#   `S1`–`S5` 原有五臂；`t33` 新增 **`S6`**（**引用夹具未来戳 ＋ 本行有自证戳 ⇒ 不许红**）、**`S7`**（**只有引用戳 ⇒ `NOINFO(no-self-stamps)`，不许红**）、**`S8`**（件不存在 ⇒ `reason` 含 `file-absent`）。
#
# 【用法】bash timestamp-order-check.sh [--file <件>]… [--assume-first-commit ISO] [--selftest]
#   缺省语料（现取）＝ `build/MilBridge/P1-w1-close-verify.md`（已提交、干净、全戳可对拍）。
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="$(cd -- "$SELF_DIR/../../.." && pwd)"
RC_PASS=0; RC_FAIL=1; RC_NOINFO=3; RC_USAGE=4

DEFAULT_FILES=("build/MilBridge/P1-w1-close-verify.md")
FILES=(); ASSUME=""; MODE="check"
while [ $# -gt 0 ]; do
  case "$1" in
    --file) FILES+=("${2:-}"); shift 2 ;;
    --assume-first-commit) ASSUME="${2:-}"; shift 2 ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) echo "用法: timestamp-order-check.sh [--file <件>]… [--assume-first-commit ISO] [--selftest]"; exit $RC_PASS ;;
    *) echo "TSORDER=FAIL reason=usage:unknown-arg $1"; exit $RC_USAGE ;;
  esac
done
[ "$MODE" = "selftest" ] || [ "${#FILES[@]}" -gt 0 ] || FILES=("${DEFAULT_FILES[@]}")

# 戳语法（两种形态；亚秒可选）：T 形 `2026-09-28T16:08:26+0800`／空格形 `2026-09-28 16:08:26 +0800`
STAMPRE='[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{1,9})?([ ]?[+-][0-9]{4}|Z)?'

epoch_of() { date -d "$1" +%s 2>/dev/null; }

first_commit_iso() {  # $1=件（相对或绝对） $2=整行原文
  git -C "$ROOT" log -S"$2" --format=%cI -- "$1" 2>/dev/null | tail -1
}

check_file() {   # ⇒ 回 rc；累积量写进全局
  local spec="$1" abs rel self_abs
  case "$spec" in /*) abs="$spec"; rel="${spec#$ROOT/}" ;; *) abs="$ROOT/$spec"; rel="$spec" ;; esac
  if [ ! -f "$abs" ]; then
    echo "TSORDER_NOFILE file=$rel（件不存在 ⇒ 不判）"; NOINFO_REASONS="$NOINFO_REASONS,file-absent"; return $RC_NOINFO
  fi
  self_abs="$SELF_DIR/$(basename -- "$SELF")"
  if [ "$(cd -- "$(dirname -- "$abs")" && pwd)/$(basename -- "$abs")" = "$self_abs" ]; then
    echo "TSORDER_SELF_SKIP file=$rel reason=detector-itself（自跳过，**上屏**；不影响判词）"; return $RC_PASS
  fi
  local msec musec; msec="$(stat -c %Y "$abs" 2>/dev/null)"; musec="$(stat -c %y "$abs" 2>/dev/null | cut -d' ' -f2)"
  local n=0 stamps=0 nlines=0 self=0
  local line st sec fsec sub nmax=0 nmin=0
  while IFS= read -r line; do
    n=$((n+1))
    local found; found="$(printf '%s' "$line" | grep -oE "$STAMPRE" || true)"
    [ -n "$found" ] || continue
    nlines=$((nlines+1)); local rest="$line"
    while IFS= read -r st; do
      [ -n "$st" ] || continue
      stamps=$((stamps+1))
      # ⏪ dated 修（`t33`，读时 2026-09-28T16:37:08.696+0800；`D-G183`）：**只判「该行自身的戳」** —— 戳前那一段（去空白／`*`／反引号／标点）
      #   必须**以自证标记收尾**；**引用/引证文本里的戳一律不判**并**逐条上屏**（`TSORDER_QUOTED`）。
      local pre="${rest%%"$st"*}"
      rest="${rest#*"$st"}"
      local tail; tail="$(printf '%s' "$pre" | sed 's/[[:space:]*`：:，,=（(]*$//')"
      case "$tail" in
        *读时|*读取时刻|*读取|*落盘|*提交时刻|*dated|*ts=) : ;;
        *) QUOTED=$((QUOTED+1))
           echo "TSORDER_QUOTED file=$rel:$n stamp=$st（**引用/引证**文本里的戳（前缀未以自证标记收尾）⇒ **不判**，上屏）"
           continue ;;
      esac
      case "$st" in *.*) sub="ms" ;; *) sub="none" ;; esac
      self=$((self+1))
      sec="$(epoch_of "$st")"
      if [ -z "$sec" ]; then
        echo "TSORDER_UNPARSABLE file=$rel:$n stamp=$st（`date -d` 解不出 ⇒ 不判）"
        NOINFO_REASONS="$NOINFO_REASONS,unparsable"; NOINFO_HIT=1; continue
      fi
      local first="$ASSUME"
      local src="assume"
      if [ -z "$first" ]; then
        src="gitlog"
        first="$(first_commit_iso "$rel" "$line")"
        [ -n "$first" ] || first="$(first_commit_iso "$rel" "$st")"
      fi
      if [ -z "$first" ]; then
        echo "TSORDER_NOCOMMIT file=$rel:$n stamp=$st（该行**取不到首次入册**：工作树脏／新件／无历史 ⇒ 不可判）"
        NOINFO_REASONS="$NOINFO_REASONS,no-first-commit"; NOINFO_HIT=1; continue
      fi
      fsec="$(epoch_of "$first")"
      [ -n "$fsec" ] || { echo "TSORDER_NOCOMMIT file=$rel:$n first_commit=$first（提交时刻解不出）"; NOINFO_REASONS="$NOINFO_REASONS,unparsable-commit"; NOINFO_HIT=1; continue; }
      echo "TSORDER_STAMP file=$rel:$n stamp=$st sub=$sub first_commit=$first src=$src delta=$((sec-fsec))s"
      [ "$sec" -gt "$fsec" ] && {
        FUTURE_HIT=1
        echo "TSORDER_FUTURE file=$rel:$n stamp=$st first_commit=$first delta=+$((sec-fsec))s（戳**晚于首次入册** ⇒ 必红并点名）"
      }
      [ "$sec" -eq "$fsec" ] && {
        NOINFO_REASONS="$NOINFO_REASONS,same-second-as-first-commit"; NOINFO_HIT=1
        echo "TSORDER_SAMESEC file=$rel:$n stamp=$st first_commit=$first（**同秒** ⇒ 先后不可判）"
      }
      if [ -n "$msec" ]; then
        if [ "$sec" -gt "$msec" ]; then
          FUTURE_HIT=1
          echo "TSORDER_FUTURE file=$rel:$n stamp=$st mtime=$musec delta=+$((sec-msec))s（戳**晚于落盘** ⇒ 必红并点名）"
        elif [ "$sec" -eq "$msec" ] && [ "$sub" = "none" ]; then
          NOINFO_REASONS="$NOINFO_REASONS,same-second-as-mtime"; NOINFO_HIT=1
          echo "TSORDER_SAMESEC file=$rel:$n stamp=$st mtime=$musec（戳无亚秒 ∧ 与落盘**同秒** ⇒ **不可对拍**）"
        fi
      fi
    done <<< "$found"
  done < "$abs"
  NFILES=$((NFILES+1)); NLINES=$((NLINES+nlines)); NSTAMPS=$((NSTAMPS+stamps)); NSELF=$((NSELF+self)); NQUOTED=$((NQUOTED+QUOTED))
  if [ "$stamps" -gt 0 ] && [ "$self" -eq 0 ]; then
    NOINFO_REASONS="$NOINFO_REASONS,no-self-stamps"; NOINFO_HIT=1
    echo "TSORDER_NOSELF file=$rel（本件**只有引用戳、零自证戳** ⇒ 判不了 ⇒ **不判绿**）"
  fi
  echo "TSORDER_SCAN file=$rel lines=$n lines_with_stamp=$nlines stamps=$stamps self=$self quoted=$QUOTED mtime=$musec"
  return $RC_PASS
}

run_check() {
  FUTURE_HIT=0; NOINFO_HIT=0; NOINFO_REASONS=""
  NFILES=0; NLINES=0; NSTAMPS=0; NSELF=0; NQUOTED=0; QUOTED=0
  local f rc
  for f in "${FILES[@]}"; do check_file "$f"; rc=$?; [ "$rc" -gt "$RC_PASS" ] && NOINFO_HIT=1; done
  if [ "$FUTURE_HIT" = 1 ]; then
    echo "TSORDER=FAIL reason=future-stamp files=$NFILES stamped_lines=$NLINES stamps=$NSTAMPS"
    return $RC_FAIL
  fi
  # ⏪ dated 修（`t33`，读时 2026-09-28T16:37:08.696+0800；`D-G183`／`V-4`）：**先报 `NOINFO` 的真因**（件不存在／无自证戳／未入册／同秒）；
  #   只有「语料里**根本没有戳**」才给 `reason=no-stamps` ⇒ **原因名不许被吃掉**。
  if [ "$NOINFO_HIT" = 1 ]; then
    echo "TSORDER=NOINFO reason=${NOINFO_REASONS#,} files=$NFILES stamped_lines=$NLINES stamps=$NSTAMPS self=$NSELF quoted=$NQUOTED（不可判／不可对拍者已逐条上屏；**NOINFO 不算绿**）"
    return $RC_NOINFO
  fi
  if [ "$NSTAMPS" -eq 0 ]; then
    echo "TSORDER=NOINFO reason=no-stamps files=$NFILES（**语料里没有任何戳** ⇒ 零检查不许给 PASS）"
    return $RC_NOINFO
  fi
  echo "TSORDER=PASS files=$NFILES stamped_lines=$NLINES stamps=$NSTAMPS self=$NSELF quoted=$NQUOTED（**自证戳**均 ≤ 其行首次入册时刻 ∧ 可对拍；引用戳不判）"
  return $RC_PASS
}

selftest() {
  local T; T="$(mktemp -d "${TMPDIR:-/tmp}/tsoc.XXXXXX")" || return $RC_NOINFO
  trap 'rm -rf "${T:-}"' RETURN
  local npass=0 nfail=0 out rc
  arm() { if [ "$2" = "1" ]; then echo "SELFTEST $1 OK :: $3"; npass=$((npass+1)); else echo "SELFTEST $1 **FAIL** :: $3"; nfail=$((nfail+1)); fi; }
  local OLD="2020-01-01T00:00:00.123+0800"
  local FUT; FUT="$(date -d '+2 years' +%Y)-01-01T00:00:00.000+0800"   # 未来戳：**不写字面值**，免自伤
  # S1 正极：过去戳 ＋ 显式喂入首次入册 ⇒ PASS
  printf '⏪ dated 追加（t27，读时 %s）\n' "$OLD" > "$T/ok.md"
  set +e; out="$(bash "$SELF" --file "$T/ok.md" --assume-first-commit '2026-09-28T16:40:00+08:00' 2>&1)"; rc=$?; set -e
  arm S1 "$([ "$rc" = "0" ] && grep -q 'TSORDER=PASS' <<< "$out" && echo 1 || echo 0)" "过去戳 ⇒ PASS（rc=$rc）"
  # S2 反极：伪造**未来戳** ⇒ 必红并点名（件＋行）
  printf '⏪ dated 追加（t27，读时 %s）\n尾行\n' "$FUT" > "$T/bad.md"
  set +e; out="$(bash "$SELF" --file "$T/bad.md" --assume-first-commit '2026-09-28T16:40:00+08:00' 2>&1)"; rc=$?; set -e
  arm S2 "$([ "$rc" = "1" ] && grep -q 'TSORDER_FUTURE' <<< "$out" && grep -q 'bad.md:1' <<< "$out" && echo 1 || echo 0)" "伪造未来戳 ⇒ FAIL 点名 file:line（rc=$rc）"
  # S3 同秒 ⇒ NOINFO（不许判绿）
  printf '⏪ dated 追加（t27，读时 2020-01-01T00:00:00+0800）\n' > "$T/same.md"
  set +e; out="$(bash "$SELF" --file "$T/same.md" --assume-first-commit '2020-01-01T00:00:00+08:00' 2>&1)"; rc=$?; set -e
  arm S3 "$([ "$rc" = "3" ] && grep -q 'same-second' <<< "$out" && echo 1 || echo 0)" "戳与首次入册**同秒** ⇒ NOINFO（rc=$rc）"
  # S4 无历史、未喂入 ⇒ NOINFO
  set +e; out="$(bash "$SELF" --file "$T/ok.md" 2>&1)"; rc=$?; set -e
  arm S4 "$([ "$rc" = "3" ] && grep -q 'no-first-commit' <<< "$out" && echo 1 || echo 0)" "取不到首次入册 ⇒ NOINFO(no-first-commit)（rc=$rc）"
  # S5 零戳语料 ⇒ NOINFO（零检查不许给 PASS）
  printf '无戳行\n' > "$T/none.md"
  set +e; out="$(bash "$SELF" --file "$T/none.md" 2>&1)"; rc=$?; set -e
  arm S5 "$([ "$rc" = "3" ] && grep -q 'no-stamps' <<< "$out" && echo 1 || echo 0)" "零戳语料 ⇒ NOINFO(no-stamps)（rc=$rc）"
  # S6 反极（`D-G183`）：**引用夹具未来戳 ＋ 本行有自证戳** ⇒ **不许红**
  printf '⏪ 反极（伪造未来戳）：沙箱把戳改成 %s（**引用**，不是本行的自证戳）\n⏪ dated 追加（t33，读时 2020-01-01T00:00:00.123+0800）\n' "$FUT" > "$T/quoted.md"
  set +e; out="$(bash "$SELF" --file "$T/quoted.md" --assume-first-commit '2026-09-28T16:40:00+08:00' 2>&1)"; rc=$?; set -e
  arm S6 "$([ "$rc" = "0" ] && grep -q 'TSORDER=PASS' <<< "$out" && grep -q 'TSORDER_QUOTED' <<< "$out" && echo 1 || echo 0)" "**引用**夹具未来戳 ＋ 有自证戳 ⇒ **不许红**（rc=$rc）"
  # S7 反极：**只有引用戳**（含未来戳）⇒ NOINFO(no-self-stamps)，不许红
  printf '⏪ 反极：沙箱把戳改成 %s（**引用**；全件没有自证戳）\n' "$FUT" > "$T/onlyquoted.md"
  set +e; out="$(bash "$SELF" --file "$T/onlyquoted.md" 2>&1)"; rc=$?; set -e
  arm S7 "$([ "$rc" = "3" ] && grep -q 'no-self-stamps' <<< "$out" && echo 1 || echo 0)" "只有引用戳 ⇒ NOINFO(no-self-stamps)（rc=$rc）"
  # S8 V-4：件不存在 ⇒ 聚合句 reason 反映真因（file-absent）
  set +e; out="$(bash "$SELF" --file "$T/absent-file.md" 2>&1)"; rc=$?; set -e
  arm S8 "$([ "$rc" = "3" ] && grep -q 'reason=file-absent' <<< "$out" && echo 1 || echo 0)" "件不存在 ⇒ NOINFO(reason=file-absent)（rc=$rc）"
  echo "TSORDER_SELFTEST=$([ "$nfail" = 0 ] && echo PASS || echo FAIL) cases=$((npass+nfail)) pass=$npass fail=$nfail"
  [ "$nfail" = 0 ] && return $RC_PASS || return $RC_FAIL
}

if [ "$MODE" = "selftest" ]; then selftest; else run_check; fi
