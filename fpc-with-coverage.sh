#!/bin/bash

SOURCE=${@: -1}
if [[ $SOURCE == "-iVSPTPSOTO" ]]
then
    fpc $*
    exit $?
fi

SOURCE=$(basename $SOURCE)
SOURCE=${SOURCE%.*}.s

#for i in arp console consoleshell devices dhcp dma dns ehci font framebuffer globalconfig globalconst globaltypes http icmp ip iphlapi ipv6 logging mmc mmcspi network pl011 pl031 pl050 pl110 platform platformarm platformarmv7 platformqemuvpb protocol qemuversatilepb rtc serial services shellfilesystem shellupdate smc91x sockets spi storage tcp threads transport udp ultibo usb webstatus winsock winsock2 versatilepb xhci

INSERTCOVERAGE=1
for i in system
do
    if [[ ${SOURCE,,*} == ${i}.s ]]
    then
        INSERTCOVERAGE=0
    fi
done
if [[ ${SOURCE:0:4} == "boot" ]]
then
    INSERTCOVERAGE=0
fi

CORE=$HOME/ultibo/core/fpc/source/rtl/ultibo/core
COVERAGEMAP=$CORE/coveragemap.inc
DATA=$HOME/ultibo/core/fpc/source/rtl/units/arm-ultibo/$SOURCE

if [[ $INSERTCOVERAGE == "1" ]]
then
    CMD="fpc -s -al $*"
    echo $SOURCE $CMD
    eval $CMD
    cp -a $DATA $DATA.in
    awk -f $HOME/github.com/markfirmware/ultibo-coverage/insert-svc.awk $DATA.in > $DATA
    ./ppas.sh
else
    CMD="fpc $*"
    echo $SOURCE $CMD
    eval $CMD
fi
echo
