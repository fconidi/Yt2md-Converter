#!/bin/bash

#########################################################
# YouTube to Markdown Converter - GUI Version
# Converte link YouTube in formato markdown per README
# Author: Edmond
# License: MIT
#########################################################

VERSION="1.0.0"
SCRIPT_NAME="yt2md-gui"

# Verifica dipendenze
check_dependencies() {
    local missing_deps=()
    
    if ! command -v zenity &> /dev/null; then
        missing_deps+=("zenity")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        if command -v zenity &> /dev/null; then
            zenity --error --width=400 --title="Dipendenze Mancanti" \
                --text="Installa le seguenti dipendenze:\n\n${missing_deps[*]}\n\nUsa: sudo apt install ${missing_deps[*]}"
        else
            echo "ERRORE: Dipendenze mancanti: ${missing_deps[*]}"
            echo "Installa con: sudo apt install ${missing_deps[*]}"
        fi
        exit 1
    fi
}

# Funzione per estrarre video ID
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

# Funzione per ottenere info video
get_video_info() {
    local video_id="$1"
    local thumbnail_size="${2:-high}"
    
    # Costruisci URL thumbnail (sempre disponibile)
    case "$thumbnail_size" in
        "default") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${video_id}/default.jpg" ;;
        "medium") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${video_id}/mqdefault.jpg" ;;
        "high") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${video_id}/hqdefault.jpg" ;;
        "maxres") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${video_id}/maxresdefault.jpg" ;;
        *) VIDEO_THUMBNAIL="https://img.youtube.com/vi/${video_id}/hqdefault.jpg" ;;
    esac
    
    VIDEO_URL="https://www.youtube.com/watch?v=${video_id}"
    
    # Metodo 1: oEmbed API
    local oembed_url="https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${video_id}&format=json"
    local json_data=$(curl -s -m 5 "$oembed_url" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$json_data" ] && [[ "$json_data" != *"error"* ]]; then
        if command -v jq &> /dev/null; then
            VIDEO_TITLE=$(echo "$json_data" | jq -r '.title' 2>/dev/null)
            VIDEO_AUTHOR=$(echo "$json_data" | jq -r '.author_name' 2>/dev/null)
        else
            VIDEO_TITLE=$(echo "$json_data" | grep -o '"title":"[^"]*"' | sed 's/"title":"//;s/"$//' | sed 's/\\u0026/\&/g; s/\\//g')
            VIDEO_AUTHOR=$(echo "$json_data" | grep -o '"author_name":"[^"]*"' | sed 's/"author_name":"//;s/"$//')
        fi
        
        if [ -n "$VIDEO_TITLE" ] && [ "$VIDEO_TITLE" != "null" ]; then
            return 0
        fi
    fi
    
    # Metodo 2: Scraping HTML
    local html_content=$(curl -s -L -m 10 "https://www.youtube.com/watch?v=${video_id}" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$html_content" ]; then
        VIDEO_TITLE=$(echo "$html_content" | grep -o '<meta property="og:title" content="[^"]*"' | sed 's/.*content="//;s/"$//' | head -1)
        VIDEO_AUTHOR=$(echo "$html_content" | grep -o '<link itemprop="name" content="[^"]*"' | sed 's/.*content="//;s/"$//' | head -1)
        
        if [ -z "$VIDEO_AUTHOR" ]; then
            VIDEO_AUTHOR=$(echo "$html_content" | grep -o '"author":"[^"]*"' | sed 's/"author":"//;s/"$//' | head -1)
        fi
        
        if [ -n "$VIDEO_TITLE" ] && [ "$VIDEO_TITLE" != "null" ]; then
            return 0
        fi
    fi
    
    # Metodo 3: Fallback
    VIDEO_TITLE="YouTube Video"
    VIDEO_AUTHOR="Unknown"
    
    return 0
}

# Funzioni di formattazione
format_standard() {
    echo "[![${VIDEO_TITLE}](${VIDEO_THUMBNAIL})](${VIDEO_URL})"
}

format_simple() {
    echo "[${VIDEO_TITLE}](${VIDEO_URL})"
}

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

format_table() {
    cat << EOF
| Video | Autore |
|-------|--------|
| [![${VIDEO_TITLE}](${VIDEO_THUMBNAIL})](${VIDEO_URL}) | ${VIDEO_AUTHOR} |
EOF
}

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
        return 0
    elif command -v xsel &> /dev/null; then
        echo -n "$content" | xsel --clipboard
        return 0
    elif command -v pbcopy &> /dev/null; then
        echo -n "$content" | pbcopy
        return 0
    else
        return 1
    fi
}

# Funzione principale GUI
main_gui() {
    while true; do
        # Dialog principale con menu
        CHOICE=$(zenity --list --radiolist \
            --title="YouTube to Markdown Converter v${VERSION}" \
            --text="Scegli un'opzione:" \
            --width=500 --height=350 \
            --column="" --column="Opzione" --column="Descrizione" \
            TRUE "convert" "Converti link YouTube" \
            FALSE "batch" "Conversione multipla (batch)" \
            FALSE "settings" "Impostazioni formato" \
            FALSE "help" "Aiuto e informazioni" \
            FALSE "quit" "Esci" 2>/dev/null)
        
        if [ $? -ne 0 ] || [ "$CHOICE" = "quit" ]; then
            exit 0
        fi
        
        case "$CHOICE" in
            "convert")
                convert_single
                ;;
            "batch")
                convert_batch
                ;;
            "settings")
                show_settings
                ;;
            "help")
                show_help_dialog
                ;;
        esac
    done
}

# Funzione per conversione singola
convert_single() {
    # Input URL o Video ID
    URL=$(zenity --entry \
        --title="Inserisci URL o Video ID YouTube" \
        --text="Incolla qui il link o Video ID del video YouTube:" \
        --width=500 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$URL" ]; then
        return
    fi
    
    # Estrai video ID
    VIDEO_ID=$(extract_video_id "$URL")
    
    if [ -z "$VIDEO_ID" ]; then
        zenity --error --width=400 \
            --title="Errore" \
            --text="URL YouTube o Video ID non valido!\n\nFormati supportati:\n• youtube.com/watch?v=...\n• youtu.be/...\n• youtube.com/shorts/...\n• Video ID (11 caratteri)" 2>/dev/null
        return
    fi
    
    # Input TITOLO (obbligatorio)
    VIDEO_TITLE=$(zenity --entry \
        --title="Titolo Video" \
        --text="Inserisci il TITOLO del video:" \
        --width=500 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$VIDEO_TITLE" ]; then
        zenity --error --width=400 \
            --title="Errore" \
            --text="Il titolo è obbligatorio!" 2>/dev/null
        return
    fi
    
    # Input AUTORE (opzionale)
    VIDEO_AUTHOR=$(zenity --entry \
        --title="Autore/Canale" \
        --text="Inserisci il nome del canale YouTube (opzionale):" \
        --entry-text="YouTube Channel" \
        --width=500 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$VIDEO_AUTHOR" ]; then
        VIDEO_AUTHOR="YouTube Channel"
    fi
    
    # Selezione formato
    FORMAT=$(zenity --list --radiolist \
        --title="Seleziona Formato Markdown" \
        --text="Scegli il formato di output:" \
        --width=500 --height=400 \
        --column="" --column="Formato" --column="Descrizione" \
        TRUE "standard" "[![Title](thumbnail)](url) - Standard con immagine" \
        FALSE "simple" "[Title](url) - Solo link testuale" \
        FALSE "embed" "Codice HTML embed completo" \
        FALSE "table" "Formato tabella markdown" \
        FALSE "badge" "Con badge YouTube personalizzato" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        FORMAT="standard"
    fi
    
    # Selezione qualità thumbnail
    THUMB_SIZE=$(zenity --list --radiolist \
        --title="Qualità Thumbnail" \
        --text="Scegli la qualità dell'immagine:" \
        --width=400 --height=300 \
        --column="" --column="Qualità" --column="Risoluzione" \
        FALSE "default" "120x90 px" \
        FALSE "medium" "320x180 px" \
        TRUE "high" "480x360 px" \
        FALSE "maxres" "1280x720 px (se disponibile)" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        THUMB_SIZE="high"
    fi
    
    # Progress bar generazione
    (
        echo "20" ; echo "# Elaborazione dati..."
        sleep 0.3
        echo "50" ; echo "# Costruzione URL thumbnail..."
        sleep 0.3
        echo "80" ; echo "# Generazione markdown..."
        sleep 0.3
        echo "100" ; echo "# Completato!"
        sleep 0.2
    ) | zenity --progress --title="Elaborazione..." --width=400 --auto-close --auto-kill 2>/dev/null
    
    # Costruisci URL thumbnail
    case "$THUMB_SIZE" in
        "default") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/default.jpg" ;;
        "medium") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/mqdefault.jpg" ;;
        "high") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/hqdefault.jpg" ;;
        "maxres") VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/maxresdefault.jpg" ;;
        *) VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/hqdefault.jpg" ;;
    esac
    
    VIDEO_URL="https://www.youtube.com/watch?v=${VIDEO_ID}"
    
    # Genera markdown
    case "$FORMAT" in
        "standard") MARKDOWN=$(format_standard) ;;
        "simple") MARKDOWN=$(format_simple) ;;
        "embed") MARKDOWN=$(format_embed) ;;
        "table") MARKDOWN=$(format_table) ;;
        "badge") MARKDOWN=$(format_badge) ;;
    esac
    
    # Mostra risultato con opzioni
    RESULT_CHOICE=$(zenity --list --radiolist \
        --title="Conversione Completata!" \
        --text="<b>Video ID:</b> ${VIDEO_ID}\n<b>Titolo:</b> ${VIDEO_TITLE}\n<b>Autore:</b> ${VIDEO_AUTHOR}\n\n<b>Markdown generato con successo!</b>\n\nScegli un'azione:" \
        --width=600 --height=400 \
        --column="" --column="Azione" --column="Descrizione" \
        TRUE "clipboard" "Copia nella clipboard" \
        FALSE "save" "Salva su file" \
        FALSE "view" "Visualizza codice" \
        FALSE "back" "Torna al menu" 2>/dev/null)
    
    case "$RESULT_CHOICE" in
        "clipboard")
            if copy_to_clipboard "$MARKDOWN"; then
                zenity --info --width=400 \
                    --title="Successo!" \
                    --text="✓ Markdown copiato nella clipboard!\n\nPuoi incollarlo direttamente nel tuo README con CTRL+V." 2>/dev/null
            else
                zenity --warning --width=400 \
                    --title="Attenzione" \
                    --text="Impossibile copiare nella clipboard.\n\nInstalla xclip o xsel:\nsudo apt install xclip" 2>/dev/null
                # Mostra comunque il codice
                zenity --text-info \
                    --title="Codice Markdown (copia manualmente)" \
                    --width=700 --height=500 \
                    --filename=<(echo "$MARKDOWN") 2>/dev/null
            fi
            ;;
        "save")
            SAVE_FILE=$(zenity --file-selection --save \
                --title="Salva Markdown" \
                --filename="youtube-video.md" \
                --file-filter="Markdown files (*.md) | *.md" \
                --file-filter="All files | *" 2>/dev/null)
            
            if [ $? -eq 0 ] && [ -n "$SAVE_FILE" ]; then
                echo "$MARKDOWN" > "$SAVE_FILE"
                zenity --info --width=400 \
                    --title="Salvato!" \
                    --text="✓ File salvato in:\n${SAVE_FILE}" 2>/dev/null
            fi
            ;;
        "view")
            zenity --text-info \
                --title="Codice Markdown Generato" \
                --width=700 --height=500 \
                --filename=<(echo "$MARKDOWN") \
                --editable 2>/dev/null
            ;;
    esac
}

# Funzione per conversione batch
convert_batch() {
    # Mostra info
    zenity --info --width=500 --height=250 \
        --title="Conversione Batch - Informazioni" \
        --text="<b>Modalità Batch</b>\n\nInserisci i video nel formato:\nVIDEO_ID | TITOLO | AUTORE\n\nUna riga per video.\n\n<b>Esempio:</b>\ndQw4w9WgXcQ | Tutorial Linux | Edmond\naBC123xYz00 | Bash Guide | TechChannel" 2>/dev/null
    
    # Input multiplo con formato strutturato
    BATCH_INPUT=$(zenity --text-info \
        --title="Conversione Batch - Inserisci Video" \
        --width=700 --height=400 \
        --editable \
        --text="Inserisci un video per riga nel formato:\nVIDEO_ID | TITOLO | AUTORE\n\nEsempio:\ndQw4w9WgXcQ | Tutorial Linux | Edmond\naBC123xYz00 | Bash Scripting | TechChannel\n" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$BATCH_INPUT" ]; then
        return
    fi
    
    # Conta righe valide
    VIDEO_COUNT=$(echo "$BATCH_INPUT" | grep -c "|")
    
    if [ $VIDEO_COUNT -eq 0 ]; then
        zenity --error --width=400 \
            --title="Errore" \
            --text="Nessuna riga valida trovata!\n\nUsa il formato:\nVIDEO_ID | TITOLO | AUTORE" 2>/dev/null
        return
    fi
    
    # Selezione formato
    FORMAT=$(zenity --list --radiolist \
        --title="Formato Output Batch" \
        --width=500 --height=350 \
        --column="" --column="Formato" \
        TRUE "standard" \
        FALSE "simple" \
        FALSE "table" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        FORMAT="standard"
    fi
    
    # Salva file output
    BATCH_FILE=$(zenity --file-selection --save \
        --title="Salva File Batch" \
        --filename="youtube-videos.md" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$BATCH_FILE" ]; then
        return
    fi
    
    # Processa batch
    > "$BATCH_FILE"
    echo "# Video YouTube" >> "$BATCH_FILE"
    echo "" >> "$BATCH_FILE"
    
    if [ "$FORMAT" = "table" ]; then
        echo "| Video | Autore |" >> "$BATCH_FILE"
        echo "|-------|--------|" >> "$BATCH_FILE"
    fi
    
    local count=0
    local total=$VIDEO_COUNT
    local errors=0
    
    (
        while IFS='|' read -r video_id title author; do
            # Pulisci spazi
            video_id=$(echo "$video_id" | xargs)
            title=$(echo "$title" | xargs)
            author=$(echo "$author" | xargs)
            
            # Salta righe vuote o commenti
            [[ -z "$video_id" ]] && continue
            [[ "$video_id" =~ ^# ]] && continue
            
            count=$((count + 1))
            percentage=$((count * 100 / total))
            echo "$percentage"
            echo "# Elaborazione video $count di $total..."
            
            # Estrai video ID se è un URL
            VIDEO_ID=$(extract_video_id "$video_id")
            
            if [ -z "$VIDEO_ID" ]; then
                errors=$((errors + 1))
                continue
            fi
            
            # Usa titolo default se mancante
            if [ -z "$title" ]; then
                title="Video ${count}"
            fi
            
            if [ -z "$author" ]; then
                author="YouTube Channel"
            fi
            
            # Genera markdown
            VIDEO_TITLE="$title"
            VIDEO_AUTHOR="$author"
            VIDEO_URL="https://www.youtube.com/watch?v=${VIDEO_ID}"
            VIDEO_THUMBNAIL="https://img.youtube.com/vi/${VIDEO_ID}/hqdefault.jpg"
            
            case "$FORMAT" in
                "standard") 
                    echo "$(format_standard)" >> "$BATCH_FILE"
                    echo "" >> "$BATCH_FILE"
                    ;;
                "simple") 
                    echo "$(format_simple)" >> "$BATCH_FILE"
                    echo "" >> "$BATCH_FILE"
                    ;;
                "table")
                    echo "| [![${VIDEO_TITLE}](${VIDEO_THUMBNAIL})](${VIDEO_URL}) | ${VIDEO_AUTHOR} |" >> "$BATCH_FILE"
                    ;;
            esac
            
            sleep 0.2
        done <<< "$BATCH_INPUT"
        
        echo "100"
        echo "# Completato!"
    ) | zenity --progress --title="Conversione Batch..." --width=400 --auto-close 2>/dev/null
    
    local success=$((count - errors))
    
    if [ $errors -gt 0 ]; then
        zenity --warning --width=400 \
            --title="Batch Completato con Avvisi" \
            --text="✓ Convertiti $success video\n✗ $errors video con errori\n\nFile salvato in:\n${BATCH_FILE}" 2>/dev/null
    else
        zenity --info --width=400 \
            --title="Batch Completato!" \
            --text="✓ Convertiti $count video con successo!\n\nFile salvato in:\n${BATCH_FILE}" 2>/dev/null
    fi
}

# Finestra impostazioni
show_settings() {
    zenity --info --width=500 --height=300 \
        --title="Impostazioni" \
        --text="<b>YouTube to Markdown Converter v${VERSION}</b>\n\n<b>Formati disponibili:</b>\n\n• <b>Standard:</b> [![Title](thumbnail)](url)\n  Link con immagine cliccabile\n\n• <b>Simple:</b> [Title](url)\n  Solo link testuale\n\n• <b>Embed:</b> Codice HTML completo\n  Con iframe per embedding\n\n• <b>Table:</b> Formato tabella\n  Per elenchi organizzati\n\n• <b>Badge:</b> Con badge YouTube\n  Formato accattivante con shield.io" 2>/dev/null
}

# Finestra aiuto
show_help_dialog() {
    zenity --text-info \
        --title="Aiuto - YouTube to Markdown" \
        --width=700 --height=600 \
        --filename=<(cat << 'EOF'
═══════════════════════════════════════════════════════
   YouTube to Markdown Converter - Guida Completa
═══════════════════════════════════════════════════════

📌 COSA FA
-----------
Converte link di video YouTube in codice Markdown formattato
per README di GitHub e documentazione.

🎯 FORMATI SUPPORTATI
----------------------
• youtube.com/watch?v=VIDEO_ID
• youtu.be/VIDEO_ID
• youtube.com/shorts/VIDEO_ID
• youtube.com/embed/VIDEO_ID

📝 FORMATI OUTPUT
------------------
1. STANDARD
   [![Title](thumbnail)](url)
   → Link con immagine thumbnail cliccabile

2. SIMPLE
   [Title](url)
   → Solo link testuale senza immagine

3. EMBED
   Codice HTML completo con:
   • Tag <a> con immagine
   • Tag <iframe> per embedding

4. TABLE
   | Video | Autore |
   |-------|--------|
   | ...   | ...    |
   → Formato tabella Markdown

5. BADGE
   Con badge personalizzato shield.io
   → Aspetto professionale

🔧 OPZIONI QUALITÀ THUMBNAIL
------------------------------
• Default:  120x90 px   (leggera)
• Medium:   320x180 px  (bilanciata)
• High:     480x360 px  (consigliata)
• MaxRes:   1280x720 px (massima qualità)

💡 CONVERSIONE BATCH
---------------------
1. Seleziona "Conversione multipla (batch)"
2. Incolla tutti i link (uno per riga)
3. Scegli il formato
4. Salva il file .md con tutti i video

📋 CLIPBOARD
-------------
Il markdown può essere copiato automaticamente
nella clipboard per un rapido incolla.

Richiede: xclip o xsel
Installa con: sudo apt install xclip

🛠️ REQUISITI SISTEMA
----------------------
• curl      (download dati)
• zenity    (interfaccia grafica)
• jq        (opzionale, per parsing JSON)
• xclip/xsel (opzionale, per clipboard)

Installa tutto con:
sudo apt install curl zenity jq xclip

📚 ESEMPI USO
--------------
1. Singolo video per README:
   • Inserisci URL
   • Scegli formato "standard"
   • Copia in clipboard
   • Incolla nel README.md

2. Lista video in documentazione:
   • Usa "table" format
   • Ottieni tabella formattata

3. Video embedded in HTML:
   • Usa "embed" format
   • Copia codice HTML/iframe

🎓 TIPS
--------
• Per README GitHub usa formato "standard"
• Per documentazione semplice usa "simple"
• Per blog/siti web usa "embed"
• La qualità "high" è perfetta per GitHub

═══════════════════════════════════════════════════════
         Creato da Edmond - Licenza MIT
═══════════════════════════════════════════════════════
EOF
) 2>/dev/null
}

# Main
check_dependencies
main_gui
