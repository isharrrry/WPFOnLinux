#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# lane-path-check.sh —— 「**落地件的默认路径不许指向任何车道目录**」牙（`TASK-0737`／`D-G137`）
#
# 【它挡的是什么】
#   从车道沙箱「提升」为**仓内件**的工具，默认读/写路径仍指向它出生的那条车道
#   （现场：`backup-completeness-gate.sh` 原实件默认输出目录写死 `~/w163a/`）⇒
#   落仓后每次运行都往**别人的目录**写证据/中间件 ⇒ 跨车道写入、证据与读数脱钩。
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）】
#   rc=0  `LANEPATH=PASS`     逐件都判到 ∧ 无 `code` 命中 ∧ 所有 `comment`/`data` 命中**都已声明**
#   rc=1  `LANEPATH=FAIL`     逐处点名（见下表）
#   rc=3  `LANEPATH=NOINFO`   算不出：扫描集为空／出处清单缺席或不可读／清单表头不认（**空边必须响亮失败**）
#
#   | 情形 | 判词 | 理由 |
#   |---|---|---|
#   | 命中在**可执行行**（非注释、非数据块） | **`FAIL rule=code-default-lane-path`** | 这正是 `D-G137` 的**本体**；`code` **永不许豁免**（清单里写了也照样红 ⇒ `rule=code-not-exemptible`） |
#   | 命中在**注释行**且已声明 | `kind=comment declared=yes`，**不判红** | 注释是**引用/出处**（如 `wm-awaited.sh` 的判据原文路径），判红会**逼人删掉判据出处** |
#   | 命中在**数据块**（多行单引号赋值内的登记表）且已声明 | `kind=data declared=yes`，**不判红** | 仓外装置根/孪生/夹具的**登记数据**——它们按设计就指向仓外车道 |
#   | `comment`/`data` 命中**未声明** | **`FAIL rule=undeclared-lane-path-mention`** | 豁免走 (乙)：**声明式出处清单 ＋ 每类件数上限**（逼后来者显式声明） |
#   | 清单声明的上限 `<` 现读件数 | **`FAIL rule=provenance-tree-grown`** | 与 `repo-alias-allow.tsv` 同口径：**上限＝现读件数 ⇒ 树长大也红** |
#
#   ⚠️ **三类分档必须逐处上屏**（`LANEPATH_HIT kind=code|comment|data file=… line=… declared=yes|no`）——
#      「不判红」不等于「不吭声」。
#
# 【判据的输入来源声明（纪律 36，**现取不缓存**）】
#   · **扫描集** = `<root>/build/MilBridge/tools/*.sh` ＋ `<root>/build/MilBridge/tests/**` 下的**代码件**
#     （`*.sh`／`*.py`）。⚠️ **不扫证据/台账**（`*.env`／`*.log`／`*.tsv`／`*.txt`／`*.png`）：那些是**取证内容**，
#     里面写着车道路径是**历史事实**，改了就是**篡改证据**。
#   · **命中** = 该行命中 ERE `(\$HOME|\$\{HOME\}|/home/links-dev)/w[0-9]+a`。
#   · **分档** = 逐行状态机：行首（去空白）`#` ⇒ `comment`；否则若处于**多行单引号赋值块**内
#     （`^\s*NAME='` 开、行尾 `'` 闭）⇒ `data`；其余 ⇒ `code`。
#   · ⚠️ **扫描集不含声明清单自身**（`lane-path-provenance.tsv` 在 `build/MilBridge/`，不在 `tools/`／`tests/`）：
#     它是**豁免声明**（`why` 列必须能点名它豁免的是哪条车道路径）⇒ 扫它就是把豁免机制本身判红。
#     它同趟**进覆盖面** ⇒ 任何改动都会移动 `inputs_fp`（**可见**，不是暗改）。
#   · **出处清单** = `build/MilBridge/lane-path-provenance.tsv`（同级目录，随件入覆盖面）：
#     表头逐字 `kind<TAB>file<TAB>max_hits<TAB>why`；`max_hits` 是**上限**（不是等号）。
#   · ★ **`# RETIRED` 记录（`#75` 主控裁定加）**：本波把三处**真默认值**改掉之后，其中一处
#     （`hidden-only-step.sh` 的 `HIDDEN_ONLY_OLDPC` 兜底）连带**丢掉 3 条夹具** ⇒ `[19]` 的射程
#     **缩减**（`skip=3`）。裁定要求"**出处必须记下来，将来谁重建了那个产物，射程即可恢复**" ⇒
#     本件认一种**机读**记录形态（清单里以 `#` 起头 ⇒ 不进豁免计数，但**必须形状合法**）：
#       `# RETIRED<TAB>kind<TAB>file<TAB>what<TAB>where<TAB>who<TAB>when<TAB>restore`
#     判据：形状不合法（字段数 < 8／`kind` 不在 `{code,comment,data}`／任一字段为空）⇒
#     **`FAIL reason=retired-record-malformed`**；合法则逐条上屏 ＋ 计数 `LANEPATH_RETIRED n=`。
#     ⚠️ 它**不参与** `rc` 的"件数上限"那一支（它是**已退役**的记录，不是现行豁免）。
#
# 【本牙自己的接线状态（**必须字面写在件头**：本牙判「件头自述 vs 接线」的对手牙会读它）】
#   **已接线**：`verify-all.sh` 的 `run_step "LANE-PATH" bash build/MilBridge/tools/lane-path-check.sh`
#   ——⚠️ **本注释不写步号**：以现场 `verify-all.sh` 的**步序**为准（写死步号 = 下一条会漂移的陈旧自述）。
#
# 【测试钩子】`--selftest`：自带 fixture（零 `X`、零 `dotnet`、零 `$R` 依赖），三档 ＋ 空边 ＋ 防假绿。
#   用法：bash lane-path-check.sh [--root DIR] [--provenance PATH] [--selftest]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
RC_PASS=0; RC_FAIL=1; RC_NOINFO=3
# 命中 ERE（**唯一字样来源**，见件头「输入来源声明」）
LP_NEEDLE='(\$HOME|\$\{HOME\}|/home/links-dev)/w[0-9]+a'
LP_PATFILE=""

classify_hits() {  # classify_hits <file> ⇒ 每行 `lineno<TAB>kind`
  # 分档状态机（**机制，不是启发式**）：
  #   ① 行首（去空白）`#` ⇒ `comment`；
  #   ② shell 的**多行单引号赋值块**（`^\s*NAME='` 且该行此后**再没有** `'` ⇒ 开块，到含收尾 `'` 的行止）
  #      内的行 ⇒ `data`（现场：`hygiene-tooth.sh` 的三张登记表 `HYG_*_ML='…'`）；
  #   ③ `.py` 的**三引号 docstring** 内的行 ⇒ `comment`（现场：`navclick.py` 的说明块）；
  #   ④ 其余 ⇒ `code`。
  local mode="sh"; case "$1" in *.py) mode="py" ;; esac
  awk -v pf="$LP_PATFILE" -v mode="$mode" '
    BEGIN{ pat=""; while ((getline l < pf) > 0) pat = pat l; inblk=0; intq=0;
           q1=sprintf("%c", 39); q3=sprintf("%c%c%c", 39, 39, 39); d3="\"\"\"" }
    {
      s=$0; sub(/^[ \t]+/, "", s); kind="code"
      if (mode == "py") {
        if (intq) kind="comment"
        else if (s ~ /^#/) kind="comment"
      } else {
        if (s ~ /^#/) kind="comment"
        else if (inblk) kind="data"
      }
      if (mode == "py") {
        n1=split($0, a1, d3); n2=split($0, a2, q3)
        c1=n1-1; c2=n2-1
        if (c1 > 0)      { if (c1 % 2 == 1) intq = 1 - intq }
        else if (c2 > 0) { if (c2 % 2 == 1) intq = 1 - intq }
      } else {
        if (!inblk) {
          # `NAME=` 后紧跟单引号，且余文里再没有引号 ⇒ 开块（**动态正则 + index()**：
          # 避开 shell 单引号与 awk 正则的**双重引号地狱** —— 本件第一版正因它把正则写成了两枚引号）
          if (s ~ ("^[A-Za-z_][A-Za-z0-9_]*=" q1)) {
            r=s; sub(("^[A-Za-z_][A-Za-z0-9_]*=" q1), "", r)
            if (index(r, q1) == 0) inblk=1
          }
        } else {
          if (index(s, q1) > 0) inblk=0
        }
      }
      if (pat != "" && $0 ~ pat) printf "%d\t%s\n", NR, kind
    }' "$1"
}

read_prov() {  # read_prov <path> ⇒ 每行 `kind<TAB>file<TAB>max_hits<TAB>why`（跳过表头/注释）
  awk -F'\t' 'NR==1 && $1=="kind" {next} /^[[:space:]]*#/ {next} NF>=3 && $1!="" {print}' "$1"
}

check_root() {  # check_root <root> <prov>；印逐处行 ＋ 机读行；返回 rc
  local root="$1" prov="$2"
  local -a scan=()
  local f
  for f in "$root"/build/MilBridge/tools/*.sh; do [ -f "$f" ] && scan+=("$f"); done
  while IFS= read -r f; do [ -n "$f" ] && scan+=("$f"); done < <(
    find "$root/build/MilBridge/tests" -type f \( -name '*.sh' -o -name '*.py' \) 2>/dev/null | LC_ALL=C sort)
  if [ "${#scan[@]}" -eq 0 ]; then
    echo "LANEPATH=NOINFO reason=scan-set-empty glob=$root/build/MilBridge/{tools/*.sh,tests/**/*.sh,*.py}"
    echo "LANEPATH_NOTE 空扫描集 ⇒ **算不出**（既不算绿也不算红）"
    return $RC_NOINFO
  fi
  if [ ! -r "$prov" ]; then
    echo "LANEPATH=NOINFO reason=provenance-absent path=$prov"
    echo "LANEPATH_NOTE 出处清单缺席 ⇒ **算不出**（豁免机制不在 ⇒ 不许静默给绿）"
    return $RC_NOINFO
  fi
  if [ "$(head -1 "$prov" | cut -f1)" != "kind" ]; then
    echo "LANEPATH=NOINFO reason=provenance-header-unknown path=$prov head=$(head -1 "$prov" | cut -c1-40)"
    echo "LANEPATH_NOTE 清单表头不认（须逐字以 kind<TAB>file<TAB>max_hits<TAB>why 起）⇒ **算不出**"
    return $RC_NOINFO
  fi

  # ── ★ `# RETIRED` 记录：形状必须合法（**出处不许丢**；`#75` 主控裁定）──────────────
  local n_ret=0 ret_bad=0 rl rn=0
  while IFS= read -r rl; do
    rn=$((rn + 1))
    case "$rl" in '# RETIRED'*) ;; *) continue ;; esac
    local nf_; nf_="$(printf '%s' "$rl" | awk -F'\t' '{print NF}')"
    local k_ w_ wh_ wt_ rs_
    k_="$(printf '%s' "$rl" | cut -f2)"; w_="$(printf '%s' "$rl" | cut -f4)"
    wh_="$(printf '%s' "$rl" | cut -f5)"; wt_="$(printf '%s' "$rl" | cut -f6)"; rs_="$(printf '%s' "$rl" | cut -f8)"
    if [ "${nf_:-0}" -lt 8 ] || [ -z "$k_" ] || [ -z "$w_" ] || [ -z "$wh_" ] || [ -z "$wt_" ] || [ -z "$rs_" ]; then
      ret_bad=$((ret_bad + 1))
      echo "LANEPATH_FAIL line=$rn rule=retired-record-malformed（# RETIRED 记录必须 8 字段且无空字段：marker/kind/file/what/where/who/when/restore）"
    else
      case "$k_" in code|comment|data) ;;
        *) ret_bad=$((ret_bad + 1)); echo "LANEPATH_FAIL line=$rn rule=retired-record-malformed kind=$k_（只认 code|comment|data）" ;;
      esac
    fi
    n_ret=$((n_ret + 1))
    echo "LANEPATH_RETIRED_RECORD kind=$k_ file=$(printf '%s' "$rl" | cut -f3) what=$(printf '%s' "$rl" | cut -f4) who=$(printf '%s' "$rl" | cut -f6) when=$(printf '%s' "$rl" | cut -f7) restore=$(printf '%s' "$rl" | cut -f8)"
  done < "$prov"
  echo "LANEPATH_RETIRED n=$n_ret malformed=$ret_bad（**已退役夹具的出处记录**；不进豁免计数，但形状必须合法）"
  local fails_ret=$ret_bad

  LP_PATFILE="$(mktemp)"; printf '%s\n' "$LP_NEEDLE" > "$LP_PATFILE"

  local examined=0 hits=0 code=0 comment=0 data=0 declared_hits=0 undeclared=0 overgrown=0 fails=0
  local n_code_total=0
  local -A seen_kf=()
  local prov_kf=() prov_max=()
  local pk pf_ pm pw
  while IFS=$'\t' read -r pk pf_ pm pw; do
    [ -z "${pk:-}" ] && continue
    prov_kf+=("$pk|$pf_"); prov_max+=("$pm")
  done < <(read_prov "$prov")

  local rel base lineno kind
  local -a hitk=() hitf=() hitl=()
  for f in "${scan[@]}"; do
    examined=$((examined + 1))
    rel="${f#"$root"/}"
    while IFS=$'\t' read -r lineno kind; do
      [ -z "${lineno:-}" ] && continue
      hits=$((hits + 1))
      case "$kind" in
        code)    code=$((code + 1)); n_code_total=$((n_code_total + 1)) ;;
        comment) comment=$((comment + 1)) ;;
        data)    data=$((data + 1)) ;;
      esac
      seen_kf["$kind|$rel"]=$(( ${seen_kf["$kind|$rel"]:-0} + 1 ))
      hitk+=("$kind"); hitf+=("$rel"); hitl+=("$lineno")
    done < <(classify_hits "$f")
  done
  rm -f "$LP_PATFILE"; LP_PATFILE=""

  # 逐处上屏（**分档可见**；`code` 永远是 FAIL）
  local i dec
  local -A declared_ok=()
  for i in "${!hitk[@]}"; do
    kind="${hitk[$i]}"; rel="${hitf[$i]}"; lineno="${hitl[$i]}"
    dec="no"
    if [ "$kind" != "code" ]; then
      for pk in "${!prov_kf[@]}"; do
        if [ "${prov_kf[$pk]}" = "$kind|$rel" ]; then dec="yes"; declared_ok["$kind|$rel"]=1; break; fi
      done
    fi
    if [ "$dec" = "yes" ]; then
      declared_hits=$((declared_hits + 1))
    else
      undeclared=$((undeclared + 1))
      fails=$((fails + 1))
      if [ "$kind" = "code" ]; then
        echo "LANEPATH_FAIL file=$rel line=$lineno kind=code rule=code-default-lane-path（**可执行行**上的车道路径 ⇒ 「D-G137」本体；kind=code 永不许豁免）"
      else
        echo "LANEPATH_FAIL file=$rel line=$lineno kind=$kind rule=undeclared-lane-path-mention（$kind 豁免必须走声明式出处清单）"
      fi
    fi
    echo "LANEPATH_HIT kind=$kind file=$rel line=$lineno declared=$dec"
  done

  # 声明与现读对账（上限口径：现读 **>** 上限 ⇒ 长大 ⇒ 红；现读 < 上限 ⇒ 只是松弛，可见不判）
  local slack=0
  local kf m obs
  for pk in "${!prov_kf[@]}"; do
    kf="${prov_kf[$pk]}"; m="${prov_max[$pk]:-0}"; obs="${seen_kf[$kf]:-0}"
    [ -z "$m" ] && m=0
    [ -z "$obs" ] && obs=0
    if [ "$obs" -gt "$m" ] 2>/dev/null; then
      overgrown=$((overgrown + 1)); fails=$((fails + 1))
      echo "LANEPATH_FAIL key=$kf observed=$obs max_hits=$m rule=provenance-tree-grown（现读件数 > 声明上限 ⇒ 树长大也红）"
    elif [ "$obs" -lt "$m" ] 2>/dev/null; then
      slack=$((slack + 1))
    fi
  done

  local nbad=$((fails + fails_ret))
  echo "LANEPATH_ROSTER examined=$examined hits=$hits code=$code comment=$comment data=$data declared_hits=$declared_hits undeclared=$undeclared overgrown=$overgrown provenance_rows=${#prov_kf[@]} slack=$slack retired=$n_ret retired_bad=$ret_bad"
  echo "LANEPATH_COUNTS files=$examined hits=$hits code=$code comment=$comment data=$data"
  if [ "$nbad" -gt 0 ]; then
    echo "LANEPATH=FAIL examined=$examined hits=$hits fails=$nbad code=$code undeclared=$undeclared overgrown=$overgrown"
    return $RC_FAIL
  fi
  echo "LANEPATH=PASS examined=$examined hits=$hits code=0 comment=$comment data=$data declared=$declared_hits undeclared=0 overgrown=0"
  return $RC_PASS
}

# ── 自测（零 `X`／零 `dotnet`／零 `$R` 依赖；三档 ＋ 空边 ＋ 防假绿）────────────────
selftest() {
  local T; T="$(mktemp -d)"; trap "rm -rf $T" EXIT
  local n=0 p=0
  mk() {  # mk <root> <relpath> <正文文件>
    mkdir -p "$T/$1/$(dirname "$2")"
    cp -p "$3" "$T/$1/$2"
  }
  prov() { # prov <root> <行...>
    local r="$1"; shift
    printf 'kind\tfile\tmax_hits\twhy\n' > "$T/$r/../prov-$r.tsv"
    local x; for x in "$@"; do printf '%s\n' "$x" >> "$T/$r/../prov-$r.tsv"; done
    printf '%s' "$T/$r/../prov-$r.tsv"
  }
  run() { # run <name> <want_rc> <must_grep|-> <must_not_grep|-> <root> <prov>
    local name="$1" want="$2" must="$3" mustnot="$4" root="$5" pv="$6"
    local out rc
    out="$(check_root "$T/$root" "$pv" 2>&1)"; rc=$?
    n=$((n + 1))
    local ok=1 why=""
    [ "$rc" = "$want" ] || { ok=0; why="$why rc=$rc(want $want)"; }
    if [ "$must" != "-" ] && ! grep -qE "$must" <<< "$out"; then ok=0; why="$why missing:$must"; fi
    if [ "$mustnot" != "-" ] && grep -qE "$mustnot" <<< "$out"; then ok=0; why="$why unexpected:$mustnot"; fi
    [ $ok -eq 1 ] && p=$((p + 1))
    printf 'LANEPATH_SELFTEST case=%s want_rc=%s got_rc=%s => %s %s\n' "$name" "$want" "$rc" "$([ $ok -eq 1 ] && echo OK || echo NO)" "$why"
  }

  # ⚠️ **夹具里的车道路径一律由片段拼出**（`$` 与 `HOME` **分写**、`/w163a` 用变量拼）——
  #   ⇒ 本件**不会把自己的夹具判红**。理由（**不是**给自己开白名单：清单**管不了** `code`）：
  #   夹具是**测试数据**，不是"落地件的默认路径"；照抄字面会让本件**落地当场自红**，
  #   而唯一能让它转绿的办法就是给 `code` 开口子 —— 那正是本仓最恨的假绿形态。
  #   拼装后夹具**逐字**含「`$HOME` ＋ `/w<NNN>a/…`」这类命中形态（S1/S2/S4/S10 都真跑到了 red）。
  local D='$' H='HOME' W1='w163a' W2='w102a' W3='w62a' W4='w86a'
  # 夹具 1：code 命中（可执行行上的默认值）
  mk r1 build/MilBridge/tools/t.sh <(printf '#!/usr/bin/env bash\nOUT="${X:-%s%s/%s/out}"\n' "$D" "$H" "$W1")
  # 夹具 2：comment 命中；夹具 3：data 块命中
  mk r2 build/MilBridge/tools/t.sh <(printf '#!/usr/bin/env bash\n# 出处：%s%s/%s/criteria.md\nROOTS=\x27\n%s%s/%s/negrepo\n\x27\n' "$D" "$H" "$W2" "$D" "$H" "$W3")
  mk r3 build/MilBridge/tools/t.sh <(printf '#!/usr/bin/env bash\necho ok\n')
  # 夹具 4：tests 下的 .py 注释命中（**代码件**射程）
  mk r4 build/MilBridge/tests/P/x.py <(printf '# 见 %s%s/%s/logs\nprint(1)\n' "$D" "$H" "$W4")

  local pv
  # S1：code 命中、清单为空 ⇒ 必红
  pv="$(prov r1)"; run S1-code-undeclared 1 'LANEPATH=FAIL' 'LANEPATH=PASS' r1 "$pv"
  # S2：comment ＋ data 命中，均已声明且上限 == 现读 ⇒ 必绿（且分档可见）
  pv="$(prov r2 'comment	build/MilBridge/tools/t.sh	1	判据原文出处（历史车道）' 'data	build/MilBridge/tools/t.sh	1	仓外装置根登记数据')"
  run S2-comment-data-declared 0 'LANEPATH=PASS' 'LANEPATH=FAIL' r2 "$pv"
  run S2b-kinds-visible 0 'kind=comment file=build/MilBridge/tools/t.sh line=2 declared=yes' 'LANEPATH_FAIL' r2 "$pv"
  run S2c-data-visible 0 'kind=data .*declared=yes' 'LANEPATH_FAIL' r2 "$pv"
  # S3：干净树 ⇒ 必绿、零命中
  pv="$(prov r3)"; run S3-clean 0 'LANEPATH=PASS examined=1 hits=0' 'LANEPATH_FAIL' r3 "$pv"
  # S4：**未声明**的 comment 命中 ⇒ 必红（豁免必须显式声明）
  pv="$(prov r1)"; run S4-undeclared-comment 1 'rule=undeclared-lane-path-mention' 'LANEPATH=PASS' r2 "$pv"
  # S5：清单上限 < 现读 ⇒ 必红（树长大也红）
  pv="$(prov r2 'comment	build/MilBridge/tools/t.sh	0	上限故意小于现读')"
  run S5-tree-grown 1 'rule=provenance-tree-grown' 'LANEPATH=PASS' r2 "$pv"
  # S6：把 code 命中写进清单 ⇒ **照样红**（防"用清单把牙关掉"）
  pv="$(prov r1 'code	build/MilBridge/tools/t.sh	9	妄图豁免 code')"
  run S6-code-not-exemptible 1 'rule=code-default-lane-path' 'LANEPATH=PASS' r1 "$pv"
  # S7：清单缺席 ⇒ NOINFO（空边响亮）
  run S7-provenance-absent 3 'LANEPATH=NOINFO reason=provenance-absent' 'LANEPATH=PASS' r3 "$T/nope.tsv"
  # S8：扫描集为空 ⇒ NOINFO
  mkdir -p "$T/empty"
  run S8-scan-set-empty 3 'LANEPATH=NOINFO reason=scan-set-empty' 'LANEPATH=PASS' empty "$(prov r3)"
  # S9：清单表头不认 ⇒ NOINFO
  printf 'kindy\tfile\n' > "$T/badhdr.tsv"
  run S9-provenance-header 3 'LANEPATH=NOINFO reason=provenance-header-unknown' 'LANEPATH=PASS' r3 "$T/badhdr.tsv"
  # S10：tests 下 .py 注释（未声明）⇒ 必红（射程含 tests/**）
  pv="$(prov r4)"; run S10-tests-python 1 'file=build/MilBridge/tests/P/x.py' 'LANEPATH=PASS' r4 "$pv"
  # S11：上限 > 现读 ⇒ 只报松弛、不判红
  pv="$(prov r2 'comment	build/MilBridge/tools/t.sh	5	上限大于现读' 'data	build/MilBridge/tools/t.sh	5	上限大于现读')"
  run S11-slack-visible 0 'LANEPATH=PASS' 'LANEPATH=FAIL' r2 "$pv"

  # S12：**合法的 `# RETIRED` 记录** ⇒ 不判红，且计数与逐条上屏
  pv="$( { printf 'kind\tfile\tmax_hits\twhy\n'
          printf '# RETIRED\tcode\tbuild/MilBridge/tools/t.sh\tHIDDEN_ONLY_OLDPC 兜底夹具\t仓外车道备份目录\tW25A\t2026-09-17\t重建该 `pc` 后把默认值从清单恢复\n'
          printf 'comment\tbuild/MilBridge/tools/t.sh\t1\t出处\n'
          printf 'data\tbuild/MilBridge/tools/t.sh\t1\t登记数据\n'; } > "$T/ret-ok.tsv"; printf '%s' "$T/ret-ok.tsv" )"
  run S12-retired-record-ok 0 'LANEPATH_RETIRED n=1 malformed=0' 'LANEPATH=FAIL' r2 "$pv"
  run S12b-retired-visible 0 'LANEPATH_RETIRED_RECORD kind=code' 'LANEPATH=FAIL' r2 "$pv"
  # S13：`# RETIRED` 记录**形状非法**（字段不足）⇒ 必红（出处不许丢）
  pv="$( { printf 'kind\tfile\tmax_hits\twhy\n'
          printf '# RETIRED\tcode\tbuild/MilBridge/tools/t.sh\t只剩三字段\n'
          printf 'comment\tbuild/MilBridge/tools/t.sh\t1\t出处\n'
          printf 'data\tbuild/MilBridge/tools/t.sh\t1\t登记数据\n'; } > "$T/ret-bad.tsv"; printf '%s' "$T/ret-bad.tsv" )"
  run S13-retired-malformed 1 'rule=retired-record-malformed' 'LANEPATH=PASS' r2 "$pv"

  echo "LANEPATH_SELFTEST_ROSTER cases=$n pass=$p fail=$((n - p))"
  if [ "$p" = "$n" ]; then echo "LANEPATH_SELFTEST=PASS total=$n pass=$p fail=0"; return 0; fi
  echo "LANEPATH_SELFTEST=FAIL total=$n pass=$p fail=$((n - p))"; return 1
}

# ── main ─────────────────────────────────────────────────────────────────────
main() {
  local root="." prov=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --selftest) selftest; exit $? ;;
      --root) root="${2:-}"; shift 2 ;;
      --root=*) root="${1#*=}"; shift ;;
      --provenance) prov="${2:-}"; shift 2 ;;
      --provenance=*) prov="${1#*=}"; shift ;;
      -h|--help) sed -n '2,45p' "${BASH_SOURCE[0]}"; exit 0 ;;
      *) echo "lane-path-check.sh: 未知参数 '$1'" >&2; exit 2 ;;
    esac
  done
  local absroot; absroot="$(cd "$root" 2>/dev/null && pwd)" || {
    echo "LANEPATH=NOINFO reason=root-absent root=$root"; exit $RC_NOINFO; }
  [ -n "$prov" ] || prov="$absroot/build/MilBridge/lane-path-provenance.tsv"
  # 相对路径解算顺序：① 相对**当前工作目录**存在 ⇒ 就用它（调用者直观）② 否则相对 `--root`
  case "$prov" in
    /*) ;;
    *) if [ ! -e "$prov" ]; then prov="$absroot/$prov"; fi ;;
  esac
  check_root "$absroot" "$prov"
  exit $?
}
main "$@"
