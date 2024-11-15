# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Next generation minimal OpenVPN client"
HOMEPAGE="https://openvpn.net"
SRC_URI="https://github.com/OpenVPN/openvpn3/archive/refs/tags/release/$PV/openvpn3-$PV.tar.gz"

LICENSE="AGPL-3+"
SLOT="0"
IUSE="dco"

KEYWORDS="~amd64"

DEPEND="
	dev-libs/jsoncpp
	sys-libs/libcap
	app-arch/lz4
	dev-cpp/asio
	dev-libs/xxhash
	dco? (
		net-vpn/ovpn-dco:=
		>=dev-libs/protobuf-2.4.0:=
		>=dev-libs/libnl-3.2.29:=
	)"

RESTRICT="test"

S="$WORKDIR/openvpn3-release-$PV"

src_configure() {
	sed -i -e 's,add_subdirectory(test/unittests),,' CMakeLists.txt

	cmake -G Ninja -B build \
		-DBUILD_SHARED_LIBS=False
}

src_compile() {
	cmake --build build
}

src_install() {
	install -Dm755 build/test/ovpncli/ovpncli -t "$D"/usr/bin
	mkdir "$D"/usr/include
	mv openvpn "$D"/usr/include
}

