#!/bin/bash

# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < rshim_userspace_install.sh
# Local host:
# 	./rshim_userspace_install.sh
#
# The card should be accessible by /dev/ttyUSB0 like this:
# minicom --color on --baudrate 115200 --device /dev/ttyUSB0
#
# If uart cable is not available, this is another option:
# minicom --color on --baudrate 115200 --device /dev/rshim0/console
#
# Once the rshim drivers have been succesfully installed, /dev/rshim0 should have been created.
# To prepare the card for provisioning, use the following commands:
# echo BOOT_MODE 1 > /dev/rshim0/misc
# echo SW_RESET 1 > /dev/rshim0/misc
#

yum install -y automake autoconf elfutils-libelf-devel fuse-devel gcc git kernel-modules-extra libusb-devel make pciutils-devel rpm-build tmux
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
