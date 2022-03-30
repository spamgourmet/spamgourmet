Feature: forward my reply from the protected email address to original source of incoming mail
In order to allow users to avoid exposing their own ("protected")
email addresses, spamgourmet accepts replies to emails sent to public email addresses
("spamgourmet address") and forwards them to the original source of the email that is replied to. 

    @live_system_future
    Scenario: reply to a forwarded mail and get the reply accepted by Google
    Given that I have a protected address
        And that I have a working spamgourmet address that will forward to the protected address
        And I have activated spamgourmet "reply address masking"
        And that I have a gmail email address [XX]
        And that [XX] is marked as exclusive sender for the protected address
    When I reply to an email sent from [XX] to the spamgourmet address
    Then after some time it should arrive to the [XX] address
        And that reply, when examined from the [XX] account, should pass Google's SPF tests 
        And that reply, when examined from the [XX] account, should pass Google's DKIM tests
        And that reply, when examined from the [XX] account, should pass Google's DMARC tests
