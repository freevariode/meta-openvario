# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)
# SRC_URI = "git://github.com/Scumi/XCSoar.git;protocol=https;branch=improvement_OpenVarioMenu \"
# SRC_URI = "git://github.com/FreeVariode/XCSoar.git;protocol=https;branch=FreeVario \"

PR = "r13"
RCONFLICTS:${PN}="xcsoar"

SRCREV:pn-xcsoar-testing = "${AUTOREV}" 

SRC_URI = "git://github.com/Blaubart/XCSoar.git;protocol=https;branch=opensoar\
	file://ovmenu-x.service \
"

inherit systemd

require xcsoar.inc

PACKAGES += "ovmenu-x"
RDEPENDS:ovmenu-x += " \
	${PN} \
	autofs-config \
"
SYSTEMD_PACKAGES = "ovmenu-x"
SYSTEMD_SERVICE:ovmenu-x = "ovmenu-x.service"

do_compile:append() {
	oe_runmake output/UNIX/bin/OpenVarioMenu
}

do_install:append() {
	install -m755 ${S}/output/UNIX/bin/OpenVarioMenu ${D}${bindir}

	install -d ${D}${systemd_unitdir}/system
	install -m644 ${WORKDIR}/ovmenu-x.service ${D}${systemd_unitdir}/system
}

FILES:ovmenu-x += "${bindir}/OpenVarioMenu"
