#!/bin/bash

# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < mst_install.sh [--install]
# Local host:
# 	./mst_install.sh [--install]
#

function install {
	if [ "$(uname -r | cut -d. -f5)" = aarch64 ]; then
		MFT_VER=mft-4.15.1-9-arm64
	else
		MFT_VER=mft-4.15.1-9-x86_64
	fi
	yum install -y wget kernel-devel-"$(uname -r)" &
	wget -P /tmp https://www.mellanox.com/downloads/MFT/$MFT_VER-rpm.tgz &>/dev/null &
	wait
	cd /tmp || exit 1
	tar xf $MFT_VER-rpm.tgz
	cd $MFT_VER-rpm || exit 1
	./install.sh
	mst start
}

if [[ $1 == "--install" ]]; then
	install
fi

mst start
MST=$(mst status | grep -Po "/dev/mst/[\w\d]+")
if mlxconfig -d "$MST" q | grep SRIOV_EN | grep -q "True\|1"; then
	echo "SRIOV enabled"
else
	echo "SRIOV needs to be enabled in BIOS"
fi

if mlxconfig -e -d "$MST"  q | grep -i internal |  cut -d' ' -f28 | grep -q EMBEDDED_CPU\(1\); then
	echo "EMBEDDED_CPU mode enabled"
else
	echo "SEPARATED_HOST mode enabled, cannot proceed with VF setup"
	if mlxconfig -e -d "$MST" q | grep -i internal | cut -d' ' -f29 | grep -q EMBEDDED_CPU\(1\); then
		echo "EMBEDDED_CPU mode is set to be enabled on next boot. Power cycle the system to enable it."
	else
		echo "Enabling EMBEDDED_CPU mode"
		mlxconfig -d "$MST" s INTERNAL_CPU_MODEL=1
		mlxconfig -d "$MST".1 s INTERNAL_CPU_MODEL=1
		echo "EMBEDDED_CPU mode will be enabled on next boot. Power cycle the system to enable it."
	fi	
	exit 1
fi
