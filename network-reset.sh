#!/bin/bash

if [ "$1" = '-r' ]; then
	echo Resetting card...
	echo SW_RESET 1 > /dev/rshim0/misc
	sleep 15
fi

nmcli connection down tmfifo_net0
systemctl restart rshim.service
nmcli connection up tmfifo_net0
systemctl restart dhcpd
iptables -t nat -A POSTROUTING -o "$(ip route |grep ^default | sed 's/.*dev \([^ ]\+\).*/\1/')" -j MASQUERADE

if [ "$1" != '-r' ]; then
	echo You should now try getting an ip address from the DPU:
	echo   minicom --color on --baudrate 115200 --device /dev/rshim0/console
	echo   nmcli connection down System\ eth0
	echo   nmcli connection up System\ eth0
fi
