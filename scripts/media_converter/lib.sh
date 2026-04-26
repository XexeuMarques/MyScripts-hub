#!/usr/bin/env bash
# lib.sh - Funções auxiliares para realizar conversões

# Retorna sucesso ou erro baseando-se no exit code do ffmpeg
convert_with_ffmpeg() {
    local input="$1"
    local output="$2"
    local extra_args="${3:-}"

    # O overwrite (-y para overwrite ou -n para não overwrite) será resolvido no script wrapper
    # Se extra_args estiver vazio passa a flag apropriada se necessário ou é tratado antes.
    
    # Separando argumentos para não ter problema com espaçamento
    # shellcheck disable=SC2086
    if ffmpeg -v warning -i "${input}" $extra_args "${output}"; then
        return 0
    else
        return 1
    fi
}

convert_with_calibre() {
    local input="$1"
    local output="$2"
    local extra_args="${3:-}"

    # shellcheck disable=SC2086
    if ebook-convert "${input}" "${output}" $extra_args > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Funções da interface (kdialog)
show_error() {
    local msg="$1"
    kdialog --error "${msg}" --title "Media Converter Error" || echo "[ERROR] ${msg}" >&2
}

show_success() {
    local msg="$1"
    # Notificação passiva
    kdialog --passivepopup "${msg}" 5 --title "Media Converter Success" || echo "[SUCCESS] ${msg}"
}
