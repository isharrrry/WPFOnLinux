#!/usr/bin/env bash
# WpfFeatureProbe · `Win32Exception (1400)` **启动复现率**测量（N≥10）
#
# 【为什么要单独量这条】2026-09-11 的默认配置门禁 env 档 rep1 以
#     System.ComponentModel.Win32Exception (1400) ← MS.Win32.UnsafeNativeMethods.CreateWindowEx
#       ← MS.Win32.HwndWrapper..ctor ← MS.Win32.MessageOnlyHwndWrapper..ctor
#       ← System.Windows.Threading.Dispatcher..ctor ← System.Windows.Application..ctor
#   **启动即崩（窗口都没出来）**，而同 tier 的 rep2/3 在**同一个 display** 上正常出窗
#   ⇒ 疑似"启动期竞态"，且比"某块画不出来"严重得多（任何真 WPF 应用都可能中）。
#   本脚本把复现率量出来，并把**当时的 X 状态**一起留痕（区分"X 不在"与"X 在但创建失败"）。
#
# 用法：
#   run-wpfprobe-1400rate.sh <运行目录> [次数 N=12] [档位 default|env] [样例名=WpfFeatureProbe]
#     <运行目录> = runner 装配出来的那个 OUT（里面有样例 dll 与全部自产件）
#   样例名：`WpfFeatureProbe`（默认，参数默认 `--only=popup`）或 `WpfTextDemo`
#     —— **观测到 1400 的是 WpfTextDemo**，"原样复现"就换样例：
#        run-wpfprobe-1400rate.sh <目录> 12 default WpfTextDemo
#        （WFP1400_ARGS 可覆盖样例参数；不设时 WpfTextDemo 走**无参默认档**，与门禁一致）
#
# 判据（主控口径）：**≥2/N ⇒ 按 P0 派单**。单次成功不能证明"已经好了"，单次失败也不能
#   证明"必崩"—— 所以逐次记 `exit` / 是否出窗 / `err1400` 计数 / `loadavg`。
#
# 纪律（与两个 runner 同规则）：Xvfb **自起自灭**；收尾**只按 PID**（脚本里不出现
#   `pkill|killall|kill -f`）；一次只跑一个应用；每轮留 `leftover` 与负载读数。
set -u

APP_DIR=${1:?用法: $0 <运行目录> [N] [default|env] [样例名]}
N=${2:-12}
TIER=${3:-default}
SAMPLE=${4:-WpfFeatureProbe}
REPO=${REPO:-/home/links-dev/netTest/wpf-linux-20260906/wpf-linux}
DISPLAY_NUM=${WFP1400_DISPLAY:-:97}
# 样例参数：探测样例默认只起一块（快）；观测到 1400 的是 WpfTextDemo，则用默认档无参启动（与门禁一致）
if [ "$SAMPLE" = "WpfFeatureProbe" ]; then ARGS=${WFP1400_ARGS---only=popup}; else ARGS=${WFP1400_ARGS-}; fi
export PATH="$HOME/.dotnet:$PATH"
export DISPLAY="$DISPLAY_NUM"

case "$TIER" in default|env) ;; *) echo "❌ 档位只认 default|env（收到 '$TIER'）" >&2; exit 2 ;; esac
[ -f "$APP_DIR/$SAMPLE.dll" ] || { echo "❌ $APP_DIR 里没有 $SAMPLE.dll（先装配运行目录）" >&2; exit 2; }

OUT="$HOME/wfp-runs/repro1400-$TIER-$(date +%m%d-%H%M%S)"
mkdir -p "$OUT"
FONT_FILE="$REPO/build/fonts-ui/UI-NoLayout.ttf"
FONT_DIR="$(cd "$(dirname "$FONT_FILE")" && pwd)"

echo "== Win32Exception(1400) 启动复现率测量 =="
echo "   运行目录=$APP_DIR  次数=$N  档位=$TIER  DISPLAY=$DISPLAY_NUM"
echo "   输出目录=$OUT"
echo "   loadavg=$(cat /proc/loadavg)  mem_available=$(free -m | awk 'NR==2{print $7}') MB  cpu=$(nproc)核"

Xvfb "$DISPLAY_NUM" -screen 0 1280x1024x24 -nolisten tcp >"$OUT/xvfb.log" 2>&1 &
XPID=$!
trap 'kill -TERM "$XPID" 2>/dev/null' EXIT INT TERM
sleep 2
if ! xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1; then
    echo "❌ Xvfb $DISPLAY_NUM 起不来（见 $OUT/xvfb.log）"; exit 3
fi
echo "   Xvfb PID=$XPID（本脚本只按这个 PID 收尾）"

crash1400=0; alive_ok=0; other_crash=0; no_window=0
for i in $(seq 1 "$N"); do
    xstate=dead; xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 && xstate=ok
    xpid_now="$(pgrep -f "Xvfb $DISPLAY_NUM" | head -1 || true)"     # 只记录，不据此杀
    la="$(cut -d' ' -f1 /proc/loadavg)"
    log="$OUT/r$i.log"
    if [ "$TIER" = "env" ]; then
        ( cd "$APP_DIR" && exec env WPF_LINUX_FONT_DIR="$FONT_DIR" WPF_LINUX_UI_FONT="Noto Sans" \
            dotnet "$SAMPLE.dll" $ARGS >"$log" 2>&1 ) &
    else
        ( cd "$APP_DIR" && exec env -u WPF_LINUX_FONT_DIR -u WPF_LINUX_UI_FONT \
            -u HLWPF_FONT_DIR -u HLWPF_UI_FONT dotnet "$SAMPLE.dll" $ARGS >"$log" 2>&1 ) &
    fi
    APID=$!
    win=no
    for _t in $(seq 1 24); do
        kill -0 "$APID" 2>/dev/null || break
        if xwininfo -root -tree -display "$DISPLAY_NUM" 2>/dev/null | grep -q "$SAMPLE"; then win=yes; break; fi
        sleep 0.25
    done
    kill -0 "$APID" 2>/dev/null && kill -TERM "$APID" 2>/dev/null
    wait "$APID" 2>/dev/null; rc=$?
    c1400="$(grep -ac 'Win32Exception (1400)' "$log" 2>/dev/null || true)"; c1400=${c1400:-0}
    cmsg="$(grep -acE 'Unrecoverable|Unhandled exception' "$log" 2>/dev/null || true)"; cmsg=${cmsg:-0}
    if [ "$c1400" -gt 0 ]; then
        verdict="WIN32-1400"; crash1400=$((crash1400 + 1))
    elif [ "$rc" = "143" ] && [ "$win" = "yes" ]; then
        verdict="alive-ok"; alive_ok=$((alive_ok + 1))
    elif [ "$cmsg" -gt 0 ]; then
        verdict="other-crash"; other_crash=$((other_crash + 1))
    else
        verdict="no-window"; no_window=$((no_window + 1))
    fi
    printf 'REP=%02d verdict=%-11s exit=%-4s window=%-3s x=%-4s xvfb_pid=%-7s loadavg=%-5s err1400=%s\n' \
        "$i" "$verdict" "$rc" "$win" "$xstate" "${xpid_now:-none}" "$la" "$c1400" | tee -a "$OUT/rows.txt"
done

echo
echo "== 原始片段（凡命中 1400 的轮次，逐条打印）=="
hit=0
for f in "$OUT"/r*.log; do
    [ -f "$f" ] || continue
    if grep -aq 'Win32Exception (1400)' "$f"; then
        hit=$((hit + 1)); echo "--- $(basename "$f")"; grep -aA 12 'Win32Exception (1400)' "$f" | head -14
    fi
done
[ "$hit" = "0" ] && echo "（无命中：$N 次里一次都没出现 1400）"

leftover="$(pgrep -c -f "dotnet $SAMPLE.dll" 2>/dev/null || true)"; leftover=${leftover:-0}
echo
echo "WFP1400_SUMMARY tier=$TIER total=$N crash1400=$crash1400 alive_ok=$alive_ok other_crash=$other_crash no_window=$no_window"
echo "WFP1400_RATE=$crash1400/$N"
echo "WFP1400_VERDICT=$([ "$crash1400" -ge 2 ] && echo 'P0（≥2 次复现，按主控口径派单）' || echo '未达 P0 阈值（<2 次）')"
echo "WFP1400_LEFTOVER_AFTER=$leftover （全机计数，**只数不杀**；本脚本起的应用一律已 wait）"
echo "WFP1400_ROWS=$OUT/rows.txt  WFP1400_LOGS=$OUT"
