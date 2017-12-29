BEGIN                {getline counter < "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragesubroutinecounter.txt"}
/\.globl\t/          {subroutine=$0}
/ldmfd.r13!,{.*r15}/ {print "        svc     #", counter++, "//", subroutine
                      print " AddSubroutine('", subroutine, "');" >> "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragemap.pas"}
                     {print}
END                  {print counter > "/root/ultibo/core/fpc/source/rtl/ultibo/core/coveragesubroutinecounter.txt"}
