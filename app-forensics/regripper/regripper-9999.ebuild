# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit eutils

DESCRIPTION="Perl scripts to parse Windows registry files"
HOMEPAGE="https://regripper.wordpress.com/regripper/"

if [[ ${PV} = 9999 ]]; then
    EGIT_REPO_URI="https://github.com/keydet89/RegRipper2.8.git"
    inherit git-2
    KEYWORDS=""
else
    SRC_URI="https://regripper.googlecode.com/files/rrv${PV}.zip"
    KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE=""

DEPEND="app-text/dos2unix"
RDEPEND="dev-perl/Parse-Win32Registry"

S="${WORKDIR}/${P/_/}"


src_prepare() {
    rm *.exe rr.pl *.dll
}

src_compile() {
    if [[ ${PV} = 9999 ]]; then
        epatch "${FILESDIR}"/plugins_folder.patch
        dos2unix plugins/*.pl
    fi

    dos2unix *.pl

    sed -i 's|c:\\perl\\bin\\perl.exe|/usr/bin/perl -w|g' rip.pl || die
}

src_install () {
    newbin rip.pl ${PN}
    rm rip.pl

    if [[ ${PV} = 9999 ]]; then
        insinto /usr/share/"${PN}"
        doins -r plugins
    fi

    dodoc regripper.pdf
}
