#!/bin/bash
#This script expects to be run from the spamgourmet-clone main directory
echo '========================= spamgourmet server installation start'
source sg-server-config.sh

cd $SCRIPT_BASE_DIR

function exim4_packages {
	echo '##########################################################################'
	echo '### install mandatory packages'
	echo '##########################################################################'
	apt-get update; apt-get upgrade -y; apt-get autoremove
	apt-get install -y exim unzip make gcc bash-completion ca-certificates wget
}


function exim4_setup {
	echo '##########################################################################'
	echo '### configure exim4'
	echo '##########################################################################'
	# need fix to work if has multiple IP addresses
	# also do not know if this will work on ipv6-only servers
	IPADDRESS=`ip -4 route get 8.8.8.8 | head -1 | awk '{print $7}'`

	sed -i "s/dc_eximconfig_configtype=.*$/dc_eximconfig_configtype='internet'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_other_hostnames=.*$/dc_other_hostnames='$DOMAIN'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_local_interfaces=.*$/dc_local_interfaces='$IPADDRESS'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_readhost=.*$/dc_readhost=''/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_relay_domains=.*$/dc_relay_domains='ob."$DOMAIN"'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_minimaldns=.*$/dc_minimaldns='false'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_relay_nets=.*$/dc_relay_nets=''/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_smarthost=.*$/dc_smarthost=''/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/CFILEMODE=.*$/CFILEMODE='644'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_use_split_config=.*$/dc_use_split_config='true'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_hide_mailname=.*$/dc_hide_mailname=''/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_mailname_in_oh=.*$/dc_mailname_in_oh='true'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_localdelivery=.*$/dc_localdelivery='mail_spool'/" /etc/exim4/update-exim4.conf.conf
	echo $DOMAIN >/etc/mailname
	update-exim4.conf
}

function configure_exim_tls {
	echo '##########################################################################'
	echo '### configure exim for TLS because certificate exists'
	echo '##########################################################################'
	cat <<-EOF >/etc/exim4/conf.d/main/00_exim4-config_myvalues
	MAIN_TLS_ENABLE = yes
	# renaming the certs to names used by default by exim4
	# so no other change to exim4 config
EOF
	service exim4 restart
}

exim4_packages
exim4_setup
configure_exim_tls
