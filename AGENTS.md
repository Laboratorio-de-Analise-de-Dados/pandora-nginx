# AGENTS.md — pandora-nginx

Guia operacional para agentes de IA. Leia antes de codar.

## Projeto

Camada de borda do ecossistema Pandora: proxy reverso nginx + TLS
automático (certbot/Let's Encrypt via Cloudflare DNS-01). É a **única
porta de entrada pública** — front e back ficam atrás dela na rede
`pandora_net`.

- `app.project-pandora.com.br` → `pandora_frontend:80` (SPA React)
- `api.project-pandora.com.br` → `pandora_web:8000` (Django)
- O **Juvia não é exposto** — serviço interno, nunca criar vhost pra ele.

## Comandos

```bash
# setup local (uma vez)
docker network create pandora_net
docker compose up --build        # sobe certbot + nginx (exige envs abaixo)

# validação — rodar antes de concluir qualquer mudança
docker compose config            # compose válido + envs resolvidas
docker run --rm -v "$PWD/nginx:/etc/nginx/conf.d:ro" nginx nginx -t

# operação
docker compose logs -f nginx certbot
docker compose exec nginx nginx -s reload   # reload sem derrubar
```

- Envs exigidas (ver `certbot/entrypoint.sh`): `CLOUDFLARE_API_TOKEN`,
  `CERTBOT_EMAIL`, `CERT_DOMAINS` (lista separada por espaço).
- O nginx só sobe depois do healthcheck do certbot — os dois certificados
  precisam existir em `/etc/letsencrypt/live/<dominio>/`.

## Deploy — release versionada (ADR-0001)

Deploy **não** sai de push: dispara ao **publicar uma Release** na UI do
GitHub (a tag `v*` é criada no publish; tag avulsa não deploya), mesmo
padrão do ADR-0022 do backend. `release.yml` copia os arquivos via scp
para `/opt/pandora/nginx` e sobe certbot + nginx; `rollback.yml`
restaura uma tag por `workflow_dispatch`; `ci.yml` valida PR/push
(`compose config`, `nginx -t` com certs dummy, build da imagem). Tudo
passa pelo portão do environment `production`.

Consequência prática: mudança em `nginx/*.conf` precisa passar pelo CI
(`nginx -t` limpo) antes de entrar em release — erro de sintaxe na borda
impede o reload do gateway e tira front + API do ar ao mesmo tempo.
Mudança no próprio workflow é código não testado até ser exercitada:
valide com `workflow_dispatch` antes de confiar nela num deploy real.

## Arquitetura

```
nginx/frontend.conf    vhost app.* → pandora_frontend:80 (SPA; 404 → index.html)
nginx/backend.conf     vhost api.* → upstream pandora_web:8000 (+ /static, /media)
certbot/entrypoint.sh  escreve cloudflare.ini da env, emite 1 cert por domínio
                       (DNS-01, idempotente) e entra em loop de renovação 12h
docker-compose.yml     certbot (emite/renova) → nginx (reload a cada 6h para
                       pegar cert renovado sem derrubar)
Dockerfile             nginx pinado + conf.d copiado
.github/workflows/     ci.yml (validação) · release.yml (deploy por
                       release publicada) · rollback.yml (restaura tag)
```

## Convenções / regras duras

- **Nunca exponha o Juvia** nem qualquer serviço interno — o nginx é o
  perímetro inteiro; o que não tem vhost não existe na internet.
- Headers de segurança e CSP moram aqui. Ao tocar `frontend.conf`,
  mantenha `connect-src` apontando para a API e o CSP coerente com o
  front (Google Fonts, Cloudflare Insights) — CSP quebrada = tela branca.
- `resolver 127.0.0.11` no `backend.conf` é o DNS interno do Docker —
  não troque por resolver externo; o upstream é nome de container.
- `/static/` e `/media/` são proxados pro Django — o nginx não tem os
  arquivos; `/static/` depende de WhiteNoise no backend.
- Redirect 80→443 é obrigatório em todo vhost novo.
- Commits `feat(escopo):` / `fix(escopo):` (conventional, PT-BR).
- **Nunca trabalhe direto na `main`** — crie `feat/*`/`fix/*`/`docs/*`
  e abra PR. (Setup operacional/docs podem ir direto por decisão do
  dono — o push continua deployando, então valide mesmo assim.)
- Nunca commitar credenciais — `CLOUDFLARE_API_TOKEN`/`CERTBOT_EMAIL`
  vêm de env/secrets do GitHub, nunca hardcoded.

## Sessões paralelas

**Antes de codar, leia `docs/TRACKER.md`** — ele coordena área de
arquivos entre sessões paralelas. Ao assumir uma frente, registre sua
linha no mesmo commit; ao concluir, atualize.

## Status e board

Status de features **não vive neste repo** — pipeline, prioridade e
checklist de aceitação ficam no Trello, board "Pandora — Implementações"
(https://trello.com/b/dXb21KpL). Convenções completas na skill
`/trello-board`.

O deploy sai só de release publicada: card vai a 📦 Entregue quando
mergeado na `main` e a 🚀 Em produção depois da release deployada +
smoke check (o `release.yml` já valida `app.`/`api.` respondendo).
