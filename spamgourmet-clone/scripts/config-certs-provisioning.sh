#!/bin/bash
#This script expects to be run from the spamgourmet-clone main directory
echo '##########################################################################'
echo '### set up automated provisioning for exim4 and lighttpd'
echo '##########################################################################'
source sg-server-config.sh

cd $SCRIPT_BASE_DIR
mkdir -p /etc/cron.weekly
cat <<-EOF >/etc/cron.weekly/provisionCerts.sh
#!/bin/bash
# exim certificates
cp /etc/ssl/certs/$DOMAIN.crt   /etc/exim4/exim.crt
cp /etc/ssl/private/$DOMAIN.pem /etc/exim4/exim.key
chown root:Debian-exim /etc/exim4/exim.*
chmod 640 /etc/exim4/exim.*
service exim4 restart
# lighttpd certificates
cat /etc/ssl/certs/$DOMAIN.crt /etc/ssl/private/$DOMAIN.pem >/etc/lighttpd/web.pem
chmod 600 /etc/lighttpd/web.pem
chown root:root /etc/lighttpd/web.pem
service lighttpd restart
EOF
chmod +x /etc/cron.weekly/provisionCerts.sh

# and now do the first provisioning
/etc/cron.weekly/provisionCerts.sh
