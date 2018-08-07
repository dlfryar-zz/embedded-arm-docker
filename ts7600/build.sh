#!/bin/bash

echo "Create epoch time file /root/epoch_time.txt"
date +%s > /root/epoch_time.txt
EPOCH_TIME=$(cat /root/epoch_time.txt)

mkdir /root/Source && cd /root/Source

git clone git://git.openembedded.org/openembedded-core oe-core && cd oe-core

# remove the check so we can build as root
# https://forums.xilinx.com/t5/Embedded-Linux/petaLinux-build-linux-donot-use-bitbake-as-root-error/td-p/750023
sed -i '/INHERIT += "sanity"/d' meta/conf/sanity.conf

git clone git://git.openembedded.org/bitbake bitbake && git checkout rocko
cd bitbake && git checkout 1.36 && cd ..
source oe-init-build-env && bitbake core-image-minimal

echo "---> Keeping the container running with a tail of the build logs"
tail -f /root/epoch_time.txt
