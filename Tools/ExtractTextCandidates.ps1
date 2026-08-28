param(
    [string]$GameRoot = '',
    [string]$Output = 'TranslationWork\source_candidates.tsv'
)

if ([string]::IsNullOrEmpty($GameRoot)) {
    foreach ($candidateRoot in @((Join-Path $PSScriptRoot '..'), (Join-Path $PSScriptRoot '..\..'))) {
        if (Test-Path (Join-Path $candidateRoot 'Gekko Episode of Nova_Data')) {
            $GameRoot = (Resolve-Path $candidateRoot).Path
            break
        }
    }
}
if ([string]::IsNullOrEmpty($GameRoot)) { throw 'Could not locate the game root from the tools directory.' }

if ($Output -eq 'TranslationWork\source_candidates.tsv' -and (Test-Path (Join-Path $PSScriptRoot '..\TranslationWork'))) {
    $Output = 'TranslationPatch_Archive\TranslationWork\source_candidates.tsv'
}

$asset = Join-Path $GameRoot 'Gekko Episode of Nova_Data\sharedassets0.assets'
$outPath = Join-Path $GameRoot $Output
if (-not (Test-Path -LiteralPath $asset)) { throw "Missing asset: $asset" }

# The serialized Unity asset stores StringGrid/TextAsset data as UTF-8 strings.
# This produces a reviewable candidate list; it deliberately does not modify game files.
$bytes = [IO.File]::ReadAllBytes($asset)
$text = [Text.Encoding]::UTF8.GetString($bytes)
$matches = [regex]::Matches($text, '[\u3040-\u30ff\u3400-\u9fffー！？。、「」『』]{2,}')
$seen = [Collections.Generic.HashSet[string]]::new()
$rows = foreach ($m in $matches) {
    $value = $m.Value.Trim()
    if ($value.Length -lt 2) { continue }
    if ($value -match '^(Normal|Highlighted|Pressed|Disabled|Japanese|English)$') { continue }
    if ($seen.Add($value)) {
        $escaped = $value.Replace("`r", '\\r').Replace("`n", '\\n').Replace("`t", '\\t')
        "${escaped}`t"
    }
}

$header = "source`ttranslation`tstatus"
Set-Content -LiteralPath $outPath -Value $header -Encoding UTF8
Add-Content -LiteralPath $outPath -Value $rows -Encoding UTF8
Write-Host "Wrote $($seen.Count) unique candidates to $outPath"
