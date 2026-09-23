#!/usr/bin/env bash
# hygiene-tooth.sh —— 「**装置/口径卫生**」的常态牙（**纯静态读、零 `dotnet`、零构建、秒级、不占槽**）
#
# ═══════════════════════════════════════════════════════════════════════════════
# 【它防什么】三类"**已经在现场发生过、但只修了一次、没有牙**"的装置/口径缺陷
#   ——`TASK-0706`。三类的共同形态是：**修法落地了，但那件事再发生时没有任何东西会响**。
#
#   ── 第一类 `D-G91`（假绿族）：根集合"同一份逻辑两处各写一份"⇒ 必然分叉 ──────────
#     现场：`sync-applocal-authority.sh` 自己写死一份默认扫描根、**漏了 `$REPO/tools`**，
#     而它的判据唯一实现 `check-applocal-sync.sh` **含**它 ⇒ ① 默认参数永远刷不到藏在
#     `$REPO/tools/**` 下的 `STALE`；② 更危险：它拿**收窄根**打出 **`STALE=0` 的假绿**。
#     W113A 已修（根集合从判据唯一实现**派生** ＋ 收窄即拒绝）。**本类把它推广成对任意
#     `(同步器, 校验器)` 对的常态检查**：登记表声明"哪些件是一对、根定义在哪"，机械抽两边的
#     根集合**做集合比较** ⇒ 不等就 `FAIL`（点名差集）；**抽不出** ⇒ `NOINFO`（不许当绿）。
#
#   ── 第二类 `D-G96`（证据保全）：**重跑即毁证** ─────────────────────────────
#     现场：`~/w63a/bin/wm-leg.sh` 用 `: > "$PROG"`（**截断**）写自己的进度文件，而那个文件
#     正是缺陷册里被**逐行引用**的证据 ⇒ **任何一次"修好后重跑一遍"都会当场抹掉该证据**。
#     W113A 已把该件改成"追加 ＋ 每趟独立名 ＋ `.latest`"，但那条纪律**没有牙**。
#     本类**静态扫**"对**跨趟固定**的**证据名**文件做截断写"这一形态（`: > F`／行首 `> F`／
#     `truncate -s 0 F`）⇒ **可执行命中 = 0** 才算绿；注释/文档命中**另计**（打印不判红）。
#     ⚠️ 判red 的三条合取（缺一不算）：**① 目标跨趟固定**（不含 `$$`/`$(date`/`mktemp`，
#        解析后不再有未解出的变量）∧ **② 基名像证据**（`log|progress|evidence|trace|…`）
#        ∧ **③ 不在本件自己的 `--selftest` 区间内**。⇒ "每趟独立名"与"临时目录"两种形态
#        **天然落在判据外**（那正是修法要的样子），不是被漏掉，是**按语义排除**（逐类计数）。
#     ⚠️ 仓外装置根（`$HOME/w63a/bin` 等，登记表给）**默认只报不判**：**仓外状态不是仓的性质**
#        ⇒ 不许把它吃进仓内门禁的 `rc`；但**也不许假装干净** ⇒ 总行必须带 `ext=HITS(n)`。
#        `--strict-ext` 可让仓外命中进 `rc`（成对读数用）。**本件不改任何仓外脚本**。
#
#   ── 第三类 `D-G97`／`D-G42`（口径语义射程）：恒真谓词的**判别式** ────────────
#     现场："前提守卫恒真"有三种形态（`grep -q window`／`if !` 反向恒假／`case … *window*`
#     glob），而两次既有普查**都按关键词做** ⇒ 机械上看不见后两种。判别式 = 三条件合取：
#       **(a) 形状**（守卫是**文本测试**）、**(b) 承载**（被测串是**某命令的 stdout**）、
#       **(c) 中毒**（那条命令**失败时也会往那个归宿打含关键词的文案**）。
#     本类**只做报告**：`(a)`/`(b)` 机械可判；**`(c)` 是语义的、机械不可判** ⇒ **不许机器猜**，
#     逐格写 `poison=undecidable` 并计入 `semantic_undecidable`。唯一例外：命令在
#     **失败文案登记表**里（人工登记"失败时打什么、打到哪个归宿"）⇒ `(c)` 变成机械可判。
#     ⇒ `HYGIENE_SCOPE` **永不为 `PASS`**（只能 `REPORT`／`NOINFO`）⇒ **不许声称全域干净**。
#
# 【三态】`0 = PASS`｜`1 = FAIL`（逐处点名）｜`2 = NOINFO`（**算不出来 ⇒ 绝不是绿**，
#   也**不冒充红**；与 `nul-bytes-check.sh`／`fp-inputs-hygiene-check.sh`／
#   `shell-quote-trap-check.sh`／`pipefail-sigpipe-check.sh` 的三态**刻意同形**）。
#   ⚠️ `verify-all.sh` 对任何非 0 判 ❌ ⇒ "没声明"/"算不出"**永远不许当绿**（纪律 21/27/28）。
#
# 【总行的读法（**写死，不许放宽**）】`HYGIENE_TOOTH=PASS` **只**等于：
#   「登记表里的根集合对**机械可判部分**一致」∧「**判red 覆盖面**（仓内）里**截断写证据文件 = 0**」。
#   它**不等于**"全域干净"：`HYGIENE_SCOPE` 恒为 `REPORT`（含 `semantic_undecidable`），
#   仓外装置根**默认只报**（`ext=HITS(n)`），登记表外的一切两套根集合**未查**。
#   总行**必须**带 `scope=`／`semantic_undecidable=`／`ext=` 三格 —— 让"我到底没查什么"在同一行上可见。
#
# 【只读】生产路径**只读**：`open()` 只读、不动 mtime、不写被测树、不删任何文件。
#   唯一"执行"的东西 = 登记表里校验器的 **`--print-scan-roots`**（该模式**只读、不扫描、
#   不写盘、立即 `exit 0`**，是 `D-G91` 的派生入口）；**不跑**同步器本体（它要扫全树 ≈48 s）。
#   所有负极构造（注入/还原）**只在 `--selftest` 的私有 `TMPDIR` 沙箱里**做。
#
# 【成本】单趟 ≈ 0.5–2 s（现场 69 件 `.sh` ＋ 若干 `.md`）、零 `dotnet`、零世代成本
#   （不动九位/`GEN_KEYS`/`known-red.json`/不动被测树）。
#   ⚠️ 本件**不在** `build/close-wave.sh` 的 `fp_inputs()` 名单里（机械核：名单是**显式
#      `printf` 列举**，本件 0 命中）⇒ **新建本件不动 `inputs_fp`**；**接线**时若按仓内惯例
#      把判据件纳入覆盖面（纪律「改判据必须看得见」），那一改**会**动 `inputs_fp`
#      ⇒ 必须安排在 `IN_FP_0` 采样**之前**（见 `build/MilBridge/W119A-report.md` §6）。
#
# 用法：
#   hygiene-tooth.sh [--root DIR] [--strict-ext] [--list-sites] [--list-cases] [--debug-tmp]
#   hygiene-tooth.sh --selftest
# 环境（自测/沙箱用；生产不需要设）：
#   HYG_ROOT / HYG_PYTHON / HYG_ANCHORS=strict|off / HYG_MIN_FILES / HYG_MIN_PAIRS /
#   HYG_PAIRS_FILE / HYG_TMPDIR / HYG_KEEP_TMP / HYG_ST_* / HYG_FIXTURE_* / HYG_STRICT_EXT /
#   HYG_TEST_BLIND / HYG_TEST_NOSCOPE
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ⚠️ 必须**绝对**路径：`--selftest` 会 `cd` 进沙箱再以 `bash "$SELF"` 拉起子进程（相对路径在那里 rc=127）
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
REAL_ROOT="$(cd "$HERE/../../.." && pwd)"

ROOT="${HYG_ROOT:-$REAL_ROOT}"
PYBIN="${HYG_PYTHON:-python3}"
ANCHORS="${HYG_ANCHORS:-strict}"           # strict | off（off 只给 --selftest 的合成夹具用）
MIN_FILES="${HYG_MIN_FILES:-60}"           # 仓内**脚本体**件数下限（现场 69）
MIN_PAIRS="${HYG_MIN_PAIRS:-1}"            # 登记表对数下限
STRICT_EXT="${HYG_STRICT_EXT:-0}"          # 1 ⇒ 仓外装置根命中进 rc（默认只报）
BLIND="${HYG_TEST_BLIND:-0}"               # 只给自测：故意弄瞎证据扫描器
NOSCOPE="${HYG_TEST_NOSCOPE:-0}"           # 只给自测：故意不产出 SCOPE 行
KEEP_TMP="${HYG_KEEP_TMP:-0}"
TMPBASE="${HYG_TMPDIR:-${TMPDIR:-/tmp}}"
WANT_SITES=0; WANT_CASES=0; DEBUG_TMP=0
CITE_OVERRIDE=0            # `HYG_CITE_ML_ENV` 注入（**只给 --selftest**；见 strict 下的自检）

# ─────────────────────────────────────────────────────────────────────────────
# 【登记表 A】**根集合对**：`同步器|校验器|校验器默认根常量名|只读派生旗标`
#   口径（写死）：本件**只对这张表里的对负责**；表外的一切两套根集合**未查**。
# ─────────────────────────────────────────────────────────────────────────────
HYG_PAIRS_ML='
build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh|build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh|SCAN_ROOTS_DEFAULT|--print-scan-roots
'
# ─────────────────────────────────────────────────────────────────────────────
# 【登记表 B】**仓外装置根**（存在则扫；**默认只报不判**，见文件头）。
#   格式化：一行一个绝对路径，`$HOME` 会被展开。
# ─────────────────────────────────────────────────────────────────────────────
HYG_EXT_ROOTS_ML='
$HOME/w63a/bin
'
# ─────────────────────────────────────────────────────────────────────────────
# 【登记表 C】**命令 → 失败时打什么、打到哪个归宿**（`(c) 中毒` 的唯一机械依据）。
#   格式：`命令|归宿(stdout|stderr)|失败文案原文`（一行一条，可多条）。
#   ⚠️ 只登记**有现场证据**的：`xprop` 的失败文案打在 **stdout 且 `rc=0`** —— 这是 `D-G97`
#      逐字记录的事实（`D-G95`／`D-G97` 两处引用同一行原文）。**不许凭感觉登记**；
#      没登记的命令 ⇒ 那一格的 `(c)` = `undecidable`（**人读**，机器不许猜）。
# ─────────────────────────────────────────────────────────────────────────────
HYG_CMDSINK_ML='
xprop|stdout|_NET_SUPPORTING_WM_CHECK:  no such atom on any window.
'
# ─────────────────────────────────────────────────────────────────────────────
# 【登记表 D】口径射程里要**找**的命令名（不要求都在 C 里；不在 C 的 ⇒ 那一格不可判）。
# ─────────────────────────────────────────────────────────────────────────────
HYG_CMDS_ML='xprop xdpyinfo xwininfo xdotool xrandr wmctrl pgrep ps'
# ─────────────────────────────────────────────────────────────────────────────
# 【登记表 E】条件 ④「承重（被引用）」的两条机械路 —— 见 py_evidence 里的注释。
#   ④a **引用面**（相对 `$ROOT`；目录 ⇒ 其下全部 `*.md`）：缺陷册 ＋ `docs/**`
#        ——本仓"引用某个日志/进度文件"的书面面
#   ④b **登记承重证据根**（相对 `$ROOT`）：`build/MilBridge/arm-logs`（血案发生地，
#        且已有 `ARM-LOG-SHA` 牙看着）
# ─────────────────────────────────────────────────────────────────────────────
HYG_CITE_ML='
samples/WpfFeatureProbe/KNOWN-DEFECTS.md
docs
'
HYG_EVIDENCE_ROOTS='build/MilBridge/arm-logs'
# ─────────────────────────────────────────────────────────────────────────────
# 【登记表 F · 第四类】**原地写者登记表**（`件|写者|原地写字面量|rename字面量`）
#   判据：若**写者**件里出现「原地写字面量」⇒ 该件的写盘方式是**原地写**（`open(w)`/`>` 截断
#   同一个 inode ⇒ **硬链接会被写穿**）；若只出现「rename字面量」⇒ 是 temp＋rename（**解链**，
#   安全）；两者都没有 ⇒ `NOINFO unconfirmed`（**不许猜**）。
#   第四字段留空 = 不声明 rename 形态（那就只认原地写字面量）。
# ─────────────────────────────────────────────────────────────────────────────
HYG_WRITERS_ML='
build/MilBridge/known-red.json|build/MilBridge/tools/repin-generation.py|open(REG, "w"|os.replace(
# ⚠️ `defect-registry-declared.tsv` **不登记**：它的原地写来自调用方的 shell 重定向
#    （`--emit > 件`），**不在**写者件自身里 ⇒ 我在这件里抽不出形态 ⇒ 登记了就是编判词。
'
# ─────────────────────────────────────────────────────────────────────────────
# 【登记表 G · 第四类】**孪生件登记表**（`仓内件|夹具件|期望 sha16|来源`）
#   用途：给出「开工 sha16 == 收工 sha16」的**可复算样板**（逐对打印两面的 sha16/inode/nlink）。
#   前三条的期望值 = 车道 W120A 现场给的三个（**只读引用**）；第四条 = 本车道现场现算。
# ─────────────────────────────────────────────────────────────────────────────
HYG_TWINS_ML='
docs/PORT-SPEC.md|$HOME/w62a/negrepo/docs/PORT-SPEC.md|7f36186d68a18332|W120A
docs/INDEX.md|$HOME/w62a/negrepo/docs/INDEX.md|c36ed5fe2a5904a7|W120A
build/MilBridge/tools/defect-registry-declared.tsv|$HOME/w62a/negrepo/build/MilBridge/tools/defect-registry-declared.tsv|934a29ed9ab399ab|W120A
build/MilBridge/known-red.json|$HOME/w62a/negrepo/build/MilBridge/known-red.json|089b7324ba12e022|W119A现算
'
# ─────────────────────────────────────────────────────────────────────────────
# 【登记表 H · 第四类】**外部夹具根**（跨区同 inode 的"区"就是这些根）——口径写死。
# ─────────────────────────────────────────────────────────────────────────────
HYG_FIXTURE_ROOTS_ML='
$HOME/w62a/negrepo
$HOME/w113a/fixture
'
# ─────────────────────────────────────────────────────────────────────────────
# 【覆盖面声明（**唯一一份**）】脚本体扩展名（判）／文档体（只看不判）／证据名模式／排除目录
# ─────────────────────────────────────────────────────────────────────────────
HYG_CODE_EXTS='.sh .bash'                  # **进 rc**：可执行形态在这里面找
HYG_DOC_EXTS='.md'                         # **不进 rc**：只计数、可列出（"注释/文档命中另计"）
HYG_EVIDENCE_RE='(^|[^a-z])(log|logs|progress|evidence|trace|record|journal|dump|report|census|readings)([^a-z]|$)'
HYG_SKIPDIRS='.git obj bin .artifacts upstream node_modules __pycache__ .vs TestResults .dotnet'
# 登记表 E 的注入**口**（只给 `--selftest`）——必须放在 E 的声明**之后**，否则被它覆盖
[ -n "${HYG_CITE_ML_ENV:-}" ] && HYG_CITE_ML="$HYG_CITE_ML_ENV"
EVIDENCE_ROOTS="${HYG_EVIDENCE_ROOTS_ENV-$HYG_EVIDENCE_ROOTS}"
# 【登记表只许被"注入"，不许被"收窄"】`*_ENV` 是 `--selftest` 的夹具入**口**（合成表），
#   生产路径不设它 ⇒ 用的是上面写死的那份。⚠️ 这不是"可收窄的 `SCAN_ROOTS`"那族口子：
#   本件的判据是"登记表内的对必须一致"，**注入的表越大判得越多**（收紧方向）；
#   而"表被换成更小的"这件事会被 `MIN_PAIRS`／`ANCHORS=strict` 的锚挡住 ⇒ 不许静默缩射程。
[ -n "${HYG_PAIRS_ENV:-}" ] && HYG_PAIRS_ML="$HYG_PAIRS_ENV"
[ -n "${HYG_FIXTURE_ROOTS_ENV+x}" ] && HYG_FIXTURE_ROOTS_ML="$HYG_FIXTURE_ROOTS_ENV"
[ -n "${HYG_WRITERS_ENV:-}" ] && HYG_WRITERS_ML="$HYG_WRITERS_ENV"
[ -n "${HYG_TWINS_ENV:-}" ] && HYG_TWINS_ML="$HYG_TWINS_ENV"
HYG_WRITERS="$(printf '%s' "$HYG_WRITERS_ML" | sed '/^[[:space:]]*$/d')"
HYG_TWINS="$(printf '%s' "$HYG_TWINS_ML" | sed '/^[[:space:]]*$/d')"
HYG_FIXTURE_ROOTS="$(printf '%s' "$HYG_FIXTURE_ROOTS_ML" | sed "s#\$HOME#$HOME#g" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"
HYG_TWINS="$(printf '%s' "$HYG_TWINS" | sed "s#\$HOME#$HOME#g")"
[ -n "${HYG_EXT_ROOTS_ENV+x}" ] && HYG_EXT_ROOTS_ML="$HYG_EXT_ROOTS_ENV"
# 压平（bash 把换行当分隔符；压平后传 argv 更稳、打印也更整齐）
HYG_PAIRS="$(printf '%s' "$HYG_PAIRS_ML" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"
HYG_EXT_ROOTS_ML="$(printf '%s' "$HYG_EXT_ROOTS_ML" | sed "s#\\\$HOME#$HOME#g")"
HYG_CMDSINK="$(printf '%s' "$HYG_CMDSINK_ML" | sed '/^[[:space:]]*$/d')"
HYG_CMDS="$(printf '%s' "$HYG_CMDS_ML" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"

# ── 引用面展开（条件 ④a）：目录 ⇒ 其下 `*.md`（**排掉**各车道报告正文 ——
#    `build/MilBridge/*-report.md` 是"叙述"而不是"引用某个证据文件"的书面面）
expand_cite() {
  local r f p out=""
  for r in $HYG_CITE_ML; do
    [ -n "$r" ] || continue
    case "$r" in /*) p="$r";; *) p="$ROOT/$r";; esac
    if [ -d "$p" ]; then
      while IFS= read -r f; do
        case "$f" in */build/MilBridge/*-report.md) continue;; esac
        [ -n "$f" ] && out="$out $f"
      done < <(find "$p" -type f -name '*.md' -not -path '*/obj/*' -not -path '*/bin/*' 2>/dev/null | LC_ALL=C sort)
    elif [ -f "$p" ]; then
      out="$out $p"
    fi
  done
  printf '%s' "$out"
}
say() { printf '%s\n' "$*"; }
self_sha16() { sha256sum "$SELF" | cut -c1-16; }
usage() {
  cat <<'USAGE'
hygiene-tooth.sh —— 装置/口径卫生牙（TASK-0706：D-G91 根集合 ／ D-G96 证据保全 ／ D-G97 口径射程）
  hygiene-tooth.sh [--root DIR] [--strict-ext] [--list-sites] [--list-cases] [--debug-tmp]
  hygiene-tooth.sh --selftest
三态：rc=0 PASS ／ rc=1 FAIL（逐处点名）／ rc=2 NOINFO（**不是绿**）
USAGE
}

# ── 小工具 ──────────────────────────────────────────────────────────────────
strip_comment() { printf '%s' "$1" | sed -E 's/(^|[ \t])#.*$//'; }   # 去整行/行尾注释（近似，够用）
norm_roots() {   # $1=冒号分隔根串 ⇒ 集合归一（realpath -m ＋ 排序去重 ＋ 冒号连接）
  local r out=""
  IFS=:; for r in $1; do [ -n "$r" ] && out="$out$(realpath -m -- "$r" 2>/dev/null)
"; done; IFS=$' \t\n'
  printf '%s' "$out" | LC_ALL=C sort -u | paste -sd: -
}
strip_vars() {   # 去掉 $VAR/${VAR} 引用，**保留 `${NAME:-DEFAULT}` 的 DEFAULT 字面部分**
  local s="$1"
  s="$(printf '%s' "$s" | sed -E 's/\$\{[A-Za-z_][A-Za-z0-9_]*:-([^}]*)\}/\1/g')"
  s="$(printf '%s' "$s" | sed -E 's/\$\{[A-Za-z_][A-Za-z0-9_]*\}//g; s/\$[A-Za-z_][A-Za-z0-9_]*//g')"
  printf '%s' "$s"
}
abspath() {   # $1=相对（按 $ROOT 解析）或绝对路径 ⇒ 绝对路径（登记表两种写法都收）
  case "$1" in /*) printf '%s' "$1";; *) printf '%s' "$ROOT/$1";; esac
}
code_lines() {   # $1=文件 ⇒ 打印 `行号<TAB>剥注释后的正文`（只留**有非空白正文**的行）
  local n=0 ln c t
  while IFS= read -r ln; do
    n=$((n + 1))
    c="$(strip_comment "$ln")"; t="${c//[[:space:]]/}"
    [ -n "$t" ] && printf '%s\t%s\n' "$n" "$c"
  done < "$1"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 第一类：根集合一致性
# ═══════════════════════════════════════════════════════════════════════════════
R_STATE=''; R_PAIRS_N=0; R_ROWS=''; R_DETAIL=''
check_roots() {
  R_STATE=PASS; R_PAIRS_N=0; R_ROWS=''; R_DETAIL=''
  local pair sync chk cvar pflag
  for pair in $HYG_PAIRS; do
    R_PAIRS_N=$((R_PAIRS_N + 1))
    IFS='|' read -r sync chk cvar pflag <<< "$pair"
    local sp cp_; sp="$(abspath "$sync")"; cp_="$(abspath "$chk")"
    local st=PASS why='' setA='' setB=''
    if [ ! -f "$sp" ] || [ ! -f "$cp_" ]; then
      R_ROWS="${R_ROWS}HYGIENE_ROOTS_PAIR id=$chk state=NOINFO why=pair-file-missing sync=$sync exist_sync=$([ -f "$sp" ] && echo 1 || echo 0) exist_check=$([ -f "$cp_" ] && echo 1 || echo 0)"$'\n'
      R_STATE=NOINFO; [ -z "$R_DETAIL" ] && R_DETAIL="pair-file-missing:$chk"
      continue
    fi
    # ── R1：校验器的默认根常量可静态抽出 ──
    local cline
    cline="$(grep -nE "^[[:space:]]*${cvar}=" "$cp_" | sed -n '1p')"
    if [ -z "$cline" ]; then
      R_ROWS="${R_ROWS}HYGIENE_ROOTS_PAIR id=$chk state=NOINFO why=R1-const-not-found const=$cvar"$'\n'
      R_STATE=NOINFO; [ -z "$R_DETAIL" ] && R_DETAIL="R1-const-not-found:$chk"
      continue
    fi
    local raw="${cline#*:}"; raw="${raw#*=}"
    raw="$(printf '%s' "$raw" | sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//')"
    raw="${raw//\$\{REPO\}/$ROOT}"; raw="${raw//\$REPO/$ROOT}"
    setA="$(norm_roots "$raw")"
    # ── R2：`--print-scan-roots` 吐出的集合 == 静态抽出的集合（**集合比较**）──
    local dyn drc
    dyn="$(AUTH_ROOT="$ROOT" bash "$cp_" "$pflag" 2>/dev/null)"; drc=$?
    if [ "$drc" != 0 ] || [ -z "$dyn" ]; then
      R_ROWS="${R_ROWS}HYGIENE_ROOTS_PAIR id=$chk state=NOINFO why=R2-print-roots-failed rc=$drc flag=$pflag"$'\n'
      R_STATE=NOINFO; [ -z "$R_DETAIL" ] && R_DETAIL="R2-print-roots-failed:$chk"
      continue
    fi
    setB="$(norm_roots "$dyn")"
    if [ "$setA" != "$setB" ]; then
      st=FAIL; why="R2-decl-vs-print-diverge"
    fi
    # ── R3：同步器**没有自写默认根字面量** ──
    local r3n=0 r3bad=''
    local n ln c rhs lit
    while IFS=$'\t' read -r n c; do
      case "$c" in *SCAN_ROOTS=*) ;; *) continue;; esac
      rhs="${c#*SCAN_ROOTS=}"; rhs="${rhs%%[[:space:]]*}"
      case "$rhs" in
        \"*\") rhs="${rhs#\"}"; rhs="${rhs%\"}";;
        \'*\') rhs="${rhs#\'}"; rhs="${rhs%\'}";;
      esac
      lit="$(strip_vars "$rhs")"
      case "$lit" in
        */*|*:*) r3n=$((r3n + 1)); r3bad="$r3bad $n:$rhs";;
      esac
    done < <(code_lines "$sp")
    if [ "$r3n" != 0 ]; then
      st=FAIL; why="${why:+$why,}R3-self-written-default"
    fi
    # ── R4：同步器**含派生调用** ──
    local r4=0
    while IFS=$'\t' read -r n c; do
      case "$c" in *"$pflag"*) r4=1;; esac
    done < <(code_lines "$sp")
    [ "$r4" = 1 ] || { st=FAIL; why="${why:+$why,}R4-derivation-missing"; }
    # ── R5：收窄拒绝存在，且**发生在任何汇总打印之前** ──
    local ln_mis=0 ln_exit=0 ln_sum=0
    while IFS=$'\t' read -r n c; do
      case "$c" in *MISMATCH*) [ "$ln_mis" = 0 ] && ln_mis="$n";; esac
      case "$c" in *"exit 2"*) [ "$ln_exit" = 0 ] && ln_exit="$n";; esac
      case "$c" in *'STALE='*|*'APPSYNC-REFRESH='*) [ "$ln_sum" = 0 ] && ln_sum="$n";; esac
    done < <(code_lines "$sp")
    if [ "$ln_mis" = 0 ] || [ "$ln_exit" = 0 ]; then
      st=FAIL; why="${why:+$why,}R5-narrow-guard-missing"
    elif [ "$ln_sum" != 0 ] && [ "$ln_exit" -gt "$ln_sum" ]; then
      st=FAIL; why="${why:+$why,}R5-narrow-guard-after-summary"
    fi
    R_ROWS="${R_ROWS}HYGIENE_ROOTS_PAIR id=$chk state=$st why=${why:-ok} const=$cvar flag=$pflag setA='$setA' setB='$setB' sums_at=$ln_sum guard_exit_at=$ln_exit"$'\n'
    case "$st" in
      FAIL) R_STATE=FAIL; R_DETAIL="${R_DETAIL:+$R_DETAIL;}$why($chk) $r3bad";;
    esac
  done
  if [ "$R_PAIRS_N" -lt "$MIN_PAIRS" ]; then
    R_STATE=NOINFO; R_DETAIL="too-few-pairs n=$R_PAIRS_N min=$MIN_PAIRS"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 第二类：证据保全（python 只报事实、不定态）
# ═══════════════════════════════════════════════════════════════════════════════
py_evidence() {   # $1=roots 规格(`mode|path;…`) $2=out.tsv $3=err.txt
  : > "$2"; : > "$3"
  HYG_EV_ROOTS="$1" HYG_EV_CODE_EXTS="$HYG_CODE_EXTS" HYG_EV_DOC_EXTS="$HYG_DOC_EXTS" \
  HYG_EV_NAME_RE="$HYG_EVIDENCE_RE" HYG_EV_SKIPDIRS="$HYG_SKIPDIRS" \
  HYG_EV_SELF="$SELF" HYG_EV_BLIND="$BLIND" HYG_EV_ROOT="$ROOT" \
  HYG_EV_CITE="$CITE_SURFACE" HYG_EV_EVROOTS="$EVIDENCE_ROOTS" \
    "$PYBIN" - > "$2" 2> "$3" <<'PY_HYG_EV'
import os, re, sys

roots = []
for spec in os.environ['HYG_EV_ROOTS'].split(';'):
    spec = spec.strip()
    if not spec:
        continue
    mode, _, path = spec.partition('|')
    if path:
        roots.append((mode, os.path.realpath(path)))
code_exts = set(os.environ['HYG_EV_CODE_EXTS'].split())
doc_exts = set(os.environ['HYG_EV_DOC_EXTS'].split())
name_re = re.compile(os.environ['HYG_EV_NAME_RE'])
skipdirs = set(os.environ['HYG_EV_SKIPDIRS'].split())
self_path = os.path.realpath(os.environ['HYG_EV_SELF'])
blind = os.environ['HYG_EV_BLIND'] == '1'
repo_root = os.path.realpath(os.environ['HYG_EV_ROOT'])
ev_roots = [os.path.realpath(os.path.join(repo_root, r))
            for r in os.environ['HYG_EV_EVROOTS'].split() if r]

# ── 条件 ④「承重（被引用）」的**机械依据**（两条路，任一成立即可）──────────────
#   ④a **引用面**：目标的基名（或解析后的完整路径）在下面这些文件里**以字面量出现过**
#       —— 那是本仓"引用某个日志/进度文件"的**书面面**（缺陷册 ＋ `docs/**`）。
#   ④b **登记承重证据根**：解析后的路径落在登记的证据根下（`build/MilBridge/arm-logs`：
#       它正是"血案"发生地，且已有 `ARM-LOG-SHA` 牙看着）。
#   ⚠️ 这一条是**加严**：多一个合取项 ⇒ 命中更少、但每一条更确定落在 `D-G96` 那一族。
#      不满足 ④ 的形态**不判红、但必须可见**（`NOTCITED`，逐条点名）—— 不许静默丢掉。
cite_text = ''
cite_files = 0
for c in os.environ['HYG_EV_CITE'].split():
    if not c:
        continue
    try:
        with open(c, 'r', encoding='utf-8', errors='replace') as fh:
            cite_text += fh.read() + '\n'
        cite_files += 1
    except OSError:
        pass

def is_loadbearing(resolved, base):
    if base and base in cite_text:
        return True, 'cited-basename'
    if resolved and not resolved.startswith('<') and resolved in cite_text:
        return True, 'cited-fullpath'
    if resolved and not resolved.startswith('<'):
        cand = resolved if os.path.isabs(resolved) else os.path.join(repo_root, resolved)
        cand = os.path.normpath(cand)
        for er in ev_roots:
            if cand == er or cand.startswith(er + os.sep):
                return True, 'under-evidence-root'
    return False, 'not-cited'

# 环境变量分类：① 跨趟固定（可当字面量）② 每趟不同（⇒ 目标不固定）
ENV_FIXED = {'HOME': '<HOME>', 'PWD': '<PWD>', 'USER': '<USER>', 'LOGNAME': '<LOGNAME>'}
ENV_VOLATILE = {'TMPDIR', 'RANDOM', 'PPID', 'BASHPID', 'SECONDS', 'LINENO'}

# 截断写形态（⚠️ `: >>`/`>>` 是**追加**，不是本类；用 `(?!>)` 排掉）
SITE_RE = [
    ('colon',    re.compile(r'(?:^|[;&|]\s*|\)\s*)\s*:\s*>(?!>)\s*(\S+)')),
    ('true',     re.compile(r'(?:^|[;&|]\s*)\s*true\s+>(?!>)\s*(\S+)')),
    ('bare',     re.compile(r'^\s*>(?!>)\s*(\S+)')),
    ('truncate', re.compile(r'\btruncate\s+(?:-s\s+0|--size=0)\s+(\S+)')),
]
ASSIGN_RE = re.compile(r'^\s*(?:local\s+|declare\s+|readonly\s+|export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$')
SELFTEST_RE = re.compile(r'^run_selftest\s*\(\)')

def emit(*a):
    sys.stdout.write('\t'.join(str(x) for x in a) + '\n')

def load(path):
    with open(path, 'r', encoding='utf-8', errors='replace') as fh:
        return fh.read().split('\n')

def is_comment(line):
    return line.lstrip().startswith('#')

def unquote(s):
    t = s.strip()
    if len(t) >= 2 and t[0] == t[-1] and t[0] in '"\'':
        return t[1:-1]
    return t

VAR_RE = re.compile(r'\$\{([A-Za-z_][A-Za-z0-9_]*)(:-([^}]*))?\}|\$([A-Za-z_][A-Za-z0-9_]*)')

def resolve_expr(expr, varmap, depth=0, seen=None):
    """把表达式里的 `$VAR`/`${VAR}`/`${VAR:-默认}` 用**件内赋值**替换；返回 (文本, 状态)
       状态 ∈ fixed | volatile | unresolved。
    ⚠️【现场踩过的坑，写死在这里】首版用 `\$\{?NAME\}?` ＋ `str.replace` 逐轮替换：
      `"${OUT:-${R_GATE_OUT:-/tmp/r-gate-$(date +%m%d-%H%M%S)-$$}}"` 这种**嵌套默认值**
      会让 token 只吃掉 `${OUT` 而把 `:-…}` 留在原地 ⇒ 下一轮又展开一遍 ⇒ **指数膨胀**
      （现场实测一条 SITE 行被撑到 **72,394 字符**）。现在改成**单趟扫描 ＋ 递归解析默认值
      ＋ seen 去环 ＋ 4 KiB 体积守卫**；超限直接判 `unresolved`（= 算不出来，不判红）。
       层数上限 3、体积上限 4096 都是**故意写死**的：它们只会让更多站点落进 NOTFIXED
      （不判红的一档），**不会**让本该红的站点变绿。"""
    if seen is None:
        seen = set()
    if depth > 3:
        return expr, 'unresolved'
    out = []
    pos = 0
    for m in VAR_RE.finditer(expr):
        out.append(expr[pos:m.start()])
        pos = m.end()
        if m.group(1) is not None:
            name, default = m.group(1), m.group(3)
        else:
            name, default = m.group(4), None
        if name in ENV_FIXED:
            out.append(ENV_FIXED[name])
            continue
        if name in ENV_VOLATILE:
            out.append('<%s>' % name)
            continue
        if name in varmap and name not in seen:
            sub, _st = resolve_expr(unquote(varmap[name]), varmap, depth + 1, seen | {name})
            out.append(sub)
            continue
        if default is not None:
            sub, _st = resolve_expr(default, varmap, depth + 1, seen | {name})
            out.append(sub)
            continue
        out.append(m.group(0))
    out.append(expr[pos:])
    res = unquote(''.join(out))
    if len(res) > 4096:
        return res[:4096], 'unresolved'          # ⚠️ 体积守卫：超限 = 算不出来
    if re.search(r'\$\$|\$RANDOM|\$\(date|\bmktemp\b|<TMPDIR>', res):
        return res, 'volatile'
    if '$' in res:
        return res, 'unresolved'
    return res, 'fixed'

def strip_token(tok):
    t = tok.strip()
    if len(t) >= 2 and t[0] == t[-1] and t[0] in '"\'':
        t = t[1:-1]
    return t

rows = 0
n_code = 0
n_ext = 0
n_doc = 0
for mode, root in roots:
    if not os.path.isdir(root):
        emit('K', 'meta', 'root_missing', root)
        continue
    for r, dirs, fs in os.walk(root):
        dirs[:] = [d for d in dirs if d not in skipdirs]
        for f in sorted(fs):
            ext = os.path.splitext(f)[1].lower()
            if ext not in code_exts and ext not in doc_exts:
                continue
            p = os.path.join(r, f)
            rel = os.path.relpath(p, root)
            try:
                lines = load(p)
            except OSError:
                emit('K', 'meta', 'read_error', rel)
                continue
            if ext in code_exts:
                if mode == 'judge':
                    n_code += 1
                else:
                    n_ext += 1
            else:
                n_doc += 1
            is_self = (os.path.realpath(p) == self_path)
            st_start = 0
            for i, ln in enumerate(lines, 1):
                if SELFTEST_RE.match(ln):
                    st_start = i
                    break
            varmap = {}
            for ln in lines:
                m = ASSIGN_RE.match(ln)
                if m and m.group(1) not in varmap:
                    varmap[m.group(1)] = m.group(2)
            for i, ln in enumerate(lines, 1):
                hit = None
                for form, rx in SITE_RE:
                    m = rx.search(ln)
                    if m:
                        hit = (form, m.group(1))
                        break
                if not hit:
                    continue
                form, tok = hit
                tgt = strip_token(tok)
                if form == 'bare' and not re.search(r'[$/.]', tgt):
                    continue          # `> 文字` 是 markdown 引用块，不是重定向（噪声过滤）
                if ext in doc_exts or is_comment(ln):
                    cls, reason, resolved = 'DOC', 'comment-or-doc', tgt
                elif is_self:
                    cls, reason, resolved = 'SELF', 'instrument-itself', tgt
                elif st_start and i > st_start:
                    cls, reason, resolved = 'SELFTEST', 'inside-own-selftest-region', tgt
                elif blind:
                    cls, reason, resolved = 'BLIND', 'scanner-blinded', tgt
                else:
                    resolved, st = resolve_expr(tgt, varmap)
                    if st == 'volatile':
                        cls, reason = 'NOTFIXED', 'target-per-run(volatile)'
                    elif st == 'unresolved':
                        cls, reason = 'NOTFIXED', 'target-not-statically-resolved'
                    else:
                        base = os.path.basename(resolved.rstrip('/')) or resolved
                        if not name_re.search(base):
                            cls, reason = 'NOTNAME', 'fixed-but-name-not-evidence'
                        else:
                            lb, lwhy = is_loadbearing(resolved, base)
                            if lb:
                                cls, reason = 'EXEC_HIT', 'truncate-fixed-loadbearing-evidence:' + lwhy
                            else:
                                cls, reason = 'NOTCITED', 'fixed-evidence-name-but-not-cited:' + lwhy
                rows += 1
                emit('SITE', mode, rel, i, form, cls, reason, resolved, ln.strip()[:220])
    emit('K', 'meta', 'root_done', root)
emit('K', 'meta', 'blind', 1 if blind else 0)
emit('K', 'meta', 'code_files', n_code)
emit('K', 'meta', 'ext_files', n_ext)
emit('K', 'meta', 'doc_files', n_doc)
emit('K', 'meta', 'cite_files', cite_files)
emit('K', 'meta', 'rows', rows)
PY_HYG_EV
}

parse_evidence() {   # $1=tsv ⇒ 结果写进全局 E_*
  E_ROWS=0; E_FILES=0; E_EXTFILES=0; E_DOCFILES=0; E_CITEFILES=0
  E_HIT=0; E_NOTNAME=0; E_NOTFIXED=0; E_NOTCITED=0; E_SELFTEST=0; E_SELF=0; E_DOC=0
  E_BLIND=0; E_BLINDMETA=0; E_EXT_HIT=0; E_EXT_OTHER=0; E_EXT_NOTCITED=0; E_ROOTMISS=''; E_READERR=0
  E_HITROWS=''; E_DIAGROWS=''; E_EXTHITROWS=''; E_NCROWS=''; E_EXTNCROWS=''
  local tag a b c d e f g h
  while IFS=$'\t' read -r tag a b c d e f g h; do
    case "$tag" in
      K) case "$a" in
           meta) case "$b" in
                   code_files) E_FILES="$c";;
                   ext_files)  E_EXTFILES="$c";;
                   doc_files)  E_DOCFILES="$c";;
                   cite_files) E_CITEFILES="$c";;
                   blind)      E_BLINDMETA="$c";;
                   rows)       E_ROWS="$c";;
                   root_missing) E_ROOTMISS="${E_ROOTMISS}$c ";;
                   read_error)   E_READERR=$((E_READERR + 1));;
                 esac;;
         esac;;
      SITE)
        # a=mode b=rel c=line d=form e=cls f=reason g=resolved h=raw
        case "$a" in
          judge)
            case "$e" in
              EXEC_HIT) E_HIT=$((E_HIT + 1)); E_HITROWS="${E_HITROWS}${b}:${c}|${d}|${g}|${h}|${f}"$'\n';;
              NOTNAME)  E_NOTNAME=$((E_NOTNAME + 1));;
              NOTCITED) E_NOTCITED=$((E_NOTCITED + 1)); E_NCROWS="${E_NCROWS}${b}:${c}|${d}|${g}|${h}"$'\n';;
              NOTFIXED) E_NOTFIXED=$((E_NOTFIXED + 1)); E_DIAGROWS="${E_DIAGROWS}NOTFIXED(${f})|${b}:${c}|${g}|${h}"$'\n';;
              SELFTEST) E_SELFTEST=$((E_SELFTEST + 1));;
              SELF)     E_SELF=$((E_SELF + 1));;
              DOC)      E_DOC=$((E_DOC + 1));;
              BLIND)    E_BLIND=$((E_BLIND + 1));;
            esac;;
          report)
            case "$e" in
              EXEC_HIT) E_EXT_HIT=$((E_EXT_HIT + 1)); E_EXTHITROWS="${E_EXTHITROWS}${b}:${c}|${d}|${g}|${h}|${f}"$'\n';;
              NOTCITED) E_EXT_NOTCITED=$((E_EXT_NOTCITED + 1)); E_EXTNCROWS="${E_EXTNCROWS}${b}:${c}|${d}|${g}|${h}"$'\n';;
              NOTNAME|NOTFIXED|DOC|SELFTEST|SELF) E_EXT_OTHER=$((E_EXT_OTHER + 1));;
              BLIND) E_BLIND=$((E_BLIND + 1));;
            esac;;
        esac;;
    esac
  done < "$1"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 第三类：口径语义射程（审计报告）
# ═══════════════════════════════════════════════════════════════════════════════
py_scope() {   # $1=roots 规格 $2=out.tsv $3=err.txt
  : > "$2"; : > "$3"
  HYG_SC_ROOTS="$1" HYG_SC_CODE_EXTS="$HYG_CODE_EXTS" HYG_SC_SKIPDIRS="$HYG_SKIPDIRS" \
  HYG_SC_CMDS="$HYG_CMDS" HYG_SC_SINK="$HYG_CMDSINK" HYG_SC_SELF="$SELF" \
  HYG_SC_OFF="$NOSCOPE" \
    "$PYBIN" - > "$2" 2> "$3" <<'PY_HYG_SC'
import os, re, sys

roots = [os.path.realpath(s.strip()) for s in os.environ['HYG_SC_ROOTS'].split(';') if s.strip()]
code_exts = set(os.environ['HYG_SC_CODE_EXTS'].split())
skipdirs = set(os.environ['HYG_SC_SKIPDIRS'].split())
cmds = set(os.environ['HYG_SC_CMDS'].split())
self_path = os.path.realpath(os.environ['HYG_SC_SELF'])
off = os.environ['HYG_SC_OFF'] == '1'
# 失败文案登记表：命令 → (归宿, [失败文案…])
sink = {}
for ln in os.environ['HYG_SC_SINK'].split('\n'):
    ln = ln.strip()
    if not ln:
        continue
    c, _, rest = ln.partition('|')
    s, _, text = rest.partition('|')
    sink.setdefault(c.strip(), []).append((s.strip(), text))

ASSIGN_RE = re.compile(r'^\s*(?:local\s+|declare\s+|export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$')
CAP_RE = re.compile(r'([A-Za-z_][A-Za-z0-9_]*)=\"?\$\(([^()]*(?:\([^()]*\)[^()]*)*)\)')
SELFTEST_RE = re.compile(r'^run_selftest\s*\(\)')
LEX = set('*?[]()|\\^$+{}.')

def emit(*a):
    sys.stdout.write('\t'.join(str(x) for x in a) + '\n')

def load(path):
    with open(path, 'r', encoding='utf-8', errors='replace') as fh:
        return fh.read().split('\n')

def cmd_of_token(tok, varmap):
    """把一个命令词解析成**命令名**：字面量 / `"$VAR"`（查件内 `VAR=…:-xprop` 的默认值）"""
    t = tok.strip()
    if len(t) >= 2 and t[0] == t[-1] and t[0] in '"\'':
        t = t[1:-1]
    t = t.strip('"\'')
    if t.startswith('$'):
        name = t.lstrip('${').rstrip('}')
        rhs = varmap.get(name, '')
        m = re.search(r':-([A-Za-z][A-Za-z0-9_.-]*)', rhs)
        if m:
            return m.group(1)
        m = re.search(r'^[^$]*\b([a-z][a-z0-9_.-]{1,15})\b', rhs)
        return m.group(1) if m else ''
    return t if re.fullmatch(r'[A-Za-z][A-Za-z0-9_.-]*', t) else ''

def first_cmd(subst, varmap):
    s = subst.strip()
    for _ in range(3):
        m = re.match(r'(timeout\s+\S+|env|command|sudo|nice)\s+', s)
        if not m:
            break
        s = s[m.end():]
    s = s.strip()
    m = re.match(r'("[^"]*"|\'[^\']*\'|\S+)', s)
    return cmd_of_token(m.group(1), varmap) if m else ''

def keywords_of(pattern):
    """从 glob 或 regex 里抽"关键词" = 长度≥2 的字母/数字/空格/引号/等号连片"""
    p = pattern.strip()
    if len(p) >= 2 and p[0] == p[-1] and p[0] in '"\'':
        p = p[1:-1]
    # ⚠️ 关键词抽取的**取舍**（写死，别改松）：先取长度 ≥2 的连片（`window`／`= "`／
    #   `EVID popup id=` 都在这一档）；**只有**在抽不出时，才退到**符号**单字（`=`／`"`）——
    #   绝不退到**字母数字**单字（那样任何失败文案里的一个字母都会把它判成中毒 ⇒ 假红）。
    out = []
    for r in re.findall(r'[A-Za-z0-9_ =":#-]{2,}', p):
        r = r.strip()
        if r and r not in out:
            out.append(r)
    if not out:
        out = [c for c in re.findall(r'[=:\"#-]', p)]
    return out

def poison_of(cmd, shape, kws):
    """(c) 中毒：只有在**失败文案登记表**里才有机械答案；否则 undecidable"""
    if cmd not in sink:
        return 'undecidable', 'cmd-not-in-failure-registry'
    entries = sink[cmd]
    if shape == 'nonempty':
        for s, _t in entries:
            if s == 'stdout':
                return 'yes', 'nonempty-test-on-command-whose-failure-text-goes-to-stdout'
        return 'no', 'failure-text-not-on-stdout'
    for kw in kws:
        for _s, text in entries:
            if kw and kw in text:
                return 'yes', 'keyword-present-in-recorded-failure-text'
    return 'no', 'keyword-absent-from-recorded-failure-text'

ncase = 0; ndec = 0; nund = 0; nst = 0; npoison = 0; nderived = 0
cid = 0
for root in roots:
    if not os.path.isdir(root):
        continue
    for r, dirs, fs in os.walk(root):
        dirs[:] = [d for d in dirs if d not in skipdirs]
        for f in sorted(fs):
            if os.path.splitext(f)[1].lower() not in code_exts:
                continue
            p = os.path.join(r, f)
            if os.path.realpath(p) == self_path:
                continue
            rel = os.path.relpath(p, root)
            try:
                lines = load(p)
            except OSError:
                continue
            st_start = 0
            for i, ln in enumerate(lines, 1):
                if SELFTEST_RE.match(ln):
                    st_start = i
                    break
            varmap = {}
            for ln in lines:
                m = ASSIGN_RE.match(ln)
                if m and m.group(1) not in varmap:
                    varmap[m.group(1)] = m.group(2)

            # ① 捕获行：VAR="$(cmd …)"（含 `timeout`/`env` 前缀与 `"$VARBIN"` 间接）
            caps = []            # (var, lineno, cmd, derived(bool), merged_stderr(bool))
            for i, ln in enumerate(lines, 1):
                for m in CAP_RE.finditer(ln):
                    var, subst = m.group(1), m.group(2)
                    cmd = first_cmd(subst, varmap)
                    if cmd not in cmds:
                        continue
                    caps.append((var, i, cmd, '|' in subst, '2>&1' in subst))
            # ② 谓词行：后文对 $VAR 的**关键词文本测试**
            for (var, cl, cmd, derived, merged) in caps:
                for i in range(cl, len(lines) + 1):
                    ln = lines[i - 1]
                    if i != cl and re.match(r'\s*(?:local\s+)?%s=' % re.escape(var), ln):
                        break
                    if ('$%s' % var) not in ln:
                        continue
                    shape = ''; kws = []; pat = ''
                    mc = re.search(r'\bcase\s+"?\$\{?' + re.escape(var) + r'\}?"?\s+in\s+(.*)', ln)
                    if mc:
                        for pm in re.finditer(r'\'([^\']*)\'|"([^"]*)"|([^)\s]+)\)', mc.group(1)):
                            pat = pm.group(1) or pm.group(2) or pm.group(3) or ''
                            kws = keywords_of(pat)
                            if kws:
                                shape = 'glob'
                                break
                    if not shape:
                        mg = re.search(r'grep\s+(-[A-Za-z]+)?\s*(\'[^\']*\'|"[^"]*"|\S+)', ln)
                        if mg:
                            pat = mg.group(2)
                            kws = keywords_of(pat)
                            if kws:
                                shape = 'grep'
                                kws = kws[:3]
                    if not shape:
                        if re.search(r'\[\s+-n\s+"?\$\{?' + re.escape(var) + r'\}?"?\s*\]', ln):
                            shape = 'nonempty'; kws = []
                    if not shape:
                        continue
                    cid += 1
                    bearing = 'no' if derived else 'yes'
                    disp = 'SELFTEST' if (st_start and i > st_start) else 'JUDGE'
                    pz, why = poison_of(cmd, shape, kws)
                    if disp == 'JUDGE':
                        ncase += 1
                        if pz == 'undecidable':
                            nund += 1
                        else:
                            ndec += 1
                        if pz == 'yes':
                            npoison += 1
                    else:
                        nst += 1
                    emit('CASE', cid, rel, i, cmd, shape, bearing, sink.get(cmd, [('-', '-')])[0][0],
                         pz, ','.join(kws) or '(none)', disp,
                         'capture_line=%d derived=%d merged_stderr=%d %s' % (cl, 1 if derived else 0,
                                                                            1 if merged else 0, why),
                         pat.replace('\t', ' ')[:80])
            # ③ 未计入的"派生值上的文本测试"（**没扫什么**的机器读数）
            for i, ln in enumerate(lines, 1):
                if re.search(r'grep\s+-[A-Za-z]*[qF]\w*\s', ln) and re.search(r'\$\(', ln):
                    nderived += 1
emit('K', 'meta', 'cases', 0 if off else ncase)
emit('K', 'meta', 'decided', 0 if off else ndec)
emit('K', 'meta', 'undecidable', 0 if off else nund)
emit('K', 'meta', 'selftest_excluded', nst)
emit('K', 'meta', 'poison_yes', 0 if off else npoison)
emit('K', 'meta', 'derived_pred_unchecked', nderived)
PY_HYG_SC
}

parse_scope() {   # $1=tsv ⇒ 结果写进全局 S_*
  S_CASES=0; S_DEC=0; S_UND=0; S_ST=0; S_POISON=0; S_DERIVED=0
  S_CASEROWS=''; S_POISONROWS=''
  local tag a b c d e f g h i j k
  while IFS=$'\t' read -r tag a b c d e f g h i j k; do
    case "$tag" in
      K) case "$a" in
           meta) case "$b" in
                   cases) S_CASES="$c";; decided) S_DEC="$c";; undecidable) S_UND="$c";;
                   selftest_excluded) S_ST="$c";; poison_yes) S_POISON="$c";;
                   derived_pred_unchecked) S_DERIVED="$c";;
                 esac;;
         esac;;
      CASE)
        # a=id b=rel c=line d=cmd e=shape f=bearing g=sink h=poison i=kws j=disp k=note/reason
        S_CASEROWS="${S_CASEROWS}${a}|${b}|${c}|${d}|${e}|${f}|${g}|${h}|${i}|${j}"$'\n'
        if [ "$h" = yes ] && [ "$f" = yes ] && [ "$j" = JUDGE ]; then
          S_POISONROWS="${S_POISONROWS}${b}:${c}|cmd=${d}|shape=${e}|kws=${i}|poison=${h}|${k}"$'\n'
        fi;;
    esac
  done < "$1"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 第四类：硬链接 / 跨区同 inode（`W120A` 新发现；方向与 `D-G80` **相反**）
#   历史血案（`D-G80` 族）是"**读到旧件**"；本条是"**写坏别人的**"：
#   `$R` 的件与**仓外夹具**（`$HOME/**`）**同 inode**（硬链接）⇒ 任何**原地写**
#   （`>`／`: >`／`open(w)`／`sed -i`）都会**写穿**夹具 ⇒ 改掉别的车道的**负控夹具**。
#   三态：跨区同 inode **且该件会被原地写** ⇒ `FAIL`（点名）；只 `links>1` 但无跨区 ⇒ **报告行**；
#        查不动（`stat` 不可用／夹具根不存在／原地写形态抽不出）⇒ `NOINFO`（不许冒绿）。
#   ⚠️ 本类**不修任何东西**：解链/改写盘是各件写者的活（其余车道的写域）。
# ═══════════════════════════════════════════════════════════════════════════════
py_inode() {   # $1=仓根 $2=夹具根串 $3=写者登记表 $4=孪生登记表 $5=out.tsv $6=err.txt
  : > "$6"
  HYG_IN_ROOT="$1" HYG_IN_FIX="$2" HYG_IN_WRITERS="$3" HYG_IN_TWINS="$4" \
  HYG_IN_SKIPDIRS="$HYG_SKIPDIRS" \
    "$PYBIN" - > "$5" 2> "$6" <<'PY_HYG_IN'
import hashlib, os, sys

root = os.path.realpath(os.environ['HYG_IN_ROOT'])
fix_roots = [os.path.realpath(p) for p in os.environ['HYG_IN_FIX'].split() if p]
skipdirs = set(os.environ['HYG_IN_SKIPDIRS'].split())
writers = [l.split('|') for l in os.environ['HYG_IN_WRITERS'].split('\n') if l.strip()]
twins = [l.split('|') for l in os.environ['HYG_IN_TWINS'].split('\n') if l.strip()]

def emit(*a):
    sys.stdout.write('\t'.join(str(x) for x in a) + '\n')

def sha16(path):
    try:
        h = hashlib.sha256()
        with open(path, 'rb') as fh:
            for b in iter(lambda: fh.read(1 << 20), b''):
                h.update(b)
        return h.hexdigest()[:16]
    except OSError:
        return '<missing>'

# ── ① 仓内 `links>1` 名单（全件，除声明排除目录）────────────────────────────────
repo_ml = {}          # (dev,ino) -> [rel…]
n_repo_files = 0
for r, dirs, fs in os.walk(root):
    dirs[:] = [d for d in dirs if d not in skipdirs]
    for f in fs:
        p = os.path.join(r, f)
        try:
            st = os.stat(p, follow_symlinks=False)
        except OSError:
            emit('K', 'meta', 'stat_error', os.path.relpath(p, root))
            continue
        n_repo_files += 1
        if st.st_nlink > 1:
            repo_ml.setdefault((st.st_dev, st.st_ino), []).append(
                (os.path.relpath(p, root), st.st_nlink, st.st_size))

for key in sorted(repo_ml):
    for rel, nl, sz in repo_ml[key]:
        emit('ML', rel, nl, sz, key[0], key[1])

# ── ② 夹具区索引（(dev,ino) -> 路径）＋ 跨区对 ─────────────────────────────────
fix_index = {}
n_fix_files = 0
missing_roots = []
for fr in fix_roots:
    if not os.path.isdir(fr):
        missing_roots.append(fr)
        continue
    for r, dirs, fs in os.walk(fr):
        for f in fs:
            p = os.path.join(r, f)
            try:
                st = os.stat(p, follow_symlinks=False)
            except OSError:
                continue
            n_fix_files += 1
            fix_index.setdefault((st.st_dev, st.st_ino), []).append(p)
emit('K', 'meta', 'fixture_roots', len(fix_roots))
emit('K', 'meta', 'fixture_roots_missing', len(missing_roots))
for m in missing_roots:
    emit('K', 'meta', 'fixture_root_missing', m)

cross = {}            # rel -> [fixture paths]
for key, lst in repo_ml.items():
    if key in fix_index:
        for rel, nl, sz in lst:
            cross[rel] = fix_index[key]
for rel in sorted(cross):
    emit('CROSS', rel, len(cross[rel]), ';'.join(sorted(cross[rel])[:6]))

# ── ③ 原地写者登记表：机械核对"写盘形态"（抽不出 ⇒ unconfirmed）───────────────
writer_form = {}      # (file, writer) -> (form, why)
for e in writers:
    if len(e) < 3:
        continue
    tgt, wrt, lit_in = e[0].strip(), e[1].strip(), e[2]
    lit_rn = e[3] if len(e) > 3 else ''
    try:
        with open(os.path.join(root, wrt), 'r', encoding='utf-8', errors='replace') as fh:
            src = fh.read()
    except OSError:
        writer_form[(tgt, wrt)] = ('unconfirmed', 'writer-file-missing')
        continue
    if lit_rn and lit_rn.strip() and lit_rn in src:
        writer_form[(tgt, wrt)] = ('temp-rename', 'rename-literal:' + lit_rn.strip())
    elif lit_in and lit_in in src:
        writer_form[(tgt, wrt)] = ('inplace', 'inplace-literal:' + lit_in)
    elif lit_rn and lit_rn.strip():
        writer_form[(tgt, wrt)] = ('unconfirmed', 'neither-literal')
    else:
        writer_form[(tgt, wrt)] = ('unconfirmed', 'inplace-literal-absent')
for (tgt, wrt), (form, why) in sorted(writer_form.items()):
    emit('WRITER', tgt, wrt, form, why)

# ── ④ 孪生件成对读数（可复算样板）────────────────────────────────────────────
for e in twins:
    if len(e) < 3:
        continue
    rel, fix = e[0].strip(), os.path.expanduser(e[1].strip())
    exp = e[2].strip()
    src = e[3].strip() if len(e) > 3 else '-'
    rp = os.path.join(root, rel)
    row = {'rel': rel, 'fix': fix, 'exp': exp, 'src': src}
    for tag, path in (('repo', rp), ('fix', fix)):
        try:
            st = os.stat(path, follow_symlinks=False)
            row[tag + '_dev'] = st.st_dev
            row[tag + '_ino'] = st.st_ino
            row[tag + '_nl'] = st.st_nlink
            row[tag + '_sha'] = sha16(path)
            row[tag + '_ok'] = 1
        except OSError:
            row[tag + '_dev'] = row[tag + '_ino'] = row[tag + '_nl'] = -1
            row[tag + '_sha'] = '<missing>'
            row[tag + '_ok'] = 0
    row['same_inode'] = 'yes' if (row['repo_ok'] and row['fix_ok']
                                  and row['repo_dev'] == row['fix_dev']
                                  and row['repo_ino'] == row['fix_ino']) else 'no'
    if row['repo_sha'] == exp and row['fix_sha'] == exp:
        row['anchor'] = 'ok'; row['exp_side'] = 'both'
    elif row['repo_sha'] == exp:
        row['anchor'] = 'ok'; row['exp_side'] = 'repo'
    elif row['fix_sha'] == exp:
        row['anchor'] = 'ok'; row['exp_side'] = 'fix'
    elif not row['repo_ok'] and not row['fix_ok']:
        row['anchor'] = 'NA'; row['exp_side'] = 'none'
    else:
        row['anchor'] = 'DRIFT'; row['exp_side'] = 'none'
    emit('TWIN', row['rel'], row['fix'], row['same_inode'],
         'repo_sha=%s fix_sha=%s exp=%s anchor=%s exp_side=%s src=%s' % (
             row['repo_sha'], row['fix_sha'], row['exp'], row['anchor'], row['exp_side'], row['src']),
         'repo_nl=%s repo_ino=%s fix_nl=%s fix_ino=%s' % (
             row['repo_nl'], row['repo_ino'], row['fix_nl'], row['fix_ino']))

emit('K', 'meta', 'repo_files', n_repo_files)
emit('K', 'meta', 'fixture_files', n_fix_files)
emit('K', 'meta', 'multilink', sum(len(v) for v in repo_ml.values()))
emit('K', 'meta', 'cross', len(cross))
PY_HYG_IN
}

parse_inode() {   # $1=tsv ⇒ 结果写进全局 N_*
  N_ML=0; N_CROSS=0; N_REPOF=0; N_FIXF=0; N_FIXROOTS=0; N_FIXMISS=0; N_STATERR=0
  N_MLROWS=''; N_CROSSROWS=''; N_WRITERROWS=''; N_TWINROWS=''
  local tag a b c d e
  while IFS=$'\t' read -r tag a b c d e; do
    case "$tag" in
      K) case "$a" in
           meta) case "$b" in
                   repo_files) N_REPOF="$c";; fixture_files) N_FIXF="$c";;
                   multilink) N_ML="$c";; cross) N_CROSS="$c";;
                   fixture_roots) N_FIXROOTS="$c";; fixture_roots_missing) N_FIXMISS="$c";;
                   stat_error) N_STATERR=$((N_STATERR + 1));;
                 esac;;
         esac;;
      ML) N_MLROWS="${N_MLROWS}${a}|${b}|${c}"$'\n';;
      CROSS) N_CROSSROWS="${N_CROSSROWS}${a}|${b}|${c}"$'\n';;
      WRITER) N_WRITERROWS="${N_WRITERROWS}${a}|${b}|${c}|${d}"$'\n';;
      TWIN) N_TWINROWS="${N_TWINROWS}${a}|${b}|${c}|${d}|${e}"$'\n';;
    esac
  done < "$1"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 覆盖面声明打印
# ═══════════════════════════════════════════════════════════════════════════════
emit_scope_decl() {
  local npairs ncmds nsink nextr
  npairs=$(printf '%s\n' $HYG_PAIRS | sed -n '$=')
  ncmds=$(printf '%s\n' $HYG_CMDS | sed -n '$=')
  nsink=$(printf '%s\n' $HYG_CMDSINK | sed -n '$=')
  nextr=$(printf '%s\n' $HYG_EXT_ROOTS_ML | sed '/^[[:space:]]*$/d' | sed -n '$=')
  say "HYGIENE_SCOPE_DECL pairs=$npairs code_exts='$HYG_CODE_EXTS' doc_exts='$HYG_DOC_EXTS' evidence_name_re='$HYG_EVIDENCE_RE' skipdirs='$HYG_SKIPDIRS' cmd_roster=$ncmds failtext_entries=$nsink ext_roots=$nextr min_files=$MIN_FILES min_pairs=$MIN_PAIRS anchors=$ANCHORS strict_ext=$STRICT_EXT"
  say "HYGIENE_SCOPE_PAIRS $HYG_PAIRS"
  say "HYGIENE_SCOPE_EXT_ROOTS $(printf '%s\n' $HYG_EXT_ROOTS_ML | tr '\n' ' ')"
  local l
  while IFS= read -r l; do [ -n "$l" ] && say "HYGIENE_SCOPE_FAILTEXT $l"; done <<< "$HYG_CMDSINK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 生产路径
# ═══════════════════════════════════════════════════════════════════════════════
cleanup_tmp() { [ "$KEEP_TMP" = 1 ] || rm -rf "$T"; }

main_run() {
  emit_scope_decl
  local fatal=''
  if ! command -v "$PYBIN" >/dev/null 2>&1; then fatal="python-missing py=$PYBIN"
  elif [ ! -d "$ROOT" ]; then fatal="root-missing root=$ROOT"; fi
  if [ -n "$fatal" ]; then
    say "HYGIENE_ROOTS=NOINFO reason=$fatal"
    say "HYGIENE_EVIDENCE=NOINFO reason=$fatal"
    say "HYGIENE_SCOPE=NOINFO reason=$fatal"
    say "HYGIENE_TOOTH=NOINFO reason=$fatal rc=2"
    say "HYGIENE_SELF path=$SELF sha16=$(self_sha16)"
    return 2
  fi
  T="$(mktemp -d "$TMPBASE/hyg-run.XXXXXX")" || { say 'HYGIENE_TOOTH=NOINFO reason=mktemp-failed rc=2'; return 2; }
  trap cleanup_tmp EXIT
  say "HYGIENE_TMPDIR=$T"

  # 登记表可读性（`D-G91` 的教训用在本件自己身上：**抽不出就 NOINFO，不许自己猜一份**）
  local reg_ok=1 reg_why=''
  if [ -n "${HYG_PAIRS_FILE:-}" ]; then
    if [ -r "$HYG_PAIRS_FILE" ]; then
      HYG_PAIRS="$(tr -s '[:space:]' ' ' < "$HYG_PAIRS_FILE" | sed 's/^ //; s/ $//')"
      say "HYGIENE_SCOPE_PAIRS_FILE $HYG_PAIRS_FILE"
    else
      reg_ok=0; reg_why="registry-unreadable file=$HYG_PAIRS_FILE"
    fi
  fi
  [ -z "$HYG_PAIRS" ] && { reg_ok=0; reg_why='registry-unreadable pairs-empty'; }

  # ── 引用面（条件 ④a）：**把 `D-G91` 的教训用在本件自己的射程上** ──
  #   调用方注入引用面（只给自测）而 `ANCHORS=strict` ⇒ **拒绝**（收窄射程不许打出绿）
  [ -n "${HYG_CITE_ML_ENV:-}" ] && CITE_OVERRIDE=1
  CITE_SURFACE="$(expand_cite)"
  CITE_N=0; for _c in $CITE_SURFACE; do CITE_N=$((CITE_N + 1)); done
  if { [ "$CITE_OVERRIDE" = 1 ] || [ -n "${HYG_FIXTURE_ROOTS_ENV+x}" ] || [ -n "${HYG_WRITERS_ENV:-}" ]; } \
     && [ "$ANCHORS" = strict ]; then
    say "HYGIENE_EVIDENCE=NOINFO reason=narrowed-citation-surface（注入引用面 ＋ ANCHORS=strict ⇒ 拒绝给读数：收窄射程打出绿就是 D-G91 的假绿）"
    say "HYGIENE_ROOTS=NOINFO reason=narrowed-citation-surface"
    say "HYGIENE_SCOPE=NOINFO reason=narrowed-citation-surface"
    say "HYGIENE_TOOTH=NOINFO reason=narrowed-citation-surface rc=2"
    say "HYGIENE_SELF path=$SELF sha16=$(self_sha16)"
    return 2
  fi
  if [ "$CITE_N" = 0 ]; then
    say "HYGIENE_EVIDENCE=NOINFO reason=cite-surface-unreadable（引用面 0 件 ⇒ 条件 ④ 判不了 ⇒ 既不绿也不红）"
    say "HYGIENE_ROOTS=NOINFO reason=cite-surface-unreadable"
    say "HYGIENE_SCOPE=NOINFO reason=cite-surface-unreadable"
    say "HYGIENE_TOOTH=NOINFO reason=cite-surface-unreadable rc=2"
    say "HYGIENE_SELF path=$SELF sha16=$(self_sha16)"
    return 2
  fi
  say "HYGIENE_EVIDENCE_CITE surface_files=$CITE_N override=$CITE_OVERRIDE roots='$EVIDENCE_ROOTS'"

  # ── 第一类 ──
  if [ "$reg_ok" != 1 ]; then
    R_STATE=NOINFO; R_DETAIL="$reg_why"; R_PAIRS_N=0
  elif [ "$ANCHORS" = strict ] && [ ! -f "$ROOT/build/close-wave.sh" ]; then
    R_STATE=NOINFO; R_DETAIL="anchor-missing:build/close-wave.sh（射程缩水 ⇒ 不许绿）"; R_PAIRS_N=0
  else
    check_roots
  fi
  [ -n "$R_ROWS" ] && printf '%s' "$R_ROWS"
  case "$R_STATE" in
    PASS) say "HYGIENE_ROOTS=PASS pairs=$R_PAIRS_N（登记表内每一对：声明集合 == 打印集合 == 同步器派生集合；无自写默认根）";;
    FAIL) say "HYGIENE_ROOTS=FAIL pairs=$R_PAIRS_N detail=$R_DETAIL";;
    *)    say "HYGIENE_ROOTS=NOINFO reason=$R_DETAIL pairs=$R_PAIRS_N";;
  esac
  say "HYGIENE_ROOTS_UNCHECKED pairs_declared=$R_PAIRS_N only-registered-pairs-are-checked（登记表外的「两处各写一份根集合」**未查**）"

  # ── 第二类 ──
  local spec evtsv everr evrc
  spec="judge|$ROOT"
  local m
  for m in $HYG_EXT_ROOTS_ML; do [ -n "$m" ] && spec="$spec;report|$m"; done
  evtsv="$T/ev.tsv"; everr="$T/ev.err"
  HYG_EXTFILES=0; E_ROOTMISS=''; E_READERR=0
  py_evidence "$spec" "$evtsv" "$everr"; evrc=$?
  parse_evidence "$evtsv"
  local ev_err_log=''; [ -s "$everr" ] && ev_err_log="$(sed -n '1p' "$everr")"
  local E_STATE=PASS E_RC=0 E_WHY=''
  if [ "$evrc" != 0 ] || [ -n "$ev_err_log" ]; then
    E_STATE=NOINFO; E_WHY="scanner-error rc=$evrc err=$ev_err_log"
  elif [ "$E_BLIND" != 0 ] || [ "$E_BLINDMETA" != 0 ]; then
    E_STATE=NOINFO; E_WHY='scanner-blinded（HYG_TEST_BLIND=1 ⇒ 不解析目标 ⇒ 读数无信息）'
  elif [ -n "$E_ROOTMISS" ]; then
    E_STATE=NOINFO; E_WHY="root-missing $E_ROOTMISS"
  elif [ "$E_READERR" != 0 ]; then
    E_STATE=NOINFO; E_WHY="read-errors n=$E_READERR"
  elif [ "$E_FILES" -eq 0 ]; then
    E_STATE=NOINFO; E_WHY='empty-roster（覆盖面 0 件 ⇒ 不是"干净"，是"没测"）'
  elif [ "$ANCHORS" = strict ] && [ "$E_FILES" -lt "$MIN_FILES" ]; then
    E_STATE=NOINFO; E_WHY="too-few-files files=$E_FILES min=$MIN_FILES"
  elif [ "$E_HIT" != 0 ]; then
    E_STATE=FAIL; E_WHY=''
  fi
  say "HYGIENE_EVIDENCE_ROSTER code_files=$E_FILES doc_files=$E_DOCFILES ext_files=$E_EXTFILES rows=$E_ROWS sites=$((E_HIT + E_NOTCITED + E_NOTNAME + E_NOTFIXED + E_SELFTEST + E_SELF + E_DOC + E_BLIND))"
  say "HYGIENE_EVIDENCE_NOTJUDGED notfixed=$E_NOTFIXED not_name=$E_NOTNAME not_cited=$E_NOTCITED selftest_region=$E_SELFTEST self=$E_SELF comment_or_doc=$E_DOC blinded=$E_BLIND"
  local nc
  while IFS= read -r nc; do
    [ -n "$nc" ] || continue
    p="${nc%%|*}"; nc="${nc#*|}"; form="${nc%%|*}"; nc="${nc#*|}"
    tgt="${nc%%|*}"; raw="${nc#*|}"
    say "HYGIENE_EVIDENCE_NOTCITED site=$p form=$form target='$tgt' raw='$raw'（固定 ＋ 证据名，但**不在引用面**、也不在承重证据根下 ⇒ 按判据**不判红**，此处逐条点名）"
  done <<< "$E_NCROWS"
  local hr p ln form tgt raw
  while IFS= read -r hr; do
    [ -n "$hr" ] || continue
    p="${hr%%|*}"; hr="${hr#*|}"; form="${hr%%|*}"; hr="${hr#*|}"
    tgt="${hr%%|*}"; hr="${hr#*|}"; raw="${hr%%|*}"; why="${hr#*|}"
    say "HYGIENE_EVIDENCE_HIT site=$p form=$form target='$tgt' raw='$raw' why=$why"
  done <<< "$E_HITROWS"
  case "$E_STATE" in
    PASS) say "HYGIENE_EVIDENCE=PASS code_files=$E_FILES exec_hits=0 not_cited=$E_NOTCITED（仓内判red 覆盖面里"对跨趟固定的**承重**证据名文件做截断写" = 0）";;
    FAIL) say "HYGIENE_EVIDENCE=FAIL exec_hits=$E_HIT code_files=$E_FILES（逐处点名见上面 HYGIENE_EVIDENCE_HIT 行）"; E_RC=1;;
    *)    say "HYGIENE_EVIDENCE=NOINFO reason=$E_WHY code_files=$E_FILES exec_hits=$E_HIT"; E_RC=2;;
  esac
  if [ "$E_EXT_HIT" = 0 ]; then
    say "HYGIENE_EVIDENCE_EXT=CLEAN ext_files=$E_EXTFILES other=$E_EXT_OTHER not_cited=$E_EXT_NOTCITED strict=$STRICT_EXT"
  else
    say "HYGIENE_EVIDENCE_EXT=HITS($E_EXT_HIT) ext_files=$E_EXTFILES other=$E_EXT_OTHER not_cited=$E_EXT_NOTCITED strict=$STRICT_EXT（**仓外装置根**；默认只报不判 ⇒ 仓内门禁不吃仓外状态；--strict-ext 才进 rc）"
    local er
    while IFS= read -r er; do
      [ -n "$er" ] || continue
      p="${er%%|*}"; er="${er#*|}"; form="${er%%|*}"; er="${er#*|}"
      tgt="${er%%|*}"; er="${er#*|}"; raw="${er%%|*}"; why="${er#*|}"
      say "HYGIENE_EVIDENCE_EXT_HIT site=$p form=$form target='$tgt' raw='$raw' why=$why"
    done <<< "$E_EXTHITROWS"
    if [ "$STRICT_EXT" = 1 ]; then
      E_RC=1; [ "$E_STATE" = PASS ] && E_STATE=FAIL
      say "HYGIENE_EVIDENCE_STRICT_EXT=FAIL strict_ext=1 ext_hits=$E_EXT_HIT（成对读数用：默认只报 ⇒ rc 不受它影响）"
    fi
  fi

  # ── 第四类：硬链接 / 跨区同 inode（`W120A`） ──
  local intsv inerr inrc
  intsv="$T/in.tsv"; inerr="$T/in.err"
  py_inode "$ROOT" "$HYG_FIXTURE_ROOTS" "$HYG_WRITERS" "$HYG_TWINS" "$intsv" "$inerr"; inrc=$?
  parse_inode "$intsv"
  local in_err_log=''; [ -s "$inerr" ] && in_err_log="$(sed -n '1p' "$inerr")"
  local N_STATE=PASS N_WHY='' N_FAILROWS=''
  if [ "$inrc" != 0 ] || [ -n "$in_err_log" ]; then
    N_STATE=NOINFO; N_WHY="scanner-error rc=$inrc err=$in_err_log"
  elif [ "$N_STATERR" != 0 ]; then
    N_STATE=NOINFO; N_WHY="stat-errors n=$N_STATERR"
  elif [ "$N_FIXROOTS" != 0 ] && [ "$N_FIXMISS" -ge "$N_FIXROOTS" ]; then
    N_STATE=NOINFO; N_WHY="fixture-roots-missing（登记的 $N_FIXROOTS 个夹具根**一个都不在** ⇒ 跨区判不了）"
  fi
  # 机械判据：写者形态（登记表 F 现算） × 跨区同 inode（登记表 G/H 现算）
  local wr unconf=''
  while IFS= read -r wr; do
    [ -n "$wr" ] || continue
    local w_t w_w w_f w_y w_hit
    w_t="${wr%%|*}"; wr="${wr#*|}"; w_w="${wr%%|*}"; wr="${wr#*|}"
    w_f="${wr%%|*}"; w_y="${wr#*|}"
    w_hit=no
    case "$N_CROSSROWS" in *"$w_t|"*) w_hit=yes;; esac
    if [ "$w_hit" = yes ] && [ "$w_f" = inplace ]; then
      N_STATE=FAIL
      N_FAILROWS="${N_FAILROWS}HYGIENE_INODE_FAIL file=$w_t writer=$w_w form=inplace cross=yes why=$w_y（**原地写 × 跨区同 inode ⇒ 写穿夹具**）"$'\n'
    elif [ "$w_hit" = yes ] && [ "$w_f" = unconfirmed ]; then
      unconf="${unconf}${w_t}($w_w: $w_y) "
    fi
  done <<< "$N_WRITERROWS"
  if [ "$N_STATE" != FAIL ] && [ -n "$unconf" ]; then
    N_STATE=NOINFO; N_WHY="writer-form-unconfirmed $unconf"
  fi
  say "HYGIENE_INODE_ROSTER repo_files=$N_REPOF fixture_files=$N_FIXF multilink=$N_ML cross_region=$N_CROSS fixture_roots=$N_FIXROOTS missing=$N_FIXMISS"
  say "HYGIENE_INODE_WRITERS $(printf '%s' "$N_WRITERROWS" | tr '\n' ';' | sed 's/;$//')"
  local tw
  while IFS= read -r tw; do
    [ -n "$tw" ] || continue
    local t_rel t_fix t_same t_read t_ids
    t_rel="${tw%%|*}"; tw="${tw#*|}"; t_fix="${tw%%|*}"; tw="${tw#*|}"
    t_same="${tw%%|*}"; tw="${tw#*|}"; t_read="${tw%%|*}"; t_ids="${tw#*|}"
    say "HYGIENE_INODE_TWIN file=$t_rel fixture=$t_fix same_inode=$t_same $t_read $t_ids（**成对样板**：开工/收工各跑一次，两趟的 repo_sha 必须逐位相同）"
  done <<< "$N_TWINROWS"
  local mr
  local n_ml_show=0
  while IFS= read -r mr; do
    [ -n "$mr" ] || continue
    local m_rel m_nl m_sz
    m_rel="${mr%%|*}"; mr="${mr#*|}"; m_nl="${mr%%|*}"; m_sz="${mr#*|}"
    n_ml_show=$((n_ml_show + 1))
    [ "$n_ml_show" -le 40 ] && say "HYGIENE_INODE_MULTILINK file=$m_rel links=$m_nl size=$m_sz"
  done <<< "$N_MLROWS"
  [ "$n_ml_show" -gt 40 ] && say "HYGIENE_INODE_MULTILINK_TRUNCATED printed=40 rest=$((n_ml_show - 40))"
  local cr2
  while IFS= read -r cr2; do
    [ -n "$cr2" ] || continue
    local c_rel c_n c_list
    c_rel="${cr2%%|*}"; cr2="${cr2#*|}"; c_n="${cr2%%|*}"; c_list="${cr2#*|}"
    say "HYGIENE_INODE_CROSS file=$c_rel n_fixtures=$c_n fixtures='$c_list'"
  done <<< "$N_CROSSROWS"
  [ -n "$N_FAILROWS" ] && printf '%s' "$N_FAILROWS"
  case "$N_STATE" in
    PASS) say "HYGIENE_INODE=PASS multilink=$N_ML cross_region=$N_CROSS（跨区同 inode 的件里**没有**登记为原地写的写者 ⇒ 无写穿风险；只 links>1 的按报告行处理）";;
    FAIL) say "HYGIENE_INODE=FAIL multilink=$N_ML cross_region=$N_CROSS（逐处点名见上面 HYGIENE_INODE_FAIL 行）";;
    *)    say "HYGIENE_INODE=NOINFO reason=$N_WHY multilink=$N_ML cross_region=$N_CROSS";;
  esac
  say "HYGIENE_INODE_UNCHECKED sed -i／tee／cp／mv／python open(w) 等**其余原地写形态未机械解析**（只按登记表 F 的原地写字面量判）；符号链接未跟随；$HOME 里未登记的夹具区未扫"

  # ── 第三类 ──
  local sctsv scerr scrc
  sctsv="$T/sc.tsv"; scerr="$T/sc.err"
  py_scope "$ROOT" "$sctsv" "$scerr"; scrc=$?
  parse_scope "$sctsv"
  local sc_err_log=''; [ -s "$scerr" ] && sc_err_log="$(sed -n '1p' "$scerr")"
  local SC_STATE=REPORT SC_RC=0 SC_WHY=''
  if [ "$scrc" != 0 ] || [ -n "$sc_err_log" ]; then
    SC_STATE=NOINFO; SC_WHY="scanner-error rc=$scrc err=$sc_err_log"
  elif [ "$S_CASES" -eq 0 ]; then
    SC_STATE=NOINFO; SC_WHY='empty-cases（0 例 ⇒ 不是"射程内干净"，是"没找到/没测"）'
  elif [ "$S_POISON" != 0 ]; then
    SC_STATE=FAIL; SC_WHY=''
  fi
  say "HYGIENE_SCOPE_ROSTER cases=$S_CASES selftest_excluded=$S_ST"
  local cr
  while IFS= read -r cr; do
    [ -n "$cr" ] || continue
    local f_id f_rel f_ln f_cmd f_shape f_bear f_sink f_poi f_kw f_disp
    f_id="${cr%%|*}"; cr="${cr#*|}"; f_rel="${cr%%|*}"; cr="${cr#*|}"
    f_ln="${cr%%|*}"; cr="${cr#*|}"; f_cmd="${cr%%|*}"; cr="${cr#*|}"
    f_shape="${cr%%|*}"; cr="${cr#*|}"; f_bear="${cr%%|*}"; cr="${cr#*|}"
    f_sink="${cr%%|*}"; cr="${cr#*|}"; f_poi="${cr%%|*}"; cr="${cr#*|}"
    f_kw="${cr%%|*}"; f_disp="${cr#*|}"
    case "$f_disp" in
      JUDGE) say "HYGIENE_SCOPE_CASE id=$f_id file=$f_rel line=$f_ln cmd=$f_cmd shape=$f_shape bearing=$f_bear sink=$f_sink poison=$f_poi keywords='$f_kw'";;
      *)     say "HYGIENE_SCOPE_CASE_SELFTEST id=$f_id file=$f_rel line=$f_ln cmd=$f_cmd shape=$f_shape bearing=$f_bear poison=$f_poi keywords='$f_kw'（本件自测区内的负控/夹具 ⇒ 只报不判）";;
    esac
  done <<< "$S_CASEROWS"
  say "HYGIENE_SCOPE_UNCHECKED derived_predicate_sites=$S_DERIVED（**派生值**上的文本测试未计入候选格：被测串经 sed/awk/printf 二次处理 ⇒ (b) 承载 按定义不成立，但「是不是恒真」仍**未查**）；cmd_roster=$HYG_CMDS 之外的命令族**未查**"
  case "$SC_STATE" in
    REPORT) say "HYGIENE_SCOPE=REPORT cases=$S_CASES decided=$S_DEC semantic_undecidable=$S_UND poison_yes=$S_POISON（**REPORT 不是 PASS**：(c) 中毒是语义的、机械不可判的那 $S_UND 格**需人读**；逐格见 HYGIENE_SCOPE_CASE）";;
    FAIL)   say "HYGIENE_SCOPE=FAIL poison_yes=$S_POISON cases=$S_CASES（**被证明的恒真谓词**，逐条见下）"; SC_RC=1
            local pr; while IFS= read -r pr; do [ -n "$pr" ] && say "HYGIENE_SCOPE_POISON $pr"; done <<< "$S_POISONROWS";;
    *)      say "HYGIENE_SCOPE=NOINFO reason=$SC_WHY cases=$S_CASES"; SC_RC=2;;
  esac
  if [ -n "$E_EXTNCROWS" ]; then
    local ec
    while IFS= read -r ec; do
      [ -n "$ec" ] || continue
      p="${ec%%|*}"; ec="${ec#*|}"; form="${ec%%|*}"; ec="${ec#*|}"
      tgt="${ec%%|*}"; raw="${ec#*|}"
      say "HYGIENE_EVIDENCE_EXT_NOTCITED site=$p form=$form target='$tgt' raw='$raw'（仓外同形但不在引用面 ⇒ 只报）"
    done <<< "$E_EXTNCROWS"
  fi
  if [ "$WANT_SITES" = 1 ]; then
    say "HYGIENE_EVIDENCE_SITES_BEGIN"
    awk -F'\t' '$1=="SITE"{printf "%s %s:%s %s %s %s\n",$2,$3,$4,$5,$6,$8}' "$evtsv"
    say "HYGIENE_EVIDENCE_SITES_END"
  fi
  if [ "$WANT_CASES" = 1 ]; then
    say "HYGIENE_SCOPE_CASES_BEGIN"
    awk -F'\t' '$1=="CASE"{printf "%s %s:%s %s %s %s %s\n",$2,$3,$4,$5,$6,$7,$9}' "$sctsv"
    say "HYGIENE_SCOPE_CASES_END"
  fi

  # ── 总行（**三态 + 三格边界，写死**） ──
  local RC=0 STATE=PASS
  case "$R_STATE" in FAIL) STATE=FAIL;; NOINFO) [ "$STATE" = FAIL ] || STATE=NOINFO;; esac
  case "$E_STATE" in FAIL) STATE=FAIL;; NOINFO) [ "$STATE" = FAIL ] || STATE=NOINFO;; esac
  case "$SC_STATE" in FAIL) STATE=FAIL;; NOINFO) [ "$STATE" = FAIL ] || STATE=NOINFO;; esac
  case "$N_STATE" in FAIL) STATE=FAIL;; NOINFO) [ "$STATE" = FAIL ] || STATE=NOINFO;; esac
  case "$STATE" in
    PASS)   RC=0; say "HYGIENE_TOOTH=PASS roots=$R_STATE evidence=$E_STATE inode=$N_STATE scope=$SC_STATE semantic_undecidable=$S_UND multilink=$N_ML cross_region=$N_CROSS ext_ext_hits=$E_EXT_HIT ext_strict=$STRICT_EXT code_files=$E_FILES";;
    FAIL)   RC=1; say "HYGIENE_TOOTH=FAIL roots=$R_STATE evidence=$E_STATE inode=$N_STATE scope=$SC_STATE semantic_undecidable=$S_UND multilink=$N_ML cross_region=$N_CROSS ext_ext_hits=$E_EXT_HIT ext_strict=$STRICT_EXT";;
    *)      RC=2; say "HYGIENE_TOOTH=NOINFO roots=$R_STATE evidence=$E_STATE inode=$N_STATE scope=$SC_STATE reason=$E_WHY$R_DETAIL$SC_WHY$N_WHY";;
  esac
  say "HYGIENE_BOUNDARY 本行的 PASS **只**等于：登记表内根集合对（$R_PAIRS_N 对）机械可判部分一致 ∧ 仓内判red 覆盖面（$E_FILES 件脚本体）里截断写跨趟固定证据名文件 = 0。**不**等于全域干净：口径射程恒为 REPORT（semantic_undecidable=$S_UND 格需人读）、仓外装置根默认只报（ext_hits=$E_EXT_HIT）、登记表外的根集合对与未登记命令族**未查**、文档体（$HYG_DOC_EXTS）只计数不判红；第四类只判**登记表 F 确认的原地写者** × 跨区同 inode（$N_CROSS 件跨区／$N_ML 件 links>1），sed -i／tee／cp／mv／python open(w) 等**其余原地写形态未解析**，$HOME 里未登记的夹具区未扫。"
  say "HYGIENE_SELF path=$SELF sha16=$(self_sha16)"
  return "$RC"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 自测（**两极化**；自带 `TMPDIR`；注入 ⇒ 必红、还原 ⇒ 回绿；该 NOINFO 的必须 NOINFO）
# ═══════════════════════════════════════════════════════════════════════════════
run_selftest() {
  local inner="${HYG_ST_INNER:-0}"
  if [ "$inner" != 1 ]; then
    local s0 s1 out rc
    s0="$(self_sha16)"
    say "ST_ATTEST=OPEN self=$SELF sha16=$s0"
    out="$(HYG_ST_INNER=1 bash "$SELF" --selftest 2>&1)"; rc=$?
    printf '%s\n' "$out"
    s1="$(self_sha16)"
    if [ "$s1" != "$s0" ]; then
      say "ST_ATTEST=NOINFO reason=self-rewritten-during-selftest（本件在自测期间被改写 ⇒ 上面的读数不可归因）self=$SELF sha0=$s0 sha1=$s1 inner_rc=$rc"
      say "HYGIENE_SELFTEST=NOINFO reason=self-rewritten sha0=$s0 sha1=$s1"
      return 2
    fi
    say "ST_ATTEST=PASS self=$SELF sha16=$s0（自测期间本件未变 ⇒ 读数可归因）"
    return "$rc"
  fi
  if ! command -v "$PYBIN" >/dev/null 2>&1; then
    say "HYGIENE_SELFTEST=NOINFO reason=premise-unmet:python-missing py=$PYBIN（自测的仪器前提不成立）"
    return 2
  fi
  local SB
  SB="$(mktemp -d "$TMPBASE/hyg-selftest.XXXXXX")" || { say 'HYGIENE_SELFTEST=FAIL reason=mktemp-failed'; return 1; }
  mkdir -p "$SB/tmp" "$SB/repo/build/DirectWrite.Linux/wic-shim" "$SB/repo/build/MilBridge/arm-logs" \
           "$SB/repo/devices" "$SB/repo/docs" "$SB/repo/samples/WpfFeatureProbe" "$SB/home/w63a/bin"
  local pass=0 fail=0 total=0 nae=0
  local CUR_OUT='' CUR_RC='' CUR_TOOTH='' CUR_ROOTS='' CUR_EV='' CUR_SC='' CUR_WANT=''
  # 夹具里的**引用面**（条件 ④a）与**锚**：沙箱自带这两样 ⇒ 不必注入引用面（`CITE_OVERRIDE=0`）
  printf '%s\n' 'dev.progress 是被本夹具引用的进度文件（D-G96 的承重关系）。' \
    > "$SB/repo/samples/WpfFeatureProbe/KNOWN-DEFECTS.md"
  printf '%s\n' '本夹具引用 dev.progress 与 arm-logs 下的证据。' > "$SB/repo/docs/cite.md"
  : > "$SB/repo/build/close-wave.sh"

  run_case() {   # $1=id $2=want(0|1|2) $3=root [额外 env 赋值...]
    local id="$1" want="$2" r="$3"; shift 3
    local -a envs=("HYG_TMPDIR=$SB/tmp" "$@")
    CUR_WANT="$want"
    CUR_OUT="$(env "${envs[@]}" bash "$SELF" --root "$r" 2>&1)"; CUR_RC=$?
    CUR_TOOTH="$(printf '%s\n' "$CUR_OUT" | sed -n 's/^HYGIENE_TOOTH=\([A-Z]*\).*/\1/p' | sed -n '1p')"
    CUR_ROOTS="$(printf '%s\n' "$CUR_OUT" | sed -n 's/^HYGIENE_ROOTS=\([A-Z]*\).*/\1/p' | sed -n '1p')"
    CUR_EV="$(printf '%s\n' "$CUR_OUT" | sed -n 's/^HYGIENE_EVIDENCE=\([A-Z]*\).*/\1/p' | sed -n '1p')"
    CUR_SC="$(printf '%s\n' "$CUR_OUT" | sed -n 's/^HYGIENE_SCOPE=\([A-Z]*\).*/\1/p' | sed -n '1p')"
    local ok='no' why=''
    if [ "$CUR_RC" = "$want" ]; then ok=yes; else why="rc=$CUR_RC want=$want"; fi
    total=$((total + 1))
    if [ "$ok" = yes ]; then pass=$((pass + 1)); else fail=$((fail + 1)); nae=$((nae + 1)); fi
    printf 'SELFTEST CASE %-30s = %s rc=%s want=%s tooth=%s roots=%s evidence=%s scope=%s %s\n' \
      "$id" "$( [ "$ok" = yes ] && echo PASS || echo FAIL )" "$CUR_RC" "$want" \
      "${CUR_TOOTH:-none}" "${CUR_ROOTS:-none}" "${CUR_EV:-none}" "${CUR_SC:-none}" "$why"
  }
  has() { case "$CUR_OUT" in *"$1"*) HAS=1;; *) HAS=0;; esac; }
  assert() {
    total=$((total + 1))
    if [ "$2" = 1 ]; then pass=$((pass + 1)); printf 'SELFTEST ASSERT %-58s = PASS\n' "$1"
    else fail=$((fail + 1)); printf 'SELFTEST ASSERT %-58s = FAIL\n' "$1"; fi
  }

  # ── 夹具生成器（**正文一律用 printf 生成**，不把被测形态写成"本件自己的代码"）──
  mk_checker() {
    {
      printf '%s\n' '#!/usr/bin/env bash'
      printf '%s\n' 'set -uo pipefail'
      printf '%s\n' 'HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'
      printf '%s\n' 'REPO="${AUTH_ROOT:-$(cd "$HERE/../../.." && pwd)}"'
      printf '%s\n' 'SCAN_ROOTS_DEFAULT="$REPO/build:$REPO/tests"'
      printf '%s\n' 'SCAN_ROOTS="${SCAN_ROOTS:-$SCAN_ROOTS_DEFAULT}"'
      printf '%s\n' 'for _a in "$@"; do case "$_a" in --print-scan-roots) printf "%s\n" "$SCAN_ROOTS_DEFAULT"; exit 0;; esac; done'
      printf '%s\n' 'echo "APPSYNC=fixture"'
      printf '%s\n' 'exit 0'
    } > "$1"
  }
  mk_sync_good() {   # 派生 ＋ 收窄拒绝（**修后形态**）
    {
      printf '%s\n' '#!/usr/bin/env bash'
      printf '%s\n' 'set -uo pipefail'
      printf '%s\n' 'HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'
      printf '%s\n' 'CHECK="$HERE/check-applocal-sync.sh"'
      printf '%s\n' 'REPO="${AUTH_ROOT:-$(cd "$HERE/../../.." && pwd)}"'
      printf '%s\n' 'SCAN_ROOTS="${SCAN_ROOTS:-}"'
      printf '%s\n' 'CHECK_ROOTS="$(AUTH_ROOT="$REPO" bash "$CHECK" --print-scan-roots 2>/dev/null)"'
      printf '%s\n' 'if [ -z "$SCAN_ROOTS" ]; then SCAN_ROOTS="$CHECK_ROOTS"; else'
      printf '%s\n' '  if [ "$SCAN_ROOTS" != "$CHECK_ROOTS" ]; then'
      printf '%s\n' '    printf "APPSYNC_ROOTS=MISMATCH sync=%s\n" "$SCAN_ROOTS"'
      printf '%s\n' '    printf "APPSYNC_ROOTS=NOINFO reason=narrowed-scan-roots\n"'
      printf '%s\n' '    exit 2'
      printf '%s\n' '  fi'
      printf '%s\n' 'fi'
      printf '%s\n' 'printf "APPSYNC-REFRESH=refreshed=0\n"'
      printf '%s\n' 'exit 0'
    } > "$1"
  }
  mk_sync_bad() {    # `D-G91` **原形**：自写收窄默认根 ＋ 不派生
    {
      printf '%s\n' '#!/usr/bin/env bash'
      printf '%s\n' 'set -uo pipefail'
      printf '%s\n' 'HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'
      printf '%s\n' 'REPO="${AUTH_ROOT:-$(cd "$HERE/../../.." && pwd)}"'
      printf '%s\n' 'SCAN_ROOTS="${SCAN_ROOTS:-$REPO/build}"'
      printf '%s\n' 'printf "APPSYNC-REFRESH=refreshed=0\n"'
      printf '%s\n' 'exit 0'
    } > "$1"
  }
  mk_dev_bad() {     # `D-G96` **原形**：截断写**跨趟固定**的**承重**证据名文件
    printf 'PROG="$HOME/fixture/logs/dev.progress"\n' > "$1"
    printf '%s\n' 'say(){ printf "%s\n" "$*" | tee -a "$PROG"; }' >> "$1"
    printf '%s > "$PROG"\n' ":" >> "$1"
    printf '%s\n' 'say hello' >> "$1"
  }
  mk_dev_good() {    # **修后形态**：追加 ＋ 每趟独立名（`D-G96` 的修法）
    printf 'PROG="$HOME/fixture/logs/dev.progress"\n' > "$1"
    printf '%s\n' 'TS="$(date +%Y%m%dT%H%M%S)"' >> "$1"
    printf '%s\n' 'say(){ printf "%s\n" "$*" | tee -a "$PROG.$TS"; }' >> "$1"
    printf '%s\n' 'say hello' >> "$1"
  }
  mk_dev_notcited() {   # 固定 ＋ 证据名，但**不在引用面** ⇒ 必须 PASS 且逐条点名（NOTCITED）
    printf 'KP="$HOME/fixture/logs/uncited-report.log"\n' > "$1"
    printf '%s > "$KP"\n' ":" >> "$1"
  }
  mk_dev_armlog() {     # 血案形态：目标落在**登记承重证据根**下 ⇒ 必红（即使没被引用面提到）
    printf '%s\n' 'LOG="build/MilBridge/arm-logs/fixture-anchor.log"' > "$1"
    printf '%s > "$LOG"\n' ":" >> "$1"
  }
  mk_writer_inplace() {   # 写盘 = **原地写**（`D-G96`/`W120A` 那一族：截断同一 inode）
    printf '%s\n' '#!/usr/bin/env python3' > "$1"
    printf '%s\n' 'import json, os' >> "$1"
    printf '%s\n' 'REG = os.environ.get("REG", "build/MilBridge/known-red.json")' >> "$1"
    printf '%s\n' 'd = json.load(open(REG, encoding="utf-8"))' >> "$1"
    printf '%s\n' 'json.dump(d, open(REG, "w", encoding="utf-8"))' >> "$1"
  }
  mk_writer_rename() {    # 写盘 = **temp ＋ rename**（解链，安全）
    printf '%s\n' '#!/usr/bin/env python3' > "$1"
    printf '%s\n' 'import json, os' >> "$1"
    printf '%s\n' 'REG = os.environ.get("REG", "build/MilBridge/known-red.json")' >> "$1"
    printf '%s\n' 'd = json.load(open(REG, encoding="utf-8"))' >> "$1"
    printf '%s\n' 'tmp = REG + ".tmp"' >> "$1"
    printf '%s\n' 'json.dump(d, open(tmp, "w", encoding="utf-8"))' >> "$1"
    printf '%s\n' 'os.replace(tmp, REG)' >> "$1"
  }
  mk_writer_neither() {   # 两种形态都抽不出 ⇒ 必须 NOINFO（不许猜）
    printf '%s\n' '#!/usr/bin/env python3' > "$1"
    printf '%s\n' 'print("no write form declared here")' >> "$1"
  }
  mk_scope_undecidable() {   # (c) 不可判格：命令不在失败文案登记表里
    printf '%s\n' '#!/usr/bin/env bash' > "$1"
    printf 'WIN="$(xwininfo -root -tree 2>/dev/null | grep -aF %s | head -1)"\n' "'FixtureWindow'" >> "$1"
    printf '%s\n' 'case "$WIN" in *0x*) echo ok ;; *) echo no ;; esac' >> "$1"
  }
  DEV="$SB/repo/devices/dev.sh"
  UNCITED="$SB/repo/devices/uncited.sh"
  ARMLOG="$SB/repo/devices/armlog.sh"
  SYNC="$SB/repo/build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh"
  CHK="$SB/repo/build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh"
  PAIRS="$SYNC|$CHK|SCAN_ROOTS_DEFAULT|--print-scan-roots"
  mk_checker "$CHK"
  mk_scope_undecidable "$SB/repo/devices/probe.sh"

  # ── S01 `D-G91` 原形 ⇒ ROOTS 必红；还原（派生）⇒ 回绿 ──────────────────────
  mk_sync_bad "$SYNC"
  run_case S01a-self-written-default 1 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'HYGIENE_ROOTS=FAIL'; assert 'S01a 自写默认根 ⇒ HYGIENE_ROOTS=FAIL' "$HAS"
  has 'R3-self-written-default'; assert 'S01a 点名 R3-self-written-default' "$HAS"
  mk_sync_good "$SYNC"
  run_case S01b-restore-derivation 0 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'HYGIENE_ROOTS=PASS'; assert 'S01b 还原（派生）⇒ HYGIENE_ROOTS=PASS（成对）' "$HAS"

  # ── S02 `D-G96` 原形 ⇒ EVIDENCE 必红；S03 还原 ⇒ 回绿 ─────────────────────
  mk_dev_bad "$DEV"
  run_case S02-truncating-evidence 1 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'HYGIENE_EVIDENCE=FAIL'; assert 'S02 截断写承重证据名 ⇒ HYGIENE_EVIDENCE=FAIL' "$HAS"
  has 'devices/dev.sh:3'; assert 'S02 逐处点名 file:line（devices/dev.sh:3）' "$HAS"
  has 'cited-basename'; assert 'S02 判词写明承重依据（cited-basename）' "$HAS"
  mk_dev_good "$DEV"
  run_case S03-append-and-unique-name 0 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'HYGIENE_EVIDENCE=PASS'; assert 'S03 追加 ＋ 每趟独立名 ⇒ 回绿（不是"看见 log 就红"）' "$HAS"
  rm -f "$DEV"

  # ── S04 三条 NOINFO（**不冒绿也不冒红**） ──────────────────────────────────
  run_case S04a-empty-roster 2 "$SB/repo" HYG_ANCHORS=strict HYG_MIN_FILES=999999 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'reason=too-few-files'; assert 'S04a 覆盖面低于下限 ⇒ NOINFO too-few-files' "$HAS"
  run_case S04b-python-missing 2 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PYTHON=/nonexistent/python3 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'reason=python-missing'; assert 'S04b 缺 python3 ⇒ NOINFO python-missing' "$HAS"
  run_case S04c-registry-unreadable 2 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_FILE=/nonexistent/hyg-pairs.txt HYG_EXT_ROOTS_ENV=''
  has 'reason=registry-unreadable'; assert 'S04c 登记表读不到 ⇒ NOINFO registry-unreadable' "$HAS"

  # ── S05 口径射程：(c) 不可判 ⇒ REPORT（**不许冒 PASS**） ───────────────────
  run_case S05-scope-undecidable 0 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'HYGIENE_SCOPE=REPORT'; assert 'S05 (c) 不可判 ⇒ HYGIENE_SCOPE=REPORT' "$HAS"
  has 'poison=undecidable'; assert 'S05 逐格写 poison=undecidable（不许机器猜）' "$HAS"
  has 'semantic_undecidable=1'; assert 'S05 semantic_undecidable=1 在 REPORT 行上' "$HAS"
  case "$CUR_SC" in PASS) HAS=0;; *) HAS=1;; esac
  assert 'S05 HYGIENE_SCOPE 不是 PASS（冒绿判据）' "$HAS"
  has 'HYGIENE_TOOTH=PASS roots=PASS evidence=PASS inode=PASS scope=REPORT'; assert 'S05 总行的 PASS 必须带 scope=REPORT' "$HAS"

  # ── S06 反极性：(c) 变成"可判且中毒" ⇒ SCOPE 必红 ─────────────────────────
  printf '%s\n' '#!/usr/bin/env bash' > "$SB/repo/devices/poison.sh"
  printf '%s\n' 'R="$(timeout 2 xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null)"' >> "$SB/repo/devices/poison.sh"
  printf '%s\n' 'case "$R" in *window*) echo present ;; *) echo absent ;; esac' >> "$SB/repo/devices/poison.sh"
  run_case S06-scope-poison 1 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'HYGIENE_SCOPE=FAIL'; assert 'S06 关键词命中已登记失败文案 ⇒ SCOPE=FAIL（判别式是活的）' "$HAS"
  has 'HYGIENE_SCOPE_POISON'; assert 'S06 逐条点名 HYGIENE_SCOPE_POISON' "$HAS"
  rm -f "$SB/repo/devices/poison.sh"

  # ── S07 仓外登记根：默认只报不判；`--strict-ext` 才进 rc（成对） ───────────
  mk_dev_bad "$SB/home/w63a/bin/dev2.sh"
  run_case S07a-ext-report-only 0 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV="$SB/home/w63a/bin"
  has 'HYGIENE_EVIDENCE_EXT=HITS(1)'; assert 'S07a 仓外承重命中：默认只报（EXT=HITS(1)）' "$HAS"
  has 'HYGIENE_TOOTH=PASS'; assert 'S07a 仓外命中**不**动仓内门禁 rc（PASS）' "$HAS"
  run_case S07b-ext-strict 1 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_STRICT_EXT=1 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV="$SB/home/w63a/bin"
  has 'HYGIENE_EVIDENCE_STRICT_EXT=FAIL'; assert 'S07b --strict-ext 才进 rc（成对读数）' "$HAS"
  rm -f "$SB/home/w63a/bin/dev2.sh"

  # ── S08 弄瞎扫描器 ⇒ NOINFO（**同一棵会判红的树**，既不绿也不冒充红） ────────
  mk_dev_bad "$DEV"
  run_case S08-blinded 2 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_TEST_BLIND=1 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'reason=scanner-blinded'; assert 'S08 弄瞎（树里有真站点）⇒ NOINFO scanner-blinded' "$HAS"
  case "$CUR_EV" in PASS) HAS=0;; *) HAS=1;; esac
  assert 'S08 弄瞎时**不冒绿也不冒红**（evidence 不是 PASS/FAIL）' "$HAS"
  run_case S08b-same-tree-unblinded 1 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'HYGIENE_EVIDENCE=FAIL'; assert 'S08b 同一棵树不弄瞎 ⇒ FAIL（成对：弄瞎确实弄瞎了）' "$HAS"
  rm -f "$DEV"

  # ── S09 临时目录隔离 ＋ S10 覆盖面无泄漏 ─────────────────────────────────
  run_case S09-tmp-isolated 0 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has "HYGIENE_TMPDIR=$SB/tmp/"; assert "S09 临时目录落在 \$TMPDIR=$SB/tmp 之下" "$HAS"
  local leak
  leak="$(find /tmp -maxdepth 1 -name 'hyg-run.*' 2>/dev/null | sed -n '$=')"
  assert 'S10 共享 /tmp 上 hyg-run.* 残留 = 0' "$( [ "${leak:-0}" = 0 ] && echo 1 || echo 0 )"

  # ── S11 总行边界句（"不许声称全域干净"） ─────────────────────────────────
  has 'HYGIENE_BOUNDARY'; assert 'S11 总行带 HYGIENE_BOUNDARY 边界句' "$HAS"
  has 'semantic_undecidable='; assert 'S11 总行带 semantic_undecidable=' "$HAS"
  has 'ext_ext_hits='; assert 'S11 总行带 ext_ext_hits=' "$HAS"

  # ── S12 本件**把 `D-G91` 的教训用在自己身上**：注入引用面 ＋ strict ⇒ 拒绝 ──
  run_case S12-cite-override-strict 2 "$SB/repo" HYG_ANCHORS=strict HYG_MIN_FILES=0 HYG_CITE_ML_ENV="$SB/repo/docs" HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'reason=narrowed-citation-surface'; assert 'S12 注入引用面 ＋ strict ⇒ NOINFO（收窄射程不许打出绿）' "$HAS"

  # ── S13 承重分层可见性：固定 ＋ 证据名但**不在引用面** ⇒ 不判红，但必须点名 ──
  mk_dev_notcited "$UNCITED"
  run_case S13-notcited-visible 0 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'HYGIENE_EVIDENCE=PASS'; assert 'S13 未被引用的同形站点 ⇒ 不判红（PASS）' "$HAS"
  has 'HYGIENE_EVIDENCE_NOTCITED site=devices/uncited.sh:2'; assert 'S13 但不许静默丢掉：逐条点名 NOTCITED' "$HAS"
  has 'not_cited=1'; assert 'S13 NOTJUDGED 行带 not_cited=1（分层计数可见）' "$HAS"
  rm -f "$UNCITED"

  # ── S14 血案形态：目标落在**登记承重证据根**下 ⇒ 必红（即使引用面没提它） ────
  mk_dev_armlog "$ARMLOG"
  run_case S14-evidence-root 1 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'HYGIENE_EVIDENCE=FAIL'; assert 'S14 落在登记承重证据根下 ⇒ FAIL（血案形态）' "$HAS"
  has 'under-evidence-root'; assert 'S14 判词写明承重依据（under-evidence-root）' "$HAS"
  rm -f "$ARMLOG"

  # ── S16 第四类（`W120A`）：硬链接 × 原地写 ⇒ 必红；改成 temp＋rename ⇒ 回绿 ──
  mkdir -p "$SB/fixture1" "$SB/repo/build/MilBridge/tools"
  printf '%s\n' '{"gen":"#51"}' > "$SB/repo/build/MilBridge/known-red.json"
  ln -f "$SB/repo/build/MilBridge/known-red.json" "$SB/fixture1/known-red.json"    # **真硬链接**
  WRT="$SB/repo/build/MilBridge/tools/repin-generation.py"
  WRITERS_FX="build/MilBridge/known-red.json|build/MilBridge/tools/repin-generation.py|open(REG, \"w\"|os.replace("
  mk_writer_inplace "$WRT"
  run_case S16a-inplace-cross-link 1 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" \
    HYG_EXT_ROOTS_ENV='' HYG_FIXTURE_ROOTS_ENV="$SB/fixture1" HYG_WRITERS_ENV="$WRITERS_FX" HYG_TWINS_ENV=''
  has 'HYGIENE_INODE=FAIL'; assert 'S16a 跨区同 inode × 原地写 ⇒ HYGIENE_INODE=FAIL' "$HAS"
  has 'HYGIENE_INODE_FAIL file=build/MilBridge/known-red.json'; assert 'S16a 逐处点名（件 ＋ 写者 ＋ form）' "$HAS"
  mk_writer_rename "$WRT"
  run_case S16b-temp-rename 0 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" \
    HYG_EXT_ROOTS_ENV='' HYG_FIXTURE_ROOTS_ENV="$SB/fixture1" HYG_WRITERS_ENV="$WRITERS_FX" HYG_TWINS_ENV=''
  has 'HYGIENE_INODE=PASS'; assert 'S16b 同一对硬链接 ＋ temp＋rename ⇒ 回绿（成对）' "$HAS"
  has 'HYGIENE_INODE_MULTILINK file=build/MilBridge/known-red.json'; assert 'S16b 但 links>1 **仍打印**（证的是"原地写"不是"看见 links>1 就红"）' "$HAS"
  mk_writer_neither "$WRT"
  run_case S16c-writer-form-unconfirmed 2 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" \
    HYG_EXT_ROOTS_ENV='' HYG_FIXTURE_ROOTS_ENV="$SB/fixture1" HYG_WRITERS_ENV="$WRITERS_FX" HYG_TWINS_ENV=''
  has 'reason=writer-form-unconfirmed'; assert 'S16c 写盘形态两种字面量都没有 ⇒ NOINFO（不许猜）' "$HAS"
  rm -f "$SB/fixture1/known-red.json" "$SB/repo/build/MilBridge/known-red.json" "$WRT"

  # ── S17 第四类：夹具根一个都不在 ⇒ NOINFO（不冒绿） ─────────────────────────
  run_case S17-fixture-roots-missing 2 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" \
    HYG_EXT_ROOTS_ENV='' HYG_FIXTURE_ROOTS_ENV="$SB/nonexistent-fixture" HYG_WRITERS_ENV="$WRITERS_FX" HYG_TWINS_ENV=''
  has 'HYGIENE_INODE=NOINFO'; assert 'S17 夹具根全缺 ⇒ HYGIENE_INODE=NOINFO' "$HAS"
  has 'fixture-roots-missing'; assert 'S17 点名 reason=fixture-roots-missing' "$HAS"

  # ── S18 第四类：注入"区定义"＋ strict ⇒ 拒绝（D-G91 教训用在自己身上） ─────
  run_case S18-fixture-roots-override-strict 2 "$SB/repo" HYG_ANCHORS=strict HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" \
    HYG_EXT_ROOTS_ENV='' HYG_FIXTURE_ROOTS_ENV="$SB/fixture1" HYG_WRITERS_ENV="$WRITERS_FX" HYG_TWINS_ENV=''
  has 'narrowed-citation-surface'; assert 'S18 注入区定义 ＋ strict ⇒ NOINFO（收窄射程不许打绿）' "$HAS"

  # ── S15 全绿基线：夹具（都修好）⇒ 三项都到位 ─────────────────────────────
  run_case S15-fixture-all-clean 0 "$SB/repo" HYG_ANCHORS=off HYG_MIN_FILES=0 HYG_PAIRS_ENV="$PAIRS" HYG_EXT_ROOTS_ENV=''
  has 'HYGIENE_TOOTH=PASS'; assert 'S15 夹具全干净 ⇒ HYGIENE_TOOTH=PASS' "$HAS"
  has 'scope=REPORT'; assert 'S15 且总行 scope=REPORT（不是 PASS）' "$HAS"

  say "HYGIENE_SELFTEST_SELF self=$SELF sha16=$(self_sha16)"
  say "HYGIENE_SELFTEST_ROSTER sandbox=$SB cases=$total pass=$pass fail=$fail not-as-expected=$nae tmpbase=$SB/tmp"
  if [ "$fail" -ne 0 ]; then
    say "HYGIENE_SELFTEST_SANDBOX=$SB（保留供诊断；rm -rf 自行清理）"
    say "HYGIENE_SELFTEST=FAIL total=$total pass=$pass fail=$fail"
    return 1
  fi
  rm -rf "$SB"
  say "HYGIENE_SELFTEST=PASS total=$total pass=$pass fail=0"
  return 0
}
# ── 入口 ─────────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2;;
    --strict-ext) STRICT_EXT=1; shift;;
    --list-sites) WANT_SITES=1; shift;;
    --list-cases) WANT_CASES=1; shift;;
    --debug-tmp) DEBUG_TMP=1; KEEP_TMP=1; shift;;
    --selftest) run_selftest; exit $?;;
    -h|--help) usage; exit 0;;
    *) say "HYGIENE_TOOTH=NOINFO reason=bad-arg arg=$1 rc=2"; exit 2;;
  esac
done
main_run
exit $?
