#!/bin/sh
# set -x
CPUS=$(nproc)

emerge --update --deep --newuse --pretend --jobs ${CPUS} world

echo "Press Ctrl-C to abort..."
read

# Trigger mount
# ls /mnt/portage/distfiles /mnt/portage/portage > /dev/null

emerge --update --deep --newuse --keep-going --jobs ${CPUS} world

# echo "Fixing pax flags..."
# ${SCRIPT_DIR}/fix_grsec.sh

echo "Going to remove unneeded packages ..."
emerge --depclean --jobs ${CPUS}

echo "Fixing dependencies..."
revdep-rebuild -i
