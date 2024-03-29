package Mail::Spamgourmet::Session;
use strict;

use Digest::MD5 qw(md5_hex);
use Crypt::Eksblowfish::Bcrypt;
use Crypt::Random;
use Mail::Spamgourmet::WebUtil;

my $_config                 = 0;
my $_defaultLanguageCode    = 'EN';
my $_defaultSessionTimeout  = 1800;
my @_supportedLanguageCodes = (
    'DA', 'DE', 'EN', 'ES', 'FR', 'JA', 'NL', 'PL',
    'PT', 'RO', 'RU', 'SV', 'TR', 'ZH'
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless $self, $class;
    my %params = @_;

    $self->{'UserID'}          = 0;
    $self->{'UserName'}        = '';
    $self->{'RealEmail'}       = '';
    $self->{'PendingEmail'}    = '';
    $self->{'Prefix'}          = '';
    $self->{'DefaultNumber'}   = 3;
    $self->{'NumDeleted'}      = 0;
    $self->{'NumForwarded'}    = 0;
    $self->{'LanguageCode'}    = $_defaultLanguageCode;
    $self->{'PendingHashCode'} = '';
    $self->{'Features'}        = 1;
    $self->{'LastCommand'}     = 0;
    $self->{'loginmsg'}        = '';
    $self->{'config'}          = 0;
    $self->{'query'}           = 0;
    $self->{'imagehash'}       = '';
    $self->{'imagefilename'}   = '';

    if ( $params{'config'} ) {
        $self->{'config'} = $params{'config'};
    }
    elsif ($_config) {
        $self->{'config'} = $_config;
    }

    if ( $params{'webutil'} ) {
        $self->{'webutil'} = $params{'webutil'};
    }
    else {
        $self->{'webutil'}
            = Mail::Spamgourmet::WebUtil->new( config => $self->{'config'} );
    }

    if ( $params{'query'} ) {
        $self->{'query'} = $params{'query'};
    }
    else {
        $self->{'query'} = new CGI;
    }

    if (   $self->{'query'}->param('languageCode')
        && $self->{'query'}->param('languageCode') =~ /^(\w\w)/ )
    {

        $self->{'LanguageCode'} = $1;
        $self->setCookies( 'languageCode', $self->{'LanguageCode'} );
    }
    elsif ($self->{'query'}->cookie('languageCode')
        && $self->{'query'}->cookie('languageCode') =~ /^\w\w/ )
    {
        $self->{'LanguageCode'} = $1;
    }
    elsif ( $ENV{'HTTP_ACCEPT_LANGUAGE'} ) {
        $self->{'LanguageCode'} = &guessLC;
    }

    $self->{'dialogs'} = Mail::Spamgourmet::Dialogs->new(
        config       => $self->{'config'},
        languageCode => $self->{'LanguageCode'}
    );

    my ( $inUser, $inPass, $token, $hashCode );

    $inUser = $self->{'query'}->param('user')
        if $self->{'query'}->param('user');
    $inPass = $self->{'query'}->param('pass')
        if $self->{'query'}->param('pass');

    $token = $self->{'query'}->cookie('token')
        if $self->{'query'}->cookie('token');

    $hashCode = $self->{'query'}->param('hc');
    $hashCode = $self->{'query'}->param('cec')                if !$hashCode;
    $hashCode = $self->{'query'}->param('confirmemailchange') if !$hashCode;

    if ( $self->{'query'}->param('logout') ) {
        $self->logout();
    }
    elsif ($self->{'query'}->param('newuser')
        && $self->{'query'}->param('imageword') )
    {
        $self->newuser(
            $self->{'query'}->param('newuser'),
            $self->{'query'}->param('newpass'),
            $self->{'query'}->param('confirm'),
            $self->{'query'}->param('imageword'),
            $self->{'query'}->param('imagehash')
        );
    }
    elsif ( $self->{'query'}->param('newuser') ) {
        my $now = time();
        if ($self->checkForTooManyAccountsFromIPAddress(
                $now, $ENV{'REMOTE_ADDR'}
            )
            )
        {
            $self->{'loginmsg'} = '...';
        }
        elsif (
            $self->checkForExistingUserName(
                $self->{'query'}->param('newuser')
            )
            )
        {
            $self->{'loginmsg'}
                = $self->{'dialogs'}->get( 'usernametaken', 'username',
                $self->{'query'}->param('newuser') );
        }
        else {
            my $word = $self->getImageWord();
            $self->{'imagefilename'} = $self->getNewImageFilename($word);
            $self->{'imagehash'}
                = $self->getNewImageHash( $self->{'query'}->param('newuser'),
                $word, $self->{'config'}->getSecretPhrase() );
        }
    }
    else {
        $self->login( $inUser, $inPass, $token, $hashCode );
    }

    if ( $self->{'UserID'} && $self->{'query'}->param('newpassword') ) {
        $self->newpassword(
            $self->{'query'}->param('newpassword'),
            $self->{'query'}->param('newpasswordconfirm'),
            $self->{'query'}->param('currentpassword')
        );
    }

    return $self;
}

sub getUserName {
    my $self = shift;
    return $self->{'UserName'};
}

sub setUserName {
    my $self  = shift;
    my $uname = shift;
    $self->{'UserName'} = $uname;
}

sub getWebUtil {
    my $self = shift;
    return $self->{'webutil'};
}

sub getImageHash {
    my $self = shift;
    return $self->{'imagehash'};
}

sub getImageFileName {
    my $self = shift;
    return $self->{'imagefilename'};
}

sub getNewImageFilename {
    my $self     = shift;
    my $quizword = shift;
    my $fn       = '';

    # Define $RmtPort and $RmtHost, remote port and host of server
    my $RmtHost = $self->{'config'}->getCaptchagenHost();
    return 'nocaptcha' unless $RmtHost;
    my $RmtPort = $self->{'config'}->getCaptchagenPort();
    use IO::Socket::INET;
    my $socket = IO::Socket::INET->new(
        PeerAddr => $RmtHost,
        PeerPort => $RmtPort,
        Proto    => "tcp",
        Type     => SOCK_STREAM
        )
        or die
        "testcaptcha: cannot connect to host $RmtHost port $RmtPort: $@\n";

    # Send the quizword to server - Note the 2 blanks after
    # the HTTP 1.1 and the double \n
    print $socket "GET /q=$quizword HTTP/1.1   \n\n";

    # Send a blank line to tell server we're done
    print $socket "\n\n";

    # Now we can get the server's response
    {    # Put perl in slurp mode
        local $/;
        $fn = <$socket>;

        # print "Server response is $response\n";
    }
    close $socket;
    return $fn;

}

sub getImageWord {
    my $self = shift;
    return 'nocaptcha' unless $self->{'config'}->getCaptchagenHost();
    my $quizword = '';
    open DICT, $self->{'config'}->{'dictionaryfile'}
        or die "Cannot read dictionary file: $!";
    seek DICT, 0, 2;    # Go to end of file
    my $DictLn = tell DICT;
    while ( eof DICT ) {
        seek DICT, int( rand( $DictLn - 10 ) ),
            0;          # Go to a random position in dict file
        next if ( eof DICT );
        $quizword = <DICT>;    # Skip the 1st word we read, because we
        $quizword = <DICT>;    # might start reading in the middle of a word
    }

    chomp $quizword;

    # Append a 3-digit int (100-999) to the quizword
    $quizword .= int( rand(899) + 100 );
    close DICT;
    return $quizword;

    #  return 'test403';
}

sub getSignupHash {
    my $self = shift;
    return $self->{'imagehash'};
}

sub guessLC {
    my $guessedLC;
    my @hals = split( /\,/, $ENV{'HTTP_ACCEPT_LANGUAGE'} );
    my ( $acceptedLC, $supportedLC, $hal ) = ( '', '', '' );
    foreach $acceptedLC (@hals) {

        # take the first two letters...
        $hal = substr( $acceptedLC, 0, 2 );
        foreach $supportedLC (@_supportedLanguageCodes) {
            if ( $hal =~ /$supportedLC/i && !$guessedLC ) {
                $guessedLC = $supportedLC;
            }
        }
    }
    if ( !$guessedLC ) {
        $guessedLC = $_defaultLanguageCode;
    }
    return $guessedLC;
}

sub getDialog {
    my $self = shift;
    return $self->{'dialogs'}->get(@_);
}

sub param {
    my $self  = shift;
    my $param = shift;
    return $self->{'query'}->param($param);
}

sub setConfig {
    my $self = shift;
    $self->{'config'} = shift;
    return $self;
}

sub setGlobalConfig {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    $_config = shift;
    return;
}

sub getLanguageCode {
    my $self = shift;
    return $self->{'LanguageCode'};
}

sub getFeatures {
    my $self = shift;
    return $self->{'Features'};
}

sub setFeatures {
    my $self     = shift;
    my $features = shift;
    $self->{'Features'} = $features;
}

sub login {
    my $self = shift;
    my ( $inUser, $inPass, $token, $hashCode ) = @_;
    my %attr;

    my ( $User, $Pass, $sql );
    my $st       = 0;
    my $st2      = 0;
    my $dbLC     = '';
    my $newToken = '';
    my $IPToken  = '';
    my $now      = time();
    my $m;
    my $badpw    = 1;
    my $disabled = 0;
    my $uid;

    # override default and cookie values, if inputs exist;
    if ( $inUser || $hashCode ) {
        $User = $inUser;
        $Pass = $inPass;
        ( $Pass, $m ) = &encrypt($Pass) if $Pass;

        if ($User) {
            my $dbpw = '';

        # this is wacky, but the cleanest way of transitioning pw methodology:
            $sql = "SELECT UserID, Password FROM Users WHERE UserName = ?";
            $st  = $self->{'config'}->db->prepare($sql);
            $st->execute($User);
            $st->bind_columns( \%attr, \$uid, \$dbpw );
            if ( $st->fetch() ) {

                # we got the encrypted pw from the db, now we need to compare
                if ( &check_password( $inPass, $dbpw ) ) {

                    # we're good
                    $badpw = 0;
                }
                elsif ( $dbpw eq $m || &check_password( $m, $dbpw ) )
                {    #either the db version is md5 or it's bc-wrapped md5

                    # update the dbpw:
                    $badpw = 0;
                    $sql = "UPDATE Users SET Password = ? WHERE UserName = ?";
                    $st  = $self->{'config'}->db->prepare($sql);
                    $st->execute( $Pass, $User );
                }
                else {
                    $badpw = 1;    #bad pw
                }
            }
            if ( !$badpw ) {
                $sql
                    = "SELECT UserID, UserName, LanguageCode, Features, RealEmail, PendingEmail,
         Prefix, NumDeleted, NumForwarded, PendingHashCode, DefaultNumber FROM Users
         WHERE (UserName = ?);";
                $st = $self->{'config'}->db->prepare($sql);
                $st->execute($User);
            }
        }
        else {    # login based on $hashcode
            $sql = "SELECT UserID FROM Users WHERE PendingHashCode = ?";
            $st  = $self->{'config'}->db->prepare($sql);
            $st->execute($hashCode);
            $st->bind_columns( \%attr, \$uid );
            $badpw = 0 if $st->fetch();
        }

        if ( !$badpw && $uid ) {
            my $existingToken;
            my $tokenToSet;
            $sql
                = "SELECT UserID, UserName, LanguageCode, Features, RealEmail, PendingEmail, SessionToken,
       Prefix, NumDeleted, NumForwarded, PendingHashCode, DefaultNumber FROM Users
       WHERE (UserID = ?);";
            $st = $self->{'config'}->db->prepare($sql);
            $st->execute($uid);
            $st->bind_columns(
                \%attr,                   \$self->{'UserID'},
                \$self->{'UserName'},     \$dbLC,
                \$self->{'Features'},     \$self->{'RealEmail'},
                \$self->{'PendingEmail'}, \$existingToken,
                \$self->{'Prefix'},       \$self->{'NumDeleted'},
                \$self->{'NumForwarded'}, \$self->{'PendingHashCode'},
                \$self->{'DefaultNumber'}
            );
            $st->fetch();

            if (!$self->hasFeature(
                    $self->{'config'}->getFeature('ACCOUNTDISABLED'),
                    $self->{'Features'}
                )
                )
            {
                if ( $self->{'query'}->param('languageCode')
                    && ( $self->{'query'}->param('languageCode') ne $dbLC ) )
                {
                    $sql
                        = "UPDATE Users SET LanguageCode = ? WHERE UserID = ?;";
                    $st2 = $self->{'config'}->db->prepare($sql);
                    $st2->execute( $self->{'query'}->param('languageCode'),
                        $self->{'UserID'} );
                }
                else {
                    $self->{'LanguageCode'} = $dbLC;
                    $self->setCookies( 'languageCode',
                        $self->{'LanguageCode'} );
                    $self->{'dialogs'} = Mail::Spamgourmet::Dialogs->new(
                        config       => $self->{'config'},
                        languageCode => $self->{'LanguageCode'}
                    );
                }

                ## update pw with md5 hash, if appropriate...
           #        if ($checkpw && $Pass && $checkpw eq $Pass) {
           #          $sql = 'UPDATE Users SET Password = ? WHERE UserID = ?';
           #          $st2 = $self->{'config'}->db->prepare($sql);
           #          $st2->execute($m , $self->{'UserID'});
           #        }

                if ( !$existingToken ) {
                    $newToken = &getNewToken($User);
                    $IPToken  = &getIPToken($newToken);

                    $sql
                        = 'UPDATE Users SET SessionToken = ?, LastCommand = ? WHERE UserID = ?';
                    $st2 = $self->{'config'}->db->prepare($sql);
                    $st2->execute( $IPToken, $now, $self->{'UserID'} );
                    $tokenToSet = $newToken;
                }
                else {
                    $tokenToSet = $existingToken;
                }
                $self->setCookies( 'token', $tokenToSet );
                $self->{'loginmsg'} = $self->{'dialogs'}
                    ->get( 'loggedinas', 'user', $self->{'UserName'} );
            }
            else {
                $disabled = 1;
                $self->{'UserID'} = 0;
                $self->{'loginmsg'}
                    = $self->{'dialogs'}->get('accountdisabled');
            }
        }
        elsif ($inUser) {
            $self->{'loginmsg'}
                = $self->{'dialogs'}->get('badusernamepassword');
        }
    }
    if ( !$self->{'UserID'} && !$disabled ) {  # if we're not logged in yet...
        if ($token) {    # do a cookie-based login locally
            $IPToken = &getIPToken($token);
            $sql
                = "SELECT UserID, UserName, LanguageCode, Features,  RealEmail, PendingEmail,
       Prefix, NumDeleted, NumForwarded, LastCommand, DefaultNumber
       FROM Users WHERE (SessionToken = ?);";
            $st = $self->{'config'}->db->prepare($sql);
            $st->execute($IPToken);
            $st->bind_columns(
                \%attr,                   \$self->{'UserID'},
                \$self->{'UserName'},     \$dbLC,
                \$self->{'Features'},     \$self->{'RealEmail'},
                \$self->{'PendingEmail'}, \$self->{'Prefix'},
                \$self->{'NumDeleted'},   \$self->{'NumForwarded'},
                \$self->{'LastCommand'},  \$self->{'DefaultNumber'}
            );
            if ( $st->fetch ) {
## todo - login timeout check here
                if (!$self->hasFeature(
                        $self->{'config'}->getFeature('ACCOUNTDISABLED'),
                        $self->{'Features'}
                    )
                    )
                {

                    if ($self->{'query'}->param('languageCode')
                        && (
                            $self->{'query'}->param('languageCode') ne $dbLC )
                        )
                    {
                        $sql
                            = "UPDATE Users SET LanguageCode = ? WHERE UserID = ?;";
                        $st2 = $self->{'config'}->db->prepare($sql);
                        $st2->execute(
                            $self->{'query'}->param('languageCode'),
                            $self->{'UserID'} );
                    }
                    else {
                        $self->{'LanguageCode'} = $dbLC;
                        $self->setCookies( 'languageCode',
                            $self->{'LanguageCode'} );
                        $self->{'dialogs'} = Mail::Spamgourmet::Dialogs->new(
                            config       => $self->{'config'},
                            languageCode => $self->{'LanguageCode'}
                        );
                    }

                    $sql
                        = 'UPDATE Users SET SessionToken = ?, LastCommand = ? WHERE UserID = ?';
                    $st2 = $self->{'config'}->db->prepare($sql);
                    $st2->execute( $IPToken, $now, $self->{'UserID'} );

                    $self->{'loginmsg'} = $self->{'dialogs'}
                        ->get( 'loggedinas', 'user', $self->{'UserName'} );
                }
                else {
                    $disabled = 1;
                    $self->{'UserID'} = 0;
                    $self->{'loginmsg'}
                        = $self->{'dialogs'}->get('accountdisabled');
                }
            }
            else {
                $self->{'loginmsg'}
                    .= $self->{'dialogs'}->get('loginproblem');
                $self->setCookies( 'token', '' );    # clear the stale token
            }
        }
    }
    $self->{'NumDeleted'}
        = $self->getWebUtil()->commify( $self->{'NumDeleted'} );
    $self->{'NumForwarded'}
        = $self->getWebUtil()->commify( $self->{'NumForwarded'} );
    $self->{'LanguageCode'} = $_defaultLanguageCode
        if !$self->{'LanguageCode'};
    $self->{'UserID'} = 0 if !$self->{'UserID'};
    return $self;
}

sub getNewToken {
    my $user = shift;
    $user = 'abcd' if !$user;
    my $token = $user . rand() . time();
    $token = &encrypt($token);
    $token = substr( $token, 0, 16 );
    return $token;
}

sub getIPToken {
    my $token = shift;

    #my $IPAddress = $ENV{'REMOTE_ADDR'};
    # aol often switches IP addresses - this pull it back to the class B
    #  $ENV{'REMOTE_ADDR'} =~ /(\d\.\d)/;
    #  my $IPAddress = $1;
    #  return  &encrypt($token . $IPAddress);
    return $token;    # note - disabling this...
}

sub getNewImageHash {
    my $self   = shift;
    my $u      = shift;
    my $w      = shift;
    my $phrase = $self->{'config'}->getSecretPhrase();
    return &encrypt( $u . $w . $phrase );

}

sub checkForExistingUserName {
    my $self  = shift;
    my $u     = shift;
    my $check = 0;
    my ( $sql, $st, %attr, $uid );
    $sql = "SELECT UserID FROM Users WHERE UserName = ?;";
    $st  = $self->{'config'}->db->prepare($sql);
    $st->execute($u);
    $st->bind_columns( \%attr, \$uid );

    if ( !$st->fetch() ) {
        $sql = "SELECT AdminEmailID FROM AdminEmail WHERE AdminUser = ?;";
        $st  = $self->{'config'}->db->prepare($sql);
        $st->execute($u);
        $st->bind_columns( \%attr, \$uid );
        if ( $st->fetch() ) {
            $check = 1;
        }
    }
    else {
        $check = 1;
    }
    return $check;
}

sub checkForTooManyAccountsFromIPAddress {
    my $self      = shift;
    my $now       = shift;
    my $ipaddress = shift;
    my $check     = 0;
    my ( $sql, $st, %attr, $uid );
    my $hourago = $now - 3600;

    $sql = "SELECT COUNT(1) FROM Users WHERE TimeAdded > ? AND IPAddress = ?";
    $st  = $self->{'config'}->db->prepare($sql);
    $st->execute( $hourago, $ipaddress );
    $st->bind_columns( \%attr, \$check );
    $st->fetch();
    $check = 0 if $check < 3;
    return $check;
}

sub newuser {
    my $self = shift;
    my ( $u, $p, $c, $iw, $ih ) = @_;
    my ( $st, $sql, %attr, $uid, $newToken, $IPToken );
    my $now = time();

    if ( $self->checkForExistingUserName($u) ) {
        $self->{'loginmsg'}
            = $self->{'dialogs'}->get( 'usernametaken', 'username', $u );

    }
    elsif ( $u =~ /\./ ) {
        $self->{'loginmsg'}
            = $self->{'dialogs'}
            ->get( 'badcharacterinusername', 'character', 'dot', 'username',
            $u );

    }
    else {
        my $newhash = $self->getNewImageHash( $u, $iw )
            ; #make a new hash from the user input to see if it matches the old
        if ( $self->{'config'}->getCaptchagenHost() && $newhash ne $ih ) {
            $self->{'loginmsg'}
                = $self->{'dialogs'}->get('imagewordmismatch');
            my $word = $self->getImageWord();
            $self->{'imagefilename'} = $self->getNewImageFilename($word);
            $self->{'imagehash'}
                = $self->getNewImageHash( $self->{'query'}->param('newuser'),
                $word, $self->{'config'}->getSecretPhrase() );

        }
        elsif ( $p ne $c ) {
            $self->{'loginmsg'} = $self->{'dialogs'}->get('passwordmismatch');
        }
        else {
            # come back here
            ( $p, undef ) = &encrypt($p);
            my $activeLC = $self->{'query'}->param('languageCode');
            $activeLC = "" if !$activeLC;
            $newToken = &getNewToken($u);
            $IPToken  = &getIPToken($newToken);
            $sql
                = "INSERT INTO Users (UserName,Password,TimeAdded,IPAddress,LanguageCode,SessionToken,LastCommand)
       VALUES (?, ?, ?, ?, ?, ?, ?);";
            $st = $self->{'config'}->db->prepare($sql);
            $st->execute( $u, $p, $now, 0, $activeLC, $IPToken, $now );
            $sql
                = "SELECT UserID FROM Users WHERE UserName = ? AND TimeAdded = ?;";
            $st = $self->{'config'}->db->prepare($sql);
            $st->execute( $u, $now );
            $st->bind_columns( \%attr, \$self->{'UserID'} );
            $st->fetch();

            $self->setCookies( 'token', $newToken );
            $self->{'loginmsg'}
                = $self->{'dialogs'}->get( 'loggedinas', 'user', $u );

            my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst )
                = localtime(time);
            $mon++;
            $year = int($year);
            $year += 1900 if $year < 1900;
            my $day = "$year-$mon-$mday";
            $sql = "SELECT CounterID FROM Counter WHERE CountDate = '$day';";

            if ( $self->{'config'}->db->selectrow_array($sql) ) {
                $sql
                    = "UPDATE Counter SET NewUsers = (NewUsers + 1) WHERE CountDate = '$day';";
            }
            else {
                $sql
                    = "INSERT INTO Counter (CountDate,NewUsers) VALUES ('$day',1);";
            }
            $self->{'config'}->db->do($sql);
        }
    }

    return $self;
}

sub newpassword {
    my $self = shift;
    my ( $p, $c, $cu ) = @_;
    my $m;
    my ( $sql, $st, $dbpw, %attr );
    my $ok = 0;

    if ( $p ne $c ) {
        $self->{'loginmsg'} = $self->{'dialogs'}->get('passwordmismatch');
    }
    elsif ($self->{'PendingHashCode'}
        && $self->{'PendingHashCode'} eq $self->{'query'}->param('hc') )
    {
        $ok = 1;
    }
    else {
        ( undef, $m ) = &encrypt($cu);
        my $u = $self->{'UserID'};
        $sql = "SELECT Password FROM Users WHERE UserID = ?;";
        $st  = $self->{'config'}->db->prepare($sql);
        $st->execute($u);
        $st->bind_columns( \%attr, \$dbpw );
        $st->fetch();
        if ( !&check_password( $cu, $dbpw ) && $dbpw ne $m ) {
            $self->{'loginmsg'} = $self->{'dialogs'}->get('badpassword');
        }
        else {
            $ok = 1;
        }
    }
    if ($ok) {
        ( $p, $m ) = &encrypt($p);
        my $u = $self->{'UserID'};
        $sql
            = "UPDATE Users SET Password = ?, PendingHashCode = ? WHERE UserID = ?;";
        $st = $self->{'config'}->db->prepare($sql);
        $st->execute( $p, '', $u );
        $self->{'loginmsg'} = $self->{'dialogs'}->get('passwordchanged');
    }

# $self->{'loginmsg'} = "phc: " . $self->{'PendingHashCode'} . " hc: " . $self->query->param('hc');
    return $self;
}

sub RealEmail {
    my $self = shift;
    my $new  = shift;
    $self->{'RealEmail'} = $new if $new;
    $self->{'RealEmail'} = ''   if $new && $new eq '_NULL';
    $self->{'RealEmail'};
}

sub PendingEmail {
    my $self = shift;
    my $new  = shift;
    $self->{'PendingEmail'} = $new if $new;
    $self->{'PendingEmail'} = ''   if $new && $new eq '_NULL';
    $self->{'PendingEmail'};
}

sub Prefix {
    my $self = shift;
    my $new  = shift;
    $self->{'Prefix'} = $new if $new;
    $self->{'Prefix'} = ''   if $new && $new eq '_NULL';
    $self->{'Prefix'};
}

sub getUserID {
    my $self = shift;
    return $self->{'UserID'};
}

sub logout {
    my $self = shift;
    if ( $self->{'query'}->cookie('token') ) {
        my $IPToken = &getIPToken( $self->{'query'}->cookie('token') );
        my $sql
            = "UPDATE Users SET SessionToken = '', LastCommand = 0 WHERE SessionToken = ?;";
        my $st = $self->{'config'}->db->prepare($sql);
        $st->execute($IPToken);
    }
    $self->setCookies( 'token', '' );
    $self->{'UserID'} = 0;
    return $self;
}

sub setCookies {
    my $self     = shift;
    my @encoding = ( '\%', '\+', '\;', '\,', '\=', '\&', '\:\:', '\s' );
    my %encoding = (
        '\%',   '%25',    '\+', '%2B', '\;', '%3B',
        '\,',   '%2C',    '\=', '%3D', '\&', '%26',
        '\:\:', '%3A%3A', '\s', '+'
    );
    my @giveyoucookies = @_;
    my ( $giveyoucookie, $value, $cookiechar );

    #  my $httpd = 1;
    my $expires = '';

    #  if ($httpd == 2) {
    #    print "Set-Cookie: ";
    #    while(($giveyoucookie,$value) = @giveyoucookies ) {
    #      foreach $cookiechar (@encoding) {
    #        $giveyoucookie =~ s/$cookiechar/$encoding{$cookiechar}/g;
    #        $value =~ s/$cookiechar/$encoding{$cookiechar}/g;
    #      }
    #      print $giveyoucookie, "=",  $value,  ";expires=never";
    #      shift(@giveyoucookies); shift(@giveyoucookies);
    #    }
    #    print "\n";
    #  } else {
    while ( ( $giveyoucookie, $value ) = @giveyoucookies ) {
        foreach $cookiechar (@encoding) {
            $expires = '';
            $giveyoucookie =~ s/$cookiechar/$encoding{$cookiechar}/g;
            $value         =~ s/$cookiechar/$encoding{$cookiechar}/g;
            if ( $giveyoucookie eq 'token' && $self->param('rememberme') ) {
                $expires = 'expires=Wed, 31 Dec 2036 00:00:00 UTC';
            }
        }
        my $secure = '';
        $secure = 'Secure;' unless $giveyoucookie eq 'languageCode';
        my $httponly = '';
        $httponly = 'httponly;' unless $giveyoucookie eq 'languageCode';
        print "Set-Cookie: ", $giveyoucookie, "=", $value,
            ";path=/;$httponly$secure$expires\n";
        shift(@giveyoucookies);
        shift(@giveyoucookies);
    }

    #  }
}

sub encrypt {

    # use system to perform one way encryption
    my $instr = shift;
    my $salt  = &salt();               #substr($instr,0,1);
    my $md5   = &encryptMD5($instr);
    $instr = &encrypt_password( $instr, $salt );
    return ( $instr, $md5 );
}

sub encryptMD5 {    # really weak - don't use for passwords
    my $instr = shift;
    return substr( md5_hex($instr), 22, 32 );
}

# thanks gcrawshaw/gist:1071698 !
# Encrypt a password
sub encrypt_password {
    my $password = shift;
    my $salt     = shift || &salt();

    # Set the cost to 12 and append a NUL
    my $settings = '$2a$12$' . $salt;
    return Crypt::Eksblowfish::Bcrypt::bcrypt( $password, $settings );
}

# Check if the passwords match
sub check_password {
    my ( $plain_password, $hashed_password ) = @_;
    if ( $hashed_password =~ m!^\$2a\$\d{2}\$([A-Za-z0-9+\\.\/]{22})! ) {
        my $match = encrypt_password( $plain_password, $1 );
        my $bad   = 0;
        for ( my $n = 0; $n < length $match; $n++ ) {
            $bad++
                if substr( $match, $n, 1 ) ne
                substr( $hashed_password, $n, 1 );
        }
        return $bad == 0;
    }
    else {
        return 0;
    }
}

# Return a salt
sub salt {
    return Crypt::Eksblowfish::Bcrypt::en_base64(
        Crypt::Random::makerandom_octet( Length => 16 ) );
}

sub hasFeature {
    my $self    = shift;
    my $feature = shift;
    return $self->getWebUtil()->hasFeature( $feature, $self->{'Features'} );
}

sub addFeature {
    my $self    = shift;
    my $feature = shift;
    $self->{'Features'}
        = $self->getWebUtil()->addFeature( $feature, $self->{'Features'} );
}

sub clearFeature {
    my $self    = shift;
    my $feature = shift;
    $self->{'Features'}
        = $self->getWebUtil()->clearFeature( $feature, $self->{'Features'} );
}

sub DESTROY { }

1;
