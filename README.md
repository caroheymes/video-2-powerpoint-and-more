# Video to PowerPoint & More

Ce projet convertit un enregistrement vidéo (réunion d'équipe, atelier, conférence, cours) en un ensemble complet de documents directement exploitables :

- La transcription intégrale horodatée, réalisée sur votre machine avec Whisper.
- Une synthèse claire des échanges et des décisions.
- Une note de cadrage au format Word (`.docx`) enrichie des captures d'écran des diapositives.
- Un diaporama PowerPoint 16:9 (`.pptx`) prêt à projeter.
- Une version web plein écran (`.html`) avec son export imprimable (`.pdf`).

---

## Prise en main rapide

Vous n'avez pas besoin d'installer Python ni de taper de ligne de commande.

### 1. Première installation

1. Double-cliquez sur `INSTALLER_WINDOWS.bat`.
2. Une fenêtre s'affiche pour vous permettre de :
   - Choisir votre moteur d'IA (OpenAI, Google Gemini ou Mistral),
   - Renseigner votre clé d'accès,
   - Cliquer sur **Installer & Configurer**.
3. L'assistant prépare tout en autonomie, dépose un raccourci **Video to PowerPoint** sur votre Bureau et ajoute l'option dans le menu clic droit de Windows.

### 2. Traitement d'une vidéo

Deux façons simples de lancer une conversion :

- **Le clic droit dans vos dossiers** : faites un clic droit sur n'importe quel fichier `.mp4` et choisissez **Convertir avec Video2PowerPoint (IA)**. Le traitement commence aussitôt sur cette vidéo.
- **Le raccourci sur le Bureau** : double-cliquez sur l'icône **Video to PowerPoint**. La fenêtre vous propose alors un choix direct :
  - Appuyez sur **Entrée** pour tester la vidéo d'exemple déjà incluse.
  - Tapez **2** pour ouvrir l'explorateur Windows et sélectionner un autre fichier vidéo.
  - Vous pouvez aussi faire glisser votre fichier vidéo directement dans la fenêtre.

Dès que le calcul s'achève, le dossier contenant tous vos documents finaux s'ouvre automatiquement.

### Que faire si des messages d'avertissement s'affichent ?

Rien du tout. Certains avertissements de bibliothèque (par exemple les messages de Hugging Face signalant que Windows ne gère pas nativement les liens symboliques en mode standard) sont de simples indications techniques internes. Ils n'interrompent pas le calcul et ne dégradent en rien vos documents.

---

## Exemple concret (vidéo de test)

Le fonctionnement a été validé sur un atelier de 7 minutes (intervention de Zoe Hames sur l'ouvrage *Too Fast to Think* de Chris Lewis).

- Fichier source : [Télécharger la vidéo sur Google Drive](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)
- Temps de traitement mesuré : 1 minute et 11 secondes sur un ordinateur de bureau standard.

Les documents générés lors de ce test sont consultables directement dans le dossier [`demo/output/`](./demo/output/) :

| Document | Fichier généré | Contenu |
| :--- | :--- | :--- |
| Note de synthèse | [`article_mode_d_emploi.docx`](./demo/output/article_mode_d_emploi.docx) | Document Word structuré avec les idées directrices et les captures associées. |
| Présentation PowerPoint | [`presentation.pptx`](./demo/output/presentation.pptx) | Diapositives 16:9 avec les messages clés et les visuels de la vidéo. |
| Version imprimable | [`presentation.pdf`](./demo/output/presentation.pdf) | Rendu PDF paysage page à page, sans coupure. |
| Présentation interactive | [`presentation.html`](./demo/output/presentation.html) | Fichier web autonome (les visuels sont intégrés, fonctionne hors-ligne). |
| Synthèse rapide | [`summary.md`](./demo/output/summary.md) | Synthèse concise des points clés et des conclusions. |
| Transcription brute | [`transcript.md`](./demo/output/transcript.md) | Texte intégral horodaté seconde par seconde. |
| Visuels extraits | [`keyframes/`](./demo/output/keyframes/) | 18 captures des moments stables de la vidéo. |

---

## Structure du projet

- **`INSTALLER_WINDOWS.bat`** : Assistant d'installation graphique pour Windows.
- **[`demo/`](./demo/)** : Pipeline prêt à l'emploi avec scripts d'exécution et dossier de sortie.
- **[`scripts_historiques/`](./scripts_historiques/)** : Scripts d'exploration et de validation initiaux.

Pour adapter ou auditer le code interne :
- [`demo/pipeline.py`](./demo/pipeline.py) regroupe l'extraction audio ffmpeg, la transcription locale Whisper, la détection visuelle de plans, les requêtes d'analyse LLM et les moteurs d'export Word, PowerPoint, HTML et PDF.
- [`demo/run_pipeline.ps1`](./demo/run_pipeline.ps1) gère la sélection interactive du fichier et l'environnement virtuel.
