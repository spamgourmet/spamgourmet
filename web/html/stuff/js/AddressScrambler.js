// addressScrambler.js version 0.21
// copyright 2001, Josiah Q. Hamilton

var scrambleOffset = 5;

var c = new Array();
c[32] = " ";
c[33] = "!";
c[34] = "\"";
c[35] = "#";
c[36] = "$";
c[37] = "%";
c[38] = "&";
c[39] = "'";
c[40] = "(";
c[41] = ")";
c[42] = "*";
c[43] = "+";
c[44] = ",";
c[45] = "-";
c[46] = ".";
c[47] = "/";
c[48] = "0";
c[49] = "1";
c[50] = "2";
c[51] = "3";
c[52] = "4";
c[53] = "5";
c[54] = "6";
c[55] = "7";
c[56] = "8";
c[57] = "9";
c[58] = ":";
c[59] = ";";
c[60] = "<";
c[61] = "=";
c[62] = ">";
c[63] = "?";
c[64] = "@";
c[65] = "A";
c[66] = "B";
c[67] = "C";
c[68] = "D";
c[69] = "E";
c[70] = "F";
c[71] = "G";
c[72] = "H";
c[73] = "I";
c[74] = "J";
c[75] = "K";
c[76] = "L";
c[77] = "M";
c[78] = "N";
c[79] = "O";
c[80] = "P";
c[81] = "Q";
c[82] = "R";
c[83] = "S";
c[84] = "T";
c[85] = "U";
c[86] = "V";
c[87] = "W";
c[88] = "X";
c[89] = "Y";
c[90] = "Z";
c[91] = "[";
c[92] = "\\";
c[93] = "]";
c[94] = "^";
c[95] = "_";
c[96] = "`";
c[97] = "a";
c[98] = "b";
c[99] = "c";
c[100] = "d";
c[101] = "e";
c[102] = "f";
c[103] = "g";
c[104] = "h";
c[105] = "i";
c[106] = "j";
c[107] = "k";
c[108] = "l";
c[109] = "m";
c[110] = "n";
c[111] = "o";
c[112] = "p";
c[113] = "q";
c[114] = "r";
c[115] = "s";
c[116] = "t";
c[117] = "u";
c[118] = "v";
c[119] = "w";
c[120] = "x";
c[121] = "y";
c[122] = "z";
c[123] = "{";
c[124] = "|";
c[125] = "}";
c[126] = "~";

function getAsciiCode(theChar) {
  var i = 32;
  var ret = 0;
  var match = false;
  while (i < 127 && match != true) {
    if (c[i] == theChar) { 
      ret = i;
    }
    i ++;
  }
  return ret;
}

function getCharacter(theCode) {
  var ret = "";
  if (theCode > 31 && theCode < 127) {
    ret = c[theCode];
  }
  return ret;
}

function _scramble(inText,inverse) {
  var i = 0;
  var outText = "";
  var currentCode = 0;
  var newCode = 0;
  var newChar = '';
  var offset = scrambleOffset;
  if (inverse == true) {
    offset = offset * -1;
  }
  while (i < inText.length) {
    currentCode = getAsciiCode(inText.charAt(i));
    if (currentCode != 0) {
      newCode = currentCode + offset;
      if (newCode > 125) {
        newCode = (newCode - 125) + 31;
      }
      if (newCode < 32) {
        newCode = 126 - (32 - newCode);
      }
    } else {
      newCode = 0;
    }

    // sub tilde for backslash
    if (inverse == false && newCode == 92) {
      newCode = 126;
    } else if (inverse == true && currentCode == 126) {
      newCode = 92 + offset;
    }
    outText += getCharacter(newCode);
    i++;
  }
  return outText;
}

function descrambleText(inText) {
  var outText = _scramble(inText,true);
  return outText;
}

function scrambleText(inText) {
  var outText = _scramble(inText,false);
  return outText;
}

function writeDescrambledAddress(scrambledAddress) {
  document.open();
  document.write(descrambleText(scrambledAddress));
  document.close();
}

function writeMailToWithClearDisplayText(scrambledAddress, text) {
  document.open();
  document.write("<a href=\"mailto:" + descrambleText(scrambledAddress) + "\">" + text + "</a>");
  document.close();
}

function writeMailToWithScrambledDisplayText(scrambledAddress, scrambledText) {
  document.open();
  document.write("<a href=\"mailto:" + descrambleText(scrambledAddress) + "\">" + descrambleText(scrambledText) + "</a>");
  document.close();
}

function writeMailTo(scrambledAddress) {
  document.open();
  document.write("<a href=\"mailto:" + descrambleText(scrambledAddress) + "\">" + descrambleText(scrambledAddress) + "</a>");
  document.close();

}


function getMailToWithClearDisplayText(scrambledAddress, text) {
  return("<a href=\\\"mailto:" + descrambleText(scrambledAddress) + "\\\">" + text + "</a>");
}

function getMailTo(scrambledAddress) {
  return("<a href=\\\"mailto:" + descrambleText(scrambledAddress) + "\\\">" + descrambleText(scrambledAddress) + "</a>");
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



function writeScrambledAddress(address) {
  document.open();
  document.write(scrambleText(address));
  document.close();
}

