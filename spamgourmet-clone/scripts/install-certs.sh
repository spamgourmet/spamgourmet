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
### NOTE #2: dkim.crt except the first and last line is actually the key
###       part of the DKIM DNS record (or should be)
##########################################################################

DKIM_PRIVKEY_FILE=/etc/ssl/private/dkim.pem
DKIM_PUBKEY_FILE=/etc/ssl/certs/dkim.crt
DOMAIN_PRIVKEY_FILE=/etc/ssl/private/$DOMAIN.pem
DOMAIN_CERT_FILE=/etc/ssl/certs/$DOMAIN.crt

DKIM_PRIVKEY_GIVEN=dkim.private
DKIM_PUBKEY_GIVEN=dkim.public

if [ -e "$DKIM_PRIVKEY_GIVEN" ]; then
  echo "installing supplied  DKIM key"
  mv "$DKIM_PRIVKEY_GIVEN" "$DKIM_PRIVKEY_FILE"
  mv "$DKIM_PUBKEY_GIVEN"  "$DKIM_PUBKEY_FILE"
elif [ -e "$DKIM_PRIVKEY_FILE" ]; then
  echo "skipping DKIM key creation as the file already exists"
else
  # adapted from https://www.mailhardener.com/kb/how-to-create-a-dkim-record-with-openssl
  openssl genrsa -out "$DKIM_PRIVKEY_FILE" 2048
  openssl rsa -in "$DKIM_PRIVKEY_FILE" -pubout -outform pem >"$DKIM_PUBKEY_FILE"
fi

if [ -e "$DOMAIN_PRIVKEY_FILE" ]
then
  echo "skipping SSL certificate creation as the file already exists"
else
  # after https://stackoverflow.com/questions/10175812/how-to-generate-a-self-signed-ssl-certificate-using-openssl
  openssl req -subj "/CN=$DOMAIN" -x509 -newkey rsa:4096 -keyout "$DOMAIN_PRIVKEY_FILE" -out "$DOMAIN_CERT_FILE" -sha256 -days 365
fi

# access rights must be ensured so this is unconditional
chmod 0600 "$DKIM_PRIVKEY_FILE"
chmod 0644 "$DKIM_PUBKEY_FILE"
chmod 0600 "$DOMAIN_PRIVKEY_FILE"
chmod 0644 "$DOMAIN_CERT_FILE"
