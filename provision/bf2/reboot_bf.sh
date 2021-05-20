#!/bin/bash

# Run this script on x86 host to safely reboot the BF2 card
#
# Prerequisite setup:
#
# run switchdev setup script on BF:
#	add_connectx_eswitch_mode_config_service.sh
# 
# Create connection between host and BF via tmfifo
# May be named eth0 or tmfifo_net0 on BF host
# Example:
#	  On Host:
#	  nmcli device connect tmfifo_net0
#	  nmcli con mod tmfifo_net0 ipv4.addresses 10.1.0.1/24
#	  On BF2:
#	  nmcli device connect tmfifo_net0
#	  nmcli con mod tmfifo_net0 ipv4.addresses 10.1.0.2/24
#
# set up ssh key access between the two

SUBNET="172.31.100"

# wait for card to come up
echo "=== STATUS === Rebooting all BF2 cards..."

ALIVE=""
for I in $(seq 10 20); do
	ping -w 1 ${SUBNET}.${I} >/dev/null 2>&1 || continue
	ALIVE="${ALIVE} ${I}"
done

test -z "${ALIVE}" && { printf "!!! ERROR !!! No BF2s are alive\n"; exit 1; }

for I in ${ALIVE}; do
	ssh root@${SUBNET}.${I} reboot
done
printf "=== STATUS === %s" "waiting for connection to Bluefield..."
sleep 10
for I in ${ALIVE}; do
	while ! timeout 0.2 ping -c 1 -n ${SUBNET}.${I} &> /dev/null
	do
		printf "%c" "."
	done
done
