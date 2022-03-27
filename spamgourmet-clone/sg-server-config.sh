###############################################################################
# configuration variables
# initialise them appropriately
# NB for the DKIM set-up you need to refer to
# https://www.geekrant.org/2017/04/25/trustworthy-email-authentication-using-exim4-spf-dkim-and-dmarc/

DOMAIN=spamgourmet.test
MARIADBROOTPWD="blahblah"
MARIADBINTERACTIVEPWD="blabblah"
SECRETPHRASE="blabblah"
ADMINEMAIL="you@whatever.com"
OTHERDOMAINEMAIL="noreply@$DOMAIN"
EATENLOGCOUNT=10
DKIM_SELECTOR="20180125"

# keep real credentials off github
[ -e sg-server-config-secrets ] && . sg-server-config-secrets
