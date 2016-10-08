#!/bin/bash
TTI="$1"
UPLINKCAP="$2"
NIC=venet #network interface controller

sed -i "s/\"tti\"[^,]*,/\"tti\":${TTI},/g" /etc/v2ray/config.json
sed -i "s/\"uplinkCapacity\"[^,]*,/\"uplinkCapacity\":${UPLINKCAP},/g" /etc/v2ray/config.json
systemctl restart v2ray.service && echo "$[TTI]:$[UPLINKCAP]:`grep $NIC /proc/net/dev |awk '{print $2}'`:`grep ${NIC} /proc/net/dev |awk '{print $10}'`">>serverresult.txt
