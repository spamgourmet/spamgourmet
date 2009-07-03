package Mail::Spamgourmet::Util;
use strict;
use Digest::MD5 qw(md5_hex);

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self,$class;
  my %params = @_;
  if ($params{'config'}) {
    $self->{'config'} = $params{'config'};
  } else {
    die 'Util must be initialized with an instance of Mail::Spamgourmet::Config.pm';
  }
  return $self;
}

sub getConfig {
  my $self = shift;
  return $self->{'config'};
}

sub isin {
  my $self = shift;
  my $subject = shift;
  return 0 if !$subject;
  my @items = @_;
  my $item;
# make sure we're matching a host...
  $subject =~ s/.*\@//;
  foreach $item (@items) {
    if ($subject =~ /^$item$/i) {
      return 1;
    }
  }
  return 0;
}


sub hasFeature {
  my $self = shift;
  my $feature = shift;
  my $userFeatureSetting = shift;
  if ($feature =~ /\w+/) { # if a string was passed in, get the number from config
    $feature = $self->{'config'}->getFeature($feature);
  }
  if ($userFeatureSetting && $feature && $userFeatureSetting % $feature == 0) {
    return 1;
  } else {
    return 0;
  }
}

sub addFeature {
  my $self = shift;
  my $feature = shift;
  my $userFeatureSetting = shift;
  return ($userFeatureSetting * $feature);
}

sub removeFeature {
  my $self = shift;
  my $feature = shift;
  my $userFeatureSetting = shift;
  my $newFeatureSetting = $userFeatureSetting;
  if ($userFeatureSetting && $feature && $userFeatureSetting % $feature == 0) {
    $newFeatureSetting = $newFeatureSetting / $feature;
  }
  return $newFeatureSetting;
}


sub clearFeature {
  my $self = shift;
  my $feature = shift;
  my $userFeatureSetting = shift;
  my $newFeatureSetting = $userFeatureSetting;
  if ($userFeatureSetting > 0 && $feature > 0) {
    while ($newFeatureSetting % $feature == 0) {
      $newFeatureSetting = $newFeatureSetting / $feature;
    }
  }
  return $newFeatureSetting;
}


# Returns a number when given a string.
# If the string is a number, returns the number
# If the string is a spamgourmet special char/string (*,+,sender,domain),
#  returns that
# If first character of string is a Roman (English) letter,
#  returns the ordinal (English) alphabet position
# Otherwise, returns default, which can be supplied as a second argument,
#  but, if not supplied, is 3.
sub getNumberFromString {
  my $self = shift;
  my $str = shift;
  my $default = shift;
  $default = 3 if !$default; #default default of 3
  return $default if !$str && $str ne '0';
  if ($str =~ /^\d*$/ || $str eq '*' || $str eq '+' || $str =~ /sender/i || $str =~ /domain/i) {
    return $str;
  }
  my $code = ord($str);
  if ($code > 96 && $code < 123) {
    return $code - 96;
  } elsif ($code > 64 && $code < 91) {
    return $code - 64;
  } else {
    return $default;
  }
}

sub getRedirectedAddress {
  my $self = shift;
  my $addr = shift;
  my $word = shift;
  my $user = shift;
  my $key  = shift;
  my $name = shift;
  my $host = $self->{'config'}->getMailHost();

  $addr =~ s/\@/\#/;
  my $hash = $self->getShortHash($addr,$key);
  my $raddr = '+' . $word . '+' . $user . '+' . $hash . '.' . $addr . '@' . $host;
  if ($name && length($raddr) < 80) {
    $raddr = $name . ' <' . $raddr . '>';
  }
  return $raddr;
}

sub getAddressAndDisplay {
  my $self = shift;
  my $str = shift;
  my $combine = shift;
  my ($addr, $display, $part, @display);
  my @parts;
  if ($str =~ /</) {
    @parts = split('<',$str);
  } else {
    @parts = split(' ',$str);
  }
  if (!@parts) {
    push (@parts,$str);
  }
  while (@parts) {
    $part = shift(@parts);
    if ($part =~ /\@/ && $part !~ /\"/) {
      $addr =~ s/\;//g;
      $addr = $part;
    } else {
      push (@display, $part);
    }
  }
  if (@display) {
    $display = join(' ',@display);
    $display =~ s/\(//g;
    $display =~ s/\)//g;
    $display =~ s/\"//g;  # remove pesky quotes
    $display =~ s/\,//g;  # remove pesky commas
    $display =~ s/^ //;
    $display =~ s/ $//;
  }
  $addr =~ s/<//;
  $addr =~ s/>//;
  $addr =~ s/\s//g;
  $addr =~ s/\"//g;
  if ($combine) {
    if ($display) {
      $display = "$display - $addr";
    } else {
      $display = $addr;
    }
  }
  return ($addr,$display);
}

sub getAddressAndDisplayOld {
  my $self = shift;
  my $adr = shift;
  my $combine = shift;
  my $display;
  $adr =~ s/(.*)<//;
  $display = $1;
  $adr =~ s/^<//;
  $adr =~ s/>$//;
  $adr =~ s/^\s+//;
  $adr =~ s/\s+$//;
  if ($adr =~ /<(.*)>/) {
    $adr = $1;
  }
  $adr =~ s/\"//g;

  if ($adr =~ s/\((.*)\)//) {
    $display = $1;
  }
  if ($display) {
    $display =~ s/\"//g;  # remove pesky quotes
    $display =~ s/\,//g;  # remove pesky commas
    $display =~ s/^ //;
    $display =~ s/ $//;
  }
  if ($combine) {
    if ($display) {
      $display = "$display - $adr";
    } else {
      $display = $adr;
    }
  }
  return ($adr,$display);
}


sub getShortHash {
  my $self = shift;
  my $stuff = shift;
  my $key = shift;
  return substr(md5_hex($key.lc($stuff)),22,32);
}

sub getEatenMessageLog {
  my $self = shift;
  my $numberOfEatenMessagesToLog = shift;
  my $from = shift;
  my $for = shift;
  my $oldLog = shift;

  my $newLog = time() . $self->setToLength(55,$from) . $self->setToLength(20,$for);
  my $log = '';
  if (length($oldLog) > (85 * ($numberOfEatenMessagesToLog - 1))) {
    $log = $newLog . substr($oldLog,0,(85*($numberOfEatenMessagesToLog - 1)));
  } else {
    $log = $newLog . $oldLog;
  }
  return $log;
}

sub setToLength {
  my $self = shift;
  my $length = shift;
  my $string = shift;
  my $newString = substr($string,0,$length);
  my $newLength = length($newString);
  if ($newLength < $length) {
    $newString .= ' ' x ($length - $newLength);
  }
#$self->{$config}->debug("length: $length - newstring length: " . length($newString));
  return $newString;
}


sub containsOne {
  my $self = shift;
  my $stuff = shift;
  my @words = @_;
  my $word;
  my $matches = 0;
  foreach $word (@words) {
    if ($stuff =~ /$word/i) {
      $matches = 1;
    }
  }
  return $matches;
}



sub formatNumDate {
  my $self = shift;
  return $self->{'config'}->formatNumDate(@_);
}



sub getExpireTime {
  my $self = shift;
  my $str = shift;
  my $now = shift;
  my @parts = split('-',$str);
  $parts[1]--;
  my $expiretime;
  eval "use Time::Local;";
  # Jan Lellmann - fix for September 9 - thanks!
  $parts[0] =~ s/^0+//;
  $parts[1] =~ s/^0//;
  $parts[2] =~ s/^0//;
  eval "timelocal(0,0,0,$parts[2],$parts[1],$parts[0]);";
  if (!$@) {
    $expiretime = timelocal(0,0,0,$parts[2],$parts[1],$parts[0]);
    if ($expiretime > $self->{'config'}->getMaxExpirePeriod() + $now) {
      $expiretime = $self->{'config'}->getMaxExpirePeriod() + $now;
    }
  }
  return $expiretime;
}


1;
