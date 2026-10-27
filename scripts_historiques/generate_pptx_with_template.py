# C:\Users\Admin\Documents\certif\bloc3\perso\generate_pptx_with_template.py
import os
import re
import shutil
import sys

# Charger python-pptx
try:
    from pptx import Presentation
    from pptx.util import Pt
except ImportError:
    print("La bibliothèque python-pptx est requise. Veuillez l'installer.")
    sys.exit(1)

def update_text_in_shape_inplace(shape, text_or_bullets):
    """
    Remplace le texte d'une forme existante tout en conservant son style 
    (police, taille, couleur, puces) au niveau des paragraphes.
    """
    if not shape.has_text_frame:
        return
        
    tf = shape.text_frame
    tf.word_wrap = True
    
    # Cas 1 : Remplacement par une chaîne de caractères simple (ex: Titres)
    if isinstance(text_or_bullets, str):
        if tf.paragraphs:
            p = tf.paragraphs[0]
            p.text = text_or_bullets
            # Vider les autres paragraphes éventuels pour éviter les résidus
            for extra_p in list(tf.paragraphs)[1:]:
                extra_p.text = ""
        else:
            tf.text = text_or_bullets
            
    # Cas 2 : Remplacement par une liste de puces (ex: Corps de texte)
    elif isinstance(text_or_bullets, list):
        paragraphs = list(tf.paragraphs)
        num_existing = len(paragraphs)
        num_new = len(text_or_bullets)
        
        # Récupérer les styles par défaut du premier paragraphe pour les nouveaux éléments
        font_name = "Arial"
        font_size = Pt(14)
        font_color = None
        if paragraphs:
            p0 = paragraphs[0]
            if p0.font.name:
                font_name = p0.font.name
            if p0.font.size:
                font_size = p0.font.size
            if p0.font.color and p0.font.color.rgb:
                font_color = p0.font.color.rgb
        
        # Mettre à jour les paragraphes
        for i in range(max(num_existing, num_new)):
            if i < num_new:
                bullet_text = text_or_bullets[i]
                if i < num_existing:
                    # Mettre à jour le texte du paragraphe existant (conserve le formatage)
                    paragraphs[i].text = bullet_text
                else:
                    # Créer un nouveau paragraphe si besoin et appliquer le style hérité
                    new_p = tf.add_paragraph()
                    new_p.text = bullet_text
                    new_p.font.name = font_name
                    new_p.font.size = font_size
                    if font_color:
                        new_p.font.color.rgb = font_color
                    new_p.space_after = Pt(10)
            else:
                # Vider les paragraphes en excès
                if i < num_existing:
                    paragraphs[i].text = ""

def parse_markdown_presentation(filepath):
    """
    Parse le fichier presentation_bloc3.md pour extraire les slides sous forme de dictionnaire indexé.
    """
    if not os.path.exists(filepath):
        print(f"Erreur : Le fichier markdown {filepath} n'existe pas.")
        sys.exit(1)
        
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    slides = {}
    chunks = re.split(r'### Slide\s+', content)
    
    for chunk in chunks[1:]:
        lines = chunk.strip().split("\n")
        if not lines:
            continue
            
        header_line = lines[0]
        match = re.match(r'(\d+)\s*:\s*(.*)', header_line)
        if match:
            slide_num = int(match.group(1))
            slide_title = match.group(2).strip()
        else:
            continue
            
        bullets = []
        in_text_section = False
        
        for line in lines[1:]:
            if "**Texte de la slide :**" in line or "**Texte de la diapositive :**" in line:
                in_text_section = True
                continue
            if in_text_section and (
                line.strip().startswith("*   **Notes orales :**") or 
                line.strip().startswith("*   **Critères :**") or 
                line.strip().startswith("*   **Visuel :**") or 
                line.strip().startswith("---")
            ):
                in_text_section = False
                
            if in_text_section:
                clean_line = line.strip()
                if clean_line.startswith(('*', '-')):
                    b_text = re.sub(r'^[\*\-]\s+', '', clean_line)
                    b_text = b_text.replace('**', '').replace('*', '').replace('_', '')
                    bullets.append(b_text)
                    
        slides[slide_num] = {
            "title": slide_title,
            "bullets": bullets
        }
    return slides

def main():
    template_path = "C:/Users/Admin/Documents/certif/bloc2/06_20_En cours d'analyse.pptx"
    markdown_path = "C:/Users/Admin/Documents/certif/bloc3/perso/presentation_bloc3.md"
    output_path = "C:/Users/Admin/Documents/certif/bloc3/perso/presentation_bloc3_final_v3.pptx"

    # 1. Parser le contenu du document markdown
    print(f"Lecture et parsing de : {markdown_path}")
    parsed_slides = parse_markdown_presentation(markdown_path)
    print(f"Nombre de slides extraites du markdown : {len(parsed_slides)}")

    # 2. Copier le template original vers notre cible finale
    print(f"Copie du template de Bloc 2 vers : {output_path}")
    shutil.copy(template_path, output_path)

    # 3. Ouvrir la présentation cible
    prs = Presentation(output_path)
    print("Mise à jour chirurgicale en place (sans supprimer de slides ni casser la mise en forme)...")

    # Mettre à jour les slides existantes du template (0 à 29)
    for idx, slide in enumerate(prs.slides):
        slide_num = idx + 1 # Le markdown est indexé de 1 à 30
        
        # Si on dépasse les 30 slides, on nettoie simplement la slide 31 superflue du template
        if slide_num == 31:
            print("Suppression de la slide 31 superflue du template...")
            rId = prs.slides._sldIdLst[idx].rId
            prs.part.drop_rel(rId)
            del prs.slides._sldIdLst[idx]
            continue
            
        if slide_num not in parsed_slides:
            continue
            
        data = parsed_slides[slide_num]
        print(f"Slide {slide_num} : '{data['title']}'...")
        
        # Extraire et trier les formes textuelles par position verticale (top)
        text_shapes = []
        for shape in slide.shapes:
            if shape.has_text_frame and shape.text.strip():
                text_shapes.append(shape)
        text_shapes.sort(key=lambda s: s.top)
        
        # Déterminer si c'est une slide de transition de section
        is_transition = slide_num in [1, 5, 10, 16, 20, 24, 28]
        
        # Construire les titres de section correspondants au Bloc 2
        title_prefix = ""
        if 2 <= slide_num <= 4:
            title_prefix = "01. CONTEXTE MÉTIER & CADRAGE\n"
        elif 6 <= slide_num <= 9:
            title_prefix = "02. ARCHITECTURE D'INGESTION & SÉCURITÉ\n"
        elif 11 <= slide_num <= 15:
            title_prefix = "03. PIPELINES D'INFÉRENCE & CALCUL DISTRIBUÉ\n"
        elif 17 <= slide_num <= 19:
            title_prefix = "04. INTELLIGENCE ARTIFICIELLE & OPÉRATIONS\n"
        elif 21 <= slide_num <= 23:
            title_prefix = "05. OBSERVABILITÉ & DRIFT CONTINU\n"
        elif 25 <= slide_num <= 27:
            title_prefix = "06. MODÉLISATION & INGESTION ANALYTIQUE (dbt)\n"
        elif 29 <= slide_num <= 30:
            title_prefix = "07. PLAN SÉCURITÉ, CONFORMITÉ & QUALITÉ (RGPD)\n"

        full_title = f"{title_prefix}{data['title']}"

        # Injection des données
        if is_transition:
            # Slides de transition de section
            if len(text_shapes) > 0:
                update_text_in_shape_inplace(text_shapes[0], data["title"].upper())
            if len(text_shapes) > 1:
                # Mettre les puces de description
                update_text_in_shape_inplace(text_shapes[1], data["bullets"])
                
        elif slide_num == 2:
            # Cas de la slide 2 (Contexte Métier avec les KPI boxes)
            # Remplacer le titre
            if len(text_shapes) > 0:
                update_text_in_shape_inplace(text_shapes[0], full_title)
                
            # Mettre à jour la description métier (TextBox 2)
            desc_shape = None
            for shape in slide.shapes:
                if shape.name == "TextBox 2" and "latence" in shape.text:
                    desc_shape = shape
                    break
            if not desc_shape and len(text_shapes) > 1:
                desc_shape = text_shapes[1]
                
            if desc_shape:
                update_text_in_shape_inplace(desc_shape, data["bullets"])
                
            # Mettre à jour les formes géométriques de KPI (les rectangles arrondis)
            kpis = [
                ("ÉCHELLE", "VOLUME CIBLE\n84K+\nTRANSACTIONS EN DIRECT\nFlux de simulation"),
                ("SLA", "SLA CRITIQUE\n< 100ms\nLATENCE D'INFÉRENCE API\nTemps réel strict"),
                ("CONFORMITÉ", "CONFORMITÉ RGPD\n100%\nEXPLICABILITÉ SHAP\nJustification requise")
            ]
            for kpi_key, kpi_val in kpis:
                for shape in slide.shapes:
                    if shape.has_text_frame and kpi_key in shape.text:
                        update_text_in_shape_inplace(shape, kpi_val)
                        
        else:
            # Slides standard (Titre + Liste à puces)
            # 1. Remplacer le Titre
            if len(text_shapes) > 0:
                update_text_in_shape_inplace(text_shapes[0], full_title)
                
            # 2. Remplacer les puces du corps
            body_shape = None
            if len(text_shapes) > 1:
                # On prend la deuxième forme textuelle (le corps principal sous le titre)
                body_shape = text_shapes[1]
                
            if body_shape:
                update_text_in_shape_inplace(body_shape, data["bullets"])

    # 4. Sauvegarder
    prs.save(output_path)
    print(f"\nPrésentation finale PowerPoint générée avec succès : {output_path}")

if __name__ == "__main__":
    main()
