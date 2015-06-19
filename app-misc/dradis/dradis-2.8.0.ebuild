# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils

DESCRIPTION="A framework for effective information sharing"
HOMEPAGE="http://dradisframework.org/"
SRC_URI="mirror://sourceforge/$PN/$PN-v$PV.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="mysql"

DEPEND="dev-ruby/sqlite3-ruby
		dev-ruby/rubygems
		dev-ruby/bundler
		mysql? ( dev-ruby/mysql-ruby )"

RDEPEND="${DEPEND}"

S="${WORKDIR}/${PN}-2.8"

src_compile() {
    # Inject missing jquery-rails-1.0.13.gem
	cp ${FILESDIR}/jquery-rails-1.0.13.gem server/vendor/cache

    export RAILS_ENV=production
    cd server
	bundle check > /dev/null || bundle install --local || die
}

src_install() {
	insinto /usr/lib/$PN
	doins -r server/* || die "install failed"
	dodoc readme.txt CHANGELOG
	dosbin "${FILESDIR}"/$PN
	newinitd "${FILESDIR}"/${PN}.initd $PN
	newconfd "${FILESDIR}"/${PN}.confd $PN
}

pkg_postinst() {
	einfo "Setting up sqlite database."
	cd /usr/lib/$PN/
    export RAILS_ENV=production
	echo y | bundle exec thor dradis:reset

	if use mysql; then
		einfo "If you want to use a MySQL database check the dradis\
		documentation: http://dradisframework.org/configure.html"
	fi
}
