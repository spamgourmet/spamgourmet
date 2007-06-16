package Mail::Spamgourmet::Dialogs;
use strict;


my %_dialogs = ();
my $_defaultLanguageCode = 'EN'; # default: config controls
my $_usefilecache = 1; # default: config controls
my $_cachetimeout = 60; # default: config controls

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self,$class;
  my %params = @_;
  if ($params{'config'}) {
    $self->{'config'} = $params{'config'};
  }
  if ($params{'languageCode'}) {
    $self->{'languageCode'} = $params{'languageCode'};
  } else {
    $self->{'languageCode'} = $_defaultLanguageCode;
  }
  $self->{'error'} = '';

  $self->{'usefilecache'} = $_usefilecache;
  $self->{'cachetimeout'} = $_cachetimeout;
  if ($self->{'config'}) {
    $self->{'cachedir'} = $self->{'config'}->{'webtemplatedir'} . 'DialogCache' . $self->{'config'}->getDirectoryDelimiter();
    $self->{'usefilecache'} = $self->{'config'}->uselocalfilecache();
    $self->{'cachetimeout'} = $self->{'config'}->localfilecachetimeout();
  }

  $self->{'initialized'} = 0;
  $self->{'initializing'} = 0;
  $self->initialize();
  return $self;
}

sub initialize {
  my $self = shift;
  if ($self->{'config'} && !%_dialogs) {
    $self->{'initializing'} = 1;

    if ($self->{'usefilecache'}) {
      opendir(DIR, $self->{'cachedir'});
      my $next = '';
      my $filename = 0;
      my $freshcache = 0;
      while (defined($next = readdir DIR)) {
        unless (-d $next) {
          $filename = $next if ($next * 1) > $filename;
        }
      }
      if ($filename) {
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) 
         = stat($self->{'cachedir'}.$filename);
        if (time() - $mtime < $self->{'cachetimeout'}) {
          $freshcache = 1;
          $self->retrieveFromFile($filename, 0);
        }
#$self->{'config'}->debug("freshcache: $freshcache time: " . time() . " mtime: $mtime to: $_cachetimeout");
      }
      if (!$freshcache) {
        my ($st,%attr);
        my $version = 0; 
        my $sql = "SELECT VersionNumber FROM Versions WHERE VersionName = 'Dialogs'";
        $st = $self->{'config'}->db->prepare($sql);
        $st->execute();
        $st->bind_columns(\%attr,\$version);
        $st->fetch();
        if ($version && $self->{'cachedir'} && -e $self->{'cachedir'} . $version) {
          $self->retrieveFromFile($version, $version);
        } else {
          $self->retrieveFromDB($version);
        } 
      }
    } else {
      $self->retrieveFromDB();
    }
    $self->{'initialized'} = 1;
    $self->{'initializing'} = 0;
  }# elsif (%_dialogs) {
 #   $self->{'initialized'} = 1;
 # }
  return $self;
}

sub retrieveFromFile {
  my $self = shift;
  my $filename = shift;
  my $version = shift;
  my $filepath = '';
  if ($self->{'usefilecache'} && $filename) {
    $filepath = $self->{'cachedir'}.$filename;
  }
  if ($filepath && -e $filepath && -r $filepath) {
    open (FILE, "<$filepath");
#    $self->{'config'}->debug("opened file for reading: $filepath");
    my $line = '';
    while (defined($line = <FILE>)) {
      $line =~ /(.*)\|(.*)\|(.*)/;
      $_dialogs{$1}{$2} = $3;
    }
    close (FILE);
    if ($version && $version eq $filename) {
      my $now = time();
      utime($now, $now, $filepath);
    }
  } else {
    $self->retrieveFromDB($version);
  }
}

sub retrieveFromDB {
  my $self = shift;
  my $version = shift; # used only to create file cache
  my ($st,%attr);
  my ($text, $code, $name) = ('','','','');

  my $fileopen = 0;

  my $sql = 'SELECT DialogName, DialogText, LanguageCode
   FROM Dialogs WHERE DialogType = 1';
  $st = $self->{'config'}->db->prepare($sql);
  $st->execute();
  $st->bind_columns(\%attr,\$name,\$text,\$code);

#  $self->{'config'}->debug("ufc is: " . $self->{'usefilecache'} . " and version is $version");

  if ($self->{'usefilecache'} && $version) {
    my $filename = $self->{'cachedir'}.$version;
    open (FILE, ">$filename");
    $fileopen = 1;
#    $self->{'config'}->debug("opened file: $filename");
  }

  while ($st->fetch()) {
    $_dialogs{$code}{$name} = $text;

    if ($fileopen) {
      $text =~ s/\n/ /g;
      $text =~ s/\r/ /g;
      print FILE "$code|$name|$text\n";
    }
  }

  if ($fileopen) {
    close FILE;
  }

}


sub get {
  my (@tag,@string);
  my $i = 0;
  my $self = shift;
  my $name = shift;
  my @args = @_;

## wait while initialing, if necessary...
#  while ($self->{'initializing'}) {
#    if ($i) {return '';}  # don't wait longer than one second;
#    sleep 1;
#    $i++;
#  }
##

  $i = 0;
  my $dialog = $_dialogs{$self->{'languageCode'}}{$name};

  if (!$dialog) {
    $dialog = $_dialogs{$_defaultLanguageCode}{$name};
  }

  while(($tag[$i],$string[$i]) = @args) {
    shift(@args);shift(@args);
#    $string[$i] = '' if !$string[$i];
    $i++;
  }

  foreach $i (0..$#tag) {
    $dialog =~ s/<%$tag[$i]%>/$string[$i]/gi if $tag[$i];
  }
  return $dialog;
}


1;
