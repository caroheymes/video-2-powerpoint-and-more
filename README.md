# Video to PowerPoint & More

Ce projet convertit un enregistrement vidéo (réunion, formation, atelier ou conférence) en documents de travail complets:

- Transcription intégrale horodatée, calculée en local avec Whisper.
- Synthèse factuelle des constats et décisions.
- Note de cadrage Word (.docx) illustrée par les captures de la vidéo.
- Diaporama PowerPoint 16:9 (.pptx).
- Version web autonome (.html) et export imprimable (.pdf).

> **Note d'avancement :** Le pipeline automatisé, les scripts d'export, le module d'installation Windows et les intégrations système sont opérationnels. L'UI reste à mettre en place!

## Architecture technique (vue d'ensemble)

Le pipeline repose sur 5 couches interconnectées, conformément au schéma du dossier [`archi/`](./archi/):

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

Le schéma interactif complet est consultable dans [`archi/Vue d'ensemble.html`](./archi/Vue%20d'ensemble.html).

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

## Installation sous Windows

L'assistant configure l'environnement sans installation préalable de Python ou de Git:

1. Téléchargement du dépôt:
   Récupérez l'archive via le lien [video-2-powerpoint-and-more.zip](https://github.com/caroheymes/video-2-powerpoint-and-more/archive/refs/heads/master.zip).
2. Décompression de l'archive:
   Faites un clic droit sur le fichier zip et choisissez "Extraire tout".
3. Exécution de l'installeur:
   Dans le dossier dézippé, double-cliquez sur `INSTALLER_WINDOWS.bat`.

Dans la fenêtre de configuration:
- Choisissez le fournisseur d'IA (OpenAI, Google Gemini ou Mistral).
- Renseignez votre clé d'API.
- Cliquez sur "Installer & Configurer".

L'assistant crée les raccourcis système:
- Une icône "Video to PowerPoint" sur le Bureau.
- Une action "Convertir avec Video2PowerPoint (IA)" dans le menu contextuel Windows des fichiers vidéo.

## Utilisation au quotidien

Deux modes d'exécution sont disponibles:

### Menu contextuel (clic droit)
Sur tout fichier vidéo (.mp4):
- Sous Windows 11: clic droit sur la vidéo, sélectionnez "Afficher d'autres options" (ou utilisez le raccourci `Maj + F10`), puis cliquez sur "Convertir avec Video2PowerPoint (IA)".
- Sous Windows 10: clic droit sur la vidéo puis cliquez directement sur "Convertir avec Video2PowerPoint (IA)".

### Lanceur ou icône de bureau
Double-cliquez sur `LANCER_PIPELINE.bat` (ou le raccourci Bureau):
- Touche Entrée: télécharge et traite la vidéo de démonstration (7 minutes).
- Option 2: ouvre l'explorateur pour sélectionner un fichier vidéo local.
- Option 3: permet de renseigner un lien Google Drive.
- Le glisser-déposer d'un fichier vidéo dans la fenêtre de console est également pris en charge.

### Suivi d'exécution et volumétrie adaptative
- Progression console: la transcription Whisper affiche une barre dynamique indiquant le temps écoulé, le pourcentage et l'estimation de fin.
- Écriture continue: le fichier `transcript.md` est créé dès le lancement et alimenté au fur et à mesure du décodage audio.
- Diaporama calibré selon la durée: le nombre de diapositives s'adapte automatiquement (10 pour moins de 10 minutes, 18 pour 30 minutes, 25 à 35 pour les enregistrements supérieurs à une heure). L'argument `--slides` permet de forcer une valeur fixe.

### Emplacement des livrables
- Pour une vidéo locale: les fichiers sont créés dans un dossier `<NomDeLaVideo>_livrables` placé à côté de la vidéo source.
- Pour la vidéo d'essai: les fichiers sont stockés dans `demo/output/`.
- En fin de traitement, l'explorateur s'ouvre sur le dossier des livrables avec une notification de confirmation.

## Résultats sur la vidéo de démonstration

Le pipeline a été vérifié sur un enregistrement de 7 minutes (intervention de Zoé Hames sur l'ouvrage Too Fast to Think):
- Source: [Lien Google Drive](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)
- Temps de traitement: 1 minute 11 secondes sur configuration de bureau standard.

Livrables disponibles dans [`demo/output/`](./demo/output/):

| Document | Fichier généré | Contenu |
| :--- | :--- | :--- |
| Note de cadrage | [`article_mode_d_emploi.docx`](./demo/output/article_mode_d_emploi.docx) | Document Word en 5 sections opérationnelles avec captures et constats. |
| Diaporama PowerPoint | [`presentation.pptx`](./demo/output/presentation.pptx) | Présentation 16:9 de 10 diapositives sans verbiage d'IA. |
| Version imprimable | [`presentation.pdf`](./demo/output/presentation.pdf) | Rendu PDF paysage page à page. |
| Présentation web | [`presentation.html`](./demo/output/presentation.html) | Fichier web autonome lisible hors-ligne avec navigation clavier. |
| Synthèse exécutive | [`summary.md`](./demo/output/summary.md) | Synthèse factuelle des constats et décisions. |
| Bilan FinOps | [`finops_report.json`](./demo/output/finops_report.json) | Rapport comptable des jetons, des coûts d'API et des gains du calcul local. |
| Transcription brute | [`transcript.md`](./demo/output/transcript.md) | Retranscription intégrale horodatée via Whisper. |
| Captures vidéo | [`keyframes/`](./demo/output/keyframes/) | 18 images des plans stables de la vidéo. |

## Évaluation FinOps et maîtrise des dépenses

L'architecture réduit les coûts d'infrastructure et d'API:

- Traitement lourd en local (0,00 €): l'extraction audio (`ffmpeg`), la transcription (`faster-whisper`), la détection des scènes (`scenedetect`) et la génération des documents (Word, PowerPoint, HTML, PDF) s'exécutent sur la machine de l'utilisateur sans service tiers.
- Gain de calcul local constaté: l'inférence locale Whisper évite la facturation des services cloud audio (base standard de 0.006 $ par minute, soit 0.42 $ de gain direct par heure traitée).
- Dépenses LLM mesurées: seule la structuration éditoriale sollicite l'API externe (OpenAI `gpt-4o-mini`, Google Gemini ou Mistral), avec un coût inférieur à 0.002 € pour 10 minutes et moins de 0.05 € pour une réunion d'une heure.
- Traçabilité financière: un fichier `finops_report.json` consigne à chaque run le décompte des jetons et la valorisation en devises (dollars et euros).

## Organisation du dépôt

- `INSTALLER_WINDOWS.bat`: assistant d'installation pour Windows (racine).
- `LANCER_PIPELINE.bat`: lanceur principal du pipeline (racine).
- `LANCER_TESTS.bat`: banc d'essai automatisé de 23 tests (racine).
- `archi/`: schéma interactif d'architecture et description des flux (`Vue d'ensemble.html`).
- `demo/`: code source, dépendances virtuelles, tests et sorties.
- `scripts_historiques/`: scripts d'exploration initiaux.

## Documents de référence et spécifications

L'ensemble des documents de cadrage du projet est directement accessible:

- [`demo/prd.md`](./demo/prd.md): Cahier des charges et spécifications fonctionnelles complètes (PRD).
- [`demo/brief.md`](./demo/brief.md): Brief initial du projet.
- [`demo/addendum.md`](./demo/addendum.md): Décisions d'architecture technique et matrice de dimensionnement.
- [`archi/Vue d'ensemble.html`](./archi/Vue%20d'ensemble.html): Schéma interactif des 5 couches d'architecture et de leurs flux.

## Validation et tests automatisés

Une suite de 23 tests automatisés `pytest` vérifie chaque composant:
- Environnement: disponibilité du binaire `ffmpeg` et import des modules (`faster-whisper`, `scenedetect`, `python-docx`, `python-pptx`, `Pillow`).
- Formats documentaires: validation de la structure Word (`.docx`), du format 16:9 PowerPoint (`.pptx`), du fichier HTML autonome et de l'export PDF.
- Intégration continue (Harness E2E): validation de l'enchaînement complet et génération conjointe des 7 livrables.
- Cadrage éditorial: contrôle des filtres anti-clichés et de l'épuration lexicale.
- Module FinOps: validation des calculs de coûts d'API et des économies Whisper.

Pour exécuter la suite de tests:
Double-cliquez sur `LANCER_TESTS.bat` ou lancez `.\.venv\Scripts\python.exe -m pytest tests -s -v` depuis `demo/`.
