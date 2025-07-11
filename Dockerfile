FROM mindsdb/mindsdb

USER root

RUN apt-get update && \
    apt-get install -y apache2-utils bash certbot cron nginx python3-certbot-nginx && \
    rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]

