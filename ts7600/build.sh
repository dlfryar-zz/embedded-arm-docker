#!/bin/bash

# COMPILE="yes"

echo "Create epoch time file /root/epoch_time.txt"
date +%s > /root/epoch_time.txt && EPOCH_TIME=$(cat /root/epoch_time.txt)

echo "Setup path for platform compiler"
export PATH=$PATH:/root/.local/bin:/root/.local/arm-fsl-linux-gnueabi/bin

echo "---> mkdir /root/Source /root/Download"
mkdir -p /root/Source /root/Download /root/.local/bin

echo "---> create /root/.netrc for aria2c"
touch /root/.netrc && chmod 600 /root/.netrc

# install compilers
echo "---> cd /root/Download"
cd /root/Download

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
mv arm-fsl-linux-gnueabi /root/.local/

# install kernel
echo "---> Clone 2.6.35.3 kernel"
cd /root/Source && git clone https://github.com/embeddedarm/linux-2.6.35.3-imx28.git

echo "---> Clone 3.14.28 kernel"
cd /root/Source && git clone https://github.com/embeddedarm/linux-3.14.28-imx28.git

echo "---> Checkout linux-3.14.79-7600-4600"
cd linux-3.14.28-imx28 && git checkout 7600-4600 && git checkout linux-3.14.79-7600-4600

echo "---> Export compiler vars for platform"
export ARCH=arm
export CROSS_COMPILE=/root/.local/arm-fsl-linux-gnueabi/bin/arm-linux-
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

echo "---> Keeping the container running with a tail of the build logs"
tail -f /root/epoch_time.txt
