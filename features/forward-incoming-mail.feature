Feature: forward incoming mail to protected email addresses
In order to allow users to avoid exposing their own ("protected")
email addresses, spamgourmet accepts emails on public email addresses
("spamgourmet address") and forards them to the protected address. 

    @live_system_future
    Scenario: forward a mail and get it accepted by Google
    Given that I have a configured gmail account
        And that I have a working spamgourmet address that will forward
    When I send an email to that address
    Then after some time it should come to my Google address
        And that email should pass Google's SPF tests
        And that email should pass Google's DKIM tests
        And that email should pass Google's DMARC tests


