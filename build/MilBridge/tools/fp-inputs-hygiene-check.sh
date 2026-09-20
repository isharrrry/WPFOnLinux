#!/usr/bin/env bash
# fp-inputs-hygiene-check.sh —— `fp_inputs()` 覆盖面「**不许含构建产物**」的自检牙（**纯读、零 `dotnet`**）
#
# 【它防什么】`build/close-wave.sh` 的 `fp_inputs()` 是**手写输入指纹**。它的覆盖面一旦吃进
#   **构建产物**（`obj/**`、`bin/**`、`.artifacts/**`），这个指纹量的就**不是输入**了 ——
#   `#28` 已实测过这一族：`find src/WpfGfx.Linux -type f -name '*.cs'` 没排除 `obj/` ⇒ 吃进 **2 份**
#   生成件（`WpfGfx.Linux.AssemblyInfo.cs` 与 `.NETCoreApp,Version=v10.0.AssemblyAttributes.cs`）
#   ⇒ **每构建一次 `inputs_fp` 就变一次**（现场：`close-wave` 记 `d409b483…`，其后 `verify-all`
#   只跑了一次 `dotnet build` ⇒ 当场变成 `4a3519ea…`，**期间无人手写任何覆盖面文件**）。
#   而 `close-wave.sh` 的 `[4/6]`「输入稳定性 波前==波后」审的本来是「**有没有人手写改动**」
#   ⇒ 不修，则这条断言**可以被构建本身打穿**。
#   `#29` W29B 把同族**另两处**也封了（`patch-*.py` 那条 `-o` 链、`build/shims/**/*.cs`）——
#   那两处**当时恰好 0 命中**（"恰好没坏"，不是"被看着"）。**本脚本就是看住它的那颗牙**：
#   将来任何人把产物吸进覆盖面 ⇒ 本步**必红并逐条点名**。
#
# 【判据（三态）】**0 = PASS**（覆盖面里 0 件产物）｜**1 = FAIL**（发现产物路径 ⇒ 逐条点名）｜**2 = NOINFO**
#   ⚠️ `NOINFO` **绝不是绿**：取不到覆盖面 / 源件缺失 / 解析失败 / 拦截不完备 —— 一律 `rc=2` 并给原因
#      （纪律 21/27/28：**"没声明"不许当绿**；`verify-all.sh` 对任何非 0 都判 `❌`）。
#   ⚠️ 与 `build/MilBridge/tools/build-hygiene-import-check.sh` 的三态**刻意同形**（`0/1/2`），
#      与 `baseline-sha-check.sh:14` 那种「FAIL 与 NOINFO 都 `rc=1`」**不同**：本处把 `NOINFO` 单列，
#      只是**不让诊断面丢信息**（两种做法在 `verify-all.sh` 里都不会变绿）。
#
# ─────────────────────────────────────────────────────────────────────────────
# 【覆盖面怎么取（**本件的设计核心**）】`inputs_fp` 是**一个哈希** ⇒ **反推不出件清单**。两条路：
#
#   (a) **第二实现**：照抄那几条 `find` 在本件里重写一遍。**本件拒绝**。理由不是洁癖，
#       是 `#28` 留下的教训原文：「**同一份逻辑存在两处必然分叉**，那次就写错了一个指纹进基线」。
#       更致命的一点：核对器与被核对者**一起漂** ⇒ 当有人把覆盖面**偷偷改小**（少收一个目录）时，
#       第二实现会**同步缩水**，于是本牙**在该响的时候反而是绿的** —— 那正是本仓库最怕的
#       「射程悄悄缩到零而它还是绿的」（见 `D-R4`）。
#
#   (b) **同码路径拦截**（**本件采用**）：把 `close-wave.sh` 里 `fp_inputs()` 的**函数体原样抽出**
#       （`sed -n '/^fp_inputs()/,/^}/p'`）在**本进程内**执行；同时**只**把它的三个生产者拦住 ——
#         · `find` / `printf`  ⇒ 同 shell 的**函数**拦（函数的查找优先于外部命令与 builtin）
#         · `sha256sum`      ⇒ `xargs` 是 **exec**、看不见 shell 函数 ⇒ 改在 **`PATH` 前置一个同名
#                               shim 脚本**拦（`xargs` 走 `execvp`，吃 `PATH`）。shim 把它收到的
#                               **argv 记下来**再 `exec` 真件 ⇒ 这就拿到**权威件集合**（真正被哈希的那些）。
#       ⇒ **逻辑只有一份**（就是被测那一份），本件**不重写任何 `find`**。
#
#   (b) 的三条**机器守卫**（任一不满足 ⇒ `NOINFO`，**不许当绿**）：
#     ① **不扰动**：拦截跑出的指纹 必须 `==` **无拦截**跑出的指纹 —— 否则说明拦截改了行为；
#     ② **完备**：**拦截到的路径集合** 与 **实际交给 `sha256sum` 的 argv 集合** 必须 `cmp` 逐字节相同
#        —— 这是"**我有没有漏掉某个生产者**"的直接机器证（**不是**推理）；
#     ③ **白名单**（**启发式，只是把 ② 之外的未知生产者提前挡住**）：函数体去掉注释后出现的
#        **命令词**只许是 `find`/`printf`/`sort`/`xargs`/`sha256sum`/`cut` —— 出现别的 ⇒ `NOINFO`。
#
#   ⚠️ **残留风险（如实写、不藏）**：若将来 `fp_inputs()` 改用**绝对路径**调起生产者
#      （`/usr/bin/find`）或改用本件不认识的调用方式，则 ③ 会漏过（正则不收 `/` 开头的词），
#      但 ② **仍会抓到**（`sha256sum` 的 argv 与拦截集合对不上）⇒ 结果是 **`NOINFO` 而不是假绿**。
#       **这正是本设计要的失败方向**：算不出来就喊算不出来，绝不当绿。
#
# 【临时文件（纪律 63）】本件所有临时件都在**自己 `mktemp -d` 出来的目录**里，且 `mktemp` 走 `TMPDIR`
#   ⇒ 沙箱 / 并发车道各跑各的（`#28` 有车道没隔离 `TMPDIR` ⇒ **同一个未改脚本三次跑出三个结果**）。
#   `--debug-tmp` 打印它实际用的目录且**不清理**（供自测断言「确实落在自己沙箱的 `TMPDIR` 下」）。
#
# 【成本】单趟 ≤1 s（现场 110 件、秒级）、**零 `dotnet`**、**零世代成本**（不动九位/不动 `GEN_KEYS`）、
#   不动 `known-red.json`、**不动被测树**（纯读）。
#
# 反极性自测：`--selftest`（自带 `TMPDIR`；含「往覆盖面注入产物 ⇒ 必红」与「修后件不再吃产物」
#   的**成对读数**，见下）
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ⚠️ 必须是**绝对**路径：`--selftest` 会 `cd` 进沙箱再以 `bash "$SELF"` 拉起子进程
#   —— 相对路径在那里会 `rc=127`（"从来没有跑过"，本项目栽过三次的那种）
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
REAL_ROOT="$(cd "$HERE/../../.." && pwd)"
ROOT="${FPHYG_ROOT:-$REAL_ROOT}"
SOURCE="${FPHYG_SOURCE:-$ROOT/build/close-wave.sh}"
KEEP_TMP=0

# 覆盖面里**不许出现**的路径（产物目录：`obj/` `bin/` `.artifacts/` 任一层）
ART_RE='(^|/)(obj|bin|\.artifacts)(/|$)'
# 可选档：临时/备份文件后缀（同一族"手写覆盖面把垃圾吸进来"）
TMP_RE='(~|\.tmp|\.swp|\.bak|\.orig|\.rej)$'
# ③ 白名单：允许出现的命令词（其余 ⇒ 拦截可能不完备 ⇒ NOINFO）
ALLOWED_PRODUCERS=' cut find printf sha256sum sort xargs '

REAL_SHA256SUM="$(type -P sha256sum || true)"
CAP_N=0
ART_N=0
ART=()
NOINFO_REASON=''
CAP_DIR_USED=''

say() { printf '%s\n' "$*"; }
sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }

usage() {
    cat <<'TXT'
用法：
  fp-inputs-hygiene-check.sh [--root DIR] [--source PATH] [--debug-tmp]
  fp-inputs-hygiene-check.sh --selftest

判据：`build/close-wave.sh` 的 `fp_inputs()` 覆盖面里**不许**出现落在
      `obj/`｜`bin/`｜`.artifacts/` 下的路径（以及 `.tmp`/`~` 结尾的临时候选）。
rc：0 = PASS（干净）｜1 = FAIL（发现产物路径，逐条点名）｜2 = NOINFO（算不出来 ⇒ **不是绿**）
环境：FPHYG_ROOT（树根，默认=本脚本上溯三级）｜FPHYG_SOURCE（被测 close-wave.sh）
TXT
}

# ── 取覆盖面：在同码路径上拦 `find`/`printf`/`sha256sum`；三条守卫不过 ⇒ NOINFO ────────────
capture() {
    local cw="$1" body capdir cap hashed fnfile real_hash intra_hash words w p

    CAP_N=0; ART_N=0; ART=(); NOINFO_REASON=''

    [ -f "$cw" ] || { NOINFO_REASON="source-missing source=$cw（**取不到覆盖面 ⇒ 不许当绿**）"; return 2; }
    [ -n "$REAL_SHA256SUM" ] || { NOINFO_REASON='sha256sum-not-found（PATH 上没有 sha256sum）'; return 2; }
    [ -d "$ROOT" ] || { NOINFO_REASON="root-missing root=$ROOT"; return 2; }

    body="$(sed -n '/^fp_inputs()/,/^}/p' "$cw" 2>/dev/null)"
    case "$body" in
        *'fp_inputs()'*) : ;;
        *) NOINFO_REASON="fp-inputs-not-found source=$cw（sed 抽不出 fp_inputs() 的函数体 ⇒ 解析失败）"; return 2 ;;
    esac

    # ── ③ 生产者白名单（启发式；真正的完备性证明是下面的 ② cmp）─────────────────
    words="$(printf '%s\n' "$body" | sed 's/#.*$//' | tr ';|{}' '\n\n\n\n' \
             | awk '{print $1}' | grep -E '^[A-Za-z_][A-Za-z0-9_]*$' | LC_ALL=C sort -u)"
    while IFS= read -r w; do
        [ -n "$w" ] || continue
        case "$ALLOWED_PRODUCERS" in
            *" $w "*) : ;;
            *) NOINFO_REASON="unrecognized-producer word=$w（本件只认识 find/printf/sort/xargs/sha256sum/cut ⇒ 拦截可能不完备 ⇒ **不许当绿**）"; return 2 ;;
        esac
    done <<< "$words"

    capdir="$(mktemp -d "${TMPDIR:-/tmp}/fp-inputs-hygiene.XXXXXX")" \
        || { NOINFO_REASON="mktemp-failed TMPDIR=${TMPDIR:-/tmp}"; return 2; }
    CAP_DIR_USED="$capdir"
    if [ "$KEEP_TMP" != 1 ]; then trap 'rm -rf "$CAP_DIR_USED"' EXIT; fi

    cap="$capdir/intercepted.txt"; hashed="$capdir/hashed.txt"; fnfile="$capdir/fn.sh"
    : >"$cap"; : >"$hashed"
    printf '%s\n' "$body" 'fp_inputs' >"$fnfile"

    # ① 无拦截跑一趟（真值）
    real_hash="$( cd "$ROOT" 2>/dev/null && bash "$fnfile" 2>/dev/null )" || true
    [ -n "$real_hash" ] || { NOINFO_REASON="fp-inputs-produced-nothing source=$cw（真件本身没吐出指纹）"; return 2; }

    # `xargs` 是 exec、看不见 shell 函数 ⇒ 用 PATH 前置的同名 shim 收 argv
    mkdir -p "$capdir/pathbin"
    cat >"$capdir/pathbin/sha256sum" <<'SHIM'
#!/usr/bin/env bash
if [ "$#" -gt 0 ]; then printf '%s\n' "$@" >>"$FPHYG_HASHED"; fi
exec "$FPHYG_REAL_SHA256SUM" "$@"
SHIM
    chmod +x "$capdir/pathbin/sha256sum"

    # ② 拦截跑一趟（同码路径：函数体一个字都没改）
    intra_hash="$(
        cd "$ROOT" 2>/dev/null || exit 2
        export FPHYG_CAP="$cap" FPHYG_HASHED="$hashed" FPHYG_REAL_SHA256SUM="$REAL_SHA256SUM"
        export PATH="$capdir/pathbin:$PATH"
        find() {
            local o
            o="$(command find "$@")" || return $?
            [ -n "$o" ] || return 0
            command printf '%s\n' "$o" >>"$FPHYG_CAP"
            command printf '%s\n' "$o"
        }
        printf() {
            if [ "${1:-}" = '%s\n' ]; then command printf '%s\n' "${@:2}" >>"$FPHYG_CAP"; fi
            command printf "$@"
        }
        source "$fnfile"
    )" 2>/dev/null

    # 守卫①：拦截不得扰动被测函数
    if [ "$real_hash" != "$intra_hash" ]; then
        NOINFO_REASON="interception-perturbed real=${real_hash:0:16} intra=${intra_hash:0:16}（拦截改了被测函数的行为 ⇒ 读数不可用）"
        return 2
    fi
    # 守卫②：拦截集合 == 真正被哈希的 argv 集合（**完备性机器证**）
    LC_ALL=C sort "$cap" >"$capdir/cap.sorted"
    LC_ALL=C sort "$hashed" >"$capdir/hashed.sorted"
    if ! cmp -s "$capdir/cap.sorted" "$capdir/hashed.sorted"; then
        NOINFO_REASON="interception-incomplete 拦截到=$(wc -l <"$cap" | tr -d ' ') 件 实际被哈希=$(wc -l <"$hashed" | tr -d ' ') 件（有生产者没被拦住 ⇒ 覆盖面的清单不完整 ⇒ **不许当绿**）"
        return 2
    fi
    # 守卫③：覆盖面不得为空（"0 件"也是一种算不出来）
    if [ ! -s "$hashed" ]; then
        NOINFO_REASON="coverage-empty source=$cw（覆盖面 0 件 ⇒ 本牙无从判断 ⇒ **不许当绿**）"
        return 2
    fi

    # ── 判据：逐个路径查产物目录 / 临时候选 ────────────────────────────────────
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        CAP_N=$((CAP_N + 1))
        if grep -qE "$ART_RE" <<<"$p"; then ART+=("ARTIFACT|$p"); ART_N=$((ART_N + 1)); continue; fi
        if grep -qE "$TMP_RE" <<<"$p"; then ART+=("TEMP|$p");     ART_N=$((ART_N + 1)); continue; fi
    done <"$hashed"
    return 0
}

noinfo() { say "FP_INPUTS_HYGIENE=NOINFO reason=$1"; return 2; }

run_check() {
    local cw="${1:-$SOURCE}" s e
    [ -n "$cw" ] || { noinfo 'source-unset（没有指定被测 close-wave.sh）'; return 2; }
    capture "$cw" || { noinfo "${NOINFO_REASON:-unknown}"; return 2; }
    s="$(sha16 "$cw")"
    say "FPHYG_SOURCE=$cw sha16=${s:-NA}"
    say "FPHYG_COVERAGE_N=$CAP_N"
    say "FPHYG_ARTIFACT_N=$ART_N"
    if [ "$ART_N" -gt 0 ]; then
        for e in "${ART[@]}"; do
            say "FP_INPUTS_DIRT=FAIL kind=${e%%|*} path=${e#*|}（这句话会被哈希进 inputs_fp ⇒ **本指纹量的不是输入**：产物一变它就变）"
        done
        say "FP_INPUTS_HYGIENE=FAIL reason=coverage-contains-artifacts artifact_n=$ART_N coverage_n=$CAP_N"
        return 1
    fi
    say "FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=$CAP_N artifact_n=0"
    return 0
}

# ── `--selftest`：夹具全部在**自带 `TMPDIR`** 的沙箱里，且**用 `cp -p` 真复制**（绝不 `ln`）────
run_selftest() {
    # ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、不许冒充红）──
    #   本件自测以 `bash "$SELF"` **重入自己**（`:291`/`:321`）⇒ bash 每次为新子进程从磁盘**重读**本件
    #   ⇒ 父进程按旧版造夹具、子进程按新版判 ⇒ **改件窗口里出的红是凭空的红**。
    #   口径：**开头记 sha16、结尾再算一次**；不等 ⇒ `ST_ATTEST=NOINFO` 并点名（含 sha0/sha1 与内层 rc），
    #   统一 **rc=2**（`NOINFO` 码，不与 `FAIL` 混）。只加在 `--selftest` 路径；**生产路径一字未动**；
    #   不删例、不放宽任何期望（成对读数见 `$HOME/w33b-report.md`）。
    if [ -z "${ST_ATTEST_INNER:-}" ]; then
        ST_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
        ST0="$(sha256sum "$ST_SELF" | cut -c1-16)"
        printf 'ST_ATTEST=OPEN self=%s sha16=%s\n' "$ST_SELF" "$ST0"
        if [ "${1:-}" = '--selftest' ]; then ST_IN=("$@"); else ST_IN=(--selftest "$@"); fi
        ST_OUT="$(ST_ATTEST_INNER=1 bash "$ST_SELF" "${ST_IN[@]}" 2>&1)"; ST_RC=$?
        printf '%s\n' "$ST_OUT"
        ST1="$(sha256sum "$ST_SELF" | cut -c1-16)"
        if [ "$ST1" != "$ST0" ]; then
            printf 'ST_ATTEST=NOINFO reason=self-rewritten-during-selftest（本件在自测期间被改写 ⇒ 上面的读数不可归因）self=%s sha0=%s sha1=%s inner_rc=%s\n' \
                   "$ST_SELF" "$ST0" "$ST1" "$ST_RC"
            return 2
        fi
        printf 'ST_ATTEST=PASS self=%s sha16=%s（自测期间本件未变 ⇒ 读数可归因）\n' "$ST_SELF" "$ST0"
        return "$ST_RC"
    fi
    local sb fix total=0 pass=0 fail=0
    sb="$(mktemp -d "${TMPDIR:-/tmp}/fphyg-selftest.XXXXXX")" || { say "SELFTEST=FAIL reason=mktemp-failed"; return 1; }
    export TMPDIR="$sb/tmp"; mkdir -p "$TMPDIR"
    fix="$sb/repo"

    local tmp_before tmp_after
    tmp_before="$(find /tmp -maxdepth 1 \( -name 'fp-inputs-hygiene.*' -o -name 'fphyg-selftest.*' \) 2>/dev/null | LC_ALL=C sort)"

    # 夹具树：一份干净件 + 四份**产物族毒件**（三种模式各一 + 一个 src 下的）
    mkdir -p "$fix/build/shims/obj/Debug/net10.0" "$fix/build/shims/bin/Debug" "$fix/build/shims/.artifacts" \
             "$fix/build/MilBridge/tools" "$fix/src/WpfGfx.Linux.Native/tools" "$fix/src/WpfGfx.Linux/obj/Debug/net10.0" \
             "$fix/build/declared/obj"
    printf 'clean\n'    >"$fix/build/shims/Clean.cs"
    printf 'poison\n'   >"$fix/build/shims/obj/Debug/net10.0/Poison.cs"     # obj 模式
    printf 'poison\n'   >"$fix/build/shims/bin/Debug/Output.cs"             # bin 模式
    printf 'poison\n'   >"$fix/build/shims/.artifacts/Stale.cs"             # .artifacts 模式
    printf 'poison\n'   >"$fix/src/WpfGfx.Linux/obj/Debug/net10.0/Poison2.cs"
    printf 'clean\n'    >"$fix/src/WpfGfx.Linux/Foo.cs"
    printf 'clean\n'    >"$fix/src/WpfGfx.Linux.Native/tools/patch-demo.py"
    printf 'x\n'        >"$fix/build/MilBridge/tools/tline-gate.sh"
    printf 'x\n'        >"$fix/build/MilBridge/known-red.json"
    printf 'x\n'        >"$fix/build/port-lib.py"
    printf 'x\n'        >"$fix/build/integration-wave.sh"
    printf 'x\n'        >"$fix/build/declared/obj/Declared.cs"
    printf 'x\n'        >"$fix/build/declared/Leftover.cs.tmp"

    # 修后件 = **真复制**现件；修前仿真件 = 现件把三组排除子句摘掉（模拟 `#28`/`#29` 之前）
    cp -p "$SOURCE" "$sb/fix-after.sh"
    sed -e "s| -not -path '\*/obj/\*'||g" \
        -e "s| -not -path '\*/bin/\*'||g" \
        -e "s| -not -path '\*/.artifacts/\*'||g" "$SOURCE" >"$sb/fix-before.sh"
    # 夹具可信性守卫：抽出的函数体**去注释后**不许再有排除子句（注释里的引文不算）
    if grep -q -- "-not -path '" <<<"$(sed -n '/^fp_inputs()/,/^}/p' "$sb/fix-before.sh" | sed 's/#.*$//')"; then
        say "SELFTEST=FAIL reason=fixture-strip-failed（修前仿真件里仍有排除子句 ⇒ 夹具不可信）"
        rm -rf "$sb"; return 1
    fi
    # 声明字面量里塞产物 / 塞临时件（证明本牙**不只审 find 分支**，也审 `printf` 声明）
    sed "s|build/MilBridge/known-red.json|build/MilBridge/known-red.json build/declared/obj/Declared.cs|" \
        "$sb/fix-after.sh" >"$sb/fix-declared.sh"
    sed "s|build/MilBridge/known-red.json|build/MilBridge/known-red.json build/declared/Leftover.cs.tmp|" \
        "$sb/fix-after.sh" >"$sb/fix-tmpfile.sh"
    # 覆盖面为空 / 没有 fp_inputs() / 生产者不在白名单 / 生产者绕过拦截（绝对路径）
    cat >"$sb/fix-empty.sh" <<'EOF'
fp_inputs() {
    { :; } | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -d' ' -f1
}
EOF
    cat >"$sb/fix-nofunc.sh" <<'EOF'
# 这份件里根本没有 fp_inputs()
other_thing() { echo hi; }
EOF
    cat >"$sb/fix-ls.sh" <<'EOF'
fp_inputs() {
    { ls "$FPHYG_FIXTURE_SHIMS"/*.cs; printf '%s\n' build/MilBridge/known-red.json; } \
        | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -d' ' -f1
}
EOF
    local findbin; findbin="$(type -P find)"
    sed "s|__FIND__|$findbin|" >"$sb/fix-abspath.sh" <<'EOF'
fp_inputs() {
    { __FIND__ build/shims -type f -name '*.cs'; printf '%s\n' build/MilBridge/known-red.json; } \
        | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -d' ' -f1
}
EOF

    # 逐例跑（子进程 = 本脚本自身）
    one() {  # one <编号> <期望rc> <源件> [<必须出现的正则>]
        total=$((total + 1))
        local out rc ok=1 key
        out="$(cd "$sb" && FPHYG_ROOT="$fix" FPHYG_SOURCE="$3" FPHYG_FIXTURE_SHIMS="$fix/build/shims" \
               bash "$SELF" 2>&1)"; rc=$?
        key="$(printf '%s\n' "$out" | grep -E '^FP_INPUTS_HYGIENE=' | head -1)"
        [ "$rc" = "$2" ] || ok=0
        if [ -n "${4:-}" ] && ! grep -qE "$4" <<< "$out"; then ok=0; fi
        if [ "$ok" = 1 ]; then
            pass=$((pass + 1)); say "SELFTEST CASE $1 = PASS rc=$rc  $key"
        else
            fail=$((fail + 1)); say "SELFTEST CASE $1 = FAIL rc=$rc want=$2 wantpat=${4:-<none>}  $key"
            printf '%s\n' "$out" | sed 's/^/      | /'
        fi
    }

    one S1-clean-fixed        0 "$sb/fix-after.sh"    '^FP_INPUTS_HYGIENE=PASS'
    one S2-poison-prefix      1 "$sb/fix-before.sh"   'kind=ARTIFACT path=build/shims/obj/Debug/net10.0/Poison.cs'
    one S2b-poison-bin        1 "$sb/fix-before.sh"   'kind=ARTIFACT path=build/shims/bin/Debug/Output.cs'
    one S2c-poison-artifacts  1 "$sb/fix-before.sh"   'kind=ARTIFACT path=build/shims/\.artifacts/Stale.cs'
    one S2d-poison-src-obj    1 "$sb/fix-before.sh"   'kind=ARTIFACT path=src/WpfGfx\.Linux/obj/Debug/net10\.0/Poison2\.cs'
    one S3-poison-fixed       0 "$sb/fix-after.sh"    '^FP_INPUTS_HYGIENE=PASS'
    # S4 的注入路径 `build/declared/obj/Declared.cs` **任何 `find` 分支都到不了**（修后件已排除 `obj/`）
    #   ⇒ 它被点名就**只能**来自 `printf` 声明行 ⇒ 证明本牙审的是**整个覆盖面**，不只是 `find`。
    one S4-declared-artifact  1 "$sb/fix-declared.sh" 'kind=ARTIFACT path=build/declared/obj/Declared\.cs'
    one S5-declared-temp      1 "$sb/fix-tmpfile.sh"  'kind=TEMP path=build/declared/Leftover.cs\.tmp'
    one S6-coverage-empty     2 "$sb/fix-empty.sh"    'reason=coverage-empty'
    one S7-no-fp-inputs       2 "$sb/fix-nofunc.sh"   'reason=fp-inputs-not-found'
    one S8-source-missing     2 "$sb/nope-close-wave.sh" 'reason=source-missing'
    one S9-unknown-producer   2 "$sb/fix-ls.sh"       'reason=unrecognized-producer word=ls'
    one SA-interception-gap   2 "$sb/fix-abspath.sh"  'reason=interception-incomplete'

    # 纪律 63：本趟的临时件必须落在**本沙箱的 TMPDIR** 下，且不得在共享 /tmp 留痕
    local dtmp
    dtmp="$(cd "$sb" && FPHYG_ROOT="$fix" FPHYG_SOURCE="$sb/fix-after.sh" bash "$SELF" --debug-tmp 2>&1 \
            | sed -n 's/^FPHYG_TMP_DIR=//p' | head -1)"
    total=$((total + 1))
    case "$dtmp" in
        "$TMPDIR"/*) pass=$((pass + 1)); say "SELFTEST CASE SB-tmpdir = PASS 用的临时目录=$dtmp（在 \$TMPDIR=$TMPDIR 之下）" ;;
        *) fail=$((fail + 1)); say "SELFTEST CASE SB-tmpdir = FAIL 用的临时目录='$dtmp' 不在 \$TMPDIR=$TMPDIR 之下" ;;
    esac
    rm -rf "$dtmp" 2>/dev/null

    tmp_after="$(find /tmp -maxdepth 1 \( -name 'fp-inputs-hygiene.*' -o -name 'fphyg-selftest.*' \) 2>/dev/null | LC_ALL=C sort)"
    total=$((total + 1))
    if [ "$tmp_before" = "$tmp_after" ]; then
        pass=$((pass + 1)); say "SELFTEST CASE SB-no-tmp-leak = PASS 共享 /tmp 上的 fp-inputs-hygiene.*/fphyg-selftest.* 开工==收工"
    else
        fail=$((fail + 1)); say "SELFTEST CASE SB-no-tmp-leak = FAIL 共享 /tmp 有新痕：before=[$tmp_before] after=[$tmp_after]"
    fi

    # 反极性总闸：S2 与 S3 是**成对**的（同一棵毒树，只换件）⇒ 必须一个红一个绿
    total=$((total + 1))
    if [ "$fail" -eq 0 ]; then
        pass=$((pass + 1)); say "SELFTEST CASE SB-pair = PASS 同一棵毒树：修前件红 / 修后件绿（本牙咬得住，且修法真的挡掉了这一族）"
    else
        fail=$((fail + 1)); say "SELFTEST CASE SB-pair = FAIL 见上面的 FAIL 明细"
    fi

    say "SELFTEST_SANDBOX=$sb"
    if [ "$fail" -eq 0 ]; then
        say "SELFTEST=PASS total=$total pass=$pass fail=$fail"
        rm -rf "$sb"; return 0
    fi
    say "SELFTEST=FAIL total=$total pass=$pass fail=$fail（沙箱保留供诊断）"
    return 1
}

# ── 入口 ─────────────────────────────────────────────────────────────────────
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root)        ROOT="$2"; SOURCE="${FPHYG_SOURCE:-$ROOT/build/close-wave.sh}"; shift 2 ;;
        --source)      SOURCE="$2"; shift 2 ;;
        --debug-tmp)   KEEP_TMP=1; shift ;;
        --selftest)    run_selftest; exit $? ;;
        -h|--help)     usage; exit 0 ;;
        *)             say "unknown-arg: $1"; usage; exit 2 ;;
    esac
done

if [ "$KEEP_TMP" = 1 ]; then
    run_check "$SOURCE"; rc=$?
    [ -n "$CAP_DIR_USED" ] && say "FPHYG_TMP_DIR=$CAP_DIR_USED"
    exit "$rc"
fi

run_check "$SOURCE"
exit $?
