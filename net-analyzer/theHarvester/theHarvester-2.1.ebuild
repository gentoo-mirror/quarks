# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

SUPPORT_PYTHON_ABIS="1"

inherit eutils python

DESCRIPTION="The Harvester is a tool designed to collect email accounts of the target domain"
HOMEPAGE="http://www.edge-security.com/theHarvester.php"
# SRC_URI="http://theharvester.googlecode.com/files/${PN}-ng-${PV}.tar"
SRC_URI="http://theharvester.googlecode.com/files/theHarvester-2.1_BH2011_Arsenal.tar"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""
EAPI="3"

DEPEND=""
RDEPEND=""

RESTRICT_PYTHON_ABIS="3.*"

S="${WORKDIR}"/"${PN}-ng-blackhat"

src_prepare() {
    epatch "${FILESDIR}"/dns-names_path.patch

	python_convert_shebangs 2 theHarvester.py;
}

src_install() {
	installation() {
		insinto $(python_get_sitedir)/${PN}
		doins myparser.py
		exeinto $(python_get_sitedir)/${PN}
		doexe theHarvester.py
		insinto $(python_get_sitedir)/${PN}/discovery
		doins discovery/*.py
		insinto $(python_get_sitedir)/${PN}/discovery/DNS
		doins discovery/DNS/*.py
		insinto $(python_get_sitedir)/${PN}/discovery/shodan
		doins discovery/shodan/*.py
		insinto $(python_get_sitedir)/${PN}/lib
		doins lib/*.py

        dosym $(python_get_sitedir)/${PN}/theHarvester.py /usr/bin/theHarvester.py
	}

    python_execute_function installation
    insinto /usr/share/"${PN}"
    doins dns-names.txt
    # doins discovery/nameservers.txt
}

pkg_postinst() {
	python_mod_optimize ${PN}/discovery ${PN}/discovery/DNS ${PN}/discovery/shodan ${PN}/lib ${PN}/theHarvester.py ${PN}/myparser.py
}

pkg_postrm() {
	python_mod_cleanup ${PN}/discovery ${PN}/discovery/DNS ${PN}/discovery/shodan ${PN}/lib ${PN}/theHarvester.py ${PN}/myparser.py
}
