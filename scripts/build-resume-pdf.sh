#!/usr/bin/env bash
# Render cv-src/christopher-wright-resume.html to public/cv/christopher-wright-resume.pdf
# using headless Chrome. System fonts only; no network access required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/cv-src/christopher-wright-resume.html"
OUT="$ROOT/public/cv/christopher-wright-resume.pdf"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

[ -x "$CHROME" ] || { echo "Chrome not found at: $CHROME (set CHROME=...)" >&2; exit 1; }

PROFILE="$(mktemp -d)"
trap 'rm -rf "$PROFILE"' EXIT
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"

"$CHROME" --headless --disable-gpu --no-sandbox \
  --user-data-dir="$PROFILE" \
  --no-pdf-header-footer \
  --virtual-time-budget=15000 \
  --print-to-pdf="$OUT" \
  "file://$SRC" >/dev/null 2>&1 &
PID=$!

# Chrome writes the PDF and then sometimes fails to exit; stop it once the file lands.
for _ in $(seq 1 60); do
  [ -s "$OUT" ] && break
  sleep 1
done
sleep 1
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true

[ -s "$OUT" ] || { echo "PDF was not produced" >&2; exit 1; }
echo "wrote $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"
