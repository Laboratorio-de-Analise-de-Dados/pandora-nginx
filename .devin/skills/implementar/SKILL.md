---
name: implementar
description: Implementar uma tarefa do board neste repo — validação nginx -t/compose config, borda como perímetro único, CSP coerente e Trello atualizado
argument-hint: "<PRD/card: ex. NG-03>"
allowed-tools:
  - read
  - edit
  - grep
  - glob
  - exec
  - mcp_call_tool
  - mcp_list_tools
---

# Implementar — pandora-nginx (borda = perímetro)

Implementação guiada por spec. O `AGENTS.md` é a referência operacional —
esta skill é o checklist de execução por cima dele.

## 1. Contexto antes de codar (não pule)

- **`.scratch/tasks-<slug>.md` primeiro**: o plano de implementação
  (tasks ordenadas, validações, notas de execução) mora local e
  gitignored neste repo — leia-o em vez de abrir o card no MCP. Se não
  existir, ele deveria ter sido gerado pelo `/to-tickets`: peça o PRD e
  derive.
- **PRD → ADRs**: o card/PRD (`pandora-docs/prd/NG-XX-*.md`) linka
  decisões sensíveis em `pandora-docs/adr/nginx/` (ADR-0001 = deploy
  por release pinada).
- **`docs/TRACKER.md`**: frente ativa na mesma área = conflito —
  alinhe ou pegue outra. Registre sua linha no mesmo commit.
- **Branch**: `feat/*`/`fix/*`/`docs/*` + PR (main protegida; setup
  operacional pode ir direto por decisão do dono — mesmo assim valide,
  o push deploya).
- **Card → 🔨 Em andamento** ao assumir (`/trello-board`).

## 2. "TDD" da borda — validação antes do deploy

Não há suite de testes — o portão é validação estática + exercitação:

1. Erro de sintaxe na borda tira front + API do ar ao mesmo tempo:
   `nginx -t` limpo é o "teste" obrigatório.
2. Mudança em workflow (`release.yml`/`rollback.yml`) é código não
   testado até exercitado — valide com `workflow_dispatch` numa tag já
   publicada antes de confiar num deploy real.
3. Toda mudança que afeta roteamento/headers: ensaiar local com
   `docker compose up` + curl nos vhosts antes de propor.

## 3. Security gates — checar antes de abrir PR

- [ ] **Nunca expor serviço interno** — Juvia e qualquer coisa sem
      vhost não existem na internet; o nginx é o perímetro inteiro.
- [ ] Redirect 80→443 em todo vhost novo.
- [ ] `frontend.conf`: `connect-src` do CSP aponta para a API e o CSP
      coerente com o front (Google Fonts, Cloudflare Insights) —
      CSP quebrada = tela branca.
- [ ] `resolver 127.0.0.11` no `backend.conf` é o DNS interno do Docker
      — não trocar por resolver externo; upstream é nome de container.
- [ ] `/static/` e `/media/` proxados pro Django (WhiteNoise) — o nginx
      não tem os arquivos.
- [ ] Nenhum segredo commitado — `CLOUDFLARE_API_TOKEN`/`CERTBOT_EMAIL`/
      `CERT_DOMAINS` vêm de env/secrets do GitHub.
- [ ] Headers de segurança novos são decisão sensível → ADR em
      `pandora-docs/adr/nginx/`.

## 4. Verificação local (portão antes de concluir)

```bash
docker compose config   # compose válido + envs resolvidas
docker run --rm -v "$PWD/nginx:/etc/nginx/conf.d:ro" nginx nginx -t
```

## 5. Fechamento — .scratch/ marca o dia a dia, Trello só os marcos

- Marque as tasks feitas no `.scratch/tasks-<slug>.md` local (o arquivo
  é seu caderno de execução — MCP não precisa ser chamado a cada task).
- **Marcos Trello** (única vez que o MCP entra): assumir → 🔨 Em
  andamento; PR aberto → comentário com o link + ✅ nos critérios
  verificados do checklist "Acceptance Criteria"; merge na `main` →
  📦 Entregue + comentário (branch/PR); release deployada + smoke
  (`app.`/`api.` respondendo) → 🚀 Em produção.
- Bug/dívida achada no caminho → card novo no Backlog — Back, capa
  rosa, com referência ao PRD/PR.
