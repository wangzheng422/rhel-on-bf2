#!/bin/bash

# Creates GENEVE tunnel to specified remote ip.
# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < pod2pod_setup.sh <remote_ip>
# Local host:
# 	./pod2pod_setup.sh <remote_ip> 
#

if [ "$#" -ne 1 ]; then
        echo "Usage: ./pod2pod <remote_ip>"
        exit
fi

yum install -y podman

podman run alpine echo "Creating cni-podman0"
ip link add veth0 type veth peer name veth1
ip link set veth1 master cni-podman0
ovs-vsctl add-br ovsbr0
ovs-vsctl add-port ovsbr0 veth0
ovs-vsctl add-port ovsbr0 geneve -- set interface geneve type=geneve options:remote_ip=$1
ip link set veth0 up
ip link set veth1 up
