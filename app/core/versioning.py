import os
from pathlib import Path
VERSION_FILE = os.environ.get("SENTINEL_VERSION_FILE", "/opt/mythos-sentinel/VERSION")
def get_app_version() -> str:
    try:
        p = Path(VERSION_FILE)
        if p.exists():
            return p.read_text(encoding="utf-8").strip()
    except Exception:
        pass
    return "0.0.0-unknown"
