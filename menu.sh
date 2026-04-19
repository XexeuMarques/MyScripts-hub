#!/usr/bin/env bash
# menu.sh - Menu Principal e Hub de Scripts

set -euo pipefail

# Diretório base
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${ROOT_DIR}/scripts"

# Import de funções lib (Cores e Logger estão aqui)
source "${ROOT_DIR}/lib/log.sh"
source "${ROOT_DIR}/lib/ui.sh"

# Lista de módulos disponíveis
listar_modulos() {
    if [[ -d "${SCRIPTS_DIR}" ]]; then
        for dir in "${SCRIPTS_DIR}"/*/; do
            if [[ -f "${dir}manifest.conf" ]]; then
                # Lê o nome do script pelo manifest usando bash regex ou source simples
                local mod_name=$(grep "^NAME=" "${dir}manifest.conf" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
                local mod_dir=$(basename "$dir")
                echo "${mod_name}:${mod_dir}"
            fi
        done
    fi
}

menu_principal() {
    while true; do
        clear
        echo -e "\n${BLUE}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BLUE}${BOLD}║              ${CYAN}✨ Hub de Scripts CLI ✨${BLUE}                ║${RESET}"
        echo -e "${BLUE}${BOLD}║              ${YELLOW}KDE Plasma ∘ Arch Linux${BLUE}                ║${RESET}"
        echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"
        
        echo -e "${BOLD} 📌 Módulos Disponíveis:${RESET}\n"
        
        # Obter módulos numa array bash
        mapfile -t modulos < <(listar_modulos)
        
        if [[ ${#modulos[@]} -eq 0 ]]; then
            echo -e "    ${YELLOW}Nenhum módulo encontrado em ${SCRIPTS_DIR}${RESET}"
        else
            for i in "${!modulos[@]}"; do
                local name="${modulos[$i]%%:*}"
                echo -e "  $((i+1))) ${CYAN}📦 ${name}${RESET}"
            done
        fi
        
        echo -e "\n  0) ${RED}🚪 Sair${RESET}\n"
        
        echo -n -e "${YELLOW}❯${RESET} Escolha uma opção: "
        read -r opc_mod

        if [[ "$opc_mod" == "0" ]]; then
            echo -e "\n${GREEN}Até logo! 👋${RESET}\n"
            exit 0
        elif [[ "$opc_mod" =~ ^[0-9]+$ ]] && [[ "$opc_mod" -gt 0 ]] && [[ "$opc_mod" -le ${#modulos[@]} ]]; then
            local idx=$((opc_mod-1))
            local selected_dir="${modulos[$idx]##*:}"
            local selected_name="${modulos[$idx]%%:*}"
            menu_acoes_modulo "${selected_dir}" "${selected_name}"
        else
            echo -e "\n  ${RED}❌ Opção inválida.${RESET}"
            sleep 1
        fi
    done
}

menu_acoes_modulo() {
    local m_dir="$1"
    local m_name="$2"
    local path="${SCRIPTS_DIR}/${m_dir}"

    while true; do
        clear
        echo -e "\n${CYAN}╭───────────────────────────────────────────────────╮${RESET}"
        echo -e "${CYAN}│  ${BOLD}Módulo:${RESET} ${YELLOW}${m_name}                                "
        echo -e "${CYAN}╰───────────────────────────────────────────────────╯${RESET}\n"
        
        echo -e "  1) 🚀 Executar / Organizar (CLI via Terminal)"
        echo -e "  2) ⚙️  Instalar (Integrações e Atalhos no Sistema)"
        echo -e "  3) 🗑️  Desinstalar (Arquivos .desktop e binds)"
        echo -e "\n  0) ⬅️  Voltar"
        echo ""
        echo -n -e "${YELLOW}❯${RESET} O que deseja fazer? "
        read -r ax

        case $ax in
            1) 
                if [[ -x "${path}/${m_dir}.sh" ]]; then
                    # Executa interativamente 
                    echo -e "\n${BOLD}--- Executando ${m_name} ---${RESET}"
                    "${path}/${m_dir}.sh" --interactive || true
                    echo -e "\n${BOLD}Pressione [ENTER] para continuar...${RESET}"
                    read -r
                else
                    log_err "Executável principal não encontrado ou sem permissão de execução: ${m_dir}.sh"
                    sleep 2
                fi
                ;;
            2)
                if [[ -x "${path}/install.sh" ]]; then
                    echo -e "\n${BOLD}--- Instalando ${m_name} ---${RESET}"
                    "${path}/install.sh"
                    echo -e "\n${BOLD}Pressione [ENTER] para continuar...${RESET}"
                    read -r
                else
                    log_err "Script de instalação ausente: install.sh"
                    sleep 2
                fi
                ;;
            3)
                if [[ -x "${path}/uninstall.sh" ]]; then
                    if ui_prompt_confirm "Tem certeza que deseja desinstalar este módulo?"; then
                        "${path}/uninstall.sh"
                        echo -e "\n${BOLD}Pressione [ENTER] para continuar...${RESET}"
                        read -r
                    fi
                else
                    log_err "Script de desinstalação ausente: uninstall.sh"
                    sleep 2
                fi
                ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida.${RESET}"; sleep 1 ;;
        esac
    done
}

# Inicializa o script e o log
mkdir -p "${LOG_DIR}"
log_info "Hub de Scripts iniciado."
menu_principal
