import base64
import pathlib
import re
import subprocess

root = pathlib.Path(r"C:\Users\Admin\Documents\MALT\10_14_Accor")
html_path = root / "presentation.html"
img_path = root / "Architecture Snowflake de Monétisation et d’Échange de Données Accor.png"
locked_path = root / "presentation-client-locked.html"
pdf_path = root / "Accor_Data_Partnerships_Proposition_Approche.pdf"

html = html_path.read_text(encoding="utf-8")

# 1. Add @media print CSS to presentation.html if not already present
print_css = """
@media print {
    @page {
        size: 16in 9in;
        margin: 0;
    }
    html, body {
        width: 16in !important;
        height: auto !important;
        overflow: visible !important;
        background: var(--bg-primary) !important;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
        scroll-snap-type: none !important;
    }
    .deck-topbar, .nav-dots, .progress-bar {
        display: none !important;
    }
    .slide {
        width: 16in !important;
        height: 9in !important;
        min-height: 9in !important;
        max-height: 9in !important;
        page-break-after: always !important;
        break-after: page !important;
        overflow: hidden !important;
    }
    .slide:last-of-type {
        page-break-after: auto !important;
        break-after: auto !important;
    }
    .reveal {
        opacity: 1 !important;
        transform: none !important;
        transition: none !important;
    }
}
</style>"""

if "@media print" not in html:
    html = html.replace("</style>", print_css, 1)
    html_path.write_text(html, encoding="utf-8")

# 2. Build presentation-client-locked.html
locked = html

# Embed PNG as base64 data URI so the locked file is 100% standalone
b64_img = base64.b64encode(img_path.read_bytes()).decode("ascii")
data_uri = f"data:image/png;base64,{b64_img}"
locked = locked.replace(
    "Architecture%20Snowflake%20de%20Mon%C3%A9tisation%20et%20d%E2%80%99%C3%89change%20de%20Donn%C3%A9es%20Accor.png",
    data_uri,
)

# Remove [U] mention in footer and titles
locked = locked.replace(" · [U] dévoiler les zones floutées", "")
locked = re.sub(
    r'title="Cliquer pour dévoiler[^"]*"',
    'title="Détail réservé à la présentation en séance"',
    locked,
)

# Disable cursor pointer & unlock CSS/JS in locked version
locked = locked.replace(
    ".teaser-blur {\n    position: relative;\n    cursor: pointer;\n}",
    ".teaser-blur {\n    position: relative;\n    cursor: default;\n}",
)
locked = re.sub(
    r"initTeasers\(\)\s*\{[\s\S]*?\n    \}",
    "initTeasers() {\n        // Locked client version: teaser unlocking disabled\n    }",
    locked,
)
locked = locked.replace(
    "            } else if (e.key.toLowerCase() === 'u') {\n                document.body.classList.toggle('unlock-all-teasers');\n",
    "",
)


def cipher_char(c: str) -> str:
    if c.islower():
        return chr((ord(c) - 97 + 13) % 26 + 97)
    elif c.isupper():
        return chr((ord(c) - 65 + 13) % 26 + 65)
    elif c.isdigit():
        return str((int(c) + 5) % 10)
    elif c in "éèêëàâîïôùûüçÉÈÊËÀÂÎÏÔÙÛÜÇ":
        return "e"
    return c


def scramble_html_inner(inner: str) -> str:
    parts = re.split(r"(<[^>]+>|&[a-zA-Z0-9#]+;)", inner)
    out = []
    for p in parts:
        if p.startswith("<") or p.startswith("&"):
            out.append(p)
        else:
            out.append("".join(cipher_char(ch) for ch in p))
    return "".join(out)


locked = re.sub(
    r'(<(?:span|li)\s+class="blur-target">)([\s\S]*?)(</(?:span|li)>)',
    lambda m: m.group(1) + scramble_html_inner(m.group(2)) + m.group(3),
    locked,
)

locked_path.write_text(locked, encoding="utf-8")
print(f"Wrote locked HTML: {locked_path} ({locked_path.stat().st_size} bytes)")

# 3. Print to PDF using headless Edge or Chrome
edge_candidates = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
]
browser = next((p for p in edge_candidates if pathlib.Path(p).exists()), None)
if browser:
    cmd = [
        browser,
        "--headless",
        "--disable-gpu",
        "--no-pdf-header-footer",
        f"--print-to-pdf={pdf_path}",
        locked_path.as_uri(),
    ]
    subprocess.run(cmd, check=True)
    print(f"Wrote PDF: {pdf_path} ({pdf_path.stat().st_size} bytes)")
else:
    print("No Edge/Chrome found")
