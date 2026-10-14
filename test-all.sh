#!/bin/bash

#########################################################
# Test Completo - Tutti gli Script
#########################################################

echo "╔════════════════════════════════════════════════╗"
echo "║   TEST COMPLETO - YouTube to Markdown         ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0

# Funzione di test
test_script() {
    local name="$1"
    local script="$2"
    shift 2
    local args="$@"
    
    echo -n "Testing $name... "
    
    if output=$(bash "$script" $args 2>&1); then
        if [[ -n "$output" ]] && [[ "$output" != *"error"* ]] && [[ "$output" != *"Error"* ]]; then
            echo "✓ PASS"
            PASS=$((PASS + 1))
            return 0
        fi
    fi
    
    echo "✗ FAIL"
    FAIL=$((FAIL + 1))
    return 1
}

echo "━━━ TEST 1: yt2md.sh (VERSIONE CONSIGLIATA) ━━━"
echo ""

test_script "Standard format" "yt2md.sh" "dQw4w9WgXcQ" "Test Video" "Test Author"
test_script "Simple format" "yt2md.sh" "-f simple" "dQw4w9WgXcQ" "Test Video"
test_script "Table format" "yt2md.sh" "-f table" "dQw4w9WgXcQ" "Test Video" "Author"
test_script "URL completo" "yt2md.sh" "https://youtube.com/watch?v=dQw4w9WgXcQ" "Test"

echo ""
echo "━━━ TEST 2: yt2md-offline.sh ━━━"
echo ""

test_script "Offline standard" "yt2md-offline.sh" "-t" "Test Title" "-a" "Author" "dQw4w9WgXcQ"
test_script "Offline simple" "yt2md-offline.sh" "-f simple" "-t" "Test" "dQw4w9WgXcQ"

echo ""
echo "━━━ TEST 3: yt2md-cli.sh (con --offline) ━━━"
echo ""

test_script "CLI offline mode" "yt2md-cli.sh" "--offline" "--title" "Test" "--author" "Auth" "dQw4w9WgXcQ"

echo ""
echo "━━━ TEST 4: Output su File ━━━"
echo ""

rm -f test-output.md 2>/dev/null

if bash yt2md.sh -o test-output.md "dQw4w9WgXcQ" "File Test" "Author" 2>/dev/null; then
    if [ -f test-output.md ] && [ -s test-output.md ]; then
        echo "File output... ✓ PASS"
        PASS=$((PASS + 1))
        cat test-output.md
    else
        echo "File output... ✗ FAIL"
        FAIL=$((FAIL + 1))
    fi
else
    echo "File output... ✗ FAIL"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "━━━ TEST 5: Formati Video ID ━━━"
echo ""

test_script "ID diretto" "yt2md.sh" "dQw4w9WgXcQ" "Test"
test_script "URL watch" "yt2md.sh" "https://youtube.com/watch?v=dQw4w9WgXcQ" "Test"
test_script "URL breve" "yt2md.sh" "https://youtu.be/dQw4w9WgXcQ" "Test"
test_script "URL shorts" "yt2md.sh" "https://youtube.com/shorts/dQw4w9WgXcQ" "Test"

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║              RISULTATI FINALI                  ║"
echo "╠════════════════════════════════════════════════╣"
echo "║  ✓ PASS: $PASS test                                 ║"
echo "║  ✗ FAIL: $FAIL test                                 ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "🎉 TUTTI I TEST SUPERATI!"
    echo ""
    echo "✅ SCRIPT FUNZIONANTI:"
    echo "  • yt2md.sh          (CONSIGLIATO - più semplice)"
    echo "  • yt2md-offline.sh  (alternativa)"
    echo "  • yt2md-cli.sh      (con --offline)"
    echo "  • yt2md-gui.sh      (interfaccia grafica) *"
    echo ""
    echo "  * Richiede zenity: sudo apt install zenity"
    echo ""
    echo "📝 USO CONSIGLIATO:"
    echo '  bash yt2md.sh VIDEO_ID "TITOLO" "AUTORE"'
    echo ""
    echo "🖥️  INTERFACCIA GRAFICA:"
    echo "  bash yt2md-gui.sh"
    echo "  (leggi GUIDA-GUI.md per dettagli)"
    echo ""
    exit 0
else
    echo "⚠️  Alcuni test falliti"
    echo "Usa gli script che hanno superato i test"
    exit 1
fi
