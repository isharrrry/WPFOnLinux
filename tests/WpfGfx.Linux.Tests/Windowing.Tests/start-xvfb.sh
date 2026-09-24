#!/usr/bin/env bash
# X11 用例的 X server 起停。
#
#   ./start-xvfb.sh start   → 起 Xvfb :99（1280x1024x24），已起则复用
#   ./start-xvfb.sh stop    → 停掉
#   ./start-xvfb.sh run     → 起 + 设 DISPLAY + 跑本目录全部测试
#
# 深度写死 24（而不是让 Xvfb 自选），是因为 XPutImage 的像素打包要按 visual 的
# RGB 掩码来，深度变了 golden 基准就对不上。CI 与本地必须用同一个深度。
set -uo pipefail

DISPLAY_NUM="${DISPLAY_NUM:-99}"
SCREEN="${SCREEN:-1280x1024x24}"

start() {
    if xdpyinfo -display ":${DISPLAY_NUM}" >/dev/null 2>&1; then
        echo "Xvfb :${DISPLAY_NUM} 已在运行"
        return 0
    fi
    Xvfb ":${DISPLAY_NUM}" -screen 0 "${SCREEN}" -nolisten tcp >"/tmp/xvfb-${DISPLAY_NUM}.log" 2>&1 &
    for _ in $(seq 1 40); do
        sleep 0.1
        if xdpyinfo -display ":${DISPLAY_NUM}" >/dev/null 2>&1; then
            echo "Xvfb :${DISPLAY_NUM} 已启动（${SCREEN}）"
            return 0
        fi
    done
    echo "Xvfb :${DISPLAY_NUM} 启动失败，日志：/tmp/xvfb-${DISPLAY_NUM}.log" >&2
    return 1
}

stop() {
    # 【`D-G103` 族修法】旧写法 `pkill -f "Xvfb :N"` **会匹配到承载本脚本的那个 shell 自己**
    #   （它的 cmdline 里含同一串字面量）⇒ 自杀（本会话现场咬过一次）。
    #   ⇒ 逐 pid 读 `/proc/<pid>/cmdline`：**先排除 `$$` 与 `${PPID}`**，再按 argv0 基名 == `Xvfb`
    #     ∧ **某个 argv 恰好等于** `:N`（`grep -qx`，不是子串）认领，最后**只按 PID** kill。
    local p a0 hit=""
    for p in /proc/[0-9]*; do
        p="${p#/proc/}"
        [ "$p" = "$$" ] && continue
        [ "$p" = "${PPID:-0}" ] && continue
        [ -r "/proc/$p/cmdline" ] || continue
        a0="$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | sed -n 1p)"
        case "${a0##*/}" in Xvfb) ;; *) continue ;; esac
        tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | grep -qx ":${DISPLAY_NUM}" || continue
        kill "$p" 2>/dev/null && hit="$p"
    done
    if [ -n "$hit" ]; then echo "已停止 Xvfb :${DISPLAY_NUM}（只按 PID：pid=$hit）"; else echo "Xvfb :${DISPLAY_NUM} 未运行"; fi
}

run() {
    start || return 1
    DISPLAY=":${DISPLAY_NUM}" dotnet test "$(dirname "$0")/WpfGfx.Linux.Windowing.Tests.csproj" "$@"
}

case "${1:-start}" in
    start) start ;;
    stop)  stop ;;
    run)   shift; run "$@" ;;
    *) echo "用法: $0 {start|stop|run}" >&2; exit 2 ;;
esac
