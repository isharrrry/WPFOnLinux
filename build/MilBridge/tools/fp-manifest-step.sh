#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  fp-manifest-step.sh —— 波 `#70`（`TASK-0724`）第 `[42]` 步驱动（**纯读、零 `dotnet`、秒级**）
#
#  【它接线什么】`build/MilBridge/tools/fp-manifest-teeth-check.sh`（`#65` 落仓、`#70` **首次接线**：
#    此前它在 `fp_inputs()` 覆盖面里，却**没有任何一步调用它** ⇒ 正常运行恒为
#    `FP_MANIFEST_TEETH=NOINFO reason=no-manifest`、`rc=2` ⇒ **"在册但没牙床"**。
#
#  【为什么必须由本件驱动（而不是把牙直接写进 `run_step`）】那条牙要一份**清单**（`sha256sum` 形态的
#    `^[0-9a-f]{64}  <path>$` 逐行表）。仓里**唯一权威的清单来源**是 `close-wave.sh` 的 `fp_inputs()`
#    —— 它是个**函数**，stdout 是**最终指纹**（不是清单）⇒ 必须走**同码路径拦截**才拿得到"真正交给
#    `sha256sum` 的那些名字"：
#      · `sha256sum` 是 `xargs` **exec** 起来的 ⇒ 用 **`PATH` 前置同名 shim** 收它的 `argv`；
#      · **函数体一个字都不改**（`sed -n '/^fp_inputs()/,/^}/p'` 原样抽出、原样执行）。
#    ⇒ 与 `fp-inputs-hygiene-check.sh` 的 `capture()` 同法（**同一份逻辑只有一份**：就是被测那一份），
#       本件**不重写任何 `find`**（本仓明令：同一份逻辑存在两处必然分叉）。
#
#  【判据（三态，与仓内牙同形）】**0 = PASS**｜**1 = FAIL**｜**2 = NOINFO**（算不出来 ⇒ **绝不是绿**）。
#    本件自己**不**判清单形状/件数 —— 那是牙的事（`MANIFEST-SHAPE`／`FILES-N`）；本件只保证端过去的
#    那份清单**确实出自同码路径**：
#      ① **可跑**：`fp_inputs()` 抽得出、跑得动、吐出 64 位 hex（否则 NOINFO）；
#      ② **不扰动**：拦截跑出的指纹 `==` 无拦截跑出的指纹（否则 NOINFO —— 拦截改了被测函数）；
#      ③ **有清单**：拦截到的 `argv` 非空（否则 NOINFO —— 0 件也是一种"算不出来"）；
#      ④ **真算**：清单产出时 `xargs sha256sum` 的 **`stderr` 必须为空**（非空 ⇒ FAIL 并点名 ——
#         这就是 `D-G120` 实例②／`D-G119` 域选错那一格：旧管道把 `stderr` 吞掉、**照旧给出形状完好的
#         64-hex 指纹**）；⑤ 清单行数 == 名字数（否则有名字没被哈希 ⇒ 同样是形状完好的假指纹）。
#
#  【件数从哪来（`--expect` **必须**由调用者声明）】本件**不猜**件数：`--expect N` 由 `verify-all.sh`
#    的步本体**显式**给出（那是**与生产路径无关**的唯一来源 —— 牙头原话）；本件把现场件数逐格印出来
#    供对账。**没给 `--expect` ⇒ 牙自己走 `NOINFO reason=no-expected-count`**（本件**不**代它补默认值
#    —— 补默认值就是"没声明也当绿"）。
#
#  【成本／副作用】纯读、零 `dotnet`、秒级（覆盖面上百件 ⇒ 一次 `sha256sum`）。**不写 `$R`**：临时件
#    一律 `mktemp -d`（优先 `TMPDIR`，**无 `TMPDIR` 时落 `$HOME/.cache/wpf-linux/tmp`，刻意不落共享
#    `/tmp`**）＋ `trap` 回收；`--debug-tmp` 打印实际目录且不清理（供诊断）。
#    ⚠️ 本件**不含任何车道路径**（`D-G137`：从车道沙箱提升为仓内件的工具，默认路径只许**仓内或调用者
#       可覆盖**）—— 默认树根 = 本件上溯三级（`build/MilBridge/tools/` ⇒ 仓根）。
# ---------------------------------------------------------------------------
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
REAL_ROOT="$(cd "$HERE/../../.." && pwd)"
REPO="${FPMS_REPO:-$REAL_ROOT}"
CW=""
EXPECT=""
TOOTH_OVERRIDE=""
TMPBASE="${TMPDIR:-$HOME/.cache/wpf-linux/tmp}"
KEEP_TMP=0

say() { printf '%s\n' "$*"; }
sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }

usage() {
    cat <<'TXT'
用法：
  fp-manifest-step.sh [--repo DIR] [--close-wave PATH] [--tooth PATH] --expect N [--debug-tmp]
判据：0 = PASS（牙判 PASS）｜1 = FAIL（牙判 FAIL／清单本身不真）｜2 = NOINFO（算不出 ⇒ 不是绿）
环境：FPMS_REPO（树根，默认=本脚本上溯三级）
TXT
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo)       REPO="${2:-}"; shift 2 ;;
        --close-wave) CW="${2:-}"; shift 2 ;;
        --tooth)      TOOTH_OVERRIDE="${2:-}"; shift 2 ;;
        --expect)     EXPECT="${2:-}"; shift 2 ;;
        --debug-tmp)  KEEP_TMP=1; shift ;;
        -h|--help)    usage; exit 0 ;;
        *)            say "unknown-arg: $1"; usage; exit 2 ;;
    esac
done

noinfo() { say "FP_MANIFEST_STEP=NOINFO reason=$1"; return 2; }

if [ -n "$EXPECT" ]; then
    case "$EXPECT" in *[!0-9]*) say "FP_MANIFEST_STEP=NOINFO reason=expect-not-a-number expect=$EXPECT"; exit 2 ;; esac
fi
[ -n "$CW" ] || CW="$REPO/build/close-wave.sh"

TOOTH="${TOOTH_OVERRIDE:-$HERE/fp-manifest-teeth-check.sh}"
[ -f "$TOOTH" ] || { noinfo "tooth-missing path=$TOOTH"; exit $?; }
[ -f "$CW" ]    || { noinfo "close-wave-missing path=$CW"; exit $?; }
[ -d "$REPO" ]  || { noinfo "repo-missing path=$REPO"; exit $?; }
REAL_SHA256SUM="$(type -P sha256sum || true)"
[ -n "$REAL_SHA256SUM" ] || { noinfo 'sha256sum-not-found'; exit $?; }

mkdir -p "$TMPBASE" 2>/dev/null || { noinfo "tmpbase-unusable TMPBASE=$TMPBASE"; exit $?; }
SB="$(mktemp -d "$TMPBASE/fp-manifest-step.XXXXXX")" || { noinfo "mktemp-failed TMPBASE=$TMPBASE"; exit $?; }
if [ "$KEEP_TMP" = 1 ]; then say "FPMS_TMP_DIR=$SB"; else trap 'rm -rf "$SB"' EXIT; fi

say "FPMS_SOURCE=$CW sha16=$(sha16 "$CW")"
say "FPMS_REPO=$REPO"
say "FPMS_TOOTH=$TOOTH sha16=$(sha16 "$TOOTH")"

# ── ① 同码路径抽函数体（**内容锚，不写行号** —— `close-wave.sh` 每波都会动，行号必错）──────────
body="$(sed -n '/^fp_inputs()/,/^}/p' "$CW" 2>/dev/null)"
case "$body" in
    *'fp_inputs()'*) : ;;
    *) noinfo "fp-inputs-not-found source=$CW（抽不出 fp_inputs() 的函数体 ⇒ 解析失败）"; exit $? ;;
esac
printf '%s\n' "$body" 'fp_inputs' > "$SB/body.sh"

# ── ② 无拦截跑一趟（真值）──────────────────────────────────────────────────────────
real_hash="$( cd "$REPO" 2>/dev/null && bash "$SB/body.sh" 2>"$SB/real.err" )" || true
case "$real_hash" in
    [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*) : ;;
    *) noinfo "fp-inputs-produced-nothing source=$CW out='${real_hash:0:40}'（覆盖率数为空 ⇒ 清单无从谈起）"; exit $? ;;
esac

# ── ③ 拦截跑一趟（**同码路径**：函数体一个字未改）＋ 收 `sha256sum` 的 argv ──────────────────
mkdir -p "$SB/pathbin"
cat > "$SB/pathbin/sha256sum" <<'SHIM'
#!/usr/bin/env bash
if [ "$#" -gt 0 ]; then printf '%s\n' "$@" >> "$FPMS_ARGV"; fi
exec "$FPMS_REAL_SHA256SUM" "$@"
SHIM
chmod +x "$SB/pathbin/sha256sum"
: > "$SB/argv.txt"
intra_hash="$(
    cd "$REPO" 2>/dev/null || exit 2
    export FPMS_ARGV="$SB/argv.txt" FPMS_REAL_SHA256SUM="$REAL_SHA256SUM"
    export PATH="$SB/pathbin:$PATH"
    source "$SB/body.sh"
)" 2>"$SB/intra.err"

# 守卫②：拦截不得扰动被测函数（③ 的机器证 —— 不是推理）
if [ "$real_hash" != "$intra_hash" ]; then
    noinfo "interception-perturbed real=${real_hash:0:16} intra=${intra_hash:0:16}（拦截改了被测函数的行为 ⇒ 读数不可用）"
    exit $?
fi
names_n="$(grep -c . "$SB/argv.txt" || true)"
# 守卫③：0 件也是一种"算不出来"
if [ "${names_n:-0}" -eq 0 ]; then
    noinfo "manifest-empty（拦截到 0 个名字 ⇒ 对拍必定假绿 ⇒ **不算绿**）"
    exit $?
fi

# ── ④ 用**生产同形**的命令把名字表变成清单（`sha256sum` 的 `stderr` **单独收**）─────────────────
#      ⚠️ 旧管道的病就在这一格：`xargs sha256sum | sha256sum | cut` 的 rc 取自**最后一段** ⇒
#         缺件时 `stderr` 有字、`stdout` 缺行，而最终指纹**形状照旧完好**。
( cd "$REPO" && LC_ALL=C xargs sha256sum < "$SB/argv.txt" ) > "$SB/manifest.txt" 2>"$SB/sum.err"
man_n="$(grep -c . "$SB/manifest.txt" || true)"
sum_err_bytes="$(wc -c < "$SB/sum.err" | tr -d ' ')"
fake_fp="$(sha256sum "$SB/manifest.txt" | cut -d' ' -f1)"
say "FP_MANIFEST_STEP names_n=$names_n manifest_n=$man_n expect=${EXPECT:-not-given} sha256sum_stderr_bytes=$sum_err_bytes would_be_fp=${fake_fp:0:16}"
if [ "$sum_err_bytes" -ne 0 ]; then
    sed -n '1,3p' "$SB/sum.err" | while IFS= read -r l; do say "FP_MANIFEST_STEP_BLAME=$l kind=sha256sum-stderr"; done
    say "FP_MANIFEST_STEP=FAIL reason=sha256sum-stderr-nonempty stderr_bytes=$sum_err_bytes manifest_n=$man_n expect=${EXPECT:-not-given}（清单里有**指向不存在件**的行 ⇒ 旧管道在这里**照旧**吐出一个形状完好的指纹 ${fake_fp:0:16}…，而覆盖面其实是缺的）"
    exit 1
fi
if [ "$man_n" -ne "$names_n" ]; then
    say "FP_MANIFEST_STEP=FAIL reason=manifest-short names_n=$names_n manifest_n=$man_n would_be_fp=${fake_fp:0:16}（有名字没被哈希 ⇒ **形状完好的假指纹**）"
    exit 1
fi

# ── ⑤ 装置自证：牙的 `--selftest`（证"装置还活着 ＋ 负腿真会红"）──────────────────────────────
#      ⚠️ **如实划界**：自测过 ≠ 生产路径已接线；本节只证**装置**还在，判定成立与否由 ⑥ 给。
st_out="$(bash "$TOOTH" --selftest 2>&1)"; st_rc=$?
st_key="$(printf '%s\n' "$st_out" | grep -E '^SELFTEST=' | tail -1)"
say "FPMS_TOOTH_SELFTEST rc=$st_rc ${st_key:-SELFTEST=<无结论行>}"
if [ "$st_rc" -ne 0 ]; then
    printf '%s\n' "$st_out" | tail -20
    say "FP_MANIFEST_STEP=FAIL reason=tooth-selftest rc=$st_rc"
    exit 1
fi

# ── ⑥ 判定：把**活的清单**交给牙（逐行形状 ＋ 件数对账都在牙里）───────────────────────────────
bash "$TOOTH" --manifest "$SB/manifest.txt" --expect "$EXPECT"
tooth_rc=$?
say "FP_MANIFEST_STEP_RC=$tooth_rc names_n=$names_n expect=${EXPECT:-not-given} tooth_sha16=$(sha16 "$TOOTH")"
exit "$tooth_rc"
