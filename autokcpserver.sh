#!/bin/bash
TTI="$1"
UPLINKCAP="$2"
NIC=venet #network interface controller

sed -i "s/\"tti\"[^,]*,/\"tti\":${TTI},/g" /etc/v2ray/config.json
sed -i "s/\"uplinkCapacity\"[^,]*,/\"uplinkCapacity\":${UPLINKCAP},/g" /etc/v2ray/config.json
systemctl restart v2ray.service && \
    echo "$[TTI] $[UPLINKCAP] `awk '/'"$NIC"'/{print $2}' /proc/net/dev` `awk '/'"$NIC"'/{print $10}' /proc/net/dev`"\
    >>serverresult.txt
