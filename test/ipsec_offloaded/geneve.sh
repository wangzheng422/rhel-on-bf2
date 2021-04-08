#!/usr/bin/env bash

if [[ "$1" -eq "0" ]]; then
  OUTER_REMOTE_IP=192.168.1.65
  OUTER_LOCAL_IP=192.168.1.64
else
  OUTER_REMOTE_IP=192.168.1.64
  OUTER_LOCAL_IP=192.168.1.65
fi

PF0=p0
VF0_REP=eth2

for ii in $VF0_REP $PF0
do
    tc qdisc del dev $ii ingress
    tc qdisc add dev $ii ingress
    ethtool -K $ii hw-tc-offload on
done

ifconfig $PF0 $OUTER_LOCAL_IP/24 up
ifconfig $VF0_REP up
# adding hw-tc-offload on
ethtool -K $VF0_REP hw-tc-offload on
ethtool -K $PF0 hw-tc-offload on
service openvswitch start
ovs-vsctl del-br ovs-br
ovs-vsctl add-br ovs-br
ovs-vsctl add-port ovs-br $VF0_REP
ovs-vsctl add-port ovs-br geneve -- set interface geneve type=geneve options:local_ip=$OUTER_LOCAL_IP options:remote_ip=$OUTER_REMOTE_IP
ovs-vsctl set Open_vSwitch . other_config:hw-offload=true
service openvswitch restart
ifconfig ovs-br up
ip link set $PF0 up
ip link set $VF0_REP up
ovs-vsctl show
