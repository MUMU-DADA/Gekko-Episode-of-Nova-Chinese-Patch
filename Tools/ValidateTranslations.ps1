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
$candidateCandidates = @(
    (Join-Path $root 'TranslationWork\serialized_candidates.tsv'),
    (Join-Path $PSScriptRoot '..\TranslationWork\serialized_candidates.tsv')
)
$candidatePath = $candidateCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $candidatePath) { throw 'Could not locate serialized_candidates.tsv.' }
$pluginPath = Join-Path $root 'BepInEx\plugins'

$candidates = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
Get-Content $candidatePath | Select-Object -Skip 1 | ForEach-Object {
    $parts = $_.Split("`t", 2)
    if ($parts.Count -eq 0) { return }

    $source = $parts[0]
    [void]$candidates.Add($source)

    # StringGrid assets are serialized as escaped TSV blobs. The runtime UI
    # receives values from their Japanese column rather than the whole blob.
    $withoutBom = $source.TrimStart([char]0xFEFF)
    if (-not $withoutBom.StartsWith('Key\tJapanese\tEnglish')) { return }

    $rowSeparator = if ($withoutBom.Contains('\r\n')) { '\r\n' } else { '\n' }
    $rows = $withoutBom.Split([string[]]@($rowSeparator), [StringSplitOptions]::None)
    foreach ($row in $rows | Select-Object -Skip 1) {
        $columns = $row.Split([string[]]@('\t'), [StringSplitOptions]::None)
        if ($columns.Count -lt 2 -or [string]::IsNullOrEmpty($columns[1])) { continue }
        $japanese = $columns[1].Replace('\r', "`r").Replace('\n', "`n").Replace('\t', "`t").Replace('\\', '\')
        [void]$candidates.Add($japanese)
    }
}

$errors = New-Object 'System.Collections.Generic.List[string]'
$translations = @{}
$entryCount = 0

Get-ChildItem $pluginPath -Filter 'GekkoNova_*.tsv' | Sort-Object Name | ForEach-Object {
    $file = $_
    $lineNumber = 0
    Get-Content $file.FullName | ForEach-Object {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($_) -or $_.StartsWith('#')) { return }
        $entryCount++
        $parts = $_.Split("`t", 2)
        if ($parts.Count -ne 2 -or [string]::IsNullOrEmpty($parts[0]) -or [string]::IsNullOrEmpty($parts[1])) {
            $errors.Add("$($file.Name):$lineNumber invalid TSV columns")
            return
        }

        $source = $parts[0]
        $translated = $parts[1]
        $isStoryText = $source.StartsWith('「') -or $source.StartsWith('（')
        if ($isStoryText -and -not $candidates.Contains($source)) {
            $errors.Add("$($file.Name):$lineNumber source not found in serialized candidates")
        }
        if ($translations.ContainsKey($source) -and $translations[$source] -ne $translated) {
            $errors.Add("$($file.Name):$lineNumber conflicting duplicate source")
        } else {
            $translations[$source] = $translated
        }

        $sourceTags = [regex]::Matches($source, '<[^>]+>') | ForEach-Object Value
        $translatedTags = [regex]::Matches($translated, '<[^>]+>') | ForEach-Object Value
        if (($sourceTags -join '|') -ne ($translatedTags -join '|')) {
            $errors.Add("$($file.Name):$lineNumber control tag mismatch")
        }

        $sourceVariables = [regex]::Matches($source, '\{[0-9]+(?:[^}]*)?\}') | ForEach-Object Value
        $translatedVariables = [regex]::Matches($translated, '\{[0-9]+(?:[^}]*)?\}') | ForEach-Object Value
        if (($sourceVariables -join '|') -ne ($translatedVariables -join '|')) {
            $errors.Add("$($file.Name):$lineNumber variable mismatch")
        }

        $sourceBreaks = ([regex]::Matches($source, '\\n')).Count
        $translatedBreaks = ([regex]::Matches($translated, '\\n')).Count
        if ($sourceBreaks -ne $translatedBreaks) {
            $errors.Add("$($file.Name):$lineNumber newline count mismatch ($sourceBreaks != $translatedBreaks)")
        }
    }
}

Write-Host "Validated $entryCount entries in $($translations.Count) unique sources"
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "ERROR: $_" -ForegroundColor Red }
    throw "Translation validation failed with $($errors.Count) error(s)"
}
Write-Host 'Translation validation passed'
