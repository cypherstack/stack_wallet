#!/usr/bin/env bash
# render.sh: Convert benchmark markdown report to HTML + PDF
# Usage:
#   ./bm/compare.py bm/results/ > report.md
#   ./bm/render.sh report.md [--open]
set -euo pipefail

MD_FILE="${1:-}"
if [ -z "$MD_FILE" ] || [ ! -f "$MD_FILE" ]; then
  echo "Usage: ./bm/render.sh <report.md> [--open]"
  exit 1
fi

OPEN=0
[ "${2:-}" = "--open" ] && OPEN=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="${MD_FILE%.md}"
HTML_FILE="${BASE}.html"
PDF_FILE="${BASE}.pdf"
CSS_FILE="$SCRIPT_DIR/report.css"

# Convert to HTML
echo "=== Markdown → HTML ==="
{
  echo '<style>'
  cat "$CSS_FILE"
  echo '</style>'
} > /tmp/_bm_css.html

pandoc "$MD_FILE" \
  --standalone \
  --metadata title="Stack Wallet: Build Benchmark Report" \
  --include-in-header /tmp/_bm_css.html \
  -o "$HTML_FILE"
rm -f /tmp/_bm_css.html
echo "  → $HTML_FILE"

# Convert to PDF
echo "=== HTML → PDF ==="
pdf_ok=0

if command -v weasyprint >/dev/null 2>&1; then
  weasyprint "$HTML_FILE" "$PDF_FILE" 2>/dev/null && pdf_ok=1
elif pip3 install --break-system-packages weasyprint 2>/dev/null; then
  weasyprint "$HTML_FILE" "$PDF_FILE" 2>/dev/null && pdf_ok=1
elif command -v wkhtmltopdf >/dev/null 2>&1; then
  wkhtmltopdf --enable-local-file-access "$HTML_FILE" "$PDF_FILE" 2>/dev/null && pdf_ok=1
elif [ "$(uname -s)" = "Darwin" ]; then
  cupsfilter "$HTML_FILE" > "$PDF_FILE" 2>/dev/null && pdf_ok=1 || true
fi

if [ "$pdf_ok" -eq 1 ] && [ -f "$PDF_FILE" ]; then
  echo "  → $PDF_FILE"
else
  echo "  ⚠ No PDF engine found. HTML ready: $HTML_FILE"
fi

[ "$OPEN" -eq 1 ] && open "$PDF_FILE" 2>/dev/null || open "$HTML_FILE" 2>/dev/null || true

echo "Done."