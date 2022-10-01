#!/usr/bin/perl
#################################################################
## Copyright 2000,2001,2002, Josiah Q. Hamilton
## Copyright 2022, Michael De La Rue
#
# spamgourmet is provided under the Artistic License of the Open Source Initiative
# A copy of the license should be provided with this distribution
use strict;
use utf8;
use lib "/path/to/modules";
use Mail::Spamgourmet::Config;
use Mail::Spamgourmet::UserStore;
use DBD::mysql;

####################### path to config file #######################

my $configfile = "/path/to/spamgourmet.config";

##################### try not to edit anything below ##############

use vars qw {$config $extradebug $debugstderr};

$config = Mail::Spamgourmet::Config->new(configfile=>$configfile,mode=>0);

$config->debugstderr($debugstderr);
$config->debug('spameater started') if $extradebug;

my $user_store = Mail::Spamgourmet::UserStore->new(config=>$config);

$user_store->setup_test_user("junk")
