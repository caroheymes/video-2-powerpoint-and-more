# Pipeline Vidéo ➔ Transcription, Synthèse & Decks Stratégiques

Solution clé en main pour transformer une vidéo longue (jusqu'à 2 heures) en un pack de livrables professionnels de niveau cabinet de conseil :
1. **Transcription complète horodatée** (`transcript.md`) via Whisper Local.
2. **Synthèse exécutive en français** (`summary.md`) via API Gemini ou Mistral.
3. **Article de fond & Mode d'emploi pratique** (`article_mode_d_emploi.docx`) sous Microsoft Word avec captures et encadrés.
4. **Deck PowerPoint 16:9** (`presentation.pptx`) avec texte & captures vidéo intégrées.
5. **Deck Web interactif & PDF 16:9** (`presentation.html` & `presentation.pdf`) conforme aux standards ECC `frontend-slides`.

---

## Démarrage Rapide (En 1 Clic / Double-Clic)

Pour les utilisateurs non techniques, deux fichiers exécutables `.bat` sont fournis :

### 1. Déposez votre vidéo
Copiez votre fichier vidéo (ex: `reunion_client.mp4`) directement dans ce dossier `demo/`.

### 2. Double-cliquez sur `LANCER_PIPELINE.bat`
* **Zéro ligne de commande à taper** : Double-cliquez simplement sur [**`LANCER_PIPELINE.bat`**](file:///C:/Users/Admin/Desktop/smac/livrable/demo/LANCER_PIPELINE.bat).
* Le script configure automatiquement Python, installe les dépendances nécessaires dans un environnement virtuel local (`.venv`) sans modifier votre système, et lance le traitement.
* À la fin de l'exécution, **le dossier des livrables s'ouvre automatiquement dans l'Explorateur Windows** !

### 3. Saisie de la Clé API (au premier lancement uniquement)
Le script vous demandera une clé d'accès LLM pour la synthèse :
- **Option 1 : Google Gemini** *(Recommandé, gratuit sur [aistudio.google.com](https://aistudio.google.com))*
- **Option 2 : Mistral AI** *(sur [console.mistral.ai](https://console.mistral.ai))*

Vous pouvez choisir de sauvegarder la clé : elle sera stockée localement dans un fichier `.env` et ne vous sera plus jamais demandée.

---

### Pour les utilisateurs avancés (PowerShell)
Vous pouvez également piloter le pipeline directement en ligne de commande :
```powershell
.\run_pipeline.ps1
```

---

## Options Avancées

Vous pouvez personnaliser l'exécution avec des paramètres :

```powershell
# Traiter une vidéo spécifique avec le modèle Whisper large
.\run_pipeline.ps1 -VideoPath "C:\Chemin\MaVideo.mp4" -ModelSize "large-v3-turbo"

# Forcer l'utilisation de Mistral
.\run_pipeline.ps1 -Provider mistral

# Reprendre sans recalculer la transcription si transcript.md existe déjà
.\run_pipeline.ps1 -SkipTranscription
```

---

## Structure des Livrables Générés (`output/`)

```text
demo/
├── output/
│   ├── transcript.md              # Transcription intégrale horodatée [HH:MM:SS]
│   ├── summary.md                 # Synthèse exécutive en français
│   ├── article_mode_d_emploi.docx # Article & Mode d'emploi Word complet illustré
│   ├── presentation.pptx          # Support de présentation PowerPoint 16:9
│   ├── presentation.html          # Deck web interactif autonome (Base64 embedded)
│   ├── presentation.pdf           # Version imprimable PDF 16:9
│   ├── deck_structure.json        # Modèle de données JSON des slides
│   └── keyframes/                 # Images clés extraites intelligemment de la vidéo
├── pipeline.py                # Moteur Python de traitement média & IA
├── run_pipeline.ps1           # Orchestrateur PowerShell avec auto-bootstrap
├── requirements.txt           # Dépendances Python isolées
├── prd.md                     # Cahier des charges produit (PRD BMad)
└── addendum.md                # Addendum technique d'architecture
```
