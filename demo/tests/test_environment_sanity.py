import pytest
import subprocess
from pathlib import Path


class TestEnvironmentSanity:
    """Vérifications du socle technique et de la présence des outils indispensables."""

    def test_ffmpeg_available(self):
        """Vérifie que l'exécutable ffmpeg autonome est disponible via imageio_ffmpeg."""
        import imageio_ffmpeg
        ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
        assert Path(ffmpeg_exe).exists()
        res = subprocess.run([ffmpeg_exe, "-version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        assert res.returncode == 0
        assert "ffmpeg version" in res.stdout

    def test_dependencies_importable(self):
        """Vérifie que toutes les dépendances requises s'importent sans conflit binaire."""
        import faster_whisper
        import scenedetect
        import docx
        import pptx
        import PIL
        import requests
        import tqdm

        assert hasattr(faster_whisper, "WhisperModel")
        assert hasattr(scenedetect, "detect")
        assert hasattr(docx, "Document")
        assert hasattr(pptx, "Presentation")
