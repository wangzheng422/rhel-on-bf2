#!/bin/bash

#!/bin/bash

# rshim installation should be done first
# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < mst_install.sh [--install]
# Local host:
# 	./mst_install.sh [--install]
#

function mst_install {
	if [ "$(uname -r | cut -d. -f5)" = aarch64 ]; then
		MFT_VER=mft-4.15.1-9-arm64
	else
		MFT_VER=mft-4.15.1-9-x86_64
	fi
	yum install -y tar wget kernel-devel-"$(uname -r)" &
	wget -P /tmp https://www.mellanox.com/downloads/MFT/$MFT_VER-rpm.tgz &>/dev/null &
	wait
	cd /tmp || exit 1
	tar xf $MFT_VER-rpm.tgz
	cd $MFT_VER-rpm || exit 1
	./install.sh
	mst start
}

function rshim_install {
	if [ "$(cat /etc/redhat-release | cut -d' ' -f 6)" = 8.2 ]; then
		dnf install -y http://download.eng.bos.redhat.com/composes/nightly-rhel-8/RHEL-8/latest-RHEL-8/compose/CRB/x86_64/os/Packages/libusb-devel-0.1.5-12.el8.x86_64.rpm
	fi

	yum install -y automake autoconf elfutils-libelf-devel fuse-devel gcc git kernel-modules-extra libusb-devel make minicom pciutils-devel rpm-build tmux
	cd /tmp || exit 1
	git clone https://github.com/Mellanox/rshim-user-space.git
	cd rshim-user-space || exit 1
	./bootstrap.sh
	./configure


	rpm_topdir=/tmp/rshim_provision_build
	/bin/rm -rf $(rpm_topdir)
	mkdir -p $rpm_topdir/{RPMS,BUILD,SRPM,SPECS,SOURCES}
	version=$(grep "Version:" *.spec | head -1 | awk '{print $NF}')
	git archive --format=tgz --prefix=rshim-"${version}"/ HEAD > $rpm_topdir/SOURCES/rshim-${version}.tar.gz
	rpmbuild -ba --nodeps --define "_topdir $rpm_topdir" --define 'dist %{nil}' *.spec

	rpm -ivh $rpm_topdir/RPMS/*/*rpm
	systemctl enable --now rshim
	systemctl status rshim

}

function firmware_update {

	if ! rpm -qa | grep -q rshim; then
		rshim_install
	fi

	if [ ! -f /usr/bin/mst ]; then
		mst_install
	fi

	wget http://www.mellanox.com/downloads/BlueField/BlueField-3.1.0.11424/BlueField-3.1.0.11424_install.bfb
	cat BlueField-3.1.0.11424_install.bfb > /dev/rshim0/boot
	cat << EOF
Use minicom to access to access card.
If UART cable is connected: minicom --color on --baudrate 115200 --device /dev/ttyUSB0
Else: minicom --color on --baudrate 115200 --device /dev/rshim0/console
                                                                                       
Log in with passwordless user: root
Run the following commands:
~]# /opt/mellanox/scripts/bfrec
~]# reboot
Repeat the previous step and again log into yocto with passwordless root
cat BlueField-3.1.0.11424_install.bfb > /dev/rshim0/boot
~]# /lib/firmware/mellanox/mlxfwmanager_sriov_dis_aarch64_41686
Perform FW update? [y/N] - y
reboot x86_64 host
EOF
}


function sriov_check {
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
}

while getopts "rmfsp:" opt; do
    case $opt in
        r)
	    rshim_install
            ;;
        m)
	    mst_install
            ;;
        f)
	    firmware_update
            ;;
        s)
	    sriov_check
            ;;
        \?)
	    echo help
            exit -1
            ;;
    esac
done
