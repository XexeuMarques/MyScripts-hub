#!/usr/bin/env bash
# lib.sh - Funções do módulo Organizer

# Lê o config e popula um array associativo (Extensões em minúsculo já no hash para validação rápida)
# Variável global: declare -A ARR_RULES
parse_config() {
    local conf_file="$1"
    
    if [[ ! -f "$conf_file" ]]; then
        return
    fi
    
    # Processa linha por linha usando regex para evitar vulnerabilidade de `source` direto
    # [Categoria]="extensao1 extensao2"
    while IFS= read -r line; do
        # Pula comentários e vazios
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        # O bash precisa capturar [Categoria] e a string "ext..."
        if [[ "$line" =~ ^\[(.+)\]=\"(.*)\"$ ]]; then
            local category="${BASH_REMATCH[1]}"
            local exts_str="${BASH_REMATCH[2]}"
            
            # Adiciona para cada extensão
            for ext in $exts_str; do
                ARR_RULES["$(echo "$ext" | tr '[:upper:]' '[:lower:]')"]="$category"
            done
        fi
    done < "$conf_file"
}

# Retorna uma array de ignores
generate_default_ignore() {
    local target_dir="$1"
    local ign_file="${target_dir}/.organizadorignore"
    
    if [[ ! -f "$ign_file" ]]; then
        cat << 'EOF' > "$ign_file"
# .organizadorignore - Arquivo de ignorados
# Linhas configuradas para ignorar pastas essenciais por padrão
# Linhas comentadas ou em branco são ignoradas por este script
node_modules
.git
build
venv
.venv
EOF
    fi
}

load_ignores() {
    local target_dir="$1"
    local ign_file="${target_dir}/.organizadorignore"
    
    if [[ -f "$ign_file" ]]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$line" ]] && continue
            # Remove barra no final se tiver para uniformizar
            local sanitized="${line%/}"
            ARR_IGNORES["$sanitized"]=1
        done < "$ign_file"
    fi
}

# Exclui o script (se rodando do dir), os configs e outros internos
setup_security_ignores() {
    ARR_IGNORES[".organizadorignore"]=1
    ARR_IGNORES[".organizador.conf"]=1
    # Ignora a si mesmo (se estiver na pasta)
    ARR_IGNORES["organizer.sh"]=1
}

ask_kdialog_options() {
    local target_dir="$1"
    
    # Executa KDialog com checklist
    # Retorna uma string com as tags ativadas
    
    local OPTS
    OPTS=$(kdialog --title "Organizador de Pastas" \
        --checklist "Escolha as opções de organização para:\n$(basename "$target_dir")" \
        "dry-run" "Testar sem modificar arquivos (Dry-Run)" off \
        "recursive" "Buscar arquivos em Subpastas" off \
        "flatten" "Acompanha o Recursivo: Trazer tudo para o nível 0 (destrói subpastas vazias)" off \
        "preserve" "Acompanha o Recursivo: Preservar hierarquia de pastas relativa" off )
        
    local exit_status=$?
    if [[ $exit_status -ne 0 ]]; then
        echo "CANCELED"
        return
    fi
    # O output do kdialog vem com aspas: "dry-run" "recursive" "flatten"
    echo "$OPTS"
}
