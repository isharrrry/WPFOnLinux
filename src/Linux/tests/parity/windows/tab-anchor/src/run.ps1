# Runs the tab-anchor oracle TWICE and compares the two JSON dumps (minus the timestamp) as a
# determinism check. Process-level retry absorbs the known ~50% garbage-HRESULT startup failure at
# IDWriteFontFace::GetMetrics (environment noise, not a data problem).
$exe = "C:\u1-shaping\src\TabAnchorOracle\bin\Debug\net10.0-windows\TabAnchorOracle.exe"
$outA = "C:\u1-shaping\out-tabanchor"
$outB = "C:\u1-shaping\out-tabanchor2"
Remove-Item $outA,$outB -Recurse -Force -ErrorAction SilentlyContinue

function RunOnce([string]$outDir) {
  for ($try = 1; $try -le 6; $try++) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = $outDir
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
    $psi.WorkingDirectory = "C:\u1-shaping\src\TabAnchorOracle"
    $pr = [System.Diagnostics.Process]::Start($psi)
    $so = $pr.StandardOutput.ReadToEnd(); $se = $pr.StandardError.ReadToEnd()
    $pr.WaitForExit(600000) | Out-Null
    if ($pr.ExitCode -eq 0 -and (Test-Path (Join-Path $outDir "tab-anchor-raw.json"))) {
      Write-Output ("EXITCODE=" + $pr.ExitCode + " (attempt " + $try + ")")
      Write-Output ($so -replace "`r`n"," | ")
      return
    }
    Write-Output ("attempt " + $try + " failed: EXITCODE=" + $pr.ExitCode + " err=" + ($se -replace "`r`n"," | ") + " out=" + ($so -replace "`r`n"," | "))
  }
  Write-Output "ALL ATTEMPTS FAILED"
}

RunOnce $outA
RunOnce $outB

function Canon([string]$p) {
  if (-not (Test-Path $p)) { return "MISSING" }
  $t = Get-Content $p -Raw
  $stripped = ($t -split "`n" | Where-Object { $_ -notmatch 'generatedUtc' }) -join "`n"
  $sha = [System.Security.Cryptography.SHA256]::Create()
  return [System.BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stripped))).Replace("-","").ToLower()
}
$ha = Canon (Join-Path $outA "tab-anchor-raw.json")
$hb = Canon (Join-Path $outB "tab-anchor-raw.json")
Write-Output ("DETERMINISM=" + $(if ($ha -eq $hb) { "MATCH" } else { "MISMATCH" }) + "  A=" + $ha.Substring(0,16) + " B=" + $hb.Substring(0,16))
Get-ChildItem $outA -ErrorAction SilentlyContinue | Format-Table Name,Length -AutoSize | Out-String
