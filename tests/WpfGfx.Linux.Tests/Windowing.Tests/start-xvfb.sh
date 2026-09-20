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
    pkill -f "Xvfb :${DISPLAY_NUM}" && echo "已停止 Xvfb :${DISPLAY_NUM}" || echo "Xvfb :${DISPLAY_NUM} 未运行"
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
