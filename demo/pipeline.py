#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pipeline Automatisé de Traitement Vidéo
---------------------------------------
Transcription Whisper Locale, Découpage de Scènes, Synthèse LLM (Gemini/Mistral),
Génération de Decks Multi-Formats (PowerPoint 16:9 & Slides Web HTML/PDF).
"""

import os
import sys
import json
import base64
import argparse
import subprocess
from pathlib import Path
from typing import List, Dict, Any, Optional

# Configuration de la sortie console UTF-8 sur Windows
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

import requests
import imageio_ffmpeg


def format_timestamp(seconds: float) -> str:
    """Convertit des secondes en format [HH:MM:SS]."""
    hrs = int(seconds // 3600)
    mins = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    return f"{hrs:02d}:{mins:02d}:{secs:02d}"


# ==============================================================================
# Étape 1 : Extraction Audio
# ==============================================================================
def extract_audio(video_path: Path, output_audio_path: Path) -> Path:
    """Extrait la piste audio en WAV 16kHz mono optimisé pour Whisper."""
    print(f"\n[1/5]  Extraction audio depuis : {video_path.name}...")
    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()

    output_audio_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        ffmpeg_exe,
        "-y",
        "-i", str(video_path),
        "-vn",
        "-acodec", "pcm_s16le",
        "-ar", "16000",
        "-ac", "1",
        str(output_audio_path)
    ]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Erreur ffmpeg lors de l'extraction audio: {result.stderr}")
    
    print(f" Piste audio extraite : {output_audio_path} ({output_audio_path.stat().st_size / (1024*1024):.1f} Mo)")
    return output_audio_path


# ==============================================================================
# Étape 2 : Transcription Whisper Locale
# ==============================================================================
def transcribe_audio(audio_path: Path, output_transcript_path: Path, model_size: str = "medium") -> str:
    """Transcrit l'audio en local via faster-whisper (CTranslate2)."""
    print(f"\n[2/5] 🎙 Transcription locale Whisper (modèle: {model_size})...")
    from faster_whisper import WhisperModel

    # Détection GPU CUDA vs CPU int8 avec repli transparent sur CPU si librairies CUDA absentes
    model = None
    segments = None
    info = None

    try:
        import ctranslate2
        if "cuda" in ctranslate2.get_supported_compute_types("cuda"):
            print(" Tentative d'initialisation sur GPU CUDA...")
            model = WhisperModel(model_size, device="cuda", compute_type="float16")
            segments_gen, info = model.transcribe(str(audio_path), beam_size=5)
            # Vérification du premier segment pour déclencher le chargement des DLLs CUDA
            first_seg = next(segments_gen, None)
            if first_seg:
                import itertools
                segments = itertools.chain([first_seg], segments_gen)
            else:
                segments = []
            print(" Exécution sur GPU CUDA active.")
    except Exception as cuda_err:
        print(f" GPU CUDA non disponible ou DLLs manquantes ({cuda_err}). Bascule sur CPU int8.")
        model = None

    if model is None:
        print(" Exécution sur CPU (calcul: int8 optimisé)...")
        model = WhisperModel(model_size, device="cpu", compute_type="int8")
        segments, info = model.transcribe(str(audio_path), beam_size=5)

    print(f" Langue détectée : {info.language} (confiance: {info.language_probability:.2f})")
    print(f" Durée audio : {format_timestamp(info.duration)}")

    lines = []
    lines.append(f"# Transcription Intégrale Horodatée\n")
    lines.append(f"- **Fichier source** : `{audio_path.name}`\n")
    lines.append(f"- **Durée totale** : `{format_timestamp(info.duration)}`\n\n---\n")

    full_text_parts = []
    for seg in segments:
        ts = f"[{format_timestamp(seg.start)} -> {format_timestamp(seg.end)}]"
        text = seg.text.strip()
        lines.append(f"**{ts}** {text}\n")
        full_text_parts.append(f"{ts} {text}")

    full_markdown = "\n".join(lines)
    output_transcript_path.write_text(full_markdown, encoding="utf-8")
    print(f" Transcription sauvegardée dans : {output_transcript_path}")
    return "\n".join(full_text_parts)


# ==============================================================================
# Étape 3 : Découpage Intelligent des Scènes
# ==============================================================================
def extract_scenes(video_path: Path, output_keyframes_dir: Path, max_scenes: int = 18) -> List[Dict[str, Any]]:
    """Détecte les changements de contenu et extrait les diapositives/keyframes stables."""
    print(f"\n[3/5] 📸 Détection intelligente des scènes vidéo...")
    output_keyframes_dir.mkdir(parents=True, exist_ok=True)

    from scenedetect import detect, ContentDetector, split_video_ffmpeg
    import cv2

    scenes = detect(str(video_path), ContentDetector(threshold=27.0, min_scene_len=25))
    print(f" Nombre de transitions de scènes détectées : {len(scenes)}")

    # Si trop de scènes ou trop peu, filtrer pour garder les plus significatives
    cap = cv2.VideoCapture(str(video_path))
    fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration_secs = total_frames / fps

    keyframes = []
    
    if not scenes:
        # Fallback si vidéo uniforme (ex: présentation statique) : découpage régulier
        step_secs = max(30.0, duration_secs / max_scenes)
        times = [i * step_secs for i in range(1, int(duration_secs // step_secs))]
        for idx, t in enumerate(times[:max_scenes]):
            scenes.append((type('obj', (object,), {'get_seconds': lambda t=t: t})(),
                           type('obj', (object,), {'get_seconds': lambda t=t: t + 10})()))

    # Sélection espacée de scènes représentatives
    stride = max(1, len(scenes) // max_scenes)
    selected_scenes = scenes[::stride][:max_scenes]

    for idx, scene in enumerate(selected_scenes):
        s0_sec = getattr(scene[0], 'seconds', None)
        if s0_sec is None:
            s0_sec = scene[0].get_seconds()
        s1_sec = getattr(scene[1], 'seconds', None)
        if s1_sec is None:
            s1_sec = scene[1].get_seconds()
        start_sec = s0_sec
        mid_sec = start_sec + (s1_sec - start_sec) / 2.0
        frame_idx = int(mid_sec * fps)

        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_idx)
        ret, frame = cap.read()
        if ret and frame is not None:
            filename = f"slide_keyframe_{idx+1:02d}.jpg"
            img_path = output_keyframes_dir / filename
            # Redimensionner en 1920x1080 si nécessaire
            h, w = frame.shape[:2]
            if w > 1920 or h > 1080:
                frame = cv2.resize(frame, (1920, 1080), interpolation=cv2.INTER_AREA)
            cv2.imwrite(str(img_path), frame, [int(cv2.IMWRITE_JPEG_QUALITY), 90])
            keyframes.append({
                "index": idx + 1,
                "timestamp": format_timestamp(mid_sec),
                "seconds": mid_sec,
                "filename": filename,
                "path": str(img_path)
            })

    cap.release()
    print(f" {len(keyframes)} diapositives clés extraites dans : {output_keyframes_dir}")
    return keyframes


# ==============================================================================
# Étape 4 : Synthèse & Structuration par API LLM (Gemini / Mistral)
# ==============================================================================
def analyze_with_llm(transcript_text: str, keyframes: List[Dict[str, Any]], api_key: str, provider: str = "gemini") -> Dict[str, Any]:
    """Appelle l'API Gemini ou Mistral pour synthétiser la vidéo et architecturer le deck."""
    print(f"\n[4/5] 🧠 Synthèse exécutive & modélisation des slides via {provider.upper()}...")

    keyframes_summary = "\n".join([f"- Image {kf['index']} ({kf['filename']}) capturée à {kf['timestamp']}" for kf in keyframes])

    system_prompt = (
        "Tu es un directeur de cabinet de conseil de premier plan, expert en synthèse stratégique, "
        "en pédagogie opérationnelle et en conception de présentations pour directions générales (C-Level). "
        "À partir de la transcription complète d'une vidéo et des captures d'écrans extraites, "
        "tu dois produire en FRANÇAIS :\n"
        "1. Une synthèse exécutive structurée (au format Markdown).\n"
        "2. Un article de fond / mode d'emploi opérationnel complet rédigé pour les équipes (sections, étapes, conseils pratiques).\n"
        "3. Un plan de présentation de 12 à 16 diapositives avec bullet points percutants et visuels associés.\n\n"
        "RÉPONDS STRICTEMENT AU FORMAT JSON avec la structure exacte suivante :\n"
        "{\n"
        '  "summary_markdown": "# Synthèse Stratégique...",\n'
        '  "article_title": "Guide Pratique & Mode d\'Emploi : ...",\n'
        '  "article_sections": [\n'
        '    {\n'
        '      "heading": "1. Contexte & Enjeux Stratégiques",\n'
        '      "paragraphs": ["...", "..."],\n'
        '      "bullets": ["...", "..."],\n'
        '      "keyframe": "slide_keyframe_01.jpg",\n'
        '      "callout": "Point de vigilance : ..."\n'
        '    },\n'
        '    {\n'
        '      "heading": "2. Mode d\'Emploi & Démarche Pas-à-Pas",\n'
        '      "paragraphs": ["...", "..."],\n'
        '      "bullets": ["Étape 1 : ...", "Étape 2 : ..."],\n'
        '      "keyframe": "slide_keyframe_02.jpg",\n'
        '      "callout": "Bonne pratique : ..."\n'
        '    },\n'
        '    {\n'
        '      "heading": "3. Décisions Clés & Plan d\'Action",\n'
        '      "paragraphs": ["..."],\n'
        '      "bullets": ["Action 1 : ...", "Action 2 : ..."],\n'
        '      "keyframe": null,\n'
        '      "callout": null\n'
        '    }\n'
        '  ],\n'
        '  "presentation_title": "Titre Exécutif du Deck",\n'
        '  "presentation_subtitle": "Sous-titre / Date / Client",\n'
        '  "slides": [\n'
        "    {\n"
        '      "slide_number": 1,\n'
        '      "type": "title",\n'
        '      "title": "...",\n'
        '      "subtitle": "..."\n'
        "    },\n"
        "    {\n"
        '      "slide_number": 2,\n'
        '      "type": "content",\n'
        '      "title": "...",\n'
        '      "bullets": ["...", "...", "..."],\n'
        '      "keyframe": "slide_keyframe_01.jpg",\n'
        '      "kpi": {"value": "+35%", "label": "Gains d\'efficacité"}\n'
        "    }\n"
        "  ]\n"
        "}"
    )

    user_prompt = f"### LISTE DES IMAGES DISPONIBLES :\n{keyframes_summary}\n\n### TRANSCRIPTION INTÉGRALE :\n{transcript_text[:120000]}"

    if provider.lower() == "gemini":
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"
        payload = {
            "contents": [
                {"role": "user", "parts": [{"text": system_prompt + "\n\n" + user_prompt}]}
            ],
            "generationConfig": {
                "responseMimeType": "application/json",
                "temperature": 0.2
            }
        }
        res = requests.post(url, json=payload, headers={"Content-Type": "application/json"}, timeout=120)
        if res.status_code != 200:
            raise RuntimeError(f"Erreur API Gemini ({res.status_code}): {res.text}")
        data = res.json()
        raw_text = data["candidates"][0]["content"]["parts"][0]["text"]

    elif provider.lower() == "mistral":
        url = "https://api.mistral.ai/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": "mistral-large-latest",
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "response_format": {"type": "json_object"},
            "temperature": 0.2
        }
        res = requests.post(url, json=payload, headers=headers, timeout=120)
        if res.status_code != 200:
            raise RuntimeError(f"Erreur API Mistral ({res.status_code}): {res.text}")
        data = res.json()
        raw_text = data["choices"][0]["message"]["content"]

    elif provider.lower() == "openai":
        url = "https://api.openai.com/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": "gpt-4o-mini",
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "response_format": {"type": "json_object"},
            "temperature": 0.2
        }
        res = requests.post(url, json=payload, headers=headers, timeout=120)
        if res.status_code != 200:
            raise RuntimeError(f"Erreur API OpenAI ({res.status_code}): {res.text}")
        data = res.json()
        raw_text = data["choices"][0]["message"]["content"]
    else:
        raise ValueError(f"Fournisseur LLM inconnu : {provider}")

    # Nettoyage JSON si balises Markdown présentes
    clean_json = raw_text.strip()
    if clean_json.startswith("```json"):
        clean_json = clean_json[7:]
    if clean_json.endswith("```"):
        clean_json = clean_json[:-3]

    return json.loads(clean_json)


# ==============================================================================
# Étape 5A : Génération de l'Article & Mode d'Emploi Word (.docx)
# ==============================================================================
def generate_docx_guide(plan: Dict[str, Any], keyframes_dir: Path, output_docx_path: Path):
    """Génère un article de fond et mode d'emploi opérationnel au format Microsoft Word (.docx)."""
    print(f"\n[5/5a]  Génération de l'Article & Mode d'Emploi Word : {output_docx_path.name}...")
    from docx import Document
    from docx.shared import Inches, Pt, RGBColor
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    from docx.enum.table import WD_TABLE_ALIGNMENT
    from docx.oxml import parse_xml
    from docx.oxml.ns import nsdecls

    doc = Document()

    # Définition des marges (1 pouce = 2.54 cm)
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)

    # Couleurs corporate
    COLOR_PRIMARY = RGBColor(30, 58, 138)    # #1E3A8A Dark Navy
    COLOR_SECONDARY = RGBColor(2, 132, 199)  # #0284C7 Sky Blue
    COLOR_TEXT = RGBColor(51, 65, 85)        # #334155 Slate Text
    COLOR_MUTED = RGBColor(100, 116, 139)    # #64748B Gray Text

    # Titre du document
    article_title = plan.get("article_title") or f"Guide & Mode d'Emploi : {plan.get('presentation_title', 'Restitution Stratégique')}"
    title_p = doc.add_paragraph()
    title_run = title_p.add_run(article_title)
    title_run.font.size = Pt(24)
    title_run.font.bold = True
    title_run.font.color.rgb = COLOR_PRIMARY
    title_p.paragraph_format.space_after = Pt(6)

    # Sous-titre / Métadonnées
    meta_p = doc.add_paragraph()
    meta_run = meta_p.add_run(f"Document de Synthèse Opérationnelle & Pratique | {plan.get('presentation_subtitle', 'Restitution Exécutive')}")
    meta_run.font.size = Pt(11)
    meta_run.font.italic = True
    meta_run.font.color.rgb = COLOR_MUTED
    meta_p.paragraph_format.space_after = Pt(20)

    # Table de cartouche métadonnées
    meta_table = doc.add_table(rows=1, cols=3)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_table.autofit = True
    hdr_cells = meta_table.rows[0].cells
    hdr_cells[0].text = "Format : Guide Opérationnel"
    hdr_cells[1].text = "Usage : Équipes & Direction"
    hdr_cells[2].text = "Origine : Restitution Vidéo"
    for c in hdr_cells:
        shading = parse_xml(r'<w:shd {} w:fill="F1F5F9"/>'.format(nsdecls('w')))
        c._tc.get_or_add_tcPr().append(shading)
        for p in c.paragraphs:
            p.runs[0].font.size = Pt(9.5)
            p.runs[0].font.color.rgb = COLOR_MUTED

    doc.add_paragraph().paragraph_format.space_after = Pt(14)

    # Sections de l'article
    sections = plan.get("article_sections", [])
    if not sections:
        sections = [
            {
                "heading": "1. Contexte & Enjeux Stratégiques",
                "paragraphs": [plan.get("summary_markdown", "Synthèse de la session.")],
                "bullets": [],
                "keyframe": None,
                "callout": "Retrouvez l'intégralité des points abordés dans les livrables associés."
            }
        ]

    for sec in sections:
        heading_text = sec.get("heading", "")
        if heading_text:
            h = doc.add_heading(level=1)
            hrun = h.add_run(heading_text)
            hrun.font.size = Pt(16)
            hrun.font.bold = True
            hrun.font.color.rgb = COLOR_PRIMARY
            h.paragraph_format.space_before = Pt(16)
            h.paragraph_format.space_after = Pt(8)

        # Paragraphes
        for p_text in sec.get("paragraphs", []):
            p = doc.add_paragraph()
            prun = p.add_run(p_text)
            prun.font.size = Pt(11)
            prun.font.color.rgb = COLOR_TEXT
            p.paragraph_format.line_spacing = 1.2
            p.paragraph_format.space_after = Pt(8)

        # Bullets
        for b_text in sec.get("bullets", []):
            bp = doc.add_paragraph(style='List Bullet')
            brun = bp.add_run(b_text)
            brun.font.size = Pt(10.5)
            brun.font.color.rgb = COLOR_TEXT
            bp.paragraph_format.space_after = Pt(4)

        # Encadré Callout / Vigilance si présent
        callout_text = sec.get("callout")
        if callout_text:
            tbl = doc.add_table(rows=1, cols=1)
            tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
            cell = tbl.rows[0].cells[0]
            shading = parse_xml(r'<w:shd {} w:fill="EFF6FF"/>'.format(nsdecls('w')))
            cell._tc.get_or_add_tcPr().append(shading)
            cp = cell.paragraphs[0]
            crun = cp.add_run(f"📌 {callout_text}")
            crun.font.size = Pt(10)
            crun.font.italic = True
            crun.font.color.rgb = COLOR_SECONDARY
            cp.paragraph_format.space_after = Pt(2)
            doc.add_paragraph().paragraph_format.space_after = Pt(8)

        # Image associée si présente
        kf_name = sec.get("keyframe")
        if kf_name and (keyframes_dir / kf_name).exists():
            img_path = keyframes_dir / kf_name
            ip = doc.add_paragraph()
            ip.alignment = WD_ALIGN_PARAGRAPH.CENTER
            ip.paragraph_format.space_before = Pt(8)
            ip.paragraph_format.space_after = Pt(4)
            ip.add_run().add_picture(str(img_path), width=Inches(5.5))

            # Légende
            cap_p = doc.add_paragraph()
            cap_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            c_run = cap_p.add_run(f"Illustration : {kf_name}")
            c_run.font.size = Pt(9)
            c_run.font.italic = True
            c_run.font.color.rgb = COLOR_MUTED
            cap_p.paragraph_format.space_after = Pt(12)

    doc.save(str(output_docx_path))
    print(f" Article Word (.docx) généré : {output_docx_path}")


# ==============================================================================
# Étape 5B : Génération du Support PowerPoint (.pptx)
# ==============================================================================
def generate_pptx(plan: Dict[str, Any], keyframes_dir: Path, output_pptx_path: Path):
    """Génère une présentation PowerPoint 16:9 haute qualité via python-pptx."""
    print(f"\n[5/5a]  Génération du PowerPoint natif : {output_pptx_path.name}...")
    from pptx import Presentation
    from pptx.util import Inches, Pt
    from pptx.dml.color import RGBColor
    from pptx.enum.text import PP_ALIGN

    prs = Presentation()
    # Format 16:9 widescreen (13.33 x 7.5 pouces)
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_layout = prs.slide_layouts[6]

    # Palette graphique corporate
    COLOR_BG = RGBColor(15, 23, 42)        # Slate 900
    COLOR_CARD = RGBColor(30, 41, 59)      # Slate 800
    COLOR_PRIMARY = RGBColor(56, 189, 248)  # Sky 400
    COLOR_TEXT = RGBColor(248, 250, 252)   # Slate 50
    COLOR_MUTED = RGBColor(148, 163, 184)  # Slate 400

    for slide_data in plan.get("slides", []):
        slide = prs.slides.add_slide(blank_layout)

        # Fond sombre
        bg = slide.background
        fill = bg.fill
        fill.solid()
        fill.fore_color.rgb = COLOR_BG

        stype = slide_data.get("type", "content")
        title_text = slide_data.get("title", "")

        if stype == "title":
            # Slide de titre
            txBox = slide.shapes.add_textbox(Inches(1.5), Inches(2.2), Inches(10.33), Inches(3.0))
            tf = txBox.text_frame
            tf.word_wrap = True

            p = tf.paragraphs[0]
            p.text = plan.get("presentation_title", title_text)
            p.font.size = Pt(44)
            p.font.bold = True
            p.font.color.rgb = COLOR_PRIMARY

            p2 = tf.add_paragraph()
            p2.text = plan.get("presentation_subtitle", slide_data.get("subtitle", ""))
            p2.font.size = Pt(22)
            p2.font.color.rgb = COLOR_MUTED
            p2.space_before = Pt(20)

        else:
            # En-tête
            header_box = slide.shapes.add_textbox(Inches(0.8), Inches(0.5), Inches(11.7), Inches(1.0))
            htf = header_box.text_frame
            hp = htf.paragraphs[0]
            hp.text = title_text
            hp.font.size = Pt(28)
            hp.font.bold = True
            hp.font.color.rgb = COLOR_PRIMARY

            # Vérifier présence image
            kf_name = slide_data.get("keyframe")
            img_path = (keyframes_dir / kf_name) if kf_name else None
            has_img = img_path and img_path.exists()

            text_width = Inches(5.8) if has_img else Inches(11.7)

            # Cartouche de contenu (bullets)
            content_box = slide.shapes.add_textbox(Inches(0.8), Inches(1.8), text_width, Inches(4.8))
            ctf = content_box.text_frame
            ctf.word_wrap = True

            bullets = slide_data.get("bullets", [])
            for i, b in enumerate(bullets):
                p = ctf.paragraphs[0] if i == 0 else ctf.add_paragraph()
                p.text = f"•  {b}"
                p.font.size = Pt(17)
                p.font.color.rgb = COLOR_TEXT
                p.space_after = Pt(16)

            # Insertion de l'image si présente
            if has_img:
                slide.shapes.add_picture(str(img_path), Inches(7.0), Inches(1.8), width=Inches(5.5))

    prs.save(str(output_pptx_path))
    print(f" PowerPoint sauvegardé : {output_pptx_path}")


# ==============================================================================
# Étape 5B : Génération Deck Web HTML & Export PDF (ECC frontend-slides)
# ==============================================================================
def generate_html_deck(plan: Dict[str, Any], keyframes_dir: Path, output_html_path: Path):
    """Génère le deck HTML autonome avec images en Base64 selon les règles ECC."""
    print(f"\n[5/5b] 🌐 Génération du Deck HTML interactif (ECC frontend-slides)...")

    slides_html = []
    title = plan.get("presentation_title", "Présentation Exécutive")
    subtitle = plan.get("presentation_subtitle", "")

    for idx, s in enumerate(plan.get("slides", [])):
        stype = s.get("type", "content")
        s_title = s.get("title", "")
        kf_name = s.get("keyframe")
        
        # Encodage base64 de l'image si présente
        img_b64 = None
        if kf_name and (keyframes_dir / kf_name).exists():
            with open(keyframes_dir / kf_name, "rb") as f:
                img_b64 = f"data:image/jpeg;base64,{base64.b64encode(f.read()).decode('utf-8')}"

        if stype == "title":
            slide_content = f"""
            <section class="slide title-slide" data-slide="{idx+1}">
                <div class="title-content">
                    <span class="badge">RESTITUTION VIDÉO EXÉCUTIVE</span>
                    <h1 class="gradient-text">{title}</h1>
                    <p class="subtitle">{subtitle or s_title}</p>
                    <div class="meta-footer">
                        <span>🗓 Synthèse Automatisée</span>
                        <span>⏱ Modèle 16:9 Viewport</span>
                        <span>🚀 Direction & Partenaires</span>
                    </div>
                </div>
            </section>
            """
        else:
            bullets_li = "".join([f"<li><span class='bullet-icon'>▸</span> {b}</li>" for b in s.get("bullets", [])])
            img_tag = f"<div class='slide-visual'><img src='{img_b64}' alt='Capture vidéo' /></div>" if img_b64 else ""

            kpi_html = ""
            if "kpi" in s and s["kpi"]:
                kpi_val = s["kpi"].get("value", "")
                kpi_lbl = s["kpi"].get("label", "")
                kpi_html = f"<div class='kpi-badge'><span class='kpi-val'>{kpi_val}</span><span class='kpi-lbl'>{kpi_lbl}</span></div>"

            layout_class = "split-layout" if img_b64 else "full-layout"

            slide_content = f"""
            <section class="slide content-slide" data-slide="{idx+1}">
                <div class="slide-header">
                    <span class="slide-number">{idx+1:02d}</span>
                    <h2>{s_title}</h2>
                    {kpi_html}
                </div>
                <div class="slide-body {layout_class}">
                    <div class="slide-bullets">
                        <ul>{bullets_li}</ul>
                    </div>
                    {img_tag}
                </div>
            </section>
            """
        slides_html.append(slide_content)

    full_html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title}</title>
    <style>
        :root {{
            --bg-primary: #0b0f19;
            --bg-card: rgba(18, 24, 38, 0.85);
            --border: rgba(255, 255, 255, 0.1);
            --primary: #38bdf8;
            --primary-glow: rgba(56, 189, 248, 0.25);
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        }}

        * {{
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }}

        body {{
            background: var(--bg-primary);
            color: var(--text-main);
            font-family: var(--font-family);
            overflow: hidden;
            height: 100vh;
            height: 100dvh;
            width: 100vw;
        }}

        .deck-container {{
            width: 100vw;
            height: 100vh;
            height: 100dvh;
            scroll-snap-type: y mandatory;
            overflow-y: scroll;
            overflow-x: hidden;
        }}

        .slide {{
            width: 100vw;
            height: 100vh;
            height: 100dvh;
            scroll-snap-align: start;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: clamp(1.5rem, 4vw, 3.5rem);
            position: relative;
            background: radial-gradient(circle at 80% 20%, rgba(56, 189, 248, 0.08) 0%, transparent 60%);
        }}

        .title-content {{
            text-align: center;
            max-width: 900px;
        }}

        .badge {{
            display: inline-block;
            background: rgba(56, 189, 248, 0.15);
            color: var(--primary);
            border: 1px solid rgba(56, 189, 248, 0.3);
            border-radius: 9999px;
            padding: 0.35rem 1rem;
            font-size: 0.85rem;
            font-weight: 600;
            letter-spacing: 0.08em;
            margin-bottom: 1.5rem;
        }}

        .gradient-text {{
            font-size: clamp(2.2rem, 5vw, 4rem);
            font-weight: 800;
            line-height: 1.15;
            background: linear-gradient(135deg, #ffffff 40%, var(--primary) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 1.2rem;
        }}

        .subtitle {{
            font-size: clamp(1.1rem, 2vw, 1.5rem);
            color: var(--text-muted);
            margin-bottom: 2.5rem;
        }}

        .meta-footer {{
            display: flex;
            gap: 2rem;
            justify-content: center;
            color: var(--text-muted);
            font-size: 0.9rem;
            border-top: 1px solid var(--border);
            padding-top: 1.5rem;
        }}

        .content-slide {{
            justify-content: flex-start;
            align-items: stretch;
            max-width: 1400px;
            margin: 0 auto;
        }}

        .slide-header {{
            display: flex;
            align-items: center;
            gap: 1.5rem;
            border-bottom: 1px solid var(--border);
            padding-bottom: 1rem;
            margin-bottom: 2rem;
        }}

        .slide-number {{
            font-size: 1.4rem;
            font-weight: 800;
            color: var(--primary);
            opacity: 0.8;
        }}

        .slide-header h2 {{
            font-size: clamp(1.5rem, 2.8vw, 2.2rem);
            font-weight: 700;
            flex-grow: 1;
        }}

        .kpi-badge {{
            display: flex;
            align-items: baseline;
            gap: 0.5rem;
            background: var(--bg-card);
            border: 1px solid rgba(56, 189, 248, 0.4);
            border-radius: 8px;
            padding: 0.4rem 0.8rem;
        }}

        .kpi-val {{
            font-size: 1.3rem;
            font-weight: 800;
            color: var(--primary);
        }}

        .kpi-lbl {{
            font-size: 0.8rem;
            color: var(--text-muted);
        }}

        .slide-body {{
            display: flex;
            flex-grow: 1;
            align-items: center;
            gap: 2.5rem;
        }}

        .slide-bullets {{
            flex: 1;
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: clamp(1.5rem, 2.5vw, 2.2rem);
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }}

        .slide-bullets ul {{
            list-style: none;
            display: flex;
            flex-direction: column;
            gap: 1.4rem;
        }}

        .slide-bullets li {{
            font-size: clamp(1.05rem, 1.6vw, 1.35rem);
            line-height: 1.5;
            color: #e2e8f0;
            display: flex;
            align-items: flex-start;
            gap: 0.8rem;
        }}

        .bullet-icon {{
            color: var(--primary);
            font-size: 1.1rem;
            flex-shrink: 0;
            margin-top: 0.15rem;
        }}

        .slide-visual {{
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
        }}

        .slide-visual img {{
            max-width: 100%;
            max-height: 55vh;
            border-radius: 12px;
            border: 1px solid var(--border);
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.5);
            object-fit: contain;
        }}

        /* Styles d'impression 16:9 stricts */
        @media print {{
            @page {{
                size: 16in 9in;
                margin: 0;
            }}
            html, body, .deck-container {{
                width: 16in !important;
                height: auto !important;
                overflow: visible !important;
                background: #0b0f19 !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }}
            .slide {{
                width: 16in !important;
                height: 9in !important;
                min-height: 9in !important;
                max-height: 9in !important;
                page-break-after: always !important;
                break-after: page !important;
                overflow: hidden !important;
            }}
            .slide:last-of-type {{
                page-break-after: auto !important;
                break-after: auto !important;
            }}
        }}
    </style>
</head>
<body>
    <div class="deck-container" id="deck">
        {"".join(slides_html)}
    </div>
    <script>
        // Navigation clavier (Flèches, Espace, PageUp/Down)
        const container = document.getElementById('deck');
        const slides = Array.from(document.querySelectorAll('.slide'));
        let currentIndex = 0;

        window.addEventListener('keydown', (e) => {{
            if (['ArrowDown', 'ArrowRight', 'Space', 'PageDown'].includes(e.code)) {{
                e.preventDefault();
                currentIndex = Math.min(currentIndex + 1, slides.length - 1);
                slides[currentIndex].scrollIntoView({{ behavior: 'smooth' }});
            }} else if (['ArrowUp', 'ArrowLeft', 'PageUp'].includes(e.code)) {{
                e.preventDefault();
                currentIndex = Math.max(currentIndex - 1, 0);
                slides[currentIndex].scrollIntoView({{ behavior: 'smooth' }});
            }}
        }});
    </script>
</body>
</html>"""

    output_html_path.write_text(full_html, encoding="utf-8")
    print(f" Deck HTML autonome généré : {output_html_path}")


# ==============================================================================
# Étape 5C : Export PDF via Edge/Chrome Headless
# ==============================================================================
def export_pdf_headless(html_path: Path, output_pdf_path: Path):
    """Exécute Edge ou Chrome headless pour imprimer le PDF 16:9 parfait."""
    print(f"\n[5/5c] 📄 Export en PDF 16:9 via Chromium headless...")
    
    browsers = [
        Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
        Path(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"),
        Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
        Path(r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"),
    ]

    browser_exe = None
    for b in browsers:
        if b.exists():
            browser_exe = b
            break

    if not browser_exe:
        print("  Navigateur Chromium non trouvé pour l'export automatique en PDF. Utilisez 'Imprimer en PDF' depuis le fichier HTML.")
        return

    cmd = [
        str(browser_exe),
        "--headless=new",
        "--disable-gpu",
        "--run-all-compositor-stages-before-draw",
        f"--print-to-pdf={output_pdf_path}",
        "--no-pdf-header-footer",
        str(html_path.resolve())
    ]
    subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if output_pdf_path.exists():
        print(f" PDF 16:9 exporté avec succès : {output_pdf_path}")


# ==============================================================================
# Point d'Entrée Principal
# ==============================================================================
def main():
    parser = argparse.ArgumentParser(description="Pipeline Automatise Video -> Transcription, Synthese & Decks")
    parser.add_argument("--video", required=True, help="Chemin du fichier vidéo MP4")
    parser.add_argument("--output", default="output", help="Répertoire de sortie des livrables")
    parser.add_argument("--model", default="medium", help="Modèle Whisper (tiny, base, small, medium, large-v3-turbo)")
    parser.add_argument("--provider", default="gemini", choices=["gemini", "mistral", "openai"], help="Fournisseur LLM")
    parser.add_argument("--api-key", default="", help="Clé API Gemini ou Mistral")
    parser.add_argument("--skip-transcription", action="store_true", help="Réutilise le transcript.md s'il existe déjà")
    args = parser.parse_args()

    video_path = Path(args.video).resolve()
    if not video_path.exists():
        print(f"Erreur : Le fichier vidéo '{video_path}' est introuvable.")
        sys.exit(1)

    out_dir = Path(args.output).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    keyframes_dir = out_dir / "keyframes"

    audio_path = out_dir / "audio_extracted.wav"
    transcript_path = out_dir / "transcript.md"
    summary_path = out_dir / "summary.md"
    docx_path = out_dir / "article_mode_d_emploi.docx"
    plan_path = out_dir / "deck_structure.json"
    pptx_path = out_dir / "presentation.pptx"
    html_path = out_dir / "presentation.html"
    pdf_path = out_dir / "presentation.pdf"

    # Récupérer la clé API
    api_key = args.api_key or os.getenv("GEMINI_API_KEY") or os.getenv("MISTRAL_API_KEY")
    if not api_key:
        print("Erreur : Clé d'accès LLM requise (--api-key ou variable d'environnement).")
        sys.exit(1)

    print("=" * 60)
    print(" DÉMARRAGE DU PIPELINE VIDÉO -> LIVRABLES STRATÉGIQUES")
    print(f" Vidéo cible    : {video_path.name}")
    print(f" Destination     : {out_dir}")
    print(f" Moteur Whisper  : {args.model}")
    print(f" Moteur Synthèse : {args.provider.upper()}")
    print("=" * 60)

    # 1. Extraction Audio & 2. Transcription
    if args.skip_transcription and transcript_path.exists():
        print(f"\n Reprise sur incident : réutilisation de {transcript_path}")
        transcript_text = transcript_path.read_text(encoding="utf-8")
    else:
        extract_audio(video_path, audio_path)
        transcript_text = transcribe_audio(audio_path, transcript_path, model_size=args.model)

    # 3. Découpage de Scènes
    keyframes = extract_scenes(video_path, keyframes_dir)

    # 4. Synthèse LLM & Plan
    plan_data = analyze_with_llm(transcript_text, keyframes, api_key=api_key, provider=args.provider)
    summary_path.write_text(plan_data.get("summary_markdown", "# Synthèse"), encoding="utf-8")
    plan_path.write_text(json.dumps(plan_data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f" Synthèse exécutive sauvegardée : {summary_path}")

    # 5. Production des Livrables (Word + PowerPoint + HTML + PDF)
    generate_docx_guide(plan_data, keyframes_dir, docx_path)
    generate_pptx(plan_data, keyframes_dir, pptx_path)
    generate_html_deck(plan_data, keyframes_dir, html_path)
    export_pdf_headless(html_path, pdf_path)

    print("\n" + "=" * 60)
    print(" TRAITEMENT FINALISÉ AVEC SUCCÈS !")
    print(" Livrables disponibles :")
    print(f"   • Transcription : {transcript_path}")
    print(f"   • Synthèse      : {summary_path}")
    print(f"   • Article Word  : {docx_path}")
    print(f"   • PowerPoint    : {pptx_path}")
    print(f"   • Deck HTML     : {html_path}")
    print(f"   • Deck PDF 16:9 : {pdf_path}")
    print("=" * 60)


if __name__ == "__main__":
    main()
