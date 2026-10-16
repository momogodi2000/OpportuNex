<#
.SYNOPSIS
  Fills the table of contents and page numbers of the user guide with Microsoft Word, and optionally exports a PDF.

.DESCRIPTION
  python-docx writes the table of contents as a field that only Word can compute. This script opens the .docx in
  Word (hidden), updates every field, saves it, and with -Pdf also writes a PDF next to the given path.
  Without Word, open the .docx and use "Update field" on the table of contents instead.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File documentation\user-guide\tools\finalize_with_word.ps1 -Pdf build\guide.pdf
#>
param(
    [string]$Docx = "documentation\user-guide\Guide_Utilisateur_Opportunex.docx",
    [string]$Pdf
)
$ErrorActionPreference = "Stop"
$path = (Resolve-Path $Docx).Path
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
# Word records its user name as "last modified by": use the guide's author, then restore the setting.
$previousUser = $word.UserName
$word.UserName = "Momo Godi Yvan"
try {
    $doc = $word.Documents.Open($path)
    foreach ($toc in $doc.TablesOfContents) { $toc.Update() }
    $doc.Fields.Update() | Out-Null
    foreach ($toc in $doc.TablesOfContents) { $toc.Update() }   # page numbers settle after the first pass
    $doc.Save()
    if ($Pdf) {
        $target = [IO.Path]::GetFullPath($Pdf)
        New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
        $doc.ExportAsFixedFormat($target, 17)   # wdExportFormatPDF
        Write-Host "PDF: $target"
    }
    Write-Host "pages: $($doc.ComputeStatistics(2))"
    $doc.Close()
} finally {
    $word.UserName = $previousUser
    $word.Quit()
}
# Word stamps the signed-in Office account as "last modified by": set it back to the guide's author.
$python = Join-Path $PSScriptRoot "..\..\..\engine\.venv\Scripts\python.exe"
& $python (Join-Path $PSScriptRoot "..\build_guide.py") --metadata-only
