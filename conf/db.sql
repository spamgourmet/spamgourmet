-- MySQL dump 10.14  Distrib 5.5.59-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: spamgourmet
-- ------------------------------------------------------
-- Server version	5.5.59-MariaDB-1~wheezy

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
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `AddressAudit` (
  `AddressAuditID` int(11) NOT NULL AUTO_INCREMENT,
  `UserID` int(11) NOT NULL DEFAULT '0',
  `Address` varchar(255) DEFAULT NULL,
  `ChangeTime` int(11) NOT NULL DEFAULT '0',
  `IPAddress` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`AddressAuditID`)
) ENGINE=MyISAM AUTO_INCREMENT=513704 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `AdminEmail`
--

DROP TABLE IF EXISTS `AdminEmail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `AdminEmail` (
  `AdminEmailID` int(11) NOT NULL AUTO_INCREMENT,
  `AdminUser` varchar(255) DEFAULT NULL,
  `AdminEmailAddress` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`AdminEmailID`),
  KEY `AdminUser` (`AdminUser`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Counter`
--

DROP TABLE IF EXISTS `Counter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Counter` (
  `CounterID` int(20) NOT NULL AUTO_INCREMENT,
  `CountDate` date NOT NULL DEFAULT '0000-00-00',
  `NumForwarded` bigint(20) NOT NULL DEFAULT '0',
  `NewUsers` bigint(20) NOT NULL DEFAULT '0',
  `WeekDay` tinyint(4) NOT NULL DEFAULT '0',
  `NumDeleted` bigint(20) NOT NULL DEFAULT '0',
  PRIMARY KEY (`CounterID`),
  KEY `CountDate` (`CountDate`)
) ENGINE=MyISAM AUTO_INCREMENT=6938 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Dialogs`
--

DROP TABLE IF EXISTS `Dialogs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Dialogs` (
  `DialogID` bigint(20) NOT NULL AUTO_INCREMENT,
  `DialogNumber` bigint(20) NOT NULL DEFAULT '0',
  `DialogName` varchar(200) NOT NULL DEFAULT '',
  `LanguageCode` char(2) NOT NULL DEFAULT '',
  `DialogText` text,
  `DialogType` smallint(6) NOT NULL DEFAULT '0',
  `Updated` int(11) DEFAULT NULL,
  PRIMARY KEY (`DialogID`),
  UNIQUE KEY `DialogID_2` (`DialogID`),
  KEY `DialogID` (`DialogID`,`DialogNumber`,`DialogName`,`LanguageCode`),
  KEY `Type` (`DialogType`)
) ENGINE=MyISAM AUTO_INCREMENT=3150 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Emails`
--

DROP TABLE IF EXISTS `Emails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Emails` (
  `EmailID` bigint(20) NOT NULL AUTO_INCREMENT,
  `UserID` bigint(20) NOT NULL DEFAULT '0',
  `Prefix` varchar(20) DEFAULT NULL,
  `Word` varchar(20) NOT NULL DEFAULT '',
  `InitialCount` tinyint(4) NOT NULL DEFAULT '0',
  `Count` tinyint(4) NOT NULL DEFAULT '0',
  `TimeAdded` bigint(20) DEFAULT NULL,
  `Sender` varchar(254) DEFAULT NULL,
  `Address` text,
  `DeliveryAddress` varchar(255) DEFAULT '',
  `Hidden` tinyint(4) NOT NULL DEFAULT '0',
  `Note` varchar(254) DEFAULT NULL,
  `PrivateHash` varchar(50) NOT NULL DEFAULT '',
  `NumForwarded` bigint(20) NOT NULL DEFAULT '0',
  `NumDeleted` bigint(20) NOT NULL DEFAULT '0',
  `ExpireTime` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`EmailID`),
  KEY `UserID` (`UserID`,`Word`,`Count`),
  KEY `Word` (`Word`)
) ENGINE=MyISAM AUTO_INCREMENT=8443939 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Permitted`
--

DROP TABLE IF EXISTS `Permitted`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Permitted` (
  `PermittedID` bigint(20) NOT NULL AUTO_INCREMENT,
  `UserID` bigint(20) NOT NULL DEFAULT '0',
  `Sender` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`PermittedID`),
  KEY `UserID` (`UserID`,`Sender`)
) ENGINE=MyISAM AUTO_INCREMENT=252017 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Users`
--

DROP TABLE IF EXISTS `Users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Users` (
  `UserID` bigint(20) NOT NULL AUTO_INCREMENT,
  `UserName` varchar(20) NOT NULL DEFAULT '',
  `RealEmail` varchar(255) NOT NULL DEFAULT '',
  `Password` varchar(100) DEFAULT NULL,
  `Prefix` varchar(20) NOT NULL DEFAULT '',
  `TimeAdded` bigint(20) DEFAULT NULL,
  `NumDeleted` bigint(20) NOT NULL DEFAULT '0',
  `NumForwarded` bigint(20) NOT NULL DEFAULT '0',
  `IPAddress` varchar(20) NOT NULL DEFAULT '',
  `SpamEmail` varchar(255) DEFAULT NULL,
  `PendingEmail` varchar(254) DEFAULT NULL,
  `PendingHashCode` varchar(40) DEFAULT '',
  `LanguageCode` char(2) NOT NULL DEFAULT '',
  `Features` bigint(20) NOT NULL DEFAULT '1',
  `EatenMessageLog` varchar(255) DEFAULT NULL,
  `SessionToken` varchar(16) NOT NULL DEFAULT '',
  `LastCommand` bigint(20) DEFAULT NULL,
  `RecThrottleTime` bigint(20) unsigned DEFAULT NULL,
  `RecThrottleCount` smallint(6) DEFAULT NULL,
  `SendThrottleTime` bigint(20) unsigned DEFAULT NULL,
  `SendThrottleCount` smallint(6) DEFAULT NULL,
  `DefaultNumber` tinyint(4) DEFAULT '3',
  `APIKey` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`UserID`),
  KEY `UserName` (`UserName`,`Password`,`Prefix`),
  KEY `SessionToken` (`SessionToken`),
  KEY `PendingHashCode` (`PendingHashCode`)
) ENGINE=MyISAM AUTO_INCREMENT=307962 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Versions`
--

DROP TABLE IF EXISTS `Versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Versions` (
  `VersionID` int(10) NOT NULL AUTO_INCREMENT,
  `VersionName` varchar(20) DEFAULT NULL,
  `VersionNumber` bigint(20) NOT NULL DEFAULT '0',
  PRIMARY KEY (`VersionID`),
  KEY `VersionName` (`VersionName`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Watchwords`
--

DROP TABLE IF EXISTS `Watchwords`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Watchwords` (
  `WatchwordID` bigint(20) NOT NULL AUTO_INCREMENT,
  `UserID` bigint(20) NOT NULL DEFAULT '0',
  `Watchword` varchar(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`WatchwordID`),
  KEY `UserID` (`UserID`,`Watchword`)
) ENGINE=MyISAM AUTO_INCREMENT=38791 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-02-25 21:04:51
