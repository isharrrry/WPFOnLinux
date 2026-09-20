#!/usr/bin/env bash
# ============================================================================
# product-entry-step.sh —— **走产品入口**的 `M_modifier` 臂的冻树牙齿（`D-G38` ＋ `D-T2-c` 的回归网）
#
# 【为什么需要它（`#31` 的欠账 ＋ `#32` 的判据）】
#   `#30` 立了**纪律 67**：「"零产品位移"可能是"**没有一支臂走产品入口**"的副产品」。
#   `#31` W31A 把这个结构性缺口做成了**可复算的读数**：新建
#     `build/MilBridge/tests/ProductEntryArm/`（`TextFormatter.Create()` ＋ `FormatLine`，真走产品入口）
#     ⇒ 5 个 `M_modifier` 例 **18 条逐行红**（`w`/`witw` 我方恒 `45.968000`、真值 `74.573333`／
#     `115.690000`／`156.916667`；`w80`/`w120` 还**少一整行**），3 个阴性对照 **98/98 全绿**。
#   根因 = `CollectLenient` 只记 modifier **起点**、**终点没接线**（`D-T2-c`）
#     ⇒ shim 吃默认 `modifierScopeEnd = -1` ⇒ 零宽跨度被放大到 `[6,62)`（真机 `[6,45)`）。
#   `#32` W32A 把根因修好之后，这支臂**变成一支普通的绿臂** ⇒ 本步就是它进 `verify-all` 的入口。
#
# 【本步判什么 —— 一句话】用现成臂 `build/MilBridge/tests/ProductEntryArm/`：**先构建**、
#   **再断言产物目录里的 `pc` 副本 == 权威 `pc`**，然后跑一次（产品默认档），把 `PEA_SUM` 的
#   `red`/`noinfo`、**逐例正控 `PEA_POSCTL`**、以及**两条下界（例数、判据格数）**一起判。
#   自报 ASCII 键：`PRODUCT_ENTRY_STEP=PASS|FAIL|NOINFO`（`verify-all` 的绿分支会把它捞上屏）。
#
# 【三态：rc=0 通过 ｜ rc=1 **判据红** ｜ rc=2 `NOINFO`（**算不出 ⇒ 不是通过**）】
#   `NOINFO` 的档（逐条，**都不许读成绿**）：缺件／**构建失败**／**产物副本 != 权威 `pc`**
#   （`D-A2` 那一族：量到的会是旧产物）／**本步期间被测 `pc` 变了**（纪律 35）／**正控不过**
#   （没走到被测代码）／**下界不满足**（例数或判据格数缩水 = **恒绿风险**，纪律 47 同族）／
#   臂自报 `noinfo>0`。判 `FAIL`：`PEA_SUM … red>0` ⇒ **逐例点名**。
#
# 【"预期红"有没有？】**今天没有**。⚠️ 这一条是**刻意写下来的**：`#31` 的读数里那 5 个 `M_modifier`
#   例是红的，而 `#32` 修好根因之后它们**必须转绿**。若将来发现本步在**现役树**上红，正确动作是
#   **去查产品侧那条链路**，**不是**在这里登记"预期红"、更不是放宽下界（**假红侵蚀对红数的信任**）。
#
# 【射程（不许读过头）】证的是「**走产品入口那条路径**上 8 个例的逐行读数与真值一致」；
#   **不证**「modifier 的语义在所有语料上都对」（语料只有 b34 家族的 8 例）。五臂喂的是**语料 meta**、
#   **绕过 PC** ⇒ 本步与它们**互补**，不是替代。
#
# 【成本（实测）】构建 ≈1.6 s（首跑含 restore ≈6 s）＋ 跑 ≈13 s ⇒ **≈15 s/趟**。
#   内存纪律：所有 `dotnet` 命令 `-m:1` ＋ `DOTNET_gcServer=0`。
#
# 【测试钩子（**只服务 `--selftest`，生产路径用不到**）】`PRODUCT_ENTRY_BUILD`／`PRODUCT_ENTRY_RUNNER`
#   （把 `dotnet` 换成替身）／`PRODUCT_ENTRY_SKIP_BUILD`／`PRODUCT_ENTRY_COPY_SHA`。
#   ⚠️ **`PRODUCT_ENTRY_COPY_SHA` 只在 `PRODUCT_ENTRY_SKIP_BUILD=1` 时被接受**（下面有断言）
#   ⇒ **生产路径不可能用它把"副本 != 权威"洗掉**。
# ============================================================================
set -uo pipefail

ROOT="${PRODUCT_ENTRY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# ★ `#39` 阶段 2/3：读**权威件**的路径必须跟随**唯一声明**（`build/SelfBuiltConfig.props`）。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../../build/selfbuilt-config.sh"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
cd "$ROOT" || exit 2
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_gcServer=0

PROBE_DIR="$ROOT/build/MilBridge/tests/ProductEntryArm"
PROJ="$PROBE_DIR/ProductEntryArm.csproj"
CFG="${PRODUCT_ENTRY_CFG:-Debug}"
DLL="${PRODUCT_ENTRY_DLL:-$PROBE_DIR/bin/$CFG/PresentationCore.Tests.dll}"
AUTH_PC="${PRODUCT_ENTRY_AUTH_PC:-$ROOT/build/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll}"
LOGDIR="${PRODUCT_ENTRY_LOGDIR:-/tmp/product-entry-step}"
BUILD="${PRODUCT_ENTRY_BUILD:-dotnet}"
RUNNER="${PRODUCT_ENTRY_RUNNER:-dotnet}"
SKIP_BUILD="${PRODUCT_ENTRY_SKIP_BUILD:-0}"
POLARITY=0
[ -n "${PRODUCT_ENTRY_RUNNER:-}" ] && POLARITY=1
[ -n "${PRODUCT_ENTRY_DLL:-}" ] && POLARITY=1
[ -n "${PRODUCT_ENTRY_AUTH_PC:-}" ] && POLARITY=1
[ -n "${PRODUCT_ENTRY_SKIP_BUILD:-}" ] && POLARITY=1

# ── 下界声明（**唯一声明处**；改它们必须同趟说明"为什么这个数变了"）──────────────────
EXPECT_CASES=8                      # 臂里的例数（5 个 M_modifier ＋ 3 个 F_lat_words 阴性对照）
EXPECT_CELLS=147                    # `PEA_SUM lines_judged`：8 例 × 各自行数 × 7 列。
#   ⏪ **`#32` 起由 `133` 重钉为 `147`**：`#32` W32A 修好 `D-T2-c`（modifier 覆盖终点）后，
#     `M_modifier_w80`/`_w120` 各**补回一行**（真值本来就是 2 行）⇒ 判据格 133 → 147（+14 = 2 行 × 7 列）。
#     ⚠️ 这个数是**实测值**、`!=` 判（涨也出声）：语料或判据面一变就必须**同趟**重钉并说明为什么。
EXPECT_MCASES=5                     # 其中带 modifier 的例数（正控必须**逐例**证明走到了宽松档）
POSCTL_LENIENT='REACHED(lenient)'   # 5 个 M 例必须走**宽松档**（严格档在 TextModifier 上必 bail）
POSCTL_STRICT='REACHED(strict)'     # 3 个阴性对照必须走**严格档**

sha16() { [ -f "$1" ] && sha256sum "$1" | cut -c1-16 || printf 'MISSING'; }

# ═══════════════════════════════════════════════════════════════════════════════════════
#  --selftest：反极性（**自生成替身**；**零 dotnet**）
# ═══════════════════════════════════════════════════════════════════════════════════════
#  纪律 68（`--selftest` 的用例会悄悄失去前提）的落点：**每一条判据**都有例，且夹具只依赖
#  **自己注入的东西**（替身 runner/build ＋ `mktemp -d` 的临时目录）—— 不读冻结基线、
#  不读登记表、不读世代号 ⇒ 前提**自持**（重冻/换代不会把它打掉）。
if [ "${1:-}" = '--selftest' ]; then
    # ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、不许冒充红）──
    #   本件自测以 `bash "$SELF"` **重入自己**（`chk()` 里）⇒ bash 每次为新子进程从磁盘**重读**本件 ⇒
    #   父进程按旧版造夹具（替身 runner/build ＋ `mktemp -d`）、子进程按新版判定 ⇒ **改件窗口里出的红是凭空的红**。
    #   口径：**开头记 sha16、结尾再算一次**；不等 ⇒ `ST_ATTEST=NOINFO` 并点名（含 sha0/sha1 与内层 rc），
    #   统一 **rc=2**（`NOINFO` 码，不与 `FAIL` 混）。只加在 `--selftest` 路径；**生产路径一字未动**；
    #   不删例、不放宽任何下界（成对读数见 `$HOME/w33b-report.md`）。
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
            exit 2
        fi
        printf 'ST_ATTEST=PASS self=%s sha16=%s（自测期间本件未变 ⇒ 读数可归因）\n' "$ST_SELF" "$ST0"
        exit "$ST_RC"
    fi
    T="$(mktemp -d "${TMPDIR:-/tmp}/product-entry-selftest.XXXXXX")"; trap 'rm -rf "$T"' EXIT
    STUB="$T/stub.sh"
    cat > "$STUB" <<'STUBEOF'
#!/usr/bin/env bash
set -u
emit() {
  echo "PEA_ENTRY=TextFormatter.Create() + FormatLine  (public)"
  echo "PEA_TIER  product_switch_HbTextFallback.Enabled=true effective=strict"
  for c in M_modifier_w80 M_modifier_w120 M_modifier_w200 M_modifier_w320 M_modifier_winf; do
    echo "PEA_CASE case=$c text_len=62 maxWidth=200.000000 mod=[6,45) truthLines=1 ourLines=1"; done
  for c in F_lat_words_winf F_lat_words_w200 F_lat_words_w80; do
    echo "PEA_CASE case=$c text_len=62 maxWidth=200.000000 mod=[0,0) truthLines=1 ourLines=1"; done
  for c in M_modifier_w80 M_modifier_w120 M_modifier_w200 M_modifier_w320 M_modifier_winf; do
    echo "PEA_POSCTL case=$c lenient_calls+1 lenient_handled+1 strict_handled+0 strict_bailed+1 verdict=REACHED(lenient)"; done
  for c in F_lat_words_winf F_lat_words_w200 F_lat_words_w80; do
    echo "PEA_POSCTL case=$c lenient_calls+0 lenient_handled+0 strict_handled+1 strict_bailed+0 verdict=REACHED(strict)"; done
  # ⚠️ **不许写死**：下界常量由父进程导出（`STUB_CASES`/`STUB_CELLS`）⇒ 重钉 `EXPECT_*` 时
  #   自测前提**自动跟着走**（纪律 68：用例不许"悄悄失去前提"）。
  echo "PEA_SUM cases=${STUB_CASES:-8} lines_judged=${STUB_CELLS:-133} ok=${STUB_CELLS:-133} red=0 noinfo=0"
}
case "${STUB_MODE:-good}" in
  good)       emit; exit 0 ;;
  red)        emit | sed "s/^PEA_SUM .*/PEA_SUM cases=$STUB_CASES lines_judged=$STUB_CELLS ok=$((STUB_CELLS-1)) red=1 noinfo=0/"
              echo "PEA_LINE case=M_modifier_w200 k=0 field=w ours=45.968000 truth=156.916667 delta=-110.948667 verdict=RED"
              exit 1 ;;
  fewcases)   emit | sed "s/cases=$STUB_CASES /cases=$((STUB_CASES-1)) /"; exit 0 ;;
  shortcells) emit | sed "s/lines_judged=$STUB_CELLS ok=$STUB_CELLS/lines_judged=$((STUB_CELLS-33)) ok=$((STUB_CELLS-33))/"; exit 0 ;;
  noposctl)   emit | grep -v '^PEA_POSCTL '; exit 0 ;;
  wrongpos)   emit | sed 's/verdict=REACHED(lenient)/verdict=REACHED(strict)/'; exit 0 ;;
  noinfo)     emit | sed "s/ok=$STUB_CELLS red=0 noinfo=0/ok=$((STUB_CELLS-33)) red=0 noinfo=33/"; exit 2 ;;
  boom)       echo "装置炸了" >&2; exit 7 ;;
esac
STUBEOF
    chmod +x "$STUB"
    TRUE_BIN="$(command -v true)"
    # 把**下界常量**导出给替身（替身**不许**自己写死这些数）—— 见上面那段注释。
    export STUB_CASES="$EXPECT_CASES" STUB_CELLS="$EXPECT_CELLS"
    np=0; nf=0
    chk() {  # chk <编号> <期望rc> <说明> [额外 env...]
        local num="$1" want="$2" desc="$3"; shift 3
        local out rc
        out="$( env PRODUCT_ENTRY_ROOT="$ROOT" PRODUCT_ENTRY_LOGDIR="$T/log-$num" \
                    PRODUCT_ENTRY_BUILD="$TRUE_BIN" PRODUCT_ENTRY_SKIP_BUILD=1 \
                    PRODUCT_ENTRY_AUTH_PC="$AUTH_PC" PRODUCT_ENTRY_DLL="$DLL" \
                    "$@" bash "$SELF" 2>&1 )"; rc=$?
        if [ "$rc" = "$want" ]; then np=$((np+1)); printf '  %-4s PASS  %s（rc=%s）\n' "$num" "$desc" "$rc"
        else nf=$((nf+1)); printf '  %-4s FAIL  %s（期望 rc=%s，实得 rc=%s）\n' "$num" "$desc" "$want" "$rc"
             printf '%s\n' "$out" | sed 's/^/        | /' | head -8; fi
    }
    echo "== ProductEntryArm 步的 --selftest（**零 dotnet**：替身 runner 重入本件；前提自持）=="
    chk S1  0 "正极性：8 例 / 133 格 / 8 条正控全 REACHED ⇒ 必须 rc=0（PASS）"            PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=good
    chk S2  1 "反极性：『PEA_SUM red=1』 ⇒ 必须 rc=1（FAIL）并点名该例该字段"                PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=red
    chk S3  2 "下界：例数 8→7 ⇒ 必须 rc=2（NOINFO，**不是绿也不是红**）"                   PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=fewcases
    chk S4  2 "下界：判据格 133→100 ⇒ 必须 rc=2（防'一格都没判过'的恒绿）"                 PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=shortcells
    chk S5  2 "正控缺失：一条 『PEA_POSCTL』 都没有 ⇒ 必须 rc=2（没走到被测代码）"           PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=noposctl
    chk S6  2 "正控走错档：M 例吐 『REACHED(strict)』 ⇒ 必须 rc=2"                            PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=wrongpos
    chk S7  2 "臂自报 noinfo=33 ⇒ 必须 rc=2（算不出 ⇒ 不是通过）"                          PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=noinfo
    chk S8  2 "装置异常（rc=7、无 PEA_SUM）⇒ 必须 rc=2（读数不可归因）"                     PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=boom
    chk S9  2 "权威 pc 缺件 ⇒ 必须 rc=2"                                                    PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=good PRODUCT_ENTRY_AUTH_PC="$T/nope.dll"
    chk S10 2 "臂产物缺件 ⇒ 必须 rc=2"                                                      PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=good PRODUCT_ENTRY_DLL="$T/nope.dll"
    chk S11 2 "**产物副本 != 权威**（钩子强制一个假副本 sha）⇒ 必须 rc=2（D-A2 那一族）"    PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=good PRODUCT_ENTRY_COPY_SHA=deadbeefdeadbeef
    chk S12 0 "副本 == 权威（钩子给真值）⇒ 放行（证明 S11 的红来自那条闸，不是来自替身）"   PRODUCT_ENTRY_RUNNER="$STUB" STUB_MODE=good PRODUCT_ENTRY_COPY_SHA="$(sha16 "$AUTH_PC")"
    echo "PRODUCT_ENTRY_SELFTEST=$([ "$nf" -eq 0 ] && echo PASS || echo FAIL) cases=$((np+nf)) pass=$np fail=$nf"
    [ "$nf" -eq 0 ] && exit 0 || exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════════════
#  正常模式（`#32` 接线后 = `verify-all.sh` 的第 `[16]` 步）
# ═══════════════════════════════════════════════════════════════════════════════════════
# ⚠️ `PRODUCT_ENTRY_COPY_SHA` 是**测试钩子**：只在 `SKIP_BUILD=1` 时被接受 ⇒ 生产路径**用不了它**。
if [ -n "${PRODUCT_ENTRY_COPY_SHA:-}" ] && [ "$SKIP_BUILD" != 1 ]; then
    echo "PRODUCT_ENTRY_STEP=NOINFO 测试钩子 PRODUCT_ENTRY_COPY_SHA 只许在 PRODUCT_ENTRY_SKIP_BUILD=1 时使用"; exit 2
fi

for f in "$PROJ" "$AUTH_PC"; do
    [ -f "$f" ] || { echo "PRODUCT_ENTRY_STEP=NOINFO 缺文件：$f"; exit 2; }
done
mkdir -p "$LOGDIR" || { echo "PRODUCT_ENTRY_STEP=NOINFO 建不了日志目录：$LOGDIR"; exit 2; }
PC_AT_START="$(sha16 "$AUTH_PC")"
echo "PRODUCT_ENTRY_STEP 仪器 臂 csproj = $(sha16 "$PROJ")｜权威 pc = $PC_AT_START"
echo "PRODUCT_ENTRY_STEP 仪器 日志目录 = $LOGDIR｜极性模式=$([ "$POLARITY" = 1 ] && echo 是 || echo 否)"

# ── 断言①：构建（**必须构建**：`[1]`/`[2]` 可能刚重编过权威 `pc`，而臂产物目录里那份 `pc` 是
#   `HintPath+Private=true` 的**内嵌副本** ⇒ 不重编就会**量到旧产物**（`D-A2` 那一族））──────
if [ "$SKIP_BUILD" != 1 ]; then
    "$BUILD" build "$PROJ" -m:1 --nologo -v q > "$LOGDIR/build.log" 2>&1 \
        || { echo "PRODUCT_ENTRY_STEP=NOINFO 构建失败 ⇒ 算不出，不是绿（见 $LOGDIR/build.log）"; exit 2; }
fi

# ── 断言②：产物副本 == 权威（可被 `PRODUCT_ENTRY_COPY_SHA` 钩子替换，**只在 SKIP_BUILD=1 时**）──
S_AUTH="$(sha16 "$AUTH_PC")"
S_COPY="${PRODUCT_ENTRY_COPY_SHA:-}"
if [ -z "$S_COPY" ] && [ -f "$PROBE_DIR/bin/$CFG/PresentationCore.dll" ]; then
    S_COPY="$(sha16 "$PROBE_DIR/bin/$CFG/PresentationCore.dll")"
fi
if [ -n "$S_COPY" ]; then
    if [ "$S_COPY" != "$S_AUTH" ] && [ "$SKIP_BUILD" != 1 ]; then
        echo "PRODUCT_ENTRY_STEP 产物副本（$S_COPY）!= 权威（$S_AUTH）⇒ 强制 -t:Rebuild 重试一次"
        "$BUILD" build "$PROJ" -m:1 --nologo -v q -t:Rebuild > "$LOGDIR/build-rebuild.log" 2>&1 \
            || { echo "PRODUCT_ENTRY_STEP=NOINFO 强制重建失败 ⇒ 算不出（见 $LOGDIR/build-rebuild.log）"; exit 2; }
        S_COPY="$(sha16 "$PROBE_DIR/bin/$CFG/PresentationCore.dll")"
    fi
    if [ "$S_COPY" != "$S_AUTH" ]; then
        echo "PRODUCT_ENTRY_STEP=NOINFO 产物目录里的 pc 副本与权威件不符：copy=$S_COPY auth=$S_AUTH"
        echo "PRODUCT_ENTRY_STEP   ⇒ 量到的会是一份**旧产物**（D-A2 那一族）⇒ 算不出，不是绿"
        exit 2
    fi
    echo "PRODUCT_ENTRY_STEP 被测 pc（副本） = $S_COPY（copy == auth ✓）"
else
    echo "PRODUCT_ENTRY_STEP ⚠️ 产物目录里没有 pc 副本可核（$PROBE_DIR/bin/$CFG/）—— 跳过该闸，如实记"
fi

[ -f "$DLL" ] || { echo "PRODUCT_ENTRY_STEP=NOINFO 臂产物不在：$DLL"; exit 2; }

OUT="$LOGDIR/run.out"
( cd "$PROBE_DIR" && ulimit -c 0 && timeout 300 "$RUNNER" "$DLL" --no-mod-variant ) > "$OUT" 2>&1
RC=$?
echo "PRODUCT_ENTRY_STEP 跑完：rc=$RC（臂自身 rc**不是**判据；判据是下面的 PEA_SUM ＋ 正控 ＋ 两条下界）｜输出=$OUT"

SUM="$(grep -a '^PEA_SUM ' "$OUT" | tail -1 || true)"
if [ -z "$SUM" ]; then
    echo "PRODUCT_ENTRY_STEP=NOINFO 拿不到 PEA_SUM 汇总行（rc=$RC ⇒ 装置异常/算不出 ⇒ **不是绿**）"
    tail -6 "$OUT" | sed 's/^/    | /'
    exit 2
fi
n_cases="$(sed -n 's/.*cases=\([0-9]*\).*/\1/p' <<< "$SUM")"
n_cells="$(sed -n 's/.*lines_judged=\([0-9]*\).*/\1/p' <<< "$SUM")"
n_ok="$(sed -n 's/.*ok=\([0-9]*\).*/\1/p' <<< "$SUM")"
n_red="$(sed -n 's/.*red=\([0-9]*\).*/\1/p' <<< "$SUM")"
n_noi="$(sed -n 's/.*noinfo=\([0-9]*\).*/\1/p' <<< "$SUM")"

# ── 断言③：逐例正控（**这一条比 rc 重要**：它证"真的走到了被测代码"）─────────────────
n_pos="$(grep -ac '^PEA_POSCTL ' "$OUT" 2>/dev/null || true)"; n_pos="${n_pos:-0}"
n_reached_len="$(grep -a '^PEA_POSCTL ' "$OUT" 2>/dev/null | grep -ac "verdict=$POSCTL_LENIENT" || true)"; n_reached_len="${n_reached_len:-0}"
n_reached_str="$(grep -a '^PEA_POSCTL ' "$OUT" 2>/dev/null | grep -ac "verdict=$POSCTL_STRICT" || true)"; n_reached_str="${n_reached_str:-0}"
echo "PRODUCT_ENTRY_STEP 口径 判定例=$n_cases 期望=$EXPECT_CASES ｜判据格=$n_cells 期望=$EXPECT_CELLS ｜符合=$n_ok 红=$n_red noinfo=$n_noi ｜正控行=$n_pos（宽松档 $n_reached_len 例、严格档 $n_reached_str 例）"
echo "PRODUCT_ENTRY_STEP 口径 下界（**唯一声明处**）：EXPECT_CASES=$EXPECT_CASES｜EXPECT_CELLS=$EXPECT_CELLS｜EXPECT_MCASES=$EXPECT_MCASES｜宽松档口径=$POSCTL_LENIENT｜严格档口径=$POSCTL_STRICT"

DEC=0; WHY=""
if [ "$n_cases" != "$EXPECT_CASES" ]; then
    DEC=2; WHY="例数不守恒：实得 $n_cases ≠ 期望 $EXPECT_CASES ⇒ 仪器没跑满"
elif [ "$n_cells" != "$EXPECT_CELLS" ]; then
    DEC=2; WHY="判据格数缩水：实得 $n_cells ≠ 期望 $EXPECT_CELLS ⇒ **判定面变小 = 恒绿风险**（纪律 47 同族）"
elif [ "$n_reached_len" != "$EXPECT_MCASES" ]; then
    DEC=2; WHY="正控不过：走宽松档的例数 $n_reached_len ≠ $EXPECT_MCASES ⇒ **没有走到被测代码**（读数无判别力）"
elif [ "$n_pos" != "$EXPECT_CASES" ]; then
    DEC=2; WHY="正控行数 $n_pos ≠ 例数 $EXPECT_CASES ⇒ 有的例连正控都没打"
elif [ -n "$n_noi" ] && [ "$n_noi" != 0 ]; then
    DEC=2; WHY="臂自报 noinfo=$n_noi ⇒ 探针算不出（**NOINFO 不许算绿**）"
elif [ -n "$n_red" ] && [ "$n_red" != 0 ]; then
    DEC=1; WHY="有判据不符的格：red=$n_red"
fi

if [ "$POLARITY" = 0 ]; then
    PC_AT_END="$(sha16 "$AUTH_PC")"
    if [ "$PC_AT_END" != "$PC_AT_START" ]; then
        echo "PRODUCT_ENTRY_STEP=NOINFO 本步期间被测 pc 变了：start=$PC_AT_START end=$PC_AT_END ⇒ 读数不可归因（纪律 35）"
        exit 2
    fi
    echo "PRODUCT_ENTRY_STEP 被测 pc 全程未变 = $PC_AT_START"
fi

case "$DEC" in
0) echo "PRODUCT_ENTRY_STEP=PASS 判定例=$n_cases/$EXPECT_CASES 判据格=$n_cells/$EXPECT_CELLS 全部符合真值（红=0 noinfo=0）｜5 个 M 例**逐例**走宽松档（正控 $n_reached_len/$EXPECT_MCASES）｜3 个阴性对照走严格档（$n_reached_str 例）｜pc=$PC_AT_START"
   exit 0 ;;
1) echo "PRODUCT_ENTRY_STEP=FAIL 判定例=$n_cases 期望=$EXPECT_CASES：$WHY"
   echo "  ∟ 逐例点名（臂原文）："
   grep -a '^PEA_LINE .*verdict=RED' "$OUT" | head -40 | sed 's/^/      /'
   echo "  ∟ ⚠️ **今天没有『预期红』**：本步在现役树上红 = **产品侧那条链路坏了**（D-T2-c 那一族）。"
   echo "     正确动作 = 去查产品侧，**不是**在这里登记预期红、更不是放宽下界。"
   exit 1 ;;
*) echo "PRODUCT_ENTRY_STEP=NOINFO 判定例=$n_cases 期望=$EXPECT_CASES：$WHY（算不出 ⇒ **不是通过**）"
   exit 2 ;;
esac
