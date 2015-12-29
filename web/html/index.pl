#!/usr/bin/perl -w
use strict;
use vars qw{$thisscript $pagemaker};
use lib "/path/to/modules";
use DBD::mysql;
use CGI;
use Digest::MD5 qw(md5_hex);
#use CGI::Carp "fatalsToBrowser";
use Mail::Spamgourmet::Config;
use Mail::Spamgourmet::Page;
use Mail::Spamgourmet::Session;
use Mail::Spamgourmet::Dialogs;
use Mail::Spamgourmet::WebUtil;
use Mail::Spamgourmet::WebMessages;

$thisscript = 'index.pl';

my $config = Mail::Spamgourmet::Config->new(configfile=>'/path/to/spamgourmet.config');
my $util = Mail::Spamgourmet::WebUtil->new(config=>$config);

my $session = Mail::Spamgourmet::Session->new(config=>$config,webutil=>$util,query=>new CGI);
Mail::Spamgourmet::Page->setGlobalConfig($config);
$pagemaker = Mail::Spamgourmet::Page->new();

$| = 1;


if ($session->param('xml')) {
  &printMyXml($config,$session,$util);
} elsif ($session->param('printpage')) {
  &printPage($session);
} else {
  &mainPage($config,$session,$util);
}

#$config->debug("dbstatus is: " . $config->dbstatus);

$config->die();

exit;

sub getLanguageList {
  my $session = shift;
  my $advanced = 0;
  if (($session->{'Prefix'} || $session->param('advanced')) && !$session->param('nobrainer')) {
    $advanced=1;
  }
  my $lc = $session->{'LanguageCode'};
  my %selected = ('DA'=>'','DE'=>'','EN'=>'','ES'=>'','FR',=>'','JA'=>'','KO'=>'','IT'=>'',
   'NL'=>'','NO'=>'','PL'=>'','PT'=>'','RO'=>'','RU'=>'','SV'=>'','TR'=>'','ZH'=>'') ;
  $selected{$lc} = 'SELECTED';
  my $list =$pagemaker->new(template=>'languagelist.html',languageCode=>$session->getLanguageCode());
  $list->setTags(
   'action',$thisscript,
   'DA',$selected{'DA'}, 'languageDanish', $session->getDialog('languageDanish'),
   'DE',$selected{'DE'}, 'languageGerman', $session->getDialog('languageGerman'),
   'EN',$selected{'EN'}, 'languageEnglish', $session->getDialog('languageEnglish'),
   'ES',$selected{'ES'}, 'languageSpanish', $session->getDialog('languageSpanish'),
   'FR',$selected{'FR'}, 'languageFrench', $session->getDialog('languageFrench'),
   'IT',$selected{'IT'}, 'languageItalian', $session->getDialog('languageItalian'),
   'JA',$selected{'JA'}, 'languageJapanese', $session->getDialog('languageJapanese'),
   'KO',$selected{'KO'}, 'languageKorean', $session->getDialog('languageKorean'),
   'NL',$selected{'NL'}, 'languageDutch', $session->getDialog('languageDutch'),
   'NO',$selected{'NO'}, 'languageNorwegian', $session->getDialog('languageNorwegian'),
   'PL',$selected{'PL'}, 'languagePolish', $session->getDialog('languagePolish'),
   'PT',$selected{'PT'}, 'languagePortuguese', $session->getDialog('languagePortuguese'),
   'RO',$selected{'RO'}, 'languageRomanian', $session->getDialog('languageRomanian'),
   'RU',$selected{'RU'}, 'languageRussian', $session->getDialog('languageRussian'),
   'SV',$selected{'SV'}, 'languageSwedish', $session->getDialog('languageSwedish'),
   'TR',$selected{'TR'}, 'languageTurkish', $session->getDialog('languageTurkish'),
   'ZH',$selected{'ZH'}, 'languageChinese', $session->getDialog('languageChinese')
   );

  return $list->getContent();
}


sub printJS {
  my $session = shift;
  my $page = getJS($session);
  $page->setContentType('application/x-javascript');
  $page->printPage();
}


sub getJS {
  my $session = shift;
  my $page =$pagemaker->new(template=>'stuff.js',languageCode=>$session->getLanguageCode());
  $page->setTags('nodelimitersinprefix',     $session->getDialog('badcharacterinprefix','character','.'),
                   'enterusernamepassword',    $session->getDialog('enterusernamepassword'),
                   'provideusername',          $session->getDialog('provideusername'),
                   'nodelimitersinusername',   $session->getDialog('badcharacterinusername','character','.',
                                                'username','\'+obj.newuser.value+\''),
                   'nospacesinusername',       $session->getDialog('badcharacterinusername','character','space',
                                                'username','\'+obj.newuser.value+\''),
                   'noatsignsinusername',      $session->getDialog('badcharacterinusername','character','@',
                                                'username','\'+obj.newuser.value+\''),
                   'providepassword',          $session->getDialog('providepassword'),
                   'provideforwardingaddress', $session->getDialog('provideforwardingaddress'),
                   'entercurrentpassword',     $session->getDialog('entercurrentpassword'),
                   'passwordmismatch',         $session->getDialog('passwordmismatch'),
                   'invalidforwardingaddress', $session->getDialog('invalidforwardingaddress') );
  return $page;
}



sub printPage {
  my $session = shift;
  my $input = $session->param('printpage');
  my $template = 'blank.html';
  if ($input eq 'faq.html'
   || $input eq 'whatsnew.html'
   || $input eq 'links.html'
   || $input eq 'link.html'
   || $input eq 'whatsnew.html'
   || $input eq 'privacy.html'
   || $input eq 'downloads.html'
   || $input eq 'terms.html'
   || $input eq 'team.html'
   || $input eq 'donate.html'
   ) {
    $template = $input;
  }

  my $page =$pagemaker->new(template=>$template,languageCode=>$session->getLanguageCode());
  if ($input eq 'links.html') {
    $page->printPage('partnersprizes',$session->getDialog('partnersprizes'),
                     'linkstous',$session->getDialog('linkstous'),
                     'linktous',$session->getDialog('linktous'),
                     'otherlinks',$session->getDialog('otherlinks'));
  } elsif ($input eq 'link.html') {
    $page->printPage('linktospamgourmet',$session->getDialog('linktospamgourmet'),
                     'howtolink', $session->getDialog('howtolink'));
  } elsif ($input eq 'donate.html') {
    my $comments = $pagemaker->new(template=>'donationcomments.html')->getContent();
    $page->printPage('donatepaypal', $session->getDialog('donatepaypal'),
                     'title', $session->getDialog('donate'),
                     'donationcomments', $comments,
                     'closewindow', $session->getDialog('closewindow'));
  } else {
    $page->printPage('closewindow', $session->getDialog('closewindow'));
  }
  return; 
}

sub confirmemailchange {
  my $config = shift;
  my $session = shift;
  my $hash = $session->param('confirmemailchange') || $session->param('cec');
  my (%attr,$UserID,$address,$msg,$realaddress);
  if ($hash) {
    my $sql = "SELECT UserID, RealEmail, PendingEmail 
     FROM Users WHERE PendingHashCode = ?";
    my $st = $config->db->prepare($sql);
    $st->execute($hash);
    $st->bind_columns(\%attr,\$UserID,\$realaddress,\$address);
    $st->fetch();
    if ($UserID && $realaddress ne $address) {
      $sql = "UPDATE Users SET RealEmail = PendingEmail WHERE UserID = ?";
      $st = $config->db->prepare($sql);
      $st->execute($UserID);
      $msg = $session->getDialog('confirmationsuccessful','address',$address); 
      $session->{'RealEmail'} = $address;
      my $now = time();
#      $sql = "INSERT INTO AddressAudit (UserID,Address,ChangeTime,IPAddress) VALUES (?,?,?,?);";
#      $st = $config->db->prepare($sql);
#      $st->execute($UserID,$address,$now,$ENV{'REMOTE_ADDR'});
    } elsif ($UserID) {
      $msg = $session->getDialog('confirmedalready','address',$address);
    }
  }
  if (!$UserID) {
    $msg = $session->getDialog('confirmationunsuccessful');
  }
  return $msg;
}

sub printMyXml {
  my $config = shift;
  my $session = shift;
  my $util = shift;
  my ($message,$data,$sql,$st) = ('','','','');
  my %attr;
  my $page =$pagemaker->new(config=>$config,languageCode=>$session->getLanguageCode());
  my $UserID = $session->{'UserID'};
  my ($EmailID,$Word,$MaxCount,$Count,$NumDeleted,$NumForwarded,$TimeAdded,$Sender,$Address,$Hidden,$Note)
   = (       0,  '',        0,     0,          0,            0,         0,     '',      '',      0,    '');

  my ($watchword,$trustedsender) = ('','');

  my ($row,$bottom);
  $page->setContentType("text/xml");

  $page->setTemplate('xmltop');

  $sql = "SELECT Sender FROM Permitted WHERE UserID = ?";
  $st = $config->db->prepare($sql);
  $st->execute($UserID);
  $st->bind_columns(\%attr, \$trustedsender);
  while ($st->fetch()) {
    $row =$pagemaker->new('config'=>$config,'languageCode'=>$session->getLanguageCode());
    $row->setTemplate('xmltrustedsenderrow');
    $row->setTags('trustedsender', $trustedsender);
    $page->concatenate($row);
  }

  $sql = "SELECT Watchword FROM Watchwords WHERE UserID = ?";
  $st = $config->db->prepare($sql);
  $st->execute($UserID);
  $st->bind_columns(\%attr, \$watchword);
  while ($st->fetch()) {
    $row =$pagemaker->new('config'=>$config,'languageCode'=>$session->getLanguageCode());
    $row->setTemplate('xmlwatchwordrow');
    $row->setTags('watchword', $watchword);
    $page->concatenate($row);
  }

  $sql = "SELECT EmailID, Word, InitialCount, Count, NumDeleted, NumForwarded,
   TimeAdded, Sender, Address, Hidden, Note
   FROM Emails WHERE UserID = ?";

  $st = $config->db->prepare($sql);
  $st->execute($UserID);
  $st->bind_columns(\%attr,\$EmailID,\$Word,\$MaxCount,\$Count,
   \$NumDeleted,\$NumForwarded,\$TimeAdded,\$Sender,\$Address,\$Hidden,\$Note);

  while ($st->fetch()) {
    $TimeAdded = $util->formatNumDate($TimeAdded);
    $Note = $util->XMLEscape($Note);
    $row =$pagemaker->new('config'=>$config,languageCode=>$session->getLanguageCode());
    $row->setTemplate('xmlrow');
    $row->setTags('ID',$EmailID,'word',$Word,'maxcount',$MaxCount,'count',$Count,
     'numdeleted',$NumDeleted,'numforwarded',$NumForwarded,'timeadded',$TimeAdded,
     'address',$Address,'sender',$Sender,'hidden',$Hidden,'notes',$Note);
    $page->concatenate($row);
  }
  $bottom =$pagemaker->new('config'=>$config,languageCode=>$session->getLanguageCode());
  $bottom->setTemplate('xmlbottom');
  $page->concatenate($bottom);
  $page->setTags('username',$session->{'UserName'}, 'prefix', $session->{'Prefix'});
  $page->printPage();

}

sub getSignUpForm {
  my $config = shift;
  my $session = shift;
  my $util = shift;
  my $signupformtemplate = $config->getCaptchagenHost() ? 'signupform.html' : 'signupformnocaptcha.html';
  my $page =$pagemaker->new(config=>$config,languageCode=>$session->getLanguageCode(),template=>$signupformtemplate);
  $page->setTags('imagefilename',$session->getImageFileName(),
                 'loginmsg', $session->{'loginmsg'},
                 'action', $thisscript,
                 'newuser', $util->webSanitize($session->param('newuser')),
                 'imagehash', $session->getImageHash(),
                 'typeimageword', $session->getDialog('typeimageword'),
                 'providepassword', $session->getDialog('providepassword'),
                 'newpass', $session->getDialog('newpass'),
                 'confirm', $session->getDialog('confirm'),
                 'realemail', $util->webSanitize($session->param('realemail')),
                 'go', $session->getDialog('go'),
                 'cannotreadimage', $session->getDialog('cannotreadimage')
                 );
  $session->{'loginmsg'} = ''; # we've moved this to the form, so we don't want it to show on the main page
  return $page;
}

sub getMySendToForm {
  my $config = shift;
  my $session = shift;
  my $disposable = shift;
  my $msg = shift;
  my ($sql,$st,%attr,$EmailID,$Address,$page) = ('',0,{},0,'','');
  $disposable = 0 if !$disposable;
  $msg = '' if !$msg;
  $sql = "SELECT EmailID, Address
   FROM Emails WHERE UserID = ? AND ((Count > -10 AND Hidden <> 1) OR EmailID = ?  );";
  $st = $config->db->prepare($sql);
  $st->execute($session->getUserID(), $disposable);
  $st->bind_columns(\%attr,\$EmailID,\$Address);
  my $addressoptions = '';
  my $domainoptions = '';
  my $option = '';
  my $domain;
  my $selecteddomain;
  if ($session->param('domain')) {
    $selecteddomain = $session->param('domain');
  } else {
    $selecteddomain = $config->getMailHost();
  }

  my $selected = '';
  while ($st->fetch()) {
    if ($EmailID eq $disposable) {
      $selected = 'SELECTED';
    } else {
      $selected = '';
    }
    $option =$pagemaker->new(template=>'sendfromoption', languageCode=>$session->getLanguageCode());
    $option->setTags('emailid',$EmailID,'selected', $selected, 'address',$Address);
    $addressoptions .= $option->getContent();
  }
  my @domains = $config->getLocalDomains();
  foreach $domain (@domains) {
    $selected = '';
    if ($domain eq $selecteddomain) {
      $selected = 'SELECTED';
    }
    $option =$pagemaker->new(template=>'domainoption', languageCode=>$session->getLanguageCode());
    $option->setTags('domain', $domain, 'selected', $selected);
    $domainoptions .= $option->getContent();
  }
  if ($session->param('domain')) {
    $domain = $session->param('domain');
  } else {
    $domain = $config->getMailHost();
  }
  $page =$pagemaker->new(template=>'mysendtoform.html',languageCode=>$session->getLanguageCode());
  my $recipient = $session->param('recipient');
  my $prefix = '';
  if ($session->Prefix()) {
    $prefix = $session->Prefix() . ' .';
  }
  $page->setTags('msg', $msg,
                 'enterrecipient',$session->getDialog('enterrecipient'),
                 'choosedisposable',$session->getDialog('choosedisposable'),
                 'makenewdisposable',$session->getDialog('makenewdisposable'),
                 'domainrequired',$session->getDialog('domainrequired'),
                 'recipientrequired',$session->getDialog('recipientrequired'),
                 'domainnotinlist',$session->getDialog('domainnotinlist'),
                 'recipient', $recipient,
                 'returntoadvancedmode',$session->getDialog('returntoadvancedmode'),
                 'addressoptions', $addressoptions,
                 'prefix', $prefix,
                 'word', $session->getDialog('word'),
                 'number', $session->getDialog('number'),
                 'domain', $selecteddomain,
                 'domainoptions', $domainoptions,
                 'username', $session->getUserName(),
                 'go', $session->getDialog('go'),
                 'sendfromdescription', $session->getDialog('sendfromdescription')
                 );
  return $page;
}

sub getMyUpdateForm {
  my $config = shift;
  my $session = shift;
  my $disposable = shift;
  my $msg = shift;
  my ($sql,$st,%attr,$page) = ('',0,{},'');
  my $UserID = $session->getUserID();
  my ($EmailID,$Word,$MaxCount,$Count,$TimeAdded,$Sender,$Address,$Hidden,$Note);
  my ($isHidden,$isNotHidden) = ('','CHECKED');
  my $showHidden = 'CHECKED' if $session->param('showHidden');
  my $searchterms = $session->param('searchterms');

  $EmailID = $session->param('EmailID');
  $sql = "SELECT EmailID, Word, InitialCount, Count, TimeAdded, Sender, Address, Hidden, Note
   FROM Emails WHERE UserID = ? AND EmailID = ?;";
  $st = $config->db->prepare($sql);
  $st->execute($UserID,$EmailID);
  $st->bind_columns(\%attr,\$EmailID,\$Word,\$MaxCount,\$Count,
   \$TimeAdded,\$Sender,\$Address,\$Hidden,\$Note);
  $st->fetch();
  $page = $pagemaker->new(config=>$config,languageCode=>$session->getLanguageCode()); 
  if ($Count >= -10) {

    if ($Hidden == 1) {
      ($isHidden,$isNotHidden) = ('CHECKED','');
    }
    $Address = $Word if !$Address; # before Feb, 2001, Addresses weren't stored...
    my $message = $Address;

    srand();
    my $r = rand(10000);

    $page->setTemplate('myupdateform.html');
    $page->setTags('message',$message,'action',$thisscript,'emailid',$EmailID,
    'updateaddress',$session->getDialog('updateaddress'),
     'remainingmessages',$session->getDialog('remainingmessages'),
     'exclusivesender',$session->getDialog('exclusivesender'),
     'thenote',$session->getDialog('note'),
     'hidden',$session->getDialog('hidden'),
     'nothidden',$session->getDialog('nothidden'),
     'updatedescription',$session->getDialog('updatedescription'),
     'trustedwarning',$session->getDialog('trustedwarning'),
     'sendfromaddress',$session->getDialog('sendfromaddress'),
     'editexemplar',$session->getDialog('editexemplar'),
     'delete',$session->getDialog('delete'),
     'deleteareyousure',$session->getDialog('deleteareyousure'),
     'randomnumber',$r,'count',$Count,'sender',$Sender,'searchterms',$searchterms,'note',$Note,
     'ishidden',$isHidden,'isnothidden',$isNotHidden,'showhidden',$showHidden,'returnwithoutsaving',
      $session->getDialog('returnwithoutsaving'));
  } else {
    $page->setTemplate('addressdisabled.html');
    $page->setTags('message', $session->getDialog('addressdisabled'),
     'returnwithoutsaving', $session->getDialog('returnwithoutsaving'));
  }
  return $page

}

sub getEditExemplarForm {
  my $config = shift;
  my $session = shift;
  my $disposable = shift;
  my $msg = shift;
  my ($sql,$st,%attr,$EmailID,$Address,$Word,$Number,$page) = ('',0,{},0,'','','','');
  $disposable = 0 if !$disposable;
#  $msg = "disposable is $disposable" if !$msg;
  $sql = "SELECT EmailID, Address, Word
   FROM Emails WHERE UserID = ? AND EmailID = ?";
  $st = $config->db->prepare($sql);
  $st->execute($session->getUserID(), $disposable);
  $st->bind_columns(\%attr,\$EmailID,\$Address, \$Word);
  $st->fetch();
  $msg = $Address;
#  if ($st->fetch()) {
#$msg .= " editing $Address word is $Word";
#  } else {
#$msg .= " no fetch?";
#  }
  my $domainoptions = '';
  my $option = '';
  my $domain;
  my $selecteddomain;
  $Address =~ /(.*)\@(.*)/;
  my $localpart = $1;
  my $existingdomain = $2;
  if ($session->param('domain')) {
    $selecteddomain = $session->param('domain');
  } elsif ($existingdomain) {
    $selecteddomain = $existingdomain;
  } else {
    $selecteddomain = $config->getMailHost();
  }
  my $selected = '';
  my @domains = $config->getLocalDomains();
  foreach $domain (@domains) {
    $selected = '';
    if ($domain eq $selecteddomain) {
      $selected = 'SELECTED';
    }
    $option =$pagemaker->new(template=>'domainoption', languageCode=>$session->getLanguageCode());
    $option->setTags('domain', $domain, 'selected', $selected);
    $domainoptions .= $option->getContent();
  }
#  if ($session->param('domain')) {
#    $domain = $session->param('domain');
#  } else {
#    $domain = $config->getMailHost();
#  }
  my ($mprefix,$mword,$mcount,$musername);
  my $delimiters = $config->getDelimiters();
  if ($localpart =~ /(.+)[$delimiters](.+)[$delimiters](.+)[$delimiters](.+)/) {
    ($mprefix,$mword,$mcount,$musername) = ($1,$2,$3,$4);
  } elsif ($localpart =~ /(.+)[$delimiters](.+)[$delimiters](.+)/) {
    ($mprefix,$mword,$mcount,$musername) = ('',$1,$2,$3);
  } elsif ($localpart =~ /(.+)[$delimiters](.+)/) {
    ($mprefix,$mword,$mcount,$musername) = ('',$1,'',$2);
  }
  $mword = $Word if !$mword;
  $musername = $session->getUserName() if !$musername;

  $page = $pagemaker->new(template=>'editexemplarform.html',languageCode=>$session->getLanguageCode());
  my $prefix = '';
  my $prefixinput = '';
#  if ($session->Prefix()) {
#    $prefix = $session->Prefix();
#  } else {
    $prefix = $mprefix;
#  }
  if ($prefix || $session->Prefix) {
    $prefixinput = $pagemaker->new(template=>'prefixtextinput',languageCode=>$session->getLanguageCode());
    $prefixinput->setTags(
                 'prefix', $session->getDialog('prefix'),
                 'theprefix', $prefix
                 );
  } else {
    $prefixinput = $pagemaker->new(template=>'prefixhiddeninput',languageCode=>$session->getLanguageCode());
  }

  $page->setTags('msg', $msg,
                 'domainrequired',$session->getDialog('domainrequired'),
                 'domainnotinlist',$session->getDialog('domainnotinlist'),
                 'canonlychangecase', $session->getDialog('canonlychangecase'),
                 'returntoadvancedmode',$session->getDialog('returntoadvancedmode'),
                 'disposable', $EmailID,
                 'prefixinput', $prefixinput->getContent(),
                 'currentprefix', $session->Prefix(),
                 'prefixmismatch', $session->getDialog('prefixmismatch'),
                 'numberrequiredforprefix', $session->getDialog('numberrequiredforprefix'),
                 'word', $session->getDialog('word'),
                 'theword', $mword,
                 'username', $musername,
                 'theusername', $session->getUserName(),
                 'user', $session->getDialog('user'),
                 'number', $session->getDialog('number'),
                 'thenumber', $mcount,
                 'thedomain', $selecteddomain,
                 'domain', $selecteddomain,
                 'domainoptions', $domainoptions,
                 'username', $session->getUserName(),
                 'go', $session->getDialog('go'),
                 'editexemplardescription', $session->getDialog('editexemplardescription')
                 );
  return $page;
}



sub myemails {
  my $config = shift;
  my $session = shift;
  my $util = shift;
  my ($message,$data,$sql,$st) = ('','','','');
  my %attr;
  my $page =$pagemaker->new(config=>$config,languageCode=>$session->getLanguageCode());
  my $UserID = $session->{'UserID'};
  my ($searchterms,$urlsearchterms,$searchrestriction) = ('','','');
  my $showHidden = '';
  my $showAddressInSearch = 0;
  if ($UserID) {
    $showHidden = 'CHECKED' if $session->param('showHidden');
    $searchterms = $session->param('searchterms');
    my ($EmailID,$Word,$MaxCount,$Count,$NumDeleted,$NumForwarded,$TimeAdded,$Sender,$Address,$Hidden,$Note)
     = (       0,  '',        0,     0,          0,            0,         0,     '',      '',      0,    '');

    if ($session->param('myupdateform')) {
      $page = &getMyUpdateForm($config,$session,$session->param('disposable'));
    } elsif ($session->param('mysendtoform')) {
      $page = &getMySendToForm($config,$session,$session->param('disposable'));
   
    } elsif ($session->param('recipient')) { # process new sendto address
      my $ph = '';
      my $toAddress = '';
      my $alreadyexists = 0;
      my $recipient = $session->param('recipient');
      $recipient =~ s/^\s*//;
      $recipient =~ s/\s*$//;
      my $disposable = $session->param('disposable');
      if ($disposable && !$session->param('word')) {
        # first, get the address info
        $sql = 'SELECT Word, PrivateHash, Address
         FROM Emails WHERE EmailID = ? AND UserID = ? AND Count > -10;';
        $st = $config->db->prepare($sql);
        $st->execute($disposable, $UserID);
        $st->bind_columns(\%attr,\$Word,\$ph, \$Address);
        $st->fetch();
        if ($Word) { # if it's there and not disabled, refresh the address
          $sql = 'UPDATE Emails SET Count = InitialCount, Hidden = 0 WHERE 
                  EmailID = ? AND UserID = ? AND Count > -10;';
          $st = $config->db->prepare($sql);
          $st->execute($disposable,$UserID);
        }
      } else {
        $Word = $session->param('word');
        $Word =~ s/^\s*//;
        $Word =~ s/\s*$//;
        #create a new address
        $sql = "SELECT EmailID FROM Emails WHERE Word = ? AND UserID = ?";
        $st = $config->db->prepare($sql);
        $st->execute($Word, $UserID);
        $st->bind_columns(\%attr,\$disposable);
        if ($st->fetch()) {
          $alreadyexists = 1;
        } else {
          my $sender = '';
          my $number = $session->param('number');
          my $defaultnumber = 3;
          $sql = "SELECT DefaultNumber FROM Users WHERE UserID = ?";
          $st = $config->db->prepare($sql);
          $st->execute($UserID);
          $st->bind_columns(\%attr,\$defaultnumber);
          $st->fetch();
          my $count = $util->getNumberFromString($number,$defaultnumber);
          $number = "$number." if $number || $number eq '0';
          if ($count eq 'sender' || $count eq '+') {
            $sender = $recipient;
          } elsif ($count eq 'domain' || $count eq '*') {
            $recipient =~ /\@(.*)/;
            $sender = $1;
          }
          $Address = $Word . '.' . $number . $session->getUserName() . '@' . $session->param('domain');
          if ($session->Prefix()) {
            $Address = $session->Prefix() . '.' . $Address;
          }
          my $now = time();
          $ph = md5_hex($UserID . rand() . $now . $config->getSecretPhrase());
          $sql = "INSERT INTO Emails
           (UserID,Word,InitialCount,Count,TimeAdded,Address,PrivateHash,Sender)
           VALUES (?,?,?,?,?,?,?,?);";
          $st = $config->db->prepare($sql);
          $st->execute($UserID,$Word,$count,
           $count,$now,$Address,$ph,$sender);
          $sql = 'SELECT EmailID FROM Emails WHERE Word = ? AND UserID = ?';
          $st = $config->db->prepare($sql);
          $st->execute($Word,$UserID);
          $st->bind_columns(\%attr,\$disposable);
          $st->fetch();
        }
      }
      if ($alreadyexists) {
        my $msg = $session->getDialog('addressalreadyexists','word',$Word);
        $page = &getMySendToForm($config,$session,$disposable,$msg);
      } else {
        if ($Word) {
          $toAddress = $util->getRedirectedAddress($recipient,
                                           $Word,
                                           $session->getUserName(),
                                           $ph);
        }
        if (!$session->hasFeature('MASKFORWARD')) { # turn on address masking if it's not on
          $session->addFeature($config->getFeature('MASKFORWARD'));
          $sql = "UPDATE Users SET Features = ? WHERE UserID = ?;";
          $st = $config->db->prepare($sql);
          $st->execute($session->getFeatures(),$UserID);
        }
        $page->setTemplate('sendtoaddress.html');
        $page->setTags('returntoadvancedmode',$session->getDialog('returntoadvancedmode'),
                     'usethisaddress',$session->getDialog('usethisaddress'),
                     'messagewillbefrom',$session->getDialog('messagewillbefrom'),
                     'recipient',$recipient,
                     'action', $thisscript,
                     'emailid', $disposable,
                     'disposable',$Address,
                     'toaddress',$toAddress);
      }
      
    } elsif ($session->param('editexemplarform')) {
      $page = &getEditExemplarForm($config,$session,$session->param('disposable'));
    } else {

      if ($session->param('editexemplar')) {
        $EmailID = $session->param('editexemplar');
        my $ExistingWord;
        $sql = "SELECT Word FROM Emails WHERE EmailID = ? AND UserID = ?";
        $st = $config->db->prepare($sql);
        $st->execute($EmailID,$UserID);
        $st->bind_columns(\%attr,\$ExistingWord);
        $st->fetch();
        $Word = $session->param('word');
        if (lc($Word) ne lc($ExistingWord)) {
          $Word = $ExistingWord;
        }
        my $UserName = $session->param('username');
        my $Number = $session->param('number');
        my $AdrPrefix = $session->param('adrprefix');
        my $Domain = $session->param('domain');
        if (lc($UserName) ne lc($session->getUserName())) {
          $UserName = $session->getUserName();
        }
        my $adr = $UserName . '@' . $Domain;
        $adr = "$Number.$adr" if $Number;
        $adr = "$Word.$adr";
        $adr = "$AdrPrefix.$adr" if $AdrPrefix;
        $sql = "UPDATE Emails SET Address = ? WHERE EmailID = ? AND UserID = ?";
        $st = $config->db->prepare($sql);
        $st->execute($adr,$EmailID,$UserID);
        $showAddressInSearch = $EmailID;
      }
      if ($session->param('deleteaddress')) {
        $EmailID = $session->param('disposable');
        $sql = "SELECT Address FROM Emails WHERE EmailID = ? AND UserID = ?";
        my $adr;
        $st = $config->db->prepare($sql);
        $st->execute($EmailID,$UserID);
        $st->bind_columns(\%attr,\$adr);
        $st->fetch(); 
        $sql = "DELETE FROM Emails WHERE EmailID = ? AND UserID = ?";
        $st = $config->db->prepare($sql);
        $st->execute($EmailID,$UserID);
        $message .= "$adr " . $session->getDialog('deleted');
      }
      if ($session->param('updateemail')) {
        $Sender = $session->param('sender');
        $Count = $session->param('count');
        $EmailID = $session->param('updateemail');
        $Hidden = $session->param('hidden');
        $Note = $session->param('note');
        $Count = int($Count);
        $Count = 0 if (!$Count || $Count < 1);
        $Count = 20 if $Count > 20;
        $EmailID = int($EmailID);
        $EmailID = 0 if !$EmailID;
        
        $sql = "UPDATE Emails SET InitialCount = ?, Count = ?, Sender = ?, Hidden = ?, Note = ?
         WHERE EmailID = ? AND UserID = ? AND Count >= -10";
        $st = $config->db->prepare($sql);
        $st->execute($Count, $Count,$Sender,$Hidden,$Note,$EmailID,$UserID);
        $showAddressInSearch = $EmailID;
      }


      if ($showAddressInSearch) {
        $searchrestriction = "AND EmailID = $showAddressInSearch";
      } elsif ($searchterms) {
        $urlsearchterms = $util->URLEncode($searchterms);
        $searchrestriction = $util->getSearchRestriction($searchterms,1,'Prefix','Word','Address','Sender','Note');
      }
      srand();
      my $r=rand(10000);

      my $orderby = '';
      if (defined($session->param('orderby') )) {
        if ($session->param('orderby') == 1) {
          $orderby = 'Prefix';
        } elsif ($session->param('orderby') == 2) {
          $orderby = 'Word';
        } elsif ($session->param('orderby') == 3) {
          $orderby = 'InitialCount';
        } elsif ($session->param('orderby') == 4) {
          $orderby = 'Count';
        } elsif ($session->param('orderby') == 5) {
          $orderby = 'TimeAdded';
        } elsif ($session->param('orderby') == 6) {
          $orderby = 'Address';
        } elsif ($session->param('orderby') == 7) {
          $orderby = 'Sender';
        } elsif ($session->param('orderby') == 8) {
          $orderby = 'NumForwarded';
        } elsif ($session->param('orderby') == 9) {
          $orderby = 'NumDeleted';
        }
      }
      if ($orderby && $session->param('desc')) {
        $orderby .= " DESC";
      }
      $orderby = " TimeAdded DESC" if !$orderby;

      my $hiddenrestriction = '';
      $hiddenrestriction = ' AND HIDDEN = 0 ' if !$showHidden && !$showAddressInSearch;
   

      $sql = "SELECT EmailID, Word, InitialCount, Count, NumDeleted, NumForwarded,
       TimeAdded, Sender, Address, Note, Hidden 
       FROM Emails WHERE UserID = ? $searchrestriction $hiddenrestriction 
       ORDER BY $orderby";

#$config->debug("$sql \n UserID=$UserID; orderby=$orderby");

      $st = $config->db->prepare($sql);
      $st->execute($UserID);
      $st->bind_columns(\%attr,\$EmailID,\$Word,\$MaxCount,\$Count,\$NumDeleted,
       \$NumForwarded,\$TimeAdded,\$Sender,\$Address,\$Note,\$Hidden);
      my $row;
      while ($st->fetch()) {
        $TimeAdded = $util->formatNumDate($TimeAdded);
        $Note = $util->escapeAngleBrackets($Note);
        $Word = $util->highlight($searchterms,$Word,'#FFFF00');
        #$Word = $session->getDialog('clicktoedit') if !$Word;
        $Address = $util->highlight($searchterms,$Address,'#FFFF00');
        $Sender = $util->highlight($searchterms,$Sender,'#FFFF00');
        $Note = $util->highlight($searchterms,$Note,'#FFFF00');
        $Count = "<b>$Count</b" if $Count == 0;

        $row =$pagemaker->new('config'=>$config,languageCode=>$session->getLanguageCode());
        if (!$Hidden) {
          $row->setTemplate('myemailrow');
        } else {
          $row->setTemplate('myhiddenemailrow');
        }
        $row->setTags('word',$Word,'action',$thisscript,'emailid',$EmailID,'showhidden',
         $showHidden,'searchterms',$urlsearchterms,
         'maxcount',$MaxCount,'count',$Count,
         'numdeleted',$NumDeleted,'numforwarded',$NumForwarded,'timeadded',$TimeAdded,
         'address',$Address,'sender',$Sender,'hidden',$Hidden,'note',$Note);
        $data .= $row->getContent();
      }
# blowing up netscape
#      if ($session->param('updateemail')) {
#        $data .= "\n<script language='JavaScript'>location='?myemails=1#".$session->param('updateemail')."';</script>\n";
#      }
      $st='';
      $page->setTemplate('myemails.html');
      $page->setTags('yourdisposableaddresses', $session->getDialog('yourdisposableaddresses'),
                     'search', $session->getDialog('search'),
                     'showhiddenaddresses', $session->getDialog('showhiddenaddresses'),
                     'word', $session->getDialog('word'),
                     'clicktoedit', $session->getDialog('clicktoedit'),
                     'maxcount', $session->getDialog('maxcount'),
                     'remaining', $session->getDialog('remaining'),
                     'forwarded', $session->getDialog('forwarded'),
                     'deleted', $session->getDialog('deleted'),
                     'created', $session->getDialog('created'),
                     'fulladdress', $session->getDialog('fulladdress'),
                     'exclusivesender', $session->getDialog('exclusivesender'),
                     'note', $session->getDialog('note'));

      $page->setTags('message',$message,'searchterms',$searchterms,'urlsearchterms',$urlsearchterms,'randomnumber',$r,
       'showhidden',$showHidden,'action',$thisscript,'returntoadvancedmode',$session->getDialog('returntoadvancedmode'),'data',$data); 
    }
  } else {
    $message = $session->getDialog('notloggedin');
    $data = '';
    $page->setTemplate('myemails.html');
    $page->setTags('yourdisposableaddresses', $session->getDialog('yourdisposableaddresses'),
                   'search', $session->getDialog('search'),
                   'showhiddenaddresses', $session->getDialog('showhiddenaddresses'),
                   'word', $session->getDialog('word'),
                   'clicktoedit', $session->getDialog('clicktoedit'),
                   'maxcount', $session->getDialog('maxcount'),
                   'remaining', $session->getDialog('remaining'),
                   'forwarded', $session->getDialog('forwarded'),
                   'deleted', $session->getDialog('deleted'),
                   'created', $session->getDialog('created'),
                   'fulladdress', $session->getDialog('fulladdress'),
                   'exclusivesender', $session->getDialog('exclusivesender'),
                   'note', $session->getDialog('note'));

    $page->setTags('message',$message,'data',$data);
  }
  return $page;
}



sub getYourStats {
  my $config = shift;
  my $session = shift;
  my $yourstats = '';
  my (%attr,$sql,$st,$useraddresscount);
  if ($session->{'UserID'}) {
    my $f = $session->{'NumForwarded'};
    my $d = $session->{'NumDeleted'};
    $yourstats = $session->getDialog('yourstats','forwarded',$f,'eaten',$d);
    $sql = "SELECT COUNT(EmailID) FROM Emails WHERE UserID = ?";
    $st = $config->db->prepare($sql);
    $st->execute($session->{'UserID'});
    $st->bind_columns(\%attr,\$useraddresscount);
    $st->fetch();
    $yourstats .= $session->getDialog('youraddresscount','addresscount',$useraddresscount);
  } elsif ($session->getImageHash()) {
    $yourstats = '';  # don't show stats on signup page
  } else {
    $yourstats = $session->getDialog('notloggedin');
  }
  return $yourstats;
}




sub mainPage {
  my $config = shift;
  my $session = shift;
  my $util = shift;
  my ($msg,$pendingmsg,$sendercount,$watchwordcount,$serverstats,
   $maskforwardon,$maskforwardoff,$watchwordson,$watchwordsoff,
   $emlon,$emloff,$dlhmon,$dlhmoff,$hston,$hstoff,$tsoon,$tsooff,
   $todaycount,$counterID,$weekchart,$normallink,$securelink);
  my ($Senders,$Watchwords);
  my ($sql,$st,%attr);
  my $UserID = $session->{'UserID'};
  my $yourstats = '';
  my $motdNum = getMOTDnum(); 
  my $motd = $session->getDialog("motd$motdNum");
  my $saying = $session->getDialog('saying' . &getSayingNum());

  if (&secureMode()) {
    $normallink = '<a href="' . $config->getConfigParameter('normalURL') . $thisscript . '?languageCode=' . $session->getLanguageCode() . '">' . $session->getDialog('normal') . '</a>';
    $securelink = $session->getDialog('secure');
  } else {
    $normallink = $session->getDialog('normal');
    $securelink = '<a href="' . $config->getConfigParameter('secureURL') . $thisscript . '?languageCode=' . $session->getLanguageCode() . '">' . $session->getDialog('secure') . '</a>';
  } 

## yourstats:
 # moved to below myemails
#  $yourstats = &getYourStats($config, $session);

## email address confirmation
  if ($session->param('confirmemailchange')
   || $session->param('cec')
   ) {
    $msg .= &confirmemailchange($config,$session);
  }
			  
## data updates here
  $msg .= &doUpdates($config, $session, $util);

  if ($UserID) {

## get more current info here
    my ($TrustedID,$Sender);
    $sql = "SELECT PermittedID, Sender FROM Permitted WHERE UserID = ?";
    $st = $config->db->prepare($sql);
    $st->execute($UserID);
    $st->bind_columns(\%attr,\$TrustedID,\$Sender);
    while ($st->fetch()) {
      $Sender = $util->escapeAngleBrackets($Sender);
      $Senders .= "<br>$Sender (<a href=\"$thisscript?deletesender=$TrustedID&advanced=1\">" . $session->getDialog('delete') . "</a>)\n";
      $sendercount ++;
    }
    if ($Senders) {
      $Senders = $session->getDialog('yourtrustedsenders','sendercount',$sendercount).$Senders;
    }

    my ($WatchwordID,$Watchword);
    $sql = "SELECT WatchwordID, Watchword FROM Watchwords WHERE UserID = ?";
    $st = $config->db->prepare($sql);
    $st->execute($UserID);
    $st->bind_columns(\%attr,\$WatchwordID,\$Watchword);
    while ($st->fetch()) {
      $Watchword = $util->escapeAngleBrackets($Watchword);
      $Watchwords .= "<br>$Watchword (<a href=\"$thisscript?deletewatchword=$WatchwordID&advanced=1\">" . $session->getDialog('delete') . "</a>)\n";
      $watchwordcount ++;
    }
    if ($Watchwords) {
      $Watchwords = $session->getDialog('yourwatchwords','watchwordcount',$watchwordcount).$Watchwords;
    }
  }
  $Senders = $session->getDialog('yourtrustedsenders','sendercount','0') if !$Senders;
  $Watchwords = $session->getDialog('yourwatchwords','watchwordcount','0') if !$Watchwords;



## maskforward setting
  if ($session->hasFeature('MASKFORWARD')) {
    $maskforwardon = "CHECKED";
    $maskforwardoff = "";
  } else {
    $maskforwardon = "";
    $maskforwardoff = "CHECKED";
  }

## watchwords setting
  if ($session->hasFeature('WATCHWORDS')) {
    $watchwordson = "CHECKED";
    $watchwordsoff = "";
  } else {
    $watchwordson = "";
    $watchwordsoff = "CHECKED";
  }


## eml setting
  if ($session->hasFeature('EATENMESSAGELOG')) {
    $emlon = "CHECKED";
    $emloff = "";
  } else {
    $emlon = "";
    $emloff = "CHECKED";
  }

# don't log hidden address messages setting
  if ($session->hasFeature('DONOTLOGHIDDEN')) {
    $dlhmon = "CHECKED";
    $dlhmoff = "";
  } else {
    $dlhmon = "";
    $dlhmoff = "CHECKED";
  }
# hide subject tagline setting
  if ($session->hasFeature('DISABLETAGLINE')) {
    $hston = "CHECKED";
    $hstoff = "";
  } else {
    $hston = "";
    $hstoff = "CHECKED";
  }
# hide for trusted/exclusiveonly setting
  if ($session->hasFeature('DISABLETAGLINETRUSTEDEXCLUSIVE')) {
    $tsoon = "CHECKED";
    $tsooff = "";
  } else {
    $tsoon = "";
    $tsooff = "CHECKED";
  }


## set pending msg, if needed
  if (!$session->RealEmail() && $session->PendingEmail() 
   || ($session->PendingEmail() &&  $session->RealEmail() ne $session->PendingEmail()) 
   ) { # && !param('realemail')) {
    $pendingmsg = $session->getDialog('pendingmessage','paddr',$session->PendingEmail() );
  }

## gluttony counts

  ($serverstats,$counterID,$todaycount) = &getServerStats($config,$session);

  $weekchart = &getWeekchart($session,$counterID,$todaycount) if $counterID;

  $st = '';
  my $mainpage =$pagemaker->new(template=>'mainpage.html',languageCode=>$session->getLanguageCode());
  my $flags =$pagemaker->new(template=>'flags.html',languageCode=>$session->getLanguageCode());
  $flags->setTags('action',$thisscript);
  my $adsense = '';
  my $adsensemedrect = '';
  my $explorerkiller = ''; #$pagemaker->new(template=>'explorernotkiller')->getContent();
  my $analytics = '';
  my $adsensesmall = '';
  if (!&secureMode()) {
    $adsense =$pagemaker->new(template=>'adsense', languageCode=>$session->getLanguageCode());
    $adsense->setTags('addisclaimer',$session->getDialog('addisclaimer'));
    $adsense = $adsense->getContent();
#    $adsensesmall=$pagemaker->new(template=>'adsensesmall')->getContent();
#    $explorerkiller = $pagemaker->new(template=>'explorerkiller')->getContent();
#    $analytics = $pagemaker->new(template=>'analytics')->getContent();
#    $adsensemedrect = $pagemaker->new(template=>'adsensemedrect',languageCode=>$session->getLanguageCode())->getContent();
  }
  my $loginform =$pagemaker->new(languageCode=>$session->getLanguageCode());
  my $form = $pagemaker->new(languageCode=>$session->getLanguageCode());
  my $content =$pagemaker->new(languageCode=>$session->getLanguageCode());
  my $tabs =$pagemaker->new(languageCode=>$session->getLanguageCode());

  my $eml =$pagemaker->new(languageCode=>$session->getLanguageCode());
  my ($alert,$button,$myemailslink,$xmllink,$sendtolink,$onload);

  if (!$UserID) {
    $loginform->setTemplate('loginform.html');
    my $remembermecheck = '';
    my $rememberme = '';
    $remembermecheck =$pagemaker->new(template=>'remembermecheck',languageCode=>$session->getLanguageCode());
    $rememberme = $session->getDialog('rememberme');
    $loginform->setTags(
                        'action', $config->getConfigParameter('secureURL') . $thisscript,
                        'login',$session->getDialog('login'),
                        'user',$session->getDialog('user'),'pass',$session->getDialog('pass'),
                        'remembermecheck', $remembermecheck->getContent(), 'rememberme', $rememberme,
                        'forgotpassword', $session->getDialog('forgotpassword'),
                        'createaccount',$session->getDialog('createaccount'),'newuser',$session->getDialog('newuser'),
                        'newpass',$session->getDialog('newpass'),'confirm',$session->getDialog('confirm'),
                        'email',$session->getDialog('email'),'go',$session->getDialog('go'),  
                        'realemail',$util->webSanitize($session->param('realemail')));

    $alert = $session->getDialog('mustloginfirst');
    $myemailslink = "javascript:$alert";
    $xmllink = "javascript:$alert";
    $sendtolink = "javascript:$alert";
    $button = 'button';
    $onload = 'if(!hastyped){document.loginform.user.focus();}' if !$session->getImageHash();
  } else {
    $loginform->setTemplate('loggedinform.html');
    $loginform->setTags('changepassword',$session->getDialog('changepassword'),'currpass',$session->getDialog('currpass'),
                        'newpass',$session->getDialog('newpass'),'confirm',$session->getDialog('confirm'),
                        'go',$session->getDialog('go'),'logout',$session->getDialog('logout'));

    $myemailslink = "$thisscript?myemails=1";
    $xmllink = "$thisscript?xml=1";
    $sendtolink = "$thisscript?myemails=1&mysendtoform=1";
    $button = 'submit';
  }

  if ($session->param('myemails')) {
    $content = &myemails($config, $session, $util);
    $tabs->setTemplate('advancedtabs.html');
  } elsif ($session->getImageHash()) {
    $loginform =$pagemaker->new(template=>'noform.html');
    $content = &getSignUpForm($config, $session,$util);
    $tabs->setTemplate('nobrainertabs.html');
  } elsif ($UserID && $session->param('resetpassword')) {
    $content->setTemplate('newpassword.html');
    $content->setTags('setnewpassword',$session->getDialog('setnewpassword'),
                      'newpass', $session->getDialog('newpass'),
                      'confirm', $session->getDialog('confirm'),
                      'hc', $session->param('hc')
                      );
    $tabs->setTemplate('nobrainertabs.html');


  } elsif ($session->param('sendpasswordreset')) {
    $content->setTemplate('sendpasswordreset.html');
    $content->setTags('sendpasswordreset',$session->getDialog('sendpasswordreset'),
                      'user', $session->getDialog('user'),
                      'email', $session->getDialog('email'),
                      'go', $session->getDialog('go')
                      );
    $tabs->setTemplate('nobrainertabs.html');

  } elsif ((!$session->{'Prefix'} && !$sendercount 
           && !$watchwordcount && !$session->param('advanced')) 
           || $session->param('nobrainer')) {
    $form->setTemplate('nobrainerform.html');
   # $form->setTags('forwardingaddress',$session->getDialog('forwardinaddress'),
                   
    $content->setTemplate('nobrainercontent.html');
    $tabs->setTemplate('nobrainertabs.html');
  } else {

    # advanced mode, so get the eaten message log:
    if ($UserID && $session->hasFeature('EATENMESSAGELOG')) {
      my $emlData = '';
      my ($chunk,$time,$date,$from,$for) = ('','','','','');
      my $num = 0;
      my $emlRows = '';
      $sql = "SELECT EatenMessageLog from Users where UserID = ?";
      $st = $config->db->prepare($sql);
      $st->execute($UserID);
      $st->bind_columns(\%attr,\$emlData);
      $st->fetch();
      if ($emlData) {
        my $emlRow = '';
        my ($stcheck,$eid,$chunksize);
        while ($emlData) {
          $chunksize = length($emlData) > 84 ? 85 : length($emlData);
          $chunk = substr($emlData,0,$chunksize);
          $time = substr($chunk,0,10);
          $date = $util->formatNumDate($time);
          $from = substr($chunk,10,55);
          $from =~ s/\s*$//;
          $for = substr($chunk,65,20);
          $for =~ s/\s*$//;
          $eid = '';
          $sql = "SELECT EmailID FROM Emails WHERE Word = ? AND UserID = ?";
          $stcheck = $config->db->prepare($sql);
          $stcheck->execute($for, $session->{'UserID'});
          $stcheck->bind_columns(\%attr, \$eid);
          $stcheck->fetch();
          my $template = 'EMLRow';
          $template = 'EMLRowNoLink' if !$eid;
          $emlRow =$pagemaker->new(template=>$template,languageCode=>$session->getLanguageCode());
          $emlRow->setTags('action',$thisscript,'date',$date,'from',$from,'for',$for,'EmailID',$eid);
          $emlRows .= $emlRow->getContent();
          $emlData = substr($emlData, $chunksize, (length($emlData) - $chunksize));
          $num ++;
        }
        $stcheck = 0;
        $eml->setTemplate('EMLTable');
        $eml->setTags('eatenmessageinfo',$session->getDialog('eatenmessageinfo','number',$num),
                      'date',$session->getDialog('date'),
                      'from',$session->getDialog('from'),
                      'to',$session->getDialog('to'),
                      'rows',$emlRows);
      }
    }
    $form->setTemplate('advancedform.html');
    $content->setTemplate('advancedcontent.html');
    $form->setTags(
      'eml',$eml->getContent(), 
      'myemailslink',$myemailslink,
      'sendtolink', $sendtolink,
      'senders',$Senders,
      'watchwords',$Watchwords,
      'showaddresses', $session->getDialog('showaddresses'),
      'showhiddenaddresses', $session->getDialog('showhiddenaddresses'),
      'search', $session->getDialog('search'),
      'sendfromanaddress', $session->getDialog('sendfromanaddress'),
      'defaultnumber', $session->getDialog('defaultnumber'),
      'mydefaultnumber', $session->{'DefaultNumber'},
      'addtrustedsender', $session->getDialog('addtrustedsender'),
      'addwatchword', $session->getDialog('addwatchword'),
      'enabled', $session->getDialog('enabled'),
      'disabled', $session->getDialog('disabled'),
      'replyaddressmasking', $session->getDialog('replyaddressmasking'),
      'maskforwardon',$maskforwardon,'maskforwardoff',$maskforwardoff,
      'watchwordenforcement', $session->getDialog('watchwordenforcement'),
      'watchwordson',$watchwordson,'watchwordsoff',$watchwordsoff,
      'eatenmessagelog', $session->getDialog('eatenmessagelog'),
      'emlon',$emlon,'emloff',$emloff,
      'hidesubjecttagline', $session->getDialog('hidesubjecttagline'),
      'hidefortsonly', $session->getDialog('hidefortsonly'),
      'hston',$hston,'hstoff',$hstoff,
      'tsoon',$tsoon,'tsooff',$tsooff,
      'dontloghiddenaddresses', $session->getDialog('dontloghiddenaddresses'),
      'dlhmon', $dlhmon, 'dlhmoff', $dlhmoff,
      'go', $session->getDialog('go'));
    $content->setTags(
      'prefix',$session->Prefix,
      'xmllink',$xmllink
     );
    $tabs->setTemplate('advancedtabs.html');
  }

## yourstats:

  $yourstats = &getYourStats($config, $session);

  $tabs->setTags(
    'nobrainermode', $session->getDialog('nobrainermode'),
    'goodprotection', $session->getDialog('goodprotection'),
    'nomaintenance', $session->getDialog('nomaintenance'),
    'advancedmode', $session->getDialog('advancedmode'),
    'betterprotection', $session->getDialog('betterprotection'),
    'alittlemaintenance',$session->getDialog('alittlemaintenance'));
  my $formandcontent = $form->getContent() . $content->getContent();
  $mainpage->setTags(
   'mainpageintro',$session->getDialog('mainpageintro'),
   'mainjavascript',&getJS($session)->{'content'},
   'tabs',$tabs->{'content'},
   'loginform',$loginform->{'content'},
#   'spameatenthisweek',$session->getDialog('spameatenthisweek'),
   'content', $formandcontent,
   'flags',$flags->getContent(),
   'explorerkiller',$explorerkiller,
   'analytics',$analytics,
   'adsensesmall',$adsensesmall,
   'adsense',$adsense,
   'adsensemedrect',$adsensemedrect,
   'weekchart',$weekchart,
   'FAQ',$session->getDialog('FAQ'),
   'donate',$session->getDialog('donate'),
   'store',$session->getDialog('store'),
   'links',$session->getDialog('links'),
   'whatsnew',$session->getDialog('whatsnew'),
   'discuss',$session->getDialog('discuss'),
   'support',$session->getDialog('support'),
   'downloads',$session->getDialog('downloads'),
   'team',$session->getDialog('team')
   );

  my $imageshost = '';
  if (!&secureMode()) {
    $imageshost = $config->getConfigParameter('normalimageshost');
  } else {
    $imageshost = $config->getConfigParameter('secureimageshost');
  }

  $mainpage->printPage('action',$thisscript,'quote',$saying,'serverstats',$serverstats,'motd',$motd,'imageshost',$imageshost,
   'languagelist', &getLanguageList($session),'onload',$onload,'normallink',$normallink,'securelink',$securelink,
   'loginmsg',$session->{'loginmsg'},
#   'linktous',$session->getDialog('linktous'),
   'privacy',$session->getDialog('privacy'),
   'termsconditions',$session->getDialog('termsconditions'),
   'message',$msg,'pendingmsg',$pendingmsg,'yourstats',$yourstats,'button',$button,
   'onclick',$alert,'forwardingaddress',$session->getDialog('forwardingaddress'),'realemail',
   $session->RealEmail,'save',$session->getDialog('save')
   );

}


# This sub does updates for the user
#
sub doUpdates {
  my $config = shift;
  my $session = shift;
  my $util = shift;
  my $msg = '';
  my ($sql, $st);
  if ($session->param('resetpassworduser')) {
    my $u = $session->param('resetpassworduser');
    my $e = $session->param('resetpasswordemail');
    my $uid = 0;
    my $re = '';
    my %attr;
    $sql = "SELECT UserID, RealEmail FROM Users WHERE UserName = ? and RealEmail = ?";    
    $st = $config->db->prepare($sql);
    $st->execute($u, $e);
    $st->bind_columns(\%attr, \$uid, \$re);
    if ($st->fetch()) {
      if ($re) {
        my $now = time();
        my $hashcode = substr(md5_hex($uid.$now),22,32);
        $sql = "UPDATE Users SET PendingHashCode = ? WHERE UserID = ?";
        $st = $config->db->prepare($sql);
        $st->execute($hashcode, $uid);
        my $wm = Mail::Spamgourmet::WebMessages->new(config=>$config); 
        $session->setUserName($u); # this is so "from" email will be correct
        $wm->sendpasswordresetmessage($session, 
                                      $thisscript, 
                                      $re, 
                                      $hashcode);
        $msg = $session->getDialog('passwordresetsent');
      } else {
        $msg = $session->getDialog('passwordresetnotsent');
      }
    } else {
      $msg = $session->getDialog('passwordresetnotsent');
    }
  }

  if ($session->getUserID()) {
    my $UserID = $session->getUserID();
    if ($session->param('saverealemail') && $session->param('realemail') ne $session->{'RealEmail'}) {
      my $e = $session->param('realemail');
      if ( !$e || (!$util->isin($e,$config->getLocalDomains()) && $util->looksRight($e))) {
        my $now = time();
        my $hashcode = substr(md5_hex($UserID.$now),22,32);
        if ($e) {
          $sql = "UPDATE Users SET PendingEmail = ?, PendingHashCode = ? WHERE UserID = ?;";
          $st = $config->db->prepare($sql);
          $st->execute($e,$hashcode,$UserID);
          my $wm = Mail::Spamgourmet::WebMessages->new(config=>$config);
          my $username = $session->getUserName();
          $username = $session->param('user') if !$username;
          $username = $session->param('newuser') if !$username;
          $session->setUserName($username); #for the case where it's not set
          my $adminemail = $wm->sendconfirmationmessage($session,$thisscript,$e,$hashcode);
          $msg = $session->getDialog('confirmationsent', 'adminemail', $adminemail);
          $session->PendingEmail($e);
        } else {
          $sql = "UPDATE Users SET RealEmail = ?, PendingEmail = ? WHERE UserID = ?;";
          $st = $config->db->prepare($sql);
          $st->execute('','',$UserID);
          $session->RealEmail('_NULL');
#          $session->PendingEmail('_NULL');
        }

      } elsif (!$util->looksRight($e)) {
        $msg .= $session->getDialog('invalidforwardingaddress','address',$e);
      } else {
        $msg .= $session->getDialog('noaddressrecursion');
      }
    } elsif ($session->param('resendconfirmation')) {
      my (%attr,$phc);
      $sql = "SELECT PendingHashCode FROM Users WHERE UserID = ?;";
      $st = $config->db->prepare($sql);
      $st->execute($UserID);
      $st->bind_columns(\%attr,\$phc);
      $st->fetch();
      if ($phc) {
        my $wm = Mail::Spamgourmet::WebMessages->new(config=>$config);
        my $adminemail = $wm->sendconfirmationmessage($session,$thisscript,$session->PendingEmail,$phc);
        $msg = $session->getDialog('confirmationsent', 'adminemail', $adminemail);
      }
    }
    if (defined($session->param('defaultnumber'))) {
      my $dn = $session->param('defaultnumber') * 1;
      $dn = 1 if $dn < 1;
      $dn = 20 if $dn > 20;
      $sql = "UPDATE Users SET DefaultNumber = ? WHERE UserID = ?;";
      $st = $config->db->prepare($sql);
      $st->execute($dn,$UserID);
      $session->{'DefaultNumber'} = $dn;
    }

    if (defined($session->param('prefix'))) {
      my $e = $session->param('prefix');
      $sql = "UPDATE Users SET Prefix = ? WHERE UserID = ?;";
      $st = $config->db->prepare($sql);
      $st->execute($e,$UserID);
      $e = '_NULL' if !$e;
      $session->Prefix($e);
      $msg .= $session->getDialog('prefixupdated');
    }
    if ($session->param('deletesender')) {
      $sql = "DELETE FROM Permitted WHERE PermittedID = ? AND UserID = ?;";
      $st = $config->db->prepare($sql);
      $st->execute($session->param('deletesender'),$UserID);
      $msg .= $session->getDialog('trustedsenderdeleted');
    }
    if ($session->param('newsender')) {
      $sql = "INSERT INTO Permitted (UserID,Sender) VALUES (?,?);";
      $st = $config->db->prepare($sql);
      my $sender = $session->param('newsender');
      $sender =~ s/^@//;
      $st->execute($UserID,$sender);
      $msg .= $session->getDialog('trustedsenderadded');
    }

    if ($session->param('newwatchword')) {
      $sql = "INSERT INTO Watchwords (UserID,Watchword) VALUES (?,?)";
      $st = $config->db->prepare($sql);
      $st->execute($UserID,$session->param('newwatchword'));
      $msg .= $session->getDialog('watchwordadded');
    }

    if ($session->param('deletewatchword')) {
      $sql = "DELETE FROM Watchwords WHERE WatchwordID = ? AND UserID = ?";
      $st = $config->db->prepare($sql);
      $st->execute($session->param('deletewatchword'),$UserID);
      $msg .= $session->getDialog('watchworddeleted');

    }

    if ($session->param('addFeature')) {
      $session->addFeature($session->param('addFeature'));
### need special logic for tagline for trusted/excl, because it's currently dependent on the main hide feature
      if ($session->param('addFeature') == $config->getFeature('DISABLETAGLINETRUSTEDEXCLUSIVE')) {
        $session->addFeature($config->getFeature('DISABLETAGLINE'));
      }
      $sql = "UPDATE Users SET Features = ? WHERE UserID = ?;";
      $st = $config->db->prepare($sql);
      $st->execute($session->getFeatures(),$UserID);
    }

# commenting this out - don't think it's used
#    if ($session->param('removeFeature')) {
#      $session->removeFeature($session->param('removeFeature'));
#      $sql = "UPDATE Users SET Features = ? WHERE UserID = ?;";
#      $st = $config->db->prepare($sql);
#      $st->execute($session->getFeatures(),$UserID);
#    }

    if ($session->param('clearFeature')) {
      $session->clearFeature($session->param('clearFeature'));
### need special logic for tagline for trusted/excl, because it's currently dependent on the main hide feature
      if ($session->param('clearFeature') == $config->getFeature('DISABLETAGLINE')) {
        $session->clearFeature($config->getFeature('DISABLETAGLINETRUSTEDEXCLUSIVE'));
      }
      $sql = "UPDATE Users SET Features = ? WHERE UserID = ?;";
      $st = $config->db->prepare($sql);
      $st->execute($session->getFeatures(),$UserID);
    }

    if ($session->{'UserID'} && !$session->{'RealEmail'} ) { # && !$session->param('realemail')) {
      $msg .= $session->getDialog('pendingaddressnotconfirmed');
    }
  }
  return $msg;
}





sub getServerStats {
  my $config = shift;
  my $session = shift;
  my (%attr, $sql,$st,$stats,%stats);

  my $filename = 'stats';
  my $gotfromfile = 0;
  if (-e $filename) {
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
    if (!$config->db || time() - $mtime < $config->localfilecachetimeout()) {
      open (FILE,"<$filename");
      my $line;
      while (defined($line = <FILE>)) {
        $line =~ /(.*)=(.*)/;
        $stats{$1}=$2;
      }
      $gotfromfile = 1; 
      close FILE;       
    }
  }

  if (!$gotfromfile) {
    my $vals = '';

    $sql = "SELECT NumForwarded AS ForwardCount FROM Counter WHERE CountDate = '0000-00-00';";
    $st = $config->db->prepare($sql);
    $st->execute();
    $st->bind_columns(\%attr,\$stats{'forwardcount'});
    $st->fetch();
    $vals .= "forwardcount=$stats{'forwardcount'}\n";

    $sql = "SELECT COUNT(CounterID) AS DayCount FROM Counter";
    $st = $config->db->prepare($sql);
    $st->execute();
    $st->bind_columns(\%attr,\$stats{'daycount'});
    $st->fetch();
    $vals .= "daycount=$stats{'daycount'}\n";

    $sql = "SELECT COUNT(UserID) AS UserCount FROM Users";
    $st = $config->db->prepare($sql);
    $st->execute();
    $st->bind_columns(\%attr,\$stats{'usercount'});
    $st->fetch();
    $vals .= "usercount=$stats{'usercount'}\n";

    $sql = "SELECT NumDeleted FROM Counter WHERE CountDate = '0000-00-00';";
    $st = $config->db->prepare($sql);
    $st->execute();
    $st->bind_columns(\%attr,\$stats{'spamcount'});
    $st->fetch();
    $vals .= "spamcount=$stats{'spamcount'}\n";

    $sql = "SELECT COUNT(EmailID) FROM Emails;";
    $st = $config->db->prepare($sql);
    $st->execute();
    $st->bind_columns(\%attr,\$stats{'addresscount'});
    $st->fetch();
    $vals .= "addresscount=$stats{'addresscount'}\n";

    my ($undef,$undef1,$undef2,$mday,$mon,$year,$undef3,$undef4,$undef5) = localtime(time);
    $mon++;
    $year = int($year);
    $year += 1900 if $year < 1900;
    $sql = "SELECT CounterID, NumDeleted, NumForwarded FROM Counter WHERE CountDate = '$year-$mon-$mday';";
    $st = $config->db->prepare($sql);
    $st->execute();
    $st->bind_columns(\%attr,\$stats{'counterID'},\$stats{'todaycount'},\$stats{'todayforwarded'});
    $st->fetch();

    $vals .= "counterID=$stats{'counterID'}\n";
    $vals .= "todaycount=$stats{'todaycount'}\n";
    $vals .= "todayforwarded=$stats{'todayforwarded'}\n";

    open (FILE, ">$filename");
    syswrite FILE, $vals, 10000;
    close FILE;
  }


  $stats{'forwardcount'} = 0 if !$stats{'forwardcount'};
  $stats{'todayforwarded'} = 0 if !$stats{'todayforwarded'};
  $stats{'daycount'} = 0 if !$stats{'daycount'};
  $stats{'usercount'} = 0 if !$stats{'usercount'};
  $stats{'spamcount'} = 0 if !$stats{'spamcount'};
  $stats{'todaycount'} = 0 if !$stats{'todaycount'};
  $stats{'rawtodaycount'} = $stats{'todaycount'};
  $stats{'todayforwarded'} = $util->commify($stats{'todayforwarded'});
  $stats{'forwardcount'} = $util->commify($stats{'forwardcount'});
  $stats{'daycount'} = $util->commify($stats{'daycount'});
  $stats{'usercount'} = $util->commify($stats{'usercount'});
  $stats{'addresscount'} = $util->commify($stats{'addresscount'});
  $stats{'spamcount'} = $util->commify($stats{'spamcount'});
  $stats{'todaycount'} = $util->commify($stats{'todaycount'});

  $stats = $session->getDialog('stats','daycount',$stats{'daycount'},'usercount',$stats{'usercount'},
                               'addresscount',$stats{'addresscount'},
                               'forwardcount',$stats{'forwardcount'},
                               'todayforwarded',$stats{'todayforwarded'},
                               'spamcount',$stats{'spamcount'},
                               'todaycount',$stats{'todaycount'});

  return ($stats, $stats{'counterID'}, $stats{'rawtodaycount'});

}



sub secureMode() {
  my $secure = 0;
  if (defined($ENV{'SERVER_PORT'}) &&  $ENV{'SERVER_PORT'} == 443) {
    $secure = 1;
  }
#$secure = 1;
  return $secure;
}


sub getWeekchart {
  if (defined($ENV{'HTTP_USER_AGENT'}) && $ENV{'HTTP_USER_AGENT'} =~ /MSIE\s5\...\;\sMac\_PowerPC/ ) {
    return '<img src="stuff/graphdisabled.png" border=0 width=300 height=100 alt="">';
  } elsif (&secureMode()) {
    return '<img src="stuff/graphdisabledforsecuremode.png" border=0 width=300 height=100 alt="graph disabled for secure mode">';
  }

  my $filename = 'weekcharturl';
  my $weekchart;
  my $gotfromfile = 0;
  my $session = shift;
  my $config = $session->{'config'};
  my $timeout = 3600;
  if (-e $filename) {
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
    if (time() - $mtime < $timeout) {
      open (FILE,"<$filename");
      my $line;
      while(defined($line = <FILE>)) {
        $weekchart = $line;
      }
      $gotfromfile = 1;
      close FILE;
    }
  }

  if (!$gotfromfile && $config->db) {
    my $counterID=shift;
    my $todaycount=shift;
    $counterID=0 if !$counterID;
    $todaycount=0 if !$counterID;
    my ($labels,$data,$countnum,$countdate,%attr,$st,$sql);
    $sql = "SELECT CountDate, NumDeleted FROM Counter WHERE CounterID > ($counterID-7) AND CounterID < $counterID;";
    $st = $config->db->prepare($sql);
    $st->execute();
    $st->bind_columns(\%attr,\$countdate,\$countnum);
    $weekchart = $config->getConfigParameter('chartserver') . "?width=300&amp;height=100&amp;type=bars3d&amp;bar_depth=10&amp;shading=3&amp;dclrs=[pink]&amp;x_labels=[";
    while ($st->fetch()) {
      $countdate =~ s/.....//;
      $countdate =~ s/(..)-//;
      my $month = &getMonth($1);
      $countdate = $month.$countdate;
      $labels .= $countdate.',';
      $data .= $countnum.',';
    }
    $weekchart .= $labels . 'today' . ']&amp;data1=[' . $data . $todaycount . ']&amp;trailing';
    my $alt = 'spam stopped this week'; # $session->getDialog('spameatenthisweek');
    $weekchart = "<img src=\"$weekchart\" border=0 width=300 height=100 alt=\"$alt\">";
    open (FILE,">$filename");
    syswrite FILE,$weekchart,10000;
    close FILE;
  }
  $weekchart;
}

sub getMonth {
  my $num = shift;
  $num *= 1;
  my $mon = '';
  $mon = 'Jan' if $num == 1;
  $mon = 'Feb' if $num == 2;
  $mon = 'Mar' if $num == 3;
  $mon = 'Apr' if $num == 4;
  $mon = 'May' if $num == 5;
  $mon = 'Jun' if $num == 6;
  $mon = 'Jul' if $num == 7;
  $mon = 'Aug' if $num == 8;
  $mon = 'Sep' if $num == 9;
  $mon = 'Oct' if $num == 10;
  $mon = 'Nov' if $num == 11;
  $mon = 'Dec' if $num == 12;
  $mon;

}


sub getMOTDnum {
  srand();
  my $r = rand(100);
  my $MOTD = 1;
  $MOTD = 2 if $r > 20 && $r < 40;
  $MOTD = 3 if $r > 39 && $r < 60;
  $MOTD = 4 if $r > 59 && $r < 80;
  $MOTD = 5 if $r > 79;

  $MOTD;
}

sub getSayingNum {
## saying for picture
  srand();
  my $r = rand(100);
  my $saying = 1;
  $saying = 2 if $r < 11;
  $saying = 3 if $r > 10 && $r < 18;
  $saying = 4 if $r > 17 && $r < 28;
  $saying = 5 if $r > 27 && $r < 35;
  $saying = 6 if $r > 34 && $r < 41;
  $saying = 7 if $r > 40 && $r < 56;
  $saying = 8 if $r > 55 && $r < 96;
  $saying = 9 if $r > 95;
  $saying;
}

sub setCookies {
  my @encoding = ('\%','\+','\;','\,','\=','\&','\:\:','\s');
  my %encoding =('\%','%25','\+','%2B','\;','%3B','\,','%2C','\=','%3D','\&',
   '%26','\:\:','%3A%3A','\s','+');   
  my @giveyoucookies = @_;
  my ($giveyoucookie,$value,$cookiechar);
  my $httpd = 1;
  if ($httpd == 2) {
    print "Set-Cookie: ";
    while(($giveyoucookie,$value) = @giveyoucookies ) {
      foreach $cookiechar (@encoding) {
        $giveyoucookie =~ s/$cookiechar/$encoding{$cookiechar}/g;
        $value =~ s/$cookiechar/$encoding{$cookiechar}/g;
      }
      print $giveyoucookie, "=",  $value,  ";expires=never";
      shift(@giveyoucookies); shift(@giveyoucookies);
    }
    print "\n";
  } else {
    while(($giveyoucookie,$value) = @giveyoucookies ) {
      foreach $cookiechar (@encoding) {
        $giveyoucookie =~ s/$cookiechar/$encoding{$cookiechar}/g;
        $value =~ s/$cookiechar/$encoding{$cookiechar}/g;
      }
      print "Set-Cookie: ",$giveyoucookie,"=",$value,";path=/;\n";
      shift(@giveyoucookies); shift(@giveyoucookies);
    }
  }
}



