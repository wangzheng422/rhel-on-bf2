#!/bin/env bash

# Assuming this script is run from a container based on
# registry.redhat.io/rhel8/support-tools like the toolbox container in openshift

curl -kO https://download-node-02.eng.bos.redhat.com/brewroot/packages/kernel/4.18.0/240.el8/$(uname -m)/kernel-devel-4.18.0-240.el8.$(uname -m).rpm
curl -kO https://download-node-02.eng.bos.redhat.com/brewroot/packages/zstd/1.4.4/1.el8/$(uname -m)/zstd-1.4.4-1.el8.$(uname -m).rpm
curl -kO https://gitlab.cee.redhat.com/egarver/smart-nic-poc/-/raw/master/provision/bf2/mst.sh
curl -kO https://download-node-02.eng.bos.redhat.com/brewroot/packages/kernel/4.18.0/240.el8/aarch64/kernel-modules-4.18.0-240.el8.aarch64.rpm
curl -kO https://linux.mellanox.com/public/repo/mlnx_ofed/5.1-2.3.7.1/rhel8.1/aarch64/mft-4.15.1-9.arm64.rpm

curl -kO https://download-node-02.eng.bos.redhat.com/brewroot/packages/kernel/4.18.0/240.el8/$(uname -m)/kernel-4.18.0-240.el8.$(uname -m).rpm
curl -kO https://download-node-02.eng.bos.redhat.com/brewroot/packages/kernel/4.18.0/240.el8/$(uname -m)/kernel-core-4.18.0-240.el8.$(uname -m).rpm
curl -kO http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/linux-firmware/20201118/101.git7455a360.el8/noarch/linux-firmware-20201118-101.git7455a360.el8.noarch.rpm
curl -kO http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/usbutils/010/3.el8/$(uname -m)/usbutils-010-3.el8.$(uname -m).rpm
curl -kO http://mirror.centos.org/centos/8/AppStream/$(uname -m)/os/Packages/rpm-build-4.14.3-4.el8.$(uname -m).rpm

dnf install -y \
kernel-4.18.0-240.el8.$(uname -m).rpm \
kernel-core-4.18.0-240.el8.$(uname -m).rpm \
kernel-modules-4.18.0-240.el8.$(uname -m).rpm \
kernel-devel-4.18.0-240.el8.$(uname -m).rpm \
gcc rpm-build make kmod pciutils kernel-devel-4.18.0-240.el8.$(uname -m).rpm \
linux-firmware-20201118-101.git7455a360.el8.noarch.rpm \
rpm-build-4.14.3-4.el8.$(uname -m).rpm \
zstd-1.4.4-1.el8.$(uname -m).rpm \
usbutils-010-3.el8.$(uname -m).rpm

chmod +x mst.sh
./mst.sh --install
