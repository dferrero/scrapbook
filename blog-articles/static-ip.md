Title: Static IP on *NIX
Date: 2017-08-02 15:22
Slugs: static-ip
Authors: Dave F
Tags: ip, script 

Static IP
=========

# IP configuration file

## /etc/dhcpcd.conf

```
static
interface eth0
	static ip_address=192.168.1.50/24
	static routers=192.168.1.1
	static domain_name_servers=8.8.8.8
```

## /etc/network/interfaces

```
iface eth0 inet static 
	address 192.168.1.50 
	network 192.168.1.0 
	broadcast 192.168.1.255 
	netmask 255.255.255.0
```

# Script

```
#!/bin/bash

################################
# Static IP
# Version 0.1
# Author: @dferrero
################################

IDENTIFIER="[ IP ]"
MSGLOG="static-ip.log"

interface="eth0"
conffile="/etc/dhcpcd.conf"

ip=""
mask=24
router=""
dns="8.8.8.8"
debug=false
log=false

# === Functions ===

function display_help(){
	echo "$0 - Script to set static ip on Raspberry Pi using dhcpcd"
	echo "Usage: $0 -i <ip> [options]"
	echo " "
	echo "options:"
	echo "-h, --help		show brief help"
	echo "-m <mask>			set ip mask (default 24)"
	echo "-r <router>		set router (default like ip ended in 1)"
	echo "-d <dns>			set dns (default 8.8.8.8)"
	echo "				if it's used more than one, use quotation marks"
	echo "-c			set configuration file path"
	echo "-I <interface>		interface to set static ip (default eth0)"
	echo "-D 			enable debug mode"
	echo "-l 			enable log storage"
	exit 0
}

function check_ip_syntax(){
	local l_ip=$1
	local checked=1

	if [[ $l_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OldIFS=$IFS
		IFS='.'
		l_ip=($l_ip)
		IFS=$OldIFS
		[[ ${l_ip[0]} -le 255 && ${l_ip[1]} -le 255 && ${l_ip[2]} -le 255 && ${l_ip[3]} -le 255 ]]
		checked=$?
	fi
	return $checked
}

function check_local_address(){
	# WIP
	local l_ip=$1
	local valid=1

	OldIFS=$IFS
	IFS='.'
	l_ip=($l_ip)
	IFS=$OldIFS
	classA=${l_ip[0]}
	classB=${l_ip[1]}
	case "$classA" in
	10)
		break
		;;
	172)
		if [[ "$classB" -lt 16 || "$classB" -gt 31 ]]; then valid=0 fi
		break
		;;
	192)
		if [[ "$classB" -ne 168 ]]; then valid=0 fi
		break
		;;
	169)
		if [[ "$classB" -ne 254 ]]; then valid=0 fi
		break
		;;
	*)
		valid=0
		break
		;;
	esac

	return $valid
}

function msg(){
	if $debug ; then echo "$IDENTIFIER $1" fi
	if $log ; then echo "$IDENTIFIER $1" >> $MSGLOG fi
}


# === Static IP script ===

# 0- Processing parameters
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		display_help
		;;
	-i)
		shift
		ip=$1
		is_ip_ok=check_ip_syntax $ip
		if [[ ! $is_ip_ok ]]; then
			msg "[ERROR] Invalid IP address. Exiting..."
			exit 1
		fi
		is_local_address=check_local_address $ip
		if [[ ! $is_local_address ]]; then
			msg "[ERROR] IP is not a local address. Exiting..."
			exit 1
		fi
		msg "Checked IP syntax -> OK"
		;;
	-m)
		shift
		mask=$1
		if [[ $mask -lt 8 || $mask -gt 32 ]]; then
			msg "[ERROR] Invalid mask. It should be a number between 8 and 32"
			exit 1
		fi
		msg "Checked mask value -> OK"
		;;
	-r)
		shift
		if [[ $ip -eq "" ]]; then
			msg "[ERROR] IP must be first argument of the script. Exiting..."
			exit 1
		fi
		router=$1
		is_router_ok=check_ip_syntax $router
		if [[ ! $is_router_ok ]]; then
			msg "[ERROR] Invalid router address. Exiting..."
			exit 1
		fi
		shift
		;;
	-d)
		shift
		dns=$1
		is_dns_ok=check_ip_syntax $dns
		if [[ ! $is_dns_ok ]]; then
			msg "[ERROR] Invalid DNS address. Exiting..."
			exit 1
		fi
		;;
	-c)
		shift
		conffile=$1
		if [[ ! -f $conffile ]]; then
			msg "[ERROR] File $conffile does not exists. Exiting..."
			exit 1
		fi
		;;
	-I)
		shift
		interface=$1
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

# 1- Checking privileges
if [ "$EUID" -ne 0 ]; then
	msg "[ERROR] This script needs root privileges. Exiting..."
	exit 1
fi
msg "Checking permissions -> OK"

# 2- Checking number of parameters
if [[ "$#" -lt 2 ]]; then
	msg "[ERROR] Wrong number of parameters"
	display_help
fi
msg "Checking number of parameters -> OK"

# 3- Checking if dhcpcd exists
if [ ! -f $file ]; then
	msg "[ERROR] Configuration file not found. Exiting..."
	exit 1
fi
msg "Checking configuration file -> OK"

# 4- Checking if IP address is free
received=`ping -c 3 $ip | grep "bytes from $ip" | wc -l`
if [[ $received -ge 1 ]]; then
	msg "[ERROR] IP address $ip is on use. Exiting..."
	exit 1
fi
msg "Checking if IP address $ip is free -> OK"

# 5- Checking if interface exists
iface=`ls /sys/class/net | grep $interface | wc -l`
# What if we chose wlan0? Does it work?
if [[ $iface -eq 0 ]]; then
	msg "[ERROR] Interface not found. Exiting..."
	exit 1
fi
msg "Checking interface -> OK"
msg "* Setting static IP $ip on $conffile"

if [[ $router -eq "" ]]; then
	net=`echo $ip |cut -d'.' -f1-3`
	routers="$net.1"
fi

# 6- Setting IP address
echo "" >> $conffile
echo "# Static IP address" >> $conffile
echo "static" >> $conffile
echo "interface $interface" >> $conffile
echo "static ip_address=$ip/$mask" >> $conffile
echo "static routers=$routers" >> $conffile
echo "static domain_name_servers=$dns" >> $conffile

# 7- Restarting network services
msg "Restarting network services"
/etc/init.d/networking restart
```
