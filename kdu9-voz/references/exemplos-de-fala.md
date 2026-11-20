# Exemplos de fala — KDu9 Voz

Formato de toda resposta:

1. Texto completo (markdown, código, detalhes).
2. Uma frase curta no fim — a frase falada.
3. Uma chamada `kdu_falar` com essa frase.

## Exemplo 1 — correção de código

**Texto:**

```markdown
Ajustei `agents/kdu9-bot.md` para carregar a skill `kdu9-voz` quando houver
pedido de fala. O `description` dela cobre resposta falada + texto completo.

- `skills/kdu9-voz/SKILL.md` — regras de fala
- `skills/kdu9-voz/references/exemplos-de-fala.md` — exemplos

Nada precisa reiniciar: o OpenCode recarrega skills ao salvar.
```

**Fala:** "Ajustei o agente para carregar a skill de voz. Já vale na próxima resposta."

## Exemplo 2 — dado medido

**Texto:** tabela com `df -h`, uso de CPU, estado do daemon.

**Fala:** "A raiz tem setenta e três gigas livres e o daemon de voz está ativo."

## Exemplo 3 — ação de risco (comando pendente)

**Texto:** o comando exato em bloco de código.

**Fala:** "Vou apagar a pasta temporária de testes. Confirma?"

**Arquivo:** `/tmp/kdu9-bot-pendente.txt` com o comando em uma linha.

## Exemplo 4 — o que NÃO falar

**Nunca:** "R M, espaço, hífen, r f, barra, té, x, eme, barra, té, x, eme..."

**Nunca:** ler um diff, um JSON ou a saída de um comando.

**Nunca:** mais de 2 frases ou mais de uma pergunta.

**Sempre:** o que foi feito e o que falta.

## Exemplo 5 — fala que saiu errada

Se o Cadu disser "Roubo" em vez de "Robô", ou soletrar uma sigla:

1. Rode `kdu_fonetizar` com a frase e mostre a saída no texto.
2. Diga no texto o que saiu e o que deveria sair.
3. O dono corrige no `KDu9-Corretor-de-Falas.sh`.
