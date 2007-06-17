#!/usr/bin/perl -w
use strict;
use vars qw{$thisscript $chartserver};
use lib "../modules";
use DBD::mysql;
use CGI qw/:standard/;
use Mail::Spamgourmet::Config;
use Mail::Spamgourmet::Page;
use Mail::Spamgourmet::Session;
use Mail::Spamgourmet::Dialogs;

$chartserver = 'http://graphs.spamgourmet.net';
my $config= Mail::Spamgourmet::Config->new(configfile=>'/home/jqh1/spamgourmet.config');
my $session = Mail::Spamgourmet::Session->new(config=>$config,query=>new CGI);
Mail::Spamgourmet::Page->setGlobalConfig($config);

$| = 1;

$thisscript = 'graphs.cgi';


my ($weekchart,$userstats,$weekdayspam,$weekdaychart,$userschart,$spamchart) = ('','','','','','');


my $url2 = "$chartserver?width=300&height=200&type=bars&x_labels=[sun,mon,tue,wed,thu,fri,sat]&dclrs=[pink]";


my $data1 = "&data1=[";
my $data2 = "&data2=[";
my $data3 = "&data3=[";

my (%attr,$CountDate,$NumDeleted,$NumForwarded,$NewUsers,$CounterID);
my ($activeAvgForwarded, $activeAvgDeleted, $frequentAvgForwarded, $frequentAvgDeleted, $longtimeAvgForwarded, $longtimeAvgDeleted);
my $i = 0;
my ($NumUsers,$totalUsers,$activeUsers) = (0,0,0);
my ($sql,$st,$st2);
my ($todayID,$todayWeekday,$offset);
my ($weekday,$topday,$bottomday,$topnum,$bottomnum,$lastSaturday,$startDate,$eatenToday) = (0,0,0,0,0,0,0,0);

my @weekdays = ($session->getDialog('weekday1'),
                $session->getDialog('weekday2'),
                $session->getDialog('weekday3'),
                $session->getDialog('weekday4'),
                $session->getDialog('weekday5'),
                $session->getDialog('weekday6'),
                $session->getDialog('weekday7'));

$sql = "SELECT MAX(CounterID) FROM Counter;";
$st = $config->db->prepare($sql);
$st->execute();
$st->bind_columns(\%attr,\$todayID);
$st->fetch();

$sql = "SELECT COUNT(UserID) FROM Users;";
$st = $config->db->prepare($sql);
$st->execute();
$st->bind_columns(\%attr,\$totalUsers);
$st->fetch();

$sql = "SELECT COUNT(UserID) FROM Users where NumDeleted > 5 OR NumForwarded > 20;";
$st = $config->db->prepare($sql);
$st->execute();
$st->bind_columns(\%attr,\$activeUsers);
$st->fetch();


##### spam by weekday ######

$sql = "SELECT WeekDay, NumDeleted FROM Counter WHERE CounterID = ?";
$st = $config->db->prepare($sql);
$st->execute($todayID);
$st->bind_columns(\%attr,\$todayWeekday,\$eatenToday);
$st->fetch();

#$offset = $todayWeekday - 1;
#$offset = 7 if $offset == 0;

$sql = "SELECT CountDate FROM Counter WHERE CounterID = ?";
$st = $config->db->prepare($sql);
$st->execute($todayID - $todayWeekday - 1);
$st->bind_columns(\%attr,\$lastSaturday);
$st->fetch();

$st = $config->db->prepare($sql);
$st->execute($todayID - $todayWeekday - 182);
$st->bind_columns(\%attr,\$startDate);
$st->fetch();


$url2 .= "&title=avg%20spam%20$startDate%20->%20$lastSaturday";


$sql = "SELECT Weekday, avg(NumDeleted) FROM Counter 
 WHERE CounterID > ? AND CounterID < ? 
 GROUP BY WeekDay ORDER BY WeekDay;";
$data1 = "&data1=[";
$i=0;
$st = $config->db->prepare($sql);
$st->execute(($todayID - 182 - $todayWeekday -1),($todayID - $todayWeekday));
$st->bind_columns(\%attr,\$weekday,\$NumDeleted);
while ($st->fetch()) {
  if ($i) {
    $data1 .= ",";
  } else {
    $bottomnum = $NumDeleted;
  }
  $i++;
  $data1 .= "$NumDeleted";
  if ($NumDeleted > $topnum) {
    $topday = $weekday;
    $topnum = $NumDeleted;
  }
  if ($NumDeleted < $bottomnum) {
    $bottomday = $weekday;
    $bottomnum = $NumDeleted;
  }
}


$data1 .= "]&trailing";
$url2 .= $data1;
##### end spam by weekday #####


$weekchart = &getWeekchart($config, $todayID, $eatenToday);

$weekdayspam = $session->getDialog('weekdayspam','topday',$weekdays[$topday],'bottomday',$weekdays[$bottomday]);

#### topday spam ####
my $dayoftheweek = $topday;
if (defined($session->param('dayoftheweek'))) {
  $dayoftheweek = $session->param('dayoftheweek');
}
my $urlspam = $chartserver."?title=$weekdays[$dayoftheweek]%20spam&width=600&height=200&type=lines"; ##### MODIFIED
my $urlusers = $chartserver."?title=$weekdays[$dayoftheweek]%20cumulative%20total%20users&width=600&height=200&type=lines"; ##### MODIFIED

my $xlabels = '&x_labels=[';
$sql = "SELECT CounterID, CountDate, NumDeleted FROM Counter
 WHERE CounterID > ? AND CounterID < ? AND WeekDay = ? ORDER BY CountDate;";
my $dataspam = "&data1=["; ##### MODIFIED
my $datausers = "&data1=["; ##### MODIFIED
$i=0;
$st = $config->db->prepare($sql);
$st->execute(($todayID - 180),$todayID,$dayoftheweek);
$st->bind_columns(\%attr,\$CounterID,\$CountDate,\$NumDeleted);
while ($st->fetch()) {

  $sql = "SELECT SUM(NewUsers) FROM Counter WHERE CounterID <= ?;";
  $st2 = $config->db->prepare($sql);
  $st2->execute($CounterID);
  $st2->bind_columns(\%attr,\$NewUsers);
  $st2->fetch();
  
  if ($i) {
    $dataspam .= ','; ##### MODIFIED
    $datausers .= ','; ##### MODIFIED
    $xlabels .= ',';
  }
  $i++;
  $CountDate =~ s/^.....//;
  $CountDate =~ s/^0//;
  $CountDate =~ s/\-0/\-/;
  $dataspam .= "$NumDeleted";
  $datausers .= "$NewUsers";
  $xlabels .= "$CountDate";
}
$dataspam .= "]"; ##### MODIFIED
$datausers .= "]"; ##### MODIFIED
$xlabels .= "]";
$urlspam .= $xlabels . $dataspam . '&trailing';  ##### MODIFIED
$urlusers .= $xlabels . $datausers . '&trailing';  ##### MODIFIED
#$url4 .= "&caption1=(1,arial.ttf,9,0,30,30,Hello)";

#$st2->finish();
#### end topday spam  #####



# stats...
#### averages for active users
$sql = "SELECT AVG(NumForwarded), AVG(NumDeleted) FROM Users WHERE NumForwarded > ? AND NumDeleted > ?";
$st = $config->db->prepare($sql);
$st->execute(0,0);
$st->bind_columns(\%attr,\$activeAvgForwarded,\$activeAvgDeleted);
$st->fetch();
$activeAvgForwarded = &commify(int($activeAvgForwarded));
$activeAvgDeleted = &commify(int($activeAvgDeleted));

#### averages for heavy users
$st->execute(99,0);
$st->bind_columns(\%attr,\$frequentAvgForwarded,\$frequentAvgDeleted);
$st->fetch();
$frequentAvgForwarded = &commify(int($frequentAvgForwarded));
$frequentAvgDeleted = &commify(int($frequentAvgDeleted));


#### averages for longtime users
my $longtimeAgo = time() - 31536000;
$sql = "SELECT AVG(NumForwarded), AVG(NumDeleted) FROM Users WHERE NumForwarded > ? AND NumDeleted > ? AND TimeAdded < ?";
$st = $config->db->prepare($sql);
$st->execute(99,0,$longtimeAgo);
$st->bind_columns(\%attr,\$longtimeAvgForwarded,\$longtimeAvgDeleted);
$st->fetch();
$longtimeAvgForwarded = &commify(int($longtimeAvgForwarded));
$longtimeAvgDeleted = &commify(int($longtimeAvgDeleted));




$userstats = $session->getDialog('useraverages','activeavgforwarded',$activeAvgForwarded,
                                 'activeavgdeleted',$activeAvgDeleted,'frequentavgforwarded',
                                 $frequentAvgForwarded,'frequentavgdeleted',$frequentAvgDeleted,
                                 'longtimeavgforwarded',$longtimeAvgForwarded,'longtimeavgdeleted',
                                 $longtimeAvgDeleted);


###### user languages ######
my $langtable = '';
my %langs;
my ($cnt,$lc);
my $total = 0;
$sql = "select Count(UserID), LanguageCode from Users group by LanguageCode";
$st = $config->db->prepare($sql);
$st->execute();
$st->bind_columns(\%attr,\$cnt,\$lc);
while ($st->fetch()) {
  if (!$lc) {
    $langs{'EN'} = 0 if !$langs{'EN'};
    $langs{'EN'} += $cnt;
  } else {
    $langs{$lc} = 0 if !$langs{$lc};
    $langs{$lc} += $cnt;
  }
  $total += $langs{$lc};
}

$langtable = Mail::Spamgourmet::Page->new(template=>'userlanguagetop.html',languageCode=>$session->getLanguageCode());
$langtable->setTags('usersbylanguage',$session->getDialog('usersbylanguage'),'language',$session->getDialog('language'),'count',$session->getDialog('count'));
$langtable = $langtable->getContent();
my $row;
foreach $lc (sort keys(%langs)) {
  $row = Mail::Spamgourmet::Page->new(template=>'userlanguagerow.html', languageCode=>$session->getLanguageCode());
  $row->setTags('lc',$lc, 'count', &commify($langs{$lc}));
  $langtable .= $row->getContent();
}
  $row = Mail::Spamgourmet::Page->new(template=>'userlanguagerow.html', languageCode=>$session->getLanguageCode());
  $row->setTags('lc','', 'count', &commify($total));
  $langtable .= $row->getContent();
$langtable .= Mail::Spamgourmet::Page->new(template=>"userlanguagebottom.html")->getContent();

my $page = Mail::Spamgourmet::Page->new(template=>'graphs2.html',languageCode=>$session->getLanguageCode());
$page->printpage('spameatenthisweek',$session->getDialog('spameatenthisweek'),'weekchart',$weekchart,'userstats',$userstats,
 'graphsshowsixmonthdata', $session->getDialog('graphsshowsixmonthdata'),
 'weekdayspam',$weekdayspam,'weekdaychart',$url2,'action',$thisscript,'langtable',$langtable,
 'spamchart',$urlspam,'userschart',$urlusers,'weekday1',$weekdays[0],'weekday2',$weekdays[1],'weekday3',$weekdays[2],
 'weekday4',$weekdays[3],'weekday5',$weekdays[4],'weekday6',$weekdays[5],'weekday7',$weekdays[6],
 'closewindow', $session->getDialog('closewindow')
 ); ##### MODIFIED

$st->finish();
$st2->finish();
$config->db->disconnect();
$config->die();
exit;





sub getWeekchart {
#  if ($ENV{'HTTP_USER_AGENT'} =~ /MSIE\s5\...\;\sMac\_PowerPC/ ) {
#    return '<img src="stuff/graphdisabled.png" border=0 width=300 height=100 alt="">';
#  } elsif ($ENV{'HTTP_HOST'} =~ /spruce/) {
#    return '<img src="stuff/graphdisabledforsecuremode.png" border=0 width=300 height=100 alt="graph disabled for secure mode">';
#  }
  my $config=shift;
  my $counterID=shift;
  my $todaycount=shift;
  $counterID=0 if !$counterID;
  $todaycount=0 if !$counterID;
  my ($weekchart,$labels,$data,$countnum,$countdate,%attr,$st,$sql);
  $sql = "SELECT CountDate, NumDeleted FROM Counter WHERE CounterID > ($counterID-7) AND CounterID < $counterID;";
  $st = $config->db->prepare($sql);
  $st->execute();
  $st->bind_columns(\%attr,\$countdate,\$countnum);
  $weekchart = "$chartserver?width=300&height=100&type=bars3d&bar_depth=10&shading=3&dclrs=[pink]&x_labels=[";
  while ($st->fetch()) {
    $countdate =~ s/.....//;
    $countdate =~ s/(..)-//;
    my $month = &getMonth($1);
    $countdate = $month.$countdate;
    $labels .= $countdate.',';
    $data .= $countnum.',';
  }
  $weekchart .= $labels . 'today' . ']&data1=[' . $data . $todaycount . ']&trailing';
#  $weekchart = "<img src=\"$weekchart\" border=0 width=300 height=100 alt=\"spam this week\">";
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





sub commify {
  my $instr = reverse $_[0];
  $instr = 0 if !$instr;
  $instr =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
  return scalar reverse $instr;
}

