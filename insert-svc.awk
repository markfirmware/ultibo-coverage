BEGIN                {getline counter < "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragesubroutinecounter.txt"
                      enabled=1
                      platformarmv7=0}
/\.file "platformarmv7.pas"/ {platformarmv7=1}
/\.globl\t/          {subroutine=$2
                      bxr14enabled=0}
platformarmv7 && /\.globl\t.*ARMV7CONTEXTSWITCH/ {bxr14enabled=1}
enabled && /ldmfd\tr13!,{.*r15}/        {print "        svc     #", counter++, "//", subroutine
                                         print " AddSubroutine('", subroutine, "');" >> "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragemap.inc"}
enabled && /ldmea\tr11,{.*r11,r13,r15}/ {print "        svc     #", counter++, "//", subroutine
                                         print " AddSubroutine('", subroutine, "');" >> "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragemap.inc"}
bxr14enabled && /bx\tr14/               {print "        svc     #", counter++, "// bx r14", subroutine
                                         print " AddSubroutine('", subroutine, "');" >> "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragemap.inc"}
                     {print}
END                  {print counter > "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragesubroutinecounter.txt"}
