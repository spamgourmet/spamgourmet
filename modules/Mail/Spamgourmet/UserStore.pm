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

    # first set up the user
   
    my $sql = "INSERT INTO Users (UserName,RealEmail,Password,TimeAdded,IPAddress,LanguageCode,SessionToken,LastCommand)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?);";
    my $st = $self->{'config'}->db->prepare($sql);
    $st->execute("test", 'testprotected@example.org', "dud-password", $now, 0, $activeLC, "junktoken", $now);

    $self->create_email_address("test")
}


sub create_email_address {

    # now find the user's ID
    my $self = shift; 
    my $User = shift;

    my $sql = "SELECT UserID, Password FROM Users WHERE UserName = ?";
    my $st = $self->{'config'}->db->prepare($sql);
    $st->execute($User);

    my %attr;
    my $uid;
    my $dbpw;

    $st->bind_columns(\%attr,\$uid,\$dbpw);
    $st->fetch();

    my $now = time();

    # now use the ID to ensure that the user has an appropriate
    # protected addres.

    my $sql = "INSERT INTO Emails
       (UserID,Word,InitialCount,Count,TimeAdded,Address,PrivateHash,Sender)
       VALUES (?,?,?,?,?,?,?,?);";
    my $st = $self->{'config'}->db->prepare($sql);
    $st->execute($uid,"junkword",10,10,$now,'junkword.test@example.com',"fakehash",'fakesender@example.org');

    my $sql = "INSERT INTO Emails
       (UserID,Word,InitialCount,Count,TimeAdded,Address,PrivateHash,Sender)
       VALUES (?,?,?,?,?,?,?,?);";
    my $st = $self->{'config'}->db->prepare($sql);
    $st->execute($uid,"exceeded",10,0,$now,'exceeded.test@example.net',"fakehash",'fakesender@example.org');


}

1;
