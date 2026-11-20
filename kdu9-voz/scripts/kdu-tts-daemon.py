#!/usr/bin/env python3
# ==========================================================================
# Projeto          : KDu9 Voz (skill portátil) — Linux KDu9-Ion-Final-Rv4-AI
# Script           : kdu-tts-daemon.py — Daemon TTS residente (Piper quente)
# Descrição        : Carrega o modelo Piper UMA única vez e fica aguardando
#                    texto num FIFO. Cada frase sintetiza em ~0,3s (o modelo
#                    fica residente), em vez de recarregar o ONNX de 63MB
#                    (~5-7s) a cada chamada. Mata o gargalo do "5s para falar".
# PORTÁVEL         : o modelo sai de KDU_VOZ_ONNX, ou de
#                    $KDU_VOZ_HOME/pt_BR-cadu-medium.onnx (~/.local/share/kdu9-voz).
# ==========================================================================
import os
import sys
import io
import time
import threading
import wave
import subprocess
import signal

# PID/fifo moram no dir do usuário (/run/user/UID), NÃO no /tmp: a rotina de
# limpeza do KDu9 varre o /tmp e apagava o pid com o daemon vivo → kdu_falar
# perdia 40s tentando ressuscitar o daemon. Sem sessão do sistema → /tmp.
RUN = os.path.join("/run/user", str(os.getuid()))
try:
    os.makedirs(RUN, mode=0o700, exist_ok=True)
    os.stat(RUN)
except OSError:
    RUN = "/tmp"
FIFO = os.path.join(RUN, "kdu9-tts.fifo")
PIDF = os.path.join(RUN, "kdu9-tts.pid")
WAV  = "/tmp/kdu-fala.wav"
# PORTÁVEL: KDU_VOZ_ONNX (caminho direto) > $KDU_VOZ_HOME/pt_BR-cadu-medium.onnx
# > caminho do KDu9. Sem modelo, o daemon não sobe e o kdu-falar cai no
# fallback (espeak) — a skill nunca fica muda.
_KDU_HOME = os.environ.get("KDU_VOZ_HOME", os.path.expanduser("~/.local/share/kdu9-voz"))
ONNX = (
    os.environ.get("KDU_VOZ_ONNX")
    or os.path.join(_KDU_HOME, "pt_BR-cadu-medium.onnx")
    or "/opt/Scripts/Progs/KDu9-Sw-Center/KDu9-Voz/pt_BR-cadu-medium.onnx"
)
LEN_SCALE = 1.5
BOT_FALA = "/tmp/kdu9-bot-fala"


def bot_fala(on=True):
    """Liga/desliga a flag que faz o bot mover a boca.

    Quem toca o áudio REAL (o paplay) é quem controla esta flag — o som
    começa e a boca abre; o som termina e a boca fecha. Nada de estimativa
    por texto (que dessincronizava quando o daemon carregava o modelo frio
    ou a fala atrasava na fila).
    """
    try:
        if on:
            open(BOT_FALA, "w").close()
        else:
            os.remove(BOT_FALA)
    except OSError:
        pass


def main():
    # Instância ÚNICA no nível do processo: flock é liberado pelo kernel na
    # morte (sem stale). Segunda instância sai ANTES de carregar o modelo.
    import fcntl
    global _lockf
    _lockf = open(os.path.join(RUN, "kdu9-tts.lockfile"), "w")
    try:
        fcntl.flock(_lockf, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        sys.exit(0)
    from piper import PiperVoice
    voice = PiperVoice.load(ONNX)
    if os.path.exists(FIFO):
        try:
            os.unlink(FIFO)
        except OSError:
            pass
    try:
        os.mkfifo(FIFO)
    except OSError:
        pass
    # só sinaliza pronto DEPOIS do modelo carregado (evita corrida de escrita)
    with open(PIDF, "w") as f:
        f.write(str(os.getpid()))

    players = []          # paplay em andamento (coletados p/ não virar zumbi)
    def colhe_players(force=False):
        # reap: todo player que terminou é coletado; zumbi = paplay que matam
        # o FALA() do script (pgrep casa com cmdline). Sem isto o mic fica
        # "preso" por 48s+ no fim (o zumbi nunca sai do pgrep).
        for p in list(players):
            rc = p.poll()
            if rc is not None:
                players.remove(p)
        # a boca/marcador do bot só fica ligada ENQUANTO houver áudio
        # tocando de verdade; último player terminou → fecha a boca.
        if not players:
            bot_fala(False)

    def vigia_players():
        # Vigia INDEPENDENTE: o colhe_players() do loop só roda quando chega
        # outra fala no FIFO — se a fila esvazia, o último paplay terminava e
        # ninguém vinha coletá-lo, deixando a boca do bot aberta pra sempre
        # (zumbi + flag presa). Esta thread varre a cada 0.3s e fecha tudo.
        while True:
            try:
                colhe_players()
            except Exception:
                pass
            time.sleep(0.3)

    threading.Thread(target=vigia_players, daemon=True).start()

    # ---- LOG (2026-09-27): faltava visibilidade e o diagnóstico custou caro.
    LOGD = os.path.join(RUN, "kdu9-tts.log")

    def _log(msg):
        try:
            with open(LOGD, "a") as f:
                f.write("%s %s\n" % (time.strftime("%H:%M:%S"), msg))
        except OSError:
            pass

    def processa(line):
        if not line:
            return
        if line == "__QUIT__":
            sys.exit(0)
        colhe_players()
        # SERIALIZA a fala: espera o player anterior terminar
        # (teto 30s). Sem isso as vozes se sobrepõem e viram
        # "tom mudado"/massa ininteligível.
        for _w in range(60):
            try:
                if not any(p.poll() is None for p in players):
                    break
                time.sleep(0.5)
            except Exception:
                break
        buf = io.BytesIO()
        w = wave.open(buf, "wb")
        try:
            voice.synthesize_wav(line, w)
        except Exception:
            _log("ERRO sintese: %s" % line[:40])
            return
        finally:
            w.close()
        with open(WAV, "wb") as fw:
            fw.write(buf.getvalue())
        bot_fala(True)   # som vai sair AGORA → boca abre
        p = subprocess.Popen(
            ["paplay", "--volume=65536", WAV],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        players.append(p)
        _log("falou: %s" % line[:60])

    # ---- AUTO-CURA DO FIFO (2026-09-27) ----------------------------------
    # O open(FIFO,"r") simples travava PARA SEMPRE dentro do open() quando o
    # FIFO era recriado por baixo (inode novo): o daemon ficava MUDO em
    # silêncio, sem erro nenhum, enquanto o kdu-falar achava que tinha falado
    # (foi o bug de 27/09). Agora o daemon abre em O_RDWR|O_NONBLOCK (não
    # trava), lê com select() e a cada tique confere se o FIFO do disco ainda
    # é o mesmo inode que ele segura — se trocar, reabre sozinho. Ninguém mais
    # consegue deixar a voz muda.
    import select

    def _abre_fifo():
        fd = os.open(FIFO, os.O_RDWR | os.O_NONBLOCK)
        return fd, os.fstat(fd).st_ino

    def _ino_do_disco():
        try:
            return os.stat(FIFO).st_ino
        except OSError:
            return None

    _log("daemon no ar pid=%d fifa=%s" % (os.getpid(), FIFO))
    fd = None
    meu_ino = None
    acc = b""
    while True:
        try:
            if fd is None or _ino_do_disco() != meu_ino:
                if fd is not None:
                    try:
                        os.close(fd)
                    except OSError:
                        pass
                    _log("FIFO trocado (era inode %s) → reabrindo" % meu_ino)
                fd, meu_ino = _abre_fifo()
                _log("ouvindo o FIFO inode %s" % meu_ino)
                acc = b""
            rlist, _, _ = select.select([fd], [], [], 0.5)
            if not rlist:
                continue
            pedaco = os.read(fd, 4096)
            if not pedaco:
                time.sleep(0.05)
                continue
            acc += pedaco
            while b"\n" in acc:
                linha, acc = acc.split(b"\n", 1)
                processa(linha.decode("utf-8", "ignore").strip())
        except OSError:
            if fd is not None:
                try:
                    os.close(fd)
                except OSError:
                    pass
            fd = None
            time.sleep(0.3)
        except Exception as e:
            _log("ERRO no loop: %r" % (e,))
            time.sleep(0.3)


def _term(*_a):
    sys.exit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, _term)
    signal.signal(signal.SIGINT, _term)
    sys.exit(main())