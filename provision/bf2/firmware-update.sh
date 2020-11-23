#!/bin/bash

yum install -y wget
wget http://www.mellanox.com/downloads/BlueField/BlueField-3.1.0.11424/BlueField-3.1.0.11424_install.bfb
cat BlueField-3.1.0.11424_install.bfb > /dev/rshim0/boot

# Log in with passwordless user: root
# Run the following commands:
# ~]# /opt/mellanox/scripts/bfrec
# ~]# reboot
# Repeat the previous step and again log into yocto with passwordless root
# cat BlueField-3.1.0.11424_install.bfb > /dev/rshim0/boot
# ~]# /lib/firmware/mellanox/mlxfwmanager_sriov_dis_aarch64_41686
# Perform FW update? [y/N] - y
# reboot x86_64 host
