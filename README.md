Discussion at https://ultibo.org/forum/viewtopic.php?f=9&t=941

prepare-debian9-linode.sh - installs dependencies needed for Ultibo on debian9/linode

ultiboinstaller-with-coverage.sh - installs Ultibo with svc calls at routine exit points by using fpc-with-coverage.sh

fpc-with-coverage.sh - compiles a pascal file with svc calls at routine exit points for logging, threads, and serial units

insert-svc.awk - actually inserts the svc calls in an assembler file

coveragetester.lpr - test program displays sorted counters periodically

coveragemap.pas - interface to the coverage data

run-coveragetester.sh - compiles and runs test program with logging output send to stdout
