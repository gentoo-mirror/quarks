#!/bin/sh

# - builds a generic image from a stage3 tarball and portage snapshot
# 
# based on work from JD Harrington https://github.com/psi/gentoo-aws
# and Matsuu Takuto https://gist.github.com/870789

#===============================================================================
GENTOO_MIRROR="http://distfiles.gentoo.org"
LOCAL_CACHE=/var/tmp
IMAGE_ROOT=/mnt/gentoo


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


# bootstrap ROOT_FS PROFILE ARCH
bootstrap() {
	local ROOT_FS=$1
	local PROFILE=$2
	local ARCH=$3

	local STAGE_PATH
	local STAGE_ARCH
	local LATEST_STAGE_FILE
	local ESELECT_PROFILE

	if [ "${ARCH}" = "i686" ] ; then
		STAGE_ARCH=${ARCH}
		# Why do they use x86 here ? :(
		STAGE_PATH="${GENTOO_MIRROR}/releases/x86/autobuilds"
	elif [ "${ARCH}" = "x86_64" ] ; then
		STAGE_ARCH="amd64"
		STAGE_PATH="${GENTOO_MIRROR}/releases/${STAGE_ARCH}/autobuilds"
	else
		die "Unknown architecture!"
	fi

	if [ "${PROFILE}" = "hardened" ] ; then
		LATEST_STAGE_FILE="${STAGE_PATH}/latest-stage3-${STAGE_ARCH}-hardened.txt"
		ESELECT_PROFILE="hardened/linux/${ARCH}"
	elif [ "${PROFILE}" = "hardened-no-multilib" ] ; then
		LATEST_STAGE_FILE="${STAGE_PATH}/latest-stage3-${STAGE_ARCH}-hardened+nomultilib.txt"
		ESELECT_PROFILE="hardened/linux/${ARCH}/no-multilib"
	elif [ "${PROFILE}" = "default" ] ; then
		LATEST_STAGE_FILE="${STAGE_PATH}/latest-stage3-${STAGE_ARCH}.txt"
		ESELECT_PROFILE="default/linux/${ARCH}/13.0"
	else
		die "Unknown profile!"
	fi

	[ -d ${ROOT_FS} ] || die "${ROOT_FS} does not exists"
	[ -w ${ROOT_FS} ] || die "${ROOT_FS} isn't writable"

	cd ${ROOT_FS}

	# first install stage 3
	if [ -d "usr" ] ; then
		echo "There seems to be already files in ${ROOT_FS} !"
		echo "Press <Ctrl+c> to abort, or <Return> to proceed without extracting stage3 ..."
		read -r REPLY
	else
		STAGE_TARBALL=${GENTOO_MIRROR}/releases/${STAGE_ARCH}/autobuilds/$(curl -s ${LATEST_STAGE_FILE} | grep -v "^#" | head -n 1) 

		fetch_file "${STAGE_TARBALL}" "${STAGE_TARBALL}.DIGESTS" || die "Cannot get ${STAGE_TARBALL}"

		echo "Extracting stage3 to ${ROOT_FS} ..."
		tar jxpf $(basename ${STAGE_TARBALL}) || die "Extracting stage3 failed"

		rm -f $(basename ${STAGE_TARBALL})
	fi

	# Portage snapshot
	PORTAGE_SNAPSHOT="${GENTOO_MIRROR}/releases/snapshots/current/portage-latest.tar.bz2"
	_PORTAGE_MOUNTED=0

	if [ "x${BIND_PORTAGE}" != "x" -a -d ${BIND_PORTAGE} ] ; then
		mkdir -p ${ROOT_FS}/usr/portage
		mount --bind ${BIND_PORTAGE} ${ROOT_FS}/usr/portage || die "Error mounting ${BIND_PORTAGE}"

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
			echo "Extracting latest portage snapshot to ${ROOT_FS}/usr ..."
			tar jxf $(basename ${PORTAGE_SNAPSHOT}) -C "${ROOT_FS}/usr" || die "Extracting portage snapshot failed"
			rm -f portage-latest.tar.bz2
		fi
	fi
}


# setup_chroot ROOT_FS
setup_chroot() {
	local ROOT_FS=$1

	# resolve.conf
	cp -L /etc/resolv.conf ${ROOT_FS}/etc/resolv.conf || die "Can't copy resolv.conf"

	# mount pseudo filesystems
	mount -t proc none ${ROOT_FS}/proc || die "Error mounting /proc"
	mount --rbind /dev ${ROOT_FS}/dev || die "Error mounting /dev"
	mount --rbind /sys ${ROOT_FS}/sys || die "Error mounting /sys"
}


# Actually prepare the install script running within chroot
# and run it
install_gentoo() {
	local ROOT_FS=$1

	if [ ${INTERACTIVE} = 1 ]; then
		echo "Done. Entering chroot environment. Good luck..."
		chroot ${ROOT_FS} /bin/bash
	else
	# Install make.conf

	# emerge --sync --quiet

	# eselect profile

	# Set Timezone

	# Configure locales

	# Compile own kernel later
	# boot + kernel + lib/modules

	# /etc/fstab
		echo "Done !"
		echo "Press <Return> to tear down the chroot environment once you are done."
		read -r REPLY

	fi
}


# Clean up host
cleanup() {
	local ROOT_FS=$1
	umount ${ROOT_FS}/dev/pts ${ROOT_FS}/dev ${ROOT_FS}/sys ${ROOT_FS}/proc
	
	if [ ${_PORTAGE_MOUNTED} != 0 ]; then
		umount ${ROOT_FS}/usr/portage
	else
		rm -rf ${ROOT_FS}/usr/portage/distfiles/*
	fi

	# Clean up chroot
	rm -rf ${ROOT_FS}/tmp/*
	rm -rf ${ROOT_FS}/var/tmp/*
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
-r chroot location (default $IMAGE_ROOT )
-c local cache (default $LOCAL_CACHE)
-b bind mount portage tree from, instead of downloading portage snapshot
-i interactive, enter chroot only, do NOT run install script
-m use custom make.conf
-d debug (set -x)
EOF
}


DEBUG=0
INTERACTIVE=0
MAKE_CONF="/etc/portage/make.conf"
BIND_PORTAGE=""
while getopts ":a:p:t:r:c:m:b:dhi" OPTIONS; do
	case $OPTIONS in
		a ) ARCH=$OPTARG;;
		p ) PROFILE=$OPTARG;;
		t ) TIMEZONE=$OPTARG;;
		d ) DEBUG=1;;
		b ) BIND_PORTAGE=$OPTARG;;
		r ) IMAGE_ROOT=$OPTARG;;
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

if [ ${DEBUG} -eq 1 ]; then
	set -x
fi

bootstrap ${IMAGE_ROOT} ${PROFILE} ${ARCH}

# From here make sure we don't leave stuff around on the host
trap "cleanup ${IMAGE_ROOT}" INT TERM EXIT

setup_chroot ${IMAGE_ROOT}
install_gentoo ${IMAGE_ROOT}
