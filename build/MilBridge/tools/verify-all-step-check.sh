#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# verify-all-step-check.sh —— `D-G22` 的「自指牙齿」草稿（**只读**）
#
# 【要解决的缺口】`#27` 一趟里 `verify-all.sh` 被改了 5 次、**全程零机器红**
#   ⇒ 「顶层结论本身没有牙齿」。本件给**步名集合 / 步数 / 头注释口径句**三件
#   一个每趟都跑的机器读者。
#
# 【判据（三件，缺一即不许绿）】
#   ① **步名多重集合**：`^run_step "NAME"` 抽出的 NAME 多重集合 == 声明里列出的多重集合
#      （**不只是个数**：删一步＋加一步会让个数不变而集合变）
#   ② **步数**：抽出条数 == `VERIFYALL-STEPS-DECL:` 的数，且该数 == 声明里列出的名字个数
#   ③ **头注释口径句**：头注释里必须有「**`<gen>` 收官起 = <N> 步**」且 `<N>` == 现场条数
#   ＋ ④ **无重名**（多重集合相等仍可能有两步同名 —— 见 `--selftest dup-consistent`）
#   ＋ ⑤ **顺序一致**（门禁步骤顺序有语义：构建在前、判据在后）
#
# 【三态（铁律：`NOINFO` 不许当绿、也不该冒充红）】
#   rc=0  `VERIFYALL_SELF=PASS`   三件全对
#   rc=1  `VERIFYALL_SELF=FAIL`   **声明存在但与现场分叉**（点名分叉在哪）
#   rc=2  `VERIFYALL_SELF=NOINFO` **缺声明**（缺 `DECL` / 缺 `STEP-NAMES` / 缺口径句）
#   ⇒ 在 `run_step` 里 `rc≠0` 一律是 `❌`（`NOINFO` 也只是"另一种红"），
#     但结论区那行 `VERIFYALL_SELF=… reason=…` 会把"缺声明"与"分叉"分开 ——
#     **不许**把 `NOINFO` 读成"这一步没判"，更不许读成绿。
#
# 【本件是纯读者】全文**没有一处写** `verify-all.sh`（`--selftest` 也只写 `mktemp -d`
#   沙箱里的 **`cp -p` 真副本**）。自指不动点修法（让判据改写自己）**不做**。
#
# 用法：
#   bash build/MilBridge/tools/verify-all-step-check.sh [--file PATH] [--trace LOG] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
ROOT="$(cd "$(dirname "$SELF")/../../.." && pwd)"
VFILE="$ROOT/verify-all.sh"
TRACE=""
SELFTEST=0

usage() {
  sed -n '2,40p' "$SELF" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --file)     VFILE="$2"; shift 2 ;;
    --file=*)   VFILE="${1#*=}"; shift ;;
    --trace)    TRACE="$2"; shift 2 ;;
    --trace=*)  TRACE="${1#*=}"; shift ;;
    --selftest) SELFTEST=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "VERIFYALL_SELF=NOINFO reason=bad-usage arg=$1" >&2; exit 2 ;;
  esac
done

sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }

# ── 抽取现场步名（**唯一**的现场口径；与 `verify-all.sh:15` 自称的机器证同一正则）────
#   ⚠️ 锚 `^run_step "` 是**故意的**：
#     * 不带锚会数到函数定义与注释（`#27` 实测差额**不是常数** ⇒ 别引用任何写死差额）；
#     * 缩进的 `run_step`、被注释掉的 `# run_step`、换成别的函数名的调用 ⇒ **都不计入**，
#       因而一旦声明里的集合与它不等就红。这是判据，不是缺陷。
extract_names() {
  sed -n 's/^run_step "\([^"]*\)".*/\1/p' "$1"
}

# ── 读声明（三行机器读注释；**缺一行 ⇒ NOINFO**，不许推断）─────────────────────
#   `# VERIFYALL-STEPS-DECL: 16 gen=#27`
#   `# VERIFYALL-STEP-NAMES: 名1 | 名2 | … | 名N`
decl_line()  { sed -n 's/^#[[:space:]]*VERIFYALL-STEPS-DECL:[[:space:]]*//p' "$1" | head -1; }
names_line() { sed -n 's/^#[[:space:]]*VERIFYALL-STEP-NAMES:[[:space:]]*//p' "$1" | head -1; }

report_noinfo() {  # report_noinfo <reason> <extra...>
  local why="$1"; shift
  echo "VERIFYALL_SELF=NOINFO reason=$why $*"
  echo "  ∟ 缺声明 ⇒ **不许当绿**（铁律）；请在 \`verify-all.sh\` 头注释补上对应声明行"
  exit 2
}

run_checks() {  # run_checks <file> ⇒ 印结论行，rc=0/1/2
  local f="$1"
  local -a fails=()

  # 缺件：无文件 = NOINFO（不是 FAIL —— 没东西可比）
  [ -f "$f" ] || report_noinfo file-absent "file=$f"

  local obs; obs="$(extract_names "$f")"
  local n_obs; n_obs="$(printf '%s\n' "$obs" | grep -c . || true)"

  local dline; dline="$(decl_line "$f")"
  [ -n "$dline" ] || report_noinfo decl-absent "file=$f"

  local n_decl gen_decl
  n_decl="$(printf '%s' "$dline" | sed -n 's/^\([0-9]\{1,\}\).*/\1/p')"
  gen_decl="$(printf '%s' "$dline" | sed -n 's/.*gen=\([^ ]*\).*/\1/p')"
  case "$n_decl" in
    ''|*[!0-9]*) report_noinfo decl-unparsable "decl_line=$dline" ;;
  esac

  local nline; nline="$(names_line "$f")"
  [ -n "$nline" ] || report_noinfo names-absent "file=$f"
  # 拆 ` | `（FOO|BAR 也认，宽松拆法只影响声明件的写法，不影响判据强度）
  local -a dnames=()
  local IFS_SAVE="$IFS"; IFS='|'
  local -a raw=(); read -r -a raw <<< "$nline"
  IFS="$IFS_SAVE"
  local tok
  for tok in "${raw[@]}"; do
    tok="${tok#"${tok%%[![:space:]]*}"}"      # ltrim
    tok="${tok%"${tok##*[![:space:]]}"}"      # rtrim
    [ -n "$tok" ] && dnames+=("$tok")
  done
  [ "${#dnames[@]}" -gt 0 ] || report_noinfo names-empty "file=$f"

  local -a onames=()
  while IFS= read -r tok; do [ -n "$tok" ] && onames+=("$tok"); done <<< "$obs"

  # ② 声明自洽：数 == 名字个数
  if [ "$n_decl" != "${#dnames[@]}" ]; then
    fails+=("decl-self-inconsistent(DECL=$n_decl 但列了 ${#dnames[@]} 个名字)")
  fi
  # ② 现场条数 == 声明数
  if [ "$n_obs" != "$n_decl" ]; then
    fails+=("count-mismatch(现场 $n_obs ≠ 声明 $n_decl)")
  fi

  # ① **多重集合**相等。⚠️ 实现用 bash 关联数组自己数，**不用 `comm`/`sort` 比**：
  #   本文件的步名含中文/`·`/全角括号，而 `comm` 按**当前 locale** 的 collation 判"是否已排序"
  #   ⇒ 实测报 `comm: 文件 1 没有被正确排序` 并把诊断当失败输出（**这是本件草稿自己的一个坑，
  #   记为"判据不许依赖 locale"**）。关联数组版本与 locale 无关，且天然是**多重**集合。
  local -A o_cnt=() d_cnt=()
  local k
  for k in "${onames[@]:-}"; do [ -n "$k" ] || continue; o_cnt["$k"]=$(( ${o_cnt["$k"]:-0} + 1 )); done
  for k in "${dnames[@]:-}"; do [ -n "$k" ] || continue; d_cnt["$k"]=$(( ${d_cnt["$k"]:-0} + 1 )); done

  local only_obs="" only_decl=""
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    [ "${d_cnt["$k"]:-0}" = "${o_cnt[$k]}" ] || only_obs="${only_obs}${k}×${o_cnt[$k]} "
  done < <(printf '%s\n' "${!o_cnt[@]}" | LC_ALL=C sort)
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    [ "${o_cnt["$k"]:-0}" = "${d_cnt[$k]}" ] || only_decl="${only_decl}${k}×${d_cnt[$k]} "
  done < <(printf '%s\n' "${!d_cnt[@]}" | LC_ALL=C sort)
  if [ -n "$only_obs" ] || [ -n "$only_decl" ]; then
    fails+=("name-set-differs(现场独有=[${only_obs:-无}] 声明独有=[${only_decl:-无}])")
  fi

  # ⑤ 顺序一致（同名同集合、换了次序也要红：门禁步骤次序有语义）
  if [ "${#onames[@]}" -eq "${#dnames[@]}" ]; then
    local i ord_diff=0
    for ((i=0; i<${#onames[@]}; i++)); do
      [ "${onames[$i]}" = "${dnames[$i]}" ] || { ord_diff=1; break; }
    done
    [ "$ord_diff" = 0 ] || fails+=("name-order-differs(第 $((i+1)) 位 现场=\"${onames[$i]}\" 声明=\"${dnames[$i]}\")")
  fi

  # ④ 无重名（**这一步独立于集合比较**：攻击者把重复名在声明里也写两遍、
  #    并把 DECL 数跟着 +1，则 ①②⑤ 全过 ⇒ 只有这条能抓）
  local dups=""
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    [ "${o_cnt[$k]}" -gt 1 ] && dups="${dups}${k}×${o_cnt[$k]} "
  done < <(printf '%s\n' "${!o_cnt[@]}" | LC_ALL=C sort)
  [ -z "$dups" ] || fails+=("duplicate-step-name($dups)")

  # ③ 头注释口径句：**`<gen>` 收官起 = <N> 步**
  local prose_ok=0
  if [ -n "$gen_decl" ]; then
    grep -qF "**\`$gen_decl\` 收官起 = $n_obs 步**" "$f" && prose_ok=1
    if [ "$prose_ok" = 0 ]; then
      if grep -qF "$gen_decl\` 收官起 = " "$f"; then
        fails+=("prose-mismatch(头注释「$gen_decl 收官起」后来跟的数 ≠ 现场 $n_obs)")
      else
        report_noinfo header-prose-absent "gen=$gen_decl 现场=$n_obs（头注释里没有「**\`$gen_decl\` 收官起 = N 步**」这半句）"
      fi
    fi
  else
    grep -qF "= $n_obs 步" "$f" && prose_ok=1
    [ "$prose_ok" = 1 ] || report_noinfo header-prose-absent "现场=$n_obs 且声明行无 gen=（找不到「= $n_obs 步」）"
  fi

  # ⑥（可选）动态轨迹：只有接线后才会有；没有 ⇒ **NOINFO，不是 PASS**
  local dyn="NOINFO"
  if [ -n "$TRACE" ] && [ -f "$TRACE" ]; then
    local traced
    traced="$(sed -n 's/.*VERIFYALL_STEPS_RUN=\([0-9]\{1,\}\).*/\1/p' "$TRACE" | tail -1)"
    if [ -n "$traced" ]; then
      if [ "$traced" = "$n_obs" ]; then dyn="OK(run=$traced)"; else
        dyn="MISMATCH(run=$traced static=$n_obs)"; fails+=("static-vs-run-mismatch(静态 $n_obs 实际跑 $traced)")
      fi
    fi
  fi

  local vsha; vsha="$(sha16 "$f")"
  if [ "${#fails[@]}" -eq 0 ]; then
  # ④c 【`#37` F3】**这一代有没有预登记节**（`#36` 的流程缺口：那一波**落地先于预登记**，
  #     而当时**零机器红** —— 整套验收里**没有任何一条牙**会问"这一代写没写预登记"）。
  #   判据：以**被测件所在目录**为仓根，扫 `docs/WAVE*-PREREGISTRATION.md` 的**标题行**里有没有本代号。
  #     三态：找到 ⇒ `PASS`（在结论行里印 `prereg=PASS`）；`docs/` 缺失 / 一件都没有 / 标题里都没有本代号
  #     ⇒ **`NOINFO`**（**缺声明 ≠ 通过**，与本件其余判据一致；也**不许冒充红**）。
  #   ⚠️ 位置**必须在"其余判据全过"的分支里**：`report_noinfo` 会**立刻 exit 2** ⇒ 若放在前面，
  #     它会把本该报 `prose-mismatch`/`duplicate-step-name` 的那些例**换一个理由**（同一个现象换个原因码，
  #     查错方向）—— 本波自测第一次跑就撞上了 17 例，现场见 `docs/WAVE37-PREREGISTRATION.md` §3.3b。
  #   ⚠️ 为什么挂在**本步**而不是新加一步：本步本来就在核"声明 ⇔ 现场"，"预登记的存在性"是同一族；
  #     新加一步要**同趟**改三处声明（`STEPS-DECL`/口径句/`STEP-NAMES` 名单）—— `#36` 刚在那上面栽过。
  #   ⚠️ 只判**本代**（`gen_decl` 取头注释那一行 = 唯一声明处），历史世代不受影响。
  local prereg="NOINFO" prereg_n=0 p
  if [ -n "$gen_decl" ]; then
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      prereg_n=$((prereg_n+1))
      # 标题行（`#`/`##`/…）里出现本代号即可；`gen_decl` 的形态已被上游约束为 `#[0-9]+` ⇒ 正则安全
      if grep -qE "^#+ .*${gen_decl}" "$p" 2>/dev/null; then prereg="PASS:$p"; break; fi
    done < <(ls -1 "$(dirname "$f")"/docs/WAVE*-PREREGISTRATION.md 2>/dev/null)
    if [ "$prereg" = "NOINFO" ]; then
      report_noinfo prereg-absent \
        "gen=$gen_decl 扫了 $prereg_n 件 docs/WAVE*-PREREGISTRATION.md，本代号没出现在任何标题行里"
    fi
  fi

    echo "VERIFYALL_SELF=PASS names=$n_obs decl=$n_decl gen=${gen_decl:-<无>} dup=0 order=OK prose=OK prereg=${prereg%%:*} dynamic_trace=$dyn vfile_sha16=$vsha"
    echo "  ∟ 步名多重集合 == 声明；声明自洽；口径句数字一致；无重名；次序一致"
    return 0
  fi
  echo "VERIFYALL_SELF=FAIL names=$n_obs decl=$n_decl gen=${gen_decl:-<无>} dynamic_trace=$dyn vfile_sha16=$vsha"
  local x
  for x in "${fails[@]}"; do echo "  ∟ $x"; done
  echo "  ∟ 现场步名（按文件次序）："
  printf '      %s\n' "${onames[@]:-<空>}"
  return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# --selftest：**反极性**。全部在 `mktemp -d` 沙箱里对 `cp -p` 真副本动手；
#   真件 sha 在开头/结尾各算一次并断言未变（**证明本件没写它**）。
#   ⚠️ 硬要求：**`cp -p` 真复制，不用 `ln`/硬链接**（本仓有车道用硬链接沙箱把真件截断过）。
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$SELFTEST" = 1 ]; then
  # ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、不许冒充红）──
  #   本件自测以 `bash "$SELF" --file …` **重入自己**（`:332-333`）⇒ bash 每次为新子进程从磁盘**重读**本件
  #   ⇒ 父进程按旧版造 fixture、子进程按新版判 ⇒ **改件窗口里出的红是凭空的红**。
  #   口径：**开头记 sha16、结尾再算一次**；不等 ⇒ `ST_ATTEST=NOINFO` 并点名（含 sha0/sha1 与内层 rc），
  #   统一 **rc=2**（`NOINFO` 码，不与 `FAIL` 混）。只加在 `--selftest` 路径；**生产路径一字未动**；
  #   不删例、不放宽任何期望（成对读数见 `$HOME/w33b-report.md`）。
  if [ -z "${ST_ATTEST_INNER:-}" ]; then
    ST_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    ST0="$(sha256sum "$ST_SELF" | cut -c1-16)"
    printf 'ST_ATTEST=OPEN self=%s sha16=%s\n' "$ST_SELF" "$ST0"
    if [ "${1:-}" = '--selftest' ]; then ST_IN=("$@"); else ST_IN=(--file "$VFILE" --selftest); fi
    ST_OUT="$(ST_ATTEST_INNER=1 bash "$ST_SELF" "${ST_IN[@]}" 2>&1)"; ST_RC=$?
    printf '%s\n' "$ST_OUT"
    ST1="$(sha256sum "$ST_SELF" | cut -c1-16)"
    if [ "$ST1" != "$ST0" ]; then
      printf 'ST_ATTEST=NOINFO reason=self-rewritten-during-selftest（本件在自测期间被改写 ⇒ 上面的读数不可归因）self=%s sha0=%s sha1=%s inner_rc=%s\n' \
             "$ST_SELF" "$ST0" "$ST1" "$ST_RC"
      exit 2
    fi
    printf 'ST_ATTEST=PASS self=%s sha16=%s（自测期间本件未变 ⇒ 读数可归因）\n' "$ST_SELF" "$ST0"
    exit "$ST_RC"
  fi
  # ═══ 【W28E 修订 · **世代无关化**】═════════════════════════════════════════════════
  # 【为什么改】本段初版把 fixture 的**世代号写死**（`'… gen=#27' % n`），而条数 `n` 是
  #   从被测件**现算**的 ⇒ 被测件换代（`#27`/16 → `#28`/17）后，fixture 的 gen 与真件的
  #   **口径句脱钩** ⇒ 6 例红（`prose-mismatch` / 期望 PASS 的例也红）。**红的是 fixture，
  #   不是判据** —— 但那意味着"`--selftest` 只在当世代绿"，而**沙箱里报的 19/19 是假绿**
  #   （沙箱被测件是旧世代）—— 本工程最怕的形态。
  # 【本版做法】① `gen` 与 `n` **一律从被测件现算**（`decl_line` 优先，缺则取**最后一次**
  #   口径句 ⇒ 前接线/后接线都能跑）；② **凡改步清单的 fixture，其 `DECL`/`NAMES` 两行都从
  #   **改动后的文件**重新抽**（`fixture.py` 的 `set-decl`/`inject-decl`）⇒ 不再做任何字符串
  #   外科（初版另有 `| DEFECT-REGISTRY`、`'BASELINE-SHA |'` 之类**位置耦合**，同族隐患）；
  #   ③ 新增两档反极性把"fixture 与真件世代脱钩"这件事**本身**钉住（`stale-gen` 必红、
  #   `gen-nonexistent` 必 NOINFO）；④ 汇总行印出本趟 fixture 用的 `fixture_gen`/`fixture_n`
  #   ⇒ **读的人一眼能看出 fixture 是跟哪一代对齐的**（不许无声）。
  # 【未动的部分】本块之外的**全部代码**（`run_checks` 判据本体、`extract_names`、`decl_line`、
  #   末尾两行驱动）**逐字节未动** —— 机器证：本文件按 `if [ "$SELFTEST" = 1 ]; then` 与
  #   `run_checks "$VFILE"` 两个标记切成三段，**第 1 段与第 3 段与本修订前 `cmp` 相同**。
  # ═══════════════════════════════════════════════════════════════════════════════════
  [ -f "$VFILE" ] || { echo "VERIFYALL_SELF=NOINFO reason=selftest-target-absent file=$VFILE"; exit 2; }
  SHA_BEFORE="$(sha256sum "$VFILE" | cut -d' ' -f1)"
  SBX="$(mktemp -d /tmp/w28e-selftest.XXXXXX)"
  trap 'rm -rf "$SBX"' EXIT
  pass=0; fail=0; skip=0

  base="$SBX/base.sh"
  cp -p "$VFILE" "$base"          # ⚠️ `cp -p` **真复制**（**禁** `ln`/硬链接 —— 纪律 60）

  gen_inc() {  # gen_inc '#28' ⇒ '#29'（纯 bash，不借 sed 做算术）
    local g="${1#\#}"
    case "$g" in ''|*[!0-9]*) printf ''; return 0 ;; esac
    printf '#%d' "$((g + 1))"
  }

  # ── ① **世代号与条数从被测件现算**（这是本次修订的要点，不许写死任何一代）──────────
  N_REAL="$(extract_names "$base" | grep -c . || true)"
  GEN_REAL="$(decl_line "$base" | sed -n 's/.*gen=\(#[0-9]\{1,\}\).*/\1/p')"
  if [ -z "$GEN_REAL" ]; then
    # 前接线形态（头注释还没声明块）：取**最后一次**口径句的世代 —— 末次 = 最新
    GEN_REAL="$(sed -n 's/.*\(#[0-9]\{1,\}\)` 收官起 = [0-9]\{1,\} 步.*/\1/p' "$base" | tail -1)"
  fi
  if [ -z "$GEN_REAL" ]; then
    echo "VERIFYALL_SELF=NOINFO reason=selftest-no-generation（被测件既无 DECL 的 gen=、也无『收官起 = N 步』口径句 ⇒ fixture 无法世代无关地构造）file=$VFILE"
    exit 2
  fi
  GEN_NEXT="$(gen_inc "$GEN_REAL")"
  # 「上一代」= 真件里出现过、但**不是本代**、且它的步数 ≠ 本代步数的那个世代（取最新一个）
  GEN_STALE="$(sed -n 's/.*\(#[0-9]\{1,\}\)` 收官起 = \([0-9]\{1,\}\) 步.*/\1 \2/p' "$base" \
               | awk -v cur="$GEN_REAL" -v n="$N_REAL" '$1 != cur && $2 != n { g = $1 } END { if (g != "") print g }')"
  # 一个真件里**完全不存在**的世代号
  GEN_GHOST='#99'
  while grep -qF "$GEN_GHOST" "$base"; do GEN_GHOST="#${GEN_GHOST#\#}9"; done

  # ── ② fixture 生成器（**世代无关**：数字全由调用方传入或从文件现抽）───────────────
  FX="$SBX/fixture.py"
  cat > "$FX" <<'PY'
import sys, io, re

def read(p):   return io.open(p, encoding='utf-8').read()
def write(p,s):io.open(p, 'w', encoding='utf-8').write(s)
def names(s):  return re.findall(r'^run_step "([^"]*)"', s, re.M)
def dline(s):
    m = re.search(r'^#\s*VERIFYALL-STEPS-DECL:.*$', s, re.M);  return m.group(0) if m else None
def nline(s):
    m = re.search(r'^#\s*VERIFYALL-STEP-NAMES:.*$', s, re.M);  return m.group(0) if m else None

def put_decl(s, n, gen):
    """把 DECL/NAMES 两行写成 (n, gen) + **从本文件现抽**的步名次序；缺则插在 shebang 之后。"""
    dl = '# VERIFYALL-STEPS-DECL: %d gen=%s' % (n, gen)
    nl = '# VERIFYALL-STEP-NAMES: %s' % ' | '.join(names(s))
    if dline(s):
        old_n = nline(s)
        s = s.replace(dline(s), dl, 1)
        if old_n: s = s.replace(old_n, nl, 1)
        else:     s = s.replace(dl, dl + '\n' + nl, 1)
    else:
        L = s.split('\n'); s = '\n'.join(L[:1] + [dl, nl] + L[1:])
    return s

def after_last_step(s, block):
    L = s.split('\n')
    idx = [i for i, l in enumerate(L) if l.startswith('run_step "')]
    assert idx, '被件里没有 ^run_step " 行'
    i = idx[-1]
    return '\n'.join(L[:i+1] + block.split('\n') + L[i+1:])

src, dst, op = sys.argv[1], sys.argv[2], sys.argv[3]
a = sys.argv[4:]
s = read(src)

if   op == 'inject-decl':  s = put_decl(s, len(names(s)), a[0])
elif op == 'set-decl':     s = put_decl(s, int(a[0]), a[1])
elif op == 'drop-decl':    s = re.sub(r'^#\s*VERIFYALL-STEPS-DECL:.*\n', '', s, flags=re.M)
elif op == 'drop-names':   s = re.sub(r'^#\s*VERIFYALL-STEP-NAMES:.*\n', '', s, flags=re.M)
elif op == 'drop-name':    s = s.replace(nline(s), nline(s).replace(' | %s' % a[0], '', 1), 1)
elif op == 'bump-prose':   s = s.replace('收官起 = %s 步' % a[0], '收官起 = %s 步' % a[1])
elif op == 'drop-prose':   s = '\n'.join(l for l in s.split('\n') if ('收官起 = %s 步' % a[0]) not in l)
elif op == 'add-prose':    s = s.replace(dline(s), dline(s) + '\n#   **`%s` 收官起 = %s 步**（fixture）' % (a[0], a[1]), 1)
elif op == 'add-step':     s = after_last_step(s, 'run_step "%s" bash build/MilBridge/tools/zzz-fixture.sh' % a[0])
elif op == 'indent-step':  s = after_last_step(s, '  run_step "%s" bash build/MilBridge/tools/zzz-fixture.sh' % a[0])
elif op == 'dead-step':    s = after_last_step(s, 'if [ 1 = 0 ]; then\nrun_step "%s" bash build/MilBridge/tools/zzz-fixture.sh\nfi' % a[0])
elif op == 'dup-step':     s = re.sub(r'^(run_step "%s".*)$' % re.escape(a[0]), r'\1\n\1', s, count=1, flags=re.M)
elif op == 'del-step':     s = re.sub(r'^run_step "%s".*\n' % re.escape(a[0]), '', s, count=1, flags=re.M)
elif op == 'rename-step':  s = s.replace('run_step "%s"' % a[0], 'run_step "%s"' % a[1], 1)
elif op == 'comment-step': s = s.replace('run_step "%s"' % a[0], '#run_step "%s"' % a[0], 1)
elif op == 'fn-rename':    s = re.sub(r'\brun_step\b', 'rs', s)
elif op == 'reorder':
    L = s.split('\n'); idx = [i for i, l in enumerate(L) if l.startswith('run_step "')]
    assert len(idx) >= 5, '步数不足以换次序'
    i, j = idx[3], idx[4]; L[i], L[j] = L[j], L[i]; s = '\n'.join(L)
else: raise SystemExit('unknown op: ' + op)

write(dst, s)
PY

  # ── 基线：声明按**现算**的 (N_REAL, GEN_REAL) 注入（不是写死的任何一代）───────────
  python3 "$FX" "$base" "$base" inject-decl "$GEN_REAL"

  # ── 【`#37` F3】给 fixture **造一份 `docs/`**（新判据按"被测件所在目录"找预登记件）────
  #    不造的话，"本代没有预登记节"会**把下面所有期望 rc=0 的例一起打红** —— 看起来像"新判据把老例全毁了"，
  #    其实只是沙箱少了 docs/（**判据没错，沙箱要跟上**；第一次跑就是这么红的，现场见 §3.3b）。
  #    ⚠️ 要把 fixture 用到的**每个世代**都写上：`GEN_REAL`（本代）、`GEN_NEXT`（下一代，`postwire` 用）、
  #       `GEN_STALE`（上一代，`stale-gen` 用）—— 少一个就会让那一例换理由。
  mkdir -p "$SBX/docs"
  { printf '# fixture 预登记（本代 `%s`）\n' "$GEN_REAL"
    printf '# fixture 预登记（下一代 `%s`）\n' "$GEN_NEXT"
    [ -n "${GEN_STALE:-}" ] && printf '# fixture 预登记（上一代 `%s`）\n' "$GEN_STALE"
  } > "$SBX/docs/WAVE00-PREREGISTRATION.md"

  chk() {  # chk <例名> <期望rc> <期望 reason 子串（空=不查）> <文件> [trace 日志]
    local nm="$1" want="$2" whyre="$3" f="$4" tr="${5:-}" out rc
    if [ -n "$tr" ]; then out="$(bash "$SELF" --file "$f" --trace "$tr" 2>&1)"; rc=$?
    else out="$(bash "$SELF" --file "$f" 2>&1)"; rc=$?; fi
    local ok=1
    [ "$rc" = "$want" ] || ok=0
    if [ -n "$whyre" ]; then grep -qF "$whyre" <<< "$out" || ok=0; fi
    if [ "$ok" = 1 ]; then
      pass=$((pass+1)); printf '  %-24s => yes  rc=%s  %s\n' "$nm" "$rc" "$(head -1 <<< "$out" | cut -c1-110)"
    else
      fail=$((fail+1)); printf '  %-24s => NO   want rc=%s/%s got rc=%s %s\n' "$nm" "$want" "${whyre:-<任意>}" "$rc" "$(head -1 <<< "$out" | cut -c1-110)"
    fi
  }
  skip_case() { skip=$((skip+1)); printf '  %-24s => n/a（**跳过并写明理由**，不许无声）reason=%s\n' "$1" "$2"; }

  # ── 阳性对照：注入声明后必须 PASS（判据能与现实一致，不是恒红）─────────────────
  chk "base（注入声明）" 0 "VERIFYALL_SELF=PASS" "$base"

  # ── 反极性：改步清单（声明不动）⇒ 必红 ────────────────────────────────────────
  python3 "$FX" "$base" "$SBX/del.sh"      del-step     ARM-LOG-SHA
  python3 "$FX" "$base" "$SBX/add.sh"      add-step     ZZZ-NEXTWAVE
  python3 "$FX" "$base" "$SBX/ren.sh"      rename-step  BASELINE-SHA BASELINE-SHA2
  python3 "$FX" "$base" "$SBX/commented.sh" comment-step BASELINE-SHA
  python3 "$FX" "$base" "$SBX/fnren.sh"    fn-rename
  python3 "$FX" "$base" "$SBX/reorder.sh"  reorder
  python3 "$FX" "$base" "$SBX/selfinc.sh"  drop-name    BASELINE-SHA
  chk "del-step"               1 "name-set-differs"       "$SBX/del.sh"
  chk "add-step"               1 "count-mismatch"         "$SBX/add.sh"
  chk "rename-step"            1 "name-set-differs"       "$SBX/ren.sh"
  chk "comment-out"            1 "count-mismatch"         "$SBX/commented.sh"
  chk "fn-renamed"             1 "count-mismatch"         "$SBX/fnren.sh"
  chk "reorder-steps"          1 "name-order-differs"     "$SBX/reorder.sh"
  chk "decl-self-inconsistent" 1 "decl-self-inconsistent" "$SBX/selfinc.sh"

  # ── 反极性：声明/口径句本身坏掉（三档 NOINFO + 一档 FAIL）────────────────────────
  python3 "$FX" "$base" "$SBX/dnum.sh"  set-decl  "$((N_REAL - 1))" "$GEN_REAL"
  python3 "$FX" "$base" "$SBX/pwrong.sh" bump-prose "$N_REAL" "$((N_REAL - 1))"
  python3 "$FX" "$base" "$SBX/noprose.sh" drop-prose "$N_REAL"
  python3 "$FX" "$base" "$SBX/nodecl.sh"  drop-decl
  python3 "$FX" "$base" "$SBX/nonames.sh" drop-names
  chk "decl-count-wrong"  1 "count-mismatch"        "$SBX/dnum.sh"
  chk "prose-wrong"       1 "prose-mismatch"        "$SBX/pwrong.sh"
  chk "prose-absent"      2 "header-prose-absent"   "$SBX/noprose.sh"
  chk "decl-absent"       2 "decl-absent"           "$SBX/nodecl.sh"
  chk "names-absent"      2 "names-absent"          "$SBX/nonames.sh"

  # ── 🔴 **本次修订新增**：把"fixture 与真件世代脱钩"这件事**本身**钉住 ──────────────
  #   ⑮「停在上一代」（主控 `#28` 落地时撞到的正是这一形态：fixture 的 gen 停在真件上一代，
  #      而该世代的**口径句仍在头注释里**（史实保留）⇒ 判据 ③ 走 `prose-mismatch` ⇒ **必红**)。
  #   ⑯「声称一个真件里根本不存在的世代」⇒ 判据 ③ 走 **缺声明** 那一支 ⇒ `NOINFO`（rc=2）。
  #      ⚠️ 为什么是 rc=2 而不是 rc=1：三段式里「**缺声明** ⇒ `NOINFO`」是本判据的设计（不许当绿）。
  #         **两者都不绿**，但理由不同 —— 不许把 rc=2 读成"这一步没判"。
  if [ -n "$GEN_STALE" ]; then
    python3 "$FX" "$base" "$SBX/stale.sh" set-decl "$N_REAL" "$GEN_STALE"
    chk "stale-gen（停在上一代）" 1 "prose-mismatch" "$SBX/stale.sh"
  else
    skip_case "stale-gen（停在上一代）" "被测件里没有『非本代且步数不同』的世代可借（GEN_STALE 空）"
  fi
  python3 "$FX" "$base" "$SBX/ghost.sh" set-decl "$N_REAL" "$GEN_GHOST"
  chk "gen-nonexistent" 2 "header-prose-absent" "$SBX/ghost.sh"

  # ── 🔵 【`#37` F3】新判据的反极性两例：**"本代没有预登记节"必须出声**（`NOINFO`，不许当绿）────
  #    例一：把唯一的预登记件**移走**（`ls` 扫到 0 件）⇒ 必须 `NOINFO prereg-absent`；
  #    例二：留一件、但标题里是**别的世代**（`#99`）⇒ 同样必须 `NOINFO prereg-absent`。
  #    ⚠️ 不动真树：只在沙箱 `$SBX/docs/` 里搬/写（真件的 docs 一个字没碰）。
  mv "$SBX/docs/WAVE00-PREREGISTRATION.md" "$SBX/docs/.parked"
  chk "prereg-absent（扫到 0 件）" 2 "prereg-absent" "$base"
  printf '# fixture 预登记（别的世代 `#99`）\n' > "$SBX/docs/WAVE00-PREREGISTRATION.md"
  chk "prereg-wrong-gen"          2 "prereg-absent" "$base"
  mv -f "$SBX/docs/.parked" "$SBX/docs/WAVE00-PREREGISTRATION.md"

  # ── 同名步 + 声明全配平（①集合②数⑤次序 全过 ⇒ **只有重名检测能抓**）──────────────
  python3 "$FX" "$base" "$SBX/dup1.sh" dup-step BASELINE-SHA
  python3 "$FX" "$SBX/dup1.sh" "$SBX/dup1.sh" set-decl "$((N_REAL + 1))" "$GEN_REAL"
  python3 "$FX" "$SBX/dup1.sh" "$SBX/dup1.sh" bump-prose "$N_REAL" "$((N_REAL + 1))"
  chk "dup-consistent" 1 "duplicate-step-name" "$SBX/dup1.sh"

  # ── 接线后模拟：**同趟**加一步 + 声明推进到下一代 + 追加新口径句 ⇒ 必须 PASS ─────────
  #   （证明自指是**可满足的不动点**；也证明"进步换代"这条路走得通）
  python3 "$FX" "$base" "$SBX/postwire.sh" add-step ZZZ-NEXTWAVE
  python3 "$FX" "$SBX/postwire.sh" "$SBX/postwire.sh" set-decl "$((N_REAL + 1))" "$GEN_NEXT"
  python3 "$FX" "$SBX/postwire.sh" "$SBX/postwire.sh" add-prose "$GEN_NEXT" "$((N_REAL + 1))"
  printf 'VERIFYALL_STEPS_RUN=%s\n' "$((N_REAL + 1))" > "$SBX/trace_next.log"
  printf 'VERIFYALL_STEPS_RUN=%s\n' "$N_REAL"           > "$SBX/trace_cur.log"
  chk "postwire-sim" 0 "VERIFYALL_SELF=PASS" "$SBX/postwire.sh" "$SBX/trace_next.log"

  # ── 已知漏网①（缩进：**会执行**但锚抽不到）及其 `--trace` 捕获 ────────────────────
  python3 "$FX" "$base" "$SBX/indented.sh" indent-step ZZZ-EXTRA
  chk "known-miss-indented"       0 ""                       "$SBX/indented.sh"
  chk "indented-caught-by-trace"  1 "static-vs-run-mismatch" "$SBX/indented.sh" "$SBX/trace_next.log"

  # ── 已知漏网②（死分支：**抽得到**但永不执行）及其 `--trace` 捕获 ──────────────────
  python3 "$FX" "$base" "$SBX/dead.sh" dead-step ZZZ-DEAD
  python3 "$FX" "$SBX/dead.sh" "$SBX/dead.sh" set-decl "$((N_REAL + 1))" "$GEN_REAL"
  python3 "$FX" "$SBX/dead.sh" "$SBX/dead.sh" bump-prose "$N_REAL" "$((N_REAL + 1))"
  chk "known-miss-deadbranch"        0 ""                       "$SBX/dead.sh"
  chk "deadbranch-caught-by-trace"   1 "static-vs-run-mismatch" "$SBX/dead.sh" "$SBX/trace_cur.log"

  # ── 真件未被本件触碰（机器证）──────────────────────────────────────────────────
  SHA_AFTER="$(sha256sum "$VFILE" | cut -d' ' -f1)"
  touch_ok="yes"; [ "$SHA_BEFORE" = "$SHA_AFTER" ] || { touch_ok="NO"; fail=$((fail+1)); }

  # 汇总行**必须印出 fixture 用的是哪一代/几条**：读的人一眼能看出它是否与真件对齐（不许无声）
  echo "VERIFYALL_SELF_SELFTEST=$( [ "$fail" -eq 0 ] && echo PASS || echo FAIL ) cases=$((pass+fail+skip)) pass=$pass fail=$fail skip=$skip fixture_gen=$GEN_REAL fixture_next=$GEN_NEXT fixture_n=$N_REAL target_untouched=$touch_ok target_sha16=$(printf '%s' "$SHA_AFTER" | cut -c1-16)"
  # ⚠️ 下面这行里的反引号**必须单引号包**：双引号里 `cp -p` 会被当命令替换执行（本件初版实测踩到）
  echo '  ∟ 沙箱 = '"$SBX"'（真副本 `cp -p`；已 rm -rf）'
  [ "$fail" -eq 0 ] || exit 1
  exit 0
fi

run_checks "$VFILE"
exit $?
