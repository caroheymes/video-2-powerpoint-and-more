# Video to PowerPoint & More

Ce projet convertit une vidéo enregistrée (réunion, conférence, cours) en plusieurs documents de travail prêts à l'emploi :

- Une transcription texte complète et horodatée via Whisper en local.
- Une synthèse des échanges et décisions.
- Une note de synthèse au format Word (`.docx`) avec les captures d'écran des diapositives.
- Un diaporama PowerPoint 16:9 (`.pptx`).
- Une version web plein écran (`.html`) et son export imprimable (`.pdf`).

---

## Organisation du dépôt

Le dépôt est séparé en deux dossiers :

- **`INSTALLER_WINDOWS.bat`** : Assistant d'installation graphique en un clic pour Windows.
- **[`demo/`](./demo/)** : Contient le pipeline fonctionnel complet.
- **[`scripts_historiques/`](./scripts_historiques/)** : Conserve les scripts de test et les composants d'exploration initiaux.

---

## Exemple concret (vidéo de test)

Le pipeline a été validé sur un enregistrement de 7 minutes (intervention de Zoe Hames autour de l'ouvrage *Too Fast to Think* de Chris Lewis).

- Fichier source : [Lien de téléchargement Google Drive](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)
- Temps d'exécution mesuré : 1 min 11 s sur un PC standard.

Les documents générés lors de ce test sont consultables directement dans le dossier [`demo/output/`](./demo/output/) :

| Document | Fichier | Description |
| :--- | :--- | :--- |
| Note de synthèse | [`article_mode_d_emploi.docx`](./demo/output/article_mode_d_emploi.docx) | Document Word reprenant le déroulé, les points d'étape et les visuels de la vidéo. |
| Présentation PowerPoint | [`presentation.pptx`](./demo/output/presentation.pptx) | Diapositives 16:9 avec les idées forces et les captures d'écran associées. |
| Présentation PDF | [`presentation.pdf`](./demo/output/presentation.pdf) | Rendu PDF paysage sans coupure de diapositive. |
| Version web interactive | [`presentation.html`](./demo/output/presentation.html) | Fichier HTML autonome (les images sont encodées en base64, aucune connexion requise). |
| Synthèse rapide | [`summary.md`](./demo/output/summary.md) | Résumé textuel des messages clés et des conclusions. |
| Transcription brute | [`transcript.md`](./demo/output/transcript.md) | Retranscription intégrale horodatée seconde par seconde. |
| Visuels extraits | [`keyframes/`](./demo/output/keyframes/) | 18 captures des moments stables de la vidéo. |

---

## Guide d'utilisation (pour utilisateurs non techniques)

Aucune compétence informatique ni installation préalable de Python n'est requise.

### 1. Installation en un clic (à faire une seule fois)

1. Double-cliquez sur le fichier **`INSTALLER_WINDOWS.bat`**.
2. Une fenêtre Windows s'affiche :
   - Choisissez votre fournisseur d'IA (OpenAI, Gemini ou Mistral),
   - Collez votre clé d'accès dans le champ prévu,
   - Cliquez sur **« Installer & Configurer »**.
3. L'assistant prépare automatiquement l'environnement sans modifier votre système, ajoute un raccourci **« Video to PowerPoint »** sur votre Bureau, et active l'option dans le menu Clic Droit de Windows.

### 2. Traiter une vidéo au quotidien

Deux options au choix :

- **Par un simple clic droit (le plus rapide)** :  
  Faites un clic droit sur n'importe quel fichier vidéo (`.mp4`) sur votre ordinateur, puis cliquez sur **« Convertir avec Video2PowerPoint (IA) »**.

- **Depuis l'icône sur le Bureau** :  
  Double-cliquez sur le raccourci **« Video to PowerPoint »** sur votre Bureau, puis appuyez sur Entrée pour désigner votre fichier vidéo dans l'explorateur Windows habituel.

Le traitement se lance automatiquement. Dès qu'il est terminé, le dossier contenant vos documents finaux (Word, PowerPoint, PDF, synthèse) s'ouvre directement sous vos yeux.

---

## Notes techniques

Pour adapter ou inspecter le fonctionnement interne du pipeline :

- [`demo/pipeline.py`](./demo/pipeline.py) : Script Python articulant l'extraction audio via ffmpeg, la transcription locale avec `faster-whisper`, la détection des changements de plan avec `scenedetect`, l'appel au modèle de langage pour la structuration, puis l'assemblage des fichiers Word, PowerPoint, HTML et PDF.
- [`demo/run_pipeline.ps1`](./demo/run_pipeline.ps1) : Script PowerShell appelé par le fichier `.bat`. Il installe l'exécutable `uv` si nécessaire, crée l'environnement virtuel `.venv` et lance le traitement.
- [`demo/prd.md`](./demo/prd.md) : Cahier des charges initial et critères d'acceptation du projet.
