#!/bin/bash
set -e

mkdir -p /etc/nginx/auth

if [ -z "$NGINX_HTPASSWD" ]; then
    echo "FATAL: NGINX_HTPASSWD secret must be set!"
    exit 1
fi

echo "$NGINX_HTPASSWD" > /etc/nginx/auth/.htpasswd

# Start MindsDB (correct python module invocation, like the official image)
nohup /venv/bin/python -Im mindsdb --config=/root/mindsdb_config.json --api=http,a2a,mcp > /tmp/mindsdb.log 2>&1 &

# Start nginx in foreground
nginx -g 'daemon off;'

