# NG-02 — Hardening da borda (Cloudflare + nginx)

**Repo:** pandora-nginx (+ settings da zone no Cloudflare) ·
**Tipo:** fix/infra · **Base:** `main`
**Status:** não iniciado.
**Origem:** auditoria de 2026-09-19 — revisão dos `.conf` + leitura das
settings da zone `project-pandora.com.br` via API Cloudflare.

## Problema

`api.` e `app.` são **proxied** pela Cloudflare (edge termina o TLS do
cliente). A auditoria encontrou gaps em três camadas:

### A. Cloudflare (mudança na dashboard/API, não no repo)

| Setting | Hoje | Recomendado | Motivo |
|---|---|---|---|
| SSL/TLS mode | `full` | `full (strict)` | Origin tem cert Let's Encrypt válido — `full` não valida o cert do origin, abre janela de MITM no hop CF→servidor |
| `min_tls_version` | `1.0` | `1.2` | TLS 1.0/1.1 são legado inseguro |
| `always_use_https` | `off` | `on` | Redirect na edge em vez de roundtrip até o origin |
| HSTS (`security_header`) | desligado | `max-age` ≥ 6 meses, `include_subdomains` | Força HTTPS em visitas subsequentes |
| Cache | `aggressive` | manter, **mas bypass em `/media/`** | ver item B |

### B. Cache de `/media/` — o achado mais sério

`backend.conf` responde `/media/` com `expires 30d` +
`Cache-Control "public"`. Com `cache_level = aggressive` na Cloudflare,
respostas com extensão cacheável (`.zip` está na lista padrão da CF)
ficam **cacheadas no edge por 30 dias e servidas a qualquer um com a
URL, sem passar pela auth do Django**. `/media/` é onde moram os uploads
(FCS/ZIP = dado de paciente).

- **Opção 1 (preferida):** Cache Rule na Cloudflare → Bypass para
  `api.project-pandora.com.br/media/*` (e provavelmente todo `api.*`,
  que é API autenticada — cache de edge não agrega).
- **Opção 2 (defesa em profundidade, fazer junto):** no `backend.conf`,
  trocar `Cache-Control "public"` de `/media/` por `private, no-store`.
  `/static/` pode manter `public` (WhiteNoise serve assets públicos com
  hash) — é exatamente o que a edge deve cachear.

### C. nginx (`nginx/*.conf`)

- `client_max_body_size` ausente → default 1m. Funciona porque o front
  fatia upload em 512KB (`ExperimentContext`), mas é acoplamento
  implícito: setar explícito (ex.: `2m` no vhost `api.`) com comentário
  apontando o vínculo.
- `proxy_read_timeout`/`proxy_send_timeout` default 60s. O backend roda
  processamento pesado síncrono na request; alinhar com o timeout real
  do gunicorn — **atenção:** `Dockerfile` do backend declara
  `--timeout 120`, mas `docker-compose.prod.yml` sobrescreve o CMD sem
  ele (gunicorn cai pro default 30s). Resolver primeiro no backend;
  depois setar `proxy_read_timeout` aqui para um valor ≥ gunicorn.
- IP real do cliente: com CF proxying, o origin vê IP da edge. Adicionar
  `set_real_ip_from` com os ranges oficiais da CF +
  `real_ip_header CF-Connecting-IP` para Django/logs receberem o IP real.
- `X-XSS-Protection "1; mode=block"` — header deprecado, remover.
- `ssl_stapling` inconsistente: ligado em `backend.conf`, desligado em
  `frontend.conf`. Como o TLS do cliente termina na Cloudflare, stapling
  no origin só afeta o hop CF→origin — padronizar (sugestão: remover dos
  dois e manter a conf mais simples; ou ligar nos dois por consistência).
- `listen 443 ssl http2` (backend.conf) vs `http2 on;` (frontend.conf) —
  sintaxe deprecada na primeira; unificar para `http2 on;`.

## Arquivos a tocar

- `nginx/backend.conf` — cache header de `/media/`, body size, timeouts,
  real_ip, headers
- `nginx/frontend.conf` — header deprecado, stapling
- Settings da zone no Cloudflare (via dashboard ou API — registrar o que
  mudou no card do Trello)

## Critérios de aceite

- [ ] SSL mode `full (strict)`; `min_tls_version` 1.2; `always_use_https`
  e HSTS ativos
- [ ] `/media/` nunca é cacheado na edge (testar: `curl -I` mostra
  `cf-cache-status: BYPASS` ou `no-store` no origin)
- [ ] `client_max_body_size` explícito e comentado
- [ ] Timeout do proxy alinhado ao gunicorn real em produção
- [ ] IP real do cliente chega ao Django (`CF-Connecting-IP`)
- [ ] `nginx -t` limpo no CI

## Fora de escopo

- Rate limiting (`limit_req`) e WAF managed rules — avaliar depois se
  aparecer abuso real; plano Free limita opções.
- Migrar TLS do hop CF→origin para cert da Cloudflare Origin CA (válido
  por 15 anos, sem renovação) — alternativa futura ao Let's Encrypt,
  mas o LE + DNS-01 já está funcionando.
