#/bin/bash

set -e

export PATH=/root/ultibo/core/fpc/bin:$PATH
fpc -B -O2 -Tultibo -Parm -CpARMV7a -WpQEMUVPB @/root/ultibo/core/fpc/bin/QEMUVPB.CFG coveragetester.lpr

qemu-system-arm -M versatilepb -display none -cpu cortex-a8 -m 256M -kernel kernel.bin -serial stdio -usb
