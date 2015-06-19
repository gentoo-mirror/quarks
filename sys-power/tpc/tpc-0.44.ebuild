# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

DESCRIPTION="TurionPowerControl is a command line tool that allows users to
tweak AMD processors parameters."
HOMEPAGE="https://code.google.com/p/turionpowercontrol/"
SRC_URI="https://turionpowercontrol.googlecode.com/files/${P}-rc2-src.tar.gz"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="sys-libs/ncurses"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${P}-rc2-src"

src_install () {
	dosbin TurionPowerControl
}
