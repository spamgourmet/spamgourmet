using System;

namespace spamgourmet {
	public class AddressScrambler {
		public static string scrambleString = "some.arbitrary.ascii.string";

		public static string _scramble(string inText, bool inverse) {
			char []outText = new char[inText.Length];
			int slen = scrambleString.Length;

			for (int i = 0; i < inText.Length; ++i) {
				int currentCode = (int) inText[i];
				int offset = (int) scrambleString[i % slen];
				if (inverse) {
					// offset should be non-negative, hence the 10*26 below
					offset = 10 * 26 - offset;
				}

				int newCode = currentCode;
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

				outText[i] = (char) newCode;
			}

			return new String(outText);
		}

		public static int Main(string []args) {
			Console.WriteLine(_scramble(args[0], false));

			return 0;
		}
	}
}

