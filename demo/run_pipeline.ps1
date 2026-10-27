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

# Masquer les alertes de sécurité Windows et avertissements techniques Hugging Face / Symlinks
$env:SEE_MASK_NOZONECHECKS = "1"
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
    $defaultGdriveUrl = "https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing"
    
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "  CHOIX DE LA VIDÉO À TRAITER" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    
    if ($mp4Files.Count -ge 1) {
        $defaultVideo = $mp4Files[0]
        Write-Host "Vidéo d'exemple disponible sur votre disque :" -ForegroundColor Gray
        Write-Host "  [1] $($defaultVideo.Name) (par défaut)" -ForegroundColor Green
        Write-Host "  [2] Parcourir mes dossiers pour choisir une vidéo sur mon ordinateur" -ForegroundColor Yellow
        Write-Host "  [3] Télécharger une autre vidéo depuis Google Drive (coller le lien)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Astuce : vous pouvez aussi glisser-déposer directement un fichier vidéo dans cette fenêtre." -ForegroundColor Gray
        Write-Host ""
        $rep = (Read-Host "Votre choix (Entrée ou 1 = vidéo locale, 2 = parcourir, 3 = lien Drive)").Trim('"').Trim("'")
        
        if ([string]::IsNullOrWhiteSpace($rep) -or $rep -eq "1") {
            $VideoPath = $defaultVideo.FullName
            Write-Host "`n [Sélection] Utilisation de la vidéo locale : $($defaultVideo.Name)" -ForegroundColor Green
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
        } elseif ($rep -eq "3") {
            $urlInput = (Read-Host "`nCollez le lien Google Drive ou l'adresse de votre vidéo").Trim('"').Trim("'")
            if ($urlInput) {
                $VideoPath = $urlInput
            } else {
                Write-Error "Aucun lien renseigné."
                exit 1
            }
        } elseif ($rep.StartsWith("http") -or ($rep -match "drive\.google\.com")) {
            $VideoPath = $rep
        } elseif (Test-Path $rep) {
            $VideoPath = $rep
            Write-Host " [Sélection] Vidéo choisie : $VideoPath" -ForegroundColor Green
        } else {
            Write-Error "Choix ou fichier non reconnu : '$rep'"
            exit 1
        }
    } else {
        Write-Host "Aucune vidéo n'a été trouvée sur votre disque." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Que souhaitez-vous faire ?"
        Write-Host "  [1] Télécharger la vidéo d'exemple depuis Google Drive (recommandé)" -ForegroundColor Green
        Write-Host "      -> Atelier de 7 min : Chris Lewis, Too Fast to Think (226 Mo)" -ForegroundColor Gray
        Write-Host "  [2] Parcourir mes dossiers pour choisir une vidéo sur mon ordinateur" -ForegroundColor Yellow
        Write-Host "  [3] Coller un lien Google Drive ou une URL de vidéo" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Astuce : vous pouvez aussi glisser-déposer directement un fichier vidéo dans cette fenêtre." -ForegroundColor Gray
        Write-Host ""
        $rep = (Read-Host "Votre choix (Entrée ou 1 = Télécharger l'exemple, 2 = Choisir sur mon PC, 3 = Lien)").Trim('"').Trim("'")
        
        if ([string]::IsNullOrWhiteSpace($rep) -or $rep -eq "1") {
            $VideoPath = $defaultGdriveUrl
            Write-Host "`n [Téléchargement] Récupération de la vidéo d'exemple depuis Google Drive..." -ForegroundColor Green
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
        } elseif ($rep -eq "3") {
            $urlInput = (Read-Host "`nCollez le lien Google Drive ou l'adresse de votre vidéo").Trim('"').Trim("'")
            if ($urlInput) {
                $VideoPath = $urlInput
            } else {
                Write-Error "Aucun lien renseigné."
                exit 1
            }
        } elseif ($rep.StartsWith("http") -or ($rep -match "drive\.google\.com")) {
            $VideoPath = $rep
        } elseif (Test-Path $rep) {
            $VideoPath = $rep
            Write-Host " [Sélection] Vidéo choisie : $VideoPath" -ForegroundColor Green
        } else {
            Write-Error "Choix ou fichier non reconnu : '$rep'"
            exit 1
        }
    }
}

$isUrl = $VideoPath.StartsWith("http://") -or $VideoPath.StartsWith("https://") -or ($VideoPath -match "drive\.google\.com")
if (!$isUrl) {
    if (!(Test-Path $VideoPath)) {
        Write-Error "Le fichier vidéo '$VideoPath' est introuvable."
        exit 1
    }
    # Supprimer le tag de sécurité de téléchargement web sur la vidéo
    Unblock-File -LiteralPath (Resolve-Path $VideoPath).Path -ErrorAction SilentlyContinue
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

# Détermination intelligente et explicite du dossier de sortie :
# Si la vidéo est un fichier local situé en dehors du dossier demo/ et qu'aucun dossier personnalisé n'est forcé :
# Créer le dossier "<Nom_de_la_video>_livrables" directement à côté de la vidéo !
$ResolvedOutputDir = $null
if (![string]::IsNullOrWhiteSpace($OutputDir) -and $OutputDir -ne "output") {
    $ResolvedOutputDir = $OutputDir
    if (![System.IO.Path]::IsPathRooted($ResolvedOutputDir)) {
        $ResolvedOutputDir = Join-Path $ScriptDir $OutputDir
    }
} else {
    if (!$isUrl -and (Test-Path $VideoPath)) {
        $fullVideoPath = (Resolve-Path $VideoPath).Path
        $videoParent = Split-Path -Parent $fullVideoPath
        $videoBaseName = [System.IO.Path]::GetFileNameWithoutExtension($fullVideoPath)
        $scriptFullPath = (Resolve-Path $ScriptDir).Path
        if ($videoParent -ne $scriptFullPath) {
            # Vidéo externe choisie sur le disque : créer le dossier juste à côté de la vidéo
            $ResolvedOutputDir = Join-Path $videoParent "${videoBaseName}_livrables"
        } else {
            # Vidéo interne du dossier demo : enregistrer dans demo/output
            $ResolvedOutputDir = Join-Path $ScriptDir "output"
        }
    } else {
        $ResolvedOutputDir = Join-Path $ScriptDir "output"
    }
}

if (!(Test-Path $ResolvedOutputDir)) {
    New-Item -ItemType Directory -Path $ResolvedOutputDir -Force | Out-Null
}

$pipelineArgs = @(
    (Join-Path $ScriptDir "pipeline.py"),
    "--video", $VideoPath,
    "--output", $ResolvedOutputDir,
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
Write-Host ""
Write-Host " DOSSIER OÙ VOS LIVRABLES SONT ENREGISTRÉS :" -ForegroundColor Yellow
Write-Host " >>> $ResolvedOutputDir <<<" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host ""
Write-Host "   • Diapositives PowerPoint : $(Join-Path $ResolvedOutputDir 'presentation.pptx')" -ForegroundColor Cyan
Write-Host "   • Mode d'emploi Word      : $(Join-Path $ResolvedOutputDir 'article_mode_d_emploi.docx')" -ForegroundColor Cyan
Write-Host "   • Présentation Web HTML   : $(Join-Path $ResolvedOutputDir 'presentation.html')" -ForegroundColor Cyan
Write-Host "   • Export PDF 16:9         : $(Join-Path $ResolvedOutputDir 'presentation.pdf')" -ForegroundColor Cyan
Write-Host "   • Synthèse Exécutive      : $(Join-Path $ResolvedOutputDir 'summary.md')" -ForegroundColor Cyan
Write-Host "   • Transcription Intégrale : $(Join-Path $ResolvedOutputDir 'transcript.md')" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ouverture automatique du dossier dans l'Explorateur Windows..." -ForegroundColor Yellow

# Ouvrir immédiatement l'explorateur Windows sur le dossier exact des résultats
try {
    Start-Process explorer.exe -ArgumentList "`"$ResolvedOutputDir`""
} catch {}

# Afficher une boîte de dialogue Windows pour confirmation visuelle immédiate
try {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Vos livrables ont été générés avec succès !`n`nIls sont enregistrés dans le dossier :`n$ResolvedOutputDir`n`nLe dossier vient de s'ouvrir dans l'Explorateur Windows.",
        "Video to PowerPoint - Livrables Prêts",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
} catch {}

Write-Host ""
Write-Host "Appuyez sur une touche pour fermer cette fenêtre..." -ForegroundColor Gray
try {
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} catch {}
