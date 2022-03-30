Feature: forward incoming mail to protected email addresses
In order to allow users to avoid exposing their own ("protected")
email addresses, spamgourmet accepts emails on public email addresses
("spamgourmet address") and forwards them to the protected address. 

    @live_system_future
    Scenario: forward a mail and get it accepted by Google
    Given that the protected address is a gmail account
        And that I have a working spamgourmet address that will forward to the protected address
        And I have activated spamgourmet "reply address masking"
        And that I have another email address [XX] hosted anywhere
        And that [XX] is marked as exclusive sender for the protected address
    When I send an email from [XX] to the spamgourmet address
    Then after some time it should arrive to my protected address
        And that email should pass Google's SPF tests
        And that email should pass Google's DKIM tests
        And that email should pass Google's DMARC tests

