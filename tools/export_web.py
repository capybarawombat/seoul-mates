"""Create a single-threaded production Godot Web export with a WSS endpoint."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build" / "web"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--wss-url", required=True, help="Public WSS endpoint, for example wss://game.example.com/socket")
    args = parser.parse_args()
    if not args.wss_url.startswith("wss://"):
        parser.error("--wss-url must begin with wss://")
    godot = os.environ.get("SEOUL_GODOT") or shutil.which("godot") or shutil.which("godot4")
    if not godot:
        parser.error("Godot executable not found; set SEOUL_GODOT")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    subprocess.run([godot, "--headless", "--path", str(ROOT), "--export-release", "Web", str(OUTPUT / "index.html")], check=True)
    html_path = OUTPUT / "index.html"
    html = html_path.read_text()
    marker = "window.SEOUL_MATES_SERVER_URL = window.SEOUL_MATES_SERVER_URL || '';"
    if marker not in html:
        raise RuntimeError("Expected WSS configuration marker missing from Godot HTML export")
    if "const GODOT_THREADS_ENABLED = false;" not in html:
        raise RuntimeError("Web export unexpectedly requires threads")
    html_path.write_text(html.replace(marker, "window.SEOUL_MATES_SERVER_URL = " + json.dumps(args.wss_url) + ";"))
    for name in ("index.html", "index.js", "index.wasm", "index.pck"):
        if (OUTPUT / name).stat().st_size == 0:
            raise RuntimeError(f"Empty web export file: {name}")
    print(f"Production Web export ready in {OUTPUT}; WSS endpoint: {args.wss_url}")


if __name__ == "__main__":
    main()
