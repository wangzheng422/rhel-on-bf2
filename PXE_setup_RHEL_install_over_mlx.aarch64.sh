#!/bin/sh
# ex:ts=4:sw=4:sts=4:et
# ex:expandtab
#
# Copyright (c) 2020, Mellanox Technologies
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# some steps based on
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/performing_an_advanced_rhel_installation/index/#preparing-for-a-network-install_installing-rhel-as-an-experienced-user

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!! DO NOT USE THIS FILE !!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# there is another file for internal use only.

# Save the current directory.
CUR_DIR=$PWD

# TFTP config.
TFTP_CFG=/etc/xinetd.d/tftp

KS_FILE=
ENABLE_KS=0

SUBNET="192.168.100"
REPO_IP="${SUBNET}.1"
PROTOCOL="ETH"
NETDEV=TBD

usage()
{
    cat <<EOF
./setup.sh -i <rhel-iso> [options]

Options:
  -i <rhel-iso>    The .iso installation file
  -d <netdev>      MLX Netdev to use
  -p <protocol>    ETH, IB, tmfifo
  -k <ks-path>     Enable kickstart auto installation
EOF
}

svcctl_cmd()
{
    oper=$1
    svc=$2

    case ${oper} in
        restart)
            if [ "$NEW_VER" = "1" ]; then
                echo "systemctl restart ${svc}"
            else
                echo "service ${svc} restart"
            fi
            ;;
        enable)
            if [ "$NEW_VER" = "1" ]; then
                echo "systemctl enable ${svc}"
            else
                echo "chkconfig ${svc} on"
            fi
            ;;
    esac
}

svcctl()
{
    cmd=`svcctl_cmd $1 $2`
    eval "$cmd"
}

REAL_PATH=/usr/bin/realpath
if [ ! -f "$REAL_PATH" ]; then
    REAL_PATH="readlink -f"
fi

type systemctl >/dev/null 2>&1 && NEW_VER=1

setup_rshim()
{
    nmcli conn delete ${NETDEV}
    rm /etc/sysconfig/network-scripts/ifcfg-${NETDEV}
    nmcli conn add type tun mode tap con-name ${NETDEV} ifname ${NETDEV} autoconnect yes ip4 ${REPO_IP}/24
    nmcli conn modify tmfifo_net0 ipv4.routes ${SUBNET}.0/24
    systemctl restart NetworkManager
    nmcli conn up ${NETDEV}

    # Create rshim udev rules.
    if :; then
        echo "Creating rshim tmfifo_net0 udev rules..."
        cat >/etc/udev/rules.d/91-tmfifo_net.rules <<EOF
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:1a:ca:ff:ff:02", ATTR{type}=="1", NAME="${NETDEV} RUN+="/usr/bin/nmcli conn up ${NETDEV}"
EOF
    fi

    if ! rpm -qa | grep -q rshim ; then
        echo "Installing rshim user-space driver..."
        yum install -y elfutils-libelf-devel
        yum install -y make
        yum install -y git
        yum install -y autoconf
        yum install -y tmux
        yum install -y automake
        yum install -y pciutils-devel
        yum install -y libusb-devel
        yum install -y fuse-devel
        yum install -y kernel-modules-extra
        yum install -y gcc

        cd /tmp
        git clone https://github.com/Mellanox/rshim-user-space.git
        cd rshim-user-space/
        ./bootstrap.sh
        ./configure

        /bin/rm -rf /tmp/mybuildtest
        rpm_topdir=/tmp/mybuildtest
        mkdir -p $rpm_topdir/{RPMS,BUILD,SRPM,SPECS,SOURCES}
        version=$(grep "Version:" *.spec | head -1 | awk '{print $NF}')
        git archive --format=tgz --prefix=rshim-${version}/ HEAD > $rpm_topdir/SOURCES/rshim-${version}.tar.gz
        rpmbuild -ba --nodeps --define "_topdir $rpm_topdir" --define 'dist %{nil}' *.spec

        rpm -ivh $rpm_topdir/RPMS/*/*rpm

        systemctl enable rshim
        systemctl start rshim
        systemctl status rshim --no-pager -l
    fi
}


# Parse command line.
while getopts "d:i:k:p:b:" opt; do
    case $opt in
        d)
            NETDEV=$OPTARG
            ;;
        i)
            DISTRO_ISO=`$REAL_PATH $OPTARG`
            ;;
        k)
            ENABLE_KS=1
            KS_FILE=`$REAL_PATH $OPTARG`
            ;;
        p)
            PROTOCOL=$OPTARG
            ;;
        \?)
            usage >&2
            exit -1
            ;;
    esac
done

# Check root permission.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit -1
fi

# Mount the .iso file. Retry it 3 times.
if [ ! -e "$DISTRO_ISO" ]; then
    echo "Can't find rhel-iso"
    usage
    exit -1
fi

case "${PROTOCOL}" in
    ETH)
        ;;
    IB)
        echo
        echo " ########### MAKE SURE OpenSM is running on ${NETDEV} #############"
        echo
        ;;
    tmfifo)
        NETDEV="tmfifo_net0"
        setup_rshim
        ;;
    *)
        echo "Unsupported protocol: ${PROTOCOL}"
        exit 1
        ;;
esac

DISTRO_VER=$(basename ${DISTRO_ISO} | sed -e 's/-dvd1.iso//g')

# PXE mount path (temporary).
PXE_MOUNT=/var/ftp/${DISTRO_VER}

# Kickstart config path.
BF_KS_PATH=/var/ftp/ks_${DISTRO_VER}


# BASE_DISTRO_VER="$PXE_MOUNT-base"

# PXE mount path (temporary).
BASE_PXE_MOUNT="${PXE_MOUNT}-base"

echo "Mounting the .iso file to ${BASE_PXE_MOUNT}..."
echo "Mounting the .iso file to ${PXE_MOUNT}..."
umount ${BASE_PXE_MOUNT} 
# umount /run/media/root/EFI-SYSTEM
umount ${PXE_MOUNT} 

mkdir -p ${PXE_MOUNT} 2>/dev/null
for i in 1..3; do
    mount -t iso9660 -o loop ${DISTRO_ISO} ${PXE_MOUNT} 2>/dev/null
    [ -d ${PXE_MOUNT}/EFI ] && break
    sleep 1
done
if [ ! -d ${PXE_MOUNT}/EFI ]; then
    echo "Unable to mount ${DISTRO_ISO}."
    exit -1
fi

mkdir -p ${BASE_PXE_MOUNT} 2>/dev/null
# for i in 1..3; do
    mount -o loop ${PXE_MOUNT}/images/efiboot.img ${BASE_PXE_MOUNT} 2>/dev/null
    # [ -d ${BASE_PXE_MOUNT}/EFI ] && break
    # sleep 1
# done
# if [ ! -d ${BASE_PXE_MOUNT}/EFI ]; then
#     echo "Unable to mount ${DISTRO_ISO}."
#     exit -1
# fi



# Restart DHCP automatically (if dhcpd is running) when board reboots.
DHCPD_RESTART_CMD=`svcctl_cmd restart dhcpd`
IFUP_LOCAL=/sbin/ifup-local
if [ ! -e "${IFUP_LOCAL}" -o -z "$(grep ${NETDEV} ${IFUP_LOCAL} 2>/dev/null)" ]; then
    cat >>${IFUP_LOCAL} <<EOF
INTF=\$1

if [[ "\$INTF" = "${NETDEV}"* ]]; then
  killall -0 dhcpd 2>/dev/null
  if [ \$? -eq 0 ]; then
    $DHCPD_RESTART_CMD
  fi
fi
EOF
    chmod +x ${IFUP_LOCAL}
fi

# Patch existing IFUP_LOCAL file if it doesn't have the dhcpd running check.
tmp="killall -0 dhcpd 2>\/dev\/null\n  if \[ \$? -eq 0 \]; then\n    ${DHCPD_RESTART_CMD}\n  fi"
if [ -z "$(grep "killall -0 dhcpd" ${IFUP_LOCAL})" ]; then
    sed -i -E "s/${DHCPD_RESTART_CMD}/${tmp}/" ${IFUP_LOCAL}
fi

#
# Setup TFTP.
# TFTP server provides the initial images (kernel & initrd) for pxeboot.
#
echo "Setup tftp service..."
yum -y install httpd vsftpd tftp-server dhcp-server

sed -i \
    -e 's/anonymous_enable=NO/anonymous_enable=YES/' \
    -e 's/write_enable=YES/write_enable=NO/' \
    /etc/vsftpd/vsftpd.conf
echo "pasv_min_port=10021" >> /etc/vsftpd/vsftpd.conf
echo "pasv_max_port=10031" >> /etc/vsftpd/vsftpd.conf


TFTP_PATH=/var/lib/tftpboot
if [ -z "$TFTP_PATH" ]; then
    echo "tftp path not found"
    exit -1
fi

# Copy over the tftp files.
echo "Generate TFTP images..."
/bin/rm -rf ${TFTP_PATH}/*
# mkdir -p ${TFTP_PATH}/pxelinux/pxelinux.cfg
# mkdir -p ${TFTP_PATH}/pxelinux/images/${DISTRO_VER}
mkdir -p ${TFTP_PATH}/{images,isolinux}
/bin/cp -fv ${BASE_PXE_MOUNT}/EFI/BOOT/BOOTAA64.EFI ${TFTP_PATH}/
/bin/cp -fv ${BASE_PXE_MOUNT}/EFI/BOOT/grubaa64.efi ${TFTP_PATH}/
/bin/cp -fv ${BASE_PXE_MOUNT}/EFI/BOOT/mmaa64.efi ${TFTP_PATH}/
/bin/cp -fv ${PXE_MOUNT}/isolinux/isolinux.cfg ${TFTP_PATH}/isolinux.cfg
/bin/cp -fv ${PXE_MOUNT}/images/pxeboot/vmlinuz ${TFTP_PATH}/
/bin/cp -fv ${PXE_MOUNT}/images/pxeboot/initrd.img ${TFTP_PATH}/
/bin/cp -fv ${PXE_MOUNT}/images/assisted_installer_custom.img ${TFTP_PATH}/
/bin/cp -fv ${PXE_MOUNT}/images/ignition.img ${TFTP_PATH}/

# get pxelinux.0
case "${DISTRO_ISO}" in
    *x86_64*)
        rm -rf /tmp/pxetmp
        mkdir /tmp/pxetmp
        cd /tmp/pxetmp
        syslinux_rpm=$(find ${PXE_MOUNT} | grep syslinux-tftpboot-[0-9] | head -1)
        if [ ! -e "${syslinux_rpm}" ] ; then
            echo "cannot find syslinux RPM in the installation ISO media!"
            exit 1
        fi
        rpm2cpio ${syslinux_rpm} | cpio -id
        /bin/cp -fv /tmp/pxetmp/tftpboot/* ${TFTP_PATH}/pxelinux/
        cd -
        rm -rf /tmp/pxetmp
        ;;
esac

# Generate the grub.cfg.
echo "Generate the grub.cfg..."
grub_opts=" console=tty0 console=ttyS0,115200 console=ttyAMA1 console=hvc0 console=ttyAMA0 earlycon=pl011,0x01000000 "
if [ ${ENABLE_KS} -eq 1 ]; then
    grub_opts="${grub_opts} inst.ks=http://${REPO_IP}/ks_${DISTRO_VER}/kickstart.ks"
fi
case "${PROTOCOL}" in
    ETH)
        grub_opts="${grub_opts} ip=dhcp"
        ;;
    IB)
        grub_opts="${grub_opts} bootdev=${NETDEV} ksdevice=${NETDEV} net.ifnames=0 biosdevname=0 rd.neednet=1 rd.boofif=0 rd.driver.pre=mlx5_ib,mlx4_ib,ib_ipoib ip=${NETDEV}:dhcp rd.net.dhcp.retry=10 rd.net.timeout.iflink=60 rd.net.timeout.ifup=80 rd.net.timeout.carrier=80"
        ;;
    tmfifo)
        grub_opts="${grub_opts} rd.driver.pre=mlx5_core  ip=192.168.77.55::192.168.77.9:255.255.255.0:bf2-dpu:enp3s0f1:none  nameserver=192.168.77.11  rd.neednet=1 "
        ;;
esac

case "${DISTRO_ISO}" in
    *x86_64*)
        cat > ${TFTP_PATH}/pxelinux/boot.msg <<EOF

!!!!!!!!!!!! PXE INSTALL TEST !!!!!!!!!!!!!!!

Select one:

  1 - Install Red Hat Enterprise Linux
  2 - Start installer but Break to shell
  3 - Reboot

EOF

    cat > ${TFTP_PATH}/pxelinux/pxelinux.cfg/default <<EOF
default vesamenu.c32
prompt 1
timeout 600

display boot.msg

label 1
  menu label ^Install ${DISTRO_VER}
  menu default
  kernel images/${DISTRO_VER}/vmlinuz
  append initrd=images/${DISTRO_VER}/initrd.img showopts ${grub_opts}

label 2
  menu label ^Start installer ${DISTRO_VER} but break to shell
  kernel images/${DISTRO_VER}/vmlinuz
  append initrd=images/${DISTRO_VER}/initrd.img showopts ${grub_opts} rd.break=initqueue rd.shell

label 3
  menu label Boot from ^Reboot
  reboot

EOF
    ;;
    *aarch64*)
    cat > ${TFTP_PATH}/grub.cfg <<EOF

function load_video {
  insmod efi_gop
  insmod efi_uga
  insmod video_bochs
  insmod video_cirrus
  insmod all_video
}

load_video
set gfxpayload=keep
insmod gzio
insmod part_gpt
insmod ext2

# ${DISTRO_ISO} ${REPO_IP}
menuentry 'Install coreos' --class red --class gnu-linux --class gnu --class os {
    linux vmlinuz ignition.firstboot ignition.platform.id=metal 'coreos.live.rootfs_url=http://192.168.77.11:8080/ocp-bf2-aarch64-rootfs.img' coreos.inst.insecure  ${grub_opts}
    initrd initrd.img ignition.img 
}

menuentry 'Start installer ${DISTRO_VER} but break to shell' --class red --class gnu-linux --class gnu --class os {
    linux images/${DISTRO_VER}/vmlinuz ${grub_opts}
    initrd images/${DISTRO_VER}/initrd.img showopts ${grub_opts} rd.break=initqueue rd.shell
}

menuentry 'Reboot' --class red --class gnu-linux --class gnu --class os {
    reboot
}
EOF
    ;;
    *)
        echo "-E- MISSING BOOT SETTINGS!!!"
    ;;
esac

#fi

#
# Setup DHCP.
# DHCP-SERVER assigns IP address to the target, and specify the boot image.
#
echo "Setup dhcp service..."
if [ -e "/etc/dhcp/dhcpd.conf" ]; then
    cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.save
fi

NAME_SERVERS=`cat /etc/resolv.conf | grep -e "^[[:blank:]]*nameserver" | awk '{print $2}'`
NAME_SERVERS=`echo ${NAME_SERVERS} | sed 's/ /, /g'`
DOMAIN_NAMES=`cat /etc/resolv.conf | grep search | awk '{$1= ""; print $0}'`
DOMAIN_NAMES=`echo $DOMAIN_NAMES | sed 's/ /", "/g; s/$/"/; s/^/"/'`
NAME_SERVERS_STR=${NAME_SERVERS:+option domain-name-servers ${NAME_SERVERS};}
DOMAIN_NAMES_STR=${DOMAIN_NAMES:+option domain-search ${DOMAIN_NAMES};}

case "${DISTRO_ISO}" in
    *x86_64*)
    filesettings='
        if option architecture-type = 00:07 {
            filename "BOOTX64.efi";
        } else {
            filename "pxelinux/pxelinux.0";
        }
    '
    ;;
    *aarch64*)
    filesettings='filename "/BOOTAA64.EFI";'
    ;;
    *)
        echo "-E- MISSING BOOT SETTINGS!!!"
    ;;
esac

cat >/etc/dhcp/dhcpd.conf <<EOF
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;
allow booting;
allow bootp;


next-server ${REPO_IP};
always-broadcast on;

${filesettings}

subnet ${SUBNET}.0 netmask 255.255.255.0 {
    range ${SUBNET}.10 ${SUBNET}.20;
    option broadcast-address ${SUBNET}.255;
    option routers ${REPO_IP};
    ${NAME_SERVERS_STR}
    ${DOMAIN_NAMES_STR}

}

EOF
    # option dhcp-client-identifier = option dhcp-client-identifier;

#
# Setup HTTP.
# The installer will fetch packages from the http server.
#
echo "Setup http service..."

if [ $ENABLE_KS -eq 1 ]; then
    mkdir -p ${BF_KS_PATH} 2>/dev/null
    /bin/cp -fv ${KS_FILE} ${BF_KS_PATH}/kickstart.ks
    sed -i "s@REPO_URL@http://${REPO_IP}/${DISTRO_VER}@" ${BF_KS_PATH}/kickstart.ks
fi

if [ "$NEW_VER" = "1" ]; then
    HTTP_PERMISSION="Require ip 127.0.0.1 ${SUBNET}.0/24"
else
    HTTP_PERMISSION="Allow from 127.0.0.1 ${SUBNET}.0/24"
fi

cat >/etc/httpd/conf.d/pxeboot_${DISTRO_VER}.conf <<EOF
Alias /${DISTRO_VER} ${PXE_MOUNT}
<Directory ${PXE_MOUNT}>
    Options Indexes FollowSymLinks
    $HTTP_PERMISSION
</Directory>

Alias /ks_${DISTRO_VER} ${BF_KS_PATH}
<Directory ${BF_KS_PATH}>
    Options Indexes FollowSymLinks
    $HTTP_PERMISSION
</Directory>
EOF

#
# Check selinux status. If enabled, it might block HTTP access which
# could affect CentOS installation.
#
sestate=`sestatus 2>/dev/null | head -1 | awk '{print $3}'`
[ "$sestate" = "enabled" ] && {
    cat << EOF
  Warning: selinux seems enabled which might affect CentOS installation.
           Suggest disabling it temporarily with command 'setenforce 0'
           if you're not sure.
EOF
}

chmod -R +r ${TFTP_PATH}/

systemctl enable vsftpd
systemctl restart vsftpd.service

systemctl enable dhcpd
systemctl restart dhcpd

systemctl enable tftp.socket
systemctl restart tftp.socket

systemctl enable httpd
systemctl restart httpd

echo -e "\nDone."
echo "Next step: PXE boot from target (make sure to select the correct port!)"

# umount ${BASE_PXE_MOUNT}
# umount ${PXE_MOUNT} 

