#!/bin/sh
# Start script for the Flagsmith Railway template.
# Sets safe defaults, migrates the database, creates the first admin once,
# then starts the API and dashboard on $PORT (IPv4 and IPv6, so the
# Railway private network works too).
set -e

# Safe defaults. Any of them can be overridden with a service variable.
export ENVIRONMENT="${ENVIRONMENT:-production}"
export DJANGO_ALLOWED_HOSTS="${DJANGO_ALLOWED_HOSTS:-*}"
export USE_POSTGRES_FOR_ANALYTICS="${USE_POSTGRES_FOR_ANALYTICS:-true}"
# Only invited users can register. Nobody can claim the instance through /api/v1/users/init/.
export ALLOW_REGISTRATION_WITHOUT_INVITE="${ALLOW_REGISTRATION_WITHOUT_INVITE:-false}"
export ALLOW_ADMIN_INITIATION_VIA_URL="${ALLOW_ADMIN_INITIATION_VIA_URL:-false}"
export ALLOW_ADMIN_INITIATION_VIA_CLI="${ALLOW_ADMIN_INITIATION_VIA_CLI:-true}"
# Without SMTP settings, print e-mails to the log instead of failing to send them.
if [ -z "${EMAIL_HOST:-}" ] && [ -z "${SENDGRID_API_KEY:-}" ]; then
  export EMAIL_BACKEND="${EMAIL_BACKEND:-django.core.mail.backends.console.EmailBackend}"
fi

if [ -z "${DATABASE_URL:-}" ]; then
  echo "DATABASE_URL is not set. Point it at a PostgreSQL database." >&2
  exit 1
fi
if [ -z "${DJANGO_SECRET_KEY:-}" ]; then
  echo "DJANGO_SECRET_KEY is not set. Set it to a long random string." >&2
  exit 1
fi
if [ -z "${ADMIN_EMAIL:-}" ]; then
  echo "ADMIN_EMAIL is not set. Set it to the e-mail address of the first admin." >&2
  exit 1
fi

# On a fresh deploy the database and its private host name can take a minute
# to come up, and Flagsmith's own wait gives up after 5 seconds. Wait longer.
flagsmith waitfordb --waitfor "${DB_WAIT_SECONDS:-180}"

# Applies migrations and creates the cache table.
flagsmith migrate

# Creates the first admin, organisation and project, only while no user exists yet.
flagsmith bootstrap

# Give the first admin ADMIN_PASSWORD, but only while it has no password of its own.
if [ -n "${ADMIN_PASSWORD:-}" ]; then
  flagsmith shell -c '
import os
from users.models import FFAdminUser
u = FFAdminUser.objects.filter(email__iexact=os.environ["ADMIN_EMAIL"]).first()
if u is not None and not u.has_usable_password():
    u.set_password(os.environ["ADMIN_PASSWORD"])
    u.save(update_fields=["password"])
    print("Set the password of %s from ADMIN_PASSWORD." % u.email)
'
fi

# Listen on $PORT on IPv4 and IPv6 (Railway's private network uses IPv6).
export GUNICORN_CMD_ARGS="--bind [::]:${PORT:-8000} ${GUNICORN_CMD_ARGS:-}"
exec flagsmith serve
