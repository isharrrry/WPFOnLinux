#!/bin/bash
# MVP-1 全量验收复跑（编译 + Rebuild + 仓外运行）
set -u
export PATH="$HOME/.dotnet:$PATH"
P=/home/links-dev/netTest/GitProj/WPFOnLinux/src/Linux/samples/WpfLinuxSdkProbe
OUT="$P/evidence"
DISP=:96
mkdir -p "$OUT"

echo "### 1) 干净首次构建（清 obj/bin + 清包缓存）"
rm -rf "$P/obj" "$P/bin" "$HOME/.nuget/packages/wpflinux.sdk"
dotnet build "$P/WpfLinuxSdkProbe.csproj" -v:m > "$OUT/mvp1-build.log" 2>&1
echo "build rc=$?"
tail -4 "$OUT/mvp1-build.log"

echo "### 2) 不带任何 -p: 的 Rebuild"
dotnet build "$P/WpfLinuxSdkProbe.csproj" -t:Rebuild -v:m > "$OUT/mvp1-rebuild.log" 2>&1
echo "rebuild rc=$?"
tail -4 "$OUT/mvp1-rebuild.log"

echo "### 3) 产物与 deps.json"
ls -la "$P/bin/Debug/net10.0/WpfLinuxSdkProbe.dll"
python3 - "$P" > "$OUT/mvp1-deps.txt" <<'PY'
import json,sys
p=sys.argv[1]+'/bin/Debug/net10.0/WpfLinuxSdkProbe.deps.json'
d=json.load(open(p))
for t,libs in d['targets'].items():
    e=libs.get('WpfLinux.Sdk/1.0.0',{})
    for a,b in sorted(e.get('runtime',{}).items()): print(f'runtime {a} assemblyVersion={b["assemblyVersion"]}')
    for a,b in sorted(e.get('runtimeTargets',{}).items()): print(f'native  {a} rid={b["rid"]}')
print('libraries:', {k:v.get('type') for k,v in d['libraries'].items() if 'WpfLinux' in k or 'Windows.Extensions' in k or 'Security.Permissions' in k})
PY
cat "$OUT/mvp1-deps.txt"

echo "### 4) 仓外运行（复制到 /tmp/probe1/app）"
A=/tmp/probe1
rm -rf "$A"; mkdir -p "$A/app"
cp -a "$P/bin/Debug/net10.0/." "$A/app/"
echo "app 根下的 .so："; ls "$A/app"/*.so 2>/dev/null
if ! xdpyinfo -display "$DISP" >/dev/null 2>&1; then Xvfb "$DISP" -screen 0 1280x1024x24 >/tmp/xvfb96.log 2>&1 & sleep 2; fi
cd "$A/app" || exit 9
DISPLAY="$DISP" dotnet WpfLinuxSdkProbe.dll > "$OUT/mvp1-run.log" 2>&1 &
APID=$!
sleep 12
ALIVE=no; kill -0 "$APID" 2>/dev/null && ALIVE=yes
if [ "$ALIVE" = yes ]; then
  DISPLAY="$DISP" xwd -root -silent 2>/dev/null | convert xwd:- "$OUT/mvp1-shot.png" 2>/dev/null
  COLORS=$(identify -format '%k' "$OUT/mvp1-shot.png" 2>/dev/null)
fi
echo "ALIVE_AFTER_12S=$ALIVE COLORS=${COLORS:-n/a}"
kill "$APID" 2>/dev/null
head -12 "$OUT/mvp1-run.log"
