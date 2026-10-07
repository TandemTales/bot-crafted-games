param([Parameter(Mandatory=$true)][string]$PackageDirectory)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'build'))
$packageRoot = [IO.Path]::GetFullPath($PackageDirectory)
if (-not $packageRoot.StartsWith($buildRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Package must be within this project build directory.' }
$manifestPath = Join-Path $packageRoot 'manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if (-not $manifest.validation.native_navigation_passed) { throw 'Native navigation validation is required before promotion.' }
$sourceExe = Join-Path $packageRoot 'Bramblecrown.exe'
if ((Get-FileHash -LiteralPath $sourceExe -Algorithm SHA256).Hash -ne $manifest.exe_sha256) { throw 'Package executable does not match its validated manifest.' }
$latestRoot = Join-Path $buildRoot 'latest'
$liveRoot = Join-Path $latestRoot 'windows'
$liveExe = Join-Path $liveRoot 'Bramblecrown.exe'
$running = @(Get-Process Bramblecrown -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $liveExe })
if ($running.Count) { throw 'Latest build is running. Close it before promoting; current latest remains unchanged.' }
New-Item -ItemType Directory -Path $latestRoot -Force | Out-Null
$token = Get-Date -Format 'yyyyMMdd-HHmmss'
$stageRoot = Join-Path $latestRoot ('.windows-staging-' + $token)
$previousRoot = Join-Path $latestRoot ('previous-windows-' + $token)
foreach ($target in @($stageRoot,$liveRoot,$previousRoot)) {
    $resolvedTarget = [IO.Path]::GetFullPath($target)
    if (-not $resolvedTarget.StartsWith($latestRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe promotion target.' }
}
New-Item -ItemType Directory -Path $stageRoot | Out-Null
foreach ($name in @('Bramblecrown.exe','README.txt','manifest.json')) {
    Copy-Item -LiteralPath (Join-Path $packageRoot $name) -Destination (Join-Path $stageRoot $name)
}
if ((Get-FileHash -LiteralPath (Join-Path $stageRoot 'Bramblecrown.exe')).Hash -ne $manifest.exe_sha256) { throw 'Staged executable hash mismatch; latest was not changed.' }
$hadPrevious = Test-Path -LiteralPath $liveRoot
if ($hadPrevious) { Move-Item -LiteralPath $liveRoot -Destination $previousRoot }
try { Move-Item -LiteralPath $stageRoot -Destination $liveRoot }
catch {
    if ($hadPrevious -and -not (Test-Path -LiteralPath $liveRoot)) { Move-Item -LiteralPath $previousRoot -Destination $liveRoot }
    throw
}
Write-Output ('LATEST_LAUNCH=' + $liveExe)
Write-Output ('SHA256=' + $manifest.exe_sha256)
