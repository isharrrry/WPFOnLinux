#!/usr/bin/env bash
# ============================================================================
#  bak-completeness-step.sh  ·  波 `#69`（`TASK-0725`，车道 W167A）· 第 `[40]` 步驱动
#
#  本步做两件事，**两件都进 rc**：
#   ① 跑 `D-G126` 牙 `backup-completeness-gate.sh --selftest`（证"装置还活着"＋五条负腿真会红）；
#   ② 评估本波声明的**可跑谓词** —— `producer=UNWIRED-IN-STEP` 到底还成不成立。
#
#  【为什么要 ②（`D-G132`：声明没有机读读者）】`#68` 的 `DECL` 里写了 `producer=UNWIRED-IN-STEP`，
#  但**全仓没有任何一件会去求值它** —— 声明是**散文**，产出端哪天被接线了，屏上**一个字都不会变**。
#  本步把它变成**机器可判**：
#
#      谓词： grep -E '^[[:space:]]*run_step .*backup-completeness-gate\.sh.*--plan' <verify-all.sh>
#      n_wired == 0  ⇒ 声明成立（牙的**真用法**仍未被门禁调用）⇒ 本项 `PASS`
#      n_wired >= 1  ⇒ 声明**失效**（产出端被接线了，头注释却还写着 UNWIRED）⇒ 本步**必须红**
#
#  ⚠️ 口径**限定到代码形状**（`^[[:space:]]*run_step`）—— 全文 `grep` 命中只作旁证，
#     否则本驱动自己、件头注释、报告里的字样都会把谓词点亮（`D-G119` 实例㉔的形态）。
#
#  三态：`PASS=rc0` ／ `FAIL=rc1` ／ `NOINFO=rc3`（缺件／缺 `verify-all.sh` ⇒ **NOINFO，不是绿**）
#  纯读、零 `dotnet`、**不写 `$R`**；本驱动自己的沙箱落点由被调牙决定（仓外）。
# ============================================================================
set -u

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DEFAULT="$(cd "$SELF_DIR/../../.." && pwd)"
VFILE="${WPF_BAK_VERIFY_ALL:-$REPO_DEFAULT/verify-all.sh}"

usage() {
  cat <<'USAGE'
bak-completeness-step.sh — 波 `#69` 第 `[40]` 步驱动（`D-G126` 牙 ＋ 其 UNWIRED 声明谓词）

用法：
  bak-completeness-step.sh [--verify-all <PATH>] [--repo <DIR>]

选项：
  --verify-all <PATH>  求值谓词所对的 `verify-all.sh`（默认 <仓根>/verify-all.sh；
                       仅供**两极化自测**指向沙箱副本）
  --repo <DIR>         权威树（默认由本脚本位置推出）

退出码：0=PASS ／ 1=FAIL ／ 3=NOINFO ／ 2=用法错
机读行：BAK_COMPLETENESS=<PASS|FAIL|NOINFO|USAGE> tooth=<PASS|FAIL|NOINFO> n_wired=<n>
        decl_steps=<n> obs_steps=<n> rc=<n>
USAGE
}

REPO="$REPO_DEFAULT"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verify-all) VFILE="${2:-}"; shift 2 ;;
    --repo)       REPO="${2:-}"; shift 2 ;;
    -h|--help)    usage; exit 2 ;;
    *) echo "bak-completeness-step.sh: 未知参数 '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

TOOTH="$REPO/build/MilBridge/tools/backup-completeness-gate.sh"

emit() {  # emit <verdict> <tooth> <n_wired> <decl> <obs> <rc>
  echo "BAK_COMPLETENESS=$1 tooth=$2 n_wired=$3 decl_steps=$4 obs_steps=$5 rc=$6"
}
noinfo() {  # noinfo <reason> <extra>
  echo "BAK_COMPLETENESS=NOINFO reason=$1 $2"
  echo "  ∟ 缺件/读不到 ⇒ **不许当绿**（铁律）"
  exit 3
}

# ── ① 牙自测（真 rc 直接取，不经管道尾）────────────────────────────────────────
[ -f "$TOOTH" ] || noinfo "tooth-absent" "file=$TOOTH"
TOOTH_LOG="$(mktemp)"
bash "$TOOTH" --selftest > "$TOOTH_LOG" 2>&1
tooth_rc=$?
grep -E '^(LEGS|BCG-SELFTEST)=' "$TOOTH_LOG" || true
tooth_verdict="$(sed -n 's/^BCG-SELFTEST=\([A-Z]*\).*/\1/p' "$TOOTH_LOG" | head -1)"
rm -f "$TOOTH_LOG"
[ -n "$tooth_verdict" ] || tooth_verdict="NOINFO"
if [ "$tooth_rc" -eq 0 ] && [ "$tooth_verdict" = "PASS" ]; then
  tooth_state="PASS"
else
  tooth_state="FAIL"
fi

# ── ② UNWIRED 谓词（**限定代码形状**）──────────────────────────────────────────
[ -f "$VFILE" ] || noinfo "verify-all-absent" "file=$VFILE"
# 逐行抽（**不用 `grep -c` 进算术** —— 纪律 4）
n_wired="$(grep -E '^[[:space:]]*run_step .*backup-completeness-gate\.sh.*--plan' "$VFILE" | wc -l)"
n_wired="${n_wired//[!0-9]/}"
# 诊断格：步数账（纪律 46 的真不变量；只印，不在此判 —— 那是 `[17] VERIFYALL-SELF` 的职分）
decl_steps="$(sed -n 's/^#[[:space:]]*VERIFYALL-STEPS-DECL:[[:space:]]*\([0-9]\{1,\}\).*/\1/p' "$VFILE" | head -1)"
obs_steps="$(grep -E '^run_step "' "$VFILE" | wc -l)"
decl_steps="${decl_steps:-?}"

pred_state="PASS"
if [ "$n_wired" -ge 1 ]; then
  pred_state="FAIL"
  echo "  谓词反证：producer=UNWIRED-IN-STEP 【已失效】 —— 门禁里有 $n_wired 条真调用产出端："
  grep -nE '^[[:space:]]*run_step .*backup-completeness-gate\.sh.*--plan' "$VFILE" | head -5
  echo "  ⇒ 要么把产出端接上（那就删掉 UNWIRED 声明），要么把调用撤回。**声明与代码必须二选一。**"
fi

if [ "$tooth_state" = "PASS" ] && [ "$pred_state" = "PASS" ]; then
  echo "  BCG_UNWIRED_PREDICATE=PASS n_wired=$n_wired file=$VFILE"
  emit PASS "$tooth_state" "$n_wired" "$decl_steps" "$obs_steps" 0
  exit 0
fi

emit FAIL "$tooth_state" "$n_wired" "$decl_steps" "$obs_steps" 1
exit 1
