#!/bin/bash

#########################################################
# YouTube to Markdown - Versione Unificata Semplice
# Funziona SEMPRE - sia online che offline
# Author: Edmond
# License: MIT
#########################################################

VERSION="1.0.0"

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << EOF
${GREEN}YouTube to Markdown v${VERSION}${NC}

${YELLOW}USO SEMPLICE:${NC}
    $0 VIDEO_ID "TITOLO" ["AUTORE"]

${YELLOW}USO AVANZATO:${NC}
    $0 [OPZIONI] VIDEO_ID "TITOLO" ["AUTORE"]

${YELLOW}OPZIONI:${NC}
    -f FORMAT    Formato: standard|simple|table|embed [default: standard]
    -s SIZE      Thumbnail: default|medium|high|maxres [default: high]
    -o FILE      Salva su file invece di stdout
    -h           Mostra questo help

${YELLOW}ESEMPI:${NC}
    # Base
    $0 dQw4w9WgXcQ "Tutorial Linux"
    
    # Con autore
    $0 dQw4w9WgXcQ "Tutorial Linux" "Edmond"
    
    # Formato simple
    $0 -f simple dQw4w9WgXcQ "Bash Guide"
    
    # Formato table
    $0 -f table dQw4w9WgXcQ "SysLinuxOS" "Edmond"
    
    # Salva su file
    $0 -o video.md dQw4w9WgXcQ "My Video"
    
    # Da URL completo
    $0 "https://youtube.com/watch?v=dQw4w9WgXcQ" "Titolo"

${YELLOW}VIDEO ID:${NC}
    Da URL: https://youtube.com/watch?v=dQw4w9WgXcQ
    ID è:   dQw4w9WgXcQ (11 caratteri dopo v=)

EOF
}

# Estrai video ID
extract_video_id() {
    local input="$1"
    
    if [[ $input =~ youtube\.com/watch\?v=([a-zA-Z0-9_-]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ $input =~ youtu\.be/([a-zA-Z0-9_-]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ $input =~ youtube\.com/shorts/([a-zA-Z0-9_-]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ $input =~ ^([a-zA-Z0-9_-]{11})$ ]]; then
        echo "$input"
    fi
}

# Genera markdown
generate_markdown() {
    local format="$1"
    local video_id="$2"
    local title="$3"
    local author="${4:-YouTube Channel}"
    local size="$5"
    
    local url="https://www.youtube.com/watch?v=${video_id}"
    local thumb=""
    
    case "$size" in
        default) thumb="https://img.youtube.com/vi/${video_id}/default.jpg" ;;
        medium) thumb="https://img.youtube.com/vi/${video_id}/mqdefault.jpg" ;;
        high) thumb="https://img.youtube.com/vi/${video_id}/hqdefault.jpg" ;;
        maxres) thumb="https://img.youtube.com/vi/${video_id}/maxresdefault.jpg" ;;
        *) thumb="https://img.youtube.com/vi/${video_id}/hqdefault.jpg" ;;
    esac
    
    case "$format" in
        standard)
            echo "[![${title}](${thumb})](${url})"
            ;;
        simple)
            echo "[${title}](${url})"
            ;;
        table)
            echo "| Video | Autore |"
            echo "|-------|--------|"
            echo "| [![${title}](${thumb})](${url}) | ${author} |"
            ;;
        embed)
            cat << EOF
<a href="${url}">
  <img src="${thumb}" alt="${title}" width="480">
</a>

<!-- Iframe embed: -->
<iframe width="560" height="315" src="https://www.youtube.com/embed/${video_id}" frameborder="0" allowfullscreen></iframe>
EOF
            ;;
        *)
            echo "[![${title}](${thumb})](${url})"
            ;;
    esac
}

# Parse opzioni
FORMAT="standard"
SIZE="high"
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -f)
            FORMAT="$2"
            shift 2
            ;;
        -s)
            SIZE="$2"
            shift 2
            ;;
        -o)
            OUTPUT="$2"
            shift 2
            ;;
        -*)
            echo -e "${RED}Opzione sconosciuta: $1${NC}"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Argomenti posizionali
VIDEO_INPUT="$1"
TITLE="$2"
AUTHOR="$3"

# Validazione
if [ -z "$VIDEO_INPUT" ]; then
    echo -e "${RED}Errore: VIDEO_ID richiesto${NC}"
    echo "Uso: $0 VIDEO_ID \"TITOLO\" [\"AUTORE\"]"
    echo "Help: $0 -h"
    exit 1
fi

if [ -z "$TITLE" ]; then
    echo -e "${RED}Errore: TITOLO richiesto${NC}"
    echo "Uso: $0 VIDEO_ID \"TITOLO\" [\"AUTORE\"]"
    exit 1
fi

# Estrai ID
VIDEO_ID=$(extract_video_id "$VIDEO_INPUT")

if [ -z "$VIDEO_ID" ]; then
    echo -e "${RED}Errore: Video ID non valido${NC}"
    exit 1
fi

# Genera markdown
MARKDOWN=$(generate_markdown "$FORMAT" "$VIDEO_ID" "$TITLE" "$AUTHOR" "$SIZE")

# Output
if [ -n "$OUTPUT" ]; then
    echo "$MARKDOWN" > "$OUTPUT"
    echo -e "${GREEN}✓ Salvato in: ${OUTPUT}${NC}"
else
    echo "$MARKDOWN"
fi
