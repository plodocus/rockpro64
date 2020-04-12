#!/bin/bash
# Gets first current global IP6
ip6=$(/sbin/ip -6 addr show dev eth0 scope global | grep -P '(?<=inet6 ).*(?=/)' -o -m1)
echo $ip6
