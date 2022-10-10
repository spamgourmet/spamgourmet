# SHUNIT tests for spamgourmet
#
# these tests are designed to test the full functionality of the
# programs included in spamgourmet in a more or less correct running
# environment and so they are really integration tests.
#
# beware that these tests manipulate the environmnet on the system
# they are running on including messing around with the sendmail
# binary. They should not be run on a production system and are
# normally expected to be run inside docker.
#

oneTimeSetUp() {
  service mysql start
  mkdir -p /path/to

  sed -e 's/dbuser/sguser/' \
    -e 's/dbname/sg/' \
    conf/spamgourmet.config > /path/to/spamgourmet.config

  /usr/bin/perl -Imodules test/create-test-user.pl

  mv /usr/sbin/sendmail /usr/sbin/sendmail.disabled

}

oneTimeTearDown() {
  if [ -z "$SHTEST_DONT_CLEAN_UP" ]; then
    rm /path/to/spamgourmet.config
    rmdir /path/to
    rmdir /path
    service mysql stop
  fi
  mv /usr/sbin/sendmail.disabled /usr/sbin/sendmail
}

setUp() {
  export SENDMAIL_OUT=$(tempfile -d $SHUNIT_TMPDIR)

  if [ -e sendmail ]; then
    echo "sendmail not disabled ; aborting"
    exit 9
  else
    (
      echo '#!/bin/bash'
      echo "echo writing mail to $SENDMAIL_OUT >&2"
      echo "cat >> $SENDMAIL_OUT"
    ) > /usr/sbin/sendmail
    chmod +x /usr/sbin/sendmail
  fi

  if [ -z "$SENDMAIL_OUT" ]; then
    echo "test setup failure, no sendmail file"
    exit 9
  fi

}

tearDown() {
  rm /usr/sbin/sendmail
  if [ -z "$SHTEST_DONT_CLEAN_UP" ]; then
    rm $SENDMAIL_OUT
  fi
}

testMailEaterShouldRejectBadMail() {
  /usr/bin/perl -Imodules -s mailhandler/spameater -extradebug=5 -debugstderr=5 < test/fixture/reject_wrong_domain.email

  assertFalse "incorrect mail accepted" "[ -s $SENDMAIL_OUT]"
}

testMailEaterShouldAcceptMail() {
  /usr/bin/perl -Imodules -s mailhandler/spameater -extradebug=5 -debugstderr=5 < test/fixture/accept_very_simple.email

  assertTrue "valid mail not accepted" "[ -s $SENDMAIL_OUT ]"
}

testMailEaterShouldRejectExceededCount() {
  # TODO we should check that the email has been recorded in appropriate statistics.
  /usr/bin/perl -Imodules -s mailhandler/spameater -extradebug=5 -debugstderr=5 < test/fixture/reject_exeeded_count.email

  assertFalse "exceeded mail accepted" "[ -s $SENDMAIL_OUT ]"
}

testMailEaterShouldRejectExceededCount() {
  # TODO we should check that the email has been recorded in appropriate statistics.
  /usr/bin/perl -Imodules -s mailhandler/spameater -extradebug=5 -debugstderr=5 < test/fixture/reject_to_address_in_body.email

  assertFalse "malformatted email accepted" "[ -s $SENDMAIL_OUT ]"
}

# Load shUnit2
. /usr/bin/shunit2
SENDMAIL_OUT=$(tempfile -d $SHUNIT_TMPDIR)
