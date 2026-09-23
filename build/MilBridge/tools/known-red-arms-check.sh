#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# known-red-arms-check.sh —— 「**不在门禁 5 臂内的在册红臂**」的**消费者**（`TASK-0708` 的承重件）
#
# 【它防什么 —— 现场机械核过的「仪器空转」】
#   `known-red.json` 今天只有**一个**读者：`build/MilBridge/tools/tline-gate.sh`。而它的臂是
#   **硬编码 5 臂**（`:124` `ARMS=(tline tab-oracle-zero tab-oracle-anchor tab-oracle-rtl textlineproto)`），
#   逐条判定处写着 `entries_here = [e for e in reg_entries if e.get("arm") == a]`（`:971`）。
#   ⇒ 一条 `arm="uia-door"` 的条目**永远不会被取到**；而 `:971` 那行**对"未知臂"没有任何告警**
#     （现场实测：往登记表加一条未知臂的条目，门禁读数**逐字不变**）。
#   ⇒ **只往登记表加 `entries[]` 是惰性的**：它看着像"已登记"，实际**没有一个字节在看着那件牙**。
#   本件就是那些臂的消费者（`D-G102` 族：「声明存在、无人消费」）。
#
# 【判据（三态，`rc` 语义写死 —— `NOINFO` 既不算绿也不算红）】
#   对**每一个** `arm ∉ <门禁 ARMS>` 的 `entries[]` 条目：
#     ① 取它的 `invoke`（**唯一声明处**＝登记表本身）跑一次，拿到**当场机读行**；
#     ② 读它的 `expected_shape`，做**整行子串**比对（与 `tline-gate.sh:339 eval_shape` 的兜底
#        分支同口径；**不是关键词匹配** —— `D-G84`/`D-G97` 族的教训是关键词会在失败态下也命中）。
#        `rc_tooth == 0` ⇒ 该臂**已不红**；`!= 0` ⇒ 红；`== 2` ⇒ `NOINFO`。
#     `rc=0`  **该臂红 ∧ 与在册 `expected_shape` 相符**（= 在册红，正常）
#     `rc=1`  **红但不在册**（新红／读数漂移）**或** 在册却**已转绿**（登记陈旧 = 假绿风险）
#     `rc=2`  **读不到** ⇒ `NOINFO`（登记表缺／坏／该臂无 `invoke`／牙自己回 `NOINFO`／
#              非门禁臂条目数 < 下限 ⇒ **射程缩到零**，**不许当绿**）
#
# 【硬约束】
#   ① **不改 `tline-gate.sh` 的 5 臂判据一字**：本件**只**处理 `arm ∉ ARMS` 的条目，
#      门禁自己的臂由门禁自己判（本件在读数行里印 `gate_arms=` 与 `skipped_gate_arms=`）。
#   ② **不许放宽**：`expected_shape` 失配就是红，**没有**"容差"；`NOINFO` 不许当绿。
#   ③ **纯读**：零 `dotnet`、不写任何仓内文件（自测全部在 `mktemp -d` 沙箱的 `cp -p` 真副本上）。
#   ④ **射程下限**：`--min-arms N`（默认 1）—— 非门禁臂条目数低于它 ⇒ `NOINFO`
#      （防"登记表被清空而它还是绿的"，与 `D-G19` 的 `judged_min` 同族）。
#
# 用法：
#   bash build/MilBridge/tools/known-red-arms-check.sh
#   bash build/MilBridge/tools/known-red-arms-check.sh --registry P --gate P --min-arms N
#   bash build/MilBridge/tools/known-red-arms-check.sh --selftest
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
ROOT="$(cd "$(dirname "$SELF")/../../.." && pwd)"
REG="$ROOT/build/MilBridge/known-red.json"
GATE="$ROOT/build/MilBridge/tools/tline-gate.sh"
MIN_ARMS=1
SELFTEST=0
KEEP_TMP=0
REG_GIVEN=0
GATE_GIVEN=0
HDR_ONLY=0

say() { printf '%s\n' "$*"; }
sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }

usage() { sed -n '2,45p' "$SELF" | sed 's/^# \{0,1\}//'; }

# ── 抽门禁的 ARMS（**从真件现抽**，不写死 —— 写死 = 第二处声明 ⇒ 必然分叉）──────────
gate_arms() {
  local g="$1"
  [ -f "$g" ] || return 1
  sed -n 's/^ARMS=(\(.*\))[[:space:]]*$/\1/p' "$g" | head -1
}

# ── 核心判定；印机读行并返回 rc（0/1/2）────────────────────────────────────────
#   用法：judge <registry> <gate> <min_arms> <fixture_runner>
#   `fixture_runner` 为空 ⇒ 用条目自己的 `invoke`（生产路径）；
#   非空 ⇒ 用它当"跑臂"的可执行文件（自测夹具用；生产路径永远为空）
judge() {
  local reg="$1" gate="$2" min_arms="$3" runner="${4:-}"
  local why_none=""

  if [ ! -f "$reg" ]; then
    say "KNOWN_RED_ARMS=NOINFO reason=registry-absent path=$reg"
    return 2
  fi
  if [ ! -f "$gate" ]; then
    say "KNOWN_RED_ARMS=NOINFO reason=gate-absent path=$gate"
    return 2
  fi
  local arms_raw; arms_raw="$(gate_arms "$gate")"
  if [ -z "$arms_raw" ]; then
    say "KNOWN_RED_ARMS=NOINFO reason=gate-arms-unparsable path=$gate"
    return 2
  fi

  # 把"逐条判定"整段交给 python3（JSON 解析唯一实现；bash 不解析 JSON 是本仓纪律）
  local out
  out="$(python3 - "$reg" "$gate" "$min_arms" "$runner" "$arms_raw" "$ROOT" <<'PY'
import io, json, os, subprocess, sys

reg_p, gate_p, min_arms, runner, arms_raw, root = sys.argv[1:7]
min_arms = int(min_arms)
arms = [a.strip() for a in arms_raw.split() if a.strip()]

try:
    reg = json.load(io.open(reg_p, encoding="utf-8"))
except Exception as exc:
    print("KNOWN_RED_ARMS=NOINFO reason=registry-unparsable path=%s err=%s" % (reg_p, exc))
    sys.exit(2)

entries = reg.get("entries") or []
out_entries = [e for e in entries if e.get("arm") not in arms]
in_arms = sorted({e.get("arm") for e in entries if e.get("arm") in arms})

print("KNOWN_RED_ARMS_SCOPE registry=%s gate=%s gate_arms=%d skipped_gate_arms=%s out_of_gate_arms=%d min_arms=%d"
      % (reg_p, gate_p, len(arms), ",".join(in_arms) if in_arms else "-", len(out_entries), min_arms))

if not out_entries:
    print("KNOWN_RED_ARMS=NOINFO reason=no-out-of-gate-arms-entries "
          "（本登记表里没有一条 `arm ∉ 门禁 ARMS` 的条目 ⇒ 本步**没有对象**；"
          "射程缩到零不许当绿 —— 与 D-R4/D-G84 同族）entries=%d" % len(entries))
    sys.exit(2)
if len(out_entries) < min_arms:
    print("KNOWN_RED_ARMS=NOINFO reason=scope-below-floor n=%d min_arms=%d"
          % (len(out_entries), min_arms))
    sys.exit(2)

bad, noinfo, ok = [], [], []
for e in out_entries:
    arm = e.get("arm", "?")
    cid = e.get("case_id", "?")
    shape = e.get("expected_shape") or ""
    invoke = e.get("invoke") or ""
    if not shape:
        noinfo.append((arm, "expected_shape-empty"))
        print("KNOWN_RED_ARM %-14s NOINFO reason=expected_shape-empty case_id=%s" % (arm, cid))
        continue
    cmd = invoke if not runner else ("%s %s" % (runner, arm))
    if not cmd.strip():
        noinfo.append((arm, "no-invoke"))
        print("KNOWN_RED_ARM %-14s NOINFO reason=no-invoke case_id=%s"
              "（该条没有 `invoke` ⇒ 谈不了'现场机读行'；**不许**用猜的）" % (arm, cid))
        continue
    p = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, cwd=root)
    text = p.stdout.decode("utf-8", "replace")
    rc = p.returncode
    if not text.strip():
        noinfo.append((arm, "no-output"))
        print("KNOWN_RED_ARM %-14s NOINFO reason=tooth-produced-no-output rc=%d cmd=%s"
              % (arm, rc, cmd))
        continue
    if rc == 2:
        noinfo.append((arm, "tooth-noinfo"))
        print("KNOWN_RED_ARM %-14s NOINFO reason=tooth-reported-noinfo case_id=%s" % (arm, cid))
        continue
    red = (rc != 0)
    hit = shape in text
    # 现场机读行（该臂自己的那一行）—— 印出来，供人一眼对账
    line = next((l for l in text.splitlines() if l.strip().startswith(arm.upper().replace("-", "_") + "=")), "")
    if red and hit:
        ok.append(arm)
        print("KNOWN_RED_ARM %-14s OK     red=yes registered=yes rc_tooth=%d case_id=%s" % (arm, rc, cid))
        print("    ∟ 现场机读行：%s" % (line or "<无>"))
    elif red and not hit:
        bad.append((arm, "new-red-or-drift"))
        print("KNOWN_RED_ARM %-14s FAIL   red=yes registered=NO  rc_tooth=%d case_id=%s"
              % (arm, rc, cid))
        print("    ∟ 现场机读行：%s" % (line or "<无>"))
        print("    ∟ 登记 expected_shape = %s  ⇒ 现场读数里**找不到**它" % shape)
    else:
        bad.append((arm, "registered-but-green"))
        print("KNOWN_RED_ARM %-14s FAIL   red=NO  registered=yes rc_tooth=%d case_id=%s"
              "（**在册却已转绿** ⇒ 登记陈旧 = 假绿风险）" % (arm, rc, cid))
        print("    ∟ 现场机读行：%s" % (line or "<无>"))

n_ok, n_bad, n_ni = len(ok), len(bad), len(noinfo)
if n_bad:
    print("KNOWN_RED_ARMS=FAIL arms=%d ok=%d fail=%d noinfo=%d reasons=%s"
          % (len(out_entries), n_ok, n_bad, n_ni,
             ",".join("%s:%s" % (a, r) for a, r in sorted(bad))))
    sys.exit(1)
if n_ni:
    print("KNOWN_RED_ARMS=NOINFO arms=%d ok=%d fail=%d noinfo=%d reasons=%s"
          % (len(out_entries), n_ok, n_bad, n_ni, ",".join("%s:%s" % (a, r) for a, r in sorted(noinfo))))
    sys.exit(2)
print("KNOWN_RED_ARMS=PASS arms=%d ok=%d fail=0 noinfo=0 registered_red=%s"
      % (len(out_entries), n_ok, ",".join(sorted(ok))))
sys.exit(0)
PY
)"
  local rc=$?
  printf '%s\n' "$out"
  echo "KNOWN_RED_ARMS_SELF path=$SELF sha16=$(sha16 "$SELF")"
  return $rc
}

# ═══════════════════════════════════════════════════════════════════════════════
# --selftest：两极化（≥3 必红 ＋ ≥1 必绿 ＋ ≥1 必 NOINFO），全部在 mktemp -d 沙箱的 cp -p 真副本上
# ═══════════════════════════════════════════════════════════════════════════════
run_selftest() {
  local SB; SB="$(mktemp -d /tmp/kra-selftest.XXXXXX)"
  local total=0 pass=0 fail=0
  local SHA0; SHA0="$(sha256sum "$SELF" | cut -c1-16)"
  say "KRA_SELFTEST_OPEN self=$SELF sha16=$SHA0 base=$SB"

  mkdir -p "$SB/fixture/teeth"
  # 假门禁：只需 ARMS=(…) 那一行（其余不需要 —— 本件不跑门禁）
  printf '# fixture gate\nARMS=(tline tab-oracle-zero tab-oracle-anchor tab-oracle-rtl textlineproto)\n' \
    > "$SB/fixture/gate.sh"
  # 假牙：rc 与 stdout 由 argv 决定（`$1`=rc，`$2`=机读行）
  cat > "$SB/fixture/teeth/a.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$2"
exit "${1:-0}"
SH
  chmod +x "$SB/fixture/teeth/a.sh"
  cp -p "$SB/fixture/teeth/a.sh" "$SB/fixture/teeth/b.sh"   # cp -p 真复制（禁 ln/硬链接）

  local REDLINE='UIA_DOOR=FAIL prod=0 consume=1 core_shim=0 uia_syms=0 live_calls=2'
  local GREENLINE='UIA_DOOR=PASS prod=1 consume=1 core_shim=1 uia_syms=1 live_calls=2'

  mkreg() {  # mkreg <file> <arm> <shape> <invoke>
    python3 - "$1" "$2" "$3" "$4" <<'PY'
import io, json, sys
p, arm, shape, invoke = sys.argv[1:5]
json.dump({"schema": "tline-known-red/4",
           "entries": [{"arm": arm, "case_id": "fx", "expected_shape": shape, "invoke": invoke}]},
          io.open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
PY
  }

  local got rc want wantrc nm
  case_run() {  # case_run <名> <期望rc> <reg文件> <runner>
    nm="$1"; wantrc="$2"
    total=$((total + 1))
    got="$(judge "$3" "$SB/fixture/gate.sh" 1 "${4:-}" 2>&1)"; rc=$?
    if [ "$rc" = "$wantrc" ]; then
      pass=$((pass + 1))
      printf '  %-34s => yes  rc=%s  %s\n' "$nm" "$rc" "$(printf '%s\n' "$got" | grep -m1 '^KNOWN_RED_ARM ' | cut -c1-96)"
    else
      fail=$((fail + 1))
      printf '  %-34s => NO   want rc=%s got rc=%s  %s\n' "$nm" "$wantrc" "$rc" \
        "$(printf '%s\n' "$got" | grep -m1 '^KNOWN_RED_ARM ' | cut -c1-80)"
    fi
  }

  # ── S1 必绿：红 ∧ 与在册形状相符 ──────────────────────────────────────────────
  mkreg "$SB/r1.json" uia-door "$REDLINE" "bash $SB/fixture/teeth/a.sh 1 '$REDLINE'"
  case_run "S1 在册红（必绿）" 0 "$SB/r1.json"

  # ── S2 必红：红但形状与登记不符（读数漂移）──────────────────────────────────
  mkreg "$SB/r2.json" uia-door "$REDLINE" "bash $SB/fixture/teeth/a.sh 1 'UIA_DOOR=FAIL prod=0 consume=1 core_shim=0 uia_syms=0'"
  case_run "S2 漂移（形状失配，必红）" 1 "$SB/r2.json"

  # ── S3 必红：在册却已转绿（登记陈旧 = 假绿风险）──────────────────────────────
  mkreg "$SB/r3.json" uia-door "$REDLINE" "bash $SB/fixture/teeth/a.sh 0 '$GREENLINE'"
  case_run "S3 在册已转绿（必红）" 1 "$SB/r3.json"

  # ── S4 必红：expected_shape 被改坏（写成一个树上不存在的串）──────────────────
  mkreg "$SB/r4.json" uia-door "UIA_DOOR=FAIL prod=99" "bash $SB/fixture/teeth/a.sh 1 '$REDLINE'"
  case_run "S4 登记串被改坏（必红）" 1 "$SB/r4.json"

  # ── S5 必 NOINFO：登记表读不到 ───────────────────────────────────────────────
  case_run "S5 登记表缺（必 NOINFO）" 2 "$SB/nonexistent.json"

  # ── S6 必 NOINFO：登记表读不到（坏 JSON）─────────────────────────────────────
  printf '{ this is not json' > "$SB/bad.json"
  case_run "S6 登记表坏 JSON（必 NOINFO）" 2 "$SB/bad.json"

  # ── S7 必 NOINFO：该臂无 `invoke`（谈不了"现场机读行"）──────────────────────
  mkreg "$SB/r7.json" uia-door "$REDLINE" ""
  case_run "S7 无 invoke（必 NOINFO）" 2 "$SB/r7.json"

  # ── S8 必 NOINFO：**射程缩到零**（条目全是门禁臂 ⇒ 本件无对象）───────────────
  python3 - "$SB/r8.json" <<'PY'
import io, json, sys
json.dump({"schema": "tline-known-red/4",
           "entries": [{"arm": "tline", "case_id": "x", "expected_shape": "❌", "invoke": "true"}]},
          io.open(sys.argv[1], "w", encoding="utf-8"), ensure_ascii=False)
PY
  case_run "S8 全是门禁臂（射程零，必 NOINFO）" 2 "$SB/r8.json"

  # ── S9 必 NOINFO：牙自己回 NOINFO（rc=2）→ 不许当绿 ─────────────────────────
  mkreg "$SB/r9.json" uia-door "$REDLINE" "bash $SB/fixture/teeth/a.sh 2 'UIA_DOOR=NOINFO reason=x'"
  case_run "S9 牙回 NOINFO（必 NOINFO）" 2 "$SB/r9.json"

  # ── S10 反极性正对照：`min-arms 2` 而只有 1 条 ⇒ 下限未达 ⇒ 必 NOINFO ────────
  total=$((total + 1))
  got="$(judge "$SB/r1.json" "$SB/fixture/gate.sh" 2 "" 2>&1)"; rc=$?
  if [ "$rc" = 2 ] && grep -q 'scope-below-floor' <<<"$got"; then
    pass=$((pass + 1)); printf '  %-34s => yes  rc=2  scope-below-floor\n' "S10 下限未达（必 NOINFO）"
  else
    fail=$((fail + 1)); printf '  %-34s => NO   want rc=2/scope-below-floor got rc=%s\n' "S10 下限未达（必 NOINFO）" "$rc"
  fi

  local SHA1; SHA1="$(sha256sum "$SELF" | cut -c1-16)"
  local touched="yes"; [ "$SHA0" = "$SHA1" ] || { touched="NO"; fail=$((fail + 1)); }
  say "KRA_SELFTEST_ROSTER sandbox=$SB cases=$total pass=$pass fail=$fail target_untouched=$touched"
  if [ "$fail" -ne 0 ]; then
    say "KRA_SELFTEST_SANDBOX=$SB（保留供诊断；rm -rf 自行清理）"
    say "KRA_SELFTEST=FAIL total=$total pass=$pass fail=$fail"
    return 1
  fi
  rm -rf "$SB"
  say "KRA_SELFTEST=PASS total=$total pass=$pass fail=0"
  return 0
}

# ── 入口 ─────────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --registry) REG="$2"; REG_GIVEN=1; shift 2;;
    --root)     ROOT="$2"; REG_GIVEN=0; GATE_GIVEN=0; shift 2;;
    --gate)     GATE="$2"; GATE_GIVEN=1; shift 2;;
    --min-arms) MIN_ARMS="$2"; shift 2;;
    --debug-tmp) KEEP_TMP=1; shift;;
    --selftest) SELFTEST=1; shift;;
    -h|--help)  usage; exit 0;;
    *) say "KNOWN_RED_ARMS=NOINFO reason=bad-arg arg=$1"; exit 2;;
  esac
done

# ── `--root` 换过仓根 ⇒ 未被显式指定的默认路径按新根重算（**不给第二处声明**）──────
if [ "${REG_GIVEN:-0}" = 0 ]; then REG="$ROOT/build/MilBridge/known-red.json"; fi
if [ "${GATE_GIVEN:-0}" = 0 ]; then GATE="$ROOT/build/MilBridge/tools/tline-gate.sh"; fi

if [ "$SELFTEST" = 1 ]; then run_selftest; exit $?; fi
judge "$REG" "$GATE" "$MIN_ARMS"
exit $?
