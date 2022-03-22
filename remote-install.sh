#!/bin/bash
echo '========================= remote-install start'
source sg-server-config.sh

THISDIR=$(dirname "$(readlink -f "$0")")
cd $THISDIR


function setupLetsEncrypt {
	./scripts/setup-lets-encrypt.sh
}

##########################################################################
### main installation - always required
##########################################################################
function mainInstall {
	,./scripts/install-spamgoumet.sh
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
