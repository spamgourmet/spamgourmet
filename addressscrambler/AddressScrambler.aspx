<%@ Import Namespace="spamgourmet" %>

<script language="JavaScript" src="AddressScrambler.js" ></script>
<html>
<head><title>Address Scrambler ASP.Net Example </title></head>
<body bgcolor="white">
<font size=4>

<script language="JavaScript">writeMailTo('<%
	Response.Write(AddressScrambler._scramble("foo@bar.com", false))
%>');</script>
</font>
</body>
</html>
