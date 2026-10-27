# Moteur de Traitement Vidéo & Génération de Decks Multi-Formats (`demo/`)

Ce dossier constitue le cœur opérationnel de l'application. Il embarque l'ensemble de la chaîne de traitement permettant de transformer un fichier vidéo brut (atelier, formation, réunion d'équipe, webinaire ou conférence) en **7 livrables stratégiques et opérationnels** directement exploitables en entreprise.

> **Note d'avancement :** Le pipeline automatisé, les scripts d'export, le module d'installation Windows et les intégrations système sont opérationnels. L'UI reste à mettre en place !

---

## 📑 Les 7 Livrables Stratégiques Générés

Chaque exécution produit un ensemble complet de documents dans le dossier de destination (dans un sous-dossier dédié `<NomDeLaVideo>_livrables` situé immédiatement à côté de votre vidéo personnelle, ou dans [`demo/output/`](./output/) pour la vidéo d'essai) :

| Livrable | Fichier généré | Format | Rôle & Description |
| :--- | :--- | :---: | :--- |
| **Note de Cadrage & Guide** | [`article_mode_d_emploi.docx`](./output/article_mode_d_emploi.docx) | `.docx` | Document Word complet structuré en 5 à 10 sections opérationnelles. Comprend constats chiffrés, recommandations concrètes, encadrés méthodologiques et captures visuelles extraites de la vidéo. |
| **Diaporama Stratégique** | [`presentation.pptx`](./output/presentation.pptx) | `.pptx` | Présentation PowerPoint native au format large **16:9 widescreen**, chartée avec typographies modernes (Calibri/Segoe UI), puces aérées, indicateurs clés et visuels synchronisés. |
| **Deck Web Interactif** | [`presentation.html`](./output/presentation.html) | `.html` | Présentation plein écran autonome (*zero-dependency*), navigable au clavier (flèches, espace), lisible hors-ligne avec images intégrées en Base64. |
| **Export Imprimable 16:9** | [`presentation.pdf`](./output/presentation.pdf) | `.pdf` | Rendu vectoriel paysage haute définition page par page, sans aucune coupure de diapositive, généré via moteur Chromium headless. |
| **Synthèse Exécutive** | [`summary.md`](./output/summary.md) | `.md` | Synthèse textuelle dense des messages essentiels, arbitrages managériaux et décisions prises, enrichie du bilan d'évaluation FinOps. |
| **Bilan FinOps** | [`finops_report.json`](./output/finops_report.json) | `.json` | Rapport financier et comptable détaillant le nombre exact de tokens consommés, les coûts d'API facturés en dollars et en euros, et les économies de calcul local. |
| **Transcription Intégrale** | [`transcript.md`](./output/transcript.md) | `.md` | Transcription textuelle exhaustive horodatée seconde par seconde avec identification de la langue et de la durée. |
| **Captures Clés (Keyframes)** | [`keyframes/`](./output/keyframes/) | `.jpg` | Sélection de 18 à 40 diapositives et moments stables extraits en haute résolution 1080p. |

---

## 🏗 Architecture Technique du Pipeline (5 Étapes)

Le traitement s'articule autour de cinq phases automatisées et résilientes :

```text
Vidéo MP4 (Locale ou Google Drive)
   │
   ├─► [Étape 1] Extraction Audio Haute-Fidélité (ffmpeg 16 kHz WAV mono)
   │
   ├─► [Étape 2] Transcription Locale Whisper (faster-whisper int8 CPU/CUDA)
   │      └─► Progression dynamique (tqdm) & écriture au fil de l'eau sur disque
   │
   ├─► [Étape 3] Détection Intelligente des Scènes (PySceneDetect + OpenCV)
   │      └─► Extraction sélective de keyframes 1080p stables
   │
   ├─► [Étape 4] Synthèse & Modélisation LLM (OpenAI / Gemini / Mistral)
   │      ├─► Directives strictes Humanizer (zéro jargon IA, zéro clichés)
   │      ├─► Nombre de slides adaptatif (10 à 35 selon la durée)
   │      └─► Calculateur de métriques et rapport FinOps
   │
   └─► [Étape 5] Production Multi-Formats des Livrables
          ├─► 5A. Document Word opérationnel (python-docx)
          ├─► 5B. Présentation PowerPoint 16:9 (python-pptx)
          ├─► 5C. Deck Web interactif (HTML5 / CSS3 Grid)
          └─► 5D. Export PDF 16:9 vectoriel (Chromium headless)
```

### 1. Extraction Audio (`extract_audio`)
* Extraction de la bande sonore via un binaire autonome `ffmpeg` (embarqué via `imageio-ffmpeg`, aucune installation système requise).
* Normalisation audio : canal mono, fréquence 16 000 Hz, encodage PCM 16 bits linéaire (`pcm_s16le`), calibré pour les modèles de reconnaissance vocale neuronale.

### 2. Transcription Locale Whisper (`transcribe_audio`)
* Utilise **`faster-whisper`** adossé au runtime CTranslate2 pour une vitesse d'inférence jusqu'à 4x supérieure à l'implémentation PyTorch originale.
* **Autonomie totale** : fonctionne 100% en local, sans envoyer la moindre bribe d'audio sur un serveur tiers. Confidentialité absolue garantie pour les réunions internes.
* **Tolérance aux pannes & repli transparent** : tentative d'accélération matérielle sur GPU Nvidia (CUDA float16), avec bascule automatique sur CPU multi-cœurs (quantification int8) si aucun GPU n'est détecté.
* **Suivi en temps réel** : barre de progression `tqdm` affichant seconde par seconde la durée décodée, le pourcentage et l'estimation de fin.
* **Écriture progressive au fil de l'eau** : les segments transcrits sont immédiatement flushés dans `transcript.md` sur le disque dès leur décodage.

### 3. Détection des Scènes & Keyframes (`extract_scenes`)
* Analyse vidéo via `scenedetect.detect` avec détection de contenu adaptative (`ContentDetector`).
* Filtrage des faux positifs (animations, gestes légers) pour n'isoler que les transitions réelles de diapositives ou de sujets.
* Dimensionnement adaptatif : extrait de 18 à 40 captures clés selon la durée de la vidéo.

### 4. Structuration & Synthèse Humanizer (`analyze_with_llm`)
* Sollicite au choix l'API **OpenAI** (`gpt-4o-mini`), **Google Gemini** (`gemini-2.0-flash`) ou **Mistral AI** (`mistral-large-latest`).
* **Charte rédactionnelle Humanizer stricte** :
  * Interdiction absolue des formules d'introduction mécaniques (*« Dans un monde en constante évolution... »*, *« À l'ère du numérique... »*).
  * Interdiction des métaphores grandiloquentes (*« nourrir l'âme »*, *« trésors cachés »*, *« libérer le potentiel »*, *« catalyseur »*, *« pierre angulaire »*).
  * Interdiction du gras mécanique systématique sur chaque puce (`**Mot** : ...`).
  * Post-filtrage programmatique systématique via `clean_humanizer_text` et `apply_humanizer_filter` pour éliminer tout tic d'écriture résiduel.
* **Volume proportionnel** : le nombre de slides est ajusté automatiquement à la densité temporelle de l'enregistrement (10 pour < 10 min, 18 pour 30 min, 25 à 35 pour > 1 heure).

### 5. Génération Native des Documents
* **Word (.docx)** : mise en page soignée avec palette corporate, typographie hiérarchisée, puces directes et insertion des captures visuelles en pleine largeur.
* **PowerPoint (.pptx)** : matrice 16:9 widescreen (13.33 x 7.5 pouces), fond ardoise sombre moderne (`#0B0F19`), titres contrastés et métriques KPI mises en avant.
* **Deck HTML** : fichier unique autonome, sans framework lourd, avec transitions fluides et navigation clavier réactive.
* **PDF 16:9** : compilation Chromium headless pour un rendu vectoriel sans artefact.

---

## 📊 Maîtrise des Coûts & Démarche FinOps

Le module FinOps intégré (`calculate_finops_cost`) chiffre avec exactitude la consommation de chaque run :

1. **Calcul des coûts LLM au jeton près** :
   * Mesure des tokens de prompt (entrée) et de génération (sortie).
   * Application de la grille tarifaire officielle par million de tokens.
   * Conversion automatique en dollars et en euros (taux de référence `0.92 € / $`).
2. **Économies de calcul local** :
   * Valorisation de la transcription locale Whisper par comparaison avec le tarif standard des API cloud de transcription vocale (0,006 $/minute).
   * Sur une vidéo de 7 minutes : **+0,042 $** économisés.
   * Sur une réunion de 1h10 : **+0,42 $** d'économies directes.
3. **Coût total de revient** :
   * Une session courte de 7 à 10 minutes coûte en moyenne **0,0015 € d'API**.
   * Une réunion complète de plus d'une heure coûte moins de **0,05 € d'API**.
   * Les résultats sont consignés dans [`output/finops_report.json`](./output/finops_report.json).

---

## 🚀 Guide d'Utilisation

### Option A : Utilisateur Non-Technique (Recommandé)

1. **Installation 1-Clic** :  
   Double-cliquez sur **`INSTALLER_WINDOWS.bat`**. Choisissez votre fournisseur d'IA, collez votre clé d'accès et cliquez sur **« Installer & Configurer »**.
2. **Traitement au Clic Droit** :  
   Sur n'importe quel fichier `.mp4` :
   * **Windows 11** : Clic droit ➔ **« Afficher d'autres options »** (ou `Maj + F10`) ➔ **« Convertir avec Video2PowerPoint (IA) »**.
   * **Windows 10** : Clic droit ➔ **« Convertir avec Video2PowerPoint (IA) »**.
3. **Traitement via le Lanceur** :  
   Double-cliquez sur **`LANCER_PIPELINE.bat`** (ou le raccourci Bureau) :
   * Appuyez sur **Entrée** pour tester la vidéo d'exemple (7 min).
   * Ou tapez **2** pour désigner une vidéo sur votre disque via l'explorateur.
   * Ou tapez **3** pour coller un lien Google Drive.

Dès la fin du traitement, le dossier des résultats s'ouvre automatiquement avec une boîte de dialogue de confirmation.

---

### Option B : Développeur & Ligne de Commande (CLI)

Vous pouvez piloter directement le moteur en Python ou via le wrapper PowerShell :

```powershell
# 1. Exécution via le script PowerShell orchestrateur
.\run_pipeline.ps1 -VideoPath "C:\Videos\ma_session.mp4" -Provider openai -ModelSize medium

# 2. Exécution directe avec l'environnement virtuel Python
.\.venv\Scripts\python.exe pipeline.py --video "C:\Videos\ma_session.mp4" --output "C:\Livrables" --provider openai --slides 20

# 3. Traitement direct d'un lien Google Drive (téléchargement par blocs et reprise)
.\.venv\Scripts\python.exe pipeline.py --video "https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing" --provider gemini

# 4. Reprise rapide sans réexécuter la transcription audio
.\.venv\Scripts\python.exe pipeline.py --video "C:\Videos\ma_session.mp4" --skip-transcription
```

### Paramètres de la CLI Python (`pipeline.py`)

| Argument | Type | Défaut | Description |
| :--- | :---: | :---: | :--- |
| `--video` | `str` | *Requis* | Chemin local vers le fichier `.mp4` ou URL Google Drive / HTTP directe. |
| `--output` | `str` | `output` | Dossier de destination recevant les livrables finaux. |
| `--model` | `str` | `medium` | Modèle Whisper (`tiny`, `base`, `small`, `medium`, `large-v3-turbo`). |
| `--provider` | `str` | `gemini` | Moteur LLM (`openai`, `gemini`, `mistral`). |
| `--api-key` | `str` | Variable d'env | Clé d'API (ou lue dans `.env` / variable d'environnement). |
| `--slides` | `int` | `0` (auto) | Nombre exact de diapositives souhaité (0 = adaptatif selon la durée). |
| `--skip-transcription` | `flag` | `False` | Réutilise le fichier `transcript.md` existant pour régénérer rapidement les livrables. |

---

## 🧪 Banc d'Essai & Validation (`tests/`)

Une suite de **23 tests automatisés** avec `pytest` garantit la fiabilité et la non-régression du moteur :

* **`test_environment_sanity.py` (2 tests)** :  
  Vérifie la disponibilité effective de `ffmpeg` autonome et le chargement de toutes les bibliothèques requises (`faster-whisper`, `scenedetect`, `docx`, `pptx`, `PIL`).
* **`test_units.py` (16 tests)** :  
  Contrôle la fonction de formatage des horodatages, l'extraction robuste des identifiants Google Drive (formats web, direct, open, id brut), l'application des règles Humanizer anti-clichés et les calculs du module FinOps pour OpenAI, Gemini et l'évaluation des économies Whisper.
* **`test_generators.py` (4 tests)** :  
  Vérifie l'intégrité structurelle des fichiers Word (`.docx`), du format 16:9 widescreen PowerPoint (`.pptx`), du deck HTML autonome et de la conversion PDF headless.
* **`test_pipeline_e2e.py` (1 test)** :  
  Harness de bout en bout simulant le cycle de vie complet du pipeline avec validation de la production simultanée des 7 livrables.

Pour exécuter la suite de tests complète :
```cmd
LANCER_TESTS.bat
```
*(ou en ligne de commande : `.\.venv\Scripts\python.exe -m pytest tests -s -v`)*

---

## 📂 Organisation Détaillée du Dossier `demo/`

```text
demo/
├── assets/
│   ├── app_icon.ico           # Icône multi-résolution (16x16 à 256x256) pour raccourcis Windows
│   └── app_icon.png           # Logo visuel de l'application
├── output/                    # Dossier recevant les livrables de la vidéo d'essai
│   ├── keyframes/             # Captures d'écran stables (slide_keyframe_XX.jpg)
│   ├── transcript.md          # Transcription textuelle complète horodatée
│   ├── summary.md             # Synthèse exécutive et section FinOps
│   ├── finops_report.json     # Rapport comptable détaillé de l'exécution
│   ├── article_mode_d_emploi.docx # Guide Word opérationnel illustré
│   ├── presentation.pptx      # Support PowerPoint 16:9
│   ├── presentation.html      # Présentation web interactive plein écran
│   ├── presentation.pdf       # Export PDF paysage 16:9
│   └── deck_structure.json    # Schéma JSON intermédiaire validé
├── tests/                     # Suite de tests automatisés (23 tests)
│   ├── conftest.py            # Fixtures partagées et données de mock
│   ├── test_environment_sanity.py # Tests d'intégrité de l'environnement
│   ├── test_units.py          # Tests unitaires, regex Drive, Humanizer et FinOps
│   ├── test_generators.py     # Tests de conformité des générateurs de documents
│   └── test_pipeline_e2e.py   # Banc d'essai bout en bout
├── pipeline.py                # Moteur principal Python (Whisper, Drive, LLM, Exports)
├── run_pipeline.ps1           # Wrapper orchestrateur PowerShell (autonome via uv)
├── install_gui.ps1            # Assistant graphique d'installation Windows (WinForms)
├── INSTALLER_WINDOWS.bat      # Lanceur 1-clic de l'installeur (UTF-8 chcp 65001)
├── LANCER_PIPELINE.bat        # Lanceur 1-clic du traitement avec gestion du menu
├── LANCER_TESTS.bat           # Lanceur 1-clic de la suite de tests pytest
├── pytest.ini                 # Configuration standard de pytest (-s -v)
├── requirements.txt           # Liste des dépendances Python figées
├── prd.md                     # Cahier des charges et spécifications fonctionnelles
├── addendum.md                # Note d'arbitrage et choix d'architecture technique
└── README.md                  # Ce guide technique complet
```
