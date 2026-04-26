#!/usr/bin/env bash
# media_converter.sh - CLI & GUI Entrypoint para conversão unificada.
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

# --- Carregar Configurações ---
CONFIG_FILE="${HOME}/.config/.media_converter.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
elif [[ -f "${SCRIPT_DIR}/config.conf" ]]; then
    # Fallback pro config default que fica na pasta
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/config.conf"
else
    # Configs default fail-safe
    OVERWRITE_EXISTING=false
    DELETE_ORIGINAL=false
    AUDIO_QUAL="192k"
    EBOOK_EXTRA_FLAGS=""
    DEBUG_MODE=false
fi

[[ "$DEBUG_MODE" == "true" ]] && set -x

# --- Handler de Argumentos ---
MODE=""
FORMAT_TARGET=""
INPUT_FILE=""

usage() {
    echo "Uso: $0 --mode <modo> --target <extensao> \"caminho_do_arquivo\""
    echo "Modos: ebook, video-to-audio, video-format, image-format"
    echo "Exemplo: $0 --mode video-to-audio --target mp3 video.mp4"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --target)
            FORMAT_TARGET="$2"
            shift 2
            ;;
        --interactive)
            # Acionado quando o usuário roda pelo Hub CLI menu.sh
            echo "==========================================================="
            echo "O módulo Media Converter funciona melhor via clique-direito no KDE Dolphin."
            echo "Para usar pelo terminal manualmente:"
            echo "Mapeamento atual:"
            echo "  $0 --mode video-to-audio --target mp3 arquivo.mp4"
            echo "==========================================================="
            exit 0
            ;;
        -*)
            echo "Opção desconhecida: $1"
            usage
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

if [[ -z "$INPUT_FILE" ]] || [[ ! -f "$INPUT_FILE" ]]; then
    show_error "Arquivo de entrada inválido ou não encontrado: ${INPUT_FILE}"
    exit 1
fi

if [[ -z "$MODE" ]] || [[ -z "$FORMAT_TARGET" ]]; then
    # TODO interativo futuramente caso falte argumento
    show_error "Argumentos obrigatórios ausentes. Use --mode e --target, ou chame pelo menu de contexto."
    usage
fi

# --- Preparação do Output ---
# Extrai pasta, nome sem extensão, e formata o alvo.
dir_path=$(dirname "$INPUT_FILE")
base_name=$(basename "$INPUT_FILE")
filename="${base_name%.*}"
OUTPUT_FILE="${dir_path}/${filename}.${FORMAT_TARGET}"

# Lidando com a checagem de sobreposição
ffmpeg_override_flag="-n"
if [[ -f "$OUTPUT_FILE" ]]; then
    if [[ "$OVERWRITE_EXISTING" == "false" ]]; then
        show_error "O arquivo '${OUTPUT_FILE}' já existe e OVERWRITE_EXISTING está setado como false. Abortando."
        exit 1
    else
        ffmpeg_override_flag="-y"
    fi
fi

echo -e "\n📦 [\033[1;36mMedia Converter\033[0m] Iniciando processamento..."
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e " 📄 \033[1mOrigem\033[0m : ${base_name}"
echo -e " 🔧 \033[1mAção\033[0m   : Converter para \033[1;32m${FORMAT_TARGET^^}\033[0m"
echo -e " 🎯 \033[1mDestino\033[0m: $(basename "$OUTPUT_FILE")"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

# --- Execução do Modo ---
success=false

case "$MODE" in
    "ebook")
        if convert_with_calibre "$INPUT_FILE" "$OUTPUT_FILE" "$EBOOK_EXTRA_FLAGS"; then
            success=true
        fi
        ;;
    "video-to-audio")
        # -vn tira o video, -b:a seta a qualidade
        if convert_with_ffmpeg "$INPUT_FILE" "$OUTPUT_FILE" "${ffmpeg_override_flag} -vn -b:a ${AUDIO_QUAL}"; then
            success=true
        fi
        ;;
    "video-format")
        # Mantém streams, re-encapsula ou encoda se o target exigir
        if convert_with_ffmpeg "$INPUT_FILE" "$OUTPUT_FILE" "${ffmpeg_override_flag}"; then
            success=true
        fi
        ;;
    "image-format")
        # Para imagens, ImageMagick é incrivelmente mais estável de lidar
        # que o ffmpeg (que às vezes surta interpretando como sequência de vídeo se houver números no nome).
        # Fallback de comando: tentar magick input output; ou convert input output.
        if command -v magick >/dev/null 2>&1; then
            if magick "$INPUT_FILE" "$OUTPUT_FILE"; then success=true; fi
        elif command -v convert >/dev/null 2>&1; then
            if convert "$INPUT_FILE" "$OUTPUT_FILE"; then success=true; fi
        else
            echo "ERRO: ImageMagick (magick/convert) não encontrado no sistema." >&2
            exit 1
        fi
        ;;
    *)
        show_error "Modo não suportado: $MODE"
        exit 1
        ;;
esac

# --- Pós Conversão ---
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$success" == "true" ]]; then
    echo -e " ✅ \033[1;32mSUCESSO\033[0m -> O arquivo foi convertido perfeitamente!"
    show_success "Conversão completa: ${filename}.${FORMAT_TARGET}"
    if [[ "$DELETE_ORIGINAL" == "true" ]]; then
        rm -f "$INPUT_FILE"
        echo -e " 🗑️ \033[1;33mINFO\033[0m -> Arquivo original deletado conforme config.conf."
    fi
else
    echo -e " ❌ \033[1;31mFALHA\033[0m -> Ocorreu um erro durante a conversão."
    show_error "A conversão falhou! Verifique os formatos ou dependências."
    exit 1
fi
echo -e "\n👋 Processo finalizado. Pode fechar o terminal.\n"
