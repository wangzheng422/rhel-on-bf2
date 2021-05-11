ovs-vsctl --if-exists del-br hostpf0
dnf install -y iproute-tc
dnf install -y NetworkManager-config-server
rm -f /var/run/NetworkManager/system-connections/*
systemctl restart NetworkManager

dnf install -y libmnl-devel
GIT_SSL_NO_VERIFY=true git clone https://github.com/huynguyen85/iproute2
cd iproute2
make -j20
make -j20 install

cp /usr/bin/connectx_eswitch_mode_config.sh{,.orig}
head -n -1 /usr/bin/connectx_eswitch_mode_config.sh > /tmp/a.sh
echo "devlink dev eswitch set pci/\${pdev} ipsec-mode full" >> /tmp/a.sh
tail -n 1 /usr/bin/connectx_eswitch_mode_config.sh >> /tmp/a.sh
mv /tmp/a.sh /usr/bin/connectx_eswitch_mode_config.sh

devlink dev eswitch set  pci/0000:03:00.0 mode legacy
devlink dev eswitch set  pci/0000:03:00.0 ipsec-mode full
devlink dev eswitch set  pci/0000:03:00.0 mode switchdev
devlink dev eswitch show pci/0000:03:00.0
