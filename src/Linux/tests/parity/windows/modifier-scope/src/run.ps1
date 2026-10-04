# Runs the oracle TWICE and compares the two JSON dumps (minus the generatedUtc line) as a determinism
# check. Process-level retry absorbs the known ~50% garbage-HRESULT startup failure at
# IDWriteFontFace::GetMetrics (environment noise, not a data problem).
# NOTE (lesson from the tab-anchor round): scp silently transferred only the FIRST of two remote source
# files, so a stale artifact was almost shipped. This script therefore prints the SHA256 of every output
# file, so the hash can be re-checked on the receiving side after each individual copy.
$exe  = "C:\u1-shaping\src\ModifierScopeOracle\bin\Debug\net10.0-windows\ModifierScopeOracle.exe"
$outA = "C:\u1-shaping\out-modifier"
$outB = "C:\u1-shaping\out-modifier2"
Remove-Item $outA,$outB -Recurse -Force -ErrorAction SilentlyContinue

function RunOnce([string]$outDir) {
  for ($try = 1; $try -le 6; $try++) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = $outDir
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
    $psi.WorkingDirectory = "C:\u1-shaping\src\ModifierScopeOracle"
    $pr = [System.Diagnostics.Process]::Start($psi)
    $so = $pr.StandardOutput.ReadToEnd(); $se = $pr.StandardError.ReadToEnd()
    $pr.WaitForExit(900000) | Out-Null
    if ($pr.ExitCode -eq 0 -and (Test-Path (Join-Path $outDir "modifier-scope-raw.json"))) {
      Write-Output ("EXITCODE=" + $pr.ExitCode + " (attempt " + $try + ")")
      Write-Output $so
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
  $stripped = ((Get-Content $p -Raw) -split "`n" | Where-Object { $_ -notmatch 'generatedUtc' }) -join "`n"
  $sha = [System.Security.Cryptography.SHA256]::Create()
  return [System.BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stripped))).Replace("-","").ToLower()
}
$ha = Canon (Join-Path $outA "modifier-scope-raw.json")
$hb = Canon (Join-Path $outB "modifier-scope-raw.json")
Write-Output ("DETERMINISM=" + $(if ($ha -eq $hb) { "MATCH" } else { "MISMATCH" }) + "  A=" + $ha.Substring(0,16) + " B=" + $hb.Substring(0,16))
Get-ChildItem $outA | ForEach-Object {
  $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
  Write-Output ("SHA256 " + $_.Name + " " + $h + " " + $_.Length)
}
