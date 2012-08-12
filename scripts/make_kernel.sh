#!/bin/sh
set -e

NEW=$(grep "Kernel Configuration" /usr/src/linux/.config | awk '{print $3}')
echo $NEW

cd /usr/src/linux-${NEW}
# make clean
# make oldconfig
make -j4 menuconfig
make -j4 all
make -j4 modules_install
make install

cp /usr/src/linux/.config  /etc/kernels/kernel-config-${NEW} 

# rm -f /boot/*.previous
if [ -f "/boot/initrd-${NEW}" ] ; then
    mv "/boot/initrd-${NEW}" "/boot/initrd-${NEW}.previous"
fi

dracut -H --force --strip /boot/initrd-${NEW} ${NEW}

grub2-mkconfig -o /boot/grub2/grub.cfg

echo "After successful boot of new kernel run:"
echo "   root # module-rebuild rebuild"
# eselect opengl set ati
