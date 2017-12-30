BEGIN                {getline counter < "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragesubroutinecounter.txt"}
/\.globl\t/          {subroutine=$2}
/ldmfd.r13!,{.*r15}/ {print "        svc     #", counter++, "//", subroutine
                      print " AddSubroutine('", subroutine, "');" >> "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragemap.inc"}
                     {print}
END                  {print counter > "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragesubroutinecounter.txt"}
