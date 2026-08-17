param(
    [Parameter(Mandatory = $true)]
    [string]$MarkdownPath,
    [Parameter(Mandatory = $true)]
    [string]$TemplatePath,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Escape-Xml([string]$Text) {
    return [System.Security.SecurityElement]::Escape($Text)
}

function Clean-Inline-Markdown([string]$Text) {
    $value = $Text
    $value = [regex]::Replace($value, '!\[([^\]]*)\]\([^\)]*\)', '$1')
    $value = [regex]::Replace($value, '\[([^\]]+)\]\([^\)]*\)', '$1')
    $value = $value.Replace('**', '').Replace('__', '').Replace('`', '')
    return $value
}

function New-RunXml([string]$Text, [bool]$Bold = $false) {
    $runProperties = if ($Bold) { '<w:rPr><w:b/></w:rPr>' } else { '' }
    $escaped = Escape-Xml (Clean-Inline-Markdown $Text)
    return "<w:r>$runProperties<w:t xml:space=`"preserve`">$escaped</w:t></w:r>"
}

function New-ParagraphXml(
    [string]$Text,
    [string]$Style = 'Normal',
    [int]$Indent = 0,
    [bool]$Bold = $false,
    [bool]$KeepNext = $false
) {
    $paragraphProperties = "<w:pStyle w:val=`"$Style`"/>"
    if ($Indent -gt 0) {
        $paragraphProperties += "<w:ind w:left=`"$Indent`"/>"
    }
    if ($KeepNext) {
        $paragraphProperties += '<w:keepNext/>'
    }
    $run = New-RunXml $Text $Bold
    return "<w:p><w:pPr>$paragraphProperties</w:pPr>$run</w:p>"
}

function Split-TableRow([string]$Line) {
    $trimmed = $Line.Trim()
    if ($trimmed.StartsWith('|')) { $trimmed = $trimmed.Substring(1) }
    if ($trimmed.EndsWith('|')) { $trimmed = $trimmed.Substring(0, $trimmed.Length - 1) }
    return @($trimmed.Split('|') | ForEach-Object { $_.Trim() })
}

function Test-TableSeparator([string]$Line) {
    $cells = Split-TableRow $Line
    if ($cells.Count -eq 0) { return $false }
    foreach ($cell in $cells) {
        if ($cell -notmatch '^:?-{3,}:?$') { return $false }
    }
    return $true
}

function New-TableXml([object[]]$Rows) {
    $columnCount = 1
    foreach ($row in $Rows) {
        if ($row.Count -gt $columnCount) { $columnCount = $row.Count }
    }
    $tableWidth = 9360
    $cellWidth = [math]::Floor($tableWidth / $columnCount)
    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.Append('<w:tbl><w:tblPr><w:tblStyle w:val="TableGrid"/><w:tblW w:w="9360" w:type="dxa"/><w:tblLayout w:type="fixed"/><w:tblBorders><w:top w:val="single" w:sz="4" w:color="B7C9D6"/><w:left w:val="single" w:sz="4" w:color="B7C9D6"/><w:bottom w:val="single" w:sz="4" w:color="B7C9D6"/><w:right w:val="single" w:sz="4" w:color="B7C9D6"/><w:insideH w:val="single" w:sz="4" w:color="D7E1E8"/><w:insideV w:val="single" w:sz="4" w:color="D7E1E8"/></w:tblBorders></w:tblPr>')
    for ($rowIndex = 0; $rowIndex -lt $Rows.Count; $rowIndex++) {
        [void]$builder.Append('<w:tr>')
        for ($columnIndex = 0; $columnIndex -lt $columnCount; $columnIndex++) {
            $text = if ($columnIndex -lt $Rows[$rowIndex].Count) { [string]$Rows[$rowIndex][$columnIndex] } else { '' }
            $shade = if ($rowIndex -eq 0) { '<w:shd w:val="clear" w:color="auto" w:fill="DCEAF2"/>' } else { '' }
            $run = New-RunXml $text ($rowIndex -eq 0)
            [void]$builder.Append("<w:tc><w:tcPr><w:tcW w:w=`"$cellWidth`" w:type=`"dxa`"/>$shade<w:vAlign w:val=`"center`"/></w:tcPr><w:p><w:pPr><w:spacing w:after=`"40`"/></w:pPr>$run</w:p></w:tc>")
        }
        [void]$builder.Append('</w:tr>')
    }
    [void]$builder.Append('</w:tbl>')
    return $builder.ToString()
}

$markdownFullPath = (Resolve-Path -LiteralPath $MarkdownPath).Path
$templateFullPath = (Resolve-Path -LiteralPath $TemplatePath).Path
$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $outputFullPath.StartsWith($workspaceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Output must stay inside workspace: $outputFullPath"
}

$lines = Get-Content -LiteralPath $markdownFullPath -Encoding UTF8
$body = [System.Text.StringBuilder]::new()
$index = 0
while ($index -lt $lines.Count) {
    $line = [string]$lines[$index]
    if ([string]::IsNullOrWhiteSpace($line)) {
        $index++
        continue
    }

    if ($line.TrimStart().StartsWith('|') -and ($index + 1) -lt $lines.Count -and (Test-TableSeparator ([string]$lines[$index + 1]))) {
        $rows = [System.Collections.Generic.List[object]]::new()
        $rows.Add((Split-TableRow $line))
        $index += 2
        while ($index -lt $lines.Count -and ([string]$lines[$index]).TrimStart().StartsWith('|')) {
            $rows.Add((Split-TableRow ([string]$lines[$index])))
            $index++
        }
        [void]$body.Append((New-TableXml $rows.ToArray()))
        continue
    }

    if ($line -match '^(#{1,6})\s+(.+)$') {
        $level = $Matches[1].Length
        $text = $Matches[2]
        $style = if ($level -eq 1) { 'Title' } else { "Heading$($level - 1)" }
        [void]$body.Append((New-ParagraphXml $text $style 0 $false $true))
        $index++
        continue
    }

    if ($line -match '^>\s?(.*)$') {
        [void]$body.Append((New-ParagraphXml $Matches[1] 'Quote' 0 $false $false))
        $index++
        continue
    }

    if ($line -match '^\s*[-*+]\s+(.+)$') {
        [void]$body.Append((New-ParagraphXml ("• " + $Matches[1]) 'ListParagraph' 360 $false $false))
        $index++
        continue
    }

    if ($line -match '^\s*(\d+)\.\s+(.+)$') {
        [void]$body.Append((New-ParagraphXml ("$($Matches[1]). $($Matches[2])") 'ListParagraph' 360 $false $false))
        $index++
        continue
    }

    if ($line -match '^\s*---+\s*$') {
        [void]$body.Append('<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="9BAFBF"/></w:pBdr></w:pPr></w:p>')
        $index++
        continue
    }

    [void]$body.Append((New-ParagraphXml $line 'Normal' 0 $false $false))
    $index++
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$probeCopy = Join-Path $PSScriptRoot 'GDD_docx_source_copy.docx'
Copy-Item -LiteralPath $templateFullPath -Destination $probeCopy -Force
$archive = [System.IO.Compression.ZipFile]::OpenRead($probeCopy)
$documentEntry = $archive.GetEntry('word/document.xml')
$reader = [System.IO.StreamReader]::new($documentEntry.Open())
$oldDocumentXml = $reader.ReadToEnd()
$reader.Dispose()
$archive.Dispose()

$sectMatch = [regex]::Match($oldDocumentXml, '<w:sectPr[\s\S]*?</w:sectPr>')
if (-not $sectMatch.Success) {
    throw 'The template does not contain a section definition.'
}

$documentXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" mc:Ignorable="w14 wp14"><w:body>' +
    $body.ToString() + $sectMatch.Value + '</w:body></w:document>'

$scratchRoot = Join-Path $PSScriptRoot ('docx_sync_' + [guid]::NewGuid().ToString('N'))
$expandedRoot = Join-Path $scratchRoot 'expanded'
$sourceZip = Join-Path $scratchRoot 'source.zip'
$outputZip = Join-Path $scratchRoot 'output.zip'
New-Item -ItemType Directory -Path $expandedRoot -Force | Out-Null
Copy-Item -LiteralPath $probeCopy -Destination $sourceZip -Force
Expand-Archive -LiteralPath $sourceZip -DestinationPath $expandedRoot -Force
[System.IO.File]::WriteAllText((Join-Path $expandedRoot 'word\document.xml'), $documentXml, [System.Text.UTF8Encoding]::new($false))
Compress-Archive -Path (Join-Path $expandedRoot '*') -DestinationPath $outputZip -CompressionLevel Optimal
Copy-Item -LiteralPath $outputZip -Destination $outputFullPath -Force

$resolvedScratch = [System.IO.Path]::GetFullPath($scratchRoot)
if (-not $resolvedScratch.StartsWith([System.IO.Path]::GetFullPath($PSScriptRoot), [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove unexpected scratch path: $resolvedScratch"
}
Remove-Item -LiteralPath $scratchRoot -Recurse -Force
Remove-Item -LiteralPath $probeCopy -Force

$outputItem = Get-Item -LiteralPath $outputFullPath
Write-Output "DOCX_SYNC_OK | $($outputItem.FullName) | $($outputItem.Length) bytes"
