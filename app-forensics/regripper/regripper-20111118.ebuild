# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /root/portage/net-analyzer/dnsenum/dnsenum-1.0.ebuild,v 1.1.1.1 2006/03/30 21:15:43 grimmlin Exp $

inherit eutils

EAPI=3

DESCRIPTION="Perl scripts to parse Windows registry files"
HOMEPAGE="http://regripper.wordpress.com/program-files/"
SRC_URI="http://winforensicaanalysis.googlecode.com/files/rr_tools.zip
         http://regripperplugins.googlecode.com/files/regripperplugins_${PV}.zip"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="app-text/dos2unix"
RDEPEND="perl-gcpan/Parse-Win32Registry"

S="${WORKDIR}/${P/_/}"


src_prepare() {
    rm -rf plugins *.exe rr.pl *.dll
}

src_compile() {
    dos2unix *.pl
    epatch "${FILESDIR}"/plugins_folder.patch

    sed -i 's|c:\\perl\\bin\\perl.exe|/usr/bin/perl -w|g' rip.pl || die
}

src_install () {
    newbin rip.pl ${PN}
    rm rip.pl

    insinto /usr/share/"${PN}"
    doins *.pl
}
