#!/bin/bash

SOURCE=${@: -1}
if [[ $SOURCE == "-iVSPTPSOTO" ]]
then
    fpc $*
    exit $?
fi

SOURCE=$(basename $SOURCE)
SOURCE=${SOURCE%.*}.s
INSERTCOVERAGE=n
for i in logging.s serial.s threads.s
do
    if [[ $SOURCE == $i ]]
    then
        INSERTCOVERAGE=y
    fi
done

if [[ $INSERTCOVERAGE == "y" ]]
then
    CMD="fpc -s -al $*"
    echo $SOURCE $CMD
    eval $CMD
    sed -i '/ldmea.r11,{.*r11,r13,r15}/i svc #0x0' /root/ultibo/core/fpc/source/rtl/units/arm-ultibo/$SOURCE
    ./ppas.sh
else
    CMD="fpc $*"
    echo $SOURCE $CMD
    eval $CMD
fi
echo
