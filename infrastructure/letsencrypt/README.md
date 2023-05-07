# Letsencrypt

Get/renew letsencrypt certificates using route53 DNS auth.

This needs to be done every 30 days, and certificates need to be copied to the
traefik directory.

## Known issues

- There is confusion about the correct location /certs vs /certs/conf of the certs.
  I can't fix this right now because of rate limits.
