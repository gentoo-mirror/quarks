#!/bin/sh
# set -x

PORTAGE=/mnt/portage/portage

emerge -q --sync 
layman -q -S

# Delete any package mask
[ -f ${PORTAGE}/profiles/hardened/linux/amd64/package.mask ] && rm -f ${PORTAGE}/profiles/hardened/linux/amd64/package.mask
# Reenable nvidia
perl -i -p -e 's/^(nvidia|video_cards_nvidia|vdpau|cuda|opencl)/# $1/;' ${PORTAGE}/profiles/hardened/linux/use.mask ${PORTAGE}/profiles/hardened/linux/amd64/use.mask

# echo "Cleaning up archives.."
eclean -q packages
eclean -q distfiles
