#!/usr/bin/env bash
# log.sh - Funções de Logging e Cores para o terminal

# Cores ANSI
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'
BOLD='\e[1m'
RESET='\e[0m'

LOG_DIR="${HOME}/.local/share/meus-scripts/logs"

# Inicializa diretório de log
mkdir -p "${LOG_DIR}"

log_info() {
    local msg="$1"
    echo -e "${BLUE}${BOLD}[INFO]${RESET} ${msg}"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - ${msg}" >> "${LOG_DIR}/hub.log"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}${BOLD}[SUCESSO]${RESET} ${msg}"
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - ${msg}" >> "${LOG_DIR}/hub.log"
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}${BOLD}[AVISO]${RESET} ${msg}"
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - ${msg}" >> "${LOG_DIR}/hub.log"
}

log_err() {
    local msg="$1"
    echo -e "${RED}${BOLD}[ERRO]${RESET} ${msg}" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - ${msg}" >> "${LOG_DIR}/hub.log"
}
