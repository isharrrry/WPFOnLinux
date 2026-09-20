#!/usr/bin/env bash
# WpfTextDemo · **最小复现矩阵**（一行命令；把 /tmp 里那套 XAML 变体固化成可复跑的东西）
#
#   tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo-minrepro.sh [超时秒数] [重复次数]
#
# 它跑 4 个档位 × N 次，输出一张"崩溃矩阵"：
#
#   default   验收·主档   默认配置（清空全部 WPF_LINUX_*/HLWPF_*）       ← 门禁结论只看它
#   env       验收·对照   带字体 env（复刻 M2 验收配置）                  ← 门禁结论只看它
#   degraded  诊断·非验收 应用侧关掉折行/省略号/对齐/列表项（--diagnostic-degraded）
#   minimal   诊断·非验收 代码构造最小可视树（3 个短 TextBlock）（--minimal）
#
# 为什么要这四档（2026-09-11 实测出来的）：
#   · 文本量大的窗口**稳定崩**（`LoCreateContext`，文本回落 LineServices），
#     而缩到 3 个短 TextBlock 之后同一份代码**三连跑全过** ⇒ 崩溃与"文本量/特性"强相关，
#     且**间歇**（同一个 XAML 也会时崩时不崩）⇒ 所以必须重复 N 次看通过率，单跑一次会骗人。
#   · degraded / minimal **不是**"绕过缺陷后的通过"：它们显式标注降级了什么，
#     并且**不参与**验收结论（`WPTD_SUMMARY` 只看 default/env）。
#
# 本脚本是 run-wpftextdemo.sh 的薄包装：真正的装配/判据/台账都在那边，避免两份实现漂移。

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TIMEOUT="${1:-45}"
REPEAT="${2:-3}"

echo "== WpfTextDemo 最小复现矩阵（4 档 × ${REPEAT} 次，每次超时 ${TIMEOUT}s）"
echo "   真正的装配与判据在 run-wpftextdemo.sh；这里只固定档位组合与重复次数。"
echo

WPTD_REPEAT="$REPEAT" "$HERE/run-wpftextdemo.sh" "$TIMEOUT" --tier matrix
rc=$?

echo
echo "== 矩阵退出码：$rc（0 = 被选中的 4 档**全部**通过；验收结论另见上面的 WPTD_SUMMARY）"
echo "   读法："
echo "     WPTD_SUMMARY=FAIL  → 默认配置/对照档没过（门禁红，当前应为红：文本回落 LineServices）"
echo "     WPTD_TIER_SUMMARY=<档> passed=k/N → 该档 N 次里过了 k 次；k<N 即**间歇**"
echo "     诊断档通过 ≠ 默认配置可用（它关掉/替换了东西）"
exit "$rc"
