#!/bin/sh
# Waits for newly created files in letsencrypt's archive folder and concatenates
# fullchain and privkey so that haproxy can use it

LEDIR="/etc/letsencrypt/live"
HPXDIR="/etc/haproxy/certs"
# wait for new files
inotifywait -mqr -e create "/etc/letsencrypt/archive" | while read line
do
    ## wait a few seconds so that all certificates are generated
    sleep 10s
    # loop over all domains
    find $LEDIR -mindepth 1 -maxdepth 1 -type d | while read line
    do
        # keep domain name
        FILENAME=$(echo $line | grep -o -P "(?<=${LEDIR}/).*")
        # concatenate fullchain and privkey
        cat "${line}/fullchain.pem" "${line}/privkey.pem" > "${HPXDIR}/${FILENAME}.pem"
    done
done
