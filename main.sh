#! /bin/bash
DRIVER=525

chmod +x ./nvidia-pikaos-kernel-module/get_pwd.sh

echo "$(apt-cache show nvidia-driver-$DRIVER | grep Version: | head -n1 | cut -f2 -d":" | cut -f1,2,3 -d"." | cut -f1 -d"-" | tr -d ' ')" > ./nvidia-pikaos-kernel-module/DRIVER
echo "$(apt-cache show kernel-pika | grep Depends: | head -n1 | cut -f2 -d":" | cut -f1 -d"," | cut -f3,4 -d"-" | tr -d ' ')" > ./nvidia-pikaos-kernel-module/KERNEL
echo "$(apt-cache show nvidia-kernel-source-525 | grep Version: | head -n1 | cut -f2 -d":" | tr -d ' ')" > ./nvidia-pikaos-kernel-module/DRIVER_VERSION

cd ./nvidia-pikaos-kernel-module

echo -e "nvidia-pikaos-kernel-module ($(cat ./DRIVER)-$(cat ./KERNEL)-99pika5.lunar) lunar; urgency=medium\n\n  * New Release\n\n -- Ward Nakchbandi <hotrod.master@hotmail.com> Sat, 01 Oct 2022 14:50:00 +0200" > debian/changelog

echo -e "Source: nvidia-pikaos-kernel-module\nSection: graphics\nPriority: optional\nMaintainer: Ward Nakchbandi <hotrod.master@hotmail.com>\nStandards-Version: 4.6.1\nBuild-Depends: debhelper-compat (= 13), linux-image-$(cat ./KERNEL), linux-headers-$(cat ./KERNEL), dkms, fakeroot\nRules-Requires-Root: no\n\nPackage: nvidia-$(cat ./KERNEL)-module-$DRIVER\nArchitecture: linux-any\nDepends: linux-image-$(cat ./KERNEL), linux-headers-$(cat ./KERNEL), $(apt-cache show nvidia-dkms-$DRIVER | grep Depends: | head -n1 | cut -f2 -d":")\nConflicts: nvidia-dkms-$DRIVER (= $(cat DRIVER_VERSION))\nProvides: nvidia-dkms-$DRIVER (= $(cat DRIVER_VERSION))\nReplaces: nvidia-dkms-$DRIVER (= $(cat DRIVER_VERSION))\nDescription: Prebuilt Nvidia module for PikaOS kernel\n\nPackage: nvidia-pika-kernel-module-$DRIVER\nArchitecture: linux-any
Depends: nvidia-$(cat ./KERNEL)-module-$DRIVER $(echo '(= ${binary:Version})')\nDescription: DKMS NVIDIA PLACEHOLDER" > ./debian/control
echo -e "usr\netc" > ./debian/nvidia-$(cat ./KERNEL)-module-$DRIVER.install

echo -e "DRIVER=$(cat ./DRIVER)\nKERNEL=$(cat ./KERNEL)\nVERSION=$(cat ./DRIVER_VERSION)\nMK_WORKDIR=$(env | grep -w "PWD" | cut -c5-)\nCARCH=x86_64" > ./Makefile
cat ./Makefiletmp >> ./Makefile

DEBIAN_FRONTEND=noninteractive

# Get build deps
apt-get build-dep ./ -y
apt download nvidia-kernel-source-$DRIVER -y
dpkg-deb -x ./nvidia-kernel-source-$DRIVER*.deb /
apt download nvidia-dkms-$DRIVER -y
dpkg-deb -x ./nvidia-dkms-$DRIVER*.deb /

# Build package
dpkg-buildpackage --no-sign
echo 'DKMS MAKEFILE LOG:'
cat ./nvidia/$(cat ./DRIVER)/$(cat ./KERNEL)/x86_64/log/make.log || cat ./nvidia/$(cat ./DRIVER)/build/make.log
# Move the debs to output
cd ../
mkdir -p ./output
mv ./*.deb ./output/
