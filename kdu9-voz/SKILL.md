---
name: KDu9 Voz
description: Padroniza as respostas do agente no KDu9 — texto completo (código, detalhes, diffs) mais uma fala curta com kdu_falar (voz Cadu/Piper). Use ao responder ao dono no KDu9, em especial quando ele estiver trabalhando nas bancadas e ouvindo em vez de lendo.
---

# KDu9 Voz

Toda resposta tem **duas camadas**:

1. **Texto completo** — para o dono ler depois: código, diffs, paths, tabelas, detalhes.
2. **Uma fala curta** — para ele ouvir agora, sem tirar os olhos da bancada.

A fala é sempre um subconjunto do texto. **Nunca a resposta inteira na voz.**

## Regra 1 — Uma única chamada de voz por resposta

No **fim** da resposta, uma vez só:

```sh
bash ~/.config/opencode/skills/kdu9-voz/scripts/kdu9-voz.sh falar "Aqui vai a frase falada."
```

- Se a skill estiver no projeto, use `.opencode/skills/kdu9-voz/scripts/kdu9-voz.sh`.
  O agente conhece a pasta onde este `SKILL.md` está.
- O script escolhe o motor sozinho (KDu9 → portátil → fallback) e aplica a
  fonetização. **Não** chame `paplay`, `aplay`, `espeak` ou `piper` direto.
- A primeira chamada do dia sobe o daemon (~2–8 s); as seguintes saem em ~0,3 s.
- Se a voz não sair, diga isso no texto e continue — não insista nem tente
  outro motor na mão.

## Níveis de voz

O motor é detectado nesta ordem: `KDU_FALAR` → motor do KDu9 (`/opt/...`) →
motor portátil (`~/.local/share/kdu9-voz`) → nenhum.

| Nível | Voz | Custo |
| --- | --- | --- |
| KDu9 | Piper/Cadu + bot de desktop + anti-eco | já instalado aqui |
| Portátil completo | Piper/Cadu | ~330 MB (venv + modelo) |
| Portátil leve | espeak-ng pt-BR | quase 0 MB |

Se não houver motor de voz, **explique no texto** e ofereça o instalador:

```sh
bash ~/.config/opencode/skills/kdu9-voz/scripts/instalar.sh --teste
```

Informe o nível em uso quando ele não for o KDu9 ("voz: espeak, fallback").
Nunca deixe de responder porque a voz falhou.

## Regra 2 — O que entra na voz

- Só o que se fala com o dono: **o que você fez, o que você achou, o que precisa dele.**
- 1 a 2 frases, português do Brasil, no máximo ~40 palavras.
- Tempo passado e direto: "Corrigi o agente.", "A raiz tem 73 gigas livres.",
  "O daemon de voz está ativo.", "Preciso que você confirme o comando."
- Escreva a frase limpa: sem markdown, sem emoji, sem `**`, sem setas.
- **Escreva com acento** as palavras que o motor come: `você`, `não`, `está`,
  `já`, `são`, `robô`. A fonetização devolve o acento, mas o texto certo evita
  o tom ruim ("voce" → "vôce").
- Evite siglas e paths na fala. Se forem inevitáveis, por extenso.

## Regra 3 — O que NÃO entra na voz

- Código, comandos, flags, JSON, URLs, saída de terminal, logs, erros crus.
- Diffs, caminhos longos, listas, tabelas, números em sequência.
- Mais de uma pergunta por vez.

## Regra 4 — Separação padrão da resposta

1. Escreva a resposta completa em markdown (com código e detalhes).
2. Termine com **uma frase curta**, que é exatamente a frase falada.
3. Depois dela, faça a chamada `kdu_falar` dessa frase.

Assim quem lê o texto depois vê o resumo no fim, e quem só ouve recebe a
mesma frase. O texto nunca é sacrificado pela fala.

## Regra 5 — Ações de risco: comando pendente

Apagar, mover, renomear, instalar, formatar, mexer em `/etc`, `/usr`, `/boot`,
`/opt` ou em serviço do sistema: **não execute**.

1. Escreva o comando exato (uma linha) em `/tmp/kdu9-bot-pendente.txt`.
2. Fale: "Vou apagar X. Confirma?"

Quem executa é o KDu9 Falar, não o agente. Nunca execute por conta própria.

## Regra 6 — Não invente

- Não falou ainda, não fez: diga "ainda não testei" ou "falta confirmar".
- Número que você não mediu não vai para a voz.

## Regra 7 — Falhas de fala

O dono corrige as falas. Se ele reportar uma fala estranha:

- Teste a fonetização antes de responder:
  `source /opt/Scripts/Progs/KDu9-Sw-Center/KDu9-Voz/kdu-falar.sh && kdu_fonetizar "texto"`
- `kdu_fonetizar` já cobre: KDu9 → "Ka Dê u 9", Rv4 → "R I quatro", KDu → "KaDê u",
  Robô, você, não, está, já, markdown, emoji, CJK.
- Descreva a situação no texto (o que você mandou falar e o que saiu). Quem
  corrige o motor é o dono, com o
  `KDu9-Voz/KDu9-Corretor-de-Falas.sh`.
- Não tente contornar reescrevendo o texto de forma esquisita: reporte a falha.

## Referências

- `references/exemplos-de-fala.md` — exemplos de antes/depois (texto × fala).
- `references/distribuicao.md` — como entregar a skill a outro usuário do OpenCode.
