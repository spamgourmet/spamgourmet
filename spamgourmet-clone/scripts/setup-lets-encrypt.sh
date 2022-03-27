#This script expects to be run from the spamgourmet-clone main directory
echo '========================= lets-encrypt setup start'
source sg-server-config.sh

##########################################################################
### install dehydrated and sets it up for your domain
##########################################################################

echo '##########################################################################'
echo '### set up LetsEncrypt'
echo '##########################################################################'
cd $SCRIPT_BASE_DIR
apt-get install -y dehydrated
./scripts/config-lets-encrypt.sh
cd $SCRIPT_BASE_DIR
echo '##########################################################################'
echo '### configure dehydrated autorenew and automatic provisioning'
echo '###   for exim4 and lighttpd'
echo '##########################################################################'
cat <<-EOF >/var/lib/dehydrated/renewAllCerts.sh
#!/bin/bash
cd /var/lib/dehydrated
dehydrated -c >/tmp/dehydrated.log 2>&1
# exim certificates
cp /var/lib/dehydrated/certs/$DOMAIN/fullchain.pem /etc/exim4/exim.crt
cp /var/lib/dehydrated/certs/$DOMAIN/privkey.pem /etc/exim4/exim.key
chown root:Debian-exim /etc/exim4/exim.*
chmod 640 /etc/exim4/exim.*
# lighttpd certificates
cat /var/lib/dehydrated/certs/$DOMAIN/cert.pem /var/lib/dehydrated/certs/$DOMAIN/privkey.pem >/etc/lighttpd/web.pem
chmod 600 /etc/lighttpd/web.pem
chown root:root /etc/lighttpd/web.pem
service exim4 restart
service lighttpd restart
EOF
chmod +x /var/lib/dehydrated/renewAllCerts.sh
mkdir -p /etc/cron.weekly
cp /var/lib/dehydrated/renewAllCerts.sh /etc/cron.weekly
echo '##########################################################################'
echo '### run dehydrated to generate/update the certs, with visible output'
echo '### to visually check that dehydrated works'
echo '##########################################################################'
/var/lib/dehydrated/renewAllCerts.sh
