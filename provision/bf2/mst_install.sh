#!/usr/bin/env bash

function install {
	if [ "$(uname -m)" = aarch64 ]; then
		MFT_VER=mft-4.15.1-9-arm64
	else
		MFT_VER=mft-4.15.1-9-x86_64
	fi
	yum install -y tar wget
	yum install -y kernel-devel-"$(uname -r)" &
	wget -P /tmp https://www.mellanox.com/downloads/MFT/$MFT_VER-rpm.tgz &>/dev/null &
	wait
	cd /tmp || exit 1
	tar xf $MFT_VER-rpm.tgz
	cd $MFT_VER-rpm || exit 1
	./install.sh
}
