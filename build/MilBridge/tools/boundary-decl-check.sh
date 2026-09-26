#!/usr/bin/env bash
# ============================================================================
#  boundary-decl-check.sh  ·  波 `#76`（合波）· `TASK-0732` 主件 · 新步 `BOUNDARY-DECL`
#
#  【治什么病（`D-G132`：诚实声明没有机读读者）】
#  "**`UNWIRED`（产出端没被任何步骤调用）／`DEPRECATED`（同形副本已标废）**"这类**边界声明**，
#  过去只写在预登记件与注释里，仓内**没有任何一件去求值它**
#  ⇒ 声明在冻结那刻为真，之后**无人再验**；谓词一旦拼写漂移（大小写／连字符／经 wrapper 调用），
#  声明可以**静默变成假话**而屏上一个字都不变。`#69` 的 `[40]` 步给**一条**声明配了**一颗写死的**牙
#  （只作**先例**，不作**答案**）。
#
#  【本牙与 `[40]` 的根本区别 ＝ 通用化】
#   ① 声明**从预登记语料读回**：本文件**通篇**只出现**族名**（`WIRING`／`COPY-CENSUS`／
#      `UNVERIFIABLE`）与**字段名** —— **没有**任何具体声明的 id／target 路径／期望值。
#      语料 ＝ `docs/WAVE*-PREREGISTRATION.md`（**现取全量、每次重扫**；`D-G140` 口径：读数必带
#      `DECL_CORPUS files=… at=… digest=…`；**一次性扫描的结论只能当当时的读数**）。
#   ② 谓词的**域是「件路径身份」而不是「令牌拼写」**（`D-G132` 的根因）：
#      · `WIRING`：`verify-all.sh` 每条 `run_step "…"` 的 argv 抽**路径形态令牌** → `realpath -m`
#        归一到仓内绝对路径 → 再对**包装件做传递闭包**（深度 ≤ `--depth`，默认 3，带环守卫）。
#        成员判定 ＝ **归一后路径相等** ⇒ 步名字符串怎么拼、路径写成 `./a//b/c.sh`、经不经包装件，
#        判定都一样。
#      · `COPY-CENSUS`：取代者存在性／仓内同基名唯一性／枚举项数 == 声明件数／**语料枚举出的
#        每个车道**里副本首行点名取代者 —— **牙里零车道名**（车道从语料读回）。
#
#  【声明记录形态（写在语料里；行首装饰剥除后可被成对反引号／`**`／`<!--` 包裹）】
#      DECL-BOUNDARY: id=<id> family=<F> target=<仓内相对路径> expect=<E> key=<k>
#                     restates=<文件>#<令牌>[,<文件>#<令牌>…] [n=<N>] [enum-from=<文件>#<令牌>] [why=<文本>]
#      DECL-BOUNDARY-COUNT: <N>      ← 记录数声明（记录被删／解析不了 ⇒ 必须**响亮**）
#      DECL-BOUNDARY-BYSTANDERS: expect=<N>  ← **旁观上限**（见下"覆盖闭包"末条；缺行 ⇒ `FAIL`）
#  族：family=WIRING expect=unwired-in-step|wired ｜ family=COPY-CENSUS target=… n=… enum-from=… ｜
#      family=UNVERIFIABLE why=<非空>   ← `D-G132` 口径句的**降级通道**（逐条上屏、不算绿）
#
#  【覆盖闭包（`D-G132` 口径句的机械化：**没有谓词的声明必须被点名**）】
#  语料里**行首即声明位**的令牌 `key=SCREAMING-VALUE` 全部**普查**出来（结构识别、**无词表**）；
#  被**覆盖** ⟺ 某记录的 `restates` 含 `<文件基名>#<key>=<value>`（**内容锚**，不用行号）；
#  未被覆盖**且** key ∈「记录里 `key=` 字段声明的键集」（键集**来自语料**）⇒ **缺口** ⇒ 本步红并点名。
#  **旁观上限（`#76` 主控裁定；`D-G132` 残余洞的堵法）**：key 不在键集里的候选按上面的口径**上屏**
#  （`DECL_BYSTANDER`），但**数量必须有声明式上限** `DECL-BOUNDARY-BYSTANDERS: expect=<N>`，**零余量**对账：
#  超出 ⇒ `FAIL rule=bystander-tree-grown` 并把**超出那几处**逐条点名（`file`／`line`／`token`）。
#  口径：按（**语料路径 `LC_ALL=C` 排序，再按行号升序**）的**前 `expect` 条**视为已批准的合法旁观；
#  其后出现的一律红。⇒ 将来某一波新写一条边界声明**却不给谓词**，本步**当场红**（而不是"记录还在 ⇒ 照旧绿"）。
#  缺 `DECL-BOUNDARY-BYSTANDERS:` 行 ⇒ `FAIL reason=bystander-expect-absent`（**空边必须响亮失败**）。
#
#  ⚠️ **绿的依赖（如实写清，别让后来者以为"历史语料下它也绿"）**：本牙的 **`PASS` 依赖预登记语料里的
#  记录**（`DECL-BOUNDARY:` ＋ `DECL-BOUNDARY-COUNT:` ＋ `DECL-BOUNDARY-BYSTANDERS:`）。
#  **只有历史语料（未落本波预登记）时**：`records=0` ⇒ `FAIL reason=no-record-parsed`，
#  两条历史散文声明（`producer=UNWIRED-IN-STEP` 等）一律现形为 `DECL_BYSTANDER`（**可见、不静默**）。
#
#  【诚实的域边界（不许读宽）】
#   · 传递闭包**要求"命令形态"**（解释器位于命令位），且只扫仓内 `*.sh`／`*.py` ⇒
#     **靠变量间接的调用看不见**（`bash "$DIR/x.sh"`）：本牙对"接线"是**保守**的（可能漏判已接线），
#     而 `route=` 命中的**都是真路径**（不拿"提到了路径"冒充"调用了它"：白名单/字符串里的路径**不算**）。
#   · `COPY-CENSUS` 的外部部分只证「**语料枚举出的**车道里副本首行确实标了废」；**未枚举**的第三方
#     副本不在射程内；车道被回收 ⇒ `evaporated`（**如实不变红**：声明讲的是**当时那次标记行为**）。
#   · 本牙**不判**"这条声明在语义上该不该存在"，只判「**声明说的话与树上的形状是否一致**」。
#
#  【接线（`D-G136`：件头自述必须与代码形状一致）】**已接线** —— 本牙是 `verify-all.sh` 第 `BOUNDARY-DECL` 步的
#    **承重件**（步号**现取**，本文件任何位置**不写死**）；接线与覆盖面（`build/close-wave.sh` 的 `fp_inputs()`）
#    与四处声明**同趟**落。⇒ 件头**只**声明本牙**已接线**这一件事（`grep -c '^run_step "'` 现取可核）。
#
#  三态：`PASS=rc0` ／ `FAIL=rc1` ／ `NOINFO=rc3`（域取不到 ⇒ **NOINFO，不许当绿**）／ `2=用法错`
#  纯读、零 `dotnet`、**不写仓**；临时件走 `mktemp -d` ＋ `trap`（`D-G133`）。
#  机读行：`BOUNDARY_DECL=<PASS|FAIL|NOINFO> records=<n> pass=<n> fail=<n> noinfo=<n>
#          coverage=<covered>/<cand> gaps=<n> unverifiable=<n> corpus=<n> rc=<n>`
# ============================================================================
set -u
LC_ALL=C

SELF="$0"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DEFAULT="$(cd "$SELF_DIR/../../.." && pwd)"
REPO="$REPO_DEFAULT"
VFILE=""
HOME_ROOT="$HOME"
MAX_DEPTH=3
SELFTEST=0
declare -a CORPUS_PATHS=()

usage() {
  sed -n '2,58p' "$SELF" | sed -E 's/^# ?//'
  cat <<'USAGE'
用法：
  boundary-decl-check.sh [--repo DIR] [--verify-all PATH] [--home-root DIR]
                         [--corpus <相对仓根的glob或绝对路径>]... [--depth N] [--selftest]
默认语料：docs/WAVE*-PREREGISTRATION.md（**每次运行现取全量重扫**）
退出码：0=PASS ／ 1=FAIL ／ 3=NOINFO ／ 2=用法错
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)       REPO="${2:-}"; shift 2 ;;
    --verify-all) VFILE="${2:-}"; shift 2 ;;
    --home-root)  HOME_ROOT="${2:-}"; shift 2 ;;
    --corpus)     CORPUS_PATHS+=("${2:-}"); shift 2 ;;
    --depth)      MAX_DEPTH="${2:-}"; shift 2 ;;
    --selftest)   SELFTEST=1; shift ;;
    -h|--help)    usage; exit 2 ;;
    *) echo "boundary-decl-check.sh: 未知参数 '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

# ── 共用小工具 ───────────────────────────────────────────────────────────────
strip_dec()  { printf '%s' "$1" | sed -E 's/^([[:space:]>#*|!-]|⚠️|★|⇒|§|：|[0-9]|\.)+//' ; }
strip_wrap() { printf '%s' "$1" | sed -E 's/^[[:space:]]*[*`]+//' | sed -E 's/[*`]+[[:space:]]*$//' ; }
esc_re() { printf '%s' "$1" | sed 's/[.[\*^$()+?{}|]/\\&/g' ; }

path_norm() {  # <token> ⇒ 归一后的绝对路径（不要求存在）
  local t="$1"
  case "$t" in
    /*) realpath -m -- "$t" 2>/dev/null || printf '%s' "$t" ;;
    *)  realpath -m -- "$REPO/$t" 2>/dev/null || printf '%s' "$REPO/$t" ;;
  esac
}

# 调用闭包：**只扫仓内 `*.sh`／`*.py`**，且令牌必须出现在**命令形态**的行上
extract_script_tokens() {  # <file> ⇒ 非注释行里的路径形态脚本令牌
  grep -vE '^[[:space:]]*#' "$1" 2>/dev/null \
    | grep -oE '(^|[^A-Za-z0-9_$./+-])([A-Za-z0-9_./+-]+\.(sh|py))' 2>/dev/null | cut -c2- || true
}

invoked_tokens_in() {  # <file> ⇒ 该文件里**以命令形态被调用**的脚本令牌
  # 「命令形态」＝ ① 解释器位于命令位（行首／`;`／`&`／`|`／`(` 之后）的那一行上出现的令牌；
  #              ② 行首即路径形态脚本令牌（可执行脚本直调）。
  # ⇒ **提到路径不算调用**（白名单/字符串/注释里的路径一律**不算**）。
  local f="$1"
  { grep -E "(^|[;&|(])[[:space:]]*(bash|sh|python3|python|source|exec|\.)[[:space:]]+" "$f" 2>/dev/null
    grep -E "^[[:space:]]*[\`(]*[A-Za-z0-9_./+-]+\.(sh|py)" "$f" 2>/dev/null
  } | grep -oE '(^|[^A-Za-z0-9_$./+-])([A-Za-z0-9_./+-]+\.(sh|py))' 2>/dev/null | cut -c2- || true
}

# ── 自测 ─────────────────────────────────────────────────────────────────────
# 夹具一律用**合成名字**（`kk1`／`kk2`／`laneA`…／`build/probe/run-maker.sh`）⇒ **牙里不留任何
# 仓内具体件名、声明 id、语料键名**；同时**证明通用性**：换一条全新声明**不需要改牙**。
if [ "$SELFTEST" -eq 1 ]; then
  d="$(mktemp -d "${TMPDIR:-/tmp}/bdc-st.XXXXXX")" || exit 2
  trap 'rm -rf "$d"' EXIT
  tot=0; ok=0; bad=0
  mk() {  # mk <根> —— 造一棵最小树
    local r="$1"
    mkdir -p "$r/docs" "$r/build/tools" "$r/build/probe" "$r/build/other"
    cat > "$r/verify-all.sh" <<'V'
#!/usr/bin/env bash
run_step "ONE" bash build/tools/alpha.sh --x
run_step "TWO" bash build/tools/beta.sh
V
    printf '#!/usr/bin/env bash\ntrue\n' > "$r/build/tools/alpha.sh"
    printf '#!/usr/bin/env bash\ntrue\n' > "$r/build/tools/beta.sh"
    printf '#!/usr/bin/env bash\ntrue\n' > "$r/build/other/gamma.sh"
    printf '#!/usr/bin/env bash\n# 产出端\ntrue\n' > "$r/build/probe/run-maker.sh"
    cat > "$r/docs/WAVE41-PREREGISTRATION.md" <<'W'
## §3 边界声明
1. **`kk1=UNWIRED-IN-STEP`**：产出端仍在车道，没有任何一步调用它。
2. **`kk2=DEPRECATED×3`**：同形产出端里 **3 份**（`laneA`／`laneB`／`laneC`）标废。
W
    cat > "$r/docs/WAVE42-PREREGISTRATION.md" <<'W'
## §3 判据（落地前写死）
DECL-BOUNDARY-COUNT: 2
DECL-BOUNDARY-BYSTANDERS: expect=0

DECL-BOUNDARY: id=PRODUCER-UNWIRED family=WIRING target=build/probe/run-maker.sh expect=unwired-in-step key=kk1 restates=WAVE41-PREREGISTRATION.md#kk1=UNWIRED-IN-STEP

DECL-BOUNDARY: id=COPIES-DEPRECATED family=COPY-CENSUS target=build/probe/run-maker.sh n=3 enum-from=WAVE41-PREREGISTRATION.md#kk2=DEPRECATED×3 key=kk2 restates=WAVE41-PREREGISTRATION.md#kk2=DEPRECATED×3
W
  }
  mk_lanes() {  # mk_lanes <home>：3 条已标废车道 ＋ 1 条**留档不标**的车道
    local h="$1" lane
    for lane in laneA laneB laneC; do
      mkdir -p "$h/$lane/bin"
      printf '# DEPRECATED-BY=run-maker.sh (W99)\ntrue\n' > "$h/$lane/bin/leg.sh"
    done
    mkdir -p "$h/laneD/bin"
    printf '#!/usr/bin/env bash\ntrue\n' > "$h/laneD/bin/keep.sh"
  }
  run_leg() {  # run_leg <名字> <期望rc> <期望令牌> <mini根> <home根>
    local name="$1" want="$2" tok="$3" r="$4" h="$5" out rc v="OK"
    out="$(bash "$SELF" --repo "$r" --home-root "$h" --corpus 'docs/WAVE*-PREREGISTRATION.md' 2>&1)"; rc=$?
    tot=$((tot+1))
    [ "$rc" -eq "$want" ] || v="BAD(rc=$rc want=$want)"
    if [ -n "$tok" ] && ! printf '%s\n' "$out" | grep -qF -- "$tok"; then v="$v:BAD(token-missing)"; fi
    if [ "$v" = "OK" ]; then ok=$((ok+1)); else bad=$((bad+1)); fi
    echo "BDC_LEG=$v name=$name rc=$rc want=$want"
    [ "$v" = "OK" ] || printf '%s\n' "$out" | sed -n '1,10p' | sed 's/^/    | /'
  }
  # L1 正极
  r="$d/L1"; mk "$r"; mk_lanes "$d/home1"
  run_leg pos 0 'BOUNDARY_DECL=PASS' "$r" "$d/home1"
  # L2 反①a 直调（步名漂移 ＋ 路径形态 `./build//…`）
  r="$d/L2"; mk "$r"; mk_lanes "$d/home2"
  printf 'run_step "MAKER-ANYSPELLING" bash ./build//probe/run-maker.sh --pair\n' >> "$r/verify-all.sh"
  run_leg neg-direct 1 'route=direct' "$r" "$d/home2"
  # L3 反①b 经包装件调用
  r="$d/L3"; mk "$r"; mk_lanes "$d/home3"
  printf '#!/usr/bin/env bash\nbash build/probe/run-maker.sh "$@"\n' > "$r/build/tools/wrap.sh"
  printf 'run_step "WRAPPED" bash build/tools/wrap.sh --pair\n' >> "$r/verify-all.sh"
  run_leg neg-wrapper 1 'route=transitive' "$r" "$d/home3"
  # L4 反② target 不存在 ⇒ NOINFO（防恒挂）
  r="$d/L4"; mk "$r"; mk_lanes "$d/home4"
  sed -i 's#target=build/probe/run-maker.sh expect=unwired-in-step#target=build/nope/run-maker.sh expect=unwired-in-step#' "$r/docs/WAVE42-PREREGISTRATION.md"
  run_leg neg-absent 3 'DECL_RECORD=NOINFO' "$r" "$d/home4"
  # L5 反③ 语料加一条**新**记录（**不动牙**）⇒ 证通用性
  r="$d/L5"; mk "$r"; mk_lanes "$d/home5"
  sed -i 's/^DECL-BOUNDARY-COUNT: 2/DECL-BOUNDARY-COUNT: 3/' "$r/docs/WAVE42-PREREGISTRATION.md"
  printf 'DECL-BOUNDARY: id=NEW-CLAIM family=WIRING target=build/tools/alpha.sh expect=unwired-in-step key=brand-new-key restates=zz.md#x=Y\n' >> "$r/docs/WAVE42-PREREGISTRATION.md"
  run_leg neg-new-record 1 'id=NEW-CLAIM' "$r" "$d/home5"
  # L6 反④ 删一条记录（COUNT 不改）
  r="$d/L6"; mk "$r"; mk_lanes "$d/home6"
  sed -i '/id=COPIES-DEPRECATED/d' "$r/docs/WAVE42-PREREGISTRATION.md"
  run_leg neg-count 1 'record-count-mismatch' "$r" "$d/home6"
  # L7 反⑤ 未覆盖且键在键集内的声明
  r="$d/L7"; mk "$r"; mk_lanes "$d/home7"
  printf '3. **`kk1=ANOTHER-VALUE`**：这条声明没有记录去求值它。\n' >> "$r/docs/WAVE41-PREREGISTRATION.md"
  run_leg neg-uncovered 1 'declaration-without-predicate' "$r" "$d/home7"
  # L8 反⑥ 车道副本未标废
  r="$d/L8"; mk "$r"; mk_lanes "$d/home8"
  printf '#!/usr/bin/env bash\ntrue\n' > "$d/home8/laneB/bin/leg.sh"
  run_leg neg-unmarked 1 'lane-unmarked' "$r" "$d/home8"
  # L9 反⑦ 车道整条不存在 ⇒ evaporated，**仍 PASS**
  r="$d/L9"; mk "$r"; mk_lanes "$d/home9"; rm -rf "$d/home9/laneC"
  run_leg neg-evaporated 0 'evaporated' "$r" "$d/home9"
  # L10 反⑧ 零记录 ⇒ 必红（纪律 5）
  r="$d/L10"; mk "$r"; mk_lanes "$d/home10"
  : > "$r/docs/WAVE42-PREREGISTRATION.md"
  run_leg neg-no-record 1 'no-record-parsed' "$r" "$d/home10"
  # L11 bystander 在**上限内** ⇒ 上屏、不进 rc（上限显式声明为 1）
  r="$d/L11"; mk "$r"; mk_lanes "$d/home11"
  sed -i 's/^DECL-BOUNDARY-BYSTANDERS: expect=0/DECL-BOUNDARY-BYSTANDERS: expect=1/' "$r/docs/WAVE42-PREREGISTRATION.md"
  printf '> `zzz=ZZZ-VALUE` 这条不是已知边界声明键。\n' >> "$r/docs/WAVE41-PREREGISTRATION.md"
  run_leg pos-bystander 0 'DECL_BYSTANDER idx=1' "$r" "$d/home11"
  # L12 反⑨ 旁观**超出上限** ⇒ 必红＋点名（`bystander-tree-grown`）
  r="$d/L12"; mk "$r"; mk_lanes "$d/home12"
  printf '> `zzz=ZZZ-VALUE` 合法旁观一条。\n' >> "$r/docs/WAVE41-PREREGISTRATION.md"
  sed -i 's/^DECL-BOUNDARY-BYSTANDERS: expect=0/DECL-BOUNDARY-BYSTANDERS: expect=1/' "$r/docs/WAVE42-PREREGISTRATION.md"
  printf '> `qqq=QQQ-VALUE` 又一波新写的边界声明**却没有谓词**。\n' >> "$r/docs/WAVE41-PREREGISTRATION.md"
  run_leg neg-bystander-grown 1 'rule=bystander-tree-grown' "$r" "$d/home12"
  # L13 反⑩ 缺旁观上限声明行 ⇒ 必红（空边必须响亮失败）
  r="$d/L13"; mk "$r"; mk_lanes "$d/home13"
  sed -i '/^DECL-BOUNDARY-BYSTANDERS:/d' "$r/docs/WAVE42-PREREGISTRATION.md"
  run_leg neg-bystander-absent 1 'reason=bystander-expect-absent' "$r" "$d/home13"
  echo "BDC-SELFTEST=$( [ "$bad" -eq 0 ] && echo PASS || echo FAIL ) cases=$tot pass=$ok fail=$bad"
  [ "$bad" -eq 0 ] || exit 1
  exit 0
fi

# ── 前置 ─────────────────────────────────────────────────────────────────────
[[ -d "$REPO" ]] || { echo "BOUNDARY_DECL=NOINFO reason=repo-absent repo=$REPO"; exit 3; }
VFILE="${VFILE:-$REPO/verify-all.sh}"
[[ -f "$VFILE" ]] || { echo "BOUNDARY_DECL=NOINFO reason=verify-all-absent file=$VFILE"; exit 3; }
[[ -d "$HOME_ROOT" ]] || { echo "BOUNDARY_DECL=NOINFO reason=home-root-absent dir=$HOME_ROOT"; exit 3; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/bdc-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# ── ① 语料现取（`D-G140`：清单数 ＋ digest ＋ 时刻；**每次重扫**）──────────────
if [ "${#CORPUS_PATHS[@]}" -eq 0 ]; then
  CORPUS_PATHS=("docs/WAVE*-PREREGISTRATION.md")
fi
: > "$WORK/corpus.list"
for pat in "${CORPUS_PATHS[@]}"; do
  if [[ "$pat" = /* ]]; then
    for f in $pat; do [ -f "$f" ] && printf '%s\n' "$f" >> "$WORK/corpus.list"; done
  else
    for f in "$REPO"/$pat; do [ -f "$f" ] && printf '%s\n' "$f" >> "$WORK/corpus.list"; done
  fi
done
LC_ALL=C sort -u -o "$WORK/corpus.list" "$WORK/corpus.list"
CORPUS_N="$(wc -l < "$WORK/corpus.list" | tr -d ' ')"
CORPUS_NOW="$(date '+%F %T %z')"
CORPUS_DIGEST="$(while IFS= read -r f; do printf '%s:%s\n' "$(basename "$f")" "$(sha256sum "$f" | cut -c1-16)"; done < "$WORK/corpus.list" | sha256sum | cut -c1-16)"
echo "DECL_CORPUS files=$CORPUS_N at=$CORPUS_NOW digest=$CORPUS_DIGEST"
if [ "$CORPUS_N" -eq 0 ]; then
  echo "BOUNDARY_DECL=FAIL reason=empty-corpus"
  echo "  ∟ 零检查**不许**算绿（纪律 5）"
  exit 1
fi

# ── ② 记录与候选解析（**全部字段从语料读回**；单趟 awk，**不是**每行起进程）──
: > "$WORK/records.tsv"; : > "$WORK/cand.tsv"; : > "$WORK/restates.txt"; : > "$WORK/count.txt"; : > "$WORK/byst.txt"
cat > "$WORK/deco.awk" <<'AWK'
# 行首装饰剥除（**迭代到稳定**，覆盖任意组合顺序）：空白／`>`／`#`／列表符／`|`／`!`／`-`／
# 有序列表序号／`<!--`／成对行内代码定界符／粗体。**只认成对包裹**（首尾同时是反引号/星号）。
function deco(s,   i) {
  for (i = 0; i < 5; i++) {
    sub(/^[ \t>#*|!-]+/, "", s)
    sub(/^([0-9]+\.)+[ \t]*/, "", s)
    sub(/^<!--[ \t]*/, "", s)
  }
  sub(/[ \t]*-->$/, "", s)
  sub(/[*`]+[ \t]*$/, "", s)
  sub(/^[*`]+/, "", s)
  return s
}
AWK
cat > "$WORK/parse.awk" <<'AWK'
{
  s = deco($0)
  if (s ~ /^DECL-BOUNDARY:/) {
    body = s; sub(/^DECL-BOUNDARY:/, "", body)
    printf "%s\t%d\t%s\n", F, FNR, body >> RECF
    n = split(body, kv, /[ \t]+/)
    for (i = 1; i <= n; i++) if (kv[i] ~ /^restates=/) {
      v = kv[i]; sub(/^restates=/, "", v)
      m = split(v, rr, ",")
      for (j = 1; j <= m; j++) if (rr[j] != "") print rr[j] >> RESF
    }
    next
  }
  if (s ~ /^DECL-BOUNDARY-BYSTANDERS:/) {
    v = s; sub(/^DECL-BOUNDARY-BYSTANDERS:/, "", v); gsub(/[ \t]/, "", v)
    sub(/^expect=/, "", v)
    if (v != "") print v >> BYSF
    next
  }
  if (s ~ /^DECL-BOUNDARY-COUNT:/) {
    v = s; sub(/^DECL-BOUNDARY-COUNT:/, "", v); gsub(/[ \t]/, "", v)
    if (v != "") print v >> CNTF
    next
  }
  if (match(s, /^[a-z][a-z0-9-]*=[A-Z][A-Z0-9-]*/)) {
    k = substr(s, RSTART, RLENGTH); sub(/=.*/, "", k)
    val = substr(s, RSTART, RLENGTH); sub(/^[^=]*=/, "", val)
    rest = substr(s, RLENGTH + 1)
    if (rest ~ /^×[0-9]/) { num = rest; sub(/^×/, "", num); sub(/[^0-9].*$/, "", num); val = val "×" num }
    printf "%s\t%d\t%s\t%s\t%s\n", F, FNR, k, val, k "=" val >> CANDF
  }
}
AWK
cat > "$WORK/anchor.awk" <<'AWK'
{ s = deco($0); if (index(s, tok) == 1) { print; exit } }
AWK
while IFS= read -r f; do
  awk -v F="$(basename "$f")" -v RECF="$WORK/records.tsv" -v RESF="$WORK/restates.txt" \
      -v CNTF="$WORK/count.txt" -v CANDF="$WORK/cand.tsv" -v BYSF="$WORK/byst.txt" \
      -f "$WORK/deco.awk" -f "$WORK/parse.awk" "$f"
done < "$WORK/corpus.list"
COUNT_DECL="$(head -1 "$WORK/count.txt" 2>/dev/null || true)"
BYST_EXPECT="$(head -1 "$WORK/byst.txt" 2>/dev/null || true)"
REC_OBS="$(wc -l < "$WORK/records.tsv" | tr -d ' ')"
echo "DECL_RECORDS decl=${COUNT_DECL:-<absent>} obs=$REC_OBS"

# ── ③ 调用闭包（直接 ＋ 经包装件传递；只认命令形态；只扫仓内 sh/py）──────────
: > "$WORK/direct.raw"
sed -nE 's/^[[:space:]]*run_step[[:space:]]+"[^"]*"[[:space:]]*//p' "$VFILE" > "$WORK/argv.txt"
extract_script_tokens "$WORK/argv.txt" > "$WORK/direct.tok" || true
while IFS= read -r t; do
  [ -n "$t" ] || continue
  case "$t" in *.sh|*.py) path_norm "$t" ;; esac
done < "$WORK/direct.tok" >> "$WORK/direct.raw"
LC_ALL=C sort -u -o "$WORK/direct.raw" "$WORK/direct.raw"
cp -f "$WORK/direct.raw" "$WORK/closure.txt"
cp -f "$WORK/direct.raw" "$WORK/frontier.txt"
depth_used=0
while [ "$depth_used" -lt "$MAX_DEPTH" ] && [ -s "$WORK/frontier.txt" ]; do
  : > "$WORK/next.all"
  while IFS= read -r p; do
    case "$p" in "$REPO"/*.sh|"$REPO"/*.py) ;; *) continue ;; esac
    [ -f "$p" ] || continue
    invoked_tokens_in "$p" > "$WORK/toks.$$" || true
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      case "$t" in *.sh|*.py) path_norm "$t" >> "$WORK/next.all" ;; esac
    done < "$WORK/toks.$$"
  done < "$WORK/frontier.txt"
  rm -f "$WORK/toks.$$"
  LC_ALL=C sort -u -o "$WORK/next.all" "$WORK/next.all"
  : > "$WORK/next.keep"
  while IFS= read -r p; do
    case "$p" in "$REPO"/*) ;; *) continue ;; esac
    grep -F -x -q -- "$p" "$WORK/closure.txt" 2>/dev/null && continue
    printf '%s\n' "$p" >> "$WORK/next.keep"
  done < "$WORK/next.all"
  LC_ALL=C sort -u -o "$WORK/next.keep" "$WORK/next.keep"
  cat "$WORK/next.keep" >> "$WORK/closure.txt"
  LC_ALL=C sort -u -o "$WORK/closure.txt" "$WORK/closure.txt"
  cp -f "$WORK/next.keep" "$WORK/frontier.txt"
  depth_used=$((depth_used+1))
done
CLOSURE_N="$(wc -l < "$WORK/closure.txt" | tr -d ' ')"
echo "DECL_CLOSURE members=$CLOSURE_N max_depth=$MAX_DEPTH used=$depth_used"

wiring_eval() {  # <target-rel> <expect> ⇒ 读数 ＋ rc
  local target="$1" expect="$2" tp route=""
  tp="$(path_norm "$target")"
  [ -f "$tp" ] || { echo "NOINFO target-absent"; return 3; }
  if grep -F -x -q -- "$tp" "$WORK/closure.txt" 2>/dev/null; then
    if grep -F -x -q -- "$tp" "$WORK/direct.raw" 2>/dev/null; then route="direct"; else route="transitive"; fi
  fi
  case "$expect" in
    unwired-in-step)
      [ -n "$route" ] && { echo "FAIL route=$route"; return 1; }
      echo "PASS route=none n_closure=$CLOSURE_N"; return 0 ;;
    wired)
      [ -z "$route" ] && { echo "FAIL route=none"; return 1; }
      echo "PASS route=$route"; return 0 ;;
    *) echo "FAIL unknown-expect=$expect"; return 1 ;;
  esac
}

copy_census_eval() {  # <target-rel> <n> <enum-from>
  local target="$1" nd="$2" enumfrom="$3" tp sbase ef_file ef_tok src="" blob=""
  tp="$(path_norm "$target")"; sbase="$(basename "$target")"
  [ -f "$tp" ] || { echo "FAIL successor-absent"; return 1; }
  local twins
  twins="$(find "$REPO" -type f -name "$sbase" 2>/dev/null | wc -l | tr -d ' ')"
  [ "$twins" -eq 1 ] || { echo "FAIL in-repo-twin n=$twins"; return 1; }
  ef_file="${enumfrom%%#*}"; ef_tok="${enumfrom#*#}"
  while IFS= read -r cpath; do
    [ -f "$cpath" ] || continue
    src="$(awk -v tok="$ef_tok" -f "$WORK/deco.awk" -f "$WORK/anchor.awk" "$cpath")"
    [ -n "$src" ] && break
  done < <(grep -F -- "$ef_file" "$WORK/corpus.list" 2>/dev/null || true)
  [ -n "$src" ] || { echo "NOINFO enum-anchor-not-found token=$ef_tok"; return 3; }
  blob="$(printf '%s' "$src" | sed -E 's/^[^（]*（([^）]*)）.*$/\1/')"
  local entries n_entries
  entries="$(printf '%s' "$blob" | tr '／' '\n' | sed -E 's/^\*+//; s/\*+$//; s/^[[:space:]`]+//; s/[[:space:]`]+$//' | grep -v '^$' || true)"
  n_entries="$(printf '%s\n' "$entries" | grep -c . || true)"
  [ "$n_entries" -eq "$nd" ] || { echo "FAIL enum-count-mismatch declared=$nd enumerated=$n_entries"; return 1; }
  local lane evap=0 unmarked=0 marked=0 detail=""
  while IFS= read -r lane; do
    [ -n "$lane" ] || continue
    lane="$(printf '%s' "$lane" | tr ' ' '/')"
    local ldir="$HOME_ROOT/$lane"
    if [ ! -d "$ldir" ]; then evap=$((evap+1)); detail="$detail $lane=evaporated"; continue; fi
    local m=0
    while IFS= read -r cf; do
      case "$(head -1 "$cf" 2>/dev/null || true)" in
        *DEPRECATED-BY=*"$sbase"*) m=$((m+1)) ;;
      esac
    done < <(grep -rIl -F --include='*.sh' --include='*.py' -e 'DEPRECATED-BY=' "$ldir" 2>/dev/null || true)
    if [ "$m" -ge 1 ]; then marked=$((marked+1)); detail="$detail $lane=marked($m)"
    else unmarked=$((unmarked+1)); detail="$detail $lane=UNMARKED"; fi
  done <<< "$entries"
  [ "$unmarked" -eq 0 ] || { echo "FAIL lane-unmarked n=$unmarked$detail"; return 1; }
  [ "$marked" -gt 0 ] || { echo "NOINFO corpus-evaporated$detail"; return 3; }
  echo "PASS marked=$marked evaporated=$evap$detail"; return 0
}

# ── ④ 逐记录求值 ─────────────────────────────────────────────────────────────
n_pass=0; n_fail=0; n_noinfo=0; n_unver=0
: > "$WORK/keys.txt"
if [ "$REC_OBS" -gt 0 ]; then
  while IFS=$'\t' read -r rfile rline rbody; do
    [ -n "${rbody:-}" ] || continue
    rid=""; rfam=""; rtgt=""; rexp=""; rkey=""; rn=""; ren=""; rwhy=""
    for kv in $rbody; do
      case "$kv" in
        id=*)        rid="${kv#id=}" ;;
        family=*)    rfam="${kv#family=}" ;;
        target=*)    rtgt="${kv#target=}" ;;
        expect=*)    rexp="${kv#expect=}" ;;
        key=*)       rkey="${kv#key=}"; printf '%s\n' "$rkey" >> "$WORK/keys.txt" ;;
        n=*)         rn="${kv#n=}" ;;
        enum-from=*) ren="${kv#enum-from=}" ;;
        why=*)       rwhy="${kv#why=}" ;;
      esac
    done
    rid="${rid:-<no-id>}"; obs=""; pred_rc=0
    case "$rfam" in
      WIRING)      obs="$(wiring_eval "$rtgt" "$rexp")"; pred_rc=$? ;;
      COPY-CENSUS) obs="$(copy_census_eval "$rtgt" "$rn" "$ren")"; pred_rc=$? ;;
      UNVERIFIABLE)
        if [ -z "${rwhy:-}" ]; then obs="FAIL why-empty"; pred_rc=1
        else obs="PASS why=$rwhy"; pred_rc=0; n_unver=$((n_unver+1)); fi ;;
      *) obs="FAIL unknown-family=${rfam:-<absent>}"; pred_rc=1 ;;
    esac
    case "$pred_rc" in
      0) echo "DECL_RECORD=PASS id=$rid family=$rfam target=$rtgt obs=$obs"; n_pass=$((n_pass+1)) ;;
      3) echo "DECL_RECORD=NOINFO id=$rid family=$rfam target=$rtgt obs=$obs"; n_noinfo=$((n_noinfo+1)) ;;
      *) echo "DECL_RECORD=FAIL id=$rid family=$rfam target=$rtgt obs=$obs found-in=$rfile:$rline"; n_fail=$((n_fail+1)) ;;
    esac
  done < "$WORK/records.tsv"
fi
LC_ALL=C sort -u -o "$WORK/keys.txt" "$WORK/keys.txt" 2>/dev/null || : > "$WORK/keys.txt"

# ── ⑤ 覆盖闭包（普查 ＋ 缺口点名）─────────────────────────────────────────────
n_cand=0; n_cover=0; n_by=0; n_gap=0; n_by_over=0
if [ -s "$WORK/cand.tsv" ]; then
  while IFS=$'\t' read -r cfile cline ckey cval ctok; do
    n_cand=$((n_cand+1))
    if grep -F -x -q -- "$cfile#$ctok" "$WORK/restates.txt" 2>/dev/null; then n_cover=$((n_cover+1)); continue; fi
    if grep -F -x -q -- "$ckey" "$WORK/keys.txt" 2>/dev/null; then
      n_gap=$((n_gap+1)); echo "DECL_GAP=FAIL rule=declaration-without-predicate file=$cfile line=$cline token=$ctok"
    else
      n_by=$((n_by+1))
      # **旁观上限**：前 `expect` 条（语料路径排序＋行号升序）视为已批准；其后一律红并点名
      if [ -n "$BYST_EXPECT" ] && [ "$n_by" -gt "$BYST_EXPECT" ]; then
        n_by_over=$((n_by_over+1))
        echo "DECL_BYSTANDER=FAIL rule=bystander-tree-grown idx=$n_by expect=$BYST_EXPECT file=$cfile line=$cline token=$ctok"
      else
        echo "DECL_BYSTANDER idx=$n_by file=$cfile line=$cline token=$ctok"
      fi
    fi
  done < "$WORK/cand.tsv"
fi
echo "DECL_CENSUS candidates=$n_cand covered=$n_cover bystanders=$n_by expect=${BYST_EXPECT:-<absent>} over=$n_by_over gaps=$n_gap keys=$(tr '\n' ',' < "$WORK/keys.txt" | sed 's/,$//')"
echo "DECL_UNVERIFIABLE n=$n_unver"

# ── ⑥ 三态汇总 ───────────────────────────────────────────────────────────────
rc=0; verdict="PASS"; reason=""
# **全部不成立的条件都进 reason**（有红先红，但**不吞**别的红：诊断要能同时看见多条）
declare -a reasons=()
[ -n "$BYST_EXPECT" ] || { echo "DECL_BYSTANDERS=FAIL rule=bystander-expect-absent expected=DECL-BOUNDARY-BYSTANDERS:expect=<n>"; reasons+=("bystander-expect-absent"); }
[ "$n_by_over" -gt 0 ] && reasons+=("bystander-tree-grown(over=$n_by_over expect=$BYST_EXPECT)")
[ "$REC_OBS" -eq 0 ] && reasons+=("no-record-parsed")
if [ -n "$COUNT_DECL" ] && [ "$COUNT_DECL" != "$REC_OBS" ]; then reasons+=("record-count-mismatch(decl=$COUNT_DECL obs=$REC_OBS)"); fi
[ "$n_cover" -eq 0 ] && reasons+=("zero-covered-candidate")
[ "$n_fail" -gt 0 ] && reasons+=("record-failure(fail=$n_fail)")
[ "$n_gap" -gt 0 ] && reasons+=("coverage-gap(gaps=$n_gap)")
if [ "${#reasons[@]}" -gt 0 ]; then
  verdict="FAIL"; rc=1; reason=" reason=$(IFS=,; printf '%s' "${reasons[*]}")"
elif [ "$n_noinfo" -gt 0 ]; then
  verdict="NOINFO"; rc=3; reason=" reason=record-noinfo"
fi
echo "BOUNDARY_DECL=$verdict records=$REC_OBS pass=$n_pass fail=$n_fail noinfo=$n_noinfo coverage=$n_cover/$n_cand gaps=$n_gap bystanders=$n_by expect=${BYST_EXPECT:-<absent>} unverifiable=$n_unver corpus=$CORPUS_N rc=$rc$reason"
exit "$rc"
