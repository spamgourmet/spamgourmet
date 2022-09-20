oneTimeSetUp () {
    #FIXME - change the way we handle path substitution and then get
    #rid of this. Bad because it forces test to run in docker container
    mkdir /path
    if [ ! -e /path/to ]
    then
        ln -s $PWD/conf /path/to
    fi
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

oneTimeTeardown () {
    rm /path/to
    rmdir /path
    mv /usr/sbin/sendmail.disabled /usr/sbin/sendmail 

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

# Load shUnit2
. /usr/bin/shunit2
