package Mail::Spamgourmet::CommandLineMailer;
use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self,$class;
  my %params = @_;
  if ($params{'config'}) {
    $self->{'config'} = $params{'config'};
  } else {
    die 'CommandLineMailer must be initialized with an instance of Mail::Spamgourmet::Config.pm';
  }
  return $self;
}

sub sendMail {
  my $self = shift;
  my $msgref = shift;
  my $rcpt = shift;
  my $sender = shift;
  return if !$rcpt;
  my $dashf = '';
  $dashf = " -f\"$sender\"" if $sender;
  my $mailprogram = $self->{'config'}->getMailProgram();
  open (MAIL, "|$mailprogram$dashf \"$rcpt\"");
  print MAIL $$msgref;
  close MAIL;
#  $self->{'config'}->debug("sent message to $rcpt");
  return;
}

1;
