# Yt2md-Converter YouTube to Markdown Converter

Convert YouTube video links to formatted Markdown code for GitHub README files
---
---

[English](#english) | [Italiano](#italiano)

---
---

<img width="512" height="512" alt="yt2md-icon" src="https://github.com/user-attachments/assets/b48b5be7-24c4-41e5-949f-1f30826c7636" />

---
---
## English
---
---

### Description

A comprehensive suite of tools to convert YouTube video links into formatted Markdown code, perfect for technical documentation, GitHub README files, and blogs.

**Available in 4 versions:**
- Simple CLI
- GUI with graphical interface (recommended)
- Offline CLI with options
- Advanced CLI


### Installation

**Requirements:**
- None for CLI versions
- `zenity` and `xclip` for GUI version

**Installation:**
```bash
git clone https://github.com/fconidi/Yt2md-Converter
cd yt2md
bash yt2md.sh --help
```

### Usage

### Quick Start

```bash
bash yt2md.sh VIDEO_ID "TITLE" "AUTHOR"
```

**Output:**
```markdown
[![TITLE](thumbnail)](url)
```



#### 1. yt2md.sh - Simple CLI

```bash
bash yt2md.sh VIDEO_ID "TITLE" ["AUTHOR"]
```

**Options:**
```bash
-f FORMAT    Output format: standard|simple|table|embed
-s SIZE      Thumbnail quality: default|medium|high|maxres
-o FILE      Save to file
-h           Show help
```

**Examples:**
```bash
# Basic
bash yt2md.sh dQw4w9WgXcQ "Linux Tutorial"

# With author
bash yt2md.sh dQw4w9WgXcQ "Tutorial" "Channel Name"

# Table format
bash yt2md.sh -f table dQw4w9WgXcQ "Video" "Author"

# Save to file
bash yt2md.sh -o output.md VIDEO_ID "Title" "Author"
```

#### 2. yt2md-gui.sh - Graphical Interface (Recommended)

```bash
bash yt2md-gui.sh
```

**Features:**
- Step-by-step guided dialogs
- Input validation
- Multiple output formats
- Clipboard integration
- Batch conversion
- Built-in help

**Batch format:**
```
VIDEO_ID | TITLE | AUTHOR
```

#### 3. yt2md-offline.sh - Alternative CLI

```bash
bash yt2md-offline.sh -t "TITLE" -a "AUTHOR" VIDEO_ID
```

#### 4. yt2md-cli.sh - Advanced CLI

```bash
bash yt2md-cli.sh --offline --title "TITLE" --author "AUTHOR" VIDEO_ID
```

### Output Formats

**Standard (Default):**
```markdown
[![Title](thumbnail)](url)
```

**Simple:**
```markdown
[Title](url)
```

**Table:**
```markdown
| Video | Author |
|-------|--------|
| [![Title](thumb)](url) | Author |
```

**Embed:**
```html
<a href="url"><img src="thumb" alt="Title" width="480"></a>
<iframe width="560" height="315" src="embed_url"></iframe>
```

### Extract Video ID

From YouTube URL:

```
https://www.youtube.com/watch?v=dQw4w9WgXcQ → dQw4w9WgXcQ
https://youtu.be/dQw4w9WgXcQ → dQw4w9WgXcQ
https://youtube.com/shorts/dQw4w9WgXcQ → dQw4w9WgXcQ
```

### Automation

**Bash Alias:**
```bash
# Add to ~/.bashrc
alias ytm='bash /path/to/yt2md.sh'
```

**Helper Script:**
```bash
#!/bin/bash
VIDEO_ID="$1"
TITLE="$2"
AUTHOR="${3:-MyChannel}"
bash yt2md.sh "$VIDEO_ID" "$TITLE" "$AUTHOR" >> README.md
```

**Batch Processing:**
```bash
while IFS='|' read -r id title author; do
    bash yt2md.sh "$id" "$title" "$author"
done < videos.txt
```

### Testing

```bash
bash test-all.sh
```


### Troubleshooting

**Script doesn't work:**
```bash
# Always use: bash script.sh
bash yt2md.sh VIDEO_ID "TITLE"
```

**GUI doesn't open:**
```bash
# Install zenity
sudo apt install zenity
```

**Empty output:**
```bash
# Verify syntax - use quotes for titles with spaces
bash yt2md.sh VIDEO_ID "Title with spaces" "Author"
```

### Documentation

| File | Description |
|------|-------------|
| README.md | This file |
| test-all.sh | Automated tests |

### License

MIT License - See LICENSE file for details

### Author

Franco Conidi aka Edmond - SysLinuxOS System Integrator, Network Engineer, IT Consultant, Blogger, Linux Developer https://francoconidi.it https://syslinuxos.com

---
---
---
## Italiano
---
---
---
### Descrizione

Suite completa di strumenti per convertire link di video YouTube in codice Markdown formattato, perfetto per documentazione tecnica, file README di GitHub e blog.

**Disponibile in 4 versioni:**
- CLI semplice
- GUI con interfaccia grafica (consigliato)
- CLI offline con opzioni
- CLI avanzato


### Installazione

**Requisiti:**
- Nessuno per le versioni CLI
- `zenity` e `xclip` per la versione GUI

**Installazione:**
```bash
git clone https://github.com/fconidi/Yt2md-Converter
cd yt2md
bash yt2md.sh --help
```

### Utilizzo

### Avvio Rapido

```bash
bash yt2md.sh VIDEO_ID "TITOLO" "AUTORE"
```

**Output:**
```markdown
[![TITOLO](thumbnail)](url)
```

#### 1. yt2md.sh - CLI Semplice

```bash
bash yt2md.sh VIDEO_ID "TITOLO" ["AUTORE"]
```

**Opzioni:**
```bash
-f FORMAT    Formato output: standard|simple|table|embed
-s SIZE      Qualità thumbnail: default|medium|high|maxres
-o FILE      Salva su file
-h           Mostra aiuto
```

**Esempi:**
```bash
# Base
bash yt2md.sh dQw4w9WgXcQ "Tutorial Linux"

# Con autore
bash yt2md.sh dQw4w9WgXcQ "Tutorial" "Nome Canale"

# Formato tabella
bash yt2md.sh -f table dQw4w9WgXcQ "Video" "Autore"

# Salva su file
bash yt2md.sh -o output.md VIDEO_ID "Titolo" "Autore"
```

#### 2. yt2md-gui.sh - Interfaccia Grafica (Consigliato)

```bash
bash yt2md-gui.sh
```

**Funzionalità:**
- Dialog guidati passo-passo
- Validazione input
- Formati multipli
- Integrazione clipboard
- Conversione batch
- Aiuto integrato

**Formato batch:**
```
VIDEO_ID | TITOLO | AUTORE
```

#### 3. yt2md-offline.sh - CLI Alternativa

```bash
bash yt2md-offline.sh -t "TITOLO" -a "AUTORE" VIDEO_ID
```

#### 4. yt2md-cli.sh - CLI Avanzato

```bash
bash yt2md-cli.sh --offline --title "TITOLO" --author "AUTORE" VIDEO_ID
```

### Formati Output

**Standard (Default):**
```markdown
[![Titolo](thumbnail)](url)
```

**Simple:**
```markdown
[Titolo](url)
```

**Table:**
```markdown
| Video | Autore |
|-------|--------|
| [![Titolo](thumb)](url) | Autore |
```

**Embed:**
```html
<a href="url"><img src="thumb" alt="Titolo" width="480"></a>
<iframe width="560" height="315" src="embed_url"></iframe>
```

### Estrarre Video ID

Da URL YouTube:

```
https://www.youtube.com/watch?v=dQw4w9WgXcQ → dQw4w9WgXcQ
https://youtu.be/dQw4w9WgXcQ → dQw4w9WgXcQ
https://youtube.com/shorts/dQw4w9WgXcQ → dQw4w9WgXcQ
```

### Automazione

**Alias Bash:**
```bash
# Aggiungi a ~/.bashrc
alias ytm='bash /percorso/yt2md.sh'
```

**Script Helper:**
```bash
#!/bin/bash
VIDEO_ID="$1"
TITOLO="$2"
AUTORE="${3:-MioCanale}"
bash yt2md.sh "$VIDEO_ID" "$TITOLO" "$AUTORE" >> README.md
```

**Elaborazione Batch:**
```bash
while IFS='|' read -r id titolo autore; do
    bash yt2md.sh "$id" "$titolo" "$autore"
done < video.txt
```

### Test

```bash
bash test-all.sh
```

### Risoluzione Problemi

**Lo script non funziona:**
```bash
# Usa sempre: bash script.sh
bash yt2md.sh VIDEO_ID "TITOLO"
```

**La GUI non si apre:**
```bash
# Installa zenity
sudo apt install zenity
```

**Output vuoto:**
```bash
# Verifica sintassi - usa virgolette per titoli con spazi
bash yt2md.sh VIDEO_ID "Titolo con spazi" "Autore"
```

### Documentazione

| File | Descrizione |
|------|-------------|
| README.md | Questo file |
| test-all.sh | Test automatici |

### Licenza

MIT License - Vedi file LICENSE per dettagli

### Autore

Franco Conidi aka Edmond - SysLinuxOS System Integrator, Network Engineer, IT Consultant, Blogger, Linux Developer https://francoconidi.it https://syslinuxos.com


### System Requirements

**Operating Systems:**
- Linux (all distributions)
- macOS (bash 4.0+)
- Windows (WSL/Git Bash)

**Shell:**
- bash >= 4.0

**Optional Dependencies:**
- zenity (for GUI)
- xclip (for clipboard support)

### Architecture

**Core Components:**
- Video ID parser
- URL builder
- Markdown formatter
- CLI argument parser
- GUI dialog manager

**Supported URL Formats:**
- `youtube.com/watch?v=ID`
- `youtu.be/ID`
- `youtube.com/shorts/ID`
- `youtube.com/embed/ID`
- Direct ID (11 characters)

**Thumbnail Qualities:**
- default: 120x90px
- medium: 320x180px
- high: 480x360px
- maxres: 1280x720px

### Testing

**Test Coverage:**
- Format tests: standard, simple, table, embed
- Input tests: Video ID, various URL formats
- Output tests: stdout, file
- Mode tests: online, offline

**Run Tests:**
```bash
bash test-all.sh
```

### Use Cases

**1. Documentation Integration:**
```bash
bash yt2md.sh VIDEO_ID "Tutorial Title" >> docs/videos.md
```

**2. README Generation:**
```bash
echo "## Video Tutorials" >> README.md
bash yt2md.sh VID1 "Intro" "Author" >> README.md
bash yt2md.sh VID2 "Setup" "Author" >> README.md
```

**3. Blog Post Embedding:**
```bash
bash yt2md.sh -f embed VIDEO_ID "Title" > post-video.html
```

**4. Batch Documentation:**
```bash
for video in $(cat video-list.txt); do
    bash yt2md.sh $video "Tutorial" "Channel"
done
```

### Known Limitations

1. **Offline Mode:**
   - Manual title/author input required
   - No video existence verification

2. **Metadata:**
   - No duration extraction
   - No view count
   - No publish date

3. **Thumbnails:**
   - Fixed URLs (no availability check)
   - MaxRes might not exist for old videos

---

## Links

- **Repository:** https://github.com/fconidi/Yt2md-Converter
- **Issues:** https://github.com/fconidi/Yt2md-Converter/issues
- **Documentation:** See docs/ folder
- **Changelog:** CHANGELOG.md

---

**Author:** Franco Conidi aka Edmond - SysLinuxOS System Integrator, Network Engineer, IT Consultant, Blogger, Linux Developer https://francoconidi.it https://syslinuxos.com

---
