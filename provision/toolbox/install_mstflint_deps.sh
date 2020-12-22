#!/bin/env bash

set -o errexit

# Assuming this script is run from a container based on
# registry.redhat.io/rhel8/support-tools like the toolbox container in openshift

# podman login registry.redhat.io # and use your access.redhat.com credentials
# uuid=$(podman pull registry.redhat.io/rhel8/support-tools)
# podman run -it $uuid
# curl -kO https://gitlab.cee.redhat.com/egarver/smart-nic-poc/-/raw/master/provision/install_mstflint_in_toolbox.sh
# chmod +x install_mstflint_in_toolbox.sh

if [ "$(uname -m)" = aarch64 ]; then
    MFT_VER_PART=arm64
else
    MFT_VER_PART=x86_64
fi

VER_PART=$(uname -r | cut -d"-" -f2 | sed s/\.$(uname -m)//g)

curl -kO https://download-node-02.eng.bos.redhat.com/brewroot/packages/kernel/4.18.0/$VER_PART/$(uname -m)/kernel-devel-$(uname -r).rpm
curl -kO https://download-node-02.eng.bos.redhat.com/brewroot/packages/zstd/1.4.4/1.el8/$(uname -m)/zstd-1.4.4-1.el8.$(uname -m).rpm
curl -kO https://gitlab.cee.redhat.com/egarver/smart-nic-poc/-/raw/master/provision/bf2/mst.sh
curl -kO https://download-node-02.eng.bos.redhat.com/brewroot/packages/kernel/4.18.0/$VER_PART/$(uname -m)/kernel-modules-$(uname -r).rpm
curl -kO https://linux.mellanox.com/public/repo/mlnx_ofed/5.1-2.3.7.1/rhel8.1/$(uname -m)/mft-4.15.1-9.$MFT_VER_PART.rpm

curl -kO https://download-node-02.eng.bos.redhat.com/brewroot/packages/kernel/4.18.0/$VER_PART/$(uname -m)/kernel-$(uname -r).rpm
curl -kO https://download-node-02.eng.bos.redhat.com/brewroot/packages/kernel/4.18.0/$VER_PART/$(uname -m)/kernel-core-$(uname -r).rpm
curl -kO http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/linux-firmware/20201118/101.git7455a360.el8/noarch/linux-firmware-20201118-101.git7455a360.el8.noarch.rpm
curl -kO http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/usbutils/010/3.el8/$(uname -m)/usbutils-010-3.el8.$(uname -m).rpm
curl -kO http://mirror.centos.org/centos/8/AppStream/$(uname -m)/os/Packages/rpm-build-4.14.3-4.el8.$(uname -m).rpm

curl -kO http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/elfutils/0.182/1.el8/$(uname -m)/elfutils-0.182-1.el8.$(uname -m).rpm
curl -kO http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/elfutils/0.182/1.el8/$(uname -m)/elfutils-libs-0.182-1.el8.$(uname -m).rpm
curl -kO http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/elfutils/0.182/1.el8/$(uname -m)/elfutils-libelf-0.182-1.el8.$(uname -m).rpm
curl -kO http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/elfutils/0.182/1.el8/$(uname -m)/elfutils-libelf-devel-0.182-1.el8.$(uname -m).rpm

dnf install -y \
kernel-$(uname -r).rpm \
kernel-core-$(uname -r).rpm \
kernel-modules-$(uname -r).rpm \
kernel-devel-$(uname -r).rpm \
gcc rpm-build make kmod pciutils kernel-devel-$(uname -r).rpm \
linux-firmware-20201118-101.git7455a360.el8.noarch.rpm \
rpm-build-4.14.3-4.el8.$(uname -m).rpm \
zstd-1.4.4-1.el8.$(uname -m).rpm \
usbutils-010-3.el8.$(uname -m).rpm \
elfutils-0.182-1.el8.$(uname -m).rpm \
elfutils-libs-0.182-1.el8.$(uname -m).rpm \
elfutils-libelf-0.182-1.el8.$(uname -m).rpm \
elfutils-libelf-devel-0.182-1.el8.$(uname -m).rpm

