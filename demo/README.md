# Module Demo : Pipeline Automatisé de Restitution Vidéo

Ce dossier contient la **solution complète et opérationnelle** permettant de convertir n'importe quelle vidéo longue en 6 livrables stratégiques professionnels.

---

## 🎬 Vidéo de Démonstration (Cas d'École)

Une vidéo test de 7 minutes (*Unlock Your Creativity with These 3 Strategies*) a été utilisée pour valider le pipeline :
* 👉 [**Télécharger / Visionner la vidéo sur Google Drive**](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)

---

## 🚀 Utilisation en 1 Clic (Zéro Python Requis)

> **Important** : Aucune compétence technique n'est requise. Vous n'avez **pas besoin d'avoir Python installé** sur votre ordinateur. Le fichier `.bat` gère automatiquement l'ensemble de la configuration sans impacter votre système.

### 1. Lancez le script
Double-cliquez simplement sur :
👉 [**`LANCER_PIPELINE.bat`**](./LANCER_PIPELINE.bat)

### 2. Répondez à la question : *« Où se trouve la vidéo ? »*
Si aucun fichier vidéo n'est déposé dans ce dossier, le script vous propose :
* **Option A** : Glisser-déposer votre vidéo `.mp4` directement dans la fenêtre.
* **Option B** : Copier-coller le chemin de votre vidéo.
* **Option C (Le plus simple)** : **Appuyez sur [Entrée]** pour ouvrir la fenêtre de sélection standard de l'Explorateur Windows et choisir votre fichier en un clic !

### 3. Récupérez vos livrables
À la fin du traitement (environ 1 minute pour une vidéo courte, ~20 min pour 2 heures), **le dossier `output/` s'ouvre automatiquement sous vos yeux**.

---

## 📦 Où se trouvent les Livrables Générés ?

Tous les livrables sont générés et stockés dans le sous-dossier [**`output/`**](./output/) :

| Livrable | Fichier | Description |
| :--- | :--- | :--- |
| 📘 **Article & Mode d'Emploi** | [**`output/article_mode_d_emploi.docx`**](./output/article_mode_d_emploi.docx) | Document Word complet rédigé avec démarche opérationnelle, encadrés et illustrations. |
| 📊 **Support de Présentation** | [**`output/presentation.pptx`**](./output/presentation.pptx) | Diapositives PowerPoint 16:9 widescreen prêtes pour la soutenance. |
| 📑 **Présentation Imprimable** | [**`output/presentation.pdf`**](./output/presentation.pdf) | Rendu PDF vectoriel 16:9 haute définition via Chromium headless. |
| 🌐 **Deck Web Interactif** | [**`output/presentation.html`**](./output/presentation.html) | Présentation plein écran autonome (normes ECC `frontend-slides`). |
| 📌 **Synthèse Exécutive** | [**`output/summary.md`**](./output/summary.md) | Synthèse de direction en style direct et humain (anti-clichés IA). |
| 📝 **Transcription Intégrale** | [**`output/transcript.md`**](./output/transcript.md) | Retranscription mot à mot horodatée `[HH:MM:SS]` (Whisper local souverain). |
| 🖼 **Galerie des Diapositives** | [**`output/keyframes/`**](./output/keyframes/) | 18 captures clés extraites de la vidéo. |

---

## ⚙️ Options Ligne de Commande (Pour Développeurs)

Pour les utilisateurs souhaitant automatiser via PowerShell :
```powershell
# Traiter une vidéo avec reprise automatique
.\run_pipeline.ps1 -VideoPath "C:\Chemin\MaVideo.mp4" -ModelSize "medium"

# Reprendre sans recalculer la transcription
.\run_pipeline.ps1 -SkipTranscription
```
