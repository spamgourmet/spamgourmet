###############################################################################
# configuration variables
# initialise them appropriately
# NB for the DKIM set-up you need to refer to
# https://www.geekrant.org/2017/04/25/trustworthy-email-authentication-using-exim4-spf-dkim-and-dmarc/

DOMAIN=example.com
MARIADBROOTPWD="blahblah"
MARIADBINTERACTIVEPWD="blabblah"
SECRETPHRASE="blabblah"
ADMINEMAIL="you@whatever.com"
OTHERDOMAINEMAIL="noreply@$DOMAIN"
EATENLOGCOUNT=10
DKIM_SELECTOR="20180125"

OVHLETSENCRYPT=1

if [ $OVHLETSENCRYPT -eq 1 ]; then
	OVHAPPKEY=CVvttJNslWX7jp0q
	OVHAPPSECRET=oJHAufRp8EHamKo64d7ClgWpXRJoodUB
	OVHCONSKEY=ulBZt16KjNp6PmOvgsge8dudNoEm2ZSO
fi