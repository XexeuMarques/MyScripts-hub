#!/usr/bin/env bash
# ui.sh - Funções para a Interface do Usuário (Menus, Prompts)

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

ui_print_header() {
    local title="$1"
    echo -e "\n${CYAN}${BOLD}=== $title ===${RESET}\n"
}

ui_prompt_confirm() {
    local msg="$1"
    while true; do
        echo -e -n "${YELLOW}${BOLD}?${RESET} ${msg} [y/N]: "
        read -r yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* | "" ) return 1;;
            * ) echo "Responda 'y' para sim ou 'n' para não.";;
        esac
    done
}
