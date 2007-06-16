package Mail::Spamgourmet::MessageIdChecker;
use strict;
use File::stat;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self,$class;
  my %params = @_;
  if ($params{'config'}) {
    $self->{'config'} = $params{'config'};
  } else {
    die 'MessageIdChecker must be initialized with an instance of Mail::Spamgourmet::Config.pm';
  }
  $self->{'tmpdir'} = $ENV{'tmp'} || '/tmp';
  $self->{'tmpdir'} .= '/spamgourmet/';
  if (! -e $self->{'tmpdir'}) {
    mkdir $self->{'tmpdir'};
  }
  $self->cleanup();
  return $self;
}

sub clearMessageId {
  my $self = shift;
  my $rawId = shift;
  return $self->checkMessageId($rawId,1);
}

sub checkMessageId {
  my $self = shift;
  my $rawId = shift;
  my $clearId = shift;
  my $existed = 0;
  if ($rawId) {
    my $id = $rawId;
    $id =~ s/\W//g;
    $id =~ s/^(........)(.*)/$2$1/; #move the first 8 chars to the end - they're usually the date 
    my ($d1, $d2) = (substr($id,0,1),substr($id,1,1));
    my $basedir = $self->{'tmpdir'} . $d1;
    if (! -e $basedir) {
      mkdir $basedir;
    }
    $basedir .= "/$d2";
    if (! -e $basedir) {
      mkdir $basedir;
    }
    my $path = "$basedir/$id";
    $self->cleanup($basedir);
    if (-e $path) {
      if (!$clearId) {
        $existed = 1;
      } else {
        unlink $path;
      }
    } elsif (!$clearId) {
      open (FILE,">$path");
      close FILE;
    }
  }
  return $existed;
}


## this sub examines the temp directory in order to delete directories
## that are more than 10 minutes old.  It saves state for the last
## examination as the __state file -- if this file is less
## than 10 minutes old, it skips the examination
sub cleanup {
  my $self = shift;
  my $dir = shift;
  my $statefile = $dir . '/__state'; # state file is __state
  my $nowtime = scalar time;
  my $stateCheckPeriod = 600;
  my $cleanupPeriod = 3600;
  my $fullpath;
  my $sb;
  if (-e $statefile) {
    my $ftime = scalar stat($statefile)->mtime;
    if ($nowtime > $ftime + $stateCheckPeriod) {
#$self->{'config'}->debug("in cleanup routine");
      opendir(DIR, $dir); # open the temp dir
      my $file = '';
      while (defined($file = readdir(DIR))) {
       # if the files in the temp dir are more than cleanupPeriod
       # old -- delete them.
        if ($file && $file ne '.' && $file ne '..' && $file ne '__state') {
          $fullpath = "$dir/$file";
          $sb = stat($fullpath);
          if ($sb) {
            $ftime = scalar $sb->mtime;
            if ($nowtime > $ftime + $cleanupPeriod) {
#$self->{'config'}->debug("unlinking $fullpath");
              unlink $fullpath;
            }
          }
        }
      }
      close DIR;
      open (FILE,">$statefile");
      close FILE;
#$self->{'config'}->debug("finished cleanup routine");
    }
  } else {
    open (FILE,">$statefile");
    close FILE;  
  }
}


1;
