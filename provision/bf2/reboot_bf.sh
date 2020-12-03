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

# wait for card to come up
modprobe -rv mlx5_{ib,core}
wait 2
echo "Rebooting SoC..."
ssh root@10.1.0.2 reboot
wait 10
printf "%s" "waiting for connection to Bluefield..."
while ! timeout 0.2 ping -c 1 -n 10.1.0.2 &> /dev/null
do
    printf "%c" "."
done
modprobe -av mlx5_{ib,core}
