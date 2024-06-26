DESCRIPTION = "XCSoar glide computer"
HOMEPAGE = "www.xcsoar.org"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=393a5ca445f6965873eca0259a17f833"
SECTION = "base/app"

DEPENDS = "	\
		curl \
		pkgconfig-native \
		libxslt-native \
		librsvg-native \
		imagemagick-native \
		libinput \
		lua \
		udev \
		ttf-dejavu \
		jpeg \
		freetype \
		libpng \
		glm \
		virtual/egl \
		virtual/mesa \
		virtual/libgles2 \
		alsa-lib \
		libsodium \
		c-ares \
		fmt \
		dbus \
"

RDEPENDS:${PN} = "\
        ttf-dejavu-sans-condensed \
        bash \
		dialog \
		rsync \
"

S = "${WORKDIR}/git"

LC_LOCALE_PATH = "${datadir}/locale"

SRC_URI += " \
	file://0007-Disable-touch-screen-auto-detection.patch \
	https://boostorg.jfrog.io/artifactory/main/release/1.84.0/source/boost_1_84_0.tar.bz2;sha256sum=cc4b893acf645c9d4b698e9a0f08ca8846aa5d6c68275c14c3e7949c24109454;unpack=0 \
	file://more_alternates.patch \
	file://update-maps.sh \
	file://update-system.sh \
	file://system-info.sh \
	file://download-igc.sh \
	file://transfer-xcsoar.sh \
	file://ov-calibrate-ts.sh \
"

inherit pkgconfig

addtask do_package_write_ipk after do_package

EXTRA_OEMAKE = " \
	HOSTCC='${BUILD_CC}' \
	HOSTCXX='${BUILD_CXX}' \
	AR='${AR}' \
	RANLIB='${RANLIB}' \
	CXX='${CXX}' \
	CC='${CC}' \
	AS='${AS}' \
	LD='${LD}' \
	STRIP='${STRIP}' \
	CCACHE='' \
	\
	DEBUG=n DEBUG_GLIBCXX=n \
	ENABLE_MESA_KMS=y GLES2=y \
	GEOTIFF=n \
"

do_configure() {
	install -d ${B}/output/download
	cp ${WORKDIR}/boost_1_84_0.tar.bz2 ${B}/output/download/
	oe_runmake boost
}

do_compile() {
	export PATH=$PATH:/usr/bin
	ln -sf convert.im7 ${STAGING_DIR_NATIVE}/usr/bin/convert
	export FONTCONFIG_PATH=/etc/fonts
	oe_runmake
}

do_install() {
	oe_runmake install-bin install-mo DESTDIR=${D}
		install -m 0755 \
		${WORKDIR}/update-maps.sh \
		${WORKDIR}/update-system.sh \
		${WORKDIR}/system-info.sh \
		${WORKDIR}/download-igc.sh \
		${WORKDIR}/transfer-xcsoar.sh \
		${WORKDIR}/ov-calibrate-ts.sh \
		${D}${bindir}/
	cd ${D}${bindir}
	ln -s -r transfer-xcsoar.sh restore-system.sh
	ln -s -r transfer-xcsoar.sh restore-xcsoar.sh
	ln -s -r transfer-xcsoar.sh backup-system.sh
	ln -s -r transfer-xcsoar.sh upload-xcsoar.sh
}

FILES:${PN} = " \
	${bindir}/xcsoar \
	${bindir}/vali-xcs \
	${LC_LOCALE_PATH}/*/LC_MESSAGES/opensoar.mo \
	${bindir}/*.sh \
	${bindir}/OpenSoar \
"