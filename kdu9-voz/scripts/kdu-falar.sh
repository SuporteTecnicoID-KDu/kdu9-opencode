#!/bin/bash
# ==========================================================================
# Projeto          : Linux KDu9-Ion-Final-Rv4-AI (Index Data)
# Script           : kdu-falar.sh — Módulo central de VOZ do KDu9 (v2)
# Atualizado em    : 11/09/2026 — v2 nasce da HOMOLOGAÇÃO manual do KDu:
#                     voz oficial = mb-br1 + s150 + p35 + PONTUAÇÃO DO TEXTO.
#                     O ritmo vem da frase ser escrita pontuada (aspas "..." ,
#                     reticências ..., vírgulas , e siglas por extenso como
#                     "K.D.u." que o mbrola lê letra a letra). O usuário
#                     homologou o "jeito artesanal" (estilo A) após ouvir.
#                     Chega de "milhões de variáveis": voz = frase bem
#                     pontuada + índice fixo. Fácil de manter, fácil de ouvir.
# Desenvolvedores  : Index Data — www.indexdata.com.br
# ---------------------------------------------------------------------------
# USO (em qualquer script do KDu):
#   source /opt/Scripts/Progs/KDu9-Sw-Center/KDu9-Voz/kdu-falar.sh
#   kdu_falar "Bem-Vindo...Esta é a apresentação do Linux K.D.u..."
#
# O que resolve:
#   1. FONÉTICA: transcreve siglas/marcas p/ o "jeito KDu" — por extenso e
#      pontuado — para o mbrola br1 pronunciar certo (KDu9→"K.D.u. nove").
#   2. RITMO: a própria pontuação do texto vira pausa natural (reticências
#      = respiro; vírgula = quebra leve; ponto = corte). Sem -g, sem magia.
#   3. PARÂMETROS HOMOLOGADOS: voz oficial mb-br1, -s 150 -p 40 (afinado
#      pelo usuário; se perderem de novo, é só reproduzir esse comando).
# ==========================================================================

# --- 1. Transcrição fonética "jeito KDu" -----------------------------------
# O segredo (homologado): escrever siglas por extenso e pontuadas, para o
# mbrola br1 ler sozinho. Nada de truques do espeak nem dezenas de flags:
#   KDu9   → "Ka Dê u 9"  – "Ka" (K) + "De" (D) + "U" + "Nóve" (9), corrido
#   KDu    → "Ka Dê u"
#   LuO    → "Lu Ô"          – "Lu" natural + "Ô" aberto (nome do projeto)
#   Rv4-AI → "R I quatro, A I"
# IMPORTANTE (homologação): as FRASES devem vir bem pontuadas — aspas "___"
# dão corpo/pausa, reticências ... dão respiro, vírgula quebra leve. É essa
# pontuação (não flags do espeak) que faz o ritmo natural aprovado.
# ATENÇÃO fonética: NÃO usar pontos entre as letras ("Ka.De.u."). O ponto
# faz o leitor (espeak/Piper) soletrar cada letra separada ("K", "D", "u").
# Espaços simples dão a sílaba corrida natural — "Ka Dê u 9" lê como
# "cadeu-nove" fluido, que é a entonação que o usuário quer ouvir.
kdu_fonetizar() {
    local t="$*"
    # SANITIZAÇÃO: tira códigos de escape ANSI (ex. \x1b[7m reverse video que
    # pode vazar de logos/terminais corrompidos), seqüências 1337/iTerm e
    # caracteres de controle. ATENÇÃO: NÃO usar `tr -cd '[:print:]'` — em
    # UTF-8 multibyte ele apaga os acentos (Atenção→Ateno) e cortava as
    # palavras. Mantemos: tabs/novas-linhas + ASCII printável (0x20-0x7e) +
    # bytes >= 0x80 (ã, é, ç...). Linguagem dele (pt-br) exige acentuação.
    t=$(printf '%s' "$t" \
        | sed -e 's/\x1b\][^\x07]*\x07//g' \
              -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' \
        | tr -cd '\t\n\40-\176\200-\377' )
    # IDIOMAS ESTRANGEIROS (bug 27/09 08:42): a IAponding tudo em portugues,
    # as vezes deixa escapar ideograma/kanji ("minha自我介绍 oficial") ou
    # japones. O Cadu leria aquilo como "zi jie shao" — lixo falado. Remove
    # CJK/Hiragana/Katakana/Hangul/pontuacao CJK/fullwidth e SOBRA NADA de
    # pt-BR (o perl Unicode working, os acentos ficam intactos).
    if command -v perl >/dev/null 2>&1; then
        t=$(printf '%s' "$t" | perl -CSD -pe \
            's/[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}\x{3000}-\x{303F}\x{FF00}-\x{FFEF}]//g' \
            2>/dev/null || printf '%s' "$t")
        # a remocao deixa dois espacos ("minha oficial") e aspas orfas
        t=$(printf '%s' "$t" | tr -s ' ' | sed -e 's/""//g' -e 's/„//g')
    fi
    # MARKDOWN → texto falável (respostas do agente chegam com **negrito**,
    # *itálico*, `código`, links [texto](url), headers "#", listas "-"):
    # limpa TUDO para o Piper nunca ler "*" como "asterisco".
    t=$(printf '%s' "$t" | sed -E \
        -e 's/```[^`]*```//g' \
        -e 's/`([^`]*)`/\1/g' \
        -e 's/\[([^]]*)\]\([^)]*\)/\1/g' \
        -e 's/\*\*([^*]*)\*\*/\1/g' \
        -e 's/\*([^*]*)\*/\1/g' \
        -e 's/__([^_]*)__/\1/g' \
        -e 's/^[[:space:]]*#{1,6}[[:space:]]*//g' \
        -e 's/^[[:space:]]*[-*+][[:space:]]+//g' \
        -e 's/^[[:space:]]*&gt;/ /g' \
        -e 's/[[:space:]]+/ /g' \
        -e 's/^ //g' -e 's/ $//g' )
    # SÍMBOLOS/EMOJI → FORA DA FALA (pedido do Querino, 16/10): o Piper lia
    # setas (→), check (✅), emoji (🎉) e sinais como lixo ou silêncio. Aqui
    # removemos SÍMBOLO (So/Sk/Sm) e marcas (Cf/Cs/Co) e as faixas de
    # setas/emoji, MANTENDO letras, números e a pontuação de fala (.,!?;:'"-).
    if command -v perl >/dev/null 2>&1; then
        t=$(printf '%s' "$t" | perl -CSD -pe \
            's/[\p{So}\p{Sk}\p{Sm}\p{Cf}\p{Cs}\p{Co}\x{2190}-\x{21FF}\x{2300}-\x{27BF}\x{2B00}-\x{2BFF}\x{FE00}-\x{FE0F}\x{1F000}-\x{1FAFF}]//g' \
            2>/dev/null || printf '%s' "$t")
        t=$(printf '%s' "$t" | tr -s ' ' | sed -e 's/^ //' -e 's/ $//')
    fi
    # Marca/versões do projeto — fonética oficial do KDu: "KaDeu9" (escrito
    # JUNTO, como nas falas do Corretor de Falas) — é o tom que o Piper lê
    # correto. NUNCA espaçar "Ka Dê u 9" (vira "KaDiu9" emendado errado).
    t=$(printf '%s' "$t" | sed -E \
        -e 's/K\.D\.u\.?[[:space:]]*9/Ka Dê u 9/gI' \
        -e 's/KDu9_Bot/Ka Dê u 9 Bôt/gI' \
        -e 's/\bBot\b/Bôt/g' \
        -e 's/\bKDu\s*9\b/Ka Dê u 9/g' \
        -e 's/K\.D\.u\.?/KaDê u/gI' \
        -e 's/\bKDu\b/KaDê u/g' )
    # POSIX (sed) em vez de ${t//...} — dash (sh) não tem substituição
    # global e o Full.sh roda em dash: sem isso, NENHUMA voz saía nele.
    # Ordem importa (igual antes): Rv4-AI, Rv4, Rv3, Rv2, Rv por último.
    t=$(printf '%s' "$t" | sed \
        -e 's/LuO/Lu Ô/g' \
        -e 's/Rv4-AI/R I quatro, A I/g' \
        -e 's/Rv4/R I quatro/g' \
        -e 's/Rv3/R I três/g' \
        -e 's/Rv2/R I dois/g' \
        -e 's/Rv/R I/g')
    # ACENTO OBRIGATORIO em palavras que o Cadu lê ERRADO sem ele. Medido pelo
    # Querino (teste A/B de 4 variantes, 27/09): "Robô" com acento = correto;
    # "robo" sem acento = o Piper lê "Roubo" (vogal aberta). A persona do
    # Falar é escrita SEM acento (estilo KDu9) e o modelo copia o defeito —
    # entao o acento e devolvido AQUI, na fonetização, que é o ponto único.
    t=$(printf '%s' "$t" | sed -E \
        -e 's/\brobo\b/Robô/g' \
        -e 's/\brobos\b/Robôs/g' \
        -e 's/\brob\b/Rob/g' )
    # sigla AI lida BONITA e natural ("laia"? não — "A I" espaçado com vírgula);
    # IA (Inteligência Artificial) sai como "i. á." cortado e neutro (homologado — opção 3).
    # ACENTO QUE O MOTOR COME (20/10): o dono ouviu "Náo" onde era "Não".
    # Sem acento, "nao/estao/ja" saem com vogal errada e "esta" (verbo) sai
    # fechado. O texto dos scripts segue sem acento; quem devolve o acento
    # e' AQUI — ponto único da fala (pedido do dono: "corrige no corretor").
    t=$(printf '%s' "$t" | sed -E \
        -e 's/\bNao\b/Não/g'      -e 's/\bnao\b/não/g' \
        -e 's/\bEstao\b/Estão/g'   -e 's/\bestao\b/estão/g' \
        -e 's/\bJa\b/Já/g'        -e 's/\bja\b/já/g' \
        -e 's/\bnao esta\b/não está/g' -e 's/\bNao esta\b/Não está/g' \
        -e 's/\besta aberto\b/está aberto/g' \
        -e 's/\besta fechado\b/está fechado/g' )
    # ACENTO QUE O MOTOR COME (20/11): "voce" sem acento sai com tom errado
    # ("vôce" em vez de "você"); o dono ouviu e pediu para escrever "você"
    # com acento. Mesma regra do "robo"→"Robô": ponto único da fonetização.
    t=$(printf '%s' "$t" | sed -E \
        -e 's/\bVOCE\b/Você/g'    -e 's/\bVoce\b/Você/g' \
        -e 's/\bvoce\b/você/g' \
        -e 's/\bVOCES\b/Vocês/g'  -e 's/\bVoces\b/Vocês/g' \
        -e 's/\bvoces\b/vocês/g' )
    t=$(printf '%s' "$t" | sed -E 's/\bAI\b/A I/g; s/\bIA\b/i. á./g')
    # separa apenas dígito colado em letra (4K → 4 K; v8.5 → v 8.5)
    t=$(printf '%s' "$t" | sed -E 's/([A-Za-z])([0-9])/\1 \2/g')
    printf '%s' "$t"
}

# --- 2b. Emoção do KDu-Bot pelo TEXTO da fala ------------------------------
# O kdu-falar detecta palavras-chave da frase e grava a emoção que o bot
# deve mostrar: lista = "palavra-chave:emoção". A ordem importa: mais
# específica (erro) primeiro; "saudacao" tem prioridade sobre "feliz".
# Falha segura: nada casa → "neutro".
kdu_emocao() {
    local f=$(printf '%s' "$*" | tr '[:upper:]' '[:lower:]')
    local regra par chave emo
    # regras: padrão:emoção (grep -E no texto). Ordem prioritária:
    # erro e saudacao primeiro (mais específicos/expressivos), depois
    # pensando, depois feliz, e triste por último (mais raro).
    for regra in \
        "erro:erro" "falh:erro" "proble:erro" "inválid:erro" "invalid:erro" \
        "atenç:erro" "atenc:erro" "cuidad:erro" "não deu:erro" "nao deu:erro" \
        "impedid:erro" "bloquead:erro" "negad:erro" "não foi possível:erro" \
        "bom dia:saudacao" "boa tarde:saudacao" "boa noite:saudacao" \
        "bem-?vindo:saudacao" "olá:saudacao" "ola:saudacao" "saudaç:saudacao" \
        "saudac:saudacao" \
        "analisando:pensando" "verificando:pensando" "aguarde:pensando" \
        "um momento:pensando" "processando:pensando" "calculando:pensando" \
        "pensando:pensando" "carregando:pensando" "buscando:pensando" \
        "espera ai:pensando" "um instante:pensando" \
        "ótimo:feliz" "otimo:feliz" "perfeito:feliz" "excelente:feliz" \
        "funcionou:feliz" "legal:feliz" "show:feliz" "parabéns:feliz" \
        "parabens:feliz" "que bom:feliz" "obrigado:feliz" "muito bem:feliz" \
        "desculpe:triste" "lamento:triste" "infelizmente:triste" \
        "não consegui:triste" "nao consegui:triste" "triste:triste" "falhou:triste" \
    ; do
        par="${regra%%:*}"; emo="${regra##*:}"
        if printf '%s' "$f" | grep -Eq "$par"; then
            printf '%s' "$emo"
            return 0
        fi
    done
    printf '%s' "neutro"
    return 0
}

# --- 2. Motor de voz (homologado — sem milhões de variáveis) ---------------
# PARÂMETROS OFICIAIS: voz mb-br1, velocidade 150, tom 35. Ritmo vem da
# PONTUAÇÃO da frase (é o que o KDu aprovou ouvindo — estilo A artesanal).
kdu_falar() {
    # REFERENCIA DE ECO (01/11/2026): TODA fala do sistema passa por aqui.
    # Guardar o texto (e a hora) permite ao Comandos de Voz reconhecer a
    # propria fala quando a transcricao chega atrasada (kdu9-eco.py).
    printf '%s' "${1:-}" > /tmp/kdu9-falando-texto 2>/dev/null
    date +%s > /tmp/kdu9-falando-texto.ts 2>/dev/null
    local TXT; TXT=$(kdu_fonetizar "$1")
    local VOZ="${2:-${KDU_VOZ:-mb-br1}}"
    local KDU_RUN="${KDU_RUN_DIR:-/run/user/$(id -u)}"
    # KDu-Bot de desktop: TODA voz do sistema garante o bot no ar (ele
    # reage em tempo real ao som vindo do alto-falante). Inicia se preciso.
    # --sem-focar (18/10): NAO trazer a janela para frente aqui. O foco
    # custa 1,4 s (kdu9-focar-janela.sh: sleeps fixos p/ o KWin carregar o
    # script) e isto roda em TODA frase -> era o "2 s de silencio" antes de
    # cada resposta. O Bot e' keep_above (ja' esta' na frente). Quem QUER
    # abrir a janela e' o botao 26 do Painel, que chama sem esta flag.
    # KDu-Bot de desktop: só no KDu9. KDU_SEM_BOT=1 desliga (máquina de
    # third-party, onde o bot não existe e só atrasaria cada frase).
    if [ "${KDU_SEM_BOT:-0}" != "1" ]; then
        [ -x /opt/Scripts/Progs/KDu9-Sw-Center/KDu9-Bot/KDu9-Bot.sh ] \
            && /opt/Scripts/Progs/KDu9-Sw-Center/KDu9-Bot/KDu9-Bot.sh --iniciar --sem-focar >/dev/null 2>&1
    fi
    # KDu-Bot de desktop: enquanto o KDu fala, o bot "dança" (flag) e
    # mostra o TEXTO + EMOÇÃO detectada da frase. Quando a voz sai pelo
    # DAEMON TTS, é o PRÓPRIO DAEMON que liga/desliga a flag conforme o
    # áudio REAL toca/termina (sincronia exata — nada de estimativa que
    # deixava a boca mexendo depois do som). Aqui só gravamos o texto e a
    # emoção; o acendimento da flag fica com o dono do som (no fallback a
    # estimativa por texto é feita logo abaixo, nos casos sem daemon).
    printf '%s' "$1" > /tmp/kdu9-bot-texto 2>/dev/null
    # HISTORICO (8 ultimas falas): o anti-eco do Falar compara a frase ouvida
    # com TUDO que o Bot falou ha' pouco. O eco junta duas falas e a ultima
    # sozinha nao acusava (21/10: apresentacao + "mic ativo" virou "fala").
    { printf '%s\n' "$1" >> /tmp/kdu9-bot-texto-hist 2>/dev/null
      tail -n 8 /tmp/kdu9-bot-texto-hist > /tmp/kdu9-bot-texto-hist.tmp 2>/dev/null \
          && mv -f /tmp/kdu9-bot-texto-hist.tmp /tmp/kdu9-bot-texto-hist 2>/dev/null; } 2>/dev/null
    printf '%s' "$(kdu_emocao "$1")" > /tmp/kdu9-bot-emocao 2>/dev/null
    # Uma voz por vez: se outro painel está falando, é cortado (evita eco/sobreposição)
    pkill -f 'espeak -v' 2>/dev/null
    # --- Daemon TTS residente (Piper quente, ~0,3s/frase) ------------------
    # Carrega o modelo 1x e fica no FIFO. Mata o gargalo de recarregar o
    # ONNX de 63MB a cada fala (que custava 5-7s). Se não estiver ativo,
    # sobe o daemon e espera até ele sinalizar pronto.
    # PORTÁVEL: venv/daemon do KDU_VOZ_HOME; se não houver, aproveita o KDu9.
    local KDU_HOME="${KDU_VOZ_HOME:-$HOME/.local/share/kdu9-voz}"
    local KDU_VENV="${KDU_VOZ_VENV:-$KDU_HOME/venv/bin/python}"
    local DAEMON="${KDU_VOZ_DAEMON:-$KDU_HOME/kdu-tts-daemon.py}"
    if [ ! -x "$KDU_VENV" ] && [ -x /opt/Scripts/Progs/KDu9-Sw-Center/KDu9-Voz/venv/bin/python ]; then
        KDU_VENV=/opt/Scripts/Progs/KDu9-Sw-Center/KDu9-Voz/venv/bin/python
        DAEMON=/opt/Scripts/Progs/KDu9-Sw-Center/KDu9-Voz/kdu-tts-daemon.py
    fi
    if [ -x "$KDU_VENV" ] && [ -f "$DAEMON" ]; then
        local pronto=0
        # sobe UM daemon se nenhum estiver ativo (trava mkdir = atômica).
        # O dono da trava SEGURA até o pid aparecer (modelo leva ~8s); quem
        # chega junto espera o pid em vez de subir gêmeo. Só o dono solta.
        if ! { [ -f $KDU_RUN/kdu9-tts.pid ] \
               && kill -0 "$(cat $KDU_RUN/kdu9-tts.pid 2>/dev/null)" 2>/dev/null; }; then
            if mkdir $KDU_RUN/kdu9-tts.lock 2>/dev/null; then
                setsid "$DAEMON" >/dev/null 2>&1 &
                for _w in $(seq 1 8); do
                    [ -f $KDU_RUN/kdu9-tts.pid ] \
                    && kill -0 "$(cat $KDU_RUN/kdu9-tts.pid 2>/dev/null)" 2>/dev/null && break
                    sleep 1
                done
                rmdir $KDU_RUN/kdu9-tts.lock 2>/dev/null
            else
                for _w in $(seq 1 8); do
                    [ -f $KDU_RUN/kdu9-tts.pid ] \
                    && kill -0 "$(cat $KDU_RUN/kdu9-tts.pid 2>/dev/null)" 2>/dev/null && break
                    sleep 1
                done
            fi
        fi
        for i in $(seq 1 4); do
            if [ -f $KDU_RUN/kdu9-tts.pid ] \
               && kill -0 "$(cat $KDU_RUN/kdu9-tts.pid 2>/dev/null)" 2>/dev/null; then
                pronto=1; break
            fi
            sleep 1
        done
        if [ "$pronto" = "1" ] && [ -p $KDU_RUN/kdu9-tts.fifo ]; then
            printf '%s\n' "$TXT" > $KDU_RUN/kdu9-tts.fifo 2>/dev/null
            printf '%s\n' "piper-daemon" > /tmp/kdu9-voz-motor 2>/dev/null
            return 0
        fi
    fi
    local ONNX="${KDU_VOZ_ONNX:-$KDU_HOME/pt_BR-cadu-medium.onnx}"
    if [ -x "$KDU_VENV" ] && [ -n "$ONNX" ] && "$KDU_VENV" -c 'import piper' >/dev/null 2>&1; then
        printf '%s' "$TXT" | "$KDU_VENV" -m piper \
            --model "$ONNX" --length_scale "${KDU_RITMO:-1.8}" --noise_scale 0.2 --noise_w_scale 0.3 \
            -f /tmp/kdu-fala.wav 2>/dev/null || return 1
        touch /tmp/kdu9-bot-fala 2>/dev/null
        (paplay --volume=65536 /tmp/kdu-fala.wav 2>/dev/null || aplay /tmp/kdu-fala.wav 2>/dev/null) &
        ( sleep $(( ${#TXT} / 8 + 1 )); rm -f /tmp/kdu9-bot-fala ) &
        printf '%s\n' "piper-venv" > /tmp/kdu9-voz-motor 2>/dev/null
        return 0
    fi
    if command -v piper >/dev/null 2>&1 && [ -n "$ONNX" ]; then
        local M; M="$ONNX"
        printf '%s' "$TXT" | piper --model "$M" --length_scale "${KDU_RITMO:-1.8}" --noise_scale 0.2 --noise_w_scale 0.3 \
            --output_file /tmp/kdu-fala.wav 2>/dev/null || return 1
        touch /tmp/kdu9-bot-fala 2>/dev/null
        (paplay --volume=65536 /tmp/kdu-fala.wav 2>/dev/null || aplay /tmp/kdu-fala.wav 2>/dev/null) &
        ( sleep $(( ${#TXT} / 8 + 1 )); rm -f /tmp/kdu9-bot-fala ) &
        printf '%s\n' "piper" > /tmp/kdu9-voz-motor 2>/dev/null
        return 0
    fi
    # --- FALLBACK LEVE (skill portátil) -------------------------------------
    # Sem Piper (venv/modelo ausente), cai no espeak-ng pt-BR. No KDu9 o
    # padrão NÃO é usar espeak (lá a fala seria pulada): KDU_SEM_FALLBACK=1
    # mantém o comportamento original deste script.
    if [ "${KDU_SEM_FALLBACK:-0}" != "1" ] && command -v espeak-ng >/dev/null 2>&1; then
        local WAV="/tmp/kdu-fala.wav"
        local VZ
        for VZ in mb-br1 brazil-mbrola-1 pt-br; do
            espeak-ng -v "$VZ" -s 150 -p 40 -w "$WAV" "$TXT" 2>/dev/null || continue
            [ -s "$WAV" ] || continue
            touch /tmp/kdu9-bot-fala 2>/dev/null
            (paplay --volume=65536 "$WAV" 2>/dev/null || aplay "$WAV" 2>/dev/null) &
            ( sleep $(( ${#TXT} / 8 + 1 )); rm -f /tmp/kdu9-bot-fala ) &
            printf '%s\n' "espeak:$VZ" > /tmp/kdu9-voz-motor 2>/dev/null
            return 0
        done
    fi
    # Sem espeak: se a voz Cadu nao subir, a fala e' pulada (nunca outra voz).
    return 1
}
