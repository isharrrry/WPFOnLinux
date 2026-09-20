#!/usr/bin/env bash
# baseline-sha-check.sh —— 冻结基线的「整份 sha + 世代」机器核对（在册、**只读**；不跑任何 harness）
#
# 判据（三档，**绝不把"没声明"当绿**）：
#   1) 现场重算  samples/WpfTextDemo/ACCEPTANCE-BASELINE.md  的 sha16
#   2) docs/CURRENT-STATE.md 里必须有机器行：
#          > BASELINE-FROZEN gen=#NN sha16=<hex16> file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
#        · 缺该行                        ⇒ BASELINESHA=NOINFO（文档没声明 ⇒ 无信息，不是"一致"）
#        · 有该行但其值 ≠ 现场重算值      ⇒ BASELINESHA=FAIL
#        · 相等                          ⇒ BASELINESHA=PASS
#   3) 基线文件里**最新**那行 `# RE-FROZEN #NN` 的 NN  必须 == 声明 gen ⇒ BASELINEGEN=PASS/FAIL
#      （防"文档说 #24、文件里最新却是 #23"）
#
# rc：**只有两项全 PASS 才 rc=0**；FAIL 与 NOINFO 都 rc=1（"没声明"必须出声，不许静默绿）
# 反极性自测：--selftest
#
# 起因见 ACCEPTANCE-BASELINE.md 的 `#24` 块：`#23` 的整份 sha 在两处文档里记录不一致
# （5ccdf74a56955096 vs 87ae111462ca2159），而 `#23` 内容已被覆盖 ⇒ **不可复算**。本脚本就是补这个洞。
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="$(cd "$HERE/../../.." && pwd)"
BASE="${BSC_BASE:-$R/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md}"
STATE="${BSC_STATE:-$R/docs/CURRENT-STATE.md}"
REL="samples/WpfTextDemo/ACCEPTANCE-BASELINE.md"

run_check() {   # $1=BASE $2=STATE
  local base="$1" state="$2" live decl dgen dsha dfile fgen
  BASELINESHA=NOINFO; BASELINEGEN=NOINFO; BASELINESHA_LIVE=''; BASELINESHA_DECL=''
  if [ ! -f "$base" ]; then echo 'BASELINESHA=NOINFO reason=baseline-missing'; return 1; fi
  if [ ! -f "$state" ]; then echo 'BASELINESHA=NOINFO reason=state-missing'; return 1; fi

  live="$(sha256sum "$base" | cut -c1-16)"
  BASELINESHA_LIVE="$live"

  decl="$(grep -m1 '^[> ]*BASELINE-FROZEN ' "$state" || true)"
  if [ -z "$decl" ]; then
    BASELINESHA=NOINFO
    echo "BASELINESHA=NOINFO reason=no-declaration state=$STATE（缺机器行 ⇒ 无从判定，**不是一致**）"
  else
    dgen="$(printf '%s' "$decl" | sed -n 's/.*gen=\(#[0-9][0-9A-Za-z]*\).*/\1/p')"
    dsha="$(printf '%s' "$decl" | sed -n 's/.*sha16=\([0-9a-f]\{16\}\).*/\1/p')"
    dfile="$(printf '%s' "$decl" | sed -n 's/.*file=\([^ ]*\).*/\1/p')"
    if [ -z "$dsha" ]; then
      BASELINESHA=NOINFO
      echo "BASELINESHA=NOINFO reason=decl-unparsable decl=$decl"
    elif [ "$dsha" = "$live" ]; then
      BASELINESHA=PASS; BASELINESHA_DECL="$dsha"
    else
      BASELINESHA=FAIL; BASELINESHA_DECL="$dsha"
    fi
    [ -n "$dfile" ] && [ "$dfile" != "$REL" ] \
      && echo "BASELINEFILE=WARN decl_file=$dfile expect=$REL"
  fi

  fgen="$(grep -m1 -o '^# RE-FROZEN #[0-9][0-9A-Za-z]*' "$base" | sed 's/^# RE-FROZEN //')"
  BASELINE_FILE_GEN="${fgen:-none}"
  if [ -n "${dgen:-}" ] && [ -n "$fgen" ]; then
    if [ "$dgen" = "$fgen" ]; then BASELINEGEN=PASS; else BASELINEGEN=FAIL; fi
  fi

  echo "BASELINESHA=$BASELINESHA live=$live decl=${BASELINESHA_DECL:-none}"
  echo "BASELINEGEN=$BASELINEGEN decl_gen=${dgen:-none} file_newest_gen=${fgen:-none}"
  echo "BASELINE_BYTES=$(stat -c '%s' "$base")"

  # 【重复字面量】"……整份 sha = `<hex16>`" 这种**散文式声明**禁止出现在**活的权威对**里
  #   （`#23` 的事故形态正是"三个文档各写一个值、事后无法判定哪个对"）⇒ **值只许出现在
  #   下面那条机器行里**。历史的 `WAVE*-PREREGISTRATION.md` 不在射程内（那是存档、不是活声明）。
  BASELINEDUP=PASS
  local dup
  dup="$(grep -nE '整份[^0-9a-f]{0,6}sha[^0-9a-f]{0,6}[0-9a-f]{16}' "$state" "$base" 2>/dev/null || true)"
  if [ -n "$dup" ]; then
    BASELINEDUP=FAIL
    printf 'BASELINEDUP=FAIL 活的权威对里出现散文式 sha 声明（只许机器行声明值）:\n%s\n' "$dup"
  else
    echo 'BASELINEDUP=PASS n=0'
  fi

  if [ "$BASELINESHA" = PASS ] && [ "$BASELINEGEN" = PASS ] && [ "$BASELINEDUP" = PASS ]; then return 0; fi
  return 1
}

if [ "${1:-}" = '--selftest' ]; then
  # ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、也不许冒充红）──
  #   为什么需要：本件的 `chk()` 用 `"$0"` **重入自己**（`:98`）⇒ bash 每次为新子进程**从磁盘重读**本件
  #   ⇒ 父进程按旧版造夹具、子进程按新版判定 ⇒ **只要本件在窗口内被改写，父子版本就错位，会出凭空的红**。
  #   （现场：`#32` W32B 观察到本件同族件在 347 行/`733c04570d4602f5` → 359 行/`b98b7d8926b275c9` 的
  #     改写窗口里 `not-as-expected`=3,1,1,1,1，改写之后连跑 9 次全 0 ⇒ 红窗口 = 改件窗口。）
  #   口径：**开头记本件 sha16、结尾再算一次**；不等 ⇒ 印 `ST_ATTEST=NOINFO` 并点名（含 sha0/sha1 与内层 rc），
  #   统一以 **rc=2**（`NOINFO` 码）收尾 —— 本件自己的 `NOINFO` 是 rc=1，这里用 2 **更强**：不会再与 FAIL 混。
  #   只加在 `--selftest` 路径上；**生产路径一字未动**；不删例、不放宽任何期望。
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
  T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
  np=0; nf=0
  mk() {  # 造一对 (base,state) 到 $T/$1
    mkdir -p "$T/$1"; cp -p "$BASE" "$T/$1/base.md"; cp -p "$STATE" "$T/$1/state.md"
  }
  # 生成声明行（用现场真值），可带扰动
  decl_line() { printf '> BASELINE-FROZEN gen=%s sha16=%s file=%s\n' "$1" "$2" "$REL"; }
  LIVE="$(sha256sum "$BASE" | cut -c1-16)"
  GEN="$(grep -m1 -o '^# RE-FROZEN #[0-9][0-9A-Za-z]*' "$BASE" | sed 's/^# RE-FROZEN //')"
  # 把 state 里原有声明行整段替换成我们造的（保证自测不受现场行影响）
  # ⚠️ 【`W33B` 加严 · 只加强】原写法 `grep -v … > "$1.tmp" && mv "$1.tmp" "$1"` 有**静默失效**：
  #    `grep -v` 在"**每一行都被过滤掉**"时**没有任何输出** ⇒ 退出码 **1** ⇒ `&&` 短路 ⇒ `mv` **不执行**
  #    ⇒ 沙箱 state **原封不动**（现场声明行没被剥掉）⇒ 夹具被现场行污染 ⇒ **凭空的红**。
  #    现场（`W33B` 实测，成对读数）：把一个"只有声明行"的 state 喂进来 ⇒ `cases=6 pass=2 fail=4`
  #    （B/C/D/E 四例假红）。真 `docs/CURRENT-STATE.md` 另有大量非声明行 ⇒ 今天**潜伏**（够不上红，
  #    但够得上"静默"）。修法：**不把 `mv` 挂在 grep 的退出码上** —— 剥没剥干净由结果文件说话。
  scrub() { grep -v '^[> ]*BASELINE-FROZEN ' "$1" > "$1.tmp" || true; mv "$1.tmp" "$1"; }

  chk() {  # $1=case $2=expect $3=dir
    local out rc got
    out="$(BSC_BASE="$T/$3/base.md" BSC_STATE="$T/$3/state.md" "$0" 2>&1)"; rc=$?
    # ⚠️ 必须 head -1：**声明缺失时**会有两行 BASELINESHA=（诊断行 + 汇总行），
    #    不取首行会让 got 里带换行、比较永远失败（本脚本自测 case C 抓到过）。
    got="$(printf '%s' "$out" | sed -n 's/^BASELINESHA=\([A-Z]*\).*/\1/p' | head -1)"
    local ggen; ggen="$(printf '%s' "$out" | sed -n 's/^BASELINEGEN=\([A-Z]*\).*/\1/p' | head -1)"
    local ok='no'
    [ "$got" = "$2" ] && ok='yes'
    # expect=GENFAIL 时单看 BASELINEGEN
    if [ "$2" = 'GENFAIL' ]; then [ "$ggen" = FAIL ] && ok='yes'; got="gen:$ggen"; fi
    local gdup; gdup="$(printf '%s' "$out" | sed -n 's/^BASELINEDUP=\([A-Z]*\).*/\1/p' | head -1)"
    if [ "$2" = 'DUPFAIL' ]; then [ "$gdup" = FAIL ] && ok='yes'; got="dup:$gdup"; fi
    if [ "$ok" = yes ]; then np=$((np+1)); else nf=$((nf+1)); fi
    printf 'SELFTEST case=%s expect=%s got=%s rc=%s => %s\n' "$1" "$2" "$got" "$rc" "$ok"
  }

  # 扰动值：换掉首位十六进制字符 ⇒ **严格 16 位**且必与真值不同
  # （原先用 sed 拼 x 前缀再截断，结果只有 15 位 ⇒ 只证出"畸形 ⇒ NOINFO"，没证出 FAIL）
  case "${LIVE:0:1}" in 0) _r=1;; *) _r=0;; esac
  BAD="$_r${LIVE:1}"
  if [ "${#BAD}" -ne 16 ] || [ "$BAD" = "$LIVE" ]; then
    echo "BSC_SELFTEST=FAIL reason=bad-construction BAD=$BAD len=${#BAD}"; exit 1
  fi
  # ── 【`W33B` 加严 · 前提自持】六例的**世代前提**：现场基线里必须有**可解析**的 `# RE-FROZEN #NN` 行。
  #   不成立 ⇒ **`NOINFO`**（不是绿、也不是红）：`--selftest` 的**仪器前提**缺了，与"判据真坏了"不是一回事。
  #   （旧行为：D/E 两例会静默变成 `got=gen:NOINFO` 混进 `fail=` 计数里，与真红不可分。）
  if [ -z "$GEN" ]; then
    echo "BSC_SELFTEST=NOINFO reason=premise-unmet:no-live-generation（现场基线里没有可解析的 \`# RE-FROZEN #NN\` 行 ⇒ 夹具的世代前提不成立 ⇒ 本趟读数无信息）"
    exit 2
  fi
  mk A; scrub "$T/A/state.md"; decl_line "$GEN" "$LIVE" >> "$T/A/state.md"; chk A PASS A
  mk B; scrub "$T/B/state.md"; decl_line "$GEN" "$BAD" >> "$T/B/state.md"; chk B FAIL B
  mk C; scrub "$T/C/state.md"; chk C NOINFO C
  # 反极性（`D`）：**声明世代 != 文件里最新世代** ⇒ `BASELINEGEN` 必须 FAIL。
  #   ⚠️ 【`W33B` 加严 · 只加强】**裸基线范式**：原写法把"不匹配的世代"**写死成字面量 `#000`**
  #   ⇒ 埋了同一族会移动的前提：「现场世代 != `#000`」。实测（合成基线最新世代恰为 `#000`）⇒ 原写法
  #   **case D 变红**（`expect=GENFAIL got=gen:PASS`，`pass=5 fail=1`）。修法：由**现场世代现算**
  #   （前面插一个 `0`：`#32` → `#032`）⇒ 与现世代**必不相同**。判据语义一字未改。
  BADGEN="#0${GEN#\#}"
  if [ "$BADGEN" = "$GEN" ]; then
    echo "BSC_SELFTEST=FAIL reason=bad-construction BADGEN=$BADGEN GEN=$GEN（现算的假世代必须与现场世代不同）"; exit 1
  fi
  mk D; scrub "$T/D/state.md"; decl_line "$BADGEN" "$LIVE" >> "$T/D/state.md"; chk D GENFAIL D
  mk E; scrub "$T/E/state.md"; decl_line "$GEN" "$LIVE" >> "$T/E/state.md"
     # 文件里**出现更新的世代行**（在册读法：最新 = 第一处匹配）⇒ gen 必须 FAIL
     # ⚠️ 【`W33B` 加严 · 只加强】**裸基线范式**：原写法把"更新的世代"**写死成字面量 `#99`**
     #    ⇒ 埋了一条**会随换代被打掉的前提**：「现场世代 != `#99`」。实测（合成基线，最新世代行
     #    恰为 `#99`）⇒ 原写法 **case E 变红**（`expect=GENFAIL got=gen:PASS`），而 `--selftest`
     #    没有任何东西看着（纪律 68）⇒ 红了也没人看见。
     #    修法：假世代由**现场世代现算**（前面插一个 `9`：`#32` → `#932`）⇒ 与现世代**必不相同**
     #    （有限串前插字符必改变该串）。**判据语义一字未改**：核的仍是"最新世代 != 声明世代 ⇒ GENFAIL"。
     FAKE_GEN="#9${GEN#\#}"
     if [ -z "$GEN" ] || [ "$FAKE_GEN" = "$GEN" ]; then
       echo "BSC_SELFTEST=FAIL reason=bad-construction FAKE_GEN=$FAKE_GEN GEN=${GEN:-<空>}（现算的假世代必须与现场世代不同）"; exit 1
     fi
     { printf '# RE-FROZEN %s —— 假的新世代\n' "$FAKE_GEN"; cat "$T/E/base.md"; } > "$T/E/base.md.new" \
       && mv "$T/E/base.md.new" "$T/E/base.md"
     chk E GENFAIL E
  mk F; scrub "$T/F/state.md"; decl_line "$GEN" "$LIVE" >> "$T/F/state.md"
     printf '> 该文件重冻时整份 sha = `deadbeefdeadbeef`\n' >> "$T/F/state.md"
     chk F DUPFAIL F

  echo "BSC_SELFTEST=$([ "$nf" -eq 0 ] && echo PASS || echo FAIL) cases=$((np+nf)) pass=$np fail=$nf"
  [ "$nf" -eq 0 ] && exit 0 || exit 1
fi

run_check "$BASE" "$STATE"
