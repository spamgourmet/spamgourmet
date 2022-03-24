#!/bin/bash
#This script expects to be run from the spamgourmet-clone main directory
echo '========================= lets-encrypt configuration start'
source sg-server-config.sh

##########################################################################
### configures dehydrated for a domain managed by your provider
### if your domain is NOT hosted by OVH you need to change accordingly
### this function
###
### at the end of this running "cd /var/lib/dehydrated; dehydrated -c"
### should work and renew the LetsEncrypt certificates located at
### "/var/lib/dehydrated/certs/$DOMAIN/"
### NB the rest of the script depends on configuring the certificate to
### cover "$DOMAIN ob.$DOMAIN" - see below what is pushed in the
### domains.txt file
##########################################################################

echo '##########################################################################'
echo "### configure dehydrated for $DOMAIN with DNS managed by OVH"
echo '##########################################################################'
apt-get install -y git python-pip
mkdir -p /var/lib/dehydrated/hooks
cd /var/lib/dehydrated/
git clone https://github.com/rbeuque74/letsencrypt-ovh-hook hooks/ovh
pip install -r hooks/ovh/requirements.txt
cp hooks/ovh/ovh.conf.dist ./ovh.conf
sed -i "s/YOUR_APPLICATION_KEY/$OVHAPPKEY/" /var/lib/dehydrated/ovh.conf
sed -i "s/YOUR_APPLICATION_SECRET/$OVHAPPSECRET/" /var/lib/dehydrated/ovh.conf
sed -i "s/YOUR_CONSUMER_KEY/$OVHCONSKEY/" /var/lib/dehydrated/ovh.conf
cat <<-EOF >/etc/dehydrated/domains.txt
$DOMAIN ob.$DOMAIN
EOF
cat <<-EOF >>/etc/dehydrated/config
IP_VERSION=4
CHALLENGETYPE="dns-01"
HOOK="\${BASEDIR}/hooks/ovh/hook.py"
CONTACT_EMAIL=$ADMINEMAIL
EOF