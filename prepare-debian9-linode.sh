#/bin/bash

# tzdata
cat > ~/.exrc << __EOF__
set noai ic
__EOF__
apt-get update
apt-get -y dist-upgrade
apt-get -y install tmux fail2ban ufw

apt-get -y install libgtk2.0-dev libcairo2-dev \
  libpango1.0-dev libgdk-pixbuf2.0-dev libatk1.0-dev \
  libghc-x11-dev

apt-get -y install binutils-arm-none-eabi

apt-get -y install build-essential gdb-minimal unzip

apt-get -y install qemu-system-arm
