#!/bin/bash
# Gets first current non-local global IP6 of eth0
ip6=$(/sbin/ip -6 addr show dev eth0 scope global | grep -P '(?<=inet6 )(?!fd00|fe80).*(?=/)' -o -m1)
echo $ip6
