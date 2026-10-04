$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "C:\u1-shaping\src\BidiOracle\bin\Debug\net10.0-windows\BidiOracle.exe"
$psi.Arguments = "C:\u1-shaping\out-bidi"
$psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
$psi.WorkingDirectory = "C:\u1-shaping\src\BidiOracle"
$pr = [System.Diagnostics.Process]::Start($psi); $pr.WaitForExit(120000) | Out-Null
Write-Output ("EXITCODE=" + $pr.ExitCode)
Write-Output ($pr.StandardOutput.ReadToEnd() -replace "`r`n"," | ")
Write-Output "--- err ---"; Write-Output $pr.StandardError.ReadToEnd()
Get-ChildItem C:\u1-shaping\out-bidi -ErrorAction SilentlyContinue | Format-Table Name,Length -AutoSize | Out-String
