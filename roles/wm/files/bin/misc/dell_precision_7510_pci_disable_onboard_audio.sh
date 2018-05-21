#!/bin/bash
pcidevice=`lspci | grep -i audio | grep -i intel | cut -d\  -f1`
echo 1 > /sys/devices/pci0000\:00/0000\:$pcidevice/remove
