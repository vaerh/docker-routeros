#!/usr/bin/env bash

# These entrypoint is for maximum 16 interfaces using Docker virtual networks.
# The number of interfaces is specified via the `IF` environment variable.
# --env IF=7

if [ -z "$IF" ] || ! [[ "$IF" =~ ^[0-9]+$ ]]; then
   IF=4
elif [ "$IF" -le 0 ] || [ "$IF" -ge 17 ]; then
   IF=4
fi

function prepare_intf() {
   ip addr flush dev $1
   ip link add $2 type bridge
   ip link set dev $1 master $2
   ip link set dev $1 up
   ip link set dev $2 up
}

prepare_intf "eth0" "qemubr1"

DHCPD_CONF_FILE="/routeros/dhcpd.conf"
/routeros/generate-dhcpd-conf.py "qemubr1" > $DHCPD_CONF_FILE
# Start our DHCPD server
udhcpd -I "10.0.0.1" -f $DHCPD_CONF_FILE &

QEMU_NICS=""

for i in $(seq 2 $IF); do 
   prepare_intf eth$i qemubr$i

   MAC=$(printf "%x" $((0x30+$i)))
   QEMU_NICS="$QEMU_NICS -nic tap,id=qemu$i,mac=54:05:AB:CD:12:$MAC,script=/routeros/qemu-ifup$i,downscript=/routeros/qemu-ifdown$i"
cat > /routeros/qemu-ifup$i <<EOF
#!/usr/bin/env bash

ip link set dev \$1 up
ip link set dev \$1 master "qemubr$i"
EOF

cat > /routeros/qemu-ifdown$i <<EOF
#!/usr/bin/env bash

ip link set dev \$1 nomaster
ip link set dev \$1 down
EOF
done

# And run the VM! A brief explanation of the options here:
# -enable-kvm: Use KVM for this VM (much faster for our case).
# -nographic: disable SDL graphics.
# -serial mon:stdio: use "monitored stdio" as our serial output.
# -nic: Use a TAP interface with our custom up/down scripts.
# -drive: The VM image we're booting.
# mac: Set up your own interfaces mac addresses here, cause from winbox you can not change these later.
exec qemu-system-x86_64 \
   -nographic -serial mon:stdio \
   -vnc 0.0.0.0:0 \
   -m 512 \
   -smp 4,sockets=1,cores=4,threads=1 \
   -nic tap,id=qemu1,mac=54:05:AB:CD:12:31,script=/routeros/qemu-ifup,downscript=/routeros/qemu-ifdown \
   $QEMU_NICS "$@" -hda $ROUTEROS_IMAGE
