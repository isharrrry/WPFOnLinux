#!/usr/bin/env bash
# ============================================================================
# run-thirdparty-mini.sh —— **第三方形态**样本的构建 + 部署 + 运行 + 判据（`#37` B）
# ============================================================================
#
# 【它为什么存在】`README.md` 里那句"第三方真实应用能渲染"在本波之前只有**仓外**证据
#   （HandyControl 示例工程 + 它的探针，两者都不在本仓）⇒ **不构成仓内判据**。
#   本 runner 把同一件事搬进仓里：一个**第三方形态**的工程（`samples/ThirdPartyMini`，
#   只经 `build/third-party/WpfLinux.props` 接线、不进 sln、自带清单）+ **部署布局**
#   （把四个 `.so` 放到应用目录，**零环境变量**）+ **时间分辨**的画面判据。
#
# 【用法】
#   bash samples/ThirdPartyMini/run-thirdparty-mini.sh [超时秒数]
#   bash samples/ThirdPartyMini/run-thirdparty-mini.sh --no-build            # 复用已构建产物
#   bash samples/ThirdPartyMini/run-thirdparty-mini.sh --hide-shim          # 反极性：不部署 libwpfwin32.so
#   bash samples/ThirdPartyMini/run-thirdparty-mini.sh --selftest           # 判据逻辑的两极化自测（不跑应用）
#   TPM_RUN_DIR=/tmp/x TPM_DISPLAY=:98 bash …                               # 并发时各用各的
#
# 【判据（三态；与 build/MilBridge/tools/frame-presence-check.sh 同一族，但**独立实现**）】
#   THIRDPARTY=PASS   采样窗口内**至少一帧**的（根窗口）颜色数 ≥ --min-colors（默认 800）
#   THIRDPARTY=FAIL   采到帧但一帧都不达标（应用没画出来 / 崩了 / 被部署坑了）
#   THIRDPARTY=NOINFO 一帧都没采到（仪器没跑起来）⇒ 与 FAIL 分开报，**不许当绿**
#   ⚠️ 颜色数取**整幅根窗口**：应用窗口 900×620 居中、桌面背景纯色 ⇒ 与"窗口矩形内"等价；
#      这条口径写在这里，免得后人以为是"数了整个桌面所以数偏大"。
#   ⚠️ 阈值 800 的来历：第三方实证（HandyControl）窗口内实测 **1275**、仓内样本 **3960/2828**
#      ⇒ 800 留足余量，且**低于它一定是坏了**（空白窗口只有 1 色）。
#
# 【本脚本刻意避开的坑（都是本仓踩过的）】
#   · 自己起的 Xvfb **记 PID 杀自己那个**，绝不 `pkill -f 'Xvfb :98'`（会匹配到自己命令行）；
#   · 采样**跑多久就拍多久**（"跑了 N 秒 ≠ 拍了 N 秒"）；
#   · 判据是"窗口内**是否出现过**达标帧"，不是"最后一张/颜色最多那张"；
#   · 不给 `--hide-shim` 时**必须**把四个 `.so` 都部署上（缺一个的表现各不相同）。
# ============================================================================
set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd -- "$HERE/../.." && pwd)"
# ★ `#39` 阶段 2/3：产物路径与构建配置都跟随**唯一声明**。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../build/selfbuilt-config.sh"
PROJ="$REPO/samples/ThirdPartyMini/ThirdPartyMini.csproj"
APP_DLL="ThirdPartyMini.dll"
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

SECS=25; MIN_COLORS=800; DO_BUILD=1; HIDE_SHIM=0; SELFTEST=0
DISP="${TPM_DISPLAY:-:98}"
for a in "$@"; do
  case "$a" in
    --no-build)   DO_BUILD=0 ;;
    --hide-shim)  HIDE_SHIM=1 ;;
    --selftest)   SELFTEST=1 ;;
    --min-colors=*) MIN_COLORS="${a#*=}" ;;
    [0-9]*)       SECS="$a" ;;
    *) echo "用法: $0 [秒数] [--no-build] [--hide-shim] [--min-colors=K] [--selftest]" >&2; exit 2 ;;
  esac
done

# ── 判据逻辑（独立实现；`--selftest` 只测这一段）─────────────────────────────
judge_dir() {   # $1=帧目录 ⇒ 印三态 + 读数
  local dir="$1" n=0 maxc=0 f c
  for f in "$dir"/*.png; do
    [ -f "$f" ] || continue
    n=$((n+1)); c="$(identify -format '%k' "$f" 2>/dev/null | head -1)"; c="${c:-0}"
    [ "$c" -gt "$maxc" ] && maxc="$c"
  done
  if [ "$n" -eq 0 ]; then
    echo "THIRDPARTY=NOINFO frames=0 reason=一帧都没采到 dir=$dir"; return 2
  fi
  if [ "$maxc" -ge "$MIN_COLORS" ]; then
    echo "THIRDPARTY=PASS frames=$n max_colors=$maxc min_colors=$MIN_COLORS dir=$dir"; return 0
  fi
  echo "THIRDPARTY=FAIL frames=$n max_colors=$maxc min_colors=$MIN_COLORS dir=$dir"; return 1
}

if [ "$SELFTEST" = 1 ]; then
  T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
  mkdir -p "$T/blank" "$T/content" "$T/empty"
  convert -size 320x240 xc:'#202020' "$T/blank/f1.png"; cp "$T/blank/f1.png" "$T/blank/f2.png"
  convert -size 320x240 gradient:red-blue "$T/content/f1.png"; cp "$T/blank/f1.png" "$T/content/f2.png"
  pass=0; fail=0
  for spec in "FAIL:$T/blank" "PASS:$T/content" "NOINFO:$T/empty"; do
    want="${spec%%:*}"; dir="${spec#*:}"
    got="$(MIN_COLORS=200 judge_dir "$dir" 2>/dev/null | sed 's/THIRDPARTY=\([A-Z]*\).*/\1/')" || true
    if [ "$got" = "$want" ]; then pass=$((pass+1)); printf '  ✅ 期望 %-6s 实得 %-6s  %s\n' "$want" "$got" "$dir"
    else fail=$((fail+1)); printf '  ❌ 期望 %-6s 实得 %-6s  %s\n' "$want" "$got" "$dir"; fi
  done
  # 反极性②：把阈值抬到不可能达到 ⇒ 必须 FAIL（证明 PASS 不是恒真）
  got="$(MIN_COLORS=999999 judge_dir "$T/content" 2>/dev/null | sed 's/THIRDPARTY=\([A-Z]*\).*/\1/')" || true
  if [ "$got" = "FAIL" ]; then pass=$((pass+1)); printf '  ✅ 期望 %-6s 实得 %-6s  （阈值抬到 999999）\n' FAIL "$got"
  else fail=$((fail+1)); printf '  ❌ 期望 %-6s 实得 %-6s  （阈值抬到 999999）\n' FAIL "$got"; fi
  echo "TPM_SELFTEST=$([ "$fail" -eq 0 ] && echo PASS || echo FAIL) pass=$pass fail=$fail"
  [ "$fail" -eq 0 ] || exit 1
  exit 0
fi

OUT="${TPM_RUN_DIR:-$HOME/w37-tpm-$(date +%H%M%S)}"
rm -rf "$OUT"; mkdir -p "$OUT"
echo "== ThirdPartyMini（第三方形态） =="
echo "run_dir=$OUT  display=$DISP  secs=$SECS  min_colors=$MIN_COLORS  hide_shim=$HIDE_SHIM"

# ── ① 构建 ───────────────────────────────────────────────────────────────────
BUILD_RC=0
if [ "$DO_BUILD" = 1 ]; then
  dotnet build "$PROJ" -c "$SELFBUILT_CONFIG" -m:1 --nologo -v q > "$OUT/build.log" 2>&1 || BUILD_RC=$?
fi
echo "THIRDPARTY_BUILD=$([ "$BUILD_RC" -eq 0 ] && echo PASS || echo FAIL) rc=$BUILD_RC log=$OUT/build.log"
[ "$BUILD_RC" -eq 0 ] || { echo "THIRDPARTY=NOINFO reason=构建失败（没东西可跑）"; exit 2; }

BIN="$REPO/samples/ThirdPartyMini/bin/$SELFBUILT_CONFIG/net10.0"
[ -f "$BIN/$APP_DLL" ] || { echo "THIRDPARTY=NOINFO reason=产物不在 $BIN"; exit 2; }

# ── ② ⭐ **搬到仓外再跑**（这才是"第三方形态"的关键；`#37` 实测发现）───────────────
#   为什么必须搬：`Win32ShimResolver` 有一条**回退** —— 从 `AppContext.BaseDirectory` 逐级向上
#   找仓根，再探 `src/WpfGfx.Linux.Native/bin/<shim>`（`build/shims/Win32ShimResolver.cs` 的
#   候选路径枚举里）。⇒ **应用只要在仓内**，即使我们**故意不部署** app-local 那个 `.so`，
#   它也会被这条回退救回来（本波现场：`--hide-shim` 照样 `THIRDPARTY=PASS`、1485 色
#   ⇒ **反极性失效**，根因就是这条回退）。
#   真正的第三方应用在仓外、没有这条回退 ⇒ 它**必须**靠"四个 `.so` 与 app 同目录"才能跑。
#   ⇒ 本 runner 默认把产物**复制到仓外的干净目录**（`$OUT/app/`）再跑，于是：
#     ① 正常档 = 真正验证"部署布局、零环境变量"；② `--hide-shim` = **真反极性**（必须红）。
APP="$OUT/app"
mkdir -p "$APP"
cp -a "$BIN"/. "$APP"/ 2>/dev/null
rm -f "$APP"/libwpfwin32.so "$APP"/libwpfwic.so "$APP"/wpfgfx_cor3.so "$APP"/libSkiaSharp.so
case "$APP" in "$REPO"/*) echo "THIRDPARTY_LAYOUT=FAIL reason=应用目录仍在仓内（回退会救它 ⇒ 反极性失效）"; exit 2 ;; esac
[ -n "$APP" ] && case "$(pwd)" in "$REPO"*) echo "THIRDPARTY_LAYOUT=NOTE cwd=$(pwd)（启动时会被切到 $APP，cwd 回退不生效）" ;; esac
echo "THIRDPARTY_LAYOUT=OUT-OF-REPO app=$APP（仓外 ⇒ 没有仓根回退可依赖）"

# ── ③ 部署布局：四个 .so 放到应用目录（**零环境变量**；这就是发给第三方的形态）────
SHIM="$REPO/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
WIC="$REPO/build/DirectWrite.Linux/wic-shim/libwpfwic.so"
MIL="$REPO/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so"
SKIA="$REPO/build/DirectWrite.Linux/wic-shim/libSkiaSharp.so"
deploy() {  # $1=源 $2=目标名
  [ -f "$1" ] || { echo "THIRDPARTY_DEPLOY=FAIL missing=$1"; return 1; }
  cp -f "$1" "$APP/$2" || return 1
  echo "THIRDPARTY_DEPLOY=$(basename "$2") OK $(sha256sum "$1" | cut -c1-16)"
}
drc=0
if [ "$HIDE_SHIM" = 1 ]; then
  # 反极性：**故意不部署** Win32 shim，且应用在**仓外**（没有任何回退可依赖）⇒ 判据必须红
  echo "THIRDPARTY_DEPLOY=libwpfwin32.so SKIPPED（反极性：不部署且仓外）"
else
  deploy "$SHIM" libwpfwin32.so || drc=1
fi
deploy "$WIC"  libwpfwic.so  || drc=1
deploy "$MIL"  wpfgfx_cor3.so || drc=1
deploy "$SKIA" libSkiaSharp.so || drc=1
[ "$drc" -eq 0 ] || { echo "THIRDPARTY=NOINFO reason=部署不全（缺 .so，本趟读数不可归因）"; exit 2; }

# ── ④ 测试图片（第三方应用常做的事：从文件加载图片）──────────────────────────
convert -size 96x96 gradient:'#FF00FF-#00FFFF' "$APP/test-image.png" 2>/dev/null \
  || convert -size 96x96 xc:'#FF00FF' "$APP/test-image.png"
echo "THIRDPARTY_TESTIMAGE=$(sha256sum "$APP/test-image.png" | cut -c1-16) path=$APP/test-image.png"

# ── ④ 起 Xvfb（记 PID，杀自己起的那个）＋ 时间分辨采样 ─────────────────────────
XPID=""
if ! xdpyinfo -display "$DISP" >/dev/null 2>&1; then
  Xvfb "$DISP" -screen 0 1280x1024x24 > "$OUT/xvfb.log" 2>&1 &
  XPID=$!
  for _ in $(seq 1 40); do xdpyinfo -display "$DISP" >/dev/null 2>&1 && break; sleep 0.25; done
fi
cleanup() { [ -n "$XPID" ] && kill "$XPID" 2>/dev/null; }
trap cleanup EXIT

# ⚠️ **必须在 `$APP` 里启动**：`Win32ShimResolver` 的候选路径会从
#   `AppContext.BaseDirectory` **与 `Directory.GetCurrentDirectory()`** 两条各自向上走 12 层找仓根
#   （`build/shims/Win32ShimResolver.cs:524-537`）⇒ 如果 cwd 是仓根，**反极性会被 cwd 回退救回来**
#   （本波实测：仓外 app 目录 + 不部署 shim，只要 cwd=仓根就照样 1485 色 PASS）。
( cd "$APP" && DISPLAY="$DISP" dotnet "$APP_DLL" ) > "$OUT/app.log" 2>&1 &
APID=$!
sleep 2
FRAMES=0
END=$(( $(date +%s) + SECS ))
while [ "$(date +%s)" -lt "$END" ]; do
  if kill -0 "$APID" 2>/dev/null; then
    DISPLAY="$DISP" xwd -root -silent 2>/dev/null | convert xwd:- "png:$OUT/f$(printf '%03d' "$FRAMES").png" 2>/dev/null \
      && FRAMES=$((FRAMES+1))
  fi
  sleep 0.5
done
kill "$APID" 2>/dev/null; wait "$APID" 2>/dev/null; APP_RC=$?
echo "THIRDPARTY_APP=exit=$APP_RC frames=$FRAMES（143 = 被本脚本正常收走）"

# 应用自己报的两条（图片解码 / 绑定）—— 如实转发，不替它下结论
grep -aE '^THIRDPARTY_IMAGE=' "$OUT/app.log" | tail -1 || echo "THIRDPARTY_IMAGE=NOINFO reason=应用没打印（可能没跑到那一步）"

# ── ⑤ 判据 ───────────────────────────────────────────────────────────────────
#   ⚠️ 三态细分（`#37` 实测补）：**应用崩了** ⇒ `FAIL`（红）；**仪器没跑起来**（采不到帧但应用正常收尾）
#      ⇒ `NOINFO`。把两者混成一个数字会让"应用起不来"看起来像"仪器故障"，而这两件事的修法完全不同。
rc=0
if [ "$FRAMES" -eq 0 ] && [ "$APP_RC" != "143" ] && [ "$APP_RC" != "0" ]; then
  echo "THIRDPARTY=FAIL frames=0 reason=app-exit=$APP_RC（应用没起来/崩了 ⇒ 判据红，不是仪器没跑）"
  grep -aE "DllNotFoundException|Unhandled exception|找不到可加载的 shim" "$OUT/app.log" | head -3 | sed 's/^/  | /'
  rc=1
else
  MIN_COLORS="$MIN_COLORS" judge_dir "$OUT"
  rc=$?
fi
echo "TPM_RUN_DIR=$OUT"
exit $rc
