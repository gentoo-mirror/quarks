#!/bin/sh
#set -x

# Look at CPU and return all actually available USE flags
get_cpu_use() {
	AVAILABLE_USE="mmx mmxext sse sse2 sse3 ssse3 sse4 sse4_1 avx 3dnow 3dnowext" 
	CPU_FLAGS=$(cat /proc/cpuinfo | grep flags | cut -d\  -f2- | uniq)

	_USE=""
	for f in ${AVAILABLE_USE}; do
		if [ "$CPU_FLAGS" != "${CPU_FLAGS/$f/}" ]; then
			_USE="$_USE $f"
		fi
	done
	echo $_USE
}

CPU_USE=$(get_cpu_use)
export USE="$CPU_USE"

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
