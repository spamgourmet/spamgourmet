# Spamgourmet

NOTE: This software is only if you want to _provide_ the service.

Additional documentation:

- [cloning script][clone-script]
- [spamgourmet home][spam-home] ([archived][spam-home-arch])
  - [spamgourmet bulletin board][spam-bbs] ([archived][spam-bbs-arch])
    - [Developers forum][spam-bbs-dev] ([archived][spam-bbs-dev-arch])
- [an alternative: erine.email](https://gitlab.com/mdavranche/erine.email) is
  open source and a very close match to spamgourmet versus
  [others](https://bbs.spamgourmet.com/viewtopic.php?f=7&t=1786)
  ([archived](https://web.archive.org/web/20190821185327/https://bbs.spamgourmet.com/viewtopic.php?f=7&t=1786))

[clone-script]: https://github.com/vasile-gh/spamgourmet-clone
[spam-home]: https://www.spamgourmet.com/index.pl
[spam-home-arch]: https://web.archive.org/web/*/www.spamgourmet.com
[spam-bbs]: https://bbs.spamgourmet.com/index.php
[spam-bbs-arch]: https://web.archive.org/web/*/https://bbs.spamgourmet.com/index.php
[spam-bbs-dev]: https://bbs.spamgourmet.com/viewforum.php?f=2
[spam-bbs-dev-arch]: https://web.archive.org/web/*/https://bbs.spamgourmet.com/viewforum.php?f=2

## HELPING WITH DEVELOPMENT

See the files in the `docs` directory, especially `dev-notes.md`

## INSTALLATION NOTES

---

The standard installation used in testing and so on is based on the
scripts in the directory spamgourmet-clone. That's probably a good
place to start for doing an instalation.

- Pre-requisites

  - Linux
  - sendmail
  - apache
  - mysql
  - perl

- MySQL

  ```bash
  mysql_install_db
  /etc/init.d/mysqld start
  mysqladmin -uroot -p<pass>
  ```

  The following commands should be entered at the mysql prompt

  ```bash
  create database <sguser>
  grant all privileges on <sguser>.* to <sguser> \
        identified by '<sgpass>' with grant option
  mysql -u<sguser> -p<sgpass> <db.sql
  mysql -u<sguser> -p<sgpass> <dialogs.sql
  ```

- Apache

- Sendmail

  - soft link from spameater to /etc/smrsh
  - specify the soft link name in .forward

- Spamgourmet

  - make appropriate changes to spamgourmet.config
    &nbsp;

  ```bash
  cd conf
  cp spamgourmet.config.default spamgourmet.config
  cp .forward.default ~/.forward
  ```

  - make appropriate changes to ~/.forward
  - edit index.pl and spameater.pl and set the configfile parameter to the full
    path the spamgourmet.config
