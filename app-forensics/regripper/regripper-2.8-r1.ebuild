# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

inherit eutils

DESCRIPTION="Perl scripts to parse Windows registry files"
HOMEPAGE="http://regripper.wordpress.com/"
SRC_URI="https://github.com/warewolf/regripper/archive/refs/heads/master.zip -> regripper.zip"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="app-text/dos2unix"
RDEPEND="dev-perl/Parse-Win32Registry"

S="${WORKDIR}/RegRipper${PV}-master"


src_prepare() {
	rm -rf *.exe *.dll
}

src_compile() {
	dos2unix *.pl
	sed -i 's|c:\\perl\\bin\\perl.exe|/usr/bin/perl -w|g' rip.pl || die
}

src_install () {
	newbin rip.pl ${PN}

	insinto /usr/share/regripper
	doins plugins/*.pl
}
