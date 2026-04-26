#!/usr/bin/env bash
# uninstall.sh - Desinstalador do Módulo Media Converter

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
KIO_DIR="${HOME}/.local/share/kio/servicemenus"

echo "Removendo binário..."
rm -f "${BIN_DIR}/media_converter"

echo "Removendo Service Menus..."
rm -f "${KIO_DIR}/mc-ebook_converter.desktop"
rm -f "${KIO_DIR}/mc-video_converter.desktop"
rm -f "${KIO_DIR}/mc-image_converter.desktop"

echo "Nota: O arquivo de configuração em ~/.config/.media_converter.conf foi mantido por precaução."
echo "Desinstalação concluída."
