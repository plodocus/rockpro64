#!/bin/bash
# Certbot pre-authentication script.
# Puts a single TXT record to subdomains of $CERTBOT_DOMAIN (DuckDNS does that for all subdomains).
# Queries TXT record and exits when it matches $CERTBOT_VALIDATION.
TOKEN=$(cat "/etc/duckdns.org/token")
URL="https://www.duckdns.org/update?domains=${CERTBOT_DOMAIN}&token=${TOKEN}&txt=${CERTBOT_VALIDATION}"
curl -s "${URL}" >> /dev/null
UPDATED=0
while [ "$UPDATED" -eq 0 ]
do
	DOMAIN="_acme-challenge.${CERTBOT_DOMAIN}"
	TXT=$(dig -t txt +short ${DOMAIN})
	UPDATED=$(echo ${TXT} | grep -c ${CERTBOT_VALIDATION})
	if [ "$UPDATED" -eq 0 ]
	then
		sleep 20s
	fi
done
