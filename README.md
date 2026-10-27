# Boîte à Outils & Pipeline de Restitution Multimédia (ECC & BMad)

Bienvenue dans l'espace de travail **`livrable`**. Ce dossier regroupe à la fois la **solution opérationnelle automatisée** développée pour le traitement de vidéos longues, ainsi que **l'ensemble des compétences ECC et scripts historiques** ayant servi de socle technique.

---

## 📁 Organisation du Dossier

```text
livrable/
├── demo/                   Solution opérationnelle clé en main (Vidéo ➔ Livrables)
│   ├── LANCER_PIPELINE.bat # Double-clic pour lancer le traitement (zéro commande)
│   ├── INSTALLER.bat       # Script optionnel d'installation/vérification préalable
│   ├── run_pipeline.ps1    # Orchestrateur PowerShell avec auto-bootstrap
│   ├── pipeline.py         # Moteur de traitement média, Whisper & IA LLM
│   ├── requirements.txt    # Dépendances isolées (auto-installées via uv)
│   ├── prd.md              # Cahier des charges produit complet (norme BMad)
│   ├── addendum.md         # Addendum technique d'architecture & dimensionnement
│   ├── brief.md            # Brief initial du projet
│   └── README.md           # Documentation détaillée dédiée au pipeline
│
├── scripts_historiques/    📚 Bibliothèque de compétences ECC & Scripts d'export
│   ├── frontend-slides/    # Skill ECC complet pour la création de decks HTML/PDF
│   ├── scripts-export/     # Scripts d'assemblage autonome & export PDF (export_deck.ps1/.py)
│   ├── 3_CONVERTIR_EN_WORD.bat            # Script batch de conversion Word
│   ├── generate_pptx_with_template.py     # Générateur PowerPoint avec template
│   └── README-SLIDES-TOOLKIT.md           # Guide d'utilisation du toolkit slides
│
└── README.md               📋 Ce document (Vue d'ensemble et guide d'orientation)
```

---

## 🚀 1. Le Pipeline Automatisé (`demo/`)

Ce module a été conçu pour un **public non technique** ou des **consultants en cabinet**, garantissant un niveau de finition exécutif pour des vidéos de réunions, comités ou conférences pouvant durer jusqu'à **2 heures**.

### 📦 Les 6 Livrables Générés Automatiquement :
À partir d'un unique fichier vidéo `.mp4`, le pipeline produit dans le sous-dossier `output/` :
1. 📝 **`transcript.md`** : Transcription intégrale horodatée `[HH:MM:SS]` (via Whisper local, sans fuite de données).
2. 📌 **`summary.md`** : Synthèse exécutive structurée en français (Contexte, Enjeux, Décisions, Recommandations).
3. 📘 **`article_mode_d_emploi.docx`** : Document Microsoft Word complet comprenant le mode d'emploi pratique pour les équipes, les encadrés d'alerte, les étapes pas-à-pas et les captures d'écran illustrées.
4. 📊 **`presentation.pptx`** : Support de présentation PowerPoint natif au format panoramique 16:9, intégrant les points clés et les visuels extraits.
5. 🌐 **`presentation.html`** : Deck web interactif conforme aux standards ECC `frontend-slides` (autonome, fluide, images embarquées en Base64, responsive).
6. 📑 **`presentation.pdf`** : Version PDF 16:9 haute résolution prête à être projetée ou transmise au client (générée via moteur Chromium headless).

### ⚡ Démarrage Rapide :
1. Déposez votre vidéo `.mp4` dans le dossier `demo/`.
2. Ouvrez PowerShell dans `demo/` et lancez :
   ```powershell
   .\run_pipeline.ps1
   ```
3. **Au premier lancement** : Le script vous demande une clé d'accès LLM (**Google Gemini** gratuit ou **Mistral AI**) avec saisie masquée sécurisée, et propose de l'enregistrer dans un fichier local `.env` pour ne plus jamais avoir à la saisir.

---

## 📚 2. Bibliothèque Historique & Compétences ECC (`scripts_historiques/`)

Ce sous-dossier conserve les briques de référence et compétences ECC :

* **Skill ECC `frontend-slides`** :
  * [`SKILL.md`](./scripts_historiques/frontend-slides/SKILL.md) : Définition, règles du viewport (`100dvh`, aucun scroll interne) et approche de découverte visuelle.
  * [`STYLE_PRESETS.md`](./scripts_historiques/frontend-slides/STYLE_PRESETS.md) : Catalogue des styles visuels (Bold Signal, Dark Botanical, Swiss Modern, etc.).
  * Scripts d'extraction et d'exportation (`export-pdf.sh`, `extract-pptx.py`).
* **Scripts d'Export & Emballage Autonome (`scripts-export/`)** :
  * [`export_deck.ps1`](./scripts_historiques/scripts-export/export_deck.ps1) & [`export_deck.py`](./scripts_historiques/scripts-export/export_deck.py) : Scripts d'injection CSS `@media print { size: 16in 9in; }`, encodage Base64 et pilotage headless Edge/Chrome.
* **Scripts de Conversion Additionnels** :
  * Conversion en Word (`3_CONVERTIR_EN_WORD.bat`) et templating PowerPoint (`generate_pptx_with_template.py`).

---

## 🔧 Prérequis Techniques & Compatibilité

* **Système d'exploitation** : Windows 10 / 11 (PowerShell 5.1 ou PowerShell 7+).
* **Gestionnaire d'environnement** : L'outil Rust [`uv`](https://github.com/astral-sh/uv) (déjà présent sur la machine) assure le bootstrapping automatique de Python et des packages sans nécessiter de droits administrateur.
* **Moteur Multimédia** : `ffmpeg` est embarqué automatiquement via le module `imageio-ffmpeg` (aucun téléchargement manuel requis).
* **Accélération Matérielle** : Whisper bascule automatiquement sur GPU NVIDIA (CUDA) si présent, ou sur CPU en quantification `int8` optimisée.
