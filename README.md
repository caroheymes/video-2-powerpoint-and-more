# Video to PowerPoint & More (Pipeline Automatisé IA)

> **Solution clé en main** pour transformer une vidéo longue (jusqu'à 2h) en un pack complet de livrables professionnels : **Transcription horodatée**, **Synthèse exécutive**, **Article & Mode d'emploi Word (.docx)**, **Présentation PowerPoint 16:9 (.pptx)** et **Deck Web interactif & PDF 16:9**.

---

## 🎯 Où se trouve la solution ?

Ce dépôt GitHub est structuré en deux parties distinctes :

| Dossier | Description & Rôle |
| :--- | :--- |
| 🚀 [**`demo/`**](./demo/) | **LA SOLUTION COMPLÈTE & OPÉRATIONNELLE.** C'est dans ce dossier que se trouve l'ensemble du pipeline automatisé, prêt à l'emploi (script double-clic `.bat`, orchestrateur PowerShell, moteur Python, cahier des charges PRD). |
| 📚 [**`scripts_historiques/`**](./scripts_historiques/) | **Archives & briques techniques de référence.** Ce dossier contient les scripts historiques et compétences ECC (notamment le skill `frontend-slides` et les scripts d'export) qui ont servi de socle de travail lors des premières expérimentations. **Ce n'est pas ce dossier qu'il faut exécuter.** |

---

## 🚀 Démarrage Rapide (Dossier `demo/`)

Toutes les opérations se déroulent exclusivement dans le dossier [**`demo/`**](./demo/) :

### 1. Cloner et déposer la vidéo
Placez votre fichier vidéo au format `.mp4` directement dans le dossier `demo/`.

### 2. Lancer le traitement (zéro installation requise)
Sous Windows, double-cliquez simplement sur :
```text
demo\LANCER_PIPELINE.bat
```
*Le script configure automatiquement un environnement Python virtuel isolé (`.venv`) via `uv`, installe les dépendances nécessaires et lance le traitement sans exiger de droits administrateur.*

### 3. Clé d'api IA
Au premier lancement, le script vous invite à renseigner une clé d'API pour la synthèse (compatible **Google Gemini**, **Mistral AI** ou **OpenAI**). La clé peut être mémorisée localement dans un fichier `.env` pour les exécutions futures.

---

## 📦 Les Livrables Générés dans `demo/output/`

À partir du fichier vidéo, le pipeline génère automatiquement dans `demo/` :

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
├── LANCER_PIPELINE.bat        # Lanceur double-clic Windows (zéro commande)
├── INSTALLER.bat              # Script d'installation & vérification
├── pipeline.py                # Moteur Python de traitement média & IA
├── run_pipeline.ps1           # Orchestrateur PowerShell avec auto-bootstrap
├── requirements.txt           # Dépendances Python isolées
├── prd.md                     # Cahier des charges produit (PRD BMad)
├── addendum.md                # Addendum technique d'architecture
└── README.md                  # Documentation détaillée du module
```

1. 📝 **`transcript.md`** : Transcription intégrale horodatée `[HH:MM:SS]` via **Whisper local** (CTranslate2, aucune fuite de données).
2. 📌 **`summary.md`** : Synthèse exécutive structurée en français (Contexte, Enjeux, Décisions, Plan d'action).
3. 📘 **`article_mode_d_emploi.docx`** : Document Word complet comprenant un guide pratique pas-à-pas, des encadrés de bonnes pratiques et les captures de scènes illustrées.
4. 📊 **`presentation.pptx`** : Support de présentation PowerPoint natif au format 16:9 widescreen avec visuels et points clés.
5. 🌐 **`presentation.html`** : Deck web interactif conforme aux standards ECC `frontend-slides` (autonome, images en Base64).
6. 📑 **`presentation.pdf`** : Version PDF 16:9 haute définition imprimée via Chromium headless.

---

## 📖 Documentation détaillée

Pour consulter les spécifications complètes et le cahier des charges produit :
* 📄 [**Cahier des charges produit (PRD)**](./demo/prd.md)
* 🛠 [**Addendum technique d'architecture**](./demo/addendum.md)
* 💡 [**Guide d'utilisation détaillé de `demo/`**](./demo/README.md)
