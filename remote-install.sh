#!/bin/bash
echo '========================= remote-install start'
source ./sg-server-config.sh

export SCRIPT_BASE_DIR=$(dirname "$(readlink -f "$0")")
cd $SCRIPT_BASE_DIR


function setupLetsEncrypt {
	./scripts/setup-lets-encrypt.sh
}

##########################################################################
### main installation - always required
##########################################################################
function mainInstall {
	./scripts/install-spamgoumet.sh
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
