# KDu — Skills para OpenCode

Habilidades (skills) criadas pelo **Projeto Linux KDu** para quem usa
[OpenCode](https://opencode.ai) e quer a IA falando de verdade pelo speaker,
em português do Brasil.

> Feito no KDu9 — Ion Final Rv4 (IA local, voz Cadu/Piper, 100% offline).

## kdu9-voz — a IA que fala com você

Toda resposta do agente passa a ter **duas camadas**:

1. **Texto completo** — código, diffs, detalhes, para você ler depois.
2. **Uma fala curta** — 1 a 2 frases, sintetizada em pt-BR, para você ouvir
   enquanto trabalha, sem ler a tela.

A fala nunca é a resposta inteira: código, comandos e logs ficam no texto.
O agente termina a resposta com uma frase curta e a fala por aqui.

## Instalar

### Opção 1 — catálogo (recomendado)

Adicione **uma linha** em `~/.config/opencode/opencode.json`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "skills": ["https://suportetecnicoid-kdu.github.io/kdu9-opencode/"]
}
```

O OpenCode baixa a skill sozinho. Não precisa reiniciar.

### Opção 2 — copiar a pasta

```sh
mkdir -p ~/.config/opencode/skills
git clone https://github.com/SuporteTecnicoID-KDu/kdu9-opencode.git /tmp/kdu-skills
cp -r /tmp/kdu-skills/kdu9-voz ~/.config/opencode/skills/
```

## Preparar a voz (uma vez por máquina)

```sh
bash ~/.config/opencode/skills/kdu9-voz/scripts/instalar.sh --teste
```

O instalador oferece dois modos:

| Modo | Voz | Custo |
| --- | --- | --- |
| **completo** | Piper + voz Cadu (natural) | ~330 MB |
| **leve** | espeak-ng pt-BR (fallback) | quase 0 MB |

A skill detecta o motor sozinha: KDu9 → motor portátil → espeak. Se a voz
falhar, o agente avisa no texto em vez de calar.

## Requisitos

- Linux (testado no KDu9) ou macOS; no Windows, use WSL.
- Áudio PulseAudio ou PipeWire.
- Modo completo: Python 3.9+ e internet para baixar o modelo.
- Modo leve: pacote `espeak-ng` (+ `mbrola` e voz `mb-br1` para melhor tom).

## Como funciona

```text
kdu9-voz/
├── SKILL.md                 regras de fala
├── references/              exemplos e guia de distribuição
└── scripts/
    ├── kdu9-voz.sh          CLI: falar | teste | status | parar
    ├── kdu-falar.sh         motor (fonetização KDu + cadeia de fallback)
    ├── kdu-tts-daemon.py    daemon Piper residente (~0,3 s por frase)
    └── instalar.sh          instalação completa ou leve
```

## Projeto Linux KDu

- SourceForge (ISO e wiki): <https://sourceforge.net/projects/kduxp/>
- Site: <https://www.linux-kdu.com.br>
- Desenvolvimento: Index Data — <https://www.indexdata.com.br>

## Licença

O texto da skill e os scripts são licenciados sob **MIT**. O modelo de voz
Cadu é do repositório `rhasspy/piper-voices` (também MIT).
