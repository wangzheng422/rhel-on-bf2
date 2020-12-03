#!/bin/bash

# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < rshim_userspace_install.sh
# Local host:
# 	./rshim_userspace_install.sh
#
#
# Once the rshim drivers have been succesfully installed, /dev/rshim0 should have been created.
# To prepare the card for provisioning, use the following commands:
# echo BOOT_MODE 1 > /dev/rshim0/misc
# echo SW_RESET 1 > /dev/rshim0/misc
#
# The card should be accessible by /dev/ttyUSB0 like this:
# minicom --color on --baudrate 115200 --device /dev/ttyUSB0
#
# If uart cable is not available, this is another option:
# minicom --color on --baudrate 115200 --device /dev/rshim0/console
#
# Press the ESC key during boot to enter BF2 boot menu.
# Enter the "Boot Manager" option to choose boot device.

if [ "$(cat /etc/redhat-release | cut -d' ' -f 6)" = 8.2 ]; then
	dnf install -y http://download.eng.bos.redhat.com/composes/nightly-rhel-8/RHEL-8/latest-RHEL-8/compose/CRB/x86_64/os/Packages/libusb-devel-0.1.5-12.el8.x86_64.rpm
fi

yum install -y automake autoconf elfutils-libelf-devel fuse-devel gcc git kernel-modules-extra libusb-devel make minicom pciutils-devel rpm-build tmux
cd /tmp || exit 1
git clone https://github.com/Mellanox/rshim-user-space.git
cd rshim-user-space || exit 1
./bootstrap.sh
./configure

/bin/rm -rf /tmp/mybuildtest
rpm_topdir=/tmp/mybuildtest
mkdir -p $rpm_topdir/{RPMS,BUILD,SRPM,SPECS,SOURCES}
version=$(grep "Version:" *.spec | head -1 | awk '{print $NF}')
git archive --format=tgz --prefix=rshim-"${version}"/ HEAD > $rpm_topdir/SOURCES/rshim-${version}.tar.gz
rpmbuild -ba --nodeps --define "_topdir $rpm_topdir" --define 'dist %{nil}' *.spec

rpm -ivh $rpm_topdir/RPMS/*/*rpm
systemctl enable --now rshim
systemctl status rshim
