#!/usr/bin/env bash
# ==========================================================================
# KDu9 Voz — CLI portátil da skill kdu9-voz
# Uso:
#   kdu9-voz.sh falar "texto"     fala o texto (fonetizado) pelo speaker
#   kdu9-voz.sh teste             fala uma frase de teste
#   kdu9-voz.sh status            mostra o motor em uso e o estado
#   kdu9-voz.sh parar             derruba o daemon TTS
#
# O agente do OpenCode usa só o "falar". O motor é escolhido nesta ordem:
#   1. KDU_FALAR (caminho explícito)
#   2. motor do KDu9  (/opt/Scripts/.../kdu-falar.sh) — com bot de desktop
#   3. motor portátil  ($KDU_VOZ_HOME/kdu-falar.sh)     — sem bot
#   4. sem motor: avisa para rodar instalar.sh
# ==========================================================================
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KDU9_FALAR="/opt/Scripts/Progs/KDu9-Sw-Center/KDu9-Voz/kdu-falar.sh"
KDU_VOZ_HOME="${KDU_VOZ_HOME:-$HOME/.local/share/kdu9-voz}"
PORTATIL="$KDU_VOZ_HOME/kdu-falar.sh"

motor() {
    if [ -n "${KDU_FALAR:-}" ] && [ -f "$KDU_FALAR" ]; then printf '%s' "$KDU_FALAR"; return 0; fi
    if [ -x "$KDU9_FALAR" ]; then printf '%s' "$KDU9_FALAR"; return 0; fi
    if [ -f "$PORTATIL" ]; then printf '%s' "$PORTATIL"; return 0; fi
    return 1
}

falar() {
    local m; m="$(motor)" || {
        printf 'sem motor de voz. rode: bash "%s/instalar.sh"\n' "$SKILL_DIR" >&2
        return 1
    }
    local sem_bot=0
    [ "$m" = "$KDU9_FALAR" ] || sem_bot=1
    (
        . "$m"
        [ "$sem_bot" = "1" ] && export KDU_SEM_BOT=1
        kdu_falar "$*"
    )
}

status() {
    local m; if m="$(motor)"; then printf 'motor : %s\n' "$m"; else printf 'motor : nenhum (rode instalar.sh)\n'; fi
    printf 'home  : %s\n' "$KDU_VOZ_HOME"
    printf 'modelo: %s\n' "$([ -s "$KDU_VOZ_HOME/pt_BR-cadu-medium.onnx" ] && echo presente || echo ausente)"
    printf 'daemon: %s\n' "$(pgrep -af kdu-tts-daemon.py | head -1 || echo parado)"
    printf 'espeak: %s\n' "$(command -v espeak-ng || echo ausente)"
    printf 'ultimo: %s\n' "$(cat /tmp/kdu9-voz-motor 2>/dev/null || echo -)"
}

parar() {
    local fifo="/run/user/$(id -u)/kdu9-tts.fifo"
    if [ -p "$fifo" ]; then printf '__QUIT__\n' > "$fifo" 2>/dev/null; printf 'daemon TTS encerrado.\n'
    else printf 'daemon TTS ja estava parado.\n'; fi
}

case "${1:-}" in
    falar)  shift; falar "$*" ;;
    teste)  falar "Teste de voz. Você está ouvindo o KDu9 Voz." ;;
    status) status ;;
    parar)  parar ;;
    *)      printf 'uso: %s {falar "texto"|teste|status|parar}\n' "${0##*/}" >&2; exit 2 ;;
esac
