#!/bin/bash


set -ex
# ./transport-offload.sh <1|2> <iface> [offload]


node=$1
dev=p0
offload=2

key1=0x$(echo key1 | md5sum | cut -d' ' -f1)beefbeef
key2=0x$(echo key2 | md5sum | cut -d' ' -f1)beefbeef


mask=24
n1=192.168.1.64
n2=192.168.1.65

spi_1=0x1001
spi_2=0x1002


reqid_out=0xb17c0ba5
reqid_in=0x0d2425dd


if [ $node = 1 ] ; then
    local=$n1
    remote=$n2


    spi_out=$spi_2
    spi_in=$spi_1


    key_out=$key2
    key_in=$key1
else
    local=$n2
    remote=$n1


    spi_out=$spi_1
    spi_in=$spi_2


    key_out=$key1
    key_in=$key2
fi

ip x s f
ip x p f


old_dev=$(ip -4 -o a | grep $local | cut -d' ' -f2)
if [ ${#old_dev} -ne 0 ] ; then
    # local ip is already present in the system
    if [ ${#dev} -ne 0 ] ; then
        if [ $dev != $old_dev ] ; then
            echo "moving $local from $old_dev to $dev"
            ip a d $local/$mask dev $old_dev
            ip a a $local/$mask dev $dev
        fi
    fi
else
    if [ ${#dev} -ne 0 ] ; then
        echo "installing $local on $dev"
        ip a a $local/$mask dev $dev
    else
        echo "ip $local isn't present and no device given"
    fi
fi


ip link set dev ${dev} up


ip x p a src ${local}  dst ${remote} dir out tmpl src ${local}  dst ${remote} proto esp reqid ${reqid_out} mode transport
ip x p a src ${remote} dst ${local}  dir in  tmpl src ${remote} dst ${local}  proto esp reqid ${reqid_in}  mode transport
ip x p a src ${remote} dst ${local}  dir fwd tmpl src ${remote} dst ${local}  proto esp reqid ${reqid_in}  mode transport


if [ ${#offload} -eq 0 ] ; then
    ip x s a src ${local}  dst ${remote} proto esp spi ${reqid_out} reqid ${reqid_out} mode transport aead 'rfc4106(gcm(aes))' $key_out 128 sel src ${local} dst ${remote}
    ip x s a src ${remote} dst ${local}  proto esp spi ${reqid_in}  reqid ${reqid_in}  mode transport aead 'rfc4106(gcm(aes))' $key_in 128  sel src ${remote} dst ${local}
else
    ip x s a src ${local}  dst ${remote} proto esp spi ${reqid_out} reqid ${reqid_out} mode transport aead 'rfc4106(gcm(aes))' $key_out 128 full_offload dev ${dev} dir out sel src ${local} dst ${remote}
    ip x s a src ${remote} dst ${local}  proto esp spi ${reqid_in}  reqid ${reqid_in}  mode transport aead 'rfc4106(gcm(aes))' $key_in 128  full_offload dev ${dev} dir in  sel src ${remote} dst ${local}
fi


ip x s
ip x p
