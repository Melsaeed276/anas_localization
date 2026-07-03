#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/tool/catalog_app"
OUTPUT_DIR="${ROOT_DIR}/lib/src/features/catalog/server/flutter_web_bundle"
TEMP_DIR="${ROOT_DIR}/build/catalog_web_bundle"

flutter pub get >/dev/null

pushd "${APP_DIR}" >/dev/null
flutter pub get >/dev/null
flutter build web \
  --release \
  --no-wasm-dry-run \
  --no-web-resources-cdn \
  --output "${TEMP_DIR}"
popd >/dev/null

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"
cp -R "${TEMP_DIR}/." "${OUTPUT_DIR}"

# Normalize permissions so CI (Linux) and dev machines (macOS) produce the same
# git file modes in the committed bundle.
OUTPUT_DIR="${OUTPUT_DIR}" python3 - <<'PY'
import os
import pathlib
import re

root = pathlib.Path(os.environ["OUTPUT_DIR"])
for p in root.rglob("*"):
    if p.is_dir():
        p.chmod(0o755)
    elif p.is_file():
        p.chmod(0o644)

# Normalize service worker version for deterministic diffs.
bootstrap = root / "flutter_bootstrap.js"
if bootstrap.exists():
    data = bootstrap.read_text(encoding="utf-8")
    data = re.sub(r'serviceWorkerVersion:\s*"\d+"', 'serviceWorkerVersion: "0"', data)
    bootstrap.write_text(data, encoding="utf-8")
PY

rm -f "${OUTPUT_DIR}/.last_build_id"
