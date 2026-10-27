# Boîte à outils : De Brief à Présentation (ECC & Scripts)

Ce dossier regroupe le skill ECC et les scripts utilisés pour transformer un brief en présentation interactive et livrable client autonome (PDF / HTML).

---

## 1. Skill ECC : `frontend-slides`

Dossier : [`frontend-slides/`](./frontend-slides/)

- [SKILL.md](./frontend-slides/SKILL.md) : Définition, règles d'exécution, architecture des slides sans dépendance (zero-dependency vanilla HTML/CSS/JS).
- [STYLE_PRESETS.md](./frontend-slides/STYLE_PRESETS.md) : Catalogue de thèmes visuels (Bold Signal, Dark Botanical, Swiss Modern, etc.) et contraintes de densité viewport (`clamp()`, 100dvh).
- [viewport-base.css](./frontend-slides/viewport-base.css) : Base CSS garantissant l'ajustement plein écran sans scrolling interne.
- [html-template.md](./frontend-slides/html-template.md) : Structure squelette d'une présentation complète.
- [animation-patterns.md](./frontend-slides/animation-patterns.md) : Patterns d'animations CSS et IntersectionObserver.
- `scripts/` :
  - `export-pdf.sh` : Script bash d'export PDF via Chrome/Chromium headless.
  - `extract-pptx.py` : Script d'extraction de contenu depuis des fichiers PowerPoint (.pptx).

---

## 2. Scripts d'automatisation & d'export développés

Dossier : [`scripts-export/`](./scripts-export/)

- **`export_deck.ps1` (PowerShell)** :
  - Injecte les règles `@media print` 16:9 (`16in x 9in`) pour les sauts de page stricts par slide.
  - Embarque les images externes en **Base64 data URI** pour produire un fichier HTML 100% autonome.
  - Active le mode verrouillé / flouté pour sécuriser le contenu avant soutenance client.
  - Pilote Microsoft Edge / Chrome en mode `--headless --print-to-pdf` pour générer un PDF haute résolution 16:9 sans aucune dépendance lourde.

- **`export_deck.py` (Python)** :
  - Version Python équivalente avec manipulation DOM et conversion headless.
