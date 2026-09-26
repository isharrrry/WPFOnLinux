#!/usr/bin/env bash
# T1c · 字形普查 / 字体诊断的**可注入 env** 复跑装置（只读被测产物，不改任何别人的文件）
# ============================================================================
# 为什么要有它：官方 runner `run-wpftextdemo.sh` 的默认档会**清空所有 WPF_LINUX_* 变量**
#   （那是它的判据要求），所以诊断开关（WPF_LINUX_GLYPH_CENSUS 等）**传不进去**。
#   本装置**不改 runner**，而是**自己装配一份运行目录**（与 runner 的 2/2a-2d 步逐条同源），
#   然后**从那里起同一个应用**并把诊断 env 传进去 —— 用的仍是**部署件**。
#
#   ⚠️ 被测产物一律取自**权威产物**（build/*.Linux/bin/Debug、build/DirectWrite.Linux/Provider、
#      src/WpfGfx.Linux.Native/bin、MilBridge 发布目录），不取样例 bin 里的快照 ——
#      与 runner 的 2a/2b/2c/2d 同一套来源，并把每个 sha 打进读数（"产物混用"是本项目的旧伤）。
#
# 用法：
#   bash build/MilBridge/tools/t1c-census.sh <outdir> <tier> [ENV=VAL ...]
#     tier = default（不设字体 env，系统字体目录 /usr/share/fonts）
#          | env    （复刻 M2 验收件：WPF_LINUX_FONT_DIR=build/fonts-ui + WPF_LINUX_UI_FONT=<族名>）
#   额外 ENV=VAL 会原样传给被测进程（例如 WPF_LINUX_COVERAGE_FALLBACK=1）
#   特殊：PC_OVERRIDE=<dll 路径> 用**别的** PresentationCore.dll 覆盖运行目录里的那一份
#         （用于"补丁后但未重建主产物"的波前 A/B；绝不写回 build/PresentationCore.Linux/bin）
#         HOLD_SECONDS=<n>（默认 18）应用存活时长
#         WPTD_DISPLAY=<:98>（默认 :98，**只用 :98**）
#
#   ── R1（多字体整形）复测用的三件（**装置自己的选项，不会被当成应用 env**）──────────────
#   T1C_AB_BASE=<上一轮的 readings.txt>   打差值对照（基线挂 `id0=325/nonlatin=0` 那一份）
#   T1C_AB_PIXELS=<上一轮的 shot-1.png>   像素对照 `compare -metric AE`（**不要用 PNG 文件 sha 判像素**）
#   T1C_FORWARD_KEYS=<正则>               转发新仪器键（默认 HBFACE|HBFALLBACK|FACE_|SEGMENT|MULTIFONT|…）
#                                        ⇒ R1 在 shim 里新加的读数**不用改本脚本**就会出现
#   机读汇总（由 `t1c-census-summary.py` 产出，可被断言）：
#     T1C_CENSUS_SUMMARY frame=N runs=.. glyphs=.. id0=.. nonlatin=.. maxid=..   ← 权威数（整帧）
#     T1C_CENSUS_SHAPE   detail_runs=..(of frame runs=..) pids=[0x..(Nruns/Ng/id0=..),…]  ← 形态数（几份面）
#     T1C_CENSUS_EMPTY   ← **空帧**：`id0=0/nonlatin=0` 是空真，不能当"没有豆腐块"（rc=3）
# ============================================================================
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"   # 波 `#77` 旧路径重指向：由仓根现推
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

OUTDIR="${1:?用法: t1c-census.sh <outdir> <tier> [ENV=VAL ...]}"
TIER="${2:?用法: t1c-census.sh <outdir> <tier> [ENV=VAL ...]}"
shift 2 || true

PC_OVERRIDE=""
HOLD_SECONDS="${HOLD_SECONDS:-18}"
DISPLAY_NUM="${WPTD_DISPLAY:-:98}"
EXTRA_ENV=()
# ⚠️ 注意：`T1C_*` 是本装置**自己**的选项（A/B 对照、转发正则），**不要**当成"传给被测应用的 env" ——
#    踩过一次：`T1C_AB_BASE=…` 被塞进应用环境 ⇒ 装置自己看不见它 ⇒ A/B 那两行**静默不出现**
#    （"仪器悄悄不工作"那一族）。这里显式区分。
T1C_AB_BASE_OPT="${T1C_AB_BASE:-}"
T1C_AB_PIXELS_OPT="${T1C_AB_PIXELS:-}"
T1C_FORWARD_KEYS_OPT="${T1C_FORWARD_KEYS:-}"
for a in "$@"; do
    case "$a" in
        PC_OVERRIDE=*) PC_OVERRIDE="${a#PC_OVERRIDE=}" ;;
        HOLD_SECONDS=*) HOLD_SECONDS="${a#HOLD_SECONDS=}" ;;
        WPTD_DISPLAY=*) DISPLAY_NUM="${a#WPTD_DISPLAY=}" ;;
        T1C_AB_BASE=*)  T1C_AB_BASE_OPT="${a#T1C_AB_BASE=}" ;;
        T1C_AB_PIXELS=*) T1C_AB_PIXELS_OPT="${a#T1C_AB_PIXELS=}" ;;
        T1C_FORWARD_KEYS=*) T1C_FORWARD_KEYS_OPT="${a#T1C_FORWARD_KEYS=}" ;;
        *) EXTRA_ENV+=("$a") ;;
    esac
done

mkdir -p "$OUTDIR"
RUN="$OUTDIR/run"
SRC="$ROOT/samples/WpfTextDemo/bin/Debug/net10.0"
FONT_FILE="$ROOT/build/fonts-ui/UI-NoLayout.ttf"
LOG="$OUTDIR/app.log"
READ="$OUTDIR/readings.txt"

[ -d "$SRC" ] || { echo "❌ 找不到 $SRC —— 先 dotnet build samples/WpfTextDemo" >&2; exit 2; }

echo "== [1/4] 装配运行目录 $RUN"
rm -rf "$RUN"; mkdir -p "$RUN"
cp -r "$SRC"/. "$RUN"/

# 2a) 自产程序集刷新成**权威产物**（只取与目录同名的那一件）
for d in "$ROOT"/build/*.Linux/bin/Debug/*.dll; do
    [ -f "$d" ] || continue
    proj="$(basename "$(dirname "$(dirname "$(dirname "$d")")")")"
    case "$proj" in CycleStub.*) continue ;; esac
    [ "$(basename "$d" .dll)" = "${proj%.Linux}" ] || continue
    cp -f "$d" "$RUN"/ 2>/dev/null
done
# 2b) provider
PROVIDER="$ROOT/build/DirectWrite.Linux/Provider/bin/Debug/DirectWrite.Linux.Provider.dll"
[ -f "$PROVIDER" ] && cp -f "$PROVIDER" "$RUN"/ || echo "   ⚠️ 找不到 provider（PC 会 FileNotFoundException）"
# 2c) win32 shim + 别名
SHIM="$ROOT/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
if [ -f "$SHIM" ]; then
    cp -f "$SHIM" "$RUN"/
    for alias in uxtheme.dll wtsapi32.dll shell32.dll PresentationNative_cor3.dll; do
        cp -f "$SHIM" "$RUN/$alias"
    done
else
    echo "   ⚠️ 找不到 $SHIM"
fi
# 2d) MilBridge AOT 发布目录（整个目录一起放）
MILDIR="$(dirname "$(find "$ROOT/build/MilBridge/.artifacts" -name 'wpfgfx_cor3.so' 2>/dev/null | head -1)" 2>/dev/null)"
if [ -n "$MILDIR" ] && [ -d "$MILDIR" ]; then
    for so in "$MILDIR"/*.so; do [ -f "$so" ] && cp -f "$so" "$RUN"/; done
else
    echo "   ⚠️ 找不到 wpfgfx_cor3.so"
fi

# PC 覆盖（波前 A/B：用 /tmp 里编出来的那一份；**不写回任何权威产物**）
if [ -n "$PC_OVERRIDE" ]; then
    [ -f "$PC_OVERRIDE" ] || { echo "❌ PC_OVERRIDE 不存在：$PC_OVERRIDE" >&2; exit 2; }
    # 同目录的 pdb 一起带过去（栈里能看到行号；不带也无妨）
    cp -f "$PC_OVERRIDE" "$RUN/PresentationCore.dll"
    [ -f "${PC_OVERRIDE%.dll}.pdb" ] && cp -f "${PC_OVERRIDE%.dll}.pdb" "$RUN/PresentationCore.pdb"
    echo "   PC 覆盖 = $PC_OVERRIDE（sha $(sha256sum "$PC_OVERRIDE" | cut -c1-16)）"
fi

# ── 档位 env ────────────────────────────────────────────────────────────────
TIER_ENV=()
case "$TIER" in
    default) TIER_ENV=() ;;
    env)
        [ -f "$FONT_FILE" ] || { echo "❌ 缺 $FONT_FILE" >&2; exit 4; }
        FAM="$(fc-scan --format '%{family}\n' "$FONT_FILE" 2>/dev/null | head -1 | cut -d, -f1)"
        TIER_ENV=(WPF_LINUX_FONT_DIR="$(cd "$(dirname "$FONT_FILE")" && pwd)" WPF_LINUX_UI_FONT="$FAM")
        ;;
    *) echo "❌ tier 只认 default|env（收到 '$TIER'）" >&2; exit 2 ;;
esac

# ══════════════════════════════════════════════════════════════════════════════════════
#  孤儿进程：**本装置自己那一族**（T3 抓到：每跑一次漏一个 ~2 GB 的孤儿应用）
# ══════════════════════════════════════════════════════════════════════════════════════
#  根因（T3 的归因，我复现一致）：`( cd … && … dotnet … ) &` 里 **`$!` 是子 shell 的 PID**，
#     `kill $!` 只杀掉子 shell ⇒ `dotnet` 被 reparent 到 1 并带着 ~2 GB RSS 留下来。
#  修法：起应用时用 **`exec`**（子 shell 被 dotnet 取代 ⇒ `$!` 就是 dotnet）；收尾 kill+wait 那个 PID；
#     并**前后各数一次**孤儿、把 `CENSUS_ORPHANS before=… after=…` 作为固定输出行（有残留就报出来，不静默）。
#  ⚠️ 判据**故意收窄**，免得误伤别人活着的应用（那些有父进程 ⇒ ppid≠1）：
#      ppid==1 ∧ basename(argv[0])=='dotnet' ∧ argv[1]=='WpfTextDemo.dll' ∧ cwd 以 /tmp/t1c 开头
#    绝不用 pkill/pgrep（本工程已因它误伤过旁观者），也绝不写"要匹配的进程名字面量"。
list_app_orphans() {
    python3 /dev/stdin <<'PYORPHAN'
import glob, os
rows = []
for d in glob.glob('/proc/[0-9]*'):
    pid = os.path.basename(d)
    try:
        with open(d + '/stat', 'rb') as f:
            stat = f.read().decode('utf-8', 'replace')
        ppid = int(stat[stat.rfind(')') + 2:].split()[1])
        if ppid != 1:
            continue
        with open(d + '/cmdline', 'rb') as f:
            argv = [a.decode('utf-8', 'replace') for a in f.read().split(b'\0') if a]
        if len(argv) < 2 or os.path.basename(argv[0]) != 'dotnet' or argv[1] != 'WpfTextDemo.dll':
            continue
        cwd = os.readlink(d + '/cwd')
        if not cwd.startswith('/tmp/t1c'):
            continue
        rss = 0
        try:
            with open(d + '/statm') as f:
                rss = int(f.read().split()[1]) * 4096
        except Exception:
            pass
        rows.append((int(pid), rss, cwd, ' '.join(argv)))
    except Exception:
        continue
for pid, rss, cwd, cmd in sorted(rows):
    print("%d rss=%dMB cwd=%s cmd=%s" % (pid, rss // 1048576, cwd, cmd))
PYORPHAN
}

# ── X server（复用；否则自己起，记 PID，**绝不 pkill -f**）────────────────────
XPID=""
if ! xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1; then
    # ⚠️ 这里**不用** `setsid`：`setsid` 可能 fork ⇒ `$!` 就不是 Xvfb 本身 ⇒ 按 PID 收尾会漏。
    #   直接后台起（stdin 接 /dev/null、输出重定向 ⇒ 不依赖控制终端），并**校验 PID 的 cmdline**。
    Xvfb "$DISPLAY_NUM" -screen 0 1280x1024x24 -nolisten tcp >"$OUTDIR/xvfb.log" 2>&1 </dev/null &
    XPID=$!
    _xcmd="$(tr '\0' ' ' < "/proc/$XPID/cmdline" 2>/dev/null || true)"
    case "$_xcmd" in *Xvfb*) : ;; *) echo "⚠️ 自起的 Xvfb：/proc/$XPID/cmdline 不像 Xvfb（$_xcmd）⇒ 收尾可能不准" >&2 ;; esac
    for _ in $(seq 1 40); do
        xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 && break
        kill -0 "$XPID" 2>/dev/null || { echo "❌ Xvfb 起不来，见 $OUTDIR/xvfb.log" >&2; exit 2; }
        sleep 0.25
    done
    sleep 0.6
fi
export DISPLAY="$DISPLAY_NUM"
xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 || { echo "❌ $DISPLAY_NUM 不可用" >&2; exit 2; }

cleanup() {
    [ "${BASHPID:-$$}" = "$$" ] || return 0
    if [ -n "$XPID" ] && kill -0 "$XPID" 2>/dev/null; then kill "$XPID" 2>/dev/null; fi
}
trap cleanup EXIT
# `timeout` 发 SIGTERM 时 **EXIT trap 不会跑** ⇒ 显式接住，免得自起的 Xvfb 变孤儿
trap 'cleanup; exit 143' TERM INT

echo "== [2/4] 产物 sha（读数必须带它们，否则无法与别人的结果对齐）"
{
    echo "== T1c census 装置 · tier=$TIER · DISPLAY=$DISPLAY_NUM · $(date -Iseconds)"
    for f in PresentationCore.dll PresentationFramework.dll DirectWrite.Linux.Provider.dll \
             libwpfwin32.so wpfgfx_cor3.so; do
        if [ -f "$RUN/$f" ]; then
            printf 'ARTIFACT %-34s sha256=%s bytes=%s\n' "$f" "$(sha256sum "$RUN/$f" | cut -d' ' -f1)" "$(stat -c%s "$RUN/$f")"
        else
            printf 'ARTIFACT %-34s MISSING\n' "$f"
        fi
    done
    printf 'ARTIFACT %-34s sha256=%s\n' "UI-NoLayout.ttf" "$(sha256sum "$FONT_FILE" | cut -d' ' -f1)"
    printf 'ARTIFACT %-34s sha256=%s\n' "FamilyCoverage.Linux.cs(生成物)" "$(sha256sum "$ROOT/build/PresentationCore.Linux/FamilyCollection.Linux.cs" | cut -d' ' -f1)"
    printf 'ENV %s\n' "tier=$TIER ${TIER_ENV[*]:-} ${EXTRA_ENV[*]:-}"
} | tee "$READ"

echo "== [3/4] 启动应用（env 注入诊断开关）"
: > "$LOG"

ORPHANS_BEFORE="$(list_app_orphans | wc -l)"
if [ "$ORPHANS_BEFORE" != "0" ]; then
    echo "   ⚠️ 跑前已存在 $ORPHANS_BEFORE 个本装置孤儿（上一次跑漏下的）："
    list_app_orphans | sed 's/^/      /'
fi

# ★ `exec`：子 shell 被 `env`→`dotnet` 取代 ⇒ **`$!` 就是应用进程**（收尾 kill/wait 才杀得掉）
( cd "$RUN" && exec env -u WPF_LINUX_GLYPH_CENSUS -u WPF_LINUX_FONT_DIAG \
      WPF_WIN32_MSG_TRACE=1 WPF_LINUX_MIL_TRACE=1 \
      "${TIER_ENV[@]}" "${EXTRA_ENV[@]}" \
      dotnet WpfTextDemo.dll > "$LOG" 2>&1 ) &
APP_PID=$!

# 装置自证：`$!` 必须真的是那个应用（否则"按 PID 收尾"就是假的 —— T3 抓到的正是这个）
sleep 0.5
APP_CMDLINE="$(tr '\0' ' ' < "/proc/$APP_PID/cmdline" 2>/dev/null || true)"
case "$APP_CMDLINE" in
    *WpfTextDemo.dll*) echo "   [自证] APP_PID=$APP_PID 的 cmdline 含 WpfTextDemo.dll ✓（\$! 就是应用，不是子 shell）" ;;
    *) echo "   ❌ [自证失败] APP_PID=$APP_PID 的 cmdline=「$APP_CMDLINE」不含 WpfTextDemo.dll ⇒ 收尾会漏进程" >&2 ;;
esac

# 等首绘信号（台账里出现 skia 指令 N>0），最多 HOLD_SECONDS
waited=0
while [ "$waited" -lt "$HOLD_SECONDS" ]; do
    kill -0 "$APP_PID" 2>/dev/null || break
    grep -qaE "skia 指令 [1-9][0-9]* 条" "$LOG" 2>/dev/null && { sleep 2; break; }
    sleep 0.5; waited=$((waited+1))
done

# 抓屏（root 连拍 + 取最佳帧；单色帧=无效帧，只计数）
SHOTS=0; BEST=""; BESTCOLORS=0
WIN="$(xwininfo -root -tree 2>/dev/null | grep -aF 'WpfTextDemo' | grep -oE '0x[0-9a-f]+' | head -1)"
for i in 1 2 3 4 5 6; do
    kill -0 "$APP_PID" 2>/dev/null || break
    if [ -n "$WIN" ]; then
        if xwd -id "$WIN" -display "$DISPLAY_NUM" -silent -out "$OUTDIR/shot-$i.xwd" 2>/dev/null; then
            if convert "$OUTDIR/shot-$i.xwd" "$OUTDIR/shot-$i.png" 2>/dev/null; then
                SHOTS=$((SHOTS+1))
                nc="$(convert "$OUTDIR/shot-$i.png" -format '%k' info: 2>/dev/null)"
                nc="${nc:-0}"
                if [ "$nc" -gt "$BESTCOLORS" ]; then BESTCOLORS="$nc"; BEST="$OUTDIR/shot-$i.png"; fi
            fi
        fi
    fi
    sleep 0.4
done
echo "SHOT frames=$SHOTS best_colors=$BESTCOLORS best=$BEST win=$WIN" | tee -a "$READ"

# 收尾：SIGTERM（退出码经文件取，**绝不**写在管道后）
kill -TERM "$APP_PID" 2>/dev/null
wait "$APP_PID"; RC=$?
echo "APP_EXIT rc=$RC" | tee -a "$READ"

# ── 孤儿断言（固定输出行；有残留就报出来并让装置退出码非 0，**不静默**）──────────────
#   为什么必须有这一步：`kill $!` 到底杀没杀掉**真正那个应用**，光看 rc 是看不出来的
#   —— 旧版 `$!` 指向子 shell 时，rc 照样正常、日志照样完整，而 2 GB 的 dotnet 留在 ppid==1。
sleep 0.5
ORPHANS_AFTER_LIST="$(list_app_orphans)"
ORPHANS_AFTER="$(printf '%s' "$ORPHANS_AFTER_LIST" | grep -c . || true)"
echo "CENSUS_ORPHANS before=$ORPHANS_BEFORE after=$ORPHANS_AFTER" | tee -a "$READ"
LEFT=0
if [ "$ORPHANS_AFTER" != "0" ]; then
    echo "❌ 收尾后有 $ORPHANS_AFTER 个本装置孤儿（按 PID 收尾没杀掉真正的应用）：" | tee -a "$READ"
    printf '%s\n' "$ORPHANS_AFTER_LIST" | sed 's/^/   /' | tee -a "$READ"
    LEFT=1
fi

echo "== [4/4] 读数（原样；判定留给人看）"
{
    echo "---- GLYPH_CENSUS / 字体诊断 / 行诊断 ----"
    grep -aE "GLYPH_CENSUS|FONT_DIAG|HB_TEXTLINE|未画种类|skia 指令|COVERAGE|COVERAGE_FALLBACK" "$LOG" 2>/dev/null | head -80
    echo "---- 应用 stdout/stderr 尾部 ----"
    tail -5 "$LOG" 2>/dev/null
} | tee -a "$READ"

# ══════════════════════════════════════════════════════════════════════════════════════
#  [4b] T1c/R1 复测列 —— **多字体整形**（"每个 run 用了几份面 / 哪几段落到回退面"）
# ══════════════════════════════════════════════════════════════════════════════════════
#  为什么加这一段：R1（shim 按 run 取字体 + 按码点覆盖回退）落地后要复测的**判据只有一个** ——
#  `id0` 降下来、`id≥0x1000` 出现、拉丁不退步；而"它到底用了几份面/哪几段回退了"只有把
#  **每条 run 明细按面聚合**才答得上。本段**只做聚合与转发**：
#   ① 聚合现有 `[GLYPH_CENSUS]` 的**逐 run** 行（数 id0 / 非拉丁 / 面 pid），不打机读行的新字段猜测；
#   ② **转发**任何新仪器键（`T1C_FORWARD_KEYS` 可覆盖正则）⇒ R1 在 shim 里新加的读数**不用改本脚本**就能出现；
#   ③ 打一行机读汇总 `T1C_CENSUS_SUMMARY …`（主控/T1b 可直接断言）；
#   ④ `T1C_AB_BASE=<上一轮的 readings.txt>` ⇒ 打**差值**（这就是 "id0 325→~0" 那条对照）。
FORWARD_KEYS="${T1C_FORWARD_KEYS_OPT:-HBFACE|HBFALLBACK|FACE_|SEGMENT|MULTIFONT|SHAPE_FACE|GLYPH_FACE|RUN_FACE}"
SUMMARY="$(python3 "$(dirname "${BASH_SOURCE[0]}")/t1c-census-summary.py" "$LOG" 2>/dev/null || true)"
if [ -n "$SUMMARY" ]; then
    {
        echo "---- [4b] R1 复测列（多字体整形：几份面 / 哪几段回退）----"
        echo "$SUMMARY"
        echo "---- [4b] 新仪器键转发（正则 $FORWARD_KEYS；R1 在 shim 里加读数**不用改本脚本**）----"
        grep -aE "$FORWARD_KEYS" "$LOG" 2>/dev/null | head -20
        if [ -n "$T1C_AB_BASE_OPT" ] && [ -f "$T1C_AB_BASE_OPT" ]; then
            base_line="$(grep -a 'T1C_CENSUS_SUMMARY' "$T1C_AB_BASE_OPT" 2>/dev/null | tail -1)"
            if [ -n "$base_line" ]; then
                echo "T1C_AB_BASE $(basename "$T1C_AB_BASE_OPT"): $base_line"
            else
                echo "T1C_AB_BASE $(basename "$T1C_AB_BASE_OPT"): <基线文件里**没有** T1C_CENSUS_SUMMARY 行 ⇒ 无差值可算>"
            fi
            echo "T1C_AB_NOW : $(printf '%s' "$SUMMARY" | grep -a 'T1C_CENSUS_SUMMARY')"
            echo "（**人读**差值：id0 应下降、非拉丁应上升；runs/glyphs 不应无故大变 —— 后两条是"拉丁不退步"的护栏）"
        fi
    } | tee -a "$READ"
fi

# 截图色数直方图（用途：A/B 像素比较；不是"读图"的替代）
if [ -n "$BEST" ]; then
    convert "$BEST" -format 'PNG %wx%h colors=%k\n' info: 2>/dev/null | tee -a "$READ"
fi

# 像素级 A/B（**不要用 PNG 文件 sha 判像素** —— 容器元数据会让它不同而像素相同）：
#   T1C_AB_PIXELS=<另一轮的 PNG> ⇒ compare -metric AE（0 = 逐像素相同）
if [ -n "$T1C_AB_PIXELS_OPT" ] && [ -n "$BEST" ] && [ -f "$T1C_AB_PIXELS_OPT" ]; then
    ae="$(compare -metric AE "$BEST" "$T1C_AB_PIXELS_OPT" null: 2>&1 || true)"
    echo "T1C_AB_PIXELS AE=$ae（0 = 逐像素相同；PNG 文件 sha 不同**不代表**像素不同）" | tee -a "$READ"
fi
echo "→ 读数文件 $READ ；日志 $LOG"
if [ "$LEFT" != "0" ]; then
    echo "→ 装置退出码 1（**收尾后有孤儿**：见上面的 CENSUS_ORPHANS / 残留列表）"
    exit 1
fi
echo "→ 装置退出码 0（CENSUS_ORPHANS before=$ORPHANS_BEFORE after=$ORPHANS_AFTER；自起 Xvfb=${XPID:-无}）"
