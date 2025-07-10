
# MindsDB on Fly.io (with Nginx HTTP Basic Auth)

This project runs [MindsDB](https://mindsdb.com) behind an Nginx reverse proxy that uses HTTP Basic Authentication.  
Multiple users are supported via a standard `.htpasswd` file—managed as a Fly.io secret.

## Quick Usage

### 1. **Add or Manage Users**

Generate or update your `.htpasswd` file locally using `htpasswd` (from `apache2-utils`):

```bash
# Create or update .htpasswd with your users:
htpasswd -c .htpasswd alice     # Add 'alice' (prompts for password)
htpasswd .htpasswd bob          # Add 'bob'
htpasswd .htpasswd charlie      # etc.
```

### 2. **Set the `.htpasswd` File as a Fly.io Secret**

```bash
fly secrets set NGINX_HTPASSWD="$(cat .htpasswd)"
```

### 3. **Deploy to Fly.io**

```bash
fly deploy
```

## **Updating Users**

- To add, remove, or change passwords: update `.htpasswd` locally, re-upload the secret, and re-deploy.

## **Access**

- Visit `https://mindsdb.fly.dev`
- Login with any username/password you added to `.htpasswd`

## **Files**

- `Dockerfile` – Runs MindsDB and Nginx
- `nginx.conf` – Nginx reverse proxy config
- `entrypoint.sh` – Entrypoint script to load `.htpasswd` from Fly secret
- `fly.toml` – Fly.io app config

## **Security**

- All access is protected by HTTP Basic Auth via Nginx.
- User management is handled through the `.htpasswd` secret.

