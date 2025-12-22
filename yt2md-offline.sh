#!/bin/bash

#########################################################
# YouTube to Markdown Converter - OFFLINE Mode
# Genera markdown anche senza connessione internet
# Author: Edmond
# License: MIT
#########################################################

VERSION="1.0.0"

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << EOF
${GREEN}YouTube to Markdown - OFFLINE Mode v${VERSION}${NC}

${YELLOW}USO:${NC}
    $0 [OPZIONI] <URL_o_VIDEO_ID>

${YELLOW}OPZIONI:${NC}
    -h, --help              Mostra questo help
    -f, --format FORMAT     Formato (standard|simple|embed|table) [default: standard]
    -t, --title "TITOLO"    Specifica titolo manualmente
    -a, --author "AUTORE"   Specifica autore manualmente
    -s, --size SIZE         Thumbnail size (default|medium|high|maxres) [default: high]
    -o, --output FILE       Salva su file

${YELLOW}MODALITÀ OFFLINE:${NC}
Questa versione genera markdown anche senza connessione internet.
Se non specifichi titolo/autore, userà valori di default.

${YELLOW}ESEMPI:${NC}
    # Con titolo e autore
    $0 -t "Tutorial Linux" -a "TechChannel" "dQw4w9WgXcQ"
    
    # Solo con ID (usa valori default)
    $0 "dQw4w9WgXcQ"
    
    # URL completo
    $0 "https://youtube.com/watch?v=dQw4w9WgXcQ"
    
    # Con file output
    $0 -t "My Video" -o video.md "VIDEO_ID"

EOF
}

# Estrai video ID
extract_video_id() {
    local url="$1"
    local video_id=""
    
    if [[ $url =~ youtube\.com/watch\?v=([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    elif [[ $url =~ youtu\.be/([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    elif [[ $url =~ youtube\.com/shorts/([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    elif [[ $url =~ youtube\.com/embed/([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    elif [[ $url =~ ^([a-zA-Z0-9_-]{11})$ ]]; then
        video_id="$url"
    fi
    
    echo "$video_id"
}

# Genera markdown
generate_markdown() {
    local format="$1"
    local video_id="$2"
    local title="$3"
    local author="$4"
    local thumb_size="$5"
    
    # Costruisci URL
    local url="https://www.youtube.com/watch?v=${video_id}"
    local thumbnail=""
    
    case "$thumb_size" in
        default) thumbnail="https://img.youtube.com/vi/${video_id}/default.jpg" ;;
        medium) thumbnail="https://img.youtube.com/vi/${video_id}/mqdefault.jpg" ;;
        high) thumbnail="https://img.youtube.com/vi/${video_id}/hqdefault.jpg" ;;
        maxres) thumbnail="https://img.youtube.com/vi/${video_id}/maxresdefault.jpg" ;;
        *) thumbnail="https://img.youtube.com/vi/${video_id}/hqdefault.jpg" ;;
    esac
    
    # Genera markdown in base al formato
    case "$format" in
        standard)
            echo "[![${title}](${thumbnail})](${url})"
            ;;
        simple)
            echo "[${title}](${url})"
            ;;
        embed)
            cat << EOF
<a href="${url}">
  <img src="${thumbnail}" alt="${title}" width="480">
</a>

<!-- Iframe embed: -->
<iframe width="560" height="315" src="https://www.youtube.com/embed/${video_id}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
EOF
            ;;
        table)
            cat << EOF
| Video | Autore |
|-------|--------|
| [![${title}](${thumbnail})](${url}) | ${author} |
EOF
            ;;
        *)
            echo "[![${title}](${thumbnail})](${url})"
            ;;
    esac
}

# Default values
FORMAT="standard"
TITLE=""
AUTHOR=""
THUMB_SIZE="high"
OUTPUT_FILE=""
URL=""

# Parse argomenti
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -t|--title)
            TITLE="$2"
            shift 2
            ;;
        -a|--author)
            AUTHOR="$2"
            shift 2
            ;;
        -s|--size)
            THUMB_SIZE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -*)
            echo "Opzione sconosciuta: $1"
            exit 1
            ;;
        *)
            URL="$1"
            shift
            ;;
    esac
done

# Verifica URL
if [ -z "$URL" ]; then
    echo "Errore: URL o Video ID richiesto!"
    echo "Usa: $0 -h per l'help"
    exit 1
fi

# Estrai video ID
VIDEO_ID=$(extract_video_id "$URL")

if [ -z "$VIDEO_ID" ]; then
    echo "Errore: URL non valido o Video ID non trovato"
    exit 1
fi

# Usa valori default se non specificati
if [ -z "$TITLE" ]; then
    TITLE="YouTube Video - ${VIDEO_ID}"
fi

if [ -z "$AUTHOR" ]; then
    AUTHOR="YouTube Channel"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Generazione Markdown (OFFLINE)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Video ID: ${YELLOW}${VIDEO_ID}${NC}"
echo -e "Titolo:   ${YELLOW}${TITLE}${NC}"
echo -e "Autore:   ${YELLOW}${AUTHOR}${NC}"
echo -e "Formato:  ${YELLOW}${FORMAT}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Genera markdown
MARKDOWN=$(generate_markdown "$FORMAT" "$VIDEO_ID" "$TITLE" "$AUTHOR" "$THUMB_SIZE")

# Output
if [ -n "$OUTPUT_FILE" ]; then
    echo "$MARKDOWN" > "$OUTPUT_FILE"
    echo -e "${GREEN}✓ Salvato in: ${OUTPUT_FILE}${NC}"
else
    echo "$MARKDOWN"
fi

echo ""
echo -e "${GREEN}✓ Markdown generato con successo!${NC}"
