# Video to PowerPoint & More : Le Pipeline Automatisé IA

> **Cas d'école complet** : transformer n'importe quelle vidéo longue (réunion, webinaire, formation de 5 min à 2h) en un pack professionnel complet de livrables opérationnels en un seul double-clic : **Transcription intégrale**, **Synthèse exécutive**, **Article & Mode d'emploi Word (.docx)**, **Support PowerPoint 16:9 (.pptx)** et **Deck Web interactif & PDF**.

---

## 🎯 Où se trouve la solution ?

| Emplacement | Usage |
| :--- | :--- |
| 🚀 [**`demo/`**](./demo/) | **LA SOLUTION OPÉRATIONNELLE.** Contient le lanceur double-clic Windows, l'orchestrateur, le moteur Python humanisé et le dossier des livrables générés. **C'est ce dossier qu'il faut utiliser.** |
| 📚 [**`scripts_historiques/`**](./scripts_historiques/) | **Archives & recherche.** Conserve les briques exploratoires d'origine et le skill ECC `frontend-slides`. Ne pas exécuter directement. |

---

## 🎓 Cas d'École : Démonstration Réelle

Pour illustrer concrètement la valeur ajoutée du pipeline, nous avons traité une vidéo réelle :

* **Sujet** : Conférence & retour d'expérience sur les stratégies de créativité (*Too Fast to Think* de Chris Lewis).
* **Durée** : 7 minutes et 15 secondes.
* **Lien de la vidéo source (Google Drive)** : 
  👉 [**Télécharger / Visionner la vidéo sur Google Drive**](https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing)
* **Temps de traitement total** : **1 minute et 11 secondes** sur un ordinateur standard.

### 📦 Où se trouvent les livrables générés ?
Les résultats sont directement consultables et téléchargeables dans le dossier [**`demo/output/`**](./demo/output/) :

| Livrable | Accès direct au fichier | Format | Contenu & Valeur Ajoutée |
| :--- | :--- | :--- | :--- |
| 📘 **Article & Mode d'Emploi** | [**`article_mode_d_emploi.docx`**](./demo/output/article_mode_d_emploi.docx) | Word `.docx` | Guide opérationnel structuré pour les équipes : démarches pas-à-pas, encadrés de bonnes pratiques et captures insérées. |
| 📊 **Support de Présentation** | [**`presentation.pptx`**](./demo/output/presentation.pptx) | PowerPoint `.pptx` | Diapositives 16:9 widescreen élégantes avec puces argumentées et visuels extraits. |
| 📑 **Export Imprimable** | [**`presentation.pdf`**](./demo/output/presentation.pdf) | PDF 16:9 | Version vectorielle haute définition prête à projeter ou imprimer sans saut de page. |
| 🌐 **Deck Web Interactif** | [**`presentation.html`**](./demo/output/presentation.html) | HTML Autonome | Rendu plein écran ECC `frontend-slides` avec images Base64 (zéro serveur, zéro dépendance). |
| 📌 **Synthèse Exécutive** | [**`summary.md`**](./demo/output/summary.md) | Markdown | Synthèse de direction en style direct et humain (sans clichés IA). |
| 📝 **Transcription Intégrale** | [**`transcript.md`**](./demo/output/transcript.md) | Markdown | Retranscription mot à mot horodatée `[HH:MM:SS]` via Whisper local souverain. |
| 🖼 **Galerie des Diapositives** | [**`keyframes/`**](./demo/output/keyframes/) | Dossier JPG | 18 captures clés nettes extraites aux points de stabilité de la vidéo. |

---

## 👤 Guide Utilisateur : Accessible à Tous (Zéro Compétence Technique)

> **Point clé** : **Vous n'avez PAS besoin d'avoir Python installé sur votre machine.**  
> Le script est 100% autonome. Il gère lui-même son environnement virtuel dans un coin isolé sans jamais modifier votre système.

### Étape 1 : Télécharger ou Cloner le dépôt
Récupérez ce dépôt sur votre machine Windows.

### Étape 2 : Double-cliquer sur `LANCER_PIPELINE.bat`
Rendez-vous dans le dossier `demo/` et double-cliquez simplement sur :
👉 [**`demo\LANCER_PIPELINE.bat`**](./demo/LANCER_PIPELINE.bat)

### Étape 3 : Indiquer votre vidéo
Le script vous accueille et vous demande :
> *« Où se trouve la vidéo ? »*

Trois options ultra-simples s'offrent à vous :
1. **Glisser-déposer** votre fichier vidéo directement dans la fenêtre noire de la console.
2. **Coller le chemin** de votre fichier (ex : `D:\MesVideos\formation.mp4`).
3. **Appuyer sur [Entrée] sans rien taper** : la fenêtre standard de l'Explorateur Windows s'ouvre pour vous permettre de cliquer sur votre fichier vidéo !

### Étape 4 : Consultation immédiate
Dès la fin du traitement, **le dossier des livrables s'ouvre automatiquement sous vos yeux dans l'Explorateur Windows**.

---

## 🧠 Rédaction Humanisée (Anti-Clichés IA)

Le moteur intègre les directives éditoriales du framework **Humanizer** :
* **Zéro formulation robotique** : Aucun cliché du type *"dans un monde hyper-connecté"*, *"véritable catalyseur"*, *"pierre angulaire"*.
* **Typographie naturelle** : Fin des labels en gras mécaniques suivis de deux-points sur chaque puce.
* **Style direct de praticien** : Des phrases fluides, concrètes, citant les personnes et situations réelles de la vidéo.

---

## 🛠 Spécifications & Architecture

Pour les développeurs et chefs de projet souhaitant inspecter la conception technique :
* 📄 [**Cahier des charges produit (PRD BMad)**](./demo/prd.md)
* 📐 [**Addendum d'architecture & dimensionnement**](./demo/addendum.md)
* 💻 [**Script Python principal (`pipeline.py`)**](./demo/pipeline.py)
