#!/bin/bash
#This script expects to be run from the spamgourmet-clone main directory
echo '========================= lets-encrypt configuration start'
source sg-server-config.sh

##########################################################################
### creates self-signed DKIM and SSL certificates to be used by a default
### test install of spamgourmet
### the certificates created by this script are in pem format as follows:
###   - /etc/ssl/private/dkim.pem
###   - /etc/ssl/certs/dkim.crt
###   - /etc/ssl/private/$DOMAIN.pem
###   - /etc/ssl/certs/$DOMAIN.crt
##########################################################################
