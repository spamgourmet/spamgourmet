#!/bin/bash
#This script expects to be run from the spamgourmet-clone main directory
echo '========================= lets-encrypt configuration start'
source sg-server-config.sh

##########################################################################
### creates self-signed DKIM and SSL certificates to be used by a default
### test install of spamgourmet
### the certificates created by this script are in pem format as follows:
###   - /etc/ssl/private/dkim.pem     (0600 permissions)
###   - /etc/ssl/certs/dkim.crt       (0644 permissions)
###   - /etc/ssl/private/$DOMAIN.pem  (0600 permissions)
###   - /etc/ssl/certs/$DOMAIN.crt    (0644 permissions)
###
###
### NOTE: if the above certificates already exist, the script will NOT
###       overwrite them because the assumption is that there's already
###       a mechanism to create and keep them up to date
###
##########################################################################

[ -e /etc/ssl/private/dkim.pem ]    && exit
[ -e /etc/ssl/private/$DOMAIN.pem ] && exit
