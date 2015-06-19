# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit perl-module

MY_N="Ocsinventory-Unix-Agent"
MY_P="${MY_N}-${PV}"

DESCRIPTION="Powerful inventory and package deployment system"
HOMEPAGE="http://www.ocsinventory-ng.org/"
SRC_URI="http://launchpad.net/${MY_N,,}/stable-2.0/${PV}/+download/${MY_P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="logrotate ssl"

RDEPEND="
    perl-core/Digest-MD5
    dev-perl/XML-Simple
    dev-perl/LWP-UserAgent-Determined
    dev-perl/Net-IP
    dev-perl/Net-SSLeay
    virtual/perl-File-Temp
    logrotate? ( app-admin/logrotate )
    ssl? ( dev-perl/Crypt-SSLeay )
"

src_prepare() {
    # Workaround stupid sources
    mv "${WORKDIR}/${MY_P}" "${S}"
    cd "${S}"
    sed -i -e "s:PATH_TO_LOG_DIRECTORY:/var/log/${PN}:" \
	etc/logrotate.d/ocsinventory-agent

    #epatch "${FILESDIR}"/equery-invocation.patch
}

src_install() {
    mytargets=pure_install
    perl-module_src_install

    insinto /etc/ocsinventory-agent
    doins etc/ocsinventory-agent/modules.conf

    insinto /etc/cron.daily
    echo -e "#!/bin/sh
/usr/bin/ocsinventory-agent --logfile /var/log/${PN}/agent.log -s \`. /etc/default/ocsinventory-agent;echo \${SERVER}\`" \
	> "${D}/etc/cron.daily/${PN}"
    fperms 0755 /etc/cron.daily/${PN}

    insinto /etc/default
    doins etc/default/ocsinventory-agent

    keepdir /var/{lib,log}/${PN}
    if use logrotate ; then
	insinto /etc/logrotate.d
	doins etc/logrotate.d/ocsinventory-agent
    fi
}

check_opt_pkg() {
    if ! has_version $1; then
	missing_opt_pkg="${missing_opt_pkg}\t- $1: ${@:2}\n"
    fi
}

pkg_postinst() {
    missing_opt_pkg=""
    check_opt_pkg sys-apps/dmidecode "Read the BIOS stats"
    check_opt_pkg sys-apps/pciutils  "List PCI devices"
    check_opt_pkg net-analyzer/nmap  "Use the network discover feature"
    check_opt_pkg x11-misc/read-edid "Get the serial number of the screen"
    check_opt_pkg dev-perl/Net-CUPS  "Detect the printers"
    check_opt_pkg sys-apps/smartmontools ""

    if [[ -n $missing_opt_pkg ]]; then
	elog "Following packages gives additional functionalities"
	elog -n $missing_opt_pkg
    fi

    elog "A script has been installed in /etc/cron.daily/ for the OCS Inventory agent"
    elog "to run regularly."
}
