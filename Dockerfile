# Versão pinada (ADR-0001): upgrade de imagem entra via PR, nunca
# silencioso por `latest`. CI usa a mesma tag no `nginx -t`.
FROM nginx:1.28.0

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx/* /etc/nginx/conf.d/ 

EXPOSE 80 443