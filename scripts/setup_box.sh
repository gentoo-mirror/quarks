#!/bin/bash
set -x

# Sets up all kinds of softlinks and scripts to share all gentoo/portage 
# across multiple machines backed by git repository
SBIN_PREFIX="/usr/local/sbin"
SBIN_FROM="update_portage.sh update_box.sh make_kernel.sh"
SBIN_TO="/mnt/portage/overlays/quarks/scripts"

pushd $SBIN_PREFIX > /dev/null
for i in $SBIN_FROM; do
	[ -e $i ] || ln -s $SBIN_TO/$i $i
done
popd > /dev/null
