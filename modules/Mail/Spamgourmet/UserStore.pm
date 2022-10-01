package Mail::Spamgourmet::UserStore;
use strict;
use utf8;
use lib "/path/to/modules";
use DBD::mysql;


# the current user handling code is in the Session.pm - this is just a
# dummy to create a test user.
my $_config = 0;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self,$class;
  my %params = @_;
  if ($params{'config'}) {
    $self->{'config'} = $params{'config'};
  } elsif ($_config) {
    $self->{'config'} = $_config;
  }
  return $self
}

sub setup_test_user {
    my $self = shift;  
    my $now = time();
    my $activeLC="EN";
    my $sql = "INSERT INTO Users (UserName,Password,TimeAdded,IPAddress,LanguageCode,SessionToken,LastCommand) 
           VALUES (?, ?, ?, ?, ?, ?, ?);";
    my $st = $self->{'config'}->db->prepare($sql);
    $st->execute("test", "dud-password", $now, 0, $activeLC, "junktoken", $now);
}

1;
