#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# wiring-coverage-check.sh —— 「**接线件集合 ⊆ 覆盖面集合**」常态牙（`TASK-0740`／`D-G140`）
#
# 【它挡的是什么】
#   `verify-all.sh` 的每一步（`run_step "名" <命令…>`）都会**读**仓内若干件；那些件里只要有
#   **一件不在** `build/close-wave.sh` 的 `fp_inputs()` 覆盖面里，改它就**零机器红**
#   （`inputs_fp` 不动、门禁照绿、两哨兵照绿）⇒ **判据的输入没人看着**。
#   本仓现场已长过两次同类缺口（`TASK-0729` 的 20 件、`#74` 的三件承重牙），
#   而"某次普查为零"这句话**会过期**（`D-G140`）⇒ 必须做成**每次运行现扫**的牙。
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）】
#   rc=0  `WIRING_COVERAGE=PASS`   接线集**每一个**成员都在覆盖面里
#   rc=1  `WIRING_COVERAGE=FAIL`   逐件点名（`rule=wired-but-uncovered`／`rule=wired-path-absent`
#                                 ／`rule=allow-without-reason`）
#   rc=3  `WIRING_COVERAGE=NOINFO` 算不出：接线事实不可读／`^run_step "` 零行／接线集抽成空集／
#                                 覆盖面活清单取不到或为空／同码路径委托不可用
#                                 （**空边必须响亮失败**：纪律 27 —— "一条都没读到" ≠ "没有一条命中"）
#
# 【判据的输入来源声明（纪律 36，**现取不缓存**；`D-G140`：读数带语料清单＋时刻）】
#   · **接线事实** = `<verify-all>` 里**现取全量**的 `^run_step "` 行；从中抽仓内**判据/产出件**路径，
#     ERE 见代码常量 `WR_ERE`（`(build|src|samples|docs|tests)/…\.(sh|py|tsv|json|txt)`）。
#     ⚠️ **不含** `.csproj`／`.sln`／`.props`：那些是**构建目标**，按本仓成文惯例**不进** `fp_inputs()`
#     （`fp_inputs()` 只收"**读 ⇒ 进名单**"的判据件）⇒ 把它们判红就是**射程过宽**（会恒红，
#     而恒红的牙会被读成"世界如此"）。**本条是显式的范围决定**，见预登记。
#   · **覆盖面** = `fp_inputs()` 的**活清单**；本件**不重写任何 `find`**：委托 `fp-manifest-step.sh`
#     （它用 `PATH` 前置 `sha256sum` shim 收 `xargs` 真交付的名字表 ＋ `sed -n '/^fp_inputs()/,/^}/p'`
#     把函数体**原文原样**抽出执行）⇒ **同一份逻辑只有一份：就是被测那一份**。
#     本件**刻意不传** `--expect`：件数常数只许活在**一处**（`verify-all.sh` 第 `[42]` 步），
#     本件据"现读到的活清单"判集合关系，与那个常数**解耦**（同一份数不许存在两处，否则必然分叉）。
#     ⚠️ 代价如实写明：本件与第 `[42]` 步**共享同一条抽清单路径**（纯读、秒级）。
#   · **允许清单（可选，`--allow`）** = `<仓内相对路径>\t<why>` 逐行（`#` 起头为注/表头）；
#     `why` 为空 ⇒ `FAIL rule=allow-without-reason`（**豁免必须成文**）。默认**无**允许清单 ⇒ 缺口就红。
#
# 【本牙自己的接线状态（**必须字面写在件头**：判「件头自述 vs 接线」的对手牙会读它）】
#   **已接线**：`verify-all.sh` 的
#   `run_step "WIRING-COVERAGE" bash build/MilBridge/tools/wiring-coverage-check.sh`
#   ——⚠️ **本注释不写步号**：以现场 `verify-all.sh` 的**步序**为准（写死步号 = 下一条会漂移的陈旧自述）。
#
# 【测试钩子】`--selftest`：自带 fixture（零 `X`、零 `dotnet`）＋ 一条**真树阳性对照**。
#   用法：bash wiring-coverage-check.sh [--root DIR] [--repo DIR] [--verify-all PATH]
#                                      [--close-wave PATH] [--fpms PATH] [--manifest FILE]
#                                      [--allow FILE] [--selftest] [--debug-tmp]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
REAL_ROOT="$(cd -- "$SELF_DIR/../../.." && pwd)"

ROOT="${WC_ROOT:-$REAL_ROOT}"
VA=""
CW=""
FPMS=""
MANIFEST=""
ALLOW=""
KEEP_TMP=0
RC_PASS=0; RC_FAIL=1; RC_NOINFO=3

# 判据的**唯一**字样来源（ERE）：接线事实里"算数"的路径形态
WR_ERE='(build|src|samples|docs|tests)/[A-Za-z0-9_./+-]+\.(sh|py|tsv|json|txt)'

TMPBASE="${TMPDIR:-$HOME/.cache/wpf-linux/tmp}"
WORK=""
ST_DIR=""      # 自检 fixture 根（**文件级**：EXIT 陷阱里 `local` 已出作用域，用它会删空路径）

say() { printf '%s\n' "$*"; }
sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }
now_iso() { date -Iseconds 2>/dev/null || date; }

usage() {
    cat <<'TXT'
用法：
  wiring-coverage-check.sh [--root DIR] [--repo DIR] [--verify-all PATH] [--close-wave PATH]
                           [--fpms PATH] [--manifest FILE] [--allow FILE] [--debug-tmp]
  wiring-coverage-check.sh --selftest

判据：`verify-all.sh` 的 `^run_step "` 行里抽出的**仓内判据/产出件**路径集合，必须**每一件**都在
      `build/close-wave.sh` 的 `fp_inputs()` 活清单里；缺一件即红并点名。
三态：0 = PASS｜1 = FAIL｜3 = NOINFO（**NOINFO 不算绿**）
TXT
}

# fp-manifest-step.sh 的临时目录形态守卫：**只清同前缀**的目录（绝不对任意路径 rm -rf）
fpms_dir_ok() { case "${1:-}" in */fp-manifest-step.??????) return 0 ;; *) return 1 ;; esac; }

# ── 取覆盖面活清单（**同码路径委托**）────────────────────────────────────────────────
# 成功：把清单复制进本件 WORK 并打印其路径；失败：返回 2（调用者报 NOINFO）
delegate_manifest() {
    local out sb man
    [ -f "$FPMS" ] || return 2
    out="$(bash "$FPMS" --repo "$ROOT" --close-wave "$CW" --debug-tmp 2>&1)" || true
    sb="$(printf '%s\n' "$out" | sed -n 's/^FPMS_TMP_DIR=//p' | head -1)"
    man="$(printf '%s\n' "$out" | sed -n 's/.*FP_MANIFEST_SCAN manifest=\([^ ][^ ]*\).*/\1/p' | head -1)"
    if [ -z "$man" ] || [ ! -f "$man" ]; then
        fpms_dir_ok "$sb" && rm -rf -- "$sb"
        return 2
    fi
    cp -a -- "$man" "$WORK/coverage.manifest" 2>/dev/null || { fpms_dir_ok "$sb" && rm -rf -- "$sb"; return 2; }
    # ⚠️ 委托件用 --debug-tmp ⇒ **由本件负责收净**（不许留临时件；先核前缀再删）
    fpms_dir_ok "$sb" && rm -rf -- "$sb"
    printf '%s\n' "$WORK/coverage.manifest"
    return 0
}

# ── 判据本体 ─────────────────────────────────────────────────────────────────────
# check_root <va> <cw> <manifest|""> <allow|""> ；印逐件行 ＋ 机读行；返回 rc
check_root() {
    local va="$1" cw="$2" man_in="$3" allow="$4"
    local runn=0 wiring_n=0 cov_n=0 missing_n=0 absent_n=0 allowed_n=0 fails=0 examined=0
    local man="" line p w
    local -a wiring=()

    [ -r "$va" ] || { say "WIRING_COVERAGE=NOINFO reason=verify-all-absent path=$va（接线事实的来源不可读 ⇒ 算不出）"; return $RC_NOINFO; }

    runn="$(awk '/^run_step "/{n++} END{print n+0}' "$va")"
    if [ "${runn:-0}" -eq 0 ]; then
        say "WIRING_COVERAGE=NOINFO reason=run-step-zero path=$va examined=0 run_step=0"
        say "WIRING_COVERAGE_NOTE 一条 run_step 都没读到 ⇒ **算不出**（「零命中」与「没读到」必须分开）"
        return $RC_NOINFO
    fi

    # ① 接线集（现取全量）
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        p="${p#./}"
        wiring+=("$p")
    done < <(grep -a '^run_step "' "$va" 2>/dev/null | grep -oE "$WR_ERE" 2>/dev/null | LC_ALL=C sort -u || true)
    wiring_n="${#wiring[@]}"
    if [ "$wiring_n" -eq 0 ]; then
        say "WIRING_COVERAGE=NOINFO reason=wiring-set-empty verify_all=$va run_step=$runn"
        say "WIRING_COVERAGE_NOTE 有 $runn 条 run_step 却抽不出一条仓内件路径 ⇒ **抽取器失明**（不是"没有接线"）"
        return $RC_NOINFO
    fi

    # ② 覆盖面活清单
    if [ -n "$man_in" ]; then
        man="$man_in"
    else
        man="$(delegate_manifest)" || man=""
    fi
    if [ -z "$man" ] || [ ! -f "$man" ]; then
        say "WIRING_COVERAGE=NOINFO reason=coverage-unavailable close_wave=$cw fpms=$FPMS"
        say "WIRING_COVERAGE_NOTE 覆盖面活清单取不到 ⇒ **算不出**（不肯拿"空集"当"都覆盖了"）"
        return $RC_NOINFO
    fi
    cov_n="$(awk 'NF>=2{n++} END{print n+0}' "$man")"
    if [ "$cov_n" -eq 0 ]; then
        say "WIRING_COVERAGE=NOINFO reason=coverage-empty manifest=$man"
        say "WIRING_COVERAGE_NOTE 活清单 0 行 ⇒ **算不出**（空清单会让"⊆"恒真 = 形状完好的假绿）"
        return $RC_NOINFO
    fi
    sed -n 's/^[0-9a-f]\{64\}  //p' "$man" | sed 's|^\./||' | LC_ALL=C sort -u > "$WORK/coverage.set"

    # ③ 允许清单（可选；豁免必须成文）
    : > "$WORK/allow.set"
    if [ -n "$allow" ]; then
        if [ ! -r "$allow" ]; then
            say "WIRING_COVERAGE=NOINFO reason=allow-unreadable path=$allow"
            return $RC_NOINFO
        fi
        while IFS= read -r line; do
            case "$line" in ''|'#'*) continue ;; esac
            p="${line%%$'\t'*}"; w="${line#*$'\t'}"
            [ "$w" = "$line" ] && w=""
            if [ -z "$p" ] || [ -z "$w" ]; then
                say "WIRING_COVERAGE_FAIL rule=allow-without-reason line='$line'"
                fails=$((fails + 1)); continue
            fi
            p="${p#./}"; printf '%s\n' "$p" >> "$WORK/allow.set"
            allowed_n=$((allowed_n + 1))
            say "WIRING_COVERAGE_ALLOW file=$p declared=yes why=$w"
        done < "$allow"
    fi

    # ④ 逐件判定
    for p in "${wiring[@]}"; do
        examined=$((examined + 1))
        if [ ! -f "$ROOT/$p" ]; then
            say "WIRING_COVERAGE_FAIL rule=wired-path-absent file=$p verify_all=$va（接线指名了一件**不存在的件**）"
            absent_n=$((absent_n + 1)); fails=$((fails + 1)); continue
        fi
        if grep -Fxq -- "$p" "$WORK/coverage.set"; then
            continue
        fi
        if grep -Fxq -- "$p" "$WORK/allow.set"; then
            continue
        fi
        say "WIRING_COVERAGE_FAIL rule=wired-but-uncovered file=$p verify_all=$va（门禁读它，改它却零机器红）"
        missing_n=$((missing_n + 1)); fails=$((fails + 1))
    done

    say "WIRING_COVERAGE_SRC verify_all=$va sha16=$(sha16 "$va") run_step=$runn close_wave=$cw sha16=$(sha16 "$cw") fpms=$FPMS sha16=$(sha16 "$FPMS") manifest_sha16=$(sha16 "$man") at=$(now_iso)"
    say "WIRING_COVERAGE_ROSTER examined=$examined wiring_n=$wiring_n coverage_n=$cov_n missing_n=$missing_n absent_n=$absent_n allowed_n=$allowed_n fails=$fails"

    local v="PASS"; [ "$fails" -gt 0 ] && v="FAIL"
    say "WIRING_COVERAGE=$v run_step=$runn wiring_n=$wiring_n coverage_n=$cov_n missing_n=$missing_n absent_n=$absent_n allowed_n=$allowed_n examined=$examined"
    [ "$v" = "FAIL" ] && return $RC_FAIL
    return $RC_PASS
}

# ── 自检（两极化：必红／必绿／必 NOINFO；含"通用性非硬编码"与"真树阳性对照"）──────────────
selftest() {
    local d tot=0 pass=0 fail=0
    mkdir -p "$TMPBASE" 2>/dev/null || true
    d="$(mktemp -d "$TMPBASE/wiring-cov-st.XXXXXX")" || return 1
    # ⚠️ 陷阱里的变量**必须**是文件级（`local` 在 EXIT 时已出作用域 ⇒ 会删空路径）
    ST_DIR="$d"
    trap 'rm -rf -- "${ST_DIR:-}"' EXIT
    local r="$d/repo"
    # ⚠️ 夹具树就是本轮的"仓根"：`check_root` 判"件存在吗"用的是 `$ROOT` ⇒ 必须切成夹具根
    ROOT="$r"
    mkdir -p "$r/build/MilBridge/tools" "$r/tests/X/tools"

    # fixture 件（真存在；本牙只判"在不在覆盖面"，不判内容）
    for f in a b z; do printf '#!/usr/bin/env bash\nexit 0\n' > "$r/build/MilBridge/tools/$f.sh"; done
    printf '#!/usr/bin/env python3\n' > "$r/tests/X/tools/t.py"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$r/build/close-wave.sh"

    # 覆盖面清单（sha256sum 形态：`<64hex>  <path>`）
    mkman() {  # mkman <out> <path…>
        local o="$1"; shift
        : > "$o"
        local p
        for p in "$@"; do printf '%s  %s\n' "$(printf 'x' | sha256sum | cut -d' ' -f1)" "$p" >> "$o"; done
    }
    mkman "$d/cov_a.tsv"  build/MilBridge/tools/a.sh
    mkman "$d/cov_ab.tsv" build/MilBridge/tools/a.sh build/MilBridge/tools/b.sh
    : > "$d/cov_empty.tsv"

    mkva() { printf '#!/usr/bin/env bash\n%s\nexit 0\n' "$1" > "$r/verify-all.sh"; }
    RS='run_step "A" bash build/MilBridge/tools/a.sh'

    try() {  # try <名> <期望rc> <必须出现ERE> <必须不出现ERE|""> <va> <man> <allow>
        local nm="$1" want="$2" must="$3" mustnot="$4" va="$5" man="$6" allow="$7" o rc
        o="$(check_root "$va" "$r/build/close-wave.sh" "$man" "$allow" 2>&1)"; rc=$?
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

    # C1 正极性：接线的那件已入名单 ⇒ PASS
    mkva "$RS"
    try "C1 正极性（已接线 ∧ 已入名单 ⇒ 绿）" 0 'WIRING_COVERAGE=PASS.+missing_n=0' '' "$r/verify-all.sh" "$d/cov_a.tsv" ""
    # C2 反向必红：喂一个"已接线但未入名单"的件 ⇒ 必红并点名
    mkva "$RS
run_step \"B\" bash build/MilBridge/tools/b.sh"
    try "C2 反极（已接线 ∧ 未入名单 ⇒ 红并点名）" 1 'rule=wired-but-uncovered file=build/MilBridge/tools/b\.sh' 'WIRING_COVERAGE=PASS' "$r/verify-all.sh" "$d/cov_a.tsv" ""
    # C3 通用性（非硬编码）：换一个从没出现过的件名 ⇒ 照样红并点名
    mkva "$RS
run_step \"Z\" bash build/MilBridge/tools/z.sh"
    try "C3 通用性（新件名 z.sh ⇒ 红并点名，证非硬编码）" 1 'rule=wired-but-uncovered file=build/MilBridge/tools/z\.sh' '' "$r/verify-all.sh" "$d/cov_a.tsv" ""
    # C4 接线指名一件不存在的件 ⇒ 必红（另一支）
    mkva "$RS
run_step \"G\" bash build/MilBridge/tools/ghost.sh"
    try "C4 反极（接线指名不存在的件 ⇒ 红）" 1 'rule=wired-path-absent file=build/MilBridge/tools/ghost\.sh' 'WIRING_COVERAGE=PASS' "$r/verify-all.sh" "$d/cov_a.tsv" ""
    # C5 射程不过宽：.csproj/.sln/.md 与 glob **不**进接线集 ⇒ 照旧绿
    mkva "$RS
run_step \"SLN\" dotnet build wpf-linux.sln
run_step \"PRJ\" dotnet build tests/X/tools/t.csproj
run_step \"PREREG\" bash build/MilBridge/tools/prereg-four-requirements-check.sh --gate --glob 'docs/WAVE*-PREREGISTRATION.md'"
    : > "$d/keep.tsv"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$r/build/MilBridge/tools/prereg-four-requirements-check.sh"
    mkman "$d/cov_a2.tsv" build/MilBridge/tools/a.sh build/MilBridge/tools/prereg-four-requirements-check.sh
    try "C5 射程（.csproj/.sln/glob 不进接线集 ⇒ 不误红）" 0 'WIRING_COVERAGE=PASS' 'rule=wired-but-uncovered' "$r/verify-all.sh" "$d/cov_a2.tsv" ""
    # C6 tests/ 在射程内（显式范围决定）：tests 下的判据件未入名单 ⇒ 必红
    mkva "$RS
run_step \"T\" python3 tests/X/tools/t.py"
    try "C6 射程（tests/ 下的判据件在射程内 ⇒ 未入名单必红）" 1 'rule=wired-but-uncovered file=tests/X/tools/t\.py' '' "$r/verify-all.sh" "$d/cov_a.tsv" ""
    # C7 允许清单（成文豁免）⇒ 不判红，且 allowed_n 上屏（⚠️ 夹具先落盘再判）
    printf 'tests/X/tools/t.py\t成文理由：自测夹具里的豁免位（仅 C7 用）\n' > "$d/allow_ok.tsv"
    try "C7 允许清单（成文豁免 ⇒ 不红 ∧ allowed_n=1）" 0 'allowed_n=1' 'WIRING_COVERAGE=FAIL' "$r/verify-all.sh" "$d/cov_a.tsv" "$d/allow_ok.tsv"
    # C8 豁免必须成文：why 为空 ⇒ 必红
    printf 'tests/X/tools/t.py\t\n' > "$d/allow_bad.tsv"
    try "C8 反极（豁免无理由 ⇒ 必红）" 1 'rule=allow-without-reason' '' "$r/verify-all.sh" "$d/cov_a.tsv" "$d/allow_bad.tsv"
    # C9 空边：run_step 零行 ⇒ NOINFO
    printf '#!/usr/bin/env bash\nexit 0\n' > "$r/verify-all.sh"
    try "C9 空边（run_step 零行 ⇒ NOINFO）" 3 'reason=run-step-zero' 'WIRING_COVERAGE=PASS' "$r/verify-all.sh" "$d/cov_a.tsv" ""
    # C10 空边：覆盖面 0 行 ⇒ NOINFO（不许把空集当"都覆盖"）
    mkva "$RS"
    try "C10 空边（覆盖面 0 行 ⇒ NOINFO）" 3 'reason=coverage-empty' 'WIRING_COVERAGE=PASS' "$r/verify-all.sh" "$d/cov_empty.tsv" ""
    # C11 空边：接线事实不可读 ⇒ NOINFO
    try "C11 空边（verify-all 缺席 ⇒ NOINFO）" 3 'reason=verify-all-absent' 'WIRING_COVERAGE=PASS' "$d/nope.sh" "$d/cov_a.tsv" ""
    # C12 空边：有 run_step 却抽不出任何仓内件 ⇒ NOINFO（抽取器失明 ≠ 没有接线）
    mkva 'run_step "X" /bin/true'
    try "C12 空边（抽取器失明 ⇒ NOINFO）" 3 'reason=wiring-set-empty' 'WIRING_COVERAGE=PASS' "$r/verify-all.sh" "$d/cov_a.tsv" ""
    # C13 真树阳性对照：委托路径在真仓上必须真拿到清单（防"委托坏了却报绿"）
    #   真树根：`WC_LIVE_ROOT` 优先（自测时可指向真仓）；落仓后 `REAL_ROOT` 本就是仓根 ⇒ 不需要它。
    mkva "$RS"
    local live live_n live_root
    live_root="${WC_LIVE_ROOT:-$REAL_ROOT}"
    live="$(bash "$SELF" --root "$live_root" 2>&1 | sed -n 's/.*coverage_n=\([0-9]*\).*/\1/p' | head -1)"
    tot=$((tot + 1))
    live_n="${live:-0}"
    if [ "${live_n:-0}" -gt 0 ]; then
        pass=$((pass + 1)); say "SELFTEST C13 真树阳性对照（委托真拿到活清单 root=$live_root coverage_n=$live_n）= OK"
    else
        fail=$((fail + 1)); say "SELFTEST C13 真树阳性对照 = FAIL（root=$live_root 委托取不到活清单 ⇒ 本牙的覆盖面来源不可信）"
    fi

    say "WIRING_COVERAGE_SELFTEST_ROSTER cases=$tot pass=$pass fail=$fail"
    if [ "$fail" -eq 0 ]; then say "WIRING_COVERAGE_SELFTEST=PASS total=$tot pass=$pass fail=$fail"; return 0; fi
    say "WIRING_COVERAGE_SELFTEST=FAIL total=$tot pass=$pass fail=$fail"; return 1
}

main() {
    local st=0
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --root|--repo)      ROOT="${2:-}"; shift 2 ;;
            --root=*|--repo=*)  ROOT="${1#*=}"; shift ;;
            --verify-all)       VA="${2:-}"; shift 2 ;;
            --verify-all=*)     VA="${1#*=}"; shift ;;
            --close-wave)       CW="${2:-}"; shift 2 ;;
            --close-wave=*)     CW="${1#*=}"; shift ;;
            --fpms)             FPMS="${2:-}"; shift 2 ;;
            --fpms=*)           FPMS="${1#*=}"; shift ;;
            --manifest)         MANIFEST="${2:-}"; shift 2 ;;
            --manifest=*)       MANIFEST="${1#*=}"; shift ;;
            --allow)            ALLOW="${2:-}"; shift 2 ;;
            --allow=*)          ALLOW="${1#*=}"; shift ;;
            --debug-tmp)        KEEP_TMP=1; shift ;;
            --selftest)         st=1; shift ;;
            -h|--help)          usage; return $RC_PASS ;;
            *) say "用法：bash $SELF [--root DIR] [--verify-all PATH] [--selftest]"; return 2 ;;
        esac
    done
    if [ "$st" = 1 ]; then
        mkdir -p "$TMPBASE" 2>/dev/null || true
        WORK="$(mktemp -d "$TMPBASE/wiring-cov.XXXXXX")" || { say "WIRING_COVERAGE=NOINFO reason=mktemp-failed"; return $RC_NOINFO; }
        selftest; local rcs=$?
        rm -rf -- "$WORK"
        return $rcs
    fi
    ROOT="$(cd -- "$ROOT" 2>/dev/null && pwd)" || { say "WIRING_COVERAGE=NOINFO reason=root-absent root=$ROOT"; return $RC_NOINFO; }
    [ -n "$VA" ] || VA="$ROOT/verify-all.sh"
    [ -n "$CW" ] || CW="$ROOT/build/close-wave.sh"
    [ -n "$FPMS" ] || FPMS="$ROOT/build/MilBridge/tools/fp-manifest-step.sh"
    [ -f "$FPMS" ] || FPMS="$SELF_DIR/fp-manifest-step.sh"
    mkdir -p "$TMPBASE" 2>/dev/null || { say "WIRING_COVERAGE=NOINFO reason=tmpbase-unusable TMPBASE=$TMPBASE"; return $RC_NOINFO; }
    WORK="$(mktemp -d "$TMPBASE/wiring-cov.XXXXXX")" || { say "WIRING_COVERAGE=NOINFO reason=mktemp-failed"; return $RC_NOINFO; }
    if [ "$KEEP_TMP" = 1 ]; then say "WIRING_COVERAGE_TMP=$WORK"; else trap 'rm -rf -- "${WORK:-}"' EXIT; fi
    check_root "$VA" "$CW" "$MANIFEST" "$ALLOW"
}

main "$@"
