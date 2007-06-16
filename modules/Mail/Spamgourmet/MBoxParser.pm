package Mail::Spamgourmet::MBoxParser;

# use strict;
use vars qw{%header @body};

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);

	if (&parse_preheader() && &parse_header() && &parse_body()) {
		$self->{'header'} = %header;
		$self->{'body'} = @body;
		&print_message();
		return $self;
	}

	return null;
}

sub print_message() {
	my $key;

	print "------ HEADER BEGIN ------\n";
	foreach $key (keys %header) {
		print "$key => $header{$key}\n";
	}
	print "------ HEADER END ------\n";
	print "------ BODY BEGIN ------\n";
	print @body;
	print "------ BODY END ------\n";
}

sub parse_preheader() {
	my $line;

	while ($line = <STDIN>) {
		if ($line =~ m/^From /) {
			return true;
		} elsif ($line =~ m/^[ \t]+$/) {
			next;
		} else {
			return false;
		}
	}
}

sub parse_header() {
	my $prev, $line;

	$prev = "";
	while ($line = <STDIN>) {
		chomp($line);
		if ($line =~ m/^[ \t]/) {
			$prev = $prev . $line;
			next;
		}

		if ($prev =~ m/^([^:]):[ \t]*(.*)[ \t]*$/) {
			$key = $1; $val = $2;
			$header{$key} = $val;
		}

		$prev = $line;
		if ($line =~ m/^$/) {
			return true;
		}
	}

	return false;
}

sub parse_body() {
	@body = <STDIN>;

	return true;
}

sub header {
	my ($self, $key) = @_;
	my %h = $self->{'header'};
	return $h{$key};
}

sub body {
	my ($self, $key) = @_;
	return $self->{'body'};
}

1;

