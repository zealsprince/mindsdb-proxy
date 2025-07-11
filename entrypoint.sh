#!/bin/bash
set -e

mkdir -p /etc/nginx/auth

if [ -z "$NGINX_HTPASSWD" ]; then
    echo "FATAL: NGINX_HTPASSWD secret must be set!"
    exit 1
fi

echo "$NGINX_HTPASSWD" > /etc/nginx/auth/.htpasswd

# Generate DH parameters for SSL if they don't exist
if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
    echo "Generating DH parameters..."
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
fi

# Handle Let's Encrypt setup if ENABLE_HTTPS is set
if [ "$ENABLE_HTTPS" = "true" ]; then
    if [ -z "$DOMAIN" ]; then
        echo "FATAL: DOMAIN environment variable must be set when ENABLE_HTTPS=true"
        exit 1
    fi
    
    if [ -z "$EMAIL" ]; then
        echo "FATAL: EMAIL environment variable must be set when ENABLE_HTTPS=true"
        exit 1
    fi
    
    echo "Setting up HTTPS with Let's Encrypt for domain: $DOMAIN"
    
    # Replace placeholder in nginx config
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" /etc/nginx/nginx.conf
    
    # Check if certificates already exist
    if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        echo "Obtaining SSL certificate..."
        # First, start nginx with HTTP only to pass Let's Encrypt challenge
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.ssl
        cat > /etc/nginx/nginx.conf << EOF
events {}
http {
    server {
        listen 80;
        server_name $DOMAIN;
        
        location /.well-known/acme-challenge/ {
            root /var/www/html;
        }
        
        location / {
            proxy_pass http://localhost:47334;
            auth_basic "Restricted";
            auth_basic_user_file /etc/nginx/auth/.htpasswd;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
    }
}
EOF
        
        # Start nginx temporarily
        nginx &
        NGINX_PID=$!
        
        # Wait for nginx to start
        sleep 2
        
        # Obtain certificate
        certbot --nginx -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive --redirect || {
            echo "Failed to obtain SSL certificate"
            kill $NGINX_PID 2>/dev/null || true
            exit 1
        }
        
        # Stop temporary nginx
        kill $NGINX_PID 2>/dev/null || true
        wait $NGINX_PID 2>/dev/null || true
        
        # Restore SSL-enabled config (certbot already modified it)
        mv /etc/nginx/nginx.conf.ssl /etc/nginx/nginx.conf
    else
        echo "SSL certificates already exist, skipping certificate generation"
    fi
    
    # Setup certificate renewal cron job
    echo "0 12 * * * /usr/bin/certbot renew --quiet && /usr/sbin/nginx -s reload" | crontab -
    
    # Start cron for certificate renewal
    cron
else
    echo "HTTPS disabled. Running in HTTP-only mode."
    # Use simplified HTTP-only nginx config
    cat > /etc/nginx/nginx.conf << EOF
events {}
http {
    server {
        listen 80;
        server_name _;
        
        location / {
            proxy_pass http://localhost:47334;
            auth_basic "Restricted";
            auth_basic_user_file /etc/nginx/auth/.htpasswd;

            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF
fi

# Start MindsDB (correct python module invocation, like the official image)
nohup /venv/bin/python -Im mindsdb --config=/root/mindsdb_config.json --api=http,a2a,mcp > /tmp/mindsdb.log 2>&1 &

# Start nginx in foreground
nginx -g 'daemon off;'

