#!/usr/bin/env bash
# T1b · LS 边界绊线装置（**真值来源 = 动态加载器自己的符号查找日志**）
# ============================================================================
#  要回答：PC 有没有在运行期**按名字要过** LineServices 的导出？
#    本工程 Win32 shim（libwpfwin32.so）里 `LoAcquireBreakRecord` / `LoCreateLine` / `LoCreateContext`
#    **连符号都没有**（`nm -D` 实测；只有 `LoGetEscString` / `LsDisableSpecialCharacterLigature`）
#    ⇒ 一旦真走到 LS，现象是 **EntryPointNotFoundException（硬崩）**，并且异常消息里带着符号名。
#
#  为什么不用 LD_PRELOAD 拦 `dlsym`（我先写了，**放弃**）：本库自己初始化就要用 dlsym，
#    而 LD_PRELOAD 把我们放在全局查找序最前面 ⇒ 自己的 `dlvsym(RTLD_NEXT,"dlsym")` 会回到自己，
#    bootstrap 不可靠（实测自证程序拿到 0 行日志）。改用 `LD_DEBUG=symbols`：
#    **日志由 ld.so 自己写**，不经过任何我们的代码 ⇒ 不可撒谎。
#
#  用法：
#    bash t1b-ls-tripwire.sh --selftest              # 装置自证（必须 0 退出）
#    bash t1b-ls-tripwire.sh <outdir> -- <cmd...>    # 跑命令并统计 LS 家族查找
#  产物：<outdir>/ld.<pid>（ld.so 原始日志，保留）+ <outdir>/ls-tripwire.txt（汇总）
# ============================================================================
set -uo pipefail

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SELFTEST="$SELF_DIR/t1b-ls-selftest"

summarize() {   # $1=目录（含 ld.* 日志）
  local dir="$1" log
  # ⚠️ LD_DEBUG_OUTPUT 是**每进程一个文件**（ld.<pid>）⇒ 必须把所有文件**聚合**起来看。
  #    本装置第一版只取 `head -1`（= bash 自己的日志），于是"被监听的 .NET 子进程"整段看不见 ——
  #    实测现象是 HelloWpf 明明建了窗口、`LsDisableSpecialCharacterLigature` 却报 0 查找。
  #    （又一条"验证工具自己在说谎"，已修。）
  log="$dir/ld-all.txt"
  cat "${T1B_LDDEBUG_DIR:-$dir}"/ld.* > "$log" 2>/dev/null
  [ -s "$log" ] || { echo "[失败] 没找到/没内容 ld.so 日志（${T1B_LDDEBUG_DIR:-$dir}/ld.*）"; return 1; }
  local nfiles; nfiles=$(ls "${T1B_LDDEBUG_DIR:-$dir}"/ld.* 2>/dev/null | wc -l)
  local out="$dir/ls-tripwire.txt"
  {
    echo "== T1b · LS 绊线（真值来源：ld.so 的 LD_DEBUG=symbols 日志）=="
    echo "日志 = $log（聚合自 $nfiles 个进程日志，共 $(wc -l < "$log") 行）"
    echo
    echo "-- LS 家族符号被查找的次数（Lo*/Ls*/Nl*/Fs*）--"
    grep -o "symbol=[A-Za-z_0-9]*" "$log" | sed 's/symbol=//' \
      | grep -E '^(Lo|Ls|Nl|Fs)[A-Za-z]' | sort | uniq -c | sort -rn
    echo
    echo "-- 关键符号：是否被查找过 / 查找传播范围 --"
    echo "   判据（不猜命中位置，只报事实）：查找行数 = 1 ⇒ 第一个库里就有；行数 ≥ 6 ⇒ 整条依赖链都翻遍（MISS）"
    for s in LoAcquireBreakRecord LoCreateLine LoCreateContext LoGetEscString LsDisableSpecialCharacterLigature; do
      local n; n=$(grep -c "symbol=$s;" "$log")
      if [ "$n" -eq 0 ]; then echo "  $s: **没有**被查找过（0 行）"
      else
        local libs; libs=$(grep "symbol=$s;" "$log" | sed 's/.*lookup in file=//; s/ \[0\]//' | sort -u)
        local nl; nl=$(printf '%s\n' "$libs" | wc -l)
        local verdict
        if [ "$nl" -ge 6 ]; then verdict="MISS（翻遍 $nl 个库没找到 ⇒ 真被调到就会抛 EntryPointNotFoundException）"
        else verdict="FOUND（只翻了 $nl 个库就命中：$(printf '%s' "$libs" | tail -1)）"; fi
        echo "  $s: 被查找 $n 行 ⇒ $verdict"
      fi
    done
  } | tee "$out"
  return 0
}

if [ "${1:-}" = "--selftest" ]; then
  # ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、不许冒充红）──
  #   本件自测以 `bash "$SELF_DIR/t1b-ls-tripwire.sh"` **重入自己**（`:66`）⇒ bash 每次为新子进程从磁盘
  #   **重读**本件 ⇒ 父进程按旧版起装置、子进程按新版判 ⇒ **改件窗口里出的红是凭空的红**。
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
      exit 2
    fi
    printf 'ST_ATTEST=PASS self=%s sha16=%s（自测期间本件未变 ⇒ 读数可归因）\n' "$ST_SELF" "$ST0"
    exit "$ST_RC"
  fi
  echo "== LS 绊线装置 · 自证 =="
  echo "（用一个**已知存在**与一个**已知缺失**的符号做对照；判据 = ld.so 日志 + nm -D 结论一致）"
  D=$(mktemp -d); rm -f /tmp/t1b-lstripwire.log
  echo
  bash "$SELF_DIR/t1b-ls-tripwire.sh" "$D" -- "$SELFTEST"
  echo
  # ── 【`W33B` 加严 · 只加强】① **聚合全部 `ld.*`**，不再 `head -1` 取一份。
  #   `LD_DEBUG_OUTPUT` 是**每进程一份** `ld.<pid>`（同件 `:26-29` 的注释自己记过这个坑：
  #   "第一版只取 head -1 = bash 自己的日志 ⇒ 被监听的子进程整段看不见"）；这里 `head -1` 取到
  #   哪一份取决于 **pid 顺序** ⇒ 两个 ✗ 的**假 ✗**。聚合后判据**更严**（两个关键符号必须出现在
  #   任何一个被监听进程的日志里；少一份日志不会让它变绿）。
  #   ② **一份 `ld.*` 都没有**时：旧行为是 `log` 为空 ⇒ `grep` 报 `没有那个文件或目录` ⇒ 两个 ✗ ⇒
  #   **红**。而"装置缺件（helper 没跑起来）"按本工程纪律（`D-T5-R`：缺 shim 由 `FAIL` 改 `NOINFO`）
  #   **不是"被测件失败"** ⇒ 改判 `NOINFO` 并点名（不许当绿、也不许冒充红）。
  log="$D/ld-selftest-all.txt"
  nlogs=$(ls "$D"/ld.* 2>/dev/null | wc -l)
  if [ "$nlogs" -eq 0 ]; then
    echo "⇒ 装置自证 NOINFO reason=no-ld-so-logs（$D 里一份 ld.* 都没有 ⇒ helper \`$SELFTEST\` 没跑起来 ⇒ 本趟无信息）"
    echo "  原始日志目录 $D/（未删，供复核）"
    exit 2
  fi
  cat "$D"/ld.* > "$log" 2>/dev/null
  echo "（聚合 $nlogs 份 ld.* ⇒ $log，共 $(wc -l < "$log") 行）"
  ok=1
  grep -q "symbol=LsDisableSpecialCharacterLigature;" "$log" || { echo "  ✗ 日志里没有『已知存在』符号的查找"; ok=0; }
  grep -q "symbol=LoAcquireBreakRecord;" "$log"            || { echo "  ✗ 日志里没有『已知缺失』符号的查找"; ok=0; }
  # 交叉核对：nm -D 的结论必须与日志一致
  SHIM="$SELF_DIR/../../../src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
  if [ ! -f "$SHIM" ]; then
    # ── 【`W33B` 加严 · 只加强】旧行为：`if [ -f "$SHIM" ]` 为假 ⇒ **整段交叉核对静默消失**，
    #    而下面照印「装置自证 通过（捕获到的查找与 **nm -D** 事实一致）」—— 那句话的**前提是
    #    "产物存在"**，产物不在时它**无法成立**却照样打绿（**成对读数**：深沙箱里真树 = 2 行 nm ✓
    #    + rc=0；同一份件 ↔ 产物不在 = **0 行 nm + 照印"通过" + rc=0**）。按本工程纪律：
    #    "前提不成立要出声，且**不是红**" ⇒ 改判 `NOINFO` 并点名。
    echo "  ⇒ 装置自证 NOINFO reason=nm-crosscheck-premise-unmet shim=$SHIM"
    echo '     （装置自证自称「与 nm -D 事实一致」，而 `nm` 的**前提 = 真构建产物存在**；产物不在 ⇒ 那句话无信息）'
    echo "  原始日志保留在 $D/（未删，供复核）"
    exit 2
  fi
  # 交叉核对（前提"产物存在"已由上面那条 `NOINFO` 守卫保证 ⇒ 这里不再需要 `if [ -f … ]`）
    # ⚠️ 不能写成 `nm ... | grep -q X && ...`：`set -o pipefail` 下 grep -q 提前退出会让 nm 吃 SIGPIPE
    #    ⇒ 管道整体非 0 ⇒ **假 ✗**（本装置第一版就踩了这个，自证曾误报"矛盾"）。先落变量再判。
    nmout=n_ls=n_lo="";
    nmout=$(nm -D --defined-only "$SHIM" 2>/dev/null || true)
    n_ls=$(printf '%s\n' "$nmout" | grep -c " T LsDisableSpecialCharacterLigature" || true)
    n_lo=$(printf '%s\n' "$nmout" | grep -c " T LoAcquireBreakRecord" || true)
    if [ "$n_ls" -ge 1 ]; then echo "  ✓ nm -D：LsDisableSpecialCharacterLigature **已定义**（与日志 FOUND 一致）"
    else echo "  ✗ nm -D 与日志矛盾（nm 说未定义，日志说 FOUND）"; ok=0; fi
    if [ "$n_lo" -eq 0 ]; then echo "  ✓ nm -D：LoAcquireBreakRecord **未定义**（与日志 MISS 一致）"
    else echo "  ✗ nm -D 与日志矛盾（nm 说已定义）"; ok=0; fi
  echo
  echo "⇒ 装置自证 $([ $ok -eq 1 ] && echo '通过（捕获到的查找与 nm -D 事实一致）' || echo '**未通过**')"
  echo "  原始日志保留在 $D/（未删，供复核）"
  exit $((1-ok))
fi

DIR="${1:?用法: t1b-ls-tripwire.sh <outdir> -- <cmd...>}"; shift
[ "${1:-}" = "--" ] && shift
mkdir -p "$DIR"
LDDBG="${T1B_LDDEBUG_DIR:-$DIR}"
mkdir -p "$LDDBG"
[ "$LDDBG" != "$DIR" ] && rm -f "$LDDBG"/ld.* 2>/dev/null
LD_DEBUG=symbols LD_DEBUG_OUTPUT="$LDDBG/ld" "$@" > "$DIR/cmd.out" 2> "$DIR/cmd.err"
rc=$?
echo "命令退出码 = $rc"
summarize "$DIR"
exit $rc
