# Module de traitement vidéo (`demo/`)

Ce dossier rassemble l'ensemble des scripts nécessaires pour convertir un enregistrement vidéo en présentations et synthèses prêtes à l'emploi.

---

## Contenu du dossier

```text
demo/
├── output/                    # Dossier recevant les livrables finaux
│   ├── transcript.md          # Transcription intégrale horodatée
│   ├── summary.md             # Synthèse textuelle courte
│   ├── article_mode_d_emploi.docx # Note de cadrage Word illustrée
│   ├── presentation.pptx      # Diaporama PowerPoint 16:9
│   ├── presentation.html      # Présentation web plein écran
│   ├── presentation.pdf       # Export PDF 16:9
│   ├── deck_structure.json    # Données intermédiaires des diapositives
│   └── keyframes/             # Captures d'écran extraites de la vidéo
├── LANCER_PIPELINE.bat        # Lanceur en un clic
├── INSTALLER_WINDOWS.bat      # Assistant d'installation graphique
├── pipeline.py                # Moteur Python (Whisper, scènes, LLM, exports)
├── run_pipeline.ps1           # Orchestrateur PowerShell avec sélection interactive
├── requirements.txt           # Dépendances Python
├── prd.md                     # Spécifications fonctionnelles
├── addendum.md                # Choix d'architecture
└── README.md                  # Ce document
```

---

## Prise en main

Aucune configuration manuelle de Python n'est requise.

### Première utilisation
Double-cliquez sur `INSTALLER_WINDOWS.bat` pour configurer votre clé d'accès (OpenAI, Gemini ou Mistral), créer le raccourci sur le Bureau et activer le clic droit Windows.

### Traiter une vidéo
Deux options selon vos habitudes :
- **Au clic droit** : faites un clic droit sur n'importe quel fichier vidéo (`.mp4`) puis sélectionnez **Convertir avec Video2PowerPoint (IA)**.
- **Depuis le lanceur** : double-cliquez sur `LANCER_PIPELINE.bat` (ou le raccourci Bureau). Le programme vous propose de valider la vidéo d'exemple avec Entrée, ou de taper 2 pour aller chercher un autre fichier dans vos dossiers.

Le dossier `output/` s'ouvre automatiquement dès que les fichiers sont prêts.

---

## Vidéo d'exemple

Pour tester le système sans enregistrement sous la main, la vidéo d'essai de 7 minutes (*Too Fast to Think*) est disponible en téléchargement :
- [Lien de téléchargement Google Drive](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)

Ses résultats de calcul sont déjà stockés dans le dossier [`output/`](./output/) pour consultation immédiate.

---

## Utilisation avancée en ligne de commande

Si vous préférez lancer le script depuis un terminal ou un automate :

```powershell
# Traitement direct avec le modèle Whisper medium
.\run_pipeline.ps1 -VideoPath "C:\Videos\reunion.mp4" -ModelSize "medium"

# Spécifier le modèle de langage
.\run_pipeline.ps1 -Provider mistral

# Réutiliser une transcription existante (gain de temps)
.\run_pipeline.ps1 -SkipTranscription
```
