Title: USB Cheatsheet
Date: 2017-08-07 17:37
Modified: 2017-08-21 14:38
Slugs: usb-cheatsheet
Authors: Dave F
Tags: LVM, usb, cheatsheet, montaje automatico, recuperacion

# LVM

## Create new volume 

```
sudo su
apt-get install lvm2
vgcreate <volume_name> <path_fist_usb> <path_second_usb>
lvcreate -l 100%FREE <logic_name>
mkfs.ext4 # Format the volume
# The disk is created on /dev/<volume_name>/<logic_name>
mkdir /data 
mount /dev/data/lvol0 /data
```

## Add new USB to a volume

W.I.P. 

# Mount on boot

Mount the volume:

```
sudo mount /dev/sd?1 <path>
```

Find the UUID:

```
sudo blkid
```

Open `/etc/fstab` and add the follow line:

```
UUID="<volume-uuid>"	/mount/path	ntfs	defaults,noatime,auto	0	0 
```

# Format

## Windows

```
Windows + R -> cmd
diskpart
list disk
select disk X
clean
create partition primary
select partition 1
active
format fs=ntfs quick
assign
```

## Linux

```
sudo umount /dev/sdX
sudo mkdosfs -n 'Label' -I /dev/sdX	# FAT32
sudo mkfs.ext4 -n 'Label' -I /dev/sdX	# EXT4
```

# Scripts

```
#!/bin/bash

################################
# LVM
# Version 0.1
# Author: @dferrero
#
# === TO DO ===
# Choose which usb's will be used
# Parameters input
################################


IDENTIFIER="[LVM2]"
MSGLOG="usb.log"

vgname="vgdata"
lvname=""
mountpath="/data"

debug=false
log=false

function display_help(){
	echo "$0 - Script to build LVM unit from scratch"
	echo "Usage: $0 [options]"
	echo " "
	echo "options:"
	echo "-h, --help		show brief help"

	echo "-D			enable debug mode"
	echo "-l			enable log storage"
	exit 0
}

function msg(){
	if $debug ; then echo "$IDENTIFIER $1" fi
	if $log ; then echo "$IDENTIFIER $1" >> $MSGLOG fi
}

# === LVM script ===

# 0- Processing parameters
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		display_help
		;;
	-D)
		shift
		debug=true
		shift
		;;
	-l)
		shift
		log=true
		shift
		;;
	*)
		break
		;;
	esac
done

# 1- Checking privileges
if [ "$EUID" -ne 0 ]; then
	msg "$IDENTIFIER [ERROR] This script needs root privileges. Exiting..."
	exit
fi
msg "$IDENTIFIER Checking permissions... OK"

# 2- Check if LVM is installed
installed=`apt-cache policy lvm2 | grep Installed | grep none | wc -l`
if [[ $installed -eq 1 ]]; then
	msg "$IDENTIFIER Installing lvm2 on system"
	apt-get install -y lvm2
fi

# 3- Creating volume group
vgonsystem=`vgdisplay | grep "VG Name" | wc -l`
vgfound=`vgdisplay | grep $vgname | wc -l`
if [[ $vgdisplay -ne 0 ]]; then
	msg "$IDENTIFIER Found $vgonsystem virtual groups on system"
	if [[ $vgfound -eq 1 ]]; then
		msg "$IDENTIFIER [ERROR] Can't create vg with same name. Exiting..."
		exit
	fi
fi
msg "$IDENTIFIER Creating volume group $vgname... OK"

# Using all USB's plugged
vgusb=""
for elem in `fdisk -l |grep "/dev/sd" |grep -v Disk |cut -d' ' -f1`; do
	vgusb="$vgusb$elem "
done
vgcreate $vgname $vgusb
msg "$IDENTIFIER Creating volume group... OK"

# 4- Creating logical volume
lvonsystem=`lvdisplay | grep "LV Path" | wc -l`
lvfound=`lvdisplay | grep $vgname | wc -l`
if [[ $lvonsystem -ne 0 ]]; then
	msg "$IDENTIFIER Found $lvonsystem logical volumes on system"
	if [[ $lvfound -eq 1 ]]; then
		msg "$IDENTIFIER [ERROR] Already created logical volume for $vgname. Exiting..."
		exit
	fi
fi
lvcreate -l 100%FREE $vgname
msg "$IDENTIFIER Creating logical volume... OK"

# 5- Format volume
msg "$IDENTIFIER Formatting logical volume"
mkfs.ext4 /dev/$vgname/lvol0

# 6- Checking mount directory
if [[ ! -d $mountpath ]]; then
	mkdir $mountpath
	msg "$IDENTIFIER Creating directory $mountpath ... OK"
fi

# 7- Mounting on boot
msg "/dev/$vgname/lvol0 $mountpath ext4 defaults 0 0" >> /etc/fstab
msg "$IDENTIFIER Mounting on boot... OK"
```
