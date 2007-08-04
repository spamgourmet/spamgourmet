<?php

function _scramble($inText, $inverse) {
	$scrambleString = "some.arbitrary.ascii.string";
	$slen = strlen($scrambleString);

	$outText = "";
	$ilen = strlen($inText);

	for ($i = 0; $i < $ilen; ++$i) {
		$currentCode = ord(substr($inText, $i));
		$offset = ord(substr($scrambleString, $i % $slen));
		if ($inverse) {
			// offset should be non-negative, hence the 10*26 below
			$offset = 10 * 26 - $offset;
		}

		$newCode = $currentCode;
		// caveat: the following lines assume ASCII encoding
		if ($currentCode == 46) {
			$newCode = 64;  // replace '.' by '@'
		} else if ($currentCode == 64) {
			$newCode = 46;  // replace '@' by '.'
		} else if (65 <= $currentCode && $currentCode <= 90) {
			$newCode = ($currentCode - 65 + $offset) % 26 + 65;
		} else if (97 <= $currentCode && $currentCode <= 122) {
			$newCode = ($currentCode - 97 + $offset) % 26 + 97;
		}

		$outText = $outText . chr($newCode);
	}

	return $outText;
}

$scrambled = _scramble("foo@bar.com", false);
echo "<script language='JavaScript'>writeMailTo('$scrambled');</script>\n";

?>

