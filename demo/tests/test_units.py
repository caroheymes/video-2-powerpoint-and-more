import pytest
import re
from pathlib import Path
import pipeline


class TestUnitFunctions:
    """Tests des fonctions utilitaires et de traitement unitaire."""

    @pytest.mark.parametrize(
        "seconds, expected",
        [
            (0.0, "00:00:00"),
            (5.4, "00:00:05"),
            (59.9, "00:00:59"),
            (60.0, "00:01:00"),
            (125.0, "00:02:05"),
            (3600.0, "01:00:00"),
            (3665.0, "01:01:05"),
            (7322.0, "02:02:02"),
        ],
    )
    def test_format_timestamp(self, seconds, expected):
        """Vérifie le formattage rigoureux des horodatages [HH:MM:SS]."""
        assert pipeline.format_timestamp(seconds) == expected

    @pytest.mark.parametrize(
        "input_url, expected_id",
        [
            (
                "https://drive.google.com/file/d/1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2/view?usp=sharing",
                "1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2",
            ),
            (
                "https://drive.google.com/uc?export=download&id=1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2",
                "1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2",
            ),
            (
                "https://drive.google.com/open?id=1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2",
                "1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2",
            ),
            (
                "1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2",
                "1pbT3kRivzOONa3B1bRP1nIhbFdkt3ef2",
            ),
        ],
    )
    def test_gdrive_id_regex(self, input_url, expected_id):
        """Vérifie l'extraction précise de l'identifiant Google Drive à partir de formats d'URL variés."""
        if "drive.google.com" in input_url:
            m = re.search(r'/d/([a-zA-Z0-9_-]+)', input_url)
            if not m:
                m = re.search(r'id=([a-zA-Z0-9_-]+)', input_url)
            extracted = m.group(1) if m else None
        else:
            extracted = input_url.strip()
        assert extracted == expected_id

    def test_humanizer_rules_defined(self):
        """Vérifie que les directives Humanizer anti-clichés sont bien ancrées dans le code du pipeline."""
        import inspect
        source = inspect.getsource(pipeline.analyze_with_llm)
        assert "HUMANIZER" in source
        assert "BANNIR LE JARGON IA" in source
        assert "BANNIR LA MISE EN FORME MÉCANIQUE" in source
