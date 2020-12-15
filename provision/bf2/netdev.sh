wget -P /tmp --no-check-cert https://gitlab.cee.redhat.com/egarver/smart-nic-poc/-/raw/master/provision/bf2/bluefield-net-rules.tgz
cd /tmp
tar xf bluefield-net-rules.tgz
cd bluefield-net-rules
./install.sh
