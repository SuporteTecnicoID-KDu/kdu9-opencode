# Como entregar a skill kdu9-voz a outro usuário do OpenCode

A skill é só texto e scripts pequenos. O que pesa (venv + modelo) **não** fica
na skill: é baixado uma vez por máquina pelo `instalar.sh`.

## Onde o OpenCode procura skills

| Escopo | Caminho |
| --- | --- |
| Global | `~/.config/opencode/skills` |
| Global (compat) | `~/.claude/skills`, `~/.agents/skills` |
| Projeto | `.opencode/skills` |
| Projeto (compat) | `.claude/skills`, `.agents/skills` |
| Qualquer config | array `skills` em `opencode.json` |

Basta a pasta `kdu9-voz/` (com o `SKILL.md` dentro) estar em um desses lugares.
Não é preciso reiniciar: o OpenCode recarrega skills ao salvar.

## Três jeitos de entregar

### 1. Copiar a pasta (mais simples)

```sh
mkdir -p ~/.config/opencode/skills
cp -r kdu9-voz ~/.config/opencode/skills/
```

### 2. Catálogo HTTP (um comando para o usuário)

O usuário adiciona uma linha em `~/.config/opencode/opencode.json`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "skills": ["https://raw.githubusercontent.com/SuporteTecnicoID-KDu/kdu9-opencode/main/"]
}
```

E o catálogo é um `index.json` na raiz:

```json
{
  "skills": [
    {
      "name": "kdu9-voz",
      "version": 1,
      "files": [
        "SKILL.md",
        "references/exemplos-de-fala.md",
        "references/distribuicao.md",
        "scripts/kdu-falar.sh",
        "scripts/kdu-tts-daemon.py",
        "scripts/kdu9-voz.sh",
        "scripts/instalar.sh"
      ]
    }
  ]
}
```

Cada arquivo sai de `<base-url>/<name>/<file>`, ou seja,
`https://raw.githubusercontent.com/SuporteTecnicoID-KDu/kdu9-opencode/main/kdu9-voz/SKILL.md`. Ao mudar um arquivo,
incremente `version` para o OpenCode atualizar o cache.

### 3. Workspace do OpenCode Console

O Console pode compartilhar skills com um workspace; os membros recebem a
skill sem copiar nada.

## Fluxo de quem vai usar (ex.: "Stubbs" no Linux)

1. Instala o OpenCode.
2. Recebe a skill por uma das 3 vias acima.
3. Prepara a voz **uma vez**:

```sh
bash ~/.config/opencode/skills/kdu9-voz/scripts/instalar.sh --teste
```

O instalador pergunta: **completo** (Piper + Cadu, ~330 MB, voz natural) ou
**leve** (espeak pt-BR, quase 0 MB, mais robótico).

4. Abre o OpenCode e conversa. A skill aparece sozinha; o agente fala pelo
   speaker com a voz escolhida.

## Requisitos de máquina

- Linux (testado aqui) ou macOS; Windows precisa de WSL.
- Áudio: PulseAudio ou PipeWire (`paplay`/`aplay`).
- Modo completo: Python 3.9+ e internet para baixar o modelo.
- Modo leve: pacote `espeak-ng` (+ `mbrola` e voz `mb-br1` para melhor tom).

## Regra de ouro da skill

A skill **nunca** aponta caminho fixo: ela detecta o motor (KDu9 → portátil →
espeak). Assim a mesma pasta funciona na sua máquina, na do Stubbs e em
qualquer OpenCode.
