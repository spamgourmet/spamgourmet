oneTimeSetUp () {
    service mysql start
    mkdir -p /path/to

    sed -e 's/dbuser/sguser/' \
        -e 's/dbname/sg/' \
        conf/spamgourmet.config > /path/to/spamgourmet.config

    /usr/bin/perl -Imodules test/create-test-user.pl

    mv /usr/sbin/sendmail /usr/sbin/sendmail.disabled

    if [ -e sendmail ]
    then
        echo "sendmail not disabled ; aborting"
        exit 9
    else
        ( echo '#!/bin/bash'
          echo 'cat >> $SENDMAIL_OUT' ) > /usr/sbin/sendmail
        chmod +x /usr/sbin/sendmail
    fi

}

oneTimeTearDown () {
    rm /path/to
    rmdir /path
    mv /usr/sbin/sendmail.disabled /usr/sbin/sendmail 

    service mysql stop
}

testMailEaterShouldRejectBadMail () {
    SENDMAIL_OUT=`tempfile -d $SHUNIT_TMPDIR`
    #
    #FIXME start stuff for spameater

    /usr/bin/perl -Imodules -s mailhandler/spameater  -extradebug=5 -debugstderr=5 <   test/fixture/reject_wrong_domain.email

    assertFalse "incorrect mail accepted" '[ -s SENDMAIL_OUT ]'
}

testMailEaterShouldAcceptMail () {
    SENDMAIL_OUT=`tempfile -d $SHUNIT_TMPDIR`
    #
    #FIXME start stuff for spameater

    /usr/bin/perl -Imodules  -s mailhandler/spameater  -extradebug=5 -debugstderr=5 <   test/fixture/accept_very_simple.email

    assertTrue "valid mail not accepted" '[ -s SENDMAIL_OUT ]'
}


testMailEaterShouldRejectExceededCount () {
    # FIXME we should check that the email has been recorded in appropriate statistics. 

    SENDMAIL_OUT=`tempfile -d $SHUNIT_TMPDIR`
    #
    #FIXME start stuff for spameater

    /usr/bin/perl -Imodules -s mailhandler/spameater  -extradebug=5 -debugstderr=5 <   test/fixture/reject_exeeded_count.email

    assertFalse "exceeded mail accepted" '[ -s SENDMAIL_OUT ]'
}

# Load shUnit2
. /usr/bin/shunit2
