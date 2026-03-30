$ErrorActionPreference = 'Stop'

$projectDoc = if ($env:PROJECT_DOC) { $env:PROJECT_DOC } else { 'AGENTS.md' }
$contextMapSection = ''
$repoRoot = (Get-Location).Path

function Get-CleanRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullName
    )

    $relative = $FullName
    if ($relative.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $relative.Substring($repoRoot.Length)
    }

    return $relative.TrimStart('\', '/').Replace('\', '/')
}

if (Test-Path -LiteralPath $projectDoc) {
    $inContextMap = $false
    foreach ($line in Get-Content -LiteralPath $projectDoc) {
        if ($line -match '^## Context Map') {
            $inContextMap = $true
            continue
        }

        if ($inContextMap -and $line -match '^##') {
            break
        }

        if ($inContextMap) {
            $contextMapSection += "$line`n"
        }
    }
}

Write-Output '--- SCAN START ---'
Write-Output 'SIGNAL:GHOST_CHECK'

if (Test-Path -LiteralPath $projectDoc) {
    $paths = [System.Collections.Generic.HashSet[string]]::new()
    $pattern = '(\./|[a-zA-Z0-9._-]+/)[a-zA-Z0-9._/-]+\.(ts|js|json|md|py|sh|ps1)'

    foreach ($line in Get-Content -LiteralPath $projectDoc) {
        foreach ($match in [regex]::Matches($line, $pattern)) {
            [void]$paths.Add($match.Value)
        }
    }

    foreach ($path in ($paths | Sort-Object)) {
        $parent = Split-Path -Parent $path
        $parentExists = [string]::IsNullOrEmpty($parent) -or (Test-Path -LiteralPath $parent -PathType Container)
        if (-not (Test-Path -LiteralPath $path) -and $parentExists) {
            Write-Output "DEAD_LINK:$path"
        }
    }
}

Get-ChildItem -Recurse -File -Include *.ts,*.js,*.json,*.md |
    Where-Object {
        $_.FullName -notmatch '[\\/]\.' -and $_.FullName -notmatch '[\\/]node_modules[\\/]'
    } |
    ForEach-Object {
        $cleanPath = Get-CleanRelativePath -FullName $_.FullName
        $tokenEst = [int]($_.Length / 4)
        $lineCount = (Get-Content -LiteralPath $_.FullName | Measure-Object -Line).Lines
        $escapedPath = [regex]::Escape($cleanPath)
        $escapedBaseName = [regex]::Escape($_.Name)
        $inMap = $contextMapSection -match $escapedPath -or $contextMapSection -match $escapedBaseName

        if (-not $inMap -and ($tokenEst -gt 500 -or $lineCount -gt 150)) {
            Write-Output "SIGNAL:DEBT|FILE:$cleanPath|TOKENS:$tokenEst|LINES:$lineCount"
        }
    }

Write-Output '--- SCAN COMPLETE ---'
