<%@ page import = "spamgourmet.AddressScrambler" %>

<script language="JavaScript" src="AddressScrambler.js" ></script>
<html>
<head><title>Address Scrambler JSP Example</title></head>
<body bgcolor="white">
<font size=4>

<script language="JavaScript">writeMailTo('<%= AddressScrambler._scramble("foo@bar.com", false) %>');</script>
</font>
</body>
</html>
