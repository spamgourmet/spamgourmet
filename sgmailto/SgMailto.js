/*
This javascript library contains functions to support the SgMailto, which 
generates a (hopefully) unique disposable email address with the "sender"
directive, which will establish the initial sender as the "exclusive sender"
for the address, allowing an email dialog through a protected address.

If the "usecookie" variable is set to true (it's false by default, see below),
the script tries to set a 10 year cookie with the address that's dished out,
so that if the browser user comes back, he or she will get the same
address as the last visit.  If the cookie's not there, then the script
just creates a new one.

To use this make sure that 1) you have a spamgourmet account (or a an account
on some other service that's providing the same thing), 2) you have "reply
address masking" enabled for your spamgourmet account in advance mode, 3) either 
you don't have watchword/prefix enabled, or you modify this script to 
account for that, and 4) you *change this script below* to put in your 
spamgourmet username.

If all that's true, then you can put this file on your website and modify 
your web page to 

1) include a reference to this file, like:

  <script type="text/javascript" src="/SgMailto.js">

2) add the SgMailto code to your page somewhere, like:

  <form name="sgmailform" action="mailto:" method="post" enctype="multipart/form-data" onSubmit="return getSgMailto(this);"><input type="submit" value="click here to send me an email!"></form>

 -- or in link form --

  <a href="" onclick="return getSgMailto(this);">email me now!</a>

*/

// change this to be your spamgourmet username
// you *must* change this or nothing will work.
var sguser="sgusername";

// change this to be the spamgourmet domain you'd like to use 
// or just leave it alone if you're OK with 'spamgourmet.com'
// if you do change it, you must use a domain handled by spamgourmet
// or some other service that's providing the same service (otherwise, the mail will go somewhere else)
var sgdomain = "spamgourmet.com";

// change this to be the default subject line for the messages you'll receive
// you might want to use %20 instead of a space, since some browsers won't
// handle the space you you might think
var subject = "contact%20from%20web%20page";

// change this to be a word that will be in each new address to help you identify them
// try to keep this to four characters or less, because it cuts into the length
// of the unique-ish string of characters that will make each address different
// the whole first part of the address (the "Word" in spamgourmet speak) can
// only be 20 characters, and your word below will be separated from the unique-ish
// string with a dash, which is one of them, too
var theword = "auto";

// set this to true if you want the script to store the address in a cookie on the
// user's browser.  This can be nice if the user comes back to your web page and
// clicks on the SgMailto again -- he or she will get the same address as last time
// provided the cookie is there. With this set to false, there'll be a new address 
// with each click.  The reason it's set to false now is because testing and setting
// up the script is a real pain when your browser is storing the same address as
// the last click -- you might make changes to the set up here, and not see them
// when you click on the link, because the cookie in your browser takes over.  Best
// to make sure the setup is the way you want, then change this to true.
var usecookie = false;

/* Copyright 2007 Josiah Q Hamilton -- portions lifted from elsewhere
This script is free software - you may use, modify, and redistibute it
under the terms of the Perl Artistic License. */

/**
 * This is the main function - it sets the action on the form (or href on the anchor) and returns true.
 */
function getSgMailto(obj) {
  var sgaddr = getSgAddr();
  obj.href = 'mailto:';
  obj.href += sgaddr;
  obj.href += "?subject=" + subject;
  obj.action = 'mailto:';
  obj.action += sgaddr;
  obj.action += "?subject=" + subject;
  return true;
}

/**
 * This function tries to fetch the address from cookie and/or
 * gets a new one and sets the cookie (if the cookie variable
 * is set to true, that is)
 */
function getSgAddr() {
  var addr;
  var existingAddr = readCookie('SgMailtoCookie');
  if (!usecookie || existingAddr == null || existingAddr == '') {
    var newAddr = getNewSgAddr();
    addr = newAddr;
    if (usecookie) {
      createCookie('SgMailtoCookie', newAddr, 3650);
    }
  } else {
    addr = existingAddr;
  }
  return addr; 
}

/**
 * This is the function that generates the sort-of-unique dispsoable address
 * using the system milliseconds and a pseudo-random number.  This could
 * likely be improved, but will probably work all the time.
 */
function getNewSgAddr() {
  var rand = Math.random();
  var randStr = "" + rand;
  var re = new RegExp("\\D","g");
  var randNumOnly = randStr.replace(re,'');
  var ms = new Date().getTime();
  ms = reverse(ms);
  var seed = ms + randNumOnly;
  var lengthoftheword = theword.length;
  var lengthofthestring = 20 - (lengthoftheword + 1);
  var thestring = seed.substring(0,lengthofthestring);
  var addr = thestring + "-" + theword + ".sender." + sguser + "@" + sgdomain;
  return addr;
}

function reverse(str) {
  var ret = 0
  str = "" + str; // make sure it's really a string -- yay for weak types!
  var i = 0;
  for (i = 0; i <= str.length; i++) {
    ret = str.charAt (i) + ret;
  }
  return ret;
} 


/**
 *
 * many thanks to Peter-Paul Koch, from whom I ripped off these handy cookie management
 * functions -- his site is http://www.quirksmode.org
 */
function createCookie(name,value,days) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

function eraseCookie(name) {
	createCookie(name,"",-1);
}

