EAPI=4
inherit eutils

DESCRIPTION="Partition cloning tool"
HOMEPAGE="http://partclone.org"
SRC_URI="http://sourceforge.net/projects/partclone/files/stable/${PV}/partclone_${PV}.orig.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="xfs reiserfs reiser4 hfs fat ntfs jfs static"

RDEPEND="${common_depends}
	sys-fs/e2fsprogs
	fat? ( sys-fs/dosfstools )
	ntfs? ( sys-fs/ntfs3g )
	hfs? ( sys-fs/hfsutils )
	jfs? ( sys-fs/jfsutils )
	reiserfs? ( sys-fs/progsreiserfs )
	reiser4? ( sys-fs/reiser4progs )
	xfs? ( sys-fs/xfsprogs )
	static? ( sys-fs/e2fsprogs[static-libs(+)]
		      sys-fs/xfsprogs[static-libs(+)]
		      sys-libs/ncurses[static-libs(+)]
		      sys-fs/ntfs3g[static-libs(+)]
		   )"
DEPEND=""

src_unpack()
{
	unpack ${A}
	#mv partclone partclone-${PV}
	cd ${S}
}

src_compile() 
{
	local myconf
	myconf="${myconf} --enable-extfs --enable-ncursesw"
	use xfs && myconf="${myconf} --enable-xfs"
	use reiserfs && myconf="${myconf} --enable-reiserfs"
	use reiser4 && myconf="${myconf} --enable-reiser4"
	use hfs && myconf="${myconf} --enable-hfsp"
	use fat && myconf="${myconf} --enable-fat"
	use ntfs && myconf="${myconf} --enable-ntfs"
	use jfs && myconf="${myconf} --enable-jfs"
	use static && myconf="${myconf} --enable-static"

	econf ${myconf} || die "econf failed"
	emake || die "make failed"
}

src_install()
{
	#emake install || die "make install failed"
	#emake DIST_ROOT="${D}" install || die "make install failed"
	cd ${S}/src
	dosbin partclone.dd partclone.restore partclone.chkimg
	dosbin partclone.extfs
	use xfs && dosbin partclone.xfs
	use reiserfs && dosbin partclone.reiserfs
	use reiser4 && dosbin partclone.reiser4
	use hfs && dosbin partclone.hfsp
	use fat && dosbin partclone.fat
	use ntfs && dosbin partclone.ntfs
	use ntfs && dosbin partclone.ntfsfixboot
}
