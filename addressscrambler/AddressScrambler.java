package spamgourmet;

import java.util.*;
import java.io.*;

public class AddressScrambler {
	public static String scrambleString = "some.arbitrary.ascii.string";
	public static String encoding = "US-ASCII";

	public AddressScrambler() {
	}

	// This "private" function holds the scrambling algorithm
	// The first argument is the text to be scrambled or unscrambled
	// The second argument is boolean -- false if the text is to be
	// scrambled or true if it is to be unscrambled 
	public static String _scramble(String inText, boolean inverse)
			throws UnsupportedEncodingException {
		byte []sbytes = scrambleString.getBytes(encoding);
		int slen = sbytes.length;

		byte []inbytes = inText.getBytes(encoding);
		byte []outbytes = new byte[inbytes.length];
		for (int i = 0; i < inbytes.length; ++i) {
			byte currentCode = inbytes[i];
			int offset = sbytes[i % slen];
			if (inverse) {
				// offset should be non-negative, hence the 10*26 below
				offset = 10 * 26 - offset;
			}

			byte newCode = currentCode;
			// caveat: the following lines assume ASCII encoding
			if (currentCode == 46) {
				newCode = 64;  // replace '.' by '@'
			} else if (currentCode == 64) {
				newCode = 46;  // replace '@' by '.'
			} else if (65 <= currentCode && currentCode <= 90) {
				newCode = (byte) ((currentCode - 65 + offset) % 26 + 65);
			} else if (97 <= currentCode && currentCode <= 122) {
				newCode = (byte) ((currentCode - 97 + offset) % 26 + 97);
			}

			outbytes[i] = newCode;
		}

		return new String(outbytes, encoding);
	}

}

