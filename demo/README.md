# Traitement vidéo et génération de supports multi-formats (demo/)

Ce dossier contient la chaîne de traitement pour convertir un enregistrement vidéo (réunion, formation, atelier ou conférence) en 7 livrables documentaires et visuels.

> **Note d'avancement :** Le pipeline automatisé, les scripts d'export, le module d'installation Windows et les intégrations système sont opérationnels. L'UI reste à mettre en place!

## Matrice des sept livrables générés

Chaque exécution produit un ensemble de documents dans le répertoire cible (un sous-dossier `<NomDeLaVideo>_livrables` créé à côté du fichier vidéo source, ou dans [`demo/output/`](./output/) pour la vidéo d'essai):

| Livrable | Fichier généré | Format | Rôle et contenu |
| :--- | :--- | :---: | :--- |
| Note de cadrage | [`article_mode_d_emploi.docx`](./output/article_mode_d_emploi.docx) | `.docx` | Document Word structuré en 5 à 10 sections opérationnelles. Réunit constats chiffrés, recommandations, encadrés méthodologiques et captures extraites de la vidéo. |
| Diaporama PowerPoint | [`presentation.pptx`](./output/presentation.pptx) | `.pptx` | Support PowerPoint au format large 16:9 widescreen, structuré avec typographies Segoe UI et Calibri, puces denses, cartes d'indicateurs et captures synchronisées. |
| Support web interactif | [`presentation.html`](./output/presentation.html) | `.html` | Présentation plein écran autonome sans dépendance externe, navigable au clavier (flèches, espace) et lisible hors-ligne avec images intégrées en base64. |
| Export imprimable 16:9 | [`presentation.pdf`](./output/presentation.pdf) | `.pdf` | Rendu vectoriel paysage page par page, sans coupure de diapositive, généré par le moteur Chromium headless. |
| Synthèse exécutive | [`summary.md`](./output/summary.md) | `.md` | Synthèse textuelle des constats essentiels, arbitrages et décisions, complétée par le bilan FinOps. |
| Bilan FinOps | [`finops_report.json`](./output/finops_report.json) | `.json` | Rapport comptable détaillant les jetons consommés, les coûts d'API facturés en dollars et en euros, et les économies réalisées via l'inférence locale. |
| Transcription intégrale | [`transcript.md`](./output/transcript.md) | `.md` | Transcription textuelle exhaustive horodatée seconde par seconde avec identification de la langue et de la durée. |
| Captures clés (keyframes) | [`keyframes/`](./output/keyframes/) | `.jpg` | Sélection de 18 à 40 diapositives et moments stables extraits en résolution 1080p. |

## Architecture technique (vue d'ensemble)

Le pipeline repose sur 5 couches interconnectées, conformément au schéma du dossier [`archi/`](../archi/):

```mermaid
flowchart LR
    UI["1. Interface et Orchestration<br/><small>Menu, .bat, CLI -> pipeline.py</small>"]
    INGESTION["2. Multimédia et Calcul Local<br/><small>Audio, Whisper, scènes (hors-ligne)</small>"]
    LLM["3. Intelligence et FinOps<br/><small>LLM, Humanizer, coûts</small>"]
    GEN["4. Générateurs Documentaires<br/><small>Word, PowerPoint, HTML, PDF</small>"]
    DELIV["5. Pack de Livrables<br/><small>docx, pptx, html, pdf, md, json</small>"]

    UI -->|vidéo| INGESTION
    INGESTION -->|texte + images| LLM
    LLM -->|deck_structure| GEN
    GEN -->|documents| DELIV
    INGESTION -->|transcript| DELIV
```

Le schéma interactif complet est consultable dans [`archi/Vue d'ensemble.html`](../archi/Vue%20d'ensemble.html).

### Composants des cinq couches

#### 1. Interface et orchestration
- Point d'entrée au clic droit Windows via le menu contextuel, lanceur `LANCER_PIPELINE.bat` et interface graphique `install_gui.ps1`.
- Orchestrateur PowerShell `run_pipeline.ps1` assurant l'initialisation du runtime et la reprise sur erreur.
- Script `pipeline.py` pilotant l'enchaînement des étapes de traitement.

#### 2. Multimédia et calcul local (100% hors-ligne)
- Extraction audio: séparation du signal WAV mono à 16 000 Hz (`pcm_s16le`) via le binaire autonome `ffmpeg` (embarqué par `imageio-ffmpeg`).
- Transcription Whisper: inférence vocale locale par `faster-whisper` adossée à CTranslate2 en quantification int8 CPU ou CUDA float16. Progression en temps réel `tqdm` et écriture continue sur disque dans `transcript.md`.
- Détection des scènes: analyse des flux visuels par `PySceneDetect` (`ContentDetector`) pour extraire 18 à 40 images clés stables en résolution 1080p.

#### 3. Intelligence et FinOps
- Synthèse LLM: envoi de la transcription vers les modèles à large fenêtre de contexte (OpenAI `gpt-4o-mini`, Google Gemini `gemini-2.0-flash` ou Mistral `mistral-large-latest`).
- Règles d'humanisation: élimination systématique des tics d'écriture d'IA, des accroches théâtrales et des métaphores abstraites. Structuration d'enseignements clés, puces denses et notes d'orateur.
- Bilan FinOps: fonction `calculate_finops_cost` mesurant les jetons exacts et valorisant les coûts d'API ainsi que les économies réalisées en local.

#### 4. Générateurs documentaires
- Générateur Word: production de la note de cadrage et du mode d'emploi via `python-docx` avec encadrés méthodologiques et captures centrées.
- Générateur PowerPoint: création de diaporamas 16:9 widescreen via `python-pptx`, incluant l'enseignement clé, cartes KPI et notes d'orateur natives.
- Générateur Web: compilation du deck interactif autonome en HTML5 et CSS3 Grid avec visuels embarqués en Base64.
- Moteur PDF: conversion vectorielle 16:9 sans débordement de page via Chromium headless.

#### 5. Pack de livrables
- Centralisation des 7 livrables directement exploitables (`.docx`, `.pptx`, `.html`, `.pdf`, `.md`, `.json`, `keyframes/`) dans le sous-dossier de destination.

## Evaluation FinOps et suivi des dépenses

La fonction `calculate_finops_cost` détaille la consommation de chaque traitement:

### Mesure des coûts d'API au jeton
- Décompte des jetons d'entrée et de sortie.
- Application des grilles officielles par million de jetons.
- Conversion en dollars et en euros (taux de change retenu: 0.92 € / $).

### Evaluation des gains liés au calcul local
- Comparaison avec le tarif standard des services cloud de transcription audio (0.006 $ par minute).
- Sur un atelier de 7 minutes: gain de 0.042 $.
- Sur une réunion de 1 heure 10 minutes: gain de 0.42 $.

### Coûts d'API constatés
- Une exécution courte de 7 à 10 minutes engendre environ 0.0015 € de requête LLM.
- Une réunion d'une heure reste sous le seuil de 0.05 € d'API.
- Le détail comptable est consigné dans [`output/finops_report.json`](./output/finops_report.json).

## Guide d'utilisation

### Interface graphique sous Windows

1. Installation:
   Double-cliquez sur `INSTALLER_WINDOWS.bat`. Sélectionnez votre fournisseur d'IA, renseignez votre clé d'accès puis cliquez sur "Installer & Configurer".

2. Conversion via le menu contextuel:
   Sur un fichier `.mp4`:
   - Sous Windows 11: clic droit sur la vidéo, sélectionnez "Afficher d'autres options" (ou utilisez le raccourci `Maj + F10`), puis cliquez sur "Convertir avec Video2PowerPoint (IA)".
   - Sous Windows 10: clic droit sur la vidéo puis cliquez sur "Convertir avec Video2PowerPoint (IA)".

3. Conversion via le lanceur:
   Double-cliquez sur `LANCER_PIPELINE.bat` (ou sur le raccourci du Bureau):
   - Appuyez sur Entrée pour traiter la vidéo de test intégrée (7 minutes).
   - Tapez 2 pour sélectionner un fichier vidéo sur votre disque via l'explorateur.
   - Tapez 3 pour indiquer une URL Google Drive.

A l'issue de l'opération, le répertoire contenant les 7 livrables s'ouvre avec un message de confirmation.

### Ligne de commande (CLI)

Le moteur s'exécute via PowerShell ou directement avec l'interpréteur Python:

```powershell
# 1. Exécution via l'orchestrateur PowerShell
.\run_pipeline.ps1 -VideoPath "C:\Videos\session.mp4" -Provider openai -ModelSize medium

# 2. Exécution via l'interpréteur Python
.\.venv\Scripts\python.exe pipeline.py --video "C:\Videos\session.mp4" --output "C:\Livrables" --provider openai --slides 20

# 3. Traitement d'un lien Google Drive
.\.venv\Scripts\python.exe pipeline.py --video "https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing" --provider gemini

# 4. Régénération documentaire à partir d'une transcription existante
.\.venv\Scripts\python.exe pipeline.py --video "C:\Videos\session.mp4" --skip-transcription
```

### Paramètres du script pipeline.py

| Paramètre | Type | Valeur par défaut | Description |
| :--- | :---: | :---: | :--- |
| `--video` | `str` | Requis | Chemin local vers le fichier `.mp4` ou URL Google Drive. |
| `--output` | `str` | `output` | Dossier de destination des livrables. |
| `--model` | `str` | `medium` | Taille du modèle Whisper (`tiny`, `base`, `small`, `medium`, `large-v3-turbo`). |
| `--provider` | `str` | `gemini` | Fournisseur de synthèse (`openai`, `gemini`, `mistral`). |
| `--api-key` | `str` | Variable d'environnement | Clé d'API pour le fournisseur sélectionné. |
| `--slides` | `int` | `0` (automatique) | Nombre cible de diapositives (0 pour calcul automatique selon la durée). |
| `--skip-transcription` | `flag` | `False` | Réutilise le fichier `transcript.md` existant sans relancer l'inférence vocale. |

## Banc d'essai et tests automatisés (tests/)

Une suite de 23 tests automatisés validée par `pytest` vérifie le bon fonctionnement du moteur:

- `test_environment_sanity.py` (2 tests): contrôle la présence du binaire `ffmpeg` et l'import des bibliothèques obligatoires (`faster-whisper`, `scenedetect`, `docx`, `pptx`, `PIL`).
- `test_units.py` (16 tests): valide les horodatages, l'extraction des identifiants Google Drive, les filtres lexicaux anti-clichés et les formules FinOps pour OpenAI, Gemini et Whisper.
- `test_generators.py` (4 tests): valide la structure du document Word, du fichier PowerPoint 16:9, du deck HTML et de la conversion PDF.
- `test_pipeline_e2e.py` (1 test): test d'intégration global vérifiant la production conjointe des 7 livrables.

Pour exécuter la suite de tests:
```cmd
LANCER_TESTS.bat
```
Ou via la commande:
```powershell
.\.venv\Scripts\python.exe -m pytest tests -s -v
```

## Structure du répertoire demo/

```text
demo/
├── assets/
│   ├── app_icon.ico           # Icône multi-résolution (16x16 à 256x256) pour Windows
│   └── app_icon.png           # Fichier image source du logo
├── output/                    # Répertoire des livrables de la vidéo de démonstration
│   ├── keyframes/             # Captures d'écran extraites (slide_keyframe_XX.jpg)
│   ├── transcript.md          # Transcription textuelle complète horodatée
│   ├── summary.md             # Synthèse exécutive et section FinOps
│   ├── finops_report.json     # Rapport comptable de l'exécution
│   ├── article_mode_d_emploi.docx # Document Word opérationnel
│   ├── presentation.pptx      # Diaporama PowerPoint 16:9
│   ├── presentation.html      # Support web interactif plein écran
│   ├── presentation.pdf       # Export PDF paysage 16:9
│   └── deck_structure.json    # Schéma JSON intermédiaire de la présentation
├── tests/                     # Suite de tests automatisés (23 tests)
│   ├── conftest.py            # Données de test et bouchons partagés
│   ├── test_environment_sanity.py # Vérification de l'environnement d'exécution
│   ├── test_units.py          # Tests unitaires: Drive, FinOps, règles de filtrage
│   ├── test_generators.py     # Vérification des formats de sortie
│   └── test_pipeline_e2e.py   # Test d'intégration de bout en bout
├── pipeline.py                # Moteur d'orchestration (Whisper, Drive, LLM, exports)
├── run_pipeline.ps1           # Wrapper d'exécution PowerShell
├── install_gui.ps1            # Assistant graphique d'installation Windows
├── INSTALLER_WINDOWS.bat      # Lanceur d'installation rapide
├── LANCER_PIPELINE.bat        # Lanceur de traitement avec menu de sélection
├── LANCER_TESTS.bat           # Lanceur de la suite de tests unitaires
├── pytest.ini                 # Options de configuration de pytest (-s -v)
├── requirements.txt           # Dépendances Python figées
├── brief.md                   # Expression du besoin initial du projet
├── prd.md                     # Cahier des charges fonctionnel détaillé (PRD)
├── addendum.md                # Note d'arbitrage et d'architecture technique
└── README.md                  # Documentation technique du module
```

## Documents de référence et spécifications

L'ensemble des documents de cadrage du projet est directement accessible dans ce dossier et dans le répertoire racine:

- [`demo/prd.md`](./prd.md): Cahier des charges et spécifications fonctionnelles complètes (PRD).
- [`demo/brief.md`](./brief.md): Brief initial du projet.
- [`demo/addendum.md`](./addendum.md): Décisions d'architecture technique et matrice de dimensionnement.
- [`archi/Vue d'ensemble.html`](../archi/Vue%20d'ensemble.html): Schéma interactif des 5 couches d'architecture et de leurs flux.
