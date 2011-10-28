#!/bin/sh

# - builds a generic image from a stage3 tarball and portage snapshot
# - creates and uploads AMI 
# 
# based on work from JD Harrington https://github.com/psi/gentoo-aws
# and Matsuu Takuto https://gist.github.com/870789

#===============================================================================
GENTOO_MIRROR="http://gentoo.arcticnetwork.ca"

set -x

die() {
  echo $@
  exit 1
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
    PORTAGE_SNAPSHOT="${GENTOO_MIRROR}/snapshots/portage-latest.tar.bz2"

    [ -d ${ROOT_FS} ] || die "${ROOT_FS} does not exists"
    [ -w ${ROOT_FS} ] || die "${ROOT_FS} isn't writable"

    cd ${ROOT_FS}
    if [ ! -d "usr" ] ; then
        wget "${STAGE_TARBALL}" || die "Getting stage file from ${STAGE_TARBALL} failed"
        tar jxpf stage3*.bz2 || die "Extracting stage file failed"
    fi
    if [ ! -d "usr/portage" ] ; then
        wget "${PORTAGE_SNAPSHOT}" || die "Getting portage snapshot ${PORTAGE_SNAPSHOT} failed"
        tar jxf portage-latest.tar.bz2 -C "${ROOT_FS}/usr" || die "Extracting portage snapshot failed"
    fi
}


usage() {
cat << EOF
Usage: $0 [options]

This script builds a generic gentoo stage3 image

OPTIONS:
-h Show this message
-a arch, either i686 or x86_64, defaults to uname -m
-p profile, either hardened or hardened-no-multilib or server(default)
-t The timezone to use, default to GMT
-v Verbose
EOF
}

while getopts ":a:p:t:vh" OPTIONS; do
    case $OPTIONS in
        a ) ARCH=$OPTARG;;
        p ) PROFILE=$OPTARG;;
        t ) TIMEZONE=$OPTARG;;
        v ) VERBOSE=1;;
        ? )
            usage
            exit
            ;;
    esac
done

ARCH=${ARCH-"$(uname -m)"}
PROFILE=${PROFILE="server"}
TIMEZONE=${TIMEZONE-"GMT"}

bootstrap /mnt/gentoo ${PROFILE} ${ARCH}
