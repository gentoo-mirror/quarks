#!/bin/bash
set -x

# Sets up all kinds of softlinks and scripts to share all gentoo/portage 
# across multiple machines backed by git repository

link() {
	FROM=$1
	TO=$2
	PREFIX=$3
	pushd $PREFIX > /dev/null
	for i in $FROM; do
		[ -e $i ] || ln -s $TO/$i $i
	done
	popd > /dev/null
}

link "update_portage.sh update_box.sh make_kernel.sh" "/mnt/portage/overlays/quarks/scripts" "/usr/local/sbin"
link "make.conf package.use package.keywords package.license" "/mnt/portage/overlays/quarks/conf/portage" "/etc/portage"
