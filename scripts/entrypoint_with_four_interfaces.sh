#!/usr/bin/env bash

QEMU_BRIDGE_ETH1='qemubr1'
QEMU_BRIDGE_ETH2='qemubr2'
QEMU_BRIDGE_ETH3='qemubr3'
QEMU_BRIDGE_ETH4='qemubr4'
default_dev1='eth0'
default_dev2='eth1'
default_dev3='eth2'
default_dev4='eth3'
# DHCPD must have an IP address to run, but that address doesn't have to
# be valid. This is the dummy address dhcpd is configured to use.
DUMMY_DHCPD_IP='10.0.0.1'

# These scripts configure/deconfigure the VM interface on the bridge.

QEMU_IFUP='/routeros/qemu-ifup'
QEMU_IFDOWN='/routeros/qemu-ifdown'
QEMU_IFUP2='/routeros/qemu-ifup2'
QEMU_IFDOWN2='/routeros/qemu-ifdown2'
QEMU_IFUP3='/routeros/qemu-ifup3'
QEMU_IFDOWN3='/routeros/qemu-ifdown3'
QEMU_IFUP4='/routeros/qemu-ifup4'
QEMU_IFDOWN4='/routeros/qemu-ifdown4'

# The name of the dhcpd config file we make
DHCPD_CONF_FILE='/routeros/dhcpd.conf'
# function default_intf() {
#     ip -json route show | jq -r '.[] | select(.dst == "default") | .dev'
# }

# First step, we run the things that need to happen before we start mucking
# with the interfaces. We start by generating the DHCPD config file based
# on our current address/routes. We "steal" the container's IP, and lease
# it to the VM once it starts up.
/routeros/generate-dhcpd-conf.py $QEMU_BRIDGE_ETH1 >$DHCPD_CONF_FILE

function prepare_intf() {
   #First we clear out the IP address and route
   ip addr flush dev $1
   # Next, we create our bridge, and add our container interface to it.
   ip link add $2 type bridge
   ip link set dev $1 master $2
   # Then, we toggle the interface and the bridge to make sure everything is up
   # and running.
   ip link set dev $1 up
   ip link set dev $2 up
}

prepare_intf $default_dev1 $QEMU_BRIDGE_ETH1
# Finally, start our DHCPD server
udhcpd -I $DUMMY_DHCPD_IP -f $DHCPD_CONF_FILE &
prepare_intf $default_dev2 $QEMU_BRIDGE_ETH2
prepare_intf $default_dev3 $QEMU_BRIDGE_ETH3
prepare_intf $default_dev4 $QEMU_BRIDGE_ETH4

# And run the VM! A brief explanation of the options here:
# -enable-kvm: Use KVM for this VM (much faster for our case).
# -nographic: disable SDL graphics.
# -serial mon:stdio: use "monitored stdio" as our serial output.
# -nic: Use a TAP interface with our custom up/down scripts.
# -drive: The VM image we're booting.
# mac: Set up your own interfaces mac addresses here, cause from winbox you can not change these later.
MAC_BASE=$(printf '54:05:AB:%02X:%02X:%X\n' $[RANDOM%256] $[RANDOM%256] $[RANDOM%16])
exec qemu-system-x86_64 \
   -nographic -serial mon:stdio \
   -vnc 0.0.0.0:0 \
   -m 512 \
   -smp 4,sockets=1,cores=4,threads=1 \
   -nic tap,id=qemu1,mac=${MAC_BASE}1,script=$QEMU_IFUP,downscript=$QEMU_IFDOWN \
   -nic tap,id=qemu2,mac=${MAC_BASE}2,script=$QEMU_IFUP2,downscript=$QEMU_IFDOWN2 \
   -nic tap,id=qemu3,mac=${MAC_BASE}3,script=$QEMU_IFUP3,downscript=$QEMU_IFDOWN3 \
   -nic tap,id=qemu4,mac=${MAC_BASE}4,script=$QEMU_IFUP4,downscript=$QEMU_IFDOWN4 \
   "$@" \
   -hda $ROUTEROS_IMAGE
