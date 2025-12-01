FROM nginx:latest

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx/* /etc/nginx/conf.d/ 

EXPOSE 80 443