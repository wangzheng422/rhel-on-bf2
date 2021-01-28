#!/bin/bash

function info {
	printf "=== INFO === %s\n" "$@"
}

function status {
	printf "=== STATUS === %s\n" "$@"
}

function die {
	printf "!!! FAILED !!! %s\n" "$@"
	exit 1
}

function mst_install {
	status "Installing MST tools"
	dnf install -y http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/mstflint/4.15.0/1.el8/x86_64/mstflint-4.15.0-1.el8.x86_64.rpm
	mst start
}

function rshim_install {
	status "Installing rshim driver and tools"
	if [ "$(cut -d' ' -f 6 < /etc/redhat-release)" = 8.2 ]; then
		dnf install -y http://download.eng.bos.redhat.com/composes/nightly-rhel-8/RHEL-8/latest-RHEL-8/compose/CRB/x86_64/os/Packages/libusb-devel-0.1.5-12.el8.x86_64.rpm
	fi

	yum install -y automake autoconf elfutils-libelf-devel fuse-devel gcc git kernel-modules-extra libusb-devel make minicom pciutils-devel rpm-build tmux
	echo "pu rtscts           No" > /root/.minirc.dfl
	pushd /tmp
	git clone https://github.com/Mellanox/rshim-user-space.git
	cd rshim-user-space || die "cd rshim-user-space"
	./bootstrap.sh
	./configure


	rpm_topdir=/tmp/rshim_provision_build
	/bin/rm -rf "$(rpm_topdir)"
	mkdir -p $rpm_topdir/{RPMS,BUILD,SRPM,SPECS,SOURCES}
	version=$(grep "Version:" *.spec | head -1 | awk '{print $NF}')
	git archive --format=tgz --prefix=rshim-"${version}"/ HEAD > $rpm_topdir/SOURCES/rshim-"${version}".tar.gz
	rpmbuild -ba --nodeps --define "_topdir $rpm_topdir" --define 'dist %{nil}' *.spec

	rpm -ivh $rpm_topdir/RPMS/*/*rpm
	systemctl enable --now rshim
	systemctl status rshim

	popd
}

function firmware_update {
	status "Performing firmware update"

	if ! rpm -qa | grep -q rshim; then
		rshim_install
	fi
	dnf -y install expect

	wget -c http://www.mellanox.com/downloads/BlueField/BlueField-3.1.0.11424/BlueField-3.1.0.11424_install.bfb
	status "Sending firmware to BF2. Please wait."
	cat BlueField-3.1.0.11424_install.bfb > /dev/rshim0/boot
	expect -c '
		spawn minicom --baudrate 115200 --device /dev/rshim0/console
		expect {
			"login:" { send "root\r"; exp_continue }
			"# " { send "/opt/mellanox/scripts/bfrec\r" }
			timeout { send "\r"; exp_continue }
		}
		expect {
			"# " { send "/lib/firmware/mellanox/mlxfwmanager_sriov_dis_aarch64_41686\r" }
			timeout exp_continue
		}
		expect {
			"Perform FW update?" { send "y\r"; exp_continue }
			"# " { exit }
			timeout exp_continue
		}
	'
}

function pxe_install() {
	status "Setting up PXE environment"

	# deduced the interface we use to access the internet via the default route
	local uplink_interface="$(ip route |grep ^default | sed 's/.*dev \([^ ]\+\).*/\1/')"
	test -n "${uplink_interface}" || die "need a default route"

	RHEL_ISO="http://download.eng.bos.redhat.com/released/RHEL-8/8.3.0/BaseOS/aarch64/iso/RHEL-8.3.0-20201009.2-aarch64-dvd1.iso"
	wget -O "/tmp/${RHEL_ISO##*/}" -c http://download.eng.bos.redhat.com/released/RHEL-8/8.3.0/BaseOS/aarch64/iso/RHEL-8.3.0-20201009.2-aarch64-dvd1.iso
	iptables -F
	bash ./PXE_setup_RHEL_install_over_mlx.sh -i "/tmp/${RHEL_ISO##*/}" -p tmfifo -k RHEL8-bluefield.ks

	info "The BF2 is about to be rebooted and minicom console"
	info "started. You must manually select the PXE boot device."
	info "This can't be fully automated because the list of"
	info "options is not consistent."
	info ""
	info "ACTION: When you see the \"Boot Option Menu\" select option"
	info "\"EFI NETWORK 4\" and press enter. After that the automation"
	info "picks up again. Let it take over. The console and reboot are"
	info "slow. Have patience."
	info ""
	info "Press enter when you're ready."
	read

	status "PXE booting the BF2 and starting minicom"
	echo BOOT_MODE 1 > /dev/rshim0/misc
	echo SW_RESET 1 > /dev/rshim0/misc

	sleep 10
	nmcli conn up tmfifo_net0
	systemctl restart dhcpd

	expect -c '
		spawn minicom --color on --baudrate 115200 --device /dev/rshim0/console
		# Spam "ESC" until we see "Boot Manager"
		#
		set timeout 1
		expect {
			"Boot Manager" { send "OBOB"; send "\r"; }
			timeout { send ""; exp_continue }
		}
		set timeout 600
		interact {
			\015 { send "\r"; return; }
			* { exp_continue }
		}
		expect {
			"Install" { send "\r"; }
		}
	'
	reset # reset console, trashed after expect/minicom

	iptables -t nat -A POSTROUTING -o ${uplink_interface} -j MASQUERADE

	info "The RHEL install has been started. This is the end of the automation."
	info "I will reattach the minicom console to see the install progress."
	info "You can drop it anytime with key sequence: ctrl-a X"
	info ""
	info "Press enter when you're ready."
	read

	minicom --color on --baudrate 115200 --device /dev/rshim0/console
}


function sriov_check {
	status "Checking usability of SRIOV"

	mst start
	MST_LIST=($(mst status | grep -Po "/dev/mst/[\w\d]+"))

	for MST in ${MST_LIST[@]}; do
		if mlxconfig -d "$MST" q | grep SRIOV_EN | grep -q "True\|1"; then
			echo "SRIOV enabled"
		else
			echo "SRIOV needs to be enabled in BIOS"
		fi

		if mlxconfig -e -d "$MST"  q | grep -i internal |  cut -d' ' -f28 | grep -q EMBEDDED_CPU\(1\); then
			echo "EMBEDDED_CPU mode enabled"
		else
			echo "SEPARATED_HOST mode enabled, cannot proceed with VF setup"
			if mlxconfig -e -d "$MST" q | grep -i internal | cut -d' ' -f29 | grep -q EMBEDDED_CPU\(1\); then
				echo "EMBEDDED_CPU mode is set to be enabled on next boot. Power cycle the system to enable it."
			else
				echo "Enabling EMBEDDED_CPU mode"
				mlxconfig -d "$MST" s INTERNAL_CPU_MODEL=1
				mlxconfig -d "$MST".1 s INTERNAL_CPU_MODEL=1
				echo "EMBEDDED_CPU mode will be enabled on next boot. Power cycle the system to enable it."
			fi
			bash ./reboot_bf.sh || exit 1
		fi

	done
}

function help {
	cat << EOF
./bluefield_provision.sh [options]

Options:
  -r	Install rshim drivers
  -m	Install MST
  -f	Update BF2 firmware
  -s    Enable ECPF mode if not already enabled
  -p	Set up PXE boot server for provisioning BF2
  -a	Run all provisioning scripts
EOF

}

while getopts "armfsp" opt; do
    case $opt in
        a)
	    rshim_install
	    mst_install
	    firmware_update
	    sriov_check
	    pxe_install
            ;;

        c)
	    mst_check
            ;;
        r)
	    rshim_install
            ;;
        m)
	    mst_install
            ;;
        f)
	    firmware_update
            ;;
        s)
	    sriov_check
            ;;
        p)
	    pxe_install
            ;;
        \?)
	    help
            exit 0
            ;;
    esac
done
