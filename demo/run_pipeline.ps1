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

    [ValidateSet("gemini", "mistral", "openai", "")]
    [string]$Provider = "",

    [string]$ApiKey = "",

    [switch]$SkipTranscription
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Masquer les avertissements techniques parasites Hugging Face / Symlinks sur Windows
$env:HF_HUB_DISABLE_SYMLINKS_WARNING = "1"
$env:PYTHONWARNINGS = "ignore"
$env:TOKENIZERS_PARALLELISM = "false"

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
function Open-VideoFilePicker {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Fichiers Vidéo (*.mp4;*.mkv;*.mov)|*.mp4;*.mkv;*.mov|Tous les fichiers (*.*)|*.*"
    $dialog.Title = "Sélectionnez le fichier vidéo à traiter"
    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

if ([string]::IsNullOrWhiteSpace($VideoPath)) {
    $mp4Files = @(Get-ChildItem -Path $ScriptDir -Filter "*.mp4")
    
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "  CHOIX DE LA VIDÉO À TRAITER" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    
    if ($mp4Files.Count -eq 1) {
        $defaultVideo = $mp4Files[0]
        Write-Host "Vidéo d'exemple détectée dans le dossier :" -ForegroundColor Gray
        Write-Host "  [1] $($defaultVideo.Name) (par défaut)" -ForegroundColor Green
        Write-Host "  [2] Parcourir mes dossiers pour choisir une autre vidéo" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Astuce : vous pouvez aussi glisser-déposer directement un fichier vidéo dans cette fenêtre." -ForegroundColor Gray
        Write-Host ""
        $rep = (Read-Host "Votre choix (Entrée ou 1 = vidéo par défaut, 2 = parcourir)").Trim('"').Trim("'")
        
        if ([string]::IsNullOrWhiteSpace($rep) -or $rep -eq "1") {
            $VideoPath = $defaultVideo.FullName
            Write-Host "`n [Sélection] Utilisation de la vidéo par défaut : $($defaultVideo.Name)" -ForegroundColor Green
        } elseif ($rep -eq "2") {
            Write-Host "`nOuverture de l'explorateur de fichiers..." -ForegroundColor Yellow
            $chosen = Open-VideoFilePicker
            if ($chosen) {
                $VideoPath = $chosen
                Write-Host " [Sélection] Vidéo choisie : $VideoPath" -ForegroundColor Green
            } else {
                Write-Error "Opération annulée : aucun fichier sélectionné."
                exit 1
            }
        } elseif (Test-Path $rep) {
            $VideoPath = $rep
            Write-Host " [Sélection] Vidéo choisie : $VideoPath" -ForegroundColor Green
        } else {
            Write-Error "Choix ou fichier non reconnu : '$rep'"
            exit 1
        }
    } elseif ($mp4Files.Count -gt 1) {
        Write-Host "Plusieurs vidéos trouvées dans le dossier :" -ForegroundColor Yellow
        for ($i = 0; $i -lt $mp4Files.Count; $i++) {
            Write-Host "  [$($i+1)] $($mp4Files[$i].Name)"
        }
        Write-Host "  [P] Parcourir mes dossiers pour choisir une autre vidéo" -ForegroundColor Cyan
        Write-Host ""
        $rep = (Read-Host "Votre choix (1-$($mp4Files.Count), ou P pour parcourir)").Trim('"').Trim("'")
        if ($rep -match '^[0-9]+$' -and [int]$rep -ge 1 -and [int]$rep -le $mp4Files.Count) {
            $VideoPath = $mp4Files[[int]$rep - 1].FullName
            Write-Host " [Sélection] Vidéo choisie : $($VideoPath)" -ForegroundColor Green
        } elseif ($rep -eq "P" -or $rep -eq "p" -or [string]::IsNullOrWhiteSpace($rep)) {
            $chosen = Open-VideoFilePicker
            if ($chosen) {
                $VideoPath = $chosen
                Write-Host " [Sélection] Vidéo choisie : $VideoPath" -ForegroundColor Green
            } else {
                exit 1
            }
        } elseif (Test-Path $rep) {
            $VideoPath = $rep
            Write-Host " [Sélection] Vidéo choisie : $VideoPath" -ForegroundColor Green
        } else {
            Write-Error "Choix invalide."
            exit 1
        }
    } else {
        Write-Host "Aucune vidéo n'est présente dans le dossier actuel."
        Write-Host "  • Appuyez sur [Entrée] pour parcourir vos dossiers et choisir une vidéo,"
        Write-Host "  • Ou glissez-déposez votre vidéo (.mp4, .mkv, .mov) dans cette fenêtre."
        Write-Host ""
        $rep = (Read-Host "Où se trouve la vidéo ?").Trim('"').Trim("'")
        if ([string]::IsNullOrWhiteSpace($rep)) {
            Write-Host "Ouverture de l'explorateur de fichiers..." -ForegroundColor Yellow
            $chosen = Open-VideoFilePicker
            if ($chosen) {
                $VideoPath = $chosen
                Write-Host " [Sélection] Vidéo choisie : $VideoPath" -ForegroundColor Green
            } else {
                Write-Error "Opération annulée : aucun fichier sélectionné."
                exit 1
            }
        } elseif (Test-Path $rep) {
            $VideoPath = $rep
            Write-Host " [Sélection] Vidéo choisie : $VideoPath" -ForegroundColor Green
        } else {
            Write-Error "Le fichier vidéo '$rep' est introuvable."
            exit 1
        }
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

    # 2. Lecture des variables : d'abord le dossier secrets global, puis le .env local (prioritaire)
    $candidateEnvFiles = @(
        "C:\Users\Admin\Desktop\secrets\.env",
        (Join-Path $ScriptDir ".env")
    )
    foreach ($ef in $candidateEnvFiles) {
        if (Test-Path $ef) {
            Get-Content $ef | ForEach-Object {
                if ($_ -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.+)\s*$') {
                    $val = $matches[2].Trim().Trim('"').Trim("'")
                    [Environment]::SetEnvironmentVariable($matches[1], $val, "Process")
                }
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
    if ($env:OPENAI_API_KEY -or $env:openai_api_key) {
        $oaKey = if ($env:OPENAI_API_KEY) { $env:OPENAI_API_KEY } else { $env:openai_api_key }
        Write-Host " [Auth] Clé OpenAI détectée via .env !" -ForegroundColor Green
        return @{ Provider = "openai"; Key = $oaKey }
    }

    # 4. Saisie interactive conviviale
    Write-Host "`n----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "  CONFIGURATION DE LA CLÉ D'ACCÈS IA (LLM)" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Une clé d'accès API est nécessaire pour synthétiser le transcript de 2h."
    Write-Host "  [1] Google Gemini (Recommandé, gratuit sur aistudio.google.com)"
    Write-Host "  [2] Mistral AI (console.mistral.ai)"
    Write-Host "  [3] OpenAI (platform.openai.com)"
    
    $choix = Read-Host "`nChoisissez votre fournisseur [1 pour Gemini, 2 pour Mistral, 3 pour OpenAI]"
    $prov = if ($choix -eq "2") { "mistral" } elseif ($choix -eq "3") { "openai" } else { "gemini" }

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
if (!$uvExe) {
    $candidates = @(
        "$HOME\.local\bin\uv.exe",
        "$env:USERPROFILE\.local\bin\uv.exe",
        "C:\Users\Admin\.local\bin\uv.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe\uv.exe",
        "$HOME\.cargo\bin\uv.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            $uvExe = $cand
            break
        }
    }
}

if (!$uvExe -or !(Test-Path $uvExe)) {
    Write-Host " [Installation] Téléchargement automatique de l'outil autonome 'uv' (sans droits admin)..." -ForegroundColor Yellow
    try {
        irm https://astral.sh/uv/install.ps1 | iex
        $uvExe = "$HOME\.local\bin\uv.exe"
        if (!(Test-Path $uvExe)) {
            $uvExe = "$env:USERPROFILE\.local\bin\uv.exe"
        }
        Write-Host " Outil 'uv' installé avec succès dans votre profil utilisateur !" -ForegroundColor Green
    } catch {
        Write-Error "Impossible de télécharger 'uv' automatiquement. Vérifiez votre connexion Internet."
        exit 1
    }
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
if ($LASTEXITCODE -ne 0) {
    Write-Error "Une erreur s'est produite lors de l'exécution du pipeline Python (code d'erreur $LASTEXITCODE)."
    exit $LASTEXITCODE
}

$sw.Stop()
$elapsed = [string]::Format("{0:d2}m {1:d2}s", $sw.Elapsed.Minutes, $sw.Elapsed.Seconds)

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   PIPELINE TERMINÉ AVEC SUCCÈS EN $elapsed !                  " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host "Livrables générés dans : $(Join-Path $ScriptDir $OutputDir)" -ForegroundColor Cyan
