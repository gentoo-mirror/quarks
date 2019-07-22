# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils

if [[ ${PV} = 9999 ]]; then
    inherit git-r3
    EGIT_REPO_URI="https://gitlab.linphone.org/BC/public/bzrtp.git"
	SRC_URI=""
else
	SRC_URI="http://www.linphone.org/releases/sources/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="Implementation of ZRTP keys exchange protocol"
HOMEPAGE="http://www.linphone.org"
LICENSE="GPL-2"
SLOT="0"
IUSE=""

DEPEND=">net-libs/bctoolbox-0.6.0
	dev-libs/libxml2:2
	dev-db/sqlite:3"
RDEPEND="${DEPEND}"

src_prepare() {
	eapply_user
	epatch "${FILESDIR}/cmake-fix.patch"

	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_SKIP_INSTALL_RPATH=ON
		-DENABLE_STRICT=NO
		)
	cmake-utils_src_configure
}


