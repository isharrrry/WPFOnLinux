#!/usr/bin/env bash
#
# 桥源码指纹（BRIDGE_SRC_FP）—— **唯一实现**。
#
# 【为什么必须"唯一实现"】本项目已登记过一类事故："一个数字两个消费者，一个陈旧"
#   （`ClosedLoop` 的 28 vs `MilExportTests` 的 27；`grep -c` 把判定语句本身数进去）。
#   归档要在**发布脚本**与**门禁 runner** 两处比对同一个指纹 ⇒ 若各写一遍"文件清单"，
#   两份实现迟早漂移，而漂移的表现恰好是"闸门红/绿取决于谁算的" —— 比没有闸门更坏。
#   ⇒ 两边**都调本脚本**，不许内联重写。
#
# 【它测什么】"当前树里的桥源码" 的指纹。用途有两个，都是**直接测量**：
#   1) 发布时写进 `.artifacts/publish/.../bridge-src-fp.txt`（发布动作的输入指纹）；
#   2) 应用级门禁开跑前重算，与上面那个文件比对 ⇒ `BRIDGE_SRC_STALE=yes` 的含义是
#      **"部署的 .so 不是当前源编出来的"**（例如 T2b 22:37 改了 Rendering/** 而桥是
#      22:24 发的 —— 2026-09-13 真实发生过，#6 就是这么被冻成"源陈旧"的）。
#   为什么可信：主控实测 **AOT 发布逐字节可复现**（同源重发 `ndiff=0`；`-t:Rebuild`
#   全量重编后仍是同一 sha）⇒ "源指纹相同 ⇒ 产物 sha 相同"是有实测支撑的。
#
# 【边界（必须显式写出，否则就是这个脚本自己在骗人）】
#   * 覆盖根：`src/WpfGfx.Linux/**` + `build/MilBridge/**`（桥的编译输入：`MilBridge.Linux.csproj`
#     只 ProjectReference `src/WpfGfx.Linux/WpfGfx.Linux.csproj`）。
#   * 排除：`bin/` `obj/` `.artifacts/`（构建产物；obj 里有生成的 `AssemblyInfo.cs`，
#     若纳入，指纹会随"构建过一次"而变 ⇒ 恒 yes 的假警报）；`build/MilBridge/tests/**`
#     （测试工程）、`build/MilBridge/alt-route-b/**`（历史路线对比实验）、
#     `build/MilBridge/spike/**`（AOT spike）—— 这三者都**不是 .so 的输入**，
#     其中后两者是死代码，若纳入，动一下它们就会产生"假 stale"（浪费一次重发+重冻）。
#     注意取向：**默认收全 `build/MilBridge/**`，只按名字排除这三处** ⇒ 将来新增的
#     工程默认被覆盖（宁可多报，不可漏报；漏报正是 #6 那次"源陈旧冻结"的成因）。
#   * 若将来给桥**新增**了这两个根之外的 ProjectReference，**必须回来加根**；
#     指纹不会自己发现这件事（`--list` 是给人看的核对入口）。
#
# 用法：
#   bash build/bridge-src-fp.sh            # 打 BRIDGE_SRC_FP=<16hex> BRIDGE_SRC_N=<n>
#   bash build/bridge-src-fp.sh --list     # 额外逐行列出参与指纹的文件（供人工核对）
#   bash build/bridge-src-fp.sh --selftest # 两极化自测（见下），exit 0=PASS / 2=FAIL
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

src_list() {
    find src/WpfGfx.Linux build/MilBridge \
        \( -name bin -o -name obj -o -name .artifacts \
           -o -path 'build/MilBridge/tests' -o -path 'build/MilBridge/alt-route-b' -o -path 'build/MilBridge/spike' \) -prune -o \
        -type f \( -name '*.cs' -o -name '*.csproj' -o -name '*.props' -o -name '*.targets' -o -name '*.resx' \) \
        -print 2>/dev/null | LC_ALL=C sort
}

src_fp() {
    # 指纹 = 对"逐文件 sha256 的有序清单"再取一次 sha256（前 16 位）。
    # 注意：**路径参与**指纹（重命名 = 变化），这是有意的。
    src_list | xargs -r sha256sum | sha256sum | cut -c1-16
}

case "${1:-}" in
--list)
    src_list | while IFS= read -r f; do printf '%s  %s\n' "$(sha256sum "$f" | cut -c1-16)" "$f"; done
    printf 'BRIDGE_SRC_FP=%s BRIDGE_SRC_N=%s\n' "$(src_fp)" "$(src_list | wc -l)"
    ;;
--selftest)
    # 两极化牙：**能变红、也能变回绿**，并且**能测出"该排除的真的被排除了"**。
    # 三条极性缺一不可 —— 前两条防"恒值"，第三条防"把 obj 也数进去"（那会让指纹随构建自变）。
    set +e
    fp0="$(src_fp)"
    probe="src/WpfGfx.Linux/__fp_selftest_probe.cs"
    objprobe="src/WpfGfx.Linux/obj/__fp_selftest_probe.cs"
    cleanup() { rm -f "$probe"; rm -f "$objprobe"; }
    trap cleanup EXIT
    printf '// fp selftest probe\n' > "$probe"
    fp1="$(src_fp)"
    rm -f "$probe"
    fp2="$(src_fp)"
    mkdir -p "$(dirname "$objprobe")" 2>/dev/null
    printf '// fp selftest probe (should be EXCLUDED)\n' > "$objprobe"
    fp3="$(src_fp)"
    rm -f "$objprobe"
    printf 'FP_SELFTEST fp0=%s\n' "$fp0"
    printf 'FP_SELFTEST fp1=%s（加一个 .cs ⇒ 期望 != fp0）\n' "$fp1"
    printf 'FP_SELFTEST fp2=%s（删掉 ⇒ 期望 == fp0）\n' "$fp2"
    printf 'FP_SELFTEST fp3=%s（只在 obj/ 里加 ⇒ 期望 == fp0）\n' "$fp3"
    if [ "$fp1" != "$fp0" ] && [ "$fp2" = "$fp0" ] && [ "$fp3" = "$fp0" ]; then
        echo "FP_SELFTEST=PASS（三条极性全对：能变红 / 能回绿 / obj 真被排除）"; exit 0
    fi
    echo "FP_SELFTEST=FAIL（这个指纹至少有一条极性不成立 ⇒ 别拿它当闸门）" >&2; exit 2
    ;;
*)
    printf 'BRIDGE_SRC_FP=%s BRIDGE_SRC_N=%s\n' "$(src_fp)" "$(src_list | wc -l)"
    ;;
esac
