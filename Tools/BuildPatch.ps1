$ErrorActionPreference = 'Stop'
$rootCandidates = @(
    (Join-Path $PSScriptRoot '..'),
    (Join-Path $PSScriptRoot '..\..')
)
$root = $null
foreach ($candidateRoot in $rootCandidates) {
    if (Test-Path (Join-Path $candidateRoot 'Gekko Episode of Nova_Data')) {
        $root = (Resolve-Path $candidateRoot).Path
        break
    }
}
if (-not $root) { throw 'Could not locate the game root from the tools directory.' }
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$out = Join-Path $root 'BepInEx\plugins\GekkoNovaPatch.dll'
& (Join-Path $PSScriptRoot 'ValidateTranslations.ps1')
$args = @('/nologo', '/target:library', "/out:$out")
foreach ($ref in @(
  'BepInEx\core\BepInEx.dll',
  'BepInEx\core\0Harmony.dll',
  'Gekko Episode of Nova_Data\Managed\netstandard.dll',
  'Gekko Episode of Nova_Data\Managed\UnityEngine.dll',
  'Gekko Episode of Nova_Data\Managed\UnityEngine.CoreModule.dll',
  'Gekko Episode of Nova_Data\Managed\UnityEngine.TextRenderingModule.dll',
  'Gekko Episode of Nova_Data\Managed\UnityEngine.UI.dll')) {
  $args += "/reference:$((Join-Path $root $ref))"
}
$args += (Join-Path $PSScriptRoot 'GekkoNovaPatch.cs')
& $compiler @args
if ($LASTEXITCODE -ne 0) { throw "C# compiler failed with exit code $LASTEXITCODE" }
Write-Host "Built $out"
