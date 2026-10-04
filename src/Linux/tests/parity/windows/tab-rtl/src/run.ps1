$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "C:\u1-shaping\src\TabRtlOracle\bin\Debug\net10.0-windows\TabRtlOracle.exe"
$psi.Arguments = "C:\u1-shaping\fonts C:\u1-shaping\out-tabrtl"
$psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
$psi.WorkingDirectory = "C:\u1-shaping\src\TabRtlOracle"
$pr = [System.Diagnostics.Process]::Start($psi); $pr.WaitForExit(180000) | Out-Null
Write-Output ("EXITCODE=" + $pr.ExitCode)
Write-Output ($pr.StandardOutput.ReadToEnd() -replace "`r`n"," | ")
Write-Output "--- err ---"; Write-Output ($pr.StandardError.ReadToEnd() -replace "`r`n"," | ")
Get-ChildItem C:\u1-shaping\out-tabrtl -ErrorAction SilentlyContinue | Format-Table Name,Length -AutoSize | Out-String
