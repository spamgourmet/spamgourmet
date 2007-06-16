package Mail::Spamgourmet::SocketMailer;
use strict;
use Socket;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self,$class;
  my %params = @_;
  if ($params{'config'}) {
    $self->{'config'} = $params{'config'};
  } else {
    die 'SocketMailer must be initialized with an instance of Mail::Spamgourmet::Config.pm';
  }
  return $self;
}

sub sendMail {
  my $self = shift;
  my $msgref = shift;
  my $rcpt = shift;
  my $sender = shift;
  return if !$rcpt;

  $self->{'config'}->debug("sending message");
  my $error = 0;
  my ($site,@parts,$hostaddr,$sockaddr,
   $there,$response,$tries,
   $a,$b,$c,$d,$proto,$line);
  my $server = $self->getConfig()->getMailHost();
  my $port = 25;

  ($sockaddr,$there,$response,$tries) = ("Snc4x8");
  $there = pack($sockaddr,2,$port,&getaddress($server));
  ($a, $b, $c, $d) = unpack('C4', $hostaddr);
  $proto = (getprotobyname ('tcp'))[2];

  if (!socket(S,AF_INET,SOCK_STREAM,$proto)) {
    $self->{'config'}->debug("$0:  Fatal Error.  $!");
    $error = 1;
  }
  if (!$error && connect(S,$there)) {
    select(S);$|=1;
    select(STDOUT);
    print S "HELO spamgourmet\n";
    $line = <S>; print $line;
    print S "MAIL FROM: $sender\n";
    $line = <S>; print $line;
    foreach $rcpt (split(',',$rcpt)) {
      print S "RCPT TO: $rcpt\n";
      $line = <S>; print $line;
    }
    print S "DATA\n";
    $line = <S>; print $line;
    print S $$msgref;
    print S "\n.\n";
    $line = <S>; print $line;
    close(S);
  } else {
    $self->{'config'}->debug("$0:  Fatal Error.  $!");
    # socket call failed -- need to call command line
    my $mailprogram = $self->{'config'}->getMailProgram();
    open (MAIL, "|$mailprogram $rcpt");
    print MAIL $$msgref;
    close MAIL;
  }
  return;
}


sub getConfig {
  my $self = shift;
  return $self->{'config'};
}

### TODO -- need to handle the situation where the mail server is 
### refusing connections!! --  probably by putting files straight into
### the mail server queue. Another possibility would be to fall back 
### to command line mode.
sub sendThroughSocket {
  my $self = shift;
  my $toadr = shift;
  my $fromadr = shift;
  my $msgref = shift;
  $self->{'config'}->debug("sending message");
  my ($site,@parts,$hostaddr,$sockaddr,
   $there,$response,$tries,
   $a,$b,$c,$d,$proto,$line);
  my $server = $self->getConfig()->getMailHost();
  my $port = 25;

  ($sockaddr,$there,$response,$tries) = ("Snc4x8");
  $there = pack($sockaddr,2,$port,&getaddress($server));
  ($a, $b, $c, $d) = unpack('C4', $hostaddr);
  $proto = (getprotobyname ('tcp'))[2];

  if (!socket(S,AF_INET,SOCK_STREAM,$proto)) { 
    $self->{'config'}->debug("$0:  Fatal Error.  $!"); 
    return 1;
  }
  if (!connect(S,$there)) { 
    $self->{'config'}->debug("$0:  Fatal Error.  $!");
    return 1;
  }
  select(S);$|=1;
  select(STDOUT);
  print S "HELO spamgourmet\n";
  $line = <S>; #print $line;
  print S "MAIL FROM: $fromadr\n";
  $line = <S>; #print $line;
  foreach $toadr (split(',',$toadr)) {
    print S "RCPT TO: $toadr\n";
    $line = <S>; #print $line;
  }
  print S "DATA\n";
  $line = <S>; #print $line;
#  print S "Subject: $subject\n\n";
#  $line = <S>; #print $line;
  print S $$msgref;
  print S "\n.\n";
  $line = <S>; #print $line;
  close(S);
  return 0;
}

sub getaddress {
  my $host = shift;
  my @ary;
  @ary = gethostbyname($host);
  return(unpack("C4",$ary[4]));
}



1;
