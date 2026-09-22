#!/usr/bin/env bash
# ============================================================================
#  wm-awaited.sh —— "等 WM 起来"的**真判据**（`D-G89` 的落地件；车道 `W102A`，`TASK-0703`）
#
#  【判据原文】`/home/links-dev/w102a/criteria.md` §1（**先写、早于本文件与任何改动**）
#     C1 ATOM_ID        root 上 `xprop _NET_SUPPORTING_WM_CHECK` **能解析出 `window id # 0x…`**（≠ `0x0`）
#     C2 WM_WINDOW_LIVE 该 id **此刻在树里**（`xwininfo -id` 成功）**且** `_NET_WM_NAME`/`WM_CLASS` 可读非空
#     C3 EWMH_SET       root 上 `_NET_SUPPORTED` 里 **≥1** 个原子
#     C4 REPARENT       存在"框架里装着一个有 `WM_CLASS` 的客户窗"的顶层窗（**默认只报不判**）
#  【判决】`PASS` ⇔ `C1∧C2∧C3`（加 `--require-reparent` 时再 ∧ `C4>0`）；
#          X 服务器本身问不到（`xdpyinfo` 失败）⇒ **`NOINFO`**（**既不算绿也不算红**）
#  【三态 rc】`PASS=0`｜`FAIL=1`｜`NOINFO=2`
#  【失败要大声】`FAIL`/`NOINFO` 一律 **非零退出**，并**逐条打出三条件的实测读数**（含 `xprop` 原文）；
#          绝不静默继续、绝不只打一句"WM 没起来"。
#
#  ⚠️【缺陷本体 `D-G89`（**旧谓词，本文件要取代的那个**）】：
#       `xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window` **恒真** ——
#       `xprop` 的**失败文案**是 `_NET_SUPPORTING_WM_CHECK:  no such atom on any window. `，
#       里面**含 `window`** ⇒ `grep` 命中 ⇒ 等待**第一次迭代就 break** ⇒ "等 WM 起来"**等于没等**
#       （现场实例 `~/w53a/cell3.sh:26`；`--selftest` 的 `S2` 就是拿这段话做**成对反极性**）。
#  ⚠️【为什么"三个全要"而不是"三取二"】`C1` 单独可为"**死 WM 的鬼影**"：`build/MilBridge/W54A-report.md`
#       §0.4(1) 与 `~/w53a/logs/WFP3-wm-killwm/report.txt:9` 都记着 `xfwm4_alive=no` 而 root 上
#       **仍留着** `window id # 0x…` 的陈旧属性 ⇒ 只查 id 会被残留骗过，必须再要"窗口还在不在"（`C2`）
#       与"WM 一族属性成组在场"（`C3`）。
# ============================================================================
set -uo pipefail

SELF="$(readlink -f "$0")"
XPROP="${WM_XPROP_BIN:-xprop}"
XWININFO="${WM_XWININFO_BIN:-xwininfo}"
XDPYINFO="${WM_XDPYINFO_BIN:-xdpyinfo}"
PROBE_TIMEOUT="${WM_PROBE_TIMEOUT:-5}"

usage() {
    cat <<'USAGE'
wm-awaited.sh [--display :N] {--check | --wait SEC} [--interval S] [--require-reparent]
wm-awaited.sh --selftest
  判决行（末行，机读）：WM_AWAITED=PASS|FAIL|NOINFO c1=… c2=… c3=… c4=… display=… elapsed_s=… attempts=…
  逐条读数行：WM_C1_ATOM_ID … / WM_C2_WM_WINDOW … / WM_C3_EWMH_SET … / WM_C4_REPARENT …
USAGE
}

DISP=""; MODE=check; WAIT_S=0; INTERVAL=0.25; REQUIRE_REPARENT=no
while [ "$#" -gt 0 ]; do
    case "$1" in
        --display)          DISP="${2:-}"; shift 2 ;;
        --wait)             MODE=wait; WAIT_S="${2:-0}"; shift 2 ;;
        --interval)         INTERVAL="${2:-0.25}"; shift 2 ;;
        --require-reparent) REQUIRE_REPARENT=yes; shift ;;
        --check)            MODE=check; shift ;;
        --selftest)         MODE=selftest; shift ;;
        --help|-h)          usage; exit 0 ;;
        *) echo "wm-awaited.sh: 未知参数 '$1'" >&2; usage >&2; exit 64 ;;
    esac
done
[ -n "$DISP" ] || DISP="${DISPLAY:-}"

now_ms() {
    local t="${EPOCHREALTIME:-}"
    if [ -n "$t" ]; then
        printf '%s' "$(( ${t%.*} * 1000 + 10#${t#*.} / 1000 ))"
    else
        printf '%s' "$(( $(date +%s) * 1000 ))"
    fi
}
ms_to_s() { awk -v ms="$1" 'BEGIN{printf "%.2f", ms/1000}'; }

# ---- 探针：只设全局，不打屏（`--wait` 只打最后一趟，免得刷 40 行）------------
RAW_C1=""; C1_ID=""; C1_OK=no
RAW_C2X=""; RAW_C2N=""; RAW_C2C=""; C2_EXISTS=no; C2_NAME=no; C2_CLASS=no; C2_OK=no
RAW_C3=""; C3_N=0; C3_OK=no
C4_N=0; C4_OK=na
DISP_OK=no

count_reparented() {
    local tree w g hit cls n=0
    tree="$(timeout "$PROBE_TIMEOUT" "$XWININFO" -display "$DISP" -root -children 2>/dev/null \
            | awk '/^ +0x[0-9a-fA-F]+ /{print $1}')"
    for w in $tree; do
        hit=no
        for g in $(timeout "$PROBE_TIMEOUT" "$XWININFO" -display "$DISP" -id "$w" -children 2>/dev/null \
                   | awk '/^ +0x[0-9a-fA-F]+ /{print $1}'); do
            cls="$(timeout "$PROBE_TIMEOUT" "$XPROP" -display "$DISP" -id "$g" WM_CLASS 2>/dev/null)"
            case "$cls" in *'= "'*) hit=yes; break ;; esac
        done
        [ "$hit" = yes ] && n=$((n + 1))
    done
    printf '%s' "$n"
}

run_probe() {
    # ① X 服务器本身可达否（不可达 ⇒ 三条件**测不出来** ⇒ NOINFO）
    if timeout "$PROBE_TIMEOUT" "$XDPYINFO" -display "$DISP" >/dev/null 2>&1; then DISP_OK=yes; else DISP_OK=no; fi

    # ② C1：root 上 `_NET_SUPPORTING_WM_CHECK` 必须**解析出窗口 id**
    RAW_C1="$(timeout "$PROBE_TIMEOUT" "$XPROP" -display "$DISP" -root _NET_SUPPORTING_WM_CHECK 2>&1)"
    C1_ID="$(printf '%s\n' "$RAW_C1" \
             | sed -n 's/.*window id # \(0x[0-9a-fA-F]\{1,\}\).*/\1/p' | head -n1 \
             | tr 'A-F' 'a-f')"
    if [ -n "$C1_ID" ] && [ "$C1_ID" != "0x0" ]; then C1_OK=yes; else C1_OK=no; fi

    # ③ C2：该 id **此刻真的在**，且 WM 自己可读（名字或类）
    C2_EXISTS=no; C2_NAME=no; C2_CLASS=no; C2_OK=no; RAW_C2X=""; RAW_C2N=""; RAW_C2C=""
    if [ "$C1_OK" = yes ]; then
        if timeout "$PROBE_TIMEOUT" "$XWININFO" -display "$DISP" -id "$C1_ID" >/dev/null 2>&1; then
            C2_EXISTS=yes
        fi
        RAW_C2N="$(timeout "$PROBE_TIMEOUT" "$XPROP" -display "$DISP" -id "$C1_ID" _NET_WM_NAME 2>&1)"
        RAW_C2C="$(timeout "$PROBE_TIMEOUT" "$XPROP" -display "$DISP" -id "$C1_ID" WM_CLASS 2>&1)"
        printf '%s' "$RAW_C2N" | grep -Eq '= *"[^"]' && C2_NAME=yes || C2_NAME=no
        printf '%s' "$RAW_C2C" | grep -Eq '= *"[^"]' && C2_CLASS=yes || C2_CLASS=no
        if [ "$C2_EXISTS" = yes ] && { [ "$C2_NAME" = yes ] || [ "$C2_CLASS" = yes ]; }; then
            C2_OK=yes
        fi
    fi

    # ④ C3：`_NET_SUPPORTED` **非空**（≥1 项）
    #   🩸【血泪（本件现场实测抓到，`criteria.md` §1 已按"加注不覆盖"追加更正）】
    #     首版按 `0x…` 十六进制 token 计数 —— **在真 `xfwm4` 上恒为 0**：xprop 对 `ATOM` 型属性
    #     打的是**原子名**（`_NET_SUPPORTED(ATOM) = _NET_ACTIVE_WINDOW, _NET_CLIENT_LIST, …`），
    #     不是 `0x14a, 0x14b`（我在 fixture 里恰好用了十六进制形状 ⇒ **自测全绿而现场全红**）。
    #     ⇒ 现在**两种形状都认**：取首个 `= ` 之后的列表，按逗号切、数非空项。
    RAW_C3="$(timeout "$PROBE_TIMEOUT" "$XPROP" -display "$DISP" -root _NET_SUPPORTED 2>&1)"
    local flat3="${RAW_C3//$'\n'/ }"
    local val3=""
    case "$flat3" in *'= '*) val3="${flat3#*= }" ;; *) val3="" ;; esac
    if [ -n "$val3" ]; then
        C3_N="$(printf '%s' "$val3" | tr ',' '\n' | grep -c '[^[:space:]]')"
    else
        C3_N=0
    fi
    if [ "${C3_N:-0}" -ge 1 ]; then C3_OK=yes; else C3_OK=no; fi

    # ⑤ C4：被重定父的顶层客户窗（**默认只报不判**）
    C4_N=0
    if [ "$DISP_OK" = yes ]; then C4_N="$(count_reparented)"; fi
    if [ "$REQUIRE_REPARENT" = yes ]; then
        if [ "${C4_N:-0}" -ge 1 ]; then C4_OK=yes; else C4_OK=no; fi
    else
        C4_OK=na
    fi
}

verdict_of() {
    if [ "$DISP_OK" != yes ]; then V=NOINFO; return; fi
    if [ "$C1_OK" = yes ] && [ "$C2_OK" = yes ] && [ "$C3_OK" = yes ]; then
        if [ "$REQUIRE_REPARENT" = yes ] && [ "$C4_OK" != yes ]; then V=FAIL; return; fi
        V=PASS
    else
        V=FAIL
    fi
}

rc_of() { case "$1" in PASS) printf '0' ;; FAIL) printf '1' ;; *) printf '2' ;; esac; }

flatten() { printf '%s' "$1" | tr '\n' '|'; }   # 读数原文压成一行（**不手抄**，原样带出）

emit_readings() {
    printf 'WM_C1_ATOM_ID ok=%s id=%s raw=%s\n' "$C1_OK" "${C1_ID:-<absent>}" "'$(flatten "$RAW_C1")'"
    printf 'WM_C2_WM_WINDOW ok=%s exists=%s name_ok=%s class_ok=%s id=%s name_raw=%s class_raw=%s\n' \
        "$C2_OK" "$C2_EXISTS" "$C2_NAME" "$C2_CLASS" "${C1_ID:-<absent>}" \
        "'$(flatten "$RAW_C2N")'" "'$(flatten "$RAW_C2C")'"
    printf 'WM_C3_EWMH_SET ok=%s n=%s raw=%s\n' "$C3_OK" "$C3_N" "'$(flatten "$RAW_C3")'"
    printf 'WM_C4_REPARENT n=%s required=%s ok=%s\n' "$C4_N" "$REQUIRE_REPARENT" "$C4_OK"
}

emit_verdict() {  # $1=elapsed_ms $2=attempts
    printf 'WM_AWAITED=%s c1=%s c2=%s c3=%s c4=%s display=%s elapsed_s=%s attempts=%s\n' \
        "$V" "$C1_OK" "$C2_OK" "$C3_OK" "$( [ "$REQUIRE_REPARENT" = yes ] && printf '%s' "$C4_OK" || printf '%s' "$C4_N" )" \
        "${DISP:-<unset>}" "$(ms_to_s "$1")" "$2"
    if [ "$V" != PASS ]; then
        printf 'WM_AWAITED_WHY verdict=%s（判据原文 ~/w102a/criteria.md §1）: C1=%s C2=%s C3=%s C4(required=%s)=%s\n' \
            "$V" "$C1_OK" "$C2_OK" "$C3_OK" "$REQUIRE_REPARENT" "$C4_OK"
    fi
}

# ---- `--selftest`：合成 fixture（**不碰真 X**），逐例**同时断言值 ＋ rc** -----------
STUB=""
mkstubs() {
    STUB="$(mktemp -d "${TMPDIR:-/tmp}/wm-awaited-selftest.XXXXXX")"
    cat > "$STUB/xdpyinfo" <<'EOS'
#!/usr/bin/env bash
[ "${SCN_DISPLAY_OK:-yes}" = yes ] || exit 1
echo "name of display: ${SCN_DIR:-}"; exit 0
EOS
    cat > "$STUB/xwininfo" <<'EOS'
#!/usr/bin/env bash
target=""; children=no
while [ "$#" -gt 0 ]; do
    case "$1" in
        -display) shift 2 ;;
        -root)    target=root; shift ;;
        -id)      target="$2"; shift 2 ;;
        -children) children=yes; shift ;;
        *) shift ;;
    esac
done
[ "${SCN_DISPLAY_OK:-yes}" = yes ] || { echo "xwininfo: unable to open display" >&2; exit 1; }
if [ "$target" = root ]; then
    if [ -f "$SCN_DIR/root.children" ]; then cat "$SCN_DIR/root.children"; else echo "0 children."; fi
    exit 0
fi
if [ -f "$SCN_DIR/$target.exists" ]; then
    if [ "$children" = yes ]; then
        if [ -f "$SCN_DIR/$target.children" ]; then cat "$SCN_DIR/$target.children"; else echo "0 children."; fi
    else
        cat "$SCN_DIR/$target.exists"
    fi
    exit 0
fi
echo "xwininfo: error: no window with id $target" >&2; exit 1
EOS
    cat > "$STUB/xprop" <<'EOS'
#!/usr/bin/env bash
target=""; atom=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        -display) shift 2 ;;
        -root)    target=root; shift ;;
        -id)      target="$2"; shift 2 ;;
        *)        atom="$1"; shift ;;
    esac
done
if [ "$target" = root ]; then
    if [ -f "$SCN_DIR/root.$atom" ]; then cat "$SCN_DIR/root.$atom"; exit 0; fi
    printf '%s:  no such atom on any window. \n' "$atom"; exit 1
fi
if [ ! -f "$SCN_DIR/$target.exists" ]; then
    echo "xprop: error: window id $target is not valid" >&2; exit 1
fi
if [ -f "$SCN_DIR/$target.$atom" ]; then cat "$SCN_DIR/$target.$atom"; exit 0; fi
printf '%s:  not found.\n' "$atom"; exit 0
EOS
    chmod +x "$STUB/xdpyinfo" "$STUB/xwininfo" "$STUB/xprop"
}
rmstubs() { [ -n "$STUB" ] && rm -rf "$STUB"; }

# 造一个"有 WM"的完整 fixture 树（供 S1/S5 复用；$1=是否有重定父客户窗）
mk_wm_fixture() {
    local reparent="$1"
    SCN_DISPLAY_OK=yes
    printf '_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x4000ae \n' > "$SCN_DIR/root._NET_SUPPORTING_WM_CHECK"
    #   ⚠️ 这里用**十六进制**形状（`0x14a, …`）—— 只为证明"两种形状都认"；
    #      真 `xfwm4` 打的是**原子名**形状，由 `S9` 覆盖（🩸首版只认十六进制 ⇒ 现场 C3 恒假）。
    printf '_NET_SUPPORTED(ATOM) = 0x14a, 0x14b, 0x14c\n'                  > "$SCN_DIR/root._NET_SUPPORTED"
    printf 'xwininfo: Window id: 0x4000ae "Xfwm4"\n'                      > "$SCN_DIR/0x4000ae.exists"
    printf '_NET_WM_NAME(UTF8_STRING) = "Xfwm4"\n'                        > "$SCN_DIR/0x4000ae._NET_WM_NAME"
    if [ "$reparent" = yes ]; then
        printf '     0x400264 (has no name): ()  810x634+240+212  +240+212\n' > "$SCN_DIR/root.children"
        printf 'xwininfo: Window id: 0x400264 (has no name)\n' > "$SCN_DIR/0x400264.exists"   # ⚠️ 少了这一行 ⇒ stub 先判"窗在不在"，`-children` 那一问直接失败 ⇒ C4 假（本件自测当场抓到）
        printf '        0x200004 "HandyControlDemo": ()  800x600+5+29  +245+241\n' > "$SCN_DIR/0x400264.children"
        printf 'xwininfo: Window id: 0x200004 "HandyControlDemo"\n' > "$SCN_DIR/0x200004.exists"
        printf 'WM_CLASS(STRING) = "HandyControlDemo", "HandyControlDemo"\n' > "$SCN_DIR/0x200004.WM_CLASS"
    else
        printf '     0x200004 "HandyControlDemo": ()  800x600+5+29  +245+241\n' > "$SCN_DIR/root.children"
        printf 'xwininfo: Window id: 0x200004 "HandyControlDemo"\n' > "$SCN_DIR/0x200004.exists"
        printf 'WM_CLASS(STRING) = "HandyControlDemo", "HandyControlDemo"\n' > "$SCN_DIR/0x200004.WM_CLASS"
    fi
}

selftest() {
    mkstubs
    trap rmstubs EXIT
    export SCN_DISPLAY_OK="${SCN_DISPLAY_OK:-yes}"   # 子进程（stub）要看得见
    local cases=0 pass=0 not_as_expected=0 rc val wmrep=0 guard_fired=0
    local T="$(mktemp -d "${TMPDIR:-/tmp}/wm-awaited-scn.XXXXXX")"
    local SEL=""        # 当前 fixture 目录名（**与用例标签分开** —— 见下面的血泪注）

    newscn() { SEL="$1"; SCN_DIR="$T/$SEL"; mkdir -p "$SCN_DIR"; }   # $1=fixture id

    run_case() {  # $1=用例标签 $2=期望裁决 $3=期望rc $4…=额外参数
        local label="$1" exp_val_="$2" exp_rc_="$3"; shift 3
        cases=$((cases + 1))
        # 🩸【血泪（本件自测当场抓到）】首版这里写的是 `SCN_DIR="$T/$1"`（**用用例标签当目录名**）
        #   ⇒ fixture 被写在 `$T/S1`、而孩子读的是 `$T/S1-all-true-with-reparent`（**空目录**）
        #   ⇒ 除"正极性"那一例外**其它例全部退化成"什么都读不到 ⇒ FAIL"**，
        #   而它们的期望又恰好是 FAIL ⇒ **七例"通过"里有六例是空转**。
        #   修法：fixture id 与标签**分开**；并加下面这条**反空转断言**。
        if [ -z "$SEL" ] || [ ! -d "$T/$SEL" ] || [ -z "$(ls -A "$T/$SEL" 2>/dev/null)" ]; then
            guard_fired=$((guard_fired + 1))
            not_as_expected=$((not_as_expected + 1))
            printf 'CASE %-42s value=FIXTURE-MISSING  expect=%s/%s  **守卫开火（本用例期望如此：空 fixture 必须被拦）dir=%s**\n' \
                "$label" "$exp_val_" "$exp_rc_" "$T/$SEL"
            return
        fi
        local out
        out="$(SCN_DIR="$T/$SEL" WM_XPROP_BIN="$STUB/xprop" WM_XWININFO_BIN="$STUB/xwininfo" \
               WM_XDPYINFO_BIN="$STUB/xdpyinfo" bash "$SELF" --display :0 "$@" 2>&1)"; rc=$?
        val="$(printf '%s\n' "$out" | sed -n 's/^WM_AWAITED=\([A-Z]*\).*/\1/p' | head -n1)"
        if [ "$val" = "$exp_val_" ] && [ "$rc" = "$exp_rc_" ]; then
            pass=$((pass + 1))
            printf 'CASE %-42s value=%-7s rc=%s  expect=%s/%s  AS-EXPECTED (fixture=%s)\n' \
                "$label" "$val" "$rc" "$exp_val_" "$exp_rc_" "$SEL"
        else
            not_as_expected=$((not_as_expected + 1))
            printf 'CASE %-42s value=%-7s rc=%s  expect=%s/%s  **NOT-AS-EXPECTED**\n' "$label" "$val" "$rc" "$exp_val_" "$exp_rc_"
            printf '%s\n' "$out" | sed 's/^/    | /'
        fi
    }

    # S1 全真 ＋ 有重定父 ⇒ PASS/0（**正极性：它是"fixture 真的接上了"的唯一证据**）
    newscn S1; mk_wm_fixture yes
    run_case S1-all-true-with-reparent PASS 0 --check --require-reparent

    # S1b 同一 fixture 走普通口径（不要求重定父）⇒ 也必须 PASS/0（`C4` 默认只报不判）
    run_case S1b-same-fixture-no-reparent-required PASS 0 --check

    # S2 **反极性核心**：无 WM，且**故意用 `xprop` 的失败文案**（缺陷本体的触发条件）
    newscn S2
    printf '_NET_SUPPORTING_WM_CHECK:  no such atom on any window. \n' > "$SCN_DIR/root._NET_SUPPORTING_WM_CHECK"
    SCN_DISPLAY_OK=yes
    run_case S2-no-wm-failure-text FAIL 1 --check
    # 同一份输入喂**旧谓词**：必须「恒真」（rc=0）—— 这正是 `D-G89` 的机证
    local old_rc=0
    SCN_DIR="$T/S2" WM_XPROP_BIN="$STUB/xprop" SCN_DISPLAY_OK=yes \
        bash -c '"$WM_XPROP_BIN" -display :0 -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window'
    old_rc=$?
    cases=$((cases + 1)); wmrep=$((wmrep + 1))
    if [ "$old_rc" = 0 ]; then
        pass=$((pass + 1))
        printf 'CASE %-42s value=OLD-PREDICATE-TRUE rc=0  expect=true/0  AS-EXPECTED（缺陷在本 fixture 上复现）\n' S2-old-predicate-on-same-input
    else
        not_as_expected=$((not_as_expected + 1))
        printf 'CASE %-42s value=OLD-PREDICATE rc=%s  expect=true/0  **NOT-AS-EXPECTED**\n' S2-old-predicate-on-same-input "$old_rc"
    fi

    # S3 陈旧 id：C1 解析出 id，但那个窗**已经不在了**（`C2` 必须拦下）
    newscn S3
    printf '_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x2000ae \n' > "$SCN_DIR/root._NET_SUPPORTING_WM_CHECK"   # 故意不写 .exists
    printf '_NET_SUPPORTED(ATOM) = 0x14a, 0x14b\n' > "$SCN_DIR/root._NET_SUPPORTED"
    SCN_DISPLAY_OK=yes
    run_case S3-stale-wm-id-window-gone FAIL 1 --check

    # S4 C1/C2 真、`_NET_SUPPORTED` 缺席 ⇒ FAIL
    newscn S4; mk_wm_fixture no
    rm -f "$SCN_DIR/root._NET_SUPPORTED"
    run_case S4-supported-missing FAIL 1 --check

    # S5 C1…C3 真，但要求重定父而**没有**客户窗在框架里 ⇒ FAIL
    newscn S5; mk_wm_fixture no
    run_case S5-require-reparent-but-none FAIL 1 --check --require-reparent

    # S6 X 服务器问不到 ⇒ NOINFO/2（**既不算绿也不算红**）
    newscn S6; mk_wm_fixture yes; SCN_DISPLAY_OK=no
    run_case S6-display-unreachable NOINFO 2 --check
    SCN_DISPLAY_OK=yes

    # S7 解析出的是 `0x0` ⇒ C1 假 ⇒ FAIL（"有 window id #"但指向 None）
    newscn S7
    printf '_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x0 \n' > "$SCN_DIR/root._NET_SUPPORTING_WM_CHECK"
    printf '_NET_SUPPORTED(ATOM) = 0x14a\n' > "$SCN_DIR/root._NET_SUPPORTED"
    SCN_DISPLAY_OK=yes
    run_case S7-zero-id FAIL 1 --check

    # S9 **原子名形状**的 `_NET_SUPPORTED`（真 `xfwm4` 就是这种）⇒ 必须 PASS/0
    #   （🩸这条是补的：首版只认 `0x…` ⇒ 真机上 C3 恒假、而 fixture 全绿 ⇒ **自测骗了我一次**）
    newscn S9; mk_wm_fixture no
    printf '_NET_SUPPORTED(ATOM) = _NET_ACTIVE_WINDOW, _NET_CLIENT_LIST, _NET_SUPPORTED, _NET_WM_NAME\n' \
        > "$SCN_DIR/root._NET_SUPPORTED"
    run_case S9-supported-as-atom-names PASS 0 --check

    # S8 未接 fixture（**故意空目录**）⇒ 反空转守卫**必须开火**（本用例的"通过"＝守卫拦住它）
    guard_fired=0
    local na_before="$not_as_expected"
    SEL="S8-empty-fixture"; SCN_DIR="$T/$SEL"; mkdir -p "$SCN_DIR"
    run_case S8-anti-vacuity-guard PASS 0 --check     # 故意给一个**达不到**的期望：守卫若不开火，这一例就是红
    not_as_expected="$na_before"                       # 撤销守卫那一记（开火＝本用例的期望行为）
    if [ "$guard_fired" -ge 1 ]; then
        pass=$((pass + 1))
        printf 'CASE %-42s value=GUARD-FIRED rc=-  expect=guard-fired  AS-EXPECTED（空 fixture 被拦住 ⇒ 上表没有空转例）\n' S8-anti-vacuity-guard
    else
        not_as_expected=$((not_as_expected + 1))
        printf 'CASE %-42s value=GUARD-SILENT  expect=guard-fired  **NOT-AS-EXPECTED**（空 fixture 竟然放行 ⇒ 守卫坏了）\n' S8-anti-vacuity-guard
    fi

    rm -rf "$T"
    printf 'WM_AWAITED_SELFTEST=%s cases=%s pass=%s not-as-expected=%s（其中"旧谓词恒真"复现例 %s 个）\n' \
        "$( [ "$not_as_expected" = 0 ] && printf PASS || printf FAIL )" "$cases" "$pass" "$not_as_expected" "$wmrep"
    [ "$not_as_expected" = 0 ] && return 0 || return 1
}

if [ "$MODE" = selftest ]; then selftest; exit $?; fi

START_MS="$(now_ms)"; ATTEMPTS=0
while :; do
    ATTEMPTS=$((ATTEMPTS + 1))
    run_probe
    verdict_of
    NOW_MS="$(now_ms)"; ELAPSED_MS=$((NOW_MS - START_MS))
    if [ "$V" = PASS ]; then break; fi
    if [ "$MODE" = check ]; then break; fi
    [ "$ELAPSED_MS" -ge "$(( ${WAIT_S%.*} * 1000 ))" ] && break
    sleep "$INTERVAL"
done
emit_readings
emit_verdict "$ELAPSED_MS" "$ATTEMPTS"
exit "$(rc_of "$V")"
