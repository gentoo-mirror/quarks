# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils subversion

DESCRIPTION="GtkEveMon is a skill monitoring stand-alone application for GNU/Linux systems"
SRC_URI=""
# ESVN_REPO_URI="svn://svn.battleclinic.com/GTKEVEMon/trunk/gtkevemon/${PN%-svn}"
ESVN_REPO_URI="svn://svn.battleclinic.com/GTKEVEMon/trunk/gtkevemon"
ESVN_PROJECT="${PN%-svn}"
HOMEPAGE="http://gtkevemon.battleclinic.com"
KEYWORDS="~x86 ~amd64"
SLOT="0"
LICENSE="GPL-3"
IUSE=""

DEPEND=">=dev-cpp/gtkmm-2.12
	>=dev-libs/libxml2-2.6.27"
RDEPEND="${DEPEND}"

src_install() {
	exeinto /usr/bin
	newexe src/${PN%-svn} ${PN%-svn}
	newicon icon/${PN%-svn}.xpm ${PN%-svn}.xpm
	newmenu icon/${PN%-svn}.desktop ${PN%-svn}.desktop
}

