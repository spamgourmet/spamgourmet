Address Scrambler Release 0.2
Copyright 2001, Josiah Q. Hamilton

This software is provided under the Artistic license of the Open
 Source Initiative, as it exists on 2001-12-19, including the optional
 provision regarding aggregation with a commercial distribution.
This notice must be included with any distribution.

Installation:
1. Place the .js file somehere in your webroot. 

2. Include the .js file in the web page files that
 will be using it like so:

  <script language="JavaScript" src="/AddressScrambler.js"></script>

 making sure that the proper web-path to the file is used, e.g., /js/AddressScrambler.js

3. Replace mailto tags with script tags that generate mailto tags.  If necessary (and it 
 probably will be) use the file AddressScramblerHelper.html to help generate the javascript
 code necessary to replace the mailto: tags. Make sure the helper file has the same include
 code that the other web pages will be using -- if you're using a different copy of
 AddressScrambler.js for the helper file, make sure it has the same scrambleString value as
 the copy you're using for your website. 

4. For use in dynamic jsp pages make use of the _scramble static function
   in the AddressScrambler.java file. For an example of such usage
   refer to the AddressScrambler.jsp file.


Known Issues - js:
The scrambling algorithm is merely to fool harvester bots -- it is likely strong enough for
 that.  It is certainly not strong enough for much else.

Known Issues - helper file
Only generates code for creating mailto tags that use 1) the address as display value or 2) another
 value stored in clear text.  The js file also contains code for creating mailto tags that have both
 the address and the display value scrambled, and also can simply spit out the unscrambled address.
 The helper file currently does not generate code for the latter options.

Changes v 0.5
Amite Marithe added server side code for several environments, including asp.net and java.  *Both* he and I came up with helper pages that work in more browsers than just IE.  Among AddressScramblerHelperGeneric.html, AddressScramblerHelperPrimitive.html, and plain-old AddressScramblerHelper.html, you should be able to find a helper page the works with your browser.

Changes v 0.2.2
Better fix for the bug below.

Changes v 0.2.1
Fixed a bug that caused a backslash to appear in the scrambled text, which messed everything up. 
 With an offset of 5 (the default), the capital letter W was affected.  Thanks to Nick Burkitt
 for finding, identifying, and reporting this bug.
 In this version, the bug was fixed by removing the tilde (~) from the supported character set
 and using it in the place of the backslash. The side effect of this is that you can't *encode*
 a tilde.  Hopefully there'll be a better fix later.

Changes v 0.2
Renamed some functions -- particularly to get ready for NS helper file support
Added comments to the code
Added this readme.txt file
Changed the writeMailTo function to take just the scrambled address for an argument and 
 to use the unscrambled address for the display value
Added methods to write mailtos with clear and scrambled display values other than the address itself
Renamed the array of ascii codes
Attempted to isolate the scrambling logic into one "private" method so that it could be easily swapped 
 out later, and more easily mirrored in the server side components.
Changed the first "A" in all the filenames and references to upper case

