#!/bin/bash
#This script expects to be run from the spamgourmet-clone main directory
echo '========================= spamgourmet server installation start'
source sg-server-config.sh

cd $SCRIPT_BASE_DIR

function mysql_packages {
	echo '##########################################################################'
	echo '### install mandatory packages'
	echo '##########################################################################'
	apt-get update; apt-get upgrade; apt-get autoremove
	apt-get install -y mariadb-server \
			unzip make gcc bash-completion ca-certificates wget
}


function mysql_setup {
	# ensure that mysqld is running, - what about init systems?
	# mysqld_safe --no-watch
	service mysql start


	echo '##########################################################################'
	echo '### configure mysql'
	echo '### this is a nasty hack - watch closely that it succeeds'
	echo '##########################################################################'

	mysql_secure_installation <<-EOF

	y
	$MARIADBROOTPWD
	$MARIADBROOTPWD
	y
	y
	y
	y
EOF

	mysqladmin -u root -p$MARIADBROOTPWD create sguser
	mysql -s -u root -p$MARIADBROOTPWD <<-EOF
	create database sg;
	grant all privileges on sg.* to sguser identified by "$MARIADBINTERACTIVEPWD" with grant option;
	flush privileges;
EOF
	# want to stop the MySQL service if we are building a docker container to ensure that no pending changes remain.
	service mysql stop
}


mysql_packages
mysql_setup
