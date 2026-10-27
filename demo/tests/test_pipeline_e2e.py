import pytest
from pathlib import Path
from unittest.mock import patch
import pipeline


class TestPipelineE2EHarness:
    """Test du banc d'essai (harness) de bout en bout du pipeline avec composants simulés."""

    def test_pipeline_full_workflow_mocked(self, tmp_path, mock_llm_data, sample_keyframe_image):
        """Vérifie l'orchestration complète du pipeline de A à Z avec validation des livrables."""
        dummy_video = tmp_path / "test_session.mp4"
        dummy_video.write_bytes(b"\x00\x00\x00\x18ftypmp42" + b"\x00" * 1024)

        output_dir = tmp_path / "output"
        output_dir.mkdir(parents=True, exist_ok=True)

        keyframes_dir = output_dir / "keyframes"
        keyframes_dir.mkdir(parents=True, exist_ok=True)
        kf_img = keyframes_dir / "slide_keyframe_01.jpg"
        kf_img.write_bytes(sample_keyframe_image.read_bytes())

        mock_kfs = [
            {
                "index": 1,
                "timestamp": "00:00:15",
                "seconds": 15.0,
                "filename": kf_img.name,
                "path": kf_img,
            }
        ]

        dummy_audio = output_dir / "audio_extracted.wav"
        dummy_audio.write_bytes(b"RIFF" + b"\x00" * 100)

        with patch("pipeline.extract_audio", return_value=dummy_audio) as mock_audio, \
             patch("pipeline.transcribe_audio", return_value="Transcription simulée.") as mock_transcribe, \
             patch("pipeline.extract_scenes", return_value=mock_kfs) as mock_scenes, \
             patch("pipeline.analyze_with_llm", return_value=mock_llm_data) as mock_llm, \
             patch("pipeline.export_pdf_headless") as mock_pdf:

            test_args = [
                "pipeline.py",
                "--video", str(dummy_video),
                "--output", str(output_dir),
                "--provider", "openai",
                "--api-key", "sk-test-mock-key-12345",
            ]

            with patch("sys.argv", test_args):
                pipeline.main()

            mock_audio.assert_called_once()
            mock_transcribe.assert_called_once()
            mock_scenes.assert_called_once()
            mock_llm.assert_called_once()
            mock_pdf.assert_called_once()

            assert (output_dir / "summary.md").exists()
            assert (output_dir / "deck_structure.json").exists()
            assert (output_dir / "article_mode_d_emploi.docx").exists()
            assert (output_dir / "presentation.pptx").exists()
            assert (output_dir / "presentation.html").exists()

            summary_content = (output_dir / "summary.md").read_text(encoding="utf-8")
            assert "Synthèse de la session" in summary_content
