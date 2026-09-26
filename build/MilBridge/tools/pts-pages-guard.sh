#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# pts-pages-guard.sh —— `D-G122`（止损无守卫）的牙：**PTS 两页（23/24）的页级降级必须还在**。
#
# 【为什么存在】`#50` 的 `A1`＋`A2`＋`A3` 把「切富文本 23／流文档 24 必死 rc=134」降级成
#   「页级可见降级（洋红占位）＋ 具名行 ＋ 进程不死」。**但这两页不在任何在跑门禁里**
#   （现场机械核：`grep -rn 'FlowDocument|RichTextBox|TASK-0007' verify-all.sh
#     build/integration-wave.sh` = 0 命中；`known-red.json` 5 条无一条相关）
#   ⇒ 该修法**不可回归**：将来谁"顺手"把 A2/A3 改回/删掉，**没有任何自动读数会响**。
#   本牙就是那条"能把它咬回来"的读数（口径句见 `D-G122`）。
#
# 【判据（逐条）】—— **承重**（进 rc）：
#   G1  leg 24 `alive=yes`                      否 ⇒ FAIL
#   G2  leg 23 `alive=yes`                      否 ⇒ FAIL
#   G3  两腿 `app_rc ∉ {134,139}`               否 ⇒ FAIL（134 = `D-G70` 族 abort；139 = 静默 SEGV）
#   G4  leg 24 `magenta ≥ 20000`                否 ⇒ FAIL（页级占位没画出来 / 空白）
#   G5  leg 23 `magenta ≥ 20000`                否 ⇒ FAIL
#   G6  leg 24 `ns == HandyControlDemo.UserControl.FlowDocumentDemo`   否 ⇒ NOINFO
#   G7  leg 23 `ns == HandyControlDemo.UserControl.RichTextBoxDemo`    否 ⇒ NOINFO
#   G8  leg 24 托管侧具名行 `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage` ∧ `err≠0`  否 ⇒ FAIL
#   G9  leg 23 同上                                                         否 ⇒ FAIL
#   G10 至少一条 native `PTS_GAP entry=CreateInstalledObjectsInfo`           否 ⇒ FAIL
#   G11 `DEV x_up=yes`                          否 ⇒ NOINFO（装置没起来 ⇒ 读数无效，不是红）
#   G12 两腿 `five_stable=yes`                  否 ⇒ NOINFO（跑的过程中件被换）
#
# 【诊断（**不进 rc**）】
#   D1/D2 `colors` 参考带 `800–1200`（实测 851/843）；出带只打 `DIAG`
#   D3    native `err=0` ⇒ 打 `DIAG fake-stub-suspected`（**不判红**：`W86A` §5.1 实测
#         「假 stub 也不能让判据变绿」—— 链上下一个真缺口 `LoCreateContext` 仍在 ⇒ 降级仍是真的）
#   D4    `AE`（点击前后像素差）、D5 `pts_gap_seq`、D6 `log_bytes`
#
# 【三态与判序（与仓内 `r-gate-step.sh` 同款）】
#   rc=0 `PTS_GUARD=PASS` ｜ rc=1 `PTS_GUARD=FAIL` ｜ rc=2 `PTS_GUARD=NOINFO`
#   ⚠️ **判序：有红先红**（`NOINFO` 比 `FAIL` 弱，先用弱结论会把真红洗成"算不出"）；
#      无红但有"判不了" ⇒ `NOINFO`。**`NOINFO` 在门禁里同样是 ❌**。
#
# 【方向口径（`D-G142`／`TASK-0741`）】**口径文本必须在判据件自身**，不许只活在别处的历史 `DECL` 行里：
#   · 洋红（`magenta`）= `0` ⇒ **页级占位缺席**（该页没画出来 ⇒ **未修方向**）；
#   · 洋红 ≥ `20000` ⇒ **占位已画出**（**修复方向**）；
#   · 红条件（方向的**反面**，逐字）：`magenta=0 ∧ 无具名行 ∧ native_gap=0`；**反转必须成对**。
#   · 下面这一行是**唯一机读声明行**；判词行**行尾**带 `direction=` 标记（**前缀语义一字不改**）；
#     本行缺失／与编译常量不符 ⇒ `PTS_DIRECTION=FAIL` ＋ 本步**当场红**（**不许静默绿**）。
# PTS-DIRECTION: absent="magenta=0" present-floor=20000 red-when="magenta=0 AND no-named-line AND native_gap=0" source=TASK-0741

# 【反例牙】**本脚本的绿必须能被两极化证伪**，配方（三臂 × 5 腿）见
#   `~/w156a/w67guard/polarity-recipe.md`：
#     ① `A`（现权威五件）⇒ 必 `PASS`  ② `B`（修前成对件 `shim 3e4390c9ec07f621` ＋
#     `pf 6375fabf89ac7fef`）⇒ 必 **`FAIL`**（`app_rc=134` ∧ `alive=no`）
#     ③ `C`（只撤"画占位"：`shim 24e906c194903c8b` ＋ `pf 0018b509567434df`）⇒ 必 **`FAIL`**
#     （`alive=yes` 但 `magenta=0`）。`--selftest` 用**合成用例**跑这三态（不需要 X、不需要应用）。
#
# 【成本（实测，`~/w156a/w67guard/report.md` §5）】跑腿 ≈ 27 s/腿（应用冷启 8 s ＋ 点击 ≈3 s ＋
#   收尾），`--legs`（只判已落盘证据）**< 0.2 s**、零 `dotnet`。
#
# 【用法】
#   bash pts-pages-guard.sh --legs <dir>      # 只判（纯读、无 X、<0.2 s）—— 门禁里用这一支
#   bash pts-pages-guard.sh --selftest        # 合成用例两极化（无 X、无应用）
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

MAGENTA_FLOOR="${PTS_GUARD_MAGENTA_FLOOR:-20000}"

# ── 小工具 ───────────────────────────────────────────────────────────────────
field() { printf '%s' "$1" | grep -o -m1 "[[:space:]]$2=[^[:space:]]*" | head -1 | sed "s/^[[:space:]]$2=//"; }

# ── 方向口径闸（`TASK-0741`：口径**自证**；坏 ⇒ 响亮）────────────────────────
DIR_TOKEN=""; DIR_RC=0
direction_gate() {   # ⚠️ **绝不可用命令替换调用**（子壳里赋的 DIR_TOKEN 会丢）⇒ 直接调用后读 DIR_RC/DIR_TOKEN
  local line fl
  line="$(grep -m1 -E '^#[[:space:]]*PTS-DIRECTION:' "$0" 2>/dev/null || true)"
  DIR_TOKEN="in-file"; DIR_RC=0
  if [ -z "$line" ]; then
    DIR_TOKEN="missing"; DIR_RC=1
    echo "PTS_DIRECTION=FAIL reason=directive-absent expected=in-file-self-declared"
    echo "  ∟ \`D-G142\`：方向口径单点存在于别处 ⇒ 本件不自证 ⇒ **不许静默绿**"
    return 1
  fi
  fl="$(printf '%s' "$line" | sed -n 's/.*present-floor=\([0-9][0-9]*\).*/\1/p')"
  if [ -z "$fl" ] || [ "$fl" != "$MAGENTA_FLOOR" ]; then
    DIR_TOKEN="floor-mismatch"; DIR_RC=1
    echo "PTS_DIRECTION=FAIL reason=floor-mismatch directive=${fl:-none} compiled=$MAGENTA_FLOOR"
    return 1
  fi
  return 0
}

# ── 判读一份证据目录 ─────────────────────────────────────────────────────────
judge_legs() {
  local dir="$1"
  local fails=() cannot=() diags=()
  local k alive rc mag colors ns msite merr nerr ngap ae seq logb
  direction_gate || true
  if [ "$DIR_RC" -ne 0 ]; then
    echo "PTS_GUARD=FAIL legs=0/2 fails=direction($DIR_TOKEN) cannot=- diag=- direction=$DIR_TOKEN"
    return 1
  fi

  [ -d "$dir" ] || { echo "PTS_GUARD=NOINFO reason=legs-dir-absent dir=$dir direction=$DIR_TOKEN"; return 2; }

  # ── 装置自证（缺失 ⇒ NOINFO，不是红）────────────────────────────────────────
  local dev="$dir/device.txt"
  local xup="-"
  if [ -f "$dev" ]; then xup="$(grep -o -m1 'X_UP=[a-z]*' "$dev" | head -1 | cut -d= -f2)"; fi
  [ -n "${xup:-}" ] || xup="-"
  if [ "$xup" != "yes" ]; then
    echo "PTS_GUARD=NOINFO reason=device-x-not-up x_up=$xup direction=$DIR_TOKEN detail=<缺 device.txt 或 X_UP≠yes ⇒ 本趟读数无效>"
    return 2
  fi

  local seen24=0 seen23=0
  local ev
  for k in 24 23; do
    ev="$dir/leg_$k.env"
    if [ ! -s "$ev" ]; then
      cannot+=("leg$k(env-absent)")
      continue
    fi
    local line; line="$(grep -m1 '^LEG ' "$ev" 2>/dev/null)"
    local nline; nline="$(grep -m1 '^NAMED ' "$ev" 2>/dev/null)"
    local dline; dline="$(grep -m1 '^DEV ' "$ev" 2>/dev/null)"
    if [ -z "$line" ]; then cannot+=("leg$k(LEG-line-absent)"); continue; fi
    [ "$k" = 24 ] && seen24=1 || seen23=1

    alive="$(field "$line" alive)"; rc="$(field "$line" app_rc)"
    mag="$(field "$line" magenta)"; colors="$(field "$line" colors)"; ns="$(field "$line" ns)"
    ae="$(field "$line" ae)"
    merr="$(field "${nline:-}" err)"
    ngap="$(field "${nline:-}" native_gap)"; nerr="$(field "${nline:-}" native_err)"

    # 空侧必须响亮失败（纪律 27：解析任一侧为空 ⇒ 不许静默判等）
    case "${alive:-}" in ''|-) cannot+=("leg$k(alive-unparsable)"); continue;; esac
    case "${rc:-}"    in ''|*[!0-9]*) cannot+=("leg$k(app_rc-unparsable)"); continue;; esac
    case "${mag:-}"   in ''|*[!0-9]*) cannot+=("leg$k(magenta-unparsable)"); continue;; esac

    # G11/G12 装置自证
    local fstable; fstable="$(field "$dline" five_stable)"
    case "${fstable:-}" in yes|YES) ;; *) cannot+=("leg$k(five-stable=$fstable)");; esac

    # G6/G7 身份牙：点错对象 ⇒ 判不了（不许判绿，也不许判红）
    local exp="$k"; case "$k" in 24) exp="HandyControlDemo.UserControl.FlowDocumentDemo";; 23) exp="HandyControlDemo.UserControl.RichTextBoxDemo";; esac
    if [ "${ns:-}" != "$exp" ]; then cannot+=("leg$k(ns=$ns≠$exp)"); fi

    # G1/G2 活着
    [ "$alive" = yes ] || fails+=("leg$k-not-alive(alive=$alive)")
    # G3 退出码黑名单
    case "$rc" in 134|139) fails+=("leg$k-abort(app_rc=$rc)");; esac
    # G4/G5 洋红阈值
    [ "$mag" -ge "$MAGENTA_FLOOR" ] || fails+=("leg$k-placeholder-missing(magenta=$mag<$MAGENTA_FLOOR)")
    # G8/G9 托管侧具名行（非零 err）
    [ "${merr:-}" = "-10000" ] || fails+=("leg$k-named-line(missing-or-err=$merr)")
    # D1/D2 诊断
    case "${colors:-}" in ''|*[!0-9]*) diags+=("leg$k-colors=$colors");;
      *) if [ "$colors" -lt 800 ] || [ "$colors" -gt 1200 ]; then diags+=("leg$k-colors-out-of-band=$colors"); fi;; esac
    if [ "${ae:-}" = "0" ]; then diags+=("leg$k-AE=0(点击前后无像素差)"); fi
  done

  # G10 native 台账（**两腿合并判**：至少一条）
  local ngap_total=0
  for k in 24 23; do
    ev="$dir/leg_$k.env"; [ -s "$ev" ] || continue
    local g; g="$(field "$(grep -m1 '^NAMED ' "$ev" 2>/dev/null)" native_gap)"
    case "${g:-}" in ''|*[!0-9]*) ;; *) ngap_total=$((ngap_total + g));; esac
  done
  [ "$ngap_total" -ge 1 ] || fails+=("native-ledger-absent(PTS_GAP n=0)")

  # D3 假 stub 诊断（**不判红**）
  for k in 24 23; do
    ev="$dir/leg_$k.env"; [ -s "$ev" ] || continue
    local ne; ne="$(field "$(grep -m1 '^NAMED ' "$ev" 2>/dev/null)" native_err)"
    if [ "${ne:-}" = "0" ]; then diags+=("leg$k-native-err=0(fake-stub-suspected)"); fi
  done

  local crit="magenta_floor=$MAGENTA_FLOOR alive24=$([ "$seen24" = 1 ] && echo ? || echo -) "
  local v
  if [ "${#fails[@]}" -gt 0 ]; then
    v="FAIL"
  elif [ "${#cannot[@]}" -gt 0 ]; then
    v="NOINFO"
  else
    v="PASS"
  fi
  printf 'PTS_GUARD=%s legs=%s/%s fails=%s cannot=%s diag=%s direction=%s\n' \
    "$v" "$(ls "$dir"/leg_*.env 2>/dev/null | wc -l)" \
    "$((seen24 + seen23))" \
    "$( [ "${#fails[@]}" -gt 0 ] && printf '%s' "$(IFS=,; echo "${fails[*]}")" || printf '-')" \
    "$( [ "${#cannot[@]}" -gt 0 ] && printf '%s' "$(IFS=,; echo "${cannot[*]}")" || printf '-')" \
    "$( [ "${#diags[@]}" -gt 0 ] && printf '%s' "$(IFS=,; echo "${diags[*]}")" || printf '-')" \
    "$DIR_TOKEN"
  case "$v" in
    PASS)   return 0 ;;
    FAIL)   return 1 ;;
    NOINFO) return 2 ;;
  esac
}

# ── 合成用例两极化（无 X、无应用、秒级）───────────────────────────────────────
selftest() {
  local T; T="$(mktemp -d)"; local npass=0 nfail=0
  mk() { # mk <case> <k> <alive> <app_rc> <magenta> <colors> <ns> <err> <native_gap> <native_err> <five> <xup>
    local c="$1" k="$2" d="$T/$1"; mkdir -p "$d"
    printf 'X_UP=%s display=:237\n' "${12}" > "$d/device.txt"
    printf 'LEG k=%s alive=%s app_rc=%s magenta=%s colors=%s ns=%s ae=12345\n' "$2" "$3" "$4" "$5" "$6" "$7" > "$d/leg_$2.env"
    printf 'NAMED managed_unavail=%s err=%s native_gap=%s native_err=%s\n' \
      "$([ "$8" = "-" ] && echo 0 || echo 1)" "$8" "$9" "${10}" >> "$d/leg_$2.env"
    printf 'DEV x_up=%s five_stable=%s shim=x pf=y\n' "${12}" "${11}" >> "$d/leg_$2.env"
  }
  good() { mk "$1" 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes yes
           mk "$1" 23 yes 143 49864 843 HandyControlDemo.UserControl.RichTextBoxDemo  -10000 0 -10000 yes yes; }
  chk() { local want="$1" got="$2" nm="$3"
    if [ "$want" = "$got" ]; then npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "$nm" "$got"
    else nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 %s\n' "$nm" "$got" "$want"; fi; }

  out() { printf '%s\n' "$1" | grep -o -m1 '^PTS_GUARD=[A-Z]*' | cut -d= -f2; }
  outdir() { printf '%s\n' "$1" | grep -o -m1 'direction=[a-z-]*' | cut -d= -f2; }

  # ① 全好 ⇒ PASS
  good c1;                              chk PASS "$(out "$(judge_legs "$T/c1")")" "全好(54454/49864)"
  # ② 修前成对件形态：leg24 rc=134 alive=no ⇒ FAIL
  good c2; rm -f "$T/c2/leg_24.env"; mk c2 24 no 134 0 1 HandyControlDemo.UserControl.FlowDocumentDemo -10000 0 -10000 yes yes
                                        chk FAIL "$(out "$(judge_legs "$T/c2")")" "rc=134/alive=no"
  # ③ 假修形态：alive=yes 但 magenta=0 ⇒ FAIL
  good c3; rm -f "$T/c3/leg_24.env"; mk c3 24 yes 143 0 643 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes yes
                                        chk FAIL "$(out "$(judge_legs "$T/c3")")" "alive 但洋红 0"
  # ④ 阈值下界 -1 ⇒ FAIL
  good c4; rm -f "$T/c4/leg_24.env"; mk c4 24 yes 143 19999 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes yes
                                        chk FAIL "$(out "$(judge_legs "$T/c4")")" "洋红 19999(<门槛)"
  # ⑤ 阈值上界（恰好 = 门槛）⇒ PASS（"≥"）
  good c5; rm -f "$T/c5/leg_24.env"; mk c5 24 yes 143 20000 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes yes
                                        chk PASS "$(out "$(judge_legs "$T/c5")")" "洋红 =20000(边界必过)"
  # ⑥ 点错对象（ns 不匹配）⇒ NOINFO
  good c6; rm -f "$T/c6/leg_24.env"; mk c6 24 yes 143 54454 851 HandyControlDemo.UserControl.BrushDemo -10000 1 -10000 yes yes
                                        chk NOINFO "$(out "$(judge_legs "$T/c6")")" "ns=B rushDemo(点错对象)"
  # ⑦ 具名行缺 ⇒ FAIL
  good c7; rm -f "$T/c7/leg_24.env"; mk c7 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo - 0 -10000 yes yes
                                        chk FAIL "$(out "$(judge_legs "$T/c7")")" "无具名行"
  # ⑧ native err=0（假 stub）⇒ 仍 PASS（只有 DIAG）
  good c8; rm -f "$T/c8/leg_24.env"; mk c8 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 0 yes yes
                                        chk PASS "$(out "$(judge_legs "$T/c8")")" "native err=0 ⇒ PASS+DIAG"
  # ⑨ X 没起来 ⇒ NOINFO
  good c9; rm -f "$T/c9/leg_24.env" "$T/c9/leg_23.env"
          mk c9 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 yes no
                                        chk NOINFO "$(out "$(judge_legs "$T/c9")")" "x_up=no"
  # ⑩ 证据目录空 ⇒ NOINFO（**响亮**，不许静默 PASS）
  mkdir -p "$T/c10";                    chk NOINFO "$(out "$(judge_legs "$T/c10")")" "空证据目录"
  # ⑪ 件跑动中被换 ⇒ NOINFO
  good c11; rm -f "$T/c11/leg_24.env";  mk c11 24 yes 143 54454 851 HandyControlDemo.UserControl.FlowDocumentDemo -10000 1 -10000 no yes
                                        chk NOINFO "$(out "$(judge_legs "$T/c11")")" "five_stable=no"
  # ⑫ 139（静默 SEGV）⇒ FAIL
  good c12; rm -f "$T/c12/leg_24.env";  mk c12 24 no 139 0 1 HandyControlDemo.UserControl.FlowDocumentDemo -10000 0 -10000 yes yes
                                        chk FAIL "$(out "$(judge_legs "$T/c12")")" "app_rc=139"

  # ⑬ 方向口径**在位** ⇒ 判词行尾带 `direction=in-file`（`TASK-0741`）
  good c13; chk in-file "$(outdir "$(judge_legs "$T/c13")")" "方向口径在位"
  # ⑭ **反极**：沙箱把件内那一行删掉 ⇒ `PTS_DIRECTION=FAIL` ＋ 判词**必红** ＋ rc≠0
  #    （口径只活在别处 ＝ `D-G142` 的现场形态；**不许静默绿**）
  _sb="$T/guard-nodirective.sh"
  grep -v -E '^#[[:space:]]*PTS-DIRECTION:' "$0" > "$_sb"
  mkdir -p "$T/c14"
  _sbo="$(bash "$_sb" --legs "$T/c14" 2>&1)"; _sbrc=$?
  chk FAIL "$(out "$_sbo")" "删句 ⇒ 判词必红"
  chk missing "$(outdir "$_sbo")" "删句 ⇒ direction 标记=missing"
  if grep -qF 'PTS_DIRECTION=FAIL' <<< "$_sbo"; then
    npass=$((npass+1)); printf '  %-34s => %-6s ok\n' "删句 ⇒ PTS_DIRECTION=FAIL" "yes"
  else
    nfail=$((nfail+1)); printf '  %-34s => %-6s ✗ 期望 PTS_DIRECTION=FAIL\n' "删句 ⇒ PTS_DIRECTION=FAIL" "no"
  fi
  if [ "$_sbrc" -ne 0 ]; then
    npass=$((npass+1)); printf '  %-34s => rc=%-3s ok\n' "删句 ⇒ rc≠0" "$_sbrc"
  else
    nfail=$((nfail+1)); printf '  %-34s => rc=%-3s ✗ 期望非零\n' "删句 ⇒ rc≠0" "$_sbrc"
  fi
  rm -rf "$T"
  printf 'PTS_GUARD_SELFTEST=%s pass=%d fail=%d\n' "$([ "$nfail" = 0 ] && echo PASS || echo FAIL)" "$npass" "$nfail"
  [ "$nfail" = 0 ]
}

case "${1:---selftest}" in
  --legs) shift; judge_legs "${1:?--legs 需要目录}"; exit $? ;;
  --selftest) selftest; exit $? ;;
  *) echo "用法: $0 --legs <dir> | --selftest" >&2; exit 2 ;;
esac
