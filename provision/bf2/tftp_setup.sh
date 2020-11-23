#!/bin/bash

yum install -y tftp wget
wget http://download.eng.bos.redhat.com/released/RHEL-8/8.3.0/BaseOS/aarch64/iso/RHEL-8.3.0-20201009.2-BaseOS-aarch64-boot.iso
mount -t iso9660 -o loop RHEL-8.3.0-20201009.2-BaseOS-aarch64-boot.iso /mnt/
mkdir -p /var/lib/tftpboot/RHEL/8.3
cp /mnt/EFI/BOOT/BOOTAA64.EFI /var/lib/tftpboot/
cp /mnt/EFI/BOOT/grubaa64.efi /var/lib/tftpboot/
cp /mnt/images/pxeboot/vmlinuz /var/lib/tftpboot/RHEL/8.3/
cp /mnt/images/pxeboot/initrd.img /var/lib/tftpboot/RHEL/8.3/initrd-orig.img
mkdir -p /tmp/.bfrhel
mkdir -p /tmp/.bfinstdd
cd /tmp/.bfrhel/
xzcat /var/lib/tftpboot/RHEL/8.3/initrd-orig.img | cpio -idm
mount /root/BlueField-3.1.0.11424/distro/rhel/bluefield_dd/bluefield_dd-4.18.0-80.7.2.el7.aarch64.iso /tmp/.bfinstdd
cp /root/BlueField-3.1.0.11424/distro/rhel/bluefield_dd/bluefield_dd-4.18.0-80.7.2.el7.aarch64.iso ./bluefield_dd.iso


