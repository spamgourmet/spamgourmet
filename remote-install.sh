#!/bin/bash
echo '========================= remote-install start'
source ./sg-server-config.sh

export SCRIPT_BASE_DIR=$(dirname "$(readlink -f "$0")")
cd $SCRIPT_BASE_DIR

# this is a hack to allow installation in a situation where there isn't a proper init and packages complain about a lack of a runlevel
if [ "$RUNLEVEL" = "" ]
then
	export RUNLEVEL=3
fi

function setupLetsEncrypt {
	./scripts/setup-lets-encrypt.sh
}

##########################################################################
### main installation - always required
##########################################################################
function mainInstall {
	./scripts/install-sg-mariadb.sh
	./scripts/install-sg-exim.sh
	./scripts/install-spamgourmet.sh
}

if [ SETUP_ENCRYPT="true" ]
then
    setupLetsEncrypt
fi
mainInstall

echo '##########################################################################'
echo "### install finished. please go to $DOMAIN,"
echo '### you should see the spamgourmet clone'
echo '##########################################################################'
