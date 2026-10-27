# Module de traitement vidéo (`demo/`)

Ce dossier rassemble l'ensemble des scripts nécessaires pour transformer un enregistrement vidéo en documents de travail complets et prêts à l'emploi.

> **Note :** Le pipeline automatisé et les flux d'export sont fonctionnels. L'UI reste à mettre en place !

---

## Contenu du dossier

```text
demo/
├── output/                    # Dossier recevant les livrables finaux
│   ├── transcript.md          # Transcription intégrale horodatée
│   ├── summary.md             # Synthèse textuelle enrichie de l'évaluation FinOps
│   ├── finops_report.json     # Rapport FinOps structuré (tokens, coûts et économies)
│   ├── article_mode_d_emploi.docx # Note de synthèse Word illustrée
│   ├── presentation.pptx      # Support PowerPoint 16:9
│   ├── presentation.html      # Présentation web interactive plein écran
│   ├── presentation.pdf       # Export PDF 16:9
│   ├── deck_structure.json    # Données intermédiaires des diapositives
│   └── keyframes/             # Images stables extraites de la vidéo
├── LANCER_PIPELINE.bat        # Fichier à double-cliquer pour démarrer
├── LANCER_TESTS.bat           # Lanceur du banc d'essai et tests automatisés
├── INSTALLER_WINDOWS.bat      # Assistant de configuration graphique
├── tests/                     # Suite de tests automatisés (23 tests pytest)
├── pytest.ini                 # Configuration du banc de test
├── pipeline.py                # Moteur Python (Whisper, Google Drive, LLM, exports)
├── run_pipeline.ps1           # Script PowerShell orchestrateur
├── requirements.txt           # Dépendances Python requises
├── prd.md                     # Spécifications fonctionnelles
├── addendum.md                # Choix d'architecture technique
└── README.md                  # Ce document
```

---

## Prise en main directe (sans compétences techniques)

1. **Installation initiale** :  
   Double-cliquez sur `INSTALLER_WINDOWS.bat` (à la racine ou dans ce dossier). Renseignez votre clé d'accès (OpenAI, Gemini ou Mistral), puis cliquez sur **« Installer & Configurer »**.  
   Un raccourci est déposé sur votre Bureau et une commande est ajoutée au menu clic droit de Windows.

2. **Traitement d'une vidéo** :
   - Soit par un **clic droit sur votre fichier vidéo (`.mp4`)** :
     - Sur **Windows 11** : faites un clic droit, cliquez sur **« Afficher d'autres options »** (ou `Maj + F10`), puis choisissez **« Convertir avec Video2PowerPoint (IA) »**.
     - Sur **Windows 10** : choisissez directement **« Convertir avec Video2PowerPoint (IA) »**.
   - Soit en double-cliquant sur **`LANCER_PIPELINE.bat`** (ou l'icône sur votre Bureau) :
     - Appuyez sur **Entrée** pour télécharger et tester la vidéo d'exemple Google Drive (7 minutes).
     - Ou tapez **2** pour choisir un fichier sur votre ordinateur via l'explorateur Windows.
     - Ou tapez **3** pour coller un lien Google Drive / URL de vidéo.
     - Ou glissez-déposez votre vidéo dans la console.

### Suivi de l'avancement :
- **Barre de progression en console** : pourcentage, durée traitée et temps restant affichés en direct via `tqdm`.
- **Écriture progressive** : `transcript.md` est mis à jour segment par segment en continu.
- **Diapositives adaptatives** : 10 slides (< 10 min) à 25-35 slides (> 1h), ou réglable via `--slides N`.

### Emplacement de vos livrables :
- **Pour une vidéo de votre choix** : un dossier dédié **`<NomDeLaVideo>_livrables`** est automatiquement créé **directement à côté de votre vidéo** (ex: sur votre Bureau si la vidéo s'y trouve).
- **Pour la vidéo d'exemple** : les fichiers sont dans le dossier **[`output/`](./output/)**.
- Dans tous les cas, l'Explorateur Windows s'ouvre automatiquement à la fin et une boîte de confirmation vous indique l'adresse complète.

---

## Vidéo d'exemple

Pour tester le fonctionnement sans enregistrement sous la main, la vidéo d'essai de 7 minutes (*Too Fast to Think*) est disponible en téléchargement :
- [Lien de téléchargement Google Drive](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)

Ses résultats de calcul sont déjà stockés dans le dossier [`output/`](./output/) pour consultation immédiate.

---

## Options avancées en ligne de commande (PowerShell)

Pour intégrer ce traitement dans un script ou l'exécuter depuis un terminal :

```powershell
# Traitement direct d'un fichier local avec le modèle Whisper medium
.\run_pipeline.ps1 -VideoPath "C:\Videos\reunion.mp4" -ModelSize "medium"

# Traitement direct à partir d'un lien Google Drive
.\run_pipeline.ps1 -VideoPath "https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing"

# Spécifier le modèle de langage
.\run_pipeline.ps1 -Provider mistral

# Reprise rapide en réutilisant la transcription existante
.\run_pipeline.ps1 -SkipTranscription
```
