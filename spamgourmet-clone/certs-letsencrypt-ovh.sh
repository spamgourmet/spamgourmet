#!/bin/bash
#This script expects to be run from the spamgourmet-clone main directory
source sg-server-config.sh

##########################################################################
### configures dehydrated for a domain managed by OVH
### at the end of this running "cd /var/lib/dehydrated; dehydrated -c"
### should work and renew the LetsEncrypt certificates located at
### "/var/lib/dehydrated/certs/$DOMAIN/"
### this also copies the certificates upon renewal to /etc/ssl/...
### finally, this creates a weekly task to renew
###   the LetsEncrypt certificate
##########################################################################

# these values are fake, replace them with your own
# from https://eu.api.ovh.com/createToken/
# they should allow the following actions:
#  - GET    on /domain/zone/$DOMAIN
#  - POST   on /domain/zone/$DOMAIN/refresh
#  - GET    on /domain/zone/$DOMAIN/soa
#  - GET    on /domain/zone/$DOMAIN/record
#  - POST   on /domain/zone/$DOMAIN/record
#  - GET    on /domain/zone/$DOMAIN/record/*
#  - DELETE on /domain/zone/$DOMAIN/record/*
#

LETSENCRYPT_OVH_APPKEY=GI9hY8855QKIbxOI
LETSENCRYPT_OVH_APPSECRET=f8jbdYCcWUFdNcIZLreq19QT6ywMy2VK
LETSENCRYPT_OVH_CONSUMERKEY=57dKujv5O3krms5kwah7D0hFNIFL6uR2

# shellcheck disable=SC1091
[ -e certs-letsencrypt-ovh-secrets ] && . certs-letsencrypt-ovh-secrets

echo "##########################################################################"
echo "### configure dehydrated for $DOMAIN with DNS managed by OVH"
echo "##########################################################################"
apt-get install -y git python3-pip dehydrated
mkdir -p /var/lib/dehydrated/hooks
cd /var/lib/dehydrated/ || exit 72
git clone https://github.com/rbeuque74/letsencrypt-ovh-hook hooks/ovh
pip install -r hooks/ovh/requirements.txt
cp hooks/ovh/ovh.conf.dist ./ovh.conf
sed -i "s/YOUR_APPLICATION_KEY/$LETSENCRYPT_OVH_APPKEY/" /var/lib/dehydrated/ovh.conf
sed -i "s/YOUR_APPLICATION_SECRET/$LETSENCRYPT_OVH_APPSECRET/" /var/lib/dehydrated/ovh.conf
sed -i "s/YOUR_CONSUMER_KEY/$LETSENCRYPT_OVH_CONSUMERKEY/" /var/lib/dehydrated/ovh.conf
cat <<- EOF > /etc/dehydrated/domains.txt
$DOMAIN ob.$DOMAIN
EOF
cat <<- EOF >> /etc/dehydrated/config
IP_VERSION=4
CHALLENGETYPE="dns-01"
HOOK="\${BASEDIR}/hooks/ovh/hook.py"
CONTACT_EMAIL=$ADMINEMAIL
EOF

/usr/bin/dehydrated --register --accept-terms

mkdir -p /etc/cron.weekly

cat <<- EOF > /etc/cron.weekly/letsencrypt-ovh-renew.sh
#!/bin/bash
cd /var/lib/dehydrated
dehydrated -c >/tmp/dehydrated.log 2>&1
cp /var/lib/dehydrated/certs/$DOMAIN/fullchain.pem /etc/ssl/certs/$DOMAIN.crt
cp /var/lib/dehydrated/certs/$DOMAIN/cert.pem      /etc/ssl/certs/$DOMAIN.pem
cp /var/lib/dehydrated/certs/$DOMAIN/privkey.pem   /etc/ssl/private/$DOMAIN.pem
EOF

chmod +x /etc/cron.weekly/letsencrypt-ovh-renew.sh

/etc/cron.weekly/letsencrypt-ovh-renew.sh
