# Runs the oracle TWICE and compares the two JSON dumps (minus generatedUtc) as a determinism check.
# Process-level retry absorbs the known ~50% garbage-HRESULT startup noise at IDWriteFontFace::GetMetrics.
# Every output file's SHA256 is printed (lesson from the tab-anchor round, where a two-source scp silently
# transferred only the first file and a stale artifact was nearly shipped): one scp per file on the way back,
# one hash check per file.
$exe  = "C:\u1-shaping\src\FontFallbackOracle\bin\Debug\net10.0-windows\FontFallbackOracle.exe"
$outA = "C:\u1-shaping\out-fontfallback"
$outB = "C:\u1-shaping\out-fontfallback2"
Remove-Item $outA,$outB -Recurse -Force -ErrorAction SilentlyContinue

function RunOnce([string]$outDir) {
  for ($try = 1; $try -le 6; $try++) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = $outDir
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
    $psi.WorkingDirectory = "C:\u1-shaping\src\FontFallbackOracle"
    $pr = [System.Diagnostics.Process]::Start($psi)
    $so = $pr.StandardOutput.ReadToEnd(); $se = $pr.StandardError.ReadToEnd()
    $pr.WaitForExit(900000) | Out-Null
    if ($pr.ExitCode -eq 0 -and (Test-Path (Join-Path $outDir "font-fallback-raw.json"))) {
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
$ha = Canon (Join-Path $outA "font-fallback-raw.json")
$hb = Canon (Join-Path $outB "font-fallback-raw.json")
Write-Output ("DETERMINISM=" + $(if ($ha -eq $hb) { "MATCH" } else { "MISMATCH" }) + "  A=" + $ha.Substring(0,16) + " B=" + $hb.Substring(0,16))
Get-ChildItem $outA | ForEach-Object {
  $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
  Write-Output ("SHA256 " + $_.Name + " " + $h + " " + $_.Length)
}
