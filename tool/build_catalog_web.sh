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
rm -f "${OUTPUT_DIR}/.last_build_id"
