#!/bin/bash

set -e

echo "Adding script at: /usr/bin/connectx_eswitch_mode_config.sh"
cat > /usr/bin/connectx_eswitch_mode_config.sh <<EOF
#!/bin/bash

mode="switchdev"

for pdev in \$(/usr/sbin/lspci -d 15b3: -D | awk '{print \$1}')
do
	# ignore VFs and PCI bridge
	if /usr/sbin/lspci -s \${pdev} | grep -qiE "PCI bridge|Virtual" ; then
		continue
	fi

	if devlink dev | grep -q "\${pdev}" ; then
		msg=\$(devlink dev eswitch set pci/\${pdev} mode \${mode} 2>&1)
		if [ \$? -eq 0 ]; then
			echo "connectx_eswitch_mode_config: \${pdev}: eswitch mode set to '\${mode}'" > /dev/kmsg
		else
			echo "connectx_eswitch_mode_config: \${pdev}: \$msg" > /dev/kmsg
		fi
	else
		echo "connectx_eswitch_mode_config: \${pdev}: devlink dev not supported, skipping.'" > /dev/kmsg
	fi
done
EOF

chmod +x /usr/bin/connectx_eswitch_mode_config.sh

echo "Adding service conf file at: /etc/systemd/system/connectx_eswitch_mode_config.service"
cat > /etc/systemd/system/connectx_eswitch_mode_config.service <<EOF
[Unit]
Description=connectx_eswitch_mode_config: Set eswitch mode
After=systemd-udev-settle.service
Before=network.target network.service networking.service remote-fs-pre.target

[Service]
Type=oneshot
ExecStart=/usr/bin/connectx_eswitch_mode_config.sh

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling the service to run on boot..."
systemctl daemon-reload
systemctl enable connectx_eswitch_mode_config

echo "Done"
echo "Checking service status:"
systemctl status connectx_eswitch_mode_config --no-pager -l
