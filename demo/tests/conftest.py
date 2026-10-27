import sys
from pathlib import Path
import pytest
from PIL import Image

# Ensure demo directory is in sys.path
demo_dir = Path(__file__).resolve().parent.parent
if str(demo_dir) not in sys.path:
    sys.path.insert(0, str(demo_dir))


@pytest.fixture
def keyframes_dir(tmp_path):
    """Creates a temporary keyframes directory with a sample JPG image."""
    kf_dir = tmp_path / "keyframes"
    kf_dir.mkdir(parents=True, exist_ok=True)
    img_path = kf_dir / "slide_keyframe_01.jpg"
    img = Image.new("RGB", (640, 360), color=(30, 41, 59))
    img.save(img_path, format="JPEG")
    return kf_dir


@pytest.fixture
def sample_keyframe_image(keyframes_dir):
    """Returns the path to the sample keyframe image."""
    return keyframes_dir / "slide_keyframe_01.jpg"


@pytest.fixture
def mock_keyframes(sample_keyframe_image):
    """Returns a list of mock keyframe dictionaries."""
    return [
        {
            "index": 1,
            "timestamp": "00:00:15",
            "seconds": 15.0,
            "filename": sample_keyframe_image.name,
            "path": sample_keyframe_image,
        },
        {
            "index": 2,
            "timestamp": "00:01:45",
            "seconds": 105.0,
            "filename": sample_keyframe_image.name,
            "path": sample_keyframe_image,
        },
    ]


@pytest.fixture
def mock_llm_data(sample_keyframe_image):
    """Returns structured JSON data simulating an LLM analysis response."""
    return {
        "summary_markdown": (
            "# Synthèse de la session\n\n"
            "Intervention centrée sur la créativité et la gestion de la surcharge d'informations.\n\n"
            "Trois constats principaux ont émergé des échanges :\n"
            "- L'accélération des flux de travail réduit le temps de réflexion stratégique.\n"
            "- La créativité nécessite des plages de déconnexion volontaires.\n"
            "- Les équipes les plus innovantes sanctuarisent des temps calmes réguliers."
        ),
        "article_title": "Gestion du Temps et Créativité en Entreprise",
        "article_sections": [
            {
                "heading": "Le défi de la surcharge d'information",
                "paragraphs": [
                    "Dans la plupart des organisations, la surcharge d'emails et de réunions fragmente l'attention.",
                    "Ce phénomène pénalise directement la qualité des décisions et la capacité d'innovation collective.",
                ],
                "bullets": [
                    "Mettre en place des demi-journées sans réunion",
                    "Favoriser la communication asynchrone pour les arbitrages non urgents",
                ],
                "keyframe": sample_keyframe_image.name,
                "callout": "La productivité réelle dépend de la qualité de la réflexion, pas du volume de messages traités.",
            },
            {
                "heading": "Sanctuariser les espaces de réflexion",
                "paragraphs": [
                    "Les participants ont partagé des retours d'expérience concrets sur la gestion des temps calmes.",
                    "L'objectif est d'installer des routines simples mais pérennes au sein des équipes.",
                ],
                "bullets": [
                    "Bloquer 2 heures hebdomadaires dans les agendas",
                    "Remplacer les longs comptes-rendus par des synthèses courtes",
                ],
                "keyframe": sample_keyframe_image.name,
                "callout": "Une heure de concentration ininterrompue produit plus de valeur que trois réunions d'alignement.",
            },
        ],
        "presentation_title": "Retrouver du Temps pour Créer",
        "presentation_subtitle": "Restitution de l'intervention de Zoe Hames - Synthèse opérationnelle",
        "slides": [
            {
                "slide_number": 1,
                "type": "title",
                "title": "Retrouver du Temps pour Créer",
                "subtitle": "Intervention de Zoe Hames - Synthèse opérationnelle",
            },
            {
                "slide_number": 2,
                "type": "content",
                "title": "Le piège de la surcharge quotidienne",
                "bullets": [
                    "Fragmentation permanente de l'attention par les alertes et réunions",
                    "Diminution directe de la créativité et de la hauteur de vue",
                    "Nécessité de sanctuariser des plages de travail asynchrone",
                ],
                "keyframe": sample_keyframe_image.name,
                "kpi": "72% du temps absorbé par la communication réactive",
            },
            {
                "slide_number": 3,
                "type": "content",
                "title": "Recommandations opérationnelles",
                "bullets": [
                    "Sanctuariser 2 heures sans interruption chaque semaine",
                    "Passer les points d'étape en asynchrone",
                    "Évaluer les projets sur leurs résultats plutôt que sur la disponibilité immédiate",
                ],
                "keyframe": sample_keyframe_image.name,
                "kpi": None,
            },
        ],
    }
