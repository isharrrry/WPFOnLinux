$exe = "C:\u1-shaping\src\LayoutOracle\bin\Debug\net10.0-windows\LayoutOracle.exe"
$out = "C:\u1-shaping\out-layout"
$ok = 0; $attempt = 0
while ($ok -lt 2 -and $attempt -lt 12) {
  $attempt++
  $dir = "$out\run$ok"
  Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $exe; $psi.Arguments = "C:\u1-shaping\fonts $dir"
  $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
  $pr = [System.Diagnostics.Process]::Start($psi); $pr.WaitForExit(180000) | Out-Null
  $o = $pr.StandardOutput.ReadToEnd(); $e = $pr.StandardError.ReadToEnd()
  $n = 0; if ($o -match "cases: (\d+)") { $n = [int]$Matches[1] }
  Write-Output ("attempt $attempt : cases=$n exit=" + $pr.ExitCode)
  Write-Output ($o -replace "`r`n"," | ")
  if ($e.Length -gt 0) { Write-Output ("   err: " + $e.Substring(0,[Math]::Min(300,$e.Length))) }
  if ($n -gt 0) {
    Copy-Item "$dir\dwrite-layout-oracle.json" "$out\dwrite-layout-cjk-oracle.json" -Force
    Copy-Item "$dir\dwrite-layout-oracle.txt"  "$out\dwrite-layout-cjk-oracle.txt"  -Force
    $ok++
  }
}
Write-Output "successful passes: $ok / attempts $attempt"
