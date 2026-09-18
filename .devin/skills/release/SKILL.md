---
name: release
description: Publicar uma GitHub Release do gateway e acompanhar o deploy — usar quando o usuário pedir "nova versão", "criar release" ou "fazer deploy" do pandora-nginx
argument-hint: "[patch|minor|major ou versão exata, ex.: v0.2.0]"
allowed-tools:
  - exec
  - read
---

Publicar uma release deste repo e conduzir o deploy da borda.

Modelo (ADR-0001): publicar uma **GitHub Release** cria a tag `vX.Y.Z` e
dispara `.github/workflows/release.yml` — scp dos arquivos para
`/opt/pandora/nginx` no servidor → `docker compose up -d --build` → smoke
check em `app.`/`api.`. Push na `main` **não** deploya. Tag avulsa via
`git tag` também não. `rollback.yml` restaura uma tag por
`workflow_dispatch`. Tudo passa pelo environment `production`.

## Passo 0 — produção não é ambiente de teste

Antes de publicar, o que entra já tem que estar verificado: CI verde
(`compose config` + `nginx -t` + build rodam em todo push/PR). Depois do
deploy só se confere o *deploy* — gateway no ar, TLS ok — nunca feature.

Pipeline novo também é código não testado: se `release.yml`/`rollback.yml`
mudaram desde o último deploy, exercite com `workflow_dispatch` antes.

## Passo 1 — descobrir a última versão e o que entra

```bash
gh release list -L 5
git fetch origin --tags
git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~50)..origin/main
```

## Passo 2 — propor a versão (semver)

| O que entrou | Bump |
|---|---|
| Só fixes/docs/ci | patch |
| Mudança de config/comportamento | minor |
| Quebra de compatibilidade | major — confirmar com o usuário |

**Sempre mostrar o que entra + a versão e confirmar antes de publicar** —
release dispara deploy real na borda (derruba front + API se errar).

## Passo 3 — publicar e acompanhar

```bash
gh release create vX.Y.Z --target main --title "vX.Y.Z" --generate-notes
gh run list --workflow release.yml --limit 3
gh run watch <run-id>
```

## Passo 4 — verificar e atualizar o board

- `gh run watch` até o fim: scp → compose up → smoke check.
- Rollback manual: `gh workflow run rollback.yml -f tag=vX.Y.Z`.
- Deploy verificado = cards das features que entraram vão para
  🚀 Em produção, com comentário citando a tag. Convenções do board na
  skill `/trello-board`.
