# Flagsmith (API + dashboard in one image), pinned by version and digest.
# Bump both the tag and the digest together, and add a CHANGELOG.md entry.
FROM flagsmith/flagsmith:2.291.0@sha256:1bf1653f69acac1fc44e06da986f107845e0909dd81601e2a9f16c277056ac1d

COPY --chmod=0755 railway-start.sh /app/railway-start.sh

EXPOSE 8000
ENTRYPOINT ["/app/railway-start.sh"]
