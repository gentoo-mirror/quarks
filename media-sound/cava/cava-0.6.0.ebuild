# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit linux-info

DESCRIPTION="Console-based Audio Visualizer for ALSA (=CAVA)"
HOMEPAGE="https://github.com/karlstav/cava"
SRC_URI="https://github.com/karlstav/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="sci-libs/fftw:3.0
	dev-libs/iniparser:0"
RDEPEND="${DEPEND}"

CONFIG_CHECK=(
	SND_ALOOP
)

src_prepare() {
	rm -R iniparser/src || die

	eapply_user

	./autogen.sh || die
}

src_configure() {
	econf --enable-legacy_iniparser
}
