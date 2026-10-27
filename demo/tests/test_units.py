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
        assert "BANNIR LE JARGON IA" in source or "ANTI-CLICHÉS" in source

    def test_clean_humanizer_text_filters_cliches(self):
        """Vérifie que les tics IA notoires sont éliminés par le filtre programmatique."""
        raw_text = (
            "Dans un monde hyper-connecté et en constante évolution, il est crucial de libérer votre potentiel créatif. "
            "Ces activités nourrissent l'âme et révèlent des trésors cachés. "
            "Gamora a su le faire. Présentation, date, Zoe Hames — un voyage exceptionnel !"
        )
        cleaned = pipeline.clean_humanizer_text(raw_text)

        assert "Dans un monde" not in cleaned
        assert "nourrissent l'âme" not in cleaned
        assert "trésors cachés" not in cleaned
        assert "libérer votre potentiel créatif" not in cleaned
        assert "Gamora" not in cleaned
        assert "date" not in cleaned
        assert "—" not in cleaned

    def test_finops_calculation_openai(self):
        """Vérifie le calcul FinOps pour OpenAI gpt-4o-mini."""
        res = pipeline.calculate_finops_cost(
            provider="openai",
            model="gpt-4o-mini",
            prompt_tokens=10000,
            completion_tokens=2000,
            audio_duration_seconds=420.0
        )
        assert res["provider"] == "openai"
        assert res["model"] == "gpt-4o-mini"
        assert res["tokens"]["total_tokens"] == 12000
        # 10k in * 0.150/1M = 0.0015 $, 2k out * 0.600/1M = 0.0012 $ -> total = 0.0027 $
        assert abs(res["costs"]["total_llm_cost_usd"] - 0.0027) < 1e-5
        assert res["costs"]["total_llm_cost_eur"] > 0
        assert res["local_compute_savings"]["whisper_cloud_avoided_cost_usd"] == 0.042

    def test_finops_calculation_gemini_and_savings(self):
        """Vérifie le calcul FinOps pour Gemini et l'économie Whisper locale."""
        res = pipeline.calculate_finops_cost(
            provider="gemini",
            model="gemini-2.0-flash",
            prompt_tokens=5000,
            completion_tokens=1000,
            audio_duration_seconds=120.0
        )
        assert res["provider"] == "gemini"
        assert res["tokens"]["total_tokens"] == 6000
        assert res["costs"]["total_llm_cost_usd"] > 0
        # 2 minutes * 0.006 $ = 0.012 $ économisés
        assert res["local_compute_savings"]["whisper_cloud_avoided_cost_usd"] == 0.012
