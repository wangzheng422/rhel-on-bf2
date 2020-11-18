#!/bin/bash

# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < rshim_userspace_install.sh
# Local host:
# 	./rshim_userspace_install.sh
#

yum install -y automake autoconf elfutils-libelf-devel fuse-devel git kernel-modules-extra libusb-devel make pciutils-devel rpm-build tmux
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
stystemctl enable --now rshim
systemctl status rshim
