#!/usr/bin/env bash
# install.sh - Instalador do Módulo Media Converter

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Como esse é um hub interligado, os lib globals estão em /lib/
if [[ -f "${ROOT_DIR}/lib/log.sh" ]]; then
    source "${ROOT_DIR}/lib/log.sh"
else
    # Fallback se log.sh não existir
    log_info() { echo "[INFO] $*"; }
    log_err() { echo "[ERROR] $*" >&2; }
    log_success() { echo "[SUCCESS] $*"; }
fi

log_info "Verificando dependências..."
deps=("kdialog" "ffmpeg")
for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_err "Dependência crítica '${cmd}' não encontrada. (Instale via pacman)"
        exit 1
    fi
done

if ! command -v "ebook-convert" >/dev/null 2>&1; then
    log_info "Aviso: 'ebook-convert' (calibre) não encontrado. A conversão de Ebooks não funcionará."
fi

BIN_DIR="${HOME}/.local/bin"
KIO_DIR="${HOME}/.local/share/kio/servicemenus"
CONF_DIR="${HOME}/.config"

mkdir -p "$BIN_DIR"
mkdir -p "$KIO_DIR"
mkdir -p "$CONF_DIR"

log_info "Instalando binário principal..."
chmod +x "${MOD_DIR}/media_converter.sh"
ln -sf "${MOD_DIR}/media_converter.sh" "${BIN_DIR}/media_converter"

log_info "Copiando config padrão se não existir..."
if [[ ! -f "${CONF_DIR}/.media_converter.conf" ]]; then
    cp "${MOD_DIR}/config.conf" "${CONF_DIR}/.media_converter.conf"
    log_success "Criado ${CONF_DIR}/.media_converter.conf"
fi

log_info "Gerando Service Menus (KDE)..."
# Copia as templates e ajusta os caminhos
for desktop_file in "${MOD_DIR}/service_menus/"*.desktop; do
    if [[ -f "$desktop_file" ]]; then
        fname=$(basename "$desktop_file")
        sed "s|_EXECUTABLE_|${BIN_DIR}/media_converter|g" "$desktop_file" > "${KIO_DIR}/mc-${fname}"
        chmod +x "${KIO_DIR}/mc-${fname}"
        log_success "Instalado: ${fname}"
    fi
done

# kbuildsycoca6 &>/dev/null || true

log_success "Instalação do Media Converter concluída com sucesso!"
