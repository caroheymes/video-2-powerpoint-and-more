# Moteur de Traitement Video et Generation de Decks Multi-Formats (demo/)

Ce dossier contient la chaine de traitement pour convertir un enregistrement video (reunion, formation, atelier ou conference) en 7 livrables documentaires et visuels.

> **Note d'avancement :** Le pipeline automatise, les scripts d'export, le module d'installation Windows et les integrations systeme sont operationnels. L'UI reste a mettre en place!

---

## Les 7 Livrables Generes

Chaque execution produit un ensemble de documents dans le repertoire cible (un sous-dossier `<NomDeLaVideo>_livrables` cree a cote du fichier video source, ou dans [`demo/output/`](./output/) pour la video d'essai):

| Livrable | Fichier genere | Format | Role et contenu |
| :--- | :--- | :---: | :--- |
| Note de cadrage | [`article_mode_d_emploi.docx`](./output/article_mode_d_emploi.docx) | `.docx` | Document Word structure en 5 a 10 sections operationnelles. Reunit constats chiffres, recommandations, encadres methodologiques et captures extraites de la video. |
| Diaporama PowerPoint | [`presentation.pptx`](./output/presentation.pptx) | `.pptx` | Support PowerPoint au format large 16:9 widescreen, structure avec typographies Segoe UI et Calibri, puces courtes, indicateurs chifPoint et captures synchronisees. |
| Support web interactif | [`presentation.html`](./output/presentation.html) | `.html` | Presentation plein ecran autonome sans dependance externe, navigable au clavier (fleches, espace) et lisible hors-ligne avec images integrees en base64. |
| Export imprimable 16:9 | [`presentation.pdf`](./output/presentation.pdf) | `.pdf` | Rendu vectoriel paysage page par page, sans coupure de diapositive, genere par le moteur Chromium headless. |
| Synthese executive | [`summary.md`](./output/summary.md) | `.md` | Synthese textuelle des constats essentiels, arbitrages et decisions, completee par le bilan FinOps. |
| Bilan FinOps | [`finops_report.json`](./output/finops_report.json) | `.json` | Rapport comptable detaillant les jetons consommes, les couts d'API factures en dollars et en euros, et les economies realisees via l'inference locale. |
| Transcription integrale | [`transcript.md`](./output/transcript.md) | `.md` | Transcription textuelle exhaustive horodatee seconde par seconde avec identification de la langue et de la duree. |
| Captures cles (keyframes) | [`keyframes/`](./output/keyframes/) | `.jpg` | Selection de 18 a 40 diapositives et moments stables extraits en resolution 1080p. |

---

## Architecture Technique du Pipeline (5 Etapes)

Le traitement enchaine cinq modules autonomes:

```text
Video MP4 (locale ou lien Google Drive)
   │
   ├─► [Etape 1] Extraction audio (ffmpeg 16 kHz WAV mono)
   │
   ├─► [Etape 2] Transcription locale Whisper (faster-whisper int8 CPU/CUDA)
   │      └─► Progression dynamique (tqdm) et ecriture continue sur disque
   │
   ├─► [Etape 3] Detection des scenes (PySceneDetect + OpenCV)
   │      └─► Extraction selective de keyframes 1080p
   │
   ├─► [Etape 4] Synthese et structuration LLM (OpenAI / Gemini / Mistral)
   │      ├─► Directives de cadrage factuel sans tics d'IA
   │      ├─► Nombre de diapositives adapte a la duree (10 a 35)
   │      └─► Calculateur de consommation et rapport FinOps
   │
   └─► [Etape 5] Production multi-formats des livrables
          ├─► 5A. Document Word operationnel (python-docx)
          ├─► 5B. Diaporama PowerPoint 16:9 (python-pptx)
          ├─► 5C. Support web interactif (HTML5 / CSS3 Grid)
          └─► 5D. Export PDF 16:9 vectoriel (Chromium headless)
```

### 1. Extraction audio (`extract_audio`)
Le flux sonore est extrait via le binaire `ffmpeg` embarque par la bibliotheque `imageio-ffmpeg`, sans prerequis d'installation systeme.
Le signal est normalise en canal mono a 16 000 Hz sous encodage PCM 16 bits lineaire (`pcm_s16le`), format optimal pour l'inference vocale neuronale.

### 2. Transcription locale Whisper (`transcribe_audio`)
La transcription s'appuie sur `faster-whisper` couple au runtime CTranslate2 pour accelerer la vitesse de calcul.
L'execution s'effectue en local sans transfert de donnees vers un serveur externe, preservant la confidentialite des reunions internes.
Le chargeur tente d'abord une acceleration GPU Nvidia (CUDA float16), puis bascule sur le CPU multi-coeurs en quantification int8 si aucun accelerateur compatible n'est detecte.
Une barre de progression `tqdm` affiche la duree audio decodee, le pourcentage traite et la cadence de transcription.
Les segments textuels sont ecrits au fur et a mesure dans `transcript.md` des leur decodage.

### 3. Detection des scenes et keyframes (`extract_scenes`)
Le decoupage temporel s'appuie sur `scenedetect.detect` avec le detecteur adaptatif `ContentDetector`.
L'algorithme filtre les mouvements transitoires pour cibler les bascules reelles de diapositives ou de sujets.
Le volume de captures varie entre 18 et 40 images 1080p selon la longueur de la video.

### 4. Synthese et structuration factuelle (`analyze_with_llm`)
Le module interroge au choix l'API OpenAI (`gpt-4o-mini`), Google Gemini (`gemini-2.0-flash`) ou Mistral AI (`mistral-large-latest`).
Le prompt applique des regles d'humanisation rigoureuses:
- Suppression des formules creuses ("Dans un monde en constante evolution", "A l'ere du numerique").
- Elimination des metaphores abstraites ("catalyseur", "pierre angulaire", "riche mosaique").
- Rejet du formatage systematique en gras sur chaque puce.
- Filtrage programmatique de cloture via `clean_humanizer_text`.
Le nombre de diapositives s'ajuste a la densite de l'enregistrement: 10 pour moins de 10 minutes, 18 pour 30 minutes, 25 a 35 au-dela d'une heure.

### 5. Generation des documents
- Word (`.docx`): mise en page structuree avec typographies d'entreprise, hierarchie visuelle nette et insertion des captures en pleine largeur.
- PowerPoint (`.pptx`): matrice 16:9 widescreen (13.33 x 7.5 pouces), fond ardoise (`#0B0F19`), contrastes et blocs d'indicateurs.
- Deck HTML: presentation autonome a fichier unique, navigable aux touches flechees, sans framework externe.
- PDF 16:9: compilation via Chromium headless garantissant un rendu vectoriel sans saut de page intempestif.

---

## Evaluation FinOps et Suivi des Depenses

La fonction `calculate_finops_cost` detaille la consommation de chaque traitement:

1. Mesure des couts d'API au jeton:
   - Decompte des jetons d'entree et de sortie.
   - Application des grilles officielles par million de jetons.
   - Conversion en dollars et en euros (taux de change retenu: 0.92 € / $).

2. Evaluation des gains lies au calcul local:
   - Comparaison avec le tarif standard des services cloud de transcription audio (0.006 $ par minute).
   - Sur un atelier de 7 minutes: gain de 0.042 $.
   - Sur une reunion de 1 heure 10 minutes: gain de 0.42 $.

3. Couts d'API constates:
   - Une execution courte de 7 a 10 minutes engendre environ 0.0015 € de requete LLM.
   - Une reunion d'une heure reste sous le seuil de 0.05 € d'API.
   - Le detail comptable est consigne dans [`output/finops_report.json`](./output/finops_report.json).

---

## Guide d'Utilisation

### Methode Windows en interface graphique

1. Installation:
   Double-cliquez sur `INSTALLER_WINDOWS.bat`. Selectionnez votre fournisseur d'IA, renseignez votre cle d'acces puis cliquez sur "Installer & Configurer".

2. Conversion via le menu contextuel:
   Sur un fichier `.mp4`:
   - Sous Windows 11: clic droit sur la video, selectionnez "Afficher d'autres options" (ou utilisez le raccourci `Maj + F10`), puis cliquez sur "Convertir avec Video2PowerPoint (IA)".
   - Sous Windows 10: clic droit sur la video puis cliquez sur "Convertir avec Video2PowerPoint (IA)".

3. Conversion via le lanceur:
   Double-cliquez sur `LANCER_PIPELINE.bat` (ou sur le raccourci du Bureau):
   - Appuyez sur Entree pour traiter la video de test integree (7 minutes).
   - Tapez 2 pour selectionner un fichier video sur votre disque via l'explorateur.
   - Tapez 3 pour indiquer une URL Google Drive.

A l'issue de l'operation, le repertoire contenant les 7 livrables s'ouvre avec un message de confirmation.

---

### Methode Ligne de Commande (CLI)

Le moteur s'execute via PowerShell ou directement avec l'interpreteur Python:

```powershell
# 1. Execution via l'orchestrateur PowerShell
.\run_pipeline.ps1 -VideoPath "C:\Videos\session.mp4" -Provider openai -ModelSize medium

# 2. Execution via l'interpreteur Python
.\.venv\Scripts\python.exe pipeline.py --video "C:\Videos\session.mp4" --output "C:\Livrables" --provider openai --slides 20

# 3. Traitement d'un lien Google Drive
.\.venv\Scripts\python.exe pipeline.py --video "https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing" --provider gemini

# 4. Regeneration documentaire a partir d'une transcription existante
.\.venv\Scripts\python.exe pipeline.py --video "C:\Videos\session.mp4" --skip-transcription
```

### Parametres du script `pipeline.py`

| Parametre | Type | Valeur par defaut | Description |
| :--- | :---: | :---: | :--- |
| `--video` | `str` | Requis | Chemin local vers le fichier `.mp4` ou URL Google Drive. |
| `--output` | `str` | `output` | Dossier de destination des livrables. |
| `--model` | `str` | `medium` | Taille du modele Whisper (`tiny`, `base`, `small`, `medium`, `large-v3-turbo`). |
| `--provider` | `str` | `gemini` | Fournisseur de synthese (`openai`, `gemini`, `mistral`). |
| `--api-key` | `str` | Variable d'environnement | Cle d'API pour le fournisseur selectionne. |
| `--slides` | `int` | `0` (automatique) | Nombre cible de diapositives (0 pour calcul automatique selon la duree). |
| `--skip-transcription` | `flag` | `False` | Reutilise le fichier `transcript.md` existant sans relancer l'inference vocale. |

---

## Banc d'Essai et Tests Automatises (`tests/`)

Une suite de 23 tests automatises validee par `pytest` verifie le bon fonctionnement du moteur:

- `test_environment_sanity.py` (2 tests): controle la presence du binaire `ffmpeg` et l'import des bibliotheques obligatoires (`faster-whisper`, `scenedetect`, `docx`, `pptx`, `PIL`).
- `test_units.py` (16 tests): valide les horodatages, l'extraction des identifiants Google Drive, les filtres lexicaux anti-cliches et les formules FinOps pour OpenAI, Gemini et Whisper.
- `test_generators.py` (4 tests): valide la structure du document Word, du fichier PowerPoint 16:9, du deck HTML et de la conversion PDF.
- `test_pipeline_e2e.py` (1 test): test d'integration global verifiant la production conjointe des 7 livrables.

Pour executer la suite de tests:
```cmd
LANCER_TESTS.bat
```
Ou via la commande:
```powershell
.\.venv\Scripts\python.exe -m pytest tests -s -v
```

---

## Structure du Repertoire `demo/`

```text
demo/
├── assets/
│   ├── app_icon.ico           # Icone multi-resolution (16x16 a 256x256) pour Windows
│   └── app_icon.png           # Fichier image source du logo
├── output/                    # Repertoire des livrables de la video de demonstration
│   ├── keyframes/             # Captures d'ecran extraites (slide_keyframe_XX.jpg)
│   ├── transcript.md          # Transcription textuelle complete horodatee
│   ├── summary.md             # Synthese executive et section FinOps
│   ├── finops_report.json     # Rapport comptable de l'execution
│   ├── article_mode_d_emploi.docx # Document Word operationnel
│   ├── presentation.pptx      # Diaporama PowerPoint 16:9
│   ├── presentation.html      # Support web interactif plein ecran
│   ├── presentation.pdf       # Export PDF paysage 16:9
│   └── deck_structure.json    # Schema JSON intermediaire de la presentation
├── tests/                     # Suite de tests automatises (23 tests)
│   ├── conftest.py            # Donnees de test et bouchons partages
│   ├── test_environment_sanity.py # Verification de l'environnement d'execution
│   ├── test_units.py          # Tests unitaires: Drive, FinOps, regles de filtrage
│   ├── test_generators.py     # Verification des formats de sortie
│   └── test_pipeline_e2e.py   # Test d'integration de bout en bout
├── pipeline.py                # Moteur d'orchestration (Whisper, Drive, LLM, exports)
├── run_pipeline.ps1           # Wrapper d'execution PowerShell
├── install_gui.ps1            # Assistant graphique d'installation Windows
├── INSTALLER_WINDOWS.bat      # Lanceur d'installation rapide
├── LANCER_PIPELINE.bat        # Lanceur de traitement avec menu de selection
├── LANCER_TESTS.bat           # Lanceur de la suite de tests unitaires
├── pytest.ini                 # Options de configuration de pytest (-s -v)
├── requirements.txt           # Dependances Python figees
├── prd.md                     # Cahier des charges fonctionnel
├── addendum.md                # Note d'architecture technique
└── README.md                  # Documentation technique du module
```
