#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="${1:-docs}"
OUT_DIR="${2:-build}"
PDF_DIR="$OUT_DIR/pdf"
DOCX_DIR="$OUT_DIR/docx"
HTML_DIR="$OUT_DIR/html"

echo "🧹 Limpando saídas antigas..."
rm -rf "$OUT_DIR"
mkdir -p "$PDF_DIR" "$DOCX_DIR" "$HTML_DIR"

echo "🔎 Procurando arquivos .md em: $SRC_DIR"
mapfile -t FILES < <(find "$SRC_DIR" -type f -name "*.md" | sort)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "⚠️ Nenhum .md encontrado em $SRC_DIR"
  exit 0
fi

# Metadados padrão se faltar título
META_COMMON=( --metadata=lang=pt-BR --standalone )

for f in "${FILES[@]}"; do
  rel="${f#$SRC_DIR/}"
  base="${rel%.md}"

  mkdir -p "$(dirname "$PDF_DIR/$base")" \
           "$(dirname "$DOCX_DIR/$base")" \
           "$(dirname "$HTML_DIR/$base")"

  title_guess=$(head -n 1 "$f" | sed 's/^#\s*//')
  if [[ -z "$title_guess" ]]; then
    title_guess="$(basename "$base")"
  fi

  echo "📄 Convertendo: $f"

  # HTML
  pandoc "$f" "${META_COMMON[@]}" --metadata=title="$title_guess" \
    -o "$HTML_DIR/$base.html"

  # DOCX
  pandoc "$f" "${META_COMMON[@]}" --metadata=title="$title_guess" \
    -o "$DOCX_DIR/$base.docx"

  # PDF via wkhtmltopdf
  pandoc "$f" "${META_COMMON[@]}" --metadata=title="$title_guess" \
    --to html5 -o "$HTML_DIR/$base.__tmp.html"

  wkhtmltopdf "$HTML_DIR/$base.__tmp.html" "$PDF_DIR/$base.pdf"
  rm -f "$HTML_DIR/$base.__tmp.html"
done

echo "✅ Conclusão: $OUT_DIR gerado."
