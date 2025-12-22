#!/bin/bash

#########################################################
# YouTube to Markdown Converter - CLI Version
# Converte link YouTube in formato markdown per README
# Author: Edmond
# License: MIT
#########################################################

VERSION="1.0.0"
SCRIPT_NAME="yt2md-cli"

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzione per mostrare l'help
show_help() {
    cat << EOF
${GREEN}$SCRIPT_NAME v$VERSION${NC}
Converte link YouTube in formato markdown per README GitHub

${YELLOW}USO:${NC}
    $0 [OPZIONI] <URL_YOUTUBE>

${YELLOW}OPZIONI:${NC}
    -h, --help              Mostra questo messaggio
    -v, --version           Mostra la versione
    -f, --format FORMAT     Formato output (default: standard)
                            Formati disponibili:
                            - standard: [![Title](thumbnail)](url)
                            - simple: [Title](url)
                            - embed: codice embed HTML
                            - table: formato tabella markdown
                            - badge: con badge personalizzato
    -o, --output FILE       Salva output su file invece che stdout
    -t, --thumbnail SIZE    Dimensione thumbnail (default, medium, high, maxres)
    --title TITLE           Specifica titolo manualmente (modalità offline)
    --author AUTHOR         Specifica autore manualmente (modalità offline)
    -c, --clipboard         Copia risultato nella clipboard
    --no-color              Disabilita output colorato
    --offline               Modalità offline (richiede --title)

${YELLOW}ESEMPI:${NC}
    $0 "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    $0 -f simple "https://youtu.be/dQw4w9WgXcQ"
    $0 -f table -o README.md "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    $0 -c "https://www.youtube.com/shorts/dQw4w9WgXcQ"
    $0 --offline --title "My Video" --author "My Channel" "dQw4w9WgXcQ"

${YELLOW}REQUISITI:${NC}
    - curl (per scaricare dati)
    - jq (per parsing JSON) - opzionale ma consigliato
    - xclip o xsel (per clipboard) - opzionale

EOF
}

# Funzione per mostrare errori
error() {
    echo -e "${RED}[ERRORE]${NC} $1" >&2
}

# Funzione per mostrare info
info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

# Funzione per mostrare successo
success() {
    echo -e "${GREEN}[OK]${NC} $1" >&2
}

# Funzione per estrarre video ID dal link
extract_video_id() {
    local url="$1"
    local video_id=""
    
    # Pattern per vari formati YouTube
    if [[ $url =~ youtube\.com/watch\?v=([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    elif [[ $url =~ youtu\.be/([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    elif [[ $url =~ youtube\.com/shorts/([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    elif [[ $url =~ youtube\.com/embed/([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    elif [[ $url =~ ^([a-zA-Z0-9_-]{11})$ ]]; then
        # Se è già un video ID
        video_id="$url"
    fi
    
    echo "$video_id"
}

# Funzione per ottenere info video
get_video_info() {
    local video_id="$1"
    local thumbnail_size="${2:-default}"
    
    info "Recupero informazioni video..."
    
    # Costruisci URL thumbnail (sempre disponibile)
    case "$thumbnail_size" in
        "default")
            VIDEO_THUMBNAIL="https://img.youtube.com/vi/${video_id}/default.jpg"
            ;;
        "medium")
            VIDEO_THUMBNAIL="https://img.youtube.com/vi/${video_id}/mqdefault.jpg"
            ;;
        "high")
            VIDEO_THUMBNAIL="https://img.youtube.com/vi/${video_id}/hqdefault.jpg"
            ;;
        "maxres")
            VIDEO_THUMBNAIL="https://img.youtube.com/vi/${video_id}/maxresdefault.jpg"
            ;;
        *)
            VIDEO_THUMBNAIL="https://img.youtube.com/vi/${video_id}/hqdefault.jpg"
            ;;
    esac
    
    VIDEO_URL="https://www.youtube.com/watch?v=${video_id}"
    
    # Metodo 1: Prova oEmbed API
    local oembed_url="https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${video_id}&format=json"
    local json_data=$(curl -s -m 5 "$oembed_url" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$json_data" ] && [[ "$json_data" != *"error"* ]]; then
        # Estrai dati (con jq se disponibile, altrimenti parsing manuale)
        if command -v jq &> /dev/null; then
            VIDEO_TITLE=$(echo "$json_data" | jq -r '.title' 2>/dev/null)
            VIDEO_AUTHOR=$(echo "$json_data" | jq -r '.author_name' 2>/dev/null)
        else
            # Parsing manuale con gestione caratteri speciali
            VIDEO_TITLE=$(echo "$json_data" | grep -o '"title":"[^"]*"' | sed 's/"title":"//;s/"$//' | sed 's/\\u0026/\&/g; s/\\//g')
            VIDEO_AUTHOR=$(echo "$json_data" | grep -o '"author_name":"[^"]*"' | sed 's/"author_name":"//;s/"$//')
        fi
        
        # Verifica che i dati siano validi
        if [ -n "$VIDEO_TITLE" ] && [ "$VIDEO_TITLE" != "null" ]; then
            success "Titolo: $VIDEO_TITLE"
            success "Autore: $VIDEO_AUTHOR"
            return 0
        fi
    fi
    
    # Metodo 2: Scraping dalla pagina HTML (fallback)
    info "Metodo oEmbed fallito, provo scraping HTML..."
    local html_content=$(curl -s -L -m 10 "https://www.youtube.com/watch?v=${video_id}" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$html_content" ]; then
        # Estrai titolo da meta tag og:title
        VIDEO_TITLE=$(echo "$html_content" | grep -o '<meta property="og:title" content="[^"]*"' | sed 's/.*content="//;s/"$//' | head -1)
        
        # Estrai autore da meta tag
        VIDEO_AUTHOR=$(echo "$html_content" | grep -o '<link itemprop="name" content="[^"]*"' | sed 's/.*content="//;s/"$//' | head -1)
        
        if [ -z "$VIDEO_AUTHOR" ]; then
            VIDEO_AUTHOR=$(echo "$html_content" | grep -o '"author":"[^"]*"' | sed 's/"author":"//;s/"$//' | head -1)
        fi
        
        # Verifica che i dati siano validi
        if [ -n "$VIDEO_TITLE" ] && [ "$VIDEO_TITLE" != "null" ]; then
            success "Titolo: $VIDEO_TITLE"
            success "Autore: $VIDEO_AUTHOR"
            return 0
        fi
    fi
    
    # Metodo 3: Fallback con titolo generico (sempre funziona)
    error "Impossibile recuperare titolo/autore, uso valori di default"
    VIDEO_TITLE="YouTube Video"
    VIDEO_AUTHOR="Unknown"
    
    return 0
}

# Funzione per generare markdown in formato standard
format_standard() {
    cat << EOF
[![${VIDEO_TITLE}](${VIDEO_THUMBNAIL})](${VIDEO_URL})
EOF
}

# Funzione per generare markdown semplice
format_simple() {
    cat << EOF
[${VIDEO_TITLE}](${VIDEO_URL})
EOF
}

# Funzione per generare codice embed HTML
format_embed() {
    local video_id=$(extract_video_id "$VIDEO_URL")
    cat << EOF
<a href="${VIDEO_URL}">
  <img src="${VIDEO_THUMBNAIL}" alt="${VIDEO_TITLE}" width="480">
</a>

<!-- Oppure iframe embed: -->
<iframe width="560" height="315" src="https://www.youtube.com/embed/${video_id}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
EOF
}

# Funzione per generare formato tabella
format_table() {
    cat << EOF
| Video | Autore |
|-------|--------|
| [![${VIDEO_TITLE}](${VIDEO_THUMBNAIL})](${VIDEO_URL}) | ${VIDEO_AUTHOR} |
EOF
}

# Funzione per generare formato con badge
format_badge() {
    cat << EOF
[![${VIDEO_TITLE}](${VIDEO_THUMBNAIL})](${VIDEO_URL})

[![YouTube](https://img.shields.io/badge/YouTube-Video-red?style=for-the-badge&logo=youtube)](${VIDEO_URL})
**${VIDEO_TITLE}** - *${VIDEO_AUTHOR}*
EOF
}

# Funzione per copiare nella clipboard
copy_to_clipboard() {
    local content="$1"
    
    if command -v xclip &> /dev/null; then
        echo -n "$content" | xclip -selection clipboard
        success "Copiato nella clipboard (xclip)"
        return 0
    elif command -v xsel &> /dev/null; then
        echo -n "$content" | xsel --clipboard
        success "Copiato nella clipboard (xsel)"
        return 0
    elif command -v pbcopy &> /dev/null; then
        echo -n "$content" | pbcopy
        success "Copiato nella clipboard (pbcopy)"
        return 0
    else
        error "Nessun tool per clipboard trovato (installa xclip, xsel o pbcopy)"
        return 1
    fi
}

# Variabili default
FORMAT="standard"
OUTPUT_FILE=""
THUMBNAIL_SIZE="high"
USE_CLIPBOARD=false
URL=""
MANUAL_TITLE=""
MANUAL_AUTHOR=""
OFFLINE_MODE=false

# Parsing argomenti
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "$SCRIPT_NAME v$VERSION"
            exit 0
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -t|--thumbnail)
            THUMBNAIL_SIZE="$2"
            shift 2
            ;;
        --title)
            MANUAL_TITLE="$2"
            OFFLINE_MODE=true
            shift 2
            ;;
        --author)
            MANUAL_AUTHOR="$2"
            shift 2
            ;;
        --offline)
            OFFLINE_MODE=true
            shift
            ;;
        -c|--clipboard)
            USE_CLIPBOARD=true
            shift
            ;;
        --no-color)
            RED=''
            GREEN=''
            YELLOW=''
            BLUE=''
            NC=''
            shift
            ;;
        -*)
            error "Opzione sconosciuta: $1"
            echo "Usa -h per l'help"
            exit 1
            ;;
        *)
            URL="$1"
            shift
            ;;
    esac
done

# Verifica che sia stato fornito un URL
if [ -z "$URL" ]; then
    error "URL YouTube richiesto!"
    echo "Usa: $0 [opzioni] <URL_YOUTUBE>"
    echo "Usa -h per l'help completo"
    exit 1
fi

# Verifica dipendenze essenziali
if ! command -v curl &> /dev/null; then
    error "curl non trovato! Installalo con: sudo apt install curl"
    exit 1
fi

# Estrai video ID
VIDEO_ID=$(extract_video_id "$URL")

if [ -z "$VIDEO_ID" ]; then
    error "URL YouTube non valido: $URL"
    exit 1
fi

info "Video ID: $VIDEO_ID"

# Ottieni info video
if [ "$OFFLINE_MODE" = true ]; then
    # Modalità offline - usa valori manuali
    info "Modalità OFFLINE attivata"
    
    VIDEO_TITLE="${MANUAL_TITLE:-YouTube Video - ${VIDEO_ID}}"
    VIDEO_AUTHOR="${MANUAL_AUTHOR:-YouTube Channel}"
    
    case "$THUMBNAIL_SIZE" in
        "default") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/default.jpg" ;;
        "medium") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/mqdefault.jpg" ;;
        "high") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/hqdefault.jpg" ;;
        "maxres") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/maxresdefault.jpg" ;;
        *) VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/hqdefault.jpg" ;;
    esac
    
    VIDEO_URL="https://www.youtube.com/watch?v=${VIDEO_ID}"
    
    success "Titolo: $VIDEO_TITLE"
    success "Autore: $VIDEO_AUTHOR"
elif ! get_video_info "$VIDEO_ID" "$THUMBNAIL_SIZE"; then
    exit 1
fi

# Genera markdown nel formato richiesto
case "$FORMAT" in
    "standard")
        MARKDOWN=$(format_standard)
        ;;
    "simple")
        MARKDOWN=$(format_simple)
        ;;
    "embed")
        MARKDOWN=$(format_embed)
        ;;
    "table")
        MARKDOWN=$(format_table)
        ;;
    "badge")
        MARKDOWN=$(format_badge)
        ;;
    *)
        error "Formato sconosciuto: $FORMAT"
        echo "Formati disponibili: standard, simple, embed, table, badge"
        exit 1
        ;;
esac

# Output risultato
if [ -n "$OUTPUT_FILE" ]; then
    echo "$MARKDOWN" > "$OUTPUT_FILE"
    success "Markdown salvato in: $OUTPUT_FILE"
else
    echo ""
    echo "$MARKDOWN"
    echo ""
fi

# Copia in clipboard se richiesto
if [ "$USE_CLIPBOARD" = true ]; then
    copy_to_clipboard "$MARKDOWN"
fi

success "Conversione completata!"
