$ErrorActionPreference = "Stop"
$root = "C:\Users\Admin\Documents\MALT\10_14_Accor"
$htmlPath = Join-Path $root "presentation.html"
$imgFile = Get-ChildItem -Path $root -Filter "Architecture Snowflake*.png" | Select-Object -First 1
$imgPath = $imgFile.FullName
$lockedPath = Join-Path $root "presentation-client-locked.html"
$pdfPath = Join-Path $root "Accor_Data_Partnerships_Proposition_Approche.pdf"

$html = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)

# Remove old @media print block if present so we can insert the perfected one
$html = [regex]::Replace($html, '\s*@media print \{[\s\S]*?\}\s*</style>', "`n</style>")

$printCss = @"

@media print {
    @page {
        size: 16in 9in;
        margin: 0;
    }
    html, body {
        width: 16in !important;
        height: auto !important;
        overflow: visible !important;
        background: var(--bg-primary) !important;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
        scroll-snap-type: none !important;
    }
    .deck-topbar, .nav-dots, .progress-bar {
        display: none !important;
    }
    .slide {
        width: 16in !important;
        height: 9in !important;
        min-height: 9in !important;
        max-height: 9in !important;
        page-break-after: always !important;
        break-after: page !important;
        overflow: hidden !important;
    }
    .slide-content {
        max-width: 100% !important;
        width: 100% !important;
        height: 9in !important;
    }
    .slide:last-of-type {
        page-break-after: auto !important;
        break-after: auto !important;
    }
    .grid-2 {
        grid-template-columns: repeat(2, 1fr) !important;
    }
    .grid-3 {
        grid-template-columns: repeat(3, 1fr) !important;
    }
    .grid-4, .kpi-strip {
        grid-template-columns: repeat(4, 1fr) !important;
    }
    .reveal {
        opacity: 1 !important;
        transform: none !important;
        transition: none !important;
    }
}
</style>
"@

$idx = $html.IndexOf("</style>")
if ($idx -ge 0) {
    $html = $html.Substring(0, $idx) + $printCss + $html.Substring($idx + 8)
    [System.IO.File]::WriteAllText($htmlPath, $html, (New-Object System.Text.UTF8Encoding($false)))
}

$locked = $html

# Embed PNG as base64 data URI so the locked file is 100% standalone
$imgBytes = [System.IO.File]::ReadAllBytes($imgPath)
$b64 = [Convert]::ToBase64String($imgBytes)
$dataUri = "data:image/png;base64,$b64"
$locked = $locked.Replace("Architecture%20Snowflake%20de%20Mon%C3%A9tisation%20et%20d%E2%80%99%C3%89change%20de%20Donn%C3%A9es%20Accor.png", $dataUri)

# Cleanly remove only the [U] hint in Slide 01 footer
$locked = [regex]::Replace($locked, '\s*\u00b7\s*\[U\]\s*d\u00e9voiler les zones flout\u00e9es', '')
$locked = [regex]::Replace($locked, 'title="Cliquer pour d[^"]*"', 'title="Contenu reserve a la soutenance"')

# Disable cursor pointer & unlock CSS/JS in locked version
$locked = $locked.Replace("cursor: pointer;", "cursor: default;")
$locked = [regex]::Replace($locked, 'initTeasers\(\)\s*\{[\s\S]*?\n    \}', "initTeasers() {`n        // Locked client version: teaser unlocking disabled`n    }")
$locked = [regex]::Replace($locked, "\s*\}\s*else if \(e\.key\.toLowerCase\(\) === 'u'\)\s*\{\s*document\.body\.classList\.toggle\('unlock-all-teasers'\);", "")

function Scramble-Text([string]$inner) {
    $parts = [regex]::Split($inner, '(<[^>]+>|&[a-zA-Z0-9#]+;)')
    $sb = New-Object System.Text.StringBuilder
    foreach ($p in $parts) {
        if ($p.StartsWith("<") -or $p.StartsWith("&")) {
            [void]$sb.Append($p)
        } else {
            foreach ($ch in $p.ToCharArray()) {
                $code = [int][char]$ch
                if ($code -ge 97 -and $code -le 122) {
                    [void]$sb.Append([char]((($code - 97 + 13) % 26) + 97))
                } elseif ($code -ge 65 -and $code -le 90) {
                    [void]$sb.Append([char]((($code - 65 + 13) % 26) + 65))
                } elseif ($code -ge 48 -and $code -le 57) {
                    [void]$sb.Append([char]((($code - 48 + 5) % 10) + 48))
                } elseif ($code -gt 127) {
                    [void]$sb.Append('e')
                } else {
                    [void]$sb.Append($ch)
                }
            }
        }
    }
    return $sb.ToString()
}

$locked = [regex]::Replace($locked, '(<(?:span|li)\s+class="blur-target">)([\s\S]*?)(</(?:span|li)>)', {
    param($m)
    return $m.Groups[1].Value + (Scramble-Text $m.Groups[2].Value) + $m.Groups[3].Value
})

[System.IO.File]::WriteAllText($lockedPath, $locked, (New-Object System.Text.UTF8Encoding($false)))
$len = (Get-Item $lockedPath).Length
Write-Host "Wrote locked HTML: $lockedPath ($len bytes)"

$p = Start-Process -FilePath "C:\Program Files\Google\Chrome\Application\chrome.exe" -ArgumentList @(
    "--headless=new",
    "--user-data-dir=$env:TEMP\chrome-pdf-out3",
    "--window-size=1920,1080",
    "--disable-gpu",
    "--no-pdf-header-footer",
    "--print-to-pdf=$pdfPath",
    "file:///C:/Users/Admin/Documents/MALT/10_14_Accor/presentation-client-locked.html"
) -Wait -PassThru

Write-Host "Chrome exit code: $($p.ExitCode)"
if (Test-Path $pdfPath) {
    $pdfLen = (Get-Item $pdfPath).Length
    Write-Host "Wrote PDF: $pdfPath ($pdfLen bytes)"
}
