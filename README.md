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

- **[`demo/`](./demo/)** : Contient le pipeline fonctionnel complet. C'est le dossier à utiliser.
- **[`scripts_historiques/`](./scripts_historiques/)** : Conserve les scripts de test et les composants d'exploration initiaux (notamment le module `frontend-slides`).

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

## Utilisation

Le script a été conçu pour tourner sur n'importe quel ordinateur Windows, même si Python n'est pas installé sur la machine. Les dépendances sont isolées localement sans modifier la configuration système.

1. Téléchargez ou clonez ce dépôt.
2. Ouvrez le dossier `demo/`.
3. Double-cliquez sur `LANCER_PIPELINE.bat`.
4. À la question *« Où se trouve la vidéo ? »* :
   - Glissez votre fichier `.mp4` dans la fenêtre,
   - Ou tapez son chemin,
   - Ou appuyez simplement sur Entrée pour choisir le fichier via l'explorateur Windows habituel.
5. Au premier lancement, collez votre clé d'API (OpenAI, Gemini ou Mistral). Vous pouvez l'enregistrer dans un fichier local `.env` pour ne plus avoir à la renseigner par la suite.
6. Une fois le traitement terminé, l'explorateur de fichiers s'ouvre directement sur le dossier `output/`.

---

## Notes techniques

Pour adapter ou inspecter le fonctionnement interne du pipeline :

- [`demo/pipeline.py`](./demo/pipeline.py) : Script Python articulant l'extraction audio via ffmpeg, la transcription locale avec `faster-whisper`, la détection des changements de plan avec `scenedetect`, l'appel au modèle de langage pour la structuration, puis l'assemblage des fichiers Word, PowerPoint, HTML et PDF.
- [`demo/run_pipeline.ps1`](./demo/run_pipeline.ps1) : Script PowerShell appelé par le fichier `.bat`. Il installe l'exécutable `uv` si nécessaire, crée l'environnement virtuel `.venv` et lance le traitement.
- [`demo/prd.md`](./demo/prd.md) : Cahier des charges initial et critères d'acceptation du projet.
