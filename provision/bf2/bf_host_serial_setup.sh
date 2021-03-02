#!/bin/bash

# Usage:
# To execute on remote host:
# 	ssh root@hostname 'bash -s' < bf_host_serial_setup.sh
# Local host:
# 	./bf_host_serial_setup.sh
#

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum update
yum install -y ser2net

mv /etc/ser2net.conf /etc/ser2net.conf.ORIG
cat << EOF | tee /etc/ser2net.conf
BANNER:banner:NVIDIA Bluefield-2 DPU Serial Console (ser2net TCP port \p)\r\n
DEFAULT:speed:115200
DEFAULT:databits:8
DEFAULT:parity:none
DEFAULT:stopbits:1
DEFAULT:xonxoff:false
DEFAULT:rtscts:false
9999:telnet:0:/dev/ttyUSB0:banner
EOF

cat << EOF | tee /etc/systemd/system/ser2net.service
[Unit]
Description=ser2net service
After=network.target

[Service]
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=ser2net -d -p 9998
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now ser2net.service
systemctl status ser2net.service --no-pager -l
