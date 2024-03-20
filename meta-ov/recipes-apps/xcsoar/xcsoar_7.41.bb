# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/freevariode/XCSoar.git;protocol=https;branch=FreeVario\
"

SRCREV = "8b9032b5fbaca16575e2ace4df372883d14db507"

require xcsoar.inc
