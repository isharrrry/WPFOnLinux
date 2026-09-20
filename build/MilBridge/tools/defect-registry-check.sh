#!/usr/bin/env bash
# defect-registry-check.sh —— 缺陷编号（`D-*`）登记出处的「机器对账」（在册、**只读**；不跑任何 harness、零 `dotnet`）
#
# 起因（`D-G15`，登记处 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:1088`）：缺陷编号的**登记地点分散**
#   —— `KNOWN-DEFECTS.md` / `docs/CURRENT-STATE.md` 各记一部分，**没有单一权威** ⇒ 引用者按错文件
#   去找会找不到。本脚本补这个洞：把「每个编号**必须**出现在哪个文件」**声明化**，然后逐条核。
#
# 判据（三档，**绝不把"没声明"当绿**）：
#   ① 声明文件缺失 / 解析后 0 条              ⇒ DEFREG=NOINFO reason=no-declaration
#   ② 声明里有畸形行（非注释非空、非 `ID<TAB>…`、编号不合词法、`req=` 不是 route 键集合）
#                                             ⇒ DEFREG=NOINFO reason=decl-unparsable（**不许当红也不许当绿**）
#   ③ 声明里 `req=K1,K2` 的编号，在某一个 K 的 route 文件里**一次都没出现**
#                                             ⇒ DEFREG=FAIL reason=declared-id-missing-in-route（**逐个点名**）
#   ④ route 文件里出现、而声明里没有的编号      ⇒ DEFREG=FAIL reason=undeclared-id-in-route（**逐个点名**）
#   ⑤ 只在 route 文件**之外**（`known-red*.json` / 报告 / 代码注释）出现的未声明编号
#                                             ⇒ DEFREG=NOINFO reason=id-only-outside-registry（未登记，不许当绿）
#   ⑥ 声明自洽校验：`present=` 与现场不符，或 `present ⊄ req`
#                                             ⇒ DEFREG=FAIL reason=decl-meta-inconsistent
#   ⑦ 全过 ⇒ DEFREG=PASS
#
# rc：**只有 DEFREG=PASS 才 rc=0**；FAIL ⇒ rc=1；NOINFO ⇒ rc=2
#     （"没声明/未登记"必须出声、不许静默绿，也**不许冒充红** —— 与 `baseline-sha-check.sh:14` 同一条纪律）
#
# 本脚本**照 `build/MilBridge/tools/baseline-sha-check.sh`（`5836b8296b2e4245`）的形态抄**，逐条对应：
#   · `:19`     `set -uo pipefail`（**不用 `-e`**；全程不用 `printf|grep -q` 形态）      → 本件同法
#     ⏪ **`#32` 主控更正（纪律 61「加注不覆盖」：上面那句原文一字未动）**：那句在 `#27`–`#31` 期间
#       是**伪证** —— 本件实测有 **4 处** `printf '%s' "<多行串>" | grep -q…` 形态（`:206`/`:215`
#       是**多行串**）。机制（`#32` W32C 取到、主控独立复现）：**bash 的 `printf '%s'` 对多行串
#       「每行一次 `write()`」**（`strace` 实测 449 B/75 行 → 52 次 `write`），而 `grep -q` 命中
#       第一行就**退出并关闭读端** ⇒ printf 的下一次 `write()` 吃 **EPIPE→SIGPIPE** ⇒ 在
#       `set -o pipefail` 下整条管线报 **141（非 0）** ⇒ `||` 分支被触发 ⇒ **一个确实写在声明表里
#       的编号被判成"未声明"** ⇒ `DEFREG=FAIL reason=undeclared-id-in-route`（**伪红**）。
#       **不需要任何写者**：`load1≈7.8` 的静树上实测 **40 趟里 20 趟 FAIL ＋ 1 趟 NOINFO**，
#       点名过 **18 个编号、全部都在声明表里**（`#31` 记的"静树 60/60 不复现"是**低负载窗口**的性质，
#       不是本件的性质 ⇒ 那条结论已在 `#32` 块里更正）。
#       **修法**：全部改成 here-string（`grep -q… <<< "$x"` / `awk … <<< "$x"`）—— **零 SIGPIPE**。
#       同族前科：`#26` W26C 在 `check-applocal-sync.sh` 的 M 段实测 ≈6.6%/趟，同样改用 `<<<`。
#   · `:21-25`  `HERE`/`R` 由脚本位置推仓根 + `BSC_*` 环境变量做**沙箱替换**            → 本件 `DRC_*`
#   · `:29-31`  三态变量先置 `NOINFO`、**输入件缺失立刻出 NOINFO 并 return 1**          → 本件 `load_decl()`
#   · `:36-51`  `grep -m1 '^[> ]*KEY '` 取机器行；取不到 ⇒ NOINFO；解析不出 ⇒ NOINFO    → 本件 `^ID<TAB>` 行
#   · `:62-64`  **自吐 `KEY=VALUE` 结论行**（`BASELINESHA=`/`BASELINEGEN=`/`BASELINE_BYTES=`）
#                                                                                      → 本件 `DEFREG=`/`DEFREG_*`
#   · `:79-80`  只有全部子项 PASS 才 `return 0`，否则 `return 1`                       → 本件 `verdict()`
#   · `:83-134` `--selftest`：`mktemp -d` + `trap rm -rf` 造沙箱；**每例必须含反极性**
#               （`:120-131` 的 A…F：1 正 + 4 反 + 1 NOINFO）；`:133-134` 汇总行 + 只在全过时 `exit 0`
#                                                                                      → 本件 `--selftest` 同法
#   · `:115-119` 反极性的**扰动必须是"必然不同"的构造**（旧构造只有 15 位 ⇒ 只证出 NOINFO）
#                                                                                      → 本件改**真实编号**，可重放
#   · `:66-77`  额外立了一条"禁止散文式声明"的独立子项（`BASELINEDUP`）                → 本件 `present ⊄ req` 子项
#
# 本件**只交付、不接线**（`#27` 写域约定：`verify-all.sh` 属 W27B）⇒ 接线锚文本见 `build/MilBridge/W27D-report.md` §6。
# 写域 = 本文件 + `build/MilBridge/tools/defect-registry-declared.tsv`（同趟新建）+ `$HOME/w27d-*`。
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="$(cd "$HERE/../../.." && pwd)"

DECL="${DRC_DECL:-$HERE/defect-registry-declared.tsv}"
KD="${DRC_KD:-$R/samples/WpfFeatureProbe/KNOWN-DEFECTS.md}"
CS="${DRC_CS:-$R/docs/CURRENT-STATE.md}"
HO="${DRC_HO:-$R/handoff.md}"
AB="${DRC_AB:-$R/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md}"
KRJ="${DRC_KRJ:-$R/build/MilBridge/known-red.json}"
KRF="${DRC_KRF:-$R/build/MilBridge/known-red-frame-structural.md}"
KRP="${DRC_KRP:-$R/build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md}"

# 编号词法：D-<scope>[digits][lowercase](-<seg>)*    seg = [A-Za-z0-9]+
#   收：D-G2 D-G14 D-F1b D-T2-c D-T5-R D-A2-r
#   不收（实测假阳性）：`D-PARTY-NOTICES`（段无数字且全大写，338 命中，全是许可文件名）、
#     `D-Bus`（混合大小写）、`D-C`（upstream/…/StrokeNodeOperations2.cs:216 的数学式 `C+s(D-C)`）
FAMRE='D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*'
TOKRE="\\b$FAMRE\\b"
FULLRE="^$FAMRE\$"

# 声明里允许用的键 = KD/CS/HO/AB（route）+ KRJ/KRF/KRP（非 route 的登记件，只许出现在 present=）
route_path() { case "$1" in KD) printf '%s' "$KD";; CS) printf '%s' "$CS";; HO) printf '%s' "$HO";; AB) printf '%s' "$AB";; *) return 1;; esac; }
sha16() { [ -f "$1" ] && sha256sum "$1" | cut -c1-16 || printf '%s' 'MISSING'; }

scan_file() { [ -f "$1" ] || return 0; grep -noE "$TOKRE" "$1" 2>/dev/null || true; }
ids_of()    { scan_file "$1" | sed 's/^[0-9]*://' | sort -u; }
line_of()   { scan_file "$1" | awk -F: -v w="$2" '$2==w {print $1; exit}'; }

# 【取数一次性化】把 7 个登记件**各扫一遍**，建三张表：
#   ID2LINE["key:id"]  = 首次出现行号      （读法：与 `ids_of` 同一支 grep，口径不会分叉）
#   IDS_BY_KEY["key"]  = 该件里的编号（空格分隔，已排序去重）
#   KEY_SHA["key"]     = 该件 sha16
# ⚠️ 为什么必须一次性化：首版用 `line_of`（每次对 1 MB 的 `handoff.md` 重扫一遍）⇒ 53 个编号 ×
#    4 个 route 键 × 每键还要 `ids_of` ⇒ 自测 10 例跑不完（真被 60 s 超时杀掉）。**判据未改，只改取数。**
declare -A ID2LINE=() IDS_BY_KEY=() KEY_SHA=()
ALLKEYS='KD CS HO AB KRJ KRF KRP'
key_path() {
  case "$1" in
    KD) printf '%s' "$KD";; CS) printf '%s' "$CS";; HO) printf '%s' "$HO";; AB) printf '%s' "$AB";;
    KRJ) printf '%s' "$KRJ";; KRF) printf '%s' "$KRF";; KRP) printf '%s' "$KRP";; *) return 1;;
  esac
}
load_maps() {
  local k p
  ID2LINE=(); IDS_BY_KEY=(); KEY_SHA=()
  for k in $ALLKEYS; do
    p="$(key_path "$k")" || continue
    KEY_SHA["$k"]="$(sha16 "$p")"
    local lst=''
    if [ -f "$p" ]; then
      while IFS=: read -r ln id; do
        [ -n "$id" ] || continue
        [ -n "${ID2LINE["$k:$id"]:-}" ] || ID2LINE["$k:$id"]="$ln"
        lst="$lst $id"
      done <<< "$(grep -noE "$TOKRE" "$p" 2>/dev/null || true)"
    fi
    IDS_BY_KEY["$k"]="$(printf '%s' "$lst" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')"
  done
}

load_decl() { [ -f "$DECL" ] || return 1; grep -v '^#' "$DECL" | grep -v '^[[:space:]]*$' || true; }

# ─────────────────────────── 现场重生成声明（机械维护 ⇒ 不是"又一份手工清单"） ───────────────────────────
emit_decl() {
  local id k req pres all
  load_maps
  all="$( { for k in $ALLKEYS; do printf '%s' "${IDS_BY_KEY["$k"]}"; done; } | tr ' ' '\n' | grep -v '^$' | sort -u )"
  printf '# DECL-GEN = (--emit) %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
  printf '# DECL-ANCHORS = KD=%s CS=%s HO=%s AB=%s KRJ=%s KRF=%s KRP=%s\n' \
    "${KEY_SHA[KD]}" "${KEY_SHA[CS]}" "${KEY_SHA[HO]}" "${KEY_SHA[AB]}" "${KEY_SHA[KRJ]}" "${KEY_SHA[KRF]}" "${KEY_SHA[KRP]}"
  printf '# grammar: %s\n' "$FAMRE"
  printf '# fields:  ID<TAB><id><TAB>req=<key,key,...|-><TAB>present=<key,key,...>\n'
  printf '# 词法边界（实测）：D-ZZ9 **不合法**（scope 段只许"1 个大写字母 + 数字量词 + 可选 1 个小写"）\n'
  printf '#   ⇒ 若真需要多位大写 scope，必须**同时**改 FAMRE 与本节说明（否则声明会被判 decl-unparsable）\n'
  printf '#   req=K1,K2  ⇒ 该编号在 K1 与 K2 的 route 文件里**各至少出现一次**（缺一个即 FAIL 点名）\n'
  printf '#   req=-      ⇒ **家族名/scaffold**（如 `D-G`、`D-T`），不要求在缺陷册里有条目\n'
  printf '#   present=   ⇒ 仅"声明依据"（现场快照的并集），**不作判据**；与 `req` 冲突会被判 FAIL\n'
  for id in $all; do
    req=''; pres=''
    for k in KD CS HO AB; do [ -n "${ID2LINE["$k:$id"]:-}" ] && req="$req${req:+,}$k"; done
    [ -z "$req" ] && req='-'
    for k in $ALLKEYS; do [ -n "${ID2LINE["$k:$id"]:-}" ] && pres="$pres${pres:+,}$k"; done
    [ -z "$pres" ] && pres='-'
    printf 'ID\t%s\treq=%s\tpresent=%s\n' "$id" "$req" "$pres"
  done
}

# ─────────────────────────── 判据 ───────────────────────────
# 打印全部 `DEFREG*` 行；rc：0=PASS 1=FAIL 2=NOINFO
run_check() {
  local decl; decl="$(load_decl)" || { echo 'DEFREG=NOINFO reason=no-declaration decl-file-missing decl='"$DECL"; return 2; }
  if [ -z "$decl" ]; then echo 'DEFREG=NOINFO reason=no-declaration（声明文件存在但解析后 0 行）decl='"$DECL"; return 2; fi

  load_maps   # 取数一次性化（见 load_maps 注释）
  local bad='' line id req n_decl=0
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue;; esac
    n_decl=$((n_decl+1))
    if [ "$(printf '%s' "$line" | cut -f1)" != 'ID' ]; then bad="$bad
  malformed-line: $line"; continue; fi
    id="$(printf '%s' "$line" | cut -f2)"
    req="$(printf '%s' "$line" | cut -f3 | sed 's/^req=//')"
    grep -qE "$FULLRE" <<< "$id" || { bad="$bad
  bad-id: $id"; continue; }
    # req 键集合：任一侧含非键 ⇒ 畸形（`D-ZZZ9/nope` 那类）
    { [ "$req" = '-' ] || grep -qE '^[A-Z][A-Z0-9]*(,[A-Z][A-Z0-9]*)*$' <<< "$req"; } || { bad="$bad
  bad-req: $id req=$req"; continue; }
    if [ "$req" != '-' ]; then
      for _k in ${req//,/ }; do
        case "$_k" in KD|CS|HO|AB) ;; *) bad="$bad
  unknown-req-key: $id req=$req key=$_k";; esac
      done
    fi
  done <<< "$decl"
  if [ -n "$bad" ]; then printf 'DEFREG=NOINFO reason=decl-unparsable%s\n' "$bad"; return 2; fi
  if [ "$n_decl" -eq 0 ]; then echo 'DEFREG=NOINFO reason=no-declaration（0 条 `ID<TAB>` 行）'; return 2; fi

  local declared; declared="$(printf '%s' "$decl" | grep '^ID	' | cut -f2 | sort -u)"
  local missing='' undecl='' meta='' k p fid fl

  # ②/③ 声明 ⇒ 现场；并核 `present=` 的**真实性**（照 baseline-sha-check.sh:66-77 的"独立子项"做法）：
  #    判据 = ① 声明的 `present=` 里列出的每一个键，现场**确实**有该编号（否则声明是伪证 ⇒ 点名 FAIL）；
  #           ② 声明的 `req=` 里列出的每一个键，都必须**在 `present=` 里出现**（"要求它在 X 里"却
  #              又不在依据里 ⇒ 声明自相矛盾 ⇒ 点名 FAIL）。
  #    ⚠️ **不**要求 `present == live`：沙箱/反极性会给现场**新增**出现点（那正是未声明路径要抓的），
  #       "多出来的出现点"由 ④ 管，不归本条 —— 两条判据问的是两件事，混在一起会让 ④ 永远够不着。
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    req="$(awk -F'\t' -v w="$id" '$1=="ID"&&$2==w {print $3; exit}' <<< "$decl" | sed 's/^req=//')"
    local pres; pres="$(awk -F'\t' -v w="$id" '$1=="ID"&&$2==w {print $4; exit}' <<< "$decl" | sed 's/^present=//')"
    local live=''
    for k in $ALLKEYS; do [ -n "${ID2LINE["$k:$id"]:-}" ] && live="$live${live:+,}$k"; done
    # ⚠️ `present=` **不进判据**（只出声）—— 它含 `known-red*.json` 这类**会被其它车道改**的件，
    #    若让它判红，并发改仓就会造成**假红**（本件首版正是这样：`#27` W27A 在 17:49 改了
    #    `known-red.json` ⇒ `present` 与实际不符 ⇒ 判 `FAIL`）。本工程铁律：**假红比假绿轻，但它
    #    侵蚀对红数的信任** ⇒ 与 `DEFREG_DECLDRIFT` 同类，降级为**非门禁的诊断行**。
    if [ "$pres" != '-' ]; then
      for k in ${pres//,/ }; do
        case ",$live," in *",$k,"*) ;; *) meta="$meta
  $id present-claims=$k BUT-not-live live=$live";; esac
      done
    fi
    if [ "$req" != '-' ]; then
      for k in ${req//,/ }; do
        case ",$pres," in *",$k,"*) ;; *) meta="$meta
  $id req=$k NOT-IN-present=$pres";; esac
      done
    fi
    [ "$req" = '-' ] && continue
    for k in ${req//,/ }; do
      p="$(key_path "$k")"
      [ -f "$p" ] || { missing="$missing
  $id req=$k ROUTE-FILE-MISSING=$p"; continue; }
      [ -n "${ID2LINE["$k:$id"]:-}" ] || missing="$missing
  $id req=$k MISSING-IN=$k route=$p"
    done
  done <<< "$declared"

  # ④ route 文件里未声明的编号
  for k in KD CS HO AB; do
    p="$(key_path "$k")"
    [ -f "$p" ] || continue
    for id in ${IDS_BY_KEY["$k"]}; do
      grep -qxF "$id" <<< "$declared" || undecl="$undecl
  $id first-seen=$k:${ID2LINE["$k:$id"]} route=$p"
    done
  done

  # ⑤ 只在 route 之外出现的未声明编号（非 route 的登记件）
  local outside='' o
  o="$( { printf '%s' "${IDS_BY_KEY[KRJ]}"; printf '%s' "${IDS_BY_KEY[KRF]}"; printf '%s' "${IDS_BY_KEY[KRP]}"; } | tr ' ' '\n' | grep -v '^$' | sort -u )"
  for id in $o; do
    grep -qxF "$id" <<< "$declared" || outside="$outside $id"
  done
  local n_route; n_route="$( { for k in KD CS HO AB; do printf '%s\n' "${IDS_BY_KEY["$k"]}" | tr ' ' '\n'; done; } | grep -v '^$' | sort -u | grep -c . )"

  echo "DEFREG_DECL=n=$n_decl route_ids=$n_route grammar=$FAMRE"
  echo "DEFREG_ROUTES=KD=${KEY_SHA[KD]} CS=${KEY_SHA[CS]} HO=${KEY_SHA[HO]} AB=${KEY_SHA[AB]}"
  echo "DEFREG_EXTRA=KRJ=${KEY_SHA[KRJ]} KRF=${KEY_SHA[KRF]} KRP=${KEY_SHA[KRP]}"
  local anchors; anchors="$(grep -m1 '^# DECL-ANCHORS = ' "$DECL" 2>/dev/null | sed 's/^# DECL-ANCHORS = //')"
  local drift='?'
  if [ -n "$anchors" ]; then
    drift=0
    for k in $ALLKEYS; do
      local want; want="$(printf '%s' "$anchors" | sed -n "s/.*$k=\([0-9a-f]\{16\}\).*/\1/p")"
      [ -n "$want" ] && [ "$want" != "${KEY_SHA["$k"]}" ] && drift=$((drift+1))
    done
  fi
  echo "DEFREG_DECLDRIFT=$drift changed-route-files-since-DECL-GEN"
  [ -n "$outside" ] && echo "DEFREG_UNREG=n=$(printf '%s' "$outside" | wc -w) ids=$(printf '%s' "$outside" | sed 's/^ //')"

  # 判定顺序是**判据的一部分**（不许依赖它"恰好"命中哪一条）：
  #   缺号（声明⇒现场） > 未声明（现场⇒声明） > 声明自身的 `present=` 不诚实 > 只在 route 之外
  [ -n "$meta" ] && printf 'DEFREG_DECLMETA=n=%s declared-present-not-matching-live（诊断，**不判红**）:%s\n' "$(printf '%s' "$meta" | grep -c .)" "$meta"
  [ -n "$missing" ] && { printf 'DEFREG=FAIL reason=declared-id-missing-in-route%s\n' "$missing"; return 1; }
  [ -n "$undecl" ]  && { printf 'DEFREG=FAIL reason=undeclared-id-in-route%s\n' "$undecl"; return 1; }
  [ -n "$outside" ] && { echo 'DEFREG=NOINFO reason=id-only-outside-registry（只在 route 之外出现的未声明编号 ⇒ 未登记，**不许当绿**）'; return 2; }
  echo "DEFREG=PASS declared=$n_decl route_ids=$n_route（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）"
  return 0
}

# ─────────────────────────── 反极性自测 ───────────────────────────
if [ "${1:-}" = '--selftest' ]; then
  # ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、不许冒充红）──
  #   本件自测以 `"$0"` **重入自己**（`:295`）⇒ bash 每次为新子进程从磁盘**重读**本件 ⇒ 父进程按旧版造
  #   夹具、子进程按新版判定 ⇒ **改件窗口里出的红是凭空的红** —— **本件就是那个现场**：`#32` W32B 观察到
  #   本件在 347 行/`733c04570d4602f5` → 359 行/`b98b7d8926b275c9` 的改写窗口里 `not-as-expected`=3,1,1,1,1，
  #   改写完成后连跑 9 次全 0（**红窗口 = 改件窗口**）。口径：**开头记 sha16、结尾再算一次**；不等 ⇒
  #   `ST_ATTEST=NOINFO` 并点名（含 sha0/sha1 与内层 rc），统一 **rc=2**（`NOINFO` 码，不与 `FAIL` 混）。
  #   只加在 `--selftest` 路径；**生产路径一字未动**；不删例、不放宽任何期望（成对读数见 `$HOME/w33b-report.md`）。
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
  np=0; nf=0; nno=0
  # ── 沙箱：**合成 fixture**，由声明本身推导 ⇒ 自测**与仓的漂移无关**（可重放；不硬链接活件）
  #    （首版用硬链接活件 ⇒ `#27` W27A 在测试窗口内改了 `known-red.json`/`KNOWN-DEFECTS.md`
  #      ⇒ 自测在仓漂移时假红。本工程的教训：**自测不许依赖窗口外的可变件**。）
  fixture() {  # $1=名字 → 按 $DECL 造 4 个 route 件：每个件里放进"req 或 present 含该键"的全部编号
    mkdir -p "$T/$1"; local k f
    for k in KD CS HO AB; do
      f="$T/$1/$k"; : > "$f"
      while IFS= read -r id; do
        [ -n "$id" ] || continue
        req="$(printf '%s' "$DECLROWS" | awk -v w="$id" '$1==w {print $2}')"
        pres="$(printf '%s' "$DECLROWS" | awk -v w="$id" '$1==w {print $3}')"
        # ⚠️ 每行**只有**编号本身 ⇒ `grep -vxF <id>` 能逐行精确删（反极性①/⑧ 靠这个）
        case ",$req,$pres," in *",$k,"*) printf '%s\n' "$id" >> "$f";; esac
      done <<< "$DECLSET"
    done
    : > "$T/$1/KRJ"; : > "$T/$1/KRF"; : > "$T/$1/KRP"
    # ── 【`W33B` 加严 · 前提自持断言】（`#32` W32B 的 `§3.2` 设计，本车道**落地并取到成对读数**）──
    #   前提：本件 fixture 的四份 route 件是**从 `$DECLROWS` 现推导**的，而 `decl.tsv` 是**冻结声明**的
    #   现复制 ⇒ 二者**必须同源**。若**活的** `$DECL_LIVE` 在本趟自测窗口内被改写（`--emit` 重生成 /
    #   并发车道编辑）⇒ 本趟读数讲的是"**一份已经不存在的声明**"⇒ 按本工程纪律：**打 `NOINFO` 并点名**
    #   （不是静默红，也不是当绿）。判法用 **sha**（比重解析便宜、且就是"同源"的定义）。
    #   ⚠️ 【第二道牙】`#33` SA2 独立复验提出的两个残余洞，本版**已闭合**：
    #     ① 原版在 `DECLROWS` **之后**才记 `sha0` ⇒ 改写落在两行之间时断言恒等、**假红回来**
    #        （SA2 确定性模拟 `R12`：`FAIL not-as-expected=5`）⇒ 本版**先冻结再读**（见下），
    #        `sha0` 即**冻结件**的 sha ⇒ 快照与夹具**必同源**（不再依赖"事后发现"）。
    #     ② 原版只给 `NOINFO` ⇒ 并发窗口里**十例一个都不跑**（零覆盖）⇒ 本版**冻结同源**：
    #        `DECLROWS` 与每例的 `decl.tsv` 都出自**同一份冻结件** ⇒ 同源是**构造保证的**，
    #        断言退化为"活件在我脚底下动过没有"的第二道牙（SA2 实测同一扰动下 `PASS 10/10`）。
    local dsha; dsha="$(sha256sum "$DECL_LIVE" 2>/dev/null | cut -c1-16)"
    if [ "$dsha" != "$ST_DECL_SHA0" ]; then
      echo "DRC_SELFTEST=NOINFO reason=fixture-decl-not-same-source（活的 $DECL_LIVE 在本趟自测窗口内被改写：frozen_sha=$ST_DECL_SHA0 live_sha=$dsha ⇒ 本趟十例讲的是冻结件、而现场声明已变 ⇒ 读数不可归因）"
      exit 2
    fi
    cp -p "$DECL" "$T/$1/decl.tsv"
  }
  # 【冻结同源】把声明**只读一次并冻结**（`cp -p`，沙箱内）⇒ 快照与每例的 `decl.tsv` 必同源。
  DECL_LIVE="$DECL"
  DECL="$T/decl-frozen.tsv"; cp -p "$DECL_LIVE" "$DECL"
  ST_DECL_SHA0="$(sha256sum "$DECL" 2>/dev/null | cut -c1-16)"
  # 声明的 (id, req, present) 三元组快照（读的是**冻结件**）
  DECLROWS="$(load_decl | awk -F'\t' '$1=="ID" {print $2"\t"$3"\t"$4}' | sed 's/req=//;s/present=//')"
  DECLSET="$(printf '%s' "$DECLROWS" | cut -f1 | sort -u)"
  # ⚠️ 【`W33B` 加严 · 只加强】声明件缺失/解析后 0 条 ⇒ 旧行为 `DRC_SELFTEST=FAIL reason=no-declaration`（**rc=1**）
  #   把"**仪器缺件**"冒充成"**判据红**"（本件生产路径对同一情形给的是 `DEFREG=NOINFO reason=decl-file-missing` **rc=2**）
  #   ⇒ 按本工程纪律（`D-T5-R`：缺 shim 由 `FAIL` 改 `NOINFO`）改判 **`NOINFO` rc=2** 并点名。
  [ -n "$DECLSET" ] || { echo "DRC_SELFTEST=NOINFO reason=no-declaration（声明件缺件/解析后 0 条 ⇒ 夹具的前提不成立 ⇒ 仪器缺件，不是判据红）file=$DECL_LIVE"; exit 2; }

  # 反极性样本：一个"声明要求它在 KD 里"的编号；与一个"只要求在 HO 里"的编号
  SPECIMEN="$(printf '%s' "$DECLROWS" | awk -F'\t' '$2 ~ /KD/ {print $1; exit}')"
  SPEC2="$(printf '%s' "$DECLROWS" | awk -F'\t' '$2 ~ /HO/ && $2 !~ /KD/ {print $1; exit}')"
  [ -n "$SPECIMEN" ] || { echo 'DRC_SELFTEST=FAIL reason=no-specimen'; exit 1; }

  np=0; nf=0; nno=0; nbad=0; cases=0
  # ⚠️ 逐例谓词**只有这一处**（纪律 53：一个结论值不许有两个来源）：
  #    ok=yes ⇔ 【值 == expect】∧【rc == 三态对应的 0/1/2】∧【（若给了）reason 含 4 参】
  #    汇总的 pass/fail/noinfo **完全由本谓词的 ok 与 expect 现算**，不再另写一遍判据。
  chk() {  # $1=case $2=expect(PASS/FAIL/NOINFO) $3=dir [$4=reason-substr]
    local out rc got reason wantrc ok=no
    out="$(DRC_DECL="$T/$3/decl.tsv" DRC_KD="$T/$3/KD" DRC_CS="$T/$3/CS" DRC_HO="$T/$3/HO" DRC_AB="$T/$3/AB" \
           DRC_KRJ="$T/$3/KRJ" DRC_KRF="$T/$3/KRF" DRC_KRP="$T/$3/KRP" "$0" 2>&1)"; rc=$?
    got="$(sed -n 's/^DEFREG=\([A-Z]*\).*/\1/p' <<< "$out" | head -1)"
    reason="$(sed -n 's/^DEFREG=[A-Z]* reason=\([^ ]*\).*/\1/p' <<< "$out" | head -1)"
    case "$2" in PASS) wantrc=0;; FAIL) wantrc=1;; NOINFO) wantrc=2;; *) wantrc=-1;; esac
    # 子断言逐项写进 %s 供读者核（值 / rc / reason 三项缺一即 no）
    local vok=no rok=no mok='n/a'
    [ "$got" = "$2" ] && vok=yes
    [ "$rc" = "$wantrc" ] && rok=yes
    if [ -n "${4:-}" ]; then mok=no; case "$reason" in *"$4"*) mok=yes;; esac; else mok='-'; fi
    [ "$vok" = yes ] && [ "$rok" = yes ] && { [ "$mok" = 'n/a' ] || [ "$mok" = yes ] || [ "$mok" = '-' ]; } && ok=yes
    cases=$((cases+1))
    if [ "$ok" = yes ]; then
      case "$2" in PASS) np=$((np+1));; FAIL) nf=$((nf+1));; NOINFO) nno=$((nno+1));; esac
    else
      nbad=$((nbad+1))   # 不达预期 ⇒ **只进 nbad**（不改写 pass/fail/noinfo，避免"汇总与逐例不同源"）
    fi
    printf 'SELFTEST case=%s expect=%s got=%s rc=%s(want %s) value=%s rc?=%s reason=%s reason?=%s => %s\n' \
      "$1" "$2" "$got" "$rc" "$wantrc" "$vok" "$rok" "${reason:-none}" "$mok" "$ok"
  }

  fixture A; chk A PASS A                                   # 正极性：声明与 fixture 一致

  fixture B; grep -vxF "$SPECIMEN" "$T/B/KD" > "$T/B/KD.n" && mv "$T/B/KD.n" "$T/B/KD"
     chk B FAIL B declared-id-missing-in-route               # 反极性①：声明点名它在 KD、KD 里没有

  fixture C; printf '### D-X99\n' >> "$T/C/KD"
     chk C FAIL C undeclared-id-in-route                     # 反极性②：route 里新编号、声明里没有

  fixture D; printf '### D-X98\n' >> "$T/D/KRJ"
     chk D NOINFO D id-only-outside-registry                 # 反极性③：只在非 route 件里 ⇒ NOINFO（不绿不红）

  fixture E; : > "$T/E/decl.tsv"
     chk E NOINFO E no-declaration                           # 反极性④：删声明 ⇒ NOINFO

  #    ⚠️ `grep -vxF <id>` 删不掉（声明行 = `ID<TAB><id><TAB>…`，整行匹配永远不中）⇒ 必须按 `^ID<TAB><id><TAB>` 删
  fixture F; grep -vP "^ID\t$SPECIMEN\t" "$T/F/decl.tsv" > "$T/F/decl.n" && mv "$T/F/decl.n" "$T/F/decl.tsv"
     chk F FAIL F undeclared-id-in-route                     # 反极性⑤：声明少一条 ⇒ 现场编号变未声明

  # ⚠️ 编号必须**词法合法**才测得到"仓内不存在"这条 —— 首版用 `D-ZZZ9`，它本身就**不合法**
  #    （scope 段不允许两位大写）⇒ 探针诚实地报 `decl-unparsable`，被误当成"用例没造出来"。
  fixture G; printf 'ID\tD-Z9\treq=KD\tpresent=KD\n' >> "$T/G/decl.tsv"
     chk G FAIL G declared-id-missing-in-route               # 反极性⑥：声明里写仓内不存在的**合法**编号 ⇒ 点名

  fixture H; printf 'ID\tD-G2\treq=NOPE\tpresent=KD\n' >> "$T/H/decl.tsv"
     chk H NOINFO H decl-unparsable                           # 反极性⑦：req 键非法 ⇒ NOINFO（不红不绿）

  if [ -n "$SPEC2" ]; then
    fixture I; grep -vxF "$SPEC2" "$T/I/HO" > "$T/I/HO.n" && mv "$T/I/HO.n" "$T/I/HO"
       chk I FAIL I declared-id-missing-in-route             # 反极性⑧：顾问位（HO）缺 ⇒ 同样点名
  fi

  # 反极性⑨（**反向**用例）：`present=` 与现场不符、但 `req=` 全部满足 ⇒ **必须仍 PASS**。
  #   做法：把 $SPECIMEN 那一行的 `present=` 改成含 `KRJ`（沙箱 KRJ 是空件）⇒ 诊断行出声、判据不变。
  #   ⚠️ 首版把"追加一条新编号"当成本例，那**真的**造出了缺号（`req=KD..` 而 fixture 里没有）⇒ 用例前提错。
  fixture J; sed -i "s|^\(ID\t$SPECIMEN\t.*\)present=.*|\1present=KRJ|" "$T/J/decl.tsv"
     chk J PASS J

  echo "DRC_SELFTEST=$([ "$nbad" -eq 0 ] && echo PASS || echo FAIL) cases=$cases got_pass=$np got_fail=$nf got_noinfo=$nno not-as-expected=$nbad"
  [ "$nbad" -eq 0 ] && exit 0 || exit 1
fi

if [ "${1:-}" = '--emit' ]; then emit_decl; exit 0; fi

run_check
exit $?
