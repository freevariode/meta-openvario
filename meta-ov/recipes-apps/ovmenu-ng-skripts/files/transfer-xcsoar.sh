#!/bin/sh
#
# transfer-xcsoar.sh
# System backup transfer script to and from usbstick for Openvario and XCSoar
#
# Created by lordfolken         2022-02-08
# Enhanced by 7lima & Blaubart  2022-06-19
#
# This backup and restore script stores all XCSoar settings and relevant
# Openvario settings like:
#
# -brightness of the display
# -rotation
# -touch screen calibration
# -language settings
# -dropbear settings
# -SSH, variod and sensord status
# 
# backups are stored at USB stick at:
# openvario/backup/<MAC address of eth0>/
# So you can store backups from more than one OV on the same stick!

echo ' [==========] Starting'
echo ' [#=========] Wait until "DONE !!" appears before you exit!'

# Provident background system buffer sync to help later syncs finish quicker
sync&

# Path where the USB stick is mounted
USB_PATH=/usb/usbstick

# XCSoar settings path
export XCSOAR_PATH=/home/root/.xcsoar

# XCSoar upload path
XCSOAR_UPLOAD_PATH=openvario/upload/xcsoar

# Backup path within the USB stick
BACKUP=openvario/backup

# MAC address of the Ethernet device eth0 to do a separate backup
MAC=`ip li|grep -A 1 eth0|tail -n 1|cut -d ' ' -f 6|sed -e s/:/-/g`

# Restore Shell Function: calls rsync with unified options. 
# Copies all files and dirs from source recursively. Parameters:
# $1 source
# $2 target
# $3 comment about type of items
restore() {
	if 
		# We use --checksum here due to cubieboards not having an rtc clock
		rsync --recursive --mkpath --checksum --quiet --progress "$1" "$2"
		test ${RSYNC_EXIT:=$?} -eq 0
	then
		echo " [####======] All $3 files have been restored."
	else 
		>&2 echo " An rsync error $RSYNC_EXIT has occurred!"
	fi
	# Provident system buffer sync to help later syncs finish quicker
	sync&
}

case `basename "$0"` in
backup-system.sh)
	echo ' [##========] System check ...'
	
	# Store SSH status 
	if   /bin/systemctl --quiet is-enabled dropbear.socket
	then	echo enabled
	elif /bin/systemctl --quiet is-active  dropbear.socket
	then	echo temporary
	else	echo disabled  
	fi > /home/root/ssh-status

	# Store variod and sensord status
	for DAEMON in variod sensord
	do
		if /bin/systemctl --quiet is-enabled $DAEMON
		then echo  enabled
		else echo disabled  
		fi > /home/root/$DAEMON-status
	done
	
	# Store if profiles are protected or not
	if [[ 'opkg list-installed | grep "e2fsprogs -"' == *"e2fsprogs"* ]]; 
	then
	PROFILE= find "$XCSOAR_PATH" -maxdepth 1 -type f -name '*.prf' -exec sh -c '
	for PROFILE; 
	do
		mkdir -p /home/root/profile-settings
		PROFILE_FILE=`basename "$PROFILE"`
		PROFILE_NAME=${PROFILE_FILE%.*}
		if lsattr "$PROFILE" | cut -b 5 | fgrep -q i; 
		then echo protected
		else echo unprotected
		fi > /home/root/profile-settings/$PROFILE_NAME 
	done
	' -- {} +
	fi

	# Copy brightness setting
	cat /sys/class/backlight/lcd/brightness > /home/root/brightness

	echo ' [####======] Starting backup ...'
	# Copy all directories and files from list below to backup directory recursively.
	# We use --checksum here due to cubieboards not having an rtc clock
	if 
		rsync --files-from - --archive --recursive --quiet \
		      --relative --mkpath --checksum --safe-links \
		      --progress \
			/ "$USB_PATH/$BACKUP/$MAC"/ <<-LISTE
				/etc/locale.conf
				/etc/udev/rules.d/libinput-ts.rules
				/etc/pointercal
				/etc/dropbear
				/home/root
				/opt/conf
				/var/lib/connman
				/boot/config.uEnv
			LISTE
		test ${RSYNC_EXIT:=$?} -eq 0
	then
		echo ' [######====] All files and settings have been backed up.'
	else 
		>&2 echo " An rsync error $RSYNC_EXIT has occurred!"
	fi;;
	
upload-xcsoar.sh)
	echo ' [##========] Starting upload of XCSoar files ...'
	# Call Shell Function defined above
	if 
		# We use --checksum here due to cubieboards not having an rtc clock
		rsync --recursive --mkpath --checksum --quiet --progress "$USB_PATH/$XCSOAR_UPLOAD_PATH"/ "$XCSOAR_PATH"
		test ${RSYNC_EXIT:=$?} -eq 0
	then
		echo " [####======] All XCSoar files have been uploaded."
	else 
		>&2 echo " An rsync error $RSYNC_EXIT has occurred!"
	fi
	# Provident system buffer sync to help later syncs finish quicker
	sync&;;
	
restore-xcsoar.sh)
	echo ' [##========] Starting restore of XCSoar ...'
	# Call Shell Function defined above
	restore "$USB_PATH/$BACKUP/$MAC/$XCSOAR_PATH"/ "$XCSOAR_PATH"/ XCSoar;;
	
restore-system.sh)
	echo ' [##========] Starting restore ...'

	# Eliminate /etc/opkg backup in case it's present
	rm -rf "$USB_PATH/$BACKUP/$MAC"/etc/opkg/

	# Call Shell Function defined above
	restore "$USB_PATH/$BACKUP/$MAC"/ / "Openvario and XCSoar"
	. /etc/locale.conf
	/bin/systemctl restart  --quiet --now ts_uinput

	# Restore SSH status 
	case `cat /home/root/ssh-status` in
	enabled)
		/bin/systemctl enable  --quiet --now dropbear.socket
		echo " [####======] SSH has been enabled permanently.";;
	temporary)
		/bin/systemctl disable --quiet --now dropbear.socket
		/bin/systemctl start   --quiet --now dropbear.socket
		echo " [####======] SSH has been enabled temporarily.";;
	disabled)
		/bin/systemctl disable --quiet --now dropbear.socket
		echo " [####======] SSH has been disabled.";;
	esac
	
	# Restore variod and sensord status 
	for DAEMON in variod sensord
	do
		case `cat /home/root/$DAEMON-status` in
		enabled)  /bin/systemctl  enable --quiet --now $DAEMON
		          echo " [#####=====] $DAEMON has been enabled.";;
		disabled) /bin/systemctl disable --quiet --now $DAEMON
		          echo " [#####=====] $DAEMON has been disabled.";;
		esac
	done

	# Restore protection for profiles if necessary
	if [[ 'opkg list-installed | grep "e2fsprogs -"' == *"e2fsprogs"* ]]; 
	then
		PROFILE= find "$XCSOAR_PATH" -maxdepth 1 -type f -name '*.prf' -exec sh -c '
		for PROFILE; 
		do
			PROFILE_FILE=`basename "$PROFILE"`
			PROFILE_NAME=${PROFILE_FILE%.*}
			case `cat /home/root/profile-settings/"$PROFILE_NAME"` in
			protected)   chattr +i "$XCSOAR_PATH"/"$PROFILE_NAME.prf"
		 	             echo " [######====] $PROFILE_NAME.prf has been protected.";;
			unprotected) echo " [######====] $PROFILE_NAME.prf is still unprotected.";;
			esac
		done
		' -- {} +
	else 
		PROFILE= find "$XCSOAR_PATH" -maxdepth 1 -type f -name '*.prf' -exec sh -c '
		for PROFILE; 
		do
			PROFILE_FILE=`basename "$PROFILE"`
			PROFILE_NAME=${PROFILE_FILE%.*}
			case `cat /home/root/profile-settings/"$PROFILE_NAME"` in
			protected)  echo " You try to protect $PROFILE_NAME.prf, but chattr is not installed!";;
			esac
		done
		' -- {} +
	fi

	# Restore brightness setting
	cat /home/root/brightness > /sys/class/backlight/lcd/brightness
	echo " [#######===] brightness setting has been restored."
	
	# Restore rotation setting
	grep "rotation" /boot/config.uEnv | cut -d '=' -f 2 | tr -d '"' > /sys/class/graphics/fbcon/rotate
	echo " [########==] rotation setting has been restored.";;
*)
	>&2 echo 'call as backup-system.sh, upload-xcsoar.sh, restore-xcsoar.sh or restore-system.sh'
	exit 1;;
esac

# Sync the system buffer to make sure all data is on disk
echo ' [#########=] Please wait a moment, synchronization is not yet complete!'
sync
echo ' [##########] DONE !! ---------------------------------------------------'
exit $RSYNC_EXIT
