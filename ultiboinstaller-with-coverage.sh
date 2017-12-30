#!/bin/bash
# Linux install script for Ultibo editions of FreePascal and Lazarus
#
# Based on the setup.sh script from http://getlazarus.org

INSTALLER_DIR=$PWD

# The full version number of the stable compiler and the one we are building
FPC_STABLE=3.0.2
FPC_BUILD=3.1.1

# Prevent this script from running as root 
#if [ "$(id -u)" = "0" ]; then
#   echo "This script should not be run as root"
#   exit 1
#fi

# Present a description of this script
clear
echo "Linux installer for Free Pascal and Lazarus (Ultibo edition)"
echo "------------------------------------------------------------"
echo "This installation will download the sources for:"
echo "  Ultibo core"
echo "  Ultibo examples"
echo "  Free Pascal (Ultibo edition)"
echo "  Lazarus (Ultibo edition)"
echo
echo "Then it will build all of the above, this will take several"
echo "minutes to complete depending on the speed of your system."
echo
echo "The installation will not interfere with any existing"
echo "development environments including other installations"
echo "of Free Pascal and Lazarus."
echo

# Ask for permission to proceed
read -r -p "Continue (y/n)? " REPLY

case $REPLY in
    [yY][eE][sS]|[yY]) 
		echo
		;;
    *)
		# Exit the script if the user does not type "y" or "Y"
		echo 
		echo "Exiting, nothing installed."
		echo 
		exit 1
		;;
esac

clear
echo "Free Pascal and Lazarus (Ultibo edition) prerequisites"
echo "------------------------------------------------------"
echo "Installing and building Free Pascal requires several tools "
echo "from the build essentials package including make, ld and as"
echo "as well as the unzip utility." 
echo
echo "These can be installed on Debian based distributions using:"
echo
echo "sudo apt-get install build-essential unzip"
echo
echo "Lazarus requires the GTK2 and X11 dev packages which can"
echo "be installed on Debian based distributions by using:"
echo
echo "sudo apt-get install libgtk2.0-dev libcairo2-dev \\" 
echo "  libpango1.0-dev libgdk-pixbuf2.0-dev libatk1.0-dev \\"
echo "  libghc-x11-dev"
echo
echo "Cross compiling Ultibo applications from Linux requires the"
echo "arm-none-eabi build of the binutils package, this can be"
echo "installed on Debian based distributions using:"
echo
echo "sudo apt-get install binutils-arm-none-eabi"
echo
echo -n "Press return to check for these prerequisites"
read CHOICE
echo

# function require(program) 
function require() {
	if ! type "$1" > /dev/null; then
		echo 
		echo "An error occurred"
		echo 
		echo "This installation requires the package $1 but it was not found on your system"
		echo 
		echo "On Debian based distributions type the following to install it"
		echo 
		echo "sudo apt-get install $2"
		echo 
		echo "Then re-run the installation"
		echo 
		echo "For other distributions refer to the documentation for your"
        echo "package manager"
		echo 
		exit 1
	fi	
	echo "$1 found"
}

# Require the following programs 
require "make" "build-essential"
require "gdb" "gdb-minimal"
require "unzip" "unzip"

# function requirePackage(package) 
function requirePackage() {
	INSTALLED=$(dpkg-query -W --showformat='${Status}\n' $1 2> /dev/null | grep "install ok installed")
	if [ "$INSTALLED" = "" ]; then
		echo "$1 not found"
		echo 
		echo "An error occurred"
		echo 
		echo "This installation requires the package $1 but it was not found on your system"
		echo 
		echo "On Debian based distributions type the following to install it"
		echo 
		echo "sudo apt-get install $1"
		echo 
		echo "Then re-run the installation"
		echo 
		echo "For other distributions refer to the documentation for your"
        echo "package manager"
		echo 
		exit 1
	fi	
	echo "$1 found"
}

# Require the following packages 
if type "dpkg-query" > /dev/null; then
	requirePackage "libgtk2.0-dev"
	requirePackage "libcairo2-dev"
	requirePackage "libpango1.0-dev"
	requirePackage "libgdk-pixbuf2.0-dev"
	requirePackage "libatk1.0-dev"
	requirePackage "libghc-x11-dev"
fi

# Require the following programs 
require "arm-none-eabi-as" "binutils-arm-none-eabi"
require "arm-none-eabi-ld" "binutils-arm-none-eabi"
require "arm-none-eabi-objcopy" "binutils-arm-none-eabi"

sleep 2s

# function download(url, output)
function download() {
	if type "wget" > /dev/null; then
		wget --quiet -O "$1" "$2"
	elif type "curl" > /dev/null; then
		curl -s -L -o "$1" "$2"
	fi	
}

# Cross platform function expandPath(path)
function expandPath() {
	if [ `uname`="Darwin" ]; then
		[[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}";
	else
		echo $(readlink -m `$1`)
	fi
}

# Error exit function
function exitFailure() {
    if [ $? -ne 0 ]; then
        echo
        echo "Exiting, installation failed."
        echo
        exit 1
    fi 
}

# The default folder
BASE=$HOME/ultibo/core

clear
echo

# Ask a series of questions
while true; do
	# Ask for an install location
	echo "Enter an installation folder or press return to"
	echo "accept the default install location"
	echo 
	echo -n "[$BASE]: "
		read CHOICE
	echo

	# Use BASE as the default
	if [ -z "$CHOICE" ]; then
		CHOICE=$BASE
	fi

	# Allow for relative paths
	CHOICE=`eval echo $CHOICE`
	EXPAND=`expandPath "$CHOICE"`
	EXPAND=${EXPAND%/}

	# Allow install only under your home folder
	if [[ $EXPAND == $HOME* ]]; then
		echo "The install folder will be:"
		echo "$EXPAND"
		echo
	else
		echo "The install folder must be under your personal home folder"
		echo
		continue
	fi

	# Confirm their choice
	echo -n "Continue? (y,n): "
	read CHOICE
	echo 

	case $CHOICE in
		[yY][eE][sS]|[yY]) 
			;;
		*)
			echo
			echo "Exiting, nothing installed."
			echo
			exit 1
			;;
	esac

	# If folder already exists ask to remove it
	if [ -d "$EXPAND" ]; then
		echo "Directory already exist"
		echo -n "Remove the entire folder and overwrite? (y,n): "
		read CHOICE
		case $CHOICE in
			[yY][eE][sS]|[yY]) 
				echo
				rm -rf $EXPAND
				;;
			*)
				echo
				echo "Exiting, nothing installed."
				echo
				exit 1
				;;
		esac
	fi

	break
done

# Ask for permission to create a local application shortcut
echo
echo "After install do you want a shortcut created in:"
read -r -p "$HOME/.local/share/applications (y/n)? " SHORTCUT
echo 

# Block comment for testing
: <<'COMMENT'
COMMENT

# Create the folder
BASE=$EXPAND
mkdir -p $BASE

# Exit if the folder could not be created
if [ ! -d "$BASE" ]; then
  echo "Could not create directory"
  echo
  echo "Exiting, installation failed."
  echo
  exit 1;
fi

cd $BASE

# Determine operating system architecture
CPU=$(uname -m)

if [ "$CPU" = "i686" ]; then
	CPU="i386"
fi

if [ "$CPU" = "i386" ]; then
    COMPILER="ppc386"
fi

if [ "$CPU" = "x86_64" ]; then
    COMPILER="ppcx64"
fi

if [ "$CPU" = "armv6l" ]; then
	CPU="arm"
    COMPILER="ppcarm"
fi

if [ "$CPU" = "armv7l" ]; then
	CPU="arm"
    COMPILER="ppcarm"
fi

# Download from GitHub 
URL=https://github.com/ultibohub

# Download into downloads folder
mkdir -p $BASE/downloads

# Download a minimal version of FPC stable
echo "Downloading FPC minimal stable $FPC_STABLE"
#cp $HOME/test/fpc-$FPC_STABLE.$CPU-linux.zip $BASE/downloads/fpc-$FPC_STABLE.$CPU-linux.zip
download "$BASE/downloads/fpc-$FPC_STABLE.$CPU-linux.zip" $URL/Tools/releases/download/1.0.5/fpc-$FPC_STABLE.$CPU-linux.zip
exitFailure

# Unzip FPC stable
echo "Extracting FPC minimal stable $FPC_STABLE"
unzip -q downloads/fpc-$FPC_STABLE.$CPU-linux.zip -d $BASE

# Add FPC stable to our path
OLDPATH=$PATH
export PPC_CONFIG_PATH=$BASE/fpc-$FPC_STABLE.$CPU-linux/bin
export PATH=$PPC_CONFIG_PATH:$OLDPATH

# Download Ultibo core
echo "Downloading Ultibo core"
download "$BASE/downloads/Core.zip" $URL/Core/archive/master.zip
exitFailure

# Download Ultibo examples
echo "Downloading Ultibo examples"
download "$BASE/downloads/Examples.zip" $URL/Examples/archive/master.zip
exitFailure

# Download Free Pascal (Ultibo edition)
echo "Downloading Free Pascal (Ultibo edition)"
download "$BASE/downloads/FPC.zip" $URL/FPC/archive/master.zip
exitFailure

# Download Lazarus (Ultibo edition)
echo "Downloading Lazarus (Ultibo edition)"
download "$BASE/downloads/Lazarus.zip" $URL/Lazarus/archive/master.zip
exitFailure

# Unzip Ultibo core
echo "Extracting Ultibo core"
unzip -q downloads/Core.zip -d downloads

# Unzip Ultibo examples
echo "Extracting Ultibo examples"
unzip -q downloads/Examples.zip -d downloads

# Unzip Free Pascal (Ultibo edition)
echo "Extracting Free Pascal (Ultibo edition)"
unzip -q downloads/FPC.zip -d downloads

# Unzip Lazarus (Ultibo edition)
echo "Extracting Lazarus (Ultibo edition)"
unzip -q downloads/Lazarus.zip -d downloads

# Move files to correct locations
mv downloads/FPC-master $BASE/fpc
mv downloads/Core-master/source/rtl/ultibo $BASE/fpc/source/rtl/ultibo
mv downloads/Core-master/source/packages/ultibounits $BASE/fpc/source/packages/ultibounits
mv downloads/Core-master/units $BASE/fpc/units
mv downloads/Examples-master $BASE/examples
mv downloads/Lazarus-master/* $BASE
rm -rf $BASE/examples/Synapse

# Build the Free Pascal (Ultibo edition) compiler
cd $BASE/fpc/source
if [ "$CPU" != "arm" ]; then
    make distclean
    exitFailure
    make all OS_TARGET=linux CPU_TARGET=$CPU
    exitFailure
    make install OS_TARGET=linux CPU_TARGET=$CPU INSTALL_PREFIX=$BASE/fpc
    exitFailure
else
    make distclean
    exitFailure
    make all OPT=-dFPC_ARMHF
    exitFailure
    make install OPT=-dFPC_ARMHF PREFIX=$BASE/fpc
    exitFailure
fi

# Copy the new compiler to the bin directory
cp $BASE/fpc/lib/fpc/$FPC_BUILD/$COMPILER $BASE/fpc/bin/$COMPILER

# Create a configuration file for the new compiler
$BASE/fpc/bin/fpcmkcfg -d basepath=$BASE/fpc/lib/fpc/$FPC_BUILD -o $BASE/fpc/bin/fpc.cfg
$BASE/fpc/bin/fpcmkcfg -p -d basepath=$BASE/fpc/lib/fpc/$FPC_BUILD -o $BASE/fpc/etc/fpc.cfg

# Add the compiler we just built to our paths
export PPC_CONFIG_PATH=$BASE/fpc/bin
export PATH=$PPC_CONFIG_PATH:$OLDPATH

# Check if cross compiler required
if [ "$CPU" != "arm" ]; then
    # Build the FPC ARM Cross Compiler
    make distclean OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv7a BINUTILSPREFIX=arm-none-eabi- FPCOPT="-dFPC_ARMHF" CROSSOPT="-CpARMV7A -CfVFPV3 -CIARM -CaEABIHF -OoFASTMATH" FPC=$BASE/fpc/bin/$COMPILER
    exitFailure
    make all OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv7a BINUTILSPREFIX=arm-none-eabi- FPCOPT="-dFPC_ARMHF" CROSSOPT="-CpARMV7A -CfVFPV3 -CIARM -CaEABIHF -OoFASTMATH" FPC=$BASE/fpc/bin/$COMPILER
    exitFailure
    make crossinstall BINUTILSPREFIX=arm-none-eabi- FPCOPT="-dFPC_ARMHF" CROSSOPT="-CpARMV7A -CfVFPV3 -CIARM -CaEABIHF -OoFASTMATH" OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv7a FPC=$BASE/fpc/bin/$COMPILER INSTALL_PREFIX=$BASE/fpc
    exitFailure

    # Copy the cross compiler to the bin directory
    cp $BASE/fpc/lib/fpc/$FPC_BUILD/ppcrossarm $BASE/fpc/bin/ppcrossarm
fi    

# Building the Ultibo RTL
# Ultibo RTL for ARMv7
make rtl_clean CROSSINSTALL=1 OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv7a BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV7A -CfVFPV3 -CIARM -CaEABIHF -OoFASTMATH" FPC=$BASE/fpc/bin/fpc
exitFailure
echo 0 > $BASE/fpc/source/rtl/ultibo/core/coveragesubroutinecounter.txt
sed -i '/^procedure StartupHandler;$/a procedure CoverageSvcHandler;' $BASE/fpc/source/rtl/ultibo/core/bootqemuvpb.pas
sed -i '/^end\.$/i procedure CoverageSvcHandler; assembler; nostackframe;\nasm\n stmfd r13!,{r14}\n ldmfd r13!,{r15}^\nend;' $BASE/fpc/source/rtl/ultibo/core/bootqemuvpb.pas
sed -i 's/ARMv7SoftwareInterruptHandler/CoverageSvcHandler/g' $BASE/fpc/source/rtl/ultibo/core/bootqemuvpb.pas
make rtl OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv7a BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV7A -CfVFPV3 -CIARM -CaEABIHF -OoFASTMATH" FPC=$INSTALLER_DIR/fpc-with-coverage.sh
exitFailure
rm -rf $INSTALLER_DIR/ultibo-coverage-s-files
mkdir -p $INSTALLER_DIR/ultibo-coverage-s-files
cp -a $HOME/ultibo/core/fpc/source/rtl/units/arm-ultibo/*.s $INSTALLER_DIR/ultibo-coverage-s-files
make rtl_install CROSSINSTALL=1 BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV7A -CfVFPV3 -CIARM -CaEABIHF -OoFASTMATH" OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv7a FPC=$BASE/fpc/bin/fpc INSTALL_PREFIX=$BASE/fpc INSTALL_UNITDIR=$BASE/fpc/units/armv7-ultibo/rtl
exitFailure

# Packages for ARMv7
make rtl_clean CROSSINSTALL=1 OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv7a BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV7A -CfVFPV3 -CIARM -CaEABIHF -OoFASTMATH" FPC=$BASE/fpc/bin/fpc
exitFailure
make packages_clean CROSSINSTALL=1 OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv7a BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV7A -CfVFPV3 -CIARM -CaEABIHF -OoFASTMATH" FPC=$BASE/fpc/bin/fpc
exitFailure
make packages OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv7a BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV7A -CfVFPV3 -CIARM -CaEABIHF -OoFASTMATH -Fu$BASE/fpc/units/armv7-ultibo/rtl" FPC=$BASE/fpc/bin/fpc
exitFailure
make packages_install CROSSINSTALL=1 BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV7A -CfVFPV3 -CIARM -CaEABIHF -OoFASTMATH" OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv7a FPC=$BASE/fpc/bin/fpc INSTALL_PREFIX=$BASE/fpc INSTALL_UNITDIR=$BASE/fpc/units/armv7-ultibo/packages
exitFailure

## Ultibo RTL for ARM6
#make rtl_clean CROSSINSTALL=1 OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv6 BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV6 -CfVFPV2 -CIARM -CaEABIHF -OoFASTMATH" FPC=$BASE/fpc/bin/fpc
#exitFailure
#make rtl OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv6 BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV6 -CfVFPV2 -CIARM -CaEABIHF -OoFASTMATH" FPC=$BASE/fpc/bin/fpc
#exitFailure
#make rtl_install CROSSINSTALL=1 BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV6 -CfVFPV2 -CIARM -CaEABIHF -OoFASTMATH" OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv6 FPC=$BASE/fpc/bin/fpc INSTALL_PREFIX=$BASE/fpc INSTALL_UNITDIR=$BASE/fpc/units/armv6-ultibo/rtl
#exitFailure
#
## Packages for ARMv6
#make rtl_clean CROSSINSTALL=1 OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv6 BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV6 -CfVFPV2 -CIARM -CaEABIHF -OoFASTMATH" FPC=$BASE/fpc/bin/fpc
#exitFailure
#make packages_clean CROSSINSTALL=1 OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv6 BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV6 -CfVFPV2 -CIARM -CaEABIHF -OoFASTMATH" FPC=$BASE/fpc/bin/fpc
#exitFailure
#make packages OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv6 BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV6 -CfVFPV2 -CIARM -CaEABIHF -OoFASTMATH -Fu$BASE/fpc/units/armv6-ultibo/rtl" FPC=$BASE/fpc/bin/fpc
#exitFailure
#make packages_install CROSSINSTALL=1 BINUTILSPREFIX=arm-none-eabi- FPCFPMAKE=$BASE/fpc/bin/fpc CROSSOPT="-CpARMV6 -CfVFPV2 -CIARM -CaEABIHF -OoFASTMATH" OS_TARGET=ultibo CPU_TARGET=arm SUBARCH=armv6 FPC=$BASE/fpc/bin/fpc INSTALL_PREFIX=$BASE/fpc INSTALL_UNITDIR=$BASE/fpc/units/armv6-ultibo/packages
#exitFailure

# Create the Configuration files
echo "Creating configuration files"
# RPI.CFG
CONFIGFILE="$BASE/fpc/bin/RPI.CFG"
echo "#" > $CONFIGFILE
echo "# Raspberry Pi (A/B/A+/B+/Zero) specific config file" >> $CONFIGFILE
echo "#" >> $CONFIGFILE
echo "-CfVFPV2" >> $CONFIGFILE
echo "-CIARM" >> $CONFIGFILE
echo "-CaEABIHF" >> $CONFIGFILE
echo "-OoFASTMATH" >> $CONFIGFILE
echo "-XParm-none-eabi-" >> $CONFIGFILE
echo "-Fu$BASE/fpc/units/armv6-ultibo/rtl" >> $CONFIGFILE
echo "-Fu$BASE/fpc/units/armv6-ultibo/packages" >> $CONFIGFILE
echo "-Fl$BASE/fpc/units/armv6-ultibo/lib" >> $CONFIGFILE
echo "-Fl$BASE/fpc/units/armv6-ultibo/lib/vc4" >> $CONFIGFILE

# RPI2.CFG
CONFIGFILE="$BASE/fpc/bin/RPI2.CFG"
echo "#" > $CONFIGFILE
echo "# Raspberry Pi 2B specific config file" >> $CONFIGFILE
echo "#" >> $CONFIGFILE
echo "-CfVFPV3" >> $CONFIGFILE
echo "-CIARM" >> $CONFIGFILE
echo "-CaEABIHF" >> $CONFIGFILE
echo "-OoFASTMATH" >> $CONFIGFILE
echo "-XParm-none-eabi-" >> $CONFIGFILE
echo "-Fu$BASE/fpc/units/armv7-ultibo/rtl" >> $CONFIGFILE
echo "-Fu$BASE/fpc/units/armv7-ultibo/packages" >> $CONFIGFILE
echo "-Fl$BASE/fpc/units/armv7-ultibo/lib" >> $CONFIGFILE
echo "-Fl$BASE/fpc/units/armv7-ultibo/lib/vc4" >> $CONFIGFILE

# RPI3.CFG
CONFIGFILE="$BASE/fpc/bin/RPI3.CFG"
echo "#" > $CONFIGFILE
echo "# Raspberry Pi 3B specific config file" >> $CONFIGFILE
echo "#" >> $CONFIGFILE
echo "-CfVFPV3" >> $CONFIGFILE
echo "-CIARM" >> $CONFIGFILE
echo "-CaEABIHF" >> $CONFIGFILE
echo "-OoFASTMATH" >> $CONFIGFILE
echo "-XParm-none-eabi-" >> $CONFIGFILE
echo "-Fu$BASE/fpc/units/armv7-ultibo/rtl" >> $CONFIGFILE
echo "-Fu$BASE/fpc/units/armv7-ultibo/packages" >> $CONFIGFILE
echo "-Fl$BASE/fpc/units/armv7-ultibo/lib" >> $CONFIGFILE
echo "-Fl$BASE/fpc/units/armv7-ultibo/lib/vc4" >> $CONFIGFILE

# QEMUVPB.CFG
CONFIGFILE="$BASE/fpc/bin/QEMUVPB.CFG"
echo "#" > $CONFIGFILE
echo "# QEMU VersatilePB specific config file" >> $CONFIGFILE
echo "#" >> $CONFIGFILE
echo "-CfVFPV3" >> $CONFIGFILE
echo "-CIARM" >> $CONFIGFILE
echo "-CaEABIHF" >> $CONFIGFILE
echo "-OoFASTMATH" >> $CONFIGFILE
echo "-XParm-none-eabi-" >> $CONFIGFILE
echo "-Fu$BASE/fpc/units/armv7-ultibo/rtl" >> $CONFIGFILE
echo "-Fu$BASE/fpc/units/armv7-ultibo/packages" >> $CONFIGFILE
echo "-Fl$BASE/fpc/units/armv7-ultibo/lib" >> $CONFIGFILE

echo skipping lazarus
exit

# Build Lazarus
# Create the missing Package.fpc for regexpr
PACKAGEFILE="$BASE/fpc/lib/fpc/$FPC_BUILD/units/$CPU-linux/regexpr/Package.fpc"
echo "[package]" > $PACKAGEFILE
echo "name=regexpr" >> $PACKAGEFILE
echo "version=$FPC_BUILD" >> $PACKAGEFILE
echo "[require]" >> $PACKAGEFILE
echo "packages_linux_$CPU=" >> $PACKAGEFILE

# Add the FPCDIR variable
export FPCDIR=$BASE/fpc/lib/fpc/$FPC_BUILD

# Update the Makefiles
cd $BASE
fpcmake -T$CPU-linux -v
exitFailure
cd ide
fpcmake -T$CPU-linux -v
exitFailure
cd ../components
fpcmake -T$CPU-linux -v
exitFailure
cd ../tools
fpcmake -T$CPU-linux -v
exitFailure
cd ..

# Build the Lazarus IDE
make clean all OPT="@$BASE/fpc/bin/fpc.cfg"
exitFailure

# Restore our path
export PATH=$OLDPATH

# Create a Lazarus shortcut file
SHORTCUTFILE="$BASE/ultibo.desktop"
echo "[Desktop Entry]" > $SHORTCUTFILE
echo "Name=Lazarus IDE (Ultibo Edition)" >> $SHORTCUTFILE
echo "Comment=A free pascal platform for bare metal development" >> $SHORTCUTFILE
echo "Exec=$BASE/lazarus.sh" >> $SHORTCUTFILE
echo "Icon=$BASE/images/icons/lazarus.ico" >> $SHORTCUTFILE
echo "Terminal=false" >> $SHORTCUTFILE
echo "Type=Application" >> $SHORTCUTFILE
echo "Categories=Development;IDE;" >> $SHORTCUTFILE
chmod +x $SHORTCUTFILE

# Create a Lazarus startup file
STARTUPFILE="$BASE/lazarus.sh"
echo "export PATH=$BASE/fpc/bin:\$PATH" > $STARTUPFILE
echo "export PPC_CONFIG_PATH=$BASE/fpc/bin" >> $STARTUPFILE
echo "$BASE/lazarus" >> $STARTUPFILE
chmod +x $STARTUPFILE

# Create a Lazarus config file
CONFIGFILE="$BASE/lazarus.cfg"
echo "#--disabledocking" > $CONFIGFILE

# Create a Lazarus options file
OPTIONSFILE="$BASE/environmentoptions.xml"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > $OPTIONSFILE
echo "<CONFIG>" >> $OPTIONSFILE
echo "  <EnvironmentOptions>" >> $OPTIONSFILE
echo "    <Version Value=\"109\" Lazarus=\"1.6U\"/>" >> $OPTIONSFILE
echo "    <LazarusDirectory Value=\"$BASE\">" >> $OPTIONSFILE
echo "    </LazarusDirectory>" >> $OPTIONSFILE
echo "    <CompilerFilename Value=\"$BASE/fpc/bin/fpc\">" >> $OPTIONSFILE
echo "    </CompilerFilename>" >> $OPTIONSFILE
echo "    <FPCSourceDirectory Value=\"$BASE/fpc/source\">" >> $OPTIONSFILE
echo "    </FPCSourceDirectory>" >> $OPTIONSFILE
echo "    <MakeFilename Value=\"make\">" >> $OPTIONSFILE
echo "    </MakeFilename>" >> $OPTIONSFILE
echo "    <TestBuildDirectory Value=\"~/tmp/\">" >> $OPTIONSFILE
echo "    </TestBuildDirectory>" >> $OPTIONSFILE
echo "    <Debugger Class=\"TGDBMIDebugger\"/>" >> $OPTIONSFILE
echo "    <DebuggerFilename Value=\"gdb\">" >> $OPTIONSFILE
echo "    </DebuggerFilename>" >> $OPTIONSFILE
echo "  </EnvironmentOptions>" >> $OPTIONSFILE
echo "</CONFIG>" >> $OPTIONSFILE

# Install the shortcut
case $SHORTCUT in
    [yY][eE][sS]|[yY]) 
		if type desktop-file-install > /dev/null; then
			desktop-file-install --dir="$HOME/.local/share/applications" "$BASE/ultibo.desktop"
		else
			cp "$BASE/ultibo.desktop" "$HOME/.local/share/applications"
		fi
		echo
		;;
    *)
		echo 
		;;
esac

# Check for Lazarus options file
if [ ! -f $HOME/.ultibo/core/environmentoptions.xml ]; then
    mkdir -p $HOME/.ultibo/core
    cp $BASE/environmentoptions.xml $HOME/.ultibo/core/environmentoptions.xml
fi

# Delete the temporary version of fpc stable
rm -rf $BASE/fpc-$FPC_STABLE.$CPU-linux
 
# Cleanup the downloads folder
rm -rf $BASE/downloads

# Install complete
echo 
echo "Free Pascal and Lazarus (Ultibo edition) install complete"
echo 
echo "Launch Lazarus from the application shortcut or by using"
echo "  $BASE/lazarus.sh"
echo "from the command line"
echo 
