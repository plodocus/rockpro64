#!/bin/bash
# Updates the IP6 at duckdns.org

DOMAINS=$(cat "/etc/duckdns.org/domains")
TOKEN=$(cat "/etc/duckdns.org/token")
IP=$(get_ip6.sh)
URL="https://www.duckdns.org/update?domains=${DOMAINS}&token=${TOKEN}&ipv6=${IP}"

curl --url $URL
