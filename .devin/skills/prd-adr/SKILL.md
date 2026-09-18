---
name: prd-adr
description: Criar PRD (pandora-docs/prd/NG-XX) ou ADR sensível (pandora-docs/adr/nginx/) seguindo as convenções do ecossistema
argument-hint: "[prd|adr] <tema da entrega ou decisão>"
allowed-tools:
  - read
  - edit
  - grep
  - glob
---

Documentar uma entrega (PRD) ou uma decisão arquitetural (ADR) do gateway.

**Docs duráveis vivem no repo privado `pandora-docs`** (repo irmão:
`../pandora-docs`) — este repo é público, então nada de doc com
requisito/decisão é commitado aqui.

Regra de bolso: PRD registra **o que** a entrega faz; ADR registra **por que**
uma decisão foi tomada. Decisões de produto do Pandora (gates, experimentos)
NÃO vão aqui — ficam em `pandora-docs/prd/`/`adr/backend/` e são
referenciadas por nome.

## PRD — procedimento

1. Descobrir o próximo número: `glob ../pandora-docs/prd/NG-*.md`, pegar o
   maior + 1.
2. Criar `../pandora-docs/prd/NG-XX-<slug-kebab>.md` em PT-BR, com o formato:

```markdown
# NG-XX — Título descritivo

**Repo:** pandora-nginx · **Tipo:** feature|fix|chore · **Base:** `main`
**Status:** não iniciado | em andamento | entregue.
(estado na criação — depois disso o status vive no card do Trello; não
edite o PRD para mudar status nem para marcar checklist)

## Problema

O problema concreto, com o comportamento observado hoje.

## Escopo

### 1. <parte>

- comportamento esperado, regras, edge cases

## Critérios de aceite

- [ ] checklist verificável

## Fora de escopo

- o que fica explicitamente de fora
```

3. Consultar `../pandora-docs/prd/NG-02-hardening-da-borda.md` como
   referência de tom.
4. Adicionar linha na tabela de `../pandora-docs/prd/README.md`.
5. Commitar **direto na `main` do `pandora-docs`** (repo de docs é trunk
   puro, sem branch/PR).

## ADR — procedimento

ADRs do nginx são quase todos de infra → vão em
`../pandora-docs/adr/nginx/` (sensível por definição). Se surgir ADR
puramente de convenção de código, avalie com o usuário.

1. Descobrir o próximo número: `glob ../pandora-docs/adr/nginx/*.md`, pegar
   o maior + 1 (formato `000X`, 4 dígitos).
2. Estrutura: Status, Data (AAAA-MM-DD), Contexto do código, Contexto
   (problema observado), Decisão, Alternativas consideradas (cada uma com o
   motivo do descarte), Consequências.
3. **Nunca editar ADR aceito.** Decisão nova = ADR novo com
   `Substitui ADR-XXXX` e o antigo passa a `Substituído por ADR-YYYY`.
4. Adicionar linha na tabela de `../pandora-docs/adr/README.md`.

## Convenções de escrita

- PT-BR, direto, sem enfeite. Problema antes de solução.
- Status do ADR novo: `Aceito` se já vigora, `Proposto` se em discussão.
