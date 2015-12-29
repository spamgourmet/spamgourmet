package Mail::Spamgourmet::WebUtil;
use strict;
use vars '@ISA';
use Mail::Spamgourmet::Util;
@ISA = ("Mail::Spamgourmet::Util");

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self,$class;
  my %params = @_;
  if ($params{'config'}) {
    $self->{'config'} = $params{'config'};
  } else {
    die 'WebUtil must be initialized with an instance of Mail::Spamgourmet::Config.pm';
  }

  return $self;
}

sub getRedirectedAddressForWeb {
  my $self = shift;
  my $adr = $self->getRedirectedAddress(shift,shift,shift,shift);
  $adr =~ s/\#/\%23/;
  return $adr;
}

sub deScript {
  my $self = shift;
  my $str = shift;
  $str =~ s/\"/\&\#34\;/g;
  $str =~ s/\'/\&\#39\;/g;
  $str =~ s/\</\&lt\;/g;
  $str =~ s/\>/\&gt\;/g;
  $str;
}


sub commify {
  my $instr = reverse $_[1];
  $instr = 0 if !$instr;
  $instr =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
  return scalar reverse $instr;
}


sub formatNumDate {
  my $self = shift;
  my $DateTime = shift;
  if ($DateTime) {
    my($sec,$min,$hour,$Mdays,$Mons,$Years,$wday,$yday,$isdst)=(0,0,0,0,0,0,0,0,0);
    ($sec,$min,$hour,$Mdays,$Mons,$Years,$wday,$yday,$isdst) = localtime($DateTime);
    $Years = $Years + 1900;
    $Mons = int($Mons+1);
#    my $day = "AM";
#    if($hour>11) {
#      $day = "PM";
#      $hour = $hour - 12 if $hour > 12;
#    }
    $Mons = "0$Mons" unless ($Mons>9);
    $Mdays = "0$Mdays" unless ($Mdays>9);
    $hour = "0$hour" unless ($hour>9);
    $min = "0$min" unless ($min>9);
    $DateTime = "$Years-$Mons-$Mdays $hour:$min";
  }
  return $DateTime;
}

# this method is not used (DBI handles the problem)
sub sanitize {
  my @instr = @_;
  my $instr;
  foreach $instr (@instr) {
    $instr =~ s/\'/\'\'/gi; ## escape single quotes
    $instr =~ s/\;//gi; ## get rid of pesky semicolons
    $instr =~ s/\|//gi; ## and pesky pipes
  }
#  if (@instr > 1) {
    return @instr;
#  } else {
#    return $instr;
#  }
}

sub webSanitize {
  my $self = shift;
  my $instr = shift;
  $instr =~ s/\'//gi; ## get rid of single quotes
  $instr =~ s/\"//gi; ## and double quotes
  $instr =~ s/\(//gi; ## and open parens
  $instr =~ s/\)//gi; ## and closed ones
  $instr =~ s/\://gi; ## and colons
  $instr =~ s/\=//gi; ## and equals signs
  $instr =~ s/\;//gi; ## get rid of pesky semicolons
  $instr =~ s/\|//gi; ## and pesky pipes
  $instr =~ s/\<//gi; ## and HTML stuff
  $instr =~ s/\>//gi; ## and other HTML stuff
  $instr =~ s/\///gi; ## and more
  return $instr;
}


sub getSearchRestriction {
  my $self = shift;
  # $restr = getSearchRestriction($searchterms[separated with spaces],
  #  $searchtype[1=and,2=or,3=exact],@fields)
  my @args = @_;
  my $dbms = 2;  #1 if db support grouping fields with text in SQL...
  my ($searchterms) = shift(@args);
  my ($searchtype) = shift(@args);
  my ($searchrestriction,$operator) = ('AND (','AND');
  $operator = 'OR' if $searchtype == 2;
  ($searchterms) = &sanitize($searchterms);  # call the 'sanitize' function to escape chars, etc.
  if ($searchtype != 3) {
    $searchterms =~ s/^ //;  # cut off leading space
    $searchterms =~ s/ ?//;  # cut off trailing space
  }

  if ($dbms != 1) {
    my @searchparts;
    foreach my $i (0..$#args) {
      $searchparts[$i] = $searchterms;
      if ($searchtype == 1 || $searchtype == 2) {
        $searchparts[$i] =~ s/ +/%' $operator $args[$i] LIKE '%/gi;
      }
      $searchrestriction .= " OR " if $i;
      $searchrestriction .= "($args[$i] LIKE \'%$searchparts[$i]%\')";
    }
    $searchrestriction .= ")";
  } else {  # if the dbms supports field squishing, it's much easier and better.
    my $searchfields;
    foreach my $i (0..$#args) {
      $searchfields .= " + ' ' + " if $searchfields;
      $searchfields .= "$args[$i]";
    }
    if ($searchtype == 1 || $searchtype == 2) {
      $searchterms =~ s/ /%' $operator $searchfields LIKE '%/gi;
    }
    $searchrestriction = "AND ($searchfields LIKE \'%$searchterms%\') ";
  }

  return $searchrestriction;
}



sub highlight {
  my $self = shift;
  my($searchterms,$instr,$color) = @_;
  if ($searchterms) {
    $instr = '' if !$instr;
    $searchterms =~ s/\*//g;
    $searchterms =~ s/\^//g;
    $searchterms =~ s/\?//g;
    $searchterms =~ s/\+/\ /g;
    $searchterms =~ s/^\s//;
    $searchterms =~ s/\s$//;
    my (@terms)=split(/\ /,$searchterms);
    my $i;
    foreach $i (0..$#terms) {
      $instr =~ s/($terms[$i])/<b style=\"background:$color\">$1<\/b>/gi;
    }
  }
  return $instr;
}

sub URLEncode {
  my $self = shift;
  my $param = shift;
  return $param if !$param;
  my @encoding=('\%','\+','\;','\,','\=','\&','\:\:','\s');
  my %encoding=('\%','%25','\+','%2B','\;','%3B','\,','%2C','\=','%3D','\&','%26','\:\:','%3A%3A','\s','+');
#  my $value = '';
  foreach my $encodechar (@encoding) {
    $param =~ s/$encodechar/$encoding{$encodechar}/g;
#    $value =~ s/$encodechar/$encoding{$encodechar}/g;
  }
  return $param;
}

sub XMLEscape {
  my $self = shift;
  my $string = shift;
  return $string if !$string;
  $string =~ s/\&/&amp;/g;
  my %encoding = (
                  '\"','&quot;',
                  '\'','&apos;',
                  '\>','&gt;',
                  '\<','&lt;'
                  );
  my $key;
  foreach $key (keys(%encoding)) {
    $string =~ s/$key/$encoding{$key}/g;
  }
  return $string;
}


sub escapeAngleBrackets {
  my $self = shift;
  my $text = shift;
  if ($text) {
    $text =~ s/\>/\&gt\;/g;
    $text =~ s/\</\&lt\;/g;
  }
  return $text;
}


## simple pattern validation for email addresses
sub looksRight {
  my $self = shift;
  my $addr = shift;
#  if ($addr =~ /\s|\>|\<|\"/) {
#    return 0;
#  }
#  return ($addr =~ /.+\@.+\.\w+\]*$/)
# 2011-05-06 - edited to restore + in address
  my $ret = $addr =~ /^(([\w\-\+]+)(\.))*([\w\-\+]+)@([\w\-]+\.)+[a-zA-Z]{2,65}$/;
#  if ($ret =~ /\+/) {
#    $ret = 0;
#  }

  if (!$ret) {
    $ret = $addr =~ /^\+.*\@/;
  }
  return $ret;
}



1;
