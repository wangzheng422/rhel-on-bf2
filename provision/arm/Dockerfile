
# This is the OpenShift ovn overlay network image.
# it provides an overlay network using ovs/ovn/ovn-kube
#
# The standard name for this image is ovn-kube

# Notes:
# This is for a build where the ovn-kubernetes utilities
# are built in this Dockerfile and included in the image (instead of the rpm)
#

FROM registry.access.redhat.com/ubi8/ubi AS builder
RUN dnf install -y make go git

# WORKDIR /go/src/github.com/openshift/ovn-kubernetes
# COPY . .


# build the binaries
# RUN cd go-controller; CGO_ENABLED=0 make
# RUN cd go-controller; CGO_ENABLED=0 make windows

#FROM registry.svc.ci.openshift.org/ocp/4.7:cli AS cli

#FROM registry.svc.ci.openshift.org/ocp/4.7:base

USER root

ENV PYTHONDONTWRITEBYTECODE yes

RUN yum install -y  \
	selinux-policy && \
	yum clean all

RUN dnf install -y \
openssl \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-9/packages/firewalld/0.9.1/1.el9/noarch/firewalld-filesystem-0.9.1-1.el9.noarch.rpm \
libpcap \
iproute \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/strace/5.7/2.el8/aarch64/strace-5.7-2.el8.aarch64.rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-9/packages/tcpdump/4.9.3/4.el9/aarch64/tcpdump-4.9.3-4.el9.aarch64.rpm \
iputils \
procps-ng \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/67.el8fdp/aarch64/openvswitch2.13-2.13.0-67.el8fdp.aarch64.rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/67.el8fdp/aarch64/openvswitch2.13-devel-2.13.0-67.el8fdp.aarch64.rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/67.el8fdp/aarch64/python3-openvswitch2.13-2.13.0-67.el8fdp.aarch64.rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch-selinux-extra-policy/1.0/23.el8fdp/noarch/openvswitch-selinux-extra-policy-1.0-23.el8fdp.noarch.rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/ovn2.13/20.09.0/12.el8fdp/aarch64/ovn2.13-20.09.0-12.el8fdp.aarch64.rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/ovn2.13/20.09.0/12.el8fdp/aarch64/ovn2.13-central-20.09.0-12.el8fdp.aarch64.rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/ovn2.13/20.09.0/12.el8fdp/aarch64/ovn2.13-host-20.09.0-12.el8fdp.aarch64.rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/ovn2.13/20.09.0/12.el8fdp/aarch64/ovn2.13-vtep-20.09.0-12.el8fdp.aarch64.rpm

RUN mkdir -p /var/run/openvswitch && \
    mkdir -p /var/run/ovn && \
    mkdir -p /usr/libexec/cni/

# RUN cd go-controller; \
# make clean; \
# make; \
# cd _output/go/bin/; \
# cp ovnkube /usr/bin/; \
# cp ovn-kube-util /usr/bin/; \
# cp ovn-k8s-cni-overlay /usr/libexec/cni/; \
# cp hybrid-overlay-node.exe /root/windows/; \
# cp ovndbchecker /usr/bin/; \
# git clone https://github.com/openshift/oc.git; \
# cd oc; \
# make oc; \
# cp oc /usr/bin; \
# ln -s /usr/bin/oc /usr/bin/kubectl

# RUN stat /usr/bin/oc

# copy git commit number into image
# COPY .git/HEAD /root/.git/HEAD
# COPY .git/refs/heads/ /root/.git/refs/heads/

# ovnkube.sh is the entry point. This script examines environment
# variables to direct operation and configure ovn
COPY ovnkube.sh /root/
#COPY ovndb-raft-functions.sh /root/

LABEL io.k8s.display-name="ovn kubernetes" \
      io.k8s.description="This is a component of OpenShift Container Platform that provides an overlay network using ovn." \
      summary="This is a component of OpenShift Container Platform that provides an overlay network using ovn." \
      io.openshift.tags="openshift" \
      maintainer="Phil Cameron <pcameron@redhat.com>"

RUN stat /root/ovnkube.sh

WORKDIR /root
ENTRYPOINT ["/root/ovnkube.sh"]
