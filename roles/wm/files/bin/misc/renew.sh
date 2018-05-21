#!/bin/bash
if [[ "$1" == "" ]]; then
    echo "no interface supplied, assuming eth1" 
    int="eth1"
elif [[ "$1" == "wlan1" ]]; then
    kill `ps ax | grep "dhclient wlan1" | grep -v grep | cut -d\  -f1`
    echo "ok, restarting wpa_supplicant" 
    kill -9 `pidof wpa_supplicant`
    int=$1
    wpa_supplicant -f /var/log/wpa_supplicant.log -B -iwlan1 -c/etc/wpa_supplicant/wpa_supplicant.conf
elif [[ "$1" == "wlan2" ]]; then
    kill `ps ax | grep "dhclient wlan2" | grep -v grep | cut -d\  -f1`
    echo "ok, restarting wpa_supplicant" 
    kill -9 `pidof wpa_supplicant`
    int=$1
    wpa_supplicant -f /var/log/wpa_supplicant.log -B -iwlan2 -c/etc/wpa_supplicant/wpa_supplicant.conf
else
    echo "interface = $1"
    int=$1
fi
echo "releasing ip"
dhclient -r $int
echo "renewing ip"
dhclient $int
