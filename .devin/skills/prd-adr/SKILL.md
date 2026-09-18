---
name: prd-adr
description: Criar PRD (docs/prd/NG-XX) ou ADR (docs/adr/XXXX) seguindo as convenções do pandora-nginx
argument-hint: "[prd|adr] <tema da entrega ou decisão>"
allowed-tools:
  - read
  - edit
  - grep
  - glob
---

Documentar uma entrega (PRD) ou uma decisão arquitetural (ADR) neste repo.

Regra de bolso: PRD registra **o que** a entrega faz; ADR registra **por que**
uma decisão foi tomada. Decisões de produto do Pandora (gates, experimentos)
NÃO vão aqui — ficam em `pandora-backend/docs/` e são referenciadas por nome.

## PRD — procedimento

1. Descobrir o próximo número: `glob docs/prd/NG-*.md`, pegar o maior + 1.
2. Criar `docs/prd/NG-XX-<slug-kebab>.md` em PT-BR, com o formato:

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

## Arquivos a tocar

- caminhos reais + o que muda em cada um (incluir mudanças fora do repo —
  ex.: settings da zone no Cloudflare — como item próprio)

## Critérios de aceite

- [ ] checklist verificável

## Fora de escopo

- o que fica explicitamente de fora
```

3. Consultar `docs/prd/NG-02-hardening-da-borda.md` como referência de tom.
4. Adicionar linha na tabela de `docs/prd/README.md`.

## ADR — procedimento

1. Descobrir o próximo número: `glob docs/adr/*.md`, pegar o maior + 1
   (formato `000X`, 4 dígitos).
2. Estrutura de `docs/adr/0001-*.md`: Status, Data (AAAA-MM-DD), Contexto do
   código, Contexto (problema observado), Decisão, Alternativas consideradas
   (cada uma com o motivo do descarte), Consequências.
3. **Nunca editar ADR aceito.** Decisão nova = ADR novo com
   `Substitui ADR-XXXX` e o antigo passa a `Substituído por ADR-YYYY`.
4. Adicionar linha na tabela de ADRs em `docs/prd/README.md`.

## Convenções de escrita

- PT-BR, direto, sem enfeite. Problema antes de solução.
- Status do ADR novo: `Aceito` se já vigora, `Proposto` se em discussão.
