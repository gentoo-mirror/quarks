# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

PYTHON_DEPEND="2:2.6"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.4"

inherit eutils

if [[ ${PV} == "9999" ]] ; then
    EGIT_REPO_URI="git://www.evefit.org/pyfa.git"
    inherit git 
    SRC_URI=""
else
    SRC_URI="http://dl.evefit.org/stable/${PN}-${PV}-stable-RC1-src.tar.bz2"
fi

DESCRIPTION="PyFa is a EVE Online fitting tool application for GNU/Linux systems"
HOMEPAGE="http://evefit.org/Pyfa"
KEYWORDS="~x86 ~amd64"
SLOT="0"
LICENSE="GPL-3"
IUSE=""

DEPEND="
	dev-python/sqlalchemy 
	dev-python/wxpython
	dev-python/matplotlib
	dev-python/numpy
	"
RDEPEND="${DEPEND}"
