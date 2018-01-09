#/bin/bash

set -e

export PATH=/root/ultibo/core/fpc/bin:$PATH
fpc -al -s -B -O2 -Tultibo -Parm -CpARMV7a -WpQEMUVPB @/root/ultibo/core/fpc/bin/QEMUVPB.CFG -Fi$HOME/ultibo/core/fpc/source/rtl/ultibo/core coveragetester.lpr
./ppas.sh

qemu-system-arm -M versatilepb -display none -cpu cortex-a8 -m 256M -kernel kernel.bin -serial stdio -usb -net nic -net user,hostfwd=tcp::5080-:80 -append "NETWORK0_IP_CONFIG=STATIC NETWORK0_IP_ADDRESS=10.0.2.15 NETWORK0_IP_NETMASK=255.255.255.0 NETWORK0_IP_GATEWAY=10.0.2.2"
