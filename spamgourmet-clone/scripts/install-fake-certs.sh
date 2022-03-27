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

DOMAIN=spamgourmet.test

DKIM_KEY_FILE=/etc/ssl/private/dkim.pem
DKIM_DNS_FILE=/etc/ssl/certs/dkim_dns_data.txt
DOMAIN_KEY_FILE=/etc/ssl/private/$DOMAIN.pem
DOMAIN_CERT_FILE=/etc/ssl/certs/$DOMAIN.crt


if [ -e "$DKIM_KEY_FILE" -o -e "$DOMAIN_KEY_FILE" ]
then
   echo "Aborting since key file already exists" >&2
   ls -l /etc/ssl/private > &2 
   exit 5
fi


# after https://stackoverflow.com/questions/10175812/how-to-generate-a-self-signed-ssl-certificate-using-openssl
openssl req -subj "/CN=$TEST_DOMAIN" -x509 -newkey rsa:4096 -keyout "$DOMAIN_KEY_FILE" -out "$DOMAIN_CERT_FILE" -sha256 -days 365

# after https://www.mailhardener.com/kb/how-to-create-a-dkim-record-with-openssl
openssl genrsa -out "$DKIM_KEY_FILE" 2048
openssl rsa -in "$DKIM_KEY_FILE" -pubout -outform der 2>/dev/null | openssl base64 -A > "$DKIM_DNS_FILE"


touch /etc/ssl/private/dkim.pem;    chmod 0600 /etc/ssl/private/dkim.pem
touch /etc/ssl/certs/dkim.crt;      chmod 0644 /etc/ssl/certs/dkim.crt
touch /etc/ssl/private/$DOMAIN.pem; chmod 0600 /etc/ssl/private/$DOMAIN.pem
touch /etc/ssl/certs/$DOMAIN.crt;   chmod 0644 
