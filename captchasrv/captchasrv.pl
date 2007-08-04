#! /usr/bin/perl -w
#################################################################
# Project spamgourmet 
# $Id: captchasrv.pl,v 1.1.1.1 2004/01/27 20:06:04 syskoll Exp $
# Copyright (C) 2003 Frederic Mora -
# The address is sg.rocks.syskoll
# The host is spamgourmet.com
# This program is placed under the GPL. See http://www.gnu.org/licenses/gpl.txt
# or the accompanying GPL_LICENSE.txt

# This program is meant to be started as a daemon. It doesn't need root priviledges.
# It requires:
# - access to the convert exec (from ImageMagick)
# - space in a temp directory
# - an HTTP server running on the same machine.
# Start the program in the background, eg: captchasrv.pl &

# The program waits on a port for a browser to send URLs requests of the form
# http://host:port/q=someword
# where:
#  - host is the host on which the program runs
#  - port is the port on which it listens (either default, see var LocalPortDef, or
#    specified with option -p)
# - someword is a string, called the quizword, to be embedded in the CAPTCHA image.
#
# For each HTTP request of the form above, the program generates a
# CAPTCHA image containing the quizword "someword". It saves the image
# to a temp file and sends back the name of the temp file as an HTTP
# response. A brower can then use that file name in an IMG tag.
# Example:
#  - Call URL http://host:port/q=abcxyz1234 to generate captcha with
#    quizword abcxyz1234
#  - The program replies something like "capP5E6VcbV.jpg", the name of the file
#    containing the capcha
#  - Then, to use the captcha in a web page, put an IMG HTML tag such as:
#    <IMG SRC="http://host:port/path/capP5E6VcbV.jpg" ALT="CAPTCHA image">

#use strict; # Clashes with constant definitions
use vars qw($opt_t $opt_o $opt_h $opt_p); # For command-line options with Getopt
use Getopt::Std;
use File::Basename;
use File::Temp qw(tempfile);
use File::stat;
use IO::Socket::INET;

#################################################################
## Main


##########
# Constant section - Personnalize here
# Beware: constant module means don't put a $ in front of name!
## Installation dir of this program - IMPORTANT
use constant InstallDir => "/home/mora/src/spamgourmet/captcha";
## Path of executable for "convert" prog, from the ImageMagick package
use constant ConvertExec => "/usr/bin/convert";
## Default local port (on which the server listens)
use constant LocalPortDef => 15678;
## Directory for temporary captcha image files 
#### MUST BE ACCESSIBLE THROUGH THE HTTP SERVER!!!
use constant   TmpDir => "/tmp/sg/captcha";
## Templates for temp files -  Xs will be replaced with random chars
use constant {
  TmpltCi => TmpDir . "/capXXXXXXXX", # For captcha images
  TmpltBg => TmpDir . "/bkgXXXXXXXX", # For background images
};
## Constants for periodic scrubbing of TmpDir
## The file longevity will be between ScrubAge and (ScrubAge+ScrubPeriod) max.
use constant {
  ScrubPeriod => 600, # Time between each scrubbing in seconds (10 mins)
  ScrubAge => 900,    # Minimum age of files to be deleted in seconds (15 mins)
};

########## End constants

# Subroutines
sub LaunchPeriodicCleanup;
sub PrintTrace;
sub str2captcha;
sub usage;

my $Progname = basename($0);
my $quizword = "";
my $LocalPort = LocalPortDef; # No $ in front of name!
my $Version = '$Revision: 1.1.1.1 $' ; # RCS tag goes here
my ($fh, $fname, $bname); # File handle, full name and base name of captcha

# Command-line options processing
# Defaults values
$opt_t = 0;
$opt_o = "";
$opt_p = "";
getopts("t:o:p:h") or usage();
if ($opt_h) { usage() };
my $TraceLvl = $opt_t;
my $Logfile = $opt_o;

# If $Logfile is specified, open it as append and redirect STDOUT to it
if ($Logfile ne "") {
open STDOUT, ">> $Logfile"
    or die "$Progname: cannot redirect STDOUT to $Logfile: $!\n";
}

# If p flag is specified
if ($opt_p ne "") {
  if ($opt_p !~ /^\d+$/) {  # If it is not made of digits
    print STDERR "Flag -p needs a numerical arg (port number).\n";
    usage();
  }
  $LocalPort = $opt_p;
}

PrintTrace(1, "Starting $Progname v $Version with options:\n" .
 "-t $TraceLvl -o " . ($opt_o eq ""? "STDOUT" : $Logfile) .
 " -p $LocalPort");

# Check the temp dir, create it if needed
if ((-d TmpDir) && (-w TmpDir))  { # Check that TmpDir is a writeable dir
  PrintTrace(3, "Temp dir ". TmpDir. " exists and is writeable, OK");
} else {
  PrintTrace(3, "creating temp file dir ". TmpDir);
  my $cmdstr = "/bin/mkdir -p " . TmpDir;
  system ($cmdstr);
  if ((-d TmpDir) && (-w TmpDir)) {
      PrintTrace(3, TmpDir . " created OK");
  } else { die "$Progname: cannot execute $cmdstr: $!\n"; }
}

# Start the cleanup child process
LaunchPeriodicCleanup(TmpDir);

# Open server socket, reusable, max 5 simultaneous client connections
my $socket = IO::Socket::INET
    ->new(LocalPort => $LocalPort,
	  Reuse => 1,
	  Type => SOCK_STREAM,
	  Listen => 5)
    or die "captchasrv: cannot open server socket on port $LocalPort: $@\n";

while ($client = $socket->accept()) {
    PrintTrace(2, "Accepted client connection"); ### DEBUG
    while (my $line = <$client>) {
	# print $line; ###DEBUG
	chop $line; # Remove CRLF at end of lines
	chop $line;
	# print "Twice-chopped line:\n!!${line}!!\n"; ###DEBUG

	# Looks for a line of the form GET /q=xyzt HTTP/1.1
	# corresponding to URL http://host:port/q=xyzt
	# Word can contain alphanum (\w) and apostrophe.
	if ($line =~ 'GET /q=([\w\']+) HTTP/1.1') {
	    $quizword=$1;
	}
	last if ($line eq ""); # end of HTTP header
    }
    #print "-------End client data\n";  ###DEBUG
    # Now send data to the browser
    PrintTrace(2, "quizword=$quizword\n");
    # Create temp file for captcha, don't delete it after use
    ($fh, $fname) = tempfile(TmpltCi, SUFFIX=>".jpg", UNLINK=>0);
    PrintTrace(3, "captcha file: $fname");
    &str2captcha($quizword,  $fh);
    # Make the captcha file world-readable
    chmod 0644, $fname;
    # Send base name of captcha file to client
    $bname = basename($fname);
    print $client "$bname";
    close $client;
    close $fh;
    PrintTrace(3, "sent name \"$bname\" to client, closed client connection\n");
}

close $socket;
PrintTrace(1, "Exiting");
exit 0;
## End main

#################################################################
## LaunchPeriodicCleanup - Start a child process that
## remove old files from temp dir at regular intervals
## Args:
## $1 - Temp dir to be scrubbed
## Uses: ScrubPeriod, ScrubAge
sub LaunchPeriodicCleanup {

  my $Dirname = shift;

# Use "foolproof method" from "Programming Perl" handbook
  my ($pid, $sb, $ftime, $nowtime);
  if ($pid = fork) {
    # We're in the parent here
      PrintTrace(2, "Started periodic cleanup process for temp files, PID=$pid");
      # Falls through and return
  } elsif (defined $pid) {
    # We're in the child here
    chdir $Dirname or die "Cannot cd to $Dirname: $!\n";

    while (1) {   # Forever
      $nowtime = scalar time;  # Current time in secs since Epoch
      opendir (DIR, ".") or die "Cannot open $Dirname: $!\n";
      # Check age of all files in dir
      while (defined($file = readdir(DIR))) {
	next unless -f $file;
	$sb = stat($file); # Grab time creation info on this file
	$ftime = scalar $sb->mtime;
	# If file older than ScrubAge, delete it
	if ($nowtime  > $ftime + ScrubAge) {
 	    unlink $file;
	    PrintTrace(5, "Deleted older file $Dirname/$file");
	}
      }
      sleep ScrubPeriod;
    } # End while -- should not happen
    PrintTrace(0, "Error: child cleanup process broke loop: $!");
    exit 1;
  } elsif ($! =~ /No more process/) {
      PrintTrace(0, "Cannot create cleanup child process, no more processes available");
  } else {
      PrintTrace(0, "Cannot create cleanup child process, fork error: $!");
  }

  return 0;
}


#################################################################
## PrintTrace - Prints a message is trace level high enough
## Args:
## $1 - trace level
## $2 - string, printed if global $TraceLvl >= $1
## String is preceded with one '*' per trace level and the local time
## Uses: $TraceLvl
sub PrintTrace {
  my ($lvl, $str, $tm);
  $lvl = shift;
  $str = shift;
  return unless  $TraceLvl  >= $lvl ;
  $tm = localtime;
  
  print  '*' x $lvl, " $tm $str\n";
}

#################################################################
## str2captcha - creates a CAPTCHA image containing the given string
## and send it to the given open file descripton
## The routine generates a CAPTCHA, i.e., a picture containing a word that a human
## being can easily read but that a spammer's OCR program could not.  Requires:
##   - "Large" background image (larger than the size of the CAPTCHA).
##   - ImageMagick should installed on the system.
##
## The routine clips a rectangle at a random location from the
## large background image. Then it draws (in the rectangle) the string passed
## as an argument.
##
## This final image is the CAPTCHA. The CAPTCHA is written to the open file descriptor
## passed as an argument.
## Args:
## $1 - quizword - string to be drawn in image
## $2 - open file descriptor to which the image will be written
sub str2captcha {
  my $quizword= shift;
  my $Outdesc = shift;  # Output file descriptor

  ##########
  # Constant section - Personnalize here if needed. Defaults should work.
  # Beware: constant module means don't put a $ in front of var name!
  ## File name of large image containing the background
  use constant LgImgFn => InstallDir . "/large.jpg";
  ## Size of large image in pixels, x and y
  use constant LgImgSzx => 1000;
  use constant LgImgSzy => 1000;
  ## Size of small image in pixels, x and y
  use constant SmImgSzx => 620;
  use constant SmImgSzy => 180;
  ## 
  ## WARNING: Don't modify the constants below unless you really know
  ## what you're doing and you have tested the results!
  ##
  ## Constants for printing the word on the background image
  ### RGB color for text, must be close to colors in backgound
  use constant FillColor => "c8a070";
  ### Magnification factor for the letters - 8 to 10 works well
  use constant MagFactor => 9;
  ### Inclination factor for the word. 0 = horizontal, -0.5 to 1 works well
  use constant InclFactor=> 0.9;
  ### Slanting factor for the letters - -2 to 2 works well
  use constant SlantFactor=> 2;
  ### Font file name - Must exist. Chose a Type 1 Roman or Utopia-like bold.
  use constant FontFn=> InstallDir . "/URW-Palladio-L-bold-r-normal.pfb";
  ### Blur factor - a value larger than 2x3 is unreadable
  use constant BlurFactor=> "2x3";
  #
  ########## End of constants

  # Determine start point of clipping rectangle
  my $randx=int(rand(LgImgSzx - SmImgSzx));
  my $randy=int(rand(LgImgSzy - SmImgSzy));
  my $TmpFhdl; # tmp file handle
  my $TmpFn;   # tmp file name

  # Create temp backgroung file for small rectangle cropped out of the large image
  ($TmpFhdl, $TmpFn) = tempfile(TmpltBg);

  # Clip a rectangle from the large image into the temp background file
  my $cmdstr= ConvertExec . " -crop " .
      SmImgSzx . "x" . SmImgSzy . "+". $randx . "+" . $randy .
      " " . LgImgFn . " $TmpFn";
  PrintTrace(4, "Extracting small image from large one");
  PrintTrace(5, "Invoking command:" . $cmdstr);
  system ($cmdstr);

  $cmdstr = ConvertExec . " -fill '#" . FillColor . "' " .
      " -affine " . MagFactor . "," . InclFactor . "," . SlantFactor . "," .
      MagFactor . ",0,0" .
      " -font " . FontFn . " -draw 'text 1,10 $quizword' " .
      " -blur " . BlurFactor . " $TmpFn -";
  PrintTrace(4, "Drawing string in small image");
  PrintTrace(5, "Invoking command:" . $cmdstr);

  # Execute cmdstr and put the result in resultstr
  my $resultstr = `$cmdstr`;
  print {$Outdesc} $resultstr; # Send result to open file - Note indirect notation "{$desc}"

  close $TmpFhdl; # Close and delete tmp background file
  unlink $TmpFn;
  return 0;
}

#################################################################
## usage() - Display usage message and exits.

sub usage {
  print STDERR << "EOF";
    
usage: $Progname [-h] [-t tracelevel]  [-p port] [-o outputfile]
  -h            : Prints this help message
  -t tracelevel : (optional) Sets level of trace messages. Higher is more
                  verbose. Default is 0 (no trace).
  -o outputfile : (optional) Sets name of file where trace output will be
                   written. Default is standard output.
  -p port       : (optional) Sets IP port where daemon will listen.
                  Default = $LocalPortDef.

 Example:
$Progname  -t 1 -o /tmp/mytrace.txt -p 12345

EOF

    exit 1;
} 




