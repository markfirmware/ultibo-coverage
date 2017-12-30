#!/bin/bash

SOURCE=${@: -1}
if [[ $SOURCE == "-iVSPTPSOTO" ]]
then
    fpc $*
    exit $?
fi

SOURCE=$(basename $SOURCE)
SOURCE=${SOURCE%.*}.s
INSERTCOVERAGE=0

for i in arp console devices dhcp dns ehci globalconfig globalconst globaltypes http icmp ip iphlapi ipv6 logging mmc mmcspi network pl011 pl031 protocol qemuversatilepb rtc serial services sockets spi storage tcp threads transport udp ultibo usb webstatus winsock winsock2 versatilepb xhci
do
    if [[ $SOURCE == ${i}.s ]]
    then
        INSERTCOVERAGE=1
        FILENAME=$i
    fi
done

CORE=$HOME/ultibo/core/fpc/source/rtl/ultibo/core
COVERAGEMAP=$CORE/coveragemap.inc
DATA=$HOME/ultibo/core/fpc/source/rtl/units/arm-ultibo/$SOURCE

if [[ $INSERTCOVERAGE == "1" ]]
then
    CMD="fpc -s -al $*"
    echo $SOURCE $CMD
    eval $CMD
    echo " AddFileName('$FILENAME');" >> $COVERAGEMAP
    cp -a $DATA $DATA.in
    awk -f $HOME/github.com/markfirmware/ultibo-coverage/insert-svc.awk $DATA.in > $DATA
    ./ppas.sh
else
    CMD="fpc $*"
    echo $SOURCE $CMD
    eval $CMD
fi
echo
