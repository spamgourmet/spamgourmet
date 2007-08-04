#! /usr/bin/perl -w
#################################################################
# Project spamgourmet 
# $Id: mkquizword.pl,v 1.1.1.1 2004/01/27 20:13:04 syskoll Exp $
# Copyright (C) 2003 Frederic Mora -
# The address is sg.rocks.syskoll
# The host is spamgourmet.com
# This program is placed under the GPL. See http://www.gnu.org/licenses/gpl.txt
# or the accompanying GPL_LICENSE.txt
#

# This file contains two routines, mkquizworddict and mkquizwordhex.
# It includes a test main that invokes these routines. Usage: 
# mkquiword.pl (no arguments)

### Subroutine: mkquizworddict
# The routine creates a quizword by picking a random work in its dictionary file
# (one word per line, selected subset of the English language), then adds appends
# a 3-digit number.
#
# Requires:
#   - English dictionary file, 1 word per line, see constant DictFn.
# Returns: quizword string
###

sub mkquizworddict {

  ##########
  # Constant section - Personnalize here
  ## Installation dir of this program - IMPORTANT
  *InstallDir=\ "/home/mora/src/spamgourmet/captcha";
  ## Dictionary file (1 word per line)
  *DictFn=\ "$InstallDir/dictionary";
  #
  ########## End of constants

  open DICT, $DictFn or die "Cannot read $DictFn: $!";
  seek DICT, 0, 2; # Go to end of file
  my $DictLn = tell DICT;
  while (eof DICT) {
    seek DICT, int(rand($DictLn - 10)), 0; # Go to a random position in dict file
    next if (eof DICT);
    $quizword=<DICT>; # Skip the 1st word we read, because we 
    $quizword=<DICT>; # might start reading in the middle of a word
  }

  chomp $quizword;
  # Append a 3-digit int (100-999) to the quizword
  $quizword .= int(rand(899) + 100);
  close DICT;

  return $quizword;
}

### Subroutine: mkquizwordhex
# The routine creates a quizword by picking a 6-digit random hex number.
# Returns: quizword string
###
sub mkquizwordhex {
  my $nbr = 0x100000 + int(rand(0xefffff)); # Range 0x100000 to  0xffffff
  return sprintf "%lx", $nbr;  # Return hex value of $nbr
}

#### Test main - Call with 1 argument, the name of the image to generate
###  (should be writeable!)
#### Usage: mkcaptcha.pl image.gif

srand; # Random number initialization
my $loops=10;
print "Calling both quizword generation routines $loops times\n";
print "Hex   \t From dictionary\n";
  for (my $i = 0;$i < $loops; $i++) {
      print mkquizwordhex() . " \t " . mkquizworddict() . "\n";
    }
exit 0;
