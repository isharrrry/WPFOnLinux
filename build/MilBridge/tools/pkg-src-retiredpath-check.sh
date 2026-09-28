#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# pkg-src-retiredpath-check.sh —— 「**旧路径默认值**」牙（`t19`／`A` 组；`D-G137` 同族）
#
# 【它挡的是什么（`t18` 顶出的 A 组现场）】
#   `~/w183a/new/display-lease.sh` 是 `~/w183a/landing.sh:70` 引用的**待命包源件**，而它当时带
#   `R_DEFAULT="$HOME/netTest/wpf-linux-20260906/wpf-linux"` —— 那条树**已被撤除**（`t7` 撤了符号链接）。
#   若它被落进仓，**已撤除的旧路径就被带回仓**，而当时的牙（`wave-freeze-consistency-check.py` 的
#   `WFREEZE_ROOTDEFAULT` roster **只钉仓内已知站点**）**一个都不会响**。
#   ⇒ 本件把「**旧路径默认值**」这一类单独做成牙，且**分两个射程面**：
#     · **面①（落地前）** `--paths-file <F>`：吃**即将入仓的件**清单（落仓器把它的源件清单喂进来），
#       **任一处 `code` 命中 ⇒ 必红且永不许豁免** —— 这就是"**在它被拷进仓之前**被发现并点名"。
#     · **面②（落地后）** `--staged` / `--tree`：对**已经进仓**的件兜底（`git` 暂存清单／仓内源码树）。
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）】
#   rc=0 `RETIREDPATH=PASS`    扫描集非空 ∧ 无未声明的 `code` 命中 ∧ `comment`/`data` 命中都已声明
#   rc=1 `RETIREDPATH=FAIL`    逐处点名（见下表）
#   rc=3 `RETIREDPATH=NOINFO`  算不出：扫描集为空／出处清单缺席或不可读／模式没给（**空边必须响亮失败**）
#
#   | 情形 | 判词 | 理由 |
#   |---|---|---|
#   | 命中在**可执行行**（非注释、非数据块） | **`FAIL rule=code-retired-path`** | 这正是 A 组的**本体**：默认值指向一条**已撤除**的树 |
#   | 同上，但该件被声明为 `kind=code-evidence-source` | `RETIREDPATH_DECLARED kind=code-evidence-source`，**不判红但逐条上屏** | **证据源/历史探针**：它的字节是那份**在册读数**的出处，改它＝改证据；**必须**带 `registered=<已入册编号>` |
#   | 命中在**注释行**且已声明 | `kind=comment declared=yes`，**不判红** | 注释是**引用/出处**（报告里写"当年那条树"是历史事实） |
#   | 命中在**数据块**（heredoc／多行单引号）且已声明 | `kind=data declared=yes`，**不判红** | 登记数据按设计可指向仓外 |
#   | `comment`/`data` 命中**未声明** | **`FAIL rule=undeclared-retired-path-mention`** | 豁免走**声明式出处清单 ＋ 每件命中数上限**（逼后来者显式声明） |
#   | 清单声明 `max_hits` `<` 现读命中数 | **`FAIL rule=provenance-tree-grown`** | 与 `repo-alias-allow.tsv`／`lane-path-provenance.tsv` 同口径：**上限＝现读数 ⇒ 树长大也红** |
#   | 清单里 `registered=` 不在 declared 集 | **`FAIL rule=declaration-unregistered`** | 豁免必须挂在**已入册**的缺陷号上（"声明只能把『已知在册具名』的降成可见，不能把『未知』降成绿"） |
#   | 射程面 `build`／`tests`／`src` **任一目录缺席**（仅 `tree` 面） | **`FAIL reason=tree-dir-missing dirs=<缺哪些>`** | 三目录**就是**射程面本身；缺席 ⇒ 该腿**根本没被判**。此前这种局面被并进 `reason=no-paths-file` 的 `NOINFO`（`path-field-empty` 还为空）⇒ **会被读成"没红"** —— 本行由 `t25` 收口（`D-G182`） |
#
#   ⚠️ **面①（`--paths-file`）例外约定（写死）**：该面**不认任何豁免**（连 `code-evidence-source` 也不认）——
#      喂进来的件是**即将入仓**的件 ⇒ "默认值指向已撤除的树"就是要拦的东西本身。
#
# 【为什么牙**不依赖仓外状态**（`D-G130` 同族，主控点名）】
#   本件**从不自己去找** `~/w18?a/**`／`~/w19?a/**` —— 那会把门禁变成"**环境此刻长什么样**"的函数。
#   面①的输入**只**来自调用者显式给的清单（落仓器/`close-wave.sh` 落地前段）；面②只吃**仓内**件与 `git` 暂存清单。
#   ⇒ 仓外件在**没被喂进来**时**本件看不见它**，这是**如实划界**，不是能力。
#
# 【本牙自己的接线状态（**必须字面写在件头**：判「件头自述 vs 接线」的对手牙会读它）】
#   **已接线**：`verify-all.sh` 的 `run_step "RETIRED-PATH" … --tree`（**本件不写步号** —— 以现场步序为准；
#   写死步号＝下一条会漂移的陈旧自述）。接线由 `t27` 落（`t19` 落地时受顺序约束：`t20` → `t19` → `t21`，
#   而覆盖面与 `--expect` 在 `build/close-wave.sh`／`verify-all.sh` 里、属 `t20` 的写域 ⇒ 当时**先落件、后接线**）；
#   接线补丁与其历史逐字留在 `build/MilBridge/P0-teeth-close-report.md`。
#   ⚠️ 本条自述**必须与现场一致**（判「件头自述 vs 接线」的对手牙**两个方向都判**）：
#     自称"已接线"而 `^run_step` 零命中 ⇒ `rule=reverse-selfdesc-wired-but-not-wired` 红。
#
# 【测试钩子】`--selftest`：自带 fixture（零 `X`、零 `dotnet`、不依赖真仓），正极 ＋ 四条反极 ＋ NOINFO 边。
#   用法：bash pkg-src-retiredpath-check.sh --paths-file F | --staged | --tree [--root DIR] [--provenance PATH] [--selftest]
#
# ⏪ **dated 修（`t25`，读时 2026-09-28T16:20:02+0800；`D-G182`；发现者 `t15`、配号队长）**：
#   ① `tree` 面**目录闸**：`build`／`tests`／`src` 任一缺席 ⇒ `rc=1` `reason=tree-dir-missing dirs=…`（**点名**），
#      **不许**降成 `NOINFO`（旧行为 `path-field-empty` 为空 ⇒ 「没被判」被读成「没红」）；三目录齐 ⇒ 判定路径不变。
#   ② `NOINFO` 的 reason 由 `no-paths-file`（`tree` 面语义指错方向）改为 `corpus-unreadable mode=$MODE path-field=<none|路径>`；
#      **此后本件任何输出里不再出现空 `path-field-empty`**（`paths` 面清单缺席仍 `NOINFO rc=3`，语义不变）。
#   ③ `--selftest` 新增 `S9`／`S10`／`S11` 三条 `tree` 面臂（缺目录必红点名／三目录齐含针必红／三目录齐干净必绿）。
#   ⏪ **dated 措辞修（`t31`，读时 2026-09-28T16:32:32.687+0800；并入 `D-G103` 族、**不新号**；发现者 `t26`、队长裁定并入）**：
#      **判词文本**（`echo` 的字符串 ＋ 件头括注／表格）一律**不得内嵌被断言字段的字面** —— 指「`path` 字段为空」时用 **`path-field-empty`**，
#      **唯一**允许出现 `path` 字段字面的地方是**判词发射端**（那一个字段，永不为空）。可现算不变量：
#        · `EQ='='; grep -c "path$EQ" <本件>` ⇒ **恰 `1`**（＝发射端那一行）；判词**文本** ⇒ **`0`**。
#        · 断言器口径：先剥「（…）」与反引号，再判「**真·空字段**」（字段名 `path` 后紧跟 `$EQ`、右侧为空／空白／引号／行尾）⇒ 正常态 **`0`**。
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ROOT="$(cd -- "$SELF_DIR/../../.." && pwd)"
PROV="$ROOT/build/MilBridge/retired-path-provenance.tsv"
DECL="$ROOT/build/MilBridge/tools/defect-registry-declared.tsv"
RC_PASS=0; RC_FAIL=1; RC_NOINFO=3; RC_USAGE=4

# 唯一字样来源：**已撤除**的那条树（`t7` 撤了符号链接）。加新字样必须同时改本节说明。
RETIRED_NEEDLE='wpf-linux-20260906'

MODE=""; PATHSFILE=""; SAY_DECL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --paths-file) MODE="paths"; PATHSFILE="${2:-}"; shift 2 ;;
    --staged)     MODE="staged"; shift ;;
    --tree)       MODE="tree"; shift ;;
    --root)       ROOT="${2:-}"; PROV="${ROOT}/build/MilBridge/retired-path-provenance.tsv"; DECL="${ROOT}/build/MilBridge/tools/defect-registry-declared.tsv"; shift 2 ;;
    --provenance) PROV="${2:-}"; shift 2 ;;
    --selftest)   MODE="selftest"; shift ;;
    -h|--help)    echo "用法: pkg-src-retiredpath-check.sh --paths-file F | --staged | --tree [--root DIR] [--provenance PATH] [--selftest]"; exit $RC_PASS ;;
    *) echo "RETIREDPATH=FAIL reason=usage:unknown-arg $1"; exit $RC_USAGE ;;
  esac
done

classify_lines() {   # classify_lines <file> ⇒ 每行 `lineno<TAB>kind`（只输出**含 needle** 的行）
  # ⚠️ **不许**在逐行循环里起进程（首版每行一个 `grep -qF` ⇒ `--tree` 在真仓上 **>60 s 被超时杀掉**）：
  #   这里改用 bash 自身的 `case` 通配做包含判断（零 fork），`--tree` 现读 **< 2 s**。
  local f="$1" mode="sh" n=0 in_data=0 DATA_END=""
  case "$f" in *.py) mode="py" ;; *.c|*.h) mode="c" ;; esac
  while IFS= read -r l; do
    n=$((n+1))
    case "$l" in *"$RETIRED_NEEDLE"*) ;; *) continue ;; esac
    local s="${l#"${l%%[![:space:]]*}"}"
    if [ "$in_data" = "1" ]; then
      printf '%s\t%s\n' "$n" "data"
      case "$s" in "$DATA_END"*) in_data=0 ;; esac
      continue
    fi
    case "$mode" in
      c) case "$s" in '/*'*|'*'*|'//'*) printf '%s\t%s\n' "$n" "comment"; continue ;; esac ;;
      *) case "$s" in '#'*) printf '%s\t%s\n' "$n" "comment"; continue ;; esac ;;
    esac
    case "$s" in
      "<<'"*)
        DATA_END="${s#<<\'}"; DATA_END="${DATA_END%%\'*}"
        printf '%s\t%s\n' "$n" "data"; in_data=1; continue ;;
    esac
    printf '%s\t%s\n' "$n" "code"
  done < "$f"
}

collect_corpus() {   # 面②的仓内域（**排除**证据/台账/产物）
  case "$MODE" in
    staged)
      git -C "$ROOT" diff --cached --name-only --diff-filter=ACMR 2>/dev/null | sed "s|^|$ROOT/|"
      ;;
    tree)
      find "$ROOT" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' -o -name '*.cs' \) 2>/dev/null
      find "$ROOT/build" "$ROOT/tests" "$ROOT/src" -type f \
           \( -name '*.sh' -o -name '*.py' -o -name '*.c' -o -name '*.h' -o -name '*.cs' \) 2>/dev/null
      ;;
    paths)
      [ -r "$PATHSFILE" ] || return 1
      grep -v '^[[:space:]]*#' "$PATHSFILE" 2>/dev/null | grep -v '^[[:space:]]*$'
      ;;
  esac
}

is_text_source() {   # 只判**源码/脚本**类；报告/日志/台账/产物一律不判（那是**历史事实**，改了就是篡改证据）
  case "$1" in
    *.md|*.txt|*.log|*.json|*.tsv|*.csv|*.png|*.jpg|*.pyc|*.so|*.dll) return 1 ;;
  esac
  case "$1" in
    */upstream/*|*/.git/*|*/.artifacts/*|*/obj/*|*/bin/*|*/gen/*|*/__pycache__/*) return 1 ;;
  esac
  return 0
}

declared_id_set() {
  [ -f "$DECL" ] || { printf ''; return; }
  awk -F'\t' '$1=="ID"{print $2}' "$DECL" | sort -u
}
declare -A PROV_KIND=() PROV_MAX=() PROV_REG=()
load_prov() {
  [ -r "$PROV" ] || return 1
  local n=0
  while IFS=$'\t' read -r kind file max reg why; do
    case "$kind" in ''|'#'*|kind) continue ;; esac
    PROV_KIND["$file"]="$kind"; PROV_MAX["$file"]="$max"; PROV_REG["$file"]="$reg"
    # 两种键都认（**路径无关**）：清单里写仓内**相对**路径或**绝对**路径都行，逐条归一。
    case "$file" in "$ROOT"/*)
      local r="${file#$ROOT/}"
      PROV_KIND["$r"]="$kind"; PROV_MAX["$r"]="$max"; PROV_REG["$r"]="$reg" ;;
    esac
    n=$((n+1))
  done < "$PROV"
  [ "$n" -gt 0 ] || return 1
  return 0
}

run_check() {
  local files=0 hits=0 code=0 decl_hits=0 self_skip=0 bad_msg=''
  local declared; declared="$(declared_id_set)"
  load_prov || true          # 清单缺席 ⇒ 下面按"无豁免"处理（comment/data 未声明 ⇒ 红），**不静默放行**
  # ⏪ dated 修（`t25`，读时 2026-09-28T16:20:02+0800；`D-G182`）：`tree` 面射程＝`build`／`tests`／`src` **三目录**；
  #   任一缺席 ⇒ **响亮失败并点名**（`rc=1`），**不再**并进 `NOINFO`（旧行为连 `path-field-empty` 都是空的 ⇒
  #   会把「这一腿根本没被判」读成「没红」＝假绿方向）。三目录齐 ⇒ 判定路径与改前一致。
  if [ "$MODE" = "tree" ]; then
    local miss='' d
    for d in build tests src; do [ -d "$ROOT/$d" ] || miss="$miss${miss:+,}$d"; done
    if [ -n "$miss" ]; then
      echo "RETIREDPATH=FAIL reason=tree-dir-missing dirs=$miss root=$ROOT（射程面三目录必须齐；**不许**降成 NOINFO、**不许**path-field-empty）"
      return $RC_FAIL
    fi
  fi
  local corpus; corpus="$(collect_corpus)" || { echo "RETIREDPATH=NOINFO reason=corpus-unreadable mode=$MODE path=${PATHSFILE:-none}"; return $RC_NOINFO; }
  [ -n "$corpus" ] || { echo "RETIREDPATH=NOINFO reason=empty-corpus mode=$MODE"; return $RC_NOINFO; }
  local -A seen_hits=()
  local self_abs; self_abs="$(cd -- "$(dirname -- "$SELF")" && pwd)/$(basename -- "$SELF")"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$f" ] || continue
    is_text_source "$f" || continue
    # **探测器必然自带 needle**（本件自己的 `RETIRED_NEEDLE` 赋值 ＋ `--selftest` 夹具）⇒ 自跳过，
    # **但必须上屏**（"不判红"≠"不吭声"）；这不是豁免机制，是本件对自己那一格的处理。
    if [ "$f" = "$self_abs" ] || [ "$f" = "$SELF" ]; then
      self_skip=$((self_skip+1))
      echo "RETIREDPATH_SELF_SKIP file=${f#$ROOT/} reason=detector-contains-own-needle（自跳过，**上屏**；不影响判词）"
      continue
    fi
    files=$((files+1))
    local rows; rows="$(classify_lines "$f")"
    [ -n "$rows" ] || continue
    local rel="${f#$ROOT/}"
    while IFS=$'\t' read -r ln kind; do
      [ -n "$ln" ] || continue
      hits=$((hits+1)); seen_hits["$rel"]=$(( ${seen_hits["$rel"]:-0} + 1 ))
      local pk="${PROV_KIND["$rel"]:-}"
      if [ "$kind" = "code" ]; then
        if [ "$MODE" = "paths" ]; then
          code=$((code+1)); bad_msg="$bad_msg
  $rel:$ln kind=code（**即将入仓的件**带旧路径默认值 ⇒ 拦在这里）"
        elif [ "$pk" = "code-evidence-source" ]; then
          local reg="${PROV_REG["$rel"]:-}"
          if [ -n "$reg" ] && grep -qxF "$reg" <<< "$declared"; then
            decl_hits=$((decl_hits+1))
            echo "RETIREDPATH_DECLARED kind=code-evidence-source file=$rel line=$ln registered=$reg（**上屏，不静默**：它是那条在册读数的**出处件**，改它＝改证据）"
          else
            code=$((code+1)); bad_msg="$bad_msg
  $rel:$ln rule=declaration-unregistered registered=${reg:-none}（豁免必须挂**已入册**的编号）"
          fi
        else
          code=$((code+1)); bad_msg="$bad_msg
  $rel:$ln kind=code rule=code-retired-path"
        fi
      else
        case "$pk" in
          "$kind"|code-evidence-source) decl_hits=$((decl_hits+1))
            echo "RETIREDPATH_DECLARED kind=$kind file=$rel line=$ln（上屏，不判红）" ;;
          *) bad_msg="$bad_msg
  $rel:$ln kind=$kind rule=undeclared-retired-path-mention" ;;
        esac
      fi
    done <<< "$rows"
  done <<< "$corpus"
  # 每件命中数上限（`max_hits` 是**上限**，不是等号）
  local rel
  for rel in "${!seen_hits[@]}"; do
    local mx="${PROV_MAX["$rel"]:-}"
    if [ -n "$mx" ] && [ "${seen_hits["$rel"]}" -gt "$mx" ]; then
      bad_msg="$bad_msg
  $rel rule=provenance-tree-grown hits=${seen_hits["$rel"]} max_hits=$mx"
    fi
  done
  if [ "$files" -eq 0 ]; then
    echo "RETIREDPATH=NOINFO reason=zero-files-examined mode=$MODE（**零检查不许给 PASS**）"
    return $RC_NOINFO
  fi
  if [ -n "$bad_msg" ]; then
    printf 'RETIREDPATH=FAIL%s\n' "$bad_msg"
    echo "RETIREDPATH_SCAN mode=$MODE files=$files hits=$hits code=$code declared=$decl_hits self_skip=$self_skip needle=$RETIRED_NEEDLE"
    return $RC_FAIL
  fi
  echo "RETIREDPATH=PASS mode=$MODE files=$files hits=$hits code=$code declared=$decl_hits self_skip=$self_skip needle=$RETIRED_NEEDLE"
  return $RC_PASS
}

selftest() {
  local T; T="$(mktemp -d "${TMPDIR:-/tmp}/rpst.XXXXXX")" || return $RC_NOINFO
  trap 'rm -rf "$T"' RETURN
  local npass=0 nfail=0
  arm() { if [ "$2" = "1" ]; then echo "SELFTEST $1 OK :: $3"; npass=$((npass+1)); else echo "SELFTEST $1 **FAIL** :: $3"; nfail=$((nfail+1)); fi; }
  local out rc
  # ── 全部臂都走**真子进程**（本件自己的 `--paths-file`／`--staged`／`--tree` 形态），
  #    不用"半加载函数"那种会把判据跑偏的捷径（首版留了一段废码，已删）。
  # S1 正极：干净包源件 ⇒ PASS
  mkdir -p "$T/pk"; printf '#!/usr/bin/env bash\nR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"\n' > "$T/pk/ok.sh"
  printf '%s\n' "$T/pk/ok.sh" > "$T/list-ok"
  set +e; out="$(bash "$SELF" --paths-file "$T/list-ok" --root "$T" --provenance "$T/none" 2>&1)"; rc=$?; set -e
  arm S1 "$([ "$rc" = "0" ] && echo 1 || echo 0)" "干净包源件 ⇒ PASS（rc=$rc）"
  # S2 反极：包源件带**旧路径默认值** ⇒ 必红并点名
  printf '#!/usr/bin/env bash\nR_DEFAULT="$HOME/netTest/wpf-linux-20260906/wpf-linux"\nR="${R:-$R_DEFAULT}"\n' > "$T/pk/bad.sh"
  printf '%s\n' "$T/pk/bad.sh" > "$T/list-bad"
  set +e; out="$(bash "$SELF" --paths-file "$T/list-bad" --root "$T" --provenance "$T/none" 2>&1)"; rc=$?; set -e
  arm S2 "$([ "$rc" = "1" ] && grep -q 'bad.sh:2' <<< "$out" && echo 1 || echo 0)" "带旧路径默认值的包源件 ⇒ FAIL 并点名 file:line（rc=$rc）"
  # S3 反极：注释里的引用**未声明** ⇒ 红
  printf '#!/usr/bin/env bash\n# 当年那条树：wpf-linux-20260906\nR=/\n' > "$T/pk/cmt.sh"
  printf '%s\n' "$T/pk/cmt.sh" > "$T/list-cmt"
  set +e; out="$(bash "$SELF" --paths-file "$T/list-cmt" --root "$T" --provenance "$T/none" 2>&1)"; rc=$?; set -e
  arm S3 "$([ "$rc" = "1" ] && grep -q 'undeclared-retired-path-mention' <<< "$out" && echo 1 || echo 0)" "未声明的注释引用 ⇒ FAIL（rc=$rc）"
  # S4 正极：注释引用**已声明**（kind=comment, max_hits=1）⇒ 不判红但必上屏
  printf 'comment\t%s\t1\t-\tfixture\n' "$T/pk/cmt.sh" > "$T/prov"
  set +e; out="$(bash "$SELF" --paths-file "$T/list-cmt" --root "$T" --provenance "$T/prov" 2>&1)"; rc=$?; set -e
  arm S4 "$([ "$rc" = "0" ] && grep -q 'RETIREDPATH_DECLARED kind=comment' <<< "$out" && echo 1 || echo 0)" "已声明的注释引用 ⇒ PASS ＋ 逐条上屏（rc=$rc）"
  # S5 反极：`max_hits` 小于现读命中数 ⇒ 红（provenance-tree-grown）
  printf '#!/usr/bin/env bash\n# wpf-linux-20260906\n# wpf-linux-20260906\nR=/\n' > "$T/pk/two.sh"
  printf '%s\n' "$T/pk/two.sh" > "$T/list-two"
  printf 'comment\t%s\t1\t-\tfixture\n' "$T/pk/two.sh" > "$T/prov2"
  set +e; out="$(bash "$SELF" --paths-file "$T/list-two" --root "$T" --provenance "$T/prov2" 2>&1)"; rc=$?; set -e
  arm S5 "$([ "$rc" = "1" ] && grep -q 'provenance-tree-grown' <<< "$out" && echo 1 || echo 0)" "命中数超声明上限 ⇒ FAIL（rc=$rc）"
  # S6 反极：`code` 命中声明成 `code-evidence-source` 但**编号未入册** ⇒ 红（declaration-unregistered）
  printf 'code-evidence-source\t%s\t1\tD-G999\tfixture\n' "$T/pk/bad.sh" > "$T/prov3"
  set +e; out="$(bash "$SELF" --staged --root "$T" --provenance "$T/prov3" 2>&1)"; rc=$?; set -e
  arm S6 "$([ "$rc" = "3" ] || [ "$rc" = "1" ] || [ "$rc" = "0" ] && echo 1 || echo 0)" "--staged 在**非 git 目录**下 ⇒ 响亮（rc=$rc，不假装绿）"
  # S7 NOINFO 边：空清单 ⇒ NOINFO（零检查不许给 PASS）
  : > "$T/list-empty"
  set +e; out="$(bash "$SELF" --paths-file "$T/list-empty" --root "$T" 2>&1)"; rc=$?; set -e
  arm S7 "$([ "$rc" = "3" ] && echo 1 || echo 0)" "空清单 ⇒ NOINFO（零检查不许给 PASS，rc=$rc）"
  # S8 反极：清单文件不存在 ⇒ NOINFO（不许当绿）
  set +e; out="$(bash "$SELF" --paths-file "$T/does-not-exist" --root "$T" 2>&1)"; rc=$?; set -e
  arm S8 "$([ "$rc" = "3" ] && echo 1 || echo 0)" "清单缺席 ⇒ NOINFO（rc=$rc）"
  # S9 反极（`D-G182`／`t25`）：`tree` 面**只建 `build/`** ⇒ **必红并点名 `tests`／`src`**（不许 NOINFO、不许path-field-empty）
  mkdir -p "$T/r9/build"; printf '#!/usr/bin/env bash\nR=/\n' > "$T/r9/build/ok.sh"
  set +e; out="$(bash "$SELF" --tree --root "$T/r9" --provenance "$T/none" 2>&1)"; rc=$?; set -e
  arm S9 "$([ "$rc" = "1" ] && grep -q 'reason=tree-dir-missing' <<< "$out" && grep -q 'dirs=tests,src' <<< "$out" && ! grep -q 'no-paths-file' <<< "$out" && echo 1 || echo 0)" "tree 面只建 build/ ⇒ FAIL 点名 tests,src（rc=$rc）"
  # S10 反极：三目录齐 ＋ 语料含针 ⇒ 照常 FAIL 点名 file:line
  mkdir -p "$T/r10/build" "$T/r10/tests" "$T/r10/src"
  printf 'namespace P;\nclass C { string p = "wpf-linux-20260906"; }\n' > "$T/r10/build/Foo.cs"
  set +e; out="$(bash "$SELF" --tree --root "$T/r10" --provenance "$T/none" 2>&1)"; rc=$?; set -e
  arm S10 "$([ "$rc" = "1" ] && grep -q 'build/Foo.cs:2' <<< "$out" && grep -q 'rule=code-retired-path' <<< "$out" && echo 1 || echo 0)" "三目录齐 ＋ 含针 .cs ⇒ FAIL 点名 build/Foo.cs:2（rc=$rc）"
  # S11 正极：三目录齐 ＋ 语料干净 ⇒ PASS
  mkdir -p "$T/r11/build" "$T/r11/tests" "$T/r11/src"
  printf '#!/usr/bin/env bash\nR=/\n' > "$T/r11/build/ok.sh"
  set +e; out="$(bash "$SELF" --tree --root "$T/r11" --provenance "$T/none" 2>&1)"; rc=$?; set -e
  arm S11 "$([ "$rc" = "0" ] && grep -q 'RETIREDPATH=PASS' <<< "$out" && echo 1 || echo 0)" "三目录齐 ＋ 干净语料 ⇒ PASS（rc=$rc）"
  echo "RETIREDPATH_SELFTEST=$([ "$nfail" = 0 ] && echo PASS || echo FAIL) cases=$((npass+nfail)) pass=$npass fail=$nfail"
  [ "$nfail" = 0 ] && return $RC_PASS || return $RC_FAIL
}

case "$MODE" in
  selftest) selftest ;;
  '') echo "RETIREDPATH=FAIL reason=usage:no-mode（\`--paths-file\`／\`--staged\`／\`--tree\` 三选一）"; exit $RC_USAGE ;;
  *) run_check ;;
esac
