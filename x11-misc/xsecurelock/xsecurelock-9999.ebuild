# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit autotools autotools-utils

if [[ ${PV} = 9999 ]]; then
	inherit git-2
fi

DESCRIPTION="X11 screen lock utility with security in mind"
HOMEPAGE="https://github.com/google/xsecurelock"
if [[ ${PV} = 9999 ]]; then
	EGIT_REPO_URI="https://github.com/google/${PN}"
	EGIT_BOOTSTRAP=""
	KEYWORDS=""
else
	SRC_URI="https://github.com/google/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

SLOT="0"
LICENSE="Apache"
RDEPEND="x11-libs/libX11
	x11-libs/libXScrnSaver"
DEPEND="${RDEPEND}
	"

src_prepare() {
	eautoreconf
}


src_configure() {
	local myeconfargs=(
			--with-pam-service-name=system-auth
			--prefix=/usr
	)
	autotools-utils_src_configure
}


src_compile() {
	autotools-utils_src_compile
}


src_install() {
	autotools-utils_src_install
}
