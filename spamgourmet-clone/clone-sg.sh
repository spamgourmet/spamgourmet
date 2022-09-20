#!/bin/bash
echo '##########################################################################'
echo '### Start Setup of Spamgourmet Clone'
echo '##########################################################################'

export SCRIPT_BASE_DIR=$(dirname "$(readlink -f "$0")")
cd $SCRIPT_BASE_DIR

# this is a hack to allow installation in a situation where there isn't a proper init and packages complain about a lack of a runlevel
if [ "$RUNLEVEL" = "" ]
then
	export RUNLEVEL=3
fi

source ./sg-server-config.sh

./scripts/install-certs.sh
./scripts/config-certs-provisioning.sh
./scripts/install-sg-mariadb.sh
./scripts/install-sg-exim.sh
./scripts/install-spamgourmet.sh
./scripts/install-dev-tools.sh

echo '##########################################################################'
echo "### install finished. please go to $DOMAIN,"
echo '### you should see the spamgourmet clone'
echo '##########################################################################'
