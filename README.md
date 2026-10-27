# Video to PowerPoint & More

Ce projet transforme n'importe quel enregistrement vidéo (réunion, formation, atelier, conférence) en documents de travail complets et prêts à l'emploi :

- La transcription intégrale horodatée, générée sur votre ordinateur avec Whisper.
- Une synthèse claire des messages clés et des décisions.
- Une note de cadrage Word (`.docx`) illustrée par les diapositives de la vidéo.
- Un diaporama PowerPoint 16:9 (`.pptx`) prêt à projeter.
- Une version web plein écran (`.html`) et son export imprimable (`.pdf`).

> **Note d'avancement :** Le pipeline automatisé, les scripts d'export, le module d'installation Windows et les intégrations système sont opérationnels. L'UI reste à mettre en place !

---

## Démarrage en 3 clics (sans compétences techniques)

Vous n'avez pas besoin d'installer Python, ni Git, ni aucun logiciel de développement.

1. **Téléchargez le projet** :  
   [Cliquez ici pour télécharger le dossier complet (.zip)](https://github.com/caroheymes/video-2-powerpoint-and-more/archive/refs/heads/master.zip) *(ou sur GitHub via le bouton vert `Code` puis `Download ZIP`)*.
2. **Dézippez le dossier** :  
   Faites un clic droit sur le fichier `.zip` téléchargé et choisissez **« Extraire tout »**, puis validez.
3. **Lancez l'installation** :  
   Dans le dossier extrait, double-cliquez sur le fichier **`INSTALLER_WINDOWS.bat`**.

Une petite fenêtre s'affiche :
- Choisissez votre moteur d'IA (OpenAI, Google Gemini ou Mistral),
- Collez votre clé d'accès dans le champ prévu,
- Cliquez sur le bouton **« Installer & Configurer »**.

L'assistant configure tout de manière autonome :
- Une icône **Video to PowerPoint** est déposée sur votre Bureau.
- Une commande **« Convertir avec Video2PowerPoint (IA) »** s'ajoute au menu clic droit de vos fichiers vidéo dans Windows.

---

## Convertir une vidéo au quotidien

Deux méthodes simples :

- **Au clic droit (le plus rapide)** :  
  Faites un clic droit sur n'importe quel fichier vidéo (`.mp4`) sur votre machine et choisissez **« Convertir avec Video2PowerPoint (IA) »**. La conversion démarre aussitôt.

- **Depuis l'icône sur le Bureau (ou `LANCER_PIPELINE.bat`)** :  
  Double-cliquez dessus. La console vous laisse le choix :
  - **Appuyez sur Entrée** : si vous n'avez pas encore de fichier sous la main, le programme télécharge automatiquement la vidéo de démonstration depuis Google Drive (atelier de 7 minutes) et lance le traitement. Si elle est déjà sur votre disque, il l'utilise directement.
  - **Tapez 2** : pour parcourir vos dossiers et désigner un fichier vidéo sur votre ordinateur (Bureau, Téléchargements, etc.).
  - **Tapez 3** : pour coller un lien Google Drive ou une adresse de vidéo en ligne.
  - Vous pouvez aussi faire glisser votre fichier vidéo directement dans la console.

### Où sont enregistrés vos documents ?
- **Pour une vidéo personnelle** (au clic droit ou via le sélecteur) : un dossier nommé **`<NomDeLaVidéo>_livrables`** est automatiquement créé **au même endroit que votre fichier vidéo** (sur votre Bureau, dans vos Téléchargements, etc.).
- **Pour la vidéo d'exemple intégrée** : les fichiers sont placés dans le sous-dossier [`demo/output/`](./demo/output/).
- **À la fin du traitement** : l'Explorateur Windows s'ouvre automatiquement sur le dossier final, accompagné d'une boîte de dialogue vous confirmant l'emplacement exact de tous vos livrables.

### Que faire face aux messages de la console ?
Rien de particulier. Certains avertissements de bibliothèque (comme les remarques de Hugging Face signalant que Windows gère le cache sans liens symboliques) sont de simples indications informatives internes. Ils ne bloquent pas le calcul et ne modifient en rien le résultat final.

---

## Exemple concret (vidéo de test)

Le pipeline a été validé sur un atelier de 7 minutes (intervention de Zoe Hames autour du livre *Too Fast to Think* de Chris Lewis).

- Fichier source : [Lien de téléchargement Google Drive](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)
- Temps de calcul constaté : 1 minute et 11 secondes sur un ordinateur de bureau standard.

Les documents issus de ce test sont consultables directement dans le dossier [`demo/output/`](./demo/output/) :

| Document | Fichier généré | Contenu |
| :--- | :--- | :--- |
| Note de synthèse | [`article_mode_d_emploi.docx`](./demo/output/article_mode_d_emploi.docx) | Document Word structuré en 5 sections opérationnelles avec constats, recommandations et visuels associés. |
| Présentation PowerPoint | [`presentation.pptx`](./demo/output/presentation.pptx) | Diaporama 16:9 complet de 10 diapositives denses, sobres et professionnelles (sans jargon ni clichés IA). |
| Version imprimable | [`presentation.pdf`](./demo/output/presentation.pdf) | Rendu PDF paysage page à page, sans coupure de diapositive. |
| Présentation interactive | [`presentation.html`](./demo/output/presentation.html) | Fichier web autonome navigable au clavier (les visuels sont intégrés, fonctionne hors-ligne). |
| Synthèse rapide | [`summary.md`](./demo/output/summary.md) | Synthèse textuelle incisive des messages essentiels et des conclusions. |
| Transcription brute | [`transcript.md`](./demo/output/transcript.md) | Retranscription intégrale horodatée seconde par seconde avec Whisper. |
| Visuels extraits | [`keyframes/`](./demo/output/keyframes/) | 18 captures des moments stables de la vidéo. |

---

## Organisation des dossiers

- **`INSTALLER_WINDOWS.bat`** : Assistant d'installation graphique pour Windows (à la racine).
- **`LANCER_PIPELINE.bat`** : Lanceur direct du traitement (à la racine).
- **`LANCER_TESTS.bat`** : Banc d'essai automatisé (21 tests unitaires et d'intégration).
- **[`demo/`](./demo/)** : Pipeline complet avec code Python, environnement virtuel, tests et dossier de sortie.
- **[`scripts_historiques/`](./scripts_historiques/)** : Scripts d'exploration et de validation initiaux.

---

## Banc de tests & Validation (Harness)

Une suite de 21 tests automatisés avec `pytest` garantit la fiabilité de chaque composant du pipeline :
- **Intégrité de l'environnement** : présence effective de `ffmpeg` autonome et des bibliothèques (`faster-whisper`, `scenedetect`, `python-docx`, `python-pptx`, `Pillow`).
- **Générateurs de documents** : conformité des fichiers Word (`.docx`), du format 16:9 widescreen PowerPoint (`.pptx`), du deck web HTML autonome (`.html`) et de l'export PDF.
- **Banc d'essai de bout en bout (Harness E2E)** : simulation complète du cycle de vie du pipeline avec vérification de la production des 7 livrables.
- **Règles rédactionnelles Humanizer** : contrôle de l'application stricte des directives anti-jargon IA et du filtrage programmatique des clichés.

Pour lancer tous les tests en un clic :  
Double-cliquez sur **`LANCER_TESTS.bat`** (à la racine ou dans `demo/`).

---

Pour adapter ou inspecter le fonctionnement technique :
- [`demo/pipeline.py`](./demo/pipeline.py) regroupe l'extraction audio ffmpeg, le téléchargement automatique Google Drive, la transcription locale Whisper, la détection visuelle de plans, l'analyse LLM et les moteurs d'export Word, PowerPoint, HTML et PDF.
- [`demo/run_pipeline.ps1`](./demo/run_pipeline.ps1) gère l'installation autonome de l'environnement virtuel (`uv`) et la sélection interactive des fichiers.
