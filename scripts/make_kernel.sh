#!/bin/sh
set -e

cd /usr/src/linux

# make clean
# make oldconfig
make menuconfig
make all ${MAKEOPTS}
make modules_install

NEW=$(make kernelversion)
TARGET=/boot

# If EFI store kernel under EFI
[ -d /sys/firmware/efi ] && [ -d /boot/EFI/Gentoo ] && TARGET=/boot/EFI/Gentoo

dracut --xz -H --force --strip ${TARGET}/initrd-${NEW} ${NEW}

export INSTALL_PATH=${TARGET}
make install

if [ ! -d /sys/firmware/efi ]; then
	grub2-mkconfig -o ${TARGET}/grub/grub.cfg
	pushd ${TARGET} >/dev/null
	ln -sf System.map-${NEW} System.map
	popd > /dev/null
fi

echo "Building tools from within kernel sources..."
echo "  cpupower (requires pciutils):"
cd tools/power/cpupower && make ${MAKEOPTS}
cp -a cpupower /usr/local/bin
cp -a libcpupower.so* /usr/lib

echo "After successful boot of new kernel run:"
echo "   root # emerge @module-rebuild"
# eselect opengl set ati

cp /usr/src/linux/.config  /etc/kernel/kernel-config-${NEW} 
