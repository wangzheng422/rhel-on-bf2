wget --no-check-cert https://gitlab.cee.redhat.com/egarver/smart-nic-poc/-/raw/master/provision/bf2/bluefield-net-rules.tgz
tar xf bluefield-net-rules.tgz
cd bluefield-net-rules
./install.sh
echo "Reboot to finalize changes"
