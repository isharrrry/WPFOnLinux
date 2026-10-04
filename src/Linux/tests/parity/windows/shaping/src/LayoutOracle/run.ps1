$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "C:\u1-shaping\src\LayoutOracle\bin\Debug\net10.0-windows\LayoutOracle.exe"
$psi.Arguments = "C:\u1-shaping\fonts C:\u1-shaping\out-layout"
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.WorkingDirectory = "C:\u1-shaping\src\LayoutOracle"
$pr = [System.Diagnostics.Process]::Start($psi)
if (-not $pr.WaitForExit(120000)) { Write-Output "TIMEOUT"; $pr.Kill() }
Write-Output ("EXITCODE=" + $pr.ExitCode)
Write-Output "--- stdout ---"; Write-Output $pr.StandardOutput.ReadToEnd()
Write-Output "--- stderr ---"; Write-Output ($pr.StandardError.ReadToEnd())
Get-ChildItem C:\u1-shaping\out-layout -ErrorAction SilentlyContinue | Format-Table Name,Length -AutoSize | Out-String
