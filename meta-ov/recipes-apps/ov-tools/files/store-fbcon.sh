#!/bin/bash
# chkconfig: 2345 20 80
# description: Description comes here....

# Source function library.
. /etc/init.d/functions

start() {
    # code to start app comes here 
    # example: daemon program_name &
}

stop() {
	RotationValue=2
    "sed -ir 's/^[#]*\s*rotation=.*/rotationtt=$RotationValue/' /boot/config.uEnv"
}

case "$1" in 
    start)
       start
       ;;
    stop)
       stop
       ;;
    restart)
       stop
       start
       ;;
    status)
       # code to check status of app comes here 
       # example: status program_name
       ;;
    *)
       echo "Usage: $0 {start|stop|status|restart}"
esac

exit 0 