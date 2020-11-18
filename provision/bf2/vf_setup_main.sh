#!/bin/bash

if [ "$#" -ne 2 ]; then
        echo "Usage: ./vf_setup_main <x86 host> <BFv2 host> <num_vfs>"
        exit
fi
HOST=$1
BF2=$2

ssh $BF2 "curl -sk https://gitlab.cee.redhat.com/fdangelo/mellanox/-/raw/master/mst.sh | bash"
if [ $? -ne 0 ]; then
	echo "Error encountered, exiting"
	exit 1
fi

ssh $HOST modprobe -rv mlx5_{ib,core}
ssh $BF2 devlink dev eswitch set pci/0000:03:00.0 mode switchdev
ssh $HOST modprobe -av mlx5_{ib,core}
ssh $HOST echo $3 > /sys/class/net/ens1f0/device/sriov_numvfs
