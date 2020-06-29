# Copyright 2020 
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PN_NB="${PN//-bin/}"
P_NB="${PN_NB}-${PV}"

DESCRIPTION="Universal markup converter"
HOMEPAGE=(
	"https://pandoc.org"
	"https://github.com/jgm/pandoc"
)
LICENSE="GPL-2"

SLOT="0"
SRC_URI=(
	"https://github.com/jgm/${PN_NB}/releases/download/${PV}/${P_NB}-linux-amd64.tar.gz"
)

KEYWORDS="-* amd64"
IUSE=( citeproc )

RDEPEND=( 
	"dev-libs/gmp:*"
	"sys-libs/zlib:*"

	"!app-text/${PN_NB}"
	"citeproc? ( !dev-haskell/${PN_NB}-citeproc )"
)

RESTRICT+=" primaryuri"

S="${WORKDIR}/${P_NB}"

src_unpack()
{
	default

	# docs/manpages are gzipped
	find . -name "*.gz" | xargs gunzip
	assert
}

src_install()
{
	cd "${S}/bin" || die
	dobin "${PN_NB}"
	use citeproc && dobin "${PN_NB}-citeproc"

	cd "${S}/share/man/man1" || die
	doman "${PN_NB}.1"
	use citeproc && doman "${PN_NB}-citeproc.1"
}

QA_PRESTRIPPED="usr/bin/.*"
