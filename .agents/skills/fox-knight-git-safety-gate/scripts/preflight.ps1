[CmdletBinding()]
param(
    [ValidateSet('Audit', 'Commit', 'Push', 'Export', 'Release')]
    [string]$Mode = 'Audit',
    [string]$ProjectRoot = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
} else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}

$findings = [System.Collections.Generic.List[object]]::new()

function Add-Finding {
    param(
        [ValidateSet('FAIL', 'WARN', 'INFO')]
        [string]$Severity,
        [string]$Code,
        [string]$Path,
        [string]$Message
    )
    $findings.Add([pscustomobject]@{
        Severity = $Severity
        Code = $Code
        Path = $Path
        Message = $Message
    })
}

function Get-RelativePath {
    param([string]$FullName)
    $rootPrefix = $ProjectRoot.TrimEnd('\') + '\'
    if (-not $FullName.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside project root: $FullName"
    }
    return $FullName.Substring($rootPrefix.Length).Replace('\', '/')
}

function Test-ProjectIgnoredPath {
    param([string]$RelativePath)
    $relative = $RelativePath.Replace('\', '/')
    if ($relative -match '^(\.git|\.godot|android|build|backups)/') { return $true }
    if ($relative -match '^work/export_templates/') { return $true }
    if ($relative -match '^work/.*\.(log|png|json|docx)$') { return $true }
    if ($relative -match '(^|/)\.env($|\.)') { return $true }
    if ($relative -match '\.(pem|key|pfx|p12)$') { return $true }
    return $false
}

function Get-CandidateFiles {
    $all = Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File -Force -ErrorAction SilentlyContinue
    return @($all | Where-Object { -not (Test-ProjectIgnoredPath (Get-RelativePath $_.FullName)) })
}

function Test-GitTracked {
    param([string]$RelativePath)
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot '.git'))) { return $false }
    & git -c "safe.directory=$ProjectRoot" -C $ProjectRoot ls-files --error-unmatch -- $RelativePath *> $null
    return $LASTEXITCODE -eq 0
}

Write-Output "MODE | $Mode"
Write-Output "ROOT | $ProjectRoot"

$candidateFiles = Get-CandidateFiles
$textExtensions = @(
    '.cfg', '.gd', '.gitignore', '.godot', '.import', '.ini', '.json', '.md',
    '.ps1', '.py', '.svg', '.toml', '.tres', '.tscn', '.txt', '.xml', '.yaml', '.yml'
)

$secretPatterns = @(
    @{ Code = 'OPENAI_KEY'; Pattern = 'sk-[A-Za-z0-9_-]{20,}' },
    @{ Code = 'GITHUB_TOKEN'; Pattern = '(github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,})' },
    @{ Code = 'AWS_ACCESS_KEY'; Pattern = 'AKIA[0-9A-Z]{16}' },
    @{ Code = 'GOOGLE_API_KEY'; Pattern = 'AIza[0-9A-Za-z_-]{30,}' },
    @{ Code = 'SLACK_TOKEN'; Pattern = 'xox[baprs]-[A-Za-z0-9-]{10,}' },
    @{ Code = 'PRIVATE_KEY'; Pattern = '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' },
    @{ Code = 'JWT_TOKEN'; Pattern = 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' }
)

foreach ($file in $candidateFiles) {
    $relative = Get-RelativePath $file.FullName
    if ($file.Length -gt 50MB) {
        Add-Finding 'WARN' 'LARGE_FILE' $relative 'Candidate Git file is larger than 50 MB; review whether it belongs in source control.'
    }

    $extension = [IO.Path]::GetExtension($file.Name).ToLowerInvariant()
    if ($file.Name -eq '.gitignore') { $extension = '.gitignore' }
    if ($textExtensions -notcontains $extension) { continue }

    try {
        $content = [IO.File]::ReadAllText($file.FullName)
    } catch {
        Add-Finding 'WARN' 'TEXT_READ_FAILED' $relative 'Text-like file could not be scanned.'
        continue
    }

    foreach ($definition in $secretPatterns) {
        if ([regex]::IsMatch($content, $definition.Pattern)) {
            Add-Finding 'FAIL' $definition.Code $relative 'Potential credential detected. The matched value is intentionally not printed.'
        }
    }

    if ([regex]::IsMatch($content, '(?i)\b(api[_-]?key|client[_-]?secret|access[_-]?token|password|passwd)\b\s*[:=]\s*["''][^"'']{8,}["'']')) {
        Add-Finding 'WARN' 'GENERIC_SECRET_ASSIGNMENT' $relative 'A secret-like assignment requires manual review.'
    }
    if ([regex]::IsMatch($content, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')) {
        Add-Finding 'WARN' 'EMAIL_ADDRESS' $relative 'An email-like value is present; confirm that publication is intentional.'
    }
    if ([regex]::IsMatch($content, '(?i)[A-Z]:[\\/]Users[\\/][^\\/\s]+')) {
        Add-Finding 'WARN' 'USER_PROFILE_PATH' $relative 'A Windows user-profile path is present; remove or generalize it before publication.'
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
foreach ($docx in @($candidateFiles | Where-Object { $_.Extension -ieq '.docx' })) {
    $relative = Get-RelativePath $docx.FullName
    $archive = $null
    try {
        $archive = [IO.Compression.ZipFile]::OpenRead($docx.FullName)
        $entry = $archive.GetEntry('docProps/core.xml')
        if ($null -eq $entry) { continue }
        $reader = [IO.StreamReader]::new($entry.Open())
        try { [xml]$core = $reader.ReadToEnd() } finally { $reader.Dispose() }
        $creator = [string]$core.coreProperties.creator
        $modifiedBy = [string]$core.coreProperties.lastModifiedBy
        $genericPattern = '^(|FoxKnight|Codex|LibreOffice|python-docx)$'
        if ($creator -notmatch $genericPattern -or $modifiedBy -notmatch $genericPattern) {
            Add-Finding 'WARN' 'DOCX_AUTHOR_METADATA' $relative 'DOCX contains non-generic author metadata; the value is intentionally not printed.'
        }
    } catch {
        Add-Finding 'WARN' 'DOCX_METADATA_READ_FAILED' $relative 'DOCX metadata could not be inspected.'
    } finally {
        if ($null -ne $archive) { $archive.Dispose() }
    }
}

$sensitiveFiles = Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match '(?i)^(\.env($|\.)|export_credentials\.cfg$|.+\.(pem|key|pfx|p12)$)'
}
foreach ($file in @($sensitiveFiles)) {
    $relative = Get-RelativePath $file.FullName
    if (Test-GitTracked $relative) {
        Add-Finding 'FAIL' 'TRACKED_SENSITIVE_FILE' $relative 'Sensitive file type is tracked by Git.'
    } else {
        Add-Finding 'INFO' 'LOCAL_SENSITIVE_FILE' $relative 'Sensitive-looking local file is untracked; keep it ignored and inspect manually.'
    }
}

$presetPath = Join-Path $ProjectRoot 'export_presets.cfg'
if (Test-Path -LiteralPath $presetPath) {
    $presetContent = [IO.File]::ReadAllText($presetPath)
    if ([regex]::IsMatch($presetContent, '(?m)^custom_template/(debug|release)="(?:[A-Z]:/|/)')) {
        $severity = if ($Mode -in @('Commit', 'Push')) { 'FAIL' } else { 'WARN' }
        Add-Finding $severity 'ABSOLUTE_EXPORT_TEMPLATE' 'export_presets.cfg' 'A machine-specific custom export template path is configured.'
    }
    foreach ($required in @('backups/*', 'docs/*', 'work/*', 'tests/*', '.agents/*', 'agents/*')) {
        if (-not $presetContent.Contains($required)) {
            Add-Finding 'WARN' 'EXPORT_EXCLUDE_MISSING' 'export_presets.cfg' "Export exclusion is missing: $required"
        }
    }
}

$hasGit = Test-Path -LiteralPath (Join-Path $ProjectRoot '.git')
if ($Mode -in @('Commit', 'Push') -and -not $hasGit) {
    Add-Finding 'FAIL' 'GIT_NOT_INITIALIZED' '.git' 'Requested mode requires an initialized Git repository.'
}

if ($hasGit) {
    $email = (& git -c "safe.directory=$ProjectRoot" -C $ProjectRoot config --local user.email 2>$null)
    if ([string]::IsNullOrWhiteSpace(($email -join ''))) {
        Add-Finding 'WARN' 'GIT_EMAIL_UNSET' '.git/config' 'Repository-local commit email is not configured.'
    } elseif (($email -join '') -notmatch 'noreply') {
        Add-Finding 'WARN' 'GIT_EMAIL_VISIBLE' '.git/config' 'Commit email is not a noreply address; confirm that publication is intentional.'
    }

    $configuredRemotes = @(& git -c "safe.directory=$ProjectRoot" -C $ProjectRoot remote)
    $remoteUrls = @()
    if ($configuredRemotes -contains 'origin') {
        $remoteUrls = @(& git -c "safe.directory=$ProjectRoot" -C $ProjectRoot remote get-url --all origin 2>$null)
    }
    foreach ($remoteUrl in $remoteUrls) {
        if ($remoteUrl -match '^https?://[^/@:]+:[^/@]+@') {
            Add-Finding 'FAIL' 'CREDENTIAL_IN_REMOTE_URL' '.git/config' 'Remote URL appears to contain embedded credentials.'
        }
    }

    if ($Mode -eq 'Commit') {
        $staged = @(& git -c "safe.directory=$ProjectRoot" -C $ProjectRoot diff --cached --name-only --diff-filter=ACMR)
        if ($staged.Count -eq 0) {
            Add-Finding 'WARN' 'NO_STAGED_FILES' '.git/index' 'No staged files are available for commit review.'
        } else {
            Add-Finding 'INFO' 'STAGED_FILE_COUNT' '.git/index' "$($staged.Count) file(s) are staged; review git diff --cached before committing."
        }
    }

    if ($Mode -eq 'Push') {
        if ($configuredRemotes.Count -eq 0) {
            Add-Finding 'WARN' 'NO_REMOTE' '.git/config' 'No Git remote is configured yet.'
        }
    }
}

if ($Mode -in @('Export', 'Release')) {
    $pckPath = Join-Path $ProjectRoot 'build\windows\FoxKnight.pck'
    if (-not (Test-Path -LiteralPath $pckPath)) {
        Add-Finding 'WARN' 'PCK_NOT_FOUND' 'build/windows/FoxKnight.pck' 'No Windows PCK is available for binary inspection.'
    } else {
        $binaryText = [Text.Encoding]::Latin1.GetString([IO.File]::ReadAllBytes($pckPath))
        foreach ($definition in $secretPatterns) {
            if ([regex]::IsMatch($binaryText, $definition.Pattern)) {
                Add-Finding 'FAIL' "PCK_$($definition.Code)" 'build/windows/FoxKnight.pck' 'Potential credential detected in PCK; the matched value is intentionally not printed.'
            }
        }
        if ([regex]::IsMatch($binaryText, '(?i)[A-Z]:[\\/]Users[\\/][^\\/\s]+')) {
            Add-Finding 'FAIL' 'PCK_USER_PROFILE_PATH' 'build/windows/FoxKnight.pck' 'A Windows user-profile path appears in the PCK.'
        }
    }

    $exportLog = Join-Path $ProjectRoot 'work\windows_export.log'
    if (Test-Path -LiteralPath $exportLog) {
        $logContent = [IO.File]::ReadAllText($exportLog)
        if ([regex]::IsMatch($logContent, 'res://(docs|work|backups|tests|agents|\.agents|build)/')) {
            Add-Finding 'FAIL' 'UNINTENDED_EXPORT_PATH' 'work/windows_export.log' 'Export log shows a path that should not be distributed.'
        }
    }
}

$rank = @{ FAIL = 0; WARN = 1; INFO = 2 }
foreach ($finding in @($findings | Sort-Object @{ Expression = { $rank[$_.Severity] } }, Code, Path)) {
    Write-Output "$($finding.Severity) | $($finding.Code) | $($finding.Path) | $($finding.Message)"
}

$failCount = @($findings | Where-Object Severity -eq 'FAIL').Count
$warnCount = @($findings | Where-Object Severity -eq 'WARN').Count
if ($failCount -gt 0) {
    Write-Output "RESULT | FAIL | $failCount failure(s), $warnCount warning(s)"
    exit 2
}
if ($warnCount -gt 0) {
    Write-Output "RESULT | WARN | $warnCount warning(s)"
    exit 0
}
Write-Output 'RESULT | PASS | Git safety preflight'
exit 0
