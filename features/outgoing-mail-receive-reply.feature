Feature: forward replies to emails "sent" by spamgourmet as if "from" a spamgourmet address
In order to allow users to avoid exposing their own ("protected")
email addresses, spamgourmet accepts replies to emails sent from a 
"spamgourmet address" and forwards them to the protected address. 

    @live_system_future
    Scenario: forward a reply to an email sent "from" a spamgourmet address and get it accepted by Google
    Given that the protected address is a gmail account
        And that I have a working spamgourmet address that will forward to the protected address
        And I have activated spamgourmet "reply address masking"
        And that I have another email address [XX] hosted anywhere
        And that [XX] is marked as exclusive sender for the protected address
    When I send an email from [XX] in reply to an email received from the spamgourmet address
    Then after some time it should arrive to my protected address
        And that reply should pass Google's SPF tests
        And that reply should pass Google's DKIM tests
        And that reply should pass Google's DMARC tests
