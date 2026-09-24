#!/usr/bin/env bash
# WpfTextDemo · **默认配置门禁** runner（一条命令可重跑）
#
#   tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh [超时秒数] [选项]
#
#   tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 45
#   tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 45 --tier env
#   WPTD_RUN_DIR=/tmp/my-run tests/.../run-wpftextdemo.sh 60      # 并发时各自指定
#
# ── 它为什么存在（主控 2026-09-11 的实测教训）─────────────────────────────────
#   M2 的验收件是**带字体 env** 跑出来的（`HLWPF_UI_FONT=…/UI-NoLayout.ttf`）。
#   同一个二进制、**不设任何字体 env**（= 真应用拿到的默认配置）时，HelloWpf 一个字都不画
#   （`未画种类 1`、PNG 46,902 B）。⇒ 我们过去的验收面是「一个样例 × 带 env 覆盖」，
#   而真应用拿到的是「默认配置」。
#
#   所以本 runner 的**主档就是"默认配置"**（清空全部 WPF_LINUX_*/HLWPF_* 字体 env），
#   "带 env"那一档只是**对照**。两档都必须过；只过一档 = 失败（`WPTD_SUMMARY=FAIL`）。
#
# ── 判据（每档四条，缺一即该档 FAIL）────────────────────────────────────────
#   ① 进程在截屏时刻**存活**，且收尾后退出码 = **143**（被本 runner 用 SIGTERM 正常终止）；
#   ② 台账里出现 `未画种类 0`（通道里**每一种**指令都真的画了；非 0 会打印实际条款）；
#   ③ 截图**非空非纯色**：文件非空 + 不同颜色数 ≥ 阈值（阈值见下，实测标定）；
#   ④ **文字真的在屏上**：按"每个可见特性各自的颜色"逐色计数（不是白像素总数）——
#      *文字缺失* 与 *文字在但没上屏* 在这条判据下是两种不同的读数。
#      ⚠️ 直方图/像素计数**不能替代读图**：本 runner 会把 PNG 路径打成机读行，由人/视觉复核。
#
# ── 本脚本刻意避开的四个坑（都是主控实测踩过的）──────────────────────────────
#   1. `WPTD_RUN_DIR` 默认**带 `$$`** —— 共用默认目录会被并发运行互相覆盖（截图丢过）。
#   2. 收尾用 `kill $XPID`（记下自己起的 Xvfb 的 PID），**绝不 `pkill -f`**
#      —— `pkill -f 'Xvfb :97'` 会匹配到本脚本自己命令行里的同一串字面量，把自己 SIGTERM 掉。
#   3. 退出码**一律用文件重定向 / 直接 wait** 取，**绝不** `... | tail; RC=$?`
#      （那拿到的是 `tail` 的状态，永远 0 —— 会把失败读成成功）。
#   4. **任何断言失败都必须让脚本失败**；判据一律是"取到的值"，不是 grep 的退出码
#      （`grep -mE1` 这种非法实参曾经让 ✅ 旁边挂着 `grep: 无效的最大计数` 的假绿）。

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
# ★ `#39`：自产件配置**只许从唯一声明处取**（`build/SelfBuiltConfig.props`）。
#   本脚本里原先写死 `bin/Debug` 的三处（样本 bin / 自产件一致性扫描 / Provider）全部跟随它。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../../build/selfbuilt-config.sh"

TIMEOUT=45
TIER=both
NO_BUILD=0
INPUT_PROBE=0
BRIDGE_IDENTITY_SELFTEST="${WPTD_BRIDGE_IDENTITY_SELFTEST:-0}"
BRIDGE_FP_SELFTEST="${WPTD_BRIDGE_FP_SELFTEST:-0}"
EXTRA_APP_ARGS=""
# 【注意】参数解析用 while+shift，**不要**用 `for arg in "$@"` + 内部 shift：
#   后者在 `--tier matrix` 上会把 `matrix` 再当成一个位置参数重复处理（实测踩到：
#   合法档位被自己的解析器判成非法，退出 2）。这一类"解析器 bug"和判据 bug 一样会骗人。
while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-build)    NO_BUILD=1; shift ;;
        --input-probe) INPUT_PROBE=1; shift ;;
        --bridge-identity-selftest) BRIDGE_IDENTITY_SELFTEST=1; shift ;;
        --bridge-fp-selftest)       BRIDGE_FP_SELFTEST=1; shift ;;
        --tier)        TIER="${2:-both}"; shift 2 ;;
        # 额外透传给应用的参数（诊断用；例：--app-args="--text-volume=25"）
        --app-args=*)  EXTRA_APP_ARGS="${1#--app-args=}"; shift ;;
        default|env|both|degraded|minimal|all|matrix) TIER="$1"; shift ;;
        *[!0-9]*)      echo "用法: $0 [超时秒数] [--tier default|env|both|degraded|minimal|all|matrix] [--no-build] [--input-probe] [--bridge-identity-selftest] [--bridge-fp-selftest]" >&2; exit 2 ;;
        *)             TIMEOUT="$1"; shift ;;
    esac
done
# 验收档：default（主）/ env（对照） ｜ 诊断档：degraded / minimal ｜ 组合：both / all / matrix
case "$TIER" in
    default|env|both|degraded|minimal|all|matrix) ;;
    *) echo "❌ --tier 只认 default|env|both|degraded|minimal|all|matrix（收到 '$TIER'）" >&2; exit 2 ;;
esac

# ── 桥→源 身份闸门（主控 2026-09-14 派；闭合 `src/** → 桥` 这条**静默陈旧洞**）──────
# 【为什么必须加】#6 冻结用的桥是 **22:24:35** 发的，而 T2b 在 **22:37:39/22:37:52** 改了
#   `src/WpfGfx.Linux/Rendering/{SkiaRenderBackend,DrawInstructionCensus}.cs` ⇒ **#6 的桥不含那两个修法**。
#   当时全仓**没有任何闸门覆盖 `src/** → 桥`**：`WFP_SRC_STALE` 只看 `build/*.Linux/**`
#   （且只在 probe runner 里、还是 advisory），`hbtextline_shim_stale` 只看 `build/shims/**`
#   ⇒ 部署件可以**静默地比源旧**，而所有读数看起来一切正常。
# 【两个位】
#   ① **便宜位（每趟默认算）**：发布目录里的 `bridge-src-fp.txt`（发布时写入的源码指纹）
#      vs **现树重算**值。`BRIDGE_SRC_STALE=yes` 的含义 = **部署的 .so 不是当前源编出来的
#      ⇒ 本趟读数作废**。依据：主控实测 **AOT 发布逐字节可复现**（同源重发 `ndiff=0`；
#      `-t:Rebuild` 全量重编后仍同 sha）⇒ "源指纹相同 ⇒ 产物 sha 相同"有实测支撑。
#      ⚠️ **文件缺失 / 解析不出 ⇒ `NOINFO`（无信息），绝不许报 `no`** —— "缺读数被当绿"
#      在本项目已发生两次（`hbtextline_shim_stale` 按构造恒 no、桥契约对整行判 `[`）。
#   ② **直接测量位（只在牙里跑，不做默认）**：同一 ArtifactsPath 重发一次，比"重发前/后 sha"，
#      不等即判红。它会**重写 .so** ⇒ 跑前落锁 `$BRIDGE_REPUBLISH_LOCK`、跑完删除
#      （T1b/M7b 已被告知"见锁不开跑加载桥的东西"）。
#   指纹实现**只调** `build/bridge-src-fp.sh`（主控指定"唯一实现"，**禁止内联重写**：
#   两份实现迟早漂移，而漂移的表现恰好是"红/绿取决于谁算的"，比没有闸门更坏）。
BRIDGE_FP_SCRIPT="$ROOT/build/bridge-src-fp.sh"
BRIDGE_PUB_DIR="$ROOT/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64"
BRIDGE_REPUBLISH_LOCK=/tmp/bridge-republish.lock

bridge_src_fp_now() {   # stdout=现树指纹(16hex)；算不出 ⇒ 非 0 退出（**不打印空串骗调用方**）
    [ -f "$BRIDGE_FP_SCRIPT" ] || return 1
    local v; v="$(bash "$BRIDGE_FP_SCRIPT" 2>/dev/null | sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p' | head -1)"
    [ -n "$v" ] || return 1
    printf '%s' "$v"
}
bridge_src_fp_pub() {   # $1=fp 文件 ⇒ stdout=指纹(16hex)；缺/解析不出 ⇒ 非 0
    [ -f "$1" ] || return 1
    local v; v="$(sed -n 's/.*BRIDGE_SRC_FP=\([0-9a-f]\{16\}\).*/\1/p' "$1" | head -1)"
    [ -n "$v" ] || return 1
    printf '%s' "$v"
}
bridge_src_stale() {    # $1=发布目录 ⇒ stdout: yes|no|NOINFO
    local f="$1/bridge-src-fp.txt" pub now
    [ -f "$f" ] || { printf 'NOINFO'; return; }
    pub="$(bridge_src_fp_pub "$f")" || { printf 'NOINFO'; return; }
    now="$(bridge_src_fp_now)"     || { printf 'NOINFO'; return; }
    if [ "$pub" = "$now" ]; then printf no; else printf yes; fi
}
bridge_src_stale_basis() {  # $1=发布目录 ⇒ 诊断串（说明为什么是这个判定）
    local f="$1/bridge-src-fp.txt" pub now
    [ -f "$f" ] || { printf 'no-file'; return; }
    pub="$(bridge_src_fp_pub "$f")" || { printf 'unparsable'; return; }
    now="$(bridge_src_fp_now)"     || { printf 'no-recompute'; return; }
    printf 'pub=%s now=%s' "$pub" "$now"
}
bridge_so_file_match() {    # $1=发布目录 $2=实际部署的 .so ⇒ stdout: yes|no|NOINFO
    local f="$1/bridge-src-fp.txt" want got
    [ -f "$f" ] || { printf 'NOINFO'; return; }
    want="$(sed -n 's/.*BRIDGE_SO_SHA256=\([0-9a-f]\{16\}\).*/\1/p' "$f" | head -1)"
    got="$(sha256sum "$2" 2>/dev/null | cut -c1-16)"
    [ -n "$want" ] && [ -n "$got" ] || { printf 'NOINFO'; return; }
    if [ "$want" = "$got" ]; then printf yes; else printf no; fi
}
bridge_src_identity() {     # $1=重发前 sha $2=重发后 sha ⇒ stdout: SAME|DIFF|NOINFO
    [ -n "${1:-}" ] && [ -n "${2:-}" ] || { printf 'NOINFO'; return; }
    if [ "$1" = "$2" ]; then printf SAME; else printf DIFF; fi
}

# ── 牙 A：便宜位谓词三极性（**临时目录，不碰桥、不跑应用**）──────────────────────
# 为什么必须有这条牙：本项目的"缺读数被当绿"已经发生过两次（`hbtextline_shim_stale`
#   按构造恒 no、桥契约对整行判 `[`）。这里要证明的正是**最危险的那一极**：
#   **文件缺失 ⇒ NOINFO**，而不是 no。三极性：缺失⇒NOINFO / 值不符⇒yes / 值相符⇒no。
if [ "${BRIDGE_FP_SELFTEST:-0}" = "1" ]; then
    _d="$(mktemp -d 2>/dev/null || echo "$HOME/.bridge-fp-selftest")"; mkdir -p "$_d"
    _now="$(bridge_src_fp_now)" || { echo "BRIDGE_FP_SELFTEST=FAIL（现树指纹算不出 ⇒ 连牙都测不了；$BRIDGE_FP_SCRIPT 在不在？）"; exit 2; }
    mkdir -p "$_d/wrong" "$_d/right"
    printf 'BRIDGE_SRC_FP=0000000000000000\n' > "$_d/wrong/bridge-src-fp.txt"
    printf 'BRIDGE_SRC_FP=%s\n' "$_now"       > "$_d/right/bridge-src-fp.txt"
    _r_missing="$(bridge_src_stale "$_d")";          _b_missing="$(bridge_src_stale_basis "$_d")"
    _r_wrong="$(bridge_src_stale "$_d/wrong")";      _b_wrong="$(bridge_src_stale_basis "$_d/wrong")"
    _r_right="$(bridge_src_stale "$_d/right")";      _b_right="$(bridge_src_stale_basis "$_d/right")"
    _r_id1="$(bridge_src_identity aaa aaa)"; _r_id2="$(bridge_src_identity aaa bbb)"; _r_id3="$(bridge_src_identity '' bbb)"
    _r_sof="$(bridge_so_file_match "$_d" /nonexistent.so)"
    rm -rf "$_d"
    printf 'BRIDGE_FP_SELFTEST 缺失=%s（basis=%s，期望 NOINFO/no-file）｜ 值不符=%s（%s，期望 yes）｜ 值相符=%s（%s，期望 no）\n' \
        "$_r_missing" "$_b_missing" "$_r_wrong" "$_b_wrong" "$_r_right" "$_b_right"
    printf 'BRIDGE_FP_SELFTEST 身份谓词 同=%s 异=%s 缺=%s（期望 SAME/DIFF/NOINFO）｜ so_file_match 缺文件=%s（期望 NOINFO）\n' \
        "$_r_id1" "$_r_id2" "$_r_id3" "$_r_sof"
    if [ "$_r_missing" = NOINFO ] && [ "$_r_wrong" = yes ] && [ "$_r_right" = no ] \
       && [ "$_r_id1" = SAME ] && [ "$_r_id2" = DIFF ] && [ "$_r_id3" = NOINFO ] && [ "$_r_sof" = NOINFO ]; then
        echo "BRIDGE_FP_SELFTEST=PASS（缺失⇒无信息、不符⇒yes、相符⇒no；身份谓词三极全对）"
        exit 0
    fi
    echo "BRIDGE_FP_SELFTEST=FAIL（至少一条极性不成立 ⇒ 这个门是假的）" >&2
    exit 2
fi

# ── 牙：**直接测量位**（同源重发前后 sha 必须逐字节相同）+ 便宜位的两极性 ──────────
# 极性（缺一不可）：
#   ① 同源重发 ⇒ `SAME`（绿）
#   ② **语义**突变一处 `src/WpfGfx.Linux/Rendering/*.cs` ⇒ 便宜位必须 `yes`；再重发 ⇒ `DIFF`（红）
#   ③ 还原源码 ⇒ 便宜位仍 `yes`（因为上一次发布是突变版）；再重发 ⇒ **sha 逐字节回到原值**（绿）
# ⚠️ **必须改语义**（常量/参数序），**不许只改注释**：AOT 会丢注释 ⇒ 只改注释**不会**改 sha，
#    那会让"②"变成**假绿**。这条边界写进报告（主控 2026-09-14 明确要求）。
# ⚠️ 安全：`src/**` 不是我的车道 ⇒ 突变前备份源码**与**部署 .so，`trap` 保证还原
#    （EXIT/INT/TERM），还原后校验源码 sha 与原地一致；最后一道网才是从备份恢复 .so。
if [ "$BRIDGE_IDENTITY_SELFTEST" = "1" ]; then
    set +e
    MUT_FILE="$ROOT/src/WpfGfx.Linux/Rendering/DrawInstructionCensus.cs"
    MUT_FROM='private const int MaxGeomLines = 60;'
    MUT_TO='private const int MaxGeomLines = 61;   // T3 bridge-identity tooth (temporary; restored by trap)'
    BAK_DIR="$(mktemp -d 2>/dev/null || echo "$HOME/.bridge-id-selftest")"; mkdir -p "$BAK_DIR"
    SRC_BAK="$BAK_DIR/$(basename "$MUT_FILE")"; SO_BAK="$BAK_DIR/wpfgfx_cor3.so"
    ORIG_SRC_SHA="$(sha256sum "$MUT_FILE" 2>/dev/null | cut -c1-16)"
    cp -f "$MUT_FILE" "$SRC_BAK" 2>/dev/null
    cp -f "$BRIDGE_PUB_DIR/wpfgfx_cor3.so" "$SO_BAK" 2>/dev/null
    LOCKED=0
    SO_SHA0=""
    restore_all() {
        # 还原源码（幂等）+ 校验；再尽力把部署 .so 还原成冻结值；最后解锁
        if [ -n "${SRC_BAK:-}" ] && [ -f "$SRC_BAK" ]; then cp -f "$SRC_BAK" "$MUT_FILE" 2>/dev/null; fi
        local back; back="$(sha256sum "$MUT_FILE" 2>/dev/null | cut -c1-16)"
        [ "$back" = "$ORIG_SRC_SHA" ] && echo "   [tooth] 源码已还原并校验：$(basename "$MUT_FILE") sha=$back ✅" \
                                      || echo "   [tooth] ⚠️ 源码还原后 sha=$back ≠ 原值 $ORIG_SRC_SHA —— 需人工处理！"
        if [ -f "$SO_BAK" ] && [ -n "${SO_SHA0:-}" ]; then
            local nows; nows="$(sha256sum "$BRIDGE_PUB_DIR/wpfgfx_cor3.so" 2>/dev/null | cut -c1-16)"
            if [ "$nows" != "${SO_SHA0:-}" ]; then
                cp -f "$SO_BAK" "$BRIDGE_PUB_DIR/wpfgfx_cor3.so" 2>/dev/null
                echo "   [tooth] ⚠️ 部署 .so 曾被留下为 $nows ≠ 冻结值 $SO_SHA0 ⇒ 已从备份恢复为 $(sha256sum "$BRIDGE_PUB_DIR/wpfgfx_cor3.so" | cut -c1-16)"
            fi
        fi
        rm -rf "$BAK_DIR" 2>/dev/null
        [ "${LOCKED:-0}" = "1" ] && { rm -f "$BRIDGE_REPUBLISH_LOCK"; echo "   [tooth] 锁已释放：$BRIDGE_REPUBLISH_LOCK"; }
    }
    trap restore_all EXIT INT TERM
    echo "== 桥→源 身份闸门 · 直接测量位自测（牙；会重写 .so，已落锁）"
    [ -f "$BRIDGE_FP_SCRIPT" ] || { echo "BRIDGE_IDENTITY_SELFTEST=FAIL（缺 $BRIDGE_FP_SCRIPT ⇒ 无信息不等于绿）"; exit 2; }
    grep -qF "$MUT_FROM" "$MUT_FILE" 2>/dev/null || { echo "BRIDGE_IDENTITY_SELFTEST=FAIL（突变目标不在 $MUT_FILE：'$MUT_FROM' ⇒ 仪器看不见对象，不许算绿）"; exit 2; }
    : > "$BRIDGE_REPUBLISH_LOCK"; LOCKED=1; echo "   已落锁：$BRIDGE_REPUBLISH_LOCK"
    SO_DEPLOYED="$(sha256sum "$BRIDGE_PUB_DIR/wpfgfx_cor3.so" 2>/dev/null | cut -c1-16)"
    SHA_FLAG="$(sed -n 's/.*SHA=\([0-9a-f]\{16\}\).*/\1/p' /tmp/bridge-frozen.flag 2>/dev/null | head -1)"
    FP_FLAG="$(sed -n 's/.*FP=\([0-9a-f]\{16\}\).*/\1/p' /tmp/bridge-frozen.flag 2>/dev/null | head -1)"
    FP_TREE0="$(bridge_src_fp_now)"
    echo "   部署件 SO_DEPLOYED=$SO_DEPLOYED ｜ 哨兵 SHA=${SHA_FLAG:-NA} FP=${FP_FLAG:-NA} ｜ 现树 FP=${FP_TREE0:-NA}"
    [ -n "$SHA_FLAG" ] && { [ "$SHA_FLAG" = "$SO_DEPLOYED" ] \
        && echo "   部署件 == 哨兵声明 ✅" \
        || echo "   ⚠️ 部署件 ≠ 哨兵声明（哨兵过期，或部署件被换过）"; }
    if [ -n "$FP_FLAG" ] && [ -n "$FP_TREE0" ]; then
        [ "$FP_FLAG" = "$FP_TREE0" ] \
            && echo "   现树源码指纹 == 哨兵声明 ✅" \
            || echo "   ⚠️ **现树源码指纹 ≠ 哨兵声明**（哨兵=$FP_FLAG 现树=$FP_TREE0）⇒ 桥输入在哨兵之后又被改过："
        [ "$FP_FLAG" = "$FP_TREE0" ] || find "$ROOT/src/WpfGfx.Linux" "$ROOT/build/MilBridge" \
            \( -name bin -o -name obj -o -name .artifacts -o -path '*/tests' -o -path '*/alt-route-b' -o -path '*/spike' \) -prune -o \
            -type f \( -name '*.cs' -o -name '*.csproj' -o -name '*.props' -o -name '*.targets' -o -name '*.resx' \) \
            -newermt "$(sed -n 's/.*PUBLISHED_AT=\(.*\)/\1/p' "$BRIDGE_PUB_DIR/bridge-src-fp.txt" 2>/dev/null | head -1)" \
            -printf '   [stale] %TY-%Tm-%Td %TH:%TM:%TS  %p\n' 2>/dev/null | sort
    fi
    # 基准 = **重发一次之后**的产物（不是重发前的部署件）：牙要测的是"同源重发 ⇒ 逐字节相同"
    #   这条**仪器前提**，而不是"部署件恰好等于当前源"（后者是 stale 位的职责，会随别的车道编辑而变）。
    republish() { ( cd "$ROOT" && bash build/publish-milbridge.sh ) >"$BAK_DIR/pub-$1.log" 2>&1; echo $?; }
    rc0="$(republish 0)"; SO_SHA0="$(sha256sum "$BRIDGE_PUB_DIR/wpfgfx_cor3.so" 2>/dev/null | cut -c1-16)"
    FP_TREE1="$(bridge_src_fp_now)"
    echo "   ① 建立基准（重发一次）：$SO_DEPLOYED → $SO_SHA0 rc=$rc0 ｜ 现树 FP $FP_TREE0 → ${FP_TREE1:-NA}"
    rc1="$(republish 1)"; SO_SHA1="$(sha256sum "$BRIDGE_PUB_DIR/wpfgfx_cor3.so" 2>/dev/null | cut -c1-16)"
    FP_TREE2="$(bridge_src_fp_now)"
    V1="$(bridge_src_identity "$SO_SHA0" "$SO_SHA1")"
    echo "   ① 幂等重发：$SO_SHA0 → $SO_SHA1 ⇒ $V1（期望 SAME）rc=$rc1"
    TREE_MOVED=no; [ -n "$FP_TREE1" ] && [ "$FP_TREE1" = "$FP_TREE2" ] || TREE_MOVED=yes
    [ "$TREE_MOVED" = yes ] && echo "   ⚠️ 牙跑期间现树指纹变了（${FP_TREE1:-NA} → ${FP_TREE2:-NA}）⇒ 有别的车道在改桥输入 ⇒ 本次判 INCONCLUSIVE（仪器没能稳定采样，不是牙坏）"
    sed -i "s|$MUT_FROM|$MUT_TO|" "$MUT_FILE"
    MUT_SRC_SHA="$(sha256sum "$MUT_FILE" | cut -c1-16)"
    STALE_MUT="$(bridge_src_stale "$BRIDGE_PUB_DIR")"
    echo "   ② 语义突变：$MUT_FROM → 61，文件 sha $ORIG_SRC_SHA→$MUT_SRC_SHA，便宜位 BRIDGE_SRC_STALE=$STALE_MUT（期望 yes）"
    rc2="$(republish 2)"; SO_SHA2="$(sha256sum "$BRIDGE_PUB_DIR/wpfgfx_cor3.so" 2>/dev/null | cut -c1-16)"
    V2="$(bridge_src_identity "$SO_SHA0" "$SO_SHA2")"
    echo "      突变后重发：after=$SO_SHA2 ⇒ $V2（期望 DIFF ⇒ 闸门必须红）rc=$rc2"
    cp -f "$SRC_BAK" "$MUT_FILE"
    STALE_BACK="$(bridge_src_stale "$BRIDGE_PUB_DIR")"
    echo "   ③ 还原源码：sha=$(sha256sum "$MUT_FILE" | cut -c1-16)，便宜位 BRIDGE_SRC_STALE=$STALE_BACK（期望 yes：上次发布是突变版）"
    rc3="$(republish 3)"; SO_SHA3="$(sha256sum "$BRIDGE_PUB_DIR/wpfgfx_cor3.so" 2>/dev/null | cut -c1-16)"
    V3="$(bridge_src_identity "$SO_SHA0" "$SO_SHA3")"
    STALE_FINAL="$(bridge_src_stale "$BRIDGE_PUB_DIR")"
    echo "      还原后重发：after=$SO_SHA3 ⇒ $V3（期望 SAME 且逐字节回到基准 $SO_SHA0）rc=$rc3"
    echo "      便宜位终值 BRIDGE_SRC_STALE=$STALE_FINAL（期望 no）"
    restore_all; trap - EXIT INT TERM   # 先把源码/锁/备份收干净，再报判定（别让收尾插在判定后面）
    if [ "$TREE_MOVED" = yes ]; then
        echo "BRIDGE_IDENTITY_SELFTEST=INCONCLUSIVE（牙跑期间桥输入被别的车道改动 ⇒ 本次读数无效，等树静下来再跑）"
        exit 3
    fi
    if [ "$V1" = SAME ] && [ "$STALE_MUT" = yes ] && [ "$V2" = DIFF ] && [ "$V3" = SAME ] && [ "$STALE_FINAL" = no ]; then
        echo "BRIDGE_IDENTITY_SELFTEST=PASS（直接测量位能红能绿；便宜位也能红能绿；还原后 sha 逐字节回原值）"
        exit 0
    fi
    echo "BRIDGE_IDENTITY_SELFTEST=FAIL（V1=$V1 stale_mut=$STALE_MUT V2=$V2 V3=$V3 stale_final=$STALE_FINAL）" >&2
    exit 2
fi

# ── 运行目录：**默认带 $$**（坑 1）────────────────────────────────────────────
OUT="${WPTD_RUN_DIR:-/tmp/wptd-run-$$}"

# ── 桥契约判定（T2b 新格式）——**判定函数化 + 可离线自测** ──────────────────────
#   【为什么不是一行 case】2026-09-13 主控现场读码抓到两处"仪器看不见对象"缺陷：
#     ① 样例 runner 对**整行**判 `[`：而台账行形如
#        `[mil   34]   ★ 首个**有内容**的帧…（skia 指令 261 条，未画种类 0）`
#        ⇒ 行首就有 `[mil 34]` ⇒ `has_clause` **恒为 1** ⇒ 空态恒假红、且**旧桥 + N>0 时恒真绿**
#        （恰好吃掉它本来要抓的那个"取到旧桥"）；
#     ② 探针 runner 用 `grep -oE '…未画种类 [0-9]+'` 抽 `nd_pair` ⇒ **后缀被切掉** ⇒ `has_clause` 恒为 0
#        ⇒ N>0 时**恒报** SUSPECT_STALE_BRIDGE。
#   正确做法：**先切出"未画种类 N"之后的尾巴**再判；空态尾巴必须**恰好是 `）`**；
#   非空态必须形如 ` [MilXxx×N…]）`。
bridge_contract() {   # $1 = 含"未画种类 N"的那一行；stdout = 判定串
    local line="$1" tail n
    n="$(printf '%s' "$line" | grep -oE '未画种类 [0-9]+' | grep -oE '[0-9]+' | head -1)"
    [ -n "$n" ] || { printf 'NA(取不到未画种类)'; return; }
    tail="$(printf '%s' "$line" | sed -n 's/.*未画种类 [0-9]\+\(.*\)/\1/p')"
    if [ "$n" = "0" ]; then
        # 空态契约（T2b）：**不得有条款表 `[]`**；尾部允许有 trace 自己的后续上下文
        #   （实测真实行是 `…未画种类 0）  累计帧数 = 2` ⇒ 早先要求"尾巴恰好是 ）"会误报 WARN）。
        case "$tail" in
            *"["*)  printf 'SUSPECT(0 却带条款表 ⇒ 格式异常)' ;;
            "）")   printf 'ok(0 且尾部恰好为）)' ;;
            "）"*)  printf 'ok(0 且无条款表；尾部=）%s)' "${tail#）}" ;;
            *)      printf 'WARN(0 但尾部不以）起头: %s)' "$tail" ;;
        esac
    else
        case "$tail" in
            *"["*"]"*) printf 'ok(%s 且带条款表)' "$n" ;;
            *)         printf 'SUSPECT_STALE_BRIDGE(%s 但无条款表 ⇒ 疑取到旧桥/旧件)' "$n" ;;
        esac
    fi
}
# 离线牙（**不需要应用**）：造 4 行假台账，其中第 4 行专门覆盖"行首有 [mil …] 不能骗过判定"。
if [ "${BRIDGE_CONTRACT_SELFTEST:-0}" = "1" ]; then
    _bc_fail=0
    _t() { # $1=行 $2=期望前缀 $3=说明
        local got; got="$(bridge_contract "$1")"
        case "$got" in "$2"*) echo "  ✅ $3 ⇒ $got" ;;
            *) echo "  ❌ $3 ⇒ 得到 '$got'，期望前缀 '$2'"; _bc_fail=1 ;;
        esac
    }
    _t '（skia 指令 261 条，未画种类 0）' 'ok(0' '空态（裸行）⇒ 必须 ok(0…)'
    _t '[mil   28]   ★ 首个**有内容**的帧…（skia 指令 261 条，未画种类 0）  累计帧数 = 2' 'ok(0' '空态（**真实整行**，带 trace 后续上下文）⇒ 必须 ok(0…) 而不是 WARN'
    _t '[mil   34]   ★ 首个**有内容**的帧…（skia 指令 261 条，未画种类 0）' 'ok(0' '行首带 [mil 34] 的空态 ⇒ **不许**被判成"带条款表"'
    _t '（skia 指令 12 条，未画种类 2 [MilPushOpacityMask×2]）' 'ok(2' '非空态 + 条款表 ⇒ ok(N…)'
    _t '（skia 指令 12 条，未画种类 2）' 'SUSPECT_STALE_BRIDGE' '非空态 + 无条款表 ⇒ 必须报"疑取旧桥"'
    if [ "$_bc_fail" = "0" ]; then echo "BRIDGE_CONTRACT_SELFTEST=PASS"; exit 0; fi
    echo "BRIDGE_CONTRACT_SELFTEST=FAIL（判定函数不能区分四种形态 ⇒ 这条检查是假的）"; exit 2
fi

BUILD_LOG="$OUT-build.log"          # 放在 $OUT 之外：装配阶段会 rm -rf $OUT
DISPLAY_NUM="${WPTD_DISPLAY:-:97}"  # 自己的显示号（:99 是 M7b 的，:98 是主控复验的）
SRC="$ROOT/samples/WpfTextDemo/bin/$SELFBUILT_CONFIG/net10.0"
FONT_FILE="$ROOT/build/fonts-ui/UI-NoLayout.ttf"

export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# ── grep 自检：判据全建立在 grep 上，它坏掉必须**立刻**失败 ───────────────────
if ! printf 'grep-selfcheck\n' | grep -q 'grep-selfcheck'; then
    echo "❌ grep 不可用或行为异常 —— 本脚本判据不可信，直接失败" >&2; exit 2
fi
for tool in xwininfo xwd convert dotnet; do
    command -v "$tool" >/dev/null 2>&1 || { echo "❌ 缺工具：$tool" >&2; exit 2; }
done

# ── X server：优先复用已存在的 :97；否则**自己起一个**并记下 PID（坑 2 的对应做法）──
XPID=""
# ★ 应用进程探针：**只认"我自己的子进程"**（`pgrep -P $$`）。
#   【为什么必须限定到自己的进程树】这台机上**别的 agent 也在跑同一个样例**（同一个
#   `dotnet WpfTextDemo.dll`）。用全局 `pgrep -f` 会：① 把别人的进程算成"我的残留"（假红）；
#   ② 更糟 —— 我的 cleanup 会**把别人的应用杀掉**（跨车道的破坏）。
#   由于启动时用了 `exec`，应用就是 runner 的**直接子进程**；但 ⚠️ **只靠 `-P $$` 还不够**：
#   命令替换的子 shell 也是 `$$` 的子进程、cmdline 与脚本同源 ⇒ 会自匹配（`D-G103` 族）。
#   ⇒ 现在 `app_procs` 在 `-P $$` 之上**再加 argv 精确比对**（见其函数体）。
# 【`D-G103` 族修法】同 `run-wpfprobe.sh`：`pgrep -P "$$" -f <模式>` 只是**集合限定**，
#   命令替换的子 shell 也是 `$$` 的子进程且 cmdline 同源 ⇒ 仍会自匹配。
#   ⇒ 保留 `-P "$$"`（只认我的直接子进程）＋ 逐 pid 读 `/proc` 做 **argv 精确比对**（只更窄、不放宽）。
app_procs() {
    local p a0 a1
    for p in $(pgrep -P "$$" 2>/dev/null | grep -oE '^[0-9]+'); do
        [ -r "/proc/$p/cmdline" ] || continue
        a0="$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | sed -n 1p)"
        a1="$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | sed -n 2p)"
        case "${a0##*/}" in dotnet) ;; *) continue ;; esac
        [ "$a1" = "WpfTextDemo.dll" ] || continue
        printf '%s\n' "$p"
    done
}
app_procs_count() { app_procs | grep -c . || true; }
# ── 孤儿回收（精确比对 argv + 只认 ppid==1 + 按 PID 杀）────────────────────────
#   【为什么需要】我调用的两个辅助趟（T1c 的普查装置 / 我自己的 WIC 诊断趟）会**各自**起一次
#   应用；实测发现它们会留下**孤儿**（ppid=1、单个 RSS ~2 GB）—— 主控抓到过一次整机
#   available→0。孤儿没有活着的父进程 ⇒ 不可能属于别人正在跑的那一轮 ⇒ 可以安全回收。
#   ⚠️ 三条自律：① 精确比对 /proc/<pid>/cmdline 的 argv（argv[0]∈{dotnet,*/dotnet} 且 argv[1]==WpfTextDemo.dll）；
#      ② **只认 ppid==1**（别人活着的应用有父进程，绝不误伤）；③ 只按显式 PID 杀，**不做模式杀**。
orphan_app_pids() {
    local p a0 a1 pp
    for p in /proc/[0-9]*; do
        p="${p#/proc/}"
        [ -r "/proc/$p/cmdline" ] || continue
        a0="$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | sed -n 1p)"
        a1="$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | sed -n 2p)"
        case "$a0" in dotnet|*/dotnet) ;; *) continue ;; esac
        [ "$a1" = "WpfTextDemo.dll" ] || continue
        pp="$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null)"
        [ "$pp" = "1" ] || continue
        printf '%s\n' "$p"
    done
}
REAPED_TOTAL=0
REAP_LOG=""
reap_orphans() {
    local label="$1" p ids n=0
    ids="$(orphan_app_pids)"
    [ -n "$ids" ] || { echo "   （$label：无孤儿）"; return 0; }
    for p in $ids; do
        kill -TERM "$p" 2>/dev/null || true
    done
    sleep 0.6
    for p in $ids; do
        [ -d "/proc/$p" ] && kill -KILL "$p" 2>/dev/null || true
        n=$((n + 1))
    done
    REAPED_TOTAL=$((REAPED_TOTAL + n))
    REAP_LOG="$REAP_LOG$label:$n;"
    echo "   ♻️ $label：回收了 $n 个**孤儿**应用进程（精确 argv 比对 + ppid==1，按 PID 杀）: $(printf '%s' "$ids" | tr '\n' ' ')"
}
# 全局计数（**只作环境观测，绝不据此杀进程：那是别人的车**）
# 【`D-G103` 族修法】旧写法 `pgrep -f … | grep -v "^$$\$"` 有两个洞：① 只排了 `$$`；
#   ② `$$` 在 `$( )` 里指的是**外层 shell**、而命令替换的**子 shell** 是另一个 pid ⇒ 排不掉。
#   ⇒ 逐 pid 读 `/proc`，显式排除 `$$` 与 `${PPID}`，并按 **argv 精确比对**认领
#     （argv0 基名 == `dotnet` ∧ argv1 逐字 == `WpfTextDemo.dll`）⇒ 承载本判据的 shell **构造上匹配不到**。
#   ⚠️ 语义仍为**全机计数**（别的人的应用照样数进来 —— 这是原意）；改动只把**假阳性**（提到该字面量的
#      包装 shell）去掉 ⇒ **只更窄、不放宽**。
app_procs_global_count() {
    local p a0 a1 n=0
    for p in /proc/[0-9]*; do
        p="${p#/proc/}"
        [ "$p" = "$$" ] && continue
        [ "$p" = "${PPID:-0}" ] && continue
        [ -r "/proc/$p/cmdline" ] || continue
        a0="$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | sed -n 1p)"
        a1="$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | sed -n 2p)"
        case "${a0##*/}" in dotnet) ;; *) continue ;; esac
        [ "$a1" = "WpfTextDemo.dll" ] || continue
        n=$((n + 1))
    done
    printf '%s\n' "$n"
}

cleanup() {
    # ★【只在主 shell 里收尾】实测（2026-09-11）：EXIT trap 会被**后台子 shell 继承**
    #   （应用是 `( … dotnet … ) &` 起的，抢拍 watcher 也是子 shell）。子 shell 退出时
    #   跑这个 trap ⇒ **把自己刚起的 Xvfb 杀掉** ⇒ 后续档位/重复全部在
    #   `CreateWindowEx` 抛 `Win32Exception(1400)`，**看起来像应用崩，其实是 runner 自伤**。
    #   症状极具误导性：单跑 `--tier env` 一切正常，`--tier both` 时第二档 3/3 全崩。
    if [ "${BASHPID:-$$}" != "$$" ]; then return 0; fi
    # 只杀**自己起的**那个 Xvfb；用 PID，不用名字匹配
    reap_orphans "脚本收尾" 2>/dev/null || true
    # 应用残留清扫（杀漏的另一面）：**只清我自己的子进程**（pgrep -P $$），
    #   绝不按名字全局杀 —— 同机上别的 agent 也在跑同一样例（跨车道破坏）。
    local _p
    for _p in $(app_procs); do kill -TERM "$_p" 2>/dev/null || true; done
    sleep 0.5
    for _p in $(app_procs); do kill -KILL "$_p" 2>/dev/null || true; done
    if [ -n "$XPID" ] && kill -0 "$XPID" 2>/dev/null; then
        kill "$XPID" 2>/dev/null || true
        wait "$XPID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

if xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1; then
    echo "== 复用已存在的 X server：$DISPLAY_NUM"
else
    command -v Xvfb >/dev/null 2>&1 || { echo "❌ $DISPLAY_NUM 上没有 X，且找不到 Xvfb" >&2; exit 2; }
    echo "== 启动自己的 Xvfb $DISPLAY_NUM（1280x1024x24）"
    Xvfb "$DISPLAY_NUM" -screen 0 1280x1024x24 >"$OUT-xvfb.log" 2>&1 &
    XPID=$!
    for _ in $(seq 1 40); do
        xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 && break
        kill -0 "$XPID" 2>/dev/null || { echo "❌ Xvfb 启动即退出，见 $OUT-xvfb.log" >&2; exit 2; }
        sleep 0.25
    done
    xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 || { echo "❌ Xvfb 起不来（$DISPLAY_NUM）" >&2; exit 2; }
    # 【为什么要再稳一下】实测（2026-09-11，连续 6 次调用本 runner 做体积扫描）：
    #   `xdpyinfo` 成功之后立刻启动应用，偶发 `Win32Exception(1400)`（= 没有可用的 X）——
    #   刚起来的 X server 还没把 socket/原子性准备好。这个失败**看起来像应用 bug**，
    #   实际是 runner 的环境竞态。⇒ 探测成功后再 settle 一下，并复验一次。
    sleep 0.6
    xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 || { echo "❌ Xvfb 起来了又不稳（$DISPLAY_NUM）" >&2; exit 2; }
fi
export DISPLAY="$DISPLAY_NUM"


# ── 负载闸门（主控 2026-09-11 新增的启动条件）──────────────────────────────────
#   本机有**别的工程**的构建负载（不是我们的），会把 90s 档变得不稳。
#   规则：开跑前看 1 分钟 loadavg；> 12 就等 2 分钟再试，最多 5 次。
#   ⚠️ 若 5 次仍高：**继续跑但把"环境负载高"写进读数** —— 读数要带成立条件，
#      "负载下的异常慢/INCONCLUSIVE"不许当成渲染结论。
load_gate() {
    local max="${LOAD_GATE_MAX:-12}" tries=0 l1
    while :; do
        l1="$(awk '{print $1}' /proc/loadavg)"
        if awk -v l="$l1" -v m="$max" 'BEGIN{exit !(l <= m)}'; then
            echo "   ✅ load gate：1min=$l1 ≤ $max（尝试 $tries 次）"
            LOAD_GATE_RESULT="ok(1min=$l1)"
            return 0
        fi
        tries=$((tries + 1))
        if [ "$tries" -ge 5 ]; then
            echo "   ⚠️ load gate：1min=$l1 仍 > $max（已重试 5 次）⇒ 继续跑，但读数标注**环境负载高**"
            LOAD_GATE_RESULT="high(1min=$l1,>5 次)"
            return 1
        fi
        echo "   ⏳ load gate：1min=$l1 > $max ⇒ 等 120s 再试（第 $tries 次）"
        sleep 120
    done
}
LOAD_GATE_RESULT="unknown"

# ── 基线表头（环境压力可核查留痕）────────────────────────────────────────────
#   【为什么要记】同一台机上还有别的工程（wpf2web 的 flock 构建）在跑 ⇒ load 不完全由我们造成。
#   读数一旦异常，先看这份留痕判断"是不是环境压力导致的漂移"。
if [ -n "${WPTD_BASELINE_OUT:-}" ]; then
    {
        echo "# BASELINE-HEADER date=$(date -Is) display=$DISPLAY_NUM host=$(hostname) kernel=$(uname -r)"
        echo "#   loadavg=$(cut -d' ' -f1-3 /proc/loadavg)  cpu=$(nproc)核"
        echo "#   mem_available=$(awk '/MemAvailable/{printf "%d MB", $2/1024}' /proc/meminfo)  mem_total=$(awk '/MemTotal/{printf "%d MB", $2/1024}' /proc/meminfo)"
        echo "#   run_dir=$OUT  repeat=${REPEAT:-${WPTD_REPEAT:-3}}  timeout=${TIMEOUT:-?}s  tier=${TIER:-?}"
        echo "#   git_head=(no git) samples_src=samples/WpfTextDemo  runner=run-wpftextdemo.sh"
    } > "$WPTD_BASELINE_OUT"   # [W153A-#61] 修前是 `>>`（**追加**）⇒ 复用同一路径就累积成 12 行，
    #   而冻结器 `w27-freeze.py:765` 断言 `len(rows)==6` ⇒ 冻结当场失败（`#57` 现场）。
    #   本行是**第一个**写点（表头）⇒ 改成截断后：**一次调用 = 恰好一批**（表头 ＋ 6 行 ＋ 注释块），
    #   与目标文件此前有没有内容无关 ⇒ 调用方**不再需要**先 `rm -f`。
fi

# ── 杀进程审计（自查）：本脚本**只按 PID 杀**，且只杀自己的子进程 ─────────────
#   背景（2026-09-11，主控报的两起误伤）：我早先的 cleanup 用过全局
#   `pgrep -f 'dotnet WpfTextDemo.dll'` 再 kill ⇒ **打中了命令行里含该字面量的旁观者**
#   （T2b 的 shell、主控的一条命令）。规则：**不要在自己命令行里写要匹配/杀的名字面量**；
#   杀进程一律按 PID 或精确比对自排除。
# 只看**代码行**（注释里会写这些名字做说明，不能因此判红）
KILL_AUDIT="$(grep -vE '^[[:space:]]*#' "$0" | grep -nE '(^|[^a-zA-Z])pkill|killall|kill[[:space:]]+-f' | grep -v 'KILL_AUDIT' | head -5)"
if [ -n "$KILL_AUDIT" ]; then
    echo "❌ 自查失败：脚本里出现了按模式杀进程的写法（必须改成按 PID）：" >&2
    printf '%s\n' "$KILL_AUDIT" >&2
    exit 2
fi

echo "== WpfTextDemo · 默认配置门禁 runner"
echo "   仓库      : $ROOT"
echo "   DISPLAY   : $DISPLAY  (Xvfb PID: ${XPID:-<复用的外部 X>})"
echo "   运行目录  : $OUT"
echo "   档位      : $TIER（default = 清空全部 WPF_LINUX_*/HLWPF_* 字体 env；env = 带字体覆盖对照）"

# ── 1. 增量构建（-m:1；失败即退出，绝不拿陈旧产物跑）─────────────────────────
if [ "$NO_BUILD" = "0" ]; then
    echo "== 0/5 负载闸门（主控条件：1min loadavg ≤ 12；>12 等 2 分钟，最多 5 次）"
load_gate || true
echo "   环境：loadavg=$(cut -d' ' -f1-3 /proc/loadavg)  mem_available=$(awk '/MemAvailable/{printf "%d MB", $2/1024}' /proc/meminfo)  cpu=$(nproc)核"

echo "== 1/5 增量构建 samples/WpfTextDemo（-m:1）"
    if ! timeout 600 dotnet build "$ROOT/samples/WpfTextDemo/WpfTextDemo.csproj" -c "$SELFBUILT_CONFIG" -m:1 >"$BUILD_LOG" 2>&1; then
        echo "   ❌ 构建失败 —— 拒绝用陈旧产物继续（日志尾 20 行）：" >&2
        tail -20 "$BUILD_LOG" | sed 's/^/      /' >&2
        exit 3
    fi
    grep -E "已成功生成|生成失败|个警告|个错误" "$BUILD_LOG" | sed 's/^/   /'
else
    echo "== 1/5 跳过构建（--no-build：仅用于**已知产物是最新**的重复观测，不用于掩盖构建问题）"
fi

# ── 2. 装配运行目录 ──────────────────────────────────────────────────────────
echo "== 2/5 装配运行目录"
[ -d "$SRC" ] || { echo "找不到 $SRC —— 先构建 samples/WpfTextDemo" >&2; exit 2; }
rm -rf "$OUT"; mkdir -p "$OUT"; : > "$OUT/tier-readings.txt"
cp -r "$SRC"/. "$OUT"/

# 2a-0) 【产物一致性】bin 里的快照 vs build/*.Linux 的权威产物
#   为什么要有这一段：实测（2026-09-11）撞到过 —— 样例 bin 里的 PC/PF 是 13:54 的，
#   而 build/PresentationCore.Linux/bin/Debug 已经是 16:14（集成波中途），两者行为不同。
#   不把这件事显式打出来，"产物混用"会被误判成"样例的问题"。**只报告，不阻止**。
echo "   自产件一致性（bin 快照 vs build/*.Linux 权威产物）："
_mismatch=0
for _d in "$ROOT"/build/*.Linux/bin/"$SELFBUILT_CONFIG"/*.dll; do
    [ -f "$_d" ] || continue
    _proj="$(basename "$(dirname "$(dirname "$(dirname "$_d")")")")"
    case "$_proj" in CycleStub.*) continue ;; esac
    _base="$(basename "$_d")"
    [ "${_base%.dll}" = "${_proj%.Linux}" ] || continue
    if [ -f "$SRC/$_base" ]; then
        _a="$(sha256sum "$SRC/$_base" | cut -c1-12)"; _b="$(sha256sum "$_d" | cut -c1-12)"
        if [ "$_a" = "$_b" ]; then printf '     %-40s 一致   %s\n' "$_base" "$_a"
        else printf '     %-40s ⚠️ 不一致 bin=%s 权威=%s（可能是集成波中途的产物）\n' "$_base" "$_a" "$_b"; _mismatch=$((_mismatch + 1)); fi
    fi
done
[ "$_mismatch" = "0" ] || echo "     ⚠️ 有 $_mismatch 个自产件不一致 —— 运行行为可能因此不同（先等 build/.wave-done 再复跑）"

# 2a) 自产程序集刷新成**权威产物**（只取与目录同名的那一件；CycleStub 跳过）
#     ⚠️ 不能 `build/*.Linux/bin/Debug/*.dll` 全量 cp：PF 的输出目录里带着**构建时快照**的
#     PresentationCore.dll，glob 字典序会让它盖掉新版的 PC。
for d in "$ROOT"/build/*.Linux/bin/"$SELFBUILT_CONFIG"/*.dll; do
    [ -f "$d" ] || continue
    proj="$(basename "$(dirname "$(dirname "$(dirname "$d")")")")"
    case "$proj" in CycleStub.*) continue ;; esac
    [ "$(basename "$d" .dll)" = "${proj%.Linux}" ] || continue
    cp -f "$d" "$OUT"/ 2>/dev/null
done

# 2b) DirectWrite.Linux.Provider（权威产物）
PROVIDER="$ROOT/build/DirectWrite.Linux/Provider/bin/$SELFBUILT_CONFIG/DirectWrite.Linux.Provider.dll"
if [ -f "$PROVIDER" ]; then cp -f "$PROVIDER" "$OUT"/; else
    echo "   警告：找不到 $PROVIDER（PC 的模块初始化器会 FileNotFoundException）" >&2
fi

# 2c) Win32 shim（app-local）+ "shim 已能服务、只缺 DLL 名"的别名
SHIM="$ROOT/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
if [ -f "$SHIM" ]; then
    cp -f "$SHIM" "$OUT"/
    # 【别名清单与依据】
    #   uxtheme/wtsapi32/shell32 —— 已在 M7b 的 `MappedLibraries` 里，这里是双保险。
    #   ★ PresentationNative_cor3.dll —— **本 runner 实测撞到的真缺口**（不是双保险）：
    #     `ListBox` 只要有选中项就会走
    #       ListBox.OnSelectionChanged → AutomationPeer.ListenerExists → AutomationPeer..cctor
    #       → InvokePatternIdentifiers..cctor → AutomationIdentifierConstants..cctor
    #       → MS.Internal.UIAutomationTypes.Interop.OSVersionHelper..cctor
    #       → [DllImport("PresentationNative_cor3.dll")] IsWindows10RS5OrGreater()
    #     ⇒ DllNotFoundException（HelloWpf 没有 Selector，所以从没走到这条）。
    #     **真根因在 build/ 侧**：`Win32ShimResolver.cs` 只编进了 WindowsBase 与 PresentationCore
    #     （`grep -l Win32ShimResolver build/*.Linux/*.csproj`），而这条 P/Invoke 来自
    #     **UIAutomationTypes** —— 没有 ModuleInitializer 给它注册 resolver ⇒ 走默认探测。
    #     符号本身**是有的**（`nm -D libwpfwin32.so` 里 IsWindows10RS5OrGreater 等 9 个都在）。
    #     ⇒ 正解在 M7b 车道（把 resolver 编进 UIAutomationTypes/UIAutomationProvider）；
    #       本行是**部署期止损**（同名 ELF 放 app-local，默认探测即可命中），
    #       已作为缺陷如实登记，**不当成修好**。
    for alias in uxtheme.dll wtsapi32.dll shell32.dll PresentationNative_cor3.dll; do
        cp -f "$SHIM" "$OUT/$alias"
    done
    echo "   Win32 shim: libwpfwin32.so + uxtheme/wtsapi32/shell32/PresentationNative_cor3 别名（app-local）"
    echo "     ⚠️ PresentationNative_cor3.dll 别名是**止损**：真缺口 = UIAutomationTypes 未编 resolver（M7b 车道）"
else
    echo "   警告：找不到 $SHIM —— 先跑 src/WpfGfx.Linux.Native/build-shim.sh" >&2
fi

# 2d) MilBridge 发布目录（AOT 的 MilCore 桥）：**整个目录一起放**
#     （AOT 镜像内的 Skia P/Invoke 只在它自己所在目录找 libSkiaSharp.so）
# 【确定性来源】原来用 `find … | head -1`：发布目录与 bin/native 各有一份，**取哪份看 find 顺序**
#   ⇒ "我加载的到底是哪一份"不可复现（本项目"标签与实物不符"家族）。现在**钉死发布目录**，
#   并把**实际加载路径**打进读数（BRIDGE_SRC）。
MILDIR="$ROOT/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64"
[ -d "$MILDIR" ] || MILDIR="$(dirname "$(find "$ROOT/build/MilBridge/.artifacts" -name 'wpfgfx_cor3.so' 2>/dev/null | head -1)" 2>/dev/null)"
BRIDGE_SRC="$MILDIR/wpfgfx_cor3.so"
if [ -n "$MILDIR" ] && [ -d "$MILDIR" ]; then
    echo "   MilBridge 发布目录: $MILDIR"
    for so in "$MILDIR"/*.so; do
        [ -f "$so" ] || continue
        cp -f "$so" "$OUT"/ && echo "     + $(basename "$so")（$(stat -c%s "$so") 字节）"
    done
    [ -f "$OUT/libSkiaSharp.so" ] || echo "   警告：libSkiaSharp.so 没进应用目录 —— 渲染会 DllNotFoundException" >&2
else
    echo "   警告：找不到 wpfgfx_cor3.so —— MIL 桥接会 DllNotFoundException" >&2
fi

# ── 3. 组装两档的 env ────────────────────────────────────────────────────────
# 【默认档】把**所有** WPF_LINUX_* / HLWPF_* 变量从子进程环境里摘掉（不是只摘几个写死的名字）
CLEAR_ARGS=()
while IFS='=' read -r name _; do
    case "$name" in
        WPF_LINUX_*|HLWPF_*) CLEAR_ARGS+=(-u "$name") ;;
    esac
done < <(env)
echo "== 3/5 默认档将清空的环境变量：${CLEAR_ARGS[*]:-<无>}"

# 【对照档】复刻 M2 验收件的字体配置：HLWPF_UI_FONT=<文件> ⇒
#   ① 校验文件存在；② fc-scan 读字族；③ WPF_LINUX_FONT_DIR=<目录>；④ WPF_LINUX_UI_FONT=<字族>
ENV_TIER_ARGS=()
ENV_TIER_DESC="未启用"
if [ "$TIER" != "default" ]; then
    if [ ! -f "$FONT_FILE" ]; then
        echo "❌ 对照档需要字体文件，但不存在：$FONT_FILE" >&2; exit 4
    fi
    FONT_FAMILY="$(fc-scan --format '%{family}\n' "$FONT_FILE" 2>/dev/null | head -1 | cut -d, -f1)"
    [ -n "$FONT_FAMILY" ] || { echo "❌ fc-scan 读不出字族名：$FONT_FILE" >&2; exit 4; }
    ENV_TIER_ARGS=(WPF_LINUX_FONT_DIR="$(cd "$(dirname "$FONT_FILE")" && pwd)" WPF_LINUX_UI_FONT="$FONT_FAMILY")
    ENV_TIER_DESC="$FONT_FILE
     字族    : $FONT_FAMILY
     大小    : $(stat -c%s "$FONT_FILE") 字节
     sha256  : $(sha256sum "$FONT_FILE" | cut -d' ' -f1)
     FONT_DIR: $(cd "$(dirname "$FONT_FILE")" && pwd)"
fi
echo "   对照档字体：$ENV_TIER_DESC"

# 【把"我到底跑在哪套产物上"打成机读行】
#   本项目栽过"产物混用被误判成样例问题"，而 AOT 桥（wpfgfx_cor3.so）是**另一个 agent 重发布**的，
#   所以每次运行都必须把它的 sha 写进读数 —— 否则结论无法与别人的读数对齐。
# ★【标签必须与实物一致】主控/M7b 实测抓到：原来那个字段叫 `shim_sha`，打的却是
#   `libwpfwin32.so`（Win32 shim）的 sha —— 而"WIC shim"是**另一份文件**（`libwpfwic.so`）。
#   一个名字对不对得上，决定了别人能不能拿你的读数去对齐。所以现在**分列**，且
#   **一律从"应用实际加载的那份"（app-local 运行目录 $OUT）读**，不是从常量/发布目录抄。
BRIDGE_SHA="$(sha256sum "$OUT/wpfgfx_cor3.so" 2>/dev/null | cut -c1-16)"
BRIDGE_BYTES="$(stat -c%s "$OUT/wpfgfx_cor3.so" 2>/dev/null)"
PC_SHA="$(sha256sum "$OUT/PresentationCore.dll" 2>/dev/null | cut -c1-16)"
PF_SHA="$(sha256sum "$OUT/PresentationFramework.dll" 2>/dev/null | cut -c1-16)"
WIN32SHIM_SHA="$(sha256sum "$OUT/libwpfwin32.so" 2>/dev/null | cut -c1-16)"
# R1 多字体整形把文本行为压进了 `build/shims/PresentationCore.HbTextLine.cs`：它**每变一次
#   都意味着文本行为变了**，所以必须进基线。
#   ⚠️ "从实际编进 PC 的那份读"只能做到**近似**：拿不到 PC 编译时的输入快照，所以我给
#   ①源文件 sha ②源文件 mtime ③**权威 PC** 的 mtime ④"源比 PC 新 ⇒ 未必编进当前 PC"的标志。
#   【2026-09-13 修 · 主控查出的第 17 个"恒真/恒假"形态】旧写法比的是 `$OUT/PresentationCore.dll`
#   —— 那是**刚 cp 出来的副本**，mtime = 拷贝时刻 = 现在 ⇒ 源永远比它旧 ⇒ 该位**按构造恒 no**，
#   于是"应用其实跑着不含 shim 最新改动的旧文本栈"这件事被门禁盖章成"相容"。真值现场：
#     源 00:36:31  >  权威 PC 00:00:23  ⇒ **yes**。
#   ⇒ 现在读**权威 PC**（`build/PresentationCore.Linux/bin/Debug/`）；权威件缺失才退回副本，
#   并把依据（`hbtextline_stale_basis=auth|applocal`）与两个 mtime 一起打进读数。
#   谓词抽成函数 ⇒ 可自测两个极性：`HBT_STALE_SELFTEST=1`（不碰任何别人的文件）。
hbt_stale() {
    local sm pm
    sm="$(stat -c %Y "$1" 2>/dev/null)"; pm="$(stat -c %Y "$2" 2>/dev/null)"
    if [ -n "$sm" ] && [ -n "$pm" ] && [ "$sm" -gt "$pm" ]; then printf yes; else printf no; fi
}
if [ "${HBT_STALE_SELFTEST:-0}" = "1" ]; then
    _d="$(mktemp -d 2>/dev/null || echo "$HOME/.hbt-selftest")"; mkdir -p "$_d"; : > "$_d/src"; : > "$_d/pc"
    touch -d '2026-01-01 00:00:00' "$_d/pc" 2>/dev/null; touch -d '2026-06-01 00:00:00' "$_d/src" 2>/dev/null
    _r1="$(hbt_stale "$_d/src" "$_d/pc")"; _r2="$(hbt_stale "$_d/pc" "$_d/src")"; rm -rf "$_d"
    echo "HBT_STALE_SELFTEST src-newer=$_r1（期望 yes） pc-newer=$_r2（期望 no）"
    if [ "$_r1" = "yes" ] && [ "$_r2" = "no" ]; then echo "HBT_STALE_SELFTEST=PASS"; exit 0; fi
    echo "HBT_STALE_SELFTEST=FAIL（谓词不能两极化 ⇒ 这个门是假的）"; exit 2
fi
HBTEXT_SHIM_SRC="$ROOT/build/shims/PresentationCore.HbTextLine.cs"
HBTEXT_SHA="$(sha256sum "$HBTEXT_SHIM_SRC" 2>/dev/null | cut -c1-16)"
HBTEXT_MTIME="$(stat -c %Y "$HBTEXT_SHIM_SRC" 2>/dev/null)"
AUTH_PC="$ROOT/build/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll"
if [ -f "$AUTH_PC" ]; then STALE_BASIS="auth"; STALE_PC="$AUTH_PC"; else STALE_BASIS="applocal"; STALE_PC="$OUT/PresentationCore.dll"; fi
PC_MTIME="$(stat -c %Y "$STALE_PC" 2>/dev/null)"
HBTEXT_STALE="$(hbt_stale "$HBTEXT_SHIM_SRC" "$STALE_PC")"
WICSHIM_SHA="$(sha256sum "$OUT/libwpfwic.so" 2>/dev/null | cut -c1-16)"
# Provider（DirectWrite.Linux.Provider.dll）也要进读数：它承载**字体/度量**那条链，
#   波 4 的"CFF 墨迹盒"修法就在它里面 ⇒ 它一变，文本相关读数就可能变。
PROVIDER_SHA="$(sha256sum "$OUT/DirectWrite.Linux.Provider.dll" 2>/dev/null | cut -c1-16)"
# 交叉校验：app-local 的那份是否等于发布目录的那份（不等 ⇒ 说明"加载的不是刚发布的"）
BRIDGE_PUB_SHA="$(sha256sum "${BRIDGE_SRC:-$MILDIR/wpfgfx_cor3.so}" 2>/dev/null | cut -c1-16)"
echo "WPTD_ARTIFACTS bridge_sha=${BRIDGE_SHA:-NA} bridge_bytes=${BRIDGE_BYTES:-0} pc_sha=${PC_SHA:-NA} pf_sha=${PF_SHA:-NA} provider_sha=${PROVIDER_SHA:-NA} win32shim_sha=${WIN32SHIM_SHA:-NA} wic_shim_sha=${WICSHIM_SHA:-NA} hbtextline_shim_sha=${HBTEXT_SHA:-NA} hbtextline_shim_stale=${HBTEXT_STALE} hbtextline_stale_basis=${STALE_BASIS} hbtextline_src_mtime=${HBTEXT_MTIME:-NA} pc_compare_mtime=${PC_MTIME:-NA} windowsbase_sha=$(sha256sum "$ROOT/build/WindowsBase.Linux/bin/Debug/WindowsBase.dll" 2>/dev/null | cut -c1-16) dwf_sha=$(sha256sum "$ROOT/build/DirectWriteForwarder.Linux/bin/Debug/DirectWriteForwarder.dll" 2>/dev/null | cut -c1-16)"
# ↑ **尾部追加 `dwf_sha`（第九位，2026-09-14 主控派）**：既有字段**顺序与含义一位未动**。
#   【为什么补】wave21 里 `DirectWriteForwarder.dll` 变了（`879f0020… → 2f77dbdf5e7e2cd5`）而它**不在八位元组里**
#   ⇒ **任何读数都看不见它** ⇒ 与"#6 桥源陈旧"同族的**静默位**。DWF 是**字体/文本栈**（给 PC 提供 DirectWrite API），
#   直接落在门禁判据 ②③④⑦（skia 指令 / 有效帧 / 特性色 / 行推进）的行为面上 ⇒ 必须能被看见。
# ── 扩展可见位（主控 2026-09-14 **批准**；只追加一行，既有字段与顺序一位未动）──────────────────
#   【口径（主控写死）】**扩展位变化 = 不自动作废基线，但必须在下一版表头记录。**
#   【为什么要它】wave21 里 `DirectWriteForwarder.dll` 变了而八位元组看不见（静默位同族）。与其把
#     "在应用加载路径、却不在元组里"的件一个个塞进**冻结元组**（那会把每一波都变成"强制重冻"），
#     不如让它们**全部可见**、由主控按波判断要不要重冻。逐条判断见 `samples/WpfTextDemo/ARTIFACT-TUPLE-COVERAGE.md`。
#   【逐件角色】
#     · `reachframework_sha` / `systemxaml_sha` = **可见位，不进冻结元组**（行内有 `*_role=visible-not-frozen` 标记）
#        理由：**每波都在动**（ReachFramework 连续三波 bin↔权威对都不同：`daf9b6f0/f64b76d4` →
#        `9ad071fe/f608cbc9` → `da65eaf4/ede1f364`），而门禁判据大概率不经过它们 ⇒ 进元组 = **噪声大于信息**。
#        **升级触发条件**：某一波它变了**且**门禁读数出现任何差异 ⇒ **立刻升进冻结元组**。
#     · `libskia_sha` + `libskia_nuget_2_88_9_match` = **可复算**口径（主控第 2 条）：
#        仓内 vendored 副本 vs **NuGet 钉版** native asset（`~/.nuget/packages/skiasharp.nativeassets.linux/
#        2.88.9/runtimes/linux-x64/native/libSkiaSharp.so`）；版本由 `src/WpfGfx.Linux/WpfGfx.Linux.csproj` 钉住
#        （`SkiaSharp 2.88.9` + `SkiaSharp.NativeAssets.Linux 2.88.9`，注释"4.x 有破坏性 API 变更，禁止升级"）。
#        2026-09-14 实测：`cmp` **逐字节相同**、同 sha `a02cd03f1ebcbb97`、同为 9,244,960 B。
#        ⚠️ NuGet 副本缺失 ⇒ 报 `NOINFO`（**不当 yes**，本项目纪律）。
#     · `presentationui_sha` 的权威件在 **`build/CycleStub.PresentationUI.Linux/`**（断环 stub 工程），
#        不是 `build/PresentationUI.Linux/` —— 实测 `build/PresentationFramework.Linux/bin/Debug/PresentationUI.dll`
#        与它同 sha，可互证。
ext_sha() { local v; v="$(sha256sum "$1" 2>/dev/null | cut -c1-16)"; printf '%s' "${v:-NA}"; }
SKIA_REPO="$ROOT/build/DirectWrite.Linux/wic-shim/libSkiaSharp.so"
SKIA_NUGET="$HOME/.nuget/packages/skiasharp.nativeassets.linux/2.88.9/runtimes/linux-x64/native/libSkiaSharp.so"
SKIA_SHA="$(ext_sha "$SKIA_REPO")"
if [ -f "$SKIA_NUGET" ]; then
    if [ "$SKIA_SHA" = "$(ext_sha "$SKIA_NUGET")" ]; then SKIA_MATCH="yes(nuget-2.88.9-linux-x64)"
    else SKIA_MATCH="no(repo=${SKIA_SHA} nuget=$(ext_sha "$SKIA_NUGET"))"; fi
else
    SKIA_MATCH="NOINFO(缺 NuGet 钉版副本 ⇒ 无从比对，**不当 yes**)"
fi
echo "WPTD_ARTIFACTS_EXT reachframework_sha=$(ext_sha "$ROOT/build/ReachFramework.Linux/bin/$SELFBUILT_CONFIG/ReachFramework.dll") reachframework_role=visible-not-frozen systemxaml_sha=$(ext_sha "$ROOT/build/System.Xaml.Linux/bin/Debug/System.Xaml.dll") systemxaml_role=visible-not-frozen presentationui_sha=$(ext_sha "$ROOT/build/CycleStub.PresentationUI.Linux/bin/Debug/PresentationUI.dll") pfclassic_sha=$(ext_sha "$ROOT/build/PresentationFramework.Classic.Linux/bin/Debug/PresentationFramework.Classic.dll") systemprinting_sha=$(ext_sha "$ROOT/build/System.Printing.Linux/bin/Debug/System.Printing.dll") uiatypes_sha=$(ext_sha "$ROOT/build/UIAutomationTypes.Linux/bin/Debug/UIAutomationTypes.dll") uiaprovider_sha=$(ext_sha "$ROOT/build/UIAutomationProvider.Linux/bin/Debug/UIAutomationProvider.dll") manipulations_sha=$(ext_sha "$ROOT/build/System.Windows.Input.Manipulations.Linux/bin/Debug/System.Windows.Input.Manipulations.dll") libskia_sha=${SKIA_SHA} libskia_nuget_2_88_9_match=${SKIA_MATCH} ｜ 口径=扩展位变化**不自动作废基线**，但必须在下一版表头记录；reachframework/systemxaml 是**可见位、不进冻结元组**（每波都在动 ⇒ 噪声大于信息；若"变了**且**门禁读数有差异"则升级进元组）"
echo "   （二进制类全部读自 **app-local 运行目录** $OUT —— 即应用真正加载的那几份）"
	if [ "$HBTEXT_STALE" = "yes" ]; then
	    echo "   ⚠️ hbtextline shim（$HBTEXT_SHA）**比 PresentationCore.dll 新** ⇒ 未必编进当前 PC，文本结论要打问号"
	else
	    echo "   hbtextline shim: $HBTEXT_SHA（源码比 PC 旧/同刻 ⇒ 与当前 PC 相容）"
	fi
echo "   bridge_publish_sha=${BRIDGE_PUB_SHA:-NA}（来源目录：$MILDIR）$([ "${BRIDGE_PUB_SHA:-x}" = "${BRIDGE_SHA:-y}" ] && echo ' == app-local ✅' || echo ' ≠ app-local ⚠️（加载的不是该来源那份）')"
# ── 桥→源 身份闸门 · 便宜位（判定函数见文件头；**缺失 ⇒ 无信息，不是绿**）──────────
#   `BRIDGE_SRC_STALE=yes` ⇒ **部署的 .so 不是当前源编出来的**（例：#6 的桥 22:24 发、
#   而 T2b 22:37 改了 `Rendering/**`）⇒ 本趟读数作废。这一位是 **advisory**（不单判红，
#   主控 2026-09-14 口径），但必须**显式打出来**，否则又变成"没读到 = 没发生"。
BRIDGE_SRC_STALE="$(bridge_src_stale "$MILDIR")"
BRIDGE_SRC_STALE_BASIS="$(bridge_src_stale_basis "$MILDIR")"
BRIDGE_SO_FILE_MATCH="$(bridge_so_file_match "$MILDIR" "$OUT/wpfgfx_cor3.so")"
echo "WPTD_BRIDGE_SRC_STALE=$BRIDGE_SRC_STALE basis=$BRIDGE_SRC_STALE_BASIS so_file_match=$BRIDGE_SO_FILE_MATCH"
case "$BRIDGE_SRC_STALE" in
    no)   echo "   桥→源：现树源码指纹 == 发布时指纹 ⇒ 部署件就是当前源编的 ✅" ;;
    yes)  echo "   ⚠️ 桥→源：**部署件比当前源旧**（$BRIDGE_SRC_STALE_BASIS）⇒ 本趟读数作废，先重发桥再重跑" ;;
    *)    echo "   ⚠️ 桥→源：**无信息**（basis=$BRIDGE_SRC_STALE_BASIS）⇒ 既不能当绿也不能当红；"
          echo "      \`bridge-src-fp.txt\` 由 publish-milbridge.sh 写入；缺失=发布脚本没跑过/被清理过" ;;
esac
[ "$BRIDGE_SO_FILE_MATCH" = "no" ] && echo "   ⚠️ 部署的 wpfgfx_cor3.so 与 fp 文件记录的 BRIDGE_SO_SHA256 不一致 ⇒ 发布后被换过件"
[ -n "${WICSHIM_SHA:-}" ] || echo "   ⚠️ libwpfwic.so 不在运行目录 ⇒ wic_shim_sha 为 NA（该 shim 未被部署）"

# ── 阈值（实测标定；改这里就等于改判据，务必写清依据）───────────────────────
MIN_COLORS="${WPTD_MIN_COLORS:-200}"     # 不同颜色数下限：纯色/未出内容会是个位数
# 【阈值语义】它是"**存在性**下限"（够区分"画了/没画"就行），不是"画得够不够多"的门槛。
#   实测教训（2026-09-11）：CJK 当前渲染成豆腐块，一行里只有 ASCII 部分带色 ⇒ `align_right`
#   实测 77 px 被判成"没画"（**假红**）。所以降到 20：>0 且稳定可复现才算"在屏上"。
MIN_TEXT_PX="${WPTD_MIN_TEXT_PX:-20}"    # 每个"文字特性色"的像素数下限（存在性）

# 每个可见特性一种颜色（与 MainWindow.xaml 一一对应）：
#   标签色 = 该特性**标题行**的颜色（标题也是文字，所以任何一条为 0 都说明"那一片没画出来"）
FEATURE_COLORS=(
    "wrap_cjk:#D8E4F5"        # ① 折行中英混排正文
    "trim:#FFD166"            # ② 省略号那行 + 回显
    "align_left:#9BE564"      # ③ 左对齐
    "align_center:#6FD3FF"    # ③ 居中
    "align_right:#FF9F7A"     # ③ 右对齐
    "image_card:#B48EFF"      # ④ 位图卡片标题
    "shapes_tomato:#FF6347"   # ⑤ 纯色矩形
    "hit_border:#2A3A55"      # ⑦ 命中条底色（未交互时的可见状态）
    # ④ 卡片里那块 96x96 图的**内容色**：BitmapSource 走通 ⇒ 四象限红/绿/蓝/黄；
    #   走不通 ⇒ 样例降级成矢量 DrawingImage，**同样的四色**。两者都画不出来时为 0（= 真缺陷）。
    "image_content_g:#3FC46B"
    "image_content_r:#E53F3F"
    "image_content_b:#3F7DE5"
)

# ── 单档执行 ─────────────────────────────────────────────────────────────────
run_tier() {
    local tier="$1"; local rep="$2"; local app_args="$3"; shift 3
    local env_args=("$@")
    local tag="$tier-r$rep"

    local log="$OUT/wpftextdemo-$tag.log"
    local shot="$OUT/wpftextdemo-$tag.png"
    local xwd_file="$OUT/wpftextdemo-$tag.xwd"
    local tier_fail=0
    local fail_reasons=()

    # 【档位相关的判据适用性】minimal 档的可视树里**故意没有**本样例的特性控件
    #   （卡片/图形/命中条…），所以"特性色必须出现"这条在那里**不适用**：
    #   既不判通过也不判失败，而是显式打印"不适用"。否则就是**用一条不适用的判据把结论做假**。
    local min_colors="$MIN_COLORS"
    local feature_applicable=1
    if [ "$tier" = "minimal" ]; then
        min_colors="${WPTD_MIN_COLORS_MINIMAL:-20}"
        feature_applicable=0
    fi

    echo
    case "$tier" in
        default) echo "════════ 档位：$tier【验收·主档：默认配置】第 $rep 次 ════════" ;;
        env)     echo "════════ 档位：$tier【验收·对照：带字体 env】第 $rep 次 ════════" ;;
        degraded) echo "════════ 档位：$tier【诊断档·非验收：降级了折行/省略号/对齐/列表项】第 $rep 次 ════════"
                  echo "   ⚠️ 本档结论**必须带这个前提**读：它关掉了已知阻塞的特性，只用于先拿图证/定位其它缺陷" ;;
        minimal)  echo "════════ 档位：$tier【诊断档·非验收：最小可视树（3 个短 TextBlock）】第 $rep 次 ════════"
                  echo "   ⚠️ 本档用于区分"是文本量/特性顶掉了快路径"还是"app/产物本身有问题"" ;;
    esac

    # 3a) 指针先挪到屏幕角落：窗口若正好出现在指针下，X 会发 EnterNotify，
    #     而输入路径上有一个**已知 NRE 崩溃**（TextServicesLoader.TIPsWantToRun，M7b 车道）。
    #     默认档要量的是"渲染/文本"，不该被那条已知缺陷打断 —— 所以先让指针不在窗口里。
    if command -v xdotool >/dev/null 2>&1; then
        xdotool mousemove 1270 1010 2>/dev/null || true
        sleep 0.2
    fi

    # ★ 残留断言：起应用之前，**必须**确认没有上一轮漏下的应用进程。
    #   为什么：残留会吃掉内存（主控实测 available→0、load 10.9），让**别的档位**的读数
    #   以奇怪方式漂移 ⇒ "环境压力"是又一个会让读数说谎的变量。
    local leftover_pre global_pre
    leftover_pre="$(app_procs_count)"
    global_pre="$(app_procs_global_count)"
    if [ "${leftover_pre:-0}" != "0" ]; then
        echo "   ❌ 档位 $tier rep=$rep 开始前发现 **$leftover_pre 个我自己的残留应用进程** —— 不带着残留继续跑"
        app_procs | sed 's/^/      pid /'
        for _p in $(app_procs); do kill -TERM "$_p" 2>/dev/null || true; done
        sleep 0.5
        for _p in $(app_procs); do kill -KILL "$_p" 2>/dev/null || true; done
        echo "      （已清理；本 rep 记为 FAIL-leftover）"
        printf '%s|%s|%s|%s|%s|%s|%s|%s\n' "$tier" "$rep" "NA" "NA" "0" "0" "0" "leftover" >> "$OUT/tier-readings.txt"
        tier_fail=1; fail_reasons+=("leftover-before-$leftover_pre")
    fi

    # 全局口径只报不改：别的 agent 可能正在同机跑同一样例（那是环境压力的一部分）
    if [ "${global_pre:-0}" != "0" ]; then
        echo "   ℹ️ 环境观测：全机当前有 $global_pre 个 \`dotnet WpfTextDemo.dll\`（含**别的 agent** 的；本 runner 不碰它们）"
    fi

    # X 存活自检：环境没了必须**当场说清楚**，否则应用会在 CreateWindowEx 抛
    # Win32Exception(1400)，看起来像它自己崩（实测踩到过一次"runner 自伤"）。
    if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
        echo "   ❌ 档位 $tier 开始前 X server（$DISPLAY）已不可用 —— 这是**环境问题**，不是应用失败"
        echo "WPTD_TIER=$tier rep=$rep RESULT=INCONCLUSIVE exit=NA notdrawn=NA drawn=NA colors=0 frames_good=0 frames_total=0 frames_blank=0 capture=no-x blocker=env:no-x shot= input_probe=skipped"
        return 2
    fi

    local before
    before="$(xwininfo -root -tree 2>/dev/null | grep -oE '0x[0-9a-f]+' | sort -u | tr '\n' ' ')"
    : > "$log"

    # ★★【必须 `exec`】实测（2026-09-11，主控抓到）：原来的写法
    #   `( cd … && env … dotnet … ) &` 里 `$!` 是**子 shell 的 PID**，不是 dotnet 的。
    #   `kill -TERM $app_pid` 于是只杀子 shell ⇒ **dotnet 被孤儿化（ppid=1）继续跑**，
    #   而 `wait` 照样返回 143 ⇒ 我的"exit=143 ✅"**根本没证明应用被终止**
    #   （主控观测到 7 个孤儿、RSS 合计 >3 GB、整机 available=0、load 10.9）。
    #   加 `exec`：子 shell 被 env→dotnet **替换**，`$!` 即应用 PID，kill/wait 才名副其实。
    ( cd "$OUT" && exec env WPF_WIN32_MSG_TRACE="${WPF_WIN32_MSG_TRACE:-1}" \
                        WPF_LINUX_MIL_TRACE="${WPF_LINUX_MIL_TRACE:-1}" \
                        "${env_args[@]}" \
                        dotnet WpfTextDemo.dll $app_args > "$log" 2>&1 ) &
    local app_pid=$!

    # 3b-0) 【抢拍】崩溃型缺陷会在窗口 map 之后**毫秒级** abort，等"有内容帧"永远等不到。
    #   实测（2026-09-11）：文本回落 LineServices 的那次崩溃，xwininfo 事后什么都看不到，
    #   于是"窗口到底出没出来"只能靠 MIL 台账推断。这里另起一个 50ms 高频轮询的抢拍进程：
    #   一看到**本应用标题**的窗口就立刻 xwd（不等内容）——它给出的是"崩溃前那一刻的屏"。
    #   语义上它是**另一档证据**（可能只是窗口底色），所以文件名与结论都分开标注。
    local first_sight="$OUT/first-sight-$tag.png"
    local app_pid_for_snap="$app_pid"
    ( for _ in $(seq 1 800); do
          kill -0 "$app_pid_for_snap" 2>/dev/null || break
          _w="$(xwininfo -root -tree 2>/dev/null | grep -F 'WpfTextDemo' | grep -oE '0x[0-9a-f]+' | head -1)"
          if [ -n "$_w" ]; then
              if xwd -id "$_w" -display "$DISPLAY" -out "$OUT/first-sight-$tag.xwd" 2>/dev/null; then
                  convert "$OUT/first-sight-$tag.xwd" "$first_sight" 2>/dev/null && printf '%s\n' "$_w" > "$OUT/first-sight-$tag.id"
              fi
              break
          fi
          sleep 0.05
      done ) &
    local snap_pid=$!

    # 3b) 找窗口：优先**按标题**认领（Title="WpfTextDemo …"），找不到再退回"新窗口"启发式
    local window="" seen="" windows_txt="$OUT/windows-$tag.txt"
    : > "$windows_txt"
    local deadline=$(( $(date +%s) + TIMEOUT ))
    while [ "$(date +%s)" -lt "$deadline" ]; do
        kill -0 "$app_pid" 2>/dev/null || break
        # 标题匹配（最强证据：这是**我的**窗口，不是别人的）
        # ⚠️⚠️【`#49` 车道 W76A 修 **`D-G79`**（2026-09-21）：**原来这一格"按标题认领"其实在按类名认领。**】
        #   缺陷现场（`#49` 收尾链，两趟门禁 **12/12 假 FAIL**，`fail_reasons=("no-window")`）：
        #     `grep -F 'WpfTextDemo'` 匹配的是 **`WM_CLASS`** —— 本进程**每一个**顶层窗的 class 都是
        #     `HwndWrapper[WpfTextDemo;;<guid>]` ⇒ 5 个顶层窗**全是**候选；而 `head -1` 取到的是
        #     **topmost** 那个（X 里新建窗口默认压在最上层），实测被
        #     **`0x200006`（无名、`style=0x0`、`800x600`、永远不 map；由托管侧在"主窗建立之后、map 之前"新建）**
        #     顶掉 ⇒ 每趟都等到 60 s 超时判 `no-window`，而**真窗 `0x200005`（标题
        #     `WpfTextDemo — text / binding / image / effect`、938x938）一直 `Map State: IsViewable`**。
        #     逐字树（`xwininfo -root -tree` 给的次序 = `head -1` 的取值域）：
        #       0x200006 (has no name): ("HwndWrapper[WpfTextDemo;;94a965e1…]") 800x600  ← head -1 取它（IsUnMapped）
        #       0x200005 "WpfTextDemo — text / binding / image / effect" 938x938        ← 真窗（IsViewable）
        #       0x200004 "SystemResourceNotifyWindow" / 0x200003 "MediaContextNotificationWindow" / 0x200002 (has no name)
        #   ⇒ 族属同 `D-G59`/`D-G77`：**"认错了对象，读数照给"**。`#48`/`#47` 那两趟 `windows-*.txt` 里
        #     唯一候选**恰好就是真窗** ⇒ **这条洞一直在，只是这一代被触发**（不是本波产品回归：
        #     真窗建/缩放/映射/呈现全部正常，`[mil 8] X11 Resize → 938x938`、`committed=886`、`skia 指令 261 条`）。
        #   【修法】**枚举全部候选**，取**第一个**满足「`WM_NAME` 以 `WpfTextDemo` 开头 ∧ 宽高 ≥64 ∧ `Map State: IsViewable`」者。
        #   ⚠️ **判据没有放宽**（反极性已实测）：真窗不可见 / 尺寸不达标 ⇒ **仍然 FAIL**，
        #      **不是**"任意候选可见即过"（旧的 size/state 两条守卫原样保留，只是从"只对 head -1"改成"对每个候选"）。
        #   ⚠️ **残余边界（如实记）**：一个**别的进程**的**可见**窗口若标题也以 `WpfTextDemo` 开头，仍会被认领
        #      —— 这与修前注释里"按标题认领"的**原意一致**，但**不是**"只认我自己的进程树"；未纳入本修法。
        local titled
        while IFS= read -r titled; do
            [ -n "$titled" ] || continue
            local tinfo tstate tw th tname
            tinfo="$(xwininfo -id "$titled" 2>/dev/null)"
            tw="$(printf '%s\n' "$tinfo" | awk -F: '/^  Width:/{gsub(/ /,"",$2);print $2}')"
            th="$(printf '%s\n' "$tinfo" | awk -F: '/^  Height:/{gsub(/ /,"",$2);print $2}')"
            tstate="$(printf '%s\n' "$tinfo" | awk -F: '/Map State:/{gsub(/^ +/,"",$2);print $2}')"
            # `WM_NAME`：`xwininfo -id` 的首行**可能是空行**（实测本机：`\n` 先出，`xwininfo: Window id: …` 在**第二行**）
            #   ⇒ 锚 `1s/…` 会**逐趟取到空串**（本波自己踩过：`name=?` ⇒ 所有候选被拒 ⇒ 仍然 `no-window`）。
            #   ⇒ 用"逐行匹配、取第一条命中"（无名窗是 `(has no name)` ⇒ 不匹配）。
            tname="$(printf '%s\n' "$tinfo" | sed -n 's/^xwininfo: Window id: [^ ]* //p' | head -1)"
            printf '     标题匹配候选 %s name=%s %sx%s map=%s\n' \
                "$titled" "${tname:-?}" "${tw:-?}" "${th:-?}" "${tstate:-?}" >> "$windows_txt"
            case "$tname" in
                '"WpfTextDemo'*) ;;                    # 标题必须以 WpfTextDemo 开头（类名不算）
                *) continue ;;
            esac
            if [ -n "$tw" ] && [ "$tw" -ge 64 ] 2>/dev/null && [ -n "$th" ] && [ "$th" -ge 64 ] 2>/dev/null; then
                case "$tstate" in *IsViewable*) window="$titled"; break ;; esac
            fi
        done < <(xwininfo -root -tree 2>/dev/null | grep -F 'WpfTextDemo' | grep -oE '0x[0-9a-f]+' | awk '!seen[$0]++')
        [ -n "$window" ] && break
        sleep 0.25
    done

    wait "$snap_pid" 2>/dev/null || true
    if [ -s "$OUT/first-sight-$tag.id" ]; then
        echo "   📸 抢拍：崩溃前抓到窗口 $(cat "$OUT/first-sight-$tag.id")（$(identify -format '%wx%h' "$first_sight" 2>/dev/null)），见 $first_sight"
    fi

    # 3c) 等"首绘"的**显式信号**（台账里出现 `skia 指令 N>0`）——比固定 sleep 可靠
    local waited=0
    if [ -n "$window" ]; then
        while [ "$waited" -lt 80 ]; do
            grep -qE "skia 指令 [1-9][0-9]* 条" "$log" 2>/dev/null && break
            kill -0 "$app_pid" 2>/dev/null || break
            sleep 0.25; waited=$((waited + 1))
        done
    fi

    # 3d) ★ 抓帧：**root 连拍 + 按窗口几何裁剪 + 取最佳帧**
    #   【为什么彻底改掉"一次 xwd -id"】主控复跑实测（2026-09-11）：同一应用 full 模式
    #   **真的画了**（`skia 指令 145 条`、`未画种类 0`、exit=143），而单次抓帧 3 次里 2 次
    #   拿到全白（411 B / 1 色）⇒ 判据③ 判 FAIL ⇒ **把成功报成失败**。
    #   这是"工具在说谎"里最贵的一种，所以判据与**抓帧时刻**彻底解耦：
    #     · 单色帧 = **本帧无效**，只计数（frames_blank），**不计入失败**；
    #     · 判据看的是"**有没有过一张有效帧**"（frames_good > 0），不是"最后一张好不好"；
    #     · 一张有效帧都没有 ⇒ 结果记为 **INCONCLUSIVE（仪器问题）**，而不是 FAIL。
    local ring_out="NA" ring_in="NA" ring_verdict="skipped"
    local frames_total=0 frames_blank=0 frames_good=0 frames_rich=0 frame_hist=""
    local max_concurrent=0 _cc
    local frame_files=()          # 所有抓到的帧（滚动前 + 滚动后），判据④ 在**并集**上判
    local colors=0 shot_bytes=0 geom_now="" crop_mismatch=0
    if [ -n "$window" ]; then
        echo "   窗口：$window（等到首绘信号约 $((waited / 4))s）"
        local info ax ay gw gh
        info="$(xwininfo -id "$window" 2>/dev/null)"
        printf '%s\n' "$info" | sed -n '1,12p' | sed 's/^/     /'
        ax="$(printf '%s\n' "$info" | awk -F: '/Absolute upper-left X/{gsub(/ /,"",$2);print $2}')"
        ay="$(printf '%s\n' "$info" | awk -F: '/Absolute upper-left Y/{gsub(/ /,"",$2);print $2}')"
        gw="$(printf '%s\n' "$info" | awk -F: '/^  Width:/{gsub(/ /,"",$2);print $2}')"
        gh="$(printf '%s\n' "$info" | awk -F: '/^  Height:/{gsub(/ /,"",$2);print $2}')"
        geom_now="${gw}x${gh}"
        local burst="${WPTD_BURST:-8}" bi bc dims
        for bi in $(seq 1 "$burst"); do
            if xwd -root -display "$DISPLAY" -out "$OUT/burst-$tag-$bi.xwd" 2>/dev/null \
               && convert "$OUT/burst-$tag-$bi.xwd" -crop "${gw}x${gh}+${ax}+${ay}" +repage "$OUT/burst-$tag-$bi.png" 2>/dev/null; then
                dims="$(identify -format '%wx%h' "$OUT/burst-$tag-$bi.png" 2>/dev/null)"
                [ "$dims" = "$geom_now" ] || crop_mismatch=$((crop_mismatch + 1))
                bc="$(convert "$OUT/burst-$tag-$bi.png" -format '%k' info: 2>/dev/null)"; bc="${bc:-0}"
                frames_total=$((frames_total + 1))
                frame_hist="$frame_hist$bc,"
                if [ "$bc" -le 1 ]; then frames_blank=$((frames_blank + 1)); else frames_good=$((frames_good + 1)); fi
                [ "$bc" -ge "$min_colors" ] && frames_rich=$((frames_rich + 1))
                frame_files+=("$OUT/burst-$tag-$bi.png")
                if [ "$bc" -gt "$colors" ]; then
                    colors="$bc"; cp -f "$OUT/burst-$tag-$bi.png" "$shot"; shot_bytes="$(stat -c%s "$shot")"
                    echo "     帧 $bi/$burst：颜色数 $bc（最佳，已采用）"
                fi
            fi
            sleep 0.12
        done
        # ── 判据⑤b 独立几何互证（**不依赖 xwd -id**）────────────────────────────
        #   【为什么换掉原来的写法】原交叉校验拿 `xwd -id` 直抓当参照，实测它在第 2 次
        #   rep 起就返回**全黑**（446 B / 879844 全像素不同）⇒ 参照物本身不可靠，
        #   差点把"裁剪错位"的假红坐实。改成**从根帧自己取证**：
        #     窗口左边界外 3px（垂直中点）应当是 X 根窗口底色（Xvfb 默认黑）；
        #     窗口内 +5px 应当是应用自己的底色（非黑）。
        #   若裁剪坐标算错（偏了/尺寸错），这两点必有一点不成立 —— 这是**非同义反复**的自检。
        # 窗口可能贴在屏幕左上角（Xvfb 无 WM ⇒ 常见 ax=0）⇒ 左边界外没有余量。
        #   那就用**右边界外**取样，别再因为 ax≤5 直接 skip（skip 等于这条判据不存在）。
        local ring_x
        if [ "${ax:-0}" -gt 5 ]; then ring_x=$((ax - 3)); else ring_x=$((ax + ${gw:-0} + 3)); fi

        if [ "$ring_x" -gt 2 ] && [ "$ring_x" -lt 1277 ]; then
            local root_png="$OUT/root-$tag.png"
            convert "$OUT/burst-$tag-1.xwd" "$root_png" 2>/dev/null
            ring_out="$(convert "$root_png" -format "%[pixel:p{${ring_x},$((ay + gh / 2))}]" info: 2>/dev/null)"
            ring_in="$(convert "$root_png" -format "%[pixel:p{$((ax + 5)),$((ay + gh / 2))}]" info: 2>/dev/null)"
            # 【`D-G42` 族修法 · 车道 W113A · 2026-09-22】原为 `printf '%s' "$ring_out" | grep -qE PAT`：
            #   本件是 `set -uo pipefail`（`:36`）⇒ `grep -q` 命中即早退、`printf` 吃 SIGPIPE(141)
            #   ⇒ **pipefail 把"命中"读成 rc≠0** ⇒ 判据被翻转（假 FAIL）。**只换喂法、正则一字未动**。
            if grep -qE '\(0,0,0\)|gray\(0\)|srgb\(0,0,0\)' <<<"$ring_out"; then
                if ! grep -qE '\(0,0,0\)|gray\(0\)|srgb\(0,0,0\)' <<<"$ring_in"; then
                    ring_verdict="ok"
                    echo "   判据⑤b 几何互证 ✅（窗口外 x=$ring_x 处 $ring_out 是根底色；窗口内 +5px=$ring_in 是应用内容）"
                else
                    ring_verdict="inside-black"
                    echo "   ❌ 判据⑤b 几何互证失败：窗口内 5px 也是黑的（$ring_in）—— 裁剪区可能偏了"
                    tier_fail=1; fail_reasons+=("ring-inside-black")
                fi
            else
                ring_verdict="outside-not-root"
                echo "   ❌ 判据⑤b 几何互证失败：窗口外 x=$ring_x 处（$ring_out）不是根底色 —— 裁剪坐标可能偏了"
                tier_fail=1; fail_reasons+=("ring-outside-$ring_out")
            fi
        fi

        echo "   抓帧统计：**有效帧 $frames_good / 总帧 $frames_total**（单色帧 $frames_blank 只计数、**不计入失败**；其中达到内容阈值 $min_colors 的 **$frames_rich** 帧）"
        # 逐帧颜色数（升序）——把"最佳帧其实只是半张画"这种情形**摆在明面上**，
        # 否则"8/8 有效帧"会让人以为每一帧都是完整画面。
        echo "   逐帧颜色数（升序）：$(printf '%s' "$frame_hist" | tr ',' '\n' | grep -v '^$' | sort -n | tr '\n' ' ')"
        [ -s "$shot" ] && echo "   采用截图：$shot（${shot_bytes} 字节，$(identify -format '%wx%h' "$shot" 2>/dev/null)，颜色数 ${colors}）"
    else
        echo "   ❌ 没找到本应用的窗口（标题 WpfTextDemo 未出现）—— 看 $windows_txt 与 $log"
        tier_fail=1; fail_reasons+=("no-window")
    fi

    # 3e) ★ **滚动后二次抓帧**（真滚动 + 视口外内容取证）
    #   【为什么必须滚】D-c 结案（T2b 实测）：⑤ 卡片的三个图形**都在画**，但设备 y≈837
    #   落在 ScrollViewer 的 clip 底边 828 **之下** ⇒ 整块被视口裁掉。也就是说
    #   `shapes_tomato=0` 是"**要滚动才看得见**"，不是"没画"。
    #   所以门禁必须**滚一次再抓**：
    #     · 让视口外的特性真正进入画面（判据④ 因此在"滚动前+滚动后"帧的**并集**上判）；
    #     · 顺带把"ScrollViewer 真滚动"变成一条**可判真的特性**（判据⑥）。
    #   【纪律】没有删任何特性、也没有把判据放宽成"看不见也算过"——恰恰相反：
    #     现在要求"滚动前后画面必须**不一样**"，比原来更严。
    local scrolled=0 scroll_ae="-"
    local before_shot="$OUT/wpftextdemo-$tag-before.png" after_shot="$OUT/wpftextdemo-$tag-after.png"
    if [ -n "$window" ] && kill -0 "$app_pid" 2>/dev/null && [ "${WPTD_SCROLL:-1}" = "1" ]; then
        # before = 第一趟的最佳帧；**同时把它当时的颜色数记下来**，好在判据⑥ 的取样行里
        #   把"两趟各自的最佳色数"一起打出来（读者能一眼看出 AE 是拿一对**真帧**算的，
        #   而不是"同一张图自己跟自己比"——那正是 2026-09-13 修掉的那个假红）。
        [ -s "$shot" ] && { cp -f "$shot" "$before_shot"; before_colors="$colors"; }
        # 【为什么要改成"绝对坐标 + 不带 --window"】实测（2026-09-11）：
        #   `xdotool click --window $w 5` 走的是 **XSendEvent（合成事件）**，很多工具包
        #   （含我们的 shim/WPF 输入路径）会忽略 `send_event` 标志 ⇒ 滚轮**根本没到应用**，
        #   表现为"滚动前后 AE=0"（看起来像"滚动坏了"，其实是注入方式错了）。
        #   正确做法：`mousemove` 到窗口内的绝对坐标 + 不带 `--window` 的 `click`（走 **XTest**，
        #   是真实指针事件）。5 = wheel down。
        local absx=$((ax + 200)) absy=$((ay + 400)) si
        xdotool mousemove "$absx" "$absy" 2>/dev/null || true
        sleep 0.4
        for si in 1 2 3 4 5 6 7 8; do
            xdotool click 5 2>/dev/null || true
            sleep 0.2
        done
        sleep 0.8
        local burst2=6 bi2 bc2
        # 【★ 2026-09-13 假红修复】`after_shot` **必须取自第二趟 burst**，不能用全局"最佳帧"指针。
        #   旧写法：`[ -s "$shot" ] && cp -f "$shot" "$after_shot"`，而 `$shot` 只在
        #   `bc2 > colors` 时才更新 ⇒ **只要第二趟的颜色数不高于第一趟，"最佳帧"就还停在滚动前**
        #   ⇒ after 成了 before 的副本 ⇒ `AE=0` ⇒ **判据⑥ 假红**。
        #   实测现场（波 9，垫片卡落地后）：滚动**确实生效**（应用侧
        #   `WPTD_SCROLL_MOVED=offset=48→96→144→192→209.2 delta=48 scrollable=209.2`，
        #   滚到底），burst1↔burst2 首帧逐像素差 **AE=141605**（env 档 135468），
        #   但 before/after 两张图 **md5 完全相同**（都等于 `burst-default-r1-1.png`），
        #   于是门禁报 `AE=0 ⇒ 滚动没有改变画面`。⇒ 现在**各趟各记一个最佳帧**：
        #     `shot`  = 全程最佳（截图产物用，语义不变）
        #     `shot2` = **第二趟的最佳**（判据⑥ 用，保证 before/after 分别来自两趟）
        local shot2=""
        for bi2 in $(seq 1 "$burst2"); do
            _cc="$(app_procs_count)"; [ "${_cc:-0}" -gt "$max_concurrent" ] && max_concurrent="$_cc"
            if xwd -root -display "$DISPLAY" -out "$OUT/burst2-$tag-$bi2.xwd" 2>/dev/null \
               && convert "$OUT/burst2-$tag-$bi2.xwd" -crop "${gw}x${gh}+${ax}+${ay}" +repage "$OUT/burst2-$tag-$bi2.png" 2>/dev/null; then
                bc2="$(convert "$OUT/burst2-$tag-$bi2.png" -format '%k' info: 2>/dev/null)"; bc2="${bc2:-0}"
                frames_total=$((frames_total + 1)); frame_hist="$frame_hist$bc2,"
                if [ "$bc2" -le 1 ]; then frames_blank=$((frames_blank + 1)); else frames_good=$((frames_good + 1)); fi
                [ "$bc2" -ge "$min_colors" ] && frames_rich=$((frames_rich + 1))
                frame_files+=("$OUT/burst2-$tag-$bi2.png")
                if [ "$bc2" -gt "$colors" ]; then
                    colors="$bc2"; cp -f "$OUT/burst2-$tag-$bi2.png" "$shot"; shot_bytes="$(stat -c%s "$shot")"
                    echo "     滚动后帧 $bi2/$burst2：颜色数 $bc2（全程最佳，已采用）"
                fi
                # 第二趟自己的最佳（与全程最佳解耦）
                if [ -z "$shot2" ] || [ "$bc2" -gt "$shot2_colors" ]; then
                    shot2_colors="$bc2"; shot2="$OUT/burst2-$tag-$bi2.png"
                fi
            fi
            sleep 0.12
        done
        # 判据⑥ 的 after 一律取**第二趟**的最佳帧；取不到才退回"全程最佳"并**大声说明**
        if [ -n "$shot2" ] && [ -s "$shot2" ]; then
            cp -f "$shot2" "$after_shot"
            echo "   判据⑥ 取样：before=第一趟最佳（色数 ${before_colors:-?}）、after=第二趟最佳（色数 ${shot2_colors:-?}）"
        elif [ -s "$shot" ]; then
            cp -f "$shot" "$after_shot"
            echo "   ⚠️ 判据⑥ 第二趟没有可用帧 ⇒ 退回全程最佳帧（此时 AE 不可信，请看 frames_good）"
        fi
        # 【判据⑤ 的独立交叉校验】"裁剪尺寸 == xwininfo 几何"**接近于同义反复**
        #   （我本来就是按那个几何裁的），它只能抓到"窗口超出屏幕导致裁剪被钳制"。
        #   所以再**独立**抓一次窗口本身（`xwd -id`），与**同一时刻**的裁剪帧逐像素比：
        #   AE≈0 ⇒ 裁剪区确实就是那个窗口；AE 很大 ⇒ 裁剪坐标算错了（会拿到"别处的画面"）。
        local cross_ae="-"
        if xwd -id "$window" -display "$DISPLAY" -out "$OUT/direct-$tag.xwd" 2>/dev/null            && convert "$OUT/direct-$tag.xwd" "$OUT/direct-$tag.png" 2>/dev/null; then
            local last_frame
            last_frame="$(ls -1 "$OUT"/burst2-$tag-*.png 2>/dev/null | tail -1)"
            if [ -n "$last_frame" ] && [ -s "$last_frame" ]; then
                cross_ae="$(compare -metric AE "$last_frame" "$OUT/direct-$tag.png" null: 2>&1 | tr -d '\n' || true)"
                [ -n "$cross_ae" ] || cross_ae="?"
                echo "   判据⑤ 交叉校验：裁剪帧 vs \`xwd -id\` 直抓 AE=$cross_ae（同刻两法互证，0=完全一致）"
            fi
        fi
        echo "   滚动后抓帧统计：有效帧 $frames_good / 总帧 $frames_total（含滚动前）"
        if [ -s "$before_shot" ] && [ -s "$after_shot" ]; then
            scroll_ae="$(compare -metric AE "$before_shot" "$after_shot" null: 2>&1 | tr -d '\n' || true)"
            [ -n "$scroll_ae" ] || scroll_ae="?"
            echo "   滚动前/后最佳帧逐像素差：AE=$scroll_ae（>0 ⇒ 画面确实变了）"
            [ "$scroll_ae" != "0" ] && [ "$scroll_ae" != "?" ] && scrolled=1
        fi
    else
        echo "   （跳过滚动阶段：窗口不在/进程已死/WPTD_SCROLL=0）"
    fi

    # ── 判据 ① 存活 + 退出码 143 ─────────────────────────────────────────────
    local alive=0
    kill -0 "$app_pid" 2>/dev/null && alive=1
    if [ "$alive" != "1" ]; then
        echo "   ❌ 判据① 截屏时刻进程已死："
        grep -A 8 "Unhandled exception" "$log" 2>/dev/null | head -12 | sed 's/^/     /'
        tier_fail=1; fail_reasons+=("process-dead")
    fi
    # 收尾：SIGTERM → 退出码应为 143（128+15）。**不用管道取 rc**（坑 3）
    kill -TERM "$app_pid" 2>/dev/null || true
    wait "$app_pid" 2>/dev/null
    local app_exit=$?
    if [ "$alive" = "1" ] && [ "$app_exit" != "143" ]; then
        echo "   ❌ 判据① 退出码应为 143（SIGTERM），实测 $app_exit"
        tier_fail=1; fail_reasons+=("exit-$app_exit")
    fi
    # 收尾验证：wait 返回后应用**必须**真的不在进程表里（这是 exec 修复后的硬断言）
    local leftover_after=0 global_after=0
    sleep 0.3
    kill -0 "$app_pid" 2>/dev/null && leftover_after=1        # 精确：我这一轮那个 PID 还在吗
    [ "$leftover_after" = "0" ] || leftover_after="$(app_procs_count)"
    global_after="$(app_procs_global_count)"
    if [ "${leftover_after:-0}" != "0" ]; then
        echo "   ❌ 收尾后仍有 $leftover_after 个应用进程存活（kill/wait 没作用到真身）—— 立即清理"
        app_procs | sed 's/^/      pid /'
        for _p in $(app_procs); do kill -TERM "$_p" 2>/dev/null || true; done; sleep 0.5
        for _p in $(app_procs); do kill -KILL "$_p" 2>/dev/null || true; done
        tier_fail=1; fail_reasons+=("leftover-after-$leftover_after")
    fi

    echo "   进程收尾：leftover_after=$leftover_after（我自己的子进程口径）；全机同一样例进程=$global_after（含别人的）"
    echo "   判据① 存活/退出码：alive=$alive exit=$app_exit $([ "$alive" = 1 ] && [ "$app_exit" = 143 ] && echo '✅' || echo '❌')"

    # ── 已知缺陷归类（崩溃点落在谁的车道上；机读）──────────────────────────
    #   【为什么必须归类】"FAIL"本身不告诉主控该派给谁。本工程已有多个**已知**阻塞点，
    #   它们是**别人的车道**（src/**、build/**），本 runner 只登记不改。
    local blocker="none"
    if grep -q 'LoCreateContext' "$log" 2>/dev/null; then
        blocker="lineservices:LoCreateContext"
        echo "   ⛔ 已知阻塞：文本回落到 **LineServices**（\`LoCreateContext\` 在 Win32 shim 里不存在）"
        echo "      语义：WPF 的文本快路径（SimpleTextLine）被拒 ⇒ FullTextLine ⇒ 需要 PresentationNative 的 LS 引擎。"
        echo "      LS 未实现（110 条 Lo*/Fs*/Nl* 导出，C++ 不在本仓库）⇒ 进程 abort。车道：PC/文本移植面。"
    elif grep -q 'MarshalDirectiveException' "$log" 2>/dev/null; then
        blocker="uia:com-marshal"
        echo "   ⛔ 已知阻塞：UIAutomationTypes 的 COM 封送（UiaCoreTypesApi，COM 接口指针在 Linux 上不可封送）"
    elif grep -q 'PresentationNative_cor3.dll' "$log" 2>/dev/null; then
        blocker="uia:resolver-missing"
        echo "   ⛔ 已知阻塞：UIAutomationTypes 没编 win32 resolver ⇒ PresentationNative_cor3.dll 解析失败"
    elif grep -q 'InvalidOperationException' "$log" 2>/dev/null; then
        blocker="wic:bitmap-source-create"
        echo "   ⚠️ 位图路径异常（BitmapSource.Create）——样例已降级为矢量图并打印原因，属已知 WIC 缺口"
    fi

    # 应用自报的"已知缺陷"标记（样例里 catch 住并**大声登记**的那种）：
    #   样例不会静默吞掉缺陷 —— 它打印 `WPTD_KNOWN_DEFECT=...`，这里原样转出来给主控。
    local app_defect
    app_defect="$(grep -oE 'WPTD_KNOWN_DEFECT=[a-z0-9-]+' "$log" 2>/dev/null | head -1)"
    [ -n "$app_defect" ] && echo "   📌 应用自报已知缺陷：$app_defect（样例降级继续跑，未静默）"
    local app_degraded
    app_degraded="$(grep -oE 'WPTD_DEGRADED=[a-z,]+' "$log" 2>/dev/null | head -1)"
    local app_mode
    app_mode="$(grep -oE 'WPTD_MODE=[a-z]+' "$log" 2>/dev/null | head -1)"
    [ -n "$app_mode" ] && echo "   🏷 应用自报运行模式：$app_mode"
    [ -n "$app_degraded" ] && echo "   🏷 应用自报降级项：$app_degraded（本档结论必须带此前提）"

    # ── 判据 ② skia 指令 > 0 且 未画种类 0（**空帧下的"未画种类 0"是空真**）──────
    local notdrawn="" drawn="" notdrawn_line="" has_clause=0
    # 取**指令数最多**的那一帧（不是"最后一条"）：末帧可能只是资源创建/空帧，
    #   而真正的画面在更早的某一帧上。按 max(drawn) 取，才是"这条通道画过什么"的证据。
    notdrawn_line="$(grep -E "skia 指令 [0-9]+ 条，未画种类 [0-9]+" "$log" 2>/dev/null \
                     | sed 's/^ *//' | sort -t' ' -k3,3nr | awk '{print}' | sort -t' ' -k3,3n | tail -1)"
    if [ -n "$notdrawn_line" ]; then
        drawn="$(printf '%s' "$notdrawn_line" | grep -oE 'skia 指令 [0-9]+ 条' | grep -oE '[0-9]+')"
        notdrawn="$(printf '%s' "$notdrawn_line" | grep -oE '未画种类 [0-9]+' | grep -oE '[0-9]+')"
        echo "   台账（取指令数最多的一帧，共 $(grep -cE 'skia 指令 [0-9]+ 条' "$log" 2>/dev/null) 条带计数的呈现行）：$notdrawn_line"
    fi
    # 桥契约（判定函数见文件头 `bridge_contract()`；**对尾巴判，不对整行判**）
    if [ -n "$notdrawn_line" ]; then
        bc="$(bridge_contract "$notdrawn_line")"
        case "$bc" in
            ok*)     echo "   桥契约 ✅ $bc" ;;
            WARN*)   echo "   ⚠️ 桥契约 $bc" ;;
            SUSPECT*) echo "   ⚠️ 桥契约 $bc" ;;
            *)       echo "   ⚠️ 桥契约 $bc" ;;
        esac
    fi
    if [ -z "${notdrawn:-}" ]; then
        echo "   ❌ 判据② 台账里取不到 '未画种类 N'（grep 取值为空 ⇒ 判据不可信，按失败处理）"
        tier_fail=1; fail_reasons+=("notdrawn-unparsable")
    elif [ "${drawn:-0}" = "0" ]; then
        echo "   ❌ 判据② 指令数最多的一帧仍是**空帧**（skia 指令 0 条）⇒ '未画种类 0' 是**空真**，不算通过"
        tier_fail=1; fail_reasons+=("empty-frame")
    elif [ "$notdrawn" != "0" ]; then
        echo "   ❌ 判据② 未画种类 = $notdrawn（>0：通道里有指令**没被画**）"
        grep -oE '\[Mil[A-Za-z]+\]|\[[A-Za-z]+\]×[0-9]+' "$log" 2>/dev/null | sort -u | head -8 | sed 's/^/      /'
        tier_fail=1; fail_reasons+=("notdrawn-$notdrawn")
    else
        echo "   判据② skia 指令 ${drawn} 条 > 0 且 未画种类 = 0 ✅（非空帧，且通道里每种指令都真的画了）"
    fi

    # ── 判据 ③ 抓到过**有效（非单色）帧** ────────────────────────────────────
    #   【语义】"单色帧"= 本帧无效（取样早于首绘 / 窗口未暴露）⇒ **只计数，不计入失败**。
    #   一张有效帧都没有 ⇒ **INCONCLUSIVE**（仪器抓不到），**不是**"应用没画"。
    local capture_status="ok" capture_inconclusive=0
    if [ "$frames_good" = "0" ]; then
        capture_status="all-blank"
        capture_inconclusive=1
        echo "   ⚠️ 判据③ **无法判定（INCONCLUSIVE）**：抓到的 $frames_total 帧全是单色。"
        echo "      这是**仪器问题**（取样窗口全落在首绘之前），**不计入 FAIL** —— 请重跑或调大 WPTD_BURST。"
    elif [ "$colors" -lt "$min_colors" ]; then
        echo "   ❌ 判据③ 最佳有效帧颜色数 ${colors} < 阈值 $min_colors（确实画得太少）"
        tier_fail=1; fail_reasons+=("colors-$colors")
    elif [ "$shot_bytes" -lt 1000 ]; then
        echo "   ❌ 判据③ 采用帧过小（${shot_bytes} 字节）"; tier_fail=1; fail_reasons+=("shot-tiny")
    else
        echo "   判据③ 有有效帧 ✅（最佳 ${colors} 色 ≥ $min_colors；有效帧 $frames_good/$frames_total，单色 $frames_blank 只计数）"
    fi

    # ── 判据 ⑤ 裁剪自检：截图的几何必须等于 xwininfo 报的窗口几何 ─────────────
    #   【为什么要有】抓帧改成"root 连拍 + 按几何裁剪"之后，**裁剪区对不对**本身成了判据的一部分：
    #   裁错区域会得到"看起来有颜色但不是这个窗口"的图，比全白更能骗人。
    if [ "$frames_good" != "0" ] && [ -s "$shot" ]; then
        local shot_dims; shot_dims="$(identify -format '%wx%h' "$shot" 2>/dev/null)"
        if [ "$shot_dims" = "$geom_now" ]; then
            echo "   判据⑤ 裁剪几何自检 ✅（截图 $shot_dims == xwininfo $geom_now）"
            echo "      ⚠️ 这一条**本身接近于同义反复**（裁剪就是用这个几何做的）——真正的互证见下面的交叉校验"
        else
            echo "   ❌ 判据⑤ 裁剪几何不一致：截图 $shot_dims vs xwininfo $geom_now（裁剪区算错了）"
            tier_fail=1; fail_reasons+=("crop-geom-$shot_dims-vs-$geom_now")
        fi
        [ "$crop_mismatch" = "0" ] || echo "      （另有 $crop_mismatch 帧裁剪尺寸不符，已忽略）"
        # 交叉校验判定：AE 允许极小差异（两次抓拍之间应用可能重绘），但**不允许量级性不符**
        if [ "${cross_ae:-}" != "-" ] && [ "${cross_ae:-}" != "?" ] && [ -n "${geom_now:-}" ]; then
            local px_limit=$(( ${gw:-0} * ${gh:-0} / 20 ))     # 5% 像素
            if [ "$cross_ae" -le "$px_limit" ] 2>/dev/null; then
                echo "   判据⑤b 独立交叉校验 ✅（AE=$cross_ae ≤ 5% 像素 $px_limit）"
            else
                echo "   ❌ 判据⑤b 交叉校验失败：AE=$cross_ae > 5% 像素 $px_limit —— 裁剪区与窗口不是同一块画面"
                tier_fail=1; fail_reasons+=("crop-cross-ae-$cross_ae")
            fi
        fi
    fi

    # ── 判据 ④ 文字/特性色真的在屏上（逐色计数，不是白像素总数）─────────────
    local textpx_report="" textpx_missing=""
    if [ "$feature_applicable" = "0" ]; then
        echo "   判据④ **本档不适用**（$tier 档的可视树里没有这些特性控件）—— 不判通过、也不判失败"
    elif [ "${#frame_files[@]}" != "0" ]; then
        # 【在**所有帧的并集**上判】视口外的特性需要滚动才可见（D-c 结案），所以
        #   "画了没有"的判据必须覆盖"滚动前 + 滚动后"的全部帧；单看一张必然假红。
        # 【性能】原来用 `convert … txt:-` 逐像素转文本：实测 **~20 秒/帧**（938×938），
        #   14 帧就是 5 分钟 —— 直接把整轮跑挂到超时（退出码 124）。改用 ImageMagick 自带的
        #   `-format %c histogram:info:-`（~0.2 秒/帧），读数相同（精确颜色计数，非量化）。
        local pixdump="$OUT/pixels-$tag.txt"
        : > "$pixdump"
        local ff
        for ff in "${frame_files[@]}"; do
            # 【别用 awk 的区间量词】本机 awk 是 **mawk**，`match($0, /#…{6}/)` 里的 `{6}`
            #   不受支持 ⇒ 匹配恒失败 ⇒ **所有特性色都读成 0**（实测踩到，差点又变成假红）。
            #   改用 GNU sed/grep（它们支持 {6}）抽 "计数 颜色"。
            convert "$ff" -format %c histogram:info:- 2>/dev/null \
              | sed -nE 's/^ *([0-9]+):.*(#[0-9A-Fa-f]{6}).*/\1 \2/p' >> "$pixdump"
        done
        awk '{s[$2]+=$1} END{for(k in s) printf "%d %s\n", s[k], k}' "$pixdump" | sort -k2 > "$pixdump.sum"
        echo "   判据④ 判定范围：**${#frame_files[@]} 帧的并集**（滚动前 + 滚动后）"
        local entry name hex cnt
        for entry in "${FEATURE_COLORS[@]}"; do
            name="${entry%%:*}"; hex="${entry##*:}"
            cnt="$(grep -E "^\s*[0-9]+ ${hex}$" "$pixdump.sum" 2>/dev/null | head -1 | grep -oE '^[[:space:]]*[0-9]+' | tr -d ' ')"
            cnt="${cnt:-0}"
            textpx_report="$textpx_report $name=$cnt"
            if [ "$cnt" -lt "$MIN_TEXT_PX" ]; then textpx_missing="$textpx_missing $name($cnt)"; fi
        done
        echo "   判据④ 特性色像素（并集）：$textpx_report"
        if [ -n "$textpx_missing" ]; then
            echo "   ❌ 判据④ 以下特性色像素 < $MIN_TEXT_PX（**滚到底之后仍然没出现**）：$textpx_missing"
            tier_fail=1; fail_reasons+=("feature-color-missing:$textpx_missing")
            # 【让"红"可归因】image_content_* 为 0 时，自动附上 WIC 侧取证：
            #   期望 D-d 修好后是 `size=96x96 fmt=…c90f`（Bgra32）；
            #   若仍是 `1x1` + `…c910`（Pbgra32）⇒ **修法没生效**，不是"另有原因"。
            # 【`D-G42` 族修法 · 车道 W113A · 2026-09-22】同上一处：`printf … | grep -q` 在 `pipefail` 下会翻转 rc。
            if grep -q 'image_content' <<<"$textpx_missing"; then
                echo "      ↳ WIC 取证（期望 96x96 + …c90f=Bgra32；1x1/…c910=Pbgra32 即未修好）："
                if grep -qE '\[cwic-trace\]' "$log" 2>/dev/null; then
                    grep -E '\[cwic-trace\]' "$log" 2>/dev/null | tail -4 | sed 's/^/         /'
                else
                    echo "         （本档日志里没有 [cwic-trace]：该 trace 需要 WPF_LINUX_CWIC_TRACE=1，"
                    echo "           而**验收档按判据清空了所有 WPF_LINUX_*** ⇒ 取证改从文末的"
                    echo "           「诊断趟」取（run_dir/census.log），不进验收判据）"
                fi
                local _imgsrc; _imgsrc="$(grep -oE 'WPTD_IMAGE_SOURCE=[^ ]+' "$log" 2>/dev/null | head -1)"
                [ -n "$_imgsrc" ] && echo "      ↳ 应用自报源：$_imgsrc"
            fi
        else
            echo "   判据④ 特性色齐全 ✅（每个可见特性都有 ≥ $MIN_TEXT_PX 像素）"
            echo "      ⚠️ 像素计数**不能替代读图**：请人工/视觉复核 $shot（及滚动前/后帧）"
        fi
    fi

    # ── 可选：输入路径探针（默认关）──────────────────────────────────────────
    # 【为什么默认关】输入路径上有一个**已知 NRE 崩溃**（TextServicesLoader.TIPsWantToRun，
    #   M7b 车道）。打开它得到的是"该缺陷的现状"，不是本档渲染结论的一部分：
    #   崩溃 ⇒ 如实报 FAIL，并注明"被已知缺陷挡住"，**不绕过、不假装通过**。
    local input_result="skipped"
    if [ "$INPUT_PROBE" = "1" ]; then
        echo "   ── 输入探针（真注入鼠标；已知崩溃在此暴露）──"
        if command -v xdotool >/dev/null 2>&1 && [ -n "$window" ]; then
            # 探针需要应用**还活着** —— 上面的收尾已经 TERM 了它，所以这里另起一个进程
            ( cd "$OUT" && exec env "${env_args[@]}" dotnet WpfTextDemo.dll $app_args >> "$log" 2>&1 ) &
            local ipid=$!
            sleep 6
            # 【为什么要扫多个点】命中目标在两种可视树里位置不同：完整档的命中条在窗口**底部**，
            #   --minimal 档的在**顶部**。只打一个点会得到"0 个事件"的假阴性（实测踩到）。
            #   所以竖向扫 3 个点，每点 move+click，再看有没有事件落到应用侧处理器上。
            for _y in 80 300 560; do
                xdotool mousemove --window "$window" 400 "$_y" 2>/dev/null || true; sleep 0.5
                xdotool click --window "$window" 1 2>/dev/null || true;            sleep 0.5
            done
            if kill -0 "$ipid" 2>/dev/null; then
                input_result="alive"
                echo "   ✅ 输入探针：注入后进程存活（MouseEnter/Down 是否到达看下两行）"
            else
                input_result="crashed"
                echo "   ❌ 输入探针：注入后进程**已死** —— 已知缺陷（M7b 车道）"
                grep -A 6 "Unhandled exception" "$log" 2>/dev/null | tail -8 | sed 's/^/      /'
            fi
            grep -c '\[wptd\] 事件：' "$log" 2>/dev/null | sed 's/^/   应用打印的鼠标事件行数：/'
            kill -TERM "$ipid" 2>/dev/null || true; wait "$ipid" 2>/dev/null || true
        else
            input_result="unavailable"
            echo "   ⚠️ 输入探针不可用（缺 xdotool 或没有窗口）"
        fi
    fi

    # ── 判据 ⑥ ScrollViewer 真滚动（D-c 结案后新增：视口外内容必须先滚出来）────
    local scroll_verdict="n/a"
    if [ -n "$window" ] && [ "${WPTD_SCROLL:-1}" = "1" ]; then
        if [ "$scrolled" = "1" ]; then
            scroll_verdict="ok"; echo "   判据⑥ 真滚动 ✅（滚动前/后最佳帧 AE=$scroll_ae）"
        else
            scroll_verdict="no-change"
            echo "   ❌ 判据⑥ 滚动**没有**改变画面（AE=$scroll_ae）—— 视口外内容取不到，且'真滚动'这条特性未成立"
            tier_fail=1; fail_reasons+=("scroll-no-change")
        fi
    fi

    # MIL 通道计数器（committed/pending/资源）—— 台账里 `通道#N: …` 那几行就是它。
    #   取法：`WPF_LINUX_MIL_TRACE=1`（本 runner 默认已开）⇒ 应用**stderr** 里，
    #   命令：grep '通道#' "$LOG" | tail -3
    local chan_line chan2_committed chan2_pending
    chan_line="$(grep '通道#2:' "$log" 2>/dev/null | tail -1 | sed 's/^ *//')"
    chan2_committed="$(printf '%s' "$chan_line" | grep -oE 'committed=[0-9]+' | head -1 | cut -d= -f2)"
    chan2_pending="$(printf '%s' "$chan_line" | grep -oE '(^| )pending=[0-9]+' | head -1 | grep -oE '[0-9]+')"
    [ -n "$chan_line" ] && echo "   通道#2 计数器（committed/pending 出处：grep '通道#' \$LOG | tail -1）：committed=${chan2_committed:-NA} pending=${chan2_pending:-NA}"

    # 应用自报的位图源（D-d 取证：Create 成功 ≠ 源真的是 96x96）
    local img_src
    img_src="$(grep -oE 'WPTD_IMAGE_SOURCE=[^ ]+' "$log" 2>/dev/null | head -1)"
    [ -n "$img_src" ] && echo "   🖼 $img_src"

    # ── 档位小结 ─────────────────────────────────────────────────────────────
    # 三态：PASS / FAIL（真红）/ INCONCLUSIVE（仪器抓不到帧 —— **不与 FAIL 混**）
    local result="PASS"
    if [ "$tier_fail" != "0" ]; then result="FAIL"
    elif [ "$capture_inconclusive" = "1" ]; then result="INCONCLUSIVE"; fi
    echo "   ── 档位 $tier：$result（原因：${fail_reasons[*]:-无}）"
    # 逐次读数落盘：结尾做"跨档对比"用（**只陈述事实，不做因果解释**）
    printf '%s|%s|%s|%s|%s|%s|%s\n' "$tier" "$rep" "${drawn:-NA}" "${notdrawn:-NA}" "${colors:-0}" "$frames_good" "$frames_rich" "${scrolled}" >> "$OUT/tier-readings.txt"

    # 基线机读行（只在 WPTD_BASELINE_OUT 指定时写；路径必须**不在共享临时目录**）
    if [ -n "${WPTD_BASELINE_OUT:-}" ]; then
        printf 'BASELINE tier=%s rep=%s config=pc:%s,bridge:%s,pf:%s,provider:%s,win32shim:%s,wic_shim:%s,hbtextline_shim:%s(%s) result=%s exit=%s drawn=%s notdrawn=%s frames_good=%s frames_total=%s frames_blank=%s capture=%s scroll=%s shot_dims=%s colors=%s cross_ae=%s max_concurrent_apps=%s leftover_after=%s rundir=%s\n' \
          "$tier" "$rep" "${PC_SHA:-NA}" "${BRIDGE_SHA:-NA}" "${PF_SHA:-NA}" "${PROVIDER_SHA:-NA}" "${WIN32SHIM_SHA:-NA}" "${WICSHIM_SHA:-NA}" "${HBTEXT_SHA:-NA}" "stale:${HBTEXT_STALE}" \
          "$result" "$app_exit" "${drawn:-NA}" "${notdrawn:-NA}" "$frames_good" "$frames_total" "$frames_blank" \
          "$capture_status" "${scroll_verdict:-n/a}" "$(identify -format '%wx%h' "$shot" 2>/dev/null || echo NA)" "${colors:-0}" "${cross_ae:-NA}" "$max_concurrent" "${leftover_after:-NA}" "$OUT" >> "$WPTD_BASELINE_OUT"
    fi

    echo "WPTD_TIER=$tier rep=$rep RESULT=$result exit=$app_exit notdrawn=${notdrawn:-NA} drawn=${drawn:-NA} colors=$colors frames_good=$frames_good frames_total=$frames_total frames_blank=$frames_blank scroll=$scroll_verdict/${scroll_ae} capture=$capture_status max_concurrent_apps=$max_concurrent leftover_after=${leftover_after:-NA} ring=${ring_verdict:-NA}/$ring_out/$ring_in chan2_committed=${chan2_committed:-NA} chan2_pending=${chan2_pending:-NA} cross_ae=${cross_ae:-NA} blocker=$blocker shot=$shot input_probe=$input_result"
    case "$result" in
        PASS) return 0 ;;
        INCONCLUSIVE) return 2 ;;
        *) return 1 ;;
    esac
}

# ── 4. 跑档位（default 是**主验收档**，必须第一个跑）─────────────────────────
# 【为什么要重复 N 次】实测（2026-09-11）：文本回落 LineServices 的崩溃是**间歇性**的 ——
#   同一份 XAML 三连跑全过、换个窗口大小/文本量就稳定崩。单跑一次得出的结论**不可信**。
#   `WPTD_REPEAT=N` 可调；通过率不足 100% 即该档 FAIL。
#
# 【验收档 vs 诊断档 —— 两者绝不可混为一谈】
#   验收档：default（默认配置，主） / env（带字体覆盖，对照）。**门禁结论只看这两档。**
#   诊断档：degraded（关掉已知阻塞特性）/ minimal（最小可视树）。**只用于拿图证与定位**，
#           它们的结论**不带"默认配置可用"的含义**，所以**不参与** WPTD_SUMMARY。
REPEAT="${WPTD_REPEAT:-3}"
run_tier_repeated() {
    local tier="$1"; local app_args="$2"; shift 2
    local ok=0 inc=0 bad=0 r rc
    for r in $(seq 1 "$REPEAT"); do
        run_tier "$tier" "$r" "$app_args $EXTRA_APP_ARGS" "$@"; rc=$?
        case "$rc" in
            0) ok=$((ok + 1)) ;;
            2) inc=$((inc + 1)) ;;
            *) bad=$((bad + 1)) ;;
        esac
    done
    echo "   ── 档位 $tier 汇总：通过 $ok/$REPEAT，失败 $bad，**仪器无效(INCONCLUSIVE) $inc**"
    echo "WPTD_TIER_SUMMARY=$tier passed=$ok/$REPEAT failed=$bad inconclusive=$inc"
    if [ "$ok" = "$REPEAT" ]; then return 0
    elif [ "$bad" != "0" ]; then return 1        # 有真红 ⇒ 该档 FAIL
    else return 2; fi                            # 全部非通过都是仪器问题 ⇒ 该档 INCONCLUSIVE
}

WANT_DEFAULT=0; WANT_ENV=0; WANT_DEGRADED=0; WANT_MINIMAL=0
case "$TIER" in
    default)  WANT_DEFAULT=1 ;;
    env)      WANT_ENV=1 ;;
    both)     WANT_DEFAULT=1; WANT_ENV=1 ;;
    degraded) WANT_DEGRADED=1 ;;
    minimal)  WANT_MINIMAL=1 ;;
    all|matrix) WANT_DEFAULT=1; WANT_ENV=1; WANT_DEGRADED=1; WANT_MINIMAL=1 ;;
esac

ACC_PASSED=0; ACC_TOTAL=0; ACC_FAILED=""; ACC_INC=""
DIAG_PASSED=0; DIAG_TOTAL=0; DIAG_FAILED=""
rc=0

if [ "$WANT_DEFAULT" = "1" ]; then
    ACC_TOTAL=$((ACC_TOTAL + 1))
    run_tier_repeated default "" "${CLEAR_ARGS[@]}"; rc=$?
    if [ "$rc" = "0" ]; then ACC_PASSED=$((ACC_PASSED + 1))
    elif [ "$rc" = "2" ]; then ACC_INC="$ACC_INC default"; else ACC_FAILED="$ACC_FAILED default"; fi
fi
if [ "$WANT_ENV" = "1" ]; then
    ACC_TOTAL=$((ACC_TOTAL + 1))
    run_tier_repeated env "" "${ENV_TIER_ARGS[@]}"; rc=$?
    if [ "$rc" = "0" ]; then ACC_PASSED=$((ACC_PASSED + 1))
    elif [ "$rc" = "2" ]; then ACC_INC="$ACC_INC env"; else ACC_FAILED="$ACC_FAILED env"; fi
fi
if [ "$WANT_DEGRADED" = "1" ]; then
    DIAG_TOTAL=$((DIAG_TOTAL + 1))
    run_tier_repeated degraded "--diagnostic-degraded" "${CLEAR_ARGS[@]}"; rc=$?
    if [ "$rc" = "0" ]; then DIAG_PASSED=$((DIAG_PASSED + 1)); else DIAG_FAILED="$DIAG_FAILED degraded"; fi
fi
if [ "$WANT_MINIMAL" = "1" ]; then
    DIAG_TOTAL=$((DIAG_TOTAL + 1))
    run_tier_repeated minimal "--minimal" "${CLEAR_ARGS[@]}"; rc=$?
    if [ "$rc" = "0" ]; then DIAG_PASSED=$((DIAG_PASSED + 1)); else DIAG_FAILED="$DIAG_FAILED minimal"; fi
fi

# ── 4.9 字形普查（CJK 豆腐块那类的**面板级**读数：id0 / nonlatin / maxid）────────────
#   【它回答什么】"豆腐块"在字形层表现为 `id0`（未映射/占位字形）偏多、`nonlatin` 偏少。
#   期望（R1 之后）`id0≈0 / nonlatin>0 / maxid≈63151`。
#   ⚠️ **普查绿 ≠ 像素对**（T1d 已登记这条预测假绿）⇒ 本 runner **保留"读图"那一格**，
#      普查只作补充读数，不替代读图。
#   【为什么调别人的脚本】这是 T1c 的装置（会自己装配运行目录并注入诊断 env）。
#      本 runner 只**只读调用**它，并且**显式传自己的显示号**（它默认用 :98，那是主控的）。
CENSUS_LINE=""; CENSUS_RC="skipped"
if [ "${WPTD_CENSUS:-1}" = "1" ]; then
    CENSUS_SCRIPT="$ROOT/build/MilBridge/tools/t1c-census.sh"
    if [ -f "$CENSUS_SCRIPT" ]; then
        echo
        reap_orphans "普查前"
        echo "== 4.9 字形普查（T1c 装置，DISPLAY=$DISPLAY）"
        # 【为什么把两个诊断开关塞进这一步】
        #   · `WPF_LINUX_GLYPH_CENSUS=1` —— 没有它就没有 `[GLYPH_CENSUS]` 行，
        #     T1c 的汇总器也就产不出 `T1C_CENSUS_SUMMARY`（实测踩到：rc=0 但无汇总行）；
        #   · `WPF_LINUX_CWIC_TRACE=1`  —— D-d 的 `[cwic-trace]`（size/fmt）**只在它开时打印**，
        #     而**验收档会按判据清空所有 `WPF_LINUX_*`** ⇒ 诊断读数只能在**非验收的诊断趟**里取。
        #   ⚠️ 这两个开关**绝不**加进验收档：那会改变被测配置本身（那就是"改配置让它过"）。
        WPTD_DISPLAY="$DISPLAY" HOLD_SECONDS="${WPTD_CENSUS_HOLD:-20}" \
            timeout 300 bash "$CENSUS_SCRIPT" "$OUT/census" default \
                WPF_LINUX_GLYPH_CENSUS=1 WPF_LINUX_CWIC_TRACE=1 > "$OUT/census.log" 2>&1
        CENSUS_RC=$?
        CENSUS_LINE="$(grep -oE 'T1C_CENSUS_SUMMARY.*' "$OUT/census.log" 2>/dev/null | tail -1)"
        # [cwic-trace] 由 4.95 的 WIC 路径诊断趟专责（普查趟走的是 BitmapSource.Create 路径，
        #   本来就不会打印该 trace —— 在这里再抓一次只会给出误导性的"没拿到"）。
        # 【前向兼容】把普查日志里**所有**机读/仪表行整段收下来（`[GLYPH_CENSUS]` 逐 run、
        #   各类"…汇总"、T1C_CENSUS_*、CENSUS_ORPHANS…）。这样**新加的仪表**（例如 T1d 的
        #   `Extent`）落地后会自动进基线，不必每来一列就改一次 runner —— "模板复用"的前提。
        CENSUS_ALL="$(grep -aE '^\[GLYPH_CENSUS\]|汇总|T1C_CENSUS_|CENSUS_ORPHANS' "$OUT/census.log" 2>/dev/null | head -24)"
        CENSUS_ORPHANS_LINE="$(grep -aoE 'CENSUS_ORPHANS.*' "$OUT/census.log" 2>/dev/null | tail -1)"
        ORIGIN_SUM_LINE="$(grep -aoE '原点Y汇总.*' "$OUT/census.log" 2>/dev/null | tail -1)"
        ORIGIN_SAMPLE="$(grep -aoE 'originDIP=\([0-9.,-]+\)' "$OUT/census.log" 2>/dev/null | sort | uniq -c | sort -rn | head -4 | tr '\n' ' ')"
        if [ -n "$CENSUS_LINE" ]; then
            echo "   $CENSUS_LINE"
            grep -oE 'T1C_CENSUS_(SHAPE|EMPTY).*' "$OUT/census.log" 2>/dev/null | tail -2 | sed 's/^/   /'
            # CENSUS_ORPHANS / 原点Y汇总：装置新仪表（T1c 修孤儿后固定输出前者；后者服务"行推进≈0"）
            #   ⚠️ 上一版我把这两行提取写进了一个**没 assert 的 replace** ⇒ 静默没生效 ⇒ 基线里是 NA。
            [ -n "${CENSUS_ORPHANS_LINE:-}" ] && echo "   $CENSUS_ORPHANS_LINE"
            if [ -n "${ORIGIN_SUM_LINE:-}" ]; then
                echo "   $ORIGIN_SUM_LINE"
                echo "   originDIP 取值频次（前 4）：${ORIGIN_SAMPLE:-无}"
                _oy="$(printf '%s' "$ORIGIN_SUM_LINE" | grep -oE 'distinct_origin_y=[0-9]+' | cut -d= -f2)"
                _runs="$(printf '%s' "$ORIGIN_SUM_LINE" | grep -oE 'runs=[0-9]+' | cut -d= -f2)"
                if [ -n "${_oy:-}" ] && [ -n "${_runs:-}" ] && [ "$_runs" -gt 1 ]; then
                    echo "   ⇒ 判读记录：$_runs 个 run 落在 $_oy 个不同的 origin_y 上（**是否≈行推进 0** 由文本车道判相关性，本 runner 只记录）"
                fi
            fi
        else
            CENSUS_ORPHANS_LINE=""; ORIGIN_SUM_LINE=""; ORIGIN_SAMPLE=""
            echo "   ⚠️ 普查没产出 T1C_CENSUS_SUMMARY（rc=$CENSUS_RC）—— 记 NA，**不当作通过**；日志：$OUT/census.log"
            CENSUS_LINE="T1C_CENSUS_SUMMARY=NA"
        fi
    else
        echo "== 4.9 字形普查：**装置不存在**（$CENSUS_SCRIPT）⇒ census=NA（明确记录，不静默）"
        CENSUS_LINE="T1C_CENSUS_SUMMARY=NA(script-missing)"
    fi
    reap_orphans "普查后"
fi

# ── 4.95 D-d 的 **WIC 路径**诊断趟（仅在需要时；默认跟普查一起跑）────────────────
#   【为什么单独一趟】`[cwic-trace]` 只在**外部 WIC 句柄**那条路打印，而样例默认走
#   `BitmapSource.Create`（进程内位图）**不触发**（实测：验收档 + 诊断档都没有该行）。
#   所以这里再起一次应用，喂一张**真实 PNG**（由 convert 生成）走 `BitmapImage` 解码路径，
#   并打开 `WPF_LINUX_CWIC_TRACE=1` —— 期望看到 `materialize尺寸=96x96 fmt=…c90f(Bgra32)`；
#   若看到 `1x1` / `…c910(Pbgra32)` ⇒ **D-d 的修法没生效**。
#   ⚠️ 全程在**诊断档**，不进验收判据、不改验收配置。
CWIC_TRACE_ALL=""
if [ "${WPTD_CENSUS:-1}" = "1" ]; then
    # ⚠️ 诊断目录必须放在 $OUT **之外**（`$OUT-wicdiag`）：放里面会在 `cp -r "$OUT"/.` 时自我递归。
    #    而且必须**整目录复制**（含 .deps.json/.runtimeconfig.json）—— 上一版只挑 *.dll/*.so，
    #    结果 `dotnet WpfTextDemo.dll` 起不来、日志为空（实测踩到，白跑一轮）。
    DIAG_DIR="$OUT-wicdiag"; rm -rf "$DIAG_DIR"; mkdir -p "$DIAG_DIR"
    cp -r "$OUT"/. "$DIAG_DIR"/ 2>/dev/null || true
    rm -rf "$DIAG_DIR/wic-diag" "$DIAG_DIR/census" "$DIAG_DIR"/burst* "$DIAG_DIR"/burst2* 2>/dev/null || true
    if convert -size 96x96 gradient:red-blue "$DIAG_DIR/diag-96.png" 2>/dev/null; then
        reap_orphans "WIC 诊断趟前"
        echo "== 4.95 D-d 的 WIC 路径诊断趟（--wic-image + WPF_LINUX_CWIC_TRACE=1）"
        #   `WPF_LINUX_CWIC_TRACE=1` 是**托管侧** materialize 台账；`WPF_LINUX_WIC_TRACE=1` 是
        #   **原生 WIC shim**（build/DirectWrite.Linux/wic-shim/wic_proxy.c）的台账 ——
        #   D-d 的 `prc=`/`COPY_PIXELS_SUBRECT`/`COPY_PIXELS_REFUSE` 只在后者里有。
        ( cd "$DIAG_DIR" && env WPF_LINUX_CWIC_TRACE=1 WPF_LINUX_WIC_TRACE=1 WPF_LINUX_MIL_TRACE=1 DISPLAY="$DISPLAY" \
              timeout 60 dotnet WpfTextDemo.dll "--wic-image=$DIAG_DIR/diag-96.png" > "$DIAG_DIR/app.log" 2>&1 )
        # 注意：**不要用 `grep -oE '\[cwic-trace\][^\n]*'`** —— `[^\n]` 在 grep 里不是"非换行"，
        #   实测会把行截断成 `[cwic-trace] source=0x2 ow`（读数被截肢）。直接整行取。
        CWIC_TRACE_ALL="$(grep -E '\[cwic-trace\]' "$DIAG_DIR/app.log" 2>/dev/null | head -3)"
        CWIC_SRC="$(grep -oE 'WPTD_IMAGE_SOURCE=[^ ]+' "$DIAG_DIR/app.log" 2>/dev/null | head -1)"
        # 原生 shim 台账：期望 `COPY_PIXELS … prc=(0,0,96,96)` / `COPY_PIXELS_SUBRECT prc=(0,0,1,1)`，
        #   **且不再出现 COPY_PIXELS_REFUSE**（修复前是 reason=invalid-rect）。
        WIC_TRACE_ALL="$(grep -aE 'WIC_TRACE (COPY_PIXELS|COPY_PIXELS_SUBRECT|COPY_PIXELS_REFUSE)' "$DIAG_DIR/app.log" 2>/dev/null | head -4)"
        WIC_REFUSE_N="$(grep -ac 'COPY_PIXELS_REFUSE' "$DIAG_DIR/app.log" 2>/dev/null || echo 0)"
        if [ -n "${WIC_TRACE_ALL:-}" ]; then
            echo "   WIC 原生台账（期望 prc=(0,0,96,96) 且 REFUSE=0）："
            printf '%s\n' "$WIC_TRACE_ALL" | sed 's/^/      /'
            echo "   COPY_PIXELS_REFUSE 行数 = ${WIC_REFUSE_N:-?}（修复前 >0；现在期望 0）"
        fi
        if [ -n "${CWIC_TRACE_ALL:-}" ]; then
            printf '%s\n' "$CWIC_TRACE_ALL" | sed 's/^/   /'
            echo "   $CWIC_SRC"
        else
            echo "   ⚠️ WIC 路径诊断趟没拿到 [cwic-trace]（记 NA，不当作通过）；日志 $DIAG_DIR/app.log"
        fi
    else
        echo "   ⚠️ 生成诊断用 PNG 失败 ⇒ 跳过 WIC 路径诊断趟（census=NA）"
    fi
    reap_orphans "WIC 诊断趟后"
fi

# ── 5. 总结（机读行给上层门禁用例解析）───────────────────────────────────────
echo
echo "== 5/5 总结"
if [ "$ACC_TOTAL" != "0" ]; then
    echo "   验收档（default/env，门禁结论只看这里）：$ACC_PASSED/$ACC_TOTAL 通过（失败：${ACC_FAILED:-无}）"
else
    echo "   验收档：本次未选（--tier $TIER 只跑诊断档）"
fi
if [ "$DIAG_TOTAL" != "0" ]; then
    echo "   诊断档（degraded/minimal，非验收）：$DIAG_PASSED/$DIAG_TOTAL 通过（失败：${DIAG_FAILED:-无}）"
    echo "   ⚠️ 诊断档通过 ≠ 默认配置可用：它们关掉了已知阻塞特性 / 换成了最小可视树"
fi
# ── 跨档读数对比（最小判据：**只陈述事实**）──────────────────────────────────
#   验收两档**只差字体 env**（default = 清空全部 WPF_LINUX_*/HLWPF_*；env = 加字体覆盖）。
#   所以"指令数是否相同"本身就是信息：不同 ⇒ **字体确实影响了绘制指令数**
#   （可能是折行数不同、某段被裁掉、或字形 run 数不同）。
#   ⚠️ **不写成"因为字体不同所以不同"** —— 那是同义反复，不是归因。这里只报数。
if [ -s "$OUT/tier-readings.txt" ]; then
    echo
    echo "   == 逐次读数（tier|rep|drawn|notdrawn|colors|有效帧|达标帧）—— 原始台账"
    sed 's/^/     /' "$OUT/tier-readings.txt"
    _d_default="$(awk -F'|' '$1=="default" && $3!="NA"{print $3}' "$OUT/tier-readings.txt" | sort -u | tr '\n' ',' | sed 's/,$//')"
    _d_env="$(awk -F'|' '$1=="env" && $3!="NA"{print $3}' "$OUT/tier-readings.txt" | sort -u | tr '\n' ',' | sed 's/,$//')"
    [ -n "$_d_default" ] || _d_default="NA"; [ -n "$_d_env" ] || _d_env="NA"
    echo "WPTD_READINGS_DRAWN default=[$_d_default] env=[$_d_env]"
    if [ "$_d_default" != "NA" ] && [ "$_d_env" != "NA" ]; then
        if [ "$_d_default" = "$_d_env" ]; then
            echo "   ⇒ 两档（只差字体 env）指令数**相同**（$_d_default）"
        else
            echo "   ⇒ 两档（**只差字体 env**）指令数**不同**：default=$_d_default vs env=$_d_env"
            echo "      **未归因**：只能确定"字体影响了绘制指令数"（折行数/裁剪/字形 run 数皆可能），"
            echo "      需文本车道判读；本 runner **不**给因果解释。"
        fi
    fi
fi

# ── 判据⑦ 行推进（"多行段落摞在同一基线"）────────────────────────────────────
#   【语义已被真实修法验证过】主控成对取证：① 卡同一段 5 行的 `devY` 由"**五个全等 175.486**"
#   变成"**175.486 / 192.462 / 209.438 / 226.414 / 243.390**"（增量 16.976 = 恰好一个行高）
#   ⇒ "同段多行的 origin_y 必须各不相同"这件事**不再是猜测**，可以落成判据。
#   【阈值怎么来的（用根治前后的实测定，不拍脑袋）】
#     根治前：`runs=131 distinct_origin_y=**6**`（131 个 run 挤在 6 个 Y 上）
#     根治后：`runs=131 distinct_origin_y=**12**`
#     ⇒ 阈值取 **10**（离"修前 6"有 4 的余量、离"修后 12"有 2 的余量）。
#   【口径】只在普查产出读数时判；普查 NA ⇒ 记 NA，**不当作通过、也不判红**（明确打印）。
LINE_ADVANCE_VERDICT="NA"; DISTINCT_OY="NA"; CENSUS_RUNS="NA"
MIN_DISTINCT_Y="${WPTD_MIN_DISTINCT_Y:-10}"
if [ -n "${ORIGIN_SUM_LINE:-}" ]; then
    DISTINCT_OY="$(printf '%s' "$ORIGIN_SUM_LINE" | grep -oE 'distinct_origin_y=[0-9]+' | cut -d= -f2)"
    CENSUS_RUNS="$(printf '%s' "$ORIGIN_SUM_LINE" | grep -oE 'runs=[0-9]+' | cut -d= -f2)"
    if [ -n "${DISTINCT_OY:-}" ]; then
        if [ "$DISTINCT_OY" -ge "$MIN_DISTINCT_Y" ]; then LINE_ADVANCE_VERDICT="PASS"; else LINE_ADVANCE_VERDICT="FAIL"; fi
        echo "   判据⑦ 行推进（多行段落是否各行独立）：distinct_origin_y=$DISTINCT_OY（阈值 $MIN_DISTINCT_Y，runs=$CENSUS_RUNS）→ $LINE_ADVANCE_VERDICT"
        echo "      依据：根治前实测 6 / 根治后实测 12；主控成对取证同段 5 行 devY 增量 = 1 个行高"
    fi
fi
echo "WPTD_LINE_ADVANCE=$LINE_ADVANCE_VERDICT distinct_origin_y=$DISTINCT_OY threshold=$MIN_DISTINCT_Y runs=$CENSUS_RUNS"

if [ -n "${WPTD_BASELINE_OUT:-}" ] && [ -n "${CENSUS_LINE:-}" ]; then
    echo "#   CENSUS(字形普查, 期望 id0≈0 / nonlatin>0 / maxid≈63151) $CENSUS_LINE rc=$CENSUS_RC" >> "$WPTD_BASELINE_OUT"
    echo "#   CWIC(诊断趟 WPF_LINUX_CWIC_TRACE=1, 期望 materialize尺寸=96x96 fmt=…c90f Bgra32) ${CWIC_TRACE:-NA} ${CWIC_TRACE_ALL:-NA}" >> "$WPTD_BASELINE_OUT"
    echo "#   WIC_NATIVE(诊断趟 WPF_LINUX_WIC_TRACE=1, 期望 prc=(0,0,96,96) 且 REFUSE=0) refuse=${WIC_REFUSE_N:-NA} ${WIC_TRACE_ALL:-NA}" >> "$WPTD_BASELINE_OUT"
    echo "#   CENSUS_ORPHANS ${CENSUS_ORPHANS_LINE:-NA}" >> "$WPTD_BASELINE_OUT"
    if [ -n "${CENSUS_ALL:-}" ]; then
        { echo "#   CENSUS_ALL（普查全量仪表行，前向兼容：新仪表自动入基线）";
          printf '%s\n' "$CENSUS_ALL" | sed 's/^/#     /'; } >> "$WPTD_BASELINE_OUT"
    else
        echo "#   CENSUS_ALL NA（普查未产出仪表行）" >> "$WPTD_BASELINE_OUT"
    fi
    echo "#   ORIGIN_Y(判据⑦ 行推进；阈值 $MIN_DISTINCT_Y；根治前=6 / 根治后=12) ${ORIGIN_SUM_LINE:-NA} verdict=$LINE_ADVANCE_VERDICT 取值频次:${ORIGIN_SAMPLE:-NA}" >> "$WPTD_BASELINE_OUT"
    echo "#   读图（保留格；普查/计数绿 ≠ 像素对 —— T1d 已登记这条预测假绿）：需人工/视觉复核 run_dir 下的 *-after.png" >> "$WPTD_BASELINE_OUT"
    echo "#   REAPED_ORPHANS total=$REAPED_TOTAL detail=${REAP_LOG:-none}（辅助趟漏下的孤儿；按精确 argv+ppid==1+PID 回收）" >> "$WPTD_BASELINE_OUT"
    # 桥→源 身份（主控 2026-09-14 新加位）：**写进机读行**，冻基线时可直接逐字抄。
    #   `yes` ⇒ 部署的 .so 不是当前源编出来的（例：#6 桥 22:24 发、T2b 22:37 改了 Rendering/**）⇒ 本趟读数作废。
    #   `NOINFO` ⇒ 无信息（`bridge-src-fp.txt` 缺失/解析不出），**不等于 no**。
    echo "#   BRIDGE_SRC_STALE(桥→源 身份；期望 no；yes=部署件不是当前源编的⇒本趟读数作废) ${BRIDGE_SRC_STALE:-NA} basis=${BRIDGE_SRC_STALE_BASIS:-NA} so_file_match=${BRIDGE_SO_FILE_MATCH:-NA}" >> "$WPTD_BASELINE_OUT"
fi
echo "   截图目录：$OUT"
ls -la "$OUT"/*.png 2>/dev/null | sed 's/^/     /'

TOTAL=$((ACC_TOTAL + DIAG_TOTAL)); PASSED=$((ACC_PASSED + DIAG_PASSED)); FAILED_TIERS="$ACC_FAILED$DIAG_FAILED"

if [ "$ACC_TOTAL" != "0" ]; then
    echo "   INCONCLUSIVE 档（仪器抓不到帧，**不是应用失败**，请重跑）：${ACC_INC:-无}"
    if [ "$ACC_PASSED" = "$ACC_TOTAL" ]; then
        echo "WPTD_SUMMARY=PASS tiers_passed=$ACC_PASSED/$ACC_TOTAL"
    elif [ -n "$ACC_FAILED" ]; then
        echo "WPTD_SUMMARY=FAIL tiers_passed=$ACC_PASSED/$ACC_TOTAL failed:${ACC_FAILED} inconclusive:${ACC_INC:-无}"
    else
        # 没有真红、也没有全过 ⇒ 仪器问题为主：**不要报成 FAIL**
        echo "WPTD_SUMMARY=INCONCLUSIVE tiers_passed=$ACC_PASSED/$ACC_TOTAL inconclusive:${ACC_INC}"
    fi
else
    echo "WPTD_SUMMARY=NOT_RUN（本次只跑了诊断档）"
fi

# 退出码 = 所有**被选中**档都通过才 0（诊断档失败也如实返回非零，便于脚本化）
# 总闸 = 验收档全过 **且** 判据⑦（行推进）不是 FAIL（NA 不算失败，但会显式打印）
GATE_RC=0
[ "$PASSED" = "$TOTAL" ] || GATE_RC=1
[ "$LINE_ADVANCE_VERDICT" = "FAIL" ] && GATE_RC=1
echo "WPTD_GATE=$( [ "$GATE_RC" = "0" ] && echo PASS || echo FAIL ) acceptance=$PASSED/$TOTAL line_advance=$LINE_ADVANCE_VERDICT"
# 桥→源 身份：**跟门禁结论并排打印**（冻基线时要逐字抄它；缺失时是 NOINFO 而不是 no）
echo "WPTD_BRIDGE_SRC_STALE=${BRIDGE_SRC_STALE:-NA} basis=${BRIDGE_SRC_STALE_BASIS:-NA} so_file_match=${BRIDGE_SO_FILE_MATCH:-NA}"
if [ "$GATE_RC" = "0" ]; then
    exit 0
else
    [ "$PASSED" = "$TOTAL" ] || echo "WPTD_ALL_TIERS=FAIL passed=$PASSED/$TOTAL failed:${FAILED_TIERS}"
    exit 1
fi
