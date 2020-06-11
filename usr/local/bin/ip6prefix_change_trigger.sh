ip -6 monitor dev eth0 | while read word1 otherparms
do
    if [ "$word1" = "Deleted" ]
    then
        duckdns_update_ip6.sh
    fi
done

