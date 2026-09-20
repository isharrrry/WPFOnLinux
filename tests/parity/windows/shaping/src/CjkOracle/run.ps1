# Runs the CJK oracle, retrying process starts because ~half of the starts hit the known
# intermittent IDWriteFontFace::GetMetrics failure on this machine.
$exe = "C:\u1-shaping\src\CjkOracle\bin\Debug\net10.0-windows\CjkOracle.exe"
$out = "C:\u1-shaping\out-cjk"
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
  if ($n -gt 0) {
    Copy-Item "$dir\dwrite-cjk-shaping-oracle.json" "$out\dwrite-cjk-shaping-oracle.json" -Force
    Copy-Item "$dir\dwrite-cjk-shaping-oracle.txt"  "$out\dwrite-cjk-shaping-oracle.txt"  -Force
    $ok++
  } elseif ($e.Length -gt 0) { Write-Output ("   err: " + $e.Substring(0,[Math]::Min(200,$e.Length))) }
}
Write-Output "successful passes: $ok / attempts $attempt"
if ($ok -ge 2) {
  $a = (Get-Content "$out\run0\dwrite-cjk-shaping-oracle.json" -Raw) -replace '"generatedUtc": "[^"]*"',''
  $b = (Get-Content "$out\run1\dwrite-cjk-shaping-oracle.json" -Raw) -replace '"generatedUtc": "[^"]*"',''
  Write-Output ("determinism: " + ($a -eq $b))
}
