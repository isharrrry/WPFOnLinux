for ($i=1; $i -le 3; $i++) {
  $dir = "C:\u1-shaping\stab$i"
  Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "C:\u1-shaping\src\bin\Debug\net10.0-windows\ShapingOracle.exe"
  $psi.Arguments = "C:\u1-shaping\fonts $dir"
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $pr = [System.Diagnostics.Process]::Start($psi)
  $pr.WaitForExit(120000) | Out-Null
  $o = $pr.StandardOutput.ReadToEnd(); $e = $pr.StandardError.ReadToEnd()
  Write-Output ("RUN $i exit=" + $pr.ExitCode + " out=" + ($o -replace "`r`n"," | ") + " err=" + ($e -replace "`r`n"," | "))
}
# hash the outputs to prove determinism
Get-FileHash C:\u1-shaping\stab1\dwrite-shaping-oracle.json, C:\u1-shaping\stab2\dwrite-shaping-oracle.json, C:\u1-shaping\stab3\dwrite-shaping-oracle.json -Algorithm SHA256 | ForEach-Object { Write-Output ($_.Hash.Substring(0,16) + "  " + (Split-Path $_.Path -Parent | Split-Path -Leaf)) }
