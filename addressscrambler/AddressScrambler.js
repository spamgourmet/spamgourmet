// addressScrambler.js version 0.2.2
// copyright 2001, 2002, Josiah Q. Hamilton

// This software is provided under the Artistic license of the Open 
//  Source Initiative, as it exists on 2001-12-19, including the optional
//  provision regarding aggregation with a commercial distribution.
// This notice must be included with any distribution.

// If you are using a server side component to scramble the
// addresses on their way out of the server, you must be using
// the same algorithm as this javascript uses to unscramble them,
// and for this one, you must have the same scramble string
var scrambleString = "some.arbitrary.ascii.string";


// This "private" function holds the scrambling algorithm
// The first argument is the text to be scrambled or unscrambled
// The second argument is boolean -- false if the text is to be
// scrambled or true if it is to be unscrambled 
function _scramble(inText,inverse) {
	var outText = "";
	var scrambleLen = scrambleString.length;
	for (var i = 0; i < inText.length; ++i) {
		var currentCode = inText.charCodeAt(i);
		var offset = scrambleString.charCodeAt(i % scrambleLen);
		if (inverse) {
			// offset should be non-negative, hence the 10*26 below
			offset = 10 * 26 - offset;
		}

		var newCode = currentCode;
		// caveat: the following lines assume ASCII encoding
		if (currentCode == 46) {
			newCode = 64;  // replace '.' by '@'
		} else if (currentCode == 64) {
			newCode = 46;  // replace '@' by '.'
		} else if (65 <= currentCode && currentCode <= 90) {
			newCode = (currentCode - 65 + offset) % 26 + 65;
		} else if (97 <= currentCode && currentCode <= 122) {
			newCode = (currentCode - 97 + offset) % 26 + 97;
		}

		outText += String.fromCharCode(newCode);
	}
	return outText;
}


// This function returns unscrambled text
// It takes scrambled text as an input
function descrambleText(inText) {
	var outText = _scramble(inText,true);
	return outText;
}


// This function returns scrambled text
// It takes unscrambled text as an input
function scrambleText(inText) {
	var outText = _scramble(inText,false);
	return outText;
}

// Function for testing
function testFunctions(addr) {
	var scrambled = scrambleText(addr);
	var descrambled = descrambleText(scrambled);
	document.open();
	document.write("<p> addr = '" + addr + "'");
	document.write("<p> scramble(addr) = '" + scrambled + "'");
	document.write("<p> descramble(scramble(addr)) = '" + descrambled + "'");
	document.close();
}

function writeScrambledAddress(address) {
	document.open();
	document.write(scrambleText(address));
	document.close();
}

function writeDescrambledAddress(scrambledAddress) {
	document.open();
	document.write(descrambleText(scrambledAddress));
	document.close();
}

// This "public" function takes a scrambled address 
// and a not-scrambled display text string
// and writes a mailto tag with them.  
// Note that the display text is not scrambled when you 
// use this function, so if the display text *is* 
// also the address, you should use the function
// writeMailTo instead, 
// and just use the scrambled address for the argument.
function writeMailToWithClearDisplayText(scrambledAddress, text) {
	document.open();
	document.write("<a href=\"mailto:" + descrambleText(scrambledAddress) + "\">" + text + "</a>");
	document.close();
}

// This "public" function takes a scrambled address *and* 
// scrambled display text, descrambles them both, and writes
// a mailto tag.  This is useful when you want to hide the display
// text from harvesters for some reason.  If you're simply using the
// address again as display text, it'll be easier to use the
// writeMailToUsingAddress function, which takes just one argument - the address 
function writeMailToWithScrambledDisplayText(scrambledAddress, scrambledText, cssClass) {
	document.open();
	document.write("<a href=\"mailto:" + descrambleText(scrambledAddress) + "\"");
        if (cssClass != null && cssClass != "") {
          document.write(" class=\"" + cssClass + "\" ");
        }
        document.write(">" + descrambleText(scrambledText) + "</a>");
	document.close();
	}

// This "public" function writes a mailto tag using the
// address itself as the display value
function writeMailTo(scrambledAddress) {
	writeMailToWithScrambledDisplayText(scrambledAddress, scrambledAddress);
}

// this "public" function writes a mailto tag using
// the address itself as the display value
// and takes css class that will be used in the tag
function writeMailToWithClass(scrambledAddress, cssClass) {
        writeMailToWithScrambledDisplayText(scrambledAddress, scrambledAddress, cssClass);
}

// the following methods are only used by the helper pages

function getMailToWithClearDisplayText(scrambledAddress, text) {
	return("<a href=\"mailto:" + descrambleText(scrambledAddress) + "\">" + text + "</a>");
}

function getMailTo(scrambledAddress) {
	return("<a href=\"mailto:" + descrambleText(scrambledAddress) + "\">" + descrambleText(scrambledAddress) + "</a>");
}

function getMailToCode(scrambledAddress) {
	return ("<script language=\"JavaScript\">writeMailTo('" + scrambledAddress + "');</script>");
}

function getEscapedMailToCode(scrambledAddress) {
	return ("&lt;script language=&quot;JavaScript&quot&gt;writeMailTo('" + scrambledAddress + "');&lt;/script&gt;");
}

function getMailToCodeWithClearDisplayText(scrambledAddress, text) {
	return ("<script language=\"JavaScript\">writeMailToWithClearDisplayText('" + scrambledAddress + ",'" + text + "');</script>");
}

function getEscapedMailToCodeWithClearDisplayText(scrambledAddress, text) {
	return ("&lt;script language=&quot;JavaScript&quot&gt;writeMailToWithClearDisplayText('" + scrambledAddress + "','"+ text + "');&lt;/script&gt;");
}

