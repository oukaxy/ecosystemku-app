#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
src="$root/assistant/characters/rem"
dst="$root/app/assets/live2d/rem"

if [ ! -f "$src/Character.model3.json" ]; then
  echo "Live2D source not found: $src" >&2
  exit 1
fi

rm -rf "$dst"
mkdir -p "$dst"
cp -R "$src"/. "$dst"/

(
  cd "$dst"
  find . -type f ! -name 'checksums.sha256' -print | sort | while read -r file; do
    sha256sum "$file"
  done
) > "$dst/checksums.sha256"

echo "Synced Live2D model to $dst"
