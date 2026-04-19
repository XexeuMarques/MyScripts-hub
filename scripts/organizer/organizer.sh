#!/usr/bin/env bash
# organizer.sh - Motor de Organização de Arquivos

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Se não encontrar as bibs, usa fallback de terminal limpo para evitar crachar logo de cara
if [[ -f "${ROOT_DIR}/lib/log.sh" && -f "${ROOT_DIR}/lib/ui.sh" ]]; then
    source "${ROOT_DIR}/lib/log.sh"
    source "${ROOT_DIR}/lib/ui.sh"
else
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_err() { echo "[ERRO] $1" >&2; }
    ui_print_header() { echo "=== $1 ==="; }
fi

if [[ -f "${MOD_DIR}/lib.sh" ]]; then
    source "${MOD_DIR}/lib.sh"
else
    log_err "lib.sh não encontrado no diretório do módulo."
    exit 1
fi

# Globals
DRY_RUN=false
RECURSIVE=false
FLATTEN=false
PRESERVE=false
INTERACTIVE=false
ADVANCED_GUI=false

TARGET_DIR=""

declare -A ARR_RULES
declare -A ARR_IGNORES

print_usage() {
    echo "Uso: organizer [OPÇÕES] <DIRETORIO>"
    echo "Opções:"
    echo "  -n, --dry-run      Apenas mostra o que será feito"
    echo "  -r, --recursive    Percorre subpastas. (Requer --flatten ou --preserve-tree)"
    echo "      --flatten      Ignora a estrutura original"
    echo "      --preserve-tree Mantém a hierarquia relativa dentro da pasta final"
    echo "  -i <pasta>         Ignora folder específico via CLI"
    echo "  --advanced-gui     Abre kdialog para selecionar opções (para KDE desktop)"
    echo "  --interactive      Roda como menu de terminal"
    exit 1
}

# Parse Args
CLI_IGNORES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=true; shift ;;
        -r|--recursive) RECURSIVE=true; shift ;;
        --flatten) FLATTEN=true; shift ;;
        --preserve-tree) PRESERVE=true; shift ;;
        -i) CLI_IGNORES+=("$2"); shift 2 ;;
        --advanced-gui) ADVANCED_GUI=true; shift ;;
        --interactive) INTERACTIVE=true; shift ;;
        -*) echo "Opção inválida: $1"; print_usage ;;
        *) 
            if [[ -z "$TARGET_DIR" ]]; then
                TARGET_DIR="$1"
            else
                log_err "Múltiplos diretórios de origem não suportados. Processando apenas o primeiro."
                exit 1
            fi
            shift 
            ;;
    esac
done

if [[ "$INTERACTIVE" == true && -z "$TARGET_DIR" ]]; then
    clear
    ui_print_header "Organizador de Pastas"
    echo -n "Digite o caminho absoluto da pasta a organizar (ou deixe em branco para a pasta atual): "
    read -r t_dir
    [[ -n "$t_dir" ]] && TARGET_DIR="$t_dir"
fi

if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR="$PWD"
fi

# Valida target dirs
if [[ ! -d "$TARGET_DIR" ]]; then
    log_err "Diretório alvo não existe: $TARGET_DIR"
    exit 1
fi

# Absolute path do target:
TARGET_DIR=$(realpath "$TARGET_DIR")

# Tratamento especial pra ADVANCED_GUI do KDE Plasma kdialog
if [[ "$ADVANCED_GUI" == true ]]; then
    # Invoca lib_kdialog pra pegar as flags do checkbox
    opts_str=$(ask_kdialog_options "$TARGET_DIR")
    if [[ "$opts_str" == "CANCELED" ]]; then
        log_info "Cancelado pelo usuário no KDE Dialog."
        exit 0
    fi
    
    # Processa as aspas do retorno ex: "dry-run" "recursive" "flatten"
    [[ $opts_str =~ "dry-run" ]] && DRY_RUN=true
    [[ $opts_str =~ "recursive" ]] && RECURSIVE=true
    [[ $opts_str =~ "flatten" ]] && FLATTEN=true
    [[ $opts_str =~ "preserve" ]] && PRESERVE=true
fi

# Valida regras de recursividade da tool
if [[ "$RECURSIVE" == true ]]; then
    if [[ "$FLATTEN" == false && "$PRESERVE" == false ]]; then
        if [[ "$ADVANCED_GUI" == true ]]; then
            kdialog --error "Modo recursivo (-r) requer seleção de --flatten ou --preserve-tree."
            exit 1
        fi
        log_err "Modo recursivo (-r) exige passagem de --flatten ou --preserve-tree."
        exit 1
    fi
    if [[ "$FLATTEN" == true && "$PRESERVE" == true ]]; then
        log_err "Não é possível usar --flatten e --preserve-tree juntos."
        exit 1
    fi
fi

if [[ "$DRY_RUN" == true ]]; then
    log_info "Executando em modo DRY-RUN. Nenhuma alteração real será feita."
fi

# ================================
# CARREGA CONFIGURAÇÕES DE EXTENSÕES
# ================================

GLOBAL_CONF="${HOME}/.config/.organizador.conf"
LOCAL_CONF="${TARGET_DIR}/.organizador.conf"

if [[ -f "$LOCAL_CONF" ]]; then
    log_info "Encontrado .organizador.conf local, priorizando-o."
    parse_config "$LOCAL_CONF"
elif [[ -f "$GLOBAL_CONF" ]]; then
    parse_config "$GLOBAL_CONF"
else
    # Fallback config
    parse_config "${MOD_DIR}/config.conf"
    log_warn "Arquivo de configuração não encontrado em ${HOME}/.config/.organizador.conf. Usando defaults nativos do módulo."
fi

# ================================
# CONFIGURA IGNORADOS PARA SEGURANÇA
# ================================

generate_default_ignore "$TARGET_DIR"
load_ignores "$TARGET_DIR"
setup_security_ignores

for cig in "${CLI_IGNORES[@]}"; do
    ARR_IGNORES["$cig"]=1
done

# ================================
# MOTOR DE VERIFICAÇÃO E HASHING
# ================================

get_hash() {
    local file="$1"
    sha256sum "$file" | awk '{print $1}'
}

is_ignored() {
    local f_path="$1"
    local base_name="$(basename "$f_path")"
    
    # Ignora arquivos ocultos sempre
    if [[ "$base_name" == .* && -f "$f_path" && ! -L "$f_path" ]]; then
        return 0 # ignored
    fi
    
    # Verifica contra o arquivo gerado via gitignore mode
    if [[ -n "${ARR_IGNORES[$base_name]+isset}" ]]; then
        return 0 # ignored
    fi
    
    # Segurança adicional de nunca mexer no próprio path principal se bater conflitos de root path
    if [[ "$f_path" == "${ROOT_DIR}" || "$f_path" == "${MOD_DIR}"* ]]; then
        return 0
    fi
    
    return 1 # not ignored
}

get_category() {
    local file="$1"
    local basename_f="$(basename "$file")"
    
    # Tratamento case-insensitive da extensão a partir do tolower (,,) do bash expansão de parâmetro
    if [[ "$basename_f" == *.* ]]; then
        local ext="${basename_f##*.}"
        ext="${ext,,}" 
        if [[ -n "${ARR_RULES[$ext]+isset}" ]]; then
            echo "${ARR_RULES[$ext]}"
            return
        fi
    fi
    
    # MIME Fallback se for noext ou ext não registrada (file --mime-type é padrão unix linux)
    local mime
    mime=$(file -b --mime-type "$file")
    
    if [[ "$mime" == image/* ]]; then echo "Imagens"; return; fi
    if [[ "$mime" == video/* ]]; then echo "Videos"; return; fi
    if [[ "$mime" == text/* ]]; then echo "Documentos"; return; fi
    if [[ "$mime" == application/pdf ]]; then echo "Documentos"; return; fi
    if [[ "$mime" == application/zip || "$mime" == application/x-tar || "$mime" == application/gzip || "$mime" == application/x-xz ]]; then echo "Arquivos_Compactados"; return; fi
    if [[ "$mime" == audio/* ]]; then echo "Audio"; return; fi
    if [[ "$mime" == application/x-executable || "$mime" == application/x-sharedlib ]]; then echo "Executaveis"; return; fi

    echo "Outros"
}

move_file() {
    local f_source="$1"
    local tgt_folder_name="$2"
    local f_base="$(basename "$f_source")"
    local dest_dir=""
    
    # Decide a pasta de destino considerando a árvore estrutural (se vai ser recriada ou se vai ignorar tudo para 1 nivel só)
    if [[ "$RECURSIVE" == true && "$PRESERVE" == true ]]; then
        local rel_dir="${f_source%/*}"
        rel_dir="${rel_dir#"$TARGET_DIR"}"
        
        # O rel_dir pode ser vazio se estiver no diretório raiz do target inicial
        dest_dir="${TARGET_DIR}/${tgt_folder_name}${rel_dir}"
    else
        dest_dir="${TARGET_DIR}/${tgt_folder_name}"
    fi

    if [[ "$f_source" == "${dest_dir}/${f_base}" ]]; then
        return
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$dest_dir"
    fi

    local final_dest="${dest_dir}/${f_base}"
    
    # Resolução de colisões de NOMES nos targets
    if [[ -e "$final_dest" ]]; then
        # Check por arquivos bytes size duplicados primeiro
        local size_s=$(stat -c%s "$f_source")
        local size_d=$(stat -c%s "$final_dest")
        
        if [[ "$size_s" == "$size_d" ]]; then
            # Bate SHA256 para dupla confirmação de file clone antes de jogar em Duplicados
            local hash_s=$(get_hash "$f_source")
            local hash_d=$(get_hash "$final_dest")
            if [[ "$hash_s" == "$hash_d" ]]; then
                dest_dir="${TARGET_DIR}/Duplicados"
                if [[ "$DRY_RUN" == false ]]; then mkdir -p "$dest_dir"; fi
                final_dest="${dest_dir}/${f_base}"
            fi
        fi

        # Modifica sufixo numerico se DEPOIS da decisão ainda colidir (Seja original ou na pasta duplicados)
        if [[ -e "$final_dest" ]]; then
            local ext="${f_base##*.}"
            local base_no_ext="${f_base%.*}"
            if [[ "$f_base" == "$ext" || "$f_base" == *[^.] ]]; then
                if [[ ! "$f_base" == *.* ]]; then
                  base_no_ext="$f_base"
                  ext=""
                else
                  ext=".$ext"
                fi
            else
                ext=".$ext"
            fi
            
            local idx=1
            while [[ -e "${dest_dir}/${base_no_ext}_${idx}${ext}" ]]; do
                ((idx++))
            done
            final_dest="${dest_dir}/${base_no_ext}_${idx}${ext}"
        fi
    fi

    # Efetua manipulação real ou log de simulação
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "[DRY-RUN] > '${f_source}' >>> '${final_dest}'"
    else
        mv "$f_source" "$final_dest"
        log_info "Movido com sucesso: '${f_base}' -> '${final_dest}'"
    fi
}

process_directory() {
    local cur_dir="$1"
    
    local items
    # Usando maxdepth 1 evita estourar RAM com for files. Processa um layer de cada vez como tree branch
    mapfile -d $'\0' items < <(find "$cur_dir" -mindepth 1 -maxdepth 1 -print0)
    
    for item in "${items[@]}"; do
        if is_ignored "$item"; then
            continue
        fi

        if [[ -d "$item" ]]; then
            # Encontrou Diretório / Folder
            
            if [[ "$RECURSIVE" == true ]]; then
                # Proteção para não re-scanear nossas próprias pastas destinadas no root (apenas scan se preserve tree estiver rolando ou flatten e não for uma categoria original que possivelmente já geramos)
                local skip_category=false
                local basename_dir="$(basename "$item")"
                
                # Se estamos na base root dir e encontramos as pastas já criadas tipo "Documentos", "Imagens" ...
                # e não queremos loopar as moves
                if [[ "$cur_dir" == "$TARGET_DIR" ]]; then
                    for cat_rule in "${ARR_RULES[@]}"; do
                        if [[ "$basename_dir" == "$cat_rule" || "$basename_dir" == "Outros" || "$basename_dir" == "Duplicados" || "$basename_dir" == "Documentos" ]]; then
                            skip_category=true
                            break
                        fi
                    done
                fi

                if [[ "$skip_category" == true ]]; then
                    continue
                fi

                # Call internal depth loop
                process_directory "$item"
                
                # Exclui seccionando empty folders no nivel final quando operando Flatten (evitar diretorios fanstasma perdidos)
                if [[ "$FLATTEN" == true && "$DRY_RUN" == false ]]; then
                    # 2>/dev/null omite "Directory not empty"
                    rmdir "$item" 2>/dev/null || true
                fi
            fi
        elif [[ -f "$item" ]]; then
            # Processa e engloba moves em arquivos nativos
            local category=$(get_category "$item")
            move_file "$item" "$category"
        fi
    done
}

# START LOGIC DA MAIN SCRIPT
log_info "Iniciando processo principal Organizer..."
echo -e "${CYAN}Alvo:${RESET} ${TARGET_DIR}"

process_directory "$TARGET_DIR"

if [[ "$DRY_RUN" == true ]]; then
    ui_print_header "Dry-Run Completo"
    log_info "Simulação Concluída."
else
    log_success "Organização em ${TARGET_DIR} finalizada."
fi

# Popup KDE de conclusão quando solicitado via Dolphin Right click context menu actions
if [[ "$ADVANCED_GUI" == true && "$DRY_RUN" == false ]]; then
    kdialog --title "Organizador de Pastas" --msgbox "Organização concluída com sucesso em:\n$TARGET_DIR"
fi

if [[ "$ADVANCED_GUI" == true && "$DRY_RUN" == true ]]; then
    kdialog --title "Organizador de Pastas" --msgbox "Verifique o console para ver a simulação.\nDry-run concluído em:\n$TARGET_DIR"
fi
