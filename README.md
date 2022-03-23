
NOTE: This software is only if you want to *provide* the service.

Additional documentation:

- [cloning script][clone-script]
- [spamgourmet home][spam-home] ([archived][spam-home-arch])
    - [spamgourmet bulletin board][spam-bbs] ([archived][spam-bbs-arch])
        - [Developers forum][spam-bbs-dev] ([archived][spam-bbs-dev-arch])
- [an alternative: erine.email](https://gitlab.com/mdavranche/erine.email) is open source and a very close match to spamgourmet versus [others](https://bbs.spamgourmet.com/viewtopic.php?f=7&t=1786) ([archived](https://web.archive.org/web/20190821185327/https://bbs.spamgourmet.com/viewtopic.php?f=7&t=1786))

[clone-script]: https://github.com/vasile-gh/spamgourmet-clone
[spam-home]: https://www.spamgourmet.com/index.pl
[spam-home-arch]: https://web.archive.org/web/*/www.spamgourmet.com
[spam-bbs]: https://bbs.spamgourmet.com/index.php
[spam-bbs-arch]: https://web.archive.org/web/*/https://bbs.spamgourmet.com/index.php
[spam-bbs-dev]: https://bbs.spamgourmet.com/viewforum.php?f=2
[spam-bbs-dev-arch]: https://web.archive.org/web/*/https://bbs.spamgourmet.com/viewforum.php?f=2

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

### LICENSE AND DISTRBUTION
---------------------------

See the file COPYING for details of the software licensing of spamgourmet. 