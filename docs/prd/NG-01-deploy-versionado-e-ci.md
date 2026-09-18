# NG-01 — Deploy versionado por release + CI de validação

**Repo:** pandora-nginx · **Tipo:** chore/infra · **Base:** `main`
**Status:** em andamento.
**ADR:** `docs/adr/0001-deploy-por-release-e-imagem-pinada.md`

## Problema

A borda de produção deployava em todo push na `main` — sem baseline
nomeada, sem rollback por tag e com `nginx:latest` (versão do servidor
mudava a cada build). Não havia nenhuma validação automática de sintaxe
de config antes do deploy.

## Escopo

### 1. Deploy por release

- `release.yml` dispara em `release: [published]` (+ `workflow_dispatch`
  como escape hatch), faz checkout na tag da release, copia
  `docker-compose.yml`, `Dockerfile`, `nginx/*`, `certbot/*` via scp e
  sobe `docker compose up -d --build` no servidor — mesmo caminho que
  já existia, agora versionado.
- Smoke check ao final: `app.` e `api.` devem responder HTTP < 500.

### 2. Rollback por tag

- `rollback.yml` (`workflow_dispatch` + input `tag`) repete o deploy
  com checkout no ref informado.

### 3. CI

- `ci.yml` em PR e push na `main`: `docker compose config --quiet`,
  `sh -n certbot/entrypoint.sh`, `nginx -t` na mesma versão pinada do
  Dockerfile (certs dummy + `--add-host` para os upstreams internos) e
  `docker build`.

### 4. Imagem pinada

- `Dockerfile`: `nginx:1.28.0` (era `nginx:latest`).

## Arquivos a tocar

- `.github/workflows/config.yml` → removido, substituído por
  `release.yml` + `rollback.yml` + `ci.yml`
- `Dockerfile` — pin da imagem
- `AGENTS.md`, `docs/` — documentação do fluxo

## Critérios de aceite

- [ ] Push na `main` não dispara deploy; publicar Release dispara
- [ ] `rollback.yml` restaura tag arbitrária via dispatch
- [ ] `ci.yml` falha em config nginx inválida
- [ ] Smoke check reprova deploy que deixou a borda fora
- [ ] Release baseline `v0.1.0` publicada marcando o estado atual

## Fora de escopo

- Registry de imagens (GHCR/Docker Hub) — build continua no servidor.
- Hardening de headers/TLS/cache — é o NG-02.
