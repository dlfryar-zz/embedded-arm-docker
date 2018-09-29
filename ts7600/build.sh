#!/bin/bash

# COMPILE="yes"

echo "Create epoch time file ~/epoch_time.txt"
date +%s > ~/epoch_time.txt && EPOCH_TIME=$(cat ~/epoch_time.txt)

echo "Setup path for platform compiler"
sed 's/mesg n || true/PATH=$PATH:~\/.local\/arm-fsl-linux-gnueabi\/bin\n\nmesg n || true/' ~/.profile 

echo "---> mkdir ~/Source ~/Download"
mkdir -p ~/Source ~/Download ~/.local/bin

echo "---> create ~/.netrc for aria2c"
touch ~/.netrc && chmod 600 ~/.netrc

# install compilers
echo "---> cd ~/Download"
cd ~/Download

# Connection limit of 30 set on ftp.embeddedarm.com
echo "---> Download SD card image ts4600_7600-mar092018-4GB.dd.bz2"
lftp -e 'pget -n 20 ftp://ftp.embeddedarm.com/ts-arm-sbc/ts-7600-linux/binaries/ts-images/ts4600_7600-mar092018-4GB.dd.bz2'

echo "---> Unarchive SD card image ts4600_7600-mar092018-4GB.dd.bz2"
tar -xjf ts4600_7600-mar092018-4GB.dd.bz2

# Connection limit of 30 set on ftp.embeddedarm.com
echo "---> Download cross compilers from ftp.embeddedarm.com (158MB)"
lftp -e 'pget -n 20 ftp://ftp.embeddedarm.com/ts-arm-sbc/ts-7600-linux/cross-toolchains/imx28-cross-glibc.tar.bz2'
# aria2c -x 16 ftp://ftp.embeddedarm.com/ts-arm-sbc/ts-7600-linux/cross-toolchains/imx28-cross-glibc.tar.bz2

echo "---> Unarchive imx28-cross-glibc cross compiler"
tar -xjf imx28-cross-glibc.tar.bz2

echo "---> Move unarchived imx28-cross-glibc cross compiler to .local"
mv arm-fsl-linux-gnueabi ~/.local/

# install kernel
echo "---> Clone 2.6.35.3 kernel"
cd ~/Source && git clone https://github.com/embeddedarm/linux-2.6.35.3-imx28.git

echo "---> Clone 3.14.28 kernel"
cd ~/Source && git clone https://github.com/embeddedarm/linux-3.14.28-imx28.git

echo "---> Checkout linux-3.14.79-7600-4600"
cd linux-3.14.28-imx28 && git checkout 7600-4600 && git checkout linux-3.14.79-7600-4600

echo "---> Export compiler vars for platform"
export ARCH=arm
export CROSS_COMPILE=~/.local/arm-fsl-linux-gnueabi/bin/arm-linux-
export LOADADDR=0x40008000
 
# This sets up the default configuration
echo "---> Make default config for 3.14.28 kernel"
make ts7600_defconfig

if [ "$COMPILE" ]; then
    echo "---> Build 3.14.28 kernel/zImage/modules"
    make && make zImage && make modules

    echo "---> Create 128MB zImage"
    cat arch/arm/boot/zImage arch/arm/boot/dts/imx28-ts7600-128M.dtb > zImage

    echo "---> Move zImage to arch/arm/boot"
    mv zImage arch/arm/boot/

    patch -p1 < install_bootstream-newer-fdisk.patch
    ./build_bootstream
fi

# ./install_bootstream imx-bootlets-src-10.12.01/imx28_ivt_linux.sb mmcblk0 p1
# ./install_hdr_mod mmcblk0p2

echo "---> Clone NodeJS"
cd ~/Source && git clone https://github.com/nodejs/node.git

echo "---> cd to node source dir and copy .env for compiler"
cd node && cp ~/Config/.env .

echo "---> Source compiler env to build NodeJS"
source .env

echo "---> Keeping the container running with a tail of the build logs"
tail -f ~/epoch_time.txt
