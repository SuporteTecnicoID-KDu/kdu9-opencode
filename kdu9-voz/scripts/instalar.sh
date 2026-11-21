#!/usr/bin/env bash
# ==========================================================================
# KDu9 Voz — instalar.sh
# Prepara o motor de voz na máquina de quem vai usar a skill kdu9-voz.
#
# Modos:
#   --modo completo   venv Piper + modelo Cadu (~330 MB) — voz natural
#   --modo leve       só os scripts + fallback espeak pt-BR (~0 MB extra)
#   --modo auto       pergunta se for interativo; senão, completo
#
#   --home DIR        onde instalar (padrão ~/.local/share/kdu9-voz)
#   --url URL         catálogo de onde baixar os scripts, se faltarem
#   --teste           fala uma frase de teste no fim
#   --limpar          limpa caches seguros (npm, OpenCode desktop, KDE, Firefox cache,
#                     shell/tool-output/log do OpenCode) antes/depois da instalação
#   --build           modo build: instala + limpa caches (equivale a --limpar)
#
# Seguro para rodar de novo: não sobrescreve modelo nem venv existentes.
# ==========================================================================
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_VOZ="${KDU_VOZ_HOME:-$HOME/.local/share/kdu9-voz}"
MODO="auto"
URL_CATALOGO="https://exemplo.com/opencode/skills/kdu9-voz/scripts"
TESTE=0
LIMPAR=0
MODELO_URL="https://huggingface.co/rhasspy/piper-voices/resolve/main/pt/pt_BR/cadu/medium/pt_BR-cadu-medium.onnx"

while [ $# -gt 0 ]; do
    case "$1" in
        --modo)   MODO="${2:?}"; shift 2 ;;
        --home)   HOME_VOZ="${2:?}"; KDU_VOZ_HOME="$HOME_VOZ"; shift 2 ;;
        --url)    URL_CATALOGO="${2:?}"; shift 2 ;;
        --teste)  TESTE=1; shift ;;
        --limpar) LIMPAR=1; shift ;;
        --build)  LIMPAR=1; shift ;;
        *) printf 'opcao desconhecida: %s\n' "$1" >&2; exit 2 ;;
    esac
done

diz() { printf '%s\n' "$*"; }

# --- limpeza de caches seguros (CaduCleaner/fu) -----------------------------
limpar_caches() {
    diz "limpando caches seguros (se existirem) ..."
    # npm
    if command -v npm >/dev/null 2>&1; then
        npm cache clean --force >/dev/null 2>&1 || true
        diz "  [ok] npm cache limpo"
    fi
    # OpenCode desktop (Electron) caches
    for d in \
        "$HOME/.config/ai.opencode.desktop/Cache" \
        "$HOME/.config/ai.opencode.desktop/Code Cache" \
        "$HOME/.config/ai.opencode.desktop/compile-cache" \
        "$HOME/.config/ai.opencode.desktop/GPUPersistentCache" \
        "$HOME/.config/ai.opencode.desktop/GPUCache"; do
        [ -d "$d" ] && rm -rf "$d" && diz "  [ok] removido: $d"
    done
    [ -d "$HOME/.config/ai.opencode.desktop/logs" ] && \
        rm -f "$HOME/.config/ai.opencode.desktop/logs/"* && diz "  [ok] logs do OpenCode desktop limpos"
    # KDE/system caches
    [ -d "$HOME/.cache" ] && rm -rf "$HOME/.cache"/* && diz "  [ok] ~/.cache limpo"
    # OpenCode session caches
    for d in \
        "$HOME/.local/share/opencode/shell" \
        "$HOME/.local/share/opencode/tool-output" \
        "$HOME/.local/share/opencode/log"; do
        [ -d "$d" ] && rm -rf "$d"/* && diz "  [ok] limpo: $d"
    done
    # Firefox caches (sem tocar extensões/temas/perfil)
    if [ -d "$HOME/.config/mozilla/firefox" ]; then
        for p in "$HOME/.config/mozilla/firefox"/*/; do
            for sub in cache2 startupCache thumbnails minidumps crashes saved-telemetry-pings; do
                [ -d "$p$sub" ] && rm -rf "$p$sub"/* 2>/dev/null
            done
        done
        rm -rf "$HOME/.config/mozilla/firefox/Pending Pings/"* \
               "$HOME/.config/mozilla/firefox/Crash Reports/"* 2>/dev/null
        diz "  [ok] caches do Firefox limpos (extensões/temas preservados)"
    fi
    diz "limpeza concluída."
}

# --- interativo: oferece a escolha (a ideia do dono: quem não quer 330 MB) --
if [ "$MODO" = "auto" ]; then
    if [ -t 0 ]; then
        printf 'Motor de voz:\n  1) completo — Piper + voz Cadu (~330 MB, natural)\n  2) leve     — fallback espeak pt-BR (quase 0 MB, mais robótico)\n'
        printf 'Escolha [1/2]: '
        read -r r < /dev/tty 2>/dev/null || read -r r
        case "$r" in 2) MODO="leve";; *) MODO="completo";; esac
    else
        MODO="completo"
    fi
fi

mkdir -p "$HOME_VOZ"

# --- 1. scripts do motor (da pasta da skill, ou do catálogo) ---------------
copiar_scripts() {
    local ok=1
    for f in kdu-falar.sh kdu-tts-daemon.py kdu9-voz.sh; do
        if [ -f "$SKILL_DIR/$f" ]; then
            cp -f "$SKILL_DIR/$f" "$HOME_VOZ/$f"
        elif [ -f "$URL_CATALOGO/$f" ]; then
            curl -fsSL --max-time 60 -o "$HOME_VOZ/$f" "$URL_CATALOGO/$f"
        else
            printf 'faltou %s (nem local, nem em %s)\n' "$f" "$URL_CATALOGO" >&2
            ok=0
        fi
    done
    chmod +x "$HOME_VOZ"/*.sh 2>/dev/null || true
    [ "$ok" = 1 ]
}

# --- 2. voz completa: venv Piper + modelo Cadu -----------------------------
instalar_completo() {
    if ! command -v python3 >/dev/null 2>&1; then
        diz "python3 não encontrado. Instale o Python 3.9+ e rode de novo."
        exit 1
    fi
    if [ ! -x "$HOME_VOZ/venv/bin/python" ]; then
        diz "criando venv em $HOME_VOZ/venv ..."
        python3 -m venv "$HOME_VOZ/venv"
    fi
    diz "instalando piper-tts no venv ..."
    "$HOME_VOZ/venv/bin/pip" install --quiet --upgrade pip
    "$HOME_VOZ/venv/bin/pip" install --quiet "piper-tts>=1.2"

    if [ ! -s "$HOME_VOZ/pt_BR-cadu-medium.onnx" ]; then
        diz "baixando o modelo Cadu (~61 MB) ..."
        curl -fL --max-time 900 --progress-bar \
            -o "$HOME_VOZ/pt_BR-cadu-medium.onnx" "$MODELO_URL"
    fi
    if [ ! -s "$HOME_VOZ/pt_BR-cadu-medium.onnx.json" ]; then
        curl -fsSL --max-time 120 \
            -o "$HOME_VOZ/pt_BR-cadu-medium.onnx.json" "$MODELO_URL.json" || \
            diz "(sem .json do modelo; o Piper tenta sem ele)"
    fi
    diz "motor completo pronto em $HOME_VOZ"
}

# --- 3. voz leve: fallback espeak pt-BR ------------------------------------
instalar_leve() {
    if ! command -v espeak-ng >/dev/null 2>&1; then
        diz "espeak-ng não encontrado. Instale o pacote do seu distro, ex.:"
        say_distro() { command -v "$1" >/dev/null 2>&1; }
        if say_distro apt-get; then diz "  sudo apt-get install espeak-ng mbrola mbrola-br1"
        elif say_distro dnf; then diz "  sudo dnf install espeak-ng"
        elif say_distro pacman; then diz "  sudo pacman -S espeak-ng"
        else diz "  (procure 'espeak-ng' no gerenciador de pacotes)"
        fi
    else
        diz "fallback espeak-ng detectado: $(espeak-ng --version 2>/dev/null)"
    fi
    diz "motor leve pronto em $HOME_VOZ (sem Piper, sem download)"
}

# --- limpar antes da instalação (se solicitado) ----------------------------
if [ "$LIMPAR" = 1 ]; then
    limpar_caches
fi

diz "KDu9 Voz — instalação ($MODO) em $HOME_VOZ"
copiar_scripts
case "$MODO" in
    completo) instalar_completo ;;
    leve)     instalar_leve ;;
    *)        diz "modo inválido: $MODO"; exit 2 ;;
esac

diz "para ver o estado:  bash $HOME_VOZ/kdu9-voz.sh status"

if [ "$TESTE" = 1 ]; then
    diz "teste de voz:"
    bash "$HOME_VOZ/kdu9-voz.sh" teste || diz "(teste falhou — veja o status acima)"
fi

# --- limpar depois da instalação (se solicitado) ---------------------------
if [ "$LIMPAR" = 1 ]; then
    diz "limpeza pós-instalação:"
    limpar_caches
fi