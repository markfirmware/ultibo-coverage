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

for i in arp devices dhcp dns icmp ip iphlapi ipv6 logging network protocol serial services sockets tcp threads transport udp winsock winsock2
do
    if [[ $SOURCE == ${i}.s ]]
    then
        INSERTCOVERAGE=1
        FILENAME=$i
    fi
done

CORE=$HOME/ultibo/core/fpc/source/rtl/ultibo/core
COVERAGEMAP=$CORE/coveragemap.pas
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
