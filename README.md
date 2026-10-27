# Video to PowerPoint & More

Ce projet convertit une vidéo enregistrée (réunion, conférence, cours, atelier) en plusieurs documents de travail directement exploitables :

- Une transcription texte intégrale et horodatée via Whisper en local.
- Une synthèse claire des échanges et des conclusions.
- Une note de synthèse au format Word (`.docx`) avec les captures d'écran des diapositives.
- Un diaporama PowerPoint 16:9 (`.pptx`) prêt à être projeté ou partagé.
- Une version web plein écran (`.html`) et son export imprimable (`.pdf`).

---

## Organisation du dépôt

- **`INSTALLER_WINDOWS.bat`** : Assistant d'installation graphique en un clic pour Windows.
- **[`demo/`](./demo/)** : Le pipeline fonctionnel complet et prêt à l'emploi.
- **[`scripts_historiques/`](./scripts_historiques/)** : Scripts de test et composants d'exploration initiaux.

---

## Que doit faire un utilisateur non technique ?

Aucune connaissance informatique ni installation préalable de Python n'est requise.

### Étape 1 : Première installation (à faire une seule fois)

1. Double-cliquez sur le fichier **`INSTALLER_WINDOWS.bat`**.
2. Une petite fenêtre s'ouvre :
   - Choisissez votre fournisseur d'IA (OpenAI, Google Gemini ou Mistral),
   - Collez votre clé d'accès dans le champ prévu,
   - Cliquez sur le bouton **« Installer & Configurer »**.
3. L'assistant prépare tout en quelques secondes sans modifier votre système, ajoute une icône **« Video to PowerPoint »** sur votre Bureau et intègre une commande dans le menu clic droit de Windows.

### Étape 2 : Traiter une vidéo au quotidien

Deux méthodes au choix :

- **Méthode 1 (la plus rapide)** : Faites un clic droit sur n'importe quel fichier vidéo (`.mp4`) sur votre ordinateur, puis choisissez **« Convertir avec Video2PowerPoint (IA) »**.
- **Méthode 2** : Double-cliquez sur l'icône **« Video to PowerPoint »** sur votre Bureau, puis appuyez sur la touche Entrée pour choisir votre vidéo dans l'explorateur Windows habituel.

Le traitement démarre dans une fenêtre console. Une fois le travail terminé, le dossier contenant vos documents finaux s'ouvre automatiquement sous vos yeux.

### Que faire si un message en jaune ou un avertissement apparaît ?

- **Absolument rien.** Certains messages informatifs (comme les avertissements de Hugging Face concernant les « symlinks » sur Windows ou l'absence de jeton de cache) sont de simples indications techniques internes.
- Ce ne sont **pas des erreurs** : ils n'empêchent en rien le programme de fonctionner normalement et de produire tous vos documents.
- Le lanceur configure désormais automatiquement les réglages nécessaires pour masquer ces messages parasites.

---

## Exemple concret (vidéo de test)

Le pipeline a été testé et validé sur un enregistrement de 7 minutes (intervention de Zoe Hames autour du livre *Too Fast to Think* de Chris Lewis).

- Fichier vidéo source : [Lien de téléchargement Google Drive](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)
- Temps de calcul constaté : 1 min 11 s sur un ordinateur de bureau standard.

Tous les fichiers issus de ce test sont directement consultables dans le dossier [`demo/output/`](./demo/output/) :

| Document | Fichier | Description |
| :--- | :--- | :--- |
| Note de synthèse | [`article_mode_d_emploi.docx`](./demo/output/article_mode_d_emploi.docx) | Document Word reprenant le fil conducteur, les points clés et les visuels de la vidéo. |
| Présentation PowerPoint | [`presentation.pptx`](./demo/output/presentation.pptx) | Diaporama 16:9 avec les idées maîtresses et les captures d'écran associées. |
| Présentation PDF | [`presentation.pdf`](./demo/output/presentation.pdf) | Rendu PDF paysage page par page, sans coupure. |
| Version web interactive | [`presentation.html`](./demo/output/presentation.html) | Fichier HTML autonome (les images sont embarquées, consultation hors-ligne). |
| Synthèse rapide | [`summary.md`](./demo/output/summary.md) | Synthèse textuelle des messages essentiels et des conclusions. |
| Transcription brute | [`transcript.md`](./demo/output/transcript.md) | Retranscription intégrale horodatée seconde par seconde. |
| Visuels extraits | [`keyframes/`](./demo/output/keyframes/) | 18 captures des moments stables de la vidéo. |

---

## Notes pour les profils techniques

Pour adapter ou inspecter le fonctionnement interne du pipeline :

- [`demo/pipeline.py`](./demo/pipeline.py) : Script Python articulant l'extraction audio via ffmpeg, la transcription locale avec `faster-whisper`, la détection des changements de plan avec `scenedetect`, l'appel au modèle de langage pour la structuration, puis l'assemblage des fichiers Word, PowerPoint, HTML et PDF.
- [`demo/run_pipeline.ps1`](./demo/run_pipeline.ps1) : Script PowerShell appelé par le fichier `.bat`. Il installe l'exécutable `uv` si nécessaire, crée l'environnement virtuel `.venv` et lance le traitement.
- [`demo/prd.md`](./demo/prd.md) : Cahier des charges initial et critères d'acceptation du projet.
