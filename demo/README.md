# Module de traitement vidéo (`demo/`)

Ce dossier regroupe le script d'automatisation et les fichiers nécessaires pour transformer un enregistrement vidéo en plusieurs documents de travail prêts à l'emploi.

---

## Organisation du dossier

```text
demo/
├── output/                    # Dossier recevant les livrables finaux
│   ├── transcript.md          # Transcription intégrale horodatée
│   ├── summary.md             # Synthèse textuelle
│   ├── article_mode_d_emploi.docx # Note de synthèse Word illustrée
│   ├── presentation.pptx      # Support PowerPoint 16:9
│   ├── presentation.html      # Présentation HTML autonome
│   ├── presentation.pdf       # Export PDF 16:9
│   ├── deck_structure.json    # Données intermédiaires des diapositives
│   └── keyframes/             # Images stables extraites de la vidéo
├── LANCER_PIPELINE.bat        # Fichier à double-cliquer pour démarrer
├── INSTALLER_WINDOWS.bat      # Assistant de configuration graphique
├── pipeline.py                # Script Python principal
├── run_pipeline.ps1           # Script PowerShell orchestrateur
├── requirements.txt           # Liste des dépendances Python
├── prd.md                     # Cahier des charges et spécifications
├── addendum.md                # Choix d'architecture technique
└── README.md                  # Ce document
```

---

## Que doit faire un utilisateur non technique ?

Aucune commande complexe ni installation manuelle de Python n'est nécessaire.

1. **Première fois** : double-cliquez sur `INSTALLER_WINDOWS.bat`, saisissez votre clé d'accès (OpenAI, Gemini ou Mistral), puis cliquez sur **« Installer & Configurer »**.
2. **Pour traiter une vidéo** :
   - Soit par un clic droit sur votre fichier vidéo (`.mp4`) : choisissez **« Convertir avec Video2PowerPoint (IA) »**.
   - Soit en double-cliquant sur **`LANCER_PIPELINE.bat`** : appuyez sur la touche Entrée pour choisir votre vidéo dans l'explorateur de fichiers.
3. Dès que le traitement est terminé, le dossier **`output/`** s'ouvre automatiquement avec tous vos documents prêts.

*Note : si un avertissement technique apparaît dans la console (par exemple au sujet des symlinks Windows de Hugging Face), vous n'avez rien à faire : ce n'est pas une erreur et cela n'empêche aucunement la génération des documents.*

---

## Vidéo d'exemple

Pour tester le fonctionnement sans disposer immédiatement d'un enregistrement sous la main, une vidéo de 7 minutes (*Too Fast to Think*) est disponible en téléchargement :
- [Lien Google Drive](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)

Les fichiers issus de cette vidéo sont déjà présents dans le dossier [`output/`](./output/) pour consultation directe.

---

## Options avancées en ligne de commande (PowerShell)

Pour intégrer ce traitement dans un script ou l'exécuter depuis un terminal :

```powershell
# Traitement direct d'un fichier avec le modèle Whisper medium
.\run_pipeline.ps1 -VideoPath "C:\Videos\reunion.mp4" -ModelSize "medium"

# Forcer l'utilisation de Mistral
.\run_pipeline.ps1 -Provider mistral

# Reprise sans réexécuter la transcription si transcript.md existe déjà
.\run_pipeline.ps1 -SkipTranscription
```
