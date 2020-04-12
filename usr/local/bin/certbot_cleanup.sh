#!/bin/bash
# Clears TXT record at DuckDNS subdomains.
TOKEN=$(cat "/etc/duckdns.org/token")
URL="https://www.duckdns.org/update?domains=${CERTBOT_DOMAIN}&token=${TOKEN}&txt=cleanup&clear=true"
curl -s "${URL}" >> /dev/null
