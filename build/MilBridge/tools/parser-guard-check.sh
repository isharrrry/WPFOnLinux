#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# parser-guard-check.sh —— 「**解析器不许把『解析不出』静默中性化** ∧ **继承环境的取数器
#                           必须校验并逐字打印**」牙（`TASK-0742`／`D-G143`）
#
# 【它挡的是什么（`D-G143` 的要害，逐字）】
#   取数器的解析函数在"格式不符"时**静默返回一个中性/零值**（而不是响亮失败），且它吃**继承来的
#   环境变量**、**从不校验** ⇒ 该腿的谓词**恒零**、正极性**永远不成立**，于是整条路被读成
#   `NOINFO`。**危害方向＝假负**（假绿有人怀疑，"世界如此"没人怀疑）—— 仓内现场：
#   `#67` 那条"新路"的正极性就是被一个静默降级的解析器掐掉的，而**同件同参重算**能算出
#   `EVT_PUSH_BACK=1`。⇒ 归档读数与真值相反，且**屏上一个字都不变**。
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）】
#   rc=0  `PARSER_GUARD=PASS`   逐件都扫到 ∧ 射程内**危害形态**零处（或已具名豁免）
#   rc=1  `PARSER_GUARD=FAIL`   逐处点名（`rule=harmful-not-exempted`／`rule=unnamed-site`
#                              ／`rule=exempt-without-reason`／`rule=exempt-tree-grown`／
#                              `rule=guard-no-teeth`）
#   rc=3  `PARSER_GUARD=NOINFO` 算不出：声明件缺席/空/表头不认／扫描集为空／一条形状都没求值
#                              （**空边必须响亮失败**：纪律 27）
#
# 【判据的输入来源声明（纪律 36，**现取不缓存**）】
#   · **声明件** = `build/MilBridge/tools/parser-guard-decl.txt`：判据的**唯一**参数名集／形态
#     正则／扫描根／**射程表**／豁免都从它读回 ⇒ 本件**零硬编码**（`D-G132`：声明必须有谓词）。
#   · **危害形态的口径**（不在本件里写死，逐字写在声明件的表头）：中性值与合法读数
#     **不可区分**（`(0,0)`／`0`／`-1` 当几何/计数用；或回退值被下游强转 `or 0)`）⇒ 危害；
#     `None`／`''`／`'?'`／调用者显式默认值之类**哨兵**、且下游**按哨兵判** ⇒ 不危害。
#     ⚠️ 这条口径是**可争论的**，故本件把它写成**声明件的头注 ＋ 逐处射程表**，任何一处都能被
#     复核者单独推翻（推翻 ⇒ 改声明件，不改牙 —— 判据只有一处）。
#   · **扫描集（`parser` 面）** = 被 `<verify-all>` 的 `^run_step "` 行引用的**仓内 `*.sh`／`*.py`**
#     ∪ 声明件 `SCANROOT` 点名的目录。**不泛扫全仓** —— 泛扫会把"取数即返回哨兵"的帮助函数一律
#     判红（本仓现场 12 处真站点全是哨兵形态）⇒ 那是**恒红的假牙**。
#   · **扫描集（`env` 面）** = 声明件 `SCANROOT` 目录下的 `*.sh`。
#   · **射程表**（声明件的 `射程表` 记录）= 现读现场的**逐处裁定**（`HARMFUL`／`BENIGN` ＋ 理由）。
#     **只上屏、不进 rc**；但**未列入射程表**的现场 ⇒ `FAIL rule=unnamed-site`
#     （＝"现扫，不许拿某次普查的结论当永久" —— `D-G140`）。
#   · **豁免** = 声明件的 `EXEMPT` 记录，**必须带非空 `why`** ＋ `max_hits` **上限**
#     （现读超上限 ⇒ `FAIL rule=exempt-tree-grown`，与 `lane-path-provenance.tsv` 同口径）。
#
# 【动态面（本件的**阳性对照**，防"判据是装饰"）】本件对声明件里**每一个** `PARAM` 种类
#   真跑一遍守卫：**畸形值 ⇒ 必须响亮失败**（非零 rc ＋ 机读理由，**且不得**回退成中性值）／
#   **合法值 ⇒ 必须通过**。缺任一条 ⇒ `FAIL rule=guard-no-teeth`。
#   ⚠️ **射程如实写明**：动态面证的是"**守卫有牙**"（即本牙要求的修法**可达成**），
#   **不**证"某个具体取数器用了它" —— 后者由射程表 ＋ 豁免逐处承载。
#
# 【本牙自己的接线状态（**必须字面写在件头**：判「件头自述 vs 接线」的对手牙会读它）】
#   **已接线**：`verify-all.sh` 的
#   `run_step "PARSER-GUARD" bash build/MilBridge/tools/parser-guard-check.sh`
#   ——⚠️ **本注释不写步号**：以现场 `verify-all.sh` 的**步序**为准（写死步号 = 下一条会漂移的陈旧自述）。
#
# 【测试钩子】`--selftest`：自带 fixture（零 `X`、零 `dotnet`、零 `$R` 依赖），两极化 ＋ 空边。
#   用法：bash parser-guard-check.sh [--root DIR] [--verify-all PATH] [--decl PATH]
#                                    [--expect-sites N] [--selftest] [--debug-tmp]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
REAL_ROOT="$(cd -- "$SELF_DIR/../../.." && pwd)"

ROOT="${PG_ROOT:-$REAL_ROOT}"
VA=""
DECL=""
EXPECT_SITES=""
KEEP_TMP=0
RC_PASS=0; RC_FAIL=1; RC_NOINFO=3

TMPBASE="${TMPDIR:-$HOME/.cache/wpf-linux/tmp}"
WORK=""
ST_DIR=""

say() { printf '%s\n' "$*"; }
sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }
now_iso() { date -Iseconds 2>/dev/null || date; }

usage() {
    cat <<'TXT'
用法：
  parser-guard-check.sh [--root DIR] [--verify-all PATH] [--decl PATH] [--expect-sites N] [--debug-tmp]
  parser-guard-check.sh --selftest

判据：声明件里 `SHAPE` 记录的**危害形态**在扫描集内**零命中**（或每处都有**成文豁免**）；
      每个 `PARAM` 种类的守卫必须**畸形值响亮失败 ∧ 合法值通过**。
三态：0 = PASS｜1 = FAIL｜3 = NOINFO（**NOINFO 不算绿**）
TXT
}

# ── 守卫（本牙要求的**修法**；动态面真跑它，证"可达成"）──────────────────────────────
# 用法：pg_guard <ere> <值>；通过 ⇒ rc 0 且打印逐字值；不通过 ⇒ rc 8 且**响亮**打印理由。
pg_guard() {
    local ere="$1" val="${2-}"
    if [ -z "$val" ]; then
        printf 'PARSER_GUARD_VALUE=FAIL reason=empty-value ere=%s\n' "$ere"; return 8
    fi
    if [[ "$val" =~ $ere ]]; then
        printf 'PARSER_GUARD_VALUE=OK value=%s ere=%s\n' "$val" "$ere"; return 0
    fi
    printf 'PARSER_GUARD_VALUE=FAIL reason=format-mismatch value=%s ere=%s（**不返回中性值**）\n' "$val" "$ere"
    return 8
}

# ── 声明件解析 ───────────────────────────────────────────────────────────────────
# decl_sites <decl> <family> ；输出 `<relpath>:<line>|<matched-ere>`
decl_shapes() { awk -F'\t' -v f="$2" '$1=="SHAPE" && $2==f {print $3}' "$1"; }
decl_params() { awk -F'\t' '$1=="PARAM" {print $2"\t"$3"\t"$4}' "$1"; }
decl_roots()  { awk -F'\t' '$1=="SCANROOT" {print $2}' "$1"; }
decl_range()  { awk -F'\t' '$1=="射程表" {print $2}' "$1"; }
decl_range_verdict() { awk -F'\t' -v s="$2" '$1=="射程表" && $2==s {print $3}' "$1"; }
decl_exempt() { awk -F'\t' -v f="$2" '$1=="EXEMPT" && $2==f {print $3"\t"$4"\t"$5}' "$1"; }
decl_selfex() { awk -F'\t' '$1=="SELF-EXCLUDE" {print $2}' "$1" | head -1; }

# scan_family <decl> <family> <file…> ⇒ 逐行 `<relpath>:<line><TAB><matched-ere>`
scan_family() {
    local decl="$1" fam="$2"; shift 2
    local f ere line
    local -a eres=()
    while IFS= read -r ere; do [ -n "$ere" ] && eres+=("$ere"); done < <(decl_shapes "$decl" "$fam")
    [ "${#eres[@]}" -eq 0 ] && return 0
    for f in "$@"; do
        [ -f "$f" ] || continue
        for ere in "${eres[@]}"; do
            while IFS= read -r line; do
                [ -n "$line" ] || continue
                printf '%s:%s\t%s\n' "${f#"$ROOT"/}" "${line%%:*}" "$ere"
            done < <(grep -nE -- "$ere" "$f" 2>/dev/null || true)
        done
    done
}

# ── 逐处判定（文件级累加器：`JS_*`；`check_root` 在末尾并入自己的 local 计数）──────────────
JS_SITES=0; JS_ENV=0; JS_PARSER=0; JS_FAILS=0
# 豁免表（**在判现场之前装载** —— 否则 `HARMFUL` 会先被判红，豁免永远来不及生效）
declare -A EX_CAP=(); declare -A EX_WHY=()
judge_sites() {   # judge_sites <decl> <family> <file…>
    local decl="$1" fam="$2"; shift 2
    local key ere verdict
    local -A seen=()
    while IFS=$'\t' read -r key ere; do
        [ -n "$key" ] || continue
        [ -n "${seen[$key]:-}" ] && continue
        seen[$key]=1
        JS_SITES=$((JS_SITES + 1))
        case "$fam" in env) JS_ENV=$((JS_ENV + 1)) ;; parser) JS_PARSER=$((JS_PARSER + 1)) ;; esac
        verdict="$(decl_range_verdict "$decl" "$key")"
        local ex="no"
        [ -n "${EX_CAP[$key]:-}" ] && ex="yes"
        say "PARSER_GUARD_SITE family=$fam site=$key ere=$ere range=${verdict:-<unnamed>} exempted=$ex"
        if [ -z "$verdict" ]; then
            say "PARSER_GUARD_FAIL rule=unnamed-site family=$fam site=$key（现扫命中却不在射程表里 ⇒ 必须逐处裁定）"
            JS_FAILS=$((JS_FAILS + 1))
        elif [ "$verdict" = "HARMFUL" ]; then
            if [ "$ex" = "yes" ]; then
                say "PARSER_GUARD_EXEMPTED family=$fam site=$key why=${EX_WHY[$key]}"
            else
                say "PARSER_GUARD_FAIL rule=harmful-not-exempted family=$fam site=$key"
                JS_FAILS=$((JS_FAILS + 1))
            fi
        fi
    done < <(scan_family "$decl" "$fam" "$@" | LC_ALL=C sort -u)
}

# ── 判据本体 ─────────────────────────────────────────────────────────────────────
check_root() {
    local va="$1" decl="$2" expect="$3"
    local files_env=0 files_parser=0 sites_env=0 sites_parser=0 named=0 exempt_used=0 dyn=0 fails=0 examined=0
    local f p site verdict why rule hits cap
    local -a envf=() pf=()

    [ -r "$decl" ] || { say "PARSER_GUARD=NOINFO reason=decl-absent path=$decl"; return $RC_NOINFO; }
    [ "$(awk -F'\t' '$1=="SCANROOT"{n++} END{print n+0}' "$decl")" -gt 0 ] || {
        say "PARSER_GUARD=NOINFO reason=decl-header-unrecognized path=$decl（一条 SCANROOT 都没有 ⇒ 声明件没被认出）"; return $RC_NOINFO; }

    # ① env 面扫描集
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        for f in "$ROOT/$p"/*.sh; do [ -f "$f" ] && envf+=("$f"); done
    done < <(decl_roots "$decl")
    # ── 自扫排除（**声明的**、逐字上屏的；缺声明 ⇒ 红）────────────────────────────────
    local selfex self_real
    selfex="$(decl_selfex "$decl")"
    if [ -z "$selfex" ]; then
        say "PARSER_GUARD_FAIL rule=self-exclude-undeclared（本件在扫描根之下 ⇒ 必须**声明**并上屏自排理由）"
        fails=$((fails + 1))
    fi
    self_real="$(cd -- "$SELF_DIR" 2>/dev/null && pwd)/$(basename -- "$SELF")"
    if [ -n "$selfex" ]; then
        say "PARSER_GUARD_SELF_EXCLUDED path=$self_real why=$selfex"
        local -a keepf=(); local k
        for k in "${envf[@]}"; do [ "$k" = "$self_real" ] || keepf+=("$k"); done
        envf=("${keepf[@]}")
    fi
    files_env="${#envf[@]}"
    # ② parser 面扫描集 = run_step 引用的仓内 sh/py ∪ env 面
    if [ -r "$va" ]; then
        while IFS= read -r p; do
            [ -n "$p" ] || continue
            case "$p" in *.sh|*.py) [ -f "$ROOT/$p" ] && pf+=("$ROOT/$p") ;; esac
        done < <(grep -a '^run_step "' "$va" 2>/dev/null \
                 | grep -oE '(build|src|samples|docs|tests)/[A-Za-z0-9_./+-]+\.(sh|py)' 2>/dev/null \
                 | LC_ALL=C sort -u || true)
    fi
    for f in "${envf[@]}"; do pf+=("$f"); done
    if [ -n "$selfex" ]; then
        local -a keepp=(); local q
        for q in "${pf[@]}"; do [ "$q" = "$self_real" ] || keepp+=("$q"); done
        pf=("${keepp[@]}")
    fi
    local -A _seen=(); local -a pf_u=()
    for f in "${pf[@]}"; do [ -n "${_seen[$f]:-}" ] && continue; _seen[$f]=1; pf_u+=("$f"); done
    pf=("${pf_u[@]}")
    files_parser="${#pf[@]}"

    if [ "$files_env" -eq 0 ] && [ "$files_parser" -eq 0 ]; then
        say "PARSER_GUARD=NOINFO reason=scan-set-empty root=$ROOT decl=$decl"
        say "PARSER_GUARD_NOTE 扫描集为空 ⇒ **算不出**（"一条都没扫"与"扫了零命中"必须分开）"
        return $RC_NOINFO
    fi

    # ③ 豁免表**先装载**（成文 ＋ 上限；装错了当场红，但不阻断后面的现场判定）
    EX_CAP=(); EX_WHY=()
    while IFS=$'\t' read -r site cap why; do
        [ -n "${site:-}" ] || continue
        exempt_used=$((exempt_used + 1))
        if [ -z "${why:-}" ]; then
            say "PARSER_GUARD_FAIL rule=exempt-without-reason site=$site"
            fails=$((fails + 1)); continue
        fi
        case "${cap:-}" in ''|*[!0-9]*) say "PARSER_GUARD_FAIL rule=exempt-cap-not-a-number site=$site cap=${cap:-<absent>}"; fails=$((fails+1)); continue ;; esac
        EX_CAP["$site"]="$cap"; EX_WHY["$site"]="$why"
    done < <(decl_exempt "$decl" env)

    # ④ env 面（逐处判定）
    JS_SITES=0; JS_ENV=0; JS_PARSER=0; JS_FAILS=0
    if [ "${#envf[@]}" -gt 0 ]; then judge_sites "$decl" env "${envf[@]}"; fi
    sites_env="$JS_ENV"; fails=$((fails + JS_FAILS))
    # ⑤ parser 面（扫 run_step 引用的件 ∪ env 面）
    JS_SITES=0; JS_ENV=0; JS_PARSER=0; JS_FAILS=0
    if [ "${#pf[@]}" -gt 0 ]; then judge_sites "$decl" parser "${pf[@]}"; fi
    sites_parser="$JS_PARSER"; fails=$((fails + JS_FAILS))
    examined=$((examined + sites_env + sites_parser))

    # ⑥ 豁免上限复核（现读超上限 ⇒ 红；**上限＝现读件数**，树长大也红）
    for site in "${!EX_CAP[@]}"; do
        cap="${EX_CAP[$site]}"
        hits="$( { scan_family "$decl" env "${envf[@]}" 2>/dev/null || true; scan_family "$decl" parser "${pf[@]}" 2>/dev/null || true; } | cut -f1 | grep -Fxc -- "$site" || true)"
        say "PARSER_GUARD_EXEMPT site=$site hits=$hits max_hits=$cap why=${EX_WHY[$site]}"
        if [ "$hits" -gt "$cap" ]; then
            say "PARSER_GUARD_FAIL rule=exempt-tree-grown site=$site hits=$hits max_hits=$cap"
            fails=$((fails + 1))
        fi
    done

    # ⑥ 动态面：每个 PARAM 种类真跑守卫（畸形必响亮／合法必过）
    while IFS=$'\t' read -r nm kind ere; do
        [ -n "${nm:-}" ] || continue
        local bad good o rc
        case "$kind" in
            display)  bad='0';          good=':97'        ;;
            geometry) bad='1280x1024x24'; good='1280x1024' ;;
            uint)     bad='x7';         good='7'          ;;
            enum)     bad='';           good='ok'         ;;
            *)        say "PARSER_GUARD_FAIL rule=unknown-param-kind param=$nm kind=$kind"; fails=$((fails+1)); continue ;;
        esac
        dyn=$((dyn + 1)); examined=$((examined + 1))
        o="$(pg_guard "$ere" "$bad" 2>&1)"; rc=$?
        if [ "$rc" -eq 0 ]; then
            say "PARSER_GUARD_FAIL rule=guard-no-teeth param=$nm kind=$kind arm=bad（畸形值**没被拒**）out=$o"
            fails=$((fails + 1))
        else
            case "$o" in *'format-mismatch'*|*'empty-value'*) : ;; *) say "PARSER_GUARD_FAIL rule=guard-silent param=$nm out=$o"; fails=$((fails + 1)) ;; esac
        fi
        o="$(pg_guard "$ere" "$good" 2>&1)"; rc=$?
        if [ "$rc" -ne 0 ]; then
            say "PARSER_GUARD_FAIL rule=guard-rejects-legal param=$nm kind=$kind arm=good value=$good out=$o"
            fails=$((fails + 1))
        fi
    done < <(decl_params "$decl")

    # ⑦ 件数常数（可选；把"扫描集被截断"变成响亮 FAIL）
    if [ -n "$expect" ]; then
        if [ "$expect" != "$examined" ]; then
            say "PARSER_GUARD_FAIL rule=examined-n-mismatch examined=$examined declared_expect=$expect"
            fails=$((fails + 1))
        fi
    fi

    say "PARSER_GUARD_SRC root=$ROOT verify_all=$va sha16=$(sha16 "$va") decl=$decl sha16=$(sha16 "$decl") at=$(now_iso)"
    say "PARSER_GUARD_ROSTER examined=$examined files_env=$files_env files_parser=$files_parser sites_env=$sites_env sites_parser=$sites_parser range_named=$named exempt_used=$exempt_used dynamic_n=$dyn fails=$fails"

    local v="PASS"; [ "$fails" -gt 0 ] && v="FAIL"
    say "PARSER_GUARD=$v examined=$examined sites_env=$sites_env sites_parser=$sites_parser exempt_used=$exempt_used dynamic_n=$dyn fails=$fails"
    [ "$v" = "FAIL" ] && return $RC_FAIL
    return $RC_PASS
}

# ── 自检（两极化：必红／必绿／必 NOINFO；含"通用性非硬编码"）──────────────────────────
selftest() {
    local d tot=0 pass=0 fail=0
    mkdir -p "$TMPBASE" 2>/dev/null || true
    d="$(mktemp -d "$TMPBASE/parser-guard-st.XXXXXX")" || return 1
    ST_DIR="$d"
    trap 'rm -rf -- "${ST_DIR:-}"' EXIT
    local r="$d/repo" dec="$d/decl.txt"
    mkdir -p "$r/build/MilBridge/tools"
    ROOT="$r"; DECL="$dec"
    printf '#!/usr/bin/env bash\nrun_step "A" bash build/MilBridge/tools/a.sh\nexit 0\n' > "$r/verify-all.sh"
    printf '#!/usr/bin/env bash\nDISPLAY_NUM="${WPTD_DISPLAY:-:97}"\nexit 0\n' > "$r/build/MilBridge/tools/a.sh"

    mkdecl() {  # mkdecl <env射程裁定|-> <parser射程裁定|-> <parser现场key> [附加记录块]
        { printf '%s\n' '# decl'
          printf '%s\n' 'PARAM	SCREEN	geometry	^[0-9]+x[0-9]+$	why'
          printf '%s\n' 'SHAPE	env	\$\{(WPTD_DISPLAY|DISPLAY_NUM|SCREEN|BASE|X):-	why'
          printf '%s\n' 'SHAPE	parser	if m else \(0, ?0\)	why'
          printf '%s\n' 'SCANROOT	build/MilBridge/tools	why'
          if [ "$1" != "-" ]; then printf '%s\n' "射程表	build/MilBridge/tools/a.sh:2	$1	why"; fi
          if [ "$2" != "-" ]; then printf '%s\n' "射程表	$3	$2	why"; fi
          if [ -n "${4:-}" ]; then printf '%s\n' "$4"; fi
        } > "$dec"
    }
    # 夹具里 b.sh 的现场（用于 G4/G7/G8 的射程表）
    BKEY='build/MilBridge/tools/b.sh:2'

    try() {  # try <名> <期望rc> <必须出现ERE> <必须不出现ERE|""> [examined期望] [声明件覆盖]
        local nm="$1" want="$2" must="$3" mustnot="$4" ex="${5:-}" do_="${6:-$dec}" o rc
        o="$(check_root "$r/verify-all.sh" "$do_" "$ex" 2>&1)"; rc=$?
        tot=$((tot + 1))
        if [ "$rc" -eq "$want" ] \
           && [ -n "$(printf '%s\n' "$o" | grep -E "$must" || true)" ] \
           && { [ -z "$mustnot" ] || [ -z "$(printf '%s\n' "$o" | grep -E "$mustnot" || true)" ]; }; then
            pass=$((pass + 1)); say "SELFTEST $nm want_rc=$want got_rc=$rc = OK"
        else
            fail=$((fail + 1)); say "SELFTEST $nm want_rc=$want got_rc=$rc must='$must' mustnot='$mustnot' = FAIL"
            printf '%s\n' "$o" | sed 's/^/    /'
        fi
    }

    # G1 正极性：env 现场已逐处裁定 BENIGN ⇒ 绿
    mkdecl BENIGN - "$BKEY"; try "G1 正极性（现场已裁定 ⇒ 绿）" 0 'PARSER_GUARD=PASS' ''
    # G2 反极：同一现场裁定 HARMFUL 却无豁免 ⇒ 必红
    mkdecl HARMFUL - "$BKEY"; try "G2 反极（裁定 HARMFUL 且无豁免 ⇒ 必红）" 1 'rule=harmful-not-exempted' ''
    # G3 反极：现扫命中但**不在射程表**（模拟"新长了没人看过的现场"）⇒ 必红
    mkdecl - - "$BKEY"; try "G3 反极（现扫命中却未点名 ⇒ 必红）" 1 'rule=unnamed-site' ''
    # G4 通用性：注入一处**新的** env 形态（另一个件名）⇒ 未点名 ⇒ 必红
    printf '#!/usr/bin/env bash\nSCREEN="${SCREEN:-1280x1024}"\nexit 0\n' > "$r/build/MilBridge/tools/b.sh"
    printf '#!/usr/bin/env bash\nrun_step "A" bash build/MilBridge/tools/a.sh\nrun_step "B" bash build/MilBridge/tools/b.sh\nexit 0\n' > "$r/verify-all.sh"
    mkdecl BENIGN - "$BKEY"
    try "G4 通用性（注入新件新现场 ⇒ 必红，证非硬编码）" 1 'unnamed-site.*b\.sh' ''
    # G5 豁免必须成文：空 why ⇒ 必红
    mkdecl - - "$BKEY" "$(printf 'EXEMPT\tenv\tbuild/MilBridge/tools/a.sh:2\t2\t')"
    try "G5 反极（豁免无理由 ⇒ 必红）" 1 'rule=exempt-without-reason' ''
    # G6 豁免上限：现读超上限 ⇒ 必红
    mkdecl - - "$BKEY" "$(printf 'EXEMPT\tenv\tbuild/MilBridge/tools/a.sh:2\t0\t成文理由')"
    try "G6 反极（豁免超上限 ⇒ 必红）" 1 'rule=exempt-tree-grown' ''
    # G7 成文豁免在上限内 ⇒ HARMFUL 被豁免、不红（且豁免计数上屏）
    mkdecl HARMFUL BENIGN "$BKEY" "$(printf 'EXEMPT\tenv\tbuild/MilBridge/tools/a.sh:2\t2\t成文理由：自测夹具')"
    try "G7 豁免在位（成文 ∧ 未超上限 ⇒ 不红）" 0 'exempt_used=1' 'PARSER_GUARD=FAIL'
    # G8 动态面必红：把白名单改成永远不中 ⇒ 合法值被拒 ⇒ 必红
    { printf '%s\n' 'PARAM	SCREEN	geometry	^NEVERMATCH$	why'
      printf '%s\n' 'SHAPE	env	\$\{(WPTD_DISPLAY|X):-	why'
      printf '%s\n' 'SCANROOT	build/MilBridge/tools	why'
      printf '%s\n' '射程表	build/MilBridge/tools/a.sh:2	BENIGN	why'
      printf '%s\n' '射程表	build/MilBridge/tools/b.sh:2	BENIGN	why'; } > "$dec"
    try "G8 反极（守卫拒合法值 ⇒ 必红）" 1 'rule=guard-rejects-legal' ''
    # G9 空边：声明件缺席 ⇒ NOINFO
    try "G9 空边（声明件缺席 ⇒ NOINFO）" 3 'reason=decl-absent' 'PARSER_GUARD=PASS' '' "$d/no-such-decl.txt"
    # G10 空边：run_step 零行 + 扫描根不存在 ⇒ NOINFO
    printf '#!/usr/bin/env bash\nexit 0\n' > "$r/verify-all.sh"
    { printf '%s\n' 'SHAPE	env	\$\{(WPTD_DISPLAY|X):-	why'; printf '%s\n' 'SCANROOT	build/NoSuchDir	why'; } > "$dec"
    try "G10 空边（扫描集为空 ⇒ NOINFO）" 3 'reason=scan-set-empty' 'PARSER_GUARD=PASS' ''
    # G11 空边：声明件认不出（无 SCANROOT）⇒ NOINFO
    printf '%s\n' 'SHAPE	env	X	why' > "$dec"
    try "G11 空边（声明件表头不认 ⇒ NOINFO）" 3 'reason=decl-header-unrecognized' 'PARSER_GUARD=PASS' ''
    # G12 件数常数不符 ⇒ 必红
    printf '#!/usr/bin/env bash\nrun_step "A" bash build/MilBridge/tools/a.sh\nexit 0\n' > "$r/verify-all.sh"
    mkdecl BENIGN BENIGN "$BKEY"; try "G12 反极（--expect-sites 不符 ⇒ 必红）" 1 'rule=examined-n-mismatch' '' 9999
    # G13 真树阳性对照：现仓上必须真扫到现场（防"扫描器失明却报绿"）
    tot=$((tot + 1))
    local live live_e live_p live_root live_decl
    live_root="${PG_LIVE_ROOT:-$REAL_ROOT}"
    live_decl="${PG_LIVE_DECL:-$live_root/build/MilBridge/tools/parser-guard-decl.txt}"
    live="$(bash "$SELF" --root "$live_root" --decl "$live_decl" 2>&1 || true)"
    live_e="$(printf '%s\n' "$live" | sed -n 's/.*sites_env=\([0-9]*\).*/\1/p' | head -1)"
    live_p="$(printf '%s\n' "$live" | sed -n 's/.*sites_parser=\([0-9]*\).*/\1/p' | head -1)"
    if [ "$(( ${live_e:-0} + ${live_p:-0} ))" -ge 1 ]; then
        pass=$((pass + 1)); say "SELFTEST G13 真树阳性对照（真扫到现场 sites_env=${live_e:-0} sites_parser=${live_p:-0} root=$live_root）= OK"
    else
        fail=$((fail + 1)); say "SELFTEST G13 真树阳性对照 = FAIL（root=$live_root decl=$live_decl 没产出任何现场 ⇒ 判据来源不可信）"
    fi

    say "PARSER_GUARD_SELFTEST_ROSTER cases=$tot pass=$pass fail=$fail"
    if [ "$fail" -eq 0 ]; then say "PARSER_GUARD_SELFTEST=PASS total=$tot pass=$pass fail=$fail"; return 0; fi
    say "PARSER_GUARD_SELFTEST=FAIL total=$tot pass=$pass fail=$fail"; return 1
}

main() {
    local st=0 expect=""
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --root|--repo)       ROOT="${2:-}"; shift 2 ;;
            --root=*|--repo=*)   ROOT="${1#*=}"; shift ;;
            --verify-all)        VA="${2:-}"; shift 2 ;;
            --verify-all=*)      VA="${1#*=}"; shift ;;
            --decl)              DECL="${2:-}"; shift 2 ;;
            --decl=*)            DECL="${1#*=}"; shift ;;
            --expect-sites)      EXPECT_SITES="${2:-}"; shift 2 ;;
            --expect-sites=*)    EXPECT_SITES="${1#*=}"; shift ;;
            --debug-tmp)         KEEP_TMP=1; shift ;;
            --selftest)          st=1; shift ;;
            -h|--help)           usage; return $RC_PASS ;;
            *) say "用法：bash $SELF [--root DIR] [--decl PATH] [--selftest]"; return 2 ;;
        esac
    done
    if [ "$st" = 1 ]; then
        mkdir -p "$TMPBASE" 2>/dev/null || true
        WORK="$(mktemp -d "$TMPBASE/parser-guard.XXXXXX")" || { say "PARSER_GUARD=NOINFO reason=mktemp-failed"; return $RC_NOINFO; }
        selftest; local rcs=$?
        rm -rf -- "$WORK"
        return $rcs
    fi
    ROOT="$(cd -- "$ROOT" 2>/dev/null && pwd)" || { say "PARSER_GUARD=NOINFO reason=root-absent root=$ROOT"; return $RC_NOINFO; }
    [ -n "$VA" ] || VA="$ROOT/verify-all.sh"
    [ -n "$DECL" ] || DECL="$ROOT/build/MilBridge/tools/parser-guard-decl.txt"
    mkdir -p "$TMPBASE" 2>/dev/null || { say "PARSER_GUARD=NOINFO reason=tmpbase-unusable TMPBASE=$TMPBASE"; return $RC_NOINFO; }
    WORK="$(mktemp -d "$TMPBASE/parser-guard.XXXXXX")" || { say "PARSER_GUARD=NOINFO reason=mktemp-failed"; return $RC_NOINFO; }
    if [ "$KEEP_TMP" = 1 ]; then say "PARSER_GUARD_TMP=$WORK"; else trap 'rm -rf -- "${WORK:-}"' EXIT; fi
    expect="$EXPECT_SITES"
    check_root "$VA" "$DECL" "$expect"
}

main "$@"
