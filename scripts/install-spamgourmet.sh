#!/bin/bash
#This script expects to be run from the spamgourmet-clone main directory
echo '========================= spamgourmet server installation start'
source sg-server-config.sh

cd $SCRIPT_BASE_DIR

function mandatory_packages {
	echo '##########################################################################'
	echo '### install mandatory packages'
	echo '##########################################################################'
	apt-get update; apt-get upgrade; apt-get autoremove
	apt-get install -y subversion libdbd-mysql-perl libclass-loader-perl \
		mariadb-server libdbd-mysql-perl libclass-loader-perl exim4 \
		imagemagick lighttpd \
		libcrypt-eksblowfish-perl libdigest-bcrypt-perl \
		unzip make gcc bash-completion ca-certificates wget
}


function download_spamgourmet {
	echo '##########################################################################'
	echo '### download and patch spamgourmet code'
	echo '##########################################################################'
	git clone https://github.com/spamgourmet/spamgourmet.git code
    (
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
    )
}

function create_folders {
	echo '##########################################################################'
	echo '### create necessary folder structure'
	echo '##########################################################################'
	mkdir -p /usr/local/lib/spamgourmet
	mkdir -p /var/www-spamgourmet
	mkdir -p /var/www-spamgourmet/captcha
	mkdir -p /var/log/spamgourmet
	mkdir -p /etc/spamgourmet
}


function install_spamgourmet {
	echo '##########################################################################'
	echo '### move stuff where it belongs'
	echo '##########################################################################'
    (
        cd code
        cp -R captchasrv mailhandler modules /usr/local/lib/spamgourmet
        cp -R web/graphs.cgi web/html/* web/templates /var/www-spamgourmet
        cp conf/spamgourmet.config /etc/spamgourmet
        wget www.spamgourmet.com/stuff/flagmap.png
        mv flagmap.png /var/www-spamgourmet/stuff/
    )
}


function mysql_setup {
    #ensure that mysqld is running, - what about init systems?
    mysqld_safe --no-watch

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
	# too short field for the entire bcrypted password
	sed -i 's/Password` varchar.50./Password` varchar(80)/' ./code/conf/db.sql
	mysql -s -u sguser -p$MARIADBINTERACTIVEPWD -Dsg <./code/conf/db.sql
	mysql -s -u sguser -p$MARIADBINTERACTIVEPWD -Dsg <./code/conf/dialogs.sql
}

function exim4_setup {
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
}

function create_captcha {
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
	Documentation=https://github.com/spamgourmet/spamgourmet/tree/master/captchasrv

	[Service]
	ExecStart=/usr/local/lib/spamgourmet/captchasrv/captchasrv.pl
	Restart=on-failure
	User=captcha

	[Install]
	WantedBy=multi-user.target
EOF
	systemctl enable captchasrv.service
	systemctl start captchasrv.service
}

function configure_exim_tls {
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
}

function install_perl_modules {
	echo '##########################################################################'
	echo '### add spamgourmet required perl modules'
	echo '##########################################################################'
	#https://www.geekrant.org/2017/04/23/how-to-to-install-the-crypteksblowfishbcrypt-module-and-cryptrandom/
	#apt-get install -y libcrypt-eksblowfish-perl libdigest-bcrypt-perl
	#apt-get install -y unzip make gcc
	wget http://search.cpan.org/CPAN/authors/id/I/IL/ILYAZ/modules/Math-Pari-2.01080900.zip
	unzip Math-Pari-2.01080900.zip
    (
        cd Math-Pari-2.01080900/
        PERL_MM_USE_DEFAULT=1 perl Makefile.PL
        sed -i 's/CLK_TCK/CLOCKS_PER_SEC/g' pari-2.1.7/src/language/init.c
        make
        make install
    )
	wget http://search.cpan.org/CPAN/authors/id/V/VI/VIPUL/Crypt-Random-1.25.tar.gz
	tar zxvf Crypt-Random-1.25.tar.gz
    (
        cd Crypt-Random-1.25
        perl Makefile.PL
        make
        make install
    )
	echo '##########################################################################'
	echo '### enable cgi for lighttpd'
	echo '##########################################################################'
	lighty-enable-mod cgi
	lighty-enable-mod expire
}

function configure_lighhttpd {
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
}

function configure_website {
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
	cd $SCRIPT_BASE_DIR
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

mandatory_packages
download_spamgourmet
create_folders
install_spamgourmet
mysql_setup
exim4_setup
create_captcha
configure_exim_tls
install_perl_modules
configure_lighhttpd
configure_website
