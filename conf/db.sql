-- MySQL dump 10.10
--
-- Host: localhost    Database: jqh1
-- ------------------------------------------------------
-- Server version	5.0.27-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `AddressAudit`
--

DROP TABLE IF EXISTS `AddressAudit`;
CREATE TABLE `AddressAudit` (
  `AddressAuditID` int(11) NOT NULL auto_increment,
  `UserID` int(11) NOT NULL default '0',
  `Address` varchar(255) default NULL,
  `ChangeTime` int(11) NOT NULL default '0',
  `IPAddress` varchar(255) default NULL,
  PRIMARY KEY  (`AddressAuditID`)
) ENGINE=MyISAM AUTO_INCREMENT=388133 DEFAULT CHARSET=latin1;

--
-- Table structure for table `AdminEmail`
--

DROP TABLE IF EXISTS `AdminEmail`;
CREATE TABLE `AdminEmail` (
  `AdminEmailID` int(11) NOT NULL auto_increment,
  `AdminUser` varchar(255) default NULL,
  `AdminEmailAddress` varchar(255) default NULL,
  PRIMARY KEY  (`AdminEmailID`),
  KEY `AdminUser` (`AdminUser`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;

--
-- Table structure for table `Comments`
--

DROP TABLE IF EXISTS `Comments`;
CREATE TABLE `Comments` (
  `CommentID` bigint(20) NOT NULL auto_increment,
  `Commenter` varchar(20) default NULL,
  `Comment` text,
  `Response` text,
  `TimeAdded` bigint(20) NOT NULL default '0',
  PRIMARY KEY  (`CommentID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `Counter`
--

DROP TABLE IF EXISTS `Counter`;
CREATE TABLE `Counter` (
  `CounterID` int(20) NOT NULL auto_increment,
  `CountDate` date NOT NULL default '0000-00-00',
  `NumForwarded` bigint(20) NOT NULL default '0',
  `NewUsers` bigint(20) NOT NULL default '0',
  `WeekDay` tinyint(4) NOT NULL default '0',
  `NumDeleted` bigint(20) NOT NULL default '0',
  PRIMARY KEY  (`CounterID`),
  KEY `CountDate` (`CountDate`)
) ENGINE=MyISAM AUTO_INCREMENT=3128 DEFAULT CHARSET=latin1;

--
-- Table structure for table `Dialogs`
--

DROP TABLE IF EXISTS `Dialogs`;
CREATE TABLE `Dialogs` (
  `DialogID` bigint(20) NOT NULL auto_increment,
  `DialogNumber` bigint(20) NOT NULL default '0',
  `DialogName` varchar(200) NOT NULL default '',
  `LanguageCode` char(2) NOT NULL default '',
  `DialogText` text,
  `DialogType` smallint(6) NOT NULL default '0',
  `Updated` int(11) default NULL,
  PRIMARY KEY  (`DialogID`),
  UNIQUE KEY `DialogID_2` (`DialogID`),
  KEY `DialogID` (`DialogID`,`DialogNumber`,`DialogName`,`LanguageCode`),
  KEY `Type` (`DialogType`)
) ENGINE=MyISAM AUTO_INCREMENT=2616 DEFAULT CHARSET=latin1;

--
-- Table structure for table `EatenMessageLog`
--

DROP TABLE IF EXISTS `EatenMessageLog`;
CREATE TABLE `EatenMessageLog` (
  `EatenMessageLogID` bigint(20) NOT NULL auto_increment,
  `UserID` bigint(20) NOT NULL default '0',
  `EatenMessageLog` text,
  PRIMARY KEY  (`EatenMessageLogID`),
  KEY `UserID` (`UserID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `Emails`
--

DROP TABLE IF EXISTS `Emails`;
CREATE TABLE `Emails` (
  `EmailID` bigint(20) NOT NULL auto_increment,
  `UserID` bigint(20) NOT NULL default '0',
  `Prefix` varchar(20) default NULL,
  `Word` varchar(20) NOT NULL default '',
  `InitialCount` tinyint(4) NOT NULL default '0',
  `Count` tinyint(4) NOT NULL default '0',
  `TimeAdded` bigint(20) default NULL,
  `Sender` varchar(254) default NULL,
  `Address` text,
  `DeliveryAddress` varchar(255) default '',
  `Hidden` tinyint(4) NOT NULL default '0',
  `Note` varchar(254) default NULL,
  `PrivateHash` varchar(50) NOT NULL default '',
  `NumForwarded` bigint(20) NOT NULL default '0',
  `NumDeleted` bigint(20) NOT NULL default '0',
  `ExpireTime` bigint(20) unsigned default NULL,
  PRIMARY KEY  (`EmailID`),
  KEY `UserID` (`UserID`,`Word`,`Count`),
  KEY `Word` (`Word`)
) ENGINE=MyISAM AUTO_INCREMENT=3204132 DEFAULT CHARSET=latin1;

--
-- Table structure for table `Forbidden`
--

DROP TABLE IF EXISTS `Forbidden`;
CREATE TABLE `Forbidden` (
  `ForbiddenID` bigint(20) NOT NULL auto_increment,
  `UserID` bigint(20) NOT NULL default '0',
  `Sender` varchar(50) NOT NULL default '',
  PRIMARY KEY  (`ForbiddenID`),
  KEY `UserID` (`UserID`,`Sender`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `LocalDomains`
--

DROP TABLE IF EXISTS `LocalDomains`;
CREATE TABLE `LocalDomains` (
  `LocalDomainID` int(11) NOT NULL auto_increment,
  `LocalDomain` varchar(255) default NULL,
  PRIMARY KEY  (`LocalDomainID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `Permitted`
--

DROP TABLE IF EXISTS `Permitted`;
CREATE TABLE `Permitted` (
  `PermittedID` bigint(20) NOT NULL auto_increment,
  `UserID` bigint(20) NOT NULL default '0',
  `Sender` varchar(50) NOT NULL default '',
  PRIMARY KEY  (`PermittedID`),
  KEY `UserID` (`UserID`,`Sender`)
) ENGINE=MyISAM AUTO_INCREMENT=78319 DEFAULT CHARSET=latin1;

--
-- Table structure for table `Users`
--

DROP TABLE IF EXISTS `Users`;
CREATE TABLE `Users` (
  `UserID` bigint(20) NOT NULL auto_increment,
  `UserName` varchar(20) NOT NULL default '',
  `RealEmail` varchar(255) NOT NULL default '',
  `Password` varchar(50) NOT NULL default '',
  `Prefix` varchar(20) NOT NULL default '',
  `TimeAdded` bigint(20) default NULL,
  `NumDeleted` bigint(20) NOT NULL default '0',
  `NumForwarded` bigint(20) NOT NULL default '0',
  `IPAddress` varchar(20) NOT NULL default '',
  `SpamEmail` varchar(255) default NULL,
  `PendingEmail` varchar(254) default NULL,
  `PendingHashCode` varchar(40) default '',
  `LanguageCode` char(2) NOT NULL default '',
  `Features` bigint(20) NOT NULL default '1',
  `EatenMessageLog` varchar(255) default NULL,
  `SessionToken` varchar(16) NOT NULL default '',
  `LastCommand` bigint(20) default NULL,
  `RecThrottleTime` bigint(20) unsigned default NULL,
  `RecThrottleCount` smallint(6) default NULL,
  `SendThrottleTime` bigint(20) unsigned default NULL,
  `SendThrottleCount` smallint(6) default NULL,
  `DefaultNumber` tinyint(4) default '3',
  PRIMARY KEY  (`UserID`),
  KEY `UserName` (`UserName`,`Password`,`Prefix`),
  KEY `SessionToken` (`SessionToken`),
  KEY `PendingHashCode` (`PendingHashCode`)
) ENGINE=MyISAM AUTO_INCREMENT=161994 DEFAULT CHARSET=latin1;

--
-- Table structure for table `Versions`
--

DROP TABLE IF EXISTS `Versions`;
CREATE TABLE `Versions` (
  `VersionID` int(10) NOT NULL auto_increment,
  `VersionName` varchar(20) default NULL,
  `VersionNumber` bigint(20) NOT NULL default '0',
  PRIMARY KEY  (`VersionID`),
  KEY `VersionName` (`VersionName`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

--
-- Table structure for table `Watchwords`
--

DROP TABLE IF EXISTS `Watchwords`;
CREATE TABLE `Watchwords` (
  `WatchwordID` bigint(20) NOT NULL auto_increment,
  `UserID` bigint(20) NOT NULL default '0',
  `Watchword` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`WatchwordID`),
  KEY `UserID` (`UserID`,`Watchword`)
) ENGINE=MyISAM AUTO_INCREMENT=18101 DEFAULT CHARSET=latin1;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2007-10-08 21:41:03
