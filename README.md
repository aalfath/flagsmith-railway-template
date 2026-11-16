# Flagsmith on Railway

A Railway template for [Flagsmith](https://www.flagsmith.com/), the open-source feature flag and remote config platform. It deploys the Flagsmith API and dashboard (one service) with a PostgreSQL database, so the apps in your Railway project can read their flags over the private network.

- **Flagsmith version:** 2.291.0 (`flagsmith/flagsmith:2.291.0@sha256:1bf1653f69acac1fc44e06da986f107845e0909dd81601e2a9f16c277056ac1d`)
- **Services:** `Flagsmith` (built from this repo, public domain, health check `/health/liveness/`) and `Postgres` (Railway's PostgreSQL, data on a volume)

## What the wrapper does

`railway-start.sh` runs before Flagsmith starts. It:

1. sets safe defaults: production mode, analytics in Postgres, **no sign-up without an invite**, the `/api/v1/users/init/` claim URL switched off, and e-mails printed to the log until you add SMTP;
2. applies database migrations;
3. creates the first admin (`ADMIN_EMAIL`), a default organisation and a default project, only while the database has no users;
4. gives that admin the password in `ADMIN_PASSWORD`, only while the admin has no password yet (later password changes in the dashboard are kept);
5. starts the API and dashboard on `$PORT`, listening on IPv4 and IPv6 so the Railway private network works.

## Variables

| Variable | Default | What it is |
|---|---|---|
| `ADMIN_EMAIL` | *(you enter it)* | E-mail of the first admin; you log in with it |
| `ADMIN_PASSWORD` | `${{secret(24)}}` | First admin password, generated; read it in the service's Variables tab |
| `DJANGO_SECRET_KEY` | `${{secret(64)}}` | Django secret key, generated |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | PostgreSQL connection string; point it at an existing Postgres to reuse one |
| `FLAGSMITH_DOMAIN` | `${{RAILWAY_PUBLIC_DOMAIN}}` | Public host name used in links and e-mails |
| `DJANGO_CSRF_TRUSTED_ORIGINS` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Lets the Django admin at `/admin/` accept logins |
| `PORT` | `8000` | Port the server listens on |

Optional settings (SMTP e-mail, OAuth, the task processor, open sign-up) are documented in [Flagsmith's API settings](https://docs.flagsmith.com/deployment/hosting/locally-api#environment-variables). Add them as service variables; any variable you set wins over the wrapper's defaults.

## Using it from your other Railway services

Your apps call the Flagsmith API inside the project, with no public traffic:

```
FLAGSMITH_API_URL=http://${{Flagsmith.RAILWAY_PRIVATE_DOMAIN}}:${{Flagsmith.PORT}}/api/v1/
FLAGSMITH_ENVIRONMENT_KEY=<server-side key from the dashboard: Environment settings, Keys>
```

Browser and mobile SDKs use the public URL `https://YOUR-DOMAIN/api/v1/` with the client-side environment key.

## Updates

This template builds from this repo's `main` branch. When a new Flagsmith release is tested, the pin in `Dockerfile` is bumped and an entry is added to `CHANGELOG.md`. Railway then shows an "update available" notice on projects deployed from the template, and you choose when to apply it. Read `CHANGELOG.md` first: breaking changes are listed at the top of each entry. Flagsmith applies its database migrations on start.
