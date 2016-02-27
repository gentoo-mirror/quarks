#!/bin/sh
# set -x

PORTAGE="/usr/portage"
# By default store SquashFS backing file under /mnt/portage
SQFS_PORTAGE="/mnt/portage/portage.sqfs"
# Store temporary overlayFS within portage tmpdir
OVERLAY="$(portageq envvar PORTAGE_TMPDIR)/portage.overlayfs"
OVERLAY_NAME=portage_overlay

usage () {
    cat << EOF
Usage: $0 [-p portage_tree] [-s squashfs_file]
EOF
    exit 0
}

# mount squashed portage incl. writeable overlay
mount_overlay () {
    # Make sure backing tree is mounted, try to mount otherwise
    mountpoint -q ${PORTAGE} || mount ${PORTAGE} && echo "Mounted ${PORTAGE}."

    # mount the overlay on top of existing live portage tree 
    mkdir -p ${OVERLAY} ${OVERLAY}.work
    mount | grep -q ${OVERLAY_NAME} || mount -t overlay ${OVERLAY_NAME} \
      -olowerdir=${PORTAGE},upperdir=${OVERLAY},workdir=${OVERLAY}.work \
      ${PORTAGE} && echo "Mounted Overlay file system." 
}

# umount overlay and clean up temp dirs
umount_overlay () {
    mount | grep -q ${OVERLAY_NAME}
    if [ $? -eq 0 ]; then
        umount ${OVERLAY_NAME} && rm -rf ${OVERLAY} ${OVERLAY}.work
        echo "Overlay file system unmounted."
    fi
}

# umount current, replace and mount new 
replace_squashfs () {
    [ -f ${SQFS_PORTAGE}.new ] || \
      { echo "No new portage tree version found!"; exit 1; }

    mountpoint -q ${PORTAGE}
    if [ $? -eq 0 ]; then
        umount ${PORTAGE} && echo "Unmounted ${PORTAGE}."
        if [ $? -ne 0 ]; then
            echo "Could not unmount ${PORTAGE} !"
            echo "New portage snapshot is at ${SQFS_PORTAGE}.new"
            exit 1
        fi
    fi

    if [ -f ${SQFS_PORTAGE} ]; then
        mv ${SQFS_PORTAGE} ${SQFS_PORTAGE}.previous
    else
        echo "No current squashFS backing file ${SQFS_PORTAGE} found,\
	assuming initial setup."
    fi
       
    mv ${SQFS_PORTAGE}.new ${SQFS_PORTAGE} && \
      mount ${PORTAGE} && echo "Updated tree mounted at ${PORTAGE}."
}

# Create new squashfs image
create_squashfs () {
    mksquashfs ${PORTAGE} ${SQFS_PORTAGE}.new -comp xz -noappend \
      -no-progress && echo "SquashFS snapshot created at ${SQFS_PORTAGE}.new"
}

# Any custom changes to the portage tree 
customize () {
    echo "Applying local customizations ..."

    # Delete any package mask
    [ -f ${PORTAGE}/profiles/hardened/linux/amd64/package.mask ] && \
      rm -f ${PORTAGE}/profiles/hardened/linux/amd64/package.mask

    # Reenable nvidia
    perl -i -p -e 's/^(app-admin\/conky nvidia|x11-drivers\/nvidia|nvidia|video_cards_nvidia|vdpau|cuda|opencl)/# $1/;' \
      ${PORTAGE}/profiles/hardened/linux/use.mask \
      ${PORTAGE}/profiles/hardened/linux/amd64/use.mask \
      ${PORTAGE}/profiles/hardened/linux/amd64/package.use.mask
}

cleanup () {
    # In case still mounted
    umount_overlay

    # Remove potential left overs from mksquashfs
    [ -f ${SQFS_PORTAGE}.new ] && rm -f ${SQFS_PORTAGE}.new

    # Make sure we have a working portage tree mounted
    mountpoint -q ${PORTAGE} || mount ${PORTAGE} 

    exit 1
}

while getopts "p:s:" OPTIONS; do
   case $OPTIONS in
       p) PORTAGE=$OPTARG;;
       s) SQFS_PORTAGE=$OPTARG;;
       ?) usage;;
   esac
done

[ -d ${PORTAGE} ] || { echo "${PORTAGE} is not a directory!"; usage; }

# make sure we clean up and have a working portage tree if interupted
trap "cleanup" INT TERM 

mount_overlay

emaint sync -r gentoo

# Optional 
customize

create_squashfs
umount_overlay

replace_squashfs
