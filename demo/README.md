# Module de traitement vidéo (`demo/`)

Ce dossier regroupe le script d'automatisation et les fichiers nécessaires pour transformer un fichier vidéo en plusieurs documents de restitution.

---

## Contenu du dossier

```text
demo/
├── output/                    # Dossier recevant les livrables générés
│   ├── transcript.md          # Transcription intégrale horodatée
│   ├── summary.md             # Synthèse textuelle courte
│   ├── article_mode_d_emploi.docx # Note de synthèse Word illustrée
│   ├── presentation.pptx      # Support PowerPoint 16:9
│   ├── presentation.html      # Présentation HTML autonome
│   ├── presentation.pdf       # Export PDF 16:9
│   ├── deck_structure.json    # Données intermédiaires des diapositives
│   └── keyframes/             # Images extraites de la vidéo
├── LANCER_PIPELINE.bat        # Fichier à double-cliquer pour démarrer
├── INSTALLER.bat              # Script optionnel de pré-installation
├── pipeline.py                # Script Python principal
├── run_pipeline.ps1           # Script PowerShell orchestrateur
├── requirements.txt           # Liste des dépendances Python
├── prd.md                     # Cahier des charges et spécifications
├── addendum.md                # Choix d'architecture technique
└── README.md                  # Ce document
```

---

## Vidéo d'exemple

Pour tester le fonctionnement sans disposer immédiatement d'un enregistrement sous la main, une vidéo de 7 minutes (*Too Fast to Think*) est disponible en téléchargement :
- [Lien Google Drive](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)

Les fichiers issus de cette vidéo sont déjà présents dans le dossier [`output/`](./output/) pour consultation directe.

---

## Utilisation

Aucune installation préalable de Python n'est nécessaire sur l'ordinateur hôte.

### 1. Installation en un clic (recommandé)
Double-cliquez sur `INSTALLER_WINDOWS.bat` pour configurer l'outil :
- Renseignez votre clé d'accès (OpenAI, Gemini ou Mistral),
- Activez le raccourci sur le Bureau et l'option Clic Droit Windows sur les vidéos.

### 2. Traitement d'une vidéo
- **Par Clic Droit** : Clic droit sur n'importe quel fichier `.mp4` -> *« Convertir avec Video2PowerPoint (IA) »*.
- **Ou via `LANCER_PIPELINE.bat`** : Double-cliquez dessus. Si aucune vidéo n'est présente dans le dossier, appuyez sur Entrée pour la sélectionner dans l'explorateur Windows habituel.

Le dossier `output/` s'ouvre automatiquement dès que les fichiers sont prêts.

---

## Paramètres avancés (PowerShell)

Pour les utilisateurs qui souhaitent intégrer ce traitement dans un script ou l'exécuter depuis un terminal :

```powershell
# Traitement direct d'un fichier avec le modèle Whisper medium
.\run_pipeline.ps1 -VideoPath "C:\Videos\reunion.mp4" -ModelSize "medium"

# Forcer l'utilisation de Mistral
.\run_pipeline.ps1 -Provider mistral

# Reprise sans réexécuter la transcription si transcript.md existe déjà
.\run_pipeline.ps1 -SkipTranscription
```
