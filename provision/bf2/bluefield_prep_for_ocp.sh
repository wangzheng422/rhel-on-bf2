#!/bin/sh
#
# This assumes 'bluefield_provision.sh' has already been run.

SUBNET="172.31.100"
ssh-keygen -t rsa -N "" -f bluefield

for I in $(seq 10 20); do
	ping -w 1 ${SUBNET}.${I} >/dev/null 2>&1 || continue

	ssh-copy-id -i bluefield root@${SUBNET}.${I}

	ssh root@${SUBNET}.${I} -i bluefield 'bash -s' < ./ovs_aarch_install.sh

	# FIXME: This should be a separate script as it's preparing the host.
	#
	# enable switchdev mode and create VFs
	bash ./add_connectx_eswitch_mode_config_service.sh
	BF2_PORT1=$(lshw -class network -businfo |grep "BlueField-2" |sort |head -n 1 |awk '{print $2}')
	bash ./vf_setup.sh ${BF2_PORT1} 5

	HOST_PFr=$(ssh root@${SUBNET}.${I} 'ip -d link |grep -B 1 "portname pf0 " |head -n 1 |awk "{print \$2}" |tr -d :')
	ssh root@${SUBNET}.${I} -i bluefield ovs-vsctl del-br hostpf0 || true
	ssh root@${SUBNET}.${I} -i bluefield ovs-vsctl add-br hostpf0
	ssh root@${SUBNET}.${I} -i bluefield ovs-vsctl add-port hostpf0 ${HOST_PFr}
	ssh root@${SUBNET}.${I} -i bluefield ovs-vsctl add-port hostpf0 p0

	ssh root@${SUBNET}.${I} -i bluefield 'echo "ip link set '${HOST_PFr}' up" >> /etc/rc.local'
	ssh root@${SUBNET}.${I} -i bluefield 'echo "ip link set p0 up" >> /etc/rc.local'

	# install libreswan on BF2
	ssh root@${SUBNET}.${I} -i bluefield dnf --nogpgcheck --assumeyes \
	                            --repofrompath "rhel84-baseos,http://download.eng.bos.redhat.com/nightly/rhel-8/RHEL-8/latest-RHEL-8.4/compose/BaseOS/aarch64/os/" \
	                            --repofrompath "rhel84-appstream,http://download.eng.bos.redhat.com/nightly/rhel-8/RHEL-8/latest-RHEL-8.4/compose/AppStream/aarch64/os/" \
	                            install libreswan

	# update BF2 kernel to 8.4 kernel for ipsec offload
	# ssh root@${SUBNET}.${I} dnf --nogpgcheck --assumeyes \
	#                             --repofrompath "rhel84-baseos,http://download.eng.bos.redhat.com/nightly/rhel-8/RHEL-8/latest-RHEL-8.4/compose/BaseOS/aarch64/os/" \
	#                             --repofrompath "rhel84-appstream,http://download.eng.bos.redhat.com/nightly/rhel-8/RHEL-8/latest-RHEL-8.4/compose/AppStream/aarch64/os/" \
	#                             upgrade kernel kernel-modules-extra

	BASE_URL=http://file.rdu.redhat.com/~bnemeth/9615/34969615/ \
	VER=4.18.0-287.el8.bz1926098.test2.dt1.aarch64
	ssh root@${SUBNET}.${I} dnf install -y $BASE_URL/kernel-$VER.rpm \
                               $BASE_URL/kernel-core-$VER.rpm \
							   $BASE_URL/kernel-devel-$VER.rpm \
							   $BASE_URL/kernel-modules-$VER.rpm \
							   $BASE_URL/kernel-modules-extra-$VER.rpm \
							   $BASE_URL/kernel-modules-internal-$VER.rpm
done

# must reboot cards due to new kernel
sh ./reboot_bf.sh
