#!/bin/sh
set -e

[ "x$NEW" == "x" ] && NEW=$(grep "Kernel Configuration" /usr/src/linux/.config | awk '{print $3}')
echo $NEW

cd /usr/src/linux-${NEW} 
# make clean
# make oldconfig
make menuconfig
make all ${MAKEOPTS}
make modules_install

for f in initrd vmlinuz System.map config; do
	[ -e "/boot/$f-${NEW}" ] && mv "/boot/$f-${NEW}" "/boot/$f-${NEW}.previous"
done

cp /usr/src/linux/.config  /etc/kernel/kernel-config-${NEW} 
make install

dracut -H --force --strip /boot/initrd-${NEW} ${NEW}

grub2-mkconfig -o /boot/grub2/grub.cfg

echo "Building tools from within kernel sources..."
echo "  cpupower:"
cd /usr/src/linux/tools/power/cpupower && make
cp -a cpupower /usr/local/bin
cp -a libcpupower.so* /usr/lib

echo "After successful boot of new kernel run:"
echo "   root # module-rebuild rebuild"
# eselect opengl set ati
