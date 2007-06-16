-- MySQL dump 8.22
--
-- Host: localhost    Database: jqh1
---------------------------------------------------------
-- Server version	3.23.56

--
-- Table structure for table 'AddressAudit'
--

CREATE TABLE AddressAudit (
  AddressAuditID int(11) NOT NULL auto_increment,
  UserID int(11) NOT NULL default '0',
  Address varchar(255) default NULL,
  ChangeTime int(11) NOT NULL default '0',
  IPAddress varchar(255) default NULL,
  PRIMARY KEY  (AddressAuditID)
) TYPE=MyISAM;

--
-- Table structure for table 'AdminEmail'
--

CREATE TABLE AdminEmail (
  AdminEmailID int(11) NOT NULL auto_increment,
  AdminUser varchar(255) default NULL,
  AdminEmailAddress varchar(255) default NULL,
  PRIMARY KEY  (AdminEmailID)
) TYPE=MyISAM;

--
-- Table structure for table 'Comments'
--

CREATE TABLE Comments (
  CommentID bigint(20) NOT NULL auto_increment,
  Commenter varchar(20) default NULL,
  Comment text,
  Response text,
  TimeAdded bigint(20) NOT NULL default '0',
  PRIMARY KEY  (CommentID)
) TYPE=MyISAM;

--
-- Table structure for table 'Counter'
--

CREATE TABLE Counter (
  CounterID int(20) NOT NULL auto_increment,
  CountDate date NOT NULL default '0000-00-00',
  NumForwarded bigint(20) NOT NULL default '0',
  NewUsers bigint(20) NOT NULL default '0',
  WeekDay tinyint(4) NOT NULL default '0',
  NumDeleted bigint(20) NOT NULL default '0',
  PRIMARY KEY  (CounterID),
  KEY CountDate (CountDate)
) TYPE=MyISAM;

--
-- Table structure for table 'Dialogs'
--

CREATE TABLE Dialogs (
  DialogID bigint(20) NOT NULL auto_increment,
  DialogNumber bigint(20) NOT NULL default '0',
  DialogName varchar(200) NOT NULL default '',
  LanguageCode char(2) NOT NULL default '',
  DialogText text,
  DialogType smallint(6) NOT NULL default '0',
  Updated int(11) default NULL,
  PRIMARY KEY  (DialogID),
  UNIQUE KEY DialogID_2 (DialogID),
  KEY DialogID (DialogID,DialogNumber,DialogName,LanguageCode),
  KEY Type (DialogType)
) TYPE=MyISAM;

--
-- Table structure for table 'EatenMessageLog'
--

CREATE TABLE EatenMessageLog (
  EatenMessageLogID bigint(20) NOT NULL auto_increment,
  UserID bigint(20) NOT NULL default '0',
  EatenMessageLog text,
  PRIMARY KEY  (EatenMessageLogID),
  KEY UserID (UserID)
) TYPE=MyISAM;

--
-- Table structure for table 'Emails'
--

CREATE TABLE Emails (
  EmailID bigint(20) NOT NULL auto_increment,
  UserID bigint(20) NOT NULL default '0',
  Prefix varchar(20) default NULL,
  Word varchar(20) NOT NULL default '',
  InitialCount tinyint(4) NOT NULL default '0',
  Count tinyint(4) NOT NULL default '0',
  TimeAdded bigint(20) default NULL,
  Sender varchar(254) default NULL,
  Address text,
  DeliveryAddress varchar(255) default '',
  Hidden tinyint(4) NOT NULL default '0',
  Note varchar(254) default NULL,
  PrivateHash varchar(50) NOT NULL default '',
  NumForwarded bigint(20) NOT NULL default '0',
  NumDeleted bigint(20) NOT NULL default '0',
  ExpireTime bigint(20) unsigned default NULL,
  PRIMARY KEY  (EmailID),
  KEY UserID (UserID,Word,Count),
  KEY Word (Word)
) TYPE=MyISAM;

--
-- Table structure for table 'Forbidden'
--

CREATE TABLE Forbidden (
  ForbiddenID bigint(20) NOT NULL auto_increment,
  UserID bigint(20) NOT NULL default '0',
  Sender varchar(50) NOT NULL default '',
  PRIMARY KEY  (ForbiddenID),
  KEY UserID (UserID,Sender)
) TYPE=MyISAM;

--
-- Table structure for table 'LocalDomains'
--

CREATE TABLE LocalDomains (
  LocalDomainID int(11) NOT NULL auto_increment,
  LocalDomain varchar(255) default NULL,
  PRIMARY KEY  (LocalDomainID)
) TYPE=MyISAM;

--
-- Table structure for table 'Permitted'
--

CREATE TABLE Permitted (
  PermittedID bigint(20) NOT NULL auto_increment,
  UserID bigint(20) NOT NULL default '0',
  Sender varchar(50) NOT NULL default '',
  PRIMARY KEY  (PermittedID),
  KEY UserID (UserID,Sender)
) TYPE=MyISAM;

--
-- Table structure for table 'Users'
--

CREATE TABLE Users (
  UserID bigint(20) NOT NULL auto_increment,
  UserName varchar(20) NOT NULL default '',
  RealEmail varchar(255) NOT NULL default '',
  Password varchar(50) NOT NULL default '',
  Prefix varchar(20) NOT NULL default '',
  TimeAdded bigint(20) default NULL,
  NumDeleted bigint(20) NOT NULL default '0',
  NumForwarded bigint(20) NOT NULL default '0',
  IPAddress varchar(20) NOT NULL default '',
  SpamEmail varchar(255) default NULL,
  PendingEmail varchar(254) default NULL,
  PendingHashCode varchar(40) default '',
  LanguageCode char(2) NOT NULL default '',
  Features bigint(20) NOT NULL default '1',
  EatenMessageLog varchar(255) default NULL,
  SessionToken varchar(16) NOT NULL default '',
  LastCommand bigint(20) default NULL,
  RecThrottleTime bigint(20) unsigned default NULL,
  RecThrottleCount smallint(6) default NULL,
  SendThrottleTime bigint(20) unsigned default NULL,
  SendThrottleCount smallint(6) default NULL,
  DefaultNumber tinyint(4) default '3',
  PRIMARY KEY  (UserID),
  KEY UserName (UserName,Password,Prefix),
  KEY SessionToken (SessionToken)
) TYPE=MyISAM;

--
-- Table structure for table 'Versions'
--

CREATE TABLE Versions (
  VersionID int(10) NOT NULL auto_increment,
  VersionName varchar(20) default NULL,
  VersionNumber bigint(20) NOT NULL default '0',
  PRIMARY KEY  (VersionID),
  KEY VersionName (VersionName)
) TYPE=MyISAM;

--
-- Table structure for table 'Watchwords'
--

CREATE TABLE Watchwords (
  WatchwordID bigint(20) NOT NULL auto_increment,
  UserID bigint(20) NOT NULL default '0',
  Watchword varchar(20) NOT NULL default '',
  PRIMARY KEY  (WatchwordID),
  KEY UserID (UserID,Watchword)
) TYPE=MyISAM;

