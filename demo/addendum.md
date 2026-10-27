# Addendum Technique & Décisions d'Architecture
## Projet : Pipeline Vidéo ➔ Transcript, Synthèse & Decks (PPTX + HTML)

### 1. Choix Technologiques & Justifications

| Composant | Option Retenue | Alternatives Écartées | Rationale |
| :--- | :--- | :--- | :--- |
| **Moteur LLM (Synthèse & Structuration Decks)** | API Cloud (Gemini ou Mistral) | Ollama local, Llama.cpp local | Déployer un LLM local de 8B à 14B paramètres via Ollama sur des postes d'utilisateurs non techniques est bloquant (installation lourde, 8+ Go de RAM/VRAM requises, configuration GPU aléatoire). L'appel direct à l'API Gemini Flash ou Mistral Large via une simple clé d'accès traite les 25 000 mots du transcript en 10 secondes pour un coût négligeable, sans aucune friction utilisateur. |
| **Moteur Whisper** | `faster-whisper` (CTranslate2) | `openai-whisper` vanilla, `whisper.cpp` | `faster-whisper` est 4x plus rapide que l'implémentation originale OpenAI, supporte nativement la quantification CPU `int8`, consomme moitié moins de RAM, et ne requiert pas de compilateur C++ sous Windows contrairement à `whisper.cpp`. |
| **Détection de Scènes** | `PySceneDetect` (ContentDetector) | Extraction aveugle toutes les N secondes, `ffmpeg select` brut | L'extraction à intervalle fixe produit 80% de doublons ou des images floues pendant les transitions d'animation. PySceneDetect analyse les seuils HSV pour capturer les slides stables. |
| **Gestionnaire d'environnement** | `uv` (Astral) | `pip` global, `conda`, `poetry` | `uv` est déjà installé sur la machine (`C:\Users\Admin\.local\bin\uv.exe`), ultra-rapide (écrit en Rust), gère le téléchargement automatique de Python sans droits admin et résout les dépendances en quelques secondes. |
| **Génération PowerPoint** | `python-pptx` | COM automation (PowerPoint.Application) | L'automatisation COM nécessite que Microsoft PowerPoint soit installé, ouvert et sous licence active sur la machine hôte. `python-pptx` est 100% autonome et génère des fichiers `.pptx` valides sans PowerPoint. |
| **Génération Deck Web** | Skill ECC `frontend-slides` | Marp CLI, Reveal.js | `frontend-slides` produit un fichier HTML unique sans aucune dépendance npm ou serveur web, avec un design exécutif supérieur et un export PDF 16:9 parfait via Chromium headless. |

---

### 2. Spécification de la Ligne de Commande PowerShell

```powershell
<#
.SYNOPSIS
    Orchestre le traitement d'une vidéo longue en livrables professionnels (Transcript, Synthèse, PPTX, HTML, PDF).
.PARAMETER VideoPath
    Chemin vers le fichier MP4 (obligatoire).
.PARAMETER ModelSize
    Taille du modèle Whisper : "base", "small", "medium" (défaut), "large-v3-turbo".
.PARAMETER OutputDir
    Répertoire de destination des livrables (défaut : .\output_<timestamp>).
.PARAMETER SkipTranscription
    Reprend l'exécution si le transcript existe déjà.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$VideoPath,
    [ValidateSet("base", "small", "medium", "large-v3-turbo")]
    [string]$ModelSize = "medium",
    [string]$OutputDir = "",
    [switch]$SkipTranscription
)
```

---

### 3. Matrice de Dimensionnement (Vidéo 2h)

- **Flux vidéo 1080p 30fps** : ~1.5 Go à 3 Go.
- **Piste audio extraite (WAV 16kHz mono)** : ~230 Mo.
- **Consommation RAM pendant Whisper `medium` (CPU int8)** : ~2.5 Go RAM.
- **Temps estimé de transcription (CPU 8 cœurs)** : ~18 à 22 minutes.
- **Temps estimé de détection de scènes** : ~3 à 5 minutes.
- **Génération des livrables (Synthèse, PPTX, HTML, PDF)** : < 1 minute.
- **Temps total de bout en bout** : ~25 à 30 minutes.
