# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/freevariode/XCSoar.git;protocol=https;branch=FreeVario\
"

SRCREV = "6a85b412395b15ea22e0035ffc9af393fff1b33c"

require xcsoar.inc
