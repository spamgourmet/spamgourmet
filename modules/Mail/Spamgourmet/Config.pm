package Mail::Spamgourmet::Config;
use strict;
use vars qw{%localdomains $websessiontimeout $dbstring $dbuser $dbpassword $webapproot 
            $webtemplatedir $mailprogram $directorydelimiter $debugmode $debugfilename
            $uselocalfilecache $localfilecachetimeout $secretphrase $delimiters
            $captchagenhost $captchagenport $dictionaryfile $admindomain 
            $secureURL $normalURL $secureimageshost $normalimageshost $chartserver
            $mailhost $useunixaccounts $adminemail $adminaccount $otherdomainemail 
            $numberofeatenmessagestolog $recthrottleinterval $maxreccount
            $sendthrottleinterval $maxsendcount $maxexpireperiod

            $mailerclass

            %FEATURES $_configFileLoaded};
            
$_configFileLoaded = 0;
use constant EX_TEMPFAIL    => 75; # temp failure; user is invited to retry
$FEATURES{'MASKFORWARD'} = 2;
$FEATURES{'WATCHWORDS'} = 3;
$FEATURES{'LEGACYPREFIX'} = 5;
$FEATURES{'EATENMESSAGELOG'} = 7;
$FEATURES{'DONOTLOGHIDDEN'} = 11;
$FEATURES{'ACCOUNTDISABLED'} = 13;
$FEATURES{'DISABLETAGLINE'} = 17;
$FEATURES{'DONOTMATCHRECIP'} = 19;
$FEATURES{'DISABLETAGLINETRUSTEDEXCLUSIVE'} = 23;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self,$class;
  my %params = @_;
  if (!$_configFileLoaded) {
    my $configfile = $params{'configfile'};
    require "$configfile";
    $_configFileLoaded = 1;
  }

  if (defined($params{'mode'})) {
    $self->{'mode'} = $params{'mode'};  # 0 for mail, 1 for web
  } else {
    $self->{'mode'} = 1; # default to web
  }

  $self->{'websessiontimeout'} = $websessiontimeout;  # default timeout in seconds
  $self->{'dbstring'} = $dbstring;
  $self->{'dbuser'} = $dbuser;
  $self->{'dbpassword'} = $dbpassword;
  $self->{'webapproot'} = $webapproot;
  $self->{'webtemplatedir'} = $webtemplatedir;
  $self->{'mailprogram'} = $mailprogram;
  $self->{'directorydelimiter'} = $directorydelimiter;
  $self->{'debugmode'} = $debugmode;
  $self->{'debugfilename'} = $debugfilename;
  $self->{'uselocalfilecache'} = $uselocalfilecache;
  $self->{'localfilecachetimeout'} = $localfilecachetimeout; # seconds to time out local file caches
  $self->{'secretphrase'} = $secretphrase;
  $self->{'captchagenhost'} = $captchagenhost;
  $self->{'captchagenport'} = $captchagenport;
  $self->{'dictionaryfile'} = $dictionaryfile;

  $self->{'secureURL'} = $secureURL;
  $self->{'normalURL'} = $normalURL;
  $self->{'secureimageshost'} = $secureimageshost;
  $self->{'normalimageshost'} = $normalimageshost;
  $self->{'chartserver'} = $chartserver;

  $self->{'maxexpireperiod'} = $maxexpireperiod;

  $self->{'mailhost'} = $mailhost;
  $self->{'useunixaccounts'} = $useunixaccounts;
  $self->{'adminemail'} = $adminemail;
  $self->{'adminaccount'} = $adminaccount;
  $self->{'otherdomainemail'} = $otherdomainemail;
  $self->{'numberofeatenmessagestolog'} = $numberofeatenmessagestolog;
  $self->{'recthrottleinterval'} = $recthrottleinterval;
  $self->{'maxreccount'} = $maxreccount;
  $self->{'sendthrottleinterval'} = $sendthrottleinterval;
  $self->{'maxsendcount'} = $maxsendcount;
  $self->{'delimiters'} = $delimiters;

  $self->{'mailerclass'} = $mailerclass;
  $self->{'mailer'} = 0;

  $self->{'admindomain'} = $admindomain;
  $self->{'error'} = '';
  $self->{'dberror'} = '';
  return bless ($self,$class);
}

sub getMailer {
  my $self = shift;
  if (!$self->{'mailer'}) {
    my $mailerclass = $self->{'mailerclass'};
    eval "require $mailerclass";
    $self->{'mailer'} = $mailerclass->new(config=>$self);
  }
  return $self->{'mailer'};
}


sub getMailerClass {
  my $self = shift;
  return $self->getMailerClass();
}

sub getWebTemplateDir {
  my $self = shift;
  return $self->{'webtemplatedir'};
}

sub getFeature {
  my $self = shift;
  my $featureword = shift;
  return $FEATURES{$featureword};
}

sub getDelimiters {
  my $self = shift;
  return $self->{'delimiters'};
}

sub getMailProgram {
  my $self = shift;
  return $self->{'mailprogram'};
}

sub getRecThrottleInterval {
  my $self = shift;
  return $self->{'recthrottleinterval'};
}
sub getMaxRecCount {
  my $self = shift;
  return $self->{'maxreccount'};
}
sub getSendThrottleInterval {
  my $self = shift;
  return $self->{'sendthrottleinterval'};
}
sub getMaxSendCount {
  my $self = shift;
  return $self->{'maxsendcount'};
}

sub getMailHost {
  my $self = shift;
  return $self->{'mailhost'};
}

sub useUnixAccounts {
  my $self = shift;
  return $self->{'useunixaccounts'};
}

#sub getAdminEmail {
#  my $self = shift;
#  return $self->{'adminemail'};
#}

sub getAdminEmail {
  my $self = shift;
  my $username = shift;
  my $ret = '';
  my $adminaccount = $self->getAdminAccount();
  my $admindomain = $self->getAdminDomain();
  if ($adminaccount && $admindomain && $username) {
    $ret = "$username.$adminaccount\@$admindomain";
  } else {
    $ret = $self->{'adminemail'};
  }
  return $ret;
}



sub getAdminAccount {
  my $self = shift;
  return $self->{'adminaccount'};
}

sub getOtherDomainEmail {
  my $self = shift;
  return $self->{'otherdomainemail'};
}

sub getNumberOfEatenMessagesToLog {
  my $self = shift;
  return $self->{'numberofeatenmessagestolog'};
}

sub getDirectoryDelimiter {
  my $self = shift;
  return $self->{'directorydelimiter'};
}

sub getSecretPhrase {
  my $self = shift;
  return $self->{'secretphrase'};
}
sub getCaptchagenHost {
  my $self = shift;
  return $self->{'captchagenhost'};
}
sub getCaptchagenPort {
  my $self = shift;
  return $self->{'captchagenport'};
}

sub getAdminDomain {
  my $self = shift;
  return $self->{'admindomain'};
}

sub getConfigParameter {
  my $self = shift;
  my $param = shift;
  return $self->{$param};
}

sub uselocalfilecache {
  my $self = shift;
  return $self->{'uselocalfilecache'};
}

sub localfilecachetimeout {
  my $self = shift;
  return $self->{'localfilecachetimeout'};
}

sub getDBConnection {
  my $self = shift;
#  my $tries = 0;
#  while (!defined($self->{'db'}) && $tries < 3) {
#    $self->{'db'} = DBI->connect($self->{'dbstring'},$self->{'dbuser'},$self->{'dbpassword'});
#    if (!defined($self->{'db'})) {
#      $tries++;
#      sleep 2;
#    }
#  }
#  if(!defined($self->{'db'})) {
#   $self->{'dberror'} = $DBI::errstr;
#   # die "$DBI::errstr\n";
#  }

  my $connectTries = 0;
  my $interval = 6; # crisis mode
  my $connected = 0;
  while (!$connected && $connectTries < 50) {
    $connected = $self->{'db'} = DBI->connect($self->{'dbstring'},$self->{'dbuser'},$self->{'dbpassword'});
    if (!$connected) {
  $self->debug("failed attempt to connect - try number: $connectTries");
      sleep $interval;
    }
    $connectTries ++;
    $interval = 15 if ($connectTries > 10); # emergency mode
    $interval = 120 if ($connectTries > 20); # apocalypse mode
  }
  if (!$connected) {
    $self->debug("could not connect to db: $DBI::errstr\n");
    die EX_TEMPFAIL if $self->{'mode'} == 0; # if we're running under sendmail, we want to issue a TEMPFAIL
  }
}




sub checkstatus {
  my $self = shift;
  if (!$self->dbstatus()) {
    $self->getDBConnection();
  }
  return $self->dbstatus();
}

sub dbstatus {
  my $self = shift;
  return defined($self->{'db'});
}

sub dberror {
  my $self = shift;
  return $self->{'dberror'};
}

sub getLocalDomains {
  my $self = shift;
  return sort keys(%localdomains);
}

sub isLocalDomain {
  my $self = shift;
  my $domain = shift;
  return $localdomains{lc($domain)};
}

sub hasLocalDomain {
  my $self = shift;
  my $adr = shift;
  $adr =~ /.*\@(.*)/;
  return $self->isLocalDomain($1);
}

sub connect_string {
  my $self = shift;
  return ($self->{'dbstring'},$self->{'dbuser'},$self->{'dbpassword'});
}

sub db {
  my $self = shift;
  if (!defined($self->{'db'})) {
    $self->getDBConnection();
  }
#  $self->debug("db called..."); 
  return $self->{'db'};
}

sub prepare {
  my $self = shift;
  my $sql = shift;
  return $self->db->prepare($sql);
}




sub debug {
  my $self = shift;
  my $chunk = shift;
  if ($self->{'debugmode'} && $self->{'debugfilename'}) {
    my $now = $self->formatNumDate(time());
    my $file = $self->{'debugfilename'};
    open(FILE, ">>$file");
    print FILE "$now [$$]: ";
    print FILE $chunk;
    print FILE "\n";
    close FILE;
    #print $chunk . "\n";
  }
}

sub formatNumDate {
  my $self = shift;
  my $DateTime = shift;
  my $dateOnly = shift;
  if ($DateTime) {
    my($sec,$min,$hour,$Mdays,$Mons,$Years,$wday,$yday,$isdst)=(0,0,0,0,0,0,0,0,0);
    ($sec,$min,$hour,$Mdays,$Mons,$Years,$wday,$yday,$isdst) = localtime($DateTime);
    $Years = $Years + 1900;
    $Mons = int($Mons+1);
    $Mons = "0$Mons" unless ($Mons>9);
    $Mdays = "0$Mdays" unless ($Mdays>9);
    if ($dateOnly) {
      $DateTime = "$Years-$Mons-$Mdays";
    } else {
      $hour = "0$hour" unless ($hour>9);
      $min = "0$min" unless ($min>9);
      $DateTime = "$Years-$Mons-$Mdays $hour:$min";
    }
  }
  return $DateTime;
}

sub getMaxExpirePeriod {
  my $self = shift;
  return $self->{'maxexpireperiod'};
}


sub die {
  my $self = shift;
  $self->{'db'}->disconnect() if $self->{'db'};
  return;
}

1;
