#!/usr/bin/env bash
# 主控 · 波 `#23` 五臂重取（世代成本 —— shim 变了就必须重取）。
# 依据：`build/MilBridge/arm-logs/README.md` 的"新世代怎么重绿"。
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"   # 波 `#77` 旧路径重指向：由仓根现推
# ★ `#39` 阶段 2/3：本脚本读的权威件路径跟随**唯一声明**。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../../build/selfbuilt-config.sh"
cd "$ROOT" || exit 2
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

OUT="${ARMS_OUT:-$HOME/wfp-runs/arms23}"
mkdir -p "$OUT"
# ── `#31` W31E 加：`OUT` 改为 env 可覆写（`ARMS_OUT`）＋ 硬链接别名守卫 ────────────────────
#   ⚠️ 本块的插入位置**刻意放在 `OUT=`/`mkdir -p` 之后**：那两行在原件里是 **11/12 行**，
#      全仓有 4 处外部引用锚在 `retake-arms-w23.sh:11`（`ACCEPTANCE-BASELINE.md` 纪律 59、
#      `docs/CURRENT-STATE.md:89`/`:661`、`handoff.md:2917`），而那几件**不在本车道写域**
#      ⇒ 把插入点后移，让 `:11` 这个锚**继续成立**（只是它描述的状态变了，见 `known-red.json` 的加注）。
#      代价：第 1–6 步的行号整体 **+36**（实测：`:21`→`:57`、`:47`→`:83`、`:59`→`:95`；
#      `known-red.json:62` 的 `:21-40` → `:57-76`，同趟加注）。
#
#   ① `ARMS_OUT`：纪律 59「重取臂前**必须**换 `OUT` 并先归档」的第①步原先只能**手改脚本第 11 行**
#      （`known-red.json:111` 逐字记着上次是手工换成 `$HOME/w30b-run/arms30b`）⇒ 一次性、不可复算。
#      改成 env 可覆写后，第①步是一条可复算的命令。**语义零变化**：不设 `ARMS_OUT` 时 `OUT` 逐字仍是
#      `$HOME/wfp-runs/arms23`（`ARMS_OUT=` 空串也走默认，因为用了 `:-`）。
#   ② 守卫：本脚本第 1–4 步全用 `> "$OUT/<臂>.log"` **重定向**写日志 ⇒ 若该路径与
#      `build/MilBridge/arm-logs/<臂>.log` **同 inode**（`$OUT` 是一份硬链接别名目录），
#      `>` 会**顺着共享 inode 就地截断归档源件**（`#27` 的事故形态；`#30` W30B 为此手工换过 `OUT`）。
#      `#31` W31C 清掉了 11 条别名、把 `$HOME/wfp-runs/arms23` 改成**真副本**（`cmp` IDENTICAL、mtime 保留）
#      —— 但那只清了**当前实例**：第 5 步的 `ln -f` 会把 `$OUT` 与 `arm-logs/` **重新绑成同一 inode**
#      ⇒ **机制还在**，下一次按别名 `OUT` 重取照样会截断上一世代证据。故守卫做成仓库侧的件。
#   ⚠️ 射程（**刻意收窄**）：**只**在「本趟将要写的目标**已经**与真件同 inode」时拒跑；
#      `$OUT` 指向干净目录（真副本 / 空目录）⇒ **一律放行** —— 不许把正常重取判红。
#      判据 = `stat -c %i`（**跟随符号链接** ⇒ `$OUT` 经目录符号链接指到归档层同样被拦）。
#      **逐条点名全部冲突支**（不是遇到第一支就退出）⇒ 一次看清哪几支要处理。
#      退出码 `4` =「环境不安全、**一个字节都还没写**」（与 `:7` 的 `exit 2`（`cd` 失败）区分开）。
bad=0
for g in tline tab-zero tab-anchor tab-rtl textlineproto; do
    o="$OUT/$g.log"; a="build/MilBridge/arm-logs/$g.log"
    if [ -e "$o" ] && [ -e "$a" ] && [ "$(stat -c %i "$o")" = "$(stat -c %i "$a")" ]; then
        echo "!! 同 inode：$o  ==  $a  (inode=$(stat -c %i "$o"))"
        bad=$((bad+1))
    fi
done
if [ "$bad" -gt 0 ]; then
    echo "!! 拒跑（exit 4）：共 $bad 支的写入目标与 build/MilBridge/arm-logs/ 下的真件同 inode（纪律 59）"
    echo "!! ⇒ 本趟第 1–4 步会用 > 重定向写上面这些路径，顺着共享 inode 就地截断归档源件。"
    echo "!! ⇒ 请先归档旧件，再用 ARMS_OUT=<与 build/MilBridge/arm-logs/ 不同 inode 的目录> 重跑。"
    exit 4
fi
echo "=== arms re-take $(date '+%F %T') loadavg=$(cut -d' ' -f1-3 /proc/loadavg) ==="
echo "shim      = $(sha256sum build/shims/PresentationCore.HbTextLine.cs | cut -c1-16)"
echo "pc        = $(sha256sum build/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll | cut -c1-16)"
echo "run.sh    = $(sha256sum build/MilBridge/run.sh | cut -c1-16)"
echo "Parity.cs = $(sha256sum build/MilBridge/tests/HbTextLineParity/Program.cs | cut -c1-16)"

say() { echo "--- $* ---"; }

# ---- 0.5) 【`#49` 车道 W76A 加 · **`D-G77` 修法**】显示号**必须真的在**，否则**大声失败** ----------
#   【缺陷现场（本脚本自己的）】第 4 步（`:83`）**硬写 `DISPLAY=:97`**，而**全仓没有任何一步保证
#     `:97` 常驻**（闸门只在它自己那一趟里临时起一个、退出就收）⇒ 任何人在闸门之外重取臂，
#     都会**静默**拿到 **X-混淆**读数。实测（W76A，2026-09-21 15:37:58–15:43:38，`:97` DOWN 全程）：
#       · `textlineproto` 臂日志出现 **2 条** `XOpenDisplay(":97") 失败` ＋ `[WIN_DIAG] CreateWindowEx 失败`
#         ＋ `[SHIM_DIAG] HwndWrapper 建窗失败`；`P4（new DrawingVisual().RenderOpen() 在纯 PC 下可用）`
#         由 **PASS 翻 FAIL**；`探针：通过 4 / 失败 2` → **`通过 3 / 失败 3`**；
#         该臂 sha 由 `4bceceeed570ba70` 变 `c1a5cf0a72bbd12d` —— **那不是产品位移**。
#       · 另四臂 `grep -c XOpenDisplay` = **0**（未混淆），但**这条洞对它们同样成立**：只是恰好没踩到。
#     同族既有缺陷：`D-G59`（显示号选定后整趟不复核）、`D-G48`（无显示时兜底链必抛）。
#   【修法（在"自起"与"大声失败"里选**两条都做**）】`:97` 不在 ⇒ **自己起一个 Xvfb** 并记 PID，
#     跑完**按 PID 收回自己起的那个**；**起不来 ⇒ `exit 5` 大声失败**，绝不带着"没有 X"往下跑。
#     选"自起"而不是"直接失败"的理由：本脚本是收尾链的一步，**没有人的机器上也要能跑**；
#     而"起不来"这一支留成硬失败，保证**永远不会有第二种"静默无 X"的形态**。
#   ⚠️ 保证的显示号**就是**第 4 步用的那个（`:97`，写死在那行里 ⇒ 本块**只保证 `:97`**，不引入第二个
#      可配的显示号 —— 两个显示号就又多一处"同一真相两处"）。
#   ⚠️ `ARMS_XVFB_BIN`（默认 `Xvfb`）是本脚本的**参数**（与 `ARMS_OUT` 同形），供反极性自测把
#      "起不来"那一支真的走到；**不设它时行为与修前逐字相同**（复用已存在的 `:97`）。
ARMS_X_DISPLAY=":97"
ARMS_XVFB_BIN="${ARMS_XVFB_BIN:-Xvfb}"
ARMS_XVFB_PID=""
cleanup_xvfb() { if [ -n "$ARMS_XVFB_PID" ]; then kill "$ARMS_XVFB_PID" 2>/dev/null; fi; return 0; }
if xdpyinfo -display "$ARMS_X_DISPLAY" >/dev/null 2>&1; then
    echo "ARMS_DISPLAY=$ARMS_X_DISPLAY source=reused（已存在 ⇒ 直接复用，与修前同径）"
else
    echo "ARMS_DISPLAY=$ARMS_X_DISPLAY source=none ⇒ 自起 Xvfb（**修前的行为是：静默带着无 X 往下跑**）"
    if ! command -v "$ARMS_XVFB_BIN" >/dev/null 2>&1; then
        echo "ARMS_DISPLAY=FAIL reason=no-xvfb-bin display=$ARMS_X_DISPLAY bin=$ARMS_XVFB_BIN"
        echo "!! 拒跑（exit 5）：没有 X 就**拿不到有效臂读数**（D-G77 现场：X-混淆会静默改写臂 sha）⇒ 不许继续"
        exit 5
    fi
    "$ARMS_XVFB_BIN" "$ARMS_X_DISPLAY" -screen 0 1280x1024x24 >"$OUT/xvfb.log" 2>&1 &
    ARMS_XVFB_PID=$!
    _ok=0
    for _ in $(seq 1 40); do
        xdpyinfo -display "$ARMS_X_DISPLAY" >/dev/null 2>&1 && { _ok=1; break; }
        sleep 0.25
    done
    if [ "$_ok" != 1 ]; then
        echo "ARMS_DISPLAY=FAIL reason=xvfb-not-ready display=$ARMS_X_DISPLAY pid=$ARMS_XVFB_PID（日志 $OUT/xvfb.log）"
        echo "!! 拒跑（exit 5）：同上 —— 无 X 的臂日志不是读数"
        kill "$ARMS_XVFB_PID" 2>/dev/null
        exit 5
    fi
    echo "ARMS_DISPLAY=$ARMS_X_DISPLAY source=self-started xvfb_pid=$ARMS_XVFB_PID（**跑完按 PID 收回**；只收自己起的这一个）"
    trap cleanup_xvfb EXIT
fi

# ---- 1) CoverageProbe（三支 tab 臂的宿主；它的 csproj 把真 shim 源编进去）----
say "rebuild CoverageProbe -c Release"
dotnet build build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj -c Release -m:1 --nologo -v q \
    > "$OUT/build-coverage.log" 2>&1
echo "CoverageProbe build rc=$?"

# ---- 2) 臂 1/5：tline（强配对；自带构建 HbTextLineParity + DirectBranchCheck）----
say "arm 1/5 tline"
timeout 3600 bash build/MilBridge/run.sh tline > "$OUT/tline.log" 2>&1
echo "tline rc=$?"

# ---- 3) 臂 2-4/5：三支 tab oracle ----
for arm in tab-zero tab-anchor tab-rtl; do
    say "arm $arm"
    ( cd build/MilBridge/tests/CoverageProbe/bin/Release && \
      timeout 3600 dotnet PresentationCore.Tests.dll \
        --tab-lines-oracle "$ROOT/tests/parity/windows/$arm/out/$arm-oracle.json" ) \
      > "$OUT/$arm.log" 2>&1
    echo "$arm rc=$?"
done

# ---- 4) 臂 5/5：textlineproto（**必须**有 DISPLAY，否则 ContractProbe 段缺 X 假红）----
say "arm 5/5 textlineproto"
DISPLAY=:97 timeout 3600 bash build/MilBridge/run.sh textline > "$OUT/textlineproto.log" 2>&1
echo "textlineproto rc=$?"

# ---- 5) 硬链接进 arm-logs（**绝不 cp**（顶 mtime ⇒ 架空弱配对判据）／**绝不 ln -s**（find -type f 漏掉））----
say "hard-link into arm-logs"
for pair in "tline:tline" "tab-zero:tab-zero" "tab-anchor:tab-anchor" "tab-rtl:tab-rtl" "textlineproto:textlineproto"; do
    src="${pair%%:*}"; dst="${pair##*:}"
    if [ -s "$OUT/$src.log" ]; then
        ln -f "$OUT/$src.log" "build/MilBridge/arm-logs/$dst.log" \
            && echo "ln -f $src.log -> arm-logs/$dst.log  (links=$(stat -c %h "build/MilBridge/arm-logs/$dst.log"))"
    else
        echo "!! $OUT/$src.log 为空 ⇒ **不覆盖** arm-logs/$dst.log（保留旧世代读数，门禁会给 STALE/NOINFO，好过静默换空日志）"
    fi
done

# ---- 6) 报每个臂日志的 sha16 + 自报身份行（供重钉登记表）----
say "arm log shas"
for f in tline tab-zero tab-anchor tab-rtl textlineproto; do
    p="build/MilBridge/arm-logs/$f.log"
    [ -f "$p" ] && printf '%-16s %s  %s\n' "$f" "$(sha256sum "$p" | cut -c1-16)" "$(stat -c %y "$p" | cut -c1-19)"
done
echo "=== done $(date '+%F %T') ==="
