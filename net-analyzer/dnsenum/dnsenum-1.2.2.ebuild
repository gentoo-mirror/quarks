# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

DESCRIPTION="A perl script to enumerate DNS from a server"
HOMEPAGE="http://code.google.com/p/dnsenum/"
SRC_URI="http://dnsenum.googlecode.com/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

DEPEND=""
RDEPEND="dev-perl/Net-Netmask
         dev-perl/XML-Writer"

S="${WORKDIR}/${P/-/}"

src_prepare() {
	sed -i 's|perl dnsenum.pl|dnsenum|g' dnsenum.pl || die
}

src_install () {
	dodoc README.txt
	newbin ${PN}.pl ${PN}

    insinto /usr/share/"${PN}"
    doins dns.txt
    doins dns-big.txt
}
