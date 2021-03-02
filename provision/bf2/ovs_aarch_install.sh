#!/bin/bash

# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < ovs_aarch_install.sh
# Local host:
# 	./ovs_aarch_install.sh
#

# Ignore SSL certificate errors
grep -q "sslverify=false" /etc/yum.conf || echo "sslverify=false" >> /etc/yum.conf

BREW_ROOT="http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/"
OVS_RPMS="openvswitch2.13/2.13.0/86.el8fdp/aarch64/openvswitch2.13-2.13.0-86.el8fdp.aarch64.rpm
          openvswitch2.13/2.13.0/86.el8fdp/aarch64/python3-openvswitch2.13-2.13.0-86.el8fdp.aarch64.rpm
          openvswitch2.13/2.13.0/86.el8fdp/aarch64/openvswitch2.13-devel-2.13.0-86.el8fdp.aarch64.rpm
          openvswitch2.13/2.13.0/86.el8fdp/aarch64/openvswitch2.13-ipsec-2.13.0-86.el8fdp.aarch64.rpm
          openvswitch-selinux-extra-policy/1.0/28.el8fdp/noarch/openvswitch-selinux-extra-policy-1.0-28.el8fdp.noarch.rpm"

dnf install -y kernel-modules-extra $(for I in ${OVS_RPMS}; do echo ${BREW_ROOT}${I}; done)

systemctl enable openvswitch
systemctl start openvswitch
systemctl status openvswitch --no-pager -l
