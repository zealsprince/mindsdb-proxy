
# MindsDB Proxy with HTTP Basic Auth & HTTPS Support

This project runs [MindsDB](https://mindsdb.com) behind an Nginx reverse proxy with HTTP Basic Authentication and optional HTTPS support via Let's Encrypt. It supports both Fly.io deployment and local/VPS deployment using Docker Compose.

## Deployment Options

### Option 1: Fly.io Deployment (Managed HTTPS)

Fly.io provides managed HTTPS, so you don't need to enable Let's Encrypt.

#### 1. Add or Manage Users

Generate your `.htpasswd` file locally:

```bash
# Install htpasswd (if not already installed)
# Ubuntu/Debian: sudo apt-get install apache2-utils
# macOS: brew install httpd

# Create or update .htpasswd with your users:
htpasswd -c .htpasswd alice     # Add 'alice' (prompts for password)
htpasswd .htpasswd bob          # Add 'bob'
htpasswd .htpasswd charlie      # etc.
```

#### 2. Set the `.htpasswd` File as a Fly.io Secret

```bash
fly secrets set NGINX_HTPASSWD="$(cat .htpasswd)"
```

#### 3. Deploy to Fly.io

```bash
fly deploy
```

### Option 2: Docker Compose (Local/VPS with Optional HTTPS)

#### 1. Setup Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file with your configuration
nano .env
```

#### 2. Configure Authentication

Generate your `.htpasswd` file:

```bash
# Create .htpasswd with your users
htpasswd -c .htpasswd alice
htpasswd .htpasswd bob

# Add the content to your .env file
echo "NGINX_HTPASSWD=$(cat .htpasswd)" >> .env
```

#### 3a. HTTP-Only Deployment

```bash
# Start the service (HTTP only)
docker-compose up -d

# Access at: http://localhost
```

#### 3b. HTTPS Deployment with Let's Encrypt

Update your `.env` file:

```bash
ENABLE_HTTPS=true
DOMAIN=your-domain.com
EMAIL=your-email@example.com
```

Then deploy:

```bash
# Start the service with HTTPS
docker-compose up -d

# Access at: https://your-domain.com
```

**Note:** For HTTPS to work, ensure:

- Your domain points to your server's IP address
- Ports 80 and 443 are accessible from the internet
- The server can reach the internet for Let's Encrypt validation

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `NGINX_HTPASSWD` | Yes | Contents of `.htpasswd` file for HTTP Basic Auth |
| `ENABLE_HTTPS` | No | Set to `true` to enable HTTPS with Let's Encrypt |
| `DOMAIN` | Yes* | Your domain name (*required if `ENABLE_HTTPS=true`) |
| `EMAIL` | Yes* | Your email for Let's Encrypt (*required if `ENABLE_HTTPS=true`) |

## Updating Users

### Fly.io

- Update `.htpasswd` locally
- Re-upload the secret: `fly secrets set NGINX_HTPASSWD="$(cat .htpasswd)"`
- Re-deploy: `fly deploy`

### Docker Compose

- Update `.htpasswd` locally
- Update the `NGINX_HTPASSWD` value in `.env`
- Restart: `docker-compose restart`

## SSL Certificate Management

When `ENABLE_HTTPS=true`, the container automatically:

- Obtains SSL certificates from Let's Encrypt on first run
- Sets up automatic certificate renewal (runs daily at 12:00 PM)
- Handles certificate validation challenges

Certificates are stored in the `letsencrypt_data` volume and persist across container restarts.
