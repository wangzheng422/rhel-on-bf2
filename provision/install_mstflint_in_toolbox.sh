#!/bin/env bash

# Assuming this script is run from a container based on
# registry.redhat.io/rhel8/support-tools like the toolbox container in openshift

dnf install -y git libtool zlib-devel openssl-devel make gcc-c++
git clone https://github.com/Mellanox/mstflint.git
cd mstflint
git checkout v4.15.0-1
./autogen.sh
./configure --disable-inband --disable-dependency-tracking
make
make install