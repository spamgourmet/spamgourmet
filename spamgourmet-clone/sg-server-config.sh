#!/bin/bash
###############################################################################
# configuration variables
# initialise them appropriately
# NB for the DKIM set-up you need to refer to
# https://www.geekrant.org/2017/04/25/trustworthy-email-authentication-using-exim4-spf-dkim-and-dmarc/

# all variables here are used in other scripts so it's okay they
# aren't used here. Disable globally.
# shellcheck disable=SC2034

DOMAIN=spamgourmet.test
MARIADBROOTPWD="blahblah"
MARIADBINTERACTIVEPWD="blabblah"
SECRETPHRASE="blabblah"
ADMINEMAIL="sg-admin@$DOMAIN"
OTHERDOMAINEMAIL="noreply@$DOMAIN"
EATENLOGCOUNT=10
DKIM_SELECTOR="20180125"

# keep real credentials off github
# shellcheck disable=SC1091
[ -e sg-server-config-secrets ] && . sg-server-config-secrets
