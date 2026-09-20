#!/usr/bin/env bash
# arm-log-sha-check.sh —— 臂日志（**派生件**）的「整份 sha」机器核对（在册、**只读**；不跑 harness、不构建）
#
# 判据（三态，**绝不把"没声明"当绿**）：
#   1) 现场重算 `<logdir>/<臂日志文件名主干>.log` 的 **sha256 全 64 位**
#   2) 与 `build/MilBridge/known-red.json` 的 **`generation.arm_logs`**（**结构化**）逐字比：
#        · 整个 `arm_logs` 缺声明                ⇒ ARMLOG_SHA=NOINFO（没声明 ⇒ 无信息，**不是**"一致"）
#        · 某支必需臂缺声明                      ⇒ 该臂 NOINFO reason=undeclared-required
#        · 声明值 ≠ 64 位小写 hex                ⇒ **FAIL**（防"只比 16 位前缀"退化）
#        · 声明的臂**日志文件不存在**            ⇒ **FAIL**（声明指向不存在的件 = 假声明，不是"无信息"）
#        · 现场 sha ≠ 声明值（逐字，全 64 位）    ⇒ **FAIL**（这正是 `D-G9` 的现场形态：换过日志）
#        · 全部逐字相等                          ⇒ PASS
#
# rc：**只有全 PASS 才 rc=0**；FAIL 与 NOINFO 都 rc=1（"没声明"必须出声，不许静默绿）。
# 反极性自测：--selftest  （**必须能证出"该红的红"**：扰动一位 ⇒ FAIL、前缀+补零 ⇒ FAIL、件缺失 ⇒ FAIL）
# 零构建：全脚本无 `dotnet`、无 MSBuild、不写仓内任何文件（`--selftest` 只写 `mktemp -d` 沙箱）。
#
# ── 起因（`D-G9`，`#25` 登记；`#26` 车道 W26D 落地）────────────────────────────
#   臂日志是**派生件**：它们的内容 sha **不是**世代绑定三项（`GEN_KEYS`）的函数，
#   且门禁**不读**那条散文 `generation.leg_resolution.cross_check`
#   （`grep -c cross_check build/MilBridge/tools/tline-gate.sh` = **0**）
#   ⇒ **换过日志没有任何机器会红**（`#24` 现场：三支 `tab-*` 臂日志被 `ln -f` 换成
#      `424d4c6d…`/`5e4d9ef3…`/`56abc845…`，而散文仍写着 `#23` 的
#      `b9d81590…`/`419e8aaa…`/`1a5bc718…` ⇒ **3/3 逐字不符**）。本脚本补上这个机器读者。
#
# ── 抄了 `baseline-sha-check.sh`（sha16 `5836b8296b2e4245`）的哪些设计（逐条带行号）──
#   · `:19`     `set -uo pipefail`
#   · `:21-22`  `HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` + `R="$(cd "$HERE/../../.." && pwd)"`
#               （**脚本位置反推仓根**，不靠 `$PWD`；这正是门禁 `tline-gate.sh:84-123` 踩过的坑）
#   · `:23-24`  `BASE="${BSC_BASE:-…}"` / `STATE="${BSC_STATE:-…}"` ⇒ 本脚本照抄成
#               `REG="${ALSC_REG:-…}"` / `LOGDIR="${ALSC_LOGDIR:-…}"`（**同一套沙箱覆盖机制**）
#   · `:27`     `run_check() { … }` 一个函数承担全部判定，**正常跑与 `--selftest` 共用它**
#   · `:29`     进函数先把三态变量**置为 NOINFO**（默认不绿）——本脚本 `ARMLOG_SHA=NOINFO`
#   · `:30-31`  缺件 ⇒ `echo 'BASELINESHA=NOINFO reason=baseline-missing'; return 1`
#               ⇒ 本脚本 `ARMLOG_SHA=NOINFO reason=registry-missing`（**缺数据不许静默**）
#   · `:44-51`  抽不出值 ⇒ NOINFO；抽出且相等 ⇒ PASS；抽出但不等 ⇒ FAIL（**三态写法原样照抄**）
#   · `:79-80`  末尾「全 PASS 才 `return 0`，否则 `return 1`」
#   · `:83-135` `--selftest`：`mktemp -d` + `trap 'rm -rf "$T"' EXIT`；`mk()` 造沙箱；
#               `chk()` 逐例打印 `SELFTEST case=… expect=… got=… rc=… => yes/no`；
#               末尾 `SELFTEST=<PASS|FAIL> cases=<n> pass=<p> fail=<f>`；**有 fail 即 rc=1**
#   · `:99-101` 的教训（**声明缺失时会印出两行同名汇总行 ⇒ 抽取必须 `head -1`**）
#              本脚本用**不同前缀**根治：逐臂行 = `ARMLOG_ARM=`、汇总行 = `ARMLOG_SHA=`，
#              全脚本只印**一行** `ARMLOG_SHA=` ⇒ 抽取天然无歧义（比 `head -1` 更硬）。
#   · `:113-119` 的教训（扰动值**必须仍是合法的那个位宽**，否则只证出 NOINFO、没证出 FAIL）
#              ⇒ selftest case B 沿用"换首位字符"；并**额外**加 case D（前 16 位 + 48 个 0）。
#
# ── 与 `baseline-sha-check.sh` 的**有意差异**（如实披露，不藏）──────────────────
#   · 值口径：本脚本比 **64 位全值**（出处 = `build/MilBridge/tests/ShimShaReader/Program.cs:12`
#     「**完整 sha256 逐字相等**才算 `no`（不许只比 16 位前缀：**前缀相等不是内容相等**）」）；
#     对方比的是文档里的 **16 位** `sha16=`。⇒ 本脚本**更严**。
#   · 声明载体：本脚本读 **JSON** 而不是文档散文行 ⇒ 用 `python3` 取键
#     （同一份 JSON，门禁 `tline-gate.sh:208-215` 也是 `python3` 在读，同族做法）。
#   · 逐臂行印 `nlink=`：**信息性，不参与判定**（同族惯例 = 登记表里 `instr_pc` 的"信息性"）。
#     为什么不当判据：`build/MilBridge/arm-logs/README.md:3-6` 要求硬链接，但**源件**
#     （如 `$HOME/wfp-runs/**`）被清理时 nlink 会自然掉到 1、而日志本身没变
#     ⇒ 拿它当判据会产生**假红**（本工程铁律：假红也是缺陷）。
#
# ── 形态兼容 ─────────────────────────────────────────────────────────────────
#   主形态（本波落地，`docs/WAVE26-PREREGISTRATION.md:49` 与 `D-G9` 的 `arm_logs: {tline:…}`）：
#       "arm_logs": { "tline": "<64 hex>", "tab-zero": "<64 hex>", …, }
#   兼容形态（`#25` W25J 草稿 `~/w25j/arm-log-registry.md` 的嵌套式）：
#       "arm_logs": { "logdir": …, "suffix": …, "sha256": { "tline": "<64 hex>", … } }
#   两者都认，`shape=flat|nested` 会印出来（**不静默**）。flat 形态下 `logdir`/`suffix`/`taken_at`/
#   `why`/`how`/`not_covered` 视为元数据（**不参与判定**，也不是臂）。
#
# 用法：
#   bash build/MilBridge/tools/arm-log-sha-check.sh            # 读仓内默认件
#   bash build/MilBridge/tools/arm-log-sha-check.sh --selftest
#   ALSC_REG=<表> ALSC_LOGDIR=<目录> bash …                    # 沙箱覆盖（--selftest 就用它）
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="$(cd "$HERE/../../.." && pwd)"
REG="${ALSC_REG:-$R/build/MilBridge/known-red.json}"
LOGDIR="${ALSC_LOGDIR:-$R/build/MilBridge/arm-logs}"

# 必需臂 = 门禁认臂集合（`build/MilBridge/tools/tline-gate.sh:91` 的 `ARMS=(…)`）；
# 键 = 臂**日志文件名主干**，门禁臂名 ↔ 文件名的映射见 `build/MilBridge/arm-logs/README.md:14-18`。
REQUIRED="tline tab-zero tab-rtl tab-anchor textlineproto"
SUFFIX=".log"

extract() {   # $1 = 登记表路径 ⇒ 机器行（**所有 JSON 解析只在 python3 里做一次**）
  python3 - "$1" <<'PYEOF'
import json, sys
p = sys.argv[1]
ALLOWED_META = {"logdir", "suffix", "taken_at", "why", "how", "not_covered"}
try:
    with open(p, encoding="utf-8") as f:
        j = json.load(f)
except FileNotFoundError:
    print("REGX=NOINFO reason=registry-missing"); sys.exit(0)
except Exception as e:
    print("REGX=NOINFO reason=registry-unreadable:%s" % type(e).__name__); sys.exit(0)
gen = j.get("generation") or {}
al = gen.get("arm_logs")
if al is None:
    print("REGX=NOINFO reason=arm_logs-absent"); sys.exit(0)
if not isinstance(al, dict):
    print("REGX=NOINFO reason=arm_logs-not-a-dict:%s" % type(al).__name__); sys.exit(0)
shape = "nested" if isinstance(al.get("sha256"), dict) else "flat"
print("REGX=OK shape=%s" % shape)
for k, v in al.items():
    if shape == "nested" and k == "sha256":
        continue
    if isinstance(v, str) and k in ALLOWED_META:
        print("META\t%s\t%s" % (k, v))
    elif isinstance(v, str):
        print("DECL\t%s\t%s" % (k, v))      # 逐臂核对（含 64 位检查）在 bash 里做
    else:
        print("BADMETA\t%s\t%s" % (k, type(v).__name__))
if shape == "nested":
    for k, v in al["sha256"].items():
        print("DECL\t%s\t%s" % (k, v if isinstance(v, str) else "<non-str>"))
PYEOF
}

run_check() {   # $1=登记表 $2=日志目录（$1 里的 logdir 元数据可覆盖 $2）
  local reg="$1" logdir="$2"
  local out shape="" ld="" npass=0 nfail=0 nnoinfo=0 ndec=0 rc=1
  ARMLOG_SHA=NOINFO

  out="$(extract "$reg")" || out="REGX=NOINFO reason=extract-failed"
  local regx; regx="$(printf '%s\n' "$out" | sed -n 's/^REGX=\([A-Z]*\).*/\1/p')"
  if [ "$regx" != "OK" ]; then
    echo "ARMLOG_SHA=NOINFO $(printf '%s\n' "$out" | sed -n 's/^REGX=[A-Z]* //p') reg=$reg"
    return 1
  fi
  shape="$(printf '%s\n' "$out" | sed -n 's/^REGX=OK shape=\(.*\)$/\1/p')"
  ld="$(printf '%s\n' "$out" | awk -F'\t' '$1=="META" && $2=="logdir" {print $3}')"
  [ -n "$ld" ] || ld="$logdir"

  local badmeta; badmeta="$(printf '%s\n' "$out" | awk -F'\t' '$1=="BADMETA" {printf "%s:%s;", $2, $3}')"
  if [ -n "$badmeta" ]; then
    echo "ARMLOG_SHA=FAIL reason=decl-non-string-value shape=$shape logdir=$ld bad=[$badmeta]"
    return 1
  fi

  # ── 逐**声明**臂核对（不限于必需集合：多声明的也照核；不许静默忽略任何声明）──
  local tag stem val f live nl
  while IFS=$'\t' read -r tag stem val; do
    [ "$tag" = "DECL" ] || continue
    ndec=$((ndec+1))
    f="$ld/$stem$SUFFIX"
    case "$val" in
      *[!0-9a-f]*|"")
        echo "ARMLOG_ARM=$stem FAIL reason=decl-not-64hex decl=$(printf '%s' "$val" | cut -c1-24) len=${#val}"
        nfail=$((nfail+1)); continue ;;
    esac
    if [ "${#val}" -ne 64 ]; then
      echo "ARMLOG_ARM=$stem FAIL reason=decl-not-64hex decl=$(printf '%s' "$val" | cut -c1-24) len=${#val}"
      nfail=$((nfail+1)); continue
    fi
    if [ ! -f "$f" ]; then
      echo "ARMLOG_ARM=$stem FAIL reason=log-missing file=$f decl=$(printf '%s' "$val" | cut -c1-16)"
      nfail=$((nfail+1)); continue
    fi
    live="$(sha256sum "$f" | cut -d' ' -f1)"
    nl="$(stat -c %h "$f" 2>/dev/null || echo '?')"
    if [ "$live" = "$val" ]; then
      echo "ARMLOG_ARM=$stem PASS decl=$(printf '%s' "$val" | cut -c1-16) live=$(printf '%s' "$live" | cut -c1-16) nlink=$nl"
      npass=$((npass+1))
    else
      echo "ARMLOG_ARM=$stem FAIL reason=sha-mismatch decl=$(printf '%s' "$val" | cut -c1-16) live=$(printf '%s' "$live" | cut -c1-16) nlink=$nl"
      nfail=$((nfail+1))
    fi
  done <<< "$out"

  # ── 必需臂里**没被声明**的 ⇒ NOINFO（缺声明 = 无信息，**不是**一致）──
  local a d st miss=""
  for a in $REQUIRED; do
    st=0
    for d in $(printf '%s\n' "$out" | awk -F'\t' '$1=="DECL" {print $2}'); do
      [ "$d" = "$a" ] && st=1 && break
    done
    if [ "$st" -eq 0 ]; then
      echo "ARMLOG_ARM=$a NOINFO reason=undeclared-required"
      miss="$miss $a"; nnoinfo=$((nnoinfo+1))
    fi
  done

  if [ "$nfail" -gt 0 ]; then
    echo "ARMLOG_SHA=FAIL shape=$shape logdir=$ld required=5 declared=$ndec pass=$npass fail=$nfail noinfo=$nnoinfo"
  elif [ "$nnoinfo" -gt 0 ]; then
    echo "ARMLOG_SHA=NOINFO reason=undeclared-required:[${miss# }] shape=$shape logdir=$ld required=5 declared=$ndec pass=$npass fail=$nfail noinfo=$nnoinfo"
  elif [ "$npass" -gt 0 ]; then
    echo "ARMLOG_SHA=PASS shape=$shape logdir=$ld required=5 declared=$ndec pass=$npass fail=$nfail noinfo=$nnoinfo"
  else
    echo "ARMLOG_SHA=NOINFO reason=no-declared-arms shape=$shape logdir=$ld"
  fi
  [ "$nfail" -eq 0 ] && [ "$nnoinfo" -eq 0 ] && [ "$npass" -gt 0 ] && rc=0
  return $rc
}

if [ "${1:-}" = '--selftest' ]; then
  # ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、不许冒充红）──
  #   本件自测以 `"$0"` **重入自己**（`:221`）⇒ bash 每次为新子进程从磁盘**重读**本件 ⇒ 父进程按旧版造
  #   夹具、子进程按新版判定 ⇒ **改件窗口里出的红是凭空的红**（`#32` W32B 现场：`not-as-expected`=3,1,1,1,1
  #   落在 347→359 行的改写窗口内，改写之后连跑 9 次全 0）。口径：**开头记 sha16、结尾再算一次**；不等 ⇒
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
  np=0; nf=0
  REQ="tline tab-zero tab-rtl tab-anchor textlineproto"

  mklogs() { mkdir -p "$1"; local tag="${2:-}"; for a in $REQ; do printf 'sandbox-log-%s%s\n' "$tag" "$a" > "$1/$a.log"; done; }
  live_of() { sha256sum "$1/$2.log" | cut -d' ' -f1; }

  # flat 形态声明块；$1=目标文件 $2=logdir（**绝对路径**）… 之后可跟 "stem:override"
  emit_flat() {
    local f="$1" ld="$2"; shift 2
    local a v ov first=1
    {
      printf '{\n  "generation": {\n    "instr_shim": "x",\n    "arm_logs": {\n'
      for a in $REQ; do
        ov=""; for o in "$@"; do [ "${o%%:*}" = "$a" ] && ov="${o#*:}"; done
        v="${ov:-$(live_of "$ld" "$a")}"
        [ "$first" -eq 1 ] || printf ',\n'
        first=0
        printf '      "%s": "%s"' "$a" "$v"
      done
      printf '\n    }\n  },\n  "entries": [{"x":1}]\n}\n'
    } > "$f"
  }

  chk() {  # $1=case $2=expect $3=reg $4=logdir
    local out got rc ok='no'
    out="$(ALSC_REG="$3" ALSC_LOGDIR="$4" "$0" 2>&1)"; rc=$?
    got="$(printf '%s\n' "$out" | sed -n 's/^ARMLOG_SHA=\([A-Z]*\).*/\1/p')"
    [ "$got" = "$2" ] && ok='yes'
    # 断言 PASS 时必须 rc=0；断言 FAIL/NOINFO 时 rc **必须非 0**（扣住"不许静默绿"）
    if [ "$2" = PASS ]; then [ "$rc" -eq 0 ] || ok='no'; else [ "$rc" -ne 0 ] || ok='no'; fi
    [ "$ok" = yes ] && np=$((np+1)) || nf=$((nf+1))
    printf 'SELFTEST case=%s expect=%s got=%s rc=%s => %s\n' "$1" "$2" "$got" "$rc" "$ok"
    printf '%s\n' "$out" | grep -a '^ARMLOG_ARM=' | sed 's/^/         /'
  }
  die() { echo "ALSC_SELFTEST=FAIL reason=$1"; exit 1; }
  flip1() { case "${1:0:1}" in 0) printf '1%s' "${1:1}";; *) printf '0%s' "${1:1}";; esac; }
  zeros48() { printf '%s' "${1:0:16}"; printf '0%.0s' $(seq 1 48); }

  # A 干净：五臂声明 == 现场 ⇒ PASS
  mklogs "$T/A-logs"; emit_flat "$T/A.json" "$T/A-logs"
  chk A PASS "$T/A.json" "$T/A-logs"

  # B 扰动一位（仍是合法 64 位 hex）⇒ FAIL
  mklogs "$T/B-logs"; emit_flat "$T/B.json" "$T/B-logs"
  L="$(live_of "$T/B-logs" tab-anchor)"; BAD="$(flip1 "$L")"
  [ "${#BAD}" -eq 64 ] && [ "$BAD" != "$L" ] || die bad-construction-B
  sed -i "s|\"tab-anchor\": \"$L\"|\"tab-anchor\": \"$BAD\"|" "$T/B.json"
  grep -q "\"tab-anchor\": \"$BAD\"" "$T/B.json" || die B-patch-missed
  chk B FAIL "$T/B.json" "$T/B-logs"

  # C 整个 arm_logs 不在 ⇒ NOINFO
  mklogs "$T/C-logs"; printf '{\n  "generation": {"instr_shim": "x"},\n  "entries": [{"x":1}]\n}\n' > "$T/C.json"
  chk C NOINFO "$T/C.json" "$T/C-logs"

  # D **前 16 位 + 48 个 0** ⇒ 必须 FAIL（防"只比 16 位前缀"退化）
  mklogs "$T/D-logs"; emit_flat "$T/D.json" "$T/D-logs"
  L="$(live_of "$T/D-logs" tab-rtl)"; Z="$(zeros48 "$L")"
  [ "${#Z}" -eq 64 ] && [ "$Z" != "$L" ] || die bad-construction-D
  sed -i "s|\"tab-rtl\": \"$L\"|\"tab-rtl\": \"$Z\"|" "$T/D.json"
  grep -q "\"tab-rtl\": \"$Z\"" "$T/D.json" || die D-patch-missed
  chk D FAIL "$T/D.json" "$T/D-logs"

  # E 声明的臂**日志文件不存在** ⇒ FAIL（假声明，不是"无信息"）
  mklogs "$T/E-logs"; emit_flat "$T/E.json" "$T/E-logs"; rm -f "$T/E-logs/textlineproto.log"
  chk E FAIL "$T/E.json" "$T/E-logs"

  # F 只声明 4/5（缺 tline）⇒ NOINFO
  mklogs "$T/F-logs"; emit_flat "$T/F.json" "$T/F-logs"
  python3 -c "
import json,sys
p='$T/F.json'; j=json.load(open(p,encoding='utf-8'))
del j['generation']['arm_logs']['tline']
open(p,'w',encoding='utf-8').write(json.dumps(j,ensure_ascii=False,indent=2)+'\n')"
  chk F NOINFO "$T/F.json" "$T/F-logs"

  # G 声明值只有 16 位（= 同表旧字段 `evidence_log_sha256` 的坏习惯）⇒ FAIL
  mklogs "$T/G-logs"; emit_flat "$T/G.json" "$T/G-logs"
  L="$(live_of "$T/G-logs" tab-zero)"
  sed -i "s|\"tab-zero\": \"$L\"|\"tab-zero\": \"${L:0:16}\"|" "$T/G.json"
  grep -q "\"tab-zero\": \"${L:0:16}\"" "$T/G.json" || die G-patch-missed
  chk G FAIL "$T/G.json" "$T/G-logs"

  # H **`D-G9` 的现场形态**：声明不动、现场日志被换掉 ⇒ FAIL
  mklogs "$T/H-logs"; emit_flat "$T/H.json" "$T/H-logs"
  printf 'REPLACED-LOG\n' > "$T/H-logs/tab-anchor.log"
  chk H FAIL "$T/H.json" "$T/H-logs"

  # I 嵌套形态（=`~/w25j` 草稿的 `arm_logs.sha256{}`）也要认 ⇒ PASS
  mklogs "$T/I-logs"
  { printf '{\n  "generation": {\n    "instr_shim": "x",\n    "arm_logs": {\n'
    printf '      "logdir": "%s",\n      "suffix": ".log",\n      "sha256": {' "$T/I-logs"
    first=1
    for a in $REQ; do
      [ "$first" -eq 1 ] || printf ','
      first=0
      printf '\n        "%s": "%s"' "$a" "$(live_of "$T/I-logs" "$a")"
    done
    printf '\n      }\n    }\n  },\n  "entries": [{"x":1}]\n}\n'
  } > "$T/I.json"
  chk I PASS "$T/I.json" "$T/I-logs"

  # J 登记表不存在 ⇒ NOINFO
  mklogs "$T/J-logs"; chk J NOINFO "$T/J-nope.json" "$T/J-logs"

  # K flat 里混进非字符串值的键（元数据混入/畸形）⇒ FAIL（不许静默忽略）
  mklogs "$T/K-logs"; emit_flat "$T/K.json" "$T/K-logs"
  python3 -c "
import json
p='$T/K.json'; j=json.load(open(p,encoding='utf-8'))
j['generation']['arm_logs']['takenAt'] = {'when':'2026-09-17'}
open(p,'w',encoding='utf-8').write(json.dumps(j,ensure_ascii=False,indent=2)+'\n')"
  chk K FAIL "$T/K.json" "$T/K-logs"

  # L logdir 元数据覆盖：声明里的 logdir 指向**另一个**目录 ⇒ 按它核（不是按 $ALSC_LOGDIR）
  mklogs "$T/L-logs" ""; mklogs "$T/L-other" "OTHER-"
  emit_flat "$T/L.json" "$T/L-logs"
  python3 -c "
import json
p='$T/L.json'; j=json.load(open(p,encoding='utf-8'))
j['generation']['arm_logs']['logdir']='$T/L-other'
open(p,'w',encoding='utf-8').write(json.dumps(j,ensure_ascii=False,indent=2)+'\n')"
  chk L FAIL "$T/L.json" "$T/L-logs"

  echo "ALSC_SELFTEST=$([ "$nf" -eq 0 ] && echo PASS || echo FAIL) cases=$((np+nf)) pass=$np fail=$nf"
  [ "$nf" -eq 0 ] && exit 0 || exit 1
fi

run_check "$REG" "$LOGDIR"
