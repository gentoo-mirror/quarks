# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils

if [[ ${PV} = 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.linphone.org/BC/public/bctoolbox.git"
	SRC_URI=""
else
	SRC_URI="http://www.linphone.org/releases/sources/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="Utilities library used by Belledonne Communications softwares"
HOMEPAGE="https://savannah.nongnu.org/projects/linphone/"

SLOT="0"
LICENSE="GPL-2"
IUSE=""

DEPEND=">=dev-util/bcunit-3.0.2
	net-libs/mbedtls"
RDEPEND="${DEPEND}"

src_configure() {
	local mycmakeargs=(
		-DCMAKE_SKIP_INSTALL_RPATH=ON
		-DENABLE_STRICT=NO
		)
	cmake-utils_src_configure
}
