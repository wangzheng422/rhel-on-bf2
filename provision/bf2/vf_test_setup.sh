#!/bin/bash

if [ "$#" -ne 2 ]; then
        echo "Usage: ./vf_test_setup <worker_ip> <SoC_ip> <client_ip>"
        exit
fi

WORKER=$1
BF=$2
CLIENT=$3

WORKER_IP=10.0.0.1
CLIENT_IP=10.0.0.2
BF_IP=10.0.0.3

ssh "$WORKER" yum install -y podman
ssh "$CLIENT" yum install -y podman

podman run alpine echo "Creating cni-podman0"
ip link add veth0 type veth peer name veth1
ip link set veth1 master cni-podman0
ovs-vsctl add-br ovsbr0
ovs-vsctl add-port ovsbr0 veth0

$POD_NS=ssh $WORKER "ip netns list | cut -d' ' -f1"
ssh $WORKER ip netns exec $POD_NS ip a add $WORKER_IP/24 dev ens1f0v1
ssh $BF ovs-vsctl add-port ovsbr0 geneve -- set interface geneve type=geneve options:remote_ip=$CLIENT_IP
ssh $CLIENT ovs-vsctl add-port ovsbr0 geneve -- set interface geneve type=geneve options:remote_ip=$BF_IP

ip link set veth0 up
ip link set veth1 up
