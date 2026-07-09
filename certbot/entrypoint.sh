#!/bin/sh
# Emissão + renovação automática de certificados Let's Encrypt via DNS-01 (Cloudflare).
# - Escreve o cloudflare.ini a partir da env (o plugin dns-cloudflare lê de arquivo, não de env)
# - Emite um certificado por domínio (idempotente: pula se já existe e não está perto de expirar)
# - Entra num loop renovando a cada 12h
set -e

CRED="/etc/letsencrypt/cloudflare.ini"

if [ -z "${CLOUDFLARE_API_TOKEN}" ]; then
  echo "❌ CLOUDFLARE_API_TOKEN não definido."
  exit 1
fi
if [ -z "${CERT_DOMAINS}" ]; then
  echo "❌ CERT_DOMAINS não definido (ex: 'api.exemplo.com app.exemplo.com')."
  exit 1
fi

mkdir -p /etc/letsencrypt
umask 077
printf 'dns_cloudflare_api_token = %s\n' "${CLOUDFLARE_API_TOKEN}" > "$CRED"
chmod 600 "$CRED"

# Emite um certificado por domínio -> cada um gera seu próprio live/<dominio>/,
# batendo com os paths usados nos .conf do nginx.
for domain in ${CERT_DOMAINS}; do
  echo "🔐 Emitindo/validando certificado para ${domain}..."
  certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$CRED" \
    --dns-cloudflare-propagation-seconds 60 \
    -d "${domain}" \
    -m "${CERTBOT_EMAIL}" \
    --agree-tos --no-eff-email \
    --keep-until-expiring --non-interactive
done

echo "✅ Certificados prontos. Loop de renovação a cada 12h."
trap exit TERM
while true; do
  sleep 12h &
  wait $!
  echo "🔄 Verificando renovação..."
  certbot renew --non-interactive
done
