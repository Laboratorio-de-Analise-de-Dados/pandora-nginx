# ADR-0001 — Deploy por release publicada e imagem pinada

**Status:** Aceito
**Data:** 2026-09-19

## Contexto do código

`docker-compose.yml` (certbot + nginx na `pandora_net`), `Dockerfile`
(imagem nginx que embute `nginx/*.conf`), `certbot/entrypoint.sh`
(emissão/renovação DNS-01 Cloudflare) e `.github/workflows/` (deploy via
scp + ssh para `/opt/pandora/nginx` no servidor).

## Contexto

O deploy disparava em **push na `main`** (`config.yml`): qualquer merge
— até um commit de docs — ia direto para a borda de produção. Era o
único repo do ecossistema sem versionamento de deploy: front e back
seguem o ADR-0022 do `pandora-backend` (deploy só ao publicar Release
`v*`, com rollback por tag). Além disso o `Dockerfile` usava
`nginx:latest`, ou seja, dois deploys idênticos podiam subir versões
diferentes do nginx — sem reprodutibilidade nem rollback confiável.

A borda é o ponto mais sensível do stack: um erro de sintaxe em
`nginx/*.conf` impede o reload e tira `app.` + `api.` do ar juntos.

## Decisão

1. **Deploy só por Release publicada** (`release.yml` com trigger
   `release: [published]`): push na `main` roda só CI. `rollback.yml`
   restaura qualquer tag `v*` por `workflow_dispatch`, mesmo caminho de
   deploy. Ambos passam pelo environment `production` (approve manual).
2. **Imagem pinada**: `FROM nginx:1.28.0` — upgrade de versão entra via
   PR, visível no diff; CI usa a mesma tag no `nginx -t`, então a versão
   testada é a versão deployada.
3. **CI de validação** (`ci.yml`) em PR/push: `docker compose config`,
   `sh -n` no entrypoint, `nginx -t` com certificados dummy e hosts
   resolvíveis, e `docker build` da imagem.
4. **Smoke check pós-deploy** no `release.yml`/`rollback.yml`: `app.` e
   `api.` precisam responder HTTP < 500 — é a única verificação em
   produção (feature é testada antes da release, nunca depois).

## Alternativas consideradas

- **A) Manter deploy por push + branch protegida**: protege histórico,
  mas continua sem ponto de restauração nomeado e sem separar "código na
  main" de "versão no ar". Descartada.
- **B) Tags de imagem versionadas em registry** (GHCR/Docker Hub): mais
  forte, mas exige registry e muda o fluxo scp+build-no-servidor que já
  funciona; o build no servidor com Dockerfile pinado cobre a
  reprodutibilidade sem infra nova. Revisitar se o servidor virar
  imutável.
- **C) Deploy por push com tag manual obrigatória**: equivalente ao
  escolhido, mas reinventa a mecânica de Release que o resto do
  ecossistema já usa. Descartada por consistência.

## Consequências

- Publicar Release `v*` vira o caminho único de deploy — precisa existir
  ao menos uma release antes do próximo deploy real (criar `v0.1.0`
  marcando o estado atual como baseline).
- `workflow_dispatch` no `release.yml` permite redeploy do ref atual sem
  release (escape hatch documentado, ainda passa pelo gate de produção).
- Rollback de conf fica trivial (dispatch + tag), mas **não** reverte
  certificados já emitidos — o que é seguro (cert emitido não é
  estado a reverter).
- O pin de imagem cria a dívida saudável de bump periódico do nginx —
  registrar no Trello quando aparecer CVE relevante.
