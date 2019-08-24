
NOTE: This software is only if you want to *provide* the service.


### INSTALLATION NOTES
------------------

- Pre-requisites

	* Linux
	* sendmail
	* apache
	* mysql
	* perl

- MySQL

  ```
	mysql_install_db
	/etc/init.d/mysqld start
	mysqladmin -uroot -p<pass>
  ```

	The following commands should be entered at the mysql prompt
  ```
	create database <sguser>
	grant all privileges on <sguser>.* to <sguser> identified by '<sgpass>' with grant option
	mysql -u<sguser> -p<sgpass> <db.sql
	mysql -u<sguser> -p<sgpass> <dialogs.sql
	```

- Apache

- Sendmail

	* soft link from spameater to /etc/smrsh
	* specify the soft link name in .forward

- Spamgourmet

	* make appropriate changes to spamgourmet.config	  
  &nbsp;
  ```
	cd conf
	cp spamgourmet.config.default spamgourmet.config
	cp .forward.default ~/.forward
  ```

	* make appropriate changes to ~/.forward
	* edit index.pl and spameater.pl and set the configfile parameter to the full path the spamgourmet.config
