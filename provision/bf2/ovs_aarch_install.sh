#!/bin/bash

# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < ovs_aarch_install.sh
# Local host:
# 	./ovs_aarch_install.sh
#

yum install -y wget

wget -P /tmp http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/60.el8fdp/aarch64/openvswitch2.13-2.13.0-60.el8fdp.aarch64.rpm &> /dev/null &
wget -P /tmp http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/60.el8fdp/aarch64/python3-openvswitch2.13-2.13.0-60.el8fdp.aarch64.rpm &> /dev/null &
wget -P /tmp http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch-selinux-extra-policy/1.0/22.el8fdp/noarch/openvswitch-selinux-extra-policy-1.0-22.el8fdp.noarch.rpm &> /dev/null &

wait

cd /tmp || exit 1

dnf install -y openvswitch2.13-2.13.0-60.el8fdp.aarch64.rpm python3-openvswitch2.13-2.13.0-60.el8fdp.aarch64.rpm openvswitch-selinux-extra-policy-1.0-22.el8fdp.noarch.rpm

systemctl enable openvswitch
systemctl start openvswitch
systemctl status openvswitch
