#!/bin/sh

# - builds a generic image from a stage3 tarball and portage snapshot
# - creates and uploads AMI 
# 
# based on work from JD Harrington https://github.com/psi/gentoo-aws
# and Matsuu Takuto https://gist.github.com/870789

#===============================================================================
GENTOO_MIRROR="http://gentoo.arcticnetwork.ca"
LOCAL_CACHE=/var/tmp
IMAGE_ROOT=/mnt/gentoo

# Import certain values from host config
_PORTDIR=$(. /etc/make.conf && echo $PORTDIR)
PORTDIR=${_PORTDIR:-/usr/portage}

set -o nounset

die() {
    echo $@
    exit 1
}


fetch_file() {
    local URL=$1
    local DIGEST=$2
    
    FILE_NAME=$(basename ${URL})
    MD5=$(curl -s -S ${DIGEST} | grep -o -E -e "^[0-9a-f]{32}\s*${FILE_NAME}$" | awk '{print $1}')

    if [ -z ${MD5} ]; then
        die "Unable to get checksum for ${FILE_NAME}, abort"
    fi

    # Do we have local copy
    if [ -f ${LOCAL_CACHE}/${FILE_NAME} ]; then
        # if we have local, correct copy use it
        if [ $(md5sum ${LOCAL_CACHE}/${FILE_NAME} | awk '{print $1}') = ${MD5} ]; then
            cp ${LOCAL_CACHE}/${FILE_NAME} .
            return 
        else
            echo "Invalid checksum for ${LOCAL_CACHE}/${FILE_NAME}, downloading new copy..."
        fi
    fi

    wget -nc ${URL} || die "Cannot download ${URL}!" 
    if [ $(md5sum ${FILE_NAME} | awk '{print $1}') != ${MD5} ]; then
        die "Invalid checksum for ${FILE_NAME}!"
    fi

    # Check if local cache is usable
    if [ -d ${LOCAL_CACHE} ] && [ -w ${LOCAL_CACHE} ]; then
        cp ${FILE_NAME} ${LOCAL_CACHE}
        echo "Stored ${FILE_NAME} in local cache."
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
    elif [ "${PROFILE}" = "server" ] ; then
        LATEST_STAGE_FILE="${STAGE_PATH}/latest-stage3-${STAGE_ARCH}.txt"
        ESELECT_PROFILE="default/linux/${ARCH}/10.0/no-multilib"
    else
        die "Unknown profile!"
    fi

    STAGE_TARBALL=${GENTOO_MIRROR}/releases/${STAGE_ARCH}/autobuilds/$(curl -s ${LATEST_STAGE_FILE} | grep -v "^#" | head -n 1) 

    [ -d ${ROOT_FS} ] || die "${ROOT_FS} does not exists"
    [ -w ${ROOT_FS} ] || die "${ROOT_FS} isn't writable"

    # install stage 3
    cd ${ROOT_FS}
    if [ -d "usr" ] ; then
        echo "There seems to be already files in ${ROOT_FS} !"
        echo "Press Ctrl+c to abort..."
	read
    fi
    fetch_file "${STAGE_TARBALL}" "${STAGE_TARBALL}.DIGESTS"
    tar jxpf $(basename ${STAGE_TARBALL}) || die "Extracting stage file failed"
    rm -f $(basename ${STAGE_TARBALL})
 
}


# setup_chroot ROOT_FS
setup_chroot() {
    local ROOT_FS=$1

    PORTAGE_SNAPSHOT="${GENTOO_MIRROR}/snapshots/portage-latest.tar.bz2"
    if [ ${BIND_PORTAGE} = 1 ]; then
        mkdir -p usr/portage
	mount --bind ${PORTDIR} ${ROOT_FS}/usr/portage || die "Error mounting ${PORTDIR}"
    else
        # install latest portage snapshot
        if [ ! -d "usr/portage" ] ; then
            fetch_file "${PORTAGE_SNAPSHOT}" "${PORTAGE_SNAPSHOT}.md5sum"
            tar jxf portage-latest.tar.bz2 -C "${ROOT_FS}/usr" || die "Extracting portage snapshot failed"
            rm -f portage-latest.tar.bz2
        fi
    fi

    # resolve.conf
    cp -L /etc/resolv.conf ${ROOT_FS}/etc/resolv.conf || die "Can't copy resolv.conf"

    # Remount pseudo filesystems
    mount --bind /dev ${ROOT_FS}/dev || die "Error mounting /dev"
    mount --bind /sys ${ROOT_FS}/sys || die "Error mounting /sys"
    mount --bind /proc ${ROOT_FS}/proc || die "Error mounting /proc"

    # Compile own kernel later
    # boot + kernel + lib/modules

    # make.conf
    # etc/portage/*

    echo "Done :D ... take a look around, any key to end"
    read
}


# Clean up host
cleanup() {
    local ROOT_FS=$1
    umount ${ROOT_FS}/dev ${ROOT_FS}/sys ${ROOT_FS}/proc
    
    if [ ${BIND_PORTAGE} = 1 ]; then
        umount ${ROOT_FS}/usr/portage
    fi
}


# print usage
usage() {
cat << EOF
Usage: $0 [options]

This script builds a generic gentoo stage3 image

OPTIONS:
-h Show this message
-a arch, either i686 or x86_64, defaults to uname -m
-p profile, either hardened or hardened-no-multilib or server(default)
-t The timezone to use, default to GMT
-r chroot location, default /mnt/gentoo
-c local cache, default /var/tmp
-b bind mount host portage tree instead of installing portage inside chroot 
-v Verbose
EOF
}


# Do some sanity checks first
if [ "$(id -u)" != "0" ]; then
    die "Sorry, but we need root permissions to create DEVICE nodes etc.!"
fi

VERBOSE=0
BIND_PORTAGE=0
while getopts ":a:p:t:r:c:bvh" OPTIONS; do
    case $OPTIONS in
        a ) ARCH=$OPTARG;;
        p ) PROFILE=$OPTARG;;
        t ) TIMEZONE=$OPTARG;;
        v ) VERBOSE=1;;
        b ) BIND_PORTAGE=1;;
        r ) IMAGE_ROOT=$OPTARG;;
        c ) LOCAL_CACHE=$OPTARG;;
        ? )
            usage
            exit
            ;;
    esac
done

ARCH=${ARCH-"$(uname -m)"}
PROFILE=${PROFILE="server"}
TIMEZONE=${TIMEZONE-"GMT"}

if [ ${VERBOSE} = 1 ]; then
    set -x
fi

bootstrap ${IMAGE_ROOT} ${PROFILE} ${ARCH}

# From here make sure we don't leave stuff around
trap "cleanup ${IMAGE_ROOT}" INT TERM EXIT

setup_chroot ${IMAGE_ROOT}
