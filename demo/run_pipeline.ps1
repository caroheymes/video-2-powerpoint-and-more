<#
.SYNOPSIS
    Pipeline Automatisé de Transcription Vidéo & Génération de Decks Multi-Formats.
.DESCRIPTION
    Transforme une vidéo MP4 longue en :
      - Transcription intégrale Markdown (Whisper local)
      - Synthèse exécutive structurée en français (Gemini ou Mistral)
      - Article de fond & Mode d'emploi opérationnel Word (.docx)
      - Diapositives PowerPoint widescreen 16:9 (.pptx)
      - Deck Web interactif zero-dependency (.html) et export PDF 16:9.
.EXAMPLE
    .\run_pipeline.ps1 -VideoPath ".\reunion.mp4"
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$VideoPath = "",

    [ValidateSet("tiny", "base", "small", "medium", "large-v3-turbo")]
    [string]$ModelSize = "medium",

    [string]$OutputDir = "output",

    [ValidateSet("gemini", "mistral", "")]
    [string]$Provider = "",

    [string]$ApiKey = "",

    [switch]$SkipTranscription
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  PIPELINE DE TRAITEMENT VIDÉO & LIVRABLES STRATÉGIQUES (ECC)   " -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# 1. Sélection ou Détection du Fichier Vidéo
# ------------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($VideoPath)) {
    $mp4Files = Get-ChildItem -Path $ScriptDir -Filter "*.mp4"
    if ($mp4Files.Count -eq 1) {
        $VideoPath = $mp4Files[0].FullName
        Write-Host " [Auto-détection] Fichier vidéo trouvé : $($mp4Files[0].Name)" -ForegroundColor Green
    } elseif ($mp4Files.Count -gt 1) {
        Write-Host "Plusieurs fichiers MP4 trouvés dans le dossier :" -ForegroundColor Yellow
        for ($i = 0; $i -lt $mp4Files.Count; $i++) {
            Write-Host "  [$($i+1)] $($mp4Files[$i].Name)"
        }
        $sel = Read-Host "`nSélectionnez le numéro de la vidéo à traiter"
        $idx = [int]$sel - 1
        $VideoPath = $mp4Files[$idx].FullName
    } else {
        Write-Host "Veuillez entrer le chemin ou glisser-déposer le fichier vidéo MP4 :" -ForegroundColor Yellow
        $VideoPath = (Read-Host "Chemin vidéo").Trim('"').Trim("'")
    }
}

if (!(Test-Path $VideoPath)) {
    Write-Error "Le fichier vidéo '$VideoPath' est introuvable."
    exit 1
}

# ------------------------------------------------------------------------------
# 2. Gestion et Saisie de la Clé d'API LLM (Gemini ou Mistral)
# ------------------------------------------------------------------------------
function Get-OrPromptApiKey {
    param([string]$ArgKey, [string]$ArgProvider)

    # 1. Si passée en argument
    if ($ArgKey) {
        $prov = if ($ArgProvider) { $ArgProvider } elseif ($ArgKey.StartsWith("AIzaSy")) { "gemini" } else { "mistral" }
        return @{ Provider = $prov; Key = $ArgKey }
    }

    # 2. Lecture du fichier local .env si existant
    $envFile = Join-Path $ScriptDir ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.+)\s*$') {
                $val = $matches[2].Trim().Trim('"').Trim("'")
                [Environment]::SetEnvironmentVariable($matches[1], $val, "Process")
            }
        }
    }

    # 3. Variables d'environnement système
    if ($env:GEMINI_API_KEY) {
        Write-Host " [Auth] Clé Gemini détectée via variable d'environnement." -ForegroundColor Green
        return @{ Provider = "gemini"; Key = $env:GEMINI_API_KEY }
    }
    if ($env:MISTRAL_API_KEY) {
        Write-Host " [Auth] Clé Mistral détectée via variable d'environnement." -ForegroundColor Green
        return @{ Provider = "mistral"; Key = $env:MISTRAL_API_KEY }
    }

    # 4. Saisie interactive conviviale
    Write-Host "`n----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "  CONFIGURATION DE LA CLÉ D'ACCÈS IA (LLM)" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Une clé d'accès API est nécessaire pour synthétiser le transcript de 2h."
    Write-Host "  [1] Google Gemini (Recommandé, gratuit sur aistudio.google.com)"
    Write-Host "  [2] Mistral AI (console.mistral.ai)"
    
    $choix = Read-Host "`nChoisissez votre fournisseur [1 pour Gemini, 2 pour Mistral]"
    $prov = if ($choix -eq "2") { "mistral" } else { "gemini" }

    Write-Host "Collez votre clé d'API $prov (clic droit ou Ctrl+V) : " -NoNewline -ForegroundColor Green
    $secure = Read-Host -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

    if ([string]::IsNullOrWhiteSpace($plain)) {
        Write-Error "Erreur : La clé d'API ne peut pas être vide."
        exit 1
    }

    $save = Read-Host "`nEnregistrer cette clé dans un fichier .env local pour les prochaines fois ? (O/N)"
    if ($save -match '^[oOyY]') {
        $varName = if ($prov -eq "gemini") { "GEMINI_API_KEY" } else { "MISTRAL_API_KEY" }
        Add-Content -Path $envFile -Value "$varName=$plain"
        Write-Host " Clé enregistrée dans .env avec succès !" -ForegroundColor Green
    }

    return @{ Provider = $prov; Key = $plain }
}

$auth = Get-OrPromptApiKey -ArgKey $ApiKey -ArgProvider $Provider

# ------------------------------------------------------------------------------
# 3. Auto-Bootstrapping de l'Environnement Virtuel via `uv`
# ------------------------------------------------------------------------------
Write-Host "`n[Initialisation] Vérification de l'environnement Python..." -ForegroundColor Cyan

# Résolution de l'exécutable uv
$uvExe = Get-Command "uv" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (!$uvExe -and (Test-Path "C:\Users\Admin\.local\bin\uv.exe")) {
    $uvExe = "C:\Users\Admin\.local\bin\uv.exe"
}

if (!$uvExe) {
    Write-Error "L'utilitaire 'uv' est requis. Téléchargement ou installation introuvable."
    exit 1
}

$venvPath = Join-Path $ScriptDir ".venv"
if (!(Test-Path $venvPath)) {
    Write-Host "Création d'un environnement virtuel isolé (.venv)..." -ForegroundColor Yellow
    & $uvExe venv $venvPath | Out-Null
}

$venvPython = Join-Path $venvPath "Scripts\python.exe"
$reqFile = Join-Path $ScriptDir "requirements.txt"

# Installation/Mise à jour ultra-rapide des dépendances
Write-Host "Vérification des dépendances (faster-whisper, scenedetect, python-pptx)..." -ForegroundColor Yellow
& $uvExe pip install -r $reqFile --python $venvPython --quiet

# ------------------------------------------------------------------------------
# 4. Lancement du Pipeline
# ------------------------------------------------------------------------------
Write-Host "`nLancement du pipeline de traitement..." -ForegroundColor Green

$pipelineArgs = @(
    (Join-Path $ScriptDir "pipeline.py"),
    "--video", $VideoPath,
    "--output", (Join-Path $ScriptDir $OutputDir),
    "--model", $ModelSize,
    "--provider", $auth.Provider,
    "--api-key", $auth.Key
)

if ($SkipTranscription) {
    $pipelineArgs += "--skip-transcription"
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()

& $venvPython @pipelineArgs

$sw.Stop()
$elapsed = [string]::Format("{0:d2}m {1:d2}s", $sw.Elapsed.Minutes, $sw.Elapsed.Seconds)

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   PIPELINE TERMINÉ AVEC SUCCÈS EN $elapsed !                  " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host "Livrables générés dans : $(Join-Path $ScriptDir $OutputDir)" -ForegroundColor Cyan
