#!/bin/sh
# set -x

emerge --update --deep --newuse --pretend world

echo "Press Ctrl-C to abort..."
read

# Trigger mount
# ls /mnt/portage/distfiles /mnt/portage/portage > /dev/null

emerge --update --deep --newuse --keep-going world

# echo "Fixing pax flags..."
# ${SCRIPT_DIR}/fix_grsec.sh

echo "Going to remove unneeded packages ..."
emerge --depclean

echo "Fixing dependencies..."
revdep-rebuild -i
