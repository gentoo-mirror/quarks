#!/bin/sh
# set -x
CPUS=$(nproc)

# as many cc as CPUs
export MAKEOPTS="-j${CPUS}"

# Trigger mount
# ls /mnt/portage/distfiles /mnt/portage/portage > /dev/null

# Half as many emerge as CPUs, to speed up configure runs
emerge --ask --update --deep --newuse --keep-going --accept-properties=-interactive --jobs $((CPUS/2)) world

# echo "Fixing pax flags..."
# ${SCRIPT_DIR}/fix_grsec.sh

echo "Going to remove unneeded packages ..."
emerge --depclean

echo "Fixing dependencies..."
revdep-rebuild -i

echo "Updating eix cache..."
eix-update -q
