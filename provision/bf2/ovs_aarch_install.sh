#!/bin/bash

# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < ovs_aarch_install.sh
# Local host:
# 	./ovs_aarch_install.sh
#

yum install -y wget

# Ignore SSL certificate errors
grep -q "sslverify=false" /etc/yum.conf || echo "sslverify=false" >> /etc/yum.conf

VER_PART=$(uname -r | cut -d"-" -f2 | sed s/\.$(uname -m)//g)

wget -P /tmp http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/67.el8fdp/aarch64/openvswitch2.13-2.13.0-67.el8fdp.aarch64.rpm &> /dev/null &
wget -P /tmp http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/67.el8fdp/aarch64/python3-openvswitch2.13-2.13.0-67.el8fdp.aarch64.rpm &> /dev/null &
wget -P /tmp http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/67.el8fdp/aarch64/openvswitch2.13-devel-2.13.0-67.el8fdp.aarch64.rpm &> /dev/null &
wget -P /tmp http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch-selinux-extra-policy/1.0/23.el8fdp/noarch/openvswitch-selinux-extra-policy-1.0-23.el8fdp.noarch.rpm &> /dev/null &
wget -P /tmp http://download-node-02.eng.bos.redhat.com/brewroot/packages/kernel/4.18.0/$VER_PART/aarch64/kernel-modules-extra-$(uname -r).rpm

wait

cd /tmp || exit 1

dnf install -y \
openvswitch2.13-2.13.0-67.el8fdp.aarch64.rpm \
python3-openvswitch2.13-2.13.0-67.el8fdp.aarch64.rpm \
openvswitch2.13-devel-2.13.0-67.el8fdp.aarch64.rpm \
openvswitch-selinux-extra-policy-1.0-23.el8fdp.noarch.rpm \
kernel-modules-extra-$(uname -r).rpm

systemctl enable openvswitch
systemctl start openvswitch
systemctl status openvswitch
