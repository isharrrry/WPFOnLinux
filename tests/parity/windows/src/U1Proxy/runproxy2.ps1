$ErrorActionPreference = "Continue"
$tag = "proxy2"
$dir = "C:\u1-parity\out\$tag"
$appdir = "C:\u1-parity\src\U1Recorder\bin\Debug\net10.0-windows"
Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $dir | Out-Null

Write-Output "--- build recorder ---"
& cmd /c "set DOTNET_CLI_UI_LANGUAGE=en&& cd /d C:\u1-parity\src\U1Recorder&& dotnet build -v q --nologo 2>&1" | Select-Object -Last 3

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "$appdir\U1Recorder.exe"
$psi.Arguments = "$dir nopatch window proxy=C:\u1-parity\src\U1Proxy\wpfgfx_cor3.dll"
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.WorkingDirectory = $appdir
$psi.EnvironmentVariables["WPF_STREAM_LOG"] = "$dir\wpf.stream"
$psi.EnvironmentVariables["WPFGFX_REAL"] = "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\10.0.7\wpfgfx_cor3.dll"
$pr = [System.Diagnostics.Process]::Start($psi)
if (-not $pr.WaitForExit(300000)) { Write-Output "TIMEOUT"; $pr.Kill(); $pr.WaitForExit(10000) }
Write-Output ("EXITCODE=" + $pr.ExitCode)
Write-Output "--- files ---"
Get-ChildItem $dir | Format-Table Name,Length -AutoSize | Out-String
$log = "$dir\wpf-proxy.log"
if (Test-Path $log) { Write-Output "--- proxy log ---"; Get-Content $log -TotalCount 10 }
$rep = "$dir\recorder-report.txt"
if (Test-Path $rep) { Get-Content $rep | Select-String -Pattern "proxy bootstrap|SetDllImportResolver|preload|rendered scenes|window" | Select-Object -First 8 }
