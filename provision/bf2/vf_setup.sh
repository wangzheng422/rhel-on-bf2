#!/bin/bash

# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < vf_setup <network_interface> <numvfs>
# Local host:
#	./vf_setup <network_interface> <numvfs>
#

if [ "$#" -ne 2 ]; then
        echo "Usage: ./vf_setup <network_interface> <numvfs>"
        exit
fi

PCI=($(lspci -D | grep "Eth.*nox.*Blue" | cut -d' ' -f1))
for i in ${PCI[@]}; do
        if [ $(ls /sys/bus/pci/devices/$i/net) = $1 ]
        then
                SRIOV_PATH=/sys/bus/pci/devices/$i/net/$1/device/sriov_numvfs
        fi
done

echo "$2" > "$SRIOV_PATH"

if [ "$(lspci | grep -c "nox.*Virtual")" == "$2" ]
then
        echo "Virtual functions successfully enabled."
        lspci | grep "nox.*Virtual"
else
        echo "Failure"
fi
