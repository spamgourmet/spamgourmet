package Mail::Spamgourmet::Page;
use strict;

my %_templates;  # hash to cache templates
my %_templatedates; # hash to track template dates (and refresh the cache if they've been updated)
my $_defaultcontenttype = 'text/html';
my $_defaultLanguageCode = 'EN';
my $_defaultCharSet = 'utf-8';
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
  if ($params{'languageCode'}) {
    $self->{'languageCode'} = $params{'languageCode'};
  } else {
    $self->{'languageCode'} = $_defaultLanguageCode;
  }
  if ($params{'charSet'}) {
    $self->{'charSet'} = $params{'charSet'};
  } else {
    $self->{'charSet'} = &getCharSet($self->{'languageCode'});
  }

  $self->{'leaveStrayTags'} = 0;
  $self->{'error'} = '';
  $self->{'content'} = '';
  $self->{'contentType'} = $_defaultcontenttype;
  $self->setTemplate($params{'template'}) if $params{'template'};
  return $self;
}

sub leaveStrayTags {
  my $self = shift;
  $self->{'leaveStrayTags'} = 1;
  return $self;
}

sub removeStrayTags {
  my $self = shift;
  $self->{'leaveStrayTags'} = 0;
  return $self;
}

sub getCharSet {
  my $lc = shift;
  my $cs = $_defaultCharSet;
  if ($lc eq 'ES') {
#    $cs = 'iso-8859-1';
  }
  if ($lc eq 'DE') {
#    $cs = 'iso-8859-1';
  }
#  if ($lc eq 'ZH') {
#    $cs = 'big5';
#  }
  return $cs;
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

sub setTemplate {
  my $self = shift;
  $self->fetchpage(@_);
  return $self;
}

sub getContent {
  my $self = shift;
  return $self->{'content'};
}

# fetchpage: this method populates a page object with raw template content
# It stores each template's content and file date in the private hashes
# _templates and _templatedates, respectively.  If an unchanged template already
# exists in the hash, the hash content is used (to speed things up)

sub fetchpage {
  my $self = shift;
  my $template = shift;

  if ($template) {

    my $templatefile = '';
    if ($self->{'config'}->{'webtemplatedir'}) {
      $templatefile = $self->{'config'}->{'webtemplatedir'}.$self->{'languageCode'}.'/'.$template;
    }
    
    my $filedate = -M $templatefile; # get template file date for comparison with cache

    # if the page is not already in the cache, or the template file
    # has been changed, then get the file contents off of the disk
    # and update the cache

    if (!$_templates{$templatefile} || $_templatedates{$templatefile} ne $filedate) {
      if (!-e $templatefile) {
        $templatefile = $self->{'config'}->{'webtemplatedir'}.$_defaultLanguageCode.'/'.$template;
      }
      if (!-e $templatefile) {
        $self->{'error'} .= "Could not open templatefile: $templatefile";
        return $self;
      } else {
        open (MYFILE,"$templatefile");
        sysread(MYFILE,$self->{'content'},100000);  # read in the file (100k max)
        close MYFILE;
        $_templatedates{$templatefile} = $filedate;  # set the cache date to match the file
        $_templates{$templatefile} = $self->{'content'};  # set the cache content to match the file content
      }
    # otherwise, just use the cached copy...
    } else {
      $self->{'content'} = $_templates{$templatefile};
    }
  } else {
    $self->{'error'} .= ' Template name must be supplied';
  }
  return $self;
}

sub settags {
  my $self = shift;
  $self->setTags(@_);
  return $self;
}

sub setTags {
  my (@tag,@string);
  my $i = 0;
  my $self = shift;
  my @args = @_;
  unless ($self->{'content'}) {
    $self->{'error'} .= ' No content!';
    return;
  }

  while(($tag[$i],$string[$i]) = @args) {
    shift(@args);shift(@args);
    $string[$i] = '' if !defined($string[$i]);
    $i++;
  }

  foreach $i (0..$#tag) {
    $self->{'content'} =~ s/<%$tag[$i]%>/$string[$i]/gi if defined($tag[$i]);
  }
  return $self;
}


sub concatenate {
  my $self = shift;
  my $stuff = shift;
  $self->{'content'} .= $stuff->{'content'};
  return $self;
}


sub setContentType {
  my $self = shift;
  $self->setcontenttype(@_);
  return $self;
}

sub setcontenttype {
  my $self = shift;
  my $type = shift;
  $self->{'contentType'} = $type;
  return $self;
}


sub printPage {
  my $self = shift;
  $self->printpage(@_);
  return $self;
}

sub printpage {
  my (@tag,@string);
  my $i = 0;
  my $self = shift;
  my @args = @_;
  unless ($self->{'content'}) {
    $self->{'error'} .= ' No content!';
    return;
  }

  while(($tag[$i],$string[$i]) = @args) {
    shift(@args);shift(@args);
    $string[$i] = '' if !defined($string[$i]);
    $i++;
  }

  my $contentType = $self->{'contentType'};
  my $contentLanguage = lc($self->{'languageCode'});
  my $charSet = $self->{'charSet'};
  print "Content-Language: $contentLanguage\n";
  print "Content-Type: $contentType; charset=$charSet\n\n";
  foreach $i (0..$#tag) {
# get tag, break out formatting, sprintf string into formatting
# assign value to string
    $self->{'content'} =~ s/<%$tag[$i]%>/$string[$i]/gi if defined($tag[$i]);
  }
  if (!$self->{'leaveStrayTags'}) {
    $self->{'content'} =~ s/<%(.*?)%>//g; # strip any remaining tags;
  }
  print $self->{'content'};
}

1;
