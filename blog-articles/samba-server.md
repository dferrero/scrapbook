Title: Samba Server
Date: 2017-08-01 19:06
Modified: 2017-08-21 15:25
Slugs: samba-server
Authors: Dave F
Tags: samba, script 

Samba server
============

# Installation

`sudo apt-get install samba samba-common-bin`

# Configuration

Make a copy without comments from the original `smb.conf` file:

```
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
sudo grep -ve ^# -ve '^;' -ve ^$ smb.conf.bak > /etc/samba/smb.conf
```

Parameters:

```
workgroup = WORKGROUP

[data] 
    comment = Data share 
    path = /data 
    browseable = yes 
    read only = no 
    writeable = yes 
    only guest = no 
```

Add user for remote access:

`sudo smbpasswd -a <username>`

# Notes
* Establishing connection from Windows needs **group name** given between `[` and `]`. Don't use the folder path specified under `path` option.
* Use mask options or `read only/writeable`. **Not both**

# Script

```
#!/bin/bash

################################
# Samba
# Version 0.0 - W.I.P
# Author: @dferrero
################################

IDENTIFIER="[SAMB]"
MSGLOG="samba-server.log"

path=""

debug=false
log=false

# === Functions ===

function display_help(){
	echo "$0 - Samba installation and configuration script"
	echo "Usage: $0 [options]"
	echo " "
	echo "options:"
	echo "-h, --help		show brief help"
	echo "-p, --path		set path for samba folder"

	echo "-D 			enable debug mode"
	echo "-l 			enable log storage"
	exit 0
}

function msg(){
	if $debug ; then echo "$IDENTIFIER $1" fi
	if $log ; then echo "$IDENTIFIER $1" >> $MSGLOG fi
}


# === Samba script ===

# 0- Processing parameters
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		display_help
		;;
	-p|--path)
		shift
		path=$1
		shift
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

# 0- Checking privileges
if [ "$EUID" -ne 0 ]; then
	err "This script needs root privileges. Exiting..."
	exit 1
fi
msg "Checking permissions -> OK"

# 1- Checking installed packages
installed=`dpkg -s samba | grep Status | grep install | wc -l`
if [[ installed -eq 0 ]]; then
	apt-get install samba samba-common-bin
fi

# 2- Creating clean config file
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
grep -ve ^# -ve '^;' -ve ^$ /etc/samba/smb.conf.bak > /etc/samba/smb.conf

# 3- Configuring new Samba group
name=""
comment=""
path=""
browseable=True
readonly=False
writeable=True
onlyguest=False

valid=False
while [ ! $valid ]; do
	echo "Enter a name to identify new Samba group: "
	read name
	check=`cat /etc/samba/smb.conf | grep "\[$name\]" | wc -l`
	if [[ $name -eq "" ]]; then
		msg "[ERROR] Name cannot be empty"
	elif [[ $check -eq 1 ]]; then
		msg "[ERROR] Name is already in use by another Samba group. Please choose a differente one"
	else
		valid=True
	fi
done

echo "Enter a comment for this group: "
read comment

valid=False
while [ ! $valid ]; do
	echo "Enter a folder path for this group: "
	read path
	if [[ $path -eq "" ]]; then
		msg "[ERROR] Folder path cannot be empty. Please type a valid one."
	elif [ ! -d "$path" ]; then
		msg "[ERROR] Folder path doesn't exist. Please type a valid one".
	else
		valid=True
	fi
done

echo "Do you want your group to be browseable? [Y/n]"
read opt
if [ "$opt" -eq Y ] || [ "$opt" -eq y ]; then
	broweable=True
elif [ "$opt" -eq N ] || [ "$opt" -eq n ]; then
	browseable=False
else
	msg "[WARN] Invalid option for browseable -> Setting value as default value"
	browseable=True
fi

echo "Do you want your group to be read-only? [y/N]"
read opt
if [ "$opt" -eq Y ] || [ "$opt" -eq y ]; then
	readonly=True
elif [ "$opt" -eq N ] || [ "$opt" -eq n ]; then
	readonly=False
else
	msg "[WARN] Invalid option for browseable -> Setting value as default value"
	readonly=False
fi

echo "Do you want your group to be writeable? [Y/n]"
read opt
if [ "$opt" -eq Y ] || [ "$opt" -eq y ]; then
	writeable=True
elif [ "$opt" -eq N ] || [ "$opt" -eq n ]; then
	writeable=False
else
	msg "[WARN] Invalid option for browseable -> Setting value as default value"
	writeable=True
fi

echo "Do you want your group to allow guest users? [y/N]"
read opt
if [ "$opt" -eq Y ] || [ "$opt" -eq y ]; then
	onlyguest=True
elif [ "$opt" -eq N ] || [ "$opt" -eq n ]; then
	onlyguest=False
else
	msg "[WARN] Invalid option for browseable -> Setting value as default value"
	onlyguest=False
fi

# 4- Preview configuration and confirm it
echo ""
echo "The configuration will be:"
echo ""
echo "[$name]"

if [ $comment -ne "" ]; then
	echo -e "\tcomment = $comment"
fi

echo -e "\tpath = $path"

if [ $browseable ]; then
	echo -e "\tbrowseable = yes"
else
	echo -e "\tbrowseable = no"
fi

if [ $readonly ]; then
	echo -e "\tread only = yes"
else 
	echo -e "\tread only = no"
fi

if [ $writeable ]; then 
	echo -e "\twriteable = yes"
else
	echo -e "\twriteable = no"
fi

if [ $onlyguest ]; then
	echo -e "\tonly guest = yes"
else
	echo -e "\tonly guest = no"
fi

echo ""
echo "Is it correct? [y/N]: "
read opt
if [ ! "$opt" -eq Y ] && [ ! "$opt" -eq y]; then
	msg "Exiting..."
	exit 1
fi

# 5- Writing configuration to file

```
