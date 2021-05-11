#!/usr/bin/env bash

DEV=ens1f0v0
ip link set $DEV mtu 1416

ip a f $DEV
if [[ "$1" -eq "1" ]]; then
ip a a 15.15.15.1/24 dev $DEV
else
ip a a 15.15.15.2/24 dev $DEV
fi

ip link set $DEV up
