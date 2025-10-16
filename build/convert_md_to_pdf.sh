#!/bin/bash
# ------------------------------------------------------------
# Script: convert_md_to_pdf.sh
# Versão: 3.1 (wkhtmltopdf + images + titles)
# ------------------------------------------------------------

set -euo pipefail

BASE_DIR="$(pwd)"
BUILD_DIR="$BASE_DIR/build/pdf"

# Ajuste aqui pastas extras onde você guarda imagens usadas nos .md
EXTRA_RESOURCE_DIRS=(
  "$BASE_DIR"
  "$BASE_DIR/Imagens"
  "$HOME/Projetos/SENAC/Imagens"
)

# Monta resource-path do Pandoc (separado por dois-pontos)
RESOURCE_PATH="$(IFS=':'; echo "${EXTRA_RESOURCE_DIRS[*]}")"

echo "🔍 Verificando dependências..."
for cmd in pandoc wkhtmltopdf; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Falta '$cmd'. Instale com: sudo apt install $cmd -y"
    exit 1
  fi
done

echo "🧹 Limpando PDFs antigos..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "📁 Procurando arquivos Markdown em: $BASE_DIR"
mapfile -t MD_FILES < <(find "$BASE_DIR" -type f -name "*.md" | sort)

if [ "${#MD_FILES[@]}" -eq 0 ]; then
  echo "❌ Nenhum arquivo .md encontrado."
  exit 1
fi

convert_one() {
  local FILE="$1"
  local REL_PATH="${FILE#$BASE_DIR/}"
  local OUT_FILE="$BUILD_DIR/${REL_PATH%.md}.pdf"
  local OUT_DIR
  OUT_DIR="$(dirname "$OUT_FILE")"
  mkdir -p "$OUT_DIR"

  # Título: usa o cabeçalho H1 se existir; senão, nome do arquivo
  local TITLE
  TITLE="$(grep -m1 '^# ' "$FILE" | sed 's/^# \+//')"
  if [ -z "${TITLE:-}" ]; then
    TITLE="$(basename "${FILE%.*}")"
  fi

  echo "📄 Convertendo: $REL_PATH → $OUT_FILE"
  if pandoc "$FILE" \
      -f markdown -t html -s \
      --pdf-engine=wkhtmltopdf \
      --pdf-engine-opt=--enable-local-file-access \
      --resource-path="$RESOURCE_PATH" \
      --metadata title="$TITLE" \
      -V geometry:margin=2cm \
      -V fontsize=11pt \
      -o "$OUT_FILE"; then
    echo "✅ Gerado com sucesso: $OUT_FILE"
  else
    echo "⚠️  Erro ao converter: $FILE"
  fi
}

# Converte em série (se quiser paralelizar, use xargs -P)
for f in "${MD_FILES[@]}"; do
  convert_one "$f"
done

echo
echo "🎉 Conversão concluída!"
echo "📚 PDFs em: $BUILD_DIR"
echo "------------------------------------------------------------"
