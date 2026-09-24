#!/usr/bin/env bash
# fp-manifest-teeth-check.sh —— `D-G120` 的**两条"指纹类必备牙"**（纯读、零 `dotnet`、零构建）
#
# ═══════════════════════════════════════════════════════════════════════════════
# 【它防什么】`D-G120`：`build/close-wave.sh` 的 `fp_inputs()` 是一张**手写输入指纹**，
#   形状是 `{ printf '%s\n' <件表…> \ … } | LC_ALL=C sort | xargs sha256sum | sha256sum | cut`。
#   2026-09-24 真咬到：**行尾 `\` 续行里插进了一行 `#` 注释** ⇒ bash **先把 `\`+换行拼成一个
#   逻辑行、再认注释** ⇒ 拼出来的那一行里的 `#` 起注释 ⇒ **吃掉参数表下半截**；
#   紧随的物理行变成**新命令被执行**，它的 stdout 落进 `{ … } | sort | xargs sha256sum`
#   ⇒ `sha256sum` 去 hash 这些"文件名"、**真名被吞** ⇒ **件数读错（160 vs 161）＋ 指纹凭空
#   多出一个中间值**。
#   （本车道现场复刻读数见 `~/w152a/w65/logs/04-polarity-faithful.log`：真件参数表 **33** 件，
#    污染后交给 `sha256sum` 的 argv 变成 **867** 个，最终指纹落到 `e3b0c442…b7852b855`
#    ＝ **空输入的 sha256**，而**管道 rc 仍是 0**。）
#
# 【为什么现有那条断言抓不到（本件的存在理由）】`close-wave.sh` 只有「波前 `IN_FP_0`
#   == 波后 `IN_FP_1`」／「预测 == 实测」这一族断言。它们审的是**两次算出来一样不一样**，
#   而**两次都走同一条被污染的管道** ⇒ **同源污染**：
#     · 被吞掉的真名**从头到尾没进过清单** ⇒ 两边**同样地少** ⇒ 断言绿；
#     · 管道的 `rc` 取自最后一段 `cut` ⇒ **rc 也绿**（现场实测 `pipeline_rc=0`）；
#     · 落到 `inputs_fp` 上的仍是一个**形状完美的 64 位十六进制** ⇒ 没有任何一格能看出"少了一件"。
#   ⇒ **只有与计算路径无关的两条牙**能看见它：**清单逐行形状** ＋ **件数对账**。
#
# 【判据（三态，与 `fp-inputs-hygiene-check.sh`／`shell-quote-trap-check.sh` 刻意同形）】
#   **0 = PASS**｜**1 = FAIL**（逐条点名）｜**2 = NOINFO**（算不出来 ⇒ **绝不是绿**）
#   ⓪ **`EMPTY-MANIFEST`**：清单**一件都没有** ⇒ FAIL（这正是 `D-G120` 污染的终态）。
#   ① **`MANIFEST-SHAPE`**：清单每个**非空**行必须匹配 `^[0-9a-f]{64}  .+`（64 位小写十六进制
#      ＋ **两个空格** ＋ 至少一个字符的路径）。不匹配 ⇒ FAIL，逐条点名 `file:line:` ＋ **该行原文**。
#   ② **`FILES-N`**：`files_n`（**非空行数**）必须 == **声明**的期望件数。两种声明源：
#        · `--expect N`  —— **显式声明的常数**（推荐：只有它**与生产路径无关**）；
#        · `--paths FILE`—— 一份**独立产出的名字表**，此时同时做**集合比对**
#          （`NAME-SWALLOWED` 真名被吞 / `NAME-EXTRA` 异物混入，逐条点名）。
#      **一个都没给** ⇒ `NOINFO reason=no-expected-count`（纪律：**没声明不许当绿**）。
#
# 【口径与边界（如实写）】
#   · 空行**不计**入 `files_n`、也不判形状（与仓内通行的 `grep -c .` 同口径）；空行数另印 `blank_n`。
#     ⇒ "把一条真名换成空行"这一族**形状牙看不见**，靠**件数牙**关。
#   · `sha256sum --binary` 的形态是 `hash *path`（一个空格＋星号）⇒ 本牙**判红**。本仓生产面
#     （`xargs sha256sum`，文本模式）**一律两个空格**；将来若改用 `--binary`，那是**该改来的地方看得见**。
#   · **重复路径**只**印**（`FP_MANIFEST_DUP`）**不判红**：它不代表污染，只是"同一件被列了两次"。
#     （件数牙仍按**行数**判 ⇒ 重复会把 `files_n` 顶上去，那时它自己就会红。）
#   · 本件**只读**：不产指纹、不写被审树、不动九位 / `GEN_KEYS` / `known-red.json`。
#
# 【定位一律用内容锚，不引行号（`#65` 追加的件头要求）】本件从不按行号定位任何东西：
#   它只按"**清单的每一行必须长什么样**"判（`^[0-9a-f]{64}  .+`）。同族的样本件（`pos.sh`/`neg.sh`）
#   由 `two-pol.sh` 用三级内容锚（`fp_inputs() {` → 汇点 → 汇点之上最近的 `printf`）提取，
#   行号**只作记录**。理由已现场咬到：`build/close-wave.sh` 被 `#64` 改过（行区间必然错位）。
#
# 【临时文件（纪律 63）】一律在**自己 `mktemp -d`** 的目录里（走 `TMPDIR`）⇒ 并发车道互不干扰。
#   `--debug-tmp` 打印实际目录且**不清理**。
#
# 【接线（**尚未接线**，属落地趟的事）】落地时建议在 `fp_inputs()` 尾部把清单 `tee` 到一个临时件
#   （`tee` **不改 stdout** ⇒ `inputs_fp` 数值不变）再交本件；`--expect` 用**冻前那一代的件数常数**
#   （只有它不与生产路径同源）。⚠️ 本件若落进 `build/MilBridge/tools/`，它**不在** `fp_inputs()`
#   那张 `printf` 件表里 ⇒ **不落仓数据即可**；是否加进件表由主控决定（加入即再挪一次 `inputs_fp`）。
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
MAX_DIAG="${FT_MAX_DIAG:-8}"
KEEP_TMP=0
TMP_DIR_USED=''

say() { printf '%s\n' "$*"; }

usage() {
    cat <<'TXT'
用法：
  fp-manifest-teeth-check.sh --manifest FILE [--expect N | --paths FILE] [--debug-tmp]
  fp-manifest-teeth-check.sh --selftest

判据（三态）：0 = PASS｜1 = FAIL（逐条点名）｜2 = NOINFO（算不出来 ⇒ 不是绿）
  EMPTY-MANIFEST：清单零件 ⇒ FAIL
  MANIFEST-SHAPE：每个非空行必须匹配 ^[0-9a-f]{64}  .+
  FILES-N       ：files_n（非空行数）必须 == 声明的期望件数（--expect 或 --paths）
环境：FT_MAX_DIAG（每条打印上限，全量计数永远打在口径行里）
TXT
}

# ── 主判据 ─────────────────────────────────────────────────────────────────────
run_check() {
    local manifest="$1" expect="$2" paths="$3"
    local tmpd files_n files_n_uniq blank_n shape_bad dup_n
    local missing_n extra_n missing_lines extra_lines declared_paths_n preason count_bad set_bad
    local TMPBASE="${TMPDIR:-/tmp}"

    TMP_DIR_USED=''
    [ -n "$manifest" ] || { say 'FP_MANIFEST_TEETH=NOINFO reason=no-manifest'; return 2; }
    if [ ! -e "$manifest" ]; then
        say "FP_MANIFEST_TEETH=NOINFO reason=manifest-missing manifest=$manifest"
        return 2
    fi
    if [ ! -r "$manifest" ]; then
        say "FP_MANIFEST_TEETH=NOINFO reason=manifest-unreadable manifest=$manifest"
        return 2
    fi
    if ! command -v awk >/dev/null 2>&1; then
        say 'FP_MANIFEST_TEETH=NOINFO reason=awk-not-found（PATH 上没有 awk ⇒ 形状解析跑不起来）'
        return 2
    fi
    tmpd="$(mktemp -d "$TMPBASE/fp-manifest-teeth.XXXXXX" 2>/dev/null)" || {
        say "FP_MANIFEST_TEETH=NOINFO reason=mktemp-failed TMPBASE=$TMPBASE"; return 2; }
    TMP_DIR_USED="$tmpd"

    # ── 牙①：逐行形状（同时把 path 抽出来给牙②／集合比对用）────────────────────────
    # ⚠️ **不用** awk 的区间量词（`{64}`）—— mawk/gawk 的区间支持不一致；改成**长度门 ＋ 字符类**。
    awk -v max="$MAX_DIAG" '
        length($0) == 0 { blank++; next }
        {
            nonblank++
            h = substr($0, 1, 64)
            ok = 1
            if (length($0) < 67)                 ok = 0
            else if (substr($0, 65, 2) != "  ")  ok = 0
            else if (h ~ /[^0-9a-f]/)            ok = 0
            if (!ok) {
                bad++
                if (bad <= max) printf "BAD\t%d\t%s\n", NR, $0
                next
            }
            p = substr($0, 67)
            print "PATH\t" p
            if (seen[p]++) dup++
        }
        END { printf "STAT\t%d\t%d\t%d\t%d\n", nonblank + 0, blank + 0, bad + 0, dup + 0 }
    ' "$manifest" > "$tmpd/shape.out" 2>"$tmpd/awk.err"

    # ⚠️ 解析面为空 ⇒ **响亮失败**（纪律 27：两侧任一为空都不许静默）
    if ! grep -q '^STAT' "$tmpd/shape.out" 2>/dev/null; then
        say "FP_MANIFEST_TEETH=NOINFO reason=parser-produced-nothing manifest=$manifest（形状解析面连 STAT 行都没有 ⇒ 算不出来）"
        sed 's/^/    awk| /' "$tmpd/awk.err" 2>/dev/null | head -5
        [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2
    fi

    read -r files_n blank_n shape_bad dup_n <<ENDSTAT
$(awk -F'\t' '$1=="STAT"{print $2, $3, $4, $5}' "$tmpd/shape.out" | head -1)
ENDSTAT
    files_n=${files_n:-0}; blank_n=${blank_n:-0}; shape_bad=${shape_bad:-0}; dup_n=${dup_n:-0}
    files_n_uniq=$(( files_n - dup_n ))

    awk -F'\t' '$1=="PATH"{print $2}' "$tmpd/shape.out" | LC_ALL=C sort -u > "$tmpd/manifest.paths.u"

    say "FP_MANIFEST_SCAN manifest=$manifest files_n=$files_n files_n_uniq=$files_n_uniq blank_n=$blank_n shape_bad=$shape_bad dup_n=$dup_n declared_expect=${expect:-none} paths=${paths:-none}"

    if [ "$shape_bad" -gt 0 ]; then
        awk -F'\t' -v m="$manifest" -v max="$MAX_DIAG" '
            $1=="BAD" { if (++n <= max) printf "FP_MANIFEST_HIT kind=MANIFEST-SHAPE file=%s line=%s: %s\n", m, $2, $3 }' \
            "$tmpd/shape.out"
        say "FP_MANIFEST_TEETH=FAIL reason=manifest-shape bad=$shape_bad files_n=$files_n（清单里出现**不是「64 位小写十六进制 ＋ 两个空格 ＋ 路径」的行** ⇒ 它会被当『文件名』交给 sha256sum ⇒ 真名被吞、指纹多出中间值）"
        [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"
        return 1
    fi

    # ── ⓪ 零件清单 ⇒ 红（`D-G120` 污染的终态；**不许**因为"没有坏行"而绿）─────────────
    if [ "$files_n" -eq 0 ]; then
        say "FP_MANIFEST_TEETH=FAIL reason=empty-manifest files_n=0 blank_n=$blank_n（清单零件 = D-G120 污染的**终态**：真名全被吞 ⇒ 最终指纹落到**空输入的 sha256**，而管道 rc 仍是 0）"
        [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"
        return 1
    fi

    # ── 牙②：件数对账（**必须有声明源**，否则 NOINFO）────────────────────────────
    if [ -z "$expect" ] && [ -z "$paths" ]; then
        say "FP_MANIFEST_TEETH=NOINFO reason=no-expected-count files_n=$files_n（没声明期望件数 ⇒ 判不出『多没多／少没少』 ⇒ **不是绿**；用 --expect N 或 --paths FILE）"
        [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"
        return 2
    fi

    if [ -n "$expect" ]; then
        case "$expect" in
            ''|*[!0-9]*)
                say "FP_MANIFEST_TEETH=NOINFO reason=expect-not-a-number expect=$expect"
                [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2 ;;
        esac
        if [ "$files_n" -ne "$expect" ]; then
            say "FP_MANIFEST_TEETH=FAIL reason=files-n-mismatch files_n=$files_n expect=$expect delta=$(( files_n - expect ))（件数对不上 ⇒ 有真名被吞或有异物混入；**形状可以完全合法**，只有这一格看得见）"
            [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"
            return 1
        fi
    fi

    if [ -n "$paths" ]; then
        if [ ! -r "$paths" ]; then
            say "FP_MANIFEST_TEETH=NOINFO reason=paths-unreadable paths=$paths"
            [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2
        fi
        LC_ALL=C sort -u "$paths" 2>/dev/null | grep . > "$tmpd/paths.u" || true
        if [ ! -s "$tmpd/paths.u" ]; then
            say "FP_MANIFEST_TEETH=NOINFO reason=paths-empty paths=$paths（声明面为空 ⇒ 对拍必定假绿 ⇒ **不算绿**）"
            [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"; return 2
        fi
        declared_paths_n="$(grep -c . "$tmpd/paths.u" 2>/dev/null)"; declared_paths_n=${declared_paths_n:-0}
        # ⚠️ 两条牙**都要报**：先**不**短路（本件第一版在这里先判件数就 `return` ⇒
        #    「哪几个名字被吞了」那一格**永远打不出来**，`--selftest` 的 D5b 当场抓住）。
        #    ⇒ 先算完整套/缺、再合起来出**一个**判决（reason 用 `+` 拼）。
        missing_lines="$(LC_ALL=C comm -23 "$tmpd/paths.u" "$tmpd/manifest.paths.u" 2>/dev/null)"
        extra_lines="$(LC_ALL=C comm -13 "$tmpd/paths.u" "$tmpd/manifest.paths.u" 2>/dev/null)"
        missing_n="$(printf '%s\n' "$missing_lines" | grep -c . || true)"; missing_n=${missing_n:-0}
        extra_n="$(printf '%s\n' "$extra_lines" | grep -c . || true)";     extra_n=${extra_n:-0}
        count_bad=0; [ "$files_n" -ne "$declared_paths_n" ] && count_bad=1
        set_bad=0;   { [ "$missing_n" -gt 0 ] || [ "$extra_n" -gt 0 ]; } && set_bad=1
        if [ "$count_bad" -eq 1 ] || [ "$set_bad" -eq 1 ]; then
            printf '%s\n' "$missing_lines" | grep . | head -n "$MAX_DIAG" | while IFS= read -r l; do
                say "FP_MANIFEST_HIT kind=NAME-SWALLOWED file=$manifest name=$l"
            done
            printf '%s\n' "$extra_lines" | grep . | head -n "$MAX_DIAG" | while IFS= read -r l; do
                say "FP_MANIFEST_HIT kind=NAME-EXTRA file=$manifest name=$l"
            done
            preason=""
            if [ "$count_bad" -eq 1 ]; then preason="files-n-mismatch"; fi
            if [ "$set_bad" -eq 1 ]; then
                if [ -n "$preason" ]; then preason="$preason+name-set-mismatch"; else preason="name-set-mismatch"; fi
            fi
            say "FP_MANIFEST_TEETH=FAIL reason=$preason files_n=$files_n declared=$declared_paths_n declared_delta=$(( files_n - declared_paths_n )) missing=$missing_n extra=$extra_n（**真名被吞** / **异物混入** 逐条点名；集合比对，与哈希值无关）"
            [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"
            return 1
        fi
        say "FP_MANIFEST_SET=OK manifest_n=$files_n declared_n=$declared_paths_n（集合逐名相同）"
    fi

    say "FP_MANIFEST_TEETH=PASS reason=ok files_n=$files_n files_n_uniq=$files_n_uniq blank_n=$blank_n declared_expect=${expect:-none} declared_paths=${paths:-none}"
    if [ "$files_n_uniq" -lt "$files_n" ]; then
        say "FP_MANIFEST_DUP n=$(( files_n - files_n_uniq ))（**只印不判**：重复路径不代表污染，只是同一件被列了两次）"
    fi
    [ "$KEEP_TMP" = 1 ] || rm -rf "$tmpd"
    return 0
}

# ── 反极性自测 ─────────────────────────────────────────────────────────────────
run_selftest() {
    local sb total=0 pass=0 fail=0 dtmp i old1 old2
    local TMPBASE="${TMPDIR:-/tmp}"
    sb="$(mktemp -d "$TMPBASE/fp-manifest-selftest.XXXXXX")" || { say 'SELFTEST=FAIL reason=mktemp-failed'; return 1; }

    one() {  # one <编号> <期望rc> <必须出现> [<必须不出现>] <参数...>
        total=$((total + 1))
        local id="$1" want="$2" must="$3" mustnot="${4:-}"; shift 4 2>/dev/null || shift $#
        local out rc ok=1 key
        out="$(bash "$SELF" "$@" 2>&1)"; rc=$?
        key="$(printf '%s\n' "$out" | grep -E '^FP_MANIFEST_TEETH=' | head -1)"
        [ "$rc" = "$want" ] || ok=0
        if [ -n "$must" ] && ! grep -qE "$must" <<< "$out"; then ok=0; fi
        if [ -n "$mustnot" ] && grep -qE "$mustnot" <<< "$out"; then ok=0; fi
        if [ "$ok" = 1 ]; then
            pass=$((pass + 1)); say "SELFTEST CASE $id = PASS rc=$rc  $key"
        else
            fail=$((fail + 1))
            say "SELFTEST CASE $id = FAIL rc=$rc want=$want must='$must' mustnot='$mustnot'  $key"
            printf '%s\n' "$out" | sed 's/^/      | /'
        fi
    }

    # ── 夹具：干净清单（6 件；每行 = 64 位十六进制 ＋ 两空格 ＋ 路径）───────────────
    : > "$sb/clean.txt"
    for i in 1 2 3 4 5 6; do
        printf '%064d  build/xxx/file%s.sh\n' "$i" "$i" >> "$sb/clean.txt"
    done
    # ── **合成污染样本**：往清单里混一行 `BASELINERATE=NOINFO`（插在第 4 行）
    awk 'NR==4{print "BASELINERATE=NOINFO"} {print}' "$sb/clean.txt" > "$sb/polluted.txt"
    # ── 形状完全合法、但**少一件**（模拟"真名被吞"）──────────────────────────────
    awk 'NR!=4' "$sb/clean.txt" > "$sb/short.txt"
    # ── 独立产出的名字表（与 clean 同集合）／零件清单 ／ 带空行的干净清单 ────────────
    awk '{print substr($0, 67)}' "$sb/clean.txt" > "$sb/paths.txt"
    : > "$sb/empty.txt"
    { cat "$sb/clean.txt"; printf '\n\n'; } > "$sb/blanked.txt"

    # ★ D1：干净清单 ＋ 声明的期望件数 ⇒ 绿
    one D1-clean-pass                  0 '^FP_MANIFEST_TEETH=PASS .*files_n=6 ' '' --manifest "$sb/clean.txt" --expect 6
    # ★ D2：**合成污染样本**（`BASELINERATE=NOINFO` 混进清单）⇒ 牙①**必红并逐字点名该行**
    one D2-shape-catches-pollution     1 'FP_MANIFEST_HIT kind=MANIFEST-SHAPE file=.*line=4: BASELINERATE=NOINFO' '' --manifest "$sb/polluted.txt" --expect 7
    # ★ D2b：把期望件数改成"刚好等于污染后的 7"（**件数牙失去判别力**）⇒ 牙①**仍然必红**
    one D2b-shape-alone-still-red      1 '^FP_MANIFEST_TEETH=FAIL reason=manifest-shape bad=1 ' '' --manifest "$sb/polluted.txt" --expect 7
    # ★ D3：形状**完全合法**、只少一件（真名被吞）⇒ 牙①看不见（无 MANIFEST-SHAPE），**牙②必红**
    one D3-count-catches-swallowed     1 '^FP_MANIFEST_TEETH=FAIL reason=files-n-mismatch files_n=5 expect=6 delta=-1' 'MANIFEST-SHAPE' --manifest "$sb/short.txt" --expect 6
    # ★ D4：**没声明期望件数** ⇒ NOINFO（清单是干净的也**不许**当绿）
    one D4-no-expect-is-noinfo         2 '^FP_MANIFEST_TEETH=NOINFO reason=no-expected-count' '' --manifest "$sb/clean.txt"
    # ★ D5：名字表逐名成对 ⇒ 绿；D5b：少一件 ⇒ `NAME-SWALLOWED` 逐名点名
    one D5-paths-set-equal             0 '^FP_MANIFEST_SET=OK ' '' --manifest "$sb/clean.txt" --paths "$sb/paths.txt"
    one D5b-paths-set-mismatch         1 'FP_MANIFEST_HIT kind=NAME-SWALLOWED .*file4\.sh' '' --manifest "$sb/short.txt" --paths "$sb/paths.txt"
    # ★ D6：零件清单（D-G120 终态）⇒ 必红（**不许**因为"没有坏行"而绿）
    one D6-empty-manifest-red          1 '^FP_MANIFEST_TEETH=FAIL reason=empty-manifest' '' --manifest "$sb/empty.txt" --expect 33
    # ★ D7：空行不计件、也不判形状（口径可见）⇒ 仍绿，且 `blank_n=2` 被打出来
    one D7-blank-lines-not-counted     0 '^FP_MANIFEST_TEETH=PASS .*files_n=6 .*blank_n=2' '' --manifest "$sb/blanked.txt" --expect 6
    # ★ D8/D9：三态左半边 —— 取不到件 / 声明面为空 ⇒ NOINFO（**不是绿**）
    one D8-manifest-missing            2 '^FP_MANIFEST_TEETH=NOINFO reason=manifest-missing' '' --manifest "$sb/no-such-file.txt" --expect 1
    one D9-paths-empty                 2 '^FP_MANIFEST_TEETH=NOINFO reason=paths-empty' '' --manifest "$sb/clean.txt" --paths "$sb/empty.txt"

    # ── D10：**旧口径为什么抓不到**（同源污染的机制演示，机器证）────────────────────
    #   旧口径 = 「预测 == 实测」那一族：把**同一条被污染的清单**算两趟再比。两趟同源 ⇒ 相等 ⇒ 绿。
    #   ⚠️ 这条**不是**在说"sha256 不稳"，而是在说：**它算出来的东西与污染无关地自洽** ⇒
    #      没有任何一格能说"清单里有坏行"。D2/D2b/D3 才是能说的那两格。
    total=$((total + 1))
    old1="$(sha256sum "$sb/polluted.txt" | cut -c1-16)"
    old2="$(sha256sum "$sb/polluted.txt" | cut -c1-16)"
    if [ -n "$old1" ] && [ "$old1" = "$old2" ]; then
        pass=$((pass + 1))
        say "SELFTEST CASE D10-old-criterion-blind = PASS 旧口径（预测==实测）在同一条**污染清单**上相等 sd=$old1 ⇒ rc=0、**一声不响**（这就是"两条牙必需"的理由：它与生产走同一条路，**结构上**不可能看见污染）"
    else
        fail=$((fail + 1))
        say "SELFTEST CASE D10-old-criterion-blind = FAIL 两趟不等（old1=$old1 old2=$old2）⇒ 这条演示本身不成立"
    fi

    # 纪律 63：临时件必须落在本沙箱 TMPDIR 之下
    dtmp="$( ( cd "$sb" && bash "$SELF" --manifest "$sb/clean.txt" --expect 6 --debug-tmp 2>&1 ) \
            | sed -n 's/^FT_TMP_DIR=//p' | head -1)"
    total=$((total + 1))
    case "$dtmp" in
        "$TMPBASE"/*) pass=$((pass + 1)); say "SELFTEST CASE D11-tmpdir = PASS 临时目录=$dtmp（在 TMPDIR=$TMPBASE 之下）" ;;
        *) fail=$((fail + 1)); say "SELFTEST CASE D11-tmpdir = FAIL 临时目录='$dtmp' 不在 TMPDIR=$TMPBASE 之下" ;;
    esac
    rm -rf "$dtmp" 2>/dev/null

    say "SELFTEST_SANDBOX=$sb"
    if [ "$fail" -eq 0 ]; then
        say "SELFTEST=PASS total=$total pass=$pass fail=$fail"
        rm -rf "$sb"; return 0
    fi
    say "SELFTEST=FAIL total=$total pass=$pass fail=$fail（沙箱保留供诊断）"
    return 1
}

# ── 入口 ─────────────────────────────────────────────────────────────────────
MANIFEST=''; EXPECT=''; PATHS=''
while [ "$#" -gt 0 ]; do
    case "$1" in
        --manifest)  MANIFEST="${2:-}"; shift 2 ;;
        --expect)    EXPECT="${2:-}"; shift 2 ;;
        --paths)     PATHS="${2:-}"; shift 2 ;;
        --debug-tmp) KEEP_TMP=1; shift ;;
        --selftest)  run_selftest; exit $? ;;
        -h|--help)   usage; exit 0 ;;
        *)           say "unknown-arg: $1"; usage; exit 2 ;;
    esac
done

run_check "$MANIFEST" "$EXPECT" "$PATHS"; rc=$?
if [ "$KEEP_TMP" = 1 ] && [ -n "$TMP_DIR_USED" ]; then say "FT_TMP_DIR=$TMP_DIR_USED"; fi
exit "$rc"
