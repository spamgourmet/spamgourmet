Feature: forward an email from a spamgourmet address to an external email
In order to allow users to avoid exposing their own ("protected")
email addresses, spamgourmet accepts emails from any email address sent to external email addresses
which will see it as coming from the "spamgourmet address".

    @live_system_future
    Scenario: send an email "from" a "spamgourmet address" and get it accepted by Google
    Given that I have a protected address
        And that I have a working spamgourmet address that will forward to the protected address
        And I have activated spamgourmet "reply address masking"
        And I have a gmail email address [XX]
    When I send an email from any email address to an email generated through spamgourmet interface to represent the [XX} email
    Then after some time it should arrive to the [XX] address
        And that email, when examined from the [XX] account, should pass Google's SPF tests 
        And that email, when examined from the [XX] account, should pass Google's DKIM tests
        And that email, when examined from the [XX] account, should pass Google's DMARC tests
