#!/bin/sh

# - builds a generic image from a stage3 tarball and portage snapshot
# 
# based on work from JD Harrington https://github.com/psi/gentoo-aws
# and Matsuu Takuto https://gist.github.com/870789

#===============================================================================
GENTOO_MIRROR="http://distfiles.gentoo.org"
LOCAL_CACHE=/var/tmp
CHROOT=/mnt/gentoo


set -o nounset

die() {
	echo $@
	exit 1
}


verify_digest() {
	local FILE_NAME=$1
	local TYPE=$2
	local DIGEST=$3
	local PURGE=$4

	case $TYPE in
		sha512)
			FILE_DIGEST=$(sha512sum ${FILE_NAME} | awk '{print $1}') 
			;;
		md5)
			FILE_DIGEST=$(md5sum ${FILE_NAME} | awk '{print $1}') 
			;;
		*)
			echo "Unknown DIGEST"
			return 1
			;;
	esac

	if [ "${FILE_DIGEST}" = "${DIGEST}" ]; then
		echo "${TYPE} checksum for ${FILE_NAME} verified."
		return 0
	else
		echo "Invalid checksum for ${FILE_NAME}!"
		[ "x${PURGE}" != "x" ] && { echo "Removing cached copy." ; rm -f ${FILE_NAME}; }
		return 1
	fi
}


fetch_file() {
	local URL=$1
	local DIGEST_URL=$2
	
	local FILE_NAME=$(basename ${URL})

	local DIGEST_TYPE

	# Check cache
	if [ ! -d ${LOCAL_CACHE} ] || [ ! -w ${LOCAL_CACHE} ]; then
		echo "Cannot write to cache ${LOCAL_CACHE}" 
		return 1
	fi

	# If DIGEST requested get it
	if [ ! -z ${DIGEST_URL} ]; then
		DIGEST=$(curl -s -S ${DIGEST_URL} | grep -A1 -e "^# SHA512 HASH" | grep -o -E -e "^[0-9a-f]{128} *${FILE_NAME}$" | awk '{print $1}')
		if [ -z ${DIGEST} ]; then
			# Let's try md5sum before giving up
			DIGEST=$(curl -s -S ${DIGEST_URL} | grep -o -E -e "^[0-9a-f]{32} *${FILE_NAME}$" | awk '{print $1}')
			if [ -z ${DIGEST} ]; then
				echo "Unable to get checksum for ${FILE_NAME}, abort"
				return 2
			fi
			DIGEST_TYPE="md5"
		else
			DIGEST_TYPE="sha512"
		fi
	fi

	# Do we have local copy
	if [ -f ${LOCAL_CACHE}/${FILE_NAME} ]; then
		verify_digest ${LOCAL_CACHE}/${FILE_NAME} $DIGEST_TYPE ${DIGEST} 1
		if [ $? -eq 0 ]; then
			cp ${LOCAL_CACHE}/${FILE_NAME} .
			echo "Using cached ${LOCAL_CACHE}/${FILE_NAME}"
			return 0
		fi
	fi

	# We we are here either we didnt have a copy or the cached file was invalid
	wget -q -O ${LOCAL_CACHE}/${FILE_NAME} ${URL}
	if [ $? -eq 0 ]; then
		echo "Downloaded ${URL} to ${LOCAL_CACHE}/${FILE_NAME}"

		verify_digest ${LOCAL_CACHE}/${FILE_NAME} $DIGEST_TYPE ${DIGEST} 1
		if [ $? -ne 0 ]; then
			echo "Could not get a verified version of ${FILE_NAME}"
			return 3
		fi
		cp ${LOCAL_CACHE}/${FILE_NAME} .
	else
		echo "Cannot download ${URL}!"
		return 4
	fi
}


# bootstrap, download stage3 and portage snapshot
bootstrap() {

	[ -d ${CHROOT} ] || die "${CHROOT} does not exists"
	[ -w ${CHROOT} ] || die "${CHROOT} isn't writable"

	cd ${CHROOT}

	# first install stage 3
	if [ -d "usr" ] ; then
		echo "There seems to be already files in ${CHROOT} !"
		echo "Press <Ctrl+c> to abort, or <Return> to proceed without extracting stage3 ..."
		read -r REPLY
	else
		STAGE_TARBALL=${GENTOO_MIRROR}/releases/${ARCH}/autobuilds/$(curl -s ${LATEST_STAGE_FILE} | grep -v "^#" | head -n 1) 

		fetch_file "${STAGE_TARBALL}" "${STAGE_TARBALL}.DIGESTS" || die "Cannot get ${STAGE_TARBALL}"

		echo "Extracting stage3 to ${CHROOT} ..."
		tar jxpf $(basename ${STAGE_TARBALL}) || die "Extracting stage3 failed"

		rm -f $(basename ${STAGE_TARBALL})
	fi

	# Portage snapshot
	PORTAGE_SNAPSHOT="${GENTOO_MIRROR}/releases/snapshots/current/portage-latest.tar.bz2"
	_PORTAGE_MOUNTED=0

	if [ "x${BIND_PORTAGE}" != "x" -a -d ${BIND_PORTAGE} ] ; then
		mkdir -p ${CHROOT}/usr/portage
		mount --bind ${BIND_PORTAGE} ${CHROOT}/usr/portage || die "Error mounting ${BIND_PORTAGE}"

		# Remember we mounted portage
		_PORTAGE_MOUNTED=1
	else
		# install latest portage snapshot
		if [ -d "usr/portage" ] ; then
			echo "There seems to be already portage files!"
			echo "Press <Ctrl+c> to abort, or <Return> to proceed without extracting portage ..."
			read -r REPLY
		else
			fetch_file "${PORTAGE_SNAPSHOT}" "${PORTAGE_SNAPSHOT}.md5sum"
			echo "Extracting latest portage snapshot to ${CHROOT}/usr ..."
			tar jxf $(basename ${PORTAGE_SNAPSHOT}) -C "${CHROOT}/usr" || die "Extracting portage snapshot failed"
			rm -f portage-latest.tar.bz2
		fi
	fi
}


# setup_chroot CHROOT
setup_chroot() {

	# mount pseudo filesystems
	mount -t proc none ${CHROOT}/proc || die "Error mounting /proc"
	mount --rbind /dev ${CHROOT}/dev || die "Error mounting /dev"
	mount --rbind /sys ${CHROOT}/sys || die "Error mounting /sys"
}


# Actually prepare the install script running within chroot
# and run it
install_gentoo() {

	if [ ${INTERACTIVE} = 1 ]; then
		echo "Done. Entering chroot environment. All yours..."
		chroot ${CHROOT} /bin/bash
	else
		# resolve.conf
		echo "Copy resolv.conf from host"
		cp -L /etc/resolv.conf ${CHROOT}/etc/resolv.conf || die "Can't copy resolv.conf"

		# Install make.conf
		if [ "x${MAKE_CONF}" != "x" ]; then
			[ -r ${MAKE_CONF} ] || die "Cannot read ${MAKE_CONF}"

			echo "Using custom make.conf"
			cp ${MAKE_CONF} ${CHROOT}/etc/portage/ 
		fi

		# From here we create the install script and execute it within the chroot at the end
		cat << 'EOF' > ${CHROOT}/tmp/install.sh
#!/bin/bash
set -x

source /etc/profile
export PS1="(chroot) $PS1"
EOF
		# Sync portage if not mounted
		if [ ${_PORTAGE_MOUNTED} = 0 ]; then
		cat << 'EOF' >> ${CHROOT}/tmp/install.sh
echo "Syncing portage snapshot..."
emerge -p --sync --quiet
EOF
		fi

		# eselect profile
		cat << EOF >> ${CHROOT}/tmp/install.sh
echo "Setting profile to ${ESELECT_PROFILE}"
eselect profile set ${ESELECT_PROFILE}
EOF

	# Set Timezone

	# Configure locales

	# Compile own kernel later
	# boot + kernel + lib/modules

	# /etc/fstab
		chmod 755 ${CHROOT}/tmp/install.sh
		chroot ${CHROOT} /tmp/install.sh

		echo "Done !"
		echo "Press <Return> to tear down the chroot environment once you are done."
		read -r REPLY

	fi
}


# Clean up host
cleanup() {
	umount ${CHROOT}/dev/pts ${CHROOT}/dev ${CHROOT}/sys ${CHROOT}/proc
	
	if [ ${_PORTAGE_MOUNTED} != 0 ]; then
		umount ${CHROOT}/usr/portage
	else
		rm -rf ${CHROOT}/usr/portage/distfiles/*
	fi

	# Clean up chroot
	rm -rf ${CHROOT}/tmp/*
	rm -rf ${CHROOT}/var/tmp/*
}


# print usage
usage() {
cat << EOF
Usage: $0 [options]

This script builds a full Gentoo chroot

OPTIONS:
-h Show this message
-a arch, either i686 or x86_64, defaults to uname -m
-p profile, [ hardened | hardened-no-multilib | default *]
-t The timezone to use, default to GMT
-r chroot location (default $CHROOT )
-c local cache (default $LOCAL_CACHE)
-b bind mount portage tree from, instead of downloading portage snapshot
-i interactive, enter chroot only, do NOT run install script
-m use custom make.conf
-d debug (set -x)
EOF
}


DEBUG=0
INTERACTIVE=0
MAKE_CONF=""
BIND_PORTAGE=""
while getopts ":a:p:t:r:c:m:b:dhi" OPTIONS; do
	case $OPTIONS in
		a ) ARCH=$OPTARG;;
		p ) PROFILE=$OPTARG;;
		t ) TIMEZONE=$OPTARG;;
		d ) DEBUG=1;;
		b ) BIND_PORTAGE=$OPTARG;;
		r ) CHROOT=$OPTARG;;
		c ) LOCAL_CACHE=$OPTARG;;
		i ) INTERACTIVE=1;;
		m ) MAKE_CONF=$OPTARG;;
		? )
			usage
			exit
			;;
	esac
done

# Do some sanity checks first
if [ "$(id -u)" != "0" ]; then
	die "Sorry, but we need root permissions to create DEVICE nodes etc.!"
fi

ARCH=${ARCH-"$(uname -m)"}
PROFILE=${PROFILE="default"}
TIMEZONE=${TIMEZONE-"GMT"}

if [ "${ARCH}" = "i686" ] ; then
	# Why do they use x86 here ? :(
	STAGE_PATH="${GENTOO_MIRROR}/releases/x86/autobuilds"
elif [ "${ARCH}" = "x86_64" ] ; then
	ARCH="amd64"
	STAGE_PATH="${GENTOO_MIRROR}/releases/${ARCH}/autobuilds"
elif [ "${ARCH}" = "amd64" ] ; then
	STAGE_PATH="${GENTOO_MIRROR}/releases/${ARCH}/autobuilds"
else
	die "Unknown architecture!"
fi

if [ "${PROFILE}" = "hardened" ] ; then
	LATEST_STAGE_FILE="${STAGE_PATH}/latest-stage3-${ARCH}-hardened.txt"
	ESELECT_PROFILE="hardened/linux/${ARCH}"
elif [ "${PROFILE}" = "hardened-no-multilib" ] ; then
	LATEST_STAGE_FILE="${STAGE_PATH}/latest-stage3-${ARCH}-hardened+nomultilib.txt"
	ESELECT_PROFILE="hardened/linux/${ARCH}/no-multilib"
elif [ "${PROFILE}" = "default" ] ; then
	LATEST_STAGE_FILE="${STAGE_PATH}/latest-stage3-${ARCH}.txt"
	ESELECT_PROFILE="default/linux/${ARCH}/13.0"
else
	die "Unknown profile!"
fi

if [ ${DEBUG} -eq 1 ]; then
	set -x
fi

bootstrap 

# From here make sure we don't leave stuff around on the host
trap "cleanup" INT TERM EXIT

setup_chroot

install_gentoo
