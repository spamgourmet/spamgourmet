package Mail::Spamgourmet::WebMessages;
use strict;
use Mail::Spamgourmet::Page;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless $self, $class;
    my %params = @_;
    if ( $params{'config'} ) {
        $self->{'config'} = $params{'config'};
        $self->{'mailer'} = $params{'config'}->getMailer();
    }
    else {
        die
            'WebMessages must be initialized with an instance of Mail::Spamgourmet::Config.pm';
    }
    return $self;
}

sub sendchangedemailmessage {
    my $self       = shift;
    my $session    = shift;
    my $thisscript = shift;
    my $oldaddress = shift;
    my $newaddress = shift;
    my $subject    = $session->getDialog('changedemail');

    my $body = Mail::Spamgourmet::Page->new(
        template     => 'changedemail.txt',
        languageCode => $session->getLanguageCode()
    );

    $body->setTags( 'oldaddress', $oldaddress, 'newaddress', $newaddress );
    my $adminemail = 'noreply@spamgourmet.com';
    my $msg        = "From: $adminemail\n";

    $msg .= "To: " . $oldaddress . "\n";
    $msg
        .= "Subject: $subject\nMIME-Version: 1.0\nContent-Type: text/plain; charset=\"utf-8\"\n";
    $msg .= $body->getContent();
    $self->{'mailer'}->sendMail( \$msg, $oldaddress, $adminemail );

    #  $self->{'config'}->debug("sent password reset message");
    return 0;
}

sub sendpasswordresetmessage {
    my $self       = shift;
    my $session    = shift;
    my $thisscript = shift;
    my $newaddress = shift;
    my $hashcode   = shift;
    my $subject    = $session->getDialog('setnewpassword');
    my $url
        = "\nhttp://www.spamgourmet.com/$thisscript?resetpassword=1&hc=$hashcode";

    my $body = Mail::Spamgourmet::Page->new(
        template     => 'resetpasswordmessage.txt',
        languageCode => $session->getLanguageCode()
    );

    $body->setTags( 'url', $url, 'username', $session->{'UserName'} );
    my $adminemail = $self->getConfig()
        ->getAdminEmail( $self->rot13( $session->getUserName() ) );
    my $msg = "From: " . $adminemail . "\n";
    $msg .= "To: " . $newaddress . "\n";
    $msg
        .= "Subject: $subject\nMIME-Version: 1.0\nContent-Type: text/plain; charset=\"utf-8\"\n";
    $msg .= $body->getContent();
    $self->{'mailer'}->sendMail( \$msg, $newaddress, $adminemail );

    #  $self->{'config'}->debug("sent password reset message");
    return $adminemail;
}

sub sendconfirmationmessage {
    my $self       = shift;
    my $session    = shift;
    my $thisscript = shift;
    my $newaddress = shift;
    my $hashcode   = shift;
    my $subject    = $session->getDialog('addressconfirmation');
    my $url        = "\nhttp://www.spamgourmet.com/$thisscript?cec=$hashcode";

    my $body = Mail::Spamgourmet::Page->new(
        template     => 'confirmationmessage.txt',
        languageCode => $session->getLanguageCode()
    );

    $body->setTags( 'url', $url, 'newaddress', $newaddress );
    my $adminemail = $self->getConfig()
        ->getAdminEmail( $self->rot13( $session->getUserName() ) );
    my $msg = "From: " . $adminemail . "\n";
    $msg .= "To: " . $newaddress . "\n";
    $msg
        .= "Subject: $subject\nMIME-Version: 1.0\nContent-Type: text/plain; charset=\"utf-8\"\n";
    $msg .= $body->getContent();
    $self->{'mailer'}->sendMail( \$msg, $newaddress, $adminemail );
    return $adminemail;
}

sub rot13 {    # used to help make the reply addresses for confirms
    my $self = shift;
    my $str  = shift;
    $str =~ y/A-Za-z/N-ZA-Mn-za-m/;
    return $str;
}

sub getConfig {
    my $self = shift;
    return $self->{'config'};
}

1;
