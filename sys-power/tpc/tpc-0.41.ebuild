# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

DESCRIPTION="TurionPowerControl is a command line tool that allows users to
tweak AMD processors parameters."
HOMEPAGE="http://amdath800.dyndns.org/amd/"
SRC_URI="http://amdath800.dyndns.org/amd/tpc/${P}.tar.gz"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}/src"

src_install () {
	dosbin TurionPowerControl
}
