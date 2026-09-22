#!/usr/bin/env bash
# ============================================================================
# run-w81a-legs.sh —— `W81A`（波 `#50`）两条腿的装置（**只跑探针，不碰任何产品件**）
# ============================================================================
#   TASK-0106 腿（`--leg pmax`）：`PMaxSize` **声明态两极化**
#     被测：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（`win32shim` 位）
#     装置：一个进程两个窗口（declared / undeclared）；读数面 = **X 服务器自己的属性**
#           （`xprop -id <xid> WM_NORMAL_HINTS`）；窗口 id 由应用自己印（HWND==XID）
#     判据（详见 `build/MilBridge/W81A-report.md` §0.1）：
#       P1 declared   ⇒ `program specified maximum size: W by H` **出现且等于声明值**
#       N1 undeclared ⇒ 同一属性里**不许**出现 `maximum size`
#       三态：`W81A_PMAX=PASS|FAIL|NOINFO`（两窗都没有 `WM_NORMAL_HINTS` ⇒ NOINFO，不许当绿）
#
#   A0 腿（`--leg a0`）：最小 `FlowDocument` 页面的**原生需求序列实测**
#     装置：仓内**已存在**的 `build/MilBridge/tools/t1b-ls-tripwire.sh`（真值 = `ld.so` 的
#           `LD_DEBUG=symbols` 日志）＋ `--mode=flowdoc` 的探针
#     判据（详见 §0.2）：设备自证 `PASS` ⇒ 应用真的走到 `step=flowdoc-shown` ⇒ 逐条给
#           「符号 / 查找次数 / FOUND|MISS / 顺序」，并与 `W78A-report.md` §2.2 的 27 条对表。
#       三态：`W81A_A0=MEASURED|NOINFO`（**A0 不是绿/红，是"有没有量到"**）
#
#   【纪律】每条重活（`dotnet build` / 应用）**各自**包进 `~/heavy-slot.sh`
#     （`--min-avail 1500 --max-hold 200` ＋ 内层 `timeout`），**不并跑**；
#     `HEAVYSLOT=MAXHOLD_KILL` / `NOINFO low-memory` 那两行 ⇒ 本趟**不是读数**（本脚本按 NOINFO 处理）；
#     Xvfb **记自己的 PID 收尾**，绝不 `pkill -f`；产物与日志一律落 `$W81A_OUT`（默认 `$HOME/w81a/out`）。
#
#   用法：
#     bash build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh                # 两条腿
#     bash build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh --leg pmax
#     bash build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh --leg a0 --no-build
#     W81A_OUT=/tmp/x W81A_DISPLAY=:94 bash …/run-w81a-legs.sh
# ============================================================================
set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd -- "$HERE/../../../.." && pwd)"
PROJ="$HERE/W81AWindowProbe.csproj"
ASM="W81AWindowProbe"
. "$REPO/build/selfbuilt-config.sh"
CFG="$SELFBUILT_CONFIG"
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

LEG=both; DO_BUILD=1; HOLD=14
MAXW=640; MAXH=480        # 探针声明的那两个上限（**DIP**；判据里的期望值要换算成设备单位）
# ⚠️ 参数解析用 `while` + `shift`，**不要** `for a in "$@"`（后者在展开后再 `shift`，
#    迭代表早已定死 ⇒ `--leg pmax --no-build` 会把 `pmax` 再当成位置参数 ⇒ 合法用法被判成非法；
#    本仓 `run-wpftextdemo.sh` 的文件头记过同一条坑）
while [ "$#" -gt 0 ]; do
  case "$1" in
    --leg)      LEG="${2:-}"; shift 2 ;;
    --leg=*)    LEG="${1#*=}"; shift ;;
    --no-build) DO_BUILD=0; shift ;;
    --hold=*)   HOLD="${1#*=}"; shift ;;
    *) echo "用法: $0 [--leg pmax|a0|both] [--no-build] [--hold=N]" >&2; exit 2 ;;
  esac
done
case "$LEG" in pmax|a0|both) ;; *) echo "❌ --leg 只认 pmax|a0|both（收到 '$LEG'）" >&2; exit 2 ;; esac

OUT="${W81A_OUT:-$HOME/w81a/out}"
mkdir -p "$OUT"
SHA16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }

# ── 重活槽（**每条命令各自**入槽；槽本身自带防嵌套） ────────────────────────────────
slot() { bash "$HOME/heavy-slot.sh" --min-avail 1500 --max-hold 200 -- "$@"; }

# ── X 前置：没有可用显示就自起（**记自己的 PID**） ────────────────────────────────
DISP="${W81A_DISPLAY:-:95}"
XPID=""
cleanup() { if [ -n "$XPID" ]; then kill "$XPID" 2>/dev/null; XPID=""; fi; }
trap cleanup EXIT INT TERM
if ! DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1; then
  Xvfb "$DISP" -screen 0 1280x1024x24 > "$OUT/xvfb.log" 2>&1 &
  XPID=$!
  for _ in $(seq 1 40); do DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1 && break; sleep 0.25; done
fi
if ! DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1; then
  echo "W81A=NOINFO reason=no-usable-display disp=$DISP out=$OUT"; exit 2
fi
echo "W81A DISPLAY=$DISP ready（$(DISPLAY="$DISP" xdpyinfo 2>/dev/null | awk '/dimensions/{print $2}')）out=$OUT cfg=$CFG"
echo "W81A SHIM $(SHA16 "$REPO/src/WpfGfx.Linux.Native/bin/libwpfwin32.so")  src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
echo "W81A PC   $(SHA16 "$REPO/build/PresentationCore.Linux/bin/$CFG/PresentationCore.dll")  PF $(SHA16 "$REPO/build/PresentationFramework.Linux/bin/$CFG/PresentationFramework.dll")  WB $(SHA16 "$REPO/build/WindowsBase.Linux/bin/$CFG/WindowsBase.dll")  （声明档 $CFG = close-wave 读九位用的同一个档）"

# ── 构建（唯一构建者 = 本车道；一次构建两条腿共用） ───────────────────────────────
BIN="$HERE/bin/$CFG"
if [ "$DO_BUILD" = 1 ]; then
  slot timeout 180 dotnet build "$PROJ" -c "$CFG" -m:1 --nologo -v q > "$OUT/build.log" 2>&1
  brc=$?
  echo "W81A_BUILD rc=$brc cfg=$CFG log=$OUT/build.log"
  grep -E "HEAVYSLOT=" "$OUT/build.log" 2>/dev/null | sed 's/^/  /'
  if [ "$brc" -ne 0 ]; then
    echo "W81A=NOINFO reason=build-failed rc=$brc（先看 $OUT/build.log）"
    grep -m5 -E ": error " "$OUT/build.log" 2>/dev/null | sed 's/^/  /'
    exit 2
  fi
fi
if [ ! -f "$BIN/$ASM.dll" ]; then
  echo "W81A=NOINFO reason=probe-dll-absent path=${BIN#"$REPO"/}/$ASM.dll"; exit 2
fi
echo "W81A_PROBE_BIN $(SHA16 "$BIN/$ASM.dll")  ${BIN#"$REPO"/}/$ASM.dll"
# app-local 副本的 sha（**运行期真正加载的是它们**，自证"不是旧代件"）
for f in PresentationCore.dll PresentationFramework.dll WindowsBase.dll DirectWrite.Linux.Provider.dll; do
  [ -f "$BIN/$f" ] && echo "W81A_APPLOCAL $f $(SHA16 "$BIN/$f")"
done

RC_PMAX=-1; RC_A0=-1

# ════════════════════════════════════════════════════════════════════════════
# TASK-0106 腿：`PMaxSize` 声明态两极化
# ════════════════════════════════════════════════════════════════════════════
if [ "$LEG" = pmax ] || [ "$LEG" = both ]; then
  D="$OUT/pmax"; rm -rf "$D"; mkdir -p "$D"

  # ── 装置判别力自证（**先做**：正极性若不成立，"看不见"必须与"没发"分开）──────────
  #   一个与 WPF/shim 无关的裸 X 客户端，成对两种模式；判据 = `max` 那窗能读到 `PMaxSize`、
  #   `nomin` 那窗读不到。装置自证不过 ⇒ 本腿一律 `NOINFO`（不许把"我读不出来"当"没发"）。
  DEV=PASS
  if ! gcc -O0 -o "$D/xprobe-hints" "$HERE/xprobe-hints.c" -lX11 > "$D/gcc.log" 2>&1; then
    echo "W81A_PMAX_DEVICE=NOINFO reason=gcc-failed log=$D/gcc.log"; DEV=NOINFO
  else
    for m in max nomin; do
      DISPLAY="$DISP" "$D/xprobe-hints" "$m" 12 > "$D/xprobe-$m.out" 2>&1 &
      eval "DPID_$m=$!"
    done
    sleep 2
    for m in max nomin; do
      xid="$(sed -n 's/^XPROBE xid=\(0x[0-9a-f]*\).*/\1/p' "$D/xprobe-$m.out" | head -1)"
      DISPLAY="$DISP" xprop -id "$xid" WM_NORMAL_HINTS > "$D/xprobe-$m.hints" 2>&1
      got="$(grep -o 'program specified maximum size: [0-9]* by [0-9]*' "$D/xprobe-$m.hints" | head -1)"
      echo "W81A_PMAX_DEVICE_ARM mode=$m xid=$xid max='${got:-<缺席>}'"
    done
    mdev="$(grep -o 'program specified maximum size: [0-9]* by [0-9]*' "$D/xprobe-max.hints" | head -1)"
    ndev="$(grep -o 'program specified maximum size: [0-9]* by [0-9]*' "$D/xprobe-nomin.hints" | head -1)"
    if [ "$mdev" = "program specified maximum size: 640 by 480" ] && [ -z "$ndev" ]; then
      echo "W81A_PMAX_DEVICE=PASS（装置成对：设了 PMaxSize 的窗读得到、没设的读不到）"
    else
      echo "W81A_PMAX_DEVICE=FAIL（装置成对不成立：max='${mdev:-<缺席>}' nomin='${ndev:-<缺席>}'）"
      DEV=FAIL
    fi
    kill "$DPID_max" "$DPID_nomin" 2>/dev/null
    wait "$DPID_max" "$DPID_nomin" 2>/dev/null
  fi

  LOG="$D/app.log"
  # `WPF_LINUX_CREATE_DIAG=1`：让 shim 自己把 `WM_GETMINMAXINFO` 那一拍的选择印出来（**旁证**，
  #   不是判据 —— 判据只有 `xprop`；两者的读数必须互相印证，若分叉要在报告里点名）
  (
    cd "$BIN" && DISPLAY="$DISP" WPF_LINUX_CREATE_DIAG=1 \
      slot timeout 180 dotnet "$BIN/$ASM.dll" --mode=pmax-pair --max="${MAXW}x${MAXH}" --hold="$HOLD"
  ) > "$LOG" 2>&1 &
  APID=$!
  ready=0
  for _ in $(seq 1 120); do
    grep -q '^W81A_READY ' "$LOG" 2>/dev/null && { ready=1; break; }
    kill -0 "$APID" 2>/dev/null || break
    sleep 0.5
  done
  if [ "$ready" != 1 ]; then
    echo "W81A_PMAX=NOINFO reason=probe-not-ready（$LOG 里没有 W81A_READY）"; sed 's/^/  | /' "$LOG" | tail -20
    RC_PMAX=2
  else
    # 逐角色取 XID（探针自己印的；本移植里 HWND == XID）并各自 `xprop`/`xwininfo`
    for role in declared undeclared late sizecontent minonly; do
      xid="$(sed -n "s/^W81A_WINDOW role=$role .*xid=\(0x[0-9a-f]*\).*/\1/p" "$LOG" | head -1)"
      echo "$xid" > "$D/$role.xid"
      if [ -z "$xid" ]; then echo "W81A_PMAX_ROLE role=$role xid=<缺席>"; continue; fi
      DISPLAY="$DISP" xprop -id "$xid" WM_NORMAL_HINTS > "$D/$role.hints" 2>&1
      DISPLAY="$DISP" xwininfo -id "$xid" > "$D/$role.wininfo" 2>&1
      mx="$(grep -o 'program specified maximum size: [0-9]* by [0-9]*' "$D/$role.hints" | head -1)"
      mn="$(grep -o 'program specified minimum size: [0-9]* by [0-9]*' "$D/$role.hints" | head -1)"
      geo="$(awk '/Width:/{w=$2} /Height:/{h=$2; printf "%sx%s", w, h}' "$D/$role.wininfo")"
      map="$(awk '/Map State:/{print $3}' "$D/$role.wininfo")"
      echo "W81A_PMAX_ROLE role=$role xid=$xid min='${mn:-<缺席>}' max='${mx:-<缺席>}' geom=$geo map=$map"
      echo "     （探针自报：$(grep -m1 "^W81A_WINDOW role=$role " "$LOG" | sed 's/^W81A_WINDOW //')）"
    done
    DMAX="$(grep -o 'program specified maximum size: [0-9]* by [0-9]*' "$D/declared.hints" | head -1)"
    UMAX="$(grep -o 'program specified maximum size: [0-9]* by [0-9]*' "$D/undeclared.hints" | head -1)"
    # 判据
    has_prop_d=0; has_prop_u=0
    grep -q 'WM_NORMAL_HINTS' "$D/declared.hints"   && has_prop_d=1
    grep -q 'WM_NORMAL_HINTS' "$D/undeclared.hints" && has_prop_u=1
    echo "W81A_PMAX_READ declared{prop=$has_prop_d max='${DMAX:-<缺席>}'} undeclared{prop=$has_prop_u max='${UMAX:-<缺席>}'} device=$DEV"
    # ── 判据的两个量：期望值必须换算成**设备单位** ────────────────────────────
    #   `MaxWidth/MaxHeight` 是 **DIP**；`WM_NORMAL_HINTS` 是**像素**。上游写回那一句是
    #   `LogicalToDeviceUnits(...)`（`Window.cs:4892-4900`）⇒ 期望值 = DIP × **工具包自己报的
    #   设备比例**（探针现场印的 `dpi=`，公开 API `VisualTreeHelper.GetDpi`）。
    #   ⇒ 这个比例**不写死在装置里**（本机实测 ≈ 1.041667 = 100/96，但那是读数不是常量）。
    dpi="$(sed -n 's/^W81A_WINDOW role=declared .* dpi=\([0-9.]*\)x.*/\1/p' "$LOG" | head -1)"
    exp_w=""; exp_h=""
    if [ -n "$dpi" ]; then
      read -r exp_w exp_h <<EOF
$(awk -v s="$dpi" -v mw="$MAXW" -v mh="$MAXH" \
  'BEGIN{printf "%d %d", int(mw*s+0.5), int(mh*s+0.5)}')
EOF
    fi
    echo "W81A_PMAX_UNITS dpi=$dpi（探针现场读的 VisualTreeHelper.GetDpi）⇒ 期望 PMaxSize=${exp_w:-<算不出>}x${exp_h:-<算不出>}（= 声明 ${MAXW}x${MAXH} DIP × 该比例；算不出则只判出现/缺席）"
    if [ "$DEV" != PASS ]; then
      echo "W81A_PMAX=NOINFO reason=device-discrimination-unproven（装置自证 $DEV ⇒ 本腿读数无信息）"
      RC_PMAX=2
    elif [ "$has_prop_d" = 0 ] || [ "$has_prop_u" = 0 ]; then
      echo "W81A_PMAX=NOINFO reason=wm-normal-hints-absent-on-window（属性本身就不在 ⇒ 这一格无信息，不许当绿）"
      RC_PMAX=2
    else
      p1=no; n1=no; reg58=no
      if [ -n "$exp_w" ]; then
        [ "$DMAX" = "program specified maximum size: $exp_w by $exp_h" ] && p1=yes
      else
        [ -n "$DMAX" ] && p1=yes
      fi
      # 波 58 的错法（把"钳制上限/屏幕尺寸"当 PMaxSize）必须能被单独点名 —— 那不是"绿"，
      #   是另一个已登记过的错；判据要能把它与"正确的声明值"分开。
      [ "$DMAX" = "program specified maximum size: 1280 by 1024" ] && reg58=yes
      [ -z "$UMAX" ] && n1=yes
      if [ "$p1" = yes ] && [ "$n1" = yes ]; then
        echo "W81A_PMAX=PASS P1=yes(declared max='$DMAX' 期望='${exp_w}x${exp_h}') N1=yes(undeclared 无 maximum size)"; RC_PMAX=0
      else
        echo "W81A_PMAX=FAIL P1=$p1(声明 ${MAXW}x${MAXH} DIP ⇒ 期望 '${exp_w:-?} by ${exp_h:-?}'，实得 '${DMAX:-<缺席>}') N1=$n1(未声明实得 '${UMAX:-<缺席>}') reg58_wave-defect-shape=$reg58"; RC_PMAX=1
      fi
    fi
  fi
  wait "$APID" 2>/dev/null; arc=$?
  echo "W81A_PMAX_APP rc=$arc（134 = FailFast / 143 = 被收走 / 0 = 自行退出）"
  echo "---- 关键行（探针 + shim 的 WMSIZE_DIAG）----"
  grep -E '^(W81A_|\[WMSIZE_DIAG\])' "$LOG" | sed 's/^/  /'
  grep -q 'HEAVYSLOT=MAXHOLD_KILL\|HEAVYSLOT=NOINFO' "$LOG" && { echo "W81A_PMAX=NOINFO reason=slot-refused-or-killed（那两行不是读数）"; RC_PMAX=2; }
fi

# ════════════════════════════════════════════════════════════════════════════
# A0 腿：最小 FlowDocument 页面的原生需求序列（真值 = ld.so 日志）
# ════════════════════════════════════════════════════════════════════════════
if [ "$LEG" = a0 ] || [ "$LEG" = both ]; then
  D="$OUT/a0"; rm -rf "$D"; mkdir -p "$D"
  LDDBG="${W81A_LDDEBUG_DIR:-/dev/shm/w81a-lddebug}"
  rm -rf "$LDDBG"; mkdir -p "$LDDBG"

  echo "---- A0-P1 设备自证（绊线自身的判别力）----"
  bash "$REPO/build/MilBridge/tools/t1b-ls-tripwire.sh" --selftest > "$D/tripwire-selftest.log" 2>&1
  st_rc=$?
  grep -E '^ST_ATTEST=|装置自证' "$D/tripwire-selftest.log" | sed 's/^/  /'
  echo "W81A_A0_TRIPWIRE_SELFTEST rc=$st_rc"

  # ⚠️ `LD_DEBUG=symbols` 对 .NET 进程是**巨量 I/O** ⇒ 日志落 tmpfs；外层槽 + 内层 timeout 双保险
  ( cd "$BIN" && DISPLAY="$DISP" T1B_LDDEBUG_DIR="$LDDBG" \
      slot timeout 240 bash "$REPO/build/MilBridge/tools/t1b-ls-tripwire.sh" "$D/tripwire" -- \
        timeout 150 dotnet "$BIN/$ASM.dll" --mode=flowdoc --hold=6 ) > "$D/run.log" 2>&1
  a0_rc=$?
  echo "W81A_A0_RUN rc=$a0_rc（134 = FailFast；124 = 内层 timeout 收走）"
  grep -E '^(命令退出码|HEAVYSLOT=)' "$D/run.log" | sed 's/^/  /' | head -10
  # ⚠️【本仓的 `QUOTE-TRAP`：双引号里的反引号 = **命令替换**】这一行原先写成
  #   echo "---- 应用自己的输出（`t1b-ls-tripwire.sh` 把…）----"
  #   实测被 shell 执行成 `t1b-ls-tripwire.sh: 未找到命令`（`verify-all` 第 `[15]` 步专治这一族）。
  #   修法 = 提示文本里**不许出现**反引号（改用单引号包整行，或把反引号去掉）。
  echo '---- 应用自己的输出（t1b-ls-tripwire.sh 把被测命令的 stdout/stderr 落在 tripwire/cmd.{out,err}）----'
  grep -hE '^W81A_' "$D/tripwire/cmd.out" "$D/tripwire/cmd.err" 2>/dev/null | sed 's/^/  /' | head -40
  echo "---- 异常原文（有就抄，没有就明说没有）----"
  #   ⚠️【`#50` W95A 修（`PIPEFAIL-SIGPIPE` 那一族；行为等价，只换喂法）】原写法是
  #     `grep … | head -8 | sed … || echo "（无）"` —— `head -8` 抄满就早退 ⇒ `grep` 吃 SIGPIPE(141)
  #     ⇒ 本脚本开头是 `set -uo pipefail` ⇒ **管道 rc≠0 ⇒ `||` 触发 ⇒ 明明有异常原文却印"（无）"**
  #     （假"没有"）。改成「先把 head 的结果收进变量，再按有没有内容分两路印」⇒ 与 SIGPIPE 无关。
  _exc8="$(grep -hE 'EntryPointNotFoundException|Unable to find an entry point|Process terminated|Unhandled exception|Invariant|FailFast' \
       "$D/tripwire/cmd.out" "$D/tripwire/cmd.err" 2>/dev/null | head -8 || true)"
  if [ -n "$_exc8" ]; then printf '%s\n' "$_exc8" | sed 's/^/  /'; else echo "  （无）"; fi
  echo "---- 绊线汇总（LS 家族查找次数）----"
  sed -n '/LS 家族符号被查找/,/关键符号/p' "$D/tripwire/ls-tripwire.txt" 2>/dev/null | sed 's/^/  /' | head -40
  echo "---- 关键符号 5 条（绊线自带的那 5 个）----"
  sed -n '/关键符号/,/^$/p' "$D/tripwire/ls-tripwire.txt" 2>/dev/null | sed 's/^/  /'

  # ── 判据 A0-P2：被测路径真的走到了吗（应用输出在 tripwire/cmd.{out,err}）─────────
  #   ⚠️【判据**再表述**（读数后；原判据见报告 §0.2，是"`step=flowdoc-shown` 必须在场"）】
  #     第一次读数就把原判据打穿了：那一句标记写在 `w.Show()` **返回之后**，而本轮**异常是从
  #     `Show()` 里抛出的**（`EntryPointNotFoundException: CreateInstalledObjectsInfo`）⇒
  #     `flowdoc-shown` 永远不会打印。照原判据会判 `no` ⇒ 把"真的走到了文档布局"读成"没走到"。
  #     ⇒ 改成**两条独立证据之一在场**（都指向"需求由 FlowDocument 布局提出"）：
  #       ① `step=flowdoc-shown`（原档）；
  #       ② `step=flowdoc-host-built` **＋** 异常文本点名 **PTS 上下文族入口**
  #          （`CreateInstalledObjectsInfo|GetFloaterHandlerInfo|GetTableObjHandlerInfo|CreateDocContext`）。
  #     这不是放宽：②证明 `FlowDocument` 与宿主都建好了，且缺的符号恰是 PTS 族入口
  #     ⇒ 需求来自**文档布局**这条链（而不是别的窗口/别的原因）。
  if grep -qh '^W81A_PROBE step=flowdoc-shown' "$D/tripwire/cmd.out" "$D/tripwire/cmd.err" 2>/dev/null; then
    echo "W81A_A0_P2=yes（原判据档：step=flowdoc-shown 在场）"
  elif grep -qh '^W81A_PROBE step=flowdoc-host-built' "$D/tripwire/cmd.out" "$D/tripwire/cmd.err" 2>/dev/null \
    && grep -qhE 'CreateInstalledObjectsInfo|GetFloaterHandlerInfo|GetTableObjHandlerInfo|CreateDocContext' \
         "$D/tripwire/cmd.out" "$D/tripwire/cmd.err" 2>/dev/null; then
    echo "W81A_A0_P2=yes（再表述档：宿主已建 ＋ 缺的符号 = PTS 上下文族入口 ⇒ 需求来自 FlowDocument 布局）"
  else
    echo "W81A_A0_P2=no（既无 flowdoc-shown，也无'宿主已建 ＋ PTS 族缺符号'这对证据）"
  fi
  echo "---- 分析（顺序 + FOUND/MISS + 与 27 条对表）----"
  python3 "$HERE/w81a-a0-analyze.py" "$LDDBG" "$D" 2>&1 | tee "$D/a0-analyze.txt" | sed 's/^/  /'
  if grep -q '^W81A_A0=MEASURED' "$D/a0-analyze.txt" 2>/dev/null; then RC_A0=0; else RC_A0=2; fi
fi

# ── 汇总 ─────────────────────────────────────────────────────────────────────
echo "W81A_LEGS leg=$LEG pmax_rc=$RC_PMAX a0_rc=$RC_A0 out=$OUT"
if [ "$RC_PMAX" = 1 ] || [ "$RC_A0" = 1 ]; then exit 1; fi
if [ "$RC_PMAX" = 2 ] || [ "$RC_A0" = 2 ]; then exit 2; fi
exit 0
