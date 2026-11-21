# Caddy with the Duck DNS plugin, so Let's Encrypt can check the hostname through
# DNS instead of over ports 80 and 443
FROM caddy:2.10-builder-alpine AS builder
RUN xcaddy build --with github.com/caddy-dns/duckdns@v0.5.0

FROM caddy:2.10-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
