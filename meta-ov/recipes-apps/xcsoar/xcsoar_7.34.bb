# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/freevariode/XCSoar.git;protocol=https;branch=FreeVario\
"

SRCREV = "003288f569e7504e702d77976c40921405ab7415"

require xcsoar.inc
