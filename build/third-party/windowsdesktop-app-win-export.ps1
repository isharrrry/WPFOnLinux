#!/usr/bin/env pwsh
#requires -Version 7.0
<#
  ============================================================================
  windowsdesktop-app-win-export.ps1
  —— 「Windows 端替换 runtime」的**一条命令**（WIN-INTEROP.md §7.4 ② / §7.5 L3）
  ============================================================================

  【它解决什么】
    本栈在 Linux 上编出来的 WPF 应用（L0 形态：`UseWPF=false` + `<Reference HintPath>`
    指自产件 + `Private=true`；见 `samples/WpfTextDemo/WpfTextDemo.csproj`），产物里
    **app-local 躺着自产 12 件 WPF 托管件 + 4 个原生 .so**，`runtimeconfig.json` 只声明
    `Microsoft.NETCore.App`。这份产物搬到 Windows 上按 §7.4 是**跑不了的形态**：
      · 宿主没见到 `Microsoft.WindowsDesktop.App` 框架声明；
      · 自产 WPF 件与官方框架件同名 ⇒ 抢位/绑不上（§7.3）；
      · `libwpfwin32.so` 等是 ELF（Windows 加载不了），而 shim 的 [ModuleInitializer]
        会把 `user32.dll` 劫持到它上面（§7.4 ① 已加平台短路兜底）。
    本脚本把这份产物**就地**改成"标准 Windows WPF 应用形态"：
      · 删掉 app-local 里**官方 Microsoft.WindowsDesktop.App 会同名提供的那批件**
        （21 件托管 + 3 个自产 ELF），让 Windows 用**官方件**；
      · 写回**标准 `runtimeconfig.json`**（`frameworks` = NETCore.App + WindowsDesktop.App）；
      · 同步 `deps.json`（去掉被删件的登记 —— 只删件不改 deps 会 `FileNotFoundException`，§7.4 ②）。

  【它不做什么 / 必须如实划界】
    · **不**声称"已在 Windows 上端到端跑通"。本机无 `Microsoft.WindowsDesktop.App.Runtime.win-x64`、
      无 wine（`WIN-INTEROP.md` §7.7）⇒ 真 Windows 端到端**本机不可得**。本脚本给的是
      **可复算的产物变换**：变换结果在**本机（Linux + pwsh）**上用 `verify` 断言形态，
      Windows 侧"跑起来"那一格必须到 Windows 机上复验。
    · 不改任何"应用自己的件"、也不碰第三方包（SkiaSharp 等）。只动"官方框架会同名提供"的那一层。
    · 替换之后 Windows 上跑的是**官方 WPF**，不是本栈实现（§7.4 末段）。

  【用法】（PowerShell 7+；Linux/macOS 上 pwsh 也能跑 —— 这正是本脚本形态可被本机复算的原因）
    pwsh -File build/third-party/windowsdesktop-app-win-export.ps1 install   <appdir> [-Force] [-DryRun]
    pwsh -File build/third-party/windowsdesktop-app-win-export.ps1 verify    <appdir>
    pwsh -File build/third-party/windowsdesktop-app-win-export.ps1 uninstall <appdir>
    选项：
      -FrameworkVersion <ver>  写进 runtimeconfig 的 WindowsDesktop.App 版本（默认 10.0.0）
      -Force                   已导出过也重做（先回到原始形态再导出）
      -DryRun                  只打印计划，不落盘

  【可回滚】
    install 把**动过的每一个文件**（删的/改的）原样备份到 `<appdir>/.wpf-win-export-backup/`，
    并写一份 `manifest.json` 记录逐条动作；uninstall 按清单**整份还原**后删掉备份目录
    （还原后目录与导出前**逐字节相同**；`verify` 会断言这一点）。
  ============================================================================
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('install', 'uninstall', 'verify')]
  [string]$Action,

  [Parameter(Mandatory = $true, Position = 1)]
  [string]$AppDir,

  [string]$FrameworkVersion = '10.0.0',
  [switch]$Force,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# ── 官方 Microsoft.WindowsDesktop.App 会**同名提供**的那批件（本栈自产件必须让位）──────────
#    12 件 WPF（与官方框架同名）+ 9 件曾走 app-local 的 OOB BCL（官方框架也含这批）。
#    依据：`~/.nuget/packages/microsoft.windowsdesktop.app.ref/10.0.11/ref/net10.0/` 的件名清单
#    （DirectWriteForwarder 不在 ref 包里，但在官方 **runtime** 包里 ⇒ 同样让位）。
$FrameworkAssemblies = @(
  'WindowsBase', 'System.Xaml', 'PresentationCore', 'PresentationFramework',
  'PresentationFramework.Classic', 'PresentationUI', 'ReachFramework', 'System.Printing',
  'System.Windows.Input.Manipulations', 'UIAutomationTypes', 'UIAutomationProvider',
  'DirectWriteForwarder',
  'System.IO.Packaging', 'System.Configuration.ConfigurationManager', 'System.Diagnostics.EventLog',
  'System.Formats.Nrbf', 'System.Security.Cryptography.Pkcs', 'System.Security.Cryptography.ProtectedData',
  'System.Security.Cryptography.Xml', 'System.Security.Permissions', 'System.Windows.Extensions'
)
# ── 自产**原生**件（Linux ELF；Windows 加载不了，且只有自产托管件会用它们）──────────────────
$SelfBuiltNative = @('libwpfwin32.so', 'libwpfwic.so', 'wpfgfx_cor3.so')
# ── 自产**Linux 专用**托管件**保留**（刻意不删）────────────────────────────────────────────
#    `DirectWrite.Linux.Provider.dll` 官方**无同名对应**（不是框架件遮蔽物）；它由自产
#    `PresentationCore` 的模块初始化器按名加载（`FontFaceBridge.Install`）。在 Windows 上官方
#    `PresentationCore` 根本不走那条路 ⇒ 该件不会被加载 ⇒ 留着**无害**；而留着它还能让同一份产物
#    在 Linux（自产框架）下保持自洽（缺它 ⇒ `FileNotFoundException: DirectWrite.Linux.Provider`，实测）。
#    ⇒ 本脚本只动"官方框架会同名提供"的那一层，不动应用自己的/第三方的件。

$ManagedToDelete = @($FrameworkAssemblies)
$AllDeletedNames = @($ManagedToDelete + $SelfBuiltNative)

$BackupDirName = '.wpf-win-export-backup'

function Fail([string]$msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }
function Step([string]$msg) { Write-Host "  [cmd] $msg" }
function Info([string]$msg) { Write-Host "        $msg" }

# ── 解析 app 目录 ─────────────────────────────────────────────────────────────
if (-not (Test-Path -LiteralPath $AppDir -PathType Container)) { Fail "app 目录不存在：$AppDir" }
$AppDir = (Resolve-Path -LiteralPath $AppDir).Path
$BackupDir = Join-Path $AppDir $BackupDirName
$ManifestPath = Join-Path $BackupDir 'manifest.json'

# ── 找应用名（<Name>.runtimeconfig.json + <Name>.deps.json + <Name>.dll）──────
$mainDll = Get-ChildItem -LiteralPath $AppDir -Filter *.dll -File |
  Where-Object { Test-Path -LiteralPath (Join-Path $AppDir ([IO.Path]::GetFileNameWithoutExtension($_.Name) + '.runtimeconfig.json')) }
if (-not $mainDll) { Fail "在 $AppDir 里找不到带 .runtimeconfig.json 的主程序集（它不是一份应用输出？）" }
$appName = [IO.Path]::GetFileNameWithoutExtension($mainDll[0].Name)
$runtimeConfigPath = Join-Path $AppDir "$appName.runtimeconfig.json"
$depsPath = Join-Path $AppDir "$appName.deps.json"
if (-not (Test-Path -LiteralPath $depsPath)) { Fail "找不到 $depsPath" }

function Show-Plan {
  Write-Host "APP            = $appName"
  Write-Host "APP_DIR        = $AppDir"
  Write-Host "RUNTIMECONFIG  = $runtimeConfigPath"
  Write-Host "DEPS           = $depsPath"
  Write-Host "BACKUP_DIR     = $BackupDir"
  Write-Host "FW_VERSION     = $FrameworkVersion"
}

# ── 备份 / 还原的原子件：一个文件进备份，再按需删/改 ─────────────────────────
function Backup-File([string]$rel) {
  $src = Join-Path $AppDir $rel
  if (-not (Test-Path -LiteralPath $src)) { return $false }
  $dst = Join-Path (Join-Path $BackupDir 'files') $rel
  $dstDir = Split-Path -Parent $dst
  if (-not (Test-Path -LiteralPath $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }
  Copy-Item -LiteralPath $src -Destination $dst -Force
  return $true
}

# ============================================================================
#  install
# ============================================================================
function Do-Install {
  Write-Host "=== install：把 Linux 编出来的产物改成「Windows 直接跑（跑官方件）」形态 ==="
  Show-Plan

  if (Test-Path -LiteralPath $BackupDir) {
    if (-not $Force) { Fail "已导出过（$BackupDir 存在）。要重做先 uninstall，或加 -Force。" }
    Write-Host "  [note] -Force：先回滚到原始形态，再重做"
    Do-Uninstall -Quiet
  }

  if ($DryRun) { Write-Host "(--DryRun：不落盘)"; return 0 }

  New-Item -ItemType Directory -Force -Path (Join-Path $BackupDir 'files') | Out-Null
  $manifest = [ordered]@{
    tool             = 'windowsdesktop-app-win-export.ps1'
    action           = 'install'
    appName          = $appName
    appDir           = $AppDir
    frameworkVersion = $FrameworkVersion
    timestamp        = (Get-Date).ToString('o')
    deletedFiles     = @()
    rewrittenFiles   = @()
  }

  # ── 1) 删掉 app-local 的自产/框架同名件 ─────────────────────────────────────
  Write-Host "-- 1) 删掉 app-local 里「官方 WindowsDesktop.App 会同名提供」的件 + 自产 ELF --"
  $deleted = 0
  foreach ($n in $AllDeletedNames) {
    foreach ($ext in @('.dll', '.pdb', '.so')) {
      $rel = "$n$ext"
      if (Backup-File $rel) {
        Step "backup + del  $rel"
        Remove-Item -LiteralPath (Join-Path $AppDir $rel) -Force
        $manifest.deletedFiles += $rel
        $deleted++
      }
    }
  }
  Info "共删除 $deleted 个文件"

  # ── 2) 写回标准 runtimeconfig.json ─────────────────────────────────────────
  Write-Host "-- 2) 写回标准 runtimeconfig.json（frameworks = NETCore.App + WindowsDesktop.App）--"
  Backup-File "$appName.runtimeconfig.json" | Out-Null
  $rc = Get-Content -LiteralPath $runtimeConfigPath -Raw | ConvertFrom-Json -AsHashtable
  $cfgProps = $rc.runtimeOptions.ContainsKey('configProperties') ? $rc.runtimeOptions.configProperties : @{}
  $tfms = $rc.runtimeOptions.ContainsKey('tfm') ? $rc.runtimeOptions.tfm : 'net10.0'
  $newRc = [ordered]@{
    runtimeOptions = [ordered]@{
      tfm        = $tfms
      frameworks = @(
        [ordered]@{ name = 'Microsoft.NETCore.App';        version = '10.0.0' }
        [ordered]@{ name = 'Microsoft.WindowsDesktop.App'; version = $FrameworkVersion }
      )
      configProperties = $cfgProps
    }
  }
  ($newRc | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath $runtimeConfigPath -Encoding utf8NoBOM
  Step "rewrite $appName.runtimeconfig.json"
  $manifest.rewrittenFiles += "$appName.runtimeconfig.json"

  # ── 3) 同步 deps.json（去掉被删件的登记）───────────────────────────────────
  Write-Host "-- 3) 同步 deps.json（去掉被删件的登记；只删件不改 deps ⇒ 启动 FileNotFoundException）--"
  Backup-File "$appName.deps.json" | Out-Null
  $deps = Get-Content -LiteralPath $depsPath -Raw | ConvertFrom-Json -AsHashtable
  $removedLibKeys = @()
  foreach ($libKey in @($deps.libraries.Keys)) {
    $simple = ($libKey -split '/')[0]
    if ($ManagedToDelete -contains $simple) { $removedLibKeys += $libKey; continue }
    # 该库的 runtime 段若**只**登记被删件，也算被删件库（实例：System.Windows.Extensions.Reference）
    $tEntry = $null
    foreach ($tk in $deps.targets.Keys) {
      if ($deps.targets[$tk].ContainsKey($libKey)) { $tEntry = $deps.targets[$tk][$libKey]; break }
    }
    if ($tEntry -and $tEntry.ContainsKey('runtime')) {
      $files = @($tEntry.runtime.Keys | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) })
      if ($files.Count -gt 0 -and (@($files | Where-Object { $ManagedToDelete -notcontains $_ }).Count -eq 0)) {
        $removedLibKeys += $libKey
      }
    }
  }
  $removedSimpleNames = @($removedLibKeys | ForEach-Object { ($_ -split '/')[0] } | Select-Object -Unique)

  foreach ($tk in $deps.targets.Keys) {
    $t = $deps.targets[$tk]
    foreach ($libKey in @($t.Keys)) {
      if ($removedLibKeys -contains $libKey) { $t.Remove($libKey) | Out-Null; continue }
      if ($t[$libKey].ContainsKey('dependencies')) {
        foreach ($dep in @($t[$libKey].dependencies.Keys)) {
          if ($removedSimpleNames -contains $dep) { $t[$libKey].dependencies.Remove($dep) | Out-Null }
        }
      }
    }
  }
  foreach ($libKey in $removedLibKeys) { $deps.libraries.Remove($libKey) | Out-Null }

  ($deps | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath $depsPath -Encoding utf8NoBOM
  Step "rewrite $appName.deps.json（移除 $($removedLibKeys.Count) 条库登记：$($removedSimpleNames -join ', ')）"
  $manifest.rewrittenFiles += "$appName.deps.json"

  ($manifest | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath $ManifestPath -Encoding utf8NoBOM
  Step "write $BackupDirName/manifest.json"

  Write-Host "OK 已导出 → $AppDir"
  Write-Host "（回滚：pwsh -File $PSCommandPath uninstall $AppDir）"
  return 0
}

# ============================================================================
#  uninstall（整份还原）
# ============================================================================
function Do-Uninstall {
  param([switch]$Quiet)
  if (-not $Quiet) { Write-Host "=== uninstall：按 manifest 整份还原 ==="; Show-Plan }
  if (-not (Test-Path -LiteralPath $ManifestPath)) { Fail "没有备份（$ManifestPath 不存在）—— 未安装？" }

  $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json -AsHashtable
  $filesRoot = Join-Path $BackupDir 'files'
  $restored = 0
  foreach ($rel in @($manifest.deletedFiles) + @($manifest.rewrittenFiles)) {
    $src = Join-Path $filesRoot $rel
    if (Test-Path -LiteralPath $src) {
      $dst = Join-Path $AppDir $rel
      $dstDir = Split-Path -Parent $dst
      if (-not (Test-Path -LiteralPath $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }
      Copy-Item -LiteralPath $src -Destination $dst -Force
      Step "restore  $rel"
      $restored++
    }
  }
  Remove-Item -LiteralPath $BackupDir -Recurse -Force
  Step "rm -r $BackupDirName"
  Info "共还原 $restored 个文件"
  Write-Host "OK 已回滚 → $AppDir"
  return 0
}

# ============================================================================
#  verify（形态断言；不依赖 Windows）
# ============================================================================
function Do-Verify {
  Write-Host "=== verify：断言产物已是「Windows 直接跑（跑官方件）」形态 ==="
  Show-Plan
  $bad = 0

  Write-Host "-- ① 框架同名件/自产 ELF 必须**不在** app-local --"
  foreach ($n in $AllDeletedNames) {
    foreach ($ext in @('.dll', '.pdb', '.so')) {
      $p = Join-Path $AppDir "$n$ext"
      if (Test-Path -LiteralPath $p) { Write-Host "  FAIL 仍在：$n$ext"; $bad++ }
    }
  }
  if ($bad -eq 0) { Write-Host "  OK  none present" }

  Write-Host "-- ② runtimeconfig 必须声明 Microsoft.WindowsDesktop.App --"
  $rc = Get-Content -LiteralPath $runtimeConfigPath -Raw | ConvertFrom-Json -AsHashtable
  $names = @($rc.runtimeOptions.frameworks | ForEach-Object { $_.name })
  Write-Host "  frameworks = [$($names -join ', ')]"
  if ($names -notcontains 'Microsoft.WindowsDesktop.App') { Write-Host "  FAIL 未声明 WindowsDesktop.App"; $bad++ }
  if ($names -notcontains 'Microsoft.NETCore.App') { Write-Host "  FAIL 未声明 NETCore.App"; $bad++ }

  Write-Host "-- ③ deps.json 不得再登记被删件 --"
  $deps = Get-Content -LiteralPath $depsPath -Raw | ConvertFrom-Json -AsHashtable
  $left = @()
  foreach ($libKey in $deps.libraries.Keys) {
    $simple = ($libKey -split '/')[0]
    if ($ManagedToDelete -contains $simple) { $left += $libKey }
  }
  if ($left.Count -gt 0) { Write-Host "  FAIL deps 仍有登记：$($left -join ', ')"; $bad++ } else { Write-Host "  OK  none registered" }

  Write-Host "-- 产物剩余（app-local .dll）--"
  Get-ChildItem -LiteralPath $AppDir -Filter *.dll -File | ForEach-Object { Write-Host "  $($_.Name)" }

  if ($bad -eq 0) { Write-Host 'VERIFY=PASS (产物形态 = 标准 Windows WPF 应用；"在 Windows 上端到端跑通"须到 Windows 机复验)' ; return 0 }
  Write-Host 'VERIFY=FAIL'; return 1
}

switch ($Action) {
  'install'   { exit (Do-Install) }
  'uninstall' { exit (Do-Uninstall) }
  'verify'    { exit (Do-Verify) }
}
