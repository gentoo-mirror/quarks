# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# based on pentoo.ch ebuilds - quark <it@startux.de>

EAPI="2"

inherit eutils
DESCRIPTION="Fierce is a DNS reconnaissance tool written in perl"
HOMEPAGE="http://ha.ckers.org/fierce/"
SRC_URI="http://ha.ckers.org/fierce/${PN}.pl
		http://ha.ckers.org/fierce/hosts.txt"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

RDEPEND="dev-perl/Net-DNS"

S="${WORKDIR}"/${PN}

src_unpack() {
	einfo "Nothing to unpack"
	mkdir "${S}"
	for x in $A
	do
		cp "${DISTDIR}"/"${x}" "${S}"
	done
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-path.patch
}

src_compile() {
	einfo "Nothing to compile"
}

src_install() {
	insinto /usr/share/"${PN}"
	doins hosts.txt
	dobin "${PN}".pl
}
