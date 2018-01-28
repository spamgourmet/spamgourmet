#!/bin/bash
echo '========================= remote-install start'
###############################################################################
# script variables
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
	OVHAPPKEY=CVvttJNs1WX7jp0q
	OVHAPPSECRET=oJHAufRpBEHamKo64d7ClgWpXRJoodUB
	OVHCONSKEY=ulBZt16KjNp6Pm0vgsge8dudNoEm2ZSO
fi

THISDIR=$(dirname "$(readlink -f "$0")")
cd $THISDIR

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
function configLetsEncrypt {
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
}

##########################################################################
### install dehydrated and sets it up for your domain
##########################################################################
function setupLetsEncrypt {
	echo '##########################################################################'
	echo '### set up LetsEncrypt'
	echo '##########################################################################'
	cd $THISDIR
	apt-get install -y dehydrated

	configLetsEncrypt

	cd $THISDIR
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
	cat <<-EOF >>/etc/crontab
	17 5,17    * * *   root    /var/lib/dehydrated/renewAllCerts.sh
	EOF
	echo '##########################################################################'
	echo '### run dehydrated to generate/update the certs, with visible output'
	echo '### to visually check that dehydrated works'
	echo '##########################################################################'
	cd /var/lib/dehydrated
	dehydrated -c
	cd $THISDIR
}

##########################################################################
### main installation - always required
##########################################################################
function mainInstall {
	cd $THISDIR
	echo '##########################################################################'
	echo '### install mandatory packages'
	echo '##########################################################################'
	apt-get update; apt-get upgrade; apt-get autoremove
	apt-get install -y subversion libdbd-mysql-perl libclass-loader-perl \
		mariadb-server libdbd-mysql-perl libclass-loader-perl exim4 \
		imagemagick lighttpd \
		libcrypt-eksblowfish-perl libdigest-bcrypt-perl \
		unzip make gcc bash-completion ca-certificates

	echo '##########################################################################'
	echo '### download and patch spamgourmet code'
	echo '##########################################################################'
	svn co https://svn.code.sf.net/p/spamgourmet/code/ code

	cd code
	OLDIFS=$IFS;IFS=$'\n'
	for f in `grep -rl /path/to/modules .`; do
	sed -i 's/\/path\/to\/modules/\/usr\/local\/lib\/spamgourmet\/modules/g' $f
	done
	for f in `grep -rl /path/to/spamgourmet.config .`; do
		sed -i 's/\/path\/to\/spamgourmet.config/\/etc\/spamgourmet\/spamgourmet.config/g' $f
	done
	for f in `grep -rl %imagefilename% .`; do
		sed -i 's/http:\/\/captcha.spamgourmet.com/https:\/\/'$DOMAIN'\/captcha/g' $f
	done
	for f in `grep -rl /path/to/outbound.log .`; do
	sed -i 's/\/path\/to\/outbound.log/\/var\/log\/spamgourmet\/outbound.log/g' $f
	done
	for f in `grep -rl /path/to/debug.txt .`; do
		sed -i 's/\/path\/to\/debug.txt/\/var\/log\/spamgourmet\/spamgourmet.config/g' $f
	done
	for f in `grep -rl /home/mora/src/spamgourmet/captcha .`; do
		sed -i 's/\/home\/mora\/src\/spamgourmet\/captcha/\/usr\/local\/lib\/spamgourmet\/captchasrv/g' $f
	done
	for f in `grep -rl /tmp/sg/captcha .`; do
		sed -i 's/\/tmp\/sg\/captcha/\/var\/www-spamgourmet\/captcha/g' $f
	done
	IFS=$OLDIFS
	cd $THISDIR

	echo '##########################################################################'
	echo '### create necessary folder structure'
	echo '##########################################################################'
	mkdir -p /usr/local/lib/spamgourmet
	mkdir -p /var/www-spamgourmet
	mkdir -p /var/www-spamgourmet/captcha
	mkdir -p /var/log/spamgourmet
	mkdir -p /etc/spamgourmet

	echo '##########################################################################'
	echo '### move stuff where it belongs'
	echo '##########################################################################'
	cd code
	cp -R captchasrv mailhandler modules /usr/local/lib/spamgourmet
	cp -R web/graphs.cgi web/html/* web/templates /var/www-spamgourmet
	cp conf/spamgourmet.config /etc/spamgourmet
	wget www.spamgourmet.com/stuff/flagmap.png
	mv flagmap.png /var/www-spamgourmet/stuff/

	cd $THISDIR
	echo '##########################################################################'
	echo '### configure mysql'
	echo '### this is a nasty hack - watch closely that it succeeds'
	echo '##########################################################################'
	mysql_secure_installation <<-EOF

	y
	$MARIADBROOTPWD
	$MARIADBROOTPWD
	y
	y
	y
	y
	EOF

	mysqladmin -u root -p$MARIADBROOTPWD create sguser
	mysql -s -u root -p$MARIADBROOTPWD <<-EOF
	create database sg;
	grant all privileges on sg.* to sguser identified by "$MARIADBINTERACTIVEPWD" with grant option;
	flush privileges;
	EOF
	mysql -s -u sguser -p$MARIADBINTERACTIVEPWD -Dsg <./code/conf/db.sql
	mysql -s -u sguser -p$MARIADBINTERACTIVEPWD -Dsg <./code/conf/dialogs.sql

	echo '##########################################################################'
	echo '### configure exim4'
	echo '##########################################################################'
	# need fix to work if has multiple IP addresses
	# also do not know if this will work on ipv6-only servers
	IPADDRESS=$(hostname -I | head -1)

	sed -i "s/dc_eximconfig_configtype=.*$/dc_eximconfig_configtype='internet'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_other_hostnames=.*$/dc_other_hostnames='$DOMAIN'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_local_interfaces=.*$/dc_local_interfaces='$IPADDRESS'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_readhost=.*$/dc_readhost=''/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_relay_domains=.*$/dc_relay_domains='ob."$DOMAIN"'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_minimaldns=.*$/dc_minimaldns='false'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_relay_nets=.*$/dc_relay_nets=''/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_smarthost=.*$/dc_smarthost=''/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/CFILEMODE=.*$/CFILEMODE='644'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_use_split_config=.*$/dc_use_split_config='true'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_hide_mailname=.*$/dc_hide_mailname=''/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_mailname_in_oh=.*$/dc_mailname_in_oh='true'/" /etc/exim4/update-exim4.conf.conf
	sed -i "s/dc_localdelivery=.*$/dc_localdelivery='mail_spool'/" /etc/exim4/update-exim4.conf.conf
	echo $DOMAIN >/etc/mailname
	update-exim4.conf

	echo '##########################################################################'
	echo '### captcha creation'
	echo '##########################################################################'
	useradd -c "captcha server for spamgourmet" -f -1 -M -r captcha
	mkdir -p /var/www-spamgourmet/captchasrv/
	chown -R captcha /usr/local/lib/spamgourmet/captchasrv/
	chown -R captcha /var/www-spamgourmet/captcha
	cat <<-EOF >/etc/systemd/system/captchasrv.service
	[Unit]
	Description=spamgourmet captcha service
	Documentation=https://sourceforge.net/p/spamgourmet/code/HEAD/tree/captchasrv/

	[Service]
	ExecStart=/usr/local/lib/spamgourmet/captchasrv/captchasrv.pl
	Restart=on-failure
	User=captcha

	[Install]
	WantedBy=multi-user.target
	EOF
	systemctl enable captchasrv.service
	systemctl start captchasrv.service

	if [ -e /var/lib/dehydrated/certs/$DOMAIN/fullchain.pem ]; then
		echo '##########################################################################'
		echo '### configure exim for TLS because dehydrated certificate exists'
		echo '##########################################################################'
		cat <<-EOF >/etc/exim4/conf.d/main/00_exim4-config_myvalues
			MAIN_TLS_ENABLE = yes
			# renaming the startssl certs to names used by default by exim4
			# so no other change to exim4 config
		EOF
		cp /var/lib/dehydrated/certs/$DOMAIN/fullchain.pem /etc/exim4/exim.crt
		cp /var/lib/dehydrated/certs/$DOMAIN/privkey.pem /etc/exim4/exim.key
		service exim4 restart
	else
		echo '##########################################################################'
		echo '### WARNING! Could NOT configure exim for TLS because'
		echo '### could not find dehydrated certificates'
		echo '##########################################################################'
	fi

	echo '##########################################################################'
	echo '### add spamgourmet required perl modules'
	echo '##########################################################################'
	#https://www.geekrant.org/2017/04/23/how-to-to-install-the-crypteksblowfishbcrypt-module-and-cryptrandom/
	#apt-get install -y libcrypt-eksblowfish-perl libdigest-bcrypt-perl
	#apt-get install -y unzip make gcc
	wget http://search.cpan.org/CPAN/authors/id/I/IL/ILYAZ/modules/Math-Pari-2.01080900.zip
	unzip Math-Pari-2.01080900.zip
	cd Math-Pari-2.01080900/
	perl Makefile.PL <<-EOF
	y
	EOF
	sed -i 's/CLK_TCK/CLOCKS_PER_SEC/g' pari-2.1.7/src/language/init.c
	make
	make install
	cd $THISDIR
	wget http://search.cpan.org/CPAN/authors/id/V/VI/VIPUL/Crypt-Random-1.25.tar.gz
	tar zxvf Crypt-Random-1.25.tar.gz
	cd Crypt-Random-1.25
	perl Makefile.PL
	make
	make install
	cd $THISDIR

	echo '##########################################################################'
	echo '### enable cgi for lighttpd'
	echo '##########################################################################'
	lighty-enable-mod cgi

	cat <<-EOF >/etc/lighttpd/conf-enabled/spamgourmet.conf
	cgi.assign      = (
	    ".pl"  => "/usr/bin/perl",
	    ".cgi" => "/usr/bin/perl"
	)

	\$SERVER["socket"] == ":443" {
	  ssl.engine = "enable",
	  ssl.pemfile = "/etc/lighttpd/web.pem"
	}

	\$HTTP["scheme"] == "http" {
	    # capture vhost name with regex conditiona -> %0 in redirect pattern
	    # must be the most inner block to the redirect rule
	    \$HTTP["host"] =~ ".*" {
	        url.redirect = (".*" => "https://%0\$0")
	    }
	}

	\$HTTP["url"] =~ ".*" {
	    expire.url = ( "" => "access plus 0 seconds" )
	}
	EOF

	echo '##########################################################################'
	echo '### configure spamgourmet website'
	echo '##########################################################################'
	sed -i 's/"index.php", "index.html"/"index.pl", "index.php", "index.html"/' /etc/lighttpd/lighttpd.conf

	sed -i "s/'example.com' => 1,/'"$DOMAIN"' => 1,/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/'example.net' => 1/'"$DOMAIN"' => 1/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/\$admindomain = 'example.com';$/\$admindomain = '"$DOMAIN"';/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/\$dbstring = 'DBI:mysql:database=dbname;host=localhost';/\$dbstring = 'DBI:mysql:database=sg;host=localhost';/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/\$dbuser = 'dbuser';/\$dbuser = 'sguser';/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/dbpassword = 'dbpassword';/dbpassword = '"$MARIADBINTERACTIVEPWD"';/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/debugfilename = '\/var\/log\/spamgourmet\/spamgourmet.config';/debugfilename = '\/var\/log\/spamgourmet\/spamgourmet.log';/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/webapproot = '\/path\/to\/web\/'/webapproot = '\/var\/www-spamgourmet\/'/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/webtemplatedir = '\/path\/to\/templates\/';/webtemplatedir = '\/var\/www-spamgourmet\/templates\/';/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/secretphrase = 'a very secret phrase';/secretphrase = '"$SECRETPHRASE"';/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/mailhost = 'localhost';/mailhost = '"$DOMAIN"';\n  \$obmailhost = 'ob."$DOMAIN"';/" /etc/spamgourmet/spamgourmet.config
	#sed -i "s/obmailhost = 'ob.example.com';/obmailhost = 'ob."$DOMAIN"';/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/adminemail = 'admin@example.com';/adminemail = '"$ADMINEMAIL"';/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/otherdomainemail = 'spameater@example.com';/otherdomainemail = '"$OTHERDOMAINEMAIL"';\n\  \$normalURL = '';\n  \$secureURL = '';/" /etc/spamgourmet/spamgourmet.config
	sed -i "s/numberofeatenmessagestolog = 3;/numberofeatenmessagestolog = "$EATENLOGCOUNT";/" /etc/spamgourmet/spamgourmet.config

	sed -i 's/server.document-root        = "\/var\/www\/html"/server.document-root        = "\/var\/www-spamgourmet"/' /etc/lighttpd/lighttpd.conf

	echo '##########################################################################'
	echo '### link to exim4'
	echo '##########################################################################'
	cat <<-EOF >>/etc/exim4/conf.d/router/00_exim4-config_header
	    spamgourmet_address:
	      debug_print = "R: spamgourmet_address \$local_part@\$domain"
	      driver = accept
	      transport = sg_to_user_pipe
	      domains = $DOMAIN
	      errors_to = "[me]"

	    outbound_spamgourmet_address:
	      debug_print = "R: outbound_spamgourmet_address \$local_part@\$domain"
	      driver = accept
	      transport = sg_from_user_pipe
	      domains = ob.$DOMAIN
	EOF

	cat <<-EOF >>/etc/exim4/conf.d/transport/00_exim4-config_header
	sg_to_user_pipe:
	  debug_print = "T: sg_to_user_pipe for \$local_part@\$domain"
	  driver = pipe
	  return_output = false
	  temp_errors = 69
	  ignore_status = true
	  environment = REPLYTO=\$reply_address:FROM=\$header_from::TO=\$header_to:
	  command = /usr/local/lib/spamgourmet/mailhandler/spameater
	  #user = "spamgourmet"
	  #group = "spamgourmet"

	sg_from_user_pipe:
	  debug_print = "T: sg_from_user_pipe for \$local_part@\$domain"
	  driver = pipe
	  return_output = true
	  environment = REPLYTO=\$reply_address:FROM=\$header_from:
	  command = /usr/local/lib/spamgourmet/mailhandler/outbound
	  # user = "spamgourmet"
	  #group = "spamgourmet"
	EOF
	# registration emails should not use spamgourmet website
	sed -i "s/www.spamgourmet.com/$DOMAIN/g" /usr/local/lib/spamgourmet/modules/Mail/Spamgourmet/WebMessages.pm
	# reply address masking uses # so let it pass
	sed -i '/^CHECK_RCPT_/ s/\#//g' /etc/exim4/conf.d/main/01_exim4-config_listmacrosdefs
	cd $THISDIR
	if [ -e ./dkim.private ]; then
		echo '##########################################################################'
		echo '### configure exim4 for dkim since there are dkim keys in the folder'
		echo '### where this script is'
		echo '##########################################################################'
		mv dkim.* /etc/exim4/
		chown root:Debian-exim /etc/exim4/dkim.*
		chmod 640 /etc/exim4/dkim.*
		cat <<-EOF >>/etc/exim4/conf.d/main/01_exim4-config_listmacrosdefs
		#DKIM loading
		DKIM_CANON = relaxed
		DKIM_DOMAIN = \${sender_address_domain}
		DKIM_PRIVATE_KEY = CONFDIR/dkim.private
		DKIM_SELECTOR = $DKIM_SELECTOR
		EOF
	else
		echo '##########################################################################'
		echo '### WARNING! CANNOT configure exim4 for dkim, missing dkim keys'
		echo '##########################################################################'
	fi
	/var/lib/dehydrated/renewAllCerts.sh
	service exim4 restart
	service lighttpd restart
}

setupLetsEncrypt
mainInstall

echo '##########################################################################'
echo "### install finished. please go to $DOMAIN,"
echo '### you should see the spamgourmet clone'
echo '##########################################################################'
