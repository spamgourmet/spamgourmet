Feature: help administrators set up spamgourmet
In order to help administrators configure their email systems

  Scenario: configure domains for spamgourmet with email 
    Given that I have a domain which is not configure for spamgourmet
    And that I have set up my configuration file
    When I run the spamgourmet configuration scripts
    Then I should have DNS records configured for DKIM
    and I should have DNS records configured for SPF


No idea where to post this comment but this won't work.

Configurig SPF and DMARC are simply a matter of configuring DNS zone entries
and configuring DKIM requires changes to exim configuration that must match 
certain records that need to be added to the domain DNS zone
