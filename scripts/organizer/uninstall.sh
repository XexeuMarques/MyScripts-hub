#!/usr/bin/env bash
# uninstall.sh - Desinstalador do Organizador

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/lib/log.sh"

BIN_DIR="${HOME}/.local/bin"
KIO_DIR="${HOME}/.local/share/kio/servicemenus"

log_info "Removendo links..."
rm -f "${BIN_DIR}/organizer"
rm -f "${KIO_DIR}/organizer-service-menu.desktop"

log_success "Desinstalação do Organizer concluída!"
