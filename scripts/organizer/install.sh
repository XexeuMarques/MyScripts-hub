#!/usr/bin/env bash
# install.sh - Instalador do Módulo Organizer

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${ROOT_DIR}/lib/log.sh"

log_info "Verificando dependências..."
deps=("kdialog" "file" "sha256sum" "jq")
for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_err "Dependência '${cmd}' não encontrada. Instale via pacman: sudo pacman -S ${cmd}"
        exit 1
    fi
done

BIN_DIR="${HOME}/.local/bin"
KIO_DIR="${HOME}/.local/share/kio/servicemenus"
CONF_DIR="${HOME}/.config"

mkdir -p "$BIN_DIR"
mkdir -p "$KIO_DIR"
mkdir -p "$CONF_DIR"

log_info "Instalando binário principal..."
chmod +x "${MOD_DIR}/organizer.sh"
# Cria ou atualiza symlink
ln -sf "${MOD_DIR}/organizer.sh" "${BIN_DIR}/organizer"

log_info "Copiando config padrão se não existir..."
if [[ ! -f "${CONF_DIR}/.organizador.conf" ]]; then
    cp "${MOD_DIR}/config.conf" "${CONF_DIR}/.organizador.conf"
    log_success "Criado ${CONF_DIR}/.organizador.conf"
fi

log_info "Gerando Service Menu..."
# Lê o template e substitui a variável _EXECUTABLE_
sed "s|_EXECUTABLE_|${BIN_DIR}/organizer|g" "${MOD_DIR}/service-menu.desktop" > "${KIO_DIR}/organizer-service-menu.desktop"

# Para dar update no cache do KDE ServiceMenus, mas geralmente é automático no Plasma 6
# kbuildsycoca6 &>/dev/null || true

log_success "Instalação do Organizer concluída com sucesso!"
