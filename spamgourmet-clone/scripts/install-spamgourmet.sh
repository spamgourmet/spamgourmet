#!/bin/bash
#This script expects to be run from the spamgourmet-clone main directory
echo '========================= spamgourmet server installation start'
source sg-server-config.sh

cd $SCRIPT_BASE_DIR

function mandatory_packages {
	echo '##########################################################################'
	echo '### install mandatory packages'
	echo '##########################################################################'
	apt-get update; apt-get upgrade -y; apt-get autoremove
	apt-get install -y git libdbd-mysql-perl libclass-loader-perl \
		libdbd-mysql-perl libclass-loader-perl imagemagick \
		libcrypt-eksblowfish-perl libdigest-bcrypt-perl \
		unzip make gcc bash-completion ca-certificates wget
}


function download_spamgourmet {
	echo '##########################################################################'
	echo '### download and patch spamgourmet code'
	echo '##########################################################################'
	git clone https://github.com/spamgourmet/spamgourmet.git code
}

function customize_spamgourmet {
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

function install_perl_modules {
	echo '##########################################################################'
	echo '### add spamgourmet required perl modules'
	echo '##########################################################################'
	#https://www.geekrant.org/2017/04/23/how-to-to-install-the-crypteksblowfishbcrypt-module-and-cryptrandom/
	#apt-get install -y libcrypt-eksblowfish-perl libdigest-bcrypt-perl
	#apt-get install -y unzip make gcc
	wget https://cpan.metacpan.org/authors/id/I/IL/ILYAZ/modules/Math-Pari-2.03052103.tar.gz
	tar xzf Math-Pari-2.03052103.tar.gz
    (
        cd Math-Pari-2.03052103/
        PERL_MM_USE_DEFAULT=1 perl Makefile.PL
        make
        make install
    )
	wget https://cpan.metacpan.org/authors/id/V/VI/VIPUL/Crypt-Random-1.54.tar.gz
	tar xzf Crypt-Random-1.54.tar.gz
    (
        cd Crypt-Random-1.54
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
	cat <<-EOF >>/etc/exim4/conf.d/router/010_exim4_router_spamgourmet
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

	cat <<-EOF >>/etc/exim4/conf.d/transport/05_exim4_transport_spamgourmet
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
	service exim4 restart
	service lighttpd restart
}

function configure_sg_db_connection_and_data {
	#ensure that mysqld is running, - what about init systems?
	#    mysqld_safe --no-watch
	service mysql start
	mysql -s -u sguser -p$MARIADBINTERACTIVEPWD -Dsg <./code/conf/db.sql
	mysql -s -u sguser -p$MARIADBINTERACTIVEPWD -Dsg <./code/conf/dialogs.sql
	service mysql restart
}

mandatory_packages
if [ ! -f "/code/README.md" ]
then
    echo "****************************************************************************"
    echo "*    No spamgourmet code present - downloading from internet archive       *"
    echo "****************************************************************************"
    download_spamgourmet
fi
customize_spamgourmet
create_folders
install_spamgourmet
create_captcha
install_perl_modules
configure_lighhttpd
configure_website
configure_sg_db_connection_and_data
