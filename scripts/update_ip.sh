#!/bin/bash
# Updates the IP6 at duckdns.org

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DOMAINS=$(cat "${DIR}/domains")
TOKEN=$(cat "${DIR}/token")
IP=$("${DIR}/get_ip.sh")
URL="https://www.duckdns.org/update?domains=${DOMAINS}&token=${TOKEN}&ipv6=${IP}"

curl --url $URL
