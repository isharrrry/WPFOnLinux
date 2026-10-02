#!/bin/bash
# ============================================================================
#  windowsdesktop-app-linux-framework-e2e.sh
#  —— L1 路线① 的**端到端复现**：把 samples/WpfTextDemo 的**源码**在一个仓外目录里
#     按「共享框架接入形态」重编（runtimeconfig 里带 Microsoft.WindowsDesktop.App，
#     编译身份 = 自产 4.0.0.1），再 `dotnet <app>.dll` 跑起来。
# ============================================================================
#  【为什么用 WpfTextDemo 的源码】
#    · 它是"源码重编"形态的真 WPF 应用（XAML/BAML 真编、真开窗、真渲染、真滚动）；
#    · 它刻意用了一堆"真应用才会用"的东西（折行/省略号/绑定/滚动/位图/效果），
#      所以"跑起来"这件事不是只看进程还活着 —— 有 `WPTD_SCROLL_*` 这类现成读数。
#
#  【它证明什么】
#    ① 编译产物 `runtimeconfig.json` 里**自动**带 `Microsoft.WindowsDesktop.App`（未手改）；
#    ② 产物的 `AssemblyRef` 是自产身份（`Version=4.0.0.1`）；
#    ③ 应用输出目录里**没有**那 12 件 WPF 托管件（由共享框架提供）；
#    ④ 4 个 `.so` 从**框架目录**加载（`/proc/<pid>/maps` 现取）。
#
#  【用法】
#    bash build/third-party/windowsdesktop-app-linux-framework-e2e.sh [--display :234] [--keep]
#    先跑 install：bash build/third-party/windowsdesktop-app-linux-framework.sh install
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"

DISPLAY_OPT="${DISPLAY:-:234}"
KEEP=0
while [ $# -gt 0 ]; do
  case "$1" in
    --display) DISPLAY_OPT="$2"; shift 2 ;;
    --keep)    KEEP=1; shift ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

WORK="$(mktemp -d /tmp/wpfwd-e2e-XXXXXX)"
APP="$WORK/wtd"
mkdir -p "$APP"
cp -p "$REPO"/samples/WpfTextDemo/{App.xaml,App.xaml.cs,MainWindow.xaml,MainWindow.xaml.cs} "$APP/"

# 由样本 csproj 派生：只动"路径 + TFM + 框架接入"三处（源码一行不改）
python3 - "$REPO" "$APP/WpfTextDemo.csproj" <<'PY'
import re, sys
R, out = sys.argv[1], sys.argv[2]
s = open(R + "/samples/WpfTextDemo/WpfTextDemo.csproj").read()
s = s.replace("$(MSBuildThisFileDirectory)../../build", R + "/build")
s = s.replace("""<Import Project="$([MSBuild]::GetPathOfFileAbove('BuildHygiene.props'))" />""",
              '<Import Project="%s/BuildHygiene.props" />' % R)
s = s.replace("<TargetFramework>net10.0</TargetFramework>", "<TargetFramework>net10.0-windows</TargetFramework>")
s = s.replace("<UseWPF>false</UseWPF>", "<UseWPF>false</UseWPF>\n    <EnableWindowsTargeting>true</EnableWindowsTargeting>")
s = s.replace('<Import Project="Sdk.props" Sdk="Microsoft.NET.Sdk" />',
              '<Import Project="Sdk.props" Sdk="Microsoft.NET.Sdk" />\n'
              '  <PropertyGroup><WpfLinuxWindowsDesktopOwnReferences>true</WpfLinuxWindowsDesktopOwnReferences></PropertyGroup>\n'
              '  <Import Project="' + R + '/build/third-party/WindowsDesktop.App.Linux.props" />')
# 12 件 WPF 交给共享框架提供 ⇒ 不 app-local 复制（源码/接线一字不改，只改这一条元数据）
for n in ["WindowsBase", "System.Xaml", "PresentationCore", "PresentationFramework",
          "DirectWriteForwarder", "UIAutomationTypes", "UIAutomationProvider",
          "System.Windows.Input.Manipulations", "PresentationFramework.Classic"]:
    s = re.sub(r'(<Reference Include="%s">\s*<HintPath>[^<]*</HintPath>\s*)<Private>true</Private>' % re.escape(n),
               r'\1<Private>false</Private>', s)
open(out, "w").write(s)
PY

echo "== 1) 构建（net10.0-windows + 自产件编译面 + WindowsDesktop 框架声明）=="
dotnet build "$APP/WpfTextDemo.csproj" -c Release -p:WpfLinuxRoot="$REPO" -v:m 2>&1 | grep -E "error|WpfTextDemo ->|已成功生成" | head -5

OUT="$APP/bin/Release/net10.0-windows"
echo "== 2) 产物读数 =="
python3 - "$OUT" <<'PY'
import json, os, sys
out = sys.argv[1]
rc = json.load(open(os.path.join(out, "WpfTextDemo.runtimeconfig.json")))
fws = [f["name"] for f in rc["runtimeOptions"].get("frameworks", [])] or [rc["runtimeOptions"].get("framework", {}).get("name")]
print("runtimeconfig.frameworks =", fws)
dlls = sorted(f for f in os.listdir(out) if f.endswith(".dll"))
print("app-local dll            =", dlls)
print("框架件是否 app-local     =", any(f in dlls for f in ["WindowsBase.dll", "PresentationFramework.dll", "PresentationCore.dll"]))
PY
echo "-- AssemblyRef（自产身份）--"
strings "$OUT/WpfTextDemo.dll" | grep -E "(PresentationCore|PresentationFramework|WindowsBase|System.Xaml), Version=[0-9]" | sed 's/^[^A-Za-z]*//' | sort -u || true

echo "== 3) 跑（DISPLAY=$DISPLAY_OPT）=="
( cd "$OUT" && exec env DISPLAY="$DISPLAY_OPT" dotnet WpfTextDemo.dll ) > "$WORK/run.log" 2>&1 &
RUNPID=$!
echo "APP_PID=$RUNPID"
sleep 14
if kill -0 "$RUNPID" 2>/dev/null; then echo "ALIVE=yes"; else echo "ALIVE=no"; echo "--- log ---"; cat "$WORK/run.log"; exit 1; fi
WID="$(DISPLAY="$DISPLAY_OPT" xdotool search --name 'WpfTextDemo' | head -1 || true)"
if [ -n "$WID" ]; then
  DISPLAY="$DISPLAY_OPT" import -window "$WID" "$WORK/shot.png" 2>/dev/null || true
  [ -s "$WORK/shot.png" ] && identify -format 'window: %wx%h colors=%k\n' "$WORK/shot.png" || true
fi
echo "-- 应用自己报的读数（行模型/滚动）--"; grep -E "WPTD_SCROLL" "$WORK/run.log" > "$WORK/_scroll.txt" || true; head -3 "$WORK/_scroll.txt"
echo "-- .so 落点（/proc/$RUNPID/maps）--"
grep -oE "/[^ ]*\.so" "/proc/$RUNPID/maps" | sort -u | grep -E "Microsoft.WindowsDesktop|libwpf|wpfgfx" || true
echo "-- 框架目录被引用的 map 行数 --"; grep -c "Microsoft.WindowsDesktop.App" "/proc/$RUNPID/maps" || true

kill "$RUNPID" 2>/dev/null || true
sleep 1
kill -0 "$RUNPID" 2>/dev/null && echo "KILL=FAILED" || echo "KILL=ok（按 PID）"
[ "$KEEP" = 1 ] && echo "保留工作目录：$WORK" || rm -rf "$WORK"
