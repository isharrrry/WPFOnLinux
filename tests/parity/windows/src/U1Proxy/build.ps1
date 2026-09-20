# Build the app-local forwarding proxy with the project-local portable zig toolchain.
$ErrorActionPreference = "Stop"
$zig   = "C:\u1-parity\pylibs\ziglang\zig.exe"
$real  = "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\10.0.7\wpfgfx_cor3.dll"
$src   = "C:\u1-parity\src\U1Proxy"
$out   = "C:\u1-parity\out\proxy"

New-Item -ItemType Directory -Force -Path $out | Out-Null
Set-Location $src

Write-Output "--- 1. parse real exports ---"
& python pe_exports.py $real "$src\exports.json"

Write-Output "--- 2. generate proxy sources ---"
& python gen_proxy.py "$src\exports.json" $src

Write-Output "--- 3. zig cc -shared ---"
# PowerShell refuses to exec zig.exe from this path, cmd does not; keep caches project-local
$cmdline = '"' + $zig + '" cc -target x86_64-windows-gnu -shared -O2' +
           ' --cache-dir C:\u1-parity\zig-cache --global-cache-dir C:\u1-parity\zig-global' +
           ' -o "' + $src + '\wpfgfx_cor3.dll" "' + $src + '\proxy.c" "' + $src + '\stubs.s"' +
           ' -lkernel32 2>&1'
Write-Output $cmdline
$zigout = & cmd /c $cmdline
Write-Output $zigout
if (-not (Test-Path "$src\wpfgfx_cor3.dll")) { throw "zig cc produced no DLL" }

Write-Output "--- 4. verify our own export table ---"
& python pe_exports.py "$src\wpfgfx_cor3.dll" "$src\proxy_exports_built.json"

$fi = Get-Item "$src\wpfgfx_cor3.dll"
Write-Output ("BUILT: " + $fi.FullName + "  " + $fi.Length + " bytes")
Copy-Item "$src\wpfgfx_cor3.dll" "$out\wpfgfx_cor3.dll" -Force
Write-Output ("COPIED to " + $out + "\wpfgfx_cor3.dll")
